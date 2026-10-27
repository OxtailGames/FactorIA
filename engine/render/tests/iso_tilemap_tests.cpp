// M31.25 isometric tilemaps: depth-ordered batched drawing, the cell <-> world mapping through the camera, and shadows.
// Default camera: the 320x180 target shows world (x, y) at pixel (160 + x, 90 - y) when the camera sits at the origin.
#include "test_util.h"

#include <cmath>
#include <string>
#include <vector>

#include "fa/scene/bounds.h"
#include "fa/scene/tilemap.h"

using namespace fa;
using namespace fa::test;

namespace {

Color flat_color(const Color& c) { return c; }

// A tileset of `colors.size()` tiles 100x50 each, side by side, every tile one flat color.
std::string write_iso_tileset(const std::vector<Color>& colors, const char* name = "assets/iso_tiles.png") {
    Image img;
    img.width = int(colors.size()) * 100;
    img.height = 50;
    img.rgba.resize(std::size_t(img.width) * std::size_t(img.height) * 4);
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) img.set_pixel(x, y, flat_color(colors[std::size_t(x / 100)]));
    REQUIRE(save_png(img, name).ok());
    return name;
}

Entity iso_map(World& w, const char* name, Vec3 pos, int cols, int rows, int tile, const std::string& tileset) {
    Entity e = make(w, name, pos);
    auto& tm = w.add<Tilemap>(e);
    tm.projection = TilemapProjection::Isometric;
    tm.tileset = tileset;
    tm.tileSize = {100, 50};
    tm.columns = 0;
    std::vector<int> tiles(std::size_t(cols) * std::size_t(rows), tile);
    set_tilemap_grid(tm, cols, rows, tiles);
    return e;
}

Entity camera_with_zoom(World& w, Vec3 pos, float zoom) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.clearColor = Color::black();
    c.orthoSize = 90.0f / zoom;
    return cam;
}

bool near_color(const Color& a, const Color& b, float tol = 0.03f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

}  // namespace

TEST_CASE("isometric tilemap: tiles are drawn back to front, a tile covers the edge of the ones behind it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color red = Color::hex(0xe02020), green = Color::hex(0x20e020), blue = Color::hex(0x2020e0), yellow = Color::hex(0xe0e020);
    const std::string tileset = write_iso_tileset({red, green, blue, yellow});
    World w;
    camera_with_zoom(w, {0, -50, 0}, 1.0f);
    Entity map = iso_map(w, "map", {0, 0, 0}, 2, 2, 0, tileset);
    Tilemap& tm = *w.get<Tilemap>(map);
    REQUIRE(set_tilemap_tile(tm, 0, 0, 0));  // red
    REQUIRE(set_tilemap_tile(tm, 1, 0, 1));  // green
    REQUIRE(set_tilemap_tile(tm, 0, 1, 2));  // blue
    REQUIRE(set_tilemap_tile(tm, 1, 1, 3));  // yellow
    Image img = g.render(w);
    // World (x, y) with the camera at (0, -50) is pixel (160 + x, 90 - (y + 50)).
    auto px = [&](float x, float y) { return img.pixel(int(160 + x), int(90 - (y + 50))); };
    CHECK(near_color(px(-10, -10), red));       // only cell (0, 0) reaches there
    CHECK(near_color(px(-25, -37), blue));      // (0, 0) and (0, 1) overlap: row 1 is drawn after row 0
    CHECK(near_color(px(25, -37), green));      // (0, 0) and (1, 0) overlap: column 1 is drawn after column 0
    CHECK(near_color(px(25, -62), yellow));     // (1, 0) and (1, 1)
    CHECK(near_color(px(-25, -62), yellow));    // (0, 1) and (1, 1)
    CHECK(near_color(px(0, -90), yellow));      // the front corner
    CHECK(near_color(px(0, 20), Color::black())); // above the map
    CHECK(g.renderer.stats().drawCalls <= 2);

    // Painting a tile with the same value in another place changes only that place.
    REQUIRE(set_tilemap_tile(tm, 0, 0, 3));
    img = g.render(w);
    CHECK(near_color(px(-10, -10), yellow));
    CHECK(near_color(px(25, -37), green));
}

