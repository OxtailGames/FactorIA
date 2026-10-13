#include "test_util.h"

#include <cstring>

using namespace fa;
using namespace fa::test;

namespace {

// Writes a tileset/sprite sheet PNG into the temp project and returns its project path.
std::string write_checker(const std::string& name, int w, int h, int cell, Color a, Color b) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * h * 4);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) img.set_pixel(x, y, (((x / cell) + (y / cell)) % 2 == 0) ? a : b);
    std::string path = "assets/" + name;
    REQUIRE(save_png(img, path).ok());
    return path;
}

// 4x2 tile sheet, each 16x16 tile a different flat color with a 1px darker border.
std::string write_tileset() {
    Image img;
    img.width = 64;
    img.height = 32;
    img.rgba.resize(64 * 32 * 4);
    const Color cols[8] = {Color::hex(0x3b7d3b), Color::hex(0x8b5a2b), Color::hex(0x4a90d9), Color::hex(0xd9c24a),
                           Color::hex(0x9a9a9a), Color::hex(0xd94a4a), Color::hex(0x7a4ad9), Color::hex(0x4ad9c2)};
    for (int y = 0; y < 32; ++y)
        for (int x = 0; x < 64; ++x) {
            int t = (y / 16) * 4 + (x / 16);
            bool border = (x % 16 == 0) || (y % 16 == 0) || (x % 16 == 15) || (y % 16 == 15);
            Color c = cols[t];
            if (border) c = Color{c.r * 0.6f, c.g * 0.6f, c.b * 0.6f, 1};
            img.set_pixel(x, y, c);
        }
    REQUIRE(save_png(img, "assets/tiles.png").ok());
    return "assets/tiles.png";
}

}  // namespace

TEST_CASE("renderer initializes headless") {
    Gfx& g = gfx();
    INFO(g.error);
    REQUIRE(g.ok);
    CHECK(g.renderer.target_width() == 320);
    CHECK(g.renderer.target_height() == 180);
}

TEST_CASE("empty world clears to the default color") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Image img = g.render(w);
    Color c = img.pixel(10, 10);
    CHECK(c.r == doctest::Approx(0.08f).epsilon(0.05));
    CHECK(c.b == doctest::Approx(0.12f).epsilon(0.05));
}

TEST_CASE("2D shapes and solid sprites") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x20242c);

    auto rect = [&](Vec3 p, Vec2 size, Color c, bool filled, int layer = 0) {
        Entity e = make(w, "rect", p);
        auto& s = w.add<Shape2D>(e);
        s.shape = ShapeType::Rectangle; s.size = size; s.color = c; s.filled = filled; s.layer = layer;
        return e;
    };
    rect({-120, 50, 0}, {60, 40}, Color::hex(0xe05050), true);
    rect({-40, 50, 0}, {60, 40}, Color::hex(0x50e050), false);
    Entity circ = make(w, "circle", {40, 50, 0});
    {
        auto& s = w.add<Shape2D>(circ);
        s.shape = ShapeType::Circle; s.size = {44, 44}; s.color = Color::hex(0x5080f0);
    }
    Entity ring = make(w, "ring", {110, 50, 0});
    {
        auto& s = w.add<Shape2D>(ring);
        s.shape = ShapeType::Circle; s.size = {44, 44}; s.color = Color::hex(0xf0c040); s.filled = false; s.thickness = 4;
    }
    Entity line = make(w, "line", {-130, -20, 0});
    {
        auto& s = w.add<Shape2D>(line);
        s.shape = ShapeType::Line; s.size = {80, -40}; s.color = Color::white(); s.thickness = 3;
    }
    Entity tri = make(w, "tri", {-20, -40, 0});
    {
        auto& s = w.add<Shape2D>(tri);
        s.shape = ShapeType::Triangle; s.size = {50, 50}; s.color = Color::hex(0xc050f0);
    }
    Entity tri2 = make(w, "tri2", {50, -40, 0});
    {
        auto& s = w.add<Shape2D>(tri2);
        s.shape = ShapeType::Triangle; s.size = {50, 50}; s.color = Color::hex(0x40d0d0); s.filled = false; s.thickness = 3;
    }
    // Sorting: lower layer first; at equal layer a lower y draws on top.
    Entity a = make(w, "a", {112, -40, 0});
    { auto& s = w.add<Sprite>(a); s.size = {40, 40}; s.color = Color::hex(0xff0000); s.layer = 1; }
    Entity b = make(w, "b", {124, -52, 0});
    { auto& s = w.add<Sprite>(b); s.size = {40, 40}; s.color = Color::hex(0x00a000); s.layer = 1; }  // lower y: on top of a
    Entity c = make(w, "c", {118, -46, 0});
    { auto& s = w.add<Sprite>(c); s.size = {16, 16}; s.color = Color::hex(0xffffff); s.layer = 2; }  // higher layer on top
    Image img = g.render(w);

    // Orientation + sorting assertions (screen center = world origin; +Y world is up).
    auto at = [&](float wx, float wy) { return img.pixel(int(160 + wx), int(90 - wy)); };
    Color red = at(-120, 50);
    CHECK(red.r > 0.8f); CHECK(red.g < 0.4f);
    Color blue = at(40, 50);
    CHECK(blue.b > 0.8f);
    Color overlapB = at(136, -52);  // inside b, outside a? a spans x 92..132 so 136 is only b
    CHECK(overlapB.g > 0.5f);
    Color overlapAB = at(118, -60);  // inside both a (y -60..-20) and b (-72..-32): b is lower y -> on top
    CHECK(overlapAB.g > 0.5f);
    CHECK(overlapAB.r < 0.3f);
    Color top = at(118, -46);
    CHECK(top.r > 0.9f); CHECK(top.g > 0.9f);  // layer 2 white square
    expect_golden(img, "2d_shapes");
}

