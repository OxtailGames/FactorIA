// Efficiency feedback (fa/tooling/efficiency.h, docs/ENGINE_FEEDBACK.md "Efficiency feedback"): transcripts are read into steps, a span is
// measured, and the report gate refuses what is not measured, not the cheapest fix, or not worth filing. Nothing here asks a model.
#include <doctest.h>

#include <filesystem>
#include <string>

#include "fa/core/date.h"
#include "fa/tooling/efficiency.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_share.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;

namespace {

constexpr std::int64_t kT0 = 1'800'000'000'000;  // ms: 2027-01-15

std::string at(std::int64_t secondsAfterStart) { return iso_utc_ms(kT0 + secondsAfterStart * 1000); }

// A built-in agent transcript of `n` steps, one minute each, each with one scene.inspect call and `tokensPerStep` tokens.
std::string builtin_session(int n, std::uint64_t tokensPerStep = 5000, double costPerStep = 0.05) {
    std::string out = Json::object({{"kind", "start"}, {"t", at(0)}}).dump() + "\n";
    for (int i = 1; i <= n; ++i) {
        const std::string id = "tu" + std::to_string(i);
        Json input = Json::object({{"command", "scene.inspect"}, {"arguments", Json::object({{"entity", "player"}})}});
        Json content = Json::array({Json::object({{"type", "tool_use"}, {"id", id}, {"name", "tool_call"}, {"input", input}})});
        out += Json::object({{"kind", "assistant"}, {"t", at(60 * i - 1)},
                             {"usage", Json::object({{"inputTokens", tokensPerStep - 500}, {"outputTokens", 500}})},
                             {"costUsd", costPerStep}, {"content", content}}).dump() + "\n";
        Json result = Json::object({{"toolUseId", id}, {"isError", i % 10 == 0}, {"ms", 40}, {"content", i % 10 == 0 ? "{\"code\":\"not_found\",\"message\":\"no\"}" : "ok"}});
        out += Json::object({{"kind", "tool_results"}, {"t", at(60 * i)}, {"results", Json::array({result})}}).dump() + "\n";
    }
    return out;
}

struct Project {
    testing::TempDir dir;
    testing::TempDir home;
    ShareEnv env;
    Project() {
        const std::string h = home.str();
        env.env = [h](const std::string& name) -> std::string { return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? h : ""; };
    }
    void session(const std::string& id, const std::string& text) { testing::write_all(dir.path / ".factoria" / "ai" / "sessions" / (id + ".jsonl"), text); }
};

EfficiencyInput good_input() {
    EfficiencyInput in;
    in.category = "scene";
    in.title = "Quantum flux calibration routine";
    in.suggestion = "A topic guide that lists the three calibration calls in order";
    in.waste = "Working out the order of the flux calibration calls took forty steps of trial";
    in.fixType = "guide";
    in.appliesTo = "every-game";
    in.saveShare = 0.5;
    in.saveWhy = "the guide gives the calls in order";
    in.evidence = {{"s1", 1, 40}};
    return in;
}

}  // namespace

TEST_CASE("efficiency: a built-in transcript is read into steps with calls, times, tokens and failures") {
    const EfficiencySession s = read_efficiency_session(builtin_session(12), "s1");
    CHECK(s.agent == "builtin");
    CHECK(s.hasTimes);
    CHECK_FALSE(s.estimated);
    REQUIRE(s.steps.size() == 12);
    CHECK(s.steps[0].tokens == 5000);
    CHECK(s.steps[0].costUsd == doctest::Approx(0.05));
    REQUIRE(s.steps[0].calls.size() == 1);
    CHECK(s.steps[0].calls[0].command == "scene.inspect");  // the tool_call wrapper names the command it runs
    CHECK(s.steps[0].calls[0].ref == "player");
    CHECK(s.steps[0].calls[0].ms == 40);
    CHECK_FALSE(s.steps[0].calls[0].failed);
    CHECK(s.steps[9].calls[0].failed);
    CHECK(s.steps[9].calls[0].code == "not_found");
    CHECK(s.skippedLines == 0);
}

TEST_CASE("efficiency: lines that are not JSON are skipped and counted, a missing time keeps the one before") {
    std::string text = builtin_session(3) + "this is not json\n{\"kind\":\"assistant\",\"usage\":{\"inputTokens\":10}}\n";
    const EfficiencySession s = read_efficiency_session(text, "x");
    CHECK(s.skippedLines == 1);
    REQUIRE(s.steps.size() == 4);
    CHECK(s.steps[3].endMs == s.steps[2].endMs);
}

