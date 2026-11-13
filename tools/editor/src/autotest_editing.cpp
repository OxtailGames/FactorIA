// Autotest sections K to N: a custom material, hand editing in the Hierarchy and the Inspector, the transform gizmos and the
// Project panel.
// Split from autotest_tools.cpp: each section is an Editor::at_section_<id>(AtScript&) that adds its steps to the script,
// called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <memory>

#include "ai_project_edit.h"
#include "auto_play_job.h"
#include "autotest_common.h"
#include "autotest_sections.h"
#include "editor_internal.h"
#include "fa/ai/command_hooks.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/savers.h"
#include "fa/core/date.h"
#include "fa/core/jobs.h"
#include "fa/tooling/feedback_share.h"
#include "fa/tooling/net.h"
#include "fa/tooling/qr.h"
#include "sokol_app.h"
#include "imgui_internal.h"
#include "ui_backend.h"

namespace fa::editor {

using namespace at_support;

namespace {

namespace stdfs = std::filesystem;

// Section K: a 3D scene with one cube drawn by a custom material (docs/design/CUSTOM_SHADERS.md). The snippet adds `glow` to the
// emission; the "v2" snippet also paints the albedo blue, and the broken one is a GLSL error on line 3.
const char* kMatScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [0, 1.5, 4] }, "Camera": { "projection": "perspective", "fov": 60, "primary": true } } },
    { "id": "sun", "components": { "Transform": { "position": [0, 5, 0], "rotation": [-50, 30, 0] }, "Light": { "intensity": 0.8 } } },
    { "id": "gem", "components": { "Transform": { "scale": [1.5, 1.5, 1.5] },
        "MeshRenderer": { "mesh": "cube", "color": [0.125, 0.125, 0.125, 1], "material": "materials/autotest_glow.material.json" } } }
  ]
})";
const char* kMatFile = R"({
  "format": "factoria.material/1",
  "doc": "Editor autotest: adds the glow color to the emission.",
  "shader": "shaders/autotest_glow.surface.glsl",
  "params": { "glow": { "type": "color", "default": [1.0, 0.35, 0.0, 1.0], "doc": "Emission color; its alpha scales the strength." } }
})";
const char* kMatSnippet = "void surface(in SurfaceInput i, inout Surface s) {\n    s.emission += glow.rgb * glow.a;\n}\n";
const char* kMatSnippetV2 = "void surface(in SurfaceInput i, inout Surface s) {\n    s.albedo = vec3(0.0, 0.0, 1.0);\n    s.emission += glow.rgb * glow.a;\n}\n";
const char* kMatSnippetBroken = "void surface(in SurfaceInput i, inout Surface s) {\n    s.albedo = vec3(0.0, 0.0, 1.0);\n    s.colour = glow.rgb;\n}\n";

// Section L: a cube with a material that has a ranged float, a vec3 and a color param (the Inspector types them by material.info).
const char* kInspectScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [0, 1.5, 4] }, "Camera": { "projection": "perspective", "fov": 60, "primary": true } } },
    { "id": "sun", "components": { "Transform": { "position": [0, 5, 0], "rotation": [-50, 30, 0] }, "Light": { "intensity": 0.8 } } },
    { "id": "gem", "components": { "Transform": { "scale": [1.5, 1.5, 1.5] },
        "MeshRenderer": { "mesh": "cube", "color": [0.125, 0.125, 0.125, 1], "material": "materials/autotest_inspect.material.json" } } }
  ]
})";
const char* kInspectMatFile = R"({
  "format": "factoria.material/1",
  "doc": "Editor autotest: params of three types for the Inspector.",
  "shader": "shaders/autotest_glow.surface.glsl",
  "params": {
    "glow": { "type": "color", "default": [1.0, 0.35, 0.0, 1.0], "doc": "Emission color; its alpha scales the strength." },
    "pulse": { "type": "float", "default": 1.0, "min": 0.0, "max": 4.0, "doc": "Pulses per second (0 to 4)." },
    "tint": { "type": "vec3", "default": [1.0, 1.0, 1.0], "doc": "Multiplies the base color." }
  }
})";

// Section M2: a tilted cube under a perspective camera (3D gizmos), and a screen-space (HUD) rectangle under a 2D camera.
const char* kGizmo3dScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [0, 0, 6] }, "Camera": { "projection": "perspective", "fov": 60, "primary": true } } },
    { "id": "sun", "components": { "Transform": { "position": [0, 5, 0], "rotation": [-50, 30, 0] }, "Light": { "intensity": 0.8 } } },
    { "id": "gem", "components": { "Transform": { "rotation": [10, 20, 0] }, "MeshRenderer": { "mesh": "cube", "color": [0.9, 0.5, 0.2, 1] } } }
  ]
})";
const char* kGizmoHudScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [0, 0, 0] }, "Camera": { "clearColor": [0.35, 0.55, 0.85, 1], "primary": true } } },
    { "id": "hud", "name": "Score",
      "components": { "Transform": { "position": [300, 200, 0] }, "Shape2D": { "size": [160, 48], "color": [0.95, 0.35, 0.3, 1], "space": "screen" } } }
  ]
})";

// The entity `id` in a saved scene's entities (children searched too), or nullptr.
const Json* find_saved_entity(const Json& list, const std::string& id) {
    if (!list.is_array()) return nullptr;
    for (const Json& e : list) {
        if (e.value("id", std::string()) == id) return &e;
        if (e.contains("children"))
            if (const Json* c = find_saved_entity(e["children"], id)) return c;
    }
    return nullptr;
}

struct MatShots {
    Image base, green, undone, v2, broken, fixed, playing;
    bool skip = false;      // no shader compiler on this machine: the section only records that
    std::uint64_t seq = 0;  // last log seq before the edit under test
    int edits = 0;          // makes every rewritten file's modification time new
    Json state;             // the material's state in the renderer before the last rewrite
};

}  // namespace

