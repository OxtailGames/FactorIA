// M78-P4a-FSR: the FidelityFX Super Resolution 3.1 provider (src/render_upscale_fsr.{h,cpp}). No AMD library is involved: the functions of the
// FidelityFX API are fakes in a table the provider takes from a fake VendorLibrary (the way it takes the real ones), and the device is a
// RecordingDevice that answers a backend and native handles. What is tested is what the provider asks of FidelityFX: when it is available,
// when its context is made, made again and destroyed, what each frame passes (jitter, motion scale, exposure, reset, frame time, flags,
// sizes, resources and their states) and in which order with the native section, and what a failure does. That the real library draws the
// right picture is for a Windows machine with the SDK, on D3D12 and Vulkan, on an AMD GPU and on another maker's.
#include <doctest.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <limits>
#include <map>
#include <memory>
#include <span>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "gpu/recording_device.h"
#include "render_features.h"
#include "render_upscale_fsr.h"
#include "render_upscale_vendor.h"

using namespace fa;
using render::GpuVendor;
namespace abi = fa::render::ffx_abi;

namespace {

// ---- the fake library ---------------------------------------------------------------------------------------------------------------

// What the fake functions saw, in order and by number.
struct Fk {
    std::vector<std::string> versions = {"3.1.4"};  // what GET_VERSIONS names
    abi::ReturnCode queryRc = 0, createRc = 0, createVkNewRc = 0, dispatchRc = 0, destroyRc = 0;
    const wchar_t* createMessage = nullptr;    // sent through the message callback by a create that fails
    const wchar_t* createWarning = nullptr;    // sent by every create, whatever it answers
    const wchar_t* dispatchMessage = nullptr;  // sent by every dispatch
    void (*messageFn)(std::uint32_t, const wchar_t*) = nullptr;  // the callback of the last create
    int creates = 0, destroys = 0, dispatches = 0, queries = 0;
    abi::CreateUpscaleDesc create{};
    std::uint64_t backendType = 0;            // the type of the backend descriptor chained to the create desc
    std::vector<std::uint64_t> backendTypes;  // one per create call
    void* backendDevice = nullptr;
    abi::VkDeviceContext backendVk{};
    abi::DispatchUpscaleDesc dispatch{};
    std::uint64_t queryCreateType = 0;
    void* queryDevice = nullptr;
    abi::VkDeviceContext queryVk{};
    std::vector<std::string> events;  // "create", "begin", "dispatch", "end", "destroy", "idle"
    int tokenStorage = 0;
    void reset() { *this = Fk{}; }
};
Fk fk;

abi::Context fake_token() { return reinterpret_cast<abi::Context>(&fk.tokenStorage); }

abi::ReturnCode fake_create(abi::Context* context, abi::Header* desc, const void*) {
    ++fk.creates;
    fk.events.push_back("create");
    const auto* up = reinterpret_cast<const abi::CreateUpscaleDesc*>(desc);
    fk.create = *up;
    if (desc->next) {
        fk.backendType = desc->next->type;
        fk.backendTypes.push_back(desc->next->type);
        if (desc->next->type == abi::kCreateBackendDx12)
            fk.backendDevice = reinterpret_cast<const abi::CreateBackendDx12Desc*>(desc->next)->device;
        else
            fk.backendVk = reinterpret_cast<const abi::CreateBackendVkDesc*>(desc->next)->deviceContext;
    }
    abi::ReturnCode rc = fk.createRc;
    if (rc == 0 && desc->next && desc->next->type == abi::kCreateBackendVk && fk.createVkNewRc != 0)
        rc = fk.createVkNewRc;
    fk.messageFn = up->message;
    if (fk.createWarning && up->message) up->message(0, fk.createWarning);
    if (rc != 0 && fk.createMessage && up->message) up->message(0, fk.createMessage);
    if (rc == 0) *context = fake_token();
    return rc;
}
abi::ReturnCode fake_destroy(abi::Context*, const void*) {
    ++fk.destroys;
    fk.events.push_back("destroy");
    return fk.destroyRc;
}
// The strings handed out live as long as the fake.
std::vector<const char*> g_names;
abi::ReturnCode fake_query(abi::Context* context, abi::Header* desc) {
    ++fk.queries;
    if (context && *context) return abi::kParameterError;  // the probe asks before any context exists
    if (fk.queryRc != 0) return fk.queryRc;
    if (desc->type != abi::kQueryGetVersions) return abi::kUnknownDescType;
    auto* q = reinterpret_cast<abi::QueryGetVersions*>(desc);
    fk.queryCreateType = q->createDescType;
    fk.queryDevice = q->device;
    if (q->device && fk.queryVk.device == nullptr && fk.backendVk.device == nullptr) {
        // A Vulkan probe passes a VkDeviceContext*; a D3D12 one the device itself. The test reads queryDevice either way.
    }
    if (!q->versionNames) {
        *q->outputCount = fk.versions.size();
        return 0;
    }
    g_names.clear();
    for (const std::string& s : fk.versions) g_names.push_back(s.c_str());
    const std::uint64_t n = std::min<std::uint64_t>(*q->outputCount, g_names.size());
    for (std::uint64_t i = 0; i < n; ++i) {
        q->versionNames[i] = g_names[std::size_t(i)];
        q->versionIds[i] = 0x1000 + i;
    }
    *q->outputCount = n;
    return 0;
}
abi::ReturnCode fake_dispatch(abi::Context*, const abi::Header* desc) {
    ++fk.dispatches;
    fk.events.push_back("dispatch");
    fk.dispatch = *reinterpret_cast<const abi::DispatchUpscaleDesc*>(desc);
    if (fk.dispatchMessage && fk.messageFn) fk.messageFn(0, fk.dispatchMessage);
    return fk.dispatchRc;
}
void fake_proc_addr() {}

class FakeLibrary final : public render::VendorLibrary {
public:
    explicit FakeLibrary(std::vector<std::string> hidden) : hidden_(std::move(hidden)) {
        table_["ffxCreateContext"] = reinterpret_cast<void*>(&fake_create);
        table_["ffxDestroyContext"] = reinterpret_cast<void*>(&fake_destroy);
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
// which image reached FSR) and counts the times the GPU was waited for.
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
        n.apiVersion = apiVersion;
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
    bool noNative = false;  // the device knows no native resource (an image it did not make)
    std::uint32_t apiVersion = (1u << 22) | (3u << 12);  // Vulkan 1.3

    gpu::Image image(int w, int h, gpu::PixelFormat format, bool storage = false) {
        gpu::ImageDesc d;
        d.width = w;
        d.height = h;
        d.pixelFormat = format;
        d.usage.storageImage = storage;
        d.label = "fsr-test";
        return make_image(d);
    }

private:
    gpu::Backend backend_;
    gpu::DeviceInfo info_{};
};

// A list whose native section is a fake: it records what was declared and, in `fk.events`, when.
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

// One frame's worth of everything: a device, a list, the images, the input and the provider under test (its own instance, not the process's).
struct Rig {
    FakeLoader loader;
    LoaderGuard guard{&loader};
    FDevice dev;
    FList list;
    std::unique_ptr<render::VendorUpscaler> fsr = render::make_fsr_provider();
    gpu::Image color, depth, velocity, output, reactive;
    render::UpscaleInput in;
    render::VendorFrame frame;
    int renderW = 160, renderH = 90, outW = 320, outH = 180;

