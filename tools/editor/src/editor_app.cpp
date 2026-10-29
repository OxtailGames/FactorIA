// Editor application shell: sokol callbacks, project/scene lifecycle, play mode, undo/redo,
// docking layout, menu, toolbar and status bar.
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <thread>
#include <filesystem>

#include "app_icon.h"
#include "autotest_sections.h"
#include "editor_internal.h"
#include "fa/core/fs.h"
#include "imgui_internal.h"
#include "sokol_app.h"
#include "fa/platform/local_date.h"
#include "fa/platform/sokol_entry.h"
#include "sokol_gfx.h"
#include "sokol_glue.h"
#include "ui_backend.h"
#include "fa/tooling/shaders.h"

namespace fa::editor {

Editor* g_editor = nullptr;

namespace {
Key map_key(sapp_keycode k) {
    if (k >= SAPP_KEYCODE_A && k <= SAPP_KEYCODE_Z) return Key(int(Key::A) + (k - SAPP_KEYCODE_A));
    if (k >= SAPP_KEYCODE_0 && k <= SAPP_KEYCODE_9) return Key(int(Key::Num0) + (k - SAPP_KEYCODE_0));
    if (k >= SAPP_KEYCODE_F1 && k <= SAPP_KEYCODE_F12) return Key(int(Key::F1) + (k - SAPP_KEYCODE_F1));
    switch (k) {
        case SAPP_KEYCODE_SPACE: return Key::Space;
        case SAPP_KEYCODE_ENTER: case SAPP_KEYCODE_KP_ENTER: return Key::Enter;
        case SAPP_KEYCODE_ESCAPE: return Key::Escape;
        case SAPP_KEYCODE_TAB: return Key::Tab;
        case SAPP_KEYCODE_BACKSPACE: return Key::Backspace;
        case SAPP_KEYCODE_INSERT: return Key::Insert;
        case SAPP_KEYCODE_DELETE: return Key::Delete;
        case SAPP_KEYCODE_LEFT: return Key::Left;
        case SAPP_KEYCODE_RIGHT: return Key::Right;
        case SAPP_KEYCODE_UP: return Key::Up;
        case SAPP_KEYCODE_DOWN: return Key::Down;
        case SAPP_KEYCODE_PAGE_UP: return Key::PageUp;
        case SAPP_KEYCODE_PAGE_DOWN: return Key::PageDown;
        case SAPP_KEYCODE_HOME: return Key::Home;
        case SAPP_KEYCODE_END: return Key::End;
        case SAPP_KEYCODE_LEFT_SHIFT: return Key::LeftShift;
        case SAPP_KEYCODE_RIGHT_SHIFT: return Key::RightShift;
        case SAPP_KEYCODE_LEFT_CONTROL: return Key::LeftControl;
        case SAPP_KEYCODE_RIGHT_CONTROL: return Key::RightControl;
        case SAPP_KEYCODE_LEFT_ALT: return Key::LeftAlt;
        case SAPP_KEYCODE_RIGHT_ALT: return Key::RightAlt;
        case SAPP_KEYCODE_MINUS: return Key::Minus;
        case SAPP_KEYCODE_EQUAL: return Key::Equal;
        case SAPP_KEYCODE_LEFT_BRACKET: return Key::LeftBracket;
        case SAPP_KEYCODE_RIGHT_BRACKET: return Key::RightBracket;
        case SAPP_KEYCODE_BACKSLASH: return Key::Backslash;
        case SAPP_KEYCODE_SEMICOLON: return Key::Semicolon;
        case SAPP_KEYCODE_APOSTROPHE: return Key::Apostrophe;
        case SAPP_KEYCODE_COMMA: return Key::Comma;
        case SAPP_KEYCODE_PERIOD: return Key::Period;
        case SAPP_KEYCODE_SLASH: return Key::Slash;
        case SAPP_KEYCODE_GRAVE_ACCENT: return Key::GraveAccent;
        default: return Key::Unknown;
    }
}

// The autotest types and clicks through its own events (inject_*), which go straight to on_event. The OS's input and
// focus events would get in its way: someone moving the mouse over the window moves the autotest's mouse, and another
// window taking focus makes ImGui drop the keys and characters typed in that frame.
bool autotest_ignores(const sapp_event* e) {
    switch (e->type) {
        case SAPP_EVENTTYPE_KEY_DOWN: case SAPP_EVENTTYPE_KEY_UP: case SAPP_EVENTTYPE_CHAR:
        case SAPP_EVENTTYPE_MOUSE_DOWN: case SAPP_EVENTTYPE_MOUSE_UP: case SAPP_EVENTTYPE_MOUSE_SCROLL:
        case SAPP_EVENTTYPE_MOUSE_MOVE: case SAPP_EVENTTYPE_MOUSE_ENTER: case SAPP_EVENTTYPE_MOUSE_LEAVE:
        case SAPP_EVENTTYPE_TOUCHES_BEGAN: case SAPP_EVENTTYPE_TOUCHES_MOVED: case SAPP_EVENTTYPE_TOUCHES_ENDED:
        case SAPP_EVENTTYPE_TOUCHES_CANCELLED: case SAPP_EVENTTYPE_FOCUSED: case SAPP_EVENTTYPE_UNFOCUSED:
            return true;
        default:
            return false;
    }
}

}  // namespace

std::string home_dir() {
    const char* h = std::getenv("HOME");
    if (!h) h = std::getenv("USERPROFILE");
    return h ? h : "";
}

std::string lower_str(std::string s) {
    for (char& c : s) c = char(std::tolower(static_cast<unsigned char>(c)));
    return s;
}
bool contains_ci(const std::string& hay, const std::string& needle) {
    if (needle.empty()) return true;
    return lower_str(hay).find(lower_str(needle)) != std::string::npos;
}
std::string editor_window_title(std::string_view version, std::string_view projectName) {
    std::string title = "FactorIA " + std::string(version);
    if (!projectName.empty()) title += " \xE2\x80\x94 " + std::string(projectName);  // U+2014 EM DASH, UTF-8
    return title;
}

ImVec4 level_color(LogLevel l) {
    switch (l) {
        case LogLevel::Trace: return ImVec4(0.5f, 0.5f, 0.55f, 1);
        case LogLevel::Debug: return ImVec4(0.55f, 0.65f, 0.75f, 1);
        case LogLevel::Info: return ImVec4(0.85f, 0.87f, 0.9f, 1);
        case LogLevel::Warn: return ImVec4(1.0f, 0.78f, 0.3f, 1);
        case LogLevel::Error: return ImVec4(1.0f, 0.4f, 0.38f, 1);
    }
    return ImVec4(1, 1, 1, 1);
}

// ------------------------------------------------------------------------------------------
// MainThreadQueue
CommandResult MainThreadQueue::call(const std::string& name, const Json& args, const std::atomic<bool>* cancel,
                                    const std::string& tag) {
    auto promise = std::make_shared<std::promise<CommandResult>>();
    auto abandoned = std::make_shared<std::atomic<bool>>(false);
    std::future<CommandResult> fut = promise->get_future();
    auto fail = [&](const char* why) {
        abandoned->store(true);  // the main thread skips the job if it has not started it
        CommandResult r;
        r.ok = false;
        r.error = Json::object({{"code", "unavailable"}, {"message", why},
                                {"hint", "The editor is closing or the run was stopped; retry later."}});
        return r;
    };
    {
        std::lock_guard<std::mutex> lock(mu_);
        if (closed_) return fail("editor main thread is not accepting commands");
        jobs_.push_back(Job{name, tag, args, promise, abandoned});
    }
    for (;;) {
        if (fut.wait_for(std::chrono::milliseconds(25)) == std::future_status::ready) return fut.get();
        bool closed;
        {
            std::lock_guard<std::mutex> lock(mu_);
            closed = closed_;
        }
        if (closed || (cancel && cancel->load())) return fail("cancelled");
    }
}

std::size_t MainThreadQueue::size() {
    std::lock_guard<std::mutex> lock(mu_);
    return jobs_.size();
}

int MainThreadQueue::pump(const std::function<std::optional<CommandResult>(const std::string&, const Json&)>& run,
                          double budgetMs) {
    std::deque<Job> local;
    {
        std::lock_guard<std::mutex> lock(mu_);
        local.swap(jobs_);
    }
    const auto t0 = std::chrono::steady_clock::now();
    int ran = 0;
    while (!local.empty()) {
        Job j = std::move(local.front());
        local.pop_front();
        if (j.abandoned && j.abandoned->load()) continue;  // its run was stopped while it waited: nobody wants the answer
        current_ = j.promise;
        currentTag_ = j.tag;
        std::optional<CommandResult> r = run(j.name, j.args);
        const bool taken = !current_;
        current_.reset();
        currentTag_.clear();
        if (!taken) j.promise->set_value(r ? std::move(*r) : CommandResult{});
        ++ran;
        if (taken) break;  // a sliced command owns the simulation until it finishes: the others wait their turn
        if (std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count() >= budgetMs) break;
    }
    if (!local.empty()) {  // out of time: keep the rest, in order, ahead of anything queued meanwhile
        std::lock_guard<std::mutex> lock(mu_);
        if (closed_) {
            for (Job& j : local) {
                CommandResult r;
                r.error = Json::object({{"code", "unavailable"}, {"message", "editor closing"}});
                j.promise->set_value(r);
            }
        } else {
            jobs_.insert(jobs_.begin(), std::make_move_iterator(local.begin()), std::make_move_iterator(local.end()));
        }
    }
    return ran;
}

void MainThreadQueue::close() {
    std::deque<Job> local;
    {
        std::lock_guard<std::mutex> lock(mu_);
        closed_ = true;
        local.swap(jobs_);
    }
    for (Job& j : local) {
        CommandResult r;
        r.error = Json::object({{"code", "unavailable"}, {"message", "editor closing"}});
        j.promise->set_value(r);
    }
}
void MainThreadQueue::reopen() {
    std::lock_guard<std::mutex> lock(mu_);
    closed_ = false;
}

// ------------------------------------------------------------------------------------------
Editor::Editor(EditorOptions options) : options_(std::move(options)) {}

Editor::~Editor() {
    ai_stop();
    if (aiDetectThread_.joinable()) aiDetectThread_.join();
    if (atThread_.joinable()) atThread_.join();
    atWatchdogStop_ = true;
    if (atWatchdog_.joinable()) atWatchdog_.join();
    if (updateThread_.joinable()) updateThread_.join();
}

int Editor::run() {
    g_editor = this;
    const char* at = std::getenv("FA_EDITOR_AUTOTEST");
    autotest_ = at && *at && std::string(at) != "0";
    atWelcome_ = autotest_ && std::string(at) == "welcome";  // no project: screenshot the Open/New dialog
    if (autotest_ && !atWelcome_)  // FA_EDITOR_AUTOTEST_SECTIONS=K,M: only those sections (checked before a window opens)
        if (const char* sections = std::getenv("FA_EDITOR_AUTOTEST_SECTIONS"); sections && *sections) {
            auto picked = parse_autotest_sections(sections);
            if (!picked) {
                std::fprintf(stderr, "error: %s\nhint: %s\n", picked.error().message.c_str(), picked.error().hint.c_str());
                return 2;
            }
            atSections_ = std::move(*picked);
        }
    AppDesc d;
    windowTitle_ = editor_window_title(FA_ENGINE_VERSION, "");
    d.title = windowTitle_;
    d.icon = editor_window_icon();
    d.dockIcon = editor_dock_icon();
    d.appName = "FactorIA";
    d.width = autotest_ ? 1600 : 1440;
    d.height = autotest_ ? 900 : 860;
    if (autotest_)  // FA_EDITOR_AUTOTEST_SIZE=1024x642: try the autotest on a small display (the macOS CI runner)
        if (const char* size = std::getenv("FA_EDITOR_AUTOTEST_SIZE")) {
            int w = 0, h = 0;
            if (std::sscanf(size, "%dx%d", &w, &h) == 2 && w > 0 && h > 0) { d.width = w; d.height = h; }
        }
    d.vsync = !autotest_;
    d.highDpi = true;
    d.init = [this] { on_init(); };
    d.frame = [this](double dt) { on_frame(dt); };
    d.cleanup = [this] { on_cleanup(); };
    d.exit_code = [this] { return atFailures_.empty() ? 0 : 1; };  // the autotest fails the process (ctest)
    sapp_desc s = to_sapp_desc(d);
    s.event_cb = [](const sapp_event* e) {
        if (g_editor && !(g_editor->autotest_active() && autotest_ignores(e))) g_editor->on_event(e);
    };
    // Copy and paste: sokol_imgui pastes on sokol_app's CLIPBOARD_PASTED event (it swallows the Ctrl+V key), and both
    // need the clipboard enabled. 1 MB, not sokol's 8 KB: a pasted log or design doc must not be refused.
    s.enable_clipboard = true;
    s.clipboard_size = 1 << 20;
    sapp_run(&s);  // macOS: does not return, the platform layer exits with d.exit_code()
    return d.exit_code();
}

void Editor::on_init() {
    set_log_level(LogLevel::Debug);
    set_dock_name("FactorIA");  // macOS: not "factoria", the executable's name
    std::string dir = options_.projectDir;
    if (autotest_) {
        // Window screenshots. FA_EDITOR_AUTOTEST_SHOW=1: a window to watch (macOS hides it from view and the mouse).
        const char* show = std::getenv("FA_EDITOR_AUTOTEST_SHOW");
        ui::prepare_backbuffer_readback(show && *show && std::string(show) != "0");
        namespace stdfs = std::filesystem;
        atWatchdog_ = std::thread([this] {
            std::uint64_t last = atHeartbeat_.load();
            auto changed = std::chrono::steady_clock::now();
            while (!atWatchdogStop_.load()) {
                std::this_thread::sleep_for(std::chrono::milliseconds(250));
                const std::uint64_t now = atHeartbeat_.load();
                if (now != last) {
                    last = now;
                    changed = std::chrono::steady_clock::now();
                } else if (std::chrono::steady_clock::now() - changed > std::chrono::seconds(60)) {
                    std::fprintf(stderr, "autotest watchdog: the editor drew no frame for 60 s (a UI or GPU call is stuck): ending the process "
                                         "so the window does not stay frozen\n");
                    std::_Exit(86);
                }
            }
        });
        const char* out = std::getenv("FA_EDITOR_AUTOTEST_OUT");
        stdfs::path base = out && *out ? stdfs::path(out) : stdfs::temp_directory_path() / "fa_editor_autotest_out";
        std::error_code ec;
        stdfs::create_directories(base, ec);
        atOutDir_ = base.string();
        // The Platform settings window saves this computer's settings: never into the user's real ~/.factoria/export.json.
        {
            const std::string machineConfig = (base / "export_config.json").string();
            stdfs::remove(machineConfig, ec);
#ifdef _WIN32
            _putenv_s("FACTORIA_EXPORT_CONFIG", machineConfig.c_str());
#else
            setenv("FACTORIA_EXPORT_CONFIG", machineConfig.c_str(), 1);
#endif
        }
        // Set Up This Computer installs into FACTORIA_HOME: a folder of the autotest's own, never the user's ~/.factoria. And the
        // editor's setup context cannot download or run anything, so no click of the autotest can install a thing (the one
        // exception is FA_EDITOR_AUTOTEST_REAL_CMAKE=1, a manual end-to-end check of the CMake button; ctest never sets it).
        {
            const stdfs::path home = base / "factoria_home";
            fs::remove_tree(home, ec);
            // That home would hide the shader compiler installed in the real one (`factoria setup shaders`, as CI does):
            // hand it over through SOKOL_SHDC, so the custom material of the autotest compiles as in the user's editor.
            const std::string shdc = std::getenv("SOKOL_SHDC") ? std::string() : find_sokol_shdc(SetupContext{});
#ifdef _WIN32
            _putenv_s("FACTORIA_HOME", home.string().c_str());
            if (!shdc.empty()) _putenv_s("SOKOL_SHDC", shdc.c_str());
#else
            setenv("FACTORIA_HOME", home.string().c_str(), 1);
            if (!shdc.empty()) setenv("SOKOL_SHDC", shdc.c_str(), 1);
#endif
            const char* real = std::getenv("FA_EDITOR_AUTOTEST_REAL_CMAKE");
            if (!(real && *real && std::string(real) != "0")) {
                SetupContext world;
                world.download = [](const DownloadRequest& rq) {
                    DownloadResult r;
                    r.ok = false;
                    r.error = make_error("The editor autotest never downloads anything (" + rq.url + ").");
                    return r;
                };
                world.run = [](const ProcessOptions& o) -> Result<ProcessResult> {
                    return make_error("The editor autotest never runs programs (" + (o.argv.empty() ? std::string() : o.argv[0]) + ").");
                };
                // What the checks see does not depend on the computer they run on: no JDK, SDK, mobile libraries or Xcode of its own.
                world.executableDir = (base / "no-exe").string();
                world.applicationsDir = (base / "no-apps").string();
                AndroidToolchainSearch search;
                search.env = [](const std::string&) { return std::string(); };
                search.jdk.push_back({(home / "android" / "jdk").string(), "FactorIA"});
                search.sdk.push_back({(home / "android" / "sdk").string(), "FactorIA"});
                world.toolchainSearch = search;
                setupTestContext_ = world;
            }
        }
        // Unique per run (an unseeded std::rand() always gave the same name, and two autotests running at once, from two
        // checkouts, deleted each other's project).
        const auto stamp = std::chrono::steady_clock::now().time_since_epoch().count();
        stdfs::path proj = stdfs::temp_directory_path() / ("fa_editor_autotest_project_" + std::to_string(stamp));
        fs::remove_tree(proj, ec);
        auto r = atWelcome_ ? Result<ScaffoldResult>(Error{"welcome mode"}) : create_project(proj.string(), "2d-platformer", ScaffoldOptions{"Autotest Platformer"});
        if (atWelcome_) {
        } else if (!r) {
            atFailures_.push_back("create_project: " + r.error().to_string());
        } else {
            dir = r->dir;
            atTempProject_ = dir;
        }
    } else {
        std::string h = home_dir();
        // layout2: a new name, so everyone starts on the AI layout once
        if (!h.empty()) iniPath_ = (std::filesystem::path(h) / ".factoria" / "editor_layout2.ini").string();
        maximize_window();  // the game view and the AI chat use the whole screen
        if (!update_repo().empty()) {  // a downloaded package: offer newer releases (draw_update_popup)
            remove_update_leftovers(executable_dir());
            updateThread_ = std::thread([this] {
                auto r = check_for_update();
                if (!r) FA_WARN("editor", "update check: {}", r.error().to_string());
                else if (r->available()) {
                    update_ = std::move(*r);
                    updateStage_ = UpdateStage::Offer;
                }
            });
        }
    }
    if (!dir.empty() && !fs::exists((std::filesystem::path(dir) / kProjectFileName).string())) {
        std::string root = find_project_root(dir);
        if (!root.empty()) dir = root;
    }
    set_update_status_extra("editor", [this] {  // engine.update_status: what the editor's notice says
        const std::string blocker = disk_restart_blocker();
        return Json::object({{"noticeShown", disk_update_due()},
                             {"restartAllowed", blocker.empty()},
                             {"restartBlockedBy", blocker}});
    });
    boot(dir);
    if (!bootError_.empty()) {
        notify(bootError_, 2);
        showProjectDialog_ = true;
    } else if (!engine_) {
        showProjectDialog_ = true;
    }
    if (autotest_) FA_INFO("editor", "autotest mode: project {} output {}", dir, atOutDir_);
}

void Editor::on_cleanup() {
    atWatchdogStop_ = true;
    if (atWatchdog_.joinable()) atWatchdog_.join();
    set_update_status_extra("editor", nullptr);
    ai_stop();
    queue_.close();
    if (uiUp_) {
        ui::shutdown();
        uiUp_ = false;
    }
    if (engine_) {
        for (auto& [path, t] : textures_) (void)path, (void)t;
        textures_.clear();
        engine_->shutdown();
        engine_.reset();
    } else if (gfxUp_) {
        ui::gfx_shutdown();
        gfxUp_ = false;
    }
    if (!atTempProject_.empty()) {
        std::error_code ec;
        fs::remove_tree(atTempProject_, ec);
    }
    if (restartAfterQuit_)
        if (auto r = start_editor_process(projectDir_); !r) FA_WARN("editor", "restart after the update: {}", r.error().to_string());
}

void Editor::save_recent_projects() {
    const std::string h = home_dir();
    if (autotest_ || h.empty()) return;
    Json j = Json::array();
    for (auto& r : recentProjects_) j.push_back(r);
    std::error_code ec;
    std::filesystem::create_directories(std::filesystem::path(h) / ".factoria", ec);
    (void)save_json_file((std::filesystem::path(h) / ".factoria" / "editor_recent.json").string(), j);
}

bool Editor::open_project(const std::string& dir) {
    pendingOpen_ = dir;
    return true;
}

bool Editor::boot(const std::string& dirIn) {
    std::string dir = dirIn;
    ai_stop();
    reset_export_state();  // an export of the previous project finishes first
    reset_platform_settings_state();  // so does a keystore being created; the unsaved settings of the old project are dropped
    // Tear down: UI first (it owns GPU resources), then the engine (owns sg_setup).
    if (uiUp_) {
        ui::shutdown();
        uiUp_ = false;
    }
    if (engine_) {
        for (auto& [path, t] : textures_) {
            (void)path;
            if (t.view || t.image) ui::destroy_texture(t.image, t.view);
        }
        for (auto& [path, p] : iconPreviews_) {
            (void)path;
            if (p.tex.view || p.tex.image) ui::destroy_texture(p.tex.image, p.tex.view);
        }
        iconPreviews_.clear();
        engine_->shutdown();
        engine_.reset();
    } else if (gfxUp_) {
        ui::gfx_shutdown();
    }
    gfxUp_ = false;
    textures_.clear();
    imageSizes_.clear();
    undo_.clear();
    redo_.clear();
    selectedId_.clear();
    play_ = PlayState::Edit;
    dirty_ = false;
    feedbackMtime_ = INT64_MIN;
    feedbackDoc_ = Json();
    layoutBuilt_ = false;
    profView_.reset();
    reset_audio_log(audioLog_);  // a new engine has a new play log that starts at seq 1
    bootError_.clear();
    projectDir_.clear();
    projectName_.clear();
    scenePath_.clear();

    if (!dir.empty()) {
        auto ps = load_project(dir);
        if (!ps) {
            bootError_ = "Cannot open project '" + dir + "': " + ps.error().to_string();
            dir.clear();
        }
    }
    if (!dir.empty()) {
        EngineConfig cfg;
        cfg.projectDir = dir;
        cfg.shaderCompiler = make_engine_shader_compiler(dir);
        cfg.editorMode = true;
        cfg.hotReload = false;       // the editor reloads scenes and scripts itself
        cfg.hotReloadAssets = true;  // but materials, snippets and textures edited on disk show right away
        cfg.audioDevice = !autotest_;
        if (!autotest_) {  // playing in the editor is playing: the player's real date (the autotest keeps the fixed one)
            const CalendarDate today = local_calendar_date();
            cfg.date = today.iso_datetime();
            cfg.dateUtcOffsetMinutes = today.utcOffsetMinutes;
        }
        engine_ = std::make_unique<Engine>();
        GfxEnvironment env = app_gfx_environment();
        std::string err;
        if (!engine_->init(cfg, &env, &err)) {
            bootError_ = "Engine failed to start for '" + dir + "': " + err;
            engine_->shutdown();
            engine_.reset();
            dir.clear();
        }
    }
    if (!engine_) {
        if (!sg_isvalid()) ui::gfx_setup();
        gfxUp_ = true;
    }
    ui::setup(iniPath_.empty() ? nullptr : iniPath_.c_str());
    panelMask_ = -1;
    register_layout_settings();
    // sokol_app hands back the last pasted text when the clipboard holds no text (a picture): ImGui would paste that
    // again, and the AI panel's Ctrl+V would never see an empty clipboard and attach the picture.
    ImGui::GetPlatformIO().Platform_GetClipboardTextFn = [](ImGuiContext*) {
        return clipboard_has_text() ? sapp_get_clipboard_string() : "";
    };
    uiUp_ = true;
    queue_.reopen();

    if (engine_) {
        projectDir_ = std::filesystem::absolute(dir).lexically_normal().string();
        while (projectDir_.size() > 1 && (projectDir_.back() == '/' || projectDir_.back() == '\\')) projectDir_.pop_back();
        fs::set_project_root(projectDir_);
        projectName_ = engine_->project().name;
        // Closed engine feedback moves to ENGINE_FEEDBACK.archive.json so the file only holds what is still open.
        if (const std::string fbPath = fs::join(projectDir_, engine_->project().feedbackFile); fs::exists(engine_->project().feedbackFile)) {
            if (auto r = archive_closed_feedback_file(fbPath); !r) FA_WARN("editor", "feedback archive: {}", r.error().to_string());
            else if (r->moved > 0) FA_INFO("editor", "moved {} closed feedback entries to the archive", r->moved);
        }
        scenePath_ = world().scene_path();
        if (scenePath_.empty()) scenePath_ = engine_->project().mainScene;
        register_project_commands(*engine_, projectDir_);
        engine_->set_paused(true);
        install_command_overrides();
        // Remember the project.
        recentProjects_.erase(std::remove(recentProjects_.begin(), recentProjects_.end(), projectDir_), recentProjects_.end());
        recentProjects_.insert(recentProjects_.begin(), projectDir_);
        if (recentProjects_.size() > 8) recentProjects_.resize(8);
        save_recent_projects();
        set_window_title(editor_window_title(FA_ENGINE_VERSION, projectName_));
        FA_INFO("editor", "opened project '{}' ({})", projectName_, projectDir_);
        if (!aiDetected_.load() && !aiDetecting_.load()) ai_refresh_providers();
    } else {
        set_window_title(editor_window_title(FA_ENGINE_VERSION, ""));  // the Open or create a project dialog
    }
    return engine_ != nullptr;
}

// The engine's current scene path now stays on the edited scene across Play/Stop/Undo (restores use
// Engine::load_scene_json). scene.save / scene.reload are still wrapped because they also have to keep the
// editor's own state (dirty flag, undo history) in sync.
void Editor::install_command_overrides() {
    CommandRegistry& reg = engine_->commands();
    if (const CommandInfo* ci = reg.info("scene.save")) {
        CommandInfo info = *ci;
        reg.add(info, [this](const Json& a) -> Json {
            const std::string path = a.value("path", scenePath_);
            if (auto w = fs::check_writable(path); !w.ok())  // same write rule as the engine's scene.save
                throw CommandError("invalid_argument", w.error().message, w.error().hint);
            auto r = save_scene_file(world(), path);
            if (!r) throw CommandError("failed", r.error().message, r.error().hint);
            if (path == scenePath_) dirty_ = false;
            return Json::object({{"ok", true}, {"path", path}, {"entities", world().entity_count()}});
        });
    }
    if (const CommandInfo* ci = reg.info("scene.reload")) {
        CommandInfo info = *ci;
        reg.add(info, [this](const Json&) -> Json {
            std::string err;
            const bool ok = engine_->load_scene(scenePath_, &err);
            world().set_scene_path(scenePath_);
            undo_.clear();
            redo_.clear();
            dirty_ = false;
            return Json::object({{"ok", ok}, {"scene", scenePath_}, {"messages", err.empty() ? Json::array() : Json::array({err})}});
        });
    }
}

// ------------------------------------------------------------------------------------------
void Editor::on_event(const sapp_event* e) {
    if (e->type == SAPP_EVENTTYPE_QUIT_REQUESTED) {
        if (updateStage_ == UpdateStage::Installing) {  // the files are being replaced: wait for it
            sapp_cancel_quit();
            return;
        }
        if (dirty_ && engine_ && !autotest_) {
            sapp_cancel_quit();
            showQuitDialog_ = true;
        }
        return;
    }
    if (e->type == SAPP_EVENTTYPE_FOCUSED) diskPollNow_ = true;  // back to the window: was the program replaced meanwhile?
    if (!uiUp_) return;
    ui::handle_event(e);
    if (!engine_) return;
    ImGuiIO& io = ImGui::GetIO();
    const bool gameActive = play_ == PlayState::Playing;
    const float dpi = dpi_ > 0 ? dpi_ : 1.0f;
    auto to_design = [&](float mx, float my) {
        const float lx = mx / dpi, ly = my / dpi;
        const float tw = float(engine_->renderer() ? engine_->renderer()->target_width() : 1);
        const float th = float(engine_->renderer() ? engine_->renderer()->target_height() : 1);
        return Vec2{(lx - vpImageMin_.x) / std::max(1.0f, vpImageSize_.x) * tw,
                    (ly - vpImageMin_.y) / std::max(1.0f, vpImageSize_.y) * th};
    };
    switch (e->type) {
        case SAPP_EVENTTYPE_KEY_DOWN:
        case SAPP_EVENTTYPE_KEY_UP:
            if (gameActive && vpFocused_ && !io.WantTextInput && !(e->type == SAPP_EVENTTYPE_KEY_DOWN && e->key_repeat) &&
                e->key_code != SAPP_KEYCODE_F9) {  // F9 marks a problem (build_ui): the game does not see it
                engine_->input().on_key(map_key(e->key_code), e->type == SAPP_EVENTTYPE_KEY_DOWN);
            }
            break;
        case SAPP_EVENTTYPE_CHAR:
            if (gameActive && vpFocused_ && !io.WantTextInput && e->char_code >= 32 && e->char_code != 127)
                engine_->input().on_text(e->char_code);
            break;
        case SAPP_EVENTTYPE_MOUSE_MOVE:
            if (gameActive && (vpHovered_ || vpMouseCaptured_[0] || vpMouseCaptured_[1] || vpMouseCaptured_[2])) {
                engine_->input().on_mouse_move(to_design(e->mouse_x, e->mouse_y));
            }
            break;
        case SAPP_EVENTTYPE_MOUSE_DOWN:
        case SAPP_EVENTTYPE_MOUSE_UP: {
            int b = e->mouse_button == SAPP_MOUSEBUTTON_LEFT ? 0 : e->mouse_button == SAPP_MOUSEBUTTON_RIGHT ? 1 : e->mouse_button == SAPP_MOUSEBUTTON_MIDDLE ? 2 : -1;
            if (b < 0) break;
            const MouseButton mb = b == 0 ? MouseButton::Left : b == 1 ? MouseButton::Right : MouseButton::Middle;
            if (e->type == SAPP_EVENTTYPE_MOUSE_DOWN) {
                if (gameActive && vpHovered_) {
                    engine_->input().on_mouse_move(to_design(e->mouse_x, e->mouse_y));
                    engine_->input().on_mouse_button(mb, true);
                    vpMouseCaptured_[b] = true;
                }
            } else if (vpMouseCaptured_[b]) {
                engine_->input().on_mouse_button(mb, false);
                vpMouseCaptured_[b] = false;
            }
            break;
        }
        case SAPP_EVENTTYPE_MOUSE_SCROLL:
            if (gameActive && vpHovered_) engine_->input().on_mouse_wheel(e->scroll_y);
            break;
        case SAPP_EVENTTYPE_UNFOCUSED:
        case SAPP_EVENTTYPE_ICONIFIED:
            engine_->input().release_all();
            break;
        case SAPP_EVENTTYPE_FILES_DROPPED:
            ai_on_files_dropped();  // pictures dropped on the window go to the AI Assistant's message (ai_panel.cpp)
            break;
        default:
            break;
    }
}

// ------------------------------------------------------------------------------------------
std::optional<CommandResult> Editor::run_queued(const std::string& name, const Json& args) {
    const auto t0 = std::chrono::steady_clock::now();
    auto elapsed = [&] { return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count(); };
    auto finish = [this, name, args](const std::shared_ptr<std::promise<CommandResult>>& promise, CommandResult r) {
        after_command(name, args, r);
        promise->set_value(std::move(r));
    };

    // game.step with many frames: run it in slices of ~8 ms, one slice per UI frame. A first {frames:0} call applies
    // press/release (and reports bad input at once); the last one builds the same state summary a single call would,
    // with the new-error/warning counters measured from before the first slice.
    if (name == "game.step" && args.is_object() && args.contains("frames") && args["frames"].is_number_integer() &&
        args["frames"].get<long long>() > 30 && args["frames"].get<long long>() <= 100000) {
        Json first = args;
        first["frames"] = 0;
        CommandResult r = engine_->commands().call(name, first);
        if (!r.ok) return r;
        auto promise = queue_.take_current();
        auto left = std::make_shared<int>(args["frames"].get<int>());
        const std::size_t errs0 = error_count();
        const std::uint64_t seq0 = log_last_seq();
        slicedJob_ = [this, promise, left, errs0, seq0, finish]() {
            const auto s0 = std::chrono::steady_clock::now();
            while (*left > 0) {
                engine_->step(1);
                --*left;
                if (std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - s0).count() > 8.0) break;
            }
            if (*left > 0) return false;
            CommandResult r = engine_->commands().call("game.step", Json::object({{"frames", 0}}));
            if (r.ok && r.result.is_object()) {
                r.result["newLogErrors"] = error_count() - errs0;
                r.result.erase("newWarnings");
                Json logs = Json::array();
                for (const LogEntry& l : recent_logs(10, LogLevel::Warn, seq0))
                    logs.push_back(Json::object({{"level", log_level_name(l.level)}, {"category", l.category}, {"message", l.message}}));
                if (!logs.empty()) r.result["newWarnings"] = logs;
            }
            finish(promise, std::move(r));
            return true;
        };
        return std::nullopt;
    }

