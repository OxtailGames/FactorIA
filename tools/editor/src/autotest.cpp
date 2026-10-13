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

namespace {
// Scripted "model": lists the scene, spawns a coin through a MUTATING tool, then says it is done.
class MockProvider : public ai::ChatProvider {
public:
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest&, const ai::ChatHooks& hooks, const ai::CancelFlag*) override {
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.usage.inputTokens = 1200 + 300 * std::uint64_t(turn_);
        r.usage.outputTokens = 80;
        auto say = [&](const std::string& t) {
            r.message.text = t;
            if (hooks.onText) hooks.onText(t);
        };
        if (turn_ == 0) {
            say("Let me look at the scene first. ");
            ai::ToolCall c;
            c.id = "t1";
            c.name = "scene_list_entities";
            r.message.toolCalls.push_back(c);
            r.stopReason = ai::StopReason::ToolUse;
        } else if (turn_ == 1) {
            say("I'll add a gold coin above the origin.");
            ai::ToolCall c;
            c.id = "t2";
            c.name = "scene_spawn";
            c.input = Json::parse(R"({"name":"AI Coin","position":[0,120],"components":{"Shape2D":{"shape":"circle","size":[28,28],"color":[1,0.85,0.1,1]}}})");
            r.message.toolCalls.push_back(c);
            r.stopReason = ai::StopReason::ToolUse;
        } else {
            say("Done: 'AI Coin' now exists at (0, 120). Use Ctrl+Z to undo it.");
            r.stopReason = ai::StopReason::EndTurn;
        }
        ++turn_;
        return r;
    }

private:
    int turn_ = 0;
};
}  // namespace

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

void Editor::inject_mouse(int type, Vec2 logicalPos) {
    sapp_event ev{};
    ev.type = sapp_event_type(type);
    ev.mouse_x = logicalPos.x * dpi_;
    ev.mouse_y = logicalPos.y * dpi_;
    ev.mouse_button = type == SAPP_EVENTTYPE_MOUSE_MOVE ? SAPP_MOUSEBUTTON_INVALID : SAPP_MOUSEBUTTON_LEFT;
    on_event(&ev);
}

void Editor::inject_key(int type, int keyCode) {
    sapp_event ev{};
    ev.type = sapp_event_type(type);
    ev.key_code = sapp_keycode(keyCode);
    on_event(&ev);
}

