// project.examples and project.create {example} as an MCP game AI calls them (docs/design/BUILDING.md, "Example games in the
// release"): the same registrations `factoria mcp` serves with and without a project, a caller that holds the capabilities of an
// MCP client, and a downloader that serves a release folder, so nothing touches the network.
#include <doctest.h>

#include <filesystem>
#include <set>
#include <string>

#include "common.h"  // tools/cli/src: Session, register_cli_commands
#include "fa/core/capability.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/examples.h"
#include "fa/tooling/scaffold.h"

namespace stdfs = std::filesystem;
using namespace fa;

namespace {

constexpr const char* kVersion = "0.30.0";

struct Scratch {
    stdfs::path path = fs::make_temp_dir("fa_examples_cmd").value();
    ~Scratch() {
        std::error_code ec;
        fs::remove_tree(path, ec);
    }
};

void write_text_file(const stdfs::path& p, const std::string& text) {
    REQUIRE(fs::write_text(fs::path_to_utf8(p), text).ok());
}

// A release folder with one example (`cat-chase`) and the context that downloads from it.
struct FakeRelease {
    Scratch assets, home;
    bool offline = false;
    int downloads = 0;

    FakeRelease() {
        Scratch src;
        write_text_file(src.path / "examples.json",
                        R"({"format":"factoria.examples-source/1","examples":[
                            {"name":"cat-chase","title":"Cat Chase","shows":"A chase.","readFirst":["docs/SCRIPTING.md"]}]})");
        write_text_file(src.path / "cat-chase/factoria.json",
                        R"({"format":"factoria.project/1","id":"com.test.catchase","name":"cat-chase"})");
        write_text_file(src.path / "cat-chase/scripts/main.js", "// chase\n");
        auto m = package_examples(src.path, assets.path, kVersion);
        REQUIRE_MESSAGE(m.ok(), (m.ok() ? std::string() : m.error().to_string()));
    }
    SetupContext ctx() {
        SetupContext c;
        c.home = fs::path_to_utf8(home.path);
        c.engineVersion = kVersion;
        c.download = [this](const DownloadRequest& rq) {
            DownloadResult r;
            const std::string file = rq.url.substr(rq.url.rfind('/') + 1);
            const stdfs::path from = assets.path / fs::path_from_utf8(file);
            std::error_code ec;
            if (offline || !stdfs::exists(from, ec)) {
                r.ok = false;
                r.error = make_error(
                    offline ? "Cannot download " + rq.what + ": no network." : "HTTP 404 for " + rq.url, "Try later.");
                return r;
            }
            ++downloads;
            const stdfs::path dest = fs::path_from_utf8(rq.destination);
            stdfs::create_directories(dest.parent_path(), ec);
            stdfs::copy_file(from, dest, stdfs::copy_options::overwrite_existing, ec);
            if (ec) {
                r.ok = false;
                r.error = make_error("copy failed: " + ec.message(), "");
            }
            return r;
        };
        return c;
    }
};

struct ScopedContext {
    explicit ScopedContext(const SetupContext& c) { set_examples_context(c); }
    ~ScopedContext() { set_examples_context(std::nullopt); }
};

