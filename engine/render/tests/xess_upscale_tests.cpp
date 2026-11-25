// M78-P4a: the XeSS provider (src/render_upscale_xess.{h,cpp}). No Intel library is involved: the functions of XeSS are fakes in a table the
// provider takes from a fake VendorLibrary (the way it takes the real ones), and the device is a RecordingDevice that answers a backend and
// native handles. What is tested is what the provider asks of XeSS: when it is available, when its context is made, initialised again and
// destroyed, what each frame passes (jitter, exposure, reset, sizes, resources) and in which order with the native section, and what a
// failure does. That the real library draws the right picture is for a machine with an Intel, NVIDIA or AMD GPU on D3D12 or Vulkan.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <limits>
#include <array>
#include <map>
#include <memory>
#include <span>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "gpu/recording_device.h"
#include "render_features.h"
#include "render_upscale_vendor.h"
#include "render_upscale_xess.h"

using namespace fa;
using render::GpuVendor;
using render::XessApi;
namespace abi = fa::render::xess_abi;

namespace {

// ---- the fake library ---------------------------------------------------------------------------------------------------------------

// What the fake functions saw, in order and by number.
struct Fx {
    abi::Version version{3, 1, 0, 0};
    std::int32_t versionRc = 0, createRc = 0, initRc = 0, executeRc = 0;
    int creates = 0, inits = 0, executes = 0, destroys = 0, velocityScales = 0;
    float velocityScaleX = 0.0f, velocityScaleY = 0.0f;
    abi::D3d12InitParams init12{};
    abi::D3d11InitParams init11{};
    abi::VkInitParams initVk{};
    abi::D3d12ExecuteParams exec12{};
    abi::D3d11ExecuteParams exec11{};
    abi::VkExecuteParams execVk{};
    const void* executeList = nullptr;
    std::vector<std::string> events;  // "create", "init", "begin", "execute", "end", "destroy", "idle"
    std::vector<std::string> instanceExtensions, deviceExtensions;
    std::uint32_t minApiVersion = 0;
    int tokenStorage = 0;
    void reset() { *this = Fx{}; }
};
Fx fx;

abi::Context fake_context() { return reinterpret_cast<abi::Context>(&fx.tokenStorage); }

std::int32_t fake_get_version(abi::Version* v) {
    *v = fx.version;
    return fx.versionRc;
}
std::int32_t fake_destroy(abi::Context) {
    ++fx.destroys;
    fx.events.push_back("destroy");
    return 0;
}
std::int32_t fake_velocity_scale(abi::Context, float x, float y) {
    ++fx.velocityScales;
    fx.velocityScaleX = x;
    fx.velocityScaleY = y;
    return 0;
}
std::int32_t fake_create(void*, abi::Context* out) {
    ++fx.creates;
    fx.events.push_back("create");
    if (fx.createRc >= 0) *out = fake_context();
    return fx.createRc;
}
std::int32_t fake_vk_create(void*, void*, void*, abi::Context* out) { return fake_create(nullptr, out); }
std::int32_t fake_init12(abi::Context, const abi::D3d12InitParams* p) {
    ++fx.inits;
    fx.events.push_back("init");
    fx.init12 = *p;
    return fx.initRc;
}
std::int32_t fake_init11(abi::Context, const abi::D3d11InitParams* p) {
    ++fx.inits;
    fx.events.push_back("init");
    fx.init11 = *p;
    return fx.initRc;
}
std::int32_t fake_init_vk(abi::Context, const abi::VkInitParams* p) {
    ++fx.inits;
    fx.events.push_back("init");
    fx.initVk = *p;
    return fx.initRc;
}
std::int32_t fake_execute12(abi::Context, void* list, const abi::D3d12ExecuteParams* p) {
    ++fx.executes;
    fx.events.push_back("execute");
    fx.executeList = list;
    fx.exec12 = *p;
    return fx.executeRc;
}
std::int32_t fake_execute11(abi::Context, const abi::D3d11ExecuteParams* p) {
    ++fx.executes;
    fx.events.push_back("execute");
    fx.exec11 = *p;
    return fx.executeRc;
}
std::int32_t fake_execute_vk(abi::Context, void* list, const abi::VkExecuteParams* p) {
    ++fx.executes;
    fx.events.push_back("execute");
    fx.executeList = list;
    fx.execVk = *p;
    return fx.executeRc;
}
// The Vulkan requirements: the lists of Fx, handed out as C strings that live as long as the fake.
std::vector<const char*> g_instanceNames, g_deviceNames;
std::int32_t fake_vk_instance_extensions(std::uint32_t* count, const char* const** names, std::uint32_t* minApi) {
    g_instanceNames.clear();
    for (const std::string& s : fx.instanceExtensions) g_instanceNames.push_back(s.c_str());
    *count = std::uint32_t(g_instanceNames.size());
    *names = g_instanceNames.data();
    *minApi = fx.minApiVersion;
    return 0;
}
std::int32_t fake_vk_device_extensions(void*, void*, std::uint32_t* count, const char* const** names) {
    g_deviceNames.clear();
    for (const std::string& s : fx.deviceExtensions) g_deviceNames.push_back(s.c_str());
    *count = std::uint32_t(g_deviceNames.size());
    *names = g_deviceNames.data();
    return 0;
}

class FakeLibrary final : public render::VendorLibrary {
public:
    explicit FakeLibrary(std::vector<std::string> hidden) : hidden_(std::move(hidden)) {
        table_["xessGetVersion"] = reinterpret_cast<void*>(&fake_get_version);
        table_["xessDestroyContext"] = reinterpret_cast<void*>(&fake_destroy);
        table_["xessSetVelocityScale"] = reinterpret_cast<void*>(&fake_velocity_scale);
        table_["xessD3D12CreateContext"] = reinterpret_cast<void*>(&fake_create);
        table_["xessD3D12Init"] = reinterpret_cast<void*>(&fake_init12);
        table_["xessD3D12Execute"] = reinterpret_cast<void*>(&fake_execute12);
        table_["xessD3D11CreateContext"] = reinterpret_cast<void*>(&fake_create);
        table_["xessD3D11Init"] = reinterpret_cast<void*>(&fake_init11);
        table_["xessD3D11Execute"] = reinterpret_cast<void*>(&fake_execute11);
        table_["xessVKGetRequiredInstanceExtensions"] = reinterpret_cast<void*>(&fake_vk_instance_extensions);
        table_["xessVKGetRequiredDeviceExtensions"] = reinterpret_cast<void*>(&fake_vk_device_extensions);
        table_["xessVKCreateContext"] = reinterpret_cast<void*>(&fake_vk_create);
        table_["xessVKInit"] = reinterpret_cast<void*>(&fake_init_vk);
        table_["xessVKExecute"] = reinterpret_cast<void*>(&fake_execute_vk);
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
    std::string path_ = "fake/libxess.dll";
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

// ---- the fake device and command list -----------------------------------------------------------------------------------------------

// A RecordingDevice that says it is another backend, gives native handles that name the resource (the image id times 16, so a test reads
// which image reached XeSS) and counts the times the GPU was waited for.
class XDevice : public gpu::RecordingDevice {
public:
    explicit XDevice(gpu::Backend backend, std::uint32_t pciVendor = 0x8086) : backend_(backend) {
        info_ = gpu::RecordingDevice::info();
        info_.backend = backend;
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
        n.apiVersion = apiVersion;
        return n;
    }
    gpu::NativeImage native_image(gpu::Image image) const override {
        gpu::NativeImage n;
        if (!image.valid()) return n;
        n.resource = reinterpret_cast<const void*>(std::uintptr_t(image.id) * 16);
        n.vkImage = std::uint64_t(image.id) * 16;
        return n;
    }
    gpu::NativeView native_view(gpu::View view) const override {
        gpu::NativeView n;
        if (!view.valid()) return n;
        n.vkImageView = std::uint64_t(view.id) * 256;
        n.nativeFormat = 37;  // VK_FORMAT_R8G8B8A8_UNORM
        n.image = viewImage.count(view.id) ? viewImage.at(view.id) : gpu::Image{};
        return n;
    }
    Result<void> wait_idle() override {
        ++idles;
        fx.events.push_back("idle");
        return {};
    }
    // The image each view was made over.
    std::map<std::uint32_t, gpu::Image> viewImage;
    int idles = 0;
    std::uint32_t apiVersion = (1u << 22) | (3u << 12);  // Vulkan 1.3

    gpu::Image image(int w, int h, gpu::PixelFormat format, bool storage = false) {
        gpu::ImageDesc d;
        d.width = w;
        d.height = h;
        d.pixelFormat = format;
        d.usage.storageImage = storage;
        d.label = "xess-test";
        return make_image(d);
    }
    gpu::View view(gpu::Image image) {
        gpu::ViewDesc v;
        v.texture.image = image;
        return make_view(v);
    }
    // Remembers the image of every view (the provider's own storage views too), so native_view can name it.
    gpu::View make_view(const gpu::ViewDesc& desc) override {
        const gpu::View made = gpu::RecordingDevice::make_view(desc);
        viewImage[made.id] = desc.texture.image.valid() ? desc.texture.image : desc.storageImage.image;
        return made;
    }

private:
    gpu::Backend backend_;
    gpu::DeviceInfo info_{};
};

// A list whose native section is a fake: it records what was declared and, in `fx.events`, when.
class XList final : public gpu::RecordingCommandList {
public:
    XList(XDevice& device, gpu::Backend backend) : gpu::RecordingCommandList(device), backend_(backend) {}
    Result<gpu::NativeCommands> begin_native(std::span<const gpu::NativeUse> uses) override {
        fx.events.push_back("begin");
        if (failBegin) return make_error("the fake list refuses a native section", "none");
        declared.assign(uses.begin(), uses.end());
        gpu::NativeCommands n;
        n.backend = backend_;
        n.list = &token;
        return n;
    }
    Result<void> end_native(std::span<const gpu::NativeUse>) override {
        fx.events.push_back("end");
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

// One frame's worth of everything: a device, a list, the images, the input and the provider under test (its own instance, not the process's).
struct Rig {
    FakeLoader loader;
    LoaderGuard guard{&loader};
    XDevice dev;
    XList list;
    std::unique_ptr<render::VendorUpscaler> xess = render::make_xess_provider();
    gpu::Image color, depth, velocity, output, reactive;
    gpu::View colorView, depthView, velocityView, reactiveView;
    render::UpscaleInput in;
    render::VendorFrame frame;
    int renderW = 160, renderH = 90, outW = 320, outH = 180;

    explicit Rig(gpu::Backend backend, std::uint32_t pciVendor = 0x8086) : dev(backend, pciVendor), list(dev, backend) {
        fx.reset();
        setup_images();
    }
    ~Rig() {
        xess->release(dev);
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
        in.linear = false;
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
        for (const gpu::Image i : {color, depth, velocity, output, reactive})
            if (i.valid()) dev.destroy_image(i);
    }
    // Changes the render and output sizes (new images; the old ones are destroyed after the provider let go).
    void resize(int rw, int rh, int ow, int oh) {
        free_images();
        reactive = {};
        renderW = rw;
        renderH = rh;
        outW = ow;
        outH = oh;
        setup_images();
    }
    render::VendorEnv env(GpuVendor vendor) const {
        render::VendorEnv e;
        e.backend = dev.backend();
        e.vendor = vendor;
        e.device = &dev;
        e.windows = true;
        return e;
    }
    bool draw() { return xess->upscale(in, frame); }
    int count(const char* event) const { return int(std::count(fx.events.begin(), fx.events.end(), event)); }
};

}  // namespace

// ---- the pure parts ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("xess: the quality setting follows the upscale ratio, M76's five names land exactly, and a wobble near a boundary does not flip it") {
    CHECK(render::xess_quality_for_ratio(1.0f) == abi::kQualityAa);
    CHECK(render::xess_quality_for_ratio(0.5f) == abi::kQualityAa);  // never an upscale below 1
    CHECK(render::xess_quality_for_ratio(1.5f) == abi::kQualityUltraQuality);
    CHECK(render::xess_quality_for_ratio(1.7f) == abi::kQualityQuality);
    CHECK(render::xess_quality_for_ratio(2.0f) == abi::kQualityBalanced);
    CHECK(render::xess_quality_for_ratio(3.0f) == abi::kQualityUltraPerformance);
    CHECK(render::xess_quality_for_ratio(2.3f) == abi::kQualityPerformance);
    CHECK(render::xess_quality_for_ratio(1.3f) == abi::kQualityUltraQualityPlus);
    CHECK(render::xess_quality_for_ratio(5.0f) == abi::kQualityUltraPerformance);
    CHECK(render::xess_quality_for_ratio(std::numeric_limits<float>::quiet_NaN()) == abi::kQualityAa);
    // The setting in use is kept while the ratio is within 0.15 of it.
    CHECK(render::xess_quality_for_ratio(1.62f) == abi::kQualityQuality);
    CHECK(render::xess_quality_for_ratio(1.62f, abi::kQualityUltraQuality) == abi::kQualityUltraQuality);
    CHECK(render::xess_quality_for_ratio(1.62f, abi::kQualityBalanced) == abi::kQualityQuality);  // too far from Balanced's 2.0
    CHECK(render::xess_quality_ratio(abi::kQualityPerformance) == doctest::Approx(2.3f));
    CHECK(render::xess_quality_ratio(0) == 0.0f);
    CHECK(render::xess_result_text(-1) == "unsupported device");
    CHECK(render::xess_result_text(-77) == "result -77");
}

TEST_CASE("xess: the PCI vendor ids decide the GPU maker the providers see") {
    gpu::GpuIdentity id;
    CHECK(render::gpu_vendor_from_identity(id) == GpuVendor::None);  // no identity at all
    id.vendorId = 0x10DE;
    CHECK(render::gpu_vendor_from_identity(id) == GpuVendor::Nvidia);
    id.vendorId = 0x1002;
    CHECK(render::gpu_vendor_from_identity(id) == GpuVendor::Amd);
    id.vendorId = 0x8086;
    CHECK(render::gpu_vendor_from_identity(id) == GpuVendor::Intel);
    id.vendorId = 0x106B;
    CHECK(render::gpu_vendor_from_identity(id) == GpuVendor::Apple);
    id.vendorId = 0x1414;  // Microsoft's WARP
    CHECK(render::gpu_vendor_from_identity(id) == GpuVendor::Other);

    XDevice intel(gpu::Backend::D3d12, 0x8086), nvidia(gpu::Backend::Vulkan, 0x10DE), warp(gpu::Backend::D3d11, 0x1414);
    CHECK(render::gpu_vendor_of(intel) == GpuVendor::Intel);
    CHECK(render::gpu_vendor_of(nvidia) == GpuVendor::Nvidia);
    CHECK(render::gpu_vendor_of(warp) == GpuVendor::Other);
    CHECK(render::vendor_env_of(intel).vendor == GpuVendor::Intel);
    CHECK(render::vendor_env_of(intel).device == &intel);
    gpu::RecordingDevice recording;
    CHECK(render::gpu_vendor_of(recording) == GpuVendor::None);
}

// ---- the probe --------------------------------------------------------------------------------------------------------------------------

TEST_CASE("xess probe: D3D12 and Vulkan run on any GPU, D3D11 on Intel only, and every refusal says what to do") {
    Rig d12(gpu::Backend::D3d12);
    for (const GpuVendor v : {GpuVendor::Intel, GpuVendor::Nvidia, GpuVendor::Amd, GpuVendor::Other}) {
        const render::VendorProbe p = d12.xess->probe(d12.env(v));
        CHECK_MESSAGE(p.available, p.reason);
        CHECK(p.reason.empty());
    }
    CHECK(d12.loader.askedFiles.back() == "libxess.dll");

    Rig d11(gpu::Backend::D3d11);
    CHECK(d11.xess->probe(d11.env(GpuVendor::Intel)).available);
    CHECK(d11.loader.askedFiles.back() == "libxess_dx11.dll");  // the Direct3D 11 library is another file
    const render::VendorProbe nv = d11.xess->probe(d11.env(GpuVendor::Nvidia));
    CHECK_FALSE(nv.available);
    CHECK(nv.reason.find("Intel Arc") != std::string::npos);
    CHECK(nv.reason.find("NVIDIA") != std::string::npos);
    CHECK(nv.reason.find("Direct3D 12 or Vulkan") != std::string::npos);

    Rig gl(gpu::Backend::Gl);
    const render::VendorProbe onGl = gl.xess->probe(gl.env(GpuVendor::Intel));
    CHECK_FALSE(onGl.available);
    CHECK(onGl.reason.find("OpenGL") != std::string::npos);
    render::VendorEnv notWindows = d12.env(GpuVendor::Intel);
    notWindows.windows = false;
    CHECK(d12.xess->probe(notWindows).reason.find("Windows") != std::string::npos);
}

TEST_CASE("xess probe: a missing, unloadable, incomplete or too old library is refused with the way to fix it") {
    Rig r(gpu::Backend::D3d12);
    r.loader.installed = false;
    render::VendorProbe p = r.xess->probe(r.env(GpuVendor::Intel));
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("factoria setup xess") != std::string::npos);
    CHECK(p.reason.find("the fake loader has no library") != std::string::npos);

    r.loader.installed = true;
    r.loader.loads = false;
    p = r.xess->probe(r.env(GpuVendor::Intel));
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("cannot load it") != std::string::npos);
    CHECK(p.reason.find("factoria setup xess") != std::string::npos);

