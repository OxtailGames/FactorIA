// run, screenshot, test
#include <filesystem>
#include <iostream>

#include "common.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/shaders.h"

namespace fa::cli {

namespace fsys = std::filesystem;

namespace {

std::vector<int> parse_frame_list(const std::string& text) {
    std::vector<int> out;
    for (const auto& part : split(text, ',')) {
        std::string p(trim(part));
        int v = 0;
        try {
            std::size_t used = 0;
            v = std::stoi(p, &used);
            if (used != p.size() || v < 0) throw std::invalid_argument("x");
        } catch (...) {
            throw UsageError("--screenshot-at expects comma-separated frame numbers, got '" + text + "'.",
                             "Example: --screenshot-at 10,60,120");
        }
        out.push_back(v);
    }
    return out;
}

std::string frame_path(const std::string& pattern, int frame) { return replace_all(pattern, "{frame}", std::to_string(frame)); }

}  // namespace

Command make_run_command() {
    Command c;
    c.name = "run";
    c.summary = "Play a project in a window, or run it headless (deterministic) and capture screenshots/state.";
    c.usage = "[project] [options]";
    c.details =
        "Windowed (default): opens the game; hot reload is on, Esc/close quits.\n"
        "Headless (--headless): no window; steps exactly 1/fixedHz per frame, so the same --seed and --input always\n"
        "give the same state and pixels. Prints a report; with --json it is machine-readable and lists the PNG\n"
        "paths so an AI can open them. Exit code 1 if scripts raised errors.\n\n"
        "Input replay JSON: {\"frames\": {\"0\": {\"press\": [\"jump\"]}, \"30\": {\"release\": [\"jump\"]}}}\n\n"
        "File paths: an INPUT file (--input) is looked up in the current directory first, then in the project folder, so\n"
        "'factoria run games/x --headless --input replays/jump.json' works from anywhere; the error lists both places.\n"
        "OUTPUT files (--state-out, --screenshot-pattern, --record-audio) are relative to the current directory; the\n"
        "report prints the absolute path written. --scene is project-relative (it names a scene of the project).";
    c.maxPositional = 1;
    c.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
               {"scene", "PATH", "Start scene override (default: project mainScene)."},
               {"width", "W", "Override the design/window width."},
               {"height", "H", "Override the design/window height."},
               {"headless", "", "No window: deterministic offscreen run."},
               {"frames", "N", "Headless: number of frames to simulate (default 60)."},
               {"input", "FILE", "Headless: input replay JSON. A relative path is looked up in the current directory, then in the project."},
               {"screenshot-at", "F1,F2", "Headless: frame numbers to capture as PNG."},
               {"screenshot-pattern", "PATTERN", "PNG path with {frame}, relative to the current directory (default <project>/.factoria/screenshots/frame_{frame}.png)."},
               {"state-out", "FILE", "Headless: write the final world state JSON here (relative to the current directory)."},
               {"record-audio", "FILE", "Headless: write the mixed audio to a WAV file (relative to the current directory)."},
               {"seed", "N", "World RNG seed (default 1)."},
               {"allow-script-errors", "", "Headless: exit 0 even if scripts raised errors."},
               {"render-all", "", "Headless: draw every frame (default: only screenshot frames and the last frame)."},
               {"persist-storage", "", "Headless: scripts' storage.* uses the real save file (default: in memory)."},
               {"json", "", "Headless: print the report as JSON."}};
    c.examples = {"factoria run",
                  "factoria run games/my-game --scene scenes/level2.scene.json",
                  "factoria run --headless --frames 120 --screenshot-at 10,60 --json",
                  "factoria run --headless --frames 300 --input replays/jump.json --state-out out/state.json --seed 7"};
    c.run = [](Context& ctx) {
        const Args& a = ctx.args;
        std::string dir = resolve_project_dir(ctx, 0);
        fs::set_project_root(dir);
        EngineConfig cfg;
        cfg.projectDir = dir;
        cfg.shaderCompiler = make_engine_shader_compiler(dir);
        cfg.scene = a.str("scene");
        cfg.width = a.integer("width", 0);
        cfg.height = a.integer("height", 0);
        cfg.seed = a.uinteger("seed", 1);
        if (!a.has("headless")) {
            for (const char* f : {"frames", "input", "screenshot-at", "screenshot-pattern", "state-out", "record-audio", "render-all", "persist-storage"})
                if (a.has(f)) throw UsageError(std::string("--") + f + " only works with --headless.", "Add --headless.");
            cfg.headless = false;
            return run_windowed(cfg);
        }
        cfg.headless = true;
        cfg.audioDevice = false;
        cfg.renderMode = a.has("render-all") ? RenderMode::Always : RenderMode::OnDemand;
        cfg.memoryStorage = !a.has("persist-storage");
        cfg.platformBackend = "fake";  // headless runs never talk to a real store (docs/PLATFORM.md)
        HeadlessRunOptions ho;
        ho.frames = a.integer("frames", 60);
        if (ho.frames < 0) throw UsageError("--frames must be >= 0.");
        // Input files: the current directory first, then the project. Output files: relative to the current directory.
        if (a.has("input")) ho.inputReplayPath = resolve_input_path(a.str("input"), dir, "the --input file");
        if (a.has("screenshot-at")) ho.screenshotFrames = parse_frame_list(a.str("screenshot-at"));
        std::string pattern = a.has("screenshot-pattern") ? absolute_path(a.str("screenshot-pattern"))
                                                          : (fsys::path(dir) / ".factoria" / "screenshots" / "frame_{frame}.png").string();
        if (pattern.find("{frame}") == std::string::npos && ho.screenshotFrames.size() > 1)
            throw UsageError("--screenshot-pattern must contain {frame} when capturing several frames.",
                             "Example: --screenshot-pattern out/shot_{frame}.png");
        ho.screenshotPattern = pattern;
        if (a.has("state-out")) ho.stateOutPath = absolute_path(a.str("state-out"));
        if (a.has("record-audio")) ho.audioOutPath = absolute_path(a.str("record-audio"));
        ho.failOnScriptError = !a.has("allow-script-errors");

        Json report = Json::object();
        int code = run_headless(cfg, ho, &report);
        if (!report.is_object()) report = Json::object();
        if (!report.contains("ok")) report["ok"] = (code == 0);
        report["exitCode"] = code;
        if (!report.contains("frames")) report["frames"] = ho.frames;
        if (!report.contains("project")) report["project"] = dir;
        if (!report.contains("screenshots")) {
            Json shots = Json::array();
            for (int f : ho.screenshotFrames) {
                std::string p = frame_path(pattern, f);
                std::error_code ec;
                if (fsys::exists(p, ec)) shots.push_back(p);
            }
            report["screenshots"] = shots;
        }
        if (!ho.stateOutPath.empty()) report["stateOut"] = ho.stateOutPath;
        if (!ho.audioOutPath.empty()) report["audioOut"] = ho.audioOutPath;
        if (a.has("json")) {
            print_json(ctx.out, report);
            return code == 0 ? 0 : 1;
        }
        ctx.out << (code == 0 ? "OK" : "FAILED") << ": ran " << report["frames"].dump() << " frames headless (exit code " << code << ")\n";
        for (const auto& s : report["screenshots"])
            ctx.out << "screenshot: " << (s.is_string() ? s.get<std::string>() : s.dump()) << "\n";
        if (!ho.stateOutPath.empty()) ctx.out << "state: " << ho.stateOutPath << "\n";
        if (!ho.audioOutPath.empty()) ctx.out << "audio: " << ho.audioOutPath << "\n";
        for (const char* key : {"scriptErrors", "sceneErrors"})
            if (report.contains(key) && report[key].is_array())
                for (const auto& e : report[key]) ctx.out << key << ": " << (e.is_string() ? e.get<std::string>() : e.dump()) << "\n";
        if (report.contains("problems") && report["problems"].is_array())
            for (const auto& pr : report["problems"]) ctx.err << "warning: " << (pr.is_string() ? pr.get<std::string>() : pr.dump()) << "\n";
        if (report.contains("error") && report["error"].is_string()) ctx.out << "error: " << report["error"].get<std::string>() << "\n";
        if (code != 0) ctx.out << "Re-run with --json for the full report.\n";
        return code == 0 ? 0 : 1;
    };
    return c;
}

