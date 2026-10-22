// The player's calendar date, read from the wall clock. THIS is the only place the engine reads the real time of day: a host
// that opens a window (the player, the editor) calls it once and puts the result in EngineConfig::date; headless runs and tests
// never call it, so a simulation never depends on when it runs (fa/core/date.h).
#pragma once

#include "fa/core/date.h"

namespace fa {

// Today in the system's time zone, with the zone's offset from UTC (daylight saving included).
CalendarDate local_calendar_date();

}  // namespace fa
