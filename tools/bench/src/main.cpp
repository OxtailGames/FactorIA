// fa_bench: the engine's microbenchmarks (docs/PERFORMANCE.md, "Microbenchmarks").
//
//   fa_bench [--filter a,b] [--list] [--repeats N] [--warmup N] [--jobs inline|auto|N] [--out FILE] [--json]
//            [--compare | --baseline FILE] [--baselines-dir DIR] [--require-baseline] [--retries N] [--report FILE]
//            [--update-baseline]
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <map>
#include <optional>
#include <sstream>
#include <string>
#include <vector>

#include "benches/benches.h"
#include "fa/core/fs.h"
#include "fa/core/jobs.h"
#include "fa/core/log.h"

using namespace fa;
using namespace fa::bench;

namespace {

struct Args {
    std::vector<std::string> filters;
    bool list = false, json = false, compare = false, requireBaseline = false, update = false, help = false;
    int repeats = 9, warmup = 2, retries = 2;
    std::string jobs = "inline";
    std::string out, baseline, baselinesDir, report;
};

const char* kUsage =
    "usage: fa_bench [options]\n"
    "  --list                 print the benchmarks and exit\n"
    "  --filter a,b           run the benchmarks whose name contains one of these words (ecs, physics.step3d...)\n"
    "  --repeats N            timed runs per benchmark (default 9); --warmup N untimed runs first (default 2)\n"
    "  --jobs inline|auto|N   the job system: inline (default, one thread: the steadiest numbers), auto, or N workers\n"
    "  --out FILE             write the measurements as JSON (the baseline format)\n"
    "  --json                 print the measurements as JSON instead of the table\n"
    "  --compare              compare with the baseline of this machine kind (<baselines dir>/<runner>.json)\n"
    "  --baseline FILE        compare with this file instead\n"
    "  --baselines-dir DIR    where the baselines are (default: tools/bench/baselines, found from here upwards)\n"
    "  --require-baseline     a benchmark without a baseline entry fails the comparison (default: it only warns)\n"
    "  --retries N            measure a benchmark that fails the comparison up to N more times, the best run counts (default 2)\n"
    "  --report FILE          write the comparison as JSON\n"
    "  --update-baseline      write the measurements into <baselines dir>/<runner>.json (the other entries stay)\n"
    "exit status: 0 = ok (also with warnings or no baseline), 1 = a benchmark got too slow, 2 = bad arguments\n";

std::vector<std::string> split(const std::string& s, char sep) {
    std::vector<std::string> out;
    std::string cur;
    std::stringstream ss(s);
    while (std::getline(ss, cur, sep))
        if (!cur.empty()) out.push_back(cur);
    return out;
}

bool parse_args(int argc, char** argv, Args& a, std::string& error) {
    auto need = [&](int& i, const char* flag) -> const char* {
        if (i + 1 >= argc) {
            error = std::string(flag) + " needs a value";
            return nullptr;
        }
        return argv[++i];
    };
    auto number = [&](const char* flag, const char* text, int lo, int hi, int& out) {
        char* end = nullptr;
        const long v = std::strtol(text, &end, 10);
        if (end == text || *end || v < lo || v > hi) {
            error = std::string(flag) + " takes a whole number from " + std::to_string(lo) + " to " + std::to_string(hi) +
                    ", got '" + text + "'";
            return false;
        }
        out = int(v);
        return true;
    };
    for (int i = 1; i < argc; ++i) {
        const std::string f = argv[i];
        const char* v = nullptr;
        if (f == "--list") a.list = true;
        else if (f == "--json") a.json = true;
        else if (f == "--compare") a.compare = true;
        else if (f == "--require-baseline") a.requireBaseline = true;
        else if (f == "--update-baseline") a.update = true;
        else if (f == "--help" || f == "-h") a.help = true;
        else if (f == "--filter") { if (!(v = need(i, "--filter"))) return false; for (auto& w : split(v, ',')) a.filters.push_back(w); }
        else if (f == "--repeats") { if (!(v = need(i, f.c_str())) || !number("--repeats", v, 1, 1000, a.repeats)) return false; }
        else if (f == "--warmup") { if (!(v = need(i, f.c_str())) || !number("--warmup", v, 0, 100, a.warmup)) return false; }
        else if (f == "--retries") { if (!(v = need(i, f.c_str())) || !number("--retries", v, 0, 10, a.retries)) return false; }
        else if (f == "--jobs") { if (!(v = need(i, f.c_str()))) return false; a.jobs = v; }
        else if (f == "--out") { if (!(v = need(i, f.c_str()))) return false; a.out = v; }
        else if (f == "--baseline") { if (!(v = need(i, f.c_str()))) return false; a.baseline = v; a.compare = true; }
        else if (f == "--baselines-dir") { if (!(v = need(i, f.c_str()))) return false; a.baselinesDir = v; }
        else if (f == "--report") { if (!(v = need(i, f.c_str()))) return false; a.report = v; }
        else {
            error = "unknown option '" + f + "'";
            return false;
        }
    }
    return true;
}

// tools/bench/baselines, looked for from the working directory upwards and then from the program's directory upwards.
std::filesystem::path find_baselines_dir(const char* argv0) {
    for (std::filesystem::path start : {std::filesystem::current_path(), std::filesystem::absolute(fs::path_from_utf8(argv0)).parent_path()}) {
        std::filesystem::path dir = start;
        for (int up = 0; up < 8 && !dir.empty(); ++up) {
            std::error_code ec;
            if (std::filesystem::is_directory(dir / "tools" / "bench" / "baselines", ec)) return dir / "tools" / "bench" / "baselines";
            if (dir == dir.parent_path()) break;
            dir = dir.parent_path();
        }
    }
    return {};
}

bool write_text_file(const std::filesystem::path& file, const std::string& text, std::string& error, bool append = false) {
    std::error_code ec;
    if (file.has_parent_path()) std::filesystem::create_directories(file.parent_path(), ec);
    std::ofstream f(file, std::ios::binary | (append ? std::ios::app : std::ios::trunc));
    f << text;
    f.flush();
    if (!f) {
        error = "cannot write " + fs::path_to_utf8(file);
        return false;
    }
    return true;
}

std::optional<Json> read_json_file(const std::filesystem::path& file, std::string& error) {
    std::ifstream f(file, std::ios::binary);
    if (!f) return std::nullopt;  // no such file
    std::stringstream ss;
    ss << f.rdbuf();
    auto j = parse_json(ss.str(), fs::path_to_utf8(file));
    if (!j.ok()) {
        error = j.error().to_string();
        return std::nullopt;
    }
    return j.value();
}

void print_table(const std::vector<Measurement>& ms) {
    std::printf("%-26s %10s %8s %10s %10s %10s  %s\n", "benchmark", "median ms", "spread", "min ms", "max ms", "cpu ms", "per run");
    for (const Measurement& m : ms) {
        if (m.skipped) {
            std::printf("%-26s skipped: %s\n", m.name.c_str(), m.skipReason.c_str());
            continue;
        }
        std::printf("%-26s %10.3f %7.0f%% %10.3f %10.3f %10.3f  %lld %s%s\n", m.name.c_str(), m.medianMs, m.spread * 100.0, m.minMs,
                    m.maxMs, m.cpuMedianMs, static_cast<long long>(m.items), m.unit.c_str(),
                    m.sameWork ? "" : "  (the repeats did different work!)");
    }
}

bool selected(const Bench& b, const std::vector<std::string>& filters) {
    if (filters.empty()) return true;
    for (const std::string& f : filters)
        if (b.name.find(f) != std::string::npos) return true;
    return false;
}

void github_annotations(const CompareReport& report) {
    for (const Comparison& c : report.rows) {
        if (c.verdict == Verdict::Fail) std::printf("::error title=bench fail (%s)::%s\n", c.name.c_str(), c.message.c_str());
        else if (c.verdict == Verdict::Warn || c.verdict == Verdict::Faster)
            std::printf("::warning title=bench %s (%s)::%s\n", verdict_name(c.verdict), c.name.c_str(), c.message.c_str());
    }
    if (!report.note.empty()) std::printf("::warning title=bench without baseline::%s\n", report.note.c_str());
    else if (report.count(Verdict::NoBaseline) > 0) {
        std::string names;
        for (const Comparison& c : report.rows)
            if (c.verdict == Verdict::NoBaseline) names += (names.empty() ? "" : ", ") + c.name;
        std::printf("::warning title=bench without baseline::No baseline entry for runner %s: %s. %s\n", report.runner.c_str(),
                    names.c_str(), update_hint(report.runner, report.baselineFile).c_str());
    }
}

void github_summary(const CompareReport& report, const std::vector<Measurement>& ms) {
    const char* path = std::getenv("GITHUB_STEP_SUMMARY");
    if (!path || !*path) return;
    std::string md = "### Microbenchmarks (" + report.runner + ")\n\n| benchmark | median ms | spread | baseline ms | ratio | result |\n|---|---|---|---|---|---|\n";
    char base[32] = "-", ratio[32] = "-", line[320];
    for (std::size_t i = 0; i < report.rows.size() && i < ms.size(); ++i) {
        const Comparison& c = report.rows[i];
        if (c.baselineMs > 0) {
            std::snprintf(base, sizeof base, "%.3f", c.baselineMs);
            std::snprintf(ratio, sizeof ratio, "x%.2f", c.ratio);
        } else {
            std::snprintf(base, sizeof base, "-");
            std::snprintf(ratio, sizeof ratio, "-");
        }
        std::snprintf(line, sizeof line, "| %s | %.3f | %.0f%% | %s | %s | %s |\n", c.name.c_str(), ms[i].medianMs, ms[i].spread * 100.0,
                      base, ratio, verdict_name(c.verdict));
        md += line;
    }
    std::string error;
    write_text_file(fs::path_from_utf8(path), md + "\n", error, true);
}

}  // namespace

