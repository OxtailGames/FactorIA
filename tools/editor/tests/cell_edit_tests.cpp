// The editor's model of a streamed world in Edit mode (cell_edit.h): loading cells as editable entities, the dirty mark by baseline, Save
// writing only the dirty cells, the re-file of an entity moved across a border, new cells, bounds that grow, snapshots and play.
// No sleeps, no wall-clock: everything here is a function of the files and the calls.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <iterator>
#include <memory>
#include <string>

#include "cell_edit.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components.h"
#include "fa/scene/components_world.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

struct CellProject {
    stdfs::path dir;
    Engine engineStorage;
    Engine* engine = &engineStorage;
    CellProject() {
        dir = fs::make_temp_dir("fa_celledit").value();
        write("factoria.json",
              R"({"format":"factoria.project/1","name":"Cells","id":"com.example.cells","mainScene":"scenes/main.scene.json",
                  "display":{"width":320,"height":180}})");
        write("scenes/main.scene.json",
              R"({"format":"factoria.scene/1","entities":[
                  {"id":"cam","components":{"Camera":{},"Transform":{"position":[0,5,0]}}},
                  {"id":"streamer","components":{"StreamedWorld":{"world":"worlds/w.world.json"}}}]})");
        write("worlds/w.world.json", R"({"format":"factoria.world/1","version":1,"dimension":"3d","cellSize":100,"origin":[0,0],"cells":[
                  {"coord":[0,0],"scene":"worlds/w_cells/0_0.scene.json","bounds":{"min":[0,0,0],"max":[100,10,100]}},
                  {"coord":[1,0],"scene":"worlds/w_cells/1_0.scene.json","bounds":{"min":[100,0,0],"max":[200,10,100]}}]})");
        write("worlds/w_cells/0_0.scene.json",
              R"({"format":"factoria.scene/1","entities":[
                  {"id":"a","components":{"Transform":{"position":[10,1,10]}}},
                  {"id":"a2","components":{"Transform":{"position":[20,1,10]}}}]})");
        write("worlds/w_cells/1_0.scene.json",
              R"({"format":"factoria.scene/1","entities":[{"id":"b","components":{"Transform":{"position":[150,2,20]}}}]})");
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.graphics = false;
        c.hotReload = false;
        c.memoryStorage = true;
        c.jobThreads = "0";
        c.scene = "scenes/main.scene.json";
        std::string err;
        REQUIRE_MESSAGE(engine->init(c, nullptr, &err), err);
    }
    ~CellProject() {
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
    World& world() { return engine->world(); }
    void move(const std::string& id, double x, double y, double z) {
        Entity e = world().find_by_id(id);
        REQUIRE_FALSE(e.is_null());
        world().get<Transform>(e)->position = world().to_local(DVec3{x, y, z});
    }
};

Json index_of(CellProject& p) {
    auto parsed = parse_json(p.read("worlds/w.world.json"), "index");
    REQUIRE(parsed.ok());
    return parsed.value();
}

}  // namespace

TEST_CASE("cells: the index is found through the scene's StreamedWorld and nothing streams by itself") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.has_index());
    CHECK(cells.index_path() == "worlds/w.world.json");
    CHECK(cells.index().cells.size() == 2);
    CHECK(cells.loaded_count() == 0);
    // No frame loads a cell: the editor's Edit mode is paused and only the user's choice loads one.
    for (int i = 0; i < 5; ++i) p.engine->frame(1.0 / 60.0);
    CHECK(p.world().find_by_id("a").is_null());
}

TEST_CASE("cells: a loaded cell is a root with its entities at their absolute positions, clean until edited") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    std::string err;
    REQUIRE(cells.load(p.world(), 0, 0, &err));
    CHECK(cells.is_loaded(0, 0));
    CHECK_FALSE(cells.is_loaded(1, 0));
    const Entity root = cells.root_of(0, 0);
    REQUIRE(p.world().alive(root));
    CHECK(p.world().info(root).streamedCell);
    CHECK(p.world().info(root).id == "cell_0_0");
    Entity a = p.world().find_by_id("a");
    REQUIRE_FALSE(a.is_null());
    CHECK(p.world().parent(a) == root);
    CHECK(p.world().absolute_position(a).x == doctest::Approx(10.0));
    CHECK(cells.load(p.world(), 0, 0, &err));  // already loaded: nothing happens
    CHECK(p.world().children(root).size() == 2);
    CHECK_FALSE(cells.load(p.world(), 7, 7, &err));
    CHECK(err.find("no cell 7,7") != std::string::npos);
    cells.note_edit();
    cells.update(p.world(), false);
    CHECK_FALSE(cells.is_dirty(0, 0));
    CHECK_FALSE(cells.any_dirty());
}

