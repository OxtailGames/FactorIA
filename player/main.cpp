// factoria_player: the minimal runtime shipped inside exported games.
//
//   Desktop : factoria_player [projectDir | game.pak] [--scene S] [--fullscreen] [--frames N] [--version] [--help]
//             Without an argument the game is, in this order: the folder "<exe dir>/game" (or
//             "<exe dir>/../Resources/game" inside a macOS .app) when it contains factoria.json; else the pack
//             "<exe dir>/game.pak" (or "<exe dir>/../Resources/game.pak"), the one archive a `factoria export
//             --release` writes in place of the folder (fa/core/pack.h); else the current directory. A game.pak given
//             as the argument is mounted the same way. While a pack is mounted fa::fs answers every project-relative
//             path from it, and the project root is the (absent) game/ folder next to the pack, so a file the game
//             writes with a relative path lands there as it always did; save games go to the user folder.
//             The log of every run also goes to <save folder>/log.txt, and a crash leaves a report (stack + last log
//             lines; a minidump on Windows) in <save folder>/crashes (fa/core/crash.h, docs/EXPORTING.md). On Windows the
//             player is a GUI program (no console window); started from a terminal it prints to that terminal.
//   Android : sokol_main() via NativeActivity. The project lives in the APK assets (root "").
//   iOS     : sokol_main(). The project lives in the app bundle at <bundle resources>/game.
//   Web     : main() in a browser page. The page writes game.pak to /game.pak of the in-memory file system first.
//
// Mobile entry points are UNTESTED on the Linux development machine (CI builds them).
#include <cctype>
#include <filesystem>
#include <string>

#include "fa/core/build_info.h"
#include "fa/core/crash.h"
#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/log.h"
#include "fa/core/pack.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif
#if defined(__ANDROID__) || (defined(__APPLE__) && TARGET_OS_IPHONE)
#define FA_PLAYER_MOBILE 1
#endif

namespace stdfs = std::filesystem;

#if defined(__EMSCRIPTEN__)
// ------------------------------------------------------------------------------------------------
// Web (WebAssembly in a browser page: platforms/web/shell.html, `factoria export --platform web`)
// ------------------------------------------------------------------------------------------------
// The page writes the game pack to /game.pak in the in-memory file system before main() runs. sapp_run() returns at once
// here and the frames come from requestAnimationFrame, so nothing the frame callbacks use may live on main()'s stack: the
// engine is owned by the shared state inside the AppDesc, which to_sapp_desc copies to a static.
#include <emscripten.h>

namespace {

constexpr const char* kWebPack = "/game.pak";

// Shows a problem on the page in plain words (Module.faFatal, set by the page) and in the console. The page keeps the loading
// screen's place for it.
EM_JS(void, fa_web_fatal, (const char* text), {
    const message = UTF8ToString(text);
    console.error(message);
    if (Module.faFatal) Module.faFatal(message);
});

// The page hides its loading screen (Module.faReady, optional).
EM_JS(void, fa_web_ready, (), { if (Module.faReady) Module.faReady(); });

int web_error(const std::string& text) {
    fa_web_fatal(text.c_str());
    return 1;
}

// The state of the start, which continues after the save folder is loaded from the browser's storage (asynchronous).
fa::EngineConfig g_cfg;

void start_game() {
    fa::AppDesc desc = fa::make_app_desc(g_cfg);  // == what run_windowed() does
    desc.fullscreen = false;                       // a page cannot start fullscreen: the browser wants a click first
    fa::run_app(desc);                             // returns at once; the browser calls the frame callback
    fa_web_ready();
}

}  // namespace

