// M18 2D features: flipped and rotated tiles, 9-slice sprites, lit sprites with normal maps (Light2D), parallax layers.
// Default camera: the 320x180 target shows world (x, y) at pixel (160 + x, 90 - y).
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <string>

#include "fa/scene/bounds.h"
#include "fa/scene/tilemap.h"

using namespace fa;
using namespace fa::test;

namespace {

bool near(const Color& a, const Color& b, float tol = 0.03f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

Entity camera_at(World& w, Vec3 pos = {0, 0, 0}) {
    Entity cam = make(w, "cam", pos);
    w.add<Camera>(cam).clearColor = Color::black();
    return cam;
}

void save(const Image& img, const char* path) { REQUIRE(save_png(img, path).ok()); }

// 16x16 tile whose quadrants are red (top-left), green (top-right), blue (bottom-left) and yellow (bottom-right).
Image quadrant_tile() {
    Image img;
    img.width = img.height = 16;
    img.rgba.resize(16 * 16 * 4);
    const Color c[4] = {Color::hex(0xe02020), Color::hex(0x20e020), Color::hex(0x2020e0), Color::hex(0xe0e020)};
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 16; ++x) img.set_pixel(x, y, c[(y / 8) * 2 + x / 8]);
    return img;
}

// 24x24 texture: four 8x8 corners with different checker patterns, dark-rimmed edges, flat centre (as the UI 9-slice test).
Image nine_slice_texture() {
    Image img;
    img.width = img.height = 24;
    img.rgba.resize(24 * 24 * 4);
    const Color corner[4] = {Color::hex(0xe04040), Color::hex(0x40e040), Color::hex(0x4040e0), Color::hex(0xe0e040)};
    for (int y = 0; y < 24; ++y)
        for (int x = 0; x < 24; ++x) {
            const int cx = x / 8, cy = y / 8;
            Color c;
            if (cx != 1 && cy != 1) {
                c = corner[(cy / 2) * 2 + cx / 2];
                if (((x % 8) / 2 + (y % 8) / 2) % 2 == 1) c = Color{c.r * 0.5f, c.g * 0.5f, c.b * 0.5f, 1};
            } else if (cx == 1 && cy == 1) {
                c = Color::hex(0xd8d8b0);
            } else {
                const int rim = cy == 0 ? y : cy == 2 ? 23 - y : cx == 0 ? x : 23 - x;
                c = rim < 2 ? Color::hex(0x202020) : Color::hex(0x808080);
            }
            img.set_pixel(x, y, c);
        }
    return img;
}

Image solid(int w, int h, Color c) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * std::size_t(h) * 4);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) img.set_pixel(x, y, c);
    return img;
}

// A normal map that tilts every normal towards +x of the picture by 45 degrees.
Image tilted_normal_map(int w, int h) {
    return solid(w, h, Color{(0.7071f + 1) * 0.5f, 0.5f, (0.7071f + 1) * 0.5f, 1});
}

}  // namespace

// ------------------------------------------------------------------------------------------------------ tile flags

TEST_CASE("tile flags: make_tile composes turns and mirrors, tile_index/tile_flags take them apart") {
    CHECK(make_tile(5) == 5);
    CHECK(make_tile(5, 1) == 5 + 1342177280);
    CHECK(make_tile(5, 2) == 5 + 805306368);
    CHECK(make_tile(5, 3) == 5 + 1610612736);
    CHECK(make_tile(5, 0, true) == 5 + kTileFlipX);
    CHECK(make_tile(5, 0, false, true) == 5 + kTileFlipY);
    CHECK(make_tile(5, -1) == make_tile(5, 3));
    CHECK(make_tile(5, 2, true, true) == 5);  // a half turn undone by both mirrors
    CHECK(make_tile(-1, 1) == -1);
    CHECK(tile_index(make_tile(77, 1, true)) == 77);
    CHECK(tile_flags(77) == 0);
    CHECK(tile_index(-1) == -1);
    CHECK(tile_flags(-1) == 0);
}

