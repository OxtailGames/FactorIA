// Crash reports, the part that runs in a healthy process: options, the report header, the ring of recent log lines,
// pruning old reports, "did the previous run crash?". The handlers themselves are crash_posix.cpp / crash_win32.cpp.
#include "fa/core/crash.h"

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <fstream>
#include <functional>
#include <mutex>

#include "crash_internal.h"
#include "fa/core/log.h"

namespace fa {
namespace crash_detail {

Shared g_shared;

}  // namespace crash_detail

namespace {

namespace stdfs = std::filesystem;
using crash_detail::g_shared;

bool is_report_name(const std::string& name, const char* extension) {
    return name.rfind("crash-", 0) == 0 && name.size() > 6 && stdfs::path(name).extension() == extension;
}

// Keeps the `keep` newest reports (a report = the .txt and the .dmp of one stem; the stem sorts by time).
void prune_reports(const stdfs::path& dir, std::size_t keep) {
    std::error_code ec;
    std::vector<std::string> stems;
    for (stdfs::directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        if (is_report_name(name, ".txt") || is_report_name(name, ".dmp")) stems.push_back(it->path().stem().string());
    }
    std::sort(stems.begin(), stems.end(), std::greater<>());
    stems.erase(std::unique(stems.begin(), stems.end()), stems.end());
    for (std::size_t i = keep; i < stems.size(); ++i) {
        stdfs::remove(dir / (stems[i] + ".txt"), ec);
        stdfs::remove(dir / (stems[i] + ".dmp"), ec);
    }
}

// The log sink: the latest lines, kept in static storage the handler reads without a lock. A line written at the very
// moment of the crash by another thread can come out cut; that is all the race can do.
std::mutex g_ringMutex;

void remember_log_line(const LogEntry& entry) {
    const std::string line = format_log_line(entry);
    std::lock_guard<std::mutex> lock(g_ringMutex);
    const std::uint32_t at = g_shared.logCount.load(std::memory_order_relaxed);
    char* slot = g_shared.logLines[at % crash_detail::kLogLines];
    const std::size_t n = std::min(line.size(), crash_detail::kLogLineBytes - 1);
    std::memcpy(slot, line.data(), n);
    slot[n] = '\0';
    g_shared.logCount.store(at + 1, std::memory_order_release);
}

// An exception nobody caught ends in std::terminate -> abort(). Keep what() for the report (the stack of a terminate
// only shows where it was called, not what was thrown), then do what the default handler does.
void on_terminate() {
    const char* text = "std::terminate() was called";
    std::string what;
    if (std::current_exception()) {
        try {
            throw;
        } catch (const std::exception& e) {
            what = std::string("uncaught exception: ") + e.what();
        } catch (...) {
            what = "uncaught exception of an unknown type";
        }
        text = what.c_str();
    }
    std::snprintf(g_shared.terminateMessage, sizeof g_shared.terminateMessage, "%s", text);
    std::fprintf(stderr, "%s\n", text);
    std::abort();
}

}  // namespace

Result<void> install_crash_reporter(const CrashReporterOptions& options) {
    namespace cd = crash_detail;
    if (options.dir.empty())
        return Error{"install_crash_reporter: no folder to write the reports into",
                     "set CrashReporterOptions::dir, e.g. <save folder>/crashes"};
    std::error_code ec;
    stdfs::create_directories(options.dir, ec);
    if (ec || !stdfs::is_directory(options.dir, ec))
        return Error{"cannot create the crash report folder '" + options.dir.string() + "'" +
                         (ec ? ": " + ec.message() : std::string()),
                     "pick a writable folder (the player uses <save folder>/crashes)"};
    prune_reports(options.dir, options.keep);

    std::string header = std::string("FactorIA crash report\nengine: ") + FA_ENGINE_VERSION + " (" + FA_PLATFORM_NAME + ")\n";
    for (const std::string& line : options.info) header += line + '\n';
    std::snprintf(g_shared.header, cd::kHeaderBytes, "%s", header.c_str());  // cut when longer: still a header

    std::string error;
    if (!cd::platform_install(stdfs::absolute(options.dir, ec), error))  // absolute: the game may change directory later
        return Error{error, "mobile systems keep their own crash logs (adb logcat and tombstones on Android, Xcode "
                            "Organizer on iOS): do not install the reporter there"};

    static std::once_flag once;
    std::call_once(once, [] {
        add_log_sink(remember_log_line);
        std::set_terminate(on_terminate);
    });
    return {};
}

std::filesystem::path take_previous_crash_report(const std::filesystem::path& dir) {
    std::error_code ec;
    std::string newest;
    for (stdfs::directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        if (is_report_name(name, ".txt") && name > newest) newest = name;
    }
    if (newest.empty()) return {};
    const stdfs::path marker = dir / ".reported";
    std::string reported;
    std::ifstream(marker, std::ios::binary) >> reported;  // a missing file leaves it empty
    if (reported >= newest) return {};
    std::ofstream(marker, std::ios::binary | std::ios::trunc) << newest << '\n';
    return dir / newest;
}

}  // namespace fa
