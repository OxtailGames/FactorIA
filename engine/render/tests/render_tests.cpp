#include "test_util.h"

#include <cstring>

#include "fa/scene/tilemap.h"

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
    CHECK(g.renderer.stats().sprites == 5);
}

TEST_CASE("tilemap: columns left unset is derived from the tileset width") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    make(w, "cam");
    w.add<Camera>(w.find("cam"));
    // 64x32 image of 16x16 tiles = 4 columns x 2 rows; tile n has a distinct flat color (see write_tileset).
    std::string tileset = write_tileset();

    // Rows form, no width/height, no columns: top-left corner of the map at the top-left of the screen.
    Entity rowsMap = make(w, "rows", {-160, 90, 0});
    {
        auto& tm = w.add<Tilemap>(rowsMap);
        REQUIRE(tm.columns == 0);  // the default: derive from the texture
        tm.tileset = tileset;
        tm.tileSize = {16, 16};
        tm.tiles = Json::array({Json::array({3, 4, 7})});
    }
    // Flat form with width/height, below it.
    Entity flatMap = make(w, "flat", {-160, 58, 0});
    {
        auto& tm = w.add<Tilemap>(flatMap);
        tm.tileset = tileset;
        tm.tileSize = {16, 16};
        tm.width = 3;
        tm.height = 2;
        tm.tiles = Json::array({5, 6, 2, 3, -1, 4});
    }
    // An explicit columns value still wins: "columns": 2 on the same 4-wide image reads tile 3 as column 1 of row 1.
    Entity explicitMap = make(w, "explicit", {-160, 10, 0});
    {
        auto& tm = w.add<Tilemap>(explicitMap);
        tm.tileset = tileset;
        tm.tileSize = {16, 16};
        tm.columns = 2;
        tm.width = 1;
        tm.height = 1;
        tm.tiles = Json::array({3});
    }
    Image img = g.render(w);
    const Color tileColor[8] = {Color::hex(0x3b7d3b), Color::hex(0x8b5a2b), Color::hex(0x4a90d9), Color::hex(0xd9c24a),
                                Color::hex(0x9a9a9a), Color::hex(0xd94a4a), Color::hex(0x7a4ad9), Color::hex(0x4ad9c2)};
    // Centre of cell (col, row) of a map whose top-left corner is at screen y = top.
    auto expect_tile = [&](int top, int col, int row, int tile, const char* what) {
        Color got = img.pixel(col * 16 + 8, top + row * 16 + 8);
        INFO(what << ": cell (" << col << ", " << row << ") should show tile " << tile << ", got rgb " << got.r << " " << got.g << " " << got.b);
        CHECK(std::fabs(got.r - tileColor[tile].r) < 0.03f);
        CHECK(std::fabs(got.g - tileColor[tile].g) < 0.03f);
        CHECK(std::fabs(got.b - tileColor[tile].b) < 0.03f);
    };
    // Tile 3 is the 4th column of the first image row (yellow), 4 the first column of the second row (grey), 7 the last.
    expect_tile(0, 0, 0, 3, "rows form");
    expect_tile(0, 1, 0, 4, "rows form");
    expect_tile(0, 2, 0, 7, "rows form");
    expect_tile(32, 0, 0, 5, "flat form");
    expect_tile(32, 1, 0, 6, "flat form");
    expect_tile(32, 2, 0, 2, "flat form");
    expect_tile(32, 0, 1, 3, "flat form");
    expect_tile(32, 2, 1, 4, "flat form");
    Color emptyCell = img.pixel(1 * 16 + 8, 32 + 16 + 8);  // tile -1 draws nothing: clear color
    CHECK(emptyCell.r < 0.2f);
    // columns = 2: tile 3 is column 1 of row 1 of the image, which is the 4x2 sheet's tile 5.
    Color explicitGot = img.pixel(8, 80 + 8);
    CHECK(std::fabs(explicitGot.r - tileColor[5].r) < 0.03f);
    CHECK(std::fabs(explicitGot.g - tileColor[5].g) < 0.03f);
}

