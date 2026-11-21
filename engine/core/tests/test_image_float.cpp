#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <random>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/image_float.h"

using namespace fa;

namespace {

using Bytes = std::vector<std::uint8_t>;

Bytes text(const std::string& s) { return Bytes(s.begin(), s.end()); }

void append(Bytes& out, std::initializer_list<int> bytes) {
    for (int b : bytes) out.push_back(std::uint8_t(b));
}

const std::string kHeader = "#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n";

Bytes file_with(const std::string& resolution, const Bytes& pixels) {
    Bytes b = text(kHeader + resolution + "\n");
    b.insert(b.end(), pixels.begin(), pixels.end());
    return b;
}

// Seeded, platform independent floats in 0..range (mt19937 is specified by the standard; its distributions are not).
ImageF random_image(int w, int h, int channels, std::uint32_t seed, float range) {
    ImageF img = ImageF::create(w, h, channels).value();
    std::mt19937 rng(seed);
    for (float& v : img.data) {
        const float unit = float(rng() >> 8) / float(1 << 24);
        v = unit * unit * range;  // squared: many small values and a few large ones, as a sky has
    }
    return img;
}

// RGBE keeps 8 bits of the largest channel of a pixel: every channel is within 1/256 of it (a little more for float
// rounding).
void check_within_rgbe(const ImageF& a, const ImageF& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            const float* p = a.at(x, y);
            const float* q = b.at(x, y);
            const float maxc = std::max({p[0], p[1], p[2]});
            for (int c = 0; c < 3; ++c) {
                if (std::fabs(p[c] - q[c]) > maxc / 250.0f + 1.0e-30f) {
                    FAIL("pixel " << x << "," << y << " channel " << c << ": " << p[c] << " came back as " << q[c]);
                }
            }
        }
}

}  // namespace

TEST_CASE("hdr: random seeded pixels survive encode and decode within RGBE precision (RLE and flat widths)") {
    for (int w : {1, 5, 7, 8, 37, 300}) {
        ImageF img = random_image(w, 11, w % 2 ? 3 : 4, 1234u + std::uint32_t(w), 40.0f);
        // Runs: a constant block, so the encoder's run codes are used too.
        for (int y = 3; y < 6; ++y)
            for (int x = 0; x < w; ++x) img.set_pixel(x, y, Color{0.25f, 2.0f, 8.0f, 1.0f});
        const Bytes bytes = encode_hdr(img);
        REQUIRE_FALSE(bytes.empty());
        auto back = decode_hdr(bytes.data(), bytes.size());
        REQUIRE(back.ok());
        CHECK(back->channels == 3);
        CHECK(back->exposure == 1.0f);
        check_within_rgbe(img, *back);
        CHECK(encode_hdr(img) == bytes);  // deterministic
    }
}

TEST_CASE("hdr: special values: black, tiny, huge, negative, NaN and infinity") {
    ImageF img = ImageF::create(8, 1, 3).value();
    img.set_pixel(0, 0, Color{0, 0, 0});
    img.set_pixel(1, 0, Color{1.0e-30f, 2.0e-30f, 0.5e-30f});
    img.set_pixel(2, 0, Color{1.0e30f, 3.0e30f, 1.0f});
    img.set_pixel(3, 0, Color{-5.0f, 2.0f, 1.0f});
    img.set_pixel(4, 0, Color{std::nanf(""), 1.0f, 0.5f});
    img.set_pixel(5, 0, Color{INFINITY, 1.0f, 0.5f});
    img.set_pixel(6, 0, Color{0.99999f, 0.5f, 0.25f});  // the mantissa rounds up to 256: the exponent must move
    img.set_pixel(7, 0, Color{1.0f, 1.0f, 1.0f});
    const Bytes bytes = encode_hdr(img);
    auto back = decode_hdr(bytes.data(), bytes.size());
    REQUIRE(back.ok());
    CHECK(back->pixel(0, 0).r == 0.0f);
    CHECK(back->pixel(1, 0).g == doctest::Approx(2.0e-30f).epsilon(0.01));
    CHECK(back->pixel(2, 0).g == doctest::Approx(3.0e30f).epsilon(0.01));
    CHECK(back->pixel(3, 0).r == 0.0f);
    CHECK(back->pixel(3, 0).g == doctest::Approx(2.0f).epsilon(0.01));
    CHECK(back->pixel(4, 0).r == 0.0f);
    CHECK(back->pixel(4, 0).g == doctest::Approx(1.0f).epsilon(0.01));
    CHECK(std::isfinite(back->pixel(5, 0).r));
    CHECK(back->pixel(5, 0).r > 1.0e38f);
    CHECK(back->pixel(6, 0).r == doctest::Approx(1.0f).epsilon(0.01));
    CHECK(back->pixel(7, 0).b == 1.0f);
}

