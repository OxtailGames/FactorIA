// The manifest of a native plugin: what the app that ships it must do for it (docs/MOBILE.md, "Native plugins (iOS)").
//
//   <plugin>/ios/plugin.json                       <plugin>/macos/plugin.json
//   { "frameworks": ["StoreKit", "GameKit"],       { "entitlements": {
//     "swift": true,                                   "com.apple.developer.game-center": true } }
//     "xcframeworks": ["frameworks/Vendor.xcframework"],
//     "infoPlist": { "SKAdNetworkItems": [ ... ] },
//     "entitlements": {
//       "com.apple.developer.game-center": true,
//       "com.apple.developer.ubiquity-kvstore-identifier": "$(TeamIdentifierPrefix)$(CFBundleIdentifier)" } }
//
//   frameworks    system frameworks the plugin's code uses: the iOS app links them (a static library cannot)
//   swift         true: the plugin is written in Swift, the iOS app gets the Swift runtime
//   entitlements  capabilities the signed app needs: merged into the app's .entitlements file
//   xcframeworks  third-party XCFrameworks the plugin vendors, as paths inside the folder of this plugin.json (ios/): the iOS app
//                 links the slice of the SDK it builds for and embeds the dynamic ones (a static framework is linked only)
//   infoPlist     entries added to the app's Info.plist: any JSON value (text, true/false, number, list, object), such as the
//                 ad network's SKAdNetworkItems
//
// The file is optional (a plugin without one needs nothing) and is read by the exports only; the plugin never sees it.
// Everything here reads and writes text only, so it works the same on every host.
#pragma once

#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr const char* kPluginManifestFile = "plugin.json";

struct PluginManifest {
    std::vector<std::string> frameworks;  // "StoreKit" (no ".framework"); no duplicates
    bool swift = false;
    Json entitlements = Json::object();   // key -> bool | integer | string | array of strings
    // "frameworks/Vendor.xcframework": relative to the plugin.json's folder, forward slashes, no "..". Merged over several plugins
    // (merge_plugin_manifests) each one becomes "<plugin>/<path>": relative to the export's plugins/ folder.
    std::vector<std::string> xcframeworks;
    Json infoPlist = Json::object();      // Info.plist key -> any JSON value but null
    bool empty() const {
        return frameworks.empty() && !swift && entitlements.empty() && xcframeworks.empty() && infoPlist.empty();
    }
};

// Parses the text of a plugin.json. `file` names it in the errors, which carry the JSON pointer of the problem, say what is
// wrong and how to fix it (an unknown key gets a "did you mean").
Result<PluginManifest> parse_plugin_manifest(const std::string& text, const std::string& file);

// <folder>/plugin.json; no such file is an empty manifest, not an error.
Result<PluginManifest> read_plugin_manifest(const std::filesystem::path& folder);

struct NamedManifest {
    std::string plugin;
    PluginManifest manifest;
};

// What the app needs for all its plugins together: the union of the frameworks (first appearance order), `swift` when any
// plugin uses it, the entitlements and the Info.plist entries merged, the XCFrameworks prefixed with their plugin's name. Two
// plugins that ask for the same entitlement or Info.plist key with different values are an Error that names both and says how
// to settle it.
Result<PluginManifest> merge_plugin_manifests(const std::vector<NamedManifest>& manifests);

// `<key>..</key><value>` pairs for the dictionary of an Info.plist (one tab of indentation, ready to paste before </dict>): the
// entries of PluginManifest::infoPlist, or any JSON object of text, true/false, numbers, lists and objects.
std::string info_plist_entries(const Json& entries);

// The entitlements as an Apple property list (the .entitlements file Xcode and codesign read). Keys keep their order.
std::string entitlements_plist(const Json& entitlements);

}  // namespace fa
