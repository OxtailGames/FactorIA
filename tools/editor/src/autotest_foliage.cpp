// Autotest section F3: the foliage tool (View > Foliage tool, foliage_tool.cpp). A 3D scene with a camera, a 64 x 64 m terrain and a Foliage
// with a ScatterRule on it; the mouse is injected over the viewport at the screen points of ground points, so the tool finds the ground
// under it the way a user's mouse does. An add stroke and a remove stroke each change the instances file, are ONE undo step of the editor
// however many foliage.paint pieces they were sent in, and Ctrl+Z / Redo give back the exact instance count; Scatter all and Clear (asking
// first) are one undo step each; Esc takes a stroke back and gives the dirty state back; a click that misses the terrain keeps the
// selection and the tool; and the undo rows of steps the foliage history forgot (more than kFoliageHistorySteps edits) leave the list
// with a toast, so no row is left that can only answer "nothing to undo".
#include <algorithm>
#include <cmath>
#include <memory>
#include <string>

#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/core/fs.h"
#include "fa/scene/foliage.h"
#include "fa/scene/terrain.h"
#include "imgui.h"
#include "imgui_internal.h"
#include "sokol_app.h"

namespace fa::editor {

using namespace at_support;

namespace {

const char* kFoliageScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "f3_camera", "components": { "Transform": { "position": [0, 30, 30], "rotation": [-45, 0, 0] },
        "Camera": { "projection": "perspective", "fov": 60, "primary": true } } },
    { "id": "f3_sun", "components": { "Transform": { "position": [0, 20, 0], "rotation": [-50, 30, 0] }, "Light": { "intensity": 0.8 } } }
  ]
})";

struct F3State {
    std::size_t undo0 = 0, redo0 = 0;
    std::uint64_t depth = 0, lost = 0;  // the history's undoDepth and historyLost after the last bulk edit
    std::size_t before = 0, after = 0, removed = 0, scattered = 0;
    int strokes0 = 0;
};

}  // namespace

