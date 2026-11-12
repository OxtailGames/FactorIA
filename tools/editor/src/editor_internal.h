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
#include <chrono>
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

#include "fa/ai/activity.h"
#include "fa/ai/commands.h"
#include "fa/ai/config.h"
#include "fa/ai/detect.h"
#include "fa/ai/plugin_install.h"
#include "fa/ai/project_settings.h"
#include "fa/ai/provider.h"
#include "fa/ai/review.h"
#include "fa/ai/skills.h"
#include "fa/ai/session.h"
#include "fa/core/asset_manifest.h"
#include "level_gen_model.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/core/process.h"
#include "fa/editor/editor.h"
#include "fa/editor/update.h"
#include "fa/mcp/http_server.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/play_session.h"
#include "fa/scene/bones2d.h"
#include "fa/scene/bounds.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/export.h"  // executable_dir: where the update goes
#include "fa/tooling/qr.h"
#include "fa/tooling/self_update.h"
#include "fa/tooling/tooling.h"
#include "ai_asset_approval.h"
#include "ai_chat.h"
#include "ai_runs.h"
#include "ai_usage.h"
#include "anim3d_ui.h"
#include "anim_ui.h"
#include "editor_tools.h"
#include "export_job.h"
#include "phone_model.h"
#include "auto_play_job.h"
#include "play_sessions_model.h"
#include "child_command_job.h"
#include "review_loader.h"
#include "review_model.h"
#include "feedback_share_ui.h"
#include "gizmo_model.h"
#include "image_ui.h"
#include "vector_ui.h"
#include "sound_ui.h"
#include "particle_ui.h"
#include "modeler_ui.h"
#include "music_ui.h"
#include "imgui.h"
#include "imgui_stdlib.h"
#include "inspector_model.h"
#include "menu_model.h"
#include "native_menu.h"
#include "platform_settings.h"
#include "project_browser_model.h"
#include "setup_job.h"

struct sapp_event;

namespace fa::editor {

enum class PlayState { Edit, Playing, Paused };

// ------------------------------------------------------------------------------------------
// Thread-safe queue that moves command calls from the AI threads to the main thread. Several runs call it at the same time
// (up to limits.maxConcurrentRuns agent threads, each with its own cancel flag and tag): jobs run one at a time on the
// main thread, in the order they were queued, and a job names the run it came from (current_tag) so the editor knows which
// chat a command belongs to.
class MainThreadQueue {
public:
    // Called from worker threads. Blocks until the main thread ran the command, the queue was closed, or `cancel` became
    // true (that run was stopped: its job is dropped if it has not started, other runs' jobs are not touched), or the
    // calling thread's request cancel flag (command_cancel_flag(): an MCP client's notifications/cancelled) became true,
    // with the same effect. A job the main thread already runs finishes there. `tag` is handed back by current_tag() while
    // the job runs.
    CommandResult call(const std::string& name, const Json& args, const std::atomic<bool>* cancel, const std::string& tag = {});
    // Main thread: runs queued jobs (each through `run`) until `budgetMs` is used up (at least one job runs; the rest
    // stay queued for the next frame so the UI keeps updating). Returns how many ran. `run` may call take_current() and
    // return nullopt: it then owns the reply and must fulfil the promise later (sliced long commands). The pump stops
    // after such a job, so a second long command from another run waits for the slice instead of replacing it.
    int pump(const std::function<std::optional<CommandResult>(const std::string&, const Json&)>& run, double budgetMs = 1e9);
    // Inside `run`: takes over the promise of the job being run.
    std::shared_ptr<std::promise<CommandResult>> take_current() { return std::move(current_); }
    // Inside `run`: the tag the caller gave (the chat id of the run that made the call; "" for any other caller).
    const std::string& current_tag() const { return currentTag_; }
    void close();   // fails pending and future calls (editor shutting down / project switch)
    void reopen();
    std::size_t size();  // jobs waiting (a test and the autotest look at it)

private:
    struct Job {
        std::string name, tag;
        Json args;
        // Who asked and what they may do (command_context() of the calling thread: the caller, the capability set and the words of a
        // refusal), installed again on the main thread while it runs: a command an MCP client or an AI role queued keeps its set.
        CommandContext context;
        std::shared_ptr<std::promise<CommandResult>> promise;
        std::shared_ptr<std::atomic<bool>> abandoned;  // the caller gave up (Stop): the job is skipped, not run
    };
    std::mutex mu_;
    std::deque<Job> jobs_;
    std::shared_ptr<std::promise<CommandResult>> current_;
    std::string currentTag_;
    bool closed_ = false;
};

// ------------------------------------------------------------------------------------------
struct Toast {
    std::string text;
    int level = 0;  // 0 info, 1 warn, 2 error
    double expires = 0;
    std::string actionLabel;        // optional button in the toast (empty: none)
    std::function<void()> action;   // what the button does
    std::string actionId;           // autotest widget name of the button
};

struct TextureEntry {
    std::uint32_t image = 0, view = 0;
    int w = 0, h = 0;
    bool failed = false;
};

// A picture of the Review window (review_panel.cpp): its texture once the reader decoded it and the UI thread uploaded it.
struct ReviewTextureSlot {
    TextureEntry tex;
    std::uint64_t usedFrame = 0;    // uiFrame_ when it was last drawn: unused for a while, it is freed
    std::string error;              // why it cannot be shown ("" = fine, or not read yet)
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
    // ~/.factoria/editor_recent.json (recent_projects.h); never read or written in the autotest.
    std::string recent_projects_file() const;
    void load_recent_projects();                    // once, when the editor starts: recentProjects_ = the ones that exist
    void remember_recent_project(const std::string& dir);  // opened: first in the file, merged with what it holds
    void forget_recent_project(const std::string& dir);    // deleted from disk: out of the file
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
    void reset_feel_choices();   // feel.reduceMotion / reducedEffects back to following the system (a Play session starts and ends)

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
    void ai_attach_session(const std::string& name, const std::string& note);  // summary + mark pictures of one session
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
    // A toast with a button: it stays longer and does not vanish while the mouse is over it.
    void notify_action(const std::string& text, const std::string& label, std::function<void()> action, const std::string& id);
    void open_screenshots_folder();
    void set_window_title(const std::string& title);  // the OS window's title (editor_window_title); windowTitle_ keeps it
    void focus_window(const char* name) { pendingFocus_ = name; }
    void run_console_line(const std::string& line);
    // Commands typed in the Console or called by the AI go through these two hooks (editor_app.cpp):
    // command_edits_scene() is false for commands that only write FILES (prefab.save, scene.format, scene.ascii_edit,
    // scene.import_ascii with `path`) and for the feel.* effects (a moment of the running game), so they neither take an undo snapshot nor mark the scene dirty; after_command() reloads
    // the scene when scene.import_ascii or scene.ascii_edit rebuilt the scene file that is open (Ctrl+Z brings back what was
    // on screen).
    bool command_edits_scene(const std::string& name, const Json& args) const;
    void after_command(const std::string& name, const Json& args, const CommandResult& result);
    const TextureEntry* texture_for(const std::string& path);
    VisualMeasure visual_measure();        // texture sizes and text layout for the engine's bounds code
    PickBounds bounds_of(Entity e);
    void mesh_local_box(Entity e, Vec3& lo, Vec3& hi);  // the selection box of a MeshRenderer in its own space (viewport.cpp)
    Entity pick_at(Vec2 designPos);
    bool primary_is_ortho();
    // Transform gizmos of the viewport (viewport_gizmo.cpp). gizmo_frame runs once per viewport frame (edit and paused): keys,
    // layout, hover, starting / updating / ending a drag. It returns true when the click was taken by a handle (so it must not
    // select). gizmo_draw paints the handles with the draw list. Every change is a scene.set_component call on Transform through
    // edit_command, so undo, the scene file and "lost on Stop" come with it.
    bool gizmo_frame(Renderer& r, ImVec2 imgMin, ImVec2 size, bool hovered);
    void gizmo_draw(ImDrawList* dl);
    void gizmo_end_drag(bool cancel);
    void gizmo_toolbar_buttons();
    Vec2 image_size_of(const std::string& path);

