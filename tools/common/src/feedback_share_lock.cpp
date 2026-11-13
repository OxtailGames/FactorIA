// The cross-process lock of the sharing files (fa/tooling/feedback_share.h, ShareLock): a lock file next to them, made with an
// exclusive create (O_EXCL on POSIX, CREATE_NEW on Windows), so only one process or thread holds it at a time. The file holds an
// owner token (process id + a random number): the holder deletes the file only while it still holds its own token, so a lock that
// was taken over from a holder that looked dead is never deleted under its new owner. A lock file that nobody refreshed (the holder
// crashed or was killed) is taken over once it is older than ShareEnv::lockStaleSec (or its time is that far in the future); the
// takeover itself is serialized with a second exclusive-create file, so two waiters never both take it over. The wait for a busy
// lock is bounded by ShareEnv::lockWaitSec, so nothing ever blocks for good.
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <limits>
#include <optional>
#include <string>
#include <system_error>
#include <thread>
#include <vector>

#include "fa/core/fs.h"
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

// The lock objects of this thread that own a lock file (the outermost one of each file): a function that holds a lock and calls
// another that takes the same file does not wait for itself, and ShareLock::keep_alive() refreshes all of them.
thread_local std::vector<ShareLock*> t_owners;
// The longest wait any lock of this thread may take (ShareWaitCap); the editor's UI thread lowers it around calls it cannot reroute.
thread_local double t_waitCap = std::numeric_limits<double>::infinity();

enum class Created { Yes, Exists, Denied, Failed };

// The system's own text of a Windows error code, as UTF-8 ("" when there is none). std::system_category().message() answers in the
// ANSI code page of the machine (not UTF-8: a Json dump of it can throw), so Windows asks for the UTF-16 text and converts it.
std::string system_error_message(unsigned long code) {
#if defined(_WIN32)
    wchar_t* wide = nullptr;
    const DWORD length =
        FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                       nullptr, static_cast<DWORD>(code), 0, reinterpret_cast<LPWSTR>(&wide), 0, nullptr);
    if (length == 0 || wide == nullptr) return {};
    std::string utf8;
    const int bytes = WideCharToMultiByte(CP_UTF8, 0, wide, static_cast<int>(length), nullptr, 0, nullptr, nullptr);
    if (bytes > 0) {
        utf8.resize(static_cast<std::size_t>(bytes));
        if (WideCharToMultiByte(CP_UTF8, 0, wide, static_cast<int>(length), utf8.data(), bytes, nullptr, nullptr) <= 0)
            utf8.clear();
    }
    LocalFree(wide);
    return utf8;
#else
    return std::system_category().message(static_cast<int>(code));
#endif
}

// "Windows error 5 (Access is denied.)": the number alone sends a person to a search engine.
std::string windows_error_text(unsigned long code) {
    std::string text = "Windows error " + std::to_string(code);
    try {
        std::string says = system_error_message(code);
        while (!says.empty() &&
               (says.back() == '\n' || says.back() == '\r' || says.back() == ' ' || says.back() == '.'))
            says.pop_back();
        if (!says.empty()) text += " (" + says + ")";
    } catch (...) {
    }
    return text;
}

unsigned long process_id() {
#if defined(_WIN32)
    return static_cast<unsigned long>(GetCurrentProcessId());
#else
    return static_cast<unsigned long>(::getpid());
#endif
}

// pid + random (not the world's rng: this is tooling, and a token must differ between processes).
std::string make_token() {
    std::string random;
    try {
        random = random_uuid_v4();
    } catch (...) {
        random = std::to_string(std::chrono::steady_clock::now().time_since_epoch().count());
    }
    return std::to_string(process_id()) + "-" + random;
}

// The text of a file (at most a few hundred bytes), "" when it cannot be read.
std::string read_small(const stdfs::path& file) {
    std::ifstream in(file, std::ios::binary);
    if (!in) return {};
    char buf[256];
    in.read(buf, sizeof buf);
    std::string text(buf, static_cast<std::size_t>(in.gcount()));
    while (!text.empty() && (text.back() == '\n' || text.back() == '\r')) text.pop_back();
    return text;
}

