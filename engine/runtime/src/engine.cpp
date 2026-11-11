#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <exception>
#include <filesystem>

#include "engine_impl.h"
#include "fa/audio/snapshots.h"
#include "fa/core/fs.h"
#include "fa/core/image_tools.h"
#include "fa/core/log.h"
#include "fa/core/perf.h"
#include "fa/core/jobs.h"
#include "fa/core/profiler.h"
#include "fa/core/screenshot_files.h"
#include "fa/core/strings.h"
#include "fa/platform/app.h"
#include "fa/runtime/platform_backend.h"
#include "fa/runtime/plugins.h"
#include "fa/scene/camera_mask.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/feel.h"
#include "fa/scene/animation.h"
#include "fa/scene/bones2d.h"
#include "fa/scene/ik3d.h"
#include "fa/scene/particle_store.h"
#include "fa/scene/serialize.h"
#include "fa/scene/sprite_animator.h"
#include "fa/scene/vfx.h"
#include "fa/scene/video.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

Json script_error_json(const ScriptError& e) {
    Json j = Json::object();
    j["file"] = e.file;
    j["line"] = e.line;
    j["column"] = e.column;
    j["message"] = e.message;
    if (!e.stack.empty()) j["stack"] = e.stack;
    if (!e.entityId.empty()) j["entityId"] = e.entityId;
    return j;
}

bool has_ext(const std::string& path, std::initializer_list<const char*> exts) {
    std::string e = fs::extension(path);
    for (const char* x : exts)
        if (e == x) return true;
    return false;
}

}  // namespace

// ------------------------------------------------------------------ Impl --
bool Engine::Impl::inject_named(const std::string& name, bool down, std::string* error) {
    if (input.has_action(name)) {
        input.set_action_override(name, down);
        return true;
    }
    Key k = key_from_name(name);
    if (k == Key::Unknown) k = modifier_key(modifier_from_name(name));  // "Ctrl", "Shift", "Alt", "Super": the left key
    if (k != Key::Unknown) {
        input.on_key(k, down);
        return true;
    }
    std::string lower = to_lower(name);
    if (lower == "mouseleft") { input.on_mouse_button(MouseButton::Left, down); return true; }
    if (lower == "mouseright") { input.on_mouse_button(MouseButton::Right, down); return true; }
    if (lower == "mousemiddle") { input.on_mouse_button(MouseButton::Middle, down); return true; }
    if (error) {
        std::vector<std::string> candidates = input.action_names();
        for (int i = 1; i < int(Key::Count); ++i) candidates.emplace_back(key_name(Key(i)));
        for (const char* m : {"MouseLeft", "MouseRight", "MouseMiddle", "Ctrl", "Shift", "Alt", "Super"}) candidates.emplace_back(m);
        *error = "Unknown input '" + name + "' (not an action, key or mouse button). " + did_you_mean(name, candidates);
        if (starts_with(to_lower(name), "gamepad") || starts_with(to_lower(name), "touch"))
            *error += " Gamepads and fingers have their own fields: {\"gamepad\": {\"buttons\": {\"A\": true}}}, "
                      "{\"touch\": {\"position\": [x, y]}}.";
    }
    return false;
}

void Engine::Impl::apply_project_settings() {
    fixedDt = 1.0 / std::max(1.0, project.fixedHz);
    world.feel().pixelsPerMeter = project.pixelsPerMeter;  // the 2D default speed of entity.knockback (fa/scene/feel.h)
    input.set_gamepad_deadzone(float(project.inputDeadzone));
    // The interface scale of factoria.json: applied when it changes (the first time included), so reloading the project for
    // another setting does not undo what the player chose in the Options menu. The start-up change sends no ui.scale event.
    if (project.uiScale != appliedProjectUiScale) {
        const bool atStart = appliedProjectUiScale < 0.0f;
        appliedProjectUiScale = project.uiScale;
        self->set_ui_scale(project.uiScale);
        if (atStart) std::erase_if(world.events().game, [](const GameEvent& e) { return e.name == "ui.scale"; });
    }
    // The mirror option of factoria.json, applied when it changes (a script's ui.mirrorRtl survives an unrelated reload).
    if (!appliedProjectMirrorRtl || *appliedProjectMirrorRtl != project.uiMirrorRtl) {
        appliedProjectMirrorRtl = project.uiMirrorRtl;
        world.set_ui_mirror_rtl(project.uiMirrorRtl);
    }
    // The tooltip settings, when the project file changes them (a script's ui.tooltipDelay survives an unrelated reload).
    if (!appliedProjectTooltip || *appliedProjectTooltip != project.uiTooltip) {
        appliedProjectTooltip = project.uiTooltip;
        world.set_ui_tooltip_settings(project.uiTooltip);
    }
    for (const std::string& problem : input.set_actions(ui_with_default_actions(project.inputActions))) {
        FA_WARN("input", "{}", problem);
        startupProblems.push_back(problem);
    }
    for (const std::string& problem : input.set_key_schemes(project.inputSchemes)) {  // after the actions: a scheme names some
        FA_WARN("input", "{}", problem);
        startupProblems.push_back(problem);
    }
    // The platform catalog. A section with errors counts as empty (every platform call then says the id is not declared):
    // the first error is logged here, `factoria validate` lists them all.
    platform.set_translator([this](const std::string& key) { return i18n.translate(key); });
    platform.set_date_source([this] { return scripts.today(); });  // the simulation's date: leaderboard periods never read the clock
    auto catalog = load_platform_catalog(project.raw.is_object() && project.raw.contains(kPlatformKey) ? project.raw[kPlatformKey] : Json());
    if (catalog.ok()) {
        platform.set_catalog(std::move(catalog.value()));
    } else {
        const std::string problem = "platform: the catalog is ignored: " + catalog.error().to_string() +
                                    " (`factoria validate` lists every problem)";
        FA_WARN("platform", "{}", problem);
        startupProblems.push_back(problem);
        platform.set_catalog(PlatformCatalog{});
    }
    // The audio snapshots. A section with errors counts as empty (audio.snapshot then says there is none); the problems are
    // logged here and `factoria validate` lists them all.
    AudioSettingsParse audioSettings = parse_audio_settings(project.raw.is_object() && project.raw.contains("audio") ? project.raw["audio"] : Json());
    if (audioSettings.ok()) {
        audio.set_buses(audioSettings.buses);
        audio.set_snapshots(std::move(audioSettings.snapshots));
    } else {
        const AudioIssue& first = audioSettings.issues.front();
        const std::string problem = "audio: the buses and the snapshot catalog are ignored: factoria.json#" + first.pointer + ": " + first.message +
                                    " (hint: " + first.hint + ")" +
                                    (audioSettings.issues.size() > 1 ? " and " + std::to_string(audioSettings.issues.size() - 1) +
                                                                           " more (`factoria validate` lists them all)"
                                                                     : std::string());
        FA_WARN("audio", "{}", problem.substr(7));
        startupProblems.push_back(problem);
        audio.set_buses({});
        audio.set_snapshots(AudioSnapshots{});
    }
    // The rich text style (markup colours, icons, bold faces). A section with errors counts as empty (a [c:name] then shows as
    // written); the first error is logged here, `factoria validate` lists them all.
    TextSettingsParse textSettings = parse_text_settings(project.raw.is_object() && project.raw.contains("text") ? project.raw["text"] : Json());
    for (const TextSettingsIssue& w : textSettings.warnings) FA_WARN("text", "factoria.json#{}: {} {}", w.pointer, w.message, w.hint);
    if (textSettings.ok()) {
        richStyle = std::move(textSettings.style);
    } else {
        const TextSettingsIssue& first = textSettings.issues.front();
        const std::string problem = "text: the markup colours, icons and bold faces are ignored: factoria.json#" + first.pointer + ": " +
                                    first.message + " (hint: " + first.hint + ")" +
                                    (textSettings.issues.size() > 1 ? " and " + std::to_string(textSettings.issues.size() - 1) +
                                                                          " more (`factoria validate` lists them all)"
                                                                    : std::string());
        FA_WARN("text", "{}", problem.substr(6));
        startupProblems.push_back(problem);
        richStyle = RichTextStyle{};
    }
    if (renderer) renderer->set_rich_text_style(richStyle);
    else cpuText.set_rich_text_style(richStyle);  // the CPU measurer only works when there is no renderer
    // The hosts http.fetch may call. A section with errors counts as empty (every http.fetch then says no host is declared).
    auto network = load_network(project.raw.is_object() && project.raw.contains(kNetworkKey) ? project.raw[kNetworkKey] : Json());
    if (network.ok()) {
        platform.set_network(std::move(network.value()));
    } else {
        const std::string problem = "network: the declaration is ignored: " + network.error().to_string() +
                                    " (`factoria validate` lists every problem)";
        FA_WARN("platform", "{}", problem);
        startupProblems.push_back(problem);
        platform.set_network(NetworkPolicy{});
    }
}

Vec2 Engine::Impl::design_size() const {
    if (renderer && renderer->initialized()) return {float(renderer->target_width()), float(renderer->target_height())};
    return {float(cfg.width > 0 ? cfg.width : project.width), float(cfg.height > 0 ? cfg.height : project.height)};
}

CameraTarget Engine::Impl::camera_target() const {
    const Vec2 size = design_size();
    CameraTarget t;
    t.width = int(size.x);
    t.height = int(size.y);
    t.designWidth = cfg.width > 0 ? cfg.width : project.width;
    t.designHeight = cfg.height > 0 ? cfg.height : project.height;
    t.expand = project.scaleMode == ScaleMode::Expand;
    return t;
}

