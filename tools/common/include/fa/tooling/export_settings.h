// Platform settings of a game's export: the `icon` and `export` keys of factoria.json (committed with the game), the
// machine settings in ~/.factoria/export.json (never in a project), and the search for the Android toolchain.
// docs/EXPORTING.md ("Platform settings") describes the format; schemas/project.schema.json documents every field.
//
//   factoria.json                                   ~/.factoria/export.json (%USERPROFILE%\.factoria\export.json)
//   { "icon": "assets/icon.png",                    { "format": "factoria.export-config/1",
//     "export": {                                     "android": { "sdk": "/Users/me/Library/Android/sdk",
//       "macos":   { "category": "...", ... },                     "jdk": "/path/to/jdk",
//       "android": { "format": "aab", ... } } }                    "keystorePassword": "...", "keyPassword": "..." } }
//
// Everything here reads and writes files only (no child process runs), so it works the same on every host.
#pragma once

#include <functional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// ---------------------------------------------------------------------------
// factoria.json: "icon" and "export"
// ---------------------------------------------------------------------------

struct WindowsExportSettings {
    std::string icon;  // project-relative; "" = the project's `icon`
    bool operator==(const WindowsExportSettings&) const = default;
};

struct MacosExportSettings {
    std::string icon;
    std::string category = "public.app-category.games";  // LSApplicationCategoryType
    std::string minimumSystemVersion = "11.0";            // LSMinimumSystemVersion, 11.0 or newer
    std::string copyright;                                // NSHumanReadableCopyright; "" = none
    std::string buildNumber;                              // CFBundleVersion; "" = the project's "version"
    bool usesNonExemptEncryption = false;                 // ITSAppUsesNonExemptEncryption in Info.plist
    Json entitlements = Json::object();                   // sandbox capabilities added to the Mac App Store signature (sign.macos)
    bool operator==(const MacosExportSettings&) const = default;
};

struct LinuxExportSettings {
    std::string icon;
    std::vector<std::string> categories = {"Game"};  // Categories= of the .desktop file
    bool operator==(const LinuxExportSettings&) const = default;
};

struct AndroidAdaptiveIconSettings {
    std::string foreground;                // 108dp layer, project-relative; "" = the icon scaled into the safe zone
    std::string background = "#FFFFFF";    // "#RRGGBB", or the project-relative path of an image
    std::string monochrome;                // optional layer for Android 13 themed icons; "" = none
    bool operator==(const AndroidAdaptiveIconSettings&) const = default;
};

struct AndroidSigningSettings {
    std::string keystore;  // project-relative or absolute path of the keystore; "" = not set
    std::string alias;     // key alias inside the keystore
    bool operator==(const AndroidSigningSettings&) const = default;
};

struct AndroidExportSettings {
    std::string icon;
    std::string format = "apk";            // "apk" | "aab" | "gradle"
    AndroidAdaptiveIconSettings adaptiveIcon;
    int versionCode = 0;                   // 0 = derived from the project's "version" (1.2.3 -> 10203)
    int minSdk = 26;                       // 26 <= minSdk <= targetSdk
    int targetSdk = 36;                    // >= 26 (Google Play asks for the latest API level)
    std::vector<std::string> permissions;  // extra <uses-permission> names, "android.permission.VIBRATE"
    AndroidSigningSettings signing;
    bool operator==(const AndroidExportSettings&) const = default;
};

// One required-reason API category of the privacy manifest (PrivacyInfo.xcprivacy) with the reason codes the app gives for
// it, e.g. {"DiskSpace", {"E174.1"}} (the NSPrivacyAccessedAPICategory prefix is left out).
struct IosPrivacyApi {
    std::string category;
    std::vector<std::string> reasons;
    bool operator==(const IosPrivacyApi&) const = default;
};

