// M78-P5d: the Intel XeSS frame generation provider (src/render_framegen_xess.{h,cpp}). No Intel library is involved: the functions of
// libxess_fg and of libxell are fakes behind a fake VendorLoader, the adapter and the device are fakes that answer a vendor id and a native
// device, and the command list is a recording list that opens native sections. What is tested is what the engine asks of each library and in
// which order (XeLL first, the context, XeLL told to the swapchain before it exists, the swapchain made from the window's description), what
// a missing or failing library does (the reasons, the one failure that keeps the provider off for the run), the tags of a frame (resources,
// states, constants, ids), and that everything is given back in the order the SDK asks (XeSS-FG before XeLL). That the real swapchain
// generates frames is for a machine with an Intel Arc GPU, which this build was not run on.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "gpu/recording_device.h"
#include "render_framegen.h"
#include "render_framegen_xess.h"
#include "render_latency.h"
#include "render_latency_xell.h"

using namespace fa;
using render::FrameGenSlot;
using render::GpuVendor;
using render::LatencyDriver;

namespace {

namespace fg = fa::render::xefg_abi;
namespace xl = fa::render::xell_abi;

// The events of both fake libraries, in the order they were called ("xell.create", "fg.init" ...).
std::vector<std::string> g_events;

bool contains(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }
std::size_t index_of(const std::string& event) {
    const auto it = std::find(g_events.begin(), g_events.end(), event);
    return it == g_events.end() ? std::size_t(-1) : std::size_t(it - g_events.begin());
}
int count_of(const std::string& event) { return int(std::count(g_events.begin(), g_events.end(), event)); }

// ---- the fake XeSS-FG library ---------------------------------------------------------------------------------------------------------

struct FgFx {
    fg::Version version{1, 0, 0, 0};
    std::int32_t versionRc = 0, createRc = 0, latencyRc = 0, initRc = 0, swapRc = 0, enableRc = 0, presentIdRc = 0,
                 constantsRc = 0, resourceRc = 0, statusRc = 0;
    int token = 0, swapchainToken = 0, contexts = 0;
    void* createdFor = nullptr;
    void* latencyCtx = nullptr;
    // What the init call was given.
    void *initHwnd = nullptr, *initQueue = nullptr, *initFactory = nullptr;
    const void* initDesc = nullptr;
    const void* initFullscreen = nullptr;
    fg::D3d12InitParams initParams{};
    fg::Guid riid{};
    std::vector<std::uint32_t> presentIds, enables;
    std::vector<std::pair<std::uint32_t, fg::FrameConstants>> constants;
    struct Tag {
        std::uint32_t id;
        fg::D3d12ResourceData data;
        void* list;
    };
    std::vector<Tag> tags;
    fg::PresentStatus status{};
    void reset() { *this = FgFx{}; }
};
FgFx fgfx;

fg::Handle fg_handle() { return reinterpret_cast<fg::Handle>(&fgfx.token); }
std::int32_t fg_get_version(fg::Version* v) {
    *v = fgfx.version;
    return fgfx.versionRc;
}
std::int32_t fg_create(void* device, fg::Handle* out) {
    g_events.push_back("fg.create");
    fgfx.createdFor = device;
    if (fgfx.createRc != 0) return fgfx.createRc;
    *out = fg_handle();
    ++fgfx.contexts;
    return 0;
}
std::int32_t fg_destroy(fg::Handle) {
    g_events.push_back("fg.destroy");
    --fgfx.contexts;
    return 0;
}
std::int32_t fg_init(fg::Handle, void* hwnd, const void* desc, const void* fullscreen, void* queue, void* factory,
                     const fg::D3d12InitParams* params) {
    g_events.push_back("fg.init");
    fgfx.initHwnd = hwnd;
    fgfx.initDesc = desc;
    fgfx.initFullscreen = fullscreen;
    fgfx.initQueue = queue;
    fgfx.initFactory = factory;
    fgfx.initParams = *params;
    return fgfx.initRc;
}
std::int32_t fg_get_swapchain(fg::Handle, const fg::Guid* riid, void** out) {
    g_events.push_back("fg.getSwapChain");
    fgfx.riid = *riid;
    if (fgfx.swapRc != 0) return fgfx.swapRc;
    *out = &fgfx.swapchainToken;
    return 0;
}
std::int32_t fg_latency(fg::Handle, void* xell) {
    g_events.push_back("fg.setLatencyReduction");
    fgfx.latencyCtx = xell;
    return fgfx.latencyRc;
}
std::int32_t fg_enabled(fg::Handle, std::uint32_t enable) {
    g_events.push_back(enable ? "fg.enable" : "fg.disable");
    fgfx.enables.push_back(enable);
    return fgfx.enableRc;
}
std::int32_t fg_present_id(fg::Handle, std::uint32_t id) {
    g_events.push_back("fg.setPresentId");
    fgfx.presentIds.push_back(id);
    return fgfx.presentIdRc;
}
std::int32_t fg_constants(fg::Handle, std::uint32_t id, const fg::FrameConstants* c) {
    g_events.push_back("fg.tagConstants");
    fgfx.constants.emplace_back(id, *c);
    return fgfx.constantsRc;
}
std::int32_t fg_resource(fg::Handle, void* list, std::uint32_t id, const fg::D3d12ResourceData* d) {
    g_events.push_back("fg.tagResource");
    fgfx.tags.push_back({id, *d, list});
    return fgfx.resourceRc;
}
std::int32_t fg_status(fg::Handle, fg::PresentStatus* out) {
    *out = fgfx.status;
    return fgfx.statusRc;
}

class FgLib final : public render::VendorLibrary {
public:
    std::vector<std::string> hidden;
    void* symbol(const char* name) override {
        const std::string n = name;
        if (std::find(hidden.begin(), hidden.end(), n) != hidden.end()) return nullptr;
        if (n == "xefgSwapChainGetVersion") return reinterpret_cast<void*>(&fg_get_version);
        if (n == "xefgSwapChainD3D12CreateContext") return reinterpret_cast<void*>(&fg_create);
        if (n == "xefgSwapChainDestroy") return reinterpret_cast<void*>(&fg_destroy);
        if (n == "xefgSwapChainD3D12InitFromSwapChainDesc") return reinterpret_cast<void*>(&fg_init);
        if (n == "xefgSwapChainD3D12GetSwapChainPtr") return reinterpret_cast<void*>(&fg_get_swapchain);
        if (n == "xefgSwapChainSetLatencyReduction") return reinterpret_cast<void*>(&fg_latency);
        if (n == "xefgSwapChainSetEnabled") return reinterpret_cast<void*>(&fg_enabled);
        if (n == "xefgSwapChainSetPresentId") return reinterpret_cast<void*>(&fg_present_id);
        if (n == "xefgSwapChainTagFrameConstants") return reinterpret_cast<void*>(&fg_constants);
        if (n == "xefgSwapChainD3D12TagFrameResource") return reinterpret_cast<void*>(&fg_resource);
        if (n == "xefgSwapChainGetLastPresentStatus") return reinterpret_cast<void*>(&fg_status);
        return nullptr;
    }
    const std::string& path() const override { return path_; }

private:
    std::string path_ = "fake/libxess_fg.dll";
};

// ---- the fake XeLL library ------------------------------------------------------------------------------------------------------------

struct XlFx {
    std::int32_t setModeRc = 0, createRc = 0;
    int token = 0, contexts = 0;
    std::vector<xl::SleepParams> modes;
    std::vector<std::uint32_t> sleeps;
    void reset() { *this = XlFx{}; }
};
XlFx xlfx;

std::int32_t xl_get_version(xl::Version* v) {
    *v = {1, 2, 0, 0};
    return 0;
}
std::int32_t xl_create(void*, xl::Context* out) {
    g_events.push_back("xell.create");
    if (xlfx.createRc != 0) return xlfx.createRc;
    *out = reinterpret_cast<xl::Context>(&xlfx.token);
    ++xlfx.contexts;
    return 0;
}
std::int32_t xl_destroy(xl::Context) {
    g_events.push_back("xell.destroy");
    --xlfx.contexts;
    return 0;
}
std::int32_t xl_set_mode(xl::Context, const xl::SleepParams* p) {
    g_events.push_back("xell.setSleepMode");
    xlfx.modes.push_back(*p);
    return xlfx.setModeRc;
}
std::int32_t xl_sleep(xl::Context, std::uint32_t id) {
    xlfx.sleeps.push_back(id);
    return 0;
}
std::int32_t xl_marker(xl::Context, std::uint32_t, std::int32_t) { return 0; }

class XlLib final : public render::VendorLibrary {
public:
    void* symbol(const char* name) override {
        const std::string n = name;
        if (n == "xellGetVersion") return reinterpret_cast<void*>(&xl_get_version);
        if (n == "xellD3D12CreateContext") return reinterpret_cast<void*>(&xl_create);
        if (n == "xellDestroyContext") return reinterpret_cast<void*>(&xl_destroy);
        if (n == "xellSetSleepMode") return reinterpret_cast<void*>(&xl_set_mode);
        if (n == "xellSleep") return reinterpret_cast<void*>(&xl_sleep);
        if (n == "xellAddMarkerData") return reinterpret_cast<void*>(&xl_marker);
        return nullptr;
    }
    const std::string& path() const override { return path_; }

private:
    std::string path_ = "fake/libxell.dll";
};

// One loader for both libraries (by file name).
class Loader final : public render::VendorLoader {
public:
    bool fgInstalled = true, xellInstalled = true, fgLoads = true;
    std::vector<std::string> fgHidden;
    std::filesystem::path find(const render::VendorLibrarySpec& spec, std::string* why) override {
        const std::string file = spec.fileName;
        CHECK(std::string(spec.setupId) == "xess");
        CHECK(std::string(spec.dirEnv) == "FA_XESS_DIR");
        const bool installed = file == "libxess_fg.dll" ? fgInstalled : xellInstalled;
        if (!installed) {
            if (why) *why = "the fake loader has no " + file;
            return {};
        }
        return std::filesystem::path("fake") / file;
    }
    std::unique_ptr<render::VendorLibrary> load(const std::filesystem::path& path, std::string* why) override {
        if (path.filename() == "libxess_fg.dll") {
            if (!fgLoads) {
                if (why) *why = "the fake loader cannot load it";
                return nullptr;
            }
            auto l = std::make_unique<FgLib>();
            l->hidden = fgHidden;
            return l;
        }
        return std::make_unique<XlLib>();
    }
};

// Puts the fake loader and the real XeLL provider in for the length of a test; the fixtures start clean.
struct Rig {
    Loader loader;
    std::unique_ptr<render::LatencyProvider> xell = render::make_xell_provider();
    Rig() {
        g_events.clear();
        fgfx.reset();
        xlfx.reset();
        render::set_vendor_loader_for_test(&loader);
        render::set_latency_provider_for_test(LatencyDriver::Xell, xell.get());
    }
    ~Rig() {
        render::set_latency_provider_for_test(LatencyDriver::Xell, nullptr);
        render::set_vendor_loader_for_test(nullptr);
    }
    Rig(const Rig&) = delete;
    Rig& operator=(const Rig&) = delete;
};

// ---- the device, the adapter, the list -------------------------------------------------------------------------------------------------

int g_deviceToken = 0, g_queueToken = 0, g_hwndToken = 0, g_factoryToken = 0, g_descToken = 0, g_listToken = 0;

class XDevice : public gpu::RecordingDevice {
public:
    XDevice(gpu::Backend deviceBackend, std::uint32_t pciVendor) : backend_(deviceBackend) {
        info_ = gpu::RecordingDevice::info();
        info_.backend = deviceBackend;
        info_.gpu.vendorId = pciVendor;
        info_.gpu.vendor = gpu::gpu_vendor_from_pci(pciVendor);
    }
    gpu::Backend backend() const override { return backend_; }
    const gpu::DeviceInfo& info() const override { return info_; }
    gpu::NativeDevice native() const override {
        gpu::NativeDevice n;
        n.device = &g_deviceToken;
        n.commandQueue = nullptr;
        n.context = &g_queueToken;
        return n;
    }
    // The ID3D12Resource of an image: a distinct pointer per image id (0 for the handle that was never given an image).
    gpu::NativeImage native_image(gpu::Image image) const override {
        gpu::NativeImage n;
        if (image.valid() && !noResources)
            n.resource = reinterpret_cast<const void*>(std::uintptr_t(0x5000 + image.id));
        return n;
    }
    bool noResources = false;

private:
    gpu::Backend backend_;
    gpu::DeviceInfo info_;
};

// A list that opens native sections and says so.
class NList final : public gpu::RecordingCommandList {
public:
    explicit NList(gpu::RecordingDevice& d) : gpu::RecordingCommandList(d) {}
    std::vector<gpu::NativeUse> uses;
    bool failBegin = false;
    Result<gpu::NativeCommands> begin_native(std::span<const gpu::NativeUse> u) override {
        g_events.push_back("list.begin");
        if (failBegin) return make_error("fake: no native section", "");
        uses.assign(u.begin(), u.end());
        gpu::NativeCommands c;
        c.backend = gpu::Backend::D3d12;
        c.list = &g_listToken;
        return c;
    }
    Result<void> end_native(std::span<const gpu::NativeUse>) override {
        g_events.push_back("list.end");
        return {};
    }
};

// A fake IDXGIAdapter1: a vtable whose slot 10 (GetDesc1) writes the vendor id at byte 256 of the description.
std::uint32_t g_adapterVendor = 0x8086;
std::int32_t fake_get_desc1(void*, void* desc) {
    std::memcpy(static_cast<unsigned char*>(desc) + 256, &g_adapterVendor, sizeof(g_adapterVendor));
    return 0;
}
struct FakeAdapter {
    void* const* vtable;
};
void* const* adapter_vtable() {
    static void* table[16] = {};
    table[10] = reinterpret_cast<void*>(&fake_get_desc1);
    return table;
}

render::VendorEnv env_of(const XDevice& d, GpuVendor vendor, bool windows = true) {
    render::VendorEnv e;
    e.backend = d.backend();
    e.vendor = vendor;
    e.device = &d;
    e.windows = windows;
    return e;
}

render::FrameGenSwapchain swapchain_of(const XDevice& d) {
    render::FrameGenSwapchain s;
    s.backend = d.backend();
    s.width = 1920;
    s.height = 1080;
    return s;
}

// A provider and its hook, with the helpers every test uses.
struct Hook {
    std::shared_ptr<render::FrameGenProvider> p = render::make_xess_framegen_provider();
    std::shared_ptr<gpu::DeviceHook> hook = p->device_hook();
    FakeAdapter adapter{adapter_vtable()};
    gpu::D3d12SwapchainCreate create;

