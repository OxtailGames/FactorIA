#pragma once
#include <filesystem>
#include <cstdlib>
#include <fstream>
#include <string>

#include "fa/core/json.h"
#include "fa/core/fs.h"

namespace fa::testing {

// FA_REQUIRE_SHDC=1 (CI sets it after `factoria setup shaders`): a test that needs the real sokol-shdc FAILS when none is
// found instead of skipping, so a broken install can never turn into silent skips. Locally the tests still skip.
inline bool shdc_required() {
    const char* v = std::getenv("FA_REQUIRE_SHDC");
    return v && std::string(v) == "1";
}

// Unique temporary directory removed on destruction.
struct TempDir {
    std::filesystem::path path;
    TempDir() {
        path = fa::fs::make_temp_dir("fa_tooling_test");
    }
    ~TempDir() {
        std::error_code ec;
        std::filesystem::remove_all(path, ec);
    }
    std::string str() const { return path.string(); }
    std::string sub(const std::string& rel) const { return (path / rel).string(); }
};

inline std::string read_all(const std::filesystem::path& p) {
    std::ifstream in(p, std::ios::binary);
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

inline void write_all(const std::filesystem::path& p, const std::string& s) {
    std::filesystem::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary) << s;
}

}  // namespace fa::testing

// Call when no sokol-shdc was found: fails the test when CI requires one (FA_REQUIRE_SHDC=1), else does nothing and the
// test skips itself.
#define FA_FAIL_IF_SHDC_REQUIRED()                                                                                         \
    do {                                                                                                                   \
        if (fa::testing::shdc_required())                                                                                  \
            FAIL("sokol-shdc was not found but FA_REQUIRE_SHDC=1: the CI step `factoria setup shaders` did not install it. " \
                 "Run it, or set SOKOL_SHDC.");                                                                            \
    } while (0)

// First line of a real-compiler test: returns (skips the test) when no sokol-shdc is found.
#define FA_SKIP_WITHOUT_SHDC(context, skipMessage) \
    do {                                           \
        if (fa::find_sokol_shdc(context).empty()) { \
            FA_FAIL_IF_SHDC_REQUIRED();            \
            MESSAGE(skipMessage);                  \
            return;                                \
        }                                          \
    } while (0)
