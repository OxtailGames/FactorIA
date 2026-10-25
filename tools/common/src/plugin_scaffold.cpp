// project.new_plugin: a native plugin to start from (docs/EXTENDING.md, "Native plugins"), from the template
// platforms/plugin/ plus fa_plugin.h, declared in factoria.json.
#include <algorithm>
#include <filesystem>

#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/runtime/plugins.h"
#include "fa/runtime/project.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/json_patch.h"
#include "fa/tooling/tooling.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

// The templates project.new_plugin can start from: "basic" (platforms/plugin/) and one per folder of platforms/plugins/
// (a store backend: "steam", "apple"). Folders are found in the bundled files, so a new one needs no code.
std::vector<std::string> plugin_templates() {
    std::vector<std::string> names = {"basic"};
    const std::string prefix = "platforms/plugins/";
    for (const std::string& path : bundled_list(prefix)) {
        const std::string name = path.substr(prefix.size(), path.find('/', prefix.size()) - prefix.size());
        if (!name.empty() && std::find(names.begin(), names.end(), name) == names.end()) names.push_back(name);
    }
    return names;
}

}  // namespace

void register_plugin_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.new_plugin";
    info.category = "project";
    info.readOnly = false;
    info.summary = "Create a native plugin (C/C++) for this game and declare it in factoria.json.";
    info.description =
        "Writes a plugin folder (default plugins/<name>, or `path`: project-relative, absolute, or with ${VARIABLE} parts "
        "for a private folder outside the repository) holding src/plugin.c, include/fa_plugin.h (the whole C API), "
        "CMakeLists.txt, README.md and android/ (the Gradle module of its Android build), and adds "
        "\"plugins\": {\"<name>\": {\"path\", \"platforms\", \"optional\"}} to factoria.json "
        "(`platforms` defaults to this computer's; `optional` to true: the game runs, and exports with allowMissingPlugins, without the build). The plugin adds the script function plugins.<name>.add(a, b) and "
        "the command <name>.info: build it with CMake (nextSteps), then `factoria run` loads it. `template` (default "
        "\"basic\") picks another starting point: a platform backend for a store (the folders of platforms/plugins/ in the "
        "engine; docs/PLATFORM.md, \"Writing a backend\"). The name: lower-case "
        "letters, digits and underscores, not an engine area (scene, game, ...). Fails when factoria.json already "
        "declares the plugin or the folder is not empty. Only that key of factoria.json changes: the other keys, their order and the layout stay as they are. "
        "With `dryRun` true nothing is written: the result lists the `files` and the `keys` of factoria.json it would write. An argument "
        "that does not exist is an error with a \"did you mean\". Returns {folder, files[], keys[], plugin, nextSteps[], dryRun?}. Details: docs_read "
        "{\"name\":\"extending\"} (section G). Example: {\"name\": \"example\"}.";
    info.inputSchema = Json::parse(R"({
      "type":"object","required":["name"],"additionalProperties":false,
      "properties":{
        "name":{"type":"string","description":"The plugin's name: scripts call plugins.<name>.<function>() and its commands are <name>.<verb>."},
        "template":{"type":"string","default":"basic","description":"What to start from: \"basic\" (an example command and function) or a store backend template shipped with the engine (the folders of platforms/plugins/: they answer the game's platform.* calls, docs/PLATFORM.md). An unknown name lists the available ones."},
        "path":{"type":"string","description":"Its folder (default plugins/<name>): project-relative, absolute, or with ${VARIABLE} parts."},
        "platforms":{"type":"array","items":{"type":"string","enum":["windows","macos","linux","ios","android"]},
                     "description":"The platforms it will be built for (default: this computer's)."},
        "optional":{"type":"boolean","default":true,"description":"Written as \"optional\" in factoria.json: true = the game runs without the plugin (a missing build is a validate warning, not an error). Pass false when the game cannot work without it."},
        "dryRun":{"type":"boolean","default":false,"description":"true = write nothing: list the files and the factoria.json keys it would write."}
      }})");
    registry.add(info, [projectDir](const Json& a) {
        const std::string name = a.at("name").get<std::string>();
        const std::string templateName = a.value("template", std::string("basic"));
        const std::vector<std::string> templates = plugin_templates();
        if (std::find(templates.begin(), templates.end(), templateName) == templates.end())
            throw CommandError("invalid_argument", "unknown plugin template '" + templateName + "'",
                               did_you_mean(templateName, templates) + " Templates: " + join(templates, ", ") +
                                   ". \"basic\" is the plain example; the others are store backends.");
        const stdfs::path projectFile = stdfs::path(projectDir) / kProjectFileName;
        const auto original = tooling_detail::read_file(projectFile);
        if (!original) throw CommandError("not_found", "no factoria.json in " + projectDir, "Run it from a game's folder.");
        auto parsed = parse_json(*original, kProjectFileName);
        if (!parsed.ok() || !parsed->is_object())
            throw CommandError("invalid_argument", "factoria.json is not a JSON object", "Fix it first: `factoria validate`.");
        const Json& project = parsed.value();
        if (project.contains("plugins") && project["plugins"].is_object() && project["plugins"].contains(name))
            throw CommandError("invalid_argument", "factoria.json#/plugins/" + name + " is already declared",
                               "Choose another name, or remove the declaration first.");
        const bool dryRun = a.value("dryRun", false);

        // The declaration, patched into the text of factoria.json (only plugins.<name> changes; the other keys, their order and
        // the layout stay as they are). Nothing is written yet: load_project checks the name and the platforms on a copy.
        Json entry = Json::object({{"path", a.value("path", "plugins/" + name)}});
        entry["platforms"] = a.contains("platforms") ? a["platforms"] : Json::array({runtime_platform()});
        if (a.value("optional", true)) entry["optional"] = true;
        auto patched = patch_json_text(*original, {{{"plugins", name}, entry}}, kProjectFileName);
        if (!patched.ok()) throw CommandError("invalid_argument", patched.error().message, patched.error().hint);
        const std::string scratch = fs::make_temp_dir("fa_new_plugin").generic_string();
        const bool scratchOk = tooling_detail::write_file(stdfs::path(scratch) / kProjectFileName, patched.value());
        auto settings = scratchOk ? load_project(scratch) : Result<ProjectSettings>(Error{"cannot write a scratch copy of factoria.json", ""});
        std::error_code rmEc;
        stdfs::remove_all(scratch, rmEc);
        if (!settings.ok()) throw CommandError("invalid_argument", settings.error().message, settings.error().hint);
        const PluginSettings* plugin = nullptr;
        for (const PluginSettings& p : settings->plugins)
            if (p.name == name) plugin = &p;
        auto folder = plugin_folder(projectDir, *plugin);
        std::error_code ec;
        if (!folder.ok()) throw CommandError("invalid_argument", folder.error().message, folder.error().hint);
        if (stdfs::exists(folder.value(), ec) && !stdfs::is_empty(folder.value(), ec))
            throw CommandError("invalid_argument", folder.value() + " is not empty", "Pass another `path`, or empty that folder.");

        // The files: the template with {{NAME}} replaced (in paths too), and the API header.
        Json files = Json::array();
        auto write = [&](const std::string& rel, const std::string& text) {
            if (!dryRun) {
                std::string err;
                if (!tooling_detail::write_file(stdfs::path(folder.value()) / rel, text, &err)) throw CommandError("failed", err);
            }
            files.push_back(rel);
        };
        auto bundled = [&](const std::string& path) {
            auto text = bundled_read(path);
            if (!text)
                throw CommandError("failed", path + " is missing from this build of factoria", "This is an engine bug; report it.");
            return *text;
        };
        const std::string prefix = templateName == "basic" ? "platforms/plugin/" : "platforms/plugins/" + templateName + "/";
        for (const std::string& path : bundled_list(prefix)) {
            const std::string rel = path.substr(prefix.size());
            if (rel.rfind("tests/", 0) == 0) continue;  // a template's tests (its mock SDK) belong to the engine's CI, not to a game
            write(replace_all(rel, "{{NAME}}", name), replace_all(bundled(path), "{{NAME}}", name));
        }
        write("include/fa_plugin.h", bundled("engine/runtime/include/fa/runtime/fa_plugin.h"));
        if (!dryRun) {
            std::string err;
            if (!tooling_detail::write_file(projectFile, patched.value(), &err)) throw CommandError("failed", err);
        }

        const std::string f = folder.value();
        const std::string build = "Build it: cmake -S \"" + f + "\" -B \"" + f + "/build\" -DCMAKE_BUILD_TYPE=Release && cmake --build \"" +
                                  f + "/build\" --config Release (it copies the library into " + f + "/" + runtime_platform() + "/)";
        Json nextSteps = Json::array({build});
        if (templateName == "basic") {
            nextSteps.push_back("Run the game: `factoria run` loads it; scripts call plugins." + name + ".add(1, 2), and `factoria call " +
                                name + ".info` runs its command");
            nextSteps.push_back("Edit src/plugin.c: include/fa_plugin.h documents the API (docs/EXTENDING.md, \"Native plugins\")");
        } else {
            nextSteps.push_back("Read " + f + "/README.md: this plugin is a platform backend, so `factoria run` makes the game's platform.* calls "
                                "go to the store (docs/PLATFORM.md). `factoria call platform.add_backend` does this whole setup, SDK files "
                                "included, in one step.");
        }
        Json out = Json::object({{"folder", f}, {"files", files}, {"plugin", entry}, {"nextSteps", nextSteps}});
        out["keys"] = Json::array({std::string(kProjectFileName) + "#/plugins/" + name});
        if (dryRun) out["dryRun"] = true;
        return out;
    });
}

}  // namespace fa