    r.loader.loads = true;
    r.loader.hidden = {"xessD3D12Execute"};
    p = r.xess->probe(r.env(GpuVendor::Intel));
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("xessD3D12Execute") != std::string::npos);
    // An export of another backend is not needed.
    r.loader.hidden = {"xessVKInit", "xessD3D11Execute"};
    CHECK(r.xess->probe(r.env(GpuVendor::Intel)).available);

    r.loader.hidden.clear();
    fx.version = {2, 0, 1, 0};
    p = r.xess->probe(r.env(GpuVendor::Intel));
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("2.0.1") != std::string::npos);
    CHECK(p.reason.find("3.0") != std::string::npos);
    fx.version = {3, 0, 0, 0};
    CHECK(r.xess->probe(r.env(GpuVendor::Intel)).available);
    fx.version = {3, 1, 0, 0};
    fx.versionRc = -6;
    p = r.xess->probe(r.env(GpuVendor::Intel));
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("device error") != std::string::npos);
}

TEST_CASE("xess probe: on Vulkan the extensions XeSS asks for must be enabled, and the API version must reach what it needs") {
    Rig r(gpu::Backend::Vulkan, 0x10DE);
    fx.instanceExtensions = {"VK_KHR_get_physical_device_properties2"};
    fx.deviceExtensions = {"VK_KHR_driver_properties", "VK_EXT_subgroup_size_control"};
    fx.minApiVersion = (1u << 22) | (1u << 12);
    render::VendorEnv e = r.env(GpuVendor::Nvidia);
    render::VendorProbe p = r.xess->probe(e);  // the engine enables none of them yet
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("VK_KHR_get_physical_device_properties2 (instance)") != std::string::npos);
    CHECK(p.reason.find("VK_EXT_subgroup_size_control (device)") != std::string::npos);
    CHECK(p.reason.find("Direct3D 12") != std::string::npos);
    e.vulkanInstanceExtensions = {"VK_KHR_get_physical_device_properties2"};
    e.vulkanDeviceExtensions = {"VK_KHR_driver_properties"};
    p = r.xess->probe(e);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("VK_EXT_subgroup_size_control") != std::string::npos);
    CHECK(p.reason.find("VK_KHR_driver_properties") == std::string::npos);
    e.vulkanDeviceExtensions.push_back("VK_EXT_subgroup_size_control");
    p = r.xess->probe(e);
    CHECK_MESSAGE(p.available, p.reason);
    // A device older than the API XeSS needs.
    r.dev.apiVersion = (1u << 22) | (0u << 12);
    p = r.xess->probe(e);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("Vulkan 1.1") != std::string::npos);
    CHECK(p.reason.find("1.0") != std::string::npos);

    // The same question, asked on its own (the device creation of M78-P2b asks it before the device exists).
    const Result<render::XessVulkanRequirements> req = render::xess_vulkan_requirements();
    REQUIRE(req.ok());
    CHECK(req->instanceExtensions == fx.instanceExtensions);
    CHECK(req->deviceExtensions.empty());  // no physical device given: only the instance's list
    CHECK(req->minApiVersion == fx.minApiVersion);
    const Result<render::XessVulkanRequirements> full =
        render::xess_vulkan_requirements(reinterpret_cast<void*>(std::uintptr_t(0x2000)), reinterpret_cast<void*>(std::uintptr_t(0x3000)));
    REQUIRE(full.ok());
    CHECK(full->deviceExtensions == fx.deviceExtensions);
    r.loader.installed = false;
    const Result<render::XessVulkanRequirements> none = render::xess_vulkan_requirements();
    CHECK_FALSE(none.ok());
}

