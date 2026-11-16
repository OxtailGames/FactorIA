// Android: the end of the activity reaches the game (docs/mobile/MOBILE_ANDROID.md, "Lifecycle").
//
// sokol_app runs the app's callbacks only while a surface exists, and the surface is always gone when the activity's
// onDestroy arrives, so its cleanup never runs and the process ends with _exit(0) (sokol_impl.c). This file runs the
// game's last code before that: the onDestroy wrapper of sokol_impl.c calls fa_android_activity_ending() on Android's
// main thread, which writes a byte to a pipe that sokol_app's loop thread watches (its ALooper) and waits, at most
// kAndroidEndBudgetMs, while the loop thread sends AppEvent::Type::Ending (app.cpp). Script code never runs on the main
// thread, the GPU is not touched, and a loop thread that does not answer in time costs the main thread the budget only.
#include <android/log.h>
#include <android/looper.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

#include <atomic>
#include <chrono>

#include "activity_end.h"
#include "fa/platform/end_handshake.h"

namespace fa {
namespace {

// What Android's main thread waits for the game's end. Far above what the end takes (a few quit handlers, the storage
// writes, the audio device closing), far below what makes Android report the app as not responding.
constexpr int kAndroidEndBudgetMs = 1500;

EndHandshake& handshake() {
    static EndHandshake* h =
        new EndHandshake();  // never destroyed: the process ends with _exit, threads may still wait
    return *h;
}

std::atomic<int> g_wakeFd{-1};  // the pipe's write end; -1 until the loop thread watches the read end

// sokol_app's loop thread, inside ALooper_pollOnce: the main thread asked for the game's end.
int on_wake(int fd, int events, void*) {
    char buf[16];
    while (read(fd, buf, sizeof buf) > 0) {
    }
    handshake().serve(app_android_end);
    return (events & (ALOOPER_EVENT_ERROR | ALOOPER_EVENT_HANGUP)) ? 0 : 1;  // 0 stops watching a broken pipe
}

}  // namespace

void android_end_attach() {
    if (g_wakeFd.load(std::memory_order_acquire) >= 0) return;
    ALooper* looper = ALooper_forThread();
    if (!looper) {
        __android_log_print(ANDROID_LOG_WARN, "factoria",
                            "platform: no looper on the app's thread: the game's end will not run");
        return;
    }
    int fds[2];
    if (pipe2(fds, O_CLOEXEC | O_NONBLOCK) != 0) {
        __android_log_print(ANDROID_LOG_WARN, "factoria",
                            "platform: cannot create the end pipe (errno %d): the game's end will not run", errno);
        return;
    }
    if (ALooper_addFd(looper, fds[0], ALOOPER_POLL_CALLBACK, ALOOPER_EVENT_INPUT, on_wake, nullptr) != 1) {
        __android_log_print(ANDROID_LOG_WARN, "factoria",
                            "platform: the looper does not watch the end pipe: the game's end will not run");
        close(fds[0]);
        close(fds[1]);
        return;
    }
    g_wakeFd.store(fds[1], std::memory_order_release);
}

}  // namespace fa

extern "C" int fa_android_activity_ending(void) {
    const int fd = fa::g_wakeFd.load(std::memory_order_acquire);
    if (fd < 0) return 1;  // the engine never started (destroyed before its first surface): nothing to end
    int wakeError = 0;
    const auto outcome = fa::handshake().request(std::chrono::milliseconds(fa::kAndroidEndBudgetMs), [fd, &wakeError] {
        const char byte = 1;
        for (;;) {
            const ssize_t n = write(fd, &byte, 1);
            if (n == 1) return true;
            if (n < 0 && errno == EINTR) continue;
            if (n < 0 && errno == EAGAIN) return true;  // a full pipe: the loop thread has wake-ups to read already
            wakeError = n < 0 ? errno : EIO;
            return false;
        }
    });
    // These two lines go straight to the system log: the engine's log may be held by the loop thread that did not answer.
    switch (outcome) {
        case fa::EndHandshake::Outcome::Served: return 1;
        case fa::EndHandshake::Outcome::TimedOut:
            __android_log_print(ANDROID_LOG_WARN, "factoria",
                                "player: the game did not end within %d ms (a quit handler or a frame still runs); the "
                                "process ends anyway",
                                fa::kAndroidEndBudgetMs);
            return 0;
        case fa::EndHandshake::Outcome::NotDelivered:
            __android_log_print(
                ANDROID_LOG_WARN, "factoria",
                "player: cannot wake the game's thread (errno %d): the process ends without the game's end", wakeError);
            return 1;
    }
    return 1;
}