    // ---------------------------------------------------------------- panels
    void build_ui();
    // The main menu (main_menu.cpp): build_main_menu makes the tree from the editor's state (`native`: for the system menu bar of
    // macOS: no Quit in File, an Export menu instead of the bar's click item, no version text), draw_main_menu shows it.
    menu::MainMenu build_main_menu(bool native);
    void draw_main_menu();
    std::unique_ptr<NativeMenu> nativeMenu_;  // the macOS system menu bar; null = the ImGui bar draws the menu
    bool nativeMenuChecked_ = false;          // nativeMenu_ is made on the first frame
    void draw_toolbar();
    void draw_status_bar();
    void build_default_layout(unsigned dockId, ImVec2 size);
    // Back to the welcome screen (no project): the UI and the engine are torn down on the next frame like in open_project.
    void close_project() { pendingWelcome_ = true; }
    void draw_viewport();
    void draw_console();
    void draw_ai_panel();
    void draw_ai_roles_tab(const ai::AiConfig& cfg, const std::vector<ai::ProviderStatus>& status);
    std::string ai_roles_summary();  // the current roles, one per line (tooltip of the AI menu's Roles...)
    // AI settings window (ai_settings.cpp; AI > AI Settings... and AI > Roles...): a Roles tab (the provider and model of each role),
    // and an Assets tab: where each kind of asset is made (provider, model, voice, API key) and which websites the AI looks at. Save goes through
    // ai::save_asset_settings: only "assets", "assetSources" and the provider fields these need change in the user's ai.json.
    void open_ai_settings(bool rolesTab = false);  // rolesTab: show the Roles tab (else the tab the window had)
    void draw_ai_settings_window();
    // Fills the draft from `cfg`. keepAssets / keepTools: carry that tab's unsaved edits over (a Save on the other tab).
    // `cfg` is the user's config (ai.json as loaded): the tool servers, extensions and providers come from it; the asset routes and
    // sites come from the open project's resolved config when a project is open (ai_window_config).
    void ai_settings_load(const ai::AiConfig& cfg, bool keepAssets = false, bool keepTools = false);
    Result<ai::AssetSettings> ai_settings_build(const ai::AiConfig& cfg) const;
    bool ai_settings_dirty(const ai::AiConfig& cfg) const;
    // The AI settings of the open project (ai_project_ui.cpp; docs/EDITOR.md "AI settings", docs/AI_PROVIDERS.md "Per project"): with a
    // project open the window edits <project>/.factoria/ai/settings.json (ai::resolve_ai_config_over says where each value comes
    // from, ai_project_edit.h what to write); without one it edits ai.json. The editor is the only writer that records trust.
    struct AiProjectUi {
        bool have = false;                  // `resolved` is the resolution of `dir`
        std::string dir;
        ai::ResolvedAiConfig resolved;
        std::optional<Error> error;         // the resolution failed: the project's file was accepted and is invalid now
        long long atMs = 0;
        std::string ignoredHash;            // the file the user chose to ignore (its hash): no banner, no effect, a Save replaces it
        std::string actionError;            // why Accept / Reset / Save of the project's file failed
        // Two confirmations (draw_ai_project_popups). The Save and Delete buttons live in child windows, so they only raise a request
        // here and the banner, at the window's own ID level, opens the popup.
        bool replaceAsk = false;            // open "Replace the project's AI settings file?": a Save would replace the file the user ignored
        bool replaceOk = false;             // the user confirmed: the next ai_project_save may replace it (and clears this)
        std::uint64_t okFrame = 0;          // the UI frame of that confirmation: it counts for the rest of that frame only
        std::string askFrom, retryFrom;     // which Save asked ("roles", "assets"), and which one the confirmation presses again
        bool deleteAsk = false;             // open "Delete the project's AI settings file?"
    } aiProj_;
    std::atomic<bool> aiProjStale_{true};   // the next ai_project_refresh() resolves again
    void ai_project_invalidate();           // ANY thread: drop every cache of the project's resolution (a save, reset, accept, ai.json change, project switch)
    const AiProjectUi& ai_project_refresh();  // main thread: the resolution of the open project (again when stale or older than a second)
    ai::AiConfig ai_user_config();          // ai.json as the editor holds it (the engine's defaults when it was not read yet)
    ai::AiConfig ai_window_config();        // what the AI settings window edits: the project's resolved config with a project open, else ai.json's
    bool ai_project_open() const { return !projectDir_.empty(); }
    bool ai_project_locked();               // a file that waits for Accept / Ignore, or one that cannot be read: nothing is saved or reset until then
    void draw_ai_project_banner();          // the top of the window: where the values are edited, what waits for Accept, the file's problems
    void ai_project_accept();
    // Before a Save replaces the project's ignored file: its copy (settings.replaced.json), or the error that says Save must be confirmed or
    // the copy could not be made. Nothing to do (ok) when no ignored file would be replaced. Called before anything else is written.
    Result<void> ai_project_keep_replaced_copy();
    Result<void> ai_project_save(const Json& overrides);   // save_project_settings(..., recordTrust=true): what the user chose here
    // Save over a file the user ignored (it came with the project and was never accepted) replaces it: first ask. True = go ahead; false =
    // the popup was requested (`from` is the Save that asked; ai_project_save_retry(from) is true on the frame after the confirmation).
    bool ai_project_replace_allowed(const char* from);
    bool ai_project_save_retry(const char* from);
    void ai_project_delete_file();                         // removes the project's file and forgets its trust record (after the popup)
    void draw_ai_project_popups();                         // the two confirmations, at the level of the window that draws the banner
    Result<void> ai_project_reset(const std::string& pointer);
    Result<void> ai_project_after_defaults(const ai::AiConfig& wanted);  // after Save as my defaults: the project's file keeps only what still differs
    Result<void> ai_user_config_reload();   // load ai.json again into aiConfig_ (and drop the caches)
    // ai.settings.set (run by an AI agent or an MCP client) wrote the user's ai.json (aiUserFileChanged_) or the
    // project's file (aiProjectFileChanged_) behind the windows' back. The callbacks run on the calling thread: they drop the caches
    // and raise the flag, and this (main thread, once per frame) does the rest: reload ai.json, detect the providers again (the key
    // and program checks) and reload the AI settings window's Roles edits and draft, keeping the rows the person had changed.
    std::atomic<bool> aiUserFileChanged_{false}, aiProjectFileChanged_{false};
    void ai_settings_changed_elsewhere();
    std::string ai_project_settings_path() const;
    void draw_feedback_panel();
    void draw_feedback_add_window();            // the Add feedback modal of the panel
    // Feedback sharing (feedback_share_ui.cpp; docs/EDITOR.md, "Sharing feedback"). share_choose_mode is the only place that sets the
    // sharing mode, reached by a click in the consent dialog or Feedback Settings and by nothing else: no command, MCP tool or script.
    void feedback_share_tick();                 // once per frame: the threads' results, then (each second) consent, queue, ask, flush
    void draw_share_consent();                  // the modal that asks while the mode is unset
    void draw_send_window();                    // the Send feedback modal: every entry that would be sent, with its text and a checkbox
    void draw_share_settings_window();          // File > Feedback Settings
    void open_share_settings();
    void open_send_window();                    // Send feedback: by the mode, the window, the consent dialog first, or why not
    void build_send_window();                   // plans the rows from the feedback file and starts their AI check
    void send_window_apply();                   // Send: store and queue the checked rows, leave the others out, flush
    void send_window_finished(int sent, const std::string& message);  // the flush Send asked for is over
    void share_fill_consent_preview(const std::string& file, const Json& doc);
    void share_choose_mode(ShareMode mode);                        // the default
    void share_choose_project_mode(std::optional<ShareMode> mode);  // this project's own (nullopt = follow the default)
    void share_start_flush(bool force, std::uint64_t session = 0);
    void share_start_verdicts(const std::string& feedbackFile);  // ask the server what the engine developers decided (a thread)
    void share_start_sign_in();
    void share_start_ai_checks();
    void draw_feedback_share_cell(const Json& entry, const char* track = nullptr);                          // the panel table's share column
    ShareUi share_;
    std::shared_ptr<ShareAutotestNet> atShareNet_;
    std::unique_ptr<ScopedShareEnv> atShareEnv_;  // the autotest: a fake transport and a config folder of its own, no network
    void draw_audio_panel();
    // Animation panel (anim_panel.cpp; View > Animation): the clips of the selected entity's Animator as a dopesheet and a curve
    // view, a time ruler to scrub, event markers, record mode and the onion skin. Every edit of a clip is an anim.* command through
    // anim_edit(), so the Console and the AI see the same calls; a clip file is not part of the scene, so its undo steps are
    // entries of the same stack (`{"$clip": {path, clip}}`: the arguments of anim.restore) and undo() / redo() run them.
    void draw_animation_panel();
    void draw_anim_toolbar(const std::shared_ptr<const ClipAsset>& clip, const std::string& path);
    void draw_anim_time_area(const std::shared_ptr<const ClipAsset>& clip, const std::string& path);
    void draw_anim_curves(const std::shared_ptr<const ClipAsset>& clip, const std::string& path, ImVec2 origin, ImVec2 size);
    void anim_key_menu(const std::shared_ptr<const ClipAsset>& clip, const std::string& path);
    void anim_event_popups(const std::string& path);
    void anim_refresh_owner();
    Entity anim_owner();
    std::string anim_clip_path();                                  // the file of the clip being edited ("" = none)
    bool anim_edit(const std::string& key, const std::vector<ModelCall>& calls, std::string* error = nullptr);
    bool anim_new_clip(const std::string& name, double duration, bool loop, std::string* error = nullptr);
    void anim_select_clip(const std::string& name);
    void anim_pose();                                              // poses the animated entity at the playhead (edit mode)
    void anim_unpose();                                            // puts the rest values back (before a save, a scene edit, Play)
    void anim_set_playhead(double t, bool pose = true);
    void anim_apply_clip_undo(const Json& entry, bool forward);    // an undo / redo step of a clip file
    bool anim_record_edit(const std::string& key, const Json& args, CommandResult& out, std::string* error);
    void anim_cancel_step();                                       // Esc during a recorded gizmo drag: the key it wrote goes away
    void anim_update_onion(Renderer& r);
    void anim_draw_onion(ImDrawList* dl, Renderer& r);
    void anim_draw_record_frame(ImDrawList* dl, ImVec2 imgMin, ImVec2 size);
    double anim_x_to_time(float x) const { return anim_.viewStart + double(x - anim_.timeX0) / double(anim_.pps); }
    float anim_time_to_x(double t) const { return anim_.timeX0 + float((t - anim_.viewStart) * double(anim_.pps)); }
    bool anim_recording() const { return anim_.recording && showAnimation_; }
    AnimUi anim_;
    bool lastEditRecorded_ = false;  // the last edit_command wrote a clip key instead of a field
    // Animation panel, 3D mode (anim3d_panel.cpp; the "3D bone clips" button of the Animation panel, or a double click on a 3D *.anim.json in the Project
    // panel): a factoria.anim3d/1 clip of a rigged model as a dopesheet, a viewport that shows the skinned model posed by the playhead, a bone list, the
    // bone tools (a rotation gizmo, IK handles, mirror pose) and the generators. The rules are in anim3d_model.h: every edit is the anim3d.* / ik3d.key
    // call an AI would make, and its undo is an entry of the editor's stack (`{"$clip3d": {path, clip}}`: the arguments of anim3d.restore).
    bool draw_animation_mode_row();                         // the 2D | 3D switch; true when the 3D mode is on
    void anim3d_prepare_window();                           // before Begin: the first time the 3D mode shows, the panel leaves its dock and grows
    void draw_animation_panel_3d();
    void draw_anim3d_sheets();                              // the filmstrip and the weights picture, in their own window
    void anim3d_toolbar();
    void anim3d_bone_list();
    void anim3d_viewport();
    void anim3d_dopesheet();
    void anim3d_inspector();
    void anim3d_scan_lists();
    Anim3DModel& anim3d_ensure_model();
    bool open_anim3d_clip(const std::string& rel, const std::string& rig = {});   // false and a toast when it does not load
    void anim3d_commit(const Anim3DEdit& edit);             // the undo entry of an edit, a toast for an error
    void anim3d_apply_undo(const Json& entry, bool forward);
    void anim3d_release_textures();
    void anim3d_load_sheet(Anim3DUi::Sheet& sheet, const std::string& what, const Json& result);
    void anim3d_show_filmstrip();
    void anim3d_show_weights();
    double anim3d_snap(double t) const;
    Vec2 anim3d_time_point(double t) const;                 // the ruler at time t (the autotest scrubs by it)
    Anim3DUi anim3d_;
    // Image panel (image_panel.cpp, image_canvas.cpp; View > Image, or a double click on a *.image.json in the Project panel): the layered
    // image document as a canvas with brushes, selections and a transform, a layer list with an inspector, adjustments and effects, a
    // palette bar and a frame strip. The rules are in image_model.h: every edit it keeps is an image.* command, so the Console and the
    // AI make the same calls, and its undo steps are entries of the same stack as the scene's (`{"$image": {"step": id}}`).
    ImageModel& image_ensure_model();                      // makes the panel's model on first use
    void draw_image_panel();
    void draw_image_toolbar(ImageModel& m);
    void draw_image_tools(ImageModel& m);
    void draw_image_options(ImageModel& m);
    void draw_image_canvas(ImageModel& m, ImVec2 size);
    void draw_image_palette(ImageModel& m);
    void draw_image_frames(ImageModel& m);
    void draw_image_side(ImageModel& m);
    void draw_image_terrain(ImageModel& m);                // terrain paint preview of a tileset document (image_canvas.cpp)
    void draw_image_layers(ImageModel& m);
    void draw_image_provider(ImageModel& m);               // Inpaint selection... / Generate layer... (image_provider_panel.cpp)
    void image_provider_refresh();
    void image_provider_start(ImageModel& m);
    void image_provider_estimate(ImageModel& m);
    void image_provider_estimate_poll(ImageModel& m);
    void image_provider_poll(ImageModel& m);
    void draw_image_layer_inspector(ImageModel& m);
    void draw_image_operations(ImageModel& m, const ImageLayer& layer, bool effect);
    void image_canvas_input(ImageModel& m, bool hovered, bool editable);
    void image_draw_selection(ImageModel& m, ImDrawList* dl);
    void image_draw_transform(ImageModel& m, ImDrawList* dl, bool editable);
    void image_update_textures(ImageModel& m);
    void image_fit();
    ImVec2 image_to_screen(float x, float y) const;
    ImVec2 image_from_screen(ImVec2 p) const;
    bool open_image_document(const std::string& rel);     // opens (or switches to) the document in the panel; false and a toast on failure
    void image_edited(const ImageEditOutcome& out);       // after an edit: the undo entry, the Project panel, a toast for an error
    void image_apply_undo(const Json& entry, bool forward);
    void image_collect_steps();                           // drops the undo steps no stack entry points to
    void image_close_document();
    void image_release_textures();
    void image_save();
    Vec2 image_screen_pos(float x, float y) const { auto p = image_to_screen(x, y); return Vec2{p.x, p.y}; }   // the autotest drives the canvas
    ImageUi image_;
    bool showImage_ = false;
    // Vector panel (vector_panel.cpp, vector_canvas.cpp; View > Vector, or a double click on a *.svg in the Project panel): an SVG as a
    // canvas with a pen, node editing, shape tools and boolean buttons, a layer list (the groups and elements of the SVG) and an
    // inspector. The rules are in vector_model.h: every edit it keeps is a vector.* command, so the Console and an AI make the same
    // edit, and each edit is ONE entry of the editor's undo stack. The svg layers of an image document open here too.
    VectorModel& vector_ensure_model();                    // makes the panel's model on first use
    void draw_vector_panel();
    void draw_vector_toolbar(VectorModel& m);
    void draw_vector_tools(VectorModel& m);
    void draw_vector_actions(VectorModel& m);
    void draw_vector_canvas(VectorModel& m, ImVec2 size);
    void draw_vector_side(VectorModel& m);
    void draw_vector_layers(VectorModel& m);
    void draw_vector_inspector(VectorModel& m);
    void draw_vector_shape_params(VectorModel& m, const VecItem& item);
    void vector_canvas_input(VectorModel& m, bool hovered, bool editable);
    void vector_draw_overlay(VectorModel& m, ImDrawList* dl);
    void vector_update_texture(VectorModel& m);
    void vector_fit();
    ImVec2 vector_to_screen(VecPoint p) const;
    VecPoint vector_from_screen(ImVec2 p) const;
    bool open_vector_document(const std::string& rel);                              // a *.svg file; false and a toast on failure
    bool open_vector_layer(const std::string& documentRel, const std::string& layer);   // an svg layer of an image document
    void vector_edited(const VectorEditOutcome& out);     // after an edit: the undo entry, a toast for an error
    void vector_apply_undo(const Json& entry, bool forward);
    void vector_collect_steps();                          // drops the undo steps no stack entry points to
    void vector_close_document();
    void vector_release_textures();
    void vector_save();
    Vec2 vector_screen_pos(double x, double y) const { auto p = vector_to_screen(VecPoint{x, y}); return Vec2{p.x, p.y}; }   // the autotest drives the canvas
    VectorUi vector_;
    bool showVector_ = false;
    // Sound panel (sound_panel.cpp; View > Sound, or a double click on a *.sfx.json, *.audio.json, .wav or .ogg in the Project panel): a sound
    // patch, an audio document or a plain sound file as a waveform and spectrogram with measurements, macro knobs, an inspector, the step chain
    // of a document with draggable loop points, variants and an A/B at the same loudness. The rules are in sound_model.h: every edit it keeps
    // is a command call (sfx.tweak, sfx.edit, audio.edit, ...), so the Console and an AI make the same edit.
    SoundModel& sound_ensure_model();                      // makes the panel's model and player on first use
    void draw_sound_panel();
    void draw_sound_toolbar(SoundModel& m);
    void draw_sound_transport(SoundModel& m);
    void draw_sound_wave(SoundModel& m);
    void draw_sound_spectrogram(const SoundRender& r);
    void draw_sound_measures(SoundModel& m);
    void draw_sound_macros(SoundModel& m);
    void draw_sound_fields(SoundModel& m, const std::string& pointer, bool top);
    void draw_sound_json_field(SoundModel& m, const SoundField& f, float width);
    void draw_sound_chain(SoundModel& m);
    void draw_sound_step_fields(SoundModel& m, const SoundChainStep& s);
    void draw_sound_ab(SoundModel& m);
    void draw_sound_variants(SoundModel& m);
    void draw_sound_presets(SoundModel& m);
    void sound_play_clip(SoundRenderPtr clip, double gainDb, int heard, const std::string& name);
    void sound_toggle_play();
    void sound_play_slot(int which);                      // 1 = A, 2 = B
    bool open_sound_document(const std::string& rel);     // *.sfx.json, *.audio.json, .wav, .ogg; false and a toast on failure
    void sound_edited(const SoundEditOutcome& out);       // after an edit: the undo entry, a toast for an error
    void sound_apply_undo(const Json& entry, bool forward);
    void sound_collect_steps();                           // drops the undo steps no stack entry points to
    void sound_close_document();
    void sound_release_textures();
    void sound_save();
    Vec2 sound_screen_pos(double seconds, double yFraction) const;   // the autotest drives the waveform
    SoundUi sound_;
    bool showSound_ = false;
    // Particle panel (particle_panel.cpp; View > Particles, or a double click on a *.vfx.json in the Project panel): an effect document played
    // by the engine's own timeline (update_vfx and one ParticleSim per emitter, ParticlePreview) with a time scrubber, a parts list and an
    // inspector built from the emitter's reflected fields, with gradient and curve editors. The rules are in particle_model.h: every edit it
    // keeps is a vfx.edit call, so the Console and an AI make the same edit.
    ParticleModel& particle_ensure_model();                // makes the panel's model and preview on first use
    void draw_particle_panel();
    void draw_particle_toolbar(ParticleModel& m);
    void draw_particle_canvas(ParticleModel& m);
    void draw_particle_timeline(ParticleModel& m);
    void draw_particle_parts(ParticleModel& m);
    void draw_particle_inspector(ParticleModel& m);
    void draw_particle_object_fields(ParticleModel& m, const std::string& base, const TypeInfo& type, const Json& patch, bool essentialsOnly);
    bool draw_particle_row(ParticleModel& m, const std::string& key, const FieldInfo& f, const std::string& pointer, const Json& cur, bool present);
    bool draw_particle_curve_field(ParticleModel& m, const std::string& pointer, const std::string& label, const Json& cur, float lo, float hi);
    bool draw_particle_gradient_field(ParticleModel& m, const std::string& pointer, const std::string& label, const Json& cur);
    bool open_particle_document(const std::string& rel);   // *.vfx.json; false and a toast on failure
    void particle_edited(const ParticleEditOutcome& out);  // after an edit: the undo entry, a toast for an error
    void particle_apply_undo(const Json& entry, bool forward);
    void particle_reload();                                // Reload: takes the file as it is and drops the undo/redo step it made stale
    void particle_drop_stale_step();                       // removes the refused step from both stacks (the file is no longer what it expects)
    void particle_collect_steps();                         // drops the undo steps no stack entry points to
    void particle_close_document();
    Vec2 particle_time_pos(double seconds, double yFraction = 0.5) const;   // the autotest drives the timeline
    Vec2 particle_canvas_pos(float worldX, float worldY) const;              // ...and the canvas
    ParticleUi particle_;
    bool showParticle_ = false;
    // Music panel (music_panel.cpp, music_mixer_panel.cpp; View > Music, or a double click on a *.song.json in the Project panel): a song as a
    // piano roll, a drum grid, an arrangement and a mixer, played by the same transport a game's entity.music uses (an intensity slider fades
    // the layers, a section can be looped). The rules are in music_model.h: every edit it keeps is a command call (music.edit, music.arpeggio,
    // music.bassline, music.drums), so the Console and an AI make the same edit; Save bakes (music.render).
    MusicModel& music_ensure_model();                      // makes the panel's model and preview on first use
    void draw_music_panel();
    void draw_music_toolbar(MusicModel& m);
    void draw_music_transport(MusicModel& m);
    void draw_music_roll(MusicModel& m);
    void draw_music_drums(MusicModel& m);
    void draw_music_arrangement(MusicModel& m);
    void draw_music_mixer(MusicModel& m);
    void music_play(int section, bool loop);               // -1: from the start of the song
    void music_toggle_play();
    bool open_music_document(const std::string& rel);      // *.song.json; false and a toast on failure
    void music_edited(const MusicEditOutcome& out);        // after an edit: the undo entry, a toast for an error
    void music_apply_undo(const Json& entry, bool forward);
    void music_collect_steps();                            // drops the undo steps no stack entry points to
    void music_close_document();
    void music_save();
    Vec2 music_screen_pos(std::int64_t tick, int pitch) const;                  // the autotest drives the piano roll
    Vec2 music_drum_cell_pos(const std::string& lane, int step) const;          // ...and the drum grid
    MusicUi music_;
    bool showMusic_ = false;
    // Model panel (modeler_panel.cpp; View > Model, or a double click on a *.model.json in the Project panel): a model document as its operation
    // tree, the picked node's parameters as sliders and a live view of the mesh it evaluates to, with the picked part highlighted. The rules are
    // in modeler_model.h: every edit it keeps is a model.edit call, so the Console and an AI make the same edit; Save bakes (model.bake).
    ModelerModel& modeler_ensure_model();                   // makes the panel's model on first use
    void draw_modeler_panel();
    void draw_modeler_toolbar(ModelerModel& m);
    void draw_modeler_tree(ModelerModel& m);
    void draw_modeler_viewport(ModelerModel& m);
    void draw_modeler_params(ModelerModel& m);
    bool open_model_document(const std::string& rel);       // *.model.json; false and a toast on failure
    void modeler_edited(const ModelerEditOutcome& out);     // after an edit: the undo entry, a toast for an error
    void modeler_apply_undo(const Json& entry, bool forward);
    void modeler_collect_steps();                           // drops the undo steps no stack entry points to
    void modeler_close_document();
    void modeler_release_textures();
    void modeler_save();
    Vec2 modeler_screen_pos(float fx, float fy) const;      // the autotest drives the viewport: a point as fractions of the picture
    ModelerUi modeler_;
    bool showModeler_ = false;
    // Bone tools (bone_tools.cpp; View > Bone tools): draw a bone chain by clicking, bind a sprite to bones, the weight colours of
    // the selected bone and a brush to paint them, IK targets as handles. They call bones.create, skin.bind, skin.auto_weights,
    // skin.set_weights and scene.set_component through edit_command.
    void draw_bone_tools_panel();
    bool bone_tools_active() const { return showBoneTools_ && bone_.tool != BoneTool::Off; }
    bool bone_tools_frame(Renderer& r, ImVec2 imgMin, ImVec2 size, bool hovered);   // true when the click was taken
    void bone_tools_draw(ImDrawList* dl, Renderer& r, ImVec2 imgMin, ImVec2 size);
    void bone_finish_chain();
    void bone_cancel_chain();
    bool bone_bind(std::string* error = nullptr);
    bool bone_paint_at(Vec2 localPoint, bool firstOfStroke);
    Entity bone_skin_entity();
    SkinBox sprite_local_box(Entity e);  // the rectangle a Sprite covers in its own space, as the renderer lays it out
    BoneUi bone_;
    // Project panel (project_browser_panel.cpp): the project's files; drag them onto Inspector asset fields and the Viewport.
    void draw_project_panel();
    void draw_project_tile(const BrowserFile& f, ImVec2 size);
    void regenerate_assets(const Json& args);  // assets.regenerate with a toast for the result; the panel rescans afterwards
    void poll_recipe_sources();                // every frame (project_browser_panel.cpp): a recipe input saved on disk?
    void draw_recipe_notice();                 // "N assets out of date  [Regenerate] [Not now]"
    void draw_sheet_preview(const std::string& path, const assets::Sheet& sheet, float height);
    // Project panel sheet preview: the clip being played ("" = every frame), when it started, and the frame it shows now.
    std::string sheetPreviewPath_, sheetPreviewChoice_;
    double sheetPreviewStart_ = 0.0;
    int sheetPreviewFrame_ = -1;
    void viewport_accept_drop(Renderer& r, Vec2 design);  // a prefab dropped on the Viewport: scene.spawn at the point under the mouse
    void project_files_changed();                          // the editor wrote or deleted a file: the Project panel rescans
    // Hierarchy (hierarchy_panel.cpp) and Inspector (inspector_panel.cpp): hand editing. Every change is a command call
    // (scene.set_component, scene.set_parent, scene.spawn, scene.destroy...) through edit_command(), the Console's path:
    // an undo snapshot first (one per `key` within 0.8 s, and one per drag), then the call. A refused call leaves no undo
    // step behind. `error` gets the command's message when it failed.
    CommandResult edit_command(const std::string& key, const std::string& name, const Json& args, std::string* error = nullptr);
    void draw_hierarchy_panel();
    void draw_inspector_panel();
    void draw_hierarchy_node(Entity e, const std::string& filter);
    void hierarchy_spawn(const std::string& parentId, const std::string& name);
    void hierarchy_duplicate(Entity e);
    void hierarchy_destroy(Entity e);
    void draw_inspector_component(Entity e, const TypeInfo& type);
    // Draws the widget of one reflected field for the JSON `current`; returns true and sets `out` when the user changed it.
    bool draw_field_widget(const std::string& key, const FieldInfo& f, const Json& current, bool disabled, Json& out);
    void draw_animator_clips(Entity e, const std::string& id, const Json& current);
    void draw_material_params(Entity e, const Json& current);
    void draw_profiler_panel();
    // Level generator window (level_gen_panel.cpp; the model, level_gen_model.h, has no ImGui).
    void draw_level_gen_panel();
    void draw_level_gen_preview(float height);
    LevelGenCaller level_gen_caller();
    void level_gen_keep();
    void level_gen_save();
    void level_gen_write(bool overwrite);   // fs.write of the level file; without overwrite an existing file opens the Replace popup
    void level_gen_refresh_sample();   // the selection's Tilemap and the sample's solid tiles, for the buttons and the preview colours
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

