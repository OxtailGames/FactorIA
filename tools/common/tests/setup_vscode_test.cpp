// `factoria setup vscode`: the VS Code extension of the script debugger (tools/vscode/, templates' launch.json). Every folder is a
// temporary one: the "home" the installer writes to is a test directory, never the real ~/.vscode.
#include <doctest.h>

#include <filesystem>
#include <set>

#include "fa/core/json.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/setup.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct VsWorld {
    testing::TempDir tmp;
    SetupContext ctx;
    stdfs::path home() const { return tmp.path / "home"; }
    // ctx.host is "linux", so the installer looks for factoria without .exe on every platform.
    stdfs::path exe() const { return tmp.path / "bin" / "factoria"; }
    VsWorld() {
        testing::write_all(exe(), "binary");
        const std::string h = home().string();
        ctx.env = [h](const std::string& n) { return (n == "HOME" || n == "USERPROFILE") ? h : std::string(); };
        ctx.home = (tmp.path / "factoria_home").string();
        ctx.engineVersion = "9.8.7";
        ctx.executableDir = (tmp.path / "bin").string();
        ctx.host = "linux";
        stdfs::create_directories(home());
    }
    stdfs::path ext(const std::string& editor, const std::string& version = "9.8.7") const {
        return home() / editor / "extensions" / ("oxtailgames.factoria-" + version);
    }
    std::string state() const {
        const SetupStatus st = setup_status(ctx, "vscode", false);
        REQUIRE(st.components.size() == 1);
        return st.components[0].state;
    }
};

}  // namespace

TEST_CASE("setup vscode: missing, then installed, with the version stamped and the path of this factoria recorded") {
    VsWorld w;
    CHECK(w.state() == "missing");
    CHECK(setup_status(w.ctx, "vscode", false).components[0].canInstall);

    SetupInstallOptions o;
    o.component = "vscode";
    SetupResult r = setup_install(o, w.ctx);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(r.report.changed);
    CHECK(w.state() == "installed");

    const stdfs::path dir = w.ext(".vscode");
    CHECK(stdfs::is_regular_file(dir / "extension.js"));
    CHECK(stdfs::is_regular_file(dir / "README.md"));
    const Json pkg = Json::parse(testing::read_all(dir / "package.json"));
    CHECK(pkg["version"] == "9.8.7");
    CHECK(pkg["name"] == "factoria");
    CHECK(pkg["publisher"] == "oxtailgames");
    std::string recorded = testing::read_all(dir / "factoria-path.txt");
    while (!recorded.empty() && (recorded.back() == '\n' || recorded.back() == '\r')) recorded.pop_back();
    CHECK(recorded == w.exe().string());

    // Editors that are not installed are not created.
    CHECK_FALSE(stdfs::exists(w.home() / ".vscode-insiders"));
    CHECK_FALSE(stdfs::exists(w.home() / ".cursor"));

    // Again: nothing to do.
    r = setup_install(o, w.ctx);
    REQUIRE(r.ok);
    CHECK_FALSE(r.report.changed);
}

TEST_CASE("setup vscode: also installs into Insiders, VSCodium and Cursor when they exist, and removes older versions") {
    VsWorld w;
    for (const char* e : {".vscode-insiders", ".vscode-oss", ".cursor"}) stdfs::create_directories(w.home() / e / "extensions");
    testing::write_all(w.ext(".vscode", "1.0.0") / "package.json", "{}");
    testing::write_all(w.ext(".cursor", "0.0.1") / "extension.js", "old");
    testing::write_all(w.home() / ".vscode" / "extensions" / "someone.else-1.0.0" / "package.json", "{}");
    CHECK(w.state() == "missing");

    SetupInstallOptions o;
    o.component = "vscode";
    const SetupResult r = setup_install(o, w.ctx);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    for (const char* e : {".vscode", ".vscode-insiders", ".vscode-oss", ".cursor"}) {
        CHECK_MESSAGE(stdfs::is_regular_file(w.ext(e) / "extension.js"), e);
        CHECK_MESSAGE(stdfs::is_regular_file(w.ext(e) / "factoria-path.txt"), e);
    }
    CHECK_FALSE(stdfs::exists(w.ext(".vscode", "1.0.0")));
    CHECK_FALSE(stdfs::exists(w.ext(".cursor", "0.0.1")));
    CHECK(stdfs::exists(w.home() / ".vscode" / "extensions" / "someone.else-1.0.0"));  // other extensions are left alone
    CHECK(w.state() == "installed");

    // One editor lacking the copy makes the component partial.
    stdfs::remove_all(w.ext(".cursor"));
    CHECK(w.state() == "partial");
}

