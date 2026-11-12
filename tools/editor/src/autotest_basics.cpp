// Autotest sections T to J: the toolbar, the Audio and Profiler panels, commands that rebuild the scene file, picking and
// bloom, the AI input text, and the Open project, Export, Platform settings and Set Up windows.
// Split from autotest_tools.cpp: each section is an Editor::at_section_<id>(AtScript&) that adds its steps to the script,
// called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include "fa/core/engine_version.h"
#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <memory>
#include <mutex>
#include <atomic>
#include <thread>

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
#include "fa/tooling/play_auto.h"
#include "fa/tooling/qr.h"
#include "sokol_app.h"
#include "imgui_internal.h"
#include "ui_backend.h"

namespace fa::editor {

using namespace at_support;

namespace {

namespace stdfs = std::filesystem;

}  // namespace

void Editor::at_section_T(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The toolbar's Screenshot button. It reads the game target back, which never completes inside the UI frame on Metal (the
    // game's command buffer is not committed yet): the button only asks, on_frame takes the picture between frames. A hang here
    // is caught by the autotest's watchdog (no frame for 60 s) instead of freezing the window for good.
    click("toolbar:screenshot");
    step(8, [this] {
        std::error_code ec;
        bool found = false;
        for (const auto& e : stdfs::directory_iterator(projectDir_ + "/.factoria/screenshots", ec))
            if (e.path().extension() == ".png") found = true;
        at_check(found, "the toolbar Screenshot button saves a PNG into the project's .factoria/screenshots");
        at_check(at_visible("toast:screenshot-reveal"), std::string("the screenshot toast offers Show in ") + file_manager_name());
        toasts_.clear();
    });
}

void Editor::at_section_A(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ----------------------------------------------------------------------------------- A. Audio panel (View menu)
    click("menu:view");
    step(3, [] {});
    click("menu:audio");
    step(4, [this] {
        at_check(showAudio_, "View > Audio shows the Audio panel");
        pendingFocus_ = "Audio";
        play();
    });
    step(12, [this] {
        // The panel may already list sounds the game made earlier in this run: the checks are relative to what it shows now.
        atAudioBase_ = audioLog_.plays.size();
        run_console_line("> audio.play('assets/blip.wav', {bus: 'ui', volume: 0.6})");
        run_console_line("> audio.play('assets/missing.wav')");
    });
    step(6, [this] {
        const size_t n = audioLog_.plays.size();
        at_check(n == atAudioBase_ + 2, "the Audio panel polled both new plays while the game runs");
        if (n >= 2) {
            const AudioPlay& good = audioLog_.plays[n - 2];
            const AudioPlay& bad = audioLog_.plays[n - 1];
            at_check(good.path == "assets/blip.wav" && good.ok && good.bus == "ui", "a successful play shows its clip and bus");
            at_check(bad.path == "assets/missing.wav" && !bad.ok, "a clip that failed to load is flagged ok: false");
        }
        pendingFocus_ = "Audio";
    });
    snap("editor_audio.png");
    step(2, [this] {
        atAudioAfter_ = audioLog_.after;
        run_console_line("> audio.play('assets/blip.wav')");
    });
    step(6, [this] {
        at_check(audioLog_.plays.size() == atAudioBase_ + 3 && audioLog_.after > atAudioAfter_, "only the new play is added (the poll asks for plays after the last seq)");
        audioLog_.filter = "missing";
        size_t visible = 0;
        for (const AudioPlay& p : audioLog_.plays) visible += audio_play_visible(p, audioLog_) ? 1 : 0;
        at_check(visible == 1, "the path filter keeps only matching plays");
        audioLog_.filter.clear();
        audioLog_.onlyFailed = true;
        visible = 0;
        size_t failed = 0;
        for (const AudioPlay& p : audioLog_.plays) {
            visible += audio_play_visible(p, audioLog_) ? 1 : 0;
            failed += p.ok ? 0 : 1;
        }
        at_check(visible == failed && failed >= 1, "Failed only keeps exactly the failed loads");
        audioLog_.onlyFailed = false;
        clear_audio_log(audioLog_);
        at_check(audioLog_.plays.empty(), "Clear empties the list");
    });
    step(4, [this] {
        at_check(audioLog_.plays.empty(), "plays seen before Clear do not come back");
        stop();
        showAudio_ = false;
        pendingFocus_ = "Console";
    });
}

void Editor::at_section_A2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ----------------------------------------------------------------------------------- A2. Profiler panel (View menu)
    // A behaviour on the player, then View > Profiler while the game plays: its class must show up as a row with time and calls.
    step(2, [this, project_file] {
        write_file(project_file("scripts/autotest_spinner.js"),
                   "import { Behaviour } from \"factoria\";\n"
                   "export default class AutotestSpinner extends Behaviour {\n"
                   "  onUpdate(dt) { let x = 0; for (let i = 0; i < 4000; i++) x += Math.sqrt(i); this.sum = x; }\n"
                   "}\n");
        run_console_line("scene.set_component {\"id\":\"player\",\"component\":\"Script\",\"fields\":{\"path\":\"scripts/autotest_spinner.js\"}}");
    });
    click("menu:view");
    step(3, [] {});
    click("menu:profiler");
    step(4, [this] {
        at_check(showProfiler_, "View > Profiler shows the Profiler panel");
        pendingFocus_ = "Profiler";
        play();
    });
    step(40, [] {});
    step(4, [this] {
        at_check(profView_.frames > 10, "the Profiler panel measured the frames of the running game");
        const auto row = std::find_if(profView_.rows.begin(), profView_.rows.end(),
                                      [](const ProfilerView::Row& r) { return r.className == "AutotestSpinner"; });
        at_check(row != profView_.rows.end(), "a row for the behaviour class AutotestSpinner appears");
        if (row != profView_.rows.end()) {
            at_check(row->ms > 0.0 && row->calls > 0.5, "...with milliseconds and about one onUpdate call per frame");
            at_check(row->path == "scripts/autotest_spinner.js", "...and its script path");
        }
        at_check(profView_.systemMs[std::size_t(ProfSystem::ScriptsUpdate)] > 0.0, "the scriptsUpdate system has time");
        pendingFocus_ = "Profiler";
    });
    snap("editor_profiler.png");
    // Threads tab: jobs that run while the game plays show up on the thread that ran them, one row per thread of the pool.
    for (int k = 0; k < 12; ++k) {
        step(1, [this] {
            std::vector<double> sums(16, 0.0);
            auto r = jobs::parallel_for("autotest.spin", 4096, 256, [&sums](const jobs::Chunk& c) {
                double x = 0;
                for (std::size_t i = c.begin; i < c.end; ++i) x += std::sqrt(double(i));
                sums[c.index] = x;
            });
            if (!r.ok()) at_check(false, "a parallel_for on the editor's main thread runs: " + r.error().to_string());
        });
    }
    step(4, [this] {
        const auto& lanes = profView_.lanes;
        at_check(!lanes.empty() && lanes[0].name == "main", "the Threads tab lists the main thread first");
        at_check(lanes.size() >= std::size_t(1 + jobs::worker_count()), "...and one row per worker of the job pool");
        bool seen = false;
        for (const ProfilerView::LaneRow& l : lanes)
            for (const ProfilerView::JobRow& j : l.top) seen = seen || (j.name == "autotest.spin" && j.ms > 0.0);
        at_check(seen, "...and the autotest.spin job with its time on a thread that ran it");
        profShowThreads_ = true;
        pendingFocus_ = "Profiler";
    });
    snap("editor_profiler_threads.png");
}