int main() {
    // Keeps the fingerprint marker in the wasm: `factoria setup webplayer` and the web export read it to see that this
    // player and factoria come from the same commit.
    fa::log(fa::LogLevel::Debug, "player", std::string("factoria_player " FA_ENGINE_VERSION " (build ") + fa::build_fingerprint() + ")");
    if (!fa::fs::exists(kWebPack)) {
        return web_error(std::string("error: ") + kWebPack + " is missing: the page must write the game pack there before "
                         "the player starts.\nhint: use the index.html that `factoria export --platform web` writes, next to "
                         "factoria_player.js, factoria_player.wasm and game.pak, and serve the folder over http (a file:// "
                         "page cannot load them).\n");
    }
    // From here on every project-relative read of the engine (factoria.json, scenes, assets, scripts) comes out of the pack.
    if (auto mounted = fa::fs::mount_pack(kWebPack); !mounted.ok()) return web_error("error: " + mounted.error().to_string());
    fa::fs::set_project_root("/game");
    if (!fa::fs::exists(fa::kProjectFileName))
        return web_error(std::string("error: no ") + fa::kProjectFileName + " in " + kWebPack +
                         ".\nhint: game.pak must be the pack `factoria export --release` writes.");
    g_cfg.projectDir = "/game";
    g_cfg.hotReload = false;
    g_cfg.platformFallback = "none";  // a shipped game never gets the fake store: no free purchases (docs/PLATFORM.md)
    auto proj = fa::load_project(g_cfg.projectDir);
    if (!proj.ok()) return web_error("error: " + proj.error().to_string());

    // The save folder is the only persistent part of the file system: /save/<game id> lives in the browser's IndexedDB
    // (one database per game, so games on one site do not share saves). log.txt and crash reports are not written: the log
    // goes to the browser console.
    std::string id = proj->id.empty() ? "factoria-game" : proj->id;
    for (char& c : id)
        if (!std::isalnum(static_cast<unsigned char>(c)) && c != '-' && c != '_' && c != '.') c = '_';
    const stdfs::path saveDir = stdfs::path("/save") / id;
    fa::fs::set_user_dir(saveDir);
    fa::fs::restore_user_dir(saveDir, start_game);  // calls start_game() once the saves are loaded
    return 0;  // the runtime stays alive: the page runs the frames
}

#elif !defined(FA_PLAYER_MOBILE)
// ------------------------------------------------------------------------------------------------
// Desktop
// ------------------------------------------------------------------------------------------------
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <mutex>

#if defined(_WIN32)
#include <windows.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#endif

