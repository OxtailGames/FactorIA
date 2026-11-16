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

// The text of factoria.json with the value of "storage"."encryptionSecret" replaced by "(hidden)", for everything that hands
// the file to an AI client or a model (fs.read, fs.search, the MCP resource, the AI prompt): the secret is the key that seals
// the game's saves and must not end up in a model's context. Only that one value changes (formatting stays, so line numbers
// agree with the real file); text without the field comes back as it is.
std::string mask_project_secrets(std::string_view factoriaJsonText);
// True for the project-relative path of the project file (case-insensitive, as a Windows or macOS disk sees it).
bool is_project_file_path(std::string_view relPath);

void register_fs_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
