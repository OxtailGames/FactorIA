// fs::file_in_use on Windows (fs.cpp): would a delete of the file fail because something holds it?
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0A00  // SetFileInformationByHandle (Vista and later); MSVC and current MinGW-w64 default to this
#endif
#include <windows.h>

#include <string>

#include "fa/core/fs.h"
#include "fs_internal.h"

namespace fa::fs::detail {

bool held_open(const std::filesystem::path& file) {
    const std::wstring path = os_path(file).native();
    const DWORD attributes = GetFileAttributesW(path.c_str());
    if (attributes == INVALID_FILE_ATTRIBUTES) return false;  // gone, or not ours to look at: remove_tree reports it
    // Marking a read-only file for deletion fails like a held one does: remove_tree drops the attribute, so it is not held.
    if (attributes & (FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_DIRECTORY)) return false;
    // Delete access, sharing everything: this conflicts only with a handle that did not allow deleting (what makes a
    // delete or a replace fail), never with readers that did (a cloud sync client, `tail`, a virus scanner).
    const HANDLE h = CreateFileW(path.c_str(), DELETE, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
                                 OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) {
        const DWORD code = GetLastError();
        return code == ERROR_SHARING_VIOLATION || code == ERROR_LOCK_VIOLATION;  // ERROR_ACCESS_DENIED: permissions, not a holder
    }
    // A running exe or a loaded library (an image section) and a mapped file allow the open but not the deletion: mark
    // the file for deletion, which fails for them, and take the mark back at once, before the handle closes, so the file
    // stays. (Were this process to end between the two calls, the file would go: the caller is about to delete it.)
    FILE_DISPOSITION_INFO mark{};
    mark.DeleteFile = TRUE;
    bool held = false;
    if (SetFileInformationByHandle(h, FileDispositionInfo, &mark, sizeof(mark))) {
        mark.DeleteFile = FALSE;
        SetFileInformationByHandle(h, FileDispositionInfo, &mark, sizeof(mark));
    } else {
        const DWORD code = GetLastError();
        held = code == ERROR_ACCESS_DENIED || code == ERROR_USER_MAPPED_FILE || code == ERROR_SHARING_VIOLATION;
    }
    CloseHandle(h);
    return held;
}

}  // namespace fa::fs::detail