    // project.test: runs the engine's own test runner, which uses process-global state (log sinks and level, the
    // project file system, the live world), so a second engine on a worker thread is not safe. Instead one test file
    // runs per UI frame and the per-file reports are merged. (A single very long file still blocks for its duration.)
    if (name == "project.test") {
        std::vector<std::string> files;
        if (args.is_object() && args.contains("files") && args["files"].is_array()) {
            for (const Json& f : args["files"]) if (f.is_string()) files.push_back(f.get<std::string>());
        } else {
            for (const auto& f : fs::list("tests", true, ".js"))
                if (f.size() >= 8 && f.compare(f.size() - 8, 8, ".test.js") == 0) files.push_back(f);
        }
        if (files.size() > 1) {
            auto promise = queue_.take_current();
            const std::string filter = args.is_object() ? args.value("filter", std::string()) : std::string();
            auto merged = std::make_shared<Json>(Json::object({{"passed", 0}, {"failed", 0}, {"cases", Json::array()},
                                                               {"loadErrors", Json::array()}, {"logs", Json::array()}}));
            auto summary = std::make_shared<std::string>();
            auto next = std::make_shared<std::size_t>(0);
            slicedJob_ = [this, promise, files, filter, merged, summary, next, finish]() {
                Json a = Json::object({{"files", Json::array({files[*next]})}});
                if (!filter.empty()) a["filter"] = filter;
                CommandResult r = engine_->commands().call("project.test", a);
                ++*next;
                if (!r.ok) {
                    finish(promise, std::move(r));
                    return true;
                }
                Json& m = *merged;
                const Json& j = r.result;
                m["passed"] = m["passed"].get<int>() + j.value("passed", 0);
                m["failed"] = m["failed"].get<int>() + j.value("failed", 0);
                for (const char* k : {"cases", "loadErrors", "logs"})
                    if (j.contains(k) && j[k].is_array()) for (const Json& e : j[k]) m[k].push_back(e);
                const std::string s = j.value("summary", std::string());
                const auto nl = s.rfind('\n');
                if (nl != std::string::npos) *summary += s.substr(0, nl + 1);  // drop the per-file totals line
                if (*next < files.size()) return false;
                if (m["logs"].empty()) m.erase("logs");
                const bool ok = m["failed"].get<int>() == 0 && m["loadErrors"].empty();
                *summary += std::to_string(m["passed"].get<int>()) + " passed, " + std::to_string(m["failed"].get<int>()) + " failed";
                if (!m["loadErrors"].empty()) *summary += ", " + std::to_string(m["loadErrors"].size()) + " file(s) failed to load";
                m["ok"] = ok;
                m["summary"] = *summary;
                m["files"] = files;
                CommandResult done;
                done.ok = true;
                done.result = m;
                finish(promise, std::move(done));
                return true;
            };
            return std::nullopt;
        }
    }

