// The commands an exported game's player has, and the check that the scripts of a game call only those
// (`factoria export` stops on a script that does not, `factoria validate` warns; docs/EXPORTING.md, "What is shipped and
// what is not"). Private to fa_tooling.
#pragma once

#include <map>
#include <string>
#include <vector>

namespace fa::tooling_detail {

// The names of the commands the exported player has (Engine::runtime_command_names(): the built-in commands, before plugins
// and before the extensions of developer tools), sorted. Worked out once per process, from an Engine that is only built
// (never started: no window, no graphics, no project, no files), so that the answer is the same in the CLI, the editor, the
// MCP server and a test.
const std::vector<std::string>& player_command_names();

// Whether this process has a developer-tool command named `name` that the player lacks (the commands tools/authoring added,
// the tooling's own).
bool developer_command_exists(const std::string& name);

// The JS way to do at play time what a developer-tool command does, "" when there is none. For a name the player lacks.
std::string player_alternative(const std::string& command);

// A literal `fa.call("<command>")` of a script that the exported player cannot run.
struct PlayerCommandIssue {
    std::string name;  // the command
    int line = 0;
    int column = 0;
    bool known = false;   // a command of the developer tools (authoring), not a misspelled or invented name
    std::string detail;   // what is wrong, without the position
    std::string message;  // "<file>:<line>:<column>: " + detail
    std::string hint;
};

// What a project declares that the player gets besides its built-in commands: the names of its native plugins (their commands
// are "<plugin>.<verb>") and the project.<name> commands of its tools/ (reported apart: tool_only_call_message).
struct PlayerCommandContext {
    std::vector<std::string> plugins;
    std::map<std::string, std::string> toolCommands;  // tool_commands(): <name> of "project.<name>" -> file
};

// Every literal `fa.call` of `text` (the script `file`) that names a command the player lacks. Plugin commands count as
// the player's. `fa.call(name)` with a name that is not a literal is not checked.
std::vector<PlayerCommandIssue> player_command_issues(const std::string& file, const std::string& text,
                                                      const PlayerCommandContext& context);

// The names of the native plugins factoria.json of `projectDir` declares ("plugins" keys); none when it cannot be read.
std::vector<std::string> declared_plugin_names(const std::string& projectDir);

}  // namespace fa::tooling_detail
