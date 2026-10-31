// The tool catalog (tool_catalog.h): which commands the built-in agent gets in full, which only as a line of the prompt, how
// it reaches those (tool_describe / tool_call), that a read-only role cannot escape through them, that the tool list does not
// change while a conversation goes on, and the split of the context the loop records.
#include "test_common.h"

#include <algorithm>

#include "fa/ai/tool_catalog.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

bool has(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

std::vector<std::string> names_of(const std::vector<ToolDef>& tools) {
    std::vector<std::string> out;
    for (const ToolDef& t : tools) out.push_back(t.name);
    return out;
}

// A registry the size of a real one in miniature: a core command that writes, core commands that only look, and many commands
// of three categories with a schema long enough for the catalog to pay off.
struct BigRegistry {
    CommandRegistry reg;
    int writeCalls = 0;
    int slicesCalls = 0;
    Json lastSliceArgs;

    BigRegistry() {
        auto add = [&](const std::string& name, const std::string& category, bool readOnly, const std::string& summary,
                       std::function<Json(const Json&)> fn = {}) {
            CommandInfo info;
            info.name = name;
            info.category = category;
            info.readOnly = readOnly;
            info.summary = summary;
            info.description = std::string(500, 'd') + " Details of " + name + ".";
            Json props = Json::object();
            for (int i = 0; i < 8; ++i) props["field" + std::to_string(i)] = Json::object({{"type", "string"}, {"description", std::string(60, 'x')}});
            info.inputSchema = Json::object({{"type", "object"}, {"properties", props}});
            reg.add(info, fn ? fn : [](const Json&) { return Json::object({{"ok", true}}); });
        };
        add("scene.spawn", "scene", false, "Create an entity.", [this](const Json&) {
            ++writeCalls;
            return Json::object({{"id", 1}});
        });
        add("scene.list_entities", "scene", true, "List entities.");
        add("game.screenshot", "game", true, "Take a screenshot.");
        add("game.step", "game", false, "Run frames.");
        add("project.validate", "project", true, "Validate the project.");
        add("ai.run", "ai", false, "must be hidden from the model");
        for (int i = 0; i < 12; ++i) add("anim.op" + std::to_string(i), "anim", i % 2 == 0, "Animation operation number " + std::to_string(i) + ".");
        for (int i = 0; i < 12; ++i) add("ui.op" + std::to_string(i), "ui", true, "UI operation " + std::to_string(i) + ".");
        add("assets.slice_sheet", "assets", false, "Cut a sprite sheet into frames.", [this](const Json& a) {
            ++slicesCalls;
            lastSliceArgs = a;
            return Json::object({{"frames", 4}});
        });
        // a command with a required argument, to see the schema come back with the error
        CommandInfo strict;
        strict.name = "assets.pack_atlas";
        strict.category = "assets";
        strict.readOnly = false;
        strict.summary = "Pack images into an atlas.";
        strict.description = std::string(2000, 'p');
        strict.inputSchema = Json::parse(R"({"type":"object","properties":{"images":{"type":"array","items":{"type":"string"}}},
            "required":["images"],"additionalProperties":false})");
        reg.add(strict, [](const Json&) { return Json::object({{"ok", true}}); });
    }
};

struct Run {
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    TempDir dir;
    AiConfig cfg = default_config();
    std::vector<AgentEvent> events;

    SessionResult run(CommandRegistry& reg, const std::string& role, SessionOptions so = {}) {
        so.projectDir = dir.str();
        so.role = role;
        so.allowDelegation = false;
        AgentSession s(reg, cfg, so);
        s.set_provider_factory([this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        });
        s.set_event_handler([this](const AgentEvent& e) { events.push_back(e); });
        return s.run("task");
    }
};

ToolCall tcall(const std::string& id, const std::string& name, Json input = Json::object()) {
    ToolCall c;
    c.id = id;
    c.name = name;
    c.input = std::move(input);
    return c;
}

Json result_json(const ChatRequest& req, std::size_t index = 0) {
    REQUIRE_FALSE(req.messages.empty());
    const Message& m = req.messages.back();
    REQUIRE(m.toolResults.size() > index);
    return Json::parse(m.toolResults[index].content, nullptr, false);
}

}  // namespace

