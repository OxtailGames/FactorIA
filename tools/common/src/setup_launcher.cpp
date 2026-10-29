// `setup launcher`: an app that opens the editor of this factoria, with the FactorIA icon, where the desktop lists apps.
//
//   macOS  <HOME>/Applications/FactorIA.app   Contents/Info.plist, Contents/MacOS/FactorIA (a zsh script that runs
//                                             `<factoria> editor`, its output in ~/Library/Logs/FactorIA/editor.log),
//                                             Contents/Resources/AppIcon.icns (tools/editor/icon/factoria.icns)
//   Linux  <XDG_DATA_HOME or ~/.local/share>/applications/factoria.desktop and icons/hicolor/256x256/apps/factoria.png
//   Windows  nothing: the installer adds FactorIA Editor to the Start menu, and FactorIA-Editor.exe of the zip can be pinned.
//
// The Dock, Launchpad and Finder show the icon of the app while the editor is not running, so it must be the icon of this
// factoria: the launcher is "partial" when it opens another factoria or its files are not the ones this one writes, and an
// install rewrites them. The files are written in place, not by swapping the folder: the Dock keeps an item that points
// at the app, and a swapped folder would leave it pointing at a deleted one. Nothing is downloaded (the icons are in the
// binary). The editor refreshes, at start, a launcher that opens it but is out of date (an update or a reinstall).
#include <fstream>

#include "fa/tooling/bundle.h"
#include "setup_internal.h"
#include "util.h"