// One kind of data the app collects (NSPrivacyCollectedDataTypes).
struct IosPrivacyCollectedData {
    std::string type;                    // "PurchaseHistory" (the NSPrivacyCollectedDataType... name without the prefix)
    bool linked = false;                 // linked to the user's identity
    bool tracking = false;               // used to track the user
    std::vector<std::string> purposes;   // "AppFunctionality" (the NSPrivacyCollectedDataTypePurpose... names without the prefix)
    bool operator==(const IosPrivacyCollectedData&) const = default;
};

// export.ios.privacy: what a game or its plugins add to the privacy manifest. The engine's own required-reason APIs are
// always declared (ios_engine_privacy_apis in fa/tooling/ios_privacy.h); nothing is collected and nothing tracks unless
// these say so.
struct IosPrivacySettings {
    bool tracking = false;                        // NSPrivacyTracking
    std::vector<std::string> trackingDomains;     // NSPrivacyTrackingDomains (what tracking needs)
    std::vector<IosPrivacyApi> accessedApis;      // added to (merged with) the engine's
    std::vector<IosPrivacyCollectedData> collectedData;
    bool operator==(const IosPrivacySettings&) const = default;
};

struct IosExportSettings {
    std::string icon;
    std::string iconBackground = "#FFFFFF";  // "#RRGGBB": the App Store icon cannot be transparent
    std::string teamId;                      // development team, 10 letters/digits; "" = FA_IOS_DEVELOPMENT_TEAM
    std::string buildNumber;                 // CFBundleVersion; "" = the project's "version"
    bool usesNonExemptEncryption = false;    // ITSAppUsesNonExemptEncryption in Info.plist
    IosPrivacySettings privacy;
    bool operator==(const IosExportSettings&) const = default;
};

// What `icon` and `export` of factoria.json say, with every default filled in. Fields that are "derived" when empty
// (Android versionCode, iOS and macOS buildNumber) stay empty/0 so that saving does not freeze them; use the helpers below.
struct ProjectExportSettings {
    std::string icon;  // the icon of every platform that has no icon of its own; "" = none
    bool scriptBytecode = true;  // export.scriptBytecode: a --release desktop export compiles the .js files to QuickJS bytecode
                                 // inside the game pack (false: plain source in the pack). No other export reads it
    std::vector<std::string> exclude;  // export.exclude: project-relative globs ('*', '**', '?') no export ships
    WindowsExportSettings windows;
    MacosExportSettings macos;
    LinuxExportSettings linux;
    AndroidExportSettings android;
    IosExportSettings ios;
    std::string projectVersion;  // "version" of factoria.json as read (not written back); derived defaults use it

    // The icon of `platform` ("windows" | "macos" | "linux" | "android" | "ios"): its own, else `icon`, else "".
    std::string icon_for(const std::string& platform) const;
    // android.versionCode when set, else android_version_code(projectVersion).
    int android_version_code() const;
    // ios.buildNumber when set, else projectVersion.
    std::string ios_build_number() const;
    // macos.buildNumber when set, else projectVersion.
    std::string macos_build_number() const;
};

// "1.2.3" -> 10203 (major * 10000 + minor * 100 + patch, each part capped at 99, at least 1): the Android versionCode
// derived from a game version.
int android_version_code_from(const std::string& version);

// One problem found in `icon` / `export` of a factoria.json.
struct ExportSettingsIssue {
    std::string pointer;  // JSON pointer inside factoria.json: "/export/android/minSdk"
    std::string message;
    std::string hint;
    std::string to_string() const;  // "factoria.json#/export/android/minSdk: message (hint: ...)"
};

struct ExportSettingsParse {
    ProjectExportSettings settings;                // what could be read; an invalid field keeps its default
    std::vector<ExportSettingsIssue> errors;       // wrong type or value: the export cannot trust the file
    std::vector<ExportSettingsIssue> warnings;     // unknown keys (with "did you mean"), not harmful
};

// Reads `icon` and `export` from the parsed factoria.json. Pure: it looks at no file (a missing icon file is reported
// by validate_project / load_icon_image). Every problem is collected, none stops the reading.
ExportSettingsParse parse_export_settings(const Json& projectJson);

