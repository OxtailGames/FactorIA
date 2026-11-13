// POSIX crash handler (Linux, macOS): see fa/core/crash.h. Android and iOS have no backtrace() here and keep their own
// crash logs, so installing fails there.
#include "crash_internal.h"
#include "fa/core/crash.h"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#if defined(__ANDROID__) || defined(__EMSCRIPTEN__) || (defined(__APPLE__) && TARGET_OS_IPHONE) ||                     \
    !__has_include(<execinfo.h>)

namespace fa::crash_detail {
bool platform_install(const std::filesystem::path&, std::string& error) {
    error = "crash reports are not written on this platform (no backtrace(): Android, iOS, the web)";
    return false;
}
}  // namespace fa::crash_detail

namespace fa {
void watch_thread_stack() {}
std::string watched_thread_stack() {
    return "no stack: threads' stacks are not read on this platform (Android, iOS, the web)\n";
}
std::string current_thread_stack() {
    return "no stack: stacks are not read on this platform (Android, iOS, the web)\n";
}
void report_runtime_checks_without_dialogs() {}
}  // namespace fa

#else

#include <execinfo.h>
#include <pthread.h>
#include <fcntl.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>

#include <algorithm>
#include <cerrno>
#include <chrono>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <thread>

namespace fa::crash_detail {
namespace {

constexpr int kSignals[] = {SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGABRT, SIGTRAP};

char g_dir[kMaxDirLength + 1];
alignas(16) char g_altStack[128 * 1024];  // the handler runs here, so it works after a stack overflow
std::atomic<bool> g_busy{false};

const char* signal_name(int sig) {
    switch (sig) {
        case SIGSEGV: return "SIGSEGV (invalid memory access)";
        case SIGBUS: return "SIGBUS (bad memory access)";
        case SIGILL: return "SIGILL (illegal instruction)";
        case SIGFPE: return "SIGFPE (arithmetic error)";
        case SIGABRT: return "SIGABRT (abort(), a failed assert or an uncaught exception)";
        case SIGTRAP: return "SIGTRAP (trap instruction)";
    }
    return "signal";
}

void write_all(int fd, const char* p, std::size_t n) {
    while (n > 0) {
        const ssize_t w = ::write(fd, p, n);
        if (w < 0) {
            if (errno == EINTR) continue;
            return;
        }
        p += w;
        n -= std::size_t(w);
    }
}

void flush(int fd, LineBuf& b) {
    write_all(fd, b.data, b.n);
    b.clear();
}

void write_report(int fd, int sig, const siginfo_t* info, const Civil& when, void* trampoline) {
    write_all(fd, g_shared.header, std::strlen(g_shared.header));
    LineBuf b;
    b.str("time: ");
    b.iso_time(when);
    b.str("\npid: ");
    b.dec(std::uint64_t(getpid()));
    b.str("\nsignal: ");
    b.str(signal_name(sig));
    if (info && sig == SIGSEGV) {
        if (info->si_code == SEGV_MAPERR)
            b.str(", address not mapped");
        else if (info->si_code == SEGV_ACCERR)
            b.str(", access not permitted");
    }
    if (info && (sig == SIGSEGV || sig == SIGBUS || sig == SIGILL || sig == SIGFPE)) {
        b.str("\nfault address: ");
        b.hex(std::uint64_t(reinterpret_cast<std::uintptr_t>(info->si_addr)));
    }
    if (g_shared.terminateMessage[0]) {
        b.str("\n");
        b.str(g_shared.terminateMessage);
    }
    void* frames[kMaxWalk];
    const int count = backtrace(frames, kMaxWalk);
    // The frames up to the signal trampoline (the address on_signal returns to) are the crash handler: leave them out.
    // The next one is where the signal hit, an exact address; every other frame is a return address, which can already be
    // the first byte of the NEXT function (a call to abort() ends its function): one byte back is inside the call.
    const int found = int(std::find(frames, frames + count, trampoline) - frames);
    const int first = found < count ? found + 1 : 0;
    b.str("\n\nstack (innermost first; ");
    if (!first) b.str("the first lines are the crash handler itself; ");
    b.str("return addresses are shown minus one):\n");
    flush(fd, b);
    for (int i = first, printed = 0; i < count && printed < kMaxFrames; ++printed) {
        int run = 1;  // a runaway recursion: say so once instead of filling the report with one line
        while (i + run < count && frames[i + run] == frames[i]) ++run;
        void* shown = (first && i == first) ? frames[i] : static_cast<char*>(frames[i]) - 1;
        backtrace_symbols_fd(&shown, 1, fd);
        if (run > 1) {
            b.str("    (the same frame ");
            b.dec(std::uint64_t(run - 1));
            b.str(" more times)\n");
            flush(fd, b);
        }
        i += run;
    }
    b.str("\nlast log lines (oldest first):\n");
    flush(fd, b);
    for_each_log_line([&](const char* line, std::size_t length) {
        write_all(fd, line, length);
        write_all(fd, "\n", 1);
    });
}

void on_signal(int sig, siginfo_t* info, void*) {
    if (g_busy.exchange(true)) {
        // A second crash while a report is written (another thread, or this handler faulted): the first one ends the
        // process when it is done; the watchdog below ends it if the first one hangs.
        for (;;) pause();
    }
    void* const trampoline = __builtin_return_address(0);  // where the kernel returns to after this handler
    alarm(15);  // SIGALRM ends the process by default: a report that hangs (a crash inside malloc) cannot hang the game

    const Civil when = civil_from_unix(std::int64_t(time(nullptr)));
    LineBuf path;
    path.str(g_dir);
    path.str("/crash-");
    path.stamp(when);
    path.str(".txt");
    path.data[path.n] = '\0';
    const int fd = open(path.data, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
    LineBuf message;
    message.str("FactorIA: the game crashed, ");
    if (fd >= 0) {
        write_report(fd, sig, info, when, trampoline);
        close(fd);
        message.str("report: ");
        message.str(path.data);
    } else {
        message.str("no report (cannot write ");
        message.str(path.data);
        message.str(")");
    }
    message.chr('\n');
    flush(STDERR_FILENO, message);

    // Let the system do what it would have done: the process ends with this signal (exit status, core dump, the OS crash
    // reporter). raise() because the signal may have been sent (kill, abort) and returning would then resume the program.
    signal(sig, SIG_DFL);
    raise(sig);
}

}  // namespace

bool platform_install(const std::filesystem::path& dir, std::string& error) {
    const std::string d = dir.string();
    if (!dir_length_ok(dir, d.size(), "bytes", error)) return false;
    std::memcpy(g_dir, d.c_str(), d.size() + 1);

    static bool installed = false;
    if (installed) return true;
    void* warmUp[1];
    backtrace(warmUp, 1);  // the first call may allocate (it loads the unwinder): do it now, not in a handler

    stack_t stack{};
    stack.ss_sp = g_altStack;
    stack.ss_size = sizeof g_altStack;
    if (sigaltstack(&stack, nullptr) != 0) {
        error = std::string("sigaltstack failed: ") + std::strerror(errno);
        return false;
    }
    struct sigaction action{};
    action.sa_sigaction = on_signal;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_SIGINFO | SA_ONSTACK | SA_RESETHAND;
    for (int sig : kSignals) {
        if (sigaction(sig, &action, nullptr) != 0) {
            error = std::string("sigaction failed for signal ") + std::to_string(sig) + ": " + std::strerror(errno);
            return false;
        }
    }
    installed = true;
    return true;
}

}  // namespace fa::crash_detail

// ---- the stack of a running thread (fa/core/crash.h: watch_thread_stack, watched_thread_stack, current_thread_stack) ----
//
// The watched thread is asked with a signal: its handler takes the backtrace on that thread (backtrace() walks only its
// own thread) into static storage, and the caller names the frames afterwards.

namespace fa {
namespace {

constexpr int kProbeSignal = SIGUSR2;

pthread_t g_watched;
std::atomic<bool> g_hasWatched{false};
void* g_probeFrames[crash_detail::kMaxFrames];
std::atomic<int> g_probeCount{-1};
std::mutex g_probeMutex;  // one question at a time

void on_probe(int) {
    const int saved = errno;
    g_probeCount.store(backtrace(g_probeFrames, crash_detail::kMaxFrames), std::memory_order_release);
    errno = saved;
}

std::string name_frames(void* const* frames, int count) {
    std::string out;
    char** names = backtrace_symbols(frames, count);
    for (int i = 0; i < count; ++i) {
        out += "#" + std::to_string(i) + "  ";
        out += names ? names[i] : "?";
        out += '\n';
    }
    std::free(names);
    return out;
}

}  // namespace

void watch_thread_stack() {
    static std::once_flag installed;
    std::call_once(installed, [] {
        void* warmUp[1];
        backtrace(warmUp, 1);  // the first call may allocate (it loads the unwinder): now, not in the handler
        struct sigaction action{};
        action.sa_handler = on_probe;
        sigemptyset(&action.sa_mask);
        action.sa_flags = SA_RESTART;               // the watched thread's blocking calls go on after the handler
        sigaction(kProbeSignal, &action, nullptr);  // kept installed: a late answer must never meet the default action
    });
    g_watched = pthread_self();
    g_hasWatched.store(true, std::memory_order_release);
}

std::string watched_thread_stack() {
    if (!g_hasWatched.load(std::memory_order_acquire))
        return "no stack: no thread is watched (call fa::watch_thread_stack() on it first)\n";
    if (pthread_equal(pthread_self(), g_watched)) return current_thread_stack();
    std::lock_guard<std::mutex> lock(g_probeMutex);
    g_probeCount.store(-1, std::memory_order_release);
    if (pthread_kill(g_watched, kProbeSignal) != 0) return "no stack: the watched thread has ended\n";
    const auto until = std::chrono::steady_clock::now() + std::chrono::seconds(2);
    while (g_probeCount.load(std::memory_order_acquire) < 0) {
        if (std::chrono::steady_clock::now() > until)
            return "no stack: the watched thread did not answer within 2 s (it blocks SIGUSR2, or is stopped in the "
                   "kernel)\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    const int count = g_probeCount.load(std::memory_order_acquire);
    // Not the handler itself (frame 0); the next frame is the signal trampoline, then the call the thread was in.
    return count > 1 ? name_frames(g_probeFrames + 1, count - 1) : std::string("no stack\n");
}

std::string current_thread_stack() {
    void* frames[crash_detail::kMaxFrames + 1];
    const int count = backtrace(frames, crash_detail::kMaxFrames + 1);
    return count > 1 ? name_frames(frames + 1, count - 1) : std::string("no stack\n");
}

void report_runtime_checks_without_dialogs() {}  // POSIX runtimes print a failed check and abort: no dialog to avoid

}  // namespace fa

#endif
