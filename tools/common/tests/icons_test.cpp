// Icon generation: what load_icon_image says, and that every writer produces files a decoder reads back with the
// sizes, opacity and byte lengths the platforms expect.
#include <doctest.h>

#include <array>
#include <filesystem>

#include "fa/tooling/icons.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A w x h image: opaque red/blue split down the middle, with a fully transparent 1-pixel frame when `frame` is set.
Image make_icon(int w, int h, bool frame = false) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(std::size_t(w) * h * 4, 0);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            if (frame && (x == 0 || y == 0 || x == w - 1 || y == h - 1)) continue;
            std::uint8_t* p = &img.rgba[(std::size_t(y) * w + x) * 4];
            const bool left = x < w / 2;
            p[0] = left ? 255 : 0;
            p[1] = 0;
            p[2] = left ? 0 : 255;
            p[3] = 255;
        }
    return img;
}

std::array<int, 4> px(const Image& img, int x, int y) {
    const std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
    return {p[0], p[1], p[2], p[3]};
}

Image read_png(const std::string& path) {
    auto img = load_image(path);
    REQUIRE_MESSAGE(img.ok(), path);
    return *img;
}

std::uint32_t be32(const std::vector<std::uint8_t>& v, std::size_t o) {
    return (std::uint32_t(v[o]) << 24) | (std::uint32_t(v[o + 1]) << 16) | (std::uint32_t(v[o + 2]) << 8) | v[o + 3];
}
std::uint32_t le32(const std::vector<std::uint8_t>& v, std::size_t o) {
    return std::uint32_t(v[o]) | (std::uint32_t(v[o + 1]) << 8) | (std::uint32_t(v[o + 2]) << 16) | (std::uint32_t(v[o + 3]) << 24);
}
std::uint32_t le16(const std::vector<std::uint8_t>& v, std::size_t o) { return std::uint32_t(v[o]) | (std::uint32_t(v[o + 1]) << 8); }

}  // namespace

// ---------------------------------------------------------------------------------------------------- loading

TEST_CASE("icons: load_icon_image returns a square image and warns about shape and size") {
    testing::TempDir tmp;
    REQUIRE(save_png(make_icon(512, 512), tmp.sub("assets/ok.png")).ok());
    REQUIRE(save_png(make_icon(256, 256), tmp.sub("assets/small.png")).ok());
    REQUIRE(save_png(make_icon(600, 520), tmp.sub("assets/wide.png")).ok());

    std::vector<ExportSettingsIssue> warnings;
    auto ok = load_icon_image(tmp.str(), "assets/ok.png", "/icon", &warnings);
    REQUIRE(ok.ok());
    CHECK(ok->width == 512);
    CHECK(warnings.empty());

    auto small = load_icon_image(tmp.str(), "assets/small.png", "/icon", &warnings);
    REQUIRE(small.ok());
    REQUIRE(warnings.size() == 1);
    CHECK(warnings[0].pointer == "/icon");
    CHECK(warnings[0].message.find("256x256") != std::string::npos);
    CHECK(warnings[0].message.find("smaller than 512") != std::string::npos);
    CHECK(warnings[0].to_string().find("factoria.json#/icon:") == 0);

    warnings.clear();
    auto wide = load_icon_image(tmp.str(), "assets/wide.png", "/export/ios/icon", &warnings);
    REQUIRE(wide.ok());
    CHECK(wide->width == 600);  // padded to a square of the longer side
    CHECK(wide->height == 600);
    CHECK(px(*wide, 300, 300)[3] == 255);  // the picture is in the middle
    CHECK(px(*wide, 300, 10)[3] == 0);     // transparent above it
    REQUIRE(warnings.size() == 1);
    CHECK(warnings[0].message.find("not square") != std::string::npos);

    // the recommended size can be changed (adaptive layers: 432)
    warnings.clear();
    REQUIRE(load_icon_image(tmp.str(), "assets/small.png", "/icon", &warnings, 200).ok());
    CHECK(warnings.empty());
    // no warnings pointer is fine
    CHECK(load_icon_image(tmp.str(), "assets/small.png", "/icon").ok());
}