namespace {

stdfs::path executable_dir() {
    std::error_code ec;
#if defined(_WIN32)
    wchar_t buf[MAX_PATH * 4];
    DWORD n = GetModuleFileNameW(nullptr, buf, DWORD(sizeof(buf) / sizeof(buf[0])));
    if (n > 0) return stdfs::path(std::wstring(buf, n)).parent_path();
#elif defined(__APPLE__)
    char buf[4096];
    uint32_t size = sizeof(buf);
    if (_NSGetExecutablePath(buf, &size) == 0) return stdfs::weakly_canonical(buf, ec).parent_path();
#else
    stdfs::path p = stdfs::read_symlink("/proc/self/exe", ec);
    if (!ec) return p.parent_path();
#endif
    return stdfs::current_path(ec);
}

bool has_project(const stdfs::path& dir) {
    std::error_code ec;
    return stdfs::exists(dir / fa::kProjectFileName, ec);
}

// Writable per-user directory for save games of a shipped game.
stdfs::path desktop_user_dir(const std::string& gameId) {
#if defined(_WIN32)
    const char* base = std::getenv("APPDATA");
    stdfs::path root = base ? stdfs::path(base) : stdfs::temp_directory_path();
#elif defined(__APPLE__)
    const char* home = std::getenv("HOME");
    stdfs::path root = stdfs::path(home ? home : ".") / "Library" / "Application Support";
#else
    const char* home = std::getenv("HOME");
    const char* xdg = std::getenv("XDG_DATA_HOME");
    stdfs::path root = xdg && *xdg ? stdfs::path(xdg) : stdfs::path(home ? home : ".") / ".local" / "share";
#endif
    return root / (gameId.empty() ? "factoria-game" : gameId);
}

// Every log line also goes to <save folder>/log.txt, rewritten on each start: a double-clicked game has no console, and
// this is the file a player can send with a bug report.
void log_to_file(const stdfs::path& dir) {
    static std::ofstream file;
    static std::mutex mutex;
    std::error_code ec;
    stdfs::create_directories(dir, ec);
    file.open(dir / "log.txt", std::ios::binary | std::ios::trunc);
    if (!file) return;
    fa::add_log_sink([](const fa::LogEntry& e) {
        std::lock_guard<std::mutex> lock(mutex);
        file << fa::format_log_line(e) << '\n' << std::flush;
    });
}

// A crash leaves <save folder>/crashes/crash-<time>.txt (and .dmp on Windows) next to log.txt. The next start says so once.
void report_crashes_to_file(const stdfs::path& saveDir, const fa::ProjectSettings& project) {
    fa::CrashReporterOptions crash;
    crash.dir = saveDir / "crashes";
    crash.info = {"game: " + project.name + " " + project.version, "game id: " + project.id};
    if (auto r = fa::install_crash_reporter(crash); !r.ok()) {
        FA_WARN("player", "crash reports are off: {}", r.error().to_string());
        return;
    }
    if (auto previous = fa::take_previous_crash_report(crash.dir); !previous.empty())
        FA_WARN("player", "the previous run crashed; the report is {}", previous.string());
}

#if defined(_WIN32)
bool g_noConsole = false;  // double-clicked: nobody sees stderr

// factoria_player.exe is a GUI program (player/CMakeLists.txt), so a game opens no console window. Started from a
// terminal, it still prints there: an output the terminal did not redirect is pointed at the terminal's console.
// (The terminal does not wait for a GUI program; `start /wait game.exe` does.)
void attach_parent_console() {
    const bool outOk = GetFileType(GetStdHandle(STD_OUTPUT_HANDLE)) != FILE_TYPE_UNKNOWN;
    const bool errOk = GetFileType(GetStdHandle(STD_ERROR_HANDLE)) != FILE_TYPE_UNKNOWN;
    if (outOk && errOk) return;  // redirected
    if (!AttachConsole(ATTACH_PARENT_PROCESS)) {
        g_noConsole = !errOk;
        return;
    }
    FILE* f = nullptr;
    if (!outOk) freopen_s(&f, "CONOUT$", "w", stdout);
    if (!errOk) freopen_s(&f, "CONOUT$", "w", stderr);
}
#endif

// An error before the game starts (there is no log file yet): on stderr, and in a message box when nobody sees stderr.
int startup_error(const std::string& text) {
    std::fprintf(stderr, "%s", text.c_str());
#if defined(_WIN32)
    if (g_noConsole) MessageBoxA(nullptr, text.c_str(), "Cannot start the game", MB_OK | MB_ICONERROR);
#endif
    return 1;
}

void print_usage() {
    std::puts("factoria_player [projectDir | game.pak] [--scene <scene path>] [--fullscreen] [--frames N]\n"
              "                [--input <replay.json>] [--dump-state <file>] [--screenshot <file>] [--version] [--help]\n"
              "  projectDir  folder containing factoria.json, or a game.pak (default: ./game next to the executable, else\n"
              "              ./game.pak next to it, else the current directory)\n"
              "  --scene     start scene override, project-relative (e.g. scenes/level2.scene.json)\n"
              "  --fullscreen  start fullscreen (overrides factoria.json display.fullscreen)\n"
              "  --frames N  draw N frames, then exit: 0, or 1 when a script failed (a crash exits non-zero too); for CI smoke tests\n"
              "  --input F   play an input replay (the JSON `input.record` writes, the one `factoria run --input` plays); needs --frames\n"
              "  --dump-state F  write the world state JSON after the last frame (= `factoria run --state-out`); needs --frames\n"
              "  --screenshot F  write a PNG of the last frame (= `factoria run --screenshot-at N-1`); needs --frames\n"
              "              these three run headless (no window, deterministic, fixed time step) like `factoria run --headless\n"
              "              --frames N`, so a shipped build can be checked by script and compared with the editor's run;\n"
              "              exit 0, 1 when a script failed, 2 for a missing or bad file\n"
              "  --version   print the engine version (the one `factoria version` prints) and exit");
}

}  // namespace

