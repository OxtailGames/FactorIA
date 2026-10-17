// The Linux AppImage: `factoria setup appimage` (appimagetool + the AppImage runtime, pinned by SHA-256) and
// `factoria export --platform linux --format appimage` (the AppDir it builds and the command it runs). No test needs Linux, a
// network or appimagetool: the SetupContext of the export is a fake Linux x86_64 computer whose downloader and process runner are
// the tests' own. The real thing is run in WSL by hand (docs/EXPORTING.md, "Linux: AppImage").
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <functional>
#include <map>

#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/tooling/export.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/setup.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A fake computer: its folders are temporary ones, what it downloads is what the test registers, and every program it "runs" is the
// test's function.
struct Lab {
    testing::TempDir tmp;
    std::string home = tmp.sub("fhome");
    std::map<std::string, std::string> served;  // url -> body
    std::vector<std::string> requested;
    std::vector<ProcessOptions> runs;
    std::function<Result<ProcessResult>(const ProcessOptions&)> program;  // what appimagetool does; empty = exit 0

    SetupContext ctx(const std::string& host = "linux", const std::string& arch = "x64") {
        SetupContext c;
        c.env = [](const std::string&) { return std::string(); };
        c.home = home;
        c.machineConfigPath = tmp.sub("export.json");
        c.host = host;
        c.hostArch = arch;
        c.engineVersion = "0.1.6";
        c.download = [this](const DownloadRequest& rq) {
            requested.push_back(rq.url);
            DownloadResult r;
            auto it = served.find(rq.url);
            if (it == served.end()) {
                r.ok = false;
                r.httpStatus = 404;
                r.error = make_error("not served in the test: " + rq.url, "test hint");
                return r;
            }
            testing::write_all(rq.destination, it->second);
            return r;
        };
        c.run = [this](const ProcessOptions& o) -> Result<ProcessResult> {
            runs.push_back(o);
            if (program) return program(o);
            ProcessResult r;
            r.exitCode = 0;
            return r;
        };
        return c;
    }

    stdfs::path tools_dir() const { return stdfs::path(home) / "tools" / "appimage"; }
    std::string tool_name() const { return std::string("appimagetool-") + kSetupAppimagetoolVersion + "-x86_64.AppImage"; }
    std::string runtime_name() const { return std::string("runtime-") + kSetupAppImageRuntimeVersion + "-x86_64"; }
    void install_fake_tools() {
        testing::write_all(tools_dir() / tool_name(), "fake appimagetool");
        testing::write_all(tools_dir() / runtime_name(), "fake runtime");
    }
};

bool has_text(const std::string& haystack, const std::string& needle) { return haystack.find(needle) != std::string::npos; }

bool any_has(const std::vector<std::string>& v, const std::string& needle) {
    return std::any_of(v.begin(), v.end(), [&](const std::string& s) { return has_text(s, needle); });
}

std::vector<std::string> listing(const stdfs::path& dir) {
    std::vector<std::string> out;
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) out.push_back(stdfs::relative(it->path(), dir).generic_string());
    std::sort(out.begin(), out.end());
    return out;
}

