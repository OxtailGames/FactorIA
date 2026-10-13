// make_app_desc / run_windowed / run_headless.
#include <algorithm>
#include <filesystem>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

struct WindowedState {
    Engine engine;
    EngineConfig cfg;
    ProjectSettings project;  // loaded early for title/size (the engine reloads it in init)
    bool ok = false;
    int exitCode = 0;
};

// Expand mode: the visible area grows on the long axis to match the window aspect.
void apply_expand(Engine& engine, int fbW, int fbH) {
    Renderer* r = engine.renderer();
    if (!r || engine.project().scaleMode != ScaleMode::Expand || fbW <= 0 || fbH <= 0) return;
    int dw = engine.config().width > 0 ? engine.config().width : engine.project().width;
    int dh = engine.config().height > 0 ? engine.config().height : engine.project().height;
    double wa = double(fbW) / fbH, da = double(dw) / dh;
    int tw = dw, th = dh;
    if (wa > da) tw = int(std::lround(dh * wa));
    else th = int(std::lround(dw / wa));
    if (tw != r->target_width() || th != r->target_height()) r->set_target_size(tw, th);
}

}  // namespace

namespace {
AppDesc build_app_desc(const EngineConfig& config, std::shared_ptr<WindowedState> st) {
    st->cfg = config;
    st->cfg.headless = false;
    {
        std::string dir = config.projectDir;
        if (!dir.empty()) {
            std::error_code ec;
            dir = std::filesystem::absolute(std::filesystem::path(dir), ec).lexically_normal().generic_string();
        }
        auto p = load_project(dir);
        if (p.ok()) st->project = p.value();
        else FA_ERROR("engine", "{}", p.error().to_string());  // init reports it again and quits
    }

    AppDesc d;
    d.title = st->project.name;
    d.width = config.width > 0 ? config.width : st->project.width;
    d.height = config.height > 0 ? config.height : st->project.height;
    d.fullscreen = st->project.fullscreen;
    d.vsync = st->project.vsync;
    d.input = &st->engine.input();
    d.to_design_coords = [st](Vec2 p) {
        Renderer* r = st->engine.renderer();
        if (!r) return p;
        return r->framebuffer_to_design(p, app_framebuffer_width(), app_framebuffer_height(), st->engine.project().scaleMode);
    };
    d.init = [st] {
        GfxEnvironment env = app_gfx_environment();
        std::string err;
        st->ok = st->engine.init(st->cfg, &env, &err);
        if (!st->ok) {
            FA_ERROR("engine", "Cannot start: {}", err);
            st->exitCode = 1;
            app_request_quit();
            return;
        }
        apply_expand(st->engine, app_framebuffer_width(), app_framebuffer_height());
    };
    d.frame = [st](double dt) {
        if (!st->ok) return;
        st->engine.frame(dt);
        if (st->engine.quit_requested()) app_request_quit();
    };
    d.event = [st](const AppEvent& e) {
        if (!st->ok) return;
        switch (e.type) {
            case AppEvent::Type::Resized: apply_expand(st->engine, e.width, e.height); break;
            case AppEvent::Type::FocusLost: st->engine.input().release_all(); break;
            default: break;
        }
    };
    d.cleanup = [st] { st->engine.shutdown(); };
    return d;
}
}  // namespace

AppDesc make_app_desc(const EngineConfig& config) { return build_app_desc(config, std::make_shared<WindowedState>()); }

int run_windowed(const EngineConfig& config) {
    auto st = std::make_shared<WindowedState>();
    AppDesc d = build_app_desc(config, st);
    int rc = run_app(d);
    return rc != 0 ? rc : st->exitCode;
}

// ------------------------------------------------------------- headless --
namespace {

void apply_replay_entry(Engine::Impl& I, const Json& entry, std::vector<std::string>& problems, int frame) {
    auto note = [&](const std::string& m) { problems.push_back("replay frame " + std::to_string(frame) + ": " + m); };
    std::string err;
    for (const char* key : {"press", "release"}) {
        if (!entry.contains(key)) continue;
        if (!entry[key].is_array()) { note(std::string("'") + key + "' must be an array of names"); continue; }
        for (const Json& n : entry[key]) {
            if (!n.is_string()) { note("input names must be strings"); continue; }
            if (!I.inject_named(n.get<std::string>(), std::string(key) == "press", &err)) note(err);
        }
    }
    if (entry.contains("keys") && entry["keys"].is_object())
        for (auto it = entry["keys"].begin(); it != entry["keys"].end(); ++it) {
            Key k = key_from_name(it.key());
            if (k == Key::Unknown) { note("unknown key '" + it.key() + "'"); continue; }
            I.input.on_key(k, it->is_boolean() ? it->get<bool>() : true);
        }
    if (entry.contains("mouse") && entry["mouse"].is_object()) {
        const Json& m = entry["mouse"];
        if (m.contains("position")) {
            Vec2 p;
            if (json_to(m["position"], p, &err)) I.input.on_mouse_move(p);
            else note("mouse.position: " + err);
        }
        const std::pair<const char*, MouseButton> buttons[] = {
            {"left", MouseButton::Left}, {"right", MouseButton::Right}, {"middle", MouseButton::Middle}};
        for (const auto& [k, b] : buttons)
            if (m.contains(k) && m[k].is_boolean()) I.input.on_mouse_button(b, m[k].get<bool>());
    }
}

}  // namespace

