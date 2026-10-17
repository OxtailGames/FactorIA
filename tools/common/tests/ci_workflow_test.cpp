// project.new_ci_workflow (fa/tooling/ci_workflow.h): the GitHub Actions workflow written into a game project. The text is checked
// for its key steps and for the one version it pins; the writing for "never overwrite". The workflow's shell steps are run by hand
// against a real release package (docs/EXPORTING.md, "CI for your game"): no test needs GitHub.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <regex>

#include "fa/core/command.h"
#include "fa/core/strings.h"
#include "fa/tooling/ci_workflow.h"
#include "fa/tooling/setup_parse.h"
#include "fa/tooling/tooling.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

bool has_text(const std::string& haystack, const std::string& needle) { return haystack.find(needle) != std::string::npos; }

bool any_has(const std::vector<std::string>& v, const std::string& needle) {
    return std::any_of(v.begin(), v.end(), [&](const std::string& s) { return has_text(s, needle); });
}

std::size_t count_of(const std::string& haystack, const std::string& needle) {
    std::size_t n = 0;
    for (std::size_t at = haystack.find(needle); at != std::string::npos; at = haystack.find(needle, at + needle.size())) ++n;
    return n;
}

const std::vector<std::string> kAll = {"linux", "windows", "macos"};

// Lines of the workflow as YAML sees them: where the `check:` and `macos:` jobs start and end.
std::string job_of(const std::string& yaml, const std::string& name) {
    const std::string head = "\n  " + name + ":\n";
    const std::size_t at = yaml.find(head);
    if (at == std::string::npos) return {};
    std::size_t end = yaml.size();
    for (std::size_t i = at + head.size(); i < yaml.size();) {  // the next line indented by exactly two spaces ends the job
        std::size_t nl = yaml.find('\n', i);
        if (nl == std::string::npos) nl = yaml.size();
        if (nl > i + 2 && yaml[i] == ' ' && yaml[i + 1] == ' ' && yaml[i + 2] != ' ') {
            end = i;
            break;
        }
        i = nl + 1;
    }
    return yaml.substr(at, end - at);
}

// A game folder (only factoria.json matters here) and the options to write its workflow as the release build 0.1.6 would.
struct Game {
    testing::TempDir tmp;
    std::string dir = tmp.sub("game");
    Game() { testing::write_all(stdfs::path(dir) / "factoria.json", "{}"); }
    std::string file(const std::string& rel = ".github/workflows/factoria.yml") const { return (stdfs::path(dir) / rel).string(); }
    CiWorkflowOptions release() const {
        CiWorkflowOptions o;
        o.projectDir = dir;
        o.engineVersion = "0.1.6";
        o.updateRepo = "OxtailGames/FactorIA";
        return o;
    }
};

}  // namespace

