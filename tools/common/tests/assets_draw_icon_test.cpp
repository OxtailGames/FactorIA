// assets.draw_icon: the icon and the Android foreground are drawn on the CPU and found by the export settings.
#include <doctest.h>

#include "asset_test_helpers.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/icons.h"

using namespace fa;
using namespace fa::testing;

namespace {

// A dark blue backdrop, a yellow disc with a white outline, and the letter I on top of it.
Json icon_spec() {
    return Json::parse(R"({
      "background": {"color": "#141428"},
      "layers": [
        {"type": "circle", "x": 50, "y": 50, "radius": 30, "fill": "#ffcc00", "outline": "#ffffff", "outlineWidth": 2},
        {"type": "text", "text": "I", "x": 50, "y": 50, "size": 40, "fill": "#000000"},
        {"type": "rect", "x": 0, "y": 90, "w": 100, "h": 10, "fill": "#00ff00", "foreground": false}
      ]})");
}

std::string message(const CommandResult& r) { return r.error["message"].get<std::string>(); }

}  // namespace

TEST_CASE("assets.draw_icon: draws a 1024 icon and a transparent adaptive foreground") {
    AssetsProject p;
    const Json r = p.ok("assets.draw_icon", icon_spec());
    CHECK(r["icon"] == "assets/icon.png");
    CHECK(r["foreground"] == "assets/icon_fg.png");

    const Image icon = read_png(p.file("assets/icon.png"));
    REQUIRE(icon.width == 1024);
    REQUIRE(icon.height == 1024);
    CHECK(get(icon, 5, 5) == Rgba{0x14, 0x14, 0x28, 255});    // backdrop
    CHECK(get(icon, 512, 330) == Rgba{255, 204, 0, 255});    // disc, above the letter
    CHECK(get(icon, 512, 1000) == Rgba{0, 255, 0, 255});     // ground strip (a background layer)
    int dark = 0;  // the letter is black on the yellow disc
    for (int y = 380; y < 640; ++y)
        for (int x = 440; x < 590; ++x) dark += get(icon, x, y).r < 60 ? 1 : 0;
    CHECK(dark > 500);
    const Rgba edge = get(icon, 512 + 307, 512);  // the disc edge is anti-aliased: neither fill nor backdrop
    CHECK(edge != Rgba{0x14, 0x14, 0x28, 255});

    const Image fg = read_png(p.file("assets/icon_fg.png"));
    REQUIRE(fg.width == 432);
    REQUIRE(fg.height == 432);
    CHECK(get(fg, 0, 0).a == 0);
    CHECK(get(fg, 431, 431).a == 0);
    CHECK(get(fg, 216, 216 - 40).a == 255);  // the disc is in the middle
    CHECK(get(fg, 216, 431 - 8).a == 0);     // the ground strip is not part of the foreground
    // Everything of the content sits inside the 66/108 safe zone of the layer (the disc has radius 30 of 100: 79 px).
    CHECK(get(fg, 216 - 75, 216).a == 255);
    CHECK(get(fg, 216 - 90, 216).a == 0);

    const Json prov = p.manifest()["assets"]["assets/icon.png"]["provenance"];
    CHECK(prov["origin"] == "original");
    CHECK(prov["ai"] == false);
    CHECK(p.manifest()["assets"].contains("assets/icon_fg.png"));
}

TEST_CASE("assets.draw_icon: same description, same bytes") {
    AssetsProject a, b;
    a.ok("assets.draw_icon", icon_spec());
    b.ok("assets.draw_icon", icon_spec());
    CHECK(read_all(a.file("assets/icon.png")) == read_all(b.file("assets/icon.png")));
}

TEST_CASE("assets.draw_icon: shapes, transparent backdrop, custom paths, no foreground") {
    AssetsProject p;
    const Json r = p.ok("assets.draw_icon",
                        {{"background", {{"shape", "transparent"}}},
                         {"layers", Json::array({Json::parse(R"({"type":"polygon","points":[[10,10],[90,10],[50,90]],"fill":"red"})"),
                                                 Json::parse(R"({"type":"roundRect","x":40,"y":2,"w":20,"h":6,"radius":3,"outline":"white"})"),
                                                 Json::parse(R"({"type":"ellipse","x":50,"y":95,"rx":20,"ry":3,"fill":"blue","softness":2})")})},
                         {"path", "assets/art/app.png"},
                         {"foreground", false}});
    CHECK(r["icon"] == "assets/art/app.png");
    CHECK_FALSE(r.contains("foreground"));
    CHECK_FALSE(p.exists("assets/icon_fg.png"));
    const Image icon = read_png(p.file("assets/art/app.png"));
    CHECK(get(icon, 2, 2).a == 0);                         // transparent backdrop
    CHECK(get(icon, 512, 200) == Rgba{255, 0, 0, 255});    // inside the triangle
    CHECK(get(icon, 100, 900).a == 0);                     // outside it
}

TEST_CASE("assets.draw_icon: unknown keys and types teach") {
    AssetsProject p;
    Json spec = icon_spec();
    spec["layers"][0]["radiu"] = 5;
    CommandResult r = p.call("assets.draw_icon", spec);
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("/layers/0/radiu") != std::string::npos);
    CHECK(r.error["hint"].get<std::string>().find("radius") != std::string::npos);

    spec = icon_spec();
    spec["layers"][1]["type"] = "triangle";
    r = p.call("assets.draw_icon", spec);
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("triangle") != std::string::npos);

    r = p.call("assets.draw_icon", {{"background", {{"color", "#fff"}, {"shape", "circel"}}}, {"layers", Json::array()}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["hint"].get<std::string>().find("circle") != std::string::npos);

    r = p.call("assets.draw_icon", {{"background", {{"color", "nope"}}}, {"layers", Json::array()}});
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("/background/color") != std::string::npos);
    CHECK_FALSE(p.exists("assets/icon.png"));  // nothing is written for a bad description
}

TEST_CASE("assets.draw_icon: the export settings find the files, and factoria.json is updated") {
    AssetsProject p;
    write_all(p.file("factoria.json"), R"({ "name": "Icon Game", "id": "com.example.icon", "version": "1.0.0" })");
    const Json r = p.ok("assets.draw_icon", icon_spec());
    CHECK(r["factoriaJsonUpdated"] == true);

    auto settings = load_export_settings(p.dir);
    REQUIRE(settings.ok());
    CHECK(settings->icon_for("windows") == "assets/icon.png");
    CHECK(settings->android.adaptiveIcon.foreground == "assets/icon_fg.png");
    auto icon = load_icon_image(p.dir, settings->icon_for("ios"), "/icon");
    REQUIRE(icon.ok());
    CHECK(icon->width == 1024);
    auto fg = load_icon_image(p.dir, settings->android.adaptiveIcon.foreground, "/export/android/adaptiveIcon/foreground");
    REQUIRE(fg.ok());
    CHECK(fg->width == 432);

    // With the paths already in factoria.json, the command writes there.
    write_all(p.file("factoria.json"),
              R"({ "name": "Icon Game", "icon": "assets/logo.png", "export": { "android": { "adaptiveIcon": { "foreground": "assets/logo_fg.png" } } } })");
    const Json again = p.ok("assets.draw_icon", icon_spec());
    CHECK(again["icon"] == "assets/logo.png");
    CHECK(again["foreground"] == "assets/logo_fg.png");
    CHECK(p.exists("assets/logo.png"));
}
