// The golden comparison helper (golden_check.h) that the render, menus and export goldens use.
#include <doctest.h>

#include <cstdint>
#include <cstdlib>
#include <string>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "golden_check.h"

using namespace fa;
using namespace fa::test;
namespace stdfs = std::filesystem;

namespace {

Image flat_picture(int w, int h, std::uint8_t grey) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(std::size_t(w) * h * 4, grey);
    for (std::size_t i = 3; i < img.rgba.size(); i += 4) img.rgba[i] = 255;
    return img;
}

struct GoldenDir {
    stdfs::path dir = fs::make_temp_dir("fa_golden_check_test").value();
    stdfs::path golden = dir / "picture.png";
    ~GoldenDir() {
        std::error_code ec;
        fs::remove_tree(dir, ec);
    }
};

}  // namespace

TEST_CASE("golden check: a missing golden fails and writes nothing; update mode writes it and then it matches") {
    GoldenDir t;
    const Image img = flat_picture(64, 36, 90);

    const GoldenResult missing = compare_golden(img, t.golden, GoldenLimits{}, false);
    CHECK(missing.verdict == GoldenVerdict::Missing);
    CHECK_FALSE(missing.ok());
    CHECK(missing.message.find("FA_UPDATE_GOLDENS=1") != std::string::npos);  // the message says how to create it
    CHECK_FALSE(stdfs::exists(t.golden));                                     // ... and a test run did not create it

    const GoldenResult wrote = compare_golden(img, t.golden, GoldenLimits{}, true);
    CHECK(wrote.verdict == GoldenVerdict::Wrote);
    CHECK(wrote.ok());
    REQUIRE(stdfs::exists(t.golden));

    const GoldenResult again = compare_golden(img, t.golden, GoldenLimits{}, false);
    CHECK(again.verdict == GoldenVerdict::Match);
    CHECK(again.diff.maxError == 0.0);
}

TEST_CASE("golden check: a golden that is not an image or has another size fails") {
    GoldenDir t;
    REQUIRE(fs::write_text(fs::path_to_utf8(t.golden), "not a png").ok());
    CHECK(compare_golden(flat_picture(8, 8, 0), t.golden, GoldenLimits{}, false).verdict == GoldenVerdict::Unreadable);

    REQUIRE(save_png(flat_picture(8, 8, 0), fs::path_to_utf8(t.golden)).ok());
    const GoldenResult wrongSize = compare_golden(flat_picture(8, 9, 0), t.golden, GoldenLimits{}, false);
    CHECK(wrongSize.verdict == GoldenVerdict::SizeMismatch);
    CHECK_FALSE(wrongSize.ok());
}

TEST_CASE("golden check: one very wrong pixel passes the mean error but is caught by the largest error") {
    GoldenDir t;
    const Image golden = flat_picture(320, 180, 20);
    REQUIRE(save_png(golden, fs::path_to_utf8(t.golden)).ok());

    Image img = golden;
    img.rgba[(100 * 320 + 160) * 4 + 0] = 255;  // one channel of one pixel, from 20 to 255
    img.rgba[(100 * 320 + 160) * 4 + 1] = 255;
    img.rgba[(100 * 320 + 160) * 4 + 2] = 255;

    const GoldenLimits limits;
    const GoldenResult r = compare_golden(img, t.golden, limits, false);
    CHECK(r.diff.meanError < limits.maxMeanError);       // the mean alone would pass ...
    CHECK(r.differingShare < limits.maxDifferingShare);  // ... and so would the share of pixels (one pixel)
    CHECK(r.diff.maxError > limits.maxPixelError);       // the largest error does not
    CHECK(r.verdict == GoldenVerdict::TooDifferent);
}

TEST_CASE("golden check: a wrong region passes the mean error but is caught by the share of differing pixels") {
    GoldenDir t;
    const Image golden = flat_picture(320, 180, 20);
    REQUIRE(save_png(golden, fs::path_to_utf8(t.golden)).ok());

    Image img = golden;
    // A 96x60 block (10 % of the picture) with one channel 30/255 off: mean error 0.1 * (30/255) / 4 = 0.003.
    for (int y = 60; y < 120; ++y)
        for (int x = 100; x < 196; ++x) img.rgba[(std::size_t(y) * 320 + x) * 4 + 1] = 50;

    const GoldenLimits limits;
    const GoldenResult r = compare_golden(img, t.golden, limits, false);
    CHECK(r.diff.meanError < limits.maxMeanError);
    CHECK(r.diff.maxError < limits.maxPixelError);
    CHECK(r.differingShare > limits.maxDifferingShare);
    CHECK(r.verdict == GoldenVerdict::TooDifferent);
}

