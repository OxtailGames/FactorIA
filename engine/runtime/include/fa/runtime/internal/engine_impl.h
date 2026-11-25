// Private state of fa::Engine, shared by engine.cpp, commands.cpp and runners.cpp, and by the authoring commands of
// tools/authoring (fa_authoring), which are registered into an Engine through fa/runtime/command_extension.h.
//
// FOR ENGINE TOOLS ONLY: a game, a plugin or any code that ships with a game must not include it. It is public to the
// build (not in engine/runtime/src) only so that tools/authoring can reach Engine::Impl, and nothing in it is a stable API:
// it changes with the engine's insides. A game gets its engine through fa/runtime/engine.h.
#pragma once

#include <atomic>
#include <chrono>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <utility>
#include <string>
#include <vector>

#include "fa/render/dynamic_resolution.h"
#include "fa/runtime/internal/background_loader.h"
#include "fa/runtime/internal/world_streamer.h"
#include "fa/core/i18n.h"
#include "fa/core/jobs.h"
#include "fa/platform/websocket.h"
#include "fa/render/text_measure.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/gpu_backend_choice.h"
#include "fa/runtime/input_recorder.h"
#include "fa/scene/camera_geometry.h"
#include "fa/scene/rich_text.h"
#include "fa/scene/serialize.h"
#include "fa/scene/vfx.h"
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
        if (system_)
            system_clipboard().set(text);
        else
            memory_.set(text);
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
    StartupTimeline startup;  // Engine::startup_timeline()
    bool firstGameFrameMarked = false;
    std::unique_ptr<LoadTrace> loadTrace;  // EngineConfig::traceLoads / Engine::begin_load_trace; null = not tracing
    // This engine's token as a reader (fa/core/load_trace.h): never reused, so a loader thread that finishes after the
    // engine is gone records into no later engine's trace.
    const LoadTrace::Owner traceOwner = LoadTrace::new_owner();
    std::uint64_t logSeqAtInit = 0;  // state() only reports logs emitted by THIS engine
    ProjectSettings project;
    bool initialized = false;
    bool jobsStarted =
        false;  // this engine holds a reference on the job pool (jobs::start in init, jobs::stop in shutdown)
    std::string
        jobThreadsSource;  // where the job thread setting came from: "EngineConfig", "FA_JOB_THREADS", "factoria.json", "default"
    GpuBackendChoice
        gpuChoice;  // the GPU backend this run asked for (EngineConfig, FA_GPU_BACKEND, factoria.json, auto)
    GpuBackend gpuBackendAuto = GpuBackend::Default;  // EngineConfig::gpuBackendAuto (graphics.backend reports it)
    // graphics.backend {"name"} (P9e2): the choice stored for the next start. With memoryStorage it lives here only.
    bool gpuStoreInMemory = false;
    std::string gpuStoredBackend;  // "" = none stored ("auto")
    // Why the run did not draw with the backend it asked for ("" = it did, or asked for none): the first error.
    std::string gpuFallbackReason;
    // The renderer's D3D12 or Vulkan device has the window's swapchain (app_claim_native_window): shutdown gives it
    // back.
    bool windowClaimed = false;
    jobs::Owner jobOwner{
        "engine"};  // this engine's jobs and main-thread tasks (shutdown waits for them; a frame runs its tasks)
    bool windowed = false;  // GPU comes from the platform window (GfxEnvironment passed to init)

    World world;
    Input input;
    Physics physics;
    Audio audio;
    VfxHost vfxHost;  // what the effect system plays sounds and calls commands with (filled by register_vfx_commands)
    ScriptSystem scripts;
    UiSystem ui;
    std::function<Vec2(Vec2)> designToWindow;  // Engine::set_design_to_window; empty = design pixels
    PlatformServices
        platform;  // achievements, purchases, ...: the catalog of factoria.json and the backend (platform_backend.h)
    I18n i18n;     // string tables and the current language (factoria.json "localization"); off without the section
    CommandRegistry commands;
    std::vector<std::string>
        runtimeCommandNames;  // Engine::runtime_command_names(): the built-ins, before plugins and extensions
    std::unique_ptr<HeadlessGpu> gpu;
    std::unique_ptr<Renderer> renderer;
    CameraSet
        cpuCameras;  // the cameras when there is no renderer: refreshed where Renderer::update would (render()), answers like it
    TextMeasurer
        cpuText;  // text sizes when there is no renderer: the same fonts and shaping (fa/render/text_measure.h); settings kept in step either way
    std::unique_ptr<AppWindowControl> appWindow;  // windowed game only
    EngineClipboard clipboard;
    std::unique_ptr<WebSocketClient>
        websocketClient;     // websocket.connect: the platform's, or the memory one in headless runs and tests
    InputRecorder recorder;  // the Input observer; records only between start_input_recording and stop_input_recording

    // Scene props (scene.load(path, {props}), `factoria run --props`): the running scene's, and the ones the next load takes.
    // A load takes `nextProps` when there are some; else a reload (keepProps) keeps the current ones; else a load gives {}.
    Json sceneProps = Json::object();
    std::optional<Json> nextProps;
    bool pendingKeepProps = false;  // the scene change scheduled for the end of the frame is a reload
    void take_scene_props(bool keepProps);

    double heldScale = 1.0;  // Engine::hold_render_scale: the render scale between captures
    // window.renderScale was set by the player's option (Engine::set_render_scale) and not as a size by hold_render_scale (--render-scale,
    // the recorder): then it is combined with the upscaler's quality (apply_render_scale).
    bool playerScale = false;
    // The ONE place that decides the render scale the renderer draws at and whether its upscale stage runs: from heldScale, the
    // upscaler's quality and the mode that really draws (docs/UPSCALING.md, "The render scale"). Called by every change of those.
    void apply_render_scale();
    // Dynamic resolution (M76-P6c, docs/UPSCALING.md): the controller, what feeds it and what it last reported. The
    // factor it gives is the `dynamicScale` that apply_render_scale multiplies in (1 while off, in the editor and for
    // a scale held as a size).
    render::DynamicResolutionController dynRes;
    std::optional<double> injectedFrameMs;  // Engine::set_dynamic_resolution_frame_ms
    std::optional<double> injectedGpuMs;    // Engine::set_dynamic_resolution_gpu_ms
    std::uint64_t drawCount = 0;            // frames handed to the renderer (draw())
    std::uint64_t tickDrawCount = 0;        // drawCount at the last tick that measured
    const char* dynSource = "none";         // what the last tick measured (DynamicResolutionState::source)
    std::vector<double> gpuFrameScratch;
    // What keeps a measurement that says nothing about the new scale or the scene out of the controller (all counted
    // in frames or in the frames' own dt, never read from a clock): the frames after a change of the scale whose time
    // is the new images' (kDynSettleFrames), the seconds after a scene load while shaders compile and assets arrive
    // (kDynFreezeS), and the frames in a row in which the GPU timer gave no result (after kGpuMissFrames the tick
    // measures the time between frames instead).
    static constexpr int kDynSettleFrames = 3;
    static constexpr double kDynFreezeS = 3.0;
    static constexpr int kGpuMissFrames = 120;
    int dynSettle = 0;
    double dynFreezeS = 0.0;
    int gpuMissFrames = 0;
    std::optional<render::DynamicResolutionSettings>
        appliedProjectDynRes;  // the project's render.dynamicResolution last applied
    // The low-latency setting (M78, docs/LATENCY.md): the project's render.latency, or what render.latency / Engine::set_latency last
    // set. The renderer holds the same value once it exists; the engine passes the display's refresh rate to it every frame.
    render::LatencySettings latency;
    std::optional<render::LatencySettings> appliedProjectLatency;  // the project's render.latency last applied
    // Engine::profile_latency is asked every frame the profiler is on; the status it reads is built (JSON, every provider's reason) only when
    // the setting, the driver that runs or the 64-frame bucket changed.
    struct LatencyProfileCache {
        bool valid = false;
        render::LatencyMode mode = render::LatencyMode::Off;
        bool boost = false;
        render::LatencyDriver driver = render::LatencyDriver::None;
        std::uint64_t bucket = 0;
        std::string name, reason;  // the status' "driver" and "reason"
    } latencyProfileCache;
    // The frame generation setting (M78, docs/FRAME_GENERATION.md): the project's render.frameGeneration, or what render.frame_generation /
    // Engine::set_frame_generation last set. The renderer holds the same value once it exists.
    render::FrameGenSettings frameGeneration;
    std::optional<render::FrameGenSettings>
        appliedProjectFrameGen;  // the project's render.frameGeneration last applied
    // The refresh rate the engine's own pacing aligns to: the display's while vsync paces a windowed game, else 0 (no pacing).
    double latency_pacing_hz() const;
    float dynamic_factor() const;
    void sync_dynamic_resolution();  // settings -> controller and the renderer's GPU timing, then apply_render_scale
    void dynamic_resolution_tick(double dt);  // one frame of the controller (the start of run_frame)
    // The display refresh rate a targetMs of 0 follows (M76-P6d, docs/UPSCALING.md, "The display's refresh rate"): the
    // platform's (asked again every kRefreshPollS seconds of frames, so a move to another monitor is seen), else the
    // estimate from the time between presented frames while vsync paces them, else kDynamicDefaultRefreshHz. Only a
    // windowed game outside the editor tracks it; it changes the frame time the controller holds and nothing of the
    // simulation.
    static constexpr double kRefreshPollS = 2.0;
    static constexpr int kRefreshRetryPolls =
        15;                                   // a given-up estimate starts over after this many polls (30 s of frames)
    std::optional<double> injectedRefreshHz;  // Engine::set_display_refresh_hz
    int refreshGaveUpPolls = 0;
    double refreshHz = 0.0;  // 0: the default
    const char* refreshSource = "default";
    render::RefreshRateEstimator refreshEstimator;
    double refreshPollS = 0.0;
    bool refreshPolled = false;  // the platform was asked once
    bool refreshPaced = false;   // the last frame was paced by the display (vsync on, no frame cap, continuous)
    int refreshDisplayW = 0,
        refreshDisplayH = 0;                // the display the estimate measures (a move to another one starts it again)
    void track_display_refresh(double dt);  // once per frame, before dynamic_resolution_tick
    bool renderStale = false;               // OnDemand: simulated since the last draw
    double lastRenderDt = 0.0;
    std::uint64_t renderedFrame = 0;  // frame index at the last draw
    std::uint64_t frame = 0;
    std::uint64_t fixedStep = 0;  // fixed simulation steps run so far (several per frame when the frame was slow)
    bool paused = false;
    bool wasUserPaused =
        false;  // scripts.user_time_scale() was 0 at the start of the last frame (pad rumble stops on the edge)
    void advance_pad_rumble(double dt);
    bool cut_pad_rumble_on_pause();  // true on the edge of the game pausing itself (and then stops every pad)
    bool quit = false;
    bool appEnded = false;  // end_app() ran
    bool inFrame = false;   // between the start and the end of run_frame (commands defer risky work)
    double accumulator = 0.0;
    double interpAlpha =
        1.0;  // render interpolation: how far past the latest fixed step this frame is, 0..1 (1 = real pose)
    double fixedDt = 1.0 / 60.0;
    std::string pendingScene;
    bool hasPendingScene = false;
    std::uint64_t pendingTraceTag = 0;  // the pending scene change is an async scene load's (its load-trace tag)
    int pendingLoadId = 0;              // ... and that load's id (0: not an async load's switch)
    BackgroundLoader::Origin pendingLoadOrigin = BackgroundLoader::Origin::Tool;

    // Background loading (scene.preload, assets.preload, scene.load {async: true}; background_loader.h). Made after the job
    // pool started (whether its IO thread runs depends on the pool), stopped before the engine waits for its jobs.
    std::unique_ptr<BackgroundLoader> loader;
    std::unique_ptr<WorldStreamer>
        streamer;  // made with the loader, destroyed before it (docs/BIG_WORLDS_STREAMING.md, "Streaming")
    std::optional<int> replayLoadUnits;  // a replay entry's "loadUnits": the units of the coming frame
    bool replaying = false;              // a windowed replay runs: frames without "loadUnits" take the fixed budget
    // Starts a background load (scene.preload, assets.preload, an async scene.load) for a script or a command. An async
    // scene load replaces a scene change asked for before it in this frame.
    Result<int> start_background_load(BackgroundLoader::Kind kind, const std::vector<std::string>& paths,
                                      std::optional<Json> props, BackgroundLoader::Origin origin);
    BackgroundLoader::Budget load_budget();
    void tick_background_loads();
    void cancel_background_scene_loads();  // a scene change was asked for: the async scene loads before it stop
    // load.cancel / a handle's cancel(): stops a running load, drops a finished one's files, and stops the switch of an
    // async scene load whose files were ready this frame (it would happen at the end of the frame). False: unknown id.
    bool cancel_background_load(int id);
    // The JavaScript context that started them is gone: its loads stop (an async scene load's pending switch too), and
    // no update of theirs is delivered to the next context.
    void cancel_script_background_loads();
    void drop_pending_async_switch();  // forgets the pending scene change of an async load (records it as cancelled)
    // Called first thing in Engine::shutdown, before it waits for this engine's jobs: a command that started a long job (the lightmap
    // bake of tools/authoring) adds one that asks the job to stop, so quitting does not wait for it. Run on the engine's thread, in order.
    std::vector<std::function<void()>> shutdownHooks;
    std::string currentScene;
    std::atomic<bool> playWorld{false};  // Engine::play_world(): the editor's Play session runs in this world
    // The current scene is the project's mainScene, loaded at start because no start scene was given (no EngineConfig::scene),
    // and no scene was loaded since. scene.import_ascii refuses `save` without `path` then: see tools/authoring/src/level_commands.cpp.
    bool implicitStartScene = false;
    // tilemap.generate_start jobs (wfc_commands.cpp): the generations the script API advances a little every frame, by id. The
    // pointers are really std::shared_ptr<GenRun>; the type stays private to wfc_commands.cpp. Dropped when the scene changes.
    std::map<int, std::shared_ptr<void>> wfcJobs;
    int nextWfcJob = 1;
    std::vector<std::string> sceneIssues;  // every LoadMessage of the last scene load (errors + warnings)
    std::size_t sceneErrorCount = 0;
    std::vector<std::string> startupProblems;
    RichTextStyle
        richStyle;  // the project's "text" section: markup colours, icons, bold faces (empty when absent or broken)
    int pluginSteamDeck = -1;  // what a plugin said about the Steam Deck (plugin API 4): -1 nothing, 0 no, 1 yes

    // Hot reload
    std::map<std::string, std::int64_t> watched;
    bool watchSeeded = false;
    double watchTimer = 0.0;
    std::int64_t projectMtime = -1;  // factoria.json mtime when I.project was last read

    // Lifecycle helpers
    void run_frame(double dt, int fixedSteps);
    // ---- floating origin (engine_origin.cpp, docs/BIG_WORLDS_STREAMING.md "Floating origin")
    // Moves the origin by `offset` (a whole multiple of the project's step per axis): World::rebase (Transforms, particles, queued
    // effects, origin observers = the renderer), then the physics, the audio and the navigation, then one `originShifted` game event.
    // All in one call on the main thread, between fixed steps, so no frame sees the subsystems disagree.
    void rebase_origin(Vec3 offset);
    // After a fixed step: when floatingOrigin is enabled and the anchor is farther than `threshold` from the local origin on any axis,
    // rebase by the anchor's position rounded to `step`. One branch when it is off.
    void auto_rebase_origin();
    // The local world position of the project's anchor ("camera": the first rendering camera; "entity:<id>"). False when there is none.
    bool origin_anchor_position(Vec3& out);
    void render(double dt);  // per-frame: draws in Always mode, only simulates visuals in OnDemand
    void draw(double dt,
              bool settled = false);  // draws the world now; settled = settle_visuals() already ran since the last step
    void
    settle_visuals();  // dt = 0 step of the sprite animators and particles: what scripts and loads changed since the last step (no renderer needed)
    void finish_scene_load(const LoadReport& report, const std::string& label, std::string* error);
    bool load_scene_json_impl(const Json& scene, std::string_view sourceName, std::string* error);
    void end_of_frame(double dt, bool simulated = true);  // simulated false: a paused redraw keeps the input edges
    // `traceTag`: the switch of an async scene load (its load-trace entry); `hotReload`: the file watcher reloads the scene
    // (async scene loads asked for keep going). Any other load cancels the async scene loads asked for before it.
    bool load_scene_impl(const std::string& path, std::string* error, bool keepProps = false,
                         std::uint64_t traceTag = 0, bool hotReload = false);
    void refresh_from_disk();  // factoria.json (input actions, ...) and script modules that changed on disk
    void apply_project_settings();
    std::optional<UiTooltipSettings> appliedProjectTooltip;  // the project's tooltip delay and look last applied
    std::optional<bool> appliedProjectMirrorRtl;             // the project's ui.mirrorRtl last applied
    std::optional<render::UpscalerSettings> appliedProjectUpscaler;  // the project's render.upscaler last applied (M76)
    // The graphics preset (M76-P6a, engine_graphics.cpp): the quality layer the renderer applies. Custom = none.
    render::GraphicsPreset graphicsPreset = render::GraphicsPreset::Custom;
    render::QualityLimits
        graphicsLimits;  // the limits of graphicsPreset after the GPU's caps (the defaults = no limit)
    // The upscaler the game had before the first preset (Custom puts it back); empty while the preset is Custom.
    std::optional<render::UpscalerSettings> upscalerBeforePreset;
    std::optional<render::GraphicsPreset> appliedProjectPreset;  // the project's render.graphicsPreset last applied
    bool applyingPreset = false;  // a preset is writing the upscaler (not a manual change)
    // Resolves graphicsPreset on this GPU and hands the limits to the renderer (called when the renderer is created, after the project's
    // preset was read).
    void apply_graphics_quality();
    float appliedProjectUiScale = -1.0f;  // the project's ui.scale last applied; -1 before the first time
    // Localization (localization.cpp). setup: configure, read locales/*.json, choose the start language. apply: rewrite the
    // text of every component with a `key`. switch_language: i18n.set_language + apply + the "i18n.change" game event.
    void setup_localization();
    void reload_localization();  // read locales/*.json again (hot reload) and rewrite the texts
    void apply_localization();
    Result<std::string> switch_language(std::string_view requested);  // the language now in use, or why not
    void
    apply_fallback_fonts();  // the renderer's fallback fonts for the language in use (localization.fallbackFonts / languageFonts)
    CameraTarget camera_target() const;  // what the cameras are drawn into: the design size (a run without a window)
    Vec2 design_size() const;  // the renderer's target size (UI anchors are fractions of it); without one the project's
    VisualMeasure
    measure() const;  // text sizes from the renderer, else from the CPU measurer (same fonts, same numbers)
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

