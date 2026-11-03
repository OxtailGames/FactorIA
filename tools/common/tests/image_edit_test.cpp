// The image.* editing commands (docs/IMAGES.md, "Commands"): create, info, export, the layer commands and their addressing errors,
// selections (by colour, shape, layer; grow, shrink, feather, combine), image.edit, image.paint (determinism) and the layered
// import of a PSD.
#include <doctest.h>

#include <cmath>
#include <filesystem>

#include "asset_test_helpers.h"
#include "fa/tooling/image_doc.h"

using namespace fa;
using namespace fa::testing;

namespace {

Json create_args(const std::string& path, int w, int h, Json layers = Json::array(), Json extra = Json::object()) {
    Json j = {{"path", path}, {"width", w}, {"height", h}, {"layers", std::move(layers)}};
    for (auto& [k, v] : extra.items()) j[k] = v;
    return j;
}

Json fill_layer(const std::string& name, const std::string& color, int x = 0, int y = 0, int w = 0, int h = 0) {
    Json j = {{"kind", "fill"}, {"name", name}, {"color", color}};
    if (w) j["width"] = w;
    if (h) j["height"] = h;
    if (x) j["x"] = x;
    if (y) j["y"] = y;
    return j;
}

Image baked(const AssetsProject& p, const std::string& png) { return read_png(p.file(png)); }

Json read_doc(const AssetsProject& p, const std::string& rel) { return parse_json(read_all(p.file(rel)), rel).value(); }

bool near_rgb(Rgba c, Rgba want, int tol = 2) {
    return std::abs(int(c.r) - want.r) <= tol && std::abs(int(c.g) - want.g) <= tol && std::abs(int(c.b) - want.b) <= tol;
}

std::string art(AssetsProject& p, const std::string& name, const std::string& bytes) {
    const auto path = p.tmp.path / "src" / name;
    write_all(path, bytes);
    return path.string();
}

std::string error_of(const CommandResult& r) { return r.error["message"].get<std::string>() + " " + r.error.value("hint", std::string()); }

constexpr const char* kDoc = "assets/art/t.image.json";
constexpr const char* kPng = "assets/art/t.png";

// A 16x16 document: a blue background and a 6x6 red box at (4,4).
void make_scene(const AssetsProject& p) {
    p.ok("image.create", create_args(kDoc, 16, 16, Json::array({fill_layer("bg", "#0000ff")})));
    p.ok("image.layer.add", {{"path", kDoc}, {"layer", {{"kind", "fill"}, {"name", "box"}, {"color", "#ff0000"}, {"x", 4}, {"y", 4}, {"width", 6}, {"height", 6}}}});
}

}  // namespace

TEST_CASE("image.create, image.info and image.export") {
    AssetsProject p;
    const Json r = p.ok("image.create", create_args(kDoc, 8, 8, Json::array({fill_layer("bg", "#00ff00")}), {{"description", "test"}}));
    CHECK(r["width"] == 8);
    CHECK(r.contains("$image"));
    CHECK(r["region"]["width"] == 8);
    CHECK(get(baked(p, kPng), 3, 3) == Rgba{0, 255, 0, 255});

    CommandResult again = p.call("image.create", create_args(kDoc, 8, 8));
    CHECK_FALSE(again.ok);
    CHECK(error_of(again).find("overwrite") != std::string::npos);
    CHECK_FALSE(p.call("image.create", create_args("assets/art/big.image.json", 5000, 8)).ok);
    CHECK_FALSE(p.call("image.create", create_args("assets/art/notdoc.json", 8, 8)).ok);

    const Json info = p.ok("image.info", {{"path", kDoc}});
    CHECK(info["width"] == 8);
    CHECK(info["layers"].size() == 1);
    CHECK(info["layers"][0]["name"] == "bg");
    CHECK(info["layers"][0]["index"] == "0");
    CHECK(info["bake"]["state"] == "fresh");

    const Json ex = p.ok("image.export", {{"path", kDoc}, {"out", "assets/art/big.png"}, {"scale", 4}});
    CHECK(ex["width"] == 32);
    CHECK(baked(p, "assets/art/big.png").width == 32);
    CHECK_FALSE(p.call("image.export", {{"path", kDoc}, {"out", "assets/art/big.png"}}).ok);  // exists
    CHECK_FALSE(p.call("image.info", {{"path", "assets/art/missing.image.json"}}).ok);
}

