// The engine's own token savers (savers.h) in the built-in loop with the fake provider: the loop guard (three identical failures
// give one redirect and no model call; the judge's tokens are counted), the tool groups the runs of a project load (counted,
// proposed, applied only on accept), the project facts (proposed, nothing written before accept), the switches in ai.json and the
// ai.savers / ai.saver_group / ai.saver_fact commands.
#include <algorithm>
#include <fstream>

#include "fa/ai/commands.h"
#include "fa/ai/savers.h"
#include "fa/ai/tool_catalog.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;
namespace fsys = std::filesystem;

namespace {

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

ToolCall call(const std::string& id, const std::string& name, Json input = Json::object()) {
    ToolCall c;
    c.id = id;
    c.name = name;
    c.input = std::move(input);
    return c;
}

struct SaverHarness {
    TempDir proj, home;
    CommandRegistry registry = make_registry();
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    AiConfig cfg = default_config();
    std::vector<AgentEvent> events;
    bool catalog = false;

    SaverHarness() {
        cfg.sourcePath = (home.path / "ai.json").string();
        // Commands of a group ("gfx") whose definitions are big enough for the catalog to pay off.
        for (const char* name : {"gfx.one", "gfx.two"}) {
            CommandInfo c;
            c.name = name;
            c.category = "gfx";
            c.summary = std::string("A gfx command ") + name + ".";
            c.description = std::string(4000, 'x');
            registry.add(c, [](const Json&) { return Json::object({{"ok", true}}); });
        }
        // Fails with "bad_name" unless called with name "ok": the fix is in the arguments.
        CommandInfo make;
        make.name = "proj.make";
        make.category = "proj";
        make.summary = "Makes a thing.";
        registry.add(make, [](const Json& a) -> Json {
            if (a.value("name", std::string()) != "ok") throw CommandError("bad_name", "name must be 'ok'", "Pass name \"ok\".");
            return Json::object({{"made", true}});
        });
    }
    SessionResult run(const std::string& task = "go") {
        SessionOptions so;
        so.projectDir = proj.str();
        so.toolCatalog = catalog;
        so.env = fake_env({{"HOME", home.str()}});
        so.extensionsTrustPath = (home.path / "ai-trust.json").string();
        AgentSession s(registry, cfg, so);
        s.set_provider_factory([this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        });
        s.set_event_handler([this](const AgentEvent& e) { events.push_back(e); });
        return s.run(task);
    }
    // A fresh fake provider for the next run (its script and requests start empty).
    void next_provider() { provider = std::make_shared<FakeProvider>(); }
    std::string tool_result_text(std::size_t request) const {
        const Message& m = provider->requests.at(request).messages.back();
        std::string all;
        for (const ToolResult& r : m.toolResults) all += r.content + "\n";
        return all;
    }
    bool said(const std::string& part) const {
        for (const auto& e : events)
            if (e.type == AgentEvent::Type::Info && has(e.text, part)) return true;
        return false;
    }
    std::string agents() const { return (proj.path / "AGENTS.md").string(); }
};

std::vector<Json> transcript_lines(const std::string& path, const std::string& kind) {
    std::vector<Json> out;
    std::ifstream f(path);
    std::string line;
    while (std::getline(f, line)) {
        Json j = Json::parse(line, nullptr, false);
        if (j.is_object() && j.value("kind", std::string()) == kind) out.push_back(j);
    }
    return out;
}

std::vector<ToolCall> three_failures() {
    return {call("a", "project_validate"), call("b", "project_validate"), call("c", "project_validate")};
}

}  // namespace

// --- loop guard ------------------------------------------------------------------------------------------------------------

