// Sandboxed file commands for agents that have no file tools of their own
// (the built-in AI agent, API-only models). Everything is project-relative;
// absolute paths, "..", and symlinks leading outside the project are rejected.
//
// Commands: fs.list, fs.read, fs.write, fs.edit, fs.search, fs.delete.
#pragma once

#include <filesystem>
#include <string>
#include <string_view>

#include "fa/core/command.h"
#include "fa/core/types.h"

namespace fa {

// Resolves a project-relative path to an absolute path inside `projectDir`.
// Fails (with a teaching hint) for absolute paths, ".." escapes and symlinks pointing outside.
Result<std::filesystem::path> resolve_project_path(const std::string& projectDir, std::string_view relPath);

void register_fs_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
