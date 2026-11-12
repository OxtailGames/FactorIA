// What each AI role may do (role_capabilities): the sets, the tools a role is offered, the refusal of a call outside the set and
// the environment that carries the set to the factoria a CLI agent starts.
#include <map>

#include "fa/ai/cli_agent.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

bool contains(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

std::vector<std::string> tool_names(const std::vector<ToolDef>& tools) {
    std::vector<std::string> out;
    for (const auto& t : tools) out.push_back(t.name);
    return out;
}

// scene.save (edits the project), the two filmstrips (one PNG under .factoria/: writeProject, so not readOnly) and
// "scene.export_anywhere", which writes outside the project (writeAnywhere). `ran` counts the handlers that ran, by command name.
CommandRegistry capability_registry(std::map<std::string, int>& ran) {
    CommandRegistry r;
    auto add = [&](const char* name, bool readOnly, CapabilitySet caps) {
        CommandInfo c;
        c.name = name;
        c.summary = name;
        c.readOnly = readOnly;
        c.capabilities = caps;
        const std::string n = name;
        r.add(c, [&ran, n](const Json&) {
            ++ran[n];
            return Json::object();
        });
    };
    add("scene.save", false, {});  // derived: read, state, writeProject
    add("scene.list_entities", true, {});
    add("anim.filmstrip", false, CapabilitySet{Capability::Read, Capability::WriteProject});
    add("vfx.filmstrip", false, CapabilitySet{Capability::Read, Capability::WriteProject});
    add("scene.export_anywhere", false, CapabilitySet{Capability::Read, Capability::WriteAnywhere});
    return r;
}

const CommandInfo* info_of(const CommandRegistry& reg, const char* name) {
    for (const CommandInfo* i : reg.list())
        if (i->name == name) return i;
    return nullptr;
}

}  // namespace

TEST_CASE("role capabilities: builders get the agent set, the critics only look and play, none ever more than that") {
    for (const char* role : {kRoleOrchestrator, kRoleWorker, kRoleFast, kRoleArtist, kRoleAudio})
        CHECK_MESSAGE(role_capabilities(role) == capability_sets::agent(), role);
    for (const char* role : {kRoleArtCritic, kRoleReviewer}) {
        const CapabilitySet set = role_capabilities(role);
        CHECK(set == CapabilitySet({Capability::Read, Capability::State, Capability::WriteProject}));
        for (Capability c : {Capability::WriteAnywhere, Capability::Network, Capability::Process, Capability::Spend, Capability::Publish})
            CHECK_FALSE(set.has(c));
    }
    CHECK(role_capabilities("nobody") == role_capabilities(kRoleReviewer));  // what cannot be read is not widened
    CHECK_FALSE(role_capabilities(kRoleWorker).has(Capability::WriteAnywhere));
    CHECK_FALSE(role_capabilities(kRoleWorker).has(Capability::Publish));
    // the words of a refusal name the role and say what to do
    CHECK(role_denial_subject(kRoleReviewer).find("Reviewer") != std::string::npos);
    CHECK(role_denial_hint(kRoleReviewer).find("{command}") != std::string::npos);
    CHECK(role_denial_hint(kRoleReviewer).find("builder role") != std::string::npos);
    CHECK(role_denial_hint(kRoleWorker).find("Ask the user") != std::string::npos);
    CHECK(role_denial_subject("nobody").empty());
}

TEST_CASE("role capabilities: the filmstrips are play tools, scene.save is not, and a play tool must fit the critics' set") {
    std::map<std::string, int> ran;
    CommandRegistry reg = capability_registry(ran);
    for (const char* name : {"anim.filmstrip", "vfx.filmstrip"}) CHECK_MESSAGE(is_read_only_tool(*info_of(reg, name)), name);
    CHECK_FALSE(is_read_only_tool(*info_of(reg, "scene.save")));
    CHECK_FALSE(is_read_only_tool(*info_of(reg, "scene.export_anywhere")));
    const auto ro = tool_names(tools_from_registry(reg, false, true));
    CHECK(contains(ro, "anim_filmstrip"));
    CHECK(contains(ro, "vfx_filmstrip"));
    CHECK_FALSE(contains(ro, "scene_save"));
    const auto rev = cli_disallowed_tools(reg, kRoleReviewer, false);
    CHECK_FALSE(contains(rev, "mcp__factoria__anim_filmstrip"));
    CHECK_FALSE(contains(rev, "mcp__factoria__vfx_filmstrip"));
    CHECK(contains(rev, "mcp__factoria__scene_save"));
    // A play command that declares more than the critics may do (a process) is not a play command, whatever its name.
    CommandRegistry other;
    CommandInfo c;
    c.name = "anim.filmstrip";
    c.summary = "x";
    c.readOnly = false;
    c.capabilities = CapabilitySet{Capability::Read, Capability::Process};
    other.add(c, [](const Json&) { return Json::object(); });
    CHECK_FALSE(is_read_only_tool(*info_of(other, "anim.filmstrip")));
}