    void device_created(std::uint32_t vendor = 0x8086) {
        g_adapterVendor = vendor;
        gpu::D3d12DeviceCreated dc;
        dc.device = &g_deviceToken;
        dc.queue = &g_queueToken;
        dc.adapter = &adapter;
        hook->d3d12_device_created(dc);
        CHECK(dc.error.empty());
    }
    bool make_swapchain() {
        create = gpu::D3d12SwapchainCreate{};
        create.factory = &g_factoryToken;
        create.queue = &g_queueToken;
        create.hwnd = &g_hwndToken;
        create.desc = &g_descToken;
        return hook->d3d12_create_swapchain(create);
    }
};

}  // namespace

// ---- the ABI --------------------------------------------------------------------------------------------------------------------------

TEST_CASE("xess frame generation: the declared C ABI has the SDK's sizes") {
    if (sizeof(void*) != 8) return;  // the structs are the 64-bit ones
    CHECK(sizeof(fg::Version) == 8);
    CHECK(sizeof(fg::Dim2) == 8);
    CHECK(sizeof(fg::FrameConstants) == 152);
    CHECK(sizeof(fg::PresentStatus) == 12);
    CHECK(sizeof(fg::D3d12InitParams) == 72);
    CHECK(sizeof(fg::D3d12ResourceData) == 40);
    CHECK(sizeof(fg::Guid) == 16);
}

