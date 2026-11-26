#include "fa/tooling/graphics_settings.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <optional>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/render/dynamic_resolution.h"
#include "fa/render/framegen.h"
#include "fa/render/graphics_preset.h"
#include "fa/render/latency.h"
#include "fa/render/raytracing.h"
#include "fa/render/upscaler.h"
#include "fa/tooling/json_patch.h"

namespace fa {

namespace {

constexpr const char* kFile = "factoria.json";

std::string project_file_path(const std::string& projectDir) {
    return (projectDir.empty() ? std::string(".") : projectDir) + "/" + kFile;
}

Json upscaler_json(const GraphicsSettings& s) {
    Json j = Json::object();
    j["mode"] = s.mode;
    j["quality"] = s.quality;
    j["sharpness"] = s.sharpness;
    return j;
}

Json dynamic_json(const GraphicsSettings& s) { return render::dynamic_resolution_to_json(s.dynamic); }

Json latency_json(const GraphicsSettings& s) {
    Json j = Json::object();
    j["mode"] = s.latencyMode;
    j["boost"] = s.latencyBoost;
    return j;
}

Json frame_gen_json(const GraphicsSettings& s) {
    Json j = Json::object();
    j["mode"] = s.frameGenMode;
    j["minBaseFps"] = s.frameGenMinBaseFps;
    return j;
}

Json ray_tracing_json(const GraphicsSettings& s) { return render::ray_tracing_to_json(s.rayTracing); }
Json path_tracer_json(const GraphicsSettings& s) { return render::path_tracer_to_json(s.pathTracer); }

// The render.supports row (feature name) of a frame-generation SDK mode, or null for off and auto.
const char* frame_gen_row_name(const std::string& mode) {
    return mode == "dlss" ? "dlssFrameGen" : mode == "fsr" ? "fsrFrameGen" : mode == "xess" ? "xessFrameGen" : nullptr;
}

std::string fixed1(double v) {
    char buf[48];
    std::snprintf(buf, sizeof buf, "%.1f", std::isfinite(v) ? v : 0.0);
    return buf;
}

}  // namespace

const std::vector<std::string>& frame_gen_modes() {
    static const std::vector<std::string> v(render::kFrameGenModeNames.begin(), render::kFrameGenModeNames.end());
    return v;
}

const std::vector<std::string>& ray_tracing_shadow_modes() {
    static const std::vector<std::string> v(render::kRtShadowsNames.begin(), render::kRtShadowsNames.end());
    return v;
}
const std::vector<std::string>& ray_tracing_gi_modes() {
    static const std::vector<std::string> v(render::kRtGiNames.begin(), render::kRtGiNames.end());
    return v;
}

std::string ray_tracing_gi_coming(const std::string& mode) {
    // The modes no renderer draws yet (the parser accepts them). Empty when every mode draws.
    if (mode == "perPixel")
        return "Coming: a bounce traced for every pixel is not drawn yet. The file may name it; until it is made it "
               "changes nothing in the picture.";
    return {};
}

RayTracingSupport ray_tracing_support(const Json& supportsReport) {
    RayTracingSupport r;
    const auto features = supportsReport.is_object() ? supportsReport.find("features") : supportsReport.end();
    if (features == supportsReport.end() || !features->is_array()) {
        r.usable = false;
        r.why = "The editor has no GPU to ask whether this machine can trace rays.";
        return r;
    }
    for (const Json& f : *features) {
        if (!f.is_object() || f.value("name", std::string()) != "raytracing") continue;
        r.usable = f.value("supported", false);
        if (!r.usable)
            r.why = f.value("status", std::string("This device cannot trace rays.")) +
                    " Choose a backend that traces with graphics.backend (d3d12 or vulkan on Windows, vulkan on "
                    "Linux and Android, metal on macOS and iOS).";
        return r;
    }
    r.usable = false;
    r.why = "This engine has no ray tracing row in render.supports.";
    return r;
}

std::string ray_tracing_preset_note(const GraphicsSettings& s) {
    const auto preset = render::parse_graphics_preset(s.preset);
    if (!preset || *preset == render::GraphicsPreset::Custom || !s.rayTracing.enabled) return {};
    const render::RayTracingSettings eff =
        render::apply_quality_to_ray_tracing(s.rayTracing, render::graphics_preset_table(*preset).limits);
    if (eff == s.rayTracing) return {};
    std::string dropped;
    const auto add = [&](const char* what) { dropped += (dropped.empty() ? "" : ", ") + std::string(what); };
    if (eff.shadows != s.rayTracing.shadows)
        add(eff.shadows == render::RtShadows::Off ? "shadows (off)" : "shadows (hard)");
    if (eff.ao != s.rayTracing.ao) add("ao");
    if (eff.reflections != s.rayTracing.reflections) add("reflections");
    if (eff.translucency != s.rayTracing.translucency) add("translucency");
    if (eff.gi != s.rayTracing.gi) add(eff.gi == render::RtGi::Off ? "gi (off)" : "gi (probes)");
    if (eff.raysPerPixel != s.rayTracing.raysPerPixel)
        add(("raysPerPixel (" + std::to_string(eff.raysPerPixel) + ")").c_str());
    return "The preset \"" + s.preset + "\" caps the ray tracing of a run: " + dropped +
           ". These settings are the project's own; the preset only lowers them while it is on, and never turns an "
           "effect on.";
}

FrameGenModeSupport frame_gen_mode_support(const Json& supportsReport, const std::string& mode) {
    FrameGenModeSupport r;
    const char* row = frame_gen_row_name(mode);
    if (!row) return r;
    const auto features = supportsReport.is_object() ? supportsReport.find("features") : supportsReport.end();
    if (features == supportsReport.end() || !features->is_array()) {
        r.usable = false;
        r.why = "The editor has no GPU to ask whether this mode can run here.";
        return r;
    }
    for (const Json& f : *features) {
        if (!f.is_object() || f.value("name", std::string()) != row) continue;
        r.usable = f.value("supported", false);
        if (!r.usable) r.why = f.value("status", std::string("not available here"));
        return r;
    }
    return r;
}

namespace {

// The frames per second at which generation comes back after it was switched off for a low rate: 10% above minBaseFps.
int resume_fps(int minBaseFps) { return int(std::lround(double(minBaseFps) * 1.1)); }

}  // namespace

std::string frame_gen_describe(const GraphicsSettings& s, const Json& supportsReport) {
    const std::string& mode = s.frameGenMode;
    if (mode == "off")
        return "Off: no SDK is loaded and the swapchain is the engine's own; the display shows the frames the game "
               "renders.";
    std::string head;
    if (mode == "auto") {
        std::string usable;
        for (const char* sdk : {"dlss", "fsr", "xess"})
            if (frame_gen_mode_support(supportsReport, sdk).usable)
                usable += (usable.empty() ? "" : ", ") + std::string(sdk);
        if (usable.empty())
            return "Auto: no SDK can run on this machine, so a run shows the rendered frames only (NVIDIA dlss, AMD "
                   "fsr and Intel xess each need their SDK and a game window on Direct3D 12 or Vulkan).";
        head = "Auto: the SDK of the GPU's maker when it can run (usable on this machine: " + usable +
               "), else the rendered frames only.";
    } else {
        const FrameGenModeSupport row = frame_gen_mode_support(supportsReport, mode);
        if (!row.usable)
            return "Not usable on this machine: " + row.why + " A run of the game shows the rendered frames only.";
        head = "Usable on this machine: a run of the game with a window on Direct3D 12 or Vulkan uses " + mode +
               " frame generation while the temporal upscaler runs.";
    }
    if (s.frameGenMinBaseFps > 0)
        head += " It switches off while the game renders fewer than " + std::to_string(s.frameGenMinBaseFps) +
                " frames per second, and on again above " + std::to_string(resume_fps(s.frameGenMinBaseFps)) + ".";
    else
        head += " It never switches off for a low frame rate (minBaseFps 0).";
    return head;
}

std::string frame_gen_latency_hint(const GraphicsSettings& s) {
    if (s.frameGenMode == "off" || s.latencyMode != "off") return {};
    std::string hint =
        "Frame generation adds about one frame of delay to the input. A low-latency mode (Low latency, above) is "
        "recommended with it.";
    if (s.frameGenMode == "dlss")
        hint += " DLSS frame generation turns NVIDIA Reflex on by itself while it runs, whatever Low latency says.";
    else if (s.frameGenMode == "auto")
        hint += " On an NVIDIA GPU the SDK is DLSS, which turns NVIDIA Reflex on by itself while it runs.";
    return hint;
}

std::string frame_gen_state_line(const Json& readout, int minBaseFps) {
    if (!readout.is_object() || readout.empty()) return "Off: nothing is generated.";
    // A key that is null or of another type (a readout from an older or broken engine) falls back to its default: value() would throw.
    const auto text = [&](const char* key, const char* fallback) {
        const auto it = readout.find(key);
        return it != readout.end() && it->is_string() ? it->get<std::string>() : std::string(fallback);
    };
    const auto number = [&](const char* key) {
        const auto it = readout.find(key);
        return it != readout.end() && it->is_number() ? it->get<double>() : 0.0;
    };
    const std::string state = text("state", "off");
    const std::string provider = text("provider", "none");
    const std::string why = text("reason", "");
    const double generated = number("generatedFrames");
    const std::string rates =
        "base " + fixed1(number("baseFps")) + " fps, presented " + fixed1(number("presentedFps")) + " fps, " +
        std::to_string(generated >= 0.0 && generated < 1.8e19 ? static_cast<std::uint64_t>(generated) : 0) +
        " generated";
    if (state == "active") return "Active (" + provider + "): " + rates + ".";
    if (state == "measuring") return "Measuring the base frame rate (" + provider + "): " + rates + ".";
    if (state == "paused")
        return "Switched off, the base frame rate is below the minimum of " + std::to_string(minBaseFps) + " fps (" +
               provider + "): " + rates + ". It comes back above " + std::to_string(resume_fps(minBaseFps)) + " fps.";
    return (state == "refused" ? "Refused: " : "Off: ") + (why.empty() ? std::string("nothing is generated.") : why);
}

const std::vector<std::string>& graphics_presets() {
    static const std::vector<std::string> v(render::kGraphicsPresetNames.begin(), render::kGraphicsPresetNames.end());
    return v;
}
const std::vector<std::string>& upscaler_modes() {
    static const std::vector<std::string> v(render::kUpscalerModeNames.begin(), render::kUpscalerModeNames.end());
    return v;
}
const std::vector<std::string>& latency_modes() {
    static const std::vector<std::string> v(render::kLatencyModeNames.begin(), render::kLatencyModeNames.end());
    return v;
}
bool latency_mode_has_boost(const std::string& mode) { return mode == "auto" || mode == "reflex" || mode == "xell"; }
const std::vector<std::string>& upscaler_qualities() {
    static const std::vector<std::string> v(render::kUpscalerQualityNames.begin(), render::kUpscalerQualityNames.end());
    return v;
}

std::vector<GraphicsSettingsProblem> check_graphics_settings(const GraphicsSettings& s) {
    std::vector<GraphicsSettingsProblem> out;
    if (!render::parse_graphics_preset(s.preset))
        out.push_back({"/render/graphicsPreset", std::string(kFile) +
                                                     "#/render/graphicsPreset: unknown graphics preset \"" + s.preset +
                                                     "\". " + did_you_mean(s.preset, graphics_presets())});
    // One key at a time, so each problem has its own pointer (the engine's parser reports the first wrong key).
    for (const char* key : {"mode", "quality", "sharpness"}) {
        Json one = Json::object();
        const Json all = upscaler_json(s);
        one[key] = all[key];
        if (std::string(key) == "sharpness" && !std::isfinite(s.sharpness)) one[key] = "not a number";
        auto r = render::parse_upscaler_settings(one, std::string(kFile) + "#/render/upscaler", {});
        if (!r.ok()) out.push_back({std::string("/render/upscaler/") + key, r.error().message + " " + r.error().hint});
    }
    // The dynamic resolution the same way: each key alone (against the widest range, so only its own number is judged), then the pair.
    const std::string where = std::string(kFile) + "#/render/dynamicResolution";
    const render::DynamicResolutionSettings wide{false, 0.0, render::kDynamicScaleFloor, render::kDynamicScaleCeiling};
    const Json dyn = dynamic_json(s);
    bool rangeBad = false;
    for (const char* key : {"enabled", "targetMs", "minScale", "maxScale"}) {
        Json one = Json::object();
        one[key] = dyn[key];
        if (std::string(key) != "enabled" && !(dyn[key].is_number() && std::isfinite(dyn[key].get<double>())))
            one[key] = "not a number";
        auto r = render::parse_dynamic_resolution_settings(one, where, wide);
        if (!r.ok()) {
            out.push_back({std::string("/render/dynamicResolution/") + key, r.error().message + " " + r.error().hint});
            rangeBad = rangeBad || std::string(key).find("Scale") != std::string::npos;
        }
    }
    if (!rangeBad) {
        auto r = render::parse_dynamic_resolution_settings(dyn, where, {});
        if (!r.ok()) out.push_back({"/render/dynamicResolution/minScale", r.error().message + " " + r.error().hint});
    }
    // The low-latency setting, one key at a time like the upscaler.
    for (const char* key : {"mode", "boost"}) {
        Json one = Json::object();
        one[key] = latency_json(s)[key];
        auto r = render::parse_latency_settings(one, std::string(kFile) + "#/render/latency", {});
        if (!r.ok()) out.push_back({std::string("/render/latency/") + key, r.error().message + " " + r.error().hint});
    }
    // The frame generation, one key at a time as well.
    for (const char* key : {"mode", "minBaseFps"}) {
        Json one = Json::object();
        one[key] = frame_gen_json(s)[key];
        auto r = render::parse_frame_gen_settings(one, std::string(kFile) + "#/render/frameGeneration", {});
        if (!r.ok())
            out.push_back({std::string("/render/frameGeneration/") + key, r.error().message + " " + r.error().hint});
    }
    // The ray tracing and the path tracer, one key at a time. The values are typed, so only a number that is not finite can be wrong; a
    // whole number outside its range is clamped by the engine, never an error.
    for (const char* key :
         {"enabled", "shadows", "ao", "reflections", "translucency", "gi", "raysPerPixel", "maxInstances"}) {
        Json one = Json::object();
        one[key] = ray_tracing_json(s)[key];
        auto r = render::parse_ray_tracing_settings(one, std::string(kFile) + "#/render/rayTracing", {});
        if (!r.ok())
            out.push_back({std::string("/render/rayTracing/") + key, r.error().message + " " + r.error().hint});
    }
    for (const char* key :
         {"enabled", "maxBounces", "samplesPerFrame", "maxSamples", "fireflyClamp", "lights", "seed"}) {
        Json one = Json::object();
        one[key] = path_tracer_json(s)[key];
        if (std::string(key) == "fireflyClamp" && !std::isfinite(double(s.pathTracer.fireflyClamp)))
            one[key] = "not a number";
        auto r = render::parse_path_tracer_settings(one, std::string(kFile) + "#/render/pathTracer", {});
        if (!r.ok())
            out.push_back({std::string("/render/pathTracer/") + key, r.error().message + " " + r.error().hint});
    }
    return out;
}

Result<GraphicsSettings> graphics_settings_from_json(const Json& json, const std::string& file, bool round) {
    GraphicsSettings s;
    if (!json.is_object())
        return make_error(file + ": the project file must be a JSON object.",
                          "Start from {\"format\": \"factoria.project/1\", \"name\": \"My Game\"}.");
    auto render = json.find("render");
    if (render == json.end() || render->is_null()) return s;
    if (!render->is_object())
        return make_error(file + "#/render: expected an object like {\"graphicsPreset\": \"high\"}.",
                          "Replace the value of \"render\" with an object.");
    if (auto gp = render->find("graphicsPreset"); gp != render->end() && !gp->is_null()) {
        std::optional<render::GraphicsPreset> p;
        if (gp->is_string()) p = render::parse_graphics_preset(gp->get<std::string>());
        if (!p)
            return make_error(file + "#/render/graphicsPreset: unknown graphics preset " + gp->dump() + ".",
                              gp->is_string() ? did_you_mean(gp->get<std::string>(), graphics_presets())
                                              : "Use \"low\", \"medium\", \"high\", \"ultra\" or \"custom\".");
        s.preset = std::string(render::graphics_preset_name(*p));
    }
    if (auto up = render->find("upscaler"); up != render->end() && !up->is_null()) {
        auto parsed = render::parse_upscaler_settings(*up, file + "#/render/upscaler", {});
        if (!parsed.ok()) return parsed.error();
        s.mode = std::string(render::upscaler_mode_name(parsed->mode));
        s.quality = std::string(render::upscaler_quality_name(parsed->quality));
        // The number of the file as it is (the parser's float would write 0.123 back as 0.12300000339): Save changes it only when the
        // slider moved it, and the slider steps in hundredths.
        const auto sh = up->find("sharpness");
        s.sharpness = sh != up->end() && sh->is_number() ? sh->get<double>() : double(parsed->sharpness);
    }
    if (auto dr = render->find("dynamicResolution"); dr != render->end() && !dr->is_null()) {
        auto parsed = render::parse_dynamic_resolution_settings(*dr, file + "#/render/dynamicResolution", {});
        if (!parsed.ok()) return parsed.error();
        s.dynamic = *parsed;
        if (round) {  // the editor's model: its sliders step in hundredths and tenths of a ms
            s.dynamic.minScale = float(std::round(double(s.dynamic.minScale) * 100.0) / 100.0);
            s.dynamic.maxScale = float(std::round(double(s.dynamic.maxScale) * 100.0) / 100.0);
            s.dynamic.targetMs = std::round(s.dynamic.targetMs * 10.0) / 10.0;
        }
    }
    if (auto lat = render->find("latency"); lat != render->end() && !lat->is_null()) {
        auto parsed = render::parse_latency_settings(*lat, file + "#/render/latency", {});
        if (!parsed.ok()) return parsed.error();
        s.latencyMode = std::string(render::latency_mode_name(parsed->mode));
        s.latencyBoost = parsed->boost;
    }
    if (auto fg = render->find("frameGeneration"); fg != render->end() && !fg->is_null()) {
        auto parsed = render::parse_frame_gen_settings(*fg, file + "#/render/frameGeneration", {});
        if (!parsed.ok()) return parsed.error();
        s.frameGenMode = std::string(render::frame_gen_mode_name(parsed->mode));
        s.frameGenMinBaseFps = parsed->minBaseFps;
    }
    if (auto rt = render->find("rayTracing"); rt != render->end() && !rt->is_null()) {
        auto parsed = render::parse_ray_tracing_settings(*rt, file + "#/render/rayTracing", {});
        if (!parsed.ok()) return parsed.error();
        s.rayTracing = *parsed;
    }
    if (auto pt = render->find("pathTracer"); pt != render->end() && !pt->is_null()) {
        auto parsed = render::parse_path_tracer_settings(*pt, file + "#/render/pathTracer", {});
        if (!parsed.ok()) return parsed.error();
        s.pathTracer = *parsed;
    }
    return s;
}

Result<GraphicsSettings> read_graphics_settings(const std::string& projectDir, bool round) {
    const std::string path = project_file_path(projectDir);
    auto text = fs::read_text(path);
    if (!text.ok())
        return make_error("Cannot read " + path + ".",
                          "Open a project folder that contains factoria.json (`factoria new` makes one).");
    auto parsed = parse_json(*text, path);
    if (!parsed.ok()) return parsed.error();
    return graphics_settings_from_json(*parsed, path, round);
}

namespace {

// What to do with one key of `render`: leave it (the default), remove it (an empty optional) or set it to a value.
struct KeyOp {
    bool touch = false;
    std::optional<Json> value;
};

// Patches the keys `ops` name into <projectDir>/factoria.json (the others, the order and the formatting stay) and
// answers whether the file changed. `preset`, `upscaler`, `dynamic`, `latency`, `frameGen`, `rayTracing` and `pathTracer` are the seven keys of
// `render`.
Result<bool> patch_render_keys(const std::string& projectDir, const KeyOp& preset, const KeyOp& upscaler,
                               const KeyOp& dynamic, const KeyOp& latency, const KeyOp& frameGen,
                               const KeyOp& rayTracing, const KeyOp& pathTracer) {
    const std::string path = project_file_path(projectDir);
    // The raw bytes, so a UTF-8 BOM the file starts with is written back (read_text drops it).
    auto bytes = fs::read_bytes(path);
    if (!bytes.ok())
        return make_error("Cannot save the graphics settings: " + path + " cannot be read.",
                          "Open a project folder that contains factoria.json.");
    const std::string rawText(bytes->begin(), bytes->end());
    const bool hasBom = rawText.compare(0, 3, "\xEF\xBB\xBF") == 0;
    auto parsed = parse_json(hasBom ? rawText.substr(3) : rawText, path);
    if (!parsed.ok())
        return make_error(parsed.error().message,
                          "Fix the JSON syntax of factoria.json first; the graphics settings are not saved over a "
                          "broken file.");
    if (!parsed->is_object())
        return make_error(path + ": the project file must be a JSON object.",
                          "Start from {\"format\": \"factoria.project/1\", \"name\": \"My Game\"}.");

    std::vector<JsonPatchOp> ops;
    // "render": null loads as no render settings, so it is an absent object here too.
    const bool hasRender = parsed->contains("render") && !(*parsed)["render"].is_null();
    if (hasRender && !(*parsed)["render"].is_object())
        return make_error(path + "#/render: expected an object.", "Replace the value of \"render\" with an object.");
    Json render = hasRender ? (*parsed)["render"] : Json::object();
    const auto apply = [&](const char* key, const KeyOp& op) {
        if (!op.touch) return;
        if (op.value)
            render[key] = *op.value;
        else
            render.erase(key);
    };
    apply("upscaler", upscaler);
    apply("graphicsPreset", preset);
    apply("dynamicResolution", dynamic);
    apply("latency", latency);
    apply("frameGeneration", frameGen);
    apply("rayTracing", rayTracing);
    apply("pathTracer", pathTracer);
    if (render.empty()) {
        // Would `render` be empty afterwards? Then the key goes too.
        if (hasRender) ops.push_back({{"render"}, std::nullopt});
    } else {
        if (parsed->contains("render") && !hasRender) ops.push_back({{"render"}, Json::object()});  // null -> {}
        // Remove what is default, set what is not: one op per key, so the rest of `render` stays byte for byte.
        const auto push = [&](const char* key, const KeyOp& op) {
            if (op.touch) ops.push_back({{"render", key}, op.value});
        };
        push("upscaler", upscaler);
        push("graphicsPreset", preset);
        push("dynamicResolution", dynamic);
        push("latency", latency);
        push("frameGeneration", frameGen);
        push("rayTracing", rayTracing);
        push("pathTracer", pathTracer);
    }
    auto patched = patch_json_text(hasBom ? rawText.substr(3) : rawText, ops, path);
    if (!patched.ok()) return patched.error();
    const std::string out = (hasBom ? std::string("\xEF\xBB\xBF") : std::string()) + *patched;
    if (out == rawText) return false;
    auto written = fs::write_bytes(path, out.data(), out.size());
    if (!written.ok()) return written.error();
    return true;
}

KeyOp set_or_remove(bool isDefault, const Json& value) {
    KeyOp op;
    op.touch = true;
    if (!isDefault) op.value = value;
    return op;
}

// The op for a block of keys: only the keys of `value` that differ from `defaults` stay; none left removes the block.
KeyOp block_op(const Json& value, const Json& defaults) {
    Json differing = Json::object();
    for (auto it = value.begin(); it != value.end(); ++it) {
        const auto d = defaults.find(it.key());
        if (d == defaults.end() || *d != it.value()) differing[it.key()] = it.value();
    }
    return set_or_remove(differing.empty(), differing);
}

}  // namespace

Result<void> write_graphics_settings(const std::string& projectDir, const GraphicsSettings& s) {
    if (auto problems = check_graphics_settings(s); !problems.empty())
        return make_error(problems.front().pointer + ": " + problems.front().message,
                          "Fix the field before saving; nothing was written.");
    const GraphicsSettings def;
    // One rule for every block: the keys that differ from the defaults are written, the others are not (a block with none
    // is removed). A reader gives an absent key its default, so the file says only what the project changed.
    auto r = patch_render_keys(
        projectDir, set_or_remove(s.preset == "custom", Json(s.preset)), block_op(upscaler_json(s), upscaler_json(def)),
        block_op(dynamic_json(s), dynamic_json(def)), block_op(latency_json(s), latency_json(def)),
        block_op(frame_gen_json(s), frame_gen_json(def)), block_op(ray_tracing_json(s), ray_tracing_json(def)),
        block_op(path_tracer_json(s), path_tracer_json(def)));
    if (!r.ok()) return r.error();
    return {};
}

void register_graphics_settings_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.graphics";
    info.category = "project";
    info.readOnly = false;
    info.summary =
        "Reads or writes the graphics preset, the upscaler, the dynamic resolution, the low-latency mode, the frame "
        "generation, the ray tracing and the path tracer a game starts with, in factoria.json.";
    info.description =
        "Edits the keys `render.graphicsPreset`, `render.upscaler`, `render.dynamicResolution`, `render.latency`, "
        "`render.frameGeneration`, `render.rayTracing` and `render.pathTracer` of factoria.json (docs/UPSCALING.md, "
        "\"Graphics presets\"; docs/LATENCY.md; docs/FRAME_GENERATION.md; docs/RAY_TRACING.md): the settings the run "
        "starts with, the ones the editor's View > Graphics window edits. With no argument it only reads and writes "
        "nothing. The keys you give replace those of the file, the others stay. A value at its default removes its "
        "key (a `render` object left empty is removed) and the rest of the file stays as it is. Every value is "
        "checked by the code that loads the project, so a wrong one is named with its JSON pointer and a \"did you "
        "mean\", and nothing is written. Examples: {\"preset\":\"medium\"}, "
        "{\"upscaler\":{\"mode\":\"auto\",\"quality\":\"balanced\"}}." FA_COMMAND_DETAILS
        "`preset` is low, medium, high, ultra or custom; `upscaler` is {mode, quality, sharpness}, `dynamicResolution` "
        "is {enabled, targetMs, minScale, maxScale}, `latency` is {mode, boost} (mode: off, auto, reflex, antilag2 or "
        "xell), `frameGeneration` is {mode, minBaseFps} (mode: off, auto, dlss, fsr or xess; minBaseFps a whole number "
        "of 0 to 1000), `rayTracing` is {enabled, shadows, ao, reflections, translucency, gi, raysPerPixel, "
        "maxInstances} and `pathTracer` is {enabled, maxBounces, samplesPerFrame, maxSamples, fireflyClamp, lights, "
        "seed} (the keys of render.ray_tracing and render.path_tracer). "
        "It does not change a running game: graphics.preset, render.upscaler, render.dynamic_resolution, "
        "render.latency, render.frame_generation, render.ray_tracing and render.path_tracer do that, "
        "and the engine does not save the player's choice. Returns {file, preset, upscaler: {mode, quality, "
        "sharpness}, dynamicResolution: {enabled, targetMs, minScale, maxScale}, latency: {mode, boost}, "
        "frameGeneration: {mode, minBaseFps}, rayTracing: {...}, pathTracer: {...}, written}; "
        "`written` is false when "
        "the file's bytes did not change (a read, or the same values written the same way; a key given at its "
        "default that the file spelled out is removed, so that counts as a write). Errors: `invalid_argument` (unknown "
        "key or wrong value), "
        "`failed` (no factoria.json, a file that is not valid JSON, or one that cannot be written).";
    info.inputSchema = Json::parse(R"({"type":"object","properties":{
        "preset":{"type":"string","enum":["low","medium","high","ultra","custom"],"description":"render.graphicsPreset: the preset a run starts with (custom removes the key)."},
        "upscaler":{"type":"object","description":"render.upscaler: the keys given replace the file's.","properties":{
            "mode":{"type":"string","enum":["stretch","spatial","temporal","metalfx","dlss","xess","fsr","auto"]},
            "quality":{"type":"string","enum":["native","quality","balanced","performance","ultraPerformance"]},
            "sharpness":{"type":"number","minimum":0,"maximum":1}}},
        "dynamicResolution":{"type":"object","description":"render.dynamicResolution: the keys given replace the file's.","properties":{
            "enabled":{"type":"boolean"},"targetMs":{"type":"number","minimum":0},
            "minScale":{"type":"number","minimum":0.1,"maximum":1},"maxScale":{"type":"number","minimum":0.1,"maximum":1}}},
        "latency":{"type":"object","description":"render.latency (docs/LATENCY.md): the keys given replace the file's.","properties":{
            "mode":{"type":"string","enum":["off","auto","reflex","antilag2","xell"]},"boost":{"type":"boolean"}}},
        "frameGeneration":{"type":"object","description":"render.frameGeneration (docs/FRAME_GENERATION.md): the keys given replace the file's.","properties":{
            "mode":{"type":"string","enum":["off","auto","dlss","fsr","xess"]},"minBaseFps":{"type":"integer","minimum":0,"maximum":1000}}},
        "rayTracing":{"type":"object","description":"render.rayTracing (docs/RAY_TRACING.md): the keys given replace the file's.","properties":{
            "enabled":{"type":"boolean","description":"The master switch. Default false."},
            "shadows":{"type":"string","enum":["off","hard","soft"],"description":"off (shadow maps), hard (one ray per light), soft (rays across the light's disc). Default off."},
            "ao":{"type":"boolean","description":"Ambient occlusion with rays. Default false."},
            "reflections":{"type":"boolean","description":"Reflections with rays. Default false."},
            "translucency":{"type":"boolean","description":"Refraction through glass and liquids traced with rays instead of the screen-space refraction. Default false."},
            "gi":{"type":"string","enum":["off","probes","perPixel"],"description":"Global illumination: off, probes (the RealtimeGI grids updated with rays) or perPixel. Default off."},
            "raysPerPixel":{"type":"integer","description":"Rays of each effect per pixel and frame. Clamped to 1..16. Default 1."},
            "maxInstances":{"type":"integer","description":"The most instances the top-level structure holds. Clamped to 1..1048576. Default 65536."}}},
        "pathTracer":{"type":"object","description":"render.pathTracer (docs/RAY_TRACING.md, \"The path tracer\"): the keys given replace the file's.","properties":{
            "enabled":{"type":"boolean","description":"Draw the main camera's lit colour with the path tracer. Default false."},
            "maxBounces":{"type":"integer","description":"Path length: 1 = direct light only. Clamped to 1..32. Default 4."},
            "samplesPerFrame":{"type":"integer","description":"Paths per pixel each frame adds to the accumulation. Clamped to 1..64. Default 1."},
            "maxSamples":{"type":"integer","description":"The accumulation stops after this many samples per pixel; 0 = never stops. Clamped to 0..16777216. Default 0."},
            "fireflyClamp":{"type":"number","minimum":0,"description":"Clamps the radiance of one path to this value (0 = off): fewer white dots for a little lost energy. Default 0."},
            "lights":{"type":"boolean","description":"Direct light from the point and spot lights (up to 8 of the frame); the sun is always sampled. Default true."},
            "seed":{"type":"integer","description":"Changes the noise pattern; the same seed gives the same picture. Clamped to 0..1073741824. Default 0."}}}}})");
    registry.add(info, [projectDir](const Json& args) {
        if (!args.is_null() && !args.is_object())
            throw CommandError("invalid_argument",
                               "project.graphics takes an object, got " + std::string(args.type_name()) + ".",
                               "Example: {\"preset\":\"medium\"}, or {} to read.");
        const std::vector<std::string> keys = {"preset",          "upscaler",   "dynamicResolution", "latency",
                                               "frameGeneration", "rayTracing", "pathTracer"};
        if (args.is_object())
            for (auto it = args.begin(); it != args.end(); ++it)
                if (std::find(keys.begin(), keys.end(), it.key()) == keys.end())
                    throw CommandError("invalid_argument",
                                       "Unknown argument '" + it.key() + "'. " + did_you_mean(it.key(), keys),
                                       "project.graphics takes `preset`, `upscaler`, `dynamicResolution`, `latency`, "
                                       "`frameGeneration`, `rayTracing` and `pathTracer`.");
        // The numbers of the file as they are (no rounding of the editor's sliders): a key this call does not name is
        // not written, and one it names keeps what the caller wrote.
        auto current = read_graphics_settings(projectDir, false);
        if (!current.ok()) throw CommandError("failed", current.error().message, current.error().hint);
        GraphicsSettings s = *current;
        Json rawDynamic = Json::object();  // the file's render.dynamicResolution, for the keys the call leaves alone
        if (auto text = fs::read_text(project_file_path(projectDir)); text.ok())
            if (auto file = parse_json(*text, project_file_path(projectDir)); file.ok() && file->is_object())
                if (auto r = file->find("render"); r != file->end() && r->is_object())
                    if (auto d = r->find("dynamicResolution"); d != r->end() && d->is_object()) rawDynamic = *d;
        const auto object_arg = [&](const char* key) -> const Json* {
            if (!args.is_object()) return nullptr;
            auto it = args.find(key);
            if (it == args.end() || it->is_null()) return nullptr;
            if (!it->is_object())
                throw CommandError("invalid_argument",
                                   std::string("`") + key + "` is an object, got " + it->type_name() + ".",
                                   std::string("Example: {\"") + key + "\": {...}}; see the command's schema.");
            return &*it;
        };
        if (args.is_object() && args.contains("preset") && !args["preset"].is_null()) {
            if (!args["preset"].is_string())
                throw CommandError("invalid_argument",
                                   std::string("`preset` is a string, got ") + args["preset"].type_name() + ".",
                                   "Use \"low\", \"medium\", \"high\", \"ultra\" or \"custom\".");
            s.preset = args["preset"].get<std::string>();
        }
        if (const Json* up = object_arg("upscaler")) {
            Json merged =
                upscaler_json(s);  // the file's keys, replaced by the ones given (an unknown one reaches the parser)
            for (auto it = up->begin(); it != up->end(); ++it) merged[it.key()] = it.value();
            auto parsed = render::parse_upscaler_settings(merged, "project.graphics upscaler", {});
            if (!parsed.ok()) throw CommandError("invalid_argument", parsed.error().message, parsed.error().hint);
            s.mode = std::string(render::upscaler_mode_name(parsed->mode));
            s.quality = std::string(render::upscaler_quality_name(parsed->quality));
            // A sharpness the caller gave stays as the caller wrote it (the parser's float would write 0.123 as 0.12300000339).
            if (auto sh = up->find("sharpness"); sh != up->end() && sh->is_number()) s.sharpness = sh->get<double>();
        }
        if (const Json* dyn = object_arg("dynamicResolution")) {
            auto parsed =
                render::parse_dynamic_resolution_settings(*dyn, "project.graphics dynamicResolution", s.dynamic);
            if (!parsed.ok()) throw CommandError("invalid_argument", parsed.error().message, parsed.error().hint);
            s.dynamic = *parsed;
        }
        if (const Json* lat = object_arg("latency")) {
            auto parsed = render::parse_latency_settings(*lat, "project.graphics latency", {});
            if (!parsed.ok()) throw CommandError("invalid_argument", parsed.error().message, parsed.error().hint);
            Json merged = latency_json(s);  // the file's keys, replaced by the ones given
            for (auto it = lat->begin(); it != lat->end(); ++it) merged[it.key()] = it.value();
            auto both = render::parse_latency_settings(merged, "project.graphics latency", {});
            if (!both.ok()) throw CommandError("invalid_argument", both.error().message, both.error().hint);
            s.latencyMode = std::string(render::latency_mode_name(both->mode));
            s.latencyBoost = both->boost;
        }
        if (const Json* fg = object_arg("frameGeneration")) {
            // The file's keys, replaced by the ones given (an unknown or wrong one is the parser's error, with its place).
            auto base =
                render::parse_frame_gen_settings(frame_gen_json(s), "factoria.json#/render/frameGeneration", {});
            if (!base.ok()) throw CommandError("failed", base.error().message, base.error().hint);
            auto parsed = render::parse_frame_gen_settings(*fg, "project.graphics frameGeneration", *base);
            if (!parsed.ok()) throw CommandError("invalid_argument", parsed.error().message, parsed.error().hint);
            s.frameGenMode = std::string(render::frame_gen_mode_name(parsed->mode));
            s.frameGenMinBaseFps = parsed->minBaseFps;
        }
        if (const Json* rt = object_arg("rayTracing")) {
            // Over the file's own setting: the keys given replace its keys, a wrong one is the parser's error with its place.
            auto parsed = render::parse_ray_tracing_settings(*rt, "project.graphics rayTracing", s.rayTracing);
            if (!parsed.ok()) throw CommandError("invalid_argument", parsed.error().message, parsed.error().hint);
            s.rayTracing = *parsed;
        }
        if (const Json* pt = object_arg("pathTracer")) {
            auto parsed = render::parse_path_tracer_settings(*pt, "project.graphics pathTracer", s.pathTracer);
            if (!parsed.ok()) throw CommandError("invalid_argument", parsed.error().message, parsed.error().hint);
            s.pathTracer = *parsed;
        }
        if (auto problems = check_graphics_settings(s); !problems.empty())
            throw CommandError("invalid_argument", problems.front().pointer + ": " + problems.front().message,
                               "Fix the value; nothing was written.");
        // Only the keys the call names are written.
        const GraphicsSettings def;
        KeyOp presetOp, upscalerOp, dynamicOp, latencyOp, frameGenOp, rayTracingOp, pathTracerOp;
        if (args.is_object() && args.contains("preset") && !args["preset"].is_null())
            presetOp = set_or_remove(s.preset == "custom", Json(s.preset));
        if (object_arg("upscaler"))
            upscalerOp = set_or_remove(s.mode == def.mode && s.quality == def.quality && s.sharpness == def.sharpness,
                                       upscaler_json(s));
        if (const Json* dyn = object_arg("dynamicResolution")) {
            Json value = dynamic_json(s);
            for (const char* key : {"enabled", "targetMs", "minScale", "maxScale"}) {
                if (dyn->contains(key))
                    value[key] = (*dyn)[key];  // as the caller wrote it (0.333, not the float's 0.33300000429)
                else if (rawDynamic.contains(key))
                    value[key] = rawDynamic[key];
            }
            dynamicOp = set_or_remove(s.dynamic == def.dynamic, value);
        }
        if (object_arg("latency"))
            latencyOp =
                set_or_remove(s.latencyMode == def.latencyMode && s.latencyBoost == def.latencyBoost, latency_json(s));
        if (object_arg("frameGeneration"))
            frameGenOp =
                set_or_remove(s.frameGenMode == def.frameGenMode && s.frameGenMinBaseFps == def.frameGenMinBaseFps,
                              frame_gen_json(s));
        if (object_arg("rayTracing")) rayTracingOp = set_or_remove(s.rayTracing == def.rayTracing, ray_tracing_json(s));
        if (object_arg("pathTracer")) pathTracerOp = set_or_remove(s.pathTracer == def.pathTracer, path_tracer_json(s));
        bool changed = false;
        if (presetOp.touch || upscalerOp.touch || dynamicOp.touch || latencyOp.touch || frameGenOp.touch ||
            rayTracingOp.touch || pathTracerOp.touch) {
            auto written = patch_render_keys(projectDir, presetOp, upscalerOp, dynamicOp, latencyOp, frameGenOp,
                                             rayTracingOp, pathTracerOp);
            if (!written.ok()) throw CommandError("failed", written.error().message, written.error().hint);
            changed = *written;
        }
        Json out = Json::object();
        out["file"] = project_file_path(projectDir);
        out["preset"] = s.preset;
        out["upscaler"] = upscaler_json(s);
        out["dynamicResolution"] = dynamic_json(s);
        out["latency"] = latency_json(s);
        out["frameGeneration"] = frame_gen_json(s);
        out["rayTracing"] = ray_tracing_json(s);
        out["pathTracer"] = path_tracer_json(s);
        out["written"] = changed;
        return out;
    });
    declare_command_capabilities(registry, {{"project.graphics", capability_sets::writes_project()}});
}

}  // namespace fa
