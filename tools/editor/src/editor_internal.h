// Editor state shared by all panels. One instance lives for the whole run_editor() call.
//
// THREADING: everything here runs on the main (UI/GPU) thread EXCEPT the AI agent
// thread and the MCP endpoint's connection threads (ai_panel.cpp). Neither touches
// the engine directly: the command registry they use is a proxy whose handlers
// enqueue jobs into MainThreadQueue and block until the main thread has executed
// them (Editor::on_frame -> queue.pump()).
#pragma once

#include <algorithm>
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
#include <set>
#include <string>
#include <string_view>
#include <thread>
#include <unordered_map>
#include <vector>

#include "fa/ai/config.h"
#include "fa/ai/detect.h"
#include "fa/ai/provider.h"
#include "fa/ai/session.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/editor/editor.h"
#include "fa/editor/update.h"
#include "fa/mcp/http_server.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/play_session.h"
#include "fa/scene/bounds.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/export.h"  // executable_dir: where the update goes
#include "fa/tooling/tooling.h"
#include "ai_chat.h"
#include "ai_usage.h"
#include "editor_tools.h"
#include "export_job.h"
#include "imgui.h"
#include "imgui_stdlib.h"
#include "platform_settings.h"
#include "play_recorder.h"
#include "setup_job.h"

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
    // Main thread: runs queued jobs (each through `run`) until `budgetMs` is used up (at least one job runs; the rest
    // stay queued for the next frame so the UI keeps updating). Returns how many ran. `run` may call take_current() and
    // return nullopt: it then owns the reply and must fulfil the promise later (sliced long commands).
    int pump(const std::function<std::optional<CommandResult>(const std::string&, const Json&)>& run, double budgetMs = 1e9);
    // Inside `run`: takes over the promise of the job being run.
    std::shared_ptr<std::promise<CommandResult>> take_current() { return std::move(current_); }
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
    std::shared_ptr<std::promise<CommandResult>> current_;
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
    void save_recent_projects();                    // ~/.factoria/editor_recent.json (not in the autotest)
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

    // ---------------------------------------------------------------- play sessions (play_session.cpp)
    // Play .. Stop is recorded (input, frame times, warnings/errors, F9 marks) and written to .factoria/sessions/<name>/ at Stop.
    void session_begin();
    void session_end();
    void session_frame(double dt, std::uint64_t frameBefore);  // after Engine::frame while Playing
    void mark_problem();                                       // F9: pause, screenshot, ask for a note
    void mark_finish(bool save);
    void draw_mark_popup();
    void ai_attach_last_session();                             // summary into the message + mark pictures

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
    void set_window_title(const std::string& title);  // the OS window's title (editor_window_title); windowTitle_ keeps it
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
    // AI panel text: the right-click menu of the InputText just submitted on `text` (Cut/Copy/Paste/Select all), and a
    // transcript message as a selectable read-only box (ai_panel.cpp)
    void text_menu(const std::string& text, bool readOnly);
    void message_text(const char* id, std::string& text, const ImVec4* color = nullptr);
    void draw_validation_window();
    void draw_docs_window();
    void draw_toasts();
    void draw_update_popup();  // dialogs.cpp

    // Export window (export_panel.cpp): one button per platform. Each row is checked with fa::plan_export and a button
    // runs fa::export_project on a worker thread (export_job.h); the window shows the report it returns.
    void open_export_window();
    void draw_export_window();
    void poll_export();             // every frame, window open or not: takes a finished export's report
    void refresh_export_status();   // plan_export for every platform
    void reset_export_state();      // project switch: waits for a running export, forgets settings and report

    // Platform settings window (platform_settings_panel.cpp; File > Platform Settings..., the Export window's Settings...
    // buttons): the game icon and what each platform's export needs, as a working copy that Save writes with
    // fa::save_export_settings (platform_settings.h has the logic).
    void open_platform_settings(SettingsTab tab = SettingsTab::General);
    void draw_platform_settings_window();
    void poll_platform_settings();          // every frame: factoria.json changed on disk, icon pictures, a keystore being created
    void reset_platform_settings_state();   // project switch: forgets the working copy
    void request_close_platform_settings(); // closes now, or asks first when there are unsaved changes
    void set_android_format(const std::string& format);  // the Export window's format combo: saves export.android.format
    // A project picture scaled down for a preview (<project>/<relPath>, at most 256 px a side), loaded again when the file
    // changes; nullptr when it cannot be read.
    const TextureEntry* icon_preview(const std::string& relPath);

    // Set Up This Computer window (setup_panel.cpp; File > Set Up This Computer..., the "Set up" buttons of the Export and
    // Platform settings windows): the four components fa::setup_status looks at and fa::setup_install on a worker thread
    // (setup_job.h has the logic). Nothing is installed without a click; the Android SDK license is shown first.
    void open_setup_window();
    void draw_setup_window();
    void draw_setup_license_dialog();   // the modal that shows the Android SDK license before its install
    void poll_setup();                  // every frame: takes a finished install, status and license text in; keeps the status fresh
    // Runs `action` (the Android SDK license dialog first when the license is not accepted yet) and shows the Set Up window.
    void request_setup(const SetupAction& action);
    // The "Set up" buttons of `platform`'s row (Export window, Platform settings tabs); idPrefix names them for the autotest.
    // `explain`: say why the row is not ready above them (the tabs do not show the row's own error).
    void draw_setup_buttons(const std::string& platform, const char* idPrefix, bool explain = false);
    SetupContext make_setup_context();  // the real downloader and process runner, the editor's shared Android listing cache
    void start_setup_install(const SetupAction& action, bool acceptLicenses);

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
    bool ai_blocks_play();  // in edit mode while the assistant works: true (and says why), Play / Step must wait
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
    struct PlayRun {
        bool active = false;
        PlaySession session;
        PlayRecorder rec;
        std::vector<double> frameMs;
        std::uint64_t startFrame = 0, logSeq = 0;
        bool skipNext = true;  // the first frame after Play / Resume is not a frame time (scene restore, popup)
    } run_;
    bool markOpen_ = false, markFocus_ = false;
    std::string markNote_;
    PlayMark markPending_;
    std::string playNotice_;  // offered in the AI panel after Stop when the session has marks or errors ("" = none)
    int stepPending_ = 0;
    // A long AI command (game.step with many frames, project.test) run one slice per UI frame; returns true when done.
    std::function<bool()> slicedJob_;
    std::optional<CommandResult> run_queued(const std::string& name, const Json& args);
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
    bool vpFocusNext_ = false;  // focus the Viewport window on its next draw (set when Play starts)
    bool vpMouseCaptured_[3] = {false, false, false};
    bool showColliders_ = true;
    bool showOverlay_ = true;
    float dpi_ = 1.0f;

    // panel visibility
    bool showViewport_ = true;
    bool showConsole_ = true, showAi_ = true, showFeedback_ = true, showAudio_ = false;
    bool showProjectDialog_ = false, showValidation_ = false, showDocs_ = false, showDemo_ = false;
    bool showQuitDialog_ = false, showReloadConfirm_ = false;
    // Engine update (fa/editor/update.h): checked once when the editor opens. While a newer release is offered the
    // modal popup blocks the editor until Update or Not now; Update installs it, then the editor quits and reopens.
    enum class UpdateStage { Idle, Offer, Installing, Failed, Installed };
    std::atomic<UpdateStage> updateStage_{UpdateStage::Idle};
    UpdateInfo update_;           // written by updateThread_ before it sets Offer
    std::string updateError_;     // written before Failed
    std::atomic<float> updateProgress_{0};
    std::thread updateThread_;
    bool restartAfterQuit_ = false;  // on_cleanup starts the updated editor
    std::string pendingScene_;  // open-scene request waiting for the unsaved-changes dialog
    std::string windowTitle_;   // what set_window_title last set ("FactorIA <version> — <project>")

    // Export window
    bool showExport_ = false, exportFocus_ = false, exportScroll_ = false;
    ExportSettings exportSettings_;
    std::vector<ExportStatus> exportStatus_;  // one per export_targets() entry, refreshed every few seconds while shown
    double exportChecked_ = -100;
    ExportJob exportJob_;
    std::optional<ExportOutcome> exportLast_;  // the last export's report (or error), shown under the buttons
    ProjectExportSettings exportSaved_;        // what factoria.json says now (the Android row's format), read with the rows
    std::string exportSavedError_;             // why it could not be read ("" = fine)

    // Platform settings window
    bool showPlatformSettings_ = false, platformFocus_ = false, platformCloseAsk_ = false, platformDiskChanged_ = false;
    PlatformSettings platformSettings_;
    SettingsTab platformTab_ = SettingsTab::General;  // the tab shown (platformTabSet_: select it next frame)
    bool platformTabSet_ = false;
    int platformBgMode_ = -1;                         // Android adaptive background: -1 = by its value, 0 colour, 1 image
    std::string platformMessage_;                     // what the last Save said when it failed
    double platformPolled_ = -10;
    IconChecks iconChecks_;                           // the icon files the window shows, checked when they change
    struct IconPreview {
        TextureEntry tex;
        std::int64_t mtime = -2;
        double checkedAt = -1e9;
    };
    std::map<std::string, IconPreview> iconPreviews_;  // the pictures the window shows (icon_preview)
    bool keystoreOpen_ = false, keystoreOpenRequest_ = false;  // the Create keystore... popup
    KeystoreForm keystoreForm_;
    std::string keystoreError_;
    KeystoreJob keystoreJob_;
    KeystoreRequest keystoreRunning_;                 // what the job in flight creates
    KeystoreForm keystoreRunningForm_;

    // Set Up This Computer window
    bool showSetup_ = false, setupFocus_ = false;
    int setupScroll_ = 0;  // frames left to scroll the Set up window to its report
    SetupJob setupJob_;                              // the install that runs (one at a time)
    SetupStatusCache setupStatus_;                   // what each component says now; refreshed on a worker, never downloads
    bool setupRefreshAgain_ = false;                 // an install finished: look again when the refresh in flight is done
    std::shared_ptr<SetupCache> setupCache_ = std::make_shared<SetupCache>();  // one Android listing for the license and the install
    std::optional<SetupOutcome> setupLast_;          // the last install's report (or error), shown in the window
    SetupLicenseLoad setupLicense_;                  // the Android SDK license text, loaded when the dialog opens
    bool setupLicenseOpen_ = false, setupLicenseRequest_ = false, setupLicenseTick_ = false;  // the dialog; the "I accept" checkbox
    SetupAction setupPending_;                       // what the license dialog installs when it is accepted
    std::optional<SetupContext> setupTestContext_;   // tests: a fake downloader and process runner instead of the real ones

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
    std::string dlgDelete_;  // project waiting for the "Delete project?" confirmation

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
    struct ProviderModels {  // what ai::list_models said about one available provider
        std::vector<ai::ModelInfo> models;
        std::string error;   // set when it could not list: the Roles window offers a text box instead of a list
    };
    std::map<std::string, ProviderModels> aiModels_;  // by provider name (under aiMu_); filled after the detection
    std::atomic<bool> aiDetected_{false};
    std::atomic<bool> aiDetecting_{false};  // provider detection AND the model lists that follow it
    std::thread aiDetectThread_;
    std::thread aiThread_;
    std::atomic<bool> aiRunning_{false};
    std::atomic<bool> aiCancel_{false};
    std::vector<ai::AgentEvent> aiPending_;  // produced by the agent thread, drained on the main thread
    std::optional<ai::SessionResult> aiResult_;
    AiChats chat_;                  // the conversations (tabs); the active one is chat_.current()
    std::string aiRunChat_;         // id of the chat the agent thread works for ("" = no run); set by ai_start, cleared on the result
    std::string aiRunProvider_;     // provider of that run (the plan limits belong to it)
    LimitsByProvider aiLimits_;     // plan windows reported since the editor started, shared by every tab
    int aiTabForce_ = 0;            // frames left to force the active tab (a tab opened/closed by code)
    bool aiHistoryOpen_ = false;    // request to open the History popup this frame
    std::vector<ChatHistoryEntry> aiHistory_;
    std::string aiHistoryDelete_;   // History row waiting for the second click on its Delete
    bool aiRolesOpen_ = false;      // request to open the AI roles popup this frame
    std::map<std::string, ai::RoleConfig> aiRolesEdit_;  // the roles being edited in that popup
    std::set<std::string> aiRolesTyping_;                // roles whose model is a text box (Other... picked)
    std::shared_ptr<CommandRegistry> aiProxy_;  // the current run's proxy (under aiMu_: the MCP endpoint reads it)
    // The editor's MCP endpoint for CLI agents (Claude Code): it serves aiProxy_, so their tool calls run here like an
    // API provider's. Started by the first ai_start, stopped by ai_stop (project switch, quit).
    McpHttpServer aiMcp_;
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
    std::map<std::string, bool> atWidgetEnabled_;           // false when the widget was submitted disabled (at_track's `enabled`)
    std::map<std::string, bool> atWidgetShown_;             // false when the widget was submitted but is scrolled out of its window
    void at_track(const std::string& name, bool enabled = true);
    Vec2 at_widget(const std::string& name);               // centre of a widget drawn in the last frames (fails the test otherwise)
    bool at_visible(const std::string& name) const;        // was the widget submitted in the last frame?
    bool at_enabled(const std::string& name) const;        // ... and not disabled (a button that cannot be pressed yet)?
    bool at_shown(const std::string& name) const;          // ... and not scrolled out of its window (a click would land elsewhere)?
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
    std::string atDeleteProject_;  // scratch project the autotest deletes through the Open project dialog
    size_t atUndoBeforeAi_ = 0;
    bool atWaitAi_ = false;
    std::vector<ai::ProviderStatus> atSavedStatus_;
    std::optional<ai::AiConfig> atSavedConfig_;  // the AI config while the CLI-agent check swaps in the fake Claude Code
    int atWaitCount_ = 0;
    // A frame that never ends (a GPU read-back that waits for ever) would leave the window frozen on the user's screen: the
    // watchdog thread ends the process when the editor draws no frame for a minute (on_init starts it, only in the autotest).
    std::atomic<std::uint64_t> atHeartbeat_{0};
    std::atomic<bool> atWatchdogStop_{false};
    std::thread atWatchdog_;
    int atFrameBudget_ = 3000;  // the autotest must be done by this frame (a real download, in the manual check, needs more)
    std::function<bool()> atWaitUntil_;  // holds the script (like atWaitAi_) until it returns true
    void save_screenshot_now(const std::string& path);
};

