// M78-P4b: the Streamline runtime core (src/streamline_runtime.{h,cpp}) and the DLSS Super Resolution provider (src/render_upscale_dlss.{h,cpp}).
// No NVIDIA library is involved: the functions of Streamline are fakes in a table the runtime takes from a fake VendorLibrary (the way it takes
// the real ones), the adapter and the COM releases are injected, and the device is a RecordingDevice that answers a backend and native handles.
// What is tested is what the engine asks of Streamline and in which order: slInit before the device, the upgrades and the device handed over
// (D3D12), the requirements, procs, extensions, features, queues and slSetVulkanInfo (Vulkan), the reasons it is unavailable, the frame token,
// the constants, tags and evaluate of each frame inside a native section with the declared states, the options set only on change, and the
// fall back when a frame fails. That the real library draws the right picture is for a machine with an NVIDIA RTX GPU on D3D12 or Vulkan.
#include <doctest.h>

#include <algorithm>
#include <array>
#include <cfloat>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <map>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/render/upscaler.h"
#include "gpu/device_hooks.h"
#include "gpu/recording_device.h"
#include "render_features.h"
#include "render_upscale_dlss.h"
#include "render_upscale_rr.h"
#include "render_upscale_vendor.h"
#include "streamline_runtime.h"

using namespace fa;
using render::GpuVendor;
namespace sl = fa::render::sl_abi;
using SlR = sl::Result;

namespace {

// ---- the fake library ---------------------------------------------------------------------------------------------------------------

struct Sx {
    SlR initRc = 0, shutdownRc = 0, supportedRc = 0, requirementsRc = 0, setD3dRc = 0, upgradeRc = 0, vkInfoRc = 0,
        tokenRc = 0, setOptionsRc = 0, optimalRc = 0, tagRc = 0, constantsRc = 0, evaluateRc = 0, functionRc = 0;
    std::vector<std::string> events;
    // slInit
    std::vector<std::uint32_t> loaded;
    std::uint64_t prefsFlags = 0;
    std::uint32_t prefsRenderApi = 99;
    std::uint32_t prefsAppId = 99;
    std::string prefsProjectId;
    std::uint64_t sdkVersion = 0;
    int inits = 0, shutdowns = 0, frees = 0;
    // slIsFeatureSupported
    int supportedCalls = 0;
    std::uint32_t supportedLuidSize = 0;
    std::uint8_t supportedLuid[8]{};
    void* supportedVkPhysical = nullptr;
    // D3D12
    bool failFactoryUpgrade = false;
    int deviceMarker = 0, factoryMarker = 0, proxyDevice = 0, proxyFactory = 0, adapterMarker = 0;
    void* setD3dDevice = nullptr;
    // Vulkan
    std::uint32_t requirementFlags = sl::kReqD3d12 | sl::kReqVulkan;
    std::vector<std::string> instanceExt{"VK_KHR_get_physical_device_properties2"}, deviceExt{"VK_NVX_binary_import"},
        f12, f13;
    std::uint32_t queuesGraphics = 0, queuesCompute = 1, queuesOpticalFlow = 1;
    sl::VulkanInfo vulkanInfo{};
    int instanceMarker = 0, physicalMarker = 0, vkDeviceMarker = 0;
    // frames
    int tokenMarker = 0;
    std::uint32_t frameAsked = 0xFFFFFFFFu;
    sl::Constants constants{};
    int constantsCalls = 0;
    void* constantsToken = nullptr;
    std::vector<sl::ResourceTag> tags;
    std::vector<sl::Resource> resources;
    void* tagList = nullptr;
    void* tagToken = nullptr;
    std::uint32_t tagViewport = 99;
    std::uint32_t evalFeature = 99;
    void* evalToken = nullptr;
    void* evalList = nullptr;
    std::uint32_t evalViewport = 99;
    sl::DlssOptions options{};
    int setOptionsCalls = 0, optimalCalls = 0;
    // Ray Reconstruction (M78-P4c): its own functions, and the evaluate of its feature alone can be refused.
    sl::DlssdOptions rrOptions{};
    sl::DlssdOptimalSettings rrSettings{};
    int rrSetOptionsCalls = 0, rrOptimalCalls = 0;
    SlR rrSetOptionsRc = 0, rrFunctionRc = 0, rrEvaluateRc = 0;
    std::vector<std::uint32_t> evalFeatures;
    std::uint32_t optimalOverrideW = 0, optimalOverrideH = 0;
    void reset() { *this = Sx{}; }
};
Sx sx;

SlR f_init(const sl::Preferences* p, std::uint64_t version) {
    sx.events.push_back("init");
    ++sx.inits;
    sx.loaded.assign(p->featuresToLoad, p->featuresToLoad + p->numFeaturesToLoad);
    sx.prefsFlags = p->flags;
    sx.prefsRenderApi = p->renderApi;
    sx.prefsAppId = p->applicationId;
    sx.prefsProjectId = p->projectId ? p->projectId : "";
    sx.sdkVersion = version;
    return sx.initRc;
}
SlR f_shutdown() {
    sx.events.push_back("shutdown");
    ++sx.shutdowns;
    return sx.shutdownRc;
}
SlR f_supported(std::uint32_t, const sl::AdapterInfo* a) {
    sx.events.push_back("supported");
    ++sx.supportedCalls;
    sx.supportedLuidSize = a->deviceLuidSizeInBytes;
    if (a->deviceLuid) std::memcpy(sx.supportedLuid, a->deviceLuid, 8);
    sx.supportedVkPhysical = a->vkPhysicalDevice;
    return sx.supportedRc;
}
SlR f_tag(void* frame, const sl::ViewportHandle* v, const sl::ResourceTag* tags, std::uint32_t n, void* list) {
    sx.events.push_back("tag");
    sx.tagToken = frame;
    sx.tagViewport = v->value;
    sx.tagList = list;
    sx.tags.assign(tags, tags + n);
    sx.resources.clear();
    for (std::uint32_t i = 0; i < n; ++i) sx.resources.push_back(*tags[i].resource);
    return sx.tagRc;
}
SlR f_constants(const sl::Constants* c, void* frame, const sl::ViewportHandle*) {
    sx.events.push_back("constants");
    ++sx.constantsCalls;
    sx.constants = *c;
    sx.constantsToken = frame;
    return sx.constantsRc;
}
// The Vulkan requirements: the lists of Sx, handed out as C strings that live as long as the fake.
std::vector<const char*> g_inst, g_dev, g_f12, g_f13;
std::vector<const char*> names_of(const std::vector<std::string>& in) {
    std::vector<const char*> out;
    for (const std::string& s : in) out.push_back(s.c_str());
    return out;
}
SlR f_requirements(std::uint32_t, sl::FeatureRequirements* r) {
    sx.events.push_back("requirements");
    if (sx.requirementsRc != 0) return sx.requirementsRc;
    g_inst = names_of(sx.instanceExt);
    g_dev = names_of(sx.deviceExt);
    g_f12 = names_of(sx.f12);
    g_f13 = names_of(sx.f13);
    r->flags = sx.requirementFlags;
    r->vkNumInstanceExtensions = std::uint32_t(g_inst.size());
    r->vkInstanceExtensions = g_inst.data();
    r->vkNumDeviceExtensions = std::uint32_t(g_dev.size());
    r->vkDeviceExtensions = g_dev.data();
    r->vkNumFeatures12 = std::uint32_t(g_f12.size());
    r->vkFeatures12 = g_f12.data();
    r->vkNumFeatures13 = std::uint32_t(g_f13.size());
    r->vkFeatures13 = g_f13.data();
    r->vkNumGraphicsQueuesRequired = sx.queuesGraphics;
    r->vkNumComputeQueuesRequired = sx.queuesCompute;
    r->vkNumOpticalFlowQueuesRequired = sx.queuesOpticalFlow;
    return 0;
}
SlR f_allocate(void*, std::uint32_t, const sl::ViewportHandle*) { return 0; }
SlR f_free(std::uint32_t, const sl::ViewportHandle*) {
    sx.events.push_back("free");
    ++sx.frees;
    return 0;
}
SlR f_evaluate(std::uint32_t feature, void* frame, const sl::Base* const* inputs, std::uint32_t, void* list) {
    sx.events.push_back("evaluate");
    sx.evalFeature = feature;
    sx.evalFeatures.push_back(feature);
    if (feature == sl::kFeatureDlssRr && sx.rrEvaluateRc != 0) return sx.rrEvaluateRc;
    sx.evalToken = frame;
    sx.evalList = list;
    sx.evalViewport = reinterpret_cast<const sl::ViewportHandle*>(inputs[0])->value;
    return sx.evaluateRc;
}
SlR f_upgrade(void** p) {
    sx.events.push_back("upgrade");
    if (sx.upgradeRc != 0) return sx.upgradeRc;
    if (*p == &sx.factoryMarker && sx.failFactoryUpgrade) return sl::kErrorMissingProxy;
    if (*p == &sx.deviceMarker) *p = &sx.proxyDevice;
    if (*p == &sx.factoryMarker) *p = &sx.proxyFactory;
    return 0;
}
SlR f_set_options(const sl::ViewportHandle*, const sl::DlssOptions* o) {
    sx.events.push_back("setOptions");
    ++sx.setOptionsCalls;
    sx.options = *o;
    return sx.setOptionsRc;
}
SlR f_optimal(const sl::DlssOptions* o, sl::DlssOptimalSettings* s) {
    sx.events.push_back("optimal");
    ++sx.optimalCalls;
    if (sx.optimalRc != 0) return sx.optimalRc;
    const float ratio = render::dlss_mode_ratio(o->mode);
    s->optimalRenderWidth =
        sx.optimalOverrideW ? sx.optimalOverrideW : std::uint32_t(float(o->outputWidth) / ratio + 0.5f);
    s->optimalRenderHeight =
        sx.optimalOverrideH ? sx.optimalOverrideH : std::uint32_t(float(o->outputHeight) / ratio + 0.5f);
    return 0;
}
SlR f_rr_set_options(const sl::ViewportHandle*, const sl::DlssdOptions* o) {
    sx.events.push_back("rrSetOptions");
    ++sx.rrSetOptionsCalls;
    sx.rrOptions = *o;
    return sx.rrSetOptionsRc;
}
SlR f_rr_optimal(const sl::DlssdOptions* o, sl::DlssdOptimalSettings* s) {
    sx.events.push_back("rrOptimal");
    ++sx.rrOptimalCalls;
    const float ratio = render::dlss_mode_ratio(o->mode);
    s->optimalRenderWidth = std::uint32_t(float(o->outputWidth) / ratio + 0.5f);
    s->optimalRenderHeight = std::uint32_t(float(o->outputHeight) / ratio + 0.5f);
    sx.rrSettings = *s;
    return 0;
}
SlR f_function(std::uint32_t feature, const char* name, void** fn) {
    if (sx.functionRc != 0) return sx.functionRc;
    const std::string n = name;
    if (feature == sl::kFeatureDlssRr) {
        if (sx.rrFunctionRc != 0) return sx.rrFunctionRc;
        if (n == "slDLSSDSetOptions") {
            *fn = reinterpret_cast<void*>(&f_rr_set_options);
            return 0;
        }
        if (n == "slDLSSDGetOptimalSettings") {
            *fn = reinterpret_cast<void*>(&f_rr_optimal);
            return 0;
        }
        return sl::kErrorFeatureMissing;
    }
    if (n == "slDLSSSetOptions")
        *fn = reinterpret_cast<void*>(&f_set_options);
    else if (n == "slDLSSGetOptimalSettings")
        *fn = reinterpret_cast<void*>(&f_optimal);
    else
        return sl::kErrorFeatureMissing;
    return 0;
}
SlR f_token(void** token, const std::uint32_t* index) {
    sx.events.push_back("token");
    sx.frameAsked = index ? *index : 0xFFFFFFFEu;
    if (sx.tokenRc != 0) return sx.tokenRc;
    *token = &sx.tokenMarker;
    return 0;
}
SlR f_set_d3d(void* device) {
    sx.events.push_back("setD3D");
    sx.setD3dDevice = device;
    return sx.setD3dRc;
}
SlR f_set_vk(const sl::VulkanInfo* info) {
    sx.events.push_back("setVulkanInfo");
    sx.vulkanInfo = *info;
    return sx.vkInfoRc;
}
void marker_instance_fn() {}
void marker_device_fn() {}
void* f_vk_instance_proc(void*, const char* name) {
    return std::string(name) == "vkQueuePresentKHR" ? reinterpret_cast<void*>(&marker_instance_fn) : nullptr;
}
void* f_vk_device_proc(void*, const char* name) {
    return std::string(name) == "vkCmdBindPipeline" ? reinterpret_cast<void*>(&marker_device_fn) : nullptr;
}

class FakeLibrary final : public render::VendorLibrary {
public:
    explicit FakeLibrary(std::vector<std::string> hidden) : hidden_(std::move(hidden)) {
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
        table_["vkGetInstanceProcAddr"] = reinterpret_cast<void*>(&f_vk_instance_proc);
        table_["vkGetDeviceProcAddr"] = reinterpret_cast<void*>(&f_vk_device_proc);
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
    std::string path_ = "fake/sl.interposer.dll";
};

class FakeLoader final : public render::VendorLoader {
public:
    bool installed = true, loads = true;
    std::vector<std::string> hidden;  // the exports the library lacks
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

// The adapter the runtime reads and the COM objects it gives back.
struct AdapterFx {
    std::uint32_t vendor = 0x10DE;
    bool readable = true;
    std::vector<void*> released;
};
render::StreamlineHost make_host(AdapterFx& a) {
    render::StreamlineHost h;
    h.readAdapter = [&a](const void*, render::StreamlineAdapter& out) {
        if (!a.readable) return false;
        out.vendorId = a.vendor;
        out.hasLuid = true;
        for (int i = 0; i < 8; ++i) out.luid[i] = std::uint8_t(i + 1);
        out.name = "Fake RTX";
        return true;
    };
    h.releaseCom = [&a](void* o) { a.released.push_back(o); };
    return h;
}

// What the engine does with a hook on a D3D12 device: before the device, then after.
void run_d3d12(render::StreamlineRuntime& rt, gpu::D3d12DeviceCreated& c, bool warp = false) {
    gpu::D3d12BeforeDevice before;
    before.factory = &sx.factoryMarker;
    before.adapter = &sx.adapterMarker;
    before.warp = warp;
    rt.d3d12_before_device(before);
    c.factory = &sx.factoryMarker;
    c.device = &sx.deviceMarker;
    c.adapter = &sx.adapterMarker;
    rt.d3d12_device_created(c);
}
// ... and on a Vulkan device: the instance, then the physical device, then the device.
void run_vulkan(render::StreamlineRuntime& rt, gpu::VulkanInstanceRequest& ir, gpu::VulkanDeviceRequest& dr,
                std::uint32_t vendorId = 0x10DE) {
    rt.vulkan_instance_request(ir);
    if (!rt.available()) return;
    rt.vulkan_instance_created(&sx.instanceMarker, nullptr);
    gpu::VulkanPhysicalDevice pd;
    pd.instance = &sx.instanceMarker;
    pd.physicalDevice = &sx.physicalMarker;
    pd.vendorId = vendorId;
    pd.name = "Fake RTX";
    rt.vulkan_device_request(pd, dr);
    if (!rt.available()) return;
    gpu::VulkanDeviceCreated dc;
    dc.native.device = &sx.vkDeviceMarker;
    dc.native.instance = &sx.instanceMarker;
    dc.native.physicalDevice = &sx.physicalMarker;
    dc.native.graphicsFamily = 0;
    dc.native.graphicsQueueIndex = 0;
    dc.native.computeFamily = 0;
    dc.native.computeQueueIndex = 0;
    std::uint32_t next = 0;
    for (const gpu::VulkanQueueRequest& q : dr.queues)
        for (std::uint32_t i = 0; i < q.count; ++i) {
            gpu::VulkanQueueGrant g;
            g.family = 5 + next;  // each role a family of its own, so the test reads which grant went where
            g.index = 1 + next;
            dc.queues.push_back(g);
            ++next;
        }
    rt.vulkan_device_created(dc);
}

// Whether `names` appear in `events` in this order (other events may lie between).
bool in_order(const std::vector<std::string>& events, std::initializer_list<const char*> names) {
    auto at = events.begin();
    for (const char* n : names) {
        at = std::find(at, events.end(), n);
        if (at == events.end()) return false;
        ++at;
    }
    return true;
}
int count_of(const std::vector<std::string>& events, const char* name) {
    return int(std::count(events.begin(), events.end(), name));
}

// ---- the fake device and command list -----------------------------------------------------------------------------------------------

class XDevice : public gpu::RecordingDevice {
public:
    explicit XDevice(gpu::Backend deviceBackend, std::uint32_t pciVendor = 0x10DE) : backend_(deviceBackend) {
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
        return n;
    }
    gpu::NativeImage native_image(gpu::Image img) const override {
        gpu::NativeImage n;
        if (!img.valid()) return n;
        n.resource = reinterpret_cast<const void*>(std::uintptr_t(img.id) * 16);
        n.vkImage = std::uint64_t(img.id) * 16;
        n.nativeFormat = 28;  // DXGI_FORMAT_R8G8B8A8_UNORM
        n.vkUsage = 0x1B;
        return n;
    }
    gpu::NativeView native_view(gpu::View v) const override {
        gpu::NativeView n;
        if (!v.valid()) return n;
        n.vkImageView = std::uint64_t(v.id) * 256;
        n.nativeFormat = 37;  // VK_FORMAT_R8G8B8A8_UNORM
        return n;
    }
    fa::Result<void> wait_idle() override {
        ++idles;
        sx.events.push_back("idle");
        return {};
    }
    int idles = 0;

