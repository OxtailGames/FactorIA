// Engine updates from GitHub Releases: see fa/editor/update.h.
#include "fa/editor/update.h"

#include <algorithm>
#include <cstdlib>
#include <fstream>
#include <vector>

#include "ai_chat.h"  // utf8_path
#include "fa/ai/process.h"
#include "fa/core/process.h"
#include "fa/tooling/export.h"  // executable_dir
#include "fa/tooling/setup.h"   // editor_restart_command

#if defined(_WIN32)
#include <windows.h>
#else
#include <unistd.h>
#endif

namespace fa {
namespace stdfs = std::filesystem;

namespace {

#if defined(_WIN32)
constexpr const char* kExe = ".exe";
#else
constexpr const char* kExe = "";
#endif

std::string strip_v(std::string tag) { return !tag.empty() && (tag[0] == 'v' || tag[0] == 'V') ? tag.substr(1) : tag; }

std::vector<long> version_parts(std::string_view v) {
    std::vector<long> parts;
    std::string s = strip_v(std::string(v));
    for (const char* p = s.c_str(); *p;) {
        char* end = nullptr;
        parts.push_back(std::strtol(p, &end, 10));
        if (end == p || *end != '.') break;  // "1.2.3-beta": the suffix is ignored
        p = end + 1;
    }
    return parts;
}

// A string field of a GitHub reply ("" when missing or null: GitHub sends "body": null for empty notes).
std::string str(const Json& j, const char* key) {
    auto it = j.find(key);
    return it != j.end() && it->is_string() ? it->get<std::string>() : std::string();
}

// Windows' own bsdtar unpacks .zip; a Git for Windows `tar` found first in PATH would not.
std::string tar_exe() {
#if defined(_WIN32)
    const char* root = std::getenv("SystemRoot");
    return std::string(root ? root : "C:\\Windows") + "\\System32\\tar.exe";
#else
    return "tar";
#endif
}

}  // namespace

std::string update_repo() {
    // Started from the AppImage: its files are a read-only mount that install_update cannot replace. Updating means
    // downloading the newer AppImage (docs/GETTING_STARTED.md, "Updates"), so the editor does not offer it.
    if (std::getenv("APPIMAGE")) return {};
    return FA_UPDATE_REPO;
}

std::string update_package_name() {
#if defined(_WIN32)
    return "FactorIA-windows-x64.zip";
#elif defined(__APPLE__)
    // A universal binary (arm64 + x86_64). Editors up to 0.1.2 look for FactorIA-macos-arm64.tar.gz, so
    // .github/workflows/release.yml still uploads this very file under that name too: drop that copy once nobody
    // runs those editors.
    return "FactorIA-macos-universal.tar.gz";
#else
    return "FactorIA-linux-x64.tar.gz";
#endif
}

bool version_newer(std::string_view a, std::string_view b) {
    std::vector<long> x = version_parts(a), y = version_parts(b);
    std::size_t n = std::max(x.size(), y.size());
    x.resize(n), y.resize(n);
    return x > y;
}

Result<UpdateInfo> parse_releases(const Json& releases, std::string_view current) {
    UpdateInfo info;
    info.current = std::string(current);
    if (!releases.is_array()) return make_error("GitHub releases: expected a JSON array, got " + releases.dump().substr(0, 200));
    std::vector<const Json*> newer;
    for (const Json& r : releases) {
        if (!r.is_object() || r.value("draft", false) || r.value("prerelease", false)) continue;
        if (version_newer(str(r, "tag_name"), current)) newer.push_back(&r);
    }
    if (newer.empty()) return info;
    std::sort(newer.begin(), newer.end(),
              [](const Json* a, const Json* b) { return version_newer(str(*a, "tag_name"), str(*b, "tag_name")); });
    const Json& latest = *newer.front();
    std::string tag = str(latest, "tag_name");
    const std::string package = update_package_name();
    if (auto assets = latest.find("assets"); assets != latest.end() && assets->is_array())
        for (const Json& a : *assets)
            if (a.is_object() && str(a, "name") == package) {
                info.packageUrl = str(a, "browser_download_url");
                if (a.contains("size") && a["size"].is_number_integer()) info.packageSize = a["size"].get<std::uint64_t>();
            }
    if (info.packageUrl.empty())
        return make_error("Release " + tag + " has no " + package + " package (yet)",
                          "its packages may still be uploading: try again in a few minutes, or download it from the "
                          "Releases page");
    info.latest = strip_v(tag);
    for (const Json* r : newer) {
        std::string name = str(*r, "name"), body = str(*r, "body");
        info.notes += "# " + (name.empty() ? "FactorIA " + str(*r, "tag_name") : name) + "\n\n" +
                      (body.empty() ? "(no release notes)" : body) + "\n\n";
    }
    return info;
}

Result<UpdateInfo> check_for_update(const ai::HttpTransport& http) {
    if (update_repo().empty()) return UpdateInfo{FA_ENGINE_VERSION};
    ai::HttpRequest rq;
    rq.method = "GET";
    rq.url = "https://api.github.com/repos/" + update_repo() + "/releases?per_page=30";
    rq.headers = {{"Accept", "application/vnd.github+json"}};
    rq.timeoutSeconds = 20;
    rq.connectTimeoutSeconds = 10;
    ai::HttpResponse resp = http(rq);
    if (resp.status == 0)
        return make_error("Cannot reach GitHub to check for updates: " + resp.error, "check the internet connection");
    if (!resp.ok())
        return make_error("GitHub answered " + std::to_string(resp.status) + " to " + rq.url + ": " + resp.body.substr(0, 300),
                          resp.status == 403 ? "GitHub limits unauthenticated requests per hour: try again later" : "");
    auto json = parse_json(resp.body, rq.url);
    if (!json) return json.error();
    return parse_releases(*json, FA_ENGINE_VERSION);
}

Result<void> install_update(const UpdateInfo& info, const stdfs::path& installDir,
                            const std::function<void(double)>& progress, const ai::HttpTransport& http) {
    std::error_code ec;
    const stdfs::path staging = installDir / ".update";
    const std::string where = editor::utf8_string(installDir);
    stdfs::remove_all(staging, ec);
    stdfs::create_directories(staging / "x", ec);
    if (ec)
        return make_error("Cannot write to " + where + ": " + ec.message(),
                          "move the FactorIA folder somewhere you can write, such as C:\\FactorIA or ~/FactorIA, "
                          "and open it from there");
    auto fail = [&](std::string message, std::string hint = {}) {
        stdfs::remove_all(staging, ec);
        return Result<void>(make_error(std::move(message), std::move(hint)));
    };

    // 1. Download.
    const stdfs::path archive = staging / update_package_name();
    {
        std::ofstream out(archive, std::ios::binary);
        std::uint64_t got = 0;
        ai::HttpRequest rq;
        rq.method = "GET";
        rq.url = info.packageUrl;
        rq.timeoutSeconds = 1800;
        rq.onData = [&](std::string_view chunk) {
            out.write(chunk.data(), std::streamsize(chunk.size()));
            got += chunk.size();
            if (progress && info.packageSize) progress(std::min(1.0, double(got) / double(info.packageSize)));
            return bool(out);
        };
        ai::HttpResponse resp = http(rq);
        out.close();
        if (!resp.ok() || !out)
            return fail("Downloading " + info.packageUrl + " failed: " +
                            (resp.error.empty() ? "HTTP " + std::to_string(resp.status) : resp.error),
                        "check the internet connection and the free disk space, then try again");
    }

    // 2. Unpack. The package holds one folder, FactorIA/, with the files that go next to factoria.
    ai::ProcessOptions po;
    po.argv = {tar_exe(), "-xf", editor::utf8_string(archive), "-C", editor::utf8_string(staging / "x")};
    auto tar = ai::run_process(po);
    const stdfs::path src = staging / "x" / "FactorIA";
    if (!tar || tar->exitCode != 0)
        return fail("Cannot unpack " + editor::utf8_string(archive) + ": " + (tar ? tar->stderrText : tar.error().message),
                    "the download may be damaged: try again");
    if (!stdfs::is_regular_file(src / (std::string("factoria") + kExe), ec))
        return fail("The package " + update_package_name() + " has no FactorIA/factoria" + kExe,
                    "download the package from the Releases page and unzip it over this folder");

    // 3. Swap the files: the old ones become <name>.old; on failure put them back.
    struct Swapped { stdfs::path dst; bool hadOld; };
    std::vector<Swapped> done;
    std::string error;
    for (const auto& entry : stdfs::directory_iterator(src, ec)) {
        // Files, and folders such as mobile/ (the prebuilt Android and iOS players that `factoria export` uses: they must
        // match this factoria), are swapped whole.
        if (!entry.is_regular_file(ec) && !entry.is_directory(ec)) continue;
        stdfs::path dst = installDir / entry.path().filename(), old = dst;
        old += ".old";
        bool had = stdfs::exists(dst, ec);
        if (had) {
            stdfs::remove_all(old, ec);
            stdfs::rename(dst, old, ec);
            if (ec) { error = "cannot rename " + editor::utf8_string(dst) + ": " + ec.message(); break; }
        }
        stdfs::rename(entry.path(), dst, ec);
        if (ec) {
            error = "cannot replace " + editor::utf8_string(dst) + ": " + ec.message();
            if (had) stdfs::rename(old, dst, ec);
            break;
        }
        done.push_back({dst, had});
    }
    if (!error.empty()) {
        for (auto it = done.rbegin(); it != done.rend(); ++it) {
            stdfs::remove_all(it->dst, ec);
            stdfs::path old = it->dst;
            old += ".old";
            if (it->hadOld) stdfs::rename(old, it->dst, ec);
        }
        return fail("Update to " + info.latest + " failed, the old version was kept: " + error,
                    "close other programs that use files in " + where + " and try again");
    }
    stdfs::remove_all(staging, ec);
    return {};
}

void remove_update_leftovers(const stdfs::path& installDir) {
    std::error_code ec;
    stdfs::remove_all(installDir / ".update", ec);
    for (const auto& entry : stdfs::directory_iterator(installDir, ec)) {
        const stdfs::path& p = entry.path();
        // Only the <name>.old of a file or folder that is still there: the ones install_update made. A running one (the
        // old editor that just restarted) cannot be removed on Windows yet; the next start does it.
        if (p.extension() == ".old" && stdfs::exists(p.parent_path() / p.stem(), ec)) stdfs::remove_all(p, ec);
    }
}

Result<void> start_editor_process(const std::string& projectDir) {
    // Through the launcher the user pinned (the Dock or taskbar icon), when it is ours: a bare `factoria` would show a
    // second FactorIA icon next to it. Any failure falls back to starting the program itself.
    std::error_code absEc;
    const stdfs::path absProject = projectDir.empty() ? stdfs::path() : stdfs::absolute(editor::utf8_path(projectDir), absEc);
#if defined(_WIN32)
    const std::vector<std::string> viaLauncher = editor_restart_command(SetupContext{}, editor::utf8_string(absProject));
#else
    // macOS: a helper that waits until this editor is gone, so the new one takes the pinned Dock icon.
    const std::vector<std::string> viaLauncher =
        editor_restart_command(SetupContext{}, editor::utf8_string(absProject), static_cast<long long>(getpid()));
#endif
    if (!viaLauncher.empty()) {
#if defined(_WIN32)
        std::wstring cmd = L"\"" + editor::utf8_path(viaLauncher[0]).wstring() + L"\"";
        if (viaLauncher.size() > 1) cmd += L" \"" + editor::utf8_path(viaLauncher[1]).wstring() + L"\"";  // none: start screen
        STARTUPINFOW si{};
        si.cb = sizeof si;
        PROCESS_INFORMATION pi{};
        if (CreateProcessW(editor::utf8_path(viaLauncher[0]).c_str(), cmd.data(), nullptr, nullptr, FALSE, CREATE_NO_WINDOW, nullptr,
                           nullptr, &si, &pi)) {
            CloseHandle(pi.hThread);
            CloseHandle(pi.hProcess);
            return {};
        }
#else
        // Detached and not waited for: it waits for this process to exit.
        std::vector<char*> argv;
        for (const std::string& a : viaLauncher) argv.push_back(const_cast<char*>(a.c_str()));
        argv.push_back(nullptr);
        if (pid_t pid = fork(); pid == 0) {
            setsid();  // outlives this editor
            execv(argv[0], argv.data());
            _exit(127);
        } else if (pid > 0) {
            return {};
        }
#endif
    }
    stdfs::path exe = executable_dir() / (std::string("factoria") + kExe);
    stdfs::path project = editor::utf8_path(projectDir);
#if defined(_WIN32)
    std::wstring cmd = L"\"" + exe.wstring() + L"\" editor";
    if (!projectDir.empty()) cmd += L" \"" + project.wstring() + L"\"";
    STARTUPINFOW si{};
    si.cb = sizeof si;
    PROCESS_INFORMATION pi{};
    if (!CreateProcessW(exe.c_str(), cmd.data(), nullptr, nullptr, FALSE, CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi))
        return make_error("Cannot start " + editor::utf8_string(exe) + " (error " + std::to_string(GetLastError()) + ")",
                          "open the editor again yourself");
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
#else
    std::string exeS = exe.string(), projS = project.string();
    pid_t pid = fork();
    if (pid < 0) return make_error("Cannot start " + exeS + ": fork failed", "open the editor again yourself");
    if (pid == 0) {
        setsid();  // outlives this editor
        execl(exeS.c_str(), exeS.c_str(), "editor", projS.empty() ? static_cast<const char*>(nullptr) : projS.c_str(),
              static_cast<char*>(nullptr));
        _exit(127);
    }
#endif
    return {};
}

}  // namespace fa
