// The arguments of the DAP `launch` request.
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <optional>

#include "fa/core/strings.h"
#include "fa/dap/server.h"
#include "fa/runtime/project.h"

namespace fa {

namespace fsys = std::filesystem;

namespace {

const std::vector<std::string>& launch_keys() {
    static const std::vector<std::string> keys = {"mode",  "project", "scene",       "frames",  "input",
                                                  "tests", "filter",  "stopOnEntry", "noDebug", "factoriaPath"};
    return keys;
}

// Keys VS Code (and other clients) add to every launch configuration. They mean nothing to the server, but a launch
// that fails on them would never start from VS Code.
bool is_ignored_key(const std::string& key) {
    static const std::vector<std::string> ignored = {
        "type",           "request",       "name",           "presentation",   "preLaunchTask",
        "postDebugTask",  "internalConsoleOptions", "debugServer", "suppressMultipleSessionWarning",
        "console",        "serverReadyAction", "restart",    "windows",        "osx",
        "linux",          "trace",         "env",            "cwd"};
    if (key.rfind("__", 0) == 0) return true;  // __sessionId, __configurationTarget, __restart...
    for (const std::string& k : ignored)
        if (k == key) return true;
    return false;
}

Error bad_value(const std::string& key, const std::string& expected, const Json& got, const std::string& example) {
    return Error{"launch attribute '" + key + "' must be " + expected + ", got " + describe_json_value(got) + ".",
                 "Example: \"" + key + "\": " + example};
}

}  // namespace

Result<DapLaunchArgs> parse_dap_launch(const Json& argumentsIn, const std::string& cwd) {
    Json arguments = argumentsIn.is_null() ? Json::object() : argumentsIn;
    if (!arguments.is_object())
        return Error{"the launch request needs an 'arguments' object like {\"mode\": \"headless\", \"project\": \"/path/to/game\"}.",
                     "In VS Code these come from the configuration in .vscode/launch.json."};
    DapLaunchArgs out;
    for (auto it = arguments.begin(); it != arguments.end(); ++it) {
        const std::string& key = it.key();
        const auto& known = launch_keys();
        if (std::find(known.begin(), known.end(), key) != known.end() || is_ignored_key(key)) continue;
        return Error{"unknown launch attribute '" + key + "'.",
                     did_you_mean(key, known) + " Attributes VS Code adds itself (type, request, name, presentation, preLaunchTask, "
                     "postDebugTask, internalConsoleOptions, debugServer, __*...) are accepted and ignored."};
    }
    auto has = [&](const char* k) { return arguments.contains(k) && !arguments[k].is_null(); };
    auto string_of = [&](const char* k, std::string& dst) -> std::optional<Error> {
        if (!has(k)) return std::nullopt;
        if (!arguments[k].is_string()) return bad_value(k, "text", arguments[k], std::string(k) == "project" ? "\"${workspaceFolder}\"" : "\"value\"");
        dst = arguments[k].get<std::string>();
        return std::nullopt;
    };
    auto bool_of = [&](const char* k, bool& dst) -> std::optional<Error> {
        if (!has(k)) return std::nullopt;
        if (!arguments[k].is_boolean()) return bad_value(k, "true or false", arguments[k], "true");
        dst = arguments[k].get<bool>();
        return std::nullopt;
    };

    std::string project, input;
    for (auto err : {string_of("mode", out.mode), string_of("project", project), string_of("scene", out.scene),
                     string_of("input", input), string_of("filter", out.filter), bool_of("stopOnEntry", out.stopOnEntry),
                     bool_of("noDebug", out.noDebug)})
        if (err) return *err;

    static const std::vector<std::string> modes = {"play", "headless", "test"};
    if (has("mode") && std::find(modes.begin(), modes.end(), out.mode) == modes.end())
        return Error{"launch attribute 'mode' is '" + out.mode + "', which is not a way to run the game.",
                     did_you_mean(out.mode, modes) + " play opens the game window, headless runs frames without a window, test runs tests/*.test.js."};

    if (has("frames")) {
        const Json& f = arguments["frames"];
        if (!f.is_number() || f.get<double>() != std::floor(f.get<double>()) || f.get<double>() < 0 || f.get<double>() > 100000000.0)
            return bad_value("frames", "a whole number of frames, 0 or more", f, "600");
        out.frames = static_cast<int>(f.get<double>());
    }
    if (has("tests")) {
        const Json& t = arguments["tests"];
        if (!t.is_array()) return bad_value("tests", "a list of test files", t, "[\"tests/player.test.js\"]");
        for (const Json& e : t) {
            if (!e.is_string()) return bad_value("tests", "a list of text entries", e, "[\"tests/player.test.js\"]");
            if (!e.get<std::string>().empty()) out.tests.push_back(e.get<std::string>());
        }
    }

    // Keys that only make sense in some modes: an ignored setting is a silent mistake, so refuse it.
    struct ModeKey {
        const char* key;
        const char* mode;
        const char* other;
    };
    for (const ModeKey& mk : {ModeKey{"frames", "headless", "play or test"}, ModeKey{"input", "headless", "play or test"},
                              ModeKey{"tests", "test", "play or headless"}, ModeKey{"filter", "test", "play or headless"}}) {
        if (has(mk.key) && out.mode != mk.mode)
            return Error{std::string("launch attribute '") + mk.key + "' only applies to mode \"" + mk.mode + "\", and this launch is \"" + out.mode + "\".",
                         std::string("Remove '") + mk.key + "' or set \"mode\": \"" + mk.mode + "\"."};
    }
    if (has("scene") && out.mode == "test")
        return Error{"launch attribute 'scene' does not apply to mode \"test\" (the tests load their own scenes).",
                     "Remove 'scene' or use mode \"play\" or \"headless\"."};

    // The project: the given folder, else the nearest one with factoria.json above the working directory.
    std::error_code ec;
    if (project.empty()) {
        project = find_project_root(cwd);
        if (project.empty())
            return Error{"no project to debug: 'project' is not set and there is no " + std::string(kProjectFileName) + " in '" + cwd +
                             "' or any folder above it.",
                         "Set \"project\": \"${workspaceFolder}\" in the launch configuration (the folder that contains " +
                             std::string(kProjectFileName) + ")."};
    }
    fsys::path p = fsys::absolute(fsys::path(project), ec);
    p = p.lexically_normal();
    std::string dir = p.string();
    while (dir.size() > 1 && (dir.back() == '/' || dir.back() == '\\')) dir.pop_back();
    if (!fsys::exists(fsys::path(dir) / kProjectFileName, ec))
        return Error{"'" + dir + "' is not a FactorIA project: " + kProjectFileName + " not found there.",
                     fsys::is_directory(dir, ec) ? "Set \"project\" to the folder that contains " + std::string(kProjectFileName) +
                                                       ", or create a project with 'factoria new'."
                                                 : "The folder does not exist. Check \"project\" in the launch configuration."};
    out.projectDir = dir;

    if (!input.empty()) {
        const fsys::path given(input);
        std::vector<fsys::path> tried;
        if (given.is_absolute()) {
            tried.push_back(given);
        } else {
            tried.push_back((fsys::path(dir) / given).lexically_normal());
            fsys::path inCwd = (fsys::path(cwd) / given).lexically_normal();
            if (inCwd != tried[0]) tried.push_back(inCwd);
        }
        for (const fsys::path& c : tried)
            if (fsys::is_regular_file(c, ec)) {
                out.inputPath = c.string();
                break;
            }
        if (out.inputPath.empty()) {
            std::string msg = "cannot find the input replay '" + input + "'. Looked in:";
            for (const fsys::path& c : tried) msg += "\n  - " + c.generic_string();
            return Error{msg, "'input' is an input replay file (the input.json that play.report points to). A relative path is looked up in the project folder, then in the working directory."};
        }
    }
    return out;
}

}  // namespace fa