bool contains(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

std::string make_player(const testing::TempDir& tmp) {
    const std::string p = tmp.sub("fake_player/factoria_player");
    testing::write_all(p, "#!/bin/sh\nexit 0\n");
    return p;
}

// "Space Dodge" (slug space-dodge), with an icon unless told otherwise.
std::string make_game(const testing::TempDir& tmp, bool withIcon = true) {
    const std::string dir = tmp.sub("proj");
    ScaffoldOptions so;
    so.name = "Space Dodge";
    so.id = "com.example.spacedodge";
    auto r = create_project(dir, "2d-platformer", so);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    {
        Json project = Json::parse(testing::read_all(stdfs::path(dir) / "factoria.json"));
        project["version"] = "1.2.3";
        testing::write_all(stdfs::path(dir) / "factoria.json", project.dump(2));
    }
    Image hero;
    hero.width = hero.height = 1;
    hero.rgba = {255, 255, 255, 255};
    const auto png = encode_png(hero);
    testing::write_all(stdfs::path(dir) / "assets" / "sprites" / "hero.png", std::string(png.begin(), png.end()));
    if (withIcon) {
        Image icon;
        icon.width = icon.height = 512;
        icon.rgba.assign(512u * 512u * 4u, 200);
        REQUIRE(save_png(icon, (stdfs::path(dir) / "assets" / "icon.png").generic_string()).ok());
        ProjectExportSettings s;
        s.icon = "assets/icon.png";
        s.linux.categories = {"Game", "ArcadeGame"};
        auto saved = save_export_settings(dir, s);
        REQUIRE_MESSAGE(saved.ok(), (saved.ok() ? "" : saved.error().to_string()));
    }
    return dir;
}

// What the fake appimagetool saw: the AppDir as it was while the program ran.
struct Seen {
    std::vector<std::string> files;
    std::string appRun, desktop;
    bool iconIsPng = false, dirIconIsPng = false;
    std::vector<std::string> argv;
    std::map<std::string, std::string> env;
};

void fake_appimagetool(Lab& lab, Seen& seen, int exitCode = 0, bool writeArtifact = true) {
    lab.program = [&seen, exitCode, writeArtifact](const ProcessOptions& o) -> Result<ProcessResult> {
        seen.argv = o.argv;
        seen.env = o.env;
        const stdfs::path appDir = o.argv.at(o.argv.size() - 2);
        seen.files = listing(appDir);
        seen.appRun = testing::read_all(appDir / "AppRun");
        seen.desktop = testing::read_all(appDir / "space-dodge.desktop");
        auto is_png = [](const stdfs::path& p) { return testing::read_all(p).compare(1, 3, "PNG") == 0; };
        seen.iconIsPng = is_png(appDir / "space-dodge.png");
        seen.dirIconIsPng = is_png(appDir / ".DirIcon");
        ProcessResult r;
        r.exitCode = exitCode;
        if (exitCode != 0) r.stderrText = "appimagetool: something went wrong\nValidation failed: Icon not found";
        if (exitCode == 0 && writeArtifact) testing::write_all(o.argv.back(), "fake AppImage");
        return r;
    };
}

}  // namespace

// ---- setup appimage ---------------------------------------------------------------------------------------------------------

TEST_CASE("setup appimage: only Linux x86_64 can build an AppImage") {
    for (auto [host, arch] : std::vector<std::pair<std::string, std::string>>{{"macos", "aarch64"}, {"windows", "x64"}, {"linux", "aarch64"}}) {
        INFO(host << "-" << arch);
        Lab lab;
        SetupContext c = lab.ctx(host, arch);
        const SetupStatus st = setup_status(c, "appimage", false);
        REQUIRE(st.components.size() == 1);
        CHECK(st.components[0].id == "appimage");
        CHECK(st.components[0].state == "unsupported");
        CHECK_FALSE(st.components[0].canInstall);
        CHECK(has_text(st.components[0].details, "x86_64"));

        SetupInstallOptions o;
        o.component = "appimage";
        const SetupResult r = setup_install(o, c);
        CHECK_FALSE(r.ok);
        CHECK(r.code == "unsupported");
        CHECK(has_text(r.error.message, host + "-" + arch));
        CHECK(has_text(r.error.hint, "WSL"));
        CHECK(lab.requested.empty());
        CHECK_FALSE(stdfs::exists(lab.tools_dir()));
    }
}

TEST_CASE("setup appimage: status names what an install downloads and finds what is installed") {
    Lab lab;
    SetupContext c = lab.ctx();
    SetupComponent missing = setup_status(c, "appimage", false).components[0];
    CHECK(missing.state == "missing");
    CHECK(missing.canInstall);
    CHECK(missing.installSizeMb > 0);
    CHECK(has_text(missing.details, kSetupAppimagetoolVersion));
    CHECK(has_text(missing.details, kSetupAppImageRuntimeVersion));
    CHECK(installed_appimage_tools(c).tool.empty());

    lab.install_fake_tools();
    SetupComponent have = setup_status(c, "appimage", false).components[0];
    CHECK(have.state == "installed");
    CHECK(have.installSizeMb == 0);
    CHECK(have.problems.empty());
    const AppImageTools tools = installed_appimage_tools(c);
    CHECK(tools.tool == (lab.tools_dir() / lab.tool_name()).string());
    CHECK(tools.runtime == (lab.tools_dir() / lab.runtime_name()).string());

    // One of the two is not enough.
    stdfs::remove(lab.tools_dir() / lab.runtime_name());
    CHECK(setup_status(c, "appimage", false).components[0].state == "missing");
    CHECK(installed_appimage_tools(c).tool.empty());
}

