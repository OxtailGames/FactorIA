#include <doctest.h>

#include <array>
#include <cmath>
#include <filesystem>

#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"

using namespace fa;

namespace {

Image solid(int w, int h, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * h * 4);
    for (std::size_t i = 0; i < std::size_t(w) * h; ++i) {
        img.rgba[i * 4 + 0] = r;
        img.rgba[i * 4 + 1] = g;
        img.rgba[i * 4 + 2] = b;
        img.rgba[i * 4 + 3] = a;
    }
    return img;
}

void put(Image& img, int x, int y, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a) {
    std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
    p[0] = r; p[1] = g; p[2] = b; p[3] = a;
}

std::array<int, 4> px(const Image& img, int x, int y) {
    const std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
    return {p[0], p[1], p[2], p[3]};
}

}  // namespace

TEST_CASE("resize_image: same size copies, bad sizes give an empty image") {
    Image a = solid(3, 2, 10, 20, 30, 255);
    Image same = resize_image(a, 3, 2);
    CHECK(same.width == 3);
    CHECK(same.rgba == a.rgba);
    CHECK(resize_image(a, 0, 4).empty());
    CHECK(resize_image(Image{}, 4, 4).empty());
}

TEST_CASE("resize_image: shrinking averages the pixels under each destination pixel") {
    Image a = solid(2, 2, 0, 0, 0, 255);
    put(a, 1, 0, 200, 200, 200, 255);
    put(a, 0, 1, 100, 100, 100, 255);
    put(a, 1, 1, 100, 100, 100, 255);
    Image one = resize_image(a, 1, 1);
    REQUIRE(one.width == 1);
    CHECK(px(one, 0, 0)[0] == 100);  // (0 + 200 + 100 + 100) / 4
    CHECK(px(one, 0, 0)[3] == 255);

    // A fractional ratio: 3 -> 2 gives weights 2/3 and 1/3 on the middle pixel.
    Image row = solid(3, 1, 0, 0, 0, 255);
    put(row, 0, 0, 0, 0, 0, 255);
    put(row, 1, 0, 90, 90, 90, 255);
    put(row, 2, 0, 180, 180, 180, 255);
    Image two = resize_image(row, 2, 1);
    CHECK(px(two, 0, 0)[0] == 30);   // (0 * 1 + 90 * 0.5) / 1.5
    CHECK(px(two, 1, 0)[0] == 150);  // (90 * 0.5 + 180 * 1) / 1.5
}

TEST_CASE("resize_image: enlarging is bilinear and keeps a flat colour flat") {
    Image flat = resize_image(solid(2, 2, 10, 120, 240, 255), 9, 7);
    REQUIRE(flat.width == 9);
    REQUIRE(flat.height == 7);
    for (int y = 0; y < 7; ++y)
        for (int x = 0; x < 9; ++x) CHECK(px(flat, x, y) == std::array<int, 4>{10, 120, 240, 255});

    Image ramp = solid(2, 1, 0, 0, 0, 255);
    put(ramp, 1, 0, 200, 200, 200, 255);
    Image up = resize_image(ramp, 4, 1);  // pixel centers at 0.25 .. 0.875 of the source: 0, 50, 150, 200
    CHECK(px(up, 0, 0)[0] == 0);
    CHECK(px(up, 1, 0)[0] == 50);
    CHECK(px(up, 2, 0)[0] == 150);
    CHECK(px(up, 3, 0)[0] == 200);
}

TEST_CASE("resize_image: transparent pixels do not darken or tint the colour of their neighbours") {
    // Left pixel opaque white, right pixel fully transparent black (the usual background of a PNG).
    Image a = solid(2, 1, 0, 0, 0, 0);
    put(a, 0, 0, 255, 255, 255, 255);
    Image one = resize_image(a, 1, 1);
    REQUIRE(one.width == 1);
    CHECK(px(one, 0, 0)[0] == 255);  // still white, not grey
    CHECK(px(one, 0, 0)[1] == 255);
    CHECK(px(one, 0, 0)[2] == 255);
    CHECK(px(one, 0, 0)[3] == 128);  // half covered: the alpha is averaged

    // A fully transparent result is (0, 0, 0, 0).
    Image clear = resize_image(solid(4, 4, 9, 9, 9, 0), 2, 2);
    CHECK(px(clear, 1, 1) == std::array<int, 4>{0, 0, 0, 0});
}

TEST_CASE("resize_image: the two axes are independent") {
    Image a = solid(4, 2, 50, 60, 70, 255);
    Image b = resize_image(a, 2, 6);  // shrink x, enlarge y
    REQUIRE(b.width == 2);
    REQUIRE(b.height == 6);
    CHECK(px(b, 1, 5) == std::array<int, 4>{50, 60, 70, 255});
}

