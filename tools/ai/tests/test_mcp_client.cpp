// The MCP client the built-in agent uses for the user's tool servers: Streamable HTTP against a fake server, stdio against
// the fake_mcp_server program (ctest sets FA_FAKE_MCP_SERVER), and the tool set the agent sees.
#include <cstdlib>

#include "fa/ai/mcp_client.h"
#include "fake_mcp_http.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;


TEST_CASE("mcp_tool_def_name: <server>__<tool>, characters a model API accepts, 64 at most, long names stay different") {
    CHECK(mcp_tool_def_name("scenario", "generate_image") == "scenario__generate_image");
    CHECK(mcp_tool_def_name("scenario", "generate image.v2") == "scenario__generate_image_v2");
    const std::string a = mcp_tool_def_name("srv", std::string(100, 'a') + "1");
    const std::string b = mcp_tool_def_name("srv", std::string(100, 'a') + "2");
    CHECK(a.size() <= 64);
    CHECK(b.size() <= 64);
    CHECK(a != b);
    CHECK(a == mcp_tool_def_name("srv", std::string(100, 'a') + "1"));  // stable
}

TEST_CASE("mcp http: initialize, tools/list (paged), headers, session id, tool calls, closing the session") {
    FakeHttpServer server;
    server.pages = 2;
    {
        McpOptions options;
        options.transport = server.transport();
        auto client = McpClient::connect(http_server(), options);
        REQUIRE_MESSAGE(client.ok(), client.error().to_string());
        CHECK((*client)->server_description() == "Fake Scenario 1.2.0");
        REQUIRE((*client)->tools().size() == 3);  // two on page 0, one on page 1
        CHECK((*client)->tools()[0].name == "tool_0");
        CHECK((*client)->tools()[1].name == "generate image");
        CHECK((*client)->tools()[1].inputSchema["type"] == "object");  // a missing schema becomes an empty object schema

        // the first request is initialize, with the configured header and the content negotiation of Streamable HTTP
        REQUIRE(server.requests.size() >= 3);
        const HttpRequest& init = server.requests[0];
        CHECK(init.url == "https://mcp.example.com/mcp");
        CHECK(header_of(init, "Authorization") == "Basic c2VjcmV0");
        CHECK(has(header_of(init, "Accept"), "text/event-stream"));
        CHECK(Json::parse(init.body)["method"] == "initialize");
        CHECK(Json::parse(init.body)["params"]["clientInfo"]["name"] == "factoria");
        CHECK(header_of(init, "Mcp-Session-Id").empty());
        // everything after it carries the session the server handed out
        for (std::size_t i = 1; i < server.requests.size(); ++i)
            CHECK_MESSAGE(header_of(server.requests[i], "Mcp-Session-Id") == "sess-1-1", i);
        CHECK(Json::parse(server.requests[1].body)["method"] == "notifications/initialized");

        auto call = (*client)->call_tool("tool_0", Json::object({{"prompt", "a coin"}}));
        REQUIRE_MESSAGE(call.ok(), call.error().to_string());
        CHECK_FALSE(call->isError);
        CHECK(call->text == "called tool_0 with {\"prompt\":\"a coin\"}");

        auto failing = (*client)->call_tool("failing", Json::object());
        REQUIRE(failing.ok());  // the tool ran: a result, flagged
        CHECK(failing->isError);
        CHECK(failing->text == "no credits left");

        auto picture = (*client)->call_tool("picture", Json::object());
        REQUIRE(picture.ok());
        REQUIRE(picture->images.size() == 1);  // png; the tiff is not something a model can look at
        CHECK(picture->images[0].mediaType == "image/png");
        CHECK(has(picture->text, "image/tiff"));
        CHECK(has(picture->text, "https://cdn.example/a.png"));

        auto structured = (*client)->call_tool("structured", Json::object());
        REQUIRE(structured.ok());
        CHECK(structured->text == "{\"id\":7}");

        auto unknown = (*client)->call_tool("nope", Json::object());
        REQUIRE_FALSE(unknown.ok());
        CHECK(has(unknown.error().message, "scenario"));
        CHECK(has(unknown.error().message, "Unknown tool nope"));
    }
    CHECK(server.deletes == 1);  // the session ended with the client
}

TEST_CASE("mcp http: the answer may be a Server-Sent Events stream") {
    FakeHttpServer server;
    server.sse = true;
    McpOptions options;
    options.transport = server.transport();
    auto client = McpClient::connect(http_server(), options);
    REQUIRE_MESSAGE(client.ok(), client.error().to_string());
    CHECK((*client)->tools().size() == 2);
    auto call = (*client)->call_tool("tool_0", Json::object());
    REQUIRE(call.ok());
    CHECK(has(call->text, "called tool_0"));
}

