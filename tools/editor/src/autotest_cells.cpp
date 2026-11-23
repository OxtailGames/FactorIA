// Autotest section W2: editing a streamed world (View > Cells, cells_panel.cpp and cell_edit.cpp). A 2D world of three cells is written
// into the project (the cell under the camera, the one to its right and one far away). The scene is opened in Edit mode: nothing streams.
// "Load around the view" loads the cell under the camera and not the far one; an entity edited through a command marks its cell dirty;
// Save writes that cell's file and neither the other cell's file nor the index; an entity moved across the border is written into the
// other cell's file on Save; Play streams the world by distance and Stop brings the loaded cells back as they were.
// Every wait is a condition with a 60 s safety net, never a frame count.
#include <algorithm>
#include <cmath>
#include <memory>
#include <system_error>

#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/core/fs.h"
#include "fa/scene/components.h"

namespace fa::editor {

using namespace at_support;

namespace {

constexpr double kCell = 100.0;  // the world's cell size, metres

struct W2 {
    std::int32_t ci = 0, cj = 0;  // the cell under the camera
    double x0 = 0, y0 = 0;        // its corner
    std::string indexBefore, bBefore, farBefore;
    Entity a2;
};

std::string cell_path(std::int32_t i, std::int32_t j) {
    return "worlds/w2_cells/" + std::to_string(i) + "_" + std::to_string(j) + ".scene.json";
}

Json entity_json(const std::string& id, double x, double y) {
    return Json::object(
        {{"id", id},
         {"components", Json::object({{"Transform", Json::object({{"position", Json::array({x, y, 0.0})}})}})}});
}

void write_cell(std::int32_t i, std::int32_t j, const Json& entities) {
    const Json scene = Json::object({{"format", "factoria.scene/1"}, {"entities", entities}});
    (void)fs::write_text(cell_path(i, j), scene.dump(2));
}

Json index_cell(std::int32_t i, std::int32_t j) {
    const double a = double(i) * kCell, b = double(j) * kCell;
    return Json::object(
        {{"coord", Json::array({i, j})},
         {"scene", cell_path(i, j)},
         {"bounds", Json::object({{"min", Json::array({a, b})}, {"max", Json::array({a + kCell, b + kCell})}})}});
}

// The x of the entity `id` in a cell file, or a number that cannot be a position when the file does not hold it.
double x_in_file(const std::string& path, const std::string& id) {
    const Result<std::string> text = fs::read_text(path);
    if (!text.ok()) return -1.0e18;
    const auto parsed = parse_json(text.value(), path);
    if (!parsed.ok()) return -1.0e18;
    const Json& f = parsed.value();
    if (!f.is_object() || !f.contains("entities") || !f["entities"].is_array()) return -1.0e18;
    for (const Json& e : f["entities"]) {
        if (!e.is_object() || e.value("id", std::string()) != id) continue;
        const Json p = json_at(e, "/components/Transform/position/0");
        return p.is_number() ? p.get<double>() : -1.0e18;
    }
    return -1.0e18;
}

void remove_world_files(const std::string& projectDir) {
    for (const std::string& rel : fs::list("worlds", true)) {
        if (rel.find("w2") == std::string::npos) continue;
        std::error_code ec;
        fs::remove_file(fs::path_from_utf8(projectDir + "/" + rel), ec);
    }
}

}  // namespace

void Editor::at_section_W2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    auto w = std::make_shared<W2>();

