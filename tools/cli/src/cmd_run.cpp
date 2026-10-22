// run, screenshot, test
#include <filesystem>
#include <iostream>

#include "common.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/export_settings.h"
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
        "OUTPUT files (--state-out, --screenshot-pattern, --record-audio, --record-video) are relative to the current directory; the\n"
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
               {"render-scale", "S", "Headless: screenshots are design size * S (0.25 to 4, default 1) drawn natively and sharp: HUD and visible area unchanged, 1.5 on 1280x720 = 1920x1080 for store screenshots."},
               {"screenshot-simulate", "MODE", "Headless: save the screenshots as a colour-blind viewer sees them: greyscale, protanopia, deuteranopia or tritanopia (Machado 2009, severity 1.0; the video and the game are unchanged). Checks that hazards read without colour."},
               {"screenshot-pattern", "PATTERN", "PNG path with {frame}, relative to the current directory (default <project>/.factoria/screenshots/frame_{frame}.png)."},
               {"state-out", "FILE", "Headless: write the final world state JSON here (relative to the current directory)."},
               {"record-audio", "FILE", "Headless: write the mixed audio to a WAV file (relative to the current directory)."},
               {"record-video", "FILE", "Headless: write every frame (drawn at --render-scale, at the project's fixedHz fps) and the audio to a video. .avi (Motion-JPEG + PCM) needs nothing; .mp4 (H.264 + AAC) needs ffmpeg (FACTORIA_FFMPEG, publish.ffmpeg in ~/.factoria/export.json, or PATH). Relative to the current directory."},
               {"seed", "N", "World RNG seed (default 1)."},
               kDateFlag,
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
        EngineConfig cfg = project_engine_config(dir, a.str("scene"), a.uinteger("seed", 1), date_flag(a));
        cfg.width = a.integer("width", 0);
        cfg.height = a.integer("height", 0);
        if (!a.has("headless")) {
            for (const char* f : {"frames", "input", "screenshot-at", "render-scale", "screenshot-simulate", "screenshot-pattern", "state-out", "record-audio", "record-video", "render-all", "persist-storage"})
                if (a.has(f)) throw UsageError(std::string("--") + f + " only works with --headless.", "Add --headless.");
            cfg.headless = false;
            return run_windowed(cfg);
        }
        apply_headless_config(cfg, a.has("render-all"), a.has("persist-storage"));
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
        ho.renderScale = a.number("render-scale", 1.0);
        if (a.has("screenshot-simulate")) {
            ho.screenshotSimulate = a.str("screenshot-simulate");
            if (auto parsed = parse_color_simulation(ho.screenshotSimulate); !parsed.ok())
                throw UsageError("--screenshot-simulate: " + parsed.error().message, parsed.error().hint);
        }
        if (a.has("state-out")) ho.stateOutPath = absolute_path(a.str("state-out"));
        if (a.has("record-audio")) ho.audioOutPath = absolute_path(a.str("record-audio"));
        if (a.has("record-video")) {
            ho.videoOutPath = absolute_path(a.str("record-video"));
            if (fs::extension(ho.videoOutPath) == ".mp4") {  // only an .mp4 needs ffmpeg; a variable that points at nothing is an error
                auto ffmpeg = find_ffmpeg();
                if (!ffmpeg.ok())
                    throw UsageError(ffmpeg.error().message, ffmpeg.error().hint + " Or record an .avi, which needs nothing: --record-video out.avi.");
                ho.ffmpegPath = ffmpeg->path;
            }
        }
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
        if (report.contains("perf") && report["perf"].is_object()) {
            const Json& pf = report["perf"];
            ctx.out << "perf: cpu/frame avg " << pf.value("cpuMsAvg", 0.0) << " ms, p95 " << pf.value("cpuMsP95", 0.0) << " ms, max "
                    << pf.value("cpuMsMax", 0.0) << " ms; peak memory " << pf.value("peakMemoryMB", 0.0) << " MB; draw calls "
                    << pf.value("drawCalls", 0) << "; entities " << pf.value("entities", 0) << " (graphics: " << pf.value("graphics", std::string()) << ")\n";
        }
        for (const auto& s : report["screenshots"])
            ctx.out << "screenshot: " << (s.is_string() ? s.get<std::string>() : s.dump()) << "\n";
        if (!ho.stateOutPath.empty()) ctx.out << "state: " << ho.stateOutPath << "\n";
        if (!ho.audioOutPath.empty()) ctx.out << "audio: " << ho.audioOutPath << "\n";
        if (report.contains("videoPath"))
            ctx.out << "video: " << report["videoPath"].get<std::string>() << " (" << report["videoFrames"].dump() << " frames"
                    << (report.value("videoAudio", false) ? ", with audio" : ", no audio") << ")\n";
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
               {"render-scale", "S", "Image size = design size * S (0.25 to 4, default 1), drawn natively and sharp: HUD and visible area unchanged, 1.5 on 1280x720 = 1920x1080."},
               {"seed", "N", "World RNG seed (default 1)."},
               kDateFlag,
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
        so.date = date_flag(a);
        auto session = Session::open(dir, so);
        int frames = a.integer("frames", 30);
        if (frames < 0) throw UsageError("--frames must be >= 0.");
        session->engine().step(frames);
        std::string out = a.has("out") ? absolute_path(a.str("out")) : (fsys::path(dir) / ".factoria" / "screenshots" / "shot.png").string();
        std::error_code ec;
        fsys::create_directories(fsys::path(out).parent_path(), ec);
        std::string err;
        if (!session->engine().screenshot_scaled(out, a.number("render-scale", 1.0), &err)) return report_failure(ctx, "Screenshot failed: " + err);
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
    c.usage = "[project] [FILE|GLOB...] [--filter TEXT] [--json]";
    c.details = "Prints one line per test with failure messages (expected/actual); console.log/warn/error output of the tests and\nbehaviours is shown indented under the test (\"| ...\"), whatever --log-level is. Exit code 1 if any test fails or a test file does not load.\nName test files (tests/saves.test.js), folders or globs (\"tests/ui*.test.js\", relative to the project) after the project to run only those; the project folder may be left out when you are inside it. A path that is not a *.test.js file is an error.";
    c.maxPositional = -1;
    c.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
               {"filter", "TEXT", "Only run tests whose name contains TEXT."},
               {"render-all", "", "Draw every frame (default: only when a test takes a screenshot)."},
               {"persist-storage", "", "Scripts' storage.* uses the real save file (default: in memory)."},
               kDateFlag,
               {"json", "", "Machine-readable report."}};
    c.examples = {"factoria test", "factoria test --filter jump --json", "factoria test tests/saves.test.js", "factoria test my-game \"tests/ui*.test.js\""};
    c.run = [](Context& ctx) {
        // The first argument is the project when it is a folder; a file or a glob first means the project is the current
        // one (or --project).
        std::vector<std::string> given = ctx.args.positional();
        std::error_code ec;
        std::string dir;
        if (!given.empty() && fsys::is_directory(fsys::path(given[0]), ec)) {
            dir = resolve_project_dir(ctx, 0);
            given.erase(given.begin());
        } else {
            if (!given.empty() && find_project_dir_or_empty(ctx, 99).empty())
                throw CliError("'" + given[0] + "' is not a project folder, and no FactorIA project was found in the current directory or any parent.",
                               "Give the project folder first: factoria test <project> " + given[0] + ".");
            dir = resolve_project_dir(ctx, 99);
        }
        // Paths are relative to the project; one typed relative to the current directory inside it, or absolute, is converted.
        for (std::string& g : given) {
            const fsys::path p(g);
            if (g.find_first_of("*?") != std::string::npos) continue;
            fsys::path abs = p.is_absolute() ? p : fsys::current_path(ec) / p;
            if (fsys::exists(abs, ec) && (p.is_absolute() || !fsys::exists(fsys::path(dir) / p, ec))) {
                const fsys::path rel = fsys::weakly_canonical(abs, ec).lexically_relative(fsys::weakly_canonical(fsys::path(dir), ec));
                if (!rel.empty() && *rel.begin() != "..") g = rel.generic_string();
            }
        }
        SessionOptions so;  // OnDemand rendering + in-memory storage by default
        so.gfx = Gfx::Auto;
        so.renderMode = ctx.args.has("render-all") ? RenderMode::Always : RenderMode::OnDemand;
        so.memoryStorage = !ctx.args.has("persist-storage");
        so.date = date_flag(ctx.args);
        auto session = Session::open(dir, so);
        TestReport rep = run_project_tests(session->engine(), ctx.args.str("filter"), given);
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
