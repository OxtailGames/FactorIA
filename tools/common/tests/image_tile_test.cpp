// Tiles for image documents (docs/IMAGES.md, "Tiles"): wrap-around editing (tile mode), the seam check, and the autotile set
// generator (image.tileset.*): exact mask -> tile mapping of the 16 and 47 sets, seed variations, rules file, staleness.
#include <doctest.h>

#include <set>

#include "asset_test_helpers.h"
#include "fa/core/json_schema.h"
#include "fa/scene/autotile.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/image_tile.h"
#include "fa/tooling/image_tileset.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "fa_test_paths.h"

using namespace fa;
using namespace fa::testing;
using namespace std::string_literals;

namespace {

constexpr const char* kDoc = "assets/art/t.image.json";
constexpr const char* kSet = "assets/art/ground.image.json";

std::string error_of(const CommandResult& r) { return r.error["message"].get<std::string>() + " " + r.error.value("hint", std::string()); }

Json read_doc(const AssetsProject& p, const char* rel = kDoc) { return parse_json(read_all(p.file(rel)), rel).value(); }

std::string rows_of(const Json& layer) {
    std::string out;
    for (const Json& r : layer["rows"]) out += r.get<std::string>() + "|";
    return out;
}

Json palette2() { return Json::array({{{"name", "a"}, {"color", "#202020"}}, {{"name", "b"}, {"color", "#e0e0e0"}}}); }

// a canvas of w x h with an empty indexed layer "s" and tile mode on (`tile` as image.tile.set takes it)
void make_tiled(const AssetsProject& p, int w, int h, Json tile = Json(true)) {
    p.ok("image.create", {{"path", kDoc}, {"width", w}, {"height", h}, {"palette", palette2()}, {"layers", Json::array({{{"kind", "indexed"}, {"name", "s"}, {"width", w}, {"height", h}}})}});
    if (!tile.is_null()) {
        Json a = {{"path", kDoc}};
        if (tile.is_object()) a.update(tile);
        p.ok("image.tile.set", a);
    }
}

std::string sheet_rows(const Json& doc) { return rows_of(doc["layers"][0]); }

}  // namespace

// ---- the pure functions ---------------------------------------------------------------------------------------------------------

TEST_CASE("tile_wrap moves a coordinate into its tile") {
    CHECK(tile_wrap(9, 0, 8) == 1);
    CHECK(tile_wrap(-1, 0, 8) == 7);
    CHECK(tile_wrap(-9, 0, 8) == 7);
    CHECK(tile_wrap(17, 8, 8) == 9);
    CHECK(tile_wrap(7, 8, 8) == 15);
}

TEST_CASE("check_tile_opposites: matching and mismatching sides, runs, tolerance and empty tiles") {
    Image img = make_image(8, 8, {50, 50, 50, 255});
    TileSeamReport r = check_tile_opposites(img, 8, 8, -1, true);
    CHECK(r.seamless());
    CHECK(r.tolerance == 0);
    CHECK(r.tilesChecked == 1);
    CHECK(r.seamsChecked == 2);
    CHECK(r.pixelPairs == 16);
    // the right column differs from the left one on rows 2 to 4
    for (int y = 2; y <= 4; ++y) fill_rect(img, 7, y, 1, 1, {200, 50, 50, 255});
    r = check_tile_opposites(img, 8, 8, -1, true);
    REQUIRE_FALSE(r.seamless());
    REQUIRE(r.bad.size() == 1);
    CHECK(r.bad[0].axis == "horizontal");
    CHECK(r.bad[0].mismatched == 3);
    CHECK(r.bad[0].length == 8);
    REQUIRE(r.bad[0].runs.size() == 1);
    CHECK(r.bad[0].runs[0] == std::pair<int, int>{2, 4});
    CHECK(r.bad[0].worst == 150);
    // a tolerance above the difference accepts it
    CHECK(check_tile_opposites(img, 8, 8, 150, true).seamless());
    CHECK_FALSE(check_tile_opposites(img, 8, 8, 149, true).seamless());
    // the bottom row against the top row
    Image img2 = make_image(8, 8, {50, 50, 50, 255});
    fill_rect(img2, 3, 7, 1, 1, {0, 0, 0, 255});
    r = check_tile_opposites(img2, 8, 8, 0, true);
    REQUIRE(r.bad.size() == 1);
    CHECK(r.bad[0].axis == "vertical");
    // a sheet of 4 x 4 tiles: only the tile with a mismatch is reported; a transparent tile is skipped
    Image sheet = make_image(8, 4);
    fill_rect(sheet, 0, 0, 4, 4, {9, 9, 9, 255});
    fill_rect(sheet, 3, 1, 1, 1, {99, 9, 9, 255});
    r = check_tile_opposites(sheet, 4, 4, 0, true);
    CHECK(r.tilesChecked == 1);
    CHECK(r.columns == 2);
    REQUIRE(r.bad.size() == 1);
    CHECK(r.bad[0].a == 0);
}