void Editor::at_section_K(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // --------------------------------------------------- K. A custom material: params, snippet reload, a broken snippet
    // The editor runs with hotReloadAssets: a material or snippet rewritten on disk (by the AI's file tools, or by hand) shows in
    // the viewport without a reload, in edit mode and while playing, and a broken edit keeps the last good picture and logs once.
    {
        auto ms = std::make_shared<MatShots>();
        const std::string snippet = project_file("shaders/autotest_glow.surface.glsl");
        // How much the viewport picture of two shots differs, in 0..255 per channel (the rest of the window, with the Console,
        // changes with every log line and says nothing about the viewport).
        auto vp_diff = [this](const Image& a, const Image& b) {
            if (a.rgba.size() != b.rgba.size() || a.rgba.empty()) return 1e9;
            const int x0 = int(vpImageMin_.x * dpi_), y0 = int(vpImageMin_.y * dpi_);
            const int x1 = std::min(a.width, x0 + int(vpImageSize_.x * dpi_)), y1 = std::min(a.height, y0 + int(vpImageSize_.y * dpi_));
            double sum = 0;
            long n = 0;
            for (int y = std::max(0, y0); y < y1; ++y)
                for (int x = std::max(0, x0); x < x1; ++x)
                    for (int c = 0; c < 3; ++c, ++n)
                        sum += std::abs(int(a.rgba[(size_t(y) * size_t(a.width) + size_t(x)) * 4 + size_t(c)]) -
                                        int(b.rgba[(size_t(y) * size_t(b.width) + size_t(x)) * 4 + size_t(c)]));
            return n ? sum / double(n) : 1e9;
        };
        // A viewport comparison: the same picture (`same`) or a changed one. The message carries the difference; on a failure
        // every shot of this section and the material's state are kept in the autotest's output (a CI artifact on macOS).
        auto diff_check = [this, ms, vp_diff](const Image& a, const Image& b, bool same, const std::string& what) {
            const double d = vp_diff(a, b);
            const bool ok = same ? d < 0.05 : d > 1.0;
            std::string detail = " (viewport difference " + std::to_string(d) + ")";
            if (!ok) {
                const std::pair<const char*, const Image*> shots[] = {{"base", &ms->base}, {"green", &ms->green}, {"undone", &ms->undone},
                    {"v2", &ms->v2}, {"broken", &ms->broken}, {"fixed", &ms->fixed}, {"playing", &ms->playing}};
                for (const auto& [name, img] : shots)
                    if (!img->rgba.empty()) (void)save_png(*img, atOutDir_ + "/material_" + name + ".png");
                detail += "; shots saved as material_*.png; materials: " + engine_->renderer()->asset_report()["materials"].dump();
            }
            at_check(ok, what + detail);
        };
        // The material's state in the renderer: its generation (+1 per build that worked) and its last error. A reload of the
        // snippet changes it, whether the new snippet compiles or not.
        auto material_state = [this] {
            const Json report = engine_->renderer()->asset_report();
            for (const Json& m : report["materials"])
                if (m.value("material", std::string()) == "materials/autotest_glow.material.json") return m;
            return Json();
        };
        // Rewrites a project file so its modification time is different from the last write, whatever the file system's resolution.
        auto rewrite = [ms, material_state](const std::string& path, const std::string& text) {
            ms->state = material_state();
            write_file(path, text);
            std::error_code ec;
            stdfs::last_write_time(path, stdfs::file_time_type::clock::now() + std::chrono::seconds(10 * ++ms->edits), ec);
        };
        // Waits until the renderer took the rewritten snippet, polling once a frame for at most 300 frames (a reload is the 0.25 s
        // poll plus a compile, slow on a software GPU), then 5 frames to draw it.
        struct Reloaded {
            Editor* ed;
            std::shared_ptr<MatShots> ms;
            std::function<Json()> state;
            int left;
            void operator()() const {
                if (ms->skip) return;
                if (state() != ms->state) ed->atSteps_.push_front(AtStep{5, [] {}});
                else if (left == 0) ed->at_check(false, "the renderer reloaded the rewritten snippet within 300 frames");
                else ed->atSteps_.push_front(AtStep{1, Reloaded{ed, ms, state, left - 1}});
            }
        };
        auto wait_reload = [this, ms, material_state, &step] { step(1, Reloaded{this, ms, material_state, 300}); };
        // A shot for vp_diff, like snap() without toasts: they fade on their own clock over the viewport (the "Reloaded" one of
        // the scene was in one shot and gone in the next on a slow runner).
        auto grab = [this, &step](Image MatShots::*which, std::shared_ptr<MatShots> shots) {
            step(3, [this] { toasts_.clear(); });
            step(3, [this, which, shots] {
                atPostFrame_.push_back([this, which, shots] { at_check(capture_window((*shots).*which), "captured the viewport"); });
            });
        };
        // Errors the AI would read: game.logs, from the seq noted before the edit.
        auto errors_naming = [this](std::uint64_t after) {
            const CommandResult r = engine_->commands().call("game.logs", Json::object({{"minLevel", "error"}, {"after", after}}));
            int n = 0;
            if (r.ok)
                for (const Json& l : r.result["logs"])
                    if (l["message"].get<std::string>().find("shaders/autotest_glow.surface.glsl:") != std::string::npos) ++n;
            return n;
        };

        step(2, [this, project_file] {
            stop();
            write_file(project_file("materials/autotest_glow.material.json"), kMatFile);
            write_file(project_file("shaders/autotest_glow.surface.glsl"), kMatSnippet);
            write_file(project_file(scenePath_), kMatScene);
            reload_scene_from_disk();
            select_id("");
            focus_window("###Viewport");
        });
        step(20, [] {});
        grab(&MatShots::base, ms);
        step(2, [this, ms] {
            const Renderer* r = engine_->renderer();
            ms->skip = !r || !r->stats().materialFallbacks.empty();
            // CI installs the compiler and sets FA_REQUIRE_SHDC=1 (docs/BUILDING.md): there a material that did not build fails.
            const char* required = std::getenv("FA_REQUIRE_SHDC");
            if (ms->skip && required && std::string(required) == "1") at_check(false, "the custom material builds (FA_REQUIRE_SHDC=1)");
            else if (ms->skip) atLog_.push_back("SKIP custom material section (the material did not build: no sokol-shdc? set SOKOL_SHDC)");
        });
        // (a) materialParams through a Console command, the way the AI edits; Undo brings the picture back.
        step(2, [this, ms] {
            if (ms->skip) return;
            run_console_line(R"(scene.set_component {"id":"gem","component":"MeshRenderer","fields":{"materialParams":{"glow":[0,1,0,1]}}})");
        });
        step(8, [] {});
        grab(&MatShots::green, ms);
        step(2, [this, ms, diff_check] {
            if (ms->skip) return;
            diff_check(ms->base, ms->green, false, "a materialParams edit from the Console changes the viewport");
            undo();
        });
        step(8, [] {});
        grab(&MatShots::undone, ms);
        step(2, [ms, diff_check] {
            if (ms->skip) return;
            diff_check(ms->base, ms->undone, true, "Undo brings the previous viewport picture back");
            ms->seq = log_last_seq();
        });
        // (b) the snippet rewritten on disk: the new picture shows after the poll, with no reload.
        step(2, [ms, rewrite, snippet] {
            if (!ms->skip) rewrite(snippet, kMatSnippetV2);
        });
        wait_reload();
        grab(&MatShots::v2, ms);
        step(2, [this, ms, diff_check] {
            if (ms->skip) return;
            diff_check(ms->base, ms->v2, false, "a snippet rewritten on disk changes the viewport without a reload");
            at_check(engine_->renderer()->stats().materialFallbacks.empty(), "...and the material still builds");
            ms->seq = log_last_seq();
        });
        // (c) a broken snippet: the last good picture stays, one error names file:line, and the AI reads it from game.logs.
        step(2, [ms, rewrite, snippet] {
            if (!ms->skip) rewrite(snippet, kMatSnippetBroken);
        });
        wait_reload();
        grab(&MatShots::broken, ms);
        step(2, [this, ms, diff_check, errors_naming] {
            if (ms->skip) return;
            diff_check(ms->v2, ms->broken, true, "a broken snippet keeps the last good picture");
            at_check(errors_naming(ms->seq) == 1, "...and logs exactly one error with file:line (game.logs shows it to the AI)");
            at_check(engine_->renderer()->stats().materialFallbacks.empty(), "...without falling back to the error material");
            showOverlay_ = false;  // no selection outline in the pictures compared below
            select_id("gem");      // the Inspector shows the build error under MeshRenderer.material
        });
        step(1, [this, ms] {  // the Inspector reads the renderer's report twice a second: wait for it (bounded)
            atWaitCount_ = 0;
            atWaitUntil_ = [this, ms] { return ms->skip || at_visible("insp:material:error"); };
        });
        step(4, [this, ms] {
            if (ms->skip) return;
            at_check(at_visible("insp:material:error"), "the Inspector shows the material's build error under the material field");
            const std::string shown = material_build_error(assetReport_, "materials/autotest_glow.material.json");
            at_check(shown.find("autotest_glow.surface.glsl") != std::string::npos, "...naming the snippet file (" + shown.substr(0, 120) + ")");
        });
        snap("editor_inspector_material_error.png");
        step(2, [ms, rewrite, snippet] {
            if (!ms->skip) rewrite(snippet, kMatSnippetV2);
        });
        wait_reload();
        grab(&MatShots::fixed, ms);
        step(2, [ms, diff_check] {
            if (ms->skip) return;
            diff_check(ms->v2, ms->fixed, true, "fixing the snippet recovers the picture");
        });
        step(1, [this, ms] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, ms] { return ms->skip || !at_visible("insp:material:error"); };
        });
        step(4, [this, ms] {
            if (ms->skip) return;
            at_check(!at_visible("insp:material:error"), "the Inspector's build error is gone once the snippet builds again");
            select_id("");
            showOverlay_ = true;
        });
        // While playing: the same reload, without leaving Play.
        step(2, [this, ms] {
            if (ms->skip) return;
            play();
        });
        step(10, [ms, rewrite, snippet] {
            if (!ms->skip) rewrite(snippet, kMatSnippet);
        });
        wait_reload();
        grab(&MatShots::playing, ms);
        step(2, [this, ms, diff_check] {
            if (ms->skip) return;
            at_check(play_state() == PlayState::Playing, "the game is playing");
            diff_check(ms->v2, ms->playing, false, "a snippet rewritten on disk changes the viewport while the game plays");
            stop();
        });
    }
}