TEST_CASE("tile flags: flipped and rotated tiles are drawn turned") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(quadrant_tile(), "assets/quadrants.png");
    World w;
    camera_at(w);
    Entity map = make(w, "map", {-160, 90, 0});
    auto& tm = w.add<Tilemap>(map);
    tm.tileset = "assets/quadrants.png";
    tm.tileSize = {16, 16};
    // plain, flipX, flipY, 90 cw, 180, 90 ccw, transpose (a mirror across the diagonal)
    const int flags[7] = {0, kTileFlipX, kTileFlipY, kTileTranspose | kTileFlipX, kTileFlipX | kTileFlipY,
                          kTileTranspose | kTileFlipY, kTileTranspose};
    Json row = Json::array();
    for (int f : flags) row.push_back(f);
    tm.tiles = Json::array({row});
    const Color R = Color::hex(0xe02020), G = Color::hex(0x20e020), B = Color::hex(0x2020e0), Y = Color::hex(0xe0e020);
    // expected [TL, TR, BL, BR] of each tile
    const Color expect[7][4] = {{R, G, B, Y}, {G, R, Y, B}, {B, Y, R, G}, {B, R, Y, G}, {Y, B, G, R}, {G, Y, R, B}, {R, B, G, Y}};
    Image img = g.render(w);
    for (int t = 0; t < 7; ++t)
        for (int q = 0; q < 4; ++q) {
            INFO("tile " << t << " quadrant " << q);
            CHECK(near(img.pixel(t * 16 + (q % 2) * 8 + 4, (q / 2) * 8 + 4), expect[t][q]));
        }
    // the helper builds the same values: a 90 degree turn then a left-right mirror is the diagonal mirror
    CHECK(make_tile(0, 1, true) == kTileTranspose);
    CHECK(make_tile(0, 1) == flags[3]);
    CHECK(make_tile(0, 3) == flags[5]);
    expect_golden(img, "2d_tile_flags");
}

TEST_CASE("tile flags: a flipped solid tile is still solid, validation reads the index only") {
    Tilemap tm;
    tm.tileSize = {16, 16};
    tm.width = 2;
    tm.height = 1;
    tm.tiles = Json::array({make_tile(3, 1), make_tile(3, 0, true, true)});
    tm.solidTiles = Json::array({3});
    CHECK(check_tilemap(tm).empty());
    const TilemapGrid grid = tilemap_grid(tm);
    CHECK(tile_index(grid.at(0, 0)) == 3);
    CHECK(tile_index(grid.at(1, 0)) == 3);
    CHECK(tile_flags(grid.at(0, 0)) == (kTileTranspose | kTileFlipX));
    tm.tiles = Json::array({3000000000.0});
    CHECK_FALSE(check_tilemap(tm).empty());  // beyond index + three flags
}

// ----------------------------------------------------------------------------------------------------- 9-slice sprites

TEST_CASE("9-slice sprite: corners keep their texture size at any sprite size, flips mirror them") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image tex = nine_slice_texture();
    save(tex, "assets/sprite_nine.png");
    World w;
    camera_at(w);
    struct Spot { float x, y, width, height; bool flipX, flipY; };
    const Spot spots[4] = {{10, 10, 40, 40, false, false}, {60, 10, 100, 60, false, false}, {10, 80, 90, 90, true, false},
                           {110, 80, 90, 90, false, true}};
    for (const Spot& s : spots) {
        Entity e = make(w, "nine", {s.x - 160, 90 - s.y, 0});  // pivot top-left at pixel (x, y)
        auto& sp = w.add<Sprite>(e);
        sp.texture = "assets/sprite_nine.png";
        sp.slice = {8, 8, 8, 8};
        sp.size = {s.width, s.height};
        sp.pivot = {0, 1};
        sp.flipX = s.flipX;
        sp.flipY = s.flipY;
    }
    Image img = g.render(w);
    for (const Spot& s : spots) {
        const int x0 = int(s.x), y0 = int(s.y), x1 = int(s.x + s.width) - 8, y1 = int(s.y + s.height) - 8;
        for (int j = 0; j < 8; ++j)
            for (int i = 0; i < 8; ++i) {
                INFO("sprite " << x0 << "," << y0 << " pixel " << i << "," << j);
                // The texture pixel shown at a corner pixel: mirrored when the sprite is flipped.
                auto src = [&](int cornerX, int cornerY, int px, int py) {
                    int tx = cornerX * 16 + px, ty = cornerY * 16 + py;  // unflipped source pixel of that corner
                    if (s.flipX) tx = (1 - cornerX) * 16 + (7 - px);
                    if (s.flipY) ty = (1 - cornerY) * 16 + (7 - py);
                    return tex.pixel(tx, ty);
                };
                CHECK(near(img.pixel(x0 + i, y0 + j), src(0, 0, i, j)));
                CHECK(near(img.pixel(x1 + i, y0 + j), src(1, 0, i, j)));
                CHECK(near(img.pixel(x0 + i, y1 + j), src(0, 1, i, j)));
                CHECK(near(img.pixel(x1 + i, y1 + j), src(1, 1, i, j)));
            }
        // the middle is the stretched centre colour
        CHECK(near(img.pixel(x0 + int(s.width) / 2, y0 + int(s.height) / 2), Color::hex(0xd8d8b0)));
    }
    expect_golden(img, "2d_sprite_nine_slice");
}