TEST_CASE("check_tile_opposites: the automatic tolerance follows the smoothness of the picture unless the colours are exact") {
    // a smooth horizontal gradient that does not wrap: the seam is the jump from the last to the first column
    Image grad = make_image(16, 4);
    for (int y = 0; y < 4; ++y)
        for (int x = 0; x < 16; ++x) fill_rect(grad, x, y, 1, 1, {std::uint8_t(x * 8), std::uint8_t(x * 8), std::uint8_t(x * 8), 255});
    const TileSeamReport soft = check_tile_opposites(grad, 16, 4, -1, false);
    CHECK(soft.toleranceAutomatic);
    CHECK(soft.tolerance > 0);
    CHECK_FALSE(soft.seamless());   // 120 apart is a real seam even for a soft picture
    CHECK(check_tile_opposites(grad, 16, 4, -1, true).tolerance == 0);
    CHECK_FALSE(check_tile_opposites(grad, 16, 4, -1, true).toleranceAutomatic == false);
    // a gradient that comes back (mirrored) is seamless
    for (int y = 0; y < 4; ++y)
        for (int x = 0; x < 16; ++x) {
            const int v = x < 8 ? x * 8 : (15 - x) * 8;
            fill_rect(grad, x, y, 1, 1, {std::uint8_t(v), std::uint8_t(v), std::uint8_t(v), 255});
        }
    CHECK(check_tile_opposites(grad, 16, 4, -1, false).seamless());
}

TEST_CASE("check_tile_set compares only the sides that touch in a map") {
    // two tiles, mask 4 (E neighbour) then mask 64 (W neighbour): tile 0's right column must meet tile 1's left column
    Image sheet = make_image(8, 4);
    fill_rect(sheet, 0, 0, 4, 4, {10, 10, 10, 255});
    fill_rect(sheet, 4, 0, 4, 4, {10, 10, 10, 255});
    TileSeamReport r = check_tile_set(sheet, 4, 4, 2, {kAutoE, kAutoW}, false, 0, true);
    CHECK(r.seamless());
    CHECK(r.seamsChecked >= 1);
    fill_rect(sheet, 4, 2, 1, 1, {200, 10, 10, 255});   // tile 1's left column differs on row 2
    r = check_tile_set(sheet, 4, 4, 2, {kAutoE, kAutoW}, false, 0, true);
    REQUIRE_FALSE(r.seamless());
    CHECK(r.bad[0].axis == "horizontal");
    CHECK(r.bad[0].a == 0);
    CHECK(r.bad[0].b == 1);
    // tile 1 does not say it has a west neighbour: the pair cannot stand side by side, so nothing is compared
    r = check_tile_set(sheet, 4, 4, 2, {kAutoE, 0}, false, 0, true);
    CHECK(r.seamless());
}

// ---- tile mode: the commands wrap ---------------------------------------------------------------------------------------------------

TEST_CASE("image.tile.set: the tile, a size that does not divide the canvas, and turning it off") {
    AssetsProject p;
    p.ok("image.create", {{"path", kDoc}, {"width", 16}, {"height", 8}, {"palette", palette2()}});
    Json r = p.ok("image.tile.set", {{"path", kDoc}});
    CHECK(r["tileMode"] == true);
    CHECK(r["tile"]["width"] == 16);
    CHECK(r["tile"]["columns"] == 1);
    CHECK(read_doc(p)["tile"] == true);
    r = p.ok("image.tile.set", {{"path", kDoc}, {"width", 8}, {"height", 8}});
    CHECK(r["tile"]["columns"] == 2);
    CHECK(read_doc(p)["tile"]["width"] == 8);
    const CommandResult bad = p.call("image.tile.set", {{"path", kDoc}, {"width", 5}});
    REQUIRE_FALSE(bad.ok);
    CHECK(error_of(bad).find("divide") != std::string::npos);
    CHECK(read_doc(p)["tile"]["width"] == 8);   // nothing was written
    p.ok("image.tile.set", {{"path", kDoc}, {"enabled", false}});
    CHECK_FALSE(read_doc(p).contains("tile"));
    CHECK_FALSE(p.call("image.tile.set", {{"path", kDoc}, {"enabled", false}, {"width", 4}}).ok);
}

TEST_CASE("tile mode: image.pixel wraps pixels, runs and stamps around the tile") {
    AssetsProject p;
    make_tiled(p, 8, 4);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({9, 0, 1}), Json::array({-1, 3, 1})})}});
    CHECK(sheet_rows(read_doc(p)) == ".1......|........|........|.......1|");
    // a run that leaves the right edge comes back in on the left
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"runs", Json::array({Json::array({6, 1, 4, 0})})}});
    CHECK(sheet_rows(read_doc(p)) == ".1......|00....00|........|.......1|");
    // a stamp too
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"stamp", {{"x", 6}, {"y", 2}, {"rows", Json::array({"111", "1.1"})}}}});
    CHECK(sheet_rows(read_doc(p)) == ".1......|00....00|1.....11|1.....11|");
    // without tile mode the same pixels fall outside the canvas
    p.ok("image.tile.set", {{"path", kDoc}, {"enabled", false}});
    const Json r = p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({9, 0, 1})})}});
    CHECK(has_warning(r, "outside"));
}