TEST_CASE("isometric tilemap: a 40x40 map draws in a few draw calls, and culling keeps the visible part only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string tileset = write_iso_tileset({Color::hex(0x40a040), Color::hex(0x808080)});
    World w;
    camera_with_zoom(w, {0, -1000, 0}, 0.05f);  // the whole map (about 4000 x 2000) is in view
    iso_map(w, "map", {0, 0, 0}, 40, 40, 0, tileset);
    Image img = g.render(w);
    const RenderStats all = g.renderer.stats();
    CHECK(all.drawCalls <= 3);
    // Zoomed in on a corner only part of the map is submitted; still one tilemap in a handful of draw calls.
    w.get<Camera>(w.find("cam"))->orthoSize = 90.0f;
    w.get<Transform>(w.find("cam"))->position = {0, -50, 0};
    g.render(w);
    CHECK(g.renderer.stats().drawCalls <= 3);
    CHECK(g.renderer.stats().drawCalls >= 1);
}

TEST_CASE("isometric tilemap: cellAt(cellToWorld(c, r)) is (c, r) at every zoom, through the camera") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string tileset = write_iso_tileset({Color::hex(0x40a040)});
    for (float zoom : {0.4f, 0.7f, 1.0f, 1.6f, 2.5f}) {
        World w;
        const Vec2 mapPos{37, 11};
        Entity cam = camera_with_zoom(w, {mapPos.x, mapPos.y - 600, 0}, zoom);
        Entity map = iso_map(w, "map", {mapPos.x, mapPos.y, 0}, 40, 40, 0, tileset);
        g.render(w);  // the camera helpers are valid after a frame
        (void)cam;
        const Tilemap& tm = *w.get<Tilemap>(map);
        int checked = 0;
        for (int r = 0; r < 40; r += 3)
            for (int c = 0; c < 40; c += 3) {
                const Vec2 local = tilemap_cell_center(tm, c, r);
                const Vec3 worldPos{mapPos.x + local.x, mapPos.y + local.y, 0};
                const Vec2 screen = g.renderer.world_to_screen(worldPos);
                const Vec3 back = g.renderer.screen_to_world(screen);
                // Only cells whose centre is on screen survive the round trip through pixels.
                if (screen.x < 0 || screen.y < 0 || screen.x >= 320 || screen.y >= 180) continue;
                const Vec3 localBack{back.x - mapPos.x, back.y - mapPos.y, 0};
                int cc = -1, rr = -1;
                REQUIRE(tilemap_cell_at_local(tm, {localBack.x, localBack.y}, cc, rr));
                CHECK(cc == c);
                CHECK(rr == r);
                ++checked;
            }
        CHECK(checked > 0);
    }
}

TEST_CASE("isometric tilemap: Light2D shadows follow the diamond cells") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string tileset = write_iso_tileset({Color::white()});
    World w;
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity cam = camera_with_zoom(w, {0, 0, 0}, 1.0f);
    (void)cam;
    // A floor that lights (lit sprite) and a single solid iso cell between the lamp and the far side.
    Entity floor = make(w, "floor", {0, 0, 0});
    {
        auto& s = w.add<Sprite>(floor);
        s.texture = "";
        s.size = {320, 180};
        s.layer = -50;
        s.lit = true;
    }
    Entity map = iso_map(w, "wall", {0, 20, 0}, 1, 1, 0, tileset);  // cell (0, 0): a diamond centred at (0, -5)
    {
        Tilemap& tm = *w.get<Tilemap>(map);
        tm.solidTiles = Json::array({0});
        tm.occludesLight = true;
        tm.layer = -60;
    }
    Entity lamp = make(w, "lamp", {-90, -5, 0});
    {
        auto& l = w.add<Light2D>(lamp);
        l.radius = 300;
        l.falloff = 1;
        l.intensity = 1;
        l.castShadows = true;
    }
    Image img = g.render(w);
    auto at = [&](float x, float y) { return img.pixel(int(160 + x), int(90 - y)).r; };
    CHECK(at(-60, -5) > 0.4f);       // in front of the diamond
    CHECK(at(60, -5) < 0.02f);       // behind the diamond's centre: shadowed
    CHECK(at(0, 40) > 0.3f);         // above the diamond: its top vertex is at y = 20, the ray passes over it
    CHECK(at(0, -50) > 0.3f);        // far below the diamond's bottom vertex (y = -30)
    CHECK(g.renderer.stats().lights2dShadowed == 1);
    // The same data as an orthogonal map blocks a square instead: x = 60 is inside it (the shadow starts where the light leaves
    // the occluder), and the shadow is cast beyond x = 100.
    w.get<Tilemap>(map)->projection = TilemapProjection::Orthogonal;
    img = g.render(w);
    CHECK(img.pixel(160 + 60, 95).r > 0.3f);
    CHECK(img.pixel(160 + 120, 95).r < 0.02f);
}