TEST_CASE("loop guard: the third failure of one command with one code gives one redirect; a success starts the count again") {
    LoopGuard g;
    CHECK_FALSE(g.record("scene.load", false, "not_found", "no scene", "Check the name").has_value());
    CHECK_FALSE(g.record("scene.load", false, "not_found", "no scene", "Check the name").has_value());
    CHECK_FALSE(g.record("scene.load", false, "other", "x", "").has_value());  // another code counts on its own
    auto r = g.record("scene.load", false, "not_found", "no scene", "Check the name");
    REQUIRE(r.has_value());
    CHECK(r->count == 3);
    CHECK(has(r->text, "[Loop guard]"));
    CHECK(has(r->text, "scene.load"));
    CHECK(has(r->text, "not_found"));
    CHECK(has(r->text, "Check the name"));
    CHECK(has(r->text, "different way"));
    CHECK_FALSE(g.record("scene.load", false, "not_found", "no scene", "").has_value());  // once per run
    g.record("scene.load", true, "", "", "");
    CHECK_FALSE(g.record("scene.load", false, "not_found", "", "").has_value());  // counting from zero
    CHECK_FALSE(g.record("scene.load", false, "not_found", "", "").has_value());
    CHECK(g.record("scene.load", false, "not_found", "", "").has_value());  // a new run of three after a success is guarded again
}

TEST_CASE("loop guard: three identical failures in a run -> one redirect on the third error and no model call for it") {
    SaverHarness h;
    h.provider->script = {tool_response(three_failures()), text_response("done")};
    auto r = h.run();
    REQUIRE(r.ok);
    CHECK(h.provider->calls == 2);  // the tool step and the final answer: the redirect asked the model nothing
    const Message& results = h.provider->requests.at(1).messages.back();
    REQUIRE(results.toolResults.size() == 3);
    CHECK_FALSE(has(results.toolResults[0].content, "Loop guard"));
    CHECK_FALSE(has(results.toolResults[1].content, "Loop guard"));
    CHECK(has(results.toolResults[2].content, "Loop guard"));
    CHECK(has(results.toolResults[2].content, "scene main is broken"));  // the error itself is still there
    CHECK(h.said("Loop guard: project.validate failed 3 times"));
    const auto lines = transcript_lines(r.transcriptPath, "saver");  // the session event
    REQUIRE(lines.size() == 1);
    CHECK(lines[0]["saver"] == "loopGuard");
    CHECK(lines[0]["command"] == "project.validate");
    CHECK(lines[0]["code"] == "failed");
    CHECK(lines[0]["judge"] == false);
    CHECK(r.usage.inputTokens == 200);  // two model calls, nothing for the redirect
}

TEST_CASE("loop guard: through tool_call the command behind the wrapper is counted; a fourth failure gets no second redirect") {
    SaverHarness h;
    h.catalog = true;
    std::vector<ToolCall> calls;
    for (const char* id : {"a", "b", "c", "d"})
        calls.push_back(call(id, "tool_call", Json::object({{"command", "project.validate"}, {"arguments", Json::object()}})));
    h.provider->script = {tool_response(calls), text_response("done")};
    REQUIRE(h.run().ok);
    const Message& results = h.provider->requests.at(1).messages.back();
    REQUIRE(results.toolResults.size() == 4);
    CHECK(has(results.toolResults[2].content, "Loop guard"));
    CHECK_FALSE(has(results.toolResults[3].content, "Loop guard"));
}

TEST_CASE("loop guard: off in ai.json -> no redirect") {
    SaverHarness h;
    h.cfg.savers.loopGuard = false;
    h.provider->script = {tool_response(three_failures()), text_response("done")};
    REQUIRE(h.run().ok);
    CHECK_FALSE(has(h.tool_result_text(1), "Loop guard"));
}

TEST_CASE("loop guard: the judge writes the redirect and its tokens are in the run's usage and cost") {
    SaverHarness h;
    h.cfg.savers.loopGuardJudge = "fast";
    ChatResponse judge = text_response("Validation cannot pass until scenes/main.scene.json is fixed; open it and repair it instead of validating again.");
    judge.usage.inputTokens = 50;
    judge.usage.outputTokens = 20;
    h.provider->script = {tool_response(three_failures()), judge, text_response("done")};
    auto r = h.run();
    REQUIRE(r.ok);
    REQUIRE(h.provider->calls == 3);
    // the judge got a short request of its own: no tools, the stuck command and its error
    const ChatRequest& jr = h.provider->requests.at(1);
    CHECK(jr.tools.empty());
    REQUIRE(jr.messages.size() == 1);
    CHECK(has(jr.messages[0].text, "project.validate"));
    CHECK(has(jr.messages[0].text, "scene main is broken"));
    CHECK(has(h.tool_result_text(2), "repair it instead of validating again"));
    CHECK(r.usage.inputTokens == 100 + 50 + 100);  // tool step + judge + final answer
    CHECK(r.usage.outputTokens == 10 + 20 + 10);
    const auto lines = transcript_lines(r.transcriptPath, "saver");
    REQUIRE(lines.size() == 1);
    CHECK(lines[0]["judge"] == true);
    CHECK(lines[0]["judgeRole"] == "fast");
    CHECK(lines[0]["judgeUsage"]["inputTokens"] == 50);
    CHECK(lines[0]["judgeCostUsd"].get<double>() > 0);
}

