// publish.steam / publish.itch / publish.epic / publish.gog (tools/common/src/publish*.cpp): the "publish" section of
// factoria.json, the build files and command lines of each store (dry run), the teaching errors, and real runs against a
// fake uploader (test_tools/fake_store_tool.cpp) that records its arguments. No test talks to a real store.
#include <doctest.h>

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <map>
#include <sstream>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/tooling/publish.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const std::string kFakeTool = FA_FAKE_STORE_TOOL;  // the fake uploader, a build product of this test target

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

// Sets an environment variable of THIS process for a scope (the fake uploader inherits it); "" removes it.
struct ScopedEnv {
    std::string name, old;
    bool had = false;
    ScopedEnv(const std::string& n, const std::string& value) : name(n) {
        const char* current = std::getenv(n.c_str());
        had = current != nullptr;
        if (had) old = current;
        set(value);
    }
    ~ScopedEnv() { set(had ? old : std::string()); }
    ScopedEnv(const ScopedEnv&) = delete;
    ScopedEnv& operator=(const ScopedEnv&) = delete;
    void set(const std::string& value) const {
#ifdef _WIN32
        _putenv_s(name.c_str(), value.c_str());
#else
        if (value.empty()) unsetenv(name.c_str());
        else setenv(name.c_str(), value.c_str(), 1);
#endif
    }
};

struct Call {
    std::vector<std::string> args;
    std::map<std::string, std::string> env;
};

std::vector<Call> read_calls(const std::string& record) {
    std::vector<Call> calls;
    std::istringstream in(testing::read_all(record));
    for (std::string line; std::getline(in, line);) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line == "call") calls.emplace_back();
        else if (line.rfind("arg: ", 0) == 0 && !calls.empty()) calls.back().args.push_back(line.substr(5));
        else if (line.rfind("env: ", 0) == 0 && !calls.empty()) {
            const std::string kv = line.substr(5);
            calls.back().env[kv.substr(0, kv.find('='))] = kv.substr(kv.find('=') + 1);
        }
    }
    return calls;
}

const char* const kFullPublish = R"({"publish": {
    "steam": {"account": "mystudio_build", "depots": {"windows": 1234561, "macos": "1234562", "linux": 1234563}},
    "itch": {"game": "mystudio/space-dodge"},
    "epic": {"organizationId": "o-abc", "productId": "prod1", "clientId": "xyzclient",
             "artifacts": {"windows": "art-win", "macos": "art-mac", "linux": "art-lin"}},
    "gog": {"productId": "1207658930", "clientId": "5555", "languages": ["en-US", "fr-FR"]}}})";

// A game "Space Dodge" 1.2.3 with the three desktop exports project.export would have written (hand-made: the files that
// matter to an upload), a Steam app id, and an environment in which every tool is the fake uploader.
struct Fixture {
    testing::TempDir tmp;
    std::string dir = tmp.sub("space");
    std::string record = tmp.sub("record.txt");
    std::string config = tmp.sub("no-export-config.json");  // does not exist: the machine's own file is never read
    std::map<std::string, std::string> vars = {{"FACTORIA_STEAMCMD", kFakeTool},
                                               {"FACTORIA_BUTLER", kFakeTool},
                                               {"FACTORIA_BUILDPATCHTOOL", kFakeTool},
                                               {"FACTORIA_GOG_PIPELINE_BUILDER", kFakeTool},
                                               {"FACTORIA_XCRUN", kFakeTool},
                                               {"FACTORIA_FASTLANE", kFakeTool}};

    explicit Fixture(const char* publishJson = kFullPublish) {
        ScaffoldOptions so;
        so.name = "Space Dodge";
        so.writeTypings = false;
        REQUIRE(create_project(dir, "2d-empty", so).ok());
        auto j = load_json_file(dir + "/factoria.json");
        REQUIRE(j.ok());
        (*j)["version"] = "1.2.3";
        json_merge(*j, *parse_json(publishJson));
        REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
        testing::write_all(dir + "/steam_appid.txt", "1234560\n");

        const std::string out = dir + "/build/export/";
        for (const std::string& platform : {"windows", "macos", "linux"}) {
            testing::write_all(out + "space-dodge-" + platform + "/.factoria-export", "written by an export");
            testing::write_all(out + "space-dodge-" + platform + "/AI_CONTENT_DISCLOSURE.md", "ai");
        }
        testing::write_all(out + "space-dodge-windows/space-dodge.exe", "exe");
        testing::write_all(out + "space-dodge-windows/FACTORIA_NOTICES.txt", "licenses");
        testing::write_all(out + "space-dodge-windows/game/factoria.json", "{}");
        testing::write_all(out + "space-dodge-macos/Space Dodge.app/Contents/MacOS/space-dodge", "mach-o");
        testing::write_all(out + "space-dodge-macos/Space Dodge.app/Contents/Info.plist", "plist");
        testing::write_all(out + "space-dodge-linux/space-dodge", "elf");
    }

    PublishOptions options(const std::string& store) const {
        PublishOptions o;
        o.store = store;
        o.projectDir = dir;
        auto copy = vars;
        o.env = [copy](const std::string& name) {
            auto it = copy.find(name);
            return it == copy.end() ? std::string() : it->second;
        };
        o.toolConfigPath = config;
        return o;
    }

    std::string export_dir(const std::string& platform) const { return stdfs::weakly_canonical(dir + "/build/export/space-dodge-" + platform).generic_string(); }

    PublishReport ok(const PublishOptions& o) const {
        auto r = publish_project(o);
        const std::string why = r.ok() ? std::string() : r.error().to_string();
        INFO(why);
        REQUIRE(r.ok());
        return std::move(r.value());
    }
    // A real run (not a dry run) stops at what is missing; a dry run only warns about it (see "publish dry run: a missing ...").
    Error fails(PublishOptions o) const {
        o.dryRun = false;
        auto r = publish_project(o);
        REQUIRE_FALSE(r.ok());
        return r.error();
    }
};

const Json* find_step(const Json& report, std::size_t i) { return &report["steps"][i]; }

}  // namespace

// ---- the "publish" section of factoria.json --------------------------------------------------------------------------

TEST_CASE("publish settings: the ids of each store are read, store ids may be numbers or text") {
    auto parsed = parse_publish_settings(*parse_json(kFullPublish));
    CHECK(parsed.errors.empty());
    CHECK(parsed.warnings.empty());
    const PublishSettings& s = parsed.settings;
    CHECK(s.steam.account == "mystudio_build");
    CHECK(s.steam.depots.at("windows") == 1234561);
    CHECK(s.steam.depots.at("macos") == 1234562);  // written as text
    CHECK(s.itch.game == "mystudio/space-dodge");
    CHECK(itch_channel_for(s.itch, "macos") == "mac");  // the defaults
    CHECK(itch_channel_for(s.itch, "linux") == "linux");
    CHECK(s.epic.artifacts.at("linux") == "art-lin");
    CHECK(s.gog.productId == "1207658930");
    CHECK(s.gog.clientId == "5555");
    CHECK(s.gog.languages == std::vector<std::string>{"en-US", "fr-FR"});
    CHECK(parse_publish_settings(*parse_json(R"({"name": "x"})")).errors.empty());  // no "publish": nothing to check
}

TEST_CASE("publish settings: every mistake names its JSON pointer, says what is wrong and how to fix it") {
    auto parsed = parse_publish_settings(*parse_json(R"({"publish": {
        "steam": {"account": "", "depots": {"windws": 1, "android": 2, "linux": "x"}, "branch": "Default"},
        "itch": {"game": "MyStudio/Game", "channels": {"windows": "Win Beta"}},
        "epic": {"artifacts": {"windows": 7}},
        "gog": {"productId": "abc", "languages": []},
        "stem": {}}})"));
    auto find = [&](const std::vector<ExportSettingsIssue>& list, const std::string& pointer) -> const ExportSettingsIssue* {
        for (const auto& i : list)
            if (i.pointer == pointer) return &i;
        return nullptr;
    };
    const auto* typo = find(parsed.errors, "/publish/steam/depots/windws");
    REQUIRE(typo);
    CHECK(has(typo->message, "not a platform"));
    CHECK(has(typo->hint, "Did you mean 'windows'?"));
    const auto* mobile = find(parsed.errors, "/publish/steam/depots/android");
    REQUIRE(mobile);
    CHECK(has(mobile->message, "cannot be uploaded"));
    const auto* depot = find(parsed.errors, "/publish/steam/depots/linux");
    REQUIRE(depot);
    CHECK(has(depot->message, "expected a Steam depot id"));
    REQUIRE(find(parsed.errors, "/publish/steam/account"));
    const auto* branch = find(parsed.errors, "/publish/steam/branch");
    REQUIRE(branch);
    CHECK(has(branch->message, "'default'"));
    CHECK(has(branch->hint, "beta branch"));
    const auto* game = find(parsed.errors, "/publish/itch/game");
    REQUIRE(game);
    CHECK(has(game->hint, "\"mystudio/game\""));
    REQUIRE(find(parsed.errors, "/publish/itch/channels/windows"));
    REQUIRE(find(parsed.errors, "/publish/epic/artifacts/windows"));
    REQUIRE(find(parsed.errors, "/publish/gog/productId"));
    REQUIRE(find(parsed.errors, "/publish/gog/languages"));
    const auto* store = find(parsed.warnings, "/publish/stem");
    REQUIRE(store);
    CHECK(has(store->hint, "Did you mean 'steam'?"));

    auto notObject = parse_publish_settings(*parse_json(R"({"publish": ["steam"]})"));
    REQUIRE(notObject.errors.size() == 1);
    CHECK(notObject.errors[0].pointer == "/publish");
    CHECK(has(notObject.errors[0].hint, "stores: steam, itch, epic, gog"));
}

