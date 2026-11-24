// The upscale stage (M76-P3a): brings the frame's picture from the render resolution (design size * renderScale) back to the output
// resolution (the design size) when the game is drawn below it, and is the seam the spatial, temporal and MetalFX upscalers plug into
// (docs/design/ARCHITECTURE_RENDERING.md, "Upscale stage (M76)"). The stage is a pass of the frame graph that runs after the post
// stack and the colour filter of the render-resolution picture; the screen-space items (HUD, UI, debug text) are drawn after it, into
// the output image, at the output resolution.
//
// Off (no pass, no image) unless Renderer::set_upscale_stage(true) and the render scale is below 1: the picture then goes from
// the game target to present() as it always did.
#pragma once

#include <cstdint>
#include <string_view>

#include "sokol_gfx.h"

namespace fa::render {

// How the picture is brought to the output resolution. Stretch is a copy through a Linear sampler (Nearest for pixel art): the image
// the renderer made at scale 1 is never touched by it. Spatial (M76-P3b, shaders/upscale_spatial.glsl) is the edge-adaptive upsample
// and the contrast-adaptive sharpen. Temporal (M76-P4): the camera is jittered at the render resolution and the TAA resolve accumulates the
// frames into a history of the OUTPUT resolution (renderer_taa.h, TaaFx::upscale); where it cannot run, spatial draws. The package after
// adds MetalFx here and a case in Renderer::Impl::run_upscale.
enum class UpscaleImpl : std::uint8_t { Stretch, Spatial, Temporal };

// The implementation a mode name selects ("stretch", "spatial", "temporal"; later "metalfx"). A name this build does not know (a
// typo, a mode of a later version, an implementation the GPU cannot run) selects Stretch: the game is never left without a picture.
// `known`, when given, says whether the name was understood. ("auto" is not an implementation: effective_upscaler_mode picks one.)
UpscaleImpl select_upscale_impl(std::string_view mode, bool* known = nullptr);
const char* upscale_impl_name(UpscaleImpl impl);

// The length of the jitter sequence of the temporal upscaler: ceil(8 * (output area / render area)), so every output pixel is covered by
// about eight samples of the sequence whatever the ratio (8 at a ratio of 1, 18 at 1.5 per side, 32 at 2, 72 at 3), at most
// kJitterPhasesMax. Pure CPU. A size below 1 reads as 1.
int upscale_jitter_phases(int renderW, int renderH, int outW, int outH);

// What an upscaler reads. `color` is the picture at the render resolution (display values after a final pass, else the scene's
// colour: the format of the output image is the same, so the copy never converts). `depth` (linear view depth) and `velocity` are
// null views until the passes that make them exist; an implementation that needs them must work without (camera reprojection).
struct UpscaleInput {
    sg_view color{};
    sg_view depth{};
    sg_view velocity{};
    float jitter[2] = {0.0f, 0.0f};  // this frame's camera jitter, in render pixels (0 until a temporal mode jitters)
    int renderW = 0, renderH = 0;    // size of `color`
    int outW = 0, outH = 0;          // size of the output image
    std::uint64_t frameIndex = 0;    // the renderer's frame counter (Renderer::Impl::frameSerial)
    bool resetHistory = false;       // a cut, a resize or a change of mode: drop what was accumulated
    bool pixelArt = false;           // ScaleMode::PixelPerfect: sample with Nearest, never blend
    bool linear =
        false;  // `color` holds linear light (a linear scene without a final pass): filters work on a perceptual curve
    float sharpness = 0.0f;  // UpscalerSettings::sharpness, 0..1: the sharpen of Spatial (Stretch ignores it)
};

}  // namespace fa::render
