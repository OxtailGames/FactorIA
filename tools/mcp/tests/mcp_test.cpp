#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <set>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include "fa/mcp/client_config.h"
#include "fa/mcp/server.h"
#include "fa/mcp/stdio.h"
#include "fa/mcp/transport.h"
#include "fa/tooling/feedback_share.h"
#include "fa/tooling/tooling.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct TempDir {
    stdfs::path path;
    TempDir() {
        path = fa::fs::make_temp_dir("fa_mcp_test").value();
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
            i.inputSchema = Json::parse(R"({"type":"object","properties":{"path":{"type":"string","description":"Image file."}}})");
            registry.add(i, [](const Json& a) {
                if (a.contains("path"))
                    return Json::object({{"$image", Json::object({{"path", a["path"]}, {"mimeType", "image/png"}})}, {"frame", 5}});
                return Json::object({{"$image", Json::object({{"base64", "iVBORw0KGgo="}, {"mimeType", "image/png"}})}});
            });
        }
        {
            // Like game.screenshot without `path`: writes <project>/.factoria/screenshots/<name> and flags it temporary.
            CommandInfo i;
            i.name = "test.temp_shot";
            i.summary = "Returns a temporary image file.";
            i.inputSchema = Json::parse(R"({"type":"object","properties":{"name":{"type":"string"},"temporary":{"type":"boolean"}}})");
            const std::string dir = tmp.path.string();
            registry.add(i, [dir](const Json& a) {
                const std::string name = a.value("name", std::string("frame_9.png"));
                const stdfs::path file = stdfs::path(dir) / ".factoria" / "screenshots" / name;
                stdfs::create_directories(file.parent_path());
                std::ofstream(file, std::ios::binary) << std::string("\x89PNG\r\n\x1a\n", 8);
                Json image = Json::object({{"path", file.generic_string()}, {"mimeType", "image/png"}});
                if (a.value("temporary", true)) image["temporary"] = true;
                return Json::object({{"frame", 9}, {"$image", image}});
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

// The result a tools/call sent: the JSON of its first text block (it is sent once, as text).
Json result_json(const Json& res) {
    CHECK_FALSE(res.contains("structuredContent"));
    return Json::parse(res["content"][0]["text"].get<std::string>());
}

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
    CHECK(instr.find("BY SECTION, never whole") != std::string::npos);  // the guide is read by heading
    CHECK(instr.find("\"heading\":\"Index\"") != std::string::npos);  // ... starting with its index
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

TEST_CASE("mcp: a value of the wrong type is an Invalid Request, never an exception") {
    Fixture f;
    f.initialize();
    auto answer = [&](const std::string& m) {
        std::optional<std::string> r;
        REQUIRE_NOTHROW(r = f.server.handle_message(m));
        REQUIRE(r.has_value());
        return Json::parse(*r);
    };
    // the id is kept when it is valid, null when it is not or there is none
    Json r = answer(R"({"jsonrpc":2,"method":"notifications/cancelled","params":{"requestId":3}})");
    CHECK(r["error"]["code"] == -32600);
    CHECK(r["id"].is_null());
    r = answer(R"({"jsonrpc":2,"id":5,"method":"ping"})");
    CHECK(r["error"]["code"] == -32600);
    CHECK(r["id"] == 5);
    r = answer(R"({"jsonrpc":"2.0","id":6,"method":7})");
    CHECK(r["error"]["code"] == -32600);
    CHECK(r["error"]["message"].get<std::string>().find("\"method\" must be a string") != std::string::npos);
    CHECK(r["id"] == 6);
    r = answer(R"({"jsonrpc":"2.0","id":{"a":1},"method":"ping"})");
    CHECK(r["error"]["code"] == -32600);
    CHECK(r["id"].is_null());
    r = answer(R"({"jsonrpc":"2.0","id":[1],"method":"ping"})");
    CHECK(r["id"].is_null());
    r = answer(R"({"jsonrpc":"2.0","id":8,"method":"tools/call","params":"test_echo_value"})");
    CHECK(r["error"]["code"] == -32600);
    CHECK(r["id"] == 8);
    r = answer(R"({"jsonrpc":"2.0","id":9,"method":"ping","params":[1]})");
    CHECK(r["error"]["code"] == -32600);
    r = answer(R"({"jsonrpc":null,"id":10,"method":"ping"})");
    CHECK(r["error"]["code"] == -32600);
    // a batch answers each item: the invalid ones with an error, the others as usual
    r = answer(R"([1,{"jsonrpc":2,"id":11,"method":"ping"},{"jsonrpc":"2.0","id":12,"method":"ping"}])");
    REQUIRE(r.is_array());
    REQUIRE(r.size() == 3);
    CHECK(r[0]["error"]["code"] == -32600);
    CHECK(r[1]["id"] == 11);
    CHECK(r[1]["error"]["code"] == -32600);
    CHECK(r[2]["id"] == 12);
    CHECK(r[2]["result"].is_object());
    // a field the server reads of the wrong type: treated as missing, or Invalid params
    r = answer(R"({"jsonrpc":"2.0","id":13,"method":"initialize","params":{"protocolVersion":20250618,"clientInfo":{"name":5}}})");
    CHECK(r["result"]["protocolVersion"] == kMcpLatestProtocol);
    r = answer(R"({"jsonrpc":"2.0","id":14,"method":"logging/setLevel","params":{"level":3}})");
    CHECK(r["error"]["code"] == -32602);
    r = answer(R"({"jsonrpc":"2.0","id":15,"method":"tools/call","params":{"name":42}})");
    CHECK(r["error"]["code"] == -32602);
    CHECK(f.server.session()->requests_in_flight() == 0);
    // the next request works as usual
    CHECK(result_json(f.call("test_echo_value", {{"value", 3}})["result"])["echo"] == 3);
}

TEST_CASE("mcp: over stdio malformed lines get errors, the valid ones around them are answered, and the server stays up") {
    Fixture f;
    std::istringstream in(
        "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-06-18\"}}\n"
        "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"test_echo_value\",\"arguments\":{\"value\":1}}}\n"
        "{\"jsonrpc\":2,\"method\":\"notifications/cancelled\",\"params\":{\"requestId\":3}}\n"
        "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":5}\n"
        "{\"jsonrpc\":\"2.0\",\"id\":{\"x\":1},\"method\":\"ping\"}\n"
        "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"ping\",\"params\":\"oops\"}\n"
        "[1,{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"ping\"}]\n"
        "{not json\n"
        "{\"jsonrpc\":2,\"id\":6,\"method\":\"tools/call\",\"params\":{\"name\":\"test_echo_value\",\"arguments\":{\"value\":2}}}\n"
        "{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"tools/call\",\"params\":{\"name\":\"test_echo_value\",\"arguments\":{\"value\":3}}}\n");
    std::ostringstream out;
    CHECK(run_stdio(f.server, in, out) == 0);
    std::istringstream lines(out.str());
    std::string line;
    std::vector<Json> msgs;
    while (std::getline(lines, line)) msgs.push_back(Json::parse(line));
    REQUIRE(msgs.size() == 10);
    CHECK(msgs[0]["result"]["protocolVersion"] == "2025-06-18");
    CHECK(result_json(msgs[1]["result"])["echo"] == 1);
    CHECK(msgs[2]["error"]["code"] == -32600);  // "jsonrpc": 2, no id
    CHECK(msgs[2]["id"].is_null());
    CHECK(msgs[3]["error"]["code"] == -32600);  // method 5
    CHECK(msgs[3]["id"] == 3);
    CHECK(msgs[4]["error"]["code"] == -32600);  // an object id
    CHECK(msgs[4]["id"].is_null());
    CHECK(msgs[5]["error"]["code"] == -32600);  // string params
    CHECK(msgs[5]["id"] == 4);
    REQUIRE(msgs[6].is_array());                // the batch
    CHECK(msgs[6][0]["error"]["code"] == -32600);
    CHECK(msgs[6][1]["id"] == 5);
    CHECK(msgs[7]["error"]["code"] == -32700);  // not JSON
    CHECK(msgs[8]["error"]["code"] == -32600);  // "jsonrpc": 2 with an id: the call does not run
    CHECK(msgs[8]["id"] == 6);
    CHECK(result_json(msgs[9]["result"])["echo"] == 3);
    CHECK(f.server.session()->requests_queued() == 0);  // nothing invalid was announced as queued
    CHECK(f.server.session()->requests_in_flight() == 0);
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
    // test.echo_value declares nothing: its _meta says so; the set is the one derived from readOnly.
    CHECK((*echo)["_meta"]["factoria/capabilitiesDeclared"] == false);
    CHECK((*echo)["_meta"]["factoria/capabilities"].is_array());
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

TEST_CASE("mcp: a tool result is sent once, as the whole JSON in a text block, whatever the protocol") {
    for (const char* version : {"2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"}) {
        Fixture f;
        f.initialize(version);
        const Json res = f.call("test_echo_value", {{"value", 7}})["result"];
        CHECK(res["isError"] == false);
        CHECK_FALSE(res.contains("structuredContent"));  // a client that reads only `content` misses nothing
        REQUIRE(res["content"].size() == 1);
        CHECK(res["content"][0]["type"] == "text");
        CHECK(Json::parse(res["content"][0]["text"].get<std::string>()) == Json::object({{"echo", 7}}));
    }
    // A result that is not an object: the same.
    Fixture f;
    Json arr = f.call("test_array_result")["result"];
    CHECK(arr["isError"] == false);
    CHECK(result_json(arr) == Json::array({1, 2, 3}));
}

TEST_CASE("mcp: an unknown argument is an error that teaches; the transport key _meta is not an argument") {
    Fixture f;
    Json bad = f.call("test_echo_value", {{"vlaue", 7}})["result"];
    CHECK(bad["isError"] == true);
    const std::string text = bad["content"][0]["text"].get<std::string>();
    CHECK(text.find("invalid_arguments") != std::string::npos);
    CHECK(text.find("/vlaue") != std::string::npos);
    CHECK(text.find("did you mean 'value'") != std::string::npos);  // from the missing required 'value'
    CHECK(text.find("unknown property 'vlaue'") != std::string::npos);
    // Some clients put `_meta` inside the arguments object: it is stripped, never reported.
    Json ok = f.call("test_echo_value", {{"value", 7}, {"_meta", {{"progressToken", "t1"}}}})["result"];
    CHECK(ok["isError"] == false);
    CHECK(result_json(ok)["echo"] == 7);
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

TEST_CASE("mcp: a command filter hides commands from tools/list and refuses to call them") {
    Fixture f;
    f.server.set_command_filter([](const CommandInfo& i) { return i.readOnly; });
    f.initialize();
    std::set<std::string> names;
    Json listed = f.rpc("tools/list");
    for (auto& t : listed["result"]["tools"]) names.insert(t["name"].get<std::string>());
    CHECK(names.count("test_echo_value") == 1);
    CHECK(names.count("test_change_state") == 0);
    CHECK(f.call("test_echo_value", {{"value", 1}})["result"]["isError"] == false);
    Json blocked = f.call("test_change_state")["result"];
    CHECK(blocked["isError"] == true);
}

namespace {
std::set<std::string> listed_tool_names(Fixture& f) {
    std::set<std::string> names;
    const Json listed = f.rpc("tools/list");
    for (const auto& t : listed["result"]["tools"]) names.insert(t["name"].get<std::string>());
    return names;
}
void add_group_command(Fixture& f, const char* name, const char* category, bool readOnly) {
    CommandInfo i;
    i.name = name;
    i.category = category;
    i.summary = "A command of a group.";
    i.readOnly = readOnly;
    f.registry.add(i, [](const Json&) { return Json::object({{"ran", true}}); });
}
}  // namespace

TEST_CASE("mcp: a tool profile lists the core set and the loader tools; tool_load adds a group and says so") {
    Fixture f;
    add_group_command(f, "wobble.spin", "wobble", true);
    add_group_command(f, "wobble.stop", "wobble", false);
    f.initialize();
    const std::size_t all = listed_tool_names(f).size();
    CHECK(listed_tool_names(f).count("tool_load") == 0);  // no profile: every command, no loader tools
    CHECK(f.server.set_tool_profile({"core"}).empty());
    std::set<std::string> names = listed_tool_names(f);
    CHECK(names.size() < all);
    CHECK(names.count("tool_load") == 1);
    CHECK(names.count("tool_describe") == 1);
    CHECK(names.count("tool_call") == 1);
    CHECK(names.count("wobble_spin") == 0);
    CHECK(names.count("fs_read") == 1);
    const Json listed = f.rpc("tools/list");
    for (const auto& t : listed["result"]["tools"]) CHECK(t["description"].get<std::string>().size() < 1536);
    // The description names the groups with their counts.
    for (const auto& t : listed["result"]["tools"])
        if (t["name"] == "tool_load") CHECK(t["description"].get<std::string>().find("wobble (2)") != std::string::npos);
    f.server.drain_outgoing();
    const Json res = f.call("tool_load", {{"groups", Json::array({"wobble"})}})["result"];
    CHECK(res["isError"] == false);
    CHECK(result_json(res)["added"] == 2);
    bool notified = false;
    for (const std::string& line : f.server.drain_outgoing())
        if (Json::parse(line).value("method", "") == "notifications/tools/list_changed") notified = true;
    CHECK(notified);
    names = listed_tool_names(f);
    CHECK(names.count("wobble_spin") == 1);
    CHECK(names.count("wobble_stop") == 1);
    // Loading it again changes nothing and sends nothing.
    CHECK(result_json(f.call("tool_load", {{"groups", Json::array({"wobble"})}})["result"])["added"] == 0);
    CHECK(f.server.drain_outgoing().empty());
    // No groups: the list of groups.
    CHECK(result_json(f.call("tool_load")["result"]).contains("groups"));
    // "all" is the default again for a profile list that holds it.
    CHECK(f.server.set_tool_profile({"all"}).empty());
    CHECK_FALSE(f.server.tool_profile_active());
}

TEST_CASE("mcp: tool_describe and tool_call reach a command outside the profile; an unknown group is refused") {
    Fixture f;
    add_group_command(f, "wobble.spin", "wobble", true);
    f.initialize();
    CHECK(f.server.set_tool_profile({"core"}).empty());
    const Json described = result_json(f.call("tool_describe", {{"commands", Json::array({"wobble.spin", "wobble_spun"})}})["result"]);
    REQUIRE(described["commands"].size() == 1);
    CHECK(described["commands"][0]["tool"] == "wobble_spin");
    CHECK(described["unknown"][0]["hint"].get<std::string>().find("wobble.spin") != std::string::npos);
    const Json called = f.call("tool_call", {{"command", "wobble.spin"}, {"arguments", Json::object()}})["result"];
    CHECK(called["isError"] == false);
    CHECK(result_json(called)["ran"] == true);
    CHECK(listed_tool_names(f).count("wobble_spin") == 0);  // the list did not change
    const Json missing = f.call("tool_call", {{"command", "wobble.spun"}})["result"];
    CHECK(missing["isError"] == true);
    CHECK(missing["content"][0]["text"].get<std::string>().find("wobble.spin") != std::string::npos);
    // An unknown group: refused with a suggestion, nothing is loaded, no notification.
    f.server.drain_outgoing();
    const Json bad = f.call("tool_load", {{"groups", Json::array({"wobbel"})}})["result"];
    CHECK(bad["isError"] == true);
    CHECK(bad["content"][0]["text"].get<std::string>().find("wobble") != std::string::npos);
    CHECK(f.server.drain_outgoing().empty());
    CHECK(listed_tool_names(f).count("wobble_spin") == 0);
    const std::string err = f.server.set_tool_profile({"core", "wobbel"});
    CHECK(err.find("wobbel") != std::string::npos);
    CHECK(err.find("wobble") != std::string::npos);
    // A profile that was refused leaves the server as it was.
    CHECK(f.server.tool_profile_active());
}

TEST_CASE("mcp: a read-only filter and the user-only commands still apply through the profile tools") {
    Fixture f;
    add_group_command(f, "wobble.spin", "wobble", true);
    add_group_command(f, "wobble.stop", "wobble", false);
    CommandInfo i;
    i.name = "ai.plugin_install";
    i.category = "ai";
    i.summary = "Installs a plugin.";
    i.readOnly = true;
    f.registry.add(i, [](const Json&) { return Json::object(); });
    f.server.set_command_filter([](const CommandInfo& c) { return c.readOnly; });
    f.initialize();
    CHECK(f.server.set_tool_profile({"core"}).empty());
    CHECK(f.call("tool_call", {{"command", "wobble.spin"}})["result"]["isError"] == false);
    CHECK(f.call("tool_call", {{"command", "wobble.stop"}})["result"]["isError"] == true);
    CHECK(f.call("tool_call", {{"command", "ai.plugin_install"}})["result"]["isError"] == true);
    CHECK(result_json(f.call("tool_describe", {{"commands", Json::array({"wobble.stop"})}})["result"]).contains("unknown"));  // not read-only: not there
}

TEST_CASE("mcp: a group the read-only filter hides says so; tool_call is read-only on a read-only server; tool_call arguments must be an object") {
    Fixture f;
    add_group_command(f, "wobble.spin", "wobble", true);
    add_group_command(f, "hidden.stop", "hidden", false);
    f.initialize();
    // No filter: tool_call can run writes, so it is annotated as a write tool.
    CHECK(f.server.set_tool_profile({"core"}).empty());
    auto call_annotations = [&] {
        const Json listed = f.rpc("tools/list");  // a named value: a range over `f.rpc(...)[..]` would dangle
        for (const auto& t : listed["result"]["tools"])
            if (t["name"] == "tool_call") return Json(t["annotations"]);
        return Json::object();
    };
    CHECK(call_annotations()["destructiveHint"] == true);
    CHECK(call_annotations()["readOnlyHint"] == false);
    // tool_call with arguments that are not an object: an isError result that names tool_call, not a JSON-RPC error.
    for (const Json& bad : {Json("text"), Json(3), Json::array({1})}) {
        const Json r = f.call("tool_call", {{"command", "wobble.spin"}, {"arguments", bad}});
        REQUIRE(r.contains("result"));
        CHECK(r["result"]["isError"] == true);
        const std::string text = r["result"]["content"][0]["text"].get<std::string>();
        CHECK(text.find("tool_call") != std::string::npos);
        CHECK(text.find("object") != std::string::npos);
    }
    CHECK(f.call("tool_call", {{"command", "wobble.spin"}, {"arguments", nullptr}})["result"]["isError"] == false);
    // A read-only server: a group that only has write commands is "hidden", not "unknown".
    f.server.set_command_filter([](const CommandInfo& c) { return c.readOnly; });
    const std::string hidden = f.server.set_tool_profile({"core", "hidden"});
    CHECK(hidden.find("read-only") != std::string::npos);
    CHECK(hidden.find("matches no command") == std::string::npos);
    const std::string typo = f.server.set_tool_profile({"core", "hiden"});
    CHECK(typo.find("matches no command") != std::string::npos);
    CHECK(f.server.tool_profile_active());  // refused profiles changed nothing: the core profile from above is still on
    // Only unknown groups: refused too.
    CHECK_FALSE(f.server.set_tool_profile({"nope1", "nope2"}).empty());
    CHECK(f.server.tool_profile_active());
    CHECK(f.server.set_tool_profile({"core"}).empty());
    CHECK(call_annotations()["readOnlyHint"] == true);
    CHECK(call_annotations()["destructiveHint"] == false);
}

TEST_CASE("mcp: ai.plugin_install is neither listed nor callable (only the user installs software)") {
    Fixture f;
    bool ran = false;
    CommandInfo i;
    i.name = "ai.plugin_install";
    i.summary = "Installs a plugin.";
    i.readOnly = false;
    f.registry.add(i, [&ran](const Json&) {
        ran = true;
        return Json::object();
    });
    f.initialize();
    // A named value: iterating `f.rpc(...)["result"]["tools"]` directly leaves the range pointing into a temporary that is
    // already destroyed (C++20 only extends the lifetime of the first temporary, not the one behind operator[]); the MSVC
    // debug heap overwrites it, so every element read as a number.
    const Json listedAll = f.rpc("tools/list");
    for (const auto& t : listedAll["result"]["tools"]) CHECK(t["name"] != "ai_plugin_install");
    CHECK(f.call("ai_plugin_install")["result"]["isError"] == true);
    CHECK_FALSE(ran);
    CHECK(is_user_only_command("ai.plugin_install"));
    CHECK_FALSE(is_user_only_command("ai.run"));
}

TEST_CASE("mcp: a tools/call runs its command as an MCP client's call (command_caller), the library call as the user's") {
    Fixture f;
    CommandInfo i;
    i.name = "test.who_calls";
    i.summary = "Says who the caller of the running command is.";
    f.registry.add(i, [](const Json&) { return Json::object({{"caller", command_caller_name(command_caller())}}); });
    f.initialize();
    const Json viaMcp = f.call("test_who_calls");
    REQUIRE(viaMcp["result"]["isError"] == false);
    CHECK(result_json(viaMcp["result"])["caller"] == "an MCP client");
    CHECK(command_caller() == CommandCaller::User);  // the scope ended with the call
    CHECK(f.registry.call("test.who_calls").result["caller"] == "the user");
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
    CHECK(result_json(byPath)["frame"] == 5);
    // missing file => text only, with an explanation
    Json missing = f.call("test_shot", {{"path", "nope.png"}})["result"];
    CHECK(missing["content"].size() == 1);
    CHECK(missing["content"][0]["text"].get<std::string>().find("not found") != std::string::npos);
}

TEST_CASE("mcp: tool calls through the real tooling commands") {
    // feedback_report takes the lock of the user's sharing files: in a scratch folder, never the real ~/.factoria.
    const std::filesystem::path scratch = fa::fs::make_temp_dir("fa_mcp_home").value();
    fa::ShareEnv scratchEnv;
    scratchEnv.env = [h = scratch.string()](const std::string& name) -> std::string {
        return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? h : "";
    };
    fa::ScopedShareEnv scopedHome(scratchEnv);
    struct Cleanup {
        std::filesystem::path dir;
        ~Cleanup() {
            std::error_code ec;
            fa::fs::remove_tree(dir, ec);
        }
    } cleanup{scratch};
    Fixture f;
    Json w = f.call("fs_write", {{"path", "notes.txt"}, {"content", "hello"}})["result"];
    CHECK(w["isError"] == false);
    Json rd = f.call("fs_read", {{"path", "../escape"}})["result"];
    CHECK(rd["isError"] == true);
    Json fb = f.call("feedback_report", {{"category", "physics"}, {"severity", "major"}, {"title", "No cloth simulation"},
                                         {"missing", "needed a cloth solver"}, {"workaround", "script"}})["result"];
    CHECK(fb["isError"] == false);
    CHECK(result_json(fb)["id"] == "FB-0001");
    // project.export is a registered tooling command, so it is an MCP tool (an unknown platform is a tool error).
    Json ex = f.call("project_export", {{"platform", "amiga"}})["result"];
    CHECK(ex["isError"] == true);
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
    // Reading is by section: the guide's index first, components one at a time, never the whole guide or `full`.
    CHECK(text.find("\"heading\":\"Index\"") != std::string::npos);
    CHECK(text.find("docs_list") != std::string::npos);
    CHECK(text.find("never with \"full\"") != std::string::npos);
    CHECK(text.find("docs_read {\"name\":\"ai-guide\"}") == std::string::npos);

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

TEST_CASE("mcp: a long tool call with a progressToken sends notifications/progress; without one nothing") {
    Fixture f;
    std::mutex mu;
    std::vector<Json> got;
    bool withToken = false;  // the call asked for progress: the command waits for what it should have caused
    // Waits (up to 10 s) until `n` notifications start with `prefix`, instead of sleeping a fixed time: a busy CI machine
    // can wake the heartbeat thread late.
    auto wait_for = [&](const std::string& prefix, std::size_t n) {
        const auto end = std::chrono::steady_clock::now() + std::chrono::seconds(10);
        while (withToken && std::chrono::steady_clock::now() < end) {
            {
                std::lock_guard<std::mutex> lock(mu);
                std::size_t seen = 0;
                for (const Json& m : got)
                    if (m["params"]["message"].get<std::string>().rfind(prefix, 0) == 0) ++seen;
                if (seen >= n) return;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
        }
    };
    CommandInfo i;
    i.name = "test.slow";
    i.summary = "Reports what it does, then returns.";
    f.registry.add(i, [&](const Json&) {
        report_command_progress("step one");
        wait_for("step one", 1);  // sent when the throttle is over
        report_command_progress("step two");
        wait_for("step two", 2);  // sent, then repeated by the heartbeat while the command is silent
        return Json::object({{"done", true}});
    });
    f.server.set_notification_sink([&](const std::string& m) {
        std::lock_guard<std::mutex> lock(mu);
        got.push_back(Json::parse(m));
    });
    f.server.set_progress_timing(std::chrono::milliseconds(50), std::chrono::milliseconds(100));

    // No token: the client did not ask for progress.
    auto plain = f.rpc("tools/call", {{"name", "test_slow"}, {"arguments", Json::object()}});
    CHECK(plain["result"]["isError"] == false);
    {
        std::lock_guard<std::mutex> lock(mu);
        CHECK(got.empty());
    }

    withToken = true;
    auto reply = f.rpc("tools/call", {{"name", "test_slow"},
                                      {"arguments", Json::object()},
                                      {"_meta", Json::object({{"progressToken", 7}})}});
    CHECK(reply["result"]["isError"] == false);
    std::lock_guard<std::mutex> lock(mu);
    REQUIRE(got.size() >= 3);
    double last = 0;
    bool sawStepTwo = false, sawHeartbeat = false;
    for (const Json& n : got) {
        CHECK(n["method"] == "notifications/progress");
        CHECK(n["params"]["progressToken"] == 7);
        CHECK(n["params"]["progress"].get<double>() > last);  // strictly increasing, as the MCP spec requires
        last = n["params"]["progress"].get<double>();
        const std::string msg = n["params"]["message"].get<std::string>();
        CHECK(msg.find("[") != std::string::npos);  // ends with the elapsed time
        if (msg.rfind("step two", 0) == 0) sawStepTwo = true;
        if (msg.rfind("step two", 0) == 0 && &n != &got.front()) sawHeartbeat = true;  // repeated while silent
    }
    CHECK(sawStepTwo);
    CHECK(sawHeartbeat);
    // A quick call sends nothing at all (the first message waits for the throttle).
    got.clear();
    CHECK(f.rpc("tools/call", {{"name", "test_echo_value"},
                               {"arguments", Json::object({{"value", 1}})},
                               {"_meta", Json::object({{"progressToken", "abc"}})}})["result"]["isError"] == false);
    CHECK(got.empty());
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
    CHECK(result_json(msgs[2]["result"])["echo"] == 1);
    // Multi-line text in results must stay on one line (escaped).
    CHECK(out.str().find("\\n") != std::string::npos);
}

TEST_CASE("mcp: client config helpers are reachable from fa_mcp") {
    Json cfg = claude_code_mcp_config();
    CHECK(cfg["mcpServers"]["factoria"]["args"] == Json::array({"mcp", "--project", "."}));
    CHECK(codex_mcp_toml().find("[mcp_servers.factoria]") != std::string::npos);
}

TEST_CASE("mcp: a temporary screenshot is attached and then its file is deleted; other images stay") {
    Fixture f;
    const stdfs::path shots = f.tmp.path / ".factoria" / "screenshots";
    // temporary: the image block is there, the file is gone, and the text no longer names a path to read.
    Json res = f.call("test_temp_shot")["result"];
    REQUIRE(res["content"].size() == 2);
    CHECK(res["content"][1]["type"] == "image");
    CHECK(res["content"][1]["data"] == "iVBORw0KGgo=");
    CHECK_FALSE(stdfs::exists(shots / "frame_9.png"));
    const std::string text = res["content"][0]["text"].get<std::string>();
    CHECK(text.find("frame_9.png") == std::string::npos);
    CHECK(text.find("deleted") != std::string::npos);
    CHECK(result_json(res)["$image"]["temporary"] == true);
    CHECK_FALSE(result_json(res)["$image"].contains("path"));
    // a file the user named is not temporary: it stays and its path is still in the reply
    Json kept = f.call("test_temp_shot", {{"name", "hall.png"}, {"temporary", false}})["result"];
    REQUIRE(kept["content"].size() == 2);
    CHECK(stdfs::exists(shots / "hall.png"));
    CHECK(kept["content"][0]["text"].get<std::string>().find("hall.png") != std::string::npos);
    // flagged but not named by the engine: never deleted
    Json odd = f.call("test_temp_shot", {{"name", "hall2.png"}})["result"];
    REQUIRE(odd["content"].size() == 2);
    CHECK(stdfs::exists(shots / "hall2.png"));
}

// ---- Result size cap -------------------------------------------------------------------------------------------------

namespace {

// "x" then `n` two-byte characters: a cut at an even byte count falls inside one.
std::string accented(std::size_t n) {
    std::string s = "x";
    for (std::size_t k = 0; k < n; ++k) s += "\xC3\xA9";
    return s;
}

void add_big_commands(CommandRegistry& registry) {
    CommandInfo paged;
    paged.name = "test.big_list";
    paged.summary = "A long list that pages.";
    paged.inputSchema = Json::parse(R"({"type":"object","properties":{
        "offset":{"type":"integer","description":"First item."},"limit":{"type":"integer","description":"Items."}}})");
    registry.add(paged, [](const Json&) {
        Json items = Json::array();
        for (int k = 0; k < 2000; ++k) items.push_back(Json::object({{"id", k}, {"name", accented(20)}}));
        return Json::object({{"total", 2000}, {"items", items}});
    });
    CommandInfo narrow;
    narrow.name = "test.big_text";
    narrow.summary = "One long string; no paging, a filter.";
    narrow.inputSchema = Json::parse(R"({"type":"object","properties":{"filter":{"type":"string","description":"Filter."}}})");
    registry.add(narrow, [](const Json&) { return Json::object({{"text", accented(40000)}}); });
    CommandInfo own = paged;
    own.name = "test.big_own_paging";
    own.inputSchema = Json::parse(R"({"type":"object","properties":{
        "pageToken":{"type":"string","description":"Where to go on."},"filter":{"type":"string","description":"Filter."},
        "homepage":{"type":"string","description":"Not paging: the word is inside another one."},
        "uvOffset":{"type":"array","items":{"type":"number"},"description":"Not paging: a vector."},
        "rateLimit":{"type":"number","description":"Not paging: a number."},
        "entityLimit":{"type":"integer","description":"Entities."}}})");
    registry.add(own, registry.handler("test.big_list"));
    CommandInfo bare;
    bare.name = "test.big_array";
    bare.summary = "A long array result (not an object), no arguments.";
    registry.add(bare, [](const Json&) {
        Json items = Json::array();
        for (int k = 0; k < 5000; ++k) items.push_back(k);
        return items;
    });
}

}  // namespace

TEST_CASE("mcp: a result over the cap is cut whole-JSON and UTF-8 safe, with a note that names the paging arguments") {
    constexpr std::size_t kCap = 16 * 1024;
    for (const char* version : {"2025-11-25", "2025-03-26"}) {
        INFO("protocol " << version);
        Fixture f;
        add_big_commands(f.registry);
        f.initialize(version);
        f.server.set_result_cap(kCap);

        const Json list = f.call("test_big_list")["result"];
        CHECK(list["isError"] == false);
        const Json value = result_json(list);  // parses: valid JSON
        CHECK(value.dump().size() <= kCap);
        CHECK(value["total"] == 2000);  // small fields stay
        REQUIRE(value["items"].is_array());
        CHECK(value["items"].size() > 10);
        CHECK(value["items"].size() < 2000);
        CHECK(value["items"][0]["name"] == accented(20));  // whole items, the first ones
        const std::string note = value["_truncated"]["note"].get<std::string>();
        CHECK(note.find("[truncated]") == 0);
        CHECK(note.find("`/items` keeps the first " + std::to_string(value["items"].size()) + " of 2000 items") != std::string::npos);
        CHECK(note.find("`offset` and `limit`") != std::string::npos);

        // The command's own paging arguments (camelCase pageToken, entityLimit), in its schema's order; homepage, a uvOffset
        // vector and a rateLimit number are not paging.
        const Json own = result_json(f.call("test_big_own_paging")["result"]);
        CHECK(own["_truncated"]["note"].get<std::string>().find("`pageToken` and `entityLimit`: call it again") != std::string::npos);

        const Json text = result_json(f.call("test_big_text")["result"]);
        const std::string kept = text["text"].get<std::string>();
        CHECK(is_valid_utf8(kept));  // never cut inside a character
        CHECK(kept.size() < 80001);
        CHECK(kept.size() > 1000);
        CHECK(text["_truncated"]["note"].get<std::string>().find("does not page: ask for less with `filter`") != std::string::npos);

        // A result that is not an object is wrapped: {"result": the cut result, "_truncated": ...}
        const Json arr = result_json(f.call("test_big_array")["result"]);
        REQUIRE(arr["result"].is_array());
        CHECK(arr["result"].size() < 5000);
        CHECK(arr["result"][0] == 0);
        CHECK(arr["_truncated"]["note"].get<std::string>().find("ask for a smaller part") != std::string::npos);

        // Under the cap nothing changes.
        CHECK(result_json(f.call("test_echo_value", {{"value", 3}})["result"]) == Json::object({{"echo", 3}}));
    }
}

TEST_CASE("mcp: set_result_cap never goes below 8 KiB; the default is kMcpResultCap") {
    Fixture f;
    CommandInfo i;
    i.name = "test.sized";
    i.summary = "Returns a string of the given size.";
    i.inputSchema = Json::parse(R"({"type":"object","properties":{"bytes":{"type":"integer"}},"required":["bytes"]})");
    f.registry.add(i, [](const Json& a) { return Json::object({{"s", std::string(a["bytes"].get<std::size_t>(), 'a')}}); });
    // 40 KiB fits the default cap of 80 KiB; 400 KiB does not
    static_assert(kMcpResultCap == 80 * 1024);
    CHECK_FALSE(result_json(f.call("test_sized", {{"bytes", 40 * 1024}})["result"]).contains("_truncated"));
    const Json big = result_json(f.call("test_sized", {{"bytes", 400 * 1024}})["result"]);
    REQUIRE(big.contains("_truncated"));
    CHECK(big.dump().size() <= kMcpResultCap);
    f.server.set_result_cap(10);  // counts as 8 KiB: room for the note and some of the result
    CHECK_FALSE(result_json(f.call("test_sized", {{"bytes", 2000}})["result"]).contains("_truncated"));
    const Json cut = result_json(f.call("test_sized", {{"bytes", 12000}})["result"]);
    REQUIRE(cut.contains("_truncated"));
    CHECK(cut.dump().size() <= 8 * 1024);
    CHECK(cut["s"].get<std::string>().size() > 1000);
}

// ---- Cancellation ----------------------------------------------------------------------------------------------------

namespace {

// test.block runs until its request is cancelled (or 60 s pass: a safety net far above any wait in these tests) and
// says whether it saw the cancel. `started` tells the test when it runs.
struct Blocker {
    std::atomic<bool> started{false};
    std::atomic<bool> sawCancel{false};
    std::atomic<bool> nestedRefused{false};
    void add_to(CommandRegistry& registry) {
        CommandInfo i;
        i.name = "test.block";
        i.summary = "Runs until cancelled.";
        registry.add(i, [this, &registry](const Json&) {
            started = true;
            const auto end = std::chrono::steady_clock::now() + std::chrono::seconds(60);
            while (!command_cancelled() && std::chrono::steady_clock::now() < end)
                std::this_thread::sleep_for(std::chrono::milliseconds(5));
            sawCancel = command_cancelled();
            // a command it calls now is refused: a compound command or an agent stops at its next step
            const CommandResult nested = registry.call("test.echo_value", Json::object({{"value", 1}}));
            nestedRefused = !nested.ok && nested.error["code"] == "cancelled";
            return Json::object({{"finished", true}});
        });
    }
};

bool wait_until(const std::function<bool()>& done) {  // 30 s: far above what a loaded machine needs
    const auto end = std::chrono::steady_clock::now() + std::chrono::seconds(30);
    while (!done()) {
        if (std::chrono::steady_clock::now() > end) return false;
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    return true;
}

std::string cancel_message(const Json& requestId) {
    return Json::object({{"jsonrpc", "2.0"}, {"method", "notifications/cancelled"},
                         {"params", Json::object({{"requestId", requestId}, {"reason", "the user pressed Esc"}})}})
        .dump();
}

}  // namespace

TEST_CASE("mcp: notifications/cancelled stops the running request, which then gets no response") {
    Fixture f;
    Blocker blocker;
    blocker.add_to(f.registry);
    f.initialize();
    std::optional<std::string> response = std::string("not set");
    std::thread caller([&] {
        response = f.server.handle_message(R"({"jsonrpc":"2.0","id":"call-1","method":"tools/call","params":{"name":"test_block","arguments":{}}})");
    });
    REQUIRE(wait_until([&] { return blocker.started.load(); }));
    CHECK(f.server.session()->requests_in_flight() == 1);
    CHECK(McpServer::is_cancel_notification(cancel_message("call-1")));
    CHECK_FALSE(f.server.handle_message(cancel_message("call-1")).has_value());  // a notification: no answer either
    caller.join();
    CHECK(blocker.sawCancel);
    CHECK(blocker.nestedRefused);
    CHECK_FALSE(response.has_value());  // MCP: a cancelled request gets no response
    CHECK(f.server.session()->requests_in_flight() == 0);
    // The server goes on: the same id again is a new request, answered.
    CHECK(f.call("test_echo_value", {{"value", 2}})["result"]["isError"] == false);
}

TEST_CASE("mcp: a cancel for an unknown or finished request is ignored without an error") {
    Fixture f;
    f.initialize();
    CHECK_FALSE(f.server.handle_message(cancel_message(999)).has_value());     // never sent
    const Json done = f.call("test_echo_value", {{"value", 4}});              // answered: id 2
    CHECK_FALSE(f.server.handle_message(cancel_message(done["id"])).has_value());  // too late: nothing to stop
    CHECK(f.server.session()->requests_in_flight() == 0);
    // malformed cancels are notifications too: no answer, nothing breaks
    CHECK_FALSE(f.server.handle_message(R"({"jsonrpc":"2.0","method":"notifications/cancelled","params":{}})").has_value());
    CHECK_FALSE(f.server.handle_message(R"({"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":{"a":1}}})").has_value());
    CHECK_FALSE(McpServer::is_cancel_notification(R"({"jsonrpc":"2.0","id":1,"method":"notifications/cancelled"})"));
    CHECK_FALSE(McpServer::is_cancel_notification("[" + cancel_message(1) + "]"));
    CHECK_FALSE(McpServer::is_cancel_notification(R"({"jsonrpc":2,"method":"notifications/cancelled","params":{"requestId":1}})"));
    // the next call works as usual
    CHECK(result_json(f.call("test_echo_value", {{"value", 5}})["result"])["echo"] == 5);
}

TEST_CASE("mcp: servers that share a session see one handshake and cancel each other's requests") {
    TempDir tmp;
    CommandRegistry registry;
    Blocker blocker;
    blocker.add_to(registry);
    SimpleMcpHost host(registry, tmp.path.string());
    auto session = std::make_shared<McpSession>();
    McpServer first(host);
    first.share_session(session);
    REQUIRE(first.handle_message(R"({"jsonrpc":"2.0","id":0,"method":"initialize","params":{"protocolVersion":"2025-03-26"}})"));
    McpServer second(host);
    second.share_session(session);  // made after the initialize: takes its protocol
    CHECK(second.protocol_version() == "2025-03-26");
    std::optional<std::string> response = std::string("not set");
    std::thread caller([&] {
        response = first.handle_message(R"({"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"test_block","arguments":{}}})");
    });
    REQUIRE(wait_until([&] { return blocker.started.load(); }));
    CHECK_FALSE(second.handle_message(cancel_message(7)).has_value());  // another server of the same client
    caller.join();
    CHECK_FALSE(response.has_value());
    CHECK(blocker.sawCancel);
}

TEST_CASE("mcp: over stdio a cancel is read at once; the other lines keep their order") {
    Fixture f;
    Blocker blocker;
    blocker.add_to(f.registry);
    std::istringstream in(
        "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-06-18\"}}\n"
        "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"test_block\",\"arguments\":{}}}\n"
        "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"ping\"}\n" +
        cancel_message(2) + "\n" +
        "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"test_echo_value\",\"arguments\":{\"value\":6}}}\n");
    std::ostringstream out;
    CHECK(run_stdio(f.server, in, out) == 0);
    std::istringstream lines(out.str());
    std::string line;
    std::vector<Json> msgs;
    while (std::getline(lines, line)) msgs.push_back(Json::parse(line));
    // The cancel is read as soon as it arrives: the call stops if it already runs, or is skipped if it still waits.
    CHECK((blocker.sawCancel || !blocker.started));
    REQUIRE(msgs.size() == 3);  // initialize, ping, the echo: nothing for the cancelled call
    CHECK(msgs[0]["id"] == 1);
    CHECK(msgs[1]["id"] == 3);
    CHECK(msgs[2]["id"] == 4);
    CHECK(result_json(msgs[2]["result"])["echo"] == 6);
}

TEST_CASE("mcp: over stdio a request cancelled while it waits for its turn never runs and gets no answer") {
    Fixture f;
    Blocker blocker;
    blocker.add_to(f.registry);
    std::atomic<bool> recordRan{false};
    CommandInfo info;
    info.name = "test.record";
    info.summary = "Says it ran.";
    f.registry.add(info, [&](const Json&) {
        recordRan = true;
        return Json::object();
    });
    // The reading thread takes the lines in order: request 3 is queued (behind the blocking 2) before its cancel is
    // read, and the cancel of 2, which lets the loop go on, comes after that.
    std::istringstream in(
        "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-06-18\"}}\n"
        "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"test_block\",\"arguments\":{}}}\n"
        "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"test_record\",\"arguments\":{}}}\n" +
        cancel_message(3) + "\n" + cancel_message(2) + "\n" +
        "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"test_echo_value\",\"arguments\":{\"value\":7}}}\n");
    std::ostringstream out;
    CHECK(run_stdio(f.server, in, out) == 0);
    std::istringstream lines(out.str());
    std::string line;
    std::vector<Json> msgs;
    while (std::getline(lines, line)) msgs.push_back(Json::parse(line));
    CHECK_FALSE(recordRan);  // skipped: it was cancelled before its turn
    REQUIRE(msgs.size() == 2);  // initialize and the echo
    CHECK(msgs[0]["id"] == 1);
    CHECK(msgs[1]["id"] == 4);
    CHECK(result_json(msgs[1]["result"])["echo"] == 7);
    CHECK(f.server.session()->requests_queued() == 0);
    CHECK(f.server.session()->requests_in_flight() == 0);
}

namespace {

// Hands out `lines`, then the end of the input once `eofWhen` is true (a timeout before that).
class ScriptedReader final : public LineReader {
public:
    ScriptedReader(std::vector<std::string> lines, std::function<bool()> eofWhen)
        : lines_(std::move(lines)), eofWhen_(std::move(eofWhen)) {}
    Status next(std::string& line, std::chrono::milliseconds timeout) override {
        if (at_ < lines_.size()) {
            line = lines_[at_++];
            return Status::Line;
        }
        if (eofWhen_()) return Status::Eof;
        std::this_thread::sleep_for(std::min(timeout, std::chrono::milliseconds(5)));
        return Status::Timeout;
    }
    bool holds_input() const override { return false; }

private:
    std::vector<std::string> lines_;
    std::size_t at_ = 0;
    std::function<bool()> eofWhen_;
};

}  // namespace

TEST_CASE("mcp: over stdio the end of the input cancels a request still running after the grace") {
    Fixture f;
    Blocker blocker;
    blocker.add_to(f.registry);
    // The input ends while the blocking call runs, with another call queued behind it.
    ScriptedReader reader(
        {R"({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}})",
         R"({"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"test_block","arguments":{}}})",
         R"({"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"test_echo_value","arguments":{"value":1}}})"},
        [&] { return blocker.started.load(); });
    std::ostringstream out;
    StdioLoopOptions options;
    options.eofGrace = std::chrono::milliseconds(200);  // the blocker waits 60 s: only the cancel ends it sooner
    CHECK(run_stdio_loop(f.server, reader, out, options) == StdioExit::Eof);
    CHECK(blocker.sawCancel);
    std::istringstream lines(out.str());
    std::string line;
    std::vector<Json> msgs;
    while (std::getline(lines, line)) msgs.push_back(Json::parse(line));
    REQUIRE(msgs.size() == 1);  // the initialize: the cancelled call and the one queued behind it get no answer
    CHECK(msgs[0]["id"] == 1);
    CHECK(f.server.session()->requests_queued() == 0);
    CHECK(f.server.session()->requests_in_flight() == 0);
}