namespace fa::setup_detail {

namespace {

constexpr const char* kMacIcon = "tools/editor/icon/factoria.icns";
constexpr const char* kLinuxIcon = "platforms/linux/factoria.png";
constexpr const char* kTargetLine = "FACTORIA=";          // macOS script: the factoria it opens, single-quoted
constexpr const char* kTargetKey = "X-FactorIA-Path=";     // Linux .desktop: the same, unquoted

stdfs::path user_home(const SetupContext& ctx) { return ctx.env ? stdfs::path(ctx.env("HOME")) : stdfs::path(); }

// This factoria (the editor ships it next to itself).
stdfs::path factoria_exe(const SetupContext& ctx) { return exe_dir(ctx) / ("factoria" + exe_suffix(ctx.host_os())); }

std::string read_all(const stdfs::path& p) { return tooling_detail::read_file(p).value_or(std::string()); }

// 'it'\''s' : a POSIX shell single-quoted word.
std::string shell_quote(const std::string& s) {
    std::string out = "'";
    for (char ch : s) out += ch == '\'' ? std::string("'\\''") : std::string(1, ch);
    return out + "'";
}

std::string shell_unquote(const std::string& s) {
    std::string out;
    bool quoted = false;
    for (std::size_t i = 0; i < s.size(); ++i) {
        if (s[i] == '\'') quoted = !quoted;
        else if (s[i] == '\\' && !quoted && i + 1 < s.size()) out += s[++i];
        else out += s[i];
    }
    return out;
}

// "x y" -> "\"x y\"": an argument of a .desktop Exec line (the Desktop Entry spec's quoting).
std::string desktop_quote(const std::string& s) {
    std::string out = "\"";
    for (char ch : s) {
        if (ch == '"' || ch == '`' || ch == '$' || ch == '\\') out += "\\\\";
        out += ch;
    }
    return out + "\"";
}

// What the launcher is made of: relative path -> content, and the file that must be executable.
struct LauncherFiles {
    stdfs::path root;   // the .app (macOS) or the data folder (Linux)
    std::vector<std::pair<std::string, std::string>> files;
    std::string script; // macOS: the relative path of the script
    std::string error;  // this build has no icon to give it
};

LauncherFiles mac_files(const SetupContext& ctx) {
    LauncherFiles l;
    l.root = user_home(ctx) / "Applications" / "FactorIA.app";
    const std::string v = ctx.version();
    l.files.emplace_back("Contents/Info.plist",
                         "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                         "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
                         "<plist version=\"1.0\">\n<dict>\n"
                         "    <key>CFBundleName</key><string>FactorIA</string>\n"
                         "    <key>CFBundleDisplayName</key><string>FactorIA</string>\n"
                         "    <key>CFBundleIdentifier</key><string>com.oxtailgames.factoria.launcher</string>\n"
                         "    <key>CFBundleVersion</key><string>" + v + "</string>\n"
                         "    <key>CFBundleShortVersionString</key><string>" + v + "</string>\n"
                         "    <key>CFBundlePackageType</key><string>APPL</string>\n"
                         "    <key>CFBundleExecutable</key><string>FactorIA</string>\n"
                         "    <key>CFBundleIconFile</key><string>AppIcon</string>\n"
                         "    <key>LSMinimumSystemVersion</key><string>11.0</string>\n"
                         "    <key>NSHighResolutionCapable</key><true/>\n"
                         "</dict>\n</plist>\n");
    l.script = "Contents/MacOS/FactorIA";
    l.files.emplace_back(l.script, "#!/bin/zsh\n"
                                   "# The FactorIA launcher, written by `factoria setup launcher`: opens the editor of this factoria.\n" +
                                   std::string(kTargetLine) + shell_quote(factoria_exe(ctx).string()) + "\n"
                                   "mkdir -p \"$HOME/Library/Logs/FactorIA\"\n"
                                   "cd \"$HOME\"\n"
                                   "exec \"$FACTORIA\" editor >\"$HOME/Library/Logs/FactorIA/editor.log\" 2>&1\n");
    if (auto icon = bundled_read(kMacIcon)) l.files.emplace_back("Contents/Resources/AppIcon.icns", std::move(*icon));
    else l.error = std::string("This build of factoria does not carry the icon (") + kMacIcon + ").";
    return l;
}

LauncherFiles linux_files(const SetupContext& ctx) {
    LauncherFiles l;
    const std::string xdg = ctx.env ? ctx.env("XDG_DATA_HOME") : std::string();
    l.root = xdg.empty() ? user_home(ctx) / ".local" / "share" : stdfs::path(xdg);
    const std::string iconRel = "icons/hicolor/256x256/apps/factoria.png";
    const std::string exe = factoria_exe(ctx).string();
    l.files.emplace_back("applications/factoria.desktop", "[Desktop Entry]\n"
                                                          "Type=Application\n"
                                                          "Name=FactorIA\n"
                                                          "Comment=Open the FactorIA editor\n"
                                                          "Exec=" + desktop_quote(exe) + " editor\n"
                                                          "Icon=" + (l.root / iconRel).string() + "\n"
                                                          "Terminal=false\n"
                                                          "Categories=Development;Game;\n" +
                                                          std::string(kTargetKey) + exe + "\n");
    if (auto icon = bundled_read(kLinuxIcon)) l.files.emplace_back(iconRel, std::move(*icon));
    else l.error = std::string("This build of factoria does not carry the icon (") + kLinuxIcon + ").";
    return l;
}

// The factoria an installed launcher opens ("" when it is not one written by `setup launcher`).
std::string launcher_target(const SetupContext& ctx, const LauncherFiles& l) {
    const bool mac = ctx.host_os() == "macos";
    std::ifstream in(l.root / (mac ? l.script : std::string("applications/factoria.desktop")));
    const std::string prefix = mac ? kTargetLine : kTargetKey;
    for (std::string line; std::getline(in, line);)
        if (line.rfind(prefix, 0) == 0) return mac ? shell_unquote(line.substr(prefix.size())) : line.substr(prefix.size());
    return {};
}

std::optional<LauncherFiles> files_for_host(const SetupContext& ctx) {
    if (ctx.host_os() == "macos") return mac_files(ctx);
    if (ctx.host_os() == "linux") return linux_files(ctx);
    return std::nullopt;
}

// The file the desktop looks for first: present = there is a launcher, whatever state it is in.
stdfs::path main_file(const SetupContext& ctx, const LauncherFiles& l) {
    return l.root / (ctx.host_os() == "macos" ? l.script : std::string("applications/factoria.desktop"));
}

}  // namespace

SetupComponent launcher_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "launcher";
    c.title = "FactorIA app launcher (Dock, Launchpad, application menu)";
    const auto l = files_for_host(ctx);
    if (!l) {
        c.state = "unsupported";
        c.details = "Not needed on Windows: the installer adds FactorIA Editor to the Start menu, and FactorIA-Editor.exe of the zip can be "
                    "pinned to the taskbar.";
        return c;
    }
    const bool mac = ctx.host_os() == "macos";
    c.canInstall = l->error.empty() && !user_home(ctx).empty();
    c.paths.emplace_back("launcher", mac ? l->root.string() : (l->root / "applications/factoria.desktop").string());
    if (!is_file(main_file(ctx, *l))) {
        c.state = "missing";
        c.details = mac ? "An app in ~/Applications that opens the editor, with the FactorIA icon, for the Dock, Launchpad and Spotlight. "
                          "`factoria setup launcher` writes it (nothing is downloaded)."
                        : "A desktop entry that opens the editor, with the FactorIA icon, in the application menu. `factoria setup launcher` "
                          "writes it (nothing is downloaded).";
        return c;
    }
    const std::string target = launcher_target(ctx, *l);
    c.paths.emplace_back("opens", target);
    const std::string exe = factoria_exe(ctx).string();
    if (target.empty())
        c.problems.push_back("The launcher at " + l->root.string() + " was not written by `factoria setup launcher`: run it to replace it with the "
                             "one of this factoria (its icon included).");
    else if (target != exe)
        c.problems.push_back("The launcher opens " + target + ", not this factoria (" + exe + "): `factoria setup launcher` points it here.");
    else
        for (const auto& [rel, data] : l->files)
            if (read_all(l->root / rel) != data) {
                c.problems.push_back("The launcher is out of date (" + rel + " is not the one of FactorIA " + ctx.version() +
                                     "): `factoria setup launcher` rewrites it; the editor also does at start.");
                break;
            }
    if (!l->error.empty()) c.problems.push_back(l->error);
    c.state = c.problems.empty() ? "installed" : "partial";
    c.details = "Opens the editor of " + (target.empty() ? std::string("another program") : target) + ".";
    return c;
}

