#include "fa/scene/animation.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <cstdlib>
#include <format>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"

namespace fa {

// ================================================================================================ sampling ======

Pose rest_pose(const SkeletonAsset& sk) {
    Pose p;
    for (const SkelNode& n : sk.nodes) {
        p.translation.push_back(n.translation);
        p.rotation.push_back(n.rotation);
        p.scale.push_back(n.scale);
    }
    return p;
}

namespace {

struct Key {
    std::size_t i0 = 0, i1 = 0;  // keys around the time
    float t = 0.0f;              // 0..1 between them
    float span = 0.0f;           // seconds between them
};

Key find_key(const std::vector<float>& times, float time) {
    Key k;
    const std::size_t n = times.size();
    if (n == 0 || time <= times.front()) return k;
    if (time >= times.back()) { k.i0 = k.i1 = n - 1; return k; }
    // First key later than time; the one before it starts the span.
    const std::size_t hi = std::size_t(std::upper_bound(times.begin(), times.end(), time) - times.begin());
    k.i0 = hi - 1;
    k.i1 = hi;
    k.span = times[k.i1] - times[k.i0];
    k.t = k.span > 1e-9f ? (time - times[k.i0]) / k.span : 0.0f;
    return k;
}

// Reads the `comps` floats of the value (not the tangents) of key i.
void value_at(const AnimChannel& c, std::size_t comps, std::size_t i, float* out) {
    const std::size_t base = (c.interp == AnimInterp::CubicSpline ? i * 3 + 1 : i) * comps;
    for (std::size_t k = 0; k < comps; ++k) out[k] = c.values[base + k];
}
void tangent_at(const AnimChannel& c, std::size_t comps, std::size_t i, bool out, float* dst) {
    const std::size_t base = (i * 3 + (out ? 2 : 0)) * comps;
    for (std::size_t k = 0; k < comps; ++k) dst[k] = c.values[base + k];
}

// The value of a channel at `time`, comps floats (3 or 4).
void sample_channel(const AnimChannel& c, float time, float* out) {
    const std::size_t comps = c.path == AnimPath::Rotation ? 4 : 3;
    const Key k = find_key(c.times, time);
    float a[4], b[4];
    value_at(c, comps, k.i0, a);
    if (k.i0 == k.i1 || c.interp == AnimInterp::Step) {
        for (std::size_t j = 0; j < comps; ++j) out[j] = a[j];
        return;
    }
    value_at(c, comps, k.i1, b);
    if (c.interp == AnimInterp::Linear) {
        if (comps == 4) {
            const Quat q = slerp(Quat{a[0], a[1], a[2], a[3]}, Quat{b[0], b[1], b[2], b[3]}, k.t);
            out[0] = q.x; out[1] = q.y; out[2] = q.z; out[3] = q.w;
        } else {
            for (std::size_t j = 0; j < 3; ++j) out[j] = a[j] + (b[j] - a[j]) * k.t;
        }
        return;
    }
    // CUBICSPLINE: Hermite with the out tangent of the first key and the in tangent of the second, scaled by the span.
    float m0[4], m1[4];
    tangent_at(c, comps, k.i0, true, m0);
    tangent_at(c, comps, k.i1, false, m1);
    const float t = k.t, t2 = t * t, t3 = t2 * t;
    const float h00 = 2 * t3 - 3 * t2 + 1, h10 = t3 - 2 * t2 + t, h01 = -2 * t3 + 3 * t2, h11 = t3 - t2;
    for (std::size_t j = 0; j < comps; ++j) out[j] = h00 * a[j] + h10 * k.span * m0[j] + h01 * b[j] + h11 * k.span * m1[j];
    if (comps == 4) {
        const Quat q = normalize(Quat{out[0], out[1], out[2], out[3]});
        out[0] = q.x; out[1] = q.y; out[2] = q.z; out[3] = q.w;
    }
}

}  // namespace

void sample_clip(const SkeletonAsset& sk, const AnimClip& clip, float time, Pose& pose) {
    time = std::clamp(time, 0.0f, clip.duration);
    for (const AnimChannel& c : clip.channels) {
        if (c.node < 0 || std::size_t(c.node) >= sk.nodes.size() || c.times.empty()) continue;
        float v[4];
        sample_channel(c, time, v);
        const std::size_t n = std::size_t(c.node);
        if (c.path == AnimPath::Translation) pose.translation[n] = {v[0], v[1], v[2]};
        else if (c.path == AnimPath::Scale) pose.scale[n] = {v[0], v[1], v[2]};
        else pose.rotation[n] = normalize(Quat{v[0], v[1], v[2], v[3]});
    }
}

Pose blend_poses(const Pose& a, const Pose& b, float w) {
    Pose r = a;
    for (std::size_t i = 0; i < a.translation.size(); ++i) {
        r.translation[i] = a.translation[i] + (b.translation[i] - a.translation[i]) * w;
        r.scale[i] = a.scale[i] + (b.scale[i] - a.scale[i]) * w;
        r.rotation[i] = slerp(a.rotation[i], b.rotation[i], w);
    }
    return r;
}

std::vector<Mat4> pose_globals(const SkeletonAsset& sk, const Pose& pose) {
    std::vector<Mat4> g(sk.nodes.size());
    for (int n : sk.order) {
        const Mat4 local = Mat4::translate(pose.translation[std::size_t(n)]) * Mat4::from_quat(pose.rotation[std::size_t(n)]) *
                           Mat4::scale(pose.scale[std::size_t(n)]);
        const int p = sk.nodes[std::size_t(n)].parent;
        g[std::size_t(n)] = p < 0 ? local : g[std::size_t(p)] * local;
    }
    return g;
}

std::vector<Mat4> skin_palette(const SkeletonAsset& sk, const Pose& pose, int skin) {
    std::vector<Mat4> out;
    if (skin < 0 || std::size_t(skin) >= sk.skins.size()) return out;
    const std::vector<Mat4> g = pose_globals(sk, pose);
    const SkelSkin& s = sk.skins[std::size_t(skin)];
    for (std::size_t j = 0; j < s.joints.size(); ++j) out.push_back(g[std::size_t(s.joints[j])] * s.inverseBind[j]);
    return out;
}

// ============================================================================================ state machine ======

namespace {

double value_of(const Json& values, const std::string& token) {
    if (token == "true") return 1.0;
    if (token == "false") return 0.0;
    char* end = nullptr;
    const double d = std::strtod(token.c_str(), &end);
    if (end != token.c_str() && *end == 0) return d;
    auto it = values.find(token);
    if (it == values.end()) return 0.0;
    if (it->is_boolean()) return it->get<bool>() ? 1.0 : 0.0;
    return it->is_number() ? it->get<double>() : 0.0;
}

std::string trim(std::string s) {
    const auto notSpace = [](unsigned char c) { return !std::isspace(c); };
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), notSpace));
    s.erase(std::find_if(s.rbegin(), s.rend(), notSpace).base(), s.end());
    return s;
}

