// The graphics settings of the project file (the Graphics window of the editor, View > Graphics, and the command project.graphics): the project's `render.graphicsPreset`,
// `render.upscaler` (mode, quality, sharpness), `render.dynamicResolution` (enabled, targetMs, minScale, maxScale) (M76, docs/UPSCALING.md) and `render.latency` (mode, boost; M78, docs/LATENCY.md) and `render.frameGeneration` (mode, minBaseFps; M78, docs/FRAME_GENERATION.md), `render.rayTracing` and `render.pathTracer` (M79, docs/RAY_TRACING.md) in factoria.json, read, checked and saved. No
// ImGui here, so the tests of the editor (tools/common/tests/graphics_settings_test.cpp) run it without a window;
// tools/editor/src/graphics_settings_panel.cpp only draws it.
//
// The checks are the engine's own: the upscaler goes through fa::render::parse_upscaler_settings and the preset through
// fa::render::parse_graphics_preset and the dynamic resolution through fa::render::parse_dynamic_resolution_settings, the code the project loader, the command render.upscaler and graphics.preset read
// the same values with, so what this window accepts is what the AI can write in the file and the reverse. Saving patches
// only those seven keys of the file's text (fa::patch_json_text): every other key, the order and the formatting stay.
#pragma once

#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/render/dynamic_resolution.h"
#include "fa/render/framegen.h"
#include "fa/render/raytracing.h"

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
    // render.frameGeneration (M78, docs/FRAME_GENERATION.md): the frame-generation mode (off, auto, dlss, fsr or xess) and the base frame rate below
    // which it switches off.
    std::string frameGenMode = "off";
    int frameGenMinBaseFps = render::kFrameGenDefaultMinBaseFps;
    // render.rayTracing and render.pathTracer (M79, docs/RAY_TRACING.md): the effects a run starts with and the reference path tracer.
    render::RayTracingSettings rayTracing;
    render::PathTracerSettings pathTracer;
    bool operator==(const GraphicsSettings&) const = default;
};

// One wrong field: the JSON pointer into factoria.json, what is wrong and how to fix it.
struct GraphicsSettingsProblem {
    std::string
        pointer;  // "/render/graphicsPreset", "/render/upscaler/mode", ".../quality", ".../sharpness" or "/render/dynamicResolution/<key>", "/render/latency/<key>" or "/render/frameGeneration/<key>", "/render/rayTracing/<key>" or "/render/pathTracer/<key>"
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
// The values of render.rayTracing.shadows and .gi in the order the combos list them.
const std::vector<std::string>& ray_tracing_shadow_modes();
const std::vector<std::string>& ray_tracing_gi_modes();
// A mode of render.rayTracing.gi the file may name (the parser accepts it) but no renderer draws yet: "" when it is drawn, else the sentence
// the editor shows next to it. perPixel waits for its package (M79-P4b); take its name out of the list in graphics_settings.cpp when it lands.
std::string ray_tracing_gi_coming(const std::string& mode);

// Whether this machine's renderer can trace rays (the row `raytracing` of render.supports, `report` being what Renderer::supports_report()
// returns), with the row's own reason when it cannot, followed by how to get a device that does (graphics.backend). Without a report (no
// renderer to ask) it cannot, with that as the reason. A project is written for the players' machines, so a device that cannot trace only
// greys the controls out in the editor: the file may still ask for rays.
struct RayTracingSupport {
    bool usable = true;
    std::string why;
};
RayTracingSupport ray_tracing_support(const Json& supportsReport);

// What the graphics preset of `s` does to its ray tracing setting, one sentence, or "" when it changes nothing (no preset, ray tracing off,
// or the preset allows everything the setting asks for): "The preset low switches off shadows, ao ... at run time: the settings below are the
// project's own, the preset only caps them."
std::string ray_tracing_preset_note(const GraphicsSettings& s);

// The frame-generation modes in the order the combo lists them (off, auto, dlss, fsr, xess), and the render.supports row of each SDK mode.
const std::vector<std::string>& frame_gen_modes();

// What the renderer says of one frame-generation mode (the rows dlssFrameGen, fsrFrameGen and xessFrameGen of render.supports, `report` being
// what Renderer::supports_report() returns): usable here, or the provider's reason it is not. off and auto are always usable (auto picks the
// SDK of the GPU's maker when there is one that can run, else nothing runs). Without a report (no renderer to ask) an SDK mode is not usable, with
// that as the reason; a report without the row (an older engine) leaves the mode usable. A project is written for the players' machines, not for
// this one, so a mode that is not usable here is only greyed out in the editor: the file may still name it.
struct FrameGenModeSupport {
    bool usable = true;
    std::string why;
};
FrameGenModeSupport frame_gen_mode_support(const Json& supportsReport, const std::string& mode);

// The sentence under the mode combo: what `mode` does on this machine (from the same rows), what minBaseFps does, and, for auto, which SDKs
// can run here. No newline.
std::string frame_gen_describe(const GraphicsSettings& s, const Json& supportsReport);

// The advice the latency setting calls for, or empty when there is none: frame generation adds a delay of about a frame, so it wants a
// low-latency mode. Empty while frame generation is off or render.latency is not off. For "dlss" it says the SDK turns Reflex on itself; for
// "auto" that the SDK of an NVIDIA GPU does.
std::string frame_gen_latency_hint(const GraphicsSettings& s);

// The one-line state of the profiler's readout (Engine::profile_frame_generation(): {provider, state, baseFps, presentedFps, generatedFrames,
// reason}): "active (dlss): base 62.1 fps, presented 124.0 fps, 3021 generated", "paused (below the minimum): ...", or the refusal reason.
// `minBaseFps` words the paused state. An empty or malformed readout says off.
std::string frame_gen_state_line(const Json& readout, int minBaseFps);

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
// default; else the four keys), `render.latency` (removed when off with no boost; else the two keys), `render.frameGeneration` (removed when off at the default minBaseFps; else the two keys), `render.rayTracing` and `render.pathTracer` (removed when every value is the default; else every key), and an empty `render` object is removed. Refuses, and writes
// nothing, when check_graphics_settings finds a problem (the error is its first message) or the file is not valid JSON.
Result<void> write_graphics_settings(const std::string& projectDir, const GraphicsSettings& s);

// project.graphics: reads, and with `preset`, `upscaler`, `dynamicResolution`, `latency`, `frameGeneration`, `rayTracing` or `pathTracer` writes, the keys above in <projectDir>/factoria.json
// (what the editor's Graphics window does), for the CLI, MCP and AIs. The live commands graphics.preset, render.upscaler,
// render.dynamic_resolution, render.latency and render.frame_generation change the running game only.
void register_graphics_settings_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
