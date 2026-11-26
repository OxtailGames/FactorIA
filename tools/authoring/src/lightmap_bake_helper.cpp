#include "lightmap_bake_helper.h"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cctype>
#include <cstdlib>
#include <filesystem>
#include <thread>

#include "fa/core/child_process.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/render/lightmap_gpu_bake.h"

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#endif

namespace fa::lightmap_job {

namespace {

namespace stdfs = std::filesystem;
using Clock = std::chrono::steady_clock;

std::atomic<int> g_helperUse{int(HelperUse::Auto)};

// Seconds. Safety nets far above what a real start, answer or cancel takes (a loaded 4-vCPU CI VM starts `factoria` in a few seconds).
constexpr double kReadySeconds = 120;
constexpr double kAnswerSeconds = 120;
constexpr double kCancelSeconds = 120;
constexpr auto kPollEvery = std::chrono::milliseconds(100);
constexpr auto kCancelSlice = std::chrono::milliseconds(20);

// This program's own file, without the `factoria` tools of tooling (a module above this one).
stdfs::path own_executable() {
    std::error_code ec;
#if defined(_WIN32)
    wchar_t buf[MAX_PATH * 4];
    const DWORD n = GetModuleFileNameW(nullptr, buf, DWORD(sizeof(buf) / sizeof(buf[0])));
    if (n > 0 && n < DWORD(sizeof(buf) / sizeof(buf[0]))) return stdfs::path(std::wstring(buf, n));
#elif defined(__APPLE__)
    char buf[4096];
    std::uint32_t size = sizeof(buf);
    if (_NSGetExecutablePath(buf, &size) == 0) return stdfs::weakly_canonical(stdfs::path(buf), ec);
#else
    const stdfs::path p = stdfs::read_symlink("/proc/self/exe", ec);
    if (!ec) return p;
#endif
    return {};
}

// The $FA_FACTORIA_EXE override as a path (read as wide characters on Windows: the narrow environment is the ANSI code page).
bool env_override(stdfs::path& out) {
#if defined(_WIN32)
    const wchar_t* env = _wgetenv(L"FA_FACTORIA_EXE");
    if (env == nullptr || *env == 0) return false;
    out = stdfs::path(std::wstring(env));
#else
    const char* env = std::getenv("FA_FACTORIA_EXE");
    if (env == nullptr || *env == 0) return false;
    out = stdfs::path(env);
#endif
    return true;
}

// What a failed or stopped helper tells the user about the files: the pages are written first and the manifest last, so a helper that
// died while it was writing may have left new pages next to the old manifest.
std::string files_hint(const std::string& lastPhase, const std::string& advice) {
    if (lastPhase == "writing")
        return "The helper stopped while it was writing the files: the manifest is the old one or the new one, but a "
               "page next to it "
               "can be new. Bake again to replace the set. " +
               advice;
    return "Nothing was changed. " + advice;
}

bool iequals_ascii(const std::string& a, const std::string& b) {
    if (a.size() != b.size()) return false;
    for (std::size_t i = 0; i < a.size(); ++i)
        if (std::tolower(static_cast<unsigned char>(a[i])) != std::tolower(static_cast<unsigned char>(b[i])))
            return false;
    return true;
}

enum class Ask { Ok, Failed, Dead, TimedOut, Cancelled };
struct Reply {
    Ask kind = Ask::Dead;
    Json result;
    Error error{"", ""};
};

bool cancel_requested();

enum class Sent { Ok, Gone, TimedOut, Cancelled };

// A request line up to this size fits in the pipe to the helper (4 KB is the smallest pipe buffer of the three systems), so
// writing it cannot block on a helper that does not read.
constexpr std::size_t kSmallWrite = 2048;

// Writes `line` to the helper's input. A long line (the plan of a big scene is megabytes) is written by a thread of its own
// while this one watches the clock and, when `cancellable`, the cancel flag: a helper that stopped reading (hung, or stopped by
// a GPU reset) would block a plain write for ever and ignore a cancel. On a timeout or a cancel the helper is terminated, which
// breaks the pipe and ends the write; the thread is joined before this returns.
Sent send_line(ChildProcess& child, const std::string& line, double timeoutSeconds, bool cancellable) {
    if (line.size() <= kSmallWrite) return child.write(line) ? Sent::Ok : Sent::Gone;
    std::atomic<int> state{0};  // 0 writing, 1 written, 2 failed
    std::thread writer([&] { state.store(child.write(line) ? 1 : 2); });
    const auto deadline =
        Clock::now() + std::chrono::duration_cast<Clock::duration>(std::chrono::duration<double>(timeoutSeconds));
    Sent result = Sent::Ok;
    while (state.load() == 0) {
        if (cancellable && cancel_requested()) {
            result = Sent::Cancelled;
            break;
        }
        if (Clock::now() >= deadline) {
            result = Sent::TimedOut;
            break;
        }
        std::this_thread::sleep_for(kCancelSlice);
    }
    if (result != Sent::Ok) child.terminate();  // terminate does not touch the input the writer is in
    writer.join();
    if (result == Sent::Ok && state.load() == 2) result = Sent::Gone;
    return result;
}

// One request line and its answer line (the session answers in order; lines that are not an answer are skipped).
// `cancellable`: a cancel of this thread's command also ends the wait for the helper to take a long request.
Reply ask(ChildProcess& child, const char* command, const Json& args, double timeoutSeconds, bool cancellable = false) {
    Reply reply;
    const Json request = Json::object({{"command", command}, {"args", args}});
    switch (send_line(child, request.dump() + "\n", timeoutSeconds, cancellable)) {
        case Sent::Ok: break;
        case Sent::Gone: return reply;
        case Sent::TimedOut: reply.kind = Ask::TimedOut; return reply;
        case Sent::Cancelled: reply.kind = Ask::Cancelled; return reply;
    }
    const auto deadline =
        Clock::now() + std::chrono::duration_cast<Clock::duration>(std::chrono::duration<double>(timeoutSeconds));
    std::string line;
    for (;;) {
        const double left = std::chrono::duration<double>(deadline - Clock::now()).count();
        if (left <= 0) {
            reply.kind = Ask::TimedOut;
            return reply;
        }
        switch (child.read_line(line, left, nullptr)) {
            case ChildProcess::Read::Timeout: reply.kind = Ask::TimedOut; return reply;
            case ChildProcess::Read::Closed:
            case ChildProcess::Read::Cancelled: return reply;
            case ChildProcess::Read::Line: break;
        }
        auto parsed = parse_json(line, "<the bake helper's answer>");
        if (!parsed.ok() || !parsed->is_object() || !parsed->contains("ok")) continue;
        if ((*parsed)["ok"] == true) {
            reply.kind = Ask::Ok;
            reply.result = parsed->value("result", Json::object());
            return reply;
        }
        const Json err = parsed->value("error", Json::object());
        reply.kind = Ask::Failed;
        reply.error = make_error(err.value("message", std::string("the helper reported an error without a message")),
                                 err.value("hint", std::string()));
        return reply;
    }
}

bool cancel_requested() {
    const std::atomic<bool>* flag = command_cancel_flag();
    return flag != nullptr && flag->load(std::memory_order_relaxed);
}

// Sleeps `total`, a few milliseconds at a time, and returns early when this thread's command was cancelled.
void nap(std::chrono::milliseconds total) {
    for (auto left = total; left.count() > 0 && !cancel_requested(); left -= kCancelSlice)
        std::this_thread::sleep_for(std::min(left, std::chrono::milliseconds(kCancelSlice)));
}

HelperOutcome outcome(HelperOutcome::Kind kind, std::string message, std::string hint) {
    HelperOutcome out;
    out.kind = kind;
    out.error = make_error(std::move(message), std::move(hint));
    return out;
}

std::string tail_of(const ChildProcess& child) {
    std::string tail = child.stderr_tail();
    if (tail.size() > 600) tail = tail.substr(tail.size() - 600);
    while (!tail.empty() && (tail.back() == '\n' || tail.back() == '\r')) tail.pop_back();
    return tail.empty() ? std::string("it printed nothing") : "its error output ended with: " + tail;
}

}  // namespace

void set_helper_use(HelperUse use) { g_helperUse.store(int(use)); }
HelperUse helper_use() {
    const HelperUse set = HelperUse(g_helperUse.load());
    if (set != HelperUse::Auto) return set;
    // $FA_LIGHTMAP_HELPER=always|never: for a machine where the choice made here is wrong, and for the tests that run the helper path on a
    // machine that does not need it.
    if (const char* env = std::getenv("FA_LIGHTMAP_HELPER")) {
        const std::string v = env;
        if (v == "always") return HelperUse::Always;
        if (v == "never") return HelperUse::Never;
    }
    return HelperUse::Auto;
}

std::string helper_executable() {
    std::error_code ec;
    stdfs::path override;
    if (env_override(override))  // a wrong override is not replaced by another program
        return stdfs::is_regular_file(override, ec) ? fs::path_to_utf8(override) : std::string();
    stdfs::path exe = own_executable();
    if (exe.empty()) return {};
    if (!iequals_ascii(
            fs::path_to_utf8(exe.stem()),
            "factoria")) {  // Factoria.exe on Windows too  // the editor or a game: the command line tool sits next to it
        stdfs::path sibling = exe.parent_path() / "factoria";
        sibling += exe.extension();  // ".exe" on Windows, nothing elsewhere; no round trip through std::string
        if (!stdfs::is_regular_file(sibling, ec)) return {};
        exe = sibling;
    }
    return fs::path_to_utf8(exe);
}

bool in_helper_session() {
    const char* env = std::getenv(kHelperSessionEnv);  // the value is ASCII
    return env != nullptr && std::string(env) == "1";
}

bool helper_wanted(const Plan& plan) {
    if (plan.options.device == DeviceChoice::Cpu) return false;
    const bool texels =
        std::any_of(plan.meshes.begin(), plan.meshes.end(), [](const PlanMesh& m) { return m.receiver; });
    if (!texels) return false;  // only probes (or nothing to light): the CPU does it, here
    switch (helper_use()) {
        case HelperUse::Never: return false;
        case HelperUse::Always: return true;
        case HelperUse::Auto: break;
    }
    return render::LightmapGpuTracer::open_needs_helper_process();
}

HelperOutcome run_in_helper(const Plan& plan, const ReportFn& report) {
    auto say = [&](const std::string& phase, double progress, std::uint64_t rays) {
        if (report) report(phase, progress, rays);
    };
    const std::string exe = helper_executable();
    if (exe.empty())
        return outcome(HelperOutcome::Kind::Unavailable,
                       "this program already uses the graphics card, so the GPU bake needs a second process, and the "
                       "factoria program that would run it was not found next to this one",
                       "Bake from a terminal (factoria call lightmap.bake '{\"device\":\"gpu\"}'), keep `factoria` in "
                       "the same folder as the editor, or set FA_FACTORIA_EXE. device \"cpu\" always works.");
    const stdfs::path root = fs::project_root();
    if (root.empty())
        return outcome(HelperOutcome::Kind::Unavailable, "no project folder is open for the helper process to bake in",
                       "Open a project first.");
    const std::string rootUtf8 = fs::path_to_utf8(root);

    say("prepare", 0.0, 0);
    ChildOptions options;
    options.argv = {exe, "session", "--project", rootUtf8, "--no-graphics", "--no-scene"};
    options.workingDir = rootUtf8;
    options.env[kHelperSessionEnv] = "1";  // lightmap.bake_plan_start answers only a session that has it
    auto started = ChildProcess::start(options);
    if (!started.ok())
        return outcome(HelperOutcome::Kind::Unavailable,
                       "the helper process could not be started: " + started.error().message, started.error().hint);
    ChildProcess& child = *started.value();

    // The first line it prints says it is ready.
    {
        const auto deadline =
            Clock::now() + std::chrono::duration_cast<Clock::duration>(std::chrono::duration<double>(kReadySeconds));
        std::string line;
        bool ready = false;
        while (!ready) {
            if (cancel_requested()) {
                child.terminate();
                return outcome(HelperOutcome::Kind::Cancelled, "cancelled", "");
            }
            const double left = std::chrono::duration<double>(deadline - Clock::now()).count();
            if (left <= 0) {
                child.terminate();
                return outcome(HelperOutcome::Kind::Unavailable,
                               "the helper process did not become ready within " + std::to_string(int(kReadySeconds)) +
                                   " seconds",
                               "Run `factoria session --no-graphics` in the project to see why it does not start.");
            }
            switch (child.read_line(line, std::min(left, 0.1), nullptr)) {
                case ChildProcess::Read::Timeout: continue;
                case ChildProcess::Read::Closed:
                case ChildProcess::Read::Cancelled:
                    return outcome(HelperOutcome::Kind::Unavailable,
                                   "the helper process ended before it was ready: " + tail_of(child),
                                   "Run `factoria session --no-graphics` in the project to see why it does not start.");
                case ChildProcess::Read::Line: break;
            }
            auto parsed = parse_json(line, "<the bake helper's first line>");
            ready = parsed.ok() && parsed->is_object() && parsed->contains("ready");
        }
    }

    Reply started1 =
        ask(child, "lightmap.bake_plan_start", Json::object({{"plan", plan_to_json(plan)}}), kAnswerSeconds, true);
    if (started1.kind == Ask::Cancelled) return outcome(HelperOutcome::Kind::Cancelled, "cancelled", "");
    if (started1.kind == Ask::Failed) {
        child.terminate();
        return outcome(HelperOutcome::Kind::Failed, started1.error.message, started1.error.hint);
    }
    if (started1.kind != Ask::Ok) {
        child.terminate();
        return outcome(HelperOutcome::Kind::Crashed, "the helper process did not take the bake: " + tail_of(child),
                       "Bake with device \"cpu\", or report this with the scene.");
    }
    const std::string jobId = started1.result.value("job", std::string());
    const Json jobArgs = Json::object({{"job", jobId}, {"apply", false}});

    bool cancelSent = false;
    Clock::time_point cancelDeadline;
    Clock::time_point lastChange = Clock::now();
    std::string lastPhase;
    double lastProgress = -1;
    std::uint64_t lastRays = 0;
    for (;;) {
        if (cancel_requested() && !cancelSent) {
            cancelSent = true;
            cancelDeadline = Clock::now() +
                             std::chrono::duration_cast<Clock::duration>(std::chrono::duration<double>(kCancelSeconds));
            (void)ask(child, "lightmap.bake_cancel", Json::object({{"job", jobId}}), kAnswerSeconds);
        }
        Reply status = ask(child, "lightmap.bake_status", jobArgs, kAnswerSeconds);
        if (status.kind != Ask::Ok) {
            const bool hung = status.kind == Ask::TimedOut;
            const std::string why =
                hung ? "the helper process stopped answering"
                     : "the helper process stopped (a driver crash or a GPU reset?): " + tail_of(child);
            child.terminate();
            if (cancelSent) return outcome(HelperOutcome::Kind::Cancelled, "cancelled", "");
            return outcome(HelperOutcome::Kind::Crashed, why,
                           files_hint(lastPhase, "Bake with device \"cpu\" if the graphics driver keeps failing."));
        }
        const std::string state = status.result.value("state", std::string());
        if (state == "running") {
            const std::string phase = status.result.value("phase", std::string("prepare"));
            const double progress = std::clamp(status.result.value("progress", 0.0), 0.0, 1.0);
            const std::uint64_t rays = status.result.value("rays", std::uint64_t(0));
            if (phase != lastPhase || progress != lastProgress || rays != lastRays) {
                lastPhase = phase;
                lastProgress = progress;
                lastRays = rays;
                lastChange = Clock::now();
                say(phase, progress, rays);
            } else if (std::chrono::duration<double>(Clock::now() - lastChange).count() > kHelperStallSeconds) {
                child.terminate();
                return outcome(HelperOutcome::Kind::Crashed,
                               "the helper process made no progress for " + std::to_string(int(kHelperStallSeconds)) +
                                   " seconds and was stopped",
                               files_hint(lastPhase, "Bake with device \"cpu\", or with fewer samples."));
            }
            if (cancelSent && Clock::now() > cancelDeadline) {
                child.terminate();
                return outcome(HelperOutcome::Kind::Cancelled, "cancelled", "");
            }
            if (cancelSent)
                std::this_thread::sleep_for(kPollEvery);  // the cancel is on its way: no more looking at the flag
            else
                nap(std::chrono::duration_cast<std::chrono::milliseconds>(kPollEvery));
            continue;
        }
        HelperOutcome out;
        if (state == "done") {
            out.kind = HelperOutcome::Kind::Done;
            out.result = status.result.value("result", Json::object());
            say("writing", 1.0, out.result.value("rays", std::uint64_t(0)));
        } else if (state == "cancelled") {
            out.kind = HelperOutcome::Kind::Cancelled;
            out.error = make_error("cancelled", "the bake was cancelled before it wrote anything");
        } else {
            out.kind = HelperOutcome::Kind::Failed;
            out.error = make_error(status.result.value("error", std::string("the bake failed in the helper process")),
                                   status.result.value("hint", std::string()));
        }
        (void)child.write(
            "{\"command\":\"session.quit\"}\n");  // it leaves by itself; the destructor waits for it and ends it if it does not
        return out;
    }
}

}  // namespace fa::lightmap_job
