// M78-P5c: the FSR 3 frame generation provider (src/render_framegen_fsr.{h,cpp}). No AMD library is involved: the functions of the FidelityFX API
// are fakes in a table the provider takes from a fake VendorLibrary (the way it takes the real ones), the device is a RecordingDevice that answers
// a backend and native handles, and the device hook is driven by hand with the structures the engine hands a hook. What is tested is what the
// provider asks of FidelityFX: when it is available, how its hook makes the swapchain (D3D12 and Vulkan), when the frame generation context is
// made, remade and destroyed, in which order, what each frame passes (the flags the depth, the jitter and the colour set, the scale of the motion,
// the planes, the picture without the screen-space items, the reset) and what a failure of each call does (a refusal with its reason, never a
// crash). That the real library interpolates the right picture is for a Windows machine with the SDK, on D3D12 and Vulkan.
#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <functional>
#include <future>
#include <limits>
#include <map>
#include <memory>
#include <span>
#include <string>
#include <thread>
#include <vector>

#include "gpu/recording_device.h"
#include "render_framegen_fsr.h"
#include "render_upscale_vendor.h"

using namespace fa;
using render::FrameGenMode;
using render::FrameGenSlot;
using render::GpuVendor;
namespace abi = fa::render::ffx_abi;

// The Vulkan headers' names for the handles of vkDestroySwapchainKHR, as render_framegen_fsr.cpp declares them: a
// function called through PFN_vkDestroySwapchainKHR (or FidelityFX's destroy function, the same plus a context) must
// have exactly that type, and the fake's must match what the hook calls it through (clang's -fsanitize=function).
struct VkDevice_T;
struct VkSwapchainKHR_T;
struct VkAllocationCallbacks;

namespace {

#if defined(__LP64__) || defined(_WIN64) || defined(_M_X64) || defined(__x86_64__) || defined(__aarch64__) ||          \
    defined(__ia64) || defined(_M_IA64) || defined(__powerpc64__) || (defined(__riscv) && __riscv_xlen == 64)
using VkSwapchainKHR = VkSwapchainKHR_T*;
VkSwapchainKHR swapchain_handle(std::uint64_t bits) { return reinterpret_cast<VkSwapchainKHR>(std::uintptr_t(bits)); }
void* swapchain_ptr(VkSwapchainKHR h) { return h; }
#else
using VkSwapchainKHR = std::uint64_t;
VkSwapchainKHR swapchain_handle(std::uint64_t bits) { return bits; }
void* swapchain_ptr(VkSwapchainKHR h) { return reinterpret_cast<void*>(std::uintptr_t(h)); }
#endif
// vkDestroySwapchainKHR as the engine calls it (PFN_vkDestroySwapchainKHR).
using VkDestroyFn = void (*)(VkDevice_T*, VkSwapchainKHR, const VkAllocationCallbacks*);
VkDevice_T* device_handle(const void* device) { return static_cast<VkDevice_T*>(const_cast<void*>(device)); }

// ---- the fake library ---------------------------------------------------------------------------------------------------------------

struct Fk {
    abi::ReturnCode createSwapRc = 0, createFgRc = 0, configureRc = 0, queryVersionsRc = 0, querySwapFnsRc = 0,
                    dispatchRc = 0, destroyRc = 0;
    std::uint64_t versionCount = 1;
    int querySwapFnsFails = 0,
        querySwapFnsCalls = 0;    // the swapchain functions query fails this many times, then answers
    bool noSwapFn = false;        // the swapchain functions query leaves the present function null
    bool noProxy = false;         // the DX12 create says ok and gives no swapchain
    bool proxyOnFailure = false;  // the DX12 create fails (createSwapRc) and has written a proxy all the same
    bool noContext = false;       // the DX12 create says ok, gives a proxy and no context
    std::function<void()>
        onWait;  // runs inside the swapchain's wait dispatch: the render thread, with the provider's mutex held
    std::vector<std::string>
        events;  // "create swapchain", "create fg", "configure on|off|hudless", "prepare", "wait", "destroy fg", "destroy swapchain", "vk destroy", "idle"
    // what the creates saw
    abi::SwapchainForHwndDx12Desc dx12Swap{};
    abi::SwapchainVkDesc vkSwap{};
    std::uint64_t vkSwapIn = 0;
    std::uint32_t swapVersion = 0;
    abi::CreateFrameGenerationDesc fg{};
    std::uint32_t hudlessFormat = 0, fgVersion = 0;
    std::uint64_t fgBackend = 0;
    void* fgDevice = nullptr;
    // what the calls after them saw
    abi::ConfigureFrameGenerationDesc configure{};
    abi::PrepareV2Desc prepare{};
    std::uint64_t queryCreateType = 0;
    std::uint64_t vkHandle = 0x7000;  // the VkSwapchainKHR the fake makes (grows with each create)
    int dxToken = 0, swapToken = 0, fgToken = 0, vkDestroyCalls = 0;
    void* lastVkDestroy = nullptr;
    std::vector<void*> vkDestroyed;  // each swapchain FidelityFX's destroy function was given, in order
    bool sameHandle =
        false;  // the next Vulkan swapchain gets the handle of the last one (the SDK's heap reuses an address)
    int destroysOfFg = 0, destroysOfSwap = 0, creates = 0;
    void reset() { *this = Fk{}; }
};
Fk fk;

abi::Context swap_ctx() { return reinterpret_cast<abi::Context>(&fk.swapToken); }
abi::Context fg_ctx() { return reinterpret_cast<abi::Context>(&fk.fgToken); }

// FidelityFX's destroy function of a swapchain it made: vkDestroySwapchainKHR's type plus a context it does not use.
void fake_vk_destroy(VkDevice_T*, VkSwapchainKHR swapchain, const VkAllocationCallbacks*, void* context) {
    ++fk.vkDestroyCalls;
    fk.lastVkDestroy = swapchain_ptr(swapchain);
    fk.vkDestroyed.push_back(swapchain_ptr(swapchain));
    CHECK(context == nullptr);  // the SDK's replacement takes a context it does not use: the hook passes none
    fk.events.push_back("vk destroy");
}
void fake_vk_noop() {}

abi::ReturnCode fake_create(abi::Context* context, abi::Header* desc, const void*) {
    ++fk.creates;
    if (desc->type == abi::kCreateSwapchainForHwndDx12) {
        fk.events.push_back("create swapchain");
        fk.dx12Swap = *reinterpret_cast<const abi::SwapchainForHwndDx12Desc*>(desc);
        if (desc->next && desc->next->type == abi::kCreateSwapchainVersionDx12)
            fk.swapVersion = reinterpret_cast<const abi::CreateVersionDesc*>(desc->next)->version;
        if (fk.createSwapRc != 0) {
            if (fk.proxyOnFailure) *fk.dx12Swap.swapchain = &fk.dxToken;
            return fk.createSwapRc;
        }
        if (!fk.noContext) *context = swap_ctx();
        if (!fk.noProxy) *fk.dx12Swap.swapchain = &fk.dxToken;
        return 0;
    }
    if (desc->type == abi::kCreateSwapchainVk) {
        fk.events.push_back("create swapchain");
        auto* d = reinterpret_cast<abi::SwapchainVkDesc*>(desc);
        fk.vkSwap = *d;
        fk.vkSwapIn = *d->swapchain;
        if (desc->next && desc->next->type == abi::kCreateSwapchainVersionVk)
            fk.swapVersion = reinterpret_cast<const abi::CreateVersionDesc*>(desc->next)->version;
        if (fk.createSwapRc != 0) return fk.createSwapRc;
        *context = swap_ctx();
        if (!fk.sameHandle) fk.vkHandle += 0x10;
        *d->swapchain = fk.vkHandle;
        return 0;
    }
    if (desc->type == abi::kCreateFrameGeneration) {
        fk.events.push_back("create fg");
        fk.fg = *reinterpret_cast<const abi::CreateFrameGenerationDesc*>(desc);
        // The chain: hudless, then the version, then the backend.
        const abi::Header* h = desc->next;
        while (h) {
            if (h->type == abi::kCreateFrameGenerationHudless)
                fk.hudlessFormat = reinterpret_cast<const abi::CreateHudlessDesc*>(h)->hudlessBackBufferFormat;
            else if (h->type == abi::kCreateFrameGenerationVersion)
                fk.fgVersion = reinterpret_cast<const abi::CreateVersionDesc*>(h)->version;
            else {
                fk.fgBackend = h->type;
                fk.fgDevice = h->type == abi::kCreateBackendDx12
                                  ? reinterpret_cast<const abi::CreateBackendDx12Desc*>(h)->device
                                  : reinterpret_cast<const abi::CreateBackendVkDesc*>(h)->deviceContext.device;
            }
            h = h->next;
        }
        if (fk.createFgRc != 0) return fk.createFgRc;
        *context = fg_ctx();
        return 0;
    }
    return abi::kUnknownDescType;
}
abi::ReturnCode fake_destroy(abi::Context* context, const void*) {
    if (*context == fg_ctx()) {
        ++fk.destroysOfFg;
        fk.events.push_back("destroy fg");
    } else {
        ++fk.destroysOfSwap;
        fk.events.push_back("destroy swapchain");
    }
    *context = nullptr;
    return fk.destroyRc;
}
abi::ReturnCode fake_configure(abi::Context* context, const abi::Header* desc) {
    CHECK(*context == fg_ctx());
    fk.configure = *reinterpret_cast<const abi::ConfigureFrameGenerationDesc*>(desc);
    const abi::ConfigureFrameGenerationDesc& c = fk.configure;
    fk.events.push_back(c.frameGenerationEnabled  ? "configure on"
                        : c.hudlessColor.resource ? "configure hudless"
                                                  : "configure off");
    return fk.configureRc;
}
abi::ReturnCode fake_query(abi::Context* context, abi::Header* desc) {
    if (desc->type == abi::kQueryGetVersions) {
        CHECK(context == nullptr);
        fk.queryCreateType = reinterpret_cast<abi::QueryGetVersions*>(desc)->createDescType;
        if (fk.queryVersionsRc != 0) return fk.queryVersionsRc;
        *reinterpret_cast<abi::QueryGetVersions*>(desc)->outputCount = fk.versionCount;
        return 0;
    }
    if (desc->type == abi::kQuerySwapchainFunctionsVk) {
        ++fk.querySwapFnsCalls;
        if (fk.querySwapFnsFails > 0) {
            --fk.querySwapFnsFails;
            return abi::kError;
        }
        if (fk.querySwapFnsRc != 0) return fk.querySwapFnsRc;
        auto* f = reinterpret_cast<abi::SwapchainFunctionsVk*>(desc);
        f->destroySwapchain = reinterpret_cast<void*>(&fake_vk_destroy);
        f->getSwapchainImages = reinterpret_cast<void*>(&fake_vk_noop);
        f->acquireNextImage = reinterpret_cast<void*>(&fake_vk_noop);
        f->queuePresent = fk.noSwapFn ? nullptr : reinterpret_cast<void*>(&fake_vk_noop);
        f->setHdrMetadata = reinterpret_cast<void*>(&fake_vk_noop);
        return 0;
    }
    return abi::kUnknownDescType;
}
abi::ReturnCode fake_dispatch(abi::Context* context, const abi::Header* desc) {
    if (desc->type == abi::kDispatchFrameGenerationPrepareV2) {
        CHECK(*context == fg_ctx());
        fk.prepare = *reinterpret_cast<const abi::PrepareV2Desc*>(desc);
        fk.events.push_back("prepare");
    } else if (desc->type == abi::kDispatchSwapchainWaitDx12 || desc->type == abi::kDispatchSwapchainWaitVk) {
        CHECK(*context == swap_ctx());
        fk.events.push_back("wait");
        if (fk.onWait) fk.onWait();
    } else {
        return abi::kUnknownDescType;
    }
    return fk.dispatchRc;
}

class FakeLibrary final : public render::VendorLibrary {
public:
    explicit FakeLibrary(std::vector<std::string> hidden) : hidden_(std::move(hidden)) {
        table_["ffxCreateContext"] = reinterpret_cast<void*>(&fake_create);
        table_["ffxDestroyContext"] = reinterpret_cast<void*>(&fake_destroy);
        table_["ffxConfigure"] = reinterpret_cast<void*>(&fake_configure);
        table_["ffxQuery"] = reinterpret_cast<void*>(&fake_query);
        table_["ffxDispatch"] = reinterpret_cast<void*>(&fake_dispatch);
    }
    void* symbol(const char* name) override {
        if (std::find(hidden_.begin(), hidden_.end(), name) != hidden_.end()) return nullptr;
        const auto it = table_.find(name);
        return it == table_.end() ? nullptr : it->second;
    }
    const std::string& path() const override { return path_; }

private:
    std::map<std::string, void*> table_;
    std::vector<std::string> hidden_;
    std::string path_ = "fake/amd_fidelityfx_loader.dll";
};

class FakeLoader final : public render::VendorLoader {
public:
    bool installed = true, loads = true;
    std::vector<std::string> hidden;
    std::vector<std::string> askedFiles;
    std::filesystem::path find(const render::VendorLibrarySpec& spec, std::string* why) override {
        askedFiles.push_back(spec.fileName);
        if (!installed) {
            if (why) *why = "the fake loader has no library";
            return {};
        }
        return std::filesystem::path("fake") / spec.fileName;
    }
    std::unique_ptr<render::VendorLibrary> load(const std::filesystem::path&, std::string* why) override {
        if (!loads) {
            if (why) *why = "the fake loader cannot load it";
            return nullptr;
        }
        return std::make_unique<FakeLibrary>(hidden);
    }
};

struct LoaderGuard {
    explicit LoaderGuard(render::VendorLoader* l) { render::set_vendor_loader_for_test(l); }
    ~LoaderGuard() { render::set_vendor_loader_for_test(nullptr); }
    LoaderGuard(const LoaderGuard&) = delete;
    LoaderGuard& operator=(const LoaderGuard&) = delete;
};

// ---- the fake Vulkan instance: the queue families and which of them present ----------------------------------------------------------

struct FakeFamily {
    std::uint32_t flags, count;
};
struct FakeVkInstance {
    // AMD's layout: one graphics queue, a compute family, a copy family.
    std::vector<FakeFamily> families{{0x7, 1}, {0x6, 4}, {0x4, 2}};
    std::map<std::uint32_t, bool> presents;  // family -> can present to the surface (absent = yes)
    bool noSurfaceFn = false;
    std::int32_t surfaceRc = 0;
    int surfaceChecks = 0;
    std::uint32_t lastFamily = ~0u;
    std::uint64_t lastSurface = 0;
};
FakeVkInstance fvk;

void fake_queue_families(const void*, std::uint32_t* count, void* out) {
    if (!out) {
        *count = std::uint32_t(fvk.families.size());
        return;
    }
    struct Props {
        std::uint32_t flags, count, timestamp, granularity[3];
    };
    auto* props = static_cast<Props*>(out);
    for (std::uint32_t i = 0; i < *count && i < fvk.families.size(); ++i)
        props[i] = {fvk.families[i].flags, fvk.families[i].count, 64, {1, 1, 1}};
}
std::int32_t fake_surface_support(const void*, std::uint32_t family, std::uint64_t surface, std::uint32_t* supported) {
    ++fvk.surfaceChecks;
    fvk.lastFamily = family;
    fvk.lastSurface = surface;
    const auto it = fvk.presents.find(family);
    *supported = it == fvk.presents.end() || it->second ? 1u : 0u;
    return fvk.surfaceRc;
}
void (*fake_instance_proc(const void*, const char* name))() {
    const std::string n = name;
    if (n == "vkGetPhysicalDeviceQueueFamilyProperties") return reinterpret_cast<void (*)()>(&fake_queue_families);
    if (n == "vkGetPhysicalDeviceSurfaceSupportKHR" && !fvk.noSurfaceFn)
        return reinterpret_cast<void (*)()>(&fake_surface_support);
    return nullptr;
}

// ---- the fake device and command list -----------------------------------------------------------------------------------------------

void fake_proc_addr() {}

class FDevice : public gpu::RecordingDevice {
public:
    explicit FDevice(gpu::Backend deviceBackend, std::uint32_t pciVendor = 0x1002) : backend_(deviceBackend) {
        info_ = gpu::RecordingDevice::info();
        info_.backend = deviceBackend;
        info_.gpu.vendorId = pciVendor;
        info_.gpu.vendor = gpu::gpu_vendor_from_pci(pciVendor);
    }
    gpu::Backend backend() const override { return backend_; }
    const gpu::DeviceInfo& info() const override { return info_; }
    gpu::NativeDevice native() const override {
        gpu::NativeDevice n;
        n.device = reinterpret_cast<const void*>(std::uintptr_t(0x1000));
        n.instance = reinterpret_cast<const void*>(std::uintptr_t(0x2000));
        n.physicalDevice = reinterpret_cast<const void*>(std::uintptr_t(0x3000));
        n.getDeviceProcAddr = &fake_proc_addr;
        n.getInstanceProcAddr = reinterpret_cast<gpu::NativeDevice::ProcAddr>(&fake_instance_proc);
        return n;
    }
    gpu::NativeImage native_image(gpu::Image img) const override {
        gpu::NativeImage n;
        if (!img.valid() || noNative) return n;
        n.resource = reinterpret_cast<const void*>(std::uintptr_t(img.id) * 16);
        n.vkImage = std::uint64_t(img.id) * 16;
        return n;
    }
    Result<void> wait_idle() override {
        ++idles;
        fk.events.push_back("idle");
        return {};
    }
    int idles = 0;
    bool noNative = false;

