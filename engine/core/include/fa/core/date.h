// Calendar dates: the "today" a game sees through `game.today()` (docs/SCRIPTING.md, "The date").
//
// The date is an INPUT of the simulation, like the seed: the engine holds one CalendarDate (EngineConfig::date), set by
// whoever starts it. A player reads the wall clock once, at the platform edge (fa/platform/local_date.h); `factoria test`,
// headless runs and the MCP server use kDefaultDate unless --date says otherwise; a replay records its date. Nothing in
// this file reads the clock.
#pragma once

#include <string>
#include <string_view>

#include "fa/core/types.h"

namespace fa {

struct CalendarDate {
    int year = 2026;
    int month = 1;  // 1..12
    int day = 1;    // 1..days in the month
    int utcOffsetMinutes = 0;  // minutes east of UTC of the player's time zone; 0 for a fixed date

    // 0 = Sunday .. 6 = Saturday (the proleptic Gregorian calendar).
    int weekday() const;
    // "YYYY-MM-DD".
    std::string iso() const;
    // Days since 1970-01-01 (negative before).
    long days_since_epoch() const;

    bool operator==(const CalendarDate& o) const {
        return year == o.year && month == o.month && day == o.day && utcOffsetMinutes == o.utcOffsetMinutes;
    }
};

// The date of `factoria test`, headless runs and every host that was not given another: 2026-01-01 (a Thursday).
inline constexpr const char* kDefaultDate = "2026-01-01";

bool is_leap_year(int year);
int days_in_month(int year, int month);  // 0 for a month outside 1..12

// Parses "YYYY-MM-DD" (years 1..9999). Every other shape and every date that does not exist (2026-02-29, 2026-13-01) is an
// error that says what is wrong and how to fix it. `what` names the source in the message ("--date", "game.setDate").
Result<CalendarDate> parse_calendar_date(std::string_view text, std::string_view what = "date");

// Days since 1970-01-01 -> year/month/day (the inverse of CalendarDate::days_since_epoch).
CalendarDate calendar_date_from_days(long days);

}  // namespace fa
