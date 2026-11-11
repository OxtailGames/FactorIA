// MCP description budget (M100.8): a client sends every tool description with every request, so a command's description, as
// `tools/list` sends it, stays under 1.5 KB. What does not fit goes to the command's section of a doc (docs.read), which the
// description names. This test walks the REAL registry (engine, tooling, ai and skills commands, as `factoria mcp` serves it).
#include <doctest.h>

#include <filesystem>
#include <regex>
#include <string>

#include "common.h"  // tools/cli/src: Session
#include "fa/core/fs.h"
#include "fa/mcp/server.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/scaffold.h"

namespace stdfs = std::filesystem;
using namespace fa;

namespace {
// What the client receives for a description is the JSON string: a quote, a backslash and a newline cost two bytes each,
// and a control character six. The budget counts those, not the characters of the C++ string.
std::size_t sent_bytes(const std::string& text) { return Json(text).dump().size() - 2; }

// Puts the project root and the temporary folder back whatever a REQUIRE or CHECK did in between.
struct RootGuard {
    stdfs::path oldRoot = fs::project_root();
    stdfs::path root = fs::make_temp_dir("fa_mcp_budget");
    ~RootGuard() {
        fs::set_project_root(oldRoot);
        std::error_code ec;
        stdfs::remove_all(root, ec);
    }
};
}  // namespace

TEST_CASE("mcp: no tool description passes 1.5 KB as it is sent") {
    constexpr std::size_t kBudget = 1536;
    RootGuard guard;
    const stdfs::path root = guard.root;
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
            const std::size_t bytes = sent_bytes(desc);
            CHECK_MESSAGE(bytes <= kBudget,
                          t["name"].get<std::string>()
                              << ": the description is " << bytes << " bytes as sent (JSON escaped), over " << kBudget
                              << ". Keep the first sentence and the essentials, move the rest to `details` (cut at a sentence "
                                 "with FA_COMMAND_DETAILS), and end the description by naming that section (doc and heading).");
        }
        // A sentence glued to the next one ("{mask}.Without") is a text that lost its space when it was split or joined.
        const std::regex glued(R"([})\]]\.[A-Z][a-z])");
        for (const CommandInfo* c : session->registry().list()) {
            CHECK_MESSAGE(!std::regex_search(c->description, glued), c->name << ": a sentence starts right after a full stop, with no space");
            CHECK_MESSAGE(!std::regex_search(c->details, glued), c->name << ": a sentence of `details` starts right after a full stop, with no space");
        }
    }
}
