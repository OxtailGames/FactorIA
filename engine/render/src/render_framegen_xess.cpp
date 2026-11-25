// The Intel XeSS frame generation provider of M78 (render_framegen_xess.h).
#include "render_framegen_xess.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstring>
#include <mutex>
#include <span>

#include "fa/core/fs.h"
#include "fa/core/log.h"

#include "render_latency.h"
#include "render_latency_xell.h"

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <d3d12.h>
#include <dxgi.h>
#endif

namespace fa::render {

namespace {

namespace abi = xefg_abi;

#if UINTPTR_MAX == 0xFFFFFFFFFFFFFFFFu
static_assert(sizeof(abi::Version) == 8, "xefg_swapchain_version_t");
static_assert(sizeof(abi::Dim2) == 8, "xefg_swapchain_2d_t");
static_assert(sizeof(abi::FrameConstants) == 152, "xefg_swapchain_frame_constant_data_t");
static_assert(sizeof(abi::PresentStatus) == 12, "xefg_swapchain_present_status_t");
static_assert(sizeof(abi::D3d12InitParams) == 72, "xefg_swapchain_d3d12_init_params_t");
static_assert(sizeof(abi::D3d12ResourceData) == 40, "xefg_swapchain_d3d12_resource_data_t");
#endif
static_assert(sizeof(abi::Guid) == 16, "GUID");

// The one constant of the ABI that is a Direct3D 12 value: the state a tagged resource is handed over in. Where the Windows headers are there,
// the build checks it against them (the others are the SDK's own enumerations, which no header of this build holds).
#if defined(_WIN32)
static_assert(abi::kStateCopySource == std::uint32_t(D3D12_RESOURCE_STATE_COPY_SOURCE),
              "D3D12_RESOURCE_STATE_COPY_SOURCE");
#endif

constexpr unsigned bit(gpu::Backend b) { return 1u << unsigned(b); }
constexpr std::uint32_t kIntelVendorId = 0x8086;
// How many presents in a row may report a failed generation before XeSS-FG is turned off for the run (a count of presents, not a time: the
// result must not depend on how fast the machine renders).
constexpr int kStatusFailures = 5;

template <class Fn>
void bind(VendorLibrary& lib, const char* name, Fn& fn, std::string& missing, bool optional = false) {
    void* address = lib.symbol(name);
    if (!address) {
        if (!optional && missing.empty()) missing = name;
        return;
    }
    fn = reinterpret_cast<Fn>(address);  // NOLINT: the export's address
}

std::string version_text(const abi::Version& v) {
    return std::to_string(v.major) + "." + std::to_string(v.minor) + "." + std::to_string(v.patch);
}

std::string call_failed(const char* function, std::int32_t result) {
    std::string text =
        std::string(function) + " answered \"" + xefg_result_text(result) + "\" (" + std::to_string(result) + ")";
    if (result == -1)
        text += ": this GPU cannot run XeSS frame generation (it needs an Intel Arc GPU)";
    else if (result == -2)
        text += ": the installed GPU driver is too old for XeSS frame generation; update it";
    else if (result == -15 || result == -16)
        text += ": XeLL is not usable here; run `factoria setup xess` to install its library again";
    return text;
}

// The IID of IDXGISwapChain1, the interface the engine's D3D12 swapchain code takes the hook's swapchain as.
constexpr abi::Guid kIidSwapChain1 = {0x790a45f7, 0x0d42, 0x4876, {0x98, 0x3a, 0x0a, 0x55, 0xcf, 0xe6, 0xf4, 0xaa}};

// The vendor id of an IDXGIAdapter1 (IDXGIAdapter1::GetDesc1, as streamline_runtime.cpp reads its adapters). 0 when `adapter` is null or the call
// fails. Where there is no DXGI (the tests of the other platforms, whose adapter is a table of function pointers laid out like the COM object)
// it is the same call made by hand: vtable slot 10, DXGI_ADAPTER_DESC1::VendorId at byte 256 after the 128 wide characters of the description;
// 0 on a 32-bit build, whose calling convention differs.
std::uint32_t adapter_vendor_id(const void* adapter) {
#if defined(_WIN32)
    if (!adapter) return 0;
    auto* a = static_cast<IDXGIAdapter1*>(const_cast<void*>(adapter));  // NOLINT: the COM call takes a non-const this
    DXGI_ADAPTER_DESC1 desc{};
    if (FAILED(a->GetDesc1(&desc))) return 0;
    return desc.VendorId;
#elif UINTPTR_MAX == 0xFFFFFFFFFFFFFFFFu
    if (!adapter) return 0;
    using GetDesc1 = std::int32_t (*)(void* self, void* desc);
    void* const* vtable = *static_cast<void* const* const*>(adapter);
    const auto getDesc1 = reinterpret_cast<GetDesc1>(vtable[10]);  // NOLINT: a COM method
    alignas(8) unsigned char desc[512] = {};
    if (getDesc1(const_cast<void*>(adapter), desc) < 0) return 0;  // NOLINT: the COM call takes a non-const this
    std::uint32_t vendor = 0;
    std::memcpy(&vendor, desc + 256, sizeof(vendor));
    return vendor;
#else
    (void)adapter;
    return 0;
#endif
}

// ---- threads ----------------------------------------------------------------------------------------------------------------------------
// Who calls what (XeSS-FG's own threads never call the provider):
//  - probe(): any thread (the editor probes from its own). It touches only the library (lib_ and api_, under mutex_) and the failure text
//    (failMutex_); nothing else of the provider.
//  - failure() and generated_frames(): any thread (failMutex_, an atomic).
//  - The render thread, the one that makes the device, the window and the frames, makes every other call: d3d12_device_created,
//    d3d12_create_swapchain, swapchain_destroying, device_destroying, start, configure, dispatch, stop and, around each Present, present_begin
//    and present_end. So ctx_, share_, device_, enabled_ and the rest of the state below need no lock.
//  - The library is loaded once and kept for the provider's life: api_ is written once (under mutex_, by whichever thread loads first) and the
//    render thread reads a copy of it (api()), so a probe from another thread cannot swap a function table under a call.
class XessFrameGenProvider final : public FrameGenProvider,
                                   public gpu::DeviceHook,
                                   public std::enable_shared_from_this<XessFrameGenProvider> {
public:
    // ---- FrameGenProvider ----
    std::string_view name() const override { return "XeSS frame generation"; }
    FrameGenSlot slot() const override { return FrameGenSlot::Xess; }
    std::string_view setup_id() const override { return "xess"; }
    unsigned backends() const override { return bit(gpu::Backend::D3d12); }
    VendorProbe probe(const VendorEnv& env) override;
    std::shared_ptr<gpu::DeviceHook> device_hook() override { return shared_from_this(); }
    // Only a game started with `xess` (or `auto`, which is XeSS on an Intel GPU) gets XeSS-FG's swapchain: `dlss` and `fsr` leave the
    // window's swapchain to their own providers.
    std::shared_ptr<gpu::DeviceHook> device_hook_for(FrameGenMode mode) override {
        if (mode != FrameGenMode::Xess && mode != FrameGenMode::Auto) return nullptr;
        return shared_from_this();
    }
    std::string start(gpu::Device& device, const FrameGenSwapchain& swapchain) override;
    void configure(bool enabled) override;
    bool dispatch(FrameGenFrame& frame) override;
    std::uint64_t generated_frames() override { return generated_.load(std::memory_order_relaxed); }
    void stop(gpu::Device& device) override;
    std::string failure() const override;

    // ---- gpu::DeviceHook ----
    // `name()` is shared with FrameGenProvider (the same text).
    void d3d12_device_created(gpu::D3d12DeviceCreated& created) override;
    bool d3d12_create_swapchain(gpu::D3d12SwapchainCreate& create) override;
    void present_begin(const gpu::PresentEvent& e) override;
    void present_end(const gpu::PresentEvent& e) override;
    void swapchain_destroying(const gpu::SwapchainEvent& e) override;
    void device_destroying() override;

private:
    // Finds, loads and checks libxess_fg (what the probe and the hook do): "" or the reason. `installed` says whether the library file was found
    // (a missing file is the probe's to report; a file that does not load is a failure of the hook too).
    std::string load_library(bool* installed);
    // XeLL's library must be installed too (XeSS frame generation cannot run without it): "" or the reason.
    static std::string xell_problem();
    void fail(const std::string& why);  // "fail once, stay off": keeps the first reason and logs it
    void destroy_context();             // the XeSS-FG context first, then the reference to XeLL's
    std::uint32_t next_present_id(bool consume);
    // Destroys an XeSS-FG context; a result that says it failed is logged (the handle is gone either way: nothing else can be done with it).
    void destroy_xefg(abi::Handle ctx);
    // SetEnabled on the live context, XeLL's sleep mode first. false (and `fail()`) when XeLL or XeSS-FG refuses.
    bool apply_enabled(bool enabled);
    // The functions of the library, as the render thread sees them (a copy, taken under the lock that guards the load).
    XefgApi api() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return api_;
    }

