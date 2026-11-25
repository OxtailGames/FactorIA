// One-click setup of everything an export needs: `factoria setup`, commands "setup.status" and "setup.install".
//
// FactorIA never only tells the user what to install when it can install it. The components:
//   android   JDK 21 (Eclipse Temurin) + the Android SDK (the command-line tools revision pinned below, platform-tools,
//             platform 36, build-tools 35.0.0) with its license accepted: what `factoria export --platform android` builds an
//             APK/AAB with.
//   players   the factoria_player of the other desktop OSes and the prebuilt mobile libraries, from the GitHub release of
//             this factoria's version: what `factoria export --platform windows|linux|macos` (for another OS) and the
//             prebuilt Android/iOS exports copy into the game.
//   webplayer the web player built from the checkout this factoria was built from (Emscripten, preset web-release), for a
//             development build that has no release to take players from.
//   cmake     CMake 3.24+ for the iOS export's build_ios.sh (macOS).
//   xcode     status and guidance only (macOS): a program cannot install Xcode; install opens its App Store page.
//   appimage  appimagetool and the AppImage runtime (Linux x86_64 only): what `factoria export --platform linux --format
//             appimage` builds an AppImage with. Pinned releases, checked against SHA-256 values kept in this file.
//   launcher  the app that opens the editor with the FactorIA icon (macOS ~/Applications/FactorIA.app, Linux a .desktop
//             entry): written from the binary, outside factoria_home() like the VS Code extension.
// Everything lands under factoria_home() (`$FACTORIA_HOME`, else ~/.factoria) and nothing outside it except the
// machine config (~/.factoria/export.json, fa/tooling/export_settings.h) that learns where the JDK and SDK are. Every
// download is verified against the checksum its publisher lists; an archive is unpacked next to its destination and
// moved into place, so a half-finished install never looks installed. docs/EXPORTING.md ("Setting up this computer").
//
// The Android SDK license must be accepted by a human: the install refuses (code "license_required") until
// `acceptLicenses` is set, and the text to show is in the status of the component. Once it is set, the install records
// exactly that one license (the line `sdkmanager --licenses` would write for it, see sdk_license_hash), nothing more.
//
// Downloads and child processes go through SetupContext::download and ::run, so tests (and embedders) replace them;
// the defaults are the `curl` executable and fa::run_process.
#pragma once

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/core/types.h"
#include "fa/tooling/export_settings.h"

