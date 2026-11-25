// M78-P5b: the DLSS frame generation provider (src/render_framegen_dlss.{h,cpp}) on the Streamline runtime (src/streamline_runtime.{h,cpp}).
// No NVIDIA library is involved: Streamline's functions are fakes in a table the runtime takes from a fake VendorLibrary (the way it takes the
// real ones), the adapter and the COM releases are injected, and the device is a RecordingDevice that answers a backend, a GPU maker and native
// handles. What is tested is what the engine asks of Streamline and when: the refusals with their reasons (not installed, not started, the
// feature never asked for, a GPU or a driver DLSS-G does not run on, Reflex missing), the options sent once and again only when they change, the
// constants of a frame (the matrices Streamline reads, the shared frame token), the tags (depth, motion and the hudless picture only when there
// are items over it, the states the native section declares, the Vulkan views), the status bits turned into sentences, the generated-frame count
// read from the state, and that nothing is called after the device went. That the real driver generates frames is for a machine with an RTX 40.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <map>
#include <memory>
#include <span>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "gpu/device_hooks.h"
#include "gpu/recording_device.h"
#include "render_framegen.h"
#include "render_framegen_dlss.h"
#include "render_latency.h"
#include "render_latency_reflex.h"
#include "streamline_runtime.h"

using namespace fa;
using render::FrameGenFrame;
using render::FrameGenSettings;
using render::FrameGenSlot;
using render::GpuVendor;
using render::LatencyDriver;
using render::LatencyMode;
namespace sl = fa::render::sl_abi;
using SlR = sl::Result;

