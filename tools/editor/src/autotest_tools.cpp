// Autotest, second half (FA_EDITOR_AUTOTEST=1): what is left of the editor's UI, driven through the REAL window.
//
// The editor has no manual editing tools (the AI edits), so this half covers the Audio panel (View > Audio), commands that rebuild
// the open scene file (the Console and the AI call them), picking and the selection outline against the real renderer, and bloom in
// the viewport. Widgets publish where they are (Editor::at_track); the script moves, presses and releases the injected mouse over
// them exactly as a person would. After each action it checks the effect on disk, in the world and in the editor state, and takes
// window screenshots. A script of small steps, one step per frame followed by a wait, so a step never races the UI: a click is
// move, press, release on different frames.
#include <cmath>
#include <filesystem>
#include <fstream>

#include "editor_internal.h"
#include "sokol_app.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

namespace stdfs = std::filesystem;

void write_file(const std::string& path, const std::string& bytes) {
    std::error_code ec;
    stdfs::create_directories(stdfs::path(path).parent_path(), ec);
    std::ofstream(path, std::ios::binary) << bytes;
}

std::string silence_wav() {  // 0.1 s of silence, 16-bit mono PCM
    const std::uint32_t n = 4410;
    std::string b;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char((v >> (8 * i)) & 0xff)); };
    auto u16 = [&](std::uint16_t v) { b.push_back(char(v & 0xff)); b.push_back(char(v >> 8)); };
    b += "RIFF"; u32(36 + n * 2); b += "WAVEfmt "; u32(16); u16(1); u16(1); u32(44100); u32(88200); u16(2); u16(16);
    b += "data"; u32(n * 2);
    b.append(std::size_t(n) * 2, '\0');
    return b;
}

// The scene the second half of the autotest works on. The first half runs on whatever the 2d-platformer template ships; from here on
// the checks must not depend on the template's entities, positions or levels, so the project's main scene is replaced by this fixture:
// a camera at the origin looking at 1280 x 720 world units, a few shapes, a player, three coins. No scripts, no physics, no tags that
// scene.import_ascii would treat as its own (`tilemap:<id>`), so importing a level into it cannot remove any of these entities.
const char* kFixtureScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "name": "Main Camera",
      "components": { "Transform": { "position": [0, 0, 0] }, "Camera": { "clearColor": [0.35, 0.55, 0.85, 1], "primary": true } } },
    { "id": "ground", "name": "Ground",
      "components": { "Transform": { "position": [0, -320, 0] }, "Shape2D": { "size": [3000, 80], "color": [0.25, 0.6, 0.3, 1] } } },
    { "id": "platform_1", "name": "Platform 1",
      "components": { "Transform": { "position": [250, -200, 0] }, "Shape2D": { "size": [220, 24], "color": [0.55, 0.4, 0.25, 1] } } },
    { "id": "player", "name": "Player", "tags": ["player"],
      "components": { "Transform": { "position": [-300, -250, 0] }, "Shape2D": { "size": [32, 48], "color": [0.95, 0.35, 0.3, 1], "layer": 2 } } },
    { "id": "coin_1", "name": "Coin", "tags": ["coin"],
      "components": { "Transform": { "position": [-100, -266, 0] }, "Shape2D": { "shape": "circle", "size": [24, 24], "color": [1, 0.85, 0.2, 1], "layer": 1 } } },
    { "id": "coin_2", "name": "Coin", "tags": ["coin"],
      "components": { "Transform": { "position": [250, -160, 0] }, "Shape2D": { "shape": "circle", "size": [24, 24], "color": [1, 0.85, 0.2, 1], "layer": 1 } } },
    { "id": "coin_3", "name": "Coin", "tags": ["coin"],
      "components": { "Transform": { "position": [420, -266, 0] }, "Shape2D": { "shape": "circle", "size": [24, 24], "color": [1, 0.85, 0.2, 1], "layer": 1 } } }
  ]
})";

}  // namespace

bool Editor::capture_window(Image& img) {
    const int w = sapp_width(), h = sapp_height();
    img.width = w;
    img.height = h;
    img.rgba.resize(size_t(w) * size_t(h) * 4);
    if (!ui::read_backbuffer(w, h, img.rgba.data())) return false;
    for (size_t i = 3; i < img.rgba.size(); i += 4) img.rgba[i] = 255;
    return true;
}

void Editor::at_run_steps(int frame) {
    if (atSteps_.empty() || frame < atStepAt_) return;
    AtStep s = std::move(atSteps_.front());
    atSteps_.pop_front();
    s.run();
    atStepAt_ = frame + s.wait;
}

void Editor::at_build_tools_script() {
    using Fn = std::function<void()>;
    auto step = [this](int wait, Fn fn) { atSteps_.push_back(AtStep{wait, std::move(fn)}); };
    // A click is three steps on different frames: move onto the widget, press, release.
    auto click = [this, &step](const std::string& name) {
        step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
        step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
        step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
    };
    // A screenshot: first the mouse is parked on the status bar (no hover tooltip) and the toasts are cleared, three frames
    // later the window is captured (after the UI of that frame was drawn).
    auto snap = [this, &step](const std::string& file) {
        step(3, [this] {
            toasts_.clear();
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{900, 884});
        });
        step(2, [this, file] { atPendingShots_.push_back(atOutDir_ + "/" + file); });
    };
    auto project_file = [this](const std::string& rel) { return projectDir_ + "/" + rel; };

    // ------------------------------------------------------------------------------------------------------ setup
    step(2, [this, project_file] {
        stop();
        select_id("");
        write_file(project_file(scenePath_), kFixtureScene);
        reload_scene_from_disk();  // the fixture is the open scene, clean (no unsaved changes, no undo history)
        write_file(project_file("assets/blip.wav"), silence_wav());
        focus_window("Viewport");
    });

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
    step(2, [this, project_file] {  // back to the clean fixture for the checks below
        write_file(project_file(scenePath_), kFixtureScene);
        reload_scene_from_disk();
        at_check(!dirty() && world().find_by_id("map3").is_null(), "the fixture is the open scene again, clean");
    });

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

    // ------------------------------------------------------------------------------------------------------ done
    step(2, [this] {
        select_id("");
        Json report = Json::object({{"failures", atFailures_}, {"log", atLog_}, {"frames", atFrame_}});
        (void)save_json_file(atOutDir_ + "/autotest_result.json", report);
        FA_INFO("autotest", "finished: {} failure(s)", atFailures_.size());
        sapp_request_quit();
    });
}

}  // namespace fa::editor