    const CommandInfo* info = engine_->commands().info(name);
    const bool mutating = info && !info->readOnly && command_edits_scene(name, args);
    if (mutating && play_ == PlayState::Edit) begin_edit("ai:" + name + ":" + std::to_string(uiFrame_));
    CommandResult r = engine_->commands().call(name, args);
    if (mutating && r.ok && play_ == PlayState::Edit) dirty_ = true;
    after_command(name, args, r);
    if (!queue_.current_tag().empty()) ai_note_command(queue_.current_tag(), name, args, r);  // which chat's run changed what
    if (elapsed() > 100.0) FA_WARN("editor", "command {} took {:.0f} ms on the UI thread", name, elapsed());
    return r;
}

void Editor::on_frame(double dt) {
    atHeartbeat_.fetch_add(1, std::memory_order_relaxed);  // the autotest's watchdog sees the editor alive
    time_ += dt;
    poll_disk_update();
    if (dt > 0) fps_ = fps_ * 0.9 + (1.0 / dt) * 0.1;
    if (!pendingOpen_.empty() || pendingWelcome_) {
        std::string dir = std::move(pendingOpen_);
        pendingOpen_.clear();
        pendingWelcome_ = false;
        boot(dir);
        if (!bootError_.empty()) {
            dlgError_ = bootError_;
            showProjectDialog_ = true;
        } else {
            showProjectDialog_ = !engine_;
            dlgError_.clear();
        }
        if (sg_isvalid()) sg_commit();
        return;  // fresh GPU state; start rendering next frame
    }
    dpi_ = sapp_dpi_scale();
    if (autotest_) autotest_pre_frame();
    if (engine_) {
        // The Win32 message loop only runs between frames: a long AI command inside this frame makes Windows treat the
        // window as hung. So queued commands share a ~10 ms budget per frame, and the two known long ones are sliced.
        if (slicedJob_) {
            if (slicedJob_()) slicedJob_ = nullptr;
        } else {
            queue_.pump([this](const std::string& name, const Json& args) { return run_queued(name, args); }, 10.0);
        }
        const bool slicing = bool(slicedJob_);
        sync_scene_path();
        ai_drain_events();
        ai_review_tick();
        const std::uint64_t frameBefore = engine_->frame_index();
        if (stepPending_ > 0) {
            --stepPending_;
            engine_->step(1);
        } else if (slicing) {
            // a sliced game.step/project.test owns the simulation: extra frames would change its result
        } else {
            engine_->frame(dt);
            if (play_ == PlayState::Playing) session_frame(dt, frameBefore);
        }
        profile_tick(frameBefore);
    }

    const int fbW = sapp_width(), fbH = sapp_height();
    ui::new_frame(fbW, fbH, dt, dpi_);
    ++uiFrame_;
    build_ui();
    ui::flush();

    sg_pass pass{};
    pass.action.colors[0].load_action = SG_LOADACTION_CLEAR;
    pass.action.colors[0].clear_value = {0.08f, 0.085f, 0.095f, 1.0f};
    pass.swapchain = sglue_swapchain();
    ui::note_window_swapchain(pass.swapchain);
    sg_begin_pass(&pass);
    ui::draw();
    sg_end_pass();
    sg_commit();
    if (engine_ && engine_->renderer()) engine_->renderer()->note_commit();

    // After the commit, before this callback returns: window screenshots read the frame just drawn (ui::read_backbuffer).
    bool wantShot = false;
    if (autotest_) autotest_post_frame(wantShot);
}

