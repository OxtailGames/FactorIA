#include "fa/scene/rig3d.h"

#include <algorithm>
#include <cmath>

#include "fa/core/det_math.h"
#include "fa/scene/animation.h"

namespace fa {

void refresh_frame(const SkeletonAsset& sk, const Pose& pose, PoseFrame& frame) {
    const std::size_t n = sk.nodes.size();
    frame.pos.resize(n);
    frame.rot.resize(n);
    for (int i : sk.order) {
        const std::size_t u = std::size_t(i);
        const int p = sk.nodes[u].parent;
        if (p < 0) {
            frame.pos[u] = pose.translation[u];
            frame.rot[u] = pose.rotation[u];
        } else {
            const std::size_t pu = std::size_t(p);
            const Vec3 s = pose.scale[pu];
            const Vec3 t = pose.translation[u];
            frame.pos[u] = frame.pos[pu] + frame.rot[pu].rotate(Vec3{t.x * s.x, t.y * s.y, t.z * s.z});
            frame.rot[u] = normalize(frame.rot[pu] * pose.rotation[u]);
        }
    }
}

PoseFrame pose_frame(const SkeletonAsset& sk, const Pose& pose) {
    PoseFrame f;
    refresh_frame(sk, pose, f);
    return f;
}

void set_global_rotation(const SkeletonAsset& sk, Pose& pose, PoseFrame& frame, int node, Quat global) {
    const int p = sk.nodes[std::size_t(node)].parent;
    pose.rotation[std::size_t(node)] = p < 0 ? normalize(global) : normalize(frame.rot[std::size_t(p)].conjugate() * global);
    refresh_frame(sk, pose, frame);
}

Quat rotation_between(Vec3 from, Vec3 to) {
    const Vec3 a = normalize(from), b = normalize(to);
    if (length_sq(a) < 0.5f || length_sq(b) < 0.5f) return Quat{};
    const float d = clamp(dot(a, b), -1.0f, 1.0f);
    if (d > 0.999999f) return Quat{};
    if (d < -0.999999f) {
        Vec3 axis = cross(a, Vec3{1, 0, 0});
        if (length_sq(axis) < 1e-6f) axis = cross(a, Vec3{0, 1, 0});
        axis = normalize(axis);
        return Quat{axis.x, axis.y, axis.z, 0.0f};
    }
    const Vec3 c = cross(a, b);
    return normalize(Quat{c.x, c.y, c.z, 1.0f + d});
}

float rotation_angle_deg(Quat q) {
    q = normalize(q);
    return 2.0f * degrees(det::acos(clamp(std::fabs(q.w), 0.0f, 1.0f)));
}

bool parse_axis_name(std::string_view text, Vec3& out) {
    float sign = 1.0f;
    if (!text.empty() && (text[0] == '+' || text[0] == '-')) {
        if (text[0] == '-') sign = -1.0f;
        text.remove_prefix(1);
    }
    if (text.size() != 1) return false;
    switch (text[0]) {
        case 'x': case 'X': out = {sign, 0, 0}; return true;
        case 'y': case 'Y': out = {0, sign, 0}; return true;
        case 'z': case 'Z': out = {0, 0, sign}; return true;
        default: return false;
    }
}

int Rig3D::find(std::string_view name) const {
    for (int n : bones)
        if (skeleton->nodes[std::size_t(n)].name == name) return n;
    return -1;
}

int Rig3D::find_role(std::string_view role, int index, std::string_view side) const {
    for (int n : bones) {
        const SkelNode& k = skeleton->nodes[std::size_t(n)];
        if (k.role == role && k.roleIndex == index && k.side == side) return n;
    }
    return -1;
}

std::vector<int> Rig3D::chain(std::string_view role, std::string_view side) const {
    std::vector<int> out;
    for (int n : bones) {
        const SkelNode& k = skeleton->nodes[std::size_t(n)];
        if (k.role == role && k.side == side) out.push_back(n);
    }
    std::stable_sort(out.begin(), out.end(),
                     [&](int a, int b) { return skeleton->nodes[std::size_t(a)].roleIndex < skeleton->nodes[std::size_t(b)].roleIndex; });
    return out;
}

std::vector<std::string> Rig3D::bone_names() const {
    std::vector<std::string> out;
    for (int n : bones) out.push_back(skeleton->nodes[std::size_t(n)].name);
    return out;
}

Rig3D make_rig3d(const SkeletonAsset& sk, int skin) {
    Rig3D r;
    r.skeleton = &sk;
    r.skin = skin;
    r.boneOfNode.assign(sk.nodes.size(), -1);
    r.rest = rest_pose(sk);
    r.restFrame = pose_frame(sk, r.rest);
    r.axis.assign(sk.nodes.size(), Vec3{});
    r.length.assign(sk.nodes.size(), 0.0f);
    if (skin >= 0 && std::size_t(skin) < sk.skins.size()) {
        const SkelSkin& s = sk.skins[std::size_t(skin)];
        r.templateName = s.rigTemplate;
        for (std::size_t j = 0; j < s.joints.size(); ++j) {
            const int n = s.joints[j];
            if (n < 0 || std::size_t(n) >= sk.nodes.size()) continue;
            r.bones.push_back(n);
            r.boneOfNode[std::size_t(n)] = int(j);
            if (!sk.nodes[std::size_t(n)].role.empty()) r.hasRoles = true;
            const Quat q = sk.nodes[std::size_t(n)].rotation;
            if (std::fabs(q.x) > 1e-4f || std::fabs(q.y) > 1e-4f || std::fabs(q.z) > 1e-4f || q.w < 0.9999f) r.identityRest = false;
        }
    }
    // Rest directions: the stored axis (rig.bake), else towards the first child that is a joint, else unknown.
    for (int n : r.bones) {
        const SkelNode& k = sk.nodes[std::size_t(n)];
        if (k.length > 0.0f && length_sq(k.axis) > 0.5f) {
            r.axis[std::size_t(n)] = normalize(k.axis);
            r.length[std::size_t(n)] = k.length;
            continue;
        }
        for (int c : r.bones) {
            if (sk.nodes[std::size_t(c)].parent != n) continue;
            const Vec3 d = r.restFrame.pos[std::size_t(c)] - r.restFrame.pos[std::size_t(n)];
            if (length(d) > 1e-6f) {
                r.axis[std::size_t(n)] = normalize(d);
                r.length[std::size_t(n)] = length(d);
                break;
            }
        }
    }
    return r;
}

std::string rig_generator_problem(const Rig3D& rig) {
    if (rig.bones.empty()) return "the model has no skin";
    if (!rig.hasRoles)
        return "its joints carry no bone roles (the skin was not made by rig.bake, so there is no (role, index, side) to find the legs, "
               "spine or arms by)";
    if (!rig.identityRest) return "its joints do not rest with identity rotations (rig.bake skeletons do)";
    return {};
}

}  // namespace fa
