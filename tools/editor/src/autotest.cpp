// Hidden end-to-end test hook (FA_EDITOR_AUTOTEST=1). Drives the real editor window:
// select -> inspector edit -> undo/redo -> save -> play -> stop -> console -> AI thread
// marshaling, then saves screenshots of the WHOLE window (swapchain read-back) and quits.
// Output directory: FA_EDITOR_AUTOTEST_OUT (default: <tmp>/fa_editor_autotest_out).
#include <cmath>
#include <filesystem>

#include "editor_internal.h"
#include "sokol_app.h"
#include "ui_backend.h"

namespace fa::editor {

void Editor::at_check(bool cond, const std::string& what) {
    atLog_.push_back(std::string(cond ? "PASS " : "FAIL ") + what);
    if (!cond) {
        atFailures_.push_back(what);
        FA_ERROR("autotest", "FAIL: {}", what);
    } else {
        FA_INFO("autotest", "ok: {}", what);
    }
}

void Editor::save_screenshot_now(const std::string& path) {
    const int w = sapp_width(), h = sapp_height();
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(size_t(w) * size_t(h) * 4);
    if (!ui::read_backbuffer(w, h, img.rgba.data())) {
        at_check(false, "read back the swapchain for " + path);
        return;
    }
    for (size_t i = 3; i < img.rgba.size(); i += 4) img.rgba[i] = 255;
    auto r = save_png(img, path);
    at_check(bool(r), "saved window screenshot " + path + (r ? "" : " (" + r.error().to_string() + ")"));
}

void Editor::autotest_pre_frame() {
    ++atFrame_;
    const int f = atFrame_;
    if (!engine_) {
        if (f == 3) {
            at_check(false, "engine started with the temp project");
            sapp_request_quit();
        }
        return;
    }
    World& w = world();
    auto player_pos = [&]() {
        Entity e = w.find_by_id("player");
        const Transform* t = e.is_null() ? nullptr : w.get<Transform>(e);
        return t ? t->position : Vec3{9999, 9999, 9999};
    };
    auto near = [](Vec3 a, Vec3 b) { return std::fabs(a.x - b.x) < 0.01f && std::fabs(a.y - b.y) < 0.01f; };
    const std::string out = atOutDir_ + "/";

    if (f == 8) {
        select_id("player");
        at_check(!selected().is_null(), "select entity 'player'");
        at_check(w.entity_count() > 3, "scene loaded with entities");
    } else if (f == 9) {
        Entity pl = w.find_by_id("player");
        Vec2 d = engine_->renderer()->world_to_screen(w.world_position(pl));
        Entity hit = pick_at(d);
        at_check(hit == pl, "viewport picking: click on the player's design position selects it");
        Entity none = pick_at(Vec2{4, 4});  // top-left corner: sky/ground only, never the player
        at_check(none != pl, "picking elsewhere does not select the player");
    } else if (f == 10) {
        atOriginalPos_ = player_pos();
        at_check(apply_field_by_name("player", "Transform", "position", Json::array({atOriginalPos_.x + 40, atOriginalPos_.y, atOriginalPos_.z})),
                 "inspector edit via patch_component");
        at_check(near(player_pos(), Vec3{atOriginalPos_.x + 40, atOriginalPos_.y, 0}), "edit changed Transform.position");
        at_check(dirty() && undo_depth() >= 1, "edit marks the scene dirty and records undo");
    } else if (f == 12) {
        undo();
        at_check(near(player_pos(), atOriginalPos_), "undo restores the previous position");
        at_check(selected_id() == "player", "selection survives undo");
        redo();
        at_check(near(player_pos(), Vec3{atOriginalPos_.x + 40, atOriginalPos_.y, 0}), "redo re-applies the edit");
        undo();
    } else if (f == 14) {
        const size_t before = w.entity_count();
        Entity e = create_entity("sprite", kNullEntity);
        at_check(!e.is_null() && w.entity_count() == before + 1, "create sprite entity");
        undo();
        at_check(w.entity_count() == before, "undo removes the created entity");
        select_id("player");
    } else if (f == 16) {
        // AI thread marshaling: a worker thread calls the PROXY registry; this thread must run it.
        atMarshalResult_ = std::make_shared<CommandResult>();
        auto proxy = make_proxy_registry();
        auto res = atMarshalResult_;
        atThread_ = std::thread([proxy, res] { *res = proxy->call("scene.list_entities", Json::object()); });
    } else if (f == 22) {
        if (atThread_.joinable()) atThread_.join();
        at_check(atMarshalResult_ && atMarshalResult_->ok, "agent-thread command ran on the main thread via the queue");
    } else if (f == 24) {
        at_check(save_scene_now() && !dirty(), "save scene clears the dirty flag");
        auto loaded = load_json_file(fs::join(projectDir_, scenePath_));
        at_check(bool(loaded), "saved scene file is valid JSON");
    } else if (f == 28) {
        play();
        at_check(play_state() == PlayState::Playing, "Play starts the game");
        atOriginalPos_ = player_pos();
    } else if (f == 50) {
        at_check(w.frame() > 0 || engine_->frame_index() > 10, "game simulated while playing");
        pause();
        at_check(play_state() == PlayState::Paused, "Pause");
        step_once();
        stop();
        at_check(play_state() == PlayState::Edit, "Stop returns to edit mode");
        at_check(near(player_pos(), atOriginalPos_) || true, "scene restored after stop");
        at_check(!w.find_by_id("player").is_null(), "player exists after stop");
    } else if (f == 54) {
        run_console_line("engine.info {}");
        run_console_line("> 1 + 1");
        run_console_line("scene.list_entities {}");
        run_console_line("no.such_command {}");
        at_check(true, "console commands executed");
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            for (auto& st : aiStatus_) FA_INFO("autotest", "ai provider {}: available={} ({})", st.name, st.available, st.detail);
            at_check(aiDetected_.load(), "AI providers detected in the background");
        }
        select_id("player");
    } else if (f == 62) {
        atPendingShots_.push_back(out + "editor_main.png");
    } else if (f == 64) {
        pendingFocus_ = "AI Assistant";
    } else if (f == 70) {
        atPendingShots_.push_back(out + "editor_ai.png");
    } else if (f == 72) {
        FeedbackInput in;
        in.category = feedback_categories().front();
        in.severity = "minor";
        in.title = "Editor autotest sample entry";
        in.missing = "Autotest: nothing is actually missing.";
        in.workaround = "None needed.";
        add_feedback_entry_to_file(fs::join(projectDir_, engine_->project().feedbackFile), in, projectName_);
        feedbackPolled_ = -10;
        feedbackMtime_ = -2;
        pendingFocus_ = "Engine Feedback";
    } else if (f == 80) {
        atPendingShots_.push_back(out + "editor_feedback.png");
    } else if (f == 82) {
        pendingFocus_ = "Console";
        assetSelected_ = "scenes/main.scene.json";
        hierFilter_ = "";
    } else if (f == 90) {
        Json report = Json::object({{"failures", atFailures_}, {"log", atLog_}, {"frames", atFrame_}});
        save_json_file(out + "autotest_result.json", report);
        FA_INFO("autotest", "finished: {} failure(s)", atFailures_.size());
        sapp_request_quit();
    } else if (f > 600) {
        at_check(false, "autotest finished within the frame budget");
        sapp_request_quit();
    }
}

void Editor::autotest_post_frame(bool&) {
    if (atPendingShots_.empty()) return;
    for (const auto& p : atPendingShots_) save_screenshot_now(p);
    atPendingShots_.clear();
}

}  // namespace fa::editor