TEST_CASE("9-slice sprite: slices are measured inside the region") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // The 24x24 frame sits at x = 24 of a 48x24 sheet whose left half is plain magenta.
    Image sheet = solid(48, 24, Color::hex(0xff00ff));
    const Image frame = nine_slice_texture();
    for (int y = 0; y < 24; ++y)
        for (int x = 0; x < 24; ++x) sheet.set_pixel(24 + x, y, frame.pixel(x, y));
    save(sheet, "assets/sprite_nine_sheet.png");
    World w;
    camera_at(w);
    Entity e = make(w, "nine", {-100, 40, 0});
    auto& sp = w.add<Sprite>(e);
    sp.texture = "assets/sprite_nine_sheet.png";
    sp.region = {24, 0, 24, 24};
    sp.slice = {8, 8, 8, 8};
    sp.size = {80, 50};
    sp.pivot = {0, 1};
    Image img = g.render(w);
    const int x0 = 60, y0 = 50;  // pixel of the top-left corner
    for (int j = 0; j < 8; ++j)
        for (int i = 0; i < 8; ++i) {
            CHECK(near(img.pixel(x0 + i, y0 + j), frame.pixel(i, j)));
            CHECK(near(img.pixel(x0 + 80 - 8 + i, y0 + 50 - 8 + j), frame.pixel(16 + i, 16 + j)));
        }
    for (int y = y0; y < y0 + 50; ++y)
        for (int x = x0; x < x0 + 80; ++x) CHECK(img.pixel(x, y).g > 0.1f);  // never the magenta of the neighbouring frame (g = 0)
}

TEST_CASE("9-slice sprite: borders that do not fit shrink together") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(nine_slice_texture(), "assets/sprite_nine.png");
    World w;
    camera_at(w);
    Entity e = make(w, "tiny", {0, 0, 0});
    auto& sp = w.add<Sprite>(e);
    sp.texture = "assets/sprite_nine.png";
    sp.slice = {8, 8, 8, 8};
    sp.size = {8, 8};  // smaller than left + right
    Image img = g.render(w);
    CHECK(near(img.pixel(156, 86), nine_slice_texture().pixel(2, 2), 0.2f));  // some corner pixel, not a stretched centre
    CHECK(img.pixel(170, 86).r < 0.05f);                                      // nothing outside the 8x8 box
}

// ------------------------------------------------------------------------------------------------------- lit sprites

namespace {

Entity lit_sprite(World& w, const char* normalMap, Vec3 pos, Vec2 size = {32, 32}) {
    Entity e = make(w, "lit", pos);
    auto& sp = w.add<Sprite>(e);
    sp.texture = "assets/white16.png";
    sp.size = size;
    sp.lit = true;
    sp.normalMap = normalMap;
    return e;
}

Entity sun(World& w, float directionDeg, float elevationDeg, float intensity = 1.0f) {
    Entity e = make(w, "sun");
    auto& l = w.add<Light2D>(e);
    l.type = Light2DType::Directional;
    l.direction = directionDeg;
    l.elevation = elevationDeg;
    l.intensity = intensity;
    return e;
}

float brightness(const Image& img, int x, int y) { return img.pixel(x, y).r; }

}  // namespace

TEST_CASE("lit sprites: a point light fades with distance, unlit sprites ignore it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(solid(16, 16, Color::white()), "assets/white16.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity wall = lit_sprite(w, "", {0, 0, 0}, {240, 60});
    (void)wall;
    Entity plain = make(w, "plain", {0, 70, 0});
    auto& ps = w.add<Sprite>(plain);
    ps.texture = "assets/white16.png";
    ps.size = {240, 20};
    Entity lamp = make(w, "lamp", {-50, 0, 0});
    auto& l = w.add<Light2D>(lamp);
    l.radius = 100;
    l.falloff = 1;
    l.intensity = 1;
    Image img = g.render(w);
    CHECK(brightness(img, 110, 90) == doctest::Approx(1.0f).epsilon(0.03));   // at the lamp
    CHECK(brightness(img, 160, 90) == doctest::Approx(0.5f).epsilon(0.03));   // 50 units away: (1 - 50/100)
    CHECK(brightness(img, 190, 90) == doctest::Approx(0.2f).epsilon(0.05));   // 80 away
    CHECK(brightness(img, 215, 90) < 0.02f);                                  // beyond the radius
    CHECK(brightness(img, 160, 90 - 70) == doctest::Approx(1.0f).epsilon(0.02));  // the unlit sprite keeps its colour
}

