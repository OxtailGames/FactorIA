#include <doctest.h>

#include "fa/platform/app.h"
#include "sokol_gfx.h"

using namespace fa;

TEST_CASE("headless GPU initializes (EGL on Linux) and runs sokol_gfx") {
    HeadlessGpu gpu;
    std::string error;
    bool ok = gpu.init(&error);
    INFO("init error: " << error);
    REQUIRE(ok);
    CHECK(gpu.valid());
    MESSAGE("headless GPU: " << std::string(gpu.description()));

    GfxEnvironment env = gpu.environment();
    sg_desc desc{};
    desc.environment = env.get();
    sg_setup(&desc);
    CHECK(sg_isvalid());
    sg_image_desc id{};
    id.usage.color_attachment = true;
    id.width = 8;
    id.height = 8;
    id.pixel_format = SG_PIXELFORMAT_RGBA8;
    sg_image img = sg_make_image(&id);
    CHECK(sg_query_image_state(img) == SG_RESOURCESTATE_VALID);
    sg_destroy_image(img);
    sg_shutdown();
    gpu.shutdown();
    CHECK_FALSE(gpu.valid());
}

TEST_CASE("headless GPU can be re-created") {
    for (int i = 0; i < 2; ++i) {
        HeadlessGpu gpu;
        std::string error;
        REQUIRE_MESSAGE(gpu.init(&error), error);
    }
}
