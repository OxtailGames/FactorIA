// The NVIDIA Reflex provider of M78 (render_latency.h; docs/LATENCY.md, "NVIDIA Reflex"). Private to fa_render.
//
// No NVIDIA header or binary is in the engine (decisions D1 and D2 of M78): Reflex is reached through the Streamline runtime of
// streamline_runtime.h, whose `sl_abi` declares the structures of Streamline 2.14.16's sl_reflex.h and sl_pcl.h. The four functions the
// provider calls (slReflexSetOptions, slReflexGetState, slReflexSleep, slPCLSetMarker) come from slGetFeatureFunction, the way the DLSS
// ones do. Where it runs: Windows, Direct3D 12 and Vulkan (the devices Streamline's hooks take part in making), on an NVIDIA GPU whose driver
// has Reflex Low Latency, with `factoria setup streamline` done. The frame token of a frame is the runtime's, the one DLSS uses.
#pragma once

#include <cstdint>
#include <string>

#include "render_latency.h"
#include "streamline_runtime.h"

namespace fa::render {

// The functions of the Reflex and PCL plugins. `setMarker` is null when the PCL plugin is not usable: Reflex then runs without markers.
struct ReflexApi {
    sl_abi::ReflexSetOptionsFn setOptions = nullptr;
    sl_abi::ReflexGetStateFn getState = nullptr;
    sl_abi::ReflexSleepFn sleep = nullptr;
    sl_abi::PclSetMarkerFn setMarker = nullptr;
};

// Takes the functions from `sl` (slGetFeatureFunction). `withPcl` false leaves setMarker null without asking. "" when the Reflex ones are
// all there, else the sentence of the first that is not (Streamline's own result, and what to do).
std::string reflex_load_api(const StreamlineApi& sl, bool withPcl, ReflexApi& api);

// The PCL marker (sl::PCLMarker) the engine's marker is sent as; -1 for a marker Reflex has no use for (the player's input sample: the PCL
// marker of it is deprecated, and Reflex finds the input by itself).
std::int32_t reflex_pcl_marker(LatencyMarker marker);

}  // namespace fa::render