namespace {

// ---- the fake library ---------------------------------------------------------------------------------------------------------------

struct Gx {
    SlR initRc = 0, supportedRc = 0, tokenRc = 0, setOptionsRc = 0, getStateRc = 0, constantsRc = 0, tagRc = 0, reflexRc = 0;
    std::uint32_t refusedFeature = 0xFFFFFFFFu;  // the feature slIsFeatureSupported refuses (with supportedRc)
    // what slDLSSGGetState answers
    std::uint32_t status = 0, minSize = 64, presented = 1, maxFrames = 1;
    std::uint64_t vram = 256ull << 20;
    // what happened
    std::vector<std::string> events;
    std::vector<sl::DlssgOptions> options;
    std::vector<sl::ReflexOptions> reflexOptions;
    int stateCalls = 0, frees = 0, shutdowns = 0, constantsCalls = 0, tokenCalls = 0;
    sl::Constants constants{};
    void* constantsToken = nullptr;
    std::vector<sl::ResourceTag> tags;
    std::vector<sl::Resource> resources;
    void* tagToken = nullptr;
    void* tagList = nullptr;
    std::uint32_t tagFeatureFreed = 0xFFFFFFFFu;
    int tokenMarker = 0, deviceMarker = 0, proxyDevice = 0, factoryMarker = 0, proxyFactory = 0, adapterMarker = 0;
    int instanceMarker = 0, physicalMarker = 0, vkDeviceMarker = 0;
    void reset() { *this = Gx{}; }
};
Gx gx;
std::vector<std::string> g_hidden;  // the feature functions the plugin lacks

SlR f_init(const sl::Preferences*, std::uint64_t) {
    gx.events.push_back("init");
    return gx.initRc;
}
SlR f_shutdown() {
    ++gx.shutdowns;
    return 0;
}
SlR f_supported(std::uint32_t feature, const sl::AdapterInfo*) { return feature == gx.refusedFeature ? gx.supportedRc : 0; }
SlR f_free(std::uint32_t feature, const sl::ViewportHandle*) {
    gx.events.push_back("free");
    gx.tagFeatureFreed = feature;
    ++gx.frees;
    return 0;
}
SlR f_allocate(void*, std::uint32_t, const sl::ViewportHandle*) { return 0; }
SlR f_requirements(std::uint32_t, sl::FeatureRequirements* r) {
    r->flags = sl::kReqD3d12 | sl::kReqVulkan;
    return 0;
}
SlR f_evaluate(std::uint32_t, void*, const sl::Base* const*, std::uint32_t, void*) { return 0; }
SlR f_upgrade(void** p) {
    if (*p == &gx.deviceMarker) *p = &gx.proxyDevice;
    if (*p == &gx.factoryMarker) *p = &gx.proxyFactory;
    return 0;
}
SlR f_set_d3d(void*) { return 0; }
SlR f_set_vk(const sl::VulkanInfo*) { return 0; }
void marker_fn() {}
void* f_vk_proc(void*, const char* name) { return std::string(name) == "vkQueuePresentKHR" ? reinterpret_cast<void*>(&marker_fn) : nullptr; }
SlR f_token(void** token, const std::uint32_t*) {
    ++gx.tokenCalls;
    gx.events.push_back("token");
    if (gx.tokenRc != 0) return gx.tokenRc;
    *token = &gx.tokenMarker;
    return 0;
}
SlR f_constants(const sl::Constants* c, void* frame, const sl::ViewportHandle*) {
    gx.events.push_back("constants");
    ++gx.constantsCalls;
    gx.constants = *c;
    gx.constantsToken = frame;
    return gx.constantsRc;
}
SlR f_tag(void* frame, const sl::ViewportHandle*, const sl::ResourceTag* tags, std::uint32_t n, void* list) {
    gx.events.push_back("tag");
    gx.tagToken = frame;
    gx.tagList = list;
    gx.tags.assign(tags, tags + n);
    gx.resources.clear();
    for (std::uint32_t i = 0; i < n; ++i) gx.resources.push_back(*tags[i].resource);
    return gx.tagRc;
}
SlR f_dlssg_options(const sl::ViewportHandle*, const sl::DlssgOptions* o) {
    gx.events.push_back("setOptions");
    gx.options.push_back(*o);
    return gx.setOptionsRc;
}
SlR f_dlssg_state(const sl::ViewportHandle*, sl::DlssgState* s, const sl::DlssgOptions*) {
    gx.events.push_back("getState");
    ++gx.stateCalls;
    if (gx.getStateRc != 0) return gx.getStateRc;
    s->status = gx.status;
    s->minWidthOrHeight = gx.minSize;
    s->numFramesActuallyPresented = gx.presented;
    s->numFramesToGenerateMax = gx.maxFrames;
    s->estimatedVRAMUsageInBytes = gx.vram;
    return 0;
}
SlR f_reflex_options(const sl::ReflexOptions* o) {
    gx.reflexOptions.push_back(*o);
    return gx.reflexRc;
}
SlR f_reflex_state(sl::ReflexState* s) {
    s->lowLatencyAvailable = true;
    s->latencyReportAvailable = true;
    return 0;
}
SlR f_reflex_sleep(void*) { return 0; }
SlR f_pcl_marker(std::uint32_t, void*) { return 0; }
SlR f_function(std::uint32_t feature, const char* name, void** fn) {
    const std::string n = name;
    if (std::find(g_hidden.begin(), g_hidden.end(), n) != g_hidden.end()) return sl::kErrorFeatureMissing;
    if (n == "slDLSSGSetOptions" && feature == sl::kFeatureDlssG) *fn = reinterpret_cast<void*>(&f_dlssg_options);
    else if (n == "slDLSSGGetState" && feature == sl::kFeatureDlssG) *fn = reinterpret_cast<void*>(&f_dlssg_state);
    else if (n == "slReflexSetOptions" && feature == sl::kFeatureReflex) *fn = reinterpret_cast<void*>(&f_reflex_options);
    else if (n == "slReflexGetState" && feature == sl::kFeatureReflex) *fn = reinterpret_cast<void*>(&f_reflex_state);
    else if (n == "slReflexSleep" && feature == sl::kFeatureReflex) *fn = reinterpret_cast<void*>(&f_reflex_sleep);
    else if (n == "slPCLSetMarker" && feature == sl::kFeaturePcl) *fn = reinterpret_cast<void*>(&f_pcl_marker);
    else return sl::kErrorFeatureMissing;
    return 0;
}

class FakeLibrary final : public render::VendorLibrary {
public:
    FakeLibrary() {
        table_["slInit"] = reinterpret_cast<void*>(&f_init);
        table_["slShutdown"] = reinterpret_cast<void*>(&f_shutdown);
        table_["slIsFeatureSupported"] = reinterpret_cast<void*>(&f_supported);
        table_["slSetTagForFrame"] = reinterpret_cast<void*>(&f_tag);
        table_["slSetConstants"] = reinterpret_cast<void*>(&f_constants);
        table_["slGetFeatureRequirements"] = reinterpret_cast<void*>(&f_requirements);
        table_["slAllocateResources"] = reinterpret_cast<void*>(&f_allocate);
        table_["slFreeResources"] = reinterpret_cast<void*>(&f_free);
        table_["slEvaluateFeature"] = reinterpret_cast<void*>(&f_evaluate);
        table_["slUpgradeInterface"] = reinterpret_cast<void*>(&f_upgrade);
        table_["slGetFeatureFunction"] = reinterpret_cast<void*>(&f_function);
        table_["slGetNewFrameToken"] = reinterpret_cast<void*>(&f_token);
        table_["slSetD3DDevice"] = reinterpret_cast<void*>(&f_set_d3d);
        table_["slSetVulkanInfo"] = reinterpret_cast<void*>(&f_set_vk);
        table_["vkGetInstanceProcAddr"] = reinterpret_cast<void*>(&f_vk_proc);
        table_["vkGetDeviceProcAddr"] = reinterpret_cast<void*>(&f_vk_proc);
    }
    void* symbol(const char* name) override {
        const auto it = table_.find(name);
        return it == table_.end() ? nullptr : it->second;
    }
    const std::string& path() const override { return path_; }

private:
    std::map<std::string, void*> table_;
    std::string path_ = "fake/sl.interposer.dll";
};

class FakeLoader final : public render::VendorLoader {
public:
    bool installed = true;
    std::filesystem::path find(const render::VendorLibrarySpec& spec, std::string* why) override {
        if (!installed) {
            if (why) *why = "the fake loader has no library";
            return {};
        }
        return std::filesystem::path("fake") / spec.fileName;
    }
    std::unique_ptr<render::VendorLibrary> load(const std::filesystem::path&, std::string*) override {
        return std::make_unique<FakeLibrary>();
    }
};

struct LoaderGuard {
    explicit LoaderGuard(render::VendorLoader* l) { render::set_vendor_loader_for_test(l); }
    ~LoaderGuard() { render::set_vendor_loader_for_test(nullptr); }
    LoaderGuard(const LoaderGuard&) = delete;
    LoaderGuard& operator=(const LoaderGuard&) = delete;
};

struct AdapterFx {
    std::vector<void*> released;
};
render::StreamlineHost make_host(AdapterFx& a) {
    render::StreamlineHost h;
    h.readAdapter = [](const void*, render::StreamlineAdapter& out) {
        out.vendorId = 0x10DE;
        out.hasLuid = true;
        for (int i = 0; i < 8; ++i) out.luid[i] = std::uint8_t(i + 1);
        out.name = "Fake RTX 4090";
        return true;
    };
    h.releaseCom = [&a](void* o) { a.released.push_back(o); };
    return h;
}

std::vector<std::uint32_t> features_without_dlssg() { return {sl::kFeatureDlss, sl::kFeatureReflex, sl::kFeaturePcl}; }
std::vector<std::uint32_t> features_with_dlssg() {
    return {sl::kFeatureDlss, sl::kFeatureReflex, sl::kFeaturePcl, sl::kFeatureDlssG};
}

void run_d3d12(render::StreamlineRuntime& rt) {
    gpu::D3d12BeforeDevice before;
    before.factory = &gx.factoryMarker;
    before.adapter = &gx.adapterMarker;
    rt.d3d12_before_device(before);
    gpu::D3d12DeviceCreated c;
    c.factory = &gx.factoryMarker;
    c.device = &gx.deviceMarker;
    c.adapter = &gx.adapterMarker;
    rt.d3d12_device_created(c);
}

void run_vulkan(render::StreamlineRuntime& rt) {
    gpu::VulkanInstanceRequest ir;
    gpu::VulkanDeviceRequest dr;
    rt.vulkan_instance_request(ir);
    rt.vulkan_instance_created(&gx.instanceMarker, nullptr);
    gpu::VulkanPhysicalDevice pd;
    pd.instance = &gx.instanceMarker;
    pd.physicalDevice = &gx.physicalMarker;
    pd.vendorId = 0x10DE;
    pd.name = "Fake RTX 4090";
    rt.vulkan_device_request(pd, dr);
    gpu::VulkanDeviceCreated dc;
    dc.native.device = &gx.vkDeviceMarker;
    dc.native.instance = &gx.instanceMarker;
    dc.native.physicalDevice = &gx.physicalMarker;
    std::uint32_t next = 0;
    for (const gpu::VulkanQueueRequest& q : dr.queues)
        for (std::uint32_t i = 0; i < q.count; ++i) {
            gpu::VulkanQueueGrant g;
            g.family = 5 + next;
            g.index = 1 + next;
            dc.queues.push_back(g);
            ++next;
        }
    rt.vulkan_device_created(dc);
}

// ---- the fake device and command list -----------------------------------------------------------------------------------------------

class GDevice : public gpu::RecordingDevice {
public:
    explicit GDevice(gpu::Backend deviceBackend, std::uint32_t pciVendor = 0x10DE) : backend_(deviceBackend) {
        info_ = gpu::RecordingDevice::info();
        info_.backend = deviceBackend;
        info_.gpu.vendorId = pciVendor;
        info_.gpu.vendor = gpu::gpu_vendor_from_pci(pciVendor);
    }
    gpu::Backend backend() const override { return backend_; }
    const gpu::DeviceInfo& info() const override { return info_; }
    gpu::NativeImage native_image(gpu::Image img) const override {
        gpu::NativeImage n;
        if (!img.valid()) return n;
        n.resource = reinterpret_cast<const void*>(std::uintptr_t(img.id) * 16);
        n.vkImage = std::uint64_t(img.id) * 16;
        n.nativeFormat = 41;  // DXGI_FORMAT_R32_FLOAT
        n.vkUsage = 0x1B;
        return n;
    }
    gpu::NativeView native_view(gpu::View v) const override {
        gpu::NativeView n;
        if (!v.valid()) return n;
        n.vkImageView = std::uint64_t(v.id) * 256;
        n.nativeFormat = 100;  // VK_FORMAT_R32_SFLOAT
        n.mipCount = 1;
        n.sliceCount = 1;
        return n;
    }
    fa::Result<void> wait_idle() override {
        ++idles;
        gx.events.push_back("idle");
        return {};
    }
    int idles = 0;