TEST_CASE("ci workflow: the text has the steps a game needs") {
    const std::string y = ci_workflow_yaml("0.1.6", "OxtailGames/FactorIA", kAll, ".");

    // The triggers and the least permissions.
    CHECK(has_text(y, "name: FactorIA\n"));
    CHECK(has_text(y, "\non:\n  push:\n    branches: [main, master]\n  pull_request:\n  workflow_dispatch:\n"));
    CHECK(has_text(y, "\npermissions:\n  contents: read\n"));

    // One pinned version and the repository it comes from: nothing else in the file says either.
    CHECK(has_text(y, "\nenv:\n  FACTORIA_VERSION: \"0.1.6\"\n  FACTORIA_REPO: \"OxtailGames/FactorIA\"\n"));
    CHECK(count_of(y, "0.1.6") == 1);  // nowhere else: changing the version means changing this one line
    CHECK(count_of(y, "OxtailGames/FactorIA") == 2);  // the env block, and the comment that says where the download comes from
    CHECK(has_text(y, "releases/download/v$FACTORIA_VERSION/$asset"));
    CHECK(has_text(y, "releases/latest/download/$asset"));  // FACTORIA_VERSION: "latest" works too

    // The ubuntu job: libraries, install with a checksum, validate, test under Xvfb, players, exports, artifacts.
    const std::string check = job_of(y, "check");
    REQUIRE_FALSE(check.empty());
    CHECK(has_text(check, "runs-on: ubuntu-24.04"));
    CHECK(has_text(check, "uses: actions/checkout@v4"));
    CHECK(has_text(check, "apt-get install -y --no-install-recommends xvfb libegl1 libopengl0 libx11-6 libxcursor1 libxi6 libasound2t64 libgl1-mesa-dri libegl-mesa0"));
    CHECK(has_text(check, "asset=\"FactorIA-linux-x64.tar.gz\""));
    CHECK(has_text(check, "digest"));  // the SHA-256 GitHub lists for the asset
    CHECK(has_text(check, "hashlib.sha256"));
    CHECK(has_text(check, "tar -xzf \"$RUNNER_TEMP/$asset\" -C \"$HOME/factoria\" --strip-components=1"));
    CHECK(has_text(check, "echo \"$HOME/factoria\" >> \"$GITHUB_PATH\""));
    const std::size_t install = check.find("name: Install FactorIA");
    const std::size_t validate = check.find("run: factoria validate");
    const std::size_t test = check.find("run: xvfb-run -a factoria test");
    const std::size_t players = check.find("run: factoria setup players --platforms windows");
    const std::size_t exportLinux = check.find("run: factoria export --platform linux");
    const std::size_t exportWindows = check.find("run: factoria export --platform windows");
    const std::size_t upload = check.find("uses: actions/upload-artifact@v4");
    for (std::size_t at : {install, validate, test, players, exportLinux, exportWindows, upload}) REQUIRE(at != std::string::npos);
    CHECK(install < validate);
    CHECK(validate < test);
    CHECK(test < players);
    CHECK(players < exportWindows);
    CHECK(exportLinux < upload);
    CHECK(exportWindows < upload);
    CHECK(has_text(check, "python3 -m zipfile -c"));  // the Windows export is a zip, the Linux one a tar (the executable bit survives)
    CHECK(has_text(check, "tar -czf \"dist/$name.tar.gz\" -C build/export \"$name\""));
    CHECK(has_text(check, "path: dist/*"));
    CHECK(has_text(check, "if-no-files-found: error"));
    CHECK_FALSE(has_text(check, "--platform macos"));

    // The macOS job: a macOS runner, the macOS package, the export.
    const std::string mac = job_of(y, "macos");
    REQUIRE_FALSE(mac.empty());
    CHECK(has_text(mac, "runs-on: macos-latest"));
    CHECK(has_text(mac, "asset=\"FactorIA-macos-universal.tar.gz\""));
    CHECK(has_text(mac, "run: factoria export --platform macos"));
    CHECK(has_text(mac, "uses: actions/upload-artifact@v4"));
    CHECK(has_text(mac, "sign.macos"));  // the comment that says where signing goes
    CHECK_FALSE(has_text(mac, "xvfb"));

    // The names of the download are the ones the release workflow publishes.
    const std::string release = testing::read_all(stdfs::path(FA_REPO_ROOT) / ".github" / "workflows" / "release.yml");
    REQUIRE_FALSE(release.empty());
    CHECK(has_text(release, "FactorIA-linux-x64.tar.gz"));
    CHECK(has_text(release, "FactorIA-macos-universal.tar.gz"));
}

TEST_CASE("ci workflow: the text is plain YAML") {
    for (const std::vector<std::string>& platforms : std::vector<std::vector<std::string>>{kAll, {"linux"}, {"windows"}, {"macos"}, {"linux", "windows"}}) {
        for (const char* wd : {".", "games/my game"}) {
            const std::string y = ci_workflow_yaml("latest", "OxtailGames/FactorIA", platforms, wd);
            INFO(platforms.size() << " platforms, working directory " << wd);
            CHECK(y.back() == '\n');
            CHECK_FALSE(has_text(y, "\t"));
            CHECK_FALSE(has_text(y, "\r"));
            CHECK_FALSE(has_text(y, " \n"));        // no trailing blanks
            CHECK_FALSE(has_text(y, "\n\n\n"));      // no stacked blank lines
            CHECK_FALSE(std::regex_search(y, std::regex("@[A-Z_]+@")));  // every placeholder was filled
            for (const std::string& line : split(y, '\n', false)) {
                std::size_t spaces = 0;
                while (spaces < line.size() && line[spaces] == ' ') ++spaces;
                CHECK_MESSAGE(spaces % 2 == 0, line);  // the shell blocks nest in steps of two
            }
            for (const char* key : {"name: FactorIA\n", "\non:\n", "\npermissions:\n", "\nenv:\n", "\njobs:\n"}) CHECK_MESSAGE(count_of(y, key) == 1, key);
        }
    }
}