TEST_CASE("tilemap: a tileset with margin 1 and spacing 2 reads each tile from its own rectangle") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    make(w, "cam");
    w.add<Camera>(w.find("cam"));
    // 22x22 image: a 1 px margin, then 2x2 tiles of 8x8 px separated by 2 px gutters; the margin and gutters are magenta.
    // Tile origins: 1 and 11 in both axes. A packed reading (no margin, no spacing) would hit magenta or the wrong tile.
    const Color tileColor[4] = {Color::hex(0x3b7d3b), Color::hex(0x4a90d9), Color::hex(0xd9c24a), Color::hex(0xd94a4a)};
    Image img;
    img.width = 22;
    img.height = 22;
    img.rgba.resize(22 * 22 * 4);
    for (int y = 0; y < 22; ++y)
        for (int x = 0; x < 22; ++x) {
            Color c = Color::hex(0xff00ff);
            const int tx = (x - 1) / 10, ty = (y - 1) / 10;
            if (x >= 1 && y >= 1 && (x - 1) % 10 < 8 && (y - 1) % 10 < 8 && tx < 2 && ty < 2) c = tileColor[ty * 2 + tx];
            img.set_pixel(x, y, c);
        }
    REQUIRE(save_png(img, "assets/margin_tiles.png").ok());
    Entity e = make(w, "map", {-160, 90, 0});
    auto& tm = w.add<Tilemap>(e);
    tm.tileset = "assets/margin_tiles.png";
    tm.tileSize = {8, 8};
    tm.margin = 1;
    tm.spacing = 2;
    tm.width = 4;
    tm.height = 1;
    tm.tiles = Json::array({0, 1, 2, 3});
    CHECK(tileset_columns(tm, 22) == 2);
    CHECK(tileset_tile_count(tm, 22, 22) == 4);
    Image out = g.render(w);
    for (int t = 0; t < 4; ++t) {
        for (int dy : {0, 7})
            for (int dx : {0, 7}) {
                Color got = out.pixel(t * 8 + dx, dy);
                INFO("tile " << t << " pixel (" << dx << ", " << dy << ") got rgb " << got.r << " " << got.g << " " << got.b);
                CHECK(std::fabs(got.r - tileColor[t].r) < 0.03f);
                CHECK(std::fabs(got.g - tileColor[t].g) < 0.03f);
                CHECK(std::fabs(got.b - tileColor[t].b) < 0.03f);
            }
    }
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
    text({-155, 72, 0}, "The quick brown fox 12px", 12);
    text({-155, 56, 0}, "Crisp at 16 px: 0123", 16);
    text({-155, 34, 0}, "Año ñandú áéíóú çà ü", 20);
    text({-155, 6, 0}, "Big 48", 48);
    text({10, 72, 0}, "Wrapped text should flow inside the box width nicely", 12, {0, 1}, "", Align::Center, 120);
    text({10, 2, 0}, "PIXEL 16", 16, {0, 1}, "builtin:pixel");
    text({85, -30, 0}, "Centered", 20, {0.5f, 0.5f}, "", Align::Center);
    text({155, -60, 0}, "Right aligned", 14, {1, 0}, "", Align::Right);
    text({314, 4, 0}, "HUD top-right", 12, {1, 1}, "", Align::Right, 0, RenderSpace::Screen);
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

