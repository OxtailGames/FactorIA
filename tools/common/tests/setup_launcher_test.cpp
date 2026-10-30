// `factoria setup launcher`: the app that opens the editor with the FactorIA icon. Every folder is a temporary one: the
// HOME the installer writes to is a test directory, never the real ~/Applications or ~/.local/share, and Launch Services
// is a fake process runner.
#include <doctest.h>

#include <filesystem>
#include <string>
#include <vector>

#include "fa/tooling/bundle.h"
#include "fa/tooling/setup.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct LauncherWorld {
    testing::TempDir tmp;
    SetupContext ctx;
    std::vector<std::vector<std::string>> runs;  // what the installer asked to run (lsregister)
    stdfs::path home() const { return tmp.path / "home"; }
    stdfs::path exe() const { return tmp.path / "bin" / "factoria"; }
    stdfs::path app() const { return home() / "Applications" / "FactorIA.app"; }
    stdfs::path desktop() const { return home() / ".local" / "share" / "applications" / "factoria.desktop"; }
    explicit LauncherWorld(const std::string& host) {
        testing::write_all(exe(), "binary");
        const std::string h = home().string();
        ctx.env = [h](const std::string& n) { return n == "HOME" ? h : std::string(); };
        ctx.home = (tmp.path / "factoria_home").string();
        ctx.engineVersion = "9.8.7";
        ctx.executableDir = (tmp.path / "bin").string();
        ctx.host = host;
        ctx.run = [this](const ProcessOptions& o) -> Result<ProcessResult> {
            runs.push_back(o.argv);
            ProcessResult pr;
            pr.exitCode = 0;
            return pr;
        };
        stdfs::create_directories(home());
    }
    SetupComponent status() const {
        const SetupStatus st = setup_status(ctx, "launcher", false);
        REQUIRE(st.components.size() == 1);
        return st.components[0];
    }
    SetupResult install(bool force = false) const {
        SetupInstallOptions o;
        o.component = "launcher";
        o.force = force;
        return setup_install(o, ctx);
    }
};

}  // namespace

TEST_CASE("setup launcher (macOS): missing, then an app in ~/Applications that opens this factoria with the FactorIA icon") {
    LauncherWorld w("macos");
    CHECK(w.status().state == "missing");
    CHECK(w.status().canInstall);

    SetupResult r = w.install();
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(r.report.changed);
    CHECK(w.status().state == "installed");

    const std::string script = testing::read_all(w.app() / "Contents/MacOS/FactorIA");
    CHECK(script.rfind("#!/bin/zsh\n", 0) == 0);
    CHECK(script.find("FACTORIA='" + w.exe().string() + "'") != std::string::npos);
    CHECK(script.find("exec \"$FACTORIA\" editor") != std::string::npos);
    CHECK((stdfs::status(w.app() / "Contents/MacOS/FactorIA").permissions() & stdfs::perms::owner_exec) != stdfs::perms::none);
    const std::string plist = testing::read_all(w.app() / "Contents/Info.plist");
    CHECK(plist.find("<string>9.8.7</string>") != std::string::npos);
    CHECK(plist.find("<key>CFBundleIconFile</key><string>AppIcon</string>") != std::string::npos);
    CHECK(testing::read_all(w.app() / "Contents/Resources/AppIcon.icns") == bundled_read("tools/editor/icon/factoria.icns").value_or("?"));

    // Launch Services is told about the app, so the Dock reads the new icon.
    REQUIRE(w.runs.size() == 1);
    CHECK(w.runs[0].back() == w.app().string());
    CHECK(w.runs[0][0].find("lsregister") != std::string::npos);

    // Again: nothing to do, nothing run.
    r = w.install();
    REQUIRE(r.ok);
    CHECK_FALSE(r.report.changed);
    CHECK(w.runs.size() == 1);
}

