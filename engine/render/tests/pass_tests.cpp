// Passes and targets: PassDesc maps every field to the sg_pass sokol gets (the swapchain case included), a window pass
// takes its formats from the environment, Gpu::begin_pass records the format pipelines are checked against, and
// make_target makes (and destroy_target frees) one description's images and views, MSAA resolve and depth included.
#include "test_util.h"

#include <string>

#include "gpu_types.h"
#include "render_internal.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("pass desc: to_sg maps the views, the actions and the label") {
    render::PassDesc d;
    d.label = "unit";
    d.color = sg_view{11};
    d.resolve = sg_view{12};
    d.depth = sg_view{13};
    d.colorLoad = SG_LOADACTION_CLEAR;
    d.colorStore = SG_STOREACTION_DONTCARE;
    d.clearColor = {0.25f, 0.5f, 0.75f, 1.0f};
    d.depthLoad = SG_LOADACTION_CLEAR;
    d.clearDepth = 0.5f;
    d.stencilLoad = SG_LOADACTION_LOAD;
    const sg_pass p = d.to_sg();
    CHECK(std::string(p.label) == "unit");
    CHECK(p.attachments.colors[0].id == 11);
    CHECK(p.attachments.resolves[0].id == 12);
    CHECK(p.attachments.depth_stencil.id == 13);
    CHECK(p.action.colors[0].load_action == SG_LOADACTION_CLEAR);
    CHECK(p.action.colors[0].store_action == SG_STOREACTION_DONTCARE);
    CHECK(p.action.colors[0].clear_value.r == doctest::Approx(0.25f));
    CHECK(p.action.colors[0].clear_value.g == doctest::Approx(0.5f));
    CHECK(p.action.colors[0].clear_value.b == doctest::Approx(0.75f));
    CHECK(p.action.colors[0].clear_value.a == doctest::Approx(1.0f));
    CHECK(p.action.depth.load_action == SG_LOADACTION_CLEAR);
    CHECK(p.action.depth.clear_value == doctest::Approx(0.5f));
    CHECK(p.action.stencil.load_action == SG_LOADACTION_LOAD);
    CHECK(p.swapchain.sample_count == 0);  // not a window pass
}

TEST_CASE("pass desc: the defaults are DONTCARE, not sokol's clear") {
    const sg_pass p = render::PassDesc{}.to_sg();
    CHECK(p.action.colors[0].load_action == SG_LOADACTION_DONTCARE);
    CHECK(p.action.colors[0].store_action == SG_STOREACTION_STORE);
    CHECK(p.action.depth.load_action == SG_LOADACTION_DONTCARE);
    CHECK(p.action.stencil.load_action == SG_LOADACTION_DONTCARE);
}

TEST_CASE("pass desc: a swapchain pass copies the swapchain and ignores the views") {
    sg_swapchain sc{};
    sc.width = 640;
    sc.height = 480;
    sc.sample_count = 4;
    sc.color_format = SG_PIXELFORMAT_BGRA8;
    sc.depth_format = SG_PIXELFORMAT_DEPTH_STENCIL;
    render::PassDesc d = render::PassDesc::for_swapchain(sc, sg_environment_defaults{});
    d.color = sg_view{5};  // ignored with a swapchain
    d.colorLoad = SG_LOADACTION_CLEAR;
    d.clearColor = {0, 0, 0, 1};
    const sg_pass p = d.to_sg();
    CHECK(p.swapchain.width == 640);
    CHECK(p.swapchain.height == 480);
    CHECK(p.swapchain.sample_count == 4);
    CHECK(p.swapchain.color_format == SG_PIXELFORMAT_BGRA8);
    CHECK(p.swapchain.depth_format == SG_PIXELFORMAT_DEPTH_STENCIL);
    CHECK(p.attachments.colors[0].id == 0);
    CHECK(p.action.colors[0].load_action == SG_LOADACTION_CLEAR);
    CHECK(d.format == render::TargetFormat{SG_PIXELFORMAT_BGRA8, SG_PIXELFORMAT_DEPTH_STENCIL, 4});
}

