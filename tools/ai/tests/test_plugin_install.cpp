// ai.plugin_install (plugin_install.h) against a fake Claude Code CLI script (never the real claude): the argv of each step, the
// steps skipped when already done, the dry run, the ai.json entry and the errors.
#ifndef _WIN32
#include <fstream>

#include "fa/ai/commands.h"
#include "fa/ai/plugin_install.h"
#include "fa/ai/session.h"
#include "fa/ai/tool_catalog.h"
#include "fa/core/fs.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;
namespace fsys = std::filesystem;

namespace {

void write_exec(const fsys::path& p, const std::string& text) {
    std::ofstream(p, std::ios::binary) << text;
    fsys::permissions(p, fsys::perms::owner_all, fsys::perm_options::add);
}

std::string slurp(const fsys::path& p) {
    std::ifstream f(p, std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(f), {});
}

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

struct FakeClaude {
    TempDir dir;
    FakeClaude() {
        const std::string d = dir.str();
        write_exec(dir.path / "claude",
                   "#!/bin/sh\n"
                   "D='" + d + "'\n"
                   "echo \"$*\" >> \"$D/argv.log\"\n"
                   "case \"$*\" in\n"
                   "  \"plugin marketplace list --json\") [ -f \"$D/nojson\" ] && exit 1; cat \"$D/marketplaces.json\" ;;\n"
                   "  \"plugin list --json\") [ -f \"$D/nojson\" ] && exit 1; cat \"$D/plugins.json\" ;;\n"
                   "  \"plugin marketplace list\") [ -f \"$D/listfails\" ] && { echo 'unknown command' >&2; exit 2; }; cat \"$D/marketplaces.txt\" ;;\n"
                   "  \"plugin list\") cat \"$D/plugins.txt\" ;;\n"
                   "  \"plugin marketplace add \"*) [ -f \"$D/fail_add\" ] && { echo 'fatal: repository not found' >&2; exit 3; }\n"
                   "     echo '[{\"name\":\"tokeneconomizer\",\"source\":\"github\",\"repo\":\"microsoft/TokenEconomizer\"}]' > \"$D/marketplaces.json\"; echo added ;;\n"
                   "  \"plugin install \"*) [ -f \"$D/fail_install\" ] && { echo 'plugin not found' >&2; exit 4; }\n"
                   "     echo '[{\"id\":\"tokeneconomizer@tokeneconomizer\",\"version\":\"1.0\"}]' > \"$D/plugins.json\"; echo installed ;;\n"
                   "  *) echo \"unexpected: $*\" >&2; exit 9 ;;\n"
                   "esac\n");
        write_exec(dir.path / "py_new", "#!/bin/sh\necho 'Python 3.12.1'\n");
        write_exec(dir.path / "py_old", "#!/bin/sh\necho 'Python 3.8.10'\n");
        std::ofstream(dir.path / "marketplaces.json") << "[]";
        std::ofstream(dir.path / "plugins.json") << "[]";
    }
    std::string claude() const { return (dir.path / "claude").string(); }
    std::string log() const { return slurp(dir.path / "argv.log"); }
    void touch(const char* name) const { std::ofstream(dir.path / name) << "x"; }
    PluginInstallHooks hooks(bool oldPython = false) const {
        PluginInstallHooks h;
        h.pythonCommands = {(dir.path / (oldPython ? "py_old" : "py_new")).string()};
        return h;
    }
};

struct Setup {
    FakeClaude cli;
    TempDir home;
    std::string aiJson;
    Setup() {
        aiJson = (home.path / "ai.json").string();
        std::ofstream(aiJson) << R"({"limits":{"maxTurns":7},"extensions":{"skills":{"gdd":{"path":"~/skills/gdd"}}}})";
    }
    AiConfig config() const {
        auto cfg = load_config(aiJson);
        REQUIRE(cfg);
        AiConfig c = *cfg;
        c.providers["claude-code"].command = cli.claude();
        return c;
    }
};

}  // namespace

