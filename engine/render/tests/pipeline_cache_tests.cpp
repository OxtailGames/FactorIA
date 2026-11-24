// The pipeline cache of Gpu: pipelines are keyed by the format of the pass they draw into (TargetFormat), so a change
// of format or sample count makes new entries and flushes nothing, and the cache is bounded by use.
#include "test_util.h"

#include <string>
#include <vector>

#include "gpu/sokol_device.h"  // sg_query_pixelformat: the formats the cases can draw into, before any Gpu
#include "render_internal.h"

using namespace fa;
using namespace fa::test;

namespace {

struct FlatScene {
    World world;
    FlatScene() {
        Entity cam = make(world, "cam");
        world.add<Camera>(cam).clearColor = Color{0.2f, 0.2f, 0.2f, 1.0f};
        Entity e = make(world, "box", {0, 0, 0});
        auto& sh = world.add<Shape2D>(e);
        sh.shape = ShapeType::Rectangle;
        sh.size = {40, 40};
        sh.color = Color{1, 0, 0, 1};
    }
};

// The start-up report numbers of a renderer (the public view of the cache).
struct CacheNumbers {
    int pipelines, hits, made, evicted;
};
CacheNumbers numbers(const Renderer& r) {
    const Json j = r.startup_report();
    return {j["pipelines"].get<int>(), j["pipelineHits"].get<int>(), j["pipelinesMade"].get<int>(),
            j["pipelinesEvicted"].get<int>()};
}

// Shuts the Gpu down at the end of a case, a failed REQUIRE included (sokol_gfx is a singleton: a leaked Gpu would break
// the cases after it).
struct GpuGuard {
    render::Gpu& gpu;
    explicit GpuGuard(render::Gpu& g) : gpu(g) {}
    ~GpuGuard() { gpu.shutdown(); }
    GpuGuard(const GpuGuard&) = delete;
    GpuGuard& operator=(const GpuGuard&) = delete;
};

// The colour formats of the cache cases that can be rendered into: one colour-filter pipeline each, no depth.
std::vector<render::TargetFormat> color_formats() {
    const gpu::PixelFormat colors[] = {gpu::PixelFormat::Rgba8, gpu::PixelFormat::Bgra8, gpu::PixelFormat::Rgb10A2,
                                       gpu::PixelFormat::Rgba16F, gpu::PixelFormat::Rgba32F};
    std::vector<render::TargetFormat> formats;
    for (gpu::PixelFormat c : colors)
        if (sg_query_pixelformat(gpu::to_sg(c)).render) formats.push_back({c, gpu::PixelFormat::None, 1});
    return formats;
}

bool can_render(gpu::PixelFormat f, bool msaa = false) {
    const sg_pixelformat_info i = sg_query_pixelformat(gpu::to_sg(f));
    return i.render && i.blend && (!msaa || i.msaa);
}

}  // namespace

TEST_CASE("pipeline cache: the number of pipelines is the same from one frame to the next") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FlatScene s;
    const CacheNumbers before = numbers(g.renderer);  // the Gfx is shared: the counters hold the cases before this one
    g.render(s.world);                                // makes what the scene needs
    const CacheNumbers first = numbers(g.renderer);
    CHECK(first.pipelines > 0);
    for (int i = 0; i < 5; ++i) g.render(s.world);
    const CacheNumbers later = numbers(g.renderer);
    CHECK(later.pipelines == first.pipelines);
    CHECK(later.made == first.made);             // nothing was made again
    CHECK(later.hits - first.hits >= 5);         // every frame's draws found their pipeline
    CHECK(later.evicted - before.evicted == 0);  // nothing of this scene was evicted
}