    gpu::Image image(int w, int h, gpu::PixelFormat format) {
        gpu::ImageDesc d;
        d.width = w;
        d.height = h;
        d.pixelFormat = format;
        d.label = "dlssg-test";
        return make_image(d);
    }

private:
    gpu::Backend backend_;
    gpu::DeviceInfo info_{};
};

class GList final : public gpu::RecordingCommandList {
public:
    GList(GDevice& device, gpu::Backend backend) : gpu::RecordingCommandList(device), backend_(backend) {}
    fa::Result<gpu::NativeCommands> begin_native(std::span<const gpu::NativeUse> uses) override {
        gx.events.push_back("begin");
        if (failBegin) return make_error("the fake list refuses a native section", "none");
        declared.assign(uses.begin(), uses.end());
        gpu::NativeCommands n;
        n.backend = backend_;
        n.list = &token;
        return n;
    }
    fa::Result<void> end_native(std::span<const gpu::NativeUse>) override {
        gx.events.push_back("end");
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

// Reflex of the test: the real provider on the fake Streamline, as the renderer's latency controller runs it.
struct ReflexOn {
    std::unique_ptr<render::LatencyProvider> reflex = render::make_reflex_provider();
    gpu::Device* started = nullptr;
    void start(gpu::Device& dev) {
        REQUIRE(reflex->start(dev).empty());
        started = &dev;
        reflex->configure(true, false, 0);
    }
    ~ReflexOn() {
        if (started) reflex->stop(*started);
    }
};

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

// One frame's worth of everything: a runtime made ready on a D3D12 or Vulkan device, a device, a list, the images and the provider under test
// (its own instance, not the process's).
struct Rig {
    FakeLoader loader;
    LoaderGuard guard{&loader};
    AdapterFx adapter;
    render::StreamlineRuntime runtime;
    GDevice dev;
    GList list;
    std::unique_ptr<render::FrameGenProvider> dlssg = render::make_dlss_framegen_provider();
    ReflexOn reflex;
    gpu::Image depth, motion, hudless, presented;
    int renderW = 160, renderH = 90, outW = 320, outH = 180;
    gpu::Backend backend;

    Rig(gpu::Backend b, bool ready = true, std::vector<std::uint32_t> features = features_with_dlssg())
        : runtime(std::move(features), make_host(adapter)), dev(b), list(dev, b), backend(b) {
        gx.reset();
        g_hidden.clear();
        render::set_streamline_runtime_for_test(&runtime);
        if (ready) {
            if (b == gpu::Backend::Vulkan) run_vulkan(runtime);
            else run_d3d12(runtime);
            REQUIRE(runtime.status().ready);
        }
        depth = dev.image(renderW, renderH, gpu::PixelFormat::R32F);
        motion = dev.image(renderW, renderH, gpu::PixelFormat::Rg16F);
        hudless = dev.image(outW, outH, gpu::PixelFormat::Rgba8);
        presented = dev.image(outW, outH, gpu::PixelFormat::Rgba8);
        gx.events.clear();
    }
    ~Rig() {
        dlssg->stop(dev);
        reflex.reflex->stop(dev);
        reflex.started = nullptr;
        render::set_streamline_runtime_for_test(nullptr);
        g_hidden.clear();
    }
    Rig(const Rig&) = delete;
    Rig& operator=(const Rig&) = delete;

    render::VendorEnv env(GpuVendor vendor = GpuVendor::Nvidia, bool windows = true) const {
        render::VendorEnv e;
        e.backend = dev.backend();
        e.vendor = vendor;
        e.device = &dev;
        e.windows = windows;
        return e;
    }
    render::FrameGenSwapchain swapchain() const {
        render::FrameGenSwapchain s;
        s.backend = dev.backend();
        s.width = outW;
        s.height = outH;
        return s;
    }
    // Starts the provider on the device with Reflex on, as the renderer does, and forgets what that sent.
    void start_all() {
        reflex.start(dev);
        REQUIRE(dlssg->start(dev, swapchain()).empty());
        gx.events.clear();
        gx.options.clear();
    }
    // A perspective frame of a camera that did not move: the previous clip position of a point is its clip position.
    FrameGenFrame frame() {
        FrameGenFrame f;
        f.device = &dev;
        f.list = &list;
        f.hudless = hudless;
        f.presented = presented;
        f.depth = depth;
        f.motion = motion;
        f.depthReversed = true;
        f.depthInfinite = true;
        f.renderW = renderW;
        f.renderH = renderH;
        f.outW = outW;
        f.outH = outH;
        const float tanHalf = std::tan(0.5f * 1.0f);
        f.proj[0] = 1.0f / (tanHalf * float(renderW) / float(renderH));
        f.proj[1] = 1.0f / tanHalf;
        f.proj[6] = -1.0f;  // P32: w = -z
        f.cameraNear = 0.1f;
        f.cameraFar = 1000.0f;
        f.cameraFovY = 1.0f;
        f.jitterX = 0.25f;
        f.jitterY = -0.125f;
        // The standard depth row of the engine's projection (the provider replaces it with the one of the reversed depth it asked for).
        Mat4 p;
        for (float& v : p.m) v = 0.0f;
        p.at(0, 0) = f.proj[0];
        p.at(1, 1) = f.proj[1];
        p.at(2, 2) = -1.0f;
        p.at(3, 2) = -0.2f;
        p.at(2, 3) = -1.0f;
        f.prevFromView = p;
        f.cameraPosition = Vec3{1, 2, 3};
        return f;
    }
};

}  // namespace

// ---- the slot and the ABI ----------------------------------------------------------------------------------------------------------

TEST_CASE("dlss frame generation: the build's provider fills the DLSS slot, and the ABI is the size Streamline 2.14.16 has") {
    render::FrameGenProvider* p = render::framegen_provider(FrameGenSlot::Dlss);
    REQUIRE(p != nullptr);
    CHECK(p->name() == "DLSS frame generation");
    CHECK(p->slot() == FrameGenSlot::Dlss);
    CHECK(p->setup_id() == "streamline");
    CHECK(p->backends() == ((1u << unsigned(gpu::Backend::D3d12)) | (1u << unsigned(gpu::Backend::Vulkan))));
    CHECK(p->wants_reversed_depth());
    CHECK(p->requires_reflex());
    CHECK(sizeof(sl::DlssgOptions) == 120);
    CHECK(sizeof(sl::DlssgState) == 88);
    sl::DlssgOptions o;
    sl::init_dlssg_options(o);
    CHECK(o.mode == sl::kDlssgOff);
    CHECK(o.numFramesToGenerate == 1);
    CHECK(o.bReserved15 == sl::kInvalid);
}

// ---- probe -----------------------------------------------------------------------------------------------------------------------------

TEST_CASE("dlss frame generation probe: usable on an NVIDIA GPU with Streamline started with the feature") {
    Rig r(gpu::Backend::D3d12);
    const render::VendorProbe p = r.dlssg->probe(r.env());
    CHECK(p.available);
    CHECK(p.reason.empty());
}

TEST_CASE("dlss frame generation probe: every refusal says what to do") {
    SUBCASE("another GPU maker") {
        Rig r(gpu::Backend::D3d12);
        const render::VendorProbe p = r.dlssg->probe(r.env(GpuVendor::Amd));
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "RTX 40"));
        CHECK(has(p.reason, "auto"));
    }
    SUBCASE("not Windows") {
        Rig r(gpu::Backend::D3d12);
        const render::VendorProbe p = r.dlssg->probe(r.env(GpuVendor::Nvidia, false));
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "Windows"));
    }
    SUBCASE("Direct3D 11") {
        Rig r(gpu::Backend::D3d11, false);
        const render::VendorProbe p = r.dlssg->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "D3D11"));
    }
    SUBCASE("Streamline is not installed") {
        Rig r(gpu::Backend::D3d12, false);
        r.loader.installed = false;
        const render::VendorProbe p = r.dlssg->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "factoria setup streamline"));
        CHECK_FALSE(has(p.reason, "arrives with"));
    }
    SUBCASE("Streamline is installed but never started") {
        Rig r(gpu::Backend::D3d12, false);
        const render::VendorProbe p = r.dlssg->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "restart"));
    }
    SUBCASE("the feature was not in the list the device was made with") {
        Rig r(gpu::Backend::D3d12, true, features_without_dlssg());
        const render::VendorProbe p = r.dlssg->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "render.frameGeneration.mode"));
        CHECK(has(p.reason, "restart"));
    }
    SUBCASE("the GPU or the driver cannot run DLSS-G") {
        Rig r(gpu::Backend::D3d12, false);
        gx.supportedRc = sl::kErrorDriverOutOfDate;
        gx.refusedFeature = sl::kFeatureDlssG;
        run_d3d12(r.runtime);
        const render::VendorProbe p = r.dlssg->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "RTX 40"));
        CHECK(has(p.reason, "Hardware-accelerated GPU scheduling"));
        CHECK(has(p.reason, "driver"));
    }
    SUBCASE("Reflex is not available") {
        Rig r(gpu::Backend::D3d12, false);
        gx.supportedRc = sl::kErrorDriverOutOfDate;
        gx.refusedFeature = sl::kFeatureReflex;
        run_d3d12(r.runtime);
        const render::VendorProbe p = r.dlssg->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "Reflex"));
    }
    SUBCASE("the PC latency markers are not available") {
        Rig r(gpu::Backend::D3d12, false);
        gx.supportedRc = sl::kErrorDriverOutOfDate;
        gx.refusedFeature = sl::kFeaturePcl;
        run_d3d12(r.runtime);
        const render::VendorProbe p = r.dlssg->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "PCL"));
    }
    SUBCASE("the plugin lacks a function") {
        Rig r(gpu::Backend::D3d12);
        g_hidden = {"slDLSSGGetState"};
        const render::VendorProbe p = r.dlssg->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "slDLSSGGetState"));
    }
}

