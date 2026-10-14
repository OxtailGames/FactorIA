// Shared fixture for renderer tests: headless GPU + renderer + golden comparison.
#pragma once

#include <doctest.h>

#include <cstdlib>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/platform/app.h"
#include "fa/render/renderer.h"
#include "fa/scene/world.h"

namespace fa::test {

// One GPU + renderer for the whole test binary (sokol_gfx is a singleton).
struct Gfx {
    HeadlessGpu gpu;
    Renderer renderer;
    std::filesystem::path projectDir;
    bool ok = false;
    std::string error;

    Gfx(int w = 320, int h = 180, int samples = std::getenv("FA_TEST_SAMPLES") ? std::atoi(std::getenv("FA_TEST_SAMPLES")) : 1) {
        static const std::filesystem::path dir = fs::make_temp_dir("fa_render_test_project");  // one per test process
        projectDir = dir;
        std::filesystem::create_directories(projectDir / "assets");
        fs::set_project_root(projectDir);
        if (!gpu.init(&error)) return;
        RendererDesc d;
        d.designWidth = w;
        d.designHeight = h;
        d.sampleCount = samples;
        d.headless = true;
        ok = renderer.init(d, gpu.environment(), &error);
    }
    ~Gfx() {
        renderer.shutdown();
        gpu.shutdown();
    }

    Image render(World& world, float dt = 0.0f) {
        renderer.begin_frame();
        renderer.render_world(world, dt);
        renderer.end_frame();
        gpu.end_frame();
        Image img;
        std::string err;
        bool captured = renderer.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
};

inline Gfx& gfx() {
    static Gfx g;
    return g;
}

// Compares against tests/golden/<name>.png (FA_UPDATE_GOLDEN=1 rewrites it).
inline void expect_golden(const Image& img, const std::string& name, double maxMeanError = 0.004) {
    std::filesystem::path path = std::filesystem::path(FA_RENDER_GOLDEN_DIR) / (name + ".png");
    const char* update = std::getenv("FA_UPDATE_GOLDEN");
    if ((update && std::string(update) == "1") || !std::filesystem::exists(path)) {
        auto r = save_png(img, path.generic_string());
        REQUIRE_MESSAGE(r.ok(), "cannot write golden " << path.string());
        MESSAGE("wrote golden " << path.string());
        return;
    }
    auto golden = load_image(path.generic_string());
    REQUIRE_MESSAGE(golden.ok(), "cannot load golden " << path.string());
    REQUIRE(golden->width == img.width);
    REQUIRE(golden->height == img.height);
    ImageDiff d = diff_images(*golden, img, 4.0f / 255.0f);
    INFO("golden " << name << ": meanError=" << d.meanError << " maxError=" << d.maxError << " differingPixels=" << d.differingPixels);
    if (d.meanError > maxMeanError) {
        auto actual = std::filesystem::path(FA_RENDER_GOLDEN_DIR) / (name + ".actual.png");
        (void)save_png(img, actual.generic_string());
        MESSAGE("actual image written to " << actual.string());
    }
    CHECK(d.meanError <= maxMeanError);
}

inline Entity make(World& w, const char* name, Vec3 pos = {}) {
    Entity e = w.create(name);
    w.get<Transform>(e)->position = pos;
    return e;
}

}  // namespace fa::test
