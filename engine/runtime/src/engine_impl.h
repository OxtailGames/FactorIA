// Private state of fa::Engine, shared by engine.cpp, commands.cpp and runners.cpp.
#pragma once

#include <chrono>
#include <map>
#include <memory>
#include <optional>
#include <utility>
#include <string>
#include <vector>

#include "fa/core/i18n.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/input_recorder.h"
#include "fa/scene/rich_text.h"
#include "fa/scene/serialize.h"
#include "fa/services/platform.h"
#include "fa/ui/ui.h"

namespace fa {

constexpr double kMaxFrameDt = 0.25;  // Engine::frame clamps dt to this (a replayed frame too)

// The game window as scripts see it (`window.*`): fa/platform/app.h plus the frame cap. Engine::window() hands it out only
// for a game that owns a window (not headless, not the editor's game view); window_control.cpp.
class AppWindowControl final : public WindowControl {
public:
    std::string mode() const override;
    bool supports_modes() const override;
    bool supports_monitors() const override;
    std::vector<WindowMonitor> monitors() const override;
    void size(int& width, int& height) const override;
    void display_size(int& width, int& height) const override;
    bool vsync() const override;
    int frame_cap() const override { return cap_; }
    std::string set_mode(const std::string& mode) override;
    std::string set_monitor(int index) override;
    std::string set_size(int width, int height) override;
    std::string set_vsync(bool on) override;
    std::string set_frame_cap(int fps) override;

    // Called at the start of every frame of the window: waits until 1 / frame_cap() seconds passed since the previous
    // frame started (nothing when the cap is 0). Only the real-time pacing changes, never the simulation.
    void throttle();

private:
    int cap_ = 0;
    std::chrono::steady_clock::time_point last_{};
};

// The clipboard of an Engine (Engine::clipboard()): the system one for a game that owns a window, an in-memory one for every
// other run, so tests and replays do not depend on what the machine has copied. Can log what reads returned, which is what an
// editor play session records into its replay ("clipboard" per frame) so the run plays back the same.
class EngineClipboard final : public Clipboard {
public:
    void use_system(bool on) { system_ = on; }
    bool supported() const override { return system_ ? system_clipboard().supported() : true; }
    std::string get() override {
        std::string text = system_ ? system_clipboard().get() : memory_.get();
        if (logging_) reads_.push_back(text);
        if (recorder_) recorder_->clipboard_read(text);
        return text;
    }
    void set_recorder(InputRecorder* recorder) { recorder_ = recorder; }
    void set(const std::string& text) override {
        if (system_) system_clipboard().set(text);
        else memory_.set(text);
    }
    void log_reads(bool on) {
        logging_ = on;
        reads_.clear();
    }
    std::vector<std::string> take_reads() { return std::exchange(reads_, {}); }

private:
    bool system_ = false;
    bool logging_ = false;
    InputRecorder* recorder_ = nullptr;  // the input recorder: a read is part of the replay
    MemoryClipboard memory_;
    std::vector<std::string> reads_;
};

struct Engine::Impl {
    Engine* self = nullptr;
    EngineConfig cfg;
    std::uint64_t logSeqAtInit = 0;  // state() only reports logs emitted by THIS engine
    ProjectSettings project;
    bool initialized = false;
    bool windowed = false;  // GPU comes from the platform window (GfxEnvironment passed to init)

    World world;
    Input input;
    Physics physics;
    Audio audio;
    ScriptSystem scripts;
    UiSystem ui;
    std::function<Vec2(Vec2)> designToWindow;  // Engine::set_design_to_window; empty = design pixels
    PlatformServices platform;  // achievements, purchases, ...: the catalog of factoria.json and the backend (platform_backend.h)
    I18n i18n;                  // string tables and the current language (factoria.json "localization"); off without the section
    CommandRegistry commands;
    std::unique_ptr<HeadlessGpu> gpu;
    std::unique_ptr<Renderer> renderer;
    std::unique_ptr<AppWindowControl> appWindow;  // windowed game only
    EngineClipboard clipboard;
    InputRecorder recorder;  // the Input observer; records only between start_input_recording and stop_input_recording

    // Scene props (scene.load(path, {props}), `factoria run --props`): the running scene's, and the ones the next load takes.
    // A load takes `nextProps` when there are some; else a reload (keepProps) keeps the current ones; else a load gives {}.
    Json sceneProps = Json::object();
    std::optional<Json> nextProps;
    bool pendingKeepProps = false;  // the scene change scheduled for the end of the frame is a reload
    void take_scene_props(bool keepProps);