TEST_CASE("image.layer.*: add, set, move, remove and addressing by name or index path") {
    AssetsProject p;
    make_scene(p);
    p.ok("image.layer.add", {{"path", kDoc}, {"layer", {{"kind", "group"}, {"name", "grp"}, {"layers", Json::array({fill_layer("inner", "#ffff00", 0, 0, 2, 2)})}}}});

    Json info = p.ok("image.info", {{"path", kDoc}});
    CHECK(info["layers"].size() == 3);
    CHECK(info["layers"][2]["name"] == "grp");
    CHECK(info["layers"][2]["children"][0]["index"] == "2/0");

    // by name and by index path
    p.ok("image.layer.set", {{"path", kDoc}, {"layer", "box"}, {"set", {{"opacity", 0.5}}}});
    CHECK(read_doc(p, kDoc)["layers"][1]["opacity"] == 0.5);
    p.ok("image.layer.set", {{"path", kDoc}, {"layer", "2/0"}, {"set", {{"visible", false}}}});
    CHECK(read_doc(p, kDoc)["layers"][2]["layers"][0]["visible"] == false);
    CHECK(near_rgb(get(baked(p, kPng), 5, 5), {128, 0, 128}));  // 50% red over blue

    // errors teach
    CommandResult typo = p.call("image.layer.set", {{"path", kDoc}, {"layer", "bx"}, {"set", {{"opacity", 1}}}});
    REQUIRE_FALSE(typo.ok);
    CHECK(error_of(typo).find("box") != std::string::npos);
    CommandResult badIndex = p.call("image.layer.remove", {{"path", kDoc}, {"layer", "7"}});
    REQUIRE_FALSE(badIndex.ok);
    CHECK(error_of(badIndex).find("bg") != std::string::npos);
    CommandResult badSet = p.call("image.layer.set", {{"path", kDoc}, {"layer", "box"}, {"set", {{"blend", "multiplyy"}}}});
    REQUIRE_FALSE(badSet.ok);
    CHECK(error_of(badSet).find("multiply") != std::string::npos);
    CHECK(read_doc(p, kDoc)["layers"][1].contains("blend") == false);  // nothing written on error

    // move: into the group, then back to the bottom of the document
    p.ok("image.layer.move", {{"path", kDoc}, {"layer", "box"}, {"parent", "grp"}});
    info = p.ok("image.info", {{"path", kDoc}});
    CHECK(info["layers"].size() == 2);
    CHECK(info["layers"][1]["children"].size() == 2);
    p.ok("image.layer.move", {{"path", kDoc}, {"layer", "1/1"}, {"parent", ""}, {"index", 0}});
    CHECK(read_doc(p, kDoc)["layers"][0]["name"] == "box");

    p.ok("image.layer.remove", {{"path", kDoc}, {"layer", "box"}});
    CHECK(read_doc(p, kDoc)["layers"].size() == 2);
    CHECK_FALSE(p.call("image.layer.remove", {{"path", kDoc}, {"layer", "box"}}).ok);
}