TEST_CASE("efficiency: a CLI agent transcript has one step per model turn, tokens estimated from bytes") {
    std::string t;
    auto line = [&](const Json& j) { t += j.dump() + "\n"; };
    line(Json::object({{"kind", "start"}, {"t", at(0)}}));
    line(Json::object({{"kind", "thinking"}, {"t", at(5)}, {"text", std::string(375, 'a')}}));
    line(Json::object({{"kind", "tool_start"}, {"t", at(6)}, {"tool", "Bash"}, {"id", "c1"},
                       {"input", Json::object({{"command", "factoria call scene.inspect --project . player"}})}}));
    line(Json::object({{"kind", "tool_end"}, {"t", at(30)}, {"tool", "Bash"}, {"id", "c1"}, {"ms", 24000},
                       {"result", "{\"code\":\"not_found\",\"message\":\"no entity\"}"}}));
    line(Json::object({{"kind", "text"}, {"t", at(40)}, {"text", "next"}}));
    line(Json::object({{"kind", "tool_start"}, {"t", at(41)}, {"tool", "Read"}, {"id", "c2"}, {"input", Json::object({{"file_path", "docs/A.md"}})}}));
    line(Json::object({{"kind", "tool_end"}, {"t", at(50)}, {"tool", "Read"}, {"id", "c2"}, {"ms", 9000}, {"result", "text"}}));
    const EfficiencySession s = read_efficiency_session(t, "cli1");
    CHECK(s.agent == "cli");
    CHECK(s.estimated);
    REQUIRE(s.steps.size() == 2);
    REQUIRE(s.steps[0].calls.size() == 1);
    CHECK(s.steps[0].calls[0].command == "scene.inspect");  // `factoria call X` inside a shell tool
    CHECK(s.steps[0].calls[0].failed);
    CHECK(s.steps[0].calls[0].code == "not_found");
    CHECK(s.steps[0].tokens > 100);
    CHECK(s.steps[1].calls[0].command == "Read");
    CHECK(s.steps[1].calls[0].ref == "docs/A.md");
    const EfficiencyMeasure m = measure_span(s, 1, 2);
    CHECK(m.estimated);
    CHECK(m.costUsd == 0);
    CHECK(m.toolCalls == 2);
    CHECK(m.minutes == doctest::Approx(0.8));  // 50 s
}

TEST_CASE("efficiency: measure_span counts the span, from the end of the step before it") {
    const EfficiencySession s = read_efficiency_session(builtin_session(40), "s1");
    const EfficiencyMeasure all = measure_span(s, 1, 40);
    CHECK(all.steps == 40);
    CHECK(all.toolCalls == 40);
    CHECK(all.minutes == doctest::Approx(40.0));
    CHECK(all.tokens == 200000);
    CHECK(all.costUsd == doctest::Approx(2.0));
    const EfficiencyMeasure mid = measure_span(s, 3, 5);
    CHECK(mid.steps == 3);
    CHECK(mid.minutes == doctest::Approx(3.0));
    CHECK(mid.tokens == 15000);
    CHECK(measure_span(s, 30, 99).steps == 11);  // clamped to the steps there are
    CHECK(measure_span(s, 9, 3).steps == 0);
    const EfficiencyMeasure half = scale_measure(all, 0.5);
    CHECK(half.minutes == doctest::Approx(20.0));
    CHECK(half.tokens == 100000);
    // the same transcript always gives the same numbers
    CHECK(measure_span(read_efficiency_session(builtin_session(40), "s1"), 1, 40).to_json() == all.to_json());
}

TEST_CASE("efficiency: the threshold table in docs/ENGINE_FEEDBACK.md is the one the gate uses") {
    const std::string doc = testing::read_text(std::filesystem::path(FA_REPO_ROOT) / "docs" / "ENGINE_FEEDBACK.md");
    CHECK_MESSAGE(doc.find(efficiency_threshold_table()) != std::string::npos,
                  "docs/ENGINE_FEEDBACK.md must contain, verbatim:\n" << efficiency_threshold_table());
}

TEST_CASE("efficiency gate: a measured report with the cheapest fix passes and is measured, not guessed") {
    Project p;
    p.session("s1", builtin_session(40));
    EfficiencyVerdict v;
    auto r = check_efficiency_report(p.dir.str(), good_input(), v);
    REQUIRE_MESSAGE(!r, r->message);
    CHECK(v.measured.steps == 40);
    CHECK(v.measured.minutes == doctest::Approx(40.0));
    CHECK(v.saving.minutes == doctest::Approx(20.0));
    CHECK(v.saving.tokens == 100000);
    CHECK_FALSE(v.candidateOnly);
    REQUIRE(v.spanMeasures.size() == 1);
}