int run_headless(const EngineConfig& configIn, const HeadlessRunOptions& options, Json* reportOut) {
    EngineConfig config = configIn;
    config.headless = true;
    config.audioDevice = false;
    Json report = Json::object();
    report["frames"] = 0;
    report["scriptErrors"] = Json::array();
    report["sceneErrors"] = Json::array();
    report["screenshots"] = Json::array();
    report["logErrors"] = 0;
    auto finish = [&](int code) {
        report["exitCode"] = code;
        if (reportOut) *reportOut = report;
        return code;
    };

    Engine engine;
    std::size_t errorsBefore = error_count();
    std::string err;
    if (!engine.init(config, nullptr, &err)) {
        report["error"] = err;
        return finish(2);
    }
    Engine::Impl& I = engine.runtime_impl();

    // Replay file.
    std::map<int, Json> replay;
    std::vector<std::string> replayProblems;
    if (!options.inputReplayPath.empty()) {
        auto r = load_json_file(options.inputReplayPath);
        if (!r.ok()) {
            report["error"] = "Cannot read input replay: " + r.error().to_string();
            return finish(2);
        }
        const Json* frames = r.value().is_object() && r.value().contains("frames") ? &r.value()["frames"] : nullptr;
        if (!frames || !frames->is_object()) {
            report["error"] = "Input replay must look like {\"frames\": {\"0\": {\"press\": [\"jump\"]}}} (file " +
                              options.inputReplayPath + ")";
            return finish(2);
        }
        for (auto it = frames->begin(); it != frames->end(); ++it) {
            try {
                replay[std::stoi(it.key())] = *it;
            } catch (...) {
                replayProblems.push_back("replay: frame key '" + it.key() + "' is not a number");
            }
        }
    }
    if (!options.audioOutPath.empty()) I.audio.start_recording();

    std::vector<int> shots = options.screenshotFrames;
    std::sort(shots.begin(), shots.end());
    Json shotPaths = Json::array();
    int ran = 0;
    for (int f = 0; f < options.frames && !engine.quit_requested(); ++f) {
        if (auto it = replay.find(f); it != replay.end()) apply_replay_entry(I, it->second, replayProblems, f);
        engine.step(1);
        ++ran;
        if (std::binary_search(shots.begin(), shots.end(), f)) {
            std::string path = replace_all(options.screenshotPattern, "{frame}", std::to_string(f));
            std::string serr;
            if (engine.screenshot(path, &serr))
                shotPaths.push_back(fs::is_absolute(path) ? path : fs::resolve(path).generic_string());
            else
                replayProblems.push_back("screenshot at frame " + std::to_string(f) + ": " + serr);
        }
    }
    engine.render_now();  // OnDemand: the last frame is drawn so renderStats / the final picture exist
    report["frames"] = ran;
    report["screenshots"] = shotPaths;
    if (!options.audioOutPath.empty()) {
        std::string aerr;
        if (I.audio.stop_recording(options.audioOutPath, &aerr))
            report["audioPath"] = fs::is_absolute(options.audioOutPath) ? options.audioOutPath : fs::resolve(options.audioOutPath).generic_string();
        else
            replayProblems.push_back("audio recording: " + aerr);
    }
    if (!options.stateOutPath.empty()) {
        auto w = fs::write_text(options.stateOutPath, dump_json(engine.state()));
        if (w.ok()) report["statePath"] = fs::is_absolute(options.stateOutPath) ? options.stateOutPath : fs::resolve(options.stateOutPath).generic_string();
        else replayProblems.push_back("state dump: " + w.error().to_string());
    }

    Json scriptErrs = Json::array();
    for (const ScriptError& e : engine.scripts().errors()) scriptErrs.push_back(e.to_string());
    report["scriptErrors"] = scriptErrs;
    Json sceneErrs = Json::array();
    if (I.sceneErrorCount > 0)
        for (const std::string& s : I.sceneIssues) sceneErrs.push_back(s);
    report["sceneErrors"] = sceneErrs;
    report["logErrors"] = error_count() - errorsBefore;
    if (!replayProblems.empty()) report["problems"] = replayProblems;
    int code = 0;
    if (options.failOnScriptError && (!scriptErrs.empty() || I.sceneErrorCount > 0)) code = 1;
    engine.shutdown();
    return finish(code);
}

}  // namespace fa
