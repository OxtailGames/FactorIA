// Autotest sections N3, P3 and O3: the Model panel, the Particles panel and the 3D clips of the Animation panel.
// Split from autotest_tools.cpp: each section is an Editor::at_section_<id>(AtScript&) that adds its steps to the script,
// called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <memory>

#include "ai_project_edit.h"
#include "auto_play_job.h"
#include "autotest_common.h"
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

}  // namespace

void Editor::at_section_N3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Model panel (docs/EDITOR.md, "Model panel"): a model document opens as its operation tree with a live view of the mesh; picking a node
    // highlights its part; a slider is clicked (ONE model.edit, one undo step) and Undo/Redo walk it through the editor's stack; a node is added,
    // switched off and removed; the view is orbited with the mouse; the 1.8 m figure and Check show their results; Save bakes the .glb. Every wait
    // counts frames or state.
    {
        struct Ns {
            size_t undo = 0;
            double height = 0;
            size_t rows = 0;
            std::uint64_t renders = 0;
            float yaw = 0;
        };
        auto ns = std::make_shared<Ns>();
        const std::string dir = "assets/at-model";
        const std::string doc = dir + "/t.model.json";
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        // The document is open, evaluated, and the viewport drew that mesh.
        auto settled = [this] {
            const ModelerModel* m = modeler_.model.get();
            return m && m->is_open() && m->valid() && !m->busy() && m->build_is_fresh() && modeler_.picture.view != 0 && !m->has_live();
        };
        auto height_of = [this]() -> double {
            const ModelerBuildPtr b = modeler_.model ? modeler_.model->build() : nullptr;
            return b ? double(b->stats.bmax.y - b->stats.bmin.y) : 0.0;
        };
        step(2, [this, doc] {
            std::error_code ec;
            stdfs::remove_all(projectDir_ + "/assets/at-model", ec);   // a leftover of an earlier run
            const Json args = Json::parse(R"({"bake":false,"nodes":[
                {"op":"box","id":"base","size":[1,0.2,1],"part":"base","align":"bottom"},
                {"op":"group","id":"top","part":"top","position":[0,0.2,0],"children":[
                    {"op":"cylinder","id":"post","radius":0.2,"height":1,"align":"bottom"},
                    {"op":"sphere","id":"ball","radius":0.3,"position":[0,1.3,0]}]}]})");
            Json a = args;
            a["path"] = doc;
            const CommandResult r = engine_->commands().call("model.create", a);
            after_command("model.create", a, r);
            at_check(r.ok, "model.create worked: " + (r.ok ? std::string() : command_error_text(r.error)));
            open_model_document(doc);
        });
        wait_until([this, settled] { return at_visible("mod:view") && at_visible("mod:save") && at_visible("mod:node:3") && settled(); });
        step(3, [this, ns, height_of] {
            ModelerModel& m = *modeler_.model;
            at_check(m.valid() && m.rows().size() == 4, "the panel opened the document with its four nodes in the tree");
            at_check(m.build() && m.build()->stats.triangles > 0, "...evaluated it to a mesh");
            at_check(modeler_.renderCount > 0 && modeler_.picture.w > 0, "...and the viewport drew it");
            at_check(at_visible("mod:check") && at_visible("mod:figure") && at_visible("mod:part:base") && at_visible("mod:part:top"), "...with Check, the figure toggle and its two parts listed");
            ns->undo = undo_depth();
            ns->height = height_of();
            ns->renders = modeler_.renderCount;
        });
        snap("editor_model_panel.png");

        // ---- a node picked: its part is highlighted and its parameters are listed
        click_widget("mod:node:2");
        wait_until([this, settled] { return modeler_.selected == "/nodes/1/children/0" && at_visible("mod:param:height") && settled(); });
        step(3, [this, ns] {
            at_check(modeler_.highlight == "top", "picking the post highlighted its part, `top`");
            at_check(modeler_.renderCount > ns->renders, "...and the view was drawn again with it");
            at_check(at_visible("mod:param:radius") && at_visible("mod:param:segments") && at_visible("mod:param:capTop") && at_visible("mod:param:position"),
                     "...and the cylinder's parameters are listed, with the fields every node has");
        });
        snap("editor_model_part.png");

        // ---- a slider clicked: one model.edit, one undo step
        click_widget("mod:param:height");
        wait_until(settled);
        step(3, [this, ns, height_of] {
            const Json* n = modeler_.model->node("/nodes/1/children/0");
            at_check(n && n->contains("height") && (*n)["height"].get<double>() > 2.0, "a click on the height slider wrote its value to the document");
            at_check(height_of() > ns->height + 1.0, "...and the model in the view is taller");
            at_check(undo_depth() == ns->undo + 1, "...as one undo step");
        });
        step(2, [this] { undo(); });
        wait_until(settled);
        step(3, [this, ns, height_of] {
            at_check(std::fabs(height_of() - ns->height) < 1e-4 && undo_depth() == ns->undo, "Undo brought the height back");
        });
        step(2, [this] { redo(); });
        wait_until(settled);
        step(3, [this, ns, height_of] { at_check(height_of() > ns->height + 1.0 && undo_depth() == ns->undo + 1, "Redo made it taller again"); });
        step(2, [this] { undo(); });
        wait_until(settled);

        // ---- a part picked in the list
        click_widget("mod:part:base");
        step(3, [this] { at_check(modeler_.highlight == "base", "a click on `base` in the part list highlights it"); });

        // ---- a node added, switched off, removed
        step(2, [this, ns] {
            ns->undo = undo_depth();
            ns->rows = modeler_.model->rows().size();
            modeler_.newOp = "torus";
        });
        click_widget("mod:add");
        wait_until([this, settled] { return modeler_.model->rows().size() == 5 && settled(); });
        step(3, [this, ns] {
            at_check(undo_depth() == ns->undo + 1, "Add put a torus in the tree as one undo step");
            at_check(modeler_.model->rows()[4].op == "torus" && modeler_.selected == "/nodes/2", "...and picked it");
        });
        click_widget("mod:enabled:4");
        wait_until([this, settled] { return !modeler_.model->rows().empty() && !modeler_.model->rows()[4].enabled && settled(); });
        step(3, [this, ns] { at_check(undo_depth() == ns->undo + 2, "the node's check box switched it off as one undo step"); });
        click_widget("mod:remove");
        wait_until([this, settled] { return modeler_.model->rows().size() == 4 && settled(); });
        step(3, [this, ns] { at_check(undo_depth() == ns->undo + 3 && modeler_.selected.empty(), "Remove took it out as one undo step"); });
        step(2, [this] { undo(); });
        step(2, [this] { undo(); });
        step(2, [this] { undo(); });
        wait_until([this, settled] { return modeler_.model->rows().size() == 4 && settled(); });
        step(3, [this, ns] {
            at_check(undo_depth() == ns->undo && modeler_.model->rows().size() == ns->rows, "three Undos took the torus out again");
            std::ifstream in(projectDir_ + "/assets/at-model/t.model.json");
            std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
            at_check(text.find("torus") == std::string::npos, "...and out of the document on disk");
        });

        // ---- the view: orbit with the mouse, the 1.8 m figure, Check
        step(2, [this, ns] {
            ns->yaw = modeler_.yaw;
            ns->renders = modeler_.renderCount;
        });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, modeler_screen_pos(0.5f, 0.5f)); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, modeler_screen_pos(0.5f, 0.5f)); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, modeler_screen_pos(0.6f, 0.5f)); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, modeler_screen_pos(0.7f, 0.45f)); });
        step(3, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, modeler_screen_pos(0.7f, 0.45f)); });
        wait_until(settled);
        step(3, [this, ns] {
            at_check(std::fabs(modeler_.yaw - ns->yaw) > 5.0f, "dragging in the view orbited the model");
            at_check(modeler_.renderCount > ns->renders, "...and the view was drawn again");
        });
        click_widget("mod:figure");
        wait_until([this, settled] { return modeler_.figure && settled(); });
        step(3, [this] { at_check(modeler_.figure, "the figure toggle stands a 1.8 m figure beside the model"); });
        snap("editor_model_figure.png");
        click_widget("mod:check");
        wait_until([this] { return at_visible("mod:finding:0") || (modeler_.check.is_object() && modeler_.check["findings"].empty()); });
        step(3, [this] {
            at_check(modeler_.check.is_object() && modeler_.check.contains("mesh") && modeler_.check["mesh"]["triangles"].get<int>() > 0, "Check ran model.check on the document");
            at_check(modeler_.checkError.empty(), "...with no error");
        });

        // ---- Save bakes the .glb
        click_widget("mod:save");
        step(10, [this] {
            const std::string out = modeler_.model->baked_path();
            at_check(!out.empty() && stdfs::exists(projectDir_ + "/" + out), "Save baked the model: " + out);
        });
        step(2, [this, dir] {
            FA_INFO("autotest", "model panel: last evaluation {:.1f} ms, last picture {:.1f} ms", modeler_.model->last_eval_ms(), modeler_.renderMs);
            showModeler_ = false;
            modeler_close_document();
            std::error_code ec;
            stdfs::remove_all(projectDir_ + "/" + dir, ec);
            project_files_changed();
        });
    }
}

