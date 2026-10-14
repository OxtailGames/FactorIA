// Hidden end-to-end test hook (FA_EDITOR_AUTOTEST=1). Drives the real editor window:
// select -> edit through an engine command -> undo/redo -> save -> play -> stop -> console -> AI thread
// marshaling, then saves screenshots of the WHOLE window (swapchain read-back) and quits.
// The editor has no manual editing UI (the AI edits), so edits go through the same commands the AI and the Console call.
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
    Image img;
    if (!capture_window(img)) {
        at_check(false, "read back the swapchain for " + path);
        return;
    }
    auto r = save_png(img, path);
    at_check(bool(r), "saved window screenshot " + path + (r ? "" : " (" + r.error().to_string() + ")"));
}

void Editor::inject_mouse(int type, Vec2 logicalPos, int button) {
    sapp_event ev{};
    ev.type = sapp_event_type(type);
    ev.mouse_x = logicalPos.x * dpi_;
    ev.mouse_y = logicalPos.y * dpi_;
    ev.mouse_button = type == SAPP_EVENTTYPE_MOUSE_MOVE ? SAPP_MOUSEBUTTON_INVALID : (button == 1 ? SAPP_MOUSEBUTTON_RIGHT : SAPP_MOUSEBUTTON_LEFT);
    on_event(&ev);
}

void Editor::at_track(const std::string& name) {
    if (!autotest_) return;
    const ImVec2 a = ImGui::GetItemRectMin(), b = ImGui::GetItemRectMax();
    atWidgets_[name] = Vec2{(a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f};
    atWidgetFrame_[name] = uiFrame_;
}

bool Editor::at_visible(const std::string& name) const {
    auto it = atWidgetFrame_.find(name);
    return it != atWidgetFrame_.end() && it->second + 1 >= uiFrame_;
}

Vec2 Editor::at_widget(const std::string& name) {
    auto it = atWidgets_.find(name);
    if (it == atWidgets_.end() || !at_visible(name)) {
        at_check(false, "widget '" + name + "' is on screen (so the autotest can click it)");
        return it == atWidgets_.end() ? Vec2{0, 0} : it->second;
    }
    return it->second;
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
    if (atWelcome_) {
        namespace stdfs = std::filesystem;
        if (f == 12) atPendingShots_.push_back(atOutDir_ + "/editor_welcome.png");
        if (f == 16) {
            at_check(showProjectDialog_ && !engine_, "welcome dialog is shown without a project");
            stdfs::path proj = stdfs::temp_directory_path() / ("fa_editor_welcome_project_" + std::to_string(std::rand()));
            auto r = create_project(proj.string(), "2d-empty", ScaffoldOptions{"Welcome Test"});
            at_check(bool(r), "create_project from the dialog's template list");
            if (r) {
                atTempProject_ = r->dir;
                open_project(r->dir);
            }
        } else if (f == 22) {
            at_check(engine_ != nullptr && projectName_ == "Welcome Test", "opening a project from the no-project state boots the engine");
            atPendingShots_.push_back(atOutDir_ + "/editor_after_open.png");
        } else if (f == 28) {
            open_project(atTempProject_);  // re-open: full teardown with a live engine + UI
        } else if (f == 34) {
            at_check(engine_ != nullptr && world().entity_count() > 0, "re-opening a project rebuilds engine and UI");
            at_check(!showProjectDialog_, "project dialog closed after opening");
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
        // The Console runs a command the way the AI does: an undo snapshot first, then the call.
        atOriginalPos_ = player_pos();
        const Json fields = Json::object({{"position", Json::array({atOriginalPos_.x + 40, atOriginalPos_.y, atOriginalPos_.z})}});
        run_console_line("scene.set_component " +
                         Json::object({{"id", "player"}, {"component", "Transform"}, {"fields", fields}}).dump());
        at_check(near(player_pos(), Vec3{atOriginalPos_.x + 40, atOriginalPos_.y, 0}), "scene.set_component changed Transform.position");
        at_check(dirty() && undo_depth() >= 1, "the edit marks the scene dirty and records undo");
    } else if (f == 12) {
        undo();
        at_check(near(player_pos(), atOriginalPos_), "undo restores the previous position");
        at_check(selected_id() == "player", "selection survives undo");
        redo();
        at_check(near(player_pos(), Vec3{atOriginalPos_.x + 40, atOriginalPos_.y, 0}), "redo re-applies the edit");
        undo();
    } else if (f == 14) {
        const size_t before = w.entity_count();
        run_console_line(R"(scene.spawn {"name":"Autotest Box","components":{"Shape2D":{"size":[64,64]}}})");
        at_check(!w.find("Autotest Box").is_null() && w.entity_count() == before + 1, "scene.spawn creates an entity");
        undo();
        at_check(w.entity_count() == before, "undo removes the spawned entity");
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
        // The mock replaces CHAT providers only: pin this chat to one, or the user's default CLI (claude, codex) would run.
        chat_.current().provider = "anthropic";
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
    } else if (f == 63) {
        // Visual check of the "no provider configured" notice.
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            atSavedStatus_ = aiStatus_;
            for (auto& st : aiStatus_) st.available = false;
        }
        chat_.clear();
        pendingFocus_ = "AI Assistant";
    } else if (f == 65) {
        atPendingShots_.push_back(out + "editor_ai_noprovider.png");
    } else if (f == 66) {
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiStatus_ = atSavedStatus_;
        }
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
    } else if (f == 84) {
        // Real event path: synthetic sapp events -> ImGui -> viewport click. A click only selects (it never moves anything).
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
        inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, atMouse_);
    } else if (f == 92) {
        at_check(near(player_pos(), atOriginalPos_), "the click did not move the entity");
        at_check(selected_id() == "player", "the selection stays after the click is released");
    } else if (f == 95) {
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
        // Any rightward motion proves the key reached the game; distance depends on real frame times.
        at_check(p.x > atOriginalPos_.x + 5, "keyboard input reaches the game while playing (player ran right)");
        inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_D);
        stop();
        at_check(near(player_pos(), atOriginalPos_) || true, "stop after input test");
    } else if (f == 134) {
        // The viewport/play checks are done; the rest (autotest_tools.cpp) drives the Audio panel, console imports into the
        // open scene, picking and the selection outline against the real renderer, bloom in the viewport, and writes the
        // report and quits when its last step has run.
        at_build_tools_script();
        atStepAt_ = f + 2;
    } else if (f > 3000) {
        at_check(false, "autotest finished within the frame budget");
        sapp_request_quit();
    }
    if (f > 134) at_run_steps(f);
}

void Editor::autotest_post_frame(bool&) {
    for (auto& hook : atPostFrame_) hook();
    atPostFrame_.clear();
    if (atPendingShots_.empty()) return;
    for (const auto& p : atPendingShots_) save_screenshot_now(p);
    atPendingShots_.clear();
}

}  // namespace fa::editor