TEST_CASE("image.select: colour, shapes, shaping, combining and persistence") {
    AssetsProject p;
    make_scene(p);
    Json r = p.ok("image.select", {{"path", kDoc}, {"name", "red"}, {"by", "color"}, {"at", {5, 5}}, {"contiguous", true}, {"tolerance", 10}});
    CHECK(r["selected"] == 36);
    CHECK(r["region"]["x"] == 4);
    CHECK(r["region"]["width"] == 6);
    CHECK(r.contains("$image"));
    CHECK(p.exists(".factoria/selections/assets/art/t.image.json/red.png"));

    // it persists: a later call reshapes the stored selection
    r = p.ok("image.select", {{"path", kDoc}, {"name", "red"}, {"then", Json::array({{{"grow", 1}}})}});
    CHECK(r["selected"].get<int>() > 36);
    CHECK(r["selected"].get<int>() <= 64);
    r = p.ok("image.select", {{"path", kDoc}, {"name", "red"}, {"then", Json::array({{{"shrink", 2}}})}});
    CHECK(r["selected"].get<int>() < 36);
    CHECK(r["selected"].get<int>() > 0);

    p.ok("image.select", {{"path", kDoc}, {"name", "r"}, {"by", "rect"}, {"x", 0}, {"y", 0}, {"width", 8}, {"height", 8}});
    r = p.ok("image.select", {{"path", kDoc}, {"name", "r"}, {"mode", "subtract"}, {"by", "ellipse"}, {"x", 0}, {"y", 0}, {"width", 8}, {"height", 8}});
    CHECK(r["selected"].get<int>() > 0);
    CHECK(r["selected"].get<int>() < 64);
    r = p.ok("image.select", {{"path", kDoc}, {"name", "poly"}, {"by", "polygon"}, {"points", {{0, 0}, {8, 0}, {0, 8}}}});
    CHECK(r["selected"].get<int>() > 20);
    CHECK(r["selected"].get<int>() < 44);
    r = p.ok("image.select", {{"path", kDoc}, {"name", "poly"}, {"then", Json::array({{{"invert", true}}})}});
    CHECK(r["selected"].get<int>() > 200);
    r = p.ok("image.select", {{"path", kDoc}, {"name", "layer"}, {"by", "layer"}, {"layer", "box"}});
    CHECK(r["selected"] == 36);
    r = p.ok("image.select", {{"path", kDoc}, {"name", "f"}, {"by", "rect"}, {"x", 2}, {"y", 2}, {"width", 8}, {"height", 8}, {"then", Json::array({{{"feather", 2}}})}});
    CHECK(r["selected"].get<int>() > 0);

    // an unknown selection lists the stored ones
    CommandResult bad = p.call("image.edit", {{"path", kDoc}, {"selection", "rd"}, {"layer", "box"}, {"action", {{"type", "delete"}}}});
    REQUIRE_FALSE(bad.ok);
    CHECK(error_of(bad).find("red") != std::string::npos);
    p.ok("image.select", {{"path", kDoc}, {"name", "red"}, {"clear", true}});
    CHECK_FALSE(p.exists(".factoria/selections/assets/art/t.image.json/red.png"));
    CHECK_FALSE(p.call("image.select", {{"path", kDoc}, {"name", "bad name!"}, {"by", "all"}}).ok);
}

TEST_CASE("image.edit: fill, recolor, move, transform, delete, copy and cut") {
    AssetsProject p;
    make_scene(p);
    p.ok("image.select", {{"path", kDoc}, {"name", "box"}, {"by", "layer"}, {"layer", "box"}});

    // a fill layer is rasterized with a warning
    Json r = p.ok("image.edit", {{"path", kDoc}, {"selection", "box"}, {"layer", "box"}, {"action", {{"type", "recolor"}, {"hueShift", 120}}}});
    CHECK(has_warning(r, "pixels layer"));
    CHECK(r["region"]["x"] == 4);
    CHECK(r["region"]["width"] == 6);
    CHECK(get(baked(p, kPng), 5, 5) == Rgba{0, 255, 0, 255});
    CHECK(read_doc(p, kDoc)["layers"][1]["kind"] == "pixels");

    p.ok("image.edit", {{"path", kDoc}, {"selection", "box"}, {"layer", "box"}, {"action", {{"type", "recolor"}, {"from", "#00ff00"}, {"to", "#ffff00"}}}});
    CHECK(get(baked(p, kPng), 5, 5) == Rgba{255, 255, 0, 255});

    p.ok("image.edit", {{"path", kDoc}, {"selection", "box"}, {"layer", "box"}, {"action", {{"type", "fill"}, {"color", "#000000"}, {"opacity", 0.5}}}});
    CHECK(near_rgb(get(baked(p, kPng), 5, 5), {128, 128, 0}));

    // move 4 right: the selection moves along
    p.ok("image.edit", {{"path", kDoc}, {"selection", "box"}, {"layer", "box"}, {"action", {{"type", "move"}, {"dx", 4}, {"dy", 0}}}});
    CHECK(get(baked(p, kPng), 5, 5) == Rgba{0, 0, 255, 255});
    CHECK(get(baked(p, kPng), 12, 5).a == 255);
    CHECK(get(baked(p, kPng), 12, 5) != Rgba{0, 0, 255, 255});
    r = p.ok("image.select", {{"path", kDoc}, {"name", "box"}, {"then", Json::array({{{"invert", true}}, {{"invert", true}}})}});
    CHECK(r["region"]["x"] == 8);

    // transform: half size, nearest, around the middle of the pixels
    r = p.ok("image.edit", {{"path", kDoc}, {"selection", "box"}, {"layer", "box"}, {"action", {{"type", "transform"}, {"scale", 0.5}, {"filter", "nearest"}}}});
    CHECK(r["filter"] == "nearest");
    CHECK(get(baked(p, kPng), 11, 7).a == 255);
    CHECK(get(baked(p, kPng), 8, 5) == Rgba{0, 0, 255, 255});
    CHECK_FALSE(p.call("image.edit", {{"path", kDoc}, {"selection", "box"}, {"layer", "box"}, {"action", {{"type", "transform"}}}}).ok);

    // copy to a new layer, cut to another, then delete both
    p.ok("image.select", {{"path", kDoc}, {"name", "all2"}, {"by", "layer"}, {"layer", "box"}});
    r = p.ok("image.edit", {{"path", kDoc}, {"selection", "all2"}, {"layer", "box"}, {"action", {{"type", "copy"}}}, {"name", "dup"}});
    CHECK(r["newLayer"]["name"] == "dup");
    CHECK(read_doc(p, kDoc)["layers"].size() == 3);
    p.ok("image.edit", {{"path", kDoc}, {"selection", "all2"}, {"layer", "box"}, {"action", {{"type", "cut"}}}, {"name", "cutout"}});
    CHECK(read_doc(p, kDoc)["layers"].size() == 4);
    p.ok("image.edit", {{"path", kDoc}, {"selection", "all2"}, {"layer", "dup"}, {"action", {{"type", "delete"}}}});
    p.ok("image.edit", {{"path", kDoc}, {"selection", "all2"}, {"layer", "cutout"}, {"action", {{"type", "delete"}}}});
    CHECK(get(baked(p, kPng), 11, 7) == Rgba{0, 0, 255, 255});

    CommandResult badType = p.call("image.edit", {{"path", kDoc}, {"selection", "all2"}, {"layer", "box"}, {"action", {{"type", "fil"}}}});
    REQUIRE_FALSE(badType.ok);
    CHECK(error_of(badType).find("fill") != std::string::npos);
    CommandResult badLayer = p.call("image.edit", {{"path", kDoc}, {"selection", "all2"}, {"layer", "bxo"}, {"action", {{"type", "delete"}}}});
    REQUIRE_FALSE(badLayer.ok);
    CHECK(error_of(badLayer).find("box") != std::string::npos);
}