VisualMeasure Engine::Impl::measure() const {
    VisualMeasure m;
    m.textScale = self->text_scale();
    if (renderer && renderer->initialized()) {
        const Renderer* r = renderer.get();
        m.textSize = [r](const Text& t) { return r->measure_text(t); };
    } else {
        // No renderer: the CPU measurer, which shapes with the very fonts and code the renderer lays text out with, so a run with
        // no graphics measures every Text (autoSize widgets, fit panels, ui.textScale, autoShrink) to the same size as one with.
        m.textSize = [measurer = &cpuText](const Text& t) { return measurer->measure_text(t); };
    }
    return m;
}

// Every scene load (scene.load, scene.reload, hot reload, project.test) starts from what is on disk now. ponytail: only
// fixedHz, the input actions, the deadzone and (when the file changed it) ui.scale are re-applied from factoria.json; size, scale mode, the renderer and the
// "localization" section (languages, default language: setup_localization) need a restart. locales/*.json reload by themselves.
void Engine::Impl::refresh_from_disk() {
    const std::int64_t t = fs::modified_time(kProjectFileName);
    if (t != projectMtime) {
        projectMtime = t;
        auto proj = load_project(fs::project_root().generic_string());  // the same folder init() read it from
        if (proj.ok()) {
            project = proj.value();
            apply_project_settings();
        } else {
            FA_WARN("project", "{} changed but could not be reloaded; keeping the previous settings: {}", kProjectFileName,
                    proj.error().to_string());
        }
    }
    scripts.refresh_modules();
}

// The props the scene being loaded starts with: the ones asked for, else the current ones on a reload, else none.
void Engine::Impl::take_scene_props(bool keepProps) {
    if (nextProps) {
        sceneProps = std::move(*nextProps);
        nextProps.reset();
    } else if (!keepProps) {
        sceneProps = Json::object();
    }
}

bool Engine::Impl::load_scene_impl(const std::string& pathIn, std::string* error, bool keepProps, std::uint64_t traceTag,
                                   bool hotReload) {
    const jobs::OwnerScope jobScope(&jobOwner);  // the jobs a scene load queues (asset loads) are this engine's
    const LoadTrace::ReadingFor reading(traceOwner);  // a scene's reads are this engine's, whoever asked (fa/core/load_trace.h)
    std::string path = pathIn;
    if (!fs::is_absolute(path)) {
        auto n = fs::normalize_checked(path);
        if (!n.ok()) {
            if (error) *error = n.error().to_string();
            sceneIssues = {n.error().to_string()};
            sceneErrorCount = 1;
            FA_ERROR("scene", "{}", n.error().to_string());
            return false;
        }
        path = n.value();
    }
    refresh_from_disk();
    // A load the game asked for now replaces the async scene loads asked for before it (the last request wins).
    if (traceTag == 0 && !hotReload) cancel_background_scene_loads();
    // Before the scene file is read: it is the first file of its scene. An async load's entry opened when it was asked for.
    if (loadTrace) loadTrace->scene_started(path, traceTag);
    hasPendingScene = false;
    take_scene_props(keepProps);
    implicitStartScene = false;  // from now on the scene was chosen (scene.load, a script, --scene, reload)
    audio.on_scene_load();
    physics.reset();
    LoadReport report = load_scene_file(world, path);
    world.set_scene_path(path);
    currentScene = path;
    finish_scene_load(report, path, error);
    return report.ok();
}

void Engine::Impl::finish_scene_load(const LoadReport& report, const std::string& label, std::string* error) {
    world.reset_clock();
    sceneIssues.clear();
    sceneErrorCount = report.error_count();
    for (const LoadMessage& m : report.messages) {
        sceneIssues.push_back(m.to_string());
        if (m.severity == LoadMessage::Severity::Error) FA_ERROR("scene", "{}", m.to_string());
        else FA_WARN("scene", "{}", m.to_string());
    }
    physics.sync(world);  // bodies exist (and can be queried) right after the load, before the first step
    bind_pending_skins(world);  // a SpriteSkin records the pose the scene was authored in, before any clip moves a bone
    ui.reset();
    apply_localization();  // the first frame (and the first onStart) already read the current language
    world.particles().clear();  // emitters are kept by entity: the new scene's start from nothing, as on every Play (before the scripts, which may emit a burst)
    // The cameras the first queries of the scripts (camera.worldToScreen in onStart, before any frame ends) answer with are the new
    // scene's, not the previous scene's or none at all. A renderer has its own, refreshed where the frame is drawn.
    if (!renderer) cpuCameras.refresh(world, camera_target());
    scripts.on_scene_loaded();
    if (loader) loader->scene_loaded();  // files read ahead for this load are dropped at the next one
    if (renderer) renderer->debug().clear();
    // The picture of the previous scene is outdated: the next screenshot / render_now must draw the new one, also when
    // no frame is stepped in between (game.load(...) then game.screenshot(...) in a test).
    if (renderer) renderStale = true;
    if (!report.ok()) {
        if (error) *error = report.summary();
        return;
    }
    FA_INFO("scene", "Loaded {} ({} entities)", label, report.created.size());
}

bool Engine::Impl::load_scene_json_impl(const Json& scene, std::string_view sourceName, std::string* error) {
    const jobs::OwnerScope jobScope(&jobOwner);  // the jobs a scene load queues (asset loads) are this engine's
    const LoadTrace::ReadingFor reading(traceOwner);
    cancel_background_scene_loads();
    hasPendingScene = false;
    take_scene_props(false);
    audio.on_scene_load();
    physics.reset();
    const std::string keptPath = world.scene_path();
    if (loadTrace) loadTrace->scene_started(keptPath.empty() ? std::string(sourceName) : keptPath);
    LoadReport report = fa::load_scene(world, scene, sourceName);
    world.set_scene_path(keptPath);
    // The scene path (world + currentScene) is deliberately left alone.
    finish_scene_load(report, std::string(sourceName), error);
    return report.ok();
}

void Engine::Impl::apply_scene_change() {
    if (!hasPendingScene) return;
    std::string path = pendingScene;
    hasPendingScene = false;
    const bool keep = std::exchange(pendingKeepProps, false);
    const std::uint64_t tag = std::exchange(pendingTraceTag, 0);  // an async scene load's switch
    pendingLoadId = 0;
    std::string err;
    load_scene_impl(path, &err, keep, tag);
}

BackgroundLoader::Budget Engine::Impl::load_budget() {
    BackgroundLoader::Budget b;  // exact, BackgroundLoader::kFixedUnitsPerFrame
    if (replayLoadUnits) {  // what the recorded frame took
        b.units = *replayLoadUnits;
        replayLoadUnits.reset();
        return b;
    }
    if (replaying || !((windowed && !cfg.editorMode) || cfg.timedLoads)) return b;
    b.exact = false;
    b.ms = project.loadBudgetMs;
    b.uploadMB = project.uploadBudgetMB;
    return b;
}

void Engine::Impl::tick_background_loads() {
    if (!loader || !loader->active()) {
        replayLoadUnits.reset();
        return;
    }
    const bool loading = loader->loading();
    const BackgroundLoader::Frame f = loader->tick(renderer.get(), &audio, load_budget());
    if (loading && recorder.recording()) recorder.load_units(frame, f.units);  // a replay takes the same units per frame
    for (const BackgroundLoader::SceneReady& ready : f.scenes) {  // its files are ready: the switch happens at the end of this frame
        if (pendingTraceTag != 0 && loadTrace) loadTrace->load_cancelled(pendingTraceTag);
        pendingScene = ready.path;
        hasPendingScene = true;
        nextProps = ready.props;
        pendingKeepProps = false;
        pendingTraceTag = ready.traceTag;
        pendingLoadId = ready.id;  // a cancel() later in this frame still stops the switch
        pendingLoadOrigin = ready.origin;
    }
    Json list = Json::array();
    for (const BackgroundLoader::Update& u : f.updates)
        if (u.origin == BackgroundLoader::Origin::Script) list.push_back(u.to_json());
    if (!list.empty()) scripts.deliver_background_loads(list);
}

void Engine::Impl::cancel_background_scene_loads() {
    if (loader) loader->cancel_scene_loads(loadTrace.get());
    if (pendingTraceTag != 0) {  // an async load was about to switch: the newer request wins
        if (loadTrace) loadTrace->load_cancelled(pendingTraceTag);
        pendingTraceTag = 0;
    }
    pendingLoadId = 0;
}

void Engine::Impl::drop_pending_async_switch() {
    if (pendingTraceTag != 0 && loadTrace) loadTrace->load_cancelled(pendingTraceTag);
    hasPendingScene = false;
    pendingScene.clear();
    nextProps.reset();
    pendingKeepProps = false;
    pendingTraceTag = 0;
    pendingLoadId = 0;
}

bool Engine::Impl::cancel_background_load(int id) {
    bool found = false;
    if (id != 0 && pendingLoadId == id) {  // its files were ready this frame: the switch at the end of it does not happen
        drop_pending_async_switch();
        found = true;
    }
    if (loader && loader->cancel(id, loadTrace.get())) found = true;  // running: stops; finished: its files are dropped
    return found;
}

void Engine::Impl::cancel_script_background_loads() {
    if (pendingLoadId != 0 && pendingLoadOrigin == BackgroundLoader::Origin::Script) drop_pending_async_switch();
    if (loader) loader->cancel_origin(BackgroundLoader::Origin::Script, loadTrace.get());
}

namespace {
// Renderer::update(World&) refreshes the cameras (queries) and the parallax offsets without drawing.
template <class R>
void update_visuals(R& r, World& w) {
    if constexpr (requires { r.update(w); }) r.update(w);
}
}  // namespace

void Engine::Impl::settle_visuals() {
    // A clip a script changed, a burst it asked for, an emitter it spawned: shown from the next draw on, whatever the next fixed step
    // does. Time does not move (dt 0), so this fires no frame event and ages no particle; it is the same with and without a renderer.
    update_sprite_animators(world, 0.0f);
    world.particles().update(world, 0.0f);
}