    gpu::Image image(int w, int h, gpu::PixelFormat format, bool storage = false) {
        gpu::ImageDesc d;
        d.width = w;
        d.height = h;
        d.pixelFormat = format;
        d.usage.storageImage = storage;
        d.label = "dlss-test";
        return make_image(d);
    }
    gpu::View view(gpu::Image img) {
        gpu::ViewDesc vd;
        vd.texture.image = img;
        return make_view(vd);
    }

private:
    gpu::Backend backend_;
    gpu::DeviceInfo info_{};
};

class XList final : public gpu::RecordingCommandList {
public:
    XList(XDevice& device, gpu::Backend backend) : gpu::RecordingCommandList(device), backend_(backend) {}
    fa::Result<gpu::NativeCommands> begin_native(std::span<const gpu::NativeUse> uses) override {
        sx.events.push_back("begin");
        if (failBegin) return make_error("the fake list refuses a native section", "none");
        declared.assign(uses.begin(), uses.end());
        gpu::NativeCommands n;
        n.backend = backend_;
        n.list = &token;
        return n;
    }
    fa::Result<void> end_native(std::span<const gpu::NativeUse>) override {
        sx.events.push_back("end");
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

// One frame's worth of everything: the Streamline runtime of the test (made ready on a D3D12 or Vulkan device), a device, a list, the images,
// the input and the provider under test (its own instance, not the process's).
struct Rig {
    FakeLoader loader;
    LoaderGuard guard{&loader};
    AdapterFx adapter;
    render::StreamlineRuntime runtime{{sl::kFeatureDlss, sl::kFeatureDlssRr}, make_host(adapter)};
    XDevice dev;
    XList list;
    std::unique_ptr<render::VendorUpscaler> dlss = render::make_dlss_provider();
    gpu::Image color, depth, velocity, output;
    gpu::View colorView, depthView, velocityView;
    render::UpscaleInput in;
    render::VendorFrame frame;
    int renderW = 160, renderH = 90, outW = 320, outH = 180;

    explicit Rig(gpu::Backend backend, bool ready = true) : dev(backend), list(dev, backend) {
        sx.reset();
        render::set_streamline_runtime_for_test(&runtime);
        if (ready) {
            if (backend == gpu::Backend::Vulkan) {
                gpu::VulkanInstanceRequest ir;
                gpu::VulkanDeviceRequest dr;
                run_vulkan(runtime, ir, dr);
            } else {
                gpu::D3d12DeviceCreated c;
                run_d3d12(runtime, c);
            }
            REQUIRE(runtime.status().ready);
        }
        setup_images();
        sx.events.clear();
    }
    ~Rig() {
        dlss->release(dev);
        render::set_streamline_runtime_for_test(nullptr);
        free_images();
    }
    Rig(const Rig&) = delete;
    Rig& operator=(const Rig&) = delete;

    void setup_images() {
        color = dev.image(renderW, renderH, gpu::PixelFormat::Rgba8);
        depth = dev.image(renderW, renderH, gpu::PixelFormat::R32F);
        velocity = dev.image(renderW, renderH, gpu::PixelFormat::Rg16F);
        output = dev.image(outW, outH, gpu::PixelFormat::Rgba8, true);
        colorView = dev.view(color);
        depthView = dev.view(depth);
        velocityView = dev.view(velocity);
        in = render::UpscaleInput{};
        in.color = colorView;
        in.depth = depthView;
        in.velocity = velocityView;
        in.renderW = renderW;
        in.renderH = renderH;
        in.outW = outW;
        in.outH = outH;
        in.jitter[0] = 0.25f;
        in.jitter[1] = -0.125f;
        frame = render::VendorFrame{};
        frame.device = &dev;
        frame.list = &list;
        frame.color = color;
        frame.depth = depth;
        frame.velocity = velocity;
        frame.output = output;
    }
    void free_images() {
        for (const gpu::Image i : {color, depth, velocity, output})
            if (i.valid()) dev.destroy_image(i);
    }
    void resize(int rw, int rh, int ow, int oh) {
        free_images();
        renderW = rw;
        renderH = rh;
        outW = ow;
        outH = oh;
        setup_images();
    }
    render::VendorEnv env(GpuVendor vendor = GpuVendor::Nvidia) const {
        render::VendorEnv e;
        e.backend = dev.backend();
        e.vendor = vendor;
        e.device = &dev;
        e.windows = true;
        return e;
    }
    bool draw() { return dlss->upscale(in, frame); }
};

}  // namespace

// ---- the C ABI -----------------------------------------------------------------------------------------------------------------------

TEST_CASE(
    "streamline abi: every structure is made with its version and a GUID, and the unset values are the headers'") {
    sl::Preferences p;
    sl::init_preferences(p);
    CHECK(p.base.version == 1u);
    CHECK(p.base.type.data1 == 0x1ca10965);
    CHECK(p.logLevel == 1);
    sl::Constants c;
    sl::init_constants(c);
    CHECK(c.base.version == 2u);
    CHECK(c.base.type.data1 == 0xdcd35ad7);
    CHECK(c.reset == sl::kInvalid);
    // The header's own defaults: INVALID_FLOAT for what is not set, eFalse for the three optional flags.
    CHECK(c.cameraNear == FLT_MAX);
    CHECK(c.cameraAspectRatio == FLT_MAX);
    CHECK(c.jitterOffset.x == FLT_MAX);
    CHECK(c.cameraPos.z == FLT_MAX);
    CHECK(c.orthographicProjection == sl::kFalse);
    CHECK(c.motionVectorsDilated == sl::kFalse);
    CHECK(c.motionVectorsJittered == sl::kFalse);
    CHECK(c.minRelativeLinearDepthObjectSeparation == doctest::Approx(40.0f));
    CHECK(c.cameraViewToClip.row[2].z == 1.0f);
    sl::DlssOptions o;
    sl::init_dlss_options(o);
    CHECK(o.base.version == 3u);
    CHECK(o.outputWidth == 0xFFFFFFFFu);
    sl::FeatureRequirements r;
    sl::init_feature_requirements(r);
    CHECK(r.base.version == 2u);
    sl::VulkanInfo v;
    sl::init_vulkan_info(v);
    CHECK(v.base.version == 3u);
    sl::Resource res;
    sl::init_resource(res);
    CHECK(res.state == 0xFFFFFFFFu);
}

TEST_CASE("streamline: results are named with what to do, and an unknown code is still printed") {
    CHECK(render::streamline_result_text(sl::kOk) == "ok");
    CHECK(render::streamline_result_text(sl::kErrorDriverOutOfDate) == "driver out of date");
    CHECK(render::streamline_result_text(99) == "result 99");
    const std::string text = render::streamline_refusal("slInit", sl::kErrorDriverOutOfDate);
    CHECK(text.find("slInit") != std::string::npos);
    CHECK(text.find("driver out of date") != std::string::npos);
    CHECK(text.find("Update the NVIDIA") != std::string::npos);
    CHECK(render::streamline_refusal("slInit", sl::kErrorOSDisabledHWS).find("Hardware-accelerated GPU scheduling") !=
          std::string::npos);
    CHECK(render::streamline_refusal("slInit", sl::kErrorNoPlugins).find("factoria setup streamline") !=
          std::string::npos);
}

TEST_CASE("streamline: the Vulkan feature blobs are whole Vulkan12 and Vulkan13 structs with the named members on") {
    std::vector<std::string> unknown;
    const std::vector<std::uint8_t> b12 =
        render::streamline_vulkan_features(12, {"bufferDeviceAddress", "timelineSemaphore", "noSuchFeature"}, &unknown);
    CHECK(b12.size() == 208);  // 16 + 47 * 4, rounded up to 8
    std::uint32_t sType = 0;
    std::memcpy(&sType, b12.data(), 4);
    CHECK(sType == 51);
    const auto flag = [](const std::vector<std::uint8_t>& b, std::size_t member) {
        std::uint32_t v = 0;
        std::memcpy(&v, b.data() + 16 + 4 * member, 4);
        return v;
    };
    CHECK(flag(b12, 38) == 1);  // bufferDeviceAddress
    CHECK(flag(b12, 37) == 1);  // timelineSemaphore
    CHECK(flag(b12, 0) == 0);
    REQUIRE(unknown.size() == 1);
    CHECK(unknown[0] == "noSuchFeature");
    const std::vector<std::uint8_t> b13 = render::streamline_vulkan_features(13, {"synchronization2"}, nullptr);
    CHECK(b13.size() == 80);
    std::memcpy(&sType, b13.data(), 4);
    CHECK(sType == 53);
    CHECK(flag(b13, 9) == 1);
}

// ---- the runtime on D3D12 ------------------------------------------------------------------------------------------------------------

TEST_CASE("streamline D3D12: slInit runs before the device, the device and the factory are upgraded after it, and the "
          "engine gets the "
          "proxies") {
    sx.reset();
    FakeLoader loader;
    LoaderGuard guard(&loader);
    AdapterFx adapter;
    render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
    gpu::D3d12BeforeDevice before;
    before.adapter = &sx.adapterMarker;
    rt.d3d12_before_device(before);
    CHECK(sx.inits == 1);
    CHECK(sx.supportedCalls == 0);  // the device is not made yet
    CHECK(sx.loaded == std::vector<std::uint32_t>{sl::kFeatureDlss});
    CHECK(sx.prefsRenderApi == sl::kRenderApiD3d12);
    CHECK((sx.prefsFlags & sl::kPrefUseManualHooking) != 0);
    CHECK((sx.prefsFlags & sl::kPrefUseFrameBasedResourceTagging) != 0);
    CHECK((sx.sdkVersion >> 48) == 2);

    gpu::D3d12DeviceCreated c;
    c.factory = &sx.factoryMarker;
    c.device = &sx.deviceMarker;
    c.adapter = &sx.adapterMarker;
    rt.d3d12_device_created(c);
    CHECK(rt.available());
    CHECK(in_order(sx.events, {"init", "setD3D", "upgrade", "upgrade", "supported"}));
    CHECK(sx.setD3dDevice == &sx.deviceMarker);  // Streamline is given the native device
    CHECK(c.device == &sx.proxyDevice);
    CHECK(c.factory == &sx.proxyFactory);
    CHECK(sx.supportedLuidSize == 8);
    CHECK(sx.supportedLuid[0] == 1);
    CHECK(sx.supportedLuid[7] == 8);
    CHECK(adapter.released.empty());
    const render::StreamlineStatus st = rt.status();
    CHECK(st.tried);
    CHECK(st.ready);
    CHECK(st.backend == gpu::Backend::D3d12);
    CHECK(st.generation == 1);
    CHECK(rt.api() != nullptr);
    CHECK(rt.feature_reason(sl::kFeatureDlss).empty());

    rt.device_destroying();
    CHECK(sx.shutdowns == 1);
    CHECK_FALSE(rt.status().ready);
    CHECK(rt.api() == nullptr);
}

TEST_CASE("streamline D3D12: a GPU that is not NVIDIA never starts Streamline, and the hook says why") {
    sx.reset();
    FakeLoader loader;
    LoaderGuard guard(&loader);
    AdapterFx adapter;
    adapter.vendor = 0x1002;
    render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
    gpu::D3d12DeviceCreated c;
    run_d3d12(rt, c);
    CHECK(sx.inits == 0);
    CHECK_FALSE(rt.available());
    CHECK(rt.unavailable_reason().find("NVIDIA RTX GPU") != std::string::npos);
    CHECK(c.device == &sx.deviceMarker);  // the engine's own device, untouched
    CHECK(c.factory == &sx.factoryMarker);
    CHECK(rt.status().tried);
    CHECK_FALSE(rt.status().ready);
    CHECK(rt.status().reason == rt.unavailable_reason());

    // WARP is not NVIDIA either, whatever its vendor id says; and a second adapter that is NVIDIA starts it.
    sx.reset();
    AdapterFx nvidia;
    render::StreamlineRuntime second({sl::kFeatureDlss}, make_host(nvidia));
    gpu::D3d12BeforeDevice warp;
    warp.warp = true;
    second.d3d12_before_device(warp);
    CHECK(sx.inits == 0);
    gpu::D3d12BeforeDevice real;
    real.adapter = &sx.adapterMarker;
    second.d3d12_before_device(real);
    CHECK(sx.inits == 1);
}

TEST_CASE("streamline D3D12: every way Streamline can be missing leaves the runtime unavailable with a reason, never "
          "the device") {
    sx.reset();
    FakeLoader loader;
    LoaderGuard guard(&loader);
    gpu::D3d12DeviceCreated c;

    SUBCASE("not installed") {
        loader.installed = false;
        AdapterFx adapter;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        run_d3d12(rt, c);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("factoria setup streamline") != std::string::npos);
        CHECK(rt.unavailable_reason().find("the fake loader has no library") != std::string::npos);
        CHECK(sx.inits == 0);
    }
    SUBCASE("cannot be loaded") {
        loader.loads = false;
        AdapterFx adapter;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        run_d3d12(rt, c);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("could not be loaded") != std::string::npos);
        CHECK(rt.unavailable_reason().find("the fake loader cannot load it") != std::string::npos);
    }
    SUBCASE("an export is missing") {
        loader.hidden = {"slUpgradeInterface"};
        AdapterFx adapter;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        run_d3d12(rt, c);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("slUpgradeInterface") != std::string::npos);
        CHECK(sx.inits == 0);
    }
    SUBCASE("slInit refuses: the driver is too old") {
        sx.initRc = sl::kErrorDriverOutOfDate;
        AdapterFx adapter;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        run_d3d12(rt, c);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("driver out of date") != std::string::npos);
        CHECK(rt.unavailable_reason().find("Update the NVIDIA") != std::string::npos);
        CHECK(sx.setD3dDevice == nullptr);
        CHECK(c.device == &sx.deviceMarker);
    }
    SUBCASE("the factory cannot be upgraded: the device's proxy is given back and Streamline is shut down") {
        AdapterFx adapter;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        sx.failFactoryUpgrade = true;
        run_d3d12(rt, c);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("slUpgradeInterface (factory)") != std::string::npos);
        CHECK(sx.shutdowns == 1);
        CHECK(c.device == &sx.deviceMarker);
        CHECK(c.factory == &sx.factoryMarker);
        REQUIRE(adapter.released.size() == 1);
        CHECK(adapter.released[0] == &sx.proxyDevice);
    }
    SUBCASE("Streamline says the GPU cannot run DLSS") {
        sx.supportedRc = sl::kErrorAdapterNotSupported;
        AdapterFx adapter;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        run_d3d12(rt, c);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("adapter not supported") != std::string::npos);
        CHECK(rt.unavailable_reason().find("RTX") != std::string::npos);
        CHECK(sx.shutdowns == 1);
        // The proxies the upgrades made are given back: the engine keeps its own objects.
        CHECK(c.device == &sx.deviceMarker);
        CHECK(c.factory == &sx.factoryMarker);
        CHECK(adapter.released.size() == 2);
    }
}