void Editor::at_section_B(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ---------------------------------------------------------- B. Commands that rebuild the open scene file (Console / AI)
    // A file import into the OPEN scene reloads it in the viewport, and Ctrl+Z still brings back what was on screen.
    step(2, [this] {
        run_console_line("scene.set_component " +
                         Json::object({{"id", "player"},
                                       {"component", "Transform"},
                                       {"fields", Json::object({{"position", Json::array({-305, -250, 0})}})}})
                             .dump());
        at_check(dirty(), "an unsaved edit before a console import");
        run_console_line("scene.import_ascii {\"rows\":[\"...\",\"###\"],\"legend\":{\"#\":0},\"entity\":\"map3\",\"path\":\"" + scenePath_ + "\"}");
    });
    step(3, [this] {
        at_check(!world().find_by_id("map3").is_null(), "a console import into the open scene reloads it");
        at_check(!dirty() && undo_depth() == 1, "...and nothing is lost: the unsaved edit is one Ctrl+Z away");
        undo();
        at_check(world().find_by_id("map3").is_null() && dirty(), "Ctrl+Z restores the scene as it was before the import");
        redo();
        at_check(!world().find_by_id("map3").is_null(), "Ctrl+Y brings the imported level back");
        undo();
        run_console_line("scene.import_ascii {\"rows\":[\"#\"],\"legend\":{\"#\":0},\"path\":\"scenes/other_level.scene.json\"}");
        at_check(dirty() && world().find_by_id("map3").is_null(), "an import into another file does not touch the open scene or its unsaved changes");
        at_check(fs::exists("scenes/other_level.scene.json"), "...it just writes the file");
    });
}

void Editor::at_section_C(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------- C. Pick bounds and the selection outline against the real renderer
    step(2, [this] {
        World& w = world();
        auto make = [&](const char* id, Vec3 pos, float rot) {
            Entity e = w.create(id, id);
            Transform* t = w.get<Transform>(e);
            t->position = pos;
            t->rotation = {0, 0, rot};
            return e;
        };
        Entity dia = make("test_diamond", {200, 150, 0}, 30.0f);
        Shape2D& d = w.add<Shape2D>(dia);
        d.shape = ShapeType::Diamond;
        d.size = {80, 40};
        d.color = {0.9f, 0.5f, 0.9f, 1};
        Entity tri = make("test_triangle", {-200, 150, 0}, 90.0f);
        Shape2D& t = w.add<Shape2D>(tri);
        t.shape = ShapeType::Triangle;
        t.size = {60, 90};
        t.pivot = {0.5f, 0.3333f};
        t.color = {0.4f, 0.9f, 0.5f, 1};
        // A Tilemap in rows form (3 x 2 tiles, top-left corner at (350, 250)) and a world-space Text.
        Entity rowsMap = make("test_rows_map", {350, 250, 0}, 0.0f);
        Tilemap& rm = w.add<Tilemap>(rowsMap);
        rm.tileSize = {32, 32};
        rm.tiles = Json::parse("[[0,0,0],[0,-1,0]]");
        Entity worldText = make("test_text", {-120, 300, 0}, 0.0f);
        Text& wt = w.add<Text>(worldText);
        wt.text = "World text";
        wt.fontSize = 28;
        // Screen-space text at the top-left (pivot top-left, y down): the shape the template's HUD text has, made here.
        Entity hudText = make("test_hud_text", {24, 24, 0}, 0.0f);
        Text& ht = w.add<Text>(hudText);
        ht.text = "Coins: 0";
        ht.fontSize = 32;
        ht.pivot = {0, 1};
        ht.space = RenderSpace::Screen;
        ht.layer = 100;
        Entity hudBox = make("test_hud", {-20, 60, 0}, 0.0f);
        Shape2D& h = w.add<Shape2D>(hudBox);
        h.size = {100, 40};
        h.pivot = {1, 0};
        h.space = RenderSpace::Screen;
        h.anchor = {1, 0};
        h.layer = 50;
        h.color = {0.2f, 0.2f, 0.2f, 0.8f};
    });
    step(3, [this] {
        Renderer* r = engine_->renderer();
        World& w = world();
        auto design = [&](float x, float y) { return r->world_to_screen(Vec3{x, y, 0}); };
        const Entity tri = w.find_by_id("test_triangle"), dia = w.find_by_id("test_diamond"), hud = w.find_by_id("test_hud");
        // Rotated triangle (pivot [0.5, 0.3333], turned 90 degrees): world x -260..-170, y 120..180 around its origin (-200, 150).
        at_check(pick_at(design(-255, 150)) == tri, "pick: inside the rotated triangle's oriented box");
        at_check(pick_at(design(-200, 205)) != tri, "pick: outside the oriented box, though inside the unrotated one");
        at_check(pick_at(design(-165, 150)) != tri, "pick: past the base of the rotated triangle");
        // Diamond turned by 30 degrees: its size box is 80 x 40 around (200, 150).
        at_check(pick_at(design(200, 150)) == dia, "pick: the diamond's centre");
        at_check(pick_at(design(200 + 30, 150 + 8)) == dia, "pick: inside the turned size box");
        at_check(pick_at(design(200, 150 + 60)) != dia, "pick: above the diamond");
        // Tilemap in rows form: x 350..446, y 186..250 (local y goes down from the top-left corner).
        const Entity rowsMap = w.find_by_id("test_rows_map");
        at_check(pick_at(design(400, 220)) == rowsMap, "pick: inside a Tilemap given as rows");
        at_check(pick_at(design(400, 180)) != rowsMap, "pick: below the map's last row");
        at_check(pick_at(design(400, 256)) != rowsMap, "pick: above the map's top-left corner");
        // Text: the box the renderer lays out (pivot top-left), not an estimate.
        const Entity worldText = w.find_by_id("test_text");
        const Vec2 ts = r->measure_text("World text", 28);
        at_check(ts.x > 100 && ts.y > 20, "the renderer measures the text");
        at_check(pick_at(design(-120 + ts.x * 0.5f, 300 - ts.y * 0.5f)) == worldText, "pick: inside the measured Text box");
        at_check(pick_at(design(-120 + ts.x + 12, 300 - ts.y * 0.5f)) != worldText, "pick: just past the measured end of the Text");
        at_check(pick_at(design(-120 + ts.x * 0.5f, 300 + 8)) != worldText, "pick: above the Text (pivot is the top-left corner)");
        // Screen space: a panel anchored top-right (x 1160..1260, y 20..60 on the 1280 x 720 screen).
        at_check(pick_at(Vec2{1200, 40}) == hud, "pick: a screen-space shape with an anchor");
        at_check(pick_at(Vec2{1100, 40}) != hud, "pick: left of the anchored panel");
        // Screen-space text (pivot top-left, y down): picked on its drawn box, not mirrored above it.
        const Entity text = w.find_by_id("test_hud_text");
        const PickBounds tb = bounds_of(text);
        at_check(tb.screenSpace, "the HUD text is a screen-space entity");
        at_check(pick_at(Vec2{40, 40}) == text, "pick: the screen-space HUD text under the cursor");
        // The engine's entity.bounds() (script) and the editor's footprint agree.
        auto r2 = engine_->commands().call("script.eval", Json::object({{"code", "world.find('test_diamond').bounds().toArray()"}}));
        const std::optional<Rect> eb = entity_world_rect(w, dia, visual_measure());
        const Json v = r2.ok ? r2.result.value("value", Json()) : Json();
        bool same = eb && v.is_array() && v.size() == 4;
        if (same) {
            const float mine[4] = {eb->x, eb->y, eb->w, eb->h};
            for (size_t i = 0; i < 4; ++i) same = same && std::fabs(v[i].get<float>() - mine[i]) < 0.01f;
        }
        at_check(same, "entity.bounds() in a script equals the editor's world rectangle for the turned diamond");
        select(dia);
    });
    snap("editor_select_diamond.png");
    step(1, [this] { select_id("test_triangle"); });
    snap("editor_select_triangle.png");
    step(1, [this] { select_id("test_hud_text"); });
    snap("editor_select_hud.png");
}

