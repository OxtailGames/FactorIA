// The FSR 3 frame generation provider of M78 (render_framegen_fsr.h): the library, the swapchain hook, the context and the frame.
#include "render_framegen_fsr.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstddef>
#include <cstring>
#include <limits>
#include <mutex>
#include <span>
#include <utility>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/types.h"

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <dxgi.h>
#endif

namespace fa::render {

namespace {

namespace abi = ffx_abi;

// The structures are the SDK's: a size or an offset that differs from the library's own is a crash, so the build says so. (FidelityFX is
// 64-bit on every platform the engine runs it on; on a 32-bit build the provider reports itself unavailable and none of these is read.)
#if UINTPTR_MAX == 0xFFFFFFFFFFFFFFFFu
static_assert(sizeof(abi::Rect2D) == 16, "FfxApiRect2D");
static_assert(sizeof(abi::CreateFrameGenerationDesc) == 40, "ffxCreateContextDescFrameGeneration");
static_assert(sizeof(abi::CreateHudlessDesc) == 24, "ffxCreateContextDescFrameGenerationHudless");
static_assert(sizeof(abi::CreateVersionDesc) == 24, "ffxCreateContextDescFrameGeneration...Version");
static_assert(sizeof(abi::ConfigureFrameGenerationDesc) == 144, "ffxConfigureDescFrameGeneration");
static_assert(offsetof(abi::ConfigureFrameGenerationDesc, frameGenerationEnabled) == 56, "ffxConfigureDescFrameGeneration::frameGenerationEnabled");
static_assert(offsetof(abi::ConfigureFrameGenerationDesc, hudlessColor) == 64, "ffxConfigureDescFrameGeneration::HUDLessColor");
static_assert(offsetof(abi::ConfigureFrameGenerationDesc, flags) == 112, "ffxConfigureDescFrameGeneration::flags");
static_assert(offsetof(abi::ConfigureFrameGenerationDesc, generationRect) == 120, "ffxConfigureDescFrameGeneration::generationRect");
static_assert(offsetof(abi::ConfigureFrameGenerationDesc, frameId) == 136, "ffxConfigureDescFrameGeneration::frameID");
static_assert(sizeof(abi::PrepareV2Desc) == 232, "ffxDispatchDescFrameGenerationPrepareV2");
static_assert(offsetof(abi::PrepareV2Desc, commandList) == 32, "PrepareV2::commandList");
static_assert(offsetof(abi::PrepareV2Desc, frameTimeDelta) == 64, "PrepareV2::frameTimeDelta");
static_assert(offsetof(abi::PrepareV2Desc, reset) == 68, "PrepareV2::reset");
static_assert(offsetof(abi::PrepareV2Desc, cameraNear) == 72, "PrepareV2::cameraNear");
static_assert(offsetof(abi::PrepareV2Desc, depth) == 88, "PrepareV2::depth");
static_assert(offsetof(abi::PrepareV2Desc, motionVectors) == 136, "PrepareV2::motionVectors");
static_assert(offsetof(abi::PrepareV2Desc, cameraPosition) == 184, "PrepareV2::cameraPosition");
static_assert(sizeof(abi::SwapchainForHwndDx12Desc) == 64, "ffxCreateContextDescFrameGenerationSwapChainForHwndDX12");
static_assert(sizeof(abi::QueueInfo) == 24, "VkQueueInfoFFXAPI");
static_assert(sizeof(abi::SwapchainVkDesc) == 248, "ffxCreateContextDescFrameGenerationSwapChainVK");
static_assert(offsetof(abi::SwapchainVkDesc, createInfo) == 48, "SwapChainVK::createInfo");
static_assert(offsetof(abi::SwapchainVkDesc, gameQueue) == 152, "SwapChainVK::gameQueue");
static_assert(sizeof(abi::SwapchainFunctionsVk) == 72, "ffxQueryDescSwapchainReplacementFunctionsVK");
#endif

// The three fields of the structures of the graphics APIs the hook reads: the format of a DXGI_SWAP_CHAIN_DESC1 and the format, size and
// old swapchain of a VkSwapchainCreateInfoKHR. They are read by value (memcpy) from the pointer the device hook hands over.
struct DxgiDesc1Head {
    std::uint32_t width, height, format;
};
struct VkCreateInfoMirror {  // VkSwapchainCreateInfoKHR, 64-bit layout
    std::uint32_t sType;
    const void* pNext;
    std::uint32_t flags;
    std::uint64_t surface;
    std::uint32_t minImageCount, imageFormat, imageColorSpace, width, height, imageArrayLayers, imageUsage, imageSharingMode,
        queueFamilyIndexCount;
    const void* queueFamilyIndices;
    std::uint32_t preTransform, compositeAlpha, presentMode, clipped;
    std::uint64_t oldSwapchain;
};
#if UINTPTR_MAX == 0xFFFFFFFFFFFFFFFFu
static_assert(sizeof(VkCreateInfoMirror) == abi::kVkSwapchainCreateInfoSize, "VkSwapchainCreateInfoKHR");
static_assert(offsetof(VkCreateInfoMirror, imageFormat) == 36, "VkSwapchainCreateInfoKHR::imageFormat");
static_assert(offsetof(VkCreateInfoMirror, oldSwapchain) == 96, "VkSwapchainCreateInfoKHR::oldSwapchain");
#endif

constexpr unsigned bit(gpu::Backend b) { return 1u << unsigned(b); }
constexpr std::uint32_t kPciVendorAmd = 0x1002;
constexpr std::uint32_t kVkQueueComputeBit = 0x2, kVkQueueTransferBit = 0x4;

// Takes `name` from the library into `fn`; the first one that is missing is remembered in `missing`.
template <class Fn>
void bind(VendorLibrary& lib, const char* name, Fn& fn, std::string& missing) {
    void* address = lib.symbol(name);
    if (!address) {
        if (missing.empty()) missing = name;
        return;
    }
    fn = reinterpret_cast<Fn>(address);  // NOLINT: the export's address
}

// What the library said to a call that went wrong, as the sentence of an error.
std::string call_failed(const char* function, std::uint32_t code) {
    std::string text = std::string(function) + " answered \"" + fsr_result_text(code) + "\" (" + std::to_string(code) + ")";
    if (code == abi::kNoProvider)
        text += ": the library has no FSR frame generation provider for this GPU or driver";
    else if (code == abi::kParameterError)
        text += ": it refused a parameter (an image whose format or usage FSR does not accept, or a size over what the "
                "context was made for)";
    else if (code == abi::kMemoryError)
        text += ": the GPU is out of memory";
    return text;
}

abi::Resource make_resource(void* handle, std::uint32_t format, int w, int h, bool storage) {
    abi::Resource r{};
    r.resource = handle;
    r.description.type = abi::kResourceTexture2d;
    r.description.format = format;
    r.description.width = std::uint32_t(std::max(w, 0));
    r.description.height = std::uint32_t(std::max(h, 0));
    r.description.depth = 1;
    r.description.mipCount = 1;
    r.description.usage = storage ? abi::kUsageUav : abi::kUsageReadOnly;
    r.state = storage ? abi::kStateUnorderedAccess : abi::kStatePixelComputeRead;
    return r;
}

void* swap_pointer(std::uint64_t handle) { return reinterpret_cast<void*>(std::uintptr_t(handle)); }  // NOLINT

// ---- the state both the hook and the provider use -------------------------------------------------------------------------------------

// What the hook decided to do with a retired Vulkan swapchain handle (a swapchain the engine still destroys after a hook replaced it).
enum class Retired : std::uint8_t {
    None,
    Skip,    // FidelityFX destroyed it already (it was replaced through the context's `swapchain` in/out pointer): the destroy is skipped
    Destroy  // its context is gone, the proxy is not: the engine's destroy goes to FidelityFX's destroy function
};

struct Core {
    std::mutex mutex;
    // the library
    std::unique_ptr<VendorLibrary> lib;
    FsrFgApi api{};
    gpu::Backend apiBackend = gpu::Backend::Recording;
    // the arming: what the renderer asked for (device_hook_for) and whether the device's GPU is one it accepts
    FrameGenMode armedMode = FrameGenMode::Off;
    bool vendorOk = false;
    std::string hookReason;  // why the hook made no swapchain, when it tried
    // Vulkan: what the hook was given when the device was made
    void* vkDevice = nullptr;
    void* vkPhysicalDevice = nullptr;
    abi::QueueInfo vkQueues[4]{};  // game, async compute, present, image acquire
    bool vkQueuesOk = false;
    // the swapchain
    abi::Context swapCtx = nullptr;
    std::uint64_t swapHandle = 0;  // IDXGISwapChain4* or VkSwapchainKHR
    std::uint32_t backFormat = abi::kFormatUnknown;
    void* vkDestroyFn = nullptr;  // FidelityFX's destroy function of the swapchain (Vulkan)
    std::uint64_t retiredHandle = 0;
    Retired retired = Retired::None;
    // the frame generation context
    abi::Context fgCtx = nullptr;
    abi::CreateFrameGenerationDesc fgKey{};
    std::uint32_t fgHudlessFormat = abi::kFormatUnknown;
    std::string fgFailedKey, fgFailure;  // the key of a context that could not be made, and why (not tried again until it changes)
    // the provider's
    bool started = false;
    bool enabled = false;
    bool needReset = true;
    std::atomic<std::uint64_t> generated{0};
    std::uint64_t generatedAtStart = 0;

