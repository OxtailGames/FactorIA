#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/image_tools.h"
#include "fa/core/screenshot_files.h"
#include "fa_test_paths.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

Image solid(int w, int h, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * h * 4);
    for (std::size_t i = 0; i < std::size_t(w) * h; ++i) {
        img.rgba[i * 4 + 0] = r;
        img.rgba[i * 4 + 1] = g;
        img.rgba[i * 4 + 2] = b;
        img.rgba[i * 4 + 3] = 255;
    }
    return img;
}

void put(Image& img, int x, int y, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
    p[0] = r;
    p[1] = g;
    p[2] = b;
    p[3] = 255;
}

}  // namespace

TEST_CASE("image_tools: crop_image keeps the pixels and pads outside with transparent black") {
    Image src = solid(10, 8, 10, 20, 30);
    put(src, 3, 2, 200, 100, 50);
    Image c = crop_image(src, 2, 1, 4, 3);
    REQUIRE(c.width == 4);
    REQUIRE(c.height == 3);
    CHECK(c.rgba[(1 * 4 + 1) * 4] == 200);  // (3,2) of src is (1,1) of the crop
    CHECK(c.rgba[0] == 10);
    Image edge = crop_image(src, 8, 6, 4, 4);  // half outside
    REQUIRE(edge.width == 4);
    CHECK(edge.rgba[3] == 255);                  // inside: opaque
    CHECK(edge.rgba[(3 * 4 + 3) * 4 + 3] == 0);  // outside: transparent
    CHECK(crop_image(src, 0, 0, 0, 4).empty());
    CHECK(crop_image(Image{}, 0, 0, 4, 4).empty());
}

TEST_CASE("image_tools: resize_nearest makes hard blocks") {
    Image src = solid(2, 1, 0, 0, 0);
    put(src, 1, 0, 255, 255, 255);
    Image big = resize_nearest(src, 8, 4);
    REQUIRE(big.width == 8);
    REQUIRE(big.height == 4);
    for (int y = 0; y < 4; ++y)
        for (int x = 0; x < 8; ++x) {
            const std::uint8_t v = big.rgba[(std::size_t(y) * 8 + x) * 4];
            CHECK(v == (x < 4 ? 0 : 255));  // only the two source colours, no blending
        }
    Image same = resize_nearest(src, 2, 1);
    CHECK(same.rgba == src.rgba);
}

TEST_CASE("image_tools: sheet_layout and contact_sheet put the tiles in a labelled grid") {
    SheetLayout l = sheet_layout(13, 4, 100, 50, 4);
    CHECK(l.columns == 4);
    CHECK(l.rows == 4);
    CHECK(l.width == 4 * 100 + 5 * 4);
    CHECK(l.height == 4 * 50 + 5 * 4);
    CHECK(sheet_layout(3, 8, 10, 10, 2).columns == 3);  // never more columns than tiles
    CHECK(sheet_layout(0, 0, 10, 10).width == 0);
    const SheetLayout autoCols = sheet_layout(12, 0, 160, 90);  // 16:9 tiles: a grid near square in pixels
    CHECK(autoCols.columns * autoCols.rows >= 12);
    CHECK(autoCols.columns >= 3);

    std::vector<Image> tiles{solid(40, 20, 255, 0, 0), solid(40, 20, 0, 255, 0), solid(40, 20, 0, 0, 255)};
    SheetLayout used;
    Image sheet = contact_sheet(tiles, {"f10", "f14 +4"}, 2, 3, &used);
    REQUIRE(sheet.width == used.width);
    CHECK(used.columns == 2);
    CHECK(used.rows == 2);
    CHECK(sheet.width == 2 * 40 + 3 * 3);
    CHECK(sheet.height == 2 * 20 + 3 * 3);
    // The third tile (blue) is on the second row, first column; a pixel away from the (top-left) label box is its colour.
    const int ox = 3, oy = 3 + 20 + 3;
    const std::uint8_t* p = &sheet.rgba[(std::size_t(oy + 15) * sheet.width + ox + 30) * 4];
    CHECK(p[2] == 255);
    CHECK(p[0] == 0);
    // The label of the first tile is white pixels on black at its top-left corner; the unlabelled third has none.
    bool white = false;
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 30; ++x)
            white |= sheet.rgba[(std::size_t(3 + y) * sheet.width + 3 + x) * 4 + 1] == 255 &&
                     sheet.rgba[(std::size_t(3 + y) * sheet.width + 3 + x) * 4 + 0] == 255;
    CHECK(white);
    CHECK(contact_sheet({}, {}, 2).empty());
}

