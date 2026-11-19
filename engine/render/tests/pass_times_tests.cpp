// What a frame cost, pass by pass: RenderStats::passes / jobs, Renderer::frame_graph_report (the `render.frame_graph` command), the
// profiler's zones and the GPU timer of the passes. Nothing here compares a time with a threshold: times are measurements that
// differ from run to run and between backends (Metal has no GPU timer, GL and D3D11 have one that answers a few frames late),
// so the tests check what must hold on every backend: the names, the order, the sums, the signs and the reasons.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

#include "fa/core/profiler.h"
#include "frame_graph.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;

namespace {

// A camera with bloom (several passes), a bright rectangle and a HUD box: one job with a handful of passes.
void bloom_scene(World& world) {
    Entity cam = make(world, "cam");
    Camera& c = world.add<Camera>(cam);
    c.clearColor = Color{0.02f, 0.02f, 0.04f, 1.0f};
    c.bloom = true;
    c.bloomThreshold = 0.5f;
    c.bloomRadius = 40.0f;
    Entity neon = make(world, "neon");
    auto& s = world.add<Shape2D>(neon);
    s.shape = ShapeType::Rectangle;
    s.size = {40, 20};
    s.color = Color{1.0f, 0.3f, 0.9f, 1.0f};
    s.blend = BlendMode::Additive;
}

// Switches the profiler on for a test and puts it back (it is one per process).
struct ProfilerOn {
    bool was = Profiler::on();
    ProfilerOn() { Profiler::get().set_enabled(true); }
    ~ProfilerOn() { Profiler::get().set_enabled(was); }
};

std::string job_of(const std::string& pass) {
    const std::size_t slash = pass.rfind('/');
    return slash == std::string::npos ? std::string() : pass.substr(0, slash);
}

}  // namespace

TEST_CASE("pass times: each pass that ran has a CPU time, in the order of the graph, and the job sums add up") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World world;
    bloom_scene(world);
    g.render(world);
    const RenderStats st = g.renderer.stats();
    const render::FrameGraph* graph = render::renderer_frame_graph(g.renderer);
    REQUIRE(graph != nullptr);
    const std::vector<std::string> order = graph->order_names();
    REQUIRE(!order.empty());
    REQUIRE(st.passes.size() == order.size());
    double sum = 0.0;
    for (std::size_t i = 0; i < order.size(); ++i) {
        INFO("pass " << order[i]);
        CHECK(st.passes[i].name == order[i]);
        CHECK(st.passes[i].job == job_of(order[i]));
        CHECK(!st.passes[i].job.empty());
        CHECK(st.passes[i].cpuMs >= 0.0);
        CHECK(st.passes[i].gpuMs == -1.0);  // the profiler is off: nothing is timed on the GPU
        sum += st.passes[i].cpuMs;
    }
    REQUIRE(!st.jobs.empty());
    int passes = 0;
    double jobSum = 0.0;
    for (const RenderStats::JobTime& j : st.jobs) {
        INFO("job " << j.job);
        int mine = 0;
        double cpu = 0.0;
        for (const RenderStats::PassTime& p : st.passes) {
            if (p.job != j.job) continue;
            ++mine;
            cpu += p.cpuMs;
        }
        CHECK(j.passes == mine);
        CHECK(j.cpuMs == doctest::Approx(cpu).epsilon(1e-9).scale(1.0));
        CHECK(j.gpuMs == -1.0);
        passes += j.passes;
        jobSum += j.cpuMs;
    }
    CHECK(passes == int(st.passes.size()));
    CHECK(jobSum == doctest::Approx(sum).epsilon(1e-9).scale(1.0));
    // The passes are inside the frame's own time.
    CHECK(sum <= st.cpuMs + 1e-6);
    CHECK(st.sortKeyFallbacks == 0);
    CHECK(st.to_json()["sortKeyFallbacks"] == 0);
}