TEST_CASE("streamline: the frame token is asked with the number of presents so far") {
    sx.reset();
    FakeLoader loader;
    LoaderGuard guard(&loader);
    AdapterFx adapter;
    render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
    std::string why;
    CHECK(rt.frame_token(nullptr, &why) == nullptr);  // not ready
    CHECK_FALSE(why.empty());
    gpu::D3d12DeviceCreated c;
    run_d3d12(rt, c);
    std::uint32_t index = 99;
    void* token = rt.frame_token(&index, &why);
    CHECK(token == &sx.tokenMarker);
    CHECK(index == 0);
    CHECK(sx.frameAsked == 0);
    gpu::PresentEvent e;
    e.backend = gpu::Backend::D3d12;
    e.frame = 1;
    rt.present_end(e);
    e.frame = 2;
    rt.present_end(e);
    CHECK(rt.frame_index() == 2);
    CHECK(rt.frame_token(&index, &why) == &sx.tokenMarker);
    CHECK(index == 2);
    CHECK(sx.frameAsked == 2);
    e.frame = 1;  // an older event never moves the count back
    rt.present_end(e);
    CHECK(rt.frame_index() == 2);
    // The token of a frame is asked once: DLSS and Reflex asking for the same index get the same token.
    sx.frameAsked = 0xFFFFFFFFu;
    CHECK(rt.frame_token(&index, &why) == &sx.tokenMarker);
    CHECK(sx.frameAsked == 0xFFFFFFFFu);
    e.frame = 3;
    rt.present_end(e);
    sx.tokenRc = sl::kErrorInvalidState;
    CHECK(rt.frame_token(&index, &why) == nullptr);
    CHECK(why.find("slGetNewFrameToken") != std::string::npos);
}

