#include <doctest.h>

#include <limits>

#include "fa/platform/accessibility.h"

using namespace fa;

TEST_CASE("accessibility: the defaults are 100 % and everything off") {
    const AccessibilitySettings s;
    CHECK(s.textScale == 1.0f);
    CHECK_FALSE(s.reduceMotion);
    CHECK_FALSE(s.highContrast);
    CHECK_FALSE(s.screenReader);
}

TEST_CASE("accessibility: text scale is clamped to a sane range") {
    AccessibilitySettings s;
    s.textScale = 100.0f;
    CHECK(sanitize_accessibility(s).textScale == kMaxSystemTextScale);
    s.textScale = 0.0f;
    CHECK(sanitize_accessibility(s).textScale == kMinSystemTextScale);
    s.textScale = -3.0f;
    CHECK(sanitize_accessibility(s).textScale == kMinSystemTextScale);
    s.textScale = std::numeric_limits<float>::quiet_NaN();
    CHECK(sanitize_accessibility(s).textScale == 1.0f);
    s.textScale = std::numeric_limits<float>::infinity();
    CHECK(sanitize_accessibility(s).textScale == 1.0f);
    s.textScale = 1.5f;
    s.reduceMotion = true;
    const AccessibilitySettings kept = sanitize_accessibility(s);
    CHECK(kept.textScale == 1.5f);
    CHECK(kept.reduceMotion);
}

TEST_CASE("accessibility: gsettings output is parsed") {
    CHECK(parse_gsettings_bool("true\n") == true);
    CHECK(parse_gsettings_bool("false") == false);
    CHECK_FALSE(parse_gsettings_bool("").has_value());
    CHECK_FALSE(parse_gsettings_bool("No such schema 'x'").has_value());
    CHECK(parse_gsettings_number("1.25\n") == doctest::Approx(1.25));
    CHECK(parse_gsettings_number("uint32 3") == doctest::Approx(3.0));
    CHECK_FALSE(parse_gsettings_number("'text'").has_value());
    CHECK_FALSE(parse_gsettings_number("").has_value());
}

TEST_CASE("accessibility: what this system says is in range") {
    const AccessibilitySettings s = system_accessibility();  // the values depend on the machine: only the range is checked
    MESSAGE("this system: textScale ", s.textScale, " reduceMotion ", s.reduceMotion, " highContrast ", s.highContrast, " screenReader ", s.screenReader);
    CHECK(s.textScale >= kMinSystemTextScale);
    CHECK(s.textScale <= kMaxSystemTextScale);
    refresh_system_accessibility();
    CHECK(system_accessibility().textScale >= kMinSystemTextScale);
}