// ------------------------------------------------------------------------------------------
// Scene / play mode
void Editor::restore_scene(const Json& snapshot) {
    if (!engine_) return;
    // Straight from the in-memory snapshot: no temp file, and the engine's current scene path (engine.info,
    // game.state, scene.save, scene.reload) keeps pointing at the scene being edited.
    std::string err;
    if (!engine_->load_scene_json(snapshot, "editor snapshot", &err)) notify("Scene restore failed: " + err, 2);
}

bool Editor::command_edits_scene(const std::string& name, const Json& args) const {
    if (name == "prefab.save" || name == "scene.format" || name == "scene.ascii_edit" || name == "fs.delete") return false;  // files only
    if (name == "scene.import_ascii" && args.is_object() && args.contains("path")) return false;  // file mode: the world is not touched
    return true;
}

void Editor::after_command(const std::string& name, const Json& args, const CommandResult& r) {
    if (!r.ok || !engine_) return;
    // Commands that write or delete project files: the Project panel reads the folder again (it never walks the disk per frame).
    if (const CommandInfo* ci = engine_->commands().info(name); ci && !ci->readOnly)
        for (const char* prefix : {"fs.", "assets.", "prefab.", "material.", "scene.save", "scene.format", "scene.import_ascii",
                                   "scene.ascii_edit"})
            if (name.rfind(prefix, 0) == 0) { project_files_changed(); break; }
    // A file-mode import (scene.import_ascii with `path`, or scene.ascii_edit rebuilding its level) returns `path` and, unless
    // it was a dry run, `saved`: the scene file it wrote.
    const Json& res = r.result;
    const bool fileImport = (name == "scene.import_ascii" || name == "scene.ascii_edit") && res.is_object() &&
                            res.contains("path") && res.contains("saved") && res["saved"].is_string();
    if (!fileImport) return;
    // The scene file that is open was rebuilt on disk (hot reload is off in the editor): load it so the viewport shows it.
    if (fs::normalize(res["saved"].get<std::string>()) != fs::normalize(scenePath_)) return;
    if (play_ != PlayState::Edit) {
        notify(scenePath_ + " was rebuilt on disk while the game runs. Stop, then Reload the scene to see it.", 1);
        return;
    }
    reload_scene_from_disk(true);  // keepUndo: nothing the user had on screen is lost
    select_id("");
}