TEST_CASE("icons: load_icon_image errors say what to do") {
    testing::TempDir tmp;
    REQUIRE(save_png(make_icon(64, 64), tmp.sub("assets/icon.png")).ok());
    testing::write_all(tmp.sub("assets/broken.png"), "this is not a png");

    auto missing = load_icon_image(tmp.str(), "assets/icn.png", "/icon");
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("factoria.json#/icon: the icon file 'assets/icn.png' does not exist") != std::string::npos);
    CHECK(missing.error().hint.find("Did you mean 'assets/icon.png'?") != std::string::npos);

    auto nowhere = load_icon_image(tmp.str(), "nothing/icon.png", "/export/android/icon");
    REQUIRE_FALSE(nowhere.ok());
    CHECK(nowhere.error().message.find("#/export/android/icon") != std::string::npos);
    CHECK(nowhere.error().hint.find("square PNG or JPG") != std::string::npos);

    auto broken = load_icon_image(tmp.str(), "assets/broken.png", "/icon");
    REQUIRE_FALSE(broken.ok());
    CHECK(broken.error().message.find("cannot use 'assets/broken.png' as an icon") != std::string::npos);
    CHECK(broken.error().hint.find("PNG or JPG") != std::string::npos);

    auto dir = load_icon_image(tmp.str(), "assets", "/icon");
    REQUIRE_FALSE(dir.ok());
    CHECK(dir.error().message.find("is not a file") != std::string::npos);

    CHECK_FALSE(load_icon_image(tmp.str(), "", "/icon").ok());
}

TEST_CASE("icons: icon_color_from_hex") {
    Color c = icon_color_from_hex("#FF8000");
    CHECK(c.r == doctest::Approx(1.0f));
    CHECK(c.g == doctest::Approx(128.0f / 255.0f));
    CHECK(c.b == doctest::Approx(0.0f));
    CHECK(c.a == 1.0f);
    CHECK(icon_color_from_hex("nonsense", Color::black()) == Color::black());
    CHECK(icon_color_from_hex("#FFF", Color::black()) == Color::black());  // only "#RRGGBB"
}

// ---------------------------------------------------------------------------------------------------- icns

TEST_CASE("icons: make_icns writes every size as a PNG entry") {
    const std::vector<std::uint8_t> icns = make_icns(make_icon(1024, 1024));
    REQUIRE(icns.size() > 16);
    CHECK(std::string(icns.begin(), icns.begin() + 4) == "icns");
    CHECK(be32(icns, 4) == icns.size());  // total length includes the 8 header bytes

    const std::vector<std::pair<std::string, int>> expected = {{"icp4", 16},  {"icp5", 32},   {"icp6", 64},   {"ic07", 128},
                                                               {"ic08", 256}, {"ic09", 512},  {"ic10", 1024}, {"ic11", 32},
                                                               {"ic12", 64},  {"ic13", 256},  {"ic14", 512}};
    std::size_t at = 8;
    for (const auto& [type, size] : expected) {
        INFO("entry ", type);
        REQUIRE(at + 8 <= icns.size());
        CHECK(std::string(icns.begin() + std::ptrdiff_t(at), icns.begin() + std::ptrdiff_t(at) + 4) == type);
        const std::uint32_t len = be32(icns, at + 4);
        REQUIRE(at + len <= icns.size());
        auto img = decode_image(icns.data() + at + 8, len - 8);  // the payload is a PNG
        REQUIRE(img.ok());
        CHECK(img->width == size);
        CHECK(img->height == size);
        CHECK(px(*img, size / 4, size / 2)[0] == 255);      // red left half survived the resampling
        CHECK(px(*img, size * 3 / 4, size / 2)[2] == 255);  // blue right half
        at += len;
    }
    CHECK(at == icns.size());  // no bytes left over
}