TEST_CASE("ci workflow: a subset of platforms leaves the others out") {
    SUBCASE("linux only") {
        const std::string y = ci_workflow_yaml("0.1.6", "OxtailGames/FactorIA", {"linux"}, ".");
        CHECK(has_text(y, "factoria export --platform linux"));
        CHECK_FALSE(has_text(y, "windows"));
        CHECK_FALSE(has_text(y, "macos"));
        CHECK_FALSE(has_text(y, "setup players"));
        CHECK(job_of(y, "macos").empty());
        CHECK(has_text(y, "name: export-linux"));
    }
    SUBCASE("windows only") {
        const std::string y = ci_workflow_yaml("0.1.6", "OxtailGames/FactorIA", {"windows"}, ".");
        CHECK(has_text(y, "factoria setup players --platforms windows"));
        CHECK(has_text(y, "factoria export --platform windows"));
        CHECK_FALSE(has_text(y, "factoria export --platform linux"));
        CHECK_FALSE(has_text(y, "macos"));
        CHECK(has_text(y, "name: export-windows"));
    }
    SUBCASE("macos only: the ubuntu job still validates and tests") {
        const std::string y = ci_workflow_yaml("0.1.6", "OxtailGames/FactorIA", {"macos"}, ".");
        const std::string check = job_of(y, "check");
        REQUIRE_FALSE(check.empty());
        CHECK(has_text(check, "run: factoria validate"));
        CHECK(has_text(check, "run: xvfb-run -a factoria test"));
        CHECK_FALSE(has_text(check, "factoria export"));
        CHECK_FALSE(has_text(check, "upload-artifact"));
        CHECK(has_text(job_of(y, "macos"), "factoria export --platform macos"));
    }
}

TEST_CASE("ci workflow: a game in a folder of the repository") {
    const std::string y = ci_workflow_yaml("0.1.6", "OxtailGames/FactorIA", kAll, "games/my-game");
    CHECK(has_text(y, "\ndefaults:\n  run:\n    working-directory: \"games/my-game\"\n"));
    CHECK(has_text(y, "path: games/my-game/dist/*"));  // `uses` steps do not follow defaults.run
    CHECK_FALSE(has_text(ci_workflow_yaml("0.1.6", "OxtailGames/FactorIA", kAll, "."), "working-directory"));
    CHECK(has_text(ci_workflow_yaml("0.1.6", "OxtailGames/FactorIA", kAll, "."), "path: dist/*"));
}

TEST_CASE("ci workflow: written for the version of the factoria that writes it") {
    Game g;
    auto r = write_ci_workflow(g.release());
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->written);
    CHECK_FALSE(r->dryRun);
    CHECK(r->version == "0.1.6");
    CHECK(r->repo == "OxtailGames/FactorIA");
    CHECK(r->platforms == kAll);
    CHECK(r->warnings.empty());
    CHECK(stdfs::path(r->path) == stdfs::weakly_canonical(g.file()));
    CHECK(testing::read_all(g.file()) == r->workflow);
    CHECK(has_text(r->workflow, "FACTORIA_VERSION: \"0.1.6\""));
    CHECK(any_has(r->nextSteps, ".github/workflows/factoria.yml"));
    CHECK(any_has(r->nextSteps, "Commit"));
    const Json j = r->to_json();
    CHECK(j["written"] == true);
    CHECK(j["version"] == "0.1.6");
    CHECK(j["workflow"] == r->workflow);
    CHECK(j["platforms"].size() == 3);
}

