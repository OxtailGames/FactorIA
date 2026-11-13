// review.sheet / review.pick / review.list / review.info: N candidates as one numbered picture, the stored sheet and the pick.
// Images, vector art and levels are drawn on the CPU, so those tests run everywhere; scene, prefab and effect items need a graphics
// device and skip (with a message) where the engine finds none. No golden hashes: structure, sizes and a few pixels with tolerance.
#include <doctest.h>

#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <memory>
#include <set>

#ifndef _WIN32
#include <unistd.h>
#endif

#include "fa/core/fs.h"
#include "asset_test_helpers.h"
#include "fa/tooling/review.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

struct ReviewProject {
    ScratchShareHome home;  // the review lock never touches the real user folder
    TempDir tmp;
    std::string dir;
    CommandRegistry reg;
    ReviewProject() {
        dir = tmp.str();
        REQUIRE(create_project(dir, "2d-empty").ok());
        register_tooling_commands(reg, dir);
        write_png(file("assets/red.png"), make_image(32, 32, {200, 30, 30, 255}));
        write_png(file("assets/green.png"), make_image(16, 24, {30, 200, 30, 255}));
        write_png(file("assets/blue.png"), make_image(64, 64, {30, 30, 200, 255}));
    }
    stdfs::path file(const std::string& rel) const {
        return stdfs::path(dir) / stdfs::path(std::u8string(rel.begin(), rel.end()));
    }
    bool exists(const std::string& rel) const { return stdfs::exists(file(rel)); }
    CommandResult call(const std::string& name, const Json& args) const { return reg.call(name, args); }
    Json ok(const std::string& name, const Json& args) const {
        CommandResult r = reg.call(name, args);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    }
    Json manifest(const std::string& sheet) const {
        return parse_json(read_all(file(".factoria/review/" + sheet + "/manifest.json")), "manifest").value();
    }
};

std::string message(const CommandResult& r) {
    return r.error.value("code", std::string()) + ": " + r.error.value("message", std::string()) + " | " +
           r.error.value("hint", std::string());
}

bool contains(const std::string& s, const std::string& needle) { return s.find(needle) != std::string::npos; }

// A graphics device the engine cannot use: the command says so with no_gpu, or the engine of the stage did not start at all.
bool no_gpu(const CommandResult& r) {
    if (r.ok) return false;
    const std::string code = r.error.value("code", std::string());
    const std::string text = r.error.value("message", std::string());
    if (code != "no_gpu" && !(code == "failed" && contains(text, "Cannot start the engine that films"))) return false;
    MESSAGE("skipped: no graphics device on this machine (" << text << ")");
    return true;
}

std::string u8c(const char8_t* text) { return std::string(reinterpret_cast<const char*>(text)); }

std::string u8s(const stdfs::path& path) {
    const std::u8string u = path.generic_u8string();
    return std::string(u.begin(), u.end());
}

// Rewrites a manifest the way someone editing the file by hand would.
void tamper(const ReviewProject& p, const std::string& sheet, const std::function<void(Json&)>& edit) {
    Json m = p.manifest(sheet);
    edit(m);
    write_all(p.file(".factoria/review/" + sheet + "/manifest.json"), m.dump(2));
}

// The system clock plus an offset: a review.cleanup that is `days` days later without waiting.
struct ClockAhead {
    std::int64_t offsetSec = 0;
    ShareEnv env;
    std::unique_ptr<ScopedShareEnv> scoped;
    explicit ClockAhead(std::int64_t days) : offsetSec(days * 86400), env(share_env()) {
        const std::int64_t offset = offsetSec;
        env.now = [offset] {
            return std::int64_t(std::chrono::duration_cast<std::chrono::seconds>(
                                    std::chrono::system_clock::now().time_since_epoch())
                                    .count()) +
                   offset;
        };
        scoped = std::make_unique<ScopedShareEnv>(env);
    }
};

Json level_item(const std::string& seeds) {
    return Json::parse(
        R"({"level":{"sample":["................","..####..........","..#..#....##....","..#..#....##....","..####..........","................","......#.........",
      "......#....###..","...........#.#..","...........###.."],"legend":{"#":0},"size":[24,16]},"seeds":)" +
        seeds + "}");
}

Json images3() {
    return Json::array({Json{{"image", "assets/red.png"}, {"label", "round"}, {"candidate", true}},
                        Json{{"image", "assets/green.png"}, {"candidate", true}},
                        Json{{"image", "assets/blue.png"}, {"candidate", true}}});
}

bool near_color(const Image& img, int x, int y, int r, int g, int b, int tolerance = 3) {
    if (x < 0 || y < 0 || x >= img.width || y >= img.height) return false;
    const Rgba c = get(img, x, y);
    return std::abs(int(c.r) - r) <= tolerance && std::abs(int(c.g) - g) <= tolerance &&
           std::abs(int(c.b) - b) <= tolerance;
}

}  // namespace