TEST_CASE(
    "xess frame generation: the library is libxess_fg.dll of `factoria setup xess`, and a missing export is named") {
    const render::VendorLibrarySpec spec = render::xefg_library_spec();
    CHECK(std::string(spec.fileName) == "libxess_fg.dll");
    CHECK(std::string(spec.setupId) == "xess");
    CHECK(std::string(spec.dirEnv) == "FA_XESS_DIR");
    FgLib lib;
    render::XefgApi api;
    CHECK(render::xefg_load_api(lib, api).empty());
    CHECK(api.d3d12Create != nullptr);
    CHECK(api.getLastPresentStatus != nullptr);
    FgLib missing;
    missing.hidden = {"xefgSwapChainSetEnabled"};
    render::XefgApi none;
    CHECK(render::xefg_load_api(missing, none) == "xefgSwapChainSetEnabled");
    CHECK(none.d3d12Create == nullptr);  // nothing is taken from a library that lacks a required export
    FgLib optional;
    optional.hidden = {"xefgSwapChainGetLastPresentStatus"};
    render::XefgApi partial;
    CHECK(render::xefg_load_api(optional, partial).empty());
    CHECK(partial.getLastPresentStatus == nullptr);
    CHECK(render::xefg_result_text(-1) == "unsupported device");
    CHECK(render::xefg_result_text(-21) == "wrong call order");
    CHECK(render::xefg_result_text(-77) == "result -77");
}

