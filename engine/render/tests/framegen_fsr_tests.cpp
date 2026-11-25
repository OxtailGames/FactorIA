// M78-P5c: the FSR 3 frame generation provider (src/render_framegen_fsr.{h,cpp}). No AMD library is involved: the functions of the FidelityFX API
// are fakes in a table the provider takes from a fake VendorLibrary (the way it takes the real ones), the device is a RecordingDevice that answers
// a backend and native handles, and the device hook is driven by hand with the structures the engine hands a hook. What is tested is what the
// provider asks of FidelityFX: when it is available, how its hook makes the swapchain (D3D12 and Vulkan), when the frame generation context is
// made, remade and destroyed, in which order, what each frame passes (the flags the depth, the jitter and the colour set, the scale of the motion,
// the planes, the picture without the screen-space items, the reset) and what a failure of each call does (a refusal with its reason, never a
// crash). That the real library interpolates the right picture is for a Windows machine with the SDK, on D3D12 and Vulkan.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <limits>
#include <map>
#include <memory>
#include <span>
#include <string>
#include <vector>

#include "gpu/recording_device.h"
#include "render_framegen_fsr.h"
#include "render_upscale_vendor.h"

using namespace fa;
using render::FrameGenMode;
using render::FrameGenSlot;
using render::GpuVendor;
namespace abi = fa::render::ffx_abi;

