// The logic behind Play > Let the AI Play (auto_play_job.h).
#include "auto_play_job.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <format>

#include "fa/core/fs.h"
#include "fa/tooling/self_update.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

Json auto_play_args(const AutoPlayRequest& request) {
    const double seconds = std::isfinite(request.seconds) ? std::clamp(request.seconds, kAutoPlayMinSeconds, kAutoPlayMaxSeconds)
                                                          : kAutoPlayDefaultSeconds;
    return Json::object({{"seconds", seconds}, {"screenshots", request.screenshots}});
}

std::string auto_play_executable() {
    if (const char* env = std::getenv("FA_FACTORIA_EXE"); env && *env) {
        std::error_code ec;
        return stdfs::is_regular_file(fs::path_from_utf8(env), ec) ? std::string(env) : std::string();
    }
    stdfs::path exe = executable_path();
    if (exe.empty()) return {};
    if (exe.stem() != "factoria") {  // a game or a test: the command line tool sits next to it
        stdfs::path sibling = exe.parent_path() / "factoria";
        sibling += exe.extension();  // ".exe" on Windows, nothing elsewhere; no round trip through std::string
        std::error_code ec;
        if (!stdfs::is_regular_file(sibling, ec)) return {};
        exe = sibling;
    }
    return fs::path_to_utf8(exe);  // UTF-8, not the ANSI code page: an accented install folder survives on Windows
}

AutoPlayOutcome auto_play_outcome(const ProcessResult& run, const std::string& stdoutText) {
    AutoPlayOutcome out;
    if (run.cancelled) {
        out.cancelled = true;
        out.error = "cancelled";
        return out;
    }
    if (run.timedOut) {
        out.error = "The bot did not finish in time and was stopped.";
        out.hint = "Play fewer seconds (the window's Seconds), or run it from a terminal to watch it: factoria call play.auto '{\"seconds\":30}'.";
        return out;
    }
    auto parsed = parse_json(stdoutText, "<play.auto in a child process>");
    if (!parsed.ok() || !parsed.value().is_object()) {
        const std::string& err = run.stderrText;
        const std::string tail = err.size() > 400 ? err.substr(err.size() - 400) : err;
        out.error = std::format("The child process that runs play.auto (exit code {}) printed no result. Its error output ended with: {}",
                                run.exitCode, tail.empty() ? std::string("(nothing)") : tail);
        out.hint = "Run it from a terminal to see why: factoria call --project <dir> play.auto '{\"seconds\":10}'.";
        return out;
    }
    const Json& j = parsed.value();
    if (j.contains("ok") && j["ok"] == false) {
        const Json err = j.value("error", Json::object());
        out.error = err.is_object() ? err.value("message", std::string("play.auto failed.")) : std::string("play.auto failed.");
        out.hint = err.is_object() ? err.value("hint", std::string()) : std::string();
        return out;
    }
    out.ok = true;
    out.session = j.value("session", std::string());
    out.ended = j.value("ended", std::string());
    const Json why = j.value("endedWhy", Json());
    out.endedWhy = why.is_string() ? why.get<std::string>() : std::string();
    const Json problems = j.value("problems", Json::array());
    out.problems = problems.is_array() ? int(std::min<std::size_t>(problems.size(), 100000)) : 0;
    const Json phases = j.value("phases", Json::array());
    out.phases = phases.is_array() ? int(std::min<std::size_t>(phases.size(), 100000)) : 0;
    if (out.session.empty()) {
        out.ok = false;
        out.error = "play.auto answered without a session name.";
        out.hint = "Update FactorIA: the editor and the factoria command line tool must be the same version.";
    }
    return out;
}

std::string auto_play_summary(const AutoPlayOutcome& o) {
    if (o.cancelled) return "The AI play was cancelled; nothing was saved.";
    if (!o.ok) return "The AI could not play: " + o.error;
    const std::string problems = o.problems == 0 ? "no problems" : std::format("{} problem{}", o.problems, o.problems == 1 ? "" : "s");
    return std::format("The AI played in {:.0f} s: it ended \"{}\" with {}.", o.seconds, o.ended, problems);
}

bool AutoPlayJob::start(const AutoPlayRequest& request) {
    if (running_) return false;
    wait();  // the previous run's thread has finished: join it
    const std::string exe = auto_play_executable();
    {
        std::lock_guard<std::mutex> lock(mu_);
        result_.reset();
        line_.clear();
    }
    cancel_.store(false);
    request_ = request;
    started_ = std::chrono::steady_clock::now();
    if (exe.empty()) {
        AutoPlayOutcome out;
        out.error = "The factoria command line tool was not found next to the editor, so the bot has nothing to run.";
        out.hint = "Reinstall FactorIA (the editor is started by the `factoria` next to it), or run: factoria call play.auto '{\"seconds\":60}'.";
        std::lock_guard<std::mutex> lock(mu_);
        result_ = std::move(out);
        return true;
    }
    ProcessOptions po;
    po.argv = {exe, "call", "--project", request.projectDir, "--no-graphics", "--json", "play.auto", auto_play_args(request).dump()};
    po.workingDir = request.projectDir;
    po.cancel = &cancel_;
    po.timeoutSeconds = 1200;  // a safety net: the bot's own wall-clock cap is 800 s
    po.onStderrLine = [this](std::string_view line) {
        std::lock_guard<std::mutex> lock(mu_);
        line_ = std::string(line);
    };
    running_ = true;
    thread_ = std::thread([this, po = std::move(po)]() mutable {
        AutoPlayOutcome out;
        auto run = run_process(po);
        if (!run.ok()) {
            out.error = "Cannot start " + po.argv[0] + ": " + run.error().message;
            out.hint = run.error().hint;
        } else {
            out = auto_play_outcome(*run, run->stdoutText);
        }
        out.seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - started_).count();
        {
            std::lock_guard<std::mutex> lock(mu_);
            result_ = std::move(out);
        }
        running_ = false;  // after the result: take_result() sees both
    });
    return true;
}

double AutoPlayJob::elapsed_seconds() const {
    if (!running_) return 0;
    return std::chrono::duration<double>(std::chrono::steady_clock::now() - started_).count();
}

std::string AutoPlayJob::progress_line() const {
    std::lock_guard<std::mutex> lock(mu_);
    return line_;
}

std::optional<AutoPlayOutcome> AutoPlayJob::take_result() {
    std::lock_guard<std::mutex> lock(mu_);
    if (!result_) return std::nullopt;
    std::optional<AutoPlayOutcome> out = std::move(result_);
    result_.reset();
    return out;
}

void AutoPlayJob::wait() {
    if (thread_.joinable()) thread_.join();
}

}  // namespace fa::editor
