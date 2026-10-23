#include <doctest.h>

#include "fa/core/i18n.h"
#include "fa/core/number_format.h"

using namespace fa;

TEST_CASE("number format: 1234.5 in the languages the table knows") {
    CHECK(format_number(1234.5, -1, "en") == "1,234.5");
    CHECK(format_number(1234.5, -1, "") == "1,234.5");
    CHECK(format_number(1234.5, -1, "es") == "1234,5");
    CHECK(format_number(12345.5, -1, "es") == "12.345,5");  // Spanish groups from 5 digits
    CHECK(format_number(1234.5, -1, "es-MX") == "1,234.5");
    CHECK(format_number(1234.5, -1, "de") == "1.234,5");
    CHECK(format_number(1234.5, -1, "de-CH") == "1\xE2\x80\x99" "234.5");
    CHECK(format_number(1234.5, -1, "fr") == "1\xE2\x80\xAF" "234,5");
    CHECK(format_number(1234.5, -1, "pt-BR") == "1.234,5");
    CHECK(format_number(1234.5, -1, "ru") == "1\xC2\xA0" "234,5");
    CHECK(format_number(1234.5, -1, "ar") == "\xD9\xA1\xD9\xAC\xD9\xA2\xD9\xA3\xD9\xA4\xD9\xAB\xD9\xA5");
    CHECK(format_number(1234.5, -1, "ja") == "1,234.5");
    CHECK(format_number(1234.5, -1, "xx") == "1,234.5");  // unknown: English
    CHECK(format_number(1234.5, -1, "pt_br") == "1.234,5");
}

TEST_CASE("number format: decimals, grouping and signs") {
    CHECK(format_number(2, 2, "en") == "2.00");
    CHECK(format_number(2.5, 0, "en") == "3");  // a tie rounds away from zero, like toFixed
    CHECK(format_number(0.25, 1, "en") == "0.3");
    CHECK(format_number(-0.25, 1, "en") == "-0.3");
    CHECK(format_number(1.005, 2, "en") == "1.00");
    CHECK(format_number(1234567.891, 1, "en") == "1,234,567.9");
    CHECK(format_number(999, 0, "en") == "999");
    CHECK(format_number(-1234.5, 1, "de") == "-1.234,5");
    CHECK(format_number(-0.04, 1, "en") == "0.0");
    CHECK(format_number(0.1 + 0.2, -1, "en") == "0.3");
    CHECK(format_number(1e15, 0, "en") == "1,000,000,000,000,000");
    CHECK(format_number(7, -1, "es") == "7");
}

TEST_CASE("number format: durations") {
    CHECK(format_duration(83.4, 1, "en") == "1:23.4");
    CHECK(format_duration(83.4, 1, "es") == "1:23,4");
    CHECK(format_duration(83.4, 0, "en") == "1:23");
    CHECK(format_duration(5, 1, "en") == "0:05.0");
    CHECK(format_duration(59.96, 1, "en") == "1:00.0");
    CHECK(format_duration(3723.4, 1, "en") == "1:02:03.4");
    CHECK(format_duration(0.125, 3, "en") == "0:00.125");
    CHECK(format_duration(-83.4, 1, "en") == "-1:23.4");
    CHECK(format_duration(-0.01, 1, "en") == "0:00.0");
    CHECK(format_duration(83.4, 1, "ar") == "\xD9\xA1:\xD9\xA2\xD9\xA3\xD9\xAB\xD9\xA4");
}

TEST_CASE("number format: {v:number:1} and {t:duration} placeholders") {
    const Json args = Json{{"v", 1234.56}, {"t", 83.4}, {"n", 12345}};
    CHECK(format_message("{v:number:1} m", args, nullptr, "en") == "1,234.6 m");
    CHECK(format_message("{v:number:1} m", args, nullptr, "es") == "1234,6 m");
    CHECK(format_message("{n:number}", args, nullptr, "es") == "12.345");
    CHECK(format_message("{n:number:0}", args, nullptr, "de") == "12.345");
    CHECK(format_message("{t:duration}", args, nullptr, "de") == "1:23,4");
    CHECK(format_message("{t:duration:0}", args, nullptr, "en") == "1:23");
    CHECK(format_message("{v}", args, nullptr, "es") == "1234.56");  // plain placeholders stay as they were

    std::vector<std::string> missing, problems;
    CHECK(format_message("{x:number:1}", args, &missing, "en", &problems) == "{x:number:1}");
    REQUIRE(missing.size() == 1);
    CHECK(missing[0] == "x");  // the name only, without the format

    problems.clear();
    CHECK(format_message("{v:money}", args, nullptr, "en", &problems) == "1234.56");
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].find("unknown format 'money'") != std::string::npos);
    problems.clear();
    CHECK(format_message("{v:number:x}", args, nullptr, "en", &problems) == "1234.56");
    REQUIRE(problems.size() == 1);
    problems.clear();
    CHECK(format_message("{s:number}", Json{{"s", "abc"}}, nullptr, "en", &problems) == "abc");
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].find("a string") != std::string::npos);
}
