// The IES photometric file parser (fa/render/ies.h): what it reads, what it refuses, and the baked profile the light atlas holds. CPU
// only. The fixtures are small profiles written for these tests (numbers of our own, not a manufacturer's file).
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

#include "fa/render/ies.h"

using namespace fa;

namespace {

// A downlight: type C, one horizontal plane (the same all around), five vertical angles from the nadir to the horizon.
const char* const kDownlight = "IESNA:LM-63-2002\n"
                               "[TEST] FA-TEST-001\n"
                               "[MANUFAC] FactorIA test fixture\n"
                               "[LUMINAIRE] Test downlight\n"
                               "TILT=NONE\n"
                               "1 1000 1 5 1 1 2 0.1 0.1 0\n"
                               "1 1 10\n"
                               "0 22.5 45 67.5 90\n"
                               "0\n"
                               "1000 800 400 100 0\n";

// A wall washer: a quarter table (0 to 90 degrees, four-fold symmetry), three vertical angles over the whole sphere.
const char* const kQuarter = "IESNA91\n"
                             "[TEST] FA-TEST-002\n"
                             "TILT=NONE\n"
                             "1 -1 1 3 3 1 1 0.2 0.2 0.1\n"
                             "1 1 20\n"
                             "0 90 180\n"
                             "0 45 90\n"
                             "100 100 100\n"
                             "200 200 200\n"
                             "400 400 400\n";

std::string without(std::string text, const std::string& what) {
    const std::size_t at = text.find(what);
    REQUIRE(at != std::string::npos);
    text.erase(at, what.size());
    return text;
}

std::string replaced(std::string text, const std::string& what, const std::string& with) {
    const std::size_t at = text.find(what);
    REQUIRE(at != std::string::npos);
    text.replace(at, what.size(), with);
    return text;
}

}  // namespace

TEST_CASE("ies: a downlight profile parses with its header and its table") {
    auto r = parse_ies(kDownlight, "lamp.ies");
    REQUIRE(r.ok());
    const IesProfile& p = *r;
    CHECK(p.version == "IESNA:LM-63-2002");
    CHECK(p.name == "Test downlight");  // [LUMINAIRE] wins over [TEST]
    CHECK(p.photometricType == 1);
    CHECK(p.units == 2);
    CHECK(p.lampLumens == doctest::Approx(1000.0));
    REQUIRE(p.vertical.size() == 5);
    REQUIRE(p.horizontal.size() == 1);
    REQUIRE(p.candela.size() == 5);
    CHECK(p.maxCandela == doctest::Approx(1000.0f));
    CHECK(p.candela_at(0, 0) == doctest::Approx(1000.0f));
    CHECK(p.candela_at(200, 11.25f) == doctest::Approx(900.0f));  // halfway between 1000 and 800, any horizontal angle
    CHECK(p.candela_at(0, 90) == doctest::Approx(0.0f));
    CHECK(p.candela_at(0, 120) == 0.0f);  // below the horizon the table does not reach: no light
}

TEST_CASE("ies: the candela multiplying factor scales the table and a name-less 1986 file parses") {
    auto r = parse_ies(replaced(kDownlight, "1 1000 1 5 1", "1 1000 2 5 1"), "lamp.ies");
    REQUIRE(r.ok());
    CHECK(r->maxCandela == doctest::Approx(2000.0f));
    CHECK(r->multiplier == doctest::Approx(2.0));
    auto old = parse_ies(without(kQuarter, "[TEST] FA-TEST-002\n"), "old.ies");
    REQUIRE(old.ok());
    CHECK(old->name.empty());
    CHECK(old->lampLumens < 0);  // -1: relative photometry
}

TEST_CASE("ies: a quarter table is folded by its symmetry") {
    auto r = parse_ies(kQuarter, "washer.ies");
    REQUIRE(r.ok());
    REQUIRE(r->horizontal.size() == 3);
    // The vertical angle goes along the rows (3 values per plane): at the nadir all planes read 100, 200 and 400 over 0, 45, 90.
    CHECK(r->candela_at(0, 0) == doctest::Approx(100.0f));
    CHECK(r->candela_at(45, 90) == doctest::Approx(200.0f));
    // 135 degrees folds to 45, 270 to 90, 315 to 45: the same plane as the table's own.
    CHECK(r->candela_at(135, 90) == doctest::Approx(r->candela_at(45, 90)));
    CHECK(r->candela_at(270, 90) == doctest::Approx(r->candela_at(90, 90)));
    CHECK(r->candela_at(315, 0) == doctest::Approx(r->candela_at(45, 0)));
    CHECK(r->candela_at(-45, 180) == doctest::Approx(r->candela_at(45, 180)));
}

TEST_CASE("ies: the baked profile is candela over the peak, 64 x 32") {
    auto r = parse_ies(kDownlight, "lamp.ies");
    REQUIRE(r.ok());
    const std::vector<float> bake = ies_bake(*r);
    REQUIRE(bake.size() == std::size_t(kIesBakeWidth) * std::size_t(kIesBakeHeight));
    // Row 0 is the vertical angle 2.8125 degrees: 1000 + (800 - 1000) * 2.8125 / 22.5 = 975, over the peak 1000.
    CHECK(bake[0] == doctest::Approx(0.975f).epsilon(1e-4));
    CHECK(bake[37] == doctest::Approx(0.975f).epsilon(1e-4));  // another column of the same row: round
    // Rows past the horizon (90 degrees and below) are 0; the peak is never above 1.
    CHECK(bake[std::size_t(20) * kIesBakeWidth] == 0.0f);
    float peak = 0;
    for (float v : bake) peak = std::max(peak, v);
    CHECK(peak <= 1.0f);
    CHECK(peak > 0.95f);
    // The same bytes every time.
    CHECK(ies_bake(*r) == bake);
}