    // Play on Phone window (phone_panel.cpp; File > Play on Phone...): the web server of project.serve_web for the Wi-Fi, its address as
    // a QR code, what to check when the phone cannot open it. The server itself is web_server() (fa/tooling/serve_web.h).
    void open_phone_window();
    void draw_phone_window();
    void poll_phone();           // every frame: takes a finished start's error
    void reset_phone_state();    // project switch: asks for the server of the project that closes to stop (on the helper thread)
    // Play sessions window and Play > Let the AI Play (play_sessions_panel.cpp, auto_play_job.h, play_sessions_model.h): the sessions
    // under .factoria/sessions/ (yours and the AI bot's, marked), one session's report, and the button that runs play.auto in a
    // child process on a worker thread. Progress and Cancel in the window; the finished run opens its report.
    void open_play_sessions(const std::string& select = std::string());
    void draw_play_sessions_window();
    void draw_play_session_report();
    void refresh_play_sessions();
    void start_auto_play();
    void poll_auto_play();            // every frame: takes a finished run's outcome
    void reset_auto_play_state();     // project switch: stops a running bot and forgets the list
    // Review window (review_panel.cpp; View > Review, docs/EDITOR.md "Review window"): the sheets review.sheet made, one shown big with
    // keyboard picking, Compare two and the History of past picks. The reader thread (review_loader.h) lists, reads and decodes; the
    // UI thread uploads one picture a frame. A pick is review.pick (assets.pick for asset candidates) through the command registry.
    void open_review(const std::string& sheet = std::string(), bool focus = true);
    void draw_review_window();
    void draw_review_sheet_tab();
    void draw_review_compare_tab();
    void draw_review_history_tab();
    void draw_review_pick_popup();
    void poll_review();                       // every frame: the reader's results, one upload, the seeds sheet job, a pick waiting
    void reset_review_state();                // project switch, autotest section: stops the reader and the job, frees the textures
    void review_release_textures();
    void review_request_pick(int n);          // opens the confirmation (or says why the number cannot be picked)
    void review_do_pick();                    // the confirmed pick: keeps what was confirmed, then starts it (or waits for the reader)
    void review_start_pick();                 // starts review_.pickPlan in a child factoria (reviewPickJob_)
    // A running pick gets kReviewPickShutdownSeconds to finish; one that hangs has its child killed, which is logged (FA_WARN, with the
    // command, sheet and arguments) and, when the editor stays alive (`editorStays`: a project switch), told in a toast.
    void review_end_pick_for_shutdown(bool editorStays);
    void review_finish_pick(const ChildCommandOutcome& done);   // its result in the window (poll_review)
    // review_pick_plan, plus what the window itself forbids: a pick still running, an older sheet of asset candidates (superseded).
    ReviewPickPlan review_plan_for(const ReviewSheetView& sheet, int n, bool drop, const std::string& note) const;
    // A toast with Open in Review; `slot`: a sheet of asset candidates for that slot (assets.generate_image with a count).
    void review_announce_sheet(const std::string& sheet, const std::string& label, const std::string& slot, const std::string& who);
    void start_level_seeds_sheet();           // the Level generator's "Sheet of N seeds"
    void review_show_sheet(const std::string& id);   // shows that sheet (its manifest and pictures are read on the reader thread)
    // The texture of a picture of the shown sheet, asked of the reader the first time (tex.view is 0 until it is uploaded, `error` when
    // it cannot be read). Marked as used this frame; one not drawn for a while is freed.
    const ReviewTextureSlot& review_texture(const std::string& key, const std::filesystem::path& file, int maxSide, bool projectFile);

