#include <doctest.h>

#include <set>

#include "fa/scene/autotile.h"

using namespace fa;

namespace {

Tilemap grass_map(int w, int h, const char* terrainsJson = R"([{"name":"grass","mode":"blob47","first":100}])") {
    Tilemap tm;
    tm.width = w;
    tm.height = h;
    tm.tileSize = {16, 16};
    std::vector<int> empty(std::size_t(w) * std::size_t(h), -1);
    set_tilemap_grid(tm, w, h, empty);
    tm.terrains = Json::parse(terrainsJson);
    return tm;
}

std::vector<std::pair<int, int>> rect(int x, int y, int w, int h) {
    std::vector<std::pair<int, int>> out;
    for (int r = y; r < y + h; ++r)
        for (int c = x; c < x + w; ++c) out.push_back({c, r});
    return out;
}

int at(const Tilemap& tm, int c, int r) { return tilemap_tile_at(tm, tilemap_size(tm), c, r); }

const TilemapIssue* issue(const std::vector<TilemapIssue>& v, const std::string& pointer) {
    for (const TilemapIssue& i : v)
        if (i.pointer == pointer) return &i;
    return nullptr;
}

}  // namespace

TEST_CASE("autotile: the 47 blob masks and the 16 basic masks, exactly") {
    const std::vector<int> blob = {0,   1,   4,   5,   7,   16,  17,  20,  21,  23,  28,  29,  31,  64,  65,  68,
                                   69,  71,  80,  81,  84,  85,  87,  92,  93,  95,  112, 113, 116, 117, 119, 124,
                                   125, 127, 193, 197, 199, 209, 213, 215, 221, 223, 241, 245, 247, 253, 255};
    CHECK(autotile_masks(AutotileMode::Blob47) == blob);
    CHECK(autotile_tile_count(AutotileMode::Blob47) == 47);
    const std::vector<int> basic = {0, 1, 4, 5, 16, 17, 20, 21, 64, 65, 68, 69, 80, 81, 84, 85};
    CHECK(autotile_masks(AutotileMode::Basic16) == basic);

    // a diagonal counts only with both orthogonals next to it
    CHECK(autotile_reduce(AutotileMode::Blob47, kAutoN | kAutoE | kAutoNE) == (kAutoN | kAutoE | kAutoNE));
    CHECK(autotile_reduce(AutotileMode::Blob47, kAutoN | kAutoNE) == kAutoN);
    CHECK(autotile_reduce(AutotileMode::Blob47, kAutoNE | kAutoSE | kAutoSW | kAutoNW) == 0);
    CHECK(autotile_reduce(AutotileMode::Blob47, 255) == 255);
    CHECK(autotile_reduce(AutotileMode::Basic16, 255) == (kAutoN | kAutoE | kAutoS | kAutoW));

    // every raw mask lands on a slot whose mask is its reduction
    std::set<int> used;
    for (int raw = 0; raw < 256; ++raw) {
        const int slot = autotile_slot(AutotileMode::Blob47, raw);
        REQUIRE(slot >= 0);
        REQUIRE(slot < 47);
        CHECK(blob[std::size_t(slot)] == autotile_reduce(AutotileMode::Blob47, raw));
        used.insert(slot);
    }
    CHECK(used.size() == 47);
    // basic16: slot = N*1 + E*2 + S*4 + W*8
    CHECK(autotile_slot(AutotileMode::Basic16, 0) == 0);
    CHECK(autotile_slot(AutotileMode::Basic16, kAutoN) == 1);
    CHECK(autotile_slot(AutotileMode::Basic16, kAutoE) == 2);
    CHECK(autotile_slot(AutotileMode::Basic16, kAutoS) == 4);
    CHECK(autotile_slot(AutotileMode::Basic16, kAutoW) == 8);
    CHECK(autotile_slot(AutotileMode::Basic16, 255) == 15);
    CHECK(autotile_slot(AutotileMode::Blob47, 0) == 0);
    CHECK(autotile_slot(AutotileMode::Blob47, 255) == 46);
}

