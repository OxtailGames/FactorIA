// The harness of fa_bench: statistics, the baseline file and the comparison (pass, faster, warn, fail, no baseline).
#include <doctest.h>

#include <map>
#include <string>
#include <utility>
#include <vector>

#include "bench.h"

using namespace fa;
using namespace fa::bench;

namespace {

Measurement measured(const std::string& name, double medianMs, double spread = 0.05) {
    Measurement m;
    m.name = name;
    m.medianMs = m.minMs = m.maxMs = m.p25Ms = m.p75Ms = medianMs;
    m.cpuMedianMs = medianMs;
    m.spread = spread;
    m.repeats = 9;
    m.items = 100;
    m.unit = "things";
    return m;
}

// A baseline file with the given (name, medianMs) entries, measured with --jobs inline.
Json baseline_with(const std::vector<std::pair<std::string, double>>& entries, const std::string& jobs = "inline") {
    Json benchmarks = Json::object();
    for (const auto& [name, ms] : entries) benchmarks[name] = Json::object({{"medianMs", ms}, {"items", 100}});
    return Json::object(
        {{"format", kFormat}, {"runner", "linux-gcc"}, {"jobs", jobs}, {"repeats", 9}, {"benchmarks", benchmarks}});
}

Comparison compare(const Json& file, const Measurement& m, const std::map<std::string, Thresholds>& per = {}) {
    CompareReport r = compare_all("linux-gcc", "tools/bench/baselines/linux-gcc.json", &file, "inline", {m}, per);
    REQUIRE(r.rows.size() == 1);
    return r.rows[0];
}

}  // namespace