int main(int argc, char** argv) {
#if defined(_WIN32)
    attach_parent_console();
#endif
    std::string projectArg, scene;
    bool fullscreen = false;
    int frames = 0;
    std::string inputArg, dumpStateArg, screenshotArg;
    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "--help" || a == "-h") {
            print_usage();
            return 0;
        } else if (a == "--version") {
            std::printf("factoria_player %s (build %s)\n", FA_ENGINE_VERSION, fa::build_fingerprint());
            return 0;
        } else if (a == "--fullscreen") {
            fullscreen = true;
        } else if (a == "--scene") {
            if (i + 1 >= argc) {
                std::fprintf(stderr, "error: --scene needs a value, e.g. --scene scenes/main.scene.json\n");
                return 2;
            }
            scene = argv[++i];
        } else if (a == "--frames" || a.rfind("--frames=", 0) == 0) {
            const std::string value = a == "--frames" ? (i + 1 < argc ? argv[++i] : "") : a.substr(9);
            char* end = nullptr;
            const long n = std::strtol(value.c_str(), &end, 10);
            if (value.empty() || *end != 0 || n < 1 || n > 1000000) {
                std::fprintf(stderr, "error: --frames needs a whole number of frames of at least 1, e.g. --frames 60\n");
                return 2;
            }
            frames = int(n);
        } else if (a.rfind("--scene=", 0) == 0) {
            scene = a.substr(8);
        } else if (a == "--input" || a == "--dump-state" || a == "--screenshot" || a.rfind("--input=", 0) == 0 ||
                   a.rfind("--dump-state=", 0) == 0 || a.rfind("--screenshot=", 0) == 0) {
            const std::size_t eq = a.find('=');
            const std::string name = a.substr(0, eq);
            if (eq == std::string::npos && (i + 1 >= argc || std::string(argv[i + 1]).rfind("--", 0) == 0)) {
                std::fprintf(stderr, "error: %s needs a file, e.g. %s %s\n", name.c_str(), name.c_str(),
                             name == "--input" ? "replay.json" : name == "--dump-state" ? "state.json" : "shot.png");
                return 2;
            }
            const std::string value = eq == std::string::npos ? std::string(argv[++i]) : a.substr(eq + 1);
            if (value.empty()) {
                std::fprintf(stderr, "error: %s needs a file name, got an empty value\n", name.c_str());
                return 2;
            }
            (name == "--input" ? inputArg : name == "--dump-state" ? dumpStateArg : screenshotArg) = value;
        } else if (!a.empty() && a[0] == '-') {
            std::fprintf(stderr, "error: unknown option '%s'\n", a.c_str());
            print_usage();
            return 2;
        } else {
            projectArg = a;
        }
    }

    const bool checkRun = !inputArg.empty() || !dumpStateArg.empty() || !screenshotArg.empty();
    if (checkRun && frames < 1) {
        std::fprintf(stderr,
                     "error: --input, --dump-state and --screenshot run the game headless for a fixed number of frames, so they need "
                     "--frames N.\nhint: e.g. factoria_player --frames 300 --input replay.json --dump-state state.json --screenshot last.png\n");
        return 2;
    }
    // Output and input files are relative to the current directory (not to the game, which may sit inside a pack).
    auto absolute = [](const std::string& p) {
        std::error_code e;
        return stdfs::absolute(p, e).lexically_normal().string();
    };
    std::string inputPath = inputArg.empty() ? std::string() : absolute(inputArg);
    if (!inputArg.empty()) {
        std::error_code e;
        if (!stdfs::is_regular_file(inputPath, e)) {
            std::fprintf(stderr, "error: --input file '%s' does not exist (looked for %s).\nhint: record one with the input.record command "
                                 "(docs/DEBUGGING.md) and pass its path, relative to the current directory.\n",
                         inputArg.c_str(), inputPath.c_str());
            return 2;
        }
    }
    for (const std::string* out : {&dumpStateArg, &screenshotArg}) {
        if (out->empty()) continue;
        std::error_code e;
        const stdfs::path parent = stdfs::path(absolute(*out)).parent_path();
        stdfs::create_directories(parent, e);
        if (e || !stdfs::is_directory(parent, e)) {
            std::fprintf(stderr, "error: cannot write '%s': the folder '%s' does not exist and cannot be created (%s).\n"
                                 "hint: pass a path in a folder you can write to.\n",
                         out->c_str(), parent.string().c_str(), e.message().c_str());
            return 2;
        }
    }

    // An exported game keeps its native plugins next to the executable (Contents/Frameworks in a macOS .app); a game
    // folder passed on the command line uses the plugins' own folders, as `factoria run` does.
    stdfs::path projectDir, pluginDir, packFile;
    std::error_code ec;
    if (!projectArg.empty()) {
        if (stdfs::is_regular_file(projectArg, ec)) {  // factoria_player path/to/game.pak
            packFile = projectArg;
            projectDir = packFile.parent_path() / "game";
            pluginDir = packFile.parent_path();
        } else {
            projectDir = projectArg;
        }
    } else {
        stdfs::path exeDir = executable_dir();
        const stdfs::path resources = exeDir.parent_path() / "Resources";
        if (has_project(exeDir / "game")) {
            projectDir = exeDir / "game";
            pluginDir = exeDir;
        } else if (has_project(resources / "game")) {
            projectDir = resources / "game";
            pluginDir = exeDir.parent_path() / "Frameworks";
        } else if (stdfs::is_regular_file(exeDir / fa::kPackFileName, ec)) {  // a --release export: the whole game in one file
            packFile = exeDir / fa::kPackFileName;
            projectDir = exeDir / "game";
            pluginDir = exeDir;
        } else if (stdfs::is_regular_file(resources / fa::kPackFileName, ec)) {
            packFile = resources / fa::kPackFileName;
            projectDir = resources / "game";
            pluginDir = exeDir.parent_path() / "Frameworks";
        } else {
            projectDir = stdfs::current_path();
        }
    }
    if (!packFile.empty()) {
        // From here on every project-relative read of the engine (factoria.json, scenes, assets, scripts) comes out of the pack.
        if (auto mounted = fa::fs::mount_pack(packFile); !mounted.ok()) return startup_error("error: " + mounted.error().to_string() + "\n");
        fa::fs::set_project_root(projectDir);
    }
    if (packFile.empty() ? !has_project(projectDir) : !fa::fs::exists(fa::kProjectFileName)) {
        return startup_error(std::string("error: no ") + fa::kProjectFileName + " in '" +
                             (packFile.empty() ? projectDir : packFile).string() +
                             "'.\nhint: pass the game folder (factoria_player path/to/game) or a game.pak, or put the game in a 'game' "
                             "folder or a game.pak next to the executable (`factoria export` does this).\n");
    }

    fa::EngineConfig cfg;
    cfg.projectDir = projectDir.string();
    cfg.scene = scene;
    cfg.hotReload = false;
    cfg.maxFrames = frames;
    cfg.pluginDir = pluginDir.generic_string();
    cfg.platformFallback = "none";  // a shipped game never gets the fake store: no free purchases (docs/PLATFORM.md)
    if (auto proj = fa::load_project(cfg.projectDir); proj.ok()) {
        fa::fs::set_user_dir(desktop_user_dir(proj->id));
        log_to_file(fa::fs::user_dir());
        report_crashes_to_file(fa::fs::user_dir(), *proj);
    } else {
        return startup_error("error: " + proj.error().to_string() + "\n");
    }
    if (checkRun) {
        // The same path as `factoria run --headless --frames N` (tools/cli/src/common.cpp apply_headless_config): the same
        // seed, fixed time step, in-memory storage and fake platform, so the state and the pixels equal the CLI's.
        cfg.headless = true;
        cfg.audioDevice = false;
        cfg.renderMode = fa::RenderMode::OnDemand;
        cfg.memoryStorage = true;
        cfg.platformBackend = "fake";
        cfg.maxFrames = 0;
        fa::HeadlessRunOptions ho;
        ho.frames = frames;
        ho.inputReplayPath = inputPath;
        if (!screenshotArg.empty()) {
            ho.screenshotFrames = {frames - 1};
            ho.screenshotPattern = absolute(screenshotArg);
        }
        if (!dumpStateArg.empty()) ho.stateOutPath = absolute(dumpStateArg);
        ho.failOnScriptError = true;
        fa::Json report = fa::Json::object();
        const int code = fa::run_headless(cfg, ho, &report);
        for (const char* key : {"scriptErrors", "sceneErrors"})
            if (report.contains(key) && report[key].is_array())
                for (const auto& e : report[key]) std::fprintf(stderr, "%s: %s\n", key, e.is_string() ? e.get<std::string>().c_str() : e.dump().c_str());
        if (report.contains("problems") && report["problems"].is_array())
            for (const auto& pr : report["problems"])
                std::fprintf(stderr, "warning: %s\n", pr.is_string() ? pr.get<std::string>().c_str() : pr.dump().c_str());
        if (report.contains("error") && report["error"].is_string()) std::fprintf(stderr, "error: %s\n", report["error"].get<std::string>().c_str());
        if (code == 0) std::printf("OK: ran %d frames headless\n", frames);
        if (code == 0 && !screenshotArg.empty() && !stdfs::exists(ho.screenshotPattern, ec))
            std::fprintf(stderr, "warning: no screenshot was written to %s\n", ho.screenshotPattern.c_str());
        return code == 0 ? 0 : (code == 2 ? 2 : 1);
    }
    fa::AppDesc desc = fa::make_app_desc(cfg);  // == what run_windowed() does
    if (fullscreen) desc.fullscreen = true;
    return fa::run_app(desc);
}