void Engine::Impl::draw(double dt, bool settled) {
    if (!renderer) return;
    if (!settled) settle_visuals();  // a picture drawn outside a frame (a screenshot right after a load) shows what the world holds now
    // Textures, fonts and meshes load when they are first drawn: a capture or a runner that draws directly reads for
    // this engine too (fa/core/load_trace.h).
    const LoadTrace::ReadingFor reading(traceOwner);
    apply_localization();  // entities created or keyed since the frame ended (a paused game, the editor) are drawn translated
    ui.layout(world, design_size(), measure());  // what scripts changed this frame is drawn in place
    renderer->begin_frame();
    renderer->render_world(world, float(dt));
    renderer->end_frame();
    if (gpu) gpu->end_frame();
    else if (windowed && !cfg.editorMode)
        renderer->present(app_gfx_swapchain(), app_framebuffer_width(), app_framebuffer_height(), project.scaleMode);
    renderStale = false;
    lastRenderDt = dt;
    renderedFrame = inFrame || frame == 0 ? frame : frame - 1;  // index of the frame this picture shows
}

void Engine::Impl::render(double dt) {
    settle_visuals();  // with or without a renderer: the world a frame ends with does not depend on drawing
    if (!renderer) {
        // What Renderer::update does without drawing: the cameras the next frame's queries answer with, and the parallax layers.
        cpuCameras.refresh(world, camera_target());
        update_parallax(world, cpuCameras.all().front().position.xy());
        return;
    }
    ProfSystemScope prof(ProfSystem::Render);
    dt *= scripts.time_scale();
    update_visuals(*renderer, world);
    if (cfg.renderMode == RenderMode::OnDemand && !windowed) {
        renderStale = true;
        lastRenderDt = dt;
        return;
    }
    draw(dt, true);  // render() settled the visuals above
}

void Engine::Impl::poll_hot_reload(bool force) {
    const bool assetsOnly = !force && !cfg.hotReload;
    if (assetsOnly && !cfg.hotReloadAssets) return;
    static const char* dirs[] = {"scripts", "tools", "scenes", "assets", "locales", "materials", "shaders"};
    std::map<std::string, std::int64_t> now;
    for (const char* d : dirs) {
        if (!fs::is_directory(d)) continue;
        for (const std::string& f : fs::list(d, true)) now[f] = fs::modified_time(f);
    }
    if (!watchSeeded) {
        watched = std::move(now);
        watchSeeded = true;
        return;
    }
    std::vector<std::string> changed;
    for (const auto& [path, t] : now) {
        auto it = watched.find(path);
        if (it == watched.end() || it->second != t) changed.push_back(path);
    }
    watched = std::move(now);
    for (const std::string& p : changed) {
        const bool songAsset = ends_with(p, ".song.json");
        const bool renderAsset = ends_with(p, ".material.json") ||
            has_ext(p, {".glsl", ".png", ".jpg", ".jpeg", ".tga", ".bmp", ".ttf", ".otf", ".obj", ".gltf", ".glb"});
        if (assetsOnly && !renderAsset && !songAsset && !has_ext(p, {".wav", ".ogg", ".mp3", ".qoa"})) continue;  // scripts, scenes and locales belong to the host
        if (starts_with(p, "locales/") && has_ext(p, {".json"})) {
            if (i18n.enabled()) {
                FA_INFO("hotreload", "String table {} changed on disk, reloading the tables", p);
                reload_localization();
            }
        } else if (has_ext(p, {".js", ".mjs"})) {
            FA_INFO("hotreload", "Reloading script {}", p);
            if (starts_with(p, "tools/")) scripts.reload_tools();
            else scripts.reload_module(p);
        } else if (songAsset) {
            FA_INFO("hotreload", "Song {} changed on disk, the players that play it crossfade to the new version", p);
            audio.reload_song(p);
        } else if (p.size() > 11 && ends_with(p, ".scene.json")) {
            if (p == currentScene) {
                FA_INFO("hotreload", "Scene {} changed on disk, reloading", p);
                std::string err;
                load_scene_impl(p, &err, true, 0, true);  // the scene file changed: same scene, same props
            }
        } else if (renderAsset) {
            // A material, a snippet (the renderer rebuilds every material using it), a texture, font or model.
            if (renderer) renderer->reload_asset(p);
        } else if (has_ext(p, {".wav", ".ogg", ".mp3", ".qoa"})) {
            audio.reload_clip(p);
        }
    }
}

void Engine::Impl::run_frame(double dt, int fixedSteps) {
    const jobs::OwnerScope jobScope(&jobOwner);  // the jobs a system or script of this frame queues are this engine's
    const LoadTrace::ReadingFor reading(traceOwner);  // play.auto and the headless runner call this directly
    const bool profiled = !inFrame;  // a nested frame (a script stepping the game) belongs to the outer one
    if (profiled) Profiler::get().begin_frame();  // no-op unless the profiler is on (fa/core/profiler.h); measures only
    inFrame = true;
    set_log_frame(frame);
    // OnDemand: debug-draw primitives of undrawn frames are dropped (immediate mode: one frame each), but the last
    // frame's survive until the next frame starts so a screenshot still shows them.
    if (renderStale && renderer) renderer->debug().clear();
    // Store answers and events reach scripts here, before anything else of the frame runs (never in the middle of a call).
    {
        ProfSystemScope prof(ProfSystem::Platform);
        if (profiled) {  // results jobs posted for the main thread (fa/core/jobs.h): this engine's, then the shared ones
            jobOwner.run_main_thread_tasks();
            jobs::run_main_thread_tasks();
        }
        platform.frame();
        tick_background_loads();  // scene.preload / assets.preload / async scene.load: this frame's share, then their handles hear it
        scripts.dispatch_platform();
        scripts.dispatch_back();  // the Back button of this frame: input.onBack handlers, else quit
        scripts.dispatch_gamepads();  // pads plugged in or out since the last frame: game.on("gamepadConnected" ...)
    }
    // Hit-stop timers run in real time (they are what slows scripts.time_scale() below) and the effects learn the system's
    // "reduce motion" for the actions that start this frame (fa/scene/feel.h).
    feel_begin_frame(world, dt, scripts.system_reduce_motion());
    const float fdt = float(fixedDt);
    for (int i = 0; i < fixedSteps; ++i) {
        // Everything this step reads of the input (scripts' onFixedUpdate and the events they get) answers for the fixed-step
        // view: a press or release reaches exactly one step, however many (0 to 5) a frame runs, and one that arrives in a
        // frame with no step waits for the next (fa/platform/input.h, "TWO VIEWS").
        Input::FixedScope fixedInput(input);
        {
            ProfSystemScope prof(ProfSystem::Physics);
            physics.sync(world);  // entities spawned since the last step get bodies before scripts query physics
        }
        bind_pending_skins(world);  // skins added since the last step bind at the pose they have now, before the animators move bones
        {
            ProfSystemScope prof(ProfSystem::ScriptsFixedUpdate);
            scripts.fixed_update(fdt);
        }
        // time.scale (game.paused = 0) slows or freezes the simulation, not only the scripts.
        const double scale = scripts.time_scale();
        if (scale > 0.0) {
            {
                ProfSystemScope prof(ProfSystem::Physics);
                physics.step(world, float(fixedDt * scale));
            }
            ProfSystemScope prof(ProfSystem::Animation);
            update_animators(world, float(fixedDt * scale));  // skeletal animation + its events, before they are dispatched
            // ---- After the Animator, before drawing ------------------------------------------------------------------
            // The Animator has just written the 2D pose (the fields keyframed clips drive: Transform, Sprite...) and the
            // 3D palettes. Systems that build on the animated pose run HERE, in this order, and nothing else writes the
            // pose after them: IK2D turns its chains so the tip reaches the target, and what it moves is what gets drawn.
            // The renderer (which deforms skinned sprites from the bones), bounds and the next physics step read the
            // result. The order "clips, then IK, then drawing" is the contract in docs/ANIMATION.md, "Bones and IK".
            update_ik2d(world);
            // IK3D rewrites the palettes of the skinned models after their clips (docs/ANIMATION.md, "3D IK"); its foot rays
            // ask the physics world, which has just stepped.
            update_ik3d(world, float(fixedDt * scale),
                        [this](Vec3 origin, Vec3 dir, float maxDistance, std::int32_t mask, Entity ignore) -> std::optional<GroundHit> {
                            RaycastOptions ro;
                            ro.mask = mask;
                            ro.ignore = ignore;
                            auto hit = physics.raycast3d(world, origin, dir, maxDistance, ro);
                            if (!hit) return std::nullopt;
                            return GroundHit{hit->point, hit->normal};
                        });
        }
        {
            // Videos follow the game clock: they stop with time.scale 0, and a play / pause / seek a script made still applies.
            ProfSystemScope prof(ProfSystem::Animation);
            update_videos(world, float(fixedDt * scale));
        }
        feel_fixed_update(world, fixedDt * scale);  // knockback of entities without a physics body (the game clock WITH hit-stop)
        {
            // Effect documents (vfx.play, Vfx components) follow the game clock like videos: they wait at time.scale 0. The sounds and
            // commands a part fires go through the audio mixer and the command registry like any other call.
            ProfSystemScope prof(ProfSystem::Animation);
            update_vfx(world, float(fixedDt * scale), vfxHost);
        }
        {
            // The SpriteAnimators (clip time, frame, frame events, clipEnded, Sprite.region) and the particles (emission, motion,
            // deaths, autoDestroy) follow the game clock too. They live in fa_scene, not in the renderer: a game with no graphics
            // (--no-graphics, no EGL) steps them exactly like one with a window. Before the events below are dispatched, so what
            // a frame event or clipEnded sends reaches the scripts in this same step.
            ProfSystemScope prof(ProfSystem::Animation);
            update_sprite_animators(world, float(fixedDt * scale));
            world.particles().update(world, float(fixedDt * scale));
        }
        {
            ProfSystemScope prof(ProfSystem::ScriptsEvents);
            scripts.dispatch_events();
        }
        world.advance_clock(fixedDt);
        input.end_fixed_step();  // what this step saw is taken: the next one gets only what arrives from now on
        ++fixedStep;
    }
    // The UI reads this frame's input and sends its events, which scripts get right away. Real time: it works at time.scale 0.
    {
        ProfSystemScope prof(ProfSystem::Ui);
        // Text a plugin's platform keyboard returned (api->submit_text), for the field that took it.
        for (const std::string& typed : plugin_take_submitted_text()) ui.submit_text(world, typed);
        ui.update(world, input, design_size(), float(dt), measure());
    }
    {
        ProfSystemScope prof(ProfSystem::ScriptsEvents);
        scripts.dispatch_events();
    }
    {
        ProfSystemScope prof(ProfSystem::ScriptsUpdate);
        scripts.update(float(dt));
    }
    {
        ProfSystemScope prof(ProfSystem::Audio);
        audio.update(world, float(dt));
        if (!windowed || !cfg.audioDevice) audio.advance_null_device(dt);
    }
    {
        ProfSystemScope prof(ProfSystem::ScriptsLateUpdate);
        scripts.late_update(float(dt));
        scripts.settle_activation();  // panels shown or hidden this frame: onStart / onEnable / onDisable before drawing
    }
    {
        ProfSystemScope prof(ProfSystem::Localization);
        apply_localization();  // keys of entities scripts spawned or edited this frame
    }
    // Shake, flash and squash follow real time times the player's time.scale: they keep moving through a hit-stop. Before
    // drawing, so the poses the renderer reads belong to this frame. The lifetimes of spawned effects run on the game clock
    // (`time_scale()`: a hit-stop or a pause holds them).
    feel_update(world, dt * scripts.user_time_scale(), dt * scripts.time_scale());
    render(dt);
    {
        ProfSystemScope prof(ProfSystem::EndOfFrame);
        end_of_frame(dt);
    }
    ++frame;
    if (recorder.recording()) recorder.timing(frame, dt, fixedSteps, fixedDt);  // [dt, steps] of the frame that just ran
    inFrame = false;
    if (profiled) {
        jobs::end_frame(&jobOwner);  // with 0 workers the jobs nobody waited for run here; closes the job statistics
        Profiler::get().end_frame();
    }
    if (profiled && loadTrace) loadTrace->frame_ended();
    if (profiled && !firstGameFrameMarked) {  // the first frame the game ran, whoever drives it
        firstGameFrameMarked = true;
        startup.mark(StartupTimeline::Mark::FirstGameFrame);
    }
}