    bool accepts() const { return (armedMode == FrameGenMode::Fsr || armedMode == FrameGenMode::Auto) && vendorOk; }
    // Finds, loads and binds the library of `backend` (a library a live context uses stays). "" or the sentence of what is missing.
    std::string ensure_library(gpu::Backend backend);
    // Tells the swapchain's frame generation context how the next frames go (and which callbacks). "" or the sentence of what failed.
    std::string configure_fg(bool enabled, const abi::Resource* hudless, int outW, int outH, std::uint64_t frameId);
    void teardown_fg(gpu::Device* device);
    void teardown_swapchain();
    void wait_presents();
    // Both contexts, in the SDK's order: generation off and its context, the presents that are in flight, then the swapchain's.
    void teardown_all() {
        const bool waited = fgCtx != nullptr;  // teardown_fg waits for the presents itself
        teardown_fg(nullptr);
        if (!waited) wait_presents();
        teardown_swapchain();
    }
};

std::string Core::ensure_library(gpu::Backend backend) {
    if (lib && apiBackend == backend) return {};
    if (swapCtx && lib) {
        return "FSR's swapchain is of " + std::string(vendor_backend_label(apiBackend)) + " already; this device is " +
               vendor_backend_label(backend) + ".";
    }
    std::string why;
    const VendorLibrarySpec spec = fsr_library_spec(backend);
    const std::filesystem::path found = vendor_loader().find(spec, &why);
    if (found.empty()) return "FSR is not installed: run `factoria setup fidelityfx` (" + why + ").";
    std::unique_ptr<VendorLibrary> loaded = vendor_loader().load(found, &why);
    if (!loaded) {
        return "FidelityFX's library " + fa::fs::path_to_utf8(found) + " could not be loaded: " + why +
               ". Run `factoria setup fidelityfx` to install it again.";
    }
    FsrFgApi a;
    if (const std::string missing = fsr_fg_load_api(*loaded, a); !missing.empty()) {
        return "FidelityFX's library " + loaded->path() + " has no export " + missing +
               " (it is not the FidelityFX API loader of SDK 2.x): run `factoria setup fidelityfx` to install the version "
               "FactorIA was tested with.";
    }
    lib = std::move(loaded);
    api = a;
    apiBackend = backend;
    return {};
}

// The dispatch callback the swapchain calls to interpolate: it forwards the descriptor to the frame generation context. `user` is the Core.
abi::ReturnCode fg_dispatch_callback(void* params, void* user) {
    auto* core = static_cast<Core*>(user);
    if (!core || !params || !core->api.dispatch || !core->fgCtx) return abi::kError;
    const abi::ReturnCode rc = core->api.dispatch(&core->fgCtx, static_cast<const abi::Header*>(params));
    if (rc == abi::kOk) core->generated.fetch_add(1, std::memory_order_relaxed);
    return rc;
}

std::string Core::configure_fg(bool enable, const abi::Resource* hudless, int outW, int outH, std::uint64_t frameId) {
    abi::ConfigureFrameGenerationDesc cfg{};
    cfg.header.type = abi::kConfigureFrameGeneration;
    cfg.swapChain = swap_pointer(swapHandle);
    // Off with no frame to describe: the swapchain presents the rendered frames and calls nothing back.
    const bool callbacks = enable || hudless;
    cfg.frameGenerationCallback = callbacks ? &fg_dispatch_callback : nullptr;
    cfg.frameGenerationCallbackUserContext = callbacks ? this : nullptr;
    cfg.frameGenerationEnabled = enable;
    cfg.allowAsyncWorkloads = false;
    if (hudless) cfg.hudlessColor = *hudless;
    cfg.generationRect = {0, 0, outW, outH};
    cfg.frameId = frameId;
    if (const abi::ReturnCode rc = api.configure(&fgCtx, &cfg.header); rc != abi::kOk) return call_failed("ffxConfigure", rc);
    return {};
}

void Core::wait_presents() {
    if (!swapCtx || !api.dispatch) return;
    abi::WaitForPresentsDesc wait{};
    wait.header.type = apiBackend == gpu::Backend::Vulkan ? abi::kDispatchSwapchainWaitVk : abi::kDispatchSwapchainWaitDx12;
    if (const abi::ReturnCode rc = api.dispatch(&swapCtx, &wait.header); rc != abi::kOk)
        FA_WARN("render", "FSR frame generation: {}", call_failed("ffxDispatch(wait for presents)", rc));
}

// Frame generation off for good: the swapchain forgets the callbacks, the presents that are in flight finish, the GPU is idle, then the
// context goes (the order of the SDK's shutdown).
void Core::teardown_fg(gpu::Device* device) {
    if (!fgCtx) return;
    if (api.configure && swapCtx) {
        abi::ConfigureFrameGenerationDesc cfg{};
        cfg.header.type = abi::kConfigureFrameGeneration;
        cfg.swapChain = swap_pointer(swapHandle);
        if (const abi::ReturnCode rc = api.configure(&fgCtx, &cfg.header); rc != abi::kOk)
            FA_WARN("render", "FSR frame generation: {}", call_failed("ffxConfigure", rc));
    }
    wait_presents();
    if (device) {
        if (const Result<void> idle = device->wait_idle(); !idle) FA_WARN("render", "FSR frame generation: {}", idle.error().message);
    }
    if (api.destroyContext) {
        if (const abi::ReturnCode rc = api.destroyContext(&fgCtx, nullptr); rc != abi::kOk)
            FA_WARN("render", "FSR frame generation: {}", call_failed("ffxDestroyContext", rc));
    }
    fgCtx = nullptr;
    fgKey = abi::CreateFrameGenerationDesc{};
    fgFailedKey.clear();
    fgFailure.clear();
}

void Core::teardown_swapchain() {
    if (!swapCtx) return;
    if (api.destroyContext) {
        if (const abi::ReturnCode rc = api.destroyContext(&swapCtx, nullptr); rc != abi::kOk)
            FA_WARN("render", "FSR frame generation: {}", call_failed("ffxDestroyContext(swapchain)", rc));
    }
    swapCtx = nullptr;
}

// ---- the Vulkan replacement functions ---------------------------------------------------------------------------------------------------

// The functions of the swapchain are plain function pointers the device calls without a context: the one that needs the hook's state
// reaches it through this (the Core of the swapchain that was made last; the process makes one window's swapchain with FSR at a time).
std::mutex g_active_mutex;
Core* g_active = nullptr;

void set_active(Core* core) {
    std::lock_guard<std::mutex> lock(g_active_mutex);
    g_active = core;
}

// vkDestroySwapchainKHR of a swapchain FidelityFX made: its own destroy function, after the context is gone (the SDK's order), with no context.
void vk_destroy_swapchain(void* device, void* swapchain, const void* allocator) {
    using DestroyFn = void (*)(void*, void*, const void*, void*);
    void* fn = nullptr;
    {
        std::lock_guard<std::mutex> lock(g_active_mutex);
        Core* core = g_active;
        if (!core) return;
        const auto handle = std::uint64_t(reinterpret_cast<std::uintptr_t>(swapchain));  // NOLINT
        if (core->retired != Retired::None && core->retiredHandle == handle) {
            const bool skip = core->retired == Retired::Skip;
            core->retired = Retired::None;
            core->retiredHandle = 0;
            if (skip) return;
        }
        fn = core->vkDestroyFn;
    }
    if (fn) reinterpret_cast<DestroyFn>(fn)(device, swapchain, allocator, nullptr);  // NOLINT
}

// ---- the hook --------------------------------------------------------------------------------------------------------------------------

#if defined(_WIN32)
std::uint32_t adapter_vendor(const void* adapter) {
    auto* a = static_cast<IDXGIAdapter*>(const_cast<void*>(adapter));
    DXGI_ADAPTER_DESC desc{};
    if (!a || FAILED(a->GetDesc(&desc))) return 0;
    return desc.VendorId;
}
#else
std::uint32_t adapter_vendor(const void* /*adapter*/) { return 0; }
#endif

class FsrHook final : public gpu::DeviceHook {
public:
    explicit FsrHook(std::shared_ptr<Core> core) : core_(std::move(core)) {}
    std::string_view name() const override { return "FSR 3 frame generation"; }

