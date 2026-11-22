// M75.3c: world.split_cells cuts a scene into a streamed world (index, cells, persistent scene) and world.merge_cells puts it back
// (docs/BIG_WORLDS.md, "Editing a streamed world"). The round trip keeps every entity and component with its id; the output is
// deterministic; the write rules of the caller apply; a streamer that loads the cells makes the same entities as the source.
// No sleeps and no wall-clock asserts: the waits are frame loops with a cap far above what they need.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <map>
#include <set>
#include <string>
#include <tuple>
#include <vector>

#include "fa/authoring/authoring.h"
#include "fa/core/capability.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components_world.h"
#include "fa/scene/world_index.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Project {
    stdfs::path dir;
    Project() {
        authoring::install();
        dir = fs::make_temp_dir("fa_worldsplit").value();
        write("factoria.json",
              R"({"format":"factoria.project/1","name":"Split","id":"com.example.wsplit","mainScene":"scenes/town.scene.json",
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

Json transform(double x, double y, double z) {
    return Json::object({{"Transform", Json::object({{"position", Json::array({x, y, z})}})}});
}

Json entity(const std::string& id, double x, double y, double z) {
    return Json::object({{"id", id}, {"name", id}, {"components", transform(x, y, z)}});
}

// The 3D test level: ground+child in cell [0,0], tree and edge in [1,0], rock in [-1,2], far in [-1,-1]; a camera, the sun, a HUD
// and a manager tagged "global" stay persistent.
Json town_scene() {
    Json ground = entity("ground", 10, 0, 10);
    Json child = entity("ground_child", 500, 0, 500);  // far from its parent's cell in the parent's space: still whole
    child["components"]["Light"] = Json::object({{"type", "Point"}});
    ground["children"] = Json::array({child});
    Json cam = entity("cam", 0, 5, 0);
    cam["components"]["Camera"] = Json::object();
    Json sun = entity("sun", 400, 50, 400);
    sun["components"]["Light"] = Json::object();  // a directional light by default
    Json hud = Json::object({{"id", "hud"}, {"components", Json::object({{"Panel", Json::object()}})}});
    Json manager = entity("manager", 700, 0, 700);
    manager["tags"] = Json::array({"global"});
    Json tree = entity("tree", 200, 1, 10);
    tree["components"]["Light"] = Json::object({{"type", "Point"}, {"range", 12}});
    return Json::object({{"format", "factoria.scene/1"},
                         {"settings", Json::object({{"gravity2D", Json::array({0, -9.81})},
                                                    {"gravity3D", Json::array({0, -3, 0})}})},
                         {"entities", Json::array({ground, cam, tree, entity("edge", 128, 0, 0), sun,
                                                   entity("rock", -5, 3, 300), hud, manager,
                                                   entity("far", -128, 0, -0.5)})}});
}

void write_town(const Project& p) { p.write("scenes/town.scene.json", town_scene().dump(1)); }

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

std::string text_of(const Json& error) { return error.value("message", std::string()) + " " + error.value("hint", std::string()); }

Json split_args(const std::string& out = "worlds/town.world.json", bool overwrite = false) {
    return Json::object({{"scene", "scenes/town.scene.json"}, {"cellSize", 128}, {"out", out}, {"overwrite", overwrite}});
}

// Every entity of a scene file by id (children too), for a comparison that ignores the order of the roots.
void index_entities(const Json& list, std::map<std::string, Json>& out) {
    for (const Json& e : list) {
        out[e.value("id", std::string())] = e;
        if (e.contains("children")) index_entities(e["children"], out);
    }
}

std::vector<std::string> ids_of(const Json& file) {
    std::vector<std::string> ids;
    for (const Json& e : file["entities"]) ids.push_back(e["id"].get<std::string>());
    return ids;
}

}  // namespace

TEST_CASE("world.split_cells: puts each root entity whole in its cell, the global ones in the persistent scene") {
    Project p;
    write_town(p);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("scenes/town.scene.json"), nullptr, &err), err);

    const CommandInfo* info = e.commands().info("world.split_cells");
    REQUIRE(info != nullptr);
    CHECK(info->category == "world");
    CHECK_FALSE(info->readOnly);
    CHECK(info->description.find("BIG_WORLDS") != std::string::npos);
    CHECK(info->description.find("persistent") != std::string::npos);
    REQUIRE(e.commands().info("world.merge_cells") != nullptr);

    const Json dry = call(e, "world.split_cells", Json::object({{"scene", "scenes/town.scene.json"}, {"cellSize", 128}, {"dryRun", true}}));
    CHECK(dry["written"] == 0);
    CHECK(dry["world"] == "scenes/town.world.json");  // the default: next to the scene, named after it
    CHECK_FALSE(stdfs::exists(p.dir / "scenes/town.world.json"));

    const Json r = call(e, "world.split_cells", split_args());
    CHECK(r["cells"] == 4);
    CHECK(r["entities"] == 9);
    CHECK(r["globalEntities"] == 4);
    CHECK(r["written"] == 6);  // 4 cells + the persistent scene + the index
    CHECK(r["persistent"] == "worlds/town_persistent.scene.json");
    CHECK(r["warnings"].empty());
    // The source scene is untouched
    CHECK(Json::parse(p.read("scenes/town.scene.json")) == town_scene());

    auto index = load_world_index("worlds/town.world.json");
    // load_world_index reads through the VFS of the engine's project
    REQUIRE_MESSAGE(index.ok(), (index.ok() ? std::string() : index.error().message));
    CHECK(index.value().dimension == WorldDimension::D3);
    CHECK(index.value().cellSize == 128.0);
    CHECK(index.value().persistent == "worlds/town_persistent.scene.json");
    REQUIRE(index.value().cells.size() == 4);
    // sorted by (j, i)
    CHECK(index.value().cells[0].id() == "-1,-1");
    CHECK(index.value().cells[1].id() == "0,0");
    CHECK(index.value().cells[2].id() == "1,0");
    CHECK(index.value().cells[3].id() == "-1,2");
    const WorldCell* c10 = index.value().find(1, 0);
    REQUIRE(c10 != nullptr);
    CHECK(c10->boundsMin.x == 128.0f);
    CHECK(c10->boundsMax.x == 256.0f);
    CHECK(c10->boundsMin.z == 0.0f);
    CHECK(c10->boundsMax.z == 128.0f);
    CHECK(c10->boundsMin.y == 0.0f);  // the heights of tree (1) and edge (0)
    CHECK(c10->boundsMax.y == 1.0f);
    CHECK(c10->sizeBytes > 0);

    // Hierarchies whole: the child (500, 500) away from its parent stays in the parent's cell
    const Json c00 = Json::parse(p.read("worlds/town_cells/0_0.scene.json"));
    REQUIRE(c00["entities"].size() == 1);
    CHECK(c00["entities"][0]["id"] == "ground");
    CHECK(c00["entities"][0]["children"][0]["id"] == "ground_child");
    // The border belongs to the higher cell
    CHECK(ids_of(Json::parse(p.read("worlds/town_cells/1_0.scene.json"))) == std::vector<std::string>{"tree", "edge"});
    CHECK(ids_of(Json::parse(p.read("worlds/town_cells/-1_2.scene.json"))) == std::vector<std::string>{"rock"});
    CHECK(ids_of(Json::parse(p.read("worlds/town_cells/-1_-1.scene.json"))) == std::vector<std::string>{"far"});
    const Json persistent = Json::parse(p.read("worlds/town_persistent.scene.json"));
    CHECK(ids_of(persistent) == std::vector<std::string>{"cam", "sun", "hud", "manager"});
    CHECK(persistent["settings"]["gravity3D"] == Json::array({0, -3, 0}));
    CHECK(r["globalList"].size() == 4);

    // Deterministic: again with `overwrite` gives the same bytes; without it the call is refused and changes nothing
    std::string before;
    for (const char* f : {"worlds/town.world.json", "worlds/town_persistent.scene.json", "worlds/town_cells/0_0.scene.json",
                          "worlds/town_cells/1_0.scene.json"})
        before += p.read(f);
    CHECK(call_error(e, "world.split_cells", split_args())["code"] == "exists");
    call(e, "world.split_cells", split_args("worlds/town.world.json", true));
    std::string after;
    for (const char* f : {"worlds/town.world.json", "worlds/town_persistent.scene.json", "worlds/town_cells/0_0.scene.json",
                          "worlds/town_cells/1_0.scene.json"})
        after += p.read(f);
    CHECK(before == after);
    // and into another folder: the same cells, the same bytes
    call(e, "world.split_cells", split_args("other/town.world.json"));
    CHECK(p.read("other/town_cells/1_0.scene.json") == p.read("worlds/town_cells/1_0.scene.json"));
    e.shutdown();
}

