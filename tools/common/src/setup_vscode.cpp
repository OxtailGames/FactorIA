// `setup vscode`: the VS Code extension of the script debugger (tools/vscode/, embedded in factoria; docs/DEBUGGING.md).
//
//   <user home>/.vscode/extensions/oxtailgames.factoria-<version>/   package.json (version stamped), extension.js, README.md,
//                                                                    factoria-path.txt (the absolute path of this factoria)
//
// The same folder goes into the extensions folder of VS Code Insiders (.vscode-insiders), VSCodium (.vscode-oss) and Cursor
// (.cursor) when that editor has a folder in the user's home. Older oxtailgames.factoria-* folders are removed. Nothing is
// downloaded: the extension is part of the binary, so the copy always matches the installed engine.
#include <fstream>

#include "fa/core/json.h"
#include "fa/tooling/bundle.h"
#include "setup_internal.h"
#include "util.h"

namespace fa::setup_detail {

namespace {

constexpr const char* kPrefix = "oxtailgames.factoria-";
constexpr const char* kPathFile = "factoria-path.txt";
constexpr const char* kEmbeddedDir = "tools/vscode/";

struct EditorTarget {
    std::string label;  // "Visual Studio Code"
    std::string dir;    // ".vscode"
    bool always;        // VS Code: the folder is created; the others only when they exist
};

const std::vector<EditorTarget>& editor_targets() {
    static const std::vector<EditorTarget> t = {{"Visual Studio Code", ".vscode", true},
                                                {"VS Code Insiders", ".vscode-insiders", false},
                                                {"VSCodium", ".vscode-oss", false},
                                                {"Cursor", ".cursor", false}};
    return t;
}

stdfs::path user_home(const SetupContext& ctx) {
    if (!ctx.env) return {};
#if defined(_WIN32)
    if (std::string h = ctx.env("USERPROFILE"); !h.empty()) return h;
#endif
    return ctx.env("HOME");
}

stdfs::path extensions_dir(const stdfs::path& home, const EditorTarget& t) { return home / t.dir / "extensions"; }

// The editors this install covers: VS Code always, the others when their folder exists.
std::vector<const EditorTarget*> active_targets(const stdfs::path& home) {
    std::vector<const EditorTarget*> out;
    for (const EditorTarget& t : editor_targets())
        if (!home.empty() && (t.always || is_dir(home / t.dir))) out.push_back(&t);
    return out;
}

std::string extension_folder_name(const SetupContext& ctx) { return std::string(kPrefix) + ctx.version(); }

// This factoria, the one the extension starts: factoria next to the running executable (the editor ships it next to itself).
stdfs::path factoria_exe(const SetupContext& ctx) { return exe_dir(ctx) / ("factoria" + exe_suffix(ctx.host_os())); }

std::string read_text(const stdfs::path& p) {
    std::ifstream in(p, std::ios::binary);
    std::string s((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    while (!s.empty() && (s.back() == '\n' || s.back() == '\r' || s.back() == ' ')) s.pop_back();
    return s;
}

// "installed" (this version, pointing at this factoria), "stale" (this version, but the recorded factoria is another),
// "missing".
std::string copy_state(const SetupContext& ctx, const stdfs::path& folder) {
    if (!is_file(folder / "package.json") || !is_file(folder / "extension.js")) return "missing";
    const stdfs::path exe = factoria_exe(ctx);
    if (is_file(exe) && read_text(folder / kPathFile) != exe.string()) return "stale";
    return "installed";
}

}  // namespace

SetupComponent vscode_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "vscode";
    c.title = "Visual Studio Code debugger (the FactorIA extension)";
    c.canInstall = true;
    const stdfs::path home = user_home(ctx);
    const std::vector<const EditorTarget*> targets = active_targets(home);
    if (targets.empty()) {
        c.state = "missing";
        c.details = "Cannot find the user's home folder (HOME or USERPROFILE is not set), so there is nowhere to put the extension.";
        c.problems.push_back("Set HOME (USERPROFILE on Windows) and run `factoria setup vscode`.");
        return c;
    }
    int installed = 0, stale = 0;
    for (const EditorTarget* t : targets) {
        const stdfs::path folder = extensions_dir(home, *t) / extension_folder_name(ctx);
        const std::string s = copy_state(ctx, folder);
        if (s == "missing") {
            c.problems.push_back(t->label + " does not have the FactorIA extension " + ctx.version() + " (" + folder.string() + ").");
            continue;
        }
        ++installed;
        if (s == "stale") ++stale;
        c.paths.emplace_back(t->dir, folder.string());
    }
    if (installed == int(targets.size()) && stale == 0) {
        c.state = "installed";
        c.problems.clear();
        c.details = "The FactorIA extension " + ctx.version() + " is in the extensions folder of " + std::to_string(targets.size()) +
                    " editor" + (targets.size() == 1 ? "" : "s") + ". Press F5 in a project folder (docs/DEBUGGING.md).";
        return c;
    }
    c.state = installed == 0 ? "missing" : "partial";
    if (stale > 0) c.problems.push_back("The extension records another factoria than this one: install again so F5 starts this one.");
    c.details = "The install copies the FactorIA extension " + ctx.version() + " (built into factoria, nothing is downloaded) to " +
                (extensions_dir(home, editor_targets()[0]) / extension_folder_name(ctx)).string() +
                " and to the other VS Code based editors found, then removes older versions. Restart VS Code afterwards.";
    return c;
}

SetupResult vscode_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    Installer in(ctx, "vscode");
    const stdfs::path home = user_home(ctx);
    if (home.empty())
        return in.fail("failed", make_error("Cannot find the user's home folder: HOME (USERPROFILE on Windows) is not set.",
                                            "Set it to the folder that holds .vscode/ and run `factoria setup vscode` again."));

