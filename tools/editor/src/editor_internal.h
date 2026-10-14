// Editor state shared by all panels. One instance lives for the whole run_editor() call.
//
// THREADING: everything here runs on the main (UI/GPU) thread EXCEPT the AI agent
// thread (ai_panel.cpp). The agent never touches the engine directly: its command
// registry is a proxy whose handlers enqueue jobs into MainThreadQueue and block
// until the main thread has executed them (Editor::on_frame -> queue.pump()).
#pragma once

#include <array>
#include <atomic>
#include <cstdint>
#include <condition_variable>
#include <deque>
#include <functional>
#include <future>
#include <map>
#include <memory>
#include <optional>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#include "fa/ai/config.h"
#include "fa/ai/detect.h"
#include "fa/ai/session.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/editor/editor.h"
#include "fa/runtime/engine.h"
#include "fa/scene/bounds.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/tooling.h"
#include "ai_chat.h"
#include "ai_usage.h"
#include "editor_tools.h"
#include "imgui.h"
#include "imgui_stdlib.h"

struct sapp_event;

namespace fa::editor {

enum class PlayState { Edit, Playing, Paused };

// ------------------------------------------------------------------------------------------
// Thread-safe queue that moves command calls from the AI thread to the main thread.
class MainThreadQueue {
public:
    // Called from worker threads. Blocks until the main thread ran the command, the queue was
    // closed, or `cancel` became true.
    CommandResult call(const std::string& name, const Json& args, const std::atomic<bool>* cancel);
    // Main thread: runs every queued job (each through `run`). Returns how many ran.
    int pump(const std::function<CommandResult(const std::string&, const Json&)>& run);
    void close();   // fails pending and future calls (editor shutting down / project switch)
    void reopen();

private:
    struct Job {
        std::string name;
        Json args;
        std::shared_ptr<std::promise<CommandResult>> promise;
    };
    std::mutex mu_;
    std::deque<Job> jobs_;
    bool closed_ = false;
};

// ------------------------------------------------------------------------------------------
struct Toast {
    std::string text;
    int level = 0;  // 0 info, 1 warn, 2 error
    double expires = 0;
};

struct TextureEntry {
    std::uint32_t image = 0, view = 0;
    int w = 0, h = 0;
    bool failed = false;
};

// What the viewport selects, outlines and hit-tests for one entity. The geometry is the engine's own footprint of the
// entity's 2D visuals (fa/scene/bounds.h, shared with `entity.bounds()`), plus a marker for entities that draw nothing.
struct PickBounds {
    bool valid = false;
    bool screenSpace = false;            // the entity is picked on the screen (design pixels, y down), not in the world
    std::vector<VisualFootprint> parts;  // local-space boxes (y up) of its visuals, or one marker
    int layer = 0;                       // highest draw layer among the parts
};

// One part's outline in WORLD xy (world-space parts) or DESIGN pixels (screen-space parts): the box the part occupies after the
// entity's transform, and the silhouette points (differs from the box for a diamond).
struct PickOutline {
    bool screenSpace = false;
    bool hasHull = false;
    std::array<Vec2, 4> box{}, hull{};
};

// pick.cpp: pure functions over a World (no window, renderer or ImGui), so they can be tested headless.
PickBounds pick_bounds(const World& w, Entity e, const VisualMeasure& measure);
std::vector<PickOutline> pick_outlines(const World& w, Entity e, const PickBounds& b, Vec2 designSize);
Vec2 pick_origin(const World& w, Entity e, const PickBounds& b, Vec2 designSize);
// `point` is world xy for world-space entities and a design pixel for screen-space ones. On a hit, *layerOut gets the layer.
bool pick_hit(const World& w, Entity e, const PickBounds& b, Vec2 point, Vec2 designSize, int* layerOut = nullptr);

class Editor {
public:
    explicit Editor(EditorOptions options);
    ~Editor();

    // sokol callbacks
    void on_init();
    void on_frame(double dt);
    void on_cleanup();
    void on_event(const sapp_event* e);
    int run();