TEST_CASE("image.edit: transform flips and rotates pixels exactly") {
    AssetsProject p;
    p.ok("image.create", create_args(kDoc, 8, 8));
    // a 2x1 sprite: red then green, two 1px dabs
    p.ok("image.paint", {{"path", kDoc}, {"layer", "px"}, {"create", true},
                         {"strokes", Json::array({{{"points", {{2.5, 2.5}}}, {"size", 1}, {"color", "#ff0000"}}, {{"points", {{3.5, 2.5}}}, {"size", 1}, {"color", "#00ff00"}}})}});
    Image img = baked(p, kPng);
    REQUIRE(get(img, 2, 2) == Rgba{255, 0, 0, 255});
    REQUIRE(get(img, 3, 2) == Rgba{0, 255, 0, 255});
    p.ok("image.select", {{"path", kDoc}, {"name", "s"}, {"by", "rect"}, {"x", 2}, {"y", 2}, {"width", 2}, {"height", 1}});
    p.ok("image.edit", {{"path", kDoc}, {"selection", "s"}, {"layer", "px"}, {"action", {{"type", "transform"}, {"flipH", true}, {"filter", "nearest"}}}});
    img = baked(p, kPng);
    CHECK(get(img, 2, 2) == Rgba{0, 255, 0, 255});
    CHECK(get(img, 3, 2) == Rgba{255, 0, 0, 255});
    // rotate 90 degrees clockwise: the row becomes a column (the left pixel goes to the top)
    p.ok("image.edit", {{"path", kDoc}, {"selection", "s"}, {"layer", "px"}, {"action", {{"type", "transform"}, {"rotate", 90}, {"filter", "nearest"}}}});
    img = baked(p, kPng);
    CHECK(get(img, 2, 2).a == 0);
    CHECK(get(img, 3, 1) == Rgba{0, 255, 0, 255});
    CHECK(get(img, 3, 2) == Rgba{255, 0, 0, 255});
}