TEST_CASE("text: characters the font has no glyph for are reported once per font, with what to do") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();  // a fresh font cache: nothing warned yet
    clear_recent_logs();
    World w;
    make(w, "cam");
    w.add<Camera>(w.find("cam"));
    auto text = [&](const std::string& s, const std::string& font = "") {
        auto& t = w.add<Text>(make(w, "t"));
        t.text = s;
        t.font = font;
    };
    text("Score 日本語 中文 한국어");   // DejaVu Sans has no CJK
    text("Año ñandú, Ωμέγα, Привет");  // Latin, Greek and Cyrillic: all there
    text("Pixel 日本", "builtin:pixel");
    for (int i = 0; i < 3; ++i) g.render(w);
    std::vector<std::string> warnings;
    for (const auto& l : recent_logs(200, LogLevel::Warn))
        if (l.message.find("no glyph for") != std::string::npos) warnings.push_back(l.message);
    REQUIRE(warnings.size() == 2);  // one per font, not per frame or per text
    const std::string& builtin = warnings[0].find("builtin:pixel") == std::string::npos ? warnings[0] : warnings[1];
    const std::string& pixel = warnings[0].find("builtin:pixel") == std::string::npos ? warnings[1] : warnings[0];
    CHECK(builtin.find("U+65E5 '\xE6\x97\xA5'") != std::string::npos);  // 日
    CHECK(builtin.find("DejaVu Sans") != std::string::npos);
    CHECK(builtin.find("Noto Sans SC, JP or KR") != std::string::npos);
    CHECK(builtin.find("assets/fonts/") != std::string::npos);
    CHECK(builtin.find("U+00F1") == std::string::npos);  // ñ is not missing
    CHECK(pixel.find("Press Start 2P") != std::string::npos);
    CHECK(pixel.find("U+65E5") != std::string::npos);
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
    Vec2 d2 = g.renderer.framebuffer_to_design({640, 500}, 1280, 1000, ScaleMode::Fit);  // letterboxed vertically
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

// ---------------------------------------------------------------------------
// Blend modes, anchors, pivots, particles (burst / autoDestroy), update/draw split, measure_text
// ---------------------------------------------------------------------------
namespace {
Entity rect_at(World& w, Vec3 p, Vec2 size, Color c, RenderSpace sp = RenderSpace::World, Vec2 pivot = {0.5f, 0.5f},
               Vec2 anchor = {0, 0}, BlendMode bm = BlendMode::Alpha, int layer = 0) {
    Entity e = make(w, "r", p);
    auto& s = w.add<Shape2D>(e);
    s.shape = ShapeType::Rectangle; s.size = size; s.color = c; s.space = sp; s.pivot = pivot; s.anchor = anchor;
    s.blend = bm; s.layer = layer;
    return e;
}
}  // namespace

TEST_CASE("blend modes: alpha, additive, multiply") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color{0.2f, 0.2f, 0.2f, 1};
    // background strip so the blends have something to act on
    rect_at(w, {0, 0, 0}, {320, 40}, Color{0.5f, 0.5f, 0.5f, 1}, RenderSpace::World, {0.5f, 0.5f}, {0, 0}, BlendMode::Alpha, -1);
    rect_at(w, {-100, 0, 0}, {50, 50}, Color{1, 0, 0, 0.5f}, RenderSpace::World, {0.5f, 0.5f}, {0, 0}, BlendMode::Alpha);
    rect_at(w, {0, 0, 0}, {50, 50}, Color{1, 0, 0, 0.5f}, RenderSpace::World, {0.5f, 0.5f}, {0, 0}, BlendMode::Additive);
    rect_at(w, {100, 0, 0}, {50, 50}, Color{0.5f, 0.5f, 1, 1}, RenderSpace::World, {0.5f, 0.5f}, {0, 0}, BlendMode::Multiply);
    // two overlapping additive items accumulate
    rect_at(w, {-30, -65, 0}, {40, 30}, Color{0.3f, 0.3f, 0.3f, 1}, RenderSpace::World, {0.5f, 0.5f}, {0, 0}, BlendMode::Additive);
    rect_at(w, {-10, -65, 0}, {40, 30}, Color{0.3f, 0.3f, 0.3f, 1}, RenderSpace::World, {0.5f, 0.5f}, {0, 0}, BlendMode::Additive);
    Image img = g.render(w);
    // centers: world (x,y) -> pixel (160+x, 90-y)
    Color a = img.pixel(60, 90), ad = img.pixel(160, 90), mu = img.pixel(260, 90);
    CHECK(a.r == doctest::Approx(0.75f).epsilon(0.03));   // 0.5*1 + 0.5*0.5
    CHECK(a.g == doctest::Approx(0.25f).epsilon(0.05));
    CHECK(ad.r == doctest::Approx(1.0f).epsilon(0.03));   // 0.5 + 0.5*1
    CHECK(ad.g == doctest::Approx(0.5f).epsilon(0.03));   // unchanged by red additive
    CHECK(mu.r == doctest::Approx(0.25f).epsilon(0.05));  // 0.5*0.5
    CHECK(mu.b == doctest::Approx(0.5f).epsilon(0.05));   // 0.2*... background strip? (y 70..110 covers) 0.5*1
    Color overlap = img.pixel(140, 155), single = img.pixel(125, 155);
    CHECK(overlap.r > single.r + 0.2f);
    expect_golden(img, "2d_blend_modes");
}