TEST_CASE("dlss frame generation: asking for frame generation adds DLSS-G to the features Streamline loads") {
    Rig r(gpu::Backend::D3d12, false, features_without_dlssg());
    CHECK(r.dlssg->device_hook() == nullptr);  // the process's runtime is the hook; the provider only adds the feature
    run_d3d12(r.runtime);
    CHECK(r.runtime.feature_asked(sl::kFeatureDlssG));
    CHECK(r.dlssg->probe(r.env()).available);
}

// ---- start, configure, stop ----------------------------------------------------------------------------------------------------------

TEST_CASE("dlss frame generation: start sends the options off once and reads the state; configure sends on and off only on a change") {
    Rig r(gpu::Backend::D3d12);
    r.reflex.start(r.dev);
    gx.events.clear();
    REQUIRE(r.dlssg->start(r.dev, r.swapchain()).empty());
    REQUIRE(gx.options.size() == 1);
    CHECK(gx.options[0].mode == sl::kDlssgOff);
    CHECK(gx.options[0].numFramesToGenerate == 1);
    CHECK((gx.options[0].flags & sl::kDlssgRetainResourcesWhenOff) != 0);
    CHECK(gx.options[0].colorWidth == std::uint32_t(r.outW));
    CHECK(gx.options[0].colorHeight == std::uint32_t(r.outH));
    CHECK(gx.stateCalls == 1);
    // the options come before the state: slDLSSGSetOptions has to run once before slDLSSGGetState works
    CHECK(gx.events.size() >= 2);
    CHECK(gx.events.front() == "setOptions");

    r.dlssg->configure(true);
    REQUIRE(gx.options.size() == 2);
    CHECK(gx.options[1].mode == sl::kDlssgOn);
    r.dlssg->configure(true);  // the same: nothing
    CHECK(gx.options.size() == 2);
    r.dlssg->configure(false);
    REQUIRE(gx.options.size() == 3);
    CHECK(gx.options[2].mode == sl::kDlssgOff);
    CHECK((gx.options[2].flags & sl::kDlssgRetainResourcesWhenOff) != 0);  // a pause keeps the resources
}