TEST_CASE("validate: the publish section is checked once, with the settings' own messages") {
    Fixture good;
    const ValidationReport clean = validate_project(good.dir);
    CHECK_MESSAGE(clean.errors.empty(), clean.to_text());
    for (const auto& w : clean.warnings) CHECK_MESSAGE(w.pointer.rfind("/publish", 0) != 0, w.pointer << ": " << w.message);  // other warnings are not about publish

    Fixture bad(R"({"publish": {"steam": {"depots": {"windws": 1}}, "itch": {"gam": "a/b"}}})");
    const ValidationReport r = validate_project(bad.dir);
    CHECK_FALSE(r.ok);
    int onTypo = 0;
    for (const auto& e : r.errors)
        if (e.pointer == "/publish/steam/depots/windws") {
            ++onTypo;
            CHECK(has(e.hint, "windows"));
        }
    CHECK(onTypo == 1);
    int unknown = 0;
    for (const auto& w : r.warnings)
        if (w.pointer == "/publish/itch/gam") {
            ++unknown;
            CHECK(has(w.hint, "Did you mean 'game'?"));
        }
    CHECK(unknown == 1);
}

// ---- Steam -------------------------------------------------------------------------------------------------------------

TEST_CASE("publish.steam dry run: the build scripts, the exact steamcmd command line and what goes where") {
    Fixture f;
    PublishOptions o = f.options("steam");
    o.dryRun = true;
    const PublishReport r = f.ok(o);
    CHECK(r.dryRun);
    CHECK_FALSE(r.uploaded);
    CHECK(r.version == "1.2.3");
    CHECK(r.tool == kFakeTool);
    CHECK(r.toolFrom == "FACTORIA_STEAMCMD");
    CHECK_FALSE(stdfs::exists(f.record));  // nothing was started

    REQUIRE(r.steps.size() == 1);
    REQUIRE(r.files.size() == 4);  // the app script first, then one depot script per platform
    const std::string appVdf = r.files[0];
    CHECK(r.steps[0].command == std::vector<std::string>{kFakeTool, "+login", "mystudio_build", "+run_app_build", appVdf, "+quit"});
    CHECK(has(appVdf, ".factoria/publish/steam/app_build_1234560.vdf"));
    CHECK_FALSE(r.steps[0].ran);

    REQUIRE(r.uploads.size() == 3);
    CHECK(r.uploads[0].platform == "windows");
    CHECK(r.uploads[0].folder == f.export_dir("windows"));
    CHECK(r.uploads[0].destination == "Steam app 1234560, depot 1234561 (windows)");
    CHECK(r.uploads[0].files == 3);  // the exe, the notices and game/factoria.json: the export's marker and AI disclosure stay behind
    CHECK(r.uploads[0].bytes == std::string("exe").size() + std::string("licenses").size() + 2);
    CHECK(r.uploads[1].destination == "Steam app 1234560, depot 1234562 (macos)");
    CHECK(r.uploads[2].files == 1);
    for (const auto& u : r.uploads) CHECK_FALSE(u.uploaded);

    const std::string app = testing::read_all(appVdf);
    CHECK(has(app, "\"AppBuild\""));
    CHECK(has(app, "\"AppID\" \"1234560\""));
    CHECK(has(app, "\"Desc\" \"Space Dodge 1.2.3\""));
    CHECK(has(app, "\"1234561\" \"depot_build_1234561.vdf\""));
    CHECK(has(app, "\"1234563\" \"depot_build_1234563.vdf\""));
    CHECK_FALSE(has(app, "SetLive"));  // nothing goes live unless a branch is named
    const std::string depot = testing::read_all(r.files[1]);
    CHECK(has(depot, "\"DepotBuild\""));
    CHECK(has(depot, "\"DepotID\" \"1234561\""));
    CHECK(has(depot, "\"ContentRoot\" \"" + f.export_dir("windows") + "\""));
    CHECK(has(depot, "\"LocalPath\" \"*\""));
    CHECK(has(depot, "\"DepotPath\" \".\""));
    CHECK(has(depot, "\"FileExclusion\" \".factoria-export\""));
    CHECK(has(depot, "\"FileExclusion\" \"AI_CONTENT_DISCLOSURE.md\""));
    CHECK(has(testing::read_all(r.files[2]), "\"ContentRoot\" \"" + f.export_dir("macos") + "\""));

    const Json j = r.to_json();
    CHECK(j["steps"][0]["commandLine"].get<std::string>().rfind(kFakeTool, 0) == 0);
    CHECK(j["dryRun"] == true);
    CHECK_FALSE(j.contains("log"));
    CHECK(has(j["nextSteps"].dump(), "not live"));
}

TEST_CASE("publish.steam: a branch is set live, the default branch never") {
    Fixture f;
    PublishOptions o = f.options("steam");
    o.dryRun = true;
    o.branch = "beta";
    o.platforms = {"windows", "win"};  // aliases work, and a platform is listed once
    const PublishReport r = f.ok(o);
    CHECK(has(testing::read_all(r.files[0]), "\"SetLive\" \"beta\""));
    REQUIRE(r.uploads.size() == 1);
    CHECK(r.files.size() == 2);
    CHECK(has(r.to_json()["nextSteps"].dump(), "'beta' beta branch"));

    o.branch = "Default";
    const Error e = f.fails(o);
    CHECK(has(e.message, "'default' cannot be set live"));
    CHECK(has(e.hint, "beta branch"));
}

TEST_CASE("publish.steam: the app id is the one in steam_appid.txt, and mistakes teach") {
    Fixture f;
    PublishOptions o = f.options("steam");
    o.dryRun = true;

    testing::write_all(f.dir + "/steam_appid.txt", "480\n");
    Error e = f.fails(o);
    CHECK(has(e.message, "480, Valve's test app"));
    CHECK(has(e.hint, "steam_appid.txt"));
    o.appId = "999";  // the argument wins
    CHECK(has(f.ok(o).files[0], "app_build_999.vdf"));
    o.appId.clear();

    testing::write_all(f.dir + "/steam_appid.txt", "not a number");
    CHECK(has(f.fails(o).message, "is not a Steam app id"));
    stdfs::remove(f.dir + "/steam_appid.txt");
    e = f.fails(o);
    CHECK(has(e.message, "no Steam app id"));
    CHECK(has(e.hint, "platform.add_backend"));
}

