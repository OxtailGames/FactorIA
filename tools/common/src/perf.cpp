// Performance budgets: perf.measure, perf.check, perf.baseline. Behaviour and file format: docs/PERFORMANCE.md.
#include "fa/tooling/perf.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <format>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/platform/app.h"
#include "fa/runtime/engine.h"
#include "fa/tooling/shaders.h"
#include "headless_run.h"
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
Json perf_sample_json(const PerfSample& s, bool withSlowest) {
    Json j = Json::object({{"frames", s.frames}, {"cpuMsAvg", round3(s.cpuMsAvg)}, {"cpuMsP95", round3(s.cpuMsP95)},
                         {"cpuMsMax", round3(s.cpuMsMax)}, {"peakMemoryMB", std::round(s.peakMemoryMB * 10.0) / 10.0},
                         {"drawCalls", s.drawCalls}, {"entities", s.entities}, {"graphics", s.graphics}});
    // Written only when recorded, so a sample read from an old baseline file is written back without invented fields.
    if (s.cpuMsMedian >= 0) j["cpuMsMedian"] = round3(s.cpuMsMedian);
    if (s.provisional) j["provisional"] = true;
    if (withSlowest && !s.slowestFrames.empty()) {
        Json slow = Json::array();
        for (const PerfFrame& f : s.slowestFrames) slow.push_back(Json::object({{"frame", f.frame}, {"ms", round3(f.ms)}}));
        j["slowestFrames"] = slow;
    }
    if (s.triangles >= 0) j["triangles"] = std::llround(s.triangles);
    if (s.lights >= 0) j["lights"] = std::llround(s.lights);
    if (s.textureMB >= 0) j["textureMB"] = round3(s.textureMB);
    if (s.startupMs >= 0) j["startupMs"] = std::round(s.startupMs * 10.0) / 10.0;
    if (withSlowest) {  // a measurement only: a baseline entry keeps the fields it gates
        if (s.audioDecodedMB >= 0) j["audioDecodedMB"] = std::round(s.audioDecodedMB * 100.0) / 100.0;
        if (s.musicMB >= 0) j["musicMB"] = std::round(s.musicMB * 100.0) / 100.0;
    }
    return j;
}

PerfSample perf_sample_from_json(const Json& j) {
    PerfSample s;
    if (!j.is_object()) return s;
    s.frames = int(num(j, "frames"));
    s.cpuMsAvg = num(j, "cpuMsAvg");
    s.cpuMsP95 = num(j, "cpuMsP95");
    s.cpuMsMax = num(j, "cpuMsMax");
    if (auto it = j.find("cpuMsMedian"); it != j.end() && it->is_number()) s.cpuMsMedian = it->get<double>();
    if (auto it = j.find("provisional"); it != j.end() && it->is_boolean()) s.provisional = it->get<bool>();
    if (auto it = j.find("slowestFrames"); it != j.end() && it->is_array())
        for (const Json& f : *it)
            if (f.is_object() && s.slowestFrames.size() < std::size_t(kPerfSlowestFrames))
                s.slowestFrames.push_back({int(std::clamp(num(f, "frame"), 0.0, 2e9)), num(f, "ms")});
    s.peakMemoryMB = num(j, "peakMemoryMB");
    s.drawCalls = int(num(j, "drawCalls"));
    s.entities = int(num(j, "entities"));
    for (const auto& f : {std::pair<const char*, double*>{"triangles", &s.triangles}, {"lights", &s.lights},
                          {"textureMB", &s.textureMB}, {"startupMs", &s.startupMs},
                          {"audioDecodedMB", &s.audioDecodedMB}, {"musicMB", &s.musicMB}})
        if (auto it = j.find(f.first); it != j.end() && it->is_number()) *f.second = it->get<double>();
    if (auto it = j.find("graphics"); it != j.end() && it->is_string()) s.graphics = it->get<std::string>();
    return s;
}

