#pragma once
#include <filesystem>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <string>
#include <utility>
#include <vector>

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
        fa::fs::remove_tree(path, ec);
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

// A .zip with the entries stored (no compression), made without a zip program: the setup under test unpacks it with the system's
// tar/unzip. `entries` are {name inside the zip, contents}; a name ending in "/" is not needed (folders are made on unpacking).
inline void write_stored_zip(const std::filesystem::path& file, const std::vector<std::pair<std::string, std::string>>& entries) {
    auto crc32 = [](const std::string& data) {
        std::uint32_t crc = 0xFFFFFFFFu;
        for (unsigned char c : data) {
            crc ^= c;
            for (int k = 0; k < 8; ++k) crc = (crc >> 1) ^ (0xEDB88320u & (0u - (crc & 1u)));
        }
        return ~crc;
    };
    std::string out, central;
    auto u16 = [](std::string& s, std::uint32_t v) { s += static_cast<char>(v & 0xFF); s += static_cast<char>((v >> 8) & 0xFF); };
    auto u32 = [&](std::string& s, std::uint32_t v) { u16(s, v & 0xFFFF); u16(s, v >> 16); };
    for (const auto& e : entries) {
        const std::uint32_t offset = static_cast<std::uint32_t>(out.size()), crc = crc32(e.second), size = static_cast<std::uint32_t>(e.second.size());
        u32(out, 0x04034b50); u16(out, 20); u16(out, 0); u16(out, 0); u16(out, 0); u16(out, 33);
        u32(out, crc); u32(out, size); u32(out, size); u16(out, static_cast<std::uint32_t>(e.first.size())); u16(out, 0);
        out += e.first + e.second;
        u32(central, 0x02014b50); u16(central, 20); u16(central, 20); u16(central, 0); u16(central, 0); u16(central, 0); u16(central, 33);
        u32(central, crc); u32(central, size); u32(central, size); u16(central, static_cast<std::uint32_t>(e.first.size()));
        u16(central, 0); u16(central, 0); u16(central, 0); u16(central, 0); u32(central, 0); u32(central, offset);
        central += e.first;
    }
    const std::uint32_t centralOffset = static_cast<std::uint32_t>(out.size());
    out += central;
    u32(out, 0x06054b50); u16(out, 0); u16(out, 0); u16(out, static_cast<std::uint32_t>(entries.size()));
    u16(out, static_cast<std::uint32_t>(entries.size())); u32(out, static_cast<std::uint32_t>(central.size())); u32(out, centralOffset); u16(out, 0);
    write_all(file, out);
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