TEST_CASE("setup appimage: a download that is not the pinned file installs nothing") {
    Lab lab;
    const std::string toolUrl = std::string("https://github.com/AppImage/appimagetool/releases/download/") + kSetupAppimagetoolVersion + "/appimagetool-x86_64.AppImage";
    const std::string runtimeUrl = std::string("https://github.com/AppImage/type2-runtime/releases/download/") + kSetupAppImageRuntimeVersion + "/runtime-x86_64";
    lab.served[toolUrl] = "somebody replaced this file";
    lab.served[runtimeUrl] = "and this one";
    SetupContext c = lab.ctx();
    SetupInstallOptions o;
    o.component = "appimage";
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "checksum_mismatch");
    CHECK(has_text(r.error.message, "appimagetool-"));
    CHECK(has_text(r.error.message, kSetupAppimagetoolSha256));
    CHECK(has_text(r.error.hint, "Nothing was installed"));
    CHECK(lab.requested == std::vector<std::string>{toolUrl});  // it stopped at the first
    CHECK(installed_appimage_tools(c).tool.empty());
    CHECK(listing(lab.tools_dir()).empty());  // no half-installed file
}

TEST_CASE("setup appimage: a failed download says what to do") {
    Lab lab;  // nothing is served: 404
    SetupContext c = lab.ctx();
    SetupInstallOptions o;
    o.component = "appimage";
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(has_text(r.error.message, "AppImage"));
    CHECK_FALSE(r.error.hint.empty());
    CHECK(listing(lab.tools_dir()).empty());
}

TEST_CASE("setup appimage: installed tools are kept, files of an older pinned version are removed") {
    Lab lab;
    lab.install_fake_tools();
    testing::write_all(lab.tools_dir() / "appimagetool-1.0.0-x86_64.AppImage", "old");
    testing::write_all(lab.tools_dir() / "runtime-20200101-x86_64", "old");
    testing::write_all(lab.tools_dir() / "notes.txt", "mine");
    SetupContext c = lab.ctx();
    SetupInstallOptions o;
    o.component = "appimage";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK_FALSE(r.report.changed);
    CHECK(lab.requested.empty());
    CHECK(listing(lab.tools_dir()) == std::vector<std::string>{lab.tool_name(), "notes.txt", lab.runtime_name()});
    CHECK(testing::read_all(lab.tools_dir() / lab.tool_name()) == "fake appimagetool");
    bool allSkipped = !r.report.steps.empty();
    for (const SetupStep& s : r.report.steps) allSkipped = allSkipped && s.outcome == "skipped";
    CHECK(allSkipped);
}

TEST_CASE("setup appimage: setup.status and setup.install know the component") {
    Lab lab;
    SetupContext c = lab.ctx();
    const Json status = setup_status(c, {}, false).to_json();
    bool listed = false;
    for (const Json& comp : status["components"]) listed = listed || comp.value("id", "") == "appimage";
    CHECK(listed);
    SetupInstallOptions o;
    o.component = "appimge";
    const SetupResult typo = setup_install(o, c);
    REQUIRE_FALSE(typo.ok);
    CHECK(has_text(typo.error.hint, "appimage"));  // "did you mean"
}

