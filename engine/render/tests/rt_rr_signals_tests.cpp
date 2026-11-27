// M79-P4b-2: DLSS Ray Reconstruction takes the ray traced signals (docs/UPSCALING_VENDORS.md "DLSS Ray Reconstruction", docs/design/ARCHITECTURE_DENOISE.md "What a
// caller does"). The renderer's frame on the RecordingDevice with a fake DLSS provider (no NVIDIA GPU, no Streamline): with Ray Reconstruction drawing, the
// reflections' and the per-pixel GI's denoiser passes are not recorded and the hit distance guide is handed over; without it they are; a frame the provider
// then refuses shows the signals noisy once and the engine's denoiser starts again from a reset history; the AO's denoiser is never touched. The
// provider's own tagging of the hit distance is tested in dlss_upscale_tests.cpp.
#include "test_util.h"

#include <string>
#include <vector>

#include "fa/render/raytracing.h"
#include "fa/render/upscaler.h"
#include "fa/scene/terrain.h"
#include "gpu/recording_device.h"
#include "render_upscale.h"
#include "render_upscale_rr.h"
#include "render_upscale_vendor.h"
#include "renderer_test_access.h"
#include "rt_denoise.h"

using namespace fa;
using namespace fa::test;
using render::UpscalerMode;
using render::UpscalerQuality;
using render::UpscalerSettings;
using render::VendorFrame;
using render::VendorProbe;

namespace {

// A DLSS stand-in: available, with Ray Reconstruction, and what it is handed.
class FakeRr final : public render::VendorUpscaler {
public:
    std::string_view name() const override { return "Fake DLSS"; }
    std::string_view mode() const override { return "dlss"; }
    std::string_view setup_id() const override { return "streamline"; }
    unsigned backends() const override { return ~0u; }
    VendorProbe probe(const render::VendorEnv&) override { return {true, ""}; }
    VendorProbe probe_ray_reconstruction(const render::VendorEnv&) override { return {true, ""}; }
    bool upscale(const render::UpscaleInput& in, VendorFrame& frame) override {
        ++frames;
        if (failNext) {  // the provider fails the frame itself (Renderer::vendor_fail: the provider is off for the rest of the run)
            failNext = false;
            frame.error = "the fake provider failed a frame.";
            return false;
        }
        asked = in.rayReconstruction;
        hitGuide = false;
        if (in.rayReconstruction) {
            ++rrFrames;
            hitGuide = frame.hitDistance.id != 0 && in.hitDistance.id != 0;
            if (refuses)
                frame.rayReconstructionFallback =
                    "DLSS Ray Reconstruction could not draw a frame (the fake refused it).";
            else
                frame.usedRayReconstruction = true;
        }
        return true;
    }
    int frames = 0, rrFrames = 0;
    bool refuses = false, asked = false, hitGuide = false, failNext = false;
};

struct ProviderGuard {
    explicit ProviderGuard(render::VendorUpscaler* p) { render::set_vendor_provider_for_test(0, p); }
    ~ProviderGuard() { render::set_vendor_provider_for_test(0, nullptr); }
    ProviderGuard(const ProviderGuard&) = delete;
    ProviderGuard& operator=(const ProviderGuard&) = delete;
};

struct Rig {
    FakeRr fake;
    ProviderGuard guard{&fake};
    Renderer renderer;
    gpu::RecordingDevice* dev = nullptr;
    World w;
    Entity cam;
    explicit Rig(bool filterFloat32 = true) {
        gfx();  // the project root of the process
        gpu::DeviceInit init;
        init.recordingRayTracing = true;
        init.recordingFilterFloat32 = filterFloat32;  // a GPU that traces rays filters the kernel's RGBA32F image
        auto made = gpu::make_device(gpu::Backend::Recording, init);
        REQUIRE_MESSAGE(made.ok(), (made.ok() ? "" : made.error().message));
        dev = dynamic_cast<gpu::RecordingDevice*>(made.value().get());
        RendererDeviceAccess::set_next_device(std::move(made.value()));
        RendererDesc d;
        d.designWidth = 160;
        d.designHeight = 96;
        d.headless = true;
        d.backend = GpuBackend::Recording;
        std::string error;
        const bool ok = renderer.init(d, gfx().gpu.environment(), &error);
        RendererDeviceAccess::set_next_device(nullptr);
        REQUIRE_MESSAGE(ok, error);
        // A linear scene (Ray Reconstruction reads linear light): a camera, a mirror floor, a box and a sun.
        w.settings().colorSpace = ColorSpace::Linear;
        cam = make(w, "cam", {0, 3, 12});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60;
        Entity floor = make(w, "floor", {0, 0, 0});
        w.get<Transform>(floor)->scale = {16, 1, 16};
        auto& fm = w.add<MeshRenderer>(floor);
        fm.mesh = "plane";
        fm.roughness = 0.0f;
        Entity box = make(w, "box", {0, 1, 0});
        w.add<MeshRenderer>(box).mesh = "cube";
        Entity sun = make(w, "sun", {0, 5, 0});
        w.get<Transform>(sun)->rotation = {-50, 30, 0};
        w.add<Light>(sun).type = LightType::Directional;
    }
    ~Rig() { renderer.shutdown(); }
    Rig(const Rig&) = delete;
    Rig& operator=(const Rig&) = delete;