TEST_CASE("mcp http: a server without sessions works, a forgotten session starts a new one") {
    {
        FakeHttpServer server;
        server.sendSessionId = false;
        McpOptions options;
        options.transport = server.transport();
        auto client = McpClient::connect(http_server(), options);
        REQUIRE(client.ok());
        for (const auto& r : server.requests) CHECK(header_of(r, "Mcp-Session-Id").empty());
        CHECK((*client)->call_tool("tool_0", Json::object()).ok());
    }
    FakeHttpServer server;
    McpOptions options;
    options.transport = server.transport();
    auto client = McpClient::connect(http_server(), options);
    REQUIRE(client.ok());
    server.forgetSessionOnce = true;
    auto call = (*client)->call_tool("tool_0", Json::object());
    REQUIRE_MESSAGE(call.ok(), call.error().to_string());
    CHECK(server.initializes == 2);
    CHECK(header_of(server.requests.back(), "Mcp-Session-Id") == "sess-1-2");
}

TEST_CASE("mcp http: refused credentials, OAuth servers, wrong address and unreachable hosts teach what to do") {
    FakeHttpServer server;
    server.status = 401;
    McpOptions options;
    options.transport = server.transport();
    auto denied = McpClient::connect(http_server(), options);
    REQUIRE_FALSE(denied.ok());
    CHECK(has(denied.error().message, "Tool server 'scenario'"));
    CHECK(has(denied.error().message, "401"));
    CHECK(has(denied.error().hint, "Check the key"));
    CHECK_FALSE(has(denied.error().hint, "OAuth"));
    // the key itself is never in an error
    CHECK_FALSE(has(denied.error().message + denied.error().hint, "c2VjcmV0"));

    server.wwwAuthenticate = "Bearer resource_metadata=\"https://mcp.example.com/.well-known/oauth-protected-resource\"";
    auto oauth = McpClient::connect(http_server(), options);
    REQUIRE_FALSE(oauth.ok());
    CHECK(has(oauth.error().hint, "OAuth"));
    CHECK(has(oauth.error().hint, "Claude Code"));

    server.status = 404;
    auto missing = McpClient::connect(http_server(), options);
    REQUIRE_FALSE(missing.ok());
    CHECK(has(missing.error().message, "HTTP 404"));
    CHECK(has(missing.error().hint, "/mcp"));

    McpOptions down;
    down.transport = [](const HttpRequest&) {
        HttpResponse r;
        r.error = "Could not resolve host";
        return r;
    };
    auto unreachable = McpClient::connect(http_server(), down);
    REQUIRE_FALSE(unreachable.ok());
    CHECK(has(unreachable.error().message, "cannot reach https://mcp.example.com/mcp"));
    CHECK(has(unreachable.error().message, "Could not resolve host"));

    McpOptions notMcp;
    notMcp.transport = [](const HttpRequest&) {
        HttpResponse r;
        r.status = 200;
        r.headers["content-type"] = "text/html";
        r.body = "<html>hello</html>";
        return r;
    };
    auto html = McpClient::connect(http_server(), notMcp);
    REQUIRE_FALSE(html.ok());
    CHECK(has(html.error().message, "not an MCP reply"));
}

TEST_CASE("mcp http: a cancelled call stops") {
    FakeHttpServer server;
    McpOptions options;
    CancelFlag cancel{false};
    options.cancel = &cancel;
    options.transport = server.transport();
    auto client = McpClient::connect(http_server(), options);
    REQUIRE(client.ok());
    cancel = true;
    auto call = (*client)->call_tool("tool_0", Json::object());
    REQUIRE_FALSE(call.ok());
    CHECK(has(call.error().message, "cancelled"));
}

TEST_CASE("McpToolSet: tools named <server>__<tool>, sorted, routed to their server; failing servers only give a note") {
    FakeHttpServer server;
    ToolServer good;
    good.name = "scenario";
    good.type = "http";
    good.url = "https://mcp.example.com/mcp";
    good.headers = {{"Authorization", "Basic {key}"}};
    good.apiKeyEnv = "SCENARIO_KEY";
    ToolServer noKey = good;
    noKey.name = "needskey";
    noKey.apiKeyEnv = "OTHER_KEY";
    ToolServer broken = good;
    broken.name = "broken";
    broken.url = "https://down.example.com/mcp";

    McpToolSet set;
    McpOptions options;
    options.transport = [&](const HttpRequest& r) {
        if (r.url.find("down.example.com") != std::string::npos) {
            HttpResponse down;
            down.error = "connection refused";
            return down;
        }
        return server.handle(r);
    };
    std::vector<std::string> notes;
    set.connect({&good, &noKey, &broken}, fake_env({{"SCENARIO_KEY", "k1"}}), options, notes);
    REQUIRE(notes.size() == 3);
    CHECK(has(notes[0], "'scenario' connected: 2 tools"));
    CHECK(has(notes[1], "'needskey' skipped"));
    CHECK(has(notes[1], "OTHER_KEY"));
    CHECK(has(notes[2], "'broken' not available"));
    CHECK(has(notes[2], "connection refused"));
    CHECK_FALSE(has(notes[0] + notes[1] + notes[2], "k1"));
    CHECK(header_of(server.requests[0], "Authorization") == "Basic k1");

    CHECK_FALSE(set.empty());
    const auto defs = set.tool_defs();
    REQUIRE(defs.size() == 2);
    CHECK(defs[0].name == "scenario__generate_image");  // "generate image" reduced to the allowed characters
    CHECK(defs[1].name == "scenario__tool_0");
    CHECK(has(defs[1].description, "tool server 'scenario'"));
    CHECK(set.owns("scenario__tool_0"));
    CHECK_FALSE(set.owns("scene_list_entities"));

    ToolCall call;
    call.id = "t1";
    call.name = "scenario__tool_0";
    call.input = Json::object({{"n", 1}});
    ToolResult r = set.call(call);
    CHECK(r.toolUseId == "t1");
    CHECK_FALSE(r.isError);
    CHECK(has(r.content, "called tool_0"));

    call.name = "scenario__generate_image";  // the server knows it as "generate image": the call reaches it with that name
    r = set.call(call);
    CHECK(r.isError);
    CHECK(has(r.content, "Unknown tool generate image"));

    call.name = "nobody__x";
    r = set.call(call);
    CHECK(r.isError);
}