TEST_CASE("setup launcher: an update makes it partial, and refresh_launcher rewrites it in place") {
    LauncherWorld w("macos");
    REQUIRE(w.install().ok);
    testing::write_all(w.app() / "Contents/Resources/keep.txt", "the folder is not replaced");

    w.ctx.engineVersion = "9.9.0";  // the same factoria after an update: a new version (and maybe icon)
    const SetupComponent c = w.status();
    CHECK(c.state == "partial");
    REQUIRE(c.problems.size() == 1);
    CHECK(c.problems[0].find("out of date") != std::string::npos);

    CHECK(refresh_launcher(w.ctx));
    CHECK(w.status().state == "installed");
    CHECK(testing::read_all(w.app() / "Contents/Info.plist").find("<string>9.9.0</string>") != std::string::npos);
    CHECK(stdfs::exists(w.app() / "Contents/Resources/keep.txt"));
    CHECK_FALSE(refresh_launcher(w.ctx));  // up to date: nothing to do
}

TEST_CASE("setup launcher: refresh_launcher leaves alone a missing launcher and one that opens another factoria") {
    LauncherWorld w("macos");
    CHECK_FALSE(refresh_launcher(w.ctx));
    CHECK_FALSE(stdfs::exists(w.app()));

    REQUIRE(w.install().ok);
    // A development build runs the editor: the launcher keeps opening the installed factoria.
    testing::write_all(w.tmp.path / "dev" / "factoria", "dev binary");
    SetupContext dev = w.ctx;
    dev.executableDir = (w.tmp.path / "dev").string();
    const SetupComponent c = setup_status(dev, "launcher", false).components.at(0);
    CHECK(c.state == "partial");
    REQUIRE(c.problems.size() == 1);
    CHECK(c.problems[0].find("not this factoria") != std::string::npos);
    CHECK_FALSE(refresh_launcher(dev));
    CHECK(testing::read_all(w.app() / "Contents/MacOS/FactorIA").find(w.exe().string()) != std::string::npos);

    // An explicit install points it at the factoria that runs it.
    SetupInstallOptions o;
    o.component = "launcher";
    REQUIRE(setup_install(o, dev).ok);
    CHECK(setup_status(dev, "launcher", false).components.at(0).state == "installed");
}

TEST_CASE("setup launcher: a hand-made app in its place is reported and replaced on install") {
    LauncherWorld w("macos");
    testing::write_all(w.app() / "Contents/MacOS/FactorIA", "#!/bin/zsh\nexec \"$HOME/FactorIA/factoria\" editor\n");
    const SetupComponent c = w.status();
    CHECK(c.state == "partial");
    REQUIRE(c.problems.size() == 1);
    CHECK(c.problems[0].find("not written by `factoria setup launcher`") != std::string::npos);
    CHECK_FALSE(refresh_launcher(w.ctx));  // not ours: only an explicit install replaces it
    REQUIRE(w.install().ok);
    CHECK(w.status().state == "installed");
}

TEST_CASE("setup launcher (Linux): a .desktop entry and its icon under ~/.local/share, or XDG_DATA_HOME") {
    LauncherWorld w("linux");
    CHECK(w.status().state == "missing");
    REQUIRE(w.install().ok);
    CHECK(w.status().state == "installed");
    const std::string entry = testing::read_all(w.desktop());
    CHECK(entry.find("Exec=\"" + w.exe().string() + "\" editor\n") != std::string::npos);
    CHECK(entry.find("X-FactorIA-Path=" + w.exe().string() + "\n") != std::string::npos);
    const stdfs::path icon = w.home() / ".local/share/icons/hicolor/256x256/apps/factoria.png";
    CHECK(entry.find("Icon=" + icon.string() + "\n") != std::string::npos);
    CHECK(testing::read_all(icon) == bundled_read("platforms/linux/factoria.png").value_or("?"));
    CHECK(w.runs.empty());  // nothing to register on Linux

    const std::string data = (w.tmp.path / "xdg").string();
    const std::string h = w.home().string();
    w.ctx.env = [h, data](const std::string& n) { return n == "HOME" ? h : n == "XDG_DATA_HOME" ? data : std::string(); };
    CHECK(w.status().state == "missing");
    REQUIRE(w.install().ok);
    CHECK(stdfs::is_regular_file(stdfs::path(data) / "applications/factoria.desktop"));
}

TEST_CASE("setup launcher: not needed on Windows") {
    LauncherWorld w("windows");
    CHECK(w.status().state == "unsupported");
    const SetupResult r = w.install();
    CHECK_FALSE(r.ok);
    CHECK(r.code == "unsupported");
    CHECK_FALSE(refresh_launcher(w.ctx));
}