TEST_CASE("mcp: over stdio a loop that ends within the grace after the input ends cancels nothing") {
    Fixture f;
    std::istringstream in(
        "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-06-18\"}}\n"
        "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"test_echo_value\",\"arguments\":{\"value\":1}}}\n");
    std::ostringstream out;
    CHECK(run_stdio(f.server, in, out) == 0);  // the default grace (10 s) is far above what two quick messages need
    std::istringstream lines(out.str());
    std::string line;
    std::vector<Json> msgs;
    while (std::getline(lines, line)) msgs.push_back(Json::parse(line));
    REQUIRE(msgs.size() == 2);
    CHECK(result_json(msgs[1]["result"])["echo"] == 1);
}

TEST_CASE("mcp: a session keeps a cancel for a queued request until it begins") {
    McpSession session;
    session.expect_request(5);
    session.expect_request("five");
    CHECK(session.requests_queued() == 2);
    CHECK(session.cancel(5));            // queued: kept
    CHECK_FALSE(session.cancel(6));      // unknown: ignored
    auto five = session.begin_request(5);
    CHECK(five->load());                 // starts cancelled
    CHECK(session.end_request(5, five));
    auto other = session.begin_request("five");
    CHECK_FALSE(other->load());          // a string id is another request
    CHECK_FALSE(session.end_request("five", other));
    CHECK(session.requests_queued() == 0);
}