TEST_CASE("xess frame generation: the projection is the Direct3D one, row-major with the row-vector convention") {
    // proj: P00, P11, P02, P12, P03, P13, P32, P33 of a perspective camera.
    const float persp[8] = {1.5f, 2.0f, 0.1f, -0.2f, 0.0f, 0.0f, -1.0f, 0.0f};
    float m[16];
    render::xefg_projection(persp, 0.1f, 100.0f, m);
    const auto at = [&](int row, int col) { return m[col * 4 + row]; };  // the memory of a column-major Mat4
    CHECK(at(0, 0) == doctest::Approx(1.5f));
    CHECK(at(1, 1) == doctest::Approx(2.0f));
    CHECK(at(0, 2) == doctest::Approx(0.1f));
    CHECK(at(1, 2) == doctest::Approx(-0.2f));
    CHECK(at(3, 2) == doctest::Approx(-1.0f));
    CHECK(at(3, 3) == doctest::Approx(0.0f));
    // z from 0 at the near plane to 1 at the far one: z' = (a * z + b) / -z for a view-space z of -near and -far.
    const float a = at(2, 2), b = at(2, 3);
    CHECK((a * -0.1f + b) / 0.1f == doctest::Approx(0.0f).epsilon(1e-4));
    CHECK((a * -100.0f + b) / 100.0f == doctest::Approx(1.0f).epsilon(1e-4));
    // An orthographic camera (P32 = 0, P33 = 1) with the nominal planes.
    const float ortho[8] = {0.01f, 0.02f, 0, 0, 0, 0, 0.0f, 1.0f};
    render::xefg_projection(ortho, -1000.0f, 1000.0f, m);
    CHECK(at(3, 2) == doctest::Approx(0.0f));
    CHECK(at(3, 3) == doctest::Approx(1.0f));
    CHECK(at(2, 2) * 1000.0f - at(2, 3) ==
          doctest::Approx(-1.0f).epsilon(1e-4));  // z of the far plane (view z = -1000)... maps to 1
}

// ---- the probe ------------------------------------------------------------------------------------------------------------------------

TEST_CASE("xess frame generation: probe reasons") {
    Rig rig;
    XDevice d12(gpu::Backend::D3d12, 0x8086);
    const auto probe = [&](const render::VendorEnv& env) { return render::make_xess_framegen_provider()->probe(env); };
    {
        const auto r = probe(env_of(d12, GpuVendor::Intel, /*windows=*/false));
        CHECK_FALSE(r.available);
        CHECK(contains(r.reason, "Windows only"));
    }
    {
        XDevice vk(gpu::Backend::Vulkan, 0x8086);
        const auto r = probe(env_of(vk, GpuVendor::Intel));
        CHECK_FALSE(r.available);
        CHECK(contains(r.reason, "D3D12"));
    }
    {
        const auto r = probe(env_of(d12, GpuVendor::Nvidia));
        CHECK_FALSE(r.available);
        CHECK(contains(r.reason, "Intel Arc"));
        CHECK(contains(r.reason, "NVIDIA"));
        CHECK(contains(r.reason, "dlss"));
    }
    rig.loader.fgInstalled = false;
    {
        const auto r = probe(env_of(d12, GpuVendor::Intel));
        CHECK_FALSE(r.available);
        CHECK(contains(r.reason, "not installed"));
        CHECK(contains(r.reason, "factoria setup xess"));
    }
    rig.loader.fgInstalled = true;
    rig.loader.fgLoads = false;
    CHECK(contains(probe(env_of(d12, GpuVendor::Intel)).reason, "could not be loaded"));
    rig.loader.fgLoads = true;
    rig.loader.fgHidden = {"xefgSwapChainTagFrameConstants"};
    {
        const auto r = probe(env_of(d12, GpuVendor::Intel));
        CHECK(contains(r.reason, "xefgSwapChainTagFrameConstants"));
        CHECK(contains(r.reason, "factoria setup xess"));
    }
    rig.loader.fgHidden.clear();
    fgfx.versionRc = -2;
    {
        const auto r = probe(env_of(d12, GpuVendor::Intel));
        CHECK_FALSE(r.available);
        CHECK(contains(r.reason, "driver is too old"));
    }
    fgfx.versionRc = 0;
    // XeSS frame generation cannot run without XeLL: its library is part of the answer.
    rig.loader.xellInstalled = false;
    {
        const auto r = probe(env_of(d12, GpuVendor::Intel));
        CHECK_FALSE(r.available);
        CHECK(contains(r.reason, "XeLL"));
        CHECK(contains(r.reason, "factoria setup xess"));
    }
    rig.loader.xellInstalled = true;
    {
        const auto r = probe(env_of(d12, GpuVendor::Intel));
        CHECK(r.available);
        CHECK(r.reason.empty());
    }
    // The slot, the setup id and the backends the seam reads.
    auto p = render::make_xess_framegen_provider();
    CHECK(p->slot() == FrameGenSlot::Xess);
    CHECK(p->setup_id() == "xess");
    CHECK(p->backends() == (1u << unsigned(gpu::Backend::D3d12)));
    CHECK_FALSE(p->wants_reversed_depth());
    CHECK(p->device_hook() != nullptr);
    // The hook takes part only for the modes that can run XeSS-FG: a game started with dlss or fsr keeps its swapchain for them.
    CHECK(p->device_hook_for(render::FrameGenMode::Xess) != nullptr);
    CHECK(p->device_hook_for(render::FrameGenMode::Auto) != nullptr);
    CHECK(p->device_hook_for(render::FrameGenMode::Dlss) == nullptr);
    CHECK(p->device_hook_for(render::FrameGenMode::Fsr) == nullptr);
    CHECK(p->device_hook_for(render::FrameGenMode::Off) == nullptr);
    CHECK(p->failure().empty());
}

// ---- the hook makes the swapchain -----------------------------------------------------------------------------------------------------

TEST_CASE("xess frame generation: the swapchain is made from XeLL, the context, XeLL told to it, and the window's "
          "description") {
    if (sizeof(void*) != 8) return;
    Rig rig;
    Hook h;
    h.device_created();
    REQUIRE(h.make_swapchain());
    CHECK(h.create.error.empty());
    CHECK(h.create.swapchain == &fgfx.swapchainToken);
    // The order the SDK asks: XeLL's context, XeSS-FG's, XeLL given to it BEFORE it is initialised, the swapchain asked for last.
    const std::vector<std::string> expected = {"xell.create", "fg.create", "fg.setLatencyReduction", "fg.init",
                                               "fg.getSwapChain"};
    CHECK(g_events == expected);
    CHECK(fgfx.createdFor == &g_deviceToken);
    CHECK(fgfx.latencyCtx == &xlfx.token);
    CHECK(fgfx.initHwnd == &g_hwndToken);
    CHECK(fgfx.initDesc == &g_descToken);
    CHECK(fgfx.initFullscreen == nullptr);
    CHECK(fgfx.initQueue == &g_queueToken);
    CHECK(fgfx.initFactory == &g_factoryToken);
    CHECK(fgfx.initParams.applicationSwapChain == nullptr);
    CHECK(fgfx.initParams.initFlags == 0);  // not inverted, not NDC, unjittered vectors
    CHECK(fgfx.initParams.maxInterpolatedFrames == 1);
    CHECK(fgfx.initParams.uiMode == fg::kUiModeNone);
    // IID_IDXGISwapChain1.
    CHECK(fgfx.riid.data1 == 0x790a45f7);
    CHECK(fgfx.riid.data2 == 0x0d42);
    CHECK(fgfx.riid.data3 == 0x4876);
    CHECK(fgfx.riid.data4[0] == 0x98);
    CHECK(fgfx.riid.data4[7] == 0xaa);
    h.hook->device_destroying();
    CHECK(fgfx.contexts == 0);
    CHECK(xlfx.contexts == 0);
}

