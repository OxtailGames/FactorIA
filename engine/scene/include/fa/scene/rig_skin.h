// Skin weights of a rig (docs/RIGGING.md, "Skin weights"): which bones move each vertex of the model and how much. The input is the document's `skin`
// section (rig_skin_doc.h), the fitted skeleton (rig_fit.h) and the evaluated model; the output is four (bone, weight) pairs per vertex, the numbers
// the .glb stores in JOINTS_0 and WEIGHTS_0, plus a report of how good they are.
//
// METHODS, per part of the model (the document's `skin.method` is the default, `skin.parts` overrides one part):
//   heat    bone heat diffusion on the surface: smooth, local weights that follow the shape. The mesh is welded by position for the solve (the seams
//           of a primitive, the hard edges of a box), so it works on the meshes the engine makes, SDF creatures included; each piece of the surface
//           is solved on its own, so a mesh made of several loose parts is fine.
//   voxel   distance along a voxelised copy of the surface: slower to converge to a smooth result but it needs no manifold, closed or consistently
//           oriented mesh. It is also what a part falls back to when the heat solve cannot converge.
//   rigid   the whole part follows one bone (robot style): the bone `skin.parts[part].bone`, or the bone of the part's own bones that is nearest to
//           the part's centre.
//   auto    heat, except in a `generic` rig, where every part is rigid: the bones were placed on parts, so each part is one bone.
//
// A vertex may only follow the bones that claim its part in the fit and their neighbours in the hierarchy (a part no bone claims may follow all of
// them), a blend never reaches further than `maxHops` bones from its strongest one, the weights are smoothed over the surface `smooth` times, limited
// to `maxInfluences` and normalised. `skin.edits` are then applied in order. Everything is deterministic: the same inputs give the same bits.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/rig_doc.h"
#include "fa/scene/rig_fit.h"

namespace fa {

// Four influences per vertex, strongest first; unused slots are bone 0 with weight 0. The weights of a vertex sum to 1.
struct RigWeights {
    std::vector<std::uint16_t> joints;  // 4 per vertex
    std::vector<float> weights;         // 4 per vertex
    std::size_t vertex_count() const { return joints.size() / 4; }
};

struct RigSkinPartReport {
    std::string part;    // "" for triangles that belong to no part
    std::string method;  // what was used: heat, voxel, rigid (a fallback says so in `note`)
    std::size_t vertices = 0;
    std::vector<std::string> bones;  // the bones the part could follow
    std::string note;
};

struct RigSkinReport {
    std::size_t vertices = 0;
    std::size_t unweighted = 0;  // vertices the method gave nothing for (they follow the nearest bone)
    int maxInfluences = 0;       // the most bones any vertex follows
    double meanInfluences = 0;
    std::size_t farBlends = 0;  // vertices that blend two bones more than `maxHops` bones apart in the hierarchy
    std::size_t editsApplied = 0;
    std::size_t mirrorUnmatched = 0;  // vertices a mirror edit found no partner for (left as they were)
    std::vector<RigSkinPartReport> parts;
    std::vector<std::pair<std::string, std::size_t>>
        boneVertices;  // vertices whose strongest bone it is, in bone order (bones with none included)
    std::vector<std::string> idleBones;  // bones that are the strongest of no vertex
    std::vector<std::string> warnings;   // each says what was noticed and what to change
    int heatComponents = 0, heatFailed = 0, heatIterations = 0;
};

struct RigSkinResult {
    RigWeights weights;
    RigSkinReport report;
};

// Computes the weights. Fails, naming the field and the fix, when a part named in `skin.parts` or in an edit is not in the model, or the rig has no
// bones. `fit` was made for `model` (rig_fit.h); a vertex is the part of the first triangle that uses it.
Result<RigSkinResult> compute_rig_skin(const RigSkinSettings& settings, const RigFit& fit, const MeshData& model);

Json rig_skin_report_to_json(const RigSkinReport& report);

// One bone bent for a posed preview or a test: rotated by `degrees` about `axis` through its head, taking its children along. A zero axis means the
// axis perpendicular to the bone (the bone's direction crossed with +Y, or with +Z when the bone is vertical): the bend of a knee or an elbow.
struct RigBonePose {
    int bone = 0;
    Vec3 axis{0, 0, 0};
    float degrees = 0;
};
// The model's positions (3 floats per vertex) deformed by linear blend skinning with `poses`; the rest pose with none.
std::vector<float> rig_skin_pose(const RigFit& fit, const RigWeights& weights, const std::vector<float>& positions,
                                 const std::vector<RigBonePose>& poses);

// How many bones apart two bones are in the hierarchy (0 = the same bone).
int rig_bone_hops(const RigFit& fit, int a, int b);

}  // namespace fa