TEST_CASE("tile mode: a shape wraps inside the cell that holds its first point; a sheet of tiles wraps cell by cell") {
    AssetsProject p;
    make_tiled(p, 8, 4, {{"width", 4}, {"height", 4}});
    // a pixel just past the right edge of the first tile (x = 4 is the second tile): it is in the second tile's cell and wraps there
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({3, 0, 1}), Json::array({4, 1, 1}), Json::array({11, 2, 1}), Json::array({-1, 3, 1})})}});
    // (3,0) is in cell 0; (4,1) is in cell 1; (11,2) is in cell 2 -> clamped to the last cell, wraps to x = 7; (-1,3) is in cell 0 -> x = 3
    CHECK(sheet_rows(read_doc(p)) == "...1....|....1...|.......1|...1....|");
    // a rectangle starting in cell 0 wraps around cell 0 only
    p.ok("image.draw", {{"path", kDoc}, {"layer", "s"}, {"shapes", Json::array({Json::parse(R"({"type":"rect","x":2,"y":0,"width":3,"height":1,"fill":0,"color":0})")})}});
    const std::string rows = sheet_rows(read_doc(p));
    CHECK(rows.substr(0, 9) == "0.00....|");   // x 2, 3 and the wrapped 4 -> 0 of cell 0; cell 1 is untouched
}

TEST_CASE("tile mode: image.draw lines and fills wrap, and a fill flows around the edges") {
    AssetsProject p;
    make_tiled(p, 8, 4);
    p.ok("image.draw", {{"path", kDoc}, {"layer", "s"}, {"shapes", Json::array({Json::parse(R"({"type":"line","points":[[6,0],[9,0]],"color":1})")})}});
    CHECK(sheet_rows(read_doc(p)) == "11....11|........|........|........|");
    // a wall of pixels in the middle column: the fill from the left side reaches the right side through the edge
    p.ok("image.draw", {{"path", kDoc}, {"layer", "s"}, {"shapes", Json::array({Json::parse(R"({"type":"rect","x":3,"y":0,"width":1,"height":4,"fill":0,"color":0})"),
                                                                              Json::parse(R"({"type":"fill","at":[1,2],"color":1})")})}});
    // the fill started left of the wall: it spreads left, through the left edge to the right side, and stops at the wall
    CHECK(sheet_rows(read_doc(p)) == "11101111|11101111|11101111|11101111|");
}

TEST_CASE("tile mode: image.paint dabs wrap, and the move action wraps inside the tile") {
    AssetsProject p;
    p.ok("image.create", {{"path", kDoc}, {"width", 8}, {"height", 8}, {"layers", Json::array({{{"kind", "fill"}, {"color", "#ffffff"}}})}});
    p.ok("image.tile.set", {{"path", kDoc}});
    p.ok("image.paint", {{"path", kDoc}, {"layer", "ink"}, {"create", true}, {"strokes", Json::array({{{"points", {{0.5, 3.5}}}, {"size", 3}, {"color", "#ff0000"}}})}});
    Image img = read_png(p.file("assets/art/t.png"));
    CHECK(get(img, 0, 3) == Rgba{255, 0, 0, 255});
    CHECK(get(img, 7, 3) == Rgba{255, 0, 0, 255});    // the dab leaves the left edge and comes back on the right
    CHECK(get(img, 4, 3) == Rgba{255, 255, 255, 255});
    // move the selection 2 to the right: what leaves the right edge re-enters on the left
    p.ok("image.edit", {{"path", kDoc}, {"selection", "all"}, {"layer", "ink"}, {"action", {{"type", "move"}, {"dx", 2}, {"dy", 0}}}});
    img = read_png(p.file("assets/art/t.png"));
    CHECK(get(img, 1, 3) == Rgba{255, 0, 0, 255});    // x 7 -> 9 -> 1
    CHECK(get(img, 2, 3) == Rgba{255, 0, 0, 255});    // x 0 -> 2
    CHECK(get(img, 0, 3) == Rgba{255, 255, 255, 255});
    CHECK(get(img, 7, 3) == Rgba{255, 255, 255, 255});
}

TEST_CASE("tile mode: pixel helpers see across the tile edges") {
    AssetsProject p;
    make_tiled(p, 6, 6);
    // a 2 x 2 block split by the right and left edges: columns 5 and 0
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"stamp", {{"x", 5}, {"y", 2}, {"rows", Json::array({"11", "11"})}}}});
    CHECK(sheet_rows(read_doc(p)) == "......|......|1....1|1....1|......|......|");
    // the outline of the block closes around it through the edge
    p.ok("image.pixel.outline", {{"path", kDoc}, {"layer", "s"}, {"color", "a"}});
    const std::string rows = sheet_rows(read_doc(p));
    CHECK(rows == "......|0....0|10..01|10..01|0....0|......|");
}

TEST_CASE("tile mode: rotate and scale do not wrap and say so") {
    AssetsProject p;
    make_tiled(p, 8, 8);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({3, 3, 1})})}});
    Json r = p.ok("image.pixel.rotate", {{"path", kDoc}, {"layer", "s"}, {"angle", 90}});
    CHECK(has_warning(r, "wrap"));
    r = p.ok("image.pixel.scale", {{"path", kDoc}, {"layer", "s"}, {"factor", 2}});
    CHECK(has_warning(r, "wrap"));
    p.ok("image.tile.set", {{"path", kDoc}, {"enabled", false}});
    r = p.ok("image.pixel.rotate", {{"path", kDoc}, {"layer", "s"}, {"angle", 90}});
    CHECK_FALSE(has_warning(r, "wrap"));
}

