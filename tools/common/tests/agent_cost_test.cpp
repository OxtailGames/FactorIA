// agent.cost (fa/tooling/agent_cost.h): the report over the transcript of one AI CLI run. A shortened Claude Code stream-json transcript
// in the shape of the real run in feedback/agent-cost/0.21.0-claude.json (whose own transcript was not kept): seven model messages, one
// engine error with a code and one failure without, a test that passed while its output showed a script error, a docs page that only
// quotes "TypeError", a play.auto that went through three levels, and the result line with that run's usage. Nothing here asks a model.
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
    return testing::read_text(std::filesystem::path(FA_REPO_ROOT) / "tools" / "common" / "tests" / "fixtures" /
                              "agent-cost" / "claude-stream.jsonl");
}
}  // namespace

TEST_CASE("agent cost: a stream-json transcript is read as steps of one model message each") {
    const EfficiencySession s = read_claude_stream_session(fixture(), "run");
    REQUIRE(s.steps.size() == 7);  // m1 streamed in two lines is one step
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
    in.finalPlay = Json::parse(
        R"({"ended":"won","phases":[{"n":1,"name":"scenes/main.scene.json","kind":"scene","time":0.0,"screenshot":"phase-1.png"}]})");
    const Json r = agent_cost_report(in);
    CHECK(r["total"]["steps"] == 7);
    CHECK(r["total"]["costUsd"].get<double>() == doctest::Approx(0.64));
    // The total is the CLI's own: input + output + cache write + cache read of the result line, not the sum of the partial per-step counts.
    CHECK(r["total"]["tokens"] == 78 + 21221 + 54956 + 2042078);
    CHECK(r["total"]["tokens"].get<std::uint64_t>() > r["total"]["stepTokens"].get<std::uint64_t>());
    CHECK(r["total"]["cliTurns"] == 56);
    CHECK(r["firstPlayable"]["reached"] == true);
    CHECK(r["firstPlayable"]["step"] == 4);
    CHECK(r["firstPlayable"]["toolCalls"] == 4);
    CHECK(r["firstPlayable"]["tokens"] == (10 + 9 + 20 + 100) + (5 + 20 + 130) + (5 + 30 + 160) + (5 + 40 + 200));
    CHECK(r["engineErrors"]["count"] ==
          1);  // the unknown command; `factoria run` that failed with no code is not counted
    CHECK(r["engineErrors"]["byCode"]["unknown_command"] == 1);
    CHECK_FALSE(r["engineErrors"]["byCode"].contains("none"));
    CHECK(r["engineErrors"]["first"][0]["step"] == 2);
    // The docs page of step 5 quotes TypeError after a passed test, and is not a script error of the game.
    REQUIRE(r["notCaught"]["count"] == 1);
    CHECK(r["notCaught"]["items"][0]["step"] == 3);
    CHECK(r["finalGame"]["reachedLastLevel"] == false);  // the final play.auto went through one level only
}

TEST_CASE("agent cost: the CLI version and a real HOME are recorded") {
    AgentCostInput in;
    in.transcript = fixture();
    in.cliVersion = "2.1.318 (Claude Code)";
    in.homeIsolated = 0;
    const Json r = agent_cost_report(in);
    CHECK(r["cliVersion"] == "2.1.318 (Claude Code)");
    bool named = false;
    for (const Json& n : r["notes"]) named = named || n.get<std::string>().find("real HOME") != std::string::npos;
    CHECK(named);
    in.homeIsolated = 1;
    const Json isolated =
        agent_cost_report(in);  // a named value: a range-for over `report(in)["notes"]` reads a destroyed temporary
    for (const Json& n : isolated["notes"]) CHECK(n.get<std::string>().find("real HOME") == std::string::npos);
}

TEST_CASE("agent cost: level names that only contain a menu word are levels") {
    const Json r =
        agent_cost_read_play_auto(R"({"ended":"won","phases":[{"name":"scenes/subtitle.scene.json","kind":"scene"},
        {"name":"scenes/twin.scene.json","kind":"scene"},{"name":"scenes/close.scene.json","kind":"scene"},{"name":"scenes/gloss.scene.json","kind":"scene"},
        {"name":"menu/level1.scene.json","kind":"scene"},{"name":"scenes/main_menu.scene.json","kind":"scene"}]})");
    CHECK(r["phases"] == 6);
    CHECK(r["levelPhases"] == 5);  // main_menu is a menu; the folder "menu/" does not make level1 one
}

