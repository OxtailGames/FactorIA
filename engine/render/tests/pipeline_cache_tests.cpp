// The pipeline cache of Gpu: pipelines are keyed by the format of the pass they draw into (TargetFormat), so a change of
// format or sample count makes new entries and flushes nothing, and the cache is bounded by use.
#include "test_util.h"

#include <string>
#include <vector>

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

// Sets an environment variable for the life of the object.
struct EnvGuard {
    std::string name, old;
    bool had = false;
    EnvGuard(const char* n, const char* value) : name(n) {
        if (const char* cur = std::getenv(n)) {
            had = true;
            old = cur;
        }
        set(value);
    }
    ~EnvGuard() { set(had ? old.c_str() : nullptr); }
    void set(const char* value) const {
#if defined(_WIN32)
        _putenv_s(name.c_str(), value ? value : "");  // an empty value removes the variable
#else
        if (value)
            setenv(name.c_str(), value, 1);
        else
            unsetenv(name.c_str());
#endif
    }
};

bool can_render(sg_pixel_format f, bool msaa = false) {
    const sg_pixelformat_info i = sg_query_pixelformat(f);
    return i.render && i.blend && (!msaa || i.msaa);
}

}  // namespace

TEST_CASE("pipeline cache: the number of pipelines is the same from one frame to the next") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FlatScene s;
    g.render(s.world);  // makes what the scene needs
    const CacheNumbers first = numbers(g.renderer);
    CHECK(first.pipelines > 0);
    for (int i = 0; i < 5; ++i) g.render(s.world);
    const CacheNumbers later = numbers(g.renderer);
    CHECK(later.pipelines == first.pipelines);
    CHECK(later.made == first.made);  // nothing was made again
    CHECK(later.hits > first.hits);   // every draw found its pipeline
    CHECK(later.evicted == 0);
}

TEST_CASE("pipeline cache: an RGBA8 and an RGBA16F target draw in one process with nothing flushed") {
    gfx();  // the sokol context
    if (!can_render(SG_PIXELFORMAT_RGBA16F)) return;  // a GPU without float targets has no second format to compare
    render::Gpu gpu;
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    const render::TargetFormat f8{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_DEPTH_STENCIL, 1};
    const render::TargetFormat f16{SG_PIXELFORMAT_RGBA16F, SG_PIXELFORMAT_DEPTH_STENCIL, 1};
    sg_pipeline q8 = gpu.quad_pipeline(f8, false, false);
    CHECK(sg_query_pipeline_state(q8) == SG_RESOURCESTATE_VALID);
    const std::size_t one = gpu.pipeline_count();
    sg_pipeline q16 = gpu.quad_pipeline(f16, false, false);
    CHECK(sg_query_pipeline_state(q16) == SG_RESOURCESTATE_VALID);
    CHECK(q16.id != q8.id);
    CHECK(gpu.pipeline_count() == one + 1);
    // Both are still there, the first one is the same object, and the wrapper picks the scene format.
    CHECK(gpu.quad_pipeline(f8, false, false).id == q8.id);
    CHECK(gpu.quad_pipeline(f16, false, false).id == q16.id);
    CHECK(gpu.pipeline_count() == one + 1);
    gpu.set_scene_format(SG_PIXELFORMAT_RGBA16F);
    CHECK(gpu.quad_pipeline(false, false).id == q16.id);
    gpu.set_scene_format(SG_PIXELFORMAT_RGBA8);  // the fall-back: a new key, not a flush
    CHECK(gpu.quad_pipeline(false, false).id == q8.id);
    CHECK(gpu.pipeline_count() == one + 1);
    CHECK(sg_query_pipeline_state(q16) == SG_RESOURCESTATE_VALID);
    gpu.shutdown();
}

TEST_CASE("pipeline cache: sample counts 1 and 4 live in one cache") {
    gfx();
    if (!can_render(SG_PIXELFORMAT_RGBA8, true)) return;
    render::Gpu gpu;
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    const render::TargetFormat one{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_DEPTH_STENCIL, 1};
    const render::TargetFormat four{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_DEPTH_STENCIL, 4};
    sg_pipeline m1 = gpu.mesh_pipeline(one, false, false);
    sg_pipeline m4 = gpu.mesh_pipeline(four, false, false);
    CHECK(sg_query_pipeline_state(m1) == SG_RESOURCESTATE_VALID);
    CHECK(sg_query_pipeline_state(m4) == SG_RESOURCESTATE_VALID);
    CHECK(m1.id != m4.id);
    CHECK(gpu.mesh_pipeline(one, false, false).id == m1.id);
    CHECK(gpu.mesh_pipeline(four, false, false).id == m4.id);
    // The bloom stages do the same without a depth attachment.
    if (gpu.bloom_ready()) {
        const render::TargetFormat b1{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_NONE, 1};
        const render::TargetFormat b4{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_NONE, 4};
        CHECK(gpu.bloom_pipeline(render::BloomStage::Composite, b1).id !=
              gpu.bloom_pipeline(render::BloomStage::Composite, b4).id);
    }
    gpu.shutdown();
}

TEST_CASE("pipeline cache: a pipeline idle for too long is destroyed once the cache is over its cap") {
    gfx();
    render::Gpu gpu;
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    CHECK(gpu.pipeline_cache_cap() == 192);
    CHECK(gpu.pipeline_idle_frames() == 300);
    gpu.set_pipeline_cache_limits(3, 4);
    // One colour-filter pipeline per colour format that can be rendered into (none of them is drawn with).
    const sg_pixel_format colors[] = {SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_BGRA8, SG_PIXELFORMAT_RGB10A2,
                                      SG_PIXELFORMAT_RGBA16F, SG_PIXELFORMAT_RGBA32F};
    std::vector<render::TargetFormat> formats;
    for (sg_pixel_format c : colors)
        if (sg_query_pixelformat(c).render) formats.push_back({c, SG_PIXELFORMAT_NONE, 1});
    REQUIRE(formats.size() >= 3);
    const render::TargetFormat keep = formats[0];
    sg_pipeline kept = gpu.colorfilter_pipeline(keep);
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
    CHECK(sg_query_pipeline_state(gpu.colorfilter_pipeline(formats[1])) == SG_RESOURCESTATE_VALID);
    CHECK(gpu.pipelines_made() == madeBefore + 1);
    gpu.shutdown();
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