TEST_CASE("screen-space anchored HUD: 4 corners + center") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x101820);
    auto S = RenderSpace::Screen;
    rect_at(w, {10, 10, 0}, {40, 20}, Color::hex(0xe05050), S, {0, 1}, {0, 0});        // top-left
    rect_at(w, {-10, 10, 0}, {40, 20}, Color::hex(0x50e050), S, {1, 1}, {1, 0});       // top-right
    rect_at(w, {10, -10, 0}, {40, 20}, Color::hex(0x5050e0), S, {0, 0}, {0, 1});       // bottom-left
    rect_at(w, {-10, -10, 0}, {40, 20}, Color::hex(0xe0e050), S, {1, 0}, {1, 1});      // bottom-right
    rect_at(w, {0, 0, 0}, {40, 20}, Color::hex(0xffffff), S, {0.5f, 0.5f}, {0.5f, 0.5f});  // center
    Entity t = make(w, "t", {0, 30, 0});
    auto& tx = w.add<Text>(t);
    tx.text = "TOP"; tx.fontSize = 14; tx.space = S; tx.anchor = {0.5f, 0}; tx.pivot = {0.5f, 1};
    Entity sp = make(w, "sp", {-10, -40, 0});
    auto& s = w.add<Sprite>(sp);
    s.space = S; s.anchor = {1, 1}; s.pivot = {1, 0}; s.size = {16, 16}; s.color = Color::hex(0xff00ff);
    Image img = g.render(w);
    CHECK(img.pixel(30, 20).r > 0.8f);     // red: x 10..50, y 10..30
    CHECK(img.pixel(9, 5).r < 0.2f);
    CHECK(img.pixel(290, 20).g > 0.8f);    // green: x 270..310
    CHECK(img.pixel(30, 160).b > 0.8f);    // blue: y 150..170
    CHECK(img.pixel(290, 160).r > 0.8f);   // yellow
    CHECK(img.pixel(160, 90).g > 0.9f);
    CHECK(img.pixel(300, 130).b > 0.8f);   // magenta sprite: x 294..310, y 114..130 -> (300,125)
    CHECK(img.pixel(300, 125).r > 0.8f);
    expect_golden(img, "ui_anchored_hud");
}

