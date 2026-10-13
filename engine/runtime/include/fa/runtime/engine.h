// Engine: owns every subsystem and runs the game loop.
//
// One frame (Engine::frame):
//   input.begin_frame (events were fed by the platform/injection)
//   N x fixed step @ fixedHz:  scripts.fixed_update -> physics.step -> scripts.dispatch_events
//   scripts.update(dt) -> animators/particles -> audio.update -> scripts.late_update
//   renderer: begin_frame -> render_world -> end_frame
//   world.flush() (deferred destroys), pending scene change, hot-reload poll
//
// Headless + deterministic (Engine::step): every frame advances exactly
// 1/fixedHz seconds with one fixed step, so a run with the same seed and the
// same injected input always produces the same state and pixels.
//
// Built-in commands (registered in init, exposed to MCP/AI/CLI):
//   engine.info, project.info, scene.list_entities, scene.get_entity,
//   scene.spawn, scene.destroy, scene.set_component, scene.remove_component,
//   scene.load, scene.save, scene.reload, game.step, game.input, game.screenshot,
//   game.state, game.logs, game.pause, game.resume, script.eval, script.errors,
//   physics.raycast, api.components, api.commands, api.scripting, assets.list
#pragma once

#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/audio/audio.h"
#include "fa/core/command.h"
#include "fa/physics/physics.h"
#include "fa/platform/app.h"
#include "fa/platform/input.h"
#include "fa/render/renderer.h"
#include "fa/runtime/project.h"
#include "fa/scene/world.h"
#include "fa/script/script.h"

namespace fa {

struct EngineConfig {
    std::string projectDir = ".";  // folder containing factoria.json
    std::string scene;             // start scene override ("" = project mainScene)
    bool headless = false;         // no window; offscreen GPU (HeadlessGpu)
    bool graphics = true;          // false = no GPU at all (pure logic tests); renderer() == nullptr
    bool audioDevice = true;       // false = null audio device (always false when headless)
    int width = 0, height = 0;     // override design resolution (0 = project)
    std::uint64_t seed = 1;        // world RNG seed
    bool hotReload = true;         // watch scripts/scenes/assets (desktop, not headless)
    bool editorMode = false;       // editor drives the loop; game starts paused
};

class Engine final : public ScriptHost {
public:
    Engine();
    ~Engine() override;

    // Loads the project, creates subsystems and loads the start scene. In
    // windowed mode call this from the AppDesc.init callback (GPU ready).
    bool init(const EngineConfig& config, const GfxEnvironment* gfx, std::string* error);
    void shutdown();

    // Variable-dt frame (windowed). Uses a fixed-step accumulator.
    void frame(double dt);
    // Deterministic frames of exactly 1/fixedHz (headless, tests, AI agents).
    void step(int frames = 1);

    bool load_scene(std::string_view path, std::string* error);  // immediate
    void reload_scene();

    // State
    bool paused() const;
    void set_paused(bool paused);
    std::uint64_t frame_index() const;
    bool quit_requested() const;

    // Screenshot of the game target (PNG). Works headless and windowed.
    bool screenshot(std::string_view path, std::string* error) override;
    // JSON dump of the world for AIs: entities, components, physics, logs, errors.
    Json state(const Json& query = Json::object());

    const ProjectSettings& project() const;
    const EngineConfig& config() const;
    HeadlessGpu* headless_gpu();

    // ScriptHost
    World& world() override;
    Input& input() override;
    Audio& audio() override;
    Physics& physics() override;
    Renderer* renderer() override;
    CommandRegistry& commands() override;
    Json project_settings() const override;
    double fixed_dt() const override;
    void request_scene_change(std::string_view scenePath) override;
    void request_quit() override;
    void step_frames(int n) override;
    std::string load_scene_now(std::string_view scenePath) override;

    ScriptSystem& scripts();

    struct Impl;
    Impl& runtime_impl() { return *impl_; }  // internal (runners, commands)

private:
    std::unique_ptr<Impl> impl_;
};

// Builds the AppDesc that runs `config`'s project in a window: title/size/fullscreen/vsync come from factoria.json,
// the callbacks own a heap Engine (init on AppDesc.init with app_gfx_environment(), frame, resize/focus events,
// shutdown on cleanup). Also used by the mobile player: fa::to_sapp_desc(make_app_desc(cfg)). `config.projectDir`
// may be "" when the platform layer already configured the VFS root (iOS/Android bundles).
AppDesc make_app_desc(const EngineConfig& config);

// Opens a window and runs the project until closed (= run_app(make_app_desc(config))). Returns process exit code.
int run_windowed(const EngineConfig& config);

// Runs headless for `frames` frames, optionally injecting input from a replay
// JSON and capturing screenshots. Returns exit code (non-zero if script errors).
//
// Input replay format (frame numbers are 0-based; an entry is applied BEFORE that frame is simulated, and a
// screenshot listed for frame N is taken AFTER frame N was simulated):
//   { "frames": {
//       "0":  { "press": ["jump"],            // action names (held until released) or key names
//               "release": [],
//               "keys":  { "Space": true },    // raw key down/up
//               "mouse": { "position": [640, 360], "left": true, "right": false, "middle": false } },
//       "30": { "release": ["jump"] } } }
// "press"/"release" accept action names (virtual action override) and key names ("Space", "A", "MouseLeft"...).
//
// Report JSON: {frames, scriptErrors: [string], sceneErrors: [string], logErrors: n, screenshots: [absolute paths],
// statePath?, audioPath?, error?, exitCode}.
struct HeadlessRunOptions {
    int frames = 60;
    std::string inputReplayPath;          // optional
    std::vector<int> screenshotFrames;    // frame indices to capture
    std::string screenshotPattern = ".factoria/screenshots/frame_{frame}.png";
    std::string stateOutPath;             // optional JSON state dump at the end
    std::string audioOutPath;             // optional WAV recording
    bool failOnScriptError = true;
};
int run_headless(const EngineConfig& config, const HeadlessRunOptions& options, Json* report = nullptr);

}  // namespace fa