TEST_CASE("pass times: a frame with a render target has a job for the target and one for the camera") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World world;
    Entity cam = make(world, "game");
    world.add<Camera>(cam).clearColor = Color{0, 0, 0, 1};
    Entity page = make(world, "cam-page", {1000, 0, 0});
    Camera& pc = world.add<Camera>(page);
    pc.renderTarget = "page";
    pc.renderTargetSize = Vec2{64, 64};
    pc.orthoSize = 32;
    pc.clearColor = Color{0.1f, 0.2f, 0.7f, 1};
    g.render(world);
    const RenderStats st = g.renderer.stats();
    REQUIRE(st.jobs.size() >= 2);
    bool target = false, camera = false;
    for (const RenderStats::JobTime& j : st.jobs) {
        target = target || j.job == "target:page";
        camera = camera || j.job == "camera:0";
        CHECK(j.passes >= 1);
        CHECK(j.cpuMs >= 0.0);
    }
    CHECK(target);
    CHECK(camera);
}

TEST_CASE("frame graph report: the graph, the pass times and the GPU state of the last frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World world;
    bloom_scene(world);
    g.render(world);
    const Json rep = g.renderer.frame_graph_report();
    REQUIRE(rep.is_object());
    CHECK(rep["source"] == "frame");
    CHECK(rep["backend"] == std::string(Renderer::backend_name()));
    const Json& order = rep["graph"]["order"];
    const Json& times = rep["passTimes"];
    REQUIRE(times.size() == order.size());
    REQUIRE(times.size() > 0);
    for (std::size_t i = 0; i < times.size(); ++i) {
        CHECK(times[i]["name"] == order[i]);
        CHECK(times[i]["cpuMs"].get<double>() >= 0.0);
        CHECK(times[i]["gpuMs"].get<double>() == -1.0);  // profiler off
    }
    double cpu = 0.0;
    int passes = 0;
    for (const Json& j : rep["jobTimes"]) {
        cpu += j["cpuMs"].get<double>();
        passes += j["passes"].get<int>();
    }
    double cpuPasses = 0.0;
    for (const Json& p : times) cpuPasses += p["cpuMs"].get<double>();
    CHECK(passes == int(times.size()));
    CHECK(cpu == doctest::Approx(cpuPasses).epsilon(0.01).scale(1.0));  // each number is rounded to 3 decimals
    // GPU: either the backend measures (the profiler is off now, so it says that) or it says why not.
    const Json& gpu = rep["gpu"];
    std::string why;
    const bool supported = g.renderer.gpu_timing_supported(&why);
    CHECK(gpu["supported"].get<bool>() == supported);
    CHECK(gpu["measuring"].get<bool>() == false);
    REQUIRE(gpu["reason"].is_string());
    CHECK(!gpu["reason"].get<std::string>().empty());
    if (!supported) CHECK(gpu["reason"] == why);
    CHECK(gpu["maxTimedPasses"].get<int>() > 0);
}

