// Structured logging.
//
// Every log line has a level, a category ("render", "script", "physics"...) and
// a message. Lines go to stderr (text or JSON-lines, see set_log_format) and to
// an in-memory ring buffer that tools read back: the editor console, the MCP
// `game_logs` tool and `factoria run --headless` reports. Thread-safe.
#pragma once

#include <cstdint>
#include <format>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

namespace fa {

enum class LogLevel : std::uint8_t { Trace, Debug, Info, Warn, Error };

const char* log_level_name(LogLevel level);                // "trace".."error"
bool parse_log_level(std::string_view name, LogLevel& out);  // case-insensitive

struct LogEntry {
    std::uint64_t seq = 0;    // monotonically increasing id
    double time = 0.0;        // seconds since process start
    std::uint64_t frame = 0;  // engine frame index when logged (0 before the loop starts)
    std::int64_t wallMs = 0;  // computer clock (system_clock) when logged: milliseconds since the Unix epoch
    LogLevel level = LogLevel::Info;
    std::string category;
    std::string message;
};

enum class LogFormat : std::uint8_t { Text, Json, None };

void log(LogLevel level, std::string_view category, std::string message);

// The local time of day of a wall-clock stamp: "14:03:22.517". A stamp of 0 (not set) gives "--:--:--.---".
std::string log_wall_time(std::int64_t wallMs);
// The same moment as ISO 8601 local time with the UTC offset: "2026-10-28T14:03:22.517+01:00" (the form of the
// `wallTime` field in JSON). Empty for a stamp of 0.
std::string log_wall_iso(std::int64_t wallMs);
// The current computer clock in the unit of LogEntry::wallMs.
std::int64_t log_wall_now_ms();

// One entry as the text format writes it, without the newline:
// "14:03:22.517 [  1.234] WARN  render: message" (local time, seconds since start, level, category).
std::string format_log_line(const LogEntry& entry);

void set_log_level(LogLevel minLevel);  // affects stderr sink + ring buffer
LogLevel log_level();
void set_log_format(LogFormat format);  // stderr format; Json = one object per line
void set_log_frame(std::uint64_t frame);  // engine updates this every frame

// Optional filter for the stderr sink only (sinks and the ring buffer are unaffected): return false to keep an entry
// off stderr. Pass an empty function to remove it. Used to capture a category (e.g. test output) without echoing it.
using LogFilter = std::function<bool(const LogEntry&)>;
void set_log_stderr_filter(LogFilter filter);
std::uint64_t log_last_seq();  // seq of the most recent entry that passed the level filter (0 = none yet)

// Extra sinks (editor console, files). Returns an id for remove_log_sink.
using LogSink = std::function<void(const LogEntry&)>;
int add_log_sink(LogSink sink);
void remove_log_sink(int id);

// Ring buffer (last 4096 entries). afterSeq lets pollers fetch only new lines.
std::vector<LogEntry> recent_logs(std::size_t maxCount = 200, LogLevel minLevel = LogLevel::Trace,
                                  std::uint64_t afterSeq = 0);
void clear_recent_logs();
std::size_t error_count();  // errors logged since start / last clear_recent_logs

}  // namespace fa

#define FA_LOG(level, category, ...) ::fa::log(level, category, std::format(__VA_ARGS__))
#define FA_TRACE(category, ...) FA_LOG(::fa::LogLevel::Trace, category, __VA_ARGS__)
#define FA_DEBUG(category, ...) FA_LOG(::fa::LogLevel::Debug, category, __VA_ARGS__)
#define FA_INFO(category, ...) FA_LOG(::fa::LogLevel::Info, category, __VA_ARGS__)
#define FA_WARN(category, ...) FA_LOG(::fa::LogLevel::Warn, category, __VA_ARGS__)
#define FA_ERROR(category, ...) FA_LOG(::fa::LogLevel::Error, category, __VA_ARGS__)
