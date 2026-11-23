// The engine-wide upscaler setting of M76 (docs/UPSCALING.md): how the picture drawn at a lower resolution reaches the screen.
// It is a setting of the whole game, not of a camera: it changes the size the frame is drawn at, like Renderer::set_render_scale.
//
// factoria.json "render.upscaler", the command render.upscaler and `window.upscaler` in scripts set it. The renderer reads it
// (Renderer::upscaler()): effective_upscaler_mode says which mode it draws with (M76-P4: "temporal" where the backend draws it).
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

// What the renderer can draw, for effective_upscaler_mode. temporal: the "temporalUpscaler" row of render.supports (a fragment
// pass on every backend; the renderer also needs the TAA shaders to have compiled). pixelArt: the game's scale mode is
// PixelPerfect, whose picture is never blended (stretch with a Nearest sampler).
struct UpscalerSupport {
    bool temporal = false;
    bool pixelArt = false;
};

// The mode the renderer really draws with (M76: P3b, P4 and P5 each change this one place). stretch: always, and for pixel art;
// temporal: where `support.temporal`; auto: the best of the modes that can be drawn (temporal for now); the others: stretch until a
// package draws them. A call without `support` (a host with no renderer) says "stretch".
UpscalerMode effective_upscaler_mode(const UpscalerSettings& s, const UpscalerSupport& support = {});

// {"mode", "quality", "sharpness"} (all three always present).
Json upscaler_to_json(const UpscalerSettings& s);

// Reads the keys of `j` that are present over `base` (a partial object changes only those): "mode" and "quality" are names,
// "sharpness" a number 0..1. An error names the place (`where` + "/key", e.g. "factoria.json#/render/upscaler" or
// "render.upscaler"), what is wrong, the valid values and a "did you mean" for a misspelt name or key. Nothing is stored.
Result<UpscalerSettings> parse_upscaler_settings(const Json& j, std::string_view where, const UpscalerSettings& base);

}  // namespace fa::render