    explicit Rig(gpu::Backend backend, std::uint32_t pciVendor = 0x1002) : dev(backend, pciVendor), list(dev, backend) {
        fk.reset();
        setup_images();
    }
    ~Rig() {
        fsr->release(dev);
        free_images();
    }
    Rig(const Rig&) = delete;
    Rig& operator=(const Rig&) = delete;

    void setup_images() {
        color = dev.image(renderW, renderH, gpu::PixelFormat::Rgba8);
        depth = dev.image(renderW, renderH, gpu::PixelFormat::R32F);
        velocity = dev.image(renderW, renderH, gpu::PixelFormat::Rg16F);
        output = dev.image(outW, outH, gpu::PixelFormat::Rgba8, true);
        in = render::UpscaleInput{};
        in.renderW = renderW;
        in.renderH = renderH;
        in.outW = outW;
        in.outH = outH;
        in.linear = false;
        in.jitter[0] = 0.25f;
        in.jitter[1] = -0.125f;
        in.quality = render::UpscalerQuality::Balanced;
        in.frameTimeMs = 16.5f;
        in.cameraNear = 0.1f;
        in.cameraFovY = 1.2f;
        frame = render::VendorFrame{};
        frame.device = &dev;
        frame.list = &list;
        frame.color = color;
        frame.depth = depth;
        frame.velocity = velocity;
        frame.output = output;
        frame.colorFormat = gpu::PixelFormat::Rgba8;
        frame.outputFormat = gpu::PixelFormat::Rgba8;
    }
    void add_reactive() {
        reactive = dev.image(renderW, renderH, gpu::PixelFormat::R8);
        frame.reactive = reactive;
    }
    void free_images() {
        for (const gpu::Image i : {color, depth, velocity, output, reactive})
            if (i.valid()) dev.destroy_image(i);
        reactive = {};
    }
    // Changes the render and output sizes (new images; the old ones are destroyed after the provider let go).
    void resize(int rw, int rh, int ow, int oh) {
        free_images();
        renderW = rw;
        renderH = rh;
        outW = ow;
        outH = oh;
        setup_images();
    }
    render::VendorEnv env(GpuVendor vendor = GpuVendor::Amd) const {
        render::VendorEnv e;
        e.backend = dev.backend();
        e.vendor = vendor;
        e.device = &dev;
        e.windows = true;
        return e;
    }
    bool draw() { return fsr->upscale(in, frame); }
    int count(const char* event) const { return int(std::count(fk.events.begin(), fk.events.end(), event)); }
};

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

}  // namespace

// ---- the pure parts ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("fsr: M76's five qualities are FSR's five modes, the flags and formats follow the frame, and the texts say "
          "what they are") {
    using render::UpscalerQuality;
    CHECK(render::fsr_quality_mode(UpscalerQuality::Native) == 0);
    CHECK(render::fsr_quality_mode(UpscalerQuality::Quality) == 1);
    CHECK(render::fsr_quality_mode(UpscalerQuality::Balanced) == 2);
    CHECK(render::fsr_quality_mode(UpscalerQuality::Performance) == 3);
    CHECK(render::fsr_quality_mode(UpscalerQuality::UltraPerformance) == 4);
    CHECK(render::fsr_quality_mode(UpscalerQuality(77)) == 0);
    // The ratios of the modes are the ones M76's render scales are made from (1, 1.5, 1.7, 2, 3).
    for (int i = 0; i < render::kUpscalerQualityCount; ++i)
        CHECK(render::fsr_quality_ratio(render::fsr_quality_mode(UpscalerQuality(i))) ==
              doctest::Approx(1.0f / render::upscaler_quality_scale(UpscalerQuality(i))));
    CHECK(render::fsr_quality_ratio(9) == 0.0f);

    const std::uint32_t display = render::fsr_create_flags(false, false);
    CHECK((display & abi::kEnableDepthInverted) != 0);
    CHECK((display & abi::kEnableDepthInfinite) != 0);
    CHECK((display & abi::kEnableNonLinearColorSpace) != 0);
    CHECK((display & abi::kEnableHdr) == 0);
    CHECK((display & abi::kEnableDynamicResolution) == 0);
    const std::uint32_t hdr = render::fsr_create_flags(true, true);
    CHECK((hdr & abi::kEnableHdr) != 0);
    CHECK((hdr & abi::kEnableNonLinearColorSpace) == 0);
    CHECK((hdr & abi::kEnableDynamicResolution) != 0);
    CHECK(render::fsr_dispatch_flags(false) == abi::kFlagNonLinearColorSrgb);
    CHECK(render::fsr_dispatch_flags(true) == 0);

    CHECK(render::fsr_surface_format(gpu::PixelFormat::Rgba8) == abi::kFormatR8G8B8A8Unorm);
    CHECK(render::fsr_surface_format(gpu::PixelFormat::Rgba16F) == abi::kFormatR16G16B16A16Float);
    CHECK(render::fsr_surface_format(gpu::PixelFormat::Rg11B10F) == abi::kFormatR11G11B10Float);
    CHECK(render::fsr_surface_format(gpu::PixelFormat::Bgra8) == abi::kFormatB8G8R8A8Unorm);
    CHECK(render::fsr_surface_format(gpu::PixelFormat::R32F) == abi::kFormatR32Float);
    CHECK(render::fsr_surface_format(gpu::PixelFormat::Rg16F) == abi::kFormatR16G16Float);
    CHECK(render::fsr_surface_format(gpu::PixelFormat::R8) == abi::kFormatR8Unorm);
    CHECK(render::fsr_surface_format(gpu::PixelFormat::Rg32F) == abi::kFormatUnknown);

    CHECK(render::fsr_result_text(0) == "ok");
    CHECK(render::fsr_result_text(4) == "no provider");
    CHECK(render::fsr_result_text(6) == "bad parameter");
    CHECK(render::fsr_result_text(99) == "code 99");

    int major = -1, minor = -1;
    CHECK(render::fsr_parse_version("3.1.4", major, minor));
    CHECK((major == 3 && minor == 1));
    CHECK(render::fsr_parse_version("FSR 3.1.0 (upscaler)", major, minor));
    CHECK((major == 3 && minor == 1));
    CHECK(render::fsr_parse_version("4", major, minor));
    CHECK((major == 4 && minor == 0));
    CHECK(render::fsr_parse_version("v2.10", major, minor));
    CHECK((major == 2 && minor == 10));
    CHECK_FALSE(render::fsr_parse_version("native", major, minor));
    CHECK_FALSE(render::fsr_parse_version("", major, minor));

    CHECK(std::string(render::fsr_library_spec(gpu::Backend::D3d12).fileName) == "amd_fidelityfx_loader_dx12.dll");
    CHECK(std::string(render::fsr_library_spec(gpu::Backend::Vulkan).fileName) == "amd_fidelityfx_loader_vk.dll");
    CHECK(std::string(render::fsr_library_spec(gpu::Backend::Vulkan).setupId) == "fidelityfx");
    CHECK(std::string(render::fsr_library_spec(gpu::Backend::Vulkan).dirEnv) == "FA_FIDELITYFX_DIR");

    // Vulkan: nothing is required of the engine's instance and device.
    const render::FsrVulkanRequirements req = render::fsr_vulkan_requirements();
    CHECK(req.instanceExtensions.empty());
    CHECK(req.deviceExtensions.empty());
    CHECK(req.minApiVersion == ((1u << 22) | (1u << 12)));
}

