// review.sheet / review.pick / review.list / review.info: N candidates as one numbered picture, the stored sheet and the pick.
// Images, vector art and levels are drawn on the CPU, so those tests run everywhere; scene, prefab and effect items need a graphics
// device and skip (with a message) where the engine finds none. No golden hashes: structure, sizes and a few pixels with tolerance.
#include <doctest.h>

#include <set>

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
    stdfs::path file(const std::string& rel) const { return stdfs::path(dir) / stdfs::path(std::u8string(rel.begin(), rel.end())); }
    bool exists(const std::string& rel) const { return stdfs::exists(file(rel)); }
    CommandResult call(const std::string& name, const Json& args) const { return reg.call(name, args); }
    Json ok(const std::string& name, const Json& args) const {
        CommandResult r = reg.call(name, args);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    }
    Json manifest(const std::string& sheet) const { return parse_json(read_all(file(".factoria/review/" + sheet + "/manifest.json")), "manifest").value(); }
};

std::string message(const CommandResult& r) { return r.error.value("code", std::string()) + ": " + r.error.value("message", std::string()) + " | " + r.error.value("hint", std::string()); }

bool contains(const std::string& s, const std::string& needle) { return s.find(needle) != std::string::npos; }

bool no_gpu(const CommandResult& r) {
    if (r.ok || r.error.value("code", std::string()) != "no_gpu") return false;
    MESSAGE("skipped: no graphics device on this machine (" << r.error.value("message", std::string()) << ")");
    return true;
}

Json level_item(const std::string& seeds) {
    return Json::parse(R"({"level":{"sample":["................","..####..........","..#..#....##....","..#..#....##....","..####..........","................","......#.........",
      "......#....###..","...........#.#..","...........###.."],"legend":{"#":0},"size":[24,16]},"seeds":)" + seeds + "}");
}

Json images3() {
    return Json::array({Json{{"image", "assets/red.png"}, {"label", "round"}, {"candidate", true}}, Json{{"image", "assets/green.png"}, {"candidate", true}},
                        Json{{"image", "assets/blue.png"}, {"candidate", true}}});
}

bool near_color(const Image& img, int x, int y, int r, int g, int b, int tolerance = 3) {
    if (x < 0 || y < 0 || x >= img.width || y >= img.height) return false;
    const Rgba c = get(img, x, y);
    return std::abs(int(c.r) - r) <= tolerance && std::abs(int(c.g) - g) <= tolerance && std::abs(int(c.b) - b) <= tolerance;
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
    const Image sheet = read_png(stdfs::path(std::u8string(picturePath.begin(), picturePath.end())));
    CHECK(sheet.width == r["picture"]["width"].get<int>());
    CHECK(sheet.height == r["picture"]["height"].get<int>());
    CHECK(sheet.width <= 2000);
    CHECK(sheet.height <= 700);

    // the files of the sheet
    CHECK(p.exists(".factoria/review/sheet-0001/sheet.png"));
    CHECK(p.exists(".factoria/review/sheet-0001/manifest.json"));
    for (const char* thumb : {"01", "02", "03"}) CHECK(p.exists(std::string(".factoria/review/sheet-0001/thumbs/") + thumb + ".png"));
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
        CHECK(near_color(sheet, c["x"].get<int>() + 9, c["y"].get<int>() + 9, 242, 183, 5));  // the amber badge of the number
    }
    CHECK(xs.size() == 3);
    // the red 32x32 picture is enlarged by a whole factor with hard pixels: the middle of its area is exactly red
    const Json& red = m["items"][0]["picture"];
    CHECK(near_color(sheet, red["x"].get<int>() + red["w"].get<int>() / 2, red["y"].get<int>() + red["h"].get<int>() / 2, 200, 30, 30));
    // the 16x24 picture keeps its proportions: green in the middle, the background at the left edge of its area
    const Json& green = m["items"][1]["picture"];
    CHECK(near_color(sheet, green["x"].get<int>() + green["w"].get<int>() / 2, green["y"].get<int>() + green["h"].get<int>() / 2, 30, 200, 30));
    CHECK_FALSE(near_color(sheet, green["x"].get<int>() + 2, green["y"].get<int>() + green["h"].get<int>() / 2, 30, 200, 30));
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
        CHECK(read_all(p.file(std::string(".factoria/review/sheet-0001/thumbs/") + t + ".png")) == read_all(p.file(std::string(".factoria/review/sheet-0002/thumbs/") + t + ".png")));
    // an explicit layout is obeyed
    const Json c = p.ok("review.sheet", Json{{"items", images3()}, {"columns", 2}, {"thumbSize", 100}});
    CHECK(c["columns"] == 2);
    CHECK(c["rows"] == 2);
    CHECK(c["thumbSize"] == 100);
    CHECK(c["picture"]["width"].get<int>() < a["picture"]["width"].get<int>());
}