TEST_CASE("icons: make_icns accepts a non-square or small icon") {
    const std::vector<std::uint8_t> icns = make_icns(make_icon(100, 60));
    CHECK(be32(icns, 4) == icns.size());
    auto first = decode_image(icns.data() + 16, be32(icns, 12) - 8);
    REQUIRE(first.ok());
    CHECK(first->width == 16);
    CHECK(first->height == 16);
}

// ---------------------------------------------------------------------------------------------------- ico / bmp

TEST_CASE("icons: icon_bmp_entry has the layout of an RT_ICON image") {
    for (int s : windows_icon_sizes()) {
        INFO("size ", s);
        const std::vector<std::uint8_t> e = icon_bmp_entry(make_icon(300, 300, /*frame=*/true), s);
        const std::size_t mask = std::size_t((s + 31) / 32) * 4 * std::size_t(s);
        CHECK(e.size() == 40 + std::size_t(s) * s * 4 + mask);
        CHECK(le32(e, 0) == 40);                      // BITMAPINFOHEADER
        CHECK(le32(e, 4) == std::uint32_t(s));        // width
        CHECK(le32(e, 8) == std::uint32_t(s) * 2);    // height counts the mask
        CHECK(le16(e, 12) == 1);                      // planes
        CHECK(le16(e, 14) == 32);                     // bits per pixel
        CHECK(le32(e, 16) == 0);                      // BI_RGB
        CHECK(le32(e, 20) == s * s * 4 + mask);
    }
    // the sizes the player's placeholder uses
    CHECK(windows_icon_sizes() == std::vector<int>{16, 24, 32, 48, 64, 128, 256});
}

TEST_CASE("icons: icon_bmp_entry pixels are bottom-up BGRA and the AND mask marks transparency") {
    // 2-pixel-wide picture is too small for a 16 px entry to keep exact, so use a flat colour: opaque orange with a
    // transparent top row.
    Image img;
    img.width = img.height = 16;
    img.rgba.assign(16 * 16 * 4, 0);
    for (int y = 1; y < 16; ++y)
        for (int x = 0; x < 16; ++x) {
            std::uint8_t* p = &img.rgba[(std::size_t(y) * 16 + x) * 4];
            p[0] = 255; p[1] = 128; p[2] = 0; p[3] = 255;
        }
    const std::vector<std::uint8_t> e = icon_bmp_entry(img, 16);
    // The first stored row is the BOTTOM row of the image: opaque orange as B, G, R, A.
    CHECK(e[40] == 0);
    CHECK(e[41] == 128);
    CHECK(e[42] == 255);
    CHECK(e[43] == 255);
    // The last stored pixel row is the top row: fully transparent.
    const std::size_t lastRow = 40 + std::size_t(15) * 16 * 4;
    CHECK(e[lastRow + 3] == 0);
    // AND mask: 4 bytes per row (16 px padded to 32 bits), bottom-up. The bottom row is opaque (bits 0), the top row
    // (the last stored) transparent (bits 1).
    const std::size_t maskStart = 40 + 16 * 16 * 4;
    CHECK(e[maskStart + 0] == 0x00);
    CHECK(e[maskStart + 1] == 0x00);
    CHECK(e[maskStart + 15 * 4 + 0] == 0xff);
    CHECK(e[maskStart + 15 * 4 + 1] == 0xff);
    CHECK(e[maskStart + 15 * 4 + 2] == 0x00);  // padding bits stay 0
}

