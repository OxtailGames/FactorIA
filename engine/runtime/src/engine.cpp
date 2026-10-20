#include <algorithm>
#include <filesystem>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/runtime/platform_backend.h"
#include "fa/runtime/plugins.h"
#include "fa/scene/animation.h"
#include "fa/scene/serialize.h"

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
        for (const char* m : {"MouseLeft", "MouseRight", "MouseMiddle"}) candidates.emplace_back(m);
        *error = "Unknown input '" + name + "' (not an action, key or mouse button). " + did_you_mean(name, candidates);
        if (starts_with(to_lower(name), "gamepad") || starts_with(to_lower(name), "touch"))
            *error += " Gamepads and fingers have their own fields: {\"gamepad\": {\"buttons\": {\"A\": true}}}, "
                      "{\"touch\": {\"position\": [x, y]}}.";
    }
    return false;
}

void Engine::Impl::apply_project_settings() {
    fixedDt = 1.0 / std::max(1.0, project.fixedHz);
    input.set_gamepad_deadzone(float(project.inputDeadzone));
    for (const std::string& problem : input.set_actions(ui_with_default_actions(project.inputActions))) {
        FA_WARN("input", "{}", problem);
        startupProblems.push_back(problem);
    }
    // The platform catalog. A section with errors counts as empty (every platform call then says the id is not declared):
    // the first error is logged here, `factoria validate` lists them all.
    platform.set_translator([this](const std::string& key) { return i18n.translate(key); });
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
}

Vec2 Engine::Impl::design_size() const {
    if (renderer && renderer->initialized()) return {float(renderer->target_width()), float(renderer->target_height())};
    return {float(cfg.width > 0 ? cfg.width : project.width), float(cfg.height > 0 ? cfg.height : project.height)};
}

VisualMeasure Engine::Impl::measure() const {
    VisualMeasure m;
    if (renderer && renderer->initialized()) {
        const Renderer* r = renderer.get();
        m.textSize = [r](const Text& t) { return r->measure_text(t.text, t.fontSize, t.font, t.maxWidth, t.space); };
    }
    return m;
}

// Every scene load (scene.load, scene.reload, hot reload, project.test) starts from what is on disk now. ponytail: only
// fixedHz, the input actions and the deadzone are re-applied from factoria.json; size, scale mode, the renderer and the
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

bool Engine::Impl::load_scene_impl(const std::string& pathIn, std::string* error) {
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
    hasPendingScene = false;
    implicitStartScene = false;  // from now on the scene was chosen (scene.load, a script, --scene, reload)
    audio.stop_all();
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
    ui.reset();
    apply_localization();  // the first frame (and the first onStart) already read the current language
    scripts.on_scene_loaded();
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
    hasPendingScene = false;
    audio.stop_all();
    physics.reset();
    const std::string keptPath = world.scene_path();
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
    std::string err;
    load_scene_impl(path, &err);
}

namespace {
// Renderer::update(World&, float) advances animators/particles without drawing. Called when the renderer has it
// (older renderers simulate inside render_world, which then has to run every frame).
template <class R>
void update_visuals(R& r, World& w, float dt) {
    if constexpr (requires { r.update(w, dt); }) r.update(w, dt);
}
}  // namespace