    gpu::Image image(int w, int h, gpu::PixelFormat format) {
        gpu::ImageDesc d;
        d.width = w;
        d.height = h;
        d.pixelFormat = format;
        d.label = "fsrfg-test";
        return make_image(d);
    }

private:
    gpu::Backend backend_;
    gpu::DeviceInfo info_{};
};

class FList final : public gpu::RecordingCommandList {
public:
    FList(FDevice& device, gpu::Backend backend) : gpu::RecordingCommandList(device), backend_(backend) {}
    Result<gpu::NativeCommands> begin_native(std::span<const gpu::NativeUse> uses) override {
        fk.events.push_back("begin");
        if (failBegin) return make_error("the fake list refuses a native section", "none");
        declared.assign(uses.begin(), uses.end());
        gpu::NativeCommands n;
        n.backend = backend_;
        n.list = &token;
        return n;
    }
    Result<void> end_native(std::span<const gpu::NativeUse>) override {
        fk.events.push_back("end");
        ++ends;
        return {};
    }
    using gpu::CommandList::end_native;
    bool failBegin = false;
    int ends = 0, token = 0;
    std::vector<gpu::NativeUse> declared;

private:
    gpu::Backend backend_;
};

// The 64-bit layout of VkSwapchainCreateInfoKHR the hook reads (its format, size and old swapchain).
struct VkInfo {
    std::uint32_t sType = 1000001000;
    std::uint32_t pad0 = 0;
    const void* pNext = nullptr;
    std::uint32_t flags = 0, pad1 = 0;
    std::uint64_t surface = 0x55;
    std::uint32_t minImageCount = 3, imageFormat = 44, imageColorSpace = 0, width = 320, height = 180,
                  imageArrayLayers = 1, imageUsage = 0x10, imageSharingMode = 0, queueFamilyIndexCount = 0, pad2 = 0;
    const void* queueFamilyIndices = nullptr;
    std::uint32_t preTransform = 1, compositeAlpha = 1, presentMode = 2, clipped = 1;
    std::uint64_t oldSwapchain = 0;
};
static_assert(sizeof(VkInfo) == abi::kVkSwapchainCreateInfoSize, "the test's VkSwapchainCreateInfoKHR");

// A DXGI_SWAP_CHAIN_DESC1 head: width, height, format.
struct DxDesc {
    std::uint32_t width = 320, height = 180, format = 28;
    std::uint32_t rest[10]{};
};

// One rig: a device, a list, the images, the loader, a frame and the provider under test (its own instance, not the process's).
struct Rig {
    FakeLoader loader;
    LoaderGuard guard{&loader};
    FDevice dev;
    FList list;
    std::shared_ptr<render::FrameGenProvider> fsr = render::make_fsr_framegen_provider();
    std::shared_ptr<gpu::DeviceHook> hook;
    gpu::Image hudless, presented, depth, motion;
    render::FrameGenFrame frame;
    int renderW = 160, renderH = 90, outW = 320, outH = 180;
    VkInfo vkInfo;
    DxDesc dxDesc;
    gpu::VulkanSwapchainCreate vkSc;

    explicit Rig(gpu::Backend backend, std::uint32_t pciVendor = 0x1002) : dev(backend, pciVendor), list(dev, backend) {
        fk.reset();
        fvk = FakeVkInstance{};
        setup_images();
    }
    ~Rig() {
        hook.reset();
        fsr.reset();
        free_images();
    }
    Rig(const Rig&) = delete;
    Rig& operator=(const Rig&) = delete;

