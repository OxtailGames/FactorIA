// assets.draw_capsules: the store images are cut at the store's sizes, around the focal point, with the logo where the
// asset's rule puts it.
#include <doctest.h>

#include <set>

#include "asset_test_helpers.h"
#include "fa/tooling/asset_capsules.h"

using namespace fa;
using namespace fa::testing;

namespace {

// 1920x1080: left half dark red, right half dark blue, a green square at (1500..1600, 950..1050), low in the picture.
Image key_art() {
    Image img = make_image(1920, 1080, {120, 20, 20, 255});
    fill_rect(img, 960, 0, 960, 1080, {20, 20, 120, 255});
    fill_rect(img, 1500, 950, 100, 100, {0, 255, 0, 255});
    return img;
}

}  // namespace

TEST_CASE("assets.draw_capsules: steam capsules have the store sizes, the focus decides the crop, the logo sits in the middle") {
    AssetsProject p;
    write_png(p.file("store/keyart.png"), key_art());
    write_png(p.file("assets/logo.png"), make_image(200, 80, {255, 255, 255, 255}));
    const Json r = p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","focus":[0.8,0.8],
        "logo":{"image":"assets/logo.png"},"stores":["steam"],"name":"demo"})"));

    const std::pair<const char*, std::pair<int, int>> expected[] = {
        {"demo_920x430", {920, 430}}, {"demo_462x174", {462, 174}}, {"demo_1232x706", {1232, 706}}, {"demo_748x896", {748, 896}},
        {"demo_1438x810", {1438, 810}}, {"demo_600x900", {600, 900}}, {"demo_3840x1240", {3840, 1240}},
        {"demo_1280x720", {1280, 720}}, {"demo_1920x1080", {1920, 1080}}};
    for (const auto& [file, size] : expected) {
        const std::string rel = std::string("store/capsules/steam/") + file + ".png";
        REQUIRE_MESSAGE(p.exists(rel), rel);
        const Image img = read_png(p.file(rel));
        CHECK(img.width == size.first);
        CHECK(img.height == size.second);
    }
    CHECK(r["written"].size() == 9);  // library header shares the header capsule's file

    // Header 920x430: 1920x1080 covers it by height... width scale 0.479, height 0.398: the width decides, and the whole
    // art width is visible, so only the vertical position follows the focus (low): the green square is in view.
    const Image header = read_png(p.file("store/capsules/steam/demo_920x430.png"));
    CHECK(get(header, 10, 10) == Rgba{120, 20, 20, 255});
    CHECK(get(header, 910, 10) == Rgba{20, 20, 120, 255});
    const int gx = 1550 * 920 / 1920;  // the green square's centre
    bool green = false;
    for (int y = 0; y < header.height; ++y) green = green || get(header, gx, y).g > 200;
    CHECK(green);
    // The logo: a white 200x80 image fitted into 70% x 50% of the capsule (644x215 box -> 537x215), centred.
    CHECK(get(header, 460, 215) == Rgba{255, 255, 255, 255});
    CHECK(get(header, 460, 215 + 100) == Rgba{255, 255, 255, 255});
    CHECK(get(header, 460, 215 + 120) != Rgba{255, 255, 255, 255});
    CHECK(get(header, 460 - 280, 215) != Rgba{255, 255, 255, 255});

    // A focus at the top keeps the green square out of the same crop.
    p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","focus":[0.5,0.0],"stores":["steam"],"name":"demo"})"));
    const Image top = read_png(p.file("store/capsules/steam/demo_920x430.png"));
    green = false;
    for (int y = 0; y < top.height; ++y) green = green || get(top, gx, y).g > 200;
    CHECK_FALSE(green);

    // Hero and page background carry no logo; the library logo is a transparent PNG with only the logo.
    p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logo":{"image":"assets/logo.png"},"stores":["steam"],"name":"demo"})"));
    const Image hero = read_png(p.file("store/capsules/steam/demo_3840x1240.png"));
    CHECK(get(hero, 1920, 620) != Rgba{255, 255, 255, 255});
    const Image logoOnly = read_png(p.file("store/capsules/steam/demo_1280x720.png"));
    CHECK(get(logoOnly, 5, 5).a == 0);
    CHECK(get(logoOnly, 640, 360) == Rgba{255, 255, 255, 255});
}

