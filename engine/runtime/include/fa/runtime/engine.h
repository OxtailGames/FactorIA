// Engine: owns every subsystem and runs the game loop.
//
// One frame (Engine::frame):
//   input.begin_frame (events were fed by the platform/injection)
//   N x fixed step @ fixedHz:  scripts.fixed_update -> physics.step -> scripts.dispatch_events
//   ui.update (layout, focus, widget events) -> scripts.dispatch_events
//   scripts.update(dt) -> animators/particles -> audio.update -> scripts.late_update
//   physics.step and animators/particles are scaled by scripts.time_scale() (game.paused: frozen)
//   localization: Text/widget `key`s are rewritten after every scene load, after scripts.late_update and before drawing
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
//   game.state, game.logs, game.pause, game.resume, audio.log, ui.state, i18n.state, i18n.set_language, script.eval, script.errors,
//   physics.raycast, api.components, api.commands, api.scripting, assets.list
#pragma once

#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/audio/audio.h"
#include "fa/core/command.h"
#include "fa/core/profiler.h"
#include "fa/physics/physics.h"
#include "fa/platform/app.h"
#include "fa/platform/input.h"
#include "fa/render/renderer.h"
#include "fa/runtime/project.h"
#include "fa/scene/world.h"
#include "fa/script/script.h"
#include "fa/services/platform.h"

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
    // Props of the start scene (a JSON object; null = none): what its scripts read with game.sceneProps() from their first
    // start(). `factoria run --props` sets it. Like scene.load(path, {props}), a reload keeps them.
    Json sceneProps;
    bool headless = false;         // no window; offscreen GPU (HeadlessGpu)
    bool graphics = true;          // false = no GPU at all (pure logic tests); renderer() == nullptr
    bool audioDevice = true;       // false = null audio device (always false when headless)
    int width = 0, height = 0;     // override design resolution (0 = project)
    std::uint64_t seed = 1;        // world RNG seed
    // The calendar date `game.today()` answers, "YYYY-MM-DD" ("" = the fixed default, kDefaultDate 2026-01-01: a simulation
    // never reads the clock). A host with a window puts the player's real date here (run_windowed does, with
    // local_calendar_date()); `factoria test`, headless runs, `factoria call/session` and the MCP server leave it empty unless
    // --date says otherwise; a replay file carries the date it was recorded on. An impossible date makes init fail.
    std::string date;
    int dateUtcOffsetMinutes = 0;  // the player's offset from UTC in minutes (utcOffsetMinutes of game.today()); 0 for a fixed date
    // Windowed runs only (run_windowed / make_app_desc): draw this many frames, then close the window; the exit code is 1 when
    // a script recorded an error by then. For smoke-testing an exported game (factoria_player --frames N). 0 = run until closed.
    int maxFrames = 0;
    bool hotReload = true;         // watch scripts/scenes/assets (desktop, not headless)
    // Watch only the files the renderer rebuilds in place (materials, shader snippets, textures, fonts, models) and
    // leave scripts, scenes and locales alone. For hosts that manage those themselves (the editor). Ignored when
    // hotReload is on, which already watches everything.
    bool hotReloadAssets = false;
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
    // The language to start in (a tag of factoria.json localization.languages, "" = automatic): overrides the choice below and
    // the FA_LANGUAGE environment variable. Automatic: headless runs (tests, the MCP server, `factoria call`) and the editor
    // always start in localization.defaultLanguage so that what they print and save does not depend on the machine; a game in
    // its own window and an exported game start in the best match of the system's languages. docs/LOCALIZATION.md.
    std::string language;
    // Compiles custom materials (MeshRenderer.material) for the renderer, host dialect only (Renderer::set_shader_compiler).
    // `factoria` and the editor pass the tooling's compile_material (fa_runtime cannot depend on fa_tooling); empty = an
    // exported game, which reads the compiled twins shipped next to each material.
    ShaderCompiler shaderCompiler;
    // The script debugger (fa/script/debugger.h): when set, the engine runs the game's scripts in debug mode (instrumented,
    // breakpoints and stepping, the stopped game inspected through the debugger's DebugClient). Null = a normal run, with
    // no cost. `factoria dap` and `script.trace` create it; the Engine hands it to its ScriptSystem before the scripts start.
    std::shared_ptr<ScriptDebugger> scriptDebugger;
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

    bool load_scene(std::string_view path, std::string* error);  // immediate; the scene has no props
    // Immediate, and the scene starts with `props` (a JSON object, see EngineConfig::sceneProps): game.sceneProps().
    bool load_scene(std::string_view path, const Json& props, std::string* error);
    // Replaces the world with a scene given as JSON (immediate; `sourceName` is only used in messages). Unlike
    // load_scene it does NOT change the current scene path (engine.info / game.state / scene.save / scene.reload keep
    // pointing at the file being edited), so editors can restore snapshots without temp files.
    bool load_scene_json(const Json& scene, std::string_view sourceName, std::string* error);
    void reload_scene();  // keeps the scene's props

    // Input recording (docs/DEBUGGING.md, the `input.record` command): from now on every key, mouse, touch, gamepad and Back
    // event the game receives, the frame times, the clipboard reads and the answers of http.fetch are written in the input
    // replay format. Starting again drops what was recorded. Start and stop BETWEEN frames: the frame that is running is not
    // replayed whole. stop_input_recording() returns the replay (what `factoria run --headless --input` plays), also when
    // nothing was recorded; frames are numbered from the start. What is held at the start (keys, buttons, pads) is part of
    // the replay. A request still waiting for its answer at the stop is not in it, nor are the ones made after it.
    void start_input_recording();
    Json stop_input_recording();
    bool input_recording() const;
    std::size_t input_recording_frames() const;  // frames recorded so far

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
    bool screenshot(std::string_view path, std::string* error) override { return screenshot_scaled(path, 1.0, error); }
    // Render scale (0.25 .. 4, output at most 8192 px per side): draws the same design-size frame into an image `scale`
    // times larger, like a fullscreen window does (layout, camera and visible area unchanged, text and shapes sharp).
    bool screenshot_scaled(std::string_view path, double scale, std::string* error) override;
    // Same, with the colour-vision simulation `simulate` ("", "none", "greyscale", "protanopia", "deuteranopia",
    // "tritanopia") applied to the saved pixels on the CPU. What the game draws is not changed.
    bool screenshot_simulated(std::string_view path, double scale, std::string_view simulate, std::string* error) override;
    // The same picture as screenshot_scaled, as pixels (row 0 = top).
    bool capture_scaled(Image& out, double scale, std::string* error);
    // Keeps the render scale at `scale` between captures (a video draws every frame at one scale; without it each
    // capture would recreate the targets). Same limits as screenshot_scaled; false + message when out of range.
    bool hold_render_scale(double scale, std::string* error);
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
    Vec2 design_size() const override;
    double fixed_dt() const override;
    Clipboard* clipboard() override;  // the system's in a game window, an in-memory one everywhere else
    // What clipboard reads returned since the last call (oldest first), once log on is set: the editor's play session
    // records them as the "clipboard" of the frame they happened in. Off by default; set false to stop logging.
    void log_clipboard_reads(bool on);
    std::vector<std::string> take_clipboard_reads();
    WindowControl* window() override;  // nullptr unless the game owns a real window (not headless, not the editor)
    PlatformServices* platform_services() override;
    const I18n* i18n() override;
    std::string set_language(std::string_view language) override;
    double preload_time_budget_ms() const override;
    void request_scene_change(std::string_view scenePath) override;
    void request_scene_change_with_props(std::string_view scenePath, const Json& props) override;
    void request_scene_reload(std::string_view scenePath) override;
    const Json& scene_props() const override;
    void request_quit() override;
    void step_frames(int n) override;
    void set_text_scale(float scale) override;  // also the renderer's
    void set_ui_scale(float scale) override;    // also the renderer's (text measuring)
    float default_ui_scale() const override;    // the ui.scale of factoria.json
    double render_scale() const override;       // window.renderScale: the held render scale
    std::string set_render_scale(double scale) override;
    Json device_info() const override;          // a game window reports the real device; headless runs the fixed values
    Json render_stats_now() override;
    std::string load_scene_now(std::string_view scenePath) override;
    std::string load_scene_now_with_props(std::string_view scenePath, const Json& props) override;
    std::string load_scene_json_now_with_props(const Json& scene, std::string_view sourceName, const Json& props) override;
    std::string load_scene_json_now(const Json& scene, std::string_view sourceName) override;

    ScriptSystem& scripts();

    // How a design-pixel point becomes a window pixel, for the rectangle a TextField hands to a plugin's text input handler
    // (fa_plugin.h, FaTextInput). A game window sets it (the letterbox mapping of the renderer); without it, design pixels.
    void set_design_to_window(std::function<Vec2(Vec2)> mapper);

    // Profiler (switch it with Profiler::get().set_enabled; fa/core/profiler.h, docs/PERFORMANCE.md). Measurement only:
    // nothing it records reaches the simulation, game.state or replays.
    ProfMemory profile_memory();  // memory now: process, JS heap, textures, decoded audio, entities
    // Appends the GPU milliseconds that came back since the last call; `supported` / `reason` say whether this backend times
    // the GPU and, when not, why. Results arrive a few frames late.
    void profile_gpu(std::vector<double>& msOut, bool* supported, std::string* reason);

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
//       "40": { "clipboard": "ABC123" }   // optional per frame: the text clipboard.read() / Ctrl+V give from that frame on
//     "date": "2026-03-14", "utcOffsetMinutes": 60  // optional: what game.today() returns (editor play sessions
//                                              // record it); --date wins; without it the fixed default date is used
// "press"/"release" accept action names (virtual action override) and key names ("Space", "A", "MouseLeft"...).
//
// Report JSON: {frames, scriptErrors: [string], sceneErrors: [string], logErrors: n, screenshots: [absolute paths],
// statePath?, audioPath?, videoPath?, videoFrames?, videoAudio?, error?, exitCode,
// perf: {frames, cpuMsAvg, cpuMsP95, cpuMsMax (CPU time per frame), cpuClock ("process" or "wall"), peakMemoryMB,
// drawCalls, entities, triangles, lights and textureMB (max over the run), graphics (the GPU in use or "none")}}.
struct HeadlessRunOptions {
    int frames = 60;
    std::string inputReplayPath;          // optional
    std::vector<int> screenshotFrames;    // frame indices to capture
    std::string screenshotPattern = ".factoria/screenshots/frame_{frame}.png";
    std::string screenshotSimulate;       // "" / none, greyscale, protanopia, deuteranopia, tritanopia: screenshots (not the video) are converted to what a colour-blind viewer sees
    double renderScale = 1.0;             // screenshots are design size * this (0.25 .. 4), drawn natively: 1.5 on 1280x720 = 1920x1080
    std::string stateOutPath;             // optional JSON state dump at the end
    std::string audioOutPath;             // optional WAV recording
    // Video of the run: every frame is drawn (at renderScale) and written to a .avi (Motion-JPEG, plus the PCM audio of
    // the run when it is not silent) at the project's fixedHz frames per second. A .mp4 (H.264 + AAC) is made by
    // ffmpeg from that, so it needs `ffmpegPath` (the CLI looks it up); without it a .mp4 request fails before the run.
    std::string videoOutPath;
    std::string ffmpegPath;
    // Called after each frame is written to the video, with the frames written so far and the frames the run was asked
    // for (a run that quits early ends below the total). The CLI prints it as progress lines.
    std::function<void(int written, int total)> videoProgress;
    bool failOnScriptError = true;
    // Profile the run (fa/core/profiler.h): report["profile"] summarises the frames after `profileWarmup` (the first frames
    // load assets and warm caches): per system and per behaviour class ms, GPU ms or null + reason, memory. Wall-clock
    // numbers, never part of the state or replay. perf.profile uses it.
    bool profile = false;
    int profileWarmup = 0;
};
int run_headless(const EngineConfig& config, const HeadlessRunOptions& options, Json* report = nullptr);

}  // namespace fa