TEST_CASE("fsr: the provider is index 2, draws on D3D12 and Vulkan only, writes the output from a compute shader and "
          "reads the reversed depth") {
    render::VendorUpscaler& p = render::vendor_provider(2);
    CHECK(p.mode() == "fsr");
    CHECK(p.name() == "FSR 3.1+");
    CHECK(p.setup_id() == "fidelityfx");
    CHECK(p.backends() == ((1u << unsigned(gpu::Backend::D3d12)) | (1u << unsigned(gpu::Backend::Vulkan))));
    CHECK(p.needs_output_storage());
    CHECK(p.wants_reversed_depth());
    // The other providers keep the depth that grows with the distance.
    CHECK_FALSE(render::vendor_provider(0).wants_reversed_depth());
    CHECK_FALSE(render::vendor_provider(1).wants_reversed_depth());
}

// ---- the probe ---------------------------------------------------------------------------------------------------------------------------

TEST_CASE("fsr probe: D3D12 and Vulkan run on any GPU with the library of their backend, D3D11 and the rest never") {
    Rig d12(gpu::Backend::D3d12);
    for (const GpuVendor v : {GpuVendor::Amd, GpuVendor::Nvidia, GpuVendor::Intel, GpuVendor::Other}) {
        const render::VendorProbe p = d12.fsr->probe(d12.env(v));
        CHECK_MESSAGE(p.available, p.reason);
        CHECK(p.reason.empty());
    }
    CHECK(d12.loader.askedFiles.back() == "amd_fidelityfx_loader_dx12.dll");
    CHECK(fk.queryCreateType == abi::kCreateUpscale);
    CHECK(fk.queryDevice == d12.dev.native().device);  // D3D12: the device itself

    Rig vk(gpu::Backend::Vulkan);
    CHECK(vk.fsr->probe(vk.env()).available);
    CHECK(vk.loader.askedFiles.back() == "amd_fidelityfx_loader_vk.dll");
    CHECK(fk.queryDevice != nullptr);  // Vulkan: a VkDeviceContext*

    for (const gpu::Backend b : {gpu::Backend::D3d11, gpu::Backend::Gl, gpu::Backend::Metal}) {
        Rig other(b);
        const render::VendorProbe p = other.fsr->probe(other.env());
        CHECK_FALSE(p.available);
        CHECK_MESSAGE(has(p.reason, "D3D12 or Vulkan"), p.reason);
        CHECK(other.loader.askedFiles.empty());  // the backend is refused before the library is looked for
    }
    render::VendorEnv notWindows = d12.env();
    notWindows.windows = false;
    CHECK(has(d12.fsr->probe(notWindows).reason, "Windows"));
}