// Reads <projectDir>/factoria.json. The Error is the first problem (message with the file and JSON pointer, hint with
// the fix; "N more" when there are several); warnings (unknown keys...) are appended to `warnings` as one line each.
Result<ProjectExportSettings> load_export_settings(const std::string& projectDir,
                                                   std::vector<std::string>* warnings = nullptr);

// Writes `icon` and `export` back into <projectDir>/factoria.json and nothing else: the file is patched in place, so
// every other key, the key order, the indentation, the array style and the line endings stay as they are. Only the
// fields that differ from what the file says now are touched; one equal to its default is removed instead of written,
// and an empty platform object (or `export`) disappears. Unknown keys inside `export` are kept. Returns an Error when
// factoria.json is missing or is not a JSON object.
Result<void> save_export_settings(const std::string& projectDir, const ProjectExportSettings& settings);

// ---------------------------------------------------------------------------
// Machine settings: ~/.factoria/export.json
// ---------------------------------------------------------------------------

using ExportEnvLookup = std::function<std::string(const std::string& name)>;  // "" when the variable is unset
ExportEnvLookup system_export_env();                                           // reads the process environment

struct MachineExportConfig {
    std::string androidSdk;                // "" = look for it (find_android_toolchain)
    std::string androidJdk;                // "" = look for it
    std::string androidKeystorePassword;   // "" = not stored here (FACTORIA_ANDROID_KEYSTORE_PASSWORD still applies)
    std::string androidKeyPassword;        // "" = the keystore password
    std::string sourcePath;                // the file it was read from ("" when there is none)
    std::vector<std::string> warnings;     // e.g. a file with passwords that other users can read
};

// $FACTORIA_EXPORT_CONFIG when set; else $FACTORIA_HOME/export.json when that is set; else <HOME>/.factoria/export.json
// (%USERPROFILE%\.factoria\export.json on Windows); else ".factoria/export.json".
std::string machine_export_config_path(const ExportEnvLookup& env = system_export_env());

// An external tool found the same way everywhere (store uploaders, ffmpeg): the environment variable `envVar` (the
// executable or the folder that holds it), else the "publish" object of the machine settings (`configKey`), else PATH.
struct MachineTool {
    std::string label;                  // starts every message: "publish.steam", "ffmpeg"
    std::string tool;                   // the name in messages: "steamcmd"
    std::string envVar;                 // FACTORIA_STEAMCMD
    std::string configKey;              // "steamcmd" in {"publish": {...}} of export.json
    std::vector<std::string> exeNames;  // looked up on PATH and inside a folder (".exe" etc. added on Windows)
    std::string download;               // where to get it, for the error
};
struct MachineToolFound {
    std::string path;
    std::string from;                   // the variable name, "export.json" or "PATH"
};
// A variable or a config entry that points at nothing is an error that says so (no fall-through to PATH); so is a tool
// found nowhere: the message names the download page, the variable and the key. `configPath` "" = machine_export_config_path(env).
Result<MachineToolFound> find_machine_tool(const MachineTool& tool, const ExportEnvLookup& env = system_export_env(), const std::string& configPath = {});
// The ffmpeg that turns a recorded .avi into an .mp4 (`factoria run --record-video x.mp4`): FACTORIA_FFMPEG, "ffmpeg" in "publish".
Result<MachineToolFound> find_ffmpeg(const ExportEnvLookup& env = system_export_env(), const std::string& configPath = {});

// A missing file is not an error (defaults come back). Unreadable JSON, a wrong "format" or a value of the wrong
// type is, naming the file and the key. `path` "" = machine_export_config_path().
Result<MachineExportConfig> load_machine_export_config(const std::string& path = {});

// Writes the file (folders created, owner-only permissions on Unix because it can hold passwords). Keys this version
// does not know are kept; empty values are removed.
Result<void> save_machine_export_config(const MachineExportConfig& config, const std::string& path = {});