TEST_CASE("cells: an edit marks the cell dirty, Undo to the saved state clears it, Save writes only that cell") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    REQUIRE(cells.load(p.world(), 1, 0, nullptr));
    const std::string before1 = p.read("worlds/w_cells/1_0.scene.json");
    const std::string indexBefore = p.read("worlds/w.world.json");
    p.move("a", 15, 1, 10);
    cells.note_edit();
    cells.update(p.world(), true);  // the mouse is dragging: the check waits
    CHECK_FALSE(cells.is_dirty(0, 0));
    cells.update(p.world(), false);
    CHECK(cells.is_dirty(0, 0));
    CHECK_FALSE(cells.is_dirty(1, 0));
    CHECK(cells.dirty_count() == 1);
    std::string err;
    CHECK_FALSE(cells.unload(p.world(), 0, 0, false, &err));
    CHECK(err.find("unsaved") != std::string::npos);
    CHECK(cells.is_loaded(0, 0));
    // back to the saved value: clean again
    p.move("a", 10, 1, 10);
    cells.note_edit();
    cells.update(p.world(), false);
    CHECK_FALSE(cells.is_dirty(0, 0));
    p.move("a", 15, 1, 10);
    cells.note_edit();
    const CellSaveReport rep = cells.save(p.world());
    REQUIRE_MESSAGE(rep.ok, rep.error);
    REQUIRE(rep.written.size() == 1);
    CHECK(rep.written[0] == "worlds/w_cells/0_0.scene.json");
    CHECK_FALSE(rep.indexWritten);
    CHECK(p.read("worlds/w_cells/1_0.scene.json") == before1);
    CHECK(p.read("worlds/w.world.json") == indexBefore);
    CHECK(p.read("worlds/w_cells/0_0.scene.json").find("15") != std::string::npos);
    CHECK_FALSE(cells.any_dirty());
    CHECK(cells.save(p.world()).written.empty());  // nothing dirty: nothing written
}

TEST_CASE("cells: Save moves an entity that crossed a border to the cell of its position, ids and order kept") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    p.move("a", 150, 1, 30);  // now in cell [1,0]
    cells.note_edit();
    cells.update(p.world(), false);
    std::int32_t i = -9, j = -9;
    REQUIRE(cells.cell_of_entity(p.world(), p.world().find_by_id("a"), i, j));
    CHECK((i == 0 && j == 0));
    REQUIRE(cells.destination_of(p.world(), p.world().find_by_id("a"), i, j));
    CHECK((i == 1 && j == 0));
    const CellSaveReport rep = cells.save(p.world());
    REQUIRE_MESSAGE(rep.ok, rep.error);
    CHECK(rep.moved == 1);
    CHECK(rep.written.size() == 2);
    CHECK(rep.written.front() == "worlds/w_cells/1_0.scene.json");  // the cell that receives goes first
    CHECK(cells.is_loaded(1, 0));
    CHECK(p.read("worlds/w_cells/0_0.scene.json").find("\"a\"") == std::string::npos);
    const std::string target = p.read("worlds/w_cells/1_0.scene.json");
    CHECK(target.find("\"a\"") != std::string::npos);
    CHECK(target.find("\"b\"") != std::string::npos);
    CHECK(target.find("\"a2\"") == std::string::npos);
    CHECK(p.read("worlds/w_cells/0_0.scene.json").find("\"a2\"") != std::string::npos);
    CHECK_FALSE(cells.any_dirty());
    CHECK(p.world().find_by_id("a") != Entity{});
}

TEST_CASE("cells: a position in no cell of the index makes a new cell, listed in the index") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 1, 0, nullptr));
    p.move("b", 350, 4, 20);  // cell [3,0]
    cells.note_edit();
    const CellSaveReport rep = cells.save(p.world());
    REQUIRE_MESSAGE(rep.ok, rep.error);
    CHECK(rep.indexWritten);
    CHECK(p.read("worlds/w_cells/3_0.scene.json").find("\"b\"") != std::string::npos);
    const Json idx = index_of(p);
    REQUIRE(idx["cells"].size() == 3);
    CHECK(idx["cells"][2]["coord"] == Json::array({3, 0}));
    CHECK(idx["cells"][2]["scene"] == "worlds/w_cells/3_0.scene.json");
    CHECK(cells.is_loaded(3, 0));
    cells.refresh(p.world(), true);
    CHECK(cells.index().cells.size() == 3);
}

