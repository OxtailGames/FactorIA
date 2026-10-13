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
    LogLevel level = LogLevel::Info;
    std::string category;
    std::string message;
};

enum class LogFormat : std::uint8_t { Text, Json, None };

void log(LogLevel level, std::string_view category, std::string message);

void set_log_level(LogLevel minLevel);  // affects stderr sink + ring buffer
LogLevel log_level();
void set_log_format(LogFormat format);  // stderr format; Json = one object per line
void set_log_frame(std::uint64_t frame);  // engine updates this every frame

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