    void setup_images() {
        hudless = dev.image(outW, outH, gpu::PixelFormat::Rgba8);
        presented = dev.image(outW, outH, gpu::PixelFormat::Rgba8);
        depth = dev.image(renderW, renderH, gpu::PixelFormat::R32F);
        motion = dev.image(renderW, renderH, gpu::PixelFormat::Rg16F);
        frame = render::FrameGenFrame{};
        frame.device = &dev;
        frame.list = &list;
        frame.hudless = hudless;
        frame.presented = presented;
        frame.depth = depth;
        frame.motion = motion;
        frame.depthReversed = true;
        frame.depthInfinite = true;
        frame.colorFormat = gpu::PixelFormat::Rgba8;
        frame.renderW = renderW;
        frame.renderH = renderH;
        frame.outW = outW;
        frame.outH = outH;
        frame.jitterX = 0.25f;
        frame.jitterY = -0.125f;
        frame.cameraNear = 0.1f;
        frame.cameraFar = 500.0f;
        frame.cameraFovY = 1.2f;
        frame.frameTimeMs = 16.5f;
        frame.frameId = 7;
        frame.cameraPosition = {1, 2, 3};
        frame.cameraRight = {1, 0, 0};
        frame.cameraUp = {0, 1, 0};
        frame.cameraForward = {0, 0, -1};
        vkInfo.width = std::uint32_t(outW);
        vkInfo.height = std::uint32_t(outH);
        dxDesc.width = std::uint32_t(outW);
        dxDesc.height = std::uint32_t(outH);
    }
    void free_images() {
        for (const gpu::Image i : {hudless, presented, depth, motion})
            if (i.valid()) dev.destroy_image(i);
    }
    render::VendorEnv env(GpuVendor vendor = GpuVendor::Amd) const {
        render::VendorEnv e;
        e.backend = dev.backend();
        e.vendor = vendor;
        e.device = &dev;
        e.windows = true;
        return e;
    }
    render::FrameGenSwapchain swapchain() const {
        render::FrameGenSwapchain s;
        s.backend = dev.backend();
        s.width = outW;
        s.height = outH;
        return s;
    }

    // The hook, armed for `mode`.
    std::shared_ptr<gpu::DeviceHook> arm(FrameGenMode mode) {
        hook = fsr->device_hook_for(mode);
        return hook;
    }
    // The Vulkan device events the engine sends: the request (three queues of its own) and the device made with them.
    gpu::VulkanDeviceRequest vk_device(std::uint32_t pciVendor = 0x1002) {
        gpu::VulkanPhysicalDevice pd;
        pd.vendorId = pciVendor;
        pd.instance = dev.native().instance;
        pd.physicalDevice = dev.native().physicalDevice;
        pd.getInstanceProcAddr = dev.native().getInstanceProcAddr;
        gpu::VulkanDeviceRequest req;
        hook->vulkan_device_request(pd, req);
        gpu::VulkanDeviceCreated made;
        made.native = dev.native();
        made.native.context = reinterpret_cast<const void*>(std::uintptr_t(0x4000));
        made.native.graphicsFamily = 0;
        for (std::size_t i = 0; i < req.queues.size(); ++i)
            made.queues.push_back({std::uint32_t(i + 1), 0, reinterpret_cast<const void*>(std::uintptr_t(0x4100 + i))});
        hook->vulkan_device_created(made);
        return req;
    }
    // A swapchain (re)creation on Vulkan: `old` is the swapchain it replaces.
    bool vk_swapchain(std::uint64_t old = 0) {
        vkSc = gpu::VulkanSwapchainCreate{};
        vkInfo.oldSwapchain = old;
        vkSc.device = reinterpret_cast<const void*>(std::uintptr_t(0x1000));
        vkSc.createInfo = &vkInfo;
        return hook->vulkan_create_swapchain(vkSc);
    }
    gpu::D3d12SwapchainCreate dxSc;
    bool dx_swapchain() {
        dxSc = gpu::D3d12SwapchainCreate{};
        dxSc.factory = reinterpret_cast<const void*>(std::uintptr_t(0x5000));
        dxSc.queue = reinterpret_cast<const void*>(std::uintptr_t(0x5100));
        dxSc.hwnd = reinterpret_cast<const void*>(std::uintptr_t(0x5200));
        dxSc.desc = &dxDesc;
        return hook->d3d12_create_swapchain(dxSc);
    }
    void dx_device() {
        gpu::D3d12DeviceCreated made;
        made.device = const_cast<void*>(dev.native().device);
        hook->d3d12_device_created(made);
    }
    bool draw() { return fsr->dispatch(frame); }
    int count(const char* event) const { return int(std::count(fk.events.begin(), fk.events.end(), event)); }
    int index(const char* event) const {
        const auto it = std::find(fk.events.begin(), fk.events.end(), event);
        return it == fk.events.end() ? -1 : int(it - fk.events.begin());
    }
};

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

// A device made on D3D12 with FSR's hook and swapchain, the provider started: what most tests begin with.
void make_ready_dx12(Rig& r, FrameGenMode mode = FrameGenMode::Fsr) {
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE(r.arm(mode));
    r.dx_device();
    REQUIRE(r.dx_swapchain());
    REQUIRE(r.fsr->start(r.dev, r.swapchain()).empty());
}
void make_ready_vk(Rig& r, FrameGenMode mode = FrameGenMode::Fsr) {
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE(r.arm(mode));
    r.vk_device();
    REQUIRE(r.vk_swapchain());
    REQUIRE(r.fsr->start(r.dev, r.swapchain()).empty());
}

}  // namespace

// ---- the identity, the table and the pure parts ---------------------------------------------------------------------------------------

TEST_CASE("fsr frame generation: the provider fills the Fsr slot, needs the reversed depth and the hook is for the "
          "modes fsr and auto") {
    render::FrameGenProvider* p = render::framegen_provider(FrameGenSlot::Fsr);
    REQUIRE(p != nullptr);
    CHECK(p->slot() == FrameGenSlot::Fsr);
    CHECK(p->name() == "FSR 3 frame generation");
    CHECK(p->setup_id() == "fidelityfx");
    CHECK(p->backends() == ((1u << unsigned(gpu::Backend::D3d12)) | (1u << unsigned(gpu::Backend::Vulkan))));
    CHECK(p->wants_reversed_depth());
    CHECK(p->generated_frames() == 0);

    // The hooks of the table follow the mode the game asked for: an FSR swapchain under "dlss" would be wrong.
    const auto fsrHooks = render::framegen_device_hooks(FrameGenMode::Fsr);
    const auto autoHooks = render::framegen_device_hooks(FrameGenMode::Auto);
    const auto dlssHooks = render::framegen_device_hooks(FrameGenMode::Dlss);
    const auto xessHooks = render::framegen_device_hooks(FrameGenMode::Xess);
    // (The other slots' providers add their own hooks: only FSR's is looked for.)
    const std::shared_ptr<gpu::DeviceHook> fsrHook = p->device_hook_for(FrameGenMode::Fsr);
    REQUIRE(fsrHook != nullptr);
    const auto has_fsr = [&](const std::vector<std::shared_ptr<gpu::DeviceHook>>& hooks) {
        return std::any_of(hooks.begin(), hooks.end(), [&](const auto& h) { return h.get() == fsrHook.get(); });
    };
    CHECK(has_fsr(fsrHooks));
    CHECK(has_fsr(autoHooks));
    CHECK_FALSE(has_fsr(dlssHooks));
    CHECK_FALSE(has_fsr(xessHooks));
}

TEST_CASE("fsr frame generation: the create flags follow the depth, the jitter and the colour of the frame") {
    render::FrameGenFrame f;
    f.depthReversed = true;
    f.depthInfinite = true;
    f.motionJittered = false;
    f.outputEncode = render::OutputEncode::Sdr;
    std::uint32_t flags = render::fsr_fg_create_flags(f);
    CHECK((flags & abi::kFgDepthInverted) != 0);
    CHECK((flags & abi::kFgDepthInfinite) != 0);
    CHECK((flags & abi::kFgJitterCancellation) == 0);
    CHECK((flags & abi::kFgHdr) == 0);
    f.depthReversed = false;
    f.depthInfinite = false;
    f.motionJittered = true;
    f.outputEncode = render::OutputEncode::Hdr10;
    flags = render::fsr_fg_create_flags(f);
    CHECK((flags & abi::kFgDepthInverted) == 0);
    CHECK((flags & abi::kFgDepthInfinite) == 0);
    CHECK((flags & abi::kFgJitterCancellation) != 0);
    CHECK((flags & abi::kFgHdr) != 0);

    // The swapchain formats: DXGI_FORMAT_ and VkFormat numbers.
    CHECK(render::fsr_fg_dxgi_format(28) == abi::kFormatR8G8B8A8Unorm);
    CHECK(render::fsr_fg_dxgi_format(87) == abi::kFormatB8G8R8A8Unorm);
    CHECK(render::fsr_fg_dxgi_format(10) == abi::kFormatR16G16B16A16Float);
    CHECK(render::fsr_fg_dxgi_format(24) == abi::kFormatR10G10B10A2Unorm);
    CHECK(render::fsr_fg_dxgi_format(0) == abi::kFormatUnknown);
    CHECK(render::fsr_fg_vulkan_format(44) == abi::kFormatB8G8R8A8Unorm);
    CHECK(render::fsr_fg_vulkan_format(37) == abi::kFormatR8G8B8A8Unorm);
    CHECK(render::fsr_fg_vulkan_format(97) == abi::kFormatR16G16B16A16Float);
    CHECK(render::fsr_fg_vulkan_format(64) == abi::kFormatR10G10B10A2Unorm);
    CHECK(render::fsr_fg_vulkan_format(1) == abi::kFormatUnknown);
}

TEST_CASE("fsr frame generation: the ABI structures are the SDK's sizes on every platform") {
    // The same asserts as the provider's (a 64-bit target); a build for 32 bits has none of them and the provider says so in its probe.
    // (A preprocessor test, not `if constexpr`: a static_assert in a branch that is not taken is still compiled in a function that is no template.)
#if UINTPTR_MAX == 0xFFFFFFFFFFFFFFFFu
    static_assert(sizeof(abi::Resource) == 48);
    static_assert(sizeof(abi::ConfigureFrameGenerationDesc) == 144);
    static_assert(sizeof(abi::PrepareV2Desc) == 232);
    static_assert(sizeof(abi::SwapchainVkDesc) == 248);
    static_assert(sizeof(abi::SwapchainForHwndDx12Desc) == 64);
    static_assert(sizeof(abi::SwapchainFunctionsVk) == 72);
    static_assert(sizeof(abi::QueueInfo) == 24);
#endif
    CHECK(abi::kFrameGenerationVersion == ((4u << 22) | 2u));
    CHECK(abi::kSwapchainVersion == (4u << 22));
}

// ---- the probe ---------------------------------------------------------------------------------------------------------------------------

TEST_CASE("fsr frame generation probe: D3D12 and Vulkan with the library, nothing else") {
    Rig d12(gpu::Backend::D3d12);
    render::VendorProbe p = d12.fsr->probe(d12.env());
    CHECK_MESSAGE(p.available, p.reason);
    CHECK(p.reason.empty());
    CHECK(d12.loader.askedFiles.back() == "amd_fidelityfx_loader_dx12.dll");
    CHECK(fk.queryCreateType ==
          abi::kCreateFrameGeneration);  // the frame generation versions are asked for, not the upscaler's
    // Any maker's GPU: FSR 3 frame generation runs on all of them.
    CHECK(d12.fsr->probe(d12.env(GpuVendor::Nvidia)).available);

    Rig vk(gpu::Backend::Vulkan);
    p = vk.fsr->probe(vk.env());
    CHECK_MESSAGE(p.available, p.reason);
    CHECK(vk.loader.askedFiles.back() == "amd_fidelityfx_loader_vk.dll");

    for (const gpu::Backend b : {gpu::Backend::D3d11, gpu::Backend::Gl, gpu::Backend::Gles3, gpu::Backend::Metal,
                                 gpu::Backend::WebGl2, gpu::Backend::Recording}) {
        Rig other(b);
        const render::VendorProbe refused = other.fsr->probe(other.env());
        CAPTURE(int(b));
        CHECK_FALSE(refused.available);
        CHECK(has(refused.reason, "Direct3D 12") + has(refused.reason, "D3D12") + has(refused.reason, "Vulkan") > 0);
        CHECK(other.loader.askedFiles.empty());  // refused before any library is looked for
    }

    Rig notWindows(gpu::Backend::D3d12);
    render::VendorEnv e = notWindows.env();
    e.windows = false;
    p = notWindows.fsr->probe(e);
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "Windows"));
    CHECK(notWindows.loader.askedFiles.empty());
}