TEST_CASE("icons: make_ico_bmp writes a directory and the entries it points at") {
    const std::vector<int> sizes = {16, 32, 256};
    const std::vector<std::uint8_t> ico = make_ico_bmp(make_icon(512, 512), sizes);
    CHECK(le16(ico, 0) == 0);
    CHECK(le16(ico, 2) == 1);  // icon
    CHECK(le16(ico, 4) == 3);
    std::size_t expectedOffset = 6 + 3 * 16;
    for (std::size_t i = 0; i < sizes.size(); ++i) {
        const std::size_t d = 6 + 16 * i;
        const int s = sizes[i];
        CHECK(ico[d] == (s == 256 ? 0 : s));  // 256 is written as 0
        CHECK(ico[d + 1] == (s == 256 ? 0 : s));
        CHECK(le16(ico, d + 4) == 1);
        CHECK(le16(ico, d + 6) == 32);
        const std::uint32_t bytes = le32(ico, d + 8), offset = le32(ico, d + 12);
        CHECK(offset == expectedOffset);
        CHECK(bytes == 40 + std::size_t(s) * s * 4 + std::size_t((s + 31) / 32) * 4 * std::size_t(s));
        CHECK(le32(ico, offset + 4) == std::uint32_t(s));  // the entry's own header agrees
        expectedOffset += bytes;
    }
    CHECK(expectedOffset == ico.size());
}

// ---------------------------------------------------------------------------------------------------- android

