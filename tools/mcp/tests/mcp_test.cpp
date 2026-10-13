#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <set>
#include <sstream>

#include "fa/mcp/client_config.h"
#include "fa/mcp/server.h"
#include "fa/mcp/transport.h"
#include "fa/tooling/tooling.h"
#include "fa/core/fs.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct TempDir {
    stdfs::path path;
    TempDir() {
        path = fa::fs::make_temp_dir("fa_mcp_test");
    }
    ~TempDir() {
        std::error_code ec;
        stdfs::remove_all(path, ec);
    }
};

struct Fixture {
    TempDir tmp;
    CommandRegistry registry;
    SimpleMcpHost host;
    McpServer server;
    int nextId = 1;

    Fixture() : host(registry, tmp.path.string()), server(host) {
        {
            CommandInfo i;
            i.name = "test.echo_value";
            i.summary = "Echo the value.";
            i.description = "Example: {\"value\": 3}";
            i.inputSchema = Json::parse(R"({"type":"object","properties":{"value":{"type":"integer"}},"required":["value"]})");
            registry.add(i, [](const Json& a) { return Json::object({{"echo", a["value"]}}); });
        }
        {
            CommandInfo i;
            i.name = "test.change_state";
            i.summary = "Mutating command.";
            i.readOnly = false;
            registry.add(i, [](const Json&) { return Json::object({{"changed", true}}); });
        }
        {
            CommandInfo i;
            i.name = "test.fail";
            i.summary = "Always fails.";
            registry.add(i, [](const Json&) -> Json { throw CommandError("not_found", "Entity 'x' not found.", "Use scene.list_entities."); });
        }
        {
            CommandInfo i;
            i.name = "test.array_result";
            i.summary = "Returns an array.";
            registry.add(i, [](const Json&) { return Json::array({1, 2, 3}); });
        }
        {
            CommandInfo i;
            i.name = "test.shot";
            i.summary = "Returns an image.";
            registry.add(i, [](const Json& a) {
                if (a.contains("path"))
                    return Json::object({{"$image", Json::object({{"path", a["path"]}, {"mimeType", "image/png"}})}, {"frame", 5}});
                return Json::object({{"$image", Json::object({{"base64", "iVBORw0KGgo="}, {"mimeType", "image/png"}})}});
            });
        }
        register_tooling_commands(registry, tmp.path.string());
    }

    Json rpc(const std::string& method, Json params = Json::object()) {
        Json req = Json::object({{"jsonrpc", "2.0"}, {"id", nextId++}, {"method", method}, {"params", std::move(params)}});
        auto resp = server.handle_message(req.dump());
        REQUIRE(resp.has_value());
        return Json::parse(*resp);
    }
    Json initialize(const std::string& version = "2025-06-18") {
        return rpc("initialize", {{"protocolVersion", version}, {"capabilities", Json::object()},
                                  {"clientInfo", {{"name", "test"}, {"version", "1"}}}});
    }
    Json call(const std::string& tool, Json args = Json::object()) {
        return rpc("tools/call", {{"name", tool}, {"arguments", std::move(args)}});
    }
};

}  // namespace

TEST_CASE("mcp: initialize negotiates protocol versions") {
    Fixture f;
    for (const char* v : {"2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"}) {
        Json r = f.initialize(v);
        CHECK(r["result"]["protocolVersion"] == v);
    }
    Json r = f.initialize("1999-01-01");
    CHECK(r["result"]["protocolVersion"] == "2025-11-25");
    CHECK(r["id"].is_number());
    const Json& res = r["result"];
    CHECK(res["serverInfo"]["name"] == "factoria");
    CHECK(res["capabilities"]["tools"]["listChanged"] == true);
    CHECK(res["capabilities"]["resources"]["listChanged"] == true);
    CHECK(res["capabilities"].contains("prompts"));
    CHECK(res["capabilities"].contains("logging"));
    std::string instr = res["instructions"];
    CHECK(instr.find("feedback_report") != std::string::npos);
    CHECK(instr.find("+Y is up") != std::string::npos);
    CHECK(f.server.initialized());
    CHECK(f.server.client_name() == "test");
}

TEST_CASE("mcp: notifications get no response; ping works; unknown method errors") {
    Fixture f;
    CHECK_FALSE(f.server.handle_message(R"({"jsonrpc":"2.0","method":"notifications/initialized"})").has_value());
    CHECK_FALSE(f.server.handle_message(R"({"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":1}})").has_value());
    CHECK_FALSE(f.server.handle_message(R"({"jsonrpc":"2.0","method":"notifications/unknown"})").has_value());
    CHECK(f.rpc("ping")["result"].is_object());
    Json r = f.rpc("does/not_exist");
    CHECK(r["error"]["code"] == -32601);
    CHECK(r["id"] == f.nextId - 1);
}

