// M78-P1: the vendor upscaler seam (src/render_upscale_vendor.h, src/renderer_upscale.cpp). No SDK is involved: the library search runs on
// temporary folders, the providers run against a fake loader, and the renderer is given fake providers, so what is tested is the seam
// itself: where a library is found, what each provider reports, that run_upscale hands the frame to a provider, and that a provider that
// refuses a frame is off for the rest of the run with the temporal upscaler drawing instead.
#include "test_util.h"

#include <algorithm>
#include <filesystem>
#include <memory>
#include <string>
#include <system_error>
#include <vector>

#include "fa/core/fs.h"
#include "gpu/recording_device.h"
#include "render_features.h"
#include "render_upscale.h"
#include "render_upscale_vendor.h"
#include "renderer_test_access.h"
#include "fa/render/upscaler.h"

using namespace fa;
using namespace fa::test;
using render::GpuVendor;
using render::UpscaleImpl;
using render::UpscalerMode;
using render::UpscalerQuality;
using render::UpscalerSettings;
using render::VendorEnv;
using render::VendorFrame;
using render::VendorLibrarySpec;
using render::VendorProbe;
using render::VendorSearchRoots;

namespace {

namespace stdfs = std::filesystem;

struct Scratch {
    stdfs::path dir = fa::fs::make_temp_dir("fa_test_vendor").value();
    ~Scratch() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    // An empty file at dir/rel (the library search only looks at whether it is a file).
    stdfs::path touch(const char* rel) const {
        const stdfs::path p = dir / stdfs::path(std::string(rel));
        std::error_code ec;
        stdfs::create_directories(p.parent_path(), ec);
        const auto written = fa::fs::write_text(fa::fs::path_to_utf8(p), "x");
        REQUIRE(written.ok());
        return p;
    }
};

const VendorLibrarySpec kSpec{"xess", "FA_XESS_DIR", "libxess.dll"};

// A loader that finds nothing, or the one path it was given, and loads nothing.
class FakeLoader final : public render::VendorLoader {
public:
    stdfs::path found;
    int finds = 0;
    stdfs::path find(const VendorLibrarySpec&, std::string* why) override {
        ++finds;
        if (found.empty() && why) *why = "the fake loader has no library";
        return found;
    }
    std::unique_ptr<render::VendorLibrary> load(const stdfs::path&, std::string* why) override {
        if (why) *why = "the fake loader loads nothing";
        return nullptr;
    }
};

struct LoaderGuard {
    explicit LoaderGuard(render::VendorLoader* l) { render::set_vendor_loader_for_test(l); }
    ~LoaderGuard() { render::set_vendor_loader_for_test(nullptr); }
    LoaderGuard(const LoaderGuard&) = delete;
    LoaderGuard& operator=(const LoaderGuard&) = delete;
};

VendorEnv windows_env(gpu::Backend backend, GpuVendor vendor) {
    VendorEnv e;
    e.backend = backend;
    e.vendor = vendor;
    e.windows = true;
    return e;
}

}  // namespace

TEST_CASE(
    "vendor loader: the folder of the environment wins, and when it lacks the library the other places are not tried") {
    Scratch s;
    const stdfs::path env = s.dir / "env", exe = s.dir / "exe", home = s.dir / "home";
    s.touch("exe/libxess.dll");
    s.touch("home/tools/xess/1.0.0/libxess.dll");
    VendorSearchRoots roots;
    roots.envDir = env;
    roots.exeDir = exe;
    roots.home = home;
    std::string why;
    CHECK(render::find_vendor_library(kSpec, roots, &why).empty());  // $FA_XESS_DIR names a folder without it
    CHECK(why.find("FA_XESS_DIR") != std::string::npos);
    CHECK(why.find("libxess.dll") != std::string::npos);
    const stdfs::path inEnv = s.touch("env/libxess.dll");
    CHECK(render::find_vendor_library(kSpec, roots) == inEnv);
}