TEST_CASE("2D textured sprites, pixel art, animator and tilemap") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    make(w, "cam");
    w.add<Camera>(w.find("cam"));
    std::string sheet = write_checker("sheet.png", 32, 8, 4, Color::hex(0xffffff), Color::hex(0x303030));
    std::string tileset = write_tileset();

    Entity bg = make(w, "map", {-160, 90, 0});  // top-left corner of the map at the top-left of the screen
    {
        auto& tm = w.add<Tilemap>(bg);
        tm.tileset = tileset;
        tm.tileSize = {16, 16};
        tm.columns = 4;
        tm.width = 20; tm.height = 3;
        tm.layer = -10;
        Json rows = Json::array();
        for (int r = 0; r < 3; ++r) {
            Json row = Json::array();
            for (int c = 0; c < 20; ++c) row.push_back(r == 0 ? -1 : ((c + r) % 8));
            rows.push_back(row);
        }
        tm.tiles = rows;
    }
    Entity flat = make(w, "flat", {-160, 20, 0});
    {
        auto& tm = w.add<Tilemap>(flat);
        tm.tileset = tileset; tm.tileSize = {16, 16}; tm.columns = 4; tm.width = 4; tm.height = 2;
        tm.tiles = Json::array({0, 1, 2, 3, 4, 5, 6, 7});
    }
    Entity big = make(w, "big", {-100, -30, 0});
    {
        auto& s = w.add<Sprite>(big);
        s.texture = sheet; s.region = {0, 0, 8, 8}; s.size = {64, 64}; s.pixelArt = true;
    }
    Entity smooth = make(w, "smooth", {-20, -30, 0});
    {
        auto& s = w.add<Sprite>(smooth);
        s.texture = sheet; s.region = {0, 0, 8, 8}; s.size = {64, 64}; s.pixelArt = false;
    }
    Entity flipped = make(w, "flip", {60, -30, 0});
    {
        auto& s = w.add<Sprite>(flipped);
        s.texture = tileset; s.region = {0, 0, 32, 32}; s.size = {48, 48}; s.flipX = true; s.color = Color{1, 1, 1, 0.8f};
    }
    Entity anim = make(w, "anim", {120, -30, 0});
    {
        auto& s = w.add<Sprite>(anim);
        s.texture = tileset; s.size = {40, 40};
        auto& a = w.add<SpriteAnimator>(anim);
        a.columns = 4; a.rows = 2; a.firstFrame = 0; a.lastFrame = 7; a.fps = 4;
    }
    Entity rot = make(w, "rot", {120, 40, 0});
    {
        auto& s = w.add<Sprite>(rot);
        s.texture = tileset; s.region = {16, 0, 16, 16}; s.size = {32, 32};
        w.get<Transform>(rot)->rotation = {0, 0, 30};
    }
    Image img = g.render(w, 0.6f);  // animator: 0.6s * 4fps = frame 2
    // tilemap row 0 empty, row 1 starts with tile (0+1)%8 = 1 (brown) at the left edge
    Color t1 = img.pixel(8, 8 + 16 + 8 - 8);  // y: row1 spans screen y 16..32
    CHECK(t1.r > 0.3f);
    Color empty = img.pixel(8, 8);  // row 0 is empty => clear color
    CHECK(empty.r < 0.2f);
    expect_golden(img, "2d_sprites_tilemap");
    CHECK(g.renderer.stats().sprites == 6);
}