TEST_CASE("world.merge_cells: the round trip gives back every entity and component with its id") {
    Project p;
    write_town(p);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("scenes/town.scene.json"), nullptr, &err), err);
    call(e, "world.split_cells", split_args());

    const Json dry = call(e, "world.merge_cells", Json::object({{"world", "worlds/town.world.json"}, {"out", "scenes/merged.scene.json"}, {"dryRun", true}}));
    CHECK(dry["written"] == 0);
    CHECK_FALSE(stdfs::exists(p.dir / "scenes/merged.scene.json"));

    const Json m = call(e, "world.merge_cells", Json::object({{"world", "worlds/town.world.json"}, {"out", "scenes/merged.scene.json"}}));
    CHECK(m["entities"] == 9);
    CHECK(m["persistentEntities"] == 4);
    CHECK(m["filesRead"] == 6);
    const Json merged = Json::parse(p.read("scenes/merged.scene.json"));
    const Json original = town_scene();
    CHECK(merged["settings"] == original["settings"]);
    std::map<std::string, Json> a, b;
    index_entities(original["entities"], a);
    index_entities(merged["entities"], b);
    CHECK(a.size() == 10);
    CHECK(a == b);  // the same ids, components, tags, names and children, to the last value
    // The first ones are the persistent scene's, then the cells in index order
    CHECK(ids_of(merged) == std::vector<std::string>{"cam", "sun", "hud", "manager", "far", "ground", "tree", "edge", "rock"});

    // Merging again with `overwrite` gives the same bytes; without it the call is refused
    const std::string once = p.read("scenes/merged.scene.json");
    CHECK(call_error(e, "world.merge_cells", Json::object({{"world", "worlds/town.world.json"}, {"out", "scenes/merged.scene.json"}}))["code"] == "exists");
    call(e, "world.merge_cells", Json::object({{"world", "worlds/town.world.json"}, {"out", "scenes/merged.scene.json"}, {"overwrite", true}}));
    CHECK(p.read("scenes/merged.scene.json") == once);
    // and splitting the merged scene gives the same cells as the first split
    call(e, "world.split_cells", Json::object({{"scene", "scenes/merged.scene.json"}, {"cellSize", 128}, {"out", "again/town.world.json"}}));
    for (const char* cell : {"0_0", "1_0", "-1_2", "-1_-1"})
        CHECK(p.read(std::string("again/town_cells/") + cell + ".scene.json") ==
              p.read(std::string("worlds/town_cells/") + cell + ".scene.json"));
    e.shutdown();
}