namespace fa {

// What `setup` installs (changing one needs the matching docs/EXPORTING.md text updated).
inline constexpr int kSetupJdkMajor = 21;  // the JDK that is downloaded
inline constexpr const char* kSetupAndroidPlatformTools = "platform-tools";
inline constexpr const char* kSetupAndroidPlatform = "platforms;android-36";  // = the default targetSdk
inline constexpr const char* kSetupAndroidBuildTools = "build-tools;35.0.0";  // the Android Gradle plugin's default
inline constexpr const char* kSetupAndroidLicenseId = "android-sdk-license";
// The Android command-line tools: a PINNED revision of the classic, Java-based sdkmanager, not `cmdline-tools;latest`. Revision 23
// (2026) turned sdkmanager into a shell script in front of Google's "Android CLI": it unpacks a ~250 MB copy of itself into
// $ANDROID_USER_HOME on first use, shows Google's terms and sends Google usage statistics, and has no switch to turn that off.
// 22.0 is the newest revision whose bin/sdkmanager still launches com.android.sdklib.tool.sdkmanager.SdkManagerCli from lib/*.jar
// (its bin/android is never called by it). Raising this means checking that again, and the text of docs/EXPORTING.md.
inline constexpr const char* kSetupAndroidCmdlineTools = "cmdline-tools;22.0";
// What is installed instead when Google's listing no longer offers the pinned package (missing or obsolete): the Android CLI front.
inline constexpr const char* kSetupAndroidCmdlineToolsFallback = "cmdline-tools;latest";
// The Emscripten SDK the web player is built with (`setup webplayer` fetches it when none is found): the version of CI and the
// releases (docs/design/BUILDING.md, "Web"; a test keeps them equal).
inline constexpr const char* kSetupEmscriptenVersion = "6.0.10";
inline constexpr const char* kSetupCmakeVersion = "3.31.6";
inline constexpr const char* kSetupCmakeMinimum = "3.24";  // what the engine and build_ios.sh need
// The AppImage tools: the same releases and hashes as scripts/package-appimage.sh (a test keeps the two equal). To upgrade,
// change the script and these four together.
inline constexpr const char* kSetupAppimagetoolVersion = "1.9.1";
inline constexpr const char* kSetupAppimagetoolSha256 =
    "ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0";
inline constexpr const char* kSetupAppImageRuntimeVersion =
    "20251108";  // github.com/AppImage/type2-runtime release tag
inline constexpr const char* kSetupAppImageRuntimeSha256 =
    "2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d";
// sokol-shdc, the shader cross-compiler of custom materials (docs/design/CUSTOM_SHADERS.md): a pinned commit of
// github.com/floooh/sokol-tools-bin (it has no release tags) and the SHA-256 of bin/<dir>/sokol-shdc[.exe] per host.
// tools/shaders/compile_shaders.sh uses the same pin (a test keeps them equal); the generated code must match
// external/sokol/sokol_gfx.h, so a sokol update moves this pin, the script and the committed headers together. This commit
// already writes `spirv_vk` (M77: SPIR-V for the Vulkan backend), so adding that dialect did not move it.
inline constexpr const char* kSetupSokolShdcCommit = "b975d5642093d62e76a1e088bdae945d6d8b8ff2";
struct SokolShdcBinary {
    const char* host;  // "windows" | "linux" | "macos" (SetupContext::host_os)
    const char* arch;  // "x64" | "aarch64" | "" (any: the Windows x64 binary also runs on Windows on Arm)
    const char* dir;   // bin/<dir>/ in sokol-tools-bin
    const char* sha256;
};
inline constexpr SokolShdcBinary kSetupSokolShdcBinaries[] = {
    {"windows", "", "win32", "43d42c2e477bcc5012420f8d9ff641fedc41d552d165397fff4f2e60ba0d2ebb"},
    {"linux", "x64", "linux", "f227db5b282dcaa8085796ba83cda217d3114cf34913ca6ba4b0103f25ccc779"},
    {"linux", "aarch64", "linux_arm64", "c31155b7d340cd561b6fac8d8580c2377abd9140b25d7403c085cb1e700cea14"},
    {"macos", "x64", "osx", "67e5c841a4ca58488e6592560dd8795c7b232a8805d2350ca346028541716252"},
    {"macos", "aarch64", "osx_arm64", "2a807d62dffcc67a50a6ab51df57cde2fc8b23a3daf6207177d79e00fbd4086b"},
};

// ffmpeg, which `factoria run --record-video x.mp4` turns its recording into H.264 + AAC with: the static builds of
// github.com/eugeneware/ffmpeg-static (release tag kSetupFfmpegRelease, ffmpeg 6.0, GPL builds with libx264 and aac), one gzip
// file per host, checked against the SHA-256 listed here. Installed to <home>/tools/ffmpeg/<release>/ffmpeg[.exe].
inline constexpr const char* kSetupFfmpegRelease = "b6.0";
struct FfmpegBinary {
    const char* host;    // "windows" | "linux" | "macos" (SetupContext::host_os)
    const char* arch;    // "x64" | "aarch64" | "" (any: the Windows x64 build also runs on Windows on Arm)
    const char* asset;   // the name in the release: ffmpeg-<asset>.gz
    const char* sha256;  // of that .gz
    int sizeMb;          // the download
};
inline constexpr FfmpegBinary kSetupFfmpegBinaries[] = {
    {"windows", "", "win32-x64", "450d66226c79405c724e821f291cab0911e934bfa9fa2231adcab587f3e07b50", 28},
    {"linux", "x64", "linux-x64", "17c1ae10b52ac499180679fe6ba77e17642390c4eedb0f1e3b0ac045da55128f", 28},
    {"linux", "aarch64", "linux-arm64", "2b708b2d15041d2a192c1db24c7a8a1d24f645a8242dce1c744ff2392b86ada1", 24},
    {"macos", "x64", "darwin-x64", "a12354fce7eb62361473bbe10d53a1893695babd35869ec8e92e5dfea8d0440b", 24},
    {"macos", "aarch64", "darwin-arm64", "6be74d6f449889c2e87a75873894f8520cad56c08ac76f2a628d85b0519daaca", 19},
};

// DirectStorage, the Microsoft runtime a Windows game reads the gdeflate blocks of game.pak with
// (docs/design/ARCHITECTURE_FILES.md, "DirectStorage"): the NuGet package Microsoft.Direct3D.DirectStorage at
// `version`, checked against the SHA-256 of its .nupkg. `setup directstorage` keeps its two redistributable x64 DLLs
// (kSetupDirectStorageFiles) in <home>/tools/directstorage/<version>/ on any host; a Windows release export with
// export.pack.directStorage copies them next to the game.
struct DirectStoragePackage {
    const char* version;
    const char* sha256;  // of the .nupkg
    int sizeMb;          // the download
};
inline constexpr DirectStoragePackage kSetupDirectStorage = {
    "1.3.0", "8ab6c1082537565388b79050d94fdd7f5f437cd0f1d909e7b19f786042b97177", 3};
inline constexpr const char* kSetupDirectStorageFiles[] = {"dstorage.dll", "dstoragecore.dll"};

// Vendor SDKs (M78, docs/exporting/EXPORTING_SETUP.md, "Vendor SDK licences"): the redistributable x64 Windows DLLs a
// game ships with to use a vendor's upscaler, frame generation or latency library: `setup streamline` (NVIDIA Streamline:
// DLSS, DLSS Ray Reconstruction, DLSS Frame Generation, Reflex), `setup xess` (Intel XeSS, XeSS-FG, XeLL) and `setup
// fidelityfx` (AMD FidelityFX: FSR upscaler and frame generation, DX12 and Vulkan). Nothing of them is part of FactorIA:
// the install downloads the vendor's own release, checks it against the SHA-256 pinned here (no vendor publishes
// checksums: FactorIA's maintainers downloaded each file once and pinned its hash), and keeps only the files listed in
// the table in <home>/tools/<id>/<version>/ (the DLLs flat, the license texts beside them), removing older versions. Only the
// listed entries are unpacked from a release archive (the whole Streamline zip is 500 MB in 500 files, some of them deep
// enough to pass Windows' MAX_PATH). Every file of the table is pinned, so a damaged install is found before an export copies it
// (verify_installed_vendor_sdk). Any
// host can install them: the DLLs are copied by a Windows export (export.pack.vendorSdks), never run here. Every one
// comes with a license the user must read and accept first (SetupInstallOptions::acceptLicenses; code `license_required`).
// Never in the tables: the Streamline performance-profiling files (sl.nvperf.dll, sl_nvperf.h; a separate, non
// redistributable Nsight Perf SDK license), the development (unsigned) builds, the denoiser and radiance-cache DLLs.
struct VendorSdkFile {
    const char* src;  // inside the archive; with no archive: the path under VendorSdk::baseUrl
    const char* dst;  // the name in the install folder; nullptr = the file name of src
    const char*
        sha256;  // of this file, always: checked when it is downloaded alone or unpacked, and again before an export copies it
};
struct VendorSdk {
    const char* id;             // "streamline" | "xess" | "fidelityfx": the component and export.pack.vendorSdks name
    const char* title;          // "NVIDIA Streamline (DLSS, DLSS-G, Reflex)"
    const char* version;        // the folder name under <home>/tools/<id>/ and what the status reports
    const char* archiveUrl;     // the release .zip; "" = every file is downloaded on its own from baseUrl
    const char* archiveSha256;  // of the archive
    const char* baseUrl;        // no archive: baseUrl + "/" + file.src
    int sizeMb;                 // the download
    const VendorSdkFile* files;
    int fileCount;
    // The license the user accepts before the download. Its text is fetched from licenseUrl when the status is asked for
    // it (a small file at the pinned tag), checked against licenseSha256 and shown; licenseEnd, when not empty, cuts the
    // shown text before that line (AMD's license.md goes on with a list of 600 files under other licenses).
    const char* licenseId;
    const char* licenseTitle;
    const char* licenseUrl;
    const char* licenseSha256;
    const char* licenseEnd;
    // What the license asks of the game that ships the DLLs, in a few sentences (the install, the export and the docs say it).
    const char* obligations;
    // Free disk space the install needs in <home>/staging while it runs, in MB: the download, the unpacked files it keeps and
    // the copy it assembles (sizeMb is the download alone). 0 = not stated.
    int diskMb = 0;
};

inline constexpr VendorSdkFile kSetupStreamlineFiles[] = {
    {"bin/x64/sl.interposer.dll", nullptr, "b1d7395aebd7b9722841d64dcf7433680020b6a8e421f851c16d5ba0c2182edf"},
    {"bin/x64/sl.common.dll", nullptr, "38eea3b4209afc455636ea372b5933d65fcc13becec6c84d101dcfc4d8648f75"},
    {"bin/x64/sl.dlss.dll", nullptr, "18871eea87c90345da97d8109faa81ea7d5840e8d99b51b55b0e46cfa177f84e"},
    {"bin/x64/sl.dlss_d.dll", nullptr, "8dff36fd063094eb1f659e8d4dcd52c7423859a9c4a3df3796084c48412d60ac"},
    {"bin/x64/sl.dlss_g.dll", nullptr, "3ed9538df724993bea8a050195a6a78b9c8c8a566d5b05ade477aab3c390e90f"},
    {"bin/x64/sl.reflex.dll", nullptr, "443577e869352436ff7ec8f4d9c90418d3e95368436ce219261e0f4f07a38122"},
    {"bin/x64/sl.pcl.dll", nullptr, "5698c38e722318681f215c9fe68e45b9bedd51378acc699d8eee26e961e57770"},
    {"bin/x64/nvngx_dlss.dll", nullptr, "d00b5b0ab29c3ca101b70c3a5ecb3a01b7ef33766a3383a28a18623083e6123e"},
    {"bin/x64/nvngx_dlssd.dll", nullptr, "b49435ae346f227feafe7bbe937d88277ea0ee7323975ec06488f377fdb46cee"},
    {"bin/x64/nvngx_dlssg.dll", nullptr, "8d59d49b36410dd6b62fef2503a5871d347415bd85d943fa0848563a95dd50c7"},
    {"bin/x64/NvLowLatencyVk.dll", nullptr, "2a77dc3e1c724b7eea5755be0ae7423752e79a2459fae72181a9f00e3507e5d6"},
    {"bin/x64/nvngx_dlss.license.txt", nullptr, "3027f23ca5a46dd9cb8183fbd522983a86f64d7daac5982912bf9f214671f294"},
    {"bin/x64/reflex.license.txt", nullptr, "ebf83c07fb3b2939908c3795d887afde3161c89a28ba391724efc784ce1bdabe"},
    {"license.txt", "sl.license.txt", "7b6f23e7d6f3ad6292f9308d2b42cdc3d82ae4e9b2abb55f230279d83bedd43d"},
    {"3rd-party-licenses.md", nullptr, "cb251639994465f31d2178c16acedf1ff4f9cef1c370a09782ed36d4c86c1dca"},
};
inline constexpr VendorSdk kSetupStreamline = {
    "streamline",
    "NVIDIA Streamline (DLSS, DLSS Ray Reconstruction, DLSS Frame Generation, Reflex)",
    "2.14.16",
    "https://github.com/NVIDIA-RTX/Streamline/releases/download/v2.14.16/streamline-sdk-v2.14.16.zip",
    "32041e51db0cab709a271b72a352281b690c2abbd669a827809401a5dd23956b",
    "",
    276,
    kSetupStreamlineFiles,
    int(sizeof(kSetupStreamlineFiles) / sizeof(kSetupStreamlineFiles[0])),
    "nvidia-rtx-sdks-license",
    "NVIDIA RTX SDKs LICENSE (with the NVIDIA RTX supplement)",
    "https://raw.githubusercontent.com/NVIDIA-RTX/Streamline/v2.14.16/external/ngx-sdk/license.txt",
    "3027f23ca5a46dd9cb8183fbd522983a86f64d7daac5982912bf9f214671f294",
    "",
    "NVIDIA's license lets a game redistribute these DLLs only as part of the game. Before the game's commercial "
    "release "
    "you must notify NVIDIA (https://developer.nvidia.com/sw-notification); the game must credit NVIDIA and show its "
    "marks (in its credits, and on a splash screen or about box for DLSS); DLSS is for systems with NVIDIA GPUs only; "
    "keep NVIDIA's license texts with the game (the export copies them to licenses/streamline/).",
    550};

inline constexpr VendorSdkFile kSetupXessFiles[] = {
    {"bin/libxess.dll", nullptr, "251659dd84a3e84de67c886a4186e01f3eca49b00641906fe38bb6b807e5d5b7"},
    {"bin/libxess_dx11.dll", nullptr, "c7cfe86f0c9d94e4fb3696d3cd5035e2bbb6a8b1b0572f8b7395a4cdfd0c625e"},
    {"bin/libxess_fg.dll", nullptr, "ec5e0c65e075570c6ede72618bb666d0be0c2e10b2ea9762c0fe8cb8e375ab27"},
    {"bin/libxell.dll", nullptr, "d2030dcd694fda8f2ec7e044b13e6db8f0b56d4ba9113a5efad334e3f3ded8c7"},
    {"LICENSE.txt", nullptr, "784be42c39a4a4d03cf85d88e15e59d75828fca773ce45b8dbfffbd7eaf208df"},
    {"third-party-programs.txt", nullptr, "e8d8899dbfc4de0e8ca25560be9358e03c1405d7c956d20a1838c3c709b9b51c"},
};
inline constexpr VendorSdk kSetupXess = {
    "xess",
    "Intel XeSS (super resolution, frame generation, low latency)",
    "3.0.2",
    "https://github.com/intel/xess/releases/download/v3.0.2/XeSS_SDK_3.0.2.zip",
    "88b8a373f30e33f3558a77a93e634f11b8132fc3047ea1a8edeead32b8471990",
    "",
    77,
    kSetupXessFiles,
    int(sizeof(kSetupXessFiles) / sizeof(kSetupXessFiles[0])),
    "intel-simplified-software-license",
    "Intel Simplified Software License (Version October 2022)",
    "https://raw.githubusercontent.com/intel/xess/v3.0.2/LICENSE.txt",
    "784be42c39a4a4d03cf85d88e15e59d75828fca773ce45b8dbfffbd7eaf208df",
    "",
    "Intel's license lets a game redistribute these DLLs, unmodified and in binary form, if Intel's copyright notice "
    "and "
    "the license terms go with the game (the export copies them to licenses/xess/); no reverse engineering or "
    "modification, and Intel's name may not be used to endorse the game.",
    300};

inline constexpr const char* kFidelityFxBase =
    "https://raw.githubusercontent.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/v2.4.0";
inline constexpr VendorSdkFile kSetupFidelityFxFiles[] = {
    {"Kits/FidelityFX/signedbin/amd_fidelityfx_loader_dx12.dll", nullptr,
     "e2191d3c0828be45eb8affd4e3ec0378f2293adc345b772a7170edcf3b021ecb"},
    {"Kits/FidelityFX/signedbin/amd_fidelityfx_loader_vk.dll", nullptr,
     "38a56a01fb3565c0757d9f5c1e4e69de4b65e5f2e5769b323b200dc1f142bab9"},
    {"Kits/FidelityFX/signedbin/amd_fidelityfx_upscaler_dx12.dll", nullptr,
     "aad4fccccb29084a655f9a4f9f613bd22c8c03fb4a0f8840148cc6543b4ccace"},
    {"Kits/FidelityFX/signedbin/amd_fidelityfx_upscaler_vk.dll", nullptr,
     "4a7e895af6e0b615d40a84d59eb8c2b1054ad91cdd0c739567940270d51bdab7"},
    {"Kits/FidelityFX/signedbin/amd_fidelityfx_framegeneration_dx12.dll", nullptr,
     "e6843252f58b0341a0d80f6a20bc0d840643ee95bc48c22cac08745344577bb6"},
    {"Kits/FidelityFX/signedbin/amd_fidelityfx_framegeneration_vk.dll", nullptr,
     "d002dabff8c5e71eaa715fc99438cd4dc81230262a7897b16bc402efec3498b4"},
    {"docs/license.md", nullptr, "410f9c138e766e846acf2dc93db768198def0293a017d7e3296815b451688dbe"},
    {"3rdpartynotice.md", nullptr, "3b69b1a1011622557a81b55a9a211dd797d01b8160924a5ec51b4c3432d33a4f"},
};
inline constexpr VendorSdk kSetupFidelityFx = {
    "fidelityfx",
    "AMD FidelityFX SDK (FSR upscaler and frame generation, DirectX 12 and Vulkan)",
    "2.4.0",
    "",
    "",
    kFidelityFxBase,
    160,
    kSetupFidelityFxFiles,
    int(sizeof(kSetupFidelityFxFiles) / sizeof(kSetupFidelityFxFiles[0])),
    "amd-fidelityfx-license",
    "AMD FidelityFX SDK license",
    "https://raw.githubusercontent.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/v2.4.0/docs/license.md",
    "410f9c138e766e846acf2dc93db768198def0293a017d7e3296815b451688dbe",
    "These source files",
    "AMD's license lets a game redistribute these DLLs, unmodified and in binary form only, if AMD's copyright notice, "
    "permission notice and disclaimers are reproduced in the game's documentation (the export copies them to "
    "licenses/fidelityfx/); no reverse engineering, decompilation or disassembly.",
    200};

// The three above, in the order of the components.
inline constexpr const VendorSdk* kSetupVendorSdks[] = {&kSetupStreamline, &kSetupXess, &kSetupFidelityFx};

// The folder everything is installed into: $FACTORIA_HOME when set, else <HOME>/.factoria
// (%USERPROFILE%\.factoria on Windows). It is also where ai.json lives (export.json follows FACTORIA_HOME unless
// FACTORIA_EXPORT_CONFIG names it).
std::string factoria_home(const ExportEnvLookup& env = system_export_env());

// ---------------------------------------------------------------------------------------------------------------
// Doing things in the world (replaceable)
// ---------------------------------------------------------------------------------------------------------------

using ProcessRunner = std::function<Result<ProcessResult>(const ProcessOptions&)>;

struct DownloadRequest {
    std::string url;                   // https:// (file:// works too: tests)
    std::string destination;           // the file to write; it is written as <destination>.part and renamed
    std::vector<std::string> headers;  // "Accept: application/vnd.github+json"
    std::uint64_t expectedBytes = 0;   // for progress only; 0 = unknown
    std::string what;                  // "JDK 21 (Eclipse Temurin)": names the download in errors
    std::function<void(std::uint64_t bytesSoFar)> onBytes;  // about twice a second while it runs; may be empty
    const CancelFlag* cancel = nullptr;
};

struct DownloadResult {
    bool ok = true;
    bool cancelled = false;
    int httpStatus = 0;  // the server's status when it answered with an error (404, 403...); 0 = none or unknown
    Error error;         // when !ok: what failed and how to fix it
};
using Downloader = std::function<DownloadResult(const DownloadRequest&)>;

// The default: the `curl` executable (macOS, Windows 10+ and most Linux have it) run through `run` (default
// fa::run_process): `curl -fL --retry 3 --connect-timeout 30 -o <file>.part <url>`, redirects only to https, proxies from
// the standard environment variables. While it runs, the size of the .part file is polled for `onBytes`; cancelling
// kills curl.
Downloader curl_downloader(ProcessRunner run = {});

struct SetupCache;  // optional per-process cache of the Android repository listing (below)

struct SetupContext {
    ExportEnvLookup env = system_export_env();
    std::string home;               // "" = factoria_home(env)
    std::string machineConfigPath;  // "" = machine_export_config_path(env)
    std::string host;               // "macos" | "windows" | "linux"; "" = this machine (tests change it)
    std::string hostArch;           // "aarch64" | "x64"; "" = this machine's
    std::string engineVersion;      // "" = FA_ENGINE_VERSION: the release the players come from
    std::string executableDir;      // "" = the folder of the running factoria (where mobile/ is looked for)
    std::string
        sourceRoot;  // "" = the checkout this factoria was built from (FA_SOURCE_ROOT): where `setup webplayer` builds
    std::string applicationsDir;                            // macOS: where Xcode*.app is looked for; "" = /Applications
    Downloader download;                                    // empty = curl_downloader()
    ProcessRunner run;                                      // empty = fa::run_process
    std::function<void(const std::string& line)> progress;  // "Downloading JDK 21 (190 MB): 40%": may be empty
    const CancelFlag* cancel = nullptr;
    std::optional<AndroidToolchainSearch> toolchainSearch;  // nullopt = default_android_toolchain_search(env)
    std::shared_ptr<SetupCache> cache;                      // null = every call fetches what it needs again
    bool verifyVendorSdkFiles =
        true;  // verify_installed_vendor_sdk checks the pinned hashes; tests with fake DLLs set false