TEST_CASE("efficiency gate: every refusal says what is wrong and what to do") {
    Project p;
    p.session("s1", builtin_session(40));
    auto refusal = [&](const EfficiencyInput& in) {
        EfficiencyVerdict v;
        auto r = check_efficiency_report(p.dir.str(), in, v);
        REQUIRE(r);
        CHECK_FALSE(r->message.empty());
        CHECK_FALSE(r->hint.empty());
        return *r;
    };
    SUBCASE("a fix type that does not exist") {
        EfficiencyInput in = good_input();
        in.fixType = "guid";
        const auto r = refusal(in);
        CHECK(r.code == "invalid_argument");
        CHECK(r.message.find("/fixType") != std::string::npos);
        CHECK(r.message.find("guide") != std::string::npos);  // did you mean
    }
    SUBCASE("a lesson only true for this game is a project fact") {
        EfficiencyInput in = good_input();
        in.appliesTo = "this-game";
        const auto r = refusal(in);
        CHECK(r.code == "project_fact");
        CHECK(r.hint.find("project fact") != std::string::npos);
    }
    SUBCASE("a model, effort or limit is the user's setting") {
        EfficiencyInput in = good_input();
        in.suggestion = "Use a cheaper model for the calibration steps";
        CHECK(refusal(in).code == "user_setting");
    }
    SUBCASE("no evidence") {
        EfficiencyInput in = good_input();
        in.evidence.clear();
        const auto r = refusal(in);
        CHECK(r.code == "no_evidence");
        CHECK(r.message.find("/evidence") != std::string::npos);
    }
    SUBCASE("a session that does not exist names the ones that do") {
        EfficiencyInput in = good_input();
        in.evidence = {{"s2", 1, 5}};
        const auto r = refusal(in);
        CHECK(r.code == "no_evidence");
        CHECK(r.message.find("/evidence/0/session") != std::string::npos);
        CHECK(r.hint.find("s1") != std::string::npos);
    }
    SUBCASE("a step that is not in the session") {
        EfficiencyInput in = good_input();
        in.evidence = {{"s1", 1, 41}};
        const auto r = refusal(in);
        CHECK(r.code == "no_evidence");
        CHECK(r.message.find("40 steps") != std::string::npos);
    }
    SUBCASE("spans that overlap would count the same steps twice") {
        EfficiencyInput in = good_input();
        in.evidence = {{"s1", 1, 20}, {"s1", 20, 40}};
        const auto r = refusal(in);
        CHECK(r.message.find("overlaps") != std::string::npos);
    }
    SUBCASE("a command option that is not shown to be the cheapest fix") {
        EfficiencyInput in = good_input();
        in.fixType = "commandOption";
        const auto r = refusal(in);
        CHECK(r.code == "not_cheapest");
        CHECK(r.message.find("/whyNotCheaper") != std::string::npos);
    }
    SUBCASE("a new command for one feature only") {
        EfficiencyInput in = good_input();
        in.fixType = "newCommand";
        in.whyNotCheaper = "A guide cannot make three calls into one call for the model";
        in.appliesTo = "feature";
        const auto r = refusal(in);
        CHECK(r.code == "below_threshold");
        CHECK(r.message.find("every game or a genre") != std::string::npos);
    }
    SUBCASE("text loaded on every step must say how big it is, and must save more than it adds") {
        EfficiencyInput in = good_input();
        in.suggestion = "Add the calibration order to AGENTS.md so that it is always loaded";
        CHECK(refusal(in).code == "costs_every_step");
        in.everyStepTokens = 2500;  // 40 steps x 2500 = 100000 added, 100000 saved
        const auto r = refusal(in);
        CHECK(r.code == "costs_every_step");
        CHECK(r.message.find("100000") != std::string::npos);
        in.everyStepTokens = 1000;  // 40000 added, 100000 saved
        EfficiencyVerdict v;
        CHECK_FALSE(check_efficiency_report(p.dir.str(), in, v));
    }
    SUBCASE("a missing waste or share") {
        EfficiencyInput in = good_input();
        in.waste = "slow";
        CHECK(refusal(in).message.find("/waste") != std::string::npos);
        in = good_input();
        in.saveShare = 0;
        CHECK(refusal(in).message.find("/expectedSaving/share") != std::string::npos);
        in = good_input();
        in.saveShare = 1.5;
        CHECK(refusal(in).message.find("/expectedSaving/share") != std::string::npos);
    }
}