// One term: `name`, `!name`, or `lhs op rhs` (op > >= < <= == !=; each side a number, true/false or a parameter).
bool eval_term(const std::string& term, const Json& values, const std::vector<std::string>& triggers) {
    static const char* const ops[] = {">=", "<=", "==", "!=", ">", "<"};
    for (const char* op : ops) {
        const std::size_t at = term.find(op);
        if (at == std::string::npos) continue;
        const double l = value_of(values, trim(term.substr(0, at))), r = value_of(values, trim(term.substr(at + std::strlen(op))));
        const std::string o = op;
        return o == ">=" ? l >= r : o == "<=" ? l <= r : o == "==" ? l == r : o == "!=" ? l != r : o == ">" ? l > r : l < r;
    }
    std::string name = term;
    bool negate = false;
    if (!name.empty() && name[0] == '!') { negate = true; name = trim(name.substr(1)); }
    const bool trig = std::find(triggers.begin(), triggers.end(), name) != triggers.end();
    return (trig || value_of(values, name) != 0.0) != negate;
}

bool eval_condition(const std::string& expr, const Json& values, const std::vector<std::string>& triggers) {
    std::size_t start = 0;
    while (true) {
        const std::size_t at = expr.find("&&", start);
        const std::string term = trim(expr.substr(start, at == std::string::npos ? std::string::npos : at - start));
        if (!term.empty() && !eval_term(term, values, triggers)) return false;
        if (at == std::string::npos) return true;
        start = at + 2;
    }
}

void emit(World& w, const std::string& name, Entity source, Json data) {
    data["id"] = w.id_of(source);
    w.events().game.push_back(GameEvent{name, std::move(data), source});
}