    // The effective values (the defaults above filled in).
    std::string home_dir() const;
    std::string host_os() const;
    std::string host_architecture() const;
    std::string version() const;
    std::string config_path() const;
    AndroidToolchainSearch search() const;
    DownloadResult fetch(const DownloadRequest& request) const;  // download, or the injected downloader
    Result<ProcessResult> run_process_with(const ProcessOptions& options) const;
    void say(const std::string& line) const {
        if (progress) progress(line);
    }
};

struct SetupCache {
    std::mutex mutex;
    std::string repositoryXml;  // repository2-3.xml of the Android SDK, kept for a few minutes
    std::int64_t fetchedAtSeconds = 0;
};

// ---------------------------------------------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------------------------------------------

struct SetupLicense {
    std::string id;     // "android-sdk-license"
    std::string title;  // "Android Software Development Kit License Agreement"
    std::string text;   // the full text to show to the user before they agree
};

struct SetupComponent {
    std::string
        id;  // "android" | "players" | "webplayer" | "cmake" | "xcode" | "appimage" | "shaders" | "vscode" | "ffmpeg" | "launcher" |
    // "directstorage" | "streamline" | "xess" | "fidelityfx"
    std::string title;
    std::string state;    // "installed" | "missing" | "partial" | "unsupported" (nothing to do on this machine)
    std::string details;  // one or two sentences: what was found, what an install does
    std::vector<std::pair<std::string, std::string>> paths;  // "jdk" -> folder, "sdk" -> folder, "cmake" -> file...
    std::vector<std::string> problems;                       // what is missing or wrong, each with the way to fix it
    int installSizeMb = 0;               // download size of an install, approximately (0 = nothing to download)
    std::vector<SetupLicense> licenses;  // licenses to show before `acceptLicenses`; only while not yet accepted
    bool canInstall = false;             // `setup.install` can do something here
    Json to_json() const;
};

struct SetupStatus {
    std::string home;  // factoria_home()
    std::string host;  // "macos-aarch64"
    std::vector<SetupComponent> components;
    const SetupComponent* find(const std::string& id) const;
    Json to_json() const;
};

// Every component of this machine, or only `component` ("" = all). Looks at folders and runs version probes
// (`cmake --version`, `xcodebuild -version`); the only network request is a license text, fetched when `fetchLicenses`
// is set: the Android SDK's while it is not accepted yet, and a vendor SDK's (streamline, xess, fidelityfx, installed
// or not) only when `component` names it.
SetupStatus setup_status(const SetupContext& context = {}, const std::string& component = {},
                         bool fetchLicenses = true);

// ---------------------------------------------------------------------------------------------------------------
// Install
// ---------------------------------------------------------------------------------------------------------------

struct SetupInstallOptions {
    std::string
        component;  // "android" | "players" | "webplayer" | "cmake" | "xcode" | "appimage" | "shaders" | "vscode" | "ffmpeg" | "launcher" |
    // "directstorage" | "streamline" | "xess" | "fidelityfx"
    bool acceptLicenses =
        false;  // android, streamline, xess, fidelityfx: the user agreed to the license shown (status: licenses)
    std::vector<std::string>
        platforms;       // players: "windows" | "linux" | "macos" | "mobile" | "web"; empty = the default
    bool force = false;  // reinstall even when it is found (android, cmake)
};

struct SetupStep {
    std::string id;  // "jdk", "cmdline-tools", "licenses", "packages", "player-windows"...
    std::string title;
    std::string outcome;  // "installed" | "skipped" (already there, or done by a later step) | "guidance"
    std::string detail;
    std::string path;  // where it is now
    std::uint64_t downloadedBytes = 0;
    double seconds = 0;
    Json to_json() const;
};

struct SetupReport {
    std::string component;
    bool changed = false;  // something was downloaded or written
    std::vector<SetupStep> steps;
    std::vector<std::pair<std::string, std::string>> paths;
    std::vector<std::string> nextSteps;  // what the user does next (xcode: install it, open it once...)
    std::vector<std::string> warnings;
    double seconds = 0;
    Json to_json() const;
};

struct SetupResult {
    bool ok = false;
    SetupReport report;  // always filled as far as the install got (the steps done before a failure)
    std::string code;  // when !ok: "license_required" | "cancelled" | "network" | "checksum_mismatch" | "no_release" |
                       // "unsupported" | "invalid_argument" | "failed"
    Error error;       // when !ok
};

SetupResult setup_install(const SetupInstallOptions& options, const SetupContext& context = {});

// ---------------------------------------------------------------------------------------------------------------
// What the export asks for
// ---------------------------------------------------------------------------------------------------------------

// The factoria_player of `platform` ("windows" | "linux" | "macos") that `setup players` installed for this factoria's
// version: <home>/players/<version>/<platform>/factoria_player[.exe]; "" when it is not there. "web" gives the path of
// <home>/players/<version>/web/factoria_player.js (factoria_player.wasm is next to it).
std::string installed_player(const std::string& platform);
std::string installed_player(const SetupContext& context, const std::string& platform);

// <home>/players/<version>/mobile (the layout of the download's mobile/ folder) when it holds prebuilt Android or iOS
// libraries; "" otherwise.
std::string installed_mobile_dir();
std::string installed_mobile_dir(const SetupContext& context);

// A CMake 3.24 or newer, as an executable path: PATH, /opt/homebrew/bin, /usr/local/bin, /Applications/CMake.app,
// Program Files, then <home>/tools/cmake (what `setup cmake` installs); "" when none.
std::string find_cmake();
std::string find_cmake(const SetupContext& context);

// The files `setup appimage` installed: <home>/tools/appimage/appimagetool-<version>-x86_64.AppImage and runtime-<version>-x86_64.
// Both empty when either is missing.
struct AppImageTools {
    std::string tool, runtime;
};
AppImageTools installed_appimage_tools(const SetupContext& context);

// The sokol-shdc binary of this host's entry in kSetupSokolShdcBinaries; nullptr when the host has none.
const SokolShdcBinary* sokol_shdc_binary(const SetupContext& context);
// <home>/tools/sokol-shdc/<kSetupSokolShdcCommit>: where `setup shaders` installs sokol-shdc[.exe].
std::string sokol_shdc_install_dir(const SetupContext& context);
// The sokol-shdc to compile materials with: $SOKOL_SHDC, else sokol-shdc[.exe] next to the factoria executable (the
// release downloads), else the one in sokol_shdc_install_dir; "" when none is there.
std::string find_sokol_shdc(const SetupContext& context = {});

// The ffmpeg binary of this host's entry in kSetupFfmpegBinaries; nullptr when the host has none.
const FfmpegBinary* ffmpeg_binary(const SetupContext& context);
// <home>/tools/ffmpeg/<kSetupFfmpegRelease>/ffmpeg[.exe]: where `setup ffmpeg` puts it (the file may not exist).
std::string ffmpeg_install_path(const SetupContext& context);

// <home>/tools/directstorage/<kSetupDirectStorage.version>: where `setup directstorage` puts the DirectStorage DLLs.
std::string directstorage_install_dir(const SetupContext& context);
// That folder when it holds both kSetupDirectStorageFiles; "" when either is missing.
std::string installed_directstorage_dir(const SetupContext& context);

// The vendor SDK `id` ("streamline" | "xess" | "fidelityfx") of kSetupVendorSdks; nullptr when it is none of them.
const VendorSdk* find_vendor_sdk(const std::string& id);
// Every id of kSetupVendorSdks.
std::vector<std::string> vendor_sdk_ids();
// <home>/tools/<id>/<version>: where `setup <id>` puts the DLLs and the license texts (the folder may not exist).
std::string vendor_sdk_install_dir(const SetupContext& context, const VendorSdk& sdk);
// That folder when it holds every file of the table; "" when any is missing. (Installing writes the folder only once complete.)
std::string installed_vendor_sdk_dir(const SetupContext& context, const VendorSdk& sdk);
// Reads every file of the installed SDK and checks it against the SHA-256 the table pins (installed_vendor_sdk_dir only checks
// that the files exist): a file that is missing, cut short or changed is an error that names it and the command that fixes it
// (`factoria setup <id> --force`, which asks for the license again). Reads about 120 MB for Streamline, so a caller that polls
// (a status line) does not call it; the export does, before it starts. A context with verifyVendorSdkFiles false (tests that
// install fake files) skips the check.
Result<void> verify_installed_vendor_sdk(const SetupContext& context, const VendorSdk& sdk);
// Does this file of the table go next to the game's executable (a .dll) or with the license texts (everything else)?
bool vendor_sdk_file_is_library(const VendorSdkFile& file);
// The name of `file` in the install folder (VendorSdkFile::dst, else the last part of src).
std::string vendor_sdk_file_name(const VendorSdkFile& file);

// Which vendor SDKs a project can use, from its factoria.json (`projectJson`), by JSON pointer and tolerant of keys that
// do not exist (yet) or have another type: render.upscaler.mode "auto" (every SDK that has an upscaler) or a vendor's mode
// ("dlss" -> streamline, "xess" -> xess, "fsr" -> fidelityfx); render.frameGeneration.mode the same ("auto", dlss, xess,
// fsr); render.latency.mode "auto" (streamline's Reflex and xess's XeLL), "reflex" -> streamline, "xell" -> xess. Ids in
// the order of kSetupVendorSdks, once each. `reasons`, when not null, receives per id the pointer and value that asked for it
// ("/render/upscaler/mode = \"dlss\"").
std::vector<std::string>
vendor_sdks_used_by_project(const Json& projectJson,
                            std::vector<std::pair<std::string, std::string>>* reasons = nullptr);

// When the launcher `setup launcher` wrote opens this factoria but is out of date (an update or a reinstall brought a new
// icon or version), writes it again and returns true. A missing launcher, or one that opens another factoria (a
// development build runs the editor too), is left alone. The editor calls it at start, off the main thread.
bool refresh_launcher(const SetupContext& context = {});

// The command that restarts the editor on `projectDir` through the launcher the user has pinned, so the Dock or taskbar
// shows one FactorIA icon and not a second one (argv[0] is the program; the caller runs it detached and does not wait for
// it). macOS, only when ~/Applications/FactorIA.app is the launcher of THIS factoria and passes the project on, even when
// another version wrote it (an editor still running after a newer FactorIA was installed over it): with `quittingPid`
// (the editor that is about to quit), a `/bin/sh` that waits until that process is gone and then runs
// `/usr/bin/open <FactorIA.app> --args <projectDir>`, so the new editor takes the pinned Dock icon (a second instance,
// `open -n`, gets an icon of its own); without it, `/usr/bin/open -n <FactorIA.app> --args <projectDir>`. Windows:
// FactorIA-Editor.exe next to this factoria.exe. With an empty projectDir (the editor is on its start screen) the same
// launcher without the project. Empty (start `factoria editor <projectDir>` yourself) when there is no such launcher,
// it is another factoria's, or on Linux (the .desktop's StartupWMClass groups the window already).
// `projectDir` should be absolute: the macOS launcher runs from the home folder.
std::vector<std::string> editor_restart_command(const SetupContext& context, const std::string& projectDir,
                                                long long quittingPid = 0);

// Registers "setup.status" ({read, process, network}: it runs the tools it probes and may fetch the Android license text) and
// "setup.install" ({read, writeAnywhere, process, network}: the user's call, an MCP client or an agent gets
// capability_denied; category "setup"). They need no project, so they are
// registered with the tooling commands and with the project-less command set; the editor calls the C++ API above.
void register_setup_commands(CommandRegistry& registry);

}  // namespace fa