// ---- the frames -------------------------------------------------------------------------------------------------------------------------

TEST_CASE("xess D3D12: one context for many frames, init again only when the size, quality or flags change, destroy on release") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.xess->probe(r.env(GpuVendor::Intel)).available);
    CHECK(r.xess->needs_output_storage());
    r.in.resetHistory = false;
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fx.creates == 1);
    CHECK(fx.inits == 1);
    CHECK(fx.executes == 1);
    CHECK(fx.init12.outputResolution.x == 320);
    CHECK(fx.init12.outputResolution.y == 180);
    CHECK(fx.init12.quality == abi::kQualityBalanced);  // 2x
    CHECK((fx.init12.initFlags & abi::kInitResponsivePixelMask) != 0);
    CHECK((fx.init12.initFlags & abi::kInitLdrInputColor) != 0);  // display values (in.linear is false)
    CHECK(fx.velocityScales == 1);
    CHECK(fx.velocityScaleX == doctest::Approx(160.0f));  // the motion is in UV units: XeSS reads pixels
    CHECK(fx.velocityScaleY == doctest::Approx(90.0f));
    CHECK(fx.exec12.resetHistory == 1);  // the first frame of a context starts the history

    // Steady frames: nothing is made again, the history is kept.
    for (int i = 0; i < 5; ++i) REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fx.creates == 1);
    CHECK(fx.inits == 1);
    CHECK(fx.executes == 6);
    CHECK(fx.exec12.resetHistory == 0);
    CHECK(r.dev.idles == 0);
    // The frame says to start over: the reset flag, and no new init.
    r.in.resetHistory = true;
    REQUIRE(r.draw());
    CHECK(fx.exec12.resetHistory == 1);
    CHECK(fx.inits == 1);
    r.in.resetHistory = false;
    REQUIRE(r.draw());
    CHECK(fx.exec12.resetHistory == 0);

    // Linear light: the LDR flag goes off, so the context is initialised again (after the GPU was waited for).
    r.in.linear = true;
    REQUIRE(r.draw());
    CHECK(fx.inits == 2);
    CHECK((fx.init12.initFlags & abi::kInitLdrInputColor) == 0);
    CHECK(fx.creates == 1);
    CHECK(r.dev.idles == 1);
    CHECK(fx.exec12.resetHistory == 1);
    // A new size: a new init at the new sizes, and the helper images follow it.
    r.resize(200, 100, 400, 200);
    r.in.linear = true;
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fx.inits == 3);
    CHECK(fx.init12.outputResolution.x == 400);
    CHECK(fx.velocityScaleX == doctest::Approx(200.0f));
    CHECK(fx.creates == 1);
    CHECK(r.dev.idles == 2);
    // Another ratio: another quality.
    r.resize(100, 56, 300, 168);
    r.in.linear = true;
    REQUIRE(r.draw());
    CHECK(fx.inits == 4);
    CHECK(fx.init12.quality == abi::kQualityUltraPerformance);  // 3x
    CHECK(fx.destroys == 0);

    // The renderer lets go: the GPU is waited for, then the context is destroyed once; a second release does nothing.
    const int idlesBefore = r.dev.idles;
    r.xess->release(r.dev);
    CHECK(fx.destroys == 1);
    CHECK(r.dev.idles == idlesBefore + 1);
    const auto destroy = std::find(fx.events.begin(), fx.events.end(), "destroy");
    REQUIRE(destroy != fx.events.begin());
    CHECK(*(destroy - 1) == "idle");
    r.xess->release(r.dev);
    CHECK(fx.destroys == 1);
    CHECK(r.dev.errors().empty());
}

