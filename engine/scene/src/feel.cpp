// Game feel (feel.h): the state, the actions, the clocks and the noise of the shake.
#include "fa/scene/feel.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <variant>

#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"

namespace fa {

namespace {


bool is_finite(float v) { return std::isfinite(v); }

std::uint32_t hash32(std::uint32_t x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

// A lattice value in [-1, 1] from the seed, the channel and the lattice index (any sign).
float lattice(std::uint32_t seed, std::uint32_t channel, std::int64_t i) {
    std::uint32_t h = hash32(seed ^ hash32(channel * 0x9e3779b9U + 0x85ebca6bU));
    h = hash32(h ^ hash32(static_cast<std::uint32_t>(i & 0xffffffff)));
    h = hash32(h + static_cast<std::uint32_t>((i >> 32) & 0xffffffff));
    return static_cast<float>(h >> 8) * (2.0f / 16777215.0f) - 1.0f;
}

FeelEntity& record_of(World& w, Entity e) { return w.feel().entities[e.bits()]; }

Error bad_entity(const char* what, Entity e, const World& w) {
    return make_error(std::format("{}: entity {} does not exist", what, e.is_null() ? "(none)" : std::to_string(e.index)),
                      w.alive(e) ? "" : "Pass a live entity: a script holds a handle that dies with its entity or with a scene load.");
}

bool has_mesh(const World& w, Entity e) { return w.has<MeshRenderer>(e); }

// A vector in the entity's own space as a world vector: the unit axes of its world matrix, so a mirrored sprite flips x and a
// turned one turns it, but its size (a 64-pixel scale) does not stretch the vector.
Vec3 local_to_world(const World& w, Entity e, Vec3 v) {
    const Mat4 m = w.world_matrix(e);
    auto axis = [&](int c) {
        const Vec3 a{m.at(c, 0), m.at(c, 1), m.at(c, 2)};
        return length_sq(a) > 1e-12f ? normalize(a) : Vec3{c == 0 ? 1.0f : 0.0f, c == 1 ? 1.0f : 0.0f, c == 2 ? 1.0f : 0.0f};
    };
    return axis(0) * v.x + axis(1) * v.y + axis(2) * v.z;
}

// ---------------------------------------------------------------------------------------------- the checks of the options
// The one place that says what a value may be, for the calls (feel_shake...) and for feel_check_action (a clip file at load).
Result<void> check_options(const ShakeOptions& o) {
    if (!is_finite(o.amount) || o.amount < 0.0f)
        return make_error(std::format("shake: amount must be a number from 0 to 1, got {}", o.amount),
                          "0.2 is a small bump, 0.5 a hit, 1 an explosion.");
    if (!is_finite(o.duration) || o.duration <= 0.0f)
        return make_error(std::format("shake: duration must be a number of seconds above 0, got {}", o.duration));
    if (!is_finite(o.frequency) || o.frequency <= 0.0f)
        return make_error(std::format("shake: frequency must be above 0, got {}", o.frequency), "Samples of noise per second; 25 is the default.");
    if (!is_finite(o.maxOffset) || o.maxOffset < 0.0f)
        return make_error(std::format("shake: maxOffset must be 0 (the camera's default) or more, got {}", o.maxOffset));
    if (!is_finite(o.maxAngle) || o.maxAngle < 0.0f)
        return make_error(std::format("shake: maxAngle must be 0 or more degrees, got {}", o.maxAngle));
    if (!is_finite(o.cap) || o.cap <= 0.0f || o.cap > 1.0f)
        return make_error(std::format("shake: cap must be above 0 and at most 1, got {}", o.cap));
    return {};
}

Result<void> check_options(const HitStopOptions& o) {
    if (!is_finite(o.duration) || o.duration <= 0.0f)
        return make_error(std::format("hitStop: duration must be a number of seconds above 0, got {}", o.duration),
                          "0.05 to 0.12 is a hit; the stop runs in real time.");
    if (o.duration > kMaxHitStopSeconds)
        return make_error(std::format("hitStop: {} seconds is longer than the {} s limit", o.duration, kMaxHitStopSeconds),
                          "The duration is in seconds, not milliseconds.");
    if (!is_finite(o.scale) || o.scale < 0.0f || o.scale > 1.0f)
        return make_error(std::format("hitStop: scale must be from 0 (frozen) to 1 (no effect), got {}", o.scale));
    return {};
}

Result<void> check_options(const FlashOptions& o) {
    if (!is_finite(o.duration) || o.duration <= 0.0f)
        return make_error(std::format("flash: duration must be a number of seconds above 0, got {}", o.duration));
    if (!is_finite(o.strength) || o.strength < 0.0f || o.strength > 1.0f)
        return make_error(std::format("flash: strength must be from 0 to 1, got {}", o.strength));
    return {};
}

Result<void> check_options(const SquashOptions& o) {
    if (!is_finite(o.amount) || std::fabs(o.amount) > 1.5f)
        return make_error(std::format("squash: amount must be from -1.5 to 1.5, got {}", o.amount),
                          "Positive squashes (wider, flatter), negative stretches; 0.3 is a clear landing.");
    if (!is_finite(o.duration) || o.duration <= 0.0f)
        return make_error(std::format("squash: duration must be a number of seconds above 0, got {}", o.duration));
    if (o.axis != 'x' && o.axis != 'y') return make_error("squash: axis must be \"x\" or \"y\"");
    return {};
}

Result<void> check_options(const KnockbackOptions& o) {
    if (!is_finite(o.direction.x) || !is_finite(o.direction.y) || !is_finite(o.direction.z))
        return make_error("knockback: direction must be finite numbers");
    if (o.speed && (!is_finite(*o.speed) || *o.speed < 0.0f))
        return make_error(std::format("knockback: speed must be 0 or more, got {}", *o.speed));
    if (!is_finite(o.lockTime) || o.lockTime < 0.0f)
        return make_error(std::format("knockback: lockTime must be 0 or more seconds, got {}", o.lockTime));
    if (!is_finite(o.decay) || o.decay < 0.0f) return make_error(std::format("knockback: decay must be 0 or more, got {}", o.decay));
    if (length(o.direction) < 1e-6f)
        return make_error("knockback: direction has no length",
                          "Pass the way to push, e.g. the vector from the attacker to the victim: [1, 0] pushes right.");
    return {};
}

Result<void> check_options(const SpawnOptions& o) {
    if (o.prefab.empty())
        return make_error("spawn: 'prefab' is required", "The prefab to instantiate, e.g. {\"action\": \"spawn\", \"prefab\": \"prefabs/hit_spark.prefab.json\"}.");
    if (!is_finite(o.offset.x) || !is_finite(o.offset.y) || !is_finite(o.offset.z)) return make_error("spawn: offset must be finite numbers");
    if (!is_finite(o.lifetime) || o.lifetime < 0.0f)
        return make_error(std::format("spawn: lifetime must be 0 (the prefab ends itself) or a number of seconds, got {}", o.lifetime));
    return {};
}

Result<void> check_options(const SoundOptions& o) {
    if (o.path.empty())
        return make_error("sound: 'path' is required", "The clip to play, e.g. {\"action\": \"sound\", \"path\": \"audio/hit.wav\"}.");
    if (!is_finite(o.volume) || o.volume < 0.0f || o.volume > 4.0f) return make_error(std::format("sound: volume must be from 0 to 4, got {}", o.volume));
    if (!is_finite(o.pitch) || o.pitch < 0.1f || o.pitch > 4.0f) return make_error(std::format("sound: pitch must be from 0.1 to 4, got {}", o.pitch));
    if (!is_finite(o.pan) || o.pan < -1.0f || o.pan > 1.0f) return make_error(std::format("sound: pan must be from -1 (left) to 1 (right), got {}", o.pan));
    if (o.bus.empty()) return make_error("sound: bus must not be empty", "\"sfx\", \"music\", \"ui\" or a bus of the project.");
    return {};
}

}  // namespace

// ------------------------------------------------------------------------------------------------------- noise
float feel_noise(std::uint32_t seed, std::uint32_t channel, double x) {
    const double fl = std::floor(x);
    const float f = static_cast<float>(x - fl);
    const float u = f * f * (3.0f - 2.0f * f);
    const std::int64_t i = static_cast<std::int64_t>(fl);
    const float a = lattice(seed, channel, i);
    const float b = lattice(seed, channel, i + 1);
    return a + (b - a) * u;
}

// ------------------------------------------------------------------------------------------------------ queries
float FeelState::hit_stop_factor() const {
    float f = 1.0f;
    for (const FeelHitStop& h : hitStops)
        if (h.remaining > 0.0f) f = std::min(f, h.scale);
    return f;
}

float FeelState::hit_stop_remaining() const {
    float r = 0.0f;
    for (const FeelHitStop& h : hitStops) r = std::max(r, h.remaining);
    return r;
}

const FeelEntity* FeelState::find(Entity e) const {
    auto it = entities.find(e.bits());
    return it == entities.end() ? nullptr : &it->second;
}

FeelEntity* FeelState::find(Entity e) {
    auto it = entities.find(e.bits());
    return it == entities.end() ? nullptr : &it->second;
}

const FeelPose* FeelState::pose_of(Entity e) const {
    if (poseCount == 0) return nullptr;
    const FeelEntity* r = find(e);
    return r && r->hasPose ? &r->pose : nullptr;
}

std::optional<Color> FeelState::flash_of(Entity e) const {
    const FeelEntity* r = find(e);
    if (!r || !r->flash || r->flash->remaining <= 0.0f) return std::nullopt;
    const FeelFlash& f = *r->flash;
    const float amount = f.strength * (f.fade && f.duration > 0.0f ? std::clamp(f.remaining / f.duration, 0.0f, 1.0f) : 1.0f);
    if (amount <= 0.0f) return std::nullopt;
    return Color{f.color.r, f.color.g, f.color.b, amount};
}

bool FeelState::any_flash() const {
    for (const auto& [bits, r] : entities)
        if (r.flash && r.flash->remaining > 0.0f) return true;
    return false;
}

bool FeelState::knocked_back(Entity e) const { return knockback_remaining(e) > 0.0f; }

float FeelState::knockback_remaining(Entity e) const {
    const FeelEntity* r = find(e);
    return r && r->knock ? std::max(0.0f, r->knock->lockRemaining) : 0.0f;
}

void FeelState::clear_scene() {
    entities.clear();
    hitStops.clear();
    counter = 0;
    poseCount = 0;
    warnedNoCamera = false;
    sounds.clear();
    spawns.clear();
    lifetimes.clear();
    warnedClipActions.clear();
    failedSounds.clear();
}

// ----------------------------------------------------------------------------------------------------- actions
float feel_default_shake_offset(const World& w, Entity camera) {
    const Camera* c = w.alive(camera) ? w.get<Camera>(camera) : nullptr;
    if (!c) return 8.0f;
    if (c->projection == Projection::Perspective) return 0.3f;
    return c->orthoSize > 0.0f ? c->orthoSize * 2.0f * 0.025f : 16.0f;
}

Result<void> feel_shake(World& w, Entity camera, const ShakeOptions& o) {
    if (camera.is_null()) {
        const std::vector<Entity> cams = rendering_cameras(w);
        if (cams.empty()) {
            // Damage code calls camera.shake without knowing the scene: a scene with no camera (a menu, a loading screen) is not
            // an error, there is just nothing to shake. One warning per scene, so the log tells where the shake went.
            FeelState& st = w.feel();
            if (!st.warnedNoCamera) {
                st.warnedNoCamera = true;
                FA_WARN("feel", "shake ignored: the scene has no active camera to shake. Hint: add an entity with a Camera component, "
                                "or pass the camera entity to shake");
            }
            return {};
        }
        camera = cams.front();
    }
    if (!w.alive(camera)) return bad_entity("shake", camera, w);
    if (auto r = check_options(o); !r.ok()) return r;

    FeelState& fs = w.feel();
    float amount = std::min(o.amount, 1.0f);
    if (fs.reduce_motion()) amount *= kReduceMotionShake;
    FeelEntity& rec = record_of(w, camera);
    if (!rec.shake) {
        FeelShake s;
        // The noise is seeded from the world's RNG state WITHOUT drawing from it, so a shake (or the player's reduce motion,
        // which scales it) never changes the random numbers the game gets; a counter makes every shake of a run different.
        s.seed = hash32(static_cast<std::uint32_t>(w.rng().state() ^ (w.rng().state() >> 32)) + 0x9e3779b9U * (++fs.counter));
        rec.shake = s;
    }
    FeelShake& s = *rec.shake;
    s.trauma = std::min(o.cap, s.trauma + amount);
    s.remaining = std::max(s.remaining, o.duration);
    s.decay = s.trauma / s.remaining;
    s.frequency = o.frequency;
    s.maxOffset = o.maxOffset > 0.0f ? o.maxOffset : feel_default_shake_offset(w, camera);
    s.maxAngle = o.maxAngle;
    const Camera* c = w.get<Camera>(camera);
    s.perspective = c && c->projection == Projection::Perspective;
    return {};
}

Result<void> feel_hit_stop(World& w, const HitStopOptions& o) {
    if (auto r = check_options(o); !r.ok()) return r;
    FeelState& fs = w.feel();
    float duration = o.duration;
    if (fs.reduce_motion()) duration *= kReduceMotionHitStop;
    // Overlapping stops do not add up: a second call with the same scale only extends the first up to its own length.
    for (FeelHitStop& h : fs.hitStops)
        if (h.scale == o.scale) {
            h.remaining = std::max(h.remaining, duration);
            return {};
        }
    fs.hitStops.push_back({duration, o.scale});
    return {};
}

Result<void> feel_flash(World& w, Entity e, const FlashOptions& o) {
    if (!w.alive(e)) return bad_entity("flash", e, w);
    if (auto r = check_options(o); !r.ok()) return r;
    FeelState& fs = w.feel();
    FeelFlash f;
    f.color = o.color;
    f.duration = o.duration;
    f.remaining = o.duration;
    f.strength = o.strength;
    f.fade = o.fade;
    if (fs.reduced_effects()) {  // no full-bright strobe: a faint fading cue
        f.strength = std::min(f.strength, kReducedEffectsFlash);
        f.fade = true;
    }
    record_of(w, e).flash = f;
    return {};
}

Result<void> feel_squash(World& w, Entity e, const SquashOptions& o) {
    if (!w.alive(e)) return bad_entity("squash", e, w);
    if (auto r = check_options(o); !r.ok()) return r;
    FeelSquash s;
    s.amount = o.amount * (w.feel().reduce_motion() ? kReduceMotionSquash : 1.0f);
    s.duration = o.duration;
    s.axis = o.axis;
    s.volume3d = has_mesh(w, e);
    record_of(w, e).squash = s;
    return {};
}

Result<void> feel_knockback(World& w, Entity e, const KnockbackOptions& o) {
    if (!w.alive(e)) return bad_entity("knockback", e, w);
    if (auto r = check_options(o); !r.ok()) return r;

    RigidBody2D* rb2 = w.get<RigidBody2D>(e);
    RigidBody3D* rb3 = w.get<RigidBody3D>(e);
    const bool body2 = rb2 && rb2->type == BodyType::Dynamic;
    const bool body3 = !body2 && rb3 && rb3->type == BodyType::Dynamic;
    Vec3 d = o.local ? local_to_world(w, e, o.direction) : o.direction;
    if (body2) d.z = 0.0f;
    const float len = length(d);
    if (len < 1e-6f)
        return make_error("knockback: direction has no length" + std::string(body2 ? " (a 2D body ignores z)" : ""),
                          "Pass the way to push, e.g. the vector from the attacker to the victim: [1, 0] pushes right.");
    d = d * (1.0f / len);
    // The default is metres per second: units for a 3D entity, pixels (times pixelsPerMeter) for a 2D one.
    const bool is3d = body3 || w.has<RigidBody3D>(e) || w.has<MeshRenderer>(e);
    const float speed = o.speed ? *o.speed : kDefaultKnockbackSpeed * (is3d ? 1.0f : std::max(w.feel().pixelsPerMeter, 1.0f));

    if (body2) {
        rb2->velocity = {rb2->velocity.x + d.x * speed, rb2->velocity.y + d.y * speed};
    } else if (body3) {
        rb3->velocity = rb3->velocity + d * speed;
    }
    FeelEntity& rec = record_of(w, e);
    FeelKnock k = rec.knock ? *rec.knock : FeelKnock{};
    if (!body2 && !body3) {
        k.velocity = d * speed;
        k.decay = o.decay;
    }
    k.lockRemaining = std::max(k.lockRemaining, o.lockTime);
    rec.knock = k;
    return {};
}

Result<void> feel_spawn(World& w, Entity e, const SpawnOptions& o) {
    if (!e.is_null() && !w.alive(e)) return bad_entity("spawn", e, w);
    if (auto r = check_options(o); !r.ok()) return r;
    FeelState& fs = w.feel();
    if (fs.spawns.size() >= kMaxQueuedSpawns) {
        // A loop or a very short clip event cannot fill the scene with effects in one frame: the rest of this frame's spawns are refused.
        return make_error(std::format("spawn: {} spawn actions are already waiting for this frame, so '{}' was not queued", kMaxQueuedSpawns, o.prefab),
                          "A clip event that fires on every step, or a script that calls feel.spawn in a loop, makes this. Fire it less often, "
                          "or spawn one prefab that holds the whole effect and give it a `lifetime`.");
    }
    FeelSpawn sp;
    sp.options = o;
    sp.position = e.is_null() ? o.offset : w.world_position(e) + (o.local ? local_to_world(w, e, o.offset) : o.offset);
    fs.spawns.push_back(std::move(sp));
    return {};
}

Result<void> feel_sound(World& w, Entity source, const SoundOptions& o) {
    if (!source.is_null() && !w.alive(source)) return bad_entity("sound", source, w);
    if (auto r = check_options(o); !r.ok()) return r;
    FeelState& fs = w.feel();
    if (fs.sounds.size() >= kMaxQueuedSounds) {
        const std::string text = std::format("more than {} sound actions waited for the audio system: the oldest were dropped. Nothing plays sounds in this world "
                                             "(no Audio::update), or a clip event / script fires `sound` on every step (fire it less often)", kMaxQueuedSounds);
        if (fs.warnedClipActions.size() < 64 && fs.warnedClipActions.insert(text).second) FA_WARN("feel", "{}", text);
        fs.sounds.erase(fs.sounds.begin());
    }
    fs.sounds.push_back({o, source.is_null() ? std::string() : w.id_of(source)});
    return {};
}

std::vector<FeelSound> feel_take_sounds(World& w) {
    std::vector<FeelSound> out;
    out.swap(w.feel().sounds);
    return out;
}

void feel_cancel(World& w, Entity e) {
    FeelState& fs = w.feel();
    if (e.is_null()) {
        fs.hitStops.clear();
        fs.entities.clear();
        fs.poseCount = 0;
        return;
    }
    auto it = fs.entities.find(e.bits());
    if (it == fs.entities.end()) return;
    if (it->second.hasPose && fs.poseCount > 0) --fs.poseCount;
    fs.entities.erase(it);
}

// ------------------------------------------------------------------------------------------------ JSON actions
const std::vector<std::string>& feel_action_names() {
    static const std::vector<std::string> names = {"shake", "hitStop", "flash", "knockback", "push", "squash", "spawn", "sound"};
    return names;
}

namespace {

struct Reader {
    const Json& a;
    std::string action;
    std::string error;

