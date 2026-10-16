// Loads the Steamworks redistributable and starts Steam. The platform-specific code is the few lines at the top (dlopen or
// LoadLibrary, the folder of this plugin's library); the rest is shared.
#include "steam_loader.h"

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <system_error>
#include <vector>

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#else
#include <dlfcn.h>
#include <limits.h>
#include <stdlib.h>
#endif

namespace steam_plugin {

namespace stdfs = std::filesystem;

namespace {

// ---------------------------------------------------------------------------------------- per-platform primitives --
#if defined(_WIN32)
const char* const kLibraryFile = "steam_api64.dll";
const char* const kSdkFile = "redistributable_bin/win64/steam_api64.dll";
using Handle = HMODULE;
#elif defined(__APPLE__)
const char* const kLibraryFile = "libsteam_api.dylib";
const char* const kSdkFile = "redistributable_bin/osx/libsteam_api.dylib";
using Handle = void*;
#else
const char* const kLibraryFile = "libsteam_api.so";
const char* const kSdkFile = "redistributable_bin/linux64/libsteam_api.so";
using Handle = void*;
#endif

void anchor() {}  // its address says which library this code is in

// The folder of this plugin's library ("" when the system does not say).
stdfs::path plugin_directory() {
#if defined(_WIN32)
    HMODULE module = nullptr;
    if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                            reinterpret_cast<LPCWSTR>(&anchor), &module))
        return {};
    std::wstring buffer(MAX_PATH, L'\0');
    for (;;) {
        const DWORD n = GetModuleFileNameW(module, &buffer[0], static_cast<DWORD>(buffer.size()));
        if (n == 0) return {};
        if (n < buffer.size()) {
            buffer.resize(n);
            break;
        }
        buffer.resize(buffer.size() * 2);
    }
    return stdfs::path(buffer).parent_path();
#else
    Dl_info info{};
    if (!dladdr(reinterpret_cast<void*>(&anchor), &info) || !info.dli_fname) return {};
    char resolved[PATH_MAX];
    const char* file = realpath(info.dli_fname, resolved) ? resolved : info.dli_fname;
    return stdfs::path(file).parent_path();
#endif
}

// Opens `file` (a full path, or the bare file name for the system's search); `why` says what failed.
Handle open_library(const stdfs::path& file, bool fullPath, std::string& why) {
#if defined(_WIN32)
    HMODULE h = LoadLibraryExW(file.c_str(), nullptr, fullPath ? LOAD_WITH_ALTERED_SEARCH_PATH : 0);
    if (!h) why = std::system_category().message(static_cast<int>(GetLastError()));
    return h;
#else
    (void)fullPath;
    void* h = dlopen(file.c_str(), RTLD_NOW | RTLD_LOCAL);
    if (!h) {
        const char* e = dlerror();
        why = e ? e : "unknown error";
    }
    return h;
#endif
}

void* symbol(Handle h, const char* name) {
#if defined(_WIN32)
    return reinterpret_cast<void*>(GetProcAddress(h, name));
#else
    return dlsym(h, name);
#endif
}

bool set_environment(const char* name, const std::string& value) {
#if defined(_WIN32)
    // Both: the Win32 block (what Steam's own DLL reads) and this plugin's C runtime copy of it.
    const bool win32 = SetEnvironmentVariableA(name, value.c_str()) != 0;
    return _putenv_s(name, value.c_str()) == 0 && win32;
#else
    return setenv(name, value.c_str(), 1) == 0;
#endif
}

bool environment_set(const char* name) {
#if defined(_WIN32)
    char buffer[8];
    return GetEnvironmentVariableA(name, buffer, sizeof buffer) > 0;
#else
    const char* v = std::getenv(name);
    return v && *v;
#endif
}

// ---------------------------------------------------------------------------------------------------- the app id --
// The number in a steam_appid.txt, or "".
std::string read_app_id(const stdfs::path& file) {
    std::error_code ec;
    if (!stdfs::is_regular_file(file, ec)) return {};
    std::ifstream in(file, std::ios::binary);
    const std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    std::string number;
    for (char c : text) {
        if (c >= '0' && c <= '9') number += c;
        else if (!number.empty() || (c != ' ' && c != '\t' && c != '\r' && c != '\n' && c != '\xEF' && c != '\xBB' && c != '\xBF')) break;
    }
    return number;
}

