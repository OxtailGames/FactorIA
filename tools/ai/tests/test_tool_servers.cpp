// External tool servers (ai.json "mcpServers"): parsing, errors, {key} and ${ENV}, redaction, saving, the prompt, the doctor.
#include <sys/stat.h>

#include "fa/ai/detect.h"
#include "fa/ai/session.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

Json scenario_entry() {
    return Json::parse(R"({
        "type": "http", "url": "https://mcp.scenario.com/mcp",
        "headers": {"Authorization": "Basic {key}"},
        "apiKeyEnv": "SCENARIO_KEY", "note": "AI game art."
    })");
}

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

}  // namespace

TEST_CASE("tool server names: letters, digits, _ and -, never the engine's own server") {
    CHECK(tool_server_name_problem("scenario").empty());
    CHECK(tool_server_name_problem("my_server-2").empty());
    CHECK_FALSE(tool_server_name_problem("").empty());
    CHECK_FALSE(tool_server_name_problem("my server").empty());
    CHECK_FALSE(tool_server_name_problem("a.b").empty());
    CHECK_FALSE(tool_server_name_problem(std::string(kMaxToolServerName + 1, 'a')).empty());
    CHECK(has(tool_server_name_problem("factoria"), "engine's own"));
    auto bad = parse_tool_server(scenario_entry(), "factoria", "/mcpServers/factoria");
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().message, "/mcpServers/factoria"));
    CHECK_FALSE(bad.error().hint.empty());
}