    void vulkan_device_request(const gpu::VulkanPhysicalDevice& pd, gpu::VulkanDeviceRequest& req) override {
        Core& c = *core_;
        std::lock_guard<std::mutex> lock(c.mutex);
        c.vkQueuesOk = false;
        c.vendorOk = c.armedMode == FrameGenMode::Fsr || (c.armedMode == FrameGenMode::Auto && pd.vendorId == kPciVendorAmd);
        if (!c.vendorOk) return;
        // FidelityFX's swapchain wants a queue of its own for the interpolation (compute), the present and the image acquire.
        req.queues.push_back({kVkQueueComputeBit, 1});
        req.queues.push_back({kVkQueueTransferBit, 1});
        req.queues.push_back({0, 1});
    }

    void vulkan_device_created(const gpu::VulkanDeviceCreated& made) override {
        Core& c = *core_;
        std::lock_guard<std::mutex> lock(c.mutex);
        if (!c.vendorOk) return;
        c.vkDevice = const_cast<void*>(made.native.device);
        c.vkPhysicalDevice = const_cast<void*>(made.native.physicalDevice);
        c.vkQueues[0] = {const_cast<void*>(made.native.context), made.native.graphicsFamily, nullptr};
        c.vkQueuesOk = made.queues.size() >= 3;
        for (std::size_t i = 0; i < 3 && i < made.queues.size(); ++i)
            c.vkQueues[i + 1] = {const_cast<void*>(made.queues[i].queue), made.queues[i].family, nullptr};
    }