TEST_CASE("publish.steam: a missing account, depot, export or platform name is a teaching error") {
    {
        Fixture f(R"({"publish": {"steam": {"depots": {"windows": 5}}}})");
        PublishOptions o = f.options("steam");
        o.dryRun = true;
        Error e = f.fails(o);
        CHECK(has(e.message, "publish/steam/account"));
        CHECK(has(e.hint, "never stored"));
        o.account = "someone";  // the argument is enough
        const PublishReport r = f.ok(o);
        CHECK(r.steps[0].command[2] == "someone");
        // exports exist for three platforms, one has a depot: the others are skipped with a warning
        REQUIRE(r.uploads.size() == 1);
        CHECK(has(r.to_json()["warnings"].dump(), "Skipped the macos export"));
        o.platforms = {"macos"};  // asking for one without a depot is an error
        e = f.fails(o);
        CHECK(has(e.message, "no depot id for macos"));
        CHECK(has(e.message, "factoria.json#/publish/steam/depots/macos"));
    }
    Fixture f;
    PublishOptions o = f.options("steam");
    o.dryRun = true;
    o.platforms = {"windws"};
    Error e = f.fails(o);
    CHECK(has(e.message, "unknown platform 'windws'"));
    CHECK(has(e.hint, "Did you mean 'windows'?"));
    o.platforms = {"android"};
    e = f.fails(o);
    CHECK(has(e.message, "'android' cannot be uploaded to steam"));
    CHECK(has(e.hint, "desktop exports"));

    o.platforms = {"linux"};
    stdfs::remove_all(f.dir + "/build/export/space-dodge-linux");
    e = f.fails(o);
    CHECK(has(e.message, "there is no export of linux"));
    CHECK(has(e.hint, "project.export {\"platform\":\"linux\"}"));
    stdfs::remove_all(f.dir + "/build");
    o.platforms.clear();
    e = f.fails(o);
    CHECK(has(e.message, "there is no export to upload"));
    CHECK(has(e.hint, "project.export"));
}

TEST_CASE("publish tools: found by environment variable, ~/.factoria/export.json or PATH; a missing one says where to get it") {
    Fixture f;
    PublishOptions o = f.options("steam");
    o.dryRun = true;

    o.env = [](const std::string&) { return std::string(); };  // no variable at all
    if (which("steamcmd").empty() && which("steamcmd.sh").empty()) {
        const Error e = f.fails(o);
        CHECK(has(e.message, "steamcmd was not found"));
        CHECK(has(e.hint, "https://developer.valvesoftware.com/wiki/SteamCMD"));
        CHECK(has(e.hint, "FACTORIA_STEAMCMD"));
        CHECK(has(e.hint, f.config));
        CHECK(has(e.hint, "Nothing is downloaded"));
    }
    // ~/.factoria/export.json: "publish": {"steamcmd": ...}, a file or the folder that holds it
    testing::write_all(f.config, "{\"format\": \"factoria.export-config/1\", \"publish\": {\"steamcmd\": \"" + kFakeTool + "\"}}");
    PublishReport r = f.ok(o);
    CHECK(r.tool == kFakeTool);
    CHECK(r.toolFrom == "export.json");
    testing::write_all(f.config, "{\"publish\": {\"steamcmd\": \"" + stdfs::path(f.tmp.sub("nothing-here")).generic_string() + "\"}}");
    Error e = f.fails(o);
    CHECK(has(e.message, "#/publish/steamcmd"));
    CHECK(has(e.message, "which is not steamcmd"));
    testing::write_all(f.config, "{ not json");
    CHECK(has(f.fails(o).message, "publish.steam:"));
    stdfs::remove(f.config);

    // a variable naming a folder: the tool is looked for inside
    const std::string folder = f.tmp.sub("tools");
#ifdef _WIN32
    testing::write_all(folder + "/steamcmd.exe", "x");
#else
    testing::write_all(folder + "/steamcmd", "x");
#endif
    f.vars = {{"FACTORIA_STEAMCMD", folder}};
    o = f.options("steam");
    o.dryRun = true;
    r = f.ok(o);
    CHECK(has(r.tool, "/tools/steamcmd"));
    f.vars = {{"FACTORIA_STEAMCMD", f.tmp.sub("missing")}};
    o = f.options("steam");
    o.dryRun = true;
    e = f.fails(o);
    CHECK(has(e.message, "FACTORIA_STEAMCMD is"));
    CHECK(has(e.message, "which is not steamcmd"));
}

TEST_CASE("publish.steam: a real run starts steamcmd, reports its progress and records the result") {
    Fixture f;
    ScopedEnv record("FA_FAKE_TOOL_RECORD", f.record);
    PublishOptions o = f.options("steam");
    std::vector<std::string> progress;
    o.progress = [&](const std::string& line) { progress.push_back(line); };
    o.branch = "beta";
    const PublishReport r = f.ok(o);
    CHECK_FALSE(r.failed);
    CHECK(r.uploaded);
    CHECK(r.exitCode == 0);
    REQUIRE(r.steps.size() == 1);
    CHECK(r.steps[0].ran);
    CHECK(r.steps[0].exitCode == 0);
    for (const auto& u : r.uploads) CHECK(u.uploaded);

    const auto calls = read_calls(f.record);
    REQUIRE(calls.size() == 1);
    CHECK(calls[0].args == std::vector<std::string>{"+login", "mystudio_build", "+run_app_build", r.files[0], "+quit"});

    bool sawStdout = false, sawStderr = false, sawCommand = false;
    for (const std::string& line : progress) {
        sawStdout = sawStdout || has(line, "fake store tool: call 1 with 5 argument(s)");
        sawStderr = sawStderr || has(line, "a line on stderr");
        sawCommand = sawCommand || has(line, "+run_app_build");
    }
    CHECK(sawStdout);
    CHECK(sawStderr);
    CHECK(sawCommand);
    CHECK(has(r.log, "/.factoria/publish/steam.log"));
    const std::string log = testing::read_all(r.log);
    CHECK(has(log, "fake store tool: call 1"));
    CHECK(has(log, "== exit code 0"));
    CHECK(r.to_json()["log"] == r.log);
    CHECK(r.to_json()["exitCode"] == 0);
}

TEST_CASE("publish.steam: a failing steamcmd is a report with the exit code, the log and what to check") {
    Fixture f;
    ScopedEnv record("FA_FAKE_TOOL_RECORD", f.record);
    ScopedEnv exitCode("FA_FAKE_TOOL_EXIT", "5");
    const PublishReport r = f.ok(f.options("steam"));  // not an Error: the report says what happened
    CHECK(r.failed);
    CHECK_FALSE(r.uploaded);
    CHECK(r.exitCode == 5);
    CHECK(has(r.failure, "exited with code 5"));
    CHECK(has(r.failure, r.log));
    CHECK(has(r.failure, "fake store tool: call 1"));
    CHECK(has(r.failureHint, "Steam Guard"));
    for (const auto& u : r.uploads) CHECK_FALSE(u.uploaded);
    CHECK(r.to_json()["failure"] == r.failure);

    // through the command: an error whose data is the report
    ScopedEnv tool("FACTORIA_STEAMCMD", kFakeTool);
    ScopedEnv cfg("FACTORIA_EXPORT_CONFIG", f.config);
    CommandRegistry reg;
    register_publish_commands(reg, f.dir);
    const CommandResult c = reg.call("publish.steam", Json::object());
    CHECK_FALSE(c.ok);
    CHECK(c.error["code"] == "failed");
    CHECK(has(c.error["message"].get<std::string>(), "exited with code 5"));
    CHECK(has(c.error["hint"].get<std::string>(), "Steam Guard"));
    CHECK(c.error["data"]["exitCode"] == 5);
    CHECK(c.error["data"]["store"] == "steam");
}

TEST_CASE("publish.steam: an uploader that cannot be started is a failure that says so") {
    Fixture f;
    const std::string notATool = f.tmp.sub("steamcmd-not-runnable.exe");
    testing::write_all(notATool, "this is text, not a program");
    f.vars["FACTORIA_STEAMCMD"] = notATool;
    const PublishReport r = f.ok(f.options("steam"));
    CHECK(r.failed);
    CHECK_FALSE(r.uploaded);
    CHECK(has(r.failure, "cannot start steamcmd"));
}

// ---- itch.io -----------------------------------------------------------------------------------------------------------

TEST_CASE("publish.itch dry run: one butler push per platform, with its channel and the game's version") {
    Fixture f;
    PublishOptions o = f.options("itch");
    o.dryRun = true;
    const PublishReport r = f.ok(o);
    REQUIRE(r.steps.size() == 3);
    const std::vector<std::string> ignore = {"--ignore", ".factoria-export", "--ignore", "AI_CONTENT_DISCLOSURE.md"};
    auto expected = [&](const std::string& platform, const std::string& channel) {
        std::vector<std::string> argv = {kFakeTool, "push", f.export_dir(platform), "mystudio/space-dodge:" + channel, "--userversion", "1.2.3"};
        argv.insert(argv.end(), ignore.begin(), ignore.end());
        return argv;
    };
    CHECK(r.steps[0].command == expected("windows", "windows"));
    CHECK(r.steps[1].command == expected("macos", "mac"));
    CHECK(r.steps[2].command == expected("linux", "linux"));
    CHECK(r.uploads[1].destination == "itch.io mystudio/space-dodge:mac (version 1.2.3)");
    CHECK(r.files.empty());  // butler needs no build files
    // no key and no butler login on this (empty) environment: a warning, not an error
    CHECK(has(r.to_json()["warnings"].dump(), "BUTLER_API_KEY"));
}

