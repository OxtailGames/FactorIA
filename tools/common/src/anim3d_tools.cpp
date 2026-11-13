// anim3d_tools.cpp: skinning a baked rig with a pose, the rotation <-> key conversions and the left/right mirror of a pose
// (fa/tooling/anim3d_tools.h). Shared by the anim3d.* commands and the editor's Animation panel.
#include "fa/tooling/anim3d_tools.h"

#include <algorithm>
#include <cmath>
#include <map>
#include <set>

#include "fa/scene/animation.h"

namespace fa {

MeshData skin_rig_mesh(const Anim3DRigModel& model, const Pose& pose) {
    const MeshData& bind = model.bind;
    const SkeletonAsset& sk = *model.skeleton;
    const int skin = model.rig.skin;
    const std::vector<Mat4> palette = skin_palette(sk, pose, skin);
    MeshData out = bind;
    const bool hasNormals = bind.normals.size() == bind.positions.size();
    std::size_t base = 0;
    for (const SkinVertices& sv : sk.skinVertices) {
        const std::size_t count = sv.joints.size();
        if (sv.skin == skin && !sv.rigid) {
            for (std::size_t i = 0; i < count && base + i < bind.vertex_count(); ++i) {
                const std::size_t v = base + i;
                const Vec3 p{bind.positions[v * 3], bind.positions[v * 3 + 1], bind.positions[v * 3 + 2]};
                const Vec3 n = hasNormals ? Vec3{bind.normals[v * 3], bind.normals[v * 3 + 1], bind.normals[v * 3 + 2]}
                                          : Vec3{0, 1, 0};
                Vec3 sp{}, sn{};
                float total = 0.0f;
                for (std::size_t k = 0; k < 4; ++k) {
                    const float w = sv.weights[i][k];
                    const std::size_t j = sv.joints[i][k];
                    if (w <= 0.0f || j >= palette.size()) continue;
                    sp = sp + palette[j].transform_point(p) * w;
                    sn = sn + palette[j].transform_dir(n) * w;
                    total += w;
                }
                if (total <= 0.0f) continue;
                sp = sp * (1.0f / total);
                out.positions[v * 3] = sp.x;
                out.positions[v * 3 + 1] = sp.y;
                out.positions[v * 3 + 2] = sp.z;
                if (hasNormals) {
                    const float l = std::sqrt(sn.x * sn.x + sn.y * sn.y + sn.z * sn.z);
                    if (l > 1e-8f) {
                        out.normals[v * 3] = sn.x / l;
                        out.normals[v * 3 + 1] = sn.y / l;
                        out.normals[v * 3 + 2] = sn.z / l;
                    }
                }
            }
        }
        base += count;
    }
    if (!out.positions.empty()) {  // bounds of the posed mesh
        out.bmin = out.bmax = {out.positions[0], out.positions[1], out.positions[2]};
        for (std::size_t v = 0; v + 2 < out.positions.size(); v += 3) {
            const Vec3 q{out.positions[v], out.positions[v + 1], out.positions[v + 2]};
            out.bmin = min(out.bmin, q);
            out.bmax = max(out.bmax, q);
        }
    }
    return out;
}

// ---- keys -------------------------------------------------------------------------------------------------------------------------------

std::array<float, 4> rotation_key_value(const Anim3DClip& clip, Quat delta) {
    delta = normalize(delta);
    if (clip.quat) {
        if (delta.w < 0)
            delta = {-delta.x, -delta.y, -delta.z, -delta.w};  // the short way round: the same rotation, a stable sign
        return {delta.x, delta.y, delta.z, delta.w};
    }
    const Vec3 e = delta.to_euler_deg();
    return {e.x, e.y, e.z, 0.0f};
}

Quat rotation_from_key_value(const Anim3DClip& clip, const std::array<float, 4>& v) {
    if (clip.quat) return normalize(Quat{v[0], v[1], v[2], v[3]});
    return Quat::from_euler_deg({v[0], v[1], v[2]});
}

Quat pose_delta_rotation(const Rig3D& rig, const Pose& pose, int node) {
    if (node < 0 || std::size_t(node) >= pose.rotation.size()) return Quat{};
    const Quat rest = rig.rest.rotation[std::size_t(node)];
    return normalize(rest.conjugate() * pose.rotation[std::size_t(node)]);
}

// ---- mirror -----------------------------------------------------------------------------------------------------------------------------

std::string bone_side(const std::string& bone) {
    if (bone.size() > 2 && bone.compare(bone.size() - 2, 2, "_l") == 0) return "l";
    if (bone.size() > 2 && bone.compare(bone.size() - 2, 2, "_r") == 0) return "r";
    return "";
}

std::string mirror_bone_name(const std::string& bone) {
    const std::string side = bone_side(bone);
    if (side.empty()) return bone;
    return bone.substr(0, bone.size() - 1) + (side == "l" ? "r" : "l");
}

Quat mirror_rotation(Quat q) { return {q.x, -q.y, -q.z, q.w}; }

std::vector<Anim3DPoseKey> mirror_pose_keys(const Anim3DClip& clip, const Rig3D& rig, float time,
                                            const std::string& from) {
    const SkeletonAsset& sk = *rig.skeleton;
    const Anim3DBinding binding = bind_anim3d(clip, sk);
    Pose pose = rig.rest;
    sample_anim3d(clip, binding, sk, time, pose);

    // Which (bone, channel) the clip animates: only those get a key, on both sides of a pair.
    std::set<std::pair<std::string, Anim3DChannel>> animated;
    for (const Anim3DTrack& t : clip.tracks) animated.insert({t.bone, t.channel});

    std::vector<Anim3DPoseKey> out;
    std::set<std::pair<std::string, Anim3DChannel>> done;
    auto emit = [&](const std::string& target, const std::string& source, Anim3DChannel channel) {
        const int tn = rig.find(target), sn = rig.find(source);
        if (tn < 0 || sn < 0) return;
        if (!animated.count({target, channel}) && !animated.count({source, channel})) return;
        if (!done.insert({target, channel}).second) return;
        Anim3DPoseKey k;
        k.bone = target;
        k.channel = channel;
        if (channel == Anim3DChannel::Rotation) {
            k.value = rotation_key_value(clip, mirror_rotation(pose_delta_rotation(rig, pose, sn)));
        } else if (channel == Anim3DChannel::Translation) {
            const Vec3 off = pose.translation[std::size_t(sn)] - rig.rest.translation[std::size_t(sn)];
            k.value = {-off.x, off.y, off.z, 0.0f};
        } else {
            const Vec3 s = pose.scale[std::size_t(sn)];
            const Vec3 r = rig.rest.scale[std::size_t(sn)];
            k.value = {r.x != 0 ? s.x / r.x : 1.0f, r.y != 0 ? s.y / r.y : 1.0f, r.z != 0 ? s.z / r.z : 1.0f, 0.0f};
        }
        out.push_back(k);
    };

    std::vector<std::string> names;  // every bone a track names, once, in track order
    for (const Anim3DTrack& t : clip.tracks)
        if (std::find(names.begin(), names.end(), t.bone) == names.end()) names.push_back(t.bone);
    // Add the partners of animated bones (their own track may be missing: it starts from rest).
    for (const std::string& n : std::vector<std::string>(names))
        if (std::find(names.begin(), names.end(), mirror_bone_name(n)) == names.end())
            names.push_back(mirror_bone_name(n));

    for (const std::string& bone : names) {
        const std::string side = bone_side(bone);
        const std::string partner = mirror_bone_name(bone);
        if (side.empty() && from != "swap") continue;                  // a bone on the mid plane mirrors only in a swap
        if (!side.empty() && from == "left" && side != "r") continue;  // "left" fills the right bones from the left
        if (!side.empty() && from == "right" && side != "l") continue;  // "right" fills the left bones from the right
        for (Anim3DChannel ch : {Anim3DChannel::Rotation, Anim3DChannel::Translation, Anim3DChannel::Scale})
            emit(bone, partner, ch);
    }
    // The values of a swap come from the sampled pose, which this function does not change, so the order above does not matter.
    return out;
}

}  // namespace fa