UiPageAimFn make_ui_page_aim(
    Engine::Impl&
        impl);  // surface_pointer.cpp: where to click a widget that only a render target shows (game.click {id})
UiSurfaceFn make_ui_surface_pointer(
    Engine::Impl& impl);  // surface_pointer.cpp: the pointer through a render target shown on a mesh
void register_builtin_commands(Engine& engine, Engine::Impl& impl);
void register_level_commands(Engine& engine, Engine::Impl& impl);  // level_commands.cpp: scene.place_ascii, tilemap.*
void register_terrain_commands(
    Engine& engine,
    Engine::Impl&
        impl);  // terrain_commands.cpp: tilemap.paint_terrain, tilemap.retile, tilemap.terrains, tilemap.set_terrains
void register_world_commands(
    Engine& engine,
    Engine::Impl&
        impl);  // world_commands.cpp: world.origin, world.rebase, world.cells, world.stream_status (M75 stubs)
void register_wfc_commands(Engine& engine, Engine::Impl& impl);  // wfc_commands.cpp: tilemap.generate
void register_play_session_commands(Engine& engine,
                                    Engine::Impl& impl);  // play_sessions.cpp: play.sessions, play.report
void register_background_load_commands(
    Engine& engine,
    Engine::Impl& impl);  // background_load_commands.cpp: scene.preload, assets.preload, load.status, load.cancel