TEST_CASE("publish.itch: channels come from factoria.json, a missing game says how to set it") {
    {
        Fixture f(R"({"publish": {"itch": {"game": "me/g", "channels": {"windows": "windows-beta"}}}})");
        f.vars["BUTLER_API_KEY"] = "key";
        PublishOptions o = f.options("itch");
        o.dryRun = true;
        o.platforms = {"windows", "macos"};
        const PublishReport r = f.ok(o);
        CHECK(r.steps[0].command[3] == "me/g:windows-beta");
        CHECK(r.steps[1].command[3] == "me/g:mac");
        CHECK(r.to_json()["warnings"].empty());  // the key is set
    }
    Fixture f("{}");
    PublishOptions o = f.options("itch");
    o.dryRun = true;
    const Error e = f.fails(o);
    CHECK(has(e.message, "publish/itch/game is not set"));
    CHECK(has(e.hint, "mystudio.itch.io/space-dodge"));
}

TEST_CASE("publish.itch: a run stops at the first failing push and says which platforms were uploaded; the API key is never shown") {
    Fixture f;
    f.vars["BUTLER_API_KEY"] = "butler-key-1234";
    ScopedEnv record("FA_FAKE_TOOL_RECORD", f.record);
    ScopedEnv failSecond("FA_FAKE_TOOL_FAIL_CALL", "2");
    ScopedEnv echo("FA_FAKE_TOOL_ECHO", "BUTLER_API_KEY");  // the fake prints the key, as a chatty tool could
    ScopedEnv key("BUTLER_API_KEY", "butler-key-1234");
    std::string everythingShown;
    PublishOptions o = f.options("itch");
    o.progress = [&](const std::string& line) { everythingShown += line + "\n"; };
    const PublishReport r = f.ok(o);
    CHECK(r.failed);
    CHECK(r.exitCode == 7);
    REQUIRE(r.uploads.size() == 3);
    CHECK(r.uploads[0].uploaded);
    CHECK_FALSE(r.uploads[1].uploaded);
    CHECK_FALSE(r.uploads[2].uploaded);
    CHECK(r.steps[1].ran);
    CHECK_FALSE(r.steps[2].ran);  // never started
    CHECK(read_calls(f.record).size() == 2);
    CHECK(has(r.failure, "exited with code 7"));
    CHECK(has(r.failureHint, "butler login"));

    const std::string log = testing::read_all(r.log);
    for (const std::string& shown : {log, everythingShown, r.to_json().dump(), r.failure}) CHECK_FALSE(has(shown, "butler-key-1234"));
    CHECK(has(log, "echo BUTLER_API_KEY=<redacted>"));
}

// ---- Epic Games Store -------------------------------------------------------------------------------------------------

TEST_CASE("publish.epic dry run: BuildPatchTool UploadBinary per platform, the secret by variable name only") {
    Fixture f;
    f.vars["FACTORIA_EPIC_CLIENT_SECRET"] = "epic-secret-5678";
    PublishOptions o = f.options("epic");
    o.dryRun = true;
    const PublishReport r = f.ok(o);
    REQUIRE(r.steps.size() == 3);
    REQUIRE(r.files.size() == 3);  // the ignore list, once per run
    const std::string work = stdfs::path(r.files[0]).parent_path().generic_string();
    CHECK(has(work, "/.factoria/publish/epic"));
    CHECK(r.steps[0].command == std::vector<std::string>{kFakeTool,
                                                         "-OrganizationId=o-abc",
                                                         "-ProductId=prod1",
                                                         "-ArtifactId=art-win",
                                                         "-ClientId=xyzclient",
                                                         "-ClientSecretEnvVar=FACTORIA_EPIC_CLIENT_SECRET",
                                                         "-mode=UploadBinary",
                                                         "-BuildRoot=" + f.export_dir("windows"),
                                                         "-CloudDir=" + work + "/cloud/windows",
                                                         "-BuildVersion=1.2.3",
                                                         "-AppLaunch=space-dodge.exe",
                                                         "-AppArgs=",
                                                         "-FileIgnoreList=" + work + "/ignore.txt"});
    CHECK(has(r.steps[1].command[3], "art-mac"));
    CHECK(r.steps[1].command[10] == "-AppLaunch=Space Dodge.app/Contents/MacOS/space-dodge");
    CHECK(r.steps[2].command[10] == "-AppLaunch=space-dodge");
    CHECK(testing::read_all(r.files[0]) == ".factoria-export\nAI_CONTENT_DISCLOSURE.md\n");
    CHECK(stdfs::is_directory(work + "/cloud/windows"));
    CHECK_FALSE(has(r.to_json().dump(), "epic-secret-5678"));
    CHECK(r.uploads[0].destination == "Epic artifact art-win (build 1.2.3)");
}

TEST_CASE("publish.epic: a game named \"Game\" is launched through game-bin on Linux, the name the export gives its executable") {
    Fixture f;
    f.vars["FACTORIA_EPIC_CLIENT_SECRET"] = "epic-secret-5678";
    auto j = load_json_file(f.dir + "/factoria.json");
    REQUIRE(j.ok());
    (*j)["name"] = "Game";
    REQUIRE(save_json_file(f.dir + "/factoria.json", *j).ok());
    testing::write_all(f.dir + "/build/export/game-linux/.factoria-export", "written by an export");
    testing::write_all(f.dir + "/build/export/game-linux/game-bin", "elf");
    testing::write_all(f.dir + "/build/export/game-linux/game/factoria.json", "{}");
    PublishOptions o = f.options("epic");
    o.dryRun = true;
    o.platforms = {"linux"};
    const PublishReport r = f.ok(o);
    REQUIRE(r.steps.size() == 1);
    CHECK(r.steps[0].command[10] == "-AppLaunch=game-bin");

    stdfs::remove(f.dir + "/build/export/game-linux/game-bin");  // game/ is not the executable
    const Error e = f.fails(o);
    CHECK(has(e.message, "has no game-bin, the game's executable"));
}

TEST_CASE("publish.epic: missing ids, secret, artifacts, or an invalid version are teaching errors") {
    {
        Fixture f("{}");
        PublishOptions o = f.options("epic");
        o.dryRun = true;
        const Error e = f.fails(o);
        CHECK(has(e.message, "publish/epic has no organizationId, productId, clientId"));
        CHECK(has(e.hint, "Build Patch Tool"));
    }
    Fixture f;
    PublishOptions o = f.options("epic");
    o.dryRun = true;
    Error e = f.fails(o);
    CHECK(has(e.message, "FACTORIA_EPIC_CLIENT_SECRET is empty"));
    CHECK(has(e.hint, "-ClientSecretEnvVar"));
    f.vars["FACTORIA_EPIC_CLIENT_SECRET"] = "s";
    o = f.options("epic");
    o.dryRun = true;
    o.platforms = {"windows"};
    f.ok(o);

    auto j = load_json_file(f.dir + "/factoria.json");
    (*j)["version"] = "1.0 beta";
    REQUIRE(save_json_file(f.dir + "/factoria.json", *j).ok());
    e = f.fails(o);
    CHECK(has(e.message, "'1.0 beta' of factoria.json cannot be an Epic BuildVersion"));
    CHECK(has(e.hint, "no spaces"));
    (*j)["version"] = "1.2.3";
    (*j)["publish"]["epic"]["artifacts"].erase("macos");
    REQUIRE(save_json_file(f.dir + "/factoria.json", *j).ok());
    o.platforms = {"macos"};
    e = f.fails(o);
    CHECK(has(e.message, "no artifact id for macos"));
    CHECK(has(e.message, "publish/epic/artifacts/macos"));

    // the game's executable is part of what Epic is told: an export without it is refused
    o.platforms = {"windows"};
    stdfs::remove(f.dir + "/build/export/space-dodge-windows/space-dodge.exe");
    e = f.fails(o);
    CHECK(has(e.message, "has no space-dodge.exe, the game's executable"));
}

