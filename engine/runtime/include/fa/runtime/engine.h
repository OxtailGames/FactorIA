// Engine: owns every subsystem and runs the game loop.
//
// One frame (Engine::frame):
//   input.begin_frame (events were fed by the platform/injection)
//   N x fixed step @ fixedHz:  scripts.fixed_update -> physics.step -> scripts.dispatch_events
//   ui.update (layout, focus, widget events) -> scripts.dispatch_events
//   scripts.update(dt) -> animators/particles -> audio.update -> scripts.late_update
//   physics.step and animators/particles are scaled by scripts.time_scale() (game.paused: frozen)
//   renderer: ui.layout -> begin_frame -> render_world -> end_frame
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
//   game.state, game.logs, game.pause, game.resume, audio.log, ui.state, script.eval, script.errors,
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

// When Engine::step/frame draws the world.
//   Always:   every frame is drawn (windowed play, the editor).
//   OnDemand: every frame is SIMULATED (scripts, physics, audio, animators/particles via Renderer::update) but the
//             world is only drawn when a picture is requested: Engine::screenshot() (and game.screenshot) draws the
//             current state first, Engine::render_now() draws explicitly, and a headless `factoria run` draws its
//             last frame. A screenshot at frame N is pixel-identical in both modes. Headless tests and
//             `factoria call/session` use OnDemand (software rendering costs ~40 ms/frame); camera helpers
//             (Renderer::world_to_screen) need a drawn frame, so Engine::renderer() (what scripts reach them through)
//             draws the current state first when frames were simulated since the last draw.
enum class RenderMode { Always, OnDemand };

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
    RenderMode renderMode = RenderMode::Always;
    // Isolate script storage (the `storage` module) in memory: nothing is read from or written to disk. Headless
    // runs and tests set this so runs do not leak state into each other (needs ScriptSystem::set_storage_mode).
    bool memoryStorage = false;
    // Where the native plugins' libraries are (fa/runtime/plugins.h): an exported game keeps them next to its executable.
    // "" = in each plugin's folder (factoria.json "plugins"), as `factoria run`, the editor and tests use them.
    std::string pluginDir;
    // Which backend answers the game's `platform` calls (docs/PLATFORM.md, "Which backend runs"): "" = automatic (the store
    // plugin the game declares, else platformFallback), "fake" (deterministic, in memory: headless runs, tests, `factoria
    // call/session` and the MCP server always use it), "none", or the name of a plugin that registered a backend.
    std::string platformBackend;
    // What automatic falls back to when no plugin offers a backend: "fake" (development: purchases are not real) or "none"
    // (exported games: a shipped game must never get free purchases from the fake).
    std::string platformFallback = "fake";
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
    // Replaces the world with a scene given as JSON (immediate; `sourceName` is only used in messages). Unlike
    // load_scene it does NOT change the current scene path (engine.info / game.state / scene.save / scene.reload keep
    // pointing at the file being edited), so editors can restore snapshots without temp files.
    bool load_scene_json(const Json& scene, std::string_view sourceName, std::string* error);
    void reload_scene();

    // State
    bool paused() const;
    void set_paused(bool paused);
    std::uint64_t frame_index() const;
    std::uint64_t fixed_step_index() const;  // fixed simulation steps run so far (frame(dt) runs 0..5 of them)
    bool quit_requested() const;

    // Applies one input-replay entry ({"press":[..],"release":[..],"keys":{..},"mouse":{..}}, format in
    // HeadlessRunOptions below) to the input state; problems (unknown names...) are appended to `problems`.
    void apply_input_entry(const Json& entry, std::vector<std::string>& problems, int frame = 0);

    // Draws the current state now when it has not been drawn yet (RenderMode::OnDemand); no-op otherwise.
    void render_now();
    // True when frames were simulated since the last draw (always false in RenderMode::Always).
    bool render_pending() const;

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
    UiSystem* ui() override;
    CommandRegistry& commands() override;
    Json project_settings() const override;
    double fixed_dt() const override;
    WindowControl* window() override;  // nullptr unless the game owns a real window (not headless, not the editor)
    PlatformServices* platform_services() override;
    void request_scene_change(std::string_view scenePath) override;
    void request_quit() override;
    void step_frames(int n) override;
    void set_text_scale(float scale) override;  // also the renderer's
    std::string load_scene_now(std::string_view scenePath) override;
    std::string load_scene_json_now(const Json& scene, std::string_view sourceName) override;

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
//       "30": { "release": ["jump"] } },
//     "timing": [[0.0167, 1], [0.05, 3]] }     // optional: frame N runs with that dt and that many fixed steps
//                                              // (editor play sessions record it); frames past its end step(1)
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