TEST_CASE("fsr frame generation probe: a missing library, a library that does not load or lacks an export, a driver "
          "with no provider") {
    Rig r(gpu::Backend::D3d12);
    r.loader.installed = false;
    render::VendorProbe p = r.fsr->probe(r.env());
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "factoria setup fidelityfx"));
    CHECK(has(p.reason, "not installed"));

    r.loader.installed = true;
    r.loader.loads = false;
    p = r.fsr->probe(r.env());
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "cannot load it"));
    CHECK(has(p.reason, "factoria setup fidelityfx"));

    r.loader.loads = true;
    r.loader.hidden = {"ffxConfigure"};
    p = r.fsr->probe(r.env());
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "ffxConfigure"));

    r.loader.hidden.clear();
    fk.versionCount = 0;
    p = r.fsr->probe(r.env());
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "no FSR 3 frame generation provider"));
    CHECK(has(p.reason, "factoria setup fidelityfx"));

    fk.versionCount = 1;
    fk.queryVersionsRc = abi::kNoProvider;
    p = r.fsr->probe(r.env());
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "ffxQuery"));
    CHECK(has(p.reason, "no provider"));

    fk.queryVersionsRc = 0;
    p = r.fsr->probe(r.env());
    CHECK_MESSAGE(p.available, p.reason);  // the refusals did not stick
}

// ---- the hook: Direct3D 12 -------------------------------------------------------------------------------------------------------------

TEST_CASE("fsr frame generation hook, D3D12: the swapchain is FidelityFX's proxy, made from the engine's description") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE(r.arm(FrameGenMode::Fsr));
    r.dx_device();
    REQUIRE(r.dx_swapchain());
    CHECK(r.dxSc.swapchain == &fk.dxToken);  // the proxy the engine takes over
    CHECK(r.dxSc.error.empty());
    CHECK(fk.dx12Swap.hwnd == r.dxSc.hwnd);
    CHECK(fk.dx12Swap.desc == r.dxSc.desc);
    CHECK(fk.dx12Swap.fullscreenDesc == nullptr);
    CHECK(fk.dx12Swap.dxgiFactory == r.dxSc.factory);
    CHECK(fk.dx12Swap.gameQueue == r.dxSc.queue);
    CHECK(fk.swapVersion == abi::kSwapchainVersion);
    CHECK(fk.dx12Swap.header.type == abi::kCreateSwapchainForHwndDx12);
    CHECK(r.count("create fg") == 0);  // the frame generation context waits for the first frame (it needs its sizes)

    CHECK(r.fsr->start(r.dev, r.swapchain()).empty());
    CHECK(r.count("create fg") == 0);
}

TEST_CASE("fsr frame generation hook, D3D12: a hook not armed, or armed for another mode, leaves the swapchain to the "
          "engine") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);
    CHECK(r.fsr->device_hook_for(FrameGenMode::Dlss) == nullptr);
    CHECK(r.fsr->device_hook_for(FrameGenMode::Xess) == nullptr);
    CHECK(r.fsr->device_hook_for(FrameGenMode::Off) == nullptr);

    // Auto on a machine whose GPU maker the hook cannot read (a non-Windows host) is not AMD: the engine makes its own.
    REQUIRE(r.arm(FrameGenMode::Auto));
    r.dx_device();
    CHECK_FALSE(r.dx_swapchain());
    CHECK(fk.creates == 0);
    const std::string why = r.fsr->start(r.dev, r.swapchain());
    CHECK(has(why, "AMD"));
    CHECK(has(why, "`fsr`"));
}

TEST_CASE("fsr frame generation hook, D3D12: a swapchain FidelityFX refuses is the engine's own, and start says why") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE(r.arm(FrameGenMode::Fsr));
    r.dx_device();
    fk.createSwapRc = abi::kNoProvider;
    CHECK_FALSE(r.dx_swapchain());
    CHECK(has(r.dxSc.error, "Direct3D 12 swapchain"));
    CHECK(has(r.dxSc.error, "ffxCreateContext(swapchain)"));
    CHECK(has(r.dxSc.error, "no provider"));
    CHECK(r.dxSc.swapchain == nullptr);
    const std::string why = r.fsr->start(r.dev, r.swapchain());
    CHECK(has(why, "could not take the window's swapchain"));
    CHECK(has(why, "no provider"));

    fk.createSwapRc = 0;
    fk.noProxy = true;  // ok, and no swapchain: a crash in the engine if it went on
    CHECK_FALSE(r.dx_swapchain());
    CHECK(has(r.dxSc.error, "gave no swapchain"));
    CHECK(r.count("destroy swapchain") == 1);  // the context it made is given back
}

TEST_CASE("fsr frame generation hook, D3D12: a missing library is the hook's error with the setup command") {
    Rig r(gpu::Backend::D3d12);
    r.loader.installed = false;
    REQUIRE(r.arm(FrameGenMode::Fsr));
    r.dx_device();
    CHECK_FALSE(r.dx_swapchain());
    CHECK(has(r.dxSc.error, "factoria setup fidelityfx"));
    CHECK(fk.creates == 0);
}

// ---- the hook: Vulkan -------------------------------------------------------------------------------------------------------------------

TEST_CASE("fsr frame generation hook, Vulkan: the device asks for the three queues, the swapchain is FidelityFX's with "
          "its functions") {
    Rig r(gpu::Backend::Vulkan);
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE(r.arm(FrameGenMode::Fsr));
    const gpu::VulkanDeviceRequest req = r.vk_device();
    REQUIRE(req.queues.size() ==
            3);  // compute (async interpolation), a family that can present (present), any (image acquire)
    CHECK(req.queues[0].flags == 0x2);
    CHECK(req.queues[1].flags == 0x2);  // AMD's layout: the graphics family has one queue, the compute family presents
    CHECK(req.queues[2].flags == 0);

    r.vkInfo.imageFormat = 44;  // VK_FORMAT_B8G8R8A8_UNORM
    REQUIRE(r.vk_swapchain());
    CHECK(r.vkSc.error.empty());
    CHECK(r.vkSc.swapchain == fk.vkHandle);
    CHECK(r.vkSc.result == 0);
    CHECK(fk.vkSwapIn == 0);
    CHECK(fk.swapVersion == abi::kSwapchainVersion);
    CHECK(fk.vkSwap.device == r.dev.native().device);
    CHECK(fk.vkSwap.physicalDevice == r.dev.native().physicalDevice);
    CHECK(fk.vkSwap.gameQueue.queue == reinterpret_cast<void*>(std::uintptr_t(0x4000)));
    CHECK(fk.vkSwap.asyncComputeQueue.queue == reinterpret_cast<void*>(std::uintptr_t(0x4100)));
    CHECK(fk.vkSwap.presentQueue.queue == reinterpret_cast<void*>(std::uintptr_t(0x4101)));
    CHECK(fk.vkSwap.imageAcquireQueue.queue == reinterpret_cast<void*>(std::uintptr_t(0x4102)));
    CHECK(fk.vkSwap.asyncComputeQueue.familyIndex == 1);
    CHECK(fk.vkSwap.presentQueue.familyIndex == 2);
    // The create info is the engine's own, byte for byte.
    CHECK(std::memcmp(fk.vkSwap.createInfo, &r.vkInfo, sizeof(VkInfo)) == 0);
    // The functions the engine calls from now on are FidelityFX's (the destroy one through the hook's wrapper).
    CHECK(r.vkSc.functions.getSwapchainImages != nullptr);
    CHECK(r.vkSc.functions.acquireNextImage != nullptr);
    CHECK(r.vkSc.functions.queuePresent != nullptr);
    CHECK(r.vkSc.functions.destroySwapchain != nullptr);
    CHECK(r.vkSc.functions.setHdrMetadata != nullptr);
    CHECK(r.fsr->start(r.dev, r.swapchain()).empty());
    // The present queue's family was asked whether it presents to the window's surface.
    CHECK(fvk.surfaceChecks == 1);
    CHECK(fvk.lastFamily == 2);
    CHECK(fvk.lastSurface == r.vkInfo.surface);
}

TEST_CASE("fsr frame generation hook, Vulkan: the present queue comes from a family that can present, never a "
          "transfer-only one") {
    SUBCASE("a graphics family with queues to spare (NVIDIA's layout) gives the graphics and compute family") {
        Rig r(gpu::Backend::Vulkan, 0x10de);
        fvk.families = {{0x7, 16}, {0x4, 2}, {0x6, 8}};
        REQUIRE(r.arm(FrameGenMode::Fsr));
        const gpu::VulkanDeviceRequest req = r.vk_device(0x10de);
        REQUIRE(req.queues.size() == 3);
        CHECK(req.queues[0].flags == 0x2);
        CHECK(req.queues[1].flags == 0x3);  // graphics + compute: the family that presents on every GPU
        CHECK((req.queues[1].flags & 0x4) == 0);
    }
    SUBCASE("a graphics family with few queues (AMD's) asks for the compute bit") {
        Rig r(gpu::Backend::Vulkan);
        fvk.families = {
            {0x7, 4}, {0x6, 4}, {0x4, 2}};  // four is not enough for the engine's three, the async queue and this one
        REQUIRE(r.arm(FrameGenMode::Fsr));
        CHECK(r.vk_device().queues[1].flags == 0x2);
    }
    SUBCASE("a loader that gives no family list falls back to the compute bit") {
        Rig r(gpu::Backend::Vulkan);
        REQUIRE(r.arm(FrameGenMode::Fsr));
        gpu::VulkanPhysicalDevice pd;  // no instance, no proc address
        gpu::VulkanDeviceRequest req;
        r.hook->vulkan_device_request(pd, req);
        REQUIRE(req.queues.size() == 3);
        CHECK(req.queues[1].flags == 0x2);
    }
}