TEST_CASE("fsr probe: a missing, unloadable, incomplete or too old library is refused with the way to fix it") {
    Rig r(gpu::Backend::D3d12);
    r.loader.installed = false;
    render::VendorProbe p = r.fsr->probe(r.env());
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "factoria setup fidelityfx"));
    CHECK(has(p.reason, "the fake loader has no library"));

    r.loader.installed = true;
    r.loader.loads = false;
    p = r.fsr->probe(r.env());
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "could not be loaded"));
    CHECK(has(p.reason, "the fake loader cannot load it"));
    CHECK(has(p.reason, "factoria setup fidelityfx"));

    r.loader.loads = true;
    for (const char* name : {"ffxCreateContext", "ffxDestroyContext", "ffxQuery", "ffxDispatch"}) {
        r.loader.hidden = {name};
        p = r.fsr->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK_MESSAGE(has(p.reason, (std::string("no export ") + name).c_str()), p.reason);
        CHECK(has(p.reason, "factoria setup fidelityfx"));
    }
    r.loader.hidden.clear();

    fk.versions = {"2.9.0"};  // older than 3.1
    p = r.fsr->probe(r.env());
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "2.9.0"));
    CHECK(has(p.reason, "3.1"));
    fk.versions = {"3.0.2"};
    CHECK_FALSE(r.fsr->probe(r.env()).available);
    fk.versions = {"3.0.2", "3.1.4"};  // the newest counts
    CHECK(r.fsr->probe(r.env()).available);
    fk.versions = {"4.0.0", "2.2.0"};  // a later FSR is the same API
    CHECK(r.fsr->probe(r.env()).available);
    fk.versions = {"nightly"};  // a name with no number is not a reason to refuse
    CHECK(r.fsr->probe(r.env()).available);

    fk.versions = {};  // no provider for this GPU: the upscaler DLL is not there, or the driver is old
    p = r.fsr->probe(r.env());
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "no FSR provider"));
    CHECK(has(p.reason, "factoria setup fidelityfx"));

    fk.versions = {"3.1.4"};
    fk.queryRc = abi::kRuntimeError;
    p = r.fsr->probe(r.env());
    CHECK_FALSE(p.available);
    CHECK(has(p.reason, "runtime error"));
    CHECK(has(p.reason, "factoria setup fidelityfx"));
}

TEST_CASE("fsr probe: Vulkan needs a device of Vulkan 1.1 or newer, and the extensions FSR asks for are none") {
    Rig r(gpu::Backend::Vulkan);
    render::VendorEnv e = r.env();
    CHECK(r.fsr->probe(e).available);  // no extension list is needed: the engine's lists may be empty
    r.dev.apiVersion = (1u << 22);     // Vulkan 1.0
    const render::VendorProbe old = r.fsr->probe(e);
    CHECK_FALSE(old.available);
    CHECK(has(old.reason, "Vulkan 1.1"));
    CHECK(has(old.reason, "1.0"));
    CHECK(has(old.reason, "Direct3D 12"));
    r.dev.apiVersion = 0;  // not reported: no check
    CHECK(r.fsr->probe(e).available);
}

// ---- the context ---------------------------------------------------------------------------------------------------------------------------