TEST_CASE("assets.draw_capsules: a text logo is drawn, no logo skips the logo-only assets, bad arguments teach") {
    AssetsProject p;
    write_png(p.file("store/keyart.png"), key_art());
    const Json r = p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logo":{"text":"Lantern Keep","fill":"#ffffff","outline":false},
        "stores":["itch"],"name":"demo"})"));
    REQUIRE(r["written"].size() == 1);
    CHECK(r["written"][0]["path"] == "store/capsules/itch/demo_630x500.png");
    const Image cover = read_png(p.file("store/capsules/itch/demo_630x500.png"));
    CHECK(cover.width == 630);
    CHECK(cover.height == 500);
    int white = 0;  // the title is white on the dark art, inside the middle of the cover
    for (int y = 150; y < 350; ++y)
        for (int x = 60; x < 570; ++x) white += get(cover, x, y).r > 200 && get(cover, x, y).g > 200 ? 1 : 0;
    CHECK(white > 500);
    CHECK(get(cover, 5, 5).a == 255);

    const Json nologo = p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","stores":["epic"],"name":"demo"})"));
    CHECK_FALSE(p.exists("store/capsules/epic/demo_960x540.png"));
    CHECK(nologo["skipped"].size() == 1);
    CHECK(p.exists("store/capsules/epic/demo_2560x1440.png"));

    CommandResult bad = p.call("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","stores":["stam"]})"));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("steam") != std::string::npos);  // did you mean
    bad = p.call("assets.draw_capsules", Json::parse(R"({"keyArt":"store/missing.png"})"));
    CHECK_FALSE(bad.ok);
    bad = p.call("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logo":{"text":"a","image":"b"}})"));
    CHECK_FALSE(bad.ok);

    // Portrait turns the phone screenshot sizes.
    p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","stores":["appstore"],"orientation":"portrait","name":"demo"})"));
    const Image shot = read_png(p.file("store/capsules/appstore/demo_1320x2868.png"));
    CHECK(shot.height == 2868);
}

TEST_CASE("store asset table: every store has assets and sizes in one store never clash") {
    for (const std::string& id : store_ids()) {
        const auto* assets = find_store_assets(id);
        REQUIRE(assets != nullptr);
        std::set<std::pair<int, int>> sizes;
        for (const StoreAsset& a : *assets) {
            const auto key = std::make_pair(a.width, a.height);
            for (const StoreAsset& b : *assets)  // the same size is one file, so it must be one rule
                if (&a != &b && a.width == b.width && a.height == b.height) {
                    CHECK(a.logo == b.logo);
                    CHECK(a.widthFraction == b.widthFraction);
                    CHECK(a.heightFraction == b.heightFraction);
                }
            sizes.insert(key);
        }
        CHECK(sizes.size() >= 1);
    }
    CHECK(find_store_assets("nope") == nullptr);
}

namespace {

struct Box {
    int x0 = 1 << 30, y0 = 1 << 30, x1 = -1, y1 = -1;  // x1, y1 inclusive
};

// The rectangle of the white pixels (the logo; the key art has none).
Box white_box(const Image& img) {
    Box b;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x)
            if (get(img, x, y) == Rgba{255, 255, 255, 255}) {
                b.x0 = std::min(b.x0, x);
                b.y0 = std::min(b.y0, y);
                b.x1 = std::max(b.x1, x);
                b.y1 = std::max(b.y1, y);
            }
    return b;
}

}  // namespace

TEST_CASE("assets.draw_capsules: logoAnchor and safeArea keep the logo inside its safe area") {
    AssetsProject p;
    write_png(p.file("store/keyart.png"), key_art());
    write_png(p.file("assets/logo.png"), make_image(200, 80, {255, 255, 255, 255}));
    const std::string rel = "store/capsules/itch/demo_630x500.png";  // itch cover: the logo fits 80% x 40%, centred by default

    p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logo":{"image":"assets/logo.png"},"stores":["itch"],"name":"demo"})"));
    Box b = white_box(read_png(p.file(rel)));
    CHECK(std::abs((b.x0 + b.x1) / 2 - 315) <= 2);  // the default: centred
    CHECK(std::abs((b.y0 + b.y1) / 2 - 250) <= 2);

    p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logo":{"image":"assets/logo.png"},"logoAnchor":"topRight",
        "stores":["itch"],"name":"demo"})"));
    b = white_box(read_png(p.file(rel)));
    CHECK(b.x1 >= int(630 * 0.95) - 2);  // against the default 5% safe area, at the top right
    CHECK(b.x1 <= int(630 * 0.95));
    CHECK(b.y0 >= int(500 * 0.05) - 1);
    CHECK(b.y0 <= int(500 * 0.05) + 2);

    p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logo":{"image":"assets/logo.png"},"logoAnchor":"bottomLeft",
        "safeArea":{"left":0.2,"bottom":0.25},"stores":["itch"],"name":"demo"})"));
    b = white_box(read_png(p.file(rel)));
    CHECK(b.x0 >= int(630 * 0.2) - 1);
    CHECK(b.x0 <= int(630 * 0.2) + 2);
    CHECK(b.y1 <= int(500 * 0.75));
    CHECK(b.y1 >= int(500 * 0.75) - 3);

    // A point of the safe area, and a safe area per store.
    p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logo":{"image":"assets/logo.png"},"logoAnchor":[1,1],
        "safeArea":{"itch":0.3},"stores":["itch","gog"],"name":"demo"})"));
    b = white_box(read_png(p.file(rel)));
    CHECK(b.x1 <= int(630 * 0.7));
    CHECK(b.x1 >= int(630 * 0.7) - 3);
    CHECK(b.y1 <= int(500 * 0.7));
    const Box gog = white_box(read_png(p.file("store/capsules/gog/demo_342x482.png")));  // no entry: the default 5%
    CHECK(gog.x1 <= int(342 * 0.95));
    CHECK(gog.x1 >= int(342 * 0.95) - 3);

    // Microsoft's poster keeps the bottom third free by default, even with the logo anchored at the bottom.
    p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logo":{"image":"assets/logo.png"},"logoAnchor":"bottom",
        "stores":["microsoft"],"name":"demo"})"));
    const Box poster = white_box(read_png(p.file("store/capsules/microsoft/demo_720x1080.png")));
    CHECK(poster.y1 <= int(1080 * (1 - 1.0 / 3.0)));

    // A logo bigger than the safe area is cut to fit it.
    p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logo":{"image":"assets/logo.png"},"safeArea":0.4,
        "stores":["itch"],"name":"demo"})"));
    b = white_box(read_png(p.file(rel)));
    CHECK(b.x0 >= int(630 * 0.4) - 1);
    CHECK(b.x1 <= int(630 * 0.6) + 1);
}

