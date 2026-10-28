#include "fa/core/log.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <deque>
#include <map>
#include <mutex>

#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/core/types.h"

#ifdef __ANDROID__
#include <android/log.h>
#endif
#ifdef __EMSCRIPTEN__
#include <emscripten/console.h>
#endif

namespace fa {
namespace {

constexpr std::size_t kRingSize = 4096;

struct LogState {
    std::mutex mutex;
    std::deque<LogEntry> ring;
    std::map<int, LogSink> sinks;
    int nextSink = 1;
    std::uint64_t nextSeq = 1;
    std::uint64_t frame = 0;
    LogLevel minLevel = LogLevel::Info;
    LogFormat format = LogFormat::Text;
    LogFilter stderrFilter;
    std::size_t errors = 0;
    std::chrono::steady_clock::time_point start = std::chrono::steady_clock::now();
};

LogState& state() {
    static LogState s;
    return s;
}

const char* padded_level(LogLevel l) {
    switch (l) {
        case LogLevel::Trace: return "TRACE";
        case LogLevel::Debug: return "DEBUG";
        case LogLevel::Info: return "INFO ";
        case LogLevel::Warn: return "WARN ";
        case LogLevel::Error: return "ERROR";
    }
    return "?????";
}

void write_stderr(const LogEntry& e, LogFormat format) {
    if (format == LogFormat::None) return;
    std::string line;
    if (format == LogFormat::Json) {
        Json j = {{"t", std::round(e.time * 1000.0) / 1000.0},
                  {"level", log_level_name(e.level)},
                  {"cat", e.category},
                  {"msg", e.message},
                  {"frame", e.frame},
                  {"wallTime", log_wall_iso(e.wallMs)}};
        line = j.dump(-1, ' ', false, Json::error_handler_t::replace);
    } else {
        line = format_log_line(e);
    }
#ifdef __EMSCRIPTEN__
    // The browser console, by level (stderr would show every line as an error there).
    if (e.level == LogLevel::Error) emscripten_console_error(line.c_str());
    else if (e.level == LogLevel::Warn) emscripten_console_warn(line.c_str());
    else emscripten_console_log(line.c_str());
    return;
#endif
    line += '\n';
    std::fwrite(line.data(), 1, line.size(), stderr);
    std::fflush(stderr);
#ifdef __ANDROID__
    int prio = e.level == LogLevel::Error ? ANDROID_LOG_ERROR
             : e.level == LogLevel::Warn ? ANDROID_LOG_WARN
             : e.level == LogLevel::Info ? ANDROID_LOG_INFO : ANDROID_LOG_DEBUG;
    __android_log_print(prio, "factoria", "%s: %s", e.category.c_str(), e.message.c_str());
#endif
}

}  // namespace

std::int64_t log_wall_now_ms() {
    using namespace std::chrono;
    return duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
}

namespace {
std::tm local_tm(std::int64_t wallMs) {
    std::time_t secs = std::time_t(wallMs >= 0 ? wallMs / 1000 : -((-wallMs + 999) / 1000));
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &secs);
#else
    localtime_r(&secs, &tm);
#endif
    return tm;
}
int ms_part(std::int64_t wallMs) { return int(((wallMs % 1000) + 1000) % 1000); }
}  // namespace

std::string log_wall_time(std::int64_t wallMs) {
    if (wallMs == 0) return "--:--:--.---";
    std::tm tm = local_tm(wallMs);
    char buf[32];
    std::snprintf(buf, sizeof buf, "%02d:%02d:%02d.%03d", tm.tm_hour, tm.tm_min, tm.tm_sec, ms_part(wallMs));
    return buf;
}

std::string log_wall_iso(std::int64_t wallMs) {
    if (wallMs == 0) return {};
    std::tm tm = local_tm(wallMs);
    char zone[16] = "+00:00";
    char off[16];
    if (std::strftime(off, sizeof off, "%z", &tm) == 5)  // "+0100"
        std::snprintf(zone, sizeof zone, "%c%c%c:%c%c", off[0], off[1], off[2], off[3], off[4]);
    char buf[64];
    std::snprintf(buf, sizeof buf, "%04d-%02d-%02dT%02d:%02d:%02d.%03d%s", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday,
                  tm.tm_hour, tm.tm_min, tm.tm_sec, ms_part(wallMs), zone);
    return buf;
}