TEST_CASE("hdr: EXPOSURE is parsed, multiplied, recorded and written back") {
    const Bytes pixels = {128, 64, 32, 129};
    Bytes file =
        text("#?RGBE\nSOFTWARE=test\nEXPOSURE=2.5\n# a comment\nEXPOSURE=2\nFORMAT=32-bit_rle_rgbe\n\n-Y 1 +X 1\n");
    file.insert(file.end(), pixels.begin(), pixels.end());
    auto img = decode_hdr(file.data(), file.size());
    REQUIRE(img.ok());
    CHECK(img->exposure == doctest::Approx(5.0f));
    CHECK(img->pixel(0, 0).r ==
          doctest::Approx(1.0f));  // 128 * 2^(129 - 136); the pixels are not divided by the exposure
    CHECK(img->pixel(0, 0).g == doctest::Approx(0.5f));
    CHECK(img->pixel(0, 0).b == doctest::Approx(0.25f));
    const Bytes again = encode_hdr(*img);
    auto back = decode_hdr(again.data(), again.size());
    REQUIRE(back.ok());
    CHECK(back->exposure == doctest::Approx(5.0f));

    // CRLF line endings in the header, the "#?" signature of other programs and no FORMAT line.
    Bytes crlf = text("#?AUTOPANO\r\nGAMMA=1\r\n\r\n-Y 1 +X 1\r\n");
    crlf.insert(crlf.end(), pixels.begin(), pixels.end());
    CHECK(decode_hdr(crlf.data(), crlf.size()).ok());

    for (const char* bad : {"EXPOSURE=abc", "EXPOSURE=-1", "EXPOSURE=0", "EXPOSURE=", "EXPOSURE=1e999999"}) {
        Bytes f = text(std::string("#?RADIANCE\n") + bad + "\n\n-Y 1 +X 1\n");
        f.insert(f.end(), pixels.begin(), pixels.end());
        auto r = decode_hdr(f.data(), f.size());
        CHECK_FALSE(r.ok());
        if (!r) CHECK(r.error().message.find("EXPOSURE") != std::string::npos);
    }
}

TEST_CASE("hdr: a hand-made flat file (width below 8)") {
    Bytes px;
    append(px, {128, 64, 0, 129});   // 1.0, 0.5, 0
    append(px, {0, 0, 0, 0});        // black
    append(px, {255, 128, 1, 128});  // 255/256, 0.5, 1/256
    append(px, {10, 20, 30, 0});     // exponent 0: black whatever the mantissas
    const Bytes file = file_with("-Y 1 +X 4", px);
    auto img = decode_hdr(file.data(), file.size());
    REQUIRE(img.ok());
    REQUIRE(img->width == 4);
    REQUIRE(img->height == 1);
    CHECK(img->pixel(0, 0).r == 1.0f);
    CHECK(img->pixel(0, 0).g == 0.5f);
    CHECK(img->pixel(0, 0).b == 0.0f);
    CHECK(img->pixel(1, 0).r == 0.0f);
    CHECK(img->pixel(2, 0).r == doctest::Approx(255.0f / 256.0f));
    CHECK(img->pixel(2, 0).b == doctest::Approx(1.0f / 256.0f));
    CHECK(img->pixel(3, 0).g == 0.0f);
}