void Engine::Impl::draw(double dt) {
    if (!renderer) return;
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
    if (!renderer) return;
    dt *= scripts.time_scale();  // particles and sprite animators follow time.scale: frozen while paused
    update_visuals(*renderer, world, float(dt));
    if (cfg.renderMode == RenderMode::OnDemand && !windowed) {
        renderStale = true;
        lastRenderDt = dt;
        return;
    }
    draw(dt);
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
        const bool renderAsset = ends_with(p, ".material.json") ||
            has_ext(p, {".glsl", ".png", ".jpg", ".jpeg", ".tga", ".bmp", ".ttf", ".otf", ".obj", ".gltf", ".glb"});
        if (assetsOnly && !renderAsset) continue;  // scripts, scenes and locales belong to the host
        if (starts_with(p, "locales/") && has_ext(p, {".json"})) {
            if (i18n.enabled()) {
                FA_INFO("hotreload", "String table {} changed on disk, reloading the tables", p);
                reload_localization();
            }
        } else if (has_ext(p, {".js", ".mjs"})) {
            FA_INFO("hotreload", "Reloading script {}", p);
            if (starts_with(p, "tools/")) scripts.reload_tools();
            else scripts.reload_module(p);
        } else if (p.size() > 11 && ends_with(p, ".scene.json")) {
            if (p == currentScene) {
                FA_INFO("hotreload", "Scene {} changed on disk, reloading", p);
                std::string err;
                load_scene_impl(p, &err);
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
    inFrame = true;
    set_log_frame(frame);
    // OnDemand: debug-draw primitives of undrawn frames are dropped (immediate mode: one frame each), but the last
    // frame's survive until the next frame starts so a screenshot still shows them.
    if (renderStale && renderer) renderer->debug().clear();
    // Store answers and events reach scripts here, before anything else of the frame runs (never in the middle of a call).
    platform.frame();
    scripts.dispatch_platform();
    scripts.dispatch_back();  // the Back button of this frame: input.onBack handlers, else quit
    const float fdt = float(fixedDt);
    for (int i = 0; i < fixedSteps; ++i) {
        physics.sync(world);  // entities spawned since the last step get bodies before scripts query physics
        scripts.fixed_update(fdt);
        // time.scale (game.paused = 0) slows or freezes the simulation, not only the scripts.
        const double scale = scripts.time_scale();
        if (scale > 0.0) {
            physics.step(world, float(fixedDt * scale));
            update_animators(world, float(fixedDt * scale));  // skeletal animation + its events, before they are dispatched
        }
        scripts.dispatch_events();
        world.advance_clock(fixedDt);
        ++fixedStep;
    }
    // The UI reads this frame's input and sends its events, which scripts get right away. Real time: it works at time.scale 0.
    ui.update(world, input, design_size(), float(dt), measure());
    scripts.dispatch_events();
    scripts.update(float(dt));
    audio.update(world, float(dt));
    if (!windowed || !cfg.audioDevice) audio.advance_null_device(dt);
    scripts.late_update(float(dt));
    scripts.settle_activation();  // panels shown or hidden this frame: onStart / onEnable / onDisable before drawing
    apply_localization();  // keys of entities scripts spawned or edited this frame
    render(dt);
    end_of_frame(dt);
    ++frame;
    inFrame = false;
}

void Engine::Impl::end_of_frame(double dt) {
    world.flush();
    apply_scene_change();
    watchTimer += dt;
    if (watchTimer >= 0.25) {
        watchTimer = 0.0;
        poll_hot_reload();
    }
    input.begin_frame();
}

// ---------------------------------------------------------------- Engine --
Engine::Engine() : impl_(std::make_unique<Impl>()) { impl_->self = this; }
Engine::~Engine() { shutdown(); }

bool Engine::init(const EngineConfig& config, const GfxEnvironment* gfx, std::string* error) {
    impl_->logSeqAtInit = log_last_seq();
    Impl& I = *impl_;
    auto fail = [&](const std::string& msg) {
        FA_ERROR("engine", "{}", msg);
        if (error) *error = msg;
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
    auto proj = load_project(dir);
    if (!proj.ok()) return fail(proj.error().to_string());
    I.project = proj.value();
    I.projectMtime = fs::modified_time(kProjectFileName);
    I.paused = config.editorMode;
    I.windowed = gfx != nullptr && !config.headless;
    if (I.windowed && !config.editorMode) I.appWindow = std::make_unique<AppWindowControl>();

    // World + input.
    I.world.rng().reseed(config.seed);
    I.apply_project_settings();
    I.setup_localization();

    // Graphics.
    if (config.graphics) {
        RendererDesc rd;
        rd.designWidth = config.width > 0 ? config.width : I.project.width;
        rd.designHeight = config.height > 0 ? config.height : I.project.height;
        rd.headless = !I.windowed;
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
        } else {
            if (config.shaderCompiler) I.renderer->set_shader_compiler(config.shaderCompiler);  // before any scene loads
            I.apply_fallback_fonts();  // the renderer did not exist when the start language was chosen
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
    register_builtin_commands(*this, I);  // before scripts.init: JS tools (tools/*.js) are added on top
    // Native plugins: their commands, and their functions for the scripts (plugins.<name>), before scripts.init.
    PluginInstall installed = install_plugins(I.project, dir, config.pluginDir, I.commands, I.scripts);
    for (std::string& problem : installed.problems) I.startupProblems.push_back(std::move(problem));
    BackendChoice choice = choose_platform_backend(config.platformBackend, config.platformFallback, I.platform.catalog(), installed,
                                                   runtime_platform());
    for (const std::string& warning : choice.warnings) {
        FA_WARN("platform", "{}", warning);
        I.startupProblems.push_back("platform: " + warning);
    }
    if (!choice.reason.empty()) FA_INFO("platform", "{}", choice.reason);
    else FA_DEBUG("platform", "backend '{}'", choice.backend->name());
    I.platform.set_backend(std::move(choice.backend), choice.why);
    std::string serr;
    if (!I.scripts.init(*this, &serr)) {
        FA_ERROR("script", "Script system init failed: {}", serr);
        I.startupProblems.push_back("script: " + serr);
    }
    if (config.memoryStorage) I.scripts.set_storage_mode(StorageMode::Memory);

    I.initialized = true;
    set_log_frame(0);

    // Start scene (errors are kept for game.state / script.errors; they do not abort init).
    std::string scenePath = config.scene.empty() ? I.project.mainScene : config.scene;
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
    if (I.windowed && I.project.scaleMode == ScaleMode::Expand) { /* resize handler adapts the target */ }
    I.poll_hot_reload();  // seeds the watch snapshot when hot reload is active
    return true;
}

void Engine::shutdown() {
    Impl& I = *impl_;
    if (!I.initialized) return;
    I.initialized = false;
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

void Engine::frame(double dt) {
    Impl& I = *impl_;
    if (!I.initialized) return;
    dt = std::clamp(dt, 0.0, kMaxFrameDt);
    if (I.paused) {
        I.inFrame = true;
        I.render(0.0);
        I.end_of_frame(dt);
        I.inFrame = false;
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
    Impl& I = *impl_;
    if (!I.initialized) return;
    for (int i = 0; i < frames && !I.quit; ++i) I.run_frame(I.fixedDt, 1);
}

bool Engine::load_scene(std::string_view path, std::string* error) { return impl_->load_scene_impl(std::string(path), error); }

bool Engine::load_scene_json(const Json& scene, std::string_view sourceName, std::string* error) {
    return impl_->load_scene_json_impl(scene, sourceName, error);
}

void Engine::render_now() {
    Impl& I = *impl_;
    if (!I.renderer) return;
    if (I.renderStale) I.draw(I.lastRenderDt);
}
bool Engine::render_pending() const { return impl_->renderStale; }

void Engine::reload_scene() {
    Impl& I = *impl_;
    if (I.currentScene.empty()) return;
    std::string err;
    I.load_scene_impl(I.currentScene, &err);
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
std::string Engine::set_language(std::string_view language) {
    auto switched = impl_->switch_language(language);
    return switched.ok() ? std::string() : switched.error().to_string();
}

ScriptSystem& Engine::scripts() { return impl_->scripts; }

bool Engine::screenshot(std::string_view path, std::string* error) {
    Impl& I = *impl_;
    auto fail = [&](const std::string& m) {
        if (error) *error = m;
        return false;
    };
    if (!I.renderer)
        return fail("No renderer: the engine runs with graphics=false" +
                    std::string(I.startupProblems.empty() ? "" : " (" + I.startupProblems.front() + ")") +
                    ". Run with a GPU (headless EGL needs Mesa) to take screenshots.");
    if (I.renderStale) I.draw(I.lastRenderDt);  // OnDemand: draw the state of the current frame
    // Also show changes made since the last draw without stepping (a test or script_eval opening a panel right after an
    // earlier screenshot). A game window presents its own frames: there only the initial state is drawn here.
    else if (!I.inFrame && (!I.windowed || I.cfg.editorMode || I.frame == 0)) I.draw(0.0);
    Image img;
    std::string cerr;
    if (!I.renderer->capture(img, &cerr)) return fail("Screenshot capture failed: " + cerr);
    auto r = save_png(img, path);
    if (!r.ok()) return fail(r.error().to_string());
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
Vec2 Engine::design_size() const { return impl_->design_size(); }
Json Engine::project_settings() const {
    Json j = impl_->project.to_json();
    j["seed"] = impl_->cfg.seed;  // the effective run seed (scripts reseed test files with it)
    return j;
}
double Engine::fixed_dt() const { return impl_->fixedDt; }
WindowControl* Engine::window() { return impl_->appWindow.get(); }

void Engine::request_scene_change(std::string_view scenePath) {
    impl_->pendingScene = std::string(scenePath);
    impl_->hasPendingScene = true;
}
void Engine::request_quit() { impl_->quit = true; }
void Engine::step_frames(int n) { step(n); }
void Engine::set_text_scale(float scale) {  // the callers (ui.textScale, ui.set_text_scale) check the range
    ScriptHost::set_text_scale(scale);
    if (impl_->renderer) impl_->renderer->set_text_scale(scale);
}
std::string Engine::load_scene_now(std::string_view scenePath) {
    std::string err;
    return impl_->load_scene_impl(std::string(scenePath), &err) ? std::string() : (err.empty() ? "scene load failed" : err);
}

}  // namespace fa
