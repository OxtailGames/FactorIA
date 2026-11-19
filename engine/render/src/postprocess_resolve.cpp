#include "postprocess_resolve.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <initializer_list>
#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/core/reflect.h"
#include "bloom.h"
#include "fa/scene/components.h"

namespace fa::render {

namespace {

// Where the fields of each effect live in a PostProcess, found once from the reflected type (a field belongs to the effect whose name
// its own name starts with, post_field_effect), so a parameter added to the component is blended without touching this file.
struct EffectFields {
    std::size_t enabledOffset = 0;
    std::vector<const FieldInfo*> params;  // every other field of the effect
};

const std::array<EffectFields, kPostEffectCount>& effect_fields() {
    static const std::array<EffectFields, kPostEffectCount> table = [] {
        ensure_builtin_components();
        std::array<EffectFields, kPostEffectCount> t{};
        const TypeInfo* info = TypeRegistry::global().of<PostProcess>();
        FA_ASSERT(info, "PostProcess is not registered");
        for (const FieldInfo& f : info->fields) {
            const int e = post_field_effect(f.name);
            if (e < 0) continue;
            if (f.name == std::string(kPostEffectOrder[std::size_t(e)]) + "Enabled")
                t[std::size_t(e)].enabledOffset = f.offset;
            else
                t[std::size_t(e)].params.push_back(&f);
        }
        return t;
    }();
    return table;
}

bool& enabled_flag(PostProcess& p, int effect) {
    return *reinterpret_cast<bool*>(reinterpret_cast<char*>(&p) + effect_fields()[std::size_t(effect)].enabledOffset);
}
bool enabled_flag(const PostProcess& p, int effect) {
    return *reinterpret_cast<const bool*>(reinterpret_cast<const char*>(&p) +
                                          effect_fields()[std::size_t(effect)].enabledOffset);
}

// a * (1 - s) + b * s: exactly b at s = 1 (a + (b - a) * s can be off by one step).
float mix(float a, float b, float s) { return s >= 1.0f ? b : a * (1.0f - s) + b * s; }

// dst = src for one field.
void copy_field(const FieldInfo& f, PostProcess& dst, const PostProcess& src) {
    switch (f.kind) {
        case FieldKind::Bool: *static_cast<bool*>(f.ptr(&dst)) = *static_cast<const bool*>(f.ptr(&src)); break;
        case FieldKind::Int:
        case FieldKind::Enum:
            *static_cast<std::int32_t*>(f.ptr(&dst)) = *static_cast<const std::int32_t*>(f.ptr(&src));
            break;
        case FieldKind::Float: *static_cast<float*>(f.ptr(&dst)) = *static_cast<const float*>(f.ptr(&src)); break;
        case FieldKind::String:
        case FieldKind::Asset:
            *static_cast<std::string*>(f.ptr(&dst)) = *static_cast<const std::string*>(f.ptr(&src));
            break;
        case FieldKind::Vec2: *static_cast<Vec2*>(f.ptr(&dst)) = *static_cast<const Vec2*>(f.ptr(&src)); break;
        case FieldKind::Vec3: *static_cast<Vec3*>(f.ptr(&dst)) = *static_cast<const Vec3*>(f.ptr(&src)); break;
        case FieldKind::Vec4: *static_cast<Vec4*>(f.ptr(&dst)) = *static_cast<const Vec4*>(f.ptr(&src)); break;
        case FieldKind::Color: *static_cast<Color*>(f.ptr(&dst)) = *static_cast<const Color*>(f.ptr(&src)); break;
        case FieldKind::Rect: *static_cast<Rect*>(f.ptr(&dst)) = *static_cast<const Rect*>(f.ptr(&src)); break;
        case FieldKind::Entity: *static_cast<Entity*>(f.ptr(&dst)) = *static_cast<const Entity*>(f.ptr(&src)); break;
        case FieldKind::ArrayF32:
            *static_cast<ArrayF32*>(f.ptr(&dst)) = *static_cast<const ArrayF32*>(f.ptr(&src));
            break;
        case FieldKind::Json: *static_cast<Json*>(f.ptr(&dst)) = *static_cast<const Json*>(f.ptr(&src)); break;
        case FieldKind::ArrayI32:
            *static_cast<ArrayI32*>(f.ptr(&dst)) = *static_cast<const ArrayI32*>(f.ptr(&src));
            break;
        case FieldKind::ArrayU8: *static_cast<ArrayU8*>(f.ptr(&dst)) = *static_cast<const ArrayU8*>(f.ptr(&src)); break;
    }
}

template <class T>
void mix_members(T* d, const T* o, float s, std::initializer_list<float T::*> members) {
    for (float T::* m : members)
        if (std::isfinite(o->*m)) d->*m = mix(d->*m, o->*m, s);
}

// dst = dst * (1 - s) + src * s for the numeric kinds; the others switch at s >= 0.5. A value that is not finite in the component is
// never mixed in (a NaN written by a script must not poison the stack).
void blend_field(const FieldInfo& f, PostProcess& dst, const PostProcess& src, float s) {
    switch (f.kind) {
        case FieldKind::Float: {
            float& d = *static_cast<float*>(f.ptr(&dst));
            const float o = *static_cast<const float*>(f.ptr(&src));
            if (std::isfinite(o)) d = mix(d, o, s);
            break;
        }
        case FieldKind::Int: {
            std::int32_t& d = *static_cast<std::int32_t*>(f.ptr(&dst));
            const std::int32_t o = *static_cast<const std::int32_t*>(f.ptr(&src));
            d = std::int32_t(std::lround(mix(float(d), float(o), s)));
            break;
        }
        case FieldKind::Vec2:
            mix_members(static_cast<Vec2*>(f.ptr(&dst)), static_cast<const Vec2*>(f.ptr(&src)), s,
                        {&Vec2::x, &Vec2::y});
            break;
        case FieldKind::Vec3:
            mix_members(static_cast<Vec3*>(f.ptr(&dst)), static_cast<const Vec3*>(f.ptr(&src)), s,
                        {&Vec3::x, &Vec3::y, &Vec3::z});
            break;
        case FieldKind::Vec4:
            mix_members(static_cast<Vec4*>(f.ptr(&dst)), static_cast<const Vec4*>(f.ptr(&src)), s,
                        {&Vec4::x, &Vec4::y, &Vec4::z, &Vec4::w});
            break;
        case FieldKind::Color:
            mix_members(static_cast<Color*>(f.ptr(&dst)), static_cast<const Color*>(f.ptr(&src)), s,
                        {&Color::r, &Color::g, &Color::b, &Color::a});
            break;
        case FieldKind::Rect:
            mix_members(static_cast<Rect*>(f.ptr(&dst)), static_cast<const Rect*>(f.ptr(&src)), s,
                        {&Rect::x, &Rect::y, &Rect::w, &Rect::h});
            break;
        default:
            if (s >= 0.5f) copy_field(f, dst, src);
            break;
    }
}

// The kinds blend_field interpolates (the others switch at s >= 0.5).
bool is_blended_kind(FieldKind k) {
    return k == FieldKind::Float || k == FieldKind::Int || k == FieldKind::Vec2 || k == FieldKind::Vec3 ||
           k == FieldKind::Vec4 || k == FieldKind::Color || k == FieldKind::Rect;
}

// Applies one component with strength s (0 < s <= 1) to the stack. `trace` (optional) learns that layer `layer` wrote what it wrote.
void apply_component(PostProcess& stack, const PostProcess& c, float s, PostTrace* trace = nullptr, int layer = 0) {
    const auto& fields = effect_fields();
    for (int e = 0; e < kPostEffectCount; ++e) {
        if (!enabled_flag(c, e)) continue;
        const EffectFields& ef = fields[std::size_t(e)];
        if (trace) trace->effectLayers[std::size_t(e)].push_back(layer);
        if (!enabled_flag(stack, e)) {
            for (const FieldInfo* f : ef.params) {
                copy_field(*f, stack, postprocess_neutral());
                if (trace) trace->fieldLayer[f->name] = -1;
            }
            enabled_flag(stack, e) = true;
        }
        for (const FieldInfo* f : ef.params) {
            blend_field(*f, stack, c, s);
            if (trace && (is_blended_kind(f->kind) || s >= 0.5f)) trace->fieldLayer[f->name] = layer;
        }
    }
}

float strength_of(const PostProcess& c) {
    const float w = std::isfinite(c.weight) ? std::clamp(c.weight, 0.0f, 1.0f) : 0.0f;
    return w;
}

// Adds the customPasses of `c` to the stack when it applies with a strength of at least 0.5 (a list cannot be blended:
// it switches like a string does). An entry that does not parse goes to `customErrors` with its JSON pointer.
void add_custom_passes(PostStack& out, const World& world, const PostProcess& c, float s, Entity entity,
                       PostTrace* trace, int layer) {
    if (s < 0.5f || !c.customPasses.is_array() || c.customPasses.empty()) return;
    if (c.customPasses.size() > std::size_t(kMaxCustomPostPasses)) {
        auto all = parse_custom_post_passes(c.customPasses, "/customPasses");  // the error that says "too many"
        if (!all.ok()) out.customErrors.push_back(all.error());
        return;
    }
    for (std::size_t i = 0; i < c.customPasses.size(); ++i) {
        auto r = parse_custom_post_pass(c.customPasses[i], "/customPasses/" + std::to_string(i));
        if (!r.ok()) {
            out.customErrors.push_back(r.error());
            continue;
        }
        if (out.custom.size() >= std::size_t(4 * kMaxCustomPostPasses)) {  // the volumes together stay bounded
            // Name the entries that are dropped: the first one with its material (or why it does not parse either), and
            // every other one of this component that does not parse with its own pointer and reason.
            const std::string prefix = "The custom passes of the camera and its volumes together are limited to " +
                                       std::to_string(4 * kMaxCustomPostPasses) + "; ";
            const std::size_t dropped = c.customPasses.size() - i;
            std::string first;
            std::vector<Error> unparsable;
            for (std::size_t j = i; j < c.customPasses.size(); ++j) {
                auto rest = parse_custom_post_pass(c.customPasses[j], "/customPasses/" + std::to_string(j));
                if (rest.ok()) {
                    if (j == i) first = " (material '" + rest->material + "')";
                } else {
                    if (j == i)
                        first = " (it does not parse either: " + rest.error().message + ")";
                    else
                        unparsable.push_back(rest.error());
                }
            }
            // The first component that hits the cap says it; the components after it (later volumes) add what they drop
            // to that message, so every dropped entry is named once, not only those of the first one.
            const auto said = std::find_if(out.customErrors.begin(), out.customErrors.end(),
                                           [&](const Error& e) { return e.message.rfind(prefix, 0) == 0; });
            if (said == out.customErrors.end()) {
                out.customErrors.push_back(Error{
                    prefix + "the " + std::to_string(dropped) + (dropped == 1 ? " entry" : " entries") +
                        " of one PostProcess from /customPasses/" + std::to_string(i) + first + " on are not drawn.",
                    "Remove entries from PostProcess.customPasses of the camera or the volumes, or merge "
                    "passes into one material."});
                for (Error& e : unparsable) out.customErrors.push_back(std::move(e));
            } else {
                const std::string who = "entity '" + world.info(entity).name + "' (" + world.id_of(entity) + ")";
                said->message += " Also not drawn: the " + std::to_string(dropped) +
                                 (dropped == 1 ? " entry" : " entries") + " of the PostProcess of " + who +
                                 " from /customPasses/" + std::to_string(i) + first + " on.";
                for (Error& e : unparsable) {
                    e.message = "In the PostProcess of " + who + ": " + e.message;
                    out.customErrors.push_back(std::move(e));
                }
            }
            return;
        }
        r->source = entity.bits();
        out.custom.push_back(std::move(*r));
        if (trace) trace->customLayers.push_back(layer);
    }
}

}  // namespace

int PostStack::effect_count() const {
    int n = 0;
    for (std::uint32_t m = mask; m; m &= m - 1) ++n;
    return n;
}

float post_volume_influence(const PostProcess& v, const Mat4& m, Vec3 point, bool perspective) {
    if (v.shape == PostShape::Global) return 1.0f;
    const Vec3 axes[3] = {m.transform_dir({1, 0, 0}), m.transform_dir({0, 1, 0}), m.transform_dir({0, 0, 1})};
    float scale[3];
    for (int i = 0; i < 3; ++i) scale[i] = length(axes[i]);
    const Vec3 d = point - m.translation();
    const float size[3] = {std::fabs(v.size.x), std::fabs(v.size.y), std::fabs(v.size.z)};
    if (!std::isfinite(d.x) || !std::isfinite(d.y) || !std::isfinite(d.z)) return 0.0f;
    for (int i = 0; i < 3; ++i)
        if (!std::isfinite(scale[i]) || !std::isfinite(size[i])) return 0.0f;
    // The point in the volume's turned frame (world units, no scale).
    float local[3];
    for (int i = 0; i < 3; ++i) local[i] = scale[i] > kEpsilon ? dot(d, axes[i]) / scale[i] : 0.0f;
    if (!perspective) local[2] = 0.0f;

    float dist = 0.0f;  // world units from the point to the shape, 0 inside
    switch (v.shape) {
        case PostShape::Box: {
            float sq = 0.0f;
            for (int i = 0; i < (perspective ? 3 : 2); ++i) {
                const float over = std::fabs(local[i]) - size[i] * scale[i] * 0.5f;
                if (over > 0.0f) sq += over * over;
            }
            dist = std::sqrt(sq);
            break;
        }
        case PostShape::Circle: {
            const float radius = size[0] * std::max(scale[0], scale[1]);
            dist = std::max(0.0f, std::sqrt(local[0] * local[0] + local[1] * local[1]) - radius);
            break;
        }
        case PostShape::Sphere: {
            const float radius =
                size[0] * (perspective ? std::max({scale[0], scale[1], scale[2]}) : std::max(scale[0], scale[1]));
            dist = std::max(0.0f, std::sqrt(local[0] * local[0] + local[1] * local[1] + local[2] * local[2]) - radius);
            break;
        }
        case PostShape::Global: break;
    }
    if (!(dist > 0.0f)) return 1.0f;
    const float blend = std::isfinite(v.blendDistance) ? v.blendDistance : 0.0f;
    if (blend <= 0.0f) return 0.0f;
    return std::clamp(1.0f - dist / blend, 0.0f, 1.0f);
}

bool legacy_post_of_camera(const Camera& cam, PostProcess& out) {
    if (!cam.bloom && cam.colorFilter == ColorFilter::None) return false;
    out = postprocess_neutral();
    const BloomSettings b =
        sanitize_bloom(cam.bloom, cam.bloomThreshold, cam.bloomIntensity, cam.bloomRadius, cam.bloomScreenSpace);
    out.bloomEnabled = b.enabled;
    out.bloomThreshold = b.threshold;
    out.bloomIntensity = b.intensity;
    out.bloomRadius = b.radius;
    out.bloomScreenSpace = b.screenSpace;
    out.bloomKnee = 0.0f;
    out.colorFilterEnabled = cam.colorFilter != ColorFilter::None;
    out.colorFilterMode = cam.colorFilter;
    return true;
}

PostStack resolve_post_stack(World& world, const CameraGeometry& cam, const PostProcess* implicitOwn,
                             PostTrace* trace) {
    PostStack out;
    if (!world.any<PostProcess>() && !implicitOwn) return out;

    struct Volume {
        Entity entity;
        const PostProcess* component;
        float strength;
        float influence;
    };
    std::vector<Volume> volumes;
    const PostProcess* own = nullptr;
    world.each<PostProcess>([&](Entity e, PostProcess& p) {
        if (!p.enabled || !world.active_in_hierarchy(e)) return;
        if (world.has<Camera>(e)) {
            if (e == cam.entity) own = &p;  // a camera's stack is its own: another camera's is not a volume
            return;
        }
        const float w = strength_of(p);
        if (!(w > 0.0f)) return;
        const float influence = post_volume_influence(p, world.world_matrix(e), cam.position, cam.perspective);
        const float s = w * influence;
        if (s > 0.0f) volumes.push_back({e, &p, s, influence});
    });

    const bool legacy = !own;
    if (!own)
        own =
            implicitOwn;  // the Camera.bloom* / Camera.colorFilter fields of a camera that has no PostProcess of its own
    if (own) {
        const float s = strength_of(*own);
        if (s > 0.0f) {
            int layer = 0;
            if (trace) {
                layer = int(trace->layers.size());
                trace->layers.push_back({legacy ? PostLayer::Kind::Legacy : PostLayer::Kind::Own, cam.entity, s, 1.0f});
            }
            apply_component(out.fx, *own, s, trace, layer);
            add_custom_passes(out, world, *own, s, cam.entity, trace, layer);
            ++out.sources;
        }
    }
    // Ascending priority, equal priorities by entity id: the last applied wins, and the result never depends on the order the
    // components happen to be stored in.
    std::sort(volumes.begin(), volumes.end(), [&](const Volume& a, const Volume& b) {
        if (a.component->priority != b.component->priority) return a.component->priority < b.component->priority;
        const std::string& ia = world.id_of(a.entity);
        const std::string& ib = world.id_of(b.entity);
        if (ia != ib) return ia < ib;
        return a.entity.bits() < b.entity.bits();
    });
    for (const Volume& v : volumes) {
        int layer = 0;
        if (trace) {
            layer = int(trace->layers.size());
            trace->layers.push_back({PostLayer::Kind::Volume, v.entity, strength_of(*v.component), v.influence});
        }
        apply_component(out.fx, *v.component, v.strength, trace, layer);
        add_custom_passes(out, world, *v.component, v.strength, v.entity, trace, layer);
        ++out.sources;
    }
    for (int e = 0; e < kPostEffectCount; ++e)
        if (enabled_flag(out.fx, e)) out.mask |= 1u << e;
    return out;
}

}  // namespace fa::render