    // ---------------------------------------------------------------- project / scene
    bool open_project(const std::string& dir);      // deferred to the next frame start
    bool boot(const std::string& dir);              // immediate (tears down and rebuilds graphics)
    bool has_project() const { return engine_ != nullptr; }
    World& world() { return engine_->world(); }
    Engine& engine() { return *engine_; }
    const std::string& project_dir() const { return projectDir_; }
    const std::string& scene_path() const { return scenePath_; }
    bool open_scene(const std::string& path);
    void sync_scene_path();
    void install_command_overrides();
    bool save_scene_now();
    void reload_scene_from_disk(bool keepUndo = false);   // keepUndo: Ctrl+Z brings back what was on screen before
    void restore_scene(const Json& snapshot);

    // ---------------------------------------------------------------- play mode
    PlayState play_state() const { return play_; }
    void play();
    void pause();
    void step_once();
    void stop();

    // ---------------------------------------------------------------- selection & edits
    // The selection is what the user points at in the viewport for the AI; nothing edits it by hand.
    Entity selected();
    void select(Entity e);
    void select_id(const std::string& id) { selectedId_ = id; }
    const std::string& selected_id() const { return selectedId_; }
    // Records an undo snapshot (coalesced per key) and marks the scene dirty. Call BEFORE mutating.
    void begin_edit(const std::string& key);
    void mark_dirty() { dirty_ = true; }
    bool dirty() const { return dirty_; }
    void undo();
    void redo();
    size_t undo_depth() const { return undo_.size(); }
    size_t redo_depth() const { return redo_.size(); }

    // ---------------------------------------------------------------- UI helpers
    void notify(const std::string& text, int level = 0);
    void focus_window(const char* name) { pendingFocus_ = name; }
    void run_console_line(const std::string& line);
    // Commands typed in the Console or called by the AI go through these two hooks (editor_app.cpp):
    // command_edits_scene() is false for commands that only write FILES (prefab.save, scene.format, scene.import_ascii with `path`),
    // so they neither take an undo snapshot nor mark the scene dirty; after_command() reloads the scene when
    // scene.import_ascii rebuilt the scene file that is open (Ctrl+Z brings back what was on screen).
    bool command_edits_scene(const std::string& name, const Json& args) const;
    void after_command(const std::string& name, const Json& args, const CommandResult& result);
    const TextureEntry* texture_for(const std::string& path);
    VisualMeasure visual_measure();        // texture sizes and text layout for the engine's bounds code
    PickBounds bounds_of(Entity e);
    Entity pick_at(Vec2 designPos);
    bool primary_is_ortho();
    Vec2 image_size_of(const std::string& path);

    // ---------------------------------------------------------------- panels
    void build_ui();
    void draw_main_menu();
    void draw_toolbar();
    void draw_status_bar();
    void build_default_layout(unsigned dockId, ImVec2 size);
    void draw_viewport();
    void draw_console();
    void draw_ai_panel();
    void draw_ai_roles_popup(const ai::AiConfig& cfg, const std::vector<ai::ProviderStatus>& status);
    void draw_feedback_panel();
    void draw_audio_panel();
    void draw_project_dialog();
    void draw_validation_window();
    void draw_docs_window();
    void draw_toasts();

    // AI
    void ai_refresh_providers();
    void ai_start(const std::string& task);   // sends `task` (+ the pending pictures) in the active chat
    void ai_stop();                           // joins the agent thread, applies its last events, saves the chats
    void ai_drain_events();
    void ai_sync_chats();                     // the chat tabs belong to the open project: switch when it changed
    void ai_on_files_dropped();               // sokol file drop: images become pending attachments of the active chat
    void ai_attach_path(const std::string& path);
    void ai_add_pending(Result<ChatAttachment> attached);
    void ai_paste_image();                    // clipboard picture -> pending attachment (does nothing without one)
    std::shared_ptr<CommandRegistry> make_proxy_registry();
    MainThreadQueue& queue() { return queue_; }
    bool ai_running() const { return aiRunning_.load(); }
    const std::vector<ChatItem>& chat() const { return chat_.current().items; }  // transcript of the active chat

    // autotest
    void autotest_pre_frame();
    void autotest_post_frame(bool& wantShot);
    bool autotest_active() const { return autotest_; }