TEST_CASE("vendor loader: next to the executable beats the setup folder, and the newest version folder wins") {
    Scratch s;
    VendorSearchRoots roots;
    roots.exeDir = s.dir / "exe";
    roots.home = s.dir / "home";
    std::string why;
    CHECK(render::find_vendor_library(kSpec, roots, &why).empty());
    CHECK(why.find("factoria setup") ==
          std::string::npos);  // the search reports where it looked; the provider adds the setup hint
    CHECK(why.find("not next to the game") != std::string::npos);
    CHECK(why.find("no version of it") != std::string::npos);
    s.touch("home/tools/xess/2.9.1/libxess.dll");
    s.touch("home/tools/xess/2.10.0/libxess.dll");
    s.touch("home/tools/xess/2.11.0/readme.txt");        // a version folder without the library does not count
    s.touch("home/tools/streamline/9.0.0/libxess.dll");  // another setup id is another folder
    CHECK(render::find_vendor_library(kSpec, roots) == s.dir / "home" / "tools" / "xess" / "2.10.0" / "libxess.dll");
    const stdfs::path beside = s.touch("exe/libxess.dll");
    CHECK(render::find_vendor_library(kSpec, roots) == beside);
}

TEST_CASE("vendor providers: a probe says what is wrong in the order GPU maker, backend, system, library") {
    FakeLoader loader;
    LoaderGuard guard(&loader);
    render::VendorUpscaler& dlss = render::vendor_provider(0);
    render::VendorUpscaler& xess = render::vendor_provider(1);
    render::VendorUpscaler& fsr = render::vendor_provider(2);
    CHECK(dlss.mode() == "dlss");
    CHECK(xess.mode() == "xess");
    CHECK(fsr.mode() == "fsr");
    CHECK(dlss.setup_id() == "streamline");
    CHECK(xess.setup_id() == "xess");
    CHECK(fsr.setup_id() == "fidelityfx");

    // DLSS: an NVIDIA RTX GPU first, whatever the library.
    VendorProbe p = dlss.probe(windows_env(gpu::Backend::D3d12, GpuVendor::Amd));
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("NVIDIA") != std::string::npos);
    CHECK(p.reason.find("AMD") != std::string::npos);
    // The backend: FSR does not draw on D3D11, nothing draws on OpenGL.
    p = fsr.probe(windows_env(gpu::Backend::D3d11, GpuVendor::Amd));
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("D3D12") != std::string::npos);
    CHECK(p.reason.find("D3D11") != std::string::npos);
    p = xess.probe(windows_env(gpu::Backend::Gl, GpuVendor::Intel));
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("OpenGL") != std::string::npos);
    // Not Windows.
    VendorEnv mac = windows_env(gpu::Backend::D3d12, GpuVendor::Intel);
    mac.windows = false;
    p = xess.probe(mac);
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("Windows") != std::string::npos);
    // Everything suits but the library is not installed: the setup command is named, and so is where it looked.
    p = xess.probe(windows_env(gpu::Backend::D3d12, GpuVendor::Other));  // xess runs on any GPU
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("factoria setup xess") != std::string::npos);
    CHECK(p.reason.find("the fake loader has no library") != std::string::npos);
    p = dlss.probe(windows_env(gpu::Backend::Vulkan, GpuVendor::Nvidia));
    CHECK(p.reason.find("factoria setup streamline") != std::string::npos);
    p = fsr.probe(windows_env(gpu::Backend::Vulkan, GpuVendor::Other));
    CHECK(p.reason.find("factoria setup fidelityfx") != std::string::npos);
    // The library is there but is not XeSS (the fake loader loads nothing): the file is named, and so is the way to fix it. The SDK's own
    // calls are tested against a fake library in xess_upscale_tests.cpp.
    Scratch s;
    loader.found = s.touch("libxess.dll");
    p = xess.probe(windows_env(gpu::Backend::D3d12, GpuVendor::Intel));
    CHECK_FALSE(p.available);
    CHECK(p.reason.find("could not be loaded") != std::string::npos);
    CHECK(p.reason.find("factoria setup xess") != std::string::npos);
    CHECK(p.reason.find("not installed") == std::string::npos);
    // The library does not rescue an environment that cannot run the SDK.
    p = xess.probe(windows_env(gpu::Backend::Gl, GpuVendor::Intel));
    CHECK(p.reason.find("OpenGL") != std::string::npos);
    // upscale() of a provider the probe did not accept draws nothing and says why (the renderer then draws the temporal upscaler).
    VendorFrame frame;
    render::UpscaleInput in;
    CHECK_FALSE(xess.upscale(in, frame));
    CHECK_FALSE(frame.error.empty());
}