TEST_CASE("pass desc: a swapchain with unset formats takes the environment's defaults, as sokol does") {
    sg_swapchain sc{};  // colour format, depth format and sample count left at 0
    sg_environment_defaults env{};
    env.color_format = SG_PIXELFORMAT_RGBA8;
    env.depth_format = SG_PIXELFORMAT_DEPTH;
    env.sample_count = 2;
    const render::PassDesc d = render::PassDesc::for_swapchain(sc, env);
    CHECK(d.format == render::TargetFormat{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_DEPTH, 2});
    CHECK(d.swapchain == &sc);
    // What the swapchain sets itself wins.
    sc.color_format = SG_PIXELFORMAT_BGRA8;
    sc.sample_count = 1;
    const render::PassDesc e = render::PassDesc::for_swapchain(sc, env);
    CHECK(e.format == render::TargetFormat{SG_PIXELFORMAT_BGRA8, SG_PIXELFORMAT_DEPTH, 1});
    // No environment at all: one sample, formats as given.
    const render::PassDesc f = render::PassDesc::for_swapchain(sg_swapchain{}, sg_environment_defaults{});
    CHECK(f.format.samples == 1);
}

TEST_CASE("target: make_target makes the images and views of one description and destroy_target frees them") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    render::Gpu gpu;
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    fa::gpu::Device& device = gpu.device();
    render::TargetDesc d;
    d.label = "unit";
    d.width = 32;
    d.height = 16;
    d.colorFormat = SG_PIXELFORMAT_RGBA8;
    d.depthFormat = SG_PIXELFORMAT_DEPTH_STENCIL;
    render::Target t = render::make_target(device, d);
    CHECK(t.valid(device));
    CHECK(t.color.id != 0);
    CHECK(t.resolve.id == 0);  // not multisampled
    CHECK(t.depth.id != 0);
    CHECK(t.colorAtt.id != 0);
    CHECK(t.depthAtt.id != 0);
    CHECK(t.texView.id != 0);
    CHECK(t.texture_image().id == t.color.id);
    CHECK(t.format == render::TargetFormat{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_DEPTH_STENCIL, 1});
    const render::PassDesc p = render::pass_into(t, "unit");
    CHECK(p.color.id == t.colorAtt.id);
    CHECK(p.depth.id == t.depthAtt.id);
    CHECK(p.resolve.id == 0);
    CHECK(p.format == t.format);
    render::destroy_target(t);
    CHECK(t.color.id == 0);
    CHECK(t.texView.id == 0);
    CHECK(!t.valid(device));
    gpu.shutdown();
    render::destroy_target(t);  // twice is harmless, and an empty target needs no device
}

TEST_CASE("target: a target without a texture view is a draw-and-read-back image") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    render::Gpu gpu;
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    fa::gpu::Device& device = gpu.device();
    render::TargetDesc d;
    d.label = "unit-readback";
    d.width = 8;
    d.height = 8;
    d.colorFormat = SG_PIXELFORMAT_RGBA8;
    d.texture = false;
    render::Target t = render::make_target(device, d);
    CHECK(t.valid(device));
    CHECK(t.texView.id == 0);
    CHECK(t.depth.id == 0);
    render::destroy_target(device, t);
    gpu.shutdown();
}