TEST_CASE("lit sprites: ambient light, light colour and intensity") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(solid(16, 16, Color::white()), "assets/white16.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0.2f, 0.1f, 0.0f, 1};
    lit_sprite(w, "", {0, 0, 0});
    Image img = g.render(w);
    CHECK(near(img.pixel(160, 90), Color{0.2f, 0.1f, 0.0f, 1}));  // no Light2D: only the ambient
    Entity s = sun(w, 270, 90, 0.5f);
    w.get<Light2D>(s)->color = Color{0, 1, 0, 1};
    img = g.render(w);
    CHECK(near(img.pixel(160, 90), Color{0.2f, 0.6f, 0.0f, 1}));  // ambient + the green sun at half strength, flat sprite
}

TEST_CASE("lit sprites: the normal map turns with the sprite's rotation and flips") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(solid(16, 16, Color::white()), "assets/white16.png");
    save(tilted_normal_map(16, 16), "assets/normal_tilt_x.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    // Light travelling left (comes from +x) 30 degrees above the picture: L = (cos 30, 0, sin 30).
    sun(w, 180, 30);
    const Vec3 L{std::cos(radians(30.0f)), 0.0f, std::sin(radians(30.0f))};
    struct Case { float rotation; bool flipX, flipY; };
    const Case cases[6] = {{0, false, false}, {0, true, false}, {90, false, false}, {180, false, false}, {90, false, true}, {-90, true, false}};
    std::vector<float> expected;
    for (int i = 0; i < 6; ++i) {
        Entity e = lit_sprite(w, "assets/normal_tilt_x.png", {-125.0f + 50.0f * float(i), 0, 0});
        w.get<Transform>(e)->rotation.z = cases[i].rotation;
        w.get<Sprite>(e)->flipX = cases[i].flipX;
        w.get<Sprite>(e)->flipY = cases[i].flipY;
        // First principles: the map tilts towards the picture's right edge; that edge points along rotation (mirrored by flipX).
        const float a = radians(cases[i].rotation);
        const float dir = cases[i].flipX ? -1.0f : 1.0f;
        const Vec2 right{dir * std::cos(a), dir * std::sin(a)};
        expected.push_back(std::max(0.0f, 0.7071f * (right.x * L.x + right.y * L.y) + 0.7071f * L.z));
    }
    Image img = g.render(w);
    for (int i = 0; i < 6; ++i) {
        INFO("case " << i << " rotation " << cases[i].rotation << " flipX " << cases[i].flipX << " flipY " << cases[i].flipY);
        CHECK(brightness(img, 35 + 50 * i, 90) == doctest::Approx(expected[std::size_t(i)]).epsilon(0.06));
    }
    CHECK(expected[0] > 0.9f);
    CHECK(expected[1] < 0.3f);  // the mirrored sprite faces away from the sun
}

TEST_CASE("lit sprites: golden - a dome normal map under a point light and a sun") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // 64x64 dome (hemisphere) normal map and a warm stone-coloured diffuse.
    Image normals = solid(64, 64, Color{0.5f, 0.5f, 1.0f, 1});
    Image diffuse = solid(64, 64, Color::hex(0xc8b08c));
    for (int y = 0; y < 64; ++y)
        for (int x = 0; x < 64; ++x) {
            const float nx = (float(x) + 0.5f - 32.0f) / 28.0f, ny = -(float(y) + 0.5f - 32.0f) / 28.0f;  // +y up the picture
            const float r2 = nx * nx + ny * ny;
            if (r2 < 1.0f) {
                const float nz = std::sqrt(1.0f - r2);
                normals.set_pixel(x, y, Color{(nx + 1) * 0.5f, (ny + 1) * 0.5f, (nz + 1) * 0.5f, 1});
            } else {
                diffuse.set_pixel(x, y, Color::hex(0x786450));
            }
        }
    save(normals, "assets/dome_n.png");
    save(diffuse, "assets/dome_d.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0.12f, 0.12f, 0.2f, 1};
    for (int i = 0; i < 3; ++i) {
        Entity e = make(w, "dome", {-90.0f + 90.0f * float(i), 0, 0});
        auto& sp = w.add<Sprite>(e);
        sp.texture = "assets/dome_d.png";
        sp.normalMap = "assets/dome_n.png";
        sp.size = {64, 64};
        sp.lit = i != 2;  // the right one is unlit for comparison
        sp.pixelArt = false;
        if (i == 1) w.get<Transform>(e)->rotation.z = 90;
    }
    Entity lamp = make(w, "lamp", {-60, 30, 0});
    auto& l = w.add<Light2D>(lamp);
    l.color = Color{1.0f, 0.85f, 0.6f, 1};
    l.radius = 220;
    l.height = 40;
    l.intensity = 1.1f;
    sun(w, 225, 50, 0.35f);
    Image img = g.render(w);
    expect_golden(img, "2d_lit_normal_map");
}