void Editor::at_section_D(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------------------------ D. Bloom in the viewport
    step(1, [this] {
        // A glow source on an empty patch of sky; bloom is still off, and nothing is selected (no outline in the way).
        Entity glow = world().create("test_glow", "test_glow");
        world().get<Transform>(glow)->position = Vec3{-420, 230, 0};
        Shape2D& g = world().add<Shape2D>(glow);
        g.shape = ShapeType::Circle;
        g.size = {70, 70};
        g.color = {1, 1, 1, 1};
        g.blend = BlendMode::Additive;
        g.layer = 5;
        select_id("");
    });
    step(4, [this] {
        // Bloom OFF reference.
        atPostFrame_.push_back([this] { at_check(capture_window(atShotBefore_), "captured the window without bloom"); });
    });
    step(3, [this] {
        // The command the AI uses; the values are inside the documented ranges (threshold 0..1, intensity 0..10, radius 1..128).
        const CommandResult r = engine_->commands().call(
            "scene.set_component",
            Json::parse(R"({"id":"camera","component":"Camera","fields":{"bloom":true,"bloomThreshold":0.8,"bloomIntensity":1.6,"bloomRadius":40}})"));
        at_check(r.ok, "scene.set_component: Camera.bloom on");
        Entity cam = world().find_by_id("camera");
        at_check(!cam.is_null() && std::fabs(world().get<Camera>(cam)->bloomRadius - 40.0f) < 0.001f, "the Camera bloom fields were written");
    });
    step(5, [this] {
        atPostFrame_.push_back([this] {
            Image after;
            if (!capture_window(after) || atShotBefore_.empty()) {
                at_check(false, "captured the window with bloom");
                return;
            }
            Renderer* r = engine_->renderer();
            const Vec2 d = r->world_to_screen(Vec3{-420, 230, 0});
            const float sx = vpImageSize_.x / float(r->target_width());
            const float cx = (vpImageMin_.x + d.x * sx) * dpi_, cy = (vpImageMin_.y + d.y * sx) * dpi_;
            const float radius = 35.0f * sx * dpi_;
            auto ring_sum = [&](const Image& img) {
                double sum = 0;
                int n = 0;
                for (int y = int(cy - radius * 2.4f); y <= int(cy + radius * 2.4f); ++y)
                    for (int x = int(cx - radius * 2.4f); x <= int(cx + radius * 2.4f); ++x) {
                        const float dist = std::hypot(float(x) - cx, float(y) - cy);
                        if (dist < radius * 1.2f || dist > radius * 2.2f || x < 0 || y < 0 || x >= img.width || y >= img.height) continue;
                        const std::uint8_t* px = &img.rgba[(size_t(y) * size_t(img.width) + size_t(x)) * 4];
                        sum += px[0] + px[1] + px[2];
                        ++n;
                    }
                return n ? sum / n : 0.0;
            };
            const double before = ring_sum(atShotBefore_), now = ring_sum(after);
            FA_INFO("autotest", "bloom ring brightness: off {:.1f}, on {:.1f}", before, now);
            at_check(now > before + 6.0, "Camera.bloom is visible in the editor viewport (the glow brightens the area around the bright shape)");
        });
    });
    snap("editor_bloom.png");
}