// Helpers shared across panel files.
extern Editor* g_editor;
// The first size of a window that is centred on the main viewport: `wanted`, made smaller to fit its work area so the
// window's own buttons (Save, Close...) are never off screen on a small display.
inline ImVec2 fit_work_area(ImVec2 wanted) {
    const ImGuiViewport* vp = ImGui::GetMainViewport();
    return ImVec2(std::min(wanted.x, vp->WorkSize.x * 0.96f), std::min(wanted.y, vp->WorkSize.y * 0.96f));
}
// Status colours of the Export and Platform settings windows.
inline const ImVec4 kStatusReady(0.5f, 0.9f, 0.55f, 1), kStatusFailed(1, 0.45f, 0.4f, 1), kStatusWarn(1, 0.8f, 0.35f, 1);
// The window title: "FactorIA <version> — <project name>", or "FactorIA <version>" with no project open (the Open or
// create a project dialog). `version` is the engine's, FA_ENGINE_VERSION: what `factoria version` prints.
std::string editor_window_title(std::string_view version, std::string_view projectName);
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
// Whether the system clipboard holds text (what Ctrl+V pastes into a text box).
bool clipboard_has_text();
void maximize_window();
// Opens `dir` in the system's file manager (Finder, Explorer, xdg-open on Linux) without waiting for it. Returns "" or
// what went wrong. file_manager_name() is what the button says: "Finder", "Explorer" or "file manager".
std::string open_in_file_manager(const std::string& dir);
// Shows one file in the file manager, selected where the system can (Finder, Explorer); on Linux its folder opens.
std::string reveal_in_file_manager(const std::string& path);
const char* file_manager_name();

}  // namespace fa::editor
