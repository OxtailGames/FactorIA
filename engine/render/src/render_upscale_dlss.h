// The DLSS Super Resolution provider of M78 (docs/design/ARCHITECTURE_RENDERING_HOOKS.md, "Streamline runtime core"; docs/UPSCALING_VENDORS.md,
// "NVIDIA DLSS Super Resolution"): NVIDIA's temporal upscaler behind the `dlss` upscaler mode, reached through the Streamline runtime (streamline_runtime.h), which
// loads sl.interposer.dll and takes part in making the device. Private to fa_render.
//
// No NVIDIA header or binary is in the engine: the Streamline structures and functions this file's .cpp calls are the engine's own
// declarations in streamline_runtime.h.
#pragma once

#include <cstdint>
#include <memory>

#include "render_upscale_vendor.h"

namespace fa::render {

class StreamlineRuntime;

// The DLSS mode (sl::DLSSMode, sl_abi::kDlss...) that draws at an upscale ratio (output size / render size, the larger of the two axes), and the
// ratio a mode stands for (DLAA 1.0, UltraQuality 1.3, MaxQuality 1.5, Balanced 1.72, MaxPerformance 2.0, UltraPerformance 3.0; M76's quality
// names are 1.0, 1.5, 1.7, 2.0 and 3.0, so they land on DLAA, MaxQuality, Balanced, MaxPerformance and UltraPerformance). The nearest mode wins,
// and `current` (0 = none) is kept while the ratio is within 0.13 of its own ratio (more than half of the 0.2 between the two closest modes), so a
// dynamic resolution that wobbles around a boundary does not set the options again every few frames.
std::uint32_t dlss_mode_for_ratio(float ratio, std::uint32_t current = 0);
float dlss_mode_ratio(std::uint32_t mode);
// "DLAA", "Quality", ... for a mode (the names of NVIDIA's own docs); "mode 9" for an unknown number.
const char* dlss_mode_name(std::uint32_t mode);

// What a renderer asks of the Streamline runtime before its device is made (`runtime` is the process's in the renderer): Ray Reconstruction's plugin
// (sl.dlss_d), only when the game asked for it (RendererDesc::rayReconstruction). Streamline loads the plugins slInit is told of, so a game
// that never uses Ray Reconstruction does not pay its load time and memory. `rayReconstructionNeedsMode`
// (RendererDesc::rayReconstructionNeedsMode): the game asked for it but starts in a mode that never draws with DLSS, so the plugin is not
// asked and the provider's answer says to change render.upscaler.mode (not the flag, which is already true).
void streamline_ask_upscaler_features(StreamlineRuntime& runtime, bool rayReconstruction,
                                      bool rayReconstructionNeedsMode = false);

// A new DLSS provider (index 0 of vendor_provider()). It is a process-wide object: the options of the device that drew last.
std::unique_ptr<VendorUpscaler> make_dlss_provider();

}  // namespace fa::render