TEST_CASE("hdr: a hand-made new-style RLE file (runs and literals, one row of 8 and one of 200)") {
    Bytes px;
    append(px, {2, 2, 0, 8});
    append(px, {128 + 8, 128});               // R: 8 x 128
    append(px, {8, 1, 2, 3, 4, 5, 6, 7, 8});  // G: literal of 8
    append(px, {3, 0, 0, 255, 128 + 5, 7});   // B: literal 3, then a run of 5
    append(px, {128 + 8, 129});               // E: 8 x 129
    // Second row, 200 wide: every channel one run of 100 and one literal of 100 (a literal holds at most 128).
    Bytes row2;
    append(row2, {2, 2, 0, 200});
    for (int c = 0; c < 4; ++c) {
        append(row2, {128 + 100, c == 3 ? 129 : 64});
        row2.push_back(100);
        for (int i = 0; i < 100; ++i) row2.push_back(std::uint8_t(c == 3 ? 129 : 32));
    }
    // Rows of different widths cannot share a file: make two files.
    auto img = [&](int w, const Bytes& pixels) {
        const Bytes f = file_with("-Y 1 +X " + std::to_string(w), pixels);
        return decode_hdr(f.data(), f.size());
    };
    auto a = img(8, px);
    REQUIRE(a.ok());
    CHECK(a->pixel(0, 0).r == 1.0f);
    CHECK(a->pixel(7, 0).r == 1.0f);
    CHECK(a->pixel(0, 0).g == doctest::Approx(1.0f / 128.0f));
    CHECK(a->pixel(7, 0).g == doctest::Approx(8.0f / 128.0f));
    CHECK(a->pixel(2, 0).b == doctest::Approx(255.0f / 128.0f));
    CHECK(a->pixel(3, 0).b == doctest::Approx(7.0f / 128.0f));
    CHECK(a->pixel(7, 0).b == doctest::Approx(7.0f / 128.0f));
    auto b = img(200, row2);
    REQUIRE(b.ok());
    CHECK(b->pixel(0, 0).r == 0.5f);
    CHECK(b->pixel(199, 0).r == doctest::Approx(0.25f));  // 32 * 2^-7... = 0.25
    CHECK(b->pixel(99, 0).r == 0.5f);
    CHECK(b->pixel(100, 0).r == doctest::Approx(0.25f));

    // Two rows, the second flat although the file is 8 wide (the encoder never mixes them, the format allows it).
    Bytes mixed = px;
    for (int i = 0; i < 8; ++i) append(mixed, {128, 64, 0, 129});
    const Bytes f = file_with("-Y 2 +X 8", mixed);
    auto m = decode_hdr(f.data(), f.size());
    REQUIRE(m.ok());
    CHECK(m->pixel(5, 1).g == 0.5f);
}

TEST_CASE("hdr: old-style repeat markers (1, 1, 1, n) also at 256 times n") {
    Bytes px;
    append(px, {128, 64, 32, 129});
    append(px, {1, 1, 1, 255});  // 255 more copies: 256 pixels
    append(px, {1, 1, 1, 1});    // the next marker counts 1 << 8: 256 more
    const Bytes f = file_with("-Y 1 +X 512", px);
    auto img = decode_hdr(f.data(), f.size());
    REQUIRE(img.ok());
    CHECK(img->pixel(0, 0).r == 1.0f);
    CHECK(img->pixel(511, 0).b == 0.25f);

    Bytes first;
    append(first, {1, 1, 1, 4});
    const Bytes bad = file_with("-Y 1 +X 5", first);
    CHECK_FALSE(decode_hdr(bad.data(), bad.size()).ok());
    Bytes tooMany;
    append(tooMany, {128, 64, 32, 129, 1, 1, 1, 200});  // 201 pixels in a 5 wide row
    const Bytes bad2 = file_with("-Y 1 +X 5", tooMany);
    CHECK_FALSE(decode_hdr(bad2.data(), bad2.size()).ok());
}