    // Kept public so panel .cpp files stay simple.
    EditorOptions options_;
    std::unique_ptr<Engine> engine_;
    std::string projectDir_;
    std::string projectName_;
    std::string scenePath_;
    std::string pendingOpen_;
    std::string bootError_;
    bool gfxUp_ = false;
    bool uiUp_ = false;
    bool dirty_ = false;
    PlayState play_ = PlayState::Edit;
    int stepPending_ = 0;
    Json playSnapshot_;
    std::string selectedId_;
    std::vector<Json> undo_, redo_;
    std::string lastEditKey_;
    double lastEditTime_ = -100.0;
    double time_ = 0.0;
    double fps_ = 60.0;
    std::uint64_t uiFrame_ = 0;
    int scriptErrors_ = 0;
    double scriptErrorsPolled_ = -10;
    std::string iniPath_;
    bool resetLayout_ = false;
    bool layoutBuilt_ = false;
    const char* pendingFocus_ = nullptr;

    // viewport (ImGui logical coordinates; sokol event coordinates / dpi match them)
    ImVec2 vpImageMin_{0, 0}, vpImageSize_{1, 1};
    bool vpHovered_ = false, vpFocused_ = false;
    bool vpMouseCaptured_[3] = {false, false, false};
    bool showColliders_ = true;
    bool showOverlay_ = true;
    float dpi_ = 1.0f;

    // panel visibility
    bool showViewport_ = true;
    bool showConsole_ = true, showAi_ = true, showFeedback_ = true, showAudio_ = false;
    bool showProjectDialog_ = false, showValidation_ = false, showDocs_ = false, showDemo_ = false;
    bool showQuitDialog_ = false, showReloadConfirm_ = false;
    std::string pendingScene_;  // open-scene request waiting for the unsaved-changes dialog

    // textures for ImGui (texture_for, viewport.cpp), and image sizes for the selection bounds
    std::unordered_map<std::string, TextureEntry> textures_;
    struct ImageSizeEntry { Vec2 size{32, 32}; std::int64_t mtime = 0; };
    std::unordered_map<std::string, ImageSizeEntry> imageSizes_;

    // console
    int consoleLevel_ = 2;  // index into {trace, debug, info, warn, error}
    std::string consoleFilter_;
    bool consoleAutoScroll_ = true;
    std::string consoleInput_;
    std::vector<std::string> consoleHistory_;
    int consoleHistoryPos_ = -1;
    bool consoleFocusInput_ = false;

    // validation / docs
    ValidationReport validation_;
    std::string docsText_, docsTitle_;

    // project dialog
    std::string dlgOpenPath_;
    std::string dlgNewName_ = "my-game";
    std::string dlgNewParent_;
    int dlgTemplate_ = 0;
    std::string dlgError_;
    std::vector<std::string> recentProjects_;
    std::vector<std::string> detectedProjects_;
    bool dlgScanned_ = false;

    // Audio panel (View > Audio): the live audio.log
    AudioLogState audioLog_;
    double audioPolled_ = -10;
    void poll_audio(bool force = false);

    // toasts
    std::vector<Toast> toasts_;

    // feedback panel
    Json feedbackDoc_;
    std::string feedbackError_;
    std::int64_t feedbackMtime_ = INT64_MIN;
    double feedbackPolled_ = -10;
    int fbStatus_ = 0, fbCategory_ = 0, fbSeverity_ = 0;
    std::string fbSelected_;
    int fbNewCategory_ = 0, fbNewSeverity_ = 1;
    std::string fbNewTitle_, fbNewMissing_, fbNewWorkaround_, fbNewSuggestion_, fbMessage_;