TEST_CASE("efficiency gate: the threshold of a fix type is where the saving is enough") {
    Project p;
    p.session("s1", builtin_session(40));  // 40 minutes, 200k tokens
    EfficiencyVerdict v;
    EfficiencyInput in = good_input();
    in.saveShare = 0.25;  // 10 minutes, 50k tokens: exactly the minutes of a doc or a guide
    CHECK_FALSE(check_efficiency_report(p.dir.str(), in, v));
    in.saveShare = 0.24;  // 9.6 minutes, 48k tokens
    auto r = check_efficiency_report(p.dir.str(), in, v);
    REQUIRE(r);
    CHECK(r->code == "below_threshold");
    CHECK(r->message.find("10 minutes or 100k tokens") != std::string::npos);
    CHECK(r->hint.find("Not worth filing") != std::string::npos);

    in = good_input();
    in.fixType = "example";
    in.saveShare = 0.3;  // 12 minutes, 60k tokens: a guide would do, an example needs 15 minutes
    r = check_efficiency_report(p.dir.str(), in, v);
    REQUIRE(r);
    CHECK(r->code == "below_threshold");
    CHECK(r->hint.find("doc, guide") != std::string::npos);  // what this saving does justify
}

TEST_CASE("efficiency gate: an engine change is a candidate, justified by hours or dollars") {
    Project p;
    p.session("s1", builtin_session(120, 5000, 0.1));  // 120 minutes, $12
    EfficiencyInput in = good_input();
    in.fixType = "engineChange";
    in.whyNotCheaper = "No doc or example can remove the rebuild the engine does on every call";
    in.evidence = {{"s1", 1, 120}};
    in.saveShare = 0.5;  // 60 minutes, $6
    EfficiencyVerdict v;
    REQUIRE_FALSE(check_efficiency_report(p.dir.str(), in, v));
    CHECK(v.candidateOnly);
}

TEST_CASE("efficiency gate: a missing guide for a doc that docs.search finds is refused, unless findability is the report") {
    Project p;
    p.session("s1", builtin_session(40));
    EfficiencyInput in = good_input();
    in.title = "Off-mesh links: jumps, climbs and drops";
    in.suggestion = "A guide for off-mesh links, jumps and drops";
    EfficiencyVerdict v;
    auto r = check_efficiency_report(p.dir.str(), in, v);
    REQUIRE(r);
    CHECK(r->code == "exists_in_docs");
    CHECK(r->message.find("docs/") != std::string::npos);
    CHECK(r->hint.find("/searched") != std::string::npos);

    // Words that do find the section: not a findability report.
    in.searched = {"off-mesh links jumps climbs drops"};
    r = check_efficiency_report(p.dir.str(), in, v);
    REQUIRE(r);
    CHECK(r->code == "exists_in_docs");
    CHECK(r->message.find("/searched/0") != std::string::npos);

    // Words that do not find it: findability, the entry says where the doc is.
    in.searched = {"xylophone zzzqqq"};
    REQUIRE_FALSE(check_efficiency_report(p.dir.str(), in, v));
    CHECK_FALSE(v.existingDoc.empty());
}

TEST_CASE("efficiency: the input from JSON names the pointer of the field that is wrong") {
    EfficiencyInput in;
    auto r = efficiency_input_from_json(Json::parse(R"({"evidence":[{"session":"s","fromStep":"1","toStep":2}]})"), in);
    REQUIRE(r);
    CHECK(r->message.find("/evidence/0/fromStep") != std::string::npos);
    r = efficiency_input_from_json(Json::parse(R"({"expectedSaving":{"share":"most"}})"), in);
    REQUIRE(r);
    CHECK(r->message.find("/expectedSaving") != std::string::npos);
    r = efficiency_input_from_json(Json::parse(R"({"everyStepTokens":-3})"), in);
    REQUIRE(r);
    CHECK(r->message.find("/everyStepTokens") != std::string::npos);
    EfficiencyInput ok;
    REQUIRE_FALSE(efficiency_input_from_json(Json::parse(R"({"waste":"w w w","fixType":"doc","appliesTo":"genre","searched":"a b",
        "expectedSaving":{"share":0.5,"why":"x y"},"evidence":[{"session":"s","fromStep":1,"toStep":2}]})"), ok));
    CHECK(ok.fixType == "doc");
    CHECK(ok.searched == std::vector<std::string>{"a b"});
    CHECK(ok.evidence.size() == 1);
}

namespace {
Json report_args(int from, int to, double share = 0.5) {
    return Json::parse(R"({"kind":"efficiency","category":"scene","title":"Quantum flux calibration routine",
        "waste":"Working out the order of the flux calibration calls took forty steps of trial",
        "suggestion":"A topic guide that lists the three calibration calls in order","fixType":"guide","appliesTo":"every-game",
        "expectedSaving":{"share":)" + std::to_string(share) + R"(,"why":"the guide gives the calls in order"},
        "evidence":[{"session":"s1","fromStep":)" + std::to_string(from) + R"(,"toStep":)" + std::to_string(to) + "}]}");
}
}  // namespace