void Editor::sync_scene_path() {
    // Commands (scene.load from the console or the AI) may switch scenes behind our back.
    if (!engine_) return;
    const std::string p = world().scene_path();
    if (p.empty() || p == scenePath_) return;
    scenePath_ = p;
    undo_.clear();
    redo_.clear();
    dirty_ = false;
}

bool Editor::open_scene(const std::string& path) {
    if (!engine_) return false;
    if (play_ != PlayState::Edit) stop();
    std::string err;
    if (!engine_->load_scene(path, &err)) {
        notify("Cannot open scene '" + path + "': " + err, 2);
        return false;
    }
    scenePath_ = path;
    world().set_scene_path(path);
    undo_.clear();
    redo_.clear();
    selectedId_.clear();
    dirty_ = false;
    notify("Opened " + path);
    return true;
}

bool Editor::save_scene_now() {
    if (!engine_) return false;
    if (play_ != PlayState::Edit) {
        notify("Stop the game before saving (play-mode changes are temporary).", 1);
        return false;
    }
    auto r = save_scene_file(world(), scenePath_);
    if (!r) {
        notify("Save failed: " + r.error().to_string(), 2);
        return false;
    }
    dirty_ = false;
    project_files_changed();
    notify("Saved " + scenePath_);
    return true;
}

void Editor::reload_scene_from_disk(bool keepUndo) {
    if (!engine_) return;
    if (play_ != PlayState::Edit) stop();
    // What is on screen now; with keepUndo it becomes the first Ctrl+Z step, so nothing is lost silently.
    Json before;
    if (keepUndo) before = save_scene(world());
    std::string err;
    if (!engine_->load_scene(scenePath_, &err)) {
        notify("Reload failed: " + err, 2);
        return;
    }
    world().set_scene_path(scenePath_);
    undo_.clear();
    redo_.clear();
    if (keepUndo) undo_.push_back(std::move(before));
    dirty_ = false;
    notify("Reloaded " + scenePath_);
}

// The assistant edits the scene in edit mode only: what it changed after Play would be thrown away at Stop. So Play
// (and Step, which starts the game too) waits while ANY chat's run is going, and the AI panel sends nothing while the game
// runs. The note names the chats that are working (ai_editing_note).
bool Editor::ai_blocks_play() {
    if (play_ != PlayState::Edit || !ai_running()) return false;
    notify(ai_editing_note(), 1);
    return true;
}

void Editor::play() {
    if (!engine_ || play_ == PlayState::Playing) return;
    if (ai_blocks_play()) return;
    if (play_ == PlayState::Edit) {
        playSnapshot_ = save_scene(world());
        restore_scene(playSnapshot_);  // fresh instantiate: scripts and physics start clean
        session_begin();
    }
    run_.skipNext = true;
    engine_->set_paused(false);
    play_ = PlayState::Playing;
    // Keys reach the game only while the viewport is focused: focus it now (draw_viewport), unless the user types elsewhere.
    vpFocusNext_ = !(ImGui::GetCurrentContext() && ImGui::GetIO().WantTextInput);
}

void Editor::pause() {
    if (!engine_ || play_ != PlayState::Playing) return;
    engine_->set_paused(true);
    play_ = PlayState::Paused;
    engine_->input().release_all();
}

void Editor::step_once() {
    if (!engine_) return;
    if (ai_blocks_play()) return;
    if (play_ == PlayState::Edit) {
        playSnapshot_ = save_scene(world());
        restore_scene(playSnapshot_);
        play_ = PlayState::Paused;
        session_begin();
    } else if (play_ == PlayState::Playing) {
        pause();
    }
    // Engine::step renders; run it INSTEAD of engine.frame() next frame (sokol allows one render per frame).
    ++stepPending_;
}

void Editor::stop() {
    if (!engine_ || play_ == PlayState::Edit) return;
    mark_finish(true);  // a note being typed is kept
    session_end();
    engine_->set_paused(true);
    engine_->input().release_all();
    play_ = PlayState::Edit;
    stepPending_ = 0;
    restore_scene(playSnapshot_);
    playSnapshot_ = Json();
}