// ---- the runtime on Vulkan -----------------------------------------------------------------------------------------------------------

TEST_CASE("streamline Vulkan: the requirements become extensions, features and queues, Streamline's procs replace the "
          "loader's, and "
          "slSetVulkanInfo gets the device and the queues") {
    sx.reset();
    sx.f12 = {"bufferDeviceAddress"};
    sx.f13 = {"synchronization2"};
    FakeLoader loader;
    LoaderGuard guard(&loader);
    AdapterFx adapter;
    render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
    gpu::VulkanInstanceRequest ir;
    gpu::VulkanDeviceRequest dr;
    rt.vulkan_instance_request(ir);
    CHECK(sx.prefsRenderApi == sl::kRenderApiVulkan);
    CHECK(in_order(sx.events, {"init", "requirements"}));
    REQUIRE(ir.extensions.size() == 1);
    CHECK(ir.extensions[0] == "VK_KHR_get_physical_device_properties2");
    rt.vulkan_instance_created(&sx.instanceMarker, nullptr);
    // Streamline's procs: an instance function, a device function, and what Streamline does not hook stays the loader's.
    const gpu::HookProcAddr loaders = reinterpret_cast<gpu::HookProcAddr>(&marker_device_fn);
    CHECK(rt.vulkan_resolve("vkQueuePresentKHR", nullptr, loaders) ==
          reinterpret_cast<gpu::HookProcAddr>(&marker_instance_fn));
    CHECK(rt.vulkan_resolve("vkCmdBindPipeline", &sx.vkDeviceMarker, nullptr) ==
          reinterpret_cast<gpu::HookProcAddr>(&marker_device_fn));
    CHECK(rt.vulkan_resolve("vkCmdDraw", &sx.vkDeviceMarker, loaders) == nullptr);
    CHECK(rt.vulkan_resolve("vkCmdBindPipeline", &sx.vkDeviceMarker, loaders) ==
          nullptr);  // the same function: no replacement

    gpu::VulkanPhysicalDevice pd;
    pd.instance = &sx.instanceMarker;
    pd.physicalDevice = &sx.physicalMarker;
    pd.vendorId = 0x10DE;
    pd.name = "Fake RTX";
    rt.vulkan_device_request(pd, dr);
    CHECK(rt.available());
    CHECK(sx.supportedVkPhysical == &sx.physicalMarker);
    REQUIRE(dr.extensions.size() == 1);
    CHECK(dr.extensions[0] == "VK_NVX_binary_import");
    REQUIRE(dr.features.size() == 2);
    CHECK(dr.features[0].size() == 208);
    CHECK(dr.features[1].size() == 80);
    REQUIRE(dr.queues.size() == 2);  // no graphics queue asked: compute, then optical flow
    CHECK(dr.queues[0].flags == 0x2);
    CHECK(dr.queues[0].count == 1);
    CHECK(dr.queues[1].flags == 0x100);

    gpu::VulkanDeviceCreated dc;
    dc.native.device = &sx.vkDeviceMarker;
    dc.native.instance = &sx.instanceMarker;
    dc.native.physicalDevice = &sx.physicalMarker;
    dc.native.graphicsFamily = 7;
    dc.native.graphicsQueueIndex = 3;
    dc.queues = {{5, 1, nullptr}, {6, 2, nullptr}};
    rt.vulkan_device_created(dc);
    CHECK(rt.available());
    CHECK(sx.vulkanInfo.device == &sx.vkDeviceMarker);
    CHECK(sx.vulkanInfo.instance == &sx.instanceMarker);
    CHECK(sx.vulkanInfo.physicalDevice == &sx.physicalMarker);
    CHECK(sx.vulkanInfo.computeQueueFamily == 5);
    CHECK(sx.vulkanInfo.computeQueueIndex == 1);
    CHECK(sx.vulkanInfo.opticalFlowQueueFamily == 6);
    CHECK(sx.vulkanInfo.opticalFlowQueueIndex == 2);
    CHECK(sx.vulkanInfo.graphicsQueueFamily == 7);  // not asked for: the engine's own graphics queue
    CHECK(sx.vulkanInfo.graphicsQueueIndex == 3);
    CHECK(rt.status().ready);
    CHECK(rt.status().backend == gpu::Backend::Vulkan);
    CHECK(in_order(sx.events, {"init", "requirements", "supported", "setVulkanInfo"}));
}

TEST_CASE(
    "streamline Vulkan: a GPU that is not NVIDIA, a refusal and a feature this build does not know leave the runtime "
    "unavailable") {
    sx.reset();
    FakeLoader loader;
    LoaderGuard guard(&loader);
    AdapterFx adapter;
    gpu::VulkanInstanceRequest ir;
    gpu::VulkanDeviceRequest dr;

    SUBCASE("another maker's GPU") {
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        run_vulkan(rt, ir, dr, 0x1002);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("NVIDIA RTX GPU") != std::string::npos);
        CHECK(sx.shutdowns == 1);
        CHECK(dr.extensions.empty());
        CHECK_FALSE(rt.status().ready);
        // Streamline is off for good: the engine's own Vulkan functions are used from now on, none of Streamline's.
        CHECK(rt.vulkan_resolve("vkCmdBindPipeline", &sx.vkDeviceMarker, nullptr) == nullptr);
        CHECK(rt.vulkan_resolve("vkCreateDevice", nullptr, nullptr) == nullptr);
    }
    SUBCASE("Streamline does not do Vulkan") {
        sx.requirementFlags = sl::kReqD3d12;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        run_vulkan(rt, ir, dr);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("Direct3D 12") != std::string::npos);
        CHECK(ir.extensions.empty());
    }
    SUBCASE("slGetFeatureRequirements fails") {
        sx.requirementsRc = sl::kErrorOSOutOfDate;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        run_vulkan(rt, ir, dr);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("OS out of date") != std::string::npos);
    }
    SUBCASE("a Vulkan feature name this build does not know") {
        sx.f12 = {"someFutureFeature"};
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        run_vulkan(rt, ir, dr);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("someFutureFeature") != std::string::npos);
    }
    SUBCASE("slSetVulkanInfo refuses") {
        sx.vkInfoRc = sl::kErrorInvalidState;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        run_vulkan(rt, ir, dr);
        CHECK_FALSE(rt.available());
        CHECK(rt.unavailable_reason().find("slSetVulkanInfo") != std::string::npos);
        CHECK(sx.shutdowns == 1);
        CHECK_FALSE(rt.status().ready);
    }
}

TEST_CASE("streamline: slInit gets FactorIA's project GUID and no application id unless the environment sets them") {
    // The text of the variables: a decimal id that fits 32 bits, a GUID; anything else is the default.
    CHECK(sl::streamline_application_id(nullptr) == 0u);
    CHECK(sl::streamline_application_id("") == 0u);
    CHECK(sl::streamline_application_id("123456") == 123456u);
    CHECK(sl::streamline_application_id("4294967295") == 4294967295u);
    CHECK(sl::streamline_application_id("4294967296") == 0u);
    CHECK(sl::streamline_application_id("12x") == 0u);
    CHECK(sl::streamline_project_id(nullptr) == sl::kDefaultProjectId);
    CHECK(sl::streamline_project_id("FactorIA") == sl::kDefaultProjectId);
    CHECK(sl::streamline_project_id("0123456789abcdef0123456789abcdef0123") == sl::kDefaultProjectId);
    CHECK(sl::streamline_project_id("01234567-89AB-cdef-0123-456789abcdeg") == sl::kDefaultProjectId);
    CHECK(sl::streamline_project_id("01234567-89AB-cdef-0123-456789abcdef") == "01234567-89AB-cdef-0123-456789abcdef");
    // The default is itself a GUID, so slInit is given one.
    CHECK(sl::streamline_project_id(sl::kDefaultProjectId) == sl::kDefaultProjectId);
    // And the start: the environment is the test's own (a developer who exports the variables does not change it).
    struct EnvGuard {
        explicit EnvGuard(render::StreamlineEnvReader reader) { render::set_streamline_environment_for_test(reader); }
        ~EnvGuard() { render::set_streamline_environment_for_test(nullptr); }
    };
    SUBCASE("the variables are not set") {
        EnvGuard env([](const char*) -> const char* { return nullptr; });
        sx.reset();
        FakeLoader loader;
        LoaderGuard guard(&loader);
        AdapterFx adapter;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        gpu::D3d12DeviceCreated c;
        run_d3d12(rt, c);
        CHECK(sx.inits == 1);
        CHECK(sx.prefsAppId == 0u);
        CHECK(sx.prefsProjectId == sl::kDefaultProjectId);
    }
    SUBCASE("the variables are set") {
        EnvGuard env([](const char* name) -> const char* {
            return std::string_view(name) == "FA_STREAMLINE_APP_ID" ? "4711" : "01234567-89AB-cdef-0123-456789abcdef";
        });
        sx.reset();
        FakeLoader loader;
        LoaderGuard guard(&loader);
        AdapterFx adapter;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        gpu::D3d12DeviceCreated c;
        run_d3d12(rt, c);
        CHECK(sx.inits == 1);
        CHECK(sx.prefsAppId == 4711u);
        CHECK(sx.prefsProjectId == "01234567-89AB-cdef-0123-456789abcdef");
    }
}

TEST_CASE("dlss: the renderer asks Streamline for Ray Reconstruction's plugin only when the game asked for it") {
    for (const bool asked : {false, true}) {
        sx.reset();
        FakeLoader loader;
        LoaderGuard guard(&loader);
        AdapterFx adapter;
        render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
        render::streamline_ask_upscaler_features(rt, asked);  // what Renderer::init does before it makes the device
        gpu::D3d12DeviceCreated c;
        run_d3d12(rt, c);
        CHECK(rt.feature_asked(sl::kFeatureDlssRr) == asked);
        CHECK(rt.feature_asked(sl::kFeatureDlss));
        CHECK((std::find(sx.loaded.begin(), sx.loaded.end(), sl::kFeatureDlssRr) != sx.loaded.end()) == asked);
    }
}