void Engine::Impl::end_of_frame(double dt, bool simulated) {
    world.flush();
    apply_scene_change();
    watchTimer += dt;
    if (watchTimer >= 0.25) {
        watchTimer = 0.0;
        poll_hot_reload();
    }
    // Edges belong to the next SIMULATED frame: a paused redraw must not eat a press injected since the last one.
    if (simulated) input.begin_frame();
    else input.discard_idle_motion();
}

// ---------------------------------------------------------------- Engine --
Engine::Engine() : impl_(std::make_unique<Impl>()) { impl_->self = this; }
Engine::~Engine() { shutdown(); }

bool Engine::init(const EngineConfig& config, const GfxEnvironment* gfx, std::string* error) {
    const LoadTrace::ReadingFor reading(impl_->traceOwner);  // what this engine reads is its load trace's (fa/core/load_trace.h)
    impl_->logSeqAtInit = log_last_seq();
    Impl& I = *impl_;
    I.startup.mark(StartupTimeline::Mark::InitBegin);
    // Only what THIS call started is undone: a second init of a running engine fails and leaves the pool running.
    bool startedHere = false;
    std::optional<jobs::OwnerScope> jobScope;
    auto fail = [&](const std::string& msg) {
        FA_ERROR("engine", "{}", msg);
        if (error) *error = msg;
        if (startedHere) {  // init failed after the pool started: its jobs end, then its reference goes back
            if (I.loader) I.loader->stop(nullptr);
            if (auto w = I.jobOwner.wait(); !w) FA_ERROR("engine", "{}", w.error().to_string());
            I.loader.reset();
            I.jobOwner.close();
            jobScope.reset();
            startedHere = false;
            I.jobsStarted = false;
            jobs::stop();
        }
        return false;
    };
    if (I.initialized) return fail("Engine::init called twice");
    I.cfg = config;
    ensure_builtin_components();

    // Project root + project file.
    std::string dir = config.projectDir;
    if (!dir.empty()) {
        std::error_code ec;
        stdfs::path abs = stdfs::absolute(stdfs::path(dir), ec).lexically_normal();
        if (abs.has_filename() == false && abs.has_parent_path()) abs = abs.parent_path();
        dir = abs.generic_string();
        fs::set_project_root(abs);
    }
    if (config.traceLoads) I.loadTrace = std::make_unique<LoadTrace>(I.traceOwner);  // reads are recorded relative to the root set above
    clear_vfx_cache();  // the effect documents are cached by project-relative path: another project (or root) has other files by that name
    auto proj = load_project(dir);
    if (!proj.ok()) return fail(proj.error().to_string());
    I.project = proj.value();
    {
        // The job pool (fa/core/jobs.h): EngineConfig, then FA_JOB_THREADS, then factoria.json runtime.jobThreads, then auto.
        jobs::Settings threads = jobs::Settings::automatic();
        I.jobThreadsSource = "default";
        if (!config.jobThreads.empty()) {
            auto r = jobs::parse_settings_text(config.jobThreads, "EngineConfig.jobThreads");
            if (!r) return fail(r.error().to_string());
            threads = r.value();
            I.jobThreadsSource = "EngineConfig";
        } else if (const char* env = std::getenv("FA_JOB_THREADS"); env && *env) {
            auto r = jobs::parse_settings_text(env, "the FA_JOB_THREADS environment variable");
            if (r) {
                threads = r.value();
                I.jobThreadsSource = "FA_JOB_THREADS";
            } else {
                FA_WARN("engine", "{}; using the project setting", r.error().to_string());
                I.startupProblems.push_back("jobs: " + r.error().to_string());
            }
        }
        if (I.jobThreadsSource == "default" && I.project.jobThreadsSet) {
            threads = I.project.jobThreads;
            I.jobThreadsSource = std::string(kProjectFileName);
        }
        if (auto r = jobs::start(threads); !r) return fail(r.error().to_string());
        startedHere = true;
        I.jobsStarted = true;
        jobScope.emplace(&I.jobOwner);  // what init queues (a first scene's loads) belongs to this engine
        I.commands.set_job_owner(&I.jobOwner);
        // Background loading: its IO thread runs only when the pool has worker threads (fa/core/background_io.h).
        I.loader = std::make_unique<BackgroundLoader>(&I.jobOwner, I.traceOwner);
    }
    // Screenshots the engine named itself (game.screenshot without a path) pile up over a long session: drop the old ones.
    if (!dir.empty()) prune_screenshots(stdfs::path(dir));
    I.projectMtime = fs::modified_time(kProjectFileName);
    I.paused = config.editorMode;
    {
        auto date = parse_calendar_date(config.date.empty() ? std::string_view(kDefaultDate) : std::string_view(config.date), "the date");
        if (!date.ok()) return fail(date.error().to_string());
        date->utcOffsetMinutes = config.dateUtcOffsetMinutes;
        I.scripts.set_start_date(date.value());
    }
    I.windowed = gfx != nullptr && !config.headless;
    if (I.windowed && !config.editorMode) {
        I.appWindow = std::make_unique<AppWindowControl>();
        I.clipboard.use_system(true);
        speech().set_backend_factory(make_system_speech_backend);  // headless runs, tests and the editor only record
    }
    I.ui.set_clipboard(&I.clipboard);  // a TextField's Ctrl+V / Ctrl+C
    I.ui.set_i18n(&I.i18n);            // a tooltip's locale keys
    // Where a world-space Interactable is on the screen: the renderer's camera for the pointer (perspective and viewports included),
    // the scene's orthographic cameras when there is no renderer.
    I.ui.set_world_projection([&I](Vec3 p, const Vec2* pointer) {
        Renderer* r = I.renderer.get();
        if (r && r->initialized() && !r->cameras().empty()) {
            const Entity cam = pointer ? r->camera_at(*pointer) : kNullEntity;
            return r->world_to_screen(p, cam != kNullEntity && I.world.alive(cam) ? cam : kNullEntity);
        }
        if (!r && !I.cpuCameras.cameras().empty()) {  // no renderer: the very maths of its camera (fa/scene/camera_geometry.h)
            const Entity cam = pointer ? I.cpuCameras.camera_at(*pointer) : kNullEntity;
            return I.cpuCameras.world_to_screen(p, cam != kNullEntity && I.world.alive(cam) ? cam : kNullEntity);
        }
        return ortho_view(I.world, I.design_size(), kNullEntity, pointer).to_screen(p);
    });

    // The culling mask (Camera.showTags / hideTags) of the camera that draws at the pointer: a world-space Interactable it does not draw
    // takes no pointer through it.
    I.ui.set_world_mask([&I](const Vec2* pointer) {
        Renderer* r = I.renderer.get();
        Entity cam;
        if (r && r->initialized() && !r->cameras().empty()) {
            cam = pointer ? r->camera_at(*pointer) : r->cameras().front();
        } else if (!r && !I.cpuCameras.cameras().empty()) {
            cam = pointer ? I.cpuCameras.camera_at(*pointer) : I.cpuCameras.cameras().front();
        } else if (pointer) {
            cam = camera_containing(I.world, I.design_size(), *pointer);
        } else {
            const std::vector<Entity> cams = rendering_cameras(I.world);
            if (!cams.empty()) cam = cams.front();
        }
        return CameraMask::of(I.world, cam);
    });

    I.ui.set_surface_pointer(make_ui_surface_pointer(I));  // the pointer through a render target shown on a mesh
    I.ui.set_page_aim(make_ui_page_aim(I));                // ...and the way back: where to click a widget only such a mesh shows

    // World + input.
    I.world.rng().reseed(config.seed);
    I.world.feel().reduceMotionSetting.reset();  // the player's feel choices belong to a run: an engine starts following the system
    I.world.feel().reducedEffectsSetting.reset();
    I.apply_project_settings();
    I.setup_localization();
    // The fonts of the start language, for the CPU measurer of a run with no renderer (the renderer gets them below).
    I.apply_fallback_fonts();

    // Graphics.
    if (config.graphics) {
        RendererDesc rd;
        rd.designWidth = config.width > 0 ? config.width : I.project.width;
        rd.designHeight = config.height > 0 ? config.height : I.project.height;
        rd.headless = !I.windowed;
        rd.adoptContext = I.windowed && config.adoptGraphicsContext;
        std::string gerr;
        bool ok = false;
        if (I.windowed) {
            I.renderer = std::make_unique<Renderer>();
            ok = I.renderer->init(rd, *gfx, &gerr);
        } else {
            I.gpu = std::make_unique<HeadlessGpu>();
            ok = I.gpu->init(&gerr);
            if (ok) {
                I.renderer = std::make_unique<Renderer>();
                ok = I.renderer->init(rd, I.gpu->environment(), &gerr);
            }
        }
        if (!ok) {
            std::string msg = "Graphics unavailable (" + gerr + "); running with graphics=false: no rendering or screenshots.";
            FA_WARN("engine", "{}", msg);
            I.startupProblems.push_back(msg);
            if (I.renderer) I.renderer->shutdown();
            I.renderer.reset();
            if (I.gpu) I.gpu->shutdown();
            I.gpu.reset();
            // The CPU measurer takes over; it was not kept in step while a renderer was.
            I.cpuText.set_text_scale(I.self->text_scale());
            I.cpuText.set_ui_scale(I.world.ui_scale());
        } else {
            if (config.shaderCompiler) I.renderer->set_shader_compiler(config.shaderCompiler);  // before any scene loads
            I.renderer->set_ui_scale(I.world.ui_scale());  // the project's, applied before the renderer existed
            I.apply_fallback_fonts();  // the renderer did not exist when the start language was chosen
            I.renderer->set_rich_text_style(I.richStyle);  // nor when the project settings were read
            FA_INFO("engine", "Graphics: {}",
                    I.gpu ? I.gpu->description()
                          : std::format("window {}x{} px (dpi scale {})", app_framebuffer_width(), app_framebuffer_height(),
                                        app_dpi_scale()));
        }
    }

    // Physics, audio, scripts.
    PhysicsSettings ps;
    ps.pixelsPerMeter = I.project.pixelsPerMeter;
    I.physics.init(ps);
    std::string aerr;
    if (!I.audio.init(I.windowed && config.audioDevice, &aerr)) {
        FA_WARN("audio", "Audio init failed: {}", aerr);
        I.startupProblems.push_back("audio: " + aerr);
    }
    I.audio.set_clock(&I.world);  // play log entries carry the frame/time scripts see
    device_overridden(device_info());  // MusicPlayer.mode "auto" chooses between live synthesis and stems for this device (docs/MUSIC.md)
    register_builtin_commands(*this, I);  // before scripts.init: JS tools (tools/*.js) are added on top
    // Native plugins: their commands, and their functions for the scripts (plugins.<name>), before scripts.init.
    PluginInstall installed = install_plugins(I.project, dir, config.pluginDir, I.commands, I.scripts);
    for (std::string& problem : installed.problems) I.startupProblems.push_back(std::move(problem));
    I.pluginSteamDeck = installed.steamDeck;
    plugin_take_submitted_text();  // text meant for an earlier engine of this process
    if (!installed.textInputs.empty()) {
        // The platform's own keyboard: the first plugin that answers 1 takes the field and is told when it loses the focus.
        auto taker = std::make_shared<int>(-1);
        I.ui.set_text_input_handler([&I, inputs = installed.textInputs, taker](const TextInputRequest& r) {
            const Vec2 a = I.designToWindow ? I.designToWindow({r.rect.x, r.rect.y}) : Vec2{r.rect.x, r.rect.y};
            const Vec2 b = I.designToWindow ? I.designToWindow({r.rect.x + r.rect.w, r.rect.y + r.rect.h})
                                            : Vec2{r.rect.x + r.rect.w, r.rect.y + r.rect.h};
            FaTextInput in{};
            in.focused = r.focused ? 1 : 0;
            in.x = a.x;
            in.y = a.y;
            in.width = b.x - a.x;
            in.height = b.y - a.y;
            in.text = r.text.c_str();
            in.multiline = r.multiline ? 1 : 0;
            in.max_length = r.maxLength;
            in.password = r.password ? 1 : 0;
            if (!r.focused) {
                if (*taker >= 0 && *taker < int(inputs.size())) inputs[std::size_t(*taker)].handler(&in, inputs[std::size_t(*taker)].user);
                *taker = -1;
                return false;
            }
            for (std::size_t i = 0; i < inputs.size(); ++i)
                if (inputs[i].handler(&in, inputs[i].user) != 0) {
                    *taker = int(i);
                    return true;
                }
            *taker = -1;
            return false;
        });
    }
    BackendChoice choice = choose_platform_backend(config.platformBackend, config.platformFallback, I.platform.catalog(), installed,
                                                   runtime_platform());
    for (const std::string& warning : choice.warnings) {
        FA_WARN("platform", "{}", warning);
        I.startupProblems.push_back("platform: " + warning);
    }
    if (!choice.reason.empty()) FA_INFO("platform", "{}", choice.reason);
    else FA_DEBUG("platform", "backend '{}'", choice.backend->name());
    // A shipped game (the player sets platformFallback "none") is a release; development runs, tests and the MCP server are not.
    I.platform.set_release(config.platformFallback == "none" && config.platformBackend != "fake" && choice.backend->name() != "fake");
    I.platform.set_backend(std::move(choice.backend), choice.why);
    if (choice.adsBackend) {
        FA_INFO("platform", "ads backend '{}': {}", choice.adsBackend->name(), choice.adsWhy);
        I.platform.set_ads_backend(std::move(choice.adsBackend), choice.adsWhy);
    } else if (!choice.adsWhy.empty()) {
        FA_DEBUG("platform", "{}", choice.adsWhy);
        I.platform.set_ads_backend(nullptr, choice.adsWhy);  // platform.state's adsWhy says why no ads plugin is in use
    }
    // http.fetch: the system's HTTP client, except in headless runs, tests, `factoria call` and the MCP server (they ask for the fake
    // backend, which answers what game.platform.respond scripted and never touches the network).
    if (config.platformBackend != "fake") {
        auto client = make_system_http_client();
        std::string why = "the system's HTTP client (" + client->name() + ")";
        if (!client->available()) {
            why = client->unavailable_reason();  // the sentence http.fetch's "unavailable" answer carries
            FA_INFO("platform", "http.fetch is not available on this computer: {}", why);
        }
        I.platform.set_http_backend(make_http_backend(std::move(client)), why);
    }
    std::string serr;
    if (config.scriptDebugger) I.scripts.set_debugger(config.scriptDebugger);
    I.scripts.set_exported_player(config.exportedPlayer);
    if (!I.scripts.init(*this, &serr)) {
        FA_ERROR("script", "Script system init failed: {}", serr);
        I.startupProblems.push_back("script: " + serr);
    }
    if (config.memoryStorage) I.scripts.set_storage_mode(StorageMode::Memory);

    I.initialized = true;
    set_log_frame(0);
    I.recorder.set_frame_source(&I.frame);  // the input recorder hears every event of the game (start_input_recording)
    I.input.set_observer(&I.recorder);
    I.clipboard.set_recorder(&I.recorder);
    I.platform.set_frame_clock(&I.frame);  // the frame of each http.fetch request, for the recorder

    // Start scene (errors are kept for game.state / script.errors; they do not abort init).
    std::string scenePath = config.scene.empty() ? I.project.mainScene : config.scene;
    if (config.sceneProps.is_object()) I.nextProps = config.sceneProps;
    if (!scenePath.empty()) {
        std::string serrText;
        if (!fs::exists(scenePath) && !fs::is_absolute(scenePath)) {
            std::string msg = "Start scene '" + scenePath + "' not found";
            std::vector<std::string> scenes = fs::list("scenes", true, ".json");
            std::string hint = scenes.empty() ? "Create it, or set mainScene in factoria.json." : did_you_mean(scenePath, scenes);
            I.sceneIssues = {msg + " (hint: " + hint + ")"};
            I.sceneErrorCount = 1;
            I.currentScene = scenePath;
            I.world.set_scene_path(scenePath);
            FA_ERROR("scene", "{} (hint: {})", msg, hint);
        } else {
            I.load_scene_impl(scenePath, &serrText);
        }
        I.implicitStartScene = config.scene.empty();  // load_scene_impl cleared it; the default scene was not chosen by anyone
    }
    I.nextProps.reset();  // a start scene that could not load takes none
    if (I.windowed && I.project.scaleMode == ScaleMode::Expand) { /* resize handler adapts the target */ }
    I.poll_hot_reload();  // seeds the watch snapshot when hot reload is active
    I.startup.mark(StartupTimeline::Mark::InitEnd);
    return true;
}

