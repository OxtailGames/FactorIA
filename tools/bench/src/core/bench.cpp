#include "bench.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>

#include "fa/core/perf.h"

namespace fa::bench {

namespace {

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

std::string fmt(const char* format, double a) {
    char buf[96];
    std::snprintf(buf, sizeof buf, format, a);
    return buf;
}
std::string ms_text(double v) { return fmt(v >= 100 ? "%.0f ms" : (v >= 10 ? "%.1f ms" : "%.2f ms"), v); }

bool same_value(double a, double b) { return a == b || (std::isnan(a) && std::isnan(b)); }

}  // namespace

double quantile_of(std::vector<double> v, double q) {
    if (v.empty()) return 0.0;
    std::sort(v.begin(), v.end());
    // Nearest rank: the smallest value with at least a share q of the values at or below it.
    const std::size_t rank = static_cast<std::size_t>(std::ceil(std::clamp(q, 0.0, 1.0) * static_cast<double>(v.size())));
    return v[std::clamp<std::size_t>(rank, 1, v.size()) - 1];
}

double median_of(std::vector<double> v) {
    if (v.empty()) return 0.0;
    std::sort(v.begin(), v.end());
    const std::size_t n = v.size();
    return n % 2 ? v[n / 2] : (v[n / 2 - 1] + v[n / 2]) / 2.0;
}

Measurement summarize(const std::string& name, const std::vector<double>& wallMs, const std::vector<double>& cpuMs,
                      const std::vector<double>& checksums) {
    Measurement m;
    m.name = name;
    m.repeats = static_cast<int>(wallMs.size());
    if (wallMs.empty()) return m;
    m.medianMs = median_of(wallMs);
    m.minMs = *std::min_element(wallMs.begin(), wallMs.end());
    m.maxMs = *std::max_element(wallMs.begin(), wallMs.end());
    m.p25Ms = quantile_of(wallMs, 0.25);
    m.p75Ms = quantile_of(wallMs, 0.75);
    m.cpuMedianMs = median_of(cpuMs);
    m.spread = m.medianMs > 0 ? (m.p75Ms - m.p25Ms) / m.medianMs : 0.0;
    for (double c : checksums)
        if (!same_value(c, checksums.front())) m.sameWork = false;
    return m;
}

Measurement run_bench(const Bench& bench, const Options& options) {
    Measurement m;
    m.name = bench.name;
    Prepared p = bench.make();
    m.items = p.items;
    m.unit = p.unit;
    if (!p.skip.empty() || !p.run) {
        m.skipped = true;
        m.skipReason = p.skip.empty() ? "the benchmark has nothing to run" : p.skip;
        return m;
    }
    using Clock = std::chrono::steady_clock;
    volatile double sink = 0;  // the checksums land here: the work cannot be optimized away
    for (int i = 0; i < options.warmup; ++i) {
        if (p.prepare) p.prepare();
        sink = sink + p.run();
    }
    std::vector<double> wall, cpu, sums;
    for (int i = 0; i < std::max(1, options.repeats); ++i) {
        if (p.prepare) p.prepare();
        const double cpu0 = process_cpu_seconds();
        const auto t0 = Clock::now();
        const double sum = p.run();
        const auto t1 = Clock::now();
        const double cpu1 = process_cpu_seconds();
        sink = sink + sum;
        wall.push_back(std::chrono::duration<double, std::milli>(t1 - t0).count());
        cpu.push_back((cpu1 - cpu0) * 1000.0);
        sums.push_back(sum);
    }
    Measurement r = summarize(bench.name, wall, cpu, sums);
    r.items = p.items;
    r.unit = p.unit;
    return r;
}

std::string runner_id() {
    if (const char* env = std::getenv("FACTORIA_BENCH_RUNNER"); env && *env) return env;
#if defined(_WIN32)
    const char* os = "windows";
#elif defined(__ANDROID__)
    const char* os = "android";
#elif defined(__EMSCRIPTEN__)
    const char* os = "web";
#elif defined(__APPLE__)
    const char* os = "macos";
#else
    const char* os = "linux";
#endif
#if defined(_MSC_VER) && !defined(__clang__)
    const char* compiler = "msvc";
#elif defined(__clang__)
    const char* compiler = "clang";
#else
    const char* compiler = "gcc";
#endif
#if defined(NDEBUG)
    const char* build = "";
#else
    const char* build = "-debug";  // unoptimized code never meets a release baseline
#endif
    return std::string(os) + "-" + compiler + build;
}

// ------------------------------------------------------------------------------------------------ the JSON file

namespace {
Json entry_json(const Measurement& m) {
    return Json::object({{"medianMs", round3(m.medianMs)},
                         {"minMs", round3(m.minMs)},
                         {"maxMs", round3(m.maxMs)},
                         {"p25Ms", round3(m.p25Ms)},
                         {"p75Ms", round3(m.p75Ms)},
                         {"spread", round3(m.spread)},
                         {"cpuMedianMs", round3(m.cpuMedianMs)},
                         {"items", m.items},
                         {"unit", m.unit}});
}
}  // namespace

Json measurements_to_json(const std::string& runner, const std::string& jobs, int repeats, const std::vector<Measurement>& ms) {
    Json benchmarks = Json::object();
    for (const Measurement& m : ms)
        if (!m.skipped) benchmarks[m.name] = entry_json(m);
    return Json::object({{"format", kFormat},
                         {"runner", runner},
                         {"jobs", jobs},
                         {"repeats", repeats},
                         {"benchmarks", benchmarks}});
}

Json merge_baseline(const Json* existing, const std::string& runner, const std::string& jobs, int repeats,
                    const std::vector<Measurement>& ms) {
    Json out = measurements_to_json(runner, jobs, repeats, {});
    const Json* old = nullptr;
    if (existing && existing->is_object() && existing->contains("benchmarks") && (*existing)["benchmarks"].is_object())
        old = &(*existing)["benchmarks"];
    // The entries already there keep their place; a new one goes at the end.
    if (old)
        for (auto it = old->begin(); it != old->end(); ++it) out["benchmarks"][it.key()] = it.value();
    for (const Measurement& m : ms) {
        if (m.skipped) continue;
        Json entry = entry_json(m);
        if (old) {
            if (auto prev = old->find(m.name); prev != old->end() && prev->is_object())
                for (const char* key : {"warnRatio", "failRatio"})
                    if (auto k = prev->find(key); k != prev->end()) entry[key] = *k;
        }
        out["benchmarks"][m.name] = entry;
    }
    return out;
}

// ------------------------------------------------------------------------------------------------ the comparison

const char* verdict_name(Verdict v) {
    switch (v) {
        case Verdict::Pass: return "pass";
        case Verdict::Faster: return "faster";
        case Verdict::Warn: return "warn";
        case Verdict::Fail: return "fail";
        case Verdict::NoBaseline: return "no_baseline";
        case Verdict::Skipped: return "skipped";
    }
    return "pass";
}

std::string update_hint(const std::string& runner, const std::string& baselineFile) {
    const std::string file = baselineFile.empty() ? "tools/bench/baselines/" + runner + ".json" : baselineFile;
    return "On a machine of the kind '" + runner + "' (same OS, compiler and a Release build) run `fa_bench --update-baseline` "
           "(add --filter <name> for one benchmark); it rewrites " + file + ". For the CI runner, run the CI workflow by hand "
           "with benchBaselines ticked and copy the file from the artifact of the 'Bench baselines' job. A baseline is "
           "refreshed because the code got slower or faster on purpose, never only to make a check pass "
           "(docs/PERFORMANCE.md, \"Microbenchmarks\").";
}

Comparison compare_one(const std::string& name, const Json* baselineEntry, const Measurement& m, const Thresholds& defaults,
                       const std::string& runner, const std::string& baselineFile) {
    Comparison c;
    c.name = name;
    c.measuredMs = m.medianMs;
    if (m.skipped) {
        c.verdict = Verdict::Skipped;
        c.message = "Benchmark '" + name + "' did not run: " + m.skipReason + ".";
        return c;
    }
    if (!baselineEntry || !baselineEntry->is_object() || !baselineEntry->contains("medianMs") ||
        !(*baselineEntry)["medianMs"].is_number() || (*baselineEntry)["medianMs"].get<double>() <= 0.0) {
        c.verdict = Verdict::NoBaseline;
        c.message = "Benchmark '" + name + "' has no baseline for runner '" + runner + "' (measured " + ms_text(m.medianMs) +
                    "), so nothing was compared. " + update_hint(runner, baselineFile);
        return c;
    }
    Thresholds t = defaults;
    if (auto it = baselineEntry->find("warnRatio"); it != baselineEntry->end() && it->is_number()) t.warnRatio = it->get<double>();
    if (auto it = baselineEntry->find("failRatio"); it != baselineEntry->end() && it->is_number()) t.failRatio = it->get<double>();
    if (t.failRatio < t.warnRatio) t.failRatio = t.warnRatio;
    const double base = (*baselineEntry)["medianMs"].get<double>();
    c.baselineMs = base;
    c.ratio = m.medianMs / base;
    c.warnLimitMs = std::max(base * t.warnRatio, base + t.warnSlackMs);
    c.failLimitMs = std::max(base * t.failRatio, base + t.failSlackMs);
    const std::string where = "median " + ms_text(m.medianMs) + " against a baseline of " + ms_text(base) + " (x" +
                              fmt("%.2f", c.ratio) + ", spread " + fmt("%.0f%%", m.spread * 100.0) + ")";
    if (m.medianMs > c.failLimitMs) {
        c.verdict = Verdict::Fail;
        c.message = "Benchmark '" + name + "' got slower: " + where + "; it fails over " + ms_text(c.failLimitMs) +
                    " (x" + fmt("%.2f", t.failRatio) + "). If the engine really got slower, find the change that did it; if this "
                    "is the price of something you meant, refresh the baseline. " + update_hint(runner, baselineFile);
    } else if (m.medianMs > c.warnLimitMs) {
        c.verdict = Verdict::Warn;
        c.message = "Benchmark '" + name + "' is inside the warning band: " + where + "; it warns over " +
                    ms_text(c.warnLimitMs) + " and fails over " + ms_text(c.failLimitMs) +
                    ". A noisy machine does this; if it repeats on every run, the code got slower.";
    } else if (m.medianMs < base * 0.7 && base - m.medianMs > t.warnSlackMs) {
        c.verdict = Verdict::Faster;
        c.message = "Benchmark '" + name + "' got faster: " + where + ". Refresh the baseline to keep the gain from slipping "
                    "back unnoticed. " + update_hint(runner, baselineFile);
    } else {
        c.verdict = Verdict::Pass;
        c.message = "Benchmark '" + name + "': " + where + ".";
    }
    return c;
}

int CompareReport::count(Verdict v) const {
    int n = 0;
    for (const Comparison& c : rows)
        if (c.verdict == v) ++n;
    return n;
}

bool CompareReport::failed(bool requireBaseline) const {
    return count(Verdict::Fail) > 0 || (requireBaseline && count(Verdict::NoBaseline) > 0);
}

std::string CompareReport::text() const {
    std::string out = "Compared with ";
    out += baselineFile.empty() ? "no baseline file" : baselineFile;
    out += " (runner " + runner + "): " + std::to_string(count(Verdict::Pass)) + " pass, " +
           std::to_string(count(Verdict::Faster)) + " faster, " + std::to_string(count(Verdict::Warn)) + " warn, " +
           std::to_string(count(Verdict::Fail)) + " fail, " + std::to_string(count(Verdict::NoBaseline)) + " without baseline, " +
           std::to_string(count(Verdict::Skipped)) + " skipped.\n";
    if (!note.empty()) out += note + "\n";
    std::string missing;
    for (const Comparison& c : rows) {
        if (c.verdict == Verdict::Pass) continue;
        if (c.verdict == Verdict::NoBaseline) {  // the hint is the same for every row: say it once
            missing += (missing.empty() ? "" : ", ") + c.name;
            continue;
        }
        out += std::string(verdict_name(c.verdict)) + ": " + c.message + "\n";
    }
    if (!missing.empty() && note.empty())
        out += "no_baseline: " + missing + " have no baseline entry for runner '" + runner + "'; " +
               update_hint(runner, baselineFile) + "\n";
    return out;
}

Json CompareReport::to_json() const {
    Json rowsJson = Json::array();
    for (const Comparison& c : rows)
        rowsJson.push_back(Json::object({{"name", c.name},
                                         {"verdict", verdict_name(c.verdict)},
                                         {"baselineMs", round3(c.baselineMs)},
                                         {"measuredMs", round3(c.measuredMs)},
                                         {"ratio", round3(c.ratio)},
                                         {"warnLimitMs", round3(c.warnLimitMs)},
                                         {"failLimitMs", round3(c.failLimitMs)},
                                         {"message", c.message}}));
    return Json::object({{"runner", runner}, {"baselineFile", baselineFile}, {"note", note}, {"rows", rowsJson}});
}

CompareReport compare_all(const std::string& runner, const std::string& baselineFileName, const Json* baselineFile,
                          const std::string& jobs, const std::vector<Measurement>& ms,
                          const std::map<std::string, Thresholds>& perBench) {
    CompareReport report;
    report.runner = runner;
    report.baselineFile = baselineFileName;
    const Json* entries = nullptr;
    if (!baselineFile) {
        report.note = "There is no baseline file for runner '" + runner + "', so nothing was compared and the numbers of this "
                      "run are only reported. " + update_hint(runner, baselineFileName);
    } else if (!baselineFile->is_object() || baselineFile->value("format", std::string()) != kFormat ||
               !baselineFile->contains("benchmarks") || !(*baselineFile)["benchmarks"].is_object()) {
        report.note = "The baseline file " + baselineFileName + " is not a '" + kFormat + "' file (it needs \"format\" and a "
                      "\"benchmarks\" object), so nothing was compared. Write it with `fa_bench --update-baseline`.";
    } else if (baselineFile->contains("jobs") && (*baselineFile)["jobs"].is_string() &&
               (*baselineFile)["jobs"].get<std::string>() != jobs) {
        report.note = "The baseline " + baselineFileName + " was measured with --jobs " +
                      (*baselineFile)["jobs"].get<std::string>() + " and this run used --jobs " + jobs +
                      ", so nothing was compared. Run again with --jobs " + (*baselineFile)["jobs"].get<std::string>() +
                      " or refresh the baseline.";
    } else {
        entries = &(*baselineFile)["benchmarks"];
    }
    for (const Measurement& m : ms) {
        Thresholds t;
        if (auto it = perBench.find(m.name); it != perBench.end()) t = it->second;
        const Json* entry = nullptr;
        if (entries)
            if (auto it = entries->find(m.name); it != entries->end()) entry = &*it;
        report.rows.push_back(compare_one(m.name, entry, m, t, runner, baselineFileName));
    }
    return report;
}

}  // namespace fa::bench