TEST_CASE("loop guard: the judge counts against the run's limits") {
    SaverHarness h;
    h.cfg.savers.loopGuardJudge = "fast";
    h.cfg.limits.maxTotalTokens = 250;  // the tool step (110) and its final answer (220) fit; with the judge (170 more) they do not
    ChatResponse judge = text_response("Try something else.");
    judge.usage.inputTokens = 150;
    judge.usage.outputTokens = 20;
    h.provider->script = {tool_response(three_failures()), judge, text_response("done")};
    auto r = h.run();
    CHECK_FALSE(r.ok);
    CHECK(r.stopReason == "budget");  // without the judge's 170 tokens the run would have finished
    CHECK(h.provider->calls == 2);
}

TEST_CASE("loop guard: a judge on a CLI agent cannot answer here; the fixed redirect is used and the run says so") {
    SaverHarness h;
    h.cfg.savers.loopGuardJudge = "fast";
    h.cfg.roles["fast"].provider = "claude-code";
    h.provider->script = {tool_response(three_failures()), text_response("done")};
    auto r = h.run();
    REQUIRE(r.ok);
    CHECK(h.provider->calls == 2);
    CHECK(has(h.tool_result_text(1), "different way"));
    const auto lines = transcript_lines(r.transcriptPath, "saver");
    REQUIRE(lines.size() == 1);
    CHECK(has(lines[0]["judgeSkipped"].get<std::string>(), "API provider"));
}

// --- the switches ----------------------------------------------------------------------------------------------------------

TEST_CASE("savers: ai.json section is validated, kept by save_savers and left out when it only holds defaults") {
    auto cfg = parse_config(Json::parse(R"({"savers":{"loopGuard":false,"loopGuardJudge":"fast","projectFacts":false}})"));
    REQUIRE(cfg);
    CHECK_FALSE(cfg->savers.loopGuard);
    CHECK(cfg->savers.loopGuardJudge == "fast");
    CHECK(cfg->savers.learnedToolGroups);
    CHECK_FALSE(cfg->savers.projectFacts);
    CHECK(validate_config_json(Json::parse(R"({"savers":{"loopGuard":"yes"}})")).size() > 0);
    CHECK(validate_config_json(Json::parse(R"({"savers":{"unknownSaver":true}})")).size() > 0);
    auto bad = parse_config(Json::parse(R"({"savers":{"loopGuardJudge":"fats"}})"));
    REQUIRE_FALSE(bad);
    CHECK(has(bad.error().hint, "fast"));  // did you mean

    TempDir dir;
    const std::string path = (dir.path / "ai.json").string();
    std::ofstream(path) << R"({"defaultProvider":"anthropic","limits":{"maxTurns":7}})";
    REQUIRE(save_savers(cfg->savers, path));
    auto again = load_config(path);
    REQUIRE(again);
    CHECK_FALSE(again->savers.loopGuard);
    CHECK(again->savers.loopGuardJudge == "fast");
    CHECK(again->limits.maxTurns == 7);  // the other keys stay
    REQUIRE(save_savers(Savers{}, path));
    CHECK(read_file(path).find("savers") == std::string::npos);
    CHECK(save_config(*cfg, path));
    CHECK(has(read_file(path), "\"loopGuardJudge\""));
}

// --- learned tool groups ---------------------------------------------------------------------------------------------------