TEST_CASE("golden check: one inverted pixel passes the edge limits but fails the default limits") {
    GoldenDir t;
    const Image golden = flat_picture(320, 180, 20);
    REQUIRE(save_png(golden, fs::path_to_utf8(t.golden)).ok());

    Image img = golden;
    for (int c = 0; c < 3; ++c)
        img.rgba[(100 * 320 + 160) * 4 + c] = 255 - 20;  // a glyph pixel that flipped: 20 -> 235

    // Text, thin lines and nearest-sampled edges use golden_edge_limits(): a single pixel may differ completely there ...
    const GoldenResult edge = compare_golden(img, t.golden, golden_edge_limits(), false);
    CHECK(edge.verdict == GoldenVerdict::Match);
    CHECK(edge.diff.maxError > 0.8);
    // ... which the default limits do not allow.
    const GoldenResult normal = compare_golden(img, t.golden, GoldenLimits{}, false);
    CHECK(normal.verdict == GoldenVerdict::TooDifferent);
    // Even the edge limits still catch a wrong region (the share) and keep the mean.
    Image block = golden;
    for (int y = 60; y < 120; ++y)
        for (int x = 100; x < 196; ++x)
            for (int c = 0; c < 3; ++c) block.rgba[(std::size_t(y) * 320 + x) * 4 + c] = 235;
    CHECK(compare_golden(block, t.golden, golden_edge_limits(), false).verdict == GoldenVerdict::TooDifferent);
}

TEST_CASE("golden check: FA_UPDATE_GOLDENS wins over the old FA_UPDATE_GOLDEN name") {
    struct Env {  // restores both variables
        std::string a, b;
        bool hadA, hadB;
        Env() {
            const char* x = std::getenv("FA_UPDATE_GOLDENS");
            const char* y = std::getenv("FA_UPDATE_GOLDEN");
            hadA = x != nullptr;
            hadB = y != nullptr;
            if (x) a = x;
            if (y) b = y;
        }
        ~Env() {
            set("FA_UPDATE_GOLDENS", hadA ? a.c_str() : nullptr);
            set("FA_UPDATE_GOLDEN", hadB ? b.c_str() : nullptr);
        }
        static void set(const char* name, const char* value) {
#ifdef _WIN32
            _putenv_s(name, value ? value : "");
#else
            if (value)
                setenv(name, value, 1);
            else
                unsetenv(name);
#endif
        }
    } env;
    Env::set("FA_UPDATE_GOLDENS", nullptr);
    Env::set("FA_UPDATE_GOLDEN", nullptr);
    CHECK_FALSE(golden_update_requested());
    Env::set("FA_UPDATE_GOLDEN", "1");
    CHECK(golden_update_requested());
    Env::set("FA_UPDATE_GOLDENS", "0");
    CHECK_FALSE(golden_update_requested());
    Env::set("FA_UPDATE_GOLDENS", "1");
    Env::set("FA_UPDATE_GOLDEN", "0");
    CHECK(golden_update_requested());
}

TEST_CASE("golden check: small rasterizer-like differences are within the limits") {
    GoldenDir t;
    const Image golden = flat_picture(320, 180, 100);
    REQUIRE(save_png(golden, fs::path_to_utf8(t.golden)).ok());

    Image img = golden;
    // Every pixel 2/255 off (under the per-pixel threshold), and a few edge pixels far off: 0.05 % of the picture.
    for (std::size_t i = 0; i < img.rgba.size(); i += 4) img.rgba[i] = 102;
    for (int x = 0; x < 28; ++x) img.rgba[(std::size_t(10) * 320 + x) * 4 + 2] = 160;  // 28 pixels, 60/255 off
    const GoldenResult r = compare_golden(img, t.golden, GoldenLimits{}, false);
    CHECK(r.verdict == GoldenVerdict::Match);
    CHECK(r.diff.differingPixels == 28);
}