TEST_CASE("xess D3D12: a frame passes the jitter, exposure, sizes and the right resources inside a native section with every state declared") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.xess->probe(r.env(GpuVendor::Amd)).available);  // any GPU
    r.in.exposure = 2.5f;
    r.in.jitter[0] = 0.4f;
    r.in.jitter[1] = -0.3f;
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    const abi::D3d12ExecuteParams& p = fx.exec12;
    CHECK(p.jitterX == doctest::Approx(0.4f));
    CHECK(p.jitterY == doctest::Approx(-0.3f));
    CHECK(p.exposureScale == doctest::Approx(2.5f));
    CHECK(p.inputWidth == 160);
    CHECK(p.inputHeight == 90);
    CHECK(p.color == r.dev.native_image(r.color).resource);
    CHECK(p.depth == r.dev.native_image(r.depth).resource);
    CHECK(p.velocity == r.dev.native_image(r.velocity).resource);
    CHECK(p.output == r.dev.native_image(r.output).resource);
    CHECK(p.exposureTexture == nullptr);
    CHECK(p.descriptorHeap == nullptr);  // XeSS keeps its own descriptors
    // A frame without a reactive mask gets the all-zero image of the render size, so the mask is always bound.
    CHECK(p.responsiveMask != nullptr);
    CHECK(p.responsiveMask != p.color);
    CHECK(r.list.declared.size() == 5);
    for (const gpu::NativeUse& u : r.list.declared) {
        CHECK(u.image.valid());
        if (u.image == r.output)
            CHECK(u.state == gpu::NativeState::UnorderedAccess);
        else
            CHECK(u.state == gpu::NativeState::ShaderRead);
    }
    CHECK(fx.executeList == &r.list.token);
    // The order: the section opens, XeSS records, the section closes.
    const std::vector<std::string> expected = {"create", "init", "begin", "execute", "end"};
    CHECK(fx.events == expected);
    CHECK(r.list.ends == 1);

    // A frame with a reactive mask passes that image and makes no empty one.
    r.reactive = r.dev.image(160, 90, gpu::PixelFormat::R8);
    r.reactiveView = r.dev.view(r.reactive);
    r.frame.reactive = r.reactive;
    r.in.reactive = r.reactiveView;
    REQUIRE(r.draw());
    CHECK(fx.exec12.responsiveMask == r.dev.native_image(r.reactive).resource);
    // Non-finite jitter never reaches the library.
    r.in.jitter[0] = std::numeric_limits<float>::quiet_NaN();
    r.in.jitter[1] = 99.0f;
    REQUIRE(r.draw());
    CHECK(fx.exec12.jitterX == 0.0f);
    CHECK(fx.exec12.jitterY == doctest::Approx(0.5f));
    CHECK(r.dev.errors().empty());
}