void register_i18n_commands(Engine& engine, Engine::Impl& impl);      // localization.cpp: i18n.state, i18n.set_language
void register_ui_check_commands(Engine& engine, Engine::Impl& impl);  // ui_check.cpp: ui.check_layout
void register_gpu_backend_commands(Engine& engine, Engine::Impl& impl);  // gpu_backend_commands.cpp: graphics.backend
void register_shot_commands(Engine& engine,
                            Engine::Impl& impl);  // shot_commands.cpp: game.screenshot, render.inspect, render.pick
void register_compute_commands(
    Engine& engine,
    Engine::Impl& impl);  // compute_commands.cpp: compute.create_buffer, .write_buffer, .dispatch
void register_music_commands(Engine& engine, Engine::Impl& impl);  // music_commands.cpp: audio.music_state, audio.music
void register_postprocess_commands(
    Engine& engine,
    Engine::Impl& impl);  // postprocess_commands.cpp: postprocess.get, postprocess.set, postprocess.presets
void register_vfx_commands(Engine& engine,
                           Engine::Impl& impl);  // vfx_commands.cpp: vfx.play, vfx.stop, vfx.list; fills vfxHost
void register_feel_commands(
    Engine& engine,
    Engine::Impl&
        impl);  // feel_commands.cpp: feel.shake, feel.hitStop, feel.flash, feel.knockback, feel.squash, feel.cancel, feel.settings, feel.state