TEST_CASE("image_tools: profile_line samples one pixel per step and find_steps lists the hard jumps") {
    Image img = solid(20, 4, 50, 50, 50);
    for (int y = 0; y < 4; ++y)
        for (int x = 10; x < 20; ++x) put(img, x, y, 200, 200, 200);  // a hard edge between x = 9 and x = 10
    for (int y = 0; y < 4; ++y) put(img, 4, y, 120, 120, 120);        // a 1 px bright seam at x = 4 (+70)
    std::vector<Vec2> pts;
    auto v = profile_line(img, {0, 1}, {19, 1}, ProfileChannel::Luminance, &pts);
    REQUIRE(v.size() == 20);
    CHECK(pts[5].x == doctest::Approx(5.0f));
    CHECK(v[0] == doctest::Approx(50.0f).epsilon(0.01));
    CHECK(v[19] == doctest::Approx(200.0f).epsilon(0.01));
    auto steps = find_steps(v, 30.0f, 2);
    REQUIRE(steps.size() == 3);  // up into the seam, down out of it, the edge
    CHECK(steps[0].index == 3);
    CHECK(steps[0].delta == doctest::Approx(70.0f).epsilon(0.02));
    CHECK(steps[1].index == 4);
    CHECK(steps[1].delta < 0);
    CHECK(steps[2].index == 9);
    CHECK(steps[2].width == 1);
    CHECK(steps[2].delta == doctest::Approx(150.0f).epsilon(0.01));
    CHECK(find_steps(v, 200.0f, 2).empty());
    // Channel and reversed direction.
    auto red = profile_line(img, {19, 1}, {0, 1}, ProfileChannel::Red);
    CHECK(red.front() == 200.0f);
    CHECK(red.back() == 50.0f);
    CHECK(profile_line(img, {5, 2}, {5, 2}, ProfileChannel::Blue).size() == 1);
    CHECK(parse_profile_channel("green").ok());
    CHECK_FALSE(parse_profile_channel("grene").ok());
}

TEST_CASE("image_tools: a smooth ramp has no steps, a staircase has one per riser, a 2 px jump is one step") {
    std::vector<float> ramp, stairs, wide;
    for (int i = 0; i < 100; ++i) ramp.push_back(float(i) * 2.0f);  // 2 levels per pixel
    CHECK(find_steps(ramp, 8.0f, 2).empty());
    for (int i = 0; i < 40; ++i) stairs.push_back(float(i / 10) * 20.0f);  // 0,20,40,60: three risers of 20
    CHECK(find_steps(stairs, 8.0f, 2).size() == 3);
    wide = {0, 0, 100, 200, 200};  // 200 in two samples
    auto steps = find_steps(wide, 150.0f, 2);
    REQUIRE(steps.size() == 1);
    CHECK(steps[0].width == 2);
    CHECK(steps[0].index == 1);  // the last flat sample, 1, is before the jump; it ends at sample 3
    CHECK(find_steps(stairs, 8.0f, 2, 2).size() == 2);  // maxSteps
}

TEST_CASE("screenshot_files: only frame_<n>*.png counts as engine-named") {
    CHECK(is_engine_named_screenshot("frame_120.png"));
    CHECK(is_engine_named_screenshot("frame_120_region.png"));
    CHECK(is_engine_named_screenshot("frame_7_sheet.png"));
    CHECK_FALSE(is_engine_named_screenshot("frame_.png"));
    CHECK_FALSE(is_engine_named_screenshot("frame_hall.png"));
    CHECK_FALSE(is_engine_named_screenshot("editor_12.png"));
    CHECK_FALSE(is_engine_named_screenshot("hall.png"));
    CHECK_FALSE(is_engine_named_screenshot("frame_12.jpg"));
}