TEST_CASE("mcp: malformed input yields JSON-RPC errors") {
    Fixture f;
    Json parseErr = Json::parse(*f.server.handle_message("{not json"));
    CHECK(parseErr["error"]["code"] == -32700);
    CHECK(parseErr["id"].is_null());
    Json invalid = Json::parse(*f.server.handle_message("42"));
    CHECK(invalid["error"]["code"] == -32600);
    Json noVersion = Json::parse(*f.server.handle_message(R"({"id":1,"method":"ping"})"));
    CHECK(noVersion["error"]["code"] == -32600);
    Json emptyBatch = Json::parse(*f.server.handle_message("[]"));
    CHECK(emptyBatch["error"]["code"] == -32600);
}

TEST_CASE("mcp: string ids and batches") {
    Fixture f;
    Json r = Json::parse(*f.server.handle_message(R"({"jsonrpc":"2.0","id":"abc","method":"ping"})"));
    CHECK(r["id"] == "abc");
    auto batch = f.server.handle_message(R"([{"jsonrpc":"2.0","id":1,"method":"ping"},{"jsonrpc":"2.0","method":"notifications/initialized"},{"jsonrpc":"2.0","id":2,"method":"ping"}])");
    REQUIRE(batch.has_value());
    Json arr = Json::parse(*batch);
    REQUIRE(arr.is_array());
    CHECK(arr.size() == 2);
}

TEST_CASE("mcp: tools/list maps command names and describes tools") {
    Fixture f;
    f.initialize();
    Json r = f.rpc("tools/list");
    const Json& tools = r["result"]["tools"];
    Json* echo = nullptr;
    Json toolsCopy = tools;
    std::set<std::string> names;
    for (auto& t : toolsCopy) {
        std::string n = t["name"];
        names.insert(n);
        CHECK(n.size() <= 64);
        CHECK(n.find('.') == std::string::npos);
        CHECK(t["inputSchema"]["type"] == "object");
        if (n == "test_echo_value") echo = &t;
    }
    REQUIRE(echo != nullptr);
    CHECK((*echo)["description"] == "Echo the value.\n\nExample: {\"value\": 3}");
    CHECK((*echo)["annotations"]["readOnlyHint"] == true);
    CHECK((*echo)["annotations"]["destructiveHint"] == false);
    CHECK((*echo)["inputSchema"]["required"][0] == "value");
    for (auto& t : toolsCopy)
        if (t["name"] == "test_change_state") {
            CHECK(t["annotations"]["readOnlyHint"] == false);
            CHECK(t["annotations"]["destructiveHint"] == true);
        }
    for (const char* n : {"feedback_report", "feedback_list", "docs_read", "docs_search", "fs_edit", "project_validate"})
        CHECK_MESSAGE(names.count(n) == 1, n);
    CHECK(mcp_tool_name("a.b_c") == "a_b_c");
    CHECK(mcp_tool_name("we ird!name").find(' ') == std::string::npos);
    CHECK(mcp_tool_name(std::string(100, 'x')).size() == 64);
}

TEST_CASE("mcp: tools/call success returns text and structuredContent") {
    Fixture f;
    Json r = f.call("test_echo_value", {{"value", 7}});
    const Json& res = r["result"];
    CHECK(res["isError"] == false);
    REQUIRE(res["content"].size() == 1);
    CHECK(res["content"][0]["type"] == "text");
    Json parsed = Json::parse(res["content"][0]["text"].get<std::string>());
    CHECK(parsed["echo"] == 7);
    CHECK(res["structuredContent"]["echo"] == 7);
    // Non-object results: text only.
    Json arr = f.call("test_array_result")["result"];
    CHECK_FALSE(arr.contains("structuredContent"));
    CHECK(arr["isError"] == false);
}

