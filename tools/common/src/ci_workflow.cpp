// project.new_ci_workflow: the GitHub Actions workflow of a game project. Behaviour: fa/tooling/ci_workflow.h and docs/EXPORTING.md
// ("CI for your game"). The workflow text is a fixed template with the version, the repository, the platforms and the working
// directory filled in; tests/ci_workflow_test.cpp checks its key steps.
#include "fa/tooling/ci_workflow.h"

#include <algorithm>
#include <filesystem>
#include <regex>

#include "export_internal.h"
#include "fa/core/strings.h"
#include "fa/tooling/export.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/setup_parse.h"
#include "util.h"

#ifndef FA_UPDATE_REPO
#define FA_UPDATE_REPO ""
#endif
#ifndef FA_ENGINE_VERSION
#define FA_ENGINE_VERSION "0.0.0"
#endif

namespace fa {

namespace {

namespace stdfs = std::filesystem;
using export_detail::generic;
using export_detail::os_path;

Error err(std::string message, std::string hint = {}) { return Error{std::move(message), std::move(hint)}; }

bool has(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

// Every line of `text` indented by `n` spaces (blank lines stay blank).
std::string indent(const std::string& text, int n) {
    const std::string pad(static_cast<std::size_t>(n), ' ');
    std::string out;
    for (std::size_t pos = 0; pos < text.size();) {
        std::size_t nl = text.find('\n', pos);
        if (nl == std::string::npos) nl = text.size();
        if (nl > pos) out += pad + text.substr(pos, nl - pos);
        out += '\n';
        pos = nl + 1;
    }
    return out;
}

// The shell of the "Install FactorIA" step: downloads the package of $FACTORIA_VERSION ("latest" = the newest release), checks it
// against the SHA-256 GitHub lists for the release asset, unpacks it and puts it on PATH. Runs on Linux and macOS runners (bash,
// curl, tar and python3 are on both).
std::string install_script(const std::string& asset) {
    std::string s = R"(asset="@ASSET@"
if [ "$FACTORIA_VERSION" = latest ]; then
  url="https://github.com/$FACTORIA_REPO/releases/latest/download/$asset"
  api="https://api.github.com/repos/$FACTORIA_REPO/releases/latest"
else
  url="https://github.com/$FACTORIA_REPO/releases/download/v$FACTORIA_VERSION/$asset"
  api="https://api.github.com/repos/$FACTORIA_REPO/releases/tags/v$FACTORIA_VERSION"
fi
curl -fsSL --retry 3 -o "$RUNNER_TEMP/$asset" "$url"
curl -fsSL --retry 3 ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} -H "Accept: application/vnd.github+json" -o "$RUNNER_TEMP/release.json" "$api"
python3 - "$RUNNER_TEMP/release.json" "$RUNNER_TEMP/$asset" "$asset" <<'PY'
import hashlib, json, sys
release, archive, name = sys.argv[1:4]
digest = next((a.get("digest") or "" for a in json.load(open(release))["assets"] if a["name"] == name), "")
actual = hashlib.sha256(open(archive, "rb").read()).hexdigest()
if not digest.startswith("sha256:"):
    print("::warning::GitHub lists no SHA-256 for " + name + ", so the download was not verified")
elif digest[7:] != actual:
    print("::error::" + name + " does not match the SHA-256 GitHub lists for it")
    sys.exit(1)
PY
mkdir -p "$HOME/factoria"
tar -xzf "$RUNNER_TEMP/$asset" -C "$HOME/factoria" --strip-components=1
echo "$HOME/factoria" >> "$GITHUB_PATH"
"$HOME/factoria/factoria" version
)";
    return replace_all(std::move(s), "@ASSET@", asset);
}

std::string install_step(const std::string& asset) {
    return "      - name: Install FactorIA\n"
           "        env:\n"
           "          GITHUB_TOKEN: ${{ github.token }}\n"
           "        run: |\n" +
           indent(install_script(asset), 10);
}

// The step that collects the exports of `platforms` into dist/: a zip for Windows, a tar.gz for the others (a tar keeps the
// executable bit of the Linux game and the macOS app, which an artifact zip would lose).
std::string pack_step(const std::vector<std::string>& platforms, const std::string& title) {
    std::string list;
    for (const std::string& p : platforms) list += (list.empty() ? "" : " ") + p;
    std::string s = "mkdir -p dist\n"
                    "for platform in " + list + "; do\n"
                    "  folder=\"$(ls -d build/export/*-\"$platform\")\"\n"
                    "  name=\"$(basename \"$folder\")\"\n";
    if (has(platforms, "windows"))
        s += "  if [ \"$platform\" = windows ]; then\n"
             "    (cd build/export && python3 -m zipfile -c \"../../dist/$name.zip\" \"$name\")\n"
             "  else\n"
             "    tar -czf \"dist/$name.tar.gz\" -C build/export \"$name\"\n"
             "  fi\n";
    else
        s += "  tar -czf \"dist/$name.tar.gz\" -C build/export \"$name\"\n";
    s += "done\n";
    return "      - name: " + title + "\n        run: |\n" + indent(s, 10);
}

std::string upload_step(const std::string& name, const std::string& prefix) {
    return "      - uses: actions/upload-artifact@v4\n"
           "        with:\n"
           "          name: " + name + "\n"
           "          path: " + prefix + "dist/*\n"
           "          if-no-files-found: error\n";
}

std::string find_game_root_warning(const stdfs::path& projectDir) {
    std::error_code ec;
    for (stdfs::path dir = projectDir; dir.has_parent_path() && dir.parent_path() != dir; dir = dir.parent_path()) {
        if (stdfs::exists(os_path(dir / ".git"), ec)) return dir == projectDir ? std::string() : generic(dir);
    }
    return {};
}

}  // namespace

