// The system's file and folder dialogs: IFileOpenDialog on Windows, AppleScript's `choose folder` / `choose file` on macOS,
// zenity or kdialog on Linux. The external programs run without a shell (fa::ai::run_process), so paths need no quoting.
// Also reads a picture from the system clipboard (the AI Assistant's Ctrl+V), and maximize_window: sokol_app has no
// "start maximized" option.
#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>

#include "editor_internal.h"

#ifdef _WIN32
#include <windows.h>
#include <shobjidl.h>

#include "sokol_app.h"
#else
#include "fa/ai/process.h"
#endif

namespace fa::editor {

namespace {

// What a dialog asks for: a folder, or one existing file of the given kinds ("Images", {"png", "jpg"}).
struct PickSpec {
    std::string title, start;
    bool folder = true;
    std::string filterName;
    std::vector<std::string> extensions;  // without the dot, lower case
};

// "*.png;*.PNG;*.jpg;*.JPG" with the separator the platform's dialog wants (also the upper-case spelling: Linux globs care).
std::string glob_list(const std::vector<std::string>& extensions, const char* separator) {
    std::string out;
    for (const std::string& e : extensions) {
        std::string up = e;
        std::transform(up.begin(), up.end(), up.begin(), [](unsigned char c) { return static_cast<char>(std::toupper(c)); });
        for (const std::string& x : {e, up}) {
            if (!out.empty()) out += separator;
            out += "*." + x;
            if (up == e) break;
        }
    }
    return out;
}

#ifdef _WIN32

std::string pick_path(const PickSpec& spec) {
    const HRESULT init = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    std::string result;
    IFileOpenDialog* dlg = nullptr;
    if (SUCCEEDED(CoCreateInstance(CLSID_FileOpenDialog, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dlg)))) {
        DWORD opts = 0;
        dlg->GetOptions(&opts);
        dlg->SetOptions(opts | FOS_FORCEFILESYSTEM | FOS_PATHMUSTEXIST | (spec.folder ? FOS_PICKFOLDERS : FOS_FILEMUSTEXIST));
        dlg->SetTitle(utf8_path(spec.title).wstring().c_str());
        const std::wstring filterName = utf8_path(spec.filterName).wstring();
        const std::wstring filterGlob = utf8_path(glob_list(spec.extensions, ";")).wstring();
        if (!spec.folder && !spec.extensions.empty()) {
            const COMDLG_FILTERSPEC filter{filterName.c_str(), filterGlob.c_str()};
            dlg->SetFileTypes(1, &filter);
        }
        std::error_code ec;
        IShellItem* folder = nullptr;
        if (!spec.start.empty() &&
            SUCCEEDED(SHCreateItemFromParsingName(std::filesystem::absolute(utf8_path(spec.start), ec).wstring().c_str(), nullptr,
                                                  IID_PPV_ARGS(&folder)))) {
            dlg->SetFolder(folder);
            folder->Release();
        }
        IShellItem* item = nullptr;
        if (SUCCEEDED(dlg->Show(static_cast<HWND>(const_cast<void*>(sapp_win32_get_hwnd())))) &&
            SUCCEEDED(dlg->GetResult(&item))) {
            PWSTR path = nullptr;
            if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &path))) {
                result = utf8_string(std::filesystem::path(path));
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

std::string pick_path(const PickSpec& spec) {
    std::string dir = spec.start.empty() ? std::filesystem::current_path().string() : spec.start;
    ai::ProcessOptions po;
#ifdef __APPLE__
    std::string types;  // {"png", "jpg"}
    for (const std::string& e : spec.extensions) types += std::string(types.empty() ? "" : ", ") + "\"" + e + "\"";
    const std::string choose = spec.folder ? "choose folder with prompt (item 1 of argv)"
                                           : "choose file with prompt (item 1 of argv) of type {" + types + "}";
    po.argv = {"osascript", "-e", "on run argv", "-e",
               "POSIX path of (" + choose + " default location (POSIX file (item 2 of argv)))", "-e", "end run", spec.title, dir};
#else
    const std::string kdeFilter = glob_list(spec.extensions, " ") + "|" + spec.filterName;
    if (!ai::which("zenity").empty()) {
        po.argv = {"zenity", "--file-selection", "--title=" + spec.title, "--filename=" + dir + "/"};
        if (spec.folder) po.argv.push_back("--directory");
        else if (!spec.extensions.empty()) po.argv.push_back("--file-filter=" + spec.filterName + " | " + glob_list(spec.extensions, " "));
    } else if (!ai::which("kdialog").empty()) {
        po.argv = spec.folder ? std::vector<std::string>{"kdialog", "--title", spec.title, "--getexistingdirectory", dir}
                              : std::vector<std::string>{"kdialog", "--title", spec.title, "--getopenfilename", dir, kdeFilter};
    } else {
        return {};
    }
#endif
    auto r = ai::run_process(po);
    if (!r || r->exitCode != 0) return {};
    std::string out = r->stdoutText;
    while (!out.empty() && (out.back() == '\n' || out.back() == '\r')) out.pop_back();
    if (out.size() > 1 && out.back() == '/') out.pop_back();  // osascript ends folders with '/'
    return out;
}

#endif

bool has_png_magic(const std::vector<std::uint8_t>& b) {
    static const std::uint8_t magic[8] = {0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A};
    return b.size() > 8 && std::equal(magic, magic + 8, b.begin());
}

}  // namespace

std::string pick_folder(const std::string& title, const std::string& start) {
    PickSpec spec;
    spec.title = title;
    spec.start = start;
    return pick_path(spec);
}

std::string pick_file(const std::string& title, const std::string& start, const std::string& filterName,
                      const std::vector<std::string>& extensions) {
    PickSpec spec;
    spec.title = title;
    spec.start = start;
    spec.folder = false;
    spec.filterName = filterName;
    spec.extensions = extensions;
    return pick_path(spec);
}

#ifdef _WIN32
void maximize_window() { ShowWindow(static_cast<HWND>(const_cast<void*>(sapp_win32_get_hwnd())), SW_MAXIMIZE); }
#else
void maximize_window() {}  // ponytail: Windows only, where a 1440x860 window at 125% DPI is taller than a 1080p screen
#endif

// ---------------------------------------------------------------------------------------------------------------------
// The clipboard's picture, as PNG bytes (empty when it holds no picture).

#ifdef _WIN32

std::vector<std::uint8_t> clipboard_image_png() {
    std::vector<std::uint8_t> png;
    if (!OpenClipboard(nullptr)) return png;
    auto grab = [](UINT format) {
        std::vector<std::uint8_t> bytes;
        if (HANDLE h = GetClipboardData(format)) {
            const SIZE_T size = GlobalSize(h);
            if (const void* p = GlobalLock(h)) {
                bytes.assign(static_cast<const std::uint8_t*>(p), static_cast<const std::uint8_t*>(p) + size);
                GlobalUnlock(h);
            }
        }
        return bytes;
    };
    // Browsers and most screenshot tools offer a registered "PNG" format: no conversion needed.
    if (const UINT pngFormat = RegisterClipboardFormatA("PNG"); pngFormat && IsClipboardFormatAvailable(pngFormat)) {
        std::vector<std::uint8_t> bytes = grab(pngFormat);
        if (has_png_magic(bytes)) png = std::move(bytes);
    }
    // Everything else puts a device-independent bitmap there (the V5 one first: it carries the alpha channel).
    for (const UINT format : {static_cast<UINT>(CF_DIBV5), static_cast<UINT>(CF_DIB)}) {
        if (!png.empty() || !IsClipboardFormatAvailable(format)) continue;
        const std::vector<std::uint8_t> dib = grab(format);
        const Image img = image_from_dib(dib.data(), dib.size());
        if (!img.empty()) png = encode_png(img);
    }
    CloseClipboard();
    return png;
}

#elif defined(__APPLE__)

std::vector<std::uint8_t> clipboard_image_png() {
    std::error_code ec;
    const std::filesystem::path tmp = std::filesystem::temp_directory_path(ec) / ("factoria_clipboard_" + std::to_string(std::rand()) + ".png");
    ai::ProcessOptions po;
    po.argv = {"osascript", "-e", "on run argv", "-e", "set theData to the clipboard as \xC2\xAB" "class PNGf\xC2\xBB", "-e",
               "set fp to open for access (POSIX file (item 1 of argv)) with write permission", "-e", "set eof fp to 0", "-e",
               "write theData to fp", "-e", "close access fp", "-e", "end run", tmp.string()};
    std::vector<std::uint8_t> png;
    auto r = ai::run_process(po);  // fails when the clipboard holds no picture
    if (r && r->exitCode == 0) {
        std::ifstream in(tmp, std::ios::binary);
        png.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
    }
    std::filesystem::remove(tmp, ec);
    return has_png_magic(png) ? png : std::vector<std::uint8_t>{};
}

#else

std::vector<std::uint8_t> clipboard_image_png() {
    ai::ProcessOptions po;
    po.maxCapture = 64u << 20;
    const char* wayland = std::getenv("WAYLAND_DISPLAY");
    if (wayland && *wayland && !ai::which("wl-paste").empty()) po.argv = {"wl-paste", "--type", "image/png"};
    else if (!ai::which("xclip").empty()) po.argv = {"xclip", "-selection", "clipboard", "-t", "image/png", "-o"};
    else return {};
    auto r = ai::run_process(po);
    if (!r || r->exitCode != 0) return {};
    std::vector<std::uint8_t> png(r->stdoutText.begin(), r->stdoutText.end());
    return has_png_magic(png) ? png : std::vector<std::uint8_t>{};
}

#endif

}  // namespace fa::editor