TEST_CASE("review.sheet: levels, one thumbnail per seed, no GPU needed") {
    ReviewProject p;
    const Json r = p.ok("review.sheet", Json{{"items", Json::array({level_item("[1, 2, 3]")})}, {"label", "Pick a layout"}});
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
    const Json one = p.ok("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/red.png"}},
                                                                     Json::parse(R"({"level":{"sample":["................","..####..........","..#..#....##....","..#..#....##....","..####..........","................","......#.........","......#....###..","...........#.#..","...........###.."],"legend":{"#":0},"size":[24,16],"seed":9},"label":"mine"})")})}});
    CHECK(one["count"] == 2);
    CHECK(one["items"][1]["label"] == "mine");
    CHECK(contains(one["items"][1]["info"].get<std::string>(), "seed 9"));
}

TEST_CASE("review.sheet: vector art is rasterized and counted") {
    ReviewProject p;
    write_all(p.file("assets/logo.svg"),
              R"(<svg xmlns="http://www.w3.org/2000/svg" width="40" height="20" viewBox="0 0 40 20"><rect x="0" y="0" width="40" height="20" fill="#ff0000"/><circle cx="20" cy="10" r="6" fill="#00ff00"/></svg>)");
    const Json r = p.ok("review.sheet", Json{{"items", Json::array({Json{{"vector", "assets/logo.svg"}}, Json{{"image", "assets/red.png"}}})}});
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
    const Json r = p.ok("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/red.png"}}, Json{{"image", "assets/broken.png"}}})}});
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
    huge += std::string("\0\0\0\x0d" "IHDR", 8);
    huge += std::string("\0\0\x4e\x20\0\0\x4e\x20\x08\x06\0\0\0", 13);
    write_all(p.file("assets/huge.png"), huge);
    const Json big = p.ok("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/red.png"}}, Json{{"image", "assets/huge.png"}}})}});
    CHECK(big["items"][1]["ok"] == false);
    CHECK(has_warning(big, "20000x20000"));

    CommandResult all = p.call("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/broken.png"}}})}});
    CHECK_FALSE(all.ok);
    CHECK(contains(message(all), "None of the 1 items could be drawn"));
    CHECK_FALSE(p.exists(".factoria/review/sheet-0003"));  // nothing was left behind
}

TEST_CASE("review.pick: picking moves the files of the other candidates and updates the manifest") {
    ReviewProject p;
    p.ok("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"candidate", true}}, Json{{"image", "assets/green.png"}, {"candidate", true}},
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
    for (const char* f : {"assets/red.png", "assets/green.png", "assets/blue.png"}) CHECK(p.exists(f));  // nothing moved
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
    CHECK(contains(fails(Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"scene", "scenes/main.scene.json"}}})}}, "/items/0"), "ONE thing"));
    fails(Json{{"items", Json::array({Json{{"label", "x"}}})}}, "/items/0");
    fails(Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"steps", 3}}})}}, "/items/0/steps");
    fails(Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"seeds", Json::array({1})}}})}}, "/items/0/seeds");
    // the file
    const std::string missing = fails(Json{{"items", Json::array({good, Json{{"image", "assets/gren.png"}}})}}, "/items/1/image");
    CHECK(contains(missing, "green.png"));  // did you mean
    CHECK(contains(fails(Json{{"items", Json::array({Json{{"image", "assets/red.json"}}})}}, "/items/0/image"), ".png"));
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
    CHECK(contains(fails(Json::parse(R"({"level":{"sample":["#."],"into":"map","size":[4,4]}})"), "/items/0/level/into"), "Leave `into` out"));
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
    CHECK(contains(fails(Json{{"level", Json::parse(R"({"sample":["#."],"size":[4,4]})")}, {"seeds", sixty}}, "/items/0/seeds"), std::to_string(kReviewMaxItems)));
    // a problem of tilemap.generate itself comes back with the pointer of the item
    CommandResult r = p.call("review.sheet", Json{{"items", Json::array({Json::parse(R"({"level":{"sample":"nobody","size":[4,4]}})")})}});
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "/items/0/level"));
    CHECK_FALSE(p.exists(".factoria/review/sheet-0001"));
}

TEST_CASE("review.sheet: a candidate may not be the main scene, a repeated file or inside .git") {
    ReviewProject p;
    write_all(p.file("scenes/variant.scene.json"), read_all(p.file("scenes/main.scene.json")));
    CommandResult r = p.call("review.sheet", Json{{"items", Json::array({Json{{"scene", "scenes/main.scene.json"}, {"candidate", true}}})}});
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "main scene"));
    CHECK(contains(message(r), "/items/0/candidate"));
    r = p.call("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"candidate", true}}, Json{{"image", "assets/RED.png"}, {"candidate", true}}})}});
    CHECK_FALSE(r.ok);  // the same file twice (the second is not on a case-sensitive disk: it is missing, or the same file)
    CHECK(contains(message(r), "/items/1"));
    r = p.call("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/red.png"}, {"candidate", true}}, Json{{"image", "assets/./red.png"}, {"candidate", true}}})}});
    CHECK_FALSE(r.ok);
    CHECK(contains(message(r), "already a candidate"));
    CHECK(p.exists("assets/red.png"));
}

