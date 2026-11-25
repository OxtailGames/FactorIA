// Passes and targets: PassDesc maps every field to the sg_pass sokol gets (the swapchain case included), a window pass
// takes its formats from the environment, a pass on the Gpu's frame list takes the pipelines of its format, and
// make_target makes (and destroy_target frees) one description's images and views, MSAA resolve and depth included.
#include "test_util.h"

#include <string>

#include "gpu/sokol_device.h"
#include "render_internal.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("pass desc: to_sg maps the views, the actions and the label") {
    gpu::PassDesc d;
    d.label = "unit";
    d.color = gpu::View{11};
    d.resolve = gpu::View{12};
    d.depth = gpu::View{13};
    d.colorLoad = gpu::LoadAction::Clear;
    d.colorStore = gpu::StoreAction::DontCare;
    d.clearColor = {0.25f, 0.5f, 0.75f, 1.0f};
    d.depthLoad = gpu::LoadAction::Clear;
    d.clearDepth = 0.5f;
    d.stencilLoad = gpu::LoadAction::Load;
    const sg_pass p = gpu::to_sg(d);
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
    const sg_pass p = gpu::to_sg(gpu::PassDesc{});
    CHECK(p.action.colors[0].load_action == SG_LOADACTION_DONTCARE);
    CHECK(p.action.colors[0].store_action == SG_STOREACTION_STORE);
    CHECK(p.action.depth.load_action == SG_LOADACTION_DONTCARE);
    CHECK(p.action.stencil.load_action == SG_LOADACTION_DONTCARE);
}

TEST_CASE("pass desc: a swapchain pass copies the swapchain and ignores the views") {
    gpu::Swapchain sc;
    sc.width = 640;
    sc.height = 480;
    sc.sampleCount = 4;
    sc.colorFormat = gpu::PixelFormat::Bgra8;
    sc.depthFormat = gpu::PixelFormat::DepthStencil;
    gpu::PassDesc d = gpu::PassDesc::for_swapchain(sc, gpu::EnvironmentDefaults{});
    d.color = gpu::View{5};  // ignored with a swapchain
    d.colorLoad = gpu::LoadAction::Clear;
    d.clearColor = {0, 0, 0, 1};
    const sg_pass p = gpu::to_sg(d);
    CHECK(p.swapchain.width == 640);
    CHECK(p.swapchain.height == 480);
    CHECK(p.swapchain.sample_count == 4);
    CHECK(p.swapchain.color_format == SG_PIXELFORMAT_BGRA8);
    CHECK(p.swapchain.depth_format == SG_PIXELFORMAT_DEPTH_STENCIL);
    CHECK(p.attachments.colors[0].id == 0);
    CHECK(p.action.colors[0].load_action == SG_LOADACTION_CLEAR);
    CHECK(d.format == gpu::TargetFormat{gpu::PixelFormat::Bgra8, gpu::PixelFormat::DepthStencil, 4});
}