    void upscaler(bool rayReconstruction) {
        renderer.set_render_scale(0.5f);
        renderer.set_upscale_stage(true);
        UpscalerSettings u;
        u.mode = UpscalerMode::Dlss;
        u.quality = UpscalerQuality::Performance;
        u.rayReconstruction = rayReconstruction;
        renderer.set_upscaler(u);
    }
    void tracing(bool reflections, bool gi, bool ao = false) {
        render::RayTracingSettings s;
        s.enabled = true;
        s.shadows = render::RtShadows::Off;
        s.reflections = reflections;
        s.gi = gi ? render::RtGi::PerPixel : render::RtGi::Off;
        s.ao = ao;
        renderer.set_ray_tracing(s);
    }
    void frame() {
        renderer.update(w);
        renderer.begin_frame();
        renderer.render_world(w, 0.0f);
        renderer.end_frame();
    }
    std::vector<std::string> lines() const {
        std::vector<std::string> out;
        for (const gpu::RecordedCommand& c : dev->commands()) out.push_back(c.list + ": " + c.text);
        return out;
    }
    int count(const std::string& needle) const {
        int n = 0;
        for (const std::string& l : lines()) n += l.find(needle) != std::string::npos ? 1 : 0;
        return n;
    }
    // The denoiser's passes of the last whole frame.
    int temporal_passes() const { return count("begin_pass 'rtd-temporal'"); }
    std::string errors() const {
        std::string s;
        for (const std::string& e : dev->errors()) s += e + "\n";
        return s;
    }
    // Frames until the first one that records the frame the settings ask for, then one more recorded alone.
    void settle(int frames = 4) {
        for (int i = 0; i < frames; ++i) frame();
        dev->clear_commands();
        frame();
    }
    const render::RtDenoiser& denoiser() { return *RendererTestAccess::rt_denoiser(renderer); }
};

// The denoiser's temporal passes of one frame of a fresh rig.
int temporal_of(bool rr, bool reflections, bool gi, bool ao) {
    Rig r;
    r.upscaler(rr);
    r.tracing(reflections, gi, ao);
    r.settle();
    CHECK(r.errors().empty());
    return r.temporal_passes();
}

}  // namespace

TEST_CASE("rt rr signals: with Ray Reconstruction drawing, the reflections' and the GI's denoiser passes are not "
          "recorded and the hit distance is a guide") {
    Rig r;
    r.upscaler(true);
    r.tracing(true, true);
    r.settle();
    INFO(r.errors());
    CHECK(r.errors().empty());
    // The provider drew Ray Reconstruction (the fake says so) and was handed the guides, the hit distance among them.
    REQUIRE(r.fake.rrFrames >= 1);
    CHECK(r.fake.asked);
    CHECK(r.fake.hitGuide);
    CHECK(RendererTestAccess::rr_hit_image(r.renderer));
    CHECK(r.count("begin_pass 'upscale-rr-hit'") == 1);
    CHECK(r.count("begin_pass 'upscale-rr-guides'") == 1);
    // Both effects traced, and nothing of the engine's denoiser ran for them.
    CHECK(r.count("rt-reflections") >= 1);
    CHECK(r.count("rt-gipixel") >= 1);
    CHECK(r.temporal_passes() == 0);
    CHECK(r.count("begin_pass 'rtd-guide'") == 0);
    CHECK(r.denoiser().history_image_count() == 0);
    // The status says which signals Ray Reconstruction took.
    const render::RtDenoiserStatus st = r.renderer.ray_tracing_denoiser_status();
    CHECK(st.reflectionsRr);
    CHECK(st.giRr);
    CHECK(st.reason.empty());
    // The kernel's image is read by the hit pass after it ran, before the upscale pass.
    const std::vector<std::string> lines = r.lines();
    int kernel = -1, hit = -1, up = -1;
    for (std::size_t i = 0; i < lines.size(); ++i) {
        if (kernel < 0 && lines[i].find("rt-reflections") != std::string::npos) kernel = int(i);
        if (hit < 0 && lines[i].find("begin_pass 'upscale-rr-hit'") != std::string::npos) hit = int(i);
        if (up < 0 && lines[i].find("begin_pass 'upscale-rr-guides'") != std::string::npos) up = int(i);
    }
    REQUIRE(kernel >= 0);
    REQUIRE(hit >= 0);
    REQUIRE(up >= 0);
    CHECK(kernel < hit);
    CHECK(hit < up);
}