namespace {
void add_cap_tool(Fixture& f, const char* name, CapabilitySet caps, bool readOnly = false, std::shared_ptr<int> ran = nullptr) {
    CommandInfo i;
    i.name = name;
    i.summary = "Capability test command.";
    i.readOnly = readOnly;
    f.registry.add(i, [ran](const Json&) {
        if (ran) ++*ran;
        return Json::object({{"ran", true}});
    });
    REQUIRE(f.registry.declare_capabilities(name, caps));
}

Json tool_annotations(Fixture& f, const std::string& tool) {
    const Json listed = f.rpc("tools/list");  // a named value: a range over a temporary would dangle
    for (const Json& t : listed["result"]["tools"])
        if (t["name"] == tool) return t["annotations"];
    FAIL("tool not listed: " << tool);
    return Json();
}

std::string error_text(const Json& response) { return response["result"]["content"][0]["text"].get<std::string>(); }
}  // namespace

TEST_CASE("mcp: a normal server refuses a writeAnywhere command with capability_denied and a hint that names the CLI") {
    Fixture f;
    auto ran = std::make_shared<int>(0);
    add_cap_tool(f, "test.outside", CapabilitySet{Capability::Read, Capability::WriteAnywhere}, false, ran);
    f.initialize();
    CHECK(f.server.capabilities() == capability_sets::mcp());
    const Json res = f.call("test_outside");
    CHECK(res["result"]["isError"] == true);
    const std::string text = error_text(res);
    CHECK(text.find("capability_denied") != std::string::npos);
    CHECK(text.find("writeAnywhere") != std::string::npos);
    CHECK(text.find("factoria call test.outside") != std::string::npos);
    CHECK(*ran == 0);
}