TEST_CASE("fsr D3D12: one context for many frames, made again only when the sizes, quality or flags change, destroyed "
          "on release") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fk.creates == 1);
    CHECK(fk.dispatches == 1);
    CHECK(fk.backendType == abi::kCreateBackendDx12);
    CHECK(fk.backendDevice == r.dev.native().device);
    CHECK(fk.create.header.type == abi::kCreateUpscale);
    CHECK(fk.create.maxRenderSize.width == 160);
    CHECK(fk.create.maxRenderSize.height == 90);
    CHECK(fk.create.maxUpscaleSize.width == 320);
    CHECK(fk.create.maxUpscaleSize.height == 180);
    CHECK(fk.create.message != nullptr);
    CHECK(fk.create.flags == render::fsr_create_flags(false, false));
    CHECK(fk.dispatch.reset);  // the first frame of a context starts the history

    // Steady frames: nothing is made again, the history is kept, the GPU is never waited for.
    for (int i = 0; i < 5; ++i) REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fk.creates == 1);
    CHECK(fk.dispatches == 6);
    CHECK_FALSE(fk.dispatch.reset);
    CHECK(r.dev.idles == 0);
    CHECK(fk.destroys == 0);
    // The frame says to start over: the reset flag, and no new context.
    r.in.resetHistory = true;
    REQUIRE(r.draw());
    CHECK(fk.dispatch.reset);
    CHECK(fk.creates == 1);
    r.in.resetHistory = false;
    REQUIRE(r.draw());
    CHECK_FALSE(fk.dispatch.reset);

    // A different quality: the GPU is waited for, the old context goes, a new one is made, and its first frame resets.
    r.in.quality = render::UpscalerQuality::Performance;
    REQUIRE(r.draw());
    CHECK(fk.creates == 2);
    CHECK(fk.destroys == 1);
    CHECK(r.dev.idles == 1);
    CHECK(fk.dispatch.reset);
    const auto destroyAt = std::find(fk.events.begin(), fk.events.end(), "destroy");
    REQUIRE(destroyAt != fk.events.begin());
    CHECK(*(destroyAt - 1) == "idle");
    REQUIRE(destroyAt + 1 != fk.events.end());
    CHECK(*(destroyAt + 1) == "create");
    // Linear light: HDR input instead of the non-linear colour space.
    r.in.linear = true;
    REQUIRE(r.draw());
    CHECK(fk.creates == 3);
    CHECK((fk.create.flags & abi::kEnableHdr) != 0);
    CHECK((fk.create.flags & abi::kEnableNonLinearColorSpace) == 0);
    CHECK(fk.dispatch.flags == 0);
    // Dynamic resolution: its flag, and only then the render size may move under the maximum.
    r.in.dynamicResolution = true;
    r.in.dynamicResolutionEnabled = true;
    r.in.maxRenderW = 160;
    r.in.maxRenderH = 90;
    REQUIRE(r.draw());
    CHECK(fk.creates == 4);
    CHECK((fk.create.flags & abi::kEnableDynamicResolution) != 0);
    const int createsBefore = fk.creates;
    r.resize(120, 68, 320, 180);  // the dynamic resolution stepped down: same maximum, same output
    r.in.linear = true;
    r.in.dynamicResolution = true;
    r.in.dynamicResolutionEnabled = true;
    r.in.quality = render::UpscalerQuality::Performance;
    r.in.maxRenderW = 160;
    r.in.maxRenderH = 90;
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fk.creates == createsBefore);
    CHECK(fk.dispatch.renderSize.width == 120);
    CHECK(fk.dispatch.renderSize.height == 68);
    CHECK(fk.dispatch.upscaleSize.width == 320);
    // A new output size: a new context at the new sizes.
    r.resize(200, 100, 400, 200);
    r.in.linear = true;
    r.in.dynamicResolution = true;
    r.in.dynamicResolutionEnabled = true;
    r.in.quality = render::UpscalerQuality::Performance;
    r.in.maxRenderW = 200;
    r.in.maxRenderH = 100;
    REQUIRE(r.draw());
    CHECK(fk.creates == createsBefore + 1);
    CHECK(fk.create.maxUpscaleSize.width == 400);
    CHECK(fk.create.maxRenderSize.width == 200);

    // The renderer lets go: the GPU is waited for, then the context is destroyed once; a second release does nothing.
    const int destroysBefore = fk.destroys;
    const int idlesBefore = r.dev.idles;
    r.fsr->release(r.dev);
    CHECK(fk.destroys == destroysBefore + 1);
    CHECK(r.dev.idles == idlesBefore + 1);
    CHECK(fk.events[fk.events.size() - 2] == "idle");
    CHECK(fk.events.back() == "destroy");
    r.fsr->release(r.dev);
    CHECK(fk.destroys == destroysBefore + 1);
    CHECK(r.dev.errors().empty());
}

TEST_CASE("fsr: a context is destroyed with the provider even when no release came, and a release of another device "
          "does nothing") {
    {
        Rig r(gpu::Backend::D3d12);
        REQUIRE(r.fsr->probe(r.env()).available);
        REQUIRE(r.draw());
        FDevice other(gpu::Backend::D3d12);
        r.fsr->release(other);
        CHECK(fk.destroys == 0);
        // The provider goes (a process shutting down) with its context live: the destructor gives it back.
        r.fsr = render::make_fsr_provider();  // the rig's own release at its end needs a provider
        CHECK(fk.destroys == 1);
    }
    CHECK(fk.destroys == 1);
}

