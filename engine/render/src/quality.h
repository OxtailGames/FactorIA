// The quality layer of the renderer (fa/render/graphics_preset.h): what a preset caps on this GPU, and the cap on a camera's post stack.
#pragma once

#include "fa/render/graphics_preset.h"
#include "postprocess_resolve.h"
#include "render_features.h"

namespace fa::render {

// `preset` as the renderer applies it under `env`: the table of the preset, with every knob the GPU cannot honour lowered or switched off and
// the reason in QualityResolved::capped (the status render.supports gives for the feature, or the GPU's texture limit). On the headless
// backend (no GPU: nothing is drawn) the table is returned as it is, and `gpu` is false. Pure: a test passes the FeatureEnv of any backend.
QualityResolved resolve_quality(GraphicsPreset preset, const FeatureEnv& env);

// Lowers a camera's resolved post stack to `q`: an effect `q` does not allow leaves the mask (and its Enabled flag), and the quality
// numbers of the others are capped. The stack is the renderer's own copy for the frame; the components are never touched.
void apply_quality_limits(PostStack& stack, const QualityLimits& q);

}  // namespace fa::render