    double heldScale = 1.0;         // Engine::hold_render_scale: the render scale between captures
    bool renderStale = false;       // OnDemand: simulated since the last draw
    double lastRenderDt = 0.0;
    std::uint64_t renderedFrame = 0;  // frame index at the last draw
    std::uint64_t frame = 0;
    std::uint64_t fixedStep = 0;  // fixed simulation steps run so far (several per frame when the frame was slow)
    bool paused = false;
    bool quit = false;
    bool inFrame = false;  // between the start and the end of run_frame (commands defer risky work)
    double accumulator = 0.0;
    double fixedDt = 1.0 / 60.0;
    std::string pendingScene;
    bool hasPendingScene = false;
    std::string currentScene;
    // The current scene is the project's mainScene, loaded at start because no start scene was given (no EngineConfig::scene),
    // and no scene was loaded since. scene.import_ascii refuses `save` without `path` then: see level_commands.cpp.
    bool implicitStartScene = false;
    std::vector<std::string> sceneIssues;  // every LoadMessage of the last scene load (errors + warnings)
    std::size_t sceneErrorCount = 0;
    std::vector<std::string> startupProblems;
    RichTextStyle richStyle;  // the project's "text" section: markup colours, icons, bold faces (empty when absent or broken)
    int pluginSteamDeck = -1;  // what a plugin said about the Steam Deck (plugin API 4): -1 nothing, 0 no, 1 yes

    // Hot reload
    std::map<std::string, std::int64_t> watched;
    bool watchSeeded = false;
    double watchTimer = 0.0;
    std::int64_t projectMtime = -1;  // factoria.json mtime when I.project was last read

    // Lifecycle helpers
    void run_frame(double dt, int fixedSteps);
    void render(double dt);       // per-frame: draws in Always mode, only simulates visuals in OnDemand
    void draw(double dt);         // draws the world now
    void finish_scene_load(const LoadReport& report, const std::string& label, std::string* error);
    bool load_scene_json_impl(const Json& scene, std::string_view sourceName, std::string* error);
    void end_of_frame(double dt);
    bool load_scene_impl(const std::string& path, std::string* error, bool keepProps = false);
    void refresh_from_disk();  // factoria.json (input actions, ...) and script modules that changed on disk
    void apply_project_settings();
    std::optional<UiTooltipSettings> appliedProjectTooltip;  // the project's tooltip delay and look last applied
    std::optional<bool> appliedProjectMirrorRtl;  // the project's ui.mirrorRtl last applied
    float appliedProjectUiScale = -1.0f;  // the project's ui.scale last applied; -1 before the first time
    // Localization (localization.cpp). setup: configure, read locales/*.json, choose the start language. apply: rewrite the
    // text of every component with a `key`. switch_language: i18n.set_language + apply + the "i18n.change" game event.
    void setup_localization();
    void reload_localization();  // read locales/*.json again (hot reload) and rewrite the texts
    void apply_localization();
    Result<std::string> switch_language(std::string_view requested);  // the language now in use, or why not
    void apply_fallback_fonts();  // the renderer's fallback fonts for the language in use (localization.fallbackFonts / languageFonts)
    Vec2 design_size() const;       // the renderer's target size (UI anchors are fractions of it); without one the project's
    VisualMeasure measure() const;  // text sizes from the renderer, else the approximation
    void poll_hot_reload(bool force = false);
    void apply_scene_change();

    // Input injection by name: action ("jump"), key ("Space") or mouse button ("MouseLeft").
    // Returns false (and a message) for an unknown name.
    bool inject_named(const std::string& name, bool down, std::string* error);
};

// The "gamepad" / "touch" members of an input replay frame (--input) and of game.input: one object or an array of them.
//   gamepad: {"index": 0, "connected": true, "buttons": {"A": true}, "axes": {"LeftX": -1}}
//   touch:   {"id": 1, "position": [x, y], "down": true}  (down on a new id begins, on a known id moves; false lifts)
// Valid parts are applied; every problem (wrong type, unknown field/button/axis with "did you mean") is appended to
// `problems` without a prefix naming the caller.
void apply_gamepad_json(Input& input, const Json& value, std::vector<std::string>& problems);
void apply_touch_json(Input& input, const Json& value, std::vector<std::string>& problems);

void register_builtin_commands(Engine& engine, Engine::Impl& impl);
void register_level_commands(Engine& engine, Engine::Impl& impl);  // level_commands.cpp: scene.import_ascii
void register_scene_file_commands(Engine& engine, Engine::Impl& impl);  // scene_file_commands.cpp: prefab.save, scene.format
void register_play_session_commands(Engine& engine, Engine::Impl& impl);  // play_sessions.cpp: play.sessions, play.report
void register_i18n_commands(Engine& engine, Engine::Impl& impl);  // localization.cpp: i18n.state, i18n.set_language
void register_ui_check_commands(Engine& engine, Engine::Impl& impl);  // ui_check.cpp: ui.check_layout
void register_shot_commands(Engine& engine, Engine::Impl& impl);  // shot_commands.cpp: game.screenshot, render.inspect, render.pick
void register_anim_commands(Engine& engine, Engine::Impl& impl);  // anim_commands.cpp (+ anim_view_commands.cpp): anim.*
void register_bones_commands(Engine& engine, Engine::Impl& impl);  // bones_commands.cpp: bones.create, skin.*

// Entity named by the string argument `key` (id or name). Throws CommandError("not_found") with a "did you mean".
Entity need_entity(World& world, const Json& args, const char* key = "id");

// scene.set_component on any World: `args` = {id, component, fields?}. Adds the component if missing and patches the given
// fields (all-or-nothing). Throws CommandError (not_found / invalid_argument) with did-you-mean. Returns {id, component, value}.
Json set_component(World& world, const Json& args);

}  // namespace fa
