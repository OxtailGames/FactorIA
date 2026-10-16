// Desktop exports (linux, windows, macos): the factoria_player runtime plus the game, the .app bundle of macOS, and the
// game's icon in the form each platform wants it (docs/EXPORTING.md, "Desktop").
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <filesystem>

#include "export_internal.h"
#include "fa/tooling/icons.h"
#include "fa/tooling/pe_icon.h"
#include "fa/tooling/setup.h"

namespace fa::export_detail {

Result<stdfs::path> find_player(const ExportOptions& o, const std::string& platform) {
    std::error_code ec;
    const std::string exe = platform == "windows" ? "factoria_player.exe" : "factoria_player";
    if (!o.playerBinary.empty()) {
        if (!stdfs::is_regular_file(o.playerBinary, ec))
            return err("export: player binary '" + o.playerBinary + "' not found",
                       "build it with `cmake --build <build dir> --target factoria_player`");
        return stdfs::path(o.playerBinary);
    }
    if (platform != host_platform()) {
        // The player `factoria setup players` downloaded for this factoria version (<home>/players/<version>/<os>/).
        if (const std::string installed = installed_player(platform); !installed.empty()) return stdfs::path(installed);
        return err("export: cannot export for " + platform + " from a " + host_platform() +
                       " machine without a player binary built for " + platform,
                   "run `factoria setup players` (the editor: Set up in the Export window) to download the " + platform +
                       " player of this FactorIA version, or build factoria_player on " + platform +
                       " (see docs/BUILDING.md) and pass it with --player <path>");
    }
    stdfs::path dir = executable_dir();
    for (const stdfs::path& c : {dir / exe, dir.parent_path() / "player" / exe, dir.parent_path().parent_path() / "player" / exe})
        if (stdfs::is_regular_file(c, ec)) return c;
    return err("export: factoria_player not found next to the factoria binary (" + generic(dir) + ")",
               "build it with `cmake --build <build dir> --target factoria_player`, or pass --player <path>");
}

namespace {

// Info.plist of the .app. The keys the settings decide (export.macos in factoria.json): LSApplicationCategoryType,
// LSMinimumSystemVersion, NSHumanReadableCopyright; the icon is Contents/Resources/AppIcon.icns, named by CFBundleIconFile.
std::string macos_plist(const Project& p, const std::string& exeName, bool hasIcon) {
    const MacosExportSettings& m = p.settings.macos;
    std::string plist =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        "<plist version=\"1.0\">\n<dict>\n"
        "\t<key>CFBundleExecutable</key><string>" + xml_escape(exeName) + "</string>\n"
        "\t<key>CFBundleIdentifier</key><string>" + xml_escape(p.id.empty() ? "com.example.game" : p.id) + "</string>\n"
        "\t<key>CFBundleName</key><string>" + xml_escape(p.name) + "</string>\n"
        "\t<key>CFBundleDisplayName</key><string>" + xml_escape(p.name) + "</string>\n"
        "\t<key>CFBundlePackageType</key><string>APPL</string>\n"
        "\t<key>CFBundleShortVersionString</key><string>" + xml_escape(p.version) + "</string>\n"
        "\t<key>CFBundleVersion</key><string>" + xml_escape(p.version) + "</string>\n";
    if (hasIcon) plist += "\t<key>CFBundleIconFile</key><string>AppIcon</string>\n";
    plist += "\t<key>LSMinimumSystemVersion</key><string>" + xml_escape(m.minimumSystemVersion) + "</string>\n"
             "\t<key>NSHighResolutionCapable</key><true/>\n"
             "\t<key>LSApplicationCategoryType</key><string>" + xml_escape(m.category) + "</string>\n";
    if (!m.copyright.empty()) plist += "\t<key>NSHumanReadableCopyright</key><string>" + xml_escape(m.copyright) + "</string>\n";
    return plist + "</dict>\n</plist>\n";
}

// A value of a .desktop file: backslash, newline and tab are escaped (Desktop Entry Specification, "Value types").
std::string desktop_entry_value(const std::string& s) {
    std::string o;
    for (char c : s) {
        if (c == '\\') o += "\\\\";
        else if (c == '\n') o += "\\n";
        else if (c == '\t') o += "\\t";
        else if (c == '\r') o += "\\r";
        else o += c;
    }
    return o;
}

// <slug>.desktop: the entry that puts the game in the application menu of a Linux desktop. `Exec` and `Icon` are the bare
// names; installing the file (nextSteps) points them at the real folder.
std::string linux_desktop_file(const Project& p, const std::string& slug, bool hasIcon) {
    std::string categories;
    for (std::string c : p.settings.linux.categories) {
        c.erase(std::remove_if(c.begin(), c.end(), [](char ch) { return ch == ';' || ch == '\n' || ch == '\r'; }), c.end());
        if (!c.empty()) categories += c + ";";
    }
    std::string out = "[Desktop Entry]\nType=Application\nName=" + desktop_entry_value(p.name) + "\nExec=" + slug + "\n";
    if (hasIcon) out += "Icon=" + slug + "\n";
    out += "Terminal=false\n";
    if (!categories.empty()) out += "Categories=" + categories + "\n";
    return out;
}

Result<void> write_binary(const stdfs::path& path, const std::vector<std::uint8_t>& bytes) {
    std::string e;
    if (!write_file(path, std::string_view(reinterpret_cast<const char*>(bytes.data()), bytes.size()), &e)) return err("export: " + e);
    return {};
}

// Puts the player at `dest`. A Windows export writes the game into the exe's resources (pe_icon.h): its icon, when it
// has one, and its name, version and file name (the version information Explorer and Task Manager show). A player that
// cannot take them is copied as it is, with a warning. `signatureRemoved` tells that the patch cut the exe's signature.
Result<void> install_player(const Project& p, const stdfs::path& player, const stdfs::path& dest, const std::string& platform,
                            const Image& icon, ExportReport& report, bool& signatureRemoved) {
    std::error_code ec;
    if (platform == "windows") {
        if (auto data = read_file(player)) {
            std::vector<std::uint8_t> bytes(data->begin(), data->end());
            data.reset();
            bool changed = false;
            const std::string newer = " Use the factoria_player.exe of this FactorIA version.";
            if (!icon.empty()) {
                const std::string keeps = " The exe keeps the player's own icon; the window still shows the game's icon at run time.";
                auto patched = patch_pe_icon(bytes, icon);
                if (patched.ok() && patched->replaced > 0) {
                    changed = true;
                    signatureRemoved = signatureRemoved || patched->signatureRemoved;
                } else {
                    report.warnings.push_back(patched.ok() ? "The player " + generic(player) + " has no placeholder icon to replace (it was "
                                                                 "built without player/windows/factoria_player.rc)." + keeps + newer
                                                           : patched.error().message + "." + keeps + " " + patched.error().hint);
                }
            }
            PeVersionInfo info;
            info.version = p.version;
            info.strings = {{"FileDescription", p.name},  {"ProductName", p.name},
                            {"FileVersion", p.version},   {"ProductVersion", p.version},
                            {"InternalName", dest.stem().string()}, {"OriginalFilename", dest.filename().string()}};
            auto version = patch_pe_version(bytes, info);
            if (version.ok() && version->found) {
                changed = true;
                signatureRemoved = signatureRemoved || version->signatureRemoved;
                for (const std::string& key : version->truncated)
                    report.warnings.push_back("The " + key + " of the exe's version information is cut short: '" + info.strings[key] +
                                              "' is longer than the room the player has for it (79 characters for names, 31 for "
                                              "versions). Use a shorter `name` or `version` in factoria.json.");
            } else if (version.ok()) {
                report.warnings.push_back("The player " + generic(player) + " has no version information to fill in, so Windows shows "
                                          "the exe's file name instead of the game's name and version." + newer);
            } else if (icon.empty()) {  // with an icon, the icon's warning already says what is wrong with the file
                report.warnings.push_back(version.error().message + ". " + version.error().hint);
            }
            if (changed) return write_binary(dest, bytes);
        }
    }
    stdfs::copy_file(os_path(player), os_path(dest), stdfs::copy_options::overwrite_existing, ec);
    if (ec) return err("export: cannot copy the player to " + generic(dest) + ": " + ec.message());
    return {};
}

}  // namespace

std::string fs_safe_name(const std::string& s) {
    std::string o;
    for (char c : s) o += (std::strchr("/\\:*?\"<>|", c) || static_cast<unsigned char>(c) < 32) ? '_' : c;
    while (!o.empty() && (o.back() == ' ' || o.back() == '.')) o.pop_back();
    return o.empty() ? "Game" : o;
}

// Seals an exported .app with an ad hoc signature; returns "" or what went wrong. The executable inside is a copy of
// factoria_player, which a release download carries signed with FactorIA's Developer ID. That signature covers the
// executable alone, so the finished bundle (its Info.plist, the game files) would fail `codesign --verify` ("code has
// no resources but signature indicates they must be present"), and a Mac that downloads such an app calls it damaged
// instead of offering Open Anyway. Signed as a whole, ad hoc, the bundle is valid and runs on this Mac; to share the
// game, its developer signs it with their own Developer ID (nextSteps, docs/EXPORTING.md).
std::string sign_app_ad_hoc(const stdfs::path& app) {
#if defined(__APPLE__)
    const std::string cmd = "/usr/bin/codesign --force --sign - --timestamp=none " + sh_quote(app.string()) + " 2>&1";
    FILE* pipe = popen(cmd.c_str(), "r");
    if (!pipe) return "could not run /usr/bin/codesign";
    std::string out;
    char buf[512];
    while (std::fgets(buf, sizeof buf, pipe)) out += buf;
    const int status = pclose(pipe);
    if (status == 0) return {};
    while (!out.empty() && (out.back() == '\n' || out.back() == '\r')) out.pop_back();
    return out.empty() ? "codesign failed" : out;
#else
    (void)app;
    return "codesign runs only on macOS";
#endif
}

Result<void> export_desktop(const Project& p, const std::string& platform, const stdfs::path& player, const stdfs::path& outRoot,
                            const std::vector<std::string>& files, const Image& icon, ExportReport& report) {
    const std::string slug = slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-');
    const std::string exeName = slug + (platform == "windows" ? ".exe" : "");
    std::error_code ec;
    stdfs::path exeDest, gameDest;
    if (platform == "macos") {
        stdfs::path app = outRoot / (fs_safe_name(p.name) + ".app") / "Contents";
        exeDest = app / "MacOS" / exeName;
        gameDest = app / "Resources" / "game";
        if (auto r = write_text(app / "Info.plist", macos_plist(p, exeName, !icon.empty())); !r.ok()) return r.error();
        if (!icon.empty())
            if (auto r = write_binary(app / "Resources" / "AppIcon.icns", make_icns(icon)); !r.ok()) return r;
    } else {
        exeDest = outRoot / exeName;
        gameDest = outRoot / "game";
    }
    stdfs::create_directories(os_path(exeDest.parent_path()), ec);
    bool signatureRemoved = false;
    if (auto r = install_player(p, player, exeDest, platform, icon, report, signatureRemoved); !r.ok()) return r;
    stdfs::permissions(os_path(exeDest), stdfs::perms::owner_exec | stdfs::perms::group_exec | stdfs::perms::others_exec,
                       stdfs::perm_options::add, ec);
    if (auto r = copy_game(p, files, gameDest); !r.ok()) return r;

    if (platform == "macos") {
        stdfs::path app = stdfs::path(fs_safe_name(p.name) + ".app");
        report.nextSteps = {
            "Run it: open '" + generic(outRoot / app) + "'",
            "To distribute outside your machine, sign and notarize the app: codesign --force --deep --options runtime "
            "--timestamp --sign \"Developer ID Application: <you>\" '" + app.string() + "', then xcrun notarytool "
            "submit and xcrun stapler staple (see docs/EXPORTING.md)",
            "Zip it for sharing: ditto -c -k --keepParent '" + app.string() + "' " + slug + "-macos.zip"};
    } else if (platform == "windows") {
        report.nextSteps = {"Run it: " + exeName + " (from " + generic(outRoot) + ")",
                            "Zip the folder '" + generic(outRoot.filename()) + "' to share it; keep game/ next to the exe"};
        if (signatureRemoved)
            report.nextSteps.push_back("The exe's digital signature was removed because the export wrote the game's icon, name and "
                                       "version into it (the player of the FactorIA download is signed with FactorIA's certificate). "
                                       "Windows may show 'unknown publisher'; sign the exe with your own certificate to publish it: "
                                       "signtool sign /fd SHA256 /a /tr <timestamp server URL> /td SHA256 " + exeName);
    } else {
        if (!icon.empty())
            if (auto r = write_png_icon(generic(outRoot / (slug + ".png")), icon, 256); !r.ok()) return r;
        if (auto r = write_text(outRoot / (slug + ".desktop"), linux_desktop_file(p, slug, !icon.empty())); !r.ok()) return r;
        report.nextSteps = {"Run it: " + generic(outRoot / exeName),
                            "To add it to the application menu, run this in the folder where the game will live: sed -e "
                            "\"s|^Exec=.*|Exec=$PWD/" + exeName + "|\" -e \"s|^Icon=.*|Icon=$PWD/" + slug + ".png|\" " + slug +
                                ".desktop > ~/.local/share/applications/" + slug + ".desktop (" + slug + ".desktop names the game, "
                                "its categories and its icon)",
                            "Archive to share: tar czf " + outRoot.filename().string() + ".tar.gz -C " +
                                generic(outRoot.parent_path()) + " " + outRoot.filename().string()};
    }
    return {};
}

}  // namespace fa::export_detail