TEST_CASE("catalog: core commands in full, the rest as catalog lines, ai.* hidden") {
    BigRegistry b;
    ToolPlan plan = plan_tools(b.reg, {});
    REQUIRE(plan.useCatalog);
    const auto tools = names_of(plan.tools);
    for (const char* t : {"scene_spawn", "scene_list_entities", "game_screenshot", "game_step", "project_validate", "tool_describe", "tool_call"})
        CHECK_MESSAGE(has(tools, t), t);
    CHECK_FALSE(has(tools, "anim_op0"));
    CHECK_FALSE(has(tools, "assets_slice_sheet"));
    CHECK_FALSE(has(tools, "ai_run"));
    CHECK(plan.catalog.size() == 12 + 12 + 2);
    CHECK(plan.catalogText.find("- assets.slice_sheet: Cut a sprite sheet into frames.") != std::string::npos);
    CHECK(plan.catalogText.find("## anim") != std::string::npos);
    CHECK(plan.catalogText.find("ai.run") == std::string::npos);
    CHECK(plan.catalogText.find("scene.spawn") == std::string::npos);  // core: a tool, not a line
    CHECK(plan.toolBytes < plan.fullBytes / 2);
    CHECK(is_core_tool("fs.read"));
    CHECK_FALSE(is_core_tool("assets.generate_image"));
    // sorted: byte-stable
    CHECK(std::is_sorted(tools.begin(), tools.end()));
    // pure: the same inputs give the same list
    CHECK(names_of(plan_tools(b.reg, {}).tools) == tools);
}

TEST_CASE("catalog: a registry with little to leave out keeps every command in full") {
    CommandRegistry reg = make_registry();
    ToolPlan plan = plan_tools(reg, {});
    CHECK_FALSE(plan.useCatalog);
    CHECK(plan.catalogText.empty());
    CHECK(names_of(plan.tools) == names_of(tools_from_registry(reg, false)));
    ToolPlanOptions off;
    off.catalog = false;
    BigRegistry b;
    CHECK_FALSE(plan_tools(b.reg, off).useCatalog);
    CHECK(names_of(plan_tools(b.reg, off).tools) == names_of(tools_from_registry(b.reg, false)));
}

TEST_CASE("catalog: tool groups load a category or a command in full, a wrong name is explained") {
    BigRegistry b;
    ToolPlanOptions o;
    o.groups = {"anim", "assets.slice_sheet", "animm"};
    ToolPlan plan = plan_tools(b.reg, o);
    const auto tools = names_of(plan.tools);
    CHECK(has(tools, "anim_op3"));
    CHECK(has(tools, "assets_slice_sheet"));
    CHECK_FALSE(has(tools, "assets_pack_atlas"));
    CHECK_FALSE(has(tools, "ui_op0"));
    CHECK(plan.catalogText.find("anim.op3") == std::string::npos);
    CHECK(plan.catalogText.find("assets.pack_atlas") != std::string::npos);
    CHECK(plan.loadedGroups == std::vector<std::string>{"anim", "assets.slice_sheet"});
    REQUIRE(plan.notes.size() == 1);
    CHECK(plan.notes[0].find("'animm'") != std::string::npos);
    CHECK(plan.notes[0].find("anim") != std::string::npos);  // did you mean

    o.groups = {"all"};
    ToolPlan all = plan_tools(b.reg, o);
    CHECK_FALSE(all.useCatalog);
    CHECK(names_of(all.tools) == names_of(tools_from_registry(b.reg, false)));

    CHECK(default_tool_groups("artist") == std::vector<std::string>{"assets"});
    CHECK(default_tool_groups("audio") == std::vector<std::string>{"assets", "audio"});
    CHECK(default_tool_groups("worker").empty());
}

