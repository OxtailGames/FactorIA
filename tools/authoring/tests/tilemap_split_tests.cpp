// M75.3b: tilemap.split_cells cuts a Tilemap into the chunk cells of a streamed 2D world (docs/BIG_WORLDS.md, "Tilemap chunks"),
// and the chunks, loaded by the streamer, are the same map: the same tiles at the same absolute places, the same solid cells, no
// seam in the collision, whatever the floating origin is. No sleeps and no wall-clock asserts: every wait is a frame loop with a
// cap far above what it needs.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "fa/authoring/authoring.h"
#include "fa/core/fs.h"
#include "fa/physics/physics.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components_world.h"
#include "fa/scene/tilemap.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

constexpr int kW = 70, kH = 20;   // the map, in tiles
constexpr float kTile = 8.0f;
constexpr double kMapX = -400.0, kMapY = 120.0;  // the map's top-left corner (absolute)

// A deterministic map: solid tile 1, decoration 2 (a rotated one among them), empty -1, a solid floor on row 15.
std::vector<int> make_tiles() {
    std::vector<int> t(std::size_t(kW) * kH, -1);
    for (int r = 0; r < kH; ++r)
        for (int c = 0; c < kW; ++c) {
            const int k = (r * 31 + c * 17 + (r * c) % 7) % 6;
            int v = -1;
            if (k == 1) v = 1;
            if (k == 2) v = 2;
            if (k == 3) v = make_tile(2, 1);
            if (r == 15) v = 1;
            t[std::size_t(r) * kW + std::size_t(c)] = v;
        }
    return t;
}

struct Project {
    stdfs::path dir;
    Project() {
        authoring::install();
        dir = fs::make_temp_dir("fa_tilesplit").value();
        write("factoria.json",
              R"({"format":"factoria.project/1","name":"Split","id":"com.example.split","mainScene":"scenes/level.scene.json",
                  "display":{"width":320,"height":180}})");
    }
    ~Project() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    std::string read(const std::string& rel) const {
        std::ifstream in(dir / rel, std::ios::binary);
        return std::string(std::istreambuf_iterator<char>(in), {});
    }
    EngineConfig config(const std::string& scene) const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.graphics = false;
        c.hotReload = false;
        c.memoryStorage = true;
        c.jobThreads = "0";
        c.scene = scene;
        return c;
    }
};

Json tilemap_fields(int w, int h, const std::vector<int>& tiles) {
    Json f = Json::object();
    f["tileset"] = "assets/tiles.png";
    f["tileSize"] = Json::array({kTile, kTile});
    f["solidTiles"] = Json::array({1});
    f["layer"] = -5;
    f["width"] = w;
    f["height"] = h;
    f["tiles"] = tiles;
    return f;
}

Json map_entity(const std::string& id, double x, double y, int w, int h, const std::vector<int>& tiles) {
    Json e = Json::object();
    e["id"] = id;
    e["components"] = Json::object({{"Transform", Json::object({{"position", Json::array({x, y, 0})}})},
                                    {"Tilemap", tilemap_fields(w, h, tiles)}});
    return e;
}

void write_scene(const Project& p, const std::string& rel, const Json& entities) {
    p.write(rel, Json::object({{"format", "factoria.scene/1"}, {"entities", entities}}).dump(1));
}

// A scene that streams `index` with every cell loaded (or around an anchor when keepLoaded is false).
void write_world_scene(const Project& p, const std::string& rel, const std::string& index, bool keepLoaded, double ax = 0,
                       double ay = 0, double radius = 100) {
    Json streamed = Json::object({{"world", index}, {"maxAppliesPerFrame", 64}, {"maxLoadsInFlight", 16}, {"keepLoaded", keepLoaded}});
    Json anchor = Json::object({{"loadRadius", radius}, {"unloadRadius", radius * 1.4}});
    Json entities = Json::array(
        {Json::object({{"id", "streamer"}, {"components", Json::object({{"StreamedWorld", streamed}})}}),
         Json::object({{"id", "anchor"},
                       {"components", Json::object({{"Transform", Json::object({{"position", Json::array({ax, ay, 0})}})},
                                                    {"StreamingAnchor", anchor}})}})});
    write_scene(p, rel, entities);
}

Json call(Engine& e, const std::string& name, const Json& args = Json::object()) {
    auto r = e.commands().call(name, args);
    INFO(name << " " << args.dump() << " -> " << r.error.dump());
    REQUIRE(r.ok);
    return r.result;
}

