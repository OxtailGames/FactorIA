#include "fa/scene/animation.h"
#include "fa/scene/anim_clip.h"
#include "fa/scene/feel.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <cstdlib>
#include <format>

#include "fa/core/fs.h"
#include "fa/core/jobs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/scene/anim3d.h"
#include "fa/scene/components.h"

#include "clip_animator.h"

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
    if (time >= times.back()) {
        k.i0 = k.i1 = n - 1;
        return k;
    }
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
            out[0] = q.x;
            out[1] = q.y;
            out[2] = q.z;
            out[3] = q.w;
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
    for (std::size_t j = 0; j < comps; ++j)
        out[j] = h00 * a[j] + h10 * k.span * m0[j] + h01 * b[j] + h11 * k.span * m1[j];
    if (comps == 4) {
        const Quat q = normalize(Quat{out[0], out[1], out[2], out[3]});
        out[0] = q.x;
        out[1] = q.y;
        out[2] = q.z;
        out[3] = q.w;
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
        if (c.path == AnimPath::Translation)
            pose.translation[n] = {v[0], v[1], v[2]};
        else if (c.path == AnimPath::Scale)
            pose.scale[n] = {v[0], v[1], v[2]};
        else
            pose.rotation[n] = normalize(Quat{v[0], v[1], v[2], v[3]});
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
        const Mat4 local = Mat4::translate(pose.translation[std::size_t(n)]) *
                           Mat4::from_quat(pose.rotation[std::size_t(n)]) * Mat4::scale(pose.scale[std::size_t(n)]);
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

std::string trim(std::string_view s) { return std::string(fa::trim(s)); }

// One term: `name`, `!name`, or `lhs op rhs` (op > >= < <= == !=; each side a number, true/false or a parameter).
bool eval_term(const std::string& term, const Json& values, const std::vector<std::string>& triggers) {
    static const char* const ops[] = {">=", "<=", "==", "!=", ">", "<"};
    for (const char* op : ops) {
        const std::size_t at = term.find(op);
        if (at == std::string::npos) continue;
        const double l = value_of(values, std::string(trim(term.substr(0, at)))),
                     r = value_of(values, std::string(trim(term.substr(at + std::strlen(op)))));
        const std::string o = op;
        return o == ">="   ? l >= r
               : o == "<=" ? l <= r
               : o == "==" ? l == r
               : o == "!=" ? l != r
               : o == ">"  ? l > r
                           : l < r;
    }
    std::string name = term;
    bool negate = false;
    if (!name.empty() && name[0] == '!') {
        negate = true;
        name = std::string(trim(std::string_view(name).substr(1)));
    }
    const bool trig = std::find(triggers.begin(), triggers.end(), name) != triggers.end();
    return (trig || value_of(values, name) != 0.0) != negate;
}

bool eval_condition(const std::string& expr, const Json& values, const std::vector<std::string>& triggers) {
    std::size_t start = 0;
    while (true) {
        const std::size_t at = expr.find("&&", start);
        const std::string term(
            trim(std::string_view(expr).substr(start, at == std::string::npos ? std::string::npos : at - start)));
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

// ---- clips: the glTF's own animations, then the 3D clip files of `clips` (rt.extraClips) ----

const AnimClip& clip_ref(const AnimatorRuntime& rt, int index) {
    const std::size_t own = rt.skeleton->clips.size();
    return std::size_t(index) < own ? rt.skeleton->clips[std::size_t(index)] : rt.extraClips[std::size_t(index) - own];
}

// Index of the clip called `name`: a clip file of `clips` first (it is the explicit choice), then the glTF's animations. -1 if none.
int find_clip_index(const AnimatorRuntime& rt, std::string_view name) {
    const std::size_t own = rt.skeleton->clips.size();
    for (std::size_t i = 0; i < rt.extraClips.size(); ++i)
        if (rt.extraClips[i].name == name) return int(own + i);
    return rt.skeleton->find_clip(name);
}

std::vector<std::string> all_clip_names(const AnimatorRuntime& rt) {
    std::vector<std::string> names = rt.skeleton->clip_names();
    for (const AnimClip& c : rt.extraClips) names.push_back(c.name);
    return names;
}

void warn_once(World& w, Entity e, Animator& a, const std::string& msg);
void clear_fade_forward(AnimatorRuntime& rt);

// Builds rt.extraClips from `clips` (name -> *.anim.json of format factoria.anim3d/1) for the skeleton in rt. Runs again when `clips`
// changes. A file that does not load, or a 2D clip, is skipped with one warning; a track on a bone the model lacks is dropped and said.
void sync_extra_clips(World& w, Entity e, Animator& a) {
    AnimatorRuntime& rt = a.rt;
    if (rt.extraClipsBuilt && rt.extraClipsFrom == a.clips) return;
    const std::string playing = rt.activeClip;
    const std::string fromName = rt.fromIndex >= 0 ? clip_ref(rt, rt.fromIndex).name : std::string();
    rt.extraClips.clear();
    rt.clipWarnings.clear();
    rt.extraClipsBuilt = true;
    rt.extraClipsFrom = a.clips;
    if (a.clips.is_object()) {
        for (auto it = a.clips.begin(); it != a.clips.end(); ++it) {
            if (!it.value().is_string() || it.value().get<std::string>().empty()) {
                rt.clipWarnings.push_back(
                    std::format("clip '{}': the value must be the path of a .anim.json file, got {}", it.key(),
                                describe_json_value(it.value())));
                continue;
            }
            const std::string path = it.value().get<std::string>();
            auto loaded = load_anim3d(path);
            if (!loaded) {
                rt.clipWarnings.push_back(std::format("clip '{}': {}", it.key(), loaded.error().to_string()));
                continue;
            }
            const Anim3DBinding binding = bind_anim3d(**loaded, *rt.skeleton);
            if (!binding.missing.empty()) {
                std::string list;
                for (std::size_t i = 0; i < binding.missing.size() && i < 6; ++i)
                    list += (i ? ", " : "") + binding.missing[i];
                if (binding.missing.size() > 6) list += std::format(" and {} more", binding.missing.size() - 6);
                rt.clipWarnings.push_back(std::format(
                    "clip '{}' ({}) drives bones the model '{}' does not have ({}); those tracks are skipped. "
                    "anim3d.retarget carries a clip over to another skeleton",
                    it.key(), path, rt.skeletonPath, list));
            }
            rt.extraClips.push_back(anim3d_to_anim_clip(**loaded, binding, *rt.skeleton, it.key()));
        }
    }
    for (const std::string& m : rt.clipWarnings) FA_WARN("animation", "entity '{}' Animator: {}", w.id_of(e), m);
    // The clip that plays may have a new index (or be gone).
    if (!playing.empty()) {
        rt.clipIndex = find_clip_index(rt, playing);
        if (rt.clipIndex < 0) rt.activeClip.clear();
    }
    if (rt.fromIndex >= 0) {
        rt.fromIndex = find_clip_index(rt, fromName);
        if (rt.fromIndex < 0) clear_fade_forward(rt);
    }
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
    if (path == a.rt.skeletonPath && a.rt.skeleton) {
        sync_extra_clips(w, e, a);
        return true;
    }
    if (path == a.rt.skeletonPath && !a.rt.skeleton) return fail("the model '" + path + "' could not be loaded");
    if (!ends_with(path, ".gltf") && !ends_with(path, ".glb"))
        return fail("'" + path + "' is not a .gltf/.glb file (a built-in shape has no skeleton)");
    a.rt.skeletonPath = path;
    a.rt.skeleton = nullptr;
    a.rt.extraClips.clear();
    a.rt.extraClipsBuilt = false;
    auto r = load_skeleton(path);
    if (!r) return fail(r.error().to_string());
    a.rt.skeleton = *r;
    sync_extra_clips(w, e, a);
    return true;
}

void clear_fade(AnimatorRuntime& rt) {
    rt.fromIndex = -1;
    rt.fadeElapsed = rt.fadeDuration = 0.0f;
}
void clear_fade_forward(AnimatorRuntime& rt) { clear_fade(rt); }

Result<void> play_clip(World& w, Entity e, Animator& a, std::string_view clip, float fade) {
    std::string why;
    if (!resolve_skeleton(w, e, a, &why)) return make_error("cannot play '" + std::string(clip) + "': " + why);
    AnimatorRuntime& rt = a.rt;
    const SkeletonAsset& sk = *rt.skeleton;
    const int idx = find_clip_index(rt, clip);
    if (idx < 0) {
        const std::vector<std::string> names = all_clip_names(rt);
        std::string hint =
            names.empty()
                ? "The file contains no animations; add 3D clips with Animator.clips (anim3d.generate makes one)."
                : did_you_mean(std::string(clip), names);
        for (const std::string& m : rt.clipWarnings) hint += " " + m + ".";
        return make_error(std::format("'{}' has no animation clip '{}'", sk.path, clip), hint);
    }
    if (rt.clipIndex == idx && a.playing && !rt.finished) {
        a.clip = rt.activeClip;
        return {};
    }
    if (fade > 0.0f && rt.clipIndex >= 0 && rt.clipIndex != idx) {
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
    if (clip_ref(rt, idx).loop >= 0 && !(a.states.is_object() && !a.states.empty()))
        a.loop = clip_ref(rt, idx).loop == 1;  // the clip file's own `loop`
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
        if (!r)
            warn_once(w, e, a, std::format("state '{}': {}", name, r.error().to_string()));
        else if (!it->contains("loop") && a.rt.clipIndex >= 0 && clip_ref(a.rt, a.rt.clipIndex).loop >= 0)
            a.loop = clip_ref(a.rt, a.rt.clipIndex).loop ==
                     1;  // a clip file's `loop` is the default of a state that does not say
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

// The game feel actions of an event that fired (feel.h): they act on the entity that plays the clip.
void run_feel(World& w, Entity e, const std::vector<Json>& actions, const std::string& clip, float time) {
    if (actions.empty()) return;
    feel_run_clip_actions(w, e, actions, std::format("Animator '{}' clip '{}' at {:.2f} s", w.id_of(e), clip, time));
}

void fire_events(World& w, Entity e, Animator& a, float from, float to) {
    struct Hit {
        float time;
        const Json* ev;
        const AnimClipEvent* own;
    };
    std::vector<Hit> hits;
    if (a.events.is_array())
        for (std::size_t index = 0; index < a.events.size(); ++index) {
            const Json& ev = a.events[index];
            if (!inline_event_usable(w, e, false, index, ev)) continue;  // a wrong JSON type: said once, skipped
            const auto cit = ev.find("clip");
            if (cit == ev.end() || cit->get<std::string>() != a.rt.activeClip) continue;
            const auto tit = ev.find("time");
            const float t = tit != ev.end() ? tit->get<float>() : 0.0f;
            if (t > from && t <= to) hits.push_back({t, &ev, nullptr});
        }
    if (a.rt.clipIndex >= 0)  // the events written in a 3D clip file
        for (const AnimClipEvent& ev : clip_ref(a.rt, a.rt.clipIndex).events)
            if (ev.time > from && ev.time <= to) hits.push_back({ev.time, nullptr, &ev});
    if (hits.empty()) return;
    std::stable_sort(hits.begin(), hits.end(), [](const Hit& x, const Hit& y) { return x.time < y.time; });
    for (const Hit& h : hits) {
        if (h.own) {
            Json data = h.own->data.is_object() ? h.own->data : Json::object();
            data["clip"] = a.rt.activeClip;
            data["time"] = h.time;
            if (!h.own->name.empty()) emit(w, h.own->name, e, std::move(data));
            run_feel(w, e, h.own->feel, a.rt.activeClip, h.time);
            continue;
        }
        const auto nit = h.ev->find("name");
        const std::string name = nit != h.ev->end() ? nit->get<std::string>() : std::string();
        if (!name.empty()) emit(w, name, e, Json::object({{"clip", a.rt.activeClip}, {"time", h.time}}));
        run_feel(w, e, feel_event_actions(*h.ev), a.rt.activeClip, h.time);
    }
}

void advance(World& w, Entity e, Animator& a, float dt) {
    AnimatorRuntime& rt = a.rt;
    const AnimClip& clip = clip_ref(rt, rt.clipIndex);
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
        const float fd = clip_ref(rt, rt.fromIndex).duration;
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
        sample_clip(sk, clip_ref(rt, rt.clipIndex), a.time, pose);
        if (rt.fromIndex >= 0 && rt.fadeDuration > 0.0f) {
            Pose from = rest_pose(sk);
            sample_clip(sk, clip_ref(rt, rt.fromIndex), rt.fromTime, from);
            pose = blend_poses(from, pose, std::clamp(rt.fadeElapsed / rt.fadeDuration, 0.0f, 1.0f));
        }
    }
    rt.pose = pose;
    animator_apply_pose(a, pose);
}

}  // namespace

void animator_apply_pose(Animator& a, const Pose& pose) {
    AnimatorRuntime& rt = a.rt;
    const SkeletonAsset& sk = *rt.skeleton;
    const std::vector<Mat4> globals = pose_globals(sk, pose);
    a.skinPalettes.resize(sk.skins.size());
    for (std::size_t si = 0; si < sk.skins.size(); ++si) {
        const SkelSkin& s = sk.skins[si];
        std::vector<Mat4>& out = a.skinPalettes[si];
        out.clear();
        for (std::size_t j = 0; j < s.joints.size(); ++j)
            out.push_back(globals[std::size_t(s.joints[j])] * s.inverseBind[j]);
    }
    a.palette = a.skinPalettes.empty() ? std::vector<Mat4>{} : a.skinPalettes[0];
}

namespace {

// One animator's step; true when its pose must be built again (update_animators builds the poses afterwards, as jobs).
bool update_one(World& w, Entity e, Animator& a, float dt) {
    AnimatorRuntime& rt = a.rt;
    std::string why;
    if (!resolve_skeleton(w, e, a, &why)) {
        warn_once(w, e, a, why);
        return false;
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
    return dirty;
}

// The poses of the animators that changed this step (every channel of their clips sampled, the blend of a fade, the
// skinning palettes) are built as jobs once this many skeleton nodes are to be posed and the pool has a worker thread,
// kPoseGrain animators per chunk: a node costs ~0.2 us, a chunk a few microseconds to hand out. A job writes only its
// own animators' pose and palettes, so the result is the same either way.
constexpr std::size_t kParallelPoseNodes = 512;
constexpr std::size_t kPoseGrain = 2;

}  // namespace

namespace animdetail {
bool condition_holds(const std::string& expr, const Json& values, const std::vector<std::string>& triggers) {
    return fa::eval_condition(expr, values, triggers);
}
void emit_game_event(World& w, const std::string& name, Entity source, Json data) {
    fa::emit(w, name, source, std::move(data));
}
}  // namespace animdetail

void update_animators(World& world, float dt) {
    // The state machines, clips, fades and events on this thread, in the order of the animators; then the poses.
    std::vector<Entity> posed;
    std::size_t nodes = 0;
    world.each<Animator>([&](Entity e, Animator& a) {
        if (!world.active_in_hierarchy(e)) return;
        if (clipanim::uses_clip_files(world, e, a))
            clipanim::update(world, e, a, dt);
        else if (update_one(world, e, a, dt)) {
            posed.push_back(e);
            nodes += a.rt.skeleton->nodes.size();
        }
    });
    if (posed.empty()) return;
    std::vector<Animator*> anims;
    anims.reserve(posed.size());
    for (Entity e : posed)
        if (Animator* a = world.get<Animator>(e); a && a->rt.skeleton) anims.push_back(a);
    if (nodes < kParallelPoseNodes || anims.size() < 2 || jobs::worker_count() == 0) {
        for (Animator* a : anims) build_palette(*a);
        return;
    }
    auto r = jobs::parallel_for("scene.animation_poses", anims.size(), kPoseGrain, [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i) build_palette(*anims[i]);
    });
    if (!r) FA_ERROR("animation", "building the poses of the animators failed: {}", r.error().message);
}

// ==================================================================================================== API ======

namespace {
Result<Animator*> animator_of(World& w, Entity e, const char* what) {
    Animator* a = w.get<Animator>(e);
    if (!a)
        return make_error(
            std::format("{}: entity '{}' has no Animator component", what, w.alive(e) ? w.id_of(e) : "?"),
            "Add one: entity.add(\"Animator\", {clip: \"Idle\"}) next to a MeshRenderer with a skinned glTF.");
    return a;
}
}  // namespace

Result<void> animator_play(World& w, Entity e, std::string_view clip, float fade) {
    auto a = animator_of(w, e, "animator.play");
    if (!a) return a.error();
    if (clipanim::uses_clip_files(w, e, **a)) return clipanim::play(w, e, **a, clip, std::max(0.0f, fade));
    return play_clip(w, e, **a, clip, std::max(0.0f, fade));
}

Result<void> animator_stop(World& w, Entity e) {
    auto an = animator_of(w, e, "animator.stop");
    if (!an) return an.error();
    Animator* a = *an;
    if (clipanim::uses_clip_files(w, e, *a)) return clipanim::stop(w, e, *a);
    a->clip.clear();
    a->rt.activeClip.clear();
    a->rt.clipIndex = -1;
    clear_fade(a->rt);
    a->time = a->rt.lastTime = 0.0f;
    a->playing = false;
    if (a->rt.skeleton) build_palette(*a);
    return {};
}

Result<void> animator_set(World& w, Entity e, std::string_view name, const Json& value) {
    auto a = animator_of(w, e, "animator.set");
    if (!a) return a.error();
    Animator& an = **a;
    if (!value.is_number() && !value.is_boolean())
        return make_error(std::format("animator.set('{}', {}): parameters are numbers or booleans", name,
                                      describe_json_value(value)));
    if (!an.values.is_object() || an.values.empty()) an.values = an.params.is_object() ? an.params : Json::object();
    if (!an.values.contains(std::string(name))) {
        std::vector<std::string> declared;
        for (auto it = an.values.begin(); it != an.values.end(); ++it) declared.push_back(it.key());
        return make_error(std::format("the Animator has no parameter '{}'", name),
                          declared.empty()
                              ? "Declare it in the Animator's `params`, e.g. {\"" + std::string(name) + "\": 0}."
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
    if (clipanim::uses_clip_files(w, e, **a)) return clipanim::clips(w, e, **a);
    std::string why;
    if (!resolve_skeleton(w, e, **a, &why)) return make_error("no clips: " + why);
    Json out = Json::array();
    for (const AnimClip& c : (*a)->rt.skeleton->clips)
        out.push_back(Json::object({{"name", c.name}, {"duration", c.duration}}));
    for (const AnimClip& c : (*a)->rt.extraClips) {  // 3D clip files
        Json o = Json::object({{"name", c.name}, {"duration", c.duration}});
        if (c.loop >= 0) o["loop"] = c.loop == 1;
        if (auto f = (*a)->clips.find(c.name); f != (*a)->clips.end()) o["file"] = *f;
        out.push_back(o);
    }
    return out;
}

namespace {
Result<Animator*> clip_animator_of(World& w, Entity e, const char* what) {
    auto a = animator_of(w, e, what);
    if (!a) return a.error();
    if (!clipanim::uses_clip_files(w, e, **a))
        return make_error(std::format("{}: this Animator does not play 2D clips", what),
                          "2D clips are the *.anim.json files of `clips` and need an Animator with no glTF model: "
                          "entity.add(\"Animator\", {clips: {walk: \"anim/walk.anim.json\"}, clip: \"walk\"}).");
    return a;
}
}  // namespace

Result<void> animator_sample(World& w, Entity e, std::string_view clip, float time) {
    auto a = clip_animator_of(w, e, "animator.sample");
    if (!a) return a.error();
    return clipanim::sample(w, e, **a, clip, time);
}

Result<void> animator_set_layer_weight(World& w, Entity e, std::string_view layer, float weight) {
    auto a = clip_animator_of(w, e, "animator.setLayerWeight");
    if (!a) return a.error();
    return clipanim::set_layer_weight(w, e, **a, layer, weight);
}

Result<void> animator_play_layer(World& w, Entity e, std::string_view layer, std::string_view clip, float fadeSeconds) {
    auto a = clip_animator_of(w, e, "animator.playLayer");
    if (!a) return a.error();
    return clipanim::play_layer(w, e, **a, layer, clip, std::max(0.0f, fadeSeconds));
}

}  // namespace fa