TEST_CASE("vendor providers: without a device the GPU maker is none, with the Recording device too") {
    CHECK(render::gpu_vendor_name(GpuVendor::None) == "none");
    CHECK(render::gpu_vendor_name(GpuVendor::Nvidia) == "NVIDIA");
    gpu::RecordingDevice recording;
    CHECK(render::gpu_vendor_of(recording) == GpuVendor::None);
    const VendorEnv env = render::vendor_env_of(recording);
    CHECK(env.backend == gpu::Backend::Recording);
    CHECK(env.vendor == GpuVendor::None);
    CHECK(env.device == &recording);
    // No device at all: the environment a probe is given before a renderer has opened one knows no maker, and no backend it runs on.
    const VendorEnv none{};
    CHECK(none.vendor == GpuVendor::None);
    CHECK(none.device == nullptr);
    CHECK(none.vulkanInstanceExtensions.empty());
    CHECK(none.vulkanDeviceExtensions.empty());
    // A GPU that gave no name and no PCI id is "some other maker" (the NVIDIA and Intel SDKs are not for it), never none or NVIDIA.
    CHECK(render::gpu_vendor_from_identity(gpu::GpuIdentity{}) == GpuVendor::None);
    gpu::GpuIdentity unknownPci;
    unknownPci.vendorId = 0xFFFF;
    CHECK(render::gpu_vendor_from_identity(unknownPci) == GpuVendor::Other);
    gpu::GpuIdentity nvidia;
    nvidia.vendorId = 0x10DE;
    CHECK(render::gpu_vendor_from_identity(nvidia) == GpuVendor::Nvidia);
    // The PCI vendor id to maker mapping is tested with a device that has one (xess_upscale_tests.cpp).
}

namespace {

// A provider the test controls: available or not, draws (returns true) or refuses (false), and counts its calls.
class FakeProvider final : public render::VendorUpscaler {
public:
    FakeProvider(const char* mode, bool available, bool draws) : mode_(mode), available_(available), draws_(draws) {}
    std::string_view name() const override { return "Fake"; }
    std::string_view mode() const override { return mode_; }
    std::string_view setup_id() const override { return "fake"; }
    unsigned backends() const override { return ~0u; }
    VendorProbe probe(const VendorEnv&) override {
        ++probes;
        VendorProbe p;
        p.available = available_;
        if (!available_) p.reason = "the fake SDK is not installed.";
        return p;
    }
    bool upscale(const render::UpscaleInput& in, VendorFrame& frame) override {
        ++frames;
        lastRenderW = in.renderW;
        lastOutW = in.outW;
        lastHadDevice = frame.device != nullptr && frame.list != nullptr;
        if (!draws_) frame.error = "the fake SDK refused this frame.";
        return draws_;
    }
    int probes = 0, frames = 0, lastRenderW = 0, lastOutW = 0;
    bool lastHadDevice = false;

private:
    const char* mode_;
    bool available_, draws_;
};

struct ProviderGuard {
    int index;
    ProviderGuard(int i, render::VendorUpscaler* p) : index(i) { render::set_vendor_provider_for_test(i, p); }
    ~ProviderGuard() { render::set_vendor_provider_for_test(index, nullptr); }
    ProviderGuard(const ProviderGuard&) = delete;
    ProviderGuard& operator=(const ProviderGuard&) = delete;
};

constexpr int kOutW = 320, kOutH = 180;

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx) : g(gx) {
        RendererDesc d;
        d.designWidth = kOutW;
        d.designHeight = kOutH;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    void frame(World& w, int n = 1) {
        for (int i = 0; i < n; ++i) {
            w.advance_clock(1.0 / 60.0);
            r.begin_frame();
            r.render_world(w, 1.0f / 60.0f);
            r.end_frame();
            g.gpu.end_frame();
        }
    }
    void upscale(UpscalerMode mode, float scale = 0.5f) {
        r.set_render_scale(scale);
        r.set_upscale_stage(true);
        UpscalerSettings u;
        u.mode = mode;
        u.quality = UpscalerQuality::Performance;
        r.set_upscaler(u);
    }
};