TEST_CASE("fit_image: centered over the background, aspect ratio kept") {
    // 2x1 image (red | blue) on a 4x4 canvas at scale 1 -> 4x2 centered, background above and below.
    Image a = solid(2, 1, 255, 0, 0, 255);
    put(a, 1, 0, 0, 0, 255, 255);
    Image f = fit_image(a, 4, 1.0f, Color::rgba8(0, 255, 0, 255));
    REQUIRE(f.width == 4);
    REQUIRE(f.height == 4);
    CHECK(px(f, 0, 0) == std::array<int, 4>{0, 255, 0, 255});
    CHECK(px(f, 3, 3) == std::array<int, 4>{0, 255, 0, 255});
    CHECK(px(f, 0, 1)[0] == 255);  // red half
    CHECK(px(f, 3, 2)[2] == 255);  // blue half
}

TEST_CASE("fit_image: scale leaves a margin, a transparent background stays transparent, an opaque one fills the corners") {
    Image a = solid(8, 8, 255, 255, 255, 255);
    Image f = fit_image(a, 16, 0.5f, Color::clear());
    CHECK(px(f, 0, 0)[3] == 0);
    CHECK(px(f, 15, 15)[3] == 0);
    CHECK(px(f, 8, 8)[3] == 255);  // the middle 8x8 square
    CHECK(px(f, 3, 8)[3] == 0);
    CHECK(px(f, 4, 8)[3] == 255);
    CHECK(px(f, 11, 8)[3] == 255);
    CHECK(px(f, 12, 8)[3] == 0);

    Image opaque = fit_image(a, 16, 0.5f, Color::black());
    for (std::size_t i = 0; i < 16 * 16; ++i) CHECK(opaque.rgba[i * 4 + 3] == 255);
    CHECK(px(opaque, 0, 0) == std::array<int, 4>{0, 0, 0, 255});
    CHECK(px(opaque, 8, 8) == std::array<int, 4>{255, 255, 255, 255});
}

TEST_CASE("fit_image: an image with alpha is composed over the background") {
    Image a = solid(2, 2, 255, 255, 255, 0);
    put(a, 0, 0, 255, 255, 255, 255);   // opaque white
    put(a, 1, 0, 255, 255, 255, 128);   // half transparent white
    Image f = fit_image(a, 2, 1.0f, Color::black());
    CHECK(px(f, 0, 0) == std::array<int, 4>{255, 255, 255, 255});
    CHECK(px(f, 1, 0)[0] == 128);                 // white over black at ~50%
    CHECK(px(f, 1, 0)[3] == 255);
    CHECK(px(f, 0, 1) == std::array<int, 4>{0, 0, 0, 255});  // fully transparent pixel: just the background
}

TEST_CASE("fit_image: edge cases") {
    CHECK(fit_image(solid(2, 2, 1, 2, 3, 255), 0, 1.0f, Color::white()).empty());
    Image just_bg = fit_image(Image{}, 3, 1.0f, Color::rgba8(10, 20, 30, 255));
    REQUIRE(just_bg.width == 3);
    CHECK(px(just_bg, 2, 2) == std::array<int, 4>{10, 20, 30, 255});
    // scale above 1 crops instead of failing
    Image crop = fit_image(solid(4, 4, 7, 7, 7, 255), 4, 2.0f, Color::black());
    CHECK(px(crop, 0, 0) == std::array<int, 4>{7, 7, 7, 255});
}

TEST_CASE("encode_png_rgb: no alpha channel in the file, same pixels when decoded") {
    Image a = solid(3, 2, 200, 100, 50, 255);
    auto png = encode_png_rgb(a);
    REQUIRE(png.size() > 33);
    // IHDR: 8 byte signature, 4 length, "IHDR", width, height, bit depth (24), colour type (25).
    CHECK(png[1] == 'P');
    CHECK(png[24] == 8);
    CHECK(png[25] == 2);  // 2 = RGB, 6 = RGBA
    auto rgba = encode_png(a);
    CHECK(rgba[25] == 6);
    auto back = decode_image(png.data(), png.size());
    REQUIRE(back.ok());
    CHECK(back->width == 3);
    CHECK(px(*back, 2, 1) == std::array<int, 4>{200, 100, 50, 255});
    CHECK(encode_png_rgb(Image{}).empty());
}

