// What the 3D clip commands (anim3d.*, ik3d.key; tools/common/src/assets_anim3d.cpp) and the editor's Animation panel share about a rigged
// model: loading a baked rig with its bind mesh, skinning that mesh with a Pose, the left/right mirror of a pose and the conversion of a
// bone's rotation into the key a clip stores. GPU-free; the maths is fa_scene's (anim3d.h, rig3d.h) and deterministic.
#pragma once

#include <array>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/anim3d.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/rig3d.h"
#include "fa/scene/skeleton.h"

namespace fa {

// A baked rig (the .glb rig.bake writes) as a tool uses it: the skeleton (shared and cached by path), the Rig3D that points into it and the
// mesh in its bind pose. Keep the shared_ptr alive while the Rig3D is used.
struct Anim3DRigModel {
    std::string path;  // the project-relative .glb
    std::shared_ptr<const SkeletonAsset> skeleton;
    Rig3D rig;
    MeshData bind;
};

// Loads `rigPath`, a .rig.glb or the .rig.json that bakes it, from project `projectDir`. The Error says what is wrong with "did you mean".
Result<std::shared_ptr<Anim3DRigModel>> load_anim3d_rig_model(const std::string& projectDir, const std::string& rigPath);

// The bind mesh of `model` skinned by `pose`, the way the renderer draws the Animator (its bounds are the posed ones).
MeshData skin_rig_mesh(const Anim3DRigModel& model, const Pose& pose);

// ------------------------------------------------------------------------------------------------------------ keys --
// One value for one channel of one bone at one time: 3 numbers (euler degrees pitch, yaw, roll; a translation; a scale) or 4 (a
// quaternion x y z w, for a rotation in a clip whose rotation is "quat").
struct Anim3DPoseKey {
    std::string bone;
    Anim3DChannel channel = Anim3DChannel::Rotation;
    std::array<float, 4> value{};
};

// The value a clip stores for a bone rotated by `delta` from its rest, euler or quaternion as the clip says.
std::array<float, 4> rotation_key_value(const Anim3DClip& clip, Quat delta);
// The rotation a stored key value stands for (the inverse).
Quat rotation_from_key_value(const Anim3DClip& clip, const std::array<float, 4>& value);

// The rotation of `node` away from its rest in `pose` (rest * delta = the local rotation, so delta = rest^-1 * local).
Quat pose_delta_rotation(const Rig3D& rig, const Pose& pose, int node);

// ------------------------------------------------------------------------------------------------------------ mirror --
// The bone on the other side of the body by canonical name: thigh_l <-> thigh_r. A bone with no side (spine_1, root, head) is its own mirror.
std::string mirror_bone_name(const std::string& bone);
// "l", "r" or "" (no side) for a canonical bone name.
std::string bone_side(const std::string& bone);
// The reflection across the character's mid plane (x -> -x) of a local rotation: pitch stays, yaw and roll change sign.
Quat mirror_rotation(Quat q);

// Keys that mirror the pose of `clip` at `time` left to right, for the bones the clip animates. `from`: "swap" (default) exchanges both
// sides and mirrors the bones on the mid plane in place; "left" copies the left side onto the right one; "right" the other way. Only bones
// that have a track (on either side of the pair) get a key; nothing else changes. Deterministic.
std::vector<Anim3DPoseKey> mirror_pose_keys(const Anim3DClip& clip, const Rig3D& rig, float time, const std::string& from = "swap");

}  // namespace fa
