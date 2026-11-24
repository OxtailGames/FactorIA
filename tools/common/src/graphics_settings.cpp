#include "fa/tooling/graphics_settings.h"

#include <algorithm>
#include <cmath>
#include <optional>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/render/dynamic_resolution.h"
#include "fa/render/graphics_preset.h"
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
        // The number of the file as it is (the parser's float would write 0.123 back as 0.12300000339): Save changes it only when the
        // slider moved it, and the slider steps in hundredths.
        const auto sh = up->find("sharpness");
        s.sharpness = sh != up->end() && sh->is_number() ? sh->get<double>() : double(parsed->sharpness);
    }
    if (auto dr = render->find("dynamicResolution"); dr != render->end() && !dr->is_null()) {
        auto parsed = render::parse_dynamic_resolution_settings(*dr, file + "#/render/dynamicResolution", {});
        if (!parsed.ok()) return parsed.error();
        s.dynamic = *parsed;
        s.dynamic.minScale = float(std::round(double(s.dynamic.minScale) * 100.0) / 100.0);
        s.dynamic.maxScale = float(std::round(double(s.dynamic.maxScale) * 100.0) / 100.0);
        s.dynamic.targetMs = std::round(s.dynamic.targetMs * 10.0) / 10.0;
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
    const bool dynamicDefault = s.dynamic == def.dynamic;
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
    if (dynamicDefault)
        render.erase("dynamicResolution");
    else
        render["dynamicResolution"] = dynamic_json(s);
    if (render.empty()) {
        if (hasRender) ops.push_back({{"render"}, std::nullopt});
    } else {
        if (parsed->contains("render") && !hasRender) ops.push_back({{"render"}, Json::object()});  // null -> {}
        // Remove what is default, set what is not: one op per key, so the rest of `render` stays byte for byte.
        ops.push_back({{"render", "upscaler"},
                       upscalerDefault ? std::optional<Json>() : std::optional<Json>(render["upscaler"])});
        ops.push_back({{"render", "graphicsPreset"},
                       presetDefault ? std::optional<Json>() : std::optional<Json>(Json(s.preset))});
        ops.push_back({{"render", "dynamicResolution"},
                       dynamicDefault ? std::optional<Json>() : std::optional<Json>(render["dynamicResolution"])});
    }
    auto patched = patch_json_text(hasBom ? rawText.substr(3) : rawText, ops, path);
    if (!patched.ok()) return patched.error();
    const std::string out = (hasBom ? std::string("\xEF\xBB\xBF") : std::string()) + *patched;
    if (out == rawText) return {};
    return fs::write_bytes(path, out.data(), out.size());
}

void register_graphics_settings_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.graphics";
    info.category = "project";
    info.readOnly = false;
    info.summary =
        "Reads or writes the graphics preset, the upscaler and the dynamic resolution a game starts with, in "
        "factoria.json.";
    info.description =
        "Edits the keys `render.graphicsPreset`, `render.upscaler` and `render.dynamicResolution` of factoria.json "
        "(docs/UPSCALING.md, \"Graphics presets\"): the settings the run starts with, the ones the editor's View > "
        "Graphics window edits. With no argument it only reads and writes nothing. `preset` is low, medium, high, "
        "ultra "
        "or custom; `upscaler` is {mode, quality, sharpness} and `dynamicResolution` is {enabled, targetMs, minScale, "
        "maxScale}: the keys you give replace those of the file, the others stay. A value at its default removes its "
        "key (a `render` object left empty is removed), and every other key and the formatting of the file stay as "
        "they are. Every value is checked by the code that loads the project, so a wrong one is named with its JSON "
        "pointer and a \"did you mean\", and nothing is written. Examples: {\"preset\":\"medium\"}, "
        "{\"upscaler\":{\"mode\":\"auto\",\"quality\":\"balanced\"}}." FA_COMMAND_DETAILS
        "It does not change a running game: graphics.preset, render.upscaler and render.dynamic_resolution do that, "
        "and the engine does not save the player's choice. Returns {file, preset, upscaler: {mode, quality, "
        "sharpness}, dynamicResolution: {enabled, targetMs, minScale, maxScale}, written}; `written` is false when "
        "nothing changed (a read, or the same values). Errors: `invalid_argument` (unknown key or wrong value), "
        "`failed` (no factoria.json, a file that is not valid JSON, or one that cannot be written).";
    info.inputSchema = Json::parse(R"({"type":"object","properties":{
        "preset":{"type":"string","enum":["low","medium","high","ultra","custom"],"description":"render.graphicsPreset: the preset a run starts with (custom removes the key)."},
        "upscaler":{"type":"object","description":"render.upscaler: the keys given replace the file's.","properties":{
            "mode":{"type":"string","enum":["stretch","spatial","temporal","metalfx","auto"]},
            "quality":{"type":"string","enum":["native","quality","balanced","performance","ultraPerformance"]},
            "sharpness":{"type":"number","minimum":0,"maximum":1}}},
        "dynamicResolution":{"type":"object","description":"render.dynamicResolution: the keys given replace the file's.","properties":{
            "enabled":{"type":"boolean"},"targetMs":{"type":"number","minimum":0},
            "minScale":{"type":"number","minimum":0.1,"maximum":1},"maxScale":{"type":"number","minimum":0.1,"maximum":1}}}}})");
    registry.add(info, [projectDir](const Json& args) {
        if (!args.is_null() && !args.is_object())
            throw CommandError("invalid_argument",
                               "project.graphics takes an object, got " + std::string(args.type_name()) + ".",
                               "Example: {\"preset\":\"medium\"}, or {} to read.");
        const std::vector<std::string> keys = {"preset", "upscaler", "dynamicResolution"};
        if (args.is_object())
            for (auto it = args.begin(); it != args.end(); ++it)
                if (std::find(keys.begin(), keys.end(), it.key()) == keys.end())
                    throw CommandError("invalid_argument",
                                       "Unknown argument '" + it.key() + "'. " + did_you_mean(it.key(), keys),
                                       "project.graphics takes `preset`, `upscaler` and `dynamicResolution`.");
        auto current = read_graphics_settings(projectDir);
        if (!current.ok()) throw CommandError("failed", current.error().message, current.error().hint);
        GraphicsSettings s = *current;
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
        if (auto problems = check_graphics_settings(s); !problems.empty())
            throw CommandError("invalid_argument", problems.front().pointer + ": " + problems.front().message,
                               "Fix the value; nothing was written.");
        const bool changed = !(s == *current);
        if (changed) {
            auto written = write_graphics_settings(projectDir, s);
            if (!written.ok()) throw CommandError("failed", written.error().message, written.error().hint);
        }
        Json out = Json::object();
        out["file"] = project_file_path(projectDir);
        out["preset"] = s.preset;
        out["upscaler"] = upscaler_json(s);
        out["dynamicResolution"] = dynamic_json(s);
        out["written"] = changed;
        return out;
    });
    declare_command_capabilities(registry, {{"project.graphics", capability_sets::writes_project()}});
}

}  // namespace fa