TEST_CASE("icons: write_android_icons writes mipmaps, round icons and the adaptive icon") {
    testing::TempDir tmp;
    const std::string res = tmp.sub("app/src/main/res");
    REQUIRE(write_android_icons(res, make_icon(1024, 1024), AdaptiveIcon{}).ok());

    struct D { const char* name; int legacy; int layer; };
    for (D d : {D{"mdpi", 48, 108}, D{"hdpi", 72, 162}, D{"xhdpi", 96, 216}, D{"xxhdpi", 144, 324}, D{"xxxhdpi", 192, 432}}) {
        INFO("density ", d.name);
        const std::string dir = res + "/mipmap-" + d.name;
        Image legacy = read_png(dir + "/ic_launcher.png");
        CHECK(legacy.width == d.legacy);
        CHECK(legacy.height == d.legacy);
        CHECK(px(legacy, 0, 0)[3] == 255);  // full-bleed square
        Image round = read_png(dir + "/ic_launcher_round.png");
        CHECK(round.width == d.legacy);
        CHECK(px(round, 0, 0)[3] == 0);                       // corners cut away
        CHECK(px(round, d.legacy / 2, d.legacy / 2)[3] == 255);
        Image fg = read_png(dir + "/ic_launcher_foreground.png");
        CHECK(fg.width == d.layer);
        CHECK(fg.height == d.layer);
        CHECK_FALSE(stdfs::exists(dir + "/ic_launcher_background.png"));
        CHECK_FALSE(stdfs::exists(dir + "/ic_launcher_monochrome.png"));
    }

    // The default foreground is the icon scaled into the 66dp safe zone of the 108dp layer: 264 of 432 px.
    Image fg = read_png(res + "/mipmap-xxxhdpi/ic_launcher_foreground.png");
    CHECK(px(fg, 0, 0)[3] == 0);
    CHECK(px(fg, 216, 216)[3] == 255);
    CHECK(px(fg, 216 - 131, 216)[3] == 255);  // inside: 216 - 132 = 84 is the first opaque column
    CHECK(px(fg, 216 - 134, 216)[3] == 0);
    CHECK(px(fg, 216 + 131, 216)[3] == 255);
    CHECK(px(fg, 216 + 134, 216)[3] == 0);

    const std::string xml = testing::read_all(res + "/mipmap-anydpi-v26/ic_launcher.xml");
    CHECK(xml.find("<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">") != std::string::npos);
    CHECK(xml.find("<background android:drawable=\"@color/ic_launcher_background\"/>") != std::string::npos);
    CHECK(xml.find("<foreground android:drawable=\"@mipmap/ic_launcher_foreground\"/>") != std::string::npos);
    CHECK(xml.find("monochrome") == std::string::npos);
    CHECK(testing::read_all(res + "/mipmap-anydpi-v26/ic_launcher_round.xml") == xml);
    const std::string colors = testing::read_all(res + "/values/ic_launcher_background.xml");
    CHECK(colors.find("<color name=\"ic_launcher_background\">#FFFFFF</color>") != std::string::npos);
}

TEST_CASE("icons: adaptive icon layers can be given: foreground, background image, monochrome, colour") {
    testing::TempDir tmp;
    const std::string res = tmp.sub("res");
    AdaptiveIcon a;
    a.foreground = make_icon(432, 432);
    a.backgroundImage = make_icon(432, 432);
    a.monochrome = make_icon(432, 432);
    REQUIRE(write_android_icons(res, make_icon(512, 512), a).ok());
    for (const char* d : {"mdpi", "xxxhdpi"}) {
        CHECK(stdfs::exists(res + "/mipmap-" + d + "/ic_launcher_background.png"));
        CHECK(stdfs::exists(res + "/mipmap-" + d + "/ic_launcher_monochrome.png"));
    }
    CHECK(read_png(res + "/mipmap-hdpi/ic_launcher_foreground.png").width == 162);
    CHECK(read_png(res + "/mipmap-hdpi/ic_launcher_background.png").width == 162);
    CHECK(read_png(res + "/mipmap-hdpi/ic_launcher_monochrome.png").width == 162);
    // an explicit foreground is used as is (not shrunk into the safe zone again): its corner is still opaque
    CHECK(px(read_png(res + "/mipmap-xxxhdpi/ic_launcher_foreground.png"), 0, 0)[3] == 255);
    const std::string xml = testing::read_all(res + "/mipmap-anydpi-v26/ic_launcher.xml");
    CHECK(xml.find("<background android:drawable=\"@mipmap/ic_launcher_background\"/>") != std::string::npos);
    CHECK(xml.find("<monochrome android:drawable=\"@mipmap/ic_launcher_monochrome\"/>") != std::string::npos);
    CHECK_FALSE(stdfs::exists(res + "/values/ic_launcher_background.xml"));  // an image replaces the colour

    // a colour background
    AdaptiveIcon c;
    c.backgroundColor = "#202020";
    const std::string res2 = tmp.sub("res2");
    REQUIRE(write_android_icons(res2, make_icon(512, 512), c).ok());
    CHECK(testing::read_all(res2 + "/values/ic_launcher_background.xml").find("#202020") != std::string::npos);
}

TEST_CASE("icons: load_adaptive_icon reads the layers named by the settings") {
    testing::TempDir tmp;
    REQUIRE(save_png(make_icon(432, 432), tmp.sub("assets/fg.png")).ok());
    REQUIRE(save_png(make_icon(432, 432), tmp.sub("assets/bg.png")).ok());
    REQUIRE(save_png(make_icon(300, 300), tmp.sub("assets/mono.png")).ok());

    AndroidExportSettings s;
    auto none = load_adaptive_icon(tmp.str(), s);
    REQUIRE(none.ok());
    CHECK_FALSE(none->foreground.has_value());
    CHECK_FALSE(none->backgroundImage.has_value());
    CHECK_FALSE(none->monochrome.has_value());
    CHECK(none->backgroundColor == "#FFFFFF");

    s.adaptiveIcon.foreground = "assets/fg.png";
    s.adaptiveIcon.background = "assets/bg.png";
    s.adaptiveIcon.monochrome = "assets/mono.png";
    std::vector<ExportSettingsIssue> warnings;
    auto all = load_adaptive_icon(tmp.str(), s, &warnings);
    REQUIRE(all.ok());
    CHECK(all->foreground.has_value());
    CHECK(all->backgroundImage.has_value());
    CHECK(all->monochrome.has_value());
    REQUIRE(warnings.size() == 1);  // 300 px is under the 432 px layer size
    CHECK(warnings[0].pointer == "/export/android/adaptiveIcon/monochrome");

    s.adaptiveIcon.background = "#112233";
    auto color = load_adaptive_icon(tmp.str(), s);
    REQUIRE(color.ok());
    CHECK_FALSE(color->backgroundImage.has_value());
    CHECK(color->backgroundColor == "#112233");

    s.adaptiveIcon.foreground = "assets/missing.png";
    auto bad = load_adaptive_icon(tmp.str(), s);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("#/export/android/adaptiveIcon/foreground") != std::string::npos);
}

TEST_CASE("icons: write_android_icons needs an icon") {
    testing::TempDir tmp;
    CHECK_FALSE(write_android_icons(tmp.sub("res"), Image{}, AdaptiveIcon{}).ok());
}

// ---------------------------------------------------------------------------------------------------- ios / linux

TEST_CASE("icons: write_ios_app_icon writes an opaque 1024 icon without an alpha channel") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("Assets.xcassets");
    // transparent in the middle, red elsewhere
    Image icon = make_icon(256, 256);
    for (int y = 96; y < 160; ++y)
        for (int x = 96; x < 160; ++x) icon.rgba[(std::size_t(y) * 256 + x) * 4 + 3] = 0;
    REQUIRE(write_ios_app_icon(dir, icon, Color::rgba8(0, 255, 0, 255)).ok());

    const Json top = *load_json_file(dir + "/Contents.json");
    CHECK(top["info"]["version"] == 1);
    const Json set = *load_json_file(dir + "/AppIcon.appiconset/Contents.json");
    REQUIRE(set["images"].size() == 1);
    CHECK(set["images"][0]["filename"] == "AppIcon-1024.png");
    CHECK(set["images"][0]["idiom"] == "universal");
    CHECK(set["images"][0]["platform"] == "ios");
    CHECK(set["images"][0]["size"] == "1024x1024");

    const std::string pngPath = dir + "/AppIcon.appiconset/AppIcon-1024.png";
    const std::string raw = testing::read_all(pngPath);
    REQUIRE(raw.size() > 33);
    CHECK(static_cast<unsigned char>(raw[25]) == 2);  // PNG colour type 2 (RGB): the file has no alpha channel
    Image png = read_png(pngPath);
    CHECK(png.width == 1024);
    CHECK(png.height == 1024);
    bool opaque = true;
    for (std::size_t i = 0; i < std::size_t(1024) * 1024; ++i) opaque = opaque && png.rgba[i * 4 + 3] == 255;
    CHECK(opaque);
    CHECK(px(png, 100, 100)[0] == 255);   // the picture
    CHECK(px(png, 512, 512)[1] == 255);   // the transparent hole shows the background (green)
    CHECK(px(png, 512, 512)[0] == 0);
}

TEST_CASE("icons: write_ios_app_icon ignores the alpha of the background colour") {
    testing::TempDir tmp;
    Image clear;
    clear.width = clear.height = 8;
    clear.rgba.assign(8 * 8 * 4, 0);
    REQUIRE(write_ios_app_icon(tmp.sub("a.xcassets"), clear, Color(0, 0, 1, 0)).ok());
    Image png = read_png(tmp.sub("a.xcassets/AppIcon.appiconset/AppIcon-1024.png"));
    CHECK(px(png, 5, 5) == std::array<int, 4>{0, 0, 255, 255});
}

TEST_CASE("icons: write_png_icon writes the size asked for") {
    testing::TempDir tmp;
    REQUIRE(write_png_icon(tmp.sub("linux/icon.png"), make_icon(900, 900), 256).ok());
    Image img = read_png(tmp.sub("linux/icon.png"));
    CHECK(img.width == 256);
    CHECK(img.height == 256);
    CHECK(px(img, 10, 128)[0] == 255);
    CHECK_FALSE(write_png_icon(tmp.sub("x.png"), Image{}, 256).ok());
    CHECK_FALSE(write_png_icon(tmp.sub("x.png"), make_icon(4, 4), 0).ok());
}