TEST_CASE("catalog: the roles' toolGroups are read from ai.json and written back") {
    auto cfg = parse_config(Json::parse(R"({"roles":{"artist":{"provider":"anthropic","toolGroups":["assets","anim"]},
        "worker":{"provider":"anthropic","toolGroups":[]}}})"));
    REQUIRE(cfg);
    REQUIRE(cfg->roles["artist"].toolGroups);
    CHECK(*cfg->roles["artist"].toolGroups == std::vector<std::string>{"assets", "anim"});
    REQUIRE(cfg->roles["worker"].toolGroups);
    CHECK(cfg->roles["worker"].toolGroups->empty());
    CHECK_FALSE(cfg->roles["orchestrator"].toolGroups);
    Json j = config_to_json(*cfg, false);
    CHECK(j["roles"]["artist"]["toolGroups"] == Json::parse(R"(["assets","anim"])"));
    CHECK_FALSE(j["roles"]["orchestrator"].contains("toolGroups"));
    // errors teach
    auto bad = parse_config(Json::parse(R"({"roles":{"artist":{"provider":"anthropic","toolGroups":"assets"}}})"));
    REQUIRE_FALSE(bad);
    CHECK(bad.error().message.find("/roles/artist/toolGroups") != std::string::npos);
    auto bad2 = parse_config(Json::parse(R"({"roles":{"artist":{"provider":"anthropic","toolGroups":["assets",3]}}})"));
    REQUIRE_FALSE(bad2);
    CHECK(bad2.error().message.find("/roles/artist/toolGroups/1") != std::string::npos);
    CHECK(validate_config_json(Json::parse(R"({"roles":{"artist":{"provider":"anthropic","toolGroups":["assets"]}}})")).empty());
    CHECK_FALSE(validate_config_json(Json::parse(R"({"roles":{"artist":{"provider":"anthropic","toolGroups":"assets"}}})")).empty());
}

TEST_CASE("catalog: describe then call; the tool list and the system prompt stay the same on every step") {
    BigRegistry b;
    Run r;
    r.provider->script = {
        tool_response({tcall("t1", "tool_describe", Json::object({{"commands", Json::array({"assets.slice_sheet", "assets_pack_atlas", "nope.cmd"})}}))}),
        tool_response({tcall("t2", "tool_call", Json::object({{"command", "assets.slice_sheet"}, {"arguments", Json::object({{"field0", "a.png"}})}}))}),
        text_response("Done."),
    };
    auto res = r.run(b.reg, kRoleWorker);
    REQUIRE(res.ok);
    REQUIRE(r.provider->requests.size() == 3);
    const ChatRequest& first = r.provider->requests[0];
    // stable prefix: nothing about the tools or the prompt changed after the model described and called a command
    for (std::size_t i = 1; i < 3; ++i) {
        CHECK(r.provider->requests[i].system == first.system);
        CHECK(names_of(r.provider->requests[i].tools) == names_of(first.tools));
        for (std::size_t k = 0; k < first.tools.size(); ++k) {
            CHECK(r.provider->requests[i].tools[k].description == first.tools[k].description);
            CHECK(r.provider->requests[i].tools[k].inputSchema == first.tools[k].inputSchema);
        }
    }
    CHECK(first.system.find("# Tools") != std::string::npos);
    CHECK(first.system.find("- assets.slice_sheet: Cut a sprite sheet into frames.") != std::string::npos);
    CHECK(first.system.find("# Tools") < first.system.find("# Project context"));
    CHECK_FALSE(has(names_of(first.tools), "assets_slice_sheet"));

    // tool_describe: full definitions, the unknown name explained
    Json described = result_json(r.provider->requests[1]);
    REQUIRE(described["commands"].size() == 2);
    CHECK(described["commands"][0]["name"] == "assets.slice_sheet");
    CHECK(described["commands"][0]["inputSchema"]["properties"].contains("field3"));
    CHECK(described["commands"][0]["description"].get<std::string>().find("Details of assets.slice_sheet") != std::string::npos);
    CHECK(described["commands"][1]["name"] == "assets.pack_atlas");
    REQUIRE(described["unknown"].size() == 1);
    CHECK(described["unknown"][0]["name"] == "nope.cmd");
    CHECK_FALSE(r.provider->requests[1].messages.back().toolResults[0].isError);

    // tool_call ran the command with the arguments, and the result is the command's
    CHECK(b.slicesCalls == 1);
    CHECK(b.lastSliceArgs["field0"] == "a.png");
    CHECK(result_json(r.provider->requests[2])["frames"] == 4);

    // the events name the command, not the wrapper
    bool sawCommand = false;
    for (const AgentEvent& e : r.events) {
        if (e.type == AgentEvent::Type::ToolStart && e.toolName == "assets_slice_sheet") {
            sawCommand = true;
            CHECK(e.toolInput["field0"] == "a.png");
        }
        if (e.type == AgentEvent::Type::ToolStart) CHECK(e.toolName != "tool_call");
    }
    CHECK(sawCommand);
}