TEST_CASE("fsr frame generation hook, Vulkan: a present queue that cannot present to the window is a hook error that "
          "says so, and nothing is made") {
    Rig r(gpu::Backend::Vulkan);
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE(r.arm(FrameGenMode::Fsr));
    r.vk_device();

    fvk.presents[2] = false;  // the family the device gave the present queue
    CHECK_FALSE(r.vk_swapchain());
    CHECK(has(r.vkSc.error, "no queue that can present"));
    CHECK(has(r.vkSc.error, "family 2"));
    CHECK(fk.creates == 0);
    CHECK(has(r.fsr->start(r.dev, r.swapchain()), "no queue that can present"));

    fvk.presents[2] = true;
    fvk.surfaceRc = -4;  // VK_ERROR_DEVICE_LOST
    CHECK_FALSE(r.vk_swapchain());
    CHECK(has(r.vkSc.error, "answered -4"));
    CHECK(fk.creates == 0);
    fvk.surfaceRc = 0;

    fvk.noSurfaceFn = true;
    CHECK_FALSE(r.vk_swapchain());
    CHECK(has(r.vkSc.error, "vkGetPhysicalDeviceSurfaceSupportKHR"));
    CHECK(fk.creates == 0);
    fvk.noSurfaceFn = false;

    CHECK(r.vk_swapchain());  // the hook is not marked by the engine in this fake: the same device presents now
}

TEST_CASE("fsr frame generation hook, Vulkan: Auto asks for queues on an AMD GPU only") {
    Rig r(gpu::Backend::Vulkan, 0x10de);
    REQUIRE(r.fsr->probe(r.env(GpuVendor::Nvidia)).available);
    REQUIRE(r.arm(FrameGenMode::Auto));
    const gpu::VulkanDeviceRequest req = r.vk_device(0x10de);
    CHECK(req.queues.empty());
    CHECK_FALSE(r.vk_swapchain());
    CHECK(fk.creates == 0);
    CHECK(has(r.fsr->start(r.dev, r.swapchain()), "AMD"));

    Rig amd(gpu::Backend::Vulkan);
    REQUIRE(amd.arm(FrameGenMode::Auto));
    CHECK(amd.vk_device(0x1002).queues.size() == 3);
    CHECK(amd.vk_swapchain());

    // Naming the mode uses it on any maker's GPU.
    Rig named(gpu::Backend::Vulkan, 0x10de);
    REQUIRE(named.arm(FrameGenMode::Fsr));
    CHECK(named.vk_device(0x10de).queues.size() == 3);
    CHECK(named.vk_swapchain());
}

namespace {
// What the engine does after a hook made a swapchain over `old` (vulkan_swapchain.cpp): tells the hooks the old one goes, then calls the destroy
// function the old swapchain was made with.
void engine_retires(Rig& r, std::uint64_t old, gpu::VulkanSwapchainFunctions oldFns) {
    gpu::SwapchainEvent e;
    e.backend = gpu::Backend::Vulkan;
    e.vkSwapchain = old;
    r.hook->swapchain_destroying(e);
    reinterpret_cast<VkDestroyFn>(oldFns.destroySwapchain)(device_handle(r.vkSc.device), swapchain_handle(old),
                                                           nullptr);
}
std::size_t destroyed_count(std::uint64_t handle) {
    return std::size_t(
        std::count(fk.vkDestroyed.begin(), fk.vkDestroyed.end(), reinterpret_cast<void*>(std::uintptr_t(handle))));
}
}  // namespace

TEST_CASE("fsr frame generation hook, Vulkan: a resize ends the old proxy through FidelityFX, makes the new one from "
          "no handle, and the engine's destroy of the old is skipped") {
    Rig r(gpu::Backend::Vulkan);
    make_ready_vk(r);
    const std::uint64_t first = fk.vkHandle;
    const gpu::VulkanSwapchainFunctions firstFns = r.vkSc.functions;
    REQUIRE(r.draw());  // the frame generation context exists
    fk.events.clear();

    CHECK(r.vk_swapchain(first));
    const std::uint64_t second = fk.vkHandle;
    CHECK(second != first);
    // FidelityFX's create destroys, with the driver, the swapchain it is given as the game's: the proxy of the old context is not one the
    // driver made, so it gets none, and the create info has no old swapchain either.
    CHECK(fk.vkSwapIn == 0);
    VkInfo given;
    std::memcpy(&given, fk.vkSwap.createInfo, sizeof(given));
    CHECK(given.oldSwapchain == 0);
    CHECK(r.vkSc.swapchain == second);
    // The order: the presents in flight, the generation context, the swapchain's context, the old proxy by FidelityFX's destroy (no context),
    // then the new swapchain.
    REQUIRE(r.count("destroy fg") == 1);
    CHECK(r.index("wait") < r.index("destroy fg"));
    CHECK(r.index("destroy fg") < r.index("destroy swapchain"));
    CHECK(r.index("destroy swapchain") < r.index("vk destroy"));
    CHECK(r.index("vk destroy") < r.index("create swapchain"));
    CHECK(destroyed_count(first) == 1);

    // The engine then tells the hook the old one is going and calls the destroy function of the old swapchain: nothing happens to it again.
    engine_retires(r, first, firstFns);
    CHECK(r.count("destroy swapchain") == 1);
    CHECK(destroyed_count(first) == 1);
    CHECK(fk.vkDestroyCalls == 1);

    // The next frame makes the context again, with a reset.
    REQUIRE(r.fsr->start(r.dev, r.swapchain()).empty());
    r.frame.reset = false;
    REQUIRE(r.draw());
    CHECK(r.count("create fg") == 1);
    CHECK(fk.prepare.reset);

    // The window closes: the new swapchain is destroyed once, by FidelityFX; every handle reached FidelityFX's destroy exactly once.
    engine_retires(r, second, r.vkSc.functions);
    CHECK(destroyed_count(second) == 1);
    CHECK(destroyed_count(first) == 1);
    CHECK(fk.vkDestroyed.size() == 2);
}

TEST_CASE("fsr frame generation hook, Vulkan: a resize whose new swapchain gets the address of the old one is not "
          "destroyed with it") {
    Rig r(gpu::Backend::Vulkan);
    make_ready_vk(r);
    const std::uint64_t first = fk.vkHandle;
    const gpu::VulkanSwapchainFunctions firstFns = r.vkSc.functions;
    REQUIRE(r.draw());
    fk.sameHandle = true;  // the SDK freed the old proxy and its allocator handed the new one the same address

    REQUIRE(r.vk_swapchain(first));
    CHECK(r.vkSc.swapchain == first);
    CHECK(destroyed_count(first) == 1);  // the old object, by the hook
    engine_retires(r, first, firstFns);  // the engine's destroy of "the old" swapchain is the old object's: skipped
    CHECK(destroyed_count(first) == 1);
    CHECK(r.count("destroy swapchain") == 1);

    // The new object is alive: a frame still works, and its own destruction reaches FidelityFX.
    REQUIRE(r.fsr->start(r.dev, r.swapchain()).empty());
    REQUIRE(r.draw());
    engine_retires(r, first, r.vkSc.functions);
    CHECK(destroyed_count(first) == 2);
    CHECK(r.count("destroy swapchain") == 2);
}

TEST_CASE("fsr frame generation hook, Vulkan: a resize whose creation fails leaves no handle destroyed twice and no "
          "context behind") {
    Rig r(gpu::Backend::Vulkan);
    make_ready_vk(r);
    const std::uint64_t first = fk.vkHandle;
    const gpu::VulkanSwapchainFunctions firstFns = r.vkSc.functions;
    REQUIRE(r.draw());

    fk.createSwapRc = abi::kRuntimeError;
    CHECK_FALSE(r.vk_swapchain(first));
    CHECK(has(r.vkSc.error, "Vulkan swapchain"));
    CHECK(destroyed_count(first) == 1);  // the old proxy ended by FidelityFX's destroy before the new one was tried
    // The engine retires the old swapchain (then makes its own): the hook does not touch it again.
    engine_retires(r, first, firstFns);
    CHECK(destroyed_count(first) == 1);
    CHECK(fk.vkDestroyed.size() == 1);
    CHECK(r.count("destroy fg") == 1);
    CHECK(r.count("destroy swapchain") == 1);
}

TEST_CASE("fsr frame generation hook, Vulkan: a resize refused before anything is touched leaves the old swapchain to "
          "the engine's destroy, once") {
    Rig r(gpu::Backend::Vulkan);
    make_ready_vk(r);
    const std::uint64_t first = fk.vkHandle;
    const gpu::VulkanSwapchainFunctions firstFns = r.vkSc.functions;
    REQUIRE(r.draw());
    fk.events.clear();

    fvk.presents[2] = false;
    CHECK_FALSE(r.vk_swapchain(first));
    CHECK(fk.vkDestroyed.empty());
    CHECK(fk.destroysOfSwap == 0);  // the old contexts are still there until the engine retires the old swapchain
    engine_retires(r, first, firstFns);
    CHECK(destroyed_count(first) == 1);
    CHECK(r.count("destroy fg") == 1);
    CHECK(r.count("destroy swapchain") == 1);
}

TEST_CASE("fsr frame generation hook, Vulkan: destroying the swapchain takes the contexts down in order and calls "
          "FidelityFX's destroy without a context") {
    Rig r(gpu::Backend::Vulkan);
    make_ready_vk(r);
    REQUIRE(r.draw());
    const std::uint64_t handle = fk.vkHandle;
    fk.events.clear();

    gpu::SwapchainEvent e;
    e.backend = gpu::Backend::Vulkan;
    e.vkSwapchain = handle;
    r.hook->swapchain_destroying(e);
    REQUIRE(r.count("destroy fg") == 1);
    CHECK(r.index("destroy fg") < r.index("destroy swapchain"));
    reinterpret_cast<VkDestroyFn>(r.vkSc.functions.destroySwapchain)(device_handle(r.vkSc.device),
                                                                     swapchain_handle(handle), nullptr);
    CHECK(fk.vkDestroyCalls == 1);
    CHECK(fk.lastVkDestroy == reinterpret_cast<void*>(std::uintptr_t(handle)));
    CHECK(r.index("destroy swapchain") < r.index("vk destroy"));
}

TEST_CASE("fsr frame generation hook, Vulkan: a swapchain that is not FidelityFX's is replaced by the engine, a hook "
          "that cannot is an error") {
    Rig r(gpu::Backend::Vulkan);
    REQUIRE(r.arm(FrameGenMode::Fsr));
    r.vk_device();
    CHECK_FALSE(r.vk_swapchain(
        0x1234));  // the engine's own old swapchain: the engine makes the new one, FidelityFX is not asked
    CHECK(fk.creates == 0);
    CHECK(r.vkSc.error.empty());

    fk.createSwapRc = abi::kRuntimeError;
    CHECK_FALSE(r.vk_swapchain());
    CHECK(has(r.vkSc.error, "Vulkan swapchain"));
    CHECK(has(r.vkSc.error, "ffxCreateContext(swapchain)"));
    fk.createSwapRc = 0;

    fk.querySwapFnsRc = abi::kError;
    CHECK_FALSE(r.vk_swapchain());
    CHECK(has(r.vkSc.error, "swapchain functions"));
    CHECK(fk.destroysOfSwap == 1);  // its context is given back
    fk.querySwapFnsRc = 0;

    fk.noSwapFn = true;
    CHECK_FALSE(r.vk_swapchain());
    CHECK(has(r.vkSc.error, "vkQueuePresentKHR"));
    // The swapchain FidelityFX made is ended (after its context, the SDK's order), so the window's surface is free for the engine's own.
    REQUIRE(fk.vkDestroyed.size() == 1);
    CHECK(fk.vkDestroyed[0] == reinterpret_cast<void*>(std::uintptr_t(fk.vkHandle)));
    CHECK(fk.destroysOfSwap == 2);
    CHECK(r.index("destroy swapchain") < r.index("vk destroy"));
    fk.noSwapFn = false;
    CHECK(r.vk_swapchain());
}