// The grid of an ASCII level in the format of scene.import_ascii (`rows`, `legend`, `legendFrom`), read for a command that learns
// from it (tilemap.generate). Checks it with the errors of scene.import_ascii (ragged rows, unknown glyphs with suggestions).
// Throws CommandError. The legend need not define '.' and ' ' (empty tiles).
struct AsciiSampleGlyph {
    std::string glyph;       // one character (UTF-8)
    int tile = -1;           // tile value (flags included), -1 = no tile
    bool hasPrefab = false;  // the legend entry also spawns an object
    Json legendEntry;        // the entry as the (merged) legend wrote it; null for a default-empty glyph
    bool placeOnly =
        false;  // defined by the legend but drawn nowhere in the rows (AsciiSample::legendOnly): no cell of `cells` holds it
};
struct AsciiSample {
    int width = 0;
    int height = 0;
    std::vector<int> cells;                // row-major, row 0 = TOP: index into `glyphs`
    std::vector<AsciiSampleGlyph> glyphs;  // in order of first appearance
    std::vector<AsciiSampleGlyph>
        legendOnly;  // the legend's other glyphs (placeOnly), in the order of the legend; not part of `glyphs`
};
AsciiSample read_ascii_sample(const Json& args);

// A `position` argument ([x, y] or [x, y, z], finite, within +-1e9; absent = the origin) of vfx.play and vfx.filmstrip. Throws
// CommandError("invalid_argument"). Defined in vfx_commands.cpp.
Vec3 vfx_position_arg(const Json& args, const char* key);

// Entity named by the string argument `key` (id or name). Throws CommandError("not_found") with a "did you mean".
Entity need_entity(World& world, const Json& args, const char* key = "id");

// scene.set_component on any World: `args` = {id, component, fields?}. Adds the component if missing and patches the given
// fields (all-or-nothing). Throws CommandError (not_found / invalid_argument) with did-you-mean. Returns {id, component, value}.
Json set_component(World& world, const Json& args);

}  // namespace fa