TEST_CASE("fsr: a context made for another device is replaced when a new device draws") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE(r.draw());
    // A second device draws (the first was destroyed without release): the old context goes, a new one is made.
    Rig second(gpu::Backend::D3d12);  // resets the counters; its own loader guard replaces the first's
    CHECK(second.fsr->probe(second.env()).available);
    REQUIRE(second.draw());
    CHECK(fk.creates == 1);
    r.frame.device = &second.dev;
    r.frame.list = &second.list;
    r.frame.color = second.color;
    r.frame.depth = second.depth;
    r.frame.velocity = second.velocity;
    r.frame.output = second.output;
    REQUIRE(r.draw());
    CHECK(fk.creates == 2);
    CHECK(fk.destroys == 1);  // the context of the first device went when the second one drew
    r.fsr->release(second.dev);
    second.fsr->release(second.dev);
}

// ---- the frame ---------------------------------------------------------------------------------------------------------------------------

TEST_CASE("fsr D3D12: a frame passes the jitter, motion scale, exposure, times, flags and the right resources inside a "
          "native section with every "
          "state declared") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);
    r.in.exposure = 0.5f;
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    const std::vector<std::string> order = {"create", "begin", "dispatch", "end"};
    CHECK(fk.events == order);
    const abi::DispatchUpscaleDesc& d = fk.dispatch;
    CHECK(d.header.type == abi::kDispatchUpscale);
    CHECK(d.commandList == static_cast<const void*>(&r.list.token));
    CHECK(d.jitterOffset.x == doctest::Approx(0.25f));
    CHECK(d.jitterOffset.y == doctest::Approx(-0.125f));
    CHECK(d.motionVectorScale.x ==
          doctest::Approx(160.0f));  // the motion is in UV units: FSR reads pixels of the render size
    CHECK(d.motionVectorScale.y == doctest::Approx(90.0f));
    CHECK(d.renderSize.width == 160);
    CHECK(d.renderSize.height == 90);
    CHECK(d.upscaleSize.width == 320);
    CHECK(d.upscaleSize.height == 180);
    CHECK_FALSE(d.enableSharpening);
    CHECK(d.sharpness == 0.0f);
    CHECK(d.frameTimeDelta == doctest::Approx(16.5f));
    CHECK(d.preExposure == doctest::Approx(0.5f));
    CHECK(d.exposure.resource == nullptr);  // no exposure texture: the pre-exposure says it
    CHECK(d.transparencyAndComposition.resource == nullptr);
    CHECK(d.reactive.resource == nullptr);  // the frame has no reactive mask
    CHECK(d.cameraNear == doctest::Approx(0.1f));
    CHECK(d.cameraFar == std::numeric_limits<float>::max());  // the depth is infinite
    CHECK(d.cameraFovAngleVertical == doctest::Approx(1.2f));
    CHECK(d.viewSpaceToMetersFactor == doctest::Approx(1.0f));
    CHECK(d.flags == abi::kFlagNonLinearColorSrgb);

    CHECK(d.color.resource == r.dev.native_image(r.color).resource);
    CHECK(d.depth.resource == r.dev.native_image(r.depth).resource);
    CHECK(d.motionVectors.resource == r.dev.native_image(r.velocity).resource);
    CHECK(d.output.resource == r.dev.native_image(r.output).resource);
    CHECK(d.color.description.format == abi::kFormatR8G8B8A8Unorm);
    CHECK(d.color.description.type == abi::kResourceTexture2d);
    CHECK(d.color.description.width == 160);
    CHECK(d.color.description.height == 90);
    CHECK(d.color.description.usage == abi::kUsageReadOnly);
    CHECK(d.depth.description.format == abi::kFormatR32Float);
    CHECK(d.motionVectors.description.format == abi::kFormatR16G16Float);
    CHECK(d.output.description.width == 320);
    CHECK(d.output.description.height == 180);
    CHECK(d.output.description.usage == abi::kUsageUav);
    for (const abi::Resource* in : {&d.color, &d.depth, &d.motionVectors})
        CHECK(in->state == abi::kStatePixelComputeRead);
    CHECK(d.output.state == abi::kStateUnorderedAccess);

    // The native section declared every image in the state the SDK reads or writes it in.
    REQUIRE(r.list.declared.size() == 4);
    CHECK(r.list.declared[0].image == r.color);
    CHECK(r.list.declared[0].state == gpu::NativeState::ShaderRead);
    CHECK(r.list.declared[1].image == r.depth);
    CHECK(r.list.declared[1].state == gpu::NativeState::ShaderRead);
    CHECK(r.list.declared[2].image == r.velocity);
    CHECK(r.list.declared[2].state == gpu::NativeState::ShaderRead);
    CHECK(r.list.declared[3].image == r.output);
    CHECK(r.list.declared[3].state == gpu::NativeState::UnorderedAccess);
    CHECK(r.list.ends == 1);

    // An unset exposure is 1, a frame time of 0 is 60 Hz's, a jitter that is not a number is none, and the reactive mask goes when there is one.
    r.in.exposure = 0.0f;
    r.in.frameTimeMs = 0.0f;
    r.in.jitter[0] = std::numeric_limits<float>::quiet_NaN();
    r.in.jitter[1] = 7.0f;
    r.in.linear = true;
    r.add_reactive();
    REQUIRE(r.draw());
    CHECK(fk.dispatch.preExposure == doctest::Approx(1.0f));
    CHECK(fk.dispatch.frameTimeDelta == doctest::Approx(1000.0f / 60.0f));
    CHECK(fk.dispatch.jitterOffset.x == 0.0f);
    CHECK(fk.dispatch.jitterOffset.y == doctest::Approx(1.0f));  // clamped to one pixel
    CHECK(fk.dispatch.reactive.resource == r.dev.native_image(r.reactive).resource);
    CHECK(fk.dispatch.reactive.description.format == abi::kFormatR8Unorm);
    CHECK(fk.dispatch.reactive.state == abi::kStatePixelComputeRead);
    REQUIRE(r.list.declared.size() == 5);
    CHECK(r.list.declared[3].image == r.reactive);
    CHECK(r.list.declared[3].state == gpu::NativeState::ShaderRead);
    CHECK(r.list.declared[4].state == gpu::NativeState::UnorderedAccess);
    CHECK(fk.dispatch.flags == 0);  // linear light has no colour space flag
}

