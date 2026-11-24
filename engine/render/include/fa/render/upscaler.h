// The engine-wide upscaler setting of M76 (docs/UPSCALING.md): how the picture drawn at a lower resolution reaches the screen.
// It is a setting of the whole game, not of a camera: it changes the size the frame is drawn at, like Renderer::set_render_scale.
//
// M76-P0 defines, validates and stores it (factoria.json "render.upscaler", the command render.upscaler, `window.upscaler` in
// scripts). The renderer draws "stretch", "spatial" (M76-P3b), "temporal" (M76-P4) and "metalfx" (M76-P5b, Apple's MetalFX on Metal);
// effective_upscaler_mode is the one place that says which mode draws; the renderer reads Renderer::upscaler().
#pragma once

#include <array>
#include <string>
#include <string_view>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::render {

// How the lower-resolution picture is brought to the output size.
//  stretch:  the plain blit of today (bilinear, or nearest for pixel-perfect and integer scales).
//  spatial:  our own edge-adaptive upscale plus a contrast-adaptive sharpen of the one frame (M76 P3b).
//  temporal: our own temporal upscaler, the jittered frames accumulated at the output size (M76 P4).
//  metalfx:  Apple's MetalFX on Metal (M76 P5).
//  auto:     the best of the above this GPU and backend can draw.
enum class UpscalerMode : std::int32_t { Stretch, Spatial, Temporal, MetalFx, Auto };
inline constexpr int kUpscalerModeCount = 5;
inline constexpr std::array<std::string_view, kUpscalerModeCount> kUpscalerModeNames = {"stretch", "spatial",
                                                                                        "temporal", "metalfx", "auto"};

// How much smaller than the output the frame is drawn: the scale factor is the share of the output's width and height.
enum class UpscalerQuality : std::int32_t { Native, Quality, Balanced, Performance, UltraPerformance };
inline constexpr int kUpscalerQualityCount = 5;
inline constexpr std::array<std::string_view, kUpscalerQualityCount> kUpscalerQualityNames = {
    "native", "quality", "balanced", "performance", "ultraPerformance"};
// 1, 1/1.5, 1/1.7, 1/2, 1/3: the linear factor of the render size against the output size.
constexpr float upscaler_quality_scale(UpscalerQuality q) {
    constexpr float kScale[kUpscalerQualityCount] = {1.0f, 1.0f / 1.5f, 1.0f / 1.7f, 0.5f, 1.0f / 3.0f};
    const int i = int(q);
    return (i >= 0 && i < kUpscalerQualityCount) ? kScale[i] : 1.0f;
}

struct UpscalerSettings {
    UpscalerMode mode = UpscalerMode::Stretch;
    UpscalerQuality quality = UpscalerQuality::Native;
    float sharpness = 0.5f;  // 0..1: the contrast-adaptive sharpen of the spatial and temporal modes
    bool operator==(const UpscalerSettings&) const = default;
};

constexpr std::string_view upscaler_mode_name(UpscalerMode m) {
    const int i = int(m);
    return (i >= 0 && i < kUpscalerModeCount) ? kUpscalerModeNames[std::size_t(i)] : std::string_view("stretch");
}
constexpr std::string_view upscaler_quality_name(UpscalerQuality q) {
    const int i = int(q);
    return (i >= 0 && i < kUpscalerQualityCount) ? kUpscalerQualityNames[std::size_t(i)] : std::string_view("native");
}

// What the renderer can draw, and what the game's display asks for, when the effective mode is decided.
struct UpscalerCaps {
    bool pixelArt =
        false;  // ScaleMode::PixelPerfect (integer scaling, Nearest): hard pixel edges are kept, nothing is filtered
    bool spatial = true;    // the "spatialUpscaler" row of render.supports: true wherever there is a GPU
    bool temporal = false;  // the "temporalUpscaler" row (M76 P4): the TAA shaders compiled and its histories fit
    bool multiCamera =
        false;  // this frame has no single full-viewport camera: the temporal upscaler (one history) cannot run
    bool metalfx =
        false;  // the "metalfx" row (M76-P5b): the Metal backend, an OS and a GPU with a MetalFX scaler, and none failed yet
    // MetalFX has its temporal scaler here (else only the spatial one, which needs no history and so draws on a frame of several cameras
    // too). Read only with `metalfx`.
    bool metalfxTemporal = true;
};

