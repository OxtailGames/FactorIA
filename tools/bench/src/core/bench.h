// The harness of `fa_bench` (docs/PERFORMANCE.md, "Microbenchmarks"): runs a benchmark with warm-up and repeats, summarises the
// timings (median and spread), writes and merges the JSON baseline file and compares a run with a baseline. It knows nothing
// about the engine except fa_core, so the comparison logic is tested on its own (tests/test_bench_compare.cpp).
#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <string>
#include <vector>

#include "fa/core/json.h"

namespace fa::bench {

inline constexpr const char* kFormat = "factoria.bench/1";

// What one benchmark gets ready. `run` is one timed iteration and returns a number that depends on the work done (a checksum): it
// keeps the optimizer from dropping the work and tells whether every repeat did the same work.
struct Prepared {
    std::function<void()> prepare;  // optional, untimed, before every run (warm-up too): puts the scene back as it was
    std::function<double()> run;
    std::int64_t items = 0;         // what one run processes (entities, bodies, calls...), for the report
    std::string unit;               // "entities"
    std::string skip;               // not empty: this benchmark cannot run here, and why ("no GPU: ...")
};

struct Bench {
    std::string name;     // "ecs.each"; the group is the part before the first dot
    std::string summary;  // one line: what it measures
    // How many times slower than the baseline's median a run may be before it warns / fails. CI machines are noisy, so the
    // defaults are wide; a benchmark that runs threads or a GPU driver gets wider ones.
    double warnRatio = 1.4;
    double failRatio = 2.0;
    std::function<Prepared()> make;  // builds the scene; called once, only for a benchmark the filter selected
};

struct Options {
    int warmup = 2;
    int repeats = 9;
};

struct Measurement {
    std::string name;
    bool skipped = false;
    std::string skipReason;
    int repeats = 0;
    double medianMs = 0, minMs = 0, maxMs = 0, p25Ms = 0, p75Ms = 0;  // wall clock of one run
    double cpuMedianMs = 0;                                           // CPU time of the process (all threads) of one run
    double spread = 0;                                                // (p75 - p25) / median: how much the repeats disagree
    bool sameWork = true;                                             // every repeat returned the same checksum
    std::int64_t items = 0;
    std::string unit;
};

// Median (average of the two middle values for an even count), and the nearest-rank quantile q in 0..1; 0 for an empty list.
double median_of(std::vector<double> v);
double quantile_of(std::vector<double> v, double q);
// The statistics of the given runs (milliseconds). `checksums` may be empty.
Measurement summarize(const std::string& name, const std::vector<double>& wallMs, const std::vector<double>& cpuMs,
                      const std::vector<double>& checksums);

// Prepares the benchmark (Bench::make), runs the warm-up and the repeats. A skipped benchmark has skipped = true and a reason.
Measurement run_bench(const Bench& bench, const Options& options);

// The id of this kind of machine and build for the baseline files: `<os>-<compiler>`, plus `-debug` for a build without NDEBUG.
// FACTORIA_BENCH_RUNNER overrides it (a build machine of your own).
std::string runner_id();

// ------------------------------------------------------------------------------------------------ the JSON file
// {format, runner, jobs, repeats, benchmarks: {name: {medianMs, minMs, maxMs, p25Ms, p75Ms, spread, cpuMedianMs, items, unit}}}.
// Floats are rounded to three decimals: the last digits differ between machines and mean nothing.
Json measurements_to_json(const std::string& runner, const std::string& jobs, int repeats, const std::vector<Measurement>& ms);
// `existing` (a baseline file, may be null) with the entries of `ms` replaced or added, the other entries and the hand-written
// "warnRatio" / "failRatio" of an entry kept. A skipped measurement changes nothing.
Json merge_baseline(const Json* existing, const std::string& runner, const std::string& jobs, int repeats,
                    const std::vector<Measurement>& ms);

// ------------------------------------------------------------------------------------------------ the comparison
enum class Verdict { Pass, Faster, Warn, Fail, NoBaseline, Skipped };

struct Thresholds {
    double warnRatio = 1.4;
    double failRatio = 2.0;
    double warnSlackMs = 0.2;  // a time under a millisecond moves by more than a ratio from one run to the next
    double failSlackMs = 0.5;
};

struct Comparison {
    std::string name;
    Verdict verdict = Verdict::NoBaseline;
    double baselineMs = 0, measuredMs = 0, ratio = 0;
    double warnLimitMs = 0, failLimitMs = 0;
    std::string message;  // one teaching sentence: the bench, the baseline, the measured value and what to do
};

const char* verdict_name(Verdict v);  // "pass", "faster", "warn", "fail", "no_baseline", "skipped"

// The command that refreshes the baseline file of a machine, for the messages.
std::string update_hint(const std::string& runner, const std::string& baselineFile);

// One benchmark against its entry of the baseline file (null = none). The limits are max(baseline * ratio, baseline + slack); an
// entry's own "warnRatio" / "failRatio" win over `defaults`. "Faster" is a run under 70% of the baseline: it passes and says the
// baseline can be refreshed.
Comparison compare_one(const std::string& name, const Json* baselineEntry, const Measurement& m, const Thresholds& defaults,
                       const std::string& runner, const std::string& baselineFile);

struct CompareReport {
    std::string runner;
    std::string baselineFile;
    std::string note;  // why there is no baseline at all ("no file for this runner"), empty when there is one
    std::vector<Comparison> rows;
    int count(Verdict v) const;
    bool failed(bool requireBaseline) const;  // a Fail row, or (requireBaseline) a NoBaseline one
    std::string text() const;                 // the messages of the rows that warn, fail, are faster or have no baseline
    Json to_json() const;
};

// All the measurements against `baselineFile` (null = no file for this runner: every row is NoBaseline). `perBench` holds the
// thresholds of each benchmark by name (missing = defaults). A baseline measured with another `jobs` mode is not compared.
CompareReport compare_all(const std::string& runner, const std::string& baselineFileName, const Json* baselineFile,
                          const std::string& jobs, const std::vector<Measurement>& ms,
                          const std::map<std::string, Thresholds>& perBench);

}  // namespace fa::bench
