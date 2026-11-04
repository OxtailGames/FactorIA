// A skeleton seen as a rig (docs/RIGGING.md, "Clips, IK and retargeting"): the bones of one skin of a SkeletonAsset by canonical
// name and by (role, index, side), their rest positions and directions, and the maths every 3D clip tool shares: global frames of a
// Pose, posing a bone by its GLOBAL rotation, shortest-arc rotations and the character's own axes. GPU-free and deterministic:
// only + - * / sqrt and the fa::det trigonometry, so a clip made on one machine poses the same bits on another.
//
// CONVENTIONS of a rig.bake skeleton: +Y is up, the character looks towards +Z, character-left is +X; every bone rests with an
// identity rotation, so the rotation a clip stores for a bone is the rotation of the bone's local frame, which at rest has the
// model's own axes ("pitch x tips an upward-pointing bone forward").
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/skeleton.h"

namespace fa {

// Global position (the bone's head) and rotation of every node of a Pose, indexed like SkeletonAsset::nodes. Scale is ignored:
// the solvers assume unit bone scale, which is what every rig has.
struct PoseFrame {
    std::vector<Vec3> pos;
    std::vector<Quat> rot;
};

PoseFrame pose_frame(const SkeletonAsset& skeleton, const Pose& pose);
// Recomputes `frame` (all of it: a rig has at most 64 bones).
void refresh_frame(const SkeletonAsset& skeleton, const Pose& pose, PoseFrame& frame);
// Turns the local rotation of `node` so its GLOBAL rotation becomes `global`; `frame` is refreshed.
void set_global_rotation(const SkeletonAsset& skeleton, Pose& pose, PoseFrame& frame, int node, Quat global);
// The shortest rotation taking direction `from` to direction `to` (identity when either is near zero; any perpendicular axis
// for opposite directions).
Quat rotation_between(Vec3 from, Vec3 to);
// Angle in degrees of the rotation `q` (0..180).
float rotation_angle_deg(Quat q);
// The unit axis a name like "+x", "-z", "y" stands for (+ is optional); false when the text is not one of them.
bool parse_axis_name(std::string_view text, Vec3& out);

struct Rig3D {
    const SkeletonAsset* skeleton = nullptr;  // not owned: keep it alive while the Rig3D is used
    int skin = 0;
    std::vector<int> bones;                   // node of each joint of the skin, in skin order (parents first)
    std::vector<int> boneOfNode;              // node -> index in `bones`, -1 when the node is not a joint
    std::string templateName;                 // the rig.bake template ("humanoid"...), "" when the skin has none
    bool hasRoles = false;                    // at least one joint carries a (role, index, side)
    bool identityRest = true;                 // every joint rests with an identity rotation (the rig.bake layout)
    Pose rest;
    PoseFrame restFrame;
    std::vector<Vec3> axis;                   // per node: unit rest direction head -> tail in model space, (0,0,0) = unknown
    std::vector<float> length;                // per node: head -> tail distance at rest, 0 = unknown

    int node_count() const { return skeleton ? int(skeleton->nodes.size()) : 0; }
    const SkelNode& node(int n) const { return skeleton->nodes[std::size_t(n)]; }
    bool is_bone(int n) const { return n >= 0 && std::size_t(n) < boneOfNode.size() && boneOfNode[std::size_t(n)] >= 0; }
    // The joint node named `name` (canonical `role[_index][_side]`), -1 when the skin has none.
    int find(std::string_view name) const;
    // The joint with this triple (index 0 = the only one of its role and side), -1 when the skin has none.
    int find_role(std::string_view role, int index, std::string_view side) const;
    // The joints of `role` on `side` ("" = no side), by ascending index: the spine chain, a tail, one leg's bones.
    std::vector<int> chain(std::string_view role, std::string_view side = {}) const;
    // Names of every joint (for "did you mean").
    std::vector<std::string> bone_names() const;
    // Head position and rest direction of a bone in model space (rest pose).
    Vec3 rest_head(int node) const { return restFrame.pos[std::size_t(node)]; }
};

// Builds the rig view of skin `skin`. Never fails: a skeleton with no skin gives an empty rig (no bones).
Rig3D make_rig3d(const SkeletonAsset& skeleton, int skin = 0);

// A rig.bake-style skeleton is what the generators and the retargeting need: roles on the joints and identity rest rotations.
// Empty when it is, else what is missing.
std::string rig_generator_problem(const Rig3D& rig);

}  // namespace fa