SetupResult launcher_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    Installer in(ctx, "launcher");
    const auto l = files_for_host(ctx);
    if (!l)
        return in.fail("unsupported", make_error("There is no launcher to install on Windows.",
                                                 "The installer adds FactorIA Editor to the Start menu; from the zip, pin FactorIA-Editor.exe to the taskbar."));
    if (user_home(ctx).empty())
        return in.fail("failed", make_error("Cannot find the user's home folder: HOME is not set.", "Set it and run `factoria setup launcher` again."));
    if (!l->error.empty()) return in.fail("failed", make_error(l->error, "Use an official download of FactorIA, or build from a full checkout."));
    if (!is_file(factoria_exe(ctx)))
        in.report.warnings.push_back("There is no factoria at " + factoria_exe(ctx).string() + ": the launcher will not open anything until there is.");

    StepTimer timer;
    SetupStep s;
    s.id = "launcher";
    s.title = ctx.host_os() == "macos" ? "FactorIA.app" : "factoria.desktop";
    s.path = ctx.host_os() == "macos" ? l->root.string() : (l->root / "applications/factoria.desktop").string();
    if (!opt.force && launcher_status(ctx).state == "installed") {
        s.outcome = "skipped";
        s.detail = "already installed";
    } else {
        for (const auto& [rel, data] : l->files) {
            const stdfs::path p = l->root / rel;
            if (read_all(p) == data) continue;
            std::string err;
            if (!tooling_detail::write_file(p, data, &err))
                return in.fail("failed", make_error("Cannot write " + p.string() + ": " + err, "Check that the folder is writable."));
        }
        if (!l->script.empty()) make_executable(l->root / l->script);
        s.outcome = "installed";
        s.detail = "opens " + factoria_exe(ctx).string();
        if (ctx.host_os() == "macos") {
            // The Dock and Finder cache the icon of an app: a newer folder date and a fresh registration make them read it again.
            std::error_code ec;
            stdfs::last_write_time(l->root, stdfs::file_time_type::clock::now(), ec);
            ProcessOptions po;
            po.argv = {"/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", "-f",
                       l->root.string()};
            po.timeoutSeconds = 30;
            auto r = ctx.run_process_with(po);
            if (!r || r->exitCode != 0)
                in.report.warnings.push_back("Could not register the app with Launch Services: the Dock may show the old icon until you log in again.");
            in.report.nextSteps.push_back("Drag FactorIA from ~/Applications to the Dock, or find it with Spotlight. If the Dock still shows an "
                                          "old icon, remove it from the Dock and add it again.");
        } else {
            in.report.nextSteps.push_back("FactorIA is in the application menu (Development). Some desktops pick a new entry up after you log in again.");
        }
    }
    s.seconds = timer.seconds();
    in.add_step(s);
    in.report.paths.emplace_back("launcher", s.path);
    return in.finish();
}

}  // namespace fa::setup_detail

namespace fa {

bool refresh_launcher(const SetupContext& context) {
    using namespace setup_detail;
    const SetupComponent c = launcher_status(context);
    if (c.state != "partial") return false;
    std::string target;
    for (const auto& [key, path] : c.paths)
        if (key == "opens") target = path;
    std::error_code ec;
    if (target.empty() || !stdfs::equivalent(target, factoria_exe(context), ec)) return false;  // another factoria's: left alone
    SetupInstallOptions options;
    options.component = "launcher";
    return launcher_install(context, options).ok;
}

}  // namespace fa