TEST_CASE("editor_restart_command (macOS): through the launcher of this factoria, with the project as an argument") {
    LauncherWorld w("macos");
    const std::string project = (w.tmp.path / "My Games" / "it's a game").string();  // spaces and a quote stay one argument

    CHECK(editor_restart_command(w.ctx, project).empty());  // no launcher yet
    REQUIRE(w.install().ok);
    CHECK(testing::read_all(w.app() / "Contents/MacOS/FactorIA").find("editor \"$@\"") != std::string::npos);

    const std::vector<std::string> cmd = editor_restart_command(w.ctx, project);
    REQUIRE(cmd.size() == 5);
    CHECK(cmd[0] == "/usr/bin/open");
    CHECK(cmd[1] == "-n");  // the old editor is still alive while it quits
    CHECK(cmd[2] == w.app().string());
    CHECK(cmd[3] == "--args");
    CHECK(cmd[4] == project);

    // No project (the start screen): still the launcher, without the arguments.
    const std::vector<std::string> bare = editor_restart_command(w.ctx, "");
    REQUIRE(bare.size() == 3);
    CHECK(bare[0] == "/usr/bin/open");
    CHECK(bare[1] == "-n");
    CHECK(bare[2] == w.app().string());
}

TEST_CASE("editor_restart_command (macOS): an out-of-date, foreign or another factoria's launcher is not used") {
    LauncherWorld w("macos");
    REQUIRE(w.install().ok);
    const std::string project = (w.tmp.path / "game").string();
    REQUIRE_FALSE(editor_restart_command(w.ctx, project).empty());

    SetupContext updated = w.ctx;
    updated.engineVersion = "9.9.0";  // not rewritten yet
    CHECK(editor_restart_command(updated, project).empty());
    CHECK(refresh_launcher(updated));
    CHECK_FALSE(editor_restart_command(updated, project).empty());

    // An old launcher (it ignored its arguments) is out of date, so the editor rewrites it before a restart needs it.
    testing::write_all(w.app() / "Contents/MacOS/FactorIA",
                       "#!/bin/zsh\nFACTORIA='" + w.exe().string() + "'\nexec \"$FACTORIA\" editor\n");
    CHECK(editor_restart_command(w.ctx, project).empty());

    // A development build.
    REQUIRE(w.install(true).ok);
    testing::write_all(w.tmp.path / "dev" / "factoria", "dev binary");
    SetupContext dev = w.ctx;
    dev.executableDir = (w.tmp.path / "dev").string();
    CHECK(editor_restart_command(dev, project).empty());

    // A hand-made app.
    testing::write_all(w.app() / "Contents/MacOS/FactorIA", "#!/bin/zsh\nexec something\n");
    CHECK(editor_restart_command(w.ctx, project).empty());
}

TEST_CASE("editor_restart_command (Windows): FactorIA-Editor.exe next to factoria.exe; Linux: none, the WM class groups") {
    LauncherWorld w("windows");
    const std::string project = (w.tmp.path / "My Games").string();
    CHECK(editor_restart_command(w.ctx, project).empty());  // no factoria.exe, no launcher
    testing::write_all(w.tmp.path / "bin" / "factoria.exe", "binary");
    CHECK(editor_restart_command(w.ctx, project).empty());
    testing::write_all(w.tmp.path / "bin" / "FactorIA-Editor.exe", "launcher");
    const std::vector<std::string> cmd = editor_restart_command(w.ctx, project);
    REQUIRE(cmd.size() == 2);
    CHECK(stdfs::path(cmd[0]).filename() == "FactorIA-Editor.exe");
    CHECK(cmd[1] == project);
    const std::vector<std::string> bare = editor_restart_command(w.ctx, "");  // start screen: no project argument
    REQUIRE(bare.size() == 1);
    CHECK(stdfs::path(bare[0]).filename() == "FactorIA-Editor.exe");

    LauncherWorld l("linux");
    REQUIRE(l.install().ok);
    CHECK(testing::read_all(l.desktop()).find("StartupWMClass=FactorIA\n") != std::string::npos);
    CHECK(editor_restart_command(l.ctx, project).empty());
}
