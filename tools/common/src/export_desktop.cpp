// Desktop exports (linux, windows, macos): the factoria_player runtime plus the game, and the .app bundle of macOS.
#include <cstdio>
#include <cstring>
#include <filesystem>

#include "export_internal.h"

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
    if (platform != host_platform())
        return err("export: cannot export for " + platform + " from a " + host_platform() +
                       " machine without a player binary built for " + platform,
                   "build factoria_player on " + platform + " (see docs/BUILDING.md) and pass it with --player <path>");
    stdfs::path dir = executable_dir();
    for (const stdfs::path& c : {dir / exe, dir.parent_path() / "player" / exe, dir.parent_path().parent_path() / "player" / exe})
        if (stdfs::is_regular_file(c, ec)) return c;
    return err("export: factoria_player not found next to the factoria binary (" + generic(dir) + ")",
               "build it with `cmake --build <build dir> --target factoria_player`, or pass --player <path>");
}

namespace {

std::string macos_plist(const Project& p, const std::string& exeName) {
    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
           "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
           "<plist version=\"1.0\">\n<dict>\n"
           "\t<key>CFBundleExecutable</key><string>" + xml_escape(exeName) + "</string>\n"
           "\t<key>CFBundleIdentifier</key><string>" + xml_escape(p.id.empty() ? "com.example.game" : p.id) + "</string>\n"
           "\t<key>CFBundleName</key><string>" + xml_escape(p.name) + "</string>\n"
           "\t<key>CFBundleDisplayName</key><string>" + xml_escape(p.name) + "</string>\n"
           "\t<key>CFBundlePackageType</key><string>APPL</string>\n"
           "\t<key>CFBundleShortVersionString</key><string>" + xml_escape(p.version) + "</string>\n"
           "\t<key>CFBundleVersion</key><string>" + xml_escape(p.version) + "</string>\n"
           "\t<key>LSMinimumSystemVersion</key><string>11.0</string>\n"
           "\t<key>NSHighResolutionCapable</key><true/>\n"
           "\t<key>LSApplicationCategoryType</key><string>public.app-category.games</string>\n"
           "</dict>\n</plist>\n";
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
                            const std::vector<std::string>& files, ExportReport& report) {
    const std::string slug = slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-');
    const std::string exeName = slug + (platform == "windows" ? ".exe" : "");
    std::error_code ec;
    stdfs::path exeDest, gameDest;
    if (platform == "macos") {
        stdfs::path app = outRoot / (fs_safe_name(p.name) + ".app") / "Contents";
        exeDest = app / "MacOS" / exeName;
        gameDest = app / "Resources" / "game";
        if (auto r = write_text(app / "Info.plist", macos_plist(p, exeName)); !r.ok()) return r.error();
    } else {
        exeDest = outRoot / exeName;
        gameDest = outRoot / "game";
    }
    stdfs::create_directories(exeDest.parent_path(), ec);
    stdfs::copy_file(player, exeDest, stdfs::copy_options::overwrite_existing, ec);
    if (ec) return err("export: cannot copy the player to " + generic(exeDest) + ": " + ec.message());
    stdfs::permissions(exeDest, stdfs::perms::owner_exec | stdfs::perms::group_exec | stdfs::perms::others_exec,
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
    } else {
        report.nextSteps = {"Run it: " + generic(outRoot / exeName),
                            "Archive to share: tar czf " + outRoot.filename().string() + ".tar.gz -C " +
                                generic(outRoot.parent_path()) + " " + outRoot.filename().string()};
    }
    return {};
}

}  // namespace fa::export_detail