TEST_CASE("mip_chain: halves down to 1x1, averaging 2x2 pixels and repeating the edge of an odd size") {
    const std::vector<Image> one = mip_chain(solid(1, 1, 9, 8, 7, 6));
    REQUIRE(one.size() == 1);
    CHECK(px(one[0], 0, 0) == std::array<int, 4>{9, 8, 7, 6});

    Image quad = solid(2, 2, 0, 0, 0, 255);
    put(quad, 0, 0, 100, 0, 0, 255);
    put(quad, 1, 1, 100, 0, 0, 255);
    const std::vector<Image> two = mip_chain(quad);
    REQUIRE(two.size() == 2);
    CHECK(px(two[1], 0, 0) == std::array<int, 4>{50, 0, 0, 255});

    // 5x3 -> 2x1 -> 1x1; the odd last column and row are not dropped, they pair with themselves.
    Image odd = solid(5, 3, 40, 40, 40, 255);
    put(odd, 4, 2, 200, 40, 40, 255);
    const std::vector<Image> chain = mip_chain(odd);
    REQUIRE(chain.size() == 3);
    CHECK(chain[1].width == 2);
    CHECK(chain[1].height == 1);
    CHECK(chain[2].width == 1);
    CHECK(chain[2].height == 1);
    CHECK(chain[1].rgba.size() == 2 * 1 * 4);

    // A 1-pixel-wide strip keeps halving the other side.
    const std::vector<Image> strip = mip_chain(solid(1, 8, 1, 2, 3, 4));
    REQUIRE(strip.size() == 4);
    CHECK(strip.back().height == 1);
}

namespace {
// The first bytes of a KTX2 file: identifier, vkFormat, typeSize, pixelWidth, pixelHeight.
std::string ktx2_header(std::uint32_t w, std::uint32_t h) {
    std::string s("\xAB" "KTX 20" "\xBB\r\n\x1A\n", 12);
    for (std::uint32_t v : {0u, 1u, w, h})
        for (int i = 0; i < 4; ++i) s.push_back(char((v >> (8 * i)) & 255));
    return s;
}
}  // namespace

TEST_CASE("ktx2_size: reads the first level from the header, rejects anything else") {
    const std::string ok = ktx2_header(300, 17);
    auto size = ktx2_size(reinterpret_cast<const std::uint8_t*>(ok.data()), ok.size());
    REQUIRE(size.ok());
    CHECK(size->width == 300);
    CHECK(size->height == 17);

    CHECK_FALSE(ktx2_size(reinterpret_cast<const std::uint8_t*>(ok.data()), 20).ok());  // truncated
    std::string wrong = ok;
    wrong[1] = 'X';
    CHECK_FALSE(ktx2_size(reinterpret_cast<const std::uint8_t*>(wrong.data()), wrong.size()).ok());
    const std::string zero = ktx2_header(0, 4);
    CHECK_FALSE(ktx2_size(reinterpret_cast<const std::uint8_t*>(zero.data()), zero.size()).ok());
}

TEST_CASE("texture_size: the file, else the packed rectangle, else the header of the .ktx2 twin") {
    namespace stdfs = std::filesystem;
    const stdfs::path oldRoot = fs::project_root();
    const stdfs::path dir = fs::make_temp_dir("fa_test_texture_size");
    fs::set_project_root(dir);
    const auto write = [&](const char* rel, const std::string& data) {
        REQUIRE(fs::write_bytes(rel, data.data(), data.size()).ok());
    };

    REQUIRE(save_png(solid(6, 4, 1, 2, 3, 255), "assets/plain.png").ok());
    write("assets/twin.png.ktx2", ktx2_header(64, 32));
    write("assets.json",
          R"({"format": "factoria.assets/1", "assets": {"assets/packed.png": {"packed": {"atlas": "assets/atlases/a.png", "rect": [2, 2, 20, 10]}}}})");

    auto plain = texture_size("assets/plain.png");
    REQUIRE(plain.ok());
    CHECK(plain->width == 6);
    CHECK(plain->height == 4);
    auto twin = texture_size("assets/twin.png");  // only the twin exists: the export replaced the PNG
    REQUIRE(twin.ok());
    CHECK(twin->width == 64);
    CHECK(twin->height == 32);
    auto packed = texture_size("assets/packed.png");  // no file at all: it lives in an atlas
    REQUIRE(packed.ok());
    CHECK(packed->width == 20);
    CHECK(packed->height == 10);
    CHECK_FALSE(texture_size("assets/missing.png").ok());

    const assets::PackedTexture p = assets::packed_texture("assets/packed.png");
    CHECK(p.atlas == "assets/atlases/a.png");
    CHECK((p.x == 2 && p.y == 2 && p.w == 20 && p.h == 10));
    CHECK(assets::packed_texture("assets/plain.png").atlas.empty());

    fs::set_project_root(oldRoot);
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}
