// A command of the open project in a child factoria process (child_command_job.h).
#include "child_command_job.h"

#include <format>

#include "fa/core/fs.h"
#include "fa/tooling/play_auto.h"  // factoria_executable

namespace fa::editor {

ChildCommandOutcome child_command_outcome(const ProcessResult& run, const std::string& stdoutText,
                                          const std::string& command) {
    ChildCommandOutcome out;
    if (run.cancelled) {
        out.cancelled = true;
        out.error = "cancelled";
        return out;
    }
    if (run.timedOut) {
        out.error = command + " did not finish in time and was stopped.";
        out.hint = "Ask for less (fewer or smaller items), or run it from a terminal to watch it: factoria call " +
                   command + " ...";
        return out;
    }
    auto parsed = parse_json(stdoutText, "<" + command + " in a child process>");
    if (!parsed.ok() || !parsed.value().is_object()) {
        const std::string& err = run.stderrText;
        const std::string tail = err.size() > 400 ? err.substr(err.size() - 400) : err;
        out.error = std::format(
            "The child process that runs {} (exit code {}) printed no result. Its error output ended with: {}", command,
            run.exitCode, tail.empty() ? std::string("(nothing)") : tail);
        out.hint = "Run it from a terminal to see why: factoria call --project <dir> " + command + " '<arguments>'.";
        return out;
    }
    const Json& j = parsed.value();
    if (const auto okIt = j.find("ok"); okIt != j.end() && *okIt == false) {
        // Read without trusting the shape: a key of the wrong type is a missing one, never an exception.
        const auto text = [](const Json& o, const char* key) {
            const auto it = o.is_object() ? o.find(key) : o.end();
            return it != o.end() && it->is_string() ? it->get<std::string>() : std::string();
        };
        const auto errIt = j.find("error");
        const Json err = errIt != j.end() ? *errIt : Json::object();
        out.error = text(err, "message");
        if (out.error.empty()) out.error = command + " failed.";
        out.hint = text(err, "hint");
        out.code = text(err, "code");
        return out;
    }
    out.ok = true;
    out.value = j;
    return out;
}

bool ChildCommandJob::start(const std::filesystem::path& projectDir, const std::string& command, const Json& args,
                            double timeoutSeconds) {
    if (running_) return false;
    wait();  // the previous run's thread has finished: join it
    const std::string exe = factoria_executable();
    {
        std::lock_guard<std::mutex> lock(mu_);
        result_.reset();
    }
    cancel_.store(false);
    command_ = command;
    started_ = std::chrono::steady_clock::now();
    if (exe.empty()) {
        ChildCommandOutcome out;
        out.error = "The factoria command line tool was not found next to the editor, so " + command +
                    " has nothing to run in.";
        out.hint = "Reinstall FactorIA (the editor is started by the `factoria` next to it), or run it from a "
                   "terminal: factoria call " +
                   command + " ...";
        std::lock_guard<std::mutex> lock(mu_);
        result_ = std::move(out);
        return true;
    }
    ProcessOptions po;
    // UTF-8 for the child (process_win32 widens argv and the working directory as UTF-8): the path object carries the real name.
    const std::string projectUtf8 = fs::path_to_utf8(projectDir);
    // replace: text that is not valid UTF-8 (a note cut inside a character) becomes U+FFFD instead of throwing on the UI thread.
    po.argv = {exe,
               "call",
               "--project",
               projectUtf8,
               "--no-graphics",
               "--json",
               command,
               args.dump(-1, ' ', false, Json::error_handler_t::replace)};
    po.workingDir = projectUtf8;
    po.cancel = &cancel_;
    po.timeoutSeconds = timeoutSeconds;
    running_ = true;
    thread_ = std::thread([this, po = std::move(po), command]() mutable {
        ChildCommandOutcome out;
        auto run = run_process(po);
        if (!run.ok()) {
            out.error = "Cannot start " + po.argv[0] + ": " + run.error().message;
            out.hint = run.error().hint;
        } else {
            out = child_command_outcome(*run, run->stdoutText, command);
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

double ChildCommandJob::elapsed_seconds() const {
    if (!running_) return 0;
    return std::chrono::duration<double>(std::chrono::steady_clock::now() - started_).count();
}

std::optional<ChildCommandOutcome> ChildCommandJob::take_result() {
    std::lock_guard<std::mutex> lock(mu_);
    if (!result_) return std::nullopt;
    std::optional<ChildCommandOutcome> out = std::move(result_);
    result_.reset();
    return out;
}

void ChildCommandJob::wait() {
    if (thread_.joinable()) thread_.join();
}

bool ChildCommandJob::wait_for(double seconds) {
    const auto until = std::chrono::steady_clock::now() + std::chrono::duration<double>(seconds);
    while (running_.load()) {
        if (std::chrono::steady_clock::now() >= until) return false;
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    wait();
    return true;
}

}  // namespace fa::editor
