// AI settings per project (<project>/.factoria/ai/settings.json): the resolution order and where each value comes from, partial
// roles, the keys a project file may not hold, unknown names with suggestions, the trust of a file the user did not save, the
// writer that keeps only what differs, and that a project without the file behaves as before.
#include <algorithm>
#include <cctype>
#include <fstream>

#include "fa/ai/extensions.h"
#include "fa/ai/project_settings.h"
#include "fa/core/json_schema.h"
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

const EnvLookup kNoEnv = [](const std::string&) { return std::string(); };

// A user's ai.json (two providers of its own, the orchestrator on Claude Code, a tool server, a skill) in its own folder, and an
// empty project next to it.
struct Setup {
    TempDir home, proj;
    std::string ai;
    Setup() {
        ai = (home.path / "ai.json").string();
        write_file(ai, R"({
          "providers": {"openrouter": {"type": "openai-compatible", "preset": "openrouter", "apiKeyEnv": "OPENROUTER_API_KEY"}},
          "roles": {"orchestrator": {"provider": "claude-code", "model": "opus"},
                    "worker": {"provider": "claude-code", "model": "sonnet"}},
          "limits": {"maxTurns": 30},
          "mcpServers": {"scenario": {"type": "http", "url": "https://mcp.example.com/mcp"}},
          "extensions": {"skills": {"gdd": {"path": "~/skills/gdd"}}}
        })");
    }
    std::string settings_path() const { return (proj.path / ".factoria" / "ai" / "settings.json").string(); }
    // A file as it would arrive inside a copied project: nobody on this computer saved it.
    void copy_in(const std::string& text) const { write_file(settings_path(), text); }
    Result<ResolvedAiConfig> resolve() const { return resolve_ai_config(proj.str(), ai, kNoEnv); }
    Result<AiConfig> load() const { return load_resolved_config(proj.str(), ai, kNoEnv); }
    // Saves like the editor does on the user's behalf: the acceptance is recorded (the default of the function is not to).
    Result<void> save(const Json& overrides, bool recordTrust = true) const {
        return save_project_settings(proj.str(), overrides, ai, kNoEnv, recordTrust);
    }
    // What is wrong with a file that came with the project (so it is not accepted): it has no effect, the resolution succeeds as
    // without the file and says what is wrong. "" when the file is fine.
    std::string error_of(const std::string& text) const {
        copy_in(text);
        auto r = resolve();
        if (!r) return "resolve failed: " + r.error().message;
        if (!r->invalidError) return std::string();
        return r->invalidError->message + " | " + r->invalidError->hint;
    }
};

}  // namespace