TEST_CASE("mcp: tools/call failures are isError results with code, message and hint") {
    Fixture f;
    Json res = f.call("test_fail")["result"];
    CHECK(res["isError"] == true);
    CHECK(res["content"][0]["text"] == "not_found: Entity 'x' not found.\nhint: Use scene.list_entities.");
    // Schema validation failure
    Json bad = f.call("test_echo_value", {{"value", "seven"}})["result"];
    CHECK(bad["isError"] == true);
    // Unknown tool: did-you-mean
    Json unknown = f.call("test_echo_vlaue")["result"];
    CHECK(unknown["isError"] == true);
    CHECK(unknown["content"][0]["text"].get<std::string>().find("test_echo_value") != std::string::npos);
    // Protocol-level problems
    Json missing = f.rpc("tools/call", Json::object());
    CHECK(missing["error"]["code"] == -32602);
    Json badArgs = f.rpc("tools/call", {{"name", "test_fail"}, {"arguments", 5}});
    CHECK(badArgs["error"]["code"] == -32602);
}

TEST_CASE("mcp: $image results add an image content block") {
    Fixture f;
    Json res = f.call("test_shot")["result"];
    REQUIRE(res["content"].size() == 2);
    CHECK(res["content"][1]["type"] == "image");
    CHECK(res["content"][1]["data"] == "iVBORw0KGgo=");
    CHECK(res["content"][1]["mimeType"] == "image/png");
    // The bulky base64 is not duplicated in the text block.
    CHECK(res["content"][0]["text"].get<std::string>().find("iVBORw0KGgo=") == std::string::npos);

    // path form (relative to the project directory)
    {
        std::ofstream out(f.tmp.path / "shot.png", std::ios::binary);
        out << std::string("\x89PNG\r\n\x1a\n", 8);
    }
    Json byPath = f.call("test_shot", {{"path", "shot.png"}})["result"];
    REQUIRE(byPath["content"].size() == 2);
    CHECK(byPath["content"][1]["data"] == "iVBORw0KGgo=");
    CHECK(byPath["content"][0]["text"].get<std::string>().find("shot.png") != std::string::npos);
    CHECK(byPath["structuredContent"]["frame"] == 5);
    // missing file => text only, with an explanation
    Json missing = f.call("test_shot", {{"path", "nope.png"}})["result"];
    CHECK(missing["content"].size() == 1);
    CHECK(missing["content"][0]["text"].get<std::string>().find("not found") != std::string::npos);
}

TEST_CASE("mcp: tool calls through the real tooling commands") {
    Fixture f;
    Json w = f.call("fs_write", {{"path", "notes.txt"}, {"content", "hello"}})["result"];
    CHECK(w["isError"] == false);
    Json rd = f.call("fs_read", {{"path", "../escape"}})["result"];
    CHECK(rd["isError"] == true);
    Json fb = f.call("feedback_report", {{"category", "physics"}, {"severity", "major"}, {"title", "No one-way platforms"},
                                         {"missing", "needed one-way"}, {"workaround", "script"}})["result"];
    CHECK(fb["isError"] == false);
    CHECK(fb["structuredContent"]["id"] == "FB-0001");
}

TEST_CASE("mcp: resources list and read") {
    Fixture f;
    {
        std::ofstream(f.tmp.path / "factoria.json") << R"({"format":"factoria.project/1","name":"T"})";
        std::ofstream(f.tmp.path / "ENGINE_FEEDBACK.json") << R"({"format":"factoria.feedback/1","project":"T","entries":[]})";
    }
    Json list = f.rpc("resources/list")["result"]["resources"];
    std::set<std::string> uris;
    for (auto& r : list) {
        uris.insert(r["uri"]);
        CHECK_FALSE(r["mimeType"].get<std::string>().empty());
    }
    CHECK(uris.count("factoria://docs/SCRIPTING.md") == 1);
    CHECK(uris.count("factoria://project/factoria.json") == 1);
    CHECK(uris.count("factoria://project/ENGINE_FEEDBACK.json") == 1);

    Json doc = f.rpc("resources/read", {{"uri", "factoria://docs/SCRIPTING.md"}});
    REQUIRE(doc.contains("result"));
    CHECK(doc["result"]["contents"][0]["mimeType"] == "text/markdown");
    CHECK(doc["result"]["contents"][0]["text"].get<std::string>().find("Behaviour") != std::string::npos);

    Json proj = f.rpc("resources/read", {{"uri", "factoria://project/factoria.json"}});
    CHECK(proj["result"]["contents"][0]["mimeType"] == "application/json");
    CHECK(Json::parse(proj["result"]["contents"][0]["text"].get<std::string>())["name"] == "T");

    Json missing = f.rpc("resources/read", {{"uri", "factoria://docs/NOPE.md"}});
    CHECK(missing["error"]["code"] == -32002);
    Json notExposed = f.rpc("resources/read", {{"uri", "factoria://project/../secret"}});
    CHECK(notExposed.contains("error"));
    CHECK(f.rpc("resources/read", Json::object())["error"]["code"] == -32602);
}

