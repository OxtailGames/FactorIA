// game.screenshot region / zoom / filmstrip / temporary files, render.inspect and render.pick.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/screenshot_files.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Shot Test",
  "id": "com.example.shottest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// Pixel-perfect 320x180 view, origin at the centre: x = 160 + worldX, y = 90 - worldY.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#202020" } } },
    { "id": "left", "components": { "Transform": { "position": [-25, 0, 0] },
                                    "Shape2D": { "size": [50, 40], "color": "#808080" } } },
    { "id": "right", "components": { "Transform": { "position": [25, 0, 0] },
                                     "Shape2D": { "size": [50, 40], "color": "#c0c0c0" } } },
    { "id": "mover", "components": { "Transform": { "position": [-150, 60, 0] },
                                     "Shape2D": { "size": [10, 10], "color": "#ff0000", "layer": 9 } } }
  ]
})";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const char* scene = kScene) {
        dir = fs::make_temp_dir("fa_shot_test_" + name);
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << scene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

EngineConfig headless_cfg(const TempProject& p) {
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    return c;
}

std::array<int, 3> rgb(const Image& img, int x, int y) {
    const std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
    return {p[0], p[1], p[2]};
}

}  // namespace

TEST_CASE("game.screenshot: region and zoom give round(w * zoom) x round(h * zoom), sharp up to 4x and blocky above") {
    TempProject p("region");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(headless_cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    e.step(1);
    auto shot = [&](Json args) {
        args["path"] = (p.dir / "r.png").generic_string();
        auto r = c.call("game.screenshot", args);
        INFO(r.error.dump());
        REQUIRE(r.ok);
        auto img = load_image((p.dir / "r.png").generic_string());
        REQUIRE(img.ok());
        CHECK(r.result["width"] == img->width);
        CHECK(r.result["height"] == img->height);
        return *img;
    };
    // The edge between the grey boxes is at design x = 160 (#808080 on the left, #c0c0c0 on the right).
    Image z4 = shot(Json{{"region", Json::array({150, 80, 20, 10})}, {"zoom", 4}});
    CHECK(z4.width == 80);
    CHECK(z4.height == 40);
    CHECK(rgb(z4, 39, 20)[0] == doctest::Approx(0x80).epsilon(0.03));  // left of x = 160 (160-150 = 10 -> 40 px)
    CHECK(rgb(z4, 41, 20)[0] == doctest::Approx(0xc0).epsilon(0.03));
    // Above 4x: still the exact size, the edge is a hard block at a multiple of the 4x pixel.
    Image z8 = shot(Json{{"region", Json::array({150, 80, 20, 10})}, {"zoom", 8}});
    CHECK(z8.width == 160);
    CHECK(z8.height == 80);
    CHECK(rgb(z8, 79, 40)[0] == doctest::Approx(0x80).epsilon(0.03));
    CHECK(rgb(z8, 81, 40)[0] == doctest::Approx(0xc0).epsilon(0.03));
    Image z32 = shot(Json{{"region", Json::array({155, 85, 10, 5})}, {"zoom", 32}});
    CHECK(z32.width == 320);
    CHECK(z32.height == 160);
    // Fractional zoom and the whole view with zoom.
    CHECK(shot(Json{{"region", Json::array({150, 80, 20, 10})}, {"zoom", 0.5}}).width == 10);
    Image whole = shot(Json{{"zoom", 2}});
    CHECK(whole.width == 640);
    CHECK(whole.height == 360);
    // A region that sticks out of the view is clamped to it.
    Image clamped = shot(Json{{"region", Json::array({300, 160, 100, 100})}, {"zoom", 2}});
    CHECK(clamped.width == 40);
    CHECK(clamped.height == 40);
    // The game is unchanged afterwards.
    CHECK(e.renderer()->target_width() == 320);

    // Mistakes teach.
    for (Json bad : {Json{{"region", Json::array({0, 0, 10, 10})}, {"zoom", 50}}, Json{{"region", Json::array({400, 0, 10, 10})}},
                     Json{{"region", Json::array({0, 0, 0, 10})}}, Json{{"zoom", 2}, {"scale", 2}},
                     Json{{"region", Json::array({0, 0, 320, 180})}, {"zoom", 32}}, Json{{"columns", 2}}, Json{{"regoin", Json::array({0, 0, 1, 1})}}}) {
        auto r = c.call("game.screenshot", bad);
        INFO(bad.dump());
        CHECK_FALSE(r.ok);
        CHECK_FALSE(r.error.dump().empty());
    }
    CHECK(c.call("game.screenshot", Json{{"regoin", Json::array({0, 0, 1, 1})}}).error.dump().find("region") != std::string::npos);
}

TEST_CASE("game.screenshot: without path the picture is temporary, with path it is kept, and an old one is pruned at init") {
    TempProject p("temp");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(headless_cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    e.step(3);
    auto r = c.call("game.screenshot", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["temporary"] == true);
    CHECK_FALSE(r.result.contains("path"));  // no path promised as persistent
    CHECK(r.result["$image"]["temporary"] == true);
    CHECK(r.result["note"].get<std::string>().find("path") != std::string::npos);
    const stdfs::path file = r.result["$image"]["path"].get<std::string>();
    CHECK(file.filename() == "frame_3.png");
    CHECK(stdfs::exists(file));
    // A consumer that attached the image deletes it with discard_temporary_image.
    CHECK(discard_temporary_image(r.result["$image"], p.dir));
    CHECK_FALSE(stdfs::exists(file));
    // Other kinds of picture have their own names, so one does not overwrite the other.
    auto reg = c.call("game.screenshot", Json{{"region", Json::array({0, 0, 40, 20})}, {"zoom", 2}});
    REQUIRE(reg.ok);
    CHECK(stdfs::path(reg.result["$image"]["path"].get<std::string>()).filename() == "frame_3_region.png");
    // With a path: kept, `path` in the result, no temporary flag.
    const std::string mine = (p.dir / ".factoria" / "screenshots" / "mine.png").generic_string();
    auto kept = c.call("game.screenshot", Json{{"path", mine}});
    REQUIRE(kept.ok);
    CHECK(kept.result["path"] == mine);
    CHECK_FALSE(kept.result.contains("temporary"));
    CHECK_FALSE(kept.result["$image"].contains("temporary"));
    CHECK_FALSE(discard_temporary_image(kept.result["$image"], p.dir));
    CHECK(stdfs::exists(mine));
    e.shutdown();

    // Opening the project again removes engine-named shots older than 3 days, not the user's.
    const stdfs::path shots = p.dir / ".factoria" / "screenshots";
    std::ofstream(shots / "frame_77.png", std::ios::binary) << "x";
    stdfs::last_write_time(shots / "frame_77.png", stdfs::file_time_type::clock::now() - std::chrono::hours(24 * 10));
    stdfs::last_write_time(mine, stdfs::file_time_type::clock::now() - std::chrono::hours(24 * 10));
    Engine again;
    REQUIRE_MESSAGE(again.init(headless_cfg(p), nullptr, &err), err);
    CHECK_FALSE(stdfs::exists(shots / "frame_77.png"));
    CHECK(stdfs::exists(mine));
}

TEST_CASE("game.screenshot: a filmstrip steps the game and lays the captures out in a labelled grid") {
    TempProject p("film");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(headless_cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    e.step(2);
    const int start = int(c.call("game.step", Json{{"frames", 0}}).result["frame"]);
    // Tile size = region size * zoom; 13 tiles in 4 columns.
    auto r = c.call("game.screenshot", Json{{"frames", 48}, {"everyFrames", 4}, {"columns", 4}, {"zoom", 1},
                                            {"region", Json::array({100, 60, 120, 60})}, {"path", (p.dir / "film.png").generic_string()}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["tiles"].size() == 13);
    CHECK(r.result["tiles"][0]["offset"] == 0);
    CHECK(r.result["tiles"][0]["frame"] == start);
    CHECK(r.result["tiles"][1]["offset"] == 4);
    CHECK(r.result["tiles"][12]["frame"] == start + 48);
    CHECK(r.result["frame"] == start + 48);  // the game really advanced
    CHECK(r.result["columns"] == 4);
    CHECK(r.result["rows"] == 4);
    CHECK(r.result["tileWidth"] == 120);
    CHECK(r.result["tileHeight"] == 60);
    const int gap = int(r.result["width"]) - 4 * 120;  // 5 gaps
    CHECK(gap % 5 == 0);
    CHECK(r.result["height"] == 4 * 60 + gap);
    auto img = load_image((p.dir / "film.png").generic_string());
    REQUIRE(img.ok());
    CHECK(img->width == r.result["width"]);
    // The first tile shows the grey boxes: below the label, the pixel at design (160, 90) is #c0c0c0 on the right of the edge.
    const int g = gap / 5;
    CHECK(rgb(*img, g + (165 - 100), g + (90 - 60))[0] == doctest::Approx(0xc0).epsilon(0.03));
    // The label of the first tile is drawn in its top-left corner (white pixels).
    bool white = false;
    for (int y = 0; y < 14; ++y)
        for (int x = 0; x < 30; ++x) white |= rgb(*img, g + x, g + y) == std::array<int, 3>{255, 255, 255};
    CHECK(white);

    // Without zoom the tiles are sized so the sheet is about 2048 px wide at most, never enlarged; temporary file name.
    auto auto_zoom = c.call("game.screenshot", Json{{"frames", 4}, {"everyFrames", 2}});
    REQUIRE_MESSAGE(auto_zoom.ok, auto_zoom.error.dump());
    CHECK(auto_zoom.result["tiles"].size() == 3);
    CHECK(auto_zoom.result["width"].get<int>() <= 2100);
    CHECK(auto_zoom.result["zoom"].get<double>() <= 1.0);
    CHECK(stdfs::path(auto_zoom.result["$image"]["path"].get<std::string>()).filename().string().find("_sheet.png") != std::string::npos);
    CHECK(auto_zoom.result["temporary"] == true);

    // Limits teach: too many tiles, a sheet over 8192 px, everyFrames without frames.
    auto many = c.call("game.screenshot", Json{{"frames", 200}, {"everyFrames", 1}});
    REQUIRE_FALSE(many.ok);
    CHECK(many.error.dump().find("everyFrames") != std::string::npos);
    auto huge = c.call("game.screenshot", Json{{"frames", 20}, {"everyFrames", 1}, {"zoom", 8}, {"columns", 8}});
    REQUIRE_FALSE(huge.ok);
    CHECK(huge.error.dump().find("8192") != std::string::npos);
    CHECK_FALSE(c.call("game.screenshot", Json{{"everyFrames", 2}}).ok);
}

TEST_CASE("render.inspect: a luminance profile along a line lists the hard steps") {
    TempProject p("inspect");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(headless_cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    e.step(1);
    // Along y = 90: clear colour (32) | #808080 from x = 110 | #c0c0c0 from x = 160 | clear again from x = 210.
    auto r = c.call("render.inspect", Json::parse(R"({"from":[100,90],"to":[220,90],"threshold":20})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["count"] == 121);
    CHECK(r.result["samples"].size() == 121);
    CHECK(r.result["samples"][0].get<int>() == doctest::Approx(32).epsilon(0.1));
    CHECK(r.result["samples"][50].get<int>() == doctest::Approx(128).epsilon(0.03));
    CHECK(r.result["samples"][80].get<int>() == doctest::Approx(192).epsilon(0.03));
    REQUIRE(r.result["steps"].size() == 3);
    CHECK(r.result["steps"][0]["at"][0].get<double>() == doctest::Approx(110.0).epsilon(0.005));
    CHECK(r.result["steps"][0]["delta"].get<double>() > 80);
    CHECK(r.result["steps"][1]["at"][0].get<double>() == doctest::Approx(160.0).epsilon(0.005));
    CHECK(r.result["steps"][1]["delta"].get<double>() == doctest::Approx(64).epsilon(0.05));
    CHECK(r.result["steps"][2]["at"][0].get<double>() == doctest::Approx(210.0).epsilon(0.005));
    CHECK(r.result["steps"][2]["delta"].get<double>() < -100);
    CHECK(r.result["stepCount"] == 3);
    // A threshold above the biggest jump finds nothing; a lower one on a flat stretch finds nothing either.
    CHECK(c.call("render.inspect", Json::parse(R"({"from":[100,90],"to":[220,90],"threshold":200})")).result["steps"].empty());
    CHECK(c.call("render.inspect", Json::parse(R"({"from":[140,90],"to":[155,90],"threshold":1})")).result["steps"].empty());
    // Only the edge between the boxes, at a higher render scale: the position is still in design pixels.
    auto fine = c.call("render.inspect", Json::parse(R"({"from":[150,90],"to":[170,90],"threshold":20,"scale":4,"channel":"red"})"));
    REQUIRE_MESSAGE(fine.ok, fine.error.dump());
    CHECK(fine.result["count"] == 81);
    REQUIRE(fine.result["steps"].size() == 1);
    CHECK(fine.result["steps"][0]["at"][0].get<double>() == doctest::Approx(160.0).epsilon(0.001));
    // A vertical line down the red mover is not in the view's middle; mistakes teach.
    CHECK_FALSE(c.call("render.inspect", Json::parse(R"({"from":[0,0],"to":[500,0]})")).ok);
    CHECK_FALSE(c.call("render.inspect", Json::parse(R"({"from":[0,0],"to":[10,0],"threshold":0})")).ok);
    auto bad = c.call("render.inspect", Json::parse(R"({"from":[0,0],"to":[10,0],"channel":"lum"})"));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("luminance") != std::string::npos);
    CHECK_FALSE(c.call("render.inspect", Json::parse(R"({"from":[0,0]})")).ok);
}

TEST_CASE("render.pick: lists what draws a pixel, topmost first") {
    const char* scene = R"({
      "format": "factoria.scene/1",
      "entities": [
        { "id": "cam", "components": { "Camera": { "clearColor": "#202020" } } },
        { "id": "back", "name": "Back", "components": { "Shape2D": { "size": [100, 100], "color": "#808080", "layer": 0 } } },
        { "id": "mid", "name": "Mid", "components": { "Sprite": { "size": [32, 32], "layer": 3 } } },
        { "id": "front", "name": "Front", "components": { "Shape2D": { "size": [40, 40], "color": "#ffffff", "layer": 5 } } },
        { "id": "ghost", "components": { "Shape2D": { "size": [100, 100], "color": [1, 1, 1, 0], "layer": 9 } } },
        { "id": "off", "active": false, "components": { "Shape2D": { "size": [100, 100], "color": "#ff0000", "layer": 8 } } },
        { "id": "hud", "name": "Hud", "components": { "Transform": { "position": [120, 50, 0] },
            "Shape2D": { "space": "screen", "anchor": [0, 0], "pivot": [0, 1], "size": [60, 30], "color": "#ff0000", "layer": 0 } } }
      ]
    })";
    TempProject p("pick", scene);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(headless_cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    e.step(1);
    auto ids = [](const Json& r) {
        std::vector<std::string> v;
        for (const Json& h : r["hits"]) v.push_back(h["entity"].get<std::string>());
        return v;
    };
    // The centre: front (layer 5), mid (3), back (0); the invisible and the inactive ones are not listed.
    auto r = c.call("render.pick", Json::parse(R"({"position":[160,90]})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(ids(r.result) == std::vector<std::string>{"front", "mid", "back"});
    CHECK(r.result["hits"][0]["component"] == "Shape2D");
    CHECK(r.result["hits"][0]["layer"] == 5);
    CHECK(r.result["hits"][0]["space"] == "world");
    CHECK(r.result["hits"][0]["name"] == "Front");
    CHECK(r.result["hits"][1]["component"] == "Sprite");
    CHECK(r.result["world"][0].get<double>() == doctest::Approx(0.0).epsilon(0.01));
    CHECK(r.result["widget"].is_null());
    // Between the front square and the edge of the back one: back only.
    CHECK(ids(c.call("render.pick", Json::parse(R"({"position":[205,90]})")).result) == std::vector<std::string>{"back"});
    // The screen-space HUD box is above the world visuals under it, at any layer.
    auto hud = c.call("render.pick", Json::parse(R"({"position":[150,60]})"));
    REQUIRE(hud.ok);
    CHECK(ids(hud.result) == std::vector<std::string>{"hud", "back"});
    CHECK(hud.result["hits"][0]["space"] == "screen");
    // Nothing there; `max` cuts the list.
    auto none = c.call("render.pick", Json::parse(R"({"position":[5,5]})"));
    REQUIRE(none.ok);
    CHECK(none.result["hits"].empty());
    CHECK(none.result["hitCount"] == 0);
    auto cut = c.call("render.pick", Json::parse(R"({"position":[160,90],"max":2})"));
    CHECK(cut.result["hits"].size() == 2);
    CHECK(cut.result["truncated"] == true);
    CHECK_FALSE(c.call("render.pick", Json::object()).ok);
    CHECK_FALSE(c.call("render.pick", Json::parse(R"({"position":[1,2],"maks":3})")).ok);
}