TEST_CASE("role capabilities: a CLI role is told to switch off what its set does not cover, builders included") {
    std::map<std::string, int> ran;
    CommandRegistry reg = capability_registry(ran);
    const auto worker = cli_disallowed_tools(reg, kRoleWorker, false);
    CHECK(contains(worker, "mcp__factoria__scene_export_anywhere"));  // writeAnywhere: the user's, not the agent's
    CHECK_FALSE(contains(worker, "mcp__factoria__scene_save"));
    CHECK_FALSE(contains(worker, "Edit"));
}

TEST_CASE("role capabilities: a reviewer run cannot call scene.save, a worker run can but not a writeAnywhere command") {
    std::map<std::string, int> ran;
    CommandRegistry reg = capability_registry(ran);

    auto run_role = [&](const char* role, const std::vector<const char*>& toolNames) {
        TempDir dir;
        auto provider = std::make_shared<FakeProvider>();
        std::vector<ToolCall> calls;
        int n = 0;
        for (const char* t : toolNames) {
            ToolCall c;
            c.id = "t" + std::to_string(++n);
            c.name = t;
            calls.push_back(c);
        }
        provider->script = {tool_response(calls), text_response("Done.\n```json\n{\"score\":6}\n```")};
        AiConfig cfg = default_config();
        SessionOptions so;
        so.projectDir = dir.str();
        so.role = role;
        so.allowDelegation = false;
        AgentSession s(reg, cfg, so);
        s.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        });
        const auto result = s.run("go");
        CHECK(result.ok);
        return provider;
    };

    {  // the reviewer: scene_save is not even offered, and the forced call is refused and does not run
        auto p = run_role(kRoleReviewer, {"scene_save"});
        REQUIRE(p->requests.size() == 2);
        CHECK_FALSE(contains(tool_names(p->requests[0].tools), "scene_save"));
        REQUIRE(p->requests[1].messages.back().toolResults.size() == 1);
        CHECK(p->requests[1].messages.back().toolResults[0].isError);
        CHECK(ran["scene.save"] == 0);
    }
    {  // the worker: scene.save runs, the writeAnywhere command is not offered and the forced call does not run
        auto p = run_role(kRoleWorker, {"scene_save", "scene_export_anywhere"});
        REQUIRE(p->requests.size() == 2);
        const auto offered = tool_names(p->requests[0].tools);
        CHECK(contains(offered, "scene_save"));
        CHECK_FALSE(contains(offered, "scene_export_anywhere"));
        const auto& results = p->requests[1].messages.back().toolResults;
        REQUIRE(results.size() == 2);
        CHECK_FALSE(results[0].isError);
        CHECK(results[1].isError);
        CHECK(ran["scene.save"] == 1);
        CHECK(ran["scene.export_anywhere"] == 0);
    }
}

TEST_CASE("role capabilities: the scope a tool call runs in refuses with the role's name, even for a command offered by mistake") {
    std::map<std::string, int> ran;
    CommandRegistry reg = capability_registry(ran);
    for (const char* role : {kRoleReviewer, kRoleWorker}) {
        CommandCallerScope caller(CommandCaller::Agent);
        CommandCapabilityScope caps(role_capabilities(role));
        CommandDenialScope denial(role_denial_subject(role), role_denial_hint(role));
        const CommandResult r = reg.call("scene.export_anywhere");
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "capability_denied");
        CHECK(r.error["message"].get<std::string>().find(role_denial_subject(role)) != std::string::npos);
        CHECK(r.error["hint"].get<std::string>().find("scene.export_anywhere") != std::string::npos);
        CHECK(r.error["hint"].get<std::string>().find("the user") != std::string::npos);
    }
    {
        CommandCallerScope caller(CommandCaller::Agent);
        CommandCapabilityScope caps(role_capabilities(kRoleWorker));
        CHECK(reg.call("scene.save").ok);  // a builder saves
    }
    CHECK(ran["scene.export_anywhere"] == 0);
}