void warn_once(World& w, Entity e, Animator& a, const std::string& msg) {
    if (a.rt.warned) return;
    a.rt.warned = true;
    FA_WARN("animation", "entity '{}' Animator: {}", w.id_of(e), msg);
}

// The skeleton to play: `model`, else the mesh of the MeshRenderer on the entity. Null when there is none.
bool resolve_skeleton(World& w, Entity e, Animator& a, std::string* why = nullptr) {
    std::string path = a.model;
    if (path.empty()) {
        if (const MeshRenderer* mr = w.get<MeshRenderer>(e)) path = mr->mesh;
    }
    auto fail = [&](std::string m) {
        if (why) *why = std::move(m);
        return false;
    };
    if (path.empty()) return fail("no model: add a MeshRenderer whose `mesh` is a .gltf/.glb file, or set `model`");
    if (path == a.rt.skeletonPath && a.rt.skeleton) return true;
    if (path == a.rt.skeletonPath && !a.rt.skeleton) return fail("the model '" + path + "' could not be loaded");
    const std::string ext = path.size() > 5 ? path.substr(path.size() - 5) : "";
    const std::string ext4 = path.size() > 4 ? path.substr(path.size() - 4) : "";
    if (ext != ".gltf" && ext4 != ".glb") return fail("'" + path + "' is not a .gltf/.glb file (a built-in shape has no skeleton)");
    a.rt.skeletonPath = path;
    a.rt.skeleton = nullptr;
    auto r = load_skeleton(path);
    if (!r) return fail(r.error().to_string());
    a.rt.skeleton = *r;
    return true;
}

void clear_fade(AnimatorRuntime& rt) {
    rt.fromClip.clear();
    rt.fromIndex = -1;
    rt.fadeElapsed = rt.fadeDuration = 0.0f;
}

Result<void> play_clip(World& w, Entity e, Animator& a, std::string_view clip, float fade) {
    std::string why;
    if (!resolve_skeleton(w, e, a, &why)) return make_error("cannot play '" + std::string(clip) + "': " + why);
    AnimatorRuntime& rt = a.rt;
    const SkeletonAsset& sk = *rt.skeleton;
    const int idx = sk.find_clip(clip);
    if (idx < 0) {
        const std::vector<std::string> names = sk.clip_names();
        return make_error(std::format("'{}' has no animation clip '{}'", sk.path, clip),
                          names.empty() ? "The file contains no animations."
                                        : did_you_mean(std::string(clip), names));
    }
    if (rt.clipIndex == idx && a.playing && !rt.finished) {
        a.clip = rt.activeClip;
        return {};
    }
    if (fade > 0.0f && rt.clipIndex >= 0 && rt.clipIndex != idx) {
        rt.fromClip = rt.activeClip;
        rt.fromIndex = rt.clipIndex;
        rt.fromTime = a.time;
        rt.fromLoop = a.loop;
        rt.fadeElapsed = 0.0f;
        rt.fadeDuration = fade;
    } else {
        clear_fade(rt);
    }
    rt.activeClip = a.clip = std::string(clip);
    rt.clipIndex = idx;
    rt.prevTime = -1.0f;
    rt.finished = false;
    a.time = rt.lastTime = 0.0f;
    a.playing = true;
    return {};
}

void enter_state(World& w, Entity e, Animator& a, const std::string& name, float fade) {
    auto it = a.states.find(name);
    if (it == a.states.end() || !it->is_object()) {
        warn_once(w, e, a, std::format("state '{}' is not in `states`", name));
        return;
    }
    const std::string prev = a.state;
    a.state = name;
    a.loop = it->value("loop", true);
    a.speed = it->value("speed", 1.0f);
    const std::string clip = it->value("clip", "");
    if (!clip.empty()) {
        auto r = play_clip(w, e, a, clip, fade);
        if (!r) warn_once(w, e, a, std::format("state '{}': {}", name, r.error().to_string()));
    }
    const std::string onEnter = it->value("onEnter", "");
    if (!onEnter.empty()) emit(w, onEnter, e, Json::object({{"state", name}, {"from", prev}}));
}

void run_state_machine(World& w, Entity e, Animator& a) {
    if (!a.states.is_object() || a.states.empty() || !a.transitions.is_array()) return;
    for (const Json& t : a.transitions) {
        if (!t.is_object()) continue;
        const std::string from = t.value("from", "*"), to = t.value("to", "");
        if (to.empty() || to == a.state) continue;
        if (from != "*" && from != a.state) continue;
        const bool onFinish = t.value("onFinish", false);
        const std::string when = t.value("when", "");
        if (onFinish && !a.rt.finished) continue;
        if (!onFinish && when.empty()) continue;  // a transition with no condition would fire every step
        if (!when.empty() && !eval_condition(when, a.values, a.rt.triggers)) continue;
        enter_state(w, e, a, to, t.value("fade", 0.2f));
        return;
    }
}

