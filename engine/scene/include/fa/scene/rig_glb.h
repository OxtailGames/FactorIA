// The skinned .glb of a rig (docs/RIGGING.md, "The .glb"): the model's mesh exactly as mesh_to_glb writes it, plus one glTF skin whose joints are the
// bones of the fit (a node each, translation = head - parent head, identity rotation and scale, `extras` {role, index, side}) and whose
// inverseBindMatrices are translate(-head), so the rest pose draws the model unchanged. Every primitive gets JOINTS_0 and WEIGHTS_0 from the rigid
// weights (rig_skin.h) or, with none given, from the rigid binding (rig_fit.h: one bone per vertex, weight 1); nothing else in the file changes.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/types.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/rig_fit.h"
#include "fa/scene/rig_skin.h"

namespace fa {

// `glbPath` is where the file will be written (project-relative): texture uris are relative to its folder, as in mesh_to_glb. `weights` (one entry per
// vertex of `model`, bones of `fit`) are what the file stores; null: the rigid binding.
Result<std::vector<std::uint8_t>> rig_to_glb(const MeshData& model, const RigFit& fit, const std::string& glbPath, const RigWeights* weights = nullptr);

}  // namespace fa
