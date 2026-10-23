// Desktop exports (linux, windows, macos): the factoria_player runtime plus the game, the .app bundle of macOS, and the
// game's icon in the form each platform wants it (docs/EXPORTING.md, "Desktop").
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <filesystem>

#include <cctype>

#include "export_internal.h"
#include "fa/core/build_info.h"
#include "fa/core/pack.h"
#include "fa/script/bytecode.h"
#include "fa/tooling/icons.h"
#include "fa/tooling/pe_icon.h"
#include "fa/tooling/plugin_manifest.h"
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

// True for the first bytes of a Windows (MZ), Linux (ELF) or macOS (Mach-O, fat) executable.
bool looks_like_executable(const std::string& head) {
    if (head.size() < 4) return false;
    const auto b = [&](std::size_t i) { return static_cast<unsigned char>(head[i]); };
    if (b(0) == 'M' && b(1) == 'Z') return true;
    if (b(0) == 0x7f && b(1) == 'E' && b(2) == 'L' && b(3) == 'F') return true;
    const std::uint32_t magic = static_cast<std::uint32_t>(b(0)) << 24 | b(1) << 16 | b(2) << 8 | b(3);
    return magic == 0xFEEDFACEu || magic == 0xFEEDFACFu || magic == 0xCEFAEDFEu || magic == 0xCFFAEDFEu || magic == 0xCAFEBABEu;
}

}  // namespace

Result<void> check_player_build(const ExportOptions& o, const stdfs::path& player, const std::string& platform,
                                std::vector<std::string>& warnings) {
    const std::string mine = build_fingerprint();
    if (mine == "unknown") return {};
    auto data = read_file(player);
    if (!data || !looks_like_executable(std::string(data->substr(0, 4)))) return {};
    const std::string theirs = find_build_fingerprint(*data);
    if (theirs == mine) return {};
    const std::string what = theirs.empty() ? "has no build fingerprint (it is older than this check)" : "was built from " + theirs;
    const std::string message = "export: the " + platform + " player '" + generic(player) + "' " + what + ", but this factoria was built from " + mine +
                                ": a player of another build may lack what the game uses (components, script API) or fail to start";
    if (o.allowPlayerMismatch) {
        warnings.push_back(message + " (exported anyway because allowPlayerMismatch / --allow-player-mismatch is on)");
        return {};
    }
    return err(message,
               "Build both from the same checkout (`cmake --build <build dir> --target factoria factoria_player`), or for another OS run "
               "`factoria setup players` (the player of this FactorIA version), or pass the matching player with --player <path>. To bundle this "
               "player anyway: factoria export --allow-player-mismatch (export command: \"allowPlayerMismatch\": true).");
}