Command make_screenshot_command() {
    Command c;
    c.name = "screenshot";
    c.summary = "Run headless for N frames and save a PNG of the game view.";
    c.usage = "[project] [--frames N] [--out shot.png]";
    c.maxPositional = 1;
    c.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
               {"scene", "PATH", "Start scene override."},
               {"frames", "N", "Frames to simulate before capturing (default 30)."},
               {"out", "FILE", "PNG path (default <project>/.factoria/screenshots/shot.png)."},
               {"width", "W", "Override the resolution width."},
               {"height", "H", "Override the resolution height."},
               {"seed", "N", "World RNG seed (default 1)."},
               {"json", "", "Print {path, frames} as JSON."}};
    c.examples = {"factoria screenshot", "factoria screenshot games/my-game --frames 120 --out /tmp/level.png --json"};
    c.run = [](Context& ctx) {
        const Args& a = ctx.args;
        std::string dir = resolve_project_dir(ctx, 0);
        SessionOptions so;
        so.gfx = Gfx::Required;
        so.scene = a.str("scene");
        so.width = a.integer("width", 0);
        so.height = a.integer("height", 0);
        so.seed = a.uinteger("seed", 1);
        auto session = Session::open(dir, so);
        int frames = a.integer("frames", 30);
        if (frames < 0) throw UsageError("--frames must be >= 0.");
        session->engine().step(frames);
        std::string out = a.has("out") ? absolute_path(a.str("out")) : (fsys::path(dir) / ".factoria" / "screenshots" / "shot.png").string();
        std::error_code ec;
        fsys::create_directories(fsys::path(out).parent_path(), ec);
        std::string err;
        if (!session->engine().screenshot(out, &err)) return report_failure(ctx, "Screenshot failed: " + err);
        if (a.has("json"))
            print_json(ctx.out, Json::object({{"path", out}, {"frames", frames}, {"ok", true}}));
        else
            ctx.out << out << "\n";
        return 0;
    };
    return c;
}

