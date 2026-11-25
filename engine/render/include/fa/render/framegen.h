// The engine-wide frame-generation setting of M78 (docs/FRAME_GENERATION.md): a vendor SDK puts a generated frame between two rendered
// ones, so the display shows more frames than the game renders. A setting of the whole game, like the upscaler (fa/render/upscaler.h) and
// the low-latency mode (fa/render/latency.h).
//
// factoria.json "render.frameGeneration" {mode, minBaseFps}, the command render.frame_generation and Engine::set_frame_generation define,
// validate and store it; the renderer drives the chosen path (src/render_framegen.h): NVIDIA DLSS frame generation, AMD FSR 3 frame
// generation or Intel XeSS frame generation. effective_frame_generation is the one place that says which provider the mode names;
// Renderer::effective_frame_generation() reads it. Whether that provider runs this frame is the controller's (it needs the temporal upscaler,
// and a base frame rate of at least minBaseFps).
#pragma once

#include <array>
#include <string>
#include <string_view>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/render/upscaler.h"

namespace fa::render {

// What the player asked for.
//  off:  no frame generation (the default); the swapchain is the engine's own.
//  auto: the SDK of this GPU's maker when it is usable (NVIDIA: dlss, AMD: fsr, Intel: xess), else none.
//  dlss: NVIDIA DLSS frame generation (through Streamline; Windows, D3D12 or Vulkan, an RTX GPU).
//  fsr:  AMD FSR 3 frame generation (FidelityFX; Windows, D3D12 or Vulkan, any GPU).
//  xess: Intel XeSS frame generation (Windows, D3D12, an Intel Arc GPU).
// The value of a mode is its index in kFrameGenModeNames.
enum class FrameGenMode : std::int32_t { Off, Auto, Dlss, Fsr, Xess };
inline constexpr int kFrameGenModeCount = 5;
inline constexpr std::array<std::string_view, kFrameGenModeCount> kFrameGenModeNames = {"off", "auto", "dlss", "fsr",
                                                                                        "xess"};

// The default and the limits of minBaseFps (frames per second the game must render for generation to run).
inline constexpr int kFrameGenDefaultMinBaseFps = 60;
inline constexpr int kFrameGenMaxMinBaseFps = 1000;

struct FrameGenSettings {
    FrameGenMode mode = FrameGenMode::Off;
    // The base frame rate (frames the game renders per second, not counting generated ones) below which generation is switched off: a
    // generated frame between two slow ones adds delay and shows artefacts, so the display is better left to the rendered frames. The
    // controller turns generation back on at 10% above it. 0 = never switch off for a low frame rate.
    int minBaseFps = kFrameGenDefaultMinBaseFps;
    bool operator==(const FrameGenSettings&) const = default;
};

constexpr std::string_view frame_gen_mode_name(FrameGenMode m) {
    const int i = int(m);
    return (i >= 0 && i < kFrameGenModeCount) ? kFrameGenModeNames[std::size_t(i)] : std::string_view("off");
}

// The provider a mode names, or the one that runs: none, or one SDK. The value is its index in kFrameGenSlotNames (also the order of the
// render.supports rows dlssFrameGen, fsrFrameGen and xessFrameGen).
enum class FrameGenSlot : std::int32_t { None, Dlss, Fsr, Xess };
inline constexpr int kFrameGenSlotCount = 4;
inline constexpr std::array<std::string_view, kFrameGenSlotCount> kFrameGenSlotNames = {"none", "dlss", "fsr", "xess"};
constexpr std::string_view frame_gen_slot_name(FrameGenSlot s) {
    const int i = int(s);
    return (i >= 0 && i < kFrameGenSlotCount) ? kFrameGenSlotNames[std::size_t(i)] : std::string_view("none");
}

// What this machine can run, when the provider is chosen.
struct FrameGenCaps {
    GpuVendor gpuVendor = GpuVendor::None;
    bool dlss = false;  // the providers' answers (usable: installed, this GPU and backend suit it, none failed)
    bool fsr = false;
    bool xess = false;
};

// The provider `s` names on `caps`:
//  - off: none;
//  - dlss, fsr, xess: that provider when `caps` says it is usable, else none;
//  - auto: the provider of the GPU's maker (NVIDIA dlss, AMD fsr, Intel xess) when it is usable, else none.
// (Where a provider is not usable the controller says why; this function only says which one would run.)
FrameGenSlot effective_frame_generation(const FrameGenSettings& s, const FrameGenCaps& caps);

// The slot an explicit mode names (None for off and auto), and the one auto names for a GPU maker (None for a maker without a provider).
FrameGenSlot frame_gen_slot_of_mode(FrameGenMode m);
FrameGenSlot frame_gen_slot_for_vendor(GpuVendor v);

// {"mode", "minBaseFps"} (both always present).
Json frame_gen_to_json(const FrameGenSettings& s);
// Reads the keys of `j` that are present over `base`: "mode" is a name, "minBaseFps" a whole number of 0 to kFrameGenMaxMinBaseFps. An
// error names the place (`where` + "/key", e.g. "factoria.json#/render/frameGeneration"), what is wrong, the valid values and a "did you
// mean" for a misspelt name or key. Nothing is stored.
Result<FrameGenSettings> parse_frame_gen_settings(const Json& j, std::string_view where, const FrameGenSettings& base);

}  // namespace fa::render