TEST_CASE("text: sizes, alignment, wrapping, accents, pixel font, screen space") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x101820);
    auto text = [&](Vec3 p, const std::string& s, float size, Vec2 pivot = {0, 1}, const std::string& font = "",
                    Align al = Align::Left, float maxW = 0, RenderSpace sp = RenderSpace::World) {
        Entity e = make(w, "t", p);
        auto& t = w.add<Text>(e);
        t.text = s; t.fontSize = size; t.pivot = pivot; t.font = font; t.align = al; t.maxWidth = maxW; t.space = sp;
        return e;
    };
    text({-155, 85, 0}, "The quick brown fox 12px", 12);
    text({-155, 70, 0}, "Crisp at 16 px: 0123456789", 16);
    text({-155, 50, 0}, "Año ñandú áéíóú çà ü ÅŁ", 20);
    text({-155, 25, 0}, "Big 48", 48);
    text({10, 80, 0}, "Wrapped text should flow inside the box width nicely", 14, {0, 1}, "", Align::Center, 140);
    text({10, 20, 0}, "PIXEL FONT 16", 16, {0, 1}, "builtin:pixel");
    text({0, -40, 0}, "Centered", 20, {0.5f, 0.5f}, "", Align::Center);
    text({155, -60, 0}, "Right aligned", 14, {1, 0}, "", Align::Right);
    text({6, 6, 0}, "HUD screen-space (top-left)", 12, {0, 1}, "", Align::Left, 0, RenderSpace::Screen);
    text({6, 174, 0}, "bottom-left HUD", 12, {0, 0}, "builtin:pixel", Align::Left, 0, RenderSpace::Screen);
    Image img = g.render(w);
    expect_golden(img, "2d_text");
    CHECK(g.renderer.stats().textGlyphs > 100);
}

TEST_CASE("particles are deterministic and visible") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto build = [](World& w) {
        Entity cam = make(w, "cam");
        w.add<Camera>(cam).clearColor = Color::hex(0x000010);
        Entity e = make(w, "fx", {0, -60, 0});
        auto& p = w.add<ParticleEmitter>(e);
        p.rate = 0; p.burst = 120; p.lifetime = 1.0f; p.speed = 120; p.spread = 40; p.startSize = 14; p.endSize = 2;
        p.startColor = Color::hex(0xffc040); p.endColor = Color{1, 0.2f, 0, 0};
        Entity e2 = make(w, "fx2", {-100, 20, 0});
        auto& q = w.add<ParticleEmitter>(e2);
        q.rate = 0; q.burst = 30; q.speed = 60; q.spread = 180; q.startSize = 10; q.endSize = 10; q.gravity = {0, 0, 0};
        q.startColor = Color::hex(0x40ff80); q.endColor = Color::hex(0x40ff80);
    };
    World w1, w2;
    build(w1);
    build(w2);
    Image a, b;
    for (int i = 0; i < 20; ++i) a = g.render(w1, 1.0f / 60.0f);
    g.renderer.clear_asset_cache();  // resets emitter states so both worlds start identically
    for (int i = 0; i < 20; ++i) b = g.render(w2, 1.0f / 60.0f);
    ImageDiff d = diff_images(a, b, 1.0f / 255.0f);
    CHECK(d.meanError < 0.0005);
    CHECK(g.renderer.stats().particles > 50);
    expect_golden(a, "2d_particles");
}