// A game started by Steam has SteamAppId in its environment. In development there is none: the app id comes from a
// steam_appid.txt, which Steam itself looks for next to the executable (here that is `factoria`, not the project), so the
// plugin looks in the folder it was started in and in the project folder (the first parent of this library that holds a
// factoria.json) and hands the number to Steam through the same variables Steam sets. Returns where the id came from.
std::string prepare_app_id() {
    if (environment_set("SteamAppId") || environment_set("SteamGameId")) return "the SteamAppId environment variable";
    std::vector<stdfs::path> folders;
    std::error_code ec;
    folders.push_back(stdfs::current_path(ec));
    stdfs::path dir = plugin_directory();
    for (int up = 0; !dir.empty() && up < 8; ++up, dir = dir.parent_path()) {
        if (stdfs::exists(dir / "factoria.json", ec)) {
            folders.push_back(dir);
            break;
        }
        if (dir == dir.parent_path()) break;
    }
    for (const stdfs::path& folder : folders) {
        const std::string id = read_app_id(folder / "steam_appid.txt");
        if (id.empty()) continue;
        set_environment("SteamAppId", id);
        set_environment("SteamGameId", id);
        return "steam_appid.txt in " + folder.generic_string() + " (app id " + id + ")";
    }
    return {};
}

struct AccessorSpec {
    const char* label;
    void* SteamApi::*field;
    std::vector<const char*> names;  // newest first
};

const std::vector<AccessorSpec>& accessor_specs() {
    static const std::vector<AccessorSpec> specs = {
#define STEAM_SPEC(field, iface, ...) {iface, &SteamApi::field, {__VA_ARGS__}},
        STEAM_ACCESSORS(STEAM_SPEC)
#undef STEAM_SPEC
    };
    return specs;
}

std::string join_names(const std::vector<const char*>& names) {
    std::string out;
    for (const char* n : names) out += (out.empty() ? "" : ", ") + std::string(n);
    return out;
}

std::string init_failure(const SteamApi& api, int result, const char* sdkMessage) {
    std::string out = "Steam did not start";
    if (sdkMessage && *sdkMessage) out += std::string(" (") + sdkMessage + ")";
    out += ". ";
    if (result == kInitVersionMismatch) {
        out += "The Steam client is older than the Steamworks library next to the plugin: update Steam (Steam menu > Check for "
               "Steam Client Updates), or use the redistributable of an older SDK. ";
    } else {
        const bool known = api.SteamAPI_IsSteamRunning != nullptr;
        const bool running = known && api.SteamAPI_IsSteamRunning();
        out += known && !running ? "Steam is not running, or the game has no app id. "
                                 : "Steam is not running, or the game has no app id (or this account does not own it). ";
        out += api.appIdSource.empty() ? "No app id was found: there is no SteamAppId variable and no steam_appid.txt in the folder "
                                         "the game started in or in the project folder. "
                                       : "The app id came from " + api.appIdSource + ". ";
    }
    out += how_to_start_steam() + " The game runs without Steam's services (the fake platform backend in development, none in an "
                                  "exported game).";
    return out;
}

}  // namespace

std::string how_to_start_steam() {
    return "Start the Steam client and sign in. For development, put a steam_appid.txt holding 480 (Valve's test app, which "
           "any Steam account can run) in the project folder: `factoria call platform.add_backend '{\"backend\": \"steam\"}'` "
           "writes it. A game exported for Steam gets its app id from Steam when it is started from the Steam client, "
           "and must not ship a steam_appid.txt.";
}

