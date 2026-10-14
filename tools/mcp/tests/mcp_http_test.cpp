// The MCP endpoint over loopback HTTP (fa/mcp/http_server.h), as the editor serves it to CLI agents: what it answers,
// and the fake Claude Code of tools/ai/tests/fixtures calling a tool through the config the CLI agent writes for it.
#include <doctest.h>

#include <chrono>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <thread>

#include "fa/ai/cli_agent.h"
#include "fa/ai/http.h"
#include "fa/ai/process.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/mcp/http_server.h"
#include "fa/mcp/server.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

ai::HttpResponse send(const std::string& url, const std::string& body, const std::string& method = "POST") {
    ai::HttpRequest r;
    r.method = method;
    r.url = url;
    r.headers = {{"content-type", "application/json"}, {"accept", "application/json, text/event-stream"}};
    r.body = body;
    r.timeoutSeconds = 20;
    r.connectTimeoutSeconds = 5;
    return ai::http_request(r);
}

// A registry with a stand-in scene.spawn, served the way the editor serves its proxy registry.
struct Endpoint {
    CommandRegistry registry;
    std::vector<std::string> spawned;
    McpHttpServer server;
    std::string url;
    explicit Endpoint(std::chrono::milliseconds streamAfter = std::chrono::seconds(10)) {
        CommandInfo i;
        i.name = "scene.spawn";
        i.summary = "Stand-in: records the name.";
        i.readOnly = false;
        registry.add(i, [this](const Json& a) {
            spawned.push_back(a.value("name", std::string()));
            return Json::object({{"id", spawned.back()}});
        });
        CommandInfo w;
        w.name = "test.wait";
        w.summary = "Stand-in for a long call (ai.run): returns after 300 ms.";
        registry.add(w, [](const Json&) {
            std::this_thread::sleep_for(std::chrono::milliseconds(300));
            return Json::object();
        });
        auto started = server.start([this](std::string_view m) {
            SimpleMcpHost host(registry, ".");
            return McpServer(host).handle_message(m);
        }, streamAfter);
        REQUIRE(started);
        url = *started;
    }
};

std::string read_file(const stdfs::path& p) {
    std::ifstream in(p, std::ios::binary);
    std::stringstream ss;
    ss << in.rdbuf();
    return ss.str();
}

}  // namespace

TEST_CASE("MCP over loopback HTTP: JSON replies, 202 for notifications, 405 for GET, 404 without the token") {
    if (!ai::http_has_libcurl() && ai::which("curl").empty()) {
        MESSAGE("no HTTP client (libcurl or the curl executable); skipped");
        return;
    }
    Endpoint ep;
    CHECK(starts_with(ep.url, "http://127.0.0.1:"));
    CHECK(ep.url.find("/mcp/") != std::string::npos);

    auto init = send(ep.url, R"({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}})");
    CHECK(init.status == 200);
    CHECK(init.header("content-type") == "application/json");
    CHECK(Json::parse(init.body)["result"]["protocolVersion"] == "2025-06-18");
    CHECK(send(ep.url, R"({"jsonrpc":"2.0","method":"notifications/initialized"})").status == 202);

    auto call = send(ep.url, R"({"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"scene_spawn","arguments":{"name":"A"}}})");
    CHECK(call.status == 200);
    REQUIRE(ep.spawned.size() == 1);
    CHECK(ep.spawned[0] == "A");
    CHECK(Json::parse(call.body)["result"]["structuredContent"]["id"] == "A");

    CHECK(send(ep.url, "", "GET").status == 405);  // no server stream: the client goes on without one
    CHECK(send(ep.url.substr(0, ep.url.rfind('/') + 1) + "not-the-token", "{}").status == 404);

    ep.server.stop();
    CHECK(ep.server.url().empty());
    CHECK(send(ep.url, "{}").status == 0);  // nothing listens any more
}

TEST_CASE("MCP over loopback HTTP: a long call is answered as an event stream, a quick one as JSON") {
    if (!ai::http_has_libcurl() && ai::which("curl").empty()) {
        MESSAGE("no HTTP client (libcurl or the curl executable); skipped");
        return;
    }
    Endpoint ep(std::chrono::milliseconds(50));
    auto call = send(ep.url, R"({"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"test_wait","arguments":{}}})");
    CHECK(call.status == 200);
    CHECK(call.header("content-type") == "text/event-stream");
    const std::string event = "event: message\ndata: ";
    const auto at = call.body.find(event);
    INFO("body: " << call.body);
    REQUIRE(at != std::string::npos);
    CHECK(Json::parse(call.body.substr(at + event.size()))["result"]["isError"] == false);

    auto quick = send(ep.url, R"({"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"scene_spawn","arguments":{"name":"B"}}})");
    CHECK(quick.header("content-type") == "application/json");
}

TEST_CASE("a CLI agent given the endpoint runs its tool calls there (fake Claude Code)") {
    if (ai::which("curl").empty()) {
        MESSAGE("the fake CLI calls the endpoint with the curl executable, which is not installed; skipped");
        return;
    }
    Endpoint ep;
    const stdfs::path project = fs::make_temp_dir("fa_mcp_http_cli");
    const stdfs::path argvFile = project / "argv.txt";
    ai::ProviderConfig cc;
    cc.name = "claude-code";
    cc.kind = ai::ProviderKind::ClaudeCode;
#ifdef _WIN32
    cc.command = stdfs::path(FA_AI_FIXTURES "/fake_claude.cmd").make_preferred().string();
#else
    cc.command = FA_AI_FIXTURES "/fake_claude.sh";
#endif
    cc.env["FAKE_MODE"] = "mcp_spawn";
    cc.env["FAKE_ARGV_FILE"] = argvFile.string();
    ai::CliRunRequest req;
    req.prompt = "Add a coin";
    req.projectDir = project.string();
    req.mcpUrl = ep.url;
    auto run = ai::CliAgent(cc).run(req, nullptr, nullptr);
    REQUIRE(run);
    CHECK(run->ok);

    // The MCP config points the CLI at the endpoint, not at a `factoria mcp` process of its own.
    auto cfg = Json::parse(read_file(project / ".factoria" / "ai" / "mcp-claude-code.json"));
    CHECK(cfg["mcpServers"]["factoria"] == Json::object({{"type", "http"}, {"url", ep.url}}));
    // ...and its tool call ran on the endpoint's registry, with the result sent back.
    REQUIRE(ep.spawned.size() == 1);
    CHECK(ep.spawned[0] == "CliCoin");
    const std::string reply = read_file(argvFile.string() + ".mcp");
    INFO("reply: " << reply);
    CHECK(Json::parse(reply)["result"]["isError"] == false);

    ep.server.stop();
    std::error_code ec;
    stdfs::remove_all(project, ec);
}
