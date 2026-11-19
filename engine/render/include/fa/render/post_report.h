// What the post-processing stack of a camera is and where each of its values comes from (the `postprocess.get` command with
// `resolved: true`, and the editor's Post-processing panel). Pure CPU: it needs no renderer and no GPU, so a run with graphics=false
// answers like a window does. The stack is the one the renderer draws (render/src/postprocess_resolve.h): the camera's own
// PostProcess (or the deprecated Camera.bloom* / colorFilter fields that stand in for it), then the volumes the camera is inside, by
// priority.
#pragma once

#include "fa/core/json.h"
#include "fa/scene/world.h"

namespace fa::render {

// The report of `camera` (a Camera entity; null = the default camera of a world without one):
//   {camera: id ("" for the default camera), position: [x, y, z], perspective,
//    layers: [{index, from, kind, entity, priority, weight, influence, strength}],
//    effects: [{name, enabled, layers: [index], fields: {<field>: {value, from, strength}}}],   // every effect, canonical order
//    count: how many effects run,
//    customPasses: [{name, material, position, enabled, materialParams, from}],   // PostProcess.customPasses in the order they are drawn
//    customPassProblems: [string]}                                                // entries that do not parse (pointer, what, hint)
// `from` is "own" (the camera's PostProcess), "legacy" (its Camera.bloom* / colorFilter fields), "volume:<entity id>", or "default" for
// a value no layer wrote (a switch that a layer too weak to switch left at its neutral value). `strength` is how strongly the layer
// was applied (its weight times how deep the camera is inside the volume). `fields` is only there for an effect that runs.
Json post_stack_report(World& world, Entity camera);

}  // namespace fa::render