TEST_CASE("ci workflow: a build from source follows the newest release and says so") {
    Game g;
    CiWorkflowOptions o = g.release();
    o.updateRepo = std::string();  // FA_UPDATE_REPO is empty outside the release packages
    o.engineVersion = "0.2.0";
    auto r = write_ci_workflow(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->version == "latest");
    CHECK(r->repo == kSetupReleaseRepo);
    CHECK(has_text(r->workflow, "FACTORIA_VERSION: \"latest\""));
    REQUIRE(r->warnings.size() == 1);
    CHECK(has_text(r->warnings[0], "build from source"));
    CHECK(has_text(r->warnings[0], "version"));  // how to pin one
    CHECK(has_text(r->warnings[0], "0.2.0"));
}

TEST_CASE("ci workflow: the version can be chosen, and only to a real one") {
    Game g;
    CiWorkflowOptions o = g.release();
    o.dryRun = true;
    SUBCASE("a release") {
        o.version = "0.1.5";
        auto r = write_ci_workflow(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->version == "0.1.5");
        CHECK(has_text(r->workflow, "FACTORIA_VERSION: \"0.1.5\""));
        CHECK(any_has(r->warnings, "another version"));  // not the one that edits the game
    }
    SUBCASE("latest") {
        o.version = "latest";
        auto r = write_ci_workflow(o);
        REQUIRE(r.ok());
        CHECK(r->version == "latest");
        CHECK(has_text(r->workflow, "FACTORIA_VERSION: \"latest\""));
    }
    SUBCASE("the same version as this factoria is no news") {
        o.version = "0.1.6";
        auto r = write_ci_workflow(o);
        REQUIRE(r.ok());
        CHECK(r->warnings.empty());
    }
    SUBCASE("anything else is refused before it reaches a shell script") {
        for (const char* bad : {"v0.1.6", "0.1", "0.1.6; rm -rf /", "$(id)", "0.1.6\"\n  X: y", "main"}) {
            INFO(bad);
            o.version = bad;
            auto r = write_ci_workflow(o);
            REQUIRE_FALSE(r.ok());
            CHECK(has_text(r.error().message, "is not a FactorIA release"));
            CHECK(has_text(r.error().hint, "latest"));
        }
    }
}

TEST_CASE("ci workflow: an existing file is never overwritten without being asked") {
    Game g;
    auto first = write_ci_workflow(g.release());
    REQUIRE(first.ok());
    const stdfs::path file = g.file();

    SUBCASE("the same text is left alone") {
        auto again = write_ci_workflow(g.release());
        REQUIRE_MESSAGE(again.ok(), (again.ok() ? "" : again.error().to_string()));
        CHECK_FALSE(again->written);
        CHECK(any_has(again->warnings, "already up to date"));
        CHECK(testing::read_all(file) == first->workflow);
    }
    SUBCASE("a file that differs is an error that says how to go on, and stays as it is") {
        testing::write_all(file, "name: mine\non: push\n");
        auto r = write_ci_workflow(g.release());
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "already exists"));
        CHECK(has_text(r.error().message, "left as it is"));
        CHECK(has_text(r.error().hint, "overwrite: true"));
        CHECK(has_text(r.error().hint, "dryRun"));
        CHECK(testing::read_all(file) == "name: mine\non: push\n");

        // A dry run shows what would be written and that it would not be.
        CiWorkflowOptions dry = g.release();
        dry.dryRun = true;
        auto shown = write_ci_workflow(dry);
        REQUIRE(shown.ok());
        CHECK_FALSE(shown->written);
        CHECK(shown->workflow == first->workflow);
        CHECK(any_has(shown->warnings, "overwrite: true"));
        CHECK(testing::read_all(file) == "name: mine\non: push\n");

        CiWorkflowOptions force = g.release();
        force.overwrite = true;
        auto replaced = write_ci_workflow(force);
        REQUIRE_MESSAGE(replaced.ok(), (replaced.ok() ? "" : replaced.error().to_string()));
        CHECK(replaced->written);
        CHECK(testing::read_all(file) == first->workflow);
    }
    SUBCASE("another file name beside it") {
        testing::write_all(file, "name: mine\n");
        CiWorkflowOptions o = g.release();
        o.path = ".github/workflows/factoria-game.yaml";
        auto r = write_ci_workflow(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->written);
        CHECK(testing::read_all(file) == "name: mine\n");
        CHECK(testing::read_all(g.file(".github/workflows/factoria-game.yaml")) == r->workflow);
    }
}