TEST_CASE("project settings: the embedded schema is valid and accepts the documented file") {
    Json schema = Json::parse(std::string(project_settings_schema_text()), nullptr, false);
    REQUIRE_FALSE(schema.is_discarded());
    CHECK(schema["properties"].contains("roles"));
    CHECK(validate_project_settings_json(Json::parse(R"({"roles": {"artist": {"enabled": false, "effort": "low"}},
        "limits": {"maxTurns": 12}, "mcpServers": {"scenario": false}})")).empty());
    CHECK_FALSE(validate_project_settings_json(Json::parse(R"({"limits": {"maxTurns": 0}})")).empty());
    CHECK_FALSE(validate_project_settings_json(Json::parse(R"({"roles": {"artist": {"effort": "huge"}}})")).empty());
}

TEST_CASE("project settings: a project without the file runs exactly as before and nothing is written") {
    Setup s;
    auto user = load_config(s.ai, kNoEnv);
    REQUIRE(user);
    auto resolved = s.resolve();
    REQUIRE(resolved);
    CHECK_FALSE(resolved->fileExists);
    CHECK_FALSE(resolved->applied);
    CHECK_FALSE(resolved->pendingTrust);
    CHECK(settings_view(resolved->config) == settings_view(*user));
    auto loaded = s.load();
    REQUIRE(loaded);
    CHECK(settings_view(*loaded) == settings_view(*user));
    CHECK(loaded->sourcePath == user->sourcePath);
    CHECK_FALSE(fsys::exists(s.proj.path / ".factoria"));
    CHECK_FALSE(fsys::exists(fsys::path(extensions_trust_path(s.ai))));
    // No project at all: the user file alone.
    auto none = load_resolved_config("", s.ai, kNoEnv);
    REQUIRE(none);
    CHECK(settings_view(*none) == settings_view(*user));
}

TEST_CASE("project settings: engine defaults < ai.json < project, and where each value comes from") {
    Setup s;
    REQUIRE(s.save(Json::parse(R"({"limits": {"maxCostUsd": 5}, "roles": {"worker": {"enabled": false}}})")));
    auto r = s.resolve();
    REQUIRE(r);
    REQUIRE(r->applied);
    CHECK(r->config.limits.maxCostUsd == 5);
    CHECK_FALSE(r->config.role_enabled("worker"));
    CHECK(r->config.limits.maxTurns == 30);  // ai.json
    CHECK(r->config.limits.stuckAfterSeconds == 180);  // the engine's
    CHECK(r->source_of("/limits/maxCostUsd") == SettingSource::Project);
    CHECK(r->source_of("/roles/worker/enabled") == SettingSource::Project);
    CHECK(r->source_of("/limits/maxTurns") == SettingSource::You);
    CHECK(r->source_of("/roles/orchestrator/provider") == SettingSource::You);
    CHECK(r->source_of("/limits/stuckAfterSeconds") == SettingSource::Default);
    CHECK(r->source_of("/savers/loopGuard") == SettingSource::Default);
    CHECK(std::string(setting_source_name(SettingSource::Project)) == "project");
    CHECK(std::string(setting_source_name(SettingSource::You)) == "you");
    CHECK(std::string(setting_source_name(SettingSource::Default)) == "default");
    // The inherited config is what "reset to mine" goes back to.
    CHECK(r->inherited.role_enabled("worker"));
    CHECK(r->inherited.limits.maxCostUsd == 0);
    // A value the project names stays "project" even when it equals the inherited one, in a file that was written by hand.
    s.copy_in(R"({"limits": {"maxTurns": 30}})");
    REQUIRE(accept_project_settings(s.proj.str(), "", s.ai, kNoEnv));
    auto same = s.resolve();
    REQUIRE(same);
    CHECK(same->source_of("/limits/maxTurns") == SettingSource::Project);
}

TEST_CASE("project settings: roles are partial, role by role and field by field") {
    Setup s;
    REQUIRE(s.save(Json::parse(R"({"roles": {"artist": {"effort": "low"}, "worker": {"model": "haiku"}}})")));
    auto cfg = s.load();
    REQUIRE(cfg);
    CHECK(cfg->role("worker").model == "haiku");
    CHECK(cfg->role("worker").provider == "claude-code");  // inherited
    CHECK(cfg->role("artist").effort == "low");
    CHECK(cfg->role("orchestrator").model == "opus");  // untouched
    CHECK(cfg->role("fast").provider == load_config(s.ai, kNoEnv)->role("fast").provider);

    // A different provider brings its own model and effort unless the file says them.
    REQUIRE(s.save(Json::parse(R"({"roles": {"worker": {"provider": "openrouter"}}})")));
    auto moved = s.load();
    REQUIRE(moved);
    CHECK(moved->role("worker").provider == "openrouter");
    CHECK(moved->role("worker").model != "sonnet");  // the model of the old provider is not carried over
    REQUIRE(s.save(Json::parse(R"({"roles": {"worker": {"provider": "openrouter", "model": "deepseek/deepseek-chat"}}})")));
    auto given = s.load();
    REQUIRE(given);
    CHECK(given->role("worker").model == "deepseek/deepseek-chat");
    // The same provider as ai.json keeps its model.
    REQUIRE(s.save(Json::parse(R"({"roles": {"worker": {"provider": "claude-code", "enabled": false}}})")));
    auto same = s.load();
    REQUIRE(same);
    CHECK(same->role("worker").model == "sonnet");
}

TEST_CASE("project settings: limits, savers, asset routes and sites, tool servers and extensions") {
    Setup s;
    REQUIRE(s.save(Json::parse(R"({
      "limits": {"maxTurns": 7}, "savers": {"loopGuard": false, "retrospective": true, "retrospectiveSteps": 60},
      "assetSources": {"images": ["kenney.nl", {"url": "opengameart.org", "note": "CC0"}], "onlyListed": true},
      "mcpServers": {"scenario": false}, "extensions": {"skills": {"gdd": false}}})")));
    auto cfg = s.load();
    REQUIRE(cfg);
    CHECK(cfg->limits.maxTurns == 7);
    CHECK_FALSE(cfg->savers.loopGuard);
    CHECK(cfg->savers.learnedToolGroups);
    CHECK(cfg->savers.retrospective);  // a project can turn the retrospective on, with its own threshold
    CHECK(cfg->savers.retrospectiveSteps == 60);
    CHECK(cfg->assetSources.onlyListed);
    REQUIRE(cfg->assetSources.images.size() == 2);
    CHECK(cfg->assetSources.images[1].note == "CC0");
    REQUIRE(cfg->toolServers.size() == 1);
    CHECK_FALSE(cfg->toolServers[0].enabled);
    CHECK(cfg->toolServers[0].url == "https://mcp.example.com/mcp");  // the definition is still the user's
    REQUIRE(cfg->extensions.entries.size() == 1);
    CHECK_FALSE(cfg->extensions.entries[0].enabled);
    CHECK(cfg->tool_servers_for("worker").empty());
}

TEST_CASE("project settings: keys that define a provider, server or extension are refused with their pointer and where they belong") {
    Setup s;
    const struct {
        const char* file;
        const char* pointer;
    } refused[] = {
        {R"({"providers": {"x": {"type": "openai-compatible", "baseUrl": "http://evil"}}})", "/providers"},
        {R"({"defaultProvider": "x"})", "/defaultProvider"},
        {R"({"roles": {"worker": {"apiKey": "sk-1"}}})", "/roles/worker/apiKey"},
        {R"({"roles": {"worker": {"baseUrl": "http://evil"}}})", "/roles/worker/baseUrl"},
        {R"({"roles": {"worker": {"command": "rm"}}})", "/roles/worker/command"},
        {R"({"mcpServers": {"scenario": {"url": "http://evil"}}})", "/mcpServers/scenario/url"},
        {R"({"mcpServers": {"scenario": {"command": "sh", "args": ["-c", "x"]}}})", "/mcpServers/scenario/command"},
        {R"({"mcpServers": {"scenario": {"headers": {"a": "b"}}}})", "/mcpServers/scenario/headers"},
        {R"({"mcpServers": {"scenario": {"env": {"A": "b"}}}})", "/mcpServers/scenario/env"},
        {R"({"extensions": {"skills": {"gdd": {"path": "/tmp/x"}}}})", "/extensions/skills/gdd/path"},
        {R"({"extensions": {"hooks": {"log": {"hooks": {}}}}})", "/extensions/hooks/log/hooks"},
        {R"({"assets": {"image": {"apiKeyEnv": "X"}}})", "/assets/image/apiKeyEnv"},
        {R"({"inheritEnv": ["AWS_SECRET_ACCESS_KEY"]})", "/inheritEnv"},  // a project could pull a secret into a hook or an agent
        {R"({"roles": {"worker": {"permissionMode": "bypassPermissions"}}})", "/roles/worker/permissionMode"},  // a project cannot loosen what an agent may do
        {R"({"providers": {"claude-code": {"permissionMode": "bypassPermissions"}}})", "/providers"},
        {R"({"mcpServers": {"scenario": {"inheritEnv": ["AWS_SECRET_ACCESS_KEY"]}}})", "/mcpServers/scenario/inheritEnv"},
    };
    for (const auto& c : refused) {
        INFO(c.file);
        const std::string err = s.error_of(c.file);
        CHECK(has(err, c.pointer));
        CHECK(has(err, "not allowed in a project's AI settings file"));
        CHECK(has(err, "~/.factoria/ai.json"));
        CHECK(has(err, s.settings_path()));
        // An invalid file that was not accepted has no effect, not even failing: it is reported, not thrown.
        auto r = s.resolve();
        REQUIRE(r);
        CHECK(r->pendingTrust);
        CHECK_FALSE(r->applied);
        CHECK(r->invalidError.has_value());
        CHECK(r->pending.empty());
        CHECK(settings_view(r->config) == settings_view(r->inherited));
        auto loaded = s.load();
        REQUIRE(loaded);
        CHECK(settings_view(*loaded) == settings_view(r->inherited));
        CHECK_FALSE(accept_project_settings(s.proj.str(), "", s.ai, kNoEnv));
    }
    // A permission mode points to the editor's Agents tab, where the user sets it.
    CHECK(has(s.error_of(R"({"roles": {"worker": {"permissionMode": "bypassPermissions"}}})"), "AI settings > Agents"));
    // The error teaches for the on/off form too.
    CHECK(has(s.error_of(R"({"mcpServers": {"scenario": {"enabled": false}}})"), "write the boolean itself"));
}

TEST_CASE("project settings: unknown names are errors with suggestions") {
    Setup s;
    std::string err = s.error_of(R"({"roles": {"worker": {"provider": "claud-code"}}})");
    CHECK(has(err, "/roles/worker/provider"));
    CHECK(has(err, "Did you mean 'claude-code'"));
    CHECK(has(err, "~/.factoria/ai.json"));
    err = s.error_of(R"({"roles": {"workr": {"enabled": false}}})");
    CHECK(has(err, "/roles/workr"));
    CHECK(has(err, "Did you mean 'worker'"));
    err = s.error_of(R"({"mcpServers": {"scenari": false}})");
    CHECK(has(err, "/mcpServers/scenari"));
    CHECK(has(err, "Did you mean 'scenario'"));
    err = s.error_of(R"({"extensions": {"skills": {"gddd": false}}})");
    CHECK(has(err, "/extensions/skills/gddd"));
    CHECK(has(err, "Did you mean 'gdd'"));
    err = s.error_of(R"({"extensions": {"plugins": {"notes": false}}})");
    CHECK(has(err, "no plugin named 'notes'"));
    err = s.error_of(R"({"limitz": {"maxTurns": 3}})");
    CHECK(has(err, "/limitz"));
    CHECK(has(err, "Did you mean 'limits'"));
    err = s.error_of(R"({"limits": {"maxTurn": 3}})");
    CHECK(has(err, "Did you mean 'maxTurns'"));
    err = s.error_of(R"({"assets": {"imge": {"provider": "openrouter"}}})");
    CHECK(has(err, "/assets/imge"));
    // Types and ranges come from the schema, with the pointer.
    err = s.error_of(R"({"limits": {"maxTurns": 0}})");
    CHECK(has(err, "/limits/maxTurns"));
    err = s.error_of(R"({"roles": {"orchestrator": {"enabled": false}}})");
    CHECK_FALSE(err.empty());  // the orchestrator cannot be turned off (ai.json's own rule, with the project file's name)
    CHECK(has(err, s.settings_path()));
    // Not JSON, and not an object.
    err = s.error_of("{ nope");
    CHECK(has(err, "settings.json"));
    err = s.error_of("[1]");
    CHECK(has(err, "must be a JSON object"));
}

TEST_CASE("project settings: a file the user did not save applies only after it is accepted") {
    Setup s;
    s.copy_in(R"({"limits": {"maxTurns": 5}, "roles": {"artist": {"enabled": false}}})");
    auto r = s.resolve();
    REQUIRE(r);
    CHECK(r->fileExists);
    CHECK_FALSE(r->applied);
    CHECK(r->pendingTrust);
    CHECK(r->config.limits.maxTurns == 30);  // as without the file
    CHECK(r->config.role_enabled("artist"));
    REQUIRE(r->pending.size() == 2);
    const bool listsTurns = std::any_of(r->pending.begin(), r->pending.end(), [](const SettingChange& c) {
        return c.pointer == "/limits/maxTurns" && c.from == 30 && c.to == 5 && c.text() == "/limits/maxTurns: 30 -> 5";
    });
    CHECK(listsTurns);
    CHECK(r->source_of("/limits/maxTurns") == SettingSource::You);
    auto loaded = s.load();
    REQUIRE(loaded);
    CHECK(loaded->limits.maxTurns == 30);
    CHECK_FALSE(fsys::exists(fsys::path(extensions_trust_path(s.ai))));  // looking grants and writes nothing

    // Accepting the file as shown: a different hash is refused.
    CHECK_FALSE(accept_project_settings(s.proj.str(), "0000", s.ai, kNoEnv));
    CHECK_FALSE(s.resolve()->applied);
    REQUIRE(accept_project_settings(s.proj.str(), r->fileHash, s.ai, kNoEnv));
    auto accepted = s.resolve();
    REQUIRE(accepted);
    CHECK(accepted->applied);
    CHECK_FALSE(accepted->pendingTrust);
    CHECK(accepted->config.limits.maxTurns == 5);
    const std::string trustPath = extensions_trust_path(s.ai);
    const std::string trustBefore = read_file(trustPath);
    CHECK_FALSE(trustBefore.empty());

    // An edit (an unzipped update, a pasted line) needs a new acceptance.
    s.copy_in(R"({"limits": {"maxTurns": 6}})");
    auto edited = s.resolve();
    REQUIRE(edited);
    CHECK_FALSE(edited->applied);
    CHECK(edited->pendingTrust);
    CHECK(edited->config.limits.maxTurns == 30);
    // Reading wrote nothing: the record of the text the user accepted is still there, so that exact text is accepted again; any
    // other text is not.
    CHECK_FALSE(s.resolve()->applied);
    CHECK(read_file(trustPath) == trustBefore);
    s.copy_in(R"({"limits": {"maxTurns": 5}, "roles": {"artist": {"enabled": false}}})");
    CHECK(s.resolve()->applied);
    s.copy_in(R"({"limits": {"maxTurns": 7}})");
    CHECK_FALSE(s.resolve()->applied);
    CHECK(read_file(trustPath) == trustBefore);

    // A file with an error cannot be accepted.
    s.copy_in(R"({"providers": {}})");
    CHECK_FALSE(accept_project_settings(s.proj.str(), "", s.ai, kNoEnv));
    // No file, nothing to accept.
    fsys::remove(s.settings_path());
    CHECK_FALSE(accept_project_settings(s.proj.str(), "", s.ai, kNoEnv));
}

TEST_CASE("project settings: saving on this computer records the acceptance; trust is per project and per file") {
    Setup s;
    TempDir other;
    REQUIRE(s.save(Json::parse(R"({"limits": {"maxTurns": 9}})")));
    auto r = s.resolve();
    REQUIRE(r);
    CHECK(r->applied);
    CHECK(r->config.limits.maxTurns == 9);
    // The same text in another project is another file for another place: not accepted there.
    write_file(other.path / ".factoria" / "ai" / "settings.json", read_file(s.settings_path()));
    auto there = resolve_ai_config(other.str(), s.ai, kNoEnv);
    REQUIRE(there);
    CHECK_FALSE(there->applied);
    CHECK(there->pendingTrust);
    // Line endings do not change the hash (a Windows checkout of the same file).
    const std::string lf = read_file(s.settings_path());
    std::string crlf;
    for (char c : lf) crlf += c == '\n' ? std::string("\r\n") : std::string(1, c);
    write_file(s.settings_path(), crlf);
    auto windows = s.resolve();
    REQUIRE(windows);
    CHECK(windows->applied);
    CHECK(windows->fileHash == r->fileHash);
    CHECK(windows->config.limits.maxTurns == 9);
    // The trust lives next to ai.json and is a record apart from the extensions'.
    const std::string trust = extensions_trust_path(s.ai);
    CHECK(project_ai_settings_trusted(trust, s.proj.str(), r->fileHash, nullptr, false));
    CHECK_FALSE(project_ai_settings_trusted(trust, other.str(), r->fileHash, nullptr, false));
    CHECK_FALSE(project_ai_settings_trusted("", s.proj.str(), r->fileHash));
    CHECK_FALSE(project_ai_settings_trusted(trust, s.proj.str(), ""));
    REQUIRE(trust_project_extensions(trust, s.proj.str(), "h1"));  // the extensions' record does not remove it
    CHECK(project_ai_settings_trusted(trust, s.proj.str(), r->fileHash));
    REQUIRE(forget_project_trust(trust, s.proj.str()));
    CHECK(project_ai_settings_trusted(trust, s.proj.str(), r->fileHash));
    CHECK_FALSE(trust_project_ai_settings(trust, s.proj.str(), ""));
#if defined(_WIN32) || defined(__APPLE__)
    // Paths there ignore case: the same folder spelled another way is the same project.
    std::string shouty = s.proj.str();
    std::transform(shouty.begin(), shouty.end(), shouty.begin(), [](unsigned char c) { return static_cast<char>(std::toupper(c)); });
    CHECK(ai_settings_trust_key(shouty) == ai_settings_trust_key(s.proj.str()));
#endif
}

TEST_CASE("project settings: the writer keeps only what differs from the inherited value") {
    Setup s;
    // 30 is what ai.json says, 180 what the engine says: neither is written. Nothing left: no file.
    REQUIRE(s.save(Json::parse(R"({"limits": {"maxTurns": 30, "stuckAfterSeconds": 180}, "savers": {"loopGuard": true}})")));
    CHECK_FALSE(fsys::exists(s.settings_path()));
    REQUIRE(s.save(Json::parse(R"({"limits": {"maxTurns": 30, "maxCostUsd": 2}, "roles": {"worker": {"model": "sonnet", "effort": "low"}}})")));
    const Json written = Json::parse(read_file(s.settings_path()));
    CHECK(written == Json::parse(R"({"roles": {"worker": {"effort": "low"}}, "limits": {"maxCostUsd": 2}})"));
    // The same save again is the same file; an empty object removes it.
    REQUIRE(s.save(written));
    CHECK(Json::parse(read_file(s.settings_path())) == written);
    REQUIRE(s.save(Json::object()));
    CHECK_FALSE(fsys::exists(s.settings_path()));
    CHECK_FALSE(project_ai_settings_trusted(extensions_trust_path(s.ai), s.proj.str(), "x", nullptr, false));
    // An invalid file is refused and nothing is written.
    CHECK_FALSE(s.save(Json::parse(R"({"mcpServers": {"scenario": {"url": "http://x"}}})")));
    CHECK_FALSE(s.save(Json::parse(R"({"roles": {"worker": {"provider": "nope"}}})")));
    CHECK_FALSE(s.save(Json::parse(R"({"roles": {"orchestrator": {"enabled": false}}})")));
    CHECK_FALSE(fsys::exists(s.settings_path()));
    CHECK_FALSE(save_project_settings("", Json::object(), s.ai, kNoEnv));
    // A provider that differs keeps its model and effort even when they equal the inherited ones.
    REQUIRE(s.save(Json::parse(R"({"roles": {"worker": {"provider": "openrouter", "model": "sonnet"}}})")));
    CHECK(Json::parse(read_file(s.settings_path()))["roles"]["worker"]["model"] == "sonnet");
    CHECK(s.load()->role("worker").model == "sonnet");
}

TEST_CASE("project settings: project_overrides_from gives the difference, and reset removes one override") {
    Setup s;
    auto user = load_config(s.ai, kNoEnv);
    REQUIRE(user);
    AiConfig wanted = *user;
    wanted.limits.maxCostUsd = 3;
    wanted.savers.projectFacts = false;
    wanted.roles["artist"].enabled = false;
    const Json ov = project_overrides_from(wanted, *user);
    CHECK(ov == Json::parse(R"({"roles": {"artist": {"enabled": false}}, "limits": {"maxCostUsd": 3}, "savers": {"projectFacts": false}})"));
    CHECK(project_overrides_from(*user, *user).empty());
    // A role that moves to another provider carries its model and effort.
    AiConfig moved = *user;
    moved.roles["worker"].provider = "openrouter";
    moved.roles["worker"].model = "x/y";
    moved.roles["worker"].effort = "high";
    const Json mv = project_overrides_from(moved, *user);
    CHECK(mv["roles"]["worker"]["provider"] == "openrouter");
    CHECK(mv["roles"]["worker"]["model"] == "x/y");
    REQUIRE(s.save(ov));
    auto r = s.resolve();
    REQUIRE(r);
    CHECK(settings_view(r->config) == settings_view(wanted));

    REQUIRE(reset_project_setting(s.proj.str(), "/limits/maxCostUsd", s.ai, kNoEnv));
    CHECK(Json::parse(read_file(s.settings_path())) == Json::parse(R"({"roles": {"artist": {"enabled": false}}, "savers": {"projectFacts": false}})"));
    CHECK(s.resolve()->applied);  // the file was accepted before: the smaller one is too
    REQUIRE(reset_project_setting(s.proj.str(), "/roles", s.ai, kNoEnv));
    REQUIRE(reset_project_setting(s.proj.str(), "/savers/projectFacts", s.ai, kNoEnv));
    CHECK_FALSE(fsys::exists(s.settings_path()));  // nothing left: the file goes
    REQUIRE(reset_project_setting(s.proj.str(), "/limits/maxTurns", s.ai, kNoEnv));  // nothing to remove is fine
    CHECK_FALSE(reset_project_setting(s.proj.str(), "limits", s.ai, kNoEnv));
    // Resetting a provider resets what follows it.
    REQUIRE(s.save(mv));
    REQUIRE(reset_project_setting(s.proj.str(), "/roles/worker/provider", s.ai, kNoEnv));
    CHECK_FALSE(fsys::exists(s.settings_path()));
    // Resetting a file that was not accepted does not accept it.
    s.copy_in(R"({"limits": {"maxTurns": 5, "maxCostUsd": 1}})");
    REQUIRE(reset_project_setting(s.proj.str(), "/limits/maxCostUsd", s.ai, kNoEnv));
    auto still = s.resolve();
    REQUIRE(still);
    CHECK(still->pendingTrust);
    CHECK_FALSE(still->applied);
}

TEST_CASE("project settings: asset routes are named from the user's providers") {
    Setup s;
    // ai.json has no route for images: the project must name the provider.
    CHECK(has(s.error_of(R"({"assets": {"image": {"model": "x"}}})"), "must name the provider"));
    REQUIRE(s.save(Json::parse(R"({"assets": {"image": {"provider": "openrouter", "model": "gpt-image-1"}}})")));
    auto cfg = s.load();
    REQUIRE(cfg);
    REQUIRE(cfg->assets.count("image"));
    CHECK(cfg->assets.at("image").provider == "openrouter");
    CHECK(cfg->assets.at("image").model == "gpt-image-1");
    auto r = s.resolve();
    REQUIRE(r);
    CHECK(r->source_of("/assets/image/provider") == SettingSource::Project);
    // A provider that cannot make that kind is refused by the same rule ai.json has.
    CHECK_FALSE(s.save(Json::parse(R"({"assets": {"model3d": {"provider": "openrouter"}}})")));
}

TEST_CASE("project settings: a friend's file naming a provider you lack does not stop you, an accepted one that turned invalid does") {
    Setup s;
    // Came inside a copied project: names a provider this computer has no entry for.
    s.copy_in(R"({"roles": {"worker": {"provider": "friends-gateway"}}, "limits": {"maxTurns": 3}})");
    auto r = s.resolve();
    REQUIRE(r);
    CHECK(r->fileExists);
    CHECK_FALSE(r->applied);
    CHECK(r->pendingTrust);
    CHECK(r->pending.empty());
    REQUIRE(r->invalidError.has_value());
    CHECK(has(r->invalidError->message, "no provider named 'friends-gateway'"));
    CHECK(has(r->invalidError->message, "/roles/worker/provider"));
    CHECK(has(r->invalidError->message, s.settings_path()));
    CHECK_FALSE(r->invalidError->hint.empty());
    CHECK(settings_view(r->config) == settings_view(r->inherited));  // nothing of the file, not even the valid limit
    CHECK(r->config.limits.maxTurns == 30);
    const bool warned = std::any_of(r->config.warnings.begin(), r->config.warnings.end(), [&](const std::string& w) {
        return has(w, s.settings_path()) && has(w, "no effect") && has(w, "friends-gateway");
    });
    CHECK(warned);
    auto loaded = s.load();  // what every runtime path reads: it runs
    REQUIRE(loaded);
    CHECK(loaded->limits.maxTurns == 30);
    CHECK_FALSE(fsys::exists(fsys::path(extensions_trust_path(s.ai))));  // none of this wrote ai-trust.json
    CHECK_FALSE(accept_project_settings(s.proj.str(), "", s.ai, kNoEnv));

    // The user's own file, accepted, then ai.json changes so the file names something that is gone: that is an error to see.
    Setup t;
    REQUIRE(t.save(Json::parse(R"({"mcpServers": {"scenario": false}})")));
    REQUIRE(t.resolve());
    CHECK(t.resolve()->applied);
    write_file(t.ai, R"({"limits": {"maxTurns": 30}})");  // the tool server 'scenario' is no longer defined
    auto gone = t.resolve();
    REQUIRE_FALSE(gone);
    CHECK(has(gone.error().message, "no tool server named 'scenario'"));
    CHECK_FALSE(t.load());
}

TEST_CASE("project settings: reading never writes ai-trust.json, and save does not accept unless told to") {
    Setup s;
    const std::string trust = extensions_trust_path(s.ai);
    REQUIRE(s.save(Json::parse(R"({"limits": {"maxTurns": 9}})")));
    const std::string before = read_file(trust);
    REQUIRE_FALSE(before.empty());
    s.copy_in(R"({"limits": {"maxTurns": 8}})");  // the file changed since the acceptance
    CHECK_FALSE(s.resolve()->applied);
    CHECK_FALSE(s.load()->limits.maxTurns == 8);
    CHECK(read_file(trust) == before);
    // A reset of a file that is not accepted reads the trust and does not add to it.
    s.copy_in(R"({"limits": {"maxTurns": 8, "maxCostUsd": 1}})");
    REQUIRE(reset_project_setting(s.proj.str(), "/limits/maxCostUsd", s.ai, kNoEnv));
    CHECK(read_file(trust) == before);

    // The default of the writer: saved, but not accepted. A second save without the flag over an accepted file un-accepts it.
    Setup t;
    REQUIRE(save_project_settings(t.proj.str(), Json::parse(R"({"limits": {"maxTurns": 4}})"), t.ai, kNoEnv));
    auto r = t.resolve();
    REQUIRE(r);
    CHECK(r->fileExists);
    CHECK_FALSE(r->applied);
    CHECK(r->pendingTrust);
    CHECK(r->config.limits.maxTurns == 30);
    CHECK_FALSE(fsys::exists(fsys::path(extensions_trust_path(t.ai))));
    REQUIRE(accept_project_settings(t.proj.str(), r->fileHash, t.ai, kNoEnv));
    CHECK(t.resolve()->config.limits.maxTurns == 4);
    REQUIRE(t.save(Json::parse(R"({"limits": {"maxTurns": 5}})"), false));
    CHECK_FALSE(t.resolve()->applied);
}

TEST_CASE("project settings: what an untrusted file says is printed with its control characters escaped") {
    Setup s;
    const std::string err = s.error_of("{\"limit\\u001b[2Js\": {}}");
    REQUIRE_FALSE(err.empty());
    CHECK(err.find('\x1b') == std::string::npos);
    CHECK(has(err, "\\x1b"));
    CHECK(escape_control_chars(std::string("a\x1b[31mb\x7f\n\tc")) == "a\\x1b[31mb\\x7f\n\tc");
    // The same in the pointer of a change.
    SettingChange c{"/roles/a\x1b", Json(nullptr), Json(1)};
    CHECK(c.text().find('\x1b') == std::string::npos);
}

TEST_CASE("project settings: a pointer that is not valid JSON pointer syntax is an error, not an exception") {
    Setup s;
    REQUIRE(s.save(Json::parse(R"({"limits": {"maxCostUsd": 2}})")));
    Result<void> bad = make_error("unset");
    CHECK_NOTHROW(bad = reset_project_setting(s.proj.str(), "/a~2", s.ai, kNoEnv));
    REQUIRE_FALSE(bad);
    CHECK(has(bad.error().message, "not a valid JSON pointer"));
    CHECK(has(bad.error().hint, "~0"));
    CHECK(fsys::exists(s.settings_path()));  // untouched
}

TEST_CASE("project settings: resolve_ai_config_over applies the file on a config in memory, as the file on disk would") {
    Setup s;
    const std::string overrides = R"({"limits": {"maxCostUsd": 4}, "roles": {"orchestrator": {"provider": "openrouter", "model": "x/y"},
                                                                          "worker": {"enabled": false}}, "mcpServers": {"scenario": false}})";
    REQUIRE(s.save(Json::parse(overrides)));
    auto disk = s.resolve();
    REQUIRE(disk);
    REQUIRE(disk->applied);
    auto user = load_config(s.ai, kNoEnv);
    REQUIRE(user);
    auto mem = resolve_ai_config_over(s.proj.str(), *user, s.ai, kNoEnv);
    REQUIRE(mem);
    CHECK(mem->applied);
    CHECK(settings_view(mem->config) == settings_view(disk->config));
    CHECK(mem->config.role("artist").provider == "openrouter");  // follows the orchestrator, as on disk
    CHECK(mem->source_of("/limits/maxCostUsd") == SettingSource::Project);
    // The config in memory is the source for the user's side: an unsaved edit of the editor shows through.
    AiConfig edited = *user;
    edited.limits.maxTurns = 11;
    edited.limits.stuckAfterSeconds = 60;
    auto over = resolve_ai_config_over(s.proj.str(), edited, s.ai, kNoEnv);
    REQUIRE(over);
    CHECK(over->applied);
    CHECK(over->config.limits.maxTurns == 11);
    CHECK(over->config.limits.stuckAfterSeconds == 60);
    CHECK(over->config.limits.maxCostUsd == 4);
    CHECK(over->inherited.limits.maxTurns == 11);
    // A role the user turned off in memory stays off; nothing but the sourcePath of the user's file locates the trust.
    AiConfig artistOff = *user;
    artistOff.roles["artist"].enabled = false;
    auto off = resolve_ai_config_over(s.proj.str(), artistOff, "", kNoEnv);
    REQUIRE(off);
    CHECK_FALSE(off->config.role_enabled("artist"));
    // No project: the config comes back as it is. No file: the same.
    auto none = resolve_ai_config_over("", edited, s.ai, kNoEnv);
    REQUIRE(none);
    CHECK(settings_view(none->config) == settings_view(edited));
    TempDir bare;
    auto nofile = resolve_ai_config_over(bare.str(), edited, s.ai, kNoEnv);
    REQUIRE(nofile);
    CHECK_FALSE(nofile->fileExists);
    CHECK(settings_view(nofile->config) == settings_view(edited));
    // An invalid file that is not accepted is reported the same way.
    Setup bad;
    bad.copy_in(R"({"roles": {"worker": {"provider": "nope"}}})");
    auto badr = resolve_ai_config_over(bad.proj.str(), *user, bad.ai, kNoEnv);
    REQUIRE(badr);
    CHECK(badr->invalidError.has_value());
    CHECK(settings_view(badr->config) == settings_view(*user));
}

TEST_CASE("project settings: an invalid ai.json is the user's error, not the project's") {
    Setup s;
    write_file(s.ai, "{ nope");
    s.copy_in(R"({"limits": {"maxTurns": 5}})");
    auto r = s.resolve();
    REQUIRE_FALSE(r);
    CHECK(has(r.error().message, s.ai));
}

TEST_CASE("project settings: the asset cost limits are nested, merge leaf by leaf with the user's, and an AI-written file waits for acceptance") {
    Setup s;
    // the user's own ai.json asks for a per-day limit
    write_file(s.ai, R"({"limits": {"maxAssetCostUsd": {"perDay": 5}, "askAboveUsd": 0.25}})");
    REQUIRE(s.save(Json::parse(R"({"limits": {"maxAssetCostUsd": {"perRun": 1.5}}})")));
    auto r = s.resolve();
    REQUIRE(r);
    CHECK(r->config.limits.maxAssetCostPerRunUsd == doctest::Approx(1.5));  // the project's
    CHECK(r->config.limits.maxAssetCostPerDayUsd == doctest::Approx(5));    // the user's, untouched by the project's perRun
    CHECK(r->config.limits.askAboveUsd == doctest::Approx(0.25));
    CHECK(r->source_of("/limits/maxAssetCostUsd/perRun") == SettingSource::Project);
    CHECK(r->source_of("/limits/maxAssetCostUsd/perDay") == SettingSource::You);
    CHECK(r->source_of("/limits/askAboveUsd") == SettingSource::You);

    // a wrong value names its pointer
    const std::string err = s.error_of(R"({"limits": {"maxAssetCostUsd": {"perRun": -2}}})");
    CHECK(has(err, "/limits/maxAssetCostUsd/perRun"));
    CHECK(has(s.error_of(R"({"limits": {"maxAssetCostUsd": {"perDays": 2}}})"), "Did you mean 'perDay'"));
}