    // The world: three cells on the plane of the 2D fixture, the first under the camera.
    step(2, [this, w] {
        stop();
        showCells_ = false;
        cellsUi_ = CellsUi{};
        cells_.reset();
        remove_world_files(projectDir_);
        double cx = 0, cy = 0;
        bool found = false;
        world().each<Camera>([&](Entity e, Camera&) {
            if (found) return;
            const DVec3 p = world().absolute_position(e);
            cx = p.x;
            cy = p.y;
            found = true;
        });
        w->ci = std::int32_t(std::floor(cx / kCell));
        w->cj = std::int32_t(std::floor(cy / kCell));
        w->x0 = double(w->ci) * kCell;
        w->y0 = double(w->cj) * kCell;
        const std::int32_t farCell = w->ci + 6;
        write_cell(
            w->ci, w->cj,
            Json::array({entity_json("w2_a1", w->x0 + 10, w->y0 + 10), entity_json("w2_a2", w->x0 + 20, w->y0 + 10)}));
        write_cell(w->ci + 1, w->cj, Json::array({entity_json("w2_b1", w->x0 + 150, w->y0 + 20)}));
        write_cell(farCell, w->cj, Json::array({entity_json("w2_f1", w->x0 + 650, w->y0 + 20)}));
        const Json index = Json::object({{"format", "factoria.world/1"},
                                         {"version", 1},
                                         {"dimension", "2d"},
                                         {"cellSize", kCell},
                                         {"origin", Json::array({0.0, 0.0})},
                                         {"cells", Json::array({index_cell(w->ci, w->cj), index_cell(w->ci + 1, w->cj),
                                                                index_cell(farCell, w->cj)})}});
        (void)fs::write_text("worlds/w2.world.json", index.dump(2));
        const Json streamer = Json::object(
            {{"id", "w2_streamer"},
             {"components", Json::object({{"StreamedWorld", Json::object({{"world", "worlds/w2.world.json"}})}})}});
        const Json anchor = Json::object(
            {{"id", "w2_anchor"},
             {"components",
              Json::object({{"Transform", Json::object({{"position", Json::array({cx, cy, 0.0})}})},
                            {"StreamingAnchor", Json::object({{"loadRadius", 150.0}, {"unloadRadius", 200.0}})}})}});
        for (const Json& e : {streamer, anchor}) {
            const CommandResult r = engine_->commands().call("scene.spawn", e);
            at_check(r.ok, "the autotest adds an entity of the streamed world: " + r.error.dump());
        }
    });
    step(6, [this, w] {
        at_check(cells_.has_index(),
                 "the editor finds the index of the scene's StreamedWorld (" + cells_.error() + ")");
        at_check(cells_.index().cells.size() == 3 && cells_.loaded_count() == 0,
                 "the index lists three cells and none is loaded");
        at_check(world().find_by_id("w2_a1").is_null() && world().find_by_id("w2_f1").is_null(),
                 "Edit mode streams nothing by distance, though an anchor stands in the first cell");
    });

    click("menu:view");
    step(3, [] {});
    click("menu:cells");
    step(4, [this] {
        at_check(showCells_, "View > Cells shows the Cells panel");
        pendingFocus_ = "Cells";
    });
    step(4, [this] {
        at_check(at_visible("cells:around") && at_visible("cells:save"),
                 "the panel has Load around the view and Save cells");
        at_check(!at_enabled("cells:save"), "Save cells is disabled while no cell has changes");
        cellsUi_.radiusCells = 1;
        pendingFocus_ = "Cells";
    });

    // Load around the camera: the cell under it, not the far one.
    click("cells:around");
    step(4, [this, w] {
        at_check(cells_.is_loaded(w->ci, w->cj),
                 "Load around the view loads the cell under the camera (" + cellsUi_.status + ")");
        at_check(!cells_.is_loaded(w->ci + 6, w->cj), "...and not the far cell");
        at_check(!world().find_by_id("w2_a1").is_null() && world().find_by_id("w2_f1").is_null(),
                 "...its entities are in the scene, the far cell's are not");
        at_check(!cells_.any_dirty() && !dirty(), "...and loading is not an edit: no cell is marked");
        std::string err;
        at_check(cells_.load(world(), w->ci + 1, w->cj, &err), "the autotest loads the next cell: " + err);
        pendingFocus_ = "Cells";
    });
    step(3, [this, w] {
        const std::string root = "cell_" + std::to_string(w->ci) + "_" + std::to_string(w->cj);
        select_id(root);
        pendingFocus_ = "Cells";
    });
    step(3, [this, w] {
        at_check(world().info(selected()).streamedCell,
                 "the root of a cell can be selected (the Select button does it)");
        select_id("w2_a1");
        w->indexBefore = fs::read_text("worlds/w2.world.json").value_or("");
        w->bBefore = fs::read_text(cell_path(w->ci + 1, w->cj)).value_or("");
        w->farBefore = fs::read_text(cell_path(w->ci + 6, w->cj)).value_or("");
    });
    snap("editor_cells.png");