TEST_CASE("ies: TILT=INCLUDE is read and dropped") {
    const std::string text = replaced(kDownlight, "TILT=NONE\n", "TILT=INCLUDE\n1\n3\n0 45 90\n1 0.8 0.5\n");
    auto r = parse_ies(text, "tilt.ies");
    REQUIRE(r.ok());
    CHECK(r->maxCandela == doctest::Approx(1000.0f));
}

TEST_CASE("ies: a file that is not photometric data says what to do") {
    auto noTilt = parse_ies("hello world\nnot a profile\n", "notes.ies");
    REQUIRE_FALSE(noTilt.ok());
    CHECK(noTilt.error().message.find("notes.ies") != std::string::npos);
    CHECK(noTilt.error().message.find("TILT") != std::string::npos);
    CHECK(noTilt.error().hint.find("IESNA") != std::string::npos);

    auto empty = parse_ies("", "empty.ies");
    REQUIRE_FALSE(empty.ok());
    CHECK(empty.error().message.find("empty.ies") != std::string::npos);

    auto word = parse_ies(replaced(kDownlight, "1 1000 1 5 1", "1 lots 1 5 1"), "word.ies");
    REQUIRE_FALSE(word.ok());
    CHECK(word.error().message.find("word.ies:6") != std::string::npos);  // the line of the header numbers
    CHECK(word.error().message.find("'lots'") != std::string::npos);
    CHECK_FALSE(word.error().hint.empty());

    auto cut = parse_ies(replaced(kDownlight, "1000 800 400 100 0\n", "1000 800\n"), "cut.ies");
    REQUIRE_FALSE(cut.ok());
    CHECK(cut.error().message.find("ends before") != std::string::npos);
    CHECK(cut.error().message.find("a candela value") != std::string::npos);
}

TEST_CASE("ies: photometric types A and B, bad counts, bad angles and bad values are refused with the line") {
    auto typeB = parse_ies(replaced(kDownlight, "1 1000 1 5 1 1 2", "1 1000 1 5 1 2 2"), "b.ies");
    REQUIRE_FALSE(typeB.ok());
    CHECK(typeB.error().message.find("b.ies:6") != std::string::npos);
    CHECK(typeB.error().message.find("type B") != std::string::npos);
    CHECK(typeB.error().hint.find("type C") != std::string::npos);

    auto zeroAngles = parse_ies(replaced(kDownlight, "1 1000 1 5 1", "1 1000 1 0 1"), "zero.ies");
    REQUIRE_FALSE(zeroAngles.ok());
    CHECK(zeroAngles.error().message.find("number of vertical angles is 0") != std::string::npos);

    auto huge = parse_ies(replaced(kDownlight, "1 1000 1 5 1", "1 1000 1 99999 1"), "huge.ies");
    REQUIRE_FALSE(huge.ok());  // refused before anything is allocated
    CHECK(huge.error().message.find("99999") != std::string::npos);

    auto descending = parse_ies(replaced(kDownlight, "0 22.5 45 67.5 90", "0 45 22.5 67.5 90"), "order.ies");
    REQUIRE_FALSE(descending.ok());
    CHECK(descending.error().message.find("not ascending") != std::string::npos);
    CHECK(descending.error().message.find("order.ies:") != std::string::npos);

    auto outside = parse_ies(replaced(kDownlight, "0 22.5 45 67.5 90", "0 22.5 45 67.5 200"), "range.ies");
    REQUIRE_FALSE(outside.ok());
    CHECK(outside.error().message.find("outside 0 to 180") != std::string::npos);

    auto negative = parse_ies(replaced(kDownlight, "1000 800 400 100 0", "1000 800 -4 100 0"), "neg.ies");
    REQUIRE_FALSE(negative.ok());
    CHECK(negative.error().message.find("negative") != std::string::npos);

    auto zeros = parse_ies(replaced(kDownlight, "1000 800 400 100 0", "0 0 0 0 0"), "dark.ies");
    REQUIRE_FALSE(zeros.ok());
    CHECK(zeros.error().message.find("dark.ies") != std::string::npos);
    CHECK(zeros.error().message.find("emits no light") != std::string::npos);

    // Two horizontal planes that start at 90 degrees are a range the renderer does not know.
    const std::string odd = "IESNA:LM-63-2002\nTILT=NONE\n1 1000 1 2 2 1 2 0 0 0\n1 1 10\n0 90\n90 270\n5 6\n7 8\n";
    auto range = parse_ies(odd, "odd.ies");
    REQUIRE_FALSE(range.ok());
    CHECK(range.error().message.find("horizontal angles run from") != std::string::npos);
    CHECK(range.error().hint.find("0 to 360") != std::string::npos);
}

TEST_CASE("ies: a byte order mark, CRLF line ends and commas between numbers parse") {
    std::string text = "\xEF\xBB\xBF";
    for (char c : std::string(kDownlight)) {
        if (c == '\n') text += '\r';
        text += c;
    }
    text = replaced(text, "0 22.5 45 67.5 90", "0, 22.5, 45, 67.5, 90");
    auto r = parse_ies(text, "crlf.ies");
    REQUIRE(r.ok());
    CHECK(r->candela_at(0, 22.5f) == doctest::Approx(800.0f));
}

TEST_CASE(
    "ies: a file over the size cap is not this parser's to read (the cap is checked by the loader before reading)") {
    // The constants the loader and the docs quote.
    CHECK(kIesMaxFileBytes == (std::size_t(4) << 20));
    CHECK(kIesMaxValues >= std::size_t(kIesMaxVerticalAngles));
}