namespace {
// One run of the catalog loop in which the model describes gfx.one and then uses it.
SessionResult run_loading_gfx(SaverHarness& h) {
    h.catalog = true;
    h.next_provider();
    h.provider->script = {tool_response({call("a", "tool_describe", Json::object({{"commands", Json::array({"gfx.one"})}}))}),
                          tool_response({call("b", "tool_call", Json::object({{"command", "gfx.one"}, {"arguments", Json::object()}}))}),
                          text_response("done")};
    return h.run();
}
bool offered(const SaverHarness& h, const std::string& tool) {
    const auto& tools = h.provider->requests.at(0).tools;
    return std::any_of(tools.begin(), tools.end(), [&](const ToolDef& t) { return t.name == tool; });
}
}  // namespace

TEST_CASE("learned groups: loads are counted per run, the group is proposed after three runs and nothing changes until accept") {
    SaverHarness h;
    for (int i = 0; i < 2; ++i) REQUIRE(run_loading_gfx(h).ok);
    CHECK(group_proposals(h.cfg, h.registry, h.proj.str()).empty());
    CHECK_FALSE(offered(h, "gfx_one"));
    REQUIRE(run_loading_gfx(h).ok);
    const auto proposals = group_proposals(h.cfg, h.registry, h.proj.str());
    REQUIRE(proposals.size() == 1);
    CHECK(proposals[0].role == "orchestrator");
    CHECK(proposals[0].group == "gfx");
    CHECK(proposals[0].runs == 3);
    CHECK(proposals[0].commands == std::vector<std::string>{"gfx.one"});
    CHECK(proposals[0].definitionBytes > 8000);  // two commands of ~4000 bytes: what loading the group would add to every step

    // proposed only: the next run still gets the catalog and nothing is denied
    REQUIRE(run_loading_gfx(h).ok);
    CHECK_FALSE(offered(h, "gfx_one"));
    CHECK(accepted_tool_groups(h.proj.str(), "orchestrator").empty());

    // the same command in one run twice counts once for that run
    const Json report = savers_report(h.cfg, h.registry, h.proj.str());
    CHECK(report["groups"]["orchestrator"]["gfx"]["commands"]["gfx.one"] == 4);
    CHECK(report["runs"]["orchestrator"] == 4);
    CHECK(report["proposals"]["toolGroups"].size() == 1);

    auto accepted = answer_tool_group(h.registry, h.proj.str(), "orchestrator", "gfx", SaverAnswer::Accept);
    REQUIRE(accepted);
    CHECK((*accepted)["status"] == "accepted");
    CHECK(group_proposals(h.cfg, h.registry, h.proj.str()).empty());
    h.catalog = true;
    h.next_provider();
    h.provider->script = {text_response("hi")};
    REQUIRE(h.run().ok);
    CHECK(offered(h, "gfx_one"));  // loaded up front from this run on
    CHECK(offered(h, "gfx_two"));  // the whole group
    CHECK(h.cfg.roles["orchestrator"].toolGroups == std::nullopt);  // ai.json is not touched: the choice belongs to the project
}

TEST_CASE("learned groups: decline keeps it from being proposed again; the switch off counts nothing; unknown names teach") {
    {
        SaverHarness h;
        for (int i = 0; i < 3; ++i) REQUIRE(run_loading_gfx(h).ok);
        REQUIRE(group_proposals(h.cfg, h.registry, h.proj.str()).size() == 1);
        REQUIRE(answer_tool_group(h.registry, h.proj.str(), "orchestrator", "gfx", SaverAnswer::Decline));
        CHECK(group_proposals(h.cfg, h.registry, h.proj.str()).empty());
        CHECK(accepted_tool_groups(h.proj.str(), "orchestrator").empty());
        run_loading_gfx(h);
        CHECK_FALSE(offered(h, "gfx_one"));
        REQUIRE(answer_tool_group(h.registry, h.proj.str(), "orchestrator", "gfx", SaverAnswer::Forget));
        CHECK(group_proposals(h.cfg, h.registry, h.proj.str()).size() == 1);
        auto unknown = answer_tool_group(h.registry, h.proj.str(), "orchestrator", "gfxx", SaverAnswer::Accept);
        REQUIRE_FALSE(unknown);
        CHECK(has(unknown.error().hint, "gfx"));
        CHECK_FALSE(answer_tool_group(h.registry, h.proj.str(), "wroker", "gfx", SaverAnswer::Accept));
    }
    {
        SaverHarness h;
        h.cfg.savers.learnedToolGroups = false;
        for (int i = 0; i < 3; ++i) REQUIRE(run_loading_gfx(h).ok);
        CHECK(group_proposals(h.cfg, h.registry, h.proj.str()).empty());
        CHECK_FALSE(fsys::exists(h.proj.path / kSaversFile));
    }
}

