// The ray tracing settings of M79 (docs/RAY_TRACING.md): which effects the renderer would trace with rays, and how many. A setting of the
// whole game, like the upscaler (fa/render/upscaler.h) and the frame generation (fa/render/framegen.h).
//
// factoria.json "render.rayTracing" and Engine::set_ray_tracing define, validate and store it. It is OFF by default and free when off: no
// acceleration structure is made, no pass is added to the frame, no memory is held. Nothing draws with the settings yet (the backends and the
// effects come one by one in milestone 79); `renderer.supports("raytracing")` and render.supports say whether the device could trace.
#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <string_view>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::render {

// How the sun and the lights' shadows are made: off = the shadow maps of the lighting (no rays), hard = one ray per light towards its
// centre (a sharp edge), soft = rays towards a point of the light's disc, so the edge softens with the distance to the caster.
enum class RtShadows : std::int32_t { Off, Hard, Soft };
inline constexpr int kRtShadowsCount = 3;
inline constexpr std::array<std::string_view, kRtShadowsCount> kRtShadowsNames = {"off", "hard", "soft"};

// Global illumination: off = the engine's own (light probes and the ambient), probes = light probes updated with rays, perPixel = a
// bounce traced for every pixel (the most expensive).
enum class RtGi : std::int32_t { Off, Probes, PerPixel };
inline constexpr int kRtGiCount = 3;
inline constexpr std::array<std::string_view, kRtGiCount> kRtGiNames = {"off", "probes", "perPixel"};

// The default and the limits of the numbers (a value outside is clamped, never an error).
inline constexpr int kRtDefaultRaysPerPixel = 1;
inline constexpr int kRtMinRaysPerPixel = 1;
inline constexpr int kRtMaxRaysPerPixel = 16;
inline constexpr int kRtDefaultMaxInstances = 65536;
inline constexpr int kRtMinMaxInstances = 1;
inline constexpr int kRtMaxMaxInstances = 1 << 20;

struct RayTracingSettings {
    // The master switch. false (the default): nothing below is read, nothing is built, nothing is paid.
    bool enabled = false;
    RtShadows shadows = RtShadows::Off;
    bool ao = false;  // ambient occlusion traced with rays, instead of the screen-space one
    bool reflections =
        false;  // reflections traced with rays (mirror under roughness 0.25, glossy and denoised up to 0.65), with the
                // screen-space ones and the probes as the per-pixel fallback
    bool translucency =
        false;  // refraction through glass and liquids traced with rays, instead of the screen-space refraction
    RtGi gi = RtGi::Off;
    int raysPerPixel =
        kRtDefaultRaysPerPixel;  // rays of each effect per pixel and frame (1 to 16); the denoiser makes up the rest
    int maxInstances =
        kRtDefaultMaxInstances;  // the most instances the TLAS holds (1 to 1048576); the nearest to the camera first
    bool operator==(const RayTracingSettings&) const = default;
};

constexpr std::string_view rt_shadows_name(RtShadows m) {
    const int i = int(m);
    return (i >= 0 && i < kRtShadowsCount) ? kRtShadowsNames[std::size_t(i)] : std::string_view("off");
}
constexpr std::string_view rt_gi_name(RtGi m) {
    const int i = int(m);
    return (i >= 0 && i < kRtGiCount) ? kRtGiNames[std::size_t(i)] : std::string_view("off");
}

// Whether any effect asks for rays: enabled and at least one effect on. The renderer pays for ray tracing only then.
constexpr bool rt_any_effect(const RayTracingSettings& s) {
    return s.enabled && (s.shadows != RtShadows::Off || s.ao || s.reflections || s.translucency || s.gi != RtGi::Off);
}

// {"enabled", "shadows", "ao", "reflections", "translucency", "gi", "raysPerPixel", "maxInstances"} (every key always present).
Json ray_tracing_to_json(const RayTracingSettings& s);
// Reads the keys of `j` that are present over `base`. An error names the place (`where` + "/key", e.g.
// "factoria.json#/render/rayTracing/shadows"), what is wrong, the valid values and a "did you mean" for a misspelt name or key. A whole
// number outside its range is clamped (raysPerPixel 1 to 16, maxInstances 1 to 1048576), never wrapped. Nothing is stored.
Result<RayTracingSettings> parse_ray_tracing_settings(const Json& j, std::string_view where,
                                                      const RayTracingSettings& base);

// ---- The path tracer (M79-P5a, docs/design/ARCHITECTURE_RT_PATHTRACER.md) ----------------------------------------------------------------

// The limits of the path tracer's numbers (a value outside is clamped, never an error).
inline constexpr int kPtDefaultMaxBounces = 4;
inline constexpr int kPtMinMaxBounces = 1;
inline constexpr int kPtMaxMaxBounces = 32;
inline constexpr int kPtDefaultSamplesPerFrame = 1;
inline constexpr int kPtMinSamplesPerFrame = 1;
inline constexpr int kPtMaxSamplesPerFrame = 64;
inline constexpr int kPtMaxMaxSamples = 1 << 24;  // 0 = no limit
inline constexpr int kPtMaxSeed = 1 << 30;

// The reference mode: instead of the raster's lit colour the main camera shows a progressive unidirectional path trace of the same scene (the same
// BRDF, the sun and the analytic lights sampled directly, the sky as the environment), accumulated over frames while nothing changes. Meant for a
// converged picture to compare the raster against, not for play. OFF by default and free when off: no kernel, no image, no pass. It needs a device that
// traces rays (render.supports raytracing); it asks for the scene's acceleration structures by itself (render.rayTracing needs no effect on).
struct PathTracerSettings {
    bool enabled = false;
    int maxBounces = kPtDefaultMaxBounces;  // path length: 1 = direct light only, up to 32 (Russian roulette ends a dark path sooner)
    int samplesPerFrame = kPtDefaultSamplesPerFrame;  // paths per pixel each frame adds to the accumulation (1 to 64)
    int maxSamples = 0;       // the accumulation stops (the picture is kept) after this many samples per pixel; 0 = never
    float fireflyClamp = 0.0f;  // clamps the radiance of one path to this value (0 = off): trades a little energy for fewer white dots
    bool lights = true;       // direct light from the point and spot lights (at most kPtMaxLights of the frame); the sun is always sampled
    int seed = 0;             // changes the noise pattern (the same seed gives the same picture on a device); never the wall clock
    bool operator==(const PathTracerSettings&) const = default;
};

// The most point and spot lights one frame's kernel samples (the strongest in view, by the renderer's own light order).
inline constexpr int kPtMaxLights = 8;

// {"enabled", "maxBounces", "samplesPerFrame", "maxSamples", "fireflyClamp", "lights", "seed"} (every key always present).
Json path_tracer_to_json(const PathTracerSettings& s);
// Reads the keys of `j` that are present over `base` (the errors of parse_ray_tracing_settings: a JSON pointer, what is wrong, did you mean).
Result<PathTracerSettings> parse_path_tracer_settings(const Json& j, std::string_view where, const PathTracerSettings& base);

// What the path tracer did, for render.ray_tracing and render.pathtrace.
struct PathTracerStatus {
    bool active = false;        // the kernel ran in the last frame that was drawn
    std::uint32_t samples = 0;  // samples per pixel accumulated so far (0 after a reset)
    int width = 0, height = 0;  // the accumulation image's size
    std::uint32_t resets = 0;   // how many times the accumulation restarted since the path tracer went on
    std::string lastReset;      // why the last restart: "first frame", "camera moved", "scene changed", "settings changed", "resized"
    std::string failure;        // why the kernel could not run (the device refused it...), or empty
};

}  // namespace fa::render