TEST_CASE("review.sheet: a sheet of images has numbered cells, a stored manifest and thumbnails") {
    ReviewProject p;
    const Json r = p.ok("review.sheet", Json{{"label", "Which hero?"}, {"items", images3()}});
    CHECK(r["sheet"] == "sheet-0001");
    CHECK(r["count"] == 3);
    CHECK(r["columns"] == 3);
    CHECK(r["rows"] == 1);
    REQUIRE(r["items"].size() == 3);
    CHECK(r["items"][0]["label"] == "round");
    CHECK(r["items"][1]["label"] == "green");  // the file name without its extension
    CHECK(r["items"][0]["info"] == "32x32, 1 color, 0% clear");
    CHECK(r["items"][1]["info"] == "16x24, 1 color, 0% clear");
    CHECK(r["warnings"].empty());
    CHECK(has_text(r["nextSteps"], "ONE number"));
    CHECK(has_text(r["nextSteps"], "review.pick"));

    // the picture: a file inside the project (not a temporary one), the size the result says
    REQUIRE(r.contains("$image"));
    CHECK(r["$image"]["mimeType"] == "image/png");
    CHECK_FALSE(r["$image"].contains("temporary"));
    const std::string picturePath = r["$image"]["path"].get<std::string>();
    const Image sheet = read_png(stdfs::path(picturePath));
    CHECK(sheet.width == r["picture"]["width"].get<int>());
    CHECK(sheet.height == r["picture"]["height"].get<int>());
    CHECK(sheet.width <= 2000);
    CHECK(sheet.height <= 700);

    // the files of the sheet
    CHECK(p.exists(".factoria/review/sheet-0001/sheet.png"));
    CHECK(p.exists(".factoria/review/sheet-0001/manifest.json"));
    for (const char* thumb : {"01", "02", "03"})
        CHECK(p.exists(std::string(".factoria/review/sheet-0001/thumbs/") + thumb + ".png"));
    CHECK_FALSE(p.exists("assets.json"));
    CHECK_FALSE(p.exists(".factoria/review/sheet-0001/thumbs/04.png"));

    const Json m = p.manifest("sheet-0001");
    CHECK(m["format"] == "factoria.review/1");
    CHECK(m["id"] == "sheet-0001");
    CHECK(m["label"] == "Which hero?");
    CHECK(m["picked"].is_null());
    CHECK(m["dropDir"] == ".factoria/review/dropped");
    CHECK(m["createdUnix"].get<long long>() > 1'600'000'000LL);
    const std::string created = m["createdAt"].get<std::string>();
    CHECK(created.size() == 24);
    CHECK(created.back() == 'Z');
    REQUIRE(m["items"].size() == 3);
    CHECK(m["items"][0]["n"] == 1);
    CHECK(m["items"][0]["type"] == "image");
    CHECK(m["items"][0]["source"] == "assets/red.png");
    CHECK(m["items"][0]["candidate"] == true);
    CHECK(m["items"][0]["numbers"]["width"] == 32);
    CHECK(m["items"][0]["numbers"]["colors"] == 1);
    CHECK(m["items"][0]["spec"]["image"] == "assets/red.png");
    CHECK(m["items"][2]["thumb"] == "thumbs/03.png");

    // layout: the cells do not overlap, sit inside the sheet, and the number badge and the picture are where the manifest says
    std::set<int> xs;
    for (const Json& item : m["items"]) {
        const Json& c = item["cell"];
        const Json& pic = item["picture"];
        CHECK(c["x"].get<int>() >= 0);
        CHECK(c["x"].get<int>() + c["w"].get<int>() <= sheet.width);
        CHECK(c["y"].get<int>() + c["h"].get<int>() <= sheet.height);
        CHECK(pic["x"].get<int>() >= c["x"].get<int>());
        CHECK(pic["x"].get<int>() + pic["w"].get<int>() <= c["x"].get<int>() + c["w"].get<int>());
        xs.insert(c["x"].get<int>());
        CHECK(near_color(sheet, c["x"].get<int>() + 9, c["y"].get<int>() + 9, 242, 183,
                         5));  // the amber badge of the number
    }
    CHECK(xs.size() == 3);
    // the red 32x32 picture is enlarged by a whole factor with hard pixels: the middle of its area is exactly red
    const Json& red = m["items"][0]["picture"];
    CHECK(near_color(sheet, red["x"].get<int>() + red["w"].get<int>() / 2,
                     red["y"].get<int>() + red["h"].get<int>() / 2, 200, 30, 30));
    // the 16x24 picture keeps its proportions: green in the middle, the background at the left edge of its area
    const Json& green = m["items"][1]["picture"];
    CHECK(near_color(sheet, green["x"].get<int>() + green["w"].get<int>() / 2,
                     green["y"].get<int>() + green["h"].get<int>() / 2, 30, 200, 30));
    CHECK_FALSE(
        near_color(sheet, green["x"].get<int>() + 2, green["y"].get<int>() + green["h"].get<int>() / 2, 30, 200, 30));
    // the stored thumbnail is the fitted picture
    const Image thumb = read_png(p.file(".factoria/review/sheet-0001/thumbs/01.png"));
    CHECK(thumb.width == 320);
    CHECK(near_color(thumb, 160, 160, 200, 30, 30));
}

TEST_CASE("review.sheet: the same items give the same layout and the same thumbnails; ids count up") {
    ReviewProject p;
    const Json a = p.ok("review.sheet", Json{{"items", images3()}});
    const Json b = p.ok("review.sheet", Json{{"items", images3()}});
    CHECK(a["sheet"] == "sheet-0001");
    CHECK(b["sheet"] == "sheet-0002");
    CHECK(a["picture"]["width"] == b["picture"]["width"]);
    CHECK(a["picture"]["height"] == b["picture"]["height"]);
    CHECK(a["thumbSize"] == b["thumbSize"]);
    for (const char* t : {"01", "02", "03"})
        CHECK(read_all(p.file(std::string(".factoria/review/sheet-0001/thumbs/") + t + ".png")) ==
              read_all(p.file(std::string(".factoria/review/sheet-0002/thumbs/") + t + ".png")));
    // an explicit layout is obeyed
    const Json c = p.ok("review.sheet", Json{{"items", images3()}, {"columns", 2}, {"thumbSize", 100}});
    CHECK(c["columns"] == 2);
    CHECK(c["rows"] == 2);
    CHECK(c["thumbSize"] == 100);
    CHECK(c["picture"]["width"].get<int>() < a["picture"]["width"].get<int>());
}

TEST_CASE("review.sheet: levels, one thumbnail per seed, no GPU needed") {
    ReviewProject p;
    const Json r =
        p.ok("review.sheet", Json{{"items", Json::array({level_item("[1, 2, 3]")})}, {"label", "Pick a layout"}});
    CHECK(r["count"] == 3);
    REQUIRE(r["items"].size() == 3);
    CHECK(r["items"][0]["type"] == "level");
    CHECK(r["items"][0]["label"] == "level seed 1");
    CHECK(r["items"][2]["label"] == "level seed 3");
    CHECK(r["items"][0]["candidate"] == false);
    CHECK(contains(r["items"][1]["info"].get<std::string>(), "24x16, seed 2"));
    CHECK(r["warnings"].empty());
    const Json m = p.manifest("sheet-0001");
    CHECK(m["items"][1]["numbers"]["seed"] == 2);
    CHECK(m["items"][1]["numbers"]["width"] == 24);
    CHECK(m["items"][1]["numbers"]["height"] == 16);
    CHECK(m["items"][1]["numbers"]["attempts"].get<int>() >= 1);
    CHECK(m["items"][1]["spec"]["level"]["seed"] == 2);  // enough to generate this very level afterwards
    CHECK(m["items"][1]["spec"]["level"]["size"] == Json::array({24, 16}));
    CHECK(m["items"][1]["source"] == "");

    // the thumbnails of two seeds differ, and a seed given twice gives the same picture
    const Json again = p.ok("review.sheet", Json{{"items", Json::array({level_item("[2, 2]")})}});
    const std::string t1 = read_all(p.file(".factoria/review/" + again["sheet"].get<std::string>() + "/thumbs/01.png"));
    const std::string t2 = read_all(p.file(".factoria/review/" + again["sheet"].get<std::string>() + "/thumbs/02.png"));
    CHECK(t1 == t2);
    CHECK(t1 == read_all(p.file(".factoria/review/sheet-0001/thumbs/02.png")));
    CHECK(t1 != read_all(p.file(".factoria/review/sheet-0001/thumbs/01.png")));

    // one level with its seed inside, mixed with an image
    const Json one = p.ok(
        "review.sheet",
        Json{
            {"items",
             Json::array(
                 {Json{{"image", "assets/red.png"}},
                  Json::parse(
                      R"({"level":{"sample":["................","..####..........","..#..#....##....","..#..#....##....","..####..........","................","......#.........","......#....###..","...........#.#..","...........###.."],"legend":{"#":0},"size":[24,16],"seed":9},"label":"mine"})")})}});
    CHECK(one["count"] == 2);
    CHECK(one["items"][1]["label"] == "mine");
    CHECK(contains(one["items"][1]["info"].get<std::string>(), "seed 9"));
}

TEST_CASE("review.sheet: vector art is rasterized and counted") {
    ReviewProject p;
    write_all(
        p.file("assets/logo.svg"),
        R"(<svg xmlns="http://www.w3.org/2000/svg" width="40" height="20" viewBox="0 0 40 20"><rect x="0" y="0" width="40" height="20" fill="#ff0000"/><circle cx="20" cy="10" r="6" fill="#00ff00"/></svg>)");
    const Json r =
        p.ok("review.sheet",
             Json{{"items", Json::array({Json{{"vector", "assets/logo.svg"}}, Json{{"image", "assets/red.png"}}})}});
    CHECK(r["items"][0]["type"] == "vector");
    CHECK(r["items"][0]["label"] == "logo");
    CHECK(r["items"][0]["ok"] == true);
    CHECK(contains(r["items"][0]["info"].get<std::string>(), "2 shapes"));
    CHECK(contains(r["items"][0]["info"].get<std::string>(), "2 colors"));
    const Json m = p.manifest("sheet-0001");
    const Image sheet = read_png(p.file(".factoria/review/sheet-0001/sheet.png"));
    const Json& pic = m["items"][0]["picture"];
    // the red rectangle is in the picture's area, near its left edge
    CHECK(near_color(sheet, pic["x"].get<int>() + 10, pic["y"].get<int>() + pic["h"].get<int>() / 2, 255, 0, 0, 12));
}

TEST_CASE("review.sheet: a picture that cannot be read is a red tile; all failing writes nothing") {
    ReviewProject p;
    write_all(p.file("assets/broken.png"), "this is not a png");
    const Json r =
        p.ok("review.sheet",
             Json{{"items", Json::array({Json{{"image", "assets/red.png"}}, Json{{"image", "assets/broken.png"}}})}});
    CHECK(r["items"][0]["ok"] == true);
    CHECK(r["items"][1]["ok"] == false);
    CHECK(has_warning(r, "Item 2"));
    CHECK(has_warning(r, "cannot be picked"));
    const Json m = p.manifest("sheet-0001");
    CHECK(m["items"][1]["ok"] == false);
    CHECK_FALSE(m["items"][1]["error"].get<std::string>().empty());
    // review.pick refuses it
    CommandResult pick = p.call("review.pick", Json{{"sheet", "latest"}, {"n", 2}});
    CHECK_FALSE(pick.ok);
    CHECK(pick.error.value("code", std::string()) == "invalid_argument");
    CHECK(contains(message(pick), "failed to render"));
    CHECK(p.manifest("sheet-0001")["picked"].is_null());

    // a PNG header that announces 20000 x 20000 pixels is refused before any pixel is made
    std::string huge = "\x89PNG\r\n\x1a\n";
    huge += std::string("\0\0\0\x0d"
                        "IHDR",
                        8);
    huge += std::string("\0\0\x4e\x20\0\0\x4e\x20\x08\x06\0\0\0", 13);
    write_all(p.file("assets/huge.png"), huge);
    const Json big =
        p.ok("review.sheet",
             Json{{"items", Json::array({Json{{"image", "assets/red.png"}}, Json{{"image", "assets/huge.png"}}})}});
    CHECK(big["items"][1]["ok"] == false);
    CHECK(has_warning(big, "20000x20000"));

    CommandResult all = p.call("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/broken.png"}}})}});
    CHECK_FALSE(all.ok);
    CHECK(contains(message(all), "None of the 1 items could be drawn"));
    CHECK_FALSE(p.exists(".factoria/review/sheet-0003"));  // nothing was left behind
}

TEST_CASE("review.pick: picking moves the files of the other candidates and updates the manifest") {
    ReviewProject p;
    p.ok("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"candidate", true}},
                                                     Json{{"image", "assets/green.png"}, {"candidate", true}},
                                                     Json{{"image", "assets/blue.png"}}})}});
    const std::string redBytes = read_all(p.file("assets/red.png"));
    const Json r = p.ok("review.pick", Json{{"sheet", "latest"}, {"n", 2}, {"note", "the green one reads best"}});
    CHECK(r["sheet"] == "sheet-0001");
    CHECK(r["n"] == 2);
    CHECK(r["label"] == "green");
    CHECK(r["source"] == "assets/green.png");
    CHECK(r["drop"] == true);
    REQUIRE(r["dropped"].size() == 1);  // the blue one is not a candidate: it stays
    CHECK(r["dropped"][0]["n"] == 1);
    CHECK(r["dropped"][0]["from"] == "assets/red.png");
    CHECK(r["dropped"][0]["to"] == ".factoria/review/dropped/sheet-0001/01_red.png");
    CHECK(r["dropped"][0]["status"] == "moved");
    CHECK(r["warnings"].empty());
    CHECK(has_text(r["nextSteps"], "assets/green.png"));
    // the files: moved, not deleted, same bytes; the picked and the unmarked ones stay
    CHECK_FALSE(p.exists("assets/red.png"));
    CHECK(p.exists("assets/green.png"));
    CHECK(p.exists("assets/blue.png"));
    CHECK(read_all(p.file(".factoria/review/dropped/sheet-0001/01_red.png")) == redBytes);
    // the manifest
    const Json m = p.manifest("sheet-0001");
    REQUIRE(m["picked"].is_object());
    CHECK(m["picked"]["n"] == 2);
    CHECK(m["picked"]["label"] == "green");
    CHECK(m["picked"]["note"] == "the green one reads best");
    CHECK(m["picked"]["drop"] == true);
    CHECK(m["picked"]["dropped"][0]["to"] == ".factoria/review/dropped/sheet-0001/01_red.png");
    CHECK(m["picked"]["spec"]["image"] == "assets/green.png");
    CHECK(m["picked"]["atUnix"].get<long long>() >= m["createdUnix"].get<long long>());
    CHECK_FALSE(m["picked"]["who"].get<std::string>().empty());

    // the list shows the answer
    const Json list = p.ok("review.list", Json::object());
    CHECK(list["total"] == 1);
    CHECK(list["sheets"][0]["picked"] == 2);
    CHECK(list["sheets"][0]["pickedLabel"] == "green");
    // review.info returns the manifest and the picture
    const Json info = p.ok("review.info", Json{{"sheet", "1"}});
    CHECK(info["id"] == "sheet-0001");
    CHECK(info["picked"]["n"] == 2);
    CHECK(info.contains("$image"));

    // a choice is final
    CommandResult again = p.call("review.pick", Json{{"sheet", "sheet-0001"}, {"n", 1}});
    CHECK_FALSE(again.ok);
    CHECK(again.error.value("code", std::string()) == "already_picked");
    CHECK(contains(message(again), "make a new sheet"));
    CHECK(p.exists("assets/green.png"));
    CHECK_FALSE(p.exists("assets/red.png"));
}

TEST_CASE("review.pick: drop false records the choice and touches no file; a level is only recorded") {
    ReviewProject p;
    p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});
    const Json r = p.ok("review.pick", Json{{"n", 3}, {"drop", false}});
    CHECK(r["drop"] == false);
    CHECK(r["dropped"].empty());
    for (const char* f : {"assets/red.png", "assets/green.png", "assets/blue.png"}) CHECK(p.exists(f));
    CHECK_FALSE(p.exists(".factoria/review/dropped"));
    CHECK(p.manifest("sheet-0001")["picked"]["drop"] == false);

    const Json lv = p.ok("review.sheet", Json{{"items", Json::array({level_item("[4, 5]")})}});
    const Json picked = p.ok("review.pick", Json{{"sheet", lv["sheet"]}, {"n", 2}});
    CHECK(picked["type"] == "level");
    CHECK(picked["spec"]["level"]["seed"] == 5);
    CHECK(picked["dropped"].empty());
    CHECK(has_text(picked["nextSteps"], "tilemap.generate"));
}