    bool vulkan_create_swapchain(gpu::VulkanSwapchainCreate& sc) override {
        Core& c = *core_;
        std::lock_guard<std::mutex> lock(c.mutex);
        if (!c.accepts()) return false;
        if (!sc.createInfo) return false;
        c.hookReason.clear();
        const auto fail = [&](std::string why) {
            c.hookReason = why;
            sc.error = std::move(why);
            return false;
        };
        if (std::string why = c.ensure_library(gpu::Backend::Vulkan); !why.empty()) return fail(std::move(why));
        if (!c.vkQueuesOk)
            return fail("the Vulkan device gave FSR frame generation fewer than the three queues it asked for (compute, present, image "
                        "acquire): this GPU's queue families cannot serve FidelityFX's swapchain.");
        VkCreateInfoMirror ci{};
        std::memcpy(&ci, sc.createInfo, sizeof(ci));
        const std::uint64_t old = ci.oldSwapchain;
        // A swapchain that is not FSR's (the engine's own, made before the hook) is the engine's to replace.
        if (old != 0 && (!c.swapCtx || old != c.swapHandle)) return false;
        // The old context goes first: frame generation, then the swapchain's (the SDK's shutdown order), which the new context replaces.
        if (c.swapCtx) {
            c.teardown_all();
            c.retiredHandle = old;
            c.retired = Retired::Destroy;
        }
        std::uint64_t handle = old;
        abi::SwapchainVkDesc desc{};
        desc.header.type = abi::kCreateSwapchainVk;
        desc.physicalDevice = c.vkPhysicalDevice;
        desc.device = c.vkDevice;
        desc.swapchain = &handle;
        std::memcpy(desc.createInfo, sc.createInfo, abi::kVkSwapchainCreateInfoSize);
        desc.gameQueue = c.vkQueues[0];
        desc.asyncComputeQueue = c.vkQueues[1];
        desc.presentQueue = c.vkQueues[2];
        desc.imageAcquireQueue = c.vkQueues[3];
        abi::CreateVersionDesc version{};
        version.header.type = abi::kCreateSwapchainVersionVk;
        version.version = abi::kSwapchainVersion;
        desc.header.next = &version.header;
        abi::Context ctx = nullptr;
        if (const abi::ReturnCode rc = c.api.createContext(&ctx, &desc.header, nullptr); rc != abi::kOk || !ctx) {
            if (ctx && c.api.destroyContext) c.api.destroyContext(&ctx, nullptr);
            return fail("FSR frame generation could not make its Vulkan swapchain " + std::to_string(ci.width) + "x" +
                        std::to_string(ci.height) + ": " + call_failed("ffxCreateContext(swapchain)", rc) + ".");
        }
        // FidelityFX destroyed the swapchain it replaced: the engine's own destroy of it (it runs after this call) is skipped.
        if (old != 0) {
            c.retiredHandle = old;
            c.retired = Retired::Skip;
        }
        c.swapCtx = ctx;
        c.swapHandle = handle;
        c.backFormat = fsr_fg_vulkan_format(ci.imageFormat);
        abi::SwapchainFunctionsVk fns{};
        fns.header.type = abi::kQuerySwapchainFunctionsVk;
        if (const abi::ReturnCode rc = c.api.query(&c.swapCtx, &fns.header); rc != abi::kOk) {
            c.teardown_swapchain();
            c.swapHandle = 0;
            return fail("FSR frame generation could not get its Vulkan swapchain functions: " +
                        call_failed("ffxQuery(swapchain functions)", rc) + ".");
        }
        const char* absent = !fns.destroySwapchain      ? "vkDestroySwapchainKHR"
                             : !fns.getSwapchainImages ? "vkGetSwapchainImagesKHR"
                             : !fns.acquireNextImage   ? "vkAcquireNextImageKHR"
                             : !fns.queuePresent       ? "vkQueuePresentKHR"
                                                       : nullptr;
        if (absent) {
            c.teardown_swapchain();
            c.swapHandle = 0;
            return fail(std::string("FSR frame generation's Vulkan swapchain has no replacement for ") + absent +
                        " (the library is not the version FactorIA was tested with): run `factoria setup fidelityfx`.");
        }
        c.vkDestroyFn = fns.destroySwapchain;
        set_active(&c);
        // The engine creates the swapchain through the hook (this call) and calls the rest through the replacements. Its destroy goes
        // through ours, which drops the context argument the SDK's function takes (the SDK says it is unused).
        sc.functions.destroySwapchain = reinterpret_cast<gpu::HookProcAddr>(&vk_destroy_swapchain);
        sc.functions.getSwapchainImages = reinterpret_cast<gpu::HookProcAddr>(fns.getSwapchainImages);
        sc.functions.acquireNextImage = reinterpret_cast<gpu::HookProcAddr>(fns.acquireNextImage);
        sc.functions.queuePresent = reinterpret_cast<gpu::HookProcAddr>(fns.queuePresent);
        if (fns.setHdrMetadata) sc.functions.setHdrMetadata = reinterpret_cast<gpu::HookProcAddr>(fns.setHdrMetadata);
        sc.swapchain = handle;
        sc.result = 0;  // VK_SUCCESS
        c.needReset = true;
        return true;
    }

    void d3d12_device_created(gpu::D3d12DeviceCreated& made) override {
        Core& c = *core_;
        std::lock_guard<std::mutex> lock(c.mutex);
        c.vendorOk = c.armedMode == FrameGenMode::Fsr || (c.armedMode == FrameGenMode::Auto && adapter_vendor(made.adapter) == kPciVendorAmd);
    }