int main(int argc, char** argv) {
    Args args;
    std::string error;
    if (!parse_args(argc, argv, args, error)) {
        std::fprintf(stderr, "fa_bench: %s\n%s", error.c_str(), kUsage);
        return 2;
    }
    if (args.help) {
        std::printf("%s", kUsage);
        return 0;
    }

    std::vector<Bench> all;
    add_ecs_benches(all);
    add_hierarchy_benches(all);
    add_physics_benches(all);
    add_render_benches(all);
    add_command_benches(all);
    add_script_benches(all);
    add_audio_benches(all);

    if (args.list) {
        for (const Bench& b : all) std::printf("%-26s %s\n", b.name.c_str(), b.summary.c_str());
        return 0;
    }

    std::vector<const Bench*> chosen;
    for (const Bench& b : all)
        if (selected(b, args.filters)) chosen.push_back(&b);
    if (chosen.empty()) {
        std::string names;
        for (const Bench& b : all) names += (names.empty() ? "" : ", ") + b.name;
        std::fprintf(stderr, "fa_bench: --filter matches no benchmark. The benchmarks are: %s\n", names.c_str());
        return 2;
    }

    auto jobsSettings = jobs::parse_settings_text(args.jobs, "--jobs");
    if (!jobsSettings.ok()) {
        std::fprintf(stderr, "fa_bench: %s\n", jobsSettings.error().to_string().c_str());
        return 2;
    }
    const std::string jobsName = jobsSettings.value().describe();

    const std::string runner = runner_id();
    const bool github = std::getenv("GITHUB_ACTIONS") != nullptr;
    std::filesystem::path baselinesDir = args.baselinesDir.empty() ? find_baselines_dir(argv[0]) : fs::path_from_utf8(args.baselinesDir);
    std::filesystem::path baselinePath =
        !args.baseline.empty() ? fs::path_from_utf8(args.baseline)
                               : (baselinesDir.empty() ? std::filesystem::path() : baselinesDir / fs::path_from_utf8(runner + ".json"));
    if ((args.compare || args.update) && baselinePath.empty()) {
        std::fprintf(stderr, "fa_bench: tools/bench/baselines was not found from here; run from the repository or give --baselines-dir DIR\n");
        return 2;
    }

    set_log_level(LogLevel::Warn);  // the engine's own info lines would drown the table
    if (auto started = jobs::start(jobsSettings.value()); !started.ok()) {
        std::fprintf(stderr, "fa_bench: cannot start the job system: %s\n", started.error().to_string().c_str());
        return 2;
    }

    Options options;
    options.repeats = args.repeats;
    options.warmup = args.warmup;
    std::vector<Measurement> results;
    for (const Bench* b : chosen) {
        std::fprintf(stderr, "running %s ...\n", b->name.c_str());
        results.push_back(run_bench(*b, options));
    }

    int status = 0;
    CompareReport report;
    bool compared = false;
    if (args.compare) {
        std::optional<Json> baseline = read_json_file(baselinePath, error);
        if (!error.empty()) {
            std::fprintf(stderr, "fa_bench: %s\n", error.c_str());
            status = 2;
        }
        std::map<std::string, Thresholds> perBench;
        for (const Bench& b : all) {
            Thresholds t;
            t.warnRatio = b.warnRatio;
            t.failRatio = b.failRatio;
            perBench[b.name] = t;
        }
        const std::string baselineName = fs::path_to_utf8(baselinePath);
        for (int attempt = 0;; ++attempt) {
            report = compare_all(runner, baselineName, baseline ? &*baseline : nullptr, jobsName, results, perBench);
            if (attempt >= args.retries || report.count(Verdict::Fail) == 0) break;
            // A shared machine is slow for seconds at a time: measure what failed again, the best run counts.
            for (std::size_t i = 0; i < results.size(); ++i) {
                if (report.rows[i].verdict != Verdict::Fail) continue;
                std::fprintf(stderr, "%s was over its limit (%.3f ms); measuring it again (%d of %d) ...\n", results[i].name.c_str(),
                             results[i].medianMs, attempt + 1, args.retries);
                for (const Bench* b : chosen) {
                    if (b->name != results[i].name) continue;
                    Measurement again = run_bench(*b, options);
                    if (!again.skipped && again.medianMs < results[i].medianMs) results[i] = again;
                }
            }
        }
        compared = true;
    }

    if (args.json) std::printf("%s", dump_json(measurements_to_json(runner, jobsName, args.repeats, results)).c_str());
    else print_table(results);
    for (const Measurement& m : results)
        if (!m.sameWork) std::printf("note: %s did different work in different repeats, so its numbers are not comparable.\n", m.name.c_str());

    if (compared) {
        if (!args.json) {
            std::printf("\n%s", report.text().c_str());
            if (github) {
                github_annotations(report);
                github_summary(report, results);
            }
        }
        // The exit status does not depend on how the measurements are printed. A bad baseline file (2) stays 2.
        if (report.failed(args.requireBaseline) && status == 0) status = 1;
    }
    if (compared && !args.report.empty()) {
        if (!write_text_file(fs::path_from_utf8(args.report), dump_json(report.to_json()), error)) {
            std::fprintf(stderr, "fa_bench: %s\n", error.c_str());
            status = 2;
        }
    }
    if (!args.out.empty()) {
        if (!write_text_file(fs::path_from_utf8(args.out), dump_json(measurements_to_json(runner, jobsName, args.repeats, results)), error)) {
            std::fprintf(stderr, "fa_bench: %s\n", error.c_str());
            status = 2;
        }
    }
    if (args.update) {
        std::string readError;
        std::optional<Json> existing = read_json_file(baselinePath, readError);
        if (!readError.empty()) {
            std::fprintf(stderr, "fa_bench: not updating, the old baseline cannot be read: %s\n", readError.c_str());
            status = 2;
        } else {
            const Json merged = merge_baseline(existing ? &*existing : nullptr, runner, jobsName, args.repeats, results);
            if (!write_text_file(baselinePath, dump_json(merged), error)) {
                std::fprintf(stderr, "fa_bench: %s\n", error.c_str());
                status = 2;
            } else {
                std::printf("\nWrote %s (runner %s).\n", fs::path_to_utf8(baselinePath).c_str(), runner.c_str());
            }
        }
    }

    release_render_env();
    jobs::stop();
    return status;
}