TEST_CASE("role capabilities: cli_capability_env narrows by the calling thread, the provider's own value and the process, never widens") {
    CliRunRequest req;
    req.role = kRoleReviewer;
    req.capabilities = role_capabilities(kRoleReviewer);
    auto env = cli_capability_env(req, {}, CapabilitySet::all());
    CHECK(*command_capabilities_from_env_value(env[kCapabilitiesEnvVar].c_str()) == role_capabilities(kRoleReviewer));
    CHECK(env[kRoleEnvVar] == kRoleReviewer);
    CHECK(env.count(kCallerEnvVar) == 1);
    // the thread that starts the run may itself be narrower (a read-only MCP client calling ai_run)
    env = cli_capability_env(req, {}, CapabilitySet{Capability::Read});
    CHECK(*command_capabilities_from_env_value(env[kCapabilitiesEnvVar].c_str()) == CapabilitySet{Capability::Read});
    // a provider "env" that already limits it is kept
    env = cli_capability_env(req, {{kCapabilitiesEnvVar, "read,state"}}, CapabilitySet::all());
    CHECK(*command_capabilities_from_env_value(env[kCapabilitiesEnvVar].c_str()) == CapabilitySet({Capability::Read, Capability::State}));
    // ... and one that cannot be read closes it
    env = cli_capability_env(req, {{kCapabilitiesEnvVar, "wirteProject"}}, CapabilitySet::all());
    CHECK(env[kCapabilitiesEnvVar] == "none");
    // a builder never gets what the agent set lacks, whatever the request says
    CliRunRequest builder;
    builder.role = kRoleWorker;
    builder.capabilities = CapabilitySet::all();
    env = cli_capability_env(builder, {}, capability_sets::agent());
    CHECK(*command_capabilities_from_env_value(env[kCapabilitiesEnvVar].c_str()) == capability_sets::agent());
}

TEST_CASE("role capabilities: the factoria server of the MCP config and Codex's arguments carry the floor") {
    const std::map<std::string, std::string> env = {{kCapabilitiesEnvVar, "read,state"}, {kRoleEnvVar, "reviewer"}};
    const Json stdio = make_mcp_config("/proj", "factoria", {}, {}, env);
    CHECK(stdio["mcpServers"]["factoria"]["env"][kCapabilitiesEnvVar] == "read,state");
    CHECK(stdio["mcpServers"]["factoria"]["env"][kRoleEnvVar] == "reviewer");
    const Json http = make_mcp_config("/proj", "factoria", "http://127.0.0.1:1/mcp/token", {}, env);  // the editor's endpoint enforces it itself
    CHECK_FALSE(http["mcpServers"]["factoria"].contains("env"));
    const Json none = make_mcp_config("/proj", "factoria");
    CHECK_FALSE(none["mcpServers"]["factoria"].contains("env"));

    const auto args = codex_factoria_env_args(env);
    REQUIRE(args.size() == 2);
    CHECK(args[0] == "-c");
    CHECK(args[1] == R"(mcp_servers.factoria.env={FACTORIA_CAPABILITIES="read,state",FACTORIA_ROLE="reviewer"})");
    CHECK(codex_factoria_env_args({}).empty());
}

namespace {
std::string env_value(const std::string& envDump, const std::string& name) {
    std::istringstream in(envDump);
    for (std::string line; std::getline(in, line);)
        if (line.rfind(name + "=", 0) == 0) return line.substr(name.size() + 1);
    return "<unset>";
}
}  // namespace

#ifndef _WIN32  // fake_claude.sh records its environment (FAKE_ENV_FILE is POSIX only)
TEST_CASE("role capabilities: the CLI agent of a reviewer starts with the reviewer's floor, a worker's with the agent set") {
    ProviderConfig cfg = default_config().providers["claude-code"];
    cfg.command = std::string(FA_AI_FIXTURES) + "/fake_claude.sh";
    TempDir scratch;
    const std::string envFile = (scratch.path / "env.txt").string();
    const std::string argvFile = (scratch.path / "argv.txt").string();
    cfg.env["FAKE_ENV_FILE"] = envFile;
    cfg.env["FAKE_ARGV_FILE"] = argvFile;

    for (const char* role : {kRoleReviewer, kRoleWorker}) {
        TempDir dir;
        CliRunRequest req{"Review it", "sonnet", dir.str()};
        req.role = role;
        req.capabilities = role_capabilities(role);
        req.readOnly = is_review_role(role);
        CliAgent agent(cfg);
        REQUIRE(agent.run(req, [](const AgentEvent&) {}, nullptr));
        const std::string seen = read_file(envFile);
        CHECK(env_value(seen, kCapabilitiesEnvVar) == capabilities_env_value(role_capabilities(role)));
        CHECK(env_value(seen, kRoleEnvVar) == role);
        // Claude Code starts the MCP server with a short environment: the floor is also in the server's own "env"
        const Json mcp = Json::parse(read_file(argvFile + ".mcpconfig"));
        CHECK(mcp["mcpServers"]["factoria"]["env"][kCapabilitiesEnvVar] == capabilities_env_value(role_capabilities(role)));
        CHECK(mcp["mcpServers"]["factoria"]["env"][kRoleEnvVar] == role);
    }
    CHECK(capabilities_env_value(role_capabilities(kRoleReviewer)).find("publish") == std::string::npos);
    CHECK(capabilities_env_value(role_capabilities(kRoleWorker)).find("writeAnywhere") == std::string::npos);
}
#endif
