// iOS export: the game plus build_ios.sh, which configures the Xcode project with CMake; in prebuilt mode the project
// and the engine archives are written into the export as well. The modes are described in export_internal.h.
#include <algorithm>
#include <cctype>
#include <cstdint>
#include <filesystem>
#include <fstream>

#include "export_internal.h"
#include "fa/core/i18n.h"
#include "fa/core/json.h"
#include "fa/services/network.h"
#include "fa/services/platform.h"
#include "fa/tooling/ads_release.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/icons.h"
#include "fa/tooling/ios_privacy.h"
#include "fa/tooling/plugin_manifest.h"
#include "fa/tooling/setup.h"
#include "fa/tooling/storekit_config.h"

namespace fa::export_detail {

// ---- ios -----------------------------------------------------------------------------------------

namespace {

// The entitlements the plugins' manifests ask for, as the app's .entitlements file next to build_ios.sh.
constexpr const char* kIosEntitlementsFile = "factoria_player.entitlements";
// The privacy manifest of the app (fa/tooling/ios_privacy.h): the file App Store Connect wants at the root of the app bundle.
constexpr const char* kIosPrivacyManifestFile = "PrivacyInfo.xcprivacy";

// The extra Info.plist keys (the plugins' infoPlist and the ads plugin's), as the fragment build_ios.sh hands to CMake
// (-DFA_GAME_INFO_PLIST_EXTRA) for platforms/ios/Info.plist.in; and the per-language texts of the "Allow tracking" sheet.
constexpr const char* kIosInfoPlistExtraFile = "InfoPlistExtra.xml";
constexpr const char* kIosLocalizedStringsDir = "InfoPlist";

// An XCFramework is a folder with one slice per SDK: ios-arm64 (iPhone) and ios-arm64_x86_64-simulator (the simulator), each
// holding the <Name>.framework (or the lib<Name>.a) built for it. Empty when there is no slice for the SDK.
stdfs::path xcframework_slice(const stdfs::path& xcframework, bool simulator) {
    std::error_code ec;
    for (stdfs::directory_iterator it(os_path(xcframework), ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        if (name.rfind("ios-", 0) != 0 || !it->is_directory(ec)) continue;
        const auto ends = [&](const std::string& tail) { return name.size() >= tail.size() && name.compare(name.size() - tail.size(), tail.size(), tail) == 0; };
        if (ends("-maccatalyst")) continue;
        if (ends("-simulator") == simulator) return it->path();
    }
    return {};
}

// The binary of the framework (or the library) inside a slice; empty when the slice holds neither.
stdfs::path xcframework_binary(const stdfs::path& slice) {
    std::error_code ec;
    for (stdfs::directory_iterator it(os_path(slice), ec), end; !ec && it != end; it.increment(ec)) {
        const stdfs::path path = it->path();
        if (path.extension() == ".framework") return path / path.stem();
        if (path.extension() == ".a" && path.filename().string().rfind("lib", 0) == 0) return path;
    }
    return {};
}

// Whether a binary is a static library: an `ar` archive, or a universal ("fat") file whose first architecture is one. A static
// framework is linked into the app; only a dynamic one is embedded in it (Frameworks/) and signed with it.
bool is_static_library(const stdfs::path& binary) {
    std::ifstream in(os_path(binary), std::ios::binary);
    auto read = [&](std::uint64_t offset, std::size_t size) {
        std::string bytes(size, '\0');
        in.clear();
        in.seekg(static_cast<std::streamoff>(offset));
        in.read(bytes.data(), static_cast<std::streamsize>(size));
        bytes.resize(static_cast<std::size_t>(in.gcount()));
        return bytes;
    };
    auto be = [](const std::string& b, std::size_t at, std::size_t size) {
        std::uint64_t v = 0;
        for (std::size_t i = 0; i < size && at + i < b.size(); ++i) v = (v << 8) | static_cast<unsigned char>(b[at + i]);
        return v;
    };
    const std::string kArchive = "!<arch>\n";
    const std::string head = read(0, 32);
    if (head.compare(0, kArchive.size(), kArchive) == 0) return true;
    // Fat header (big endian): magic 0xCAFEBABE (32-bit offsets) or 0xCAFEBABF (64-bit), count, then one entry per architecture.
    if (head.size() < 24 || be(head, 0, 3) != 0xCAFEBA || (be(head, 3, 1) != 0xBE && be(head, 3, 1) != 0xBF) || be(head, 4, 4) == 0) return false;
    const std::uint64_t offset = be(head, 3, 1) == 0xBE ? be(head, 16, 4) : be(head, 16, 8);
    return read(offset, kArchive.size()) == kArchive;
}

// The text of a .strings file value.
std::string strings_escape(const std::string& text) {
    std::string out;
    for (char c : text) {
        if (c == '\\' || c == '"') out += '\\', out += c;
        else if (c == '\n') out += "\\n";
        else out += c;
    }
    return out;
}

// Prebuilt mode: the CMake project (CMakeLists.txt + cmake/) and the engine archives (lib/<sdk>/*.a) of the app.
Result<void> write_ios_prebuilt_project(const MobileSetup& setup, const stdfs::path& outRoot) {
    static const std::pair<const char*, const char*> kFiles[] = {
        {"platforms/ios/prebuilt/CMakeLists.txt", "CMakeLists.txt"},
        {"platforms/ios/plist.cmake", "cmake/plist.cmake"},
        {"platforms/ios/plugins.cmake", "cmake/plugins.cmake"},
        {"platforms/ios/Info.plist.in", "cmake/Info.plist.in"},
        {"platforms/common/copy_game.cmake", "cmake/copy_game.cmake"}};
    for (const auto& [from, to] : kFiles) {
        auto data = bundled_read(from);
        if (!data)
            return err(std::string("export: this factoria has no built-in iOS template ") + from, "this is an engine bug; report it");
        if (auto r = write_text(outRoot / to, *data); !r.ok()) return r;
    }
    std::error_code ec;
    for (const char* slice : kIosSlices) {
        stdfs::create_directories(os_path(outRoot / "lib" / slice), ec);
        for (stdfs::directory_iterator it(setup.libs / slice, ec), end; !ec && it != end; it.increment(ec)) {
            if (it->path().extension() != ".a") continue;
            std::error_code ec2;
            stdfs::copy_file(it->path(), os_path(outRoot / "lib" / slice / it->path().filename()), stdfs::copy_options::overwrite_existing, ec2);
            if (ec2) return err("export: cannot copy the prebuilt iOS library " + generic(it->path()) + ": " + ec2.message());
        }
    }
    return {};
}

}  // namespace

Result<void> export_ios(const ExportOptions& o, const Project& p, const MobileSetup& setup, const stdfs::path& outRoot,
                        const std::vector<std::string>& files, const Image& icon, ExportReport& report) {
    if (auto r = copy_game(p, files, outRoot / "game"); !r.ok()) return r;
    if (setup.prebuilt)
        if (auto r = write_ios_prebuilt_project(setup, outRoot); !r.ok()) return r;
    // Native plugins: each one's static libraries (<name>/iphoneos, <name>/iphonesimulator) next to build_ios.sh, which hands
    // them to CMake (-DFA_GAME_PLUGINS, -DFA_GAME_PLUGIN_DIR) so that the app links them (platforms/ios/plugins.cmake).
    // Each plugin's manifest (ios/plugin.json, fa/tooling/plugin_manifest.h) says which system frameworks and Swift runtime the
    // app must link and which capabilities (entitlements) it is signed with.
    std::string pluginNames;
    std::vector<NamedManifest> manifests;
    for (const Project::Plugin& plugin : p.plugins) {
        const stdfs::path dest = outRoot / "plugins" / plugin.name;
        std::error_code ec;
        stdfs::create_directories(os_path(dest), ec);
        stdfs::copy(os_path(plugin.build), os_path(dest), stdfs::copy_options::recursive | stdfs::copy_options::overwrite_existing, ec);
        if (ec) return err("export: cannot copy the plugin '" + plugin.name + "' (" + generic(plugin.build) + ") to " + generic(dest) +
                           ": " + ec.message());
        pluginNames += (pluginNames.empty() ? "" : ";") + plugin.name;
        auto manifest = read_plugin_manifest(plugin.build);
        if (!manifest.ok())
            return err("export: the manifest of the plugin '" + plugin.name + "': " + manifest.error().message, manifest.error().hint);
        manifests.push_back({plugin.name, manifest.value()});
    }
    auto merged = merge_plugin_manifests(manifests);
    if (!merged.ok()) return err("export: " + merged.error().message, merged.error().hint);
    const PluginManifest& needs = merged.value();
    const bool hasEntitlements = !needs.entitlements.empty();
    if (hasEntitlements)
        if (auto r = write_text(outRoot / kIosEntitlementsFile, entitlements_plist(needs.entitlements)); !r.ok()) return r;
    // Vendored XCFrameworks (the ads plugin's Google SDK, ...): they must be in the copied plugin; a static one is linked into
    // the app, a dynamic one is also embedded in it (platforms/ios/plugins.cmake picks the slice of the SDK it builds for).
    std::vector<std::string> embedXcframeworks;
    for (const std::string& xcframework : needs.xcframeworks) {
        const std::string plugin = xcframework.substr(0, xcframework.find('/'));
        const stdfs::path path = outRoot / "plugins" / xcframework;
        std::error_code ec;
        if (!stdfs::is_directory(os_path(path), ec))
            return err("export: the plugin '" + plugin + "' lists the XCFramework " + xcframework.substr(plugin.size() + 1) +
                           " in its ios/plugin.json but the plugin's ios/ folder does not have it",
                       "Put the .xcframework there. A vendor SDK is a download that the repository never holds: for the admob plugin run "
                       "`factoria call platform.add_backend '{\"backend\":\"admob\",\"sdk\":\"<the Google Mobile Ads SDK zip or folder>\"}'` "
                       "(docs/PLATFORM.md, \"Ads on iOS\"), which copies it in");
        const stdfs::path device = xcframework_slice(path, false);
        const stdfs::path simulator = xcframework_slice(path, true);
        if (device.empty() && simulator.empty())
            return err("export: " + xcframework + " has no iOS slice (ios-arm64, ios-arm64_x86_64-simulator)",
                       "Use the XCFramework built for iOS, not a macOS-only one");
        for (const auto& [slice, name] : {std::pair{device, "iPhone"}, std::pair{simulator, "iOS Simulator"}})
            if (slice.empty())
                report.warnings.push_back(xcframework + " has no slice for the " + name + ": " +
                                          (std::string(name) == "iPhone" ? "a device build" : "./build_ios.sh --simulator") + " will fail to link it");
        const stdfs::path binary = xcframework_binary(device.empty() ? simulator : device);
        if (binary.empty())
            return err("export: " + xcframework + " has no .framework or lib*.a in its iOS slice",
                       "An XCFramework holds <Name>.framework (or lib<Name>.a) in each ios-* folder; download it again");
        if (!is_static_library(binary)) embedXcframeworks.push_back(xcframework);
    }
    // The Info.plist keys of the plugins (plugin.json "infoPlist") plus the ones the export writes for the ads plugin: Google's
    // app id (a development export carries Google's sample), the test flag and audience the plugin reads, and the sentence of
    // the "Allow tracking" sheet (translated by an InfoPlist.strings per language of the game).
    const AdsIosSettings ads = ads_ios_settings(generic(p.dir), o.release);
    Json plist = needs.infoPlist.is_object() ? needs.infoPlist : Json::object();
    if (ads.present) {
        std::vector<std::pair<std::string, Json>> adsKeys = {
            {"GADApplicationIdentifier", ads.appId},
            {"FactoriaAdsTest", ads.test},
            {"FactoriaAdsAudience", ads.audience},
            {"FactoriaAdsTrackingPrompt", ads.trackingPrompt}};
        if (ads.trackingPrompt) adsKeys.push_back({"NSUserTrackingUsageDescription", ads.trackingDescription});
        if (!ads.trackingDescriptions.empty()) {
            Json languages = Json::array();
            for (const auto& [tag, text] : ads.trackingDescriptions) languages.push_back(tag);
            adsKeys.push_back({"CFBundleLocalizations", languages});
        }
        for (auto& [key, value] : adsKeys) {
            if (plist.contains(key))
                return err("export: " + key + " is in the infoPlist of a plugin and the export writes it for the ads plugin too",
                           "Remove it from the plugin's ios/plugin.json \"infoPlist\": the export takes it from factoria.json (platform.ads)");
            plist[key] = value;
        }
    }
    const bool hasInfoPlistExtra = !plist.empty();
    if (hasInfoPlistExtra)
        if (auto r = write_text(outRoot / kIosInfoPlistExtraFile, info_plist_entries(plist)); !r.ok()) return r;
    const bool hasLocalizedStrings = ads.present && ads.trackingPrompt && !ads.trackingDescriptions.empty();
    if (hasLocalizedStrings)
        for (const auto& [tag, text] : ads.trackingDescriptions)
            if (auto r = write_text(outRoot / kIosLocalizedStringsDir / (tag + ".lproj") / "InfoPlist.strings",
                                    "\"NSUserTrackingUsageDescription\" = \"" + strings_escape(text) + "\";\n");
                !r.ok())
                return r;
    if (o.release)
        for (const AdsIssue& i : check_ads(generic(p.dir), "ios")) report.warnings.push_back("factoria.json#" + i.pointer + ": " + i.message + ". " + i.hint);
    // The catalog's products as Products.storekit, whether or not the Apple plugin is declared or built (the plugin only matters
    // for the scheme): Xcode sells them to a run from Xcode without App Store Connect (build_ios.sh wires it into the scheme).
    // One localization per language of the game, from the products' titleKey / descriptionKey.
    bool hasStoreKit = false;
    {
        auto project = load_json_file(generic(p.dir / "factoria.json"));
        if (project.ok() && project->is_object() && project->contains("platform")) {
            const PlatformCatalog catalog = parse_platform_catalog((*project)["platform"]).catalog;
            if (!catalog.products.empty()) {
                auto script = bundled_read("platforms/ios/storekit_scheme.cmake");
                if (!script)
                    return err("export: this factoria has no built-in platforms/ios/storekit_scheme.cmake", "this is an engine bug; report it");
                std::vector<StoreKitLanguage> languages;
                const LocalizationSettings localization =
                    project->contains("localization") ? parse_localization((*project)["localization"]).settings : LocalizationSettings{};
                if (localization.enabled()) {
                    auto read_strings = [&](const std::string& tag) {
                        std::map<std::string, std::string> out;
                        const std::string file = "locales/" + tag + ".json";
                        auto doc = load_json_file(generic(p.dir / file));
                        if (!doc.ok()) return out;
                        auto table = parse_string_table(*doc, tag, file);
                        if (!table.ok()) return out;
                        for (const auto& [key, entry] : table->entries)
                            out[key] = entry.fallback_text();
                        return out;
                    };
                    const auto base = read_strings(localization.defaultLanguage);
                    for (const std::string& tag : localization.languages) {
                        StoreKitLanguage lang{tag, base};  // a key a language lacks falls back to the default language
                        for (auto& [key, text] : read_strings(tag)) lang.strings[key] = std::move(text);
                        languages.push_back(std::move(lang));
                    }
                }
                if (auto r = write_text(outRoot / kStoreKitFileName, dump_json(storekit_configuration(catalog, "apple", p.name, p.id, languages))); !r.ok())
                    return r;
                if (auto r = write_text(outRoot / "storekit_scheme.cmake", *script); !r.ok()) return r;
                hasStoreKit = true;
            }
        }
    }
    // The app icon: an asset catalog next to build_ios.sh, which hands it to CMake (-DFA_GAME_ASSET_CATALOG) so that Xcode
    // compiles it into the app (Assets.car + CFBundleIcons). The App Store icon has no transparency: it is composed over
    // export.ios.iconBackground.
    const IosExportSettings& ios = p.settings.ios;
    const bool hasIcon = !icon.empty();
    if (hasIcon)
        if (auto r = write_ios_app_icon(generic(outRoot / "Assets.xcassets"), icon, icon_color_from_hex(ios.iconBackground)); !r.ok()) return r;
    // The privacy manifest next to build_ios.sh, which hands it to CMake (-DFA_GAME_PRIVACY_MANIFEST) so that it lands in the app
    // bundle: App Store Connect rejects an upload whose app uses required-reason APIs without declaring them.
    // A game with an "analytics" section sends usage events once the player agrees (docs/ANALYTICS.md): the manifest declares
    // them as ProductInteraction for Analytics, not linked to the user and not used for tracking, unless export.ios.privacy
    // already lists that data type with that purpose.
    IosPrivacySettings privacy = ios.privacy;
    {
        auto project = load_json_file(generic(p.dir / "factoria.json"));
        if (project.ok() && project->is_object() && project->contains(kAnalyticsKey)) {
            const NetworkParse network = parse_network(project->contains(kNetworkKey) ? (*project)[kNetworkKey] : Json());
            const AnalyticsParse analytics = parse_analytics((*project)[kAnalyticsKey], network.policy);
            const auto lists = [&](const IosPrivacyCollectedData& d) {
                return d.type == "ProductInteraction" && std::find(d.purposes.begin(), d.purposes.end(), "Analytics") != d.purposes.end();
            };
            if (analytics.settings.configured && std::none_of(privacy.collectedData.begin(), privacy.collectedData.end(), lists)) {
                IosPrivacyCollectedData d;
                d.type = "ProductInteraction";
                d.purposes = {"Analytics"};
                privacy.collectedData.push_back(std::move(d));
                report.nextSteps.push_back("PrivacyInfo.xcprivacy declares the analytics events (ProductInteraction, purpose Analytics, not linked, no tracking): "
                                       "the game has an \"analytics\" section. Answer \"Product Interaction\" under Usage Data in App Store Connect (docs/LEGAL.md).");
            }
        }
    }
    if (auto r = write_text(outRoot / kIosPrivacyManifestFile, ios_privacy_manifest(privacy)); !r.ok()) return r;
    // The team id is 10 letters/digits (validated with the settings): it goes into the script as it is, inside "${VAR:-...}" where
    // single quotes would be kept literally.
    std::string team;
    for (char c : ios.teamId) if (std::isalnum(static_cast<unsigned char>(c))) team += c;
    const std::string buildNumber = safe_version_name(p.settings.ios_build_number().empty() ? p.version : p.settings.ios_build_number());
    const std::string config = o.release ? "Release" : "Debug";
    std::string s;
    s += "#!/usr/bin/env bash\n";
    s += "# Generated by `factoria export --platform ios` for \"" + replace_all(p.name, "\n", " ") + "\" (mode: " + report.mode + ").\n";
    s += setup.prebuilt ? "# Configures the Xcode project (CMakeLists.txt) with the game in ./game bundled; the engine is linked from the prebuilt\n"
                    "# libraries in ./lib, so no engine source is needed.\n"
                  : "# Configures the Xcode project (same settings as the `ios` CMake preset) with the game in ./game bundled.\n";
    s += "#   ./build_ios.sh                    Xcode project for a device, then opens it\n";
    s += "#   ./build_ios.sh --simulator        same for the iOS Simulator\n";
    s += "#   ./build_ios.sh --build            also compile (" + config + "). A device build needs a team (FA_IOS_DEVELOPMENT_TEAM" +
         (team.empty() ? std::string() : ", default " + team + " from export.ios.teamId of factoria.json") + ") and\n";
    s += "#                                     the iPhone/iPad connected (FA_IOS_DEVICE=<udid> picks one): the first build\n";
    s += "#                                     for a team registers it there. Simulator builds are not signed.\n";
    s += "#   ./build_ios.sh [--simulator] --run   build, install and start the game, its console in this terminal\n";
    s += "#   ./build_ios.sh --build -- <args>  everything after -- goes to xcodebuild\n";
    s += "# Needs macOS, Xcode (full app), CMake 3.24+.\n";
    s += "set -euo pipefail\n";
    s += "HERE=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\"\n";
    // CMake 3.24+: $FACTORIA_CMAKE, else the one this export found (`factoria setup cmake` installs one into ~/.factoria),
    // else cmake from PATH (the folder may be built on another Mac than the one that exported it).
    const std::string cmake = host_platform() == "macos" ? find_cmake() : std::string();
    s += "CMAKE=\"${FACTORIA_CMAKE:-}\"\n";
    s += "if [ -z \"$CMAKE\" ]; then\n  for c in " + (cmake.empty() ? std::string() : sh_quote(cmake) + " ") +
         "cmake; do if command -v \"$c\" >/dev/null 2>&1; then CMAKE=\"$c\"; break; fi; done\nfi\n";
    s += "[ -n \"$CMAKE\" ] || { echo \"CMake 3.24+ not found: run \\`factoria setup cmake\\` (or install CMake), or set FACTORIA_CMAKE\" >&2; exit 1; }\n";
    if (!setup.prebuilt) s += "ENGINE_DIR=\"${FACTORIA_ENGINE_DIR:-" + generic(setup.engine) + "}\"\n";
    s += "SYSROOT=iphoneos\nBUILD=0\nRUN=0\nXCODE_ARGS=()\n";
    s += "while [ $# -gt 0 ]; do\n  case \"$1\" in\n    --simulator) SYSROOT=iphonesimulator ;;\n    --build) BUILD=1 ;;\n"
         "    --run) BUILD=1; RUN=1 ;;\n"
         "    --) shift; XCODE_ARGS=(\"$@\"); break ;;\n"
         "    *) echo \"unknown option: $1 (options: --simulator, --build, --run, -- <xcodebuild arguments>)\" >&2; exit 2 ;;\n"
         "  esac\n  shift\ndone\n";
    if (!setup.prebuilt)
        s += "[ -f \"$ENGINE_DIR/CMakeLists.txt\" ] || { echo \"engine not found at $ENGINE_DIR: set FACTORIA_ENGINE_DIR\" >&2; exit 1; }\n";
    s += std::string("\"$CMAKE\" -S ") + (setup.prebuilt ? "\"$HERE\"" : "\"$ENGINE_DIR\"") + " -B \"$HERE/build\" -G Xcode \\\n"
         "  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=16.3 -DCMAKE_OSX_SYSROOT=\"$SYSROOT\" \\\n" +
         (setup.prebuilt ? "" : "  -DFA_BUILD_TOOLS=OFF -DFA_BUILD_TESTS=OFF \\\n") +
         "  -DFA_GAME_PROJECT_DIR=\"$HERE/game\" \\\n"
         "  -DFA_GAME_BUNDLE_ID=" + sh_quote(p.id) + " \\\n"
         "  -DFA_GAME_NAME=" + sh_quote(p.name) + " \\\n"
         "  -DFA_GAME_VERSION=" + sh_quote(safe_version_name(p.version)) + " \\\n"
         "  -DFA_GAME_BUILD=" + sh_quote(buildNumber) + " \\\n"
         "  -DFA_GAME_ORIENTATION=" + sh_quote(p.orientation) + " \\\n" +
         (hasIcon ? "  -DFA_GAME_ASSET_CATALOG=\"$HERE/Assets.xcassets\" \\\n" : "") +
         "  -DFA_GAME_PRIVACY_MANIFEST=\"$HERE/" + kIosPrivacyManifestFile + "\" \\\n" +
         (ios.usesNonExemptEncryption ? "  -DFA_GAME_NON_EXEMPT_ENCRYPTION=ON \\\n" : "") +
         (pluginNames.empty() ? "" : "  -DFA_GAME_PLUGINS=" + sh_quote(pluginNames) + " -DFA_GAME_PLUGIN_DIR=\"$HERE/plugins\" \\\n") +
         (needs.frameworks.empty() ? "" : "  -DFA_GAME_PLUGIN_FRAMEWORKS=" + sh_quote(join(needs.frameworks, ";")) + " \\\n") +
         (needs.swift ? "  -DFA_GAME_PLUGIN_SWIFT=ON \\\n" : "") +
         (needs.xcframeworks.empty() ? ""
                                     : "  -DFA_GAME_PLUGIN_XCFRAMEWORKS=" + sh_quote(join(needs.xcframeworks, ";")) +
                                           (embedXcframeworks.empty() ? "" : " -DFA_GAME_PLUGIN_EMBED_XCFRAMEWORKS=" + sh_quote(join(embedXcframeworks, ";"))) +
                                           " \\\n") +
         (hasInfoPlistExtra ? std::string("  -DFA_GAME_INFO_PLIST_EXTRA=\"$HERE/") + kIosInfoPlistExtraFile + "\" \\\n" : "") +
         (hasLocalizedStrings ? std::string("  -DFA_GAME_LOCALIZED_STRINGS=\"$HERE/") + kIosLocalizedStringsDir + "\" \\\n" : "") +
         (hasEntitlements ? std::string("  -DFA_GAME_ENTITLEMENTS=\"$HERE/") + kIosEntitlementsFile + "\" \\\n" : "") +
         (hasStoreKit ? "  -DFA_GAME_STOREKIT=ON \\\n" : "") +
         "  -DFA_IOS_DEVELOPMENT_TEAM=\"${FA_IOS_DEVELOPMENT_TEAM:-" + team + "}\"\n" +
         (hasStoreKit ? std::string("# Running the project from Xcode sells the products of ") + kStoreKitFileName + " (no App Store Connect needed).\n"
                        "\"$CMAKE\" -DPROJECT=\"$HERE/build/FactorIA.xcodeproj\" -DSTOREKIT=\"$HERE/" + kStoreKitFileName +
                        "\" -P \"$HERE/storekit_scheme.cmake\"\n"
                      : "");
    std::string build = R"SH(if [ "$BUILD" = 0 ]; then
  echo "Open $HERE/build/FactorIA.xcodeproj, pick the 'factoria_player' scheme, set Signing & Capabilities > Team, press Run."
  open "$HERE/build/FactorIA.xcodeproj" 2>/dev/null || true
  exit 0
fi
CONFIG=@CONFIG@
BUNDLE_ID=@BUNDLE_ID@
# The connected iPhone or iPad (FA_IOS_DEVICE=<udid> picks one).
device_udid() {
  if [ -n "${FA_IOS_DEVICE:-}" ]; then echo "$FA_IOS_DEVICE"; return; fi
  local list; list="$(mktemp)"
  if xcrun devicectl list devices --json-output "$list" >/dev/null 2>&1; then
    python3 -c 'import json, sys
for d in json.load(open(sys.argv[1]))["result"]["devices"]:
    hw, conn = d.get("hardwareProperties", {}), d.get("connectionProperties", {})
    if hw.get("reality") == "physical" and hw.get("platform") == "iOS" and conn.get("tunnelState") == "connected":
        print(hw["udid"]); break' "$list"
  fi
  rm -f "$list"
}
# A booted simulator, else the first iPhone of the newest iOS runtime.
simulator_udid() {
  xcrun simctl list devices available -j | python3 -c 'import json, sys
data = json.load(sys.stdin)["devices"]
def version(key): return [int(p) for p in key.rsplit(".", 1)[-1].split("-")[1:] if p.isdigit()]
runtimes = sorted((k for k in data if ".iOS-" in k), key=version, reverse=True)
devices = [d for k in runtimes for d in data[k] if d.get("isAvailable", True)]
pick = [d for d in devices if d["state"] == "Booted"] or [d for d in devices if d["name"].startswith("iPhone")]
print(pick[0]["udid"] if pick else "")'
}
if [ "$SYSROOT" = iphonesimulator ]; then
  # Simulator apps need no team: build unsigned, then sign ad hoc as Xcode does for the simulator.
  "$CMAKE" --build "$HERE/build" --config "$CONFIG" --target factoria_player -- -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO \
    ${XCODE_ARGS[@]+"${XCODE_ARGS[@]}"}
else
  # A scheme build with a destination (not cmake --build, which builds a target and ignores the destination), so that
  # Xcode can register the connected device with the team and create the provisioning profile on the first build.
  DEVICE="$(device_udid)"
  if [ -n "$DEVICE" ]; then
    DESTINATION="id=$DEVICE"
  else
    DESTINATION="generic/platform=iOS"
    echo "note: no iPhone or iPad connected: building for any device. A team's first build needs the device connected," >&2
    echo "      unlocked and in Developer Mode (Settings > Privacy & Security), so Xcode can register it." >&2
  fi
  xcodebuild -project "$HERE/build/FactorIA.xcodeproj" -scheme factoria_player -configuration "$CONFIG" \
    -destination "$DESTINATION" -allowProvisioningUpdates -allowProvisioningDeviceRegistration build \
    ${XCODE_ARGS[@]+"${XCODE_ARGS[@]}"}
fi
APP="$(find "$HERE/build" -maxdepth 4 -type d -path "*/$CONFIG-$SYSROOT/factoria_player.app" | head -n 1)"
[ -n "$APP" ] || { echo "error: the build left no factoria_player.app for $SYSROOT under $HERE/build" >&2; exit 1; }
echo "Built $APP"
[ "$RUN" = 1 ] || exit 0
if [ "$SYSROOT" = iphonesimulator ]; then
  codesign --force --sign - --timestamp=none "$APP"
  SIM="$(simulator_udid)"
  [ -n "$SIM" ] || { echo "error: no iOS simulator; add one in Xcode (Settings > Components)" >&2; exit 1; }
  xcrun simctl boot "$SIM" 2>/dev/null || true
  open -a Simulator 2>/dev/null || true
  xcrun simctl bootstatus "$SIM" -b >/dev/null
  xcrun simctl install "$SIM" "$APP"
  echo "Starting $BUNDLE_ID in the simulator; its console follows (Ctrl+C ends the game)."
  exec xcrun simctl launch --terminate-running-process --console-pty "$SIM" "$BUNDLE_ID"
fi
[ -n "$DEVICE" ] || { echo "error: connect an iPhone or iPad (unlocked, Developer Mode on) to run the game on it" >&2; exit 1; }
xcrun devicectl device install app --device "$DEVICE" "$APP"
echo "Starting $BUNDLE_ID on the device; its console follows (Ctrl+C ends the game)."
exec xcrun devicectl device process launch --console --terminate-existing --device "$DEVICE" "$BUNDLE_ID"
)SH";
    build = replace_all(build, "@CONFIG@", config);
    build = replace_all(build, "@BUNDLE_ID@", sh_quote(p.id));
    s += build;
    if (auto r = write_text(outRoot / "build_ios.sh", s, true); !r.ok()) return r;
    report.nextSteps = {
        "On a Mac with Xcode and CMake 3.24+, copy or open this folder: cd '" + generic(outRoot) + "'",
        "./build_ios.sh --simulator --run   builds the game, starts it in the iOS Simulator and shows its console",
        "On an iPhone/iPad (connected, unlocked, Developer Mode on): " +
            std::string(team.empty() ? "FA_IOS_DEVELOPMENT_TEAM=<TEAMID> ./build_ios.sh --run (or set export.ios.teamId in factoria.json). "
                                     : "./build_ios.sh --run (team " + team + " from export.ios.teamId in factoria.json; "
                                       "FA_IOS_DEVELOPMENT_TEAM overrides it). ") +
            "Or ./build_ios.sh creates build/FactorIA.xcodeproj and opens it: select the 'factoria_player' scheme, set a "
            "Team under Signing & Capabilities (bundle id " + p.id + "), then Run",
        std::string(setup.prebuilt ? "Mode prebuilt: the engine is linked from lib/, copied from " + generic(setup.libs) + " (no engine source needed). "
                                   : "Mode source: the engine is compiled from " + generic(setup.engine) + ". ") +
            "Build number (CFBundleVersion) " + buildNumber + (hasIcon ? ", app icon from Assets.xcassets" : ", no app icon (set `icon` in factoria.json)") +
            ". Details and App Store notes: docs/MOBILE.md"};
    report.nextSteps.push_back(std::string(kIosPrivacyManifestFile) + " is the app's privacy manifest (the engine's required-reason APIs; nothing collected, no tracking) and Info.plist says "
                               "ITSAppUsesNonExemptEncryption " + (ios.usesNonExemptEncryption ? "true" : "false") +
                               ". If the game or a plugin collects data, tracks or calls more required-reason APIs, add export.ios.privacy in factoria.json "
                               "(docs/MOBILE.md, \"Store privacy forms\")");
    if (hasEntitlements) {
        std::vector<std::string> names;
        for (auto it = needs.entitlements.begin(); it != needs.entitlements.end(); ++it) names.push_back(it.key());
        report.nextSteps.push_back(
            "The plugins ask for capabilities (" + join(names, ", ") + "): " + std::string(kIosEntitlementsFile) +
            " is the app's entitlements file, so Xcode's automatic signing turns them on for the App ID of " + p.id +
            " (a device build needs the Team). They need the matching services set up in App Store Connect: docs/PLATFORM.md");
    }
    if (!needs.xcframeworks.empty()) {
        std::string linked;
        for (const std::string& x : needs.xcframeworks) linked += (linked.empty() ? "" : ", ") + x.substr(x.find('/') + 1);
        report.nextSteps.push_back("The plugins bring XCFrameworks (" + linked + "), copied to plugins/ with them: build_ios.sh links them into the app" +
                                   (embedXcframeworks.empty() ? " (all static, so none is embedded)"
                                                              : " and embeds the dynamic ones (" + std::to_string(embedXcframeworks.size()) + ") in Frameworks/"));
    }
    if (ads.present && ads.trackingPrompt && !ios.privacy.tracking)
        report.warnings.push_back("platform.ads.trackingPrompt is true but export.ios.privacy.tracking is not: PrivacyInfo.xcprivacy says the app does not "
                                  "track while the app shows the \"Allow tracking\" sheet. Set \"export\": {\"ios\": {\"privacy\": {\"tracking\": true, "
                                  "\"trackingDomains\": [...]}}} (docs/MOBILE.md, \"Store privacy forms\")");
    if (ads.present) {
        report.nextSteps.push_back(
            "The ads plugin: Info.plist carries GADApplicationIdentifier " + ads.appId +
            (o.release ? (ads.appId == kAdmobSampleAppIdIos ? " (Google's sample: set platform.ads.appIds.ios, a release shows test ads that earn nothing)" : "")
                       : " (Google's sample app: a development export always shows test ads; export with --release and platform.ads.appIds.ios for real ones)") +
            (ads.trackingPrompt
                 ? ", and NSUserTrackingUsageDescription is the sentence of the \"Allow tracking\" sheet" +
                       std::string(hasLocalizedStrings ? " (one InfoPlist.strings per language of the game)" : "") +
                       ": the plugin shows it after Google's consent form. " +
                       std::string(ios.privacy.tracking
                                       ? "PrivacyInfo.xcprivacy says the app tracks (export.ios.privacy.tracking) and lists " +
                                             std::to_string(ios.privacy.trackingDomains.size()) +
                                             " tracking domain(s): the ad network's go in export.ios.privacy.trackingDomains. Answer \"Data Used to Track You\" in App Store Connect"
                                       : "An app that asks to track declares it: export.ios.privacy.tracking true and the tracking domains, and "
                                         "\"Data Used to Track You\" in App Store Connect")
                 : ". platform.ads.trackingPrompt is off: the app never asks to track, so Google's SDK gets no advertising identifier"));
    }
    if (hasStoreKit)
        report.nextSteps.push_back(std::string("Running the project from Xcode sells the products of ") + kStoreKitFileName +
                                   " (generated from factoria.json's platform.products), no App Store Connect needed; if the scheme "
                                   "shows StoreKit Configuration: None, pick the file under Product > Scheme > Edit Scheme > Run > Options. "
                                   "./build_ios.sh --run (simctl launch) does not use it");
    return {};
}

}  // namespace fa::export_detail