    bool d3d12_create_swapchain(gpu::D3d12SwapchainCreate& sc) override {
        Core& c = *core_;
        std::lock_guard<std::mutex> lock(c.mutex);
        if (!c.accepts()) return false;
        c.hookReason.clear();
        const auto fail = [&](std::string why) {
            c.hookReason = why;
            sc.error = std::move(why);
            return false;
        };
        if (std::string why = c.ensure_library(gpu::Backend::D3d12); !why.empty()) return fail(std::move(why));
        if (c.swapCtx) c.teardown_all();  // a second swapchain on the same hook: the first one's contexts go
        DxgiDesc1Head head{};
        if (sc.desc) std::memcpy(&head, sc.desc, sizeof(head));
        void* proxy = nullptr;
        abi::SwapchainForHwndDx12Desc desc{};
        desc.header.type = abi::kCreateSwapchainForHwndDx12;
        desc.swapchain = &proxy;
        desc.hwnd = sc.hwnd;
        desc.desc = sc.desc;
        desc.fullscreenDesc = nullptr;
        desc.dxgiFactory = const_cast<void*>(sc.factory);
        desc.gameQueue = const_cast<void*>(sc.queue);
        abi::CreateVersionDesc version{};
        version.header.type = abi::kCreateSwapchainVersionDx12;
        version.version = abi::kSwapchainVersion;
        desc.header.next = &version.header;
        abi::Context ctx = nullptr;
        if (const abi::ReturnCode rc = c.api.createContext(&ctx, &desc.header, nullptr); rc != abi::kOk || !ctx || !proxy) {
            if (ctx && c.api.destroyContext) c.api.destroyContext(&ctx, nullptr);
            return fail("FSR frame generation could not make its Direct3D 12 swapchain " + std::to_string(head.width) + "x" +
                        std::to_string(head.height) + ": " + call_failed("ffxCreateContext(swapchain)", rc) +
                        (rc == abi::kOk ? ": it gave no swapchain" : "") + ".");
        }
        c.swapCtx = ctx;
        c.swapHandle = std::uint64_t(reinterpret_cast<std::uintptr_t>(proxy));  // NOLINT
        c.backFormat = fsr_fg_dxgi_format(head.format);
        c.needReset = true;
        sc.swapchain = proxy;  // one reference, the engine's
        return true;
    }

    void swapchain_destroying(const gpu::SwapchainEvent& e) override {
        Core& c = *core_;
        std::lock_guard<std::mutex> lock(c.mutex);
        if (!c.swapCtx) return;
        const std::uint64_t handle = e.backend == gpu::Backend::Vulkan
                                         ? e.vkSwapchain
                                         : std::uint64_t(reinterpret_cast<std::uintptr_t>(e.swapchain));  // NOLINT
        // The swapchain a new one replaced (Vulkan): its context is gone already and its handle is retired.
        if (c.retired != Retired::None && handle == c.retiredHandle) return;
        if (handle != c.swapHandle) return;
        c.teardown_all();
        if (e.backend == gpu::Backend::Vulkan) {
            // The engine destroys the proxy next, through vk_destroy_swapchain: the SDK's destroy function with no context.
            c.retiredHandle = handle;
            c.retired = Retired::Destroy;
        }
        // Direct3D 12: the proxy is the engine's reference; the engine's release of it frees it (the context is gone).
        c.swapHandle = 0;
        c.started = false;
    }

    void device_destroying() override {
        Core& c = *core_;
        std::lock_guard<std::mutex> lock(c.mutex);
        c.teardown_fg(nullptr);
        c.teardown_swapchain();
        c.swapHandle = 0;
        c.started = false;
        c.vkQueuesOk = false;
        c.vkDevice = c.vkPhysicalDevice = nullptr;
    }

private:
    std::shared_ptr<Core> core_;
};

// ---- the provider -----------------------------------------------------------------------------------------------------------------------

class FsrFrameGenProvider final : public FrameGenProvider {
public:
    FsrFrameGenProvider() : core_(std::make_shared<Core>()), hook_(std::make_shared<FsrHook>(core_)) {}
    ~FsrFrameGenProvider() override {
        std::lock_guard<std::mutex> lock(core_->mutex);
        {
            std::lock_guard<std::mutex> active(g_active_mutex);
            if (g_active == core_.get()) g_active = nullptr;
        }
        core_->teardown_fg(nullptr);
        core_->teardown_swapchain();
    }

    std::string_view name() const override { return "FSR 3 frame generation"; }
    FrameGenSlot slot() const override { return FrameGenSlot::Fsr; }
    std::string_view setup_id() const override { return "fidelityfx"; }
    unsigned backends() const override { return bit(gpu::Backend::D3d12) | bit(gpu::Backend::Vulkan); }
    // FSR's frame generation reads the depth the way its upscaler does: reversed and infinite (the create flags say so).
    bool wants_reversed_depth() const override { return true; }

    VendorProbe probe(const VendorEnv& env) override;
    std::shared_ptr<gpu::DeviceHook> device_hook() override { return device_hook_for(FrameGenMode::Fsr); }
    std::shared_ptr<gpu::DeviceHook> device_hook_for(FrameGenMode mode) override {
        if (mode != FrameGenMode::Fsr && mode != FrameGenMode::Auto) return nullptr;
        std::lock_guard<std::mutex> lock(core_->mutex);
        core_->armedMode = mode;
        return hook_;
    }
    std::string start(gpu::Device& device, const FrameGenSwapchain& swapchain) override;
    void swapchain_changed(gpu::Device& device, const FrameGenSwapchain& swapchain) override;
    void configure(bool enabled) override;
    bool dispatch(FrameGenFrame& frame) override;
    std::uint64_t generated_frames() override { return core_->generated.load(std::memory_order_relaxed) - core_->generatedAtStart; }
    void stop(gpu::Device& device) override;

private:
    std::string ensure_context(gpu::Device& device, const FrameGenFrame& frame, std::uint32_t flags, std::uint32_t hudlessFormat);