void Engine::shutdown() {
    Impl& I = *impl_;
    end_load_trace();  // also after a failed init
    if (!I.initialized) return;
    I.initialized = false;
    // This engine's jobs run to the end before the systems they may touch go away; its main-thread tasks still queued
    // are dropped. Other engines' jobs keep running: the pool joins its threads when the last engine stops it.
    {
        const jobs::OwnerScope jobScope(&I.jobOwner);
        // Background loads stop first: the IO thread lets go of this engine's files, and the decodes still running are
        // this engine's jobs, which the wait below sees through. Their results are thrown away.
        if (I.loader) I.loader->stop(nullptr);
        if (auto w = I.jobOwner.wait(); !w) FA_ERROR("engine", "{}", w.error().to_string());
        I.loader.reset();
        I.jobOwner.close();
    }
    if (I.jobsStarted) {
        I.jobsStarted = false;
        jobs::stop();
    }
    clear_vfx_cache();
    I.scripts.shutdown();
    I.appWindow.reset();
    I.audio.shutdown();
    I.physics.shutdown();
    I.world.clear();
    if (I.renderer) I.renderer->shutdown();
    I.renderer.reset();
    if (I.gpu) I.gpu->shutdown();
    I.gpu.reset();
}

void Engine::begin_load_trace() {
    end_load_trace();
    impl_->loadTrace = std::make_unique<LoadTrace>(impl_->traceOwner);
}