TEST_CASE("hdr: headers that are refused teach what to do") {
    const Bytes pixels = {128, 64, 32, 129};
    auto refuse = [&](const Bytes& file, const char* mention) {
        auto r = decode_hdr(file.data(), file.size());
        REQUIRE_FALSE(r.ok());
        const std::string all = r.error().message + " " + r.error().hint;
        if (all.find(mention) == std::string::npos) FAIL("the error does not mention '" << mention << "': " << all);
        CHECK_FALSE(r.error().hint.empty());
    };
    auto with_res = [&](const std::string& res) { return file_with(res, pixels); };
    CHECK_FALSE(decode_hdr(nullptr, 0).ok());
    refuse(text("\x89PNG\r\n\x1a\n"), "#?RADIANCE");
    refuse(Bytes{0x76, 0x2f, 0x31, 0x01, 2, 0, 0, 0}, "OpenEXR");
    refuse(text("#?RADIANCE\nFORMAT=32-bit_rle_xyze\n\n-Y 1 +X 1\n"), "XYZE");
    refuse(text("#?RADIANCE\nFORMAT=whatever\n\n-Y 1 +X 1\n"), "FORMAT");
    refuse(with_res("+Y 1 +X 1"), "orientation");
    refuse(with_res("-Y 1 -X 1"), "orientation");
    refuse(with_res("+X 1 -Y 1"), "orientation");
    refuse(with_res("-Y 1 +X"), "resolution");
    refuse(with_res("-Y one +X 1"), "positive");
    refuse(with_res("-Y 0 +X 1"), "positive");
    refuse(with_res("-Y 1 +X 99999999999"), "positive");
    refuse(text("#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n"), "header");
    refuse(text("#?RADIANCE"), "header");
    refuse(Bytes(5000, 'a'), "#?RADIANCE");
    Bytes longLine = text("#?RADIANCE\n");
    longLine.insert(longLine.end(), 5000, 'a');
    refuse(longLine, "longer");
    Bytes manyLines = text("#?RADIANCE\n");
    for (int i = 0; i < 1500; ++i) {
        const Bytes comment = text("# a comment line of some length\n");
        manyLines.insert(manyLines.end(), comment.begin(), comment.end());
    }
    refuse(manyLines, "header is longer than 16384");
}

TEST_CASE("hdr: encode_hdr never writes an EXPOSURE that decode_hdr refuses") {
    for (float exposure : {1.0e35f, 1.0e-35f, 3.0e38f, 1.0e30f, 1.0e-30f}) {
        ImageF img = random_image(4, 2, 3, 3, 2.0f);
        img.exposure = exposure;
        const Bytes bytes = encode_hdr(img);
        auto back = decode_hdr(bytes.data(), bytes.size());
        REQUIRE(back.ok());
        CHECK(back->exposure >= 0.99e-30f);
        CHECK(back->exposure <= 1.01e30f);
    }
    for (float exposure : {0.0f, -2.0f, std::nanf(""), INFINITY}) {  // no usable exposure: no EXPOSURE line
        ImageF img = random_image(4, 2, 3, 3, 2.0f);
        img.exposure = exposure;
        const Bytes bytes = encode_hdr(img);
        auto back = decode_hdr(bytes.data(), bytes.size());
        REQUIRE(back.ok());
        CHECK(back->exposure == 1.0f);
    }
}

