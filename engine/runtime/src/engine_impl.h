// Private state of fa::Engine, shared by engine.cpp, commands.cpp and runners.cpp.
#pragma once

#include <chrono>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "fa/runtime/engine.h"
#include "fa/scene/serialize.h"
#include "fa/ui/ui.h"

namespace fa {

constexpr double kMaxFrameDt = 0.25;  // Engine::frame clamps dt to this (a replayed frame too)

// The game window as scripts see it (`window.*`): fa/platform/app.h plus the frame cap. Engine::window() hands it out only
// for a game that owns a window (not headless, not the editor's game view); window_control.cpp.
class AppWindowControl final : public WindowControl {
public:
    bool fullscreen() const override;
    void size(int& width, int& height) const override;
    void display_size(int& width, int& height) const override;
    bool vsync() const override;
    int frame_cap() const override { return cap_; }
    std::string set_fullscreen(bool on) override;
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
    CommandRegistry commands;
    std::unique_ptr<HeadlessGpu> gpu;
    std::unique_ptr<Renderer> renderer;
    std::unique_ptr<AppWindowControl> appWindow;  // windowed game only

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
    bool load_scene_impl(const std::string& path, std::string* error);
    void refresh_from_disk();  // factoria.json (input actions, ...) and script modules that changed on disk
    void apply_project_settings();
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

// Entity named by the string argument `key` (id or name). Throws CommandError("not_found") with a "did you mean".
Entity need_entity(World& world, const Json& args, const char* key = "id");

// scene.set_component on any World: `args` = {id, component, fields?}. Adds the component if missing and patches the given
// fields (all-or-nothing). Throws CommandError (not_found / invalid_argument) with did-you-mean. Returns {id, component, value}.
Json set_component(World& world, const Json& args);

}  // namespace fa