TEST_CASE("Shape2D pivots in world and screen space") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x101820);
    // world: pivot [0,0] = bottom-left corner at position (extends right/up)
    rect_at(w, {-100, 0, 0}, {40, 30}, Color::hex(0xe05050), RenderSpace::World, {0, 0});
    auto circle = [&](Vec3 p, Vec2 pivot, Color c, RenderSpace sp) {
        Entity e = make(w, "c", p);
        auto& s = w.add<Shape2D>(e);
        s.shape = ShapeType::Circle; s.size = {30, 30}; s.color = c; s.pivot = pivot; s.space = sp;
    };
    auto tri = [&](Vec3 p, Vec2 pivot, Color c, RenderSpace sp) {
        Entity e = make(w, "t", p);
        auto& s = w.add<Shape2D>(e);
        s.shape = ShapeType::Triangle; s.size = {30, 30}; s.color = c; s.pivot = pivot; s.space = sp;
    };
    circle({0, 0, 0}, {0, 0}, Color::hex(0x50e050), RenderSpace::World);
    tri({60, 0, 0}, {0, 0}, Color::hex(0x5050e0), RenderSpace::World);
    // screen: pivot [0,1] = top-left corner at position (extends right/down)
    rect_at(w, {20, 120, 0}, {40, 30}, Color::hex(0xe0e050), RenderSpace::Screen, {0, 1});
    circle({100, 120, 0}, {0, 1}, Color::hex(0x50e0e0), RenderSpace::Screen);
    // default stays centered
    rect_at(w, {160, 140, 0}, {20, 20}, Color::hex(0xffffff), RenderSpace::Screen);
    Image img = g.render(w);
    CHECK(img.pixel(60, 80).r > 0.8f);     // world red: x -100..-60 -> px 60..100, y 0..30 -> py 90..60
    CHECK(img.pixel(55, 80).r < 0.2f);
    CHECK(img.pixel(160 + 15, 75).g > 0.8f);   // circle center at (15,15)
    CHECK(img.pixel(160 - 5, 95).g < 0.2f);
    CHECK(img.pixel(40, 135).r > 0.8f);    // screen yellow: x 20..60, y 120..150
    CHECK(img.pixel(40, 115).b < 0.2f);
    CHECK(img.pixel(115, 135).g > 0.8f);   // screen circle center (115,135)
    CHECK(img.pixel(160, 140).r > 0.9f);
    CHECK(img.pixel(160, 155).r < 0.2f);
    expect_golden(img, "2d_shape_pivots");
}

TEST_CASE("particles: burst fires with emitting=false, emit_burst, autoDestroy") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x000010);
    Entity e = make(w, "boom", {-80, 0, 0});
    auto& p = w.add<ParticleEmitter>(e);
    p.emitting = false; p.rate = 0; p.burst = 60; p.lifetime = 1.0f; p.speed = 80; p.spread = 180; p.startSize = 12;
    p.endSize = 12; p.gravity = {0, 0, 0}; p.startColor = Color::hex(0xffc040); p.endColor = Color::hex(0xffc040);
    p.autoDestroy = true; p.blend = BlendMode::Additive;
    Entity m = make(w, "manual", {80, 0, 0});
    auto& q = w.add<ParticleEmitter>(m);
    q.emitting = false; q.rate = 0; q.burst = 0; q.lifetime = 10.0f; q.speed = 30; q.spread = 180; q.startSize = 10;
    q.endSize = 10; q.gravity = {0, 0, 0}; q.startColor = Color::hex(0x40ff80); q.endColor = Color::hex(0x40ff80);
    Image img;
    for (int i = 0; i < 3; ++i) img = g.render(w, 1.0f / 30.0f);
    CHECK(g.renderer.stats().particles == 60);  // burst fired though emitting=false; manual emitter idle
    g.renderer.emit_burst(m, 40);
    for (int i = 0; i < 6; ++i) img = g.render(w, 1.0f / 30.0f);
    CHECK(g.renderer.stats().particles == 100);
    expect_golden(img, "2d_particle_burst_idle");
    for (int i = 0; i < 40; ++i) { img = g.render(w, 1.0f / 30.0f); w.flush(); }
    CHECK_FALSE(w.alive(e));       // autoDestroy removed the finished one-shot
    CHECK(w.alive(m));             // no autoDestroy on the manual one
    CHECK(g.renderer.stats().particles == 40);
    expect_golden(img, "2d_particle_autodestroy");
}