// Whether the default Metal GPU of this machine can run MetalFX, and why not when it cannot (a sentence that says what is missing and
// what to do). What a run without a renderer reports (Engine::upscaler_caps: "what a GPU here would draw"); false on every backend that is
// not Metal. `temporal` says the temporal scaler is there too. Asks the system (a Metal device is made), so call it once, not per frame.
struct MetalFxHere {
    bool available = false;  // at least the spatial scaler
    bool temporal = false;
    std::string reason;  // empty when both scalers are available
};
MetalFxHere metalfx_available_here();

// The mode the renderer really draws with, so reading the setting back never lies:
//  - pixel art (`caps.pixelArt`): always stretch (Nearest); a filter would blur the pixels the game keeps hard;
//  - stretch: stretch;
//  - spatial: spatial, stretch where the backend cannot draw it (`caps.spatial` false: no GPU);
//  - temporal and metalfx: themselves when drawable, else the next best this GPU can draw (metalfx -> temporal -> spatial); temporal
//    is not drawable when `caps.temporal` is false or the frame has several cameras (`caps.multiCamera`: one history per rectangle
//    is not made), and spatial draws instead; metalfx is not drawable when `caps.metalfx` is false (not on Metal, no MetalFX on this
//    GPU, or it failed) or, with its temporal scaler, on a frame of several cameras: the same rule as temporal;
//  - auto: the best drawable of metalfx, temporal, spatial; stretch when none is.
// Without a renderer (a run with graphics=false) the host reports what a GPU would draw: caps with pixelArt taken from the project's
// scale mode and the default `spatial` (true), so a pixel-perfect project says stretch and any other says spatial for spatial, auto,
// temporal and metalfx. The default argument is that host with a scale mode that is not pixel perfect.
UpscalerMode effective_upscaler_mode(const UpscalerSettings& s, const UpscalerCaps& caps = {});

// The render scale the game is drawn at and whether the upscale stage runs (docs/UPSCALING.md, "The render scale"): the player's scale
// (window.renderScale) times the quality's, never below `minScale` (the engine's 0.25 floor). The stage is on when that scale is below 1
// or the effective mode is not stretch (at scale 1 the renderer decides every frame, Renderer::upscale_stage: only the spatial sharpen has
// something to draw there, and a frame with several cameras makes a temporal mode spatial; the temporal and MetalFX modes draw nothing at
// scale 1), and never above 1: a scale above 1 is a bigger picture (a screenshot's "scale"), not an upscale. Only the renderer's
// `effective` mode decides: pixel art is stretch there.
// `dynamicScale` is the factor of the dynamic resolution (fa/render/dynamic_resolution.h, 1 while it is off): the one place it multiplies in.
struct UpscaleScalePlan {
    float scale = 1.0f;
    bool stage = false;
};
constexpr UpscaleScalePlan plan_upscale_scale(float windowScale, UpscalerQuality quality, UpscalerMode effective,
                                              float minScale, float dynamicScale = 1.0f) {
    float s = windowScale * upscaler_quality_scale(quality);
    if (dynamicScale != 1.0f) s *= dynamicScale;  // off is the same arithmetic as before: bit-identical
    if (!(s >= minScale)) s = minScale;           // also a NaN
    UpscaleScalePlan p;
    p.scale = s;
    p.stage = s <= 1.0f && (s < 1.0f || effective != UpscalerMode::Stretch);
    return p;
}

// {"mode", "quality", "sharpness"} (all three always present).
Json upscaler_to_json(const UpscalerSettings& s);

// Reads the keys of `j` that are present over `base` (a partial object changes only those): "mode" and "quality" are names,
// "sharpness" a number 0..1. An error names the place (`where` + "/key", e.g. "factoria.json#/render/upscaler" or
// "render.upscaler"), what is wrong, the valid values and a "did you mean" for a misspelt name or key. Nothing is stored.
Result<UpscalerSettings> parse_upscaler_settings(const Json& j, std::string_view where, const UpscalerSettings& base);

}  // namespace fa::render
