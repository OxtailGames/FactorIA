// Carries a 3D bone clip from one rig to another (docs/ANIMATION.md, "Retargeting"): a walk made for the humanoid plays on another
// humanoid with other proportions, a bird, or a quadruped's legs. Bones are matched by their canonical (role, index, side) triple, not
// by name (rig.bake names them <role>[_<index>][_<side>], so the triple and the name carry the same information).
//
//   * A bone with a track in the clip and the same triple in the target gets the track: rotations are copied (rest poses are identity
//     rotations in both rigs, so a rotation means the same in either), translations are scaled.
//   * A chain whose bone count differs (spine_1..3 against spine_1..2, a longer tail) keeps its TOTAL bend: the source bones' rotations
//     are composed and shared evenly between the target's bones. The keys of such a chain become linear keys at the union of the source
//     key times.
//   * A bone with no counterpart (a tail on a rig without one, fingers, toes) is dropped, and the result lists it. The target's bones
//     that the clip does not move rest.
//   * The root's translation, the ground speed and the feet are scaled by the ratio of the leg lengths (hip to ankle; the height of the
//     root when a rig has no legs), or by `scale` when given.
//   * Planted feet. If the clip has `contacts`, the legs that have one are solved again with the two-bone solver: each ankle follows the
//     source ankle's path (its offset from the rest pose, scaled), so a foot that stands still on the ground in the source stands still
//     in the result, whatever the leg proportions. The clip is sampled at `fps` keys per second for that. A leg that cannot reach (the
//     target's legs are too short for the path) stretches straight and is reported in the notes.
#pragma once

#include <string>
#include <vector>

#include "fa/core/types.h"
#include "fa/scene/anim3d.h"
#include "fa/scene/rig3d.h"

namespace fa {

struct RetargetOptions {
    bool plantFeet = true;  // solve the legs with a contact again, so they keep their feet planted
    float scale = 0.0f;     // 0 = the ratio of the leg lengths; else the factor for root motion, ground speed and the feet
    float fps = 30.0f;      // keys per second of the re-solved legs
};

struct RetargetResult {
    Anim3DClip clip;
    float scale = 1.0f;
    int mapped = 0;                      // tracks copied or resampled
    std::vector<std::string> dropped;    // source bones with no counterpart in the target
    std::vector<std::string> resampled;  // roles whose bone count differed (spine, tail...)
    std::vector<std::string> planted;    // end bones whose legs were solved again
    std::vector<std::string> notes;      // anything else worth telling: unreachable feet, no legs to scale by
};

// Both rigs need bone roles (a rig.bake skeleton). Errors teach which rig lacks what.
Result<RetargetResult> retarget_anim3d(const Anim3DClip& clip, const Rig3D& from, const Rig3D& to, const RetargetOptions& options = {});

}  // namespace fa