TEST_CASE("screenshot_files: prune_screenshots drops old and surplus engine-named files, never the user's") {
    const stdfs::path dir = fs::make_temp_dir("fa_prune_shots").value();
    const stdfs::path shots = dir / ".factoria" / "screenshots";
    stdfs::create_directories(shots);
    auto make = [&](const std::string& name, int ageHours) {
        std::ofstream(shots / name, std::ios::binary) << "png";
        stdfs::last_write_time(shots / name, stdfs::file_time_type::clock::now() - std::chrono::hours(ageHours));
    };
    make("frame_1.png", 24 * 10);        // old: goes
    make("frame_2_region.png", 24 * 5);  // old: goes
    make("frame_3.png", 24);             // fresh: stays
    make("editor_9.png", 24 * 30);       // the user's, however old: stays
    make("hall.png", 24 * 30);           // named by a test: stays
    CHECK(prune_screenshots(dir, 3, 200) == 2);
    CHECK_FALSE(stdfs::exists(shots / "frame_1.png"));
    CHECK_FALSE(stdfs::exists(shots / "frame_2_region.png"));
    CHECK(stdfs::exists(shots / "frame_3.png"));
    CHECK(stdfs::exists(shots / "editor_9.png"));
    CHECK(stdfs::exists(shots / "hall.png"));
    // The cap keeps the newest.
    make("frame_10.png", 5);
    make("frame_11.png", 3);
    make("frame_12.png", 1);
    CHECK(prune_screenshots(dir, 3, 2) == 2);  // frame_3 (24 h) and frame_10 (5 h) are the oldest of five
    CHECK_FALSE(stdfs::exists(shots / "frame_3.png"));
    CHECK_FALSE(stdfs::exists(shots / "frame_10.png"));
    CHECK(stdfs::exists(shots / "frame_11.png"));
    CHECK(stdfs::exists(shots / "frame_12.png"));
    CHECK(stdfs::exists(shots / "editor_9.png"));
    CHECK(prune_screenshots(dir / "no_such_project") == 0);
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}

TEST_CASE(
    "screenshot_files: discard_temporary_image deletes only a flagged engine-named file in the screenshot folder") {
    const stdfs::path dir = fs::make_temp_dir("fa_discard_shots").value();
    const stdfs::path shots = dir / ".factoria" / "screenshots";
    stdfs::create_directories(shots);
    stdfs::create_directories(dir / "assets");
    auto make = [&](const stdfs::path& p) { std::ofstream(p, std::ios::binary) << "png"; };
    make(shots / "frame_5.png");
    make(shots / "hall.png");
    make(dir / "assets" / "frame_5.png");
    auto spec = [](const stdfs::path& p, bool temporary) {
        Json j = Json::object({{"path", p.generic_string()}, {"mimeType", "image/png"}});
        if (temporary) j["temporary"] = true;
        return j;
    };
    CHECK_FALSE(discard_temporary_image(spec(shots / "frame_5.png", false), dir));  // not flagged
    CHECK(stdfs::exists(shots / "frame_5.png"));
    CHECK_FALSE(discard_temporary_image(spec(shots / "hall.png", true), dir));              // not engine-named
    CHECK_FALSE(discard_temporary_image(spec(dir / "assets" / "frame_5.png", true), dir));  // outside the folder
    CHECK(stdfs::exists(dir / "assets" / "frame_5.png"));
    CHECK(discard_temporary_image(spec(shots / "frame_5.png", true), dir));
    CHECK_FALSE(stdfs::exists(shots / "frame_5.png"));
    CHECK_FALSE(discard_temporary_image(spec(shots / "frame_5.png", true), dir));  // already gone
    make(shots / "frame_6.png");
    Json rel = Json::object({{"path", ".factoria/screenshots/frame_6.png"}, {"temporary", true}});
    CHECK(discard_temporary_image(rel, dir));  // a project-relative path
    CHECK_FALSE(discard_temporary_image(Json::object({{"base64", "AAAA"}, {"temporary", true}}), dir));
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}

// ---- Normal maps made from a height field (M74) ----------------------------------------------------------------------

namespace {

// The input of the frozen maps in tests/data/normal_map_from_height.png: a fixed function of the pixel (never change it).
std::vector<double> bumpy_field(int w, int h) {
    std::vector<double> v(std::size_t(w) * std::size_t(h));
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x)
            v[std::size_t(y) * std::size_t(w) + std::size_t(x)] =
                0.5 + 0.35 * std::sin(double(x) * 0.31) * std::cos(double(y) * 0.23) +
                0.1 * double((x * 7 + y * 13) % 5) / 5.0;
    return v;
}

}  // namespace

