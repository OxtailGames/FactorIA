// ai.settings.get / ai.settings.set: every scope, that set never accepts a project's file (ai-trust.json is not written), unknown
// pointers, rejected keys, and that ai.run and agent_delegate honour a role the project turned off and say which setting did.
#include <fstream>

#include "fa/ai/commands.h"
#include "fa/ai/extensions.h"
#include "fa/ai/project_settings.h"
#include "fa/core/fs.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;
namespace fsys = std::filesystem;

namespace {

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

void write_file(const fsys::path& path, const std::string& text) {
    fsys::create_directories(path.parent_path());
    std::ofstream(path, std::ios::binary) << text;
}

// A user's ai.json in its own folder (never the real ~/.factoria) and a project next to it.
struct World {
    TempDir home, proj;
    std::string ai;
    CommandRegistry reg = make_registry();
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    World() {
        ai = (home.path / "ai.json").string();
        write_file(ai, R"({
          "providers": {"openrouter": {"type": "openai-compatible", "preset": "openrouter", "apiKeyEnv": "OPENROUTER_API_KEY"}},
          "roles": {"orchestrator": {"provider": "claude-code", "model": "opus"}},
          "limits": {"maxTurns": 30},
          "mcpServers": {"scenario": {"type": "http", "url": "https://mcp.example.com/mcp"}}
        })");
        write_file(proj.path / "factoria.json", R"({"name":"g"})");
        AiCommandOptions opt;
        opt.aiConfigPath = ai;
        opt.runtime.env = fake_env({});
        opt.projectDir = [this] { return proj.str(); };
        opt.providerFactory = [this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        };
        register_ai_commands(reg, opt);
    }
    std::string settings_file() const { return (proj.path / ".factoria" / "ai" / "settings.json").string(); }
    std::string trust_file() const { return extensions_trust_path(ai); }
    CommandResult get(const char* scope) { return reg.call("ai.settings.get", Json::object({{"scope", scope}})); }
    CommandResult set(const char* scope, const std::string& pointer, Json value) {
        return reg.call("ai.settings.set", Json::object({{"scope", scope}, {"pointer", pointer}, {"value", value}}));
    }
};

Json value_row(const Json& values, const std::string& pointer) {
    for (const Json& v : values)
        if (v["pointer"] == pointer) return v;
    return Json(nullptr);
}

}  // namespace

TEST_CASE("ai.settings.get: resolved shows each value with where it comes from, project and user show their own file") {
    World w;
    auto r = w.get("resolved");
    REQUIRE(r.ok);
    CHECK(r.result["project"] == w.proj.str());
    CHECK_FALSE(r.result.contains("projectSettings"));  // the project has no file
    CHECK(value_row(r.result["values"], "/limits/maxTurns")["source"] == "you");
    CHECK(value_row(r.result["values"], "/limits/maxTurns")["value"] == 30);
    CHECK(value_row(r.result["values"], "/roles/artist/enabled")["source"] == "default");

    // a project file that was saved on this computer applies; every value says where it comes from
    REQUIRE(save_project_settings(w.proj.str(), Json::parse(R"({"roles":{"artist":{"enabled":false}},"limits":{"maxTurns":5}})"), w.ai,
                                  fake_env({}), true));
    r = w.get("resolved");
    REQUIRE(r.ok);
    CHECK(value_row(r.result["values"], "/roles/artist/enabled")["source"] == "project");
    CHECK(value_row(r.result["values"], "/roles/artist/enabled")["value"] == false);
    CHECK(value_row(r.result["values"], "/limits/maxTurns")["source"] == "project");
    CHECK(value_row(r.result["values"], "/limits/maxTurns")["value"] == 5);
    CHECK(value_row(r.result["values"], "/limits/maxCostUsd")["source"] == "default");
    CHECK(r.result["projectSettings"]["applied"] == true);

    auto p = w.get("project");
    REQUIRE(p.ok);
    CHECK(p.result["exists"] == true);
    CHECK(p.result["overrides"]["limits"]["maxTurns"] == 5);
    CHECK(p.result["pendingTrust"] == false);
    CHECK(p.result["file"] == w.settings_file());

    // the user's view ignores the project
    auto u = w.get("user");
    REQUIRE(u.ok);
    CHECK(u.result["configPath"] == w.ai);
    CHECK(u.result["configFound"] == true);
    CHECK(value_row(u.result["values"], "/limits/maxTurns")["value"] == 30);
    CHECK(value_row(u.result["values"], "/limits/maxTurns")["source"] == "you");
    CHECK(value_row(u.result["values"], "/roles/artist/enabled")["source"] == "default");
}