void Editor::at_section_E(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------------- E. Ctrl+V into the AI Assistant input
    // sokol_app turns Ctrl+V into a CLIPBOARD_PASTED event (only with the clipboard enabled); sokol_imgui then presses
    // Ctrl+V for ImGui, which pastes the clipboard's text into the focused box.
    static const char* kPasted = "A 3D tower game.\nThree levels.";
    click("ai:input");
    step(4, [this] {
        chat_.current().input.clear();
        sapp_set_clipboard_string(kPasted);
        sapp_event ev{};
        ev.type = SAPP_EVENTTYPE_CLIPBOARD_PASTED;
        on_event(&ev);
    });
    step(2, [this] {
        at_check(chat_.current().input == kPasted, "Ctrl+V pastes the clipboard's text into the AI Assistant input");
        chat_.current().input.clear();
        focus_window("###Viewport");
    });
}

void Editor::at_section_F(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ----------------------------------------------- F. AI Assistant text: wrapping, right-click menu, selectable messages
    auto rclick = [this, &step](const std::string& name) {
        step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
        step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name), 1); });
        step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name), 1); });
    };
    static const char* kLong = "Make a 3D tower game: the player throws balls at towers of crates, three levels, each tower "
                               "taller than the last, a score for every crate that falls off, and a restart button at the end.";
    step(2, [this] { chat_.current().input = kLong; });  // before the click: an active box keeps its own copy of the text
    click("ai:input");
    snap("editor_ai_input_wrap.png");  // the long message wraps inside the box
    rclick("ai:input");
    click("textmenu:Select all");
    rclick("ai:input");
    snap("editor_ai_text_menu.png");
    click("textmenu:Cut");
    step(2, [this] {
        at_check(chat_.current().input.empty(), "right-click > Select all, then Cut, empties the AI Assistant input");
        const char* clip = ImGui::GetClipboardText();
        at_check(clip && std::string(clip) == kLong, "Cut puts the text on the clipboard");
    });
    rclick("ai:input");
    click("textmenu:Paste");
    step(2, [this] {
        at_check(chat_.current().input == kLong, "right-click > Paste puts the clipboard's text back");
        chat_.current().input.clear();
        ChatItem reply;
        reply.kind = ChatItem::Kind::Assistant;
        reply.text = "Copy this reply.";
        chat_.current().items.push_back(reply);
        chat_.current().scrollDown = true;
    });
    rclick("ai:message");
    click("textmenu:Select all");
    rclick("ai:message");
    click("textmenu:Copy");
    step(2, [this] {
        const char* clip = ImGui::GetClipboardText();
        at_check(clip && std::string(clip) == "Copy this reply.", "an assistant message can be selected and copied (right-click > Select all, Copy)");
        chat_.current().items.pop_back();
    });

    // New output is followed only at the bottom: scrolled up to read, the transcript stays put and "Jump to latest" goes back.
    auto transcript = [] {
        for (ImGuiWindow* w : GImGui->Windows)
            if (std::strstr(w->Name, "AI Assistant/##chat_") && !std::strstr(w->Name, "##jump") && w->Active) return w;
        return static_cast<ImGuiWindow*>(nullptr);
    };
    auto items0 = std::make_shared<std::size_t>();
    step(2, [this, items0] {
        *items0 = chat_.current().items.size();
        for (int i = 0; i < 80; ++i) {
            ChatItem it;
            it.kind = ChatItem::Kind::Info;
            it.text = "line " + std::to_string(i);
            chat_.current().items.push_back(it);
        }
        chat_.current().forceScroll = true;
    });
    step(3, [this, transcript] {
        ImGuiWindow* w = transcript();
        at_check(w && w->ScrollMax.y > 0 && w->Scroll.y >= w->ScrollMax.y - 4, "the AI transcript scrolls to the bottom");
        if (w) ImGui::SetScrollY(w, 0);  // the user scrolls up to read
    });
    step(3, [this] {
        ChatItem it;
        it.kind = ChatItem::Kind::Info;
        it.text = "new output while reading";
        chat_.current().items.push_back(it);
        chat_.current().scrollDown = true;
    });
    step(3, [this, transcript] {
        ImGuiWindow* w = transcript();
        at_check(w && w->Scroll.y < 1, "new output does not move a transcript the user scrolled up");
    });
    snap("editor_ai_jump_latest.png");
    click("ai:jump");
    step(3, [this, transcript] {
        ImGuiWindow* w = transcript();
        at_check(w && w->Scroll.y >= w->ScrollMax.y - 4, "Jump to latest goes back to the bottom");
    });
    step(2, [this] {
        ChatItem it;
        it.kind = ChatItem::Kind::Info;
        it.text = "followed again";
        chat_.current().items.push_back(it);
        chat_.current().scrollDown = true;
    });
    step(3, [this, transcript] {
        ImGuiWindow* w = transcript();
        at_check(w && w->Scroll.y >= w->ScrollMax.y - 4, "at the bottom again, new output is followed");
    });
    // The grip above the message box makes it taller.
    auto grip = std::make_shared<Vec2>();
    step(2, [this, grip] {
        aiInputH_ = 0;
        *grip = at_widget("ai:input:grip");
        inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, *grip);
    });
    step(2, [this, grip] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, *grip); });
    step(2, [this, grip] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{grip->x, grip->y - 40}); });
    step(2, [this, grip] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{grip->x, grip->y - 80}); });
    step(2, [this, grip] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, Vec2{grip->x, grip->y - 80}); });
    snap("editor_ai_input_tall.png");
    step(2, [this, items0, transcript] {
        const float def = ImGui::GetTextLineHeight() * 3.4f + 8;
        at_check(aiInputH_ > def + 40, "dragging the grip up makes the AI message box taller (" + std::to_string(aiInputH_) + ")");
        ImGuiWindow* w = transcript();
        at_check(w && w->Scroll.y >= w->ScrollMax.y - 4, "a transcript at the bottom stays at the bottom while the box grows");
        aiInputH_ = 0;
        chat_.current().items.resize(*items0);
        focus_window("###Viewport");
    });
}

void Editor::at_section_G(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------- G. Delete a project from the Open project dialog
    step(2, [this] {
        atDeleteProject_ = atOutDir_ + "/delete-me";
        ScaffoldOptions so;
        so.name = "delete-me";
        auto r = create_project(atDeleteProject_, "2d-empty", so);
        at_check(bool(r), "a scratch project to delete was created");
        showProjectDialog_ = true;
    });
    step(2, [this] { dlgOpenPath_ = atDeleteProject_; });
    click("project:delete");
    snap("editor_delete_project.png");  // the confirmation popup
    step(2, [this] { at_check(stdfs::exists(atDeleteProject_), "Delete... only asks: the project is still there"); });
    click("project:delete-confirm");
    step(2, [this] {
        at_check(!stdfs::exists(atDeleteProject_), "confirming deletes the project folder");
        at_check(dlgError_.empty(), "no error deleting the project (" + dlgError_ + ")");
        showProjectDialog_ = false;
        dlgScanned_ = false;
    });
}