TEST_CASE("missing assets fall back and log exactly one error") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    clear_recent_logs();
    World w;
    make(w, "cam");
    w.add<Camera>(w.find("cam"));
    write_checker("player.png", 8, 8, 2, Color::white(), Color::black());
    Entity e = make(w, "s", {0, 0, 0});
    { auto& s = w.add<Sprite>(e); s.texture = "assets/playr.png"; }
    Entity m = make(w, "m", {0, 0, -3});
    { auto& mr = w.add<MeshRenderer>(m); mr.mesh = "assets/models/nope.glb"; }
    Entity t = make(w, "t");
    { auto& tx = w.add<Text>(t); tx.font = "assets/fonts/none.ttf"; }
    for (int i = 0; i < 3; ++i) {
        Image img = g.render(w);
        CHECK(img.width == 320);
    }
    int textureErrors = 0, meshErrors = 0, fontErrors = 0;
    std::string textureMsg;
    for (const auto& l : recent_logs(100, LogLevel::Error)) {
        if (l.message.find("playr.png") != std::string::npos) { ++textureErrors; textureMsg = l.message; }
        if (l.message.find("nope.glb") != std::string::npos) ++meshErrors;
        if (l.message.find("none.ttf") != std::string::npos) ++fontErrors;
    }
    CHECK(textureErrors == 1);
    CHECK(meshErrors == 1);
    CHECK(fontErrors == 1);
    CHECK(textureMsg.find("file not found") != std::string::npos);
    CHECK(textureMsg.find("Did you mean") != std::string::npos);
    CHECK(textureMsg.find("assets/player.png") != std::string::npos);
    Json report = g.renderer.asset_report();
    CHECK(report["failures"].size() >= 3);
}

TEST_CASE("camera helpers: world_to_screen / screen_to_world / ray") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam", {50, 20, 0});
    w.add<Camera>(cam);
    g.render(w);
    Vec2 s = g.renderer.world_to_screen({50, 20, 0});
    CHECK(s.x == doctest::Approx(160.0f)); CHECK(s.y == doctest::Approx(90.0f));
    Vec2 s2 = g.renderer.world_to_screen({60, 30, 0});  // right + up
    CHECK(s2.x == doctest::Approx(170.0f)); CHECK(s2.y == doctest::Approx(80.0f));
    Vec3 back = g.renderer.screen_to_world({170, 80}, 0.0f);
    CHECK(back.x == doctest::Approx(60.0f)); CHECK(back.y == doctest::Approx(30.0f));

    World w3;
    Entity c3 = make(w3, "cam", {0, 0, 5});
    w3.add<Camera>(c3).projection = Projection::Perspective;
    g.render(w3);
    Vec3 o, d;
    g.renderer.screen_ray({160, 90}, o, d);
    CHECK(d.z == doctest::Approx(-1.0f).epsilon(0.01));
    CHECK(o.z == doctest::Approx(5.0f).epsilon(0.01));
    Vec2 center = g.renderer.world_to_screen({0, 0, 0});
    CHECK(center.x == doctest::Approx(160.0f).epsilon(0.01));

    Vec2 d1 = g.renderer.framebuffer_to_design({640, 360}, 1280, 720, ScaleMode::Fit);
    CHECK(d1.x == doctest::Approx(160.0f)); CHECK(d1.y == doctest::Approx(90.0f));
    Vec2 d2 = g.renderer.framebuffer_to_design({640, 360}, 1280, 1000, ScaleMode::Fit);  // letterboxed vertically
    CHECK(d2.y == doctest::Approx(90.0f));
    Vec2 d3 = g.renderer.framebuffer_to_design({0, 140}, 1280, 1000, ScaleMode::Fit);  // top letterbar edge
    CHECK(d3.y == doctest::Approx(0.0f).epsilon(0.02));
}

TEST_CASE("debug draw renders on top and clears each frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    make(w, "cam");
    w.add<Camera>(w.find("cam"));
    g.renderer.debug().line({-100, -50, 0}, {100, 50, 0}, Color::red(), 2);
    g.renderer.debug().rect(Rect{-50, -20, 100, 40}, Color::green(), false);
    g.renderer.debug().circle({0, 0}, 30, Color::blue(), false);
    g.renderer.debug().text({4, 4}, "debug text", Color::white(), 12);
    Image a = g.render(w);
    expect_golden(a, "2d_debug");
    Image b = g.render(w);  // debug data was consumed
    CHECK(b.pixel(160, 90).r < 0.2f);
}