PerfTolerance perf_tolerance_from_json(const Json& j, std::vector<std::string>* problems) {
    PerfTolerance t;
    if (!j.is_object()) return t;
    const std::pair<const char*, double*> fields[] = {{"cpuMedian", &t.cpuMedian}, {"cpuP95", &t.cpuP95},
                                                      {"cpuFail", &t.cpuFail},     {"cpuFailSlackMs", &t.cpuFailSlackMs},
                                                      {"memoryFail", &t.memoryFail}, {"memoryFailSlackMB", &t.memoryFailSlackMB},
                                                      {"memory", &t.memory},       {"drawCalls", &t.drawCalls},
                                                      {"entities", &t.entities},   {"cpuSlackMs", &t.cpuSlackMs},
                                                      {"memorySlackMB", &t.memorySlackMB}, {"countSlack", &t.countSlack},
                                                      {"triangles", &t.triangles}, {"lights", &t.lights},
                                                      {"textureMB", &t.textureMB}, {"textureSlackMB", &t.textureSlackMB},
                                                      {"startup", &t.startup},     {"startupSlackMs", &t.startupSlackMs}};
    std::vector<std::string> names;
    for (const auto& f : fields) names.push_back(f.first);
    for (auto it = j.begin(); it != j.end(); ++it) {
        bool known = false;
        // "cpuAvg" is the old name of "cpuMedian" (the average is no longer gated): it applies unless "cpuMedian" is there too.
        const bool oldAvg = it.key() == "cpuAvg";
        for (const auto& f : fields) {
            if (it.key() != f.first && !(oldAvg && std::string(f.first) == "cpuMedian")) continue;
            known = true;
            if (oldAvg && j.contains("cpuMedian")) break;
            if (it->is_number() && it->get<double>() >= 0) *f.second = it->get<double>();
            else if (problems) problems->push_back("tolerance." + it.key() + " must be a number >= 0 (a ratio such as 0.1 = +10%, or a slack in ms / MB / count).");
        }
        if (!known && problems) problems->push_back("Unknown tolerance '" + it.key() + "'. " + did_you_mean(it.key(), names));
    }
    return t;
}

PerfVerdict perf_compare(const PerfSample& m, const PerfSample& b, const PerfTolerance& tol, bool strictTime) {
    PerfVerdict v;
    // A row with one limit (counters, start-up) passes the same ratio and slack twice.
    auto add = [&](const char* metric, double measured, double baseline, double ratio, double slack, bool timing,
                   double failRatio = -1, double failSlack = -1) {
        PerfCheckRow r;
        r.metric = metric;
        r.measured = measured;
        r.baseline = baseline;
        r.warnLimit = std::max(baseline * (1.0 + ratio), baseline + slack);
        r.limit = failRatio < 0 ? r.warnLimit : std::max(r.warnLimit, std::max(baseline * (1.0 + failRatio), baseline + failSlack));
        r.timing = timing;
        r.exceeded = measured > r.limit;
        r.warned = !r.exceeded && measured > r.warnLimit;
        v.rows.push_back(r);
    };
    // Counters: the same on every run of a fixed scene, so the baseline itself is the limit (tolerance 0). Always compared.
    add("drawCalls", m.drawCalls, b.drawCalls, tol.drawCalls, tol.countSlack, false);
    add("entities", m.entities, b.entities, tol.entities, tol.countSlack, false);
    // Render numbers: only when the baseline recorded them (a baseline from before has no budget for them).
    if (b.triangles >= 0) add("triangles", m.triangles, b.triangles, tol.triangles, tol.countSlack, false);
    if (b.lights >= 0) add("lights", m.lights, b.lights, tol.lights, tol.countSlack, false);
    // A provisional entry is an estimate: only the counters above are enforced.
    if (!b.provisional) {
        if (b.textureMB >= 0) add("textureMB", m.textureMB, b.textureMB, tol.textureMB, tol.textureSlackMB, false);
        // Time: the median and the p95 (never the average or the maximum, which one slow frame decides), warning from the
        // ratio and failing only past the wide band. A baseline from before the median stands the average in for it.
        const double bMedian = b.cpuMsMedian >= 0 ? b.cpuMsMedian : b.cpuMsAvg;
        const double mMedian = m.cpuMsMedian >= 0 ? m.cpuMsMedian : m.cpuMsAvg;
        add("cpuMsMedian", mMedian, bMedian, tol.cpuMedian, tol.cpuSlackMs, true, tol.cpuFail, tol.cpuFailSlackMs);
        add("cpuMsP95", m.cpuMsP95, b.cpuMsP95, tol.cpuP95, tol.cpuSlackMs, true, tol.cpuFail, tol.cpuFailSlackMs);
        add("peakMemoryMB", m.peakMemoryMB, b.peakMemoryMB, tol.memory, tol.memorySlackMB, false, tol.memoryFail, tol.memoryFailSlackMB);
        // Start-up is a time: it warns outside CI and fails in CI (after re-measures), like the CPU times. Only with a baseline that has it.
        if (b.startupMs >= 0 && m.startupMs >= 0) add("startupMs", m.startupMs, b.startupMs, tol.startup, tol.startupSlackMs, true);
    }
    v.status = "pass";
    for (const PerfCheckRow& r : v.rows) {
        if (r.exceeded && (!r.timing || strictTime)) {
            v.status = "fail";
            break;
        }
        if (r.exceeded || r.warned) v.status = "warn";
    }
    return v;
}