void Editor::at_section_H(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------- H. Export window: a button per platform, then the export's report
    // Export Game in the menu bar opens it. Every platform's row says what an export there writes, or why it cannot run here
    // (another OS's desktop player is not in this build tree). This machine's platform is exported for real, with the
    // factoria_player of the build tree, on the export's worker thread; the report shows the folder and the next steps.
    const std::string host = normalize_export_platform("");
    auto host_status = [this, host]() -> const ExportStatus* {
        for (size_t i = 0; i < export_targets().size() && i < exportStatus_.size(); ++i)
            if (host == export_targets()[i].platform) return &exportStatus_[i];
        return nullptr;
    };
    step(2, [this] {
        at_check(windowTitle_ == editor_window_title(FA_ENGINE_VERSION, "Autotest Platformer"),
                 "the window title names the engine version and the project (" + windowTitle_ + ")");
        at_check(at_visible("menu:version"), "the menu bar shows the engine version at its right end");
    });
    click("menu:export");
    step(4, [this, host_status] {
        at_check(showExport_, "the Export Game item of the menu bar opens the Export window");
        at_check(exportStatus_.size() == export_targets().size(), "the Export window checked every platform");
        for (size_t i = 0; i < exportStatus_.size() && i < export_targets().size(); ++i) {
            const ExportTarget& t = export_targets()[i];
            const ExportStatus& st = exportStatus_[i];
            if (st.ready) continue;
            at_check(!st.error.empty() && !st.hint.empty(), std::string(t.label) + " is not ready and says why and how to fix it");
            if (export_needs_player(t.platform))
                at_check(st.error.find("cannot export for") != std::string::npos,
                         std::string(t.label) + " needs a player built for it (" + st.error + ")");
        }
        const ExportStatus* st = host_status();
        if (st && !st->ready) {  // a build tree without factoria_player: export with a stand-in, the window is what is tested
            atLog_.push_back("NOTE no factoria_player for this machine (" + st->error + "): exporting with a stand-in player");
            const std::string fake = atOutDir_ + "/stand-in-player/factoria_player";
            write_file(fake, "#!/bin/sh\nexit 0\n");
            exportSettings_.players[normalize_export_platform("")] = fake;
            exportChecked_ = -100;
        }
    });
    snap("editor_export_window.png");
    click("export:" + host);
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return !exportJob_.running() && exportLast_.has_value(); };
    });
    step(2, [this, host] {
        at_check(exportLast_.has_value(), "pressing this machine's Export button runs an export that finishes");
        if (!exportLast_) return;
        const ExportOutcome& o = *exportLast_;
        at_check(o.ok && o.platform == host, "the " + host + " export succeeded (" + o.error + " " + o.hint + ")");
        if (!o.ok) return;
        std::error_code ec;
        const stdfs::path out = stdfs::weakly_canonical(o.report.outputDir, ec);
        const stdfs::path parent = stdfs::weakly_canonical(stdfs::path(projectDir_) / "build" / "export", ec);
        at_check(out.parent_path() == parent && out.filename().string() == "autotest-platformer-" + host,
                 "the export went to <project>/build/export/<game>-<platform> (" + o.report.outputDir + ")");
        at_check(stdfs::exists(out / o.report.notices), "the license notices are where the report says (" + o.report.notices + ")");
        at_check(!o.report.nextSteps.empty(), "the report lists the next steps");
        at_check(at_visible("export:reveal"), std::string("the report offers Show in ") + file_manager_name());
        at_check(export_report_text(o).find(o.report.outputDir) != std::string::npos, "Copy report includes the output folder");
    });
    snap("editor_export_report.png");
    step(2, [this] { showExport_ = false; });
}