    mutable std::mutex mutex_;  // the library: the probe may come from another thread than the hook
    std::unique_ptr<VendorLibrary> lib_;
    XefgApi api_{};

    mutable std::mutex failMutex_;
    std::string failure_;

    // The device of the hook and what the swapchain was made with (render thread; the present hooks run on the thread that presents).
    const void* device_ = nullptr;
    bool intel_ = false;
    std::string hookProblem_;  // why the hook made no swapchain ("" when it did, or it was never asked)
    abi::Handle ctx_ = nullptr;
    XellShare* share_ = nullptr;
    XellContext xell_{};
    bool xellHeld_ = false;
    std::atomic<bool> live_{false};  // the swapchain of ctx_ exists (swapchain_destroying clears it)
    std::atomic<bool> running_{false};
    bool enabled_ = false;      // what XeSS-FG's swapchain was last told (false on a new swapchain)
    bool wantEnabled_ = false;  // what the controller last asked (configure): put back on a swapchain made again
    // Negative results of the swapchain's present status in a row (fewer than kStatusFailures are tolerated: a resize or a device hiccup).
    int statusFailures_ = 0;
    std::uint32_t lastPresentId_ = 0;  // the id of the last tagged frame (see next_present_id)
    std::uint32_t taggedId_ = 0;       // the present id the last dispatch tagged (0: none since the last present)
    std::uint64_t presents_ = 0;       // PresentEvent::frame of the last present begun
    std::atomic<std::uint64_t> generated_{0};
};

std::string XessFrameGenProvider::failure() const {
    std::lock_guard<std::mutex> lock(failMutex_);
    return failure_;
}

void XessFrameGenProvider::fail(const std::string& why) {
    {
        std::lock_guard<std::mutex> lock(failMutex_);
        if (!failure_.empty()) return;
        failure_ = why;
    }
    FA_WARN("render", "XeSS frame generation: {} It stays off for the rest of this run.", why);
}

std::string XessFrameGenProvider::xell_problem() {
    std::string why;
    if (vendor_loader().find(xell_library_spec(), &why).empty())
        return "XeSS frame generation needs Intel XeLL (" + std::string(xell_library_spec().fileName) +
               "), which is not installed: run `factoria setup xess` (" + why + ").";
    LatencyProvider* xell = latency_provider(LatencyDriver::Xell);
    if (!xell || !xell->xell_share())
        return "XeSS frame generation needs Intel XeLL, and this build has no XeLL provider.";
    return {};
}

std::string XessFrameGenProvider::load_library(bool* installed) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (lib_ && api_.d3d12Create) {
            if (installed) *installed = true;
            return {};
        }
    }
    if (installed) *installed = false;
    std::string why;
    const std::filesystem::path found = vendor_loader().find(xefg_library_spec(), &why);
    if (found.empty()) return "XeSS frame generation is not installed: run `factoria setup xess` (" + why + ").";
    if (installed) *installed = true;
    std::unique_ptr<VendorLibrary> lib = vendor_loader().load(found, &why);
    if (!lib)
        return "XeSS frame generation's library " + fa::fs::path_to_utf8(found) + " could not be loaded: " + why +
               ". Run `factoria setup xess` to install it again.";
    XefgApi loaded;
    if (const std::string missing = xefg_load_api(*lib, loaded); !missing.empty())
        return "XeSS frame generation's library " + lib->path() + " has no export " + missing +
               " (it is not the XeSS-FG swapchain library): run `factoria setup xess` to install the version "
               "FactorIA was tested with.";
    abi::Version version{};
    if (const std::int32_t rc = loaded.getVersion(&version); rc != abi::kResultSuccess)
        return "XeSS frame generation's library " + lib->path() +
               " did not answer its version: " + call_failed("xefgSwapChainGetVersion", rc) +
               ". Run `factoria setup xess` to install it again.";
    std::lock_guard<std::mutex> lock(mutex_);
    // Another thread may have loaded the library while this one did (the probe and the hook race): the first one stays, because the functions
    // it gave are in use, and this copy is closed. Replacing it would unload the library under a call.
    if (lib_ && api_.d3d12Create) return {};
    FA_INFO("render", "XeSS frame generation: library {} (swapchain API {})", lib->path(), version_text(version));
    lib_ = std::move(lib);
    api_ = loaded;
    return {};
}