std::string ci_workflow_yaml(const std::string& version, const std::string& repo, const std::vector<std::string>& platforms,
                             const std::string& workingDirectory) {
    const bool linux_ = has(platforms, "linux"), windows = has(platforms, "windows"), macos = has(platforms, "macos");
    std::vector<std::string> checked;  // the exports the Ubuntu job makes
    if (linux_) checked.push_back("linux");
    if (windows) checked.push_back("windows");
    const std::string prefix = workingDirectory == "." ? std::string() : workingDirectory + "/";

    std::string y = R"(# FactorIA checks for this game. Written by project.new_ci_workflow (factoria call project.new_ci_workflow).
#
# On every push to main or master and on every pull request:
#   check   installs FactorIA, validates the project, runs its tests headless (Mesa software rendering under Xvfb)@CHECK_EXPORTS@
@MACOS_COMMENT@# and keeps the exports as workflow artifacts (Actions > the run > Artifacts).
#
# FACTORIA_VERSION is the FactorIA this file was written for, downloaded from github.com/@REPO@/releases and checked
# against the SHA-256 GitHub lists for it. Change it to move the game to another version ("latest" = the newest release).
# Documentation: docs_read exporting ("CI for your game") or docs/EXPORTING.md of FactorIA.
name: FactorIA

on:
  push:
    branches: [main, master]
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

env:
  FACTORIA_VERSION: "@VERSION@"
  FACTORIA_REPO: "@REPO@"
@DEFAULTS@
jobs:
  check:
    name: Validate, test@CHECK_NAME@
    runs-on: ubuntu-24.04
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Install the libraries FactorIA needs (OpenGL, X11, audio, Xvfb)
        run: |
          sudo apt-get update
          sudo apt-get install -y --no-install-recommends xvfb libegl1 libopengl0 libx11-6 libxcursor1 libxi6 libasound2t64 libgl1-mesa-dri libegl-mesa0

)";
    y += install_step("FactorIA-linux-x64.tar.gz");
    y += R"(
      - name: Validate the project
        run: factoria validate

      - name: Run the tests
        run: xvfb-run -a factoria test
)";
    if (windows)
        y += "\n      - name: Download the Windows player\n        run: factoria setup players --platforms windows\n";
    for (const std::string& p : checked) {
        const std::string label = p == "linux" ? "Linux" : "Windows";
        y += "\n      - name: Export for " + label + "\n        run: factoria export --platform " + p + "\n";
    }
    if (!checked.empty()) {
        y += "\n" + pack_step(checked, "Pack the exports");
        y += "\n" + upload_step(linux_ && windows ? "exports-linux-windows" : (linux_ ? "export-linux" : "export-windows"), prefix);
    }
    if (macos) {
        y += "\n  macos:\n"
             "    name: Export for macOS\n"
             "    runs-on: macos-latest\n"
             "    timeout-minutes: 30\n"
             "    steps:\n"
             "      - uses: actions/checkout@v4\n\n";
        y += install_step("FactorIA-macos-universal.tar.gz");
        y += "\n      # The export seals the app ad hoc (it runs on this Mac). To sign it with your Developer ID and notarize it, import the\n"
             "      # certificate into a keychain here and run `factoria call sign.macos` (docs/EXPORTING.md, \"Signing and notarizing for macOS\").\n"
             "      - name: Export for macOS\n        run: factoria export --platform macos\n";
        y += "\n" + pack_step({"macos"}, "Pack the export");
        y += "\n" + upload_step("export-macos", prefix);
    }

    std::string checkExports, checkName = " and export";
    if (checked.empty()) {
        checkName = "";
    } else {
        checkExports = ",\n#           and exports the game for ";
        checkExports += linux_ && windows ? "Linux and Windows" : (linux_ ? "Linux" : "Windows");
    }
    y = replace_all(std::move(y), "@CHECK_EXPORTS@", checkExports);
    y = replace_all(std::move(y), "@CHECK_NAME@", checkName);
    y = replace_all(std::move(y), "@MACOS_COMMENT@", macos ? "#   macos   exports the game for macOS on a macOS runner (the app is sealed ad hoc there)\n" : "");
    y = replace_all(std::move(y), "@REPO@", repo);
    y = replace_all(std::move(y), "@VERSION@", version);
    y = replace_all(std::move(y), "@DEFAULTS@", workingDirectory == "." ? "" : "\ndefaults:\n  run:\n    working-directory: \"" + workingDirectory + "\"\n");
    return y;
}