// ---- the tileset generator ---------------------------------------------------------------------------------------------------------

namespace {

Json colour_part(const char* hex) { return Json::object({{"color", hex}}); }

// A set whose parts are flat colours: every quadrant of every tile shows one colour, so the mask -> part mapping can be read straight off the sheet.
Json flat_args(const std::string& mode, int variations = 1, long long seed = 0) {
    Json parts = {{"inside", colour_part("#00ff00")}, {"edge", colour_part("#0000ff")}, {"corner", colour_part("#ff0000")}};
    if (mode == "blob47") parts["innerCorner"] = colour_part("#ffff00");
    return {{"path", kSet}, {"mode", mode}, {"tileWidth", 8}, {"tileHeight", 8}, {"variations", variations}, {"seed", seed}, {"parts", parts}};
}

// The part a quadrant must show for the neighbours (bits of fa/scene/autotile.h) next to it: the rule of docs/IMAGES.md, "Tiles".
Rgba expected_quadrant(int mask, int vBit, int hBit, int dBit, bool blob) {
    const bool v = mask & vBit, h = mask & hBit;
    if (!v && !h) return {255, 0, 0, 255};        // corner
    if (!v || !h) return {0, 0, 255, 255};        // edge
    if (blob && !(mask & dBit)) return {255, 255, 0, 255};   // innerCorner
    return {0, 255, 0, 255};                      // inside
}

}  // namespace

TEST_CASE("image.tileset.build: the 47-tile set puts the right part in every quadrant of every tile") {
    AssetsProject p;
    const Json r = p.ok("image.tileset.build", flat_args("blob47"));
    CHECK(r["width"] == 64);    // 8 columns of 8
    CHECK(r["height"] == 48);   // 6 rows
    CHECK(r["tileset"]["layout"]["tiles"] == 47);
    const Image sheet = read_png(p.file("assets/art/ground.png"));
    const auto& masks = autotile_masks(AutotileMode::Blob47);
    REQUIRE(masks.size() == 47);
    for (int slot = 0; slot < 47; ++slot) {
        const int mask = masks[slot], tx = (slot % 8) * 8, ty = (slot / 8) * 8;
        INFO("slot " << slot << " mask " << mask);
        CHECK(get(sheet, tx + 1, ty + 1) == expected_quadrant(mask, kAutoN, kAutoW, kAutoNW, true));
        CHECK(get(sheet, tx + 6, ty + 1) == expected_quadrant(mask, kAutoN, kAutoE, kAutoNE, true));
        CHECK(get(sheet, tx + 1, ty + 6) == expected_quadrant(mask, kAutoS, kAutoW, kAutoSW, true));
        CHECK(get(sheet, tx + 6, ty + 6) == expected_quadrant(mask, kAutoS, kAutoE, kAutoSE, true));
    }
    // the whole-neighbourhood tile is the inside colour everywhere; the lone tile is the corner colour everywhere
    CHECK(get(sheet, 3, 3) == Rgba{255, 0, 0, 255});   // slot 0 = no neighbours
}

TEST_CASE("image.tileset.build: the 16-tile set has no inner corners") {
    AssetsProject p;
    const Json r = p.ok("image.tileset.build", flat_args("basic16"));
    CHECK(r["width"] == 32);    // 4 columns of 8
    CHECK(r["height"] == 32);
    const Image sheet = read_png(p.file("assets/art/ground.png"));
    const auto& masks = autotile_masks(AutotileMode::Basic16);
    REQUIRE(masks.size() == 16);
    for (int slot = 0; slot < 16; ++slot) {
        const int mask = masks[slot], tx = (slot % 4) * 8, ty = (slot / 4) * 8;
        INFO("slot " << slot << " mask " << mask);
        CHECK(get(sheet, tx + 1, ty + 1) == expected_quadrant(mask, kAutoN, kAutoW, kAutoNW, false));
        CHECK(get(sheet, tx + 6, ty + 6) == expected_quadrant(mask, kAutoS, kAutoE, kAutoSE, false));
    }
    // the rules: every slot maps to its own tile
    const Json rules = read_doc(p, "assets/art/ground.terrains.json");
    CHECK(rules["format"] == "factoria.terrains/1");
    CHECK(rules["terrains"][0]["mode"] == "basic16");
    CHECK(rules["terrains"][0]["tiles"].size() == 16);
    for (int i = 0; i < 16; ++i) CHECK(rules["terrains"][0]["tiles"][i] == i);
}