TEST_CASE("rt rr signals: without Ray Reconstruction the denoiser passes are there, and no hit distance is made") {
    const int reflectOnly = temporal_of(false, true, false, false);
    const int giOnly = temporal_of(false, false, true, false);
    CHECK(reflectOnly >= 1);
    CHECK(giOnly >= 1);
    // The same frame with Ray Reconstruction asked for but no effect that makes a signal: nothing of this package is in it.
    Rig r;
    r.upscaler(true);
    r.tracing(false, false, true);  // the AO only
    r.settle();
    CHECK(r.errors().empty());
    CHECK(r.count("upscale-rr-hit") == 0);
    CHECK_FALSE(RendererTestAccess::rr_hit_image(r.renderer));
    CHECK_FALSE(r.fake.hitGuide);
    const render::RtDenoiserStatus st = r.renderer.ray_tracing_denoiser_status();
    CHECK_FALSE(st.reflectionsRr);
    CHECK_FALSE(st.giRr);
    CHECK(st.reason.empty());
    // Ray Reconstruction off: the same, with every denoiser pass.
    Rig off;
    off.upscaler(false);
    off.tracing(true, true);
    off.settle();
    CHECK(off.count("upscale-rr-hit") == 0);
    CHECK(off.temporal_passes() == reflectOnly + giOnly);
    CHECK_FALSE(off.renderer.ray_tracing_denoiser_status().reflectionsRr);
    CHECK_FALSE(off.renderer.ray_tracing_denoiser_status().giRr);
    CHECK(off.renderer.ray_tracing_denoiser_status().reason.empty());
}

TEST_CASE("rt rr signals: the AO keeps the engine's denoiser, and only the reflections or only the GI can go") {
    const int ao = temporal_of(true, false, false, true);
    CHECK(ao >= 1);
    CHECK(temporal_of(false, false, false, true) == ao);  // the same with Ray Reconstruction off
    // Everything on: with Ray Reconstruction the AO's passes are all that is left; without it the sum of the three.
    CHECK(temporal_of(true, true, true, true) == ao);
    CHECK(temporal_of(false, true, true, true) ==
          ao + temporal_of(false, true, false, false) + temporal_of(false, false, true, false));
    CHECK(temporal_of(true, true, false, false) == 0);
    CHECK(temporal_of(true, false, true, false) == 0);
}

TEST_CASE("rt rr signals: a frame Ray Reconstruction refuses shows the signals noisy once, and the engine's denoiser "
          "starts from a reset history") {
    Rig r;
    r.upscaler(true);
    r.tracing(true, true);
    for (int i = 0; i < 4; ++i) r.frame();
    REQUIRE(r.fake.rrFrames >= 1);
    CHECK(r.denoiser().history_image_count() == 0);
    // The provider refuses the next frame: it is drawn with the noisy signals (nothing of the denoiser was recorded for it), and the status says so.
    r.fake.refuses = true;
    r.dev->clear_commands();
    r.frame();
    CHECK(r.temporal_passes() == 0);
    CHECK(r.denoiser().history_image_count() == 0);
    const render::RtDenoiserStatus refused = r.renderer.ray_tracing_denoiser_status();
    CHECK_FALSE(refused.reflectionsRr);
    CHECK_FALSE(refused.giRr);
    CHECK(refused.reason.find("fake refused") != std::string::npos);
    // The next frame: Ray Reconstruction is off for the run (fail once, stay off), so the engine's denoiser is back, from a history that does not exist.
    const int rrFrames = r.fake.rrFrames;
    r.dev->clear_commands();
    r.frame();
    CHECK(r.fake.rrFrames == rrFrames);
    CHECK(r.temporal_passes() >= 3);  // the reflections' two signals and the GI's
    CHECK(r.denoiser().history_image_count() > 0);
    const std::uint64_t cam = r.cam.bits();
    CHECK(r.denoiser().last_reset(cam, RendererTestAccess::rt_gi_pixel_signal_id()) == render::DenoiseReset::Fresh);
    CHECK(r.denoiser().last_reset(cam, RendererTestAccess::rt_reflect_signal_id()) == render::DenoiseReset::Fresh);
    const render::RtDenoiserStatus after = r.renderer.ray_tracing_denoiser_status();
    CHECK_FALSE(after.reflectionsRr);
    CHECK_FALSE(after.giRr);
    CHECK_FALSE(after.reason.empty());  // Ray Reconstruction was asked for and is not drawing: why
    // And the frame after that blends with it.
    r.frame();
    CHECK(r.denoiser().last_reset(cam, RendererTestAccess::rt_gi_pixel_signal_id()) == render::DenoiseReset::None);
    CHECK(r.errors().empty());
}