// ---- the provider: probe and the auto choice -----------------------------------------------------------------------------------------

TEST_CASE("dlss probe: the GPU and backend first, then what Streamline says, and a library that is not there names the "
          "setup command") {
    sx.reset();
    FakeLoader loader;
    LoaderGuard guard(&loader);
    AdapterFx adapter;
    render::StreamlineRuntime rt({sl::kFeatureDlss}, make_host(adapter));
    render::set_streamline_runtime_for_test(&rt);
    std::unique_ptr<render::VendorUpscaler> dlss = render::make_dlss_provider();
    CHECK(dlss->mode() == "dlss");
    CHECK(dlss->setup_id() == "streamline");
    CHECK(dlss->needs_output_storage());
    CHECK(dlss->backends() == ((1u << unsigned(gpu::Backend::D3d12)) | (1u << unsigned(gpu::Backend::Vulkan))));

    render::VendorEnv env;
    env.backend = gpu::Backend::D3d12;
    env.vendor = GpuVendor::Amd;
    env.windows = true;
    render::VendorProbe p = dlss->probe(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("NVIDIA RTX GPU") != std::string::npos);
    CHECK(p.reason.find("AMD") != std::string::npos);
    env.vendor = GpuVendor::Nvidia;
    env.backend = gpu::Backend::D3d11;  // the hooks are not called there
    p = dlss->probe(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("D3D12") != std::string::npos);
    env.backend = gpu::Backend::D3d12;
    env.windows = false;
    p = dlss->probe(env);
    CHECK(p.reason.find("Windows") != std::string::npos);
    env.windows = true;

    // Streamline never saw this device: the library is missing, or it is there and was not started.
    loader.installed = false;
    p = dlss->probe(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("factoria setup streamline") != std::string::npos);
    loader.installed = true;
    p = dlss->probe(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("not started") != std::string::npos);

    // Streamline started with the device: DLSS is available.
    gpu::D3d12DeviceCreated c;
    run_d3d12(rt, c);
    p = dlss->probe(env);
    CHECK(p.available);
    CHECK(p.reason.empty());
    env.backend = gpu::Backend::Vulkan;  // Streamline was started for D3D12
    p = dlss->probe(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("D3D12") != std::string::npos);
    rt.device_destroying();

    // Streamline tried and failed: its own reason.
    sx.initRc = sl::kErrorDriverOutOfDate;
    gpu::D3d12DeviceCreated failed;
    env.backend = gpu::Backend::D3d12;
    run_d3d12(rt, failed);
    p = dlss->probe(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("driver out of date") != std::string::npos);
    render::set_streamline_runtime_for_test(nullptr);
}

TEST_CASE("dlss: auto picks it on an NVIDIA GPU, an explicit dlss runs on any GPU, and neither without a usable DLSS") {
    using render::UpscalerCaps;
    using render::UpscalerMode;
    render::UpscalerSettings s;
    UpscalerCaps caps;
    caps.temporal = true;
    caps.gpuVendor = GpuVendor::Nvidia;
    caps.dlss = true;
    s.mode = UpscalerMode::Auto;
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Dlss);
    caps.dlss = false;  // Streamline missing, or a frame it refused
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Temporal);
    caps.dlss = true;
    caps.gpuVendor = GpuVendor::Amd;  // another maker's GPU: auto asks its own SDK
    CHECK(render::effective_upscaler_mode(s, caps) != UpscalerMode::Dlss);
    s.mode = UpscalerMode::Dlss;
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Dlss);
    caps.dlss = false;
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Temporal);
    caps.dlss = true;
    caps.temporal = false;  // a vendor SDK reads the jittered frame
    CHECK(render::effective_upscaler_mode(s, caps) != UpscalerMode::Dlss);
}

TEST_CASE(
    "dlss: the feature row of render.supports takes the provider's answer, and the table says no backend for it") {
    render::FeatureEnv env;
    env.backend = render::FeatureBackend::D3d11;
    std::array<render::VendorProbe, render::kVendorUpscalerCount> answers;
    answers[0].available = false;
    answers[0].reason = "DLSS is not installed: run `factoria setup streamline`.";
    render::set_vendor_upscalers_env(env, answers);
    const int row = render::find_feature("dlss");
    REQUIRE(row >= 0);
    std::string why;
    CHECK_FALSE(render::feature_supported(env, row, &why));
    CHECK(why == answers[0].reason);
    answers[0] = render::VendorProbe{true, ""};
    render::set_vendor_upscalers_env(env, answers);
    CHECK(render::feature_supported(env, row, &why));
    const Json report = render::feature_report(env, "d3d11");
    bool found = false;
    for (const Json& f : report["features"])
        if (f["name"] == "dlss") {
            found = true;
            CHECK(f["supported"] == true);
            CHECK(f["backends"]["D3D11"] ==
                  false);  // DLSS runs on D3D12 and Vulkan, whose columns the table does not have
        }
    CHECK(found);
}

TEST_CASE("dlss: the mode follows the upscale ratio, M76's names land exactly, and a wobble near a boundary does not "
          "flip it") {
    CHECK(render::dlss_mode_for_ratio(1.0f) == sl::kDlssDlaa);
    CHECK(render::dlss_mode_for_ratio(0.5f) == sl::kDlssDlaa);
    CHECK(render::dlss_mode_for_ratio(1.5f) == sl::kDlssMaxQuality);
    CHECK(render::dlss_mode_for_ratio(1.7f) == sl::kDlssBalanced);
    CHECK(render::dlss_mode_for_ratio(2.0f) == sl::kDlssMaxPerformance);
    CHECK(render::dlss_mode_for_ratio(3.0f) == sl::kDlssUltraPerformance);
    CHECK(render::dlss_mode_for_ratio(1.3f) == sl::kDlssUltraQuality);
    CHECK(render::dlss_mode_for_ratio(9.0f) == sl::kDlssUltraPerformance);
    CHECK(render::dlss_mode_for_ratio(1.58f) == sl::kDlssMaxQuality);
    CHECK(render::dlss_mode_for_ratio(1.62f) == sl::kDlssBalanced);
    CHECK(render::dlss_mode_for_ratio(1.62f, sl::kDlssMaxQuality) ==
          sl::kDlssMaxQuality);  // within 0.13 of Quality's 1.5
    CHECK(render::dlss_mode_for_ratio(1.62f, sl::kDlssMaxPerformance) ==
          sl::kDlssBalanced);  // too far from Performance's 2.0
    CHECK(render::dlss_mode_ratio(sl::kDlssMaxPerformance) == doctest::Approx(2.0f));
    CHECK(std::string(render::dlss_mode_name(sl::kDlssDlaa)) == "DLAA");
}

// ---- the provider: frames ----------------------------------------------------------------------------------------------------------

TEST_CASE("dlss D3D12: a frame sets the constants and tags of the frame's token and evaluates inside a native section "
          "with the "
          "declared states") {
    Rig rig(gpu::Backend::D3d12);
    gpu::PresentEvent pe;
    pe.frame = 7;
    rig.runtime.present_end(pe);
    REQUIRE(rig.draw());
    CHECK(rig.frame.error.empty());
    CHECK(in_order(sx.events, {"optimal", "setOptions", "token", "constants", "begin", "tag", "evaluate", "end"}));
    CHECK(sx.frameAsked == 7);
    // The options: Performance mode (ratio 2), the output size, the exposure of the frame, an LDR picture, auto exposure.
    CHECK(sx.options.mode == sl::kDlssMaxPerformance);
    CHECK(sx.options.outputWidth == 320);
    CHECK(sx.options.outputHeight == 180);
    CHECK(sx.options.preExposure == doctest::Approx(1.0f));
    CHECK(sx.options.colorBuffersHdr == sl::kFalse);
    CHECK(sx.options.useAutoExposure == sl::kTrue);
    // The constants.
    CHECK(sx.constantsToken == &sx.tokenMarker);
    CHECK(sx.constants.jitterOffset.x == doctest::Approx(0.25f));
    CHECK(sx.constants.jitterOffset.y == doctest::Approx(-0.125f));
    CHECK(sx.constants.mvecScale.x == 1.0f);
    CHECK(sx.constants.mvecScale.y == 1.0f);
    CHECK(sx.constants.depthInverted == sl::kFalse);
    CHECK(sx.constants.cameraMotionIncluded == sl::kTrue);
    CHECK(sx.constants.motionVectors3d == sl::kFalse);
    CHECK(sx.constants.reset == sl::kTrue);  // the first frame starts the history
    CHECK(sx.constants.cameraAspectRatio == doctest::Approx(320.0f / 180.0f));
    // The tags: colour, depth, motion, output, with the native resources, extents and states, on the frame's token and viewport 0.
    REQUIRE(sx.tags.size() == 4);
    CHECK(sx.tagToken == &sx.tokenMarker);
    CHECK(sx.tagViewport == 0);
    CHECK(sx.tags[0].type == sl::kBufferScalingInputColor);
    CHECK(sx.tags[1].type == sl::kBufferDepth);
    CHECK(sx.tags[2].type == sl::kBufferMotionVectors);
    CHECK(sx.tags[3].type == sl::kBufferScalingOutputColor);
    CHECK(sx.resources[0].native == reinterpret_cast<void*>(std::uintptr_t(rig.color.id) * 16));
    CHECK(sx.resources[1].native == reinterpret_cast<void*>(std::uintptr_t(rig.depth.id) * 16));
    CHECK(sx.resources[2].native == reinterpret_cast<void*>(std::uintptr_t(rig.velocity.id) * 16));
    CHECK(sx.resources[3].native == reinterpret_cast<void*>(std::uintptr_t(rig.output.id) * 16));
    CHECK(sx.resources[0].state == 0xC0);
    CHECK(sx.resources[1].state == 0xC0);
    CHECK(sx.resources[2].state == 0xC0);
    CHECK(sx.resources[3].state == 0x8);
    CHECK(sx.tags[0].extent.width == 160);
    CHECK(sx.tags[0].extent.height == 90);
    CHECK(sx.tags[3].extent.width == 320);
    CHECK(sx.tags[3].extent.height == 180);
    CHECK(sx.tags[0].lifecycle == sl::kOnlyValidNow);
    // The evaluate: DLSS, the same token, the native list the section gave, viewport 0.
    CHECK(sx.evalFeature == sl::kFeatureDlss);
    CHECK(sx.evalToken == &sx.tokenMarker);
    CHECK(sx.evalList == &rig.list.token);
    CHECK(sx.tagList == &rig.list.token);
    CHECK(sx.evalViewport == 0);
    // The section declared the same images in the same states.
    REQUIRE(rig.list.declared.size() == 4);
    CHECK(rig.list.declared[0].image == rig.color);
    CHECK(rig.list.declared[0].state == gpu::NativeState::ShaderRead);
    CHECK(rig.list.declared[3].image == rig.output);
    CHECK(rig.list.declared[3].state == gpu::NativeState::UnorderedAccess);
    CHECK(rig.list.ends == 1);
}