TEST_CASE("post pass times: the post passes are named, summed, and a missing GPU time is null with a reason, never 0") {
    CHECK(is_post_pass("camera:0/post"));
    CHECK(is_post_pass("camera:0/bloom-bright"));
    CHECK(is_post_pass("target:minimap/exposure-adapt"));
    CHECK(is_post_pass("post"));
    CHECK(is_post_pass("camera:0/post-part0"));  // a piece of the final pass cut by a custom pass
    CHECK(is_post_pass("camera:0/post-base"));
    CHECK(is_post_pass("camera:0/custom-tonemap-pass0"));
    CHECK(is_post_pass("target:minimap/custom-main-pass1"));
    CHECK(!is_post_pass("camera:0/customised"));  // "custom" or "custom-<what>" only
    CHECK(!is_post_pass("camera:0/prepass"));
    CHECK(!is_post_pass("camera:0/sprite-coverage"));
    CHECK(!is_post_pass("camera:0/game"));

    Gfx& g = gfx();
    REQUIRE(g.ok);
    World world;
    bloom_scene(world);
    g.render(world);  // the profiler is off: nothing is timed on the GPU
    Json rep = g.renderer.frame_graph_report();
    REQUIRE(rep["postProcess"].is_object());
    const Json* pp = &rep["postProcess"];
    REQUIRE((*pp)["passes"].size() > 0);  // the bloom passes
    bool bright = false;
    double cpu = 0.0;
    for (const Json& p : (*pp)["passes"]) {
        bright = bright || p["name"].get<std::string>().find("bloom-bright") != std::string::npos;
        CHECK(is_post_pass(p["name"].get<std::string>()));
        cpu += p["cpuMs"].get<double>();
    }
    CHECK(bright);
    CHECK(cpu == doctest::Approx((*pp)["cpuMs"].get<double>()).epsilon(0.01).scale(1.0));
    CHECK((*pp)["gpuMs"].is_null());
    CHECK((*pp)["gpuStatus"] == "unavailable");
    REQUIRE((*pp)["gpuReason"].is_string());
    CHECK(!(*pp)["gpuReason"].get<std::string>().empty());
    const PostPassTimes none = post_pass_times(g.renderer.stats());
    CHECK(none.gpuMs == -1.0);
    CHECK(none.passes.size() == (*pp)["passes"].size());

    {  // with the profiler on: a number, or the same "unavailable" with the backend's reason
        ProfilerOn on;
        for (int i = 0; i < 12; ++i) g.render(world);
        rep = g.renderer.frame_graph_report();
        pp = &rep["postProcess"];
        if ((*pp)["gpuStatus"] == "measured") {
            CHECK((*pp)["gpuMs"].get<double>() >= 0.0);
            CHECK((*pp)["gpuReason"].is_null());
        } else {
            CHECK((*pp)["gpuMs"].is_null());
            CHECK((*pp)["gpuReason"].is_string());
        }
    }
}

TEST_CASE("is_post_pass: an effect's own name or <effect>-<what>, nothing that merely starts like it") {
    CHECK(is_post_pass("main/post"));
    CHECK(is_post_pass("camera:2/post-base"));  // per-camera stacks (M71-C3a): the pass under the cameras' rectangles
    CHECK(is_post_pass("camera:1/exposure-luma"));
    CHECK(is_post_pass("camera:1/exposure-adapt"));
    CHECK(!is_post_pass("camera:1/post-basement"));
    CHECK(is_post_pass("main/bloom-bright"));
    CHECK(is_post_pass("main/ssao"));
    CHECK(is_post_pass("main/color-filter"));
    CHECK(!is_post_pass("main/fogbank"));
    CHECK(!is_post_pass("main/taaa"));
    CHECK(!is_post_pass("main/prepass"));
    CHECK(!is_post_pass("main/sprite-coverage"));
}

TEST_CASE("frame graph report: null before the first frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Renderer fresh;
    CHECK(fresh.frame_graph_report().is_null());  // not initialized
    RendererDesc d;
    d.designWidth = 64;
    d.designHeight = 64;
    d.headless = true;
    d.adoptContext = true;
    std::string error;
    REQUIRE_MESSAGE(fresh.init(d, g.gpu.environment(), &error), error);
    CHECK(fresh.frame_graph_report().is_null());  // initialized, nothing drawn
    fresh.shutdown();
}