TEST_CASE("pipeline cache: an RGBA8 and an RGBA16F target draw in one process with nothing flushed") {
    gfx();                                         // the sokol context
    if (!can_render(gpu::PixelFormat::Rgba16F)) {  // a GPU without float targets has no second format to compare
        MESSAGE("RGBA16F cannot be rendered into with blending on this GPU: the two-format comparison is skipped");
        CHECK(can_render(gpu::PixelFormat::Rgba8));  // at least the first format is there
        return;
    }
    render::Gpu gpu;
    GpuGuard guard(gpu);
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    const render::TargetFormat f8{gpu::PixelFormat::Rgba8, gpu::PixelFormat::DepthStencil, 1};
    const render::TargetFormat f16{gpu::PixelFormat::Rgba16F, gpu::PixelFormat::DepthStencil, 1};
    gpu::Pipeline q8 = gpu.quad_pipeline(f8, false, false);
    CHECK(gpu.device().state(q8) == gpu::ResourceState::Valid);
    const std::size_t one = gpu.pipeline_count();
    gpu::Pipeline q16 = gpu.quad_pipeline(f16, false, false);
    CHECK(gpu.device().state(q16) == gpu::ResourceState::Valid);
    CHECK(q16.id != q8.id);
    CHECK(gpu.pipeline_count() == one + 1);
    // Both are still there, the first one is the same object, and the wrapper picks the scene format.
    CHECK(gpu.quad_pipeline(f8, false, false).id == q8.id);
    CHECK(gpu.quad_pipeline(f16, false, false).id == q16.id);
    CHECK(gpu.pipeline_count() == one + 1);
    gpu.set_scene_pick(0);  // the chain of a gamma scene starts with RGBA16F here
    CHECK(gpu.quad_pipeline(false, false).id == q16.id);
    REQUIRE(gpu.next_scene_format());  // the fall-back to RGBA8: a new key, not a flush
    CHECK(gpu.scene_format() == gpu::PixelFormat::Rgba8);
    CHECK(gpu.quad_pipeline(false, false).id == q8.id);
    CHECK(gpu.pipeline_count() == one + 1);
    CHECK(gpu.device().state(q16) == gpu::ResourceState::Valid);
}

TEST_CASE("pipeline cache: sample counts 1 and 4 live in one cache") {
    gfx();
    if (!can_render(gpu::PixelFormat::Rgba8, true)) {
        MESSAGE("RGBA8 cannot be multisampled on this GPU: the sample-count comparison is skipped");
        CHECK(can_render(gpu::PixelFormat::Rgba8));
        return;
    }
    render::Gpu gpu;
    GpuGuard guard(gpu);
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    const render::TargetFormat one{gpu::PixelFormat::Rgba8, gpu::PixelFormat::DepthStencil, 1};
    const render::TargetFormat four{gpu::PixelFormat::Rgba8, gpu::PixelFormat::DepthStencil, 4};
    gpu::Pipeline m1 = gpu.mesh_pipeline(one, false, false);
    gpu::Pipeline m4 = gpu.mesh_pipeline(four, false, false);
    CHECK(gpu.device().state(m1) == gpu::ResourceState::Valid);
    CHECK(gpu.device().state(m4) == gpu::ResourceState::Valid);
    CHECK(m1.id != m4.id);
    CHECK(gpu.mesh_pipeline(one, false, false).id == m1.id);
    CHECK(gpu.mesh_pipeline(four, false, false).id == m4.id);
    // The bloom stages do the same without a depth attachment.
    if (gpu.bloom_ready()) {
        const render::TargetFormat b1{gpu::PixelFormat::Rgba8, gpu::PixelFormat::None, 1};
        const render::TargetFormat b4{gpu::PixelFormat::Rgba8, gpu::PixelFormat::None, 4};
        CHECK(gpu.bloom_pipeline(render::BloomStage::Composite, b1).id !=
              gpu.bloom_pipeline(render::BloomStage::Composite, b4).id);
    }
}