TEST_CASE("xess: a failure returns false with the reason, restarts the history, and never leaves a native section open") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.xess->probe(r.env(GpuVendor::Intel)).available);
    REQUIRE(r.draw());
    REQUIRE(r.draw());
    CHECK(fx.exec12.resetHistory == 0);
    // XeSS's execute fails: the section was closed, the error says which call and what it answered, the next frame resets.
    fx.executeRc = -6;
    CHECK_FALSE(r.draw());
    CHECK(r.frame.error.find("xessD3D12Execute") != std::string::npos);
    CHECK(r.frame.error.find("device error") != std::string::npos);
    CHECK(r.list.ends == 3);
    fx.executeRc = 0;
    REQUIRE(r.draw());
    CHECK(fx.exec12.resetHistory == 1);
    // The native section cannot be opened: nothing was called of XeSS, the list is as it was.
    r.list.failBegin = true;
    const int executes = fx.executes, ends = r.list.ends;
    CHECK_FALSE(r.draw());
    CHECK(r.frame.error.find("native command section") != std::string::npos);
    CHECK(fx.executes == executes);
    CHECK(r.list.ends == ends);
    r.list.failBegin = false;
    // A frame without velocity or depth is refused before anything is called, naming the missing image.
    r.frame.velocity = {};
    CHECK_FALSE(r.draw());
    CHECK(r.frame.error.find("velocity") != std::string::npos);
    r.frame.velocity = r.velocity;
    r.frame.list = nullptr;
    CHECK_FALSE(r.draw());
    CHECK_FALSE(r.frame.error.empty());
    r.frame.list = &r.list;
    // The old-driver warning is not an error.
    REQUIRE(r.draw());
}