void XessFrameGenProvider::destroy_xefg(abi::Handle ctx) {
    if (!ctx) return;
    if (const std::int32_t rc = api().destroy(ctx); rc < 0)
        FA_WARN("render", "XeSS frame generation: {}", call_failed("xefgSwapChainDestroy", rc));
}

bool XessFrameGenProvider::apply_enabled(bool enabled) {
    if (enabled) {
        // XeSS-FG finds XeLL's sleep mode on, or refuses to generate.
        if (std::string why = share_->ensure_sleep_mode(); !why.empty()) {
            fail("XeLL's sleep mode could not be set (" + why + ").");
            return false;
        }
    }
    const std::int32_t rc = api().setEnabled(ctx_, enabled ? 1u : 0u);
    if (rc < 0) {
        if (enabled) fail(call_failed("xefgSwapChainSetEnabled", rc) + ".");
        return false;
    }
    enabled_ = enabled;
    return true;
}

VendorProbe XessFrameGenProvider::probe(const VendorEnv& env) {
    VendorProbe p;
    p.reason = vendor_environment_problem(name(), backends(), env);
    if (p.reason.empty() && sizeof(void*) != 8)
        p.reason = "XeSS frame generation's library is 64-bit; this build is not.";
    if (p.reason.empty() && env.vendor != GpuVendor::Intel)
        p.reason =
            "XeSS frame generation needs an Intel Arc GPU; this GPU is " +
            (env.vendor == GpuVendor::None ? std::string("not known") : std::string(gpu_vendor_name(env.vendor))) +
            "'s. Use render.frameGeneration.mode \"dlss\" on NVIDIA or \"fsr\" on any GPU.";
    if (p.reason.empty()) p.reason = failure();
    if (p.reason.empty()) p.reason = load_library(nullptr);
    if (p.reason.empty()) p.reason = xell_problem();
    p.available = p.reason.empty();
    return p;
}

