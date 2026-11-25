// The Intel XeSS Low Latency (XeLL) provider of M78 (render_latency.h; docs/LATENCY.md, "Intel XeLL"). Private to fa_render.
//
// No Intel header or binary is in the engine (decision D2 of M78): this file declares the C ABI of XeLL 1.x the engine calls, written from
// the headers of github.com/intel/xess (inc/xell/xell.h and xell_d3d12.h, XeSS 3.0.x, MIT). Every function is taken from libxell.dll
// (installed by `factoria setup xess`, next to libxess.dll) through VendorLibrary::symbol into XellApi. XeLL has a Direct3D 12 entry point
// only; on Vulkan and Direct3D 11 the mode reports itself unavailable and the engine's own pacing runs.
#pragma once

#include <cstdint>
#include <string>

#include "render_latency.h"

namespace fa::render {

namespace xell_abi {

#pragma pack(push, 8)
struct Version {  // xell_version_t
    std::uint16_t major, minor, patch, reserved;
};
// xell_sleep_params_t: the minimum frame time, and the two flags of its bit field (low latency mode in bit 0, boost in bit 1).
struct SleepParams {
    std::uint32_t minimumIntervalUs;
    std::uint32_t flags;
};
// xell_frame_report_t: the timestamps XeLL took for one frame, in nanoseconds of its own clock (0 = not marked).
struct FrameReport {
    std::uint32_t frameId;
    std::uint64_t simStart, simEnd, renderSubmitStart, renderSubmitEnd, presentStart, presentEnd;
    std::uint64_t reserved[5];
};
#pragma pack(pop)
inline constexpr std::uint32_t kFlagLowLatency = 1u << 0, kFlagBoost = 1u << 1;
inline constexpr int kReportCount = 64;  // xellGetFramesReports fills this many

// xell_latency_marker_type_t
inline constexpr std::int32_t kMarkerSimulationStart = 0, kMarkerSimulationEnd = 1, kMarkerRenderSubmitStart = 2,
                              kMarkerRenderSubmitEnd = 3, kMarkerPresentStart = 4, kMarkerPresentEnd = 5,
                              kMarkerInputSample = 6;
// xell_result_t: success is 0, an error negative.
inline constexpr std::int32_t kResultSuccess = 0;

using Context = struct ContextTag*;  // xell_context_handle_t

using GetVersionFn = std::int32_t (*)(Version*);
using D3d12CreateContextFn = std::int32_t (*)(void* device, Context*);
using DestroyContextFn = std::int32_t (*)(Context);
using SetSleepModeFn = std::int32_t (*)(Context, const SleepParams*);
using SleepFn = std::int32_t (*)(Context, std::uint32_t frameId);
using AddMarkerDataFn = std::int32_t (*)(Context, std::uint32_t frameId, std::int32_t marker);
using GetFramesReportsFn = std::int32_t (*)(Context, FrameReport* out);  // out[kReportCount]

}  // namespace xell_abi

struct XellApi {
    xell_abi::GetVersionFn getVersion = nullptr;
    xell_abi::D3d12CreateContextFn d3d12Create = nullptr;
    xell_abi::DestroyContextFn destroyContext = nullptr;
    xell_abi::SetSleepModeFn setSleepMode = nullptr;
    xell_abi::SleepFn sleep = nullptr;
    xell_abi::AddMarkerDataFn addMarker = nullptr;
    xell_abi::GetFramesReportsFn getFramesReports = nullptr;  // optional: a library without it gives no vendor report
};

// The XeLL context of a device, shared by two users: the XeLL latency provider (render.latency) and Intel XeSS frame generation
// (render_framegen_xess.h), which cannot run without XeLL and takes the context at the moment it makes the window's swapchain, before the
// latency controller exists. The provider owns the context; each user holds a reference, and the context goes with the last one (XeSS frame
// generation is destroyed first, as XeSS-FG asks). The XeLL provider of the latency table gives it (LatencyProvider::xell_share()).
struct XellContext {
    XellApi api;
    xell_abi::Context ctx = nullptr;
};
class XellShare {
public:
    virtual ~XellShare() = default;
    // A reference to the context on the ID3D12Device `nativeDevice`, made when there is none (the library is loaded when no probe did): ""
    // or why not. A context of another device (one that went without a release) is destroyed first.
    virtual std::string acquire(const void* nativeDevice, XellContext& out) = 0;
    // Gives a reference back; the context is destroyed with the last one. A device that is not the context's does nothing.
    virtual void release(const void* nativeDevice) = 0;
    // The sleep mode with low latency on, when the latency controller has not set it ("" or XeLL's reason): XeSS-FG must find it on
    // before it generates.
    virtual std::string ensure_sleep_mode() = 0;
    // The frame id of the last sleep or marker the controller gave (the id of the present that will show the frame); 0 until one did.
    virtual std::uint32_t frame_id() const = 0;
};

VendorLibrarySpec xell_library_spec();
// Takes the functions from `lib`. "" when the required ones are all there, else the name of the first missing one.
std::string xell_load_api(VendorLibrary& lib, XellApi& api);
// "success", "unsupported device", ... for an xell_result_t; "result -12" for a code this build does not know.
std::string xell_result_text(std::int32_t result);

}  // namespace fa::render