TEST_CASE("image.paint: deterministic strokes, erase, create and selections") {
    auto paint = [](AssetsProject& p) {
        p.ok("image.create", create_args(kDoc, 32, 32, Json::array({fill_layer("bg", "#ffffff")})));
        return p.ok("image.paint", {{"path", kDoc}, {"layer", "ink"}, {"create", true},
                                    {"strokes", Json::array({{{"points", {{3, 3}, {28, 9}, {5, 27}}}, {"size", 5}, {"hardness", 0.5}, {"color", "#336699"}, {"opacity", 0.8}},
                                                            {{"points", {{16, 16}}}, {"size", 9}, {"color", "#ff0000"}}})}});
    };
    AssetsProject a, b;
    const Json r = paint(a);
    paint(b);
    CHECK(r["createdLayer"]["name"] == "ink");
    CHECK(r["changed"] == true);
    CHECK(r["region"]["width"].get<int>() > 20);
    CHECK(read_all(a.file(kPng)) == read_all(b.file(kPng)));  // same input, same bytes
    CHECK(get(baked(a, kPng), 16, 16) == Rgba{255, 0, 0, 255});
    CHECK(get(baked(a, kPng), 31, 31) == Rgba{255, 255, 255, 255});

    // erase through the middle; a selection limits painting
    a.ok("image.paint", {{"path", kDoc}, {"layer", "ink"}, {"strokes", Json::array({{{"points", {{16, 16}}}, {"size", 3}, {"erase", true}}})}});
    CHECK(get(baked(a, kPng), 16, 16) == Rgba{255, 255, 255, 255});
    a.ok("image.select", {{"path", kDoc}, {"name", "left"}, {"by", "rect"}, {"x", 0}, {"y", 0}, {"width", 8}, {"height", 32}});
    a.ok("image.paint", {{"path", kDoc}, {"layer", "ink"}, {"selection", "left"}, {"strokes", Json::array({{{"points", {{0, 20}, {31, 20}}}, {"size", 2}, {"color", "#00ff00"}}})}});
    CHECK(get(baked(a, kPng), 4, 20) == Rgba{0, 255, 0, 255});
    CHECK(get(baked(a, kPng), 20, 20) == Rgba{255, 255, 255, 255});

    CommandResult noCreate = a.call("image.paint", {{"path", kDoc}, {"layer", "inkk"}, {"strokes", Json::array({{{"points", {{1, 1}}}, {"color", "red"}}})}});
    REQUIRE_FALSE(noCreate.ok);
    CHECK(error_of(noCreate).find("ink") != std::string::npos);
    CHECK(error_of(noCreate).find("create") != std::string::npos);
    CHECK_FALSE(a.call("image.paint", {{"path", kDoc}, {"layer", "ink"}, {"strokes", Json::array({{{"points", {{1, 1}}}}})}}).ok);  // no colour
    CHECK_FALSE(a.call("image.paint", {{"path", kDoc}, {"layer", "ink"}, {"strokes", Json::array()}}).ok);
}

// ---- a Photoshop file with layers ------------------------------------------------------------------------------------

