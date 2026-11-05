// Game feel (feel.h): the state, the actions, the clocks and the noise of the shake.
#include "fa/scene/feel.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

namespace fa {

namespace {


bool finite(float v) { return std::isfinite(v); }

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
        if (cams.empty())
            return make_error("shake: the scene has no active camera to shake",
                              "Add an entity with a Camera component, or pass the entity to shake.");
        camera = cams.front();
    }
    if (!w.alive(camera)) return bad_entity("shake", camera, w);
    if (!finite(o.amount) || o.amount < 0.0f)
        return make_error(std::format("shake: amount must be a number from 0 to 1, got {}", o.amount),
                          "0.2 is a small bump, 0.5 a hit, 1 an explosion.");
    if (!finite(o.duration) || o.duration <= 0.0f)
        return make_error(std::format("shake: duration must be a number of seconds above 0, got {}", o.duration));
    if (!finite(o.frequency) || o.frequency <= 0.0f)
        return make_error(std::format("shake: frequency must be above 0, got {}", o.frequency), "Samples of noise per second; 25 is the default.");
    if (!finite(o.maxOffset) || o.maxOffset < 0.0f)
        return make_error(std::format("shake: maxOffset must be 0 (the camera's default) or more, got {}", o.maxOffset));
    if (!finite(o.maxAngle) || o.maxAngle < 0.0f)
        return make_error(std::format("shake: maxAngle must be 0 or more degrees, got {}", o.maxAngle));
    if (!finite(o.cap) || o.cap <= 0.0f || o.cap > 1.0f)
        return make_error(std::format("shake: cap must be above 0 and at most 1, got {}", o.cap));

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
    if (!finite(o.duration) || o.duration <= 0.0f)
        return make_error(std::format("hitStop: duration must be a number of seconds above 0, got {}", o.duration),
                          "0.05 to 0.12 is a hit; the stop runs in real time.");
    if (o.duration > kMaxHitStopSeconds)
        return make_error(std::format("hitStop: {} seconds is longer than the {} s limit", o.duration, kMaxHitStopSeconds),
                          "The duration is in seconds, not milliseconds.");
    if (!finite(o.scale) || o.scale < 0.0f || o.scale > 1.0f)
        return make_error(std::format("hitStop: scale must be from 0 (frozen) to 1 (no effect), got {}", o.scale));
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
    if (!finite(o.duration) || o.duration <= 0.0f)
        return make_error(std::format("flash: duration must be a number of seconds above 0, got {}", o.duration));
    if (!finite(o.strength) || o.strength < 0.0f || o.strength > 1.0f)
        return make_error(std::format("flash: strength must be from 0 to 1, got {}", o.strength));
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
    if (!finite(o.amount) || std::fabs(o.amount) > 1.5f)
        return make_error(std::format("squash: amount must be from -1.5 to 1.5, got {}", o.amount),
                          "Positive squashes (wider, flatter), negative stretches; 0.3 is a clear landing.");
    if (!finite(o.duration) || o.duration <= 0.0f)
        return make_error(std::format("squash: duration must be a number of seconds above 0, got {}", o.duration));
    if (o.axis != 'x' && o.axis != 'y') return make_error("squash: axis must be \"x\" or \"y\"");
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
    if (!finite(o.direction.x) || !finite(o.direction.y) || !finite(o.direction.z))
        return make_error("knockback: direction must be finite numbers");
    if (!finite(o.speed) || o.speed < 0.0f) return make_error(std::format("knockback: speed must be 0 or more, got {}", o.speed));
    if (!finite(o.lockTime) || o.lockTime < 0.0f)
        return make_error(std::format("knockback: lockTime must be 0 or more seconds, got {}", o.lockTime));
    if (!finite(o.decay) || o.decay < 0.0f) return make_error(std::format("knockback: decay must be 0 or more, got {}", o.decay));

    RigidBody2D* rb2 = w.get<RigidBody2D>(e);
    RigidBody3D* rb3 = w.get<RigidBody3D>(e);
    const bool body2 = rb2 && rb2->type == BodyType::Dynamic;
    const bool body3 = !body2 && rb3 && rb3->type == BodyType::Dynamic;
    Vec3 d = o.direction;
    if (body2) d.z = 0.0f;
    const float len = length(d);
    if (len < 1e-6f)
        return make_error("knockback: direction has no length" + std::string(body2 ? " (a 2D body ignores z)" : ""),
                          "Pass the way to push, e.g. the vector from the attacker to the victim: [1, 0] pushes right.");
    d = d * (1.0f / len);

    if (body2) {
        rb2->velocity = {rb2->velocity.x + d.x * o.speed, rb2->velocity.y + d.y * o.speed};
    } else if (body3) {
        rb3->velocity = rb3->velocity + d * o.speed;
    }
    FeelEntity& rec = record_of(w, e);
    FeelKnock k = rec.knock ? *rec.knock : FeelKnock{};
    if (!body2 && !body3) {
        k.velocity = d * o.speed;
        k.decay = o.decay;
    }
    k.lockRemaining = std::max(k.lockRemaining, o.lockTime);
    rec.knock = k;
    return {};
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
    static const std::vector<std::string> names = {"shake", "hitStop", "flash", "knockback", "squash"};
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

}  // namespace

Result<void> feel_apply_action(World& w, Entity target, const Json& action) {
    if (!action.is_object()) return make_error("feel action must be an object like {\"action\": \"shake\", \"amount\": 0.4}");
    auto it = action.find("action");
    if (it == action.end() || !it->is_string())
        return make_error("feel action needs an \"action\" string", "One of: " + join(feel_action_names(), ", ") + ".");
    const std::string name = it->get<std::string>();
    Reader r{action, name, {}};
    auto fail = [&]() -> Result<void> { return make_error(r.error); };
    if (name == "shake") {
        ShakeOptions o;
        if (!r.keys({"amount", "duration", "frequency", "maxOffset", "maxAngle", "cap"}) || !r.number("amount", o.amount) ||
            !r.number("duration", o.duration) || !r.number("frequency", o.frequency) || !r.number("maxOffset", o.maxOffset) ||
            !r.number("maxAngle", o.maxAngle) || !r.number("cap", o.cap))
            return fail();
        return feel_shake(w, target, o);
    }
    if (name == "hitStop") {
        HitStopOptions o;
        if (!r.keys({"duration", "scale"}) || !r.number("duration", o.duration) || !r.number("scale", o.scale)) return fail();
        return feel_hit_stop(w, o);
    }
    if (name == "flash") {
        FlashOptions o;
        if (!r.keys({"color", "duration", "fade", "strength"}) || !r.color("color", o.color) || !r.number("duration", o.duration) ||
            !r.boolean("fade", o.fade) || !r.number("strength", o.strength))
            return fail();
        return feel_flash(w, target, o);
    }
    if (name == "knockback") {
        KnockbackOptions o;
        if (!r.keys({"direction", "speed", "lockTime", "decay"}) || !r.vec("direction", o.direction) ||
            !r.number("speed", o.speed) || !r.number("lockTime", o.lockTime) || !r.number("decay", o.decay))
            return fail();
        return feel_knockback(w, target, o);
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
        return feel_squash(w, target, o);
    }
    return make_error(std::format("unknown feel action '{}'. {}", name, did_you_mean(name, feel_action_names())));
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

void feel_update(World& w, double clockDtD) {
    FeelState& fs = w.feel();
    if (fs.entities.empty()) {
        fs.poseCount = 0;
        return;
    }
    const float dt = static_cast<float>(std::max(0.0, clockDtD));
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
