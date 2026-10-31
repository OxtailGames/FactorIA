// The tool catalog against the REAL command registry of a project (tools/ai/include/fa/ai/tool_catalog.h): every core command
// exists, the built-in agent's request is a fraction of what offering every command costs, a read-only role reaches only the
// commands that look and play, and the scripted task of docs/AI_COSTS.md ("Fewer tool tokens") costs what that page says.
#include <doctest.h>

#include <cstdio>
#include <filesystem>

#include "common.h"  // tools/cli/src: Session
#include "fa/ai/session.h"
#include "fa/ai/tool_catalog.h"
#include "fa/core/fs.h"
#include "fa/tooling/scaffold.h"

namespace stdfs = std::filesystem;
using namespace fa;
using namespace fa::ai;

namespace {

// Answers from a script and keeps what every request carried.
class ScriptedProvider : public ChatProvider {
public:
    std::string name() const override { return "scripted"; }
    Result<ChatResponse> chat(const ChatRequest& req, const ChatHooks&, const CancelFlag*) override {
        splits.push_back(estimate_context(req));
        toolLists.emplace_back();
        for (const ToolDef& t : req.tools) toolLists.back().push_back(t.name);
        systems.push_back(req.system);
        if (next >= script.size()) return make_error("script exhausted");
        return script[next++];
    }
    std::vector<ChatResponse> script;
    std::size_t next = 0;
    std::vector<ContextSplit> splits;
    std::vector<std::vector<std::string>> toolLists;
    std::vector<std::string> systems;
};

ChatResponse calls(std::vector<std::pair<std::string, Json>> list) {
    ChatResponse r;
    r.message.role = Role::Assistant;
    int n = 0;
    Json raw = Json::array();
    for (auto& [name, input] : list) {
        ToolCall c;
        c.id = "t" + std::to_string(++n);
        c.name = name;
        c.input = input;
        raw.push_back(Json::object({{"type", "tool_use"}, {"id", c.id}, {"name", c.name}, {"input", c.input}}));
        r.message.toolCalls.push_back(std::move(c));
    }
    r.message.raw = raw;
    r.stopReason = StopReason::ToolUse;
    r.rawStopReason = "tool_use";
    return r;
}

ChatResponse done() {
    ChatResponse r;
    r.message.role = Role::Assistant;
    r.message.text = "Done.";
    r.message.raw = Json::array({Json::object({{"type", "text"}, {"text", "Done."}})});
    r.rawStopReason = "end_turn";
    return r;
}

std::unique_ptr<cli::Session> open_game(const char* tag, stdfs::path& oldRoot) {
    oldRoot = fs::project_root();
    const stdfs::path root = fs::make_temp_dir(std::string("fa_tool_catalog_") + tag);
    ScaffoldOptions opt;
    opt.writeTypings = false;
    const std::string dir = (root / "game").string();
    auto made = create_project(dir, "2d-empty", opt);
    REQUIRE_MESSAGE(made.ok(), made.error().to_string());
    cli::SessionOptions so;
    so.gfx = cli::Gfx::None;
    return cli::Session::open(dir, so);
}

}  // namespace

TEST_CASE("tool catalog: every core command exists in the real registry, none is an ai.* command") {
    stdfs::path oldRoot;
    auto session = open_game("core", oldRoot);
    for (const std::string& name : core_tool_names()) {
        INFO(name);
        CHECK(session->registry().info(name) != nullptr);
        CHECK_FALSE(is_agent_tool_excluded(name));
    }
    session.reset();
    fs::set_project_root(oldRoot);
}