TEST_CASE("review.pick: all or nothing; a leftover in the drop folder stops it before any file moves") {
    ReviewProject p;
    p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});
    write_all(p.file(".factoria/review/dropped/sheet-0001/03_blue.png"), "a leftover");
    CommandResult r = p.call("review.pick", Json{{"n", 1}});
    CHECK_FALSE(r.ok);
    CHECK(r.error.value("code", std::string()) == "exists");
    CHECK(contains(message(r), "03_blue.png"));
    for (const char* f : {"assets/red.png", "assets/green.png", "assets/blue.png"})
        CHECK(p.exists(f));  // nothing moved
    CHECK_FALSE(p.exists(".factoria/review/dropped/sheet-0001/02_green.png"));
    CHECK(p.manifest("sheet-0001")["picked"].is_null());
    // once the leftover is gone the same pick works
    std::error_code ec;
    stdfs::remove(p.file(".factoria/review/dropped/sheet-0001/03_blue.png"), ec);
    CHECK(p.call("review.pick", Json{{"n", 1}}).ok);
    CHECK(p.exists(".factoria/review/dropped/sheet-0001/03_blue.png"));
}

TEST_CASE("review.pick: a candidate that is already gone is reported, not an error") {
    ReviewProject p;
    p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});
    std::error_code ec;
    stdfs::remove(p.file("assets/green.png"), ec);
    const Json r = p.ok("review.pick", Json{{"n", 1}});
    CHECK(has_warning(r, "green"));
    CHECK(p.exists(".factoria/review/dropped/sheet-0001/03_blue.png"));
    CHECK(r["dropped"].size() == 1);
}

TEST_CASE("review.pick: errors teach") {
    ReviewProject p;
    CommandResult r = p.call("review.pick", Json{{"n", 1}});
    CHECK_FALSE(r.ok);
    CHECK(r.error.value("code", std::string()) == "not_found");
    CHECK(contains(message(r), "review.sheet"));
    p.ok("review.sheet", Json{{"items", images3()}});
    r = p.call("review.pick", Json{{"sheet", "sheet-0007"}, {"n", 1}});
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "sheet-0001"));  // did you mean / the sheets there are
    r = p.call("review.pick", Json{{"n", 9}});
    CHECK_FALSE(r.ok);
    CHECK(r.error.value("code", std::string()) == "invalid_argument");
    CHECK(contains(message(r), "1 to 3"));
    r = p.call("review.pick", Json{{"n", 0}});
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "/n"));
    r = p.call("review.pick", Json::object());
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "'n'"));
    r = p.call("review.pick", Json{{"n", 1}, {"dorp", false}});
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "drop"));  // did you mean
    CHECK(p.manifest("sheet-0001")["picked"].is_null());
}

TEST_CASE("review.sheet: argument errors name the JSON pointer and suggest the fix") {
    ReviewProject p;
    auto fails = [&](const Json& args, const std::string& pointer) {
        CommandResult r = p.call("review.sheet", args);
        CHECK_FALSE(r.ok);
        CHECK_MESSAGE(contains(message(r), pointer), message(r));
        CHECK_FALSE(p.exists(".factoria/review/sheet-0001"));  // detected before anything is made
        return message(r);
    };
    const Json good = Json{{"image", "assets/red.png"}};
    // a typo of a key: did you mean
    CHECK(contains(fails(Json{{"items", Json::array({good, Json{{"imge", "assets/red.png"}}})}}, "/items/1"), "image"));
    CHECK(contains(fails(Json{{"items", Json::array({good})}, {"colums", 3}}, "colums"), "columns"));
    // two things in one item, none, wrong place for an option
    CHECK(contains(
        fails(Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"scene", "scenes/main.scene.json"}}})}},
              "/items/0"),
        "ONE thing"));
    fails(Json{{"items", Json::array({Json{{"label", "x"}}})}}, "/items/0");
    fails(Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"steps", 3}}})}}, "/items/0/steps");
    fails(Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"seeds", Json::array({1})}}})}},
          "/items/0/seeds");
    // the file
    const std::string missing =
        fails(Json{{"items", Json::array({good, Json{{"image", "assets/gren.png"}}})}}, "/items/1/image");
    CHECK(contains(missing, "green.png"));  // did you mean
    CHECK(
        contains(fails(Json{{"items", Json::array({Json{{"image", "assets/red.json"}}})}}, "/items/0/image"), ".png"));
    fails(Json{{"items", Json::array({Json{{"image", "../outside.png"}}})}}, "/items/0/image");
    fails(Json{{"items", Json::array({Json{{"image", 3}}})}}, "/items/0/image");
    // the list and the layout
    fails(Json{{"items", Json::array()}}, "/items");
    fails(Json{{"items", "assets/red.png"}}, "/items");
    fails(Json::object(), "items");
    fails(Json{{"items", Json::array({good})}, {"columns", 0}}, "/columns");
    fails(Json{{"items", Json::array({good})}, {"columns", 2.5}}, "/columns");
    fails(Json{{"items", Json::array({good})}, {"thumbSize", 10}}, "/thumbSize");
    fails(Json{{"items", Json::array({good})}, {"thumbSize", 1e12}}, "/thumbSize");
    fails(Json{{"items", Json::array({good})}, {"dropDir", "assets"}}, "/dropDir");
    fails(Json{{"items", Json::array({good})}, {"label", std::string(200, 'x')}}, "/label");
    // too many items, and a sheet that would be too big for the caps
    Json many = Json::array();
    for (int i = 0; i < kReviewMaxItems + 1; ++i) many.push_back(good);
    CHECK(contains(fails(Json{{"items", many}}, "/items"), std::to_string(kReviewMaxItems)));
    Json forty = Json::array();
    for (int i = 0; i < 40; ++i) forty.push_back(good);
    CHECK(contains(fails(Json{{"items", forty}, {"columns", 1}, {"thumbSize", 512}}, "/thumbSize"), "limit"));
}

TEST_CASE("review.sheet: level arguments are checked before any generation") {
    ReviewProject p;
    auto fails = [&](const Json& item, const std::string& pointer) {
        CommandResult r = p.call("review.sheet", Json{{"items", Json::array({item})}});
        CHECK_FALSE(r.ok);
        CHECK_MESSAGE(contains(message(r), pointer), message(r));
        CHECK_FALSE(p.exists(".factoria/review/sheet-0001"));
        return message(r);
    };
    CHECK(
        contains(fails(Json::parse(R"({"level":{"sample":["#."],"into":"map","size":[4,4]}})"), "/items/0/level/into"),
                 "Leave `into` out"));
    fails(Json::parse(R"({"level":{"sample":["#."],"seed":3,"size":[4,4]},"seeds":[1,2]})"), "/items/0/seeds");
    fails(Json::parse(R"({"level":{"sample":["#."],"size":[4000,4]}})"), "/items/0/level/size/0");
    fails(Json::parse(R"({"level":{"sample":["#."],"size":[4,4]},"seeds":[-1]})"), "/items/0/seeds/0");
    fails(Json::parse(R"({"level":{"sample":["#."],"size":[4,4]},"seeds":[]})"), "/items/0/seeds");
    fails(Json::parse(R"({"level":{"sample":["#."],"size":[4,4]},"candidate":true})"), "/items/0/candidate");
    fails(Json::parse(R"({"level":{"sample":["#."],"size":[4,4],"seeds":[1]}})"), "/items/0/level/seeds");
    fails(Json::parse(R"({"level":{}})"), "/items/0/level");
    // 30 seeds are fine, 60 are over the cap of items once expanded
    Json sixty = Json::array();
    for (int i = 0; i < 60; ++i) sixty.push_back(i);
    CHECK(contains(
        fails(Json{{"level", Json::parse(R"({"sample":["#."],"size":[4,4]})")}, {"seeds", sixty}}, "/items/0/seeds"),
        std::to_string(kReviewMaxItems)));
    // a problem of tilemap.generate itself comes back with the pointer of the item
    CommandResult r = p.call(
        "review.sheet", Json{{"items", Json::array({Json::parse(R"({"level":{"sample":"nobody","size":[4,4]}})")})}});
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "/items/0/level"));
    CHECK_FALSE(p.exists(".factoria/review/sheet-0001"));
}

TEST_CASE("review.sheet: a candidate may not be the main scene, a repeated file or inside .git") {
    ReviewProject p;
    write_all(p.file("scenes/variant.scene.json"), read_all(p.file("scenes/main.scene.json")));
    CommandResult r = p.call(
        "review.sheet", Json{{"items", Json::array({Json{{"scene", "scenes/main.scene.json"}, {"candidate", true}}})}});
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "main scene"));
    CHECK(contains(message(r), "/items/0/candidate"));
    r = p.call("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"candidate", true}},
                                                           Json{{"image", "assets/RED.png"}, {"candidate", true}}})}});
    CHECK_FALSE(
        r.ok);  // the same file twice (the second is not on a case-sensitive disk: it is missing, or the same file)
    CHECK(contains(message(r), "/items/1"));
    r = p.call("review.sheet",
               Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"candidate", true}},
                                           Json{{"image", "assets/./red.png"}, {"candidate", true}}})}});
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "already the file of item 1"));
    CHECK(p.exists("assets/red.png"));
}

TEST_CASE("review.sheet: scenes, prefabs and effects need a GPU and say so before anything is written") {
    ReviewProject p;
    write_all(p.file("scenes/level.scene.json"), R"({"format":"factoria.scene/1","entities":[
      {"id":"cam","components":{"Transform":{},"Camera":{"orthoSize":100,"clearColor":[0,0,0,1]}}},
      {"id":"hero","components":{"Transform":{"position":[-50,0,0]},"Shape2D":{"shape":"rectangle","size":[20,20],"color":[0,0,1,1]}}}]})");
    write_all(p.file("prefabs/box.prefab.json"), R"({"format":"factoria.prefab/1","entity":
      {"id":"box","components":{"Transform":{},"Shape2D":{"shape":"rectangle","size":[20,10],"color":[0,1,0,1]}}}})");
    CommandResult r =
        p.call("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/red.png"}},
                                                           Json{{"scene", "scenes/level.scene.json"}, {"steps", 1}},
                                                           Json{{"prefab", "prefabs/box.prefab.json"}}})}});
    if (no_gpu(r)) {
        CHECK_FALSE(p.exists(".factoria/review/sheet-0001"));  // nothing was left behind
        CHECK(contains(message(r), "GPU"));
        return;
    }
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["items"][1]["type"] == "scene");
    CHECK(contains(r.result["items"][1]["info"].get<std::string>(), "entities"));
    CHECK(r.result["items"][2]["type"] == "prefab");
    CHECK(r.result["items"][2]["ok"] == true);
    const Json m = p.manifest("sheet-0001");
    const Image sheet = read_png(p.file(".factoria/review/sheet-0001/sheet.png"));
    // the scene's blue hero is somewhere in the scene's area
    const Json& area = m["items"][1]["picture"];
    int blue = 0;
    for (int y = area["y"].get<int>(); y < area["y"].get<int>() + area["h"].get<int>(); ++y)
        for (int x = area["x"].get<int>(); x < area["x"].get<int>() + area["w"].get<int>(); ++x)
            if (near_color(sheet, x, y, 0, 0, 255, 40)) ++blue;
    CHECK(blue > 50);
    // the prefab fills its area: its green box is in the middle
    const Json& pa = m["items"][2]["picture"];
    CHECK(near_color(sheet, pa["x"].get<int>() + pa["w"].get<int>() / 2, pa["y"].get<int>() + pa["h"].get<int>() / 2, 0,
                     255, 0, 60));
    // no stage scene is left in the scratch folder
    std::error_code ec;
    int leftovers = 0;
    for (stdfs::directory_iterator it(p.file(".factoria/tmp"), ec), end; !ec && it != end; it.increment(ec))
        ++leftovers;
    CHECK(leftovers == 0);
}