void XessFrameGenProvider::d3d12_device_created(gpu::D3d12DeviceCreated& created) {
    device_ = created.device;
    const std::uint32_t vendor = adapter_vendor_id(created.adapter);
    intel_ = vendor == kIntelVendorId;
    hookProblem_.clear();
    {
        std::lock_guard<std::mutex> lock(failMutex_);
        failure_.clear();  // a new device is a new run: what failed on the one before does not count
    }
    if (!intel_) hookProblem_ = "this GPU is not an Intel one (XeSS frame generation needs an Intel Arc GPU)";
}

bool XessFrameGenProvider::d3d12_create_swapchain(gpu::D3d12SwapchainCreate& create) {
    // Another swapchain made before this one (the window was made again): the earlier proxy is gone with its swapchain, and its XeSS-FG context
    // is destroyed now (it can only be destroyed once every reference to the swapchain is released), before the new one is made. XeLL's context
    // stays (this provider's reference to it is kept), so the sleep mode and the frame ids go on.
    destroy_xefg(ctx_);
    ctx_ = nullptr;
    live_ = false;
    if (!intel_ || !device_) return false;  // the probe says why; the engine makes its own swapchain
    if (!failure().empty()) return false;
    bool installed = false;
    if (std::string why = load_library(&installed); !why.empty()) {
        hookProblem_ = why;
        if (installed)
            create.error =
                why;  // a library that is there and does not work is an error; one that is not there is the probe's
        return false;
    }
    if (std::string why = xell_problem(); !why.empty()) {
        hookProblem_ = why;
        return false;
    }
    const XefgApi xe = this->api();  // loaded by load_library above, never replaced
    share_ = latency_provider(LatencyDriver::Xell)->xell_share();
    if (!xellHeld_) {
        if (std::string why = share_->acquire(device_, xell_); !why.empty()) {
            hookProblem_ = "XeSS frame generation needs XeLL, which could not start: " + why;
            create.error = hookProblem_;
            return false;
        }
        xellHeld_ = true;
    }
    const auto give_up = [&](const std::string& why) {
        destroy_xefg(ctx_);
        ctx_ = nullptr;
        if (xellHeld_) share_->release(device_);
        xellHeld_ = false;
        hookProblem_ = why;
        create.error = why;
        return false;
    };
    abi::Handle handle = nullptr;
    if (const std::int32_t rc =
            xe.d3d12Create(const_cast<void*>(device_), &handle);  // NOLINT: the SDK takes a non-const device
        rc < 0 || !handle)
        return give_up("XeSS frame generation could not make its context: " +
                       call_failed("xefgSwapChainD3D12CreateContext", rc));
    ctx_ = handle;
    // XeSS-FG refuses to initialise without XeLL: it is told before the swapchain exists.
    if (const std::int32_t rc = xe.setLatencyReduction(ctx_, xell_.ctx); rc < 0)
        return give_up("XeSS frame generation could not use XeLL: " +
                       call_failed("xefgSwapChainSetLatencyReduction", rc));
    abi::D3d12InitParams params{};
    params.maxInterpolatedFrames = 1;  // one generated frame between two rendered ones
    params.uiMode = abi::kUiModeNone;  // the screen-space items are in the picture: they are interpolated with it
    if (const std::int32_t rc =
            xe.d3d12InitFromDesc(ctx_, const_cast<void*>(create.hwnd), create.desc, nullptr,  // NOLINT
                                 const_cast<void*>(create.queue), const_cast<void*>(create.factory), &params);
        rc < 0)
        return give_up("XeSS frame generation could not make the window's swapchain: " +
                       call_failed("xefgSwapChainD3D12InitFromSwapChainDesc", rc));
    void* swapchain = nullptr;
    if (const std::int32_t rc = xe.d3d12GetSwapChainPtr(ctx_, &kIidSwapChain1, &swapchain); rc < 0 || !swapchain)
        return give_up("XeSS frame generation gave no swapchain: " +
                       call_failed("xefgSwapChainD3D12GetSwapChainPtr", rc));
    create.swapchain = swapchain;
    live_ = true;
    enabled_ = false;  // a new swapchain starts with generation off; dispatch puts wantEnabled_ back
    taggedId_ = 0;
    statusFailures_ = 0;
    hookProblem_.clear();
    return true;
}