TEST_CASE("xess: a context that cannot be made or initialised says why, and the GPU's own refusal teaches") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.xess->probe(r.env(GpuVendor::Nvidia)).available);
    fx.createRc = -1;
    CHECK_FALSE(r.draw());
    CHECK(r.frame.error.find("xessD3D12CreateContext") != std::string::npos);
    CHECK(r.frame.error.find("Shader Model 6.4") != std::string::npos);
    CHECK(fx.inits == 0);
    CHECK(fx.executes == 0);
    fx.createRc = 0;
    fx.initRc = -2;
    CHECK_FALSE(r.draw());
    CHECK(r.frame.error.find("xessD3D12Init") != std::string::npos);
    CHECK(r.frame.error.find("driver is too old") != std::string::npos);
    CHECK(r.frame.error.find("160x90 -> 320x180") != std::string::npos);
    CHECK(fx.executes == 0);
    fx.initRc = 0;
    REQUIRE_MESSAGE(r.draw(), r.frame.error);  // the context the second call made, now initialised
    CHECK(fx.creates == 2);
    CHECK(fx.executes == 1);
    // A provider that was never probed has no library.
    auto fresh = render::make_xess_provider();
    CHECK_FALSE(fresh->upscale(r.in, r.frame));
    CHECK(r.frame.error.find("probe") != std::string::npos);
    // A release for a device that never drew with it does nothing.
    XDevice other(gpu::Backend::D3d12);
    r.xess->release(other);
    CHECK(fx.destroys == 0);
}