void Editor::at_section_P3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Particles panel (docs/EDITOR.md, "Particles panel"): New writes a starter effect and opens it, the preview plays it, the time scrubber
    // is dragged (the same moment shows the same particles every time), a gradient key and a curve key are dragged (ONE vfx.edit and one undo step
    // each), a part is added and removed, and Undo/Redo walk every step through the editor's stack back to the file as it was. Every wait counts
    // frames or state.
    {
        struct Ps {
            size_t undo = 0;
            std::string original, afterGradient;
            double len = 0, t1 = 0;
            int count = 0;
            float x0 = 0, y0 = 0;
            Vec2 start{};
        };
        auto ps = std::make_shared<Ps>();
        const std::string rel = "assets/vfx/effect.vfx.json";
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        // Press at the widget's centre plus `from`, move in three steps by `by` and let go.
        auto drag = [this, &step, ps](const std::string& name, Vec2 from, Vec2 by) {
            step(2, [this, name, from, ps] {
                const Vec2 c = at_widget(name);
                ps->start = Vec2{c.x + from.x, c.y + from.y};
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, ps->start);
            });
            step(2, [this, ps] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, ps->start); });
            for (int i = 1; i <= 3; ++i)
                step(2, [this, ps, by, i] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{ps->start.x + by.x * float(i) / 3.0f, ps->start.y + by.y * float(i) / 3.0f}); });
            step(4, [this, ps, by] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, Vec2{ps->start.x + by.x, ps->start.y + by.y}); });
        };
        auto read_text = [this](const std::string& r) {
            std::ifstream in(projectDir_ + "/" + r, std::ios::binary);
            return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        };
        auto file_json = [read_text, rel]() {
            Json j = Json::parse(read_text(rel), nullptr, false);
            return j.is_discarded() ? Json::object() : j;
        };
        auto emitter_of = [file_json]() {
            const Json j = file_json();
            return j.contains("parts") && j["parts"].is_array() && !j["parts"].empty() && j["parts"][0].contains("emitter") ? j["parts"][0]["emitter"] : Json::object();
        };
        auto parts_in_file = [file_json]() { const Json j = file_json(); return j.contains("parts") && j["parts"].is_array() ? j["parts"].size() : size_t(0); };
        auto ready = [this] {
            return particle_.model && particle_.model->is_open() && particle_.model->valid() && particle_.model->doc() && particle_.preview &&
                   at_visible("pt:timeline") && at_visible("pt:canvas") && at_visible("pt:part:0") && particle_.canvasW > 100 && particle_.tlW > 100;
        };
        step(2, [this, ps, rel] {
            std::error_code ec;
            stdfs::remove(projectDir_ + "/" + rel, ec);   // a leftover of an earlier run
            project_files_changed();
            ps->undo = undo_depth();
            showParticle_ = true;
            focus_window("Particles");
        });
        wait_until([this] { return at_visible("pt:new") && at_visible("pt:open"); });
        step(3, [this] { at_check(!particle_.model || !particle_.model->is_open(), "the Particles panel opens with no effect, offering New and the list of files"); });
        click_widget("pt:new");
        wait_until(ready);
        step(3, [this, ps, rel, read_text] {
            ps->original = read_text(rel);
            at_check(!ps->original.empty(), "New wrote " + rel);
            at_check(particle_.model->path() == rel && particle_.model->parts().size() == 1, "...and opened it with its one emitter part");
            at_check(undo_depth() == ps->undo, "...which is not an undo step (a new file)");
            at_check(particle_.preview->timeline_length() >= 0.25, "the timeline covers the burst and its particles' lives");
            at_check(at_visible("pt:play") && at_visible("pt:restart") && at_visible("pt:add_emitter") && at_visible("pt:add_light") && at_visible("pt:add_sound") &&
                         at_visible("pt:add_command"),
                     "the toolbar and the add buttons are on screen");
        });
        wait_until([this] { return particle_.preview->live_particles() > 0; });
        step(3, [this] { at_check(particle_.preview->live_particles() > 0 && particle_.playing, "the preview plays the burst: particles are alive"); });
        snap("editor_particle_panel.png");

        // ---- the time scrubber: Pause, drag the playhead, the same moment shows the same particles
        click_widget("pt:play");
        step(3, [this, ps] {
            at_check(!particle_.playing, "Pause stopped the preview");
            ps->len = particle_.preview->timeline_length();
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, particle_time_pos(ps->len * 0.25, 0.12));
        });
        step(2, [this, ps] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, particle_time_pos(ps->len * 0.25, 0.12)); });
        step(2, [] {});   // the frames in which the panel sees the mouse and seeks
        wait_until([this] { return particle_.preview && !particle_.preview->catching_up(); });   // the preview rebuilds a share of its steps per frame
        step(3, [this, ps] {
            const ParticlePreview& pv = *particle_.preview;
            at_check(particle_.scrubbing && !particle_.playing, "pressing on the timeline picks up the playhead");
            at_check(std::fabs(pv.time() - ps->len * 0.25) < 0.04, "...and puts it at the mouse: " + std::to_string(pv.time()) + " s of " + std::to_string(ps->len));
            ps->t1 = pv.time();
            ps->count = pv.live_particles();
            ps->x0 = pv.dots().empty() ? 0.0f : pv.dots()[0].x;
            ps->y0 = pv.dots().empty() ? 0.0f : pv.dots()[0].y;
            at_check(ps->count > 0, "...where the burst is still alive");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, particle_time_pos(ps->len * 0.95, 0.12));
        });
        step(2, [] {});
        wait_until([this] { return !particle_.preview->catching_up(); });
        step(3, [this, ps] {
            at_check(particle_.preview->time() > ps->len * 0.85, "dragging to the right end moved the playhead there");
            at_check(particle_.preview->live_particles() == 0, "...where every particle is gone");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, particle_time_pos(ps->len * 0.25, 0.12));
        });
        step(2, [] {});
        wait_until([this] { return !particle_.preview->catching_up(); });
        step(3, [this, ps] {
            const ParticlePreview& pv = *particle_.preview;
            at_check(pv.time() == ps->t1, "dragging back to the same pixel gave the same time");
            at_check(pv.live_particles() == ps->count && !pv.dots().empty() && std::fabs(pv.dots()[0].x - ps->x0) < 1e-4f && std::fabs(pv.dots()[0].y - ps->y0) < 1e-4f,
                     "...and the same particles in the same places (a seeded, repeatable preview)");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, particle_time_pos(ps->len * 0.25, 0.12));
        });
        step(3, [this] { at_check(!particle_.scrubbing, "letting go dropped the playhead"); });
        snap("editor_particle_scrub.png");

        // ---- a gradient key dragged: one vfx.edit, one undo step
        step(2, [this, ps] { ps->undo = undo_depth(); });
        drag("pt:grad:colorGradient", Vec2{0, 0}, Vec2{40, 0});
        step(3, [this, ps, emitter_of] {
            const Json g = emitter_of().contains("colorGradient") ? emitter_of()["colorGradient"] : Json::array();
            at_check(g.is_array() && g.size() == 3, "a click on the gradient bar added a key, and the document on disk has three");
            at_check(g.is_array() && g.size() == 3 && g[1][0].get<double>() > 0.55, "...which the drag moved to the right: " + g.dump());
            at_check(undo_depth() == ps->undo + 1, "...as ONE undo step");
            ps->afterGradient = emitter_of().dump();
        });

        // ---- curve keys: one added by dragging out of a click, a second one by a click
        drag("pt:curve:sizeCurve", Vec2{0, 0}, Vec2{50, -12});
        step(3, [this, ps, emitter_of] {
            const Json c = emitter_of().contains("sizeCurve") ? emitter_of()["sizeCurve"] : Json::array();
            at_check(c.is_array() && c.size() == 1, "a click on the size curve added one key to the document");
            at_check(c.is_array() && !c.empty() && c[0].is_array() && c[0][0].get<double>() > 0.55, "...which the drag moved to the right: " + c.dump());
            at_check(undo_depth() == ps->undo + 2, "...as ONE more undo step");
        });
        drag("pt:curve:sizeCurve", Vec2{-80, 0}, Vec2{0, 0});
        step(3, [this, ps, emitter_of] {
            const Json c = emitter_of().contains("sizeCurve") ? emitter_of()["sizeCurve"] : Json::array();
            at_check(c.is_array() && c.size() == 2 && c[0][0].get<double>() < c[1][0].get<double>(), "a second click added a second key, in order");
            at_check(undo_depth() == ps->undo + 3, "...as one undo step");
        });

        // ---- a part added and removed
        click_widget("pt:add_light");
        wait_until([this] { return particle_.model->parts().size() == 2 && at_visible("pt:part:1"); });
        step(3, [this, ps, parts_in_file] {
            at_check(parts_in_file() == 2 && particle_.model->parts()[1].type == "light", "+ Light wrote a light part to the document");
            at_check(undo_depth() == ps->undo + 4 && particle_.selectedPart == 1, "...as one undo step, and selected it");
            at_check(at_visible("pt:add_light_settings") || at_visible("insp:pt:/parts/1/at"), "...with its fields in the inspector");
        });
        click_widget("pt:part_remove");
        wait_until([this] { return particle_.model->parts().size() == 1; });
        step(3, [this, ps, parts_in_file] {
            at_check(parts_in_file() == 1 && undo_depth() == ps->undo + 5, "Remove took the part out of the document as one undo step");
        });

        // ---- Undo and Redo through the editor's stack
        for (int i = 0; i < 5; ++i) step(3, [this] { undo(); });
        step(3, [this, ps, rel, read_text, emitter_of] {
            at_check(undo_depth() == ps->undo, "five Undos used up the panel's steps");
            at_check(read_text(rel) == ps->original, "...and the document is byte for byte what New wrote");
            at_check(emitter_of().contains("colorGradient") && emitter_of()["colorGradient"].size() == 2 && !emitter_of().contains("sizeCurve"), "...with the two gradient keys and no size curve");
        });
        for (int i = 0; i < 4; ++i) step(3, [this] { redo(); });
        step(3, [this, ps, emitter_of] {
            at_check(undo_depth() == ps->undo + 4, "four Redos put the steps back");
            at_check(emitter_of().dump() != ps->afterGradient && emitter_of().contains("sizeCurve") && emitter_of()["sizeCurve"].size() == 2, "...with both curve keys");
        });
        for (int i = 0; i < 4; ++i) step(3, [this] { undo(); });
        step(3, [this, ps, rel, read_text] { at_check(read_text(rel) == ps->original, "four more Undos: the file is as New wrote it again"); });

        // ---- the file is changed by another program: Redo refuses to overwrite it, keeps the step, and Reload takes the file as it is
        step(2, [this, ps, rel, read_text] {
            ps->count = int(redo_.size());
            write_file(projectDir_ + "/" + rel, read_text(rel) + "\n");
            redo();   // in the same frame: a later one could find the panel's poll has already taken the change (and the step with it)
        });
        step(3, [this, ps, rel, read_text] {
            at_check(particle_.model->conflict(), "Redo of a file that was changed outside the editor was refused");
            at_check(read_text(rel) == ps->original + "\n", "...the other program's change is still in the file");
            at_check(int(redo_.size()) == ps->count, "...and the step stays on the Redo stack");
        });
        // The panel polls the file every 20 frames: it must not take the change by itself while the warning is up (Reload decides).
        step(45, [] {});
        step(2, [this, ps] {
            at_check(particle_.model->conflict(), "...and the warning is still there after the panel polled the file");
            at_check(int(redo_.size()) == ps->count, "...with the step on the Redo stack");
            particle_reload();
            at_check(!particle_.model->conflict(), "Reload took the file as it is and cleared the warning");
            at_check(int(redo_.size()) == ps->count - 1, "...and dropped the step that cannot be applied any more, so Undo and Redo are not stuck");
        });

        step(2, [this, rel] {
            showParticle_ = false;
            particle_close_document();
            std::error_code ec;
            stdfs::remove(projectDir_ + "/" + rel, ec);
            project_files_changed();
        });
    }
}