TEST_CASE("dlss frame generation: start refuses with the reason when Streamline says no") {
    SUBCASE("the options are refused") {
        Rig r(gpu::Backend::D3d12);
        gx.setOptionsRc = sl::kErrorDriverOutOfDate;
        const std::string why = r.dlssg->start(r.dev, r.swapchain());
        CHECK(has(why, "slDLSSGSetOptions"));
    }
    SUBCASE("the state is refused") {
        Rig r(gpu::Backend::D3d12);
        gx.getStateRc = sl::kErrorDriverOutOfDate;
        const std::string why = r.dlssg->start(r.dev, r.swapchain());
        CHECK(has(why, "slDLSSGGetState"));
    }
    SUBCASE("DLSS-G was never asked for") {
        Rig r(gpu::Backend::D3d12, true, features_without_dlssg());
        const std::string why = r.dlssg->start(r.dev, r.swapchain());
        CHECK(has(why, "restart"));
    }
    SUBCASE("a device of another backend") {
        Rig r(gpu::Backend::D3d12);
        GDevice vk(gpu::Backend::Vulkan);
        const std::string why = r.dlssg->start(vk, r.swapchain());
        CHECK_FALSE(why.empty());
    }
}

TEST_CASE("dlss frame generation: stop turns generation off, gives the resources back and then calls nothing") {
    Rig r(gpu::Backend::D3d12);
    r.start_all();
    r.dlssg->configure(true);
    gx.events.clear();
    gx.options.clear();
    r.dlssg->stop(r.dev);
    CHECK(r.dev.idles == 1);
    REQUIRE(gx.options.size() == 1);
    CHECK(gx.options[0].mode == sl::kDlssgOff);
    CHECK((gx.options[0].flags & sl::kDlssgRetainResourcesWhenOff) == 0);
    CHECK(gx.frees == 1);
    CHECK(gx.tagFeatureFreed == sl::kFeatureDlssG);
    const std::size_t calls = gx.events.size();
    r.dlssg->stop(r.dev);  // already stopped
    r.dlssg->configure(true);
    CHECK(r.dlssg->generated_frames() == 0);
    CHECK(gx.events.size() == calls);
}

TEST_CASE("dlss frame generation: nothing is called into a Streamline that went with its device") {
    Rig r(gpu::Backend::D3d12);
    r.start_all();
    r.dlssg->configure(true);
    r.runtime.device_destroying();
    gx.events.clear();
    r.dlssg->configure(false);
    CHECK(r.dlssg->generated_frames() == 0);
    FrameGenFrame f = r.frame();
    CHECK_FALSE(r.dlssg->dispatch(f));
    CHECK_FALSE(f.error.empty());
    r.dlssg->stop(r.dev);
    CHECK(gx.events.empty());
}

// ---- the frame ---------------------------------------------------------------------------------------------------------------------------

