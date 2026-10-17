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
    int framesRendered = 0;  // drawn frames, for the run marker in AppDesc.frame
    int framesSinceResume = -1;  // -1: not waiting for the post-resume marker; else drawn frames since Resumed
    // What the window shows of Input's requested cursor and on-screen keyboard state (input.mouse.visible/locked,
    // input.showKeyboard): scripts change Input, apply_input_requests() makes the window follow.
    bool mouseVisible = true, mouseLocked = false, keyboardShown = false;
};

void apply_input_requests(WindowedState& st) {
    const Input& in = st.engine.input();
    if (in.mouse_visible() != st.mouseVisible) app_show_mouse(st.mouseVisible = in.mouse_visible());
    if (in.mouse_locked() != st.mouseLocked) app_lock_mouse(st.mouseLocked = in.mouse_locked());
    if (in.keyboard_shown() != st.keyboardShown) app_show_keyboard(st.keyboardShown = in.keyboard_shown());
}

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

// The window icon (AppDesc::icon): the game's icon (`icon` / `export.<this platform>.icon` of factoria.json) as a few square
// images of 16 to 256 px, never larger than the file itself. A missing or unreadable icon is a warning, never a failure:
// the window just keeps the platform's default icon. Desktop only (mobile apps have no window icon).
std::vector<AppIconImage> load_window_icon(const std::string& projectDir, const std::string& rel) {
    std::vector<AppIconImage> out;
    if (rel.empty() || app_is_mobile()) return out;
    auto relative = fs::normalize_checked(rel);
    if (!relative.ok()) {
        FA_WARN("engine", "window icon: {}", relative.error().to_string());
        return out;
    }
    // A mounted game pack holds the icon too (project-relative); otherwise it is a file of the project folder.
    auto bytes = fs::read_bytes(projectDir.empty() || fs::pack_mounted() ? relative.value() : fs::join(projectDir, relative.value()));
    if (!bytes.ok()) {
        FA_WARN("engine", "window icon: cannot read '{}': {} (the window keeps the default icon; fix `icon` in factoria.json)", rel,
                bytes.error().message);
        return out;
    }
    auto decoded = decode_image(bytes->data(), bytes->size());
    if (!decoded.ok()) {
        FA_WARN("engine", "window icon: cannot decode '{}': {} (use a PNG or JPG; the window keeps the default icon)", rel,
                decoded.error().message);
        return out;
    }
    const int side = std::max(decoded->width, decoded->height);
    const Image square = decoded->width == decoded->height ? *decoded : fit_image(*decoded, side, 1.0f, Color::clear());
    for (int size : {16, 32, 48, 64, 128, 256}) {
        if (size > side) break;
        const Image img = size == side ? square : resize_image(square, size, size);
        out.push_back({img.width, img.height, img.rgba});
    }
    if (out.empty()) out.push_back({square.width, square.height, square.rgba});  // smaller than 16 px: as it is
    return out;
}

}  // namespace

namespace {
AppDesc build_app_desc(const EngineConfig& config, std::shared_ptr<WindowedState> st) {
    st->cfg = config;
    st->cfg.headless = false;
    std::string dir = config.projectDir;
    if (!dir.empty()) {
        std::error_code ec;
        dir = std::filesystem::absolute(std::filesystem::path(dir), ec).lexically_normal().generic_string();
    }
    {
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
    d.icon = load_window_icon(dir, st->project.window_icon());
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
        if (AppWindowControl* window = st->engine.runtime_impl().appWindow.get()) window->throttle();  // window.frameCap
        st->engine.frame(dt);
        apply_input_requests(*st);
        // Run marker: ONE info line after the 60th drawn frame. The device smoke tests (scripts/ios-smoke.sh,
        // scripts/android-smoke.sh) grep for it to prove the game started and kept rendering on a simulator/emulator.
        if (st->engine.renderer() && ++st->framesRendered == 60) FA_INFO("player", "60 frames rendered");
        // The same marker after every suspend/resume (app sent to the background and back), so the smoke tests can tell
        // the window kept rendering once the surface and context were rebuilt.
        if (st->engine.renderer() && st->framesSinceResume >= 0 && ++st->framesSinceResume == 60) {
            FA_INFO("player", "60 frames rendered after resume");
            st->framesSinceResume = -1;
        }
        if (st->engine.quit_requested()) app_request_quit();
    };
    d.event = [st](const AppEvent& e) {
        if (!st->ok) return;
        switch (e.type) {
            case AppEvent::Type::Resized: apply_expand(st->engine, e.width, e.height); break;
            case AppEvent::Type::FocusLost: st->engine.input().release_all(); break;
            case AppEvent::Type::FocusGained:
                st->mouseLocked = false;  // the window system unlocked the mouse with the focus: lock it again if requested
                break;
            case AppEvent::Type::Suspended: FA_INFO("player", "suspended"); break;
            case AppEvent::Type::Resumed:
                FA_INFO("player", "resumed");
                st->framesSinceResume = 0;
                break;
            default: break;
        }
    };
    d.cleanup = [st] { st->engine.shutdown(); };
    d.exit_code = [st] { return st->exitCode; };
    return d;
}
}  // namespace

