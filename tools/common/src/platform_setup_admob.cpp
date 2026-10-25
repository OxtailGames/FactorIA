// platform.add_backend {"backend": "admob"}: the ads backend for Android and iOS (docs/PLATFORM.md, "Ads"). It creates the plugin
// from platforms/plugins/admob and builds it: on Android a C bridge for arm64-v8a and x86_64 with the Android SDK's NDK, CMake and
// Ninja (a Gradle module in Java does the work); on iOS, on a Mac, Swift libraries for the device and the Simulator against Google's
// iOS SDK, which is a download ("sdk": its zip or folder) copied into the plugin's ios/frameworks/. It lists what only a person can
// do in the AdMob console. The repository holds no Google code: Gradle fetches the Android SDK when the game is exported, and the
// iOS XCFrameworks stay out of git (platforms/plugins/admob/README.md).
#include <algorithm>
#include <cctype>
#include <filesystem>
#include <optional>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/services/platform.h"
#include "fa/tooling/setup.h"
#include "platform_setup.h"
#include "setup_internal.h"
#include "util.h"

namespace fa::platform_setup {

namespace stdfs = std::filesystem;

namespace {

constexpr const char* kSdkPage = "developers.google.com/admob/ios/quick-start";
const char* const kFrameworks[] = {"GoogleMobileAds.xcframework", "UserMessagingPlatform.xcframework"};

bool is_dir(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_directory(p, ec);
}

bool is_zip(const stdfs::path& p) {
    std::error_code ec;
    if (!stdfs::is_regular_file(p, ec)) return false;
    std::string ext = p.extension().string();
    std::transform(ext.begin(), ext.end(), ext.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return ext == ".zip";
}

const std::string kSdkHelp = std::string("Google's Mobile Ads SDK for iOS is a download (") + kSdkPage +
                             ", \"Download the SDK\"; the zip holds GoogleMobileAds.xcframework and UserMessagingPlatform.xcframework): its license "
                             "does not let FactorIA ship the files. Pass the .zip or the unpacked folder as \"sdk\".";

// The folder that holds both XCFrameworks: `base`, one of its children, or a folder up to three levels down (the zip unpacks to
// GoogleMobileAdsSdkiOS-<version>/ and the CocoaPods layout nests them deeper).
std::optional<stdfs::path> find_frameworks(const stdfs::path& base) {
    auto holds = [](const stdfs::path& dir) {
        return std::all_of(std::begin(kFrameworks), std::end(kFrameworks),
                           [&](const char* name) { return is_dir(dir / name); });
    };
    if (holds(base)) return base;
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(base, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        if (it.depth() >= 3) it.disable_recursion_pending();
        if (it->is_directory(ec) && holds(it->path())) return it->path();
    }
    return std::nullopt;
}

// Resolves the "sdk" argument to the folder holding the two XCFrameworks (unpacking a zip into `scratch`), or throws a teaching error.
stdfs::path resolve_sdk(const std::string& sdk, const std::string& projectDir, Scratch& scratch) {
    const stdfs::path path = expand_path(sdk, projectDir);
    std::error_code ec;
    if (!stdfs::exists(path, ec))
        throw CommandError("not_found", "the Google Mobile Ads SDK '" + path.generic_string() + "' does not exist", kSdkHelp);
    stdfs::path base = path;
    if (!is_dir(path)) {
        if (!is_zip(path))
            throw CommandError("invalid_argument", "the Google Mobile Ads SDK '" + path.generic_string() + "' is a file, but not a .zip", kSdkHelp);
        scratch.dir = fs::make_temp_dir("fa_admob_sdk");
        if (auto fail = setup_detail::extract_archive(fa::SetupContext{}, path, scratch.dir))
            throw CommandError(fail->code, "cannot unpack the Google Mobile Ads SDK " + path.generic_string() + ": " + fail->error.message,
                               fail->error.hint.empty() ? "Unpack the .zip yourself and pass the folder as \"sdk\"." : fail->error.hint);
        base = scratch.dir;
    }
    if (auto found = find_frameworks(base)) return *found;
    throw CommandError("invalid_argument",
                       "'" + path.generic_string() + "' is not the Google Mobile Ads SDK for iOS: no folder in it (up to three levels down) holds both " +
                           join(std::vector<std::string>(std::begin(kFrameworks), std::end(kFrameworks)), " and "),
                       kSdkHelp);
}

// Copies the two XCFrameworks into <plugin>/ios/frameworks/, replacing what is there.
void copy_frameworks(Context& ctx, const stdfs::path& from, const std::string& folder) {
    const stdfs::path destination = stdfs::path(folder) / "ios" / "frameworks";
    std::vector<std::string> names;
    for (const char* name : kFrameworks) {
        const stdfs::path target = destination / name;
        if (!ctx.dryRun) {
            std::error_code ec;
            stdfs::create_directories(destination, ec);
            stdfs::remove_all(target, ec);
            ec.clear();
            stdfs::copy(from / name, target, stdfs::copy_options::recursive | stdfs::copy_options::copy_symlinks | stdfs::copy_options::overwrite_existing, ec);
            if (ec)
                throw CommandError("failed", "cannot copy " + (from / name).generic_string() + " to " + target.generic_string() + ": " + ec.message(),
                                   "Check that the plugin's folder can be written to, and run platform.add_backend again.");
        }
        ctx.wrote(target.generic_string());
        names.push_back(name);
    }
    ctx.done.push_back(std::string(ctx.dryRun ? "would copy " : "copied ") + join(names, " and ") + " from " + from.generic_string() + " into " +
                       destination.generic_string() + " (never commit them: the plugin's .gitignore keeps them out of git)");
}

bool frameworks_in_place(const std::string& folder) {
    return std::all_of(std::begin(kFrameworks), std::end(kFrameworks),
                       [&](const char* name) { return is_dir(stdfs::path(folder) / "ios" / "frameworks" / name); });
}

const std::vector<std::string>& all_platforms() {
    static const std::vector<std::string> platforms = {"android", "ios"};
    return platforms;
}

}  // namespace

Backend admob_backend() {
    Backend b;
    b.name = "admob";
    b.summary = "the AdMob ads plugin for Android and iOS: Google's consent form (UMP), App Tracking Transparency on iOS and rewarded ads. It offers only "
                "the \"ads\" service, so it works next to the store backend of the game. Android: a C bridge and a Java module (built with the Android "
                "SDK's NDK). iOS: Swift (built on a Mac with Xcode against Google's iOS SDK: \"sdk\", its zip or folder). macOS has no AdMob SDK: "
                "there the game has no ads.";
    b.properties = Json::object(
        {{"admobBuild",
          Json::object({{"type", "boolean"},
                        {"default", true},
                        {"description", "admob: false only writes the plugin and declares it, without building (any computer); build it later "
                                        "where the Android NDK (Android) or Xcode (iOS) is installed."}})},
         {"admobPlatforms",
          Json::object({{"type", "array"},
                        {"items", Json::object({{"type", "string"}, {"enum", Json::array({"android", "ios"})}})},
                        {"description", "admob: the platforms the plugin is declared and built for. Default: android and ios. The iOS part is built "
                                        "only on a Mac."}})},
         {"sdk",
          Json::object({{"type", "string"},
                        {"description", "(admob) Google's Mobile Ads SDK for iOS: its folder or the GoogleMobileAdsSdkiOS-*.zip from "
                                        "developers.google.com/admob/ios/quick-start. GoogleMobileAds.xcframework and UserMessagingPlatform.xcframework "
                                        "are copied from it into the plugin's ios/frameworks/ (git ignores them). Without it iOS is not built unless "
                                        "they are there already. Relative paths start in the project folder."}})}});
    b.run = [](Context& ctx) {
        const bool build = !ctx.args.contains("admobBuild") || !ctx.args["admobBuild"].is_boolean() || ctx.args["admobBuild"].get<bool>();
        std::vector<std::string> platforms = all_platforms();
        if (ctx.args.contains("admobPlatforms") && ctx.args["admobPlatforms"].is_array() && !ctx.args["admobPlatforms"].empty()) {
            platforms.clear();
            for (const Json& p : ctx.args["admobPlatforms"]) {
                const std::string name = p.is_string() ? p.get<std::string>() : std::string();
                if (std::find(all_platforms().begin(), all_platforms().end(), name) == all_platforms().end())
                    throw CommandError("invalid_argument", "admobPlatforms: '" + name + "' is not a platform of the AdMob plugin",
                                       did_you_mean(name, all_platforms()) + " AdMob has an SDK for android and ios only.");
                if (std::find(platforms.begin(), platforms.end(), name) == platforms.end()) platforms.push_back(name);
            }
        }
        const bool android = std::find(platforms.begin(), platforms.end(), "android") != platforms.end();
        const bool ios = std::find(platforms.begin(), platforms.end(), "ios") != platforms.end();
        const bool askedSdk = ctx.args.contains("sdk") && ctx.args["sdk"].is_string() && !ctx.args["sdk"].get<std::string>().empty();
        if (askedSdk && !ios)
            throw CommandError("invalid_argument", "\"sdk\" is Google's iOS SDK, but admobPlatforms has no ios",
                               "Add \"ios\" to admobPlatforms, or drop \"sdk\" (Android takes its SDK from Gradle).");
        const bool onMac = std::string(runtime_platform()) == "macos";

        // Check everything that can be wrong before anything is written: the toolchain and the SDK.
        NdkToolchain tc;
        if (android && build) tc = find_ndk_toolchain(ctx.androidSearch ? *ctx.androidSearch : default_android_toolchain_search(), "admob", "the AdMob plugin");
        Scratch scratch;
        std::optional<stdfs::path> sdkFrameworks;
        if (askedSdk) sdkFrameworks = resolve_sdk(ctx.args["sdk"].get<std::string>(), ctx.projectDir, scratch);

        // The plugin is declared for Android and iOS only: macOS has no AdMob SDK, so a Mac app has no ads (platform.has("ads") is false).
        const std::string folder = ctx.ensure_plugin(platforms);

        Json libraries = Json::array();
        if (android) {
            if (build) {
                build_android_abis(ctx, tc, folder);
                for (const Json& l : ctx.extra.value("libraries", Json::array())) libraries.push_back(l);
                ctx.cmakeExe.clear();  // the iOS build uses the CMake of this computer, not the Android SDK's
            } else {
                ctx.done.push_back("did not build Android (admobBuild is false): see the plugin's README.md in " + folder + " for the NDK commands");
            }
        }
        bool iosFrameworks = false;
        if (ios) {
            if (sdkFrameworks) copy_frameworks(ctx, *sdkFrameworks, folder);
            iosFrameworks = sdkFrameworks.has_value() || frameworks_in_place(folder);
            if (!build) {
                ctx.done.push_back("did not build iOS (admobBuild is false): on a Mac, cmake -S " + folder + " -B " + folder + "/build && cmake --build " +
                                   folder + "/build");
            } else if (!onMac) {
                ctx.done.push_back("did not build iOS: Swift and Google's iOS SDK need a Mac with Xcode, and this computer runs " +
                                   std::string(runtime_platform()) + " (the plugin is declared; build it on a Mac)");
            } else if (!iosFrameworks) {
                ctx.done.push_back("did not build iOS: Google's SDK is not in " + folder + "/ios/frameworks/ (pass \"sdk\")");
            } else if (ctx.dryRun) {
                ctx.done.push_back("would configure and build the admob plugin for iOS with Xcode (iphoneos, iphonesimulator)");
            } else {
                const std::vector<std::string> slices = {"iphoneos", "iphonesimulator"};
                ctx.run_cmake({"-S", folder, "-B", folder + "/build", "-DCMAKE_BUILD_TYPE=Release", "-DFA_ADMOB_SLICES=" + join(slices, ";")},
                              "configure the admob plugin for iOS");
                ctx.run_cmake({"--build", folder + "/build"}, "build the admob plugin for iOS");
                for (const std::string& slice : slices) {
                    const std::string rel = "ios/" + slice + "/lib" + ctx.backend + ".a";
                    if (!stdfs::exists(stdfs::path(folder) / rel))
                        throw CommandError("failed", "the build of the admob plugin left no " + folder + "/" + rel,
                                           "Look at the plugin's CMake output above; `cmake --build " + folder + "/build` repeats the build.");
                    libraries.push_back(rel);
                }
                ctx.done.push_back("built the iOS libraries with Xcode: " + libraries.dump());
            }
        }
        ctx.extra["libraries"] = libraries;
        ctx.extra["platforms"] = Json(platforms);

        // What the developer does by hand, with the ids of the game's own catalog.
        std::string packageName = "com.example.game";
        if (auto project = load_project(ctx.projectDir); project.ok()) packageName = project->id;
        std::vector<std::string> placements, missingUnits, missingUnitsIos;
        std::string appId, iosAppId, audience = "general";
        bool trackingPrompt = false;
        if (auto file = load_json_file(ctx.projectDir + "/" + kProjectFileName); file.ok() && file->is_object() && file->contains("platform")) {
            const PlatformCatalog catalog = parse_platform_catalog((*file)["platform"]).catalog;
            for (const PlatformPlacement& p : catalog.placements) {
                placements.push_back(p.id);
                if (!p.ids.count("admob")) missingUnits.push_back(p.id);
                if (!p.ids.count("admob_ios")) missingUnitsIos.push_back(p.id);
            }
            if (auto it = catalog.adsAppIds.find("android"); it != catalog.adsAppIds.end()) appId = it->second;
            if (auto it = catalog.adsAppIds.find("ios"); it != catalog.adsAppIds.end()) iosAppId = it->second;
            audience = catalog.adsAudience;
            trackingPrompt = catalog.adsTrackingPrompt;
        }

        ctx.extra["appId"] = appId;
        ctx.extra["iosAppId"] = iosAppId;
        ctx.extra["audience"] = audience;

        if (ios && build && onMac && !iosFrameworks)
            ctx.nextSteps.push_back("Download Google's Mobile Ads SDK for iOS (" + std::string(kSdkPage) + ", \"Download the SDK\") and run this command again with "
                                    "\"sdk\": \"<the .zip or the unpacked folder>\": it copies the two XCFrameworks into " + folder + "/ios/frameworks/ and builds the iOS "
                                    "libraries. Keep the download out of git.");
        else if (ios && (!onMac || !build))
            ctx.nextSteps.push_back(std::string("On a Mac with Xcode: `factoria call platform.add_backend '{\"backend\":\"admob\",\"sdk\":\"<the Google iOS SDK .zip or folder>\"}'` "
                                                "(") + kSdkPage + ") copies Google's XCFrameworks into " + folder + "/ios/frameworks/ and builds the iOS libraries; an iOS "
                                    "export needs those libraries and the frameworks (git ignores the frameworks: each clone copies them again) in the plugin's folder.");
        ctx.nextSteps.push_back(
            "Nothing else is needed to see ads in a development export: `factoria export --platform " + std::string(android ? "android" : "ios") +
            "` (without --release) always uses Google's test app id and test rewarded ad, which show test ads and earn nothing. Try that first "
            "(docs/PLATFORM.md, \"Ads\", has the emulator and simulator steps).");
        if (android)
            ctx.nextSteps.push_back(
                "AdMob console (admob.google.com), Android: add the app " + packageName + " (Apps > Add app; if it is not on Google Play yet, add it manually) and "
                "copy its app id (ca-app-pub-<16 digits>~<10 digits>, App settings) into factoria.json: \"platform\": {\"ads\": {\"appIds\": {\"android\": \"<the app id>\"}}}." +
                (appId.empty() ? std::string(" It is not set yet: a release export without it would stop at start.")
                               : " The catalog has " + appId + " already."));
        if (ios)
            ctx.nextSteps.push_back(
                "AdMob console, iOS: add the iOS app " + packageName + " (a separate app from the Android one; add it manually if it is not on the App Store yet) and "
                "copy its app id into factoria.json: \"platform\": {\"ads\": {\"appIds\": {\"ios\": \"<the app id>\"}}}." +
                (iosAppId.empty() ? std::string(" It is not set yet: a release export without it carries Google's sample app id.")
                                  : " The catalog has " + iosAppId + " already."));
        if (placements.empty()) {
            ctx.nextSteps.push_back("Ad units: declare the places the game shows ads in factoria.json's \"platform\".\"ads\".\"placements\" first (docs/PLATFORM.md), "
                                    "then create a rewarded ad unit for each in AdMob (Ad units > Add ad unit > Rewarded).");
        } else {
            if (android)
                ctx.nextSteps.push_back("Ad units (Android): create a rewarded ad unit in AdMob (Ad units > Add ad unit > Rewarded) for each placement (" + quoted_list(placements) +
                                        ") and copy its id (ca-app-pub-<16 digits>/<10 digits>) into platform.ads.placements[].ids.admob." +
                                        (missingUnits.empty() ? std::string()
                                                              : " The placements " + quoted_list(missingUnits) + " have no ids.admob yet: a release build cannot load an ad for them."));
            if (ios)
                ctx.nextSteps.push_back("Ad units (iOS): the same on the iOS app, one rewarded unit per placement (" + quoted_list(placements) + "), into "
                                        "platform.ads.placements[].ids.admob_ios (iOS units differ from Android's)." +
                                        (missingUnitsIos.empty() ? std::string()
                                                                 : " The placements " + quoted_list(missingUnitsIos) + " have no ids.admob_ios yet: a release iOS build cannot load an ad for them."));
        }
        ctx.nextSteps.push_back(
            "Consent: in AdMob > Privacy & messaging, create the GDPR message (European regulations) and, if you sell in the United States, the US states "
            "message, and publish them; without a published message the consent library has no form to show. The audience of the game is \"" + audience +
            "\" (platform.ads.audience): \"children\" for a game made for children, \"mixed\" for children and adults (the menu kit's ageGate part asks the age: "
            "`project.add_menu_kit {\"parts\":[\"ageGate\"]}`). Docs/PLATFORM.md, \"Children and consent\", says what each one does.");
        if (ios)
            ctx.nextSteps.push_back(
                std::string("App Tracking Transparency (iOS): the plugin asks for it only when \"platform\".\"ads\".\"trackingPrompt\" is true, and only after the consent form (never for a game "
                            "for children). ") +
                (trackingPrompt ? "The catalog turns it on: set \"trackingDescription\" (or \"trackingDescriptionKey\", a translation key) to the sentence of the sheet, "
                                  "which Apple reviews. "
                                : "It is off now, which is right for a game that does not track; turn it on only if the ads you serve need the IDFA. ") +
                "In AdMob > Privacy & messaging also create the IDFA explainer message if you ask for tracking.");
        ctx.nextSteps.push_back(std::string("Then `factoria export --platform ") + (android ? "android" : "ios") + "`" +
                                (android && ios ? " (or --platform ios)" : "") + ". " +
                                (android ? "On Android, Gradle adds the Mobile Ads SDK and the consent library from Google's Maven repository. " : "") +
                                (ios ? std::string("On iOS, the export links and embeds the XCFrameworks that ios/plugin.json lists and writes GADApplicationIdentifier and "
                                                   "SKAdNetworkItems into the Info.plist. ")
                                     : std::string()) +
                                "In a running game the command admob.status (fa.call) lists what the device lacks. Details and what each method does: "
                                "docs/PLATFORM.md, section Ads. Before a release, `factoria validate` warns about the sample app id or a missing app id.");
    };
    return b;
}

}  // namespace fa::platform_setup