TEST_CASE("publish.epic: a real run passes the secret to the tool in its environment, and scrubs it from everything shown") {
    Fixture f;
    f.vars["FACTORIA_EPIC_CLIENT_SECRET"] = "epic-secret-5678";
    ScopedEnv record("FA_FAKE_TOOL_RECORD", f.record);
    ScopedEnv names("FA_FAKE_TOOL_ENV", "FACTORIA_EPIC_CLIENT_SECRET");
    ScopedEnv echo("FA_FAKE_TOOL_ECHO", "FACTORIA_EPIC_CLIENT_SECRET");
    PublishOptions o = f.options("epic");
    o.platforms = {"windows"};
    std::string progress;
    o.progress = [&](const std::string& line) { progress += line + "\n"; };
    const PublishReport r = f.ok(o);
    CHECK(r.uploaded);
    const auto calls = read_calls(f.record);
    REQUIRE(calls.size() == 1);
    CHECK(calls[0].env.at("FACTORIA_EPIC_CLIENT_SECRET") == "epic-secret-5678");  // the tool gets it
    for (const std::string& arg : calls[0].args) CHECK_FALSE(has(arg, "epic-secret-5678"));  // but never on its command line
    for (const std::string& shown : {testing::read_all(r.log), progress, r.to_json().dump()}) CHECK_FALSE(has(shown, "epic-secret-5678"));
    CHECK(has(progress, "FACTORIA_EPIC_CLIENT_SECRET=<redacted>"));
}

// ---- GOG ---------------------------------------------------------------------------------------------------------------

TEST_CASE("publish.gog dry run: one Pipeline Builder project file per platform and the build-game command line") {
    Fixture f;
    PublishOptions o = f.options("gog");
    o.dryRun = true;
    o.branch = "testing";
    const PublishReport r = f.ok(o);
    REQUIRE(r.steps.size() == 3);
    REQUIRE(r.files.size() == 6);  // the project file and the ignore list of each run
    CHECK(has(r.files[0], "/.factoria/publish/gog/gog-windows.json"));
    CHECK(r.steps[0].command == std::vector<std::string>{kFakeTool, "build-game", r.files[0], "--ignore_list", r.files[1], "--version", "1.2.3", "--branch", "testing"});
    CHECK(r.steps[1].command[2] == r.files[2]);
    CHECK(testing::read_all(r.files[1]) == ".factoria-export\nAI_CONTENT_DISCLOSURE.md\n");
    CHECK(has(r.to_json()["warnings"].dump(), "cached from an earlier sign-in"));  // no credentials in this environment

    auto windows = parse_json(testing::read_all(r.files[0]));
    REQUIRE(windows.ok());
    const Json& project = (*windows)["project"];
    CHECK(project["platform"] == "windows");
    CHECK(project["baseProductId"] == "1207658930");
    CHECK(project["clientId"] == "5555");
    CHECK(project["clientSecret"] == "");  // never written
    CHECK(project["name"] == "Space Dodge");
    CHECK(project["installDirectory"] == "Space Dodge");
    const Json& product = project["products"][0];
    CHECK(product["productId"] == "1207658930");
    CHECK(product["depots"][0]["folder"] == f.export_dir("windows"));
    CHECK(product["depots"][0]["languages"] == Json::array({"en-US", "fr-FR"}));
    CHECK(product["depots"][0]["name"] == "space-dodge-1.2.3-windows");
    CHECK(product["tasks"][0]["type"] == "FileTask");
    CHECK(product["tasks"][0]["isPrimary"] == true);
    CHECK(product["tasks"][0]["path"] == "space-dodge.exe");
    CHECK(product["tasks"][0]["osBitness"] == Json::array({"64"}));

    auto mac = parse_json(testing::read_all(r.files[2]));
    REQUIRE(mac.ok());
    CHECK((*mac)["project"]["platform"] == "osx");
    CHECK((*mac)["project"]["products"][0]["tasks"][0]["path"] == "Space Dodge.app");
    CHECK_FALSE((*mac)["project"]["products"][0]["tasks"][0].contains("osBitness"));
}

TEST_CASE("publish.gog: the password is redacted wherever FactorIA shows anything, the tool still gets it") {
    Fixture f;
    f.vars["FACTORIA_GOG_USERNAME"] = "maker";
    f.vars["FACTORIA_GOG_PASSWORD"] = "hunter2-secret";
    PublishOptions o = f.options("gog");
    o.dryRun = true;
    o.platforms = {"linux"};
    PublishReport dry = f.ok(o);
    const std::vector<std::string>& shown = dry.steps[0].command;
    CHECK(std::vector<std::string>(shown.end() - 4, shown.end()) == std::vector<std::string>{"--username", "maker", "--password", "<redacted>"});
    CHECK_FALSE(has(dry.to_json().dump(), "hunter2-secret"));
    CHECK(dry.to_json()["warnings"].empty());

    ScopedEnv record("FA_FAKE_TOOL_RECORD", f.record);
    ScopedEnv print("FA_FAKE_TOOL_PRINT_ARGS", "1");
    o.dryRun = false;
    std::string progress;
    o.progress = [&](const std::string& line) { progress += line + "\n"; };
    const PublishReport r = f.ok(o);
    CHECK(r.uploaded);
    const auto calls = read_calls(f.record);
    REQUIRE(calls.size() == 1);
    CHECK(calls[0].args.back() == "hunter2-secret");  // the real password reached the tool
    CHECK(calls[0].args[calls[0].args.size() - 2] == "--password");
    for (const std::string& text : {testing::read_all(r.log), progress, r.to_json().dump()}) CHECK_FALSE(has(text, "hunter2-secret"));
    CHECK(has(progress, "argument 10: <redacted>"));
}

TEST_CASE("publish.gog: half a login, the master branch and a missing product id are teaching errors") {
    {
        Fixture f("{}");
        PublishOptions o = f.options("gog");
        o.dryRun = true;
        const Error e = f.fails(o);
        CHECK(has(e.message, "publish/gog/productId is not set"));
        CHECK(has(e.hint, "Developer Portal"));
    }
    Fixture f;
    f.vars["FACTORIA_GOG_USERNAME"] = "maker";
    PublishOptions o = f.options("gog");
    o.dryRun = true;
    Error e = f.fails(o);
    CHECK(has(e.message, "FACTORIA_GOG_USERNAME is set but FACTORIA_GOG_PASSWORD is not"));
    f.vars.erase("FACTORIA_GOG_USERNAME");
    o = f.options("gog");
    o.dryRun = true;
    o.branch = "Master";
    e = f.fails(o);
    CHECK(has(e.message, "cannot publish to the Master branch"));
}

// ---- App Store Connect and Google Play --------------------------------------------------------------------------------

const char* const kMobilePublish = R"({"id": "com.mystudio.spacedodge",
    "export": {"ios": {"buildNumber": "42"}, "android": {"signing": {"keystore": "upload.jks", "alias": "upload"}}},
    "publish": {"appstore": {"appleId": 6448277777},
                "googleplay": {"changelogs": {"en-US": "store/whats-new-en.txt", "es-419": "store/whats-new-es.txt"}}}})";

// The fixture plus what the mobile stores need: the .ipa archived in Xcode, the release .aab, the App Store Connect API key
// (a .p8 file) and the Play service account key. The key files hold a marker that must never be shown anywhere.
struct MobileFixture : Fixture {
    std::string keys = tmp.sub("keys");
    std::string p8 = stdfs::path(keys + "/AuthKey_ABCDE12345.p8").generic_string();
    std::string serviceAccount = stdfs::path(keys + "/play.json").generic_string();
    std::string ipa = stdfs::weakly_canonical(dir + "/build/export/space-dodge.ipa").generic_string();
    std::string aab = stdfs::weakly_canonical(dir + "/build/export/space-dodge-android/space-dodge.aab").generic_string();

    MobileFixture() : Fixture(kMobilePublish) {
        testing::write_all(ipa, "PK\x03\x04 ipa");
        testing::write_all(aab, "PK\x03\x04 aab");
        testing::write_all(p8, "-----BEGIN PRIVATE KEY-----\nAPPSTORE-KEY-BODY\n-----END PRIVATE KEY-----\n");
        testing::write_all(serviceAccount, R"({"type": "service_account", "client_email": "up@proj.iam.gserviceaccount.com", "private_key": "PLAY-KEY-BODY"})");
        testing::write_all(dir + "/store/whats-new-en.txt", "Faster levels.\nNew boss.\n");
        testing::write_all(dir + "/store/whats-new-es.txt", "Niveles mas rapidos.");
        vars["FACTORIA_APPSTORE_API_KEY"] = p8;
        vars["FACTORIA_APPSTORE_API_KEY_ID"] = "ABCDE12345";
        vars["FACTORIA_APPSTORE_API_ISSUER"] = "11111111-2222-3333-4444-555555555555";
        vars["FACTORIA_GOOGLEPLAY_JSON_KEY"] = serviceAccount;
    }