struct Scene {
    World w;
    Scene() {
        const Entity cam = make(w, "cam", {0, 0, 10});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60.0f;
        c.clearColor = Color{0, 0, 0, 1};
        w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
        const Entity box = make(w, "box", {0, 0, 0});
        w.get<Transform>(box)->scale = {3.0f, 3.0f, 3.0f};
        auto& m = w.add<MeshRenderer>(box);
        m.mesh = "cube";
        m.color = Color::white();
        m.unlit = true;
    }
};

}  // namespace

TEST_CASE("vendor renderer: a usable provider is handed the jittered frame and its mode is the effective one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FakeProvider fake("xess", true, true);
    ProviderGuard guard(1, &fake);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    own.upscale(UpscalerMode::Xess);
    own.frame(s.w, 3);
    CHECK(fake.probes == 1);  // asked once, never per frame
    CHECK(fake.frames >= 2);
    CHECK(fake.lastHadDevice);
    CHECK(fake.lastOutW == kOutW);
    CHECK(fake.lastRenderW == kOutW / 2);
    CHECK(RendererTestAccess::mfx_images(own.r) == 2);  // depth and motion are kept while the provider draws
    CHECK(own.r.effective_upscaler_mode() == UpscalerMode::Xess);
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Xess));
    CHECK_FALSE(RendererTestAccess::vendor_failed(own.r, 1));
    const render::UpscalerCaps caps = own.r.upscaler_caps();
    CHECK(caps.xess);
    CHECK_FALSE(caps.dlss);
    CHECK_FALSE(caps.fsr);
    // Another mode: the provider is not asked for frames any more.
    const int before = fake.frames;
    own.upscale(UpscalerMode::Spatial);
    own.frame(s.w, 2);
    CHECK(fake.frames == before);
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Spatial));
}

TEST_CASE(
    "vendor renderer: a provider that refuses a frame is off for the run and the temporal upscaler draws instead") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FakeProvider fake("fsr", true, false);
    ProviderGuard guard(2, &fake);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    own.upscale(UpscalerMode::Fsr);
    own.frame(s.w, 1);
    CHECK(fake.frames == 1);
    CHECK(RendererTestAccess::vendor_failed(own.r, 2));
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Temporal));  // the frame was still drawn
    own.frame(s.w, 3);
    CHECK(fake.frames == 1);  // fail once, stay off
    // The next best of the chain: the temporal upscaler, or MetalFX on a Mac that has it (it is first in the chain).
    const UpscalerMode next = own.r.effective_upscaler_mode();
    CHECK((next == UpscalerMode::Temporal || next == UpscalerMode::MetalFx));
    // Its preparation images are given back after the failure (MetalFX, where the Mac has it, keeps them for its own use).
    if (next != UpscalerMode::MetalFx) CHECK(RendererTestAccess::mfx_images(own.r) == 0);
    CHECK(RendererTestAccess::upscale_impl(own.r) ==
          int(next == UpscalerMode::MetalFx ? UpscaleImpl::MetalFx : UpscaleImpl::Temporal));
    CHECK_FALSE(own.r.upscaler_caps().fsr);
    Image img;
    std::string err;
    REQUIRE_MESSAGE(own.r.capture(img, &err), err);
    CHECK(img.width == kOutW);
    CHECK(img.height == kOutH);
}