std::string XessFrameGenProvider::start(gpu::Device& device, const FrameGenSwapchain& /*swapchain*/) {
    if (device.backend() != gpu::Backend::D3d12) return "XeSS frame generation runs on Direct3D 12 only.";
    if (std::string why = failure(); !why.empty()) return why;
    if (!available()) return "XeSS frame generation's swapchain hook was not used: " + unavailable_reason();
    if (!ctx_ || !live_ || device.native().device != device_) {
        if (!hookProblem_.empty())
            return "XeSS frame generation did not make the window's swapchain: " + hookProblem_ + ".";
        return "XeSS frame generation did not make the window's swapchain (the game must start with "
               "render.frameGeneration.mode set, on an Intel Arc GPU with Direct3D 12).";
    }
    running_ = true;
    return {};
}

void XessFrameGenProvider::configure(bool enabled) {
    // Remembered even when there is no swapchain to tell now: the controller says it once, and a window made again (a new swapchain, which
    // starts with generation off) must get it back (dispatch).
    wantEnabled_ = enabled;
    if (!ctx_ || !live_ || enabled == enabled_) return;
    apply_enabled(enabled);
}

std::uint32_t XessFrameGenProvider::next_present_id(bool consume) {
    // The present that shows this frame is the one XeLL's frame id names; without one (the controller did not give any yet) it is the count of
    // the presents this device made, plus one.
    std::uint32_t id = share_ ? share_->frame_id() : 0u;
    if (id == 0) id = std::uint32_t(presents_ + 1);
    // A present that tags nothing (generation off, or before the first frame) only reads the source: it must not move lastPresentId_, or the
    // ids of the presents XeLL no longer counts would run ahead of XeLL's own, and the tag, the present id and XeLL's marker id (the three
    // XeSS-FG needs to be the same) would never meet again.
    if (!consume) return id;
    // A tagged frame takes the source's id as it is, also when it went back (XeLL's context was made again, or the count of presents
    // restarted: the sequence is followed, not outrun). The one guard: an id the SDK was just given is not given twice for another frame
    // (two dispatches before XeLL's next sleep), so it becomes the last plus one.
    if (id == lastPresentId_) id = lastPresentId_ + 1;
    lastPresentId_ = id;
    taggedId_ = id;
    return id;
}