TEST_CASE("hdr: a header that claims too much is refused before any pixel memory is asked for") {
    const Bytes none;
    auto size_of = [&](const std::string& res) {
        const Bytes f = file_with(res, none);
        return decode_hdr(f.data(), f.size());
    };
    auto tall = size_of("-Y 100000 +X 100000");
    REQUIRE_FALSE(tall.ok());
    CHECK(tall.error().message.find("more than the 16384 pixels per side") != std::string::npos);
    auto big = size_of("-Y 16384 +X 16384");  // 3 GB of floats
    REQUIRE_FALSE(big.ok());
    CHECK(big.error().message.find("MB") != std::string::npos);
    CHECK(big.error().message.find("more than") != std::string::npos);
    // Inside the budget but with no data behind it: a truncation error at the first row, not an out-of-memory.
    auto empty = size_of("-Y 16384 +X 4096");
    REQUIRE_FALSE(empty.ok());
    CHECK(empty.error().message.find("row 1 of 16384") != std::string::npos);

    CHECK(image_float_bytes(0, 5, 3) == 0);
    CHECK(image_float_bytes(-1, 5, 3) == 0);
    CHECK(image_float_bytes(16384, 16384, 4) == std::uint64_t(16384) * 16384 * 16);
    CHECK(image_float_bytes(INT64_MAX, INT64_MAX, 4) == UINT64_MAX);
    CHECK(image_float_bytes(INT64_MAX, 4, 4) == UINT64_MAX);
    CHECK_FALSE(ImageF::create(0, 4, 3).ok());
    CHECK_FALSE(ImageF::create(4, 4, 2).ok());
    CHECK_FALSE(ImageF::create(16385, 1, 3).ok());
    CHECK_FALSE(ImageF::create(16384, 16384, 4).ok());
    CHECK(ImageF::create(64, 64, 4).ok());
}

TEST_CASE("hdr: every truncation of a valid file is an error that names a byte, and never crashes") {
    for (int w : {5, 40}) {
        ImageF img = random_image(w, 6, 3, 99u + std::uint32_t(w), 10.0f);
        for (int x = 0; x < w; ++x) img.set_pixel(x, 2, Color{1, 2, 3});
        const Bytes full = encode_hdr(img);
        REQUIRE(decode_hdr(full.data(), full.size()).ok());
        for (std::size_t n = 0; n < full.size(); ++n) {
            auto r = decode_hdr(full.data(), n);
            if (r.ok()) FAIL("a file cut to " << n << " of " << full.size() << " bytes decoded");
            CHECK(r.error().message.find("(at byte ") != std::string::npos);
        }
        // Trailing bytes after the last row are ignored.
        Bytes longer = full;
        longer.push_back(7);
        CHECK(decode_hdr(longer.data(), longer.size()).ok());
    }
}

TEST_CASE("hdr: corrupt bytes never crash (every byte of a small file replaced by several values)") {
    for (int w : {6, 24}) {
        ImageF img = random_image(w, 3, 3, 5u + std::uint32_t(w), 4.0f);
        const Bytes full = encode_hdr(img);
        for (std::size_t i = 0; i < full.size(); ++i)
            for (int value : {0, 1, 2, 127, 128, 129, 255}) {
                Bytes b = full;
                b[i] = std::uint8_t(value);
                auto r = decode_hdr(b.data(), b.size());
                if (r.ok()) {
                    CHECK(r->width >= 1);
                    CHECK(r->data.size() == std::size_t(r->width) * std::size_t(r->height) * 3);
                }
            }
    }
}

TEST_CASE("hdr: save_hdr and load_hdr go through the file layer, also under a folder with accents") {
    namespace stdfs = std::filesystem;
    // Puts the project root back and removes the folder even when a REQUIRE below ends the test early.
    struct RootGuard {
        stdfs::path oldRoot = fs::project_root();
        stdfs::path dir = fs::make_temp_dir("fa_test_hdr").value();
        RootGuard() { fs::set_project_root(dir); }
        ~RootGuard() {
            fs::set_project_root(oldRoot);
            std::error_code ec;
            stdfs::remove_all(dir, ec);
        }
    } guard;
    const stdfs::path& dir = guard.dir;
    const ImageF img = random_image(33, 9, 3, 77, 6.0f);
    const std::string rel = fs::path_to_utf8(stdfs::path(u8"assets/cañón niño/sky.hdr"));
    REQUIRE(save_hdr(img, rel).ok());
    REQUIRE(stdfs::exists(dir / stdfs::path(u8"assets/cañón niño/sky.hdr")));
    auto back = load_hdr(rel);
    REQUIRE(back.ok());
    check_within_rgbe(img, *back);

    auto missing = load_hdr("assets/none.hdr");
    CHECK_FALSE(missing.ok());
    REQUIRE(fs::write_bytes("assets/bad.hdr", "#?RADIANCE\n\n+Y 4 +X 4\n", 22).ok());
    auto bad = load_hdr("assets/bad.hdr");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("assets/bad.hdr") != std::string::npos);
    CHECK_FALSE(save_hdr(ImageF{}, "assets/empty.hdr").ok());
}