TEST_CASE("vendor renderer: a provider that is not available is never given a frame, and the mode falls to the "
          "temporal one with the reason "
          "in render.supports") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FakeProvider fake("dlss", false, true);
    ProviderGuard guard(0, &fake);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    own.upscale(UpscalerMode::Dlss);
    own.frame(s.w, 2);
    CHECK(fake.frames == 0);
    CHECK(own.r.effective_upscaler_mode() != UpscalerMode::Dlss);
    CHECK_FALSE(own.r.upscaler_caps().dlss);
    CHECK_FALSE(RendererTestAccess::vendor_failed(own.r, 0));  // never failed: it was never usable
    CHECK_FALSE(own.r.supports("dlss"));
    const Json report = own.r.supports_report();
    bool found = false;
    for (const Json& f : report["features"]) {
        if (f["name"] != "dlss") continue;
        found = true;
        CHECK(f["supported"] == false);
        CHECK(f["status"].get<std::string>().find("the fake SDK is not installed.") != std::string::npos);
    }
    CHECK(found);
}

TEST_CASE("vendor renderer: render.supports lists the three rows and answers yes for an available provider") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FakeProvider fake("xess", true, true);
    ProviderGuard guard(1, &fake);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    const std::vector<std::string> names = Renderer::feature_names();
    for (const char* n : {"dlss", "xess", "fsr"}) CHECK(std::find(names.begin(), names.end(), n) != names.end());
    CHECK(own.r.supports("xess"));
    CHECK_FALSE(own.r.supports("fsr"));  // the registered provider: the library of this machine is not there
}

namespace {

// A DLSS stand-in that answers for Ray Reconstruction: what it is handed, and whether it says it drew with it.
class FakeRrProvider final : public render::VendorUpscaler {
public:
    std::string_view name() const override { return "Fake DLSS"; }
    std::string_view mode() const override { return "dlss"; }
    std::string_view setup_id() const override { return "streamline"; }
    unsigned backends() const override { return ~0u; }
    VendorProbe probe(const VendorEnv&) override { return {true, ""}; }
    VendorProbe probe_ray_reconstruction(const VendorEnv&) override {
        ++rrProbes;
        VendorProbe p;
        p.available = rrAvailable;
        if (!rrAvailable)
            p.reason = "DLSS Ray Reconstruction is not available on this machine: the fake plugin is missing.";
        return p;
    }
    bool upscale(const render::UpscaleInput& in, VendorFrame& frame) override {
        ++frames;
        asked = in.rayReconstruction;
        if (in.rayReconstruction) {
            ++rrFrames;
            guidesGiven = frame.normalRoughness.id != 0 && frame.diffuseAlbedo.id != 0 &&
                          frame.specularAlbedo.id != 0 && frame.rrDepth.id != 0 && in.rrDepth.id != 0 &&
                          in.camera.valid && in.camera.perspective;
            normalViewValid = in.normalRoughness.id != 0;
            if (rrRefuses)
                frame.rayReconstructionFallback =
                    "DLSS Ray Reconstruction could not draw a frame (the fake refused it).";
            else
                frame.usedRayReconstruction = true;
        }
        return true;
    }
    int rrProbes = 0, frames = 0, rrFrames = 0;
    bool rrAvailable = true, rrRefuses = false, asked = false, guidesGiven = false, normalViewValid = false;
};

}  // namespace