TEST_CASE("rt rr signals: switching Ray Reconstruction off gives the signals back to the engine's denoiser, and the "
          "hit distance image goes") {
    Rig r;
    r.upscaler(true);
    r.tracing(true, true);
    for (int i = 0; i < 4; ++i) r.frame();
    CHECK(RendererTestAccess::rr_hit_image(r.renderer));
    CHECK(r.denoiser().history_image_count() == 0);
    r.upscaler(false);
    for (int i = 0; i < 2; ++i) r.frame();
    CHECK_FALSE(RendererTestAccess::rr_hit_image(r.renderer));
    CHECK_FALSE(RendererTestAccess::rr_guide_images(r.renderer));
    CHECK(r.denoiser().history_image_count() > 0);
    CHECK(r.renderer.ray_tracing_denoiser_status().reason.empty());
    // And on again: the signals go back to Ray Reconstruction and the engine's histories are freed.
    r.upscaler(true);
    for (int i = 0; i < 3; ++i) r.frame();
    CHECK(r.denoiser().history_image_count() == 0);
    CHECK(RendererTestAccess::rr_hit_image(r.renderer));
    CHECK(r.renderer.ray_tracing_denoiser_status().giRr);
}

TEST_CASE("rt rr signals: a gamma scene (Ray Reconstruction cannot draw it) keeps the engine's denoiser from the first "
          "frame, with the reason") {
    Rig r;
    r.w.settings().colorSpace = ColorSpace::Gamma;
    r.upscaler(true);
    r.tracing(true, true);
    r.settle();
    CHECK(r.fake.rrFrames == 0);
    CHECK(r.temporal_passes() >= 3);
    CHECK(r.count("upscale-rr-hit") == 0);
    const render::RtDenoiserStatus st = r.renderer.ray_tracing_denoiser_status();
    CHECK_FALSE(st.reflectionsRr);
    CHECK_FALSE(st.giRr);
    CHECK(st.reason.find("linear") != std::string::npos);
}

TEST_CASE("rt rr signals: a device that cannot filter 32-bit floats keeps the GI's denoiser (the lit meshes read its "
          "16-bit image) and gives the reflections to Ray Reconstruction") {
    Rig r(false);
    r.upscaler(true);
    r.tracing(true, true);
    r.settle();
    CHECK(r.errors().empty());
    REQUIRE(r.fake.rrFrames >= 1);
    CHECK(r.fake.hitGuide);
    const render::RtDenoiserStatus st = r.renderer.ray_tracing_denoiser_status();
    CHECK(st.reflectionsRr);
    CHECK_FALSE(st.giRr);
    CHECK(st.reason.find("32-bit") != std::string::npos);
    // The GI's one signal is the engine's: one guide, one temporal and one a-trous pass for it, and none for the reflections.
    CHECK(r.temporal_passes() == 1);
    CHECK(r.denoiser().history_image_count() > 0);
}

// ---- M79 POLISH-RB: what the status says when a camera does not trace, a recovery that is true, the optional hit guide, two cameras -------------------------