Json call_error(Engine& e, const std::string& name, const Json& args) {
    auto r = e.commands().call(name, args);
    INFO(name << " " << args.dump());
    REQUIRE_FALSE(r.ok);
    return r.error;
}

void settle(Engine& e, int maxFrames = 200) {
    for (int f = 0; f < maxFrames; ++f) {
        e.step(1);
        const Json s = call(e, "world.stream_status");
        if (s["pending"].empty() && s["cellsUnloading"].get<int>() == 0 && s["cellsQueued"].get<int>() == 0 && f > 0) return;
    }
    FAIL("the streamer did not settle: " << call(e, "world.stream_status").dump());
}

std::vector<std::string> loaded_ids(Engine& e) {
    std::vector<std::string> ids;
    const Json listed = call(e, "world.cells", Json::object({{"state", "loaded"}}));
    for (const Json& c : listed["cells"]) ids.push_back(c["id"].get<std::string>());
    std::sort(ids.begin(), ids.end());
    return ids;
}

// Every non-empty tile of every chunk entity of the world, by ABSOLUTE tile column and row counted from the map's own corner
// (x = kMapX, y = kMapY): column = (x - kMapX) / kTile, row = (kMapY - y) / kTile.
std::map<std::pair<int, int>, int> absolute_tiles(Engine& e, const std::string& prefix, int* chunks = nullptr) {
    std::map<std::pair<int, int>, int> out;
    int count = 0;
    for (Entity ent : e.world().entities_with(&World::type_of<Tilemap>())) {
        const std::string id = e.world().info(ent).id;
        if (id.rfind(prefix, 0) != 0) continue;
        ++count;
        const Tilemap& tm = *e.world().get<Tilemap>(ent);
        const DVec3 at = e.world().absolute_position(ent);
        const double c0 = (at.x - kMapX) / double(kTile), r0 = (kMapY - at.y) / double(kTile);
        REQUIRE(c0 == doctest::Approx(std::round(c0)));
        REQUIRE(r0 == doctest::Approx(std::round(r0)));
        const TilemapGrid g = tilemap_grid(tm);
        for (int r = 0; r < g.height; ++r)
            for (int c = 0; c < g.width; ++c)
                if (g.at(c, r) >= 0) out[{int(std::lround(c0)) + c, int(std::lround(r0)) + r}] = g.at(c, r);
    }
    if (chunks) *chunks = count;
    return out;
}

// Which cells of the map block (a 2 x 2 box at the cell's centre overlaps a collider), asked of the physics world.
std::vector<bool> solid_cells_by_physics(Engine& e) {
    std::vector<bool> out;
    for (int r = 0; r < kH; ++r)
        for (int c = 0; c < kW; ++c) {
            const double x = kMapX + (double(c) + 0.5) * kTile, y = kMapY - (double(r) + 0.5) * kTile;
            const Vec3 l = e.world().to_local(DVec3{x, y, 0});
            out.push_back(!e.physics().overlap_box2d(e.world(), Rect{l.x - 1.0f, l.y - 1.0f, 2.0f, 2.0f}).empty());
        }
    return out;
}

std::vector<bool> solid_cells_expected() {
    std::vector<bool> out;
    for (int v : make_tiles()) out.push_back(v >= 0 && tile_index(v) == 1);
    return out;
}

void prepare_level(const Project& p) {
    write_scene(p, "scenes/level.scene.json", Json::array({map_entity("ground", kMapX, kMapY, kW, kH, make_tiles())}));
}

Json split(Engine& e, int cellSize = 16, const std::string& out = "worlds/level.world.json", bool overwrite = false) {
    return call(e, "tilemap.split_cells",
                Json::object({{"scene", "scenes/level.scene.json"}, {"cellSize", cellSize}, {"out", out}, {"overwrite", overwrite}}));
}

}  // namespace