TEST_CASE("xess Vulkan: the images go as image views with their formats, sizes and ranges, and the output gets a storage view") {
    Rig r(gpu::Backend::Vulkan, 0x1002);
    fx.instanceExtensions = {"VK_KHR_get_physical_device_properties2"};
    render::VendorEnv e = r.env(GpuVendor::Amd);
    e.vulkanInstanceExtensions = {"VK_KHR_get_physical_device_properties2"};
    REQUIRE_MESSAGE(r.xess->probe(e).available, "the extensions are enabled");
    r.in.jitter[0] = -0.25f;
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fx.creates == 1);
    CHECK(fx.initVk.outputResolution.x == 320);
    CHECK(fx.initVk.quality == abi::kQualityBalanced);
    const abi::VkExecuteParams& p = fx.execVk;
    CHECK(p.color.imageView == std::uint64_t(r.colorView.id) * 256);
    CHECK(p.color.image == std::uint64_t(r.color.id) * 16);
    CHECK(p.color.width == 160);
    CHECK(p.color.height == 90);
    CHECK(p.color.aspectMask == 1);
    CHECK(p.color.levelCount == 1);
    CHECK(p.color.layerCount == 1);
    CHECK(p.color.format == 37);
    CHECK(p.depth.image == std::uint64_t(r.depth.id) * 16);
    CHECK(p.velocity.image == std::uint64_t(r.velocity.id) * 16);
    CHECK(p.responsiveMask.imageView != 0);  // the empty mask
    CHECK(p.output.width == 320);
    CHECK(p.output.height == 180);
    CHECK(p.output.image == std::uint64_t(r.output.id) * 16);
    CHECK(p.output.imageView != 0);
    CHECK(p.output.imageView != std::uint64_t(r.colorView.id) * 256);
    CHECK(p.jitterX == doctest::Approx(-0.25f));
    CHECK(p.resetHistory == 1);
    CHECK(p.inputWidth == 160);
    CHECK(fx.executeList == &r.list.token);
    // The same output image: its storage view is kept, not made again.
    const std::uint64_t outputView = p.output.imageView;
    REQUIRE(r.draw());
    CHECK(fx.execVk.output.imageView == outputView);
    CHECK(fx.execVk.resetHistory == 0);
    // Another output image (a resize): a new view.
    r.resize(160, 90, 320, 180);
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fx.execVk.output.image == std::uint64_t(r.output.id) * 16);
    r.xess->release(r.dev);
    CHECK(fx.destroys == 1);
    CHECK(r.dev.errors().empty());
}

