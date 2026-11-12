// Tool groups: which commands a client that does not want every tool loads first. Shared by the built-in agent loop
// (fa/ai/tool_catalog.h: core commands in full, the rest in a catalog) and the MCP server (`factoria mcp --tools core,anim`).
//
// The CORE set is the ~50 commands nearly every task needs (files, docs, the scene, running and looking at the game,
// validating the project, scripts). A GROUP is one of: a command category ("anim", "assets"...), the exact name of a
// command ("assets.slice_sheet"), "core" (the core set) or "all" (every command).
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"

namespace fa {

// Every core command name (a test checks each one exists in the real registry).
const std::vector<std::string>& core_command_names();
bool is_core_command(std::string_view commandName);

// True when `info` belongs to `group` ("all", "core", its category, or its exact dotted name).
bool command_in_tool_group(const CommandInfo& info, std::string_view group);

// "Did you mean ...?" text for a group that matches nothing: the categories and command names of `commands` are the
// candidates ("core" and "all" too).
std::string tool_group_hint(std::string_view group, const std::vector<const CommandInfo*>& commands);

// "core,anim, physics" -> {"core","anim","physics"}: split on commas, trimmed, empty items dropped, no duplicates.
std::vector<std::string> split_tool_groups(std::string_view list);

}  // namespace fa