TEST_CASE("review.list: newest first, a limit, and sheets that cannot be read are reported") {
    ReviewProject p;
    for (int i = 0; i < 3; ++i)
        p.ok("review.sheet", Json{{"items", images3()}, {"label", "round " + std::to_string(i + 1)}});
    Json list = p.ok("review.list", Json::object());
    CHECK(list["total"] == 3);
    CHECK(list["sheets"][0]["id"] == "sheet-0003");
    CHECK(list["sheets"][0]["label"] == "round 3");
    CHECK(list["sheets"][0]["picked"].is_null());
    CHECK(list["sheets"][0]["count"] == 3);
    list = p.ok("review.list", Json{{"limit", 2}});
    CHECK(list["sheets"].size() == 2);
    CHECK(list["total"] == 3);
    CommandResult bad = p.call("review.list", Json{{"limit", 0}});
    CHECK_FALSE(bad.ok);
    CHECK(contains(message(bad), "/limit"));
    // a manifest that is not JSON
    write_all(p.file(".factoria/review/sheet-0002/manifest.json"), "{ not json");
    list = p.ok("review.list", Json::object());
    CHECK(list["sheets"].size() == 2);
    REQUIRE(list.contains("unreadable"));
    CHECK(list["unreadable"][0]["id"] == "sheet-0002");
    CHECK(p.ok("review.info", Json::object())["id"] == "sheet-0003");
    CommandResult info = p.call("review.info", Json{{"sheet", "sheet-0002"}});
    CHECK_FALSE(info.ok);
    CHECK(contains(message(info), "sheet-0002"));
}

TEST_CASE(
    "review store: unicode folder names, an abandoned sheet leaves nothing, a sheet in the making is not listed") {
    TempDir tmp;
    ScratchShareHome home;
    const stdfs::path root = tmp.path / stdfs::path(std::u8string(u8"proyecto áé"));
    std::error_code ec;
    stdfs::create_directories(root, ec);
    const std::string dir = root.string();  // a project folder is a NATIVE string (the ANSI code page on Windows)
    ReviewOutcome a = review_reserve(dir);
    REQUIRE_MESSAGE(a.ok, a.message);
    CHECK(a.value["id"] == "sheet-0001");
    // reserved but never committed: not listed, not the "latest"
    ReviewOutcome list = review_list(dir, 10);
    REQUIRE(list.ok);
    CHECK(list.value["total"] == 0);
    CHECK_FALSE(review_load(dir, "latest").ok);
    review_abandon(dir, "sheet-0001");
    CHECK_FALSE(stdfs::exists(root / ".factoria" / "review" / "sheet-0001"));
    // the number is reused once the folder is gone
    ReviewOutcome b = review_reserve(dir);
    REQUIRE(b.ok);
    CHECK(b.value["id"] == "sheet-0001");
    Image sheet = make_image(8, 8, {1, 2, 3, 255});
    Json manifest = Json::object(
        {{"label", "café"},
         {"items",
          Json::array({Json::object(
              {{"n", 1}, {"type", "level"}, {"label", "x"}, {"source", ""}, {"candidate", false}, {"ok", true}})})},
         {"picked", nullptr}});
    ReviewOutcome done = review_commit(dir, "sheet-0001", manifest, sheet, {ReviewThumb{1, sheet}});
    REQUIRE_MESSAGE(done.ok, done.message);
    review_abandon(dir, "sheet-0001");  // a finished sheet is never removed by this
    CHECK(stdfs::exists(root / ".factoria" / "review" / "sheet-0001" / "manifest.json"));
    ReviewOutcome loaded = review_load(dir, "latest");
    REQUIRE(loaded.ok);
    CHECK(loaded.value["label"] == "café");
    CHECK(loaded.value["engineVersion"].is_string());
}

// ---- review.pick trusts nothing in the manifest -----------------------------------------------------------------------------------

namespace {

// A sheet of the three images, all candidates, whose item 3 (blue) is rewritten by `edit`; then item 1 is picked. The pick must be refused
// with nothing moved and the manifest unchanged.
void pick_is_refused(ReviewProject& p, const std::function<void(Json&)>& edit, const std::string& needle) {
    const Json made = p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});
    const std::string id = made["sheet"].get<std::string>();
    tamper(p, id, edit);
    const std::string before = read_all(p.file(".factoria/review/" + id + "/manifest.json"));
    const CommandResult r = p.call("review.pick", Json{{"sheet", id}, {"n", 1}});
    CHECK_FALSE(r.ok);
    CHECK_MESSAGE(contains(message(r), needle), message(r));
    for (const char* f : {"assets/red.png", "assets/green.png", "assets/blue.png"})
        CHECK(p.exists(f));  // nothing moved
    CHECK_FALSE(p.exists(".factoria/review/dropped/" + id));
    CHECK(read_all(p.file(".factoria/review/" + id + "/manifest.json")) == before);
}

}  // namespace

TEST_CASE("review.pick: a hand-edited source never moves a file outside the project, a project file or a file of "
          "another kind") {
    ReviewProject p;
    TempDir other;  // a folder outside the project
    const stdfs::path precious = other.path / "precious.png";
    write_png(precious, make_image(4, 4, {9, 9, 9, 255}));
    const std::string preciousBytes = read_all(precious);
    write_all(p.file(".factoria/keep.png"), "kept");
    write_all(p.file("scenes/variant.scene.json"), read_all(p.file("scenes/main.scene.json")));
    auto source = [](const std::string& value, const std::string& type = "image") {
        return [value, type](Json& m) {
            m["items"][2]["source"] = value;
            m["items"][2]["type"] = type;
        };
    };
    pick_is_refused(p, source(u8s(precious)), "may not move");  // an absolute path
    pick_is_refused(p, source("../precious.png"), "may not move");
    pick_is_refused(p, source("assets/../../precious.png"), "may not move");
    pick_is_refused(p, source("factoria.json"), "may not move");
    pick_is_refused(p, source("assets.json"), "may not move");
    pick_is_refused(p, source(".factoria/keep.png"), ".factoria");
    pick_is_refused(p, source(".git/config"), "may not move");
    pick_is_refused(p, source("scenes/main.scene.json", "scene"), "main scene");
    pick_is_refused(p, source("./scenes/main.scene.json", "scene"), "main scene");
    pick_is_refused(p, source("SCENES\\Main.scene.json", "scene"), "main scene");
    pick_is_refused(p, source("scenes/variant.scene.json", "image"), "may not move");  // a scene is no picture
    CHECK(read_all(precious) == preciousBytes);
    CHECK(p.exists(".factoria/keep.png"));
    CHECK(p.exists("scenes/main.scene.json"));

    // a link inside the project that leads out of it
    std::error_code ec;
    stdfs::create_symlink(precious, p.file("assets/link.png"), ec);
    if (ec) {
        MESSAGE("symlink case skipped: " << ec.message());
    } else {
        pick_is_refused(p, source("assets/link.png"), "may not move");
        CHECK(read_all(precious) == preciousBytes);
    }

    // the stage of an effect is never moved, whoever owns it
    pick_is_refused(
        p,
        [](Json& m) {
            m["items"][2]["source"] = "scenes/variant.scene.json";
            m["items"][2]["type"] = "scene";
            m["items"][0]["spec"]["stage"] = "./scenes/Variant.scene.json";
        },
        "stage");
}

TEST_CASE("review.pick: a hand-edited drop folder is refused before any file moves") {
    ReviewProject p;
    for (const char* bad : {".factoria/tmp", ".factoria/tmp/x", "assets", "../elsewhere", ".factoria/review",
                            ".factoria/review/sheet-0001", ".factoria", "/abs/where"}) {
        pick_is_refused(p, [bad](Json& m) { m["dropDir"] = bad; }, "drop folder");
        CHECK_FALSE(p.exists("../elsewhere"));
    }
    // and the folder is asked for the same way by review.sheet, with a JSON pointer
    for (const char* bad :
         {".factoria/tmp", "assets", "../elsewhere", ".factoria/review", ".factoria/review/sheet-0009/x"}) {
        const CommandResult r = p.call("review.sheet", Json{{"items", images3()}, {"dropDir", bad}});
        CHECK_FALSE(r.ok);
        CHECK_MESSAGE(contains(message(r), "/dropDir"), message(r));
    }
    // a folder of the project's own below .factoria/ is fine
    const Json r =
        p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}, {"dropDir", ".factoria/old-takes"}});
    const Json picked = p.ok("review.pick", Json{{"sheet", r["sheet"]}, {"n", 2}});
    CHECK(picked["dropped"][0]["to"].get<std::string>().rfind(".factoria/old-takes/", 0) == 0);
    CHECK(p.exists(".factoria/old-takes/" + r["sheet"].get<std::string>() + "/01_red.png"));
}