TEST_CASE(
    "vendor renderer: Ray Reconstruction is asked for, given its guides and the camera, and a refusal stays off") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FakeRrProvider fake;
    ProviderGuard guard(0, &fake);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.w.settings().colorSpace = ColorSpace::Linear;  // Ray Reconstruction reads linear light
    own.upscale(UpscalerMode::Dlss);
    // Not asked for: Super Resolution's frame, no probe, no guides.
    own.frame(s.w, 2);
    CHECK(fake.frames >= 1);
    CHECK_FALSE(fake.asked);
    CHECK(fake.rrFrames == 0);
    UpscalerSettings u;
    u.mode = UpscalerMode::Dlss;
    u.quality = UpscalerQuality::Performance;
    u.rayReconstruction = true;
    own.r.set_upscaler(u);
    own.frame(s.w, 2);
    CHECK(fake.rrProbes == 1);  // asked once, never per frame
    if (!own.r.supports("dlssRayReconstruction")) {
        // A device whose pipeline is not linear cannot give Ray Reconstruction its colour: the row says so, and there is nothing more to see.
        const Json report = own.r.supports_report();
        std::string why;
        for (const Json& f : report["features"])
            if (f["name"] == "dlssRayReconstruction") why = f["status"].dump();
        MESSAGE("Ray Reconstruction is not supported on this device, the frame draws Super Resolution: " << why);
        CHECK(why.find("linear") != std::string::npos);
        CHECK(fake.rrFrames == 0);
        return;
    }
    CHECK(fake.asked);
    CHECK(fake.rrFrames >= 1);
    CHECK(fake.guidesGiven);
    CHECK(fake.normalViewValid);
    CHECK(own.r.upscaler().rayReconstruction);
    // The guides are only made for the frames that use them, and kept while the setting is on and the render size stays: a frame that
    // draws as Super Resolution (the dynamic resolution) makes none. A new render size gives the old images back (the renderer's resize).
    CHECK(RendererTestAccess::rr_guide_images(own.r));
    int rrBefore = fake.rrFrames;
    own.r.set_render_scale(0.4f, 0.5f);
    own.frame(s.w, 2);
    CHECK(fake.rrFrames == rrBefore);
    CHECK_FALSE(fake.asked);
    own.r.set_render_scale(0.5f, 0.5f);
    own.frame(s.w, 1);
    CHECK(fake.rrFrames == rrBefore + 1);
    rrBefore = fake.rrFrames;
    u.rayReconstruction = false;
    own.r.set_upscaler(u);
    own.frame(s.w, 1);
    CHECK(fake.rrFrames == rrBefore);
    CHECK_FALSE(RendererTestAccess::rr_guide_images(own.r));  // the setting went false: the four images are given back
    // A frame DLSS drew with Super Resolution instead: Ray Reconstruction is off for the run and the row says why.
    fake.rrRefuses = true;
    u.rayReconstruction = true;
    own.r.set_upscaler(u);
    own.frame(s.w, 1);
    CHECK(fake.rrFrames == rrBefore + 1);
    CHECK_FALSE(own.r.supports("dlssRayReconstruction"));
    own.frame(s.w, 3);
    CHECK(fake.rrFrames == rrBefore + 1);  // fail once, stay off
    CHECK(fake.frames >= 1);
    CHECK_FALSE(RendererTestAccess::vendor_failed(own.r, 0));  // DLSS itself is not off: Super Resolution goes on
}

TEST_CASE("vendor renderer: a machine without Ray Reconstruction draws Super Resolution and the row says why") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FakeRrProvider fake;
    fake.rrAvailable = false;
    ProviderGuard guard(0, &fake);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.w.settings().colorSpace = ColorSpace::Linear;
    UpscalerSettings u;
    u.mode = UpscalerMode::Dlss;
    u.quality = UpscalerQuality::Performance;
    u.rayReconstruction = true;
    own.r.set_render_scale(0.5f);
    own.r.set_upscale_stage(true);
    own.r.set_upscaler(u);
    own.frame(s.w, 3);
    CHECK(fake.frames >= 1);
    CHECK(fake.rrFrames == 0);
    CHECK_FALSE(own.r.supports("dlssRayReconstruction"));
    CHECK(fake.rrProbes == 1);
}

TEST_CASE("vendor renderer: Ray Reconstruction on a picture of display values draws Super Resolution and says why") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FakeRrProvider fake;
    ProviderGuard guard(0, &fake);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;  // a gamma scene: the colour is display values
    UpscalerSettings u;
    u.mode = UpscalerMode::Dlss;
    u.quality = UpscalerQuality::Performance;
    u.rayReconstruction = true;
    own.r.set_render_scale(0.5f);
    own.r.set_upscale_stage(true);
    own.r.set_upscaler(u);
    own.frame(s.w, 3);
    CHECK(fake.frames >= 1);
    CHECK(fake.rrFrames == 0);
    CHECK_FALSE(own.r.supports("dlssRayReconstruction"));
}