TEST_CASE("pipeline cache: a pipeline idle for too long is destroyed once the cache is over its cap") {
    gfx();
    render::Gpu gpu;
    GpuGuard guard(gpu);
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    CHECK(gpu.pipeline_cache_cap() == 192);
    CHECK(gpu.pipeline_idle_frames() == 300);
    // One colour-filter pipeline per colour format that can be rendered into (none of them is drawn with).
    const std::vector<render::TargetFormat> formats = color_formats();
    REQUIRE(formats.size() >= 2);                          // eviction needs one pipeline to keep and one to lose
    gpu.set_pipeline_cache_limits(formats.size() - 1, 4);  // the cap is under what is made, whatever the GPU supports
    const render::TargetFormat keep = formats[0];
    gpu::Pipeline kept = gpu.colorfilter_pipeline(keep);
    for (std::size_t i = 1; i < formats.size(); ++i) gpu.colorfilter_pipeline(formats[i]);
    const std::size_t made = gpu.pipeline_count();
    REQUIRE(made == formats.size());
    CHECK(gpu.pipelines_evicted() == 0);
    // 40 frames that ask only for `keep`: the others go idle, the sweep (every 16 frames) destroys them.
    for (int i = 0; i < 40; ++i) {
        gpu.begin_frame();
        CHECK(gpu.colorfilter_pipeline(keep).id == kept.id);
        gpu.note_commit();
    }
    CHECK(gpu.pipeline_count() == 1);
    CHECK(gpu.pipelines_evicted() == formats.size() - 1);
    CHECK(gpu.colorfilter_pipeline(keep).id == kept.id);  // one in use is never destroyed
    // An evicted one is made again when it is asked for.
    const std::uint64_t madeBefore = gpu.pipelines_made();
    CHECK(gpu.device().state(gpu.colorfilter_pipeline(formats[1])) == gpu::ResourceState::Valid);
    CHECK(gpu.pipelines_made() == madeBefore + 1);
}

TEST_CASE("pipeline cache: a pipeline made by the warm-up is never evicted, an idle one made later is") {
    gfx();
    render::Gpu gpu;
    GpuGuard guard(gpu);
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    const std::vector<render::TargetFormat> formats = color_formats();
    if (formats.size() < 3) {  // the one in use, the warmed one and the one that goes
        MESSAGE("skipped: fewer than 3 renderable colour formats");
        return;
    }
    gpu.set_pipeline_cache_limits(1, 4);
    const gpu::Pipeline used = gpu.colorfilter_pipeline(formats[0]);
    gpu.set_warming(true);
    const gpu::Pipeline warmed = gpu.colorfilter_pipeline(formats[1]);
    gpu.set_warming(false);
    gpu.colorfilter_pipeline(formats[2]);
    for (int i = 0; i < 40; ++i) {
        gpu.begin_frame();
        gpu.colorfilter_pipeline(formats[0]);
        gpu.note_commit();
    }
    CHECK(gpu.pipeline_count() == 2);  // the one in use and the warmed one
    CHECK(gpu.pipelines_evicted() == 1);
    const std::uint64_t madeBefore = gpu.pipelines_made();
    CHECK(gpu.colorfilter_pipeline(formats[1]).id == warmed.id);  // still there: nothing is made again
    CHECK(gpu.colorfilter_pipeline(formats[0]).id == used.id);
    CHECK(gpu.pipelines_made() == madeBefore);
}

TEST_CASE("pipeline cache: the RGBA8 fall-back renders and keeps its pipelines from frame to frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    EnvGuard hook("FA_SCENE_FORMAT", "rgba16f_invalid");
    Renderer fallback;
    RendererDesc d;
    d.designWidth = 320;
    d.designHeight = 180;
    d.sampleCount = std::getenv("FA_TEST_SAMPLES") ? std::atoi(std::getenv("FA_TEST_SAMPLES")) : 1;
    d.headless = true;
    d.adoptContext = true;
    std::string error;
    REQUIRE_MESSAGE(fallback.init(d, g.gpu.environment(), &error), error);
    FlatScene s;
    Image img;
    for (int i = 0; i < 3; ++i) {
        fallback.begin_frame();
        fallback.render_world(s.world, 0.0f);
        fallback.end_frame();
        g.gpu.end_frame();
        REQUIRE_MESSAGE(fallback.capture(img, &error), error);
    }
    CHECK_FALSE(fallback.hdr_scene());
    CHECK(img.pixel(160, 90).r > 0.9f);  // the red box
    const CacheNumbers n1 = numbers(fallback);
    fallback.begin_frame();
    fallback.render_world(s.world, 0.0f);
    fallback.end_frame();
    g.gpu.end_frame();
    const CacheNumbers n2 = numbers(fallback);
    CHECK(n2.made == n1.made);
    CHECK(n2.pipelines == n1.pipelines);
    CHECK(n2.evicted == 0);
    fallback.shutdown();
}
