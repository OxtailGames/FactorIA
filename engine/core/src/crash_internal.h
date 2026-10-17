// Private to crash*.cpp: what the platform handlers (crash_posix.cpp, crash_win32.cpp) share with crash.cpp.
//
// A crash handler may not allocate, take a lock or call printf, so everything it reads is filled in at install time into
// static storage, and everything it formats goes through LineBuf (plain loops, no libc).
#pragma once

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <string>

namespace fa::crash_detail {

constexpr std::size_t kLogLines = 48;
constexpr std::size_t kLogLineBytes = 320;
constexpr std::size_t kHeaderBytes = 2048;
constexpr std::size_t kMessageBytes = 400;

struct Shared {
    char header[kHeaderBytes];                // "FactorIA crash report\nengine: ...\n<info lines>", NUL-terminated
    char logLines[kLogLines][kLogLineBytes];  // the newest log lines, a ring; a log sink fills it
    std::atomic<std::uint32_t> logCount;      // lines ever stored (line i is at logLines[i % kLogLines])
    char terminateMessage[kMessageBytes];     // what() of the exception that reached std::terminate, else ""
};
extern Shared g_shared;

// Platform half of install_crash_reporter: copies what it needs from `dir`, installs the handlers. False + `error`
// (what is wrong) when the platform cannot.
bool platform_install(const std::filesystem::path& dir, std::string& error);

// ---- formatting without the C library ----------------------------------------------------------------------------

struct Civil {
    int year, month, day, hour, minute, second;
};

// UTC calendar time of a Unix time (Howard Hinnant's civil_from_days).
inline Civil civil_from_unix(std::int64_t t) {
    std::int64_t days = t / 86400;
    std::int64_t rem = t % 86400;
    if (rem < 0) {
        rem += 86400;
        --days;
    }
    days += 719468;
    const std::int64_t era = (days >= 0 ? days : days - 146096) / 146097;
    const std::int64_t doe = days - era * 146097;
    const std::int64_t yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    const std::int64_t doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    const std::int64_t mp = (5 * doy + 2) / 153;
    const std::int64_t day = doy - (153 * mp + 2) / 5 + 1;
    const std::int64_t month = mp < 10 ? mp + 3 : mp - 9;
    const std::int64_t year = yoe + era * 400 + (month <= 2 ? 1 : 0);
    return {int(year), int(month), int(day), int(rem / 3600), int(rem % 3600 / 60), int(rem % 60)};
}

inline std::size_t c_length(const char* s) {
    std::size_t n = 0;
    while (s[n]) ++n;
    return n;
}

// A line being built on the stack; text that does not fit is cut.
struct LineBuf {
    char data[1024];
    std::size_t n = 0;

    void clear() { n = 0; }
    void chr(char c) {
        if (n + 1 < sizeof data) data[n++] = c;
    }
    void str(const char* s) {
        while (*s) chr(*s++);
    }
    void dec(std::uint64_t v) {
        char t[20];
        int k = 0;
        do {
            t[k++] = char('0' + v % 10);
            v /= 10;
        } while (v);
        while (k) chr(t[--k]);
    }
    void hex(std::uint64_t v) {
        str("0x");
        char t[16];
        int k = 0;
        do {
            t[k++] = "0123456789abcdef"[v & 15];
            v >>= 4;
        } while (v);
        while (k) chr(t[--k]);
    }
    void pad2(int v) {
        chr(char('0' + v / 10 % 10));
        chr(char('0' + v % 10));
    }
    void year(int v) {
        chr(char('0' + v / 1000 % 10));
        chr(char('0' + v / 100 % 10));
        pad2(v % 100);
    }
    // 2026-10-17T14:30:52Z
    void iso_time(const Civil& c) {
        year(c.year); chr('-'); pad2(c.month); chr('-'); pad2(c.day); chr('T');
        pad2(c.hour); chr(':'); pad2(c.minute); chr(':'); pad2(c.second); chr('Z');
    }
    // 20261017T143052Z: the time in a file name
    void stamp(const Civil& c) {
        year(c.year); pad2(c.month); pad2(c.day); chr('T'); pad2(c.hour); pad2(c.minute); pad2(c.second); chr('Z');
    }
};

// Calls write(text, length) for each log line of the ring, oldest first (no newline).
template <class Write>
void for_each_log_line(Write&& write) {
    const std::uint32_t count = g_shared.logCount.load(std::memory_order_acquire);
    const std::uint32_t first = count > kLogLines ? count - std::uint32_t(kLogLines) : 0;
    for (std::uint32_t i = first; i < count; ++i) {
        const char* line = g_shared.logLines[i % kLogLines];
        std::size_t len = 0;
        while (len < kLogLineBytes - 1 && line[len]) ++len;
        write(line, len);
    }
}

}  // namespace fa::crash_detail