TEST_CASE("dlss frame generation: a frame sends the constants and the tags with the one token of the frame") {
    Rig r(gpu::Backend::D3d12);
    r.start_all();
    r.dlssg->configure(true);
    gx.events.clear();
    FrameGenFrame f = r.frame();
    f.reset = true;
    REQUIRE_MESSAGE(r.dlssg->dispatch(f), f.error);

    std::string why;
    void* const token = r.runtime.frame_token(nullptr, &why);
    REQUIRE(token != nullptr);
    CHECK(gx.constantsToken == token);  // the token Reflex's markers and the upscaler's evaluation use
    CHECK(gx.tagToken == token);
    // constants, then the native section with the tags
    const auto at = [](const char* name) {
        return std::find(gx.events.begin(), gx.events.end(), name) - gx.events.begin();
    };
    CHECK(at("constants") < at("begin"));
    CHECK(at("begin") < at("tag"));
    CHECK(at("tag") < at("end"));
    CHECK(r.list.ends == 1);
    CHECK(gx.tagList == &r.list.token);

    const sl::Constants& c = gx.constants;
    CHECK(c.reset == sl::kTrue);
    CHECK(c.depthInverted == sl::kTrue);
    CHECK(c.cameraMotionIncluded == sl::kTrue);
    CHECK(c.orthographicProjection == sl::kFalse);
    CHECK(c.motionVectorsJittered == sl::kFalse);
    CHECK(c.mvecScale.x == 1.0f);
    CHECK(c.mvecScale.y == 1.0f);
    CHECK(c.jitterOffset.x == doctest::Approx(0.25f));
    CHECK(c.jitterOffset.y == doctest::Approx(-0.125f));
    CHECK(c.cameraNear == doctest::Approx(0.1f));
    CHECK(c.cameraPos.x == 1.0f);
    CHECK(c.cameraPos.z == 3.0f);
    CHECK(c.cameraAspectRatio == doctest::Approx(160.0f / 90.0f));
    // The matrices are Streamline's: row-major with row vectors, so a column-vector projection arrives transposed. The reversed infinite depth
    // has the clip z row [0, 0, 0, near]; w = -z is the last column of the engine's matrix and the third row's w here.
    CHECK(c.cameraViewToClip.row[0].x == doctest::Approx(f.proj[0]));
    CHECK(c.cameraViewToClip.row[1].y == doctest::Approx(f.proj[1]));
    CHECK(c.cameraViewToClip.row[2].w == doctest::Approx(-1.0f));
    CHECK(c.cameraViewToClip.row[3].z == doctest::Approx(0.1f));
    CHECK(c.cameraViewToClip.row[2].z == doctest::Approx(0.0f));
    // A camera that did not move: previous clip position = clip position, with the depth row of the tagged depth.
    for (int row = 0; row < 4; ++row) {
        const float* cp = &c.clipToPrevClip.row[row].x;
        const float* pc = &c.prevClipToClip.row[row].x;
        for (int col = 0; col < 4; ++col) {
            CHECK(cp[col] == doctest::Approx(row == col ? 1.0f : 0.0f).epsilon(1e-3));
            CHECK(pc[col] == doctest::Approx(row == col ? 1.0f : 0.0f).epsilon(1e-3));
        }
    }
}

TEST_CASE("dlss frame generation: the depth and the motion are tagged always, the hudless picture only with items over it") {
    Rig r(gpu::Backend::D3d12);
    r.start_all();
    r.dlssg->configure(true);
    SUBCASE("no screen-space items") {
        FrameGenFrame f = r.frame();
        f.hudDrawn = false;
        REQUIRE_MESSAGE(r.dlssg->dispatch(f), f.error);
        REQUIRE(gx.tags.size() == 2);
        CHECK(gx.tags[0].type == sl::kBufferDepth);
        CHECK(gx.tags[1].type == sl::kBufferMotionVectors);
        CHECK(r.list.declared.size() == 2);
    }
    SUBCASE("items drawn") {
        FrameGenFrame f = r.frame();
        f.hudDrawn = true;
        REQUIRE_MESSAGE(r.dlssg->dispatch(f), f.error);
        REQUIRE(gx.tags.size() == 3);
        CHECK(gx.tags[2].type == sl::kBufferHudLessColor);
        CHECK(gx.resources[2].width == std::uint32_t(r.outW));
        CHECK(gx.resources[2].height == std::uint32_t(r.outH));
        CHECK(gx.tags[2].extent.width == std::uint32_t(r.outW));
        REQUIRE(r.list.declared.size() == 3);
        CHECK(r.list.declared[2].image == r.hudless);
    }
    // what every tag says
    FrameGenFrame f = r.frame();
    f.hudDrawn = true;
    REQUIRE(r.dlssg->dispatch(f));
    for (std::size_t i = 0; i < gx.tags.size(); ++i) {
        CAPTURE(i);
        CHECK(gx.tags[i].lifecycle == sl::kValidUntilPresent);  // read inside Present, after the frame's own passes
        CHECK(gx.resources[i].state == 0xC0);                   // pixel + non-pixel shader resource
        CHECK(gx.resources[i].native != nullptr);
        CHECK(gx.resources[i].nativeFormat == 41);
        CHECK(r.list.declared[i].state == gpu::NativeState::ShaderRead);
    }
    CHECK(gx.resources[0].width == std::uint32_t(r.renderW));
    CHECK(gx.resources[1].height == std::uint32_t(r.renderH));
    CHECK(gx.tags[0].extent.width == std::uint32_t(r.renderW));
    CHECK(r.list.declared[0].image == r.depth);
    CHECK(r.list.declared[1].image == r.motion);
}

TEST_CASE("dlss frame generation: the options follow the picture's size, sent again only when it changes") {
    Rig r(gpu::Backend::D3d12);
    r.start_all();
    r.dlssg->configure(true);
    FrameGenFrame f = r.frame();
    REQUIRE(r.dlssg->dispatch(f));
    REQUIRE_FALSE(gx.options.empty());
    CHECK(gx.options.back().mode == sl::kDlssgOn);
    CHECK(gx.options.back().mvecDepthWidth == std::uint32_t(r.renderW));
    CHECK(gx.options.back().mvecDepthHeight == std::uint32_t(r.renderH));
    CHECK(gx.options.back().colorWidth == std::uint32_t(r.outW));
    const std::size_t n = gx.options.size();
    FrameGenFrame again = r.frame();
    REQUIRE(r.dlssg->dispatch(again));
    CHECK(gx.options.size() == n);  // nothing changed
    FrameGenFrame bigger = r.frame();
    bigger.renderW = 200;
    bigger.renderH = 112;
    r.depth = r.dev.image(200, 112, gpu::PixelFormat::R32F);
    bigger.depth = r.depth;
    REQUIRE(r.dlssg->dispatch(bigger));
    REQUIRE(gx.options.size() == n + 1);
    CHECK(gx.options.back().mvecDepthWidth == 200);
}