TEST_CASE("fsr Vulkan: the images go as VkImage handles, the device context names the Vulkan device, and an older "
          "loader gets the older descriptor") {
    Rig r(gpu::Backend::Vulkan);
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fk.backendType == abi::kCreateBackendVk);
    CHECK(fk.backendVk.device == r.dev.native().device);
    CHECK(fk.backendVk.physicalDevice == r.dev.native().physicalDevice);
    CHECK(fk.backendVk.deviceProcAddr == r.dev.native().getDeviceProcAddr);
    CHECK(fk.dispatch.color.resource == reinterpret_cast<void*>(std::uintptr_t(r.dev.native_image(r.color).vkImage)));
    CHECK(fk.dispatch.output.resource == reinterpret_cast<void*>(std::uintptr_t(r.dev.native_image(r.output).vkImage)));
    CHECK(fk.dispatch.output.state == abi::kStateUnorderedAccess);
    CHECK(fk.dispatch.commandList == static_cast<const void*>(&r.list.token));
    CHECK(fk.creates == 1);

    // FSR 3.1.4's loader refuses the new backend descriptor: the older one is tried, once, and the context is made.
    r.fsr->release(r.dev);
    fk.reset();
    fk.createVkNewRc = abi::kUnknownDescType;
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fk.creates == 2);
    REQUIRE(fk.backendTypes.size() == 2);
    CHECK(fk.backendTypes[0] == abi::kCreateBackendVk);
    CHECK(fk.backendTypes[1] == abi::kCreateBackendVkDeprecated);
    CHECK(fk.dispatches == 1);
}

// ---- failures ------------------------------------------------------------------------------------------------------------------------------

TEST_CASE("fsr: a context that cannot be made, a dispatch the library refuses and a native section that does not open "
          "all say why and return false") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);

    fk.createRc = abi::kParameterError;
    fk.createMessage = L"the output size is too large";
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "ffxCreateContext"));
    CHECK(has(r.frame.error, "bad parameter"));
    CHECK(has(r.frame.error, "the output size is too large"));  // the library's own message, through the callback
    CHECK(has(r.frame.error, "160x90 -> 320x180"));
    CHECK(fk.dispatches == 0);
    fk.createRc = abi::kNoProvider;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "no FSR provider for this GPU"));
    fk.createRc = 0;
    fk.createMessage = nullptr;

    // The context is made on the next frame (a refusal leaves nothing behind), and a dispatch the library refuses is a false with its code.
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    fk.dispatchRc = abi::kRuntimeError;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "ffxDispatch"));
    CHECK(has(r.frame.error, "runtime error"));
    CHECK(r.list.ends == 2);  // the native section is closed whatever FSR answered
    fk.dispatchRc = 0;
    REQUIRE(r.draw());
    CHECK(fk.dispatch.reset);  // after a failure the history starts again

    // The native section does not open: FSR is not called.
    r.list.failBegin = true;
    const int dispatchesBefore = fk.dispatches;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "native command section"));
    CHECK(fk.dispatches == dispatchesBefore);
    r.list.failBegin = false;

    // The device knows no native resource, or a format FSR has no name for.
    r.dev.noNative = true;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "no native resource"));
    r.dev.noNative = false;
    r.frame.colorFormat = gpu::PixelFormat::Rg32F;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "colour"));
    CHECK(has(r.frame.error, "pixel format"));
    r.frame.colorFormat = gpu::PixelFormat::Rgba8;
    REQUIRE(r.draw());
}

TEST_CASE(
    "fsr: a frame without what FSR reads, a probe that did not run or the wrong backend is refused before any call") {
    Rig r(gpu::Backend::D3d12);
    CHECK_FALSE(r.draw());  // no probe: no library
    CHECK(has(r.frame.error, "probe"));
    REQUIRE(r.fsr->probe(r.env()).available);
    const gpu::Image velocity = r.frame.velocity;
    r.frame.velocity = {};
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "velocity"));
    r.frame.velocity = velocity;
    r.in.outW = 0;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "empty picture"));
    r.in.outW = r.outW;
    CHECK(fk.creates == 0);
    CHECK(fk.dispatches == 0);

    Rig vk(gpu::Backend::Vulkan);  // loaded for Vulkan, drawn on D3D12 by the first provider: another provider's frame
    REQUIRE(vk.fsr->probe(vk.env()).available);
    vk.frame.device = &r.dev;
    CHECK_FALSE(vk.draw());
    CHECK(has(vk.frame.error, "Vulkan"));
}

// ---- the choice and the reports ---------------------------------------------------------------------------------------------------------