void Editor::at_section_L(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------- L. Hand editing: the Hierarchy and the Inspector, with the mouse
    // The acceptance of M20's hand editing: select in the tree by clicking, click a number in the Inspector, type a value, Enter;
    // the world changed, one undo step was added, Save writes it into the scene file. Drag and drop in the tree reparents.
    {
        struct HandEdit {
            size_t undo = 0;
            Vec3 coinWorld{};
        };
        auto he = std::make_shared<HandEdit>();
        auto type_text = [this, &step](const std::string& text) {
            step(3, [this, text] {
                for (char c : text) inject_char(unsigned(static_cast<unsigned char>(c)));
            });
        };
        auto press_enter = [this, &step] {
            step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_ENTER); });
            step(4, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_ENTER); });
        };
        auto right_click = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name), 1); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name), 1); });
        };
        // Drag `from` over `to` and let go: ImGui's drag and drop needs the mouse to travel with the button held.
        auto drag = [this, &step](const std::string& from, const std::string& to) {
            auto start = std::make_shared<Vec2>();
            step(2, [this, from, start] {
                *start = at_widget(from);
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, *start);
            });
            step(2, [this, start] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, *start); });
            step(2, [this, start] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{start->x + 6, start->y + 14}); });
            step(2, [this, to] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(to)); });
            step(3, [this, to] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(to)); });
            step(4, [this, to] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(to)); });
        };
        auto scene_file = [this, project_file] {
            auto loaded = load_json_file(project_file(scenePath_));
            return loaded ? *loaded : Json::object();
        };
        auto position_of = [this](const char* id) {
            Entity e = world().find_by_id(id);
            const Transform* t = e.is_null() ? nullptr : world().get<Transform>(e);
            return t ? t->position : Vec3{9999, 9999, 9999};
        };

        step(2, [this, project_file] {
            stop();
            select_id("");
            showHierarchy_ = showInspector_ = true;
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            focus_window("###Viewport");
        });
        step(10, [this] {
            at_check(at_visible("tree:coin_2") && at_visible("tree:player") && at_visible("tree:camera"), "the Hierarchy lists the scene's entities");
            at_check(!at_visible("insp:Transform.position.0"), "the Inspector shows nothing with no entity selected");
        });
        snap("editor_hierarchy_empty.png");

        // 1. Select in the tree: the Inspector shows the entity.
        click("tree:coin_2");
        step(4, [this] {
            at_check(selected_id() == "coin_2", "clicking an entity in the Hierarchy selects it");
            at_check(at_visible("insp:Transform.position.0") && at_visible("insp:Shape2D.thickness"), "the Inspector shows its components and fields");
            at_check(!at_enabled("insp:EntityInfo.id"), "a read-only field (the entity id) is disabled");
        });
        snap("editor_inspector.png");

        // 2. Click a number, type, Enter: the world changes with one undo step.
        step(2, [this, he] { he->undo = undo_depth(); });
        click("insp:Transform.position.0");
        step(4, [this] { at_check(ImGui::GetIO().WantTextInput, "clicking a number in the Inspector opens it for typing"); });
        type_text("300");
        press_enter();
        step(4, [this, he, position_of] {
            at_check(std::fabs(position_of("coin_2").x - 300.0f) < 0.01f && std::fabs(position_of("coin_2").y + 160.0f) < 0.01f,
                     "typing 300 and Enter sets Transform.position.x of the selected entity (y is kept)");
            at_check(undo_depth() == he->undo + 1 && dirty(), "...as ONE undo step, and the scene is dirty");
        });
        click("toolbar:save");
        step(4, [this, scene_file] {
            at_check(!dirty(), "Save clears the dirty flag");
            const Json scene = scene_file();
            const Json* coin = find_saved_entity(scene["entities"], "coin_2");
            at_check(coin && coin->contains("components") && (*coin)["components"]["Transform"]["position"][0] == 300,
                     "the scene file has the value typed in the Inspector");
        });
        click("toolbar:undo");
        step(4, [this, position_of] { at_check(std::fabs(position_of("coin_2").x - 250.0f) < 0.01f, "the Undo button takes the typed value back"); });

        // 3. A value the command refuses changes nothing, and its message shows under the field.
        step(2, [this, he] { he->undo = undo_depth(); });
        step(2, [this] { inspScrollTo_ = "Shape2D.thickness"; });  // a small window shows only the top of the Inspector
        step(3, [] {});
        click("insp:Shape2D.thickness");
        type_text("-5");
        press_enter();
        step(4, [this, he] {
            Entity c = world().find_by_id("coin_2");
            at_check(world().get<Shape2D>(c)->thickness >= 0.0f, "a value outside the field's range is refused: nothing changed");
            at_check(undo_depth() == he->undo, "...and the refused edit left no undo step");
            auto it = inspErrors_.find("Shape2D.thickness");
            at_check(it != inspErrors_.end() && it->second.find("thickness") != std::string::npos,
                     "...and the Inspector keeps the command's message for the field");
        });
        snap("editor_inspector_error.png");

        // 4. Add and remove a component.
        click("insp:add");
        step(3, [this] { at_check(at_visible("insp:add:Sprite"), "the Add Component list offers the components the entity lacks"); });
        click("insp:add:Sprite");
        step(2, [this] { inspScrollTo_ = "Sprite"; });
        step(3, [] {});
        step(4, [this] {
            at_check(world().has<Sprite>(world().find_by_id("coin_2")), "choosing a component in the list adds it with its defaults");
            at_check(at_visible("insp:hdr:Sprite"), "...and the Inspector shows its header");
        });
        click("insp:hdr:Sprite:x");
        step(4, [this] { at_check(!world().has<Sprite>(world().find_by_id("coin_2")), "the x on a component's header removes it"); });

        // 5. Reparent by drag and drop.
        step(2, [this] { toasts_.clear(); });
        step(2, [this, he] {
            he->undo = undo_depth();
            he->coinWorld = world().world_position(world().find_by_id("coin_3"));
        });
        drag("tree:coin_3", "tree:platform_1");
        step(4, [this, he] {
            World& w = world();
            at_check(w.parent(w.find_by_id("coin_3")) == w.find_by_id("platform_1"), "dragging an entity onto another in the Hierarchy makes it a child");
            at_check(undo_depth() == he->undo + 1, "...as one undo step");
            const Vec3 now = w.world_position(w.find_by_id("coin_3"));
            at_check(std::fabs(now.x - he->coinWorld.x) < 0.01f && std::fabs(now.y - he->coinWorld.y) < 0.01f,
                     "...and the entity stays where it was on screen");
        });
        click("toolbar:save");
        step(4, [this, scene_file] {
            const Json scene = scene_file();
            const Json* plat = find_saved_entity(scene["entities"], "platform_1");
            bool nested = false;
            if (plat && plat->contains("children"))
                for (const Json& c : (*plat)["children"]) nested = nested || c.value("id", std::string()) == "coin_3";
            bool topLevel = false;
            for (const Json& e : scene["entities"]) topLevel = topLevel || e.value("id", std::string()) == "coin_3";
            at_check(nested && !topLevel, "the scene file has the entity under its new parent");
        });
        snap("editor_hierarchy_children.png");
        drag("tree:coin_3", "tree:empty");
        step(4, [this] {
            World& w = world();
            at_check(w.parent(w.find_by_id("coin_3")).is_null(), "dropping an entity on the empty space of the Hierarchy moves it to the top level");
        });

        // 6. The context menu: create a child, rename, toggle active, delete.
        right_click("tree:coin_1");
        step(3, [this] { at_check(at_visible("tree:ctx:child") && at_visible("tree:ctx:delete"), "right-clicking an entity opens its context menu"); });
        click("tree:ctx:child");
        step(4, [this] {
            World& w = world();
            const Entity coin = w.find_by_id("coin_1");
            at_check(w.children(coin).size() == 1, "Create empty child adds an entity under it");
            at_check(!selected().is_null() && w.parent(selected()) == coin, "...and selects the new entity");
        });
        right_click("tree:coin_1");
        step(3, [] {});
        click("tree:ctx:rename");
        step(4, [this] { at_check(at_visible("tree:rename:text"), "Rename opens a box for the name"); });
        type_text("Gold");
        press_enter();
        step(4, [this] { at_check(world().info(world().find_by_id("coin_1")).name == "Gold", "typing a name and Enter renames the entity"); });
        right_click("tree:coin_1");
        step(3, [] {});
        click("tree:ctx:active");
        step(4, [this] { at_check(!world().info(world().find_by_id("coin_1")).active, "the Active item of the context menu deactivates the entity"); });
        snap("editor_hierarchy.png");
        right_click("tree:coin_3");
        step(3, [] {});
        click("tree:ctx:delete");
        step(4, [this] { at_check(world().find_by_id("coin_3").is_null(), "Delete removes the entity"); });
        click("toolbar:undo");
        step(4, [this] { at_check(!world().find_by_id("coin_3").is_null(), "Undo brings the deleted entity back"); });

        // 7. While the game plays an edit changes the running game, and Stop takes it back.
        step(2, [this, he] {
            he->undo = undo_depth();
            play();
        });
        step(6, [this] { select_id("player"); });
        step(6, [this] { at_check(at_visible("insp:Transform.position.0"), "the Inspector works while the game runs"); });
        click("insp:Transform.position.0");
        type_text("-111");
        press_enter();
        step(4, [this, he, position_of] {
            at_check(std::fabs(position_of("player").x + 111.0f) < 0.5f, "an edit while playing changes the running game");
            at_check(undo_depth() == he->undo, "...and adds no undo step (Stop discards it)");
        });
        snap("editor_inspector_play.png");
        step(2, [this] { stop(); });
        step(4, [this, position_of] { at_check(std::fabs(position_of("player").x + 300.0f) < 0.01f, "Stop takes the edit made while playing back"); });

        // 8. A material: its params typed by material.info, edited with the same commands.
        step(2, [this, project_file, he] {
            write_file(project_file("materials/autotest_inspect.material.json"), kInspectMatFile);
            write_file(project_file("shaders/autotest_glow.surface.glsl"), kMatSnippet);
            write_file(project_file(scenePath_), kInspectScene);
            reload_scene_from_disk();
            select_id("gem");
            he->undo = undo_depth();
        });
        step(30, [this] {
            at_check(at_visible("insp:matparam:pulse") && at_visible("insp:matparam:glow") && at_visible("insp:matparam:tint"),
                     "the Inspector lists the params of MeshRenderer.material, typed by material.info");
            at_check(!at_enabled("insp:matreset:pulse"), "...a param with no override cannot be reset");
        });
        // Scrolled once the material's build report is in: an error under the material field (no shader compiler on this
        // machine) pushes the params down, out of a small window's Inspector.
        step(2, [this] { inspScrollTo_ = "MeshRenderer.materialParams"; });
        step(3, [] {});
        click("insp:matparam:pulse");
        type_text("2.5");
        press_enter();
        step(4, [this, he] {
            const Json params = component_to_json(world(), world().find_by_id("gem"), *TypeRegistry::global().find("MeshRenderer"), true, false)["materialParams"];
            at_check(params.is_object() && params.value("pulse", 0.0) == 2.5, "typing a value for a material param writes it into materialParams");
            at_check(undo_depth() == he->undo + 1, "...as one undo step");
            at_check(at_enabled("insp:matreset:pulse"), "...and the param can now be reset");
        });
        click("insp:matparam:pulse");
        type_text("9");
        press_enter();
        step(4, [this] {
            const Json params = component_to_json(world(), world().find_by_id("gem"), *TypeRegistry::global().find("MeshRenderer"), true, false)["materialParams"];
            at_check(params.value("pulse", 0.0) == 4.0, "a value above the param's max is held to it (max 4)");
        });
        snap("editor_inspector_material.png");
        click("insp:matreset:pulse");
        step(4, [this] {
            const Json params = component_to_json(world(), world().find_by_id("gem"), *TypeRegistry::global().find("MeshRenderer"), true, false)["materialParams"];
            at_check(!params.contains("pulse"), "Reset removes the override: the material's default applies again");
            select_id("");
            reload_scene_from_disk();
        });
    }
}