TEST_CASE("world.split_cells: errors teach, with the place and the fix, and write nothing") {
    Project p;
    write_town(p);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("scenes/town.scene.json"), nullptr, &err), err);
    auto written = [&] { return stdfs::exists(p.dir / "worlds"); };

    CHECK(call_error(e, "world.split_cells", Json::object({{"scene", "scenes/none.scene.json"}, {"cellSize", 128}}))["code"] == "not_found");
    CHECK(text_of(call_error(e, "world.split_cells", Json::object({{"scene", "scenes/town.scene.json"}}))).find("cellSize") != std::string::npos);
    CHECK(text_of(call_error(e, "world.split_cells", Json::object({{"scene", "scenes/town.scene.json"}, {"cellSize", 0.01}}))).find("cellSize") != std::string::npos);
    CHECK(text_of(call_error(e, "world.split_cells", Json::object({{"scene", "scenes/town.scene.json"}, {"cellSize", 128}, {"dimension", "4d"}}))).find("dimension") != std::string::npos);
    CHECK(text_of(call_error(e, "world.split_cells", Json::object({{"scene", "scenes/town.scene.json"}, {"cellSize", 128}, {"out", "worlds/town.json"}}))).find(".world.json") != std::string::npos);
    CHECK(call_error(e, "world.split_cells", Json::object({{"scene", "scenes/town.scene.json"}, {"cellSize", 128}, {"out", "../x.world.json"}}))["code"] == "path_outside_root");
    CHECK(call_error(e, "world.split_cells", Json::object({{"scene", "scenes/town.scene.json"}, {"cellSize", 128}, {"out", ".factoria/save/x.world.json"}}))["code"] == "managed_path_denied");
    CHECK_FALSE(written());

    // The source scene is never the output, whatever `overwrite` says
    p.write("scenes/town_persistent.scene.json", town_scene().dump(1));
    const Json clash = call_error(e, "world.split_cells", Json::object({{"scene", "scenes/town_persistent.scene.json"}, {"cellSize", 128}, {"out", "scenes/town.world.json"}, {"overwrite", true}}));
    CHECK(text_of(clash).find("never changes it") != std::string::npos);

    // A floating origin: the positions are not absolute
    Json shifted = town_scene();
    shifted["origin"] = Json::array({1000000, 0, 0});
    p.write("scenes/shifted.scene.json", shifted.dump(1));
    const Json origin = call_error(e, "world.split_cells", Json::object({{"scene", "scenes/shifted.scene.json"}, {"cellSize", 128}}));
    CHECK(text_of(origin).find("scenes/shifted.scene.json/origin") != std::string::npos);
    CHECK(text_of(origin).find("world.rebase") != std::string::npos);

    // Nothing to put in a cell
    p.write("scenes/ui.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({Json::object({{"id", "cam"}, {"components", Json::object({{"Camera", Json::object()}})}})})}}).dump(1));
    CHECK(text_of(call_error(e, "world.split_cells", Json::object({{"scene", "scenes/ui.scene.json"}, {"cellSize", 128}}))).find("no entity to put in a cell") != std::string::npos);

    // An entity so far away that the index cannot hold its cell names its place in the file
    Json faraway = town_scene();
    faraway["entities"].push_back(entity("moon", 5e9, 0, 0));
    p.write("scenes/faraway.scene.json", faraway.dump(1));
    CHECK(text_of(call_error(e, "world.split_cells", Json::object({{"scene", "scenes/faraway.scene.json"}, {"cellSize", 128}}))).find("scenes/faraway.scene.json/entities/9") != std::string::npos);
    CHECK_FALSE(written());

    // The write rules of the caller: a read-only client may ask with dryRun but not write
    {
        CommandCapabilityScope readOnly(capability_sets::mcp_read_only());
        CommandCallerScope mcp(CommandCaller::Mcp);
        CHECK(call_error(e, "world.split_cells", split_args())["code"] == "capability_denied");
        CHECK(call_error(e, "world.merge_cells", Json::object({{"world", "worlds/town.world.json"}, {"out", "scenes/m.scene.json"}}))["code"] == "capability_denied");
    }
    CHECK_FALSE(written());
    e.shutdown();
}