TEST_CASE("review.sheet: scenes, prefabs and effects need a GPU and say so before anything is written") {
    ReviewProject p;
    write_all(p.file("scenes/level.scene.json"), R"({"format":"factoria.scene/1","entities":[
      {"id":"cam","components":{"Transform":{},"Camera":{"orthoSize":100,"clearColor":[0,0,0,1]}}},
      {"id":"hero","components":{"Transform":{"position":[-50,0,0]},"Shape2D":{"shape":"rectangle","size":[20,20],"color":[0,0,1,1]}}}]})");
    write_all(p.file("prefabs/box.prefab.json"), R"({"format":"factoria.prefab/1","entity":
      {"id":"box","components":{"Transform":{},"Shape2D":{"shape":"rectangle","size":[20,10],"color":[0,1,0,1]}}}})");
    CommandResult r = p.call("review.sheet", Json{{"items", Json::array({Json{{"image", "assets/red.png"}}, Json{{"scene", "scenes/level.scene.json"}, {"steps", 1}},
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
    CHECK(near_color(sheet, pa["x"].get<int>() + pa["w"].get<int>() / 2, pa["y"].get<int>() + pa["h"].get<int>() / 2, 0, 255, 0, 60));
    // no stage scene is left in the scratch folder
    std::error_code ec;
    int leftovers = 0;
    for (stdfs::directory_iterator it(p.file(".factoria/tmp"), ec), end; !ec && it != end; it.increment(ec)) ++leftovers;
    CHECK(leftovers == 0);
}

TEST_CASE("review.list: newest first, a limit, and sheets that cannot be read are reported") {
    ReviewProject p;
    for (int i = 0; i < 3; ++i) p.ok("review.sheet", Json{{"items", images3()}, {"label", "round " + std::to_string(i + 1)}});
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

TEST_CASE("review store: unicode folder names, an abandoned sheet leaves nothing, a sheet in the making is not listed") {
    TempDir tmp;
    ScratchShareHome home;
    const stdfs::path root = tmp.path / stdfs::path(std::u8string(u8"proyecto áé"));
    std::error_code ec;
    stdfs::create_directories(root, ec);
    const std::string dir(reinterpret_cast<const char*>(root.generic_u8string().c_str()));
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
    Json manifest = Json::object({{"label", "café"}, {"items", Json::array({Json::object({{"n", 1}, {"type", "level"}, {"label", "x"}, {"source", ""}, {"candidate", false}, {"ok", true}})})}, {"picked", nullptr}});
    ReviewOutcome done = review_commit(dir, "sheet-0001", manifest, sheet, {ReviewThumb{1, sheet}});
    REQUIRE_MESSAGE(done.ok, done.message);
    review_abandon(dir, "sheet-0001");  // a finished sheet is never removed by this
    CHECK(stdfs::exists(root / ".factoria" / "review" / "sheet-0001" / "manifest.json"));
    ReviewOutcome loaded = review_load(dir, "latest");
    REQUIRE(loaded.ok);
    CHECK(loaded.value["label"] == "café");
    CHECK(loaded.value["engineVersion"].is_string());
}