TEST_CASE("mcp: the read-only server serves the play commands and refuses the rest, listed or not") {
    Fixture f;
    auto stepped = std::make_shared<int>(0), saved = std::make_shared<int>(0), published = std::make_shared<int>(0);
    add_cap_tool(f, "game.step", capability_sets::changes_state(), false, stepped);
    {
        // Like the real game.screenshot: {read, state} by default, and a `path` needs writeProject and stays in the project.
        CommandInfo i;
        i.name = "game.screenshot";
        i.summary = "Screenshot.";
        i.inputSchema = Json::parse(R"({"type":"object","properties":{"path":{"type":"string"}}})");
        f.registry.add(i, [](const Json& a) {
            if (a.contains("path")) resolve_caller_write_path(a["path"].get<std::string>(), "game.screenshot");
            return Json::object({{"ok", true}});
        });
        REQUIRE(f.registry.declare_capabilities("game.screenshot", capability_sets::changes_state()));
    }
    add_cap_tool(f, "scene.save", capability_sets::edits_project(), false, saved);
    add_cap_tool(f, "test.publish", CapabilitySet{Capability::Read, Capability::Publish}, false, published);
    f.server.set_command_filter([](const CommandInfo& info) {
        return info.readOnly || info.name == "game.step" || info.name == "game.screenshot" || info.name == "test.publish";
    });
    f.server.set_capabilities(capability_sets::mcp_read_only());
    f.initialize();

    CHECK(f.call("game_step")["result"]["isError"] == false);
    CHECK(*stepped == 1);
    CHECK(f.call("game_screenshot")["result"]["isError"] == false);
    const Json withPath = f.call("game_screenshot", {{"path", "shots/a.png"}});  // a path needs writeProject: not in {read, state}
    CHECK(withPath["result"]["isError"] == true);
    CHECK(error_text(withPath).find("capability_denied") != std::string::npos);

    const Json unlisted = f.call("scene_save");  // not served: the filter refuses it before any capability check
    CHECK(unlisted["result"]["isError"] == true);
    CHECK(error_text(unlisted).find("tool_not_available") != std::string::npos);
    CHECK(error_text(unlisted).find("factoria call scene.save") != std::string::npos);
    CHECK(*saved == 0);

    const Json denied = f.call("test_publish");  // served, but the set lacks publish
    CHECK(error_text(denied).find("capability_denied") != std::string::npos);
    CHECK(*published == 0);
}