TEST_CASE("pass times: with the profiler on every pass is a profiler zone and the GPU numbers are -1 or not negative") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World world;
    bloom_scene(world);
    ProfilerOn on;
    Profiler& prof = Profiler::get();
    std::string why;
    const bool supported = g.renderer.gpu_timing_supported(&why);
    std::vector<std::string> names;
    bool anyGpu = false;
    // Timer queries answer a few frames late: draw a few frames, and do not require the answer (a loaded CI machine may be slower).
    for (int i = 0; i < 12; ++i) {
        prof.begin_frame();
        g.render(world);
        prof.end_frame();
        const RenderStats st = g.renderer.stats();
        REQUIRE(!st.passes.empty());
        if (i == 0) {
            for (const RenderStats::PassTime& p : st.passes) names.push_back(p.name);
        }
        for (const RenderStats::PassTime& p : st.passes) {
            CHECK(p.cpuMs >= 0.0);
            CHECK((p.gpuMs == -1.0 || p.gpuMs >= 0.0));
            anyGpu = anyGpu || p.gpuMs >= 0.0;
            if (!supported) CHECK(p.gpuMs == -1.0);
        }
        // Zones: one per pass of this frame, with the pass's name.
        const ProfFrame& f = prof.last();
        REQUIRE(f.zones.size() == st.passes.size());
        for (const RenderStats::PassTime& p : st.passes) {
            const auto it =
                std::find_if(f.zones.begin(), f.zones.end(), [&](const ProfZoneSample& z) { return z.name == p.name; });
            INFO("zone " << p.name);
            REQUIRE(it != f.zones.end());
            CHECK(it->calls == 1);
            CHECK(it->ms >= 0.0);
        }
    }
    const Json rep = g.renderer.frame_graph_report();
    CHECK(rep["gpu"]["supported"].get<bool>() == supported);
    CHECK(rep["gpu"]["measuring"].get<bool>() == supported);
    if (!anyGpu) {
        REQUIRE(rep["gpu"]["reason"].is_string());  // no number: the reason says why
        if (!supported) CHECK(rep["gpu"]["reason"] == why);
    }
    // The frame times the passes' polling read are still handed to take_gpu_ms, none negative.
    std::vector<double> frames;
    g.renderer.take_gpu_ms(frames);
    for (double ms : frames) CHECK(ms >= 0.0);
    if (!supported) CHECK(frames.empty());
}

TEST_CASE("pass times: stats(false) leaves them out, and a capture does not change the ones of the last frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World world;
    bloom_scene(world);
    g.render(world);
    const RenderStats full = g.renderer.stats();
    REQUIRE(!full.passes.empty());
    REQUIRE(!full.jobs.empty());
    const RenderStats light = g.renderer.stats(false);
    CHECK(light.passes.empty());
    CHECK(light.jobs.empty());
    CHECK(light.drawCalls == full.drawCalls);
    // Reading them twice gives the same passes.
    CHECK(g.renderer.stats().passes.size() == full.passes.size());

    // The capture replaces the frame graph; the stats of the frame keep the passes of the frame, the report shows the capture.
    Renderer::WorldCapture spec;
    spec.subject = world.find("neon");
    spec.rect = Rect{-50, -30, 100, 60};
    spec.scale = 1.0f;
    Image img;
    std::string err;
    REQUIRE_MESSAGE(g.renderer.capture_world(world, spec, img, &err), err);
    const RenderStats after = g.renderer.stats();
    REQUIRE(after.passes.size() == full.passes.size());
    for (std::size_t i = 0; i < full.passes.size(); ++i) CHECK(after.passes[i].name == full.passes[i].name);
    CHECK(g.renderer.frame_graph_report()["source"] == "capture");
    g.render(world);
    CHECK(g.renderer.frame_graph_report()["source"] == "frame");
    CHECK(g.renderer.stats().passes.size() == full.passes.size());
}

TEST_CASE("pass times: the GPU times of an earlier run of the profiler are forgotten when it is switched on again") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World world;
    bloom_scene(world);
    {
        ProfilerOn on;
        for (int i = 0; i < 12; ++i) g.render(world);  // the answers come back a few frames late
    }
    // Off: no pass has a GPU time, whatever the timers still held.
    g.render(world);
    for (const RenderStats::PassTime& p : g.renderer.stats().passes) CHECK(p.gpuMs == -1.0);
    // On again: the first frame has no answer of its own yet and the answers of the first run were dropped.
    ProfilerOn on;
    g.render(world);
    const RenderStats st = g.renderer.stats();
    REQUIRE(!st.passes.empty());
    for (const RenderStats::PassTime& p : st.passes) CHECK(p.gpuMs == -1.0);
}