TEST_CASE("world.merge_cells: errors teach, and a cell reference across a border is a warning of the split") {
    Project p;
    write_town(p);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("scenes/town.scene.json"), nullptr, &err), err);
    call(e, "world.split_cells", split_args());

    CHECK(text_of(call_error(e, "world.merge_cells", Json::object({{"world", "worlds/town.world.json"}}))).find("out") != std::string::npos);
    CHECK(call_error(e, "world.merge_cells", Json::object({{"world", "worlds/none.world.json"}, {"out", "scenes/m.scene.json"}}))["code"] != "");
    CHECK(text_of(call_error(e, "world.merge_cells", Json::object({{"world", "worlds/town.world.json"}, {"out", "worlds/town_cells/0_0.scene.json"}, {"overwrite", true}}))).find("never changes them") != std::string::npos);
    CHECK(text_of(call_error(e, "world.merge_cells", Json::object({{"world", "worlds/town.world.json"}, {"out", "scenes/m.json"}}))).find(".scene.json") != std::string::npos);
    CHECK(call_error(e, "world.merge_cells", Json::object({{"world", "worlds/town.world.json"}, {"out", "../m.scene.json"}}))["code"] == "path_outside_root");

    // The same id in two cell files
    Json dup = Json::parse(p.read("worlds/town_cells/-1_2.scene.json"));
    dup["entities"][0]["id"] = "tree";
    p.write("worlds/town_cells/-1_2.scene.json", dup.dump(1));
    const Json dupe = call_error(e, "world.merge_cells", Json::object({{"world", "worlds/town.world.json"}, {"out", "scenes/m.scene.json"}}));
    CHECK(text_of(dupe).find("'tree'") != std::string::npos);
    CHECK(text_of(dupe).find("/entities/0") != std::string::npos);
    CHECK_FALSE(stdfs::exists(p.dir / "scenes/m.scene.json"));

    // A reference to an entity of another cell
    Json scene = town_scene();
    scene["entities"][0]["components"]["Script"] = Json::object({{"path", "scripts/x.ts"}, {"props", Json::object({{"target", "rock"}})}});
    p.write("scenes/ref.scene.json", scene.dump(1));
    const Json r = call(e, "world.split_cells", Json::object({{"scene", "scenes/ref.scene.json"}, {"cellSize", 128}, {"out", "ref/town.world.json"}}));
    REQUIRE(r["warnings"].size() == 1);
    const std::string w = r["warnings"][0].get<std::string>();
    CHECK(w.find("'ground'") != std::string::npos);
    CHECK(w.find("'rock'") != std::string::npos);
    CHECK(w.find("cell -1,2") != std::string::npos);
    e.shutdown();
}