TEST_CASE(
    "xess frame generation: the hook makes no swapchain where it cannot, and says why only when something broke") {
    if (sizeof(void*) != 8) return;
    Rig rig;
    {  // not an Intel GPU: the engine makes its own swapchain, nothing of Intel is touched
        Hook h;
        h.device_created(0x10de);
        CHECK_FALSE(h.make_swapchain());
        CHECK(h.create.error.empty());
        CHECK(g_events.empty());
        XDevice dev(gpu::Backend::D3d12, 0x10de);
        const std::string why = h.p->start(dev, swapchain_of(dev));
        CHECK(contains(why, "not an Intel"));
    }
    {  // the library is not installed: the probe tells the user; the hook is silent
        rig.loader.fgInstalled = false;
        Hook h;
        h.device_created();
        CHECK_FALSE(h.make_swapchain());
        CHECK(h.create.error.empty());
        CHECK(g_events.empty());
        XDevice dev(gpu::Backend::D3d12, 0x8086);
        CHECK(contains(h.p->start(dev, swapchain_of(dev)), "not installed"));
        rig.loader.fgInstalled = true;
    }
    {  // installed and broken: an error, so the device marks the hook unavailable and logs it
        rig.loader.fgHidden = {"xefgSwapChainDestroy"};
        Hook h;
        h.device_created();
        CHECK_FALSE(h.make_swapchain());
        CHECK(contains(h.create.error, "xefgSwapChainDestroy"));
        rig.loader.fgHidden.clear();
    }
    {  // no XeLL library
        rig.loader.xellInstalled = false;
        Hook h;
        h.device_created();
        CHECK_FALSE(h.make_swapchain());
        CHECK(h.create.error.empty());
        XDevice dev(gpu::Backend::D3d12, 0x8086);
        const std::string why = h.p->start(dev, swapchain_of(dev));
        CHECK(contains(why, "XeLL"));
        CHECK(contains(why, "factoria setup xess"));
        rig.loader.xellInstalled = true;
    }
    {  // XeLL's own context fails
        g_events.clear();
        xlfx.createRc = -1;
        Hook h;
        h.device_created();
        CHECK_FALSE(h.make_swapchain());
        CHECK(contains(h.create.error, "XeLL"));
        CHECK(fgfx.contexts == 0);
        CHECK(index_of("fg.create") == std::size_t(-1));
        xlfx.createRc = 0;
    }
}

TEST_CASE("xess frame generation: a failing SDK call gives everything back, XeSS-FG before XeLL, and names the call") {
    if (sizeof(void*) != 8) return;
    struct Case {
        const char* what;
        std::int32_t FgFx::* field;
        std::int32_t rc;
        const char* call;
    };
    const Case cases[] = {{"create", &FgFx::createRc, -1, "xefgSwapChainD3D12CreateContext"},
                          {"latency", &FgFx::latencyRc, -15, "xefgSwapChainSetLatencyReduction"},
                          {"init", &FgFx::initRc, -2, "xefgSwapChainD3D12InitFromSwapChainDesc"},
                          {"swapchain", &FgFx::swapRc, -17, "xefgSwapChainD3D12GetSwapChainPtr"}};
    for (const Case& c : cases) {
        CAPTURE(c.what);
        Rig rig;
        fgfx.*(c.field) = c.rc;
        Hook h;
        h.device_created();
        CHECK_FALSE(h.make_swapchain());
        CHECK(contains(h.create.error, c.call));
        CHECK(h.create.swapchain == nullptr);
        CHECK(fgfx.contexts == 0);
        CHECK(xlfx.contexts == 0);
        if (std::string(c.what) != "create") CHECK(index_of("fg.destroy") < index_of("xell.destroy"));
        if (std::string(c.what) == "create") CHECK(contains(h.create.error, "Intel Arc"));
        if (std::string(c.what) == "init") CHECK(contains(h.create.error, "driver is too old"));
        // Nothing was made: the controller's start says so.
        XDevice dev(gpu::Backend::D3d12, 0x8086);
        CHECK(contains(h.p->start(dev, swapchain_of(dev)), "did not make the window's swapchain"));
    }
}

TEST_CASE("xess frame generation: a swapchain made again destroys the context before, and keeps XeLL's") {
    if (sizeof(void*) != 8) return;
    Rig rig;
    Hook h;
    h.device_created();
    REQUIRE(h.make_swapchain());
    h.hook->swapchain_destroying(gpu::SwapchainEvent{});
    // The engine releases the proxy swapchain after that call: nothing is destroyed yet.
    CHECK(count_of("fg.destroy") == 0);
    XDevice dev(gpu::Backend::D3d12, 0x8086);
    CHECK(contains(h.p->start(dev, swapchain_of(dev)), "did not make"));  // no live swapchain now
    g_events.clear();
    REQUIRE(h.make_swapchain());
    const std::vector<std::string> expected = {"fg.destroy", "fg.create", "fg.setLatencyReduction", "fg.init",
                                               "fg.getSwapChain"};
    CHECK(g_events == expected);  // XeLL's context stayed: no xell.create, no xell.destroy
    CHECK(xlfx.contexts == 1);
    CHECK(h.p->start(dev, swapchain_of(dev)).empty());
    h.hook->swapchain_destroying(gpu::SwapchainEvent{});
    g_events.clear();
    h.hook->device_destroying();
    const std::vector<std::string> gone = {"fg.destroy", "xell.destroy"};  // XeSS-FG first: it uses XeLL's context
    CHECK(g_events == gone);
    CHECK(fgfx.contexts == 0);
    CHECK(xlfx.contexts == 0);
}