TEST_CASE("target: a multisampled target resolves into a single-sample image the texture view samples") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    render::Gpu gpu;
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    fa::gpu::Device& device = gpu.device();
    const sg_pixelformat_info info = sg_query_pixelformat(SG_PIXELFORMAT_RGBA8);
    const sg_pixelformat_info depthInfo = sg_query_pixelformat(SG_PIXELFORMAT_DEPTH_STENCIL);
    if (!info.render || !info.msaa || !depthInfo.msaa) {  // e.g. Mesa llvmpipe, D3D11 WARP
        MESSAGE("this GPU cannot multisample RGBA8 and depth-stencil: the resolve case is skipped");
        CHECK(sg_query_pixelformat(SG_PIXELFORMAT_RGBA8).render);
        gpu.shutdown();
        return;
    }
    render::TargetDesc d;
    d.label = "unit-msaa";
    d.width = 16;
    d.height = 16;
    d.colorFormat = SG_PIXELFORMAT_RGBA8;
    d.samples = 4;
    d.resolveAsColor = true;
    d.depthFormat = SG_PIXELFORMAT_DEPTH_STENCIL;
    render::Target t = render::make_target(device, d);
    REQUIRE(t.valid(device));
    CHECK(t.resolve.id != 0);
    CHECK(t.resolveAtt.id != 0);
    CHECK(t.resolveColorAtt.id != 0);
    CHECK(t.texture_image().id == t.resolve.id);
    const render::PassDesc p = render::pass_into(t, "unit-msaa");
    CHECK(p.resolve.id == t.resolveAtt.id);
    CHECK(p.format.samples == 4);
    render::destroy_target(device, t);
    gpu.shutdown();
}

TEST_CASE("gpu: begin_pass records the pass format and end_pass forgets it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    render::Gpu gpu;
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    render::TargetDesc d;
    d.label = "unit-pass";
    d.width = 8;
    d.height = 8;
    d.colorFormat = gpu.scene_format();
    d.depthFormat = render::kSceneDepthFormat;
    render::Target t = render::make_target(d);
    REQUIRE(t.valid());
    CHECK(!render::Gpu::in_pass());
    render::PassDesc p = render::pass_into(t, "unit-pass");
    p.colorLoad = SG_LOADACTION_CLEAR;
    p.depthLoad = SG_LOADACTION_CLEAR;
    p.stencilLoad = SG_LOADACTION_CLEAR;
    gpu.begin_pass(p);
    CHECK(render::Gpu::in_pass());
    CHECK(render::Gpu::pass_format() == gpu.scene_target_format());
    // A pipeline for the pass's own format is fine.
    CHECK(sg_query_pipeline_state(gpu.quad_pipeline(false, false)) == SG_RESOURCESTATE_VALID);
    gpu.end_pass();
    CHECK(!render::Gpu::in_pass());
    // Outside a pass any format may be asked for (the warm-up does).
    const render::TargetFormat other{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_NONE, 1};
    CHECK(sg_query_pipeline_state(gpu.blit_pipeline(other)) == SG_RESOURCESTATE_VALID);
    sg_commit();
    render::destroy_target(t);
    gpu.shutdown();
}

TEST_CASE("gpu: active() is the Gpu initialised last of those alive, and the free target helpers use its device") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    std::string error;
    render::Gpu* const before = render::Gpu::active();  // a renderer another test left alive, or none
    render::Gpu first;
    REQUIRE_MESSAGE(first.init(1, &error), error);
    CHECK(render::Gpu::active() == &first);
    {
        render::Gpu second;
        REQUIRE_MESSAGE(second.init(1, &error), error);
        CHECK(render::Gpu::active() == &second);
        CHECK(&render::Gpu::active_device() == &second.device());
        second.shutdown();
        CHECK(render::Gpu::active() == &first);  // the one before is active again, not none
        REQUIRE_MESSAGE(second.init(1, &error), error);
        CHECK(render::Gpu::active() == &second);
        second.shutdown();
    }
    CHECK(render::Gpu::active() == &first);
    render::TargetDesc d;
    d.label = "unit-active";
    d.width = d.height = 4;
    d.colorFormat = SG_PIXELFORMAT_RGBA8;
    render::Target t = render::make_target(d);
    CHECK(t.valid());
    CHECK(t.valid(first.device()));
    CHECK(first.device().state(fa::gpu::from_sg(t.color)) == fa::gpu::ResourceState::Valid);
    render::destroy_target(t);
    CHECK(t.color.id == 0);
    first.shutdown();
    CHECK(render::Gpu::active() == before);
}