TEST_CASE("plugin_install: python_version_at_least compares major and minor") {
    CHECK(python_version_at_least("3.12.1", "3.10"));
    CHECK(python_version_at_least("3.10", "3.10"));
    CHECK(python_version_at_least("4.0", "3.10"));
    CHECK_FALSE(python_version_at_least("3.9.18", "3.10"));
    CHECK_FALSE(python_version_at_least("2.7.18", "3.10"));
    CHECK_FALSE(python_version_at_least("", "3.10"));
}

TEST_CASE("plugin_install: dry run lists the commands and what is needed, and changes nothing") {
    Setup s;
    PluginInstallRequest req = token_economizer_request();
    req.dryRun = true;
    auto r = plugin_install(s.config(), req, s.cli.hooks());
    REQUIRE(r);
    CHECK((*r)["ok"] == true);
    CHECK((*r)["dryRun"] == true);
    REQUIRE((*r)["steps"].size() == 3);
    const Json& market = (*r)["steps"][0];
    CHECK(market["id"] == "marketplace");
    CHECK(market["needed"] == true);
    CHECK(market["status"] == "would_run");
    CHECK(market["command"][1] == "plugin");
    CHECK(market["command"][4] == "microsoft/TokenEconomizer");
    CHECK((*r)["steps"][1]["command"][3] == "tokeneconomizer@tokeneconomizer");
    CHECK((*r)["steps"][2]["id"] == "entry");
    CHECK((*r)["python"]["ok"] == true);
    CHECK((*r)["python"]["version"] == "3.12.1");
    const std::string log = s.cli.log();
    CHECK_FALSE(has(log, "marketplace add"));
    CHECK_FALSE(has(log, "plugin install"));
    CHECK_FALSE(has(slurp(s.aiJson), "tokeneconomizer"));
}

TEST_CASE("plugin_install: runs the CLI's own commands in order and adds the ai.json entry, keeping the other keys") {
    Setup s;
    PluginInstallRequest req = token_economizer_request();
    req.roles = {"orchestrator", "worker"};
    std::vector<std::string> seen;
    PluginInstallHooks hooks = s.cli.hooks();
    hooks.onStep = [&](const Json& step) { seen.push_back(step["id"].get<std::string>() + ":" + step["status"].get<std::string>()); };
    auto r = plugin_install(s.config(), req, hooks);
    REQUIRE(r);
    CHECK((*r)["entry"]["added"] == true);
    const std::string log = s.cli.log();
    const auto addAt = log.find("plugin marketplace add microsoft/TokenEconomizer");
    const auto installAt = log.find("plugin install tokeneconomizer@tokeneconomizer");
    REQUIRE(addAt != std::string::npos);
    REQUIRE(installAt != std::string::npos);
    CHECK(addAt < installAt);
    CHECK(seen == std::vector<std::string>{"marketplace:running", "marketplace:done", "plugin:running", "plugin:done", "entry:running",
                                           "entry:done"});
    auto after = load_config(s.aiJson);
    REQUIRE(after);
    CHECK(after->limits.maxTurns == 7);  // the other keys stay
    const auto it = std::ranges::find_if(after->extensions.entries, [](const Extension& e) { return e.plugin == "tokeneconomizer@tokeneconomizer"; });
    REQUIRE(it != after->extensions.entries.end());
    CHECK(it->name == "tokeneconomizer");
    CHECK(it->roles == std::vector<std::string>{"orchestrator", "worker"});
    CHECK(std::ranges::any_of(after->extensions.entries, [](const Extension& e) { return e.name == "gdd"; }));

    // Again: everything is done, so nothing runs and the entry is not duplicated.
    auto again = plugin_install(*after, req, s.cli.hooks());
    REQUIRE(again);
    CHECK((*again)["entry"]["added"] == false);
    for (const Json& st : (*again)["steps"]) CHECK(st["status"] == "skipped");
    CHECK(s.cli.log().find("marketplace add", addAt + 40) == std::string::npos);
    int entries = 0;
    const auto finalCfg = load_config(s.aiJson);
    REQUIRE(finalCfg);
    for (const Extension& e : finalCfg->extensions.entries) entries += e.plugin == "tokeneconomizer@tokeneconomizer";
    CHECK(entries == 1);
}