TEST_CASE("setup appimage: the pinned files are the ones scripts/package-appimage.sh uses") {
    const std::string script = testing::read_all(stdfs::path(FA_REPO_ROOT) / "scripts" / "package-appimage.sh");
    REQUIRE_FALSE(script.empty());
    CHECK(has_text(script, std::string("appimagetool/releases/download/") + kSetupAppimagetoolVersion + "/appimagetool-x86_64.AppImage"));
    CHECK(has_text(script, std::string("appimagetool_sha256=") + kSetupAppimagetoolSha256));
    CHECK(has_text(script, std::string("type2-runtime/releases/download/") + kSetupAppImageRuntimeVersion + "/runtime-x86_64"));
    CHECK(has_text(script, std::string("runtime_sha256=") + kSetupAppImageRuntimeSha256));
}

// ---- the export -------------------------------------------------------------------------------------------------------------

TEST_CASE("export appimage: the AppDir and the appimagetool command line") {
    Lab lab;
    lab.install_fake_tools();
    Seen seen;
    fake_appimagetool(lab, seen);
    SetupContext c = lab.ctx();

    const std::string proj = make_game(lab.tmp);
    testing::write_all(stdfs::path(proj) / "plugins" / "demo" / "linux" / "libdemo.so", "plugin");
    testing::write_all(stdfs::path(proj) / "plugins" / "demo" / "linux" / "plugin.json", "{}");
    {
        Json project = Json::parse(testing::read_all(stdfs::path(proj) / "factoria.json"));
        project["plugins"] = Json::parse(R"json({"demo": {"path": "plugins/demo", "platforms": ["linux"]}})json");
        testing::write_all(stdfs::path(proj) / "factoria.json", project.dump(2));
    }
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "linux";
    o.format = "appimage";
    o.outDir = lab.tmp.sub("out");
    o.playerBinary = make_player(lab.tmp);
    o.setup = &c;

    // The plan names the file without writing anything.
    auto plan = plan_export(o);
    REQUIRE_MESSAGE(plan.ok(), (plan.ok() ? "" : plan.error().to_string()));
    CHECK(plan->format == "appimage");
    CHECK(has_text(plan->artifact, "space-dodge-linux/space-dodge-x86_64.AppImage"));
    CHECK(lab.runs.empty());
    CHECK_FALSE(stdfs::exists(lab.tmp.sub("out")));

    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->format == "appimage");
    CHECK(r->artifact == plan->artifact);
    CHECK(stdfs::is_regular_file(stdfs::path(r->artifact)));
    REQUIRE(lab.runs.size() == 1);

    // appimagetool: the pinned tool and runtime, no AppStream data, ARCH set, no FUSE needed.
    REQUIRE(seen.argv.size() == 6);
    CHECK(seen.argv[0] == (lab.tools_dir() / lab.tool_name()).string());
    CHECK(seen.argv[1] == "--no-appstream");
    CHECK(seen.argv[2] == "--runtime-file");
    CHECK(seen.argv[3] == (lab.tools_dir() / lab.runtime_name()).string());
    CHECK(stdfs::path(seen.argv[4]).filename().string() == ".space-dodge-linux.AppDir");
    CHECK(stdfs::path(seen.argv[5]).generic_string() == r->artifact);
    CHECK(seen.env["ARCH"] == "x86_64");
    CHECK(seen.env["APPIMAGE_EXTRACT_AND_RUN"] == "1");

    // The AppDir: AppRun, the .desktop, the icon twice, and the export folder under usr/bin (without what sits at the top).
    CHECK(contains(seen.files, "AppRun"));
    CHECK(contains(seen.files, "space-dodge.desktop"));
    CHECK(contains(seen.files, "space-dodge.png"));
    CHECK(contains(seen.files, ".DirIcon"));
    CHECK(contains(seen.files, "usr/bin/space-dodge"));
    CHECK(contains(seen.files, "usr/bin/game"));
    CHECK(contains(seen.files, "usr/bin/FACTORIA_NOTICES.txt"));
    CHECK(contains(seen.files, "usr/bin/libdemo.so"));  // the plugins' libraries sit next to the player, where it looks for them
    CHECK_FALSE(contains(seen.files, "usr/bin/.factoria-export"));
    CHECK_FALSE(contains(seen.files, "usr/bin/space-dodge.desktop"));
    CHECK_FALSE(contains(seen.files, "usr/bin/space-dodge.png"));
    CHECK_FALSE(contains(seen.files, "usr/bin/space-dodge-x86_64.AppImage"));
    CHECK(seen.iconIsPng);
    CHECK(seen.dirIconIsPng);

    CHECK(has_text(seen.appRun, "#!/bin/sh"));
    CHECK(has_text(seen.appRun, "${APPDIR:-"));  // the runtime sets APPDIR; unpacked, the script finds its own folder
    CHECK(has_text(seen.appRun, "exec \"$here/usr/bin/space-dodge\" \"$@\""));

    // <slug>.desktop: the export's entry with the Icon the AppImage needs and the version.
    CHECK(has_text(seen.desktop, "[Desktop Entry]\n"));
    CHECK(has_text(seen.desktop, "Name=Space Dodge\n"));
    CHECK(has_text(seen.desktop, "Exec=space-dodge\n"));
    CHECK(has_text(seen.desktop, "Icon=space-dodge\n"));
    CHECK(has_text(seen.desktop, "Categories=Game;ArcadeGame;\n"));
    CHECK(has_text(seen.desktop, "X-AppImage-Version=1.2.3\n"));
    CHECK(seen.desktop.find("Icon=") == seen.desktop.rfind("Icon="));  // exactly one

    // Afterwards: the AppDir is gone, the export folder is still the folder export, the next steps start with the AppImage.
    CHECK_FALSE(stdfs::exists(lab.tmp.sub("out/.space-dodge-linux.AppDir")));
    CHECK(stdfs::exists(stdfs::path(r->outputDir) / "space-dodge"));
    CHECK(stdfs::exists(stdfs::path(r->outputDir) / "space-dodge.desktop"));
    REQUIRE(r->nextSteps.size() >= 2);
    CHECK(has_text(r->nextSteps[0], "space-dodge-x86_64.AppImage"));
    CHECK(has_text(r->nextSteps[0], "--appimage-extract-and-run"));
    CHECK(has_text(r->nextSteps[1], "space-dodge-x86_64.AppImage"));
    CHECK(any_has(r->nextSteps, "tar czf"));  // the folder's own next steps stay
    CHECK(r->to_json()["format"] == "appimage");
    CHECK(r->to_json()["artifact"] == r->artifact);

    // Exporting again replaces the folder, AppImage included.
    auto again = export_project(o);
    REQUIRE_MESSAGE(again.ok(), (again.ok() ? "" : again.error().to_string()));
    CHECK(lab.runs.size() == 2);
}