TEST_CASE("image_float: sRGB conversion round trips every byte") {
    CHECK(srgb_to_linear(0.0f) == 0.0f);
    CHECK(srgb_to_linear(1.0f) == 1.0f);
    CHECK(srgb_to_linear(0.5f) == doctest::Approx(0.2140f).epsilon(0.001));
    CHECK(linear_to_srgb(0.2140411f) == doctest::Approx(0.5f).epsilon(0.001));
    CHECK(linear_to_srgb(std::nanf("")) == 0.0f);
    CHECK(linear_to_srgb(7.0f) == 1.0f);
    CHECK(srgb_to_linear(-3.0f) == 0.0f);

    Image img;
    img.width = 16;
    img.height = 16;
    img.rgba.resize(16 * 16 * 4);
    for (std::size_t i = 0; i < 256; ++i) {
        img.rgba[i * 4 + 0] = std::uint8_t(i);
        img.rgba[i * 4 + 1] = std::uint8_t(255 - i);
        img.rgba[i * 4 + 2] = std::uint8_t((i * 7) & 255);
        img.rgba[i * 4 + 3] = std::uint8_t((i * 13) & 255);
    }
    for (bool srgb : {true, false}) {
        auto f = ImageF::from_image(img, srgb);
        REQUIRE(f.ok());
        CHECK(f->channels == 4);
        const Image back = f->to_image(srgb);
        CHECK(back.rgba == img.rgba);
    }
    auto lin = ImageF::from_image(img, true);
    CHECK(lin->pixel(0, 8).a ==
          doctest::Approx(float(img.rgba[128 * 4 + 3]) / 255.0f));  // pixel 128: alpha stays linear
    CHECK(lin->pixel(0, 8).r == doctest::Approx(srgb_to_linear(128.0f / 255.0f)));

    // Exposure scales the colour only; a value above 1 is white; RGB images get an opaque alpha.
    auto lit = ImageF::from_image(img, false, 4.0f, 3);
    REQUIRE(lit.ok());
    CHECK(lit->channels == 3);
    CHECK(lit->pixel(0, 0).a == 1.0f);
    CHECK(lit->pixel(15, 15).r == doctest::Approx(4.0f));
    const Image white = lit->to_image(false);
    CHECK(white.rgba[255 * 4] == 255);
    CHECK(white.rgba[255 * 4 + 3] == 255);
    const Image dim = lit->to_image(false, 0.25f);
    CHECK(dim.rgba[255 * 4] == img.rgba[255 * 4]);
    CHECK_FALSE(ImageF::from_image(Image{}, true).ok());
}

