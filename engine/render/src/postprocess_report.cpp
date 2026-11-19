#include "fa/render/post_report.h"

#include <cmath>
#include <string>

#include "fa/core/log.h"
#include "fa/core/reflect.h"
#include "fa/scene/camera_geometry.h"
#include "postprocess_resolve.h"

namespace fa::render {

namespace {

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

std::string layer_label(const World& world, const PostLayer& l) {
    if (l.kind == PostLayer::Kind::Own) return "own";
    if (l.kind == PostLayer::Kind::Legacy) return "legacy";
    return "volume:" + world.id_of(l.entity);
}

const char* layer_kind(const PostLayer& l) {
    return l.kind == PostLayer::Kind::Volume ? "volume" : l.kind == PostLayer::Kind::Own ? "own" : "legacy";
}

}  // namespace

Json post_stack_report(World& world, Entity camera) {
    ensure_builtin_components();
    const TypeInfo* type = TypeRegistry::global().of<PostProcess>();
    FA_ASSERT(type, "PostProcess is not registered");
    if (!camera.is_null() && !world.alive(camera)) camera = kNullEntity;

    std::string warned;
    const CameraGeometry geo = camera_geometry(world, camera, CameraTarget{}, warned, nullptr, false, false);
    PostProcess legacy;
    const Camera* cam = camera.is_null() ? nullptr : world.get<Camera>(camera);
    const bool useLegacy = cam && legacy_post_of_camera(*cam, legacy);
    PostTrace trace;
    const PostStack stack = resolve_post_stack(world, geo, useLegacy ? &legacy : nullptr, &trace);

    Json layers = Json::array();
    for (std::size_t i = 0; i < trace.layers.size(); ++i) {
        const PostLayer& l = trace.layers[i];
        Json j = Json::object({{"index", int(i)},
                               {"from", layer_label(world, l)},
                               {"kind", layer_kind(l)},
                               {"entity", world.alive(l.entity) ? world.id_of(l.entity) : std::string()},
                               {"weight", round3(l.weight)},
                               {"influence", round3(l.influence)},
                               {"strength", round3(l.strength())}});
        if (l.kind == PostLayer::Kind::Volume)
            if (const PostProcess* p = world.get<PostProcess>(l.entity)) j["priority"] = p->priority;
        layers.push_back(std::move(j));
    }

    Json effects = Json::array();
    for (int e = 0; e < kPostEffectCount; ++e) {
        const std::string name(kPostEffectOrder[std::size_t(e)]);
        Json eff = Json::object({{"name", name}, {"enabled", stack.has(PostEffect(e))}});
        Json used = Json::array();
        for (const int li : trace.effectLayers[std::size_t(e)]) used.push_back(li);
        eff["layers"] = std::move(used);
        if (stack.has(PostEffect(e))) {
            Json fields = Json::object();
            for (const FieldInfo& f : type->fields) {
                if (post_field_effect(f.name) != e || f.name == name + "Enabled") continue;
                Json value;
                if (f.kind == FieldKind::Entity) {
                    const Entity t = *static_cast<const Entity*>(f.ptr(&stack.fx));
                    value = !t.is_null() && world.alive(t) ? Json(world.id_of(t)) : Json("");
                } else {
                    value = field_to_json(f, &stack.fx);
                }
                const auto it = trace.fieldLayer.find(f.name);
                const int li = it == trace.fieldLayer.end() ? -1 : it->second;
                Json entry = Json::object({{"value", std::move(value)}});
                if (li >= 0 && li < int(trace.layers.size())) {
                    entry["from"] = layer_label(world, trace.layers[std::size_t(li)]);
                    entry["strength"] = round3(trace.layers[std::size_t(li)].strength());
                } else {
                    entry["from"] = "default";
                }
                fields[f.name] = std::move(entry);
            }
            eff["fields"] = std::move(fields);
        }
        effects.push_back(std::move(eff));
    }

    // The custom passes the camera draws, in the order they are added (own first, then the volumes by priority).
    Json custom = Json::array();
    for (std::size_t i = 0; i < stack.custom.size(); ++i) {
        const CustomPostPass& c = stack.custom[i];
        const int li = i < trace.customLayers.size() ? trace.customLayers[i] : -1;
        Json j = Json::object({{"name", c.name.empty() ? c.material : c.name},
                               {"material", c.material},
                               {"position", c.position},
                               {"enabled", c.enabled},
                               {"materialParams", c.params}});
        j["from"] = li >= 0 && li < int(trace.layers.size()) ? layer_label(world, trace.layers[std::size_t(li)])
                                                             : std::string("default");
        custom.push_back(std::move(j));
    }
    Json problems = Json::array();
    for (const Error& e : stack.customErrors) problems.push_back(e.to_string());

    return Json::object(
        {{"camera", camera.is_null() ? std::string() : world.id_of(camera)},
         {"customPasses", std::move(custom)},
         {"customPassProblems", std::move(problems)},
         {"position", Json::array({round3(geo.position.x), round3(geo.position.y), round3(geo.position.z)})},
         {"perspective", geo.perspective},
         {"layers", std::move(layers)},
         {"effects", std::move(effects)},
         {"count", stack.effect_count()}});
}

}  // namespace fa::render