TEST_CASE("learned groups: a group the role already loads is not proposed") {
    SaverHarness h;
    for (int i = 0; i < 3; ++i) REQUIRE(run_loading_gfx(h).ok);
    h.cfg.roles["orchestrator"].toolGroups = std::vector<std::string>{"gfx"};
    CHECK(group_proposals(h.cfg, h.registry, h.proj.str()).empty());
}

// --- project facts ---------------------------------------------------------------------------------------------------------

namespace {
// A run in which proj.make fails with bad_name and then works with other arguments.
SessionResult run_failing_then_fixed(SaverHarness& h, bool fixed = true) {
    h.next_provider();
    std::vector<ChatResponse> script = {tool_response({call("a", "proj_make", Json::object({{"name", "bad"}}))})};
    if (fixed) script.push_back(tool_response({call("b", "proj_make", Json::object({{"name", "ok"}}))}));
    script.push_back(text_response("done"));
    h.provider->script = script;
    return h.run();
}
}  // namespace

TEST_CASE("project facts: a failure that a later call fixed, in three runs, is proposed; AGENTS.md is untouched until accept") {
    SaverHarness h;
    const std::string original = "# My game\n\nSome text.\n\n## Conventions\n\n- Use tabs.\n";
    std::ofstream(h.agents()) << original;
    REQUIRE(run_failing_then_fixed(h, false).ok);  // never fixed: not a fact
    for (int i = 0; i < 2; ++i) REQUIRE(run_failing_then_fixed(h).ok);
    CHECK(fact_proposals(h.proj.str()).empty());
    REQUIRE(run_failing_then_fixed(h).ok);
    const auto facts = fact_proposals(h.proj.str());
    REQUIRE(facts.size() == 1);
    CHECK(facts[0].id == "proj.make:bad_name");
    CHECK(facts[0].runs == 3);
    CHECK(facts[0].line.rfind("- ", 0) == 0);
    CHECK(facts[0].line.find('\n') == std::string::npos);
    CHECK(has(facts[0].line, "proj.make"));
    CHECK(has(facts[0].line, "bad_name"));
    CHECK(has(facts[0].line, "{\"name\":\"ok\"}"));  // what worked
    CHECK(has(facts[0].line, "Pass name"));         // the error's hint
    CHECK(read_file(h.agents()) == original);        // nothing written before the user answers

    auto accepted = answer_fact(h.proj.str(), facts[0].id, SaverAnswer::Accept);
    REQUIRE(accepted);
    const std::string after = read_file(h.agents());
    CHECK(has(after, "## Project facts"));
    CHECK(has(after, facts[0].line));
    CHECK(after.substr(0, original.size()) == original);  // appended, the rest is as it was
    CHECK(fact_proposals(h.proj.str()).empty());
    REQUIRE(answer_fact(h.proj.str(), facts[0].id, SaverAnswer::Accept));  // twice: still one line
    const std::string twice = read_file(h.agents());
    CHECK(twice.find(facts[0].line) == twice.rfind(facts[0].line));
    CHECK_FALSE(answer_fact(h.proj.str(), "proj.make:bad_nme", SaverAnswer::Accept));
}