TEST_CASE("rt rr signals: a kernel the driver refused is reported as not traced, and Ray Reconstruction did not take "
          "what was never traced") {
    Rig r;
    r.dev->inject_faults(true, false);  // every compute pipeline is refused: neither kernel runs
    r.upscaler(true);
    r.tracing(true, true);
    for (int i = 0; i < 4; ++i) r.frame();
    const render::RtDenoiserStatus st = r.renderer.ray_tracing_denoiser_status();
    CHECK(st.settled);
    CHECK_FALSE(st.reflectionsTraced);
    CHECK_FALSE(st.giTraced);
    CHECK_FALSE(st.reflectionsRr);
    CHECK_FALSE(st.giRr);
    // A healthy rig of the same settings traces both and says so.
    Rig ok;
    ok.upscaler(true);
    ok.tracing(true, true);
    ok.settle();
    const render::RtDenoiserStatus good = ok.renderer.ray_tracing_denoiser_status();
    CHECK(good.settled);
    CHECK(good.reflectionsTraced);
    CHECK(good.giTraced);
    CHECK(good.reflectionsRr);
    CHECK(good.giRr);
    // Before any frame nothing is known.
    Rig fresh;
    CHECK_FALSE(fresh.renderer.ray_tracing_denoiser_status().settled);
}

TEST_CASE("rt rr signals: the recovery step counts frames in a row that the decision and DLSS agree on") {
    int agree = 0;
    // A frame the decision has no answer for counts neither way.
    for (int i = 0; i < 3 * render::kRrRecoverFrames; ++i) CHECK_FALSE(render::rr_recovery_step(agree, false, true));
    CHECK(agree == 0);
    for (int i = 0; i < render::kRrRecoverFrames - 1; ++i) CHECK_FALSE(render::rr_recovery_step(agree, true, true));
    CHECK(render::rr_recovery_step(agree, true, true));
    CHECK(agree == 0);
    // A frame DLSS drew without it starts the count over.
    for (int i = 0; i < render::kRrRecoverFrames - 1; ++i) CHECK_FALSE(render::rr_recovery_step(agree, true, true));
    CHECK_FALSE(render::rr_recovery_step(agree, true, false));
    CHECK(agree == 0);
    for (int i = 0; i < render::kRrRecoverFrames - 1; ++i) CHECK_FALSE(render::rr_recovery_step(agree, true, true));
    CHECK(render::rr_recovery_step(agree, true, true));
}

TEST_CASE(
    "rt rr signals: a transient disagreement recovers after kRrRecoverFrames agreeing frames, and the text says so") {
    Rig r;
    r.upscaler(true);
    r.tracing(true, true);
    for (int i = 0; i < 4; ++i) r.frame();
    REQUIRE(r.renderer.ray_tracing_denoiser_status().giRr);
    CHECK_FALSE(RendererTestAccess::rr_signals_lost(r.renderer));
    // A disagreement that is not a refusal for the run: the engine's denoiser keeps the signals.
    RendererTestAccess::set_rr_signals_lost(r.renderer, true);
    r.dev->clear_commands();
    r.frame();
    CHECK(r.temporal_passes() >= 3);
    CHECK_FALSE(RendererTestAccess::rr_failed(r.renderer));
    const render::RtDenoiserStatus held = r.renderer.ray_tracing_denoiser_status();
    CHECK_FALSE(held.giRr);
    CHECK(held.reason.find(std::to_string(render::kRrRecoverFrames) + " frames") != std::string::npos);
    CHECK(held.reason.find("off and on") == std::string::npos);
    CHECK(RendererTestAccess::rr_signals_lost(r.renderer));
    // Frames in a row with the decision and DLSS in agreement give the signals back.
    for (int i = 0; i < 3 * render::kRrRecoverFrames && RendererTestAccess::rr_signals_lost(r.renderer); ++i) r.frame();
    CHECK_FALSE(RendererTestAccess::rr_signals_lost(r.renderer));
    for (int i = 0; i < 3; ++i) r.frame();
    r.dev->clear_commands();
    r.frame();
    CHECK(r.temporal_passes() == 0);
    CHECK(r.denoiser().history_image_count() == 0);
    const render::RtDenoiserStatus back = r.renderer.ray_tracing_denoiser_status();
    CHECK(back.reflectionsRr);
    CHECK(back.giRr);
    CHECK(back.reason.empty());
}