TEST_CASE("ai.settings.get: a project file nobody accepted is pending, an invalid one is reported and has no effect") {
    World w;
    write_file(w.settings_file(), R"({"roles":{"artist":{"enabled":false}}})");  // as if it came inside a copied project
    auto p = w.get("project");
    REQUIRE(p.ok);
    CHECK(p.result["pendingTrust"] == true);
    CHECK(p.result["applied"] == false);
    REQUIRE(p.result["pending"].size() == 1);
    CHECK(p.result["pending"][0]["pointer"] == "/roles/artist/enabled");
    CHECK(has(p.result["hint"], "accepts it once"));
    auto r = w.get("resolved");
    REQUIRE(r.ok);
    CHECK(value_row(r.result["values"], "/roles/artist/enabled")["value"] == true);  // no effect yet
    CHECK(r.result["projectSettings"]["pendingTrust"] == true);

    write_file(w.settings_file(), R"({"providers":{"x":{"command":"rm"}}})");
    p = w.get("project");
    REQUIRE(p.ok);
    CHECK(p.result.contains("invalidError"));
    CHECK(has(p.result["invalidError"]["message"], "not allowed"));
    CHECK(p.result["pending"].empty());
    CHECK(w.get("resolved").ok);  // an unaccepted invalid file never stops the project

    fsys::remove(w.settings_file());
    CHECK(w.get("project").result["exists"] == false);
}

TEST_CASE("ai.settings.get: no project") {
    World w;
    fsys::remove(w.proj.path / "factoria.json");
    auto p = w.get("project");
    REQUIRE_FALSE(p.ok);
    CHECK(p.error["code"] == "no_project");
    auto r = w.get("resolved");
    REQUIRE(r.ok);
    CHECK(r.result["project"].is_null());
    CHECK(w.get("user").ok);
    auto s = w.set("project", "/roles/artist/enabled", false);
    REQUIRE_FALSE(s.ok);
    CHECK(s.error["code"] == "no_project");
}

