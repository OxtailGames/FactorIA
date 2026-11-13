// Thread names on Windows. SetThreadDescription exists from Windows 10 1607 on, so it is looked up at run time: on an
// older system (or Wine without it) the thread just stays unnamed.
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <string>

#include "jobs_internal.h"

namespace fa::jobs::detail {

void set_current_thread_name(const char* name) {
    using SetDescriptionFn = HRESULT(WINAPI*)(HANDLE, PCWSTR);
    static const SetDescriptionFn fn = [] {
        HMODULE kernel = GetModuleHandleW(L"kernel32.dll");
        if (!kernel) return SetDescriptionFn(nullptr);
        return reinterpret_cast<SetDescriptionFn>(
            reinterpret_cast<void*>(GetProcAddress(kernel, "SetThreadDescription")));
    }();
    if (!fn || !name) return;
    std::wstring wide;
    for (const char* c = name; *c; ++c) wide.push_back(wchar_t(static_cast<unsigned char>(*c)));  // names are ASCII
    fn(GetCurrentThread(), wide.c_str());
}

}  // namespace fa::jobs::detail
