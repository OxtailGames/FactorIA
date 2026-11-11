// MCP description budget (M100.8): a client sends every tool description with every request, so a command's description, as
// `tools/list` sends it, stays under 1.5 KB. What does not fit goes to the command's section of a doc (docs.read), which the
// description names. This test walks the REAL registry (engine, tooling, ai and skills commands, as `factoria mcp` serves it).
#include <doctest.h>

#include <filesystem>
#include <string>

#include "common.h"  // tools/cli/src: Session
#include "fa/core/fs.h"
#include "fa/mcp/server.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/scaffold.h"

namespace stdfs = std::filesystem;
using namespace fa;

TEST_CASE("mcp: no tool description passes 1.5 KB") {
    constexpr std::size_t kBudget = 1536;
    const stdfs::path oldRoot = fs::project_root();
    const stdfs::path root = fs::make_temp_dir("fa_mcp_budget");
    ScaffoldOptions opt;
    opt.writeTypings = false;
    const std::string dir = (root / "game").string();
    auto made = create_project(dir, "2d-empty", opt);
    REQUIRE_MESSAGE(made.ok(), (made.ok() ? std::string() : made.error().to_string()));
    {
        cli::SessionOptions so;
        so.gfx = cli::Gfx::None;
        auto session = cli::Session::open(dir, so);
        cli::register_cli_commands(session->registry(), dir, &session->engine());
        SimpleMcpHost host(session->registry(), dir);
        McpServer server(host);
        Json init = Json::object({{"jsonrpc", "2.0"}, {"id", 1}, {"method", "initialize"},
                                  {"params", {{"protocolVersion", "2025-06-18"}, {"capabilities", Json::object()},
                                              {"clientInfo", {{"name", "test"}, {"version", "1"}}}}}});
        server.handle_message(init.dump());
        Json list = Json::object({{"jsonrpc", "2.0"}, {"id", 2}, {"method", "tools/list"}, {"params", Json::object()}});
        auto resp = server.handle_message(list.dump());
        REQUIRE(resp.has_value());
        // Nothing is lost: what a description gave up (CommandInfo::details) is in the docs reference, and the description
        // MCP sends names where.
        const std::string reference = export_commands_markdown(session->registry());
        std::size_t withDetails = 0;
        for (const CommandInfo* c : session->registry().list()) {
            CHECK_MESSAGE(c->description.find(kCommandDetailsMark) == std::string::npos, c->name << ": a marker is left in the description");
            if (c->details.empty()) continue;
            ++withDetails;
            CHECK_MESSAGE(reference.find(c->details) != std::string::npos, c->name << ": its details are not in the docs reference");
            CHECK_MESSAGE(command_details_pointer(*c).find("docs_commands") != std::string::npos, c->name);
        }
        CHECK(withDetails > 50);
        const Json listed = Json::parse(*resp);
        const Json& tools = listed["result"]["tools"];
        CHECK(tools.size() > 150);
        for (const Json& t : tools) {
            const std::string desc = t["description"].get<std::string>();
            CHECK_MESSAGE(desc.size() <= kBudget,
                          t["name"].get<std::string>()
                              << ": the description is " << desc.size() << " bytes, over " << kBudget
                              << ". Keep the first sentence and the essentials, move the rest to the command's section of a "
                                 "docs/*.md, and end the description by naming that section (doc and heading).");
        }
    }
    fs::set_project_root(oldRoot);
    std::error_code ec;
    stdfs::remove_all(root, ec);
}