TEST_CASE("xess D3D11: the immediate context path takes the same parameters without a command list") {
    Rig r(gpu::Backend::D3d11, 0x8086);
    REQUIRE(r.xess->probe(r.env(GpuVendor::Intel)).available);
    r.in.exposure = 0.0f;  // an unset exposure is 1, never 0
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fx.init11.outputResolution.x == 320);
    CHECK(fx.init11.quality == abi::kQualityBalanced);
    CHECK(fx.exec11.exposureScale == doctest::Approx(1.0f));
    CHECK(fx.exec11.color == r.dev.native_image(r.color).resource);
    CHECK(fx.exec11.output == r.dev.native_image(r.output).resource);
    CHECK(fx.exec11.jitterX == doctest::Approx(0.25f));
    CHECK(fx.exec11.inputHeight == 90);
    const std::vector<std::string> expected = {"create", "init", "begin", "execute", "end"};
    CHECK(fx.events == expected);  // D3D11's section is declared too (it only checks the uses)
}

// ---- the choice and the reports ---------------------------------------------------------------------------------------------------------

TEST_CASE("xess: auto picks it on an Intel GPU, an explicit xess runs on any GPU, and neither without a usable XeSS") {
    using render::UpscalerCaps;
    using render::UpscalerMode;
    render::UpscalerSettings s;
    UpscalerCaps caps;
    caps.temporal = true;
    caps.gpuVendor = GpuVendor::Intel;
    caps.xess = true;
    s.mode = UpscalerMode::Auto;
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Xess);
    caps.xess = false;  // not installed, or a frame it refused
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Temporal);
    caps.xess = true;
    caps.gpuVendor = GpuVendor::Nvidia;  // another maker's GPU: auto asks its own SDK (DLSS, not installed here)
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Temporal);
    s.mode = UpscalerMode::Xess;  // chosen explicitly: any GPU
    for (const GpuVendor v : {GpuVendor::Intel, GpuVendor::Nvidia, GpuVendor::Amd, GpuVendor::Other})
        CHECK_MESSAGE((caps.gpuVendor = v, render::effective_upscaler_mode(s, caps) == UpscalerMode::Xess), render::gpu_vendor_name(v));
    caps.xess = false;
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Temporal);
    caps.temporal = false;  // a vendor SDK reads the jittered frame: without the temporal upscaler it falls to the spatial one
    caps.xess = true;
    CHECK(render::effective_upscaler_mode(s, caps) != UpscalerMode::Xess);
}

TEST_CASE("xess: the feature row of render.supports takes the provider's answer, with its reason") {
    render::FeatureEnv env;
    env.backend = render::FeatureBackend::D3d11;
    std::array<render::VendorProbe, render::kVendorUpscalerCount> answers;
    answers[1].available = false;
    answers[1].reason = "XeSS is not installed: run `factoria setup xess`.";
    render::set_vendor_upscalers_env(env, answers);
    const int row = render::find_feature("xess");
    REQUIRE(row >= 0);
    std::string why;
    CHECK_FALSE(render::feature_supported(env, row, &why));
    CHECK(why == answers[1].reason);
    answers[1] = render::VendorProbe{true, ""};
    render::set_vendor_upscalers_env(env, answers);
    CHECK(render::feature_supported(env, row, &why));
    // The table's own column says where XeSS runs that the table knows (D3D11), and the report carries it.
    const Json report = render::feature_report(env, "d3d11");
    bool found = false;
    for (const Json& f : report["features"])
        if (f["name"] == "xess") {
            found = true;
            CHECK(f["supported"] == true);
            CHECK(f["backends"]["D3D11"] == true);
        }
    CHECK(found);
}