// Whose a lock file is. A file that exists but reads "" is not somebody else's: on Windows a virus scanner or another process that
// has just made it can hold it open for a moment (the read fails, or it is not written yet), so it is read again a few times; only
// another token ends the question, and a file that stays unreadable is `Unknown` (left alone, like another owner's).
enum class Owner { Gone, Ours, Other, Unknown };
Owner owner_of(const stdfs::path& file, const std::string& token, int tries = 20) {
    for (int i = 0; i < tries; ++i) {
        std::error_code ec;
        if (!stdfs::exists(file, ec)) return Owner::Gone;
        const std::string text = read_small(file);
        if (!text.empty()) return text == token ? Owner::Ours : Owner::Other;
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    return Owner::Unknown;
}

// Whether two lock files of this thread are the same file: the same text, the same path once `.`, `..` and symlinks are resolved, or
// (the file exists) the same file for the file system, which also settles another case on a volume that ignores it and NFC/NFD.
bool same_lock_file(const stdfs::path& a, const stdfs::path& b) {
    if (a == b) return true;
    std::error_code ec;
    if (stdfs::weakly_canonical(stdfs::absolute(a, ec), ec) == stdfs::weakly_canonical(stdfs::absolute(b, ec), ec) &&
        !ec)
        return true;
    ec.clear();
    return stdfs::equivalent(a, b, ec) && !ec;
}

// Creates `file` and writes `content` into it; it must not exist. For Failed `why` says why; for Denied `code` is the Windows error.
// Denied is Windows only: ERROR_ACCESS_DENIED on CREATE_NEW is what a file that is being deleted (delete pending) or held open by
// a virus scanner gives, but also what a folder without write permission gives.
Created create_exclusive(const stdfs::path& file, const std::string& content, std::string& why, int& code) {
#if defined(_WIN32)
    HANDLE h = CreateFileW(file.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) {
        const DWORD e = GetLastError();
        code = static_cast<int>(e);
        if (e == ERROR_FILE_EXISTS || e == ERROR_ALREADY_EXISTS || e == ERROR_SHARING_VIOLATION) return Created::Exists;
        if (e == ERROR_ACCESS_DENIED) return Created::Denied;
        why = windows_error_text(e);
        return Created::Failed;
    }
    DWORD written = 0;
    const BOOL wrote = WriteFile(h, content.data(), static_cast<DWORD>(content.size()), &written, nullptr);
    const DWORD writeError = GetLastError();
    CloseHandle(h);
    if (!wrote || written != content.size()) {
        std::error_code ec;
        stdfs::remove(file, ec);
        why = "the owner could not be written (" + windows_error_text(writeError) + ")";
        return Created::Failed;
    }
    return Created::Yes;
#else
    (void)code;
    const int fd = ::open(file.c_str(), O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0600);
    if (fd < 0) {
        if (errno == EEXIST) return Created::Exists;
        why = std::strerror(errno);
        return Created::Failed;
    }
    const ssize_t n = ::write(fd, content.data(), content.size());
    ::close(fd);
    if (n != static_cast<ssize_t>(content.size())) {
        std::error_code ec;
        stdfs::remove(file, ec);
        why = "the owner could not be written (" + std::string(std::strerror(errno)) + ")";
        return Created::Failed;
    }
    return Created::Yes;
#endif
}

// Whether files can be made in `dir` at all: told apart from "the lock file is busy" when Windows answers access denied.
bool folder_is_writable(const stdfs::path& dir, const std::string& lockName, const std::string& token,
                        std::string& why) {
    const stdfs::path probe = dir / (lockName + ".probe." + token);
    int code = 0;
    const Created c = create_exclusive(probe, token, why, code);
    if (c == Created::Yes) {
        std::error_code ec;
        stdfs::remove(probe, ec);
        return true;
    }
    if (why.empty()) why = "access denied (" + windows_error_text(static_cast<unsigned long>(code)) + ")";
    return false;
}

// How long ago the file was last written (negative when its time is in the future); nullopt when it cannot be read.
std::optional<double> file_age_sec(const stdfs::path& file) {
    std::error_code ec;
    const auto written = stdfs::last_write_time(file, ec);
    if (ec) return std::nullopt;
    const auto age = stdfs::file_time_type::clock::now() - written;
    return std::chrono::duration<double>(age).count();
}

// A file that nobody refreshed for `staleSec`, or whose time is further than that in the future (a clock that was set back, another
// machine's clock on a shared folder): the holder is gone, or the time cannot be trusted either way.
bool is_stale(const stdfs::path& file, double staleSec) {
    const std::optional<double> age = file_age_sec(file);
    return age && (*age > staleSec || *age < -staleSec);
}

void remove_with_retries(const stdfs::path& file) {
    for (int i = 0; i < 20; ++i) {
        std::error_code ec;
        stdfs::remove(file, ec);
        if (!ec) return;
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
}

std::string text_of(const stdfs::path& p);

// Removes what an earlier takeover or probe left behind (a process died, or Windows could not delete a file at once).
void remove_leftovers(const stdfs::path& dir, const std::string& base, double staleSec) {
    try {
        const stdfs::path::string_type prefixes[] = {stdfs::path(base + ".stale.").native(),
                                                     stdfs::path(base + ".probe.").native(),
                                                     stdfs::path(base + ".dead.").native()};
        std::error_code ec;
        stdfs::directory_iterator it(dir, ec), end;
        while (!ec && it != end) {
            const stdfs::path p = it->path();
            const stdfs::path::string_type name = p.filename().native();
            bool leftover = false;
            for (const stdfs::path::string_type& prefix : prefixes)
                if (name.compare(0, prefix.size(), prefix) == 0) leftover = true;
            if (leftover && is_stale(p, staleSec)) {
                std::error_code rc;
                stdfs::remove(p, rc);
            }
            it.increment(ec);
        }
    } catch (...) {
    }
}

// Takes over a lock file that looks stale. Only one waiter at a time gets past the ".takeover" file, and it looks again inside:
// a lock another waiter just made (fresh) is left alone. True when the stale file was moved away and the caller may try to create
// the lock again at once; false when somebody else is taking over, or the lock is not stale after all.
bool take_over_stale(const stdfs::path& lockFile, const stdfs::path& takeoverFile, const std::string& token,
                     double staleSec) {
    std::string why;
    int code = 0;
    const Created c = create_exclusive(takeoverFile, token, why, code);
    if (c != Created::Yes) {
        // A takeover that nobody finished (its process died) must not stop every other takeover for good.
        if (c == Created::Exists && is_stale(takeoverFile, staleSec)) {
            const stdfs::path aside{takeoverFile.native() + stdfs::path(".dead." + token).native()};
            std::error_code rc;
            stdfs::rename(takeoverFile, aside, rc);
            if (!rc) remove_with_retries(aside);
        }
        return false;
    }
    bool movedAway = false;
    if (is_stale(lockFile, staleSec)) {
        // Moved aside with an atomic rename (the name is free at once, even where Windows cannot delete the file yet).
        const stdfs::path aside{lockFile.native() + stdfs::path(".stale." + token).native()};
        std::error_code rc;
        stdfs::rename(lockFile, aside, rc);
        movedAway = !rc;
        if (movedAway && !is_stale(aside, staleSec)) {
            // Between the look above and the rename the holder finished and somebody made a fresh lock (or the holder refreshed it):
            // what was moved is alive. Put it back if the name is still free; the window between look and rename is microseconds,
            // not zero, which is why the lock is documented as "one holder at a time except for that window".
            std::error_code back;
            if (!stdfs::exists(lockFile, back)) stdfs::rename(aside, lockFile, back);
            if (back || stdfs::exists(aside, back)) remove_with_retries(aside);
            movedAway = false;
        } else if (movedAway) {
            remove_with_retries(aside);
        }
    }
    remove_with_retries(takeoverFile);
    if (movedAway) remove_leftovers(lockFile.parent_path(), text_of(lockFile.filename()), staleSec);
    return movedAway;
}

std::string seconds_text(double s) {
    char buf[32];
    std::snprintf(buf, sizeof buf, "%.1f", s);
    return buf;
}

std::string text_of(const stdfs::path& p) {
    try {
        const std::u8string u = p.u8string();
        return std::string(reinterpret_cast<const char*>(u.data()), u.size());
    } catch (...) {
        return "feedback-share.lock";
    }
}

}  // namespace

ShareWaitCap::ShareWaitCap(double sec) : previous_(t_waitCap) { t_waitCap = std::min(t_waitCap, sec); }
ShareWaitCap::~ShareWaitCap() { t_waitCap = previous_; }

ShareLock::ShareLock(const ShareEnv& env) : name_(kFeedbackShareLockFile) {
    init(env, stdfs::path(env.config_dir()), -1);
}

ShareLock::ShareLock(const ShareEnv& env, const stdfs::path& folder, double reportedWaitSec,
                     std::string_view lockFileName)
    : name_(lockFileName) {
    init(env, folder, reportedWaitSec);
}

void ShareLock::init(const ShareEnv& env, const stdfs::path& folder, double reportedWaitSec) {
    try {
        file_ = folder / name_;
        for (const ShareLock* owner : t_owners) {
            if (same_lock_file(owner->file_,
                               file_)) {  // this thread holds it already (under whatever spelling of the folder)
                held_ = true;
                nested_ = true;
                path_ = owner->path_;
                return;
            }
        }
        acquire(env, folder, reportedWaitSec);
    } catch (const std::exception& e) {
        held_ = false;
        error_ = std::string("Cannot take the lock of the sharing files (") + e.what() + "), so nothing was changed.";
    } catch (...) {
        held_ = false;
        error_ = "Cannot take the lock of the sharing files, so nothing was changed.";
    }
}

void ShareLock::acquire(const ShareEnv& env, const stdfs::path& dir, double reportedWaitSec) {
    std::error_code ec;
    stdfs::create_directories(dir, ec);
    file_ = dir / name_;
    path_ = text_of(file_);
    staleSec_ = env.lockStaleSec;
    token_ = make_token();
    const stdfs::path takeoverFile = dir / (name_ + ".takeover");
    const double waitSec = std::min(env.lockWaitSec, t_waitCap);
    const auto deadline =
        std::chrono::steady_clock::now() +
        std::chrono::duration_cast<std::chrono::steady_clock::duration>(std::chrono::duration<double>(waitSec));
    int takeovers = 0, deniedCode = 0;
    bool probed = false;
    for (;;) {
        std::string why;
        int code = 0;
        const Created c = create_exclusive(file_, token_, why, code);
        if (c == Created::Yes) {
            held_ = true;
            t_owners.push_back(this);
            return;
        }
        if (c == Created::Failed) {
            unwritable_ = true;
            error_ = "Cannot create the lock file " + path_ + " (" + why +
                     "), so the sharing files were not changed. "
                     "Check the permissions of that folder.";
            return;
        }
        if (c == Created::Denied) {
            // Windows: access denied is what a lock file that is being deleted, or that a virus scanner holds open, answers: it
            // is busy until it goes away. A folder that cannot be written at all answers the same, so that is told apart by
            // making a file of another name, once: that case fails at once instead of after the whole wait.
            deniedCode = code;
            if (!probed) {
                probed = true;
                std::string probeWhy;
                if (!folder_is_writable(dir, name_, token_, probeWhy)) {
                    unwritable_ = true;
                    error_ = "Cannot create files in " + text_of(dir) + " (" + probeWhy +
                             "), so the sharing files were not changed. "
                             "Check the permissions of that folder.";
                    return;
                }
            }
        }
        // Busy. A lock file nobody refreshed (its process died) is taken over, one waiter at a time.
        if (takeovers < 20 && is_stale(file_, env.lockStaleSec)) {
            if (take_over_stale(file_, takeoverFile, token_, env.lockStaleSec)) {
                ++takeovers;
                continue;
            }
        }
        if (std::chrono::steady_clock::now() >= deadline) {
            error_ = "Another FactorIA process is changing the sharing files and did not finish in " +
                     seconds_text(reportedWaitSec >= 0 ? reportedWaitSec : waitSec) + " s (lock file " + path_ +
                     "), so nothing was changed. "
                     "Try again; if no FactorIA program is running, delete that file.";
            if (deniedCode != 0)
                error_ += " (Windows answered \"access denied\", " +
                          windows_error_text(static_cast<unsigned long>(deniedCode)) +
                          ", when the lock was made: a virus scanner or a delete in progress may be holding the file.)";
            return;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
}

ShareLock::~ShareLock() {
    if (!held_) return;
    if (nested_) return;
    t_owners.erase(std::remove(t_owners.begin(), t_owners.end(), this), t_owners.end());
    try {
        // Only a lock that still carries our token is ours to delete: one that was taken over (this process looked dead for longer
        // than the stale time) belongs to its new owner now. On Windows a virus scanner may hold the file for a moment: retry. A
        // lock that stays is taken over after lockStaleSec.
        for (int i = 0; i < 20; ++i) {
            if (owner_of(file_, token_) != Owner::Ours)
                return;  // gone, somebody else's, or unreadable for good: leave it
            std::error_code ec;
            stdfs::remove(file_, ec);
            if (!ec) return;
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    } catch (...) {
    }
}

FeedbackFileLock::FeedbackFileLock(const ShareEnv& env, const std::string& feedbackPath, bool projectOnly) {
    // The path is converted the way load_feedback / save_feedback open it (std::filesystem::path from the narrow text: the ANSI code
    // page on Windows, as the CLI and the editor pass it), so the lock lands in the folder of the file it protects whatever the
    // folder is called. A path with no folder part is the working directory.
    stdfs::path parent;
    try {
        parent = stdfs::path(feedbackPath).parent_path();
        if (parent.empty()) parent = stdfs::path(".");
    } catch (const std::exception& e) {
        error_ = std::string("Cannot work out the project's lock folder from ") + feedbackPath + " (" + e.what() +
                 "), so nothing was changed.";
        return;
    }
    // A folder that does not exist holds no file to protect, and a lock must not make the folder (nor `.factoria` in it): nothing is
    // taken, and the caller's own read or write says what is wrong with the path.
    std::error_code existsEc;
    if (!stdfs::is_directory(fs::os_path(parent), existsEc)) {
        noFolder_ = true;
        return;
    }
    // One wait for both locks: the second only waits for what is left of it.
    const double totalSec = std::min(env.lockWaitSec, t_waitCap);
    const auto start = std::chrono::steady_clock::now();
    // Order: the user's folder first, then the project's. Every process takes them in this order (a process that cannot write the
    // user's folder takes only the project's), so none waits for a lock another one holds while holding the lock that one wants.
    std::string userError;
    if (!projectOnly) {
        user_ = std::make_unique<ShareLock>(env);
        if (!user_->held()) {
            if (!user_->unwritable()) {  // busy: nothing was changed
                error_ = user_->error();
                user_.reset();
                return;
            }
            userError = user_->error();  // a read-only or missing home, a sandbox: the project's lock alone then
            user_.reset();
        }
    }
    try {
        ShareEnv rest = env;
        rest.lockWaitSec =
            std::max(0.0, totalSec - std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count());
        local_ = std::make_unique<ShareLock>(rest, parent / ".factoria", totalSec);
    } catch (const std::exception& e) {
        error_ = std::string("Cannot take the project's lock next to ") + feedbackPath + " (" + e.what() +
                 "), so nothing was changed.";
        user_.reset();
        return;
    }
    if (local_->held()) return;
    if (projectOnly && local_->unwritable()) {
        // The caller wanted only the project's lock, but that folder cannot hold one: the user's lock is the fallback, as for any writer.
        const std::string localError = local_->error();
        local_.reset();
        ShareEnv left = env;
        left.lockWaitSec =
            std::max(0.0, totalSec - std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count());
        user_ = std::make_unique<ShareLock>(left, stdfs::path(env.config_dir()), totalSec);
        if (user_->held()) return;
        error_ = user_->unwritable() ? localError + " The user's folder did not work either: " + user_->error()
                                     : user_->error();
        user_.reset();
        return;
    }
    if (user_ && local_->unwritable()) {
        // The user's lock is held and the project's folder cannot hold one: the processes that can write the user's folder are
        // excluded by it (the others cannot reach this file's folder either).
        local_.reset();
        return;
    }
    // Both folders unwritable: say both. Home unwritable and the project's lock only busy (or the other way round): say only what is true.
    if (!userError.empty() && local_->unwritable())
        error_ = userError + " The project's own folder did not work either: " + local_->error();
    else
        error_ = local_->error();
    local_.reset();
    user_.reset();
}

bool FeedbackFileLock::held() const { return noFolder_ || (user_ && user_->held()) || (local_ && local_->held()); }

FeedbackFileLock::~FeedbackFileLock() {
    // Reverse of the order they were taken in.
    local_.reset();
    user_.reset();
}

void ShareLock::keep_alive() {
    for (ShareLock* owner : t_owners) owner->refresh();
}

void ShareLock::refresh() {
    try {
        // The time of the file is what other processes judge by: a long change (many entries written) must not let a live holder
        // look dead. Only when a quarter of the stale time has passed, and only while the file is still ours.
        const std::optional<double> age = file_age_sec(file_);
        if (age && *age >= 0 && *age < staleSec_ / 4) return;
        if (owner_of(file_, token_, 3) != Owner::Ours) return;  // (a UI thread calls this: a short retry)
        std::error_code ec;
        stdfs::last_write_time(file_, stdfs::file_time_type::clock::now(), ec);
    } catch (...) {
    }
}

}  // namespace fa