TEST_CASE("fsr frame generation hook, Vulkan: a device that gave fewer than three queues cannot serve FidelityFX's "
          "swapchain") {
    Rig r(gpu::Backend::Vulkan);
    REQUIRE(r.arm(FrameGenMode::Fsr));
    gpu::VulkanPhysicalDevice pd;
    pd.vendorId = 0x1002;
    gpu::VulkanDeviceRequest req;
    r.hook->vulkan_device_request(pd, req);
    gpu::VulkanDeviceCreated made;
    made.native = r.dev.native();
    made.queues.push_back({1, 0, reinterpret_cast<const void*>(std::uintptr_t(0x4100))});
    r.hook->vulkan_device_created(made);
    CHECK_FALSE(r.vk_swapchain());
    CHECK(has(r.vkSc.error, "three queues"));
    CHECK(fk.creates == 0);
}

// ---- the frames ---------------------------------------------------------------------------------------------------------------------

TEST_CASE(
    "fsr frame generation: a frame makes the context once, configures it and prepares it inside a native section") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    r.fsr->configure(true);
    REQUIRE(r.draw());
    CHECK(r.frame.error.empty());
    // Order: the context, the frame's description for the swapchain, then the section with the prepare dispatch.
    REQUIRE(r.count("create fg") == 1);
    CHECK(r.index("create fg") < r.index("configure on"));
    CHECK(r.index("configure on") < r.index("begin"));
    CHECK(r.index("begin") < r.index("prepare"));
    CHECK(r.index("prepare") < r.index("end"));
    CHECK(r.list.ends == 1);
    // The context is made for the display and the render size, the swapchain's format, with the backend.
    CHECK(fk.fg.displaySize.width == 320);
    CHECK(fk.fg.displaySize.height == 180);
    CHECK(fk.fg.maxRenderSize.width == 160);
    CHECK(fk.fg.maxRenderSize.height == 90);
    CHECK(fk.fg.backBufferFormat == abi::kFormatR8G8B8A8Unorm);
    CHECK(fk.hudlessFormat == abi::kFormatR8G8B8A8Unorm);
    CHECK(fk.fgVersion == abi::kFrameGenerationVersion);
    CHECK(fk.fgBackend == abi::kCreateBackendDx12);
    CHECK(fk.fgDevice == r.dev.native().device);
    CHECK((fk.fg.flags & abi::kFgDepthInverted) != 0);
    CHECK((fk.fg.flags & abi::kFgDepthInfinite) != 0);
    CHECK((fk.fg.flags & abi::kFgJitterCancellation) == 0);

    // Second frame: no new context, the same calls.
    fk.events.clear();
    r.frame.frameId = 8;
    REQUIRE(r.draw());
    CHECK(r.count("create fg") == 0);
    CHECK(r.count("prepare") == 1);
    CHECK(fk.prepare.frameId == 8);
}

TEST_CASE("fsr frame generation: the frame's constants reach FidelityFX as the SDK reads them") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    r.frame.motionScaleX = 1.0f;
    r.frame.motionScaleY = 1.0f;
    REQUIRE(r.draw());
    const abi::PrepareV2Desc& d = fk.prepare;
    CHECK(d.header.type == abi::kDispatchFrameGenerationPrepareV2);
    CHECK(d.frameId == 7);
    CHECK(d.renderSize.width == 160);
    CHECK(d.renderSize.height == 90);
    CHECK(d.jitterOffset.x == doctest::Approx(0.25f));
    CHECK(d.jitterOffset.y == doctest::Approx(-0.125f));
    // The motion is in fractions of the picture: FSR reads pixels of the render size.
    CHECK(d.motionVectorScale.x == doctest::Approx(160.0f));
    CHECK(d.motionVectorScale.y == doctest::Approx(90.0f));
    CHECK(d.frameTimeDelta == doctest::Approx(16.5f));
    CHECK(d.cameraNear == doctest::Approx(0.1f));
    CHECK(d.cameraFovAngleVertical == doctest::Approx(1.2f));
    CHECK(d.viewSpaceToMetersFactor == doctest::Approx(1.0f));
    CHECK(d.cameraPosition[0] == doctest::Approx(1.0f));
    CHECK(d.cameraPosition[1] == doctest::Approx(2.0f));
    CHECK(d.cameraPosition[2] == doctest::Approx(3.0f));
    CHECK(d.cameraUp[1] == doctest::Approx(1.0f));
    CHECK(d.cameraRight[0] == doctest::Approx(1.0f));
    CHECK(d.cameraForward[2] == doctest::Approx(-1.0f));
    // Infinite depth: the far plane is the largest float (FSR's "infinite").
    CHECK(d.cameraFar == std::numeric_limits<float>::max());
    CHECK(d.commandList == &r.list.token);
    // The depth and the motion are the frame's images, read as shader resources, in the formats the engine made them.
    CHECK(d.depth.resource == reinterpret_cast<void*>(std::uintptr_t(r.depth.id) * 16));
    CHECK(d.motionVectors.resource == reinterpret_cast<void*>(std::uintptr_t(r.motion.id) * 16));
    CHECK(d.depth.description.format == abi::kFormatR32Float);
    CHECK(d.motionVectors.description.format == abi::kFormatR16G16Float);
    CHECK(d.depth.description.width == 160);
    CHECK(d.depth.description.height == 90);
    CHECK(d.depth.state == abi::kStatePixelComputeRead);
    REQUIRE(r.list.declared.size() == 2);  // depth and motion; no screen-space items, no hudless image
    for (const gpu::NativeUse& u : r.list.declared) CHECK(u.state == gpu::NativeState::ShaderRead);
}

TEST_CASE("fsr frame generation: a finite depth gives the planes of the camera, a pixel-unit motion scale multiplies "
          "the render size") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    r.frame.depthReversed = false;
    r.frame.depthInfinite = false;
    r.frame.cameraNear = 0.5f;
    r.frame.cameraFar = 250.0f;
    r.frame.motionScaleX = 2.0f;
    r.frame.motionScaleY = 0.5f;
    r.frame.motionJittered = true;
    REQUIRE(r.draw());
    CHECK(fk.prepare.cameraNear == doctest::Approx(0.5f));
    CHECK(fk.prepare.cameraFar == doctest::Approx(250.0f));
    CHECK(fk.prepare.motionVectorScale.x == doctest::Approx(320.0f));
    CHECK(fk.prepare.motionVectorScale.y == doctest::Approx(45.0f));
    CHECK((fk.fg.flags & abi::kFgDepthInverted) == 0);
    CHECK((fk.fg.flags & abi::kFgDepthInfinite) == 0);
    CHECK((fk.fg.flags & abi::kFgJitterCancellation) != 0);
}

TEST_CASE("fsr frame generation: nonsense numbers in a frame become defaults, never NaN for the SDK") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    const float nan = std::numeric_limits<float>::quiet_NaN();
    r.frame.depthInfinite = false;
    r.frame.jitterX = nan;
    r.frame.jitterY = 1e30f;
    r.frame.frameTimeMs = nan;
    r.frame.cameraNear = -1.0f;
    r.frame.cameraFar = nan;
    r.frame.cameraFovY = 0.0f;
    r.frame.cameraPosition = {nan, 1e38f, 0};
    REQUIRE(r.draw());
    const abi::PrepareV2Desc& d = fk.prepare;
    CHECK(d.jitterOffset.x == 0.0f);
    CHECK(d.jitterOffset.y == doctest::Approx(1.0f));
    CHECK(d.frameTimeDelta > 0.0f);
    CHECK(d.cameraNear > 0.0f);
    CHECK(d.cameraFar > d.cameraNear);
    CHECK(d.cameraFovAngleVertical > 0.0f);
    CHECK(d.cameraPosition[0] == 0.0f);
    CHECK(d.cameraPosition[1] == doctest::Approx(1e30f));
}

TEST_CASE("fsr frame generation: the picture before the screen-space items goes to the swapchain only when the items "
          "were drawn") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    r.fsr->configure(true);

    r.frame.hudDrawn = false;
    REQUIRE(r.draw());
    CHECK(fk.configure.hudlessColor.resource == nullptr);  // the swapchain's own picture is the hudless one
    CHECK(fk.configure.frameGenerationEnabled);
    CHECK(fk.configure.swapChain == &fk.dxToken);
    CHECK(fk.configure.frameGenerationCallback != nullptr);
    CHECK(fk.configure.frameId == 7);
    CHECK(fk.configure.generationRect.width == 320);
    CHECK(fk.configure.generationRect.height == 180);
    REQUIRE(r.list.declared.size() == 2);

    r.frame.hudDrawn = true;
    REQUIRE(r.draw());
    CHECK(fk.configure.hudlessColor.resource == reinterpret_cast<void*>(std::uintptr_t(r.hudless.id) * 16));
    CHECK(fk.configure.hudlessColor.description.format == abi::kFormatR8G8B8A8Unorm);
    CHECK(fk.configure.hudlessColor.description.width == 320);
    CHECK(fk.configure.hudlessColor.state == abi::kStatePixelComputeRead);
    REQUIRE(r.list.declared.size() == 3);  // the hudless picture is declared too

    // The swapchain's callback dispatches what it is handed on the frame generation context.
    CHECK(r.fsr->generated_frames() == 0);
    using Callback = abi::ReturnCode (*)(void*, void*);
    abi::Header dispatchDesc{};
    // The fake has no frame generation dispatch type: it answers "unknown desc type", which the callback returns as an error and does not count.
    CHECK(reinterpret_cast<Callback>(fk.configure.frameGenerationCallback)(
              &dispatchDesc, fk.configure.frameGenerationCallbackUserContext) == abi::kUnknownDescType);
    CHECK(r.fsr->generated_frames() == 0);
}

TEST_CASE("fsr frame generation: the generated frames are the callback's successful dispatches since start") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    r.fsr->configure(true);
    REQUIRE(r.draw());
    using Callback = abi::ReturnCode (*)(void*, void*);
    // The swapchain's callback hands over a descriptor of the SDK's own; the fake knows the prepare type and answers ok to it.
    abi::PrepareV2Desc d{};
    d.header.type = abi::kDispatchFrameGenerationPrepareV2;
    auto cb = reinterpret_cast<Callback>(fk.configure.frameGenerationCallback);
    CHECK(cb(&d, fk.configure.frameGenerationCallbackUserContext) == abi::kOk);
    CHECK(cb(&d, fk.configure.frameGenerationCallbackUserContext) == abi::kOk);
    CHECK(r.fsr->generated_frames() == 2);
    CHECK(cb(nullptr, fk.configure.frameGenerationCallbackUserContext) == abi::kError);
    CHECK(r.fsr->generated_frames() == 2);
    // A new start counts from zero.
    r.fsr->stop(r.dev);
    REQUIRE(r.fsr->start(r.dev, r.swapchain()).empty());
    CHECK(r.fsr->generated_frames() == 0);
}