// -------------------------------------------------------------------------------------------------------- loading --
bool load_library(SteamApi& api, std::string& error) {
    const stdfs::path folder = plugin_directory();
    std::error_code ec;
    Handle handle = nullptr;
    std::string why;
    if (!folder.empty() && stdfs::is_regular_file(folder / kLibraryFile, ec)) {
        api.library = (folder / kLibraryFile).generic_string();
        handle = open_library(folder / kLibraryFile, true, why);
        if (!handle) {
            error = std::string("The Steamworks library ") + api.library + " cannot be loaded: " + why +
                    ". It must be the 64-bit build for this operating system and CPU from the Steamworks SDK (" + kSdkFile +
                    "), not a file from another platform or a damaged copy. Copy it again, or run `factoria call "
                    "platform.add_backend '{\"backend\": \"steam\", \"sdk\": \"<Steamworks SDK folder>\"}'`.";
            return false;
        }
    } else {
        api.library = kLibraryFile;
        handle = open_library(kLibraryFile, false, why);
        if (!handle) {
            const std::string tried = folder.empty() ? std::string("the system's library path")
                                                     : folder.generic_string() + " and the system's library path";
            error = std::string("The Steamworks library ") + kLibraryFile + " was not found (looked in " + tried +
                    "). Valve's files are not part of FactorIA: download the Steamworks SDK (partner.steamgames.com/downloads/list, "
                    "needs a free Steamworks account) and copy " + kSdkFile + " next to this plugin" +
                    (folder.empty() ? std::string() : " (into " + folder.generic_string() + ")") +
                    ", or run `factoria call platform.add_backend '{\"backend\": \"steam\", \"sdk\": \"<Steamworks SDK folder or "
                    ".zip>\"}'` to do it. Without it the game uses the fake platform backend in development and has no platform "
                    "services in an exported game.";
            return false;
        }
    }
    api.module = handle;

    std::vector<std::string> missing;
#define STEAM_LOOKUP_REQUIRED(name, ret, params)                       \
    api.name = reinterpret_cast<ret(*) params>(symbol(handle, #name)); \
    if (!api.name) missing.push_back(#name);
    STEAM_REQUIRED_FUNCTIONS(STEAM_LOOKUP_REQUIRED)
#undef STEAM_LOOKUP_REQUIRED
#define STEAM_LOOKUP_OPTIONAL(name, ret, params) api.name = reinterpret_cast<ret(*) params>(symbol(handle, #name));
    STEAM_OPTIONAL_FUNCTIONS(STEAM_LOOKUP_OPTIONAL)
#undef STEAM_LOOKUP_OPTIONAL
    if (!missing.empty()) {
        error = api.library + " does not export " + missing[0] +
                (missing.size() > 1 ? " (and " + std::to_string(missing.size() - 1) + " more)" : std::string()) +
                ": it is not a Steamworks library this plugin can use. The plugin was checked against the flat API of the " +
                kSupportedSdk + "; copy the redistributable of one of those SDKs next to the plugin.";
        return false;
    }
    if (!api.SteamAPI_InitFlat && !api.SteamAPI_Init) {
        error = api.library + " exports neither SteamAPI_InitFlat nor SteamAPI_Init: it is not a Steamworks library. Use the " +
                std::string(kSupportedSdk) + " redistributable.";
        return false;
    }

    // The interfaces are looked up after Steam started (start_steam), but their accessors are checked now: a library of an SDK
    // this plugin does not know is refused before it is started.
    std::string absent;
    for (const AccessorSpec& spec : accessor_specs()) {
        bool found = false;
        for (const char* name : spec.names) found = found || symbol(handle, name) != nullptr;
        if (!found) absent += (absent.empty() ? "" : "; ") + std::string(spec.label) + " (" + join_names(spec.names) + ")";
    }
    if (!absent.empty()) {
        error = api.library + " has none of the interface accessors this plugin knows: " + absent + ". This plugin supports the " +
                kSupportedSdk + "; this library is from a newer or an older SDK. Copy the redistributable of a supported SDK next "
                "to the plugin, or update the plugin from the engine's template (a new `factoria call project.new_plugin` with "
                "\"template\": \"steam\" in another folder, then compare).";
        return false;
    }
    return true;
}

bool start_steam(SteamApi& api, std::string& error) {
    api.appIdSource = prepare_app_id();
    if (api.SteamAPI_InitFlat) {
        char message[1024] = {0};  // k_cchMaxSteamErrMsg
        const int result = api.SteamAPI_InitFlat(message);
        if (result != kInitOk) {
            error = init_failure(api, result, message);
            return false;
        }
    } else if (!api.SteamAPI_Init()) {
        error = init_failure(api, kInitFailedGeneric, "");
        return false;
    }
    // "ManualDispatch_Init: must be called after SteamAPI_Init, but before you use any of the other manual dispatch functions"
    // (steam_api.h). From here on the plugin pumps callbacks itself; SteamAPI_RunCallbacks must never be called.
    api.SteamAPI_ManualDispatch_Init();
    api.pipe = api.SteamAPI_GetHSteamPipe();

    const Handle handle = static_cast<Handle>(api.module);
    std::string failed;
    for (const AccessorSpec& spec : accessor_specs()) {
        void* (*accessor)() = nullptr;
        std::string used;
        for (const char* name : spec.names) {
            if (accessor) break;
            accessor = reinterpret_cast<void* (*)()>(symbol(handle, name));
            used = name;
        }
        api.*spec.field = accessor ? accessor() : nullptr;
        if (!(api.*spec.field)) {
            failed += (failed.empty() ? "" : ", ") + std::string(spec.label);
            continue;
        }
        api.accessors += (api.accessors.empty() ? "" : ", ") + std::string(spec.label) + " " + used.substr(used.rfind('_') + 1);
    }
    if (!failed.empty()) {
        api.SteamAPI_Shutdown();
        error = "Steam started, but the library returned no interface for " + failed + ": it does not match the client. Update "
                "Steam, or use the redistributable of a supported SDK (" + kSupportedSdk + ").";
        return false;
    }
    api.needsStatsRequest = api.SteamAPI_ISteamUserStats_RequestCurrentStats != nullptr;
    return true;
}

}  // namespace steam_plugin