TEST_CASE("plugin_install: a marketplace that is already listed is not added again; an installed plugin runs nothing") {
    Setup s;
    std::ofstream(s.cli.dir.path / "marketplaces.json") << R"([{"name":"tokeneconomizer","repo":"microsoft/TokenEconomizer"}])";
    auto r = plugin_install(s.config(), token_economizer_request(), s.cli.hooks());
    REQUIRE(r);
    CHECK((*r)["steps"][0]["status"] == "skipped");
    CHECK((*r)["steps"][1]["status"] == "done");
    CHECK_FALSE(has(s.cli.log(), "marketplace add"));
    CHECK(has(s.cli.log(), "plugin install tokeneconomizer@tokeneconomizer"));

    // Installed (as the CLI's plain listing says it, no --json): only the entry is added, and no Python is needed.
    Setup t;
    t.cli.touch("nojson");
    std::ofstream(t.cli.dir.path / "marketplaces.txt") << "  tokeneconomizer (github: microsoft/TokenEconomizer)\n";
    std::ofstream(t.cli.dir.path / "plugins.txt") << "  tokeneconomizer@tokeneconomizer  v1.0  enabled\n";
    auto only = plugin_install(t.config(), token_economizer_request(), t.cli.hooks(true));
    REQUIRE(only);
    CHECK((*only)["steps"][0]["status"] == "skipped");
    CHECK((*only)["steps"][1]["status"] == "skipped");
    CHECK((*only)["steps"][2]["status"] == "done");
    CHECK_FALSE(has(t.cli.log(), "marketplace add"));
    CHECK_FALSE(has(t.cli.log(), "plugin install"));
}

TEST_CASE("plugin_install: errors name the step, what the CLI said and the fix, and leave ai.json alone") {
    SUBCASE("the marketplace cannot be added") {
        Setup s;
        s.cli.touch("fail_add");
        auto r = plugin_install(s.config(), token_economizer_request(), s.cli.hooks());
        REQUIRE_FALSE(r);
        CHECK(has(r.error().message, "adding the marketplace microsoft/TokenEconomizer failed"));
        CHECK(has(r.error().message, "exit code 3"));
        CHECK(has(r.error().message, "repository not found"));
        CHECK(has(r.error().hint, "plugin marketplace add microsoft/TokenEconomizer"));
        CHECK_FALSE(has(slurp(s.aiJson), "tokeneconomizer"));
    }
    SUBCASE("the plugin cannot be installed: the finished step is reported, no entry is written") {
        Setup s;
        s.cli.touch("fail_install");
        auto r = plugin_install(s.config(), token_economizer_request(), s.cli.hooks());
        REQUIRE_FALSE(r);
        CHECK(has(r.error().message, "installing tokeneconomizer@tokeneconomizer failed"));
        CHECK(has(r.error().message, "Done before: adding the marketplace"));
        CHECK_FALSE(has(slurp(s.aiJson), "tokeneconomizer"));
    }
    SUBCASE("Python is too old: nothing is installed") {
        Setup s;
        auto r = plugin_install(s.config(), token_economizer_request(), s.cli.hooks(true));
        REQUIRE_FALSE(r);
        CHECK(has(r.error().message, "Python 3.8.10"));
        CHECK(has(r.error().message, "older than the 3.10"));
        CHECK(has(r.error().hint, "Install Python 3.10"));
        CHECK_FALSE(has(s.cli.log(), "marketplace add"));
        PluginInstallRequest dry = token_economizer_request();
        dry.dryRun = true;
        auto d = plugin_install(s.config(), dry, s.cli.hooks(true));
        REQUIRE(d);
        CHECK((*d)["ok"] == false);
        CHECK((*d)["python"]["ok"] == false);
    }
    SUBCASE("Python is missing") {
        Setup s;
        PluginInstallHooks h;
        h.pythonCommands = {(s.cli.dir.path / "no_such_python").string()};
        auto r = plugin_install(s.config(), token_economizer_request(), h);
        REQUIRE_FALSE(r);
        CHECK(has(r.error().message, "was not found"));
    }
    SUBCASE("a bad role is refused before anything is installed") {
        Setup s;
        PluginInstallRequest req = token_economizer_request();
        req.roles = {"wroker"};
        auto r = plugin_install(s.config(), req, s.cli.hooks());
        REQUIRE_FALSE(r);
        CHECK(has(r.error().message, "Nothing was installed"));
        CHECK(has(r.error().message + r.error().hint, "worker"));
        CHECK_FALSE(has(s.cli.log(), "plugin"));
    }
    SUBCASE("the CLI has no plugin commands") {
        Setup s;
        s.cli.touch("nojson");
        s.cli.touch("listfails");
        auto r = plugin_install(s.config(), token_economizer_request(), s.cli.hooks());
        REQUIRE_FALSE(r);
        CHECK(has(r.error().message, "failed"));
        CHECK(has(r.error().hint, "Update Claude Code"));
    }
    SUBCASE("no claude-code provider, or its program is missing") {
        Setup s;
        AiConfig none = s.config();
        none.providers.erase("claude-code");
        auto r = plugin_install(none, token_economizer_request(), s.cli.hooks());
        REQUIRE_FALSE(r);
        CHECK(has(r.error().message, "No claude-code provider"));
        AiConfig gone = s.config();
        gone.providers["claude-code"].command = (s.cli.dir.path / "missing_claude").string();
        auto m = plugin_install(gone, token_economizer_request(), s.cli.hooks());
        REQUIRE_FALSE(m);
        CHECK_FALSE(m.error().hint.empty());
    }
    SUBCASE("the plugin must be name@marketplace") {
        Setup s;
        PluginInstallRequest req = token_economizer_request();
        req.plugin = "tokeneconomizer";
        auto r = plugin_install(s.config(), req, s.cli.hooks());
        REQUIRE_FALSE(r);
        CHECK(has(r.error().message, "name@marketplace"));
    }
}

