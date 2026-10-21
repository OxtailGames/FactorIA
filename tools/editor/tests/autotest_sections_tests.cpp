// FA_EDITOR_AUTOTEST_SECTIONS: which sections of the windowed autotest a run plays. The sections themselves run in the
// windowed autotest (ctest editor_autotest_*); this is only the parsing of the variable.
#include <set>
#include <string>

#include "autotest_sections.h"
#include "doctest.h"

using namespace fa;
using namespace fa::editor;

TEST_CASE("autotest sections: ids in any case, separated by commas or spaces") {
    auto picked = parse_autotest_sections("k, m  a2,o");
    REQUIRE(picked);
    CHECK(*picked == std::set<std::string>{"A2", "K", "M", "O"});

    auto one = parse_autotest_sections("s");
    REQUIRE(one);
    CHECK(*one == std::set<std::string>{"S"});
}

TEST_CASE("autotest sections: an unknown id names the closest one and lists them all") {
    auto bad = parse_autotest_sections("K,A3");
    REQUIRE_FALSE(bad);
    CHECK(bad.error().message.find("'A3'") != std::string::npos);
    CHECK(bad.error().message.find("A2") != std::string::npos);  // did you mean
    for (const AutotestSection& s : kAutotestSections) CHECK(bad.error().hint.find(s.title) != std::string::npos);
}

TEST_CASE("autotest sections: a value that names no section is an error") {
    CHECK_FALSE(parse_autotest_sections(" , "));
    CHECK_FALSE(parse_autotest_sections(""));
}

TEST_CASE("autotest sections: ids are unique") {
    std::set<std::string> ids;
    for (const AutotestSection& s : kAutotestSections) CHECK(ids.insert(s.id).second);
}