#ifndef _WIN32

namespace {

std::string fake_server_path() {
    const char* p = std::getenv("FA_FAKE_MCP_SERVER");
    return p ? p : "";
}

ResolvedToolServer stdio_server(const std::string& exe) {
    ResolvedToolServer s;
    s.name = "local";
    s.type = "stdio";
    s.command = exe;
    s.timeoutSeconds = 20;
    return s;
}

}  // namespace

TEST_CASE("mcp stdio: a local program is started, listed, called and ended with the client") {
    const std::string exe = fake_server_path();
    if (exe.empty()) return;  // run by hand without ctest: the program's path is unknown
    ResolvedToolServer server = stdio_server(exe);
    server.env = {{"FA_MCP_TEST_VALUE", "from the server entry"}};
    auto client = McpClient::connect(server);
    REQUIRE_MESSAGE(client.ok(), client.error().to_string());
    CHECK((*client)->server_description() == "FakeStdio 0.1");
    CHECK((*client)->tools().size() == 7);

    auto echo = (*client)->call_tool("echo", Json::object({{"text", "hi"}}));
    REQUIRE(echo.ok());
    CHECK(echo->text == "echo: hi");
    auto env = (*client)->call_tool("env", Json::object({{"name", "FA_MCP_TEST_VALUE"}}));
    REQUIRE(env.ok());
    CHECK(env->text == "from the server entry");
    auto fail = (*client)->call_tool("fail", Json::object());
    REQUIRE(fail.ok());
    CHECK(fail->isError);
    auto image = (*client)->call_tool("image", Json::object());
    REQUIRE(image.ok());
    CHECK(image->images.size() == 1);
    CHECK(image->text == "here is the picture");
    auto ping = (*client)->call_tool("ping_first", Json::object());  // the server asks a ping before it answers
    REQUIRE(ping.ok());
    CHECK(ping->text == "pinged");
    auto big = (*client)->call_tool("big", Json::object());
    REQUIRE(big.ok());
    CHECK(big->text.size() < 100100);
    CHECK(has(big->text, "result cut at 100000 characters"));
    auto unknown = (*client)->call_tool("nope", Json::object());
    REQUIRE_FALSE(unknown.ok());
    CHECK(has(unknown.error().message, "Unknown tool: nope"));
}

TEST_CASE("mcp stdio: a program that dies mid-call is an error that says so, not a hang") {
    const std::string exe = fake_server_path();
    if (exe.empty()) return;
    auto client = McpClient::connect(stdio_server(exe));
    REQUIRE(client.ok());
    auto crash = (*client)->call_tool("crash", Json::object());
    REQUIRE_FALSE(crash.ok());
    CHECK(has(crash.error().message, "Tool server 'local'"));
    CHECK(has(crash.error().message, "exited"));
    auto after = (*client)->call_tool("echo", Json::object());
    REQUIRE_FALSE(after.ok());  // and it stays dead
    CHECK(has(after.error().message, "exited"));
}

TEST_CASE("mcp stdio: a program that is not there is an error with a hint") {
    ResolvedToolServer s = stdio_server("fa-no-such-mcp-program-for-the-test");
    auto client = McpClient::connect(s);
    REQUIRE_FALSE(client.ok());
    CHECK(has(client.error().message, "Tool server 'local'"));
    CHECK(has(client.error().message, "fa-no-such-mcp-program-for-the-test"));
    CHECK_FALSE(client.error().hint.empty());
}

TEST_CASE("mcp stdio: a call that never answers times out") {
    // `sleep` reads nothing and says nothing: initialize waits until the connect timeout.
    ResolvedToolServer silent = stdio_server("sleep");
    silent.args = {"30"};
    McpOptions options;
    options.connectTimeoutSeconds = 0.5;
    auto client = McpClient::connect(silent, options);
    REQUIRE_FALSE(client.ok());
    CHECK(has(client.error().message, "timed out"));
    CHECK(has(client.error().hint, "timeoutSeconds"));
}

#endif