TEST_CASE("assets.draw_capsules: focus moves the logo when the art already has the capsule's proportions") {
    AssetsProject p;
    write_png(p.file("store/keyart.png"), make_image(1260, 1000, {20, 20, 120, 255}));  // the itch cover's 630:500
    write_png(p.file("assets/logo.png"), make_image(80, 80, {255, 255, 255, 255}));
    const std::string rel = "store/capsules/itch/demo_630x500.png";
    const auto centre = [&](const char* focus) {
        p.ok("assets.draw_capsules", Json::parse(std::string(R"({"keyArt":"store/keyart.png","logo":{"image":"assets/logo.png"},"stores":["itch"],"name":"demo")") +
                                                 (*focus ? std::string(R"(,"focus":)") + focus : std::string()) + "}"));
        const Box b = white_box(read_png(p.file(rel)));
        return std::pair((b.x0 + b.x1) / 2, (b.y0 + b.y1) / 2);
    };
    const auto none = centre("");
    CHECK(std::abs(none.first - 315) <= 2);
    CHECK(std::abs(centre("[0.5,0.5]").first - 315) <= 2);  // the middle leaves it
    const auto left = centre("[0.3,0.5]");
    CHECK(left.first < none.first - 100);  // 0.2 of 630 = 126 px to the left, kept inside the safe area
    CHECK(std::abs(left.second - none.second) <= 2);
    const auto low = centre("[0.5,0.9]");
    CHECK(low.second > none.second + 100);
    CHECK(low.second + 100 <= int(500 * 0.95));  // the logo's lower edge stays in the safe area
    // The art of another shape: focus keeps deciding only the crop, the logo stays where the rule puts it.
    write_png(p.file("store/wide.png"), key_art());
    p.ok("assets.draw_capsules", Json::parse(R"({"keyArt":"store/wide.png","logo":{"image":"assets/logo.png"},"focus":[0.2,0.5],"stores":["itch"],"name":"demo"})"));
    const Box wide = white_box(read_png(p.file(rel)));
    CHECK(std::abs((wide.x0 + wide.x1) / 2 - 315) <= 2);
}

TEST_CASE("assets.draw_capsules: logoAnchor and safeArea mistakes teach") {
    AssetsProject p;
    write_png(p.file("store/keyart.png"), key_art());
    CommandResult bad = p.call("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logoAnhor":"top"})"));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("logoAnchor") != std::string::npos);  // did you mean
    bad = p.call("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logoAnchor":"topRigth"})"));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("topRight") != std::string::npos);
    bad = p.call("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","logoAnchor":[2,0]})"));
    CHECK_FALSE(bad.ok);
    bad = p.call("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","safeArea":0.7})"));
    CHECK_FALSE(bad.ok);
    bad = p.call("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","safeArea":{"left":0.45,"right":0.45}})"));
    CHECK_FALSE(bad.ok);
    bad = p.call("assets.draw_capsules", Json::parse(R"({"keyArt":"store/keyart.png","safeArea":{"stam":0.1}})"));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("steam") != std::string::npos);
}