void Editor::at_section_M(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------- M. Transform gizmos: move, rotate, scale in the viewport
    // The acceptance of the gizmos: select the player, press W / E / R, drag handles with the injected mouse. Every drag is one
    // undo step and a scene.set_component on Transform; Ctrl snaps; a child of a rotated, scaled parent follows the mouse in
    // world space; Esc puts the start value back with no undo step; Q hides the handles; none while Playing, but Paused edits the
    // running game; Save writes the values into the scene file.
    {
        struct Gz {
            Vec2 grab{}, cur{};
            Vec3 pos{}, rot{}, scl{};
            size_t undo = 0;
            double restUntil = 0;
        };
        auto g = std::make_shared<Gz>();
        auto tf = [this](const char* id) {
            Entity e = world().find_by_id(id);
            const Transform* t = e.is_null() ? nullptr : world().get<Transform>(e);
            return t ? *t : Transform{};
        };
        // Panel pixels per design pixel (= world unit with the fixture's camera).
        auto sc = [this] { return vpImageSize_.x / float(engine_->renderer()->target_width()); };
        auto sc_y = [this] { return vpImageSize_.y / float(engine_->renderer()->target_height()); };  // the image size is floored: not quite the same
        auto panel_of_player = [this] {
            const Vec2 d = engine_->renderer()->world_to_screen(world().world_position(world().find_by_id("player")));
            return Vec2{vpImageMin_.x + d.x / float(engine_->renderer()->target_width()) * vpImageSize_.x,
                        vpImageMin_.y + d.y / float(engine_->renderer()->target_height()) * vpImageSize_.y};
        };
        auto press = [this, &step](int keyCode) {
            step(3, [this, keyCode] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, keyCode); });
            step(3, [this, keyCode] { inject_key(SAPP_EVENTTYPE_KEY_UP, keyCode); });
        };
        auto ctrl = [this, &step](bool down) {
            step(2, [this, down] {
#if defined(__APPLE__)
                // Dear ImGui swaps Cmd and Ctrl on macOS (io.KeyCtrl is Cmd): the key a Mac user holds to snap is Cmd.
                atMods_ = down ? SAPP_MODIFIER_SUPER : 0;
                inject_key(down ? SAPP_EVENTTYPE_KEY_DOWN : SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_LEFT_SUPER);
#else
                atMods_ = down ? SAPP_MODIFIER_CTRL : 0;
                inject_key(down ? SAPP_EVENTTYPE_KEY_DOWN : SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_LEFT_CONTROL);
#endif
            });
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        // Grab a handle (at the point the layout says it can be grabbed), move the mouse to `target()` in one go, let go.
        auto grab = [this, &step, &wait_until, g](const std::string& handle) {
            step(2, [this, g, handle] {
                g->grab = g->cur = at_widget("gizmo:" + handle);
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, g->grab);
            });
            step(2, [this, g] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, g->grab); });
            wait_until([this] { return gizmoDrag_.active; });
        };
        auto move_to = [this, &step, &wait_until, g](std::function<Vec2()> target) {
            step(2, [this, g, target] {
                g->cur = target();
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, g->cur);
            });
            wait_until([this] { return gizmoDrag_.wrote; });
            step(3, [] {});
        };
        auto release = [this, &step, &wait_until, g] {
            step(2, [this, g] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, g->cur); });
            wait_until([this] { return !gizmoDrag_.active; });
            step(3, [] {});
        };
        auto drag_by = [&grab, &move_to, &release, g](const std::string& handle, float dx, float dy) {
            grab(handle);
            move_to([g, dx, dy] { return Vec2{g->grab.x + dx, g->grab.y + dy}; });
            release();
        };
        // A ring drag: from where the ring was grabbed (45 degrees up-right of the entity) to `degrees` of screen angle.
        auto ring_to = [&move_to, g, panel_of_player](float degrees) {
            move_to([g, panel_of_player, degrees] {
                const Vec2 c = panel_of_player();
                const float r = std::hypot(g->grab.x - c.x, g->grab.y - c.y);
                return Vec2{c.x + r * std::cos(degrees * kDegToRad), c.y + r * std::sin(degrees * kDegToRad)};
            });
        };
        auto remember = [this, g, tf] {
            const Transform t = tf("player");
            g->pos = t.position;
            g->rot = t.rotation;
            g->scl = t.scale;
            g->undo = undo_depth();
        };

        step(2, [this, project_file] {
            stop();
            select_id("player");
            gizmoMode_ = GizmoMode::Select;
            showHierarchy_ = showInspector_ = true;
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            select_id("player");
            focus_window("###Viewport");
        });
        // The mouse over the viewport (keys reach it while hovered or focused).
        step(4, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.25f}); });
        step(4, [this] { at_check(!at_visible("gizmo:move:x"), "Select mode shows no gizmo"); });
        click("toolbar:gizmo:move");
        step(4, [this] {
            at_check(gizmoMode_ == GizmoMode::Move, "the toolbar's Move button switches to the move gizmo");
            at_check(at_visible("gizmo:move:x") && at_visible("gizmo:move:y") && at_visible("gizmo:move:plane"),
                     "Move shows an arrow per axis and the free-move square on the selected entity");
            at_check(!at_visible("gizmo:move:z"), "...with no Z arrow under a 2D camera");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.25f});
        });
        press(SAPP_KEYCODE_Q);
        step(3, [this] { at_check(gizmoMode_ == GizmoMode::Select && !at_visible("gizmo:move:x"), "Q switches to Select: the gizmo disappears"); });
        press(SAPP_KEYCODE_W);
        step(3, [this] { at_check(gizmoMode_ == GizmoMode::Move && at_visible("gizmo:move:x"), "W switches to Move: the gizmo is back"); });
        snap("editor_gizmo_move.png");

        // Move: the X arrow. The world moved by what the mouse covered (px / panel scale) and y did not.
        step(2, remember);
        drag_by("move:x", 60, 25);
        step(2, [this, g, tf, sc] {
            const Transform t = tf("player");
            at_check(std::fabs(t.position.x - (g->pos.x + 60.0f / sc())) < 0.05f, "dragging the X arrow moves position.x by the world distance the mouse covered");
            at_check(t.position.y == g->pos.y && t.position.z == g->pos.z, "...and position.y / z did not change (the drag followed the axis)");
            at_check(undo_depth() == g->undo + 1, "the whole drag is ONE undo step");
            at_check(dirty_, "...and marks the scene dirty");
            undo();
            at_check(tf("player").position.x == g->pos.x, "Undo puts the position back");
        });
        // Move: the free square (the XY plane in 2D; y is down on screen, up in the world).
        step(2, remember);
        drag_by("move:plane", 30, 20);
        step(2, [this, g, tf, sc, sc_y] {
            const Transform t = tf("player");
            at_check(std::fabs(t.position.x - (g->pos.x + 30.0f / sc())) < 0.05f && std::fabs(t.position.y - (g->pos.y - 20.0f / sc_y())) < 0.05f,
                     "dragging the centre square moves the entity in both axes under the mouse");
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            undo();
        });

        // Rotate: a ring around Z. From 45 degrees on the ring to 0: a clockwise 45 on screen is -45 about Z (y is up).
        press(SAPP_KEYCODE_E);
        step(3, [this] { at_check(gizmoMode_ == GizmoMode::Rotate && at_visible("gizmo:rotate:z") && !at_visible("gizmo:rotate:x"), "E shows one rotation ring in 2D"); });
        snap("editor_gizmo_rotate.png");
        step(2, remember);
        grab("rotate:z");
        ring_to(0.0f);
        release();
        step(2, [this, g, tf] {
            const Transform t = tf("player");
            at_check(std::fabs(t.rotation.z + 45.0f) < 2.0f, "dragging the ring turns rotation.z with the mouse's angle around the entity (" + std::to_string(t.rotation.z) + ")");
            at_check(t.rotation.x == 0 && t.rotation.y == 0 && t.position.x == g->pos.x && t.scale.x == g->scl.x, "...and nothing else changes");
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            undo();
        });
        // Past 180 degrees the ring keeps turning: -45 to 135 on screen is +180 about the mouse, and the next half turn goes on.
        step(2, remember);
        grab("rotate:z");
        ring_to(-45.0f - 120.0f);
        ring_to(-45.0f - 240.0f);
        release();
        step(2, [this, tf] {
            const float z = tf("player").rotation.z;
            at_check(std::fabs(z - 240.0f) < 3.0f, "a drag that goes more than half a turn keeps turning (rotation.z " + std::to_string(z) + ", wanted 240)");
            undo();
        });

        // Scale: the X handle's box grows the entity along its own X only.
        press(SAPP_KEYCODE_R);
        step(3, [this] { at_check(gizmoMode_ == GizmoMode::Scale && at_visible("gizmo:scale:x") && at_visible("gizmo:scale:all"), "R shows scale handles and the uniform box"); });
        snap("editor_gizmo_scale.png");
        step(2, remember);
        drag_by("scale:x", 40, 0);
        step(2, [this, g, tf] {
            const Transform t = tf("player");
            at_check(std::fabs(t.scale.x - 1.5f) < 0.02f && t.scale.y == g->scl.y && t.scale.z == g->scl.z, "dragging the X handle scales x only (1 -> " + std::to_string(t.scale.x) + ")");
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            undo();
        });
        // A drag back through the pivot never reaches 0 or flips the sign.
        step(2, remember);
        drag_by("scale:x", -400, 0);
        step(2, [this, tf] {
            const Transform t = tf("player");
            at_check(t.scale.x > 0.0f && t.scale.x < 0.05f, "dragging a scale handle past the pivot holds a small positive value (" + std::to_string(t.scale.x) + ")");
            undo();
        });

        // Ctrl snaps the value: whole units (2D) for move, 15 degrees for rotate, 0.1 for scale. (Keys are ignored while Ctrl is held.)
        press(SAPP_KEYCODE_W);
        ctrl(true);
        drag_by("move:x", 33.3f, 0);
        step(2, [this, tf] {
            const float x = tf("player").position.x;
            at_check(std::fabs(x - std::round(x)) < 1e-3f, "Ctrl while dragging an arrow snaps the position to whole units (" + std::to_string(x) + ")");
            undo();
        });
        ctrl(false);
        press(SAPP_KEYCODE_E);
        ctrl(true);
        grab("rotate:z");
        ring_to(-45.0f + 100.0f);
        release();
        step(2, [this, tf] {
            const float z = tf("player").rotation.z;
            at_check(std::fabs(z) > 1.0f && std::fabs(z / 15.0f - std::round(z / 15.0f)) < 1e-3f, "Ctrl while dragging a ring snaps the rotation to 15 degrees (" + std::to_string(z) + ")");
            undo();
        });
        ctrl(false);
        press(SAPP_KEYCODE_R);
        ctrl(true);
        drag_by("scale:x", 37, 0);
        step(2, [this, tf] {
            const float s = tf("player").scale.x;
            at_check(s > 1.0f && std::fabs(s * 10.0f - std::round(s * 10.0f)) < 1e-2f, "Ctrl while dragging a scale handle snaps it to 0.1 (" + std::to_string(s) + ")");
            undo();
        });
        ctrl(false);
        press(SAPP_KEYCODE_W);

        // A child of a rotated and scaled parent ends where the mouse put it in world space (the value written is local).
        step(2, [this, g] {
            run_console_line(R"(scene.set_component {"id":"platform_1","component":"Transform","fields":{"rotation":[0,0,30],"scale":[1.5,1,1]}})");
            run_console_line(R"(scene.set_parent {"id":"coin_1","parent":"platform_1"})");
            select_id("coin_1");
            g->undo = undo_depth();
            g->pos = world().world_position(world().find_by_id("coin_1"));
        });
        step(4, [this] { at_check(!world().parent(world().find_by_id("coin_1")).is_null() && at_visible("gizmo:move:x"), "the child has the gizmo too"); });
        drag_by("move:x", 50, 0);
        step(2, [this, g, sc] {
            const Vec3 now = world().world_position(world().find_by_id("coin_1"));
            at_check(std::fabs(now.x - (g->pos.x + 50.0f / sc())) < 0.1f && std::fabs(now.y - g->pos.y) < 0.1f,
                     "a child of a rotated, scaled parent moves by the mouse's world distance (the local value written differs from it)");
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            select_id("player");
        });

        // Esc in the middle of a drag: the start value is back and no undo step is left behind. The mouse rests longer than the
        // 0.8 s that merges edits into one undo step before it moves on: still one step, which Esc takes back.
        step(4, remember);
        grab("move:x");
        move_to([g] { return Vec2{g->grab.x + 45, g->grab.y}; });
        step(1, [this, g] { g->restUntil = time_ + 1.0; });
        wait_until([this, g] { return time_ > g->restUntil; });
        step(2, [this, g] { gizmoDrag_.wrote = false; });
        move_to([g] { return Vec2{g->grab.x + 70, g->grab.y}; });
        step(2, [this, g, tf] {
            at_check(tf("player").position.x != g->pos.x, "mid-drag the entity has moved");
            at_check(undo_depth() == g->undo + 1, "a drag that rests mid-way is still one undo step");
            inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_ESCAPE);
        });
        step(4, [this, g, tf] {
            inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_ESCAPE);
            at_check(tf("player").position.x == g->pos.x, "Esc while dragging puts the start value back");
            at_check(undo_depth() == g->undo && !gizmoDrag_.active, "...and leaves no undo step, ending the drag");
        });
        release();
        step(2, [this, g, tf] { at_check(tf("player").position.x == g->pos.x, "letting go after Esc changes nothing"); });

        // Playing: the input goes to the game, so no handles. Paused: they edit the running game, with no undo step, lost on Stop.
        step(2, [this, remember] {
            remember();
            play();
        });
        wait_until([this] { return play_ == PlayState::Playing && !at_visible("gizmo:move:x"); });
        step(3, [this] {
            at_check(!at_visible("gizmo:move:x"), "no gizmo while the game plays");
            pause();
        });
        step(6, [this] { at_check(play_ == PlayState::Paused && at_visible("gizmo:move:x"), "paused: the gizmo is back"); });
        drag_by("move:x", 40, 0);
        step(2, [this, g, tf, sc] {
            at_check(std::fabs(tf("player").position.x - (g->pos.x + 40.0f / sc())) < 0.05f, "a drag while paused edits the running game");
            at_check(undo_depth() == g->undo, "...with no undo step (Stop discards it)");
            stop();
        });
        step(6, [this, g, tf] { at_check(tf("player").position.x == g->pos.x, "Stop takes the edit made while paused back"); });

        // Save: the scene file holds what the gizmo wrote.
        step(2, remember);
        drag_by("move:x", 80, 0);
        step(2, [this, tf, project_file] {
            at_check(save_scene_now(), "Save works after gizmo edits");
            auto loaded = load_json_file(project_file(scenePath_));
            const Json* saved = loaded ? find_saved_entity((*loaded)["entities"], "player") : nullptr;
            const Json pos = saved ? (*saved)["components"]["Transform"]["position"] : Json();
            at_check(pos.is_array() && pos.size() >= 1 && std::fabs(pos[0].get<float>() - tf("player").position.x) < 1e-3f,
                     "the scene file holds the position the gizmo set");
            at_check(!dirty_, "...and the scene is clean after saving");
        });
        step(2, [this] {
            // The open scene's path spelled another way ("./scenes/..."): scene.save of the same file still leaves it clean.
            const std::string spelled = scenePath_;
            scenePath_ = "./" + spelled;
            dirty_ = true;
            const CommandResult saved = engine_->commands().call("scene.save", Json::object({{"path", spelled}}));
            at_check(saved.ok && !dirty_, "scene.save of the open file clears the dirty flag whatever the spelling of the scene path");
            scenePath_ = spelled;
        });
        step(2, [this, project_file] {  // back to the fixture the next sections expect
            gizmoMode_ = GizmoMode::Move;
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            select_id("");
        });

        // ---- M2. The same gizmos with a perspective camera (3D) and on a screen-space (HUD) entity.
        auto piv = std::make_shared<Vec2>();
        auto shape_of = [this](GizmoHandle h) -> const GizmoShape* {
            for (const GizmoShape& s : gizmoShapes_)
                if (s.handle == h) return &s;
            return nullptr;
        };
        // A point on a ring where the hit test gives THIS ring (rings of a 3D gizmo cross each other).
        auto ring_point = [this, shape_of](GizmoHandle h) {
            const GizmoShape* s = shape_of(h);
            if (s)
                for (size_t i = 0; i < s->ring.size(); ++i) {
                    const Vec2 v = s->ring[(i + 8) % s->ring.size()];
                    if (gizmo_hit(gizmoShapes_, v, 7.0f) == h) return v;
                }
            at_check(false, "a point of the " + gizmo_handle_name(h) + " ring that only it can be grabbed by");
            return Vec2{-100, -100};
        };
        auto grab_pt = [this, &step, &wait_until, g, piv, shape_of](GizmoHandle h, std::function<Vec2()> where) {
            step(2, [this, g, piv, shape_of, h, where] {
                g->grab = g->cur = where();
                if (const GizmoShape* s = shape_of(h)) *piv = s->centre;
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, g->grab);
            });
            step(2, [this, g] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, g->grab); });
            wait_until([this] { return gizmoDrag_.active; });
        };
        auto over_viewport = [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.25f}); };
        auto start_scene = [this, project_file](const char* json, const char* id, int mode) {
            write_file(project_file(scenePath_), json);
            reload_scene_from_disk();
            select_id(id);
            gizmoMode_ = GizmoMode(mode);
            focus_window("###Viewport");
        };
        // Rotation matrices before and after: `after` is `before` turned about its own local axis `axis` (by some angle).
        auto turned_about_local = [](Vec3 before, Vec3 after, int axis) {
            const Mat4 rel = Mat4::rotate_euler_deg(before).transposed() * Mat4::rotate_euler_deg(after);
            const bool fixed = std::fabs(rel.at(axis, axis) - 1.0f) < 1e-3f;
            const int other = (axis + 1) % 3;
            return fixed && rel.at(other, other) < 0.9998f;
        };
        auto vec3_str = [](Vec3 v) { return "(" + std::to_string(v.x) + ", " + std::to_string(v.y) + ", " + std::to_string(v.z) + ")"; };

        step(2, [start_scene] { start_scene(kGizmo3dScene, "gem", int(GizmoMode::Move)); });
        step(6, over_viewport);
        step(4, [this] { at_check(at_visible("gizmo:move:x") && at_visible("gizmo:move:y"), "3D: the move gizmo shows on the cube"); });
        snap("editor_gizmo_move_3d.png");
        step(2, [this, g, tf] {
            const Transform t = tf("gem");
            g->pos = t.position;
            g->rot = t.rotation;
            g->scl = t.scale;
            g->undo = undo_depth();
        });
        drag_by("move:x", 40, 15);
        step(2, [this, g, tf, vec3_str] {
            const Transform t = tf("gem");
            at_check(t.position.x > g->pos.x + 0.05f && t.position.y == g->pos.y && t.position.z == g->pos.z,
                     "3D: dragging the X arrow grows position.x and leaves y and z alone " + vec3_str(t.position));
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            undo();
        });

        step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_E); });
        step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_E); });
        step(3, [this] { at_check(at_visible("gizmo:rotate:x") && at_visible("gizmo:rotate:y") && at_visible("gizmo:rotate:z"), "3D: the rotate gizmo has three rings"); });
        snap("editor_gizmo_rotate_3d.png");
        for (int axis = 0; axis < 2; ++axis) {  // the local x ring, then the local y ring
            const GizmoHandle h{GizmoKind::RotateAxis, axis};
            step(2, [this, g, tf] {
                const Transform t = tf("gem");
                g->rot = t.rotation;
                g->scl = t.scale;
                g->undo = undo_depth();
            });
            grab_pt(h, [ring_point, h] { return ring_point(h); });
            move_to([g, piv] {  // 40 degrees around the projected pivot
                const float a = 40.0f * kDegToRad, dx = g->grab.x - piv->x, dy = g->grab.y - piv->y;
                return Vec2{piv->x + dx * std::cos(a) - dy * std::sin(a), piv->y + dx * std::sin(a) + dy * std::cos(a)};
            });
            release();
            step(2, [this, g, tf, axis, turned_about_local, vec3_str] {
                const Transform t = tf("gem");
                at_check(turned_about_local(g->rot, t.rotation, axis),
                         std::string("3D: dragging the local ") + (axis == 0 ? "x" : "y") + " ring turns the cube about that local axis, as the euler round trip says " + vec3_str(g->rot) + " -> " + vec3_str(t.rotation));
                at_check(t.scale.x == g->scl.x && undo_depth() == g->undo + 1, "...one undo step, scale untouched");
                undo();
            });
        }

        step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_R); });
        step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_R); });
        step(3, [this] { at_check(at_visible("gizmo:scale:x") && at_visible("gizmo:scale:y"), "3D: the scale gizmo shows"); });
        step(2, [this, g, tf] {
            g->scl = tf("gem").scale;
            g->undo = undo_depth();
        });
        grab_pt(GizmoHandle{GizmoKind::ScaleAxis, 1}, [this] { return at_widget("gizmo:scale:y"); });
        move_to([g, piv] {  // 30 px further out along the handle
            const float dx = g->grab.x - piv->x, dy = g->grab.y - piv->y, l = std::max(1.0f, std::hypot(dx, dy));
            return Vec2{g->grab.x + dx / l * 30.0f, g->grab.y + dy / l * 30.0f};
        });
        release();
        step(2, [this, g, tf, vec3_str] {
            const Transform t = tf("gem");
            at_check(t.scale.y > g->scl.y * 1.1f && t.scale.x == g->scl.x && t.scale.z == g->scl.z,
                     "3D: dragging the local Y scale handle changes scale.y only " + vec3_str(t.scale));
            undo();
        });

        // HUD: a screen-space shape. Its Transform is in design pixels, y down: the gizmo's Y arrow points down the screen.
        step(2, [start_scene] { start_scene(kGizmoHudScene, "hud", int(GizmoMode::Move)); });
        step(6, over_viewport);
        step(4, [this, shape_of] {
            at_check(at_visible("gizmo:move:x") && at_visible("gizmo:move:plane"), "HUD: a screen-space entity gets the move gizmo");
            const GizmoShape* y = shape_of(GizmoHandle{GizmoKind::MoveAxis, 1});
            at_check(y && y->dir.y > 0.9f, "HUD: the Y arrow points down the screen (design y grows downwards)");
        });
        snap("editor_gizmo_hud.png");
        step(2, [this, g, tf] {
            g->pos = tf("hud").position;
            g->undo = undo_depth();
        });
        drag_by("move:plane", 30, 20);
        step(2, [this, g, tf, sc, sc_y] {
            const Transform t = tf("hud");
            at_check(std::fabs(t.position.x - (g->pos.x + 30.0f / sc())) < 0.1f && std::fabs(t.position.y - (g->pos.y + 20.0f / sc_y())) < 0.1f,
                     "HUD: the centre square moves it by the design pixels the mouse covered (right and DOWN are positive)");
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            g->pos = t.position;
            g->undo = undo_depth();
        });
        drag_by("move:y", 12, 30);
        step(2, [this, g, tf, sc_y] {
            const Transform t = tf("hud");
            at_check(std::fabs(t.position.y - (g->pos.y + 30.0f / sc_y())) < 0.1f && t.position.x == g->pos.x,
                     "HUD: the Y arrow moves it down by the design pixels covered, x unchanged");
            undo();
            undo();
        });
    }
}