bool XessFrameGenProvider::dispatch(FrameGenFrame& frame) {
    if (std::string why = failure(); !why.empty()) {
        frame.error = why;
        return false;
    }
    if (!ctx_ || !live_ || !running_) {
        frame.error = "XeSS frame generation has no swapchain to tag the frame for.";
        return false;
    }
    // A window made again gave a swapchain that starts with generation off: the controller said "on" once, so it is put back here.
    if (wantEnabled_ && !enabled_ && !apply_enabled(true)) {
        frame.error = failure();
        return false;
    }
    const XefgApi xe = this->api();
    gpu::Device& device = *frame.device;
    void* const depth =
        const_cast<void*>(device.native_image(frame.depth).resource);  // NOLINT: the SDK takes a non-const resource
    void* const motion = const_cast<void*>(device.native_image(frame.motion).resource);  // NOLINT
    if (!depth || !motion) {
        frame.error = std::string("XeSS frame generation: the device gave no native resource for the ") +
                      (depth ? "motion" : "depth") + " image.";
        return false;
    }
    const std::uint32_t presentId = next_present_id(true);

    const auto finite = [](float v, float limit) { return std::isfinite(v) ? std::clamp(v, -limit, limit) : 0.0f; };
    abi::FrameConstants c{};
    std::memcpy(c.viewMatrix, frame.viewFromWorld.m, sizeof(c.viewMatrix));
    xefg_projection(frame.proj, frame.cameraNear, frame.cameraFar, c.projectionMatrix);
    c.jitterOffsetX = finite(frame.jitterX, 0.5f);
    c.jitterOffsetY = finite(frame.jitterY, 0.5f);
    // The motion image is in fractions of the picture; XeSS-FG reads pixels of the render size.
    c.motionVectorScaleX = float(frame.renderW);
    c.motionVectorScaleY = float(frame.renderH);
    c.resetHistory = frame.reset ? 1u : 0u;
    c.frameRenderTime = finite(frame.frameTimeMs, 1.0e6f);

    // Both images are only valid now: XeSS-FG records a copy of each into the frame's list, so they are handed over in the copy-source state.
    gpu::NativeUse uses[2];
    uses[0].image = frame.depth;
    uses[0].state = gpu::NativeState::CopySource;
    uses[1].image = frame.motion;
    uses[1].state = gpu::NativeState::CopySource;
    abi::D3d12ResourceData data[2]{};
    for (abi::D3d12ResourceData& d : data) {
        d.validity = abi::kValidityOnlyNow;
        d.resourceBase = {0, 0};
        d.resourceSize = {std::uint32_t(frame.renderW), std::uint32_t(frame.renderH)};
        d.incomingState = abi::kStateCopySource;
    }
    data[0].type = abi::kResourceDepth;
    data[0].resource = depth;
    data[1].type = abi::kResourceMotionVector;
    data[1].resource = motion;

    if (const std::int32_t rc = xe.tagFrameConstants(ctx_, presentId, &c); rc < 0) {
        fail(call_failed("xefgSwapChainTagFrameConstants", rc) + ".");
        frame.error = failure();
        return false;
    }
    const Result<gpu::NativeCommands> native = frame.list->begin_native(std::span<const gpu::NativeUse>(uses, 2));
    if (!native) {
        frame.error = "XeSS frame generation could not open a native command section: " + native.error().message;
        return false;
    }
    std::int32_t rc = abi::kResultSuccess;
    const char* what = "";
    for (const abi::D3d12ResourceData& d : data) {
        rc = xe.d3d12TagFrameResource(ctx_, const_cast<void*>(native->list), presentId,
                                      &d);  // NOLINT: a non-const list
        if (rc < 0) {
            what = d.type == abi::kResourceDepth ? "depth" : "motion vector";
            break;
        }
    }
    // The section is closed whatever XeSS-FG answered: the images are left in the state they were declared in.
    const Result<void> closed = frame.list->end_native();
    if (rc < 0) {
        fail("tagging the " + std::string(what) + " image: " + call_failed("xefgSwapChainD3D12TagFrameResource", rc) +
             ".");
        frame.error = failure();
        return false;
    }
    if (!closed) {
        frame.error = "XeSS frame generation tagged the frame, but its native command section could not be closed: " +
                      closed.error().message;
        return false;
    }
    return true;
}