void Editor::at_section_I(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------- I. Platform settings window
    // Opened from the Settings... button of the Android row in the Export window, then through the tabs. Edits make it dirty,
    // the Export window's format menu keeps working next to pending edits, Save writes factoria.json (and only that: this
    // computer's file is untouched), closing with unsaved changes asks, and File > Platform Settings... opens it again.
    // This computer's settings live in a scratch file (FACTORIA_EXPORT_CONFIG, set by on_init): never the user's own.
    const std::string machineFile = machine_export_config_path();
    step(2, [this, project_file] {
        // A game icon with a transparent corner, as the AI would make one.
        Image icon;
        icon.width = icon.height = 1024;
        icon.rgba.resize(size_t(icon.width) * size_t(icon.height) * 4);
        for (int y = 0; y < icon.height; ++y)
            for (int x = 0; x < icon.width; ++x) {
                std::uint8_t* px = &icon.rgba[(size_t(y) * size_t(icon.width) + size_t(x)) * 4];
                px[0] = std::uint8_t(x / 4);
                px[1] = std::uint8_t(y / 4);
                px[2] = 200;
                px[3] = (x < 200 && y < 200) ? 0 : 255;
            }
        at_check(save_png(icon, project_file("assets/icon.png")).ok(), "a game icon was written to assets/icon.png");
    });
    click("menu:export");
    step(4, [this] { at_check(at_visible("export:settings:android"), "the Export window has a Settings... button on the Android row"); });
    // On a smaller screen (the macOS runner's 1024x642) the Android row can be out of view: above it after section H (the
    // window stays scrolled down to the report it showed), below it when this section runs alone. Scroll to it.
    scroll_until("export:settings:android", 6, Vec2{700, 400}, 560);
    click("export:settings:android");
    step(4, [this] {
        at_check(showPlatformSettings_, "the Android row's Settings... button opens the Platform settings window");
        at_check(platformTab_ == SettingsTab::Android, "...on the Android tab");
        at_check(platformSettings_.loaded() && !platformSettings_.dirty(), "...with nothing to save yet");
        at_check(platformSettings_.info.name == "Autotest Platformer", "it shows the game's own name (" + platformSettings_.info.name + ")");
        at_check(platformSettings_.parseErrors.empty() && platformSettings_.fileError.empty(), "the project's export settings read without errors");
        // What a person types in the fields.
        PlatformSettings& ps = platformSettings_;
        ps.project.icon = "assets/icon.png";
        ps.project.android.versionCode = 12;
        ps.project.android.permissions = {"android.permission.VIBRATE"};
        ps.project.android.signing.keystore = "keys/upload.keystore";
        ps.project.macos.copyright = "Copyright 2026 Autotest";
        ps.project.ios.teamId = "ABCDE12345";
        at_check(ps.dirty(), "typing in a field makes the settings dirty");
        at_check(ps.validate().errors.empty(), "the edits are valid");
        at_check(ps.validate().warning_for("/export/android/signing/alias") != nullptr, "a keystore without an alias is a warning next to the alias field");
    });
    snap("editor_platform_android.png");
    scroll_until("platform:keystore-create", -6, Vec2{800, 420}, 560);
    snap("editor_platform_android_signing.png");
    click("platform:keystore-create");
    step(4, [this] {
        at_check(keystoreOpen_, "Create keystore... opens its window");
        at_check(!keystoreForm_.path.empty() && keystoreForm_.alias == "upload", "...with a keystore path and the alias upload filled in");
    });
    snap("editor_platform_keystore.png");
    click("platform:keystore-cancel");
    step(4, [this] { at_check(!keystoreOpen_, "Cancel closes the keystore window"); });
    click("platform:tab:general");
    step(4, [this] { at_check(platformTab_ == SettingsTab::General, "clicking the General tab shows it"); });
    snap("editor_platform_general.png");
    click("platform:tab:macos");
    step(4, [this] { at_check(platformTab_ == SettingsTab::Macos, "clicking the macOS tab shows it"); });
    snap("editor_platform_macos.png");
    click("platform:tab:ios");
    step(4, [this] { at_check(platformTab_ == SettingsTab::Ios, "clicking the iOS tab shows it"); });
    snap("editor_platform_ios.png");
    click("platform:tab:linux");
    step(4, [this] { at_check(platformTab_ == SettingsTab::Linux, "clicking the Linux tab shows it"); });
    snap("editor_platform_linux.png");
    click("platform:tab:windows");
    step(4, [this] { at_check(platformTab_ == SettingsTab::Windows, "clicking the Windows tab shows it"); });
    snap("editor_platform_windows.png");

    // The Export window's format menu, with edits pending here: the format is saved at once and the working copy follows.
    step(2, [this] {
        set_android_format("aab");
        auto saved = load_export_settings(projectDir_);
        at_check(saved.ok() && saved->android.format == "aab", "the Export window's format menu saves export.android.format in factoria.json");
        at_check(saved.ok() && saved->android.versionCode == 0, "...and nothing else of the pending edits");
        at_check(platformSettings_.project.android.format == "aab" && platformSettings_.project.android.versionCode == 12,
                 "...while the Platform settings window keeps its other edits");
        at_check(platformSettings_.dirty(), "...which are still unsaved");
        at_check(!platformSettings_.project_file_changed(), "factoria.json written by the editor itself is not reported as changed behind its back");
    });
    // The same for the Windows format (folder | MSIX): saved at once, the pending edits stay.
    step(2, [this] {
        set_windows_format("msix");
        auto saved = load_export_settings(projectDir_);
        at_check(saved.ok() && saved->windows.format == "msix", "the Export window's Windows format menu saves export.windows.format in factoria.json");
        at_check(saved.ok() && saved->android.versionCode == 0, "...and nothing else of the pending edits");
        at_check(platformSettings_.project.windows.format == "msix" && platformSettings_.project.android.versionCode == 12,
                 "...while the Platform settings window keeps its other edits");
        at_check(platformSettings_.dirty(), "...which are still unsaved");
        at_check(!platformSettings_.project_file_changed(), "factoria.json written by the editor itself is not reported as changed behind its back");
        platformSettings_.project.windows.msix.identityName = "12345Autotest.Platformer";
        platformSettings_.project.windows.msix.publisher = "CN=0123ABCD-4567-89EF-0123-456789ABCDEF";
        platformSettings_.project.windows.msix.publisherDisplayName = "Autotest Studio";
    });
    click("platform:tab:android");
    step(3, [this] { platformSettings_.project.android.signing.alias = "upload"; });
    click("platform:save");
    step(4, [this, machineFile] {
        at_check(!platformSettings_.dirty(), "Save leaves nothing unsaved");
        auto saved = load_export_settings(projectDir_);
        at_check(saved.ok(), "factoria.json still reads after Save");
        if (saved.ok()) {
            at_check(saved->icon == "assets/icon.png", "Save wrote the game icon");
            at_check(saved->android.versionCode == 12 && saved->android.format == "aab", "Save wrote the Android settings");
            at_check(saved->windows.format == "msix" && saved->windows.msix.identityName == "12345Autotest.Platformer" &&
                         saved->windows.msix.publisherDisplayName == "Autotest Studio",
                     "Save wrote the Windows MSIX settings");
            at_check(saved->android.permissions == std::vector<std::string>{"android.permission.VIBRATE"}, "Save wrote the permissions");
            at_check(saved->android.signing.keystore == "keys/upload.keystore" && saved->android.signing.alias == "upload", "Save wrote the signing key");
            at_check(saved->macos.copyright == "Copyright 2026 Autotest" && saved->ios.teamId == "ABCDE12345", "Save wrote the macOS and iOS settings");
        }
        auto project = load_project(projectDir_);
        at_check(project.ok() && project->name == "Autotest Platformer", "Save kept the game's own keys");
        at_check(!std::filesystem::exists(machineFile), "Save did not write this computer's file (nothing of it was edited)");
    });

    // Closing with unsaved changes asks first.
    step(2, [this] { platformSettings_.project.windows.icon = "assets/icon.png"; });
    click("platform:close");
    step(4, [this] {
        at_check(platformCloseAsk_ && showPlatformSettings_, "Close with unsaved changes asks instead of closing");
    });
    snap("editor_platform_unsaved.png");
    click("platform:close-discard");
    step(4, [this] {
        at_check(!showPlatformSettings_ && !platformCloseAsk_, "Discard closes the window");
        auto saved = load_export_settings(projectDir_);
        at_check(saved.ok() && saved->windows.icon.empty(), "...without saving the edit");
    });
    click("menu:file");
    step(3, [] {});
    click("menu:platform-settings");
    step(4, [this] {
        at_check(showPlatformSettings_ && platformTab_ == SettingsTab::General, "File > Platform Settings... opens the window on General");
        at_check(platformSettings_.loaded() && !platformSettings_.dirty() && platformSettings_.project.icon == "assets/icon.png",
                 "...with what was saved");
    });
    snap("editor_platform_reopened.png");
    click("platform:close");
    step(4, [this] { at_check(!showPlatformSettings_, "Close with nothing unsaved just closes"); });
    step(2, [this] { showExport_ = false; });
}