TEST_CASE("export appimage: a game without an icon gets a placeholder and a warning") {
    Lab lab;
    lab.install_fake_tools();
    Seen seen;
    fake_appimagetool(lab, seen);
    SetupContext c = lab.ctx();
    ExportOptions o;
    o.projectDir = make_game(lab.tmp, false);
    o.platform = "linux";
    o.format = "AppImage";  // not case sensitive
    o.outDir = lab.tmp.sub("out");
    o.playerBinary = make_player(lab.tmp);
    o.setup = &c;
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(seen.iconIsPng);
    CHECK(seen.dirIconIsPng);
    CHECK(has_text(seen.desktop, "Icon=space-dodge\n"));
    CHECK(any_has(r->warnings, "placeholder icon"));
    CHECK_FALSE(stdfs::exists(stdfs::path(r->outputDir) / "space-dodge.png"));  // the folder export itself has none
}

TEST_CASE("export appimage: other computers, other platforms and missing tools get an error that teaches") {
    SUBCASE("a Mac, Windows or a Linux that is not x86_64") {
        for (auto [host, arch] : std::vector<std::pair<std::string, std::string>>{{"macos", "aarch64"}, {"windows", "x64"}, {"linux", "aarch64"}}) {
            INFO(host << "-" << arch);
            Lab lab;
            SetupContext c = lab.ctx(host, arch);
            ExportOptions o;
            o.projectDir = make_game(lab.tmp);
            o.platform = "linux";
            o.format = "appimage";
            o.outDir = lab.tmp.sub("out");
            o.playerBinary = make_player(lab.tmp);
            o.setup = &c;
            auto planned = plan_export(o);
            REQUIRE_FALSE(planned.ok());
            CHECK(has_text(planned.error().message, "AppImage can only be built on Linux x86_64"));
            CHECK(has_text(planned.error().message, host + "-" + arch));
            auto failed = export_project(o);
            REQUIRE_FALSE(failed.ok());
            CHECK(failed.error().message == planned.error().message);
            CHECK(has_text(failed.error().hint, "WSL"));
            CHECK(has_text(failed.error().hint, "--format appimage"));
            CHECK_FALSE(stdfs::exists(lab.tmp.sub("out")));  // refused before anything was written
            CHECK(lab.runs.empty());
        }
    }
    SUBCASE("the tools are not installed") {
        Lab lab;
        SetupContext c = lab.ctx();
        ExportOptions o;
        o.projectDir = make_game(lab.tmp);
        o.platform = "linux";
        o.format = "appimage";
        o.outDir = lab.tmp.sub("out");
        o.playerBinary = make_player(lab.tmp);
        o.setup = &c;
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "appimagetool"));
        CHECK(has_text(r.error().message, "not installed"));
        CHECK(has_text(r.error().hint, "factoria setup appimage"));
        CHECK_FALSE(stdfs::exists(lab.tmp.sub("out")));
        CHECK(lab.requested.empty());  // an export never downloads anything by itself
    }
    SUBCASE("only linux has the format") {
        Lab lab;
        SetupContext c = lab.ctx();
        ExportOptions o;
        o.projectDir = make_game(lab.tmp);
        o.platform = "windows";
        o.format = "appimage";
        o.outDir = lab.tmp.sub("out");
        o.playerBinary = make_player(lab.tmp);
        o.setup = &c;
        auto plan = plan_export(o);
        REQUIRE_MESSAGE(plan.ok(), (plan.ok() ? "" : plan.error().to_string()));
        CHECK(plan->format.empty());
        CHECK(plan->artifact.empty());
        CHECK(any_has(plan->warnings, "appimage"));  // ignored, with a note that names where it applies
        CHECK(any_has(plan->warnings, "linux"));
    }
    SUBCASE("a format that does not exist") {
        Lab lab;
        CommandRegistry registry;
        register_export_commands(registry, make_game(lab.tmp));
        auto r = registry.call("project.export", Json::object({{"platform", "linux"}, {"format", "flatpak"}, {"dryRun", true}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "invalid_arguments");  // the schema's enum lists appimage
        CHECK(has_text(r.error["message"].get<std::string>(), "flatpak"));
        CHECK(has_text(r.error["hint"].get<std::string>(), "appimage"));
    }
}

TEST_CASE("export appimage: when appimagetool fails the folder is complete and the AppDir is gone") {
    Lab lab;
    lab.install_fake_tools();
    Seen seen;
    SetupContext c = lab.ctx();
    ExportOptions o;
    o.projectDir = make_game(lab.tmp);
    o.platform = "linux";
    o.format = "appimage";
    o.outDir = lab.tmp.sub("out");
    o.playerBinary = make_player(lab.tmp);
    o.setup = &c;

    SUBCASE("a non-zero exit code quotes what it said") {
        fake_appimagetool(lab, seen, 1);
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "appimagetool failed (exit code 1)"));
        CHECK(has_text(r.error().message, "Icon not found"));
        CHECK_FALSE(r.error().hint.empty());
    }
    SUBCASE("exit code 0 without a file") {
        fake_appimagetool(lab, seen, 0, false);
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "was not written"));
    }
    SUBCASE("it cannot start") {
        lab.program = [](const ProcessOptions&) -> Result<ProcessResult> { return make_error("Exec format error"); };
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "cannot run appimagetool"));
        CHECK(has_text(r.error().hint, "factoria setup appimage --force"));
    }
    CHECK_FALSE(stdfs::exists(lab.tmp.sub("out/.space-dodge-linux.AppDir")));
    CHECK(stdfs::exists(lab.tmp.sub("out/space-dodge-linux/space-dodge")));  // the plain export is all there
}