    PublishOptions store(const std::string& name, bool dryRun = true) const {
        PublishOptions o = options(name);
        o.dryRun = dryRun;
        o.host = "macos";
        return o;
    }
    // Changes factoria.json (the keystore setting, the changelogs...).
    template <class F>
    void edit(F change) const {
        auto j = load_json_file(dir + "/factoria.json");
        REQUIRE(j.ok());
        change(*j);
        REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
    }
};

bool leaks_keys(const std::string& text) { return has(text, "APPSTORE-KEY-BODY") || has(text, "PLAY-KEY-BODY") || has(text, "BEGIN PRIVATE KEY"); }

TEST_CASE("publish settings: appstore and googleplay are read, and every mistake teaches") {
    auto parsed = parse_publish_settings(*parse_json(kMobilePublish));
    CHECK(parsed.errors.empty());
    CHECK(parsed.warnings.empty());
    CHECK(parsed.settings.appstore.appleId == "6448277777");  // a number, kept whole (it does not fit 32 bits)
    CHECK(parsed.settings.googleplay.track == "internal");    // the defaults
    CHECK(parsed.settings.googleplay.releaseStatus == "draft");
    CHECK(parsed.settings.googleplay.changelogs.at("es-419") == "store/whats-new-es.txt");

    parsed = parse_publish_settings(*parse_json(R"({"publish": {
        "appstore": {"appleId": "me@example.com", "teamId": "X"},
        "googleplay": {"track": "my track", "releaseStatus": "complete", "changelogs": {"english": "a.txt", "en-US": 5}}}})"));
    auto find = [&](const std::string& pointer) -> const ExportSettingsIssue* {
        for (const auto& i : parsed.errors)
            if (i.pointer == pointer) return &i;
        return nullptr;
    };
    const auto* apple = find("/publish/appstore/appleId");
    REQUIRE(apple);
    CHECK(has(apple->hint, "General Information"));
    REQUIRE(find("/publish/googleplay/track"));
    const auto* status = find("/publish/googleplay/releaseStatus");
    REQUIRE(status);
    CHECK(has(status->hint, "Did you mean 'completed'?"));
    const auto* locale = find("/publish/googleplay/changelogs/english");
    REQUIRE(locale);
    CHECK(has(locale->hint, "en-US"));
    REQUIRE(find("/publish/googleplay/changelogs/en-US"));
    REQUIRE(parsed.warnings.size() == 1);
    CHECK(parsed.warnings[0].pointer == "/publish/appstore/teamId");
}

TEST_CASE("publish.appstore dry run: the exact altool command line, what is uploaded where, and no secret anywhere") {
    MobileFixture f;
    const PublishReport r = f.ok(f.store("appstore"));
    CHECK(r.dryRun);
    CHECK_FALSE(r.uploaded);
    REQUIRE(r.steps.size() == 1);
    CHECK(r.steps[0].command == std::vector<std::string>{kFakeTool, "altool", "--upload-package", f.ipa, "--type", "ios", "--apple-id", "6448277777", "--bundle-id", "com.mystudio.spacedodge",
                                                         "--bundle-version", "42", "--bundle-short-version-string", "1.2.3", "--apiKey", "ABCDE12345", "--apiIssuer",
                                                         "11111111-2222-3333-4444-555555555555"});
    REQUIRE(r.uploads.size() == 1);
    CHECK(r.uploads[0].platform == "ios");
    CHECK(r.uploads[0].folder == f.ipa);
    CHECK(r.uploads[0].files == 1);
    CHECK(r.uploads[0].bytes > 0);
    CHECK(has(r.uploads[0].destination, "App Store Connect app 6448277777 (com.mystudio.spacedodge), version 1.2.3 build 42"));
    CHECK(has(r.to_json()["nextSteps"].dump(), "TestFlight"));
    CHECK(has(r.to_json()["warnings"].dump(), "read from factoria.json"));
    CHECK_FALSE(leaks_keys(r.to_json().dump()));
    CHECK(f.export_dir("windows").size() > 0);  // desktop exports exist and are not what appstore uploads
}

TEST_CASE("publish.appstore: the notarization variables of sign.macos also work, and the newest .ipa of the export folder is used") {
    MobileFixture f;
    for (const char* v : {"FACTORIA_APPSTORE_API_KEY", "FACTORIA_APPSTORE_API_KEY_ID", "FACTORIA_APPSTORE_API_ISSUER"}) f.vars.erase(v);
    f.vars["FACTORIA_NOTARY_API_KEY"] = f.p8;
    f.vars["FACTORIA_NOTARY_API_KEY_ID"] = "ABCDE12345";
    f.vars["FACTORIA_NOTARY_API_ISSUER"] = "issuer-uuid";
    stdfs::rename(f.ipa, f.dir + "/build/export/factoria_player.ipa");  // what Xcode names it
    const PublishReport r = f.ok(f.store("appstore"));
    CHECK(has(r.uploads[0].folder, "/build/export/factoria_player.ipa"));
    CHECK(r.steps[0].command.back() == "issuer-uuid");
}

TEST_CASE("publish.appstore: a real run starts altool with the key folder in its environment, and shows no secret") {
    MobileFixture f;
    ScopedEnv record("FA_FAKE_TOOL_RECORD", f.record);
    ScopedEnv names("FA_FAKE_TOOL_ENV", "API_PRIVATE_KEYS_DIR");
    ScopedEnv print("FA_FAKE_TOOL_PRINT_ARGS", "1");
    PublishOptions o = f.store("appstore", false);
    std::string progress;
    o.progress = [&](const std::string& line) { progress += line + "\n"; };
    const PublishReport r = f.ok(o);
    CHECK(r.uploaded);
    CHECK(r.uploads[0].uploaded);
    CHECK(r.exitCode == 0);
    const auto calls = read_calls(f.record);
    REQUIRE(calls.size() == 1);
    CHECK(calls[0].args[0] == "altool");
    CHECK(calls[0].args[2] == f.ipa);
    CHECK(calls[0].env.at("API_PRIVATE_KEYS_DIR") == stdfs::path(f.keys).generic_string());
    for (const std::string& text : {testing::read_all(r.log), progress, r.to_json().dump()}) CHECK_FALSE(leaks_keys(text));
}

TEST_CASE("publish.appstore: a failing altool is a report with the reason to check") {
    MobileFixture f;
    ScopedEnv exitCode("FA_FAKE_TOOL_EXIT", "1");
    const PublishReport r = f.ok(f.store("appstore", false));
    CHECK(r.failed);
    CHECK_FALSE(r.uploaded);
    CHECK_FALSE(r.uploads[0].uploaded);
    CHECK(has(r.failure, "failed"));
    CHECK(has(r.failureHint, "Unable to authenticate"));
}

TEST_CASE("publish.appstore: missing settings, key, .ipa or Mac are teaching errors") {
    {
        MobileFixture f;
        f.edit([](Json& j) { j["publish"].erase("appstore"); });
        const Error e = f.fails(f.store("appstore"));
        CHECK(has(e.message, "publish.appstore: factoria.json#/publish/appstore/appleId is not set"));
        CHECK(has(e.hint, "General Information"));
    }
    {
        MobileFixture f;
        f.edit([](Json& j) { j.erase("id"); });
        CHECK(has(f.fails(f.store("appstore")).message, "factoria.json#/id is not set"));
    }
    {
        MobileFixture f;
        f.edit([](Json& j) { j["version"] = "1.0-beta"; });
        const Error e = f.fails(f.store("appstore"));
        CHECK(has(e.message, "cannot be an iOS version"));
        CHECK(has(e.hint, "1.2.3"));
    }
    {
        MobileFixture f;
        f.vars.erase("FACTORIA_APPSTORE_API_KEY_ID");
        f.vars.erase("FACTORIA_APPSTORE_API_ISSUER");
        const Error e = f.fails(f.store("appstore"));
        CHECK(has(e.message, "FACTORIA_APPSTORE_API_KEY_ID (the Key ID), FACTORIA_APPSTORE_API_ISSUER (the Issuer ID)"));
        CHECK_FALSE(has(e.message, "FACTORIA_APPSTORE_API_KEY (the path"));
        CHECK(has(e.hint, "App Manager"));
    }
    {
        MobileFixture f;
        f.vars["FACTORIA_APPSTORE_API_KEY"] = f.keys + "/nope.p8";
        CHECK(has(f.fails(f.store("appstore")).message, "which is not a file"));
        testing::write_all(f.keys + "/mykey.p8", "x");
        f.vars["FACTORIA_APPSTORE_API_KEY"] = f.keys + "/mykey.p8";
        const Error e = f.fails(f.store("appstore"));
        CHECK(has(e.message, "named 'mykey.p8'"));
        CHECK(has(e.message, "AuthKey_ABCDE12345.p8"));
    }
    {
        MobileFixture f;
        stdfs::remove(f.ipa);
        Error e = f.fails(f.store("appstore"));
        CHECK(has(e.message, "there is no .ipa to upload"));
        CHECK(has(e.hint, "Product > Archive"));
        CHECK(has(e.hint, "space-dodge.ipa"));
        PublishOptions o = f.store("appstore");
        o.artifact = f.dir + "/MyGame.xcarchive";
        stdfs::create_directories(o.artifact);
        e = f.fails(o);
        CHECK(has(e.message, "is an Xcode archive, not an .ipa"));
        o.artifact = f.dir + "/store/whats-new-en.txt";
        CHECK(has(f.fails(o).message, "is not an .ipa"));
        testing::write_all(f.dir + "/fake.ipa", "not a zip");
        o.artifact = f.dir + "/fake.ipa";
        CHECK(has(f.fails(o).message, "not a zip file"));
        o.platforms = {"windows"};
        CHECK(has(f.fails(o).message, "`platforms` and `folders` do not apply"));
    }
    {
        MobileFixture f;  // xcrun and altool exist only on macOS: a real run elsewhere is refused, a dry run still shows the plan
        PublishOptions o = f.store("appstore", false);
        o.host = "windows";
        const Error e = f.fails(o);
        CHECK(has(e.message, "this computer is not a Mac (windows)"));
        CHECK(has(e.hint, "dryRun"));
        o.dryRun = true;
        CHECK(f.ok(o).steps.size() == 1);
    }
}

