#include <chrono>
#include <cctype>
#include <cstdio>
#include "fa/core/date.h"

#include <cstdio>

namespace fa {

namespace {
// Howard Hinnant's civil-calendar algorithms (public domain), proleptic Gregorian.
long days_from_civil(int y, int m, int d) {
    y -= m <= 2;
    const long era = (y >= 0 ? y : y - 399) / 400;
    const long yoe = y - era * 400;
    const long doy = (153L * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    const long doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}
}  // namespace

bool is_leap_year(int year) { return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0; }

int days_in_month(int year, int month) {
    static const int days[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (month < 1 || month > 12) return 0;
    return month == 2 && is_leap_year(year) ? 29 : days[month - 1];
}

long CalendarDate::days_since_epoch() const { return days_from_civil(year, month, day); }

int CalendarDate::weekday() const {
    const long z = days_since_epoch();
    return int(((z % 7) + 11) % 7);  // 1970-01-01 was a Thursday (4)
}

std::string CalendarDate::iso() const {
    char buf[32];
    std::snprintf(buf, sizeof buf, "%04d-%02d-%02d", year, month, day);
    return buf;
}

std::string CalendarDate::iso_time() const {
    char buf[32];
    std::snprintf(buf, sizeof buf, "%02d:%02d:%02d", hour, minute, second);
    return buf;
}

std::string CalendarDate::iso_datetime() const { return iso() + "T" + iso_time(); }

CalendarDate CalendarDate::utc() const {
    long minutes = days_since_epoch() * 1440L + hour * 60L + minute - utcOffsetMinutes;
    long days = minutes / 1440;
    if (minutes % 1440 < 0) --days;  // floor, also before 1970
    return calendar_date_from_days(days);
}

CalendarDate calendar_date_from_days(long z) {
    z += 719468;
    const long era = (z >= 0 ? z : z - 146096) / 146097;
    const long doe = z - era * 146097;
    const long yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    const long doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    const long mp = (5 * doy + 2) / 153;
    CalendarDate c;
    c.day = int(doy - (153 * mp + 2) / 5 + 1);
    c.month = int(mp < 10 ? mp + 3 : mp - 9);
    c.year = int(yoe + era * 400 + (c.month <= 2));
    return c;
}

Result<CalendarDate> parse_calendar_date(std::string_view text, std::string_view what) {
    const std::string who(what);
    const std::string shown(text);
    auto digits = [&](std::size_t from, std::size_t n) {
        for (std::size_t i = from; i < from + n; ++i)
            if (text[i] < '0' || text[i] > '9') return false;
        return true;
    };
    const bool hasTime = text.size() > 10;
    if (hasTime && (text[10] != 'T' && text[10] != ' ')) {
        return Error{who + " '" + shown + "' is not a date of the form YYYY-MM-DD",
                     "Write the year with four digits and the month and day with two, e.g. 2026-10-23, optionally followed by a time: 2026-10-23T18:30 or 2026-10-23T18:30:15."};
    }
    const std::string_view day = text.substr(0, 10);
    if (text.size() < 10 || day[4] != '-' || day[7] != '-' || !digits(0, 4) || !digits(5, 2) || !digits(8, 2))
        return Error{who + " '" + shown + "' is not a date of the form YYYY-MM-DD",
                     "Write the year with four digits and the month and day with two, e.g. 2026-10-23."};
    CalendarDate c;
    c.year = std::stoi(std::string(text.substr(0, 4)));
    c.month = std::stoi(std::string(text.substr(5, 2)));
    c.day = std::stoi(std::string(text.substr(8, 2)));
    if (c.year < 1)
        return Error{who + " '" + shown + "' has year 0000", "Years start at 0001; use a year from 0001 to 9999."};
    if (c.month < 1 || c.month > 12)
        return Error{who + " '" + shown + "' has month " + std::to_string(c.month) + ", which does not exist",
                     "The month is 01 to 12 (YYYY-MM-DD, e.g. 2026-10-23)."};
    const int maxDay = days_in_month(c.year, c.month);
    if (c.day < 1 || c.day > maxDay) {
        const std::string why = std::string("month ") + std::string(text.substr(5, 2)) + " of " + std::string(text.substr(0, 4)) + " has " +
              std::to_string(maxDay) + " days";
        std::string hint = "Use a day from 01 to " + std::to_string(maxDay) + ".";
        if (c.month == 2 && c.day == 29) hint = std::string(text.substr(0, 4)) + " is not a leap year: use 02-28 or 03-01, or a leap year such as 2028-02-29.";
        return Error{who + " '" + shown + "' is not a real date: " + why, hint};
    }
    if (hasTime) {
        const std::string_view t = text.substr(11);
        const bool shape = (t.size() == 5 || t.size() == 8) && t[2] == ':' && digits(11, 2) && digits(14, 2) &&
                           (t.size() == 5 || (t[5] == ':' && digits(17, 2)));
        if (!shape)
            return Error{who + " '" + shown + "' has a time that is not HH:MM or HH:MM:SS",
                         "Write the time after the date with two digits per part, e.g. 2026-10-23T18:30 or 2026-10-23T18:30:15."};
        c.hour = std::stoi(std::string(t.substr(0, 2)));
        c.minute = std::stoi(std::string(t.substr(3, 2)));
        c.second = t.size() == 8 ? std::stoi(std::string(t.substr(6, 2))) : 0;
        if (c.hour > 23 || c.minute > 59 || c.second > 59)
            return Error{who + " '" + shown + "' is not a real time: hours are 00-23, minutes and seconds 00-59",
                         "Use a time such as 23:59:59; midnight is 00:00:00 of the next day."};
    }
    return c;
}

std::int64_t unix_time_ms_now() {
    return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
}

std::string iso_utc_ms(std::int64_t unixMs) {
    std::int64_t days = unixMs / 86400000;
    std::int64_t rem = unixMs % 86400000;
    if (rem < 0) { rem += 86400000; --days; }
    CalendarDate d = calendar_date_from_days(static_cast<long>(days));
    char buf[40];
    std::snprintf(buf, sizeof buf, "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ", d.year, d.month, d.day, static_cast<int>(rem / 3600000),
                  static_cast<int>(rem / 60000 % 60), static_cast<int>(rem / 1000 % 60), static_cast<int>(rem % 1000));
    return buf;
}

bool parse_iso_utc_ms(std::string_view text, std::int64_t& unixMs) {
    int y = 0, mo = 0, d = 0, h = 0, mi = 0, sec = 0, ms = 0, n = 0;
    std::string t(text);
    if (std::sscanf(t.c_str(), "%4d-%2d-%2dT%2d:%2d:%2d%n", &y, &mo, &d, &h, &mi, &sec, &n) != 6) return false;
    if (mo < 1 || mo > 12 || d < 1 || d > days_in_month(y, mo) || h > 23 || mi > 59 || sec > 60) return false;
    std::size_t pos = static_cast<std::size_t>(n);
    if (pos < t.size() && t[pos] == '.') {
        int digits = 0;
        ++pos;
        int scale = 100;
        while (pos < t.size() && std::isdigit(static_cast<unsigned char>(t[pos]))) {
            if (digits < 3) { ms += (t[pos] - '0') * scale; scale /= 10; }
            ++digits;
            ++pos;
        }
        if (digits == 0) return false;
    }
    if (pos < t.size() && t[pos] != 'Z') return false;
    CalendarDate cd;
    cd.year = y; cd.month = mo; cd.day = d;
    unixMs = (static_cast<std::int64_t>(cd.days_since_epoch()) * 86400 + h * 3600 + mi * 60 + sec) * 1000 + ms;
    return true;
}

}  // namespace fa