Command make_test_command() {
    Command c;
    c.name = "test";
    c.summary = "Run the project's tests (tests/**/*.test.js) on a headless engine.";
    c.usage = "[project] [--filter TEXT] [--json]";
    c.details = "Prints one line per test with failure messages (expected/actual); console.log/warn/error output of the tests and\nbehaviours is shown indented under the test (\"| ...\"), whatever --log-level is. Exit code 1 if any test fails or a test file does not load.";
    c.maxPositional = 1;
    c.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
               {"filter", "TEXT", "Only run tests whose name contains TEXT."},
               {"render-all", "", "Draw every frame (default: only when a test takes a screenshot)."},
               {"persist-storage", "", "Scripts' storage.* uses the real save file (default: in memory)."},
               {"json", "", "Machine-readable report."}};
    c.examples = {"factoria test", "factoria test --filter jump --json"};
    c.run = [](Context& ctx) {
        std::string dir = resolve_project_dir(ctx, 0);
        SessionOptions so;  // OnDemand rendering + in-memory storage by default
        so.gfx = Gfx::Auto;
        so.renderMode = ctx.args.has("render-all") ? RenderMode::Always : RenderMode::OnDemand;
        so.memoryStorage = !ctx.args.has("persist-storage");
        auto session = Session::open(dir, so);
        TestReport rep = run_project_tests(session->engine(), ctx.args.str("filter"));
        if (ctx.args.has("json")) {
            Json j = rep.to_json();
            if (!j.contains("ok")) j["ok"] = rep.ok();
            print_json(ctx.out, j);
            return rep.ok() ? 0 : 1;
        }
        if (rep.cases.empty() && rep.loadErrors.empty()) {
            ctx.out << "No tests found (tests/*.test.js"
                    << (ctx.args.has("filter") ? " matching '" + ctx.args.str("filter") + "'" : "") << ").\n";
            return 0;
        }
        auto print_logs = [&](const std::vector<TestLogLine>& logs) {
            for (const auto& l : logs) {
                const char* tag = l.level >= LogLevel::Error ? "error: " : l.level == LogLevel::Warn ? "warn: " : "";
                ctx.out << "        | " << tag << replace_all(l.message, "\n", "\n        | ") << "\n";
            }
        };
        if (!rep.otherLogs.empty()) {
            ctx.out << "  (output outside tests)\n";
            print_logs(rep.otherLogs);
        }
        for (const auto& t : rep.cases) {
            ctx.out << (t.passed ? "  PASS  " : "  FAIL  ") << t.file << " > " << t.name << " (" << static_cast<int>(t.milliseconds) << " ms)\n";
            print_logs(t.logs);
            if (!t.passed && !t.message.empty()) ctx.out << "        " << replace_all(t.message, "\n", "\n        ") << "\n";
        }
        for (const auto& e : rep.loadErrors) ctx.out << "  ERROR " << e.to_string() << "\n";
        // TestReport::summary() repeats every case; the lines above already list them, print only the totals.
        std::string sum = rep.summary();
        if (auto nl = sum.rfind('\n'); nl != std::string::npos) sum = sum.substr(nl + 1);
        ctx.out << sum << "\n";
        return rep.ok() ? 0 : 1;
    };
    return c;
}

}  // namespace fa::cli