TEST_CASE("image_float: pixel access, bilinear sampling with clamp and wrap") {
    ImageF img = ImageF::create(2, 2, 4).value();
    img.set_pixel(0, 0, Color{0, 0, 0, 1});
    img.set_pixel(1, 0, Color{2, 0, 0, 1});
    img.set_pixel(0, 1, Color{0, 4, 0, 1});
    img.set_pixel(1, 1, Color{2, 4, 8, 0});
    CHECK(img.pixel(1, 1).b == 8.0f);
    CHECK(img.pixel(-1, 0).a == 0.0f);
    CHECK(img.pixel(2, 0).r == 0.0f);
    img.set_pixel(5, 5, Color{1, 1, 1, 1});  // ignored

    // Texel centres at 0.25 and 0.75.
    CHECK(img.sample(0.25f, 0.25f).r == doctest::Approx(0.0f));
    CHECK(img.sample(0.75f, 0.25f).r == doctest::Approx(2.0f));
    CHECK(img.sample(0.5f, 0.25f).r == doctest::Approx(1.0f));
    CHECK(img.sample(0.5f, 0.5f).g == doctest::Approx(2.0f));
    // Clamp: beyond the edge it is the edge texel; repeat: halfway between the last and the first texel.
    CHECK(img.sample(-3.0f, 0.25f).r == doctest::Approx(0.0f));
    CHECK(img.sample(5.0f, 0.25f).r == doctest::Approx(2.0f));
    CHECK(img.sample(0.0f, 0.25f, ImageWrap::Repeat).r == doctest::Approx(1.0f));
    CHECK(img.sample(1.0f, 0.25f, ImageWrap::Repeat).r == doctest::Approx(1.0f));
    CHECK(img.sample(1.25f, 0.25f, ImageWrap::Repeat).r == doctest::Approx(0.0f));
    CHECK(img.sample(-0.25f, 0.25f, ImageWrap::Repeat).r == doctest::Approx(2.0f));
    CHECK(std::isfinite(img.sample(std::nanf(""), INFINITY).r));
    CHECK(std::isfinite(img.sample(1.0e30f, -1.0e30f, ImageWrap::Repeat, ImageWrap::Repeat).r));
    CHECK(ImageF{}.sample(0.5f, 0.5f).a == 0.0f);

    ImageF rgb = ImageF::create(1, 1, 3).value();
    rgb.set_pixel(0, 0, Color{1, 2, 3, 0.25f});
    CHECK(rgb.pixel(0, 0).a == 1.0f);
    CHECK(rgb.sample(0.5f, 0.5f).b == doctest::Approx(3.0f));
}

TEST_CASE("image_float: resized averages by area when shrinking and is bilinear when enlarging") {
    ImageF img = ImageF::create(4, 2, 3).value();
    for (int y = 0; y < 2; ++y)
        for (int x = 0; x < 4; ++x) img.set_pixel(x, y, Color{float(x + 4 * y), 1.0f, 100.0f * float(y)});
    auto half = img.half_size();
    REQUIRE(half.ok());
    REQUIRE(half->width == 2);
    REQUIRE(half->height == 1);
    CHECK(half->pixel(0, 0).r == doctest::Approx((0 + 1 + 4 + 5) / 4.0f));
    CHECK(half->pixel(1, 0).r == doctest::Approx((2 + 3 + 6 + 7) / 4.0f));
    CHECK(half->pixel(0, 0).b == doctest::Approx(50.0f));

    auto third = img.resized(3, 1);  // 4/3 source pixels per destination pixel
    REQUIRE(third.ok());
    float sum = 0;
    for (int x = 0; x < 3; ++x) sum += third->pixel(x, 0).g;
    CHECK(sum == doctest::Approx(3.0f));  // weights sum to 1: a constant stays constant
    CHECK(third->pixel(0, 0).r ==
          doctest::Approx(2.25f));  // rows: (0 + 1/3) / (4/3) = 0.25 and (4 + 5/3) / (4/3) = 4.25

    auto big = img.resized(8, 4);
    REQUIRE(big.ok());
    CHECK(big->pixel(0, 0).r == doctest::Approx(0.0f));
    CHECK(big->pixel(7, 3).r == doctest::Approx(7.0f));
    CHECK(big->pixel(1, 0).r == doctest::Approx(0.25f).epsilon(0.01));  // between 0 and 1 at 1/4

    auto same = img.resized(4, 2);
    REQUIRE(same.ok());
    CHECK(same->data == img.data);
    auto one = ImageF::create(1, 1, 3).value().half_size();
    REQUIRE(one.ok());
    CHECK(one->width == 1);
    CHECK_FALSE(img.resized(0, 2).ok());
    CHECK_FALSE(ImageF{}.resized(2, 2).ok());
}

