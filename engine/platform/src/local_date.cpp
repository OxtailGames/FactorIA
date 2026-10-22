#include "fa/platform/local_date.h"

#include <ctime>

namespace fa {

CalendarDate local_calendar_date() {
    const std::time_t now = std::time(nullptr);
    std::tm local{}, utc{};
#if defined(_WIN32)
    localtime_s(&local, &now);
    gmtime_s(&utc, &now);
#else
    localtime_r(&now, &local);
    gmtime_r(&now, &utc);
#endif
    CalendarDate c;
    c.year = local.tm_year + 1900;
    c.month = local.tm_mon + 1;
    c.day = local.tm_mday;
    // The offset: the local wall-clock reading minus the UTC one, both as plain calendar arithmetic (no mktime, whose
    // daylight-saving guesses would be wrong twice a year).
    auto seconds = [](const std::tm& t) {
        CalendarDate d;
        d.year = t.tm_year + 1900;
        d.month = t.tm_mon + 1;
        d.day = t.tm_mday;
        return d.days_since_epoch() * 86400L + t.tm_hour * 3600L + t.tm_min * 60L + t.tm_sec;
    };
    c.utcOffsetMinutes = int((seconds(local) - seconds(utc)) / 60);
    return c;
}

}  // namespace fa
