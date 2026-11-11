// agent.cost (fa/tooling/agent_cost.h): the report over the transcript of one AI CLI run. A recorded (shortened) Claude Code stream-json
// transcript: five model messages, one engine error, a test that passed while its output showed a script error, and a play.auto that
// went through three levels. Nothing here asks a model.
#include <doctest.h>

#include <filesystem>
#include <string>

#include "fa/tooling/agent_cost.h"
#include "fa/tooling/efficiency.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;

namespace {
std::string fixture() {
    return testing::read_text(std::filesystem::path(FA_REPO_ROOT) / "tools" / "common" / "tests" / "fixtures" / "agent-cost" / "claude-stream.jsonl");
}
}  // namespace

TEST_CASE("agent cost: a stream-json transcript is read as steps of one model message each") {
    const EfficiencySession s = read_claude_stream_session(fixture(), "run");
    REQUIRE(s.steps.size() == 5);  // m1 streamed in two lines is one step
    CHECK(s.skippedLines == 0);
    CHECK(s.steps[0].tokens == 10u + 9u + 20u + 100u);  // the largest each field reached
    REQUIRE(s.steps[1].calls.size() == 1);
    CHECK(s.steps[1].calls[0].command == "scene.nope");
    CHECK(s.steps[1].calls[0].failed);
    CHECK(s.steps[1].calls[0].code == "unknown_command");
    CHECK(s.steps[3].calls[0].command == "play.auto");  // `--project .` before the command is skipped
    CHECK_FALSE(s.estimated);
}

TEST_CASE("agent cost: the report finds the first playable build, the engine errors and the ones nothing caught") {
    AgentCostInput in;
    in.transcript = fixture();
    in.cli = "claude";
    in.model = "sonnet";
    in.finalPlay = Json::parse(R"({"ended":"won","phases":[{"n":1,"name":"scenes/main.scene.json","kind":"scene","time":0.0,"screenshot":"phase-1.png"}]})");
    const Json r = agent_cost_report(in);
    CHECK(r["total"]["steps"] == 5);
    CHECK(r["total"]["costUsd"].get<double>() == doctest::Approx(0.12));
    CHECK(r["firstPlayable"]["reached"] == true);
    CHECK(r["firstPlayable"]["step"] == 4);
    CHECK(r["firstPlayable"]["toolCalls"] == 4);
    CHECK(r["firstPlayable"]["tokens"] == (10 + 9 + 20 + 100) + (5 + 20 + 130) + (5 + 30 + 160) + (5 + 40 + 200));
    CHECK(r["engineErrors"]["count"] == 1);
    CHECK(r["engineErrors"]["byCode"]["unknown_command"] == 1);
    CHECK(r["engineErrors"]["first"][0]["step"] == 2);
    REQUIRE(r["notCaught"]["count"] == 1);
    CHECK(r["notCaught"]["items"][0]["step"] == 3);
    CHECK(r["finalGame"]["reachedLastLevel"] == false);  // the final play.auto went through one level only
}

TEST_CASE("agent cost: a run without a result line or a playable build says so") {
    AgentCostInput in;
    in.transcript = R"({"type":"assistant","message":{"id":"m1","usage":{"output_tokens":4},"content":[{"type":"text","text":"hi"}]}})" "\n";
    const Json r = agent_cost_report(in);
    CHECK(r["firstPlayable"]["reached"] == false);
    CHECK(r["notes"].size() == 2);
    CHECK(r["engineErrors"]["count"] == 0);
}

TEST_CASE("agent cost: a play.auto answer is read whole or cut") {
    const Json whole = agent_cost_read_play_auto(R"(note {"ended":"won","phases":[{"n":1,"name":"scenes/a.scene.json","kind":"scene"},{"n":2,"name":"boss","kind":"mark"},{"n":3,"name":"boss","kind":"mark"}],"scriptErrors":[1,2]} end)");
    CHECK(whole["phases"] == 2);  // the same mark twice is one phase
    CHECK(whole["ended"] == "won");
    CHECK(whole["scriptErrors"] == 2);
    const Json cut = agent_cost_read_play_auto(R"("ended":"stuck","phases":[{"name":"a"},{"name":"b"},{"name":"c)");
    CHECK(cut["phases"] == 2);
    CHECK(cut["parsed"] == false);
}
