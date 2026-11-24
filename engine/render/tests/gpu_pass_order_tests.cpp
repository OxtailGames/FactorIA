// The order of the calls of passes the renderer records on the frame's command list (Gpu::commands()), read from a
// RecordingDevice: the fog's draw inside the caller's pass and the six faces of the environment's sky. The pictures they
// draw are in fog_shafts_tests.cpp and env_sh_tests.cpp. A RecordingDevice also checks every call against the rules of a real
// device, so a pass that recorded something it should not shows in errors().
#include "test_util.h"

#include <memory>
#include <string>
#include <vector>

#include "gpu/recording_device.h"
#include "render_internal.h"
#include "renderer_env.h"
#include "renderer_fog.h"

using namespace fa;
using namespace fa::test;

namespace {

// A Gpu on a RecordingDevice. The built-in programs come from the generated descs of the open sokol context (the fixture's).
struct RecordedGpu {
    render::Gpu gpu;
    gpu::RecordingDevice* dev = nullptr;
    bool ok = false;
    std::string error;
    RecordedGpu() {
        auto rec = std::make_unique<gpu::RecordingDevice>();
        dev = rec.get();
        ok = gpu.init(1, &error, std::move(rec));
    }
    ~RecordedGpu() { gpu.shutdown(); }
    // What the frame recorded so far (the frame's list is submitted), without the commits.
    std::vector<gpu::RecordedCommand> frame() {
        gpu.commit_frame();
        std::vector<gpu::RecordedCommand> out;
        for (const gpu::RecordedCommand& c : dev->commands())
            if (c.kind != gpu::CommandKind::Commit) out.push_back(c);
        return out;
    }
};

std::string joined(const std::vector<std::string>& lines) {
    std::string out;
    for (const std::string& l : lines) out += l + "\n";
    return out;
}

std::vector<gpu::CommandKind> kinds_of(const std::vector<gpu::RecordedCommand>& commands) {
    std::vector<gpu::CommandKind> kinds;
    for (const gpu::RecordedCommand& c : commands) kinds.push_back(c.kind);
    return kinds;
}

}  // namespace

TEST_CASE("fog: draw_fog records one full-screen triangle inside the caller's pass, in a fixed order") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RecordedGpu rg;
    REQUIRE_MESSAGE(rg.ok, rg.error);
    gpu::Device& device = rg.gpu.device();

    gpu::ImageDesc target;
    target.width = target.height = 32;
    target.usage.colorAttachment = true;
    target.pixelFormat = gpu::PixelFormat::Rgba8;
    target.label = "fog target";
    const gpu::Image targetImage = device.make_image(target);
    gpu::ImageDesc prepass = target;
    prepass.pixelFormat = gpu::PixelFormat::Rgba16F;
    prepass.label = "fog prepass";
    const gpu::Image prepassImage = device.make_image(prepass);
    gpu::ViewDesc att;
    att.colorAttachment.image = targetImage;
    att.label = "fog target color";
    const gpu::View targetView = device.make_view(att);
    gpu::ViewDesc tex;
    tex.texture.image = prepassImage;
    tex.label = "fog prepass tex";
    const gpu::View prepassTex = device.make_view(tex);

    gpu::PassDesc pass;
    pass.label = "main";
    pass.color = targetView;
    pass.format = gpu::TargetFormat{gpu::PixelFormat::Rgba8, gpu::PixelFormat::None, 1};
    pass.colorLoad = gpu::LoadAction::Clear;

    render::FogFx fx;
    render::FogFxPlan plan;
    plan.fog = true;
    plan.density = 0.02f;
    CHECK_FALSE(fx.draw_fog(rg.gpu, plan, gpu::View{}, pass.format));  // no prepass: nothing is recorded

    gpu::CommandList& list = rg.gpu.commands();
    list.begin_pass(pass);
    CHECK(fx.draw_fog(rg.gpu, plan, prepassTex, pass.format));
    list.end_pass();

    const std::vector<gpu::RecordedCommand> frame = rg.frame();
    INFO(joined(rg.dev->errors()));
    CHECK(rg.dev->errors().empty());
    using K = gpu::CommandKind;
    const std::vector<K> expected = {K::BeginPass,   K::SetPipeline, K::SetBindings, K::SetUniforms,
                                     K::SetUniforms, K::Draw,        K::EndPass};
    CHECK(kinds_of(frame) == expected);
    REQUIRE(frame.size() == expected.size());
    CHECK(frame[5].args[0] == 0);  // draw(0, 3, 1): the full-screen triangle
    CHECK(frame[5].args[1] == 3);
    CHECK(frame[5].args[2] == 1);
    fx.release();
    device.destroy_view(targetView);
    device.destroy_view(prepassTex);
    device.destroy_image(targetImage);
    device.destroy_image(prepassImage);
}

TEST_CASE("environment: a bake begins the sky's six cube faces first, one pass each, with the sky drawn inside") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RecordedGpu rg;
    REQUIRE_MESSAGE(rg.ok, rg.error);
    render::Environment env;
    REQUIRE(env.ready(rg.gpu));

    int calls = 0;
    bool allInPass = true;
    int drawCalls = 0;
    env.bake(
        rg.gpu, 1,
        [&](const float*, const gpu::TargetFormat&) {
            ++calls;
            allInPass = allInPass && rg.gpu.commands().pass_state() == gpu::PassState::Render;
        },
        &drawCalls);
    CHECK(env.baked());
    CHECK(calls == 6);
    CHECK(allInPass);

    const std::vector<gpu::RecordedCommand> frame = rg.frame();
    INFO(joined(rg.dev->errors()));
    CHECK(rg.dev->errors().empty());
    // The first twelve commands are the six faces: begin_pass "env-sky", the sky's own calls (none here), end_pass.
    REQUIRE(frame.size() > 12);
    for (int f = 0; f < 6; ++f) {
        CHECK(frame[std::size_t(2 * f)].kind == gpu::CommandKind::BeginPass);
        CHECK(frame[std::size_t(2 * f)].text.find("env-sky") != std::string::npos);
        CHECK(frame[std::size_t(2 * f + 1)].kind == gpu::CommandKind::EndPass);
    }
    // Every pass of the bake is one begin and one end (60 passes: kEnvPasses).
    int begins = 0, ends = 0;
    for (const gpu::RecordedCommand& c : frame) {
        begins += c.kind == gpu::CommandKind::BeginPass ? 1 : 0;
        ends += c.kind == gpu::CommandKind::EndPass ? 1 : 0;
    }
    CHECK(begins == render::kEnvPasses);
    CHECK(ends == render::kEnvPasses);
    env.release();
}
