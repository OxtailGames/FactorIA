#include "fa/runtime/project.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

namespace stdfs = std::filesystem;

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
    j["input"] = input;
    Json plats = Json::array();
    for (const auto& p : platforms) plats.push_back(p);
    j["platforms"] = plats;
    j["feedbackFile"] = feedbackFile;
    return j;
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

Result<std::string> read_project_text(std::string_view projectDir) {
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
        if (dirName.empty() || dirName == ".") dirName = stdfs::absolute(stdfs::path(std::string(projectDir))).parent_path().filename().string();
        if (!dirName.empty()) s.name = dirName;
    }
    FA_TRY(read_string(j, "name", "", s.name));
    FA_TRY(read_string(j, "id", "", s.id));
    FA_TRY(read_string(j, "version", "", s.version));
    FA_TRY(read_string(j, "engine", "", s.engineVersion));
    FA_TRY(read_string(j, "mainScene", "", s.mainScene));
    FA_TRY(read_string(j, "feedbackFile", "", s.feedbackFile));

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
constexpr const char* kSchemaText = R"JSON({
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
          "android"
        ]
      }
    },
    "feedbackFile": {
      "type": "string",
      "description": "Project-relative path of the engine feedback log (default ENGINE_FEEDBACK.json)."
    }
  }
})JSON";
}

Json project_json_schema() {
    auto r = parse_json(kSchemaText, "project schema");
    return r.ok() ? r.value() : Json::object();
}

}  // namespace fa
