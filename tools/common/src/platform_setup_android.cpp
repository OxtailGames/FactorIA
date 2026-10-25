// What the Android plugin backends (googleplay, admob) share in platform.add_backend: find the Android SDK's NDK, CMake and Ninja, and
// build the plugin's C bridge for arm64-v8a and x86_64 (docs/PLATFORM.md, "Google Play" and "Ads").
#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <functional>

#include "fa/core/strings.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/setup.h"
#include "platform_setup.h"
#include "setup_internal.h"

namespace fa::platform_setup {

namespace stdfs = std::filesystem;

namespace {

constexpr const char* kNdkVersion = "27.2.12479018";  // the NDK of the engine's own Android build (docs/EXPORTING.md)
constexpr const char* kAbis[] = {"arm64-v8a", "x86_64"};
#if defined(_WIN32)
constexpr const char* kExe = ".exe";
#else
constexpr const char* kExe = "";
#endif

using setup_detail::is_dir;
using setup_detail::is_file;

std::vector<int> version_parts(const std::string& v) {
    std::vector<int> parts;
    for (const std::string& p : split(v, '.')) parts.push_back(std::atoi(p.c_str()));
    return parts;
}

// The folder under `parent` to use: `pinned` when it is valid, else the newest valid one; "" when none is.
std::string pick_version(const stdfs::path& parent, const std::string& pinned, const std::function<bool(const stdfs::path&)>& valid) {
    std::vector<std::string> versions;
    std::error_code ec;
    if (is_dir(parent))
        for (const auto& e : stdfs::directory_iterator(parent, ec))
            if (e.is_directory(ec) && valid(e.path())) versions.push_back(e.path().filename().string());
    if (versions.empty()) return {};
    if (std::find(versions.begin(), versions.end(), pinned) != versions.end()) return pinned;
    return *std::max_element(versions.begin(), versions.end(), [](const std::string& a, const std::string& b) {
        return version_parts(a) < version_parts(b);
    });
}

std::string install_help(const std::string& backend) {
    return "Install them once: `sdkmanager \"ndk;27.2.12479018\" \"cmake;3.31.6\"` (the sdkmanager is in cmdline-tools/<revision>/bin of the SDK; "
           "Android Studio: Settings > Languages & Frameworks > Android SDK > SDK Tools > NDK (Side by side) and CMake). If there is no Android SDK at all, "
           "`factoria setup android` installs one. Or pass \"" + backend + "Build\": false to only write the plugin and declare it, and build it where the NDK is "
           "(for each ABI: cmake -S plugins/" + backend + " -B plugins/" + backend + "/build-<abi> -G Ninja -DCMAKE_BUILD_TYPE=Release "
           "-DCMAKE_TOOLCHAIN_FILE=<sdk>/ndk/27.2.12479018/build/cmake/android.toolchain.cmake -DANDROID_ABI=<abi> -DANDROID_PLATFORM=android-26 "
           "&& cmake --build plugins/" + backend + "/build-<abi>), or let the CI of the game do it.";
}

}  // namespace

NdkToolchain find_ndk_toolchain(const AndroidToolchainSearch& search, const std::string& backend, const std::string& display) {
    const ExportEnvLookup env = search.env ? search.env : system_export_env();
    MachineExportConfig config;
    if (auto machine = load_machine_export_config(machine_export_config_path(env)); machine.ok()) config = std::move(machine.value());
    const AndroidToolchain found = find_android_toolchain(config, search);
    const stdfs::path sdk(found.sdk);
    // find_android_toolchain also reports JDK problems, which a native build does not care about: judge the SDK folder itself.
    if (found.sdk.empty() || !(is_dir(sdk / "platform-tools") || is_dir(sdk / "platforms") || is_dir(sdk / "licenses")))
        throw CommandError("unavailable", "cannot build " + display + ": no Android SDK was found on this computer (it needs the SDK's NDK, CMake and Ninja)",
                           install_help(backend));

    NdkToolchain t;
    t.sdk = sdk.generic_string();
    const std::string ndk = pick_version(sdk / "ndk", kNdkVersion, [](const stdfs::path& p) {
        return is_file(p / "build" / "cmake" / "android.toolchain.cmake");
    });
    if (ndk.empty())
        throw CommandError("unavailable", "cannot build " + display + ": the Android SDK at '" + t.sdk + "' has no NDK (no ndk/<version>/build/cmake/android.toolchain.cmake)",
                           install_help(backend));
    t.ndk = (sdk / "ndk" / ndk).generic_string();
    t.toolchainFile = t.ndk + "/build/cmake/android.toolchain.cmake";
    if (ndk != kNdkVersion)
        t.notes.push_back(std::string("used NDK ") + ndk + " because the pinned " + kNdkVersion + " is not installed (sdkmanager \"ndk;" + kNdkVersion + "\")");

    const std::string cmake = pick_version(sdk / "cmake", kSetupCmakeVersion, [](const stdfs::path& p) {
        return is_file(p / "bin" / (std::string("cmake") + kExe)) && is_file(p / "bin" / (std::string("ninja") + kExe));
    });
    if (cmake.empty())
        throw CommandError("unavailable", "cannot build " + display + ": the Android SDK at '" + t.sdk + "' has no CMake with Ninja (no cmake/<version>/bin/cmake and ninja)",
                           install_help(backend));
    t.cmake = (sdk / "cmake" / cmake / "bin" / (std::string("cmake") + kExe)).generic_string();
    t.ninja = (sdk / "cmake" / cmake / "bin" / (std::string("ninja") + kExe)).generic_string();
    if (cmake != kSetupCmakeVersion)
        t.notes.push_back("used CMake " + cmake + " because the pinned " + kSetupCmakeVersion + " is not installed (sdkmanager \"cmake;" + kSetupCmakeVersion + "\")");
    return t;
}

void build_android_abis(Context& ctx, const NdkToolchain& tc, const std::string& folder) {
    if (ctx.dryRun) {
        ctx.done.push_back("would build the C bridge for arm64-v8a and x86_64 with the NDK in " + tc.ndk);
        return;
    }
    int minSdk = 26;
    if (auto settings = load_export_settings(ctx.projectDir); settings.ok()) minSdk = settings->android.minSdk;
    ctx.cmakeExe = tc.cmake;
    Json libraries = Json::array();
    for (const char* abi : kAbis) {
        const std::string dir = folder + "/build-" + abi;
        ctx.run_cmake({"-S", folder, "-B", dir, "-G", "Ninja", "-DCMAKE_MAKE_PROGRAM=" + tc.ninja, "-DCMAKE_BUILD_TYPE=Release",
                       "-DCMAKE_TOOLCHAIN_FILE=" + tc.toolchainFile, std::string("-DANDROID_ABI=") + abi,
                       "-DANDROID_PLATFORM=android-" + std::to_string(minSdk)},
                      "configure the " + ctx.backend + " plugin for " + abi);
        ctx.run_cmake({"--build", dir}, "build the " + ctx.backend + " plugin for " + abi);
        const std::string rel = std::string("android/src/main/jniLibs/") + abi + "/lib" + ctx.backend + ".so";
        if (!is_file(stdfs::path(folder) / rel))
            throw CommandError("failed", "the build of the " + ctx.backend + " plugin left no " + folder + "/" + rel,
                               "Look at the plugin's CMake output above; `cmake --build " + dir + "` repeats the build.");
        libraries.push_back(rel);
    }
    ctx.extra["libraries"] = libraries;
    ctx.done.push_back("built the C bridge for arm64-v8a and x86_64 with the NDK in " + tc.ndk + ": " + libraries.dump());
    for (const std::string& note : tc.notes) ctx.done.push_back(note);
}

}  // namespace fa::platform_setup
