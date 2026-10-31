// Which tools the built-in agent loop offers in full and which it only lists.
//
// Offering every registry command as a tool costs about 80k tokens on every step (the definitions of all commands:
// summary, description and input schema). The loop offers instead:
//   * the CORE commands in full (reading and writing files, the docs, the scene, running and looking at the game,
//     validating and testing the project, scripts),
//   * the commands of the TOOL GROUPS the role always loads (a group is a command category: "assets", "anim", "ui"...;
//     `roles.<role>.toolGroups` in ai.json, defaults in default_tool_groups),
//   * two loop-internal tools, `tool_describe` (the full definition of any command) and `tool_call` (call any command by
//     name), and
//   * a CATALOG in the system prompt: one line per remaining command (name and summary).
// The tool list is computed once per run and does not change while the conversation goes on, so the prompt cache (tool
// definitions come first in the cached prefix) keeps working: nothing is added to the tool list when the model describes a
// command, the definition comes back as the result of `tool_describe` and stays in the conversation.
// The catalog is only used when it saves something: a registry whose non-core definitions are small is offered in full.
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/ai/types.h"
#include "fa/core/command.h"

namespace fa::ai {

inline constexpr const char* kToolDescribe = "tool_describe";
inline constexpr const char* kToolCall = "tool_call";

// A command that is always offered with its full definition (file and doc access, scene editing, running and looking at the
// game, validating and testing, scripts). `commandName` is the dotted registry name ("scene.spawn").
bool is_core_tool(std::string_view commandName);
// Every core command name (a test checks each one exists in the real registry).
std::vector<std::string> core_tool_names();
// The tool groups a role loads when ai.json does not say ("artist" -> assets, "audio" -> assets and audio, others none).
std::vector<std::string> default_tool_groups(std::string_view role);

struct ToolPlanOptions {
    bool withDelegate = false;          // agent_delegate (the orchestrator)
    bool readOnly = false;              // only is_read_only_tool commands exist for this role
    std::vector<std::string> groups;    // tool groups to load in full: command categories, or exact command names
    bool catalog = true;                // false = every command in full (no tool_describe / tool_call)
    // The catalog is used only when the definitions it leaves out add up to more than this many bytes. A project with few
    // commands (tests) gets them all in full, which is cheaper than the two extra tools.
    u64 minCatalogSavingBytes = 6000;
};

struct CatalogEntry {
    std::string command;   // "assets.slice_sheet"
    std::string toolName;  // "assets_slice_sheet": the name the provider-safe tool would have
    std::string category;
    std::string summary;   // the first line of CommandInfo::summary
    bool readOnly = false; // is_read_only_tool
};

struct ToolPlan {
    std::vector<ToolDef> tools;              // offered in full, sorted by name (byte-stable); tool_describe / tool_call included
    std::vector<CatalogEntry> catalog;       // listed only, sorted by category then name
    std::vector<std::string> loadedGroups;   // the groups that matched at least one command
    std::vector<std::string> notes;          // problems the user can fix: a group name that matches nothing, with suggestions
    bool useCatalog = false;                 // tool_describe / tool_call are in `tools` and the catalog is in the prompt
    u64 toolBytes = 0;                       // size of `tools` (estimate_context counts it the same way)
    u64 fullBytes = 0;                       // what offering every command in full would have cost
    // The "# Tools" section of the system prompt: how to use the catalog and its lines. "" when !useCatalog.
    std::string catalogText;
};

// The plan for the commands of `registry` a session may use (is_agent_tool_excluded commands left out; `readOnly` keeps
// only is_read_only_tool ones). Pure function of its inputs: calling it twice gives the same tool list.
ToolPlan plan_tools(const CommandRegistry& registry, const ToolPlanOptions& options);
// The ToolDef of one command (name provider-safe, description = summary + details, the input schema).
ToolDef tool_def_for_command(const CommandInfo& info);

// What `tool_describe` answers: the full definition of each named command (dotted or underscore name), as
//   {"commands":[{"name","tool","category","summary","description","readOnly","inputSchema"}], "unknown":[{"name","message","hint"}]}
// `readOnly`: commands a read-only role may not use are unknown to it. `ok` is false when no name matched.
Json describe_commands(const CommandRegistry& registry, const std::vector<std::string>& names, bool readOnly, bool& ok);
// The registry command a name stands for: "scene.spawn" or "scene_spawn". nullptr when none is usable by the session
// (excluded, or not read-only for a read-only role); `why` then says which of the two it is. `hint` gets the did-you-mean suggestions.
const CommandInfo* resolve_command(const CommandRegistry& registry, std::string_view name, bool readOnly, std::string& why,
                                   std::string& hint);

}  // namespace fa::ai