TEST_CASE("hdr: hdr_info reads the size and the exposure from the header alone, and teaches on a file that is not "
          "Radiance's") {
    const std::string text = "#?RADIANCE\nFORMAT=32-bit_rle_rgbe\nEXPOSURE=2\n\n-Y 1024 +X 2048\n";
    const std::vector<std::uint8_t> head(text.begin(), text.end());  // no pixels at all
    auto info = hdr_info(head.data(), head.size());
    REQUIRE(info.ok());
    CHECK(info->width == 2048);
    CHECK(info->height == 1024);
    CHECK(info->exposure == doctest::Approx(2.0f));
    CHECK_FALSE(decode_hdr(head.data(), head.size()).ok());  // the pixels are what is missing, not the header
    const std::string junk = "this is not a radiance file, it is a sentence";
    auto bad = hdr_info(reinterpret_cast<const std::uint8_t*>(junk.data()), junk.size());
    REQUIRE_FALSE(bad.ok());
    CHECK_FALSE(bad.error().message.empty());
}

TEST_CASE("hdr: a decode limit refuses a picture from its header; a file bad in its last row makes no pixel buffer") {
    // 4096 x 2048 floats are 96 MB: inside the default budget, over a 64 MB limit.
    const Bytes f = file_with("-Y 2048 +X 4096", Bytes{});
    auto limited = decode_hdr(f.data(), f.size(), std::uint64_t(64) << 20);
    REQUIRE_FALSE(limited.ok());
    CHECK(limited.error().message.find("more than the 64 MB") != std::string::npos);
    CHECK_FALSE(hdr_info(f.data(), f.size(), std::uint64_t(64) << 20).ok());
    CHECK(hdr_info(f.data(), f.size()).ok());
    CHECK(hdr_info(f.data(), f.size(), ~std::uint64_t(0)).ok());  // above kMaxImageFloatBytes: the budget itself

    // A real small picture decodes under a small limit, and the buffer is exactly the picture (no spare capacity from growth).
    Bytes px;
    append(px, {128, 64, 32, 129});
    append(px, {1, 1, 1, 255});  // 256 pixels
    const Bytes ok = file_with("-Y 1 +X 256", px);
    auto small = decode_hdr(ok.data(), ok.size(), 4096);
    REQUIRE(small.ok());
    CHECK(small->data.size() == 256 * 3);
    CHECK(small->data.capacity() == small->data.size());
    CHECK_FALSE(decode_hdr(ok.data(), ok.size(), 3071).ok());  // 256 x 1 x 3 floats are 3072 bytes

    // Rows that are right except the last one, which is cut short: the first pass finds it (the error names the row).
    Bytes rows;
    for (int y = 0; y < 63; ++y) {
        append(rows, {128, 64, 32, 129});
        append(rows, {1, 1, 1, 255});
    }
    append(rows, {128, 64, 32, 129});
    const Bytes badLast = file_with("-Y 64 +X 256", rows);
    auto r = decode_hdr(badLast.data(), badLast.size());
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("row 64 of 64") != std::string::npos);
}

TEST_CASE("hdr: the EXPOSURE is deterministic and within a few ulp of its text") {
    auto exposure_of = [](const std::string& value) {
        const Bytes f = text("#?RADIANCE\nEXPOSURE=" + value + "\n\n-Y 1 +X 1\n" + std::string("\x80\x80\x80\x81", 4));
        auto img = decode_hdr(f.data(), f.size());
        REQUIRE(img.ok());
        return img->exposure;
    };
    CHECK(exposure_of("2") == 2.0f);
    CHECK(exposure_of("0.5") == 0.5f);
    CHECK(exposure_of("1e-3") == doctest::Approx(0.001f).epsilon(1e-6));
    CHECK(exposure_of("0.1") == doctest::Approx(0.1f).epsilon(1e-6));
    CHECK(exposure_of("3.14159265358979") == doctest::Approx(3.14159265f).epsilon(1e-6));
    CHECK(exposure_of("0.1") == exposure_of("0.1"));  // the same bits every time
}