void XessFrameGenProvider::stop(gpu::Device& /*device*/) {
    // Generation off and the hook passes everything through; the proxy swapchain stays (the window presents through it, and XeSS-FG can only be
    // destroyed once the swapchain is released: device_destroying).
    wantEnabled_ = false;  // the controller turns generation off before it stops the provider; a start again begins off
    if (ctx_ && live_ && enabled_) {
        api().setEnabled(ctx_, 0u);
        enabled_ = false;
    }
    running_ = false;
    taggedId_ = 0;
}

void XessFrameGenProvider::present_begin(const gpu::PresentEvent& e) {
    presents_ = e.frame;
    if (!ctx_ || !live_) return;
    // The id of the frame the last dispatch tagged; a frame it did not tag (generation paused) is named by XeLL's id all the same.
    const std::uint32_t id = running_ && taggedId_ != 0 ? taggedId_ : next_present_id(false);
    taggedId_ = 0;
    if (const std::int32_t rc = api().setPresentId(ctx_, id); rc < 0 && running_)
        fail(call_failed("xefgSwapChainSetPresentId", rc) + ".");
}

void XessFrameGenProvider::present_end(const gpu::PresentEvent& /*e*/) {
    if (!ctx_ || !live_ || !running_) return;
    const XefgApi xe = this->api();
    if (!xe.getLastPresentStatus) return;
    abi::PresentStatus status{};
    if (xe.getLastPresentStatus(ctx_, &status) < 0) return;
    if (status.isFrameGenEnabled && status.framesPresented > 1)
        generated_.fetch_add(status.framesPresented - 1, std::memory_order_relaxed);
    if (status.isFrameGenEnabled && status.frameGenResult < 0) {
        // One negative result is not the end: a swapchain being resized or a device that stalled for a frame says it for a present or two.
        // Only kStatusFailures presents in a row turn XeSS-FG off for the run (a count, so the result does not depend on the machine's speed).
        if (++statusFailures_ >= kStatusFailures)
            fail("generating a frame (" + std::to_string(statusFailures_) +
                 " presents in a row): " + call_failed("the present", status.frameGenResult) + ".");
    } else {
        statusFailures_ = 0;
    }
}

void XessFrameGenProvider::swapchain_destroying(const gpu::SwapchainEvent& /*e*/) {
    // The engine releases the proxy swapchain after this call: XeSS-FG cannot be destroyed before that (device_destroying, or the next swapchain).
    live_ = false;
    enabled_ = false;
    taggedId_ = 0;
}

void XessFrameGenProvider::destroy_context() {
    live_ = false;
    if (ctx_) {
        destroy_xefg(ctx_);  // XeSS-FG first: it uses XeLL's context
        ctx_ = nullptr;
    }
    if (xellHeld_ && share_) share_->release(device_);
    xellHeld_ = false;
    share_ = nullptr;
    xell_ = XellContext{};
    enabled_ = false;
    taggedId_ = 0;
    statusFailures_ = 0;
}