TEST_CASE("tilemap.split_cells: writes the index and one chunk per cell, deterministically, and teaches on errors") {
    Project p;
    prepare_level(p);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("scenes/level.scene.json"), nullptr, &err), err);

    const CommandInfo* info = e.commands().info("tilemap.split_cells");
    REQUIRE(info != nullptr);
    CHECK(info->category == "world");
    CHECK_FALSE(info->readOnly);
    CHECK(info->description.find("Example") != std::string::npos);

    // dryRun reports and writes nothing
    const Json dry = call(e, "tilemap.split_cells", Json::object({{"scene", "scenes/level.scene.json"}, {"cellSize", 16}, {"dryRun", true}}));
    CHECK(dry["written"] == 0);
    CHECK(dry["index"] == "scenes/level.world.json");  // the default: next to the scene, named after it
    CHECK_FALSE(stdfs::exists(p.dir / "scenes/level.world.json"));

    const Json r = split(e);
    CHECK(r["cellGrid"] == Json::array({5, 2}));
    CHECK(r["cells"] == 10);
    CHECK(r["cellSize"] == 128.0);
    CHECK(r["origin"] == Json::array({kMapX, kMapY - kH * kTile}));
    CHECK(r["written"] == 11);
    const Json index = Json::parse(p.read("worlds/level.world.json"));
    CHECK(index["dimension"] == "2d");
    CHECK(index["cells"].size() == 10);
    // The top row of cells holds the top 4 map rows (20 = 16 + 4), the last column 6 of the 16 columns
    const Json* top = nullptr;
    for (const Json& c : index["cells"])
        if (c["coord"] == Json::array({4, 1})) top = &c;
    REQUIRE(top != nullptr);
    CHECK((*top)["bounds"]["min"] == Json::array({-400.0 + 4 * 128.0, -40.0 + 128.0}));
    CHECK((*top)["bounds"]["max"] == Json::array({-400.0 + 4 * 128.0 + 6 * 8.0, -40.0 + 128.0 + 4 * 8.0}));
    const Json chunk = Json::parse(p.read("worlds/level_cells/4_1.scene.json"));
    CHECK(chunk["entities"][0]["id"] == "ground_4_1");
    CHECK(chunk["entities"][0]["components"]["Tilemap"]["width"] == 6);
    CHECK(chunk["entities"][0]["components"]["Tilemap"]["height"] == 4);
    CHECK(chunk["entities"][0]["components"]["Tilemap"]["tileset"] == "assets/tiles.png");
    CHECK(chunk["entities"][0]["components"]["Transform"]["position"] == Json::array({-400.0 + 512.0, kMapY, 0}));

    // The same call again is refused (nothing is replaced), with `overwrite` it writes the same bytes
    const Json refused = call_error(e, "tilemap.split_cells", Json::object({{"scene", "scenes/level.scene.json"}, {"cellSize", 16}, {"out", "worlds/level.world.json"}}));
    CHECK(refused["code"] == "exists");
    const std::string before = p.read("worlds/level_cells/2_0.scene.json") + p.read("worlds/level.world.json");
    split(e, 16, "worlds/level.world.json", true);
    CHECK(p.read("worlds/level_cells/2_0.scene.json") + p.read("worlds/level.world.json") == before);

    // Errors teach
    CHECK(call_error(e, "tilemap.split_cells", Json::object({{"scene", "scenes/none.scene.json"}}))["code"] == "not_found");
    CHECK(call_error(e, "tilemap.split_cells", Json::object({{"scene", "scenes/level.scene.json"}, {"cellSize", 5000}})).dump()
              .find("4096") != std::string::npos);
    CHECK(call_error(e, "tilemap.split_cells", Json::object({{"scene", "scenes/level.scene.json"}, {"out", "worlds/level.json"}}))["message"]
              .get<std::string>().find(".world.json") != std::string::npos);
    const Json wrong = call_error(e, "tilemap.split_cells", Json::object({{"scene", "scenes/level.scene.json"}, {"tilemap", "grund"}}));
    CHECK(wrong["message"].get<std::string>().find("ground") != std::string::npos);
    CHECK(call_error(e, "tilemap.split_cells", Json::object({{"scene", "scenes/level.scene.json"}, {"out", "../x.world.json"}}))["code"] == "invalid_argument");

    // a map with rectangular tiles, a scaled one and a scene without a map
    Json rect = map_entity("ground", 0, 0, 2, 2, {1, 1, 1, 1});
    rect["components"]["Tilemap"]["tileSize"] = Json::array({16, 8});
    write_scene(p, "scenes/rect.scene.json", Json::array({rect}));
    CHECK(call_error(e, "tilemap.split_cells", Json::object({{"scene", "scenes/rect.scene.json"}}))["message"].get<std::string>().find("square") != std::string::npos);
    Json scaled = map_entity("ground", 0, 0, 2, 2, {1, 1, 1, 1});
    scaled["components"]["Transform"]["scale"] = Json::array({2, 2, 1});
    write_scene(p, "scenes/scaled.scene.json", Json::array({scaled}));
    CHECK(call_error(e, "tilemap.split_cells", Json::object({{"scene", "scenes/scaled.scene.json"}}))["message"].get<std::string>().find("scale") != std::string::npos);
    write_scene(p, "scenes/empty.scene.json", Json::array());
    CHECK(call_error(e, "tilemap.split_cells", Json::object({{"scene", "scenes/empty.scene.json"}}))["message"].get<std::string>().find("no entity with a Tilemap") != std::string::npos);

    // an all-empty cell is not written
    std::vector<int> sparse(std::size_t(8) * 8, -1);
    sparse[0] = 1;
    write_scene(p, "scenes/sparse.scene.json", Json::array({map_entity("m", 0, 0, 8, 8, sparse)}));
    const Json sp = call(e, "tilemap.split_cells", Json::object({{"scene", "scenes/sparse.scene.json"}, {"cellSize", 4}}));
    CHECK(sp["cells"] == 1);
    CHECK(sp["emptyCellsSkipped"] == 3);
    e.shutdown();
}

