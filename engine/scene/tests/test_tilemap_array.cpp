// Tilemap::tiles as a flat fa::ArrayI32 (M94.2b): the rows form of a file, the errors, the stamps caches compare.
#include <doctest.h>

#include <span>
#include <utility>
#include <vector>

#include "fa/scene/serialize.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

Json scene_with_tilemap(const std::string& fieldsJson) {
    return Json::parse(R"({"version":1,"entities":[{"id":"map","components":{"Tilemap":)" + fieldsJson + "}}]}");
}

std::vector<std::int32_t> tiles_vec(const Tilemap& tm) {
    return std::vector<std::int32_t>(tm.tiles.cdata(), tm.tiles.cdata() + tm.tiles.size());
}

}  // namespace

TEST_CASE("tilemap array: a file's rows form is flattened at load and saved flat") {
    World w;
    LoadReport r =
        load_scene(w, scene_with_tilemap(R"({"tileSize":[16,16],"tiles":[[0,1,2],[3,-1,5]]})"), "a.scene.json");
    REQUIRE(r.ok());
    const Tilemap* tm = w.get<Tilemap>(w.find_by_id("map"));
    REQUIRE(tm != nullptr);
    CHECK(tm->width == 3);
    CHECK(tm->height == 2);
    CHECK(tiles_vec(*tm) == std::vector<std::int32_t>{0, 1, 2, 3, -1, 5});
    const Json saved = save_scene(w);
    const Json& fields = saved["entities"][0]["components"]["Tilemap"];
    CHECK(fields["tiles"] == Json::parse("[0,1,2,3,-1,5]"));
    CHECK(fields["width"] == 3);
    CHECK(fields["height"] == 2);
}

TEST_CASE("tilemap array: a rows form that disagrees with itself or with width/height is an error with a pointer") {
    {
        World w;
        LoadReport r = load_scene(w, scene_with_tilemap(R"({"tileSize":[16,16],"tiles":[[0,1,2],[3,4],[5,6,7]]})"),
                                  "ragged.scene.json");
        REQUIRE_FALSE(r.ok());
        bool found = false;
        for (const LoadMessage& m : r.messages)
            if (m.pointer.find("/components/Tilemap/tiles/1") != std::string::npos) {
                found = true;
                CHECK_FALSE(m.hint.empty());
            }
        CHECK(found);
    }
    {
        World w;
        LoadReport r = load_scene(w, scene_with_tilemap(R"({"tileSize":[16,16],"height":3,"tiles":[[0,1],[2,3]]})"),
                                  "height.scene.json");
        REQUIRE_FALSE(r.ok());
        CHECK(r.summary().find("height") != std::string::npos);
    }
    {
        World w;
        LoadReport r =
            load_scene(w, scene_with_tilemap(R"({"tileSize":[16,16],"tiles":[[0,"x"],[2,3]]})"), "text.scene.json");
        REQUIRE_FALSE(r.ok());
        CHECK(r.summary().find("/tiles/0/1") != std::string::npos);
    }
}

TEST_CASE("tilemap array: a flat list that does not fill width x height is an error that says how to fix it") {
    World w;
    LoadReport r = load_scene(w, scene_with_tilemap(R"({"tileSize":[16,16],"width":3,"height":2,"tiles":[0,1,2,3,4]})"),
                              "f.scene.json");
    REQUIRE_FALSE(r.ok());
    const std::string text = r.summary();
    CHECK(text.find("5 entries") != std::string::npos);
    CHECK(text.find("3 x 2 = 6") != std::string::npos);
}

