// The cross-process lock of the sharing files (fa/tooling/feedback_share.h, ShareLock): a lock file next to them, made with an
// exclusive create (O_EXCL on POSIX, CREATE_NEW on Windows), so only one process or thread holds it at a time. A lock file
// that nobody removed (the holder crashed or was killed) is taken over once it is older than ShareEnv::lockStaleSec; the wait
// for a busy lock is bounded by ShareEnv::lockWaitSec, so nothing ever blocks for good.
#include <chrono>
#include <cstdio>
#include <filesystem>
#include <string>
#include <system_error>
#include <thread>

#include "fa/tooling/feedback_share.h"

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#else
#include <fcntl.h>
#include <unistd.h>

#include <cerrno>
#include <cstring>
#endif

namespace fa {

namespace stdfs = std::filesystem;

namespace {

// Locks taken by this thread: a function that holds the lock and calls another that also takes it does not wait for itself.
thread_local int t_depth = 0;

enum class Created { Yes, Exists, Failed };

// Creates the lock file and writes the pid into it (for a person who finds it). `why` is filled for Failed.
Created create_lock_file(const stdfs::path& path, std::string& why) {
#if defined(_WIN32)
    HANDLE h = CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) {
        const DWORD e = GetLastError();
        // A lock file that is being deleted (DELETE pending) or held open by a scanner also reads as busy.
        if (e == ERROR_FILE_EXISTS || e == ERROR_ALREADY_EXISTS || e == ERROR_SHARING_VIOLATION || e == ERROR_ACCESS_DENIED) {
            std::error_code ec;
            if (e != ERROR_ACCESS_DENIED || stdfs::exists(path, ec)) return Created::Exists;
        }
        why = "Windows error " + std::to_string(e);
        return Created::Failed;
    }
    const std::string text = std::to_string(GetCurrentProcessId()) + "\n";
    DWORD written = 0;
    (void)WriteFile(h, text.data(), static_cast<DWORD>(text.size()), &written, nullptr);
    CloseHandle(h);
    return Created::Yes;
#else
    const int fd = ::open(path.c_str(), O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0600);
    if (fd < 0) {
        if (errno == EEXIST) return Created::Exists;
        why = std::strerror(errno);
        return Created::Failed;
    }
    const std::string text = std::to_string(static_cast<long>(::getpid())) + "\n";
    const ssize_t n = ::write(fd, text.data(), text.size());
    (void)n;
    ::close(fd);
    return Created::Yes;
#endif
}

// How long ago the lock file was last written; negative (never stale) when it cannot be read or its time is in the future
// (another machine's clock on a shared folder).
double lock_age_sec(const stdfs::path& path) {
    std::error_code ec;
    const auto written = stdfs::last_write_time(path, ec);
    if (ec) return -1.0;
    const auto age = stdfs::file_time_type::clock::now() - written;
    return std::chrono::duration<double>(age).count();
}

}  // namespace

ShareLock::ShareLock(const ShareEnv& env) {
    if (t_depth > 0) {  // this thread holds it already
        ++t_depth;
        held_ = true;
        nested_ = true;
        return;
    }
    const stdfs::path dir = env.config_dir();
    std::error_code ec;
    stdfs::create_directories(dir, ec);
    path_ = (dir / kFeedbackShareLockFile).string();
    const stdfs::path path(path_);
    const auto start = std::chrono::steady_clock::now();
    const auto deadline = start + std::chrono::duration_cast<std::chrono::steady_clock::duration>(std::chrono::duration<double>(env.lockWaitSec));
    int takeovers = 0;
    for (;;) {
        std::string why;
        const Created c = create_lock_file(path, why);
        if (c == Created::Yes) {
            held_ = true;
            ++t_depth;
            return;
        }
        if (c == Created::Failed) {
            error_ = "Cannot create the lock file " + path_ + " (" + why + "), so the sharing files were not changed. "
                     "Check the permissions of that folder.";
            return;
        }
        // Busy. A lock file nobody released (its process died) is older than the stale time: take it over.
        if (lock_age_sec(path) > env.lockStaleSec && takeovers < 50) {
            ++takeovers;
            // Move it aside first (an atomic rename), so two waiters that both found it stale do not both delete a lock that a
            // third one just made.
            const stdfs::path aside = path_ + ".stale." + std::to_string(takeovers) + "." +
                                      std::to_string(std::chrono::steady_clock::now().time_since_epoch().count());
            std::error_code rc;
            if (lock_age_sec(path) > env.lockStaleSec) stdfs::rename(path, aside, rc);
            if (!rc) stdfs::remove(aside, rc);
            continue;
        }
        if (std::chrono::steady_clock::now() >= deadline) {
            error_ = "Another FactorIA process is changing the sharing files and did not finish in " +
                     std::to_string(static_cast<int>(env.lockWaitSec)) + " s (lock file " + path_ + "), so nothing was changed. "
                     "Try again; if no FactorIA program is running, delete that file.";
            return;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
}

ShareLock::~ShareLock() {
    if (!held_) return;
    --t_depth;
    if (nested_) return;
    // On Windows a virus scanner may hold the file for a moment: retry. A lock that stays is taken over after lockStaleSec.
    for (int i = 0; i < 20; ++i) {
        std::error_code ec;
        stdfs::remove(stdfs::path(path_), ec);
        if (!ec) return;
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
}

}  // namespace fa