namespace {

// ---- the fake library ---------------------------------------------------------------------------------------------------------------

struct Fk {
    abi::ReturnCode createSwapRc = 0, createFgRc = 0, configureRc = 0, queryVersionsRc = 0, querySwapFnsRc = 0, dispatchRc = 0, destroyRc = 0;
    std::uint64_t versionCount = 1;
    bool noSwapFn = false;       // the swapchain functions query leaves the present function null
    bool noProxy = false;        // the DX12 create says ok and gives no swapchain
    std::vector<std::string> events;  // "create swapchain", "create fg", "configure on|off|hudless", "prepare", "wait", "destroy fg", "destroy swapchain", "vk destroy", "idle"
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
    int destroysOfFg = 0, destroysOfSwap = 0, creates = 0;
    void reset() { *this = Fk{}; }
};
Fk fk;

abi::Context swap_ctx() { return reinterpret_cast<abi::Context>(&fk.swapToken); }
abi::Context fg_ctx() { return reinterpret_cast<abi::Context>(&fk.fgToken); }

void fake_vk_destroy(void*, void* swapchain, const void*, void* context) {
    ++fk.vkDestroyCalls;
    fk.lastVkDestroy = swapchain;
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
        if (fk.createSwapRc != 0) return fk.createSwapRc;
        *context = swap_ctx();
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
        fk.vkHandle += 0x10;
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
                fk.fgDevice = h->type == abi::kCreateBackendDx12 ? reinterpret_cast<const abi::CreateBackendDx12Desc*>(h)->device
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
    fk.events.push_back(c.frameGenerationEnabled ? "configure on" : c.hudlessColor.resource ? "configure hudless" : "configure off");
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
    std::uint32_t minImageCount = 3, imageFormat = 44, imageColorSpace = 0, width = 320, height = 180, imageArrayLayers = 1, imageUsage = 0x10,
                  imageSharingMode = 0, queueFamilyIndexCount = 0, pad2 = 0;
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

TEST_CASE("fsr frame generation: the provider fills the Fsr slot, needs the reversed depth and the hook is for the modes fsr and auto") {
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
    CHECK(fsrHooks.size() == 1);
    CHECK(autoHooks.size() == 1);
    CHECK(dlssHooks.empty());
    CHECK(xessHooks.empty());
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
    if constexpr (sizeof(void*) == 8) {
        static_assert(sizeof(abi::Resource) == 48);
        static_assert(sizeof(abi::ConfigureFrameGenerationDesc) == 144);
        static_assert(sizeof(abi::PrepareV2Desc) == 232);
        static_assert(sizeof(abi::SwapchainVkDesc) == 248);
        static_assert(sizeof(abi::SwapchainForHwndDx12Desc) == 64);
        static_assert(sizeof(abi::SwapchainFunctionsVk) == 72);
        static_assert(sizeof(abi::QueueInfo) == 24);
    }
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
    CHECK(fk.queryCreateType == abi::kCreateFrameGeneration);  // the frame generation versions are asked for, not the upscaler's
    // Any maker's GPU: FSR 3 frame generation runs on all of them.
    CHECK(d12.fsr->probe(d12.env(GpuVendor::Nvidia)).available);

    Rig vk(gpu::Backend::Vulkan);
    p = vk.fsr->probe(vk.env());
    CHECK_MESSAGE(p.available, p.reason);
    CHECK(vk.loader.askedFiles.back() == "amd_fidelityfx_loader_vk.dll");

    for (const gpu::Backend b : {gpu::Backend::D3d11, gpu::Backend::Gl, gpu::Backend::Gles3, gpu::Backend::Metal, gpu::Backend::WebGl2,
                                 gpu::Backend::Recording}) {
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

TEST_CASE("fsr frame generation probe: a missing library, a library that does not load or lacks an export, a driver with no provider") {
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

TEST_CASE("fsr frame generation hook, D3D12: a hook not armed, or armed for another mode, leaves the swapchain to the engine") {
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

TEST_CASE("fsr frame generation hook, Vulkan: the device asks for the three queues, the swapchain is FidelityFX's with its functions") {
    Rig r(gpu::Backend::Vulkan);
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE(r.arm(FrameGenMode::Fsr));
    const gpu::VulkanDeviceRequest req = r.vk_device();
    REQUIRE(req.queues.size() == 3);  // compute (async interpolation), transfer-only (present), any (image acquire)
    CHECK((req.queues[0].flags & 0x2) != 0);
    CHECK((req.queues[1].flags & 0x4) != 0);

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

TEST_CASE("fsr frame generation hook, Vulkan: a resize drops the old context first, FidelityFX destroys the old swapchain and the engine's destroy of it is skipped") {
    Rig r(gpu::Backend::Vulkan);
    make_ready_vk(r);
    const std::uint64_t first = fk.vkHandle;
    REQUIRE(r.draw());  // the frame generation context exists
    fk.events.clear();

    CHECK(r.vk_swapchain(first));
    const std::uint64_t second = fk.vkHandle;
    CHECK(second != first);
    CHECK(fk.vkSwapIn == first);  // FidelityFX is given the swapchain it replaces
    CHECK(r.vkSc.swapchain == second);
    // The order: the generation context, the presents in flight, the swapchain's context, then the new one.
    REQUIRE(r.count("destroy fg") == 1);
    CHECK(r.index("wait") < r.index("destroy fg"));  // the presents in flight finish before the context goes
    CHECK(r.index("destroy fg") < r.index("destroy swapchain"));
    CHECK(r.index("destroy swapchain") < r.index("create swapchain"));

    // The engine then tells the hook the old one is going and calls the destroy function of the old swapchain: nothing happens to it.
    gpu::SwapchainEvent e;
    e.backend = gpu::Backend::Vulkan;
    e.vkSwapchain = first;
    r.hook->swapchain_destroying(e);
    CHECK(r.count("destroy swapchain") == 1);
    using DestroyFn = void (*)(const void*, void*, const void*);
    reinterpret_cast<DestroyFn>(r.vkSc.functions.destroySwapchain)(r.vkSc.device, reinterpret_cast<void*>(std::uintptr_t(first)), nullptr);
    CHECK(fk.vkDestroyCalls == 0);

    // The next frame makes the context again, with a reset.
    REQUIRE(r.fsr->start(r.dev, r.swapchain()).empty());
    r.frame.reset = false;
    REQUIRE(r.draw());
    CHECK(r.count("create fg") == 1);
    CHECK(fk.prepare.reset);
}

TEST_CASE("fsr frame generation hook, Vulkan: destroying the swapchain takes the contexts down in order and calls FidelityFX's destroy without a context") {
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
    using DestroyFn = void (*)(const void*, void*, const void*);
    reinterpret_cast<DestroyFn>(r.vkSc.functions.destroySwapchain)(r.vkSc.device, reinterpret_cast<void*>(std::uintptr_t(handle)), nullptr);
    CHECK(fk.vkDestroyCalls == 1);
    CHECK(fk.lastVkDestroy == reinterpret_cast<void*>(std::uintptr_t(handle)));
    CHECK(r.index("destroy swapchain") < r.index("vk destroy"));
}

TEST_CASE("fsr frame generation hook, Vulkan: a swapchain that is not FidelityFX's is replaced by the engine, a hook that cannot is an error") {
    Rig r(gpu::Backend::Vulkan);
    REQUIRE(r.arm(FrameGenMode::Fsr));
    r.vk_device();
    CHECK_FALSE(r.vk_swapchain(0x1234));  // the engine's own old swapchain: the engine makes the new one, FidelityFX is not asked
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
    fk.noSwapFn = false;
    CHECK(r.vk_swapchain());
}

TEST_CASE("fsr frame generation hook, Vulkan: a device that gave fewer than three queues cannot serve FidelityFX's swapchain") {
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

TEST_CASE("fsr frame generation: a frame makes the context once, configures it and prepares it inside a native section") {
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

TEST_CASE("fsr frame generation: a finite depth gives the planes of the camera, a pixel-unit motion scale multiplies the render size") {
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

TEST_CASE("fsr frame generation: the picture before the screen-space items goes to the swapchain only when the items were drawn") {
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
    CHECK(reinterpret_cast<Callback>(fk.configure.frameGenerationCallback)(&dispatchDesc, fk.configure.frameGenerationCallbackUserContext) ==
          abi::kUnknownDescType);
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

TEST_CASE("fsr frame generation: a reset is asked after the first frame, a camera cut, a failed frame and a change of the swapchain") {
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

TEST_CASE("fsr frame generation: a new output size or new flags make the context again, after the old one is taken down in order") {
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

TEST_CASE("fsr frame generation: stop turns generation off, waits, and destroys the context but leaves the swapchain presenting") {
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

TEST_CASE("fsr frame generation: the swapchain going away takes the contexts down, and the device after it has nothing left") {
    Rig r(gpu::Backend::D3d12);
    make_ready_dx12(r);
    REQUIRE(r.draw());
    fk.events.clear();
    gpu::SwapchainEvent e;
    e.backend = gpu::Backend::D3d12;
    e.swapchain = &fk.dxToken;
    r.hook->swapchain_destroying(e);
    REQUIRE(r.count("destroy fg") == 1);
    REQUIRE(r.count("destroy swapchain") == 1);
    CHECK(r.index("destroy fg") < r.index("destroy swapchain"));
    // The engine's release of the proxy is the last: no frame is drawn with a swapchain that is gone.
    CHECK_FALSE(r.draw());
    r.hook->device_destroying();
    CHECK(r.count("destroy fg") == 1);
    CHECK(r.count("destroy swapchain") == 1);
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

TEST_CASE("fsr frame generation: each FidelityFX call that fails is a refusal with the library's words, never a crash") {
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

TEST_CASE("fsr frame generation: a frame that lacks what FidelityFX needs, or a device of another backend, is refused with the reason") {
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