TEST_CASE("rt rr signals: a frame DLSS refused for the run never recovers, and the text says the run, not a switch") {
    Rig r;
    r.upscaler(true);
    r.tracing(true, true);
    for (int i = 0; i < 4; ++i) r.frame();
    r.fake.refuses = true;
    r.frame();
    CHECK(RendererTestAccess::rr_failed(r.renderer));
    const render::RtDenoiserStatus refused = r.renderer.ray_tracing_denoiser_status();
    CHECK(refused.reason.find("rest of this run") != std::string::npos);
    CHECK(refused.reason.find("off and on") == std::string::npos);
    r.fake.refuses = false;
    for (int i = 0; i < 4 * render::kRrRecoverFrames; ++i) r.frame();
    CHECK(RendererTestAccess::rr_failed(r.renderer));
    CHECK(RendererTestAccess::rr_signals_lost(r.renderer));
    CHECK(r.temporal_passes() >= 3);  // still the engine's denoiser
    const render::RtDenoiserStatus later = r.renderer.ray_tracing_denoiser_status();
    CHECK_FALSE(later.giRr);
    CHECK(later.reason.find("started again") != std::string::npos);
    CHECK(later.reason.find("off and on") == std::string::npos);
    // Switching the setting off and on does not bring it back either (rrFailed is for the run).
    r.upscaler(false);
    r.frame();
    r.upscaler(true);
    for (int i = 0; i < 4; ++i) r.frame();
    CHECK_FALSE(r.renderer.ray_tracing_denoiser_status().giRr);
}

TEST_CASE("rt rr signals: a hit distance shader that does not compile only leaves that guide out; the reflections "
          "still go to Ray Reconstruction") {
    Rig r;
    r.dev->fail_shaders_labelled("upscale_rr_rr_hit_shader");
    r.upscaler(true);
    r.tracing(true, true);
    r.settle();
    REQUIRE(r.fake.rrFrames >= 1);
    CHECK(RendererTestAccess::rr_hit_program_failed(r.renderer));
    CHECK_FALSE(RendererTestAccess::rr_hit_image(r.renderer));
    CHECK_FALSE(r.fake.hitGuide);
    CHECK(r.count("begin_pass 'upscale-rr-hit'") == 0);
    CHECK(r.count("begin_pass 'upscale-rr-guides'") == 1);  // the other guides are still made
    CHECK(r.temporal_passes() == 0);
    const render::RtDenoiserStatus st = r.renderer.ray_tracing_denoiser_status();
    CHECK(st.reflectionsRr);
    CHECK(st.giRr);
    CHECK_FALSE(RendererTestAccess::rr_failed(r.renderer));
    CHECK(st.reason.find("hit distance guide is left out") != std::string::npos);
    // Without reflections the shader is never made, so its failure is never met.
    Rig gi;
    gi.dev->fail_shaders_labelled("upscale_rr_rr_hit_shader");
    gi.upscaler(true);
    gi.tracing(false, true);
    gi.settle();
    CHECK_FALSE(RendererTestAccess::rr_hit_program_failed(gi.renderer));
    CHECK(gi.renderer.ray_tracing_denoiser_status().giRr);
    CHECK(gi.renderer.ray_tracing_denoiser_status().reason.empty());
}

TEST_CASE("rt rr signals: a render target camera next to the screen camera leaves the screen camera's signals to Ray "
          "Reconstruction") {
    Rig r;
    Entity second = make(r.w, "mini", {0, 3, 12});
    auto& c = r.w.add<Camera>(second);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.renderTarget = "mini";
    c.renderTargetSize = Vec2{64.0f, 48.0f};
    r.upscaler(true);
    r.tracing(true, true);
    r.settle(6);
    INFO(r.errors());
    CHECK(r.errors().empty());
    REQUIRE(r.fake.rrFrames >= 1);
    // The camera DLSS resolves handed its signals over: the engine's denoiser has no history for it, and the status says so.
    CHECK(r.denoiser().last_used_history(r.cam.bits(), RendererTestAccess::rt_gi_pixel_signal_id()) == false);
    CHECK(r.denoiser().last_reset(r.cam.bits(), RendererTestAccess::rt_gi_pixel_signal_id()) ==
          render::DenoiseReset::Fresh);
    CHECK(r.renderer.ray_tracing_denoiser_status().giRr);
    CHECK(r.renderer.ray_tracing_denoiser_status().reflectionsRr);
}