PerfBudgets perf_budgets_from_json(const Json& j, std::vector<std::string>* problems) {
    PerfBudgets b;
    if (!j.is_object()) return b;
    const std::pair<const char*, double*> fields[] = {{"maxTriangles", &b.maxTriangles}, {"maxLights", &b.maxLights},
                                                      {"maxTextureMB", &b.maxTextureMB}, {"maxDrawCalls", &b.maxDrawCalls},
                                                      {"maxEntities", &b.maxEntities}, {"maxStartupMs", &b.maxStartupMs}};
    std::vector<std::string> names;
    for (const auto& f : fields) names.push_back(f.first);
    for (auto it = j.begin(); it != j.end(); ++it) {
        bool known = false;
        for (const auto& f : fields) {
            if (it.key() != f.first) continue;
            known = true;
            if (it->is_number() && it->get<double>() >= 0) *f.second = it->get<double>();
            else if (problems) problems->push_back("budgets." + it.key() + " must be a number >= 0 (the most the game may reach).");
        }
        if (!known && problems) problems->push_back("Unknown budget '" + it.key() + "'. " + did_you_mean(it.key(), names));
    }
    return b;
}

std::vector<PerfCheckRow> perf_budget_rows(const PerfSample& m, const PerfBudgets& b) {
    std::vector<PerfCheckRow> rows;
    auto add = [&](const char* metric, double measured, double cap, bool timing = false) {
        if (cap < 0) return;
        PerfCheckRow r;
        r.metric = metric;
        r.measured = measured;
        r.baseline = r.limit = r.warnLimit = cap;
        r.timing = timing;
        r.exceeded = measured > cap;
        rows.push_back(r);
    };
    add("maxTriangles", m.triangles, b.maxTriangles);
    add("maxLights", m.lights, b.maxLights);
    add("maxTextureMB", m.textureMB, b.maxTextureMB);
    add("maxDrawCalls", m.drawCalls, b.maxDrawCalls);
    add("maxEntities", m.entities, b.maxEntities);
    if (m.startupMs >= 0) add("maxStartupMs", m.startupMs, b.maxStartupMs, true);
    return rows;
}

std::string perf_startup_advice() {
    return "Start-up is the time from reading the game to its first frame: it grows with the files of the first scene (textures and models "
           "are decoded, audio is decoded, scripts are compiled). Keep the first scene small and load the rest later (scene.load / "
           "scene.preload, a loading screen), keep textures and audio of the first scene to what it shows, and do not do heavy work in "
           "onStart. Measure it with: factoria call perf.measure (startupMs); see docs/PERFORMANCE.md, \"Startup\".";
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
        // GitHub's macOS runners are virtual machines: their Metal device is the Apple Paravirtual device, which costs about
        // 6 MB (20%) less peak memory than a Mac's own GPU on the same build. Like WARP, it is a kind of its own.
        gpu = g.find("paravirtual") != std::string::npos ? "metal-paravirtual" : "metal";
    } else if (g.rfind("d3d11", 0) == 0) {
        gpu = "d3d11";
    } else {
        for (char c : g) {
            if (std::isalnum(static_cast<unsigned char>(c))) gpu += c;
            else if (!gpu.empty()) break;
        }
        if (gpu.empty()) gpu = "gpu";
    }
#if defined(NDEBUG)
    const char* build = "";
#else
    // A Debug build maps more and bigger code and runs slower: about 9 MB more peak memory than the release build on the
    // same Mac, past the tolerance, so its numbers never meet a release build's baseline (CI builds release).
    const char* build = "-debug";
#endif
    return std::string(os) + "-" + compiler + "-" + gpu + build;
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

std::string abs_path(const std::string& projectDir, const std::string& p) { return tooling_detail::project_path(projectDir, p); }

// One headless run with the GPU renderer (when there is one), drawing every frame; returns the run's report (`needKey` must be in it).
Json run_report(const std::string& projectDir, const RunSpec& spec, HeadlessRunOptions ho, const char* needKey) {
    // The run starts its own engine with its own GPU, and a process has one graphics device: asking sokol for a second one aborts.
    if (gfx_device_active())
        throw CommandError("gpu_busy", "This process already uses the graphics card (the editor, a window or an engine with graphics), and a measured run needs a second engine with its own.",
                           "Run it from a terminal: factoria call --no-graphics perf.measure (perf.profile, perf.check...; plain 'factoria call perf.*' does that by itself). In the editor use View > Profiler or play.report's profile instead.");
    EngineConfig cfg = tooling_detail::headless_engine_config(projectDir, spec.scene, true, RenderMode::Always);
    if (!spec.input.empty()) ho.inputReplayPath = abs_path(projectDir, spec.input);
    Json report;
    const int code = run_headless(cfg, ho, &report);
    if (code != 0 || !report.contains(needKey)) {
        std::string why = report.value("error", std::string());
        if (report.contains("scriptErrors") && report["scriptErrors"].is_array() && !report["scriptErrors"].empty())
            why += (why.empty() ? "" : " ") + std::string("Script error: ") + report["scriptErrors"][0].dump();
        throw CommandError("failed", "The measured run did not finish cleanly (exit code " + std::to_string(code) + "): " + why,
                           "Run 'factoria run --headless --frames " + std::to_string(ho.frames) +
                               "' to see the problem; a budget needs a game that runs.");
    }
    return report;
}