TEST_CASE("autotile: the variation hash depends on seed, column and row only") {
    CHECK(autotile_hash(5, 3, 4) == autotile_hash(5, 3, 4));
    CHECK(autotile_hash(5, 3, 4) != autotile_hash(6, 3, 4));
    std::set<std::uint32_t> seen;
    for (int r = 0; r < 8; ++r)
        for (int c = 0; c < 8; ++c) seen.insert(autotile_hash(1, c, r));
    CHECK(seen.size() > 60);
}

TEST_CASE("autotile: painting a block draws edges, corners and the inside") {
    Tilemap tm = grass_map(5, 5);
    auto r = paint_terrain(tm, "grass", rect(1, 1, 3, 3));
    REQUIRE(r.ok());
    CHECK(r->painted == 9);
    const auto& masks = autotile_masks(AutotileMode::Blob47);
    auto slot_of = [&](int mask) { return int(std::lower_bound(masks.begin(), masks.end(), mask) - masks.begin()); };
    // the centre has all 8 neighbours; the top-left corner has E, SE, S; the top edge has E, SE, S, SW, W
    CHECK(at(tm, 2, 2) == 100 + slot_of(255));
    CHECK(at(tm, 1, 1) == 100 + slot_of(kAutoE | kAutoSE | kAutoS));
    CHECK(at(tm, 2, 1) == 100 + slot_of(kAutoE | kAutoSE | kAutoS | kAutoSW | kAutoW));
    CHECK(at(tm, 3, 3) == 100 + slot_of(kAutoN | kAutoNW | kAutoW));
    CHECK(at(tm, 0, 0) == -1);
    CHECK(at(tm, 4, 4) == -1);
}

TEST_CASE("autotile: painting a cell next to a terrain cell re-tiles the neighbours and reports them") {
    Tilemap tm = grass_map(4, 1);
    REQUIRE(paint_terrain(tm, "grass", {{1, 0}}).ok());
    CHECK(at(tm, 1, 0) == 100);  // alone
    auto r = paint_terrain(tm, "grass", {{2, 0}});
    REQUIRE(r.ok());
    const auto& masks = autotile_masks(AutotileMode::Blob47);
    auto slot_of = [&](int mask) { return int(std::lower_bound(masks.begin(), masks.end(), mask) - masks.begin()); };
    CHECK(at(tm, 1, 0) == 100 + slot_of(kAutoE));
    CHECK(at(tm, 2, 0) == 100 + slot_of(kAutoW));
    // the neighbour (1,0) changed besides the painted cell
    bool neighbour = false;
    for (const TerrainChange& c : r->changes)
        if (c.col == 1 && c.row == 0) neighbour = c.from == 100 && c.to == 100 + slot_of(kAutoE);
    CHECK(neighbour);
    // erasing empties the cell and the neighbour goes back to alone
    auto e = paint_terrain(tm, "grass", {{2, 0}}, true);
    REQUIRE(e.ok());
    CHECK(at(tm, 2, 0) == -1);
    CHECK(at(tm, 1, 0) == 100);
}

TEST_CASE("autotile: basic16 uses the four neighbours only") {
    Tilemap tm = grass_map(3, 3, R"([{"name":"wall","mode":"basic16","first":10}])");
    REQUIRE(paint_terrain(tm, "wall", rect(0, 0, 3, 3)).ok());
    CHECK(at(tm, 1, 1) == 10 + 15);
    CHECK(at(tm, 0, 0) == 10 + 2 + 4);      // E and S
    CHECK(at(tm, 2, 2) == 10 + 1 + 8);      // N and W
    CHECK(at(tm, 1, 0) == 10 + 2 + 4 + 8);  // E, S, W
}

