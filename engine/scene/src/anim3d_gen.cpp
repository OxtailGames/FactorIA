#include "fa/scene/anim3d_gen.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <functional>

#include "fa/core/det_math.h"
#include "fa/core/strings.h"
#include "fa/scene/ik3d.h"

namespace fa {

namespace {

constexpr float kPi = 3.14159265358979f;

float frac(float x) { return x - std::floor(x); }
float sin_t(float turns) { return det::sin(2.0f * kPi * frac(turns)); }
float cos_t(float turns) { return det::cos(2.0f * kPi * frac(turns)); }
float smoother(float x) {
    x = clamp(x, 0.0f, 1.0f);
    return x * x * x * (x * (x * 6.0f - 15.0f) + 10.0f);
}
float smooth(float x) {
    x = clamp(x, 0.0f, 1.0f);
    return x * x * (3.0f - 2.0f * x);
}

// ----------------------------------------------------------------------------------------------------- parameters --
struct Params {
    const Json& in;
    Json resolved = Json::object();
    std::vector<std::string> names;
    std::string error, hint;
    explicit Params(const Json& j) : in(j) {}
    void fail(std::string msg, std::string h) {
        if (error.empty()) { error = std::move(msg); hint = std::move(h); }
    }
    float num(const std::string& name, float def, float lo, float hi) {
        names.push_back(name);
        float v = def;
        auto it = in.find(name);
        if (it != in.end()) {
            if (!it->is_number() || !std::isfinite(it->get<double>())) {
                fail(std::format("parameter '{}' must be a number, got {}", name, describe_json_value(*it)),
                     std::format("Write a number from {} to {}.", lo, hi));
            } else {
                v = it->get<float>();
                if (v < lo || v > hi) {
                    fail(std::format("parameter '{}' is {} but must be from {} to {}", name, v, lo, hi), "Use a value inside that range.");
                    v = def;
                }
            }
        }
        resolved[name] = double(std::stod(std::format("{:.7g}", v)));
        return v;
    }
    std::string str(const std::string& name, const std::string& def, const std::vector<std::string>& allowed = {}) {
        names.push_back(name);
        std::string v = def;
        auto it = in.find(name);
        if (it != in.end()) {
            if (!it->is_string()) fail(std::format("parameter '{}' must be a string, got {}", name, describe_json_value(*it)), "Write a string.");
            else {
                v = it->get<std::string>();
                if (!allowed.empty() && std::find(allowed.begin(), allowed.end(), v) == allowed.end()) {
                    fail(std::format("parameter '{}' is \"{}\", which is not one of its values", name, v), did_you_mean(v, allowed));
                    v = def;
                }
            }
        }
        resolved[name] = v;
        return v;
    }
    std::vector<std::string> list(const std::string& name, const std::vector<std::string>& def) {
        names.push_back(name);
        std::vector<std::string> v = def;
        auto it = in.find(name);
        if (it != in.end()) {
            bool ok = it->is_array();
            std::vector<std::string> got;
            if (ok)
                for (const Json& e : *it) {
                    if (!e.is_string()) { ok = false; break; }
                    got.push_back(e.get<std::string>());
                }
            if (ok) v = got;
            else fail(std::format("parameter '{}' must be an array of strings, got {}", name, describe_json_value(*it)),
                      "Write role names or bone names: [\"tail\"].");
        }
        resolved[name] = v;
        return v;
    }
    Result<void> finish() {
        for (auto it = in.begin(); it != in.end(); ++it)
            if (std::find(names.begin(), names.end(), it.key()) == names.end())
                fail(std::format("unknown parameter '{}'", it.key()), did_you_mean(it.key(), names));
        if (!error.empty()) return make_error(error, hint);
        return {};
    }
};

// ------------------------------------------------------------------------------------------------------ clip builder --
using PoseFn = std::function<void(float u, float t, Pose& pose)>;

Anim3DClip build_clip(const Rig3D& rig, float duration, float fps, bool loop, const PoseFn& posing) {
    Anim3DClip clip;
    clip.duration = duration;
    clip.loop = loop;
    clip.templateName = rig.templateName;
    clip.rig = rig.skeleton->path;
    const int n = std::max(2, int(std::ceil(duration * fps - 1e-4f)));
    const std::size_t nodes = rig.skeleton->nodes.size();
    std::vector<std::vector<Vec3>> rot(nodes), tr(nodes);
    std::vector<float> times;
    for (int i = 0; i <= n; ++i) {
        const float u = float(i) / float(n);
        const float t = i == n ? duration : duration * u;
        times.push_back(t);
        Pose pose = rig.rest;
        posing(u, t, pose);
        for (int node : rig.bones) {
            const std::size_t k = std::size_t(node);
            const Quat d = normalize(rig.rest.rotation[k].conjugate() * pose.rotation[k]);
            rot[k].push_back(d.to_euler_deg());
            tr[k].push_back(pose.translation[k] - rig.rest.translation[k]);
        }
    }
    for (int node : rig.bones) {
        const std::size_t k = std::size_t(node);
        const std::string& name = rig.skeleton->nodes[k].name;
        float dev = 0.0f, tdev = 0.0f;
        for (const Vec3& e : rot[k]) dev = std::max({dev, std::fabs(e.x), std::fabs(e.y), std::fabs(e.z)});
        for (const Vec3& v : tr[k]) tdev = std::max({tdev, std::fabs(v.x), std::fabs(v.y), std::fabs(v.z)});
        if (dev > 1e-3f) {
            Anim3DTrack track;
            track.bone = name;
            track.channel = Anim3DChannel::Rotation;
            Vec3 prev{};
            for (std::size_t i = 0; i < rot[k].size(); ++i) {
                Vec3 e = rot[k][i];
                if (i > 0) {  // keep each angle within 180 degrees of the previous key, so linear keys take the short way
                    auto wrap = [](float v, float p) { while (v - p > 180.0f) v -= 360.0f; while (v - p < -180.0f) v += 360.0f; return v; };
                    e = {wrap(e.x, prev.x), wrap(e.y, prev.y), wrap(e.z, prev.z)};
                }
                prev = e;
                ClipKey key;
                key.t = times[i];
                key.value = {e.x, e.y, e.z, 0.0f};
                track.keys.push_back(key);
            }
            clip.tracks.push_back(std::move(track));
        }
        if (tdev > 1e-6f) {
            Anim3DTrack track;
            track.bone = name;
            track.channel = Anim3DChannel::Translation;
            for (std::size_t i = 0; i < tr[k].size(); ++i) {
                ClipKey key;
                key.t = times[i];
                key.value = {tr[k][i].x, tr[k][i].y, tr[k][i].z, 0.0f};
                track.keys.push_back(key);
            }
            clip.tracks.push_back(std::move(track));
        }
    }
    return clip;
}

void set_euler(Pose& pose, int node, Vec3 e) { pose.rotation[std::size_t(node)] = Quat::from_euler_deg(e); }

// Points `node` along `dir` (model space) by turning it from its rest direction.
void aim(const Rig3D& rig, Pose& pose, PoseFrame& frame, int node, Vec3 dir) {
    if (length_sq(rig.axis[std::size_t(node)]) < 0.5f) return;
    set_global_rotation(*rig.skeleton, pose, frame, node, rotation_between(rig.axis[std::size_t(node)], dir));
}

int first_of(const Rig3D& rig, const char* role, const std::string& side) {
    const auto c = rig.chain(role, side);
    return c.empty() ? -1 : c.front();
}

std::string generator_name(const std::string& kind) { return "anim3d.generate " + kind; }

// --------------------------------------------------------------------------------------------------------- gaits ----
struct Leg {
    int a = -1, b = -1, c = -1;
    float phase = 0.0f;
    bool front = false;
    float poleSign = 1.0f;
    Vec3 restFoot{};
    float len = 0.0f;
    std::string name;  // the end bone, for contacts
};

struct GaitDefaults {
    float duty, stride, cadence, bounce, crouch, lift, armSwing, elbow, lean, twist, sway, flex, tail, bounceFreq;
};

Result<Anim3DClip> make_gait(const Rig3D& rig, const std::string& kind, const Json& paramsIn) {
    const SkeletonAsset& sk = *rig.skeleton;
    const bool quad = rig.templateName == "quadruped";
    if (quad && kind == "run") return make_gait(rig, "gallop", paramsIn);
    if (!quad && (kind == "trot" || kind == "gallop"))
        return make_error(std::format("'{}' is a quadruped gait, but this rig is {}", kind, rig.templateName.empty() ? "not a quadruped" : "a " + rig.templateName),
                          "Use kind \"walk\" or \"run\" for a biped.");
    const int root = rig.find_role("root", 0, "");
    if (root < 0) return make_error("the rig has no 'root' bone, so a gait has nothing to bounce", "Bake the model with rig.create: every template has a root.");
    std::vector<Leg> legs;
    auto add_leg = [&](const char* upper, const char* mid, const char* end, const std::string& side, bool front) -> bool {
        Leg l;
        l.a = first_of(rig, upper, side);
        l.b = first_of(rig, mid, side);
        l.c = first_of(rig, end, side);
        if (l.a < 0 || l.b < 0 || l.c < 0) return false;
        if (sk.nodes[std::size_t(l.b)].parent != l.a || sk.nodes[std::size_t(l.c)].parent != l.b) return false;
        l.front = front;
        l.poleSign = front ? -1.0f : 1.0f;
        l.restFoot = rig.rest_head(l.c);
        l.len = length(rig.rest_head(l.b) - rig.rest_head(l.a)) + length(l.restFoot - rig.rest_head(l.b));
        l.name = sk.nodes[std::size_t(l.c)].name;
        legs.push_back(l);
        return true;
    };
    bool hindL = add_leg("thigh", "shin", "foot", "l", false), hindR = add_leg("thigh", "shin", "foot", "r", false);
    bool foreL = false, foreR = false;
    if (quad) {
        foreL = add_leg("arm_upper", "arm_lower", "hand", "l", true);
        foreR = add_leg("arm_upper", "arm_lower", "hand", "r", true);
    }
    if (legs.size() < 2)
        return make_error(std::format("{} needs legs: the rig {}has {} complete leg chain{} (thigh, shin, foot{})", kind,
                                      rig.templateName.empty() ? "" : "(a " + rig.templateName + ") ", legs.size(), legs.size() == 1 ? "" : "s",
                                      quad ? ", and arm_upper, arm_lower, hand for the front legs" : ""),
                          "walk, run, trot and gallop work on the humanoid, bird and quadruped templates; a tail or chain rig can use swing and idle.");
    float L = 0.0f;
    for (const Leg& l : legs) L += l.len;
    L /= float(legs.size());
    if (L < 1e-3f) return make_error("the legs of the rig have no length", "Check the rig fit with rig.info.");
    // Footfall order per gait: the phase of each leg within the cycle (0..1).
    auto phase_of = [&](const Leg& l, const std::string& side) {
        const bool left = side == "l";
        if (!quad) return left ? 0.0f : 0.5f;
        if (kind == "walk") return l.front ? (left ? 0.25f : 0.75f) : (left ? 0.0f : 0.5f);  // lateral sequence: LH, LF, RH, RF
        if (kind == "trot") return left == l.front ? 0.5f : 0.0f;                              // diagonal pairs: LH+RF, RH+LF
        return l.front ? (left ? 0.55f : 0.45f) : (left ? 0.1f : 0.0f);                        // transverse gallop: RH, LH, RF, LF
    };
    for (Leg& l : legs) l.phase = phase_of(l, sk.nodes[std::size_t(l.c)].side);
    (void)hindL; (void)hindR; (void)foreL; (void)foreR;

    GaitDefaults d{};
    if (!quad) {
        d = kind == "run" ? GaitDefaults{0.35f, 3.0f, 1.45f, 0.08f, 0.08f, 0.20f, 45.0f, 85.0f, 10.0f, 10.0f, 0.015f, 0.0f, 10.0f, 2.0f}
                          : GaitDefaults{0.60f, 1.4f, 0.90f, 0.04f, 0.03f, 0.08f, 25.0f, 12.0f, 3.0f, 5.0f, 0.020f, 0.0f, 10.0f, 2.0f};
    } else if (kind == "walk") {
        d = {0.70f, 1.6f, 0.80f, 0.05f, 0.04f, 0.10f, 0.0f, 0.0f, 0.0f, 3.0f, 0.010f, 3.0f, 12.0f, 4.0f};
    } else if (kind == "trot") {
        d = {0.50f, 2.0f, 1.30f, 0.08f, 0.05f, 0.14f, 0.0f, 0.0f, 0.0f, 4.0f, 0.005f, 4.0f, 14.0f, 2.0f};
    } else {
        d = {0.30f, 3.2f, 2.00f, 0.15f, 0.06f, 0.22f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 14.0f, 16.0f, 1.0f};
    }
    Params p(paramsIn);
    const float stride = p.num("strideLength", d.stride * L, 0.05f * L, 10.0f * L);
    const float cadence = p.num("cadence", d.cadence, 0.1f, 6.0f);
    const float duty = p.num("duty", d.duty, 0.15f, 0.9f);
    const float bounce = p.num("bounce", d.bounce * L, 0.0f, L);
    const float crouch = p.num("crouch", d.crouch * L, 0.0f, L);
    const float footLift = p.num("footLift", d.lift * L, 0.0f, L);
    const float armSwing = p.num("armSwing", d.armSwing, 0.0f, 90.0f);
    const float elbow = p.num("elbowBend", d.elbow, 0.0f, 150.0f);
    const float lean = p.num("lean", d.lean, -45.0f, 45.0f);
    const float twist = p.num("twist", d.twist, 0.0f, 45.0f);
    const float sway = p.num("hipSway", d.sway * L, 0.0f, L);
    const float flex = p.num("spineFlex", d.flex, 0.0f, 45.0f);
    const float tailSwing = p.num("tailSwing", d.tail, 0.0f, 90.0f);
    const float fps = p.num("fps", 30.0f, 4.0f, 120.0f);
    const std::string footstep = p.str("footstepEvent", "footstep");
    const std::string doc = p.str("doc", "");
    if (auto r = p.finish(); !r) return r.error();

    float Lmax = 1e9f;
    for (const Leg& l : legs) Lmax = std::min(Lmax, 0.985f * l.len);
    const float stanceLen = stride * duty;
    if (stanceLen * 0.5f > 0.85f * Lmax)
        return make_error(std::format("strideLength {:.3f} with duty {:.2f} puts the foot {:.3f} from the hip, but the legs reach {:.3f}",
                                      stride, duty, stanceLen * 0.5f, Lmax),
                          std::format("Use a strideLength of at most {:.3f} (or a lower duty), or a smaller cadence for a slower walk.", 1.7f * Lmax / duty));
    const float T = 1.0f / cadence;
    float phiMid = 0.0f;
    {
        float sum = 0.0f;
        int count = 0;
        for (const Leg& l : legs) if (!l.front) { sum += l.phase; ++count; }
        phiMid = (count ? sum / float(count) : legs[0].phase) + duty * 0.5f;
        if (!quad) phiMid = legs[0].phase + duty * 0.5f;
    }
    const std::vector<int> spine = rig.chain("spine"), neck = rig.chain("neck", ""), tail = rig.chain("tail");
    const int head = rig.find_role("head", 0, "");
    const bool arms = !quad && rig.templateName != "bird";
    const float toeDown = 25.0f, toeUp = 10.0f;

    PoseFn posing = [&](float u, float, Pose& pose) {
        const float phi = u;
        struct Tgt { Vec3 target; float pitch; };
        std::vector<Tgt> tg;
        for (const Leg& l : legs) {
            const float lf = frac(phi - l.phase);
            Tgt t{l.restFoot, 0.0f};
            if (lf < duty) {
                t.target.z += stanceLen * 0.5f - (lf / duty) * stanceLen;
            } else {
                const float s = (lf - duty) / (1.0f - duty);
                t.target.z += -stanceLen * 0.5f + stanceLen * smoother(s);
                t.target.y += footLift * sin_t(0.5f * s);
                t.pitch = s < 0.5f ? toeDown * sin_t(s) : toeUp * sin_t(s);
            }
            tg.push_back(t);
        }
        const float hipYaw = quad ? 0.0f : -twist * cos_t(phi);
        const float swayX = sway * cos_t(phi - phiMid);  // one phase for bipeds and quadrupeds: the sway peaks at the middle of the stance
        pose.translation[std::size_t(root)] += Vec3{swayX, 0, 0};
        set_euler(pose, root, {0, hipYaw, 0});
        // Spine, neck, head and tail.
        const float torsoYaw = quad ? twist * sin_t(phi) : 1.5f * twist * cos_t(phi);
        const float flexNow = flex * cos_t(phi - phiMid);
        for (std::size_t i = 0; i < spine.size(); ++i) {
            const float n = float(spine.size());
            set_euler(pose, spine[i], {lean / n + (quad ? flexNow / n : 0.0f), torsoYaw / n, 0.0f});
        }
        const std::size_t headCount = neck.size() + (head >= 0 ? 1 : 0);
        for (std::size_t i = 0; i <= neck.size() && headCount > 0; ++i) {
            const int node = i < neck.size() ? neck[i] : head;
            if (node < 0) continue;
            const float n = float(headCount);
            const float counterYaw = quad ? -torsoYaw * 0.5f : -(hipYaw + torsoYaw);
            set_euler(pose, node, {-lean / n - (quad ? flexNow * 0.5f / n : 0.0f), counterYaw / n, 0.0f});
        }
        for (std::size_t i = 0; i < tail.size(); ++i)
            set_euler(pose, tail[i], {0, tailSwing * sin_t(phi - 0.1f * float(i) + 0.25f) / float(tail.size()) * 2.0f, 0});
        PoseFrame frame = pose_frame(sk, pose);
        // The pelvis: bounce, lowered as far as the legs need to reach their ankles.
        float dy = -crouch - bounce * 0.5f * (1.0f - cos_t(d.bounceFreq * (phi - phiMid)));
        for (std::size_t i = 0; i < legs.size(); ++i) {
            const Vec3 hip = frame.pos[std::size_t(legs[i].a)];
            const float hx = hip.x - tg[i].target.x, hz = hip.z - tg[i].target.z;
            const float reach = std::sqrt(std::max(0.985f * 0.985f * legs[i].len * legs[i].len - hx * hx - hz * hz, 0.0f));
            dy = std::min(dy, tg[i].target.y + reach - hip.y);
        }
        pose.translation[std::size_t(root)].y += dy;
        refresh_frame(sk, pose, frame);
        // Arms swing against the legs.
        if (arms) {
            for (const char* side : {"l", "r"}) {
                const int up = first_of(rig, "arm_upper", side), low = first_of(rig, "arm_lower", side), hand = first_of(rig, "hand", side);
                if (up < 0 || low < 0) continue;
                const float sgn = std::string(side) == "l" ? 1.0f : -1.0f;
                const float A = -sgn * armSwing * cos_t(phi);  // forward is positive; the left arm is back when the left foot lands
                const float B = elbow + 0.5f * std::max(A, 0.0f);
                const int parent = sk.nodes[std::size_t(up)].parent;
                const Quat pr = parent >= 0 ? frame.rot[std::size_t(parent)] : Quat{};
                auto dir = [&](float deg) {
                    return pr.rotate(normalize(Vec3{sgn * det::sin(radians(6.0f)), -det::cos(radians(deg)), det::sin(radians(deg))}));
                };
                aim(rig, pose, frame, up, dir(A));
                aim(rig, pose, frame, low, dir(A + B));
                if (hand >= 0) aim(rig, pose, frame, hand, dir(A + B));
            }
        }
        // Legs: the ankle on its path.
        for (std::size_t i = 0; i < legs.size(); ++i) {
            const Leg& l = legs[i];
            const Vec3 pole = frame.pos[std::size_t(l.a)] + Vec3{0, 0, l.poleSign};
            const Quat endRot = Quat::from_euler_deg({tg[i].pitch, 0, 0});
            (void)solve_two_bone(sk, pose, l.a, l.b, l.c, tg[i].target, pole, 1.0f, endRot);
            refresh_frame(sk, pose, frame);
        }
    };
    Anim3DClip clip = build_clip(rig, T, fps, true, posing);
    clip.groundSpeed = stride * cadence;
    for (const Leg& l : legs) {
        Anim3DContact c;
        c.bone = l.name;
        c.from = frac(l.phase) * T;
        c.to = frac(l.phase + duty) * T;
        clip.contacts.push_back(c);
        if (!footstep.empty()) {
            ClipEvent ev;
            ev.t = c.from;
            ev.name = footstep;
            ev.data = Json::object();
            ev.data["bone"] = l.name;
            clip.events.push_back(ev);
        }
    }
    std::stable_sort(clip.events.begin(), clip.events.end(), [](const ClipEvent& a, const ClipEvent& b) { return a.t < b.t; });
    clip.doc = doc.empty() ? std::format("{} cycle: {:.2f} m stride at {:.2f} cycles per second ({:.2f} m/s)", kind, stride, cadence, stride * cadence) : doc;
    clip.generated = Json::object();
    clip.generated["kind"] = kind;
    clip.generated["params"] = p.resolved;
    return clip;
}

// ------------------------------------------------------------------------------------------------------------ idle --
Result<Anim3DClip> make_idle(const Rig3D& rig, const Json& paramsIn) {
    const SkeletonAsset& sk = *rig.skeleton;
    const std::vector<int> spine = rig.chain("spine"), neck = rig.chain("neck", ""), tail = rig.chain("tail");
    const int head = rig.find_role("head", 0, "");
    const int root = rig.find_role("root", 0, "");
    if (spine.empty() && neck.empty() && head < 0 && tail.empty())
        return make_error("idle breathing needs a spine, neck, head or tail to move, and the rig has none",
                          "Use the humanoid, quadruped or bird template, or the swing kind for a tail or chain rig.");
    Params p(paramsIn);
    const float duration = p.num("duration", 4.0f, 0.5f, 60.0f);
    const float breaths = p.num("breaths", 1.0f, 1.0f, 30.0f);
    const float amount = p.num("breathAmount", 2.0f, 0.0f, 20.0f);
    const float sway = p.num("weightShift", 1.0f, 0.0f, 20.0f);
    const float tailSwing = p.num("tailSwing", 8.0f, 0.0f, 60.0f);
    const float fps = p.num("fps", 30.0f, 4.0f, 120.0f);
    const std::string doc = p.str("doc", "");
    if (auto r = p.finish(); !r) return r.error();
    const int nb = int(std::round(breaths));
    PoseFn posing = [&](float u, float, Pose& pose) {
        const float breath = sin_t(u * float(nb));
        const float shift = sin_t(u);
        const float n = float(std::max<std::size_t>(spine.size(), 1));
        for (std::size_t i = 0; i < spine.size(); ++i) {
            const float w = (float(i) + 1.0f) / (n * (n + 1.0f) * 0.5f) * n;  // the upper spine breathes more
            set_euler(pose, spine[i], {-amount * breath * w / n, 0.0f, sway * shift / n});
        }
        const std::size_t hc = neck.size() + (head >= 0 ? 1 : 0);
        for (std::size_t i = 0; i <= neck.size() && hc > 0; ++i) {
            const int node = i < neck.size() ? neck[i] : head;
            if (node < 0) continue;
            set_euler(pose, node, {amount * 0.8f * breath / float(hc), 0.0f, -sway * shift / float(hc)});
        }
        for (const char* side : {"l", "r"}) {
            const int cl = first_of(rig, "clavicle", side);
            if (cl >= 0) set_euler(pose, cl, {0.0f, 0.0f, (std::string(side) == "l" ? 1.0f : -1.0f) * amount * 0.5f * breath});
        }
        for (std::size_t i = 0; i < tail.size(); ++i)
            set_euler(pose, tail[i], {0.0f, tailSwing * sin_t(u - 0.12f * float(i)) / float(tail.size()) * 2.0f, 0.0f});
        (void)root; (void)sk;
    };
    Anim3DClip clip = build_clip(rig, duration, fps, true, posing);
    clip.doc = doc.empty() ? std::format("idle: {} breath{} in {:.1f} s", nb, nb == 1 ? "" : "s", duration) : doc;
    clip.generated = Json::object();
    clip.generated["kind"] = "idle";
    clip.generated["params"] = p.resolved;
    return clip;
}

// ----------------------------------------------------------------------------------------------------------- swing --
Result<Anim3DClip> make_swing(const Rig3D& rig, const Json& paramsIn) {
    Params p(paramsIn);
    std::vector<std::string> def;
    for (const char* r : {"tail", "chain"})
        if (!rig.chain(r).empty() || !rig.chain(r, "l").empty()) def.push_back(r);
    const std::vector<std::string> selected = p.list("bones", def);
    const float duration = p.num("period", 1.6f, 0.2f, 60.0f);
    const float cycles = p.num("cycles", 1.0f, 1.0f, 20.0f);
    const float amplitude = p.num("amplitude", 20.0f, 0.0f, 120.0f);
    const std::string axis = p.str("axis", "yaw", {"yaw", "pitch", "roll"});
    const float lag = p.num("lag", 0.12f, 0.0f, 1.0f);
    const float growth = p.num("growth", 0.5f, 0.0f, 5.0f);
    const float bias = p.num("bias", 0.0f, -90.0f, 90.0f);
    const float fps = p.num("fps", 30.0f, 4.0f, 120.0f);
    const std::string doc = p.str("doc", "");
    if (auto r = p.finish(); !r) return r.error();
    // Each entry is a role (every bone of the role, by index, either side) or a bone name.
    std::vector<std::vector<int>> groups;
    const std::vector<std::string> names = rig.bone_names();
    for (const std::string& s : selected) {
        std::vector<int> g;
        if (int n = rig.find(s); n >= 0) g.push_back(n);
        else {
            for (const char* side : {"", "l", "r"})
                for (int n2 : rig.chain(s, side)) g.push_back(n2);
        }
        if (g.empty())
            return make_error(std::format("'bones' names '{}', which is neither a bone nor a role of this rig", s),
                              did_you_mean(s, names) + " Roles: tail, chain, spine, neck, arm_upper...");
        groups.push_back(g);
    }
    if (groups.empty())
        return make_error("swing needs bones to swing, and this rig has no tail or chain", "Name them: {\"bones\": [\"spine\"]} or {\"bones\": [\"arm_lower_l\"]}.");
    const int nc = int(std::round(cycles));
    PoseFn posing = [&](float u, float, Pose& pose) {
        for (const auto& g : groups)
            for (std::size_t i = 0; i < g.size(); ++i) {
                const float amp = amplitude * (1.0f + growth * (g.size() > 1 ? float(i) / float(g.size() - 1) : 0.0f));
                const float a = amp * sin_t(u * float(nc) - lag * float(i)) + bias;
                set_euler(pose, g[i], axis == "yaw" ? Vec3{0, a, 0} : axis == "pitch" ? Vec3{a, 0, 0} : Vec3{0, 0, a});
            }
    };
    Anim3DClip clip = build_clip(rig, duration * float(nc), fps, true, posing);
    clip.doc = doc.empty() ? std::format("swing of {} about {}", selected.empty() ? "nothing" : selected[0], axis) : doc;
    clip.generated = Json::object();
    clip.generated["kind"] = "swing";
    clip.generated["params"] = p.resolved;
    return clip;
}

// ------------------------------------------------------------------------------------------------------------- hit --
Result<Anim3DClip> make_hit(const Rig3D& rig, const Json& paramsIn) {
    const std::vector<int> spine = rig.chain("spine"), neck = rig.chain("neck", "");
    const int head = rig.find_role("head", 0, ""), root = rig.find_role("root", 0, "");
    if (spine.empty() && root < 0)
        return make_error("a hit reaction needs a spine or a root to recoil, and the rig has neither", "Use the humanoid, quadruped or bird template.");
    Params p(paramsIn);
    const float duration = p.num("duration", 0.6f, 0.1f, 5.0f);
    const float strength = p.num("strength", 18.0f, 0.0f, 80.0f);
    const float from = p.num("fromAngle", 0.0f, -180.0f, 180.0f);
    const float attack = p.num("attack", 0.18f, 0.02f, 0.6f);
    const float fps = p.num("fps", 30.0f, 4.0f, 120.0f);
    const std::string event = p.str("event", "");
    const std::string doc = p.str("doc", "");
    if (auto r = p.finish(); !r) return r.error();
    auto envelope = [&](float u) {
        if (u <= attack) {
            const float a = u / attack;
            return 1.0f - (1.0f - a) * (1.0f - a);
        }
        const float r = (u - attack) / (1.0f - attack);
        return (1.0f - smooth(r)) + 0.1f * sin_t(1.5f * r) * (1.0f - r);
    };
    const float sa = det::sin(radians(from)), ca = det::cos(radians(from));
    PoseFn posing = [&](float u, float, Pose& pose) {
        const float f = envelope(u);
        // The torso tips away from the side the hit comes from: from 0 = the front (+Z), 90 = the character's left (+X).
        const float pitch = -strength * ca * f, roll = strength * sa * f;
        if (root >= 0) set_euler(pose, root, {pitch * 0.2f, 0.0f, roll * 0.2f});
        float total = 0.0f;
        for (std::size_t i = 0; i < spine.size(); ++i) total += float(i + 1);
        for (std::size_t i = 0; i < spine.size(); ++i) {
            const float w = float(i + 1) / total;
            set_euler(pose, spine[i], {pitch * 0.8f * w * 1.5f, 0.0f, roll * 0.8f * w * 1.5f});
        }
        const float fh = envelope(std::max(u - 0.06f, 0.0f) / (1.0f - 0.06f));  // the head lags the torso
        const std::size_t hc = neck.size() + (head >= 0 ? 1 : 0);
        for (std::size_t i = 0; i <= neck.size() && hc > 0; ++i) {
            const int node = i < neck.size() ? neck[i] : head;
            if (node < 0) continue;
            set_euler(pose, node, {-strength * ca * fh * 0.7f / float(hc), 0.0f, strength * sa * fh * 0.7f / float(hc)});
        }
        for (const char* side : {"l", "r"}) {
            const int cl = first_of(rig, "clavicle", side);
            if (cl >= 0) set_euler(pose, cl, {0.0f, 0.0f, (std::string(side) == "l" ? 1.0f : -1.0f) * strength * 0.15f * f});
        }
    };
    Anim3DClip clip = build_clip(rig, duration, fps, false, posing);
    if (!event.empty()) {
        ClipEvent ev;
        ev.t = 0.0f;
        ev.name = event;
        clip.events.push_back(ev);
    }
    clip.doc = doc.empty() ? std::format("hit reaction from {:.0f} degrees, {:.0f} degrees of recoil", from, strength) : doc;
    clip.generated = Json::object();
    clip.generated["kind"] = "hit";
    clip.generated["params"] = p.resolved;
    return clip;
}

}  // namespace

const std::vector<std::string>& anim3d_generator_kinds() {
    static const std::vector<std::string> kinds = {"walk", "run", "trot", "gallop", "idle", "swing", "hit"};
    return kinds;
}

Result<Anim3DClip> generate_anim3d(const Rig3D& rig, std::string_view kindView, const Json& params) {
    const std::string kind(kindView);
    const auto& kinds = anim3d_generator_kinds();
    if (std::find(kinds.begin(), kinds.end(), kind) == kinds.end())
        return make_error(std::format("unknown generator '{}'", kind), did_you_mean(kind, kinds));
    if (!params.is_object()) return make_error("generator parameters must be an object, got " + describe_json_value(params), "Pass {} or {\"strideLength\": 1.2}.");
    if (std::string problem = rig_generator_problem(rig); !problem.empty())
        return make_error(std::format("{} cannot make a clip for this model: {}", generator_name(kind), problem),
                          "Bake the skeleton with rig.create / rig.bake (docs/RIGGING.md): its bones carry the roles the generators look for.");
    if (kind == "walk" || kind == "run" || kind == "trot" || kind == "gallop") return make_gait(rig, kind, params);
    if (kind == "idle") return make_idle(rig, params);
    if (kind == "swing") return make_swing(rig, params);
    return make_hit(rig, params);
}

Json anim3d_generator_catalog() {
    auto param = [](const char* name, const char* doc, Json def, Json lo = Json(), Json hi = Json()) {
        Json j = Json::object();
        j["name"] = name;
        j["doc"] = doc;
        j["default"] = def;
        if (!lo.is_null()) j["min"] = lo;
        if (!hi.is_null()) j["max"] = hi;
        return j;
    };
    Json common = Json::array();
    common.push_back(param("fps", "Keys per second of the clip.", 30, 4, 120));
    common.push_back(param("doc", "The clip's description; empty = a summary of the parameters.", ""));
    auto kind = [&](const char* name, const char* doc, const char* templates, Json params) {
        for (const Json& c : common) params.push_back(c);
        Json j = Json::object();
        j["kind"] = name;
        j["doc"] = doc;
        j["templates"] = templates;
        j["params"] = params;
        return j;
    };
    // Defaults that scale with the leg are written "N x leg" (leg = hip to ankle, rest pose); the gait tables are in docs/ANIMATION.md.
    Json gait = Json::array();
    gait.push_back(param("strideLength", "Distance one cycle covers (a foot lands again at the same place), model units.", "walk 1.4 x leg, run 3.0 x leg (quadruped: walk 1.6, trot 2.0, gallop 3.2)", 0.05, 10));
    gait.push_back(param("cadence", "Cycles per second. A cycle is two steps of a biped, four footfalls of a quadruped. The speed is strideLength x cadence.", "walk 0.9, run 1.45 (quadruped: walk 0.8, trot 1.3, gallop 2.0)", 0.1, 6));
    gait.push_back(param("duty", "Fraction of the cycle each foot is on the ground. Below 0.5 both feet leave the ground for a moment (a run).", "walk 0.6, run 0.35 (quadruped: 0.7, 0.5, 0.3)", 0.15, 0.9));
    gait.push_back(param("bounce", "How far the pelvis dips between steps, model units.", "walk 0.04 x leg, run 0.08 x leg", 0, 100));
    gait.push_back(param("crouch", "How far the pelvis stays below the straight-leg height, model units.", "walk 0.03 x leg, run 0.08 x leg", 0, 100));
    gait.push_back(param("footLift", "Height of the swinging foot, model units.", "walk 0.08 x leg, run 0.2 x leg", 0, 100));
    gait.push_back(param("armSwing", "Biped: degrees each arm swings forward and back, against the legs.", "walk 25, run 45", 0, 90));
    gait.push_back(param("elbowBend", "Biped: degrees the elbow stays bent.", "walk 12, run 85", 0, 150));
    gait.push_back(param("lean", "Degrees the torso leans forward (the head stays level).", "walk 3, run 10", -45, 45));
    gait.push_back(param("twist", "Degrees the hips and shoulders twist against each other (a quadruped: the sway of the spine).", "walk 5, run 10", 0, 45));
    gait.push_back(param("hipSway", "Sideways sway of the pelvis towards the standing leg, model units.", "0.02 x leg", 0, 100));
    gait.push_back(param("spineFlex", "Quadruped: degrees the spine bends and straightens through the cycle.", "walk 3, trot 4, gallop 14", 0, 45));
    gait.push_back(param("tailSwing", "Degrees the tail sways.", 10, 0, 90));
    gait.push_back(param("footstepEvent", "Name of the clip event sent each time a foot lands, with data {bone}; empty = none.", "footstep"));
    Json out = Json::array();
    out.push_back(kind("walk", "A walking cycle with planted feet: biped (humanoid, bird) or the lateral-sequence walk of a quadruped.", "humanoid, bird, quadruped", gait));
    out.push_back(kind("run", "A running cycle with a flight phase (biped); on a quadruped it is the gallop.", "humanoid, bird, quadruped", gait));
    out.push_back(kind("trot", "The diagonal-pair trot of a quadruped.", "quadruped", gait));
    out.push_back(kind("gallop", "The transverse gallop of a quadruped.", "quadruped", gait));
    Json idle = Json::array();
    idle.push_back(param("duration", "Length of the loop in seconds.", 4, 0.5, 60));
    idle.push_back(param("breaths", "Breaths in the loop.", 1, 1, 30));
    idle.push_back(param("breathAmount", "Degrees the spine and shoulders move with a breath.", 2, 0, 20));
    idle.push_back(param("weightShift", "Degrees the spine leans side to side once per loop.", 1, 0, 20));
    idle.push_back(param("tailSwing", "Degrees the tail sways.", 8, 0, 60));
    out.push_back(kind("idle", "Standing still: breathing, a slow weight shift, a swaying tail. The feet do not move.", "humanoid, quadruped, bird", idle));
    Json swing = Json::array();
    swing.push_back(param("bones", "Roles or bone names that swing, as a chain with a travelling wave (tail, chain, spine, arm_lower_l...).", "the tail and chain bones of the rig"));
    swing.push_back(param("period", "Seconds of one swing.", 1.6, 0.2, 60));
    swing.push_back(param("cycles", "Swings in the clip (a whole number).", 1, 1, 20));
    swing.push_back(param("amplitude", "Degrees each bone swings either side of `bias`.", 20, 0, 120));
    swing.push_back(param("axis", "Rotation axis of the bone: yaw (about Y), pitch (X) or roll (Z).", "yaw"));
    swing.push_back(param("lag", "Fraction of the period each bone is behind the one before it.", 0.12, 0, 1));
    swing.push_back(param("growth", "How much wider the tip swings than the base (1 = twice).", 0.5, 0, 5));
    swing.push_back(param("bias", "Degrees added to every swing: a tail held up or to one side.", 0, -90, 90));
    out.push_back(kind("swing", "A tail, tentacle, antenna or chain swinging; also a pendulum on any bones.", "any rig with those bones", swing));
    Json hit = Json::array();
    hit.push_back(param("duration", "Seconds from the hit to the pose at rest.", 0.6, 0.1, 5));
    hit.push_back(param("strength", "Degrees the torso recoils.", 18, 0, 80));
    hit.push_back(param("fromAngle", "Where the hit comes from: 0 the front (+Z), 90 the character's left (+X), 180 the back, -90 the right.", 0, -180, 180));
    hit.push_back(param("attack", "Fraction of the clip the recoil takes to reach its peak.", 0.18, 0.02, 0.6));
    hit.push_back(param("event", "Name of a clip event sent at the start (empty = none).", ""));
    out.push_back(kind("hit", "A hit reaction: the torso recoils, the head lags it, then everything settles. Plays once.", "humanoid, quadruped, bird", hit));
    return out;
}

}  // namespace fa
