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

// FileDispositionInfoEx (Windows 10 1607; the read-only flag 1809) and its flags: older SDK and MinGW-w64 headers lack
// some of them.
#ifndef FILE_DISPOSITION_FLAG_DO_NOT_DELETE
#define FILE_DISPOSITION_FLAG_DO_NOT_DELETE 0x00000000
#endif
#ifndef FILE_DISPOSITION_FLAG_DELETE
#define FILE_DISPOSITION_FLAG_DELETE 0x00000001
#endif
#ifndef FILE_DISPOSITION_FLAG_IGNORE_READONLY_ATTRIBUTE
#define FILE_DISPOSITION_FLAG_IGNORE_READONLY_ATTRIBUTE 0x00000010
#endif

namespace fa::fs::detail {

namespace {

// FILE_DISPOSITION_INFO_EX, declared here so that headers with it and headers without it build the same.
struct DispositionEx {
    DWORD Flags;
};
constexpr auto kFileDispositionInfoEx = static_cast<FILE_INFO_BY_HANDLE_CLASS>(21);  // FileDispositionInfoEx

bool running_under_wine() {
    static const bool wine = [] {
        const HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
        return ntdll != nullptr && GetProcAddress(ntdll, "wine_get_version") != nullptr;
    }();
    return wine;
}

// The errors of a deletion mark that something holding the file causes (not permissions: those come at the open).
bool held_code(DWORD code) {
    return code == ERROR_ACCESS_DENIED || code == ERROR_USER_MAPPED_FILE || code == ERROR_SHARING_VIOLATION;
}

}  // namespace

// What makes a delete fail on Windows. MSVC's std::filesystem::remove deletes with POSIX semantics, which goes through
// while the handles open on the file all shared delete (an unmapped fa::PackReader, a cloud sync client, `tail`): they
// are not holders here. It fails for a handle that did not share delete, a running exe or loaded library, a mapped
// file. (A replace with MoveFileExW fails for any open handle, delete shared or not: replace_file waits for those.)
Held held_open(const std::filesystem::path& file) {
    const std::wstring path = os_path(file).native();
    const DWORD attributes = GetFileAttributesW(path.c_str());
    if (attributes == INVALID_FILE_ATTRIBUTES) return Held::No;  // gone, or not ours to look at: remove_tree reports it
    if (attributes & FILE_ATTRIBUTE_DIRECTORY) return Held::No;
    const bool readOnly = (attributes & FILE_ATTRIBUTE_READONLY) != 0;

    if (running_under_wine()) {
        // Wine's server need not refuse the deletion mark below for a mapped or running file, so that probe could say
        // "not held" for a game running from the folder (the MinGW + Wine job of scripts/ci-local.sh). An exclusive open
        // conflicts with every open handle instead: stricter than Windows (a holder that shared delete counts too),
        // which only makes an export refuse where Windows would have let it through.
        const HANDLE h = CreateFileW(path.c_str(), GENERIC_READ, 0, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (h != INVALID_HANDLE_VALUE) {
            CloseHandle(h);
            return Held::No;
        }
        const DWORD code = GetLastError();
        return code == ERROR_SHARING_VIOLATION || code == ERROR_LOCK_VIOLATION ? Held::Yes : Held::No;
    }

    // Delete access, sharing everything: this conflicts only with a handle that did not allow deleting, never with
    // readers that did.
    const HANDLE h = CreateFileW(path.c_str(), DELETE, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
                                 OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) {
        const DWORD code = GetLastError();
        // ERROR_ACCESS_DENIED: permissions, not a holder.
        return code == ERROR_SHARING_VIOLATION || code == ERROR_LOCK_VIOLATION ? Held::Yes : Held::No;
    }
    // A running exe or a loaded library (an image section) and a mapped file allow the open but not the deletion: mark
    // the file for deletion, which fails for them, and take the mark back at once, before the handle closes, so the file
    // stays. For the microseconds between the two calls the file is "delete pending": a program that opens it then gets
    // ERROR_ACCESS_DENIED, as for a file being deleted (the caller is about to delete it anyway), and were this process
    // to end in between, the file would go for the same reason. The Ex mark ignores the read-only attribute (Windows 10
    // 1809 and later), so a running read-only exe is found too. Where Windows has no such mark, a read-only file is not
    // marked (the mark would fail as for a held file) and counts as not held: remove_tree drops the attribute.
    bool ex = true;
    bool marked = false;
    DWORD code = 0;
    DispositionEx markEx{FILE_DISPOSITION_FLAG_DELETE | FILE_DISPOSITION_FLAG_IGNORE_READONLY_ATTRIBUTE};
    if (SetFileInformationByHandle(h, kFileDispositionInfoEx, &markEx, sizeof(markEx))) {
        marked = true;
    } else {
        code = GetLastError();
        if (code == ERROR_INVALID_PARAMETER || code == ERROR_NOT_SUPPORTED) {  // an older Windows or file system
            ex = false;
            if (readOnly) {
                CloseHandle(h);
                return Held::No;
            }
            FILE_DISPOSITION_INFO mark{};
            mark.DeleteFile = TRUE;
            if (SetFileInformationByHandle(h, FileDispositionInfo, &mark, sizeof(mark)))
                marked = true;
            else
                code = GetLastError();
        }
    }
    if (!marked) {
        CloseHandle(h);
        return held_code(code) ? Held::Yes : Held::No;
    }
    // Take the mark back, once more if Windows refuses the first time. Should it refuse twice, closing the handle deletes
    // the file: say so (MarkLost) rather than let the caller report that nothing was deleted.
    bool unmarked = false;
    for (int attempt = 0; attempt < 2 && !unmarked; ++attempt) {
        if (ex) {
            DispositionEx keep{FILE_DISPOSITION_FLAG_DO_NOT_DELETE};
            unmarked = SetFileInformationByHandle(h, kFileDispositionInfoEx, &keep, sizeof(keep)) != FALSE;
        } else {
            FILE_DISPOSITION_INFO keep{};
            keep.DeleteFile = FALSE;
            unmarked = SetFileInformationByHandle(h, FileDispositionInfo, &keep, sizeof(keep)) != FALSE;
        }
    }
    CloseHandle(h);
    return unmarked ? Held::No : Held::MarkLost;
}

}  // namespace fa::fs::detail
