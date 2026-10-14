// The system's folder dialog: IFileOpenDialog on Windows, AppleScript's `choose folder` on macOS, zenity or kdialog on
// Linux. The external programs run without a shell (fa::ai::run_process), so paths need no quoting.
#include <filesystem>

#include "editor_internal.h"

#ifdef _WIN32
#include <windows.h>
#include <shobjidl.h>

#include "sokol_app.h"
#else
#include "fa/ai/process.h"
#endif

namespace fa::editor {

#ifdef _WIN32

std::string pick_folder(const std::string& title, const std::string& start) {
    const HRESULT init = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    std::string result;
    IFileOpenDialog* dlg = nullptr;
    if (SUCCEEDED(CoCreateInstance(CLSID_FileOpenDialog, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dlg)))) {
        DWORD opts = 0;
        dlg->GetOptions(&opts);
        dlg->SetOptions(opts | FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM | FOS_PATHMUSTEXIST);
        dlg->SetTitle(std::filesystem::path(title).wstring().c_str());
        std::error_code ec;
        IShellItem* folder = nullptr;
        if (!start.empty() && std::filesystem::is_directory(start, ec) &&
            SUCCEEDED(SHCreateItemFromParsingName(std::filesystem::absolute(start, ec).wstring().c_str(), nullptr,
                                                  IID_PPV_ARGS(&folder)))) {
            dlg->SetFolder(folder);
            folder->Release();
        }
        IShellItem* item = nullptr;
        if (SUCCEEDED(dlg->Show(static_cast<HWND>(const_cast<void*>(sapp_win32_get_hwnd())))) &&
            SUCCEEDED(dlg->GetResult(&item))) {
            PWSTR path = nullptr;
            if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &path))) {
                result = std::filesystem::path(path).string();
                CoTaskMemFree(path);
            }
            item->Release();
        }
        dlg->Release();
    }
    if (SUCCEEDED(init)) CoUninitialize();
    return result;
}

#else

std::string pick_folder(const std::string& title, const std::string& start) {
    std::string dir = start.empty() ? std::filesystem::current_path().string() : start;
    ai::ProcessOptions po;
#ifdef __APPLE__
    po.argv = {"osascript", "-e", "on run argv", "-e",
               "POSIX path of (choose folder with prompt (item 1 of argv) default location (POSIX file (item 2 of argv)))",
               "-e", "end run", title, dir};
#else
    if (!ai::which("zenity").empty())
        po.argv = {"zenity", "--file-selection", "--directory", "--title=" + title, "--filename=" + dir + "/"};
    else if (!ai::which("kdialog").empty())
        po.argv = {"kdialog", "--title", title, "--getexistingdirectory", dir};
    else
        return {};
#endif
    auto r = ai::run_process(po);
    if (!r || r->exitCode != 0) return {};
    std::string out = r->stdoutText;
    while (!out.empty() && (out.back() == '\n' || out.back() == '\r')) out.pop_back();
    if (out.size() > 1 && out.back() == '/') out.pop_back();  // osascript ends folders with '/'
    return out;
}

#endif

}  // namespace fa::editor