TEST_CASE("dlss frame generation: a frame it cannot use is refused with a sentence that says what to do") {
    Rig r(gpu::Backend::D3d12);
    r.start_all();
    r.dlssg->configure(true);
    SUBCASE("an orthographic camera") {
        FrameGenFrame f = r.frame();
        f.cameraPerspective = false;
        CHECK_FALSE(r.dlssg->dispatch(f));
        CHECK(has(f.error, "perspective"));
        CHECK(gx.constantsCalls == 0);
    }
    SUBCASE("a depth that is not the reversed one") {
        FrameGenFrame f = r.frame();
        f.depthReversed = false;
        CHECK_FALSE(r.dlssg->dispatch(f));
        CHECK(has(f.error, "reversed"));
    }
    SUBCASE("no depth or motion image") {
        FrameGenFrame f = r.frame();
        f.motion = gpu::Image{};
        CHECK_FALSE(r.dlssg->dispatch(f));
        CHECK(has(f.error, "motion"));
    }
    SUBCASE("a projection that is not a number") {
        FrameGenFrame f = r.frame();
        f.proj[1] = std::nanf("");
        CHECK_FALSE(r.dlssg->dispatch(f));
        CHECK(has(f.error, "projection"));
        CHECK(gx.constantsCalls == 0);
    }
    SUBCASE("a frame with no token") {
        gx.tokenRc = sl::kErrorNoPlugins;
        FrameGenFrame f = r.frame();
        CHECK_FALSE(r.dlssg->dispatch(f));
        CHECK_FALSE(f.error.empty());
        CHECK(gx.constantsCalls == 0);
    }
    SUBCASE("Streamline refuses the constants") {
        gx.constantsRc = sl::kErrorDriverOutOfDate;
        FrameGenFrame f = r.frame();
        CHECK_FALSE(r.dlssg->dispatch(f));
        CHECK(has(f.error, "slSetConstants"));
        CHECK(gx.tags.empty());
    }
    SUBCASE("Streamline refuses the tags: the native section is still closed") {
        gx.tagRc = sl::kErrorDriverOutOfDate;
        FrameGenFrame f = r.frame();
        CHECK_FALSE(r.dlssg->dispatch(f));
        CHECK(has(f.error, "slSetTagForFrame"));
        CHECK(r.list.ends == 1);
    }
    SUBCASE("the list cannot open a native section") {
        r.list.failBegin = true;
        FrameGenFrame f = r.frame();
        CHECK_FALSE(r.dlssg->dispatch(f));
        CHECK(has(f.error, "native"));
        CHECK(gx.tags.empty());
    }
    SUBCASE("a duplicate set of constants is not fatal: the frame the upscaler set them for still generates") {
        gx.constantsRc = sl::kErrorDuplicatedConstants;
        FrameGenFrame f = r.frame();
        CHECK(r.dlssg->dispatch(f));
        CHECK(gx.tags.size() == 2);
    }
}

TEST_CASE("dlss frame generation: a frame is refused while Reflex is not running") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.dlssg->start(r.dev, r.swapchain()).empty());  // Reflex never started
    r.dlssg->configure(true);
    FrameGenFrame f = r.frame();
    CHECK_FALSE(r.dlssg->dispatch(f));
    CHECK(has(f.error, "Reflex"));
    r.reflex.start(r.dev);
    FrameGenFrame again = r.frame();
    CHECK(r.dlssg->dispatch(again));
}

TEST_CASE("dlss frame generation: the status Streamline reports becomes the reason, once per cause, after the frame went out") {
    Rig r(gpu::Backend::D3d12);
    r.start_all();
    r.dlssg->configure(true);
    const auto refused = [&r](std::uint32_t status) {
        gx.status = status;
        (void)r.dlssg->generated_frames();  // the controller reads it once per rendered frame
        FrameGenFrame f = r.frame();
        const bool ok = r.dlssg->dispatch(f);
        return std::make_pair(ok, f.error);
    };
    const auto none = refused(0);
    CHECK(none.first);
    const auto low = refused(sl::kDlssgFailResolutionTooLow);
    CHECK_FALSE(low.first);
    CHECK(has(low.second, "smaller than the SDK allows"));
    CHECK(has(low.second, "64"));
    CHECK(gx.tags.size() == 2);  // the inputs went out: the next present can recover
    const auto reflex = refused(sl::kDlssgFailReflexNotDetectedAtRuntime);
    CHECK(has(reflex.second, "Reflex"));
    const auto hdr = refused(sl::kDlssgFailHdrFormatNotSupported);
    CHECK(has(hdr.second, "HDR"));
    const auto bad = refused(sl::kDlssgFailCommonConstantsInvalid);
    CHECK(has(bad.second, "constants"));
    const auto index = refused(sl::kDlssgFailGetCurrentBackBufferIndexNotCalled);
    CHECK(has(index.second, "report it"));
    CHECK(refused(0).first);  // and it recovers
}

TEST_CASE("dlss frame generation: a status read while generation was off is not held against the frame") {
    Rig r(gpu::Backend::D3d12);
    r.start_all();
    gx.status = sl::kDlssgFailReflexNotDetectedAtRuntime;  // what an off period reports
    (void)r.dlssg->generated_frames();
    r.dlssg->configure(true);
    FrameGenFrame f = r.frame();
    CHECK(r.dlssg->dispatch(f));
}

// ---- the readout -----------------------------------------------------------------------------------------------------------------------