// ================================================================================================== playback ======

void fire_events(World& w, Entity e, Animator& a, float from, float to) {
    if (!a.events.is_array() || a.events.empty()) return;
    struct Hit { float time; const Json* ev; };
    std::vector<Hit> hits;
    for (const Json& ev : a.events) {
        if (!ev.is_object() || ev.value("clip", "") != a.rt.activeClip) continue;
        const float t = ev.value("time", 0.0f);
        if (t > from && t <= to) hits.push_back({t, &ev});
    }
    std::stable_sort(hits.begin(), hits.end(), [](const Hit& x, const Hit& y) { return x.time < y.time; });
    for (const Hit& h : hits) {
        const std::string name = h.ev->value("name", "");
        if (!name.empty()) emit(w, name, e, Json::object({{"clip", a.rt.activeClip}, {"time", h.time}}));
    }
}

void advance(World& w, Entity e, Animator& a, float dt) {
    AnimatorRuntime& rt = a.rt;
    const AnimClip& clip = rt.skeleton->clips[std::size_t(rt.clipIndex)];
    const float dur = clip.duration;
    const float step = dt * std::max(0.0f, a.speed);
    float t = a.time + step;
    if (dur <= 0.0f) {
        if (!rt.finished && step > 0.0f) fire_events(w, e, a, rt.prevTime, 0.0f);
        a.time = 0.0f;
        rt.prevTime = 0.0f;
    } else if (a.loop) {
        int guard = 0;
        while (t >= dur && step > 0.0f && ++guard < 1000) {
            fire_events(w, e, a, rt.prevTime, dur);
            rt.prevTime = -1.0f;
            t -= dur;
        }
        if (step > 0.0f) fire_events(w, e, a, rt.prevTime, t);
        a.time = t;
        rt.prevTime = t;
    } else if (!rt.finished) {
        if (t >= dur) {
            fire_events(w, e, a, rt.prevTime, dur);
            a.time = dur;
            rt.prevTime = dur;
            rt.finished = true;
            a.playing = false;
            emit(w, "anim.finished", e, Json::object({{"clip", rt.activeClip}}));
        } else {
            if (step > 0.0f) fire_events(w, e, a, rt.prevTime, t);
            a.time = t;
            rt.prevTime = t;
        }
    }
    rt.lastTime = a.time;
    if (rt.fromIndex >= 0) {
        const float fd = rt.skeleton->clips[std::size_t(rt.fromIndex)].duration;
        rt.fromTime += step;
        if (fd > 0.0f) rt.fromTime = rt.fromLoop ? std::fmod(rt.fromTime, fd) : std::min(rt.fromTime, fd);
        rt.fadeElapsed += dt;
        if (rt.fadeElapsed >= rt.fadeDuration) clear_fade(rt);
    }
}

void build_palette(Animator& a) {
    AnimatorRuntime& rt = a.rt;
    const SkeletonAsset& sk = *rt.skeleton;
    Pose pose = rest_pose(sk);
    if (rt.clipIndex >= 0) {
        sample_clip(sk, sk.clips[std::size_t(rt.clipIndex)], a.time, pose);
        if (rt.fromIndex >= 0 && rt.fadeDuration > 0.0f) {
            Pose from = rest_pose(sk);
            sample_clip(sk, sk.clips[std::size_t(rt.fromIndex)], rt.fromTime, from);
            pose = blend_poses(from, pose, std::clamp(rt.fadeElapsed / rt.fadeDuration, 0.0f, 1.0f));
        }
    }
    a.palette = skin_palette(sk, pose, 0);
}

