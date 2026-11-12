// M92.1b2b: the tooling commands declare what they may do, and the writers among them keep an MCP client or an agent inside the
// project (image documents, vectors, rigs, signing). The asset and audio commands have their own tests.
#include <doctest.h>

#include <filesystem>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/capability.h"
#include "fa/core/command.h"
#include "fa/runtime/project.h"
#include "fa/tooling/tooling.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Call {
    const char* command;
    Json args;
};

}  // namespace

TEST_CASE("tooling commands declare their capabilities explicitly (M92.1b2b)") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    CommandRegistry reg;
    register_tooling_commands(reg, tmp.sub("game"));
    using capability_sets::reads;
    using capability_sets::writes_project;
    const std::vector<std::pair<std::string, CapabilitySet>> expected = {
        {"agent.cost", reads()},
        {"docs.read", reads()},
        {"fs.read", reads()},
        {"fs.write", writes_project()},
        {"checkpoint.create", writes_project()},
        {"checkpoint.read", reads()},
        {"project.validate", reads()},
        {"project.export", CapabilitySet{Capability::Read, Capability::WriteProject, Capability::Process, Capability::Network}},
        {"feedback.list", reads()},
        {"feedback.report", writes_project()},
        {"feedback.verdicts", CapabilitySet{Capability::Read, Capability::WriteProject, Capability::Network}},
        {"feedback.share", CapabilitySet{Capability::Read, Capability::WriteProject, Capability::Network, Capability::Publish}},
        {"setup.status", CapabilitySet{Capability::Read, Capability::Process, Capability::Network}},
        {"setup.install", CapabilitySet{Capability::Read, Capability::WriteAnywhere, Capability::Process, Capability::Network}},
        {"sign.macos", CapabilitySet{Capability::Read, Capability::WriteProject, Capability::Process, Capability::Network}},
        {"shader.compile", CapabilitySet{Capability::Read, Capability::Process}},
        {"image.create", writes_project()},
        {"image.info", reads()},
        {"image.export", writes_project()},
        {"image.frame.add", writes_project()},
        {"image.tileset.build", writes_project()},
        {"image.pixel", writes_project()},
        {"vector.add", writes_project()},
        {"vector.to_rig", writes_project()},
    };
    for (const auto& [name, set] : expected) {
        CAPTURE(name);
        const CommandInfo* info = reg.info(name);
        REQUIRE(info != nullptr);
        CHECK(info->capabilitiesDeclared);
        CHECK(info->capabilities == set);
    }
}

