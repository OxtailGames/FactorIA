// factoria_player: the minimal runtime shipped inside exported games.
//
//   Desktop : factoria_player [projectDir] [--scene S] [--fullscreen] [--help]
//             projectDir defaults to "<exe dir>/game" (or "<exe dir>/../Resources/game" inside a macOS
//             .app) when that folder contains factoria.json, otherwise the current directory.
//             The log of every run also goes to <save folder>/log.txt. On Windows the player is a GUI program (no
//             console window); started from a terminal it prints to that terminal.
//   Android : sokol_main() via NativeActivity. The project lives in the APK assets (root "").
//   iOS     : sokol_main(). The project lives in the app bundle at <bundle resources>/game.
//
// Mobile entry points are UNTESTED on the Linux development machine (CI builds them).
#include <filesystem>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/log.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif
#if defined(__ANDROID__) || (defined(__APPLE__) && TARGET_OS_IPHONE)
#define FA_PLAYER_MOBILE 1
#endif

namespace stdfs = std::filesystem;

#if !defined(FA_PLAYER_MOBILE)
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
    std::puts("factoria_player [projectDir] [--scene <scene path>] [--fullscreen] [--help]\n"
              "  projectDir  folder containing factoria.json (default: ./game next to the executable, else the current directory)\n"
              "  --scene     start scene override, project-relative (e.g. scenes/level2.scene.json)\n"
              "  --fullscreen  start fullscreen (overrides factoria.json display.fullscreen)");
}

}  // namespace

int main(int argc, char** argv) {
#if defined(_WIN32)
    attach_parent_console();
#endif
    std::string projectArg, scene;
    bool fullscreen = false;
    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "--help" || a == "-h") {
            print_usage();
            return 0;
        } else if (a == "--fullscreen") {
            fullscreen = true;
        } else if (a == "--scene") {
            if (i + 1 >= argc) {
                std::fprintf(stderr, "error: --scene needs a value, e.g. --scene scenes/main.scene.json\n");
                return 2;
            }
            scene = argv[++i];
        } else if (a.rfind("--scene=", 0) == 0) {
            scene = a.substr(8);
        } else if (!a.empty() && a[0] == '-') {
            std::fprintf(stderr, "error: unknown option '%s'\n", a.c_str());
            print_usage();
            return 2;
        } else {
            projectArg = a;
        }
    }

    // An exported game keeps its native plugins next to the executable (Contents/Frameworks in a macOS .app); a game
    // folder passed on the command line uses the plugins' own folders, as `factoria run` does.
    stdfs::path projectDir, pluginDir;
    if (!projectArg.empty()) {
        projectDir = projectArg;
    } else {
        stdfs::path exeDir = executable_dir();
        if (has_project(exeDir / "game")) {
            projectDir = exeDir / "game";
            pluginDir = exeDir;
        } else if (has_project(exeDir.parent_path() / "Resources" / "game")) {
            projectDir = exeDir.parent_path() / "Resources" / "game";
            pluginDir = exeDir.parent_path() / "Frameworks";
        } else {
            projectDir = stdfs::current_path();
        }
    }
    if (!has_project(projectDir)) {
        return startup_error(std::string("error: no ") + fa::kProjectFileName + " in '" + projectDir.string() +
                             "'.\nhint: pass the game folder (factoria_player path/to/game) or put the game in a 'game' folder "
                             "next to the executable (`factoria export` does this).\n");
    }

    fa::EngineConfig cfg;
    cfg.projectDir = projectDir.string();
    cfg.scene = scene;
    cfg.hotReload = false;
    cfg.pluginDir = pluginDir.generic_string();
    cfg.platformFallback = "none";  // a shipped game never gets the fake store: no free purchases (docs/PLATFORM.md)
    if (auto proj = fa::load_project(cfg.projectDir); proj.ok()) {
        fa::fs::set_user_dir(desktop_user_dir(proj->id));
        log_to_file(fa::fs::user_dir());
    } else {
        return startup_error("error: " + proj.error().to_string() + "\n");
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
