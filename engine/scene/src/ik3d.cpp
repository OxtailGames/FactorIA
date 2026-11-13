#include "fa/scene/ik3d.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/det_math.h"

namespace fa {

namespace {

// Rotates `v` so it has no component along unit `u`.
Vec3 reject(Vec3 v, Vec3 u) { return v - u * dot(v, u); }

float wrap_deg(float a) {
    while (a > 180.0f) a -= 360.0f;
    while (a < -180.0f) a += 360.0f;
    return a;
}

}  // namespace

Result<TwoBoneResult> solve_two_bone(const SkeletonAsset& sk, Pose& pose, int root, int mid, int end, Vec3 target,
                                     const std::optional<Vec3>& pole, float weight,
                                     const std::optional<Quat>& endRotation) {
    const int n = int(sk.nodes.size());
    auto name = [&](int i) { return i >= 0 && i < n ? sk.nodes[std::size_t(i)].name : std::string("?"); };
    if (root < 0 || mid < 0 || end < 0 || root >= n || mid >= n || end >= n)
        return make_error("two-bone IK needs three bones of the skeleton",
                          "Name the root, mid and end bones of the limb.");
    if (sk.nodes[std::size_t(mid)].parent != root || sk.nodes[std::size_t(end)].parent != mid)
        return make_error(
            std::format(
                "two-bone IK needs a chain root -> mid -> end, but '{}' is not the parent of '{}' or '{}' is not the "
                "parent of '{}'",
                name(root), name(mid), name(mid), name(end)),
            "Name three bones where each is the child of the one before: arm_upper_l, arm_lower_l, hand_l.");
    const Pose original = pose;
    PoseFrame f = pose_frame(sk, pose);
    const Vec3 a = f.pos[std::size_t(root)], b = f.pos[std::size_t(mid)], c = f.pos[std::size_t(end)];
    const float l1 = length(b - a), l2 = length(c - b);
    TwoBoneResult res;
    if (l1 < 1e-6f || l2 < 1e-6f) {
        res.end = c;
        res.error = distance(c, target);
        res.reached = res.error < 1e-4f;
        return res;
    }
    const Vec3 toTarget = target - a;
    const float dist = length(toTarget);
    const float maxReach = l1 + l2, minReach = std::fabs(l1 - l2);
    res.reached = dist <= maxReach + 1e-5f && dist >= minReach - 1e-5f;
    Vec3 u = dist > 1e-6f ? toTarget / dist : normalize(c - a);
    if (length_sq(u) < 0.5f) u = Vec3{0, -1, 0};
    const float d = std::max(std::min(dist, maxReach), std::max(minReach, 1e-4f));
    // The elbow/knee sits where the two circles of radius l1 (around a) and l2 (around the reachable end) meet; the pole picks the side.
    const float x = (l1 * l1 - l2 * l2 + d * d) / (2.0f * d);
    const float h = std::sqrt(std::max(l1 * l1 - x * x, 0.0f));
    Vec3 bend = pole ? reject(*pole - a, u) : reject(b - a, u);
    if (length_sq(bend) < 1e-10f) bend = reject(b - a, u);
    if (length_sq(bend) < 1e-10f) bend = reject(pole ? *pole - a : Vec3{0, 0, 1}, u);
    if (length_sq(bend) < 1e-10f) bend = reject(Vec3{1, 0, 0}, u);
    if (length_sq(bend) < 1e-10f) bend = reject(Vec3{0, 0, 1}, u);
    bend = normalize(bend);
    const Vec3 newMid = a + u * x + bend * h;
    const Vec3 newEnd = a + u * d;

    set_global_rotation(sk, pose, f, root, rotation_between(b - a, newMid - a) * f.rot[std::size_t(root)]);
    const Vec3 b2 = f.pos[std::size_t(mid)], c2 = f.pos[std::size_t(end)];
    set_global_rotation(sk, pose, f, mid, rotation_between(c2 - b2, newEnd - b2) * f.rot[std::size_t(mid)]);
    if (endRotation) set_global_rotation(sk, pose, f, end, *endRotation);

    weight = clamp(weight, 0.0f, 1.0f);
    if (weight < 1.0f) {
        for (int i : {root, mid, end}) {
            const std::size_t u2 = std::size_t(i);
            pose.rotation[u2] = slerp(original.rotation[u2], pose.rotation[u2], weight);
        }
        refresh_frame(sk, pose, f);
    }
    res.end = f.pos[std::size_t(end)];
    res.error = distance(res.end, target);
    return res;
}

LookAtResult solve_look_at(const SkeletonAsset& sk, Pose& pose, int bone, Vec3 target, const LookAtParams& prm,
                           Quat& state) {
    LookAtResult res;
    const std::size_t bi = std::size_t(bone);
    const int parent = sk.nodes[bi].parent;
    PoseFrame f = pose_frame(sk, pose);
    const Quat parentRot = parent < 0 ? Quat{} : f.rot[std::size_t(parent)];
    const Quat toLocal = parentRot.conjugate();
    const Vec3 fwd = normalize(prm.forward);
    // Everything below is in the parent's frame, where +Y is up and +Z forward at rest.
    const Vec3 animated = normalize(pose.rotation[bi].rotate(fwd));  // where the animation points the bone
    Quat wanted;                                                     // the turn on top of the animation
    bool aimed = false;
    float aimYaw = 0.0f, aimPitch = 0.0f;
    const Vec3 toTarget = toLocal.rotate(target - f.pos[bi]);
    if (length_sq(toTarget) > 1e-10f && length_sq(animated) > 0.5f) {
        const Vec3 dl = normalize(toTarget);
        const float yawA = degrees(det::atan2(animated.x, animated.z)),
                    pitchA = degrees(det::asin(clamp(animated.y, -1.0f, 1.0f)));
        const float yawD = degrees(det::atan2(dl.x, dl.z)), pitchD = degrees(det::asin(clamp(dl.y, -1.0f, 1.0f)));
        float dyaw = wrap_deg(yawD - yawA), dpitch = pitchD - pitchA;
        const float yl = clamp(prm.yawLimit, 0.0f, 180.0f), pl = clamp(prm.pitchLimit, 0.0f, 90.0f);
        if (std::fabs(dyaw) > yl) {
            dyaw = dyaw < 0 ? -yl : yl;
            res.clamped = true;
        }
        if (std::fabs(dpitch) > pl) {
            dpitch = dpitch < 0 ? -pl : pl;
            res.clamped = true;
        }
        const float yawC = yawA + dyaw, pitchC = clamp(pitchA + dpitch, -89.0f, 89.0f);
        const float cp = det::cos(radians(pitchC));
        const Vec3 aim{det::sin(radians(yawC)) * cp, det::sin(radians(pitchC)), det::cos(radians(yawC)) * cp};
        wanted = rotation_between(animated, aim);
        res.yaw = dyaw;
        res.pitch = pitchC - pitchA;
        aimed = true;
        aimYaw = yawA;
        aimPitch = pitchA;
    }
    wanted = slerp(Quat{}, wanted, clamp(prm.weight, 0.0f, 1.0f));
    if (prm.maxTurn > 0.0f) {
        // Move the carried turn towards the wanted one by at most maxTurn radians.
        const Quat delta = wanted * state.conjugate();
        const float ang = radians(rotation_angle_deg(delta));
        state = ang <= prm.maxTurn ? wanted : normalize(slerp(state, wanted, prm.maxTurn / ang));
    } else {
        state = wanted;
    }
    pose.rotation[bi] = normalize(state * pose.rotation[bi]);
    if (aimed) {  // report the turn that was applied (the weight and the turn speed may stop short of the wanted one)
        const Vec3 now = normalize(pose.rotation[bi].rotate(fwd));
        res.yaw = wrap_deg(degrees(det::atan2(now.x, now.z)) - aimYaw);
        res.pitch = degrees(det::asin(clamp(now.y, -1.0f, 1.0f))) - aimPitch;
    }
    return res;
}

}  // namespace fa