    // Platform settings window (platform_settings_panel.cpp; File > Platform Settings..., the Export window's Settings...
    // buttons): the game icon and what each platform's export needs, as a working copy that Save writes with
    // fa::save_export_settings (platform_settings.h has the logic).
    void open_platform_settings(SettingsTab tab = SettingsTab::General);
    void draw_platform_settings_window();
    void poll_platform_settings();          // every frame: factoria.json changed on disk, icon pictures, a keystore being created
    void reset_platform_settings_state();   // project switch: forgets the working copy
    void request_close_platform_settings(); // closes now, or asks first when there are unsaved changes
    void set_windows_format(const std::string& format);  // the Export window's Windows format combo: saves export.windows.format
    void set_android_format(const std::string& format);  // the Export window's format combo: saves export.android.format
    // A project picture scaled down for a preview (<project>/<relPath>, at most 256 px a side), loaded again when the file
    // changes; nullptr when it cannot be read.
    const TextureEntry* icon_preview(const std::string& relPath);

    // Set Up This Computer window (setup_panel.cpp; File > Set Up This Computer..., the "Set up" buttons of the Export and
    // Platform settings windows): the five components fa::setup_status looks at and fa::setup_install on a worker thread
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
    void ai_stop(const char* cause);                           // stops every run: joins the agent threads, applies their last events, saves the chats
    void ai_stop_run(const std::string& chatId);  // stops one chat's run the same way (the others go on)
    void ai_drain_events();                   // every run's pending events and result (one frame's worth)
    void ai_drain_run(AiRun& run);
    // Launches the agent thread of `run` for `prompt` (ai_start's second half; also the automatic continuation of an
    // orchestrator whose delegated worker finished after its turn ended).
    void ai_launch(AiRun& run, const std::string& prompt, const std::vector<std::string>& imageFiles);
    // Ends `run`: its checkpoint item, the saved chat, the endpoint stopped, the run forgotten. `c` is its chat or nullptr.
    void ai_end_run(AiRun& run, AiChat* c);
    // The run of `chat`, not yet in aiRuns_, its MCP endpoint up; nullptr (with a notice) when every slot is taken.
    std::unique_ptr<AiRun> ai_new_run(const AiChat& chat);
    // Reviews (ai_review.cpp): art critiques and game reviews, started ONLY by the user's buttons. A review is one more run
    // (it counts toward limits.maxConcurrentRuns) in the chat tab it was asked from.
    void ai_review_request(const std::string& kind, int count, const std::string& focus);
    void ai_review_next();           // starts the next reviewer of the job
    void ai_review_tick();           // every frame: takes a finished reviewer's report in, starts the next one
    void ai_review_abort(const std::string& why);
    void draw_ai_review_row(bool gameRuns);          // the buttons under the message box
    void draw_ai_reviews_window();                   // past reviews, scores, the report and "Send to orchestrator"
    void ai_review_send(const ai::Review& review);   // posts a review to an orchestrator chat as a user message
    // Everything about "is it still working": called every frame while a run is on (ai_panel.cpp).
    void ai_watchdog_tick(AiRun& run);
    void ai_check_activity(AiRun& run);       // the "Check activity" button: inspects the processes, writes the verdict in the chat
    // The tool calls and file changes of a run, for the same-file warning and the Revert scope (ai_revert.cpp).
    void ai_note_command(const std::string& chatId, const std::string& name, const Json& args, const CommandResult& result);
    void ai_note_files(const std::string& chatId, const std::vector<std::string>& files);
    void ai_warn_conflicts(const std::vector<FileConflict>& conflicts);   // queues them; ai_flush_conflicts tells the chats
    void ai_flush_conflicts();
    // Revert an AI run (ai_revert.cpp): a checkpoint of the project before each run, the Revert button after it.
    void ai_run_checkpoint_begin(AiRun& run, const std::string& task);   // in ai_start, before the agent thread exists
    void ai_run_checkpoint_finish(AiRun& run, AiChat& chat);             // when the run's result is drained: the "changed N files" item
    // Runs (one per chat, at most ai_max_runs() at a time). A run exists from ai_start until its result is drained.
    AiRun* ai_run_of(const std::string& chatId) const;
    bool ai_busy() const { return !aiRuns_.empty(); }                   // any chat has a run
    bool ai_chat_busy(const std::string& chatId) const { return ai_run_of(chatId) != nullptr; }
    bool ai_chat_running(const std::string& chatId) const;              // that chat's run is going (or waits for its worker)
    int ai_run_count() const { return static_cast<int>(aiRuns_.size()); }
    int ai_max_runs();                                                  // limits.maxConcurrentRuns of ai.json (and the project's)
    // The config a run of the open project uses: the editor's own (ai.json as loaded, or what a test put there) with the project's
    // AI settings (<project>/.factoria/ai/settings.json) applied when it has them and the user accepted them. Any thread. A project
    // with a settings file is re-read at most once a second unless `fresh` (a run starting): the panels ask every frame.
    Result<ai::AiConfig> ai_project_config(bool fresh = false);
    // The same without a copy: calls `use` with the config (valid during the call; `use` must not lock aiMu_). False, and the
    // project file's problem in `error`, when the project's file was accepted and is invalid now (ai.json changed): `use` is not called.
    bool ai_with_project_config(const std::function<void(const ai::AiConfig&)>& use, Error* error = nullptr, bool fresh = false);
    // What the Play button says while the assistant works: which chats.
    std::string ai_editing_note();
    int ai_last_revertable_run() const;                      // index of the active chat's newest Run item not reverted, or -1
    void ai_revert_request(const std::string& chatId, int item);  // opens the confirm dialog for a Run (Revert) or Revert (Undo revert) item
    void draw_ai_revert_dialog();
    void draw_ai_run_item(ChatItem& c, AiChat& chat, int index);  // a Run / Revert item of the transcript, with its button
    void ai_revert_apply(bool includeShared);
    void ai_remember_scene(const std::string& checkpointId, bool dirty);  // the world as it is now, for ai_revert_apply
    void ai_sync_chats();                     // the chat tabs belong to the open project: switch when it changed
    void ai_on_files_dropped();               // sokol file drop: images become pending attachments of the active chat
    void ai_attach_path(const std::string& path);
    void ai_add_pending(Result<ChatAttachment> attached);
    void ai_paste_image();                    // clipboard picture -> pending attachment (does nothing without one)
    std::shared_ptr<CommandRegistry> make_proxy_registry(AiRun& run);
    // Paid asset calls that wait for the user's yes (ai_asset_approval.h): the cards of `chat` under its transcript. `height` is
    // the room reserved for them (ai_asset_cards_height); the answers go to the waiting agent thread.
    float ai_asset_cards_height(const AiChat& chat, float availableY);
    void draw_ai_asset_cards(AiChat& chat, float height);
    void ai_asset_notify_other_chats();   // a card in a chat that is not in front: tell the user once
    MainThreadQueue& queue() { return queue_; }
    // True while any chat's run is going: an agent thread, or the wait for a delegated worker whose orchestrator turn already
    // ended.
    bool ai_running() const;
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
    bool pendingWelcome_ = false;  // close_project(): back to the welcome screen on the next frame
    std::string bootError_;
    bool gfxUp_ = false;
    bool uiUp_ = false;
    bool dirty_ = false;
    PlayState play_ = PlayState::Edit;
    struct PlayRun {
        bool active = false;
        PlaySession session;
        std::vector<double> frameMs;
        ProfileSummary profile;  // the profiler's numbers of the session (session.json "profile")
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
    // Which panels are open is saved with the layout (a [FactorIAEditor][Panels] section of the same ini file).
    int panelMask_ = -1;  // the mask last seen; -1 = not yet (the first frame after the ini is read does not count as a change)
    int panels_mask() const;
    void set_panels_mask(int mask);
    void register_layout_settings();
    const char* pendingFocus_ = nullptr;

