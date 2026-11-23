// The graphics presets of the engine (M76, docs/UPSCALING.md "Graphics presets"): game.graphics, graphics.preset and graphics.detect.
//
// A preset is a quality layer of the renderer (fa/render/graphics_preset.h): limits on what the scene asks for, plus the upscaler setting.
// The scene, its components and the project file are never written; `custom` takes the layer away and puts the upscaler back that the
// game had before the first preset, so the game looks as its author made it. Nothing here reads the simulation, and the benchmark of
// graphics.detect draws a world of its own.
#include <cmath>

#include "engine_impl.h"
#include "fa/core/strings.h"
#include "fa/render/gpu_info.h"

namespace fa {

namespace {

using render::GraphicsPreset;

std::vector<std::string> preset_names() {
    std::vector<std::string> n;
    for (std::string_view v : render::kGraphicsPresetNames) n.emplace_back(v);
    return n;
}

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

Json upscaler_json(const render::UpscalerSettings& s, render::UpscalerMode effective) {
    Json out = render::upscaler_to_json(s);
    out["effectiveMode"] = std::string(render::upscaler_mode_name(effective));
    out["scale"] = round3(double(render::upscaler_quality_scale(s.quality)));
    return out;
}

// {knob, from, to} for every limit that differs.
Json diff_limits(const render::QualityLimits& before, const render::QualityLimits& after) {
    Json out = Json::array();
    const Json a = render::quality_limits_to_json(before), b = render::quality_limits_to_json(after);
    for (const std::string& knob : render::quality_knob_names())
        if (a[knob] != b[knob]) out.push_back(Json::object({{"knob", knob}, {"from", a[knob]}, {"to", b[knob]}}));
    return out;
}

Json caps_json(const render::QualityResolved& r) {
    Json caps = Json::array();
    for (const render::QualityCap& c : r.capped)
        caps.push_back(
            Json::object({{"knob", c.knob}, {"wanted", c.wanted}, {"effective", c.effective}, {"reason", c.reason}}));
    return caps;
}

}  // namespace

void Engine::Impl::apply_graphics_quality() {
    if (!renderer || !renderer->initialized()) return;
    if (graphicsPreset == GraphicsPreset::Custom) {
        graphicsLimits = render::QualityLimits{};
    } else {
        graphicsLimits = renderer->resolve_graphics_preset(graphicsPreset).limits;
    }
    renderer->set_quality(graphicsLimits);
    renderStale = true;
}

Json Engine::graphics_preset(const Json& args, std::string* error) {
    Impl& I = *impl_;
    const auto fail = [&](const std::string& msg) {
        if (error) *error = msg;
        return Json();
    };
    if (!args.is_null() && !args.is_object())
        return fail(std::string("graphics.preset: the arguments are an object like {\"name\": \"high\"}, got ") +
                    args.type_name() + ".");
    std::optional<GraphicsPreset> wanted;
    if (args.is_object()) {
        const std::vector<std::string> known = {"name"};
        for (auto it = args.begin(); it != args.end(); ++it)
            if (it.key() != "name")
                return fail("graphics.preset: unknown argument '" + it.key() + "'. " + did_you_mean(it.key(), known) +
                            " Pass {\"name\": \"high\"} to apply a preset, or no argument to read the current one.");
        if (args.contains("name") && !args["name"].is_null()) {
            if (!args["name"].is_string())
                return fail(
                    std::string("graphics.preset: `name` is a string (one of low, medium, high, ultra, custom), got ") +
                    args["name"].type_name() + ".");
            const std::string name = args["name"].get<std::string>();
            wanted = render::parse_graphics_preset(name);
            if (!wanted)
                return fail("graphics.preset: unknown preset '" + name + "'. " + did_you_mean(name, preset_names()) +
                            " The names are low, medium, high, ultra and custom.");
        }
    }
    const GraphicsPreset previous = I.graphicsPreset;
    const render::QualityLimits limitsBefore = I.graphicsLimits;
    const render::UpscalerSettings upscalerBefore = upscaler();
    render::QualityResolved resolved = I.renderer && I.renderer->initialized()
                                           ? I.renderer->resolve_graphics_preset(wanted.value_or(previous))
                                           : render::resolve_graphics_preset_uncapped(wanted.value_or(previous));
    if (wanted) {
        const GraphicsPreset p = *wanted;
        // The upscaler: a preset writes it (the game's own setting is kept for `custom`), `custom` puts the game's own back.
        I.applyingPreset = true;
        if (p == GraphicsPreset::Custom) {
            if (I.upscalerBeforePreset) {
                set_upscaler(render::upscaler_to_json(*I.upscalerBeforePreset), "graphics.preset");
                I.upscalerBeforePreset.reset();
            }
        } else {
            if (!I.upscalerBeforePreset) I.upscalerBeforePreset = upscaler();
            // A preset with no upscaler of its own (ultra) leaves the game's own: the one before the first preset.
            const render::UpscalerSettings target = resolved.upscaler ? *resolved.upscaler : *I.upscalerBeforePreset;
            if (target != upscaler()) set_upscaler(render::upscaler_to_json(target), "graphics.preset");
        }
        I.applyingPreset = false;
        I.graphicsPreset = p;
        I.graphicsLimits = p == GraphicsPreset::Custom ? render::QualityLimits{} : resolved.limits;
        if (I.renderer && I.renderer->initialized()) I.renderer->set_quality(I.graphicsLimits);
        I.renderStale = true;
    }
    Json changes = diff_limits(limitsBefore, I.graphicsLimits);
    if (upscaler() != upscalerBefore)
        changes.push_back(Json::object({{"knob", "upscaler"},
                                        {"from", render::upscaler_to_json(upscalerBefore)},
                                        {"to", render::upscaler_to_json(upscaler())}}));
    Json out = Json::object();
    out["preset"] = std::string(render::graphics_preset_name(I.graphicsPreset));
    out["previous"] = std::string(render::graphics_preset_name(previous));
    out["changed"] = !changes.empty() || previous != I.graphicsPreset;
    out["changes"] = changes;
    out["limits"] = render::quality_limits_to_json(I.graphicsLimits);
    out["capped"] = I.graphicsPreset == GraphicsPreset::Custom ? Json::array() : caps_json(resolved);
    out["upscaler"] = upscaler_json(upscaler(), effective_upscaler_mode());
    out["headless"] = !resolved.gpu;
    return out;
}

Json Engine::graphics_detect(std::string* error) {
    (void)error;
    Impl& I = *impl_;
    const bool hasRenderer = I.renderer && I.renderer->initialized();
    const render::GpuInfo gpu = hasRenderer ? render::query_gpu_info() : render::GpuInfo{};
    render::GpuBenchmark bench;
    if (hasRenderer)
        bench = render::run_gpu_benchmark(*I.renderer, gpu);
    else
        bench.why = "the engine runs without graphics (graphics=false)";
    const Json device = device_info();
    render::DeviceClass cls;
    cls.tier = device.value("tier", std::string("medium"));
    cls.formFactor = device.value("formFactor", std::string("desktop"));
    cls.handheld = device.value("handheld", false);
    const render::PresetSuggestion s = render::suggest_graphics_preset(gpu, bench, cls);
    Json out = Json::object();
    out["preset"] = std::string(render::graphics_preset_name(s.preset));
    out["reason"] = s.reason;
    out["gpu"] = gpu.to_json();
    out["benchmarkMs"] = bench.totalMs;
    out["benchmark"] = bench.to_json();
    out["device"] = Json::object({{"tier", cls.tier}, {"formFactor", cls.formFactor}, {"handheld", cls.handheld}});
    return out;
}

}  // namespace fa