TEST_CASE("review.sheet: a candidate is the right kind of file, not a project file, not a stage and not shown twice") {
    ReviewProject p;
    write_all(p.file("scenes/variant.scene.json"), read_all(p.file("scenes/main.scene.json")));
    write_all(p.file("assets/vfx/a.vfx.json"),
              R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","emitter":{"burst":4}}]})");
    write_all(p.file(".factoria/keep.png"), "kept");
    auto fails = [&](const Json& items, const std::string& pointer, const std::string& needle) {
        const CommandResult r = p.call("review.sheet", Json{{"items", items}});
        CHECK_FALSE(r.ok);
        CHECK_MESSAGE(contains(message(r), pointer), message(r));
        CHECK_MESSAGE(contains(message(r), needle), message(r));
        CHECK_FALSE(p.exists(".factoria/review/sheet-0001"));
    };
    // suffixes: factoria.json and assets.json are no prefab or effect
    fails(Json::array({Json{{"prefab", "factoria.json"}, {"candidate", true}}}), "/items/0/prefab", ".prefab.json");
    fails(Json::array({Json{{"vfx", "assets.json"}, {"candidate", true}}}), "/items/0/vfx", ".vfx.json");
    fails(Json::array({Json{{"scene", "factoria.json"}}}), "/items/0/scene", ".scene.json");
    fails(Json::array({Json{{"vector", "assets/vfx/a.vfx.json"}}}), "/items/0/vector", ".svg");
    // files below .factoria/ and the main scene, written in other ways
    fails(Json::array({Json{{"image", ".factoria/keep.png"}, {"candidate", true}}}), "/items/0/candidate", ".factoria");
    fails(Json::array({Json{{"scene", "./scenes/main.scene.json"}, {"candidate", true}}}), "/items/0/candidate",
          "main scene");
    fails(Json::array({Json{{"scene", "scenes\\main.scene.json"}, {"candidate", true}}}), "/items/0/candidate",
          "main scene");
    // an effect's stage may not be a candidate (in either order)
    fails(Json::array({Json{{"vfx", "assets/vfx/a.vfx.json"}, {"stage", "scenes/variant.scene.json"}},
                       Json{{"scene", "scenes/variant.scene.json"}, {"candidate", true}}}),
          "/items/0/stage", "stage");
    fails(Json::array({Json{{"scene", "scenes/variant.scene.json"}, {"candidate", true}},
                       Json{{"vfx", "assets/vfx/a.vfx.json"}, {"stage", "./scenes/variant.scene.json"}}}),
          "/items/1/stage", "stage");
    // the same file twice where one is a candidate, in either order; twice without a candidate is fine
    fails(Json::array({Json{{"image", "assets/red.png"}}, Json{{"image", "assets/./red.png"}, {"candidate", true}}}),
          "/items/1/image", "already the file of item 1");
    fails(Json::array({Json{{"image", "assets/red.png"}, {"candidate", true}}, Json{{"image", "assets/red.png"}}}),
          "/items/1/image", "already the file of item 1");
    // the scene a level looks its entity up in is read, not moved: no candidate may be that file, in either order
    const Json lvl =
        Json::parse(R"({"level":{"sample":"example","size":[12,8]},"sampleScene":"scenes/variant.scene.json"})");
    fails(Json::array({lvl, Json{{"scene", "./scenes/variant.scene.json"}, {"candidate", true}}}), "/items/1/scene",
          "already the file of item 1");
    fails(Json::array({Json{{"scene", "scenes/variant.scene.json"}, {"candidate", true}}, lvl}), "/items/1/sampleScene",
          "candidate of item 1");
    const Json twice =
        p.ok("review.sheet",
             Json{{"items", Json::array({Json{{"image", "assets/red.png"}}, Json{{"image", "assets/red.png"}}})}});
    CHECK(twice["count"] == 2);
}

TEST_CASE("review: a link to a folder inside the project does not dodge the rules about the main scene and .factoria") {
    ReviewProject p;
    write_all(p.file(".factoria/keep.png"), "kept");
    std::error_code ec;
    stdfs::create_directory_symlink(p.file("scenes"), p.file("assets/scn"), ec);
    if (!ec) stdfs::create_directory_symlink(p.file(".factoria"), p.file("assets/fa"), ec);
    if (ec) {
        MESSAGE("symlink case skipped: " << ec.message());
        return;
    }
    const CommandResult viaLink =
        p.call("review.sheet",
               Json{{"items", Json::array({Json{{"scene", "assets/scn/main.scene.json"}, {"candidate", true}}})}});
    CHECK_FALSE(viaLink.ok);
    CHECK_MESSAGE(contains(message(viaLink), "main scene"), message(viaLink));
    const CommandResult viaFa = p.call(
        "review.sheet", Json{{"items", Json::array({Json{{"image", "assets/fa/keep.png"}, {"candidate", true}}})}});
    CHECK_FALSE(viaFa.ok);
    CHECK_MESSAGE(contains(message(viaFa), ".factoria"), message(viaFa));
    // and a hand-edited manifest cannot make a pick move them
    pick_is_refused(
        p,
        [](Json& m) {
            m["items"][2]["source"] = "assets/scn/main.scene.json";
            m["items"][2]["type"] = "scene";
        },
        "main scene");
    pick_is_refused(p, [](Json& m) { m["items"][2]["source"] = "assets/fa/keep.png"; }, ".factoria");
    CHECK(p.exists("scenes/main.scene.json"));
    CHECK(p.exists(".factoria/keep.png"));
}

TEST_CASE("resolve_project_path takes the project folder as a native string and the relative path as UTF-8") {
    TempDir tmp;
    const stdfs::path root = tmp.path / stdfs::path(std::u8string(u8"proyecto áé"));
    std::error_code ec;
    stdfs::create_directories(root / "assets", ec);
    write_png(root / "assets" / stdfs::path(std::u8string(u8"rojo ñ.png")), make_image(2, 2, {1, 2, 3, 255}));
    const auto found = resolve_project_path(root.string(), u8c(u8"assets/rojo ñ.png"));
    REQUIRE_MESSAGE(found.ok(), (found.ok() ? std::string() : found.error().message));
    CHECK(stdfs::exists(*found));
    CHECK(stdfs::equivalent(*found, root / "assets" / stdfs::path(std::u8string(u8"rojo ñ.png"))));
    CHECK_FALSE(resolve_project_path(root.string(), "../outside.png").ok());
}

// ---- levels sampled from a scene's Tilemap entity ----------------------------------------------------------------------------------

TEST_CASE("review.sheet: a level may sample the Tilemap entity of the main scene or of the scene the item names") {
    ReviewProject p;
    const std::string tiles =
        "0,0,0,0,0,0,0,0, 0,1,1,1,1,1,1,0, 0,1,0,0,1,0,1,0, 0,1,1,1,1,0,1,0, 0,1,0,1,1,1,1,0, 0,0,0,0,0,0,0,0";
    auto scene = [&](const std::string& entityId) {
        return std::string(
                   R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},{"id":")") +
               entityId +
               R"(","name":"Map","components":{"Tilemap":{"tileSize":[16,16],"width":8,"height":6,"tiles":[)" + tiles +
               "]}}}]}";
    };
    write_all(p.file("scenes/main.scene.json"), scene("example"));
    write_all(p.file("scenes/town.scene.json"), scene("town"));
    const std::string mainBytes = read_all(p.file("scenes/main.scene.json"));
    const std::string townBytes = read_all(p.file("scenes/town.scene.json"));

    // the documented example: the entity named `example`, looked up in the main scene
    const Json r = p.ok(
        "review.sheet",
        Json{{"items",
              Json::array({Json::parse(R"({"level":{"sample":"example","n":2,"size":[24,16]},"seeds":[1,2]})")})}});
    CHECK(r["count"] == 2);
    CHECK(r["warnings"].empty());
    CHECK(r["items"][0]["ok"] == true);
    CHECK(contains(r["items"][0]["info"].get<std::string>(), "24x16, seed 1"));
    Json m = p.manifest("sheet-0001");
    CHECK(m["items"][0]["spec"]["sampleScene"] == "scenes/main.scene.json");
    CHECK(m["items"][1]["spec"]["level"]["sample"] == "example");

    // the entity by its name, in another scene the item names
    const Json t = p.ok(
        "review.sheet",
        Json{
            {"items",
             Json::array(
                 {Json::parse(
                      R"({"level":{"sample":"town","n":2,"size":[12,8]},"sampleScene":"scenes/town.scene.json","seeds":[3]})"),
                  Json::parse(R"({"level":{"sample":"Map","n":2,"size":[12,8]},"label":"main map"})")})}});
    CHECK(t["count"] == 2);
    CHECK(t["items"][0]["ok"] == true);
    CHECK(t["items"][1]["ok"] == true);
    m = p.manifest(t["sheet"].get<std::string>());
    CHECK(m["items"][0]["spec"]["sampleScene"] == "scenes/town.scene.json");
    CHECK(m["items"][1]["spec"]["sampleScene"] == "scenes/main.scene.json");
    CHECK(m["items"][0]["numbers"]["width"] == 12);

    // an entity the scene does not have: the error names the item, nothing is written
    CommandResult missing = p.call(
        "review.sheet", Json{{"items", Json::array({Json::parse(R"({"level":{"sample":"town","size":[12,8]}})")})}});
    CHECK_FALSE(missing.ok);
    CHECK(contains(message(missing), "/items/0/level"));
    // `sampleScene` with ASCII rows, or of a file that is no scene, is refused with its pointer
    CommandResult rows = p.call(
        "review.sheet",
        Json{{"items", Json::array({Json::parse(
                           R"({"level":{"sample":["#."],"size":[4,4]},"sampleScene":"scenes/town.scene.json"})")})}});
    CHECK_FALSE(rows.ok);
    CHECK(contains(message(rows), "/items/0/sampleScene"));
    CommandResult notScene =
        p.call("review.sheet",
               Json{{"items", Json::array({Json::parse(
                                  R"({"level":{"sample":"town","size":[4,4]},"sampleScene":"factoria.json"})")})}});
    CHECK_FALSE(notScene.ok);
    CHECK(contains(message(notScene), "/items/0/sampleScene"));
    CommandResult elsewhere = p.call(
        "review.sheet",
        Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"sampleScene", "scenes/town.scene.json"}}})}});
    CHECK_FALSE(elsewhere.ok);
    CHECK(contains(message(elsewhere), "/items/0/sampleScene"));
    CHECK_FALSE(p.exists(".factoria/review/sheet-0003"));

    // the scenes were only read
    CHECK(read_all(p.file("scenes/main.scene.json")) == mainBytes);
    CHECK(read_all(p.file("scenes/town.scene.json")) == townBytes);

    // picking a level hands back the scene the entity came from
    const Json picked = p.ok("review.pick", Json{{"sheet", "sheet-0001"}, {"n", 2}});
    CHECK(picked["spec"]["sampleScene"] == "scenes/main.scene.json");
    CHECK(has_text(picked["nextSteps"], "sampleScene"));
}

TEST_CASE("review.sheet: an entity sample without a main scene needs sampleScene and says so") {
    ReviewProject p;
    {
        Json project = parse_json(read_all(p.file("factoria.json")), "factoria.json").value();
        project.erase("mainScene");
        write_all(p.file("factoria.json"), project.dump(2));
    }
    const CommandResult r = p.call(
        "review.sheet", Json{{"items", Json::array({Json::parse(R"({"level":{"sample":"example","size":[4,4]}})")})}});
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "/items/0/level/sample"));
    CHECK(contains(message(r), "sampleScene"));
    CHECK_FALSE(p.exists(".factoria/review/sheet-0001"));
}

// ---- all or nothing, for real ------------------------------------------------------------------------------------------------------