// ---- start, configure, stop -----------------------------------------------------------------------------------------------------------

TEST_CASE("xess frame generation: start needs the swapchain of this device; configure sets XeLL's sleep mode before it "
          "enables") {
    if (sizeof(void*) != 8) return;
    Rig rig;
    Hook h;
    XDevice dev(gpu::Backend::D3d12, 0x8086);
    CHECK(contains(h.p->start(dev, swapchain_of(dev)), "did not make the window's swapchain"));  // no hook ran
    XDevice vk(gpu::Backend::Vulkan, 0x8086);
    CHECK(contains(h.p->start(vk, swapchain_of(vk)), "Direct3D 12 only"));
    h.device_created();
    REQUIRE(h.make_swapchain());
    CHECK(h.p->start(dev, swapchain_of(dev)).empty());
    g_events.clear();
    h.p->configure(true);
    // The sleep mode is on (low latency) before the generation is enabled.
    const std::vector<std::string> on = {"xell.setSleepMode", "fg.enable"};
    CHECK(g_events == on);
    REQUIRE(xlfx.modes.size() == 1);
    CHECK((xlfx.modes[0].flags & xl::kFlagLowLatency) != 0);
    g_events.clear();
    h.p->configure(true);  // already on: nothing is called
    CHECK(g_events.empty());
    h.p->configure(false);
    const std::vector<std::string> off = {"fg.disable"};
    CHECK(g_events == off);
    CHECK(h.p->failure().empty());
    // stop: generation off and the hook passes the presents through (the swapchain stays: it is the window's).
    h.p->configure(true);
    g_events.clear();
    h.p->stop(dev);
    CHECK(g_events == off);
    g_events.clear();
    gpu::PresentEvent e;
    e.frame = 5;
    h.hook->present_begin(e);
    h.hook->present_end(e);
    CHECK(count_of("fg.setPresentId") == 1);  // present ids are still set (the swapchain is the proxy), nothing else
    CHECK(count_of("fg.tagConstants") == 0);
    CHECK(h.p->start(dev, swapchain_of(dev)).empty());  // and a start again works on the same swapchain
    h.hook->device_destroying();
}

TEST_CASE("xess frame generation: a sleep mode that cannot be set, or an enable that fails, keeps it off for the run") {
    if (sizeof(void*) != 8) return;
    {
        Rig rig;
        Hook h;
        XDevice dev(gpu::Backend::D3d12, 0x8086);
        h.device_created();
        REQUIRE(h.make_swapchain());
        REQUIRE(h.p->start(dev, swapchain_of(dev)).empty());
        xlfx.setModeRc = -3;
        h.p->configure(true);
        CHECK(contains(h.p->failure(), "XeLL"));
        CHECK(contains(h.p->failure(), "sleep mode"));
        CHECK(count_of("fg.enable") == 0);
        // Off for the run: the probe says it, a frame is refused, a start again says it.
        XDevice probeDev(gpu::Backend::D3d12, 0x8086);
        CHECK(contains(h.p->probe(env_of(probeDev, GpuVendor::Intel)).reason, "sleep mode"));
        CHECK(contains(h.p->start(dev, swapchain_of(dev)), "sleep mode"));
        h.hook->device_destroying();
    }
    {
        Rig rig;
        Hook h;
        XDevice dev(gpu::Backend::D3d12, 0x8086);
        h.device_created();
        REQUIRE(h.make_swapchain());
        REQUIRE(h.p->start(dev, swapchain_of(dev)).empty());
        fgfx.enableRc = -7;
        h.p->configure(true);
        CHECK(contains(h.p->failure(), "xefgSwapChainSetEnabled"));
        // A new device is a new run.
        h.hook->device_destroying();
        h.device_created();
        CHECK(h.p->failure().empty());
        h.hook->device_destroying();
    }
}

// ---- the frame ------------------------------------------------------------------------------------------------------------------------

namespace {

struct FrameRig {
    Rig rig;
    Hook h;
    XDevice dev{gpu::Backend::D3d12, 0x8086};
    NList list{dev};
    render::FrameGenFrame f;
    FrameRig() {
        h.device_created();
        REQUIRE(h.make_swapchain());
        REQUIRE(h.p->start(dev, swapchain_of(dev)).empty());
        h.p->configure(true);
        g_events.clear();
        f.device = &dev;
        f.list = &list;
        f.depth = gpu::Image{3};
        f.motion = gpu::Image{4};
        f.renderW = 960;
        f.renderH = 540;
        f.outW = 1920;
        f.outH = 1080;
        const float proj[8] = {1.5f, 2.0f, 0.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f};
        for (int i = 0; i < 8; ++i) f.proj[i] = proj[i];
        f.cameraNear = 0.1f;
        f.cameraFar = 100.0f;
        f.viewFromWorld.at(3, 0) = 7.0f;  // a translation: the memory is copied as it is
        f.jitterX = 0.25f;
        f.jitterY = -0.75f;  // beyond the SDK's range: clamped
        f.frameTimeMs = 16.5f;
        f.reset = true;
    }
    ~FrameRig() { h.hook->device_destroying(); }
};

}  // namespace