TEST_CASE("parse_tool_server: the transport is inferred, the fields are read") {
    auto http = parse_tool_server(scenario_entry(), "scenario", "/mcpServers/scenario");
    REQUIRE(http.ok());
    CHECK(http->type == "http");
    CHECK(http->url == "https://mcp.scenario.com/mcp");
    REQUIRE(http->headers.size() == 1);
    CHECK(http->headers[0].first == "Authorization");
    CHECK(http->apiKeyEnv == "SCENARIO_KEY");
    CHECK(http->enabled);
    CHECK(http->timeoutSeconds == doctest::Approx(120));

    // no "type": a command means stdio, a url means http
    auto stdio = parse_tool_server(Json::parse(R"({"command":"npx","args":["-y","some-server"],"env":{"A":"b"},
                                                   "roles":["worker","artist"],"enabled":false,"timeoutSeconds":30})"),
                                   "local", "/mcpServers/local");
    REQUIRE(stdio.ok());
    CHECK(stdio->type == "stdio");
    CHECK(stdio->args == std::vector<std::string>{"-y", "some-server"});
    CHECK(stdio->env.at("A") == "b");
    CHECK(stdio->roles == std::vector<std::string>{"worker", "artist"});
    CHECK_FALSE(stdio->enabled);
    CHECK(stdio->timeoutSeconds == doctest::Approx(30));
    auto viaUrl = parse_tool_server(Json::parse(R"({"url":"http://localhost:8080/mcp"})"), "l", "/x");
    REQUIRE(viaUrl.ok());
    CHECK(viaUrl->type == "http");
    // Claude Code's spelling of the transport
    auto streamable = parse_tool_server(Json::parse(R"({"type":"streamable-http","url":"https://a.example/mcp"})"), "s", "/x");
    REQUIRE(streamable.ok());
    CHECK(streamable->type == "http");
}

TEST_CASE("parse_tool_server: errors say where, what is wrong and how to fix it") {
    auto at = [](const char* text) { return parse_tool_server(Json::parse(text), "srv", "/mcpServers/srv"); };

    auto typo = at(R"({"url":"https://a.example/mcp","header":{}})");
    REQUIRE_FALSE(typo.ok());
    CHECK(has(typo.error().message, "/mcpServers/srv/header"));
    CHECK(has(typo.error().message, "unknown property"));
    CHECK(has(typo.error().hint, "headers"));  // did you mean

    auto sse = at(R"({"type":"sse","url":"https://a.example/sse"})");
    REQUIRE_FALSE(sse.ok());
    CHECK(has(sse.error().message, "SSE"));
    CHECK(has(sse.error().hint, "Streamable HTTP"));

    auto nothing = at(R"({"note":"x"})");
    REQUIRE_FALSE(nothing.ok());
    CHECK(has(nothing.error().message, "\"url\""));
    CHECK(has(nothing.error().message, "\"command\""));

    auto notUrl = at(R"({"type":"http","url":"mcp.example.com"})");
    REQUIRE_FALSE(notUrl.ok());
    CHECK(has(notUrl.error().message, "is not a web address"));

    auto both = at(R"({"type":"http","url":"https://a.example/mcp","command":"npx"})");
    REQUIRE_FALSE(both.ok());
    CHECK(has(both.error().message, "/command"));

    auto noCommand = at(R"({"type":"stdio"})");
    REQUIRE_FALSE(noCommand.ok());
    CHECK(has(noCommand.error().message, "/command"));

    auto role = at(R"({"url":"https://a.example/mcp","roles":["wroker"]})");
    REQUIRE_FALSE(role.ok());
    CHECK(has(role.error().message, "/roles/0"));
    CHECK(has(role.error().hint, "worker"));

    auto header = at(R"({"url":"https://a.example/mcp","headers":{"Bad Name":"x"}})");
    REQUIRE_FALSE(header.ok());
    CHECK(has(header.error().message, "not a header name"));

    auto number = at(R"({"command":"x","env":{"PORT":8080}})");
    REQUIRE_FALSE(number.ok());
    CHECK(has(number.error().message, "/env/PORT"));

    auto timeout = at(R"({"url":"https://a.example/mcp","timeoutSeconds":0})");
    REQUIRE_FALSE(timeout.ok());
    CHECK(has(timeout.error().message, "timeoutSeconds"));

    auto notObject = at(R"("https://a.example/mcp")");
    REQUIRE_FALSE(notObject.ok());
    CHECK(has(notObject.error().message, "is an object"));
}

TEST_CASE("parse_tool_server: pasted entries may carry keys this version does not know, they are listed and skipped") {
    std::vector<std::string> ignored;
    auto s = parse_tool_server(Json::parse(R"({"url":"https://a.example/mcp","disabled":true,"alwaysAllow":["x"]})"), "pasted",
                               "/x", &ignored);
    REQUIRE(s.ok());
    CHECK(ignored == std::vector<std::string>{"disabled", "alwaysAllow"});  // in the order of the entry
}

TEST_CASE("parse_tool_servers: the object, or Claude Code's {\"mcpServers\": ...} wrapper") {
    const Json inner = Json::parse(R"({"scenario":{"url":"https://mcp.scenario.com/mcp"},"local":{"command":"node","args":["s.js"]}})");
    auto plain = parse_tool_servers(inner, "/mcpServers");
    REQUIRE(plain.ok());
    REQUIRE(plain->size() == 2);
    CHECK((*plain)[0].name == "scenario");  // in the order of the file
    auto wrapped = parse_tool_servers(Json::object({{"mcpServers", inner}}), "/paste");
    REQUIRE(wrapped.ok());
    CHECK(wrapped->size() == 2);
    // a server that happens to be called "mcpServers" next to others is not a wrapper
    auto notObject = parse_tool_servers(Json::array(), "/mcpServers");
    REQUIRE_FALSE(notObject.ok());
    CHECK(has(notObject.error().message, "one entry per server"));
    auto oneBad = parse_tool_servers(Json::parse(R"({"good":{"command":"x"},"bad name":{"command":"x"}})"), "/mcpServers");
    REQUIRE_FALSE(oneBad.ok());
    CHECK(has(oneBad.error().message, "bad name"));
}

TEST_CASE("resolve_tool_server: {key} comes from the environment first, then the file") {
    auto parsed = parse_tool_server(scenario_entry(), "scenario", "/x");
    REQUIRE(parsed.ok());
    ToolServer s = *parsed;
    auto fromEnv = resolve_tool_server(s, fake_env({{"SCENARIO_KEY", "env-key"}}));
    REQUIRE(fromEnv.ok());
    CHECK(fromEnv->headers[0].second == "Basic env-key");
    CHECK(fromEnv->keySource == "env:SCENARIO_KEY");
    CHECK(fromEnv->usesKey);

    s.apiKey = "file-key";
    auto both = resolve_tool_server(s, fake_env({{"SCENARIO_KEY", "env-key"}}));
    REQUIRE(both.ok());
    CHECK(both->headers[0].second == "Basic env-key");  // the environment wins
    auto fromFile = resolve_tool_server(s, fake_env({}));
    REQUIRE(fromFile.ok());
    CHECK(fromFile->headers[0].second == "Basic file-key");
    CHECK(fromFile->keySource == "config");

    s.apiKey.clear();
    auto missing = resolve_tool_server(s, fake_env({}));
    REQUIRE_FALSE(missing.ok());
    CHECK(has(missing.error().message, "{key}"));
    CHECK(has(missing.error().message, "header 'Authorization'"));
    CHECK(has(missing.error().hint, "SCENARIO_KEY"));
}

TEST_CASE("resolve_tool_server: ${NAME} and ${NAME:-default} in headers, args and env; nothing secret in the errors") {
    ToolServer s;
    s.name = "local";
    s.type = "stdio";
    s.command = "node";
    s.args = {"--root", "${PROJECT_ROOT:-/tmp/none}", "--token=${LOCAL_TOKEN}"};
    s.env = {{"API_TOKEN", "${LOCAL_TOKEN}"}, {"PLAIN", "x"}};
    auto ok = resolve_tool_server(s, fake_env({{"LOCAL_TOKEN", "tok-123"}}));
    REQUIRE(ok.ok());
    CHECK(ok->args == std::vector<std::string>{"--root", "/tmp/none", "--token=tok-123"});
    CHECK(ok->env.at("API_TOKEN") == "tok-123");
    CHECK_FALSE(ok->usesKey);
    CHECK(ok->keySource.empty());
    auto set = resolve_tool_server(s, fake_env({{"LOCAL_TOKEN", "t"}, {"PROJECT_ROOT", "/p"}}));
    REQUIRE(set.ok());
    CHECK(set->args[1] == "/p");

    auto missing = resolve_tool_server(s, fake_env({{"OTHER_SECRET", "must-not-appear"}}));
    REQUIRE_FALSE(missing.ok());
    CHECK(has(missing.error().message, "${LOCAL_TOKEN}"));
    CHECK(has(missing.error().message, "argument 3"));
    CHECK_FALSE(has(missing.error().message + missing.error().hint, "must-not-appear"));
}

TEST_CASE("keys are redacted when the config is shown, kept when it is written") {
    auto parsed = parse_tool_server(Json::parse(R"({"url":"https://a.example/mcp","apiKey":"secret-key-1",
        "headers":{"Authorization":"Basic aGFyZGNvZGVk","Accept":"text/plain","X-Api-Key":"{key}"},
        "command":"","env":{}})"),
                                    "srv", "/x");
    REQUIRE(parsed.ok());
    const Json shown = tool_server_to_json(*parsed, true);
    CHECK(shown["apiKey"] == "***");
    CHECK(shown["headers"]["Authorization"] == "***");  // a secret written out in full
    CHECK(shown["headers"]["Accept"] == "text/plain");
    CHECK(shown["headers"]["X-Api-Key"] == "{key}");    // a reference is not a secret
    CHECK_FALSE(has(shown.dump(), "secret-key-1"));
    CHECK_FALSE(has(shown.dump(), "aGFyZGNvZGVk"));
    const Json written = tool_server_to_json(*parsed, false);
    CHECK(written["apiKey"] == "secret-key-1");
    CHECK(written["headers"]["Authorization"] == "Basic aGFyZGNvZGVk");

    AiConfig cfg = default_config();
    cfg.toolServers.push_back(*parsed);
    CHECK_FALSE(has(config_to_json(cfg, true).dump(), "secret-key-1"));
    CHECK(has(config_to_json(cfg, false).dump(), "secret-key-1"));
}

TEST_CASE("serves_role: the roles that build the game by default, review roles only when listed, off serves nobody") {
    ToolServer s;
    s.name = "x";
    for (const char* r : {"orchestrator", "worker", "fast", "artist", "audio"}) CHECK_MESSAGE(s.serves_role(r), r);
    CHECK_FALSE(s.serves_role("artCritic"));
    CHECK_FALSE(s.serves_role("reviewer"));
    s.roles = {"reviewer"};
    CHECK(s.serves_role("reviewer"));
    CHECK_FALSE(s.serves_role("worker"));
    s.enabled = false;
    CHECK_FALSE(s.serves_role("reviewer"));
}

TEST_CASE("an ai.json with mcpServers loads, validates against the schema and round-trips") {
    const Json file = Json::parse(R"({"mcpServers":{
        "scenario":{"type":"http","url":"https://mcp.scenario.com/mcp","headers":{"Authorization":"Basic {key}"},
                    "apiKeyEnv":"SCENARIO_KEY","note":"AI game art.","roles":["artist"],"timeoutSeconds":300},
        "local":{"command":"npx","args":["-y","x"],"env":{"A":"${B:-c}"}}}})");
    CHECK(validate_config_json(file).empty());
    auto cfg = parse_config(file, "test.json");
    REQUIRE(cfg.ok());
    REQUIRE(cfg->toolServers.size() == 2);
    CHECK(cfg->tool_servers_for("artist").size() == 2);
    REQUIRE(cfg->tool_servers_for("worker").size() == 1);  // scenario lists only the artist
    CHECK(cfg->tool_servers_for("worker")[0]->name == "local");
    CHECK(cfg->tool_servers_for("reviewer").empty());

    // a typo is reported with its pointer
    const Json typo = Json::parse(R"({"mcpServers":{"scenario":{"url":"https://a.example/mcp","apiKeyEnvv":"X"}}})");
    CHECK_FALSE(validate_config_json(typo).empty());
    auto bad = parse_config(typo, "bad.json");
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().message, "bad.json"));
    CHECK(has(bad.error().message, "/mcpServers/scenario/apiKeyEnvv"));

    auto again = parse_config(config_to_json(*cfg, false), "again.json");
    REQUIRE(again.ok());
    CHECK(config_to_json(*again, false)["mcpServers"] == config_to_json(*cfg, false)["mcpServers"]);
}

TEST_CASE("plain http to another computer with a key warns, localhost and https do not") {
    auto warnings = [](const char* url) {
        Json j = Json::object({{"mcpServers", Json::object({{"s", Json::object({{"url", url}, {"apiKey", "k"}})}})}});
        auto cfg = parse_config(j, "w.json");
        REQUIRE(cfg.ok());
        return cfg->warnings;
    };
    CHECK(warnings("http://tools.example.com/mcp").size() == 1);
    CHECK(warnings("http://localhost:8080/mcp").empty());
    CHECK(warnings("http://127.0.0.1:8080/mcp").empty());
    CHECK(warnings("https://tools.example.com/mcp").empty());
}

TEST_CASE("save_tool_servers: only mcpServers changes, the file stays private, bad input is refused") {
    TempDir dir;
    const std::string path = (dir.path / "ai.json").string();
    std::ofstream(path) << R"({"defaultProvider":"claude-code","limits":{"maxTurns":7}})";
    auto parsed = parse_tool_server(scenario_entry(), "scenario", "/x");
    REQUIRE(parsed.ok());
    parsed->apiKey = "file-key-77";

    REQUIRE(save_tool_servers({*parsed}, path).ok());
    Json saved = Json::parse(read_file(path));
    CHECK(saved["defaultProvider"] == "claude-code");
    CHECK(saved["limits"]["maxTurns"] == 7);
    CHECK(saved["mcpServers"]["scenario"]["apiKey"] == "file-key-77");
    CHECK(validate_config_json(saved).empty());
#ifndef _WIN32
    struct stat st{};
    REQUIRE(stat(path.c_str(), &st) == 0);
    CHECK((st.st_mode & (S_IRWXG | S_IRWXO)) == 0);
#endif
    auto loaded = load_config(path, fake_env({}));
    REQUIRE(loaded.ok());
    REQUIRE(loaded->toolServers.size() == 1);
    CHECK(loaded->toolServers[0].apiKey == "file-key-77");

    ToolServer clash = *parsed;
    CHECK_FALSE(save_tool_servers({*parsed, clash}, path).ok());
    ToolServer renamed = *parsed;
    renamed.name = "bad name";
    auto badName = save_tool_servers({renamed}, path);
    REQUIRE_FALSE(badName.ok());
    CHECK(has(badName.error().message, "bad name"));
    CHECK(Json::parse(read_file(path))["mcpServers"].contains("scenario"));  // the failed saves left the file alone

    REQUIRE(save_tool_servers({}, path).ok());
    saved = Json::parse(read_file(path));
    CHECK_FALSE(saved.contains("mcpServers"));
    CHECK(saved["limits"]["maxTurns"] == 7);

    const std::string notJson = (dir.path / "broken.json").string();
    std::ofstream(notJson) << "[1,2]";
    CHECK_FALSE(save_tool_servers({*parsed}, notJson).ok());
    CHECK(read_file(notJson) == "[1,2]");
}

TEST_CASE("external_tools_prompt: each server with its note and how its tools are named; the read-only variant brings nothing in") {
    CHECK(external_tools_prompt({}).empty());
    const std::vector<ToolServerBrief> servers = {{"scenario", "AI game art: sprites, textures.", "mcp__scenario__"},
                                                  {"local", "", ""}};
    const std::string p = external_tools_prompt(servers);
    CHECK(has(p, "External tools"));
    CHECK(has(p, "scenario"));
    CHECK(has(p, "AI game art: sprites, textures."));
    CHECK(has(p, "mcp__scenario__"));
    CHECK(has(p, "assets_import"));
    CHECK(has(p, "credits"));
    const std::string ro = external_tools_prompt(servers, true);
    CHECK_FALSE(ro.empty());
    CHECK_FALSE(has(ro, "assets_import"));

    PromptContext ctx;
    ctx.projectDir = "/p";
    ctx.role = "worker";
    CHECK_FALSE(has(build_system_prompt(ctx), "External tools"));
    ctx.toolServers = servers;
    CHECK(has(build_system_prompt(ctx), "External tools"));
}

TEST_CASE("doctor: the tool servers are listed with where the key comes from, never the key") {
    AiConfig cfg = default_config();
    cfg.toolServers.push_back(*parse_tool_server(scenario_entry(), "scenario", "/x"));
    cfg.toolServers.push_back(*parse_tool_server(Json::parse(R"({"command":"npx","args":["a"],"enabled":false})"), "off", "/x"));

    const auto ready = tool_server_statuses(cfg, fake_env({{"SCENARIO_KEY", "very-secret"}}));
    REQUIRE(ready.size() == 2);
    CHECK(ready[1].name == "off");
    CHECK_FALSE(ready[1].enabled);
    CHECK(ready[0].problem.empty());
    CHECK(ready[0].keySource == "env:SCENARIO_KEY");
    CHECK(ready[0].roles.size() == 5);
    CHECK_FALSE(has(ready[0].to_json().dump(), "very-secret"));
    const std::string report = format_doctor_report(cfg, {}, fake_env({{"SCENARIO_KEY", "very-secret"}}));
    CHECK(has(report, "External tool servers"));
    CHECK(has(report, "[ok]   scenario (http): https://mcp.scenario.com/mcp"));
    CHECK(has(report, "[key from env:SCENARIO_KEY]"));
    CHECK(has(report, "[off]  off (stdio): npx"));
    CHECK_FALSE(has(report, "very-secret"));

    const auto missing = tool_server_statuses(cfg, fake_env({}));
    CHECK_FALSE(missing[0].problem.empty());
    const std::string bad = format_doctor_report(cfg, {}, fake_env({}));
    CHECK(has(bad, "[--]   scenario"));
    CHECK(has(bad, "SCENARIO_KEY"));

    AiConfig none = default_config();
    CHECK(has(format_doctor_report(none, {}, fake_env({})), "none configured: add \"mcpServers\""));
}

TEST_CASE("a key in the URL's query string stays out of the status") {
    AiConfig cfg = default_config();
    cfg.toolServers.push_back(*parse_tool_server(Json::parse(R"({"url":"https://a.example/mcp?token=hunter2"})"), "q", "/x"));
    const auto st = tool_server_statuses(cfg, fake_env({}));
    REQUIRE(st.size() == 1);
    CHECK(st[0].target == "https://a.example/mcp");
    CHECK_FALSE(has(format_doctor_report(cfg, {}, fake_env({})), "hunter2"));
}
