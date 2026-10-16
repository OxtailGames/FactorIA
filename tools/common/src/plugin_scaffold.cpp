// project.new_plugin: a native plugin to start from (docs/EXTENDING.md, "Native plugins"), from the template
// platforms/plugin/ plus fa_plugin.h, declared in factoria.json.
#include <filesystem>

#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/runtime/plugins.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/tooling.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

void register_plugin_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.new_plugin";
    info.category = "project";
    info.readOnly = false;
    info.summary = "Create a native plugin (C/C++) for this game and declare it in factoria.json.";
    info.description =
        "Writes a plugin folder (default plugins/<name>, or `path`: project-relative, absolute, or with ${VARIABLE} parts "
        "for a private folder outside the repository) holding src/plugin.c, include/fa_plugin.h (the whole C API), "
        "CMakeLists.txt and README.md, and adds \"plugins\": {\"<name>\": {\"path\", \"platforms\"}} to factoria.json "
        "(`platforms` defaults to this computer's). The plugin adds the script function plugins.<name>.add(a, b) and "
        "the command <name>.info: build it with CMake (nextSteps), then `factoria run` loads it. The name: lower-case "
        "letters, digits and underscores, not an engine area (scene, game, ...). Fails when factoria.json already "
        "declares the plugin or the folder is not empty. Returns {folder, files[], plugin, nextSteps[]}. Details: docs_read "
        "{\"name\":\"extending\"} (section G). Example: {\"name\": \"example\"}.";
    info.inputSchema = Json::parse(R"({
      "type":"object","required":["name"],
      "properties":{
        "name":{"type":"string","description":"The plugin's name: scripts call plugins.<name>.<function>() and its commands are <name>.<verb>."},
        "path":{"type":"string","description":"Its folder (default plugins/<name>): project-relative, absolute, or with ${VARIABLE} parts."},
        "platforms":{"type":"array","items":{"type":"string","enum":["windows","macos","linux","ios","android"]},
                     "description":"The platforms it will be built for (default: this computer's)."}
      }})");
    registry.add(info, [projectDir](const Json& a) {
        const std::string name = a.at("name").get<std::string>();
        const stdfs::path projectFile = stdfs::path(projectDir) / kProjectFileName;
        const auto original = tooling_detail::read_file(projectFile);
        if (!original) throw CommandError("not_found", "no factoria.json in " + projectDir, "Run it from a game's folder.");
        auto parsed = parse_json(*original, kProjectFileName);
        if (!parsed.ok() || !parsed->is_object())
            throw CommandError("invalid_argument", "factoria.json is not a JSON object", "Fix it first: `factoria validate`.");
        Json project = parsed.value();
        if (project.contains("plugins") && project["plugins"].is_object() && project["plugins"].contains(name))
            throw CommandError("invalid_argument", "factoria.json#/plugins/" + name + " is already declared",
                               "Choose another name, or remove the declaration first.");

        // The declaration first: load_project checks the name (and the platforms) with its teaching errors.
        Json entry = Json::object({{"path", a.value("path", "plugins/" + name)}});
        entry["platforms"] = a.contains("platforms") ? a["platforms"] : Json::array({runtime_platform()});
        project["plugins"][name] = entry;
        if (!tooling_detail::write_file(projectFile, dump_json(project)))
            throw CommandError("failed", "cannot write " + projectFile.generic_string());
        auto settings = load_project(projectDir);
        auto restore = [&] { tooling_detail::write_file(projectFile, *original); };
        if (!settings.ok()) {
            restore();
            throw CommandError("invalid_argument", settings.error().message, settings.error().hint);
        }
        const PluginSettings* plugin = nullptr;
        for (const PluginSettings& p : settings->plugins)
            if (p.name == name) plugin = &p;
        auto folder = plugin_folder(projectDir, *plugin);
        std::error_code ec;
        if (!folder.ok() || (stdfs::exists(folder.value(), ec) && !stdfs::is_empty(folder.value(), ec))) {
            restore();
            if (!folder.ok()) throw CommandError("invalid_argument", folder.error().message, folder.error().hint);
            throw CommandError("invalid_argument", folder.value() + " is not empty", "Pass another `path`, or empty that folder.");
        }

        // The files: the template with {{NAME}} replaced (in paths too), and the API header.
        Json files = Json::array();
        auto write = [&](const std::string& rel, const std::string& text) {
            std::string err;
            if (!tooling_detail::write_file(stdfs::path(folder.value()) / rel, text, &err)) {
                restore();
                throw CommandError("failed", err);
            }
            files.push_back(rel);
        };
        auto bundled = [&](const std::string& path) {
            auto text = bundled_read(path);
            if (!text) {
                restore();
                throw CommandError("failed", path + " is missing from this build of factoria", "This is an engine bug; report it.");
            }
            return *text;
        };
        const std::string prefix = "platforms/plugin/";
        for (const std::string& path : bundled_list(prefix))
            write(replace_all(path.substr(prefix.size()), "{{NAME}}", name), replace_all(bundled(path), "{{NAME}}", name));
        write("include/fa_plugin.h", bundled("engine/runtime/include/fa/runtime/fa_plugin.h"));

        const std::string f = folder.value();
        return Json::object(
            {{"folder", f},
             {"files", files},
             {"plugin", entry},
             {"nextSteps", Json::array({"Build it: cmake -S \"" + f + "\" -B \"" + f + "/build\" -DCMAKE_BUILD_TYPE=Release && cmake --build \"" +
                                            f + "/build\" --config Release (it copies the library into " + f + "/" +
                                            runtime_platform() + "/)",
                                        "Run the game: `factoria run` loads it; scripts call plugins." + name +
                                            ".add(1, 2), and `factoria call " + name + ".info` runs its command",
                                        "Edit src/plugin.c: include/fa_plugin.h documents the API (docs/EXTENDING.md, \"Native plugins\")"})}});
    });
}

}  // namespace fa