// ------------------------------------------------------------------------------------------
// Selection and edits
Entity Editor::selected() {
    if (!engine_ || selectedId_.empty()) return kNullEntity;
    Entity e = world().find_by_id(selectedId_);
    if (e.is_null() || !world().alive(e)) return kNullEntity;
    return e;
}

void Editor::select(Entity e) {
    selectedId_ = (e.is_null() || !engine_) ? std::string() : world().id_of(e);
}

void Editor::begin_edit(const std::string& key) {
    if (play_ != PlayState::Edit || !engine_) return;
    const bool coalesce = key == lastEditKey_ && (time_ - lastEditTime_) < 0.8;
    lastEditTime_ = time_;
    lastEditKey_ = key;
    dirty_ = true;
    if (coalesce) return;
    undo_.push_back(save_scene(world()));
    if (undo_.size() > 100) undo_.erase(undo_.begin());
    redo_.clear();
}

void Editor::undo() {
    if (play_ != PlayState::Edit || undo_.empty() || !engine_) return;
    redo_.push_back(save_scene(world()));
    Json s = std::move(undo_.back());
    undo_.pop_back();
    restore_scene(s);
    dirty_ = true;
    lastEditKey_.clear();
}

void Editor::redo() {
    if (play_ != PlayState::Edit || redo_.empty() || !engine_) return;
    undo_.push_back(save_scene(world()));
    Json s = std::move(redo_.back());
    redo_.pop_back();
    restore_scene(s);
    dirty_ = true;
    lastEditKey_.clear();
}

void Editor::set_window_title(const std::string& title) {
    windowTitle_ = title;
    app_set_title(title);
}

void Editor::notify(const std::string& text, int level) {
    toasts_.push_back(Toast{text, level, time_ + (level >= 2 ? 6.0 : 3.5)});
    if (toasts_.size() > 6) toasts_.erase(toasts_.begin());
    if (level >= 2) FA_ERROR("editor", "{}", text);
    else if (level == 1) FA_WARN("editor", "{}", text);
    else FA_INFO("editor", "{}", text);
}

void Editor::notify_action(const std::string& text, const std::string& label, std::function<void()> action, const std::string& id) {
    Toast t{text, 0, time_ + 8.0};
    t.actionLabel = label;
    t.action = std::move(action);
    t.actionId = id;
    toasts_.push_back(std::move(t));
    if (toasts_.size() > 6) toasts_.erase(toasts_.begin());
    FA_INFO("editor", "{}", text);
}

void Editor::open_screenshots_folder() {
    const std::string dir = projectDir_ + "/.factoria/screenshots";
    std::error_code ec;
    std::filesystem::create_directories(dir, ec);
    if (std::string why = open_in_file_manager(dir); !why.empty()) notify(why, 1);
}

// ------------------------------------------------------------------------------------------
// Layout and top-level UI
// The panels that can be closed, in the order of the saved mask. The dock layout itself is saved by ImGui in the same ini file.
int Editor::panels_mask() const {
    const bool flags[] = {showViewport_, showHierarchy_, showInspector_, showConsole_, showProject_,
                          showAi_,       showFeedback_,  showAudio_,     showProfiler_};
    int mask = 0;
    for (std::size_t i = 0; i < std::size(flags); ++i)
        if (flags[i]) mask |= 1 << i;
    return mask;
}

void Editor::set_panels_mask(int mask) {
    bool* flags[] = {&showViewport_, &showHierarchy_, &showInspector_, &showConsole_, &showProject_,
                     &showAi_,       &showFeedback_,  &showAudio_,     &showProfiler_};
    for (std::size_t i = 0; i < std::size(flags); ++i) *flags[i] = (mask >> i) & 1;
}

// The layout file also says which panels are open: a closed panel stays closed the next time the editor opens. The handler
// is registered after the context is created and before its first frame, which is when ImGui reads the ini file.
void Editor::register_layout_settings() {
    ImGuiSettingsHandler h;
    h.TypeName = "FactorIAEditor";
    h.TypeHash = ImHashStr("FactorIAEditor");
    h.UserData = this;
    h.ReadOpenFn = [](ImGuiContext*, ImGuiSettingsHandler*, const char* name) -> void* {
        return std::strcmp(name, "Panels") == 0 ? reinterpret_cast<void*>(1) : nullptr;
    };
    h.ReadLineFn = [](ImGuiContext*, ImGuiSettingsHandler* handler, void*, const char* line) {
        Editor* ed = static_cast<Editor*>(handler->UserData);
        int mask = 0;
        float h = 0;
        if (std::sscanf(line, "Open=%d", &mask) == 1) ed->set_panels_mask(mask);
        else if (std::sscanf(line, "AiInputHeight=%f", &h) == 1) ed->aiInputH_ = std::max(0.0f, h);
    };
    h.WriteAllFn = [](ImGuiContext*, ImGuiSettingsHandler* handler, ImGuiTextBuffer* out) {
        const Editor* ed = static_cast<const Editor*>(handler->UserData);
        out->appendf("[%s][Panels]\nOpen=%d\nAiInputHeight=%.0f\n\n", handler->TypeName, ed->panels_mask(), ed->aiInputH_);
    };
    ImGui::AddSettingsHandler(&h);
}

void Editor::build_default_layout(unsigned dockId, ImVec2 size) {
    ImGui::DockBuilderRemoveNode(dockId);
    ImGui::DockBuilderAddNode(dockId, ImGuiDockNodeFlags_DockSpace);
    ImGui::DockBuilderSetNodeSize(dockId, size);
    ImGuiID center = dockId;
    // The AI builds the game: the game view and the AI chat fill the window, logs and feedback sit under the view.
    ImGuiID ai = ImGui::DockBuilderSplitNode(center, ImGuiDir_Right, 0.32f, nullptr, &center);
    // Hand editing: the entity tree over the inspector, in a column left of the view.
    ImGuiID left = ImGui::DockBuilderSplitNode(center, ImGuiDir_Left, 0.30f, nullptr, &center);
    ImGuiID inspector = ImGui::DockBuilderSplitNode(left, ImGuiDir_Down, 0.60f, nullptr, &left);
    ImGuiID bottom = ImGui::DockBuilderSplitNode(center, ImGuiDir_Down, 0.30f, nullptr, &center);
    ImGui::DockBuilderDockWindow("Hierarchy", left);
    ImGui::DockBuilderDockWindow("Inspector", inspector);
    ImGui::DockBuilderDockWindow("###Viewport", center);
    ImGui::DockBuilderDockWindow("AI Assistant", ai);
    ImGui::DockBuilderDockWindow("Console", bottom);
    ImGui::DockBuilderDockWindow("Project", bottom);
    ImGui::DockBuilderDockWindow("Engine Feedback", bottom);
    ImGui::DockBuilderDockWindow("Audio", bottom);
    ImGui::DockBuilderDockWindow("Profiler", bottom);
    ImGui::DockBuilderFinish(dockId);
}

