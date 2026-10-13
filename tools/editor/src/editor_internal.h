// Editor state shared by all panels. One instance lives for the whole run_editor() call.
//
// THREADING: everything here runs on the main (UI/GPU) thread EXCEPT the AI agent
// thread (ai_panel.cpp). The agent never touches the engine directly: its command
// registry is a proxy whose handlers enqueue jobs into MainThreadQueue and block
// until the main thread has executed them (Editor::on_frame -> queue.pump()).
#pragma once

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
#include "fa/scene/serialize.h"
#include "fa/tooling/tooling.h"
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

struct ChatItem {
    enum class Kind { User, Assistant, Thinking, Tool, Info, Error };
    Kind kind = Kind::Info;
    std::string text;
    std::string tool;
    Json input;
    Json result;
    bool done = false;
    bool isError = false;
    int depth = 0;
    std::string role;
};

struct TextureEntry {
    std::uint32_t image = 0, view = 0;
    int w = 0, h = 0;
    bool failed = false;
};

struct AssetNode {
    std::string name;
    std::string path;  // project-relative; folders end without '/'
    bool isDir = false;
    std::vector<AssetNode> children;
};

struct JsonEditState {
    std::string text;
    std::string error;
    bool editing = false;
};

struct PickBounds {
    bool valid = false;
    bool screenSpace = false;
    Vec2 center{0, 0};  // local space, relative to the entity origin
    Vec2 half{16, 16};
    int layer = 0;
};

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
    void reload_scene_from_disk();
    void restore_scene(const Json& snapshot);

    // ---------------------------------------------------------------- play mode
    PlayState play_state() const { return play_; }
    void play();
    void pause();
    void step_once();
    void stop();

    // ---------------------------------------------------------------- selection & edits
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
    // Writes one reflected field via fa::patch_component (the path every inspector widget uses).
    bool apply_field(Entity e, const TypeInfo& type, const std::string& field, const Json& value, const std::string& key);
    bool apply_field_by_name(const std::string& entityId, const std::string& component, const std::string& field,
                             const Json& value);
    Entity create_entity(const std::string& kind, Entity parent);
    Entity duplicate_entity(Entity e);
    void delete_entity(Entity e);

    // ---------------------------------------------------------------- UI helpers
    void notify(const std::string& text, int level = 0);
    void focus_window(const char* name) { pendingFocus_ = name; }
    void run_console_line(const std::string& line);
    const TextureEntry* texture_for(const std::string& path);
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
    void draw_hierarchy();
    void draw_inspector();
    void draw_assets();
    void draw_console();
    void draw_ai_panel();
    void draw_feedback_panel();
    void draw_project_dialog();
    void draw_validation_window();
    void draw_docs_window();
    void draw_toasts();
    void draw_inspector_component(Entity e, const TypeInfo& t);
    bool draw_field(Entity e, const TypeInfo& t, const FieldInfo& f, void* comp);

    // AI
    void ai_refresh_providers();
    void ai_start(const std::string& task);
    void ai_stop();
    void ai_drain_events();
    std::shared_ptr<CommandRegistry> make_proxy_registry();
    MainThreadQueue& queue() { return queue_; }
    bool ai_running() const { return aiRunning_.load(); }
    const std::vector<ChatItem>& chat() const { return chat_; }

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
    bool dragging_ = false;
    Vec3 dragStartWorld_{}, dragStartPos_{};
    float dpi_ = 1.0f;

    // panel visibility
    bool showViewport_ = true, showHierarchy_ = true, showInspector_ = true, showAssets_ = true;
    bool showConsole_ = true, showAi_ = true, showFeedback_ = true;
    bool showProjectDialog_ = false, showValidation_ = false, showDocs_ = false, showDemo_ = false;
    bool showQuitDialog_ = false, showReloadConfirm_ = false;
    std::string pendingScene_;  // open-scene request waiting for the unsaved-changes dialog

    // hierarchy
    std::string hierFilter_;
    std::string renamingId_;
    bool renameFocus_ = false;
    std::string pendingReparentChild_, pendingReparentParent_;
    bool pendingReparent_ = false;

    // inspector
    std::unordered_map<std::string, JsonEditState> jsonEdits_;
    std::string componentFilter_;
    std::string assetPickFilter_;

    // assets
    AssetNode assetRoot_;
    double assetsScanned_ = -10;
    std::string assetSelected_;
    std::vector<std::string> projectFiles_;
    double filesScanned_ = -10;
    const std::vector<std::string>& project_files();
    std::unordered_map<std::string, TextureEntry> textures_;
    std::unordered_map<std::string, Vec2> imageSizes_;

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
    std::vector<ChatItem> chat_;
    std::string aiInput_;
    int aiProvider_ = 0;  // 0 = role default
    int aiRole_ = 0;
    ai::Usage aiUsage_;
    double aiCost_ = 0;
    bool aiScrollDown_ = false;
    std::shared_ptr<CommandRegistry> aiProxy_;

    // autotest
    bool autotest_ = false;
    int atFrame_ = 0;
    std::string atOutDir_;
    std::string atTempProject_;
    std::vector<std::string> atFailures_;
    std::vector<std::string> atLog_;
    std::vector<std::string> atPendingShots_;
    std::future<CommandResult> atThreadResult_;
    std::thread atThread_;
    std::shared_ptr<CommandResult> atMarshalResult_;
    Vec3 atOriginalPos_{};
    std::uint64_t atStepFrame_ = 0;
    void at_check(bool cond, const std::string& what);
    void save_screenshot_now(const std::string& path);
};

// Helpers shared across panel files.
extern Editor* g_editor;
std::string lower_str(std::string s);
bool contains_ci(const std::string& hay, const std::string& needle);
ImVec4 level_color(LogLevel l);
const char* asset_extensions_hint(const std::string& assetType);
bool asset_matches(const std::string& assetType, const std::string& path);

}  // namespace fa::editor