TEST_CASE("tilemap.split_cells: all the chunks loaded are the original map (tiles, flags and solid cells), at any floating origin") {
    Project p;
    prepare_level(p);
    std::vector<bool> expectedSolid = solid_cells_expected();
    std::map<std::pair<int, int>, int> expectedTiles;
    {
        const std::vector<int> t = make_tiles();
        for (int r = 0; r < kH; ++r)
            for (int c = 0; c < kW; ++c)
                if (t[std::size_t(r) * kW + std::size_t(c)] >= 0) expectedTiles[{c, r}] = t[std::size_t(r) * kW + std::size_t(c)];
    }
    {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config("scenes/level.scene.json"), nullptr, &err), err);
        split(e);
        // The unsplit map answers the same solid cells as the expectation: the baseline of the comparison.
        e.step(3);
        CHECK(solid_cells_by_physics(e) == expectedSolid);
        e.shutdown();
    }
    write_world_scene(p, "scenes/world.scene.json", "worlds/level.world.json", true);
    for (double shift : {0.0, 4096.0, -12288.0}) {
        INFO("origin shift " << shift);
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config("scenes/world.scene.json"), nullptr, &err), err);
        if (shift != 0.0) e.world().rebase(Vec3{float(shift), 0, 0});
        settle(e);
        e.step(3);
        int chunks = 0;
        CHECK(absolute_tiles(e, "ground_", &chunks) == expectedTiles);  // flags included (a rotated tile keeps its rotation)
        CHECK(chunks == 10);
        CHECK(solid_cells_by_physics(e) == expectedSolid);
        // A rebase after the cells loaded moves what is local, never what is where
        e.world().rebase(Vec3{512, 0, 0});
        e.step(3);
        CHECK(absolute_tiles(e, "ground_") == expectedTiles);
        CHECK(solid_cells_by_physics(e) == expectedSolid);
        CHECK(call(e, "world.stream_status")["cellsLoaded"] == 10);
        e.shutdown();
    }
}

