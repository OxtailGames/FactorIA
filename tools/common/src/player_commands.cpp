#include "player_commands.h"

#include <algorithm>
#include <mutex>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/runtime/command_extension.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/internal/engine_impl.h"
#include "fa/tooling/tooling.h"
#include "js_scan.h"
#include "util.h"

namespace fa::tooling_detail {

namespace {

std::vector<std::string> names_of(Engine& engine) {
    std::vector<std::string> out;
    for (const CommandInfo* info : engine.commands().list()) out.push_back(info->name);
    std::sort(out.begin(), out.end());
    return out;
}

struct Sets {
    std::vector<std::string> runtime;
    std::set<std::string> developer;                        // what this process has besides `runtime`
    std::size_t extensions = static_cast<std::size_t>(-1);  // how many command extensions `developer` was made with
};

std::mutex g_mutex;
Sets g_sets;

// Caller holds g_mutex. An Engine that was built and not started has an empty registry; registering the built-in commands in
// it is what Engine::init does first (engine.cpp notes the names right after), and the handlers capture the engine's state
// without running. A test checks that this list is the one an initialized Engine reports as Engine::runtime_command_names().
void refresh() {
    const std::size_t extensions = command_extension_names().size();
    if (!g_sets.runtime.empty() && g_sets.extensions == extensions) return;
    Engine engine;
    register_builtin_commands(engine, engine.runtime_impl());
    std::vector<std::string> runtime = names_of(engine);
    if (g_sets.runtime.empty()) g_sets.runtime = std::move(runtime);  // made once: callers keep references to it
    run_command_extensions(engine);
    register_project_commands(engine, "-");  // the tooling's own: project.validate, project.export, docs.*, fs.* ...
    g_sets.developer.clear();
    for (const std::string& name : names_of(engine))
        if (!std::binary_search(g_sets.runtime.begin(), g_sets.runtime.end(), name)) g_sets.developer.insert(name);
    g_sets.extensions = extensions;
}

bool starts_with(const std::string& s, const std::string& prefix) { return s.rfind(prefix, 0) == 0; }

}  // namespace

const std::vector<std::string>& player_command_names() {
    const std::lock_guard<std::mutex> lock(g_mutex);
    if (g_sets.runtime.empty()) refresh();
    return g_sets.runtime;
}

bool developer_command_exists(const std::string& name) {
    const std::lock_guard<std::mutex> lock(g_mutex);
    refresh();
    return g_sets.developer.count(name) > 0;
}

std::string player_alternative(const std::string& command) {
    if (starts_with(command, "mesh."))
        return "In a script, build meshes with the `mesh` API of \"factoria\" (import { mesh } from \"factoria\"; "
               "mesh.create, mesh.update, mesh.destroy, mesh.save): it runs in the player.";
    if (starts_with(command, "anim."))
        return "Author the clips (anim.*) with the editor, `factoria call` or MCP before you export: the *.anim.json "
               "files ship as assets. At play time the entity's Animator plays them (entity.animator.play(\"Clip\")).";
    if (command == "scene.import_ascii")
        return "Use scene.place_ascii at play time: it builds the same level in the running world and writes no file "
               "(tilemap.generate with `place` uses it). Save a scene with scene.import_ascii before you export.";
    if (command == "prefab.save" || command == "scene.format")
        return "Nothing replaces " + command +
               " at play time: it writes project files, which a shipped game does not do. Run it with `factoria "
               "call`, the editor or MCP while you work on the game, before you export.";
    return {};
}

std::vector<PlayerCommandIssue> player_command_issues(const std::string& file, const std::string& text,
                                                      const PlayerCommandContext& context) {
    std::vector<PlayerCommandIssue> out;
    const std::vector<LiteralCall> calls = literal_calls(text);
    if (calls.empty()) return out;
    const std::vector<std::string>& runtime = player_command_names();
    for (const LiteralCall& call : calls) {
        if (std::binary_search(runtime.begin(), runtime.end(), call.name)) continue;
        bool plugin = false;
        for (const std::string& name : context.plugins) plugin = plugin || starts_with(call.name, name + ".");
        if (plugin) continue;
        if (starts_with(call.name, "project.") && context.toolCommands.count(call.name.substr(8)) > 0)
            continue;  // a tool's command: tool_only_call_message says it
        PlayerCommandIssue issue;
        issue.name = call.name;
        issue.line = call.line;
        issue.column = call.column;
        issue.known = developer_command_exists(call.name);
        if (issue.known) {
            issue.detail = "fa.call(\"" + call.name +
                           "\") calls a command that is for the editor, the CLI and MCP (authoring); the exported "
                           "player does not have it, so in the shipped game this call fails";
            issue.hint = player_alternative(call.name);
            if (issue.hint.empty())
                issue.hint = "Do the work before you export (run the command with `factoria call`, the editor or "
                             "MCP), or look in docs/SCRIPTING.md for what a game can do at play time.";
        } else {
            issue.detail = "fa.call(\"" + call.name +
                           "\"): the exported player has no command with this name, so in the shipped game this call "
                           "fails";
            issue.hint = did_you_mean(call.name, runtime, 8);
            if (std::string alt = player_alternative(call.name); !alt.empty()) issue.hint = alt + " " + issue.hint;
            issue.hint += " (`factoria call docs.commands` lists the commands.)";
        }
        issue.message = file + ":" + std::to_string(call.line) + ":" + std::to_string(call.column) + ": " + issue.detail;
        out.push_back(std::move(issue));
    }
    return out;
}

std::vector<std::string> declared_plugin_names(const std::string& projectDir) {
    std::vector<std::string> out;
    const auto text = read_file(fs::path_from_utf8(projectDir) / "factoria.json");
    if (!text) return out;
    const Json j = parse_json_lenient(*text);
    if (!j.is_object()) return out;
    const auto it = j.find("plugins");
    if (it == j.end() || !it->is_object()) return out;
    for (const auto& item : it->items()) out.push_back(item.key());
    return out;
}

}  // namespace fa::tooling_detail
