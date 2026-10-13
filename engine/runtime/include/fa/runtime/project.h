// Project file: <project>/factoria.json
//
// {
//   "format": "factoria.project/1",
//   "name": "Space Dodge",
//   "id": "com.example.spacedodge",          // reverse-DNS, used for mobile bundles
//   "version": "0.1.0",
//   "engine": "0.1",                          // engine version the game was made with
//   "mainScene": "scenes/main.scene.json",
//   "display": { "width": 1280, "height": 720, "scaleMode": "fit",
//                "fullscreen": false, "vsync": true, "orientation": "landscape",
//                "pixelArt": false },
//   "physics": { "fixedHz": 60, "pixelsPerMeter": 100 },
//   "input": { "actions": { "jump": ["Space", "W"] } },
//   "platforms": ["windows", "macos", "linux", "ios", "android"],
//   "feedbackFile": "ENGINE_FEEDBACK.json"
// }
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/render/renderer.h"

namespace fa {

inline constexpr const char* kProjectFileName = "factoria.json";
inline constexpr const char* kFeedbackFileName = "ENGINE_FEEDBACK.json";

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
    double fixedHz = 60.0;
    float pixelsPerMeter = 100.0f;
    Json inputActions = Json::object();
    std::vector<std::string> platforms;
    std::string feedbackFile = kFeedbackFileName;
    Json raw;  // the whole file, for fields the engine does not model yet

    Json to_json() const;
};

// Loads <dir>/factoria.json (lenient, with defaults). Errors name the field.
Result<ProjectSettings> load_project(std::string_view projectDir);
Result<void> save_project(std::string_view projectDir, const ProjectSettings& settings);
// Walks up from `startDir` looking for factoria.json ("" if none).
std::string find_project_root(std::string_view startDir);
Json project_json_schema();

}  // namespace fa