TEST_CASE("autotile: outside=terrain removes the border at the map edge; joins connect terrains") {
    Tilemap tm = grass_map(3, 1, R"([{"name":"sea","mode":"basic16","first":0,"outside":"terrain"}])");
    REQUIRE(paint_terrain(tm, "sea", rect(0, 0, 3, 1)).ok());
    CHECK(at(tm, 1, 0) == 15);
    CHECK(at(tm, 0, 0) == 15);

    Tilemap two = grass_map(3, 1,
                            R"([{"name":"grass","mode":"basic16","first":0,"joins":["path"]},
                                {"name":"path","mode":"basic16","first":16,"joins":["grass"]}])");
    REQUIRE(paint_terrain(two, "grass", {{0, 0}}).ok());
    REQUIRE(paint_terrain(two, "path", {{1, 0}}).ok());
    CHECK(at(two, 0, 0) == 0 + 2);   // grass sees the path to its east
    CHECK(at(two, 1, 0) == 16 + 8);  // path sees the grass to its west
}

TEST_CASE("autotile: terrains without joins ignore each other") {
    Tilemap tm = grass_map(3, 1,
                           R"([{"name":"grass","mode":"basic16","first":0},
                               {"name":"water","mode":"basic16","first":16}])");
    REQUIRE(paint_terrain(tm, "grass", {{0, 0}, {1, 0}}).ok());
    REQUIRE(paint_terrain(tm, "water", {{2, 0}}).ok());
    CHECK(at(tm, 1, 0) == 0 + 8);  // only its west neighbour is grass
    CHECK(at(tm, 2, 0) == 16);
}

TEST_CASE("autotile: variations are picked by seed, column and row, always the same") {
    const char* rules =
        R"([{"name":"grass","mode":"basic16","seed":3,"tiles":[[0,100,200],1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]}])";
    Tilemap a = grass_map(16, 16, rules), b = grass_map(16, 16, rules);
    REQUIRE(paint_terrain(a, "grass", {{0, 0}}).ok());  // slot 0: alone
    // many lone cells (every other cell, so no neighbours) show all three variations
    std::vector<std::pair<int, int>> lone;
    for (int r = 0; r < 16; r += 2)
        for (int c = 0; c < 16; c += 2) lone.push_back({c, r});
    REQUIRE(paint_terrain(a, "grass", lone).ok());
    REQUIRE(paint_terrain(b, "grass", lone).ok());
    std::set<int> seen;
    for (const auto& c : lone) {
        CHECK(at(a, c.first, c.second) == at(b, c.first, c.second));  // deterministic
        seen.insert(at(a, c.first, c.second));
    }
    CHECK(seen == std::set<int>{0, 100, 200});
    // another seed gives another picture
    Tilemap c = grass_map(
        16, 16,
        R"([{"name":"grass","mode":"basic16","seed":4,"tiles":[[0,100,200],1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]}])");
    REQUIRE(paint_terrain(c, "grass", lone).ok());
    bool differs = false;
    for (const auto& cell : lone) differs = differs || at(a, cell.first, cell.second) != at(c, cell.first, cell.second);
    CHECK(differs);
    // a cell keeps its variation when its neighbours change around it and come back
    Tilemap d = grass_map(16, 16, rules);
    REQUIRE(paint_terrain(d, "grass", lone).ok());
    const int before = at(d, 4, 4);
    REQUIRE(paint_terrain(d, "grass", {{5, 4}}).ok());
    REQUIRE(paint_terrain(d, "grass", {{5, 4}}, true).ok());
    CHECK(at(d, 4, 4) == before);
}

TEST_CASE("autotile: retile fixes a map whose tiles were written by hand") {
    Tilemap tm = grass_map(3, 1, R"([{"name":"g","mode":"basic16","first":0}])");
    set_tilemap_tile(tm, 0, 0, 0);
    set_tilemap_tile(tm, 1, 0, 0);
    set_tilemap_tile(tm, 2, 0, 0);
    auto r = retile_terrains(tm);
    REQUIRE(r.ok());
    CHECK(at(tm, 0, 0) == 2);
    CHECK(at(tm, 1, 0) == 2 + 8);
    CHECK(at(tm, 2, 0) == 8);
    CHECK(r->changes.size() == 3);
}