TEST_CASE("feedback.report kind efficiency: stored with the measured numbers, merged by fix, idempotent") {
    Project p;
    ScopedShareEnv scoped(p.env);
    p.session("s1", builtin_session(80));
    CommandRegistry registry;
    register_feedback_commands(registry, p.dir.str());
    const std::string file = p.dir.sub("ENGINE_FEEDBACK.json");

    auto first = registry.call("feedback.report", report_args(1, 40));
    REQUIRE_MESSAGE(first.ok, first.error.dump());
    CHECK(first.result["kind"] == "efficiency");
    CHECK(first.result["merged"] == false);
    CHECK(first.result["measured"]["steps"] == 40);
    CHECK(first.result["saving"]["tokens"] == 100000);
    CHECK_FALSE(first.result["message"].get<std::string>().empty());

    // The same evidence again: nothing is counted twice.
    auto again = registry.call("feedback.report", report_args(1, 40));
    REQUIRE_MESSAGE(again.ok, again.error.dump());
    CHECK(again.result["alreadyCounted"] == true);
    CHECK(load_feedback(file).value()["entries"][0]["occurrences"] == 1);

    // Other steps of the same waste, with another wording of the title: one entry, the numbers summed.
    Json second = report_args(41, 80);
    second["title"] = "Flux calibration routine for the quantum thing";
    auto merged = registry.call("feedback.report", second);
    REQUIRE_MESSAGE(merged.ok, merged.error.dump());
    CHECK(merged.result["merged"] == true);
    CHECK(merged.result["occurrences"] == 2);
    const Json doc = load_feedback(file).value();
    REQUIRE(doc["entries"].size() == 1);
    const Json& e = doc["entries"][0];
    CHECK(e["kind"] == "efficiency");
    CHECK(e["measured"]["steps"] == 80);
    CHECK(e["saving"]["tokens"] == 200000);
    CHECK(e["evidence"].size() == 2);
    CHECK_FALSE(e.contains("spans"));  // the per-span numbers are only for merging
    for (const auto& err : validate_feedback(doc)) CHECK_MESSAGE(false, err.to_string());

    // A different fix for the same words is another entry.
    Json other = report_args(1, 40);
    other["fixType"] = "example";
    other["expectedSaving"]["share"] = 0.9;
    auto ex = registry.call("feedback.report", other);
    REQUIRE_MESSAGE(ex.ok, ex.error.dump());
    CHECK(ex.result["merged"] == false);
    CHECK(load_feedback(file).value()["entries"].size() == 2);

    // list filters by kind
    auto list = registry.call("feedback.list", Json::object({{"kind", "gap"}}));
    REQUIRE(list.ok);
    CHECK(list.result["entries"].empty());
    CHECK(registry.call("feedback.list", Json::object({{"kind", "efficiency"}})).result["entries"].size() == 2);
    CHECK_FALSE(registry.call("feedback.list", Json::object({{"kind", "efficienty"}})).ok);
}

TEST_CASE("feedback.report kind efficiency: a refusal writes nothing and an unknown kind teaches") {
    Project p;
    ScopedShareEnv scoped(p.env);
    p.session("s1", builtin_session(40));
    CommandRegistry registry;
    register_feedback_commands(registry, p.dir.str());
    Json args = report_args(1, 40, 0.1);  // 4 minutes: under the threshold
    auto r = registry.call("feedback.report", args);
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.value("code", std::string()) == "below_threshold");
    CHECK_FALSE(std::filesystem::exists(p.dir.sub("ENGINE_FEEDBACK.json")));
    args["kind"] = "efficency";
    r = registry.call("feedback.report", args);
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("efficiency") != std::string::npos);
}