TEST_CASE("catalog: tool_call explains its mistakes; a wrong argument brings the schema back") {
    BigRegistry b;
    Run r;
    r.provider->script = {
        tool_response({tcall("a", "tool_call", Json::object({{"command", "assets.slice_shet"}})),
                       tcall("b", "tool_call", Json::object({{"arguments", Json::object()}})),
                       tcall("c", "tool_call", Json::object({{"command", "assets.pack_atlas"}, {"arguments", Json::object({{"images", 5}})}})),
                       tcall("d", "tool_call", Json::object({{"command", "ai.run"}, {"arguments", Json::object()}})),
                       tcall("e", "tool_call", Json::object({{"command", "assets.pack_atlas"}, {"arguments", "x"}})),
                       tcall("f", "tool_call", Json::object({{"command", "scene_list_entities"}})),
                       tcall("g", "tool_describe")}),
        text_response("Done."),
    };
    REQUIRE(r.run(b.reg, kRoleWorker).ok);
    const ChatRequest& req = r.provider->requests[1];
    Json a = result_json(req, 0);
    CHECK(a["code"] == "unknown_command");
    CHECK(a["hint"].get<std::string>().find("assets.slice_sheet") != std::string::npos);
    CHECK(result_json(req, 1)["code"] == "invalid_arguments");
    Json c = result_json(req, 2);
    CHECK(c["code"] == "invalid_arguments");
    CHECK(c["inputSchema"]["required"] == Json::parse(R"(["images"])"));
    CHECK(result_json(req, 3)["code"] == "not_allowed");
    CHECK(result_json(req, 4)["code"] == "invalid_arguments");
    CHECK_FALSE(req.messages.back().toolResults[5].isError);  // underscore name, no arguments: fine
    CHECK(result_json(req, 6)["code"] == "invalid_arguments");
}

TEST_CASE("catalog: a read-only role has no way to a command that changes the project") {
    BigRegistry b;
    // what the role is offered
    ToolPlanOptions o;
    o.readOnly = true;
    ToolPlan plan = plan_tools(b.reg, o);
    CHECK_FALSE(has(names_of(plan.tools), "scene_spawn"));
    CHECK(plan.catalogText.find("assets.slice_sheet") == std::string::npos);
    CHECK(plan.catalogText.find("anim.op1:") == std::string::npos);  // odd ones write
    CHECK(plan.catalogText.find("anim.op0:") != std::string::npos);

    Run r;
    r.provider->script = {
        tool_response({tcall("a", "tool_call", Json::object({{"command", "scene.spawn"}, {"arguments", Json::object()}})),
                       tcall("b", "tool_call", Json::object({{"command", "scene_spawn"}})),
                       tcall("c", "scene_spawn"),
                       tcall("d", "tool_call", Json::object({{"command", "assets.slice_sheet"}})),
                       tcall("e", "tool_describe", Json::object({{"commands", Json::array({"assets.slice_sheet"})}})),
                       tcall("f", "tool_call", Json::object({{"command", "anim.op0"}}))}),
        text_response("Done."),
    };
    REQUIRE(r.run(b.reg, kRoleReviewer).ok);
    const ChatRequest& req = r.provider->requests[1];
    for (std::size_t i : {0, 1, 3}) {
        Json e = result_json(req, i);
        CHECK_MESSAGE(e["code"] == "not_allowed", i);
        CHECK(e["message"].get<std::string>().find("read-only") != std::string::npos);
    }
    CHECK(result_json(req, 2)["code"] == "unknown_tool");
    CHECK(req.messages.back().toolResults[4].isError);  // nothing to describe
    CHECK(result_json(req, 4)["unknown"].size() == 1);
    CHECK_FALSE(req.messages.back().toolResults[5].isError);  // a read-only one goes through
    CHECK(b.writeCalls == 0);
    CHECK(b.slicesCalls == 0);
}

TEST_CASE("catalog: the role's tool groups decide what the artist gets in full") {
    BigRegistry b;
    Run r;
    r.cfg.roles["artist"].toolGroups = std::vector<std::string>{"ui"};
    r.provider->script = {text_response("Done.")};
    REQUIRE(r.run(b.reg, kRoleArtist).ok);
    const auto tools = names_of(r.provider->requests[0].tools);
    CHECK(has(tools, "ui_op4"));
    CHECK_FALSE(has(tools, "assets_slice_sheet"));  // the default (assets) is replaced, not added to
    // a group that matches nothing: the user is told, the run goes on
    Run r2;
    r2.cfg.roles["artist"].toolGroups = std::vector<std::string>{"uii"};
    r2.provider->script = {text_response("Done.")};
    REQUIRE(r2.run(b.reg, kRoleArtist).ok);
    bool told = false;
    for (const AgentEvent& e : r2.events) {
        if (e.type == AgentEvent::Type::Info && e.text.find("toolGroups") != std::string::npos && e.text.find("'uii'") != std::string::npos) told = true;
    }
    CHECK(told);
    // without a setting the artist loads the assets
    Run r3;
    r3.provider->script = {text_response("Done.")};
    REQUIRE(r3.run(b.reg, kRoleArtist).ok);
    CHECK(has(names_of(r3.provider->requests[0].tools), "assets_slice_sheet"));
}