TEST_CASE("mcp: the read-only capability set covers the play commands it serves and nothing dangerous") {
    const CapabilitySet ro = capability_sets::mcp_read_only();
    CHECK(ro == CapabilitySet{Capability::Read, Capability::State});
    CHECK(ro.has_all(capability_sets::changes_state()));
    CHECK_FALSE(ro.has(Capability::WriteProject));
    CHECK_FALSE(ro.has(Capability::WriteAnywhere));
    CHECK_FALSE(ro.has(Capability::Network));
    CHECK_FALSE(ro.has(Capability::Process));
    CHECK_FALSE(ro.has(Capability::Spend));
    CHECK_FALSE(ro.has(Capability::Publish));
}

TEST_CASE("mcp: tool hints come from the capabilities") {
    Fixture f;
    add_cap_tool(f, "scene.save", capability_sets::edits_project());
    add_cap_tool(f, "game.screenshot", capability_sets::changes_state());
    add_cap_tool(f, "test.look", capability_sets::reads(), true);
    add_cap_tool(f, "test.net", CapabilitySet{Capability::Read, Capability::Network});
    add_cap_tool(f, "test.spend", CapabilitySet{Capability::Read, Capability::Spend});
    add_cap_tool(f, "test.edit_memory", capability_sets::changes_state());
    f.initialize();
    auto check = [&](const char* tool, bool readOnly, bool destructive, bool openWorld) {
        const Json a = tool_annotations(f, tool);
        INFO(tool);
        CHECK(a["readOnlyHint"] == readOnly);
        CHECK(a["destructiveHint"] == destructive);
        CHECK(a["openWorldHint"] == openWorld);
    };
    check("scene_save", false, true, false);
    check("game_screenshot", false, false, false);  // {read, state}: its picture goes under .factoria/
    check("test_look", true, false, false);
    check("test_net", false, false, true);
    check("test_spend", false, true, true);
    check("test_edit_memory", false, false, false);
}