TEST_CASE("rt rr signals: a split screen has no camera DLSS resolves, so both cameras keep the engine's denoiser and "
          "no G-buffer is drawn for Ray Reconstruction") {
    // One camera: the thin G-buffer pass is there for Ray Reconstruction.
    int single = 0;
    {
        Rig r;
        r.upscaler(true);
        r.tracing(
            false,
            true);  // the GI only: the reflections ask for the G-buffer themselves, Ray Reconstruction is the only other one that does
        r.settle();
        single = r.count("begin_pass 'gbuffer'");
        CHECK(single >= 1);
    }
    Rig r;
    r.w.get<Camera>(r.cam)->viewport = Rect{0, 0, 0.5f, 1};
    Entity second = make(r.w, "cam2", {4, 3, 12});
    auto& c = r.w.add<Camera>(second);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.viewport = Rect{0.5f, 0, 0.5f, 1};
    c.clear = false;
    r.upscaler(true);
    r.tracing(
        false,
        true);  // the GI only: the reflections ask for the G-buffer themselves, Ray Reconstruction is the only other one that does
    r.settle(6);
    INFO(r.errors());
    CHECK(r.errors().empty());
    CHECK(r.fake.rrFrames == 0);
    CHECK(r.count("begin_pass 'gbuffer'") == 0);
    CHECK(r.count("upscale-rr-hit") == 0);
    CHECK(r.temporal_passes() >= 1);
    CHECK(r.denoiser().last_used_history(r.cam.bits(), RendererTestAccess::rt_gi_pixel_signal_id()));
    const render::RtDenoiserStatus st = r.renderer.ray_tracing_denoiser_status();
    CHECK_FALSE(st.giRr);
    CHECK_FALSE(st.reflectionsRr);
    CHECK(st.reason.find("not the one DLSS resolves") != std::string::npos);
}

TEST_CASE("rt rr signals: the upscaler switched off in the middle of a run gives the signals back to the engine's "
          "denoiser with a fresh history") {
    Rig r;
    r.upscaler(true);
    r.tracing(true, true);
    for (int i = 0; i < 4; ++i) r.frame();
    REQUIRE(r.renderer.ray_tracing_denoiser_status().giRr);
    // The upscale stage goes away altogether (not only Ray Reconstruction).
    UpscalerSettings stretch;
    stretch.mode = UpscalerMode::Stretch;
    r.renderer.set_upscaler(stretch);
    r.renderer.set_upscale_stage(false);
    r.renderer.set_render_scale(1.0f);
    const std::uint64_t cam = r.cam.bits();
    r.dev->clear_commands();
    r.frame();
    CHECK(r.temporal_passes() >= 3);
    CHECK(r.denoiser().history_image_count() > 0);
    CHECK(r.denoiser().last_reset(cam, RendererTestAccess::rt_gi_pixel_signal_id()) == render::DenoiseReset::Fresh);
    CHECK(r.denoiser().last_reset(cam, RendererTestAccess::rt_reflect_signal_id()) == render::DenoiseReset::Fresh);
    r.frame();
    CHECK_FALSE(RendererTestAccess::rr_hit_image(r.renderer));
    CHECK_FALSE(RendererTestAccess::rr_guide_images(r.renderer));
    const render::RtDenoiserStatus st = r.renderer.ray_tracing_denoiser_status();
    CHECK_FALSE(st.giRr);
    CHECK_FALSE(st.reflectionsRr);
    CHECK(st.giTraced);
    CHECK(r.denoiser().last_reset(cam, RendererTestAccess::rt_gi_pixel_signal_id()) == render::DenoiseReset::None);
    CHECK(r.errors().empty());
}

// ---- M79 POLISH-last-B ------------------------------------------------------------------------------------------------------------------------------

TEST_CASE(
    "rt rr signals: reflectionsTraced and giTraced say whether some camera traced the signal, not whether the last "
    "one did") {
    Rig r;
    // A second camera, drawn after the screen camera, into an image of its own.
    Entity second = make(r.w, "mini", {0, 3, 12});
    auto& c = r.w.add<Camera>(second);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.renderTarget = "mini";
    c.renderTargetSize = Vec2{64.0f, 48.0f};
    r.upscaler(true);
    r.tracing(true, true);
    r.settle(6);
    render::RtDenoiserStatus st = r.renderer.ray_tracing_denoiser_status();
    CHECK(st.reflectionsTraced);
    CHECK(st.giTraced);
    // The second camera alone (the screen camera is switched off) is the only one that can trace: the status still reports it.
    r.w.get<Camera>(r.cam)->primary = false;
    r.settle(6);
    st = r.renderer.ray_tracing_denoiser_status();
    CHECK(st.settled);
    INFO("reflectionsTraced " << st.reflectionsTraced << " giTraced " << st.giTraced << " reason " << st.reason);
    CHECK(st.reflectionsTraced);
    CHECK(st.giTraced);
}