TEST_CASE("agent cost: PascalCase menu and end screens are not levels, a mark is read whole") {
    const Json r =
        agent_cost_read_play_auto(R"({"ended":"won","phases":[{"name":"scenes/MainMenu.scene.json","kind":"scene"},
        {"name":"scenes/LevelWin.scene.json","kind":"scene"},{"name":"scenes/TitleScreen.scene.json","kind":"scene"},
        {"name":"scenes/GameOver.scene.json","kind":"scene"},{"name":"scenes/Subtitle.scene.json","kind":"scene"},
        {"name":"menu/open","kind":"mark"}]})");
    CHECK(r["phases"] == 6);
    CHECK(r["levelPhases"] == 1);  // Subtitle; the mark "menu/open" is a menu mark (read whole)
}

TEST_CASE("agent cost: a menu, a level and a win screen are one level, not three") {
    const Json menu = agent_cost_read_play_auto(
        R"({"ended":"won","endedWhy":"scripts/autoplay.js ended the run with \"won\"\nsecond line","phases":[
        {"n":1,"name":"scenes/menu.scene.json","kind":"scene"},{"n":2,"name":"scenes/main.scene.json","kind":"scene"},
        {"n":3,"name":"scenes/win.scene.json","kind":"scene"}]})");
    CHECK(menu["phases"] == 3);
    CHECK(menu["levelPhases"] == 1);
    CHECK(menu["endedWhy"] == "scripts/autoplay.js ended the run with \"won\"");
    AgentCostInput in;
    in.transcript = fixture();
    in.finalPlay = Json::parse(
        R"({"ended":"won","phases":[{"name":"scenes/menu.scene.json","kind":"scene"},{"name":"scenes/main.scene.json","kind":"scene"},{"name":"scenes/win.scene.json","kind":"scene"}]})");
    CHECK(agent_cost_report(in)["finalGame"]["reachedLastLevel"] == false);
    in.finalPlay = Json::parse(
        R"({"ended":"won","phases":[{"name":"scenes/main.scene.json","kind":"scene"},{"name":"scenes/level2.scene.json","kind":"scene"},{"name":"scenes/level3.scene.json","kind":"scene"}]})");
    CHECK(agent_cost_report(in)["finalGame"]["reachedLastLevel"] == true);
}

TEST_CASE("agent cost: a run without a result line or a playable build says so") {
    AgentCostInput in;
    in.transcript =
        R"({"type":"assistant","message":{"id":"m1","usage":{"output_tokens":4},"content":[{"type":"text","text":"hi"}]}})"
        "\n";
    const Json r = agent_cost_report(in);
    CHECK(r["firstPlayable"]["reached"] == false);
    CHECK(r["notes"].size() == 2);
    CHECK(r["engineErrors"]["count"] == 0);
}

TEST_CASE("agent cost: a play.auto answer is read whole or cut") {
    const Json whole = agent_cost_read_play_auto(
        R"(note {"ended":"won","phases":[{"n":1,"name":"scenes/a.scene.json","kind":"scene"},{"n":2,"name":"boss","kind":"mark"},{"n":3,"name":"boss","kind":"mark"}],"scriptErrors":[1,2]} end)");
    CHECK(whole["phases"] == 2);  // the same mark twice is one phase
    CHECK(whole["ended"] == "won");
    CHECK(whole["scriptErrors"] == 2);
    const Json cut = agent_cost_read_play_auto(R"("ended":"stuck","phases":[{"name":"a"},{"name":"b"},{"name":"c)");
    CHECK(cut["phases"] == 2);
    CHECK(cut["parsed"] == false);
    // Wrapped text: a "name" key outside the phases array is not a phase.
    const Json wrapped =
        agent_cost_read_play_auto(R"(log "phases": [{"name":"a"},{"name":"b"}] and later "name":"zzz", "name":"yyy")");
    CHECK(wrapped["phases"] == 2);
}
