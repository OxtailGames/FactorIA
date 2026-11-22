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
        write(
            "factoria.json",
            R"({"format":"factoria.project/1","name":"Cells","id":"com.example.cells","mainScene":"scenes/main.scene.json",
                  "display":{"width":320,"height":180}})");
        write("scenes/main.scene.json",
              R"({"format":"factoria.scene/1","entities":[
                  {"id":"cam","components":{"Camera":{},"Transform":{"position":[0,5,0]}}},
                  {"id":"streamer","components":{"StreamedWorld":{"world":"worlds/w.world.json"}}}]})");
        write("worlds/w.world.json",
              R"({"format":"factoria.world/1","version":1,"dimension":"3d","cellSize":100,"origin":[0,0],"cells":[
                  {"coord":[0,0],"scene":"worlds/w_cells/0_0.scene.json","bounds":{"min":[0,1,0],"max":[100,1,100]}},
                  {"coord":[1,0],"scene":"worlds/w_cells/1_0.scene.json","bounds":{"min":[100,2,0],"max":[200,2,100]}}]})");
        write("worlds/w_cells/0_0.scene.json",
              R"({"format":"factoria.scene/1","entities":[
                  {"id":"a","components":{"Transform":{"position":[10,1,10]}}},
                  {"id":"a2","components":{"Transform":{"position":[20,1,10]}}}]})");
        write(
            "worlds/w_cells/1_0.scene.json",
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

TEST_CASE("cells: a cell's height bounds follow its entities, up and down, and only a change writes the index") {
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
    CHECK(idx["cells"][0]["bounds"]["min"][1].get<double>() == doctest::Approx(1.0));
    // the entity comes back down: the bounds shrink with it (they are not a high-water mark)
    p.move("a", 10, 1, 10);
    cells.note_edit();
    const CellSaveReport down = cells.save(p.world());
    REQUIRE_MESSAGE(down.ok, down.error);
    CHECK(down.indexWritten);
    CHECK(index_of(p)["cells"][0]["bounds"]["max"][1].get<double>() == doctest::Approx(1.0));
    // an edit that leaves the range alone does not write the index
    p.move("a", 12, 1, 10);
    cells.note_edit();
    const CellSaveReport same = cells.save(p.world());
    REQUIRE_MESSAGE(same.ok, same.error);
    CHECK_FALSE(same.indexWritten);
}

TEST_CASE("cells: sizeBytes, when the index lists it, follows the file after a save") {
    CellProject p;
    p.write("worlds/w.world.json",
            R"({"format":"factoria.world/1","version":1,"dimension":"3d","cellSize":100,"origin":[0,0],"cells":[
                  {"coord":[0,0],"scene":"worlds/w_cells/0_0.scene.json","bounds":{"min":[0,1,0],"max":[100,1,100]},"sizeBytes":5},
                  {"coord":[1,0],"scene":"worlds/w_cells/1_0.scene.json","bounds":{"min":[100,2,0],"max":[200,2,100]}}]})");
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    REQUIRE(cells.load(p.world(), 1, 0, nullptr));
    p.move("a", 15, 1, 10);
    p.move("b", 160, 2, 20);
    cells.note_edit();
    const CellSaveReport rep = cells.save(p.world());
    REQUIRE_MESSAGE(rep.ok, rep.error);
    CHECK(rep.indexWritten);
    const Json idx = index_of(p);
    CHECK(idx["cells"][0]["sizeBytes"].get<std::int64_t>() ==
          std::int64_t(p.read("worlds/w_cells/0_0.scene.json").size()));
    CHECK_FALSE(idx["cells"][1].contains("sizeBytes"));  // a cell that never listed it does not get one
}

TEST_CASE("cells: a save the index would refuse changes nothing in the editor") {
    CellProject p;
    // Cells of 35 m: the far cell [1000000, 0] starts at 3.5e7 and its far edge, 35000035, is not a float (it rounds up to
    // 35000036), so an index with that cell in it is refused.
    p.write("worlds/w.world.json",
            R"({"format":"factoria.world/1","version":1,"dimension":"3d","cellSize":35,"origin":[0,0],"cells":[
                  {"coord":[0,0],"scene":"worlds/w_cells/0_0.scene.json","bounds":{"min":[0,1,0],"max":[35,1,35]}}]})");
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.has_index());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    const std::string cell0 = p.read("worlds/w_cells/0_0.scene.json");
    const std::string indexText = p.read("worlds/w.world.json");
    const Entity root = cells.root_of(0, 0);
    p.move("a", 4.0e7, 1, 10);  // cell [1000000, 0], the last one the index can name
    cells.note_edit();
    const CellSaveReport rep = cells.save(p.world());
    REQUIRE_FALSE(rep.ok);
    CHECK(rep.error.find("Nothing was saved") != std::string::npos);
    CHECK(rep.written.empty());
    CHECK(rep.moved == 0);
    // memory is as before the save: no cell was made, the entity is still under its cell, the index is the one on disk
    CHECK(cells.loaded_count() == 1);
    CHECK_FALSE(cells.is_loaded(1000000, 0));
    CHECK(p.world().parent(p.world().find_by_id("a")) == root);
    CHECK(cells.index().cells.size() == 1);
    CHECK_FALSE(cells.index_changed());
    CHECK(cells.is_dirty(0, 0));
    CHECK(p.read("worlds/w_cells/0_0.scene.json") == cell0);
    CHECK(p.read("worlds/w.world.json") == indexText);
    // put the entity back in its cell and the same cells save normally
    p.move("a", 15, 1, 10);
    cells.note_edit();
    const CellSaveReport again = cells.save(p.world());
    REQUIRE_MESSAGE(again.ok, again.error);
    CHECK(again.written.size() == 1);
}