TEST_CASE("autotile: flip flags of a terrain tile are kept") {
    Tilemap tm =
        grass_map(1, 1, R"([{"name":"g","mode":"basic16","tiles":[268435456,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]}])");
    REQUIRE(paint_terrain(tm, "g", {{0, 0}}).ok());
    CHECK(at(tm, 0, 0) == kTileFlipX);
    CHECK(terrain_of_tile(*parse_terrains(tm.terrains), at(tm, 0, 0)).terrain == "g");
}

TEST_CASE("autotile: cells outside the map are skipped and counted") {
    Tilemap tm = grass_map(2, 2);
    auto r = paint_terrain(tm, "grass", {{0, 0}, {5, 5}, {-1, 0}});
    REQUIRE(r.ok());
    CHECK(r->painted == 1);
    CHECK(r->outside == 2);
}

TEST_CASE("autotile: errors name the terrain, the pointer and the fix") {
    Tilemap tm = grass_map(2, 2);
    auto unknown = paint_terrain(tm, "gras", {{0, 0}});
    REQUIRE_FALSE(unknown.ok());
    CHECK(unknown.error().message.find("Unknown terrain 'gras'") != std::string::npos);
    CHECK(unknown.error().hint.find("grass") != std::string::npos);

    Tilemap none = grass_map(2, 2, "[]");
    auto r = paint_terrain(none, "grass", {{0, 0}});
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().hint.find("terrains") != std::string::npos);

    Tilemap nomap;
    nomap.terrains = Json::parse(R"([{"name":"g","mode":"blob47","first":0}])");
    auto empty = paint_terrain(nomap, "g", {{0, 0}});
    REQUIRE_FALSE(empty.ok());
    CHECK(empty.error().message.find("no cells") != std::string::npos);

    auto bad = check_terrains(Json::parse(R"([{"name":"g","mode":"blob48","first":0},
                                              {"name":"h","mode":"blob47","tiles":[1,2,3]},
                                              {"name":"h","mode":"basic16","first":0,"jions":[]},
                                              {"mode":"basic16","first":0},
                                              {"name":"x","mode":"basic16"},
                                              {"name":"y","mode":"basic16","first":0,"joins":["zz"]},
                                              {"name":"s","mode":"basic16","first":5.5}])"));
    const TilemapIssue* mode = issue(bad, "/terrains/0/mode");
    REQUIRE(mode);
    CHECK(mode->hint.find("blob47") != std::string::npos);  // did you mean
    const TilemapIssue* count = issue(bad, "/terrains/1/tiles");
    REQUIRE(count);
    CHECK(count->message.find("47") != std::string::npos);
    CHECK(issue(bad, "/terrains/2/jions"));
    CHECK(issue(bad, "/terrains/2/name"));  // duplicate
    CHECK(issue(bad, "/terrains/3/name"));
    CHECK(issue(bad, "/terrains/4"));  // no tiles
    CHECK(issue(bad, "/terrains/5/joins"));
    CHECK(issue(bad, "/terrains/6/first"));

    auto shared = check_terrains(
        Json::parse(R"([{"name":"a","mode":"basic16","first":0},{"name":"b","mode":"basic16","first":10}])"));
    REQUIRE(shared.size() == 1);
    CHECK(shared[0].pointer == "/terrains/1/tiles");
    CHECK(shared[0].message.find("belongs to both") != std::string::npos);

    CHECK(check_terrains(Json::array()).empty());
    CHECK(issue(check_terrains(Json::parse("{}")), "/terrains"));
}

TEST_CASE("autotile: check_tilemap reports bad terrains with the component pointer") {
    Tilemap tm = grass_map(2, 2, R"([{"name":"g","mode":"blob99","first":0}])");
    auto issues = check_tilemap(tm);
    REQUIRE(issue(issues, "/terrains/0/mode"));
    CHECK(check_tilemap(grass_map(2, 2)).empty());
}