TEST_CASE("rt rr signals: the hit distance shader is made when the frame is planned, so its failure is known even on a "
          "frame whose reflections never reach the guide pass") {
    Rig r;
    r.dev->fail_shaders_labelled("upscale_rr_rr_hit_shader");
    r.dev->inject_faults(true,
                         false);  // the reflections' kernel is refused: no frame ever has an image for the hit pass
    r.upscaler(true);
    r.tracing(true, false);
    r.frame();
    CHECK(RendererTestAccess::rr_hit_program_failed(r.renderer));
    CHECK(r.count("begin_pass 'upscale-rr-hit'") == 0);
    // Without reflections the program is not asked for at all.
    Rig gi;
    gi.dev->fail_shaders_labelled("upscale_rr_rr_hit_shader");
    gi.upscaler(true);
    gi.tracing(false, true);
    gi.frame();
    CHECK_FALSE(RendererTestAccess::rr_hit_program_failed(gi.renderer));
}

TEST_CASE("rt rr signals: a terrain G-buffer shader that does not compile is in the status reason, with the shader's "
          "name") {
    Rig r;
    constexpr int kSamples = 33;
    GrayImage16 g;
    g.width = g.height = kSamples;
    g.sixteenBit = true;
    g.samples.assign(std::size_t(kSamples) * kSamples, std::uint16_t(20000));
    const auto png = encode_png_gray16(g);
    const std::string file = fs::path_to_utf8(gfx().projectDir / "rr_flat.png");
    REQUIRE(fs::write_bytes(file, png.data(), png.size()).ok());
    Entity ground = make(r.w, "ground", {0, -2, 0});
    auto& t = r.w.add<Terrain3D>(ground);
    t.heightmap = file;
    t.size = {32.0f, 32.0f};
    t.heightScale = 4.0f;
    r.dev->fail_shaders_labelled("terrain_gbuffer_shader");
    r.upscaler(true);
    r.tracing(false, true);
    r.settle(6);
    const render::RtDenoiserStatus st = r.renderer.ray_tracing_denoiser_status();
    INFO(st.reason);
    CHECK(st.reason.find("terrain_gbuffer") != std::string::npos);
    CHECK(st.reason.find("did not compile") != std::string::npos);
    // Ray Reconstruction still takes the signal: the guides only keep the constants for the terrain.
    CHECK(st.giRr);
    // A healthy rig says nothing of the kind.
    Rig ok;
    ok.upscaler(true);
    ok.tracing(false, true);
    ok.settle(6);
    CHECK(ok.renderer.ray_tracing_denoiser_status().reason.empty());
}

TEST_CASE("rt rr signals: a frame the provider itself fails sets rrSignalsLost by the natural path, and the text says "
          "the signals stay with the engine for the run") {
    Rig r;
    r.upscaler(true);
    r.tracing(true, true);
    for (int i = 0; i < 4; ++i) r.frame();
    REQUIRE(r.renderer.ray_tracing_denoiser_status().giRr);
    REQUIRE_FALSE(RendererTestAccess::rr_signals_lost(r.renderer));
    r.fake.failNext = true;
    r.frame();
    CHECK(RendererTestAccess::rr_signals_lost(
        r.renderer));  // no test access wrote it: the frame was handed the signals and DLSS did not draw it
    CHECK_FALSE(RendererTestAccess::rr_failed(r.renderer));
    const render::RtDenoiserStatus lost = r.renderer.ray_tracing_denoiser_status();
    CHECK_FALSE(lost.giRr);
    CHECK(lost.reason.find("started again") != std::string::npos);
    CHECK(lost.reason.find("the fake provider failed a frame") != std::string::npos);
    // A provider that failed for good draws no frame again, so the recovery count never reaches kRrRecoverFrames: the engine keeps the signals.
    r.dev->clear_commands();
    for (int i = 0; i < 3 * render::kRrRecoverFrames; ++i) r.frame();
    CHECK(RendererTestAccess::rr_signals_lost(r.renderer));
    CHECK_FALSE(r.renderer.ray_tracing_denoiser_status().giRr);
    CHECK(r.temporal_passes() >= 1);
    // The reason of those later frames says DLSS failed earlier in this run, with the provider's own reason, not that the camera is another one.
    const std::string later = r.renderer.ray_tracing_denoiser_status().reason;
    INFO(later);
    CHECK(later.find("failed a frame earlier in this run") != std::string::npos);
    CHECK(later.find("the fake provider failed a frame") != std::string::npos);
    CHECK(later.find("not the one DLSS resolves") == std::string::npos);
}