    // viewport (ImGui logical coordinates; sokol event coordinates / dpi match them)
    ImVec2 vpImageMin_{0, 0}, vpImageSize_{1, 1};
    bool vpHovered_ = false, vpFocused_ = false;
    bool vpFocusNext_ = false;  // focus the Viewport window on its next draw (set when Play starts)
    bool vpMouseCaptured_[3] = {false, false, false};
    bool showColliders_ = true;
    bool showNav_ = false;                 // draw the NavMesh3D walkable cells (Window > Show navmesh)
    std::vector<NavLinkDraw> navLinks_;    // last links drawn (same rule as navCells_)
    std::vector<NavCell> navCells_;        // last cells drawn; kept while the mouse is down so a drag does not rebake each frame
    // gizmos (viewport_gizmo.cpp)
    GizmoMode gizmoMode_ = GizmoMode::Move;
    std::vector<GizmoShape> gizmoShapes_;  // this frame's handles (panel pixels); empty when no gizmo shows
    GizmoHandle gizmoHover_;
    struct GizmoDrag {
        bool active = false;
        GizmoHandle handle;
        GizmoMode mode = GizmoMode::Move;
        std::string id, key;
        Vec2 mouseStart{};
        Transform start;               // the entity's Transform when the drag began
        Vec3 last{};                   // the last value written (of the field the mode edits)
        Vec3 pivot{};
        Vec3 local[3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
        Mat4 parentWorld;
        bool hasParent = false, wrote = false, recorded = false;  // recorded: the edits went to a clip key (record mode)
        Vec3 planeStart{};             // free move: where the mouse was on the drag plane
        AngleTracker angle;
        float sign = 1;
        std::vector<Json> redoBefore;
        bool dirtyBefore = false;
    } gizmoDrag_;
    bool showOverlay_ = true;
    float dpi_ = 1.0f;

    // panel visibility
    bool showViewport_ = true;
    bool showConsole_ = true, showAi_ = true, showFeedback_ = true, showAudio_ = false, showProfiler_ = false, showProject_ = true;
    bool showAnimation_ = false, showBoneTools_ = false;
    bool showLevelGen_ = false;
    LevelGenSession levelGen_;
    LevelGenOptions levelGenOpt_;
    std::string levelGenKeepName_ = "generated", levelGenSavePath_ = "levels/generated.json", levelGenMessage_;
    bool levelGenMessageBad_ = false;
    std::string levelGenSaveTarget_, levelGenSaveContent_;   // the file Save asked about and what it would write (the Replace popup repeats it)
    bool levelGenReplaceOpen_ = false;                       // open the "Replace <file>?" popup this frame
    std::vector<int> levelGenSolid_;   // solid tile numbers of the sample, for the preview colours
    std::string levelGenSelId_;        // the selection levelGenSelTilemap_ was read for
    bool levelGenSelTilemap_ = false;  // the selected entity has a Tilemap
    bool levelGenSampleStale_ = true; // read the selection and the sample's Tilemap again (selection change, a command, an undo, a sample change)
    ProjectBrowser projBrowser_;
    bool showProjectDialog_ = false, showValidation_ = false, showDocs_ = false;
    bool showQuitDialog_ = false, showReloadConfirm_ = false;
    // Engine update (fa/editor/update.h): checked once when the editor opens. While a newer release is offered the
    // modal popup blocks the editor until Update or Not now; Update installs it, then the editor quits and reopens.
    enum class UpdateStage { Idle, Offer, Installing, Failed, Installed };
    std::atomic<UpdateStage> updateStage_{UpdateStage::Idle};
    UpdateInfo update_;           // written by updateThread_ before it sets Offer
    std::string updateError_;     // written before Failed
    std::atomic<float> updateProgress_{0};
    std::thread updateThread_;
    std::thread launcherThread_;  // refresh_launcher at start: an out-of-date Dock/menu launcher of this factoria
    bool restartAfterQuit_ = false;  // on_cleanup starts the updated editor

