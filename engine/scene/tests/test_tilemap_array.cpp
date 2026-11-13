// Tilemap::tiles as a flat fa::ArrayI32 (M94.2b): the rows form of a file, the errors, the stamps caches compare.
#include <doctest.h>

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
    LoadReport r = load_scene(
        w, scene_with_tilemap(R"({"tileSize":[16,16],"width":3,"height":2,"tiles":[0,1,2,3,4]})"), "f.scene.json");
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
    tm.tiles.acknowledge();
    REQUIRE(set_tilemap_tile(tm, 2, 1, 7));
    CHECK_FALSE(tilemap_stamp(tm) == s0);
    CHECK(tm.tiles.dirty_begin() == 6);
    CHECK(tm.tiles.dirty_end() == 7);
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