TEST_CASE("dlss frame generation: the generated frames are what Streamline presented besides the rendered one") {
    Rig r(gpu::Backend::D3d12);
    r.start_all();
    r.dlssg->configure(true);
    gx.presented = 2;  // one rendered, one generated
    CHECK(r.dlssg->generated_frames() == 1);
    CHECK(r.dlssg->generated_frames() == 2);
    gx.presented = 1;  // only the rendered one (paused)
    CHECK(r.dlssg->generated_frames() == 2);
    gx.presented = 0;
    CHECK(r.dlssg->generated_frames() == 2);
    gx.presented = 4;  // frames the loop did not read between
    CHECK(r.dlssg->generated_frames() == 5);
    gx.getStateRc = sl::kErrorDriverOutOfDate;  // a refusal keeps the count and does not throw
    CHECK(r.dlssg->generated_frames() == 5);
    CHECK(gx.stateCalls >= 7);
}

TEST_CASE("dlss frame generation: a swapchain made again sends the new size") {
    Rig r(gpu::Backend::D3d12);
    r.start_all();
    r.dlssg->configure(true);
    FrameGenFrame f = r.frame();
    REQUIRE(r.dlssg->dispatch(f));
    gx.options.clear();
    render::FrameGenSwapchain sc = r.swapchain();
    sc.width = 640;
    sc.height = 360;
    r.dlssg->swapchain_changed(r.dev, sc);
    REQUIRE(gx.options.size() == 1);
    CHECK(gx.options[0].colorWidth == 640);
    CHECK(gx.options[0].colorHeight == 360);
    CHECK(gx.options[0].mode == sl::kDlssgOn);
    // Another device's swapchain is not ours.
    GDevice other(gpu::Backend::D3d12);
    r.dlssg->swapchain_changed(other, sc);
    CHECK(gx.options.size() == 1);
}

// ---- Vulkan ------------------------------------------------------------------------------------------------------------------------------

TEST_CASE("dlss frame generation on Vulkan: the tags carry the image, its sampled view and the shader-read layout") {
    Rig r(gpu::Backend::Vulkan);
    r.start_all();
    r.dlssg->configure(true);
    FrameGenFrame f = r.frame();
    f.hudDrawn = true;
    REQUIRE_MESSAGE(r.dlssg->dispatch(f), f.error);
    REQUIRE(gx.resources.size() == 3);
    for (const sl::Resource& res : gx.resources) {
        CHECK(res.native != nullptr);
        CHECK(res.view != nullptr);
        CHECK(res.state == 5);  // VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
        CHECK(res.usage == 0x1B);
        CHECK(res.nativeFormat == 100);
        CHECK(res.mipLevels == 1);
    }
    CHECK(gx.resources[0].native == reinterpret_cast<void*>(std::uintptr_t(r.depth.id) * 16));
    const void* firstView = gx.resources[0].view;
    // The views are made once per image, not once per frame.
    FrameGenFrame again = r.frame();
    again.hudDrawn = true;
    REQUIRE(r.dlssg->dispatch(again));
    CHECK(gx.resources[0].view == firstView);
    r.dlssg->stop(r.dev);
}

// ---- the renderer's side ---------------------------------------------------------------------------------------------------------------

TEST_CASE("dlss frame generation through the controller: Reflex is required while it runs, and generation follows the base rate") {
    Rig r(gpu::Backend::D3d12);
    render::FrameGenController c;
    render::set_framegen_provider_for_test(FrameGenSlot::Dlss, r.dlssg.get());
    struct Reset {
        ~Reset() { render::set_framegen_provider_for_test(FrameGenSlot::Dlss, nullptr); }
    } resetProvider;
    CHECK_FALSE(c.requires_reflex());
    c.attach(&r.dev, r.env(), r.swapchain(), true);
    FrameGenSettings s;
    s.mode = render::FrameGenMode::Dlss;
    s.minBaseFps = 0;
    c.set_settings(s);
    REQUIRE_MESSAGE(c.state() != render::FrameGenState::Refused, c.reason());
    CHECK(c.provider() == FrameGenSlot::Dlss);
    CHECK(c.requires_reflex());
    CHECK(c.wants_reversed_depth());
    r.reflex.start(r.dev);  // what Renderer::Impl::sync_reflex_for_framegen makes of requires_reflex
    double t = 1000.0;
    for (int i = 0; i < 3; ++i) {
        t += 10.0;
        c.begin_frame(t);
    }
    CHECK(c.wants_dispatch());
    CHECK(gx.options.back().mode == sl::kDlssgOn);
    FrameGenFrame f = r.frame();
    CHECK(c.dispatch(f));
    CHECK(f.reset);  // the first frame has no history
    CHECK(gx.constantsCalls == 1);
    c.set_settings(FrameGenSettings{});  // off
    CHECK_FALSE(c.requires_reflex());
    CHECK(gx.frees == 1);
    c.detach();
}

TEST_CASE("latency controller: a feature that needs Reflex turns it on whatever the player's mode, and gives it back") {
    Rig r(gpu::Backend::D3d12);
    render::LatencyController c;
    c.attach(&r.dev, r.env(), true);
    c.set_settings(render::LatencySettings{});  // off
    CHECK(c.driver() == LatencyDriver::None);
    CHECK_FALSE(render::reflex_running());
    c.require_reflex(true);
    CHECK(c.driver() == LatencyDriver::Reflex);
    CHECK(c.reflex_forced());
    CHECK(render::reflex_running());
    REQUIRE_FALSE(gx.reflexOptions.empty());
    CHECK(gx.reflexOptions.back().mode == sl::kReflexLowLatency);
    CHECK(c.settings().mode == LatencyMode::Off);  // the player's setting itself is not changed
    c.require_reflex(false);
    CHECK(c.driver() == LatencyDriver::None);
    CHECK_FALSE(c.reflex_forced());
    CHECK_FALSE(render::reflex_running());
    // a player who chose Reflex keeps their own boost, and nothing is "forced"
    render::LatencySettings boost;
    boost.mode = LatencyMode::Reflex;
    boost.boost = true;
    c.set_settings(boost);
    c.require_reflex(true);
    CHECK_FALSE(c.reflex_forced());
    CHECK(gx.reflexOptions.back().mode == sl::kReflexLowLatencyBoost);
    c.require_reflex(false);
    CHECK(c.driver() == LatencyDriver::Reflex);
    c.detach();
}
