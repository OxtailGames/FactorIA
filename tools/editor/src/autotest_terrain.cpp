// Autotest section T3: the terrain tool (View > Terrain tool, terrain_tool.cpp). A 3D scene with a camera and a Terrain3D with two layers;
// the mouse is injected over the viewport at the screen points of ground points, so the tool finds the ground under it the way a user's
// mouse does. A sculpt stroke, a paint stroke and a holes stroke each change the terrain, are ONE undo step of the editor and ONE step of
// the terrain's own history, and Undo / Redo give back the exact samples (a checksum); an undo of an unrelated edit (a scene snapshot) keeps
// the terrain's unsaved data; a failing save says why and keeps the edits; Save writes the files.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <system_error>

#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/core/fs.h"
#include "fa/scene/terrain.h"
#include "imgui.h"
#include "imgui_internal.h"
#include "sokol_app.h"

namespace fa::editor {

using namespace at_support;

namespace {

// A camera 42 m from the middle of the 64 x 64 m terrain, looking down at it at 45 degrees.
const char* kTerrainScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "t3_camera", "components": { "Transform": { "position": [0, 30, 30], "rotation": [-45, 0, 0] },
        "Camera": { "projection": "perspective", "fov": 60, "primary": true } } },
    { "id": "t3_sun", "components": { "Transform": { "position": [0, 20, 0], "rotation": [-50, 30, 0] }, "Light": { "intensity": 0.8 } } }
  ]
})";

// FNV-1a over bytes: the same input gives the same number on every CPU.
std::uint64_t fnv(const std::uint8_t* p, std::size_t n, std::uint64_t h = 1469598103934665603ull) {
    for (std::size_t i = 0; i < n; ++i) {
        h ^= p[i];
        h *= 1099511628211ull;
    }
    return h;
}

std::uint64_t checksum(const TerrainHeights& h) {
    std::uint64_t s = fnv(reinterpret_cast<const std::uint8_t*>(h.data.data()), h.data.size() * sizeof(std::uint16_t));
    s = fnv(h.holes.data(), h.holes.size(), s);
    for (const TerrainSplat& m : h.splat) s = fnv(m.rgba.data(), m.rgba.size(), s);
    return s;
}

// How many texels of splat map 0 carry weight in the given channel (0 = red = layer 0).
std::size_t weighted(const TerrainHeights& h, int channel) {
    std::size_t n = 0;
    for (std::size_t i = std::size_t(channel); i < h.splat[0].rgba.size(); i += 4)
        if (h.splat[0].rgba[i] > 0) ++n;
    return n;
}

std::size_t holes_cut(const TerrainHeights& h) {
    return std::size_t(
        std::count_if(h.holes.begin(), h.holes.end(), [](std::uint8_t v) { return v != 0; }));  // 1 = a hole
}

struct T3State {
    std::size_t undo0 = 0, redo0 = 0, history0 = 0;
    int strokes0 = 0;
    std::uint64_t before = 0, after = 0;
    std::size_t paintedBefore = 0;
    float centreBefore = 0;
    std::string holesPath;
};

}  // namespace