void Editor::build_ui() {
    ImGuiIO& io = ImGui::GetIO();
    ImGuiViewport* vp = ImGui::GetMainViewport();
    poll_export();
    poll_platform_settings();
    poll_setup();
    draw_main_menu();

    const float statusH = ImGui::GetFrameHeight() + 6;
    const float toolbarH = ImGui::GetFrameHeight() + 12;
    const ImVec2 pos = vp->WorkPos;
    const ImVec2 size(vp->WorkSize.x, std::max(1.0f, vp->WorkSize.y - statusH));

    // Keyboard shortcuts (not while typing).
    if (engine_ && !io.WantTextInput) {
        const bool ctrl = io.KeyCtrl;
        if (ctrl && ImGui::IsKeyPressed(ImGuiKey_S, false)) save_scene_now();
        if (ctrl && !io.KeyShift && ImGui::IsKeyPressed(ImGuiKey_Z, false)) undo();
        if ((ctrl && ImGui::IsKeyPressed(ImGuiKey_Y, false)) || (ctrl && io.KeyShift && ImGui::IsKeyPressed(ImGuiKey_Z, false))) redo();
        if (ImGui::IsKeyPressed(ImGuiKey_F5, false)) { if (play_ == PlayState::Edit) play(); else stop(); }
        if (ImGui::IsKeyPressed(ImGuiKey_F6, false)) { if (play_ == PlayState::Playing) pause(); else play(); }
        if (ImGui::IsKeyPressed(ImGuiKey_F10, false)) step_once();
        if (ImGui::IsKeyPressed(ImGuiKey_F9, false)) mark_problem();
    }

    // Toolbar strip.
    ImGui::SetNextWindowPos(pos);
    ImGui::SetNextWindowSize(ImVec2(size.x, toolbarH));
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(8, 5));
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.105f, 0.110f, 0.125f, 1));
    ImGui::Begin("##toolbar", nullptr,
                 ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoDocking | ImGuiWindowFlags_NoMove |
                     ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoBringToFrontOnFocus | ImGuiWindowFlags_NoScrollbar);
    draw_toolbar();
    ImGui::End();
    ImGui::PopStyleColor();
    ImGui::PopStyleVar(2);

    // Dock host.
    ImGui::SetNextWindowPos(ImVec2(pos.x, pos.y + toolbarH));
    ImGui::SetNextWindowSize(ImVec2(size.x, std::max(1.0f, size.y - toolbarH)));
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0, 0));
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
    ImGui::Begin("##dockhost", nullptr,
                 ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoDocking | ImGuiWindowFlags_NoMove |
                     ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoBringToFrontOnFocus |
                     ImGuiWindowFlags_NoNavFocus | ImGuiWindowFlags_NoBackground);
    ImGui::PopStyleVar(2);
    const ImGuiID dockId = ImGui::GetID("FactorIADockSpace");
    if (engine_ && (!layoutBuilt_ || resetLayout_)) {
        // A layout saved before the Hierarchy and Inspector existed has no place for them: build the default one once.
        const bool oldLayout = !layoutBuilt_ && ImGui::FindWindowSettingsByID(ImHashStr("Hierarchy")) == nullptr;
        if (resetLayout_ || oldLayout || ImGui::DockBuilderGetNode(dockId) == nullptr)
            build_default_layout(dockId, ImGui::GetContentRegionAvail());
        layoutBuilt_ = true;
        if (resetLayout_) set_panels_mask(0x7F);  // the default panels: Audio and Profiler stay closed
        resetLayout_ = false;
    }
    {  // a panel opened or closed (its X, the Window menu): the ini file is written soon, with the layout
        const int mask = panels_mask();
        if (panelMask_ >= 0 && mask != panelMask_) ImGui::MarkIniSettingsDirty();
        panelMask_ = mask;
    }
    ImGui::DockSpace(dockId, ImVec2(0, 0), ImGuiDockNodeFlags_None);
    ImGui::End();

    draw_status_bar();

    if (engine_) {
        if (showViewport_) draw_viewport();
        if (showHierarchy_) draw_hierarchy_panel();
        if (showInspector_) draw_inspector_panel();
        if (showConsole_) draw_console();
        if (showProject_) draw_project_panel();
        if (showAi_) draw_ai_panel();
        if (showFeedback_) draw_feedback_panel();
        if (showAudio_) draw_audio_panel();
        if (showProfiler_) draw_profiler_panel();
        if (pendingFocus_) {
            ImGui::SetWindowFocus(pendingFocus_);
            pendingFocus_ = nullptr;
        }
    }
    draw_project_dialog();
    draw_validation_window();
    draw_export_window();
    draw_platform_settings_window();
    draw_setup_window();
    draw_docs_window();
    draw_toasts();
    draw_mark_popup();
    draw_update_popup();
    draw_disk_update_notice();

    // Unsaved changes dialogs.
    if (showQuitDialog_) ImGui::OpenPopup("Unsaved changes##quit");
    if (ImGui::BeginPopupModal("Unsaved changes##quit", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::Text("Scene '%s' has unsaved changes.", scenePath_.c_str());
        if (ImGui::Button("Save and quit")) {
            save_scene_now();
            dirty_ = false;
            showQuitDialog_ = false;
            ImGui::CloseCurrentPopup();
            sapp_request_quit();
        }
        ImGui::SameLine();
        if (ImGui::Button("Discard and quit")) {
            dirty_ = false;
            showQuitDialog_ = false;
            ImGui::CloseCurrentPopup();
            sapp_request_quit();
        }
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) {
            showQuitDialog_ = false;
            restartAfterQuit_ = false;  // the update stays installed; the next start uses it (the disk notice offers Restart again)
            ImGui::CloseCurrentPopup();
        }
        ImGui::EndPopup();
    }
    if (!pendingScene_.empty()) ImGui::OpenPopup("Unsaved changes##open");
    if (ImGui::BeginPopupModal("Unsaved changes##open", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::Text("Scene '%s' has unsaved changes.", scenePath_.c_str());
        auto close = [&] { pendingScene_.clear(); ImGui::CloseCurrentPopup(); };
        if (ImGui::Button("Save, then open")) { std::string p = pendingScene_; if (save_scene_now()) open_scene(p); close(); }
        ImGui::SameLine();
        if (ImGui::Button("Discard changes")) { std::string p = pendingScene_; dirty_ = false; open_scene(p); close(); }
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) close();
        ImGui::EndPopup();
    }
    draw_ai_revert_dialog();
    if (showReloadConfirm_) ImGui::OpenPopup("Reload scene##confirm");
    if (ImGui::BeginPopupModal("Reload scene##confirm", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::TextUnformatted("Discard unsaved changes and reload the scene from disk?");
        if (ImGui::Button("Reload")) { reload_scene_from_disk(); showReloadConfirm_ = false; ImGui::CloseCurrentPopup(); }
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) { showReloadConfirm_ = false; ImGui::CloseCurrentPopup(); }
        ImGui::EndPopup();
    }
}

void Editor::draw_main_menu() {
    if (!ImGui::BeginMainMenuBar()) return;
    const bool have = engine_ != nullptr;
    const bool editing = have && play_ == PlayState::Edit;
    const bool fileOpen = ImGui::BeginMenu("File");
    at_track("menu:file");
    if (fileOpen) {
        if (ImGui::MenuItem("New Project...")) showProjectDialog_ = true;
        if (ImGui::MenuItem("Open Project...")) showProjectDialog_ = true;
        if (ImGui::BeginMenu("Recent Projects", !recentProjects_.empty())) {
            for (const auto& r : recentProjects_)
                if (ImGui::MenuItem(r.c_str())) open_project(r);
            ImGui::EndMenu();
        }
        ImGui::Separator();
        if (ImGui::MenuItem("Save Scene", "Ctrl+S", false, editing)) save_scene_now();
        if (ImGui::MenuItem("Reload Scene", nullptr, false, have)) { if (dirty_) showReloadConfirm_ = true; else reload_scene_from_disk(); }
        if (ImGui::BeginMenu("Open Scene", have)) {
            for (const auto& f : fs::list("", true))
                if (f.size() > 11 && f.ends_with(".scene.json") && f[0] != '.')
                    if (ImGui::MenuItem(f.c_str(), nullptr, f == scenePath_)) { if (dirty_) pendingScene_ = f; else open_scene(f); }
            ImGui::EndMenu();
        }
        ImGui::Separator();
        if (ImGui::MenuItem("Open Screenshots Folder", nullptr, false, have)) open_screenshots_folder();
        if (ImGui::MenuItem("Export Game...", nullptr, false, have)) open_export_window();
        ImGui::SetItemTooltip("Package the game for Windows, macOS, Linux, Android or iOS");
        if (ImGui::MenuItem("Platform Settings...", nullptr, false, have)) open_platform_settings();
        at_track("menu:platform-settings");
        ImGui::SetItemTooltip("The game icon and what each platform's export needs: Android version and signing key, macOS category, iOS team...");
        if (ImGui::MenuItem("Set Up This Computer...")) open_setup_window();
        at_track("menu:setup");
        ImGui::SetItemTooltip("Install what an export needs: the Android build tools, the players of other platforms, CMake, Xcode");
        ImGui::Separator();
        if (ImGui::MenuItem("Quit")) sapp_request_quit();
        ImGui::EndMenu();
    }
    if (ImGui::BeginMenu("Edit")) {
        if (ImGui::MenuItem("Undo", "Ctrl+Z", false, editing && !undo_.empty())) undo();
        if (ImGui::MenuItem("Redo", "Ctrl+Y", false, editing && !redo_.empty())) redo();
        ImGui::Separator();
        const int lastRun = ai_last_revertable_run();
        if (ImGui::MenuItem("Revert Last AI Run", nullptr, false, editing && !ai_chat_busy(chat_.current().id) && lastRun >= 0)) ai_revert_request(chat_.current().id, lastRun);
        at_track("menu:revert-ai");
        ImGui::SetItemTooltip("Puts the project's files and the open scene back as they were before the last run of the AI Assistant in this chat.");
        ImGui::EndMenu();
    }
    const bool viewOpen = ImGui::BeginMenu("View");
    at_track("menu:view");
    if (viewOpen) {
        ImGui::MenuItem("Viewport", nullptr, &showViewport_);
        ImGui::MenuItem("Hierarchy", nullptr, &showHierarchy_);
        at_track("menu:hierarchy");
        ImGui::MenuItem("Inspector", nullptr, &showInspector_);
        at_track("menu:inspector");
        ImGui::MenuItem("Console", nullptr, &showConsole_);
        ImGui::MenuItem("Project", nullptr, &showProject_);
        at_track("menu:project");
        ImGui::SetItemTooltip("The project's files: filter, search, drag onto the Inspector or the Viewport, open scenes");
        ImGui::MenuItem("AI Assistant", nullptr, &showAi_);
        ImGui::MenuItem("Engine Feedback", nullptr, &showFeedback_);
        ImGui::MenuItem("Audio", nullptr, &showAudio_);
        at_track("menu:audio");
        ImGui::SetItemTooltip("The live audio.log: every sound played, with its bus, volume, source entity and whether the clip loaded");
        ImGui::MenuItem("Profiler", nullptr, &showProfiler_);
        at_track("menu:profiler");
        ImGui::SetItemTooltip("Where the time goes while the game plays: milliseconds per engine system and per script behaviour class, GPU time, memory");
        ImGui::Separator();
        ImGui::MenuItem("Show colliders", nullptr, &showColliders_);
        ImGui::MenuItem("Show navmesh", nullptr, &showNav_);
        ImGui::SetItemTooltip("Draws the walkable cells of every NavMesh3D (green; red where a moving obstacle blocks; blue on a walkable moving body) and its off-mesh links (yellow lines), the ground nav.findPath walks on");
        ImGui::MenuItem("Selection overlay", nullptr, &showOverlay_);
        if (ImGui::MenuItem("Reset layout")) resetLayout_ = true;
        ImGui::EndMenu();
    }
    if (ImGui::BeginMenu("Help")) {
        if (ImGui::MenuItem("AI providers setup")) {
            auto d = read_doc("ai-providers");
            docsTitle_ = "AI_PROVIDERS.md";
            docsText_ = d ? *d : d.error().to_string();
            showDocs_ = true;
        }
        if (ImGui::MenuItem("Scripting guide")) {
            auto d = read_doc("scripting");
            docsTitle_ = "SCRIPTING.md";
            docsText_ = d ? *d : d.error().to_string();
            showDocs_ = true;
        }
        if (ImGui::MenuItem("Engine feedback guide")) {
            auto d = read_doc("engine-feedback");
            docsTitle_ = "ENGINE_FEEDBACK.md";
            docsText_ = d ? *d : d.error().to_string();
            showDocs_ = true;
        }
        ImGui::EndMenu();
    }
    ImGui::EndMainMenuBar();
}

