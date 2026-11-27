#include "fa/core/engine_version.h"
#include "fa/runtime/project.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <format>
#include <fstream>
#include <sstream>

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include "fa/core/fs.h"
#include "fa/core/i18n.h"
#include "fa/core/strings.h"
#include "fa/script/script_budget.h"

namespace fa {

namespace stdfs = std::filesystem;

std::string asset_type_of(std::string_view path) {
    const std::string p = to_lower(path);
    if (ends_with(p, ".scene.json")) return "scene";
    if (ends_with(p, ".prefab.json")) return "prefab";
    if (ends_with(p, ".material.json")) return "material";
    if (ends_with(p, ".vfx.json")) return "vfx";
    const auto dot = p.rfind('.');
    const auto slash = p.find_last_of('/');
    if (dot == std::string::npos || (slash != std::string::npos && dot < slash)) return "other";
    const std::string ext = p.substr(dot);
    if (ext == ".png" || ext == ".jpg" || ext == ".jpeg" || ext == ".tga" || ext == ".bmp") return "texture";
    if (ext == ".wav" || ext == ".ogg" || ext == ".mp3" || ext == ".qoa") return "audio";
    if (ext == ".mpg" || ext == ".mpeg") return "video";
    if (ext == ".hdr") return "hdri";
    if (ext == ".ttf" || ext == ".otf") return "font";
    if (ext == ".obj" || ext == ".gltf" || ext == ".glb") return "mesh";
    if (ext == ".js") return "script";
    return "other";
}

const char* scale_mode_name(ScaleMode mode) {
    switch (mode) {
        case ScaleMode::Fit: return "fit";
        case ScaleMode::Stretch: return "stretch";
        case ScaleMode::Expand: return "expand";
        case ScaleMode::PixelPerfect: return "pixel-perfect";
    }
    return "fit";
}

bool parse_scale_mode(std::string_view text, ScaleMode& out) {
    std::string t;
    for (char c : text)
        if (c != '-' && c != '_' && c != ' ') t += char(std::tolower(static_cast<unsigned char>(c)));
    if (t == "fit")
        out = ScaleMode::Fit;
    else if (t == "stretch")
        out = ScaleMode::Stretch;
    else if (t == "expand")
        out = ScaleMode::Expand;
    else if (t == "pixelperfect")
        out = ScaleMode::PixelPerfect;
    else
        return false;
    return true;
}

Json ProjectSettings::to_json() const {
    Json j = raw.is_object() ? raw : Json::object();
    j["format"] = "factoria.project/1";
    j["name"] = name;
    j["id"] = id;
    j["version"] = version;
    j["engine"] = engineVersion;
    j["mainScene"] = mainScene;
    Json display = j.contains("display") && j["display"].is_object() ? j["display"] : Json::object();
    display["width"] = width;
    display["height"] = height;
    display["scaleMode"] = scale_mode_name(scaleMode);
    display["fullscreen"] = fullscreen;
    display["vsync"] = vsync;
    display["orientation"] = orientation;
    display["pixelArt"] = pixelArt;
    j["display"] = display;
    Json physics = j.contains("physics") && j["physics"].is_object() ? j["physics"] : Json::object();
    physics["fixedHz"] = fixedHz;
    physics["pixelsPerMeter"] = pixelsPerMeter;
    j["physics"] = physics;
    if (renderInterpolation || renderInterpolationSnapDistance > 0.0f || upscaler != render::UpscalerSettings{} ||
        latency != render::LatencySettings{} || frameGeneration != render::FrameGenSettings{} ||
        rayTracing != render::RayTracingSettings{} || pathTracer != render::PathTracerSettings{} ||
        dynamicResolution != render::DynamicResolutionSettings{} || graphicsPreset != render::GraphicsPreset::Custom ||
        renderBackend != "auto" || !renderAsyncCompute || !renderMultiThreadRecording) {
        Json render = j.contains("render") && j["render"].is_object() ? j["render"] : Json::object();
        if (renderInterpolation || renderInterpolationSnapDistance > 0.0f)
            render["interpolation"] = renderInterpolation;
        else
            render.erase("interpolation");
        if (renderInterpolationSnapDistance > 0.0f)
            render["interpolationSnapDistance"] = renderInterpolationSnapDistance;
        else
            render.erase("interpolationSnapDistance");
        if (upscaler != render::UpscalerSettings{})
            render["upscaler"] = render::upscaler_to_json(upscaler);
        else
            render.erase("upscaler");
        if (latency != render::LatencySettings{})
            render["latency"] = render::latency_to_json(latency);
        else
            render.erase("latency");
        if (frameGeneration != render::FrameGenSettings{})
            render["frameGeneration"] = render::frame_gen_to_json(frameGeneration);
        else
            render.erase("frameGeneration");
        if (rayTracing != render::RayTracingSettings{})
            render["rayTracing"] = render::ray_tracing_to_json(rayTracing);
        else
            render.erase("rayTracing");
        if (pathTracer != render::PathTracerSettings{})
            render["pathTracer"] = render::path_tracer_to_json(pathTracer);
        else
            render.erase("pathTracer");
        if (dynamicResolution != render::DynamicResolutionSettings{})
            render["dynamicResolution"] = render::dynamic_resolution_to_json(dynamicResolution);
        else
            render.erase("dynamicResolution");
        if (graphicsPreset != render::GraphicsPreset::Custom)
            render["graphicsPreset"] = std::string(render::graphics_preset_name(graphicsPreset));
        else
            render.erase("graphicsPreset");
        if (renderBackend != "auto")
            render["backend"] = renderBackend;
        else
            render.erase("backend");
        if (!renderAsyncCompute)
            render["asyncCompute"] = false;
        else
            render.erase("asyncCompute");
        if (!renderMultiThreadRecording)
            render["multiThreadRecording"] = false;
        else
            render.erase("multiThreadRecording");
        j["render"] = render;
    } else if (j.contains("render") && j["render"].is_object()) {
        j["render"].erase("interpolation");
        j["render"].erase("interpolationSnapDistance");
        j["render"].erase("upscaler");
        j["render"].erase("latency");
        j["render"].erase("frameGeneration");
        j["render"].erase("rayTracing");
        j["render"].erase("pathTracer");
        j["render"].erase("dynamicResolution");
        j["render"].erase("graphicsPreset");
        j["render"].erase("backend");
        j["render"].erase("asyncCompute");
        j["render"].erase("multiThreadRecording");
        if (j["render"].empty()) j.erase("render");
    }
    if (floatingOrigin != FloatingOriginSettings{}) {
        Json world = j.contains("world") && j["world"].is_object() ? j["world"] : Json::object();
        Json fo = Json::object();
        fo["enabled"] = floatingOrigin.enabled;
        fo["threshold"] = floatingOrigin.threshold;
        fo["step"] = floatingOrigin.step;
        fo["anchor"] = floatingOrigin.anchor;
        world["floatingOrigin"] = fo;
        j["world"] = world;
    } else if (j.contains("world") && j["world"].is_object()) {
        j["world"].erase("floatingOrigin");
        if (j["world"].empty()) j.erase("world");
    }
    Json input = j.contains("input") && j["input"].is_object() ? j["input"] : Json::object();
    input["actions"] = inputActions;
    input["deadzone"] = inputDeadzone;
    if (!inputSchemes.empty())
        input["schemes"] = inputSchemes;
    else
        input.erase("schemes");
    j["input"] = input;
    if (uiScale != 1.0f || !uiMirrorRtl || (j.contains("ui") && j["ui"].is_object())) {
        Json ui = j.contains("ui") && j["ui"].is_object() ? j["ui"] : Json::object();
        ui["scale"] = uiScale;
        if (!uiMirrorRtl)
            ui["mirrorRtl"] = false;
        else
            ui.erase("mirrorRtl");
        j["ui"] = ui;
    }
    Json plats = Json::array();
    for (const auto& p : platforms) plats.push_back(p);
    j["platforms"] = plats;
    j["feedbackFile"] = feedbackFile;
    if (icon.empty())
        j.erase("icon");
    else
        j["icon"] = icon;
    if (jobThreadsSet) {
        Json runtime = j.contains("runtime") && j["runtime"].is_object() ? j["runtime"] : Json::object();
        runtime["jobThreads"] = jobThreads.to_json();
        j["runtime"] = runtime;
    } else if (j.contains("runtime") && j["runtime"].is_object()) {
        j["runtime"].erase("jobThreads");
        if (j["runtime"].empty()) j.erase("runtime");
    }
    return j;
}

Json ProjectSettings::to_json_redacted() const {
    Json j = to_json();
    if (auto st = j.find("storage"); st != j.end() && st->is_object())
        if (auto sec = st->find("encryptionSecret");
            sec != st->end() && sec->is_string() && !sec->get<std::string>().empty())
            *sec = "(hidden)";
    return j;
}

const char* runtime_platform() {
#if defined(__ANDROID__)
    return "android";
#elif defined(__APPLE__) && TARGET_OS_IPHONE
    return "ios";
#elif defined(__APPLE__)
    return "macos";
#elif defined(_WIN32)
    return "windows";
#elif defined(__EMSCRIPTEN__)
    return "web";
#else
    return "linux";
#endif
}

const std::vector<std::string>& platform_names() {
    static const std::vector<std::string> names = {"windows", "macos", "linux", "ios", "android", "web"};
    return names;
}

std::vector<std::string> ProjectSettings::plugin_platforms(const PluginSettings& plugin) const {
    if (!plugin.platforms.empty()) return plugin.platforms;
    if (!platforms.empty()) return platforms;
    // A browser cannot load a native library: a plugin without its own list is meant for the other platforms.
    std::vector<std::string> native = platform_names();
    native.erase(std::remove(native.begin(), native.end(), "web"), native.end());
    return native;
}

std::string ProjectSettings::window_icon() const {
    const char* platform = runtime_platform();
    if (auto exp = raw.find("export"); exp != raw.end() && exp->is_object())
        if (auto plat = exp->find(platform); plat != exp->end() && plat->is_object())
            if (auto own = plat->find("icon");
                own != plat->end() && own->is_string() && !own->get<std::string>().empty())
                return own->get<std::string>();
    return icon;
}

namespace {

std::string at(std::string_view pointer) { return std::string(kProjectFileName) + "#" + std::string(pointer); }

Error field_error(std::string_view pointer, const std::string& expected, const Json& got,
                  const std::string& hint = {}) {
    return make_error(at(pointer) + ": expected " + expected + ", got " + describe_json_value(got),
                      hint.empty() ? "Fix the value in factoria.json (schema: schemas/project.schema.json)." : hint);
}

template <class T>
struct Reader {
    static bool read(const Json& j, T& out);
};

// Each reader returns an Error on type mismatch and leaves `out` untouched when the key is absent.
Result<void> read_string(const Json& obj, const char* key, std::string_view ptr, std::string& out) {
    auto it = obj.find(key);
    if (it == obj.end() || it->is_null()) return {};
    if (!it->is_string()) return field_error(std::string(ptr) + "/" + key, "a string", *it);
    out = it->get<std::string>();
    return {};
}
Result<void> read_bool(const Json& obj, const char* key, std::string_view ptr, bool& out) {
    auto it = obj.find(key);
    if (it == obj.end() || it->is_null()) return {};
    if (!it->is_boolean()) return field_error(std::string(ptr) + "/" + key, "true or false", *it);
    out = it->get<bool>();
    return {};
}
Result<void> read_int(const Json& obj, const char* key, std::string_view ptr, int& out, int minValue) {
    auto it = obj.find(key);
    if (it == obj.end() || it->is_null()) return {};
    if (!it->is_number()) return field_error(std::string(ptr) + "/" + key, "a number", *it);
    int v = int(it->get<double>());
    if (v < minValue)
        return make_error(at(std::string(ptr) + "/" + key) + ": value " + std::to_string(v) + " is below the minimum " +
                              std::to_string(minValue),
                          "Use a value >= " + std::to_string(minValue) + ".");
    out = v;
    return {};
}
Result<void> read_double(const Json& obj, const char* key, std::string_view ptr, double& out, double minValue,
                         bool exclusive) {
    auto it = obj.find(key);
    if (it == obj.end() || it->is_null()) return {};
    if (!it->is_number()) return field_error(std::string(ptr) + "/" + key, "a number", *it);
    double v = it->get<double>();
    if (v < minValue || (exclusive && v <= minValue))
        return make_error(at(std::string(ptr) + "/" + key) + ": value " + std::to_string(v) + " must be " +
                              (exclusive ? "greater than " : "at least ") + std::to_string(minValue),
                          "Typical values: fixedHz 60, pixelsPerMeter 100.");
    out = v;
    return {};
}

#define FA_TRY(expr)                                                                                                   \
    do {                                                                                                               \
        Result<void> r_ = (expr);                                                                                      \
        if (!r_.ok()) return r_.error();                                                                               \
    } while (0)

// "world": {"floatingOrigin": {...}} (docs/BIG_WORLDS.md): a number in a range, a name that fits, else an error with the pointer.
Result<void> read_floating_origin(const Json& fo, FloatingOriginSettings& out) {
    const std::string base = "/world/floatingOrigin";
    if (!fo.is_object())
        return field_error(
            base, "an object like {\"enabled\": true, \"threshold\": 2048, \"step\": 256, \"anchor\": \"camera\"}", fo);
    static const std::vector<std::string> keys = {"enabled", "threshold", "step", "anchor"};
    for (auto e = fo.begin(); e != fo.end(); ++e)
        if (std::find(keys.begin(), keys.end(), e.key()) == keys.end())
            return make_error(at(base + "/" + e.key()) + ": '" + e.key() + "' is not a floating origin setting",
                              did_you_mean(e.key(), keys));
    FloatingOriginSettings v = out;
    FA_TRY(read_bool(fo, "enabled", base, v.enabled));
    auto number = [&](const char* key, double lo, double hi, double& dst, const char* example) -> Result<void> {
        auto it = fo.find(key);
        if (it == fo.end() || it->is_null()) return {};
        const std::string ptr = base + "/" + key;
        if (!it->is_number()) return field_error(ptr, std::string("a number of metres like ") + example, *it);
        const double d = it->get<double>();
        if (!(d >= lo && d <= hi))
            return make_error(at(ptr) + ": " + std::format("{}", d) + " is out of range (at least " +
                                  std::format("{}", lo) + ", at most " + std::format("{}", hi) + " metres)",
                              std::string("Typical value: ") + example + ". Remove the field to use the default.");
        dst = d;
        return {};
    };
    FA_TRY(number("threshold", 16.0, 1.0e7, v.threshold, "2048"));
    // step: an integer power of two (1, 2, 4 ... 1048576), so that moving the origin by a multiple of it is exact in a float at
    // any distance. Left out, it is the largest power of two that is at most 256 and at most threshold.
    if (auto st = fo.find("step"); st != fo.end() && !st->is_null()) {
        const std::string ptr = base + "/step";
        if (!st->is_number()) return field_error(ptr, "a power of two of metres like 256", *st);
        const double d = st->get<double>();
        const bool whole = d == std::floor(d) && d >= 1.0 && d <= 1048576.0;
        const bool pow2 = whole && (std::uint64_t(d) & (std::uint64_t(d) - 1)) == 0;
        if (!pow2)
            return make_error(
                at(ptr) + ": " + std::format("{}", d) + " is not a power of two between 1 and 1048576 (2^20) metres",
                "Use 1, 2, 4, 8 ... 256, 512 ... 1048576: a shift by a power of two is exact in a float, any "
                "other step would round. Typical: 256. Remove the field to use the default.");
        if (d > v.threshold)
            return make_error(
                at(ptr) + ": step " + std::format("{}", d) + " is above threshold " + std::format("{}", v.threshold) +
                    ", so the origin would jump past the anchor",
                "Make step a power of two that is at most threshold: threshold 2048 with step 256 is typical.");
        v.step = d;
    } else {
        double s = 1.0;
        while (s * 2.0 <= std::min(256.0, v.threshold)) s *= 2.0;
        v.step = s;
    }
    if (auto it = fo.find("anchor"); it != fo.end() && !it->is_null()) {
        if (!it->is_string()) return field_error(base + "/anchor", "\"camera\" or \"entity:<id>\"", *it);
        const std::string a = it->get<std::string>();
        const bool named = a.rfind("entity:", 0) == 0 && a.size() > 7;
        if (a != "camera" && !named)
            return make_error(
                at(base + "/anchor") + ": anchor " + describe_json_value(*it) +
                    (a.rfind("entity:", 0) == 0 ? " names no entity" : " is neither \"camera\" nor \"entity:<id>\""),
                "Use \"camera\" (the active 3D camera) or \"entity:player\" (the entity whose id is player).");
        v.anchor = a;
    }
    out = v;
    return {};
}

// Names a plugin cannot take: the areas of the built-in commands (a plugin's commands are "<name>.<verb>") and the
// names scripts already use.
const std::vector<std::string>& reserved_plugin_names() {
    static const std::vector<std::string> names = {
        "ai",      "api",      "app",      "assets",  "audio",    "debug",  "docs",    "editor",   "engine",
        "fa",      "factoria", "feedback", "fs",      "game",     "i18n",   "input",   "jobs",     "level",
        "math",    "mcp",      "nav",      "physics", "play",     "plugin", "plugins", "platform", "prefab",
        "project", "scene",    "script",   "session", "settings", "setup",  "test",    "ui",       "world"};
    return names;
}

bool is_plugin_name(const std::string& n) {
    if (n.empty() || n.size() > 64 || !(n[0] >= 'a' && n[0] <= 'z')) return false;
    return std::all_of(n.begin(), n.end(),
                       [](char c) { return (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_'; });
}

// One entry of "plugins": {"path": "...", "platforms": [...], "optional": false}.
Result<PluginSettings> read_plugin(const std::string& name, const Json& v) {
    const std::string ptr = "/plugins/" + name;
    if (!is_plugin_name(name))
        return make_error(
            at(ptr) + ": '" + name + "' is not a plugin name",
            "Use lower-case letters, digits and underscores, starting with a letter (at most 64), e.g. \"steam\" or "
            "\"play_billing\": scripts call plugins." +
                name + ".<function>() and its commands are <name>.<verb>.");
    const auto& reserved = reserved_plugin_names();
    if (std::find(reserved.begin(), reserved.end(), name) != reserved.end())
        return make_error(at(ptr) + ": '" + name + "' is a name the engine uses (its commands are " + name + ".*)",
                          "Give the plugin another name, e.g. \"" + name +
                              "_plugin\" or the name of the SDK it wraps.");
    if (!v.is_object())
        return field_error(ptr, "an object like {\"path\": \"plugins/" + name + "\"}", v,
                           "\"path\" is the plugin's folder: project-relative, absolute, or with ${VARIABLE} parts.");
    PluginSettings p;
    p.name = name;
    FA_TRY(read_string(v, "path", ptr, p.path));
    if (p.path.empty())
        return make_error(
            at(ptr + "/path") + ": missing or empty",
            "Set the folder that holds the plugin's builds (windows/, macos/, linux/, android/, ios/), e.g. \"path\": "
            "\"plugins/" +
                name + "\" or \"${MY_SDK_PLUGINS}/" + name + "\" for a private folder outside the repository.");
    if (auto it = v.find("platforms"); it != v.end() && !it->is_null()) {
        if (!it->is_array() || it->empty())
            return field_error(
                ptr + "/platforms", "a non-empty array of platform names", *it,
                "List the platforms the plugin is built for, e.g. [\"windows\", \"android\"], or leave it out "
                "for every platform of the game.");
        for (std::size_t k = 0; k < it->size(); ++k) {
            const Json& e = (*it)[k];
            const std::string name_k = e.is_string() ? e.get<std::string>() : std::string();
            const auto& all = platform_names();
            if (std::find(all.begin(), all.end(), name_k) == all.end())
                return make_error(at(ptr + "/platforms/" + std::to_string(k)) + ": " + describe_json_value(e) +
                                      " is not a platform",
                                  "Use windows, macos, linux, ios or android. " + did_you_mean(name_k, all));
            p.platforms.push_back(name_k);
        }
    }
    FA_TRY(read_bool(v, "optional", ptr, p.optional));
    return p;
}

// True when `dir` is the folder fs treats as the project root (the player sets it before the engine starts).
bool is_project_root(std::string_view dir) {
    std::error_code ec;
    stdfs::path a = stdfs::absolute(stdfs::path(std::string(dir)), ec).lexically_normal();
    stdfs::path b = fs::project_root();
    if (!a.has_filename()) a = a.parent_path();
    if (!b.has_filename()) b = b.parent_path();
    return a.generic_string() == b.generic_string();
}

Result<std::string> read_project_text(std::string_view projectDir) {
    // A game pack (fs::mount_pack) holds the project: its factoria.json is in the pack, not next to it on disk.
    if (fs::pack_mounted() && (projectDir.empty() || is_project_root(projectDir)))
        return fs::read_text(kProjectFileName);
    if (!projectDir.empty()) {
        stdfs::path p = stdfs::path(std::string(projectDir)) / kProjectFileName;
        std::error_code ec;
        if (stdfs::is_regular_file(p, ec)) {
            fa::fs::ReadStream in(p, std::ios::binary);
            std::stringstream ss;
            ss << in.rdbuf();
            return ss.str();
        }
    }
    return fs::read_text(projectDir.empty() ? std::string(kProjectFileName) : fs::join(projectDir, kProjectFileName));
}

}  // namespace

// ---- "localization" ---------------------------------------------------------------------------------------------------------
std::vector<std::string> LocalizationSettings::fallback_fonts_for(std::string_view language) const {
    std::vector<std::string> out;
    const auto add = [&](const std::vector<std::string>& fonts) {
        for (const std::string& f : fonts)
            if (std::find(out.begin(), out.end(), f) == out.end()) out.push_back(f);
    };
    for (std::string l(language); !l.empty(); l = base_language(l))
        if (auto it = languageFonts.find(l); it != languageFonts.end()) {
            add(it->second);
            break;
        }
    add(fallbackFonts);
    return out;
}

LocalizationParse parse_localization(const Json& section) {
    LocalizationParse r;
    LocalizationSettings& s = r.settings;
    const auto issue = [&](const std::string& pointer, const std::string& message, const std::string& hint) {
        r.issues.push_back({"/localization" + pointer, message, hint});
    };
    if (section.is_null()) return r;
    if (!section.is_object()) {
        issue("",
              "expected an object like {\"defaultLanguage\": \"en\", \"languages\": [\"en\", \"es\"]}, got " +
                  describe_json_value(section),
              "Declare the game's languages; each has a string table locales/<language>.json (docs/LOCALIZATION.md).");
        return r;
    }
    const std::string tagHint = "Write BCP 47 tags with this case: language lower case, script capitalized, region "
                                "upper case: \"en\", \"pt-BR\", \"zh-Hans\".";
    // A language tag at `pointer`, stored in `into` when it is written the canonical way.
    const auto read_tag = [&](const Json& value, const std::string& pointer, std::string& into) {
        if (!value.is_string()) {
            issue(pointer, "expected a language tag such as \"en\" or \"pt-BR\", got " + describe_json_value(value),
                  tagHint);
            return false;
        }
        const std::string tag = value.get<std::string>();
        if (!is_language_tag(tag)) {
            const std::string fixed = normalize_language_tag(tag);
            issue(pointer,
                  "\"" + tag + "\" is not a language tag" +
                      (fixed.empty() ? std::string() : ". Did you mean \"" + fixed + "\"?"),
                  tagHint);
            return false;
        }
        into = tag;
        return true;
    };
    const auto read_fonts = [&](const Json& value, const std::string& pointer, std::vector<std::string>& into) {
        if (!value.is_array()) {
            issue(pointer, "expected an array of font paths, got " + describe_json_value(value),
                  "List project-relative .ttf or .otf files: [\"assets/fonts/NotoSansJP-Regular.ttf\"].");
            return;
        }
        for (std::size_t i = 0; i < value.size(); ++i) {
            const std::string where = pointer + "/" + std::to_string(i);
            if (!value[i].is_string() || value[i].get<std::string>().empty()) {
                issue(where, "expected the path of a font file, got " + describe_json_value(value[i]),
                      "A project-relative path such as \"assets/fonts/NotoSansJP-Regular.ttf\".");
                continue;
            }
            const std::string raw = value[i].get<std::string>();
            const std::string path = fs::is_absolute(raw) ? std::string() : fs::normalize(raw);
            if (path.empty()) {
                issue(where, "\"" + raw + "\" is not a path inside the project",
                      "Copy the font into the project (assets/fonts/) and write its project-relative path with forward "
                      "slashes.");
                continue;
            }
            into.push_back(path);
        }
    };

    static const std::vector<std::string> keys = {"defaultLanguage", "languages", "fallbackFonts", "languageFonts"};
    for (auto it = section.begin(); it != section.end(); ++it)
        if (std::find(keys.begin(), keys.end(), it.key()) == keys.end())
            r.warnings.push_back(
                {"/localization/" + it.key(),
                 "unknown key \"" + it.key() + "\" in \"localization\" (ignored). " + did_you_mean(it.key(), keys),
                 "Remove it or fix the spelling."});

    std::string def;
    bool hasDefault = false;
    if (auto it = section.find("defaultLanguage"); it != section.end() && !it->is_null())
        hasDefault = read_tag(*it, "/defaultLanguage", def);
    bool languagesBad = false;
    if (auto it = section.find("languages"); it != section.end() && !it->is_null()) {
        if (!it->is_array() || it->empty()) {
            issue("/languages", "expected a non-empty array of language tags, got " + describe_json_value(*it),
                  "List the languages the game ships, e.g. [\"en\", \"es\"]; each needs locales/<tag>.json.");
            languagesBad = true;
        } else {
            for (std::size_t i = 0; i < it->size(); ++i) {
                std::string tag;
                const std::string pointer = "/languages/" + std::to_string(i);
                if (!read_tag((*it)[i], pointer, tag)) {
                    languagesBad = true;
                } else if (std::find(s.languages.begin(), s.languages.end(), tag) != s.languages.end()) {
                    issue(pointer, "\"" + tag + "\" is listed twice", "Remove the repeat.");
                    languagesBad = true;
                } else {
                    s.languages.push_back(tag);
                }
            }
        }
    } else if (hasDefault) {
        s.languages.push_back(def);  // a game with one language
    } else {
        issue("/languages", "missing: the section needs the languages of the game",
              "Add \"languages\": [\"en\", \"es\"] (and a locales/<tag>.json for each), or remove the \"localization\" "
              "section.");
        languagesBad = true;
    }
    if (hasDefault && !languagesBad && std::find(s.languages.begin(), s.languages.end(), def) == s.languages.end())
        issue("/defaultLanguage", "\"" + def + "\" is not one of \"languages\". " + did_you_mean(def, s.languages),
              "Add it to \"languages\" or choose one of them.");
    else if (!s.languages.empty())
        s.defaultLanguage = hasDefault ? def : s.languages.front();

    if (auto it = section.find("fallbackFonts"); it != section.end() && !it->is_null())
        read_fonts(*it, "/fallbackFonts", s.fallbackFonts);
    if (auto it = section.find("languageFonts"); it != section.end() && !it->is_null()) {
        if (!it->is_object()) {
            issue("/languageFonts",
                  "expected an object mapping a language to its fonts, got " + describe_json_value(*it),
                  "Example: \"languageFonts\": {\"zh-Hans\": [\"assets/fonts/NotoSansSC-Regular.ttf\"]}.");
        } else {
            for (auto lf = it->begin(); lf != it->end(); ++lf) {
                const std::string pointer = "/languageFonts/" + lf.key();
                if (!is_language_tag(lf.key())) {
                    issue(pointer, "\"" + lf.key() + "\" is not a language tag", tagHint);
                    continue;
                }
                if (!languagesBad && std::find(s.languages.begin(), s.languages.end(), lf.key()) == s.languages.end()) {
                    issue(pointer,
                          "\"" + lf.key() + "\" is not one of \"languages\". " + did_you_mean(lf.key(), s.languages),
                          "Use the tag as it is written in \"languages\".");
                    continue;
                }
                read_fonts(*lf, pointer, s.languageFonts[lf.key()]);
            }
        }
    }
    return r;
}

Result<ProjectSettings> load_project(std::string_view projectDir) {
    auto text = read_project_text(projectDir);
    if (!text.ok())
        return make_error(
            "Cannot read " + std::string(kProjectFileName) + " in '" + std::string(projectDir) +
                "': " + text.error().message,
            "Run from the project folder, pass --project <dir>, or create a project with `factoria new`.");
    auto parsed = parse_json(text.value(), (stdfs::path(std::string(projectDir)) / kProjectFileName).generic_string());
    if (!parsed.ok()) return parsed.error();
    const Json& j = parsed.value();
    if (!j.is_object())
        return make_error(at("") + ": the project file must be a JSON object, got " + describe_json_value(j),
                          "Start from {\"format\": \"factoria.project/1\", \"name\": \"My Game\"}.");

    ProjectSettings s;
    s.raw = j;
    if (auto it = j.find("format"); it != j.end() && it->is_string() && it->get<std::string>() != "factoria.project/1")
        return make_error(at("/format") + ": unsupported format '" + it->get<std::string>() + "'",
                          "Use \"factoria.project/1\" (this engine is " + std::string(FA_ENGINE_VERSION) + ").");

    // Default the name to the folder name when absent.
    {
        std::string dirName = stdfs::path(std::string(projectDir)).filename().string();
        if (dirName.empty() || dirName == ".") {
            // "" means the current directory; libstdc++'s absolute("") throws (MSVC's does not).
            std::error_code ec;
            dirName = stdfs::absolute(stdfs::path(projectDir.empty() ? "." : std::string(projectDir)), ec)
                          .parent_path()
                          .filename()
                          .string();
        }
        if (!dirName.empty()) s.name = dirName;
    }
    FA_TRY(read_string(j, "name", "", s.name));
    FA_TRY(read_string(j, "id", "", s.id));
    FA_TRY(read_string(j, "version", "", s.version));
    FA_TRY(read_string(j, "engine", "", s.engineVersion));
    FA_TRY(read_string(j, "mainScene", "", s.mainScene));
    FA_TRY(read_string(j, "feedbackFile", "", s.feedbackFile));
    FA_TRY(read_string(j, "icon", "", s.icon));
    FA_TRY(read_bool(j, "pauseOnSuspend", "", s.pauseOnSuspend));

    if (auto it = j.find("display"); it != j.end() && !it->is_null()) {
        if (!it->is_object()) return field_error("/display", "an object like {\"width\": 1280, \"height\": 720}", *it);
        FA_TRY(read_int(*it, "width", "/display", s.width, 16));
        FA_TRY(read_int(*it, "height", "/display", s.height, 16));
        FA_TRY(read_bool(*it, "fullscreen", "/display", s.fullscreen));
        FA_TRY(read_bool(*it, "vsync", "/display", s.vsync));
        FA_TRY(read_bool(*it, "pixelArt", "/display", s.pixelArt));
        FA_TRY(read_string(*it, "orientation", "/display", s.orientation));
        if (s.orientation != "landscape" && s.orientation != "portrait" && s.orientation != "any")
            return make_error(at("/display/orientation") + ": unknown orientation '" + s.orientation + "'",
                              "Use \"landscape\", \"portrait\" or \"any\".");
        if (auto m = it->find("scaleMode"); m != it->end() && !m->is_null()) {
            if (!m->is_string() || !parse_scale_mode(m->get<std::string>(), s.scaleMode))
                return make_error(at("/display/scaleMode") + ": unknown scale mode " + describe_json_value(*m),
                                  "Use \"fit\", \"stretch\", \"expand\" or \"pixel-perfect\".");
        }
    }
    if (auto it = j.find("physics"); it != j.end() && !it->is_null()) {
        if (!it->is_object()) return field_error("/physics", "an object like {\"fixedHz\": 60}", *it);
        FA_TRY(read_double(*it, "fixedHz", "/physics", s.fixedHz, 1.0, false));
        double ppm = s.pixelsPerMeter;
        FA_TRY(read_double(*it, "pixelsPerMeter", "/physics", ppm, 0.0, true));
        s.pixelsPerMeter = float(ppm);
    }
    if (auto it = j.find("render"); it != j.end() && !it->is_null()) {
        if (!it->is_object()) return field_error("/render", "an object like {\"interpolation\": true}", *it);
        FA_TRY(read_bool(*it, "interpolation", "/render", s.renderInterpolation));
        FA_TRY(read_bool(*it, "asyncCompute", "/render", s.renderAsyncCompute));
        FA_TRY(read_bool(*it, "multiThreadRecording", "/render", s.renderMultiThreadRecording));
        double snap = s.renderInterpolationSnapDistance;
        FA_TRY(read_double(*it, "interpolationSnapDistance", "/render", snap, 0.0, false));
        s.renderInterpolationSnapDistance = float(snap);
        if (auto up = it->find("upscaler"); up != it->end() && !up->is_null()) {
            Result<render::UpscalerSettings> upscalerSet =
                render::parse_upscaler_settings(*up, at("/render/upscaler"), render::UpscalerSettings{});
            if (!upscalerSet.ok()) return upscalerSet.error();
            s.upscaler = upscalerSet.value();
        }
        if (auto lat = it->find("latency"); lat != it->end() && !lat->is_null()) {
            Result<render::LatencySettings> latencySet =
                render::parse_latency_settings(*lat, at("/render/latency"), render::LatencySettings{});
            if (!latencySet.ok()) return latencySet.error();
            s.latency = latencySet.value();
        }
        if (auto fg = it->find("frameGeneration"); fg != it->end() && !fg->is_null()) {
            Result<render::FrameGenSettings> frameGenSet =
                render::parse_frame_gen_settings(*fg, at("/render/frameGeneration"), render::FrameGenSettings{});
            if (!frameGenSet.ok()) return frameGenSet.error();
            s.frameGeneration = frameGenSet.value();
        }
        if (auto rt = it->find("rayTracing"); rt != it->end() && !rt->is_null()) {
            Result<render::RayTracingSettings> rayTracingSet =
                render::parse_ray_tracing_settings(*rt, at("/render/rayTracing"), render::RayTracingSettings{});
            if (!rayTracingSet.ok()) return rayTracingSet.error();
            s.rayTracing = rayTracingSet.value();
        }
        if (auto pt = it->find("pathTracer"); pt != it->end() && !pt->is_null()) {
            Result<render::PathTracerSettings> pathTracerSet =
                render::parse_path_tracer_settings(*pt, at("/render/pathTracer"), render::PathTracerSettings{});
            if (!pathTracerSet.ok()) return pathTracerSet.error();
            s.pathTracer = pathTracerSet.value();
        }
        if (auto dr = it->find("dynamicResolution"); dr != it->end() && !dr->is_null()) {
            Result<render::DynamicResolutionSettings> dynamicSet = render::parse_dynamic_resolution_settings(
                *dr, at("/render/dynamicResolution"), render::DynamicResolutionSettings{});
            if (!dynamicSet.ok()) return dynamicSet.error();
            s.dynamicResolution = dynamicSet.value();
        }
        if (auto gp = it->find("graphicsPreset"); gp != it->end() && !gp->is_null()) {
            std::optional<render::GraphicsPreset> preset;
            if (gp->is_string()) preset = render::parse_graphics_preset(gp->get<std::string>());
            if (!preset) {
                std::vector<std::string> names;
                for (std::string_view n : render::kGraphicsPresetNames) names.emplace_back(n);
                return make_error(at("/render/graphicsPreset") + ": unknown graphics preset " +
                                      describe_json_value(*gp),
                                  gp->is_string() ? did_you_mean(gp->get<std::string>(), names)
                                                  : "Use \"low\", \"medium\", \"high\", \"ultra\" or \"custom\".");
            }
            s.graphicsPreset = *preset;
        }
        if (auto be = it->find("backend"); be != it->end() && !be->is_null()) {
            std::optional<GpuBackend> asked;  // not `parsed`: that one is the whole file (MSVC C4456)
            if (be->is_string()) asked = parse_gpu_backend_name(be->get<std::string>());
            if (!asked) {
                std::vector<std::string> names = gpu_backend_names();
                std::string list = "\"auto\"";
                for (const std::string& n : names) list += ", \"" + n + "\"";
                names.push_back("auto");
                std::string hint = be->is_string() ? did_you_mean(be->get<std::string>(), names) : std::string();
                if (!hint.empty()) hint += " ";
                return make_error(at("/render/backend") + ": unknown GPU backend " + describe_json_value(*be),
                                  hint + "Use one of " + list + ".");
            }
            s.renderBackend = gpu_backend_name(*asked);
        }
    }
    if (auto it = j.find("world"); it != j.end() && !it->is_null()) {
        if (!it->is_object())
            return field_error("/world", "an object like {\"floatingOrigin\": {\"enabled\": true}}", *it);
        static const std::vector<std::string> worldKeys = {"floatingOrigin"};
        for (auto e = it->begin(); e != it->end(); ++e)
            if (std::find(worldKeys.begin(), worldKeys.end(), e.key()) == worldKeys.end())
                return make_error(at("/world/" + e.key()) + ": '" + e.key() + "' is not a \"world\" setting",
                                  did_you_mean(e.key(), worldKeys));
        if (auto fo = it->find("floatingOrigin"); fo != it->end() && !fo->is_null()) {
            FA_TRY(read_floating_origin(*fo, s.floatingOrigin));
        }
    }
    if (auto it = j.find("storage"); it != j.end() && !it->is_null()) {
        if (!it->is_object()) return field_error("/storage", "an object like {\"encryptionSecret\": \"...\"}", *it);
        std::string secret;
        FA_TRY(read_string(*it, "encryptionSecret", "/storage", secret));
        if (it->contains("encryptionSecret") && !(*it)["encryptionSecret"].is_null() && secret.size() < 16)
            return make_error(
                at("/storage/encryptionSecret") + ": the secret is " + std::to_string(secret.size()) +
                    " characters, too short to be a key",
                "Do not write it by hand: delete the field and run `factoria call "
                "project.create_storage_secret` for a random one (saves written with the old secret cannot "
                "be opened afterwards).");
    }
    if (auto it = j.find("runtime"); it != j.end() && !it->is_null()) {
        if (!it->is_object()) return field_error("/runtime", "an object like {\"jobThreads\": \"auto\"}", *it);
        if (auto jt = it->find("jobThreads"); jt != it->end() && !jt->is_null()) {
            auto threads = jobs::parse_settings(*jt, at("/runtime/jobThreads"));
            if (!threads) return threads.error();
            s.jobThreads = threads.value();
            s.jobThreadsSet = true;
        }
        // Background loading budgets (docs/PERFORMANCE.md, "Background loading"): a number in a range, else an error that
        // names the field and the range.
        auto budget = [&](const char* key, double maxValue, double& out, const char* example) -> Result<void> {
            auto b = it->find(key);
            if (b == it->end() || b->is_null()) return {};
            const std::string ptr = std::string("/runtime/") + key;
            if (!b->is_number()) return field_error(ptr, std::string("a number like ") + example, *b);
            const double v = b->get<double>();
            if (!(v > 0.0) || v > maxValue)
                return make_error(at(ptr) + ": " + std::format("{}", v) + " is out of range (more than 0, at most " +
                                      std::format("{}", maxValue) + ")",
                                  std::string("Typical value: ") + example + ". Remove the field to use the default.");
            out = v;
            return {};
        };
        FA_TRY(budget("loadBudgetMs", 100.0, s.loadBudgetMs, "4"));
        FA_TRY(budget("uploadBudgetMB", 1024.0, s.uploadBudgetMB, "16"));
        // The script budgets: a number, or {"default": n, "<platform>": n}. The script system resolves the value for the platform
        // it runs on (fa/script/script_budget.h); here the file is only checked.
        auto per_platform = [&](const char* key, double lo, double hi, const char* unit, const char* example,
                                const char* what) -> Result<void> {
            auto b = it->find(key);
            if (b == it->end()) return {};  // absent: the default (null is an error, as in the schema)
            const std::string ptr = std::string("/runtime/") + key;
            const std::string shape = std::string("a number of ") + unit + " like " + example +
                                      ", or an object with one number per platform like {\"default\": " + example +
                                      ", \"android\": ...}";
            auto check = [&](const Json& v, const std::string& at_ptr) -> Result<void> {
                if (!v.is_number()) return field_error(at_ptr, "a number of " + std::string(unit), v, what);
                const double d = v.get<double>();
                if (!(d >= lo && d <= hi))
                    return make_error(at(at_ptr) + ": " + std::format("{}", d) + " is out of range (at least " +
                                          std::format("{}", lo) + ", at most " + std::format("{}", hi) + " " + unit +
                                          ")",
                                      what);
                return {};
            };
            if (b->is_object()) {
                std::vector<std::string> keys = {"default"};
                for (const std::string& p : platform_names()) keys.push_back(p);
                for (auto e = b->begin(); e != b->end(); ++e) {
                    if (std::find(keys.begin(), keys.end(), e.key()) == keys.end())
                        return make_error(
                            at(ptr + "/" + e.key()) + ": '" + e.key() + "' is neither \"default\" nor a platform",
                            did_you_mean(e.key(), keys) + " Use \"default\" for every platform not named.");
                    FA_TRY(check(e.value(), ptr + "/" + e.key()));
                }
                return {};
            }
            if (!b->is_number()) return field_error(ptr, shape, *b, what);
            return check(*b, ptr);
        };
        FA_TRY(
            per_platform("scriptMemoryMB", kMinScriptMemoryMB, kMaxScriptMemoryMB, "megabytes", "768",
                         "The heap cap of the scripts (default 768 on every platform). Example: \"scriptMemoryMB\": "
                         "{\"default\": 768, \"android\": 384, \"web\": 256}. Remove the field to use the default."));
        FA_TRY(per_platform(
            "scriptFrameBudgetMs", 0.0, kMaxScriptFrameBudgetMs, "milliseconds", "8",
            "The script time of one frame above which the engine warns (default 8; 0 turns the warning off). "
            "Example: \"scriptFrameBudgetMs\": {\"default\": 8, \"android\": 12}."));
    }
    if (auto it = j.find("input"); it != j.end() && !it->is_null()) {
        if (!it->is_object()) return field_error("/input", "an object like {\"actions\": {...}}", *it);
        if (auto a = it->find("actions"); a != it->end() && !a->is_null()) {
            if (!a->is_object())
                return field_error("/input/actions", "an object mapping action names to binding lists", *a,
                                   "Example: \"actions\": {\"jump\": [\"Space\", \"W\"]}");
            for (auto ai = a->begin(); ai != a->end(); ++ai) {
                if (!ai->is_array())
                    return field_error("/input/actions/" + ai.key(), "an array of binding names", *ai,
                                       "Example: \"" + ai.key() + "\": [\"Space\"]");
                for (std::size_t k = 0; k < ai->size(); ++k)
                    if (!(*ai)[k].is_string())
                        return field_error("/input/actions/" + ai.key() + "/" + std::to_string(k),
                                           "a binding name string", (*ai)[k],
                                           "Binding names look like \"Space\", \"A\", \"MouseLeft\" or, with modifiers "
                                           "held, \"Ctrl+Z\", \"Shift+MouseLeft\".");
            }
            s.inputActions = *a;
        }
        if (auto sc = it->find("schemes"); sc != it->end() && !sc->is_null()) {
            if (!sc->is_object())
                return field_error("/input/schemes", "an object mapping scheme names to key sets", *sc,
                                   "Example: \"schemes\": {\"arrows\": {\"extends\": \"right\"}}; the actions and key "
                                   "names are checked when the game starts.");
            s.inputSchemes = *sc;
        }
        if (auto d = it->find("deadzone"); d != it->end() && !d->is_null()) {
            if (!d->is_number()) return field_error("/input/deadzone", "a number from 0 to 0.95", *d);
            double v = d->get<double>();
            if (!(v >= 0.0 && v < 1.0))
                return make_error(
                    at("/input/deadzone") + ": value " + std::to_string(v) + " must be at least 0 and below 1",
                    "Typical values: 0.1 (precise sticks) to 0.3 (worn or drifting sticks); the default is 0.2.");
            s.inputDeadzone = v;
        }
    }
    if (auto it = j.find("ui"); it != j.end() && !it->is_null()) {
        if (!it->is_object()) return field_error("/ui", "an object like {\"scale\": 1.25}", *it);
        if (auto sc = it->find("scale"); sc != it->end() && !sc->is_null()) {
            if (!sc->is_number()) return field_error("/ui/scale", "a number from 0.5 to 3", *sc);
            const double v = sc->get<double>();
            if (!(v >= 0.5 && v <= 3.0))
                return make_error(
                    at("/ui/scale") + ": value " + std::to_string(v) + " must be from 0.5 to 3",
                    "1 keeps the interface as authored; 1.25 makes every screen-space widget and its text 25% bigger "
                    "(docs/TEXT.md, \"Interface size\"). The Options menu and scripts change it with ui.scale.");
            s.uiScale = float(v);
        }
        if (auto mr = it->find("mirrorRtl"); mr != it->end() && !mr->is_null()) {
            if (!mr->is_boolean()) return field_error("/ui/mirrorRtl", "true or false", *mr);
            s.uiMirrorRtl = mr->get<bool>();
        }
        Result<UiTooltipSettings> tip = parse_tooltip_settings(*it, at("/ui"));
        if (!tip.ok()) return tip.error();
        s.uiTooltip = tip.value();
    }
    if (auto it = j.find("platforms"); it != j.end() && !it->is_null()) {
        if (!it->is_array()) return field_error("/platforms", "an array of platform names", *it);
        for (std::size_t k = 0; k < it->size(); ++k) {
            if (!(*it)[k].is_string()) return field_error("/platforms/" + std::to_string(k), "a string", (*it)[k]);
            s.platforms.push_back((*it)[k].get<std::string>());
        }
    }
    if (auto it = j.find("plugins"); it != j.end() && !it->is_null()) {
        if (!it->is_object())
            return field_error("/plugins", "an object mapping plugin names to their folders", *it,
                               "Example: \"plugins\": {\"example\": {\"path\": \"plugins/example\"}}");
        for (auto pi = it->begin(); pi != it->end(); ++pi) {
            auto plugin = read_plugin(pi.key(), *pi);
            if (!plugin.ok()) return plugin.error();
            s.plugins.push_back(std::move(plugin.value()));
        }
        std::sort(s.plugins.begin(), s.plugins.end(),
                  [](const PluginSettings& a, const PluginSettings& b) { return a.name < b.name; });
    }
    if (auto it = j.find("localization"); it != j.end() && !it->is_null()) {
        LocalizationParse loc = parse_localization(*it);
        if (!loc.ok()) {
            const LocalizationIssue& first = loc.issues.front();
            std::string more;
            if (loc.issues.size() > 1)
                more = " (and " + std::to_string(loc.issues.size() - 1) +
                       " more problem(s) in \"localization\"; `factoria validate` lists them all)";
            return make_error(at(first.pointer) + ": " + first.message + more, first.hint);
        }
        s.localization = std::move(loc.settings);
    }
    return s;
}

Result<void> save_project(std::string_view projectDir, const ProjectSettings& settings) {
    std::string path = projectDir.empty() ? std::string(kProjectFileName) : fs::join(projectDir, kProjectFileName);
    std::string text = dump_json(settings.to_json());
    if (!projectDir.empty() && fs::is_absolute(projectDir)) {
        std::error_code ec;
        stdfs::create_directories(stdfs::path(std::string(projectDir)), ec);
        std::ofstream out(stdfs::path(std::string(projectDir)) / kProjectFileName, std::ios::binary);
        if (!out) return make_error("Cannot write " + path, "Check that the folder exists and is writable.");
        out << text;
        return {};
    }
    return fs::write_text(path, text);
}

std::string find_project_root(std::string_view startDir) {
    std::error_code ec;
    stdfs::path p = stdfs::absolute(stdfs::path(startDir.empty() ? "." : std::string(startDir)), ec).lexically_normal();
    if (p.has_filename() == false && p.has_parent_path()) p = p.parent_path();
    while (!p.empty()) {
        if (stdfs::is_regular_file(p / kProjectFileName, ec)) return p.generic_string();
        stdfs::path parent = p.parent_path();
        if (parent == p) break;
        p = parent;
    }
    return {};
}

namespace {
constexpr const char* kSchemaText =
    // Several literals: MSVC limits a single string literal to about 16 KB. Keep in sync with schemas/project.schema.json (runtime_tests checks it).
    R"JSON({
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://factoria.dev/schemas/project.schema.json",
  "title": "FactorIA factoria.json",
  "description": "Project file at the root of every FactorIA game. Unknown keys are kept but ignored by the engine.",
  "type": "object",
  "required": [
    "format",
    "name"
  ],
  "properties": {
    "$schema": {
      "type": "string",
      "description": "Optional schema reference for editors."
    },
    "format": {
      "const": "factoria.project/1",
      "description": "File format identifier. Always \"factoria.project/1\"."
    },
    "name": {
      "type": "string",
      "minLength": 1,
      "description": "Human-readable game name shown in window titles and stores."
    },
    "id": {
      "type": "string",
      "pattern": "^[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+$",
      "description": "Reverse-DNS identifier used for mobile bundles, e.g. \"com.example.spacedodge\"."
    },
    "version": {
      "type": "string",
      "description": "Game version, semantic versioning, e.g. \"0.1.0\"."
    },
    "engine": {
      "type": "string",
      "description": "Engine version the game was made with, e.g. \"0.1\"."
    },
    "mainScene": {
      "type": "string",
      "description": "Project-relative path of the scene loaded at startup, e.g. \"scenes/main.scene.json\"."
    },
    "pauseOnSuspend": {
      "type": "boolean",
      "description": "Default true. While the app is in the background (a phone's home button or an incoming call) the engine freezes the game (game.paused becomes true, unless a game.on(\"suspend\") handler paused it already) and silences the music and every sound, and unfreezes both when the app comes back. Set false to decide yourself in game.on(\"suspend\") and game.on(\"resume\") handlers. A window that merely loses the focus is never paused (use game.on(\"blur\")). docs/MOBILE.md, Lifecycle."
    },
    "ui": {
      "type": "object",
      "description": "Screen-space interface settings.",
      "properties": {
        "scale": {
          "type": "number",
          "minimum": 0.5,
          "maximum": 3,
          "description": "The interface scale the game starts with (default 1): the size, offset, padding, spacing, margins and font size of every screen-space widget (Panel, Button, Label, Text with space \"screen\"...) are multiplied by it, on top of the text size option (ui.textScale). Scripts and the Options menu change it while the game runs (ui.scale = 1.25, the ui.set_scale command); tests start from this value. docs/TEXT.md, \"Interface size\"."
        },
        "mirrorRtl": {
          "type": "boolean",
          "description": "Whether a right-to-left language (i18n.direction \"rtl\") mirrors the screen-space UI (default true): anchor.x, pivot.x and position.x flip, Toggle boxes and Sliders run right to left, and a widget with UiBox.mirror false stays. Scripts change it with ui.mirrorRtl, the ui.set_mirror_rtl command too. docs/LOCALIZATION.md, \"Right-to-left text\"."
        },
        "tooltipDelay": {
          "type": "number",
          "minimum": 0,
          "maximum": 60,
          "description": "Seconds the pointer rests on a widget before its tooltip shows (default 0.5; 0 = at once). Scripts change it with ui.tooltipDelay. docs/MENUS.md, \"Tooltips\"."
        },
        "tooltipOnTouch": {
          "type": "boolean",
          "description": "Default false: tooltips stay off while the last input was a touch (a finger has no hover). true shows them there too."
        },
        "tooltip": {
          "type": "object",
          "description": "The look of every tooltip (the UI theme for them); sizes are UI units. Keys: color and textColor and titleColor (colours), texture and slice (a 9-slice background), font, fontSize, titleSize, maxWidth (lines wrap here), spacing, padding [l, t, r, b], gap (from the pointer), layer (draw order).",
          "additionalProperties": false,
          "properties": {
            "color": {}, "textColor": {}, "titleColor": {}, "texture": {"type": "string"}, "slice": {}, "font": {"type": "string"},
            "fontSize": {"type": "number"}, "titleSize": {"type": "number"}, "maxWidth": {"type": "number"}, "spacing": {"type": "number"},
            "padding": {}, "gap": {"type": "number"}, "layer": {"type": "integer"}
          }
        }
      }
    },
    "display": {
      "type": "object",
      "description": "Window and design-resolution settings. The game always renders at the design resolution.",
      "properties": {
        "width": {
          "type": "integer",
          "minimum": 16,
          "description": "Design width in pixels."
        },
        "height": {
          "type": "integer",
          "minimum": 16,
          "description": "Design height in pixels."
        },
        "scaleMode": {
          "enum": [
            "fit",
            "stretch",
            "expand",
            "pixel-perfect"
          ],
          "description": "How the design resolution maps to the window: fit (keep aspect, letterbox), stretch (fill the window, distort), expand (keep aspect, grow the visible area on the long axis), pixel-perfect (integer scaling, letterbox). Default \"fit\". The loader also accepts any capitalisation and \"pixelPerfect\"."
        },
        "fullscreen": {
          "type": "boolean",
          "description": "Start in fullscreen."
        },
        "vsync": {
          "type": "boolean",
          "description": "Synchronize presentation with the display refresh."
        },
        "orientation": {
          "enum": [
            "landscape",
            "portrait",
            "any"
          ],
          "description": "Allowed screen orientation on mobile."
        },
        "pixelArt": {
          "type": "boolean",
          "description": "Use nearest-neighbour filtering when scaling the final image."
        }
      }
    },
    "physics": {
      "type": "object",
      "description": "Simulation settings.",
      "properties": {
        "fixedHz": {
          "type": "number",
          "minimum": 1,
          "description": "Fixed simulation steps per second (default 60)."
        },
        "pixelsPerMeter": {
          "type": "number",
          "exclusiveMinimum": 0,
          "description": "2D world units per physics meter (default 100)."
        }
      }
    },
    "render": {
      "type": "object",
      "description": "Drawing settings.",
      "properties": {
        "interpolation": {
          "type": "boolean",
          "default": false,
          "description": "Draw entities at the pose between the last two fixed simulation steps, so a 60 Hz simulation looks smooth on a 120-144 Hz display (the picture is one step behind the simulation). Only the drawing changes: Transform, physics and scripts see the real pose. Cameras, physics bodies and children of interpolated entities are included; a Transform written outside the fixed step, a new entity and entity.teleport() are not smeared. The Interpolation component overrides it per entity. Default false (docs/RENDERING.md, \"Render interpolation\")."
        },
        "interpolationSnapDistance": {
          "type": "number",
          "minimum": 0,
          "default": 0,
          "description": "With interpolation: a fixed step that moves an entity farther than this many world units (pixels in 2D) is a jump and is drawn without blending. 0 (default) = no limit; use entity.teleport() for known jumps."
)JSON"
    R"JSON(        },
        "upscaler": {
          "type": "object",
          "description": "How the picture drawn at a lower resolution reaches the screen (M76, docs/UPSCALING.md). A game-wide setting that scripts change at run time with window.upscaler and the command render.upscaler. M76 stores and reports it; every mode still draws as \"stretch\" until the renderer learns the others.",
          "additionalProperties": false,
          "properties": {
            "mode": {
              "type": "string",
              "enum": ["stretch", "spatial", "temporal", "metalfx", "dlss", "xess", "fsr", "auto"],
              "default": "stretch",
              "description": "stretch = the plain blit of today; spatial = edge-adaptive upscale plus sharpen of one frame; temporal = jittered frames accumulated at the output size; metalfx = Apple's MetalFX (Metal only); dlss = NVIDIA DLSS (an RTX GPU, Windows, `factoria setup streamline`); xess = Intel XeSS (Windows, `factoria setup xess`); fsr = AMD FSR 3.1 (Windows, D3D12 or Vulkan, `factoria setup fidelityfx`); auto = the GPU maker's own SDK when it is installed, else the best this GPU can draw. A mode that cannot run draws as the next best (effectiveMode says which). Default stretch."
            },
            "quality": {
              "type": "string",
              "enum": ["native", "quality", "balanced", "performance", "ultraPerformance"],
              "default": "native",
              "description": "How much smaller than the output the frame is drawn: native 1, quality 1/1.5, balanced 1/1.7, performance 1/2, ultraPerformance 1/3 of the output's width and height. Default native."
            },
            "sharpness": {
              "type": "number",
              "minimum": 0,
              "maximum": 1,
              "default": 0.5,
              "description": "Strength of the contrast-adaptive sharpen of the spatial and temporal modes, from 0 (none) to 1. Default 0.5."
            },
            "rayReconstruction": {
              "type": "boolean",
              "default": false,
              "description": "With mode \"dlss\", or \"auto\" where it picks DLSS: draw with NVIDIA DLSS Ray Reconstruction (the denoiser-upscaler of DLSS 3.5, through Streamline) instead of Super Resolution, on an NVIDIA RTX GPU on D3D12 or Vulkan with the Streamline SDK and its Ray Reconstruction plugin installed (`factoria setup streamline`) and a linear frame without a final pass; where it cannot run (render.supports \"dlssRayReconstruction\" says why) or the SDK refuses it, the frame draws with Super Resolution and the log says why once. An opt-in preview: the renderer has no ray-traced signals to denoise yet (M79) and its guides are approximations (docs/UPSCALING_VENDORS.md, \"DLSS Ray Reconstruction\"). Its plugin is loaded when the game starts, and only when the project's mode is dlss or auto, so the project setting (not a later window.upscaler change) is what makes it available. Ignored by every other mode. Default false."
            }
          }
        },
)JSON"
    R"JSON(        "latency": {
          "type": "object",
          "description": "Low latency (M78, docs/LATENCY.md): the loop waits before it reads the player's input so the frame that shows a press is as new as possible. A game-wide setting that the command render.latency changes at run time. Off by default (the loop of every earlier version). The profiler reports the measured input-to-present time (profile.latency) while it is on.",
          "additionalProperties": false,
          "properties": {
            "mode": {
              "type": "string",
              "enum": ["off", "auto", "reflex", "antilag2", "xell"],
              "default": "off",
              "description": "off = no pacing; auto = the SDK of the GPU's maker when it is usable (AMD: Anti-Lag 2, Intel: XeLL, NVIDIA: Reflex), else the engine's own pacing; reflex = NVIDIA Reflex (Windows, D3D12 or Vulkan on an NVIDIA GPU, Streamline: `factoria setup streamline`); antilag2 = AMD Anti-Lag 2 (Windows, D3D12 or Vulkan on a Radeon GPU, in the driver); xell = Intel XeSS Low Latency (Windows, D3D12, `factoria setup xess`). A mode whose SDK cannot run uses the engine's own pacing, which needs a window and the display's vsync (render.latency says why). Default off."
            },
            "boost": {
              "type": "boolean",
              "default": false,
              "description": "The vendor's boost: the GPU clocks stay up while the game waits, for less latency at more power (Reflex boost, XeLL). Anti-Lag 2 and the engine's own pacing have no such switch and ignore it. Default false."
            }
          }
        },
        "frameGeneration": {
          "type": "object",
          "description": "Frame generation (M78, docs/FRAME_GENERATION.md): a vendor SDK puts a generated frame between two rendered ones, so the display shows more frames than the game renders. A game-wide setting that the command render.frame_generation reads and changes at run time. Off by default (the swapchain of every earlier version). It needs a game window on D3D12 or Vulkan, the temporal upscaler (render.upscaler, a render scale below 1) and the provider's SDK (`factoria setup`); render.frame_generation says why a mode does not run. The profiler reports the base and presented frame rates and the generated frames (profile.frameGeneration).",
          "additionalProperties": false,
          "properties": {
            "mode": {
              "type": "string",
              "enum": ["off", "auto", "dlss", "fsr", "xess"],
              "default": "off",
              "description": "off = no frame generation; auto = the SDK of the GPU's maker (NVIDIA: dlss, AMD: fsr, Intel: xess); dlss = NVIDIA DLSS frame generation (Windows, D3D12 or Vulkan, an RTX GPU, through Streamline); fsr = AMD FSR 3 frame generation (Windows, D3D12 or Vulkan, any GPU, FidelityFX); xess = Intel XeSS frame generation (Windows, D3D12, an Arc GPU). A mode whose SDK cannot run draws the rendered frames only, and render.frame_generation says why. Turning a provider on needs the start of the run (it owns the swapchain). Default off."
            },
            "minBaseFps": {
              "type": "integer",
              "minimum": 0,
              "maximum": 1000,
              "default": 60,
              "description": "The frame rate the game renders at (generated frames not counted) below which generation is switched off: a generated frame between two slow ones adds delay and shows artefacts. It turns on again at 10% above it. 0 = never switch off. Default 60."
            }
          }
        },
        "rayTracing": {
          "type": "object",
          "description": "Ray tracing (M79, docs/RAY_TRACING.md): which effects the renderer traces with rays on a GPU that can (D3D12, Vulkan or Metal; renderer.supports(\"raytracing\") says whether this one can). A game-wide setting that the command render.ray_tracing reads and changes at run time. Off by default and free when off: no acceleration structure is made, no pass is added to the frame. In this version the renderer builds the scene's acceleration structures when an effect is on, and the shadow of the directional light that casts shadows (shadows hard) is traced with rays, and so are the ambient occlusion (ao, in place of the screen-space one), the sharp reflections (reflections) and the refraction through glass and liquids (translucency, in place of the screen-space one); global illumination does not draw with rays yet.",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": false,
              "description": "The master switch. false = nothing below is read and nothing is paid. Default false."
            },
            "shadows": {
              "type": "string",
              "enum": ["off", "hard", "soft"],
              "default": "off",
              "description": "off = the shadow maps of the lighting; hard = one ray per pixel towards the sun (a sharp edge); soft = raysPerPixel rays towards points of the sun's disc, denoised (the edge softens with the distance to the caster; the disc is the scene setting skySunSize). The directional light that casts shadows is traced, and so are the point, spot and area lights that cast shadows: the 3 most important ones of each camera (by brightness, range and distance to the camera), the rest keep their shadow maps. Default off."
            },
            "ao": {
              "type": "boolean",
              "default": false,
              "description": "Ambient occlusion traced with rays instead of the screen-space one, on the main camera of a device that traces: raysPerPixel rays in a hemisphere around each surface, denoised, applied as the screen-space occlusion is (the radius and intensity are the camera's PostProcess ssaoRadius and ssaoIntensity, else their defaults). Default false."
            },
            "reflections": {
              "type": "boolean",
              "default": false,
              "description": "Reflections traced with rays: a surface smoother than roughness 0.25 gets one mirror ray per pixel; one from 0.25 to 0.65 gets raysPerPixel rays spread by its roughness, denoised, fading into the screen-space reflections and the probes towards 0.65; a rougher surface, a ray that leaves the scene and a device that cannot trace keep the screen-space reflections and the probes. Default false."
            },
            "translucency": {
              "type": "boolean",
              "default": false,
              "description": "Refraction through glass and liquids traced with rays instead of the screen-space refraction: a ray bent by the material's ior at every interface of the closed mesh (up to six), tinted by its attenuation colour and distance. Glass casts a solid shadow; coloured shadows are not made. Default false."
            },
            "gi": {
              "type": "string",
              "enum": ["off", "probes", "perPixel"],
              "default": "off",
              "description": "Global illumination: off = the engine's own (light probes and the ambient); probes = the probes of the RealtimeGI grids updated with rays instead of raster captures (raysPerProbe and rtProbesPerFrame of the component set the cost); perPixel = one bounce traced for every pixel of the main camera, denoised, in place of the probes' and the ambient light of the lit meshes (the most expensive: raysPerPixel rays per pixel). Default off."
            },
            "raysPerPixel": {
              "type": "integer",
              "minimum": 1,
              "maximum": 16,
              "default": 1,
              "description": "Rays of each effect per pixel and frame; the denoiser makes up the rest. A value outside 1 to 16 is clamped. Default 1."
            },
            "maxInstances": {
              "type": "integer",
              "minimum": 1,
              "maximum": 1048576,
              "default": 65536,
              "description": "The most instances the top-level acceleration structure holds; the nearest to the camera come first. A value outside 1 to 1048576 is clamped. Default 65536."
            }
          }
        },
)JSON"
    R"JSON(        "pathTracer": {
          "type": "object",
          "description": "The path traced reference mode (M79, docs/RAY_TRACING.md, \"The path tracer\"): instead of the raster's lit colour the main camera shows a progressive unidirectional path trace of the same scene (the same materials, the sun and up to 8 point or spot lights sampled directly, the sky as the environment), accumulated over frames while nothing changes; the post stack and the tonemap apply. For comparing the raster against a converged picture, not for play. It needs a device that traces rays (D3D12, Vulkan or Metal) and builds the scene's acceleration structures by itself. Off by default and free when off. The command render.path_tracer reads and changes it at run time; render.pathtrace writes a converged image to a file.",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": false,
              "description": "true shows the path traced picture in place of the lit one. false (default) traces nothing and costs nothing."
            },
            "maxBounces": {
              "type": "integer",
              "minimum": 1,
              "maximum": 32,
              "default": 4,
              "description": "The longest path in segments: 1 = the direct light only, 2 adds one bounce, and so on; Russian roulette ends a dark path sooner. Default 4."
            },
            "samplesPerFrame": {
              "type": "integer",
              "minimum": 1,
              "maximum": 64,
              "default": 1,
              "description": "Paths per pixel that each frame adds to the accumulation. More converges faster per frame and costs more per frame. Default 1."
            },
            "maxSamples": {
              "type": "integer",
              "minimum": 0,
              "maximum": 16777216,
              "default": 0,
              "description": "The accumulation stops, and the picture is kept without tracing more, after this many samples per pixel. 0 (default) = never."
            },
            "fireflyClamp": {
              "type": "number",
              "minimum": 0,
              "default": 0,
              "description": "The largest luminance one path may carry (0 = no clamp): trades a little energy for fewer white dots. 5 to 20 is usual. Default 0."
            },
            "lights": {
              "type": "boolean",
              "default": true,
              "description": "Direct light from the point and spot lights (the 8 strongest of the frame; an area light counts as a point). The sun is always sampled. Default true."
            },
            "seed": {
              "type": "integer",
              "minimum": 0,
              "maximum": 1073741824,
              "default": 0,
              "description": "Changes the noise pattern; the same seed on the same device gives the same picture. Never the wall clock. Default 0."
            }
          }
        },
)JSON"
    R"JSON(        "dynamicResolution": {
          "type": "object",
          "description": "Dynamic resolution (M76, docs/UPSCALING.md, \"Dynamic resolution\"): the render scale follows the frame time so the game holds a target. Off by default (the picture is the fixed render scale). It multiplies into window.renderScale and the upscaler's quality, in steps, at most twice a second. Scripts change it with window.dynamicResolution and the command render.dynamic_resolution.",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": false,
              "description": "true turns the controller on. false (default) draws at the fixed render scale."
            },
            "targetMs": {
              "type": ["number", "null"],
              "minimum": 0,
              "maximum": 100,
              "default": 0,
              "description": "The frame time to hold, in ms: 33.3 for 30 fps, 16.7 for 60 fps. 0 or null (default) follows the refresh rate of the display the window is on (the OS's, else one estimated from the frame times, else 60 Hz: docs/UPSCALING.md, \"The display's refresh rate\"). 0, or 4 to 100."
            },
            "minScale": {
              "type": "number",
              "minimum": 0.25,
              "maximum": 1,
              "default": 0.5,
              "description": "The smallest share of the render size's width and height the controller uses, 0.25 to 1. Default 0.5 (a quarter of the pixels)."
            },
            "maxScale": {
              "type": "number",
              "minimum": 0.25,
              "maximum": 1,
              "default": 1,
              "description": "The largest share, where it starts, minScale to 1. Default 1."
            }
          }
        },
        "backend": {
          "type": "string",
          "enum": ["auto", "d3d11", "d3d12", "vulkan", "metal", "gl", "gles3", "webgl2"],
          "default": "auto",
          "description": "The GPU backend the game draws with (M77-P9a, docs/RENDERING.md, \"Choosing the GPU backend\"). \"auto\" (the default) is the backend this build of the engine uses today (OpenGL on Linux, Direct3D 11 on Windows, Metal on Apple, OpenGL ES 3 on Android, WebGL 2 on the web); later M77 work lets it pick the best one. On Linux and Android the exported game runs the Vulkan variant of the player first (factoria_player_vulkan, export.linux.vulkanPlayer / export.android.vulkanPlayer): auto there means Vulkan, and where Vulkan cannot start that player hands over to the GL one, a second process whose startup report names gpu.fallbackFrom and gpu.fallbackReason. A name the platform or this binary does not have (metal on Windows, d3d12 off Windows, vulkan in a build without it) starts with a warning and uses auto. d3d12 and vulkan draw into the game window with a swapchain of their own (Windows; Linux and Android, where the window's OpenGL surface waits off screen; vulkan on macOS through MoltenVK in a build that has it) and headless runs draw offscreen on them; when the one asked for cannot start, the engine warns once with its first error and draws with auto in the same process (gpu.backendFallback), after the Vulkan player of Linux and Android has tried to hand over to the GL player. The player's user setting (the graphics.backend command, stored in the user folder) overrides this key, the FA_GPU_BACKEND environment variable (same names) overrides both, and EngineConfig.gpuBackend overrides everything."
        },
        "asyncCompute": {
          "type": "boolean",
          "default": true,
          "description": "On Direct3D 12 and Vulkan with a separate compute queue, run the depth-pyramid (HiZ) reduce of GPU occlusion culling on the compute queue next to the graphics work (M77-P10d, docs/RENDERING.md, \"Async compute and multi-thread recording\"). The image is the same either way; false keeps it on the graphics queue (to compare timings or to rule out a driver problem). Other backends ignore it. The startup report says whether it is in use."
        },
        "multiThreadRecording": {
          "type": "boolean",
          "default": true,
          "description": "On Direct3D 12 and Vulkan, record the shadow cascades and spot-light shadows on job threads, up to four command lists submitted in a fixed order (M77-P10d, docs/RENDERING.md, \"Async compute and multi-thread recording\"). The image is the same either way; false records everything on the render thread. Other backends ignore it. The startup report says whether it is in use."
        },
        "graphicsPreset": {
          "type": "string",
          "enum": ["low", "medium", "high", "ultra", "custom"],
          "default": "custom",
          "description": "The graphics preset a run starts with (M76, docs/UPSCALING.md, \"Graphics presets\"): a quality layer the renderer applies on top of what the scene asks for (shadow cascades and sizes, ambient occlusion, reflections, depth of field, motion blur, volumetric fog, level-of-detail distances, foliage and terrain detail, 2D lighting, global illumination) and the upscaler. low, medium, high and ultra lower the settings of the scene, never raise them; custom (the default) is no layer: the game looks as its author made it. It writes nothing into the scenes. While a preset other than custom is on, render.upscaler is what custom brings back, not what is drawn. Scripts and the commands graphics.preset and graphics.detect change it at run time; the engine does not save the player's choice."
        }
      }
    },
    "input": {
      "type": "object",
      "description": "Input configuration.",
      "properties": {
        "actions": {
          "type": "object",
          "description": "Named input actions. Each maps to a list of bindings: key names (\"Space\", \"A\", \"Left\"), \"MouseLeft\"/\"MouseRight\"/\"MouseMiddle\", \"Touch\", gamepad buttons (\"GamepadA\", \"GamepadStart\", \"GamepadDpadLeft\"...) and gamepad half axes (\"GamepadLeftStickLeft\", \"GamepadRightStickUp\", \"GamepadRightTrigger\"...). Gamepad bindings match any connected pad. A key, mouse button or \"Touch\" takes modifiers joined by \"+\": \"Ctrl+Z\", \"Shift+MouseLeft\", \"Ctrl+Shift+S\" (Ctrl, Shift, Alt and Super each name either side's key; \"Shift\" alone is a binding too). When one action binds Z and another Ctrl+Z, Z does not fire while Ctrl is held.",
          "additionalProperties": {
            "type": "array",
            "items": {
              "type": "string"
            },
            "description": "Bindings that trigger this action."
          }
        },
        "schemes": {
          "type": "object",
          "description": "Key schemes for local multiplayer: named sets of keys a player can be given with input.player(i).use({keys: name}). The built-in ones are \"all\", \"left\" (WASD side of the keyboard) and \"right\" (arrows side). Each scheme is {\"extends\": a built-in scheme, \"keys\": [key names], \"actions\": {action: [key names]}} or just an array of key names; its keys are the extended scheme's plus \"keys\" plus the keys of \"actions\", and \"actions\" gives the keys of those actions for players of the scheme (the others use the key bindings of input.actions that belong to the scheme).",
          "additionalProperties": {
            "oneOf": [
              {"type": "array", "items": {"type": "string"}},
              {
                "type": "object",
                "properties": {
                  "extends": {"type": "string", "enum": ["all", "left", "right"]},
                  "keys": {"type": "array", "items": {"type": "string"}},
                  "actions": {"type": "object", "additionalProperties": {"type": "array", "items": {"type": "string"}}}
                },
                "additionalProperties": false
              }
            ]
          }
        },
        "deadzone": {
          "type": "number",
          "minimum": 0,
          "exclusiveMaximum": 1,
          "description": "Gamepad deadzone for sticks (radial) and triggers (default 0.2): pushes below it count as 0 and the rest is rescaled to 0..1. Raise it for worn sticks that drift, lower it for precise ones."
        }
      }
    },
    "platforms": {
      "type": "array",
      "description": "Platforms this game targets.",
      "items": {
        "enum": [
          "windows",
          "macos",
          "linux",
          "ios",
          "android",
          "web"
        ]
      }
    },
    "icon": {
      "type": "string",
      "description": "Game icon: the project-relative path of a square PNG or JPG image, e.g. \"assets/icon.png\" (forward slashes, inside the project folder). 1024x1024 recommended; it should be at least 512x512 (smaller or non-square images give a warning, a non-square one is centered on a transparent square). Every export generates what its platform needs from this one image: the .icns of a macOS app, the exe icon on Windows, the launcher icons of Android, the App Store icon of iOS, the PNG of a Linux build. Each platform can use another image through export.<platform>.icon. No icon at all means the platform's default icon plus a warning on export. On Windows and Linux the same image is also the icon of the game window at run time. Edited by the editor's Platform settings window."
    },
    "plugins": {
      "type": "object",
      "description": "Native plugins of the game: libraries in C, C++ or any language with a C ABI that add commands and script functions (plugins.<name>.<function>(...)) through fa_plugin.h, e.g. store and platform SDKs. Each key is a plugin name (lower-case letters, digits and underscores; its commands are <name>.<verb>). `factoria run`, the editor and tests load the build for this computer from the plugin's folder; `factoria export` copies or links the build for the target platform into the game. `factoria validate` checks that every build exists. Created with project.new_plugin. See docs/EXTENDING.md, \"Native plugins\".",
      "propertyNames": {
        "pattern": "^[a-z][a-z0-9_]{0,63}$"
      },
      "additionalProperties": {
        "type": "object",
        "required": [
          "path"
        ],
        "additionalProperties": false,
        "properties": {
          "path": {
            "type": "string",
            "minLength": 1,
            "description": "The plugin's folder: project-relative, absolute, or with ${VARIABLE} parts replaced by environment variables, so that a private SDK can live outside the game's repository (\"${STEAMWORKS_PLUGIN}\"). It holds one build per platform: windows/<name>.dll, macos/lib<name>.dylib, linux/lib<name>.so (each next to the libraries it needs), android/ (a Gradle library module with build.gradle, or .aar files) and ios/iphoneos/lib<name>.a plus ios/iphonesimulator/lib<name>.a."
          },
          "platforms": {
            "type": "array",
            "minItems": 1,
            "description": "The platforms the plugin is built for (default: the game's `platforms`, or all five). On other platforms the game runs without it and plugins.<name> is undefined.",
            "items": {
              "enum": [
                "windows",
                "macos",
                "linux",
                "ios",
                "android",
                "web"
              ]
            }
          },
          "optional": {
            "type": "boolean",
            "description": "true: the game runs without this plugin, so a missing build for this computer is a warning in `factoria validate`, not an error. Without the build, `plugins.<name>` still exists but throws \"the native plugin is not loaded\" when a function is used (wrap calls in try/catch, or reach the plugin only through what it provides, e.g. the `platform` API falls back to the development fake store), and the runtime only logs a warning. `factoria export` still fails without the build for the target platform, so a store build cannot ship without it by accident. Default false."
          }
        }
      }
    },
)JSON"
    R"JSON(    "world": {
      "type": "object",
      "description": "Big-world settings (docs/BIG_WORLDS.md).",
      "properties": {
        "floatingOrigin": {
          "type": "object",
          "description": "Floating origin (M75.4): when the anchor is farther than `threshold` metres from the world origin, the engine moves the origin to the anchor (rounded to a multiple of `step`) and shifts every Transform the other way, so nothing moves on screen and float precision holds at 100 km and more.",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": false,
              "description": "true turns the floating origin on. Default false: the world origin never moves."
            },
            "threshold": {
              "type": "number",
              "minimum": 16,
              "maximum": 10000000,
              "default": 2048,
              "description": "Metres between the anchor and the origin beyond which the origin moves. Default 2048."
            },
            "step": {
              "type": "integer",
              "enum": [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576],
              "default": 256,
              "description": "Metres: the origin only moves in multiples of this. An integer power of two (1, 2, 4 ... 1048576), so a move is exact in a float at any distance, and at most `threshold`. Default 256, or the largest power of two at most `threshold` when `threshold` is below 256."
            },
            "anchor": {
              "type": "string",
              "pattern": "^(camera|entity:.+)$",
              "default": "camera",
              "description": "What is measured from the origin: \"camera\" (the active 3D camera) or \"entity:<id>\" (the entity with that id, e.g. \"entity:player\"). Default \"camera\"."
            }
          }
        }
      }
    },
    "storage": {
      "type": "object",
      "description": "Save storage settings (docs/scripting/SCRIPTING_UI_SCENES.md, \"Encrypted saves\").",
      "properties": {
        "encryptionSecret": {
          "type": "string",
          "minLength": 16,
          "description": "The random secret that storage.set(key, value, {encrypt: true}) derives its keys from (HKDF-SHA256, salted with \"id\", one key per storage key). Create it ONCE with the command project.create_storage_secret (`factoria call project.create_storage_secret`), never by hand and never in the running game. Keep it for the life of the game: saves written with another secret cannot be opened. It is packed into the exported game, so it makes saves tamper-evident, not secret from a determined player. project.info and `game.project` show it as \"(hidden)\"."
        }
      }
    },
    "runtime": {
      "type": "object",
      "description": "How the engine runs the game on the player's machine. These settings never change what the game computes: a game gives the same result with any of them (docs/PERFORMANCE.md, \"Job threads\").",
      "properties": {
        "jobThreads": {
          "description": "Worker threads of the job system (docs/design/ARCHITECTURE_THREADS.md, \"Jobs and threads\"): \"auto\" (the default: hardware threads - 1, at most 8 on desktop and 4 on phones; 0 in a web build, which has no threads), a number from 0 to 32 written as a number, not in quotes (0: jobs run on the main thread when it waits for them or at the end of the frame), or \"inline\" (debugging: every job runs on the main thread when it is submitted, in order). The FA_JOB_THREADS environment variable overrides it.",
          "oneOf": [
            {
              "type": "string",
              "enum": [
                "auto",
                "inline"
              ]
            },
            {
              "type": "integer",
              "minimum": 0,
              "maximum": 32
            }
          ]
        },
        "loadBudgetMs": {
          "type": "number",
          "exclusiveMinimum": 0,
          "maximum": 100,
          "default": 4,
          "description": "Background loading (scene.preload, assets.preload, scene.load with {async: true}; docs/PERFORMANCE.md, \"Background loading\"): how many milliseconds of a frame the main thread may spend taking finished files and uploading them to the GPU, in a game with a window. Default 4. Tests, headless runs, the editor and replays use a fixed number of files per frame instead, so they do not depend on the machine."
        },
        "uploadBudgetMB": {
          "type": "number",
          "exclusiveMinimum": 0,
          "maximum": 1024,
          "default": 16,
          "description": "Background loading: how many megabytes of textures and meshes a frame may upload to the GPU, in a game with a window (the frame stops taking files once it passed this; at least one file per frame). Default 16."
        },
        "scriptMemoryMB": {
          "description": "Heap cap of the scripts in megabytes (docs/PERFORMANCE.md, \"Script budgets\"): a script that needs more fails with 'out of memory', and the error names this setting and its value. A number for every platform, or an object with one number per platform: {\"default\": 768, \"android\": 384, \"web\": 256} (platforms: windows, macos, linux, ios, android, web; \"default\" covers the others). Default 768 on every platform. From 16 to 2048.",
          "oneOf": [
            { "type": "number", "minimum": 16, "maximum": 2048 },
            {
              "type": "object",
              "propertyNames": { "enum": ["default", "windows", "macos", "linux", "ios", "android", "web"] },
              "additionalProperties": { "type": "number", "minimum": 16, "maximum": 2048 }
            }
          ],
          "default": 768
        },
        "scriptFrameBudgetMs": {
          "description": "Script time budget of one frame in milliseconds (docs/PERFORMANCE.md, \"Script budgets\"): when the callbacks, timers, event handlers and promise jobs of a frame add up to more, the engine logs a warning in category `script.budget` (the slowest callbacks, this setting) at most once every 5 seconds of game time, marks the frame in the profiler (`overBudget` of the profile) and play.report lists the warning. The frames that load a scene are not counted. 0 turns it off. A number for every platform, or an object with one number per platform like scriptMemoryMB. Default 8. It never stops a script (the watchdog does that, after 2 seconds) and never changes what the game computes.",
          "oneOf": [
            { "type": "number", "minimum": 0, "maximum": 1000 },
            {
              "type": "object",
              "propertyNames": { "enum": ["default", "windows", "macos", "linux", "ios", "android", "web"] },
              "additionalProperties": { "type": "number", "minimum": 0, "maximum": 1000 }
            }
          ],
          "default": 8
        }
      }
    },
)JSON"
    R"JSON(    "audio": {
      "type": "object",
      "description": "The mixer (docs/SCRIPTING.md, \"Audio buses\"). `buses` declares the project's own buses; `snapshots` is the catalog audio.snapshot(name, { fade }) and the audio.snapshot command read. `factoria validate` reports every problem with how to fix it.",
      "properties": {
        "buses": {
          "type": "object",
          "description": "The project's own mixer buses, by name, each with a parent. Beside the built-in \"sfx\", \"music\", \"ui\" and \"master\". A bus is mixed with its effects and volume and then summed into its parent. Example: {\"ambience\": {\"parent\": \"sfx\"}}. Names are lowercase letters, digits, '_' or '-'.",
          "additionalProperties": {
            "type": "object",
            "description": "One bus.",
            "properties": {
              "parent": {
                "type": "string",
                "description": "The bus this one is summed into: \"sfx\", \"music\", \"ui\", \"master\" (default) or another bus of this list."
              }
            }
          }
        },
        "snapshots": {
          "type": "object",
          "description": "Named sets of bus settings. Applying one moves every bus to the snapshot's state: a bus it does not list goes back to neutral (volume scale 1, no low-pass, no reverb, no ducking), so a snapshot is the whole picture and `\"normal\": {}` is the way back. The volumes the player set (audio.setVolume) are not touched. Example: {\"underwater\": {\"fade\": 0.8, \"buses\": {\"sfx\": {\"lowpass\": 600, \"reverb\": 0.3}, \"music\": {\"volume\": 0.5, \"lowpass\": 400}}}, \"normal\": {}}.",
          "additionalProperties": {
            "type": "object",
            "description": "One snapshot.",
            "properties": {
              "fade": {
                "type": "number",
                "minimum": 0,
                "maximum": 60,
                "description": "Seconds audio.snapshot takes when the call gives no time (default 0.5)."
              },
              "buses": {
                "type": "object",
                "description": "Settings by bus name: \"sfx\", \"music\", \"ui\", \"master\" or a bus of audio.buses.",
                "additionalProperties": {
                  "type": "object",
                  "description": "What the snapshot sets on one bus.",
                  "properties": {
                    "volume": {
                      "type": "number",
                      "minimum": 0,
                      "maximum": 4,
                      "description": "A scale on the bus's own volume (the one the player's options set): 1 = unchanged (default), 0.5 = half, 0 = silent."
                    },
                    "lowpass": {
                      "type": ["number", "null"],
                      "minimum": 0,
                      "maximum": 20000,
                      "description": "Low-pass cutoff in Hz, 20..20000 (a 12 dB per octave filter: 600 is a muffled, underwater sound). 0 or null = no filter (default)."
                    },
                    "reverb": {
                      "type": "number",
                      "minimum": 0,
                      "maximum": 1,
                      "description": "Reverb wet mix: 0 = none (default), 0.3 = a touch of room, 1 = all wet."
                    },
                    "duck": {
                      "type": ["object", "null"],
                      "description": "Lowers this bus while another one plays (not for \"master\"). Example: {\"by\": \"sfx\", \"amount\": 0.5, \"attack\": 0.05, \"release\": 0.5}. Ducking switches at once when the snapshot is applied; it does not fade.",
                      "properties": {
                        "by": {
                          "enum": ["sfx", "music", "ui"],
                          "description": "The bus that triggers it (another bus than this one)."
                        },
                        "amount": {
                          "type": "number",
                          "minimum": 0,
                          "maximum": 1,
                          "description": "The fraction of the volume removed while `by` plays: 0.5 (default) is half as loud, 1 is silent, 0 is no ducking."
                        },
                        "attack": {
                          "type": "number",
                          "minimum": 0,
                          "maximum": 30,
                          "description": "Attack time constant in seconds: the bus covers 63% of the way down to the ducked level in this time, about 95% in three times it (default 0.05)."
                        },
                        "release": {
                          "type": "number",
                          "minimum": 0,
                          "maximum": 30,
                          "description": "Release time constant in seconds: 63% of the way back up in this time once `by` has stopped, about 95% in three times it (default 0.5)."
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
)JSON"
    R"JSON(    "text": {
      "type": "object",
      "description": "Rich text (docs/TEXT.md, \"Rich text\"): what a Text with `markup: true` (and the label of a Button, Toggle, Slider or TouchButton with it) can name, and the bold face of each font. `[c:good]` reads `colors.good`, `[icon:fish]` reads `icons.fish`, `[b]` and `bold: true` use `fonts.<font>.bold`. `factoria validate` reports every problem with how to fix it.",
      "properties": {
        "colors": {
          "type": "object",
          "description": "Named colours for `[c:name]`. A tag may also use a built-in colour name (\"red\") or #rgb / #rrggbb / #rrggbbaa without being declared. A run colour replaces the colour of the Text (its alpha still multiplies the Text's alpha). Example: {\"good\": \"#80dc80\", \"bad\": [1, 0.48, 0.42, 1]}. Names are letters, digits, '_', '-' and '.'.",
          "additionalProperties": {
            "description": "A colour: \"#rrggbb\", \"#rrggbbaa\", a colour name, or [r, g, b, a] with components 0 to 1."
          }
        },
        "icons": {
          "type": "object",
          "description": "Pictures for `[icon:name]`: a rectangle of a project texture, drawn inline as tall as the line of text. Example: {\"fish\": {\"texture\": \"assets/atlas.png\", \"region\": [0, 0, 32, 32]}}.",
          "additionalProperties": {
            "type": "object",
            "description": "One icon.",
            "properties": {
              "texture": {
                "type": "string",
                "description": "Project-relative path of the image the icon is a part of."
              },
              "region": {
                "type": "array",
                "description": "[x, y, width, height] in pixels of the texture, from its top-left corner (width and height at least 1). The icon is drawn as tall as the line and as wide as the region's proportions say.",
                "items": { "type": "number" },
                "minItems": 4,
                "maxItems": 4
              }
            }
          }
        },
        "fonts": {
          "type": "object",
          "description": "The bold and italic faces of each font, keyed by the font as a Text names it: a project path such as \"assets/fonts/Body-Regular.ttf\", a built-in font (\"builtin:pixel\", \"builtin:serif\", ...) or \"\" (DejaVu Sans). `[b]` and `Text.bold` use the bold face for the glyphs it has; a font with no entry (or a glyph its bold face lacks) is emboldened by the engine, which looks heavier but never as good as a drawn face. `[i]` uses the italic face; a font with none stays upright. builtin:serif, builtin:hand and builtin:display bring faces of their own, so they need no entry. `factoria validate` suggests adding one for a font that markup or bold uses.",
          "additionalProperties": {
            "type": "object",
            "description": "One font.",
            "properties": {
              "bold": {
                "type": "string",
                "description": "Project-relative path of the bold font file (.ttf or .otf)."
              },
              "italic": {
                "type": "string",
                "description": "Project-relative path of the italic font file (.ttf or .otf), drawn for `[i]` text."
              }
            }
          }
        }
      }
    },
)JSON"
    R"JSON(    "localization": {
      "type": "object",
      "description": "Languages of the game (docs/LOCALIZATION.md). Each language has a string table locales/<language>.json; Text.key and the widgets' key fields, `i18n.t(key, args)` in scripts and the i18n.* commands read them. Without this section localization is off and the game behaves as it always did. Headless runs (tests, the MCP server, `factoria call`) and the editor always use defaultLanguage; a game in its own window or an exported game starts in the language of the player's system that best matches `languages`, unless the environment variable FA_LANGUAGE names one. `factoria validate` reports every problem with how to fix it.",
      "properties": {
        "defaultLanguage": {
          "type": "string",
          "pattern": "^[a-z]{2,3}(-[A-Z][a-z]{3})?(-([A-Z]{2}|[0-9]{3}))?$",
          "description": "The language the strings are written in first and the last fallback of every lookup; also the language of headless runs and the editor. Must be one of `languages` (default: the first of them). A BCP 47 tag: language lower case, script capitalized, region upper case (\"en\", \"pt-BR\", \"zh-Hans\")."
        },
        "languages": {
          "type": "array",
          "minItems": 1,
          "uniqueItems": true,
          "description": "The languages the game ships, in the order a language menu lists them. Each is a BCP 47 tag and has a string table locales/<tag>.json (\"en\", \"es\", \"pt-BR\", \"zh-Hans\", \"ja\", \"ar\"). With only defaultLanguage given, the game has that one language.",
          "items": {
            "type": "string",
            "pattern": "^[a-z]{2,3}(-[A-Z][a-z]{3})?(-([A-Z]{2}|[0-9]{3}))?$"
          }
        },
        "fallbackFonts": {
          "type": "array",
          "description": "Project-relative paths of .ttf or .otf fonts that fill the characters the main font of a Text lacks, in every language, after the font of the language itself (languageFonts). Typically Noto fonts for the scripts of `languages`: [\"assets/fonts/NotoSansArabic-Regular.ttf\", \"assets/fonts/NotoSansJP-Regular.ttf\"]. Stored here; the text renderer uses them (see the font documentation).",
          "items": {
            "type": "string",
            "minLength": 1
          }
        },
        "languageFonts": {
          "type": "object",
          "description": "Fonts for one language, tried before fallbackFonts when the game runs in it (or in a region of it: \"zh-Hans\" also serves \"zh-Hans-CN\"). Keys are tags of `languages`: {\"zh-Hans\": [\"assets/fonts/NotoSansSC-Regular.ttf\"], \"ja\": [\"assets/fonts/NotoSansJP-Regular.ttf\"]}.",
          "propertyNames": {
            "pattern": "^[a-z]{2,3}(-[A-Z][a-z]{3})?(-([A-Z]{2}|[0-9]{3}))?$"
          },
          "additionalProperties": {
            "type": "array",
            "items": {
              "type": "string",
              "minLength": 1
            }
          }
        }
      }
    },
)JSON"
    R"JSON(    "network": {
      "type": "object",
      "description": "The network use of the game: the hosts `http.fetch` may call (docs/NETWORKING.md). A game without this section has no network: every http.fetch throws and says what to declare. Declaring hosts also adds the INTERNET permission to an Android export and tells you what to write in the privacy policy (docs/LEGAL.md). Only https:// addresses are sent (plain http:// only to localhost, for development), and only to a declared host. `factoria validate` reports every problem with how to fix it.",
      "properties": {
        "hosts": {
          "type": "array",
          "description": "The host names the game calls, as in the URL: \"api.example.com\" (that host only), \"*.cdn.example.com\" (every subdomain of cdn.example.com, not cdn.example.com itself), \"localhost\" (development; also the only way to call http:// there). No scheme, port or path.",
          "items": {
            "type": "string",
            "minLength": 1
          }
        },
        "purpose": {
          "type": "string",
          "description": "What the game sends and why, in one or two sentences for the privacy policy, e.g. \"Sends the player's name and score to the leaderboard server, and reads the daily challenge.\" `factoria validate` warns when hosts are declared without it."
        }
      }
    },
)JSON"
    R"JSON(    "analytics": {
      "type": "object",
      "description": "Usage analytics of the game (docs/ANALYTICS.md): analytics.event(name, props) queues small events and sends them in batches to `endpoint` through http.fetch, only after the player consented (analytics.setConsent). Its host must also be in \"network\".\"hosts\". Nothing is sent without this section. Say in your privacy policy and the store privacy forms what is sent (docs/LEGAL.md). `factoria validate` reports every problem with how to fix it.",
      "properties": {
        "endpoint": { "type": "string", "description": "The https:// address that receives each batch as a POST with a JSON body { game, version, sentOn, events: [{ name, props, t }] }. Its host must be listed in network.hosts." },
        "batch": { "type": "integer", "minimum": 1, "maximum": 100, "description": "Events that make a batch go out at once. Default 20." },
        "flushSeconds": { "type": "number", "minimum": 1, "maximum": 3600, "description": "The longest an event waits in the queue before it is sent (engine seconds). Default 30." },
        "timeoutSeconds": { "type": "number", "minimum": 0.5, "maximum": 120, "description": "Seconds one request may take. Default 10." },
        "consentFromAds": { "type": "boolean", "description": "For a game with ads: until the player answers the analytics question themselves, analytics counts as granted when the ads consent is (GDPR granted and tracking authorized or not required). The player's own answer always wins. Default false." }
      }
    },
    "remoteConfig": {
      "type": "object",
      "description": "Remote values for the game (docs/ANALYTICS.md): remoteConfig.get(key, default) reads a JSON object fetched once at start from `url` through http.fetch, cached in storage for offline runs. The host must also be in \"network\".\"hosts\". Nothing is fetched without this section.",
      "properties": {
        "url": { "type": "string", "description": "The https:// address of a JSON object (at most 64 KB and 500 keys). Its host must be listed in network.hosts." },
        "timeoutSeconds": { "type": "number", "minimum": 0.5, "maximum": 30, "description": "Seconds the fetch may take. Default 5." }
      }
    },
)JSON"
    R"JSON(    "platform": {
      "type": "object",
      "description": "Store and platform services of the game: achievements, stats, leaderboards, cloud saves and in-app purchases behind one scripting API (`platform` from \"factoria\", docs/PLATFORM.md). This section declares what the game has, so that ids are checked before a request leaves the game and each store gets its own id for the same entry (\"ids\"). Every key is optional. Which store answers is chosen by the native plugins the game declares (\"plugins\") and by \"backend\"; development runs, tests and the MCP server use a deterministic fake store. `factoria validate` reports every problem with how to fix it.",
      "properties": {
        "backend": {
          "description": "Which native plugin provides the store backend: \"auto\" (the default: the only plugin that registers one), a plugin name (\"steam\"), or an object per platform ({\"windows\": \"steam\", \"macos\": \"steam\", \"linux\": \"steam\", \"ios\": \"apple\"}). Needed only when several plugins offer a backend. Without any, development runs use the fake backend and exported games get no platform services.",
          "oneOf": [
            {
              "type": "string",
              "pattern": "^(auto|[a-z][a-z0-9_]{0,63})$"
            },
            {
              "type": "object",
              "propertyNames": {
                "enum": [
                  "windows",
                  "macos",
                  "linux",
                  "ios",
                  "android",
                  "web"
                ]
              },
              "additionalProperties": {
                "type": "string",
                "pattern": "^(auto|[a-z][a-z0-9_]{0,63})$"
              }
            }
          ]
        },
        "achievements": {
          "type": "array",
          "description": "The achievements of the game: platform.achievements.unlock(\"<id>\").",
          "items": {
            "type": "object",
            "required": [
              "id"
            ],
            "anyOf": [
              {
                "required": [
                  "name"
                ]
              },
              {
                "required": [
                  "nameKey"
                ]
              }
            ],
            "properties": {
              "id": {
                "type": "string",
                "pattern": "^[A-Za-z0-9_.-]{1,64}$",
                "description": "The id scripts use (platform.<service>.<function>(\"<id>\")): 1-64 letters, digits, '_', '.' or '-', unique within its section."
              },
              "name": {
                "type": "string",
                "minLength": 1,
                "description": "The achievement's title."
              },
              "nameKey": {
                "type": "string",
                "minLength": 1,
                "description": "A key of locales/<language>.json instead of \"name\": the title in the current language (docs/PLATFORM.md, \"Translated texts\")."
              },
              "description": {
                "type": "string",
                "description": "What the player did to earn it."
              },
              "descriptionKey": {
                "type": "string",
                "minLength": 1,
                "description": "A key of locales/<language>.json instead of \"description\"."
              },
              "hidden": {
                "type": "boolean",
                "default": false,
                "description": "Hidden until unlocked (the stores' secret achievements)."
              },
              "ids": {
                "type": "object",
                "description": "The id each store uses for this entry, keyed by backend name: {\"steam\": \"ACH_WIN_ONE_GAME\", \"apple\": \"com.studio.game.first_win\"}. Without an entry for a backend, the id is used as it is.",
                "propertyNames": {
                  "pattern": "^[a-z][a-z0-9_]{0,63}$"
                },
                "additionalProperties": {
                  "type": "string",
                  "minLength": 1
                }
              }
            }
          }
        },
        "stats": {
          "type": "array",
          "description": "Numbers the store keeps for the player: platform.stats.get(\"<id>\"), set, add.",
          "items": {
            "type": "object",
            "required": [
              "id"
            ],
            "properties": {
              "id": {
                "type": "string",
                "pattern": "^[A-Za-z0-9_.-]{1,64}$",
                "description": "The id scripts use (platform.<service>.<function>(\"<id>\")): 1-64 letters, digits, '_', '.' or '-', unique within its section."
              },
              "type": {
                "enum": [
                  "int",
                  "float"
                ],
                "default": "int",
                "description": "\"int\" keeps whole numbers, \"float\" fractions."
              },
              "ids": {
                "type": "object",
                "description": "The id each store uses for this entry, keyed by backend name: {\"steam\": \"ACH_WIN_ONE_GAME\", \"apple\": \"com.studio.game.first_win\"}. Without an entry for a backend, the id is used as it is.",
                "propertyNames": {
                  "pattern": "^[a-z][a-z0-9_]{0,63}$"
                },
                "additionalProperties": {
                  "type": "string",
                  "minLength": 1
                }
              }
            }
          }
        },
        "leaderboards": {
          "type": "array",
          "description": "Leaderboards: platform.leaderboards.submit(\"<id>\", score) and entries(\"<id>\").",
          "items": {
            "type": "object",
            "required": [
              "id"
            ],
            "anyOf": [
              {
                "required": [
                  "name"
                ]
              },
              {
                "required": [
                  "nameKey"
                ]
              }
            ],
            "properties": {
              "id": {
                "type": "string",
                "pattern": "^[A-Za-z0-9_.-]{1,64}$",
                "description": "The id scripts use (platform.<service>.<function>(\"<id>\")): 1-64 letters, digits, '_', '.' or '-', unique within its section."
              },
              "name": {
                "type": "string",
                "minLength": 1,
                "description": "The leaderboard's title."
              },
              "nameKey": {
                "type": "string",
                "minLength": 1,
                "description": "A key of locales/<language>.json instead of \"name\": the title in the current language (docs/PLATFORM.md, \"Translated texts\")."
              },
              "order": {
                "enum": [
                  "descending",
                  "ascending"
                ],
                "default": "descending",
                "description": "\"descending\": a higher score is better (points); \"ascending\": a lower one is (times)."
              },
              "period": {
                "enum": [
                  "allTime",
                  "daily",
                  "weekly"
                ],
                "default": "allTime",
                "description": "How often the board starts over: \"allTime\" (never), \"daily\" (a new board every calendar day of game.today()) or \"weekly\" (every Monday). Scores are kept per period; the fake backend implements it, real stores' recurring boards come with M12 (docs/PLATFORM.md, \"Leaderboard periods\")."
              },
              "ids": {
                "type": "object",
                "description": "The id each store uses for this entry, keyed by backend name: {\"steam\": \"ACH_WIN_ONE_GAME\", \"apple\": \"com.studio.game.first_win\"}. Without an entry for a backend, the id is used as it is.",
                "propertyNames": {
                  "pattern": "^[a-z][a-z0-9_]{0,63}$"
                },
                "additionalProperties": {
                  "type": "string",
                  "minLength": 1
                }
              }
            }
          }
        },
        "products": {
          "type": "array",
          "description": "What the game sells: platform.purchases.buy(\"<id>\").",
          "items": {
            "type": "object",
            "required": [
              "id",
              "type"
            ],
            "anyOf": [
              {
                "required": [
                  "title"
                ]
              },
              {
                "required": [
                  "titleKey"
                ]
              }
            ],
            "properties": {
              "id": {
                "type": "string",
                "pattern": "^[A-Za-z0-9_.-]{1,64}$",
                "description": "The id scripts use (platform.<service>.<function>(\"<id>\")): 1-64 letters, digits, '_', '.' or '-', unique within its section."
              },
              "type": {
                "enum": [
                  "consumable",
                  "nonConsumable",
                  "subscription"
                ],
                "description": "\"consumable\" can be bought again (gems), \"nonConsumable\" once (remove ads), \"subscription\" renews."
              },
              "title": {
                "type": "string",
                "minLength": 1,
                "description": "The product's name. Real stores show their own; the fake backend uses this."
              },
              "titleKey": {
                "type": "string",
                "minLength": 1,
                "description": "A key of locales/<language>.json instead of \"title\": the product's name in the current language. Real stores show their own; the fake backend uses this."
              },
              "description": {
                "type": "string",
                "description": "What it gives. Real stores show their own; the fake backend uses this."
              },
              "descriptionKey": {
                "type": "string",
                "minLength": 1,
                "description": "A key of locales/<language>.json instead of \"description\"."
              },
              "price": {
                "type": "number",
                "minimum": 0,
                "description": "The price the fake backend shows (real stores give their own)."
              },
              "currency": {
                "type": "string",
                "default": "USD",
                "description": "The currency of `price` for the fake backend."
              },
              "ids": {
                "type": "object",
                "description": "The id each store uses for this entry, keyed by backend name: {\"steam\": \"ACH_WIN_ONE_GAME\", \"apple\": \"com.studio.game.first_win\"}. Without an entry for a backend, the id is used as it is.",
                "propertyNames": {
                  "pattern": "^[a-z][a-z0-9_]{0,63}$"
                },
                "additionalProperties": {
                  "type": "string",
                  "minLength": 1
                }
              }
            }
          }
        },
        "ads": {
          "type": "object",
          "description": "Advertising: the placements the game shows ads at (platform.ads.showRewarded(\"<id>\")). Development runs and tests show a scripted test ad; real ad networks (AdMob) come with M12 (docs/PLATFORM.md, \"Ads\").",
          "properties": {
            "placements": {
              "type": "array",
              "description": "Where the game offers an ad: platform.ads.available(\"<id>\") and platform.ads.showRewarded(\"<id>\").",
              "items": {
                "type": "object",
                "required": [
                  "id"
                ],
                "properties": {
                  "id": {
                    "type": "string",
                    "pattern": "^[A-Za-z0-9_.-]{1,64}$",
                    "description": "The id scripts use (platform.ads.showRewarded(\"<id>\")): 1-64 letters, digits, '_', '.' or '-', unique within its section."
                  },
                  "type": {
                    "enum": [
                      "rewarded"
                    ],
                    "default": "rewarded",
                    "description": "The kind of ad: \"rewarded\" (the player watches it to the end for a reward). The only kind so far."
                  },
                  "description": {
                    "type": "string",
                    "description": "What the player gets for watching (for you and for the store consoles; not shown by the engine)."
                  },
                  "ids": {
                    "type": "object",
                    "description": "The ad unit id each ad network uses for this placement, keyed by backend name: {\"admob\": \"ca-app-pub-1234/5678\"}. Without an entry for a backend, the id is used as it is.",
                    "propertyNames": {
                      "pattern": "^[a-z][a-z0-9_]{0,63}$"
                    },
                    "additionalProperties": {
                      "type": "string",
                      "minLength": 1
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "export": {
      "type": "object",
)JSON"
    R"JSON(      "description": "Per-platform export settings, committed with the game. Every field is optional and defaults are applied; a field equal to its default is best left out. Unknown keys inside a platform object only give a warning (with a \"did you mean\"). Edited by the editor's Platform settings window; machine-specific settings (Android SDK and JDK folders, keystore passwords) are never stored here but in ~/.factoria/export.json. See docs/EXPORTING.md, \"Platform settings\".",
      "properties": {
        "scriptBytecode": {
          "type": "boolean",
          "default": true,
          "description": "Release builds of the desktop platforms (factoria export --release for windows, macos, linux): compile the scripts (.js) to QuickJS bytecode inside the game pack instead of shipping their source. Default true. The compiled scripts only run on the FactorIA version that wrote them (a game that meets another version says so and asks for a new export), keep their file names and line numbers in error messages, and leave out the source text. false ships the scripts as plain source in the pack. A script with a syntax error is shipped as source with a warning. Without --release, and on Android and iOS, the setting changes nothing. See docs/EXPORTING.md, \"Release build\"."
        },
        "exclude": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Project-relative globs no export ships (folder, game.pak, web, android, ios): \"store/**\", \"levels/*.tmx\", \"notes\" (a folder). '*' matches inside one folder, '**' crosses folders, '?' one character. Added to the files and folders every export already leaves out (hidden files and folders whose name starts with a dot, build/, tests/, tools/, types/, README.md, the feedback file, AGENTS.md, CLAUDE.md). `factoria validate` warns about a glob that matches no file and fails when one matches the main scene. See docs/EXPORTING.md, \"What is shipped\"."
        },
)JSON"
    R"JSON(        "pack": {
          "type": "object",
          "description": "How a release build packs game.pak (factoria export --release for windows, macos, linux, and every web export): the codec of each file type and the order of the files. The pack is compressed in blocks of 256 KiB, each one decoded on its own, so a game reads only the blocks it needs. See docs/exporting/EXPORTING_DESKTOP.md, \"Release build\".",
          "properties": {
            "codecs": {
              "type": "object",
              "additionalProperties": {"type": "string", "enum": ["store", "lz4", "zstd", "gdeflate"]},
              "description": "File extension (lower case, with its dot: \".json\"; a .scene.json counts as .json) -> \"store\", \"lz4\", \"zstd\" or \"gdeflate\", over the engine's default for that type: store for files that are compressed already (.png, .jpg, .webp, .ogg, .mp3, .qoa, .mp4, .ktx2 with supercompression, archives), zstd for fonts and text (.ttf, .otf, .txt, .md, .csv, .xml, .svg, shader sources), lz4 for everything else (JSON, scenes, scripts and their bytecode, meshes). lz4 decodes fastest, zstd packs smallest, gdeflate is the stream DirectStorage decompresses on the GPU; a block that compression shrinks by less than 1/32 is stored as it is."
            },
            "codec": {
              "type": "string",
              "enum": ["auto", "lz4", "zstd", "gdeflate"],
              "default": "auto",
              "description": "The codec of every file that is compressed (not the ones stored by default, like .png and .ogg, and not an extension named in \"codecs\", which keeps its own). \"auto\" (default): each type's own choice (zstd for fonts and text, lz4 for the rest), except a Windows export with \"directStorage\" on, which packs them as gdeflate. \"lz4\", \"zstd\" or \"gdeflate\": that codec for all of them. gdeflate is Deflate64 in 64 KiB tiles of 32 lanes, the stream DirectStorage 1.1 decompresses on the GPU; other readers decode it on the CPU, somewhat slower than zstd and about half as fast as lz4, with about the ratio of zlib. An older FactorIA cannot read a pack with gdeflate files."
            },
            "directStorage": {
              "type": "boolean",
              "default": false,
              "description": "true makes a Windows export pack its compressed files as gdeflate (see \"codec\") and, in a release export, copy the DirectStorage DLLs that `factoria setup directstorage` installed next to the game, whose player then reads and decompresses those files through DirectStorage (on its worker threads for now; decompression on the GPU comes with GPU destinations). Without the DLLs the export warns and the game decodes them on the CPU. Default false."
            },
            "useLoadOrder": {
              "type": "boolean",
              "default": true,
              "description": "true (default): the files go into the pack in the order the game first read them in play sessions (the editor's Play, factoria run, play.auto record it per scene in .factoria/cache/load-order.json): the main scene's files first, then each scene's in the order the scenes first loaded, then the files no session read, by path. Reading a pack front to back is what disks and SSDs do fastest. false, or no session recorded yet: by path. The export says which order it used and how many files it covered."
            },
            "vendorSdks": {
              "oneOf": [
                {"type": "string", "enum": ["auto", "none"]},
                {"type": "array", "items": {"type": "string", "enum": ["streamline", "xess", "fidelityfx"]}, "uniqueItems": true}
              ],
              "default": "auto",
              "description": "Which vendor SDKs a Windows export copies next to the game, with their license texts in licenses/<id>/: \"auto\" (default) ships each one that is installed (`factoria setup streamline | xess | fidelityfx`) and that the project's render settings can use (render.upscaler.mode and render.frameGeneration.mode auto, dlss, xess or fsr; render.latency.mode auto, reflex or xell), and says in the export report when one is not installed; \"none\" ships none; an array of ids ships exactly those and fails when one is not installed. streamline is NVIDIA Streamline (DLSS, Frame Generation, Reflex), xess Intel XeSS, fidelityfx the AMD FidelityFX SDK. Each SDK's license is accepted when it is installed; NVIDIA's asks you to notify NVIDIA before a commercial release (the export report repeats it). Other platforms ship nothing."
            }
          }
        },
        "windows": {
          "type": "object",
          "description": "Windows export settings (factoria export --platform windows).",
          "properties": {
            "icon": {
              "type": "string",
              "description": "Icon of the Windows export, replacing the project's top-level \"icon\" there. Same rules as the top-level \"icon\". Empty or absent = use the project's \"icon\"."
            },
            "format": {
              "type": "string",
              "enum": ["folder", "msix"],
              "default": "folder",
              "description": "\"folder\" (default): <slug>-windows/ with the exe and the game. \"msix\": also writes <out>/<slug>-windows.msix next to that folder, the package of the Microsoft Store (and of Add-AppxPackage on a PC). It can be built on any computer. `factoria export --format msix` wins over this. See docs/EXPORTING.md, \"Microsoft Store\"."
            },
            "msix": {
              "type": "object",
              "description": "The MSIX package of the Microsoft Store (format \"msix\"). The identity fields come from Partner Center > your app > Product identity; a package built without them installs on your own PC but the Store rejects it. See docs/EXPORTING.md, \"Microsoft Store\".",
              "properties": {
                "identityName": {
                  "type": "string",
                  "pattern": "^[A-Za-z0-9][A-Za-z0-9.\\-]{1,48}[A-Za-z0-9]$",
                  "description": "Package/Identity/Name: 3 to 50 letters, digits, '.' and '-'. Partner Center shows it as \"Package/Identity/Name\", e.g. \"12345MyStudio.MyGame\"."
                },
                "publisher": {
                  "type": "string",
                  "pattern": "^[Cc][Nn]=.+",
                  "description": "Package/Identity/Publisher, copied exactly from Partner Center (\"CN=0123ABCD-4567-89EF-0123-456789ABCDEF\"). It must equal the subject of the certificate that signs the package (the Store signs uploads itself)."
                },
                "publisherDisplayName": {
                  "type": "string",
                  "description": "The publisher name players see (Partner Center > Product identity > Package/Properties/PublisherDisplayName)."
                },
                "displayName": {
                  "type": "string",
                  "description": "The name of the app in the Start menu and the Store listing. Default: the game's name."
                },
                "description": {
                  "type": "string",
                  "description": "The short description Windows shows for the app. Default: the display name."
                },
                "backgroundColor": {
                  "type": "string",
                  "pattern": "^(transparent|#[0-9A-Fa-f]{6})$",
                  "default": "transparent",
                  "description": "Background of the app's tile: \"#RRGGBB\" or \"transparent\" (default)."
                },
                "version": {
                  "type": "string",
                  "pattern": "^[0-9]{1,5}(\\.[0-9]{1,5}){3}$",
                  "description": "Package version, four numbers (\"1.2.3.0\"). The Microsoft Store requires the fourth to be 0. Default: the project's \"version\" with a 0 appended (1.2.3 -> 1.2.3.0)."
                },
                "minVersion": {
                  "type": "string",
                  "pattern": "^[0-9]{1,5}(\\.[0-9]{1,5}){3}$",
                  "default": "10.0.17763.0",
                  "description": "Oldest Windows 10 build the package installs on (TargetDeviceFamily MinVersion). Default 10.0.17763.0 (Windows 10 version 1809)."
                },
                "languages": {
                  "type": "array",
                  "items": {"type": "string"},
                  "description": "Language tags the app lists as resources (\"en-us\", \"es-es\"): the Store lists the app for these. Default: localization.languages of the project, else [\"en-us\"]."
                }
              }
            }
          }
        },
        "macos": {
          "type": "object",
          "description": "macOS export settings (factoria export --platform macos): fields of the app's Info.plist.",
          "properties": {
            "icon": {
              "type": "string",
              "description": "Icon of the macOS export, replacing the project's top-level \"icon\" there. Same rules as the top-level \"icon\". Empty or absent = use the project's \"icon\"."
            },
            "category": {
              "type": "string",
              "minLength": 1,
              "description": "Mac App Store category of the app (LSApplicationCategoryType in Info.plist), e.g. \"public.app-category.games\" (the default), \"public.app-category.action-games\", \"public.app-category.puzzle-games\", \"public.app-category.role-playing-games\"."
            },
            "minimumSystemVersion": {
              "type": "string",
              "pattern": "^[0-9]+(\\.[0-9]+){0,2}$",
              "description": "Oldest macOS the app runs on (LSMinimumSystemVersion in Info.plist), as \"major.minor\". Default \"11.0\", which is also the lowest value: FactorIA's macOS player needs macOS 11 or newer."
            },
            "copyright": {
              "type": "string",
              "description": "Copyright notice shown in the app's About information (NSHumanReadableCopyright in Info.plist), e.g. \"Copyright 2026 My Studio\". Default: none."
            },
            "buildNumber": {
              "type": "string",
              "pattern": "^([0-9]+(\\.[0-9]+){0,2})?$",
              "description": "Build number of the app (CFBundleVersion): up to three whole numbers separated by dots, e.g. \"42\" or \"1.2.3\"; the Mac App Store needs it to grow with every upload of the same version. Default: the project's \"version\"."
            },
            "usesNonExemptEncryption": {
              "type": "boolean",
              "description": "ITSAppUsesNonExemptEncryption in Info.plist: true only when the game uses encryption beyond what macOS provides (HTTPS and other system encryption are exempt). Default false, so App Store Connect does not ask the export-compliance question at every upload."
            },
            "entitlements": {
              "type": "object",
              "description": "Sandbox capabilities the game needs beyond the default, added to the entitlements of the Mac App Store signature (sign.macos with distribution \"appStore\"): {\"com.apple.security.network.client\": true} lets the game open network connections. The default is only com.apple.security.app-sandbox (the player's save folder, log, screenshots, gamepads, audio and opening links need nothing else); the entitlements of the native plugins are added on top. Values are true/false, a string, a whole number or an array of strings. Keys that FactorIA sets itself (the sandbox, the application and team identifiers) are not allowed. Default: none. See docs/EXPORTING.md, \"Mac App Store\".",
              "additionalProperties": {
                "anyOf": [
                  {"type": "boolean"},
                  {"type": "string"},
                  {"type": "integer"},
                  {"type": "array", "items": {"type": "string"}}
                ]
              }
            }
          }
        },
        "linux": {
          "type": "object",
          "description": "Linux export settings (factoria export --platform linux).",
          "properties": {
            "icon": {
              "type": "string",
              "description": "Icon of the Linux export, replacing the project's top-level \"icon\" there. Same rules as the top-level \"icon\". Empty or absent = use the project's \"icon\"."
            },
            "categories": {
              "type": "array",
              "items": {
                "type": "string",
                "minLength": 1,
                "pattern": "^[^;]+$",
                "description": "One freedesktop.org menu category, e.g. \"Game\", \"ActionGame\", \"ArcadeGame\", \"PuzzleGame\"."
              },
              "description": "Menu categories of the game's .desktop file (the Categories= line; FactorIA joins the entries with ';'). Default [\"Game\"]."
            },
            "vulkanPlayer": {
              "type": "boolean",
              "default": true,
              "description": "Ship the Vulkan variant of the player: the game's executable is factoria_player_vulkan and <executable>-gl the GL player it starts where Vulkan cannot (no driver, no device). Only when the variant is next to the player the export uses. false = only the GL player, as the game's executable. Default true."
            }
          }
        },
        "android": {
          "type": "object",
          "description": "Android export settings (factoria export --platform android).",
          "properties": {
            "icon": {
              "type": "string",
              "description": "Icon of the Android export, replacing the project's top-level \"icon\" there. Same rules as the top-level \"icon\". Empty or absent = use the project's \"icon\". The launcher icons are generated from it, unless adaptiveIcon says otherwise."
            },
            "format": {
              "enum": [
                "apk",
                "aab",
                "gradle"
              ],
              "description": "What the Android export produces: \"apk\" (default; runs the Gradle build and copies <game>.apk next to the project; debug builds are <game>-debug.apk), \"aab\" (an Android App Bundle for Google Play) or \"gradle\" (only the Gradle project, to open in Android Studio)."
            },
            "adaptiveIcon": {
              "type": "object",
              "description": "Layers of the Android adaptive icon (Android 8+). Absent = the game icon scaled into the safe zone over a white background.",
              "properties": {
                "foreground": {
                  "type": "string",
                  "description": "Project-relative path of the foreground layer: a square PNG of the whole 108dp layer (432x432 recommended) in which only the inner 66dp circle is guaranteed to stay visible, with a transparent background. Default: the game icon scaled into that safe zone (66/108 of the layer)."
                },
                "background": {
                  "type": "string",
                  "description": "Background of the adaptive icon: a colour written \"#RRGGBB\" (default \"#FFFFFF\"), or the project-relative path of a square image (432x432 recommended) that fills the whole layer."
                },
                "monochrome": {
                  "type": "string",
                  "description": "Optional project-relative path of a square single-colour PNG with transparency (432x432 recommended) that Android 13+ tints for themed icons. Default: none, so the icon is not themed."
                }
              }
            },
            "versionCode": {
              "type": "integer",
              "minimum": 1,
              "maximum": 2100000000,
              "description": "Android versionCode: a whole number that must grow with every upload to Google Play. Default: derived from \"version\" (1.2.3 -> 10203; each part is capped at 99)."
            },
            "minSdk": {
)JSON"
    R"JSON(              "type": "integer",
              "minimum": 26,
              "maximum": 99,
              "description": "Lowest Android API level the app installs on. Default 26 (Android 8.0), which is also the lowest value; it must not exceed targetSdk."
            },
            "targetSdk": {
              "type": "integer",
              "minimum": 26,
              "maximum": 99,
              "description": "Android API level the app is built and tested against (also the compileSdk). Default 36; Google Play requires a recent one for new apps and updates. Must be at least minSdk."
            },
            "permissions": {
              "type": "array",
              "items": {
                "type": "string",
                "pattern": "^[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+$",
                "description": "Android permission name, e.g. \"android.permission.VIBRATE\"."
              },
              "description": "Extra <uses-permission> entries of the manifest, for permissions the game's scripts or features need (the engine itself needs none). Default: none."
            },
            "vulkanPlayer": {
              "type": "boolean",
              "default": true,
              "description": "Ship the Vulkan variant of the player: the launcher activity loads libfactoria_player_vulkan.so and hands over to the GL player (libfactoria_player.so, its own activity in the process :gl) where Vulkan cannot start. A prebuilt export ships it only when the downloaded players have it for every ABI. false = only the GL player, as the launcher. Default true."
            },
            "signing": {
              "type": "object",
              "description": "Release signing of the Android export. The keystore PASSWORDS never go in the project: they come from the FACTORIA_ANDROID_KEYSTORE_PASSWORD and FACTORIA_ANDROID_KEY_PASSWORD environment variables, or from the machine settings file ~/.factoria/export.json. Release builds without a keystore are signed with the debug key and warn.",
              "properties": {
                "keystore": {
                  "type": "string",
                  "description": "Path of the keystore file (.keystore or .jks): project-relative, or absolute (keystores are better kept outside the repository). Create one with the editor's \"Create keystore...\" button or the JDK's keytool."
                },
                "alias": {
                  "type": "string",
                  "description": "Alias of the signing key inside the keystore (the -alias given to keytool), e.g. \"upload\"."
                }
              }
            }
          }
        },
        "ios": {
          "type": "object",
          "description": "iOS export settings (factoria export --platform ios).",
          "properties": {
            "icon": {
              "type": "string",
              "description": "Icon of the iOS export, replacing the project's top-level \"icon\" there. Same rules as the top-level \"icon\". Empty or absent = use the project's \"icon\". The App Store icon is the icon composed over iconBackground."
            },
            "iconBackground": {
              "type": "string",
              "pattern": "^#[0-9A-Fa-f]{6}$",
              "description": "Colour \"#RRGGBB\" the icon is composed over: the App Store rejects icons with transparency, so any transparent pixels of the icon take this colour. Default \"#FFFFFF\"."
            },
            "teamId": {
              "type": "string",
              "pattern": "^([A-Z0-9]{10})?$",
              "description": "Apple developer Team ID (10 capital letters and digits, shown at developer.apple.com/account under Membership details), used to sign device builds. Default: the FA_IOS_DEVELOPMENT_TEAM environment variable of build_ios.sh, which takes precedence when set."
            },
            "buildNumber": {
              "type": "string",
              "pattern": "^([0-9]+(\\.[0-9]+){0,2})?$",
              "description": "Build number of the app (CFBundleVersion): up to three whole numbers separated by dots, e.g. \"42\" or \"1.2.3\"; it must grow with every App Store upload of the same version. Default: the project's \"version\"."
            },
            "usesNonExemptEncryption": {
              "type": "boolean",
              "description": "ITSAppUsesNonExemptEncryption in Info.plist: true only when the game uses encryption beyond what iOS provides (HTTPS and other system encryption are exempt). Default false, so App Store Connect does not ask the export-compliance question at every upload."
            },
            "privacy": {
              "type": "object",
              "description": "What the game adds to the privacy manifest PrivacyInfo.xcprivacy that the iOS export writes into the app. The engine's own required-reason APIs (file timestamps, system boot time) are always declared; nothing is collected and nothing tracks unless this says so. Add what your plugins or scripts do. See docs/MOBILE.md, \"Store privacy forms\".",
              "properties": {
                "tracking": {
                  "type": "boolean",
                  "description": "NSPrivacyTracking: true when the app or an SDK in it tracks users across other companies' apps and sites. Default false. Needs trackingDomains."
                },
                "trackingDomains": {
                  "type": "array",
                  "items": { "type": "string" },
                  "description": "NSPrivacyTrackingDomains: the domains that connect to tracking services, e.g. [\"ads.example.com\"]. Default none."
                },
                "accessedApis": {
                  "type": "array",
                  "description": "Required-reason APIs the game's plugins or native code call, on top of the engine's. Each entry names a category and the reason codes that fit; entries for a category the engine already declares are merged with it.",
                  "items": {
                    "type": "object",
                    "required": ["category", "reasons"],
                    "properties": {
                      "category": {
                        "type": "string",
                        "enum": ["FileTimestamp", "SystemBootTime", "DiskSpace", "UserDefaults", "ActiveKeyboards"],
                        "description": "The API category (the NSPrivacyAccessedAPICategory name without the prefix)."
                      },
                      "reasons": {
                        "type": "array",
                        "minItems": 1,
                        "items": { "type": "string", "pattern": "^[A-Z0-9]{4}\\.[0-9]$" },
                        "description": "Apple's reason codes for the category, e.g. [\"E174.1\"] for DiskSpace. FileTimestamp: DDA9.1, C617.1, 3B52.1, 0A2A.1. SystemBootTime: 35F9.1, 8FFB.1, 3D61.1. DiskSpace: E174.1, 85F4.1, 7D9E.1, B728.1. UserDefaults: CA92.1, 1C8F.1, C56D.1, AC6B.1. ActiveKeyboards: 3EC4.1, 54BD.1."
                      }
                    }
                  }
                },
                "collectedData": {
                  "type": "array",
                  "description": "Data the app collects (NSPrivacyCollectedDataTypes), for example the purchase history a store plugin reads. Default none: a game that sends nothing off the device collects nothing.",
                  "items": {
                    "type": "object",
                    "required": ["type", "purposes"],
                    "properties": {
                      "type": {
                        "type": "string",
                        "description": "The kind of data, without the NSPrivacyCollectedDataType prefix: Name, EmailAddress, PhoneNumber, PhysicalAddress, OtherUserContactInfo, Health, Fitness, PaymentInfo, CreditInfo, OtherFinancialInfo, PreciseLocation, CoarseLocation, SensitiveInfo, Contacts, EmailsOrTextMessages, PhotosOrVideos, AudioData, GameplayContent, CustomerSupport, OtherUserContent, BrowsingHistory, SearchHistory, UserID, DeviceID, PurchaseHistory, ProductInteraction, AdvertisingData, OtherUsageData, CrashData, PerformanceData, OtherDiagnosticData, EnvironmentScanning, Hands, Head or OtherDataTypes."
                      },
                      "linked": {
                        "type": "boolean",
                        "description": "True when the data is linked to the user's identity. Default false."
                      },
                      "tracking": {
                        "type": "boolean",
                        "description": "True when the data is used to track the user. Default false."
                      },
                      "purposes": {
                        "type": "array",
                        "minItems": 1,
                        "items": { "type": "string", "enum": ["ThirdPartyAdvertising", "DeveloperAdvertising", "Analytics", "ProductPersonalization", "AppFunctionality", "Other"] },
                        "description": "Why the data is collected (the NSPrivacyCollectedDataTypePurpose name without the prefix)."
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "feedbackFile": {
      "type": "string",
      "description": "Project-relative path of the engine feedback log (default ENGINE_FEEDBACK.json)."
    },
)JSON"
    R"JSON(    "publish": {
      "type": "object",
      "description": "Where the game is sold, for the publish.steam, publish.itch, publish.epic, publish.gog, publish.appstore, publish.googleplay and publish.microsoft commands (`factoria call publish.steam '{\"dryRun\":true}'`): the ids of the game in each store. Only the stores you publish to need an entry. Nothing secret goes here: passwords, API keys and client secrets are environment variables (BUTLER_API_KEY, FACTORIA_EPIC_CLIENT_SECRET, FACTORIA_GOG_USERNAME / FACTORIA_GOG_PASSWORD; the App Store Connect API key and the Google Play service account key are files named by FACTORIA_APPSTORE_API_KEY and FACTORIA_GOOGLEPLAY_JSON_KEY) or the stores' tools keep the login themselves. Steam's app id is the one in steam_appid.txt. Unknown keys give a warning with a \"did you mean\". See docs/EXPORTING.md, \"Uploading to stores\".",
      "properties": {
        "steam": {
          "type": "object",
          "description": "Steam (SteamPipe, uploaded with steamcmd).",
          "properties": {
            "account": {
              "type": "string",
              "minLength": 1,
              "description": "Name of the Steam account that uploads builds (a build account with the \"Edit App Metadata\" permission), e.g. \"mystudio_build\". Its password is never stored: sign in once with `steamcmd +login <account>` and steamcmd keeps the login."
            },
            "depots": {
              "type": "object",
              "description": "The depot id of each platform, from the Steamworks partner site (App Admin > SteamPipe > Depots): {\"windows\": 1234561, \"macos\": 1234562, \"linux\": 1234563}. A platform without a depot is not uploaded.",
              "additionalProperties": {
                "type": [
                  "integer",
                  "string"
                ]
              }
            },
            "branch": {
              "type": "string",
              "minLength": 1,
              "description": "Beta branch to set every uploaded build live on, e.g. \"beta\". Absent = the build is only uploaded. \"default\" is not allowed: Steam sets that branch live by hand only."
            }
          }
        },
        "itch": {
          "type": "object",
          "description": "itch.io (uploaded with butler).",
          "properties": {
            "game": {
              "type": "string",
              "pattern": "^[a-z0-9_-]+/[a-z0-9_-]+$",
              "description": "Your itch.io page as \"user/game\" in lower case, from its address (mystudio.itch.io/space-dodge is \"mystudio/space-dodge\")."
            },
            "channels": {
              "type": "object",
              "description": "The butler channel of each platform. itch.io tags a download by the words in its channel name: windows, linux, mac or osx. Default: {\"windows\": \"windows\", \"macos\": \"mac\", \"linux\": \"linux\"}.",
              "additionalProperties": {
                "type": "string"
              }
            }
          }
        },
        "epic": {
          "type": "object",
          "description": "Epic Games Store (uploaded with BuildPatchTool). The ids are in the Epic Games Dev Portal.",
          "properties": {
            "organizationId": {
              "type": "string",
              "minLength": 1,
              "description": "Organization ID (Dev Portal > Organization settings)."
            },
            "productId": {
              "type": "string",
              "minLength": 1,
              "description": "Product ID of the game (Dev Portal > Product settings)."
            },
            "clientId": {
              "type": "string",
              "minLength": 1,
              "description": "Client ID of the Build Patch Tool credential (Product Settings > General > Build Patch Tool Credentials; an SDK client does not work). Its secret goes in the environment variable FACTORIA_EPIC_CLIENT_SECRET, never here."
            },
            "artifacts": {
              "type": "object",
              "description": "The artifact id of each platform (Dev Portal > Artifacts and Binaries): {\"windows\": \"<id>\", \"macos\": \"<id>\"}. A platform without an artifact is not uploaded.",
              "additionalProperties": {
                "type": "string"
              }
            }
          }
        },
        "gog": {
          "type": "object",
          "description": "GOG (uploaded with GOG Galaxy Pipeline Builder).",
          "properties": {
            "productId": {
              "type": [
                "string",
                "integer"
              ],
              "description": "Product id of the game in the GOG Developer Portal."
            },
            "clientId": {
              "type": [
                "string",
                "integer"
              ],
              "description": "GALAXY SDK client id of the game, when it uses the GALAXY SDK (its secret is not written to the project file). Default: none."
            },
            "languages": {
              "type": "array",
              "minItems": 1,
              "items": {
                "type": "string"
              },
              "description": "Locale codes of the languages the game supports, e.g. [\"en-US\", \"fr-FR\"]. Default [\"en-US\"]."
            }
          }
        },
        "appstore": {
          "type": "object",
          "description": "App Store Connect / TestFlight (the .ipa is uploaded with xcrun altool; macOS only). The bundle id is the game's top-level \"id\".",
          "properties": {
            "appleId": {
              "type": [
                "string",
                "integer"
              ],
              "description": "The app's Apple ID, the number under App Store Connect > your app > App Information > General Information (e.g. 6448277777; not an e-mail address). The App Store Connect API key is a file named by the environment variable FACTORIA_APPSTORE_API_KEY (with FACTORIA_APPSTORE_API_KEY_ID and FACTORIA_APPSTORE_API_ISSUER), never written here."
            }
          }
        },
        "googleplay": {
          "type": "object",
          "description": "Google Play (the release .aab is uploaded with fastlane supply). The package name is the game's top-level \"id\". The service account key is a file named by the environment variable FACTORIA_GOOGLEPLAY_JSON_KEY, never written here. The first bundle of a new app must be uploaded by hand in the Play Console.",
          "properties": {
            "track": {
              "type": "string",
              "description": "Release track: internal, alpha, beta, production, or the name of a closed testing track. Default \"internal\"."
            },
            "releaseStatus": {
              "type": "string",
              "enum": [
                "draft",
                "completed"
              ],
              "description": "draft: the release waits in the Play Console until you roll it out; completed: it rolls out right away (an app that was never published accepts only draft). Default \"draft\"."
            },
            "changelogs": {
              "type": "object",
              "description": "The release notes (\"What's new\") per Google Play language: {\"en-US\": \"store/whats-new-en.txt\"}. Each value is the project-relative path of a text file of 1 to 500 characters. Default: no release notes uploaded.",
              "additionalProperties": {
                "type": "string"
              }
            }
          }
        },
        "microsoft": {
          "type": "object",
          "description": "Microsoft Store (the .msix is uploaded with the Microsoft Store Developer CLI, msstore). The package identity comes from export.windows.msix. The Partner Center credentials (tenant id, seller id, client id, client secret) are the environment variables FACTORIA_MSSTORE_TENANT_ID, FACTORIA_MSSTORE_SELLER_ID, FACTORIA_MSSTORE_CLIENT_ID and FACTORIA_MSSTORE_CLIENT_SECRET, never written here. The first submission of a new app must be created by hand in Partner Center.",
          "properties": {
            "productId": {
              "type": "string",
              "pattern": "^[A-Za-z0-9]{12}$",
              "description": "The Store ID (Partner Center > your app > Product identity > Store ID, 12 characters such as 9NBLGGH4NNS1)."
            }
          }
        }
      }
    }
  }
})JSON";
}

Json project_json_schema() {
    auto r = parse_json(kSchemaText, "project schema");
    return r.ok() ? r.value() : Json::object();
}

}  // namespace fa