    // The program replaced on disk (tooling/self_update.h, docs/EDITOR.md "Updates"): files copied over the installation without
    // the updater above. A non-blocking notice offers Restart / Not now; poll_disk_update() looks every few seconds and when the
    // window gets focus.
    std::unique_ptr<UpdateWatch> diskWatchOwn_;  // the autotest's watch over a fake program; null = this process's own
    UpdateWatch& disk_watch() { return diskWatchOwn_ ? *diskWatchOwn_ : process_update_watch(); }
    double diskPolled_ = -100;
    bool diskPollNow_ = false;        // the window just got focus
    bool diskSettling_ = false;       // the file changed and was not seen twice alike yet: look again in a second
    FileStamp diskDismissed_;         // the file Not now was said to: the notice stays quiet until the file changes again
    bool diskDismissedSet_ = false;
    bool diskRestartRequested_ = false;  // the autotest: Restart was accepted (it must not really reopen the editor)
    void poll_disk_update();             // every frame (dialogs.cpp)
    bool disk_update_due();              // the notice is showing
    std::string disk_restart_blocker();  // why Restart is not possible now; "" = it is
    void request_disk_restart();         // quits (the unsaved-changes dialog still asks) and reopens on the same project
    void draw_disk_update_notice();
    std::string pendingScene_;  // open-scene request waiting for the unsaved-changes dialog
    std::string windowTitle_;   // what set_window_title last set ("FactorIA <version> — <project>")

    // Play sessions window
    bool showPlaySessions_ = false, playSessionsFocus_ = false, playSessionsDirty_ = true;
    std::atomic<bool> playSessionsOutside_{false};  // an AI agent thread ran play.auto (make_proxy_registry): the list reads the folder again
    AutoPlayJob autoPlay_;
    std::optional<AutoPlayOutcome> autoPlayLast_;  // the last run's outcome (an error stays under the button)
    double autoPlaySeconds_ = kAutoPlayDefaultSeconds;
    // Review window
    struct ReviewDeadTexture {
        std::uint32_t image = 0, view = 0;
        std::uint64_t frame = 0;
    };
    struct ReviewUi {
        bool show = false, wasShown = false, focus = false, listDirty = true, sheetDirty = false;
        std::uint64_t gen = 1;                       // the listing's generation (a project switch bumps it): older results are dropped
        std::uint64_t sheetGen = 1;                  // the shown sheet's generation (another sheet bumps it): its manifest and pictures
        bool listLoading = false, listLoaded = false;
        std::vector<ReviewListRow> rows;
        std::vector<ReviewHistoryRow> history;
        std::map<std::string, std::string> superseded;   // review_superseded(rows): an older candidates sheet -> the newest of its slot
        std::string listError;
        std::string sheetId;                         // the sheet shown ("" = the first in the list)
        bool sheetLoading = false;
        std::optional<ReviewSheetView> sheet;
        std::string sheetError;
        int selected = 0;
        int tab = 0, tabSet = -1;                    // 0 Sheet, 1 Compare, 2 History; tabSet selects one next frame
        float zoom = 0;                              // 0 = fit the window, else the scale of sheet.png
        int compareA = 1, compareB = 2;
        bool compareSource = true;                   // the candidates' own pictures (image items), else the thumbnails
        std::map<std::string, ReviewTextureSlot> textures;
        std::deque<ReviewLoaded> uploads;            // decoded pictures waiting for their frame (one upload a frame)
        // the pick
        bool confirmRequest = false, confirmOpen = false, keepFiles = false, pickPending = false;
        std::optional<ReviewSheetView> pickSheet;    // the sheet a running pick answers (a copy: the shown one can change meanwhile)
        ReviewPickPlan pickPlan;                     // ...its command and arguments
        int pickN = 0;
        std::uint64_t confirmFrame = 0;
        int confirmN = 0;
        std::string note;
        ReviewPickPlan plan;
        std::string pickMessage;                     // what the last pick did (or why it failed)
        bool pickBad = false;
        std::vector<std::string> pickLines;          // its moved files and warnings
        // the Level generator's sheet of seeds
        int seedsCount = kReviewSeedsDefault;
    };
    ReviewUi review_;
    std::vector<ReviewDeadTexture> reviewGraveyard_;
    ReviewLoader reviewLoader_;
    ChildCommandJob reviewSeedsJob_;
    ChildCommandJob reviewPickJob_;                // review.pick / assets.pick: they move files (with retries on Windows) and write manifests
    // Review sheets an AI module command made on an agent thread (make_proxy_registry): offered in a toast by poll_review.
    std::mutex reviewInboxMu_;
    std::vector<ReviewAnnounce> reviewInbox_;
    bool autoPlayPictures_ = true;
    std::vector<PlaySessionRow> playSessionRows_;
    std::string playSessionsPick_;                 // the folder shown in the report pane
    std::uint64_t playSessionsGen_ = 0;            // bumped at every listing: the report is re-read after it
    Json playSessionDoc_;
    std::string playSessionDocName_, playSessionDocError_;
    std::uint64_t playSessionDocGen_ = 0;

    // Export window
    bool showExport_ = false, exportFocus_ = false, exportScroll_ = false;
    ExportSettings exportSettings_;
    std::vector<ExportStatus> exportStatus_;  // one per export_targets() entry, refreshed every few seconds while shown
    double exportChecked_ = -100;
    ExportJob exportJob_;
    std::optional<ExportOutcome> exportLast_;  // the last export's report (or error), shown under the buttons
    ProjectExportSettings exportSaved_;        // what factoria.json says now (the Android row's format), read with the rows
    std::string exportSavedError_;             // why it could not be read ("" = fine)

    // Play on Phone window
    bool showPhone_ = false, phoneFocus_ = false;
    PhoneSession phone_;
    bool phoneStopPending_ = false;        // a project switch asked for the server to stop; poll_phone() starts the stop job
    std::string phoneError_, phoneHint_;   // why the last Start did not start the server
    std::string phoneQrUrl_;               // the address phoneQr_ was made for
    std::optional<QrCode> phoneQr_;
    int phoneUrlIndex_ = 0;                // which LAN address the code shows
    std::string phonePlayer_;              // ServeWebOptions::playerBinary ("" = the installed web player); the autotest sets a stand-in
    bool phoneAllowMismatch_ = false;      // ServeWebOptions::allowPlayerMismatch; the autotest's stand-in has no build fingerprint

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

    // Hierarchy / Inspector
    bool showHierarchy_ = true, showInspector_ = true;
    std::string hierFilter_;
    std::string hierRenameId_, hierRenameText_;   // the entity being renamed (popup)
    bool hierRenameOpen_ = false;                 // request to open the rename popup this frame
    std::string hierLastSelected_;                // selection the tree last scrolled to (a viewport click moves the tree)
    std::string hierRevealId_;                    // entity whose ancestors open and which scrolls into view next frame
    std::map<std::string, std::string> inspErrors_;  // field key -> the last refused edit's message (shown under the field)
    struct JsonBox {
        std::string text, error;
        bool dirty = false;   // the text differs from the value: the user is editing it (or it did not parse)
    };
    std::map<std::string, JsonBox> inspJson_;     // Json fields, by field key
    std::string inspEntity_;                      // entity the inspector showed last frame (state resets when it changes)
    std::string inspScrollTo_;                    // "Component" or "Component.field": scroll the Inspector to that row (the autotest)
    struct MaterialInfoEntry {
        Json info;
        std::string error;    // material.info failed (the file is unreadable or invalid)
        std::int64_t mtime = -2;
        double checkedAt = -1e9;
    };
    std::map<std::string, MaterialInfoEntry> materialInfo_;   // by material path
    Json assetReport_;                            // Renderer::asset_report(), refreshed twice a second
    double assetReportAt_ = -1e9;
    std::map<std::string, std::pair<double, std::vector<std::string>>> assetFiles_;  // asset type -> files, refreshed every 2 s

    // Audio panel (View > Audio): the live audio.log
    AudioLogState audioLog_;
    double audioPolled_ = -10;
    void poll_audio(bool force = false);

    // Profiler panel (View > Profiler) and the `profile` section of play sessions (fa/core/profiler.h). The profiler runs only while
    // a play session records or the panel is open; profile_tick() runs once per UI frame after the engine frame.
    ProfilerView profView_;
    int profMemoryIn_ = 0;  // frames until the next memory sample
    bool profShowThreads_ = false;  // select the Profiler's Threads tab on its next draw (autotest)
    void profile_tick(std::uint64_t frameBefore);

    // toasts
    std::vector<Toast> toasts_;
    bool toastHover_ = false;

    // feedback panel
    Json feedbackDoc_;
    std::string feedbackError_;
    std::int64_t feedbackMtime_ = INT64_MIN;
    bool feedbackRecheck_ = false;  // read once more next poll: a write right after the read may have kept the same time
    double feedbackPolled_ = -10;
    int fbStatus_ = 0, fbCategory_ = 0, fbSeverity_ = 0;
    std::string fbSelected_;
    // The closed entries (fixed, won't fix, duplicate, rejected) live in ENGINE_FEEDBACK.archive.json: the panel reads it too, shows
    // its entries when "closed" is ticked or a closed status is filtered, and keeps the detail windows of archived entries working.
    Json fbArchive_;
    std::int64_t fbArchiveMtime_ = INT64_MIN;
    bool fbShowClosed_ = false;
    // Detail windows: double-clicking a row opens one for that entry (several can be open at once; each is movable and resizable).
    std::vector<std::string> fbWindows_;
    // The question a status change or a delete asks first: why an entry is rejected (a reason is required), or "delete it?".
    struct FbAsk {
        std::string id;      // the entry
        std::string status;  // "rejected": asking for the reason | "delete": asking for the confirmation
        std::string reason;  // typed by the person
        std::string error;
        bool open = false;
    } fbAsk_;
    void draw_feedback_windows();                                    // the detail windows (after the panel)
    void draw_feedback_detail(const Json& entry, const std::string& path, bool inWindow);  // fields + share + actions of one entry
    void draw_feedback_actions(const Json& entry, const std::string& path);   // status combo, Copy, Delete (+ their popups)
    void feedback_reload_soon();                                     // read both files again, and run the share tick, next frame
    const Json* feedback_entry(const std::string& id) const;         // an entry of the file or of the archive (nullptr: none)
    bool fbAddOpen_ = false;        // the Add feedback modal is open
    int fbNewCategory_ = 0, fbNewSeverity_ = 1;
    std::string fbNewTitle_, fbNewMissing_, fbNewWorkaround_, fbNewSuggestion_, fbMessage_;
    // The Retrospective button (feedback_panel.cpp): ai.retrospective on a thread of its own (it asks a model, which takes seconds), one at a
    // time. The thread hands the answer over under `mu`; the panel applies it on the main thread and says what it filed.
    struct FbRetro {
        std::mutex mu;
        bool running = false;
        bool finished = false;       // an answer is waiting for the panel
        bool ok = false;
        std::string dir;             // the project the run was started for: an answer that arrives after another project was opened is dropped
        Json result;                 // the answer of ai.retrospective
        std::string message;         // why it failed (with the hint)
        CancelFlag cancel{false};
    };
    std::shared_ptr<FbRetro> fbRetro_ = std::make_shared<FbRetro>();
    std::thread fbRetroThread_;
    void feedback_start_retrospective();   // the button: the whole retrospective of this project's runs, off the UI thread
    void feedback_apply_retrospective();   // every frame: takes the answer of the thread, if there is one