TEST_CASE(
    "dlss: a frame with a reactive mask tags it as the bias hint of the current colour, one without tags the four") {
    Rig rig(gpu::Backend::D3d12);
    REQUIRE(rig.draw());
    CHECK(sx.tags.size() == 4);
    gpu::Image reactive = rig.dev.image(rig.renderW, rig.renderH, gpu::PixelFormat::R8);
    rig.frame.reactive = reactive;
    rig.in.reactive = rig.dev.view(reactive);
    REQUIRE(rig.draw());
    REQUIRE(sx.tags.size() == 5);
    CHECK(sx.tags[4].type == sl::kBufferBiasCurrentColorHint);
    CHECK(sx.resources[4].native == reinterpret_cast<void*>(std::uintptr_t(reactive.id) * 16));
    CHECK(sx.resources[4].state == 0xC0);
    CHECK(sx.tags[4].extent.width == 160);
    REQUIRE(rig.list.declared.size() == 5);
    CHECK(rig.list.declared[4].image == reactive);
    CHECK(rig.list.declared[4].state == gpu::NativeState::ShaderRead);
    rig.dev.destroy_image(reactive);
}

TEST_CASE("dlss: the options are set only when they change, and the history restarts with them") {
    Rig rig(gpu::Backend::D3d12);
    REQUIRE(rig.draw());
    CHECK(sx.setOptionsCalls == 1);
    CHECK(sx.optimalCalls == 1);
    REQUIRE(rig.draw());
    CHECK(sx.setOptionsCalls == 1);
    CHECK(sx.optimalCalls == 1);
    CHECK(sx.constantsCalls == 2);
    CHECK(sx.constants.reset == sl::kFalse);  // the second frame goes on from the first
    rig.in.resetHistory = true;
    REQUIRE(rig.draw());
    CHECK(sx.constants.reset == sl::kTrue);
    rig.in.resetHistory = false;
    rig.in.exposure = 2.0f;  // the camera's exposure changed
    REQUIRE(rig.draw());
    CHECK(sx.setOptionsCalls == 2);
    CHECK(sx.optimalCalls == 1);  // the sizes did not change
    CHECK(sx.options.preExposure == doctest::Approx(2.0f));
    CHECK(sx.constants.reset == sl::kTrue);
    rig.in.linear = true;
    REQUIRE(rig.draw());
    CHECK(sx.setOptionsCalls == 3);
    CHECK(sx.options.colorBuffersHdr == sl::kTrue);
    // A new output size at the same ratio asks DLSS again, and sets the options again.
    rig.resize(240, 135, 480, 270);
    rig.in.exposure = 2.0f;
    rig.in.linear = true;
    REQUIRE(rig.draw());
    CHECK(sx.optimalCalls == 2);
    CHECK(sx.setOptionsCalls == 4);
    CHECK(sx.options.outputWidth == 480);
    // A wobble of the dynamic resolution that stays in the mode's band does not set anything.
    rig.resize(238, 134, 480, 270);
    rig.in.exposure = 2.0f;
    rig.in.linear = true;
    REQUIRE(rig.draw());
    CHECK(sx.setOptionsCalls == 4);
    CHECK(sx.options.mode == sl::kDlssMaxPerformance);
}

TEST_CASE("dlss: the quality names of M76 land on DLSS's modes and a render size outside DLSS's range is refused with "
          "what to do") {
    Rig rig(gpu::Backend::D3d12);
    rig.resize(214, 120, 320, 180);  // 1.5
    REQUIRE(rig.draw());
    CHECK(sx.options.mode == sl::kDlssMaxQuality);
    rig.resize(320, 180, 320, 180);  // 1.0: DLAA
    REQUIRE(rig.draw());
    CHECK(sx.options.mode == sl::kDlssDlaa);
    rig.resize(107, 60, 320, 180);  // 3.0
    REQUIRE(rig.draw());
    CHECK(sx.options.mode == sl::kDlssUltraPerformance);
    // 4:1 is nearest to UltraPerformance, whose render size at 640x360 is 213x120: the frame was drawn at 160x90.
    rig.resize(160, 90, 640, 360);
    const int endsBefore = rig.list.ends;
    CHECK_FALSE(rig.draw());
    CHECK(rig.frame.error.find("213x120") != std::string::npos);
    CHECK(rig.frame.error.find("takes render sizes from ") != std::string::npos);       // the valid range
    CHECK(rig.frame.error.find("the frame was drawn at 160x90") != std::string::npos);  // the size asked for
    CHECK(rig.frame.error.find("render.upscaler.quality") != std::string::npos);
    CHECK(rig.list.ends == endsBefore);  // the section was never opened
    // DLSS says it does not do this size at all.
    sx.optimalOverrideW = 0;
    rig.resize(160, 90, 320, 180);
    sx.optimalRc = sl::kErrorFeatureNotSupported;
    CHECK_FALSE(rig.draw());
    CHECK(rig.frame.error.find("slDLSSGetOptimalSettings") != std::string::npos);
}

TEST_CASE("dlss Vulkan: the images go as Vulkan images and views with their layouts, formats and usage") {
    Rig rig(gpu::Backend::Vulkan);
    REQUIRE(rig.draw());
    REQUIRE(sx.resources.size() == 4);
    CHECK(sx.resources[0].native == reinterpret_cast<void*>(std::uintptr_t(rig.color.id) * 16));
    CHECK(sx.resources[0].view == reinterpret_cast<void*>(std::uintptr_t(rig.colorView.id) * 256));
    CHECK(sx.resources[0].nativeFormat == 37);
    CHECK(sx.resources[0].usage == 0x1B);
    CHECK(sx.resources[0].width == 160);
    CHECK(sx.resources[0].height == 90);
    CHECK(sx.resources[0].mipLevels == 1);
    CHECK(sx.resources[0].arrayLayers == 1);
    CHECK(sx.resources[0].state == 5);  // VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
    CHECK(sx.resources[1].state == 5);
    CHECK(sx.resources[2].state == 5);
    CHECK(sx.resources[3].state == 1);  // VK_IMAGE_LAYOUT_GENERAL (storage image)
    CHECK(sx.resources[3].width == 320);
}

TEST_CASE("dlss: a frame that fails says why, closes its section, and the next frame starts the history again") {
    Rig rig(gpu::Backend::D3d12);
    REQUIRE(rig.draw());
    REQUIRE(rig.draw());
    CHECK(sx.constants.reset == sl::kFalse);

    SUBCASE("slEvaluateFeature") {
        sx.evaluateRc = sl::kErrorDriverOutOfDate;
        CHECK_FALSE(rig.draw());
        CHECK(rig.frame.error.find("slEvaluateFeature") != std::string::npos);
        CHECK(rig.frame.error.find("driver out of date") != std::string::npos);
        CHECK(rig.frame.error.find("Update the NVIDIA") != std::string::npos);
        CHECK(rig.list.ends == 3);  // closed all three times
        sx.evaluateRc = 0;
        REQUIRE(rig.draw());
        CHECK(sx.constants.reset == sl::kTrue);
    }
    SUBCASE("slSetTagForFrame") {
        sx.tagRc = sl::kErrorInvalidState;
        sx.evalFeature = 99;
        CHECK_FALSE(rig.draw());
        CHECK(rig.frame.error.find("slSetTagForFrame") != std::string::npos);
        CHECK(sx.evalFeature == 99);  // never evaluated
        CHECK(rig.list.ends == 3);
    }
    SUBCASE("the frame token") {
        // The token of a frame is asked once, so Streamline is asked again only for a new frame (a present went by).
        gpu::PresentEvent present;
        present.backend = gpu::Backend::D3d12;
        present.frame = 100;
        rig.runtime.present_end(present);
        sx.tokenRc = sl::kErrorInvalidState;
        CHECK_FALSE(rig.draw());
        CHECK(rig.frame.error.find("slGetNewFrameToken") != std::string::npos);
    }
    SUBCASE("slSetConstants") {
        sx.constantsRc = sl::kErrorInvalidState;
        CHECK_FALSE(rig.draw());
        CHECK(rig.frame.error.find("slSetConstants") != std::string::npos);
    }
    SUBCASE("the native section cannot be opened") {
        rig.list.failBegin = true;
        CHECK_FALSE(rig.draw());
        CHECK(rig.frame.error.find("native command section") != std::string::npos);
        CHECK(sx.tags.size() == 4);  // the tags of the earlier frame: nothing was tagged
    }
    SUBCASE("the options") {
        rig.in.exposure = 4.0f;
        sx.setOptionsRc = sl::kErrorInvalidState;
        CHECK_FALSE(rig.draw());
        CHECK(rig.frame.error.find("slDLSSSetOptions") != std::string::npos);
    }
    SUBCASE("a frame without depth") {
        rig.frame.depth = {};
        CHECK_FALSE(rig.draw());
        CHECK(rig.frame.error.find("depth") != std::string::npos);
    }
}

TEST_CASE("dlss: a runtime that is not ready draws nothing and gives Streamline's reason") {
    Rig rig(gpu::Backend::D3d12, false);
    CHECK_FALSE(rig.draw());
    CHECK(rig.frame.error.find("NVIDIA Streamline") != std::string::npos);
    CHECK(count_of(sx.events, "begin") == 0);
}

TEST_CASE("dlss: release turns the options off, frees DLSS's resources after the GPU is idle, and only for the device "
          "it drew on") {
    Rig rig(gpu::Backend::D3d12);
    REQUIRE(rig.draw());
    XDevice other(gpu::Backend::D3d12);
    sx.events.clear();
    rig.dlss->release(other);  // it never drew on this one
    CHECK(sx.events.empty());
    rig.dlss->release(rig.dev);
    CHECK(rig.dev.idles == 1);
    CHECK(in_order(sx.events, {"idle", "setOptions", "free"}));
    CHECK(sx.options.mode == sl::kDlssOff);
    CHECK(sx.frees == 1);
    sx.events.clear();
    rig.dlss->release(rig.dev);  // already released
    CHECK(sx.events.empty());
}

// ---- DLSS Ray Reconstruction (M78-P4c) ----------------------------------------------------------------------------------------------

