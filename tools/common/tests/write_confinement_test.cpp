// Commands that write to a path their caller gives (M92.2b): the path goes through fa::fs::resolve_for_write, so an MCP client or an
// agent (no WriteAnywhere) stays inside the project, and only the command-line user may name another folder. The families that
// have their own fixture (i18n.export, player.run_ios_sim, perf.baseline, docs.write_reference) are tested in their own files.
#include <doctest.h>

#include <filesystem>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/capability.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/runtime/project.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/tooling.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

bool has_text(const std::string& haystack, const std::string& needle) { return haystack.find(needle) != std::string::npos; }

// Every "x-fa-path" in a schema says "read" or "write".
void collect_paths(const Json& schema, const std::string& where, std::vector<std::string>& bad, int& count) {
    if (!schema.is_object()) return;
    if (schema.contains("x-fa-path")) {
        ++count;
        if (!schema["x-fa-path"].is_string() || (schema["x-fa-path"] != "read" && schema["x-fa-path"] != "write"))
            bad.push_back(where);
    }
    for (auto it = schema.begin(); it != schema.end(); ++it) collect_paths(it.value(), where + "/" + it.key(), bad, count);
}

}  // namespace

TEST_CASE("resolve_write_path: the project root refuses managed folders, the caller's right decides on absolute paths") {
    testing::TempDir tmp;
    testing::TempDir other;
    const std::string dir = tmp.str();
    std::error_code ec;
    const stdfs::path root = stdfs::weakly_canonical(tmp.path, ec);

    // The command-line user: an absolute path is theirs to name.
    auto abs = resolve_write_path(dir, (other.path / "out.png").generic_string());
    REQUIRE_MESSAGE(abs.ok(), abs.error().message);
    CHECK(abs.value().filename() == "out.png");
    CHECK(resolve_write_path(dir, "build/x.png").value() == root / "build" / "x.png");

    {
        CommandCapabilityScope mcp(capability_sets::mcp());
        for (const char* bad : {"../x.png", "a/../../x.png", "/tmp/x.png", "C:/x.png", "~/x.png"}) {
            CAPTURE(bad);
            auto r = resolve_write_path(dir, bad);
            REQUIRE_FALSE(r.ok());
            CHECK_FALSE(r.error().hint.empty());
        }
        CHECK(fs::path_error_code(resolve_write_path(dir, (other.path / "out.png").generic_string()).error()) == "absolute_path_denied");
        CHECK(fs::path_error_code(resolve_write_path(dir, "../x.png").error()) == "path_outside_root");
        CHECK(resolve_write_path(dir, "build/x.png").ok());
    }
    {
        CommandCapabilityScope agent(capability_sets::agent());
        CHECK_FALSE(resolve_write_path(dir, (other.path / "out.png").generic_string()).ok());
    }

    // The tools' own folders are not a target for a command's output unless it opts in; .factoria/tmp is the scratch folder.
    CHECK(fs::path_error_code(resolve_write_path(dir, ".git/config").error()) == "managed_path_denied");
    CHECK(fs::path_error_code(resolve_write_path(dir, ".factoria/settings.json").error()) == "managed_path_denied");
    CHECK(resolve_write_path(dir, ".factoria/tmp/shot.png").ok());
    CHECK(resolve_write_path(dir, ".factoria/settings.json", fs::WriteRoot::Project, fs::ManagedFolders::Allow).ok());
}

TEST_CASE("project.new_plugin: path stays inside the project for MCP and agents, the command-line user may name any folder") {
    testing::TempDir tmp;
    testing::TempDir other;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    CommandRegistry reg;
    register_plugin_commands(reg, dir);

    const std::string outside = (other.path / "plug").generic_string();
    {
        CommandCapabilityScope mcp(capability_sets::mcp());
        for (const std::string& bad : {std::string("../plug"), outside, std::string("${HOME}/plug")}) {
            CAPTURE(bad);
            auto r = reg.call("project.new_plugin", Json::object({{"name", "p1"}, {"path", bad}, {"dryRun", true}}));
            REQUIRE_FALSE(r.ok);
            CHECK(r.error["code"] == "invalid_argument");
            CHECK(has_text(r.error["message"].get<std::string>(), "path"));
            CHECK_FALSE(r.error["hint"].get<std::string>().empty());
        }
        CHECK_FALSE(stdfs::exists(other.path / "plug"));
        // Inside the project the same call works.
        auto ok = reg.call("project.new_plugin", Json::object({{"name", "p1"}, {"path", "plugins/p1"}, {"dryRun", true}}));
        CHECK_MESSAGE(ok.ok, ok.error.dump());
    }
    // The user: an absolute folder is accepted (a dry run writes nothing).
    auto user = reg.call("project.new_plugin", Json::object({{"name", "p1"}, {"path", outside}, {"dryRun", true}}));
    CHECK_MESSAGE(user.ok, user.error.dump());
    CHECK_FALSE(stdfs::exists(other.path / "plug"));
}

TEST_CASE("project.export: out stays inside the project for MCP and agents (refused before anything is built)") {
    testing::TempDir tmp;
    testing::TempDir other;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    CommandRegistry reg;
    register_tooling_commands(reg, dir);
    REQUIRE(reg.has("project.export"));

    CommandCapabilityScope mcp(capability_sets::mcp());
    for (const std::string& bad : {std::string("../export"), (other.path / "export").generic_string(), std::string(".git/export")}) {
        CAPTURE(bad);
        auto r = reg.call("project.export", Json::object({{"platform", "linux"}, {"out", bad}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "invalid_argument");
        CHECK_FALSE(r.error["hint"].get<std::string>().empty());
    }
    CHECK_FALSE(stdfs::exists(other.path / "export"));
    CHECK_FALSE(stdfs::exists(tmp.path / "export"));
}

TEST_CASE("x-fa-path: every annotation in the registered commands' schemas says read or write, and the writing ones are marked") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    CommandRegistry reg;
    register_tooling_commands(reg, tmp.sub("game"));
    std::vector<std::string> bad;
    int count = 0;
    for (const CommandInfo* info : reg.list()) collect_paths(info->inputSchema, info->name, bad, count);
    CHECK(bad.empty());
    CHECK(count > 10);
    // The commands that write to a caller-given path say so.
    for (const auto& [command, argument] : std::vector<std::pair<std::string, std::string>>{
             {"fs.write", "path"}, {"project.export", "out"}, {"i18n.export", "out"}, {"project.new_plugin", "path"},
             {"perf.baseline", "file"}, {"player.run_ios_sim", "screenshot"}}) {
        CAPTURE(command);
        const CommandInfo* info = reg.info(command);
        REQUIRE(info != nullptr);
        REQUIRE(info->inputSchema["properties"].contains(argument));
        CHECK(info->inputSchema["properties"][argument].value("x-fa-path", std::string()) == "write");
    }
}
