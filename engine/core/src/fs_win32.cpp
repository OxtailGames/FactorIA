// fs::temp_base on Windows (fs.cpp): the system's temporary folder, asked of the Windows API.
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <string>

#include "fs_internal.h"

namespace fa::fs::detail {

std::wstring windows_temp_path() {
    // GetTempPath2W (Windows 11; a service running as SYSTEM gets its private folder) when kernel32 has it, else
    // GetTempPathW. Both read TMP, TEMP and USERPROFILE and answer in UTF-16, which stays UTF-16 (no ANSI code page). A
    // relative TMP is made absolute by the call itself, against the working directory of that moment. Neither checks that the
    // folder exists, and the standard library's temp_directory_path does, on both STLs.
    using GetTempPathFn = DWORD(WINAPI*)(DWORD, LPWSTR);
    GetTempPathFn fn = nullptr;
    if (HMODULE k32 = ::GetModuleHandleW(L"kernel32.dll"))
        fn = reinterpret_cast<GetTempPathFn>(reinterpret_cast<void*>(::GetProcAddress(k32, "GetTempPath2W")));
    if (!fn) fn = &::GetTempPathW;
    std::wstring buf(MAX_PATH + 1, L'\0');
    DWORD n = fn(static_cast<DWORD>(buf.size()), buf.data());
    if (n >= buf.size()) {  // longer than MAX_PATH: n is the size needed, with the terminator
        buf.assign(static_cast<std::size_t>(n) + 1, L'\0');
        n = fn(static_cast<DWORD>(buf.size()), buf.data());
    }
    if (n == 0 || n >= buf.size()) return {};
    buf.resize(n);
    return buf;
}

}  // namespace fa::fs::detail
