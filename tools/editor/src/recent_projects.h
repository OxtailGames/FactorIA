// The editor's list of recent projects (~/.factoria/editor_recent.json) as pure functions of the file path, so
// tools/editor/tests/recent_projects_tests.cpp can run them on a temp dir. No ImGui, no engine.
//
// The file is the truth: it keeps entries whose folder is missing right now (a drive that is not mounted can come
// back), and every write re-reads it first so entries this editor never loaded (or another editor wrote) survive.
#pragma once

#include <string>
#include <vector>

namespace fa::editor {

inline constexpr std::size_t kRecentProjectsMax = 8;

// Absolute, lexically normal, no trailing slash: "/a/b/" and "/a/./b" are the same project.
std::string normalize_project_path(const std::string& path);

// Every entry of the file, normalised, de-duplicated, most recent first, capped. A missing, corrupt or non-array file
// is an empty list; entries that are not strings are skipped.
std::vector<std::string> read_recent_projects(const std::string& file);

// The entries whose folder still holds factoria.json: what the dialog and the menu show.
std::vector<std::string> existing_recent_projects(const std::vector<std::string>& list);

// Put `project` first in the file (re-reading it right before writing), cap and write. Returns the list written.
std::vector<std::string> remember_recent_project(const std::string& file, const std::string& project);

// Drop `project` from the file (re-reading it first) and write. Returns the list written.
std::vector<std::string> forget_recent_project(const std::string& file, const std::string& project);

}  // namespace fa::editor