namespace {

struct Be {
    std::vector<std::uint8_t> v;
    Be& u8(unsigned x) { v.push_back(std::uint8_t(x)); return *this; }
    Be& u16(unsigned x) { return u8(x >> 8).u8(x & 255); }
    Be& u32(unsigned x) { return u16(x >> 16).u16(x & 0xffff); }
    Be& tag(const char* s) { for (int i = 0; i < 4; ++i) u8(static_cast<unsigned char>(s[i])); return *this; }
    Be& add(const Be& o) { v.insert(v.end(), o.v.begin(), o.v.end()); return *this; }
    Be& zeros(int n) { v.insert(v.end(), std::size_t(n), 0); return *this; }
};

struct PsdTestLayer {
    std::string name;
    int top = 0, left = 0, bottom = 0, right = 0;
    std::vector<std::uint8_t> r, g, b, a;  // one plane each, (right-left)*(bottom-top) samples; empty = none
    const char* blend = "norm";
    int opacity = 255;
    bool hidden = false, rle = false;
    int divider = 0;                       // lsct type
    std::vector<std::uint8_t> mask;        // a layer mask over the whole layer rect (empty = none)
    std::string unicodeName;               // luni
};

Be channel_data(const std::vector<std::uint8_t>& plane, int w, int h, bool rle) {
    Be d;
    if (!rle) {
        d.u16(0);
        d.v.insert(d.v.end(), plane.begin(), plane.end());
        return d;
    }
    d.u16(1);
    Be rows;
    for (int y = 0; y < h; ++y) {
        Be row;
        for (int x = 0; x < w;) {  // PackBits: a repeat when the next sample repeats, else a literal of one
            int run = 1;
            while (x + run < w && run < 128 && plane[std::size_t(y * w + x + run)] == plane[std::size_t(y * w + x)]) ++run;
            if (run > 1) row.u8(unsigned(257 - run)).u8(plane[std::size_t(y * w + x)]);
            else row.u8(0).u8(plane[std::size_t(y * w + x)]);
            x += run;
        }
        d.u16(unsigned(row.v.size()));
        rows.add(row);
    }
    return d.add(rows);
}

std::vector<std::uint8_t> make_psd(int w, int h, const std::vector<PsdTestLayer>& layers) {
    Be records, data;
    for (const PsdTestLayer& l : layers) {
        const int lw = l.right - l.left, lh = l.bottom - l.top;
        struct Ch {
            int id;
            Be bytes;
        };
        std::vector<Ch> chs;
        if (!l.r.empty()) {
            chs.push_back({-1, channel_data(l.a, lw, lh, l.rle)});
            chs.push_back({0, channel_data(l.r, lw, lh, l.rle)});
            chs.push_back({1, channel_data(l.g, lw, lh, l.rle)});
            chs.push_back({2, channel_data(l.b, lw, lh, l.rle)});
        } else {
            for (int id : {-1, 0, 1, 2}) chs.push_back({id, Be().u16(0)});
        }
        if (!l.mask.empty()) chs.push_back({-2, channel_data(l.mask, lw, lh, false)});
        records.u32(unsigned(l.top)).u32(unsigned(l.left)).u32(unsigned(l.bottom)).u32(unsigned(l.right)).u16(unsigned(chs.size()));
        for (const Ch& c : chs) records.u16(unsigned(c.id) & 0xffff).u32(unsigned(c.bytes.v.size()));
        records.tag("8BIM").tag(l.blend).u8(unsigned(l.opacity)).u8(0).u8(l.hidden ? 2 : 0).u8(0);
        Be extra;
        if (!l.mask.empty()) extra.u32(20).u32(unsigned(l.top)).u32(unsigned(l.left)).u32(unsigned(l.bottom)).u32(unsigned(l.right)).u8(0).u8(0).u16(0);
        else extra.u32(0);
        extra.u32(0);  // blending ranges
        extra.u8(unsigned(l.name.size()));
        for (char c : l.name) extra.u8(static_cast<unsigned char>(c));
        extra.zeros(int((4 - ((l.name.size() + 1) % 4)) % 4));
        if (!l.unicodeName.empty()) {
            Be block;
            block.u32(unsigned(l.unicodeName.size()));
            for (char c : l.unicodeName) block.u16(static_cast<unsigned char>(c));
            while (block.v.size() % 4) block.u8(0);
            extra.tag("8BIM").tag("luni").u32(unsigned(block.v.size())).add(block);
        }
        if (l.divider) extra.tag("8BIM").tag("lsct").u32(4).u32(unsigned(l.divider));
        records.u32(unsigned(extra.v.size())).add(extra);
        for (const Ch& c : chs) data.add(c.bytes);
    }
    Be info;
    info.u16(unsigned(layers.size())).add(records).add(data);
    if (info.v.size() % 2) info.u8(0);
    Be file;
    file.tag("8BPS").u16(1).zeros(6).u16(3).u32(unsigned(h)).u32(unsigned(w)).u16(8).u16(3).u32(0).u32(0);
    Be misc;
    misc.u32(unsigned(info.v.size())).add(info).u32(0);  // + empty global layer mask info
    file.u32(unsigned(misc.v.size())).add(misc);
    file.u16(0);  // merged image: raw planes (flat grey)
    file.v.insert(file.v.end(), std::size_t(w) * std::size_t(h) * 3, 50);
    return file.v;
}

std::vector<std::uint8_t> solid(int n, unsigned v) { return std::vector<std::uint8_t>(std::size_t(n), std::uint8_t(v)); }

}  // namespace