TEST_CASE("tool catalog: a scripted task on the real registry sends a fraction of the context, with a fixed tool list") {
    stdfs::path oldRoot;
    auto session = open_game("task", oldRoot);
    CommandRegistry& reg = session->registry();

    // The same six steps with and without the catalog: look at the project, validate, list entities, look at the UI state, then
    // one command that is not a tool of its own (ui.state): through tool_describe + tool_call with the catalog, directly without.
    auto script = [](bool catalog) {
        std::vector<ChatResponse> s;
        s.push_back(calls({{"fs_list", Json::object()}}));
        s.push_back(calls({{"project_validate", Json::object()}}));
        s.push_back(calls({{"scene_list_entities", Json::object()}}));
        if (catalog) {
            s.push_back(calls({{"tool_describe", Json::object({{"commands", Json::array({"ui.state"})}})}}));
            s.push_back(calls({{"tool_call", Json::object({{"command", "ui.state"}, {"arguments", Json::object()}})}}));
        } else {
            s.push_back(calls({{"ui_state", Json::object()}}));
        }
        s.push_back(done());
        return s;
    };
    struct Measured {
        std::vector<ContextSplit> splits;
        std::vector<std::vector<std::string>> toolLists;
        std::vector<std::string> systems;
        bool ok = false;
    };
    auto measure = [&](bool catalog) {
        auto provider = std::make_shared<ScriptedProvider>();
        provider->script = script(catalog);
        AiConfig cfg = default_config();
        SessionOptions so;
        so.projectDir = session->project_dir();
        so.role = kRoleOrchestrator;
        so.allowDelegation = false;
        so.toolCatalog = catalog;
        so.saveTranscript = false;
        AgentSession s(reg, cfg, so);
        s.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        });
        Measured m;
        m.ok = s.run("Look at the project and check it.").ok;
        m.splits = provider->splits;
        m.toolLists = provider->toolLists;
        m.systems = provider->systems;
        return m;
    };
    const Measured withCatalog = measure(true);
    const Measured full = measure(false);
    REQUIRE(withCatalog.ok);
    REQUIRE(full.ok);
    REQUIRE(withCatalog.splits.size() == 6);
    REQUIRE(full.splits.size() == 5);

    u64 catalogTotal = 0, fullTotal = 0;
    std::printf("tool catalog, scripted task on the real registry (estimated bytes per step: system / tools / conversation)\n");
    for (std::size_t i = 0; i < withCatalog.splits.size(); ++i) {
        const ContextSplit& c = withCatalog.splits[i];
        catalogTotal += c.totalBytes();
        std::printf("  with catalog  step %zu: %6llu / %6llu / %6llu  (%d tools, %d catalog lines)\n", i + 1,
                    static_cast<unsigned long long>(c.systemBytes), static_cast<unsigned long long>(c.toolBytes),
                    static_cast<unsigned long long>(c.conversationBytes), c.toolCount, c.catalogCount);
    }
    for (std::size_t i = 0; i < full.splits.size(); ++i) {
        const ContextSplit& c = full.splits[i];
        fullTotal += c.totalBytes();
        std::printf("  every tool    step %zu: %6llu / %6llu / %6llu  (%d tools)\n", i + 1, static_cast<unsigned long long>(c.systemBytes),
                    static_cast<unsigned long long>(c.toolBytes), static_cast<unsigned long long>(c.conversationBytes), c.toolCount);
    }
    std::printf("  step 1: %llu bytes with the catalog, %llu with every tool\n",
                static_cast<unsigned long long>(withCatalog.splits[0].totalBytes()), static_cast<unsigned long long>(full.splits[0].totalBytes()));

    // The saving: a step sends under a third of what it did, and a step of the catalog run stays under 100 KB.
    CHECK(withCatalog.splits[0].totalBytes() < full.splits[0].totalBytes() / 3);
    CHECK(withCatalog.splits[0].totalBytes() < 100000);
    CHECK(withCatalog.splits[0].toolBytes < full.splits[0].toolBytes / 5);
    CHECK(full.splits[0].toolBytes > 150000);  // what the real registry costs in full: the problem this package solves
    CHECK(plan_tools(reg, ToolPlanOptions{}).catalog.size() > 80);  // most of the registry is catalog lines

    // The tool list and the system prompt do not change from one step to the next (the prompt cache's prefix).
    for (std::size_t i = 1; i < withCatalog.toolLists.size(); ++i) {
        CHECK(withCatalog.toolLists[i] == withCatalog.toolLists[0]);
        CHECK(withCatalog.systems[i] == withCatalog.systems[0]);
    }
    session.reset();
    fs::set_project_root(oldRoot);
}

TEST_CASE("tool catalog: on the real registry a read-only role reaches exactly the commands that look and play") {
    stdfs::path oldRoot;
    auto session = open_game("readonly", oldRoot);
    CommandRegistry& reg = session->registry();
    ToolPlanOptions po;
    po.readOnly = true;
    const ToolPlan plan = plan_tools(reg, po);
    for (const CommandInfo* info : reg.list()) {
        INFO(info->name);
        std::string why, hint;
        const CommandInfo* found = resolve_command(reg, info->name, true, why, hint);
        const bool allowed = !is_agent_tool_excluded(info->name) && is_read_only_tool(*info);
        CHECK((found != nullptr) == allowed);
        const bool offered = [&] {
            for (const ToolDef& t : plan.tools) if (t.name == tool_name_for_command(info->name)) return true;
            for (const CatalogEntry& e : plan.catalog) if (e.command == info->name) return true;
            return false;
        }();
        CHECK(offered == allowed);
    }
    // the roles that write get the whole registry minus ai.*
    ToolPlanOptions all;
    const ToolPlan writer = plan_tools(reg, all);
    CHECK(writer.tools.size() + writer.catalog.size() >= plan.tools.size() + plan.catalog.size());
    session.reset();
    fs::set_project_root(oldRoot);
}