TEST_CASE("mcp: prompts list and get") {
    Fixture f;
    Json list = f.rpc("prompts/list")["result"]["prompts"];
    std::set<std::string> names;
    for (auto& p : list) names.insert(p["name"]);
    for (const char* n : {"make-game", "add-feature", "fix-bug", "report-engine-gap"}) CHECK(names.count(n) == 1);

    Json mg = f.rpc("prompts/get", {{"name", "make-game"}, {"arguments", {{"idea", "a space shooter"}}}})["result"];
    REQUIRE(mg["messages"].size() == 1);
    CHECK(mg["messages"][0]["role"] == "user");
    std::string text = mg["messages"][0]["content"]["text"];
    CHECK(text.find("a space shooter") != std::string::npos);
    for (const char* tool : {"project_validate", "game_screenshot", "feedback_report", "game_step"})
        CHECK_MESSAGE(text.find(tool) != std::string::npos, tool);

    for (auto [name, key] : {std::pair{"add-feature", "feature"}, {"fix-bug", "description"}}) {
        Json r = f.rpc("prompts/get", {{"name", name}, {"arguments", {{key, "XYZZY"}}}})["result"];
        CHECK(r["messages"][0]["content"]["text"].get<std::string>().find("XYZZY") != std::string::npos);
    }
    Json gap = f.rpc("prompts/get", {{"name", "report-engine-gap"}})["result"];
    CHECK(gap["messages"][0]["content"]["text"].get<std::string>().find("feedback_report") != std::string::npos);

    CHECK(f.rpc("prompts/get", {{"name", "make-game"}})["error"]["code"] == -32602);   // missing idea
    CHECK(f.rpc("prompts/get", {{"name", "make-gam"}})["error"]["code"] == -32602);    // unknown
}

TEST_CASE("mcp: tools/list_changed and log notifications") {
    Fixture f;
    f.server.notify_tools_changed();
    auto queued = f.server.drain_outgoing();
    REQUIRE(queued.size() == 1);
    CHECK(Json::parse(queued[0])["method"] == "notifications/tools/list_changed");
    CHECK(Json::parse(queued[0]).contains("id") == false);

    std::vector<std::string> got;
    f.server.set_notification_sink([&](const std::string& m) { got.push_back(m); });
    f.server.log("debug", "test", "hidden at info level");
    CHECK(got.empty());
    f.server.log("warning", "test", "visible");
    REQUIRE(got.size() == 1);
    CHECK(Json::parse(got[0])["params"]["level"] == "warning");
    CHECK(f.rpc("logging/setLevel", {{"level", "debug"}})["result"].is_object());
    f.server.log("debug", "test", "now visible");
    CHECK(got.size() == 2);
    CHECK(f.rpc("logging/setLevel", {{"level", "loud"}})["error"]["code"] == -32602);
    f.server.notify_tools_changed();
    CHECK(got.size() == 3);
}

TEST_CASE("mcp: stdio transport is newline-delimited and writes only protocol messages") {
    Fixture f;
    std::istringstream in(
        "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-03-26\"}}\n"
        "\n"
        "{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}\r\n"
        "garbage\n"
        "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"test_echo_value\",\"arguments\":{\"value\":1}}}\n");
    std::ostringstream out;
    CHECK(run_stdio(f.server, in, out) == 0);
    std::istringstream lines(out.str());
    std::string line;
    std::vector<Json> msgs;
    while (std::getline(lines, line)) {
        REQUIRE_NOTHROW(msgs.push_back(Json::parse(line)));  // every line is exactly one JSON message
    }
    REQUIRE(msgs.size() == 3);
    CHECK(msgs[0]["result"]["protocolVersion"] == "2025-03-26");
    CHECK(msgs[1]["error"]["code"] == -32700);
    CHECK(msgs[2]["result"]["structuredContent"]["echo"] == 1);
    // Multi-line text in results must stay on one line (escaped).
    CHECK(out.str().find("\\n") != std::string::npos);
}

TEST_CASE("mcp: client config helpers are reachable from fa_mcp") {
    Json cfg = claude_code_mcp_config();
    CHECK(cfg["mcpServers"]["factoria"]["args"] == Json::array({"mcp", "--project", "."}));
    CHECK(codex_mcp_toml().find("[mcp_servers.factoria]") != std::string::npos);
}
