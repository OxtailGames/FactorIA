#include "graphics_settings_model.h"

#include <cmath>
#include <optional>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/render/graphics_preset.h"
#include "fa/render/upscaler.h"
#include "fa/tooling/json_patch.h"

namespace fa::editor {

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

}  // namespace

const std::vector<std::string>& graphics_presets() {
    static const std::vector<std::string> v(render::kGraphicsPresetNames.begin(), render::kGraphicsPresetNames.end());
    return v;
}
const std::vector<std::string>& upscaler_modes() {
    static const std::vector<std::string> v(render::kUpscalerModeNames.begin(), render::kUpscalerModeNames.end());
    return v;
}
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
    return out;
}

Result<GraphicsSettings> graphics_settings_from_json(const Json& json, const std::string& file) {
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
        s.sharpness = double(std::round(parsed->sharpness * 100.0f)) / 100.0;
    }
    return s;
}

Result<GraphicsSettings> read_graphics_settings(const std::string& projectDir) {
    const std::string path = project_file_path(projectDir);
    auto text = fs::read_text(path);
    if (!text.ok())
        return make_error("Cannot read " + path + ".",
                          "Open a project folder that contains factoria.json (`factoria new` makes one).");
    auto parsed = parse_json(*text, path);
    if (!parsed.ok()) return parsed.error();
    return graphics_settings_from_json(*parsed, path);
}

Result<void> write_graphics_settings(const std::string& projectDir, const GraphicsSettings& s) {
    if (auto problems = check_graphics_settings(s); !problems.empty())
        return make_error(problems.front().pointer + ": " + problems.front().message,
                          "Fix the field before saving; nothing was written.");
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

    const GraphicsSettings def;
    const bool upscalerDefault = s.mode == def.mode && s.quality == def.quality && s.sharpness == def.sharpness;
    const bool presetDefault = s.preset == "custom";
    std::vector<JsonPatchOp> ops;
    // Would `render` be empty afterwards? Then the key goes too.
    // "render": null loads as no render settings, so it is an absent object here too.
    const bool hasRender = parsed->contains("render") && !(*parsed)["render"].is_null();
    if (hasRender && !(*parsed)["render"].is_object())
        return make_error(path + "#/render: expected an object.", "Replace the value of \"render\" with an object.");
    Json render = hasRender ? (*parsed)["render"] : Json::object();
    if (upscalerDefault)
        render.erase("upscaler");
    else
        render["upscaler"] = upscaler_json(s);
    if (presetDefault)
        render.erase("graphicsPreset");
    else
        render["graphicsPreset"] = s.preset;
    if (render.empty()) {
        if (hasRender) ops.push_back({{"render"}, std::nullopt});
    } else {
        if (parsed->contains("render") && !hasRender) ops.push_back({{"render"}, Json::object()});  // null -> {}
        // Remove what is default, set what is not: one op per key, so the rest of `render` stays byte for byte.
        ops.push_back({{"render", "upscaler"},
                       upscalerDefault ? std::optional<Json>() : std::optional<Json>(render["upscaler"])});
        ops.push_back({{"render", "graphicsPreset"},
                       presetDefault ? std::optional<Json>() : std::optional<Json>(Json(s.preset))});
    }
    auto patched = patch_json_text(hasBom ? rawText.substr(3) : rawText, ops, path);
    if (!patched.ok()) return patched.error();
    const std::string out = (hasBom ? std::string("\xEF\xBB\xBF") : std::string()) + *patched;
    if (out == rawText) return {};
    return fs::write_bytes(path, out.data(), out.size());
}

}  // namespace fa::editor
