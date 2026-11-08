// fs::find_file_in_use on Windows (fs.cpp): an open that shares nothing tells whether another handle holds the file.
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include "fa/core/fs.h"
#include "fs_internal.h"

namespace fa::fs::detail {

bool held_open(const std::filesystem::path& file) {
    // Share mode 0 conflicts with every handle that reads, writes or deletes the file, and with a mapping of it (the
    // section keeps its file object open after the program closed the handle): exactly what stops a delete or a replace.
    const HANDLE h = CreateFileW(os_path(file).c_str(), GENERIC_READ, 0, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) {
        const DWORD code = GetLastError();
        return code == ERROR_SHARING_VIOLATION || code == ERROR_LOCK_VIOLATION;
    }
    CloseHandle(h);
    return false;
}

}  // namespace fa::fs::detail
