#include <doctest.h>

#include <string>

#include "fa/core/build_info.h"

using namespace fa;

TEST_CASE("build info: this program has a fingerprint, and the marker in its bytes is found") {
    const std::string mine = build_fingerprint();
    CHECK_FALSE(mine.empty());
    if (mine != "unknown") CHECK(mine.size() >= 12);
    const std::string bytes = std::string("MZ\0\0 junk ", 10) + "FA-BUILD-FINGERPRINT:" + mine + ";" + " tail";
    CHECK(find_build_fingerprint(bytes) == mine);
}

TEST_CASE("build info: find_build_fingerprint reads a marker of another build and ignores a cut one") {
    CHECK(find_build_fingerprint("xx FA-BUILD-FINGERPRINT:0123456789ab-dirty; yy") == "0123456789ab-dirty");
    CHECK(find_build_fingerprint("no marker here").empty());
    CHECK(find_build_fingerprint("FA-BUILD-FINGERPRINT:abc").empty());  // no terminating ';'
    CHECK(find_build_fingerprint("FA-BUILD-FINGERPRINT:;").empty());
    // The first complete marker wins when a cut one comes before it.
    CHECK(find_build_fingerprint("FA-BUILD-FINGERPRINT:ab FA-BUILD-FINGERPRINT:cd;") == "cd");
}