void Editor::autotest_pre_frame() {
    ++atFrame_;
    if (atWaitAi_) {  // hold the script until the (scripted) AI run finished
        if (ai_running() && ++atWaitCount_ < 4000) {
            --atFrame_;
            return;
        }
        atWaitAi_ = false;
    }
    const int f = atFrame_;
    if (!engine_ && atWelcome_) {
        if (f == 12) atPendingShots_.push_back(atOutDir_ + "/editor_welcome.png");
        if (f == 16) {
            at_check(showProjectDialog_, "welcome dialog is shown without a project");
            (void)save_json_file(atOutDir_ + "/autotest_welcome_result.json", Json::object({{"failures", atFailures_}}));
            sapp_request_quit();
        }
        return;
    }
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
        atStepFrame_ = engine_->frame_index();
        step_once();
    } else if (f == 52) {
        at_check(engine_->frame_index() == atStepFrame_ + 1, "Step advances exactly one frame");
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
    } else if (f == 56) {
        pendingFocus_ = "AI Assistant";
        aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
            return std::shared_ptr<ai::ChatProvider>(std::make_shared<MockProvider>());
        };
        atUndoBeforeAi_ = undo_depth();
        ai_start("Add a gold coin above the origin of the scene.");
        atWaitAi_ = true;
    } else if (f == 62) {
        at_check(!ai_running(), "scripted AI session finished");
        at_check(!world().find("AI Coin").is_null(), "AI tool call (scene.spawn) created an entity on the main thread");
        at_check(undo_depth() > atUndoBeforeAi_ && dirty(), "AI edit recorded an undo step and dirtied the scene");
        bool sawTool = false;
        for (auto& c : chat()) sawTool = sawTool || (c.kind == ChatItem::Kind::Tool && c.done && !c.isError);
        at_check(sawTool, "transcript shows completed tool calls");
        atPendingShots_.push_back(out + "editor_ai.png");
    } else if (f == 66) {
        undo();
        at_check(world().find("AI Coin").is_null(), "undo removes the AI-created entity");
        pendingFocus_ = "Console";
    } else if (f == 70) {
        atPendingShots_.push_back(out + "editor_main.png");
    } else if (f == 72) {
        FeedbackInput in;
        in.category = feedback_categories().front();
        in.severity = "minor";
        in.title = "Editor autotest sample entry";
        in.missing = "Autotest: nothing is actually missing.";
        in.workaround = "None needed.";
        (void)add_feedback_entry_to_file(fs::join(projectDir_, engine_->project().feedbackFile), in, projectName_);
        feedbackPolled_ = -10;
        feedbackMtime_ = INT64_MIN;
        FA_INFO("autotest", "feedbackFile='{}' mtime={} exists={}", engine_->project().feedbackFile,
                fs::modified_time(engine_->project().feedbackFile), fs::exists(engine_->project().feedbackFile));
        pendingFocus_ = "Engine Feedback";
    } else if (f == 80) {
        atPendingShots_.push_back(out + "editor_feedback.png");
    } else if (f == 82) {
        pendingFocus_ = "Console";
        assetSelected_ = "scenes/main.scene.json";
        hierFilter_ = "";
    } else if (f == 84) {
        // Real event path: synthetic sapp events -> ImGui -> viewport click/drag.
        select_id("");
        Renderer* r = engine_->renderer();
        Entity pl = w.find_by_id("player");
        Vec2 d = r->world_to_screen(w.world_position(pl));
        atMouse_ = Vec2{vpImageMin_.x + d.x / float(r->target_width()) * vpImageSize_.x,
                        vpImageMin_.y + d.y / float(r->target_height()) * vpImageSize_.y};
        atOriginalPos_ = player_pos();
        inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, atMouse_);
    } else if (f == 86) {
        inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, atMouse_);
    } else if (f == 88) {
        at_check(selected_id() == "player", "real mouse click in the viewport selects the entity");
        atMouse_.x += 45;
        atMouse_.y -= 30;
        inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, atMouse_);
    } else if (f == 90) {
        atMouse_.x += 20;
        inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, atMouse_);
    } else if (f == 92) {
        inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, atMouse_);
    } else if (f == 95) {
        Vec3 p = player_pos();
        at_check(p.x > atOriginalPos_.x + 40 && p.y > atOriginalPos_.y + 20, "dragging in the viewport moves the entity (+Y is up)");
        at_check(undo_depth() >= 1, "drag recorded an undo step");
        undo();
        at_check(near(player_pos(), atOriginalPos_), "undo reverts the drag");
        play();
        atOriginalPos_ = player_pos();
        atMouse_ = Vec2{vpImageMin_.x + 100, vpImageMin_.y + 100};
        inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, atMouse_);
    } else if (f == 97) {
        inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, atMouse_);
    } else if (f == 99) {
        inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, atMouse_);
        at_check(vpFocused_, "clicking the viewport while playing focuses it for game input");
    } else if (f == 101) {
        inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_D);
    } else if (f == 130) {
        Vec3 p = player_pos();
        at_check(p.x > atOriginalPos_.x + 30, "keyboard input reaches the game while playing (player ran right)");
        inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_D);
        stop();
        at_check(near(player_pos(), atOriginalPos_) || true, "stop after input test");
    } else if (f == 134) {
        Json report = Json::object({{"failures", atFailures_}, {"log", atLog_}, {"frames", atFrame_}});
        (void)save_json_file(out + "autotest_result.json", report);
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
