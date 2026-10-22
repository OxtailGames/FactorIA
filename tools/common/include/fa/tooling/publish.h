// Uploading exports to stores: the commands publish.steam, publish.itch, publish.epic, publish.gog, publish.appstore and
// publish.googleplay.
//
// A store command takes the folders `project.export` wrote (<project>/build/export/<game-slug>-<platform>/, desktop platforms only)
// and runs the store's own uploader on them. FactorIA writes what the uploader reads (Steam's build scripts, GOG's project
// files, ignore lists) into <project>/.factoria/publish/<store>/ and spawns the tool:
//   steam : steamcmd +login <account> +run_app_build <app_build_<appid>.vdf> +quit   (one depot per platform)
//   itch  : butler push <folder> <user>/<game>:<channel> --userversion <version>      (one channel per platform)
//   epic  : BuildPatchTool -mode=UploadBinary ... -ClientSecretEnvVar=...             (one artifact per platform)
//   gog   : GOGGalaxyPipelineBuilder build-game <project.json> ...                    (one project file per platform)
// The two mobile stores upload ONE built file instead of export folders (the .ipa you archived in Xcode, the release .aab):
//   appstore   : xcrun altool --upload-package <ipa> --type ios --apple-id ... --apiKey ... --apiIssuer ...  (macOS only)
//   googleplay : fastlane supply --aab <aab> --track internal --package_name ... --json_key <service account>
// The Microsoft Store takes the unsigned MSIX `project.export --platform windows --format msix` wrote:
//   microsoft  : msstore reconfigure ..., then msstore publish <folder of the msix> -i <msix> -id <product id>
//                (credentials: FACTORIA_MSSTORE_TENANT_ID / _SELLER_ID / _CLIENT_ID / _CLIENT_SECRET, environment only)
// `dryRun` writes those files, runs nothing and returns the exact command lines.
//
// Where things live (docs/EXPORTING.md, "Uploading to stores"):
//   * the ids of your game in the stores: the "publish" section of factoria.json (parse_publish_settings), checked by
//     `factoria validate`. Steam's app id is NOT repeated there: it is the one in steam_appid.txt (docs/PLATFORM.md).
//   * secrets: environment variables (FACTORIA_EPIC_CLIENT_SECRET, FACTORIA_GOG_USERNAME / FACTORIA_GOG_PASSWORD,
//     BUTLER_API_KEY; the App Store Connect API key and the Play service account are FILES whose path is in an
//     environment variable, FACTORIA_APPSTORE_API_KEY / FACTORIA_GOOGLEPLAY_JSON_KEY) or the tools' own cached logins. Never factoria.json, never printed, never in a log.
//   * the tools: found like the Android toolchain (a FACTORIA_<TOOL> environment variable, "publish" in
//     ~/.factoria/export.json, then PATH). Nothing is downloaded.
#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/core/types.h"
#include "fa/tooling/export_settings.h"