PerfSample measure_once(const std::string& projectDir, const RunSpec& spec) {
    HeadlessRunOptions ho;
    ho.frames = spec.frames;
    return perf_sample_from_json(run_report(projectDir, spec, ho, "perf")["perf"]);
}

double median(std::vector<double> v) {
    std::sort(v.begin(), v.end());
    return v.empty() ? 0.0 : v[v.size() / 2];
}

// `repeats` runs: time metrics are the median, draw calls and entities the max, memory the first run's (see below).
PerfSample measure(const std::string& projectDir, const RunSpec& spec, int repeats) {
    std::vector<double> avg, med, p95, mx, startup;
    PerfSample out;
    double worstMax = 0;
    for (int i = 0; i < std::max(1, repeats); ++i) {
        PerfSample s = measure_once(projectDir, spec);
        avg.push_back(s.cpuMsAvg);
        med.push_back(s.cpuMsMedian >= 0 ? s.cpuMsMedian : s.cpuMsAvg);
        // The frames named are those of the run that had the worst spike: the report shows it, whichever run the median picks.
        if (i == 0 || s.cpuMsMax > worstMax) {
            worstMax = s.cpuMsMax;
            out.slowestFrames = s.slowestFrames;
        }
        p95.push_back(s.cpuMsP95);
        mx.push_back(s.cpuMsMax);
        if (s.startupMs >= 0) startup.push_back(s.startupMs);
        out.frames = s.frames;
        out.graphics = s.graphics;
        // The process peak only grows and engines of earlier repeats leave memory behind: the first run is the one a
        // single perf.check measures, so memory is the smallest of the repeats (the first).
        out.peakMemoryMB = i == 0 ? s.peakMemoryMB : std::min(out.peakMemoryMB, s.peakMemoryMB);
        out.drawCalls = std::max(out.drawCalls, s.drawCalls);
        out.entities = std::max(out.entities, s.entities);
        out.triangles = std::max(out.triangles, s.triangles);
        out.lights = std::max(out.lights, s.lights);
        out.textureMB = std::max(out.textureMB, s.textureMB);
        out.audioDecodedMB = std::max(out.audioDecodedMB, s.audioDecodedMB);
        out.musicMB = std::max(out.musicMB, s.musicMB);
    }
    out.cpuMsAvg = median(avg);
    out.cpuMsMedian = median(med);
    out.cpuMsP95 = median(p95);
    out.cpuMsMax = median(mx);
    if (!startup.empty()) out.startupMs = median(startup);
    return out;
}