// What `factoria mcp` serves without a project and what it serves inside one.
// `relative`: the folders are given relative to `out` (a caller that may not write anywhere gives them inside the project).
void check_registry(CommandRegistry& reg, FakeRelease& rel, const stdfs::path& out, bool relative) {
    auto where = [&](const char* name) { return relative ? std::string(name) : fs::path_to_utf8(out / name); };
    REQUIRE(reg.has("project.examples"));
    REQUIRE(reg.has("project.create"));
    // Both are declared (the walks of command_paths_test depend on it) and MCP may call them: no WriteAnywhere needed.
    for (const char* name : {"project.examples", "project.create"}) {
        const CommandInfo* info = reg.info(name);
        REQUIRE(info);
        CHECK(info->capabilitiesDeclared);
        CHECK((CapabilitySet{Capability::Read, Capability::WriteProject, Capability::Network})
                  .has_all(info->capabilities));
        CHECK_FALSE(info->capabilities.has(Capability::WriteAnywhere));
    }
    CHECK(reg.info("project.examples")->capabilities.has(Capability::Network));
    CHECK_FALSE(reg.info("project.examples")->capabilities.has(Capability::WriteProject));
    CHECK_FALSE(reg.info("project.create")->readOnly);
    CHECK(reg.info("project.create")->inputSchema["properties"].contains("example"));

    CommandCallerScope mcp(CommandCaller::Mcp);

    auto listed = reg.call("project.examples", Json::object());
    REQUIRE_MESSAGE(listed.ok, listed.error.dump());
    REQUIRE(listed.result["examples"].size() == 1);
    CHECK(listed.result["examples"][0]["name"] == "cat-chase");
    CHECK(listed.result["examples"][0]["readFirst"][0] == "docs/SCRIPTING.md");
    CHECK(listed.result["engineVersion"] == kVersion);
    CHECK(listed.result["stale"] == false);

    const std::string dir = where("chase");
    auto made = reg.call("project.create", Json::object({{"dir", dir}, {"example", "cat-chase"}, {"name", "Chase"}}));
    REQUIRE_MESSAGE(made.ok, made.error.dump());
    CHECK(made.result["dir"].get<std::string>().find("chase") != std::string::npos);
    CHECK(stdfs::exists(out / "chase/scripts/main.js"));
    CHECK(rel.downloads == 3);  // the manifest for project.examples, the manifest again for project.create, and the zip
    CHECK(fs::read_text(fs::path_to_utf8(out / "chase/factoria.json")).value().find("\"Chase\"") != std::string::npos);

    // A name that does not exist: did you mean, and nothing is created.
    auto wrong = reg.call("project.create", Json::object({{"dir", where("w")}, {"example", "cat-chas"}}));
    REQUIRE_FALSE(wrong.ok);
    CHECK(wrong.error["message"].get<std::string>().find("cat-chase") != std::string::npos);
    CHECK_FALSE(stdfs::exists(out / "w"));

    // A template and an example together are a contradiction, named by its pointer, before anything is downloaded.
    const int before = rel.downloads;
    auto both = reg.call("project.create",
                         Json::object({{"dir", where("b")}, {"example", "cat-chase"}, {"template", "2d-empty"}}));
    REQUIRE_FALSE(both.ok);
    CHECK(both.error["message"].get<std::string>().find("/template") != std::string::npos);
    CHECK(rel.downloads == before);
    CHECK_FALSE(stdfs::exists(out / "b"));

    // The template way is what it was.
    auto tmpl = reg.call("project.create", Json::object({{"dir", where("t")}, {"template", "2d-empty"}}));
    REQUIRE_MESSAGE(tmpl.ok, tmpl.error.dump());
    CHECK(stdfs::exists(out / "t/factoria.json"));

    // A client that was not granted the network cannot download (the read-only MCP of `factoria mcp --read-only` is refused first).
    {
        CommandCapabilityScope noNetwork(CapabilitySet{Capability::Read, Capability::WriteProject});
        auto denied = reg.call("project.create", Json::object({{"dir", where("n")}, {"example", "cat-chase"}}));
        REQUIRE_FALSE(denied.ok);
        CHECK(denied.error["code"] == "capability_denied");
        CHECK_FALSE(stdfs::exists(out / "n"));
        auto list = reg.call("project.examples", Json::object());
        REQUIRE_FALSE(list.ok);
        CHECK(list.error["code"] == "capability_denied");
    }
    {
        CommandCapabilityScope readOnly(capability_sets::mcp_read_only());
        auto denied = reg.call("project.create", Json::object({{"dir", where("r")}, {"example", "cat-chase"}}));
        REQUIRE_FALSE(denied.ok);
        CHECK(denied.error["code"] == "capability_denied");
    }
}

}  // namespace

TEST_CASE("examples commands: `factoria mcp` without a project serves project.examples and project.create {example}") {
    FakeRelease rel;
    Scratch out;
    ScopedContext scoped(rel.ctx());
    CommandRegistry reg;
    cli::register_cli_commands(reg, "", nullptr);
    check_registry(reg, rel, out.path, false);
}

TEST_CASE("examples commands: `factoria mcp --project` serves the same two commands") {
    FakeRelease rel;
    Scratch out;
    const std::string project = fs::path_to_utf8(out.path / "game");
    ScaffoldOptions opt;
    opt.writeTypings = false;
    auto made = create_project(project, "2d-empty", opt);
    REQUIRE_MESSAGE(made.ok(), (made.ok() ? std::string() : made.error().to_string()));
    const stdfs::path root = fs::project_root();
    ScopedContext scoped(rel.ctx());
    {
        cli::SessionOptions so;
        so.gfx = cli::Gfx::None;
        auto session = cli::Session::open(project, so);
        CommandRegistry& reg = session->registry();
        cli::register_cli_commands(reg, project, &session->engine());
        check_registry(reg, rel, out.path / "game", true);
    }
    fs::set_project_root(root);
}
