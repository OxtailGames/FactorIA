// The rules of the Graphics settings window (View > Graphics): the project's `render.graphicsPreset` and
// `render.upscaler` (mode, quality, sharpness) in factoria.json (M76, docs/UPSCALING.md), read, checked and saved. No
// ImGui here, so the tests of the editor (tools/editor/tests/graphics_settings_tests.cpp) run it without a window;
// graphics_settings_panel.cpp only draws it.
//
// The checks are the engine's own: the upscaler goes through fa::render::parse_upscaler_settings and the preset through
// fa::render::parse_graphics_preset, the code the project loader, the command render.upscaler and graphics.preset read
// the same values with, so what this window accepts is what the AI can write in the file and the reverse. Saving patches
// only those two keys of the file's text (fa::patch_json_text): every other key, the order and the formatting stay.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::editor {

// What the window edits. The defaults are what factoria.json means when the keys are missing.
struct GraphicsSettings {
    std::string preset = "custom";   // low, medium, high, ultra or custom
    std::string mode = "stretch";    // stretch, spatial, temporal, metalfx or auto
    std::string quality = "native";  // native, quality, balanced, performance or ultraPerformance
    double sharpness = 0.5;          // 0..1: the sharpen of the spatial and temporal modes
    bool operator==(const GraphicsSettings&) const = default;
};

// One wrong field: the JSON pointer into factoria.json, what is wrong and how to fix it.
struct GraphicsSettingsProblem {
    std::string pointer;  // "/render/graphicsPreset", "/render/upscaler/mode", ".../quality" or ".../sharpness"
    std::string message;  // the engine's own sentence (with a "did you mean" for a misspelt name)
};

// The valid values, in the order the combos list them.
const std::vector<std::string>& graphics_presets();
const std::vector<std::string>& upscaler_modes();
const std::vector<std::string>& upscaler_qualities();

// The settings of `json` (a parsed factoria.json). Missing keys are the defaults; a wrong value is an error naming its place.
Result<GraphicsSettings> graphics_settings_from_json(const Json& json, const std::string& file = "factoria.json");
// Reads <projectDir>/factoria.json.
Result<GraphicsSettings> read_graphics_settings(const std::string& projectDir);

// Every problem of `s`, each with its pointer (empty = fine). Nothing is saved or changed.
std::vector<GraphicsSettingsProblem> check_graphics_settings(const GraphicsSettings& s);

// Writes `s` into <projectDir>/factoria.json: `render.graphicsPreset` (removed when custom) and `render.upscaler` (removed
// when every value is the default; else the three keys), and an empty `render` object is removed. Refuses, and writes
// nothing, when check_graphics_settings finds a problem (the error is its first message) or the file is not valid JSON.
Result<void> write_graphics_settings(const std::string& projectDir, const GraphicsSettings& s);

}  // namespace fa::editor
