// Manual windowed smoke check. Runs only when FA_WINDOWED_SMOKE=1 and a display exists:
//   FA_WINDOWED_SMOKE=1 xvfb-run -a -s "-screen 0 1280x720x24" build/.../fa_test_render -tc="windowed*"
// (sokol_gfx is a process singleton, so this must not share a process with the headless tests.)
#include <doctest.h>

// Desktop OpenGL readback: Linux only (macOS renders with Metal, Windows with D3D11).
#if defined(__linux__)

#include <cstdlib>
#include <cstring>

#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>

#include "fa/core/image.h"
#include "fa/platform/app.h"
#include "fa/render/renderer.h"
#include "fa/scene/world.h"
#include "test_util.h"

using namespace fa;

TEST_CASE("windowed smoke: run_app opens, renders, presents with letterboxing and quits"
          * doctest::skip(std::getenv("FA_WINDOWED_SMOKE") == nullptr)) {
    Renderer renderer;
    World world;
    Input input;
    std::string error;
    int frames = 0;
    Image window, game;
    bool captured = false;

    AppDesc desc;
    desc.title = "FactorIA smoke";
    desc.width = 640;
    desc.height = 480;
    desc.highDpi = false;
    desc.input = &input;
    desc.to_design_coords = [&](Vec2 p) {
        return renderer.framebuffer_to_design(p, app_framebuffer_width(), app_framebuffer_height(), ScaleMode::Fit);
    };
    desc.init = [&] {
        RendererDesc rd;
        rd.designWidth = 320;
        rd.designHeight = 180;
        rd.headless = false;
        REQUIRE_MESSAGE(renderer.init(rd, app_gfx_environment(), &error), error);
        Entity cam = test::make(world, "cam");
        world.add<Camera>(cam).clearColor = Color::hex(0x204060);
        Entity box = test::make(world, "box", {0, 0, 0});
        auto& s = world.add<Shape2D>(box);
        s.size = {100, 60};
        s.color = Color::hex(0xe0a020);
        Entity txt = test::make(world, "txt", {0, -50, 0});
        auto& t = world.add<Text>(txt);
        t.text = "windowed";
        t.pivot = {0.5f, 0.5f};
        t.align = Align::Center;
    };
    desc.frame = [&](double dt) {
        renderer.begin_frame();
        renderer.render_world(world, float(dt));
        renderer.end_frame();
        int fw = app_framebuffer_width(), fh = app_framebuffer_height();
        renderer.present(app_gfx_swapchain(), fw, fh, ScaleMode::Fit);
        if (++frames == 5) {
            // The back buffer still holds the presented image until sokol_app swaps.
            window.width = fw;
            window.height = fh;
            window.rgba.resize(std::size_t(fw) * fh * 4);
            glReadBuffer(GL_BACK);
            glPixelStorei(GL_PACK_ALIGNMENT, 1);
            glReadPixels(0, 0, fw, fh, GL_RGBA, GL_UNSIGNED_BYTE, window.rgba.data());
            window.flip_vertical();
            captured = renderer.capture(game, &error);
            app_request_quit();
        }
    };
    desc.cleanup = [&] { renderer.shutdown(); };

    int rc = run_app(desc);
    CHECK(rc == 0);
    CHECK(frames >= 5);
    REQUIRE(captured);
    CHECK(game.width == 320);
    // 640x480 window, 320x180 target, Fit: scale 2 -> 640x360 centered with 60px black bars top and bottom.
    REQUIRE(window.width == 640);
    REQUIRE(window.height == 480);
    CHECK(window.pixel(320, 20).r == doctest::Approx(0.0f).epsilon(0.02));
    CHECK(window.pixel(320, 460).b == doctest::Approx(0.0f).epsilon(0.02));
    Color inside = window.pixel(10, 70);  // inside the letterboxed game area: clear color 0x204060
    CHECK(inside.b > 0.3f);
    Color box = window.pixel(320, 240 - 40);  // box center region (world y +20 -> window y 200)
    CHECK(box.r > 0.7f);
    test::expect_golden(window, "windowed_letterbox");
}

#endif  // __linux__