    // AI
    MainThreadQueue queue_;
    std::mutex aiMu_;
    ai::AiConfig aiConfig_;
    std::string aiConfigError_;
    std::vector<ai::ProviderStatus> aiStatus_;
    std::atomic<bool> aiDetected_{false};
    std::atomic<bool> aiDetecting_{false};
    std::thread aiDetectThread_;
    std::thread aiThread_;
    std::atomic<bool> aiRunning_{false};
    std::atomic<bool> aiCancel_{false};
    std::vector<ai::AgentEvent> aiPending_;  // produced by the agent thread, drained on the main thread
    std::optional<ai::SessionResult> aiResult_;
    AiChats chat_;                  // the conversations (tabs); the active one is chat_.current()
    std::string aiRunChat_;         // id of the chat the agent thread works for ("" = no run); set by ai_start, cleared on the result
    std::string aiRunProvider_;     // provider of that run (the plan limits belong to it)
    LimitsByProvider aiLimits_;     // last known plan windows, shared by every tab; kept in ~/.factoria/ai_limits.json
    bool aiLimitsLoaded_ = false;
    int aiTabForce_ = 0;            // frames left to force the active tab (a tab opened/closed by code)
    bool aiHistoryOpen_ = false;    // request to open the History popup this frame
    std::vector<ChatHistoryEntry> aiHistory_;
    std::string aiHistoryDelete_;   // History row waiting for the second click on its Delete
    bool aiRolesOpen_ = false;      // request to open the AI roles popup this frame
    std::map<std::string, ai::RoleConfig> aiRolesEdit_;  // the roles being edited in that popup
    std::shared_ptr<CommandRegistry> aiProxy_;
    ai::ProviderFactory aiFactory_;  // test hook: replaces the real providers (autotest mock)

    // autotest
    bool autotest_ = false;
    bool atWelcome_ = false;
    int atFrame_ = 0;
    std::string atOutDir_;
    std::string atTempProject_;
    std::vector<std::string> atFailures_;
    std::vector<std::string> atLog_;
    std::vector<std::string> atPendingShots_;
    std::thread atThread_;
    std::shared_ptr<CommandResult> atMarshalResult_;
    Vec3 atOriginalPos_{};
    std::uint64_t atStepFrame_ = 0;
    void at_check(bool cond, const std::string& what);
    void inject_mouse(int type, Vec2 logicalPos, int button = 0);   // button 0 = left, 1 = right (sapp_mousebutton)
    // Widgets the autotest clicks with injected mouse events: name -> centre in logical (ImGui) coordinates. Filled by
    // at_track() right after a widget is submitted, only when the autotest runs.
    std::map<std::string, Vec2> atWidgets_;
    std::map<std::string, std::uint64_t> atWidgetFrame_;   // uiFrame_ when the widget was last submitted
    void at_track(const std::string& name);
    Vec2 at_widget(const std::string& name);               // centre of a widget drawn in the last frames (fails the test otherwise)
    bool at_visible(const std::string& name) const;        // was the widget submitted in the last frame?
    // Second half of the autotest (autotest_tools.cpp): a script of steps, one per frame, each followed by a wait.
    struct AtStep {
        int wait = 1;
        std::function<void()> run;
    };
    std::deque<AtStep> atSteps_;
    int atStepAt_ = 0;
    std::vector<std::function<void()>> atPostFrame_;       // run once after the UI was drawn (swapchain read-back)
    Image atShotBefore_;
    std::uint64_t atAudioAfter_ = 0;
    std::size_t atAudioBase_ = 0;
    void at_build_tools_script();
    void at_run_steps(int frame);
    bool capture_window(Image& img);
    void inject_key(int type, int keyCode);
    Vec2 atMouse_{};
    size_t atUndoBeforeAi_ = 0;
    bool atWaitAi_ = false;
    std::vector<ai::ProviderStatus> atSavedStatus_;
    int atWaitCount_ = 0;
    void save_screenshot_now(const std::string& path);
};

// Helpers shared across panel files.
extern Editor* g_editor;
std::string lower_str(std::string s);
std::string home_dir();  // HOME, else USERPROFILE (Windows sets no HOME), else ""
bool contains_ci(const std::string& hay, const std::string& needle);
ImVec4 level_color(LogLevel l);

// folder_picker.cpp: the system's folder dialog, opened at `start` (blocks until it closes). "" when cancelled, or
// when there is no dialog (Linux without zenity or kdialog).
std::string pick_folder(const std::string& title, const std::string& start);
// Same for one existing file of the given kinds (`filterName` "Images", `extensions` {"png", "jpg"}, no dot).
std::string pick_file(const std::string& title, const std::string& start, const std::string& filterName,
                      const std::vector<std::string>& extensions);
// The picture on the system clipboard as PNG bytes; empty when there is none (or no tool to read it on Linux).
std::vector<std::uint8_t> clipboard_image_png();
void maximize_window();

}  // namespace fa::editor
