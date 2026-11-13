// ai.settings.get / ai.settings.set: every scope, that set never accepts a project's file (ai-trust.json is not written), unknown
// pointers, rejected keys, and that ai.run and agent_delegate honour a role the project turned off and say which setting did.
#include <atomic>
#include <fstream>
#include <thread>
#include <vector>

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
    int userChanged = 0, projectChanged = 0;  // how many times the editor's callbacks ran
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
        opt.onUserConfigChanged = [this] { ++userChanged; };
        opt.onProjectConfigChanged = [this] { ++projectChanged; };
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
    REQUIRE(save_project_settings(w.proj.str(),
                                  Json::parse(R"({"roles":{"artist":{"enabled":false}},"limits":{"maxTurns":5}})"),
                                  w.ai, fake_env({}), true));
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
    write_file(w.settings_file(),
               R"({"roles":{"artist":{"enabled":false}}})");  // as if it came inside a copied project
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
    for (const char* p :
         {"/roles/artist/enabled", "/limits/maxCostUsd", "/assetSources/images", "/mcpServers/scenario"})
        REQUIRE(w.set("project", p, nullptr).ok);
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
    CHECK(has(typo.error["message"].get<std::string>() + typo.error["hint"].get<std::string>(),
              "artist"));  // did you mean

    auto limits = w.set("project", "/limits/maxTurnz", 3);
    REQUIRE_FALSE(limits.ok);
    CHECK(limits.error["code"] == "unknown_pointer");
    CHECK(has(limits.error["hint"], "/limits/maxTurns"));

    auto branch = w.set("project", "/roles/artist", Json::object());
    REQUIRE_FALSE(branch.ok);
    CHECK(branch.error["code"] == "unknown_pointer");
    CHECK(has(branch.error["hint"], "ai.settings.get"));

    for (const char* p : {"/providers/x/command", "/defaultProvider", "/roles/worker/apiKey",
                          "/mcpServers/scenario/url", "/roles/worker/command"}) {
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
    CHECK((*file)["roles"]["orchestrator"]["model"] == "opus");                        // kept
    CHECK((*file)["providers"].contains("openrouter"));                                // kept
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

TEST_CASE("ai.settings.set user: the result lists what changed, and the callbacks tell the editor") {
    World w;
    auto s = w.set("user", "/limits/maxTurns", 12);
    REQUIRE(s.ok);
    REQUIRE(s.result["changed"].size() == 1);
    CHECK(s.result["changed"][0]["pointer"] == "/limits/maxTurns");
    CHECK(s.result["changed"][0]["from"] == 30);
    CHECK(s.result["changed"][0]["to"] == 12);
    CHECK(w.userChanged == 1);
    CHECK(w.projectChanged == 0);

    // a new provider for a role drops the model it had: both show up
    auto p = w.set("user", "/roles/orchestrator/provider", "openrouter");
    REQUIRE(p.ok);
    bool provider = false, model = false;
    for (const Json& c : p.result["changed"]) {
        if (c["pointer"] == "/roles/orchestrator/provider")
            provider = c["from"] == "claude-code" && c["to"] == "openrouter";
        if (c["pointer"] == "/roles/orchestrator/model") model = c["from"] == "opus" && c["to"] != "opus";
    }
    CHECK(provider);
    CHECK(model);

    // a removal says what went back to the engine's value; a value that was not set changes nothing
    auto r = w.set("user", "/limits/maxTurns", nullptr);
    REQUIRE(r.ok);
    REQUIRE(r.result["changed"].size() == 1);
    CHECK(r.result["changed"][0]["from"] == 12);
    CHECK(r.result["changed"][0]["to"] != 12);
    auto none = w.set("user", "/limits/maxCostUsd", nullptr);
    REQUIRE(none.ok);
    CHECK(none.result["changed"].empty());

    // a project change tells the other callback; a refused one tells nobody
    const int user = w.userChanged;
    REQUIRE(w.set("project", "/roles/artist/enabled", false).ok);
    CHECK(w.projectChanged == 1);
    CHECK(w.userChanged == user);
    CHECK_FALSE(w.set("project", "/roles/artst/enabled", false).ok);
    CHECK_FALSE(w.set("user", "/limits/nope", 1).ok);
    CHECK(w.projectChanged == 1);
    CHECK(w.userChanged == user);
}

TEST_CASE("ai.settings.set user: only the user's own calls may change the user's defaults (not MCP, not an AI agent)") {
    World w;
    const std::string before = *fa::fs::read_text(w.ai);
    for (CommandCaller who : {CommandCaller::Mcp, CommandCaller::Agent}) {
        CommandCallerScope scope(who);
        INFO(command_caller_name(who));
        auto refused = w.set("user", "/roles/artist/enabled", false);
        REQUIRE_FALSE(refused.ok);
        CHECK(refused.error["code"] == "user_only");
        const std::string text =
            refused.error["message"].get<std::string>() + " " + refused.error["hint"].get<std::string>();
        CHECK(has(text, command_caller_name(who)));
        CHECK(has(text, "AI settings window (Your defaults)"));
        CHECK(has(text, "ask the user"));
        // removing is refused the same way
        auto removal = w.set("user", "/limits/maxTurns", nullptr);
        REQUIRE_FALSE(removal.ok);
        CHECK(removal.error["code"] == "user_only");
        // reading the user's settings and changing the PROJECT's file stay open to an AI
        CHECK(w.get("user").ok);
        CHECK(w.set("project", "/limits/maxCostUsd", 3).ok);
    }
    CHECK(*fa::fs::read_text(w.ai) == before);  // ai.json was not touched
    CHECK(w.userChanged == 0);
    CHECK(w.projectChanged == 2);
    // outside the scopes the same call works: `factoria call` installs none
    CHECK(command_caller() == CommandCaller::User);
    auto allowed = w.set("user", "/roles/artist/enabled", false);
    REQUIRE(allowed.ok);
    CHECK(allowed.result["changed"].size() == 1);
    CHECK(w.userChanged == 1);
}

TEST_CASE(
    "ai.settings.set project: removing a value keeps an accepted file accepted, a file nobody accepted stays pending") {
    World w;
    // accepted (as the editor does): two values
    REQUIRE(save_project_settings(w.proj.str(),
                                  Json::parse(R"({"roles":{"artist":{"enabled":false}},"limits":{"maxTurns":5}})"),
                                  w.ai, fake_env({}), true));
    const std::string hashBefore = read_project_settings_file(w.proj.str()).hash;
    CHECK(w.get("project").result["applied"] == true);
    auto r = w.set("project", "/limits/maxTurns", nullptr);
    REQUIRE(r.ok);
    CHECK(r.result["needsAcceptance"] == false);
    CHECK(r.result["applied"] == true);  // still accepted
    CHECK(has(r.result["hint"], "already accepted"));
    const std::string hashAfter = read_project_settings_file(w.proj.str()).hash;
    CHECK(hashAfter != hashBefore);
    // the trust record follows the smaller file: it is the one that is accepted now
    CHECK(project_ai_settings_trusted(w.trust_file(), w.proj.str(), hashAfter, nullptr, false));
    CHECK_FALSE(project_ai_settings_trusted(w.trust_file(), w.proj.str(), hashBefore, nullptr, false));
    CHECK(w.get("project").result["pendingTrust"] == false);

    // setting a value in it is not an acceptance: the file waits again and the record is the old one
    REQUIRE(w.set("project", "/limits/maxTurns", 9).ok);
    CHECK(w.get("project").result["pendingTrust"] == true);
    CHECK(project_ai_settings_trusted(w.trust_file(), w.proj.str(), hashAfter, nullptr, false));
    REQUIRE(w.set("project", "/limits/maxTurns", nullptr).ok);  // back to the accepted content: accepted again
    CHECK(w.get("project").result["pendingTrust"] == false);

    // emptying the file removes it and forgets the record
    REQUIRE(w.set("project", "/roles/artist/enabled", nullptr).ok);
    CHECK_FALSE(fsys::exists(w.settings_file()));
    auto trust = fa::parse_json(*fa::fs::read_text(w.trust_file()), "trust");
    REQUIRE(trust);
    CHECK_FALSE(project_ai_settings_trusted(w.trust_file(), w.proj.str(), hashAfter, nullptr, false));
    const Json section = trust->value("aiSettings", Json::object());
    CHECK_FALSE(section.contains(ai_settings_trust_key(w.proj.str())));

    // a file nobody accepted: removing a value leaves it waiting (and writes no trust)
    write_file(w.settings_file(), R"({"roles":{"artist":{"enabled":false}},"limits":{"maxTurns":5}})");
    const std::string trustText = *fa::fs::read_text(w.trust_file());
    auto pending = w.set("project", "/limits/maxTurns", nullptr);
    REQUIRE(pending.ok);
    CHECK(pending.result["needsAcceptance"] == true);
    CHECK(pending.result["applied"] == false);
    CHECK(w.get("project").result["pendingTrust"] == true);
    CHECK(*fa::fs::read_text(w.trust_file()) == trustText);
}

TEST_CASE("set_user_setting: a pointer that is not a setting is refused also when the value is null") {
    World w;
    const std::string before = *fa::fs::read_text(w.ai);
    auto typo = set_user_setting("/roles/artst/enabled", Json(nullptr), w.ai, fake_env({}));
    REQUIRE_FALSE(typo.ok());
    CHECK(has(typo.error().message + " " + typo.error().hint, "artist"));
    auto limit = set_user_setting("/limits/maxTurnz", Json(nullptr), w.ai, fake_env({}));
    REQUIRE_FALSE(limit.ok());
    CHECK(has(limit.error().message + " " + limit.error().hint, "/limits/maxTurns"));
    auto ghost = set_user_setting("/mcpServers/ghost", Json(nullptr), w.ai, fake_env({}));
    REQUIRE_FALSE(ghost.ok());
    CHECK(has(ghost.error().message, "ghost"));
    auto branch = set_user_setting("/roles", Json(nullptr), w.ai, fake_env({}));
    REQUIRE_FALSE(branch.ok());
    CHECK(has(branch.error().message, "/roles"));
    CHECK(*fa::fs::read_text(w.ai) == before);
    // a real setting the file does not set is not an error and writes nothing
    CHECK(set_user_setting("/limits/maxCostUsd", Json(nullptr), w.ai, fake_env({})).ok());
    CHECK(*fa::fs::read_text(w.ai) == before);
}

TEST_CASE(
    "roles off in the project: ai.run and agent_delegate refuse and say which project setting turned the role off") {
    World w;
    REQUIRE(save_project_settings(w.proj.str(), Json::parse(R"({"roles":{"artist":{"enabled":false}}})"), w.ai,
                                  fake_env({}), true));
    auto refused = w.reg.call("ai.run", Json::object({{"task", "paint"}, {"role", "artist"}}));
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"] == "role_off");
    const std::string text =
        refused.error["message"].get<std::string>() + " " + refused.error["hint"].get<std::string>();
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
    cfg.roles["orchestrator"] =
        default_config().roles["orchestrator"];  // an API provider: the fake one answers (not a CLI agent)
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

TEST_CASE(
    "write_private_file: owner-only, a symlinked file is written through, two writers never share a temporary file") {
    TempDir t;
    const fsys::path file = t.path / "sub" / "ai.json";
    REQUIRE(write_private_file(file.string(), "one"));
    {
        auto text = fa::fs::read_text(file.string());
        REQUIRE(text);
        CHECK(*text == "one");
    }
#ifndef _WIN32
    const auto perms = fsys::status(file).permissions();
    CHECK((perms & (fsys::perms::group_all | fsys::perms::others_all)) == fsys::perms::none);
#else
    // Windows: the protected owner-only ACL is read back in engine/core/tests/test_private_file.cpp. Here what a wrong ACL would
    // break in this code path: the owner (this process) replaces what it wrote and reads the new bytes, the file is not
    // read-only, and the replace left no temporary file.
    REQUIRE(fsys::exists(file));
    CHECK((fsys::status(file).permissions() & fsys::perms::owner_write) != fsys::perms::none);
    REQUIRE(write_private_file(file.string(), "one again"));
    {
        auto again = fa::fs::read_text(file.string());
        REQUIRE(again);
        CHECK(*again == "one again");
    }
    REQUIRE(write_private_file(file.string(), "one"));
#endif
    auto leftovers = [&](const fsys::path& dir) {
        int n = 0;
        for (const auto& e : fsys::directory_iterator(dir))
            if (e.path().filename().string().find(".fa-tmp") != std::string::npos) ++n;
        return n;
    };
    CHECK(leftovers(file.parent_path()) == 0);

    // Writers at the same time (the editor's MCP threads and the agent can all save): none fails, one text wins whole.
    std::atomic<int> failed{0};
    std::vector<std::thread> writers;
    for (int w = 0; w < 4; ++w) {
        writers.emplace_back([&, w] {
            for (int i = 0; i < 25; ++i) {
                if (!write_private_file(file.string(), "writer " + std::to_string(w) + " round " + std::to_string(i)))
                    ++failed;
            }
        });
    }
    for (auto& th : writers) th.join();
#ifndef _WIN32
    CHECK(
        failed ==
        0);  // on Windows a file another writer has open can refuse the replace: fs::replace_file retries but may give up
#endif
    CHECK(has(*fa::fs::read_text(file.string()), "writer "));
    CHECK(leftovers(file.parent_path()) == 0);

#ifndef _WIN32
    // ai.json may be a link into a dotfiles repository: the link stays, the file behind it is replaced
    const fsys::path real = t.path / "dotfiles" / "ai.json";
    fsys::create_directories(real.parent_path());
    write_file(real, "old");
    const fsys::path link = t.path / "link.json";
    std::error_code ec;
    fsys::create_symlink(real, link, ec);
    if (!ec) {
        REQUIRE(write_private_file(link.string(), "two"));
        CHECK(fsys::is_symlink(link));
        CHECK(*fa::fs::read_text(real.string()) == "two");
        CHECK(leftovers(t.path) == 0);
    }
#endif
}

TEST_CASE(
    "ai.settings.set: null for a setting the file does not hold says removed false with a hint that nothing changed") {
    World w;
    // project: the project has no file at all, then a file that holds another value
    auto none = w.set("project", "/limits/maxTurns", nullptr);
    REQUIRE(none.ok);
    CHECK(none.result["removed"] == false);
    CHECK(has(none.result["hint"], "Nothing changed"));
    CHECK(has(none.result["hint"], "/limits/maxTurns"));
    CHECK_FALSE(fsys::exists(w.settings_file()));  // nothing was written
    REQUIRE(save_project_settings(w.proj.str(), Json::parse(R"({"roles":{"artist":{"enabled":false}}})"), w.ai,
                                  fake_env({}), true));
    auto other = w.set("project", "/limits/maxTurns", nullptr);
    REQUIRE(other.ok);
    CHECK(other.result["removed"] == false);
    CHECK(has(other.result["hint"], "Nothing changed"));
    auto real = w.set("project", "/roles/artist/enabled", nullptr);
    REQUIRE(real.ok);
    CHECK(real.result["removed"] == true);
    CHECK_FALSE(has(real.result["hint"], "Nothing changed"));

    // user: ai.json sets maxTurns, not artist.enabled
    auto notSet = w.set("user", "/roles/artist/enabled", nullptr);
    REQUIRE(notSet.ok);
    CHECK(notSet.result["removed"] == false);
    CHECK(has(notSet.result["hint"], "Nothing changed"));
    CHECK(notSet.result["changed"].empty());
    auto set = w.set("user", "/limits/maxTurns", nullptr);
    REQUIRE(set.ok);
    CHECK(set.result["removed"] == true);
    CHECK(has(set.result["hint"], "Saved in your ai.json"));
}

TEST_CASE("ai.settings.set user: removing a tool server or a plugin switch says removed true only when ai.json held "
          "its \"enabled\"") {
    World w;
    write_file(w.ai, R"({
      "mcpServers": {"scenario": {"type": "http", "url": "https://mcp.example.com/mcp", "enabled": false},
                     "plain": {"type": "http", "url": "https://mcp.example.com/plain"}},
      "extensions": {"plugins": {"notes": {"path": ")" +
                         (w.home.path / "notes").generic_string() + R"(", "note": "keeps notes", "enabled": false}}}
    })");
    fsys::create_directories(w.home.path / "notes");
    auto read = [&] {
        auto file = fa::parse_json(*fa::fs::read_text(w.ai), "f");
        REQUIRE(file);
        return *file;
    };
    // a tool server whose definition holds its switch: the switch goes, the definition stays
    auto server = w.set("user", "/mcpServers/scenario", nullptr);
    REQUIRE(server.ok);
    CHECK(server.result["removed"] == true);
    CHECK(has(server.result["hint"], "Saved in your ai.json"));
    Json file = read();
    CHECK(file.contains("/mcpServers/scenario/url"_json_pointer));
    CHECK_FALSE(file.contains("/mcpServers/scenario/enabled"_json_pointer));
    CHECK(file.contains("/extensions/plugins/notes/enabled"_json_pointer));  // the plugin is untouched
    // the same for a plugin
    auto plugin = w.set("user", "/extensions/plugins/notes", nullptr);
    REQUIRE(plugin.ok);
    CHECK(plugin.result["removed"] == true);
    file = read();
    CHECK(file.contains("/extensions/plugins/notes/path"_json_pointer));
    CHECK_FALSE(file.contains("/extensions/plugins/notes/enabled"_json_pointer));
    // a definition without a switch, and a switch that is already gone: nothing was taken out
    for (const char* pointer : {"/mcpServers/plain", "/mcpServers/scenario", "/extensions/plugins/notes"}) {
        const std::string before = *fa::fs::read_text(w.ai);
        auto none = w.set("user", pointer, nullptr);
        INFO(pointer);
        REQUIRE(none.ok);
        CHECK(none.result["removed"] == false);
        CHECK(has(none.result["hint"], "Nothing changed"));
        CHECK(*fa::fs::read_text(w.ai) == before);
    }
}

TEST_CASE("ai.settings: the permission mode of each CLI agent is listed with what it allows and set only by the user") {
    World w;
    auto got = w.get("user");
    REQUIRE(got.ok);
    Json claude;
    for (const Json& row : got.result["permissionModes"])
        if (row["provider"] == "claude-code") claude = row;
    REQUIRE(claude.is_object());
    CHECK(claude["mode"] == "acceptEdits");
    CHECK(claude["default"] == "acceptEdits");
    CHECK(claude["source"] == "default");
    CHECK(claude["pointer"] == "/providers/claude-code/permissionMode");
    bool sawDangerous = false;
    for (const Json& v : claude["values"]) {
        CHECK_FALSE(v["allows"].get<std::string>().empty());
        sawDangerous = sawDangerous || (v["value"] == "bypassPermissions" && v["dangerous"] == true);
    }
    CHECK(sawDangerous);
    CHECK(w.get("resolved").result.contains("permissionModes"));

    // a project file can never hold it, not even through ai.settings.set
    auto project = w.set("project", "/providers/claude-code/permissionMode", "bypassPermissions");
    REQUIRE_FALSE(project.ok);
    CHECK(project.error["code"] == "rejected_key");
    CHECK_FALSE(fsys::exists(w.settings_file()));
    // an AI agent or MCP client cannot change it for the user
    const std::string before = *fa::fs::read_text(w.ai);
    for (CommandCaller who : {CommandCaller::Mcp, CommandCaller::Agent}) {
        CommandCallerScope scope(who);
        auto refused = w.set("user", "/providers/claude-code/permissionMode", "bypassPermissions");
        REQUIRE_FALSE(refused.ok);
        CHECK(refused.error["code"] == "user_only");
    }
    CHECK(*fa::fs::read_text(w.ai) == before);

    // the user does
    auto ok = w.set("user", "/providers/claude-code/permissionMode", "plan");
    REQUIRE(ok.ok);
    CHECK(ok.result["runsWith"] == "plan");
    CHECK(ok.result["dangerous"] == false);
    CHECK(ok.result["changed"].size() == 1);
    CHECK(w.userChanged == 1);
    CHECK(Json::parse(*fa::fs::read_text(w.ai))["providers"]["claude-code"]["permissionMode"] == "plan");
    CHECK(Json::parse(*fa::fs::read_text(w.ai))["limits"]["maxTurns"] == 30);  // the rest stays
    auto danger = w.set("user", "/providers/codex/permissionMode", "danger-full-access");
    REQUIRE(danger.ok);
    CHECK(danger.result["dangerous"] == true);
    CHECK(has(danger.result["hint"], "DANGEROUS"));
    // wrong values and providers teach
    auto wrongKind = w.set("user", "/providers/codex/permissionMode", "acceptEdits");
    REQUIRE_FALSE(wrongKind.ok);
    CHECK(has(wrongKind.error["message"], "/providers/codex/permissionMode"));
    auto unknown = w.set("user", "/providers/claud-code/permissionMode", "plan");
    REQUIRE_FALSE(unknown.ok);
    CHECK(has(unknown.error["hint"], "claude-code"));
    CHECK_FALSE(w.set("user", "/providers/claude-code/permissionMode", 3).ok);
    CHECK_FALSE(w.set("user", "/providers/openrouter/permissionMode", "plan").ok);
    // null goes back to the default and drops the key
    auto reset = w.set("user", "/providers/claude-code/permissionMode", nullptr);
    REQUIRE(reset.ok);
    CHECK(reset.result["runsWith"] == "acceptEdits");
    CHECK_FALSE(Json::parse(*fa::fs::read_text(w.ai))["providers"].contains("claude-code"));
}