// The Android signing passwords: environment variables win over the file.
struct AndroidSigningSecrets {
    std::string keystorePassword;      // FACTORIA_ANDROID_KEYSTORE_PASSWORD, else the file
    std::string keyPassword;           // FACTORIA_ANDROID_KEY_PASSWORD, else the file, else the keystore password
    std::string keystorePasswordFrom;  // "FACTORIA_ANDROID_KEYSTORE_PASSWORD" | "export.json" | "" (not set)
    std::string keyPasswordFrom;       // "FACTORIA_ANDROID_KEY_PASSWORD" | "export.json" | "keystore password" | ""
};
AndroidSigningSecrets resolve_android_signing_secrets(const MachineExportConfig& config,
                                                      const ExportEnvLookup& env = system_export_env());

// ---------------------------------------------------------------------------
// Android toolchain (JDK + SDK), found by looking at folders only
// ---------------------------------------------------------------------------

struct AndroidToolchain {
    std::string jdk;       // folder that holds bin/java (JAVA_HOME style); "" when none was found
    std::string jdkFrom;   // "config" | "JAVA_HOME" | "FactorIA" | "Android Studio" | "Unity Hub"
    int jdkMajor = 0;      // 17 for "17.0.9", read from <jdk>/release; 0 when unknown
    std::string sdk;       // folder of the Android SDK; "" when none was found
    std::string sdkFrom;   // "config" | "ANDROID_HOME" | "ANDROID_SDK_ROOT" | "FactorIA" | "default location" | "Unity Hub"
    std::vector<std::string> problems;  // what blocks a build, each saying what is missing and how to fix it
    std::vector<std::string> warnings;  // worth knowing (a configured folder that was skipped, licenses not accepted)

    bool ok() const { return problems.empty(); }
    Json to_json() const;
};

// Where to look. Each candidate is a folder, or a pattern whose path segments may be "*" (Unity Hub keeps one folder
// per editor version: the matches are tried newest version first). Candidates are tried in order after the
// configured folder and JAVA_HOME / ANDROID_HOME / ANDROID_SDK_ROOT; `from` is what AndroidToolchain::jdkFrom says.
struct AndroidToolchainCandidate {
    std::string path;
    std::string from;
};
struct AndroidToolchainSearch {
    ExportEnvLookup env = system_export_env();
    std::vector<AndroidToolchainCandidate> jdk;
    std::vector<AndroidToolchainCandidate> sdk;
};

// The usual places on this OS: what `factoria setup android` installs (<factoria home>/android/jdk and /sdk, `from`
// "FactorIA", first), Android Studio's bundled JDK and Unity Hub's Android JDK; the SDK folders of Android Studio
// (~/Library/Android/sdk, %LOCALAPPDATA%\Android\Sdk, ~/Android/Sdk) and Unity Hub.
AndroidToolchainSearch default_android_toolchain_search(const ExportEnvLookup& env = system_export_env());

// JDK: the folder of `config`, else JAVA_HOME, else the candidates. SDK: the folder of `config`, else ANDROID_HOME,
// else ANDROID_SDK_ROOT, else the candidates. A JDK needs bin/java and bin/javac and Java 17 or newer (the major
// version comes from <jdk>/release); a folder is an SDK when it has platform-tools/, platforms/ or licenses/. The
// first folder that qualifies wins; one that was configured but does not qualify is skipped with a warning. When
// nothing qualifies, `problems` says what is missing and where to set the path (Platform settings > Android in the
// editor, ~/.factoria/export.json, or the environment variable).
AndroidToolchain find_android_toolchain(const MachineExportConfig& config, const AndroidToolchainSearch& search);
inline AndroidToolchain find_android_toolchain(const MachineExportConfig& config) {
    return find_android_toolchain(config, default_android_toolchain_search());
}

// Major version of the Java in `jdkDir` from its `release` file (JAVA_VERSION="17.0.9" -> 17, "1.8.0_392" -> 8); 0 when
// the file is missing or has no version.
int jdk_major_version(const std::string& jdkDir);

}  // namespace fa