void Editor::at_section_N(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------------------------------ N. Project panel (View > Project)
    // The acceptance of the file browser: the panel lists the project's files, the type filter and the search narrow the list, a
    // prefab dragged onto the Viewport spawns an entity at the point under the mouse (one undo step, Ctrl+Z removes it), a picture
    // dragged onto a Sprite's texture field sets the field (and a sound dragged there does nothing), Delete goes through fs.delete,
    // and the listing is read from the disk only on a refresh, not per frame.
    {
        struct Browse {
            Vec2 from{}, to{};
            size_t undo = 0, entities = 0;
            int scans = 0;
            Vec3 expected{};
        };
        auto bz = std::make_shared<Browse>();
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        auto right_click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name), 1); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name), 1); });
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        // Drag a tile (or any tracked widget) to a point: the mouse travels with the button held, as ImGui's drag and drop needs.
        auto drag_to = [this, &step, bz](const std::string& from, std::function<Vec2()> target) {
            step(2, [this, from, bz] {
                bz->from = at_widget(from);
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, bz->from);
            });
            step(2, [this, bz] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, bz->from); });
            step(2, [this, bz] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{bz->from.x + 6, bz->from.y + 14}); });
            step(2, [this, bz, target] {
                bz->to = target();
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, bz->to);
            });
            step(3, [this, bz] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, bz->to); });
            step(4, [this, bz] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, bz->to); });
        };
        auto type_text = [this, &step](const std::string& text) {
            step(3, [this, text] {
                for (char c : text) inject_char(unsigned(static_cast<unsigned char>(c)));
            });
        };
        auto ctrl_z = [this, &step] {
            step(2, [this] {
#if defined(__APPLE__)
                atMods_ = SAPP_MODIFIER_SUPER;  // Dear ImGui swaps Cmd and Ctrl on macOS
                inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_LEFT_SUPER);
#else
                atMods_ = SAPP_MODIFIER_CTRL;
                inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_LEFT_CONTROL);
#endif
            });
            step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_Z); });
            step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_Z); });
            step(2, [this] {
#if defined(__APPLE__)
                inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_LEFT_SUPER);
#else
                inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_LEFT_CONTROL);