TEST_CASE("image.tileset.build: edges and corners are oriented by flipping the parts") {
    AssetsProject p;
    // the edge part: terrain below the top edge: a red top row, rows 1.. green. corner: a red top-left pixel.
    Json args = flat_args("basic16");
    Json edgeRows = Json::array(), cornerRows = Json::array(), insideRows = Json::array();
    for (int y = 0; y < 8; ++y) {
        edgeRows.push_back(y == 0 ? "00000000" : "11111111");
        insideRows.push_back("11111111");
        cornerRows.push_back(y == 0 ? "01111111" : "11111111");
    }
    args["palette"] = Json::array({"#ff0000", "#00ff00"});
    args["parts"] = {{"inside", {{"rows", insideRows}}}, {"edge", {{"rows", edgeRows}}}, {"corner", {{"rows", cornerRows}}}};
    p.ok("image.tileset.build", args);
    const Image sheet = read_png(p.file("assets/art/ground.png"));
    const Rgba red{255, 0, 0, 255}, green{0, 255, 0, 255};
    // masks of the four edges: terrain on three sides, the open side is the edge
    const auto& masks = autotile_masks(AutotileMode::Basic16);
    auto slot_of = [&](int mask) {
        for (int i = 0; i < 16; ++i)
            if (masks[i] == mask) return i;
        return -1;
    };
    const int top = slot_of(kAutoE | kAutoS | kAutoW), bottom = slot_of(kAutoN | kAutoE | kAutoW);
    const int left = slot_of(kAutoN | kAutoE | kAutoS), right = slot_of(kAutoN | kAutoS | kAutoW);
    REQUIRE(top >= 0);
    REQUIRE(bottom >= 0);
    REQUIRE(left >= 0);
    REQUIRE(right >= 0);
    auto at = [&](int slot, int x, int y) { return get(sheet, (slot % 4) * 8 + x, (slot / 4) * 8 + y); };
    CHECK(at(top, 2, 0) == red);       // the edge as drawn: its red row on top
    CHECK(at(top, 2, 1) == green);
    CHECK(at(bottom, 2, 7) == red);    // flipped: the red row at the bottom
    CHECK(at(bottom, 2, 6) == green);
    CHECK(at(left, 0, 3) == red);      // turned: the red column on the left
    CHECK(at(left, 1, 3) == green);
    CHECK(at(right, 7, 3) == red);
    CHECK(at(right, 6, 3) == green);
}

TEST_CASE("image.tileset.build: variations are chosen by the seed, deterministically") {
    AssetsProject a, b, c;
    auto make = [](AssetsProject& p, long long seed) {
        Json args = flat_args("basic16", 3, seed);
        args["parts"]["inside"] = Json::array({colour_part("#00ff00"), colour_part("#00dd00"), colour_part("#00bb00"), colour_part("#009900")});
        args["parts"]["edge"] = Json::array({colour_part("#0000ff"), colour_part("#0000dd"), colour_part("#0000bb")});
        return p.ok("image.tileset.build", args);
    };
    const Json r = make(a, 7);
    make(b, 7);
    make(c, 8);
    CHECK(r["tileset"]["layout"]["tiles"] == 48);    // 16 slots x 3 variations
    CHECK(read_all(a.file("assets/art/ground.png")) == read_all(b.file("assets/art/ground.png")));
    CHECK(read_all(a.file("assets/art/ground.png")) != read_all(c.file("assets/art/ground.png")));
    const Image sheet = read_png(a.file("assets/art/ground.png"));
    const auto& masks = autotile_masks(AutotileMode::Basic16);
    // variation 0 is the first variant of every part; tile = slot * 3 + variation
    auto tile_at = [&](int tile, int x, int y) {
        const int columns = r["tileset"]["layout"]["columns"].get<int>();
        return get(sheet, (tile % columns) * 8 + x, (tile / columns) * 8 + y);
    };
    int full = -1;
    for (int i = 0; i < 16; ++i)
        if (masks[i] == (kAutoN | kAutoE | kAutoS | kAutoW)) full = i;
    REQUIRE(full >= 0);
    CHECK(tile_at(full * 3, 4, 4) == Rgba{0, 255, 0, 255});
    std::set<std::uint32_t> insides;
    for (int v = 0; v < 3; ++v) {
        const Rgba c4 = tile_at(full * 3 + v, 4, 4);
        insides.insert(c4.r << 24 | c4.g << 16 | c4.b << 8 | c4.a);
    }
    CHECK(insides.size() >= 2);   // the other variations pick other variants
    // the rules list the variations of every slot, in order
    const Json rules = read_doc(a, "assets/art/ground.terrains.json");
    CHECK(rules["terrains"][0]["seed"] == 7);
    CHECK(rules["terrains"][0]["tiles"][full] == Json::array({full * 3, full * 3 + 1, full * 3 + 2}));
}