TEST_CASE("setup vscode: a copy that records another factoria is not installed") {
    VsWorld w;
    SetupInstallOptions o;
    o.component = "vscode";
    REQUIRE(setup_install(o, w.ctx).ok);
    testing::write_all(w.ext(".vscode") / "factoria-path.txt", "/somewhere/else/factoria\n");
    CHECK(w.state() == "partial");
    const SetupResult r = setup_install(o, w.ctx);
    REQUIRE(r.ok);
    CHECK(r.report.changed);
    CHECK(w.state() == "installed");
}

TEST_CASE("setup vscode: a new version replaces the old folder") {
    VsWorld w;
    SetupInstallOptions o;
    o.component = "vscode";
    REQUIRE(setup_install(o, w.ctx).ok);
    w.ctx.engineVersion = "9.9.0";
    CHECK(w.state() == "missing");
    REQUIRE(setup_install(o, w.ctx).ok);
    CHECK(stdfs::exists(w.ext(".vscode", "9.9.0")));
    CHECK_FALSE(stdfs::exists(w.ext(".vscode", "9.8.7")));
}

TEST_CASE("setup vscode: an existing extensions.json keeps the other entries, replaces ours and gains the new one") {
    VsWorld w;
    const stdfs::path reg = w.home() / ".vscode" / "extensions" / "extensions.json";
    testing::write_all(reg, R"([
      {"identifier":{"id":"someone.else"},"version":"1.0.0","relativeLocation":"someone.else-1.0.0","location":{"$mid":1,"path":"/x","scheme":"file"}},
      {"identifier":{"id":"OxtailGames.Factoria"},"version":"1.0.0","relativeLocation":"oxtailgames.factoria-1.0.0"}
    ])");
    testing::write_all(w.ext(".vscode", "1.0.0") / "package.json", "{}");
    CHECK(w.state() == "missing");

    SetupInstallOptions o;
    o.component = "vscode";
    const SetupResult r = setup_install(o, w.ctx);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(r.report.warnings.empty());
    const Json list = Json::parse(testing::read_all(reg));
    REQUIRE(list.is_array());
    REQUIRE(list.size() == 2);
    CHECK(list[0]["identifier"]["id"] == "someone.else");
    CHECK(list[0]["relativeLocation"] == "someone.else-1.0.0");
    CHECK(list[1]["identifier"]["id"] == "oxtailgames.factoria");
    CHECK(list[1]["version"] == "9.8.7");
    CHECK(list[1]["relativeLocation"] == "oxtailgames.factoria-9.8.7");
    CHECK(list[1]["location"]["scheme"] == "file");
    CHECK(list[1]["location"]["path"].get<std::string>().find("oxtailgames.factoria-9.8.7") != std::string::npos);
    CHECK(list[1]["metadata"]["installedTimestamp"].is_number());
    CHECK(w.state() == "installed");

    // Installing again does not duplicate it.
    SetupInstallOptions force = o;
    force.force = true;
    REQUIRE(setup_install(force, w.ctx).ok);
    CHECK(Json::parse(testing::read_all(reg)).size() == 2);
}