TEST_CASE("normal_map_from_height: the shared kernel keeps the bytes of the frozen fixture, clamped and tiled") {
    // tests/data/normal_map_from_height.png holds six 48 x 32 maps of bumpy_field one under the other, made once by the kernel as
    // tools/common wrote it before M74 (clamped then tiled; strength 0, 1, 3.5 in each). It is a copy of what the kernel gave
    // then, not a second implementation: a change of the kernel that moves a byte fails here, and the fixture is replaced
    // only on purpose.
    const int w = 48, h = 32;
    std::ifstream in(std::string(FA_REPO_ROOT) + "/engine/core/tests/data/normal_map_from_height.png",
                     std::ios::binary);
    REQUIRE(in.good());
    const std::vector<std::uint8_t> bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    const auto frozen = decode_image(bytes.data(), bytes.size());
    REQUIRE(frozen);
    REQUIRE(frozen->width == w);
    REQUIRE(frozen->height == h * 6);
    const std::vector<double> field = bumpy_field(w, h);
    int part = 0;
    for (bool tile : {false, true})
        for (double strength : {0.0, 1.0, 3.5}) {
            CAPTURE(tile);
            CAPTURE(strength);
            const Image got = normal_map_from_height(field, w, h, tile, strength);
            REQUIRE(got.width == w);
            REQUIRE(got.height == h);
            const auto first = frozen->rgba.begin() + std::ptrdiff_t(part) * w * h * 4;
            CHECK(std::equal(got.rgba.begin(), got.rgba.end(), first));
            ++part;
        }
    // a flat map is (0.5, 0.5, 1) everywhere
    const Image flat = normal_map_from_height(std::vector<double>(16, 0.3), 4, 4, false, 2.0);
    CHECK(int(flat.rgba[0]) == 128);
    CHECK(int(flat.rgba[1]) == 128);
    CHECK(int(flat.rgba[2]) == 255);
    // bad sizes give an empty image, never a read past the field
    CHECK(normal_map_from_height(field, 0, 5, false, 1.0).empty());
    CHECK(normal_map_from_height(std::vector<double>(3, 0.0), 4, 4, false, 1.0).empty());
}

TEST_CASE("normal_map_from_sprite: the silhouette is a bevel that faces outwards, an empty or opaque flat sprite stays "
          "flat inside") {
    // a 32x32 opaque square on a transparent 48x48 picture
    Image sprite = solid(48, 48, 200, 200, 200);
    for (int y = 0; y < 48; ++y)
        for (int x = 0; x < 48; ++x)
            if (x < 8 || x >= 40 || y < 8 || y >= 40) sprite.rgba[(std::size_t(y) * 48 + std::size_t(x)) * 4 + 3] = 0;
    const Image n = normal_map_from_sprite(sprite, 8.0);
    REQUIRE(n.width == 48);
    auto px = [&](int x, int y) { return &n.rgba[(std::size_t(y) * 48 + std::size_t(x)) * 4]; };
    CHECK(int(px(8, 24)[0]) < 124);   // the left edge faces left (-x)
    CHECK(int(px(39, 24)[0]) > 132);  // the right edge faces right
    CHECK(int(px(24, 8)[1]) > 132);   // the top edge faces up the picture (+y)
    CHECK(int(px(24, 39)[1]) < 124);  // the bottom edge faces down
    CHECK(int(px(0, 0)[2]) == 255);   // far outside: flat
    // the same picture twice gives the same bytes
    CHECK(normal_map_from_sprite(sprite, 8.0).rgba == n.rgba);
    // a grey image as a height field: a ramp rising to the right tilts the normals to the left
    Image ramp = solid(64, 64, 0, 0, 0);
    for (int y = 0; y < 64; ++y)
        for (int x = 0; x < 64; ++x) {
            const auto v = std::uint8_t(x * 4);
            std::uint8_t* o = &ramp.rgba[(std::size_t(y) * 64 + std::size_t(x)) * 4];
            o[0] = o[1] = o[2] = v;
        }
    const Image rn = normal_map_from_height_image(ramp, 40.0);
    CHECK(int(rn.rgba[(32 * 64 + 32) * 4]) < 120);
    CHECK(int(rn.rgba[(32 * 64 + 32) * 4 + 1]) == 128);
}