TEST_CASE("update/draw split: skipping draws gives the same image") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto build = [](World& w) {
        Entity cam = make(w, "cam");
        w.add<Camera>(cam).clearColor = Color::hex(0x000010);
        Entity e = make(w, "fx", {0, -60, 0});
        auto& p = w.add<ParticleEmitter>(e);
        p.rate = 60; p.burst = 20; p.lifetime = 1.0f; p.speed = 100; p.spread = 40; p.startSize = 10;
        Entity s = make(w, "anim", {-100, 40, 0});
        w.add<Sprite>(s).size = {20, 20};
        auto& a = w.add<SpriteAnimator>(s);
        a.columns = 2; a.rows = 1; a.firstFrame = 0; a.lastFrame = 1; a.fps = 7;
    };
    auto sheet = write_checker("split_sheet.png", 32, 16, 8, Color::hex(0xff0000), Color::hex(0x00ff00));
    World w1, w2;
    build(w1); build(w2);
    w1.each<Sprite>([&](Entity, Sprite& s) { s.texture = sheet; });
    w2.each<Sprite>([&](Entity, Sprite& s) { s.texture = sheet; });
    Image a, b;
    g.renderer.clear_asset_cache();
    for (int i = 0; i < 25; ++i) { g.renderer.update(w1, 1.0f / 60.0f); a = g.render(w1, 1.0f / 60.0f); }
    g.renderer.clear_asset_cache();
    for (int i = 0; i < 25; ++i) {
        g.renderer.update(w2, 1.0f / 60.0f);
        if (i == 24) b = g.render(w2, 1.0f / 60.0f);  // only the last frame is drawn
    }
    ImageDiff d = diff_images(a, b, 1.0f / 255.0f);
    CHECK(d.meanError < 0.0005);
    CHECK(d.differingPixels == 0);
}

TEST_CASE("measure_text matches Text layout") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Vec2 one = g.renderer.measure_text("Hello world", 20);
    CHECK(one.x > 50);
    CHECK(one.y > 10);
    CHECK(g.renderer.measure_text("Hello world", 40).x > one.x * 1.8f);
    Vec2 wrapped = g.renderer.measure_text("Hello world this wraps", 20, {}, 80);
    CHECK(wrapped.x <= 80.5f);
    CHECK(wrapped.y > one.y * 1.5f);
    Vec2 two = g.renderer.measure_text("a\nb", 20);
    CHECK(two.y > one.y * 1.5f);
    CHECK(g.renderer.measure_text("", 20).x == 0);
}

// ---- ParticleEmitter.space = screen -------------------------------------------------------------------------------------

namespace {

// One motionless 16 px dot, born by the initial burst (the emitter never emits again, the particle never fades).
Entity dot_emitter(World& w, Vec3 pos, RenderSpace space, Color c = Color::white()) {
    Entity e = make(w, "dot", pos);
    auto& p = w.add<ParticleEmitter>(e);
    p.emitting = false; p.rate = 0; p.burst = 1; p.lifetime = 100.0f; p.lifetimeVariance = 0; p.speed = 0;
    p.speedVariance = 0; p.spread = 0; p.gravity = {0, 0, 0}; p.startSize = p.endSize = 16; p.startColor = p.endColor = c;
    p.space = space;
    return e;
}

}  // namespace

TEST_CASE("particles: a screen-space emitter sits at its screen position whatever the camera does") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::black();
    dot_emitter(w, {60, 40, 0}, RenderSpace::Screen, Color{0, 1, 0, 1});   // screen pixel (60, 40)
    dot_emitter(w, {100, 50, 0}, RenderSpace::World, Color{1, 0, 0, 1});   // world (100, 50) = pixel (260, 40) for this camera
    Image home = g.render(w);
    CHECK(home.pixel(60, 40).g > 0.9f);   CHECK(home.pixel(60, 40).r < 0.1f);
    CHECK(home.pixel(60, 52).g < 0.05f);  CHECK(home.pixel(72, 40).g < 0.05f);   // a 16 px dot, not a bigger blob
    CHECK(home.pixel(260, 40).r > 0.9f);

    w.get<Transform>(cam)->position = {400, -250, 0};   // pan far away
    Image panned = g.render(w);
    CHECK(panned.pixel(60, 40).g > 0.9f);                // the HUD dot did not move
    CHECK(panned.pixel(260, 40).r < 0.05f);              // the world dot left the view with the camera
    for (int y = 0; y < panned.height; ++y)
        for (int x = 0; x < 200; ++x) REQUIRE(panned.pixel(x, y).g == home.pixel(x, y).g);
    CHECK(g.renderer.stats().particles == 2);
}