#endif
                atMods_ = 0;
            });
        };
        // A search that leaves one tile: it is the first, so it is on screen even in a small window.
        auto search_for = [this, &step, &click_widget, &type_text](const std::string& text) {
            step(2, [this] { projBrowser_.query.search.clear(); });
            click_widget("proj:search");
            type_text(text);
            step(4, [] {});
        };
        const std::string tile_prefab = "proj:file:prefabs/autotest_drop.prefab.json";
        const std::string tile_png = "proj:file:assets/autotest_drop.png";

        step(2, [this, project_file, bz] {
            stop();
            select_id("");
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            Image img;
            img.width = img.height = 16;
            img.rgba.assign(16 * 16 * 4, 255);
            for (size_t i = 0; i < img.rgba.size(); i += 4) { img.rgba[i + 1] = 90; img.rgba[i + 2] = 40; }
            at_check(save_png(img, project_file("assets/autotest_drop.png")).ok(), "a picture was written for the Project panel test");
            write_file(project_file("assets/autotest_trash.txt"), "delete me");
            // The prefab comes from the open scene's coin, through the command the AI uses.
            std::string err;
            CommandResult r = edit_command("at:prefab", "prefab.save",
                                           Json::object({{"id", "coin_1"}, {"path", "prefabs/autotest_drop.prefab.json"}, {"overwrite", true}}), &err);
            at_check(r.ok, "prefab.save made a prefab for the Project panel test: " + err);
            r = edit_command("at:sprite", "scene.spawn",
                             Json::object({{"id", "dropsprite"}, {"name", "Drop Sprite"},
                                           {"components", Json::object({{"Transform", Json::object({{"position", Json::array({300, 250, 0})}})},
                                                                        {"Sprite", Json::object()}})}}),
                             &err);
            at_check(r.ok, "an entity with a Sprite was spawned: " + err);
            bz->undo = undo_depth();
            showProject_ = true;
            focus_window("Project");
        });
        wait_until([this] { return at_visible("proj:refresh") && at_visible("proj:file:assets/blip.wav"); });
        step(4, [this, bz] {
            at_check(at_visible("proj:file:assets/blip.wav"), "the Project panel lists a file of the project (assets/blip.wav)");
            at_check(at_visible("proj:folder:") && at_visible("proj:folder:assets"), "...and a folder tree");
            bz->scans = projBrowser_.scans;
            // The scan read the recipes too: the watcher's next poll (every second, so maybe after the 30 frames below on a
            // fast machine) must not walk the disk again for the prefab.save above.
            at_check(!projBrowser_.recipesDirty, "...and leaves the recipe watcher no second walk of the disk to do");
        });
        step(30, [this, bz] { at_check(projBrowser_.scans == bz->scans, "the panel does not read the disk again while nothing changed"); });
        snap("editor_project_panel.png");

        // The type filter.
        click_widget("proj:type");
        step(3, [] {});
        click_widget("proj:type:audio");
        step(5, [this] {
            at_check(at_visible("proj:file:assets/blip.wav"), "the type filter 'audio' keeps the sounds");
            at_check(!at_visible("proj:file:assets/autotest_drop.png") && !at_visible("proj:file:prefabs/autotest_drop.prefab.json"),
                     "...and hides the pictures and prefabs");
        });
        snap("editor_project_filter.png");
        step(2, [this] { projBrowser_.query.type = "all"; });
        // The search.
        search_for("DROP.p");
        step(4, [this] {
            at_check(at_visible("proj:file:assets/autotest_drop.png") && at_visible("proj:file:prefabs/autotest_drop.prefab.json"),
                     "searching 'DROP.p' (case-insensitive) keeps the files whose path contains it (the prefab.save and the picture written "
                     "after the panel was created are listed without Refresh)");
            at_check(!at_visible("proj:file:assets/blip.wav"), "...and hides the others");
        });
        snap("editor_project_search.png");
        click_widget("proj:refresh");
        step(4, [this] { at_check(projBrowser_.scans > 0, "Refresh reads the folder again"); });

        // A prefab dropped on the viewport: scene.spawn at the world point under the mouse.
        search_for("autotest_drop.prefab");
        step(2, [this, bz] {
            bz->entities = world().entity_count();
            bz->undo = undo_depth();
        });
        drag_to(tile_prefab, [this, bz] {
            const Vec2 t{vpImageMin_.x + vpImageSize_.x * 0.78f, vpImageMin_.y + vpImageSize_.y * 0.30f};
            const float tw = float(engine_->renderer()->target_width()), th = float(engine_->renderer()->target_height());
            bz->expected = engine_->renderer()->screen_to_world(Vec2{(t.x - vpImageMin_.x) / vpImageSize_.x * tw, (t.y - vpImageMin_.y) / vpImageSize_.y * th}, 0.0f);
            return t;
        });
        step(5, [this, bz] {
            at_check(world().entity_count() == bz->entities + 1, "dropping a prefab on the Viewport adds one entity");
            at_check(undo_depth() == bz->undo + 1, "...as one undo step");
            Entity e = selected();
            at_check(!e.is_null() && world().id_of(e) != "coin_1", "...and the new entity is the selection");
            const Vec3 p = e.is_null() ? Vec3{9999, 9999, 9999} : world().world_position(e);
            // A world unit can be less than a pixel in a small window: allow two panel pixels of difference.
            const float tol = 2.0f * float(engine_->renderer()->target_width()) / std::max(1.0f, vpImageSize_.x);
            at_check(std::fabs(p.x - bz->expected.x) < tol && std::fabs(p.y - bz->expected.y) < tol && std::fabs(p.z) < 0.01f,
                     "...at the world point under the mouse on the z = 0 plane (" + std::to_string(p.x) + ", " + std::to_string(p.y) +
                         " expected " + std::to_string(bz->expected.x) + ", " + std::to_string(bz->expected.y) + ")");
        });
        snap("editor_project_drop_prefab.png");
        step(2, [this] { focus_window("###Viewport"); });
        step(4, [] {});
        ctrl_z();
        step(5, [this, bz] {
            at_check(world().entity_count() == bz->entities, "Ctrl+Z removes the spawned entity");
            at_check(undo_depth() == bz->undo, "...and takes the undo step back");
        });

        // A file that is not a prefab dropped on the viewport does nothing.
        search_for("autotest_drop.png");
        drag_to(tile_png, [this] { return Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.5f}; });
        step(5, [this, bz] {
            at_check(world().entity_count() == bz->entities && undo_depth() == bz->undo, "a picture dropped on the Viewport does nothing");
        });

        // A picture dropped on a Sprite's texture field.
        step(2, [this, bz] {
            focus_window("Project");
            select_id("dropsprite");
            inspScrollTo_ = "Sprite.texture";
            bz->undo = undo_depth();
        });
        wait_until([this] { return at_shown("insp:Sprite.texture") && at_visible(std::string("proj:file:assets/autotest_drop.png")); });
        drag_to(tile_png, [this] { return at_widget("insp:Sprite.texture"); });
        step(5, [this, bz] {
            const Sprite* sp = world().get<Sprite>(world().find_by_id("dropsprite"));
            at_check(sp && sp->texture == "assets/autotest_drop.png", "a picture dropped on the Sprite's texture field sets it");
            at_check(undo_depth() == bz->undo + 1, "...as one undo step");
        });
        snap("editor_project_drop_texture.png");
        search_for("blip.wav");
        step(2, [this, bz] { bz->undo = undo_depth(); });
        wait_until([this] { return at_shown("insp:Sprite.texture") && at_visible(std::string("proj:file:assets/blip.wav")); });
        drag_to("proj:file:assets/blip.wav", [this] { return at_widget("insp:Sprite.texture"); });
        step(5, [this, bz] {
            const Sprite* sp = world().get<Sprite>(world().find_by_id("dropsprite"));
            at_check(sp && sp->texture == "assets/autotest_drop.png" && undo_depth() == bz->undo,
                     "a sound dropped on a texture field is refused (the field keeps its value)");
        });

        // Delete: the right-click menu, a confirmation, fs.delete; the listing follows without Refresh.
        search_for("autotest_trash");
        wait_until([this] { return at_visible("proj:file:assets/autotest_trash.txt"); });
        right_click_widget("proj:file:assets/autotest_trash.txt");
        step(3, [this] {
            at_check(at_visible("proj:ctx:reveal") && at_visible("proj:ctx:copy") && at_visible("proj:ctx:delete"),
                     "right-clicking a file offers Show in the file manager, Copy path and Delete");
        });
        snap("editor_project_menu.png");
        click_widget("proj:ctx:copy");
        step(4, [this] { at_check(std::string(ImGui::GetClipboardText() ? ImGui::GetClipboardText() : "") == "assets/autotest_trash.txt", "Copy path puts the project-relative path on the clipboard"); });
        right_click_widget("proj:file:assets/autotest_trash.txt");
        step(3, [] {});
        click_widget("proj:ctx:delete");
        step(4, [this] { at_check(at_visible("proj:delete-confirm") && stdfs::exists(projectDir_ + "/assets/autotest_trash.txt"), "Delete asks first; the file is still there"); });
        snap("editor_project_delete.png");
        click_widget("proj:delete-confirm");
        wait_until([this] { return !at_visible("proj:file:assets/autotest_trash.txt") && !at_visible("proj:delete-confirm"); });
        step(4, [this] {
            at_check(!stdfs::exists(projectDir_ + "/assets/autotest_trash.txt"), "confirming removes the file from disk (fs.delete)");
            at_check(!at_visible("proj:file:assets/autotest_trash.txt"), "...and the panel stops listing it without a Refresh");
        });

    }
}

}  // namespace fa::editor
