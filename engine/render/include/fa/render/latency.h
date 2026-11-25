// The engine-wide low-latency setting of M78 (docs/LATENCY.md): how much earlier than the plain loop the game samples the player's input, so
// the time from a press to the frame that shows it gets shorter. A setting of the whole game, like the upscaler (fa/render/upscaler.h).
//
// factoria.json "render.latency" {mode, boost}, the command render.latency and Engine::set_latency define, validate and store it; the
// renderer drives the chosen path (src/render_latency.h): a vendor SDK's own pacing (AMD Anti-Lag 2, Intel XeLL, NVIDIA Reflex) or the
// engine's own pacing. effective_latency_driver is the one place that says which path runs; Renderer::effective_latency() reads it.
#pragma once

#include <array>
#include <string>
#include <string_view>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/render/upscaler.h"

namespace fa::render {

// What the player asked for.
//  off:      no pacing at all; the loop is the one of today (the default).
//  auto:     the SDK of this GPU's maker when it is usable (AMD: antilag2, Intel: xell, NVIDIA: reflex), else the engine's own pacing.
//  reflex:   NVIDIA Reflex (Windows, D3D12 or Vulkan on an NVIDIA GPU, through Streamline: `factoria setup streamline`).
//  antilag2: AMD Anti-Lag 2 (Windows, D3D12 or Vulkan on an AMD GPU; the driver is the SDK, nothing to install).
//  xell:     Intel XeSS Low Latency (Windows, D3D12, `factoria setup xess`).
// The value of a mode is its index in kLatencyModeNames.
enum class LatencyMode : std::int32_t { Off, Auto, Reflex, AntiLag2, Xell };
inline constexpr int kLatencyModeCount = 5;
inline constexpr std::array<std::string_view, kLatencyModeCount> kLatencyModeNames = {"off", "auto", "reflex",
                                                                                      "antilag2", "xell"};

struct LatencySettings {
    LatencyMode mode = LatencyMode::Off;
    // The vendor's "boost": the GPU clocks stay up while the game waits, for less latency at more power (Reflex boost, XeLL's low latency
    // boost). Anti-Lag 2 and the engine's own pacing have no such switch and ignore it.
    bool boost = false;
    bool operator==(const LatencySettings&) const = default;
};

constexpr std::string_view latency_mode_name(LatencyMode m) {
    const int i = int(m);
    return (i >= 0 && i < kLatencyModeCount) ? kLatencyModeNames[std::size_t(i)] : std::string_view("off");
}

// The path that really runs (never the vendor path that is not there): none (off), the engine's own pacing, or one SDK.
enum class LatencyDriver : std::int32_t { None, Pacing, Reflex, AntiLag2, Xell };
inline constexpr int kLatencyDriverCount = 5;
inline constexpr std::array<std::string_view, kLatencyDriverCount> kLatencyDriverNames = {"none", "pacing", "reflex",
                                                                                          "antilag2", "xell"};
constexpr std::string_view latency_driver_name(LatencyDriver d) {
    const int i = int(d);
    return (i >= 0 && i < kLatencyDriverCount) ? kLatencyDriverNames[std::size_t(i)] : std::string_view("none");
}

// The points of a frame the game reports (the markers of Reflex, XeLL and Anti-Lag 2 are these; the order below is the order of a frame).
//  SimulationStart: the frame's work starts (after the pacing sleep). InputSample: the player's input of this frame is read.
//  SimulationEnd: scripts and physics are done. RenderSubmitStart/End: the frame is recorded and submitted to the GPU.
//  PresentStart/End: around the call that hands the picture to the display.
enum class LatencyMarker : std::int32_t {
    SimulationStart,
    InputSample,
    SimulationEnd,
    RenderSubmitStart,
    RenderSubmitEnd,
    PresentStart,
    PresentEnd
};
inline constexpr int kLatencyMarkerCount = 7;
std::string_view latency_marker_name(LatencyMarker m);

// What this machine can run, when the effective path is decided.
struct LatencyCaps {
    GpuVendor gpuVendor = GpuVendor::None;
    bool pacing =
        false;  // a window to pace: the engine's own pacing can run (not in a headless run, not in the editor)
    bool reflex = false;  // the providers' answers (usable: installed, this GPU and backend suit it, none failed)
    bool antiLag2 = false;
    bool xell = false;
};

// The path that runs for `s` on `caps`:
//  - off: none;
//  - reflex, antilag2, xell: that SDK when `caps` says it is usable, else the engine's own pacing (`caps.pacing`), else none;
//  - auto: the SDK of the GPU's maker (NVIDIA reflex, AMD antilag2, Intel xell) when it is usable, else the engine's own pacing, else none.
LatencyDriver effective_latency_driver(const LatencySettings& s, const LatencyCaps& caps);

// {"mode", "boost"} (both always present).
Json latency_to_json(const LatencySettings& s);
// Reads the keys of `j` that are present over `base`: "mode" is a name, "boost" a boolean. An error names the place (`where` + "/key", e.g.
// "factoria.json#/render/latency"), what is wrong, the valid values and a "did you mean" for a misspelt name or key. Nothing is stored.
Result<LatencySettings> parse_latency_settings(const Json& j, std::string_view where, const LatencySettings& base);

}  // namespace fa::render
