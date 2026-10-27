// Run-time textures: a picture of the frame made into a texture (Renderer::capture_fitted, create_runtime_texture), which
// a Sprite draws like an asset. These run on whatever backend the machine has (Metal, GL, D3D11), reading the frame back.
#include "test_util.h"

#include "fa/core/image.h"

using namespace fa;
using namespace fa::test;

namespace {

// A frame with something different in every quarter, so a flipped, shifted or cropped copy is told from the right one.
void town(World& w) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x203040);
    auto shape = [&](const char* name, Vec3 pos, Vec2 size, Color color) {
        Entity e = make(w, name, pos);
        auto& s = w.add<Shape2D>(e);
        s.size = size;
        s.color = color;
    };
    shape("red", {-80, 45, 0}, {100, 50}, Color::hex(0xd03030));
    shape("blue", {90, -40, 0}, {60, 60}, Color::hex(0x3050e0));
    shape("tall", {-140, -30, 0}, {20, 90}, Color::hex(0x40c060));
}

// A world that only shows the texture `id`, `size` large, in the middle of the 320 x 180 view.
void show(World& w, const std::string& id, Vec2 size) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x000000);
    Entity e = make(w, "pic", {0, 0, 0});
    auto& s = w.add<Sprite>(e);
    s.texture = id;
    s.size = size;
    s.pixelArt = true;
}

Json texture_entry(Gfx& g, const std::string& id) {
    const Json report = g.renderer.asset_report();
    for (const Json& t : report["textures"])
        if (t["path"] == id) return t;
    return Json();
}

bool has_failure(Gfx& g, const std::string& id) {
    const Json report = g.renderer.asset_report();
    for (const Json& f : report["failures"])
        if (f["path"] == id) return true;
    return false;
}

}  // namespace

TEST_CASE("runtime textures: a capture at the target size has the pixels of the screenshot, and a Sprite draws it back") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World a;
    town(a);
    const Image frame = g.render(a);

    Image pic;
    std::string err;
    REQUIRE_MESSAGE(g.renderer.capture_fitted(pic, frame.width, frame.height, false, &err), err);
    CHECK(pic.width == frame.width);
    CHECK(pic.height == frame.height);
    CHECK(pic.rgba == frame.rgba);  // exactly the screenshot's pixels

    const std::string id = g.renderer.create_runtime_texture(pic, &err);
    REQUIRE_MESSAGE(!id.empty(), err);
    CHECK(id.rfind("runtime:", 0) == 0);
    World b;
    show(b, id, {float(frame.width), float(frame.height)});
    const Image again = g.render(b);
    const ImageDiff d = diff_images(frame, again, 1.0f / 255.0f);
    INFO("meanError=" << d.meanError << " maxError=" << d.maxError << " differingPixels=" << d.differingPixels);
    CHECK(d.meanError < 0.001);  // the same picture, the right way up
    CHECK(g.renderer.destroy_runtime_texture(id));
}

TEST_CASE("runtime textures: a smaller capture keeps the picture (cover crops to the aspect ratio, stretch squeezes the frame)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World a;
    town(a);
    const Image frame = g.render(a);

    Image cover, stretch;
    REQUIRE(g.renderer.capture_fitted(cover, 90, 90, false));
    REQUIRE(g.renderer.capture_fitted(stretch, 160, 90, true));
    CHECK(cover.width == 90);
    CHECK(cover.height == 90);
    CHECK(stretch.width == 160);
    CHECK(stretch.height == 90);
    // The same as cutting and resampling the screenshot by hand.
    CHECK(cover.rgba == cover_image(frame, 90, 90).rgba);
    CHECK(stretch.rgba == resize_image(frame, 160, 90).rgba);
    // cover is the middle 180 x 180 of the 320 x 180 frame: the green bar at the far left (x < 20 of 320) is cut away.
    const Color leftEdge = cover.pixel(0, 60);
    CHECK(leftEdge.g < 0.6f);  // not the bar's green 0xc0
    const Color stretchLeft = stretch.pixel(5, 60);
    CHECK(stretchLeft.g > 0.6f);  // the stretched copy still has it
    CHECK_FALSE(g.renderer.capture_fitted(cover, 0, 10, false));
}

TEST_CASE("runtime textures: ids, report, memory, destroy and clear_asset_cache") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Image px;
    px.width = px.height = 8;
    px.rgba.assign(8 * 8 * 4, 200);
    g.renderer.clear_asset_cache();  // earlier tests of this binary share the renderer: count from nothing
    const std::uint64_t before = g.renderer.texture_bytes();
    std::string err;
    const std::string one = g.renderer.create_runtime_texture(px, &err);
    const std::string two = g.renderer.create_runtime_texture(px, &err);
    REQUIRE(!one.empty());
    REQUIRE(!two.empty());
    CHECK(one != two);
    CHECK(g.renderer.texture_bytes() > before);
    const Json entry = texture_entry(g, one);
    REQUIRE(entry.is_object());
    CHECK(entry["width"] == 8);
    CHECK(entry["runtime"] == true);

    g.renderer.clear_asset_cache();  // a script holds the ids: they stay
    CHECK(texture_entry(g, one).is_object());

    CHECK(g.renderer.destroy_runtime_texture(one));
    CHECK_FALSE(g.renderer.destroy_runtime_texture(one));  // twice is a plain false
    CHECK_FALSE(texture_entry(g, one).is_object());
    CHECK(g.renderer.destroy_runtime_texture(two));
    CHECK(g.renderer.texture_bytes() == before);

    // A Sprite that still names a destroyed texture draws the missing-texture checker and the failure says what happened.
    World w;
    show(w, one, {64, 64});
    const Image missing = g.render(w);
    CHECK(has_failure(g, one));
    World bare;
    show(bare, "", {64, 64});
    CHECK(diff_images(missing, g.render(bare), 4.0f / 255.0f).meanError > 0.01);
    bool taught = false;
    const Json report = g.renderer.asset_report();
    for (const Json& f : report["failures"])
        if (f["path"] == one) taught = f["message"].get<std::string>().find("run-time texture") != std::string::npos;
    CHECK(taught);

    Image empty;
    CHECK(g.renderer.create_runtime_texture(empty, &err).empty());
    CHECK(err.find("4096") != std::string::npos);
}