#else
// ------------------------------------------------------------------------------------------------
// Mobile: sokol_app owns the process entry point and calls sokol_main().
// ------------------------------------------------------------------------------------------------
#include <memory>

#include "fa/platform/sokol_entry.h"
#include "sokol_gfx.h"
#include "sokol_glue.h"

#if defined(__ANDROID__)
#include <android/native_activity.h>
#else
// Implemented in ios_bundle.mm.
std::string fa_player_ios_game_dir();       // <bundle resource path>/game
std::string fa_player_ios_documents_dir();  // app Documents directory
#endif

namespace {

// Shown when the game cannot start (no project in the app bundle/APK): a red screen plus a log line.
// (No text rendering is available without the engine, so `adb logcat -s FactorIA` / the Xcode console
// carry the explanation.)
std::string g_errorMessage;

void error_init() {
    sg_desc d{};
    d.environment = sglue_environment();
    d.logger.func = fa_sokol_log_func;
    sg_setup(&d);
}
void error_frame() {
    sg_pass pass{};
    pass.action.colors[0].load_action = SG_LOADACTION_CLEAR;
    pass.action.colors[0].clear_value = {0.55f, 0.08f, 0.08f, 1.0f};
    pass.swapchain = sglue_swapchain();
    sg_begin_pass(&pass);
    sg_end_pass();
    sg_commit();
}
void error_cleanup() { sg_shutdown(); }

sapp_desc error_desc(const std::string& message) {
    g_errorMessage = message;
    FA_ERROR("player", "{}", g_errorMessage);
    sapp_desc s{};
    s.init_cb = error_init;
    s.frame_cb = error_frame;
    s.cleanup_cb = error_cleanup;
    s.window_title = "FactorIA error";
    return s;
}

}  // namespace