Json CiWorkflowReport::to_json() const {
    Json j = Json::object();
    j["path"] = path;
    j["written"] = written;
    j["dryRun"] = dryRun;
    j["version"] = version;
    j["repo"] = repo;
    j["platforms"] = platforms;
    j["workflow"] = workflow;
    j["warnings"] = warnings;
    j["nextSteps"] = nextSteps;
    return j;
}

Result<CiWorkflowReport> write_ci_workflow(const CiWorkflowOptions& o) {
    const std::string who = "project.new_ci_workflow: ";
    if (o.projectDir.empty()) return err(who + "no project directory given", "pass the folder that contains factoria.json");
    std::error_code ec;
    const stdfs::path dir = stdfs::weakly_canonical(o.projectDir, ec);
    if (!stdfs::exists(os_path(dir / "factoria.json"), ec))
        return err(who + generic(dir / "factoria.json") + " not found", "run it on a game folder (the one containing factoria.json); create a game with `factoria new <dir>`");

    // ---- platforms
    std::vector<std::string> platforms;
    for (const std::string& name : o.platforms) {
        const std::string p = name.empty() ? std::string() : normalize_export_platform(name);
        if (p == "android" || p == "ios")
            return err(who + "'" + name + "' is not exported by this workflow",
                       "The workflow exports the desktop platforms (linux, windows, macos). A mobile export needs the Android SDK or Xcode: add a job of your own (docs/EXPORTING.md).");
        if (p.empty()) return err(who + "unknown platform '" + name + "'", did_you_mean(name, std::vector<std::string>{"linux", "windows", "macos"}));
        if (!has(platforms, p)) platforms.push_back(p);
    }
    if (platforms.empty()) platforms = {"linux", "windows", "macos"};
    {
        std::vector<std::string> ordered;
        for (const char* p : {"linux", "windows", "macos"})
            if (has(platforms, p)) ordered.push_back(p);
        platforms = ordered;
    }

    // ---- where the file goes
    std::string rel = o.path.empty() ? std::string(".github/workflows/factoria.yml") : o.path;
    std::replace(rel.begin(), rel.end(), '\\', '/');
    auto resolved = resolve_project_path(generic(dir), rel);
    if (!resolved.ok()) return err(who + "path: " + resolved.error().message, resolved.error().hint);
    const std::string relNormal = generic(stdfs::path(rel).lexically_normal());
    if (!starts_with(relNormal, ".github/workflows/") || !(ends_with(relNormal, ".yml") || ends_with(relNormal, ".yaml")) || relNormal.find('/', 18) != std::string::npos)
        return err(who + "path '" + rel + "' is not a workflow file: GitHub runs only .github/workflows/<name>.yml (or .yaml) of the repository",
                   "Use the default (.github/workflows/factoria.yml) or another file name in that folder.");

    // ---- the game's folder in the repository
    std::string wd = o.workingDirectory.empty() ? "." : o.workingDirectory;
    std::replace(wd.begin(), wd.end(), '\\', '/');
    while (wd.size() > 1 && wd.back() == '/') wd.pop_back();
    if (wd != ".") {
        static const std::regex safe("^[A-Za-z0-9._ -]+(/[A-Za-z0-9._ -]+)*$");
        if (!std::regex_match(wd, safe) || starts_with(wd, "/") || wd.find("..") != std::string::npos)
            return err(who + "workingDirectory '" + o.workingDirectory + "' is not a folder inside the repository",
                       "Use the game's folder relative to the repository root, e.g. games/my-game: letters, digits, space . _ - and / only, no \"..\".");
    }

    // ---- the FactorIA version
    CiWorkflowReport rep;
    rep.dryRun = o.dryRun;
    rep.platforms = platforms;
    const std::string engineVersion = o.engineVersion ? *o.engineVersion : std::string(FA_ENGINE_VERSION);
    const std::string updateRepo = o.updateRepo ? *o.updateRepo : std::string(FA_UPDATE_REPO);
    const bool release = !updateRepo.empty();
    rep.repo = release ? updateRepo : std::string(kSetupReleaseRepo);
    static const std::regex repoName("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$");
    if (!std::regex_match(rep.repo, repoName)) return err(who + "the release repository '" + rep.repo + "' is not owner/name", "This is a bug in this build of FactorIA; report it.");
    if (!o.version.empty()) {
        static const std::regex semver("^[0-9]+\\.[0-9]+\\.[0-9]+([-+.][A-Za-z0-9.]+)?$");
        if (o.version != "latest" && !std::regex_match(o.version, semver))
            return err(who + "version '" + o.version + "' is not a FactorIA release", "Use \"latest\" or a version such as 0.1.6 (github.com/" + rep.repo + "/releases lists them).");
        rep.version = o.version;
    } else if (release) {
        rep.version = engineVersion;
    } else {
        rep.version = "latest";
        rep.warnings.push_back("This factoria (" + engineVersion + ") is a build from source and has no release of its own, so the workflow downloads the newest FactorIA release (FACTORIA_VERSION: \"latest\"). "
                               "Pin a version by passing `version` (e.g. \"0.1.6\") or editing FACTORIA_VERSION in the file.");
    }
    if (rep.version != "latest" && !o.version.empty() && release && rep.version != engineVersion)
        rep.warnings.push_back("The workflow downloads FactorIA " + rep.version + " but the factoria that wrote it is " + engineVersion + ": the game is checked and exported with another version than the one you edit it with.");

    // ---- the file
    rep.workflow = ci_workflow_yaml(rep.version, rep.repo, platforms, wd);
    rep.path = generic(*resolved);
    auto existing = tooling_detail::read_file(*resolved);
    const bool exists = stdfs::exists(os_path(*resolved), ec);
    const bool identical = existing && *existing == rep.workflow;
    if (exists && !identical && !o.overwrite && !o.dryRun)
        return err(who + rep.path + " already exists and differs from what would be written; it is left as it is",
                   "Pass overwrite: true to replace it, pass another file name in `path`, or run it with dryRun: true to see the new text first.");
    if (exists && !identical && !o.overwrite && o.dryRun)
        rep.warnings.push_back(rep.path + " already exists and differs: writing needs overwrite: true.");
    if (!o.dryRun && !identical) {
        std::string e;
        if (!tooling_detail::write_file(*resolved, rep.workflow, &e)) return err(who + e);
        rep.written = true;
    }
    if (identical) rep.warnings.push_back(rep.path + " is already up to date: nothing was written.");

    // ---- warnings and next steps
    if (const std::string repoRoot = find_game_root_warning(dir); !repoRoot.empty())
        rep.warnings.push_back("This project is inside the git repository at " + repoRoot + ", and GitHub runs workflows only from " + repoRoot + "/.github/workflows/. Move the file there and "
                               "pass workingDirectory (the game's folder relative to " + repoRoot + ") when you write it.");
    if (!o.dryRun || identical) {
        rep.nextSteps.push_back("Commit " + relNormal + " and push: the workflow runs on GitHub (Actions tab) on every push to main or master and on pull requests; the exports are its artifacts.");
        rep.nextSteps.push_back("The game must be in the repository as factoria.json at " + std::string(wd == "." ? "its root" : wd) + "; build/, .factoria/ and the editor's caches belong in .gitignore.");
    } else {
        rep.nextSteps.push_back("This was a dry run: call it again without dryRun to write " + relNormal + ".");
    }
    return rep;
}