TEST_CASE("publish.appstore: a missing xcrun says how to get Xcode") {
    MobileFixture f;
    PublishOptions o = f.store("appstore");
    o.env = [](const std::string&) { return std::string(); };
    if (which("xcrun").empty()) {
        const Error e = f.fails(o);
        CHECK(has(e.message, "xcrun was not found"));
        CHECK(has(e.hint, "xcode-select --install"));
        CHECK(has(e.hint, "FACTORIA_XCRUN"));
    }
}

TEST_CASE("publish.googleplay dry run: the exact fastlane supply command line, the release notes files and no secret anywhere") {
    MobileFixture f;
    const PublishReport r = f.ok(f.store("googleplay"));
    CHECK(r.dryRun);
    REQUIRE(r.steps.size() == 1);
    const std::string metadata = stdfs::weakly_canonical(f.dir).generic_string() + "/.factoria/publish/googleplay/metadata";
    CHECK(r.steps[0].command == std::vector<std::string>{kFakeTool, "supply", "--aab", f.aab, "--track", "internal", "--release_status", "draft", "--package_name",
                                                         "com.mystudio.spacedodge", "--json_key", f.serviceAccount, "--skip_upload_apk", "true", "--skip_upload_metadata",
                                                         "true", "--skip_upload_images", "true", "--skip_upload_screenshots", "true", "--metadata_path", metadata});
    REQUIRE(r.files.size() == 2);
    CHECK(r.files[0] == metadata + "/en-US/changelogs/default.txt");
    CHECK(testing::read_all(r.files[0]) == "Faster levels.\nNew boss.");
    CHECK(testing::read_all(r.files[1]) == "Niveles mas rapidos.");
    CHECK(r.uploads[0].platform == "android");
    CHECK(r.uploads[0].folder == f.aab);
    CHECK(has(r.uploads[0].destination, "Google Play com.mystudio.spacedodge, track internal (draft, version code 10203)"));
    CHECK(has(r.to_json()["nextSteps"].dump(), "The release is a draft"));
    CHECK_FALSE(leaks_keys(r.to_json().dump()));

    // a language taken out of factoria.json does not stay in the metadata folder
    f.edit([](Json& j) { j["publish"]["googleplay"]["changelogs"].erase("es-419"); });
    const PublishReport again = f.ok(f.store("googleplay"));
    CHECK(again.files.size() == 1);
    CHECK_FALSE(stdfs::exists(metadata + "/es-419"));
}

TEST_CASE("publish.googleplay: track and status come from the arguments or factoria.json; without release notes none are uploaded") {
    MobileFixture f;
    f.edit([](Json& j) {
        j["publish"]["googleplay"] = Json::object({{"track", "beta"}, {"releaseStatus", "completed"}});
    });
    PublishReport r = f.ok(f.store("googleplay"));
    const std::vector<std::string>& c = r.steps[0].command;
    CHECK(std::find(c.begin(), c.end(), "beta") != c.end());
    CHECK(std::find(c.begin(), c.end(), "completed") != c.end());
    CHECK(std::find(c.begin(), c.end(), "--skip_upload_changelogs") != c.end());
    CHECK(std::find(c.begin(), c.end(), "--metadata_path") == c.end());
    CHECK(r.files.empty());
    CHECK(has(r.uploads[0].destination, "track beta (completed"));
    CHECK(has(r.to_json()["nextSteps"].dump(), "rolling out on the 'beta' track"));

    PublishOptions o = f.store("googleplay");
    o.track = "production";
    r = f.ok(o);
    CHECK(has(r.to_json()["warnings"].dump(), "production track and rolls it out to everyone"));
    o.releaseStatus = "draft";
    CHECK(f.ok(o).warnings.empty());
    o.track = "my closed test";
    CHECK(has(f.fails(o).message, "is not a track name"));
    o.track = "internal";
    o.releaseStatus = "complete";
    const Error e = f.fails(o);
    CHECK(has(e.message, "'complete' is not a release status"));
    CHECK(has(e.hint, "Did you mean 'completed'?"));
}

TEST_CASE("publish.googleplay: a real run starts fastlane once and shows no secret") {
    MobileFixture f;
    ScopedEnv record("FA_FAKE_TOOL_RECORD", f.record);
    PublishOptions o = f.store("googleplay", false);
    std::string progress;
    o.progress = [&](const std::string& line) { progress += line + "\n"; };
    const PublishReport r = f.ok(o);
    CHECK(r.uploaded);
    CHECK(r.uploads[0].uploaded);
    const auto calls = read_calls(f.record);
    REQUIRE(calls.size() == 1);
    CHECK(calls[0].args[0] == "supply");
    CHECK(calls[0].args[2] == f.aab);
    for (const std::string& text : {testing::read_all(r.log), progress, r.to_json().dump()}) CHECK_FALSE(leaks_keys(text));
}

TEST_CASE("publish.googleplay: a debug-signed bundle is refused, a missing key, bundle or release note is a teaching error") {
    {
        MobileFixture f;  // the debug export is named <slug>-debug.aab
        stdfs::rename(f.aab, f.dir + "/build/export/space-dodge-android/space-dodge-debug.aab");
        const Error e = f.fails(f.store("googleplay"));
        CHECK(has(e.message, "space-dodge-debug.aab is a debug build"));
        CHECK(has(e.hint, "export --platform android --format aab --release"));
    }
    {
        MobileFixture f;  // no keystore in factoria.json: the release export fell back to the debug key
        f.edit([](Json& j) { j["export"]["android"].erase("signing"); });
        Error e = f.fails(f.store("googleplay"));
        CHECK(has(e.message, "export/android/signing/keystore is not set"));
        CHECK(has(e.message, "debug key"));
        CHECK(has(e.hint, "keytool"));
        PublishOptions o = f.store("googleplay");  // a bundle signed some other way: passed by hand, FactorIA only warns
        o.artifact = f.aab;
        const PublishReport r = f.ok(o);
        CHECK(has(r.to_json()["warnings"].dump(), "cannot tell how space-dodge.aab was signed"));
    }
    {
        MobileFixture f;
        f.vars.erase("FACTORIA_GOOGLEPLAY_JSON_KEY");
        Error e = f.fails(f.store("googleplay"));
        CHECK(has(e.message, "FACTORIA_GOOGLEPLAY_JSON_KEY is empty"));
        CHECK(has(e.hint, "service account"));
        f.vars["SUPPLY_JSON_KEY"] = f.serviceAccount;  // fastlane's own variable works too
        CHECK(f.ok(f.store("googleplay")).steps.size() == 1);
        f.vars["SUPPLY_JSON_KEY"] = f.keys + "/nope.json";
        CHECK(has(f.fails(f.store("googleplay")).message, "which is not a file"));
        testing::write_all(f.keys + "/oauth.json", R"({"installed": {"client_secret": "PLAY-KEY-BODY"}})");
        f.vars["SUPPLY_JSON_KEY"] = f.keys + "/oauth.json";
        e = f.fails(f.store("googleplay"));
        CHECK(has(e.message, "is not a service account key"));
        CHECK_FALSE(leaks_keys(e.to_string()));
    }
    {
        MobileFixture f;
        stdfs::remove(f.aab);
        const Error e = f.fails(f.store("googleplay"));
        CHECK(has(e.message, "there is no bundle to upload"));
        CHECK(has(e.hint, "--format aab --release"));
        PublishOptions o = f.store("googleplay");
        testing::write_all(f.dir + "/app-release.apk", "PK");
        o.artifact = f.dir + "/app-release.apk";
        const Error apk = f.fails(o);
        CHECK(has(apk.message, "is not an .aab"));
        CHECK(has(apk.hint, "Android App Bundle, not an APK"));
    }
    {
        MobileFixture f;
        testing::write_all(f.dir + "/store/whats-new-es.txt", std::string(501, 'x'));
        Error e = f.fails(f.store("googleplay"));
        CHECK(has(e.message, "changelogs/es-419"));
        CHECK(has(e.message, "has 501 characters"));
        CHECK(has(e.hint, "500"));
        stdfs::remove(f.dir + "/store/whats-new-es.txt");
        CHECK(has(f.fails(f.store("googleplay")).message, "does not exist"));
        f.edit([](Json& j) { j["publish"]["googleplay"]["changelogs"]["es-419"] = "../outside.txt"; });
        CHECK(has(f.fails(f.store("googleplay")).message, "changelogs/es-419"));
    }
}