TEST_CASE("setup vscode: a missing extensions.json is not created; .obsolete loses our folders") {
    VsWorld w;
    const stdfs::path extDir = w.home() / ".vscode" / "extensions";
    testing::write_all(extDir / ".obsolete", R"({"oxtailgames.factoria-9.8.7":true,"someone.else-1.0.0":true})");
    SetupInstallOptions o;
    o.component = "vscode";
    REQUIRE(setup_install(o, w.ctx).ok);
    CHECK_FALSE(stdfs::exists(extDir / "extensions.json"));
    CHECK(w.state() == "installed");
    const Json obsolete = Json::parse(testing::read_all(extDir / ".obsolete"));
    CHECK_FALSE(obsolete.contains("oxtailgames.factoria-9.8.7"));
    CHECK(obsolete.contains("someone.else-1.0.0"));
}

TEST_CASE("setup vscode: the folder alone is not installed when extensions.json does not list it") {
    VsWorld w;
    SetupInstallOptions o;
    o.component = "vscode";
    REQUIRE(setup_install(o, w.ctx).ok);
    testing::write_all(w.home() / ".vscode" / "extensions" / "extensions.json", "[]");
    CHECK(w.state() == "missing");
}

TEST_CASE("setup vscode: the unknown-component error lists vscode") {
    VsWorld w;
    SetupInstallOptions o;
    o.component = "vscod";
    const SetupResult r = setup_install(o, w.ctx);
    CHECK_FALSE(r.ok);
    CHECK(r.error.hint.find("vscode") != std::string::npos);
}

TEST_CASE("vscode extension: the embedded package.json declares the factoria debugger with the launch attributes of the design") {
    const auto text = bundled_read("tools/vscode/package.json");
    REQUIRE(text);
    const Json pkg = Json::parse(*text);
    CHECK(pkg["publisher"] == "oxtailgames");
    CHECK(pkg["name"] == "factoria");
    CHECK(pkg["main"] == "./extension.js");
    REQUIRE(bundled_read("tools/vscode/extension.js"));
    REQUIRE(bundled_read("tools/vscode/README.md"));

    const Json& dbg = pkg["contributes"]["debuggers"][0];
    CHECK(dbg["type"] == "factoria");
    const Json& props = dbg["configurationAttributes"]["launch"]["properties"];
    for (const char* key : {"mode", "project", "scene", "frames", "input", "tests", "filter", "stopOnEntry", "factoriaPath"}) {
        REQUIRE_MESSAGE(props.contains(key), key);
        CHECK_MESSAGE(!props[key].value("description", "").empty(), key);
    }
    CHECK(props["mode"]["enum"] == Json::array({"play", "headless", "test"}));
    std::set<std::string> names;
    for (const Json& c : dbg["initialConfigurations"]) {
        CHECK(c["type"] == "factoria");
        CHECK(c["request"] == "launch");
        names.insert(c["mode"].get<std::string>());
    }
    CHECK(names == std::set<std::string>{"play", "headless", "test"});
    CHECK(dbg["configurationSnippets"].size() == 3);
    CHECK(pkg["contributes"]["breakpoints"][0]["language"] == "javascript");
}

TEST_CASE("templates: every new project gets a .vscode/launch.json with Play, Headless and Tests") {
    for (const TemplateInfo& t : list_templates()) {
        testing::TempDir tmp;
        ScaffoldOptions so;
        so.writeTypings = false;
        auto r = create_project(tmp.sub("game"), t.name, so);
        REQUIRE_MESSAGE(r.ok(), t.name);
        const stdfs::path file = tmp.path / "game" / ".vscode" / "launch.json";
        REQUIRE_MESSAGE(stdfs::is_regular_file(file), t.name);
        const Json j = Json::parse(testing::read_all(file));
        std::set<std::string> modes;
        for (const Json& c : j["configurations"]) {
            CHECK(c["type"] == "factoria");
            CHECK(c["request"] == "launch");
            modes.insert(c["mode"].get<std::string>());
        }
        CHECK_MESSAGE((modes == std::set<std::string>{"play", "headless", "test"}), t.name);
    }
}