TEST_CASE("image, vector, vector_rig and sign.macos refuse an output outside the project or inside .git for an MCP client") {
    testing::TempDir tmp;
    testing::TempDir other;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path game = tmp.path / "game";
    stdfs::create_directories(game / ".git");
    stdfs::create_directories(game / "assets" / "art");
    CommandRegistry reg;
    register_tooling_commands(reg, game.generic_string());
    const std::string outsideDoc = (other.path / "evil.image.json").generic_string();
    const std::string outsidePng = (other.path / "evil.png").generic_string();
    const std::string outsideSvg = (other.path / "evil.svg").generic_string();

    auto create = [&](const char* key, const std::string& value) {
        Json args = Json::object({{"path", "assets/art/ok.image.json"}, {"width", 8}, {"height", 8}});
        args[key] = value;
        return Call{"image.create", args};
    };
    const std::vector<Call> calls = {
        // image edit: the document and the PNG it bakes to
        create("path", "../evil.image.json"),
        create("path", outsideDoc),
        create("path", ".git/evil.image.json"),
        create("output", "../evil.png"),
        create("output", outsidePng),
        create("output", ".git/evil.png"),
        // image frame / tile / indexed / tileset: the document, and the tileset's own `output` and `rules`
        {"image.frame.add", Json::object({{"path", "../evil.image.json"}})},
        {"image.frame.add", Json::object({{"path", outsideDoc}})},
        {"image.frame.add", Json::object({{"path", ".git/evil.image.json"}})},
        {"image.tile.set", Json::object({{"path", ".git/evil.image.json"}, {"enabled", true}})},
        {"image.pixel", Json::object({{"path", "../evil.image.json"}})},
        {"image.draw", Json::object({{"path", outsideDoc}})},
        {"image.tileset.build", Json::object({{"path", "../evil.image.json"}})},
        {"image.tileset.build", Json::object({{"path", "assets/art/t.image.json"}, {"output", "../evil.png"}})},
        {"image.tileset.build", Json::object({{"path", "assets/art/t.image.json"}, {"output", ".git/evil.png"}})},
        {"image.tileset.build", Json::object({{"path", "assets/art/t.image.json"}, {"rules", "../evil.json"}})},
        {"image.tileset.build", Json::object({{"path", "assets/art/t.image.json"}, {"rules", ".git/evil.json"}})},
        // vector and vector_rig
        {"vector.add", Json::object({{"source", "assets/art/a.svg"}, {"out", "../evil.svg"}, {"shape", "rect"}})},
        {"vector.add", Json::object({{"source", "assets/art/a.svg"}, {"out", outsideSvg}, {"shape", "rect"}})},
        {"vector.add", Json::object({{"source", "assets/art/a.svg"}, {"out", ".git/evil.svg"}, {"shape", "rect"}})},
        {"vector.to_rig", Json::object({{"source", "assets/art/a.svg"}, {"out", "../evil.prefab.json"}})},
        {"vector.to_rig", Json::object({{"source", "assets/art/a.svg"}, {"out", outsideSvg}})},
        {"vector.to_rig", Json::object({{"source", "assets/art/a.svg"}, {"out", ".git/evil.prefab.json"}})},
        {"vector.to_rig", Json::object({{"source", "assets/art/a.svg"}, {"atlas", ".git/evil.png"}})},
        // sign.macos: `app` is signed in place
        {"sign.macos", Json::object({{"app", "../Evil.app"}, {"dryRun", true}})},
        {"sign.macos", Json::object({{"app", (other.path / "Evil.app").generic_string()}, {"dryRun", true}})},
        {"sign.macos", Json::object({{"app", ".git/Evil.app"}, {"dryRun", true}})},
    };
    {
        CommandCallerScope mcp(CommandCaller::Mcp);
        for (const Call& c : calls) {
            CAPTURE(c.command);
            CAPTURE(c.args.dump());
            REQUIRE(reg.has(c.command));
            auto r = reg.call(c.command, c.args);
            CHECK_FALSE(r.ok);
        }
    }
    for (const char* name : {"evil.image.json", "evil.png", "evil.svg", "evil.prefab.json", "Evil.app"})
        CHECK_FALSE(stdfs::exists(other.path / name));
    CHECK_FALSE(stdfs::exists(tmp.path / "evil.image.json"));
    CHECK_FALSE(stdfs::exists(tmp.path / "evil.png"));
    CHECK(stdfs::is_empty(game / ".git"));
    CHECK_FALSE(stdfs::exists(game / "assets" / "art" / "ok.image.json"));

    // Inside the project the same caller can write.
    CommandCallerScope mcp(CommandCaller::Mcp);
    auto ok = reg.call("image.create", Json::object({{"path", "assets/art/ok.image.json"}, {"width", 8}, {"height", 8}}));
    CHECK_MESSAGE(ok.ok, ok.error.dump());
    CHECK(stdfs::exists(game / "assets" / "art" / "ok.image.json"));
    CHECK(stdfs::exists(game / "assets" / "art" / "ok.png"));
}

TEST_CASE("a {read,state} scope is refused the writers and the network commands; the command-line user may write an absolute path") {
    testing::TempDir tmp;
    testing::TempDir other;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path game = tmp.path / "game";
    CommandRegistry reg;
    register_tooling_commands(reg, game.generic_string());
    {
        CommandCapabilityScope readOnly(CapabilitySet{Capability::Read, Capability::State});
        const std::vector<Call> refused = {
            {"fs.write", Json::object({{"path", "notes.txt"}, {"content", "x"}})},
            {"image.create", Json::object({{"path", "assets/ok.image.json"}, {"width", 8}, {"height", 8}})},
            {"vector.add", Json::object({{"source", "assets/a.svg"}, {"shape", "rect"}})},
            {"feedback.report", Json::object({{"title", "x"}})},
            {"feedback.verdicts", Json::object()},
            {"feedback.share", Json::object()},
            {"setup.status", Json::object()},
            {"sign.macos", Json::object({{"dryRun", true}})},
            {"project.export", Json::object({{"platform", "web"}})},
        };
        for (const Call& c : refused) {
            CAPTURE(c.command);
            REQUIRE(reg.has(c.command));
            auto r = reg.call(c.command, c.args);
            REQUIRE_FALSE(r.ok);
            CHECK_MESSAGE(r.error["code"] == "capability_denied", r.error.dump());
        }
        CHECK_FALSE(stdfs::exists(game / "notes.txt"));
        CHECK_FALSE(stdfs::exists(game / "assets" / "ok.image.json"));
        // A read still works.
        CHECK(reg.call("fs.read", Json::object({{"path", "factoria.json"}})).ok);
    }
    const std::string outside = (other.path / "plug").generic_string();
    {
        // An MCP client may not name a folder outside the project.
        CommandCallerScope mcp(CommandCaller::Mcp);
        CHECK_FALSE(reg.call("project.new_plugin", Json::object({{"name", "p1"}, {"path", outside}, {"dryRun", true}})).ok);
        CHECK_FALSE(stdfs::exists(other.path / "plug"));
    }
    // The command-line user (every capability) may.
    auto user = reg.call("project.new_plugin", Json::object({{"name", "p1"}, {"path", outside}, {"dryRun", true}}));
    CHECK_MESSAGE(user.ok, user.error.dump());
    CHECK_FALSE(stdfs::exists(other.path / "plug"));  // a dry run writes nothing
}