TEST_CASE("image.tileset.build: running it again updates the document in place; null removes a part; rules are recorded for regeneration") {
    AssetsProject p;
    p.ok("image.tileset.build", flat_args("blob47"));
    Json doc = read_doc(p, kSet);
    CHECK(doc["layers"].size() == 1);
    CHECK(doc["tile"]["width"] == 8);
    CHECK(doc["width"] == 64);
    // a second run with a new inside colour: same layer, same files, new pixels
    const Image before = read_png(p.file("assets/art/ground.png"));
    Json again = {{"path", kSet}, {"parts", {{"inside", colour_part("#123456")}}}};
    const Json r = p.ok("image.tileset.build", again);
    CHECK(r["tileset"]["created"] == false);
    doc = read_doc(p, kSet);
    CHECK(doc["layers"].size() == 1);
    CHECK(doc["layers"][0]["parts"]["edge"]["color"] == "#0000ff");   // untouched
    CHECK(doc["layers"][0]["parts"]["inside"]["color"] == "#123456");
    CHECK(read_png(p.file("assets/art/ground.png")).rgba != before.rgba);
    // a required part cannot be removed
    const CommandResult gone = p.call("image.tileset.build", {{"path", kSet}, {"parts", {{"corner", Json()}}}});
    REQUIRE_FALSE(gone.ok);
    CHECK(error_of(gone).find("corner") != std::string::npos);
    CHECK(read_doc(p, kSet)["layers"][0]["parts"].contains("corner"));   // nothing was written
    // an optional part can
    p.ok("image.tileset.build", {{"path", kSet}, {"parts", {{"edgeBottom", colour_part("#abcdef")}}}});
    CHECK(read_doc(p, kSet)["layers"][0]["parts"].contains("edgeBottom"));
    p.ok("image.tileset.build", {{"path", kSet}, {"parts", {{"edgeBottom", Json()}}}});
    CHECK_FALSE(read_doc(p, kSet)["layers"][0]["parts"].contains("edgeBottom"));
    // the manifest: the PNG is baked by image.bake, the rules by image.tileset.rules from the document
    const Json manifest = p.manifest();
    CHECK(manifest["assets"]["assets/art/ground.png"]["provenance"]["recipe"]["command"] == "image.bake");
    const Json rec = manifest["assets"]["assets/art/ground.terrains.json"]["provenance"]["recipe"];
    CHECK(rec["command"] == "image.tileset.rules");
    CHECK(rec["args"]["path"] == kSet);
    CHECK(rec["inputs"][0]["path"] == kSet);
}

TEST_CASE("image.tileset.build: a file that is not this layer's rules is not replaced without overwrite") {
    AssetsProject p;
    write_all(p.file("assets/art/ground.terrains.json"), "{\"mine\": true}");
    const CommandResult r = p.call("image.tileset.build", flat_args("basic16"));
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("overwrite") != std::string::npos);
    CHECK(read_all(p.file("assets/art/ground.terrains.json")) == "{\"mine\": true}");
    Json args = flat_args("basic16");
    args["overwrite"] = true;
    p.ok("image.tileset.build", args);
    CHECK(read_doc(p, "assets/art/ground.terrains.json")["format"] == "factoria.terrains/1");
    // another path for the rules
    Json other = flat_args("basic16");
    other["rules"] = "assets/art/other.terrains.json";
    p.ok("image.tileset.build", other);
    CHECK(p.exists("assets/art/other.terrains.json"));
    Json off = flat_args("basic16");
    off["path"] = "assets/art/nowrite.image.json";
    off["writeRules"] = false;
    p.ok("image.tileset.build", off);
    CHECK_FALSE(p.exists("assets/art/nowrite.terrains.json"));
}

TEST_CASE("image.tileset: parts that are PNG files make the bake stale when they change, and assets.regenerate makes the set again") {
    AssetsProject p;
    auto flat = [](Rgba c) { return make_image(8, 8, c); };
    write_png(p.file("assets/art/in.png"), flat({0, 255, 0, 255}));
    write_png(p.file("assets/art/ed.png"), flat({0, 0, 255, 255}));
    write_png(p.file("assets/art/co.png"), flat({255, 0, 0, 255}));
    Json args = {{"path", kSet}, {"mode", "basic16"}, {"tileWidth", 8}, {"parts", {{"inside", {{"source", "assets/art/in.png"}}}, {"edge", "assets/art/ed.png"}, {"corner", {{"source", "assets/art/co.png"}}}}}};
    const Json r = p.ok("image.tileset.build", args);
    CHECK(has_text(r["inputs"], "assets/art/in.png"));
    CHECK(image_bake_status(p.dir, kSet).state == ImageBakeState::Fresh);
    write_png(p.file("assets/art/in.png"), flat({0, 128, 0, 255}));
    CHECK(image_bake_status(p.dir, kSet).state == ImageBakeState::Stale);
    const Json regen = p.ok("assets.regenerate", {{"path", "assets/art/ground.png"}});
    CHECK(regen["count"] == 1);
    CHECK(image_bake_status(p.dir, kSet).state == ImageBakeState::Fresh);
    const Image sheet = read_png(p.file("assets/art/ground.png"));
    // slot 15 = all four neighbours: the inside
    const auto& masks = autotile_masks(AutotileMode::Basic16);
    for (int i = 0; i < 16; ++i)
        if (masks[i] == (kAutoN | kAutoE | kAutoS | kAutoW)) CHECK(get(sheet, (i % 4) * 8 + 4, (i / 4) * 8 + 4) == Rgba{0, 128, 0, 255});
    // the rules file is regenerated through its own recipe, after the document changes
    Json edited = read_doc(p, kSet);
    edited["layers"][0]["seed"] = 5;
    write_all(p.file(kSet), edited.dump(2));
    const Json rules = p.ok("assets.regenerate", {{"path", "assets/art/ground.terrains.json"}});
    CHECK(rules["count"] == 1);
    CHECK(read_doc(p, "assets/art/ground.terrains.json")["terrains"][0]["seed"] == 5);
}