namespace {

Mat4 mat_from(const sl::Float4x4& f) {
    Mat4 m;
    static_assert(sizeof(f) == sizeof(m.m));
    std::memcpy(m.m, &f, sizeof(m.m));
    return m;
}
bool near_identity(const Mat4& m, float eps = 1e-3f) {
    for (int c = 0; c < 4; ++c)
        for (int r = 0; r < 4; ++r)
            if (std::fabs(m.at(c, r) - (c == r ? 1.0f : 0.0f)) > eps) return false;
    return true;
}

// A frame with the guides and a camera: the images, their views and a real view and projection (with a camera of the frame before).
struct RrFx {
    Rig& rig;
    gpu::Image normalRoughness, diffuse, specular, hwDepth;
    Mat4 view = Mat4::translate({-1.0f, -2.0f, -3.0f});
    Mat4 proj = Mat4::perspective(1.0f, 16.0f / 9.0f, 0.1f, 100.0f, true);
    Mat4 prevFromView = proj * Mat4::translate({0.1f, 0.0f, 0.0f});
    explicit RrFx(Rig& r) : rig(r) {
        normalRoughness = rig.dev.image(rig.renderW, rig.renderH, gpu::PixelFormat::Rgba16F);
        diffuse = rig.dev.image(rig.renderW, rig.renderH, gpu::PixelFormat::Rgba8);
        specular = rig.dev.image(rig.renderW, rig.renderH, gpu::PixelFormat::Rgba8);
        hwDepth = rig.dev.image(rig.renderW, rig.renderH, gpu::PixelFormat::R32F);
        rig.frame.rrDepth = hwDepth;
        rig.in.rrDepth = rig.dev.view(hwDepth);
        rig.frame.normalRoughness = normalRoughness;
        rig.frame.diffuseAlbedo = diffuse;
        rig.frame.specularAlbedo = specular;
        rig.in.normalRoughness = rig.dev.view(normalRoughness);
        rig.in.diffuseAlbedo = rig.dev.view(diffuse);
        rig.in.specularAlbedo = rig.dev.view(specular);
        rig.in.rayReconstruction = true;
        rig.in.linear = true;
        rig.in.cameraFovY = 1.0f;
        render::UpscaleCamera& c = rig.in.camera;
        c.valid = true;
        std::memcpy(c.view, view.m, sizeof(c.view));
        std::memcpy(c.proj, proj.m, sizeof(c.proj));
        std::memcpy(c.prevFromView, prevFromView.m, sizeof(c.prevFromView));
        c.prevValid = true;
        c.position[0] = 1.0f;
        c.position[1] = 2.0f;
        c.position[2] = 3.0f;
        c.nearPlane = 0.1f;
        c.farPlane = 100.0f;
    }
    ~RrFx() {
        for (const gpu::Image i : {normalRoughness, diffuse, specular, hwDepth}) rig.dev.destroy_image(i);
    }
};

}  // namespace

TEST_CASE("dlss ray reconstruction: the probe is DLSS's plus the plugin, and the supports row takes it") {
    sx.reset();
    FakeLoader loader;
    LoaderGuard guard(&loader);
    AdapterFx adapter;
    render::StreamlineRuntime rt({sl::kFeatureDlss},
                                 make_host(adapter));  // the plugin of Ray Reconstruction is not asked
    render::set_streamline_runtime_for_test(&rt);
    std::unique_ptr<render::VendorUpscaler> dlss = render::make_dlss_provider();
    render::VendorEnv env;
    env.backend = gpu::Backend::D3d12;
    env.vendor = GpuVendor::Amd;
    env.windows = true;
    // Not an NVIDIA RTX GPU: DLSS's own reason, said for Ray Reconstruction.
    render::VendorProbe p = dlss->probe_ray_reconstruction(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("Ray Reconstruction") != std::string::npos);
    CHECK(p.reason.find("NVIDIA RTX GPU") != std::string::npos);
    // No Streamline setup.
    env.vendor = GpuVendor::Nvidia;
    loader.installed = false;
    p = dlss->probe_ray_reconstruction(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("factoria setup streamline") != std::string::npos);
    loader.installed = true;
    // Another backend than the one Streamline was started for.
    gpu::D3d12DeviceCreated c;
    run_d3d12(rt, c);
    CHECK(dlss->probe(env).available);
    p = dlss->probe_ray_reconstruction(
        env);  // Super Resolution is there, the plugin of Ray Reconstruction was not asked
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("Ray Reconstruction") != std::string::npos);
    CHECK(p.reason.find("render.upscaler.rayReconstruction") !=
          std::string::npos);  // the project setting and a restart
    CHECK(p.reason.find("restart") != std::string::npos);
    CHECK(std::find(sx.loaded.begin(), sx.loaded.end(), sl::kFeatureDlssRr) ==
          sx.loaded.end());                                             // slInit was not told of the plugin
    CHECK(p.reason.find("render.upscaler.mode") == std::string::npos);  // the flag is the one to set here, not the mode
    // The project asked (the flag is true) but starts in a mode that never draws with DLSS: the hint names the mode, not the flag.
    render::streamline_ask_upscaler_features(rt, false, true);
    p = dlss->probe_ray_reconstruction(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("Ray Reconstruction") != std::string::npos);
    CHECK(p.reason.find("render.upscaler.rayReconstruction is true") != std::string::npos);
    CHECK(p.reason.find("Set render.upscaler.mode to \"dlss\" or \"auto\" in factoria.json and restart") !=
          std::string::npos);
    CHECK(p.reason.find("Set render.upscaler.rayReconstruction") == std::string::npos);
    render::streamline_ask_upscaler_features(rt, false, false);  // the next renderer says nothing of it
    p = dlss->probe_ray_reconstruction(env);
    CHECK(p.reason.find("Set render.upscaler.rayReconstruction to true in factoria.json and restart") !=
          std::string::npos);
    env.backend = gpu::Backend::Vulkan;
    p = dlss->probe_ray_reconstruction(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("D3D12") != std::string::npos);
    rt.device_destroying();
    // The plugin is there: available.
    render::StreamlineRuntime both({sl::kFeatureDlss, sl::kFeatureDlssRr}, make_host(adapter));
    render::set_streamline_runtime_for_test(&both);
    gpu::D3d12DeviceCreated c2;
    run_d3d12(both, c2);
    env.backend = gpu::Backend::D3d12;
    p = dlss->probe_ray_reconstruction(env);
    CHECK(p.available);
    CHECK(p.reason.empty());
    // The plugin refused by Streamline (the GPU or the driver): its reason, for Ray Reconstruction only.
    both.device_destroying();
    sx.supportedRc = sl::kErrorDriverOutOfDate;
    gpu::D3d12DeviceCreated c3;
    run_d3d12(both, c3);
    p = dlss->probe_ray_reconstruction(env);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("Ray Reconstruction") != std::string::npos);
    render::set_streamline_runtime_for_test(nullptr);

    // The supports row: the providers' answer, named dlssRayReconstruction, and the machine's reason is the row's.
    render::FeatureEnv fenv;
    fenv.backend = render::FeatureBackend::D3d11;
    std::array<render::VendorProbe, render::kVendorUpscalerCount> answers;
    answers[0] = render::VendorProbe{true, ""};
    render::VendorProbe rr;
    rr.reason = "DLSS Ray Reconstruction is not available on this machine: the plugin is missing.";
    render::set_vendor_upscalers_env(fenv, answers, rr);
    const int row = render::find_feature("dlssRayReconstruction");
    REQUIRE(row >= 0);
    std::string why;
    CHECK_FALSE(render::feature_supported(fenv, row, &why));
    CHECK(why == rr.reason);
    CHECK(render::feature_supported(fenv, render::find_feature("dlss"), &why));  // Super Resolution is not affected
    rr = render::VendorProbe{true, ""};
    render::set_vendor_upscalers_env(fenv, answers, rr);
    CHECK(render::feature_supported(fenv, row, &why));
}

TEST_CASE(
    "dlss ray reconstruction D3D12: the feature switches to Ray Reconstruction, which is tagged with its seven buffers "
    "and told the camera") {
    Rig rig(gpu::Backend::D3d12);
    RrFx fx(rig);
    REQUIRE(rig.draw());
    CHECK(rig.frame.error.empty());
    CHECK(rig.frame.usedRayReconstruction);
    CHECK(rig.frame.rayReconstructionFallback.empty());
    CHECK(in_order(sx.events, {"rrOptimal", "rrSetOptions", "token", "constants", "begin", "tag", "evaluate", "end"}));
    // The feature of the evaluate is Ray Reconstruction, and Super Resolution's options were never touched.
    CHECK(sx.evalFeature == sl::kFeatureDlssRr);
    REQUIRE(sx.evalFeatures.size() == 1);
    CHECK(sx.setOptionsCalls == 0);
    CHECK(sx.optimalCalls == 0);
    // The tags: the colour, depth, motion and output, then the three guides.
    REQUIRE(sx.tags.size() == 7);
    CHECK(sx.tags[0].type == sl::kBufferScalingInputColor);
    CHECK(sx.tags[1].type == sl::kBufferDepth);
    CHECK(sx.tags[2].type == sl::kBufferMotionVectors);
    CHECK(sx.tags[3].type == sl::kBufferScalingOutputColor);
    CHECK(sx.tags[4].type == sl::kBufferAlbedo);
    CHECK(sx.tags[5].type == sl::kBufferSpecularAlbedo);
    CHECK(sx.tags[6].type == sl::kBufferNormalRoughness);
    // The depth tagged is the one made from the projection the constants carry, not the d / (d + 1) of Super Resolution.
    CHECK(sx.resources[1].native == reinterpret_cast<void*>(std::uintptr_t(fx.hwDepth.id) * 16));
    CHECK(sx.resources[1].native != reinterpret_cast<void*>(std::uintptr_t(rig.depth.id) * 16));
    CHECK(sx.constants.depthInverted == sl::kFalse);
    CHECK(sx.resources[4].native == reinterpret_cast<void*>(std::uintptr_t(fx.diffuse.id) * 16));
    CHECK(sx.resources[5].native == reinterpret_cast<void*>(std::uintptr_t(fx.specular.id) * 16));
    CHECK(sx.resources[6].native == reinterpret_cast<void*>(std::uintptr_t(fx.normalRoughness.id) * 16));
    for (int i = 4; i < 7; ++i) {
        CHECK(sx.resources[i].state == 0xC0);  // read by DLSS
        CHECK(sx.tags[i].extent.width == 160);
        CHECK(sx.tags[i].extent.height == 90);
        CHECK(sx.tags[i].lifecycle == sl::kOnlyValidNow);
    }
    REQUIRE(rig.list.declared.size() == 7);
    CHECK(rig.list.declared[6].image == fx.normalRoughness);
    CHECK(rig.list.declared[6].state == gpu::NativeState::ShaderRead);
    CHECK(rig.list.declared[3].state == gpu::NativeState::UnorderedAccess);
    // The options: the mode of the ratio, packed normals and roughness, HDR, the output size, the camera's view and its inverse.
    CHECK(sx.rrOptions.mode == sl::kDlssMaxPerformance);
    CHECK(sx.rrOptions.outputWidth == 320);
    CHECK(sx.rrOptions.outputHeight == 180);
    CHECK(sx.rrOptions.normalRoughnessMode == sl::kDlssdNormalRoughnessPacked);
    CHECK(sx.rrOptions.colorBuffersHdr == sl::kTrue);
    CHECK(sx.rrOptions.sharpness == 0.0f);
    CHECK(std::memcmp(&sx.rrOptions.worldToCameraView, fx.view.m, sizeof(fx.view.m)) == 0);
    CHECK(near_identity(mat_from(sx.rrOptions.cameraViewToWorld) * mat_from(sx.rrOptions.worldToCameraView)));
    // The constants: the camera's real matrices and frame, and the motion reprojected with the frame before.
    CHECK(std::memcmp(&sx.constants.cameraViewToClip, fx.proj.m, sizeof(fx.proj.m)) == 0);
    CHECK(near_identity(mat_from(sx.constants.clipToCameraView) * mat_from(sx.constants.cameraViewToClip)));
    const Mat4 clipToPrev = mat_from(sx.constants.clipToPrevClip);
    CHECK(near_identity(clipToPrev * fx.proj * fx.prevFromView.inverse()));
    CHECK(near_identity(mat_from(sx.constants.prevClipToClip) * clipToPrev));
    CHECK(sx.constants.cameraPos.x == doctest::Approx(1.0f));
    CHECK(sx.constants.cameraPos.z == doctest::Approx(3.0f));
    CHECK(sx.constants.cameraNear == doctest::Approx(0.1f));
    CHECK(sx.constants.cameraFar == doctest::Approx(100.0f));
    CHECK(sx.constants.cameraFov == doctest::Approx(1.0f));
    CHECK(sx.constants.orthographicProjection == sl::kFalse);
    CHECK(sx.constants.reset == sl::kTrue);  // the first frame starts the history
    // A second frame: the options go again (the matrices move with the camera) and the history goes on.
    REQUIRE(rig.draw());
    CHECK(sx.rrSetOptionsCalls == 2);
    CHECK(sx.rrOptimalCalls == 1);
    CHECK(sx.constants.reset == sl::kFalse);
    // A cut (no camera of the frame before): the history starts again.
    rig.in.camera.prevValid = false;
    REQUIRE(rig.draw());
    CHECK(sx.constants.reset == sl::kTrue);
}

