// The Linux AppImage of an exported game (`factoria export --platform linux --format appimage`, docs/EXPORTING.md, "Linux:
// AppImage"). The export has already written the folder <out>/<slug>-linux/ (executable, game/, <slug>.desktop, <slug>.png,
// notices); this builds an AppDir from it and runs appimagetool:
//
//   <slug>.AppDir/
//     AppRun                 starts usr/bin/<slug>
//     <slug>.desktop         the export's entry, with Icon and the version fixed for AppImage
//     <slug>.png, .DirIcon   the game's icon (a plain placeholder when the game has none: appimagetool insists on one)
//     usr/bin/               everything else the export folder holds, in the same layout: the executable, game/ (or whatever
//                            the export wrote next to it), FACTORIA_NOTICES.txt, the native plugins' libraries
//
// The player finds game/ and the plugins next to its own executable, so keeping that layout under usr/bin is all it takes.
// appimagetool and the runtime come from `factoria setup appimage` (setup_appimage.cpp); nothing is downloaded by the export.
#include <algorithm>
#include <cstdlib>

#include "export_internal.h"
#include "fa/core/image.h"
#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "fa/tooling/ai_disclosure.h"
#include "fa/tooling/setup.h"

namespace fa::export_detail {

namespace {

constexpr const char* kArch = "x86_64";

std::string slug_of(const Project& p) { return slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-'); }

bool is_file_at(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_regular_file(os_path(p), ec);
}

// The plain icon of a game that set none: a dark square with a light "play" triangle.
std::vector<std::uint8_t> placeholder_icon_png() {
    Image img;
    img.width = img.height = 256;
    img.rgba.resize(256u * 256u * 4u);
    for (int y = 0; y < 256; ++y)
        for (int x = 0; x < 256; ++x) {
            const bool inside = x >= 96 && x <= 176 && std::abs(y - 128) * 80 <= (176 - x) * 48;
            std::uint8_t* px = &img.rgba[(static_cast<std::size_t>(y) * 256 + x) * 4];
            px[0] = inside ? 235 : 43;
            px[1] = inside ? 238 : 51;
            px[2] = inside ? 245 : 80;
            px[3] = 255;
        }
    return encode_png(img);
}

std::string last_lines(const std::string& text, std::size_t n) {
    std::vector<std::string> lines;
    for (const std::string& line : split(text, '\n')) {
        const std::string t(trim(line));
        if (!t.empty()) lines.push_back(t);
    }
    std::string out;
    for (std::size_t i = lines.size() > n ? lines.size() - n : 0; i < lines.size(); ++i) out += (out.empty() ? "" : " | ") + lines[i];
    return out;
}

}  // namespace

Result<AppImagePlan> plan_appimage(const ExportOptions& o, const Project& p, const stdfs::path& outRoot) {
    const SetupContext ctx = o.setup ? *o.setup : SetupContext{};
    if (ctx.host_os() != "linux" || ctx.host_architecture() != "x64")
        return err("export: an AppImage can only be built on Linux x86_64 (appimagetool is a Linux program), and this computer is " + ctx.host_os() + "-" +
                       ctx.host_architecture(),
                   "Export on a Linux x86_64 computer, or in WSL (Ubuntu) on Windows: `factoria export --platform linux --format appimage` there. Without --format the Linux export "
                   "works from here and writes a folder you can archive (tar czf).");
    const AppImageTools tools = installed_appimage_tools(ctx);
    if (tools.tool.empty())
        return err("export: appimagetool and the AppImage runtime are not installed (" + (stdfs::path(ctx.home_dir()) / "tools" / "appimage").string() + ")",
                   "Run `factoria setup appimage` (the setup.install command with component appimage; about 5 MB from github.com/AppImage, SHA-256 checked), then export again.");
    AppImagePlan plan;
    plan.enabled = true;
    plan.tool = tools.tool;
    plan.runtime = tools.runtime;
    plan.artifact = outRoot / (slug_of(p) + "-" + kArch + ".AppImage");
    return plan;
}

Result<void> write_appdir(const Project& p, const stdfs::path& exportRoot, const stdfs::path& appDir, const std::string& artifactName,
                          std::vector<std::string>& warnings) {
    const std::string slug = slug_of(p);
    std::error_code ec;
    stdfs::create_directories(os_path(appDir / "usr" / "bin"), ec);
    if (ec) return err("export: cannot create " + generic(appDir) + ": " + ec.message());

    // usr/bin: the export folder as it is, but for what the AppDir keeps at its top and what only a store form wants.
    for (stdfs::directory_iterator it(os_path(exportRoot), ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        if (name == kExportMarkerFile || name == slug + ".desktop" || name == slug + ".png" || name == kAiDisclosureFile || name == artifactName ||
            ends_with(name, ".AppImage"))
            continue;
        std::error_code copyEc;
        stdfs::copy(it->path(), os_path(appDir / "usr" / "bin" / name),
                    stdfs::copy_options::recursive | stdfs::copy_options::overwrite_existing | stdfs::copy_options::copy_symlinks, copyEc);
        if (copyEc) return err("export: cannot copy " + name + " into the AppDir: " + copyEc.message());
    }
    if (!is_file_at(appDir / "usr" / "bin" / slug))
        return err("export: the export folder " + generic(exportRoot) + " has no " + slug + " (the game's executable)", "Export the game again (project.export {\"platform\":\"linux\"}).");

    // AppRun: appimagetool wants it at the top. APPDIR is set by the AppImage runtime; the fallback also lets the AppDir run unpacked.
    const std::string appRun = "#!/bin/sh\n"
                               "# Starts the game of this AppImage (written by `factoria export --format appimage`).\n"
                               "here=\"${APPDIR:-$(dirname \"$(readlink -f \"$0\")\")}\"\n"
                               "exec \"$here/usr/bin/" + slug + "\" \"$@\"\n";
    if (auto r = write_text(appDir / "AppRun", appRun, true); !r.ok()) return r;

    // The icon.
    std::vector<std::uint8_t> icon;
    if (auto data = read_file(exportRoot / (slug + ".png"))) {
        icon.assign(data->begin(), data->end());
    } else {
        icon = placeholder_icon_png();
        warnings.push_back("No icon is set, so the AppImage gets a plain placeholder icon. Set \"icon\" in factoria.json (a square PNG or JPG, 1024x1024 recommended).");
    }
    for (const stdfs::path& to : {appDir / ".DirIcon", appDir / (slug + ".png")}) {
        std::string e;
        if (!write_file(to, std::string_view(reinterpret_cast<const char*>(icon.data()), icon.size()), &e)) return err("export: " + e);
    }

    // <slug>.desktop: the export's entry, Icon always set (appimagetool refuses an entry without one), the version added.
    std::string desktop;
    if (auto text = read_file(exportRoot / (slug + ".desktop"))) {
        bool hasIcon = false;
        for (const std::string& line : split(*text, '\n', false)) {
            if (line.empty()) continue;
            if (starts_with(line, "Icon=")) {
                hasIcon = true;
                desktop += "Icon=" + slug + "\n";
            } else {
                desktop += line + "\n";
            }
        }
        if (!hasIcon) desktop += "Icon=" + slug + "\n";
    } else {
        return err("export: the export folder " + generic(exportRoot) + " has no " + slug + ".desktop", "Export the game again (project.export {\"platform\":\"linux\"}).");
    }
    desktop += "X-AppImage-Version=" + safe_version_name(p.version) + "\n";
    return write_text(appDir / (slug + ".desktop"), desktop);
}

Result<void> build_appimage(const ExportOptions& o, const Project& p, const AppImagePlan& a, const stdfs::path& outRoot, ExportReport& report) {
    const std::string slug = slug_of(p);
    const SetupContext ctx = o.setup ? *o.setup : SetupContext{};
    // Beside the export folder, not inside it: the folder is what gets listed and archived. Removed again whatever happens.
    const stdfs::path appDir = outRoot.parent_path() / ("." + slug + "-linux.AppDir");
    std::error_code ec;
    stdfs::remove_all(os_path(appDir), ec);
    struct Cleanup {
        stdfs::path dir;
        ~Cleanup() {
            std::error_code e;
            stdfs::remove_all(os_path(dir), e);
        }
    } cleanup{appDir};

    if (auto r = write_appdir(p, outRoot, appDir, a.artifact.filename().string(), report.warnings); !r.ok()) return r;

    ProcessOptions po;
    po.argv = {a.tool.string(), "--no-appstream", "--runtime-file", a.runtime.string(), appDir.string(), a.artifact.string()};
    // ARCH: appimagetool cannot tell the architecture of the game from a shell script. EXTRACT_AND_RUN: appimagetool is an AppImage
    // itself; this runs it without FUSE (a CI runner, a container, WSL).
    po.env = {{"ARCH", kArch}, {"APPIMAGE_EXTRACT_AND_RUN", "1"}};
    po.cancel = o.cancel;
    if (o.progress) {
        po.onStdoutLine = [&o](std::string_view l) { o.progress(std::string(l)); };
        po.onStderrLine = [&o](std::string_view l) { o.progress(std::string(l)); };
    }
    auto run = ctx.run_process_with(po);
    if (!run.ok())
        return err("export: cannot run appimagetool (" + a.tool.string() + "): " + run.error().message,
                   "Run `factoria setup appimage --force` to install it again. A /home mounted noexec stops it from starting; set FACTORIA_HOME to a folder that is not.");
    if (run->cancelled || is_cancelled(o.cancel)) return err("export: cancelled while appimagetool was building the AppImage");
    if (run->exitCode != 0) {
        const std::string said = last_lines(run->stderrText + "\n" + run->stdoutText, 6);
        return err("export: appimagetool failed (exit code " + std::to_string(run->exitCode) + ")" + (said.empty() ? std::string(".") : ". It said: " + said),
                   "The export folder is complete without the AppImage (the temporary AppDir was removed); run the export again once this is fixed. `desktop-file-validate` (desktop-file-utils) complaints point at the Name or Categories of the game "
                   "(export.linux.categories in factoria.json).");
    }
    if (!is_file_at(a.artifact))
        return err("export: appimagetool finished but " + generic(a.artifact) + " was not written", "Run it again, and report this if it keeps happening.");
    stdfs::permissions(os_path(a.artifact), stdfs::perms::owner_exec | stdfs::perms::group_exec | stdfs::perms::others_exec, stdfs::perm_options::add, ec);

    report.format = "appimage";
    report.artifact = generic(a.artifact);
    const std::string file = a.artifact.filename().string();
    report.nextSteps.insert(report.nextSteps.begin(),
                            {"Run the AppImage: " + generic(a.artifact) + " (a file manager needs 'allow executing as a program' set once; on a computer without FUSE add "
                             "--appimage-extract-and-run)",
                             "Share " + file + ": it is the whole game in one file. Like the folder it uses the system's X11, OpenGL and ALSA and needs a glibc at least as new as "
                             "the player's (the FactorIA download is built on Ubuntu 24.04)."});
    return {};
}

}  // namespace fa::export_detail