TEST_CASE("tilemap array: the stamp tells a changed map from an unchanged one; reads never change it") {
    Tilemap tm;
    tm.tileSize = {16, 16};
    set_tilemap_grid(tm, 4, 4, std::vector<int>(16, 0));
    const TilemapStamp s0 = tilemap_stamp(tm);
    CHECK(tilemap_stamp(tm) == s0);
    // What render, physics and nav do every frame: they read through the const accessors.
    const TilemapSize size = tilemap_size(tm);
    int sum = 0;
    for (int r = 0; r < size.height; ++r)
        for (int c = 0; c < size.width; ++c) sum += tilemap_tile_at(tm, size, c, r);
    CHECK(sum == 0);
    CHECK(tilemap_grid(tm).tiles.size() == 16);
    CHECK(check_tilemap(tm).empty());
    CHECK(tilemap_stamp(tm) == s0);
    CHECK(tm.tiles.version() == s0.version);
    // One write moves it, and the dirty range names the cell.
    REQUIRE(set_tilemap_tile(tm, 2, 1, 7));
    CHECK_FALSE(tilemap_stamp(tm) == s0);
    std::size_t db = 0, de = 0;
    CHECK(tm.tiles.dirty_since(s0.version, db, de));
    CHECK(db == 6);
    CHECK(de == 7);
    // A width change is a change too.
    const TilemapStamp s1 = tilemap_stamp(tm);
    tm.width = 2;
    CHECK_FALSE(tilemap_stamp(tm) == s1);
}

TEST_CASE("tilemap array: a cache keyed on the stamp sees a component added again and a world restored") {
    World w;
    Entity e = w.create("map", "map");
    w.add<Tilemap>(e);
    TilemapStamp before = tilemap_stamp(*w.get<Tilemap>(e));
    // A copy of a Tilemap starts again at version 0, so the version alone would say "unchanged".
    Tilemap copy = *w.get<Tilemap>(e);
    CHECK(copy.tiles.version() == 0);
    CHECK_FALSE(tilemap_stamp(copy) == before);
    w.remove<Tilemap>(e);
    w.add<Tilemap>(e);
    CHECK(w.get<Tilemap>(e)->tiles.version() == 0);
    CHECK_FALSE(tilemap_stamp(*w.get<Tilemap>(e)) == before);
    before = tilemap_stamp(*w.get<Tilemap>(e));
    // The world restored from a snapshot (editor Stop, undo): every component is a new object.
    const Json snapshot = save_scene(w);
    REQUIRE(load_scene(w, snapshot, "snapshot").ok());
    const Tilemap* restored = w.get<Tilemap>(w.find_by_id("map"));
    REQUIRE(restored != nullptr);
    CHECK_FALSE(tilemap_stamp(*restored) == before);
}

TEST_CASE("tilemap array: component_to_json can summarise a big tiles array (the inspector builds it every frame)") {
    World w;
    Entity e = w.create("map", "map");
    Tilemap& tm = w.add<Tilemap>(e);
    tm.tileSize = {16, 16};
    set_tilemap_grid(tm, 512, 512, std::vector<int>(512 * 512, 3));
    const std::uint64_t version = tm.tiles.version();
    const Json small = component_to_json(w, e, World::type_of<Tilemap>(), true, false, 4096);
    CHECK(small["tiles"]["$elements"] == 512 * 512);
    CHECK(small["width"] == 512);
    CHECK(small.dump().size() < 4000);
    const Json full = component_to_json(w, e, World::type_of<Tilemap>(), false, false);
    CHECK(full["tiles"].size() == 512u * 512u);
    CHECK(tm.tiles.version() == version);  // building the JSON only reads
}