// ---- the commands ---------------------------------------------------------------------------------------------------

TEST_CASE("publish commands: documented, in the publish area, and their arguments are checked before anything runs") {
    Fixture f;
    CommandRegistry reg;
    register_publish_commands(reg, f.dir);
    for (const std::string& store : publish_stores()) {
        const CommandInfo* info = reg.info("publish." + store);
        REQUIRE(info);
        CHECK(info->category == "publish");
        CHECK_FALSE(info->readOnly);
        CHECK_FALSE(info->summary.empty());
        CHECK(has(info->description, "dryRun"));
        CHECK(has(info->description, "Examples:"));
        CHECK(has(info->description, "exporting"));
        for (auto p = info->inputSchema["properties"].begin(); p != info->inputSchema["properties"].end(); ++p)
            CHECK_MESSAGE(p.value().contains("description"), "publish." << store << " argument " << p.key());
    }
    CHECK(reg.info("publish.steam")->inputSchema["properties"].contains("appId"));
    CHECK_FALSE(reg.info("publish.itch")->inputSchema["properties"].contains("branch"));
    CHECK(reg.info("publish.gog")->inputSchema["properties"].contains("branch"));

    ScopedEnv tool("FACTORIA_STEAMCMD", kFakeTool);
    ScopedEnv cfg("FACTORIA_EXPORT_CONFIG", f.config);
    CommandResult c = reg.call("publish.steam", Json::object({{"platforms", Json::array({"windws"})}}));
    CHECK_FALSE(c.ok);
    CHECK(has(c.error["message"].get<std::string>(), "unknown platform 'windws'"));
    CHECK(has(c.error["hint"].get<std::string>(), "Did you mean 'windows'?"));

    c = reg.call("publish.steam", Json::object({{"out", "../elsewhere"}}));  // inside the project only, like fs.*
    CHECK_FALSE(c.ok);
    CHECK(c.error["code"] == "invalid_argument");
    c = reg.call("publish.steam", Json::object({{"folders", Json::object({{"windos", "x"}})}}));
    CHECK_FALSE(c.ok);
    CHECK(has(c.error["hint"].get<std::string>(), "Did you mean 'windows'?"));

    c = reg.call("publish.steam", Json::object({{"dryRun", true}, {"platforms", Json::array({"windows"})}}));
    REQUIRE(c.ok);
    CHECK(c.result["store"] == "steam");
    CHECK(c.result["dryRun"] == true);
    CHECK(c.result["steps"][0]["command"][1] == "+login");

    // explicit folders and a different out
    stdfs::rename(f.dir + "/build/export", f.dir + "/dist");
    c = reg.call("publish.steam", Json::object({{"dryRun", true}, {"out", "dist"}, {"platforms", Json::array({"linux"})}}));
    REQUIRE(c.ok);
    CHECK(has(c.result["uploads"][0]["folder"].get<std::string>(), "/dist/space-dodge-linux"));
    stdfs::rename(f.dir + "/dist/space-dodge-windows", f.dir + "/elsewhere-win");
    c = reg.call("publish.steam", Json::object({{"dryRun", true}, {"out", "dist"}, {"folders", Json::object({{"win", "elsewhere-win"}})}, {"platforms", Json::array({"windows"})}}));
    REQUIRE(c.ok);
    CHECK(has(c.result["uploads"][0]["folder"].get<std::string>(), "/elsewhere-win"));
}

TEST_CASE("publish commands: the mobile stores take a file inside the project, not export folders") {
    MobileFixture f;
    CommandRegistry reg;
    register_publish_commands(reg, f.dir);
    const Json& gp = reg.info("publish.googleplay")->inputSchema["properties"];
    CHECK(gp.contains("artifact"));
    CHECK(gp.contains("track"));
    CHECK(gp.contains("releaseStatus"));
    CHECK_FALSE(gp.contains("platforms"));
    CHECK(reg.info("publish.appstore")->inputSchema["properties"].contains("artifact"));
    CHECK_FALSE(reg.info("publish.appstore")->inputSchema["properties"].contains("track"));

    ScopedEnv tool("FACTORIA_FASTLANE", kFakeTool);
    ScopedEnv cfg("FACTORIA_EXPORT_CONFIG", f.config);
    ScopedEnv key("FACTORIA_GOOGLEPLAY_JSON_KEY", f.serviceAccount);
    CommandResult c = reg.call("publish.googleplay", Json::object({{"artifact", "../elsewhere.aab"}}));
    CHECK_FALSE(c.ok);
    CHECK(c.error["code"] == "invalid_argument");
    c = reg.call("publish.googleplay", Json::object({{"dryRun", true}, {"track", "beta"}, {"artifact", "build/export/space-dodge-android/space-dodge.aab"}}));
    REQUIRE_MESSAGE(c.ok, c.error.dump());
    CHECK(c.result["store"] == "googleplay");
    CHECK(c.result["steps"][0]["command"][1] == "supply");
    CHECK(has(c.result["uploads"][0]["destination"].get<std::string>(), "track beta"));
    CHECK_FALSE(leaks_keys(c.result.dump()));
}

TEST_CASE("publish commands: they are registered with the other tooling commands") {
    Fixture f;
    CommandRegistry reg;
    register_tooling_commands(reg, f.dir);
    for (const char* name : {"publish.steam", "publish.itch", "publish.epic", "publish.gog", "publish.appstore", "publish.googleplay"}) CHECK_MESSAGE(reg.has(name), name);
}

TEST_CASE("publish dry run: a missing uploader, secret or app id is a warning and the plan is still returned") {
    // Steam: no steamcmd, no steam_appid.txt, no account.
    {
        Fixture f(R"({"publish": {"steam": {"depots": {"windows": 5}}}})");
        stdfs::remove(f.dir + "/steam_appid.txt");
        f.vars.erase("FACTORIA_STEAMCMD");
        PublishOptions o = f.options("steam");
        o.dryRun = true;
        o.platforms = {"windows"};
        const PublishReport r = f.ok(o);
        REQUIRE(r.steps.size() == 1);
        CHECK(r.steps[0].command[0] == "steamcmd");
        const std::string warnings = r.to_json()["warnings"].dump();
        CHECK(has(warnings, "steamcmd was not found"));
        CHECK(has(warnings, "no Steam app id"));
        CHECK(has(warnings, "no Steam account"));
        o.dryRun = false;  // a real run still stops at the first missing thing
        CHECK(has(f.fails(o).message, "steamcmd was not found"));
    }
    // Epic: no ids and no secret.
    {
        Fixture f(R"({"publish": {"epic": {"artifacts": {"windows": "art"}}}})");
        PublishOptions o = f.options("epic");
        o.dryRun = true;
        o.platforms = {"windows"};
        const PublishReport r = f.ok(o);
        REQUIRE(r.steps.size() == 1);
        const std::string warnings = r.to_json()["warnings"].dump();
        CHECK(has(warnings, "has no organizationId, productId, clientId"));
        CHECK(has(warnings, "client secret is not set"));
        o.dryRun = false;
        CHECK(has(f.fails(o).message, "has no organizationId"));
    }
}