TEST_CASE("pass desc: a swapchain with unset formats takes the environment's defaults, as sokol does") {
    gpu::Swapchain sc;  // colour format, depth format and sample count left at 0
    gpu::EnvironmentDefaults env;
    env.colorFormat = gpu::PixelFormat::Rgba8;
    env.depthFormat = gpu::PixelFormat::Depth;
    env.sampleCount = 2;
    const gpu::PassDesc d = gpu::PassDesc::for_swapchain(sc, env);
    CHECK(d.format == gpu::TargetFormat{gpu::PixelFormat::Rgba8, gpu::PixelFormat::Depth, 2});
    CHECK(d.swapchain == &sc);
    // What the swapchain sets itself wins.
    sc.colorFormat = gpu::PixelFormat::Bgra8;
    sc.sampleCount = 1;
    const gpu::PassDesc e = gpu::PassDesc::for_swapchain(sc, env);
    CHECK(e.format == gpu::TargetFormat{gpu::PixelFormat::Bgra8, gpu::PixelFormat::Depth, 1});
    // No environment at all: one sample, formats as given.
    const gpu::Swapchain unset;
    const gpu::PassDesc f = gpu::PassDesc::for_swapchain(unset, gpu::EnvironmentDefaults{});
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
    d.colorFormat = gpu::PixelFormat::Rgba8;
    d.depthFormat = gpu::PixelFormat::DepthStencil;
    render::Target t = render::make_target(device, d);
    CHECK(t.valid(device));
    CHECK(t.color.id != 0);
    CHECK(t.resolve.id == 0);  // not multisampled
    CHECK(t.depth.id != 0);
    CHECK(t.colorAtt.id != 0);
    CHECK(t.depthAtt.id != 0);
    CHECK(t.texView.id != 0);
    CHECK(t.texture_image().id == t.color.id);
    CHECK(t.format == gpu::TargetFormat{gpu::PixelFormat::Rgba8, gpu::PixelFormat::DepthStencil, 1});
    const gpu::PassDesc p = render::pass_into(t, "unit");
    CHECK(p.color.id == t.colorAtt.id);
    CHECK(p.depth.id == t.depthAtt.id);
    CHECK(p.resolve.id == 0);
    CHECK(p.format == t.format);
    render::destroy_target(device, t);
    CHECK(t.color.id == 0);
    CHECK(t.texView.id == 0);
    CHECK(!t.valid(device));
    render::destroy_target(device, t);  // twice is harmless
    gpu.shutdown();
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
    d.colorFormat = gpu::PixelFormat::Rgba8;
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
    const sg_pixelformat_info info = sg_query_pixelformat(gpu::to_sg(gpu::PixelFormat::Rgba8));
    const sg_pixelformat_info depthInfo = sg_query_pixelformat(gpu::to_sg(gpu::PixelFormat::DepthStencil));
    if (!info.render || !info.msaa || !depthInfo.msaa) {  // e.g. Mesa llvmpipe, D3D11 WARP
        MESSAGE("this GPU cannot multisample RGBA8 and depth-stencil: the resolve case is skipped");
        CHECK(sg_query_pixelformat(gpu::to_sg(gpu::PixelFormat::Rgba8)).render);
        gpu.shutdown();
        return;
    }
    render::TargetDesc d;
    d.label = "unit-msaa";
    d.width = 16;
    d.height = 16;
    d.colorFormat = gpu::PixelFormat::Rgba8;
    d.samples = 4;
    d.resolveAsColor = true;
    d.depthFormat = gpu::PixelFormat::DepthStencil;
    render::Target t = render::make_target(device, d);
    REQUIRE(t.valid(device));
    CHECK(t.resolve.id != 0);
    CHECK(t.resolveAtt.id != 0);
    CHECK(t.resolveColorAtt.id != 0);
    CHECK(t.texture_image().id == t.resolve.id);
    const gpu::PassDesc p = render::pass_into(t, "unit-msaa");
    CHECK(p.resolve.id == t.resolveAtt.id);
    CHECK(p.format.samples == 4);
    render::destroy_target(device, t);
    gpu.shutdown();
}

TEST_CASE("gpu: a pass on the frame list takes the pipelines of its format; in_pass follows the list") {
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
    render::Target t = render::make_target(gpu.device(), d);
    REQUIRE(t.valid(gpu.device()));
    CHECK(!gpu.in_pass());
    gpu::PassDesc p = render::pass_into(t, "unit-pass");
    p.colorLoad = gpu::LoadAction::Clear;
    p.depthLoad = gpu::LoadAction::Clear;
    p.stencilLoad = gpu::LoadAction::Clear;
    CHECK(p.format == gpu.scene_target_format());
    gpu::CommandList& list = gpu.commands();
    list.begin_pass(p);  // a debug build asserts here that p.format is what the attachments are
    CHECK(gpu.in_pass());
    // A pipeline for the pass's own format is fine (a debug build asserts the match in set_pipeline).
    const gpu::Pipeline quad = gpu.quad_pipeline(false, false);
    CHECK(gpu.device().state(quad) == gpu::ResourceState::Valid);
    list.set_pipeline(quad);
    list.end_pass();
    CHECK(!gpu.in_pass());
    // Outside a pass any format may be asked for (the warm-up does).
    const gpu::TargetFormat other{gpu::PixelFormat::Rgba8, gpu::PixelFormat::None, 1};
    CHECK(gpu.device().state(gpu.blit_pipeline(other)) == gpu::ResourceState::Valid);
    gpu.commit_frame();
    render::destroy_target(gpu.device(), t);
    gpu.shutdown();
}

TEST_CASE("gpu: every Gpu has its own device and frame list, and a resource lives on the device that made it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    std::string error;
    render::Gpu first;
    REQUIRE_MESSAGE(first.init(1, &error), error);
    {
        render::Gpu second;
        REQUIRE_MESSAGE(second.init(1, &error), error);
        CHECK(&first.device() != &second.device());
        CHECK(&first.commands() != &second.commands());
        second.shutdown();
        CHECK(!second.has_device());  // the one that stays is not touched
        CHECK(first.has_device());
        REQUIRE_MESSAGE(second.init(1, &error), error);
        CHECK(second.has_device());
        second.shutdown();
    }
    render::TargetDesc d;
    d.label = "unit-own-device";
    d.width = d.height = 4;
    d.colorFormat = gpu::PixelFormat::Rgba8;
    render::Target t = render::make_target(first.device(), d);
    CHECK(t.valid(first.device()));
    CHECK(first.device().state(t.color) == fa::gpu::ResourceState::Valid);
    render::destroy_target(first.device(), t);
    CHECK(t.color.id == 0);
    first.shutdown();
    CHECK(!first.has_device());
}