LoadTrace::Owner Engine::load_trace_owner() const { return impl_->traceOwner; }

Json Engine::loading_report() const {
    if (!impl_->loadTrace) return Json();
    Json report = impl_->loadTrace->report();
    // An editor engine started once, with the editor: its init numbers say nothing about a Play session, so there is no
    // "startup" there (docs/PERFORMANCE.md, "Startup"). A player, `factoria run` and `play.auto` start with their session.
    if (!impl_->cfg.editorMode) report["startup"] = startup_report();
    return report;
}

StartupTimeline& Engine::startup_timeline() { return impl_->startup; }

int Engine::warm_step(const GfxSwapchain& swapchain) {
    Impl& I = *impl_;
    if (!I.initialized) return 0;
    const int left = I.windowed && I.renderer ? I.renderer->warm_step(swapchain, I.world) : 0;
    if (left == 0) I.startup.mark(StartupTimeline::Mark::WarmEnd);
    return left;
}

Json Engine::startup_report() const {
    Json j = impl_->startup.to_json();
    j["gpu"] = impl_->renderer && impl_->renderer->initialized() ? impl_->renderer->startup_report() : Json();
    return j;
}

void Engine::end_load_trace() {
    Impl& I = *impl_;
    if (!I.loadTrace) return;
    std::unique_ptr<LoadTrace> trace = std::move(I.loadTrace);
    if (I.cfg.loadOrderSink) {
        LoadOrder order = trace->order();
        trace.reset();  // stop recording before the sink runs: what it reads is not the game's
        // It also runs from ~Engine (shutdown), where an exception would end the process: a sink that throws loses
        // this session's order, nothing else.
        if (!order.empty()) {
            try {
                I.cfg.loadOrderSink(order);
            } catch (const std::exception& e) {
                FA_ERROR("engine", "The load order of this session was not recorded: {}", e.what());
            }
        }
    }
}

void Engine::frame(double dt) {
    const LoadTrace::ReadingFor reading(impl_->traceOwner);
    Impl& I = *impl_;
    if (!I.initialized) return;
    dt = std::clamp(dt, 0.0, kMaxFrameDt);
    if (I.paused) {
        const jobs::OwnerScope jobScope(&I.jobOwner);
        I.inFrame = true;
        I.jobOwner.run_main_thread_tasks();  // a paused game still takes the results of its jobs (a load that finished)
        jobs::run_main_thread_tasks();
        I.audio.service();  // the sounds a paused game (or the editor) still plays keep their streams decoded
        I.render(0.0);
        I.end_of_frame(dt, false);
        I.inFrame = false;
        jobs::end_frame(&I.jobOwner);
        return;
    }
    I.accumulator += dt;
    int steps = 0;
    while (I.accumulator >= I.fixedDt && steps < 5) {
        I.accumulator -= I.fixedDt;
        ++steps;
    }
    if (steps == 5 && I.accumulator > I.fixedDt) I.accumulator = 0.0;  // spiral of death: drop the backlog
    I.run_frame(dt, steps);
}

void Engine::step(int frames) {
    const LoadTrace::ReadingFor reading(impl_->traceOwner);
    Impl& I = *impl_;
    if (!I.initialized) return;
    for (int i = 0; i < frames && !I.quit; ++i) I.run_frame(I.fixedDt, 1);
}

bool Engine::load_scene(std::string_view path, std::string* error) {
    const LoadTrace::ReadingFor reading(impl_->traceOwner);
    return impl_->load_scene_impl(std::string(path), error);
}
bool Engine::load_scene(std::string_view path, const Json& props, std::string* error) {
    const LoadTrace::ReadingFor reading(impl_->traceOwner);
    if (props.is_object()) impl_->nextProps = props;
    return impl_->load_scene_impl(std::string(path), error);
}

bool Engine::load_scene_json(const Json& scene, std::string_view sourceName, std::string* error) {
    const LoadTrace::ReadingFor reading(impl_->traceOwner);
    return impl_->load_scene_json_impl(scene, sourceName, error);
}

void Engine::render_now() {
    const LoadTrace::ReadingFor reading(impl_->traceOwner);
    Impl& I = *impl_;
    if (!I.renderer) return;
    if (I.renderStale) I.draw(I.lastRenderDt);
}
bool Engine::render_pending() const { return impl_->renderStale; }

void Engine::reload_scene() {
    const LoadTrace::ReadingFor reading(impl_->traceOwner);
    Impl& I = *impl_;
    if (I.currentScene.empty()) return;
    std::string err;
    I.load_scene_impl(I.currentScene, &err, true);
}

bool Engine::paused() const { return impl_->paused; }
void Engine::set_paused(bool p) { impl_->paused = p; }
std::uint64_t Engine::frame_index() const { return impl_->frame; }
std::uint64_t Engine::fixed_step_index() const { return impl_->fixedStep; }
bool Engine::quit_requested() const { return impl_->quit; }
const ProjectSettings& Engine::project() const { return impl_->project; }
const EngineConfig& Engine::config() const { return impl_->cfg; }
HeadlessGpu* Engine::headless_gpu() { return impl_->gpu.get(); }
PlatformServices* Engine::platform_services() { return &impl_->platform; }
const I18n* Engine::i18n() { return &impl_->i18n; }
const RichTextStyle* Engine::rich_text_style() { return &impl_->richStyle; }
std::string Engine::set_language(std::string_view language) {
    auto switched = impl_->switch_language(language);
    return switched.ok() ? std::string() : switched.error().to_string();
}

ScriptSystem& Engine::scripts() { return impl_->scripts; }

bool Engine::capture_scaled(Image& img, double scale, std::string* error) {
    Impl& I = *impl_;
    auto fail = [&](const std::string& m) {
        if (error) *error = m;
        return false;
    };
    if (!I.renderer)
        return fail("No renderer: the engine runs with graphics=false" +
                    std::string(I.startupProblems.empty() ? "" : " (" + I.startupProblems.front() + ")") +
                    ". Run with a GPU (headless EGL needs Mesa) to take screenshots.");
    constexpr double kMaxSide = 8192;
    if (!(scale >= Renderer::kMinRenderScale && scale <= Renderer::kMaxRenderScale))
        return fail("Screenshot scale " + (std::isfinite(scale) ? std::to_string(scale) : std::string("(not a number)")) +
                    " is out of range. scale draws the same design-size frame into an image scale times larger (sharp, not "
                    "upscaled); it must be between 0.25 and 4. Example: scale 1.5 on a 1280x720 game writes a 1920x1080 PNG.");
    if (scale * std::max(I.renderer->target_width(), I.renderer->target_height()) > kMaxSide)
        return fail("Screenshot scale " + std::to_string(scale) + " would make an image wider than 8192 px (the game is " +
                    std::to_string(I.renderer->target_width()) + "x" + std::to_string(I.renderer->target_height()) +
                    "). Use a smaller scale.");
    struct ScaleGuard {  // back to the held scale (1 unless hold_render_scale) afterwards; the next picture is drawn again
        Impl& I; bool on;
        ~ScaleGuard() { if (on) { I.renderer->set_render_scale(float(I.heldScale)); I.renderStale = true; } }
    } guard{I, scale != I.heldScale};
    if (guard.on) I.renderer->set_render_scale(float(scale));  // new images: the picture must be drawn again
    if (I.renderStale) I.draw(I.lastRenderDt);  // OnDemand: draw the state of the current frame
    // Also show changes made since the last draw without stepping (a test or script_eval opening a panel right after an
    // earlier screenshot). A game window presents its own frames: there only the initial state is drawn here.
    else if (!I.inFrame && (guard.on || !I.windowed || I.cfg.editorMode || I.frame == 0)) I.draw(0.0);
    std::string cerr;
    if (!I.renderer->capture(img, &cerr)) return fail("Screenshot capture failed: " + cerr);
    return true;
}

Engine::RegionPlan Engine::plan_region(Vec2 view, const Rect& r, double zoom) {
    RegionPlan p;
    constexpr double kMaxSide = 8192;
    if (!(zoom >= 0.25 && zoom <= 32.0)) {
        p.error = "zoom " + (std::isfinite(zoom) ? std::to_string(zoom) : std::string("(not a number)")) +
                  " is out of range. zoom must be between 0.25 and 32. Example: region [600,0,80,720] with zoom 8 gives 640x5760.";
        return p;
    }
    p.x1 = view.x;
    p.y1 = view.y;
    if (r.w > 0 && r.h > 0) {
        p.x0 = std::max(0.0, double(r.x));
        p.y0 = std::max(0.0, double(r.y));
        p.x1 = std::min(double(view.x), double(r.x) + r.w);
        p.y1 = std::min(double(view.y), double(r.y) + r.h);
        if (!(p.x1 > p.x0 && p.y1 > p.y0)) {
            p.error = "region [" + std::to_string(int(r.x)) + ", " + std::to_string(int(r.y)) + ", " + std::to_string(int(r.w)) + ", " +
                      std::to_string(int(r.h)) + "] is outside the game view (" + std::to_string(int(view.x)) + "x" + std::to_string(int(view.y)) +
                      " design pixels, origin top-left). Use [x, y, width, height] inside it.";
            return p;
        }
    }
    p.width = std::max(1, int(std::lround((p.x1 - p.x0) * zoom)));
    p.height = std::max(1, int(std::lround((p.y1 - p.y0) * zoom)));
    if (p.width > kMaxSide || p.height > kMaxSide)
        p.error = "The picture would be " + std::to_string(p.width) + "x" + std::to_string(p.height) +
                  " px, over the 8192 px limit per side. Use a smaller region or zoom.";
    return p;
}

