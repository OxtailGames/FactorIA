// Moving the unpacked example into its folder (create_example_project, fa/tooling/examples.h). Private to fa_tooling; the header exists so
// the tests can reach the pieces with a rename that fails when they say so.
#pragma once

#include <filesystem>
#include <functional>
#include <string>
#include <system_error>

#include "fa/core/process.h"
#include "fa/core/types.h"

namespace fa::examples_detail {

// One rename that never replaces: `ec` says "file exists" (is_name_taken) when `to` is there. Linux renameat2(RENAME_NOREPLACE), macOS
// renamex_np(RENAME_EXCL), Windows MoveFileExW without MOVEFILE_REPLACE_EXISTING. A file system that has none of them (an old kernel,
// NFS, a seccomp filter) gets a look at `to` and a plain rename, which leaves a window of microseconds.
void rename_no_replace(const std::filesystem::path& from, const std::filesystem::path& to, std::error_code& ec);

// `ec` is "the destination is on another file system": EXDEV, or ERROR_NOT_SAME_DEVICE (17) on Windows, which the standard library only
// maps to that condition in some implementations.
bool is_cross_device(const std::error_code& ec);
// `ec` is "something is at the destination already": EEXIST, ENOTEMPTY, ERROR_ALREADY_EXISTS (183), ERROR_FILE_EXISTS (80).
bool is_name_taken(const std::error_code& ec);

// The rename move_entry and place_project use, replaced by a test.
using RenameFn = std::function<void(const std::filesystem::path& from, const std::filesystem::path& to, std::error_code& ec)>;

// Moves one file or folder to a name that does not exist yet, never over something that is there. Across file systems a rename is
// refused: it copies and deletes then. `partial` (when given) is set to a sentence when a copy that failed could not be taken away
// again, so something of the entry is still at `to`; a failed move that left nothing leaves it empty.
void move_entry(const std::filesystem::path& from, const std::filesystem::path& to, std::error_code& ec,
                const CancelFlag* cancel, std::string* partial = nullptr, const RenameFn& rename = {});

// Puts the unpacked project (`staging`, a folder beside `dir`) at `dir` (see examples_download.cpp). A cancelled call returns the
// "was cancelled" error itself.
Result<void> place_project(const std::filesystem::path& staging, const std::filesystem::path& dir, bool dirExists,
                           const CancelFlag* cancel, const RenameFn& rename = {});

}  // namespace fa::examples_detail
