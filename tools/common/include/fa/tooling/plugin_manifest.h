// The manifest of a native plugin: what the app that ships it must do for it (docs/MOBILE.md, "Native plugins (iOS)").
//
//   <plugin>/ios/plugin.json                       <plugin>/macos/plugin.json
//   { "frameworks": ["StoreKit", "GameKit"],       { "entitlements": {
//     "swift": true,                                   "com.apple.developer.game-center": true } }
//     "entitlements": {
//       "com.apple.developer.game-center": true,
//       "com.apple.developer.ubiquity-kvstore-identifier": "$(TeamIdentifierPrefix)$(CFBundleIdentifier)" } }
//
//   frameworks    system frameworks the plugin's code uses: the iOS app links them (a static library cannot)
//   swift         true: the plugin is written in Swift, the iOS app gets the Swift runtime
//   entitlements  capabilities the signed app needs: merged into the app's .entitlements file
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
    bool empty() const { return frameworks.empty() && !swift && entitlements.empty(); }
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
// plugin uses it, the entitlements merged. Two plugins that ask for the same entitlement with different values are an Error
// that names both and says how to settle it.
Result<PluginManifest> merge_plugin_manifests(const std::vector<NamedManifest>& manifests);

// The entitlements as an Apple property list (the .entitlements file Xcode and codesign read). Keys keep their order.
std::string entitlements_plist(const Json& entitlements);

}  // namespace fa