TEST_CASE("xess frame generation: a frame tags depth and motion (copy source, only now), the constants and the XeLL "
          "frame id") {
    if (sizeof(void*) != 8) return;
    FrameRig r;
    // The XeLL controller's last sleep names the present that will show the frame.
    r.rig.xell->sleep(41);  // (a no-op without a context of its own: the sleep mode was set by XeSS frame generation)
    CHECK(r.h.p->dispatch(r.f));
    CHECK(r.f.error.empty());
    REQUIRE(fgfx.constants.size() == 1);
    REQUIRE(fgfx.tags.size() == 2);
    const std::vector<std::string> order = {"fg.tagConstants", "list.begin", "fg.tagResource", "fg.tagResource",
                                            "list.end"};
    CHECK(g_events == order);
    // The native section declared both images in the copy-source state.
    REQUIRE(r.list.uses.size() == 2);
    CHECK(r.list.uses[0].image == gpu::Image{3});
    CHECK(r.list.uses[1].image == gpu::Image{4});
    for (const gpu::NativeUse& u : r.list.uses) CHECK(u.state == gpu::NativeState::CopySource);
    const auto& depth = fgfx.tags[0];
    const auto& motion = fgfx.tags[1];
    CHECK(depth.data.type == fg::kResourceDepth);
    CHECK(motion.data.type == fg::kResourceMotionVector);
    for (const auto* t : {&depth, &motion}) {
        CHECK(t->data.validity == fg::kValidityOnlyNow);
        CHECK(t->data.incomingState == 0x800);  // D3D12_RESOURCE_STATE_COPY_SOURCE
        CHECK(t->data.resourceBase.x == 0);
        CHECK(t->data.resourceBase.y == 0);
        CHECK(t->data.resourceSize.x == 960);  // the render size, both alike
        CHECK(t->data.resourceSize.y == 540);
        CHECK(t->list == &g_listToken);  // XeSS-FG records its copy into the section's list
        CHECK(t->id == fgfx.constants[0].first);
    }
    CHECK(depth.data.resource == reinterpret_cast<void*>(std::uintptr_t(0x5003)));
    CHECK(motion.data.resource == reinterpret_cast<void*>(std::uintptr_t(0x5004)));
    const fg::FrameConstants& c = fgfx.constants[0].second;
    CHECK(c.motionVectorScaleX == 960.0f);  // the motion image is in fractions of the picture
    CHECK(c.motionVectorScaleY == 540.0f);
    CHECK(c.resetHistory == 1);
    CHECK(c.jitterOffsetX == doctest::Approx(0.25f));
    CHECK(c.jitterOffsetY == doctest::Approx(-0.5f));
    CHECK(c.frameRenderTime == doctest::Approx(16.5f));
    CHECK(c.viewMatrix[12] == doctest::Approx(7.0f));  // the translation of the column-major view, as it is in memory
    CHECK(c.projectionMatrix[0] == doctest::Approx(1.5f));
    CHECK(c.projectionMatrix[5] == doctest::Approx(2.0f));
    CHECK(c.projectionMatrix[11] == doctest::Approx(-1.0f));  // row 3, column 2 of the row-vector projection
    // A frame that is not a reset says so.
    r.f.reset = false;
    CHECK(r.h.p->dispatch(r.f));
    REQUIRE(fgfx.constants.size() == 2);
    CHECK(fgfx.constants[1].second.resetHistory == 0);
}

TEST_CASE(
    "xess frame generation: the present id of the tag is the one the present sets, XeLL's frame id when it has one") {
    if (sizeof(void*) != 8) return;
    FrameRig r;
    // Without a XeLL frame id (no controller gave one yet) the id is the count of presents plus one.
    gpu::PresentEvent e;
    e.frame = 9;
    r.h.hook->present_begin(e);  // a present with nothing tagged: named all the same
    REQUIRE(fgfx.presentIds.size() == 1);
    CHECK(fgfx.presentIds[0] == 10);
    CHECK(r.h.p->dispatch(r.f));
    REQUIRE(fgfx.constants.size() == 1);
    const std::uint32_t tagged = fgfx.constants[0].first;
    CHECK(tagged == 10);
    e.frame = 10;
    r.h.hook->present_begin(e);
    REQUIRE(fgfx.presentIds.size() == 2);
    CHECK(fgfx.presentIds[1] == tagged);  // the same id the frame's resources and constants carry
    r.h.hook->present_end(e);
}

TEST_CASE("xess frame generation: the generated frames are what the swapchain says it presented") {
    if (sizeof(void*) != 8) return;
    FrameRig r;
    CHECK(r.h.p->generated_frames() == 0);
    gpu::PresentEvent e;
    e.frame = 1;
    fgfx.status.isFrameGenEnabled = 1;
    fgfx.status.framesPresented = 2;  // the rendered frame and one generated
    r.h.hook->present_begin(e);
    r.h.hook->present_end(e);
    CHECK(r.h.p->generated_frames() == 1);
    fgfx.status.framesPresented = 1;  // nothing generated this time
    r.h.hook->present_end(e);
    CHECK(r.h.p->generated_frames() == 1);
    fgfx.status.isFrameGenEnabled = 0;
    fgfx.status.framesPresented = 2;
    r.h.hook->present_end(e);
    CHECK(r.h.p->generated_frames() == 1);  // generation is off: whatever the status says is not counted
    // A present the SDK could not generate is a failure of the run.
    fgfx.status.isFrameGenEnabled = 1;
    fgfx.status.frameGenResult = -12;
    r.h.hook->present_end(e);
    CHECK(contains(r.h.p->failure(), "mismatched input resources"));
}

TEST_CASE(
    "xess frame generation: a frame the SDK refuses is a failure for the run; one the engine cannot give is not") {
    if (sizeof(void*) != 8) return;
    {  // no native resource for an image: this frame only
        FrameRig r;
        r.dev.noResources = true;
        CHECK_FALSE(r.h.p->dispatch(r.f));
        CHECK(contains(r.f.error, "native resource"));
        CHECK(r.h.p->failure().empty());
        r.dev.noResources = false;
        r.f.error.clear();
        CHECK(r.h.p->dispatch(r.f));
    }
    {  // no native section
        FrameRig r;
        r.list.failBegin = true;
        CHECK_FALSE(r.h.p->dispatch(r.f));
        CHECK(contains(r.f.error, "native command section"));
        CHECK(r.h.p->failure().empty());
    }
    {  // the SDK refuses the constants
        FrameRig r;
        fgfx.constantsRc = -4;
        CHECK_FALSE(r.h.p->dispatch(r.f));
        CHECK(contains(r.f.error, "xefgSwapChainTagFrameConstants"));
        CHECK(contains(r.h.p->failure(), "xefgSwapChainTagFrameConstants"));
        CHECK(contains(r.h.p->failure(), "invalid argument"));
    }
    {  // the SDK refuses a resource: the native section is closed all the same
        FrameRig r;
        fgfx.resourceRc = -12;
        CHECK_FALSE(r.h.p->dispatch(r.f));
        CHECK(count_of("list.end") == 1);
        CHECK(contains(r.f.error, "depth"));
        CHECK(contains(r.f.error, "xefgSwapChainD3D12TagFrameResource"));
        CHECK(contains(r.h.p->failure(), "mismatched input resources"));
        // From then on every frame is refused with the same reason, and nothing more is tagged.
        const std::size_t tags = fgfx.tags.size();
        r.f.error.clear();
        CHECK_FALSE(r.h.p->dispatch(r.f));
        CHECK(fgfx.tags.size() == tags);
        CHECK(r.f.error == r.h.p->failure());
    }
}

