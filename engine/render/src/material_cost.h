// What a MeshRenderer's material costs the renderer (M73-P6b): the one source of truth of the material inspector's "cost" view and of the
// command render.material_cost (Renderer::material_cost). Each feature a material can switch on is listed with what it adds: an extra pass of
// the frame (transmission copies the opaque picture, a full-shader material draws the mesh once per pass), a phase change (blended meshes are
// drawn after the opaque ones, far to near), or only fragment work (the clear coat, sheen and anisotropy lobes). The editor shows the report's
// own `summary` and `features` and decides nothing itself, so it cannot disagree with the renderer.
//
// The decisions are the renderer's own functions (mesh_is_transmissive and mesh_is_blended in render_scene.h, the full flag and the passes of
// the material asset), not a copy of them; `levels` is the number of atlas levels the copy of a `targetW` x `targetH` picture makes
// (renderer_xmit.h, xmit_layout), so the pass count is the one the frame will run.
#pragma once

#include "fa/core/json.h"
#include "fa/scene/components.h"

#include "render_internal.h"

namespace fa::render {

// {extraPasses, phase: "opaque" | "blended", summary, features: [{name, field, active, cost: "extraPass" | "phase" | "shader", extraPasses,
// note}]}. `mesh` and `material` may be null (the mesh did not load, no material): only the MeshRenderer's own fields count then.
// `targetW` x `targetH`: the size of the picture the transmission copy would read (0 when unknown: the largest atlas).
Json material_cost_report(const MeshRenderer& mr, const MeshAsset* mesh, const MaterialAsset* material, int targetW,
                          int targetH);

}  // namespace fa::render