TEST_CASE("review.pick: a candidate held open by another program puts the earlier moves back and changes no manifest") {
    ReviewProject p;
    const bool rules = fs::windows_rules();
    fs::set_windows_rules(true);  // an open file cannot be replaced, as on Windows
    struct Restore {
        bool was;
        ~Restore() { fs::set_windows_rules(was); }
    } restore{rules};
    p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});
    const std::string manifestBefore = read_all(p.file(".factoria/review/sheet-0001/manifest.json"));
    const std::string greenBytes = read_all(p.file("assets/green.png"));
    {
        fs::ReadStream viewer(p.file("assets/blue.png"), std::ios::binary);  // a viewer, an antivirus scan
        REQUIRE(viewer.is_open());
        const CommandResult r = p.call("review.pick", Json{{"n", 1}});
        CHECK_FALSE(r.ok);
        CHECK(r.error.value("code", std::string()) == "busy");
        CHECK_MESSAGE(contains(message(r), "put back"), message(r));
        CHECK(contains(message(r), "blue.png"));
        CHECK(contains(message(r), "open in another program"));
        // item 2 (green) was moved before item 3 failed: it is back, byte for byte
        CHECK(p.exists("assets/green.png"));
        CHECK(read_all(p.file("assets/green.png")) == greenBytes);
        CHECK(p.exists("assets/blue.png"));
        CHECK(p.exists("assets/red.png"));
        CHECK_FALSE(p.exists(".factoria/review/dropped/sheet-0001/02_green.png"));
        CHECK(read_all(p.file(".factoria/review/sheet-0001/manifest.json")) == manifestBefore);
    }
    // the viewer let go: the same pick works
    const Json r = p.ok("review.pick", Json{{"n", 1}});
    CHECK(r["dropped"].size() == 2);
    CHECK(p.exists(".factoria/review/dropped/sheet-0001/03_blue.png"));
}

TEST_CASE("review store: a busy lock changes nothing and says so; the lock is free again afterwards") {
    ReviewProject p;
    p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});
    ShareEnv env = share_env();
    env.lockWaitSec = 0.2;
    env.lockStaleSec = 600.0;
    ScopedShareEnv scoped(env);
    const stdfs::path lockFile = p.file(".factoria/review") / kFeedbackShareLockFile;
    write_all(lockFile, "alive");  // another process holds it
    const std::string manifestBefore = read_all(p.file(".factoria/review/sheet-0001/manifest.json"));

    CommandResult pick = p.call("review.pick", Json{{"n", 1}});
    CHECK_FALSE(pick.ok);
    CHECK(pick.error.value("code", std::string()) == "busy");
    CHECK(contains(message(pick), "Nothing was changed"));
    for (const char* f : {"assets/red.png", "assets/green.png", "assets/blue.png"}) CHECK(p.exists(f));
    CHECK(read_all(p.file(".factoria/review/sheet-0001/manifest.json")) == manifestBefore);

    CommandResult sheet = p.call("review.sheet", Json{{"items", images3()}});
    CHECK_FALSE(sheet.ok);
    CHECK(sheet.error.value("code", std::string()) == "busy");
    CHECK_FALSE(p.exists(".factoria/review/sheet-0002"));

    CommandResult cleanup = p.call("review.cleanup", Json::object());
    CHECK_FALSE(cleanup.ok);
    CHECK(cleanup.error.value("code", std::string()) == "busy");
    // reading never needs the lock
    CHECK(p.call("review.list", Json::object()).ok);
    CHECK(p.call("review.info", Json::object()).ok);

    std::error_code ec;
    stdfs::remove(lockFile, ec);
    CHECK(p.call("review.pick", Json{{"n", 1}}).ok);
    CHECK_FALSE(stdfs::exists(lockFile));  // released
}

// ---- meta, an integer sheet argument ------------------------------------------------------------------------------------------------

TEST_CASE(
    "review: the meta object is stored by review.sheet and returned by review.pick, review.info and review.list") {
    ReviewProject p;
    const Json meta = Json::parse(R"({"slot":"hero","milestone":69,"nested":{"a":[1,2]}})");
    const Json made = p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}, {"meta", meta}});
    CHECK(made["meta"] == meta);
    CHECK(p.manifest("sheet-0001")["meta"] == meta);
    const Json plain = p.ok("review.sheet", Json{{"items", images3()}});
    CHECK(plain["meta"] == Json::object());
    CHECK(p.manifest("sheet-0002")["meta"] == Json::object());

    const Json list = p.ok("review.list", Json::object());
    CHECK(list["sheets"][1]["meta"] == meta);
    CHECK(list["sheets"][0]["meta"] == Json::object());
    CHECK(p.ok("review.info", Json{{"sheet", "sheet-0001"}})["meta"] == meta);
    // the sheet argument may be the number itself
    CHECK(p.ok("review.info", Json{{"sheet", 1}})["id"] == "sheet-0001");
    const Json picked = p.ok("review.pick", Json{{"sheet", 1}, {"n", 2}});
    CHECK(picked["sheet"] == "sheet-0001");
    CHECK(picked["meta"] == meta);
    CHECK(p.manifest("sheet-0001")["meta"] == meta);  // the pick keeps it
    CHECK_FALSE(p.call("review.pick", Json{{"sheet", 1.5}, {"n", 2}}).ok);

    // bad meta: a pointer, nothing written
    const CommandResult text = p.call("review.sheet", Json{{"items", images3()}, {"meta", "hero"}});
    CHECK_FALSE(text.ok);
    CHECK(contains(message(text), "meta"));
    const CommandResult big =
        p.call("review.sheet",
               Json{{"items", images3()}, {"meta", Json{{"blob", std::string(kReviewMetaMaxBytes + 10, 'x')}}}});
    CHECK_FALSE(big.ok);
    CHECK(contains(message(big), "/meta"));
    CHECK_FALSE(p.exists(".factoria/review/sheet-0003"));
}

// ---- housekeeping ------------------------------------------------------------------------------------------------------------------

TEST_CASE("review.cleanup: dropped candidates expire after a week, chosen files and unanswered sheets never, orphans "
          "after an hour") {
    ReviewProject p;
    p.ok("review.sheet",
         Json{{"candidates", true}, {"items", images3()}});  // sheet-0001: answered, drops green and blue
    p.ok("review.pick", Json{{"n", 1}});
    write_png(p.file("assets/yellow.png"), make_image(8, 8, {200, 200, 30, 255}));
    write_png(p.file("assets/violet.png"), make_image(8, 8, {150, 30, 200, 255}));
    p.ok("review.sheet",
         Json{{"items",
               Json::array({Json{{"image", "assets/yellow.png"}, {"candidate", true}},
                            Json{{"image", "assets/violet.png"}, {"candidate", true}}})}});  // sheet-0002: not answered
    const ReviewOutcome orphan = review_reserve(p.dir);  // sheet-0003: a process died before the manifest
    REQUIRE_MESSAGE(orphan.ok, orphan.message);
    CHECK(orphan.value["id"] == "sheet-0003");
    write_all(p.file(".factoria/review/sheet-0003/sheet.png.partial"), "half a picture");

    // listed as an orphan, not as a sheet
    const Json list = p.ok("review.list", Json::object());
    CHECK(list["total"] == 2);
    REQUIRE(list.contains("orphans"));
    CHECK(list["orphans"][0] == "sheet-0003");

    // today: nothing is old
    Json r = p.ok("review.cleanup", Json::object());
    CHECK(r["droppedExpired"].empty());
    CHECK(r["orphansRemoved"].empty());
    CHECK(r["dryRun"] == false);
    CHECK(p.exists(".factoria/review/dropped/sheet-0001/02_green.png"));
    CHECK(p.exists(".factoria/review/sheet-0003"));

    // 6 days on: still inside the week; the orphan is old enough
    {
        ClockAhead sixDays(6);
        r = p.ok("review.cleanup", Json{{"dryRun", true}});
        CHECK(r["droppedExpired"].empty());
        REQUIRE(r["orphansRemoved"].size() == 1);
        CHECK(p.exists(".factoria/review/sheet-0003"));  // a dry run removes nothing
        r = p.ok("review.cleanup", Json::object());
        CHECK(r["orphansRemoved"][0] == "sheet-0003");
        CHECK_FALSE(p.exists(".factoria/review/sheet-0003"));
        CHECK(p.exists(".factoria/review/dropped/sheet-0001/02_green.png"));
    }

    // a hand-edited entry that points at the chosen file is never deleted
    tamper(p, "sheet-0001", [](Json& m) { m["picked"]["dropped"][1]["to"] = "assets/red.png"; });

    // 8 days on
    {
        ClockAhead eightDays(8);
        r = p.ok("review.cleanup", Json{{"dryRun", true}});
        REQUIRE(r["droppedExpired"].size() == 1);
        CHECK(r["droppedExpired"][0]["files"].size() == 1);
        CHECK(p.exists(".factoria/review/dropped/sheet-0001/02_green.png"));  // a dry run deletes nothing
        r = p.ok("review.cleanup", Json::object());
        REQUIRE(r["droppedExpired"].size() == 1);
        CHECK(r["droppedExpired"][0]["files"][0] == ".factoria/review/dropped/sheet-0001/02_green.png");
        REQUIRE(r["skipped"].size() == 1);
        CHECK(r["skipped"][0]["sheet"] == "sheet-0001");
        CHECK(contains(r["skipped"][0]["reason"].get<std::string>(), "left alone"));
        CHECK_FALSE(p.exists(".factoria/review/dropped/sheet-0001/02_green.png"));
        CHECK(p.exists("assets/red.png"));     // the chosen one
        CHECK(p.exists("assets/yellow.png"));  // the sheet nobody answered
        CHECK(p.exists("assets/violet.png"));
        const Json m = p.manifest("sheet-0001");
        CHECK(m["picked"]["dropped"][0]["status"] == "expired");
        CHECK(m["picked"]["dropped"][1]["status"] == "moved");
        CHECK(m["picked"]["n"] == 1);
        // the same call again has nothing left to do for the expired one
        r = p.ok("review.cleanup", Json::object());
        CHECK(r["droppedExpired"].empty());
        // droppedDays 0 keeps files for ever, whatever the age
        CHECK(p.ok("review.cleanup", Json{{"droppedDays", 0}})["droppedExpired"].empty());
    }
    CHECK_FALSE(p.call("review.cleanup", Json{{"droppedDays", -1}}).ok);
    CHECK(contains(message(p.call("review.cleanup", Json{{"orphanMinutes", 1e9}})), "/orphanMinutes"));
}