bool Engine::capture_region(Image& out, const Rect& region, double zoom, std::string* error) {
    Impl& I = *impl_;
    if (!I.renderer) {
        Image probe;
        return capture_scaled(probe, 1.0, error);  // the same message as a screenshot
    }
    const double vw = I.renderer->target_width(), vh = I.renderer->target_height();
    const RegionPlan plan = plan_region({float(vw), float(vh)}, region, zoom);
    if (!plan.error.empty()) {
        if (error) *error = plan.error;
        return false;
    }
    // Native re-render at the largest render scale that is allowed (and fits 8192 px for the whole frame); beyond it the
    // rest of the magnification is nearest-neighbour.
    constexpr double kMaxSide = 8192;
    double native = std::min({zoom, double(Renderer::kMaxRenderScale), kMaxSide / std::max(vw, vh)});
    native = std::max(native, double(Renderer::kMinRenderScale));
    Image full;
    if (!capture_scaled(full, native, error)) return false;
    const double sx = double(full.width) / vw, sy = double(full.height) / vh;  // pixels per design pixel actually rendered
    const int cx = int(std::lround(plan.x0 * sx)), cy = int(std::lround(plan.y0 * sy));
    const int cw = std::max(1, int(std::lround((plan.x1 - plan.x0) * sx))), ch = std::max(1, int(std::lround((plan.y1 - plan.y0) * sy)));
    Image part = crop_image(full, cx, cy, cw, ch);
    out = (part.width == plan.width && part.height == plan.height) ? std::move(part) : resize_nearest(part, plan.width, plan.height);
    return true;
}

bool Engine::capture_frame(Image& out, std::string* error) { return capture_scaled(out, impl_->heldScale, error); }

bool Engine::hold_render_scale(double scale, std::string* error) {
    Impl& I = *impl_;
    Image probe;
    if (!I.renderer) return capture_scaled(probe, scale, error);  // the same message as a screenshot
    if (scale == I.heldScale) return true;
    // Validate with the screenshot rules (range, 8192 px), without drawing.
    constexpr double kMaxSide = 8192;
    if (!(scale >= Renderer::kMinRenderScale && scale <= Renderer::kMaxRenderScale) ||
        scale * std::max(I.renderer->target_width(), I.renderer->target_height()) > kMaxSide) {
        return capture_scaled(probe, scale, error);  // fails with the explanation
    }
    I.heldScale = scale;
    I.renderer->set_render_scale(float(scale));
    I.renderStale = true;
    return true;
}

bool Engine::screenshot_scaled(std::string_view path, double scale, std::string* error) {
    return screenshot_simulated(path, scale, {}, error);
}

bool Engine::screenshot_simulated(std::string_view path, double scale, std::string_view simulate, std::string* error) {
    ColorSimulation mode = ColorSimulation::None;
    if (!simulate.empty()) {
        auto parsed = parse_color_simulation(simulate);
        if (!parsed.ok()) {
            if (error) *error = parsed.error().to_string();
            return false;
        }
        mode = *parsed;
    }
    Image img;
    if (!capture_scaled(img, scale, error)) return false;
    simulate_color_vision(img, mode);
    auto r = save_png(img, path);
    if (!r.ok()) {
        if (error) *error = r.error().to_string();
        return false;
    }
    return true;
}

Json Engine::state(const Json& query) {
    Impl& I = *impl_;
    World& w = I.world;
    bool includeDefaults = query.value("includeDefaults", false);
    std::size_t maxEntities = std::size_t(std::max(0, query.value("maxEntities", 200)));
    std::vector<std::string> comps;
    if (query.contains("components") && query["components"].is_array())
        for (const Json& c : query["components"])
            if (c.is_string()) comps.push_back(to_lower(c.get<std::string>()));
    std::vector<Entity> list;
    Json missing = Json::array();
    if (query.contains("entities") && query["entities"].is_array()) {
        for (const Json& id : query["entities"]) {
            if (!id.is_string()) continue;
            Entity e = w.find(id.get<std::string>());
            if (e) list.push_back(e);
            else missing.push_back(id);
        }
    } else {
        list = w.entities();
    }
    Json ents = Json::array();
    EntityJsonOptions eo;
    eo.includeChildren = false;
    eo.includeDefaults = includeDefaults;
    eo.includeRuntime = true;
    for (Entity e : list) {
        if (ents.size() >= maxEntities) break;
        Json j = entity_to_json(w, e, eo);
        if (Entity p = w.parent(e)) j["parent"] = w.id_of(p);
        if (!comps.empty() && j.contains("components")) {
            Json filtered = Json::object();
            for (auto it = j["components"].begin(); it != j["components"].end(); ++it)
                if (std::find(comps.begin(), comps.end(), to_lower(it.key())) != comps.end()) filtered[it.key()] = *it;
            j["components"] = filtered;
        }
        ents.push_back(std::move(j));
    }

    Json out = Json::object();
    out["frame"] = I.frame;
    out["time"] = w.time();
    out["scene"] = I.currentScene;
    out["paused"] = I.paused;
    out["entityCount"] = w.entity_count();
    out["entities"] = ents;
    if (ents.size() < list.size()) out["truncated"] = true;
    if (!missing.empty()) out["missingEntities"] = missing;
    out["physics"] = I.physics.debug_state(w);
    Json errs = Json::array();
    for (const ScriptError& e : I.scripts.errors()) errs.push_back(script_error_json(e));
    out["scriptErrors"] = errs;
    Json issues = Json::array();
    for (const std::string& s : I.sceneIssues) issues.push_back(s);
    out["sceneIssues"] = issues;
    Json logs = Json::array();
    for (const LogEntry& l : recent_logs(50, LogLevel::Warn, I.logSeqAtInit)) {
        // Only this engine's logs, and no wall-clock time / global seq: state dumps must be reproducible.
        logs.push_back(Json::object({{"frame", l.frame}, {"level", log_level_name(l.level)}, {"category", l.category},
                                     {"message", l.message}}));
    }
    out["recentLogs"] = logs;
    if (I.renderer) {
        Json rs = I.renderer->stats().to_json();
        if (rs.is_object()) rs.erase("cpuMs");
        out["renderStats"] = rs;
    } else {
        out["renderStats"] = nullptr;
    }
    if (I.cfg.renderMode == RenderMode::OnDemand) out["renderedFrame"] = I.renderedFrame;
    out["audio"] = I.audio.stats();
    out["input"] = I.input.snapshot();
    return out;
}


// ScriptHost
std::string Engine::load_scene_json_now(const Json& scene, std::string_view sourceName) {
    std::string err;
    return impl_->load_scene_json_impl(scene, sourceName, &err) ? std::string() : (err.empty() ? "scene load failed" : err);
}
World& Engine::world() { return impl_->world; }
Input& Engine::input() { return impl_->input; }
Audio& Engine::audio() { return impl_->audio; }
Physics& Engine::physics() { return impl_->physics; }
// Scripts reach the renderer for camera helpers (screen<->world conversion, screen size). In OnDemand mode those need
// the camera of a drawn frame, so the first access after simulated-but-undrawn frames draws the current state.
Renderer* Engine::renderer() {
    // No draw needed here: camera queries (world_to_screen, screen_to_world...) are refreshed by
    // Renderer::update, which runs every simulated frame even when drawing is skipped (OnDemand).
    return impl_->renderer.get();
}
UiSystem* Engine::ui() { return &impl_->ui; }
CommandRegistry& Engine::commands() { return impl_->commands; }
void Engine::set_design_to_window(std::function<Vec2(Vec2)> mapper) { impl_->designToWindow = std::move(mapper); }

Vec2 Engine::design_size() const { return impl_->design_size(); }
Json Engine::project_settings() const {
    Json j = impl_->project.to_json();
    j["seed"] = impl_->cfg.seed;  // the effective run seed (scripts reseed test files with it)
    return j;
}
double Engine::fixed_dt() const { return impl_->fixedDt; }
WindowControl* Engine::window() { return impl_->appWindow.get(); }
Clipboard* Engine::clipboard() { return &impl_->clipboard; }
void Engine::start_input_recording() {
    Impl& I = *impl_;
    const std::uint64_t f = I.frame;
    I.recorder.start(f);
    I.platform.log_http(false);  // http.fetch answers go into the replay too, from the requests made from now on
    I.platform.log_http(true);
    const CalendarDate today = I.scripts.today();
    I.recorder.set_date(today.iso(), today.utcOffsetMinutes, today.iso_time());
    // What is held now is part of the session: the replay starts from nothing.
    const Input& in = I.input;
    for (int k = 1; k < int(Key::Count); ++k)
        if (in.key_down(Key(k))) I.recorder.key(f, Key(k), true);
    I.recorder.mouse_position(f, in.mouse_position());
    for (MouseButton b : {MouseButton::Left, MouseButton::Right, MouseButton::Middle})
        if (in.mouse_down(b)) I.recorder.mouse_button(f, b, true);
    for (int p = 0; p < kMaxGamepads; ++p) {
        if (!in.gamepad_connected(p)) continue;
        I.recorder.gamepad_connected(f, p, true);
        for (int b = 0; b < int(GamepadButton::Count); ++b)
            if (in.gamepad_down(p, GamepadButton(b))) I.recorder.gamepad_button(f, p, GamepadButton(b), true);
        for (int a = 0; a < int(GamepadAxis::Count); ++a)
            if (const float v = in.gamepad_raw_axis(p, GamepadAxis(a)); v != 0.0f) I.recorder.gamepad_axis(f, p, GamepadAxis(a), v);
    }
    for (const Touch& t : in.touches()) I.recorder.touch_begin(f, t.id, t.position);
}
Json Engine::stop_input_recording() {
    Impl& I = *impl_;
    if (I.recorder.recording())
        for (const HttpLogEntry& e : I.platform.take_http_log()) I.recorder.http(e.frame, e.answer);  // the answered requests
    I.platform.log_http(false);
    I.recorder.stop();
    return I.recorder.input();
}
bool Engine::input_recording() const { return impl_->recorder.recording(); }
std::size_t Engine::input_recording_frames() const { return impl_->recorder.frame_count(); }
void Engine::log_clipboard_reads(bool on) { impl_->clipboard.log_reads(on); }
std::vector<std::string> Engine::take_clipboard_reads() { return impl_->clipboard.take_reads(); }