TEST_CASE("fsr frame generation: a reset is asked after the first frame, a camera cut, a failed frame and a change of "
          "the swapchain") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    REQUIRE(r.draw());
    CHECK(fk.prepare.reset);  // the first frame has no history
    REQUIRE(r.draw());
    CHECK_FALSE(fk.prepare.reset);

    r.frame.reset = true;  // a camera cut
    REQUIRE(r.draw());
    CHECK(fk.prepare.reset);
    r.frame.reset = false;
    REQUIRE(r.draw());
    CHECK_FALSE(fk.prepare.reset);

    // A frame FidelityFX refused: the next one starts the history again.
    fk.dispatchRc = abi::kError;
    CHECK_FALSE(r.draw());
    fk.dispatchRc = 0;
    REQUIRE(r.draw());
    CHECK(fk.prepare.reset);
    REQUIRE(r.draw());
    CHECK_FALSE(fk.prepare.reset);

    // The swapchain was made again: the context goes, the next frame makes it again and resets.
    r.fsr->swapchain_changed(r.dev, r.swapchain());
    fk.events.clear();
    REQUIRE(r.draw());
    CHECK(r.count("create fg") == 1);
    CHECK(fk.prepare.reset);
}

TEST_CASE("fsr frame generation: a new output size or new flags make the context again, after the old one is taken "
          "down in order") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    REQUIRE(r.draw());
    fk.events.clear();
    r.frame.depthInfinite = false;  // the flags change
    REQUIRE(r.draw());
    REQUIRE(r.count("create fg") == 1);
    CHECK(r.index("destroy fg") < r.index("create fg"));
    CHECK(r.index("wait") < r.index("destroy fg"));
    CHECK(r.index("idle") < r.index("destroy fg"));  // the GPU is idle before the context goes
    CHECK((fk.fg.flags & abi::kFgDepthInfinite) == 0);

    // A larger render size than the context was made for.
    fk.events.clear();
    r.frame.renderW = 200;
    REQUIRE(r.draw());
    CHECK(r.count("create fg") == 1);
    CHECK(fk.fg.maxRenderSize.width == 200);
    fk.events.clear();
    r.frame.renderW = 160;  // smaller again: the same context serves
    REQUIRE(r.draw());
    CHECK(r.count("create fg") == 0);
}

// ---- stop ---------------------------------------------------------------------------------------------------------------------------------

TEST_CASE("fsr frame generation: stop turns generation off, waits, and destroys the context but leaves the swapchain "
          "presenting") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    r.fsr->configure(true);
    REQUIRE(r.draw());
    fk.events.clear();
    r.fsr->stop(r.dev);
    // The SDK's shutdown: callbacks off, the presents in flight finish, the GPU is idle, the context goes.
    REQUIRE(r.count("destroy fg") == 1);
    CHECK(r.index("configure off") >= 0);
    CHECK(fk.configure.frameGenerationCallback == nullptr);
    CHECK(r.index("configure off") < r.index("wait"));
    CHECK(r.index("wait") < r.index("idle"));
    CHECK(r.index("idle") < r.index("destroy fg"));
    CHECK(r.count("destroy swapchain") == 0);  // the proxy keeps presenting the rendered frames
    // A frame after stop is refused (nothing started), and a new start works with the same swapchain.
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "not started"));
    CHECK(r.fsr->start(r.dev, r.swapchain()).empty());
    REQUIRE(r.draw());
    CHECK(r.count("create fg") == 1);
}

TEST_CASE("fsr frame generation: the swapchain going away takes the contexts down, and the device after it has nothing "
          "left") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    REQUIRE(r.draw());
    fk.events.clear();
    gpu::SwapchainEvent e;
    e.backend = gpu::Backend::D3d12;
    e.swapchain = &fk.dxToken;
    r.hook->swapchain_destroying(e);
    // Direct3D 12: the generation context goes and the presents finish while the proxy is still there; the swapchain's context waits for the
    // engine's release of the proxy (the FidelityFX sample's order: the application's reference first, then ffxDestroyContext).
    REQUIRE(r.count("destroy fg") == 1);
    CHECK(r.index("wait") < r.index("destroy fg"));
    CHECK(r.count("destroy swapchain") == 0);
    // No frame is drawn with a swapchain that is gone.
    CHECK_FALSE(r.draw());
    r.hook->device_destroying();
    CHECK(r.count("destroy fg") == 1);
    REQUIRE(r.count("destroy swapchain") == 1);
    CHECK(r.index("destroy fg") < r.index("destroy swapchain"));
    r.hook->device_destroying();  // and once only
    CHECK(r.count("destroy swapchain") == 1);
}

TEST_CASE("fsr frame generation hook, D3D12: a swapchain made after the last one went takes the last one's context "
          "down first") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    REQUIRE(r.draw());
    gpu::SwapchainEvent e;
    e.backend = gpu::Backend::D3d12;
    e.swapchain = &fk.dxToken;
    r.hook->swapchain_destroying(e);  // the engine releases the proxy after this (a window made again)
    CHECK(r.count("destroy swapchain") == 0);
    CHECK(has(r.fsr->start(r.dev, r.swapchain()), "swapchain"));  // nothing to present on until the new one is made
    fk.events.clear();
    REQUIRE(r.dx_swapchain());
    REQUIRE(r.count("destroy swapchain") == 1);
    REQUIRE(r.count("create swapchain") == 1);
    CHECK(r.index("destroy swapchain") < r.index("create swapchain"));
    CHECK(r.fsr->start(r.dev, r.swapchain()).empty());
    REQUIRE(r.draw());  // the new swapchain generates again
}

TEST_CASE("fsr frame generation: destroying the provider with a live context gives it back") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    REQUIRE(r.draw());
    fk.events.clear();
    r.hook.reset();
    r.fsr.reset();
    CHECK(fk.destroysOfFg == 1);
    CHECK(fk.destroysOfSwap == 1);
}

// ---- failures --------------------------------------------------------------------------------------------------------------------------------

TEST_CASE("fsr frame generation: start refuses without a swapchain of its own, naming what to switch on") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);
    // No hook ran: the engine made the swapchain.
    const std::string why = r.fsr->start(r.dev, r.swapchain());
    CHECK(has(why, "swapchain"));
    CHECK(has(why, "frameGeneration"));

    Rig other(gpu::Backend::Vulkan);
    REQUIRE(other.fsr->probe(other.env()).available);
    Rig dx(gpu::Backend::D3d12);
    // Not probed at all (no library): start says so rather than crash.
    CHECK(has(dx.fsr->start(dx.dev, dx.swapchain()), "probe"));

    // The swapchain's format has no FidelityFX name.
    Rig f(gpu::Backend::D3d12);
    REQUIRE(f.fsr->probe(f.env()).available);
    REQUIRE(f.arm(FrameGenMode::Fsr));
    f.dx_device();
    f.dxDesc.format = 1;
    REQUIRE(f.dx_swapchain());
    CHECK(has(f.fsr->start(f.dev, f.swapchain()), "format"));
}

TEST_CASE(
    "fsr frame generation: each FidelityFX call that fails is a refusal with the library's words, never a crash") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    r.fsr->configure(true);

    // The context cannot be made: the reason names the call and the code; the same picture is not tried again every frame.
    fk.createFgRc = abi::kNoProvider;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "ffxCreateContext"));
    CHECK(has(r.frame.error, "no provider"));
    CHECK(has(r.frame.error, "320x180"));
    const int creates = r.count("create fg");
    CHECK_FALSE(r.draw());
    CHECK(r.count("create fg") == creates);
    fk.createFgRc = 0;
    r.frame.outW = 320;
    r.frame.renderW = 100;  // another picture: tried again, and a bad parameter says what it means
    fk.createFgRc = abi::kParameterError;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "refused a parameter"));
    fk.createFgRc = 0;
    r.frame.renderW = 160;
    REQUIRE(r.draw());  // a context that can be made, is made

    // configure fails
    fk.configureRc = abi::kError;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "ffxConfigure"));
    fk.configureRc = 0;

    // prepare fails: the native section is closed all the same
    r.list.ends = 0;
    fk.dispatchRc = abi::kMemoryError;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "ffxDispatch"));
    CHECK(has(r.frame.error, "out of memory"));
    CHECK(r.list.ends == 1);
    fk.dispatchRc = 0;

    // the list refuses a native section
    r.list.failBegin = true;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "native command section"));
    r.list.failBegin = false;

    // the device knows no native resource of an image
    r.dev.noNative = true;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "native resource"));
    r.dev.noNative = false;
    CHECK(r.draw());
}

TEST_CASE("fsr frame generation: a frame that lacks what FidelityFX needs, or a device of another backend, is refused "
          "with the reason") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    gpu::Image keep = r.frame.depth;
    r.frame.depth = {};
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "depth"));
    r.frame.depth = keep;
    keep = r.frame.motion;
    r.frame.motion = {};
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "motion"));
    r.frame.motion = keep;
    r.frame.hudDrawn = true;
    keep = r.frame.hudless;
    r.frame.hudless = {};
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "hudless"));
    r.frame.hudless = keep;
    r.frame.hudDrawn = false;
    r.frame.outW = 0;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "empty picture"));
    r.frame.outW = 320;
    r.frame.colorFormat = gpu::PixelFormat::Rg32F;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "pixel format"));
    r.frame.colorFormat = gpu::PixelFormat::Rgba8;
    r.frame.list = nullptr;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "command list"));
    r.frame.list = &r.list;
    CHECK(r.draw());

    // A Vulkan device handed a frame after a D3D12 start.
    FDevice vkDev(gpu::Backend::Vulkan);
    FList vkList(vkDev, gpu::Backend::Vulkan);
    r.frame.device = &vkDev;
    r.frame.list = &vkList;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "D3D12"));
    CHECK(has(r.frame.error, "Vulkan"));
}

TEST_CASE("fsr frame generation: a failing destroy or wait is told, and the provider goes on") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    REQUIRE(r.draw());
    fk.destroyRc = abi::kError;
    fk.dispatchRc = abi::kError;  // the wait for presents fails too
    r.fsr->stop(r.dev);
    CHECK(r.count("destroy fg") == 1);
    fk.destroyRc = 0;
    fk.dispatchRc = 0;
    REQUIRE(r.fsr->start(r.dev, r.swapchain()).empty());
    REQUIRE(r.draw());
}

TEST_CASE("fsr frame generation: Vulkan frames hand FidelityFX the VkImage handles and the Vulkan backend") {
    Rig r(gpu::Backend::Vulkan);
    make_ready_vk(r);
    r.frame.hudDrawn = true;
    REQUIRE(r.draw());
    CHECK(fk.fgBackend == abi::kCreateBackendVk);
    CHECK(fk.fgDevice == r.dev.native().device);
    CHECK(fk.fg.backBufferFormat == abi::kFormatB8G8R8A8Unorm);  // the swapchain's VkFormat 44
    CHECK(fk.prepare.depth.resource == reinterpret_cast<void*>(std::uintptr_t(r.depth.id) * 16));
    CHECK(fk.configure.swapChain == reinterpret_cast<void*>(std::uintptr_t(fk.vkHandle)));
    CHECK(fk.configure.hudlessColor.resource == reinterpret_cast<void*>(std::uintptr_t(r.hudless.id) * 16));
}