TEST_CASE("review.cleanup: a hand-edited atUnix that is huge, negative or not a number never overflows") {
    ReviewProject p;
    p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});
    p.ok("review.pick", Json{{"n", 1}});
    ClockAhead later(30);
    for (const double at : {1e300, -1e300, 9.3e18, 4e12, -1.0}) {
        tamper(p, "sheet-0001", [at](Json& m) { m["picked"]["atUnix"] = at; });
        const CommandResult r = p.call("review.cleanup", Json{{"dryRun", true}});
        CHECK_MESSAGE(r.ok, r.error.dump());
        if (r.ok) CHECK_MESSAGE(r.result["droppedExpired"].size() == (at < 1e12 ? 1u : 0u), at);
    }
    tamper(p, "sheet-0001", [](Json& m) { m["picked"]["atUnix"] = std::int64_t(9223372036854775807LL); });
    CHECK(p.call("review.cleanup", Json{{"dryRun", true}}).ok);
    // an unsigned number above INT64_MAX is far in the future, not a negative (long gone) date: nothing expires
    for (const std::uint64_t at : {std::uint64_t(9223372036854775808ULL), std::uint64_t(18446744073709551615ULL)}) {
        tamper(p, "sheet-0001", [at](Json& m) { m["picked"]["atUnix"] = at; });
        const CommandResult r = p.call("review.cleanup", Json{{"dryRun", true}});
        CHECK_MESSAGE(r.ok, r.error.dump());
        if (r.ok) CHECK_MESSAGE(r.result["droppedExpired"].empty(), at);
    }
}

TEST_CASE("review: a manifest whose numbers are strings is refused or skipped with a reason, never a crash") {
    ReviewProject p;
    pick_is_refused(p, [](Json& m) { m["items"][2]["n"] = "3"; }, "whole number");
    pick_is_refused(p, [](Json& m) { m["items"][2]["n"] = 3.5; }, "whole number");
    {
        // already answered, with a text where the number should be
        p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});
        tamper(p, "sheet-0002", [](Json& m) { m["picked"] = Json::object({{"n", "two"}, {"at", 7}}); });
        const CommandResult again = p.call("review.pick", Json{{"sheet", "sheet-0002"}, {"n", 1}});
        CHECK_FALSE(again.ok);
        CHECK(again.error.value("code", std::string()) == "already_picked");
        CHECK(p.call("review.list", Json::object()).ok);
        CHECK(p.call("review.info", Json{{"sheet", "sheet-0002"}}).ok);
    }
    // review.cleanup: an entry of picked.dropped without a whole number `n` is left alone and reported; the others still expire
    p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});  // sheet-0003
    p.ok("review.pick", Json{{"sheet", "sheet-0003"}, {"n", 1}});
    tamper(p, "sheet-0003", [](Json& m) { m["picked"]["dropped"][0]["n"] = "2"; });
    ClockAhead later(8);
    const Json r = p.ok("review.cleanup", Json::object());
    REQUIRE(r["skipped"].size() == 1);
    CHECK(contains(r["skipped"][0]["reason"].get<std::string>(), "whole number"));
    REQUIRE(r["droppedExpired"].size() == 1);
    CHECK(r["droppedExpired"][0]["files"].size() == 1);
    CHECK(p.exists(".factoria/review/dropped/sheet-0003/02_green.png"));  // the entry with the bad number stays
    CHECK_FALSE(p.exists(".factoria/review/dropped/sheet-0003/03_blue.png"));
    CHECK(p.manifest("sheet-0003")["picked"]["dropped"][0]["status"] == "moved");
}

#ifndef _WIN32
TEST_CASE("review.cleanup: a dropped file that cannot be looked at is skipped with the reason, not marked gone") {
    if (::geteuid() == 0) {
        MESSAGE("skipped: root can look at any folder");
        return;
    }
    ReviewProject p;
    p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});
    p.ok("review.pick", Json{{"n", 1}});
    const stdfs::path dropped = p.file(".factoria/review/dropped/sheet-0001");
    struct Restore {
        stdfs::path dir;
        ~Restore() {
            std::error_code ec;
            stdfs::permissions(dir, stdfs::perms::owner_all, ec);
        }
    } restore{dropped};
    std::error_code ec;
    stdfs::permissions(dropped, stdfs::perms::none, ec);
    REQUIRE_FALSE(ec);
    ClockAhead later(8);
    const CommandResult r = p.call("review.cleanup", Json::object());
    stdfs::permissions(dropped, stdfs::perms::owner_all, ec);
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["droppedExpired"].empty());
    CHECK(r.result["skipped"].size() == 2);
    const Json m = p.manifest("sheet-0001");
    CHECK(m["picked"]["dropped"][0]["status"] == "moved");
    CHECK(m["picked"]["dropped"][1]["status"] == "moved");
    CHECK(p.exists(".factoria/review/dropped/sheet-0001/02_green.png"));
}
#endif

namespace {

// True when `text` is well-formed UTF-8 (no cut character).
bool valid_utf8(const std::string& text) {
    std::size_t i = 0;
    while (i < text.size()) {
        const unsigned char c = static_cast<unsigned char>(text[i]);
        const std::size_t extra = c < 0x80           ? 0
                                  : (c >> 5) == 0x6  ? 1
                                  : (c >> 4) == 0xE  ? 2
                                  : (c >> 3) == 0x1E ? 3
                                                     : std::size_t(-1);
        if (extra == std::size_t(-1) || i + extra >= text.size()) return false;
        for (std::size_t k = 1; k <= extra; ++k)
            if ((static_cast<unsigned char>(text[i + k]) & 0xC0) != 0x80) return false;
        i += extra + 1;
    }
    return true;
}

}  // namespace

TEST_CASE("review_drop_file_name: NN_ and the name, cut to 255 bytes at a character boundary with the extension kept") {
    CHECK(review_drop_file_name(2, "assets/green.png") == "02_green.png");
    CHECK(review_drop_file_name(12, "a/b/c.png") == "12_c.png");
    const std::string accents = u8c(u8"ñé");
    // short: untouched
    CHECK(review_drop_file_name(1, "assets/" + accents + ".png") == "01_" + accents + ".png");
    // 255 bytes exactly: untouched
    const std::string exact = std::string(248, 'a') + ".png";  // + "01_" = 255
    CHECK(review_drop_file_name(1, "assets/" + exact) == "01_" + exact);
    // one byte over: the stem loses one character, the extension stays
    const std::string over = std::string(249, 'a') + ".png";
    const std::string cut = review_drop_file_name(1, "assets/" + over);
    CHECK(cut.size() == 255);
    CHECK(cut == "01_" + std::string(248, 'a') + ".png");
    // a two-byte character that straddles the cut (bytes 250 and 251 of the name; the stem may keep 251 bytes): it goes whole
    const std::string straddle = std::string(247, 'a') + u8c(u8"ñ") + std::string(10, 'x') + ".png";
    const std::string s1 = review_drop_file_name(1, "assets/" + straddle);
    CHECK(s1.size() <= 255);
    CHECK(valid_utf8(s1));
    CHECK(s1.compare(s1.size() - 4, 4, ".png") == 0);
    CHECK(s1 == "01_" + std::string(247, 'a') + ".png");
    // a two-byte character whose last byte is exactly byte 251 of the name: kept, and the result is exactly 255 bytes
    const std::string fits = std::string(246, 'a') + u8c(u8"é") + std::string(10, 'x') +
                             ".png";  // "01_" + 246 a = 249; é = 249, 250; stem cut at 251
    const std::string s2 = review_drop_file_name(1, "assets/" + fits);
    CHECK(valid_utf8(s2));
    CHECK(s2.size() <= 255);
    CHECK(s2.compare(s2.size() - 4, 4, ".png") == 0);
    CHECK(s2.find(u8c(u8"é")) != std::string::npos);
    // a two-byte character that starts exactly where the stem must end (bytes 251 and 252 of the name): it is dropped whole, 255 bytes remain
    const std::string edge = std::string(248, 'a') + u8c(u8"é") + std::string(5, 'y') + ".png";
    const std::string s3 = review_drop_file_name(1, "assets/" + edge);
    CHECK(valid_utf8(s3));
    CHECK(s3 == "01_" + std::string(248, 'a') + ".png");
    CHECK(s3.size() == 255);
    // three- and four-byte characters (the euro sign, an emoji) are never split either
    for (const std::string& wide : {u8c(u8"\u20ac"), u8c(u8"\U0001F600")}) {
        for (int pad = 244; pad <= 250; ++pad) {
            const std::string name = std::string(std::size_t(pad), 'a') + wide + wide + ".png";
            const std::string result = review_drop_file_name(7, "x/" + name);
            CHECK_MESSAGE(valid_utf8(result), pad);
            CHECK_MESSAGE(result.size() <= 255, pad);
            CHECK_MESSAGE(result.compare(result.size() - 4, 4, ".png") == 0, pad);
        }
    }
}

TEST_CASE(
    "review.pick: a long file name keeps the dropped name inside 255 bytes, and review.cleanup still finds the file") {
    ReviewProject p;
    const std::string longName = std::string(249, 'a') + ".png";  // 253 bytes: with "01_" it is 256
    const stdfs::path longFile = p.file("assets/" + longName);
    {
        std::ofstream out(fs::os_path(longFile), std::ios::binary);
        const std::string bytes = png_string(make_image(8, 8, {200, 30, 30, 255}));
        out.write(bytes.data(), std::streamsize(bytes.size()));
        REQUIRE(out.good());
    }
    const Json made = p.ok(
        "review.sheet",
        Json{{"candidates", true},
             {"items", Json::array({Json{{"image", "assets/" + longName}}, Json{{"image", "assets/green.png"}}})}});
    const Json picked = p.ok("review.pick", Json{{"sheet", made["sheet"]}, {"n", 2}});
    REQUIRE(picked["dropped"].size() == 1);
    const std::string to = picked["dropped"][0]["to"].get<std::string>();
    const std::string name = to.substr(to.rfind('/') + 1);
    CHECK(name.size() == 255);
    CHECK(name.compare(0, 3, "01_") == 0);
    CHECK(name.compare(name.size() - 4, 4, ".png") == 0);
    std::error_code ec;
    CHECK(stdfs::exists(fs::os_path(p.file(to)), ec));
    CHECK_FALSE(stdfs::exists(fs::os_path(longFile), ec));
    ClockAhead later(8);
    const Json cleaned = p.ok("review.cleanup", Json::object());
    CHECK(cleaned["droppedExpired"].size() == 1);
    CHECK(cleaned["skipped"].empty());
    CHECK_FALSE(stdfs::exists(fs::os_path(p.file(to)), ec));
}

TEST_CASE("review store: a project folder that cannot hold the lock says so and changes nothing") {
    ReviewProject p;
    write_all(p.file(".factoria/review"), "a file where the folder should be");
    const CommandResult sheet = p.call("review.sheet", Json{{"items", images3()}});
    CHECK_FALSE(sheet.ok);
    CHECK_MESSAGE(contains(message(sheet), "cannot be changed"), message(sheet));
    CHECK_MESSAGE(contains(message(sheet), "Nothing was changed"), message(sheet));
    CHECK(sheet.error.value("code", std::string()) != "busy");
    for (const char* f : {"assets/red.png", "assets/green.png", "assets/blue.png"}) CHECK(p.exists(f));
}