TEST_CASE("context split: every step records where the context went; the catalog makes the tools part small") {
    BigRegistry b;
    auto measure = [&](bool catalog, std::vector<AgentEvent>* events, std::string* transcript) {
        Run r;
        r.provider->script = {tool_response({tcall("a", "scene_list_entities")}), tool_response({tcall("b", "scene_list_entities")}),
                              text_response("Done.")};
        SessionOptions so;
        so.toolCatalog = catalog;
        auto res = r.run(b.reg, kRoleWorker, so);
        REQUIRE(res.ok);
        if (events) *events = r.events;
        if (transcript) *transcript = read_file(res.transcriptPath);
        u64 total = 0;
        for (const ChatRequest& req : r.provider->requests) total += estimate_context(req).totalBytes();
        return total;
    };
    std::vector<AgentEvent> events;
    std::string transcript;
    const u64 withCatalog = measure(true, &events, &transcript);
    const u64 full = measure(false, nullptr, nullptr);
    CHECK(withCatalog < full * 6 / 10);

    std::vector<ContextSplit> splits;
    for (const AgentEvent& e : events) {
        if (e.type == AgentEvent::Type::Usage) splits.push_back(e.contextSplit);
    }
    REQUIRE(splits.size() == 3);
    for (const ContextSplit& s : splits) {
        CHECK(s.known());
        CHECK(s.systemBytes > 0);
        CHECK(s.toolBytes > 0);
        CHECK(s.catalogBytes > 0);
        CHECK(s.catalogBytes < s.systemBytes);  // the catalog is part of the system prompt
        CHECK(s.catalogCount == 26);
        CHECK(s.toolCount == 7);  // 5 core in the registry + tool_describe + tool_call
    }
    CHECK(splits[0].toolBytes == splits[2].toolBytes);              // fixed for the run
    CHECK(splits[0].systemBytes == splits[2].systemBytes);
    CHECK(splits[2].conversationBytes > splits[0].conversationBytes);  // the conversation is what grows
    // the transcript has it on the assistant lines, and ai.session_timeline sums it up
    std::size_t lines = 0;
    for (std::size_t pos = 0; (pos = transcript.find("\"context\":{", pos)) != std::string::npos; ++pos) ++lines;
    CHECK(lines == 3);
    Json tl = session_timeline_from_text(transcript, 0);
    REQUIRE(tl["context"]["known"] == true);
    REQUIRE(tl["context"]["steps"].size() == 3);
    CHECK(tl["context"]["steps"][0]["toolCount"] == 7);
    CHECK(tl["context"]["totals"]["toolTokens"].get<u64>() > 0);
    CHECK(tl["context"]["totals"]["toolShare"].get<double>() > 0);
    // a session recorded without the sizes says so
    Json old = session_timeline_from_text(R"({"kind":"assistant","t":"2026-10-30T14:03:22.481Z"})", 0);
    CHECK(old["context"]["known"] == false);
}

TEST_CASE("context split: estimate_context counts the three parts and survives JSON") {
    ChatRequest req;
    req.system = std::string(1000, 's');
    ToolDef t;
    t.name = "x";
    t.description = std::string(100, 'd');
    t.inputSchema = Json::parse(R"({"type":"object"})");
    req.tools = {t, t};
    req.messages = {Message::user(std::string(300, 'u'))};
    ContextSplit c = estimate_context(req);
    CHECK(c.systemBytes == 1000);
    CHECK(c.toolCount == 2);
    CHECK(c.toolBytes > 200);
    CHECK(c.conversationBytes == 300);
    CHECK(c.totalBytes() == c.systemBytes + c.toolBytes + c.conversationBytes);
    CHECK(estimate_tokens(375) == 100);
    ContextSplit back = ContextSplit::from_json(c.to_json());
    CHECK(back.systemBytes == c.systemBytes);
    CHECK(back.toolBytes == c.toolBytes);
    CHECK(back.toolCount == 2);
    CHECK_FALSE(ContextSplit::from_json(Json::object()).known());
}