// ---- M78-POLISH: what the review of the provider found ------------------------------------------------------------------------------------

namespace {
std::vector<void*> g_released;
void record_release(void* object) { g_released.push_back(object); }
struct ReleaseGuard {
    ReleaseGuard() {
        g_released.clear();
        render::set_fsr_com_release_for_test(&record_release);
    }
    ~ReleaseGuard() { render::set_fsr_com_release_for_test(nullptr); }
    ReleaseGuard(const ReleaseGuard&) = delete;
    ReleaseGuard& operator=(const ReleaseGuard&) = delete;
};
}  // namespace

TEST_CASE("fsr frame generation hook, D3D12: a proxy of an ok create that gave no context is released, one that worked "
          "is the engine's") {
    Rig r(gpu::Backend::D3d12);
    ReleaseGuard guard;
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE(r.arm(FrameGenMode::Fsr));
    r.dx_device();
    // Ok, a swapchain and no context: the reference came through the out parameter and nothing can use it, so the hook gives it back.
    fk.noContext = true;
    CHECK_FALSE(r.dx_swapchain());
    REQUIRE(g_released.size() == 1);
    CHECK(g_released[0] == &fk.dxToken);
    CHECK(r.dxSc.swapchain == nullptr);
    CHECK(has(r.dxSc.error, "gave no swapchain"));
    fk.noContext = false;
    g_released.clear();
    // An error result hands over no reference (an out parameter of a failed call, by COM's convention): nothing is released, even if the
    // fake wrote a pointer there.
    fk.createSwapRc = abi::kNoProvider;
    fk.proxyOnFailure = true;
    CHECK_FALSE(r.dx_swapchain());
    CHECK(g_released.empty());
    CHECK(r.dxSc.swapchain == nullptr);
    fk.proxyOnFailure = false;
    CHECK_FALSE(r.dx_swapchain());
    CHECK(g_released.empty());
    // Ok with a context and a proxy: the proxy goes to the engine, which owns that reference.
    fk.createSwapRc = 0;
    REQUIRE(r.dx_swapchain());
    CHECK(g_released.empty());
    CHECK(r.dxSc.swapchain == &fk.dxToken);
    // Ok with no proxy: the context goes (as before), and there is nothing to release.
    fk.noProxy = true;
    CHECK_FALSE(r.dx_swapchain());
    CHECK(g_released.empty());
}

TEST_CASE("fsr frame generation: configure between two frames repeats the last frame's number, never a 0 that goes "
          "backwards") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    r.fsr->configure(true);
    r.frame.frameId = 41;
    REQUIRE(r.draw());
    CHECK(fk.configure.frameId == 41);
    fk.events.clear();
    r.fsr->configure(false);
    REQUIRE(r.count("configure off") == 1);
    CHECK(fk.configure.frameId == 41);
    r.fsr->configure(true);
    CHECK(r.count("configure on") == 1);
    CHECK(fk.configure.frameId == 41);
    r.frame.frameId = 42;
    REQUIRE(r.draw());
    r.fsr->configure(false);
    CHECK(fk.configure.frameId == 42);
    // A frame that failed does not move the number: the SDK was not given it.
    r.frame.frameId = 43;
    fk.dispatchRc = abi::kError;
    CHECK_FALSE(r.draw());
    fk.dispatchRc = 0;
    r.fsr->configure(true);
    CHECK(fk.configure.frameId == 42);
}

TEST_CASE("fsr frame generation hook, Vulkan: mode auto on an AMD GPU asks for no queue when FidelityFX is not "
          "installed, mode fsr "
          "still does") {
    {
        Rig r(gpu::Backend::Vulkan);
        r.loader.installed = false;
        REQUIRE(r.arm(FrameGenMode::Auto));
        const gpu::VulkanDeviceRequest req = r.vk_device(0x1002);
        CHECK(req.queues.empty());
        CHECK_FALSE(r.vk_swapchain());
        CHECK(fk.creates == 0);
        const std::string why = r.fsr->start(r.dev, r.swapchain());
        CHECK(has(why, "factoria setup fidelityfx"));  // the one place that says it, once per start
        // The library is asked for once by the hook: not again for the swapchain, which has no vendor to serve.
        CHECK(r.loader.askedFiles.size() == 1);
    }
    {  // the reason of a device is not the next device's: with the library there now, the old sentence is gone
        Rig r(gpu::Backend::Vulkan);
        r.loader.installed = false;
        REQUIRE(r.arm(FrameGenMode::Auto));
        CHECK(r.vk_device(0x1002).queues.empty());
        CHECK(has(r.fsr->start(r.dev, r.swapchain()), "factoria setup fidelityfx"));
        r.loader.installed = true;
        CHECK(r.vk_device(0x1002).queues.size() == 3);
        CHECK_FALSE(has(r.fsr->start(r.dev, r.swapchain()), "factoria setup fidelityfx"));
    }
    {
        Rig r(gpu::Backend::Vulkan);
        r.loader.installed = false;
        REQUIRE(r.arm(FrameGenMode::Fsr));  // the game named it: the error is its to see, at the swapchain
        CHECK(r.vk_device(0x1002).queues.size() == 3);
        CHECK_FALSE(r.vk_swapchain());
        CHECK(has(r.vkSc.error, "factoria setup fidelityfx"));
    }
    {
        Rig r(gpu::Backend::Vulkan);  // installed: auto on AMD is what it was
        REQUIRE(r.arm(FrameGenMode::Auto));
        CHECK(r.vk_device(0x1002).queues.size() == 3);
        CHECK(r.vk_swapchain());
    }
}

// Threads. FidelityFX's present thread calls the dispatch callback while the render thread holds the provider's mutex and waits for the
// presents in flight (stop, a swapchain going away, a context made again): the callback must finish without that mutex, or the two wait for
// each other for ever. The fake's wait function is the render thread's wait; the callback runs on a thread of its own inside it.
TEST_CASE(
    "fsr frame generation: the present thread's callback finishes while the render thread waits for the presents") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    r.fsr->configure(true);
    REQUIRE(r.draw());
    using Callback = abi::ReturnCode (*)(void*, void*);
    const auto cb = reinterpret_cast<Callback>(fk.configure.frameGenerationCallback);
    void* const user = fk.configure.frameGenerationCallbackUserContext;
    REQUIRE(cb != nullptr);

    struct Shared {
        std::promise<abi::ReturnCode> done;
    };
    auto shared = std::make_shared<Shared>();
    std::future<abi::ReturnCode> result = shared->done.get_future();
    bool answered = false;
    std::thread present;
    bool fired = false;
    // The Rig ends last and waits for the presents again: the hook goes before the locals it reads (ASan: stack-use-after-scope).
    struct ClearWait {
        ~ClearWait() { fk.onWait = nullptr; }
    } clearWait;
    fk.onWait = [&] {
        if (fired) return;  // the first wait only
        fired = true;
        present = std::thread([shared, cb, user] {
            abi::PrepareV2Desc d{};
            d.header.type = abi::kDispatchFrameGenerationPrepareV2;
            shared->done.set_value(cb(&d, user));
        });
        // 20 s is a safety net, far above what a callback that does not wait takes; a callback stuck on the mutex fails here, not hangs.
        answered = result.wait_for(std::chrono::seconds(20)) == std::future_status::ready;
    };
    r.fsr->stop(r.dev);  // generation off, the presents in flight finish (the fake's wait), the context goes
    if (!answered) present.detach();  // a failing run only: the thread is stuck, and ends with the process
    REQUIRE(answered);
    present.join();
    CHECK(result.get() == abi::kOk);
    CHECK(r.fsr->generated_frames() == 1);
    CHECK(r.count("destroy fg") == 1);
    // The context is gone: a callback after that is refused, and does not touch what was destroyed.
    abi::PrepareV2Desc d{};
    d.header.type = abi::kDispatchFrameGenerationPrepareV2;
    CHECK(cb(&d, user) == abi::kError);
    CHECK(r.fsr->generated_frames() == 1);
}

TEST_CASE(
    "fsr frame generation hook, Vulkan: the destroy function of a swapchain that outlives its provider does nothing") {
    VkDestroyFn destroy = nullptr;
    std::uint64_t handle = 0;
    {
        Rig r(gpu::Backend::Vulkan);
        make_ready_vk(r);
        destroy = reinterpret_cast<VkDestroyFn>(r.vkSc.functions.destroySwapchain);
        handle = fk.vkHandle;
        r.hook.reset();
        r.fsr.reset();  // the swapchain functions are plain pointers: the engine can still hold them
        fk.vkDestroyCalls = 0;
        REQUIRE(destroy != nullptr);
        destroy(reinterpret_cast<VkDevice_T*>(std::uintptr_t(0x1000)), swapchain_handle(handle), nullptr);
        CHECK(fk.vkDestroyCalls == 0);
    }
}

TEST_CASE("fsr frame generation hook, Vulkan: the query of the swapchain functions is asked once more, and a proxy "
          "that cannot be ended is "
          "told") {
    {  // one refusal, then the answer: the swapchain is made
        Rig r(gpu::Backend::Vulkan);
        REQUIRE(r.arm(FrameGenMode::Fsr));
        r.vk_device();
        fk.querySwapFnsFails = 1;
        CHECK(r.vk_swapchain());
        CHECK(fk.querySwapFnsCalls == 2);
        CHECK(fk.destroysOfSwap == 0);
    }
    {  // two refusals on the first swapchain: no destroy function is known, the proxy stays and the message says so
        Rig r(gpu::Backend::Vulkan);
        REQUIRE(r.arm(FrameGenMode::Fsr));
        r.vk_device();
        fk.querySwapFnsFails = 2;
        CHECK_FALSE(r.vk_swapchain());
        CHECK(fk.querySwapFnsCalls == 2);
        CHECK(has(r.vkSc.error, "swapchain functions"));
        CHECK(has(r.vkSc.error, "stays until the process ends"));
        CHECK(fk.destroysOfSwap == 1);  // its context is given back
        CHECK(fk.vkDestroyCalls == 0);
    }
    {  // a swapchain of this library gave the destroy function before: the proxy is ended after its context
        Rig r(gpu::Backend::Vulkan);
        make_ready_vk(r);
        const std::uint64_t old = fk.vkHandle;
        fk.events.clear();
        fk.querySwapFnsFails = 2;
        CHECK_FALSE(r.vk_swapchain(old));
        CHECK_FALSE(has(r.vkSc.error, "stays until the process ends"));
        REQUIRE(fk.vkDestroyCalls >= 1);
        CHECK(fk.vkDestroyed.back() == reinterpret_cast<void*>(std::uintptr_t(fk.vkHandle)));
        CHECK(r.index("destroy swapchain") < r.index("vk destroy"));
    }
}