TEST_CASE("bench: median and quantiles") {
    CHECK(median_of({}) == 0.0);
    CHECK(median_of({5.0}) == 5.0);
    CHECK(median_of({9.0, 1.0, 5.0}) == 5.0);
    CHECK(median_of({4.0, 1.0, 3.0, 2.0}) == 2.5);
    CHECK(quantile_of({}, 0.5) == 0.0);
    CHECK(quantile_of({1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, 0.0) == 1.0);
    CHECK(quantile_of({1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, 1.0) == 10.0);
}

TEST_CASE("bench: summarize reports median, spread and whether the work repeated") {
    Measurement m = summarize("x", {10, 12, 11, 30, 10}, {9, 9, 9, 9, 9}, {4.0, 4.0, 4.0, 4.0, 4.0});
    CHECK(m.medianMs == 11.0);
    CHECK(m.minMs == 10.0);
    CHECK(m.maxMs == 30.0);
    CHECK(m.cpuMedianMs == 9.0);
    CHECK(m.sameWork);
    CHECK(m.spread > 0.0);
    CHECK(m.repeats == 5);
    Measurement different = summarize("x", {1, 1, 1}, {1, 1, 1}, {1.0, 2.0, 1.0});
    CHECK_FALSE(different.sameWork);
}

TEST_CASE("bench: run_bench runs the warm-up and the repeats, prepare before every run") {
    int prepared = 0, ran = 0;
    Bench b;
    b.name = "t.count";
    b.make = [&] {
        Prepared p;
        p.prepare = [&] { ++prepared; };
        p.run = [&] {
            ++ran;
            return 7.0;
        };
        p.items = 3;
        p.unit = "things";
        return p;
    };
    Options o;
    o.warmup = 2;
    o.repeats = 5;
    Measurement m = run_bench(b, o);
    CHECK_FALSE(m.skipped);
    CHECK(ran == 7);
    CHECK(prepared == 7);
    CHECK(m.repeats == 5);
    CHECK(m.sameWork);
    CHECK(m.items == 3);

    Bench skipped;
    skipped.name = "t.skip";
    skipped.make = [] {
        Prepared p;
        p.skip = "no GPU: nothing here";
        return p;
    };
    Measurement s = run_bench(skipped, o);
    CHECK(s.skipped);
    CHECK(s.skipReason == "no GPU: nothing here");
}

TEST_CASE("bench: a run inside the limits passes") {
    Json file = baseline_with({{"ecs.each", 10.0}});
    Comparison c = compare(file, measured("ecs.each", 11.0));
    CHECK(c.verdict == Verdict::Pass);
    CHECK(c.baselineMs == doctest::Approx(10.0));
    CHECK(c.ratio == doctest::Approx(1.1));
}

TEST_CASE("bench: a run under 70% of the baseline is faster and says the baseline can be refreshed") {
    Json file = baseline_with({{"ecs.each", 10.0}});
    Comparison c = compare(file, measured("ecs.each", 5.0));
    CHECK(c.verdict == Verdict::Faster);
    CHECK(c.message.find("Refresh the baseline") != std::string::npos);
}

TEST_CASE("bench: the warning band lies below the fail limit") {
    Json file = baseline_with({{"ecs.each", 10.0}});
    Comparison warn = compare(file, measured("ecs.each", 15.0));  // x1.5: over 1.4, under 2.0
    CHECK(warn.verdict == Verdict::Warn);
    CHECK(warn.warnLimitMs == doctest::Approx(14.0));
    CHECK(warn.failLimitMs == doctest::Approx(20.0));
    CHECK(warn.message.find("ecs.each") != std::string::npos);
    Comparison edge = compare(file, measured("ecs.each", 14.0));  // exactly the limit still passes
    CHECK(edge.verdict == Verdict::Pass);
}

TEST_CASE("bench: a run over the fail limit fails with a message that teaches") {
    Json file = baseline_with({{"ecs.each", 10.0}});
    Comparison c = compare(file, measured("ecs.each", 25.0));
    CHECK(c.verdict == Verdict::Fail);
    CHECK(c.message.find("ecs.each") != std::string::npos);           // the bench
    CHECK(c.message.find("25.") != std::string::npos);                // the measured value
    CHECK(c.message.find("10.") != std::string::npos);                // the baseline
    CHECK(c.message.find("--update-baseline") != std::string::npos);  // how to update it
    CHECK(c.message.find("linux-gcc") != std::string::npos);
}

TEST_CASE("bench: a tiny time moves by more than a ratio, so the limits have a floor in milliseconds") {
    Json file = baseline_with({{"command.call", 0.1}});
    CHECK(compare(file, measured("command.call", 0.28)).verdict == Verdict::Pass);  // x2.8, but under 0.1 + 0.2
    CHECK(compare(file, measured("command.call", 0.5)).verdict == Verdict::Warn);   // over 0.3, under 0.6
    CHECK(compare(file, measured("command.call", 0.7)).verdict == Verdict::Fail);   // over 0.6
}

TEST_CASE("bench: the ratios of an entry and of a bench change the limits") {
    Json file = baseline_with({{"a", 10.0}, {"b", 10.0}});
    file["benchmarks"]["a"]["warnRatio"] = 3.0;
    file["benchmarks"]["a"]["failRatio"] = 4.0;
    CHECK(compare(file, measured("a", 25.0)).verdict == Verdict::Pass);  // the entry's ratios, not the defaults
    CHECK(compare(file, measured("a", 35.0)).verdict == Verdict::Warn);
    CHECK(compare(file, measured("a", 41.0)).verdict == Verdict::Fail);
    Thresholds wide;
    wide.warnRatio = 1.6;
    wide.failRatio = 2.5;
    CHECK(compare(file, measured("b", 24.0), {{"b", wide}}).verdict == Verdict::Warn);  // the bench's own defaults
    CHECK(compare(file, measured("b", 26.0), {{"b", wide}}).verdict == Verdict::Fail);
}

TEST_CASE("bench: a bench without an entry has no baseline and does not fail unless asked") {
    Json file = baseline_with({{"ecs.each", 10.0}});
    CompareReport r = compare_all("linux-gcc", "tools/bench/baselines/linux-gcc.json", &file, "inline",
                                  {measured("ecs.each", 10.0), measured("physics.step2d", 3.0)}, {});
    REQUIRE(r.rows.size() == 2);
    CHECK(r.rows[0].verdict == Verdict::Pass);
    CHECK(r.rows[1].verdict == Verdict::NoBaseline);
    CHECK_FALSE(r.failed(false));
    CHECK(r.failed(true));
    const std::string text = r.text();
    CHECK(text.find("physics.step2d") != std::string::npos);
    CHECK(text.find("--update-baseline") != std::string::npos);
    CHECK(text.find("benchBaselines") != std::string::npos);
}

TEST_CASE("bench: a missing, foreign or other-jobs baseline file compares nothing and says why") {
    const std::vector<Measurement> ms = {measured("ecs.each", 999.0)};
    CompareReport none = compare_all("linux-gcc", "tools/bench/baselines/linux-gcc.json", nullptr, "inline", ms, {});
    CHECK(none.rows[0].verdict == Verdict::NoBaseline);
    CHECK_FALSE(none.failed(false));
    CHECK(none.note.find("no baseline file") != std::string::npos);
    CHECK(none.text().find("linux-gcc") != std::string::npos);

    Json foreign = Json::object({{"format", "something/9"}, {"benchmarks", Json::object()}});
    CompareReport wrong = compare_all("linux-gcc", "f.json", &foreign, "inline", ms, {});
    CHECK(wrong.rows[0].verdict == Verdict::NoBaseline);
    CHECK(wrong.note.find(kFormat) != std::string::npos);

    Json other = baseline_with({{"ecs.each", 10.0}}, "4");
    CompareReport jobs = compare_all("linux-gcc", "f.json", &other, "inline", ms, {});
    CHECK(jobs.rows[0].verdict == Verdict::NoBaseline);
    CHECK(jobs.note.find("--jobs 4") != std::string::npos);
}

TEST_CASE("bench: a skipped benchmark is reported, never failed") {
    Json file = baseline_with({{"render.frame2d", 10.0}});
    Measurement m = measured("render.frame2d", 0.0);
    m.skipped = true;
    m.skipReason = "no GPU: no display";
    CompareReport r = compare_all("linux-gcc", "f.json", &file, "inline", {m}, {});
    CHECK(r.rows[0].verdict == Verdict::Skipped);
    CHECK_FALSE(r.failed(true));
    CHECK(r.text().find("no GPU: no display") != std::string::npos);
}

TEST_CASE("bench: the report counts verdicts and writes JSON") {
    Json file = baseline_with({{"a", 10.0}, {"b", 10.0}, {"c", 10.0}});
    CompareReport r = compare_all("linux-gcc", "f.json", &file, "inline",
                                  {measured("a", 10.0), measured("b", 15.0), measured("c", 30.0)}, {});
    CHECK(r.count(Verdict::Pass) == 1);
    CHECK(r.count(Verdict::Warn) == 1);
    CHECK(r.count(Verdict::Fail) == 1);
    CHECK(r.failed(false));
    Json j = r.to_json();
    CHECK(j["rows"].size() == 3);
    CHECK(j["rows"][2]["verdict"] == "fail");
    CHECK(j["runner"] == "linux-gcc");
}

TEST_CASE("bench: the baseline file merges, keeping other entries and the ratios written by hand") {
    Json old = baseline_with({{"keep.me", 1.0}, {"ecs.each", 10.0}});
    old["benchmarks"]["ecs.each"]["failRatio"] = 3.5;
    Measurement fresh = measured("ecs.each", 12.3456);
    Measurement added = measured("new.bench", 2.0);
    Measurement skipped = measured("render.frame2d", 0.0);
    skipped.skipped = true;
    Json merged = merge_baseline(&old, "linux-gcc", "inline", 9, {fresh, added, skipped});
    CHECK(merged["format"] == kFormat);
    CHECK(merged["runner"] == "linux-gcc");
    CHECK(merged["benchmarks"].contains("keep.me"));
    CHECK(merged["benchmarks"]["ecs.each"]["medianMs"].get<double>() == doctest::Approx(12.346));  // three decimals
    CHECK(merged["benchmarks"]["ecs.each"]["failRatio"] == 3.5);
    CHECK(merged["benchmarks"].contains("new.bench"));
    CHECK_FALSE(merged["benchmarks"].contains("render.frame2d"));

    Json fromNothing = merge_baseline(nullptr, "linux-gcc", "inline", 9, {fresh});
    CHECK(fromNothing["benchmarks"].size() == 1);
    // What merge_baseline writes is what compare_all reads back.
    CompareReport back = compare_all("linux-gcc", "f.json", &fromNothing, "inline", {measured("ecs.each", 12.4)}, {});
    CHECK(back.rows[0].verdict == Verdict::Pass);
}

TEST_CASE("bench: the runner id names the OS and the compiler") {
    const std::string id = runner_id();
    CHECK_FALSE(id.empty());
    CHECK(id.find('-') != std::string::npos);
}