void Editor::at_section_O3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Animation panel's 3D mode (docs/EDITOR.md, "Animation panel, 3D clips"): a generated walk opens on the rigged model, a bone is picked in the list and
    // in the view, the rotation gizmo is dragged (ONE key, one undo step) and an IK handle too, a key is moved and deleted in the dopesheet, Mirror pose keys
    // the other side, the filmstrip and the weights come back as pictures, a clip is generated from the panel and Undo/Redo walk every step through the
    // editor's stack. Every wait counts frames or state.
    {
        struct Os {
            size_t undo = 0;
            std::string original, afterGizmo, afterMirror;
            Vec3 head{};
            std::uint64_t renders = 0;
            Vec2 start{};
            double playhead = 0;
        };
        auto os = std::make_shared<Os>();
        const std::string dir = "assets/at-anim3d";
        const std::string rigGlb = dir + "/hero.rig.glb";
        const std::string clipRel = "anim/at-hero_walk.anim.json";
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        // Press on a widget, move in four steps by `to(start, i)` (i = 1..4) and let go.
        auto drag = [this, &step, os](const std::string& name, std::function<Vec2(Vec2, int)> to) {
            step(2, [this, name, os] {
                os->start = at_widget(name);
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, os->start);
            });
            step(2, [this, os] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, os->start); });
            for (int i = 1; i <= 4; ++i) step(2, [this, os, to, i] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, to(os->start, i)); });
            step(4, [this, os, to] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, to(os->start, 4)); });
        };
        auto clip_text = [this, clipRel] { return read_file(projectDir_ + "/" + clipRel); };
        auto settled = [this] {
            const Anim3DModel* m = anim3d_.model.get();
            return m && m->is_open() && m->has_rig() && anim3d_.picture.view != 0 && !anim3d_.live && anim3d_.drag == Anim3DUi::Drag::None;
        };
        auto bone_head_now = [this](const std::string& bone) {
            const Anim3DModel& m = *anim3d_.model;
            return bone_head(*m.rig(), m.pose_at(anim3d_.playhead), m.node_of(bone));
        };
        step(2, [this, dir, clipRel, rigGlb] {
            std::error_code ec;
            stdfs::remove_all(projectDir_ + "/" + dir, ec);   // a leftover of an earlier run
            stdfs::remove_all(projectDir_ + "/anim", ec);
            stdfs::create_directories(projectDir_ + "/" + dir, ec);
            write_file(projectDir_ + "/" + dir + "/hero.model.json", R"({"format":"factoria.model/1","nodes":[
                {"op":"box","size":[0.36,0.2,0.2],"position":[0,0.95,0],"part":"pelvis"},
                {"op":"box","size":[0.4,0.5,0.22],"position":[0,1.3,0],"part":"torso"},
                {"op":"box","size":[0.1,0.1,0.1],"position":[0,1.6,0],"part":"neck"},
                {"op":"box","size":[0.22,0.25,0.22],"position":[0,1.77,0.02],"part":"head"},
                {"op":"box","size":[0.7,0.1,0.1],"position":[0.55,1.5,0],"part":"arm_l"},
                {"op":"box","size":[0.7,0.1,0.1],"position":[-0.55,1.5,0],"part":"arm_r"},
                {"op":"box","size":[0.14,0.9,0.14],"position":[0.11,0.45,0],"part":"leg_l"},
                {"op":"box","size":[0.14,0.9,0.14],"position":[-0.11,0.45,0],"part":"leg_r"}]})");
            const Json rigArgs = Json::object({{"path", dir + "/hero.rig.json"}, {"model", dir + "/hero.model.json"}, {"template", "humanoid"}});
            const CommandResult rr = engine_->commands().call("rig.create", rigArgs);
            after_command("rig.create", rigArgs, rr);
            at_check(rr.ok, "rig.create worked: " + (rr.ok ? std::string() : command_error_text(rr.error)));
            const Json genArgs = Json::object({{"rig", rigGlb}, {"kind", "walk"}, {"out", clipRel}});
            const CommandResult gr = engine_->commands().call("anim3d.generate", genArgs);
            after_command("anim3d.generate", genArgs, gr);
            at_check(gr.ok, "anim3d.generate worked: " + (gr.ok ? std::string() : command_error_text(gr.error)));
            at_check(anim3d_file_is_3d(projectDir_, clipRel), "the Project panel's test tells the generated file is a 3D clip");
            open_anim3d_clip(clipRel, rigGlb);
        });
        wait_until([this, settled] { return settled() && at_shown("a3:view") && at_shown("a3:bone:spine_1") && at_visible("a3:key:arm_upper_l:0:0") && at_visible("a3:ruler"); });
        step(3, [this, os, clipRel, clip_text] {
            const Anim3DModel& m = *anim3d_.model;
            at_check(m.path() == clipRel && m.has_rig() && m.clip() && !m.clip()->tracks.empty(), "the panel opened the generated walk on its rig");
            at_check(anim3d_.renderCount > 0 && anim3d_.picture.w > 100, "...the viewport drew the posed model");
            at_check(anim3d_.bonesDrawn > 8 && anim3d_.keysDrawn > 8, "...with the bones over it and the keys in the dopesheet");
            at_check(at_visible("a3:filmstrip") && at_visible("a3:mirror") && at_visible("a3:tool:ik") && at_visible("a3:play"), "...and the toolbar and the tools are there");
            at_check(m.rows().size() > 10, "...the bone list holds the rig's bones");
            os->undo = undo_depth();
            os->original = clip_text();
            os->renders = anim3d_.renderCount;
        });
        snap("editor_anim3d_panel.png");

        // ---- a bone picked in the list, then in the view
        click("a3:bone:spine_1");
        step(3, [this] {
            at_check(anim3d_.bone == "spine_1", "a click on a bone in the list picked it");
            at_check(anim3d_.handlesDrawn >= 3, "...and the rotation gizmo (three rings) is drawn on it");
        });
        wait_until([this] { return at_visible("a3:joint:arm_upper_l"); });
        click("a3:joint:arm_upper_l");
        step(3, [this] { at_check(anim3d_.bone == "arm_upper_l", "a click on a bone's joint in the view picked it"); });
        wait_until([this] { return at_visible("a3:ring:x") && at_visible("a3:ring:y") && at_visible("a3:ring:z"); });

        // ---- the rotation gizmo: a drag round the joint is ONE key and one undo step
        step(2, [this, os, bone_head_now] {
            os->head = bone_head_now("hand_l");
            os->undo = undo_depth();
            os->renders = anim3d_.renderCount;
        });
        drag("a3:ring:z", [this](Vec2 start, int i) {
            const Vec2 c = at_widget("a3:joint:arm_upper_l");
            const double a = 0.17 * i;   // about 40 degrees round the joint on the screen
            const double dx = double(start.x - c.x), dy = double(start.y - c.y);
            return Vec2{float(c.x + dx * std::cos(a) - dy * std::sin(a)), float(c.y + dx * std::sin(a) + dy * std::cos(a))};
        });
        wait_until(settled);
        step(3, [this, os, clip_text, bone_head_now] {
            const Anim3DModel& m = *anim3d_.model;
            at_check(undo_depth() == os->undo + 1, "the gizmo drag is one undo step");
            at_check(m.key_at(Key3D{"arm_upper_l", 0, 0}) != nullptr, "...it keyed the picked bone at the playhead");
            at_check(clip_text() != os->original, "...the clip file on disk changed");
            at_check(length(bone_head_now("hand_l") - os->head) > 0.02f, "...and the hand moved with the arm");
            at_check(anim3d_.renderCount > os->renders, "...and the view was drawn again");
            os->afterGizmo = clip_text();
        });
        snap("editor_anim3d_gizmo.png");

        // ---- Mirror pose copies the left side onto the right as one more step
        step(2, [this] { anim3d_.mirrorFrom = 1; });
        click("a3:mirror");
        wait_until([this, os] { return undo_depth() == os->undo + 2; });
        step(3, [this, os, clip_text] {
            at_check(clip_text() != os->afterGizmo, "Mirror pose keyed the right side as one more undo step");
            os->afterMirror = clip_text();
        });
        step(2, [this] { undo(); });
        wait_until(settled);
        step(3, [this, os, clip_text] { at_check(clip_text() == os->afterGizmo && undo_depth() == os->undo + 1, "Undo took the mirror back"); });
        step(2, [this] { undo(); });
        wait_until(settled);
        step(3, [this, os, clip_text] {
            at_check(clip_text() == os->original && undo_depth() == os->undo, "Undo again took the gizmo's key back: the file is the generated one");
            at_check(anim3d_.model->revision() > 0, "...and the panel read it again");
        });
        step(2, [this] { redo(); });
        step(2, [this] { redo(); });
        wait_until(settled);
        step(3, [this, os, clip_text] {
            at_check(clip_text() == os->afterMirror && undo_depth() == os->undo + 2, "two Redos brought both steps back");
        });
        step(2, [this] { undo(); });
        wait_until(settled);

        // ---- the dopesheet: a key moved, undone, deleted
        click("a3:onlybone");
        wait_until([this] { return at_shown("a3:key:arm_upper_l:0:0"); });
        step(2, [this, os] { os->undo = undo_depth(); });
        drag("a3:key:arm_upper_l:0:0", [](Vec2 start, int i) { return Vec2{start.x + 14.0f * float(i), start.y}; });
        wait_until(settled);
        step(3, [this, os] {
            const Anim3DModel& m = *anim3d_.model;
            at_check(undo_depth() == os->undo + 1, "dragging a key in the dopesheet is one undo step");
            at_check(m.key_at(Key3D{"arm_upper_l", 0, 0}) == nullptr, "...the key left its time");
            at_check(!anim3d_.selection.empty() && anim3d_.selection.begin()->ms > 0, "...and the selection followed it");
        });
        step(2, [this] { undo(); });
        wait_until([this, settled] { return settled() && at_shown("a3:key:arm_upper_l:0:0"); });
        step(3, [this, os] { at_check(anim3d_.model->key_at(Key3D{"arm_upper_l", 0, 0}) != nullptr && undo_depth() == os->undo, "Undo put the key back"); });
        click("a3:key:arm_upper_l:0:0");
        wait_until([this] { return anim3d_.selection.size() == 1 && at_enabled("a3:delete"); });
        click("a3:delete");
        wait_until([this, os, settled] { return settled() && undo_depth() == os->undo + 1; });
        step(3, [this] { at_check(anim3d_.model->key_at(Key3D{"arm_upper_l", 0, 0}) == nullptr && anim3d_.selection.empty(), "Delete keys removed the picked key"); });
        step(2, [this] { undo(); });
        wait_until([this, settled] { return settled() && anim3d_.model->key_at(Key3D{"arm_upper_l", 0, 0}) != nullptr; });
        click("a3:onlybone");

        // ---- the IK handle: a foot dragged up is one undo step
        wait_until([this] { return at_shown("a3:joint:foot_l"); });
        click("a3:joint:foot_l");
        click("a3:tool:ik");
        wait_until([this] { return anim3d_.bone == "foot_l" && at_visible("a3:ik:target") && at_visible("a3:ik:pole"); });
        step(2, [this, os, bone_head_now] {
            os->head = bone_head_now("foot_l");
            os->undo = undo_depth();
        });
        drag("a3:ik:target", [](Vec2 start, int i) { return Vec2{start.x, start.y - 7.0f * float(i)}; });
        wait_until(settled);
        step(3, [this, os, bone_head_now] {
            at_check(undo_depth() == os->undo + 1, "an IK handle drag is one undo step");
            at_check(bone_head_now("foot_l").y > os->head.y + 0.03f, "...the foot followed the handle up");
        });
        snap("editor_anim3d_ik.png");
        step(2, [this] { undo(); });
        wait_until(settled);
        step(3, [this, os, bone_head_now] { at_check(undo_depth() == os->undo && std::fabs(bone_head_now("foot_l").y - os->head.y) < 0.005f, "Undo put the foot back"); });
        click("a3:tool:rotate");

        // ---- scrubbing and playing
        click("a3:ruler");
        step(3, [this] { at_check(anim3d_.playhead > 0.05, "a click on the ruler moved the playhead"); });
        step(2, [this, os] {
            os->playhead = anim3d_.playhead;
            anim3d_.playhead = 0;
        });
        click("a3:play");
        wait_until([this] { return anim3d_.playhead > 0.05 && anim3d_.playing; });
        click("a3:play");
        step(3, [this] { at_check(!anim3d_.playing, "Play ran the playhead and a second click stopped it"); });

        // ---- an event that only runs game feel actions: typed into the new-event row, with no name
        wait_until([this] { return at_visible("a3:event:newfeel") && at_visible("a3:event:add"); });
        step(2, [this, os] {
            anim3d_.eventName.clear();
            anim3d_.newEventFeel.clear();
            os->undo = undo_depth();
        });
        click("a3:event:add");
        step(3, [this, os] {
            at_check(undo_depth() == os->undo && !anim3d_.newEventError.empty(), "Add with no name and no feel actions was refused, with the reason");
        });
        click("a3:event:newfeel");
        step(3, [this] {
            for (char c : std::string("[{\"action\":\"hitStop\"")) inject_char(unsigned(static_cast<unsigned char>(c)));
        });
        click("a3:event:add");
        step(3, [this, os] {
            at_check(undo_depth() == os->undo && anim3d_.newEventError.find("JSON") != std::string::npos, "feel actions that are not JSON were refused, naming JSON");
        });
        click("a3:event:newfeel");   // the click on Add took the focus away: back in the box; a click puts the cursor where it lands, so End first
        step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_END); });
        step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_END); });
        step(3, [this] {
            for (char c : std::string(",\"duration\":0.05}]")) inject_char(unsigned(static_cast<unsigned char>(c)));
        });
        click("a3:event:add");
        wait_until([this, os, settled] { return settled() && undo_depth() == os->undo + 1; });
        step(3, [this] {
            const Anim3DModel& m = *anim3d_.model;
            const ClipEvent* found = nullptr;
            if (m.clip())
                for (const ClipEvent& ev : m.clip()->events)
                    if (ev.name.empty()) found = &ev;
            at_check(found && found->feel.size() == 1 && found->feel[0].value("action", "") == "hitStop", "Add made a nameless event that holds the hitStop action");
            at_check(anim3d_.newEventError.empty(), "...and cleared the error");
            at_check(anim3d_.selectedEvent >= 0 && anim3d_.eventFeel.find("hitStop") != std::string::npos, "...the new event is the picked one and its feel field shows the actions");
        });
        step(2, [this] { undo(); });
        wait_until([this, os, settled] { return settled() && undo_depth() == os->undo; });
        step(3, [this] {
            bool any = false;
            if (anim3d_.model->clip())
                for (const ClipEvent& ev : anim3d_.model->clip()->events) any = any || ev.name.empty();
            at_check(!any, "Undo took the feel-only event back out of the clip");
            anim3d_.selectedEvent = -1;
            anim3d_.newEventFeel.clear();
        });

        // ---- the filmstrip and the weights
        click("a3:filmstrip");
        wait_until([this] { return anim3d_.film.tex.view != 0 || !anim3d_.film.error.empty(); });
        step(3, [this] {
            at_check(anim3d_.film.error.empty() && anim3d_.film.tex.w > 300 && anim3d_.film.tex.h > 150, "the Filmstrip button drew anim3d.preview's sheet (several poses, three angles)");
            at_check(anim3d_.showSheets, "...in its own window");
        });
        wait_until([this] { return at_visible("a3:sheet:filmstrip"); });
        snap("editor_anim3d_filmstrip.png");
        step(2, [this] { anim3d_.showSheets = false; });   // the sheet window floats over the toolbar: close it like a user would
        click("a3:weights");
        wait_until([this] { return anim3d_.weights.tex.view != 0 || !anim3d_.weights.error.empty(); });
        step(3, [this] { at_check(anim3d_.weights.error.empty() && anim3d_.weights.tex.w > 100, "the Weights button drew skin3d.preview's picture: " + anim3d_.weights.error); });

        // ---- Generate from the panel: a new clip, opened, with Undo and Redo
        step(2, [this, os] {
            os->undo = undo_depth();
            anim3d_.kind = "idle";
            anim3d_.generateOutEdited = false;
        });
        click("a3:section:generate");
        wait_until([this] { return at_shown("a3:generate") && at_enabled("a3:generate"); });
        click("a3:generate");
        wait_until([this, settled] { return anim3d_.model->is_open() && anim3d_.model->path() == "anim/hero_idle.anim.json" && settled(); });
        step(3, [this, os] {
            at_check(undo_depth() == os->undo + 1, "Generate in the panel is one undo step");
            at_check(stdfs::exists(projectDir_ + "/anim/hero_idle.anim.json") && anim3d_.model->clip() && anim3d_.model->clip()->generated.is_object(),
                     "...it wrote the clip and opened it");
        });
        step(2, [this] { undo(); });
        step(4, [this] {
            at_check(!stdfs::exists(projectDir_ + "/anim/hero_idle.anim.json") && !anim3d_.model->is_open(), "Undo deleted the generated clip and closed it");
        });
        step(2, [this] { redo(); });
        wait_until([this, settled] { return anim3d_.model->is_open() && anim3d_.model->path() == "anim/hero_idle.anim.json" && settled(); });
        step(3, [this] { at_check(stdfs::exists(projectDir_ + "/anim/hero_idle.anim.json"), "Redo wrote it again and opened it"); });

        step(2, [this, dir] {
            FA_INFO("autotest", "3D animation panel: {} pictures drawn, {} edits sent", anim3d_.renderCount, anim3d_.commits);
            showAnimation_ = false;
            anim3d_release_textures();
            anim3d_ = Anim3DUi{};
            std::error_code ec;
            stdfs::remove_all(projectDir_ + "/" + dir, ec);
            stdfs::remove_all(projectDir_ + "/anim", ec);
            project_files_changed();
        });
    }
}

}  // namespace fa::editor