    std::shared_ptr<Core> core_;
    std::shared_ptr<FsrHook> hook_;
};

VendorProbe FsrFrameGenProvider::probe(const VendorEnv& env) {
    VendorProbe p;
    p.reason = framegen_environment_problem(*this, env);
    if (p.reason.empty() && sizeof(void*) != 8) p.reason = "FidelityFX's libraries are 64-bit; this build is not.";
    if (!p.reason.empty()) return p;

    Core& c = *core_;
    std::lock_guard<std::mutex> lock(c.mutex);
    if (std::string why = c.ensure_library(env.backend); !why.empty()) {
        p.reason = std::move(why);
        return p;
    }
    // Ask the library which frame generation providers it has for this GPU (a null context: the query is made before any).
    const gpu::NativeDevice nd = env.device ? env.device->native() : gpu::NativeDevice{};
    abi::VkDeviceContext vkContext{const_cast<void*>(nd.device), const_cast<void*>(nd.physicalDevice), nd.getDeviceProcAddr};
    abi::QueryGetVersions q{};
    q.header.type = abi::kQueryGetVersions;
    q.createDescType = abi::kCreateFrameGeneration;
    q.device = env.backend == gpu::Backend::Vulkan ? static_cast<void*>(&vkContext) : const_cast<void*>(nd.device);
    std::uint64_t count = 0;
    q.outputCount = &count;
    if (const abi::ReturnCode rc = c.api.query(nullptr, &q.header); rc != abi::kOk) {
        p.reason = "FidelityFX's library " + c.lib->path() + " did not list its frame generation versions: " +
                   call_failed("ffxQuery(get versions)", rc) + ". Run `factoria setup fidelityfx` to install it again.";
        return p;
    }
    if (count == 0) {
        p.reason = "FidelityFX's library " + c.lib->path() + " has no FSR 3 frame generation provider for this GPU on " +
                   vendor_backend_label(env.backend) +
                   " (its frame generation DLL is missing next to it, or the driver is too old): run `factoria setup fidelityfx` "
                   "to install the whole SDK, or update the GPU driver.";
        return p;
    }
    p.available = true;
    return p;
}

std::string FsrFrameGenProvider::start(gpu::Device& device, const FrameGenSwapchain& swapchain) {
    Core& c = *core_;
    std::lock_guard<std::mutex> lock(c.mutex);
    if (!c.lib || !c.api.createContext) return "FSR frame generation was not found by its probe (its library is not loaded).";
    if (device.backend() != c.apiBackend) {
        return "FSR frame generation was loaded for " + std::string(vendor_backend_label(c.apiBackend)) + " and this device is " +
               vendor_backend_label(device.backend()) + ".";
    }
    if (!c.swapCtx) {
        if (!c.hookReason.empty()) return "FSR frame generation could not take the window's swapchain: " + c.hookReason;
        if (!c.accepts() && c.armedMode == FrameGenMode::Auto)
            return "mode auto uses FSR frame generation on an AMD GPU only; this device's maker is not AMD. Name the mode `fsr` to use it "
                   "anyway.";
        return "the window's swapchain is not FidelityFX's: FSR frame generation takes part in making it, so the renderer must be made "
               "with RendererDesc::frameGeneration on (factoria.json render.frameGeneration) and a window on Direct3D 12 or Vulkan.";
    }
    if (c.backFormat == abi::kFormatUnknown)
        return "the window's swapchain format has no FidelityFX name: frame generation needs an 8-bit, 10-bit or 16-bit float RGBA "
               "swapchain.";
    // The context is made on the first frame (it needs the picture's size and formats).
    c.started = true;
    c.enabled = false;
    c.needReset = true;
    c.generatedAtStart = c.generated.load(std::memory_order_relaxed);
    (void)swapchain;
    return {};
}

void FsrFrameGenProvider::swapchain_changed(gpu::Device& device, const FrameGenSwapchain& swapchain) {
    Core& c = *core_;
    std::lock_guard<std::mutex> lock(c.mutex);
    (void)swapchain;
    // The context was made for the old display size: it is made again on the next frame, which carries `reset`.
    c.teardown_fg(&device);
    c.needReset = true;
}

void FsrFrameGenProvider::configure(bool enabled) {
    Core& c = *core_;
    std::lock_guard<std::mutex> lock(c.mutex);
    c.enabled = enabled;
    if (!c.fgCtx || !c.swapCtx || !c.api.configure) return;
    // Generation on or off between two frames: the swapchain is told now (the next dispatch describes the frame in full).
    const int w = int(c.fgKey.displaySize.width), h = int(c.fgKey.displaySize.height);
    if (const std::string why = c.configure_fg(enabled, nullptr, w, h, 0); !why.empty())
        FA_WARN("render", "FSR frame generation: {}", why);
}

// Makes (or keeps) the frame generation context for this frame's sizes and formats. "" or the sentence of what failed.
std::string FsrFrameGenProvider::ensure_context(gpu::Device& device, const FrameGenFrame& frame, std::uint32_t flags,
                                                std::uint32_t hudlessFormat) {
    Core& c = *core_;
    const std::uint32_t maxW = std::uint32_t(std::max(frame.renderW, int(c.fgKey.maxRenderSize.width)));
    const std::uint32_t maxH = std::uint32_t(std::max(frame.renderH, int(c.fgKey.maxRenderSize.height)));
    if (c.fgCtx && c.fgKey.displaySize.width == std::uint32_t(frame.outW) && c.fgKey.displaySize.height == std::uint32_t(frame.outH) &&
        c.fgKey.flags == flags && c.fgKey.backBufferFormat == c.backFormat && c.fgHudlessFormat == hudlessFormat &&
        frame.renderW <= int(c.fgKey.maxRenderSize.width) && frame.renderH <= int(c.fgKey.maxRenderSize.height))
        return {};
    const std::string key = std::to_string(frame.outW) + "x" + std::to_string(frame.outH) + "/" + std::to_string(maxW) + "x" +
                            std::to_string(maxH) + "/" + std::to_string(flags) + "/" + std::to_string(c.backFormat) + "/" +
                            std::to_string(hudlessFormat);
    // A context that could not be made is not tried again every frame: the same picture would fail the same way.
    if (!c.fgFailedKey.empty() && c.fgFailedKey == key) return c.fgFailure;
    c.teardown_fg(&device);

    abi::CreateFrameGenerationDesc d{};
    d.header.type = abi::kCreateFrameGeneration;
    d.flags = flags;
    d.displaySize = {std::uint32_t(frame.outW), std::uint32_t(frame.outH)};
    d.maxRenderSize = {maxW, maxH};
    d.backBufferFormat = c.backFormat;
    abi::CreateHudlessDesc hudless{};
    hudless.header.type = abi::kCreateFrameGenerationHudless;
    hudless.hudlessBackBufferFormat = hudlessFormat;
    abi::CreateVersionDesc version{};
    version.header.type = abi::kCreateFrameGenerationVersion;
    version.version = abi::kFrameGenerationVersion;
    abi::CreateBackendDx12Desc dx{};
    abi::CreateBackendVkDesc vk{};
    const gpu::NativeDevice nd = device.native();
    if (device.backend() == gpu::Backend::Vulkan) {
        vk.header.type = abi::kCreateBackendVk;
        vk.deviceContext = {const_cast<void*>(nd.device), const_cast<void*>(nd.physicalDevice), nd.getDeviceProcAddr};
        version.header.next = &vk.header;
    } else {
        dx.header.type = abi::kCreateBackendDx12;
        dx.device = const_cast<void*>(nd.device);
        version.header.next = &dx.header;
    }
    hudless.header.next = &version.header;
    d.header.next = &hudless.header;
    abi::Context ctx = nullptr;
    const abi::ReturnCode rc = c.api.createContext(&ctx, &d.header, nullptr);
    if (rc != abi::kOk || !ctx) {
        if (ctx && c.api.destroyContext) c.api.destroyContext(&ctx, nullptr);
        c.fgFailedKey = key;
        c.fgFailure = "FSR frame generation could not make its context for " + std::to_string(frame.outW) + "x" +
                      std::to_string(frame.outH) + ": " + call_failed("ffxCreateContext", rc) + ".";
        return c.fgFailure;
    }
    c.fgCtx = ctx;
    d.header.next = nullptr;
    c.fgKey = d;
    c.fgKey.header.next = nullptr;
    c.fgHudlessFormat = hudlessFormat;
    c.fgFailedKey.clear();
    c.fgFailure.clear();
    c.needReset = true;
    return {};
}

bool FsrFrameGenProvider::dispatch(FrameGenFrame& frame) {
    Core& c = *core_;
    std::lock_guard<std::mutex> lock(c.mutex);
    frame.error.clear();
    const auto fail = [&](std::string why) {
        c.needReset = true;
        frame.error = std::move(why);
        return false;
    };
    if (!c.started || !c.lib || !c.api.dispatch) return fail("FSR frame generation was not started (the controller starts it before the first frame).");
    if (!frame.device || !frame.list) return fail("FSR frame generation was given no device or no command list.");
    gpu::Device& device = *frame.device;
    if (device.backend() != c.apiBackend)
        return fail("FSR frame generation was loaded for " + std::string(vendor_backend_label(c.apiBackend)) + " and this device is " +
                    vendor_backend_label(device.backend()) + ".");
    if (!c.swapCtx)
        return fail("FSR frame generation has no swapchain: it was destroyed or never made (the window's swapchain is made again with the "
                    "next frame generation start).");
    if (!frame.depth.valid() || !frame.motion.valid() || (frame.hudDrawn && !frame.hudless.valid())) {
        return fail(std::string("FSR frame generation needs the depth and the motion of the frame (and the picture before the screen-space items "
                                "when they were drawn): the frame has no ") +
                    (!frame.depth.valid() ? "depth" : !frame.motion.valid() ? "motion" : "hudless picture") + " image.");
    }
    if (frame.renderW <= 0 || frame.renderH <= 0 || frame.outW <= 0 || frame.outH <= 0)
        return fail("FSR frame generation was given an empty picture (" + std::to_string(frame.renderW) + "x" + std::to_string(frame.renderH) +
                    " -> " + std::to_string(frame.outW) + "x" + std::to_string(frame.outH) + ").");
    const std::uint32_t hudlessFormat = fsr_surface_format(frame.colorFormat);
    if (hudlessFormat == abi::kFormatUnknown)
        return fail("FSR frame generation: the picture's pixel format has no FidelityFX name.");
    if (std::string why = ensure_context(device, frame, fsr_fg_create_flags(frame), hudlessFormat); !why.empty()) return fail(std::move(why));

    const gpu::Backend backend = device.backend();
    // The handles come before the native section opens: a failure here leaves the list as it was.
    std::string missing;
    const auto handle_of = [&](gpu::Image image, const char* what) -> void* {
        const gpu::NativeImage ni = device.native_image(image);
        void* h = backend == gpu::Backend::Vulkan ? reinterpret_cast<void*>(std::uintptr_t(ni.vkImage))  // NOLINT
                                                  : const_cast<void*>(ni.resource);
        if (!h && missing.empty()) missing = what;
        return h;
    };
    // The picture before the screen-space items goes to the swapchain when the items were drawn over the final one; without items the
    // swapchain's own picture is the hudless one.
    const bool withHudless = frame.hudDrawn;
    abi::Resource hudless{};
    if (withHudless) hudless = make_resource(handle_of(frame.hudless, "hudless picture"), hudlessFormat, frame.outW, frame.outH, false);
    const abi::Resource depth = make_resource(handle_of(frame.depth, "depth"), abi::kFormatR32Float, frame.renderW, frame.renderH, false);
    const abi::Resource motion = make_resource(handle_of(frame.motion, "motion"), abi::kFormatR16G16Float, frame.renderW, frame.renderH, false);
    if (!missing.empty()) return fail("FSR frame generation: the device gave no native resource for the " + missing + " image.");

    // The frame's description for the swapchain: the hudless picture, the frame number, and generation on or off.
    if (const std::string why = c.configure_fg(c.enabled, withHudless ? &hudless : nullptr, frame.outW, frame.outH, frame.frameId); !why.empty())
        return fail("FSR frame generation could not describe the frame: " + why + ".");

    const auto finite = [](float v, float limit) { return std::isfinite(v) ? std::clamp(v, -limit, limit) : 0.0f; };
    abi::PrepareV2Desc d{};
    d.header.type = abi::kDispatchFrameGenerationPrepareV2;
    d.frameId = frame.frameId;
    d.flags = 0;
    d.renderSize = {std::uint32_t(frame.renderW), std::uint32_t(frame.renderH)};
    d.jitterOffset = {finite(frame.jitterX, 1.0f), finite(frame.jitterY, 1.0f)};
    // The motion image is in fractions of the picture: FSR reads pixels of the render size.
    d.motionVectorScale = {float(frame.renderW) * (frame.motionScaleX > 0.0f ? frame.motionScaleX : 1.0f),
                           float(frame.renderH) * (frame.motionScaleY > 0.0f ? frame.motionScaleY : 1.0f)};
    d.frameTimeDelta = std::isfinite(frame.frameTimeMs) && frame.frameTimeMs > 0.0f ? frame.frameTimeMs : 1000.0f / 60.0f;
    d.reset = frame.reset || c.needReset;
    d.cameraNear = std::isfinite(frame.cameraNear) && frame.cameraNear > 0.0f ? frame.cameraNear : 0.1f;
    d.cameraFar = frame.depthInfinite ? std::numeric_limits<float>::max()
                                      : (std::isfinite(frame.cameraFar) && frame.cameraFar > d.cameraNear ? frame.cameraFar : 1000.0f);
    d.cameraFovAngleVertical = std::isfinite(frame.cameraFovY) && frame.cameraFovY > 0.0f ? frame.cameraFovY : 1.0f;
    d.viewSpaceToMetersFactor = 1.0f;
    d.depth = depth;
    d.motionVectors = motion;
    d.cameraPosition[0] = finite(frame.cameraPosition.x, 1e30f);
    d.cameraPosition[1] = finite(frame.cameraPosition.y, 1e30f);
    d.cameraPosition[2] = finite(frame.cameraPosition.z, 1e30f);
    const Vec3 axes[3] = {frame.cameraUp, frame.cameraRight, frame.cameraForward};
    float* const out[3] = {d.cameraUp, d.cameraRight, d.cameraForward};
    for (int a = 0; a < 3; ++a) {
        out[a][0] = finite(axes[a].x, 1.0f);
        out[a][1] = finite(axes[a].y, 1.0f);
        out[a][2] = finite(axes[a].z, 1.0f);
    }

    // The images the SDK touches, in the state it reads them in; the engine puts them there before the native section.
    gpu::NativeUse uses[3];
    std::size_t useCount = 0;
    const auto use = [&](gpu::Image image) {
        uses[useCount].image = image;
        uses[useCount].state = gpu::NativeState::ShaderRead;
        ++useCount;
    };
    use(frame.depth);
    use(frame.motion);
    if (withHudless) use(frame.hudless);
    const Result<gpu::NativeCommands> native = frame.list->begin_native(std::span<const gpu::NativeUse>(uses, useCount));
    if (!native) return fail("FSR frame generation could not open a native command section: " + native.error().message);
    d.commandList = const_cast<void*>(native->list);
    const abi::ReturnCode rc = c.api.dispatch(&c.fgCtx, &d.header);
    // The section is closed whatever FSR answered: the images are left in the states they were declared in.
    const Result<void> closed = frame.list->end_native();
    if (rc != abi::kOk) return fail("FSR frame generation failed to prepare a frame: " + call_failed("ffxDispatch", rc) + ".");
    if (!closed) return fail("FSR frame generation prepared a frame, but its native command section could not be closed: " + closed.error().message);
    c.needReset = false;
    return true;
}

void FsrFrameGenProvider::stop(gpu::Device& device) {
    Core& c = *core_;
    std::lock_guard<std::mutex> lock(c.mutex);
    // The frame generation context goes; the proxy swapchain stays and presents the rendered frames only (it goes with the device's own
    // swapchain), so a later start() finds it again.
    c.teardown_fg(&device);
    c.started = false;
    c.enabled = false;
}

}  // namespace

std::string fsr_fg_load_api(VendorLibrary& lib, FsrFgApi& api) {
    FsrFgApi a;
    std::string missing;
    bind(lib, "ffxCreateContext", a.createContext, missing);
    bind(lib, "ffxDestroyContext", a.destroyContext, missing);
    bind(lib, "ffxConfigure", a.configure, missing);
    bind(lib, "ffxQuery", a.query, missing);
    bind(lib, "ffxDispatch", a.dispatch, missing);
    if (!missing.empty()) return missing;
    api = a;
    return {};
}

std::uint32_t fsr_fg_create_flags(const FrameGenFrame& frame) {
    std::uint32_t flags = 0;
    if (frame.depthReversed) flags |= abi::kFgDepthInverted;
    if (frame.depthInfinite) flags |= abi::kFgDepthInfinite;
    if (frame.motionJittered) flags |= abi::kFgJitterCancellation;
    if (frame.outputEncode != OutputEncode::Sdr) flags |= abi::kFgHdr;
    return flags;
}

std::uint32_t fsr_fg_dxgi_format(std::uint32_t f) {
    switch (f) {
        case 2: return abi::kFormatR32G32B32A32Float;   // DXGI_FORMAT_R32G32B32A32_FLOAT
        case 10: return abi::kFormatR16G16B16A16Float;  // R16G16B16A16_FLOAT
        case 24: return abi::kFormatR10G10B10A2Unorm;   // R10G10B10A2_UNORM
        case 26: return abi::kFormatR11G11B10Float;     // R11G11B10_FLOAT
        case 28: return abi::kFormatR8G8B8A8Unorm;      // R8G8B8A8_UNORM
        case 29: return abi::kFormatR8G8B8A8Srgb;       // R8G8B8A8_UNORM_SRGB
        case 87: return abi::kFormatB8G8R8A8Unorm;      // B8G8R8A8_UNORM
        case 91: return abi::kFormatB8G8R8A8Srgb;       // B8G8R8A8_UNORM_SRGB
        default: return abi::kFormatUnknown;
    }
}

std::uint32_t fsr_fg_vulkan_format(std::uint32_t f) {
    switch (f) {
        case 37: return abi::kFormatR8G8B8A8Unorm;      // VK_FORMAT_R8G8B8A8_UNORM
        case 43: return abi::kFormatR8G8B8A8Srgb;       // VK_FORMAT_R8G8B8A8_SRGB
        case 44: return abi::kFormatB8G8R8A8Unorm;      // VK_FORMAT_B8G8R8A8_UNORM
        case 50: return abi::kFormatB8G8R8A8Srgb;       // VK_FORMAT_B8G8R8A8_SRGB
        case 64: return abi::kFormatR10G10B10A2Unorm;   // VK_FORMAT_A2B10G10R10_UNORM_PACK32
        case 97: return abi::kFormatR16G16B16A16Float;  // VK_FORMAT_R16G16B16A16_SFLOAT
        case 109: return abi::kFormatR32G32B32A32Float; // VK_FORMAT_R32G32B32A32_SFLOAT
        case 122: return abi::kFormatR11G11B10Float;    // VK_FORMAT_B10G11R11_UFLOAT_PACK32
        default: return abi::kFormatUnknown;
    }
}

std::shared_ptr<FrameGenProvider> make_fsr_framegen_provider() { return std::make_shared<FsrFrameGenProvider>(); }

}  // namespace fa::render