void Editor::draw_toolbar() {
    const bool have = engine_ != nullptr;
    auto colored = [](ImVec4 c) {
        ImGui::PushStyleColor(ImGuiCol_Button, c);
        ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(std::min(1.f, c.x + 0.1f), std::min(1.f, c.y + 0.1f), std::min(1.f, c.z + 0.1f), 1));
        ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(c.x * 0.8f, c.y * 0.8f, c.z * 0.8f, 1));
    };
    ImGui::BeginDisabled(!have);
    const bool aiEditing = play_ == PlayState::Edit && ai_running();
    ImGui::BeginDisabled(play_ == PlayState::Playing || aiEditing);
    colored(ImVec4(0.18f, 0.48f, 0.26f, 1));
    if (ImGui::Button(" Play ")) play();
    ImGui::PopStyleColor(3);
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("%s", aiEditing ? ai_editing_note().c_str() : "Snapshot the scene and run the game (F5 toggles Play/Stop)");
    ImGui::SameLine();
    ImGui::BeginDisabled(play_ != PlayState::Playing);
    if (ImGui::Button(" Pause ")) pause();
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Pause the simulation (F6)");
    ImGui::SameLine();
    ImGui::BeginDisabled(aiEditing);
    if (ImGui::Button(" Step ")) step_once();
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("%s", aiEditing ? ai_editing_note().c_str() : "Advance exactly one fixed frame (F10)");
    ImGui::SameLine();
    ImGui::BeginDisabled(play_ == PlayState::Edit);
    colored(ImVec4(0.62f, 0.22f, 0.20f, 1));
    if (ImGui::Button(" Stop ")) stop();
    ImGui::PopStyleColor(3);
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Stop and restore the scene as it was before Play");

    ImGui::SameLine();
    ImGui::TextDisabled("|");
    ImGui::SameLine();
    ImGui::BeginDisabled(play_ != PlayState::Edit);
    if (ImGui::Button("Save")) save_scene_now();
    at_track("toolbar:save");
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Save the scene to %s (Ctrl+S)", scenePath_.c_str());
    ImGui::SameLine();
    if (ImGui::Button("Reload")) { if (dirty_) showReloadConfirm_ = true; else reload_scene_from_disk(); }
    ImGui::SetItemTooltip("Reload the scene from disk");
    ImGui::SameLine();
    if (ImGui::Button("Validate")) {
        validation_ = validate_project(projectDir_);
        showValidation_ = true;
        FA_INFO("editor", "validate: {} error(s), {} warning(s)", validation_.errors.size(), validation_.warnings.size());
    }
    ImGui::SetItemTooltip("Run factoria validate on the whole project");
    ImGui::SameLine();
    if (ImGui::Button("Screenshot")) {
        std::string path = ".factoria/screenshots/editor_" + std::to_string(engine_->frame_index()) + ".png";
        std::string err;
        if (engine_->screenshot(path, &err)) {
            const std::string full = projectDir_ + "/" + path;
            notify_action("Screenshot saved: " + path, std::string("Show in ") + file_manager_name(),
                          [this, full] { if (std::string why = reveal_in_file_manager(full); !why.empty()) notify(why, 1); },
                          "toast:screenshot-reveal");
        }
        else notify("Screenshot failed: " + err, 2);
    }
    at_track("toolbar:screenshot");
    ImGui::SetItemTooltip("Save the game view as PNG into .factoria/screenshots (a hidden folder:\nthe toast has a Show in %s button, and File > Open Screenshots Folder opens it)", file_manager_name());
    ImGui::SameLine();
    if (ImGui::Button("Export")) open_export_window();
    at_track("toolbar:export");
    ImGui::SetItemTooltip("Package the game for Windows, macOS, Linux, Android or iOS (File > Export Game...)");
    ImGui::SameLine();
    ImGui::TextDisabled("|");
    ImGui::SameLine();
    ImGui::BeginDisabled(play_ != PlayState::Edit || undo_.empty());
    if (ImGui::Button("Undo")) undo();
    at_track("toolbar:undo");
    ImGui::EndDisabled();
    ImGui::SameLine();
    ImGui::BeginDisabled(play_ != PlayState::Edit || redo_.empty());
    if (ImGui::Button("Redo")) redo();
    ImGui::EndDisabled();
    ImGui::SameLine();
    if (!selected().is_null()) {  // the gizmo modes act on the selection: with nothing selected they are hidden
        ImGui::TextDisabled("|");
        ImGui::SameLine();
        gizmo_toolbar_buttons();
    }
    ImGui::EndDisabled();

    const char* label = play_ == PlayState::Edit ? "EDIT" : play_ == PlayState::Playing ? "PLAYING" : "PAUSED";
    ImVec4 col = play_ == PlayState::Edit ? ImVec4(0.6f, 0.65f, 0.75f, 1) : play_ == PlayState::Playing ? ImVec4(0.4f, 0.9f, 0.5f, 1) : ImVec4(1, 0.8f, 0.3f, 1);
    const float labelX = ImGui::GetWindowWidth() - ImGui::CalcTextSize(label).x - 20;
    const float usedX = ImGui::GetCursorPosX();
    if (usedX < labelX) {  // a narrow window: the Viewport title shows the mode too, so the label gives way
        ImGui::SameLine(labelX);
        ImGui::TextColored(col, "%s", label);
    }
    const char* hint = "F9 marks a problem";
    const float hintX = labelX - ImGui::CalcTextSize(hint).x - 20;
    if (play_ == PlayState::Playing && usedX < hintX) {  // the hint lives in the toolbar, never over the game picture
        ImGui::SameLine(hintX);
        ImGui::TextDisabled("%s", hint);
        ImGui::SetItemTooltip("Pauses the game, takes a screenshot and asks for a one-line note.\nThe AI reads the notes of your last play session (AI panel: Attach last play session).");
    }
}

void Editor::draw_status_bar() {
    ImGuiViewport* vp = ImGui::GetMainViewport();
    const float h = ImGui::GetFrameHeight() + 6;
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x, vp->WorkPos.y + vp->WorkSize.y - h));
    ImGui::SetNextWindowSize(ImVec2(vp->WorkSize.x, h));
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(10, 4));
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.17f, 0.36f, 0.62f, 1));
    ImGui::Begin("##status", nullptr,
                 ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoDocking | ImGuiWindowFlags_NoMove |
                     ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoScrollbar);
    if (engine_) {
        if (time_ - scriptErrorsPolled_ > 0.5) {
            scriptErrorsPolled_ = time_;
            CommandResult r = engine_->commands().call("script.errors");
            if (r.ok) {
                if (r.result.is_array()) scriptErrors_ = int(r.result.size());
                else if (r.result.is_object() && r.result.contains("errors") && r.result["errors"].is_array())
                    scriptErrors_ = int(r.result["errors"].size());
                else if (r.result.is_object() && r.result.contains("count") && r.result["count"].is_number())
                    scriptErrors_ = r.result["count"].get<int>();
            }
        }
        ImGui::Text("%s", projectName_.c_str());
        ImGui::SameLine(); ImGui::TextDisabled("|"); ImGui::SameLine();
        ImGui::Text("%s%s", scenePath_.c_str(), dirty_ ? " *" : "");
        ImGui::SameLine(); ImGui::TextDisabled("|"); ImGui::SameLine();
        ImGui::Text("%.0f FPS", fps_);
        ImGui::SameLine(); ImGui::TextDisabled("|"); ImGui::SameLine();
        ImGui::Text("%zu entities", world().entity_count());
        ImGui::SameLine(); ImGui::TextDisabled("|"); ImGui::SameLine();
        char buf[64];
        std::snprintf(buf, sizeof buf, "%d script error%s", scriptErrors_, scriptErrors_ == 1 ? "" : "s");
        ImGui::PushStyleColor(ImGuiCol_Text, scriptErrors_ > 0 ? ImVec4(1, 0.75f, 0.7f, 1) : ImVec4(0.9f, 0.95f, 1, 1));
        if (ImGui::Selectable(buf, false, 0, ImGui::CalcTextSize(buf))) {
            consoleLevel_ = 4;
            focus_window("Console");
        }
        ImGui::PopStyleColor();
    } else {
        ImGui::TextUnformatted("No project open");
    }
    ImGui::End();
    ImGui::PopStyleColor();
    ImGui::PopStyleVar(2);
}

}  // namespace fa::editor

namespace fa {
int run_editor(const EditorOptions& options) {
    editor::Editor ed(options);
    return ed.run();
}
}  // namespace fa