TEST_CASE("ai.settings.set project: writes the file but never accepts it (ai-trust.json is not written)") {
    World w;
    auto s = w.set("project", "/roles/artist/enabled", false);
    REQUIRE(s.ok);
    CHECK(s.result["needsAcceptance"] == true);
    CHECK(s.result["applied"] == false);
    CHECK(s.result["value"] == false);
    CHECK(s.result["runsWith"] == true);  // the project still runs with the user's settings
    CHECK(has(s.result["hint"], "NOT applied"));
    CHECK(has(s.result["hint"], "accepts"));
    CHECK(fsys::exists(w.settings_file()));
    CHECK_FALSE(fsys::exists(w.trust_file()));
    auto file = fa::parse_json(*fa::fs::read_text(w.settings_file()), "f");
    REQUIRE(file);
    CHECK((*file)["roles"]["artist"]["enabled"] == false);

    // more values: still pending, still no trust file; an array value for a site list
    REQUIRE(w.set("project", "/limits/maxCostUsd", 2).ok);
    REQUIRE(w.set("project", "/assetSources/images", Json::parse(R"(["https://example.com/art"])")).ok);
    REQUIRE(w.set("project", "/mcpServers/scenario", false).ok);
    CHECK_FALSE(fsys::exists(w.trust_file()));
    CHECK(w.get("project").result["pendingTrust"] == true);

    // a file the user accepted (as the editor does) stops applying once a command changes it
    REQUIRE(accept_project_settings(w.proj.str(), "", w.ai, fake_env({})));
    CHECK(w.get("project").result["applied"] == true);
    const std::string trustBefore = *fa::fs::read_text(w.trust_file());
    auto again = w.set("project", "/limits/maxTurns", 7);
    REQUIRE(again.ok);
    CHECK(again.result["needsAcceptance"] == true);
    CHECK(*fa::fs::read_text(w.trust_file()) == trustBefore);  // unchanged: the new file is not in it
    CHECK(w.get("project").result["applied"] == false);

    // value null removes the override; the last one removes the file
    auto reset = w.set("project", "/limits/maxTurns", nullptr);
    REQUIRE(reset.ok);
    CHECK(reset.result["removed"] == true);
    CHECK(w.get("project").result["overrides"]["limits"].contains("maxTurns") == false);
    for (const char* p : {"/roles/artist/enabled", "/limits/maxCostUsd", "/assetSources/images", "/mcpServers/scenario"}) REQUIRE(w.set("project", p, nullptr).ok);
    CHECK_FALSE(fsys::exists(w.settings_file()));
    auto last = w.set("project", "/limits/maxCostUsd", nullptr);  // nothing to remove is not an error
    REQUIRE(last.ok);
    CHECK(last.result["needsAcceptance"] == false);
}

TEST_CASE("ai.settings.set project: unknown pointers and rejected keys are refused with what to do") {
    World w;
    auto typo = w.set("project", "/roles/artst/enabled", false);
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["code"] == "unknown_pointer");
    CHECK(has(typo.error["message"].get<std::string>() + typo.error["hint"].get<std::string>(), "artist"));  // did you mean

    auto limits = w.set("project", "/limits/maxTurnz", 3);
    REQUIRE_FALSE(limits.ok);
    CHECK(limits.error["code"] == "unknown_pointer");
    CHECK(has(limits.error["hint"], "/limits/maxTurns"));

    auto branch = w.set("project", "/roles/artist", Json::object());
    REQUIRE_FALSE(branch.ok);
    CHECK(branch.error["code"] == "unknown_pointer");
    CHECK(has(branch.error["hint"], "ai.settings.get"));

    for (const char* p : {"/providers/x/command", "/defaultProvider", "/roles/worker/apiKey", "/mcpServers/scenario/url", "/roles/worker/command"}) {
        INFO(p);
        auto r = w.set("project", p, "evil");
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "rejected_key");
        CHECK(has(r.error["message"], "~/.factoria/ai.json"));
    }
    // a name the user does not have
    auto server = w.set("project", "/mcpServers/nope", true);
    REQUIRE_FALSE(server.ok);
    CHECK(has(server.error["message"], "nope"));
    auto provider = w.set("project", "/roles/worker/provider", "not-a-provider");
    REQUIRE_FALSE(provider.ok);
    CHECK(has(provider.error["message"], "not-a-provider"));
    // a value of the wrong type
    auto wrong = w.set("project", "/limits/maxTurns", "many");
    REQUIRE_FALSE(wrong.ok);
    CHECK(wrong.error["code"] == "invalid_setting");

    CHECK_FALSE(fsys::exists(w.settings_file()));  // nothing was written
    CHECK_FALSE(fsys::exists(w.trust_file()));
}

TEST_CASE("ai.settings.set user: writes ai.json, keeps everything else, null removes the key; never the trust file") {
    World w;
    auto s = w.set("user", "/roles/artist/enabled", false);
    REQUIRE(s.ok);
    CHECK(s.result["needsAcceptance"] == false);
    CHECK(s.result["source"] == "you");
    auto file = fa::parse_json(*fa::fs::read_text(w.ai), "f");
    REQUIRE(file);
    CHECK((*file)["roles"]["artist"]["enabled"] == false);
    CHECK((*file)["roles"]["orchestrator"]["model"] == "opus");                    // kept
    CHECK((*file)["providers"].contains("openrouter"));                          // kept
    CHECK((*file)["mcpServers"]["scenario"]["url"] == "https://mcp.example.com/mcp");  // kept
    CHECK_FALSE(fsys::exists(w.trust_file()));
    // every project starts from it
    CHECK(value_row(w.get("resolved").result["values"], "/roles/artist/enabled")["value"] == false);
    CHECK(value_row(w.get("resolved").result["values"], "/roles/artist/enabled")["source"] == "you");

    REQUIRE(w.set("user", "/mcpServers/scenario", false).ok);
    file = fa::parse_json(*fa::fs::read_text(w.ai), "f");
    CHECK((*file)["mcpServers"]["scenario"]["enabled"] == false);
    CHECK((*file)["mcpServers"]["scenario"]["url"] == "https://mcp.example.com/mcp");
    REQUIRE(w.set("user", "/limits/maxTurns", nullptr).ok);
    file = fa::parse_json(*fa::fs::read_text(w.ai), "f");
    CHECK_FALSE((*file)["limits"].contains("maxTurns"));
    CHECK(value_row(w.get("user").result["values"], "/limits/maxTurns")["source"] == "default");

    auto bad = w.set("user", "/roles/artst/enabled", false);
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["code"] == "unknown_pointer");
    auto rejected = w.set("user", "/providers/openrouter/command", "x");
    REQUIRE_FALSE(rejected.ok);
    CHECK(rejected.error["code"] == "rejected_key");
    auto ghost = w.set("user", "/mcpServers/ghost", true);
    REQUIRE_FALSE(ghost.ok);
    CHECK(has(ghost.error["message"], "ghost"));
    // the file is still valid
    CHECK(load_config(w.ai, fake_env({})).ok());
}

