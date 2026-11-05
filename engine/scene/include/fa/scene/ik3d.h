// 3D inverse kinematics for skinned rigs (docs/ANIMATION.md, "3D IK"): two-bone limbs with a pole vector, look-at with angle
// limits, and foot placement on the ground (a ray per foot, the pelvis lowered to fit). The solvers here work on a Pose of a
// SkeletonAsset in the model's space and need nothing else, so tests, the clip generators (anim3d_gen.h) and the commands use
// the very same maths the IK3D component runs every step. update_ik3d() is that component's system: it runs after the Animator
// (engine.cpp, "After the Animator") and rewrites the palettes of the Animators that have an IK3D.
//
// Deterministic: only + - * / sqrt and fa::det trigonometry; no wall clock, the step is the engine's fixed one.
#pragma once

#include <functional>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/rig3d.h"
#include "fa/scene/world.h"

namespace fa {

// ------------------------------------------------------------------------------------------------------------- solvers --
struct TwoBoneResult {
    bool reached = true;   // the target was inside the limb's reach (min..max); false = the limb is straight (or folded) towards it
    float error = 0.0f;    // distance from the end of the chain to the target after solving
    Vec3 end{};            // where the end bone's head is after solving, model space
};
// Turns `root` and `mid` so the head of `end` reaches `target` (model space). `mid` must be a child of `root` and `end` a child of
// `mid`. The mid joint bends towards `pole` (a point in model space; the plane of root, target and pole); with no pole it keeps the
// side it already bends to. `weight` 0..1 blends the solved rotations with the ones `pose` had. The lengths of the two bones are
// the ones of the current pose. `endRotation` (global) is applied to `end` when given. The error names the nodes when the chain is
// not root -> mid -> end.
Result<TwoBoneResult> solve_two_bone(const SkeletonAsset& skeleton, Pose& pose, int root, int mid, int end, Vec3 target,
                                     const std::optional<Vec3>& pole = std::nullopt, float weight = 1.0f,
                                     const std::optional<Quat>& endRotation = std::nullopt);

struct LookAtParams {
    Vec3 forward{0, 0, 1};     // the bone's own axis that looks at the target (its local axis: the model's axes at rest)
    float yawLimit = 70.0f;    // degrees the aim may turn left or right from the animated aim, 0..180
    float pitchLimit = 45.0f;  // degrees up or down, 0..90
    float weight = 1.0f;       // 0..1: how much of the turn is applied
    float maxTurn = 0.0f;      // radians the turn offset may change in this call (0 = no limit: the aim snaps)
};
struct LookAtResult {
    bool clamped = false;  // the target is outside the limits: the bone aims as far as they allow
    float yaw = 0.0f;      // degrees turned from the animated aim (as applied: the weight and turn speed count); positive turns +Z towards +X (character-left)
    float pitch = 0.0f;    // degrees turned up (positive) or down
};
// Turns `bone` so its `forward` axis points at `target` (model space), within the limits measured from the aim the animation gave
// it. `state` carries the turn between calls (identity at first): with `maxTurn` it moves towards the wanted turn at that speed,
// which smooths a head that follows a moving target.
LookAtResult solve_look_at(const SkeletonAsset& skeleton, Pose& pose, int bone, Vec3 target, const LookAtParams& params,
                           Quat& state);

// ------------------------------------------------------------------------------------------------------ the component --
// What the foot placement asks of the world: the first thing a ray hits. `origin` and `direction` are in world space; `ignore` is
// the entity that casts (its own colliders must not count).
struct GroundHit {
    Vec3 point{};
    Vec3 normal{0, 1, 0};
};
using GroundRaycast =
    std::function<std::optional<GroundHit>(Vec3 origin, Vec3 direction, float maxDistance, std::int32_t mask, Entity ignore)>;

// Solves the IK3D of every entity that has an Animator (after update_animators): copies the animated pose, applies the solvers in
// order, writes the Animator's palettes. `ground` answers the foot rays (null = no ground: foot solvers leave their feet alone).
void update_ik3d(World& world, float dt, const GroundRaycast& ground);

// One problem of the `solvers` of an IK3D: where (a JSON pointer such as "/2/root"), what, and how to fix it.
struct IKIssue {
    std::string pointer;
    std::string message;
    std::string hint;
};
// Checks the shape of `solvers` (types, keys, number ranges). With a rig it also checks the bone names ("did you mean").
std::vector<IKIssue> ik3d_check_solvers(const Json& solvers, const Rig3D* rig);

// One solver run offline, for authoring (ik3d.solve): `solver` is one entry of IK3D.solvers whose targets are positions [x, y, z] in the
// model's space (an entity target is an error: there is no scene). A twoBone solver reaches its target; a lookAt solver aims; a foot solver
// puts the ankle at the height of a flat ground at `groundHeight`. `pose` is solved in place. The Json has {type, reached, error, bones: [{bone,
// head}]} for a limb, {clamped, yaw, pitch, aim} for a look-at.
Result<Json> ik3d_solve_once(const Rig3D& rig, Pose& pose, const Json& solver, float groundHeight = 0.0f);

}  // namespace fa