void require_project(const std::string& projectDir) { tooling_detail::require_project_dir(projectDir, "perf.*"); }

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
    m.summary = "Run the game headless for N frames and report its cost: CPU time per frame, peak memory, draw calls, entities, triangles, lights, texture memory.";
    m.description =
        "Runs the project in a second headless engine inside this process, drawing every frame with the GPU renderer when there is one (graphics \"none\" otherwise: draw calls are 0), and returns "
        "{runner, sample: {frames, cpuMsAvg, cpuMsMedian, cpuMsP95, cpuMsMax (process CPU per frame; perf.check gates the median and the p95, the rest is reported), slowestFrames ([{frame, ms}], the five slowest frames of the run, slowest first: a spike is named here), peakMemoryMB (peak resident memory "
        "of the process), drawCalls, entities, triangles (of the main pass), lights (3D lights of the main pass plus Light2D lights of the same frame), textureMB (GPU texture memory), audioDecodedMB and musicMB (decoded audio, the music alone; not gated; read every 8th frame), all max over the run, startupMs (CPU milliseconds from reading the game's files to its first frame: scenes, scripts, textures, shaders), graphics}}. `runner` is the id of this machine's and build's kind (os-compiler-renderer, plus -debug for a Debug build, e.g. linux-gcc-llvmpipe) that budget files key their "
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

    CommandInfo pr;
    pr.name = "perf.profile";
    pr.category = "project";
    pr.readOnly = true;
    pr.summary = "Run the game headless with the profiler on and report where the time goes: per engine system, per script behaviour class, GPU time, memory.";
    pr.description =
        "Use it when the game is slow and you need to know WHY (perf.measure only says how slow). Runs the "
        "project like perf.measure (drawing every frame with the GPU renderer when there is one) with the "
        "profiler on and returns {runner, graphics, profile}. profile = {frames, clock:\"wall\", "
        "frameMs:{avg,p95,max} (engine time of a frame), systems: {platform, physics, scriptsFixedUpdate, "
        "animation, scriptsEvents, ui, scriptsUpdate, audio, scriptsLateUpdate, localization, render, "
        "endOfFrame: {avgMs, p95Ms, maxMs}}, behaviours: [{class, path, avgMs (per frame, counting the "
        "frames it did not run), maxMs, callsPerFrame}] slowest first (every per-behaviour callback counts: "
        "onStart, onUpdate, onFixedUpdate, onLateUpdate, collision/trigger handlers, onEvent; timers, "
        "world.on handlers and promise jobs are the bucket \"(timers, events and promises)\"), gpu: {avgMs, "
        "p95Ms, maxMs, samples, reason} (milliseconds the GPU took to draw the world; null with a `reason` "
        "where the graphics backend has no timer queries: Metal, GLES3, WebGL2, or no GPU), memory: {start, "
        "end, peak: {processMB, jsHeapMB, textureMB, audioDecodedMB, musicMB, entities}}}. Example: "
        "{\"frames\":300,\"input\":\"replays/play.json\"}."
        FA_COMMAND_DETAILS
        "Times are wall-clock milliseconds and vary a little from run to run: compare the ORDER and the big "
        "gaps, not the decimals. A system's time includes the behaviours it runs (scriptsUpdate holds every "
        "onUpdate). `warmup` frames (default 30) run first and are not counted, because the first frames "
        "load assets. Use `input` (an input replay) to reach the heavy part of the game. The profiler only "
        "measures: game.state, replays and saves are identical with it on. The editor's play sessions record "
        "the same section in play.report, and View > Profiler shows it live.";
    pr.inputSchema = Json::parse(R"({"type":"object","properties":{
        "frames":{"type":"integer","default":300,"minimum":1,"description":"How many frames to profile (fixed step), after the warm-up."},
        "warmup":{"type":"integer","default":30,"minimum":0,"description":"Frames to run first and leave out of the numbers (assets load, caches fill)."},
        "scene":{"type":"string","description":"Start scene (default: the project's mainScene)."},
        "input":{"type":"string","description":"Project-relative input replay JSON applied during the run."}}})");
    registry.add(pr, [projectDir](const Json& a) {
        require_project(projectDir);
        const RunSpec spec = spec_from_args(a, RunSpec{});
        const int warmup = int(tooling_detail::arg_int(a, "warmup", 30));
        if (warmup < 0) throw CommandError("invalid_argument", "warmup must be >= 0.", "Use 0 to count every frame, or about 30.");
        HeadlessRunOptions ho;
        ho.frames = spec.frames + warmup;
        ho.profile = true;
        ho.profileWarmup = warmup;
        const Json report = run_report(projectDir, spec, ho, "profile");
        const std::string graphics = report["perf"].value("graphics", std::string("none"));
        return Json::object({{"runner", perf_runner_id(graphics)}, {"graphics", graphics}, {"profile", report["profile"]}});
    });

    CommandInfo b;
    b.name = "perf.baseline";
    b.category = "project";
    b.readOnly = false;
    b.summary = "Measure the game and write or refresh THIS runner's entry in its performance budget file (perf.json).";
    b.description =
        "Measures like perf.measure (3 runs, median) and stores the result under runners.<runner> of the "
        "budget file, keeping the other runners' entries, the run settings and any \"tolerance\" already "
        "there. Run it once per kind of machine you want checked (the runner id is os-compiler-renderer, "
        "e.g. windows-msvc-d3d11-warp, linux-gcc-llvmpipe, macos-clang-metal-paravirtual; a Debug build adds "
        "-debug), and again when the game got heavier ON PURPOSE. A game sets its own budget the same way: "
        "`factoria call perf.baseline` writes <project>/perf.json, commit it, and `factoria call perf.check` "
        "(in CI it fails past the tolerance) checks it. Example: "
        "{\"frames\":300,\"input\":\"replays/play.json\"}."
        FA_COMMAND_DETAILS
        "File: {format:\"factoria.perf/1\", frames, scene?, input?, tolerance?: {cpuMedian:1.0 (warn ratio "
        "over the baseline; cpuAvg is its old name), cpuP95:1.5, cpuFail:5.0 (fail ratio of both), "
        "cpuFailSlackMs:10, memory:0.1, memoryFail:0.5, memoryFailSlackMB:32, drawCalls:0, entities:0, "
        "triangles:0, lights:0 (counters: exact), textureMB:0.1, startup:2.0, cpuSlackMs:1, memorySlackMB:8, "
        "textureSlackMB:1, startupSlackMs:500, countSlack:0}, budgets?: {maxTriangles, maxLights, "
        "maxTextureMB, maxDrawCalls, maxEntities, maxStartupMs} (absolute caps, see perf.check; maxStartupMs "
        "is the `perf.startup` budget), runners: {<id>: sample}}. A sample may hold \"provisional\": true "
        "(an estimate: only the counters are enforced; the entry perf.baseline writes never has it). A warn "
        "limit is max(baseline*(1+ratio), baseline+slack), a fail limit max(baseline*(1+failRatio), "
        "baseline+failSlack). `tolerance` here sets the file's tolerances. Returns {file, runner, sample, "
        "created}.";
    b.inputSchema = Json::parse(R"({"type":"object","properties":{
        "file":{"type":"string","default":"perf.json","description":"Budget file, project-relative (or absolute)."},
        "frames":{"type":"integer","description":"Frames per run; stored in the file (default: the file's value, else 300)."},
        "scene":{"type":"string","description":"Start scene; stored in the file."},
        "input":{"type":"string","description":"Project-relative input replay; stored in the file."},
        "repeats":{"type":"integer","default":3,"minimum":1,"description":"Runs to take the median of."},
        "tolerance":{"type":"object","description":"Tolerances to store in the file: cpuMedian, cpuP95, cpuFail, memory, memoryFail, drawCalls, entities, triangles, lights, textureMB, startup (ratios), cpuSlackMs, cpuFailSlackMs, memorySlackMB, memoryFailSlackMB, textureSlackMB, startupSlackMs, countSlack."}}})");
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
                                   "Tolerance keys: cpuMedian, cpuP95, cpuFail, cpuFailSlackMs, memory, memoryFail, memoryFailSlackMB, drawCalls, entities, triangles, lights, textureMB, startup, cpuSlackMs, memorySlackMB, textureSlackMB, startupSlackMs, countSlack.");
            budget["tolerance"] = a["tolerance"];
        }
        const PerfSample s = measure(projectDir, spec, int(tooling_detail::arg_int(a, "repeats", 3)));
        const std::string runner = perf_runner_id(s.graphics);
        budget["format"] = kFormat;
        budget["frames"] = spec.frames;
        if (!spec.scene.empty()) budget["scene"] = spec.scene;
        if (!spec.input.empty()) budget["input"] = spec.input;
        if (!budget.contains("runners") || !budget["runners"].is_object()) budget["runners"] = Json::object();
        budget["runners"][runner] = perf_sample_json(s, false);  // no provisional flag: this is a measurement
        if (auto w = fs::write_text(file, dump_json(budget) + "\n"); !w.ok()) throw CommandError("failed", w.error().message, w.error().hint);
        return Json::object({{"file", file}, {"runner", runner}, {"sample", perf_sample_json(s, false)}, {"created", created}});
    });

    CommandInfo c;
    c.name = "perf.check";
    c.category = "project";
    c.readOnly = true;
    c.summary = "Measure the game and fail when it costs more than its performance budget (perf.json) allows on this runner.";
    c.description =
        "Measures with the settings of the budget file (frames, scene, input) and compares with "
        "runners.<this runner> of the file (see perf.baseline for the format and the tolerances). The "
        "counters (draw calls, entities; triangles and lights when the baseline has them) are exact: one "
        "more than the baseline FAILS always (fewer passes). The median and p95 frame time and the peak "
        "memory have a wide band: past a warn limit the status is \"warn\" and the message says so, and only "
        "past the fail limit (about 6x for a time, +50% for memory, each with an absolute floor) does it "
        "FAIL, so a baseline is never refreshed to pass (docs/PERFORMANCE.md, \"The band\"). The average and "
        "the maximum are not gated; the message names the slowest frames. An entry with \"provisional\": "
        "true enforces only the counters. Texture memory fails past +10% and 1 MB. Example: {} or "
        "{\"file\":\"perf.json\"}."
        FA_COMMAND_DETAILS
        "The file's \"budgets\" object ({maxTriangles, maxLights, maxTextureMB, maxDrawCalls, maxEntities, "
        "maxStartupMs}) or the `budgets` argument sets absolute caps that fail whatever the baseline says, "
        "also on a runner with no baseline. maxStartupMs is the `perf.startup` budget: the most CPU "
        "milliseconds the game may take from reading its files to its first frame (startupMs of the sample); "
        "the templates ship one with a wide margin, and the message tells how to bring start-up down. A time "
        "(cpuMsMedian, cpuMsP95, startupMs, maxStartupMs) past its fail limit FAILS when the CI environment "
        "variable is set; elsewhere it only WARNS (status \"warn\"), because a developer machine can be "
        "busy. A time past its fail limit is measured up to twice more (the best time of each metric counts) "
        "before it fails. A runner with no entry passes with status \"no_baseline\" and returns "
        "`baselineEntry`: the exact JSON to add under \"runners\" (or run perf.baseline here); with "
        "requireBaseline it fails instead (error `perf_no_baseline`, same data). Returns {runner, status: "
        "pass|warn|no_baseline, file, sample, rows: [{metric, measured, baseline, limit (where it fails), "
        "warnLimit?, warned?, exceeded}], message, provisional?, baselineEntry?}; a failure is an error "
        "`perf_budget_exceeded` with the same data.";
    c.inputSchema = Json::parse(R"({"type":"object","properties":{
        "file":{"type":"string","default":"perf.json","description":"Budget file, project-relative (or absolute)."},
        "strictTime":{"type":"boolean","description":"Make a time over its limit fail even outside CI (default: only in CI)."},
        "requireBaseline":{"type":"boolean","default":false,"description":"Fail when this runner has no entry in the file, so a CI job cannot pass without checking anything."},
        "budgets":{"type":"object","description":"Absolute caps that fail whatever the baseline says (they replace the same keys of the file's \"budgets\"): maxTriangles, maxLights, maxTextureMB, maxDrawCalls, maxEntities, maxStartupMs."}}})");
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
        // Absolute caps: the file's "budgets" object, with the keys of the `budgets` argument on top.
        Json budgetJson = budget.value("budgets", Json::object());
        if (!budgetJson.is_object()) throw CommandError("failed", file + ": \"budgets\" must be an object such as {\"maxTriangles\": 200000}.", "Fix the \"budgets\" object of the budget file.");
        if (a.contains("budgets") && a["budgets"].is_object())
            for (auto it = a["budgets"].begin(); it != a["budgets"].end(); ++it) budgetJson[it.key()] = it.value();
        const PerfBudgets caps = perf_budgets_from_json(budgetJson, &problems);
        if (!problems.empty()) throw CommandError("invalid_argument", file + ": " + problems[0], "Budgets: maxTriangles, maxLights, maxTextureMB, maxDrawCalls, maxEntities, maxStartupMs.");
        const bool strictTime = tooling_detail::arg_bool(a, "strictTime", perf_in_ci());
        PerfSample s = measure(projectDir, spec, 1);
        const std::string runner = perf_runner_id(s.graphics);
        Json result = Json::object({{"runner", runner}, {"file", file}});
        const Json* entry = nullptr;
        if (auto it = budget.find("runners"); it != budget.end() && it->is_object())
            if (auto r = it->find(runner); r != it->end() && r->is_object()) entry = &*r;
        const PerfSample base = entry ? perf_sample_from_json(*entry) : PerfSample{};
        // The baseline rows and the absolute caps. A row over its limit is a "hard" one (memory, counts: fails always) or a time
        // (CPU times, start-up: warns outside CI, fails in CI).
        struct Eval {
            PerfVerdict v;
            std::vector<PerfCheckRow> capRows;
            bool hard = false, timeOver = false;
        } e;
        auto evaluate = [&] {
            e = Eval{};
            if (entry) e.v = perf_compare(s, base, tol, strictTime);
            e.capRows = perf_budget_rows(s, caps);
            for (const std::vector<PerfCheckRow>* rows : {&e.v.rows, &e.capRows})
                for (const PerfCheckRow& r : *rows)
                    if (r.exceeded) (r.timing ? e.timeOver : e.hard) = true;
        };
        evaluate();
        // A time over the limit may be a busy machine (a shared CI VM can run a few times slower for seconds): measure up
        // to twice more and keep the best time of each metric. A game that got heavier is slow every time and still fails.
        for (int retry = 0; retry < 2 && e.timeOver && !e.hard; ++retry) {
            const PerfSample again = measure(projectDir, spec, 1);
            // The spike stays in the message: the frames named are those of the run with the worst frame, however the best time goes.
            if (!again.slowestFrames.empty() && (s.slowestFrames.empty() || again.slowestFrames[0].ms > s.slowestFrames[0].ms))
                s.slowestFrames = again.slowestFrames;
            s.cpuMsAvg = std::min(s.cpuMsAvg, again.cpuMsAvg);
            if (s.cpuMsMedian >= 0 && again.cpuMsMedian >= 0) s.cpuMsMedian = std::min(s.cpuMsMedian, again.cpuMsMedian);
            s.cpuMsP95 = std::min(s.cpuMsP95, again.cpuMsP95);
            s.cpuMsMax = std::min(s.cpuMsMax, again.cpuMsMax);
            if (s.startupMs >= 0 && again.startupMs >= 0) s.startupMs = std::min(s.startupMs, again.startupMs);
            evaluate();
        }
        std::vector<PerfCheckRow> all = e.v.rows;
        all.insert(all.end(), e.capRows.begin(), e.capRows.end());
        Json rows = Json::array();
        std::string over, inBand;
        bool startupOver = false, anyWarned = false;
        for (const PerfCheckRow& r : all) {
            Json row = Json::object({{"metric", r.metric}, {"measured", round3(r.measured)}, {"baseline", round3(r.baseline)},
                                     {"limit", round3(r.limit)}, {"exceeded", r.exceeded}});
            if (r.warnLimit != r.limit) {
                row["warnLimit"] = round3(r.warnLimit);
                row["warned"] = r.warned;
            }
            rows.push_back(row);
            if (r.warned) {
                anyWarned = true;
                inBand += std::format(" {} {} > {} (baseline {}; it fails past {});", r.metric, fmt(r.measured), fmt(r.warnLimit), fmt(r.baseline), fmt(r.limit));
            }
            if (!r.exceeded) continue;
            startupOver = startupOver || r.metric == "startupMs" || r.metric == "maxStartupMs";
            if (r.metric.rfind("max", 0) == 0) over += std::format(" {} {} > budget {};", r.metric, fmt(r.measured), fmt(r.limit));
            else over += std::format(" {} {} > limit {} (baseline {});", r.metric, fmt(r.measured), fmt(r.limit), fmt(r.baseline));
        }
        result["sample"] = perf_sample_json(s);
        if (!all.empty()) result["rows"] = rows;
        // The slowest frames: one spike decides a maximum and nothing else, so it is named, not gated.
        std::string slowest;
        for (const PerfFrame& f : s.slowestFrames) slowest += std::format("{} frame {} {} ms", slowest.empty() ? "" : ",", f.frame, fmt(f.ms));
        if (!slowest.empty()) slowest = " Slowest frames:" + slowest + ".";
        if (base.provisional) result["provisional"] = true;
        const std::string provisionalNote = base.provisional ? " The baseline entry is provisional: only draw calls, entities, triangles and lights are enforced; replace it with the output of perf.baseline on this runner (the CI workflow \"Perf baselines\" records it)." : std::string();
        const std::string startupHelp = startupOver ? " " + perf_startup_advice() : std::string();
        const bool failing = e.hard || (e.timeOver && strictTime);
        if (!entry) {
            result["status"] = "no_baseline";
            result["baselineEntry"] = Json::object({{runner, perf_sample_json(s, false)}});
            result["message"] = "No baseline for runner '" + runner + "' in " + file + ": nothing was checked against a baseline. Commit this entry under \"runners\": " +
                                dump_json(result["baselineEntry"]) + " (or run: factoria call perf.baseline).";
            if (failing)
                throw CommandError("perf_budget_exceeded", "Over the budgets of " + file + " (no baseline for runner '" + runner + "'):" + over,
                                   "Reduce what the scene draws (fewer or simpler meshes, fewer lights), or raise the budget on purpose." + startupHelp, result);
            if (e.timeOver) {  // only a time cap, outside CI
                result["status"] = "warn";
                result["message"] = "Over the time budget of " + file + " (only a warning outside CI; no baseline for runner '" + runner + "'):" + over + startupHelp;
                return result;
            }
            if (tooling_detail::arg_bool(a, "requireBaseline", false))
                throw CommandError("perf_no_baseline", result["message"].get<std::string>(),
                                   "Add baselineEntry under \"runners\" of " + file + ", or run factoria call perf.baseline on this runner.", result);
            return result;
        }
        result["status"] = failing ? "fail" : (e.timeOver || anyWarned) ? "warn" : "pass";
        if (result["status"] == "pass") {
            result["message"] = "Within the budget of runner '" + runner + "'." + slowest + provisionalNote;
            return result;
        }
        const std::string how = "If the cost is intended, refresh the baseline on this runner: factoria call perf.baseline (file: " + file +
                                "). Otherwise find what got heavier (play.report spikes, game.state)." + startupHelp;
        if (!failing) {
            std::string msg;
            if (!over.empty()) msg += "Over the time budget of runner '" + runner + "' (only a warning outside CI):" + over;
            if (!inBand.empty())
                msg += std::string(msg.empty() ? "" : " ") + "Inside the warning band of runner '" + runner + "' (not a failure; a baseline needs no refresh for this):" + inBand;
            result["message"] = msg + slowest + provisionalNote + (over.empty() ? "" : " " + how);
            return result;
        }
        throw CommandError("perf_budget_exceeded", "Over the performance budget of runner '" + runner + "' (" + file + "):" + over + slowest + provisionalNote, how, result);
    });
}

}  // namespace fa