    bool number(const char* key, float& out) {
        auto it = a.find(key);
        if (it == a.end()) return true;
        std::string err;
        if (!it->is_number() || !json_to(*it, out, &err)) {
            error = std::format("{}: '{}' must be a number, got {}", action, key, describe_json_value(*it));
            return false;
        }
        return true;
    }
    bool optional_number(const char* key, std::optional<float>& out) {
        if (a.find(key) == a.end()) return true;
        float v = 0.0f;
        if (!number(key, v)) return false;
        out = v;
        return true;
    }
    bool boolean(const char* key, bool& out) {
        auto it = a.find(key);
        if (it == a.end()) return true;
        if (!it->is_boolean()) {
            error = std::format("{}: '{}' must be true or false, got {}", action, key, describe_json_value(*it));
            return false;
        }
        out = it->get<bool>();
        return true;
    }
    bool string(const char* key, std::string& out) {
        auto it = a.find(key);
        if (it == a.end()) return true;
        if (!it->is_string()) {
            error = std::format("{}: '{}' must be a string, got {}", action, key, describe_json_value(*it));
            return false;
        }
        out = it->get<std::string>();
        return true;
    }
    bool color(const char* key, Color& out) {
        auto it = a.find(key);
        if (it == a.end()) return true;
        std::string err;
        if (!json_to(*it, out, &err)) {
            error = std::format("{}: '{}' is not a colour: {}", action, key, err);
            return false;
        }
        return true;
    }
    bool vec(const char* key, Vec3& out) {
        auto it = a.find(key);
        if (it == a.end()) return true;
        if (it->is_array() && it->size() == 2 && (*it)[0].is_number() && (*it)[1].is_number()) {
            out = {(*it)[0].get<float>(), (*it)[1].get<float>(), 0.0f};
            return true;
        }
        std::string err;
        if (!json_to(*it, out, &err)) {
            error = std::format("{}: '{}' must be [x, y] or [x, y, z], got {}", action, key, describe_json_value(*it));
            return false;
        }
        return true;
    }
    bool keys(std::initializer_list<const char*> allowed) {
        std::vector<std::string> names;
        for (const char* k : allowed) names.push_back(k);
        names.push_back("action");
        for (auto it = a.begin(); it != a.end(); ++it) {
            if (std::find(names.begin(), names.end(), it.key()) != names.end()) continue;
            error = std::format("{}: unknown option '{}'. {}", action, it.key(), did_you_mean(it.key(), names));
            return false;
        }
        return true;
    }
};

// An action read and checked: its name as written and its options.
struct ParsedAction {
    std::string name;
    std::variant<ShakeOptions, HitStopOptions, FlashOptions, KnockbackOptions, SquashOptions, SpawnOptions, SoundOptions> options;
};

Result<ParsedAction> parse_action(const Json& action) {
    if (!action.is_object()) return make_error("feel action must be an object like {\"action\": \"shake\", \"amount\": 0.4}");
    auto it = action.find("action");
    if (it == action.end() || !it->is_string())
        return make_error("feel action needs an \"action\" string", "One of: " + join(feel_action_names(), ", ") + ".");
    ParsedAction out;
    out.name = it->get<std::string>();
    const std::string& name = out.name;
    Reader r{action, name, {}};
    auto fail = [&]() -> Result<ParsedAction> { return make_error(r.error); };
    auto checked = [&](auto o) -> Result<ParsedAction> {
        if (auto c = check_options(o); !c.ok()) return c.error();
        out.options = std::move(o);
        return out;
    };
    if (name == "shake") {
        ShakeOptions o;
        if (!r.keys({"amount", "duration", "frequency", "maxOffset", "maxAngle", "cap"}) || !r.number("amount", o.amount) ||
            !r.number("duration", o.duration) || !r.number("frequency", o.frequency) || !r.number("maxOffset", o.maxOffset) ||
            !r.number("maxAngle", o.maxAngle) || !r.number("cap", o.cap))
            return fail();
        return checked(o);
    }
    if (name == "hitStop") {
        HitStopOptions o;
        if (!r.keys({"duration", "scale"}) || !r.number("duration", o.duration) || !r.number("scale", o.scale)) return fail();
        return checked(o);
    }
    if (name == "flash") {
        FlashOptions o;
        if (!r.keys({"color", "duration", "fade", "strength"}) || !r.color("color", o.color) || !r.number("duration", o.duration) ||
            !r.boolean("fade", o.fade) || !r.number("strength", o.strength))
            return fail();
        return checked(o);
    }
    if (name == "knockback" || name == "push") {
        KnockbackOptions o;
        if (!r.keys({"direction", "speed", "lockTime", "decay", "local"}) || !r.vec("direction", o.direction) ||
            !r.optional_number("speed", o.speed) || !r.number("lockTime", o.lockTime) || !r.number("decay", o.decay) ||
            !r.boolean("local", o.local))
            return fail();
        return checked(o);
    }
    if (name == "squash") {
        SquashOptions o;
        if (!r.keys({"amount", "duration", "axis"}) || !r.number("amount", o.amount) || !r.number("duration", o.duration)) return fail();
        auto ax = action.find("axis");
        if (ax != action.end()) {
            if (!ax->is_string() || (ax->get<std::string>() != "x" && ax->get<std::string>() != "y"))
                return make_error(std::format("squash: 'axis' must be \"x\" or \"y\", got {}", describe_json_value(*ax)));
            o.axis = ax->get<std::string>()[0];
        }
        return checked(o);
    }
    if (name == "spawn") {
        SpawnOptions o;
        if (!r.keys({"prefab", "offset", "local", "lifetime"}) || !r.string("prefab", o.prefab) || !r.vec("offset", o.offset) ||
            !r.boolean("local", o.local) || !r.number("lifetime", o.lifetime))
            return fail();
        return checked(o);
    }
    if (name == "sound") {
        SoundOptions o;
        if (!r.keys({"path", "volume", "pitch", "pan", "bus"}) || !r.string("path", o.path) || !r.number("volume", o.volume) ||
            !r.number("pitch", o.pitch) || !r.number("pan", o.pan) || !r.string("bus", o.bus))
            return fail();
        return checked(o);
    }
    return make_error(std::format("unknown feel action '{}'. {}", name, did_you_mean(name, feel_action_names())));
}

}  // namespace

Result<void> feel_check_action(const Json& action) {
    auto parsed = parse_action(action);
    if (!parsed.ok()) return parsed.error();
    return {};
}

Result<void> feel_apply_action(World& w, Entity target, const Json& action) {
    auto parsed = parse_action(action);
    if (!parsed.ok()) return parsed.error();
    struct Run {
        World& w;
        Entity target;
        Result<void> operator()(const ShakeOptions& o) const { return feel_shake(w, target, o); }
        Result<void> operator()(const HitStopOptions& o) const { return feel_hit_stop(w, o); }
        Result<void> operator()(const FlashOptions& o) const { return feel_flash(w, target, o); }
        Result<void> operator()(const KnockbackOptions& o) const { return feel_knockback(w, target, o); }
        Result<void> operator()(const SquashOptions& o) const { return feel_squash(w, target, o); }
        Result<void> operator()(const SpawnOptions& o) const { return feel_spawn(w, target, o); }
        Result<void> operator()(const SoundOptions& o) const { return feel_sound(w, target, o); }
    };
    return std::visit(Run{w, target}, parsed->options);
}

std::vector<Json> feel_event_actions(const Json& event) {
    std::vector<Json> out;
    if (!event.is_object()) return out;
    auto it = event.find("feel");
    if (it == event.end()) return out;
    if (it->is_array()) out.assign(it->begin(), it->end());
    else if (it->is_object()) out.push_back(*it);
    return out;
}

void feel_run_clip_actions(World& w, Entity player, const std::vector<Json>& actions, std::string_view where) {
    for (const Json& a : actions) {
        const auto kind = a.is_object() ? a.find("action") : a.end();
        const bool shake = a.is_object() && kind != a.end() && kind->is_string() && kind->get<std::string>() == "shake";
        // The camera that plays the clip shakes itself; any other entity's clip shakes the main camera.
        const Entity target = shake && !w.has<Camera>(player) ? kNullEntity : player;
        Result<void> r = feel_apply_action(w, target, a);
        if (r.ok()) continue;
        FeelState& fs = w.feel();
        const std::string text = std::format("{}: {}", where, r.error().to_string());
        if (fs.warnedClipActions.size() < 64 && fs.warnedClipActions.insert(text).second) FA_WARN("feel", "{}", text);
    }
}

// --------------------------------------------------------------------------------------------------------- clocks
void feel_begin_frame(World& w, double realDt, bool systemReduceMotion) {
    FeelState& fs = w.feel();
    fs.systemReduceMotion = systemReduceMotion;
    if (fs.hitStops.empty()) return;
    const float dt = static_cast<float>(std::max(0.0, realDt));
    for (FeelHitStop& h : fs.hitStops) h.remaining -= dt;
    fs.hitStops.erase(std::remove_if(fs.hitStops.begin(), fs.hitStops.end(), [](const FeelHitStop& h) { return h.remaining <= 1e-6f; }),
                      fs.hitStops.end());
}

void feel_fixed_update(World& w, double dtd) {
    FeelState& fs = w.feel();
    if (fs.entities.empty()) return;
    const float dt = static_cast<float>(dtd);
    for (auto& [bits, rec] : fs.entities) {
        if (!rec.knock) continue;
        const Entity e = Entity::from_bits(bits);
        if (!w.alive(e)) continue;  // feel_update removes the record
        FeelKnock& k = *rec.knock;
        k.lockRemaining -= dt;
        if (length(k.velocity) > 0.0f) {
            w.set_world_position(e, w.world_position(e) + k.velocity * dt);
            k.velocity = k.velocity * std::exp(-k.decay * dt);
            if (length(k.velocity) < 0.01f) k.velocity = {};
        }
        if (k.lockRemaining <= 0.0f && length(k.velocity) == 0.0f) rec.knock.reset();
    }
}

namespace {

// Instantiates the queued `spawn` actions and destroys the effects whose lifetime is over. Outside any iteration of the world,
// which is why a spawn is queued by the action instead of made at once.
void run_spawns(World& w, float dt) {
    FeelState& fs = w.feel();
    for (FeelLifetime& l : fs.lifetimes) l.remaining -= dt;
    fs.lifetimes.erase(std::remove_if(fs.lifetimes.begin(), fs.lifetimes.end(),
                                      [&](const FeelLifetime& l) {
                                          const Entity e = Entity::from_bits(l.entity);
                                          if (!w.alive(e)) return true;
                                          if (l.remaining > 0.0f) return false;
                                          w.destroy(e);
                                          return true;
                                      }),
                       fs.lifetimes.end());
    if (fs.spawns.empty()) return;
    std::vector<FeelSpawn> todo;
    todo.swap(fs.spawns);  // a prefab's own scripts may queue more; they wait for the next frame
    for (const FeelSpawn& sp : todo) {
        LoadReport report;
        const Entity e = instantiate_prefab(w, sp.options.prefab, kNullEntity, report);
        if (!report.ok() || e.is_null()) {
            const std::string text = std::format("spawn '{}' failed: {}", sp.options.prefab, report.summary());
            if (fs.warnedClipActions.size() < 64 && fs.warnedClipActions.insert(text).second) FA_WARN("feel", "{}", text);
            // A prefab that loaded only in part (a child with a wrong component) must not stay in the scene: nothing owns it and no lifetime would end it.
            for (auto it = report.created.rbegin(); it != report.created.rend(); ++it)
                if (w.alive(*it) && !w.pending_destroy(*it)) w.destroy(*it);
            if (!e.is_null() && w.alive(e) && !w.pending_destroy(e)) w.destroy(e);
            continue;
        }
        for (Entity c : report.created) w.info(c).scriptSpawned = true;  // scene.save leaves them out: the action makes them again
        w.set_world_position(e, sp.position);
        if (sp.options.lifetime > 0.0f) fs.lifetimes.push_back({e.bits(), sp.options.lifetime});
    }
}

}  // namespace

void feel_update(World& w, double clockDtD, double gameDtD) {
    FeelState& fs = w.feel();
    const float dt = static_cast<float>(std::max(0.0, clockDtD));
    if (!fs.spawns.empty() || !fs.lifetimes.empty()) run_spawns(w, static_cast<float>(std::max(0.0, gameDtD)));
    if (fs.entities.empty()) {
        fs.poseCount = 0;
        return;
    }
    std::size_t poses = 0;
    for (auto it = fs.entities.begin(); it != fs.entities.end();) {
        FeelEntity& rec = it->second;
        const Entity e = Entity::from_bits(it->first);
        if (!w.alive(e)) {
            it = fs.entities.erase(it);
            continue;
        }
        if (rec.shake) {
            FeelShake& s = *rec.shake;
            s.phase += double(dt) * s.frequency;
            s.remaining -= dt;
            s.trauma = std::max(0.0f, s.trauma - s.decay * dt);
            if (s.trauma <= 0.0f || s.remaining <= 0.0f) rec.shake.reset();
        }
        if (rec.flash) {
            rec.flash->remaining -= dt;
            if (rec.flash->remaining <= 0.0f) rec.flash.reset();
        }
        if (rec.squash) {
            rec.squash->time += dt;
            if (rec.squash->time >= rec.squash->duration) rec.squash.reset();
        }
        FeelPose pose;
        bool any = false;
        if (rec.shake) {
            const FeelShake& s = *rec.shake;
            const float m = s.trauma * s.trauma;
            const float nx = feel_noise(s.seed, 0, s.phase), ny = feel_noise(s.seed, 1, s.phase), nz = feel_noise(s.seed, 2, s.phase);
            pose.position = {nx * s.maxOffset * m, ny * s.maxOffset * m, 0.0f};
            if (s.perspective) {
                pose.rotation = {feel_noise(s.seed, 3, s.phase) * s.maxAngle * m * 0.5f, feel_noise(s.seed, 4, s.phase) * s.maxAngle * m * 0.5f,
                                 nz * s.maxAngle * m};
            } else {
                pose.rotation = {0.0f, 0.0f, nz * s.maxAngle * m};
            }
            any = true;
        }
        if (rec.squash) {
            const FeelSquash& q = *rec.squash;
            const float u = std::clamp(q.time / q.duration, 0.0f, 1.0f);
            // 1 at the start, past 0 into a smaller swing the other way, settling at exactly 0: a spring that comes back.
            const float pulse = (1.0f - u) * (1.0f - u) * std::cos(3.0f * kPi * u);
            const float k = std::exp(q.amount * pulse);  // x * y stays 1 (with a mesh: x * y * z)
            const float other = q.volume3d ? std::sqrt(k) : 1.0f;
            if (q.axis == 'y') pose.scale = {q.volume3d ? other : k, 1.0f / k, other};
            else pose.scale = {1.0f / k, q.volume3d ? other : k, other};
            any = true;
        }
        rec.pose = pose;
        rec.hasPose = any;
        if (any) ++poses;
        if (!rec.shake && !rec.flash && !rec.squash && !rec.knock) it = fs.entities.erase(it);
        else ++it;
    }
    fs.poseCount = poses;
}

// ----------------------------------------------------------------------------------------------------- debug view
Json feel_state_json(const World& w) {
    const FeelState& fs = w.feel();
    Json j = Json::object();
    j["reduceMotion"] = fs.reduce_motion();
    j["reducedEffects"] = fs.reduced_effects();
    j["reduceMotionSetting"] = fs.reduceMotionSetting ? Json(*fs.reduceMotionSetting) : Json(nullptr);
    j["reducedEffectsSetting"] = fs.reducedEffectsSetting ? Json(*fs.reducedEffectsSetting) : Json(nullptr);
    j["hitStop"] = {{"remaining", fs.hit_stop_remaining()}, {"scale", fs.hit_stop_factor()}, {"running", fs.hitStops.size()}};
    j["queued"] = {{"sounds", fs.sounds.size()}, {"spawns", fs.spawns.size()}, {"spawnLifetimes", fs.lifetimes.size()}};
    Json list = Json::array();
    for (const auto& [bits, rec] : fs.entities) {
        const Entity e = Entity::from_bits(bits);
        if (!w.alive(e)) continue;
        Json o = Json::object();
        o["entity"] = w.id_of(e);
        if (rec.shake) o["shake"] = {{"trauma", rec.shake->trauma}, {"remaining", rec.shake->remaining}, {"maxOffset", rec.shake->maxOffset}};
        if (rec.flash) o["flash"] = {{"remaining", rec.flash->remaining}, {"strength", rec.flash->strength}, {"fade", rec.flash->fade}};
        if (rec.squash) o["squash"] = {{"amount", rec.squash->amount}, {"time", rec.squash->time}, {"duration", rec.squash->duration}};
        if (rec.knock)
            o["knockback"] = {{"remaining", std::max(0.0f, rec.knock->lockRemaining)}, {"velocity", to_json(rec.knock->velocity)}};
        if (rec.hasPose) o["pose"] = {{"position", to_json(rec.pose.position)}, {"rotation", to_json(rec.pose.rotation)}, {"scale", to_json(rec.pose.scale)}};
        list.push_back(std::move(o));
    }
    j["entities"] = std::move(list);
    return j;
}

}  // namespace fa
