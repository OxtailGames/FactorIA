// ai.session_timeline: gaps with what was going on, totals, logs without times.
#include <fstream>

#include "fa/ai/commands.h"
#include "fa/ai/session.h"
#include "fa/core/date.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

TEST_CASE("iso_utc_ms and parse_iso_utc_ms are inverse") {
    std::int64_t ms = 0;
    REQUIRE(parse_iso_utc_ms("2026-10-30T14:03:22.481Z", ms));
    CHECK(iso_utc_ms(ms) == "2026-10-30T14:03:22.481Z");
    std::int64_t again = 0;
    REQUIRE(parse_iso_utc_ms("2026-10-30T14:03:23Z", again));
    CHECK(again - ms == 519);
    CHECK_FALSE(parse_iso_utc_ms("yesterday", ms));
    CHECK_FALSE(parse_iso_utc_ms("2026-02-30T00:00:00Z", ms));
    CHECK(iso_utc_ms(0) == "1970-01-01T00:00:00.000Z");
}

TEST_CASE("session timeline: gaps are labelled by what ended them, totals add up") {
    const std::string log =
        R"({"kind":"start","t":"2026-10-30T10:00:00.000Z"}
{"kind":"user","t":"2026-10-30T10:00:00.100Z"}
{"kind":"thinking","t":"2026-10-30T10:01:10.100Z","text":"","ms":70000}
{"kind":"tool_start","t":"2026-10-30T10:01:11.000Z","tool":"Bash"}
{"kind":"tool_end","t":"2026-10-30T10:03:11.000Z","tool":"Bash","ms":120000}
{"kind":"text","t":"2026-10-30T10:03:15.000Z"}
{"kind":"tool_start","t":"2026-10-30T10:03:16.000Z","tool":"AskUserQuestion"}
{"kind":"tool_end","t":"2026-10-30T10:04:16.000Z","tool":"AskUserQuestion","ms":60000}
{"kind":"end","t":"2026-10-30T10:04:17.000Z"}
)";
    Json tl = session_timeline_from_text(log, 30);
    CHECK(tl["hasTimes"] == true);
    CHECK(tl["totalSeconds"] == 257);
    REQUIRE(tl["gaps"].size() == 3);
    CHECK(tl["gaps"][0]["activity"] == "thinking");
    CHECK(tl["gaps"][0]["seconds"] == 70);
    CHECK(tl["gaps"][1]["activity"] == "tool");
    CHECK(tl["gaps"][1]["detail"].get<std::string>().find("Bash") != std::string::npos);
    CHECK(tl["gaps"][2]["activity"] == "user");
    CHECK(tl["totals"]["tool"]["seconds"] == 120);
    CHECK(tl["totals"]["tool"]["byTool"][0]["tool"] == "Bash");
    CHECK(tl["totals"]["thinking"]["seconds"] == 70);
    CHECK(tl["totals"]["user"]["seconds"] == 60);
    // a shorter threshold lists more gaps; totals do not change
    Json all = session_timeline_from_text(log, 0);
    CHECK(all["gaps"].size() == 8);
    CHECK(all["totals"]["model"]["count"] == 5);
    // the built-in agent's lines: assistant = the model, tool_results = the tools
    Json chat = session_timeline_from_text(
        R"({"kind":"start","t":"2026-10-30T10:00:00.000Z"}
{"kind":"assistant","t":"2026-10-30T10:00:20.000Z","ms":20000}
{"kind":"tool_results","t":"2026-10-30T10:00:50.000Z","results":[{"tool":"scene_spawn","ms":30000}]}
)", 25);
    REQUIRE(chat["gaps"].size() == 1);
    CHECK(chat["gaps"][0]["activity"] == "tool");
    CHECK(chat["totals"]["model"]["seconds"] == 20);
}

TEST_CASE("session timeline: an old log without times says so, and the command finds the newest session") {
    Json old = session_timeline_from_text("{\"kind\":\"start\"}\n{\"kind\":\"end\"}\n", 30);
    CHECK(old["hasTimes"] == false);
    CHECK(old["note"].get<std::string>().find("no times") != std::string::npos);
    CHECK(old["gaps"].empty());

    TempDir dir;
    auto sessions = dir.path / ".factoria" / "ai" / "sessions";
    std::filesystem::create_directories(sessions);
    std::ofstream(sessions / "20261030-100000-orchestrator.jsonl")
        << "{\"kind\":\"start\",\"t\":\"2026-10-30T10:00:00.000Z\"}\n{\"kind\":\"end\",\"t\":\"2026-10-30T10:01:00.000Z\"}\n";
    CommandRegistry registry = make_registry();
    AiCommandOptions opt;
    opt.loadConfig = [] { return Result<AiConfig>(default_config()); };
    opt.projectDir = [&] { return dir.str(); };
    register_ai_commands(registry, opt);
    REQUIRE(registry.has("ai.session_timeline"));
    CHECK(registry.info("ai.session_timeline")->readOnly);
    auto r = registry.call("ai.session_timeline", Json::object({{"minGapSeconds", 10}}));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["gaps"].size() == 1);
    CHECK(r.result["session"].get<std::string>().find("20261030-100000-orchestrator.jsonl") != std::string::npos);
    auto named = registry.call("ai.session_timeline", Json::object({{"session", "20261030-100000-orchestrator"}}));
    CHECK(named.ok);
    auto missing = registry.call("ai.session_timeline", Json::object({{"session", "20261030-100001-orchestrator"}}));
    CHECK_FALSE(missing.ok);
    CHECK(missing.error["hint"].get<std::string>().find("20261030-100000-orchestrator") != std::string::npos);
}
