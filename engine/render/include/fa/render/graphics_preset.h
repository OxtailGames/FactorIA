// The graphics quality presets of M76 (docs/UPSCALING.md, "Graphics presets"): Low, Medium, High, Ultra, and "custom" for the
// game's own look.
//
// A preset is a QUALITY LAYER of the engine, not a change of the scene: every knob below is a LIMIT the renderer applies to what the
// scene, the camera's PostProcess and the lights ask for. A limit only ever lowers (a scene that asks for 2 shadow cascades under a
// limit of 4 still draws 2), and the default value of every field is "no limit", so Ultra is the game as its author made it and
// "custom" (no preset) is exactly that too. Nothing is written into the scene, its components or the project file: leaving a preset
// brings the game's own look back unchanged. The simulation never reads a limit.
//
// This header holds the names, the table of limits of each preset and their JSON; Renderer::set_quality() applies a set of limits and
// Renderer::resolve_graphics_preset() caps a preset by what the GPU can draw (render.supports), with the reason of every cap.
#pragma once

#include <array>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/render/raytracing.h"
#include "fa/render/upscaler.h"
#include "fa/scene/components.h"
#include "fa/scene/postprocess.h"

namespace fa::render {

enum class GraphicsPreset : std::int32_t { Low, Medium, High, Ultra, Custom };
inline constexpr int kGraphicsPresetCount = 5;
inline constexpr std::array<std::string_view, kGraphicsPresetCount> kGraphicsPresetNames = {"low", "medium", "high",
                                                                                            "ultra", "custom"};

constexpr std::string_view graphics_preset_name(GraphicsPreset p) {
    const int i = int(p);
    return (i >= 0 && i < kGraphicsPresetCount) ? kGraphicsPresetNames[std::size_t(i)] : std::string_view("custom");
}
// "low", "Low" or "LOW" -> Low; anything else -> nullopt (the caller teaches with did_you_mean over kGraphicsPresetNames).
std::optional<GraphicsPreset> parse_graphics_preset(std::string_view name);

// The limits of one quality layer. Every field is a cap on what the scene asks for; the defaults are the loosest value, i.e. no limit.
// A bool is "may be drawn" (false switches the feature off whatever the scene says), a number is the most the renderer uses.
struct QualityLimits {
    // Post stack (the camera's PostProcess and its volumes, after they are blended).
    bool temporalAA = true;
    bool ssao = true;
    SsaoQuality ssaoQuality = SsaoQuality::Ultra;  // the most directions and steps of the ambient occlusion
    bool ssr = true;
    int ssrSteps = 128;  // steps along a reflection ray (the effect's own range is 8..128)
    bool sunShafts = true;
    bool depthOfField = true;
    bool depthOfFieldBokeh = true;  // false: the smooth blur, even where the scene asks for the bokeh discs
    bool motionBlur = true;
    int motionBlurSamples = 32;  // taps along the movement (the effect's own range is 4..32)
    // Shadows (SceneSettings, Light).
    int shadowCascades = 4;      // cascades of the directional light's map (1..4)
    int shadowAtlasSize = 8192;  // texels per side of the shadow atlas
    int shadowTileSize = 4096;   // texels per side of one shadow map a light asks for with Light.shadowResolution
    bool softShadows = true;     // false: a PCSS light (Light.shadowFilter pcss) is drawn with the plain PCF filter
    bool localShadows = true;    // shadows of point and spot lights
    bool contactShadows = true;  // the screen-space contact shadows
    bool volumetricFog = true;   // SceneSettings.volumetricFog
    VolumetricQuality volumetricQuality = VolumetricQuality::High;
    // Level of detail and big worlds (M75).
    float lodDistanceScale =
        1.0f;  // >= 1: the distance a mesh or a LodGroup picks its level at is multiplied by it (levels switch sooner)
    float foliageDensity = 1.0f;   // 0..1: multiplies Foliage.density
    float foliageDistance = 1.0f;  // 0..1: multiplies Foliage.lodDistance, fadeStart and fadeEnd
    float terrainLodQuality =
        1.0f;  // 0..1: multiplies Terrain.lodQuality (the mesh density and the distances of the coarser rings)
    // 2D lighting and global illumination.
    bool gi2d = true;  // GlobalIllumination2D
    GI2DQuality gi2dQuality = GI2DQuality::High;
    float gi2dResolutionScale = 1.0f;  // caps GlobalIllumination2D.resolutionScale (0.1..1)
    float lightScale = 1.0f;  // caps SceneSettings.lightScale, the size of the Light2D buffer as a share of the picture
    // Realtime global illumination (M73).
    int realtimeGiProbesPerFrame = 32;  // caps RealtimeGI.probesPerFrame (1..32): how fast the probe grid updates
    // Ray tracing (M79, docs/RAY_TRACING.md): what render.rayTracing may ask for. A preset only CAPS the project's setting, never turns it on:
    // a game whose `render.rayTracing.enabled` is false traces nothing under any preset, and an effect the game left off stays off. The
    // defaults are the loosest value, so `custom` and ultra leave the game's own setting as it is. A device that cannot trace rays is not
    // changed by any of these (nothing traces there).
    RtShadows rtShadows = RtShadows::Soft;  // the most the shadows may be traced: off, hard or soft
    bool rtAo = true;            // false: ray traced ambient occlusion is not drawn (the screen-space one stays)
    bool rtReflections = true;   // false: ray traced reflections are not drawn
    bool rtTranslucency = true;  // false: ray traced refraction through glass is not drawn
    RtGi rtGi = RtGi::PerPixel;  // the most global illumination may be traced: off, probes or perPixel
    int rtRaysPerPixel = kRtMaxRaysPerPixel;  // caps RayTracingSettings.raysPerPixel (1..16)