void XessFrameGenProvider::device_destroying() {
    destroy_context();
    running_ = false;
    wantEnabled_ = false;
    lastPresentId_ = 0;  // a new device counts its presents again, and so does its XeSS-FG context
    device_ = nullptr;
    intel_ = false;
}

}  // namespace

VendorLibrarySpec xefg_library_spec() { return {"xess", "FA_XESS_DIR", "libxess_fg.dll"}; }

std::string xefg_load_api(VendorLibrary& lib, XefgApi& api) {
    XefgApi a;
    std::string missing;
    bind(lib, "xefgSwapChainGetVersion", a.getVersion, missing);
    bind(lib, "xefgSwapChainD3D12CreateContext", a.d3d12Create, missing);
    bind(lib, "xefgSwapChainDestroy", a.destroy, missing);
    bind(lib, "xefgSwapChainD3D12InitFromSwapChainDesc", a.d3d12InitFromDesc, missing);
    bind(lib, "xefgSwapChainD3D12GetSwapChainPtr", a.d3d12GetSwapChainPtr, missing);
    bind(lib, "xefgSwapChainSetLatencyReduction", a.setLatencyReduction, missing);
    bind(lib, "xefgSwapChainSetEnabled", a.setEnabled, missing);
    bind(lib, "xefgSwapChainSetPresentId", a.setPresentId, missing);
    bind(lib, "xefgSwapChainTagFrameConstants", a.tagFrameConstants, missing);
    bind(lib, "xefgSwapChainD3D12TagFrameResource", a.d3d12TagFrameResource, missing);
    bind(lib, "xefgSwapChainGetLastPresentStatus", a.getLastPresentStatus, missing, true);
    if (!missing.empty()) return missing;
    api = a;
    return {};
}

std::string xefg_result_text(std::int32_t result) {
    switch (result) {
        case 0: return "success";
        case 2: return "old driver";
        case 3: return "too few frames";
        case 4: return "frame ids mismatch";
        case 5: return "missing present status";
        case 6: return "resource sizes mismatch";
        case -1: return "unsupported device";
        case -2: return "unsupported driver";
        case -3: return "uninitialized";
        case -4: return "invalid argument";
        case -5: return "device out of memory";
        case -6: return "device error";
        case -7: return "not implemented";
        case -8: return "invalid context";
        case -9: return "operation in progress";
        case -10: return "unsupported";
        case -11: return "cannot load library";
        case -12: return "mismatched input resources";
        case -13: return "incorrect output resources";
        case -14: return "incorrect input resources";
        case -15: return "latency reduction unsupported";
        case -16: return "latency reduction function missing";
        case -17: return "HRESULT failure";
        case -18: return "DXGI invalid call";
        case -19: return "pointer still in use";
        case -20: return "invalid descriptor heap";
        case -21: return "wrong call order";
        case -1000: return "unknown error";
        default: break;
    }
    return "result " + std::to_string(result);
}

void xefg_projection(const float proj[8], float nearPlane, float farPlane, float out[16]) {
    // Column-major, like Mat4: out[column * 4 + row].
    for (int i = 0; i < 16; ++i) out[i] = 0.0f;
    const auto set = [&](int row, int col, float v) { out[col * 4 + row] = v; };
    set(0, 0, proj[0]);
    set(1, 1, proj[1]);
    set(0, 2, proj[2]);
    set(1, 2, proj[3]);
    set(0, 3, proj[4]);
    set(1, 3, proj[5]);
    set(3, 2, proj[6]);
    set(3, 3, proj[7]);
    const float n = nearPlane;
    const float span = (n - farPlane) != 0.0f ? (n - farPlane) : -1.0f;
    if (std::fabs(proj[6]) > 0.5f) {  // perspective: w = -z; z from 0 at the near plane to 1 at the far one
        set(2, 2, farPlane / span);
        set(2, 3, n * farPlane / span);
    } else {  // orthographic: w = 1
        set(2, 2, 1.0f / span);
        set(2, 3, n / span);
    }
}

std::shared_ptr<FrameGenProvider> make_xess_framegen_provider() { return std::make_shared<XessFrameGenProvider>(); }

}  // namespace fa::render