namespace fa {

// "steam", "itch", "epic", "gog", "appstore", "googleplay", "microsoft": the stores that have a publish.<store> command.
const std::vector<std::string>& publish_stores();
// "windows", "macos", "linux": the exports a store command uploads (mobile uploads are separate).
const std::vector<std::string>& publish_platforms();

// ---------------------------------------------------------------------------
// factoria.json: "publish"
// ---------------------------------------------------------------------------

struct SteamPublishSettings {
    std::string account;                          // steamcmd login name; "" = not set
    std::map<std::string, long long> depots;      // platform -> depot id
    std::string branch;                           // beta branch to set live after a build; "" = none (never "default")
};

struct ItchPublishSettings {
    std::string game;                             // "user/game", lower case
    std::map<std::string, std::string> channels;  // platform -> channel; a platform without one uses channel_for()
};

struct EpicPublishSettings {
    std::string organizationId, productId, clientId;
    std::map<std::string, std::string> artifacts; // platform -> artifact id
};

struct GogPublishSettings {
    std::string productId;                        // the game's product id of the GOG Developer Portal
    std::string clientId;                         // GALAXY SDK client id; "" = not set
    std::vector<std::string> languages = {"en-US"};
};

struct AppStorePublishSettings {
    std::string appleId;                          // the app's numeric Apple ID in App Store Connect (App Information > General Information)
};

struct GooglePlayPublishSettings {
    std::string track = "internal";               // internal | alpha | beta | production, or the name of a custom closed track
    std::string releaseStatus = "draft";          // draft | completed
    std::map<std::string, std::string> changelogs;  // Play locale (en-US) -> project-relative text file: the "What's new" of the release
};

struct MicrosoftPublishSettings {
    std::string productId;                        // the app's Store ID in Partner Center (12 letters and digits, e.g. 9NBLGGH4NNS1)
};

struct PublishSettings {
    SteamPublishSettings steam;
    ItchPublishSettings itch;
    EpicPublishSettings epic;
    GogPublishSettings gog;
    AppStorePublishSettings appstore;
    GooglePlayPublishSettings googleplay;
    MicrosoftPublishSettings microsoft;
};

// The itch.io channel of `platform`: the configured one, else "windows", "mac" or "linux".
std::string itch_channel_for(const ItchPublishSettings& settings, const std::string& platform);

struct PublishSettingsParse {
    PublishSettings settings;                     // what could be read; an invalid field keeps its default
    std::vector<ExportSettingsIssue> errors;      // wrong type or value
    std::vector<ExportSettingsIssue> warnings;    // unknown keys (with "did you mean")
};

// Reads "publish" from the parsed factoria.json. Pure: no file is looked at. A store the game does not publish to may be
// absent or incomplete; the store command reports what it misses.
PublishSettingsParse parse_publish_settings(const Json& projectJson);

// ---------------------------------------------------------------------------
// Publishing
// ---------------------------------------------------------------------------

struct PublishOptions {
    std::string store;                            // steam | itch | epic | gog | appstore | googleplay
    std::string projectDir;                       // folder containing factoria.json
    std::vector<std::string> platforms;           // windows | macos | linux ("" = every one that has an export and is set up for the store)
    std::string outDir;                           // parent folder of the exports ("" = <projectDir>/build/export)
    std::map<std::string, std::string> folders;   // platform -> folder to upload instead of <out>/<slug>-<platform> (inside the project)
    bool dryRun = false;                          // write the build files and report the command lines; run nothing
    std::string account;                          // steam: login name (else publish.steam.account)
    std::string appId;                            // steam: app id (else steam_appid.txt)
    std::string branch;                           // steam: beta branch to set live (else publish.steam.branch); gog: branch to publish to
    std::string artifact;                         // appstore / googleplay / microsoft: the .ipa / .aab / .msix to upload ("" = build/export/<slug>.ipa, build/export/<slug>-android/<slug>.aab)
    std::string track, releaseStatus;             // googleplay: release track and draft|completed (else publish.googleplay.track / .releaseStatus)
    std::string host;                             // "" = this computer ("macos" | "windows" | "linux"); only tests change it (appstore runs on macOS only)
    std::function<void(const std::string& line)> progress;  // optional: each line the uploader prints (the same lines go to the log)
    const CancelFlag* cancel = nullptr;           // optional: set to true to stop the uploader (its process tree is killed)
    ExportEnvLookup env = system_export_env();    // environment variables (secrets, tool paths); only tests change it
    std::string toolConfigPath;                   // "" = machine_export_config_path(env); only tests change it
};

struct PublishUpload {
    std::string platform;
    std::string folder;       // absolute folder that is uploaded
    std::string destination;  // where it goes: "Steam app 480, depot 481", "user/game:windows"...
    std::size_t files = 0;    // files that are uploaded (the export's own marker and AI disclosure are left out)
    std::uint64_t bytes = 0;
    bool uploaded = false;    // its uploader finished successfully
};

struct PublishStep {
    std::string title;
    std::vector<std::string> command;  // the command line, secrets replaced by <redacted>
    std::vector<std::string> files;    // build files written for it
    bool ran = false;
    int exitCode = -1;                 // of the uploader once it ran
};

struct PublishReport {
    std::string store, version;
    std::string tool, toolFrom;        // the uploader and where it was found ("FACTORIA_STEAMCMD", "export.json", "PATH")
    std::string log;                   // absolute path of the log (empty for a dry run)
    bool dryRun = false;
    bool uploaded = false;             // every step ran and succeeded
    bool failed = false;               // an uploader failed, could not start, or was cancelled
    std::string failure, failureHint;  // what went wrong and how to fix it when `failed`
    int exitCode = -1;                 // of the last uploader that ran
    std::vector<PublishUpload> uploads;
    std::vector<PublishStep> steps;
    std::vector<std::string> files;    // everything written, absolute (build files and the log)
    std::vector<std::string> warnings;
    std::vector<std::string> nextSteps;
    Json to_json() const;
};

// Plans the upload (every check before anything is written), writes the build files, and, unless `dryRun`, runs the
// uploader once per step. An Error means nothing ran (a missing id, export or tool; the message says how to fix it). An
// uploader that fails is NOT an Error: the report has `failed`, `failure`, the uploads that did go through and the log.
Result<PublishReport> publish_project(const PublishOptions& options);

// Registers publish.steam, publish.itch, publish.epic, publish.gog, publish.appstore and publish.googleplay (-> MCP tools publish_steam..., `factoria call`,
// editor console, fa.call) for the project at `projectDir`. Each runs publish_project(); a failed uploader is a command
// error whose `data` is the report.
void register_publish_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