TEST_CASE("world.split_cells: a 2D scene is cut on the XY plane and merges back") {
    Project p;
    Json scene = Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array()}});
    for (const auto& [id, x, y] : std::vector<std::tuple<std::string, double, double>>{{"a", 5, 5}, {"b", 70, 5}, {"c", 5, -70}, {"d", 5, 300}, {"e", -3, 60}}) {
        Json en = entity(id, x, y, 0);
        en["components"]["Sprite"] = Json::object();
        scene["entities"].push_back(en);
    }
    p.write("scenes/town.scene.json", scene.dump(1));
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("scenes/town.scene.json"), nullptr, &err), err);
    const Json r = call(e, "world.split_cells", Json::object({{"scene", "scenes/town.scene.json"}, {"cellSize", 64}, {"dimension", "2d"}, {"out", "w/side.world.json"}}));
    CHECK(r["dimension"] == "2d");
    CHECK(r["cells"] == 5);
    const Json index = Json::parse(p.read("w/side.world.json"));
    CHECK(index["dimension"] == "2d");
    CHECK(index["persistent"] == "w/side_persistent.scene.json");
    for (const Json& c : index["cells"]) CHECK(c["bounds"]["min"].size() == 2);
    auto loaded = load_world_index("w/side.world.json");
    REQUIRE_MESSAGE(loaded.ok(), (loaded.ok() ? std::string() : loaded.error().message));
    CHECK(loaded.value().dimension == WorldDimension::D2);
    CHECK(ids_of(Json::parse(p.read("w/side_cells/1_0.scene.json"))) == std::vector<std::string>{"b"});
    CHECK(ids_of(Json::parse(p.read("w/side_cells/0_-2.scene.json"))) == std::vector<std::string>{"c"});
    CHECK(ids_of(Json::parse(p.read("w/side_cells/-1_0.scene.json"))) == std::vector<std::string>{"e"});
    call(e, "world.merge_cells", Json::object({{"world", "w/side.world.json"}, {"out", "w/back.scene.json"}}));
    std::map<std::string, Json> a, b;
    index_entities(scene["entities"], a);
    index_entities(Json::parse(p.read("w/back.scene.json"))["entities"], b);
    CHECK(a == b);
    e.shutdown();
}

TEST_CASE("world.split_cells: the streamer loads the cells as the entities of the source scene") {
    Project p;
    write_town(p);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("scenes/town.scene.json"), nullptr, &err), err);
    call(e, "world.split_cells", split_args());
    // The persistent scene plus a StreamedWorld that keeps every cell loaded
    Json persistent = Json::parse(p.read("worlds/town_persistent.scene.json"));
    persistent["entities"].push_back(Json::object({{"id", "streamer"}, {"components", Json::object({{"StreamedWorld", Json::object({{"world", "worlds/town.world.json"}, {"keepLoaded", true}, {"maxAppliesPerFrame", 16}, {"maxLoadsInFlight", 8}})}})}}));
    p.write("worlds/town_persistent.scene.json", persistent.dump(1));
    call(e, "scene.load", Json::object({{"path", "worlds/town_persistent.scene.json"}}));
    for (int f = 0; f < 600; ++f) {
        e.step(1);
        const Json s = call(e, "world.stream_status");
        if (f > 2 && s["pending"].empty() && s["cellsQueued"].get<int>() == 0 && s["cellsUnloading"].get<int>() == 0) break;
    }
    const Json original = town_scene();
    std::map<std::string, Json> ids;
    index_entities(original["entities"], ids);
    for (const auto& [id, json] : ids) {
        CAPTURE(id);
        const Entity en = e.world().find_by_id(id);
        REQUIRE(e.world().alive(en));
        if (json.contains("components") && json["components"].contains("Transform") && id != "ground_child") {
            const Json& pos = json["components"]["Transform"]["position"];
            const DVec3 at = e.world().absolute_position(en);
            CHECK(at.x == doctest::Approx(pos[0].get<double>()));
            CHECK(at.z == doctest::Approx(pos[2].get<double>()));
        }
    }
    e.shutdown();
}