TEST_CASE("lit tilemaps: a tilemap is shaded and a rotated tile turns its normals") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(solid(16, 16, Color::white()), "assets/white16.png");
    save(tilted_normal_map(16, 16), "assets/normal_tilt_x.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    sun(w, 180, 30);
    Entity map = make(w, "map", {-160, 90, 0});
    auto& tm = w.add<Tilemap>(map);
    tm.tileset = "assets/white16.png";
    tm.normalMap = "assets/normal_tilt_x.png";
    tm.lit = true;
    tm.tileSize = {16, 16};
    tm.tiles = Json::array({Json::array({0, make_tile(0, 1), make_tile(0, 2), make_tile(0, 0, true)})});
    Image img = g.render(w);
    const Vec3 L{std::cos(radians(30.0f)), 0.0f, std::sin(radians(30.0f))};
    // tile 0 faces the sun, 1 (90 cw: right edge points down) is lit by L.z only, 2 (180) and 3 (mirrored) face away
    const float s = 0.7071f;
    CHECK(brightness(img, 8, 8) == doctest::Approx(s * L.x + s * L.z).epsilon(0.06));
    CHECK(brightness(img, 24, 8) == doctest::Approx(s * L.z).epsilon(0.08));
    CHECK(brightness(img, 40, 8) == doctest::Approx(std::max(0.0f, -s * L.x + s * L.z)).epsilon(0.1));
    CHECK(brightness(img, 56, 8) == doctest::Approx(std::max(0.0f, -s * L.x + s * L.z)).epsilon(0.1));
}

// ----------------------------------------------------------------------------------------------------------- parallax

namespace {

Entity block(World& w, Vec3 pos, Vec2 size, Color c, Vec2 factor) {
    Entity e = make(w, "layer", pos);
    auto& sp = w.add<Sprite>(e);
    sp.size = size;
    sp.color = c;
    w.add<Parallax>(e).factor = factor;
    return e;
}

}  // namespace

TEST_CASE("parallax: layers follow the camera by their factor") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera_at(w, {100, 0, 0});
    block(w, {0, 40, 0}, {10, 10}, Color::hex(0xff0000), {1, 1});      // normal object: world x 0
    block(w, {0, 0, 0}, {10, 10}, Color::hex(0x00ff00), {0.5f, 0.5f});  // drawn at world x 50
    block(w, {0, -40, 0}, {10, 10}, Color::hex(0x0000ff), {0, 0});     // glued to the camera: drawn at world x 100
    block(w, {0, 70, 0}, {10, 10}, Color::hex(0xffff00), {2, 1});       // foreground: drawn at world x -100
    Image img = g.render(w);
    // pixel x = 160 + (world x - camera x)
    CHECK(near(img.pixel(60, 90 - 40), Color::hex(0xff0000)));
    CHECK(near(img.pixel(110, 90), Color::hex(0x00ff00)));
    CHECK(near(img.pixel(160, 90 + 40), Color::hex(0x0000ff)));
    // the entity's own position did not change, bounds() reports where it is drawn
    for (Entity e : w.entities()) {
        const Parallax* p = w.get<Parallax>(e);
        if (!p) continue;
        const Vec3 pos = w.get<Transform>(e)->position;
        const std::optional<Rect> box = entity_world_rect(w, e);
        REQUIRE(box.has_value());
        CHECK(box->x + 5 == doctest::Approx(pos.x + 100 * (1 - p->factor.x)));
        CHECK(p->offset.x == doctest::Approx(100 * (1 - p->factor.x)));
    }
}