void register_ci_workflow_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.new_ci_workflow";
    info.category = "project";
    info.readOnly = false;
    info.summary = "Write a GitHub Actions workflow that validates, tests and exports the game on every push.";
    info.description =
        "Writes .github/workflows/factoria.yml into the game's folder. On every push to main or master and every pull request it installs FactorIA on an Ubuntu 24.04 runner (the "
        "release package of the SAME version as this factoria, checked against the SHA-256 GitHub lists; a build from source has no release of its own, so it follows the newest one and "
        "warns), installs the OpenGL/X11/Xvfb libraries, runs `factoria validate` and `factoria test` under xvfb-run, downloads the other players (`factoria setup players`), exports the "
        "game for Linux and Windows, and on a macOS runner for macOS, and uploads the exports as workflow artifacts (tar.gz; the Windows one is a zip). It never overwrites a file that "
        "differs unless `overwrite` is true (an identical file is left alone). Project templates do not carry the file: call this when the game goes on GitHub. A game in a subfolder of "
        "the repository: GitHub reads workflows only from the repository root, so write it with `workingDirectory` set to that folder and move the file to <repo>/.github/workflows/. "
        "Returns {path, written, dryRun, version, repo, platforms[], workflow (the YAML), warnings[], nextSteps[]}. Details: docs_read {\"name\":\"exporting\"}, \"CI for your game\". "
        "Examples: {}, {\"platforms\":[\"linux\",\"windows\"],\"dryRun\":true}, {\"workingDirectory\":\"games/my-game\",\"overwrite\":true}.";
    info.inputSchema = Json::parse(R"({
      "type":"object",
      "properties":{
        "platforms":{"type":"array","items":{"type":"string"},"description":"Which exports the workflow makes: linux, windows, macos (aliases win, mac, osx also work). Default: all three."},
        "path":{"type":"string","description":"The workflow file, relative to the project: .github/workflows/<name>.yml. Default: .github/workflows/factoria.yml."},
        "workingDirectory":{"type":"string","default":".","description":"The game's folder relative to the repository root when factoria.json is not at the root of the repository."},
        "version":{"type":"string","description":"The FactorIA release the workflow downloads: \"latest\" or a version such as 0.1.6. Default: the version of this factoria (a build from source: latest, with a warning)."},
        "overwrite":{"type":"boolean","default":false,"description":"Replace the file when it exists and differs. Without it that is an error."},
        "dryRun":{"type":"boolean","default":false,"description":"Return the workflow and what would happen; write nothing."}
      }})");
    registry.add(info, [projectDir](const Json& args) {
        CiWorkflowOptions o;
        o.projectDir = projectDir;
        if (auto it = args.find("platforms"); it != args.end() && it->is_array())
            for (const Json& p : *it)
                if (p.is_string()) o.platforms.push_back(p.get<std::string>());
        if (std::string v = tooling_detail::arg_string(args, "path", false); !v.empty()) o.path = v;
        o.workingDirectory = tooling_detail::arg_string(args, "workingDirectory", false, ".");
        o.version = tooling_detail::arg_string(args, "version", false);
        o.overwrite = tooling_detail::arg_bool(args, "overwrite", false);
        o.dryRun = tooling_detail::arg_bool(args, "dryRun", false);
        auto r = write_ci_workflow(o);
        if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
        return r->to_json();
    });
}

}  // namespace fa