TEST_CASE("image.tileset: project.validate accepts the set, its rules file and its recipes") {
    TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    CommandRegistry registry;
    register_asset_commands(registry, dir);
    CommandResult built = registry.call("image.tileset.build", flat_args("blob47"));
    REQUIRE_MESSAGE(built.ok, built.error.dump());
    const ValidationReport r = validate_project(dir);
    CHECK_MESSAGE(r.ok, r.to_text());
    for (const ValidationIssue& w : r.warnings) CHECK_MESSAGE(w.file.find("ground") == std::string::npos, w.message);
}

TEST_CASE("image.tileset.build and the document parser teach: missing parts, a wrong mode, an odd tile, a size that is not even") {
    AssetsProject p;
    Json noParts = {{"path", kSet}, {"mode", "blob47"}, {"tileWidth", 8}};
    CommandResult r = p.call("image.tileset.build", noParts);
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("parts") != std::string::npos);
    CHECK_FALSE(p.exists(kSet));   // a failed build writes nothing
    Json missing = flat_args("blob47");
    missing["parts"].erase("innerCorner");
    r = p.call("image.tileset.build", missing);
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("innerCorner") != std::string::npos);
    Json mode = flat_args("blob47");
    mode["mode"] = "blob48";
    r = p.call("image.tileset.build", mode);
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("blob47") != std::string::npos);   // did you mean
    Json odd = flat_args("blob47");
    odd["tileWidth"] = 7;
    r = p.call("image.tileset.build", odd);
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("even") != std::string::npos);
    Json unknownPart = flat_args("basic16");
    unknownPart["parts"]["insidee"] = colour_part("#000000");
    r = p.call("image.tileset.build", unknownPart);
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("inside") != std::string::npos);
    // a part picture of the wrong size says so with the pointer of the part
    write_png(p.file("assets/art/big.png"), make_image(16, 16, {1, 2, 3, 255}));
    Json big = flat_args("basic16");
    big["parts"]["inside"] = {{"source", "assets/art/big.png"}};
    r = p.call("image.tileset.build", big);
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("/parts/inside") != std::string::npos);
    CHECK(error_of(r).find("16 x 16") != std::string::npos);
    // a tile that is not square needs edgeLeft
    Json wide = flat_args("basic16");
    wide["tileHeight"] = 4;
    r = p.call("image.tileset.build", wide);
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("edgeLeft") != std::string::npos);
    // the sheet may not exceed the largest picture
    Json huge = flat_args("blob47", 8);
    huge["tileWidth"] = 64;
    huge["tileHeight"] = 64;
    huge["columns"] = 1;
    r = p.call("image.tileset.build", huge);
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("columns") != std::string::npos);
}

TEST_CASE("image.tileset.check: seamless parts pass, a part that does not meet its neighbours fails with the tiles named, files of the wrong size are listed") {
    AssetsProject p;
    // an inside tile of one colour, an edge whose top row is a different colour, a corner that continues it
    const Json palette = Json::array({"#336633", "#99cc99", "#ff00ff"});
    Json good = {{"path", kSet}, {"mode", "basic16"}, {"tileWidth", 8}, {"tileHeight", 8}, {"palette", palette}};
    Json insideRows = Json::array(), edgeRows = Json::array(), cornerRows = Json::array();
    for (int y = 0; y < 8; ++y) {
        insideRows.push_back("11111111");
        edgeRows.push_back(y < 2 ? "........" : (y == 2 ? "00000000" : "11111111"));
        cornerRows.push_back(y < 2 ? "........" : (y == 2 ? "..000000" : "..011111"));
    }
    good["parts"] = {{"inside", {{"rows", insideRows}}}, {"edge", {{"rows", edgeRows}}}, {"corner", {{"rows", cornerRows}}}};
    p.ok("image.tileset.build", good);
    Json r = p.ok("image.tileset.check", {{"path", kSet}});
    CHECK(r["ok"] == true);
    INFO(r["problems"].dump());
    CHECK(r["seamless"] == true);
    CHECK(r["tolerance"] == 0);    // a palette: pixel art, the colours must be equal
    CHECK(p.exists(".factoria/previews/assets/art/ground.image.json.tilesetcheck.png"));
    CHECK(r.contains("$image"));
    // break the edge: its last pixel of the line is another colour, so the line breaks where two tiles touch
    Json broken = good;
    broken["parts"]["edge"]["rows"][2] = "00000002";
    p.ok("image.tileset.build", broken);
    r = p.ok("image.tileset.check", {{"path", kSet}});
    CHECK(r["ok"] == true);
    CHECK(r["seamless"] == false);
    REQUIRE(r["problems"].size() >= 1);
    CHECK(r["problems"][0]["message"].get<std::string>().find("does not match") != std::string::npos);
    CHECK(r["problems"][0]["a"].contains("neighbours"));
    CHECK(r["badSeams"].get<int>() >= 1);
    // a tolerance above every difference accepts it
    CHECK(p.ok("image.tileset.check", {{"path", kSet}, {"tolerance", 255}})["seamless"] == true);
    // a PNG part that changed to the wrong size is listed, not a thrown error
    write_png(p.file("assets/art/small.png"), make_image(4, 4, {1, 2, 3, 255}));
    Json f = read_doc(p, kSet);
    f["layers"][0]["parts"]["inside"] = {{"source", "assets/art/small.png"}};
    write_all(p.file(kSet), f.dump(2));
    r = p.ok("image.tileset.check", {{"path", kSet}});
    CHECK(r["ok"] == false);
    REQUIRE(r["issues"].size() == 1);
    CHECK(r["issues"][0]["pointer"] == "/layers/0/parts/inside/source");
    CHECK(r["issues"][0]["message"].get<std::string>().find("4 x 4") != std::string::npos);
    // not a tileset document
    p.ok("image.create", {{"path", kDoc}, {"width", 4}, {"height", 4}});
    const CommandResult none = p.call("image.tileset.check", {{"path", kDoc}});
    REQUIRE_FALSE(none.ok);
    CHECK(error_of(none).find("image.tileset.build") != std::string::npos);
}