    // An edit through a command marks only its cell.
    step(3, [this, w] {
        std::string err;
        const Json fields = Json::object({{"position", Json::array({w->x0 + 11, w->y0 + 10, 0.0})}});
        at_check(edit_command("at:w2:a1", "scene.set_component",
                              Json::object({{"id", "w2_a1"}, {"component", "Transform"}, {"fields", fields}}), &err)
                     .ok,
                 "an edit of an entity of a loaded cell goes through: " + err);
    });
    step(4, [this, w] {
        at_check(cells_.is_dirty(w->ci, w->cj) && !cells_.is_dirty(w->ci + 1, w->cj),
                 "the edited cell is marked, the other is not");
        at_check(dirty() && at_enabled("cells:save"), "the editor shows unsaved changes and Save cells is enabled");
        pendingFocus_ = "Cells";
    });
    click("cells:save");
    step(4, [this, w] {
        at_check(!cells_.any_dirty(), "Save cells clears the mark");
        at_check(std::abs(x_in_file(cell_path(w->ci, w->cj), "w2_a1") - (w->x0 + 11)) < 1e-3,
                 "...the edited cell's file has the new position");
        at_check(fs::read_text(cell_path(w->ci + 1, w->cj)).value_or("") == w->bBefore &&
                     fs::read_text(cell_path(w->ci + 6, w->cj)).value_or("") == w->farBefore,
                 "...the other cells' files are not written");
        at_check(fs::read_text("worlds/w2.world.json").value_or("") == w->indexBefore,
                 "...nor the index (its bounds did not change)");
    });

    // An entity dragged across the border is filed into the cell its position is in, at Save.
    step(3, [this, w] {
        std::string err;
        const Json fields = Json::object({{"position", Json::array({w->x0 + 130, w->y0 + 30, 0.0})}});
        at_check(edit_command("at:w2:a2", "scene.set_component",
                              Json::object({{"id", "w2_a2"}, {"component", "Transform"}, {"fields", fields}}), &err)
                     .ok,
                 "an entity of the first cell moves into the second cell's area: " + err);
        w->a2 = world().find_by_id("w2_a2");
    });
    step(4, [this, w] {
        std::int32_t ti = 0, tj = 0;
        at_check(cells_.destination_of(world(), w->a2, ti, tj) && ti == w->ci + 1 && tj == w->cj,
                 "its destination is the second cell");
        at_check(cells_.is_dirty(w->ci, w->cj), "the cell it leaves is marked");
        pendingFocus_ = "Cells";
    });
    click("cells:save");
    step(4, [this, w] {
        at_check(!cells_.any_dirty(), "Save cells clears the marks after a re-file");
        at_check(x_in_file(cell_path(w->ci, w->cj), "w2_a2") < -1.0e17,
                 "the first cell's file no longer holds the entity");
        at_check(std::abs(x_in_file(cell_path(w->ci + 1, w->cj), "w2_a2") - (w->x0 + 130)) < 1e-3,
                 "...the second cell's file holds it, at its position");
        at_check(x_in_file(cell_path(w->ci + 1, w->cj), "w2_b1") > -1.0e17, "...next to the entity that was there");
        const Entity a2 = world().find_by_id("w2_a2");
        at_check(!a2.is_null() && world().parent(a2) == cells_.root_of(w->ci + 1, w->cj),
                 "...and in the scene it is under the second cell's root");
        at_check(fs::read_text(cell_path(w->ci + 6, w->cj)).value_or("") == w->farBefore,
                 "the far cell's file was never written");
    });