void Editor::at_section_J(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------- J. Set Up This Computer
    // File > Set Up This Computer... lists the five components; the Export window and the Platform settings tabs offer the
    // "Set up" button that fixes a row; the Android SDK license dialog only lets "I accept" through after its checkbox.
    // The editor's setup context in the autotest (on_init) can neither download nor run a program, and its FACTORIA_HOME is a
    // folder of the autotest's own: no step here can install anything, and none presses "I accept".
    std::string otherOs, ownOs;  // a desktop platform that needs another OS's player, and one that does not
    for (const char* p : {"windows", "linux", "macos"}) {
        if (export_needs_player(p) && otherOs.empty()) otherOs = p;
        if (!export_needs_player(p) && ownOs.empty()) ownOs = p;
    }
    // A Mac with nothing set up, and Export rows to match: the other OS's player and the Android toolchain missing, the rest ready.
    auto inject_setup = [this, otherOs] {
        SetupStatus st;
        st.home = atOutDir_ + "/factoria_home";
        st.host = "injected-autotest";
        auto add = [&st](const char* id, const char* title, const char* details, int mb) {
            SetupComponent c;
            c.id = id;
            c.title = title;
            c.state = "missing";
            c.details = details;
            c.installSizeMb = mb;
            c.canInstall = true;
            st.components.push_back(c);
        };
        add("android", "Android export (JDK + Android SDK)", "`setup.install android` fetches what is missing.", 600);
        add("players", "Players of the other platforms", "Missing: other desktop players and mobile libraries.", 60);
        add("cmake", "CMake (iOS export)", "CMake 3.24 or newer is needed by build_ios.sh.", 75);
        st.components.back().problems = {"No CMake 3.24 or newer was found (PATH, Homebrew, /Applications/CMake.app)."};
        add("xcode", "Xcode (iOS export)", "Xcode is not installed.", 0);
        setupStatus_.set(st, time_ + 100000.0);  // far in the future: the window's own refresh leaves it alone
        setupRefreshAgain_ = false;
        exportStatus_.assign(export_targets().size(), ExportStatus{});
        for (size_t i = 0; i < exportStatus_.size(); ++i) {
            const std::string platform = export_targets()[i].platform;
            exportStatus_[i].ready = true;
            exportStatus_[i].hint = "injected-autotest";
            if (platform == otherOs) {
                exportStatus_[i].ready = false;
                exportStatus_[i].error = "export: cannot export for " + platform + " without a player binary built for " + platform;
            } else if (platform == "android") {
                exportStatus_[i].ready = false;
                exportStatus_[i].error = "export: cannot build the Android app on this computer: No JDK 17 or newer was found.";
            }
        }
        exportChecked_ = time_ + 100000.0;
        exportLast_.reset();  // the report of section H would push the rows out of view
    };
    auto action_labels = [this](const std::string& platform) {
        std::vector<std::string> out;
        for (size_t i = 0; i < export_targets().size() && i < exportStatus_.size(); ++i)
            if (platform == export_targets()[i].platform)
                for (const SetupAction& a : setup_actions_for_row(platform, exportStatus_[i], setupStatus_.status())) out.push_back(a.label);
        return out;
    };

    // The window: File > Set Up This Computer... lists the seven components, each with its Install button (the AppImage
    // tools and sokol-shdc have none yet: `factoria setup appimage|shaders`).
    click("menu:file");
    step(3, [] {});
    click("menu:setup");
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return setupStatus_.has() && !setupStatus_.refreshing(); };
    });
    step(4, [this] {
        at_check(showSetup_, "File > Set Up This Computer... opens the window");
        const SetupStatus& st = setupStatus_.status();
        std::string ids;
        for (const SetupComponent& c : st.components) ids += c.id + " ";
        at_check(ids == "android players cmake xcode appimage shaders vscode ffmpeg webplayer launcher ", "the window lists the ten components, in order (" + ids + ")");
        at_check(st.home == (std::filesystem::path(atOutDir_) / "factoria_home").string(), "...installing into the autotest's own FACTORIA_HOME (" + st.home + ")");
        for (const SetupComponent& c : st.components)
            if (setup_action_for_component(c, st.home))
                at_check(at_visible("setup:install:" + c.id) && at_enabled("setup:install:" + c.id), "the " + c.id + " component has an Install button");
        at_check(at_visible("setup:install:android") && at_visible("setup:install:players"), "Android and players can always be installed");
        at_check(at_visible("setup:refresh"), "the window can check the computer again");
        at_check(!setupJob_.running() && !setupLast_, "nothing is installed until a button is pressed");
    });
    snap("editor_setup_window.png");
    step(2, [this] { showSetup_ = false; });

    // The Export window: the "Set up" button that fixes each row that is not ready.
    step(2, [this, inject_setup] {
        inject_setup();
        showExport_ = true;
        exportFocus_ = true;
    });
    step(4, [this, otherOs, ownOs, action_labels] {
        at_check(at_visible("setup:export:android:android"), "the Android row that cannot find a JDK and SDK has a Set up button");
        at_check(action_labels("android") == std::vector<std::string>{"Install Android build tools"}, "...Install Android build tools");
        const std::string os = otherOs == "macos" ? "macOS" : (otherOs == "windows" ? "Windows" : "Linux");
        at_check(at_visible("setup:export:" + otherOs + ":players-" + otherOs), "the row that needs another OS's player has a Set up button");
        at_check(action_labels(otherOs) == std::vector<std::string>{"Download " + os + " player"}, "...Download " + os + " player");
        at_check(at_visible("setup:export:ios:cmake") && at_visible("setup:export:ios:xcode"), "the iOS row, ready, still offers CMake and Xcode");
        at_check((action_labels("ios") == std::vector<std::string>{"Install CMake", "Open App Store (Xcode)"}), "...Install CMake and Open App Store (Xcode)");
        at_check(!at_visible("setup:export:" + ownOs + ":players-" + ownOs), "a row that is ready has no download button");
        at_check(at_enabled("setup:export:android:android") && at_enabled("setup:export:ios:cmake"), "the Set up buttons can be pressed");
    });
    snap("editor_setup_export.png");

    // Pressing one runs the setup in the editor (here it can only fail, the autotest has no network) and shows its report.
    scroll_until("setup:export:" + otherOs + ":players-" + otherOs, 6, Vec2{700, 400}, 500);
    click("setup:export:" + otherOs + ":players-" + otherOs);
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return !setupJob_.running() && setupLast_.has_value(); };
    });
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return setupStatus_.has() && !setupStatus_.refreshing() && setupStatus_.status().host != "injected-autotest"; };
    });
    step(4, [this, otherOs] {
        at_check(showSetup_, "pressing a Set up button opens the Set Up window");
        at_check(setupLast_.has_value() && !setupLast_->ok && !setupLast_->cancelled,
                 "the setup ran (setup_install) and failed where the autotest cannot download: " + (setupLast_ ? setupLast_->error : std::string("no result")));
        at_check(setupLast_ && setupLast_->options.component == "players" && setupLast_->options.platforms == std::vector<std::string>{otherOs},
                 "...it was the player of that platform");
        at_check(setupStatus_.status().host != "injected-autotest", "when it finished the status was read again");
        bool rechecked = !exportStatus_.empty();
        for (const ExportStatus& st : exportStatus_) rechecked = rechecked && st.hint != "injected-autotest";
        at_check(rechecked, "...and so were the Export rows");
        at_check(at_visible("setup:copy-report"), "the window shows the report with Copy report");
    });
    snap("editor_setup_failed.png");
    step(2, [this] { showSetup_ = false; });

    // The license dialog, first with a license that cannot be loaded: the dialog says so and installs nothing.
    step(2, [this, inject_setup] {
        inject_setup();
        setupLicense_.reset();
        setupLast_.reset();
        showExport_ = true;
        exportFocus_ = true;
    });
    step(3, [] {});
    scroll_until("setup:export:android:android", -6, Vec2{700, 400}, 560);
    click("setup:export:android:android");
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return setupLicense_.state() == SetupLicenseLoad::State::Failed; };
    });
    step(4, [this] {
        at_check(setupLicenseOpen_ && at_visible("setup:license-retry"), "Install Android build tools opens the license dialog first; a license that cannot be loaded offers Try again");
        at_check(!at_visible("setup:license-accept") || !at_enabled("setup:license-accept"), "...and cannot be accepted");
        at_check(!setupJob_.running(), "...and nothing is installed meanwhile");
    });
    snap("editor_setup_license_failed.png");
    click("setup:license-decline");
    step(4, [this] {
        at_check(!setupLicenseOpen_ && !setupJob_.running() && !setupLast_.has_value(), "Decline closes the dialog and installs nothing");
    });

    // With the text: shown in full, "I accept" waits for the checkbox.
    step(2, [this] {
        SetupLicense lic;
        lic.id = "android-sdk-license";
        lic.title = "Android Software Development Kit License Agreement";
        lic.text = "Terms and Conditions\n\n";
        for (int i = 1; i <= 24; ++i)
            lic.text += std::to_string(i) + ". This is paragraph " + std::to_string(i) + " of the test license. It is long enough to wrap onto a second "
                        "line in the box, so the box has to scroll to show all of the text before anyone agrees to it.\n\n";
        lic.text += "The end of the license.";
        setupLicense_.set(SetupLicenseLoad::State::Ready, {lic});
    });
    click("setup:export:android:android");
    step(4, [this] {
        at_check(setupLicenseOpen_ && at_visible("setup:license-text"), "the license dialog shows the license text in a box of its own");
        at_check(at_visible("setup:license-accept") && !at_enabled("setup:license-accept"), "I accept is disabled until the checkbox is ticked");
        at_check(at_enabled("setup:license-check") && !setupLicenseTick_, "...the checkbox is there, not ticked");
        at_check(at_visible("setup:license-decline"), "...next to Decline");
    });
    snap("editor_setup_license.png");
    click("setup:license-check");
    step(3, [this] {
        at_check(setupLicenseTick_, "ticking the checkbox...");
        at_check(at_enabled("setup:license-accept"), "...enables I accept");
        at_check(!setupJob_.running(), "...but nothing is installed until it is pressed");
    });
    snap("editor_setup_license_ticked.png");
    click("setup:license-check");
    step(3, [this] {
        at_check(!setupLicenseTick_ && !at_enabled("setup:license-accept"), "unticking the checkbox disables I accept again");
    });
    click("setup:license-decline");
    step(4, [this] {
        at_check(!setupLicenseOpen_ && !setupJob_.running() && !setupLast_.has_value(), "Decline closes the dialog and installs nothing");
        showExport_ = false;
    });

    // The Platform settings window: a button on General, and the tabs offer what their row needs.
    step(2, [this, inject_setup] {
        inject_setup();
        open_platform_settings(SettingsTab::General);
    });
    step(4, [this] { at_check(at_visible("setup:open-general"), "Platform settings > General has a Set Up This Computer... button"); });
    scroll_until("setup:open-general", -6, Vec2{512, 320}, 560);  // at the end of the tab: below the fold on a small display
    click("setup:open-general");
    step(4, [this, inject_setup] {
        at_check(showSetup_, "...that opens the Set Up window");
        showSetup_ = false;
        // Opening the window read this computer again (a Linux runner has CMake and no Xcode to offer): back to the injected
        // status, which drops that read if it is still running.
        inject_setup();
        open_platform_settings(SettingsTab::Android);
    });
    step(4, [this] { at_check(at_visible("setup:tab:android:android"), "the Android tab offers Install Android build tools next to the JDK and SDK status"); });
    step(2, [this, otherOs] { open_platform_settings(*settings_tab_for_platform(otherOs)); });
    step(4, [this, otherOs] {
        at_check(at_visible("setup:tab:" + otherOs + ":players-" + otherOs), "the " + otherOs + " tab offers to download its player");
        open_platform_settings(SettingsTab::Ios);
    });
    step(4, [this] {
        at_check(at_visible("setup:tab:ios:cmake") && at_visible("setup:tab:ios:xcode"), "the iOS tab offers CMake and Xcode");
    });
    snap("editor_setup_ios_tab.png");
    step(2, [this] {
        request_close_platform_settings();
        platformCloseAsk_ = false;
        showPlatformSettings_ = false;
        exportChecked_ = -100;
        setupRefreshAgain_ = true;  // what the windows show is read from this computer again
    });
}

}  // namespace fa::editor