void Editor::at_section_F3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    auto m = std::make_shared<F3State>();
    // How many instances the Foliage's file holds now (0 while it has no file).
    auto count = [this]() -> std::size_t {
        const Foliage* f = world().get<Foliage>(world().find_by_id("f3_forest"));
        if (!f || f->instances.empty() || !fs::exists(f->instances)) return 0;
        auto r = read_foliage(f->instances, f->meshes.size());
        return r.ok() ? r->size() : 0;
    };
    // The undo rows that run foliage commands.
    auto foliage_rows = [this]() {
        std::size_t n = 0;
        for (const UndoEntry& e : undo_)
            if (e.kind == UndoEntry::Kind::Command && !e.forward.empty() && e.forward[0].cmd.rfind("foliage.", 0) == 0)
                ++n;
        return n;
    };
    auto error_toasts = [this]() {
        return std::size_t(std::count_if(toasts_.begin(), toasts_.end(), [](const Toast& t) { return t.level == 2; }));
    };
    auto panel_at = [this](float x, float z) {
        Renderer* r = engine_->renderer();
        float y = 0;
        (void)terrain_height_at(world(), world().find_by_id("f3_ground"), x, z, y, true);
        const Vec2 d = r->world_to_screen(Vec3{x, y, z});
        return Vec2{vpImageMin_.x + d.x / float(r->target_width()) * vpImageSize_.x,
                    vpImageMin_.y + d.y / float(r->target_height()) * vpImageSize_.y};
    };
    // One stroke with the left button from the ground point a to b, slow enough (6 frames a move) that the rate limit lets several
    // pieces through on a slow machine and at least the first piece and the release's on a fast one.
    auto stroke = [this, &step, panel_at](float ax, float az, float bx, float bz) {
        step(2, [this, panel_at, ax, az] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_at(ax, az)); });
        step(3, [this] {
            at_check(vpHovered_, "the mouse is over the viewport (no panel covers it)");
            at_check(foliage_.hasHit, std::string("the brush finds the ground under the mouse (tool ") +
                                          (foliage_tool_active() ? "on" : "off") + ")");
            at_check(foliage_.ringSegments > 0, "the cursor ring is drawn on the terrain");
        });
        step(2, [this, panel_at, ax, az] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, panel_at(ax, az)); });
        for (int i = 1; i <= 8; ++i)
            step(6, [this, panel_at, ax, az, bx, bz, i] {
                const float k = float(i) / 8.0f;
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_at(ax + (bx - ax) * k, az + (bz - az) * k));
            });
        step(3, [this] { at_check(foliage_.stroke.active(), "the stroke is live while the button is down"); });
        step(2, [this, panel_at, bx, bz] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, panel_at(bx, bz)); });
        step(4, [] {});
    };
    auto hold_ctrl = [this, &step](bool down) {
        step(2, [this, down] {
#if defined(__APPLE__)
            atMods_ = down ? SAPP_MODIFIER_SUPER : 0;
            inject_key(down ? SAPP_EVENTTYPE_KEY_DOWN : SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_LEFT_SUPER);
#else
            atMods_ = down ? SAPP_MODIFIER_CTRL : 0;
            inject_key(down ? SAPP_EVENTTYPE_KEY_DOWN : SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_LEFT_CONTROL);
#endif
        });
    };

    // ---- the scene: a camera, a light, a terrain of 64 x 64 m at height 2, a Foliage with a rule (one mesh, 1 per m2)
    step(2, [this, project_file, m] {
        stop();
        write_file(project_file(scenePath_), kFoliageScene);
        reload_scene_from_disk();
        const CommandResult c = engine_->commands().call(
            "terrain.create", Json::parse(R"({"name":"f3_ground","size":[64,64],"resolution":65,"baseHeight":2})"));
        at_check(c.ok, "terrain.create makes the terrain of the section: " + c.error.dump());
        const CommandResult f = engine_->commands().call(
            "scene.spawn",
            Json::parse(R"({"id":"f3_forest","components":{"Foliage":{},"ScatterRule":{"terrain":"f3_ground",)"
                        R"("meshes":[{"mesh":"cube","weight":1}],"density":1.0,"seed":7}}})"));
        at_check(f.ok, "scene.spawn makes the Foliage and its rule: " + f.error.dump());
        select_id("f3_forest");
        foliage_ = FoliageUi{};
        foliage_.brush = BrushSettings{4.0f, 1.0f, 1.0f};
        showFoliageTool_ = true;
        pendingFocus_ = "Foliage tool";
        dirty_ = false;
    });
    step(4, [this] { pendingFocus_ = "Foliage tool"; });
    // The panel docks next to the Inspector on a first run, but a saved layout or a small display can put it over the strokes: a panel
    // that is not docked and overlaps the viewport image moves over the left column.
    step(3, [this] {
        ImGuiWindow* w = ImGui::FindWindowByName("Foliage tool");
        at_check(w != nullptr, "the Foliage tool window exists");
        if (!w || w->DockId != 0 || w->DockNode != nullptr) return;
        const bool over = w->Pos.x < vpImageMin_.x + vpImageSize_.x && w->Pos.x + w->Size.x > vpImageMin_.x &&
                          w->Pos.y < vpImageMin_.y + vpImageSize_.y && w->Pos.y + w->Size.y > vpImageMin_.y;
        if (!over) return;
        ImGui::SetWindowPos(w, ImVec2(8, 28));
        ImGui::SetWindowSize(w, ImVec2(std::max(120.0f, std::min(340.0f, vpImageMin_.x - 16.0f)), 460));
    });
    step(2, [this, count] {
        at_check(at_visible("foliage:mode:add") && at_visible("foliage:mode:remove") && at_visible("foliage:scatter") &&
                     at_visible("foliage:clear"),
                 "the panel lists Add, Remove, Scatter all and Clear");
        at_check(!foliage_tool_active(), "no mode is on yet: the viewport tool is off and the gizmo keeps the clicks");
        at_check(count() == 0, "the Foliage starts with no instances");
    });

    // ---- Add: one stroke
    click("foliage:mode:add");
    step(4, [this, m] {
        at_check(foliage_.mode == FoliageMode::Add && foliage_tool_active(), "Add turns the viewport tool on");
        at_check(at_visible("foliage:radius") && at_visible("foliage:ruledensity") && at_visible("foliage:mesh"),
                 "the panel shows the brush radius, the density source and the mesh");
        m->undo0 = undo_depth();
        m->strokes0 = foliage_.strokes;
    });
    stroke(-10, 0, 10, 0);
    step(3, [this, m, count] {
        m->after = count();
        at_check(foliage_.strokes == m->strokes0 + 1, "the stroke ended");
        at_check(m->after > 50, "the add stroke planted instances (" + std::to_string(m->after) + ")");
        at_check(foliage_.pieces >= 2,
                 "...sent as several foliage.paint pieces (" + std::to_string(foliage_.pieces) + ")");
        at_check(undo_depth() == m->undo0 + 1, "...and is ONE undo step of the editor (depth " +
                                                   std::to_string(undo_depth()) + " from " + std::to_string(m->undo0) +
                                                   ")");
        at_check(dirty(), "...and the scene is dirty");
    });
    hold_ctrl(true);
    step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_Z); });
    step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_Z); });
    hold_ctrl(false);
    step(3, [this, m, count] {
        at_check(count() == 0, "Ctrl+Z takes the whole stroke back (one press, " + std::to_string(count()) + " left)");
        at_check(undo_depth() == m->undo0 && redo_depth() == 1, "...and the redo stack holds the stroke");
    });
    step(2, [this] { redo(); });
    step(3, [this, m, count] {
        at_check(count() == m->after, "Redo gives back the same instances (" + std::to_string(count()) + ")");
        at_check(undo_depth() == m->undo0 + 1 && redo_depth() == 0, "...and the undo stack holds it again");
    });

    // ---- Remove: a stroke through the middle of the planted strip
    click("foliage:mode:remove");
    step(4, [this, m] {
        at_check(foliage_.mode == FoliageMode::Remove, "the Remove mode is on");
        m->undo0 = undo_depth();
    });
    stroke(-4, 0, 4, 0);
    step(3, [this, m, count] {
        m->removed = count();
        at_check(m->removed < m->after, "the remove stroke erased instances (" + std::to_string(m->after) + " -> " +
                                            std::to_string(m->removed) + ")");
        at_check(undo_depth() == m->undo0 + 1, "...as one undo step of the editor");
        undo();
    });
    step(3, [this, m, count] {
        at_check(count() == m->after, "Undo puts the erased instances back");
        redo();
    });
    step(3, [this, m, count] { at_check(count() == m->removed, "Redo erases them again"); });

    // ---- Scatter all and Clear: one undo step each, and Clear asks first
    click("foliage:scatter");
    step(4, [this, m, count] {
        m->scattered = count();
        at_check(m->scattered > 1000,
                 "Scatter all fills the Foliage from its rule (" + std::to_string(m->scattered) + ")");
        at_check(undo_depth() == m->undo0 + 2, "...as one undo step");
        undo();
    });
    step(3, [this, m, count] {
        at_check(count() == m->removed, "Undo puts the instances of before Scatter all back");
        redo();
    });
    click("foliage:clear");
    step(4, [this, count, m] {
        at_check(foliage_.clearArmed && count() == m->scattered, "the first click on Clear asks and removes nothing");
    });
    click("foliage:clear");
    step(4, [this, count, m] {
        at_check(count() == 0, "the second click clears every instance");
        at_check(undo_depth() == m->undo0 + 3, "...as one undo step");
        undo();
    });
    step(3, [this, count, m] {
        at_check(count() == m->scattered, "Undo of Clear gives the instances back");
        undo();  // Scatter all
        undo();  // the remove stroke
    });
    step(3, [this, count, m] {
        at_check(count() == m->after, "three undos go back to the strip of the add stroke");
        at_check(undo_depth() == m->undo0, "...with the add stroke still in the undo list");
        redo();
        redo();
        redo();
    });
    step(3, [this, m, count] {
        at_check(count() == 0,
                 "the three redo rows run in order and end with the Clear (" + std::to_string(count()) + ")");
        undo();
        undo();
        undo();
    });

    // ---- Esc cancels a stroke and gives back the dirty state it found
    step(2, [this, m, count, panel_at] {
        dirty_ = false;
        m->before = count();
        m->undo0 = undo_depth();
        inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_at(-6, 10));
    });
    step(2, [this] { foliage_.mode = FoliageMode::Add; });
    step(2, [this, panel_at] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, panel_at(-6, 10)); });
    step(2, [this, panel_at] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_at(4, 10)); });
    step(4, [this, m, count] {
        at_check(foliage_.stroke.active() && count() > m->before, "a stroke is live and planted instances");
        inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_ESCAPE);
    });
    step(3, [this, m, count] {
        inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_ESCAPE);
        at_check(!foliage_.stroke.active(), "Esc ends the stroke");
        at_check(count() == m->before, "...and takes its instances back (" + std::to_string(count()) + " of " +
                                           std::to_string(m->before) + ")");
        at_check(undo_depth() == m->undo0, "...and leaves no undo step");
        at_check(!dirty(), "...and the scene is as clean as before the stroke");
    });
    step(2, [this, panel_at] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, panel_at(4, 10)); });
    step(3, [] {});

    // ---- a click that misses the terrain keeps the selection and the tool
    step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{vpImageMin_.x + 3, vpImageMin_.y + 3}); });
    step(3, [this] {
        at_check(!foliage_.hasHit,
                 "the corner of the viewport is off the terrain (the camera of this test sees no ground there)");
        inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, Vec2{vpImageMin_.x + 3, vpImageMin_.y + 3});
    });
    step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, Vec2{vpImageMin_.x + 3, vpImageMin_.y + 3}); });
    step(4, [this] {
        at_check(selected_id() == "f3_forest" && foliage_tool_active(),
                 "a click that misses the terrain keeps the Foliage selected and the tool on");
    });

    // ---- the bookkeeping: more edits than the history keeps drop the undo rows of the steps it forgot, with a toast
    step(2, [this, m] {
        toasts_.clear();
        for (int i = 0; i < 70; ++i) {
            const float x = -27.0f + float(i % 10) * 6.0f, z = -27.0f + float(i / 10) * 6.0f;
            std::string error;
            const CommandResult r =
                edit_command("f3:bulk:" + std::to_string(i), "foliage.paint",
                             Json::parse(std::string(R"({"entity":"f3_forest","center":[)") + std::to_string(x) + "," +
                                         std::to_string(z) + R"(],"radius":1.5,"density":3})"),
                             &error);
            if (!r.ok) {
                at_check(false, "foliage.paint " + std::to_string(i) + " is accepted: " + error);
                continue;
            }
            // A stroke over ground the earlier ones filled may plant nothing and make no step: the history's own numbers say how
            // many steps it holds, so the check does not depend on every stroke changing something.
            const auto number = [&](const char* key) -> std::uint64_t {
                return r.result.is_object() && r.result.contains(key) && r.result[key].is_number_unsigned()
                           ? r.result[key].get<std::uint64_t>()
                           : 0;
            };
            m->depth = number("undoDepth");
            m->lost = number("historyLost");
        }
    });
    step(3, [this, m, foliage_rows] {
        const std::size_t rows = foliage_rows();
        at_check(m->depth >= 1 && m->depth <= kFoliageHistorySteps, "the history holds between 1 and " +
                                                                        std::to_string(kFoliageHistorySteps) +
                                                                        " steps (" + std::to_string(m->depth) + ")");
        at_check(rows == m->depth, "the undo list holds exactly the steps the history keeps (" + std::to_string(rows) +
                                       " rows, " + std::to_string(m->depth) + " steps)");
        bool told = false;
        for (const Toast& t : toasts_)
            if (t.level == 1 && t.text.find("can no longer be undone") != std::string::npos &&
                t.text.find(std::to_string(kFoliageHistorySteps)) != std::string::npos)
                told = true;
        at_check(told == (m->lost > 0), "...and a toast names the limit exactly when the history let steps go (lost " +
                                            std::to_string(m->lost) + ")");
        // Every row left works: undoing all of them raises no error.
        for (std::size_t i = 0; i < rows; ++i) undo();
    });
    step(3, [this, error_toasts, foliage_rows] {
        at_check(error_toasts() == 0, "every row left undoes without an error toast");
        at_check(foliage_rows() == 0, "...and the list holds none of the foliage rows afterwards");
    });

    // ---- leave the fixture the next sections expect
    step(2, [this, project_file] {
        foliage_ = FoliageUi{};
        showFoliageTool_ = false;
        write_file(project_file(scenePath_), kFixtureScene);
        reload_scene_from_disk();
        select_id("");
        dirty_ = false;
    });
}

}  // namespace fa::editor