TEST_CASE("cells: a cell's height bounds grow when an entity goes above them, and only then the index is written") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    p.move("a", 10, 50, 10);
    cells.note_edit();
    const CellSaveReport rep = cells.save(p.world());
    REQUIRE_MESSAGE(rep.ok, rep.error);
    CHECK(rep.indexWritten);
    const Json idx = index_of(p);
    CHECK(idx["cells"][0]["bounds"]["max"][1].get<double>() == doctest::Approx(50.0));
    CHECK(idx["cells"][0]["bounds"]["min"][1].get<double>() == doctest::Approx(0.0));
}

TEST_CASE("cells: the write rules refuse a cell file in a managed folder and nothing is written") {
    CellProject p;
    p.write("worlds/w.world.json",
            R"({"format":"factoria.world/1","version":1,"dimension":"3d","cellSize":100,"origin":[0,0],"cells":[
                  {"coord":[0,0],"scene":".git/0_0.scene.json","bounds":{"min":[0,0,0],"max":[100,10,100]}}]})");
    p.write(".git/0_0.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"g","components":{}}]})");
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.has_index());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    p.world().get<Transform>(p.world().find_by_id("g"))->position = Vec3{1, 2, 3};
    cells.note_edit();
    const std::string before = p.read(".git/0_0.scene.json");
    const CellSaveReport rep = cells.save(p.world());
    CHECK_FALSE(rep.ok);
    CHECK(rep.error.find("Nothing was saved") != std::string::npos);
    CHECK(p.read(".git/0_0.scene.json") == before);
    CHECK(cells.is_dirty(0, 0));
}

TEST_CASE("cells: snapshots carry the loaded cells, restore brings them back, play suspends and Stop restores") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    p.move("a", 33, 1, 10);
    cells.note_edit();
    cells.update(p.world(), false);
    REQUIRE(cells.is_dirty(0, 0));
    const Json cap = cells.capture(p.world());
    REQUIRE(cap.contains("0,0"));
    CHECK(cap["0,0"].size() == 2);
    // Play: the world is replaced and the cells are not restored
    Json scene = snapshot_scene(p.world());
    CHECK(scene.dump().find("\"a2\"") == std::string::npos);  // the scene snapshot leaves cells out
    cells.suspend();
    std::string err;
    REQUIRE(p.engine->load_scene_json(scene, "snapshot", &err));
    CHECK(p.world().find_by_id("a").is_null());
    CHECK_FALSE(cells.load(p.world(), 1, 0, &err));  // not while the game runs
    CHECK(cells.capture(p.world()).empty());
    // Stop
    REQUIRE(p.engine->load_scene_json(scene, "snapshot", &err));
    cells.restore(p.world(), cap, Json());
    Entity a = p.world().find_by_id("a");
    REQUIRE_FALSE(a.is_null());
    CHECK(p.world().absolute_position(a).x == doctest::Approx(33.0));
    cells.update(p.world(), false);
    CHECK(cells.is_dirty(0, 0));  // still different from the file
    // Undo to the saved state: a snapshot taken from the file's state
    p.move("a", 10, 1, 10);
    cells.note_edit();
    cells.update(p.world(), false);
    CHECK_FALSE(cells.is_dirty(0, 0));
}

TEST_CASE("cells: with the floating origin moved a cell still lands at its absolute positions") {
    CellProject p;
    p.world().set_origin(DVec3{1000.0, 0.0, 0.0});
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    Entity a = p.world().find_by_id("a");
    REQUIRE_FALSE(a.is_null());
    CHECK(p.world().absolute_position(a).x == doctest::Approx(10.0));
    CHECK(p.world().world_position(a).x == doctest::Approx(-990.0));
    cells.note_edit();
    cells.update(p.world(), false);
    CHECK_FALSE(cells.is_dirty(0, 0));
    p.move("a", 20, 1, 10);
    cells.note_edit();
    REQUIRE(cells.save(p.world()).ok);
    CHECK(p.read("worlds/w_cells/0_0.scene.json").find("20") != std::string::npos);
}

TEST_CASE("cells: load around the view loads the nearest cells first and says what is left") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    int loaded = 0, left = 0;
    std::string err;
    REQUIRE(cells.load_around(p.world(), 150, 50, 10, 1, &loaded, &left, &err));  // inside cell [1,0] only
    CHECK(loaded == 1);
    CHECK(left == 0);
    CHECK(cells.is_loaded(1, 0));
    CHECK_FALSE(cells.is_loaded(0, 0));
    REQUIRE(cells.load_around(p.world(), 100, 50, 1000, 5, &loaded, &left, &err));
    CHECK(loaded == 1);  // [1,0] was loaded already
    CHECK(cells.is_loaded(0, 0));
    const auto rows = cells.rows(p.world(), 100, 50, 10);
    REQUIRE(rows.size() == 2);
    CHECK(rows[0].loaded);
    CHECK(cells.unload_clean(p.world()) == 2);
    CHECK(cells.loaded_count() == 0);
}