TEST_CASE("project facts: decline, a line the user edited, a second fact under the same heading, the switch off") {
    SaverHarness h;
    for (int i = 0; i < 3; ++i) REQUIRE(run_failing_then_fixed(h).ok);
    REQUIRE(fact_proposals(h.proj.str()).size() == 1);
    auto declined = answer_fact(h.proj.str(), "proj.make:bad_name", SaverAnswer::Decline);
    REQUIRE(declined);
    CHECK((*declined)["status"] == "declined");
    CHECK(fact_proposals(h.proj.str()).empty());
    CHECK_FALSE(fsys::exists(h.proj.path / "AGENTS.md"));  // declined: nothing was written
    REQUIRE(answer_fact(h.proj.str(), "proj.make:bad_name", SaverAnswer::Forget));
    REQUIRE(answer_fact(h.proj.str(), "proj.make:bad_name", SaverAnswer::Accept, "proj.make needs name ok"));
    CHECK(has(read_file(h.agents()), "- proj.make needs name ok"));  // created, with the heading
    CHECK(has(read_file(h.agents()), "## Project facts"));

    // another fact lands under the same heading, before a later section
    std::ofstream(h.agents()) << "# G\n\n## Project facts\n\n- old\n\n## Other\n\ntext\n";
    // (the stored store has one fact only: reuse it with a different id by a second command)
    SaverHarness h2;
    std::ofstream(h2.agents()) << "# G\n\n## Project facts\n\n- old\n\n## Other\n\ntext\n";
    for (int i = 0; i < 3; ++i) REQUIRE(run_failing_then_fixed(h2).ok);
    REQUIRE(answer_fact(h2.proj.str(), "proj.make:bad_name", SaverAnswer::Accept));
    const std::string text = read_file(h2.agents());
    CHECK(text.find("- old") < text.find("- `proj.make`"));
    CHECK(text.find("- `proj.make`") < text.find("## Other"));
    CHECK(has(text, "text\n"));

    SaverHarness off;
    off.cfg.savers.projectFacts = false;
    for (int i = 0; i < 3; ++i) REQUIRE(run_failing_then_fixed(off).ok);
    CHECK(fact_proposals(off.proj.str()).empty());
}

// --- the commands ----------------------------------------------------------------------------------------------------------

TEST_CASE("ai.savers, ai.saver_group and ai.saver_fact: state, accept and decline through the registry") {
    SaverHarness h;
    AiCommandOptions o;
    o.loadConfig = [&]() -> Result<AiConfig> { return h.cfg; };
    o.projectDir = [&] { return h.proj.str(); };
    register_ai_commands(h.registry, o);
    for (int i = 0; i < 3; ++i) REQUIRE(run_loading_gfx(h).ok);
    for (int i = 0; i < 3; ++i) REQUIRE(run_failing_then_fixed(h).ok);

    auto state = h.registry.call("ai.savers");
    REQUIRE(state.ok);
    CHECK(state.result["switches"]["loopGuard"] == true);
    CHECK(state.result["proposals"]["toolGroups"].size() == 1);
    CHECK(state.result["proposals"]["toolGroups"][0]["group"] == "gfx");
    CHECK(state.result["proposals"]["facts"].size() == 1);
    CHECK(state.result["proposals"]["facts"][0]["id"] == "proj.make:bad_name");
    CHECK_FALSE(fsys::exists(h.proj.path / "AGENTS.md"));

    auto bad = h.registry.call("ai.saver_group", Json::object({{"role", "orchestrator"}, {"group", "gfxx"}, {"answer", "accept"}}));
    REQUIRE_FALSE(bad.ok);
    CHECK(has(bad.error["hint"].get<std::string>(), "gfx"));
    auto group = h.registry.call("ai.saver_group", Json::object({{"role", "orchestrator"}, {"group", "gfx"}, {"answer", "accept"}}));
    REQUIRE(group.ok);
    CHECK(group.result["status"] == "accepted");
    auto fact = h.registry.call("ai.saver_fact", Json::object({{"id", "proj.make:bad_name"}, {"answer", "accept"}}));
    REQUIRE(fact.ok);
    CHECK(has(read_file(h.agents()), "proj.make"));

    state = h.registry.call("ai.savers");
    CHECK(state.result["proposals"]["toolGroups"].empty());
    CHECK(state.result["proposals"]["facts"].empty());
    CHECK(state.result["acceptedGroups"]["orchestrator"][0] == "gfx");
    auto wrong = h.registry.call("ai.saver_fact", Json::object({{"id", "proj.make:bad_name"}, {"answer", "maybe"}}));
    REQUIRE_FALSE(wrong.ok);
    CHECK(wrong.error["code"] == "invalid_arguments");
}
