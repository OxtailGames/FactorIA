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
#include "fa/core/fs.h"
#include "fa/core/types.h"

namespace fa {

// Resolves a project-relative path to an absolute path inside `projectDir`.
// Fails (with a teaching hint) for absolute paths, ".." escapes and symlinks pointing outside.
Result<std::filesystem::path> resolve_project_path(const std::string& projectDir, std::string_view relPath);

// Resolves a path that the CALLER of a command gave for a file the command WRITES (an `out`, a `file`, a screenshot): through
// fs::resolve_for_write_in with the caller's own right to write anywhere (caller_capabilities() has WriteAnywhere: the
// command-line user, never MCP or an agent), so a relative path stays inside `root`, and an absolute one is accepted only
// for that user. `projectDir` is the project folder of the registration; Export and Save use the folders of fa::fs. The
// managed folders of the project (`.git`, `.factoria/` except `.factoria/tmp`) are refused unless `managed` is Allow, for a
// command that chooses such a target itself. The error is the one of resolve_for_write (code via fs::path_error_code).
Result<std::filesystem::path> resolve_write_path(const std::string& projectDir, std::string_view path,
                                                 fs::WriteRoot root = fs::WriteRoot::Project,
                                                 fs::ManagedFolders managed = fs::ManagedFolders::Refuse);

void register_fs_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