TEST_CASE("assets.import: a PSD with layers becomes an image document") {
    AssetsProject p;
    PsdTestLayer bg;
    bg.name = "Background";
    bg.bottom = bg.right = 4;
    bg.r = solid(16, 0);
    bg.g = solid(16, 0);
    bg.b = solid(16, 255);
    bg.a = solid(16, 255);
    PsdTestLayer divider;
    divider.name = "</Layer group>";
    divider.divider = 3;
    PsdTestLayer red;
    red.name = "red";
    red.top = red.left = 1;
    red.bottom = red.right = 3;
    red.r = solid(4, 255);
    red.g = solid(4, 0);
    red.b = solid(4, 0);
    red.a = solid(4, 255);
    red.blend = "mul ";
    red.opacity = 128;
    red.rle = true;
    PsdTestLayer masked;
    masked.name = "masked";
    masked.bottom = masked.right = 2;
    masked.r = solid(4, 0);
    masked.g = solid(4, 255);
    masked.b = solid(4, 0);
    masked.a = solid(4, 255);
    masked.mask = {255, 0, 255, 0};
    masked.hidden = true;
    PsdTestLayer folder;
    folder.name = "g";
    folder.divider = 1;
    folder.unicodeName = "Group 1";
    const auto bytes = make_psd(4, 4, {bg, divider, red, masked, folder});
    const std::string src = art(p, "layers.psd", std::string(bytes.begin(), bytes.end()));

    const Json r = p.ok("assets.import", {{"source", src}});
    CHECK(r["importer"] == "psd");
    CHECK(r["path"] == "assets/layers.png");
    CHECK(r["details"]["document"] == "assets/layers.image.json");
    CHECK_FALSE(has_warning(r, "flattened"));
    CHECK_FALSE(r["details"].contains("layersFlattened"));

    const Json doc = read_doc(p, "assets/layers.image.json");
    REQUIRE(doc["layers"].size() == 2);
    CHECK(doc["layers"][0]["name"] == "Background");
    CHECK(doc["layers"][0]["kind"] == "pixels");
    const Json& grp = doc["layers"][1];
    CHECK(grp["kind"] == "group");
    CHECK(grp["name"] == "Group 1");
    REQUIRE(grp["layers"].size() == 2);
    CHECK(grp["layers"][0]["name"] == "red");
    CHECK(grp["layers"][0]["blend"] == "multiply");
    CHECK(std::abs(grp["layers"][0]["opacity"].get<double>() - 128.0 / 255.0) < 0.001);
    CHECK(grp["layers"][0]["x"] == 1);
    CHECK(grp["layers"][1]["name"] == "masked");
    CHECK(grp["layers"][1]["visible"] == false);
    CHECK(p.exists("assets/layers.layers/red.png"));

    // the layer PNGs hold the pixels (the mask is baked into the alpha); the baked PNG is drawn from the layers
    CHECK(get(read_png(p.file("assets/layers.layers/red.png")), 0, 0) == Rgba{255, 0, 0, 255});
    const Image m = read_png(p.file("assets/layers.layers/masked.png"));
    CHECK(get(m, 0, 0).a == 255);
    CHECK(get(m, 1, 0).a == 0);
    const Image flat = read_png(p.file("assets/layers.png"));
    CHECK(flat.width == 4);
    CHECK(get(flat, 0, 0) == Rgba{0, 0, 255, 255});
    CHECK(get(flat, 1, 1).b < 255);  // the 50% multiply of red over blue darkens the blue
    const Json info = p.ok("image.info", {{"path", "assets/layers.image.json"}});
    CHECK(info["bake"]["state"] == "fresh");

    // a second import needs overwrite
    CHECK_FALSE(p.call("assets.import", {{"source", src}}).ok);
    CHECK(p.call("assets.import", {{"source", src}, {"overwrite", true}}).ok);

    // a damaged layer section falls back to the merged image, and the warning says why
    auto damaged = bytes;
    for (std::size_t i = 26; i + 4 < damaged.size(); ++i)
        if (std::string(damaged.begin() + std::ptrdiff_t(i), damaged.begin() + std::ptrdiff_t(i) + 4) == "8BIM") {
            damaged[i] = 'X';
            break;
        }
    const Json fb = p.ok("assets.import", {{"source", art(p, "damaged.psd", std::string(damaged.begin(), damaged.end()))}});
    CHECK(has_warning(fb, "flattened"));
    CHECK(fb["details"]["layersFlattened"] == true);
}