TEST_CASE("ai.plugin_install: the command takes the preset, is for the user only and is not offered to the agent") {
    Setup s;
    CommandRegistry registry = make_registry();
    AiCommandOptions opt;
    opt.loadConfig = [&] { return Result<AiConfig>(s.config()); };
    register_ai_commands(registry, opt);
    const CommandInfo* info = registry.info("ai.plugin_install");
    REQUIRE(info);
    CHECK_FALSE(info->description.empty());
    CHECK(is_agent_tool_excluded("ai.plugin_install"));
    for (const ToolDef& t : tools_from_registry(registry, false, false)) CHECK(t.name != "ai_plugin_install");

    auto dry = registry.call("ai.plugin_install", Json::object({{"preset", "tokeneconomizer"}, {"dryRun", true}}));
    REQUIRE(dry.ok);
    CHECK(dry.result["marketplace"] == "microsoft/TokenEconomizer");
    CHECK(dry.result["steps"].size() == 3);
    CHECK_FALSE(has(s.cli.log(), "marketplace add"));

    auto bad = registry.call("ai.plugin_install", Json::object({{"preset", "nope"}}));
    CHECK_FALSE(bad.ok);
    auto missing = registry.call("ai.plugin_install", Json::object({{"marketplace", "owner/repo"}}));
    CHECK_FALSE(missing.ok);

    // A generic plugin: its own marketplace and plugin, no Python needed.
    std::ofstream(s.cli.dir.path / "marketplaces.json") << "[]";
    auto generic = registry.call("ai.plugin_install", Json::object({{"marketplace", "owner/repo"}, {"plugin", "tool@repo"}, {"roles", Json::array({"fast"})}}));
    REQUIRE_MESSAGE(generic.ok, generic.error.dump());
    CHECK(has(s.cli.log(), "plugin marketplace add owner/repo"));
    CHECK(has(s.cli.log(), "plugin install tool@repo"));
    CHECK(has(slurp(s.aiJson), "tool@repo"));
}
#endif  // !_WIN32