    // AI
    MainThreadQueue queue_;
    std::mutex aiMu_;
    ai::AiConfig aiConfig_;
    std::mutex aiProjMu_;                       // the cache of ai_with_project_config(); never held while aiMu_ is taken
    std::string aiProjFileDir_;                 // the project whose settings file existence was checked ...
    long long aiProjFileAtMs_ = 0;              // ... when (steady-clock ms) ...
    bool aiProjHasFile_ = false;                // ... and what was found
    std::string aiProjKey_;                     // the project of the last resolution
    long long aiProjAtMs_ = 0;
    std::shared_ptr<const ai::AiConfig> aiProjConfig_;  // null: the resolution failed (aiProjError_)
    Error aiProjError_;
    std::uint64_t aiProjGen_ = 0;               // counts ai_project_invalidate() calls: a resolution started under an older count is not cached
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
    // The runs, one per chat that is working (main thread owns the vector; ai_runs.h says what is shared with the threads).
    std::vector<std::unique_ptr<AiRun>> aiRuns_;
    AssetApprovals aiApprovals_;    // paid asset calls waiting for the user's yes (any thread asks, the main thread answers)
    std::set<u64> aiCardNotified_;  // cards of other chats the user was told about
    std::vector<FileConflict> aiConflicts_;  // same-file conflicts found this frame, not yet written into the chats
    RunTouchTracker aiTouch_;       // main thread: which files each running chat changed (the same-file warning, Revert's scope)
    AiChats chat_;                  // the conversations (tabs); the active one is chat_.current()
    // The world as it was when a checkpoint was taken (before a run) or replaced (before a revert), by checkpoint id: restoring
    // that checkpoint puts the world back as ONE undo step. Memory only; after a restart the scene is read from disk instead.
    struct SceneAtCheckpoint {
        std::string id, scenePath;
        Json scene;
        bool dirty = false;
    };
    std::vector<SceneAtCheckpoint> aiScenes_;
    struct AiRevertRequest {
        bool open = false, shown = false, undo = false;
        std::string chatId, target, error;
        int item = -1, laterRuns = 0;
        CheckpointDiff diff;
        RevertPlan plan;            // what other chats' runs change about it (ai_runs.h)
        std::set<std::string> own;  // the files of the run and of its chat's later runs
        std::string scene;          // the open scene's file when the run (or a later one of the chat) changed the scene
    } aiRevert_;
    // The review job in progress (ai_review.cpp): N reviewers one after another, each in the same chat tab.
    struct AiReviewJob {
        bool active = false;
        std::string kind, role, focus, chatId;
        int count = 1, next = 0;            // reviewers asked for / index of the one that runs (or runs next)
        std::size_t itemStart = 0;          // chat items before the current reviewer's run
        double costBefore = 0;
        std::string provider, model;
        std::vector<std::string> savedIds;  // the reviews this job produced
        bool stopped = false;               // the current reviewer was stopped by the user (set when its run ends)
    } aiReview_;
    int aiReviewCount_ = 1;                 // the count the buttons use (1..kMaxReviewers)
    std::string aiReviewFocus_;             // what to look at ("" = everything)
    std::string aiReviewAsk_;               // the review kind ("art", "game") waiting for Start in the confirmation dialog
    bool aiReviewsShown_ = false;           // the "AI reviews" window
    std::vector<ai::Review> aiReviewList_;  // saved reviews, newest first (reloaded when aiReviewDirty_)
    bool aiReviewDirty_ = true;
    std::string aiReviewSelected_;          // id of the review whose report the window shows
    LimitsByProvider aiLimits_;     // plan windows reported since the editor started, shared by every tab
    int aiTabForce_ = 0;            // frames left to force the active tab (a tab opened/closed by code)
    bool aiHistoryOpen_ = false;    // request to open the History popup this frame
    std::vector<ChatHistoryEntry> aiHistory_;
    std::string aiHistoryDelete_;   // History row waiting for the second click on its Delete
    bool aiRolesOpen_ = false;      // request to restart the role edits from the loaded config this frame
    std::optional<ai::AiConfig> aiRolesBase_;  // the config aiRolesEdit_ started from (what the Roles tab showed): an edit is a row that differs from it
    bool aiRolesKeepEdits_ = false; // with aiRolesOpen_: the restart keeps the rows edited since aiRolesBase_ (a reload behind the window's back, Accept)
    float aiInputH_ = 0;            // the AI message box's height the user dragged it to (0 = 3 lines); kept in the layout file
    std::map<std::string, ai::RoleConfig> aiRolesEdit_;  // the roles being edited in the Roles tab
    std::set<std::string> aiRolesTyping_;                // roles whose model is a text box (Other... picked)
    bool showAiSettings_ = false, aiSettingsFocus_ = false;
    int aiSettingsTab_ = 0;         // tab to select next frame in the AI settings window: 0 none, 1 Roles, 2 Assets, 3 External tools, 4 Extensions, 5 Agents
    struct AiSettingsDraft {                       // the AI settings window's working copy (dropped when it closes: a typed key must not linger)
        bool loaded = false;
        std::string title;                         // the window's title as drawn last ("AI settings - This project: <name>")
        std::string project;                       // the project the draft was loaded for ("" = your defaults): a switch reloads it
        std::string path;                          // the ai.json it saves into
        ai::AiConfig base;                         // the config the routes and sources started from: an edit is a row that differs from it
        std::map<std::string, ai::AssetRoute> routes;  // by media kind name; provider "" = none (made procedurally)
        ai::AssetSources sources;
        std::map<std::string, std::string> keys;   // API keys typed this session, by provider (never shown, never logged)
        std::set<std::string> removeKey;           // providers whose stored key Save deletes
        std::map<std::string, std::string> command, args;  // asset-command providers: the program and its arguments line
        std::array<std::string, 5> newUrl, newNote;       // the "add a site" row of each category
        std::string siteError, saveError;
        // "Spending limits" (Assets tab): limits.maxAssetCostUsd.perRun / perDay and limits.askAboveUsd of ai.json, with their own Save.
        double limRun = 0, limDay = 0, limAsk = 0.5;
        std::string limError, limMessage;
        std::vector<ai::ProviderStatus> status;    // key / program checks, taken when the window loaded the file
        // The "External tools" tab: the user's tool servers (ai.json "mcpServers") being edited.
        struct ToolTests {                         // what the Test buttons found; shared with the thread that runs them
            std::mutex mu;
            std::map<std::string, std::string> text;   // by server name: "Connected: 3 tools..." / the error
            std::map<std::string, bool> ok;
            CancelFlag cancel{false};                  // set when the window closes: a running test stops waiting
        };
        struct ToolsDraft {
            std::vector<ai::ToolServer> servers;       // the working copy, in the order of the file
            int editing = -1;                          // index of the server in the form; -1 = form closed
            bool adding = false;                       // the form makes a new server
            ai::ToolServer edit;                       // the form
            std::string editHeaders, editArgs, editEnv;  // the form's multi-line / one-line text fields
            std::string editError;                     // why Apply refused
            bool showPaste = false;
            std::string pasteText, pasteName, pasteMessage;
            bool pasteFailed = false;
            std::string saveError;
            std::shared_ptr<ToolTests> tests = std::make_shared<ToolTests>();
            std::vector<std::string> inheritEnvGlobal;  // ai.json's top-level inheritEnv: a server made in the form or pasted gets it too (its Test inherits it)
        } tools;
        // The "Agents" tab: the permission mode of each CLI agent (ai.json providers.<name>.permissionMode).
        struct AgentsDraft {
            std::map<std::string, std::string> mode;   // by provider: the mode picked in the combo (only providers the person touched)
            std::string confirm;                       // the provider whose dangerous mode waits for the confirmation ("" = none)
            std::string message;                       // what the last Save did, or why it failed
            bool failed = false;
        } agents;
        // The "Extensions" tab: plugins, skill folders and hooks (ai.json "extensions" and the project's .factoria/extensions.json).
        struct ExtensionsDraft {
            std::vector<ai::Extension> user;           // the user's entries, the working copy
            bool inherit = true;                       // inheritUserPlugins
            std::vector<ai::Extension> project;        // the open project's entries (.factoria/extensions.json), the working copy
            bool projectExists = false;                // the project's file exists on disk
            std::string projectError;                  // why the project's file could not be read ("" = fine)
            std::string projectHash;                   // hash of the file as read; the trust applies to exactly this
            std::string claudeHash;                    // ClaudeProjectSettings::hash as read ("" = nothing in .claude runs a program)
            std::vector<std::string> claudeGrants;   // what in the project's .claude/settings*.json runs a program or widens what the AI may do (env, allowed tools)
            bool projectTrusted = false;               // the user trusted the project for projectHash + claudeHash
            std::vector<ai::Extension> userLoaded, projectLoaded;  // as saved, to tell what changed
            int addKind = 0;                           // the add row: 0 plugin folder or .zip, 1 skill folder, 2 installed plugin name@marketplace
            bool addToProject = false;                 // keep the new entry in the project's file instead of ai.json
            std::string addPath, addName, addError;
            bool showHooks = false;
            std::string hooksText, hooksName, hooksMessage;
            bool hooksFailed = false;
            bool showTrust = false;                    // the "what would run" list of the Trust this project step
            std::string saveError, trustMessage;
            std::map<std::string, std::string> status; // by "kind:source:name": why it cannot load ("" = ready), refreshed every second
            double statusAt = -10;
            Json hooksReport;                          // ai::hooks_report as saved + the runs of this process, refreshed every second
            double hooksAt = -10;
            std::vector<ai::SkillInfo> skills;         // every skill the Skills list shows (ai::scan_skills of the working copy), refreshed with `status`
            ai::Savers savers;                         // the token savers' switches, the working copy (ai.json "savers")
            Json saversReport;                         // ai::savers_report: this project's counts and the proposals, refreshed every second
            double saversAt = -10;
            std::string saversMessage;                 // what the last accept / decline did
        } ext;
    } aiSettings_;
    ai::ProviderFactory aiFactory_;  // test hook: replaces the real providers (autotest mock)
    ai::HttpTransport aiToolTransport_;  // test hook: the HTTP the External tools tab's Test button uses (empty = the network)
    std::thread aiToolTestThread_;       // the running Test of a tool server (one at a time)
    std::atomic<bool> aiToolTestRunning_{false};
    void draw_ai_tools_tab(const ai::AiConfig& cfg, bool configReadable);
    void ai_tool_form_open(int index);    // opens the form on server `index` (-1: a new one)
    Result<ai::ToolServer> ai_tool_form_build() const;  // the form as a server, validated like ai.json would
    void ai_tool_test(const ai::ToolServer& server);    // Test button: connects off the main thread, writes the draft's ToolTests
    void ai_settings_discard();  // closes the draft (stops a running Test)
    // Loads what the files say now into the open window without losing what the person typed (ai_project_edit.h, ai_*_keep_edits): the
    // rows they changed stay, the others show the new values. userChanged: ai.json changed too, so the providers' programs and the External
    // tools / Extensions tabs show the file again. true when something unsaved was kept.
    bool ai_settings_reload_keeping_edits(bool userChanged);
    void ai_settings_save_assets(bool asDefaults);  // Save / Save as my defaults of the Assets tab
    void draw_ai_extensions_tab(const ai::AiConfig& cfg, bool configReadable);  // ai_extensions.cpp
    void draw_ai_agents_tab(const ai::AiConfig& cfg, bool configReadable);      // ai_permissions.cpp: the permission mode of each CLI agent
    void ai_agents_reload();                                                    // ai_permissions.cpp: after a save, the editor follows ai.json
    // The Add TokenEconomizer section of that tab (ai_economizer.cpp): a dry run of ai::plugin_install says what is installed, the button
    // asks first, the install runs on its own thread and the result lands in the draft. One job at a time.
    struct AiPluginJob {
        std::mutex mu;
        bool running = false;        // a thread works (a dry run or an install)
        bool installing = false;     // the running thread installs (its steps are in `lines`)
        bool probeDone = false;      // `probe` / `probeError` hold the answer of the last dry run
        Json probe = Json::object();  // ai::plugin_install dry-run report
        std::string probeError;      // why the dry run failed ("" = it did not)
        std::vector<std::string> lines;  // an install's progress, one line per step event
        bool finished = false;       // an install ended and the UI has not applied it yet
        bool ok = false;
        std::string message;         // the install's result (or error with its hint)
        CancelFlag cancel{false};
    };
    std::shared_ptr<AiPluginJob> aiPluginJob_ = std::make_shared<AiPluginJob>();
    std::thread aiPluginThread_;
    std::vector<std::string> aiPluginPython_;  // test hook: the Python programs ai::plugin_install tries (empty = python3 / python)
    bool aiEconomizerConfirm_ = false;         // the confirmation of Add TokenEconomizer is open
    bool aiPluginProbeInTest_ = false;         // test hook: the autotest lets the tab ask the real CLI only in the section that fakes it
    bool aiEconomizerOk_ = true;
    std::string aiEconomizerMessage_;          // what the last install did (or why it failed)
    void draw_ai_economizer_view(const ai::AiConfig& cfg, bool configReadable);
    void ai_plugin_start(const ai::AiConfig& cfg, const ai::PluginInstallRequest& request, bool install);  // off the UI thread
    void draw_ai_savers_view(const ai::AiConfig& cfg);  // the Token savers section of that tab: switches, judge, proposals
    void draw_ai_hooks_view(const Json& report);        // the Hooks section of that tab: handlers and recent runs
    void ai_extensions_load(const ai::AiConfig& cfg);   // the Extensions draft from the loaded config and the open project's file

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
    std::unique_ptr<AiRun> atMarshalRun_;  // the run whose proxy the marshaling check calls
    std::atomic<bool> atMarshalDone_{false};
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
    void at_track_at(const std::string& name, Vec2 centre, bool enabled = true);  // a point inside the last item (a part of it)
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
    // A step aims at a widget that is drawn but scrolled out of its window (a small screen): at_widget names it here, at_track
    // scrolls its window to it, and the step runs again once it is shown. A second miss on the same widget is a failure.
    bool atInStep_ = false;
    bool atStepRetry_ = false;
    std::string atScrollTo_;
    std::vector<std::function<void()>> atPostFrame_;       // run once after the UI was drawn (swapchain read-back)
    Image atShotBefore_;
    std::uint64_t atAudioAfter_ = 0;
    std::size_t atAudioBase_ = 0;
    void at_build_tools_script();
    void at_run_steps(int frame);
    bool capture_window(Image& img);
    void inject_key(int type, int keyCode);
    void inject_char(unsigned codepoint);   // a typed character (sapp CHAR event): what an InputText receives
    Vec2 atMouse_{};
    std::uint32_t atMods_ = 0;     // SAPP_MODIFIER_* the injected events carry (Ctrl held while the script drags)
    std::string atDeleteProject_;  // scratch project the autotest deletes through the Open project dialog
    size_t atUndoBeforeAi_ = 0;
    bool atWaitAi_ = false;
    std::vector<ai::ProviderStatus> atSavedStatus_;
    std::string atQFake_, atQArgv_;  // section Q: the fake Claude Code and the file it records its argv and stdin in
    std::optional<ai::AiConfig> atSavedConfig_;  // the AI config while the CLI-agent check swaps in the fake Claude Code
    int atWaitCount_ = 0;  // frames a wait has held the script; 0 = a new wait (a step sets it)
    std::chrono::steady_clock::time_point atWaitStart_;  // when that wait began: waits are bounded in time, not frames
    bool at_keep_waiting();
    // A frame that never ends (a GPU read-back that waits for ever) would leave the window frozen on the user's screen: the
    // watchdog thread ends the process when the editor draws no frame for a minute (on_init starts it, only in the autotest).
    std::atomic<std::uint64_t> atHeartbeat_{0};
    std::atomic<bool> atWatchdogStop_{false};
    std::thread atWatchdog_;
    int atFrameBudget_ = 4000;  // the autotest must be done by this frame (a real download, in the manual check, needs more)
    float atLayoutWidth_ = 0;      // section U: the width of the Hierarchy after the user's change
    int atReopenIn_ = 0;           // section U: frames on the welcome screen before the project is opened again
    std::string atReopenDir_;
    std::string atIniSaved_;       // section U: the layout file the editor really uses, put back at the end
    std::function<bool()> atWaitUntil_;  // holds the script (like atWaitAi_) until it returns true
    // What atWaitUntil_ waits for, in words (set next to it by a wait that wants to be honest): when the 60 s run out, the
    // autotest fails with "waited 60 s for <this>"; empty = the wait expires with only a warning in the log.
    std::string atWaitWhat_;
    void save_screenshot_now(const std::string& path);
    // FA_EDITOR_AUTOTEST_SECTIONS (autotest_sections.h, read by run()): the sections to run, empty for all of them.
    std::set<std::string> atSections_;
    bool at_section_selected(const std::string& id) const { return atSections_.empty() || atSections_.count(id) > 0; }
    // What each section cost (autotest_result.json, and a table on stdout at the end): every frame drawn while it ran, the
    // frames the script held for a condition included, its seconds and its failed checks.
    struct AtSectionCost {
        std::string id;
        std::uint64_t frames = 0;
        double seconds = 0;
        std::size_t failures = 0;
    };
    std::vector<AtSectionCost> atCosts_;
    std::uint64_t atFramesDrawn_ = 0;  // every autotest frame (atFrame_ does not count the held ones)
    std::uint64_t atSectionFrame0_ = 0;
    std::chrono::steady_clock::time_point atSectionStart_{};
    std::size_t atSectionFailures0_ = 0;
    void at_section_begin(const std::string& id);  // ends the running section's cost record (if any) and starts id's
    Json at_section_report();                      // ends the last record, prints the table, returns the records as JSON
};

// Helpers shared across panel files.
extern Editor* g_editor;
// Puts the next button on the line of the previous item when it fits in the window, else on a new line: a row of buttons that
// wraps in a small window instead of running out of it. Call it right before the button, after the previous item.
inline void fit_same_line(const char* nextLabel) {
    const ImGuiStyle& st = ImGui::GetStyle();
    const float w = ImGui::CalcTextSize(nextLabel, nullptr, true).x + st.FramePadding.x * 2;
    const float right = ImGui::GetCursorScreenPos().x + ImGui::GetContentRegionAvail().x;
    if (ImGui::GetItemRectMax().x + st.ItemSpacing.x + w <= right) ImGui::SameLine();
}

// The first size of a window that is centred on the main viewport: `wanted`, made smaller to fit its work area so the
// window's own buttons (Save, Close...) are never off screen on a small display.
inline ImVec2 fit_work_area(ImVec2 wanted) {
    const ImGuiViewport* vp = ImGui::GetMainViewport();
    return ImVec2(std::min(wanted.x, vp->WorkSize.x * 0.96f), std::min(wanted.y, vp->WorkSize.y * 0.96f));
}
// The first place of a large panel that floats the first time it opens (Image, Sound, Music, Modeler): `pos` (from the
// work area's corner) and `wanted`, the size made to fit the work area and the place moved up and left so the whole
// window is on screen, its right-hand inspector included, on a small display (the macOS CI runner's is 1024 x 642).
inline void first_floating_window(ImVec2 pos, ImVec2 wanted) {
    const ImGuiViewport* vp = ImGui::GetMainViewport();
    const ImVec2 size = fit_work_area(wanted);
    const float x = std::max(0.0f, std::min(pos.x, vp->WorkSize.x - size.x));
    const float y = std::max(0.0f, std::min(pos.y, vp->WorkSize.y - size.y));
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + x, vp->WorkPos.y + y), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(size, ImGuiCond_FirstUseEver);
}
// Status colours of the Export and Platform settings windows.
inline const ImVec4 kStatusReady(0.5f, 0.9f, 0.55f, 1), kStatusFailed(1, 0.45f, 0.4f, 1), kStatusWarn(1, 0.8f, 0.35f, 1);
inline const ImVec4 kProjectBlue(0.55f, 0.75f, 1.0f, 1.0f);  // "This project" in the AI settings rows
// The window title: "FactorIA <version> — <project name>", or "FactorIA <version>" with no project open (the Open or
// create a project dialog). `version` is the engine's, FA_ENGINE_VERSION: what `factoria version` prints.
std::string editor_window_title(std::string_view version, std::string_view projectName);
// While the game runs the Hierarchy and Inspector edit the running game: say they are lost on Stop (hierarchy_panel.cpp).
void draw_play_banner(const Editor& ed);
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
// Opens an https:// address in the default browser without waiting. Returns "" or what went wrong.
std::string open_url(const std::string& url);

}  // namespace fa::editor