TEST_CASE("review.sheet: a new sheet cleans up what is old (and a failing cleanup is a warning, not an error)") {
    ReviewProject p;
    p.ok("review.sheet", Json{{"candidates", true}, {"items", images3()}});
    p.ok("review.pick", Json{{"n", 1}});
    CHECK(p.exists(".factoria/review/dropped/sheet-0001/03_blue.png"));
    write_png(p.file("assets/green.png"), make_image(16, 24, {30, 200, 30, 255}));
    write_png(p.file("assets/blue.png"), make_image(64, 64, {30, 30, 200, 255}));
    ClockAhead later(10);
    const Json r = p.ok("review.sheet", Json{{"items", images3()}});
    CHECK_FALSE(p.exists(".factoria/review/dropped/sheet-0001/03_blue.png"));
    CHECK(p.manifest("sheet-0001")["picked"]["dropped"][1]["status"] == "expired");
    CHECK(r["warnings"].empty());
}

// ---- pictures that announce a huge size ---------------------------------------------------------------------------------------------

TEST_CASE("review.sheet: a JPEG, BMP or TGA header that announces a huge picture is refused before any pixel is made") {
    ReviewProject p;
    auto le32 = [](std::string& s, std::size_t at, std::uint32_t v) {
        for (int i = 0; i < 4; ++i) s[at + std::size_t(i)] = char((v >> (8 * i)) & 0xFF);
    };
    std::string bmp(54, '\0');
    bmp[0] = 'B';
    bmp[1] = 'M';
    le32(bmp, 10, 54);
    le32(bmp, 14, 40);
    le32(bmp, 18, 20000);
    le32(bmp, 22, 20000);
    bmp[26] = 1;
    bmp[28] = 24;
    write_all(p.file("assets/huge.bmp"), bmp);
    std::string jpg = "\xFF\xD8\xFF\xC0";
    jpg += std::string("\0\x11\x08\x4E\x20\x4E\x20\x03", 8);
    jpg += std::string(10, '\0');
    write_all(p.file("assets/huge.jpg"), jpg);
    std::string tga(18, '\0');
    tga[2] = 2;
    tga[12] = char(0x20);
    tga[13] = char(0x4E);
    tga[14] = char(0x20);
    tga[15] = char(0x4E);
    tga[16] = 32;
    write_all(p.file("assets/huge.tga"), tga);
    for (const char* name : {"assets/huge.bmp", "assets/huge.jpg", "assets/huge.tga"}) {
        const Json r = p.ok("review.sheet",
                            Json{{"items", Json::array({Json{{"image", "assets/red.png"}}, Json{{"image", name}}})}});
        CHECK_MESSAGE(r["items"][1]["ok"] == false, name);
        CHECK_MESSAGE(has_warning(r, "20000x20000"), name);
    }
}

TEST_CASE(
    "review.sheet: a file the decoder could read but whose size cannot be checked (GIF, PSD, HDR) is a red tile") {
    ReviewProject p;
    write_all(p.file("assets/anim.png"), std::string("GIF89a") + std::string(40, '\x01'));
    write_all(p.file("assets/layers.jpg"), std::string("8BPS") + std::string(40, '\x01'));
    write_all(p.file("assets/light.bmp"), std::string("#?RADIANCE\n") + std::string(40, 'x'));
    for (const char* name : {"assets/anim.png", "assets/layers.jpg", "assets/light.bmp"}) {
        const Json r = p.ok("review.sheet",
                            Json{{"items", Json::array({Json{{"image", "assets/red.png"}}, Json{{"image", name}}})}});
        CHECK_MESSAGE(r["items"][1]["ok"] == false, name);
        CHECK_MESSAGE(has_warning(r, "not a PNG, JPEG, BMP or TGA"), name);
    }
}

TEST_CASE("review.sheet: a sheet of the largest pictures holds the thumbnails, not the pictures") {
    ReviewProject p;
    // 24 pictures of 1200 x 1200 (5.7 MB each as pixels, 138 MB together if all were kept) still make one sheet; each is shrunk right after it is read
    constexpr int kBig = 24;
    write_png(p.file("assets/big.png"), make_image(1200, 1200, {20, 100, 200, 255}));
    Json items = Json::array();
    for (int i = 0; i < kBig; ++i)
        items.push_back(Json{{"image", "assets/big.png"}, {"label", "big " + std::to_string(i + 1)}});
    const Json r = p.ok("review.sheet", Json{{"items", items}, {"thumbSize", 64}});
    CHECK(r["count"] == kBig);
    CHECK(r["warnings"].empty());
    CHECK(r["picture"]["width"].get<int>() <= 2000);
    CHECK(r["picture"]["height"].get<int>() <= 2000);
    const Image thumb = read_png(p.file(".factoria/review/sheet-0001/thumbs/24.png"));
    CHECK(thumb.width == 64);
    CHECK(near_color(thumb, 32, 32, 20, 100, 200));
}

// ---- unicode project folders ---------------------------------------------------------------------------------------------------------

TEST_CASE("review commands work in a project whose folder has accents") {
    ScratchShareHome home;
    TempDir tmp;
    const stdfs::path root = tmp.path / stdfs::path(u8"proyecto áé ñ");
    const std::string dir = root.string();  // native, like every project folder the engine is given
    REQUIRE(create_project(dir, "2d-empty").ok());
    CommandRegistry reg;
    register_tooling_commands(reg, dir);
    write_png(root / "assets" / stdfs::path(u8"rojo ñ.png"), make_image(16, 16, {200, 30, 30, 255}));
    write_png(root / "assets" / stdfs::path(u8"verde.png"), make_image(16, 16, {30, 200, 30, 255}));
    const CommandResult made = reg.call(
        "review.sheet", Json{{"items", Json::array({Json{{"image", u8c(u8"assets/rojo ñ.png")}, {"candidate", true}},
                                                    Json{{"image", "assets/verde.png"}, {"candidate", true}}})},
                             {"label", "¿Cuál?"}});
    REQUIRE_MESSAGE(made.ok, made.error.dump());
    CHECK(made.result["items"][0]["label"] == u8c(u8"rojo ñ"));
    const std::string pictureText = made.result["$image"]["path"].get<std::string>();
    CHECK(stdfs::exists(
        fa::fs::path_from_utf8(pictureText)));  // `$image.path` is UTF-8, like every string in a JSON result
    const CommandResult picked = reg.call("review.pick", Json{{"n", 2}});
    REQUIRE_MESSAGE(picked.ok, picked.error.dump());
    CHECK(picked.result["dropped"][0]["from"] == u8c(u8"assets/rojo ñ.png"));
    CHECK_FALSE(stdfs::exists(root / "assets" / stdfs::path(u8"rojo ñ.png")));
    CHECK(stdfs::exists(root / ".factoria" / "review" / "dropped" / "sheet-0001" / stdfs::path(u8"01_rojo ñ.png")));
    CHECK(stdfs::exists(root / "assets" / "verde.png"));
    CHECK(reg.call("review.list", Json::object()).ok);
    CHECK(reg.call("review.cleanup", Json{{"dryRun", true}}).ok);
}

// ---- every kind of GPU item on one sheet --------------------------------------------------------------------------------------------

TEST_CASE("review.sheet: scene, 2D and 3D prefabs and effects (plain stage and a stage of the project) share one "
          "engine and leave nothing behind") {
    ReviewProject p;
    write_all(p.file("scenes/level.scene.json"), R"({"format":"factoria.scene/1","entities":[
      {"id":"cam","components":{"Transform":{},"Camera":{"orthoSize":100,"clearColor":[0,0,0,1]}}},
      {"id":"hero","components":{"Transform":{"position":[-50,0,0]},"Shape2D":{"shape":"rectangle","size":[20,20],"color":[0,0,1,1]}}}]})");
    write_all(p.file("prefabs/box.prefab.json"), R"({"format":"factoria.prefab/1","entity":
      {"id":"box","components":{"Transform":{},"Shape2D":{"shape":"rectangle","size":[20,10],"color":[0,1,0,1]}}}})");
    write_all(p.file("prefabs/cube.prefab.json"), R"({"format":"factoria.prefab/1","entity":
      {"id":"cube","components":{"Transform":{"scale":[1,1,1]},"MeshRenderer":{"mesh":"cube","color":[0.9,0.45,0.2,1]}}}})");
    write_all(
        p.file("assets/vfx/burst.vfx.json"),
        R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","emitter":{"burst":40,"lifetime":1.0,"startSize":8,"speed":60}}]})");
    const std::string stageBytes = read_all(p.file("scenes/level.scene.json"));
    const CommandResult r =
        p.call("review.sheet", Json{{"items", Json::array({Json{{"scene", "scenes/level.scene.json"}, {"steps", 1}},
                                                           Json{{"prefab", "prefabs/box.prefab.json"}},
                                                           Json{{"prefab", "prefabs/cube.prefab.json"}},
                                                           Json{{"vfx", "assets/vfx/burst.vfx.json"}},
                                                           Json{{"vfx", "assets/vfx/burst.vfx.json"},
                                                                {"stage", "scenes/level.scene.json"},
                                                                {"label", "on the level"}},
                                                           Json{{"image", "assets/red.png"}}})}});
    if (no_gpu(r)) {
        CHECK_FALSE(p.exists(".factoria/review/sheet-0001"));
        return;
    }
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK_MESSAGE(r.result["warnings"].empty(), r.result["warnings"].dump());
    for (std::size_t i = 0; i < 6; ++i) CHECK_MESSAGE(r.result["items"][i]["ok"] == true, r.result["items"][i].dump());
    CHECK(r.result["items"][2]["type"] == "prefab");
    CHECK(r.result["items"][3]["type"] == "vfx");
    CHECK(r.result["items"][4]["label"] == "on the level");
    const Json m = p.manifest("sheet-0001");
    const Image sheet = read_png(p.file(".factoria/review/sheet-0001/sheet.png"));
    // the 3D cube is drawn: its area is not one flat colour
    const Json& area = m["items"][2]["picture"];
    const Rgba corner = get(sheet, area["x"].get<int>() + 1, area["y"].get<int>() + 1);
    int different = 0;
    for (int y = area["y"].get<int>(); y < area["y"].get<int>() + area["h"].get<int>(); ++y)
        for (int x = area["x"].get<int>(); x < area["x"].get<int>() + area["w"].get<int>(); ++x) {
            const Rgba c = get(sheet, x, y);
            if (std::abs(int(c.r) - corner.r) + std::abs(int(c.g) - corner.g) + std::abs(int(c.b) - corner.b) > 60)
                ++different;
        }
    CHECK(different > 200);
    // the project's scene that was a stage is untouched, and the scratch folder has no stage left
    CHECK(read_all(p.file("scenes/level.scene.json")) == stageBytes);
    std::error_code ec;
    int leftovers = 0;
    for (stdfs::directory_iterator it(p.file(".factoria/tmp"), ec), end; !ec && it != end; it.increment(ec))
        ++leftovers;
    CHECK(leftovers == 0);
}