TEST_CASE("dlss ray reconstruction: a frame it cannot draw falls to Super Resolution and says why") {
    Rig rig(gpu::Backend::D3d12);
    RrFx fx(rig);
    SUBCASE("Streamline refuses the evaluate of the feature") {
        sx.rrEvaluateRc = sl::kErrorDriverOutOfDate;
        REQUIRE(rig.draw());
        CHECK_FALSE(rig.frame.usedRayReconstruction);
        CHECK(rig.frame.rayReconstructionFallback.find("Ray Reconstruction") != std::string::npos);
        CHECK(rig.frame.rayReconstructionFallback.find("slEvaluateFeature") != std::string::npos);
        REQUIRE(sx.evalFeatures.size() == 2);
        CHECK(sx.evalFeatures[0] == sl::kFeatureDlssRr);
        CHECK(sx.evalFeatures[1] == sl::kFeatureDlss);
        CHECK(sx.tags.size() == 4);  // the Super Resolution frame is tagged with its four buffers
        CHECK(sx.constants.reset == sl::kTrue);
        CHECK(rig.list.ends == 2);  // both native sections were closed
        // The next frame, asked for Super Resolution by the renderer, goes on from the Super Resolution frame.
        rig.in.rayReconstruction = false;
        REQUIRE(rig.draw());
        CHECK(rig.frame.rayReconstructionFallback.empty());
        CHECK(sx.evalFeature == sl::kFeatureDlss);
        CHECK(sx.constants.reset == sl::kFalse);
    }
    SUBCASE("the plugin's functions are missing") {
        sx.rrFunctionRc = sl::kErrorFeatureMissing;
        REQUIRE(rig.draw());
        CHECK_FALSE(rig.frame.usedRayReconstruction);
        CHECK(rig.frame.rayReconstructionFallback.find("slDLSSDSetOptions") != std::string::npos);
        CHECK(sx.evalFeature == sl::kFeatureDlss);
        CHECK(sx.rrSetOptionsCalls == 0);
    }
    SUBCASE("the options are refused") {
        sx.rrSetOptionsRc = sl::kErrorInvalidState;
        REQUIRE(rig.draw());
        CHECK_FALSE(rig.frame.usedRayReconstruction);
        CHECK(rig.frame.rayReconstructionFallback.find("slDLSSDSetOptions") != std::string::npos);
        CHECK(sx.evalFeature == sl::kFeatureDlss);
    }
    SUBCASE("the frame has no guides") {
        rig.frame.normalRoughness = {};
        REQUIRE(rig.draw());
        CHECK_FALSE(rig.frame.usedRayReconstruction);
        CHECK(rig.frame.rayReconstructionFallback.find("guide") != std::string::npos);
        CHECK(sx.evalFeature == sl::kFeatureDlss);
        CHECK(sx.rrSetOptionsCalls == 0);
    }
    SUBCASE("the frame has no camera") {
        rig.in.camera.valid = false;
        REQUIRE(rig.draw());
        CHECK(rig.frame.rayReconstructionFallback.find("camera") != std::string::npos);
        CHECK(sx.evalFeature == sl::kFeatureDlss);
    }
    SUBCASE("the colour is not linear HDR") {
        rig.in.linear = false;
        REQUIRE(rig.draw());
        CHECK(rig.frame.rayReconstructionFallback.find("linear HDR") != std::string::npos);
        CHECK(sx.evalFeature == sl::kFeatureDlss);
    }
    SUBCASE("a dynamic resolution") {
        rig.in.dynamicResolution = true;
        REQUIRE(rig.draw());
        CHECK(rig.frame.rayReconstructionFallback.find("dynamic resolution") != std::string::npos);
        CHECK(sx.evalFeature == sl::kFeatureDlss);
    }
    SUBCASE("a render size outside the range of the mode") {
        // Ray Reconstruction answers the sizes of its mode: a frame drawn at another one is refused, and Super Resolution says its own.
        rig.resize(100, 90, 320, 180);
        RrFx other(rig);
        REQUIRE_FALSE(rig.draw());  // neither accepts the size
        CHECK(rig.frame.error.find("Choose another") != std::string::npos);
        CHECK(rig.frame.rayReconstructionFallback.find("DLSS Ray Reconstruction's") != std::string::npos);
    }
    SUBCASE("the Super Resolution frames never touch Ray Reconstruction") {
        rig.in.rayReconstruction = false;
        REQUIRE(rig.draw());
        CHECK(sx.rrSetOptionsCalls == 0);
        CHECK(sx.rrOptimalCalls == 0);
        CHECK(sx.tags.size() == 4);
        CHECK(sx.evalFeature == sl::kFeatureDlss);
    }
}

TEST_CASE("dlss ray reconstruction: switching between it and Super Resolution starts the history again, and a lost "
          "device starts everything again") {
    Rig rig(gpu::Backend::D3d12);
    RrFx fx(rig);
    REQUIRE(rig.draw());
    REQUIRE(rig.draw());
    CHECK(sx.constants.reset == sl::kFalse);
    rig.in.rayReconstruction = false;  // a frame the renderer cannot give the guides to
    REQUIRE(rig.draw());
    CHECK(sx.evalFeature == sl::kFeatureDlss);
    CHECK(sx.constants.reset == sl::kTrue);
    REQUIRE(rig.draw());
    CHECK(sx.constants.reset == sl::kFalse);
    rig.in.rayReconstruction = true;
    REQUIRE(rig.draw());
    CHECK(sx.evalFeature == sl::kFeatureDlssRr);
    CHECK(sx.constants.reset == sl::kTrue);

    // The device is lost: nothing draws until Streamline starts again, and then the options are asked again from the start.
    rig.runtime.device_destroying();
    CHECK_FALSE(rig.draw());
    CHECK(rig.frame.error.find("Streamline") != std::string::npos);
    const int optimalBefore = sx.rrOptimalCalls;
    gpu::D3d12DeviceCreated c;
    run_d3d12(rig.runtime, c);
    REQUIRE(rig.runtime.status().ready);
    REQUIRE(rig.draw());
    CHECK(rig.frame.usedRayReconstruction);
    CHECK(sx.rrOptimalCalls == optimalBefore + 1);
    CHECK(sx.constants.reset == sl::kTrue);
}

TEST_CASE("dlss ray reconstruction: release turns its options off and frees both features") {
    Rig rig(gpu::Backend::D3d12);
    {
        RrFx fx(rig);
        REQUIRE(rig.draw());
        sx.events.clear();
        sx.frees = 0;
        rig.dlss->release(rig.dev);
        CHECK(in_order(sx.events, {"idle", "rrSetOptions", "free"}));
        CHECK(sx.rrOptions.mode == sl::kDlssOff);
        CHECK(sx.frees == 2);
    }
}

TEST_CASE("dlss ray reconstruction D3D12: a provider without the feature (the others) says it has none") {
    // The default of VendorUpscaler::probe_ray_reconstruction: only DLSS has a ray reconstruction.
    class Plain final : public render::VendorUpscaler {
    public:
        std::string_view name() const override { return "Plain"; }
        std::string_view mode() const override { return "xess"; }
        std::string_view setup_id() const override { return "xess"; }
        unsigned backends() const override { return 0; }
        render::VendorProbe probe(const render::VendorEnv&) override { return {true, ""}; }
        bool upscale(const render::UpscaleInput&, render::VendorFrame&) override { return false; }
    } plain;
    const render::VendorProbe p = plain.probe_ray_reconstruction(render::VendorEnv{});
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("Plain") != std::string::npos);
}

TEST_CASE("dlss ray reconstruction: the depth guide is the hardware depth of the projection the constants carry") {
    // The guides shader writes clip z / clip w from the projection's depth terms (shaders/upscale_rr.glsl): a known view distance must land
    // where the projection puts it, because Streamline rebuilds the view position from this depth and the matrices it is told.
    const Mat4 proj = Mat4::perspective(60.0f, 16.0f / 9.0f, 0.1f, 100.0f, true);
    float terms[4];
    render::rr_depth_terms(proj, terms);
    for (const float d : {0.1f, 0.5f, 1.0f, 7.5f, 42.0f, 100.0f}) {
        const float viaMatrix = [&] {
            const float z = -d;  // a point d in front of the camera, on its axis
            const float clipZ = proj.at(2, 2) * z + proj.at(3, 2);
            const float clipW = proj.at(2, 3) * z + proj.at(3, 3);
            return clipZ / clipW;
        }();
        CHECK(render::rr_hardware_depth(terms, d, true) == doctest::Approx(viaMatrix).epsilon(1e-5));
    }
    CHECK(std::fabs(render::rr_hardware_depth(terms, 0.1f, true)) < 1e-4f);                        // the near plane
    CHECK(render::rr_hardware_depth(terms, 100.0f, true) == doctest::Approx(1.0f).epsilon(1e-4));  // the far plane
    CHECK(render::rr_hardware_depth(terms, 5.0f, false) == 1.0f);                                  // the sky
    // Streamline's own inverse: clipToCameraView of the constants maps (x, y, depth) back to the view distance it came from.
    Rig rig(gpu::Backend::D3d12);
    RrFx fx(rig);
    fx.proj = proj;
    std::memcpy(rig.in.camera.proj, proj.m, sizeof(rig.in.camera.proj));
    REQUIRE(rig.draw());
    REQUIRE(rig.frame.usedRayReconstruction);
    const Mat4 clipToView = mat_from(sx.constants.clipToCameraView);
    const float d = 12.0f;
    const float ndcDepth = render::rr_hardware_depth(terms, d, true);
    const Vec4 clip{0.0f, 0.0f, ndcDepth, 1.0f};  // a point on the view axis, with w = 1 before the divide
    const Vec4 v = clipToView * clip;
    CHECK(-v.z / v.w == doctest::Approx(d).epsilon(1e-3));
}