    bool operator==(const QualityLimits&) const = default;
};

// What a preset sets: the limits above and the upscaler setting (mode, quality, sharpness). "ultra" and "custom" are unlimited and set
// no upscaler: the game keeps its own, so their picture is the same bit for bit.
struct GraphicsPresetTable {
    QualityLimits limits;
    std::optional<UpscalerSettings> upscaler;
};
// The table of one preset (Custom: no limit, no upscaler). It never changes at run time; every limit is the value the preset wants,
// before the GPU's own caps (Renderer::resolve_graphics_preset).
const GraphicsPresetTable& graphics_preset_table(GraphicsPreset p);

// {knob: value}: every field of QualityLimits by its name, bools as booleans, the quality enums as their names ("low" .. "ultra"),
// numbers rounded to 3 decimals.
Json quality_limits_to_json(const QualityLimits& q);
// The knob names of quality_limits_to_json, in its order.
const std::vector<std::string>& quality_knob_names();
// The same knobs as numbers where a higher number is a higher quality (a bool is 0 or 1, an enum its index, lodDistanceScale is
// 1 / scale): what the monotony of the presets is checked with. Same order as quality_knob_names().
std::vector<double> quality_knob_levels(const QualityLimits& q);

// `s` as a graphics preset lets it be drawn: shadows, gi and raysPerPixel at most the limit's, an effect the limit switches off turned off.
// `enabled` and `maxInstances` are never touched, and nothing is turned on that `s` has off. With the default limits it returns `s`.
RayTracingSettings apply_quality_to_ray_tracing(const RayTracingSettings& s, const QualityLimits& q);

// One knob the GPU capped below what the preset wants.
struct QualityCap {
    std::string knob;    // a name of quality_knob_names()
    Json wanted;         // what the preset's table says
    Json effective;      // what the renderer uses on this GPU
    std::string reason;  // one sentence naming the backend or the missing capability (the status render.supports gives)
};

// A preset as the renderer applies it on this GPU.
struct QualityResolved {
    GraphicsPreset preset = GraphicsPreset::Custom;
    QualityLimits limits;  // the table's limits after the GPU's caps
    std::optional<UpscalerSettings> upscaler;
    std::vector<QualityCap> capped;
    bool gpu = true;  // false: no GPU (the headless backend): nothing is capped, and nothing is drawn
};

// `preset` with no GPU to cap it (the engine runs without graphics): the table as it is, `gpu` false.
QualityResolved resolve_graphics_preset_uncapped(GraphicsPreset preset);

}  // namespace fa::render
