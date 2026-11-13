// The last steps of a forked child before it becomes another program, shared by run_process (process_posix.cpp) and
// ChildProcess (child_process_posix.cpp). Everything here runs between fork and exec: only async-signal-safe calls
// (no malloc, no opendir, no locks).
#pragma once

#include <cerrno>
#include <ctime>

#include <unistd.h>
#ifdef __linux__
#include <sys/syscall.h>
#endif

namespace fa::detail {

// Closes every descriptor from 3 up except `keep` (the pipe that reports an exec error to the parent).
//
// O_CLOEXEC is not enough: Linux refuses to exec a file that any open file DESCRIPTION still has open for writing
// (ETXTBSY), and it checks that before the close-on-exec descriptors are closed. After fork the child owns a copy of the
// description of every file the parent's other threads have open, so a child that keeps them until its own exec can make
// another thread's freshly written program unstartable. Closing them here keeps that window as short as possible.
inline void close_inherited_descriptors(int keep) {
#if defined(__linux__) && defined(SYS_close_range)
    // One system call per range below and above `keep` (Linux 5.9+; an older kernel fails with ENOSYS: the loop below).
    const unsigned long last = 0xFFFFFFFFul;
    bool done = true;
    if (keep > 3) done = syscall(SYS_close_range, 3ul, static_cast<unsigned long>(keep - 1), 0ul) == 0;
    if (done) {
        const unsigned long from = keep >= 3 ? static_cast<unsigned long>(keep) + 1ul : 3ul;
        done = syscall(SYS_close_range, from, last, 0ul) == 0;
    }
    if (done) return;
#endif
    constexpr long kCap = 65536;  // a raised or unlimited descriptor limit must not turn this into millions of calls
    long maxFd = sysconf(_SC_OPEN_MAX);
    if (maxFd < 0 || maxFd > kCap) maxFd = kCap;
    for (int fd = 3; fd < maxFd; ++fd)
        if (fd != keep) close(fd);
}

// execv (a path with a slash) or execvp (looked up on PATH). Returns only when the exec failed, with errno set.
//
// A program that was written a moment ago can still be open for writing in another thread, or in another process's
// fork that has not reached its exec yet (ETXTBSY, "Text file busy"): retry with a doubling pause, 10 ms to 640 ms
// (about 1.3 s in all), because a loaded machine can delay the writer. nanosleep is async-signal-safe.
inline void exec_with_retry(bool hasSlash, char* const* argv) {
    long pauseMs = 10;
    for (int attempt = 0;; ++attempt) {
        if (hasSlash)
            execv(argv[0], argv);
        else
            execvp(argv[0], argv);
        if (errno != ETXTBSY || attempt == 7) return;  // 7 pauses: 10 + 20 + ... + 640 ms
        const int saved = errno;
        const struct timespec pause = {0, pauseMs * 1000 * 1000};
        nanosleep(&pause, nullptr);
        errno = saved;
        pauseMs *= 2;
    }
}

}  // namespace fa::detail