TEST_CASE("particles: in screen space direction 90 flies up the screen and negative gravity falls down it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::black();
    Entity up = dot_emitter(w, {100, 150, 0}, RenderSpace::Screen);       // default direction 90 = up, 100 px/s
    w.get<ParticleEmitter>(up)->speed = 100;
    Entity right = dot_emitter(w, {20, 90, 0}, RenderSpace::Screen);      // direction 0 = right
    w.get<ParticleEmitter>(right)->speed = 100;
    w.get<ParticleEmitter>(right)->direction = 0;
    Entity fall = dot_emitter(w, {220, 20, 0}, RenderSpace::Screen);      // negative gravity y = falling
    w.get<ParticleEmitter>(fall)->gravity = {0, -200, 0};
    Image img;
    for (int i = 0; i < 30; ++i) img = g.render(w, 1.0f / 60.0f);          // half a second
    CHECK(img.pixel(100, 100).r > 0.9f);   // 50 px above where it was born (screen y shrinks upwards)
    CHECK(img.pixel(100, 150).r < 0.05f);
    CHECK(img.pixel(70, 90).r > 0.9f);     // 50 px to the right
    CHECK(img.pixel(20, 90).r < 0.05f);
    CHECK(img.pixel(220, 46).r > 0.9f);    // fell ~26 px (0.5 * 200 * 0.5^2) down the screen
    CHECK(img.pixel(220, 14).r < 0.05f);
    CHECK(g.renderer.stats().particles == 3);
}

TEST_CASE("particles: screen-space anchor, worldSpace and is3D") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::black();
    // anchor: the position is relative to a screen point (like Sprite and Shape2D)
    Entity topRight = dot_emitter(w, {-20, 20, 0}, RenderSpace::Screen);
    w.get<ParticleEmitter>(topRight)->anchor = {1, 0};                     // pixel (300, 20)
    Entity centre = dot_emitter(w, {0, 0, 0}, RenderSpace::Screen);
    w.get<ParticleEmitter>(centre)->anchor = {0.5f, 0.5f};                 // pixel (160, 90)
    Entity bottomLeft = dot_emitter(w, {20, -10, 0}, RenderSpace::Screen);
    w.get<ParticleEmitter>(bottomLeft)->anchor = {0, 1};                   // pixel (20, 170)
    // worldSpace = true: particles stay where they were born; false: they follow the emitter
    Entity stay = dot_emitter(w, {60, 50, 0}, RenderSpace::Screen);
    Entity follow = dot_emitter(w, {60, 130, 0}, RenderSpace::Screen);
    w.get<ParticleEmitter>(follow)->worldSpace = false;
    Image before = g.render(w);
    CHECK(before.pixel(300, 20).r > 0.9f);  CHECK(before.pixel(160, 90).r > 0.9f);  CHECK(before.pixel(20, 170).r > 0.9f);
    CHECK(before.pixel(60, 50).r > 0.9f);   CHECK(before.pixel(60, 130).r > 0.9f);
    w.get<Transform>(stay)->position.x += 100;
    w.get<Transform>(follow)->position.x += 100;
    Image after = g.render(w);
    CHECK(after.pixel(60, 50).r > 0.9f);    CHECK(after.pixel(160, 50).r < 0.05f);    // stayed
    CHECK(after.pixel(160, 130).r > 0.9f);  CHECK(after.pixel(60, 130).r < 0.05f);    // followed
    CHECK(after.pixel(300, 20).r > 0.9f);                                               // the others did not move
}

TEST_CASE("particles: is3D ignores the screen space") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    World w;
    Entity cam = make(w, "cam", {0, 0, 5});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.clearColor = Color::black();
    Entity e = dot_emitter(w, {0, 0, 0}, RenderSpace::World);
    w.get<ParticleEmitter>(e)->is3D = true;
    w.get<ParticleEmitter>(e)->startSize = w.get<ParticleEmitter>(e)->endSize = 1.0f;
    Image world3d = g.render(w);
    CHECK(world3d.pixel(160, 90).r > 0.9f);
    w.get<ParticleEmitter>(e)->space = RenderSpace::Screen;   // documented: treated as world, the billboard stays put
    Image screen3d = g.render(w);
    CHECK(screen3d.rgba == world3d.rgba);
}
