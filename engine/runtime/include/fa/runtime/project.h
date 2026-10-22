// Project file: <project>/factoria.json
//
// {
//   "format": "factoria.project/1",
//   "name": "Space Dodge",
//   "id": "com.example.spacedodge",          // reverse-DNS, used for mobile bundles
//   "version": "0.1.0",
//   "engine": "0.1",                          // engine version the game was made with
//   "mainScene": "scenes/main.scene.json",
//   "display": { "width": 1280, "height": 720, "scaleMode": "fit",   // fit | stretch | expand | pixel-perfect
//                "fullscreen": false, "vsync": true, "orientation": "landscape",
//                "pixelArt": false },
//   "physics": { "fixedHz": 60, "pixelsPerMeter": 100 },
//   "input": { "actions": { "jump": ["Space", "W"] }, "deadzone": 0.2 },   // deadzone: gamepad sticks and triggers
//   "platforms": ["windows", "macos", "linux", "ios", "android"],
//   "feedbackFile": "ENGINE_FEEDBACK.json",
//   "icon": "assets/icon.png",                // the game icon; export.<platform>.icon replaces it for one platform
//   "localization": { "defaultLanguage": "en", "languages": ["en", "es", "ja"],       // BCP 47 tags; locales/<language>.json
//                     "fallbackFonts": ["assets/fonts/NotoSansArabic-Regular.ttf"],   // fonts for what the main font lacks
//                     "languageFonts": { "zh-Hans": ["assets/fonts/NotoSansSC-Regular.ttf"] } },   // docs/LOCALIZATION.md
//   "plugins": { "example": { "path": "plugins/example", "platforms": ["windows"] } },   // native plugins: fa/runtime/plugins.h
//   "export": { ... }                         // per-platform export settings: fa/tooling/export_settings.h, docs/EXPORTING.md
// }
#pragma once

#include <map>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/render/renderer.h"

namespace fa {

inline constexpr const char* kProjectFileName = "factoria.json";
inline constexpr const char* kFeedbackFileName = "ENGINE_FEEDBACK.json";

// The asset type of a project file, from its name (case-insensitive): "texture" (.png .jpg .jpeg .tga .bmp), "audio" (.wav .ogg
// .mp3 .qoa), "font" (.ttf .otf), "mesh" (.obj .gltf .glb), "script" (.js), "scene" (.scene.json), "prefab" (.prefab.json),
// "material" (.material.json) or "other". The one classifier: assets.list, the Inspector's asset fields and the Project panel use it.
std::string asset_type_of(std::string_view path);

// One native plugin of "plugins" (fa/runtime/plugins.h, docs/EXTENDING.md "Native plugins").
struct PluginSettings {
    std::string name;                    // the key: [a-z][a-z0-9_]*, the plugins.<name> of scripts and the prefix of its commands
    std::string path;                    // its folder as written: project-relative or absolute, ${VAR} = an environment variable
    std::vector<std::string> platforms;  // the platforms it is built for; empty = the project's `platforms` (all five without)
    bool optional = false;               // the game runs without it: a missing build for this computer is a validate warning, not an error
};

// The "localization" section (docs/LOCALIZATION.md). No section = `languages` is empty = localization is off and the game behaves as
// before.
struct LocalizationSettings {
    std::string defaultLanguage;                           // one of `languages`; the language of headless runs and the last fallback
    std::vector<std::string> languages;                    // BCP 47 tags in the order language menus list them; each has locales/<tag>.json
    std::vector<std::string> fallbackFonts;                // project-relative .ttf/.otf for every language, after the main font
    std::map<std::string, std::vector<std::string>> languageFonts;  // per language: tried before fallbackFonts

    bool enabled() const { return !languages.empty(); }
    // The fonts a Text in `language` falls back to when its own font lacks a glyph: languageFonts[language] (else of its base
    // language: zh-Hans-CN -> zh-Hans -> zh), then fallbackFonts, without repeats. Parsed and stored here; fa_render uses it.
    std::vector<std::string> fallback_fonts_for(std::string_view language) const;
};

// One problem of the "localization" section, with the JSON pointer it is at ("/localization/languages/1").
struct LocalizationIssue {
    std::string pointer, message, hint;
};
struct LocalizationParse {
    LocalizationSettings settings;
    std::vector<LocalizationIssue> issues;    // every problem found; `settings` is only usable without any
    std::vector<LocalizationIssue> warnings;  // keys the engine does not know (a typo), with "did you mean"
    bool ok() const { return issues.empty(); }
};
// Reads the value of "localization" (null = the section is absent = off). Reports every mistake with its pointer, a fix and a
// "did you mean".
LocalizationParse parse_localization(const Json& section);

struct ProjectSettings {
    std::string name = "Untitled";
    std::string id = "com.example.game";
    std::string version = "0.1.0";
    std::string engineVersion = FA_ENGINE_VERSION;
    std::string mainScene = "scenes/main.scene.json";
    int width = 1280;
    int height = 720;
    ScaleMode scaleMode = ScaleMode::Fit;
    bool fullscreen = false;
    bool vsync = true;
    std::string orientation = "landscape";  // "landscape" | "portrait" | "any" (mobile)
    bool pixelArt = false;
    bool pauseOnSuspend = true;  // "pauseOnSuspend": freeze the game and the music while the app is in the background (docs/MOBILE.md, "Lifecycle")
    double fixedHz = 60.0;
    float pixelsPerMeter = 100.0f;
    Json inputActions = Json::object();
    double inputDeadzone = 0.2;  // gamepad sticks (radial) and triggers; 0 <= value < 1 (see Input::set_gamepad_deadzone)
    std::vector<std::string> platforms;
    std::string feedbackFile = kFeedbackFileName;
    std::string icon;  // "icon": project-relative path of the game icon (a square PNG/JPG); "" = none
    std::vector<PluginSettings> plugins;  // "plugins", sorted by name
    LocalizationSettings localization;    // "localization": languages and fonts; off when the section is absent
    Json raw;  // the whole file, for fields the engine does not model yet

    // The icon file the window of THIS platform shows: `export.<platform>.icon` of the file (windows | macos | linux |
    // android | ios, the platform the engine was built for), else `icon`. "" = none. Lenient: a value of the wrong type
    // counts as unset (`factoria validate` reports it).
    std::string window_icon() const;
    // The platforms `plugin` is built for: its own `platforms`, else the project's, else all five.
    std::vector<std::string> plugin_platforms(const PluginSettings& plugin) const;

    Json to_json() const;
};

// Loads <dir>/factoria.json (lenient, with defaults). Errors name the field.
Result<ProjectSettings> load_project(std::string_view projectDir);
Result<void> save_project(std::string_view projectDir, const ProjectSettings& settings);
// Walks up from `startDir` looking for factoria.json ("" if none).
std::string find_project_root(std::string_view startDir);
Json project_json_schema();

// The platform this engine was built for: "windows", "macos", "linux", "android", "ios" or "web".
const char* runtime_platform();
// The platform names (windows, macos, linux, ios, android, web), in that order.
const std::vector<std::string>& platform_names();

// scaleMode spellings: "fit" | "stretch" | "expand" | "pixel-perfect" (parsing is case-insensitive and also
// accepts "pixelPerfect" / "pixel_perfect"). scale_mode_name returns the canonical spelling.
const char* scale_mode_name(ScaleMode mode);
bool parse_scale_mode(std::string_view text, ScaleMode& out);

}  // namespace fa