// ---- the controller -------------------------------------------------------------------------------------------------------------------

TEST_CASE("xess frame generation: the controller starts it, and a failure while it runs turns it off for the run") {
    if (sizeof(void*) != 8) return;
    Rig rig;
    // The provider the table holds: the one a renderer gets.
    render::FrameGenProvider* p = render::framegen_provider(FrameGenSlot::Xess);
    REQUIRE(p != nullptr);
    CHECK(p->name() == "XeSS frame generation");
    std::shared_ptr<gpu::DeviceHook> hook = p->device_hook();
    REQUIRE(hook != nullptr);
    CHECK(render::framegen_device_hooks().size() >= 1);
    FakeAdapter adapter{adapter_vtable()};
    g_adapterVendor = 0x8086;
    gpu::D3d12DeviceCreated dc;
    dc.device = &g_deviceToken;
    dc.adapter = &adapter;
    hook->d3d12_device_created(dc);
    gpu::D3d12SwapchainCreate sc;
    sc.factory = &g_factoryToken;
    sc.queue = &g_queueToken;
    sc.hwnd = &g_hwndToken;
    sc.desc = &g_descToken;
    REQUIRE(hook->d3d12_create_swapchain(sc));

    XDevice dev(gpu::Backend::D3d12, 0x8086);
    NList list(dev);
    render::FrameGenController fc;
    fc.attach(&dev, env_of(dev, GpuVendor::Intel), swapchain_of(dev), /*hooked=*/true);
    render::FrameGenSettings s;
    s.mode = render::FrameGenMode::Xess;
    s.minBaseFps = 0;  // no rate rule: generation runs as soon as a frame is begun
    fc.set_settings(s);
    CHECK(fc.provider() == FrameGenSlot::Xess);
    CHECK(fc.provider_reason(FrameGenSlot::Xess).empty());
    fc.begin_frame(1000.0);
    REQUIRE(fc.wants_dispatch());
    CHECK(count_of("fg.enable") == 1);

    render::FrameGenFrame f;
    f.device = &dev;
    f.list = &list;
    f.depth = gpu::Image{3};
    f.motion = gpu::Image{4};
    f.renderW = 640;
    f.renderH = 360;
    f.outW = 1280;
    f.outH = 720;
    f.cameraFar = 100.0f;
    CHECK(fc.dispatch(f));
    CHECK(fgfx.constants.back().second.resetHistory == 1);  // the controller's first frame is a reset
    fgfx.resourceRc = -6;
    CHECK_FALSE(fc.dispatch(f));
    // The provider failed for good: the controller stopped it and says why, and the slot is not usable again this run.
    CHECK(fc.provider() == FrameGenSlot::None);
    CHECK(fc.state() == render::FrameGenState::Refused);
    CHECK(contains(fc.reason(), "xefgSwapChainD3D12TagFrameResource"));
    CHECK(contains(fc.provider_reason(FrameGenSlot::Xess), "device error"));
    CHECK(fgfx.enables.back() == 0);  // generation off: the swapchain presents the rendered frames only
    CHECK_FALSE(fc.caps().xess);
    fc.detach();
    hook->device_destroying();
    CHECK(fgfx.contexts == 0);
    CHECK(xlfx.contexts == 0);
}

// ---- XeLL -----------------------------------------------------------------------------------------------------------------------------

TEST_CASE("xess frame generation: XeLL runs with it whatever render.latency says, and one context serves both") {
    if (sizeof(void*) != 8) return;
    Rig rig;
    Hook h;
    h.device_created();
    REQUIRE(h.make_swapchain());  // takes XeLL's context before the latency controller exists
    CHECK(count_of("xell.create") == 1);

    XDevice dev(gpu::Backend::D3d12, 0x8086);
    render::LatencyController lc;
    lc.attach(&dev, env_of(dev, GpuVendor::Intel), /*pacing=*/true);
    render::LatencySettings off;  // render.latency "off"
    lc.set_settings(off);
    CHECK(lc.driver() == LatencyDriver::None);
    CHECK(lc.required_driver() == LatencyDriver::None);
    lc.require_driver(LatencyDriver::Xell);  // XeSS frame generation is the provider that runs
    CHECK(lc.required_driver() == LatencyDriver::Xell);
    CHECK(lc.driver() == LatencyDriver::Xell);
    CHECK(lc.settings().mode == render::LatencyMode::Off);  // the setting itself is untouched
    CHECK(count_of("xell.create") == 1);  // the context the swapchain took is the one the controller uses
    REQUIRE_FALSE(xlfx.modes.empty());
    CHECK((xlfx.modes.back().flags & xl::kFlagLowLatency) != 0);
    // The frame ids the controller gives XeLL are the present ids of the tags.
    XDevice fdev(gpu::Backend::D3d12, 0x8086);
    REQUIRE(h.p->start(fdev, swapchain_of(fdev)).empty());
    lc.frame_begin(0.0);
    REQUIRE_FALSE(xlfx.sleeps.empty());
    NList list(fdev);
    render::FrameGenFrame f;
    f.device = &fdev;
    f.list = &list;
    f.depth = gpu::Image{3};
    f.motion = gpu::Image{4};
    f.renderW = f.outW = 640;
    f.renderH = f.outH = 360;
    f.cameraFar = 100.0f;
    h.p->configure(true);
    REQUIRE(h.p->dispatch(f));
    CHECK(fgfx.constants.back().first == xlfx.sleeps.back());

    // The requirement ends with the provider: the latency controller stops XeLL (its own reference), the swapchain's stays.
    lc.require_driver(LatencyDriver::None);
    CHECK(lc.driver() == LatencyDriver::None);
    CHECK(xlfx.contexts == 1);
    lc.detach();
    h.hook->device_destroying();
    CHECK(xlfx.contexts == 0);
    CHECK(fgfx.contexts == 0);
}
