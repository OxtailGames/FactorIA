// Which test files `factoria test <files>` and the `project.test` command run.
#pragma once

#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa {

// Turns what a user passed into sorted, unique, project-relative test files (names ending in ".test.js"). Each argument
// is a file, a folder (every test file below it) or a glob (`*` and `?` stay inside a folder name, `**` crosses folders),
// all relative to the project root. An empty list gives every tests/**/*.test.js. An argument that is not a test file, a
// missing file or a glob without matches is an Error that says what to pass, with a "did you mean" for a near miss.
Result<std::vector<std::string>> resolve_test_files(const std::vector<std::string>& args);

// Glob match of a project-relative path: `*` and `?` do not cross '/', `**` does.
bool glob_match(const std::string& pattern, const std::string& path);

}  // namespace fa
