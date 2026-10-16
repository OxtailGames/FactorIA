// The palette lock: fa/tooling/palette.h.
#include <doctest.h>

#include "fa/core/fs.h"
#include "fa/tooling/palette.h"
#include "test_helpers.h"

using namespace fa;

namespace {

// Project-relative reads go to `dir` while this lives.
struct ProjectRoot {
    std::filesystem::path previous = fs::project_root();
    explicit ProjectRoot(const std::filesystem::path& dir) { fs::set_project_root(dir); }
    ~ProjectRoot() { fs::set_project_root(previous); }
};

Image strip(std::initializer_list<std::array<std::uint8_t, 4>> pixels) {
    Image img;
    img.width = static_cast<int>(pixels.size());
    img.height = 1;
    for (const auto& p : pixels) img.rgba.insert(img.rgba.end(), p.begin(), p.end());
    return img;
}

}  // namespace

TEST_CASE("load_palette: a list of #rrggbb colours") {
    auto palette = load_palette(Json::parse(R"(["#000000","#FFffff","#1a1c2c"])"));
    REQUIRE(palette.ok());
    REQUIRE(palette->size() == 3);
    CHECK((*palette)[1] == std::array<std::uint8_t, 3>{255, 255, 255});
    CHECK((*palette)[2] == std::array<std::uint8_t, 3>{0x1a, 0x1c, 0x2c});

    auto bad = load_palette(Json::parse(R"(["#000000","red"])"));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message == "palette colour 1 is 'red', not a colour like \"#1a1c2c\"");
    CHECK_FALSE(bad.error().hint.empty());
    CHECK_FALSE(load_palette(Json::parse(R"(["#000000","#12345"])")).ok());
    CHECK_FALSE(load_palette(Json::parse(R"(["#000000",5])")).ok());
    CHECK_FALSE(load_palette(Json::parse(R"(["#000000"])")).ok());  // one colour is not a palette
    CHECK_FALSE(load_palette(Json::parse("12")).ok());
}

TEST_CASE("load_palette: the distinct opaque colours of an image") {
    testing::TempDir tmp;
    ProjectRoot root(tmp.path);
    Image img = strip({{255, 0, 0, 255}, {255, 0, 0, 255}, {0, 0, 255, 255}, {9, 9, 9, 0}});  // the transparent pixel is no colour
    REQUIRE(save_png(img, "palette.png").ok());
    auto palette = load_palette(Json("palette.png"));
    REQUIRE(palette.ok());
    REQUIRE(palette->size() == 2);
    CHECK((*palette)[0] == std::array<std::uint8_t, 3>{255, 0, 0});
    CHECK((*palette)[1] == std::array<std::uint8_t, 3>{0, 0, 255});

    auto missing = load_palette(Json("nope.png"));
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("'nope.png'") != std::string::npos);

    Image many;
    many.width = 300;
    many.height = 1;
    for (int i = 0; i < 300; ++i) many.rgba.insert(many.rgba.end(), {std::uint8_t(i % 256), std::uint8_t(i / 256), 0, 255});
    REQUIRE(save_png(many, "many.png").ok());
    auto tooMany = load_palette(Json("many.png"));
    REQUIRE_FALSE(tooMany.ok());
    CHECK(tooMany.error().message.find("more than 256 colours") != std::string::npos);
    CHECK(tooMany.error().hint.find("at most 256") != std::string::npos);
}

TEST_CASE("quantize_to_palette: nearest colour, alpha kept") {
    const Palette palette = {{0, 0, 0}, {255, 255, 255}, {200, 30, 30}};
    const Image src = strip({{10, 10, 10, 255}, {240, 250, 245, 128}, {190, 60, 20, 0}, {255, 0, 0, 255}});
    const Image out = quantize_to_palette(src, palette);
    REQUIRE(out.width == 4);
    REQUIRE(out.rgba.size() == src.rgba.size());
    CHECK(out.rgba[0] == 0);
    CHECK(out.rgba[3] == 255);
    CHECK(out.rgba[4] == 255);  // nearly white -> white, and the half-transparent alpha stays
    CHECK(out.rgba[7] == 128);
    CHECK(out.rgba[8] == 200);  // reddish -> the red of the palette, transparent stays transparent
    CHECK(out.rgba[11] == 0);
    CHECK(out.rgba[12] == 200);
    CHECK(out.rgba[13] == 30);
    CHECK(quantize_to_palette(src, {}).rgba == src.rgba);  // no palette: unchanged
    CHECK(quantize_to_palette(out, palette).rgba == out.rgba);  // idempotent
}