    // The embedded extension.
    std::vector<std::pair<std::string, std::string>> files;  // name -> content
    for (const std::string& path : bundled_list(kEmbeddedDir)) {
        const std::string rel = path.substr(std::string(kEmbeddedDir).size());
        if (rel.empty() || rel.find('/') != std::string::npos) continue;
        if (auto data = bundled_read(path)) files.emplace_back(rel, std::move(*data));
    }
    bool hasPackage = false, hasMain = false;
    for (auto& [name, data] : files) {
        if (name == "package.json") {
            hasPackage = true;
            Json j = Json::parse(data, nullptr, false);
            if (j.is_discarded() || !j.is_object())
                return in.fail("failed", make_error("The embedded tools/vscode/package.json is not valid JSON.", "This is a bug in this build of factoria."));
            j["version"] = ctx.version();
            data = j.dump(2) + "\n";
        } else if (name == "extension.js") {
            hasMain = true;
        }
    }
    if (!hasPackage || !hasMain)
        return in.fail("failed", make_error("This build of factoria does not carry the VS Code extension (tools/vscode/package.json and extension.js).",
                                            "Use an official download of FactorIA, or build from a checkout that has tools/vscode/."));

    const stdfs::path exe = factoria_exe(ctx);
    const bool exeExists = is_file(exe);
    const std::string folderName = extension_folder_name(ctx);
    const stdfs::path staged = in.make_staging_subdir(folderName);
    for (const auto& [name, data] : files) {
        std::string err;
        if (!tooling_detail::write_file(staged / name, data, &err)) return in.fail("failed", make_error(err));
    }
    if (exeExists) {
        std::string err;
        if (!tooling_detail::write_file(staged / kPathFile, exe.string() + "\n", &err)) return in.fail("failed", make_error(err));
    } else {
        in.report.warnings.push_back("There is no factoria next to " + exe_dir(ctx).string() +
                                     ", so the extension was not told where it is: it will run `factoria` from the PATH (or set \"factoriaPath\" in launch.json).");
    }

    for (const EditorTarget* t : active_targets(home)) {
        StepTimer stepTimer;
        SetupStep s;
        s.id = t->dir;
        s.title = t->label;
        const stdfs::path extDir = extensions_dir(home, *t);
        const stdfs::path dest = extDir / folderName;
        std::error_code ec;
        s.path = dest.string();
        if (!opt.force && copy_state(ctx, dest) == "installed") {
            s.outcome = "skipped";
            s.detail = "already installed";
        } else {
            stdfs::create_directories(extDir, ec);
            const stdfs::path incoming = extDir / (folderName + ".installing");
            stdfs::remove_all(incoming, ec);
            stdfs::copy(staged, incoming, stdfs::copy_options::recursive, ec);
            if (ec)
                return in.fail("failed", make_error("Cannot write " + incoming.string() + ": " + ec.message(),
                                                    "Check that the folder is writable and the disk is not full."));
            if (auto f = replace_dir(incoming, dest)) return in.fail(*f);
            s.outcome = "installed";
            s.detail = "extension " + ctx.version() + " copied";
        }
        // Older versions are no longer used (and VS Code would load the newest of them otherwise).
        std::vector<stdfs::path> old;
        for (stdfs::directory_iterator it(extDir, ec), end; !ec && it != end; it.increment(ec)) {
            const std::string name = it->path().filename().string();
            if (name.rfind(kPrefix, 0) == 0 && name != folderName && it->is_directory()) old.push_back(it->path());
        }
        for (const stdfs::path& p : old) {
            std::error_code rm;
            stdfs::remove_all(p, rm);
            if (!rm) s.detail += "; removed " + p.filename().string();
            else in.report.warnings.push_back("Could not remove the old extension " + p.string() + ": " + rm.message());
        }
        s.seconds = stepTimer.seconds();
        in.add_step(s);
        if (t->always) in.report.paths.emplace_back("extension", dest.string());
    }
    in.report.nextSteps.push_back("Restart VS Code (or run \"Developer: Reload Window\"), open a project folder and press F5. docs/DEBUGGING.md has the details.");
    return in.finish();
}

}  // namespace fa::setup_detail
