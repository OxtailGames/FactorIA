#include "fa/runtime/project.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <sstream>

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include "fa/core/fs.h"
#include "fa/core/i18n.h"
#include "fa/core/strings.h"

namespace fa {

namespace stdfs = std::filesystem;

std::string asset_type_of(std::string_view path) {
    const std::string p = to_lower(path);
    if (ends_with(p, ".scene.json")) return "scene";
    if (ends_with(p, ".prefab.json")) return "prefab";
    if (ends_with(p, ".material.json")) return "material";
    const auto dot = p.rfind('.');
    const auto slash = p.find_last_of('/');
    if (dot == std::string::npos || (slash != std::string::npos && dot < slash)) return "other";
    const std::string ext = p.substr(dot);
    if (ext == ".png" || ext == ".jpg" || ext == ".jpeg" || ext == ".tga" || ext == ".bmp") return "texture";
    if (ext == ".wav" || ext == ".ogg" || ext == ".mp3" || ext == ".qoa") return "audio";
    if (ext == ".mpg" || ext == ".mpeg") return "video";
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
    if (t == "fit") out = ScaleMode::Fit;
    else if (t == "stretch") out = ScaleMode::Stretch;
    else if (t == "expand") out = ScaleMode::Expand;
    else if (t == "pixelperfect") out = ScaleMode::PixelPerfect;
    else return false;
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
    Json input = j.contains("input") && j["input"].is_object() ? j["input"] : Json::object();
    input["actions"] = inputActions;
    input["deadzone"] = inputDeadzone;
    if (!inputSchemes.empty()) input["schemes"] = inputSchemes;
    else input.erase("schemes");
    j["input"] = input;
    Json plats = Json::array();
    for (const auto& p : platforms) plats.push_back(p);
    j["platforms"] = plats;
    j["feedbackFile"] = feedbackFile;
    if (icon.empty()) j.erase("icon");
    else j["icon"] = icon;
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
            if (auto own = plat->find("icon"); own != plat->end() && own->is_string() && !own->get<std::string>().empty())
                return own->get<std::string>();
    return icon;
}

namespace {

std::string at(std::string_view pointer) { return std::string(kProjectFileName) + "#" + std::string(pointer); }

Error field_error(std::string_view pointer, const std::string& expected, const Json& got, const std::string& hint = {}) {
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

#define FA_TRY(expr)                    \
    do {                                \
        Result<void> r_ = (expr);       \
        if (!r_.ok()) return r_.error(); \
    } while (0)

// Names a plugin cannot take: the areas of the built-in commands (a plugin's commands are "<name>.<verb>") and the
// names scripts already use.
const std::vector<std::string>& reserved_plugin_names() {
    static const std::vector<std::string> names = {
        "ai",   "api",     "app",    "assets",  "audio",   "debug",   "docs",    "editor", "engine", "fa",    "factoria",
        "feedback", "fs",  "game",   "i18n",    "input",   "level",   "math",    "mcp",     "nav",     "physics", "play",  "plugin", "plugins",
        "platform", "prefab", "project", "scene", "script", "session", "settings", "setup", "test", "ui", "world"};
    return names;
}

bool is_plugin_name(const std::string& n) {
    if (n.empty() || n.size() > 64 || !(n[0] >= 'a' && n[0] <= 'z')) return false;
    return std::all_of(n.begin(), n.end(), [](char c) { return (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_'; });
}

// One entry of "plugins": {"path": "...", "platforms": [...], "optional": false}.
Result<PluginSettings> read_plugin(const std::string& name, const Json& v) {
    const std::string ptr = "/plugins/" + name;
    if (!is_plugin_name(name))
        return make_error(at(ptr) + ": '" + name + "' is not a plugin name",
                          "Use lower-case letters, digits and underscores, starting with a letter (at most 64), e.g. \"steam\" or "
                          "\"play_billing\": scripts call plugins." + name + ".<function>() and its commands are <name>.<verb>.");
    const auto& reserved = reserved_plugin_names();
    if (std::find(reserved.begin(), reserved.end(), name) != reserved.end())
        return make_error(at(ptr) + ": '" + name + "' is a name the engine uses (its commands are " + name + ".*)",
                          "Give the plugin another name, e.g. \"" + name + "_plugin\" or the name of the SDK it wraps.");
    if (!v.is_object())
        return field_error(ptr, "an object like {\"path\": \"plugins/" + name + "\"}", v,
                           "\"path\" is the plugin's folder: project-relative, absolute, or with ${VARIABLE} parts.");
    PluginSettings p;
    p.name = name;
    FA_TRY(read_string(v, "path", ptr, p.path));
    if (p.path.empty())
        return make_error(at(ptr + "/path") + ": missing or empty",
                          "Set the folder that holds the plugin's builds (windows/, macos/, linux/, android/, ios/), e.g. \"path\": "
                          "\"plugins/" + name + "\" or \"${MY_SDK_PLUGINS}/" + name + "\" for a private folder outside the repository.");
    if (auto it = v.find("platforms"); it != v.end() && !it->is_null()) {
        if (!it->is_array() || it->empty())
            return field_error(ptr + "/platforms", "a non-empty array of platform names", *it,
                               "List the platforms the plugin is built for, e.g. [\"windows\", \"android\"], or leave it out "
                               "for every platform of the game.");
        for (std::size_t k = 0; k < it->size(); ++k) {
            const Json& e = (*it)[k];
            const std::string name_k = e.is_string() ? e.get<std::string>() : std::string();
            const auto& all = platform_names();
            if (std::find(all.begin(), all.end(), name_k) == all.end())
                return make_error(at(ptr + "/platforms/" + std::to_string(k)) + ": " + describe_json_value(e) + " is not a platform",
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
    if (fs::pack_mounted() && (projectDir.empty() || is_project_root(projectDir))) return fs::read_text(kProjectFileName);
    if (!projectDir.empty()) {
        stdfs::path p = stdfs::path(std::string(projectDir)) / kProjectFileName;
        std::error_code ec;
        if (stdfs::is_regular_file(p, ec)) {
            std::ifstream in(p, std::ios::binary);
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
        issue("", "expected an object like {\"defaultLanguage\": \"en\", \"languages\": [\"en\", \"es\"]}, got " + describe_json_value(section),
              "Declare the game's languages; each has a string table locales/<language>.json (docs/LOCALIZATION.md).");
        return r;
    }
    const std::string tagHint =
        "Write BCP 47 tags with this case: language lower case, script capitalized, region upper case: \"en\", \"pt-BR\", \"zh-Hans\".";
    // A language tag at `pointer`, stored in `into` when it is written the canonical way.
    const auto read_tag = [&](const Json& value, const std::string& pointer, std::string& into) {
        if (!value.is_string()) {
            issue(pointer, "expected a language tag such as \"en\" or \"pt-BR\", got " + describe_json_value(value), tagHint);
            return false;
        }
        const std::string tag = value.get<std::string>();
        if (!is_language_tag(tag)) {
            const std::string fixed = normalize_language_tag(tag);
            issue(pointer, "\"" + tag + "\" is not a language tag" + (fixed.empty() ? std::string() : ". Did you mean \"" + fixed + "\"?"), tagHint);
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
                      "Copy the font into the project (assets/fonts/) and write its project-relative path with forward slashes.");
                continue;
            }
            into.push_back(path);
        }
    };

    static const std::vector<std::string> keys = {"defaultLanguage", "languages", "fallbackFonts", "languageFonts"};
    for (auto it = section.begin(); it != section.end(); ++it)
        if (std::find(keys.begin(), keys.end(), it.key()) == keys.end())
            r.warnings.push_back({"/localization/" + it.key(),
                                  "unknown key \"" + it.key() + "\" in \"localization\" (ignored). " + did_you_mean(it.key(), keys),
                                  "Remove it or fix the spelling."});

    std::string def;
    bool hasDefault = false;
    if (auto it = section.find("defaultLanguage"); it != section.end() && !it->is_null()) hasDefault = read_tag(*it, "/defaultLanguage", def);
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
              "Add \"languages\": [\"en\", \"es\"] (and a locales/<tag>.json for each), or remove the \"localization\" section.");
        languagesBad = true;
    }
    if (hasDefault && !languagesBad && std::find(s.languages.begin(), s.languages.end(), def) == s.languages.end())
        issue("/defaultLanguage", "\"" + def + "\" is not one of \"languages\". " + did_you_mean(def, s.languages),
              "Add it to \"languages\" or choose one of them.");
    else if (!s.languages.empty())
        s.defaultLanguage = hasDefault ? def : s.languages.front();

    if (auto it = section.find("fallbackFonts"); it != section.end() && !it->is_null()) read_fonts(*it, "/fallbackFonts", s.fallbackFonts);
    if (auto it = section.find("languageFonts"); it != section.end() && !it->is_null()) {
        if (!it->is_object()) {
            issue("/languageFonts", "expected an object mapping a language to its fonts, got " + describe_json_value(*it),
                  "Example: \"languageFonts\": {\"zh-Hans\": [\"assets/fonts/NotoSansSC-Regular.ttf\"]}.");
        } else {
            for (auto lf = it->begin(); lf != it->end(); ++lf) {
                const std::string pointer = "/languageFonts/" + lf.key();
                if (!is_language_tag(lf.key())) {
                    issue(pointer, "\"" + lf.key() + "\" is not a language tag", tagHint);
                    continue;
                }
                if (!languagesBad && std::find(s.languages.begin(), s.languages.end(), lf.key()) == s.languages.end()) {
                    issue(pointer, "\"" + lf.key() + "\" is not one of \"languages\". " + did_you_mean(lf.key(), s.languages),
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
        return make_error("Cannot read " + std::string(kProjectFileName) + " in '" + std::string(projectDir) +
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
            dirName = stdfs::absolute(stdfs::path(projectDir.empty() ? "." : std::string(projectDir)), ec).parent_path().filename().string();
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
                        return field_error("/input/actions/" + ai.key() + "/" + std::to_string(k), "a binding name string",
                                           (*ai)[k], "Binding names look like \"Space\", \"A\", \"MouseLeft\".");
            }
            s.inputActions = *a;
        }
        if (auto sc = it->find("schemes"); sc != it->end() && !sc->is_null()) {
            if (!sc->is_object())
                return field_error("/input/schemes", "an object mapping scheme names to key sets", *sc,
                                   "Example: \"schemes\": {\"arrows\": {\"extends\": \"right\"}}; the actions and key names are checked when the game starts.");
            s.inputSchemes = *sc;
        }
        if (auto d = it->find("deadzone"); d != it->end() && !d->is_null()) {
            if (!d->is_number()) return field_error("/input/deadzone", "a number from 0 to 0.95", *d);
            double v = d->get<double>();
            if (!(v >= 0.0 && v < 1.0))
                return make_error(at("/input/deadzone") + ": value " + std::to_string(v) + " must be at least 0 and below 1",
                                  "Typical values: 0.1 (precise sticks) to 0.3 (worn or drifting sticks); the default is 0.2.");
            s.inputDeadzone = v;
        }
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
        std::sort(s.plugins.begin(), s.plugins.end(), [](const PluginSettings& a, const PluginSettings& b) { return a.name < b.name; });
    }
    if (auto it = j.find("localization"); it != j.end() && !it->is_null()) {
        LocalizationParse loc = parse_localization(*it);
        if (!loc.ok()) {
            const LocalizationIssue& first = loc.issues.front();
            std::string more;
            if (loc.issues.size() > 1)
                more = " (and " + std::to_string(loc.issues.size() - 1) + " more problem(s) in \"localization\"; `factoria validate` lists them all)";
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
    "input": {
      "type": "object",
      "description": "Input configuration.",
      "properties": {
        "actions": {
          "type": "object",
          "description": "Named input actions. Each maps to a list of bindings: key names (\"Space\", \"A\", \"Left\"), \"MouseLeft\"/\"MouseRight\"/\"MouseMiddle\", \"Touch\", gamepad buttons (\"GamepadA\", \"GamepadStart\", \"GamepadDpadLeft\"...) and gamepad half axes (\"GamepadLeftStickLeft\", \"GamepadRightStickUp\", \"GamepadRightTrigger\"...). Gamepad bindings match any connected pad.",
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
          "description": "The bold face of each font, keyed by the font as a Text names it: a project path such as \"assets/fonts/Body-Regular.ttf\", \"builtin:pixel\" or \"\" (the built-in font). `[b]` and `Text.bold` use it for the glyphs it has; a font with no entry (or a glyph its bold face lacks) is emboldened by the engine, which looks heavier but never as good as a drawn face. `factoria validate` suggests adding one for a font that markup or bold uses.",
          "additionalProperties": {
            "type": "object",
            "description": "One font.",
            "properties": {
              "bold": {
                "type": "string",
                "description": "Project-relative path of the bold font file (.ttf or .otf)."
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
