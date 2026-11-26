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
    bool translucency = false;  // light through glass and thin surfaces (refraction and coloured shadows)
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

}  // namespace fa::render
