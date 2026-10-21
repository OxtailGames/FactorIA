// Performance budgets: perf.measure, perf.check, perf.baseline. Behaviour and file format: docs/PERFORMANCE.md.
#include "fa/tooling/perf.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <format>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/runtime/engine.h"
#include "fa/tooling/shaders.h"
#include "util.h"

namespace fa {

namespace {

double num(const Json& j, const char* key) {
    auto it = j.find(key);
    return it != j.end() && it->is_number() ? it->get<double>() : 0.0;
}

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

}  // namespace

// ------------------------------------------------------------------------------------------------ samples and tolerances
Json perf_sample_json(const PerfSample& s) {
    return Json::object({{"frames", s.frames}, {"cpuMsAvg", round3(s.cpuMsAvg)}, {"cpuMsP95", round3(s.cpuMsP95)},
                         {"cpuMsMax", round3(s.cpuMsMax)}, {"peakMemoryMB", std::round(s.peakMemoryMB * 10.0) / 10.0},
                         {"drawCalls", s.drawCalls}, {"entities", s.entities}, {"graphics", s.graphics}});
}

PerfSample perf_sample_from_json(const Json& j) {
    PerfSample s;
    if (!j.is_object()) return s;
    s.frames = int(num(j, "frames"));
    s.cpuMsAvg = num(j, "cpuMsAvg");
    s.cpuMsP95 = num(j, "cpuMsP95");
    s.cpuMsMax = num(j, "cpuMsMax");
    s.peakMemoryMB = num(j, "peakMemoryMB");
    s.drawCalls = int(num(j, "drawCalls"));
    s.entities = int(num(j, "entities"));
    if (auto it = j.find("graphics"); it != j.end() && it->is_string()) s.graphics = it->get<std::string>();
    return s;
}

PerfTolerance perf_tolerance_from_json(const Json& j, std::vector<std::string>* problems) {
    PerfTolerance t;
    if (!j.is_object()) return t;
    const std::pair<const char*, double*> fields[] = {{"cpuAvg", &t.cpuAvg},       {"cpuP95", &t.cpuP95},
                                                      {"memory", &t.memory},       {"drawCalls", &t.drawCalls},
                                                      {"entities", &t.entities},   {"cpuSlackMs", &t.cpuSlackMs},
                                                      {"memorySlackMB", &t.memorySlackMB}, {"countSlack", &t.countSlack}};
    std::vector<std::string> names;
    for (const auto& f : fields) names.push_back(f.first);
    for (auto it = j.begin(); it != j.end(); ++it) {
        bool known = false;
        for (const auto& f : fields) {
            if (it.key() != f.first) continue;
            known = true;
            if (it->is_number() && it->get<double>() >= 0) *f.second = it->get<double>();
            else if (problems) problems->push_back("tolerance." + it.key() + " must be a number >= 0 (a ratio such as 0.1 = +10%, or a slack in ms / MB / count).");
        }
        if (!known && problems) problems->push_back("Unknown tolerance '" + it.key() + "'. " + did_you_mean(it.key(), names));
    }
    return t;
}

PerfVerdict perf_compare(const PerfSample& m, const PerfSample& b, const PerfTolerance& tol, bool strictTime) {
    PerfVerdict v;
    auto add = [&](const char* metric, double measured, double baseline, double ratio, double slack, bool timing) {
        PerfCheckRow r;
        r.metric = metric;
        r.measured = measured;
        r.baseline = baseline;
        r.limit = std::max(baseline * (1.0 + ratio), baseline + slack);
        r.timing = timing;
        r.exceeded = measured > r.limit;
        v.rows.push_back(r);
    };
    add("cpuMsAvg", m.cpuMsAvg, b.cpuMsAvg, tol.cpuAvg, tol.cpuSlackMs, true);
    add("cpuMsP95", m.cpuMsP95, b.cpuMsP95, tol.cpuP95, tol.cpuSlackMs, true);
    add("peakMemoryMB", m.peakMemoryMB, b.peakMemoryMB, tol.memory, tol.memorySlackMB, false);
    add("drawCalls", m.drawCalls, b.drawCalls, tol.drawCalls, tol.countSlack, false);
    add("entities", m.entities, b.entities, tol.entities, tol.countSlack, false);
    v.status = "pass";
    for (const PerfCheckRow& r : v.rows) {
        if (!r.exceeded) continue;
        if (!r.timing || strictTime) {
            v.status = "fail";
            break;
        }
        v.status = "warn";
    }
    return v;
}

// ------------------------------------------------------------------------------------------------ runner id
std::string perf_runner_id(const std::string& graphics) {
    if (const char* env = std::getenv("FACTORIA_PERF_RUNNER"); env && *env) return env;
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
    const std::string g = to_lower(graphics);
    std::string gpu;
    if (g.empty() || g == "none") {
        gpu = "nogpu";
    } else if (g.find("llvmpipe") != std::string::npos) {
        gpu = "llvmpipe";
    } else if (g.find("warp") != std::string::npos || g.find("basic render driver") != std::string::npos) {
        gpu = "d3d11-warp";  // the Basic Render Driver is WARP as the adapter of a machine with no graphics card (CI)
    } else if (g.find("metal") != std::string::npos) {
        gpu = "metal";
    } else if (g.rfind("d3d11", 0) == 0) {
        gpu = "d3d11";
    } else {
        for (char c : g) {
            if (std::isalnum(static_cast<unsigned char>(c))) gpu += c;
            else if (!gpu.empty()) break;
        }
        if (gpu.empty()) gpu = "gpu";
    }
    return std::string(os) + "-" + compiler + "-" + gpu;
}

static bool perf_in_ci() {
    const char* ci = std::getenv("CI");
    return ci && *ci && std::string(ci) != "0" && std::string(ci) != "false";
}

// ------------------------------------------------------------------------------------------------ commands
namespace {

constexpr const char* kFormat = "factoria.perf/1";
constexpr const char* kDefaultFile = "perf.json";
constexpr int kDefaultFrames = 300;

struct RunSpec {
    int frames = kDefaultFrames;
    std::string scene, input;
};

std::string abs_path(const std::string& projectDir, const std::string& p) {
    return fs::is_absolute(p) ? p : (std::filesystem::path(projectDir) / p).generic_string();
}

// One headless run with the GPU renderer (when there is one), drawing every frame; returns the report's perf object.
PerfSample measure_once(const std::string& projectDir, const RunSpec& spec) {
    EngineConfig cfg;
    cfg.projectDir = projectDir;
    cfg.shaderCompiler = make_engine_shader_compiler(projectDir);
    cfg.scene = spec.scene;
    cfg.headless = true;
    cfg.audioDevice = false;
    cfg.hotReload = false;
    cfg.renderMode = RenderMode::Always;
    cfg.memoryStorage = true;
    cfg.platformBackend = "fake";
    HeadlessRunOptions ho;
    ho.frames = spec.frames;
    if (!spec.input.empty()) ho.inputReplayPath = abs_path(projectDir, spec.input);
    Json report;
    const int code = run_headless(cfg, ho, &report);
    if (code != 0 || !report.contains("perf")) {
        std::string why = report.value("error", std::string());
        if (report.contains("scriptErrors") && report["scriptErrors"].is_array() && !report["scriptErrors"].empty())
            why += (why.empty() ? "" : " ") + std::string("Script error: ") + report["scriptErrors"][0].dump();
        throw CommandError("failed", "The measured run did not finish cleanly (exit code " + std::to_string(code) + "): " + why,
                           "Run 'factoria run --headless --frames " + std::to_string(spec.frames) +
                               "' to see the problem; a budget needs a game that runs.");
    }
    return perf_sample_from_json(report["perf"]);
}

double median(std::vector<double> v) {
    std::sort(v.begin(), v.end());
    return v.empty() ? 0.0 : v[v.size() / 2];
}

// `repeats` runs: time metrics are the median, draw calls and entities the max, memory the first run's (see below).
PerfSample measure(const std::string& projectDir, const RunSpec& spec, int repeats) {
    std::vector<double> avg, p95, mx;
    PerfSample out;
    for (int i = 0; i < std::max(1, repeats); ++i) {
        PerfSample s = measure_once(projectDir, spec);
        avg.push_back(s.cpuMsAvg);
        p95.push_back(s.cpuMsP95);
        mx.push_back(s.cpuMsMax);
        out.frames = s.frames;
        out.graphics = s.graphics;
        // The process peak only grows and engines of earlier repeats leave memory behind: the first run is the one a
        // single perf.check measures, so memory is the smallest of the repeats (the first).
        out.peakMemoryMB = i == 0 ? s.peakMemoryMB : std::min(out.peakMemoryMB, s.peakMemoryMB);
        out.drawCalls = std::max(out.drawCalls, s.drawCalls);
        out.entities = std::max(out.entities, s.entities);
    }
    out.cpuMsAvg = median(avg);
    out.cpuMsP95 = median(p95);
    out.cpuMsMax = median(mx);
    return out;
}

void require_project(const std::string& projectDir) {
    if (projectDir.empty() || !std::filesystem::exists(fs::os_path(std::filesystem::path(projectDir) / "factoria.json")))
        throw CommandError("not_found", "perf.* needs a project (factoria.json not found).",
                           "Run it inside a game folder or pass --project <folder>.");
}

RunSpec spec_from_args(const Json& a, const RunSpec& def) {
    RunSpec s = def;
    if (a.contains("frames")) s.frames = int(tooling_detail::arg_int(a, "frames", def.frames));
    if (s.frames < 1) throw CommandError("invalid_argument", "frames must be >= 1.", "A budget needs a run of a few hundred frames, e.g. 300.");
    if (a.contains("scene")) s.scene = tooling_detail::arg_string(a, "scene", false, def.scene);
    if (a.contains("input")) s.input = tooling_detail::arg_string(a, "input", false, def.input);
    return s;
}

Json load_budget(const std::string& file, bool mustExist) {
    if (!std::filesystem::exists(fs::os_path(file))) {
        if (mustExist)
            throw CommandError("not_found", "Budget file '" + file + "' does not exist.",
                               "Create it for this runner with: factoria call perf.baseline");
        return Json::object();
    }
    auto r = load_json_file(file);
    if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
    if (!r->is_object())
        throw CommandError("failed", "Budget file '" + file + "' must be a JSON object.", "Delete it and run: factoria call perf.baseline");
    return *r;
}

std::string fmt(double v) { return std::format("{:.4g}", v); }

}  // namespace

void register_perf_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo m;
    m.name = "perf.measure";
    m.category = "project";
    m.readOnly = true;
    m.summary = "Run the game headless for N frames and report its cost: CPU time per frame, peak memory, draw calls, entities.";
    m.description =
        "Runs the project in a second headless engine inside this process, drawing every frame with the GPU renderer when there is one (graphics \"none\" otherwise: draw calls are 0), and returns "
        "{runner, sample: {frames, cpuMsAvg, cpuMsP95, cpuMsMax (CPU time of the engine per frame: process CPU, not wall clock, so a busy machine moves it less), peakMemoryMB (peak resident memory "
        "of the process), drawCalls and entities (max over the run), graphics}}. `runner` is the id of this machine's kind (os-compiler-renderer, e.g. linux-gcc-llvmpipe) that budget files key their "
        "baselines by. `input` is an input replay (like `factoria run --input`) to reach the heavy part of the game. Peak memory is the whole process's, so measure with the same host every time "
        "(`factoria call --no-graphics perf.measure`). Example: {\"frames\":300}.";
    m.inputSchema = Json::parse(R"({"type":"object","properties":{
        "frames":{"type":"integer","default":300,"minimum":1,"description":"How many frames to run (fixed step)."},
        "scene":{"type":"string","description":"Start scene (default: the project's mainScene)."},
        "input":{"type":"string","description":"Project-relative input replay JSON applied during the run."},
        "repeats":{"type":"integer","default":1,"minimum":1,"description":"Run this many times; time metrics are the median, memory/draw calls/entities the max."}}})");
    registry.add(m, [projectDir](const Json& a) {
        require_project(projectDir);
        const RunSpec spec = spec_from_args(a, RunSpec{});
        const PerfSample s = measure(projectDir, spec, int(tooling_detail::arg_int(a, "repeats", 1)));
        return Json::object({{"runner", perf_runner_id(s.graphics)}, {"sample", perf_sample_json(s)}});
    });

    CommandInfo b;
    b.name = "perf.baseline";
    b.category = "project";
    b.readOnly = false;
    b.summary = "Measure the game and write or refresh THIS runner's entry in its performance budget file (perf.json).";
    b.description =
        "Measures like perf.measure (3 runs, median) and stores the result under runners.<runner> of the budget file, keeping the other runners' entries, the run settings and any \"tolerance\" "
        "already there. Run it once per kind of machine you want checked (the runner id is os-compiler-renderer, e.g. windows-msvc-d3d11-warp, linux-gcc-llvmpipe, macos-clang-metal), and again "
        "when the game got heavier ON PURPOSE. A game sets its own budget the same way: `factoria call perf.baseline` writes <project>/perf.json, commit it, and `factoria call perf.check` (in "
        "CI it fails past the tolerance) checks it. File: {format:\"factoria.perf/1\", frames, scene?, input?, tolerance?: {cpuAvg:1.0 (ratio over the baseline), cpuP95:1.5, memory:0.1, "
        "drawCalls:0.1, entities:0.1, cpuSlackMs:1, memorySlackMB:8, countSlack:2}, runners: {<id>: sample}}. A limit is max(baseline*(1+ratio), baseline+slack). `tolerance` here sets the "
        "file's tolerances. Returns {file, runner, sample, created}. Example: {\"frames\":300,\"input\":\"replays/play.json\"}.";
    b.inputSchema = Json::parse(R"({"type":"object","properties":{
        "file":{"type":"string","default":"perf.json","description":"Budget file, project-relative (or absolute)."},
        "frames":{"type":"integer","description":"Frames per run; stored in the file (default: the file's value, else 300)."},
        "scene":{"type":"string","description":"Start scene; stored in the file."},
        "input":{"type":"string","description":"Project-relative input replay; stored in the file."},
        "repeats":{"type":"integer","default":3,"minimum":1,"description":"Runs to take the median of."},
        "tolerance":{"type":"object","description":"Tolerances to store in the file: cpuAvg, cpuP95, memory, drawCalls, entities (ratios), cpuSlackMs, memorySlackMB, countSlack."}}})");
    registry.add(b, [projectDir](const Json& a) {
        require_project(projectDir);
        const std::string file = abs_path(projectDir, tooling_detail::arg_string(a, "file", false, kDefaultFile));
        Json budget = load_budget(file, false);
        const bool created = budget.empty();
        RunSpec def;
        def.frames = budget.contains("frames") && budget["frames"].is_number_integer() ? budget["frames"].get<int>() : kDefaultFrames;
        def.scene = budget.value("scene", std::string());
        def.input = budget.value("input", std::string());
        const RunSpec spec = spec_from_args(a, def);
        if (a.contains("tolerance")) {
            std::vector<std::string> problems;
            perf_tolerance_from_json(a["tolerance"], &problems);
            if (!problems.empty())
                throw CommandError("invalid_argument", problems[0],
                                   "Tolerance keys: cpuAvg, cpuP95, memory, drawCalls, entities, cpuSlackMs, memorySlackMB, countSlack.");
            budget["tolerance"] = a["tolerance"];
        }
        const PerfSample s = measure(projectDir, spec, int(tooling_detail::arg_int(a, "repeats", 3)));
        const std::string runner = perf_runner_id(s.graphics);
        budget["format"] = kFormat;
        budget["frames"] = spec.frames;
        if (!spec.scene.empty()) budget["scene"] = spec.scene;
        if (!spec.input.empty()) budget["input"] = spec.input;
        if (!budget.contains("runners") || !budget["runners"].is_object()) budget["runners"] = Json::object();
        budget["runners"][runner] = perf_sample_json(s);
        if (auto w = fs::write_text(file, dump_json(budget) + "\n"); !w.ok()) throw CommandError("failed", w.error().message, w.error().hint);
        return Json::object({{"file", file}, {"runner", runner}, {"sample", perf_sample_json(s)}, {"created", created}});
    });

    CommandInfo c;
    c.name = "perf.check";
    c.category = "project";
    c.readOnly = true;
    c.summary = "Measure the game and fail when it costs more than its performance budget (perf.json) allows on this runner.";
    c.description =
        "Measures with the settings of the budget file (frames, scene, input) and compares with runners.<this runner> of the file (see perf.baseline for the format and the tolerances). Memory, "
        "draw calls and entities past their limit FAIL always. A time (cpuMsAvg, cpuMsP95) past its limit FAILS when the CI environment variable is set; elsewhere it only WARNS (status \"warn\"), "
        "because a developer machine can be busy. A time over the limit is measured a second time before it counts. A runner with no entry passes with status \"no_baseline\" and returns "
        "`baselineEntry`: the exact JSON to add under \"runners\" (or run perf.baseline here); with requireBaseline it fails instead (error `perf_no_baseline`, same data). Returns {runner, status: pass|warn|no_baseline, file, sample, rows: [{metric, measured, baseline, limit, "
        "exceeded}], message, baselineEntry?}; a failure is an error `perf_budget_exceeded` with the same data. Example: {} or {\"file\":\"perf.json\"}.";
    c.inputSchema = Json::parse(R"({"type":"object","properties":{
        "file":{"type":"string","default":"perf.json","description":"Budget file, project-relative (or absolute)."},
        "strictTime":{"type":"boolean","description":"Make a time over its limit fail even outside CI (default: only in CI)."},
        "requireBaseline":{"type":"boolean","default":false,"description":"Fail when this runner has no entry in the file, so a CI job cannot pass without checking anything."}}})");
    registry.add(c, [projectDir](const Json& a) {
        require_project(projectDir);
        const std::string file = abs_path(projectDir, tooling_detail::arg_string(a, "file", false, kDefaultFile));
        const Json budget = load_budget(file, true);
        RunSpec spec;
        if (budget.contains("frames") && budget["frames"].is_number_integer()) spec.frames = budget["frames"].get<int>();
        spec.scene = budget.value("scene", std::string());
        spec.input = budget.value("input", std::string());
        std::vector<std::string> problems;
        const PerfTolerance tol = perf_tolerance_from_json(budget.value("tolerance", Json::object()), &problems);
        if (!problems.empty()) throw CommandError("failed", file + ": " + problems[0], "Fix the \"tolerance\" object of the budget file.");
        const bool strictTime = tooling_detail::arg_bool(a, "strictTime", perf_in_ci());
        PerfSample s = measure(projectDir, spec, 1);
        const std::string runner = perf_runner_id(s.graphics);
        Json result = Json::object({{"runner", runner}, {"file", file}});
        const Json* entry = nullptr;
        if (auto it = budget.find("runners"); it != budget.end() && it->is_object())
            if (auto r = it->find(runner); r != it->end() && r->is_object()) entry = &*r;
        if (!entry) {
            result["status"] = "no_baseline";
            result["sample"] = perf_sample_json(s);
            result["baselineEntry"] = Json::object({{runner, perf_sample_json(s)}});
            result["message"] = "No baseline for runner '" + runner + "' in " + file + ": nothing was checked. Commit this entry under \"runners\": " +
                                dump_json(result["baselineEntry"]) + " (or run: factoria call perf.baseline).";
            if (tooling_detail::arg_bool(a, "requireBaseline", false))
                throw CommandError("perf_no_baseline", result["message"].get<std::string>(),
                                   "Add baselineEntry under \"runners\" of " + file + ", or run factoria call perf.baseline on this runner.", result);
            return result;
        }
        const PerfSample base = perf_sample_from_json(*entry);
        PerfVerdict v = perf_compare(s, base, tol, strictTime);
        if (v.status != "pass") {  // a time over the limit may be a busy machine: measure again, keep the better of the two
            bool timeOnly = true;
            for (const PerfCheckRow& r : v.rows) timeOnly = timeOnly && (!r.exceeded || r.timing);
            if (timeOnly) {
                const PerfSample again = measure(projectDir, spec, 1);
                s.cpuMsAvg = std::min(s.cpuMsAvg, again.cpuMsAvg);
                s.cpuMsP95 = std::min(s.cpuMsP95, again.cpuMsP95);
                s.cpuMsMax = std::min(s.cpuMsMax, again.cpuMsMax);
                v = perf_compare(s, base, tol, strictTime);
            }
        }
        Json rows = Json::array();
        std::string over;
        for (const PerfCheckRow& r : v.rows) {
            rows.push_back(Json::object({{"metric", r.metric}, {"measured", round3(r.measured)}, {"baseline", round3(r.baseline)},
                                         {"limit", round3(r.limit)}, {"exceeded", r.exceeded}}));
            if (r.exceeded) over += std::format(" {} {} > limit {} (baseline {});", r.metric, fmt(r.measured), fmt(r.limit), fmt(r.baseline));
        }
        result["status"] = v.status;
        result["sample"] = perf_sample_json(s);
        result["rows"] = rows;
        if (v.status == "pass") {
            result["message"] = "Within the budget of runner '" + runner + "'.";
            return result;
        }
        const std::string how = "If the cost is intended, refresh the baseline on this runner: factoria call perf.baseline (file: " + file +
                                "). Otherwise find what got heavier (play.report spikes, game.state).";
        if (v.status == "warn") {
            result["message"] = "Over the time budget of runner '" + runner + "' (only a warning outside CI):" + over + " " + how;
            return result;
        }
        throw CommandError("perf_budget_exceeded", "Over the performance budget of runner '" + runner + "' (" + file + "):" + over, how, result);
    });
}

}  // namespace fa