void update_one(World& w, Entity e, Animator& a, float dt) {
    AnimatorRuntime& rt = a.rt;
    std::string why;
    if (!resolve_skeleton(w, e, a, &why)) {
        warn_once(w, e, a, why);
        return;
    }
    bool dirty = a.palette.empty();
    if (!rt.started) {
        rt.started = true;
        dirty = true;
        if (a.values.empty() && a.params.is_object()) a.values = a.params;
        if (a.states.is_object() && !a.states.empty()) {
            std::string first = a.states.begin().key();
            enter_state(w, e, a, a.states.contains(a.state) ? a.state : first, 0.0f);
        } else if (!a.clip.empty()) {
            auto r = play_clip(w, e, a, a.clip, 0.0f);
            if (!r) warn_once(w, e, a, r.error().to_string());
        }
    } else {
        if (a.clip != rt.activeClip) {
            dirty = true;
            if (a.clip.empty()) {
                rt.activeClip.clear();
                rt.clipIndex = -1;
                clear_fade(rt);
                a.time = rt.lastTime = 0.0f;
            } else {
                auto r = play_clip(w, e, a, a.clip, a.fade);
                if (!r) {
                    warn_once(w, e, a, r.error().to_string());
                    a.clip = rt.activeClip;
                }
            }
        }
        if (a.time != rt.lastTime) {  // a script seeked: no events for the jump
            rt.prevTime = a.time;
            rt.lastTime = a.time;
            dirty = true;
        }
    }
    const std::string stateBefore = a.state;
    run_state_machine(w, e, a);
    if (a.state != stateBefore) dirty = true;
    if (a.playing && rt.clipIndex >= 0 && dt > 0.0f) {
        advance(w, e, a, dt);
        dirty = true;
    }
    rt.triggers.clear();
    if (dirty) build_palette(a);
}

}  // namespace

void update_animators(World& world, float dt) {
    world.each<Animator>([&](Entity e, Animator& a) {
        if (!world.active_in_hierarchy(e)) return;
        update_one(world, e, a, dt);
    });
}

// ==================================================================================================== API ======

namespace {
Result<Animator*> animator_of(World& w, Entity e, const char* what) {
    Animator* a = w.get<Animator>(e);
    if (!a) return make_error(std::format("{}: entity '{}' has no Animator component", what, w.alive(e) ? w.id_of(e) : "?"),
                              "Add one: entity.add(\"Animator\", {clip: \"Idle\"}) next to a MeshRenderer with a skinned glTF.");
    return a;
}
}  // namespace

Result<void> animator_play(World& w, Entity e, std::string_view clip, float fade) {
    auto a = animator_of(w, e, "animator.play");
    if (!a) return a.error();
    return play_clip(w, e, **a, clip, std::max(0.0f, fade));
}

void animator_stop(World& w, Entity e) {
    Animator* a = w.get<Animator>(e);
    if (!a) return;
    a->clip.clear();
    a->rt.activeClip.clear();
    a->rt.clipIndex = -1;
    clear_fade(a->rt);
    a->time = a->rt.lastTime = 0.0f;
    a->playing = false;
    if (a->rt.skeleton) build_palette(*a);
}

Result<void> animator_set(World& w, Entity e, std::string_view name, const Json& value) {
    auto a = animator_of(w, e, "animator.set");
    if (!a) return a.error();
    Animator& an = **a;
    if (!value.is_number() && !value.is_boolean())
        return make_error(std::format("animator.set('{}', {}): parameters are numbers or booleans", name, describe_json_value(value)));
    if (!an.values.is_object() || an.values.empty()) an.values = an.params.is_object() ? an.params : Json::object();
    if (!an.values.contains(std::string(name))) {
        std::vector<std::string> declared;
        for (auto it = an.values.begin(); it != an.values.end(); ++it) declared.push_back(it.key());
        return make_error(std::format("the Animator has no parameter '{}'", name),
                          declared.empty() ? "Declare it in the Animator's `params`, e.g. {\"" + std::string(name) + "\": 0}."
                                           : did_you_mean(std::string(name), declared));
    }
    an.values[std::string(name)] = value;
    return {};
}

Result<void> animator_trigger(World& w, Entity e, std::string_view name) {
    auto a = animator_of(w, e, "animator.trigger");
    if (!a) return a.error();
    (*a)->rt.triggers.emplace_back(name);
    return {};
}

Result<Json> animator_clips(World& w, Entity e) {
    auto a = animator_of(w, e, "animator.clips");
    if (!a) return a.error();
    std::string why;
    if (!resolve_skeleton(w, e, **a, &why)) return make_error("no clips: " + why);
    Json out = Json::array();
    for (const AnimClip& c : (*a)->rt.skeleton->clips) out.push_back(Json::object({{"name", c.name}, {"duration", c.duration}}));
    return out;
}

}  // namespace fa