TEST_CASE("fsr: auto picks it on an AMD GPU, an explicit fsr runs on any GPU, and neither without a usable FSR") {
    using render::UpscalerCaps;
    using render::UpscalerMode;
    render::UpscalerSettings s;
    UpscalerCaps caps;
    caps.temporal = true;
    caps.gpuVendor = GpuVendor::Amd;
    caps.fsr = true;
    s.mode = UpscalerMode::Auto;
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Fsr);
    caps.fsr = false;  // not installed, or a frame it refused
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Temporal);
    caps.fsr = true;
    caps.gpuVendor = GpuVendor::Nvidia;  // another maker's GPU: auto asks its own SDK (DLSS, not installed here)
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Temporal);
    s.mode = UpscalerMode::Fsr;  // chosen explicitly: any GPU
    for (const GpuVendor v : {GpuVendor::Intel, GpuVendor::Nvidia, GpuVendor::Amd, GpuVendor::Other})
        CHECK_MESSAGE((caps.gpuVendor = v, render::effective_upscaler_mode(s, caps) == UpscalerMode::Fsr),
                      render::gpu_vendor_name(v));
    caps.fsr = false;
    CHECK(render::effective_upscaler_mode(s, caps) == UpscalerMode::Temporal);

    // The environment of an AMD device is an AMD one: the probe of that env is what `fsr` is told.
    FDevice amd(gpu::Backend::D3d12, 0x1002);
    CHECK(render::vendor_env_of(amd).vendor == GpuVendor::Amd);
}

TEST_CASE("fsr: the feature row of render.supports takes the provider's answer with its reason, and its backends "
          "column names D3D12 and Vulkan") {
    render::FeatureEnv env;
    env.backend = render::FeatureBackend::D3d11;
    std::array<render::VendorProbe, render::kVendorUpscalerCount> answers;
    answers[2].available = false;
    answers[2].reason = "FSR is not installed: run `factoria setup fidelityfx`.";
    render::set_vendor_upscalers_env(env, answers);
    const int row = render::find_feature("fsr");
    REQUIRE(row >= 0);
    std::string why;
    CHECK_FALSE(render::feature_supported(env, row, &why));
    CHECK(why == answers[2].reason);
    answers[2] = render::VendorProbe{true, ""};
    render::set_vendor_upscalers_env(env, answers);
    CHECK(render::feature_supported(env, row, &why));
    const Json report = render::feature_report(env, "d3d11");
    bool found = false;
    for (const Json& f : report["features"])
        if (f["name"] == "fsr") {
            found = true;
            CHECK(f["supported"] == true);
            CHECK(f["backends"]["D3D12"] == true);
            CHECK(f["backends"]["Vulkan"] == true);
            CHECK(f["backends"]["D3D11"] == false);  // FSR never draws on Direct3D 11
            CHECK(f["backends"]["Metal"] == false);
        }
    CHECK(found);
}

TEST_CASE("fsr: the dynamic resolution flag follows the setting being on, not the size of this frame") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);
    // The setting is off: the render size moving once (a scale step of the renderer) does not change the context.
    r.in.dynamicResolution = true;
    REQUIRE(r.draw());
    CHECK((fk.create.flags & abi::kEnableDynamicResolution) == 0);
    CHECK(fk.creates == 1);
    r.in.dynamicResolution = false;
    REQUIRE(r.draw());
    CHECK(fk.creates == 1);
    // The setting is on: the flag is in the context from its first frame, whatever size that frame has, and it stays through the steps.
    r.in.dynamicResolutionEnabled = true;
    r.in.dynamicResolution = false;
    REQUIRE(r.draw());
    CHECK(fk.creates == 2);
    CHECK((fk.create.flags & abi::kEnableDynamicResolution) != 0);
    r.in.dynamicResolution = true;
    r.resize(120, 68, 320, 180);
    r.in.dynamicResolutionEnabled = true;
    r.in.dynamicResolution = true;
    r.in.maxRenderW = 160;
    r.in.maxRenderH = 90;
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fk.creates == 2);
    CHECK(fk.dispatch.renderSize.width == 120);
    r.in.dynamicResolution = false;
    REQUIRE(r.draw());
    CHECK(fk.creates == 2);
}

TEST_CASE("fsr: what the library said before a dispatch is not blamed on it, and what it says during one is") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);
    fk.createWarning = L"a warning from the context's creation";
    REQUIRE(r.draw());
    fk.dispatchRc = abi::kRuntimeError;
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "ffxDispatch"));
    CHECK_FALSE(has(r.frame.error, "a warning from the context's creation"));
    fk.dispatchMessage = L"the depth image is empty";
    CHECK_FALSE(r.draw());
    CHECK(has(r.frame.error, "the depth image is empty"));
}

TEST_CASE("fsr: a context made on one device is made again on another, even at the address of a destroyed one") {
    Rig r(gpu::Backend::D3d12);
    REQUIRE(r.fsr->probe(r.env()).available);
    REQUIRE(r.draw());
    CHECK(fk.creates == 1);
    FDevice other(gpu::Backend::D3d12);
    CHECK(other.generation() != r.dev.generation());
    FList otherList(other, gpu::Backend::D3d12);
    r.frame.device = &other;
    r.frame.list = &otherList;
    REQUIRE_MESSAGE(r.draw(), r.frame.error);
    CHECK(fk.destroys == 1);
    CHECK(fk.creates == 2);
    r.fsr->release(other);
    CHECK(fk.destroys == 2);
}
