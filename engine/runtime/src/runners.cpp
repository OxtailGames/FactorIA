// make_app_desc / run_windowed / run_headless.
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <optional>

#include "engine_impl.h"
#include "fa/core/avi.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/process.h"
#include "fa/core/log.h"
#include "fa/core/perf.h"
#include "fa/core/strings.h"
#include "fa/platform/accessibility.h"
#include "fa/platform/local_date.h"
#include "fa/runtime/play_session.h"

namespace fa {

namespace {

struct WindowedState {
    Engine engine;
    EngineConfig cfg;
    ProjectSettings project;  // loaded early for title/size (the engine reloads it in init)
    bool ok = false;
    int exitCode = 0;
    int framesRendered = 0;  // drawn frames, for the run marker in AppDesc.frame
    int framesRun = 0;       // frames run so far, for EngineConfig::maxFrames
    int framesSinceResume = -1;  // -1: not waiting for the post-resume marker; else drawn frames since Resumed
    // The player's date when it came from the wall clock (no --date): read again when the app comes back, see refresh_clock_date.
    std::optional<CalendarDate> clockDate;
    // What the window shows of Input's requested cursor and on-screen keyboard state (input.mouse.visible/locked,
    // input.showKeyboard): scripts change Input, apply_input_requests() makes the window follow.
    bool mouseVisible = true, mouseLocked = false, keyboardShown = false;
};

void apply_input_requests(WindowedState& st) {
    Input& in = st.engine.input();
    if (in.mouse_visible() != st.mouseVisible) app_show_mouse(st.mouseVisible = in.mouse_visible());
    if (in.mouse_locked() != st.mouseLocked) app_lock_mouse(st.mouseLocked = in.mouse_locked());
    if (in.keyboard_shown() != st.keyboardShown) app_show_keyboard(st.keyboardShown = in.keyboard_shown());
    for (float seconds : in.vibrations()) app_vibrate(seconds);  // headless runs keep the list; a window plays it
    in.clear_vibrations();
}

// A player whose date came from the clock reads it again when the app comes back (resume, focus), before the scripts hear
// about it: a game left in the background overnight sees the new day in its "resume" handler. Only a change of the clock's
// date moves game.today(), so nothing else the game did to the date is undone by a focus change.
void refresh_clock_date(WindowedState& st) {
    if (!st.clockDate) return;
    const CalendarDate today = local_calendar_date();
    if (today == *st.clockDate) return;
    st.clockDate = today;
    st.engine.scripts().set_start_date(today);
}

// The device's safe area (notch, rounded corners, system bars) as insets of the renderer's target, in design pixels: the
// platform reports framebuffer pixels, and with letterboxing the picture covers only part of the framebuffer, so the two
// corners of the safe rectangle go through the same mapping the pointer does and are clamped to the picture.
void apply_safe_insets(WindowedState& st) {
    Renderer* r = st.engine.renderer();
    if (!r || !r->initialized()) return;
    EdgeInsets out;
    const EdgeInsets px = app_safe_insets();
    const int fbW = app_framebuffer_width(), fbH = app_framebuffer_height();
    if (!px.zero() && fbW > 0 && fbH > 0) {
        const ScaleMode mode = st.engine.project().scaleMode;
        const Vec2 topLeft = r->framebuffer_to_design({px.left, px.top}, fbW, fbH, mode);
        const Vec2 bottomRight = r->framebuffer_to_design({float(fbW) - px.right, float(fbH) - px.bottom}, fbW, fbH, mode);
        const float tw = float(r->target_width()), th = float(r->target_height());
        out.left = std::clamp(topLeft.x, 0.0f, tw);
        out.top = std::clamp(topLeft.y, 0.0f, th);
        out.right = std::clamp(tw - bottomRight.x, 0.0f, tw);
        out.bottom = std::clamp(th - bottomRight.y, 0.0f, th);
    }
    st.engine.world().set_safe_insets(out);
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
        // The wall clock is read here and in refresh_clock_date only: the player's date goes into the config like the seed
        // does (--date overrides, and then it never changes).
        if (st->cfg.date.empty()) {
            const CalendarDate today = local_calendar_date();
            st->cfg.date = today.iso();
            st->cfg.dateUtcOffsetMinutes = today.utcOffsetMinutes;
            st->clockDate = today;
        }
        st->ok = st->engine.init(st->cfg, &env, &err);
        if (!st->ok) {
            FA_ERROR("engine", "Cannot start: {}", err);
            st->exitCode = 1;
            app_request_quit();
            return;
        }
        apply_expand(st->engine, app_framebuffer_width(), app_framebuffer_height());
        // A phone is played by touch from the start: touch-only on-screen controls are drawn before the first finger.
        if (app_is_mobile()) st->engine.input().set_last_device(InputDevice::Touch);
    };
    d.frame = [st](double dt) {
        if (!st->ok) return;
        if (AppWindowControl* window = st->engine.runtime_impl().appWindow.get()) window->throttle();  // window.frameCap
        apply_safe_insets(*st);  // before the frame: layout and drawing read it
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
        if (st->cfg.maxFrames > 0 && ++st->framesRun >= st->cfg.maxFrames) {
            for (const ScriptError& e : st->engine.scripts().errors()) {
                FA_ERROR("player", "script error: {}", e.to_string());
                st->exitCode = 1;
            }
            app_request_quit();
        }
    };
    d.event = [st](const AppEvent& e) {
        if (!st->ok) return;
        switch (e.type) {
            case AppEvent::Type::Resized: apply_expand(st->engine, e.width, e.height); break;
            case AppEvent::Type::FocusLost:
                st->engine.input().release_all();
                st->engine.scripts().app_event(ScriptSystem::AppLifecycle::Blur);  // game.on("blur")
                break;
            case AppEvent::Type::FocusGained:
                st->mouseLocked = false;  // the window system unlocked the mouse with the focus: lock it again if requested
                refresh_system_accessibility();  // the player may have changed a system setting meanwhile (game.accessibility)
                refresh_clock_date(*st);
                st->engine.scripts().app_event(ScriptSystem::AppLifecycle::Focus);
                break;
            case AppEvent::Type::Suspended:
                FA_INFO("player", "suspended");
                st->engine.input().release_all();  // no key stays held while the app is away
                st->engine.scripts().app_event(ScriptSystem::AppLifecycle::Suspend);  // game.on("suspend"), pauseOnSuspend
                break;
            case AppEvent::Type::Resumed:
                FA_INFO("player", "resumed");
                refresh_system_accessibility();
                st->framesSinceResume = 0;
                refresh_clock_date(*st);
                st->engine.scripts().app_event(ScriptSystem::AppLifecycle::Resume);
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
        static const std::vector<std::string> known = {"press", "release", "keys", "mouse", "gamepad", "touch", "back"};
        for (auto it = entry.begin(); it != entry.end(); ++it)
            if (std::find(known.begin(), known.end(), it.key()) == known.end())
                note("unknown field '" + it.key() + "' (ignored). " + did_you_mean(it.key(), known) +
                     " A frame entry takes press, release, keys, mouse, gamepad, touch and back.");
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
    if (entry.contains("back")) {
        if (entry["back"].is_boolean()) {
            if (entry["back"].get<bool>()) I.input.on_back();
        } else {
            note("'back' must be true (press the system Back button)");
        }
    }
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

    EngineConfig effective = config;  // the replay file may add the date it was recorded on
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
        // Optional "date" ("YYYY-MM-DD") and "utcOffsetMinutes": the calendar date the run was recorded on, which game.today()
        // answers again so a daily seed replays. --date wins; a file without it plays on the fixed default date.
        if (config.date.empty()) {
            if (const Json& dj = r.value().value("date", Json()); !dj.is_null()) {
                auto parsed = dj.is_string() ? parse_calendar_date(dj.get<std::string>(), "date") : Result<CalendarDate>(Error{"date must be a string \"YYYY-MM-DD\"", "Example: \"date\": \"2026-10-23\"."});
                if (!parsed.ok()) {
                    report["error"] = "Input replay " + options.inputReplayPath + ": " + parsed.error().to_string();
                    return finish(2);
                }
                effective.date = dj.get<std::string>();
                effective.dateUtcOffsetMinutes = r.value().value("utcOffsetMinutes", 0);
            }
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
    Engine engine;
    std::size_t errorsBefore = error_count();
    std::string err;
    if (!engine.init(effective, nullptr, &err)) {
        report["error"] = err;
        return finish(2);
    }
    Engine::Impl& I = engine.runtime_impl();

    // Video: validated before the run, so a wrong request does not cost a whole replay.
    const bool wantVideo = !options.videoOutPath.empty();
    const std::string videoExt = wantVideo ? fs::extension(options.videoOutPath) : std::string();
    AviWriter avi;
    std::string aviPath;  // where the AVI is written: the output itself, or a temporary one that ffmpeg converts
    bool videoFailed = false;
    const auto video_fail = [&](const std::string& why) {  // the report says why; the video stops, the run goes on
        replayProblems.push_back("video: " + why);
        videoFailed = true;
    };
    if (wantVideo) {
        if (videoExt != ".avi" && videoExt != ".mp4") {
            report["error"] = "--record-video writes .avi or .mp4 files, but '" + options.videoOutPath + "' ends in '" + videoExt +
                              "'. Use a name like out/trailer.avi (no extra tools needed) or out/trailer.mp4 (needs ffmpeg).";
            return finish(2);
        }
        if (videoExt == ".mp4" && options.ffmpegPath.empty()) {
            report["error"] = "Recording an .mp4 needs ffmpeg, and it was not found (looked at: the FACTORIA_FFMPEG environment "
                              "variable, \"publish\": {\"ffmpeg\": \"<path>\"} in ~/.factoria/export.json, and PATH). Install ffmpeg "
                              "(https://ffmpeg.org/download.html; Windows: winget install ffmpeg, macOS: brew install ffmpeg, Linux: "
                              "apt install ffmpeg) or record an .avi, which needs nothing, and convert it later with: ffmpeg -i "
                              "trailer.avi -c:v libx264 -pix_fmt yuv420p -c:a aac trailer.mp4";
            return finish(2);
        }
        if (!I.renderer) {
            report["error"] = "--record-video needs a GPU renderer, and this run has none (graphics=false or no GPU found). Headless "
                              "EGL works with Mesa (llvmpipe).";
            return finish(2);
        }
        std::string serr;
        if (!engine.hold_render_scale(options.renderScale, &serr)) {
            report["error"] = "--render-scale: " + serr;
            return finish(2);
        }
        aviPath = videoExt == ".mp4" ? options.videoOutPath + ".tmp.avi" : options.videoOutPath;
    }
    if (!options.audioOutPath.empty() || wantVideo) I.audio.start_recording();

    std::vector<int> shots = options.screenshotFrames;
    std::sort(shots.begin(), shots.end());
    Json shotPaths = Json::array();
    int ran = 0;
    std::vector<double> cpuMs;  // CPU time of each frame (process CPU, not wall clock): report["perf"]
    int maxDrawCalls = 0, maxEntities = 0;
    // Profiler (options.profile): measure the frames after the warm-up into report["profile"]; the setting is put back at the end.
    struct ProfilerGuard {
        bool was;
        ~ProfilerGuard() { Profiler::get().set_enabled(was); }
    } profilerGuard{Profiler::on()};
    ProfileSummary profile;
    std::vector<double> gpuMs;
    bool gpuSupported = false;
    std::string gpuReason = "the GPU time was not measured";
    if (options.profile) {
        Profiler::get().set_enabled(true);
        profile.add_memory(engine.profile_memory());
    }
    for (int f = 0; f < options.frames && !engine.quit_requested(); ++f) {
        if (auto it = replay.find(f); it != replay.end()) apply_replay_entry(I, it->second, replayProblems, f);
        const double cpu0 = process_cpu_seconds();
        if (std::size_t(f) < timing.size()) {
            I.run_frame(timing[f].first, timing[f].second);
        } else {
            engine.step(1);
        }
        cpuMs.push_back((process_cpu_seconds() - cpu0) * 1000.0);
        if (options.profile) {
            engine.profile_gpu(gpuMs, &gpuSupported, &gpuReason);
            if (f >= options.profileWarmup) {
                profile.add_frame(Profiler::get().last());
                for (double ms : gpuMs) profile.add_gpu_ms(ms);
                if ((f - options.profileWarmup) % 30 == 0) profile.add_memory(engine.profile_memory());
            }
            gpuMs.clear();
        }
        maxEntities = std::max(maxEntities, int(engine.world().entity_count()));
        if (Renderer* r = engine.renderer()) maxDrawCalls = std::max(maxDrawCalls, r->stats().drawCalls);  // OnDemand: the last drawn frame
        ++ran;
        if (wantVideo && !videoFailed) {
            Image frameImg;
            std::string verr;
            if (!engine.capture_scaled(frameImg, options.renderScale, &verr)) {
                video_fail("frame " + std::to_string(f) + ": " + verr);
            } else {
                if (avi.frame_count() == 0)
                    if (auto b = avi.begin(aviPath, frameImg.width, frameImg.height, 1.0 / engine.fixed_dt()); !b.ok()) video_fail(b.error().to_string());
                if (!videoFailed)
                    if (auto a = avi.add_frame(encode_jpeg(frameImg, 85)); !a.ok())
                        video_fail(a.error().to_string() + " The video stops here (" + std::to_string(avi.frame_count()) + " frames); the run goes on.");
            }
        }
        if (std::binary_search(shots.begin(), shots.end(), f)) {
            std::string path = replace_all(options.screenshotPattern, "{frame}", std::to_string(f));
            std::string serr;
            if (engine.screenshot_simulated(path, options.renderScale, options.screenshotSimulate, &serr))
                shotPaths.push_back(fs::is_absolute(path) ? path : fs::resolve(path).generic_string());
            else
                replayProblems.push_back("screenshot at frame " + std::to_string(f) + ": " + serr);
        }
    }
    engine.render_now();  // OnDemand: the last frame is drawn so renderStats / the final picture exist
    if (options.profile) {
        engine.profile_gpu(gpuMs, &gpuSupported, &gpuReason);
        for (double ms : gpuMs) profile.add_gpu_ms(ms);  // the answers of the last frames, if they are ready
        profile.set_gpu_status(gpuSupported, gpuReason);
        profile.add_memory(engine.profile_memory());
        report["profile"] = profile.to_json();
    }
    report["frames"] = ran;
    report["screenshots"] = shotPaths;
    if (Renderer* r = engine.renderer()) maxDrawCalls = std::max(maxDrawCalls, r->stats().drawCalls);
    {
        const FrameStats cpu = compute_frame_stats(cpuMs);
        auto r3 = [](double v) { return std::round(v * 1000.0) / 1000.0; };
        Json perf = Json::object();
        perf["frames"] = cpu.count;
        perf["cpuMsAvg"] = r3(cpu.avgMs);
        perf["cpuMsP95"] = r3(cpu.p95Ms);
        perf["cpuMsMax"] = r3(cpu.maxMs);
        perf["cpuClock"] = cpu_time_is_wall_clock() ? "wall" : "process";
        perf["peakMemoryMB"] = std::round(double(peak_memory_bytes()) / (1024.0 * 1024.0) * 10.0) / 10.0;
        perf["drawCalls"] = maxDrawCalls;
        perf["entities"] = maxEntities;
        perf["graphics"] = I.renderer ? Json(I.gpu ? I.gpu->description() : "window") : Json("none");
        report["perf"] = perf;
    }
    std::vector<std::int16_t> pcm;
    int pcmRate = 0;
    if (!options.audioOutPath.empty() || wantVideo) {
        std::string aerr;
        if (I.audio.stop_recording(options.audioOutPath, &aerr, wantVideo ? &pcm : nullptr, &pcmRate)) {
            if (!options.audioOutPath.empty())
                report["audioPath"] = fs::is_absolute(options.audioOutPath) ? options.audioOutPath : fs::resolve(options.audioOutPath).generic_string();
        } else {
            replayProblems.push_back("audio recording: " + aerr);
        }
    }
    if (wantVideo && !videoFailed) {
        const bool audible = std::any_of(pcm.begin(), pcm.end(), [](std::int16_t v) { return v != 0; });  // a silent run has no track
        const int videoFrames = avi.frame_count();
        auto w = videoFrames == 0 ? Result<void>(make_error("the run drew no frame (--frames 0?)", "Run at least one frame."))
                                  : avi.finish(audible ? pcm.data() : nullptr, audible ? pcm.size() / 2 : 0, pcmRate);
        if (!w.ok()) {
            video_fail(w.error().to_string());
        } else if (videoExt == ".mp4") {
            ProcessOptions po;
            po.argv = {options.ffmpegPath, "-y", "-loglevel", "error", "-i", aviPath, "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2",
                       "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
                       "-movflags", "+faststart", options.videoOutPath};
            po.captureStdout = false;
            po.timeoutSeconds = 1800;
            auto pr = run_process(po);
            std::error_code ec;
            std::filesystem::remove(fs::os_path(aviPath), ec);
            if (!pr.ok())
                video_fail("cannot start ffmpeg (" + options.ffmpegPath + "): " + pr.error().to_string());
            else if (pr->exitCode != 0)
                video_fail("ffmpeg failed (exit " + std::to_string(pr->exitCode) + "): " + pr->stderrText.substr(0, 600) +
                           " Record an .avi instead if this keeps failing.");
        }
        if (!videoFailed) {
            report["videoPath"] = fs::is_absolute(options.videoOutPath) ? options.videoOutPath : fs::resolve(options.videoOutPath).generic_string();
            report["videoFrames"] = videoFrames;
            report["videoAudio"] = audible;
        }
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
    if (videoFailed) code = 2;
    engine.shutdown();
    return finish(code);
}

}  // namespace fa