double Engine::render_scale() const { return impl_->renderer ? impl_->heldScale : ScriptHost::render_scale(); }

std::string Engine::set_render_scale(double scale) {
    Impl& I = *impl_;
    if (!I.renderer) return ScriptHost::set_render_scale(scale);  // no graphics: remembered, nothing to resize
    std::string err;
    return hold_render_scale(scale, &err) ? std::string() : err;
}

void Engine::device_overridden(const Json& device) {
    MusicDeviceProfile music;
    music.formFactor = device.value("formFactor", std::string("desktop"));
    music.tier = device.value("tier", std::string("high"));
#if defined(__EMSCRIPTEN__)
    music.web = true;
#endif
    impl_->audio.set_music_device(music);
}

Json Engine::device_info() const {
    const Impl& I = *impl_;
    if (!I.appWindow) return ScriptHost::device_info();  // headless runs, tests, the editor: fixed values
    std::string form = "desktop";
    if (app_is_mobile()) {
        int w = 0, h = 0;
        app_window_size(w, h);  // logical pixels: a tablet is 600 or more on its short side
        form = std::min(w, h) >= 600 ? "tablet" : "phone";
    }
    const double memoryGB = std::round(double(total_memory_bytes()) / (1024.0 * 1024.0 * 1024.0) * 10.0) / 10.0;
    const std::string backend = Renderer::backend_name();
    std::string tier = "medium";  // unknown memory (web) stays here
    if (backend == "dummy") tier = "low";
    else if (memoryGB > 0) tier = memoryGB < 3.5 ? "low" : (memoryGB < 7.5 || (form != "desktop" && memoryGB < 5.5)) ? "medium" : "high";
    // The Steam plugin knows for sure when Steam is up; without it the SteamDeck=1 environment variable that Steam sets for the
    // games it starts on a Deck (and "SteamDeck=0" in a launch option turns off) is the answer.
    bool steamDeck = I.pluginSteamDeck == 1;
    if (I.pluginSteamDeck < 0) {
        const char* env = std::getenv("SteamDeck");
        steamDeck = env && std::string_view(env) == "1";
    }
    return Json::object({{"formFactor", form}, {"gpuBackend", backend}, {"memoryGB", memoryGB}, {"tier", tier},
                         {"steamDeck", steamDeck}, {"handheld", steamDeck || form != "desktop"}});
}

Json Engine::render_stats_now() {
    Impl& I = *impl_;
    if (!I.renderer) return Json();
    render_now();  // a headless test may not have drawn a frame yet (OnDemand, or before the first step)
    Json j = I.renderer->stats().to_json();
    j.erase("cpuMs");  // wall-clock: not for scripts that must stay reproducible
    j["textureMB"] = std::round(double(I.renderer->texture_bytes()) / (1024.0 * 1024.0) * 100.0) / 100.0;
    j["width"] = int(std::lround(I.renderer->target_width() * I.heldScale));  // the size of the picture drawn
    j["height"] = int(std::lround(I.renderer->target_height() * I.heldScale));
    j["renderScale"] = I.heldScale;
    return j;
}

double Engine::preload_time_budget_ms() const {
    // A game with a window reads ahead until a few ms of the frame are gone (at least one file); everything else reads one
    // file per frame, so tests, replays and headless runs give the same result on any machine.
    return impl_->windowed && !impl_->cfg.editorMode ? 4.0 : 0.0;
}

void Engine::drop_script_jobs(const std::vector<int>& jobs) {
    for (int id : jobs) impl_->wfcJobs.erase(id);
}

void Engine::drop_script_background_loads() { impl_->cancel_script_background_loads(); }

Result<int> Engine::Impl::start_background_load(BackgroundLoader::Kind kind, const std::vector<std::string>& paths,
                                                std::optional<Json> props, BackgroundLoader::Origin origin) {
    if (!loader) return make_error("background loading needs a running engine (Engine::init)", "");
    const LoadTrace::ReadingFor reading(traceOwner);
    const jobs::OwnerScope jobScope(&jobOwner);
    auto r = loader->start(kind, paths, std::move(props), origin, loadTrace.get());
    if (r && kind == BackgroundLoader::Kind::SceneLoad) {
        // The last request wins: a scene change asked for earlier in this frame does not happen.
        if (pendingTraceTag != 0 && loadTrace) loadTrace->load_cancelled(pendingTraceTag);
        pendingTraceTag = 0;
        pendingLoadId = 0;
        hasPendingScene = false;
        nextProps.reset();
        pendingKeepProps = false;
    }
    return r;
}

Result<int> Engine::background_load_start(int kind, const std::vector<std::string>& paths, const Json* props) {
    const BackgroundLoader::Kind k = kind == 0   ? BackgroundLoader::Kind::ScenePreload
                                     : kind == 1 ? BackgroundLoader::Kind::Assets
                                                 : BackgroundLoader::Kind::SceneLoad;
    std::optional<Json> p;
    if (props && props->is_object()) p = *props;
    return impl_->start_background_load(k, paths, std::move(p), BackgroundLoader::Origin::Script);
}

bool Engine::background_load_cancel(int id) { return impl_->cancel_background_load(id); }

void Engine::background_loads_reset() {
    if (impl_->pendingLoadId != 0) impl_->drop_pending_async_switch();  // an async load ready this frame does not switch
    if (impl_->loader) impl_->loader->reset(impl_->loadTrace.get());
}

void Engine::request_scene_change(std::string_view scenePath) {
    impl_->cancel_background_scene_loads();  // the last request wins
    impl_->pendingScene = std::string(scenePath);
    impl_->hasPendingScene = true;
    impl_->nextProps.reset();  // the last request wins, props included
    impl_->pendingKeepProps = false;
}
void Engine::request_scene_change_with_props(std::string_view scenePath, const Json& props) {
    request_scene_change(scenePath);
    impl_->nextProps = props;
}
void Engine::request_scene_reload(std::string_view scenePath) {
    request_scene_change(scenePath);
    impl_->pendingKeepProps = true;
}
const Json& Engine::scene_props() const { return impl_->sceneProps; }
void Engine::request_quit() { impl_->quit = true; }
ProfMemory Engine::profile_memory() {
    Impl& I = *impl_;
    ProfMemory m;
    m.processBytes = current_memory_bytes();
    m.peakProcessBytes = peak_memory_bytes();
    m.entities = int(I.world.entity_count());
    m.jsHeapBytes = std::uint64_t(I.scripts.stats().value("memoryBytes", 0LL));
    if (I.renderer) m.textureBytes = I.renderer->texture_bytes();
    m.audioDecodedBytes = std::uint64_t(I.audio.stats().value("decodedBytes", 0LL));
    return m;
}

void Engine::profile_gpu(std::vector<double>& msOut, bool* supported, std::string* reason) {
    Renderer* r = impl_->renderer.get();
    if (!r) {
        if (supported) *supported = false;
        if (reason) *reason = "no graphics in this run (a logic-only engine draws nothing)";
        return;
    }
    r->take_gpu_ms(msOut);
    if (supported) *supported = r->gpu_timing_supported(reason);
}

void Engine::step_frames(int n) { step(n); }
const TextMeasurer* Engine::text_measurer() const { return &impl_->cpuText; }
const CameraSet* Engine::camera_set() const { return &impl_->cpuCameras; }
void Engine::set_text_scale(float scale) {  // the callers (ui.textScale, ui.set_text_scale) check the range
    ScriptHost::set_text_scale(scale);
    if (impl_->renderer) impl_->renderer->set_text_scale(scale);
    else impl_->cpuText.set_text_scale(scale);  // the CPU measurer only works when there is no renderer
}
void Engine::set_ui_scale(float scale) {  // the callers (ui.scale, ui.set_scale, the project default) check the range
    ScriptHost::set_ui_scale(scale);
    if (impl_->renderer) {
        impl_->renderer->set_ui_scale(scale);
        impl_->renderStale = true;
    } else {
        impl_->cpuText.set_ui_scale(scale);  // the CPU measurer only works when there is no renderer
    }
}
bool Engine::default_ui_mirror_rtl() const { return impl_->project.uiMirrorRtl; }
float Engine::default_ui_scale() const { return impl_->project.uiScale; }
std::string Engine::load_scene_now_with_props(std::string_view scenePath, const Json& props) {
    impl_->nextProps = props;
    return load_scene_now(scenePath);
}
std::string Engine::load_scene_json_now_with_props(const Json& scene, std::string_view sourceName, const Json& props) {
    impl_->nextProps = props;
    return load_scene_json_now(scene, sourceName);
}
std::string Engine::load_scene_now(std::string_view scenePath) {
    std::string err;
    return impl_->load_scene_impl(std::string(scenePath), &err) ? std::string() : (err.empty() ? "scene load failed" : err);
}

}  // namespace fa