TEST_CASE("image.tile.check: reports the seams with canvas coordinates, writes the preview, and uses the document's tile size") {
    AssetsProject p;
    make_tiled(p, 8, 4, {{"width", 4}, {"height", 4}});
    // a dot at the right edge of the first tile with no partner at its left edge
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({3, 1, 1})})}});
    Json r = p.ok("image.tile.check", {{"path", kDoc}});
    CHECK(r["seamless"] == false);
    CHECK(r["tile"]["width"] == 4);
    CHECK(r["tile"]["columns"] == 2);
    CHECK(r["tolerance"] == 0);    // a palette: exact
    REQUIRE(r["problems"].size() == 1);
    CHECK(r["problems"][0]["tile"] == 0);
    CHECK(r["problems"][0]["axis"] == "horizontal");
    CHECK(r["problems"][0]["columns"] == Json::array({3, 0}));
    CHECK(r["problems"][0]["rows"] == Json::array({Json::array({1, 1})}));
    CHECK(r["problems"][0]["sides"] == "right column against left column");
    CHECK(p.exists(".factoria/previews/assets/art/t.image.json.tilecheck.png"));
    CHECK(r.contains("$image"));
    // with the partner pixel drawn, it is seamless
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({0, 1, 1})})}});
    CHECK(p.ok("image.tile.check", {{"path", kDoc}})["seamless"] == true);
    // sizes are checked against the picture
    const CommandResult bad = p.call("image.tile.check", {{"path", kDoc}, {"tileWidth", 3}});
    REQUIRE_FALSE(bad.ok);
    CHECK(error_of(bad).find("whole number of times") != std::string::npos);
    // an empty picture has nothing to compare
    p.ok("image.create", {{"path", "assets/art/e.image.json"}, {"width", 4}, {"height", 4}});
    r = p.ok("image.tile.check", {{"path", "assets/art/e.image.json"}});
    CHECK(has_warning(r, "empty"));
}

TEST_CASE("image.tileset.info: the parts of a mode, and the tiles of a tileset layer") {
    AssetsProject p;
    Json r = p.ok("image.tileset.info", {{"mode", "basic16"}});
    CHECK(r["requiredParts"] == Json::array({"inside", "edge", "corner"}));
    CHECK(r["slots"].size() == 16);
    bool hasInner = false;
    for (const Json& part : r["parts"])
        if (part["name"] == "innerCorner") hasInner = true;
    CHECK_FALSE(hasInner);
    r = p.ok("image.tileset.info", {{"mode", "blob47"}});
    CHECK(r["requiredParts"] == Json::array({"inside", "edge", "corner", "innerCorner"}));
    CHECK(r["slots"].size() == 47);
    CHECK(r["parts"][0]["diagram"].size() == 4);
    CHECK_FALSE(p.call("image.tileset.info", {{"mode", "blob48"}}).ok);
    p.ok("image.tileset.build", flat_args("basic16", 2));
    r = p.ok("image.tileset.info", {{"path", kSet}});
    CHECK(r["layout"]["tiles"] == 32);
    CHECK(r["tiles"].size() == 32);
    CHECK(r["tiles"][3]["slot"] == 1);
    CHECK(r["tiles"][3]["variation"] == 1);
}

TEST_CASE("image schema: the tile key and the tileset layer, as the code writes them, validate") {
    AssetsProject p;
    auto schema = parse_json(read_all(std::filesystem::path(FA_REPO_ROOT) / "schemas" / "image.schema.json"), "image.schema.json");
    REQUIRE(schema.ok());
    CHECK(std::find((*schema)["$defs"]["layer"]["properties"]["kind"]["enum"].begin(), (*schema)["$defs"]["layer"]["properties"]["kind"]["enum"].end(), Json("tileset")) !=
          (*schema)["$defs"]["layer"]["properties"]["kind"]["enum"].end());
    Json args = flat_args("blob47", 2, 3);
    args["parts"]["edge"] = Json::array({colour_part("#0000ff"), colour_part("#0000dd")});
    p.ok("image.tileset.build", args);
    const Json built = read_doc(p, kSet);
    CHECK(validate_json(*schema, built).empty());
    make_tiled(p, 8, 8, {{"width", 4}, {"height", 4}});
    CHECK(validate_json(*schema, read_doc(p)).empty());
    Json bad = read_doc(p);
    bad["tile"] = "yes";
    CHECK_FALSE(validate_json(*schema, bad).empty());
    Json badSet = built;
    badSet["layers"][0]["mode"] = "blob48";
    CHECK_FALSE(validate_json(*schema, badSet).empty());
}
