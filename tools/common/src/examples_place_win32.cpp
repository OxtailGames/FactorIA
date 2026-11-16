// The no-replace rename of an unpacked example, Windows (examples_place.h). The POSIX one is examples_place_posix.cpp.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#include "examples_place.h"

namespace fa::examples_detail {

// MoveFileExW without MOVEFILE_REPLACE_EXISTING says ERROR_ALREADY_EXISTS (183) or ERROR_FILE_EXISTS (80) when `to` is there, and
// ERROR_SHARING_VIOLATION (32) while somebody holds a file inside `from` (rename_waiting retries that one). Without
// MOVEFILE_COPY_ALLOWED a move to another volume is ERROR_NOT_SAME_DEVICE (17): move_entry copies then. This is the real Windows
// answer, so the emulation of fs (fs::windows_rules, which only knows files opened through fs::ReadStream) is not consulted.
void rename_no_replace(const std::filesystem::path& from, const std::filesystem::path& to, std::error_code& ec) {
    ec.clear();
    if (!MoveFileExW(from.c_str(), to.c_str(), 0)) ec.assign(int(GetLastError()), std::system_category());
}

}  // namespace fa::examples_detail