TEST_CASE("roles off in the project: ai.run and agent_delegate refuse and say which project setting turned the role off") {
    World w;
    REQUIRE(save_project_settings(w.proj.str(), Json::parse(R"({"roles":{"artist":{"enabled":false}}})"), w.ai, fake_env({}), true));
    auto refused = w.reg.call("ai.run", Json::object({{"task", "paint"}, {"role", "artist"}}));
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"] == "role_off");
    const std::string text = refused.error["message"].get<std::string>() + " " + refused.error["hint"].get<std::string>();
    CHECK(has(text, "this project's AI settings"));
    CHECK(has(text, w.settings_file()));
    CHECK(has(text, "/roles/artist/enabled"));
    CHECK(has(text, "ai.settings.set"));
    CHECK(w.provider->requests.empty());

    // another role is not affected
    w.provider->script = {text_response("done")};
    CHECK(w.reg.call("ai.run", Json::object({{"task", "code"}, {"role", "worker"}})).ok);

    // the in-process delegation of the built-in agent says the same
    AiConfig cfg = *load_resolved_config(w.proj.str(), w.ai, fake_env({}));
    REQUIRE_FALSE(cfg.role_enabled("artist"));
    cfg.roles["orchestrator"] = default_config().roles["orchestrator"];  // an API provider: the fake one answers (not a CLI agent)
    auto provider = std::make_shared<FakeProvider>();
    ToolCall d;
    d.id = "d1";
    d.name = "agent_delegate";
    d.input = Json::object({{"role", "artist"}, {"task", "paint"}});
    provider->script = {tool_response({d}), text_response("I will do it myself.")};
    SessionOptions so;
    so.projectDir = w.proj.str();
    AgentSession s(w.reg, cfg, so);
    s.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
        return std::static_pointer_cast<ChatProvider>(provider);
    });
    REQUIRE(s.run("make the art").ok);
    REQUIRE(provider->requests.size() == 2);
    const auto& res = provider->requests[1].messages.back().toolResults[0];
    CHECK(res.isError);
    CHECK(has(res.content, "role_off"));
    CHECK(has(res.content, "this project's AI settings"));
    CHECK(has(res.content, "/roles/artist/enabled"));

    // a role the USER turned off says it is ai.json that does it
    REQUIRE(w.set("user", "/roles/audio/enabled", false).ok);
    auto user = w.reg.call("ai.run", Json::object({{"task", "sound"}, {"role", "audio"}}));
    REQUIRE_FALSE(user.ok);
    CHECK(user.error["code"] == "role_off");
    CHECK_FALSE(has(user.error["message"], "this project's AI settings"));
    CHECK(has(user.error["hint"], "ai.json"));

    // a project file that has not been accepted does not turn anything off
    write_file(w.settings_file(), R"({"roles":{"artist":{"enabled":false},"fast":{"enabled":false}}})");
    w.provider->script = {text_response("painted")};
    w.provider->calls = 0;
    CHECK(w.reg.call("ai.run", Json::object({{"task", "paint"}, {"role", "fast"}})).ok);
}
