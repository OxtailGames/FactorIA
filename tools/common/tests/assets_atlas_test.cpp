// assets.pack_atlas: a folder of frames becomes one PNG and a frame table that matches it, packing again keeps the frames in place.
// The frames are solid colours drawn here, so each expectation can be read off the code.
#include <doctest.h>

#include "asset_test_helpers.h"

using namespace fa;
using namespace fa::testing;

namespace {

const Rgba kRed{255, 0, 0, 255}, kGreen{0, 255, 0, 255}, kBlue{0, 0, 255, 255}, kYellow{255, 255, 0, 255}, kWhite{255, 255, 255, 255};

void frame(const AssetsProject& p, const std::string& name, int w, int h, Rgba c) { write_png(p.file("art/" + name + ".png"), make_image(w, h, c)); }

Json pack(const AssetsProject& p, Json extra = Json::object()) {
    Json args = {{"folder", "art"}, {"out", "assets/atlas.png"}, {"table", "data/atlas.json"}};
    args.update(extra);
    return p.ok("assets.pack_atlas", args);
}

Json table(const AssetsProject& p) { return parse_json(read_all(p.file("data/atlas.json")), "atlas.json").value(); }

std::array<int, 4> rect_of(const Json& t, const std::string& name) { return t["frames"][name]["rect"].get<std::array<int, 4>>(); }

// The frame's pixels, found where the table says, must be the picture that was in the folder (and its padding the edge repeated).
void check_frame(const AssetsProject& p, const Json& t, const std::string& name, Rgba c) {
    const Image atlas = read_png(p.file("assets/atlas.png"));
    const auto r = rect_of(t, name);
    for (int y = r[1] - 2; y < r[1] + r[3] + 2; ++y)
        for (int x = r[0] - 2; x < r[0] + r[2] + 2; ++x) CHECK_MESSAGE(get(atlas, x, y) == c, name << " at " << x << "," << y);
}

bool overlap(const std::array<int, 4>& a, const std::array<int, 4>& b, int pad) {
    return a[0] - pad < b[0] + b[2] + pad && b[0] - pad < a[0] + a[2] + pad && a[1] - pad < b[1] + b[3] + pad && b[1] - pad < a[1] + a[3] + pad;
}

}  // namespace

TEST_CASE("assets.pack_atlas: a folder of frames packs into one PNG whose table matches") {
    AssetsProject p;
    frame(p, "red", 30, 20, kRed);
    frame(p, "green", 16, 40, kGreen);
    frame(p, "ship/blue", 25, 25, kBlue);
    write_all(p.file("art/pivots.json"), R"({"red": [0.5, 0], "nothing": [1, 1]})");

    const Json r = pack(p);
    CHECK(r["frames"] == 3);
    CHECK(r["kept"] == 0);
    CHECK(r["added"].size() == 3);
    CHECK(r["written"] == true);
    CHECK(has_warning(r, "'nothing', which is not a frame"));
    const Json t = table(p);
    CHECK(t["texture"] == "assets/atlas.png");
    const Image atlas = read_png(p.file("assets/atlas.png"));
    CHECK(t["size"] == Json::array({atlas.width, atlas.height}));
    CHECK(atlas.width % 4 == 0);
    CHECK(atlas.height % 4 == 0);
    CHECK(t["frames"].size() == 3);
    CHECK(t["frames"]["red"]["pivot"] == Json::array({0.5, 0}));
    CHECK(t["frames"]["green"]["pivot"] == Json::array({0.5, 0.5}));
    CHECK(rect_of(t, "red")[2] == 30);
    CHECK(rect_of(t, "ship/blue")[3] == 25);
    check_frame(p, t, "red", kRed);
    check_frame(p, t, "green", kGreen);
    check_frame(p, t, "ship/blue", kBlue);
    const auto names = {"red", "green", "ship/blue"};
    for (const char* a : names)
        for (const char* b : names)
            if (std::string(a) != b) CHECK_FALSE(overlap(rect_of(t, a), rect_of(t, b), 2));

    // The same folder again changes nothing, byte for byte.
    const std::string pngBefore = read_all(p.file("assets/atlas.png")), tableBefore = read_all(p.file("data/atlas.json"));
    const Json again = pack(p);
    CHECK(again["written"] == false);
    CHECK(again["kept"] == 3);
    CHECK(read_all(p.file("assets/atlas.png")) == pngBefore);
    CHECK(read_all(p.file("data/atlas.json")) == tableBefore);
}