TEST_CASE("cells: an edit names its cell and only that one is checked first, the others follow one per update") {
    CellProject p;
    p.write("worlds/w.world.json",
            R"({"format":"factoria.world/1","version":1,"dimension":"3d","cellSize":100,"origin":[0,0],"cells":[
                  {"coord":[0,0],"scene":"worlds/w_cells/0_0.scene.json","bounds":{"min":[0,1,0],"max":[100,1,100]}},
                  {"coord":[1,0],"scene":"worlds/w_cells/1_0.scene.json","bounds":{"min":[100,2,0],"max":[200,2,100]}},
                  {"coord":[0,1],"scene":"worlds/w_cells/0_1.scene.json","bounds":{"min":[0,3,100],"max":[100,3,200]}}]})");
    p.write(
        "worlds/w_cells/0_1.scene.json",
        R"({"format":"factoria.scene/1","entities":[{"id":"c","components":{"Transform":{"position":[10,3,150]}}}]})");
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    REQUIRE(cells.load(p.world(), 1, 0, nullptr));
    REQUIRE(cells.load(p.world(), 0, 1, nullptr));
    p.move("a", 15, 1, 10);
    p.move("c", 11, 3, 150);
    cells.note_edit(p.world(), p.world().find_by_id("a"));
    cells.update(p.world(), false);
    CHECK(cells.is_dirty(0, 0));        // the named cell is checked at once
    CHECK_FALSE(cells.is_dirty(0, 1));  // another cell waits for its turn...
    int guard = 0;
    while (cells.pending_checks() > 0 && guard++ < 10) cells.update(p.world(), false);
    CHECK(cells.pending_checks() == 0);
    CHECK(cells.is_dirty(0, 1));  // ...and is found within a few updates
    CHECK(cells.dirty_count() == 2);
    // the cell root itself counts as its cell
    cells.note_edit();
    cells.update(p.world(), false);
    p.move("c", 10, 3, 150);
    cells.note_edit(p.world(), cells.root_of(0, 1));
    cells.update(p.world(), false);
    CHECK_FALSE(cells.is_dirty(0, 1));
    // an entity that is gone checks every cell in one update
    p.move("c", 12, 3, 150);
    cells.note_edit(p.world(), Entity{});
    cells.update(p.world(), false);
    CHECK(cells.is_dirty(0, 1));
    CHECK(cells.pending_checks() == 0);
}

TEST_CASE("cells: deleting the root of a cell with unsaved changes keeps it unsaved and Save writes it empty") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    REQUIRE(cells.load(p.world(), 1, 0, nullptr));
    p.move("a", 15, 1, 10);
    cells.note_edit();
    cells.update(p.world(), false);
    REQUIRE(cells.is_dirty(0, 0));
    const Json before = cells.capture(p.world());
    p.world().destroy(cells.root_of(0, 0));
    p.world().destroy(cells.root_of(1, 0));  // a clean cell: it is only closed
    p.world().flush();
    cells.note_edit();
    cells.update(p.world(), false);
    CHECK(cells.is_loaded(0, 0));
    CHECK(cells.is_dirty(0, 0));
    CHECK(cells.any_dirty());
    CHECK_FALSE(cells.is_loaded(1, 0));
    CHECK(cells.warnings().find("1,0") != std::string::npos);
    const auto rows = cells.rows(p.world(), 50, 50, 10);
    bool sawGone = false;
    for (const CellRow& r : rows)
        if (r.i == 0 && r.j == 0) sawGone = r.rootGone && r.dirty && r.entities == 0;
    CHECK(sawGone);
    // Undo brings the entities back from the snapshot taken before the delete
    CHECK(cells.capture(p.world())["0,0"].empty());
    cells.restore(p.world(), before, Json());
    REQUIRE_FALSE(p.world().find_by_id("a").is_null());
    cells.update(p.world(), false);
    CHECK(cells.is_dirty(0, 0));
    // the same delete again, then Save
    p.world().destroy(cells.root_of(0, 0));
    p.world().flush();
    cells.note_edit();
    cells.update(p.world(), false);
    const CellSaveReport rep = cells.save(p.world());
    REQUIRE_MESSAGE(rep.ok, rep.error);
    REQUIRE(rep.written.size() == 1);
    CHECK(rep.written[0] == "worlds/w_cells/0_0.scene.json");
    const Json file = parse_json(p.read("worlds/w_cells/0_0.scene.json"), "cell").value();
    CHECK(file["entities"].is_array());
    CHECK(file["entities"].empty());
    CHECK_FALSE(cells.is_loaded(0, 0));  // written empty: the cell is closed
    CHECK_FALSE(cells.any_dirty());
}