std::string format_log_line(const LogEntry& e) {
    char head[128];
    std::snprintf(head, sizeof head, "%s [%7.3f] %s %s: ", log_wall_time(e.wallMs).c_str(), e.time, padded_level(e.level),
                  e.category.c_str());
    return head + e.message;
}

const char* log_level_name(LogLevel level) {
    switch (level) {
        case LogLevel::Trace: return "trace";
        case LogLevel::Debug: return "debug";
        case LogLevel::Info: return "info";
        case LogLevel::Warn: return "warn";
        case LogLevel::Error: return "error";
    }
    return "info";
}

bool parse_log_level(std::string_view name, LogLevel& out) {
    std::string n = to_lower(trim(name));
    for (LogLevel l : {LogLevel::Trace, LogLevel::Debug, LogLevel::Info, LogLevel::Warn, LogLevel::Error}) {
        if (n == log_level_name(l)) { out = l; return true; }
    }
    if (n == "warning") { out = LogLevel::Warn; return true; }
    return false;
}

void log(LogLevel level, std::string_view category, std::string message) {
    LogState& s = state();
    std::vector<LogSink> sinks;
    LogEntry entry;
    LogFormat format;
    {
        std::lock_guard<std::mutex> lock(s.mutex);
        if (level < s.minLevel) return;
        entry.seq = s.nextSeq++;
        entry.time = std::chrono::duration<double>(std::chrono::steady_clock::now() - s.start).count();
        entry.frame = s.frame;
        entry.wallMs = log_wall_now_ms();
        entry.level = level;
        entry.category = std::string(category);
        entry.message = std::move(message);
        if (level == LogLevel::Error) ++s.errors;
        s.ring.push_back(entry);
        if (s.ring.size() > kRingSize) s.ring.pop_front();
        for (auto& [id, sink] : s.sinks) sinks.push_back(sink);
        format = s.format;
        if (!s.stderrFilter || s.stderrFilter(entry)) write_stderr(entry, format);  // under the lock so lines never interleave
    }
    // Sinks run outside the lock so they may call log() themselves.
    for (auto& sink : sinks) sink(entry);
}

void set_log_level(LogLevel minLevel) {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().minLevel = minLevel;
}
LogLevel log_level() {
    std::lock_guard<std::mutex> lock(state().mutex);
    return state().minLevel;
}
void set_log_format(LogFormat format) {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().format = format;
}
void set_log_stderr_filter(LogFilter filter) {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().stderrFilter = std::move(filter);
}
std::uint64_t log_last_seq() {
    std::lock_guard<std::mutex> lock(state().mutex);
    return state().nextSeq - 1;
}
void set_log_frame(std::uint64_t frame) {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().frame = frame;
}

int add_log_sink(LogSink sink) {
    std::lock_guard<std::mutex> lock(state().mutex);
    int id = state().nextSink++;
    state().sinks[id] = std::move(sink);
    return id;
}
void remove_log_sink(int id) {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().sinks.erase(id);
}

std::vector<LogEntry> recent_logs(std::size_t maxCount, LogLevel minLevel, std::uint64_t afterSeq) {
    LogState& s = state();
    std::lock_guard<std::mutex> lock(s.mutex);
    std::vector<LogEntry> out;
    // Walk backwards so we keep the NEWEST maxCount matches, then restore order.
    for (auto it = s.ring.rbegin(); it != s.ring.rend() && out.size() < maxCount; ++it) {
        if (it->seq <= afterSeq) break;
        if (it->level >= minLevel) out.push_back(*it);
    }
    std::reverse(out.begin(), out.end());
    return out;
}

void clear_recent_logs() {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().ring.clear();
    state().errors = 0;
}

std::size_t error_count() {
    std::lock_guard<std::mutex> lock(state().mutex);
    return state().errors;
}

namespace detail {
[[noreturn]] void assert_fail(const char* cond, const char* msg, const char* file, int line) {
    std::string text = std::format("Assertion failed: {} -- {} ({}:{})", cond, msg, file, line);
    // Log first so sinks (and the ring buffer) see it, then print directly in case the log level hides errors.
    log(LogLevel::Error, "assert", text);
#ifdef __EMSCRIPTEN__
    emscripten_console_error(text.c_str());
#endif
    std::fprintf(stderr, "%s\n", text.c_str());
    std::fflush(stderr);
    std::abort();
}
}  // namespace detail

}  // namespace fa