namespace {

// Info.plist of the .app. The keys the settings decide (export.macos in factoria.json): LSApplicationCategoryType,
// LSMinimumSystemVersion, NSHumanReadableCopyright, CFBundleVersion (buildNumber), ITSAppUsesNonExemptEncryption; the icon is Contents/Resources/AppIcon.icns, named by CFBundleIconFile.
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
        "\t<key>CFBundleVersion</key><string>" + xml_escape(p.settings.macos_build_number().empty() ? p.version : p.settings.macos_build_number()) + "</string>\n"
        "\t<key>ITSAppUsesNonExemptEncryption</key>" + (m.usesNonExemptEncryption ? "<true/>" : "<false/>") + "\n";
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

// <slug>.desktop: the entry that puts the game in the application menu of a Linux desktop. `Exec` (the executable) and `Icon`
// (the slug) are bare names; installing the file (nextSteps) points them at the real folder.
std::string linux_desktop_file(const Project& p, const std::string& slug, const std::string& exeName, bool hasIcon) {
    std::string categories;
    for (std::string c : p.settings.linux.categories) {
        c.erase(std::remove_if(c.begin(), c.end(), [](char ch) { return ch == ';' || ch == '\n' || ch == '\r'; }), c.end());
        if (!c.empty()) categories += c + ";";
    }
    std::string out = "[Desktop Entry]\nType=Application\nName=" + desktop_entry_value(p.name) + "\nExec=" + exeName + "\n";
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

// The release build: every file of the game goes into ONE pack (fa/core/pack.h, read through fa::fs), no loose files. A
// script becomes QuickJS bytecode when export.scriptBytecode is on (fa/script/bytecode.h); the module keeps its path in the
// pack, so nothing in the game changes. A script that does not compile is packed as the source it is, with a warning: the
// game then behaves exactly as it does when run from the folder (the error shows when something loads that script).
Result<void> pack_game(const Project& p, const std::vector<std::string>& files, const stdfs::path& packFile, ExportReport& report) {
    PackWriter writer;
    for (const std::string& f : files) {
        const auto staged = p.staged.find(f);
        const stdfs::path from = staged != p.staged.end() ? staged->second : p.dir / f;
        const std::string ext = fs::extension(f);
        if (p.settings.scriptBytecode && (ext == ".js" || ext == ".mjs")) {
            auto source = read_file(from);
            if (!source) return err("export: cannot read '" + f + "' to pack it (" + generic(from) + ")");
            auto bytecode = compile_script_bytecode(*source, f);
            if (bytecode.ok()) {
                if (auto r = writer.add_bytes(f, std::move(bytecode.value())); !r.ok()) return err("export: " + r.error().message, r.error().hint);
                continue;
            }
            report.warnings.push_back(bytecode.error().message + " - '" + f + "' is packed as plain source, so the game reports this error "
                                      "when it loads the script (`factoria validate` lists the syntax errors of a project)");
        }
        if (auto r = writer.add_file(f, from); !r.ok()) return err("export: " + r.error().message, r.error().hint);
    }
    std::error_code ec;
    stdfs::create_directories(os_path(packFile.parent_path()), ec);
    if (auto r = writer.write(packFile); !r.ok()) return err("export: " + r.error().message, r.error().hint);
    report.pack = generic(packFile.filename());
    report.packed = files;
    return {};
}

}  // namespace

Result<void> pack_project(const Project& p, const std::vector<std::string>& files, const stdfs::path& packFile, ExportReport& report) {
    return pack_game(p, files, packFile, report);
}

// The entitlements of a signed macOS app, from the plugins' manifests: Xcode's build settings ($(TeamIdentifierPrefix),
// $(CFBundleIdentifier)) filled in as codesign needs them, plus the two identifiers a provisioning profile ties them to. The
// Team ID is export.ios.teamId when set (one team signs a developer's apps), else the placeholder TEAMID to replace.
static Json macos_entitlements(const Json& asked, const Project& p) {
    if (asked.empty()) return Json::object();
    std::string team;
    for (char c : p.settings.ios.teamId) if (std::isalnum(static_cast<unsigned char>(c))) team += c;
    if (team.empty()) team = "TEAMID";
    Json out = Json::object();
    out["com.apple.application-identifier"] = team + "." + p.id;
    out["com.apple.developer.team-identifier"] = team;
    for (auto it = asked.begin(); it != asked.end(); ++it) {
        if (it->is_string())
            out[it.key()] = replace_all(replace_all(it->get<std::string>(), "$(TeamIdentifierPrefix)", team + "."), "$(CFBundleIdentifier)", p.id);
        else
            out[it.key()] = it.value();
    }
    return out;
}

std::string fs_safe_name(const std::string& s) {
    std::string o;
    for (char c : s) o += (std::strchr("/\\:*?\"<>|", c) || static_cast<unsigned char>(c) < 32) ? '_' : c;
    while (!o.empty() && (o.back() == ' ' || o.back() == '.')) o.pop_back();
    return o.empty() ? "Game" : o;
}

std::string desktop_exe_name(const std::string& slug, const std::string& platform) {
    if (platform == "windows") return slug + ".exe";
    return platform == "linux" && slug == "game" ? "game-bin" : slug;
}

// Seals an exported .app with an ad hoc signature; returns "" or what went wrong. The executable inside is a copy of
// factoria_player, which a release download carries signed with FactorIA's Developer ID. That signature covers the
// executable alone, so the finished bundle (its Info.plist, the game files) would fail `codesign --verify` ("code has
// no resources but signature indicates they must be present"), and a Mac that downloads such an app calls it damaged
// instead of offering Open Anyway. Signed as a whole, ad hoc, the bundle is valid and runs on this Mac; to share the
// game, its developer signs it with their own Developer ID (nextSteps, docs/EXPORTING.md).
std::string sign_app_ad_hoc(const stdfs::path& app) {
#if defined(__APPLE__)
    // --deep: the native plugins in Contents/Frameworks are signed too.
    const std::string cmd = "/usr/bin/codesign --force --deep --sign - --timestamp=none " + sh_quote(app.string()) + " 2>&1";
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

Result<void> export_desktop(const ExportOptions& options, const Project& p, const std::string& platform, const stdfs::path& player,
                            const stdfs::path& outRoot, const std::vector<std::string>& files, const Image& icon, ExportReport& report) {
    const std::string slug = slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-');
    const std::string exeName = desktop_exe_name(slug, platform);
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
    // The pack sits where the game/ folder would: next to the executable, in Contents/Resources of a macOS app.
    const stdfs::path packFile = gameDest.parent_path() / kPackFileName;
    if (options.release) {
        if (auto r = pack_game(p, files, packFile, report); !r.ok()) return r;
    } else if (auto r = copy_game(p, files, gameDest); !r.ok()) {
        return r;
    }
    // Native plugins: their build folder (the library and the ones it needs) next to the executable, where the player
    // looks for them; inside a macOS app that is Contents/Frameworks.
    const stdfs::path libDest = platform == "macos" ? exeDest.parent_path().parent_path() / "Frameworks" : exeDest.parent_path();
    std::vector<NamedManifest> manifests;
    for (const Project::Plugin& plugin : p.plugins) {
        stdfs::create_directories(os_path(libDest), ec);
        stdfs::copy(os_path(plugin.build), os_path(libDest),
                    stdfs::copy_options::recursive | stdfs::copy_options::overwrite_existing | stdfs::copy_options::copy_symlinks, ec);
        if (ec) return err("export: cannot copy the plugin '" + plugin.name + "' (" + generic(plugin.build) + ") to " +
                           generic(libDest) + ": " + ec.message());
        // plugin.json tells the export what the app needs (fa/tooling/plugin_manifest.h); the player never reads it.
        if (stdfs::exists(os_path(plugin.build / kPluginManifestFile), ec)) {
            stdfs::remove(os_path(libDest / kPluginManifestFile), ec);
            if (platform == "macos") {
                auto manifest = read_plugin_manifest(plugin.build);
                if (!manifest.ok())
                    return err("export: the manifest of the plugin '" + plugin.name + "': " + manifest.error().message, manifest.error().hint);
                manifests.push_back({plugin.name, manifest.value()});
            }
        }
    }
    // Capabilities the plugins ask for (Game Center, iCloud): they go into the signature, which needs the developer's own
    // certificate and provisioning profile. The ad hoc signature below cannot carry them (macOS kills an app that claims a
    // restricted entitlement without a profile), so they are written next to the app for the developer's signing step.
    std::string entitlementsFile;
    Json entitlements = Json::object();
    if (!manifests.empty()) {
        auto merged = merge_plugin_manifests(manifests);
        if (!merged.ok()) return err("export: " + merged.error().message, merged.error().hint);
        entitlements = macos_entitlements(merged->entitlements, p);
        if (!entitlements.empty()) {
            entitlementsFile = slug + ".entitlements";
            if (auto r = write_text(outRoot / entitlementsFile, entitlements_plist(entitlements)); !r.ok()) return r;
        }
    }

    if (platform == "macos") {
        stdfs::path app = stdfs::path(fs_safe_name(p.name) + ".app");
        report.nextSteps = {
            "Run it: open '" + generic(outRoot / app) + "'",
            "To distribute outside your machine, sign it with your Developer ID and have Apple notarize it, on a Mac: factoria call sign.macos "
            "'{\"identity\":\"Developer ID Application: <you> (TEAMID)\",\"keychainProfile\":\"<notarytool profile>\"}' signs the app and its plugin "
            "libraries, notarizes it, staples the ticket and writes " + slug + "-macos.zip to share; add \"dryRun\":true to see the commands first "
            "(docs/EXPORTING.md, \"Signing and notarizing for macOS\")",
            "For the Mac App Store: sign.macos with \"distribution\":\"appStore\" sandboxes the app, signs it for the store and writes " + slug +
            "-macos.pkg, which publish.appstore uploads (export.macos.buildNumber / usesNonExemptEncryption / entitlements are the store's settings; "
            "docs/EXPORTING.md, \"Mac App Store\")"};
        if (!entitlementsFile.empty()) {
            std::vector<std::string> names;
            for (auto it = entitlements.begin(); it != entitlements.end(); ++it) names.push_back(it.key());
            report.nextSteps.push_back(
                "The plugins ask for capabilities (" + join(names, ", ") + "), which only a signature with your Apple developer "
                "certificate and a provisioning profile can carry: until then the app runs and those services answer 'unavailable' with "
                "a hint. To turn them on: create a macOS provisioning profile for the App ID " + p.id + " with the same capabilities in the "
                "Apple Developer portal, replace TEAMID in " + entitlementsFile + " with your 10-character Team ID (or set export.ios.teamId "
                "in factoria.json and export again), and sign with sign.macos passing \"provisioningProfile\": the path of the profile file; "
                "it embeds the profile and applies " + entitlementsFile + " (docs/PLATFORM.md, section Apple)");
        }
    } else if (platform == "windows") {
        report.nextSteps = {"Run it: " + exeName + " (from " + generic(outRoot) + ")",
                            "Zip the folder '" + generic(outRoot.filename()) + "' to share it; keep " +
                                (options.release ? std::string(kPackFileName) : std::string("game/")) + " next to the exe"};
        if (signatureRemoved)
            report.nextSteps.push_back("The exe's digital signature was removed because the export wrote the game's icon, name and "
                                       "version into it (the player of the FactorIA download is signed with FactorIA's certificate). "
                                       "Windows may show 'unknown publisher'; sign the exe with your own certificate to publish it: "
                                       "signtool sign /fd SHA256 /a /tr <timestamp server URL> /td SHA256 " + exeName);
    } else {
        if (!icon.empty())
            if (auto r = write_png_icon(generic(outRoot / (slug + ".png")), icon, 256); !r.ok()) return r;
        if (auto r = write_text(outRoot / (slug + ".desktop"), linux_desktop_file(p, slug, exeName, !icon.empty())); !r.ok()) return r;
        report.nextSteps = {"Run it: " + generic(outRoot / exeName),
                            "To add it to the application menu, run this in the folder where the game will live: sed -e "
                            "\"s|^Exec=.*|Exec=$PWD/" + exeName + "|\" -e \"s|^Icon=.*|Icon=$PWD/" + slug + ".png|\" " + slug +
                                ".desktop > ~/.local/share/applications/" + slug + ".desktop (" + slug + ".desktop names the game, "
                                "its categories and its icon)",
                            "Archive to share: tar czf " + outRoot.filename().string() + ".tar.gz -C " +
                                generic(outRoot.parent_path()) + " " + outRoot.filename().string()};
    }
    if (options.release)
        report.nextSteps.push_back(std::string("The whole game is in ") + kPackFileName + " (" + std::to_string(files.size()) + " files" +
                                   (p.settings.scriptBytecode ? ", scripts compiled to bytecode" : ", scripts as source") + "), next to the " +
                                   (platform == "macos" ? "app's executable inside the .app" : "executable") +
                                   "; there is no game/ folder. Ship them together");
    return {};
}

}  // namespace fa::export_detail
