// The graphics settings of the project file (the Graphics window of the editor, View > Graphics, and the command project.graphics): the project's `render.graphicsPreset`,
// `render.upscaler` (mode, quality, sharpness), `render.dynamicResolution` (enabled, targetMs, minScale, maxScale) (M76, docs/UPSCALING.md) and `render.latency` (mode, boost; M78, docs/LATENCY.md) in factoria.json, read, checked and saved. No
// ImGui here, so the tests of the editor (tools/common/tests/graphics_settings_test.cpp) run it without a window;
// tools/editor/src/graphics_settings_panel.cpp only draws it.
//
// The checks are the engine's own: the upscaler goes through fa::render::parse_upscaler_settings and the preset through
// fa::render::parse_graphics_preset and the dynamic resolution through fa::render::parse_dynamic_resolution_settings, the code the project loader, the command render.upscaler and graphics.preset read
// the same values with, so what this window accepts is what the AI can write in the file and the reverse. Saving patches
// only those four keys of the file's text (fa::patch_json_text): every other key, the order and the formatting stay.
#pragma once

#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/render/dynamic_resolution.h"

namespace fa {

// What the window edits. The defaults are what factoria.json means when the keys are missing.
struct GraphicsSettings {
    std::string preset = "custom";   // low, medium, high, ultra or custom
    std::string mode = "stretch";    // stretch, spatial, temporal, metalfx, dlss, xess, fsr or auto
    std::string quality = "native";  // native, quality, balanced, performance or ultraPerformance
    double sharpness = 0.5;          // 0..1: the sharpen of the spatial and temporal modes
    // render.dynamicResolution: off, no target (0 = one refresh of the display), the range 0.5..1.
    render::DynamicResolutionSettings dynamic;
    // render.latency (M78, docs/LATENCY.md): the low-latency mode (off, auto, reflex, antilag2 or xell) and its boost.
    std::string latencyMode = "off";
    bool latencyBoost = false;
    bool operator==(const GraphicsSettings&) const = default;
};

// One wrong field: the JSON pointer into factoria.json, what is wrong and how to fix it.
struct GraphicsSettingsProblem {
    std::string
        pointer;  // "/render/graphicsPreset", "/render/upscaler/mode", ".../quality", ".../sharpness" or "/render/dynamicResolution/<key>" or "/render/latency/<key>"
    std::string message;  // the engine's own sentence (with a "did you mean" for a misspelt name)
};

// The valid values, in the order the combos list them.
const std::vector<std::string>& graphics_presets();
const std::vector<std::string>& upscaler_modes();
const std::vector<std::string>& upscaler_qualities();
const std::vector<std::string>& latency_modes();
// Whether `mode` of latency_modes() has a boost switch (the SDKs that keep the GPU clocks up: Reflex and XeLL, and auto, which may pick
// one of them); the others ignore it.
bool latency_mode_has_boost(const std::string& mode);

// The settings of `json` (a parsed factoria.json). Missing keys are the defaults; a wrong value is an error naming its place.
// `round` (the editor's model, the default) rounds targetMs to tenths and minScale / maxScale to hundredths, the steps
// of its sliders; the command project.graphics reads with `round` false and so never rewrites a number it was not asked
// to.
Result<GraphicsSettings> graphics_settings_from_json(const Json& json, const std::string& file = "factoria.json",
                                                     bool round = true);
// Reads <projectDir>/factoria.json.
Result<GraphicsSettings> read_graphics_settings(const std::string& projectDir, bool round = true);

// Every problem of `s`, each with its pointer (empty = fine). Nothing is saved or changed.
std::vector<GraphicsSettingsProblem> check_graphics_settings(const GraphicsSettings& s);

// Writes `s` into <projectDir>/factoria.json: `render.graphicsPreset` (removed when custom), `render.upscaler` (removed
// when every value is the default; else the three keys) and `render.dynamicResolution` (removed when every value is the
// default; else the four keys), `render.latency` (removed when off with no boost; else the two keys), and an empty `render` object is removed. Refuses, and writes
// nothing, when check_graphics_settings finds a problem (the error is its first message) or the file is not valid JSON.
Result<void> write_graphics_settings(const std::string& projectDir, const GraphicsSettings& s);

// project.graphics: reads, and with `preset`, `upscaler`, `dynamicResolution` or `latency` writes, the four keys above in <projectDir>/factoria.json
// (what the editor's Graphics window does), for the CLI, MCP and AIs. The live commands graphics.preset, render.upscaler,
// render.dynamic_resolution and render.latency change the running game only.
void register_graphics_settings_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