TEST_CASE("tilemap.split_cells: chunks load and unload around the anchor, counted in frames and cells") {
    Project p;
    prepare_level(p);
    {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config("scenes/level.scene.json"), nullptr, &err), err);
        split(e);
        e.shutdown();
    }
    // The anchor stands in the cell [0, 0]; every chunk within 100 units of it loads.
    write_world_scene(p, "scenes/world.scene.json", "worlds/level.world.json", false, -336, 24, 100);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("scenes/world.scene.json"), nullptr, &err), err);
    settle(e);
    using Ids = std::vector<std::string>;
    CHECK(loaded_ids(e) == Ids{"0,0", "0,1", "1,0", "1,1"});
    CHECK(e.world().alive(e.world().find_by_id("ground_0_0")));
    CHECK_FALSE(e.world().alive(e.world().find_by_id("ground_2_0")));
    // The chunk sits under its cell's root, which is at the absolute origin
    CHECK(e.world().parent(e.world().find_by_id("ground_0_0")) == e.world().find_by_id("cell_0_0"));
    // Walk right 256 units: the left cells are past the unload radius and go, the new ones load
    e.world().get<Transform>(e.world().find_by_id("anchor"))->position = e.world().to_local(DVec3{-80, 24, 0});
    settle(e);
    CHECK(loaded_ids(e) == Ids{"1,0", "1,1", "2,0", "2,1", "3,0", "3,1"});
    CHECK_FALSE(e.world().alive(e.world().find_by_id("ground_0_0")));
    // No stale collider is left: the cell [0, 0] floor (row 15 of the map) no longer answers, the loaded one does
    e.step(2);
    auto solid_at = [&](double x, double y) {
        const Vec3 l = e.world().to_local(DVec3{x, y, 0});
        return !e.physics().overlap_box2d(e.world(), Rect{l.x - 1.0f, l.y - 1.0f, 2.0f, 2.0f}).empty();
    };
    CHECK_FALSE(solid_at(kMapX + 0.5 * kTile, kMapY - 15.5 * kTile));  // column 0, row 15: in the unloaded cell
    CHECK(solid_at(kMapX + 20.5 * kTile, kMapY - 15.5 * kTile));       // column 20, row 15: loaded
    e.shutdown();
}

namespace {

// A body pushed along a flat floor keeps its speed: a seam between two boxes would stop it (see test_tilemap_chunks.cpp).
float slowest_on_floor(Engine& e, Entity box, float from, float to, float v0) {
    float slowest = v0;
    for (int i = 0; i < 900; ++i) {
        e.step(1);
        const float x = e.world().world_position(box).x;
        if (x > from && x < to) slowest = std::min(slowest, e.world().get<RigidBody2D>(box)->velocity.x);
        if (x >= to) return slowest;
    }
    FAIL("the body never reached " << to << ", x " << e.world().world_position(box).x << " y " << e.world().world_position(box).y
                                    << " vx " << e.world().get<RigidBody2D>(box)->velocity.x << " slowest " << slowest);
    return slowest;
}

}  // namespace

TEST_CASE("tilemap.split_cells: a body slides over the borders between chunks without catching") {
    Project p;
    // A floor of 120 tiles on row 3 of a 120 x 6 map at the origin, cut into chunks of 16 tiles (borders at 128, 256, ...).
    const int w = 120, h = 6;
    std::vector<int> tiles(std::size_t(w) * h, -1);
    for (int c = 0; c < w; ++c) tiles[std::size_t(3 * w + c)] = 1;
    write_scene(p, "scenes/level.scene.json", Json::array({map_entity("ground", 0, 0, w, h, tiles)}));
    {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config("scenes/level.scene.json"), nullptr, &err), err);
        const Json r = split(e);
        CHECK(r["cells"] == 8);  // 8 columns of chunks; the rows 0-2 and 4-5 are empty in the cells' own rows... one row of cells
        e.shutdown();
    }
    write_world_scene(p, "scenes/world.scene.json", "worlds/level.world.json", true);
    for (ColliderShape shape : {ColliderShape::Box, ColliderShape::Circle, ColliderShape::Capsule}) {
        INFO("shape " << int(shape));
        for (double shift : {0.0, 20000.0}) {
            INFO("origin shift " << shift);
            Engine e;
            std::string err;
            REQUIRE_MESSAGE(e.init(p.config("scenes/world.scene.json"), nullptr, &err), err);
            if (shift != 0.0) e.world().rebase(Vec3{float(shift), 0, 0});
            settle(e);
            Entity box = e.world().create("runner", "runner");
            e.world().get<Transform>(box)->position = e.world().to_local(DVec3{3.0 * kTile, -3.0 * kTile + 3.5, 0});
            Collider2D& col = e.world().add<Collider2D>(box);
            col.shape = shape;
            col.size = shape == ColliderShape::Capsule ? Vec2{5, 8} : Vec2{6, 6};
            col.radius = 3.0f;
            col.friction = 0.0f;
            RigidBody2D& rb = e.world().add<RigidBody2D>(box);
            rb.type = BodyType::Dynamic;
            rb.fixedRotation = true;
            rb.velocity = {120.0f, 0};
            e.step(30);  // settles on the floor
            const float x0 = e.world().world_position(box).x;
            const float from = x0 + float(kTile), to = x0 + 100.0f * float(kTile);
            CHECK(slowest_on_floor(e, box, from, to, 120.0f) > 119.0f);
            e.shutdown();
        }
    }
}