TEST_CASE("parallax: a repeating strip never runs out and the result is deterministic") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // 20x20 tile: left half orange, right half dark.
    Image strip = solid(20, 20, Color::hex(0x303040));
    for (int y = 0; y < 20; ++y)
        for (int x = 0; x < 10; ++x) strip.set_pixel(x, y, Color::hex(0xff8000));
    save(strip, "assets/strip.png");
    auto scene = [&](World& w, float camX) {
        camera_at(w, {camX, 0, 0});
        Entity e = make(w, "hills", {0, -60, 0});
        auto& sp = w.add<Sprite>(e);
        sp.texture = "assets/strip.png";
        sp.pivot = {0, 0.5f};
        auto& pa = w.add<Parallax>(e);
        pa.factor = {0.5f, 1};
        pa.repeatX = true;
        block(w, {-100, 60, 0}, {20, 20}, Color::hex(0x20c0ff), {0.8f, 1});
    };
    World a, b;
    scene(a, 0);
    scene(b, 0);
    Image ia = g.render(a), ib = g.render(b);
    CHECK(diff_images(ia, ib, 0.0f).differingPixels == 0);
    // Along the strip row (world y -60 = pixel y 150) the 20-unit pattern repeats across the whole width.
    for (int x = 0; x < 320; ++x) {
        const bool orange = (x % 20) < 10;
        INFO("camera 0, pixel x " << x);
        CHECK(near(ia.pixel(x, 150), orange ? Color::hex(0xff8000) : Color::hex(0x303040)));
    }
    // Camera at x = 37: the strip moves half as far (18.5 units left).
    World c;
    scene(c, 37);
    Image ic = g.render(c);
    for (int x = 0; x < 320; ++x) {
        const float worldX = float(x) - 160.0f + 37.0f;                // the world position under the pixel
        const float local = worldX - 37.0f * 0.5f;                     // minus the strip's drawn offset (camera * (1 - 0.5))
        const float m = local - 20.0f * std::floor(local / 20.0f);     // position within its 20-unit period
        if (std::fabs(m - 10.0f) < 1.0f || m < 1.0f || m > 19.0f) continue;  // skip the pixel seams
        INFO("camera 37, pixel x " << x);
        CHECK(near(ic.pixel(x, 150), m < 10.0f ? Color::hex(0xff8000) : Color::hex(0x303040)));
    }
    expect_golden(ic, "2d_parallax");
}

TEST_CASE("lit shapes: shaded by Light2D and the ambient light, unlit shapes keep their colour (golden)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0.15f, 0.15f, 0.2f, 1};
    const ShapeType kinds[5] = {ShapeType::Rectangle, ShapeType::Circle, ShapeType::Triangle, ShapeType::Star, ShapeType::Line};
    for (int row = 0; row < 2; ++row)  // top row lit, bottom row unlit
        for (int i = 0; i < 5; ++i) {
            Entity e = make(w, "shape", {-112.0f + 56.0f * float(i), row == 0 ? 36.0f : -36.0f, 0});
            auto& sh = w.add<Shape2D>(e);
            sh.shape = kinds[i];
            sh.size = kinds[i] == ShapeType::Line ? Vec2{40, 40} : Vec2{44, 44};
            sh.color = Color{0.9f, 0.6f, 0.3f, 1};
            sh.filled = i != 1 || row == 1;  // the lit circle is an outline ring
            sh.thickness = 6;
            sh.lit = row == 0;
        }
    Entity lamp = make(w, "lamp", {-60, 36, 0});
    auto& l = w.add<Light2D>(lamp);
    l.radius = 200;
    l.intensity = 1.0f;
    Image img = g.render(w);
    // Lit rectangle near the lamp: darker than its colour, brighter than the ambient light alone; the one below is not
    // lit: exactly its colour.
    CHECK(img.pixel(48, 54).r > 0.35f);
    CHECK(img.pixel(48, 54).r < 0.85f);
    CHECK(near(img.pixel(48, 126), Color{0.9f, 0.6f, 0.3f, 1}));
    // The lit star on the far side is out of the lamp's reach: only the ambient light (0.15, 0.15, 0.2).
    CHECK(near(img.pixel(272, 54), Color{0.9f * 0.15f, 0.6f * 0.15f, 0.3f * 0.2f, 1}, 0.03f));
    expect_golden(img, "2d_lit_shapes");
}
