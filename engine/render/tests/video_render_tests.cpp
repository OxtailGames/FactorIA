// A Video component draws the current picture of its .mpg inside its rectangle (fit contain / cover / stretch) and the
// picture follows the clock update_videos advances. engine/core/tests/data/colors.mpg is 64x64: red 0 - 0.4 s, green
// 0.4 - 0.8 s, blue 0.8 - 1.2 s, with noise in its top 8 rows.
#include "test_util.h"

#include <filesystem>

#include "fa/scene/video.h"

using namespace fa;
using namespace fa::test;

namespace {

void install_fixture(Gfx& g) {
    std::filesystem::create_directories(g.projectDir / "assets/video");
    std::filesystem::copy_file(FA_VIDEO_FIXTURE, g.projectDir / "assets/video/colors.mpg",
                               std::filesystem::copy_options::overwrite_existing);
}

Video& video_at(World& w, float x, float y, float width, float height, VideoFit fit) {
    Entity e = make(w, "video", {x, y, 0});
    Video& v = w.add<Video>(e);
    v.path = "assets/video/colors.mpg";
    v.size = {width, height};
    v.pivot = {0, 1};
    v.fit = fit;
    v.color = Color{0, 0, 0, 1};
    return v;
}

bool is_red(const Color& c) { return c.r > 0.75f && c.g < 0.25f && c.b < 0.25f; }
bool is_green(const Color& c) { return c.g > 0.4f && c.r < 0.25f && c.b < 0.25f; }
bool is_blue(const Color& c) { return c.b > 0.75f && c.r < 0.25f && c.g < 0.25f; }
bool is_black(const Color& c) { return c.r < 0.05f && c.g < 0.05f && c.b < 0.05f; }

}  // namespace

TEST_CASE("video: the picture of the clock's time is drawn into the UI rectangle") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_fixture(g);
    World w;
    w.add<Camera>(make(w, "cam"));
    video_at(w, 10, 10, 128, 128, VideoFit::Stretch);
    update_videos(w, 0.0f);  // opens the file; the first picture is there
    Image img = g.render(w);
    CHECK(is_red(img.pixel(70, 74)));
    CHECK_FALSE(is_red(img.pixel(5, 74)));  // outside the rectangle: the clear colour

    update_videos(w, 0.6f);  // 0.6 s: green
    img = g.render(w);
    CHECK(is_green(img.pixel(70, 74)));
    update_videos(w, 0.4f);  // 1.0 s: blue
    img = g.render(w);
    CHECK(is_blue(img.pixel(70, 74)));
    // A frame drawn twice without the clock moving shows the same picture.
    CHECK(is_blue(g.render(w).pixel(70, 74)));
}

TEST_CASE("video: contain keeps the aspect ratio with bars, cover fills and crops, stretch fills") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_fixture(g);
    for (VideoFit fit : {VideoFit::Contain, VideoFit::Cover, VideoFit::Stretch}) {
        World w;
        w.add<Camera>(make(w, "cam"));
        // 200 x 100 rectangle at (10, 10); the picture is square.
        video_at(w, 10, 10, 200, 100, fit);
        update_videos(w, 0.0f);
        const Image img = g.render(w);
        INFO("fit " << int(fit));
        CHECK(is_red(img.pixel(110, 60)));  // the middle is picture in every mode
        if (fit == VideoFit::Contain) {
            CHECK(is_black(img.pixel(20, 60)));    // bar on the left: the picture is 100 wide, centred (60 .. 160)
            CHECK(is_black(img.pixel(200, 60)));   // bar on the right
            CHECK(is_red(img.pixel(70, 60)));      // the picture's left edge
            CHECK(is_red(img.pixel(150, 60)));     // and its right edge
        } else {
            CHECK(is_red(img.pixel(20, 60)));      // fills the width
            CHECK(is_red(img.pixel(200, 60)));
        }
        if (fit == VideoFit::Cover) {
            // The square picture is scaled to 200 x 200 and the middle 100 rows are shown: the noise strip (top 8 rows of
            // the picture, the first 25 px of the scaled one) is cropped away, so the top row of the rectangle is red.
            CHECK(is_red(img.pixel(110, 12)));
        }
    }
}

TEST_CASE("video: a Video whose file is missing draws only its background and a tint multiplies the picture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_fixture(g);
    World w;
    w.add<Camera>(make(w, "cam"));
    Video& missing = video_at(w, 10, 10, 60, 60, VideoFit::Stretch);
    missing.path = "assets/video/nope.mpg";
    missing.color = Color{0, 0.5f, 0, 1};
    Video& tinted = video_at(w, 100, 10, 60, 60, VideoFit::Stretch);
    tinted.tint = Color{1, 0.5f, 0.5f, 1};
    update_videos(w, 0.0f);
    CHECK_FALSE(missing.rt.decoder);
    const Image img = g.render(w);
    const Color bg = img.pixel(40, 40);
    CHECK((bg.g > 0.4f && bg.r < 0.05f));
    const Color t = img.pixel(130, 40);  // red picture with g and b halved
    CHECK(t.r > 0.75f);
    CHECK(t.g < 0.2f);
}

TEST_CASE("video: the background is left out when the opaque picture hides all of it") {
    // A full-screen video would otherwise fill the screen twice: on a software renderer that is most of a frame.
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_fixture(g);
    auto draw = [&](VideoFit fit, float width, float tintAlpha, int& drawCalls) {
        World w;
        w.add<Camera>(make(w, "cam"));
        Video& v = video_at(w, 10, 10, width, 128, fit);
        v.color = Color{0, 1, 0, 1};
        v.tint.a = tintAlpha;
        update_videos(w, 0.0f);
        Image img = g.render(w);
        drawCalls = g.renderer.stats().drawCalls;
        return img;
    };
    int opaque = 0, see_through = 0, square = 0, bars = 0;
    const Image a = draw(VideoFit::Stretch, 128, 1.0f, opaque);
    const Image b = draw(VideoFit::Stretch, 128, 0.999f, see_through);
    draw(VideoFit::Contain, 128, 1.0f, square);            // a square picture in a square rectangle: covers it too
    const Image c = draw(VideoFit::Contain, 200, 1.0f, bars);  // wider: bars on the sides
    CHECK(see_through == opaque + 1);  // the background is drawn under a picture that lets it through
    CHECK(square == opaque);
    CHECK(bars == opaque + 1);
    const Color bar = c.pixel(20, 74);
    CHECK((bar.g > 0.9f && bar.r < 0.05f));
    CHECK(is_red(a.pixel(70, 74)));
    CHECK(is_red(b.pixel(70, 74)));
    CHECK(is_red(a.pixel(11, 136)));  // the picture reaches the rectangle's corners (its top rows are noise)
    CHECK(is_red(a.pixel(136, 136)));
}