AppDesc make_app_desc(const EngineConfig& config) { return build_app_desc(config, std::make_shared<WindowedState>()); }

int run_windowed(const EngineConfig& config) {
    auto st = std::make_shared<WindowedState>();
    AppDesc d = build_app_desc(config, st);
    return run_app(d);  // st->exitCode, through d.exit_code
}

// ------------------------------------------------------------- headless --
namespace {

void apply_replay_entry(Engine::Impl& I, const Json& entry, std::vector<std::string>& problems, int frame) {
    auto note = [&](const std::string& m) { problems.push_back("replay frame " + std::to_string(frame) + ": " + m); };
    std::string err;
    if (!entry.is_object()) {
        note("a frame entry must be an object like {\"press\": [\"jump\"]}, got " + describe_json_value(entry));
        return;
    }
    {
        // Misspelled entry fields used to be ignored silently ("pres" => nothing pressed).
        static const std::vector<std::string> known = {"press", "release", "keys", "mouse", "gamepad", "touch"};
        for (auto it = entry.begin(); it != entry.end(); ++it)
            if (std::find(known.begin(), known.end(), it.key()) == known.end())
                note("unknown field '" + it.key() + "' (ignored). " + did_you_mean(it.key(), known) +
                     " A frame entry takes press, release, keys, mouse, gamepad and touch.");
    }
    for (const char* key : {"press", "release"}) {
        if (!entry.contains(key)) continue;
        if (!entry[key].is_array()) { note(std::string("'") + key + "' must be an array of names"); continue; }
        for (const Json& n : entry[key]) {
            if (!n.is_string()) { note("input names must be strings"); continue; }
            if (!I.inject_named(n.get<std::string>(), std::string(key) == "press", &err)) note(err);
        }
    }
    if (entry.contains("keys") && !entry["keys"].is_object()) note("'keys' must be an object like {\"A\": true}");
    if (entry.contains("mouse") && !entry["mouse"].is_object()) note("'mouse' must be an object like {\"position\": [10, 20], \"left\": true}");
    if (entry.contains("keys") && entry["keys"].is_object())
        for (auto it = entry["keys"].begin(); it != entry["keys"].end(); ++it) {
            Key k = key_from_name(it.key());
            if (k == Key::Unknown) {
                std::vector<std::string> names;
                for (int i = 1; i < int(Key::Count); ++i) names.emplace_back(key_name(Key(i)));
                note("unknown key '" + it.key() + "' (ignored). " + did_you_mean(it.key(), names));
                continue;
            }
            I.input.on_key(k, it->is_boolean() ? it->get<bool>() : true);
        }
    if (entry.contains("mouse") && entry["mouse"].is_object()) {
        const Json& m = entry["mouse"];
        static const std::vector<std::string> mouseKnown = {"position", "left", "right", "middle"};
        for (auto it = m.begin(); it != m.end(); ++it)
            if (std::find(mouseKnown.begin(), mouseKnown.end(), it.key()) == mouseKnown.end())
                note("unknown mouse field '" + it.key() + "' (ignored). " + did_you_mean(it.key(), mouseKnown));
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
    std::vector<std::string> pads;  // gamepad / touch problems come back without the frame prefix
    if (entry.contains("gamepad")) apply_gamepad_json(I.input, entry["gamepad"], pads);
    if (entry.contains("touch")) apply_touch_json(I.input, entry["touch"], pads);
    for (const std::string& m : pads) note(m);
}

}  // namespace

void Engine::apply_input_entry(const Json& entry, std::vector<std::string>& problems, int frame) {
    apply_replay_entry(*impl_, entry, problems, frame);
}

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
    std::vector<std::pair<double, int>> timing;
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
        // Optional "timing": [[dt, fixedSteps], ...] per frame (the editor records it): replayed frames run exactly the
        // dt and fixed steps of the recorded ones, so onUpdate(dt) and input edges match a slow or fast windowed run.
        if (const Json& t = r.value().value("timing", Json()); !t.is_null()) {
            if (!t.is_array()) replayProblems.push_back("replay: timing must be an array of [dt, fixedSteps] (one per frame)");
            for (std::size_t i = 0; t.is_array() && i < t.size(); ++i) {
                const Json& e = t[i];
                if (!(e.is_array() && e.size() == 2 && e[0].is_number() && e[1].is_number_integer() && e[1].get<int>() >= 0)) {
                    replayProblems.push_back("replay: timing[" + std::to_string(i) + "] must be [dt, fixedSteps] like [0.0167, 1], got " +
                                             describe_json_value(e) + "; the rest of the run steps one fixed step per frame");
                    break;
                }
                timing.emplace_back(std::clamp(e[0].get<double>(), 0.0, kMaxFrameDt), e[1].get<int>());
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
        if (std::size_t(f) < timing.size()) {
            I.run_frame(timing[f].first, timing[f].second);
        } else {
            engine.step(1);
        }
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