void Editor::at_section_T3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    auto m = std::make_shared<T3State>();
    auto heights = [this]() -> std::shared_ptr<TerrainHeights> {
        const Entity e = world().find_by_id("t3_ground");
        return e.is_null() ? nullptr : world().terrain().find(e);
    };
    // The panel position of the ground point (x, z) of the terrain.
    auto panel_at = [this](float x, float z) {
        Renderer* r = engine_->renderer();
        float y = 0;
        (void)terrain_height_at(world(), world().find_by_id("t3_ground"), x, z, y, true);
        const Vec2 d = r->world_to_screen(Vec3{x, y, z});
        return Vec2{vpImageMin_.x + d.x / float(r->target_width()) * vpImageSize_.x,
                    vpImageMin_.y + d.y / float(r->target_height()) * vpImageSize_.y};
    };
    // One stroke with the left button from the ground point a to b; the checks of the effect come in the steps that follow it.
    auto stroke = [this, &step, panel_at](float ax, float az, float bx, float bz) {
        step(2, [this, panel_at, ax, az] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_at(ax, az)); });
        step(3, [this] {
            at_check(vpHovered_, "the mouse is over the viewport (no panel covers it)");
            at_check(terrain_.hasHit, std::string("the brush finds the ground under the mouse (tool ") +
                                          (terrain_tool_active() ? "on" : "off") + ")");
            at_check(terrain_.ringSegments > 0, "the cursor ring is drawn on the terrain");
        });
        step(2, [this, panel_at, ax, az] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, panel_at(ax, az)); });
        for (int i = 1; i <= 8; ++i)
            step(2, [this, panel_at, ax, az, bx, bz, i] {
                const float k = float(i) / 8.0f;
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_at(ax + (bx - ax) * k, az + (bz - az) * k));
            });
        step(3, [this] { at_check(terrain_.stroke.active(), "the stroke is live while the button is down"); });
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

    // ---- the scene: a camera, a light, a terrain of 64 x 64 m (1 m per sample) at height 2 with two layers
    step(2, [this, project_file, m] {
        stop();
        write_file(project_file(scenePath_), kTerrainScene);
        reload_scene_from_disk();
        const CommandResult c = engine_->commands().call(
            "terrain.create",
            Json::parse(R"({"name":"t3_ground","size":[64,64],"resolution":65,"heightScale":50,"baseHeight":2})"));
        at_check(c.ok, "terrain.create makes the terrain of the section: " + c.error.dump());
        const CommandResult l = engine_->commands().call(
            "scene.set_component",
            Json::parse(
                R"({"id":"t3_ground","component":"Terrain","fields":{"layers":[{"albedo":"assets/terrain/t3_a.png"},{"albedo":"assets/terrain/t3_b.png"}]}})"));
        at_check(l.ok, "two layers are set: " + l.error.dump());
        select_id("t3_ground");
        terrain_ = TerrainUi{};
        terrain_.brush = BrushSettings{4.0f, 1.0f, 1.0f};
        terrain_.amount = 0.5f;
        showTerrainTool_ = true;
        pendingFocus_ = "Terrain tool";
        dirty_ = false;
        m->undo0 = undo_depth();
    });
    step(4, [this] { pendingFocus_ = "Terrain tool"; });
    // The panel docks next to the Inspector on a first run, but a layout saved on disk, a small display or a floating window can put
    // it over the strokes: a panel that is not docked and overlaps the viewport image moves to the top-left, over the left column.
    step(3, [this] {
        ImGuiWindow* w = ImGui::FindWindowByName("Terrain tool");
        at_check(w != nullptr, "the Terrain tool window exists");
        if (!w || w->DockId != 0 || w->DockNode != nullptr) return;
        const bool over = w->Pos.x < vpImageMin_.x + vpImageSize_.x && w->Pos.x + w->Size.x > vpImageMin_.x &&
                          w->Pos.y < vpImageMin_.y + vpImageSize_.y && w->Pos.y + w->Size.y > vpImageMin_.y;
        if (!over) return;
        ImGui::SetWindowPos(w, ImVec2(8, 28));
        ImGui::SetWindowSize(w, ImVec2(std::max(120.0f, std::min(340.0f, vpImageMin_.x - 16.0f)), 520));
    });
    step(2, [this, heights] {
        at_check(heights() != nullptr, "the terrain's heights are loaded");
        at_check(at_visible("terrain:mode:sculpt") && at_visible("terrain:mode:paint") &&
                     at_visible("terrain:mode:holes"),
                 "the panel lists the Sculpt, Paint and Holes modes");
        at_check(!terrain_tool_active(), "no mode is on yet: the viewport tool is off and the gizmo keeps the clicks");
    });

    // ---- Sculpt: a raise stroke
    click("terrain:mode:sculpt");
    step(4, [this] {
        at_check(terrain_.mode == TerrainMode::Sculpt && terrain_tool_active(), "Sculpt turns the viewport tool on");
        at_check(at_visible("terrain:sculpt:raise") && at_visible("terrain:radius") && at_visible("terrain:falloff"),
                 "the panel shows the sculpt tools and the brush settings");
    });
    step(2, [this, heights, m] {
        const std::shared_ptr<TerrainHeights> h = heights();
        m->before = checksum(*h);
        m->history0 = h->undo_depth();
        m->undo0 = undo_depth();
        m->strokes0 = terrain_.strokes;
        float y = 0;
        (void)terrain_height_at(world(), world().find_by_id("t3_ground"), 0, 0, y);
        m->centreBefore = y;
    });
    stroke(-10, 0, 10, 0);
    step(2, [this, heights, m] {
        const std::shared_ptr<TerrainHeights> h = heights();
        m->after = checksum(*h);
        at_check(terrain_.strokes == m->strokes0 + 1, "the stroke ended");
        at_check(m->after != m->before, "the sculpt stroke changed the heights");
        at_check(terrain_.pieces >= 2,
                 "...sent as several commands while the mouse moved (" + std::to_string(terrain_.pieces) + ")");
        at_check(undo_depth() == m->undo0 + 1, "...and is ONE undo step of the editor (depth " +
                                                   std::to_string(undo_depth()) + " from " + std::to_string(m->undo0) +
                                                   ")");
        at_check(h->undo_depth() == m->history0 + 1, "...and ONE step of the terrain's own history");
        at_check(dirty() && has_unsaved_work(), "...and the scene is dirty");
        float y = 0;
        (void)terrain_height_at(world(), world().find_by_id("t3_ground"), 0, 0, y);
        at_check(y > m->centreBefore + 0.1f, "...and the ground is higher under the stroke (" +
                                                 std::to_string(m->centreBefore) + " -> " + std::to_string(y) + ")");
    });
    // Ctrl+Z through the keyboard shortcut
    hold_ctrl(true);
    step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_Z); });
    step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_Z); });
    hold_ctrl(false);
    step(3, [this, heights, m] {
        at_check(checksum(*heights()) == m->before,
                 "Ctrl+Z gives back the exact heights of before the stroke (one press)");
        at_check(undo_depth() == m->undo0 && redo_depth() == 1, "...and the redo stack holds the stroke");
    });
    step(2, [this] { redo(); });
    step(3, [this, heights, m] {
        at_check(checksum(*heights()) == m->after, "Redo gives back the exact heights of the stroke");
        at_check(undo_depth() == m->undo0 + 1 && redo_depth() == 0, "...and the undo stack holds it again");
    });

    // ---- an undo of an unrelated edit (a scene snapshot) must not take the unsaved terrain with it
    step(2, [this] {
        begin_edit("t3:camera");
        if (Transform* t = world().get<Transform>(world().find_by_id("t3_camera"))) t->position.y += 1.0f;
        undo();  // restores the snapshot taken before the edit: the scene is loaded again
    });
    step(3, [this, heights, m] {
        const Entity cam = world().find_by_id("t3_camera");
        const Transform* t = cam.is_null() ? nullptr : world().get<Transform>(cam);
        at_check(t && std::fabs(t->position.y - 30.0f) < 1e-3f, "the snapshot undo restored the camera");
        const std::shared_ptr<TerrainHeights> h = heights();
        at_check(h && checksum(*h) == m->after, "...and the terrain kept its unsaved sculpt (no silent loss)");
        at_check(h && h->undo_depth() == m->history0 + 1, "...and its undo history");
        select_id("t3_ground");
    });

    // ---- Paint: layer 1
    click("terrain:mode:paint");
    step(4, [this] { at_check(terrain_.mode == TerrainMode::Paint, "the Paint mode is on"); });
    click("terrain:layer:1");
    step(3, [this, heights, m] {
        at_check(terrain_.layer == 1, "the second layer is picked in the panel");
        const std::shared_ptr<TerrainHeights> h = heights();
        m->before = checksum(*h);
        m->paintedBefore = weighted(*h, 1);
        m->undo0 = undo_depth();
        m->history0 = h->undo_depth();
    });
    stroke(-12, 8, 12, 8);
    step(3, [this, heights, m] {
        const std::shared_ptr<TerrainHeights> h = heights();
        m->after = checksum(*h);
        at_check(weighted(*h, 1) > m->paintedBefore,
                 "the paint stroke put weight on layer 1 (" + std::to_string(weighted(*h, 1)) + " texels)");
        at_check(undo_depth() == m->undo0 + 1 && h->undo_depth() == m->history0 + 1,
                 "...as one undo step of the editor and one of the terrain");
        undo();
    });
    step(3, [this, heights, m] {
        const std::shared_ptr<TerrainHeights> h = heights();
        at_check(weighted(*h, 1) == m->paintedBefore, "Undo takes the paint back");
        redo();
    });
    step(3, [this, heights, m] {
        at_check(checksum(*heights()) == m->after, "Redo gives the painted splat map back exactly");
    });

    // ---- Holes: a cut
    click("terrain:mode:holes");
    step(4, [this, heights, m] {
        at_check(terrain_.mode == TerrainMode::Holes && at_visible("terrain:holes:cut"),
                 "the Holes mode shows Cut and Fill");
        const std::shared_ptr<TerrainHeights> h = heights();
        m->before = checksum(*h);
        m->undo0 = undo_depth();
        m->history0 = h->undo_depth();
        at_check(holes_cut(*h) == 0, "no hole yet");
    });
    stroke(-12, -8, 12, -8);
    step(3, [this, heights, m] {
        const std::shared_ptr<TerrainHeights> h = heights();
        m->after = checksum(*h);
        at_check(holes_cut(*h) > 0, "the holes stroke cut holes (" + std::to_string(holes_cut(*h)) + " cells)");
        at_check(undo_depth() == m->undo0 + 1 && h->undo_depth() == m->history0 + 1,
                 "...as one undo step of the editor and one of the terrain");
        undo();
    });
    step(3, [this, heights, m] {
        at_check(holes_cut(*heights()) == 0, "Undo fills the holes again");
        redo();
    });
    step(3, [this, heights, m] { at_check(checksum(*heights()) == m->after, "Redo cuts them again exactly"); });

    // ---- Save: a write error is told and keeps every edit; then the files are written
    step(2, [this, heights, m] {
        const Entity e = world().find_by_id("t3_ground");
        const Terrain3D* t = world().get<Terrain3D>(e);
        at_check(t && !t->holes.empty() && !t->splatMaps.empty(),
                 "the first holes and paint strokes set Terrain.holes and Terrain.splatMaps");
        if (!t) return;
        m->holesPath = t->holes;
        at_check(!fs::exists(m->holesPath), "nothing was written before the save");
        // A directory where the holes image goes: the write fails.
        std::error_code ec;
        std::filesystem::create_directories(fs::path_from_utf8(projectDir_ + "/" + m->holesPath), ec);
        toasts_.clear();
        const bool saved = save_scene_now();
        at_check(!saved, "Save fails when a terrain file cannot be written");
        bool told = false;
        for (const Toast& t2 : toasts_)
            if (t2.level == 2 && t2.text.find("Save failed") != std::string::npos) told = true;
        at_check(told, "...and says so in a toast");
        at_check(dirty() && has_unsaved_work() && heights()->any_unsaved(), "...and nothing is marked as saved");
        std::filesystem::remove_all(fs::path_from_utf8(projectDir_ + "/" + m->holesPath), ec);
    });
    step(2, [this, heights, m] {
        at_check(save_scene_now(), "Save writes the scene and the terrain files");
        const std::shared_ptr<TerrainHeights> h = heights();
        at_check(!h->any_unsaved() && !dirty() && !has_unsaved_work(), "...and nothing is unsaved afterwards");
        at_check(fs::exists("assets/terrain/t3_ground.height.png") && fs::exists(m->holesPath),
                 "...the heights and the holes image exist");
        const Terrain3D* t = world().get<Terrain3D>(world().find_by_id("t3_ground"));
        at_check(t && t->splatMaps.is_array() && !t->splatMaps.empty() && t->splatMaps[0].is_string() &&
                     fs::exists(t->splatMaps[0].get<std::string>()),
                 "...and the splat map");
    });

    // ---- terrain edits the scene file does not hold are asked about on close, even when the scene itself is clean
    step(2, [this] { terrain_.mode = TerrainMode::Sculpt; });
    stroke(-6, -2, 6, -2);
    step(3, [this, heights] {
        dirty_ = false;  // as if only the terrain differed from disk
        at_check(heights()->any_unsaved() && has_unsaved_work(),
                 "an unsaved terrain edit counts as unsaved work on its own");
        forget_unsaved_terrain();
        at_check(!has_unsaved_work(), "Discard marks the terrains as written");
    });

    // ---- Esc cancels a stroke and gives back the dirty state it found (nothing was edited, so nothing is unsaved)
    step(2, [this, heights, m, panel_at] {
        dirty_ = false;
        m->before = checksum(*heights());
        inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_at(-6, 2));
    });
    step(2, [this, panel_at] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, panel_at(-6, 2)); });
    step(2, [this, panel_at] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_at(0, 2)); });
    step(3, [this, heights, m] {
        at_check(terrain_.stroke.active() && checksum(*heights()) != m->before,
                 "a stroke is live and changed the heights");
        inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_ESCAPE);
    });
    step(3, [this, heights, m] {
        inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_ESCAPE);
        at_check(!terrain_.stroke.active(), "Esc ends the stroke");
        at_check(checksum(*heights()) == m->before, "...and gives the heights back");
        at_check(!dirty() && !heights()->any_unsaved() && !has_unsaved_work(),
                 "...and the scene and the terrain are as clean as before the stroke");
    });
    step(2, [this, panel_at] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, panel_at(0, 2)); });
    step(3, [] {});

    // ---- a click that misses the terrain keeps the selection and the tool
    step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{vpImageMin_.x + 3, vpImageMin_.y + 3}); });
    step(3, [this] {
        if (terrain_.hasHit) return;  // this camera sees the ground in that corner: nothing to check
        inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, Vec2{vpImageMin_.x + 3, vpImageMin_.y + 3});
    });
    step(2, [this] {
        if (terrain_.hasHit) return;
        inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, Vec2{vpImageMin_.x + 3, vpImageMin_.y + 3});
    });
    step(4, [this] {
        at_check(selected_id() == "t3_ground" && terrain_tool_active(),
                 "a click that misses the terrain keeps it selected and the tool on");
    });

    // ---- Play and Stop: the game edits its own copy; Stop gives back the heights, the holes and the splat maps exactly
    step(2, [this, heights, m] {
        m->before = checksum(*heights());
        m->history0 = heights()->undo_depth();
        play();
    });
    step(6, [this, heights, m] {
        at_check(play_ != PlayState::Edit, "Play started");
        const std::shared_ptr<TerrainHeights> h = heights();
        at_check(h != nullptr && checksum(*h) == m->before, "the game starts from the terrain as the editor has it");
        const CommandResult c = engine_->commands().call(
            "terrain.sculpt",
            Json::parse(R"({"entity":"t3_ground","tool":"raise","center":[5,5],"radius":8,"amount":9,"strength":1})"));
        at_check(c.ok, "the game can sculpt its terrain: " + c.error.dump());
        at_check(h && checksum(*h) != m->before, "...and it changed during Play");
        const CommandResult p = engine_->commands().call(
            "terrain.holes", Json::parse(R"({"entity":"t3_ground","center":[-5,-5],"radius":4,"mode":"cut"})"));
        at_check(p.ok, "...and cut holes: " + p.error.dump());
    });
    step(2, [this] { stop(); });
    step(6, [this, heights, m] {
        at_check(play_ == PlayState::Edit, "Stop returned to editing");
        const std::shared_ptr<TerrainHeights> h = heights();
        at_check(h != nullptr && checksum(*h) == m->before,
                 "Stop gives back the exact heights, holes and splat maps of before Play");
        at_check(h && h->undo_depth() == m->history0,
                 "...and the terrain's history (" + std::to_string(m->history0) + ")");
    });

    // ---- leave the fixture the next sections expect
    step(2, [this, project_file] {
        terrain_ = TerrainUi{};
        showTerrainTool_ = false;
        write_file(project_file(scenePath_), kFixtureScene);
        reload_scene_from_disk();
        select_id("");
        dirty_ = false;
    });
}

}  // namespace fa::editor