// sokol_app.h (compiled as C in fa_platform) calls sokol_main with C linkage.
extern "C" sapp_desc sokol_main(int, char*[]) {
    fa::EngineConfig cfg;
    cfg.hotReload = false;
    cfg.platformFallback = "none";  // a shipped game never gets the fake store: no free purchases (docs/PLATFORM.md)
#if defined(__ANDROID__)
    const auto* activity = static_cast<const ANativeActivity*>(sapp_android_get_native_activity());
    if (!activity) return error_desc("Android: sapp_android_get_native_activity() returned null.");
    fa::fs::set_android_asset_manager(activity->assetManager);
    if (activity->internalDataPath) fa::fs::set_user_dir(activity->internalDataPath);
    cfg.projectDir = "";  // the APK assets root
    fa::fs::set_project_root("");
    if (!fa::fs::exists(fa::kProjectFileName))
        return error_desc("No factoria.json in the APK assets. Export with `factoria export --platform android` "
                          "(files must end up in app/src/main/assets/).");
#else
    cfg.projectDir = fa_player_ios_game_dir();
    fa::fs::set_user_dir(fa_player_ios_documents_dir());
    if (!stdfs::exists(stdfs::path(cfg.projectDir) / fa::kProjectFileName))
        return error_desc("No game in the app bundle (expected " + cfg.projectDir +
                          "/factoria.json). Configure with -DFA_GAME_PROJECT_DIR=<game folder> "
                          "(`factoria export --platform ios` does this).");
#endif
    static fa::AppDesc desc;  // to_sapp_desc copies it, keep alive anyway
    desc = fa::make_app_desc(cfg);
    return fa::to_sapp_desc(desc);
}
#endif