TEST_CASE("ci workflow: a dry run writes nothing, not even the folders") {
    Game g;
    CiWorkflowOptions o = g.release();
    o.dryRun = true;
    auto r = write_ci_workflow(o);
    REQUIRE(r.ok());
    CHECK(r->dryRun);
    CHECK_FALSE(r->written);
    CHECK_FALSE(r->workflow.empty());
    CHECK(any_has(r->nextSteps, "dry run"));
    CHECK_FALSE(stdfs::exists(stdfs::path(g.dir) / ".github"));
}

TEST_CASE("ci workflow: the file goes where GitHub reads workflows") {
    Game g;
    CiWorkflowOptions o = g.release();
    o.dryRun = true;
    for (const char* bad : {"../factoria.yml", "factoria.yml", "docs/factoria.yml", ".github/factoria.yml", ".github/workflows/factoria.txt", ".github/workflows/sub/factoria.yml",
                            ".github/workflows/", "/etc/factoria.yml"}) {
        INFO(bad);
        o.path = bad;
        auto r = write_ci_workflow(o);
        REQUIRE_FALSE(r.ok());
        CHECK_FALSE(r.error().hint.empty());
    }
    o.path = ".github/workflows/ci.yml";
    CHECK(write_ci_workflow(o).ok());
    o.path = ".github\\workflows\\ci.yaml";
    CHECK(write_ci_workflow(o).ok());
    o.path = "./.github/workflows/ci.yml";
    CHECK(write_ci_workflow(o).ok());
}

TEST_CASE("ci workflow: platforms and the folder of the game are checked") {
    Game g;
    CiWorkflowOptions o = g.release();
    o.dryRun = true;
    SUBCASE("aliases, repeats and order") {
        o.platforms = {"Mac", "win", "linux", "windows", "OSX"};
        auto r = write_ci_workflow(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->platforms == kAll);
    }
    SUBCASE("one platform") {
        o.platforms = {"linux"};
        auto r = write_ci_workflow(o);
        REQUIRE(r.ok());
        CHECK(r->platforms == std::vector<std::string>{"linux"});
    }
    SUBCASE("a platform that does not exist") {
        o.platforms = {"linx"};
        auto r = write_ci_workflow(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "unknown platform 'linx'"));
        CHECK(has_text(r.error().hint, "linux"));  // did you mean
        o.platforms = {""};
        CHECK_FALSE(write_ci_workflow(o).ok());
    }
    SUBCASE("mobile platforms are not part of this workflow") {
        for (const char* mobile : {"android", "ios"}) {
            o.platforms = {mobile};
            auto r = write_ci_workflow(o);
            REQUIRE_FALSE(r.ok());
            CHECK(has_text(r.error().message, "is not exported by this workflow"));
            CHECK(has_text(r.error().hint, "docs/EXPORTING.md"));
        }
    }
    SUBCASE("working directory") {
        o.workingDirectory = "games\\my-game/";
        auto r = write_ci_workflow(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(has_text(r->workflow, "working-directory: \"games/my-game\""));
        for (const char* bad : {"../elsewhere", "/abs/path", "games/../x", "a\"b", "a;b", "$(x)", "a\nb"}) {
            INFO(bad);
            o.workingDirectory = bad;
            auto no = write_ci_workflow(o);
            REQUIRE_FALSE(no.ok());
            CHECK(has_text(no.error().message, "not a folder inside the repository"));
        }
    }
    SUBCASE("a repository that is not a FactorIA fork name") {
        o.updateRepo = "not a repo";
        CHECK_FALSE(write_ci_workflow(o).ok());
    }
}

TEST_CASE("ci workflow: not a game folder") {
    testing::TempDir tmp;
    CiWorkflowOptions o;
    o.projectDir = tmp.sub("nothing");
    auto r = write_ci_workflow(o);
    REQUIRE_FALSE(r.ok());
    CHECK(has_text(r.error().message, "factoria.json"));
    CHECK(has_text(r.error().hint, "factoria new"));
    o.projectDir.clear();
    CHECK_FALSE(write_ci_workflow(o).ok());
}

