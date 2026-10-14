// FactorIA-Editor.exe (Windows): a window-subsystem launcher that runs `factoria.exe editor` from its own folder with
// no console window, so it opens like any other program. Its arguments are passed on: a project folder dropped on it
// is opened.
#include <windows.h>

#include <string>

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR args, int) {
    wchar_t self[MAX_PATH * 4];
    std::wstring exe(self, GetModuleFileNameW(nullptr, self, MAX_PATH * 4));
    exe = exe.substr(0, exe.find_last_of(L"\\/") + 1) + L"factoria.exe";
    std::wstring cmd = L"\"" + exe + L"\" editor " + args;
    STARTUPINFOW si{};
    si.cb = sizeof si;
    PROCESS_INFORMATION pi{};
    if (!CreateProcessW(exe.c_str(), cmd.data(), nullptr, nullptr, FALSE, CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi)) {
        std::wstring msg = L"Cannot start " + exe + L" (error " + std::to_wstring(GetLastError()) +
                           L").\n\nFactorIA-Editor.exe must be in the same folder as factoria.exe.";
        MessageBoxW(nullptr, msg.c_str(), L"FactorIA", MB_ICONERROR);
        return 1;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 0;
}