TEST_CASE("tilemap edits: tilemap_edits_since explains a stamp by the writes since, and refuses what the log does not "
          "cover") {
    Tilemap tm;
    tm.tileSize = {16, 16};
    set_tilemap_grid(tm, 8, 8, std::vector<int>(64, -1));
    const TilemapStamp s0 = tilemap_stamp(tm);
    std::span<const TileEdit> edits;
    REQUIRE(tilemap_edits_since(tm, s0, edits));  // nothing happened
    CHECK(edits.empty());
    REQUIRE(set_tilemap_tile(tm, 1, 1, 4));
    REQUIRE(set_tilemap_tile(tm, 2, 3, 5));
    REQUIRE(set_tilemap_tile(tm, 1, 1, 6));
    REQUIRE(tilemap_edits_since(tm, s0, edits));
    REQUIRE(edits.size() == 3);
    CHECK(edits[0].cell == 1 * 8 + 1);
    CHECK(edits[0].oldIndex == -1);
    CHECK(edits[0].newIndex == 4);
    CHECK(edits[1].cell == 3 * 8 + 2);
    CHECK(edits[2].oldIndex == 4);
    CHECK(edits[2].newIndex == 6);
    const TilemapStamp s1 = tilemap_stamp(tm);
    REQUIRE(set_tilemap_tile(tm, 0, 0, 7));
    REQUIRE(tilemap_edits_since(tm, s1, edits));  // the log is not consumed: an older stamp still works
    CHECK(edits.size() == 1);
    REQUIRE(tilemap_edits_since(tm, s0, edits));
    CHECK(edits.size() == 4);
    // A write that bypasses the log (the version moves, no edit) is not explained.
    tm.tiles.set(5, 9);
    CHECK_FALSE(tilemap_edits_since(tm, s1, edits));
    CHECK(edits.empty());
    CHECK_FALSE(tilemap_edits_since(tm, s0, edits));
    // Another size is another map.
    TilemapStamp wrong = tilemap_stamp(tm);
    wrong.width += 1;
    CHECK_FALSE(tilemap_edits_since(tm, wrong, edits));
}

TEST_CASE("tilemap edits: assigning a Tilemap never lets its edit log explain the destination's change") {
    Tilemap a, b;
    a.tileSize = b.tileSize = {16, 16};
    set_tilemap_grid(a, 8, 8, std::vector<int>(64, -1));
    set_tilemap_grid(b, 8, 8, std::vector<int>(64, 2));
    const TilemapStamp before = tilemap_stamp(a);
    REQUIRE(set_tilemap_tile(b, 3, 3, 9));  // b: one edit, and one version step on top of the tiles it was set to
    a = b;
    CHECK(a.edits.empty());  // a copy does not carry the log
    CHECK(Tilemap(b).edits.empty());
    Tilemap moved(std::move(b));     // b is not used again
    CHECK(moved.edits.size() == 1);  // a move does (the scene pool relocates components by moving them)
    std::span<const TileEdit> edits;
    CHECK_FALSE(
        tilemap_edits_since(a, before, edits));  // same id, one version step, the edit does not describe a's change
    // The log works again for the writes that follow.
    const TilemapStamp after = tilemap_stamp(a);
    REQUIRE(set_tilemap_tile(a, 0, 0, 1));
    REQUIRE(tilemap_edits_since(a, after, edits));
    CHECK(edits.size() == 1);
    // A moved-in Tilemap too.
    Tilemap c = a;
    REQUIRE(set_tilemap_tile(c, 1, 0, 3));
    const TilemapStamp beforeMove = tilemap_stamp(a);
    a = std::move(c);
    CHECK_FALSE(tilemap_edits_since(a, beforeMove, edits));
}

TEST_CASE("tilemap edits: the log stays bounded and a stamp older than it is refused") {
    Tilemap tm;
    tm.tileSize = {16, 16};
    set_tilemap_grid(tm, 100, 100, std::vector<int>(10000, -1));
    const TilemapStamp old = tilemap_stamp(tm);
    for (int i = 0; i < 6000; ++i) REQUIRE(set_tilemap_tile(tm, i % 100, i / 100, i % 5));
    CHECK(tm.edits.size() <= 4096);
    std::span<const TileEdit> edits;
    CHECK_FALSE(tilemap_edits_since(tm, old, edits));
    const TilemapStamp recent = tilemap_stamp(tm);
    REQUIRE(set_tilemap_tile(tm, 50, 50, 1));
    REQUIRE(tilemap_edits_since(tm, recent, edits));
    CHECK(edits.size() == 1);
}