TEST_CASE("ci workflow: a game inside a larger repository is told where the file must go") {
    testing::TempDir tmp;
    testing::write_all(tmp.path / "repo" / ".git" / "HEAD", "ref: refs/heads/main\n");
    testing::write_all(tmp.path / "repo" / "games" / "g" / "factoria.json", "{}");
    CiWorkflowOptions o;
    o.projectDir = (tmp.path / "repo" / "games" / "g").string();
    o.engineVersion = "0.1.6";
    o.updateRepo = "OxtailGames/FactorIA";
    o.workingDirectory = "games/g";
    auto r = write_ci_workflow(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    REQUIRE(r->warnings.size() == 1);
    CHECK(has_text(r->warnings[0], "git repository"));
    CHECK(has_text(r->warnings[0], "repo"));
    CHECK(has_text(r->warnings[0], "/.github/workflows/"));
    CHECK(stdfs::exists(tmp.path / "repo" / "games" / "g" / ".github" / "workflows" / "factoria.yml"));
    CHECK(has_text(r->workflow, "working-directory: \"games/g\""));

    // The game is the repository: nothing to warn about.
    testing::write_all(tmp.path / "solo" / ".git" / "HEAD", "ref: refs/heads/main\n");
    testing::write_all(tmp.path / "solo" / "factoria.json", "{}");
    o.projectDir = (tmp.path / "solo").string();
    o.workingDirectory = ".";
    auto solo = write_ci_workflow(o);
    REQUIRE(solo.ok());
    CHECK(solo->warnings.empty());
}

TEST_CASE("ci workflow: the command") {
    Game g;
    CommandRegistry registry;
    register_ci_workflow_commands(registry, g.dir);
    const CommandInfo* info = registry.info("project.new_ci_workflow");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    for (const char* key : {"platforms", "path", "workingDirectory", "version", "overwrite", "dryRun"}) CHECK_MESSAGE(info->inputSchema["properties"].contains(key), key);
    CHECK(has_text(info->description, "never overwrites"));
    CHECK(has_text(info->description, "workingDirectory"));
    CHECK(has_text(info->description, "xvfb"));

    auto dry = registry.call("project.new_ci_workflow", Json::object({{"platforms", Json::array({"linux", "windows"})}, {"dryRun", true}, {"version", "0.1.6"}}));
    REQUIRE_MESSAGE(dry.ok, dry.error.dump());
    CHECK(dry.result["dryRun"] == true);
    CHECK(dry.result["written"] == false);
    CHECK(dry.result["platforms"] == Json::array({"linux", "windows"}));
    CHECK(has_text(dry.result["workflow"].get<std::string>(), "FACTORIA_VERSION: \"0.1.6\""));
    CHECK_FALSE(stdfs::exists(stdfs::path(g.dir) / ".github"));

    auto written = registry.call("project.new_ci_workflow", Json::object({{"version", "0.1.6"}}));
    REQUIRE_MESSAGE(written.ok, written.error.dump());
    CHECK(written.result["written"] == true);
    CHECK(stdfs::exists(g.file()));

    auto again = registry.call("project.new_ci_workflow", Json::object({{"version", "0.1.5"}}));  // another text
    REQUIRE_FALSE(again.ok);
    CHECK(again.error["code"] == "failed");
    CHECK(has_text(again.error["message"].get<std::string>(), "already exists"));
    CHECK(has_text(again.error["hint"].get<std::string>(), "overwrite"));
    CHECK(has_text(testing::read_all(g.file()), "FACTORIA_VERSION: \"0.1.6\""));  // untouched

    auto forced = registry.call("project.new_ci_workflow", Json::object({{"version", "0.1.5"}, {"overwrite", true}}));
    REQUIRE_MESSAGE(forced.ok, forced.error.dump());
    CHECK(has_text(testing::read_all(g.file()), "FACTORIA_VERSION: \"0.1.5\""));
}

TEST_CASE("ci workflow and sign.macos are part of the tooling every game project gets") {
    testing::TempDir tmp;
    CommandRegistry registry;
    register_tooling_commands(registry, tmp.str());
    for (const char* name : {"project.new_ci_workflow", "sign.macos", "project.export"}) CHECK_MESSAGE(registry.has(name), name);
}