    // The streamer's HLOD proxy ("hlod i,j", EntityInfo::streamedProxy) is not listed in the Hierarchy, next to an ordinary entity.
    step(2, [this] {
        showHierarchy_ = true;
        const Entity proxy = world().create("hlod 9,9", "w2_hlod_proxy");
        world().info(proxy).streamedProxy = true;
        const Entity plain = world().create("w2 plain", "w2_plain");
        (void)plain;
    });
    // hierRows_ is filled only when the Hierarchy window is drawn: a docked-behind or collapsed panel would show no rows and fail the
    // check below for the wrong reason, so wait (the script's own 60 s cap names it) until the panel was drawn with the new entity listed.
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitWhat_ =
            "the Hierarchy panel to be on screen and list the new entity (a collapsed or hidden panel draws no rows)";
        atWaitUntil_ = [this] {
            const auto listed = [](const std::vector<std::string>& rows) {
                return std::find(rows.begin(), rows.end(), "w2_plain") != rows.end();
            };
            return at_visible("tree:filter") && (listed(hierRows_) || listed(hierRowsPrev_));
        };
    });
    step(3, [this] {
        bool proxyRow = false, plainRow = false;
        for (const std::string& id : hierRows_) {
            proxyRow = proxyRow || id == "w2_hlod_proxy";
            plainRow = plainRow || id == "w2_plain";
        }
        at_check(plainRow, "an ordinary new entity is listed in the Hierarchy");
        at_check(!proxyRow, "...and the streamer's HLOD proxy is not");
        world().destroy(world().find_by_id("w2_hlod_proxy"));
        world().destroy(world().find_by_id("w2_plain"));
        world().flush();
    });

    // Play streams by distance; Stop brings the loaded cells back.
    step(3, [this] { play(); });
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitWhat_ = "the game to stream the cell under the anchor";
        atWaitUntil_ = [this] { return play_ == PlayState::Playing && !world().find_by_id("w2_a1").is_null(); };
    });
    step(3, [this] {
        at_check(cells_.suspended(), "while the game plays the editor's cells are suspended");
        at_check(world().find_by_id("w2_f1").is_null(),
                 "...and the game streams by distance: the far cell is not loaded");
    });
    step(3, [this] { stop(); });
    step(6, [this, w] {
        at_check(play_ == PlayState::Edit && !cells_.suspended(), "Stop returns to Edit and the cells are back");
        at_check(cells_.is_loaded(w->ci, w->cj) && cells_.is_loaded(w->ci + 1, w->cj) && cells_.loaded_count() == 2,
                 "...the same two cells are loaded");
        const Entity a1 = world().find_by_id("w2_a1");
        at_check(!a1.is_null() && world().parent(a1) == cells_.root_of(w->ci, w->cj),
                 "...their entities are under their roots");
        at_check(!cells_.any_dirty(), "...and clean: Play changed nothing");
        at_check(world().find_by_id("w2_f1").is_null(), "...and the far cell is not loaded");
    });

    // Clean up: the scene and the project go back as they were.
    step(3, [this] {
        cells_.unload_clean(world());
        for (const char* id : {"w2_streamer", "w2_anchor"})
            (void)engine_->commands().call("scene.destroy", Json::object({{"id", id}}));
        showCells_ = false;
    });
    step(3, [this] {
        cells_.reset();
        cellsUi_ = CellsUi{};
        remove_world_files(projectDir_);
        at_check(!at_visible("cells:around"), "closing the panel removes it");
    });
}

}  // namespace fa::editor