TEST_CASE(
    "cells: a root deleted before its cell was checked counts as an unsaved change, not as the clean state last seen") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    REQUIRE(cells.load(p.world(), 1, 0, nullptr));
    p.move("b", 160, 2, 20);  // an edit of cell 1,0 that no check has seen yet
    p.move("a", 15, 1, 10);
    cells.note_edit(p.world(), p.world().find_by_id("a"));  // names cell 0,0 only: 1,0 waits for its turn in the sweep
    CHECK_FALSE(cells.is_dirty(1, 0));                      // (its `current` is still the clean state of the load)
    p.world().destroy(cells.root_of(1, 0));
    p.world().flush();
    cells.update(p.world(), false);
    REQUIRE(cells.is_loaded(1, 0));  // not closed on the strength of a stale mark: the edit is not dropped silently
    CHECK(cells.is_dirty(1, 0));
    bool gone = false;
    for (const CellRow& r : cells.rows(p.world(), 150, 50, 10))
        if (r.i == 1 && r.j == 0) gone = r.rootGone && r.dirty && r.entities == 0;
    CHECK(gone);
    CHECK(cells.warnings().find("1,0") != std::string::npos);
}

TEST_CASE("cells: a clean, checked cell whose root is deleted closes without touching its file, whatever is selected") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    REQUIRE(cells.load(p.world(), 1, 0, nullptr));
    cells.note_edit();
    cells.update(p.world(), false);
    REQUIRE_FALSE(cells.any_dirty());
    const std::string file = p.read("worlds/w_cells/1_0.scene.json");
    // The AI, the Console or MCP deletes the root while an entity of the other cell is selected: the editor names the live
    // selection and, for the id that is gone, asks for a check of every cell (Editor::note_cells_edit).
    p.world().destroy(cells.root_of(1, 0));
    p.world().flush();
    cells.note_edit(p.world(), p.world().find_by_id("a"));
    cells.note_edit();
    cells.update(p.world(), false);
    CHECK_FALSE(cells.is_loaded(1, 0));
    CHECK(cells.is_loaded(0, 0));
    CHECK_FALSE(cells.any_dirty());
    const CellSaveReport rep = cells.save(p.world());
    CHECK(rep.ok);
    CHECK(rep.written.empty());
    CHECK(p.read("worlds/w_cells/1_0.scene.json") == file);
}

TEST_CASE("cells: deleting a clean cell's root through the Hierarchy closes it, an unchecked edit in a deleted cell "
          "does not") {
    CellProject p;
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 0, 0, nullptr));
    REQUIRE(cells.load(p.world(), 1, 0, nullptr));
    cells.note_edit();
    cells.update(p.world(), false);
    // the Hierarchy names the root while it is alive, then deletes it before the next check
    cells.note_edit(p.world(), cells.root_of(1, 0));
    p.world().destroy(cells.root_of(1, 0));
    p.world().flush();
    cells.update(p.world(), false);
    CHECK_FALSE(cells.is_loaded(1, 0));
    CHECK_FALSE(cells.any_dirty());
    // an edit in a cell that no check has seen, then its root deleted: that one is an unsaved change
    p.move("a", 15, 1, 10);
    cells.note_edit(p.world(), p.world().find_by_id("a"));
    p.world().destroy(cells.root_of(0, 0));
    p.world().flush();
    cells.update(p.world(), false);
    REQUIRE(cells.is_loaded(0, 0));
    CHECK(cells.is_dirty(0, 0));
}

TEST_CASE("cells: a cell whose file is empty is closed when its root is deleted, never kept as an unsaved empty slot") {
    CellProject p;
    p.write("worlds/w_cells/1_0.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    CellEdit cells;
    cells.refresh(p.world());
    REQUIRE(cells.load(p.world(), 1, 0, nullptr));
    CHECK_FALSE(cells.is_dirty(1, 0));
    const Entity added = p.world().create("added", "added1");
    p.world().set_parent(added, cells.root_of(1, 0));
    cells.note_edit();
    cells.update(p.world(), false);
    REQUIRE(cells.is_dirty(1, 0));
    p.world().destroy(cells.root_of(1, 0));  // the cell is empty again, which is what its file holds
    p.world().flush();
    cells.note_edit();
    cells.update(p.world(), false);
    CHECK_FALSE(cells.is_loaded(1, 0));
    CHECK_FALSE(cells.any_dirty());
    CHECK(cells.warnings().find("1,0") != std::string::npos);
    CHECK(cells.warnings().find("unchanged") != std::string::npos);
    const CellSaveReport rep = cells.save(p.world());  // nothing left to write
    CHECK(rep.ok);
    CHECK(rep.written.empty());
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
