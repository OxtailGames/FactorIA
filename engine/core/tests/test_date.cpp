#include <doctest.h>

#include "fa/core/date.h"

using namespace fa;

TEST_CASE("date: parse, weekday and iso") {
    auto d = parse_calendar_date("2026-10-23");
    REQUIRE(d.ok());
    CHECK(d->year == 2026);
    CHECK(d->month == 10);
    CHECK(d->day == 23);
    CHECK(d->weekday() == 5);  // Friday
    CHECK(d->iso() == "2026-10-23");
    CHECK(parse_calendar_date(kDefaultDate)->weekday() == 4);  // Thursday
    CHECK(parse_calendar_date("1970-01-01")->days_since_epoch() == 0);
    CHECK(parse_calendar_date("2000-02-29").ok());  // divisible by 400
    CHECK(parse_calendar_date("2028-02-29").ok());
}

TEST_CASE("date: impossible dates are teaching errors") {
    auto leap = parse_calendar_date("2026-02-29", "--date");
    REQUIRE(!leap.ok());
    CHECK(leap.error().message.find("--date '2026-02-29' is not a real date") != std::string::npos);
    CHECK(leap.error().message.find("28 days") != std::string::npos);
    CHECK(leap.error().hint.find("not a leap year") != std::string::npos);
    CHECK(!parse_calendar_date("1900-02-29").ok());
    CHECK(!parse_calendar_date("2026-04-31").ok());
    auto month = parse_calendar_date("2026-13-01");
    REQUIRE(!month.ok());
    CHECK(month.error().message.find("month 13") != std::string::npos);
    CHECK(!parse_calendar_date("2026-00-10").ok());
    CHECK(!parse_calendar_date("2026-01-00").ok());
    CHECK(!parse_calendar_date("0000-01-01").ok());
    for (const char* bad : {"", "2026-1-1", "26-01-01", "2026/01/01", "tomorrow", "2026-01-011", "2026-01-0a"}) {
        auto r = parse_calendar_date(bad);
        CHECK_MESSAGE(!r.ok(), bad);
        if (!r.ok()) CHECK(!r.error().hint.empty());
    }
}

TEST_CASE("date: days round trip") {
    for (const char* s : {"1999-12-31", "2000-02-29", "2026-03-01", "2100-02-28", "0001-01-01", "9999-12-31"}) {
        auto d = parse_calendar_date(s);
        REQUIRE(d.ok());
        CalendarDate back = calendar_date_from_days(d->days_since_epoch());
        CHECK(back.iso() == s);
    }
    CHECK(calendar_date_from_days(parse_calendar_date("2026-02-28")->days_since_epoch() + 1).iso() == "2026-03-01");
}