TEST_CASE("assets.pack_atlas: adding an image keeps the others in place") {
    AssetsProject p;
    const std::vector<std::pair<std::string, Rgba>> first = {{"a", kRed}, {"b", kGreen}, {"c", kBlue}};
    for (std::size_t i = 0; i < first.size(); ++i) frame(p, first[i].first, 40 + int(i) * 10, 50 - int(i) * 10, first[i].second);
    pack(p);
    const Json before = table(p);

    // A taller picture would be placed first by a fresh pack; here it must not move anything.
    frame(p, "d", 60, 90, kYellow);
    const Json r = pack(p);
    CHECK(r["kept"] == 3);
    CHECK(r["added"] == Json::array({"d"}));
    CHECK(r["moved"].empty());
    const Json after = table(p);
    for (const auto& f : first) {
        CHECK(rect_of(after, f.first) == rect_of(before, f.first));
        CHECK(after["frames"][f.first] == before["frames"][f.first]);
        check_frame(p, after, f.first, f.second);
    }
    check_frame(p, after, "d", kYellow);

    // So many that the page must grow: the old frames still do not move.
    for (int i = 0; i < 12; ++i) frame(p, "extra" + std::to_string(i), 70, 70, kWhite);
    const Json grown = pack(p);
    CHECK(grown["kept"] == 4);
    const Json big = table(p);
    CHECK(big["size"][0].get<int>() * big["size"][1].get<int>() > after["size"][0].get<int>() * after["size"][1].get<int>());
    for (const char* n : {"a", "b", "c", "d"}) CHECK(rect_of(big, n) == rect_of(after, n));
    check_frame(p, big, "extra11", kWhite);

    // A removed frame leaves its place to the next one; a frame of another size moves and is reported.
    std::filesystem::remove(p.file("art/b.png"));
    frame(p, "c", 20, 20, kBlue);
    const Json last = pack(p);
    CHECK(last["removed"] == Json::array({"b"}));
    CHECK(last["moved"] == Json::array({"c"}));
    const Json t = table(p);
    CHECK_FALSE(t["frames"].contains("b"));
    CHECK(rect_of(t, "a") == rect_of(before, "a"));
    check_frame(p, t, "c", kBlue);
}

TEST_CASE("assets.pack_atlas: keys of the table that are not the packer's stay, and a Sprite region reads the frame") {
    AssetsProject p;
    frame(p, "left", 8, 8, kRed);
    frame(p, "right", 8, 8, kGreen);
    write_all(p.file("data/atlas.json"), R"({"roadFrames": {"0": "left"}})");
    pack(p);
    const Json t = table(p);
    CHECK(t["roadFrames"]["0"] == "left");
    // The region [x, y, w, h] from the top-left is Sprite.region: the pixels under it are the frame, and only the frame.
    const Image atlas = read_png(p.file("assets/atlas.png"));
    const auto r = rect_of(t, "right");
    for (int y = r[1]; y < r[1] + r[3]; ++y)
        for (int x = r[0]; x < r[0] + r[2]; ++x) CHECK(get(atlas, x, y) == kGreen);
}

TEST_CASE("assets.pack_atlas: errors say what to change") {
    AssetsProject p;
    CHECK(p.call("assets.pack_atlas", {{"folder", "art"}, {"out", "assets/a.png"}}).error["message"].get<std::string>().find("does not exist") != std::string::npos);
    std::filesystem::create_directories(p.file("art"));
    CHECK(p.call("assets.pack_atlas", {{"folder", "art"}, {"out", "assets/a.png"}}).error["message"].get<std::string>().find("no images") != std::string::npos);
    frame(p, "big", 200, 200, kRed);
    CHECK(p.call("assets.pack_atlas", {{"folder", "art"}, {"out", "a.jpg"}}).ok == false);
    const CommandResult tooBig = p.call("assets.pack_atlas", {{"folder", "art"}, {"out", "assets/a.png"}, {"maxSize", 128}});
    REQUIRE_FALSE(tooBig.ok);
    CHECK(tooBig.error["hint"].get<std::string>().find("maxSize") != std::string::npos);
    frame(p, "s1", 100, 100, kRed);
    frame(p, "s2", 100, 100, kRed);
    frame(p, "s3", 100, 100, kRed);
    std::filesystem::remove(p.file("art/big.png"));
    const CommandResult full = p.call("assets.pack_atlas", {{"folder", "art"}, {"out", "assets/a.png"}, {"maxSize", 128}});
    REQUIRE_FALSE(full.ok);
    CHECK(full.error["message"].get<std::string>().find("do not fit") != std::string::npos);
    frame(p, "dup", 8, 8, kRed);
    write_png(p.file("art/dup.jpg.png"), make_image(8, 8, kRed));
    write_all(p.file("art/pivots.json"), R"({"dup": [1]})");
    CHECK(p.call("assets.pack_atlas", {{"folder", "art"}, {"out", "assets/a.png"}}).error["message"].get<std::string>().find("pivot") != std::string::npos);
}
