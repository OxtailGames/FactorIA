// Frames and tags of image documents (docs/IMAGES.md, "Frames and tags"): the format and its teaching errors, held and linked cels, the
// onion skin, tags -> SpriteAnimator clips of the baked sheet (reverse, ping-pong, repeat, durations), and the image.frame.* /
// image.tag.* commands with the `frame` argument of the editing commands.
#include <doctest.h>

#include <algorithm>
#include <cmath>

#include "asset_test_helpers.h"
#include "fa/tooling/image_doc.h"

using namespace fa;
using namespace fa::testing;

namespace {

constexpr const char* kDoc = "assets/art/a.image.json";
constexpr const char* kPng = "assets/art/a.png";

const Rgba kRed{255, 0, 0, 255}, kGreen{0, 255, 0, 255}, kBlue{0, 0, 255, 255}, kClear{0, 0, 0, 0};

std::string error_of(const CommandResult& r) { return r.error["message"].get<std::string>() + " " + r.error.value("hint", std::string()); }

Json read_doc(const AssetsProject& p) { return parse_json(read_all(p.file(kDoc)), kDoc).value(); }

// A 2x2 PNG of one colour, written under assets/art/.
void put_png(const AssetsProject& p, const std::string& name, Rgba c) {
    write_png(p.file("assets/art/" + name), make_image(2, 2, c));
}

// A 2x2 document with a pixels layer showing red, and (cels) green in frame 1, blue in frame 3; frame 2 holds green.
Json pixels_doc() {
    return Json::parse(R"({
      "width": 2, "height": 2,
      "frames": [{"duration": 100}, {"duration": 100}, {"duration": 100}, {"duration": 100}],
      "layers": [{"kind": "pixels", "name": "body", "source": "assets/art/red.png",
        "cels": [{"frame": 1, "source": "assets/art/green.png"}, {"frame": 3, "source": "assets/art/blue.png"}]}]})");
}

void put_pixels_pngs(const AssetsProject& p) {
    put_png(p, "red.png", kRed);
    put_png(p, "green.png", kGreen);
    put_png(p, "blue.png", kBlue);
}

Image frame_of(const ImageDocument& doc, const std::string& dir, int frame, std::optional<ImageOnionSkin> onion = std::nullopt) {
    ImageRenderOptions options;
    options.projectDir = dir;
    options.frame = frame;
    options.onion = onion;
    auto r = composite_image_document(doc, options);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().message));
    return r->image;
}

// 4x4 indexed documents: a one-pixel dot that moves right by one pixel per frame.
void make_dot(const AssetsProject& p, int frames = 3) {
    p.ok("image.create", {{"path", kDoc}, {"width", 4}, {"height", 4}, {"palette", Json::array({"#000000", "#ff0000"})}});
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "dot"}, {"create", true}, {"pixels", Json::array({Json::array({0, 0, 1})})}});
    p.ok("image.frame.add", {{"path", kDoc}, {"count", frames - 1}});
    for (int f = 1; f < frames; ++f) {
        p.ok("image.frame.cel", {{"path", kDoc}, {"layer", "dot"}, {"frame", f}, {"clear", true}});
        p.ok("image.pixel", {{"path", kDoc}, {"layer", "dot"}, {"frame", f}, {"pixels", Json::array({Json::array({f, 0, 1})})}});
    }
}

const Json* clip_named(const Json& sheet, const std::string& name) {
    if (!sheet.contains("clips")) return nullptr;
    for (const Json& c : sheet["clips"])
        if (c["name"] == name) return &c;
    return nullptr;
}

}  // namespace

TEST_CASE("frames: held cels, links and empty cels give what each frame shows") {
    AssetsProject p;
    put_pixels_pngs(p);
    Json j = pixels_doc();
    auto doc = parse_image_document(j, "a.image.json", p.dir);
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? "" : doc.error().message));
    CHECK(image_frame_count(*doc) == 4);
    CHECK(get(frame_of(*doc, p.dir, 0), 0, 0) == kRed);
    CHECK(get(frame_of(*doc, p.dir, 1), 1, 1) == kGreen);
    CHECK(get(frame_of(*doc, p.dir, 2), 0, 1) == kGreen);   // no cel of its own: holds frame 1
    CHECK(get(frame_of(*doc, p.dir, 3), 0, 0) == kBlue);

    // A link shows an earlier frame's picture again; an empty cel shows nothing.
    j["layers"][0]["cels"] = Json::parse(R"([{"frame": 1, "source": "assets/art/green.png"}, {"frame": 2, "link": 0}, {"frame": 3, "empty": true}])");
    auto linked = parse_image_document(j, "a.image.json", p.dir);
    REQUIRE_MESSAGE(linked.ok(), (linked.ok() ? "" : linked.error().message));
    CHECK(get(frame_of(*linked, p.dir, 2), 1, 1) == kRed);
    CHECK(get(frame_of(*linked, p.dir, 3), 1, 1) == kClear);

    // A layer without cels (a fill) is the same in every frame.
    j["layers"].push_back(Json::parse(R"({"kind": "fill", "color": "#0000ff", "width": 1, "height": 1, "x": 1, "y": 1})"));
    auto both = parse_image_document(j, "a.image.json", p.dir);
    REQUIRE(both.ok());
    for (int f = 0; f < 4; ++f) CHECK(get(frame_of(*both, p.dir, f), 1, 1) == kBlue);

    // A frame that does not exist is an error that says how many there are.
    ImageRenderOptions options;
    options.projectDir = p.dir;
    options.frame = 4;
    auto bad = composite_image_document(*both, options);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("4 frames") != std::string::npos);
}

TEST_CASE("frames: the format rejects what it cannot show, naming the JSON pointer and a fix") {
    AssetsProject p;
    put_pixels_pngs(p);
    auto issues = [&](const Json& j) {
        std::vector<ImageIssue> out;
        parse_image_document(j, "a.image.json", p.dir, &out);
        return out;
    };
    auto find = [](const std::vector<ImageIssue>& list, const std::string& pointer) -> const ImageIssue* {
        for (const ImageIssue& i : list)
            if (i.pointer == pointer) return &i;
        return nullptr;
    };

    Json tag = pixels_doc();
    tag["tags"] = Json::parse(R"([{"name": "walk", "from": 0, "to": 9, "direction": "pingpng"}])");
    auto a = issues(tag);
    const ImageIssue* range = find(a, "/tags/0/to");
    REQUIRE(range);
    CHECK(range->hint.find("0 to 3") != std::string::npos);
    const ImageIssue* dir = find(a, "/tags/0/direction");
    REQUIRE(dir);
    CHECK(dir->hint.find("pingpong") != std::string::npos);   // did you mean

    Json twice = pixels_doc();
    twice["tags"] = Json::parse(R"([{"name": "a", "from": 0, "to": 1}, {"name": "a", "from": 2, "to": 3}])");
    CHECK(find(issues(twice), "/tags/1/name"));

    Json cels = pixels_doc();
    cels["layers"][0]["cels"] = Json::parse(R"([{"frame": 2, "source": "assets/art/green.png"}, {"frame": 1, "source": "assets/art/blue.png"}, {"frame": 3, "link": 3}, {"frame": 9, "empty": true}])");
    auto b = issues(cels);
    const ImageIssue* order = find(b, "/layers/0/cels/1/frame");
    REQUIRE(order);
    CHECK(order->message.find("increasing") != std::string::npos);
    CHECK(find(b, "/layers/0/cels/2/link"));
    CHECK(find(b, "/layers/0/cels/3/frame"));

    Json still = pixels_doc();
    still.erase("frames");
    auto c = issues(still);
    const ImageIssue* nofr = find(c, "/layers/0/cels/0/frame");
    REQUIRE(nofr);
    CHECK(nofr->hint.find("image.frame.add") != std::string::npos);

    Json mixed = pixels_doc();
    mixed["layers"][0]["cels"][0]["empty"] = true;
    CHECK(find(issues(mixed), "/layers/0/cels/0"));

    Json duration = pixels_doc();
    duration["frames"][1]["duration"] = 0;
    CHECK(find(issues(duration), "/frames/1/duration"));
}

TEST_CASE("frames: a document with one frame stays exactly as it was") {
    AssetsProject p;
    p.ok("image.create", {{"path", kDoc}, {"width", 4}, {"height", 4}, {"layers", Json::array({Json::parse(R"({"kind": "fill", "color": "#ff0000", "name": "bg"})")})}});
    const std::string bytes = read_all(p.file(kPng));
    const Json doc = read_doc(p);
    CHECK_FALSE(doc.contains("frames"));
    CHECK_FALSE(doc.contains("tags"));
    CHECK_FALSE(p.manifest()["assets"][kPng].contains("sheet"));
    const Image img = read_png(p.file(kPng));
    CHECK(img.width == 4);   // the canvas, not a sheet
    CHECK(get(img, 3, 3) == kRed);

    // frame 0 of a still document is the document: a `frame` argument 0 changes nothing.
    const Json r = p.ok("image.info", {{"path", kDoc}});
    CHECK_FALSE(r.contains("animation"));
    CHECK_FALSE(p.call("image.draw", {{"path", kDoc}, {"layer", "x"}, {"frame", 1}, {"create", true}, {"shapes", Json::array()}}).ok);
}

TEST_CASE("frames: tags become the clips of the baked sheet, and the sheet is stale-checked like any bake") {
    AssetsProject p;
    put_pixels_pngs(p);
    Json j = pixels_doc();
    j["frames"][2]["duration"] = 200;   // frames 0, 1, 3: 100 ms; frame 2: 200 ms
    j["tags"] = Json::parse(R"([
      {"name": "fwd", "from": 0, "to": 1},
      {"name": "back", "from": 0, "to": 2, "direction": "reverse"},
      {"name": "ping", "from": 0, "to": 3, "direction": "pingpong"},
      {"name": "once", "from": 0, "to": 1, "repeat": 1},
      {"name": "twice", "from": 0, "to": 1, "repeat": 2},
      {"name": "slow", "from": 1, "to": 2}])");
    j["sheet"] = {{"columns", 4}};
    write_all(p.file(kDoc), j.dump(2));
    const Json baked = p.ok("image.bake", {{"path", kDoc}});
    const Json& sheet = baked["sheet"];
    CHECK(sheet["frameWidth"] == 2);
    CHECK(sheet["frameHeight"] == 2);
    CHECK(sheet["columns"] == 4);
    CHECK(p.manifest()["assets"][kPng]["sheet"] == sheet);

    const Json* fwd = clip_named(sheet, "fwd");
    REQUIRE(fwd);
    CHECK((*fwd)["firstFrame"] == 0);
    CHECK((*fwd)["lastFrame"] == 1);
    CHECK((*fwd)["fps"] == 10);   // 100 ms a frame
    CHECK((*fwd)["loop"] == true);

    // Everything else is spelled out in extra cells after the four frames.
    const std::vector<std::string> extra = {"back", "ping", "twice", "slow"};
    int next = 4;
    std::vector<std::pair<int, int>> spans;
    for (const std::string& name : extra) {
        const Json* c = clip_named(sheet, name);
        REQUIRE_MESSAGE(c, name);
        CHECK_MESSAGE((*c)["firstFrame"].get<int>() >= next, name);
        next = (*c)["lastFrame"].get<int>() + 1;
        spans.push_back({(*c)["firstFrame"].get<int>(), (*c)["lastFrame"].get<int>()});
    }
    // back: frames 2, 1, 0 at 100 ms steps (frame 2 lasts 200 ms = two cells): 4 cells at 10 fps
    const Json& back = *clip_named(sheet, "back");
    CHECK(back["lastFrame"].get<int>() - back["firstFrame"].get<int>() + 1 == 4);
    CHECK(back["fps"] == 10);
    // ping: 0 1 2 2 3 2 2 1 (a looping ping-pong leaves out the turn-around frames at both ends)
    const Json& ping = *clip_named(sheet, "ping");
    CHECK(ping["lastFrame"].get<int>() - ping["firstFrame"].get<int>() + 1 == 8);
    CHECK(ping["loop"] == true);
    // once: plays once and stops; twice: two passes
    const Json& once = *clip_named(sheet, "once");
    CHECK(once["loop"] == false);
    CHECK(once["lastFrame"].get<int>() == 1);   // a forward, uniform tag that plays once needs no extra cells
    const Json& twice = *clip_named(sheet, "twice");
    CHECK(twice["lastFrame"].get<int>() - twice["firstFrame"].get<int>() + 1 == 4);
    CHECK(twice["loop"] == false);
    // slow: frames of different durations (100 and 200 ms): 3 cells of 100 ms
    const Json& slow = *clip_named(sheet, "slow");
    CHECK(slow["lastFrame"].get<int>() - slow["firstFrame"].get<int>() + 1 == 3);
    CHECK(slow["fps"] == 10);

    // The sheet picture: each cell is a frame, left to right, top to bottom.
    const Image img = read_png(p.file(kPng));
    const int cells = sheet["frames"].get<int>();
    CHECK(img.width == 4 * 2);
    CHECK(img.height == ((cells + 3) / 4) * 2);
    CHECK(get(img, 0, 0) == kRed);     // cell 0 = frame 0
    CHECK(get(img, 2, 0) == kGreen);   // cell 1 = frame 1
    CHECK(get(img, 4, 0) == kGreen);   // cell 2 = frame 2 (held)
    CHECK(get(img, 6, 0) == kBlue);    // cell 3 = frame 3
    // back starts on frame 2 (green)
    const int bc = back["firstFrame"].get<int>();
    CHECK(get(img, (bc % 4) * 2, (bc / 4) * 2) == kGreen);
    CHECK(get(img, ((bc + 3) % 4) * 2, ((bc + 3) / 4) * 2) == kRed);   // and ends on frame 0

    // Provenance and staleness: the recipe is image.bake; a changed cel makes the sheet stale.
    const Json entry = p.manifest()["assets"][kPng];
    CHECK(entry["provenance"]["recipe"]["command"] == "image.bake");
    CHECK(p.ok("image.info", {{"path", kDoc}})["bake"]["state"] == "fresh");
    put_png(p, "green.png", Rgba{1, 2, 3, 255});
    CHECK(p.ok("image.info", {{"path", kDoc}})["bake"]["state"] == "stale");
    const Json rebaked = p.ok("assets.regenerate", {{"path", kPng}});
    CHECK(rebaked.dump().find("error") == std::string::npos);
    CHECK(get(read_png(p.file(kPng)), 2, 0) == Rgba{1, 2, 3, 255});
}

TEST_CASE("frames: a sheet that would not fit a texture is an error that says how to fix it") {
    AssetsProject p;
    Json j = Json::parse(R"({"width": 4096, "height": 4096, "frames": [{}, {}, {}, {}, {}], "sheet": {"columns": 5},
      "layers": [{"kind": "fill", "color": "#ff0000"}]})");
    write_all(p.file(kDoc), j.dump(2));
    CommandResult r = p.call("image.bake", {{"path", kDoc}});
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("16384") != std::string::npos);
    CHECK(error_of(r).find("columns") != std::string::npos);
}

TEST_CASE("frames: the onion skin ghosts the neighbouring frames under the frame, and never reaches the bake") {
    AssetsProject p;
    make_dot(p, 3);
    auto doc = load_image_document(p.dir, kDoc);
    REQUIRE(doc.ok());
    // Frame 1 shows the dot at x = 1. Without onion skin the other pixels are clear.
    const Image plain = frame_of(*doc, p.dir, 1);
    CHECK(get(plain, 1, 0).a == 255);
    CHECK(get(plain, 0, 0).a == 0);
    CHECK(get(plain, 2, 0).a == 0);

    ImageOnionSkin onion;
    const Image ghosted = frame_of(*doc, p.dir, 1, onion);
    CHECK(get(ghosted, 1, 0) == get(plain, 1, 0));   // the frame itself is drawn over the ghosts
    const Rgba before = get(ghosted, 0, 0), after = get(ghosted, 2, 0);
    CHECK(before.a > 0);
    CHECK(before.a < 255);
    CHECK(before.r > before.b);   // the frame before is tinted red
    CHECK(after.a > 0);
    CHECK(after.b > after.r);     // the frame after is tinted blue
    CHECK(get(ghosted, 3, 0).a == 0);

    // Configurable: nothing before, two after, a different opacity.
    onion.before = 0;
    onion.after = 2;
    onion.opacity = 0.8f;
    const Image custom = frame_of(*doc, p.dir, 0, onion);
    CHECK(get(custom, 0, 0).a == 255);   // the frame
    CHECK(get(custom, 1, 0).a > 0);
    CHECK(get(custom, 2, 0).a > 0);
    CHECK(get(custom, 1, 0).a > get(custom, 2, 0).a);   // the second ghost is fainter
    // Loop: the frame before frame 0 is the last one.
    ImageOnionSkin wrap;
    wrap.after = 0;
    CHECK(get(frame_of(*doc, p.dir, 0, wrap), 2, 0).a == 0);
    wrap.loop = true;
    CHECK(get(frame_of(*doc, p.dir, 0, wrap), 2, 0).a > 0);

    // The bake does not draw it.
    const Image baked = read_png(p.file(kPng));
    CHECK(get(baked, 4 + 0, 0).a == 0);   // cell 1 is frame 1: the dot at x = 1 is in cell 1, x = 4 + 1
    CHECK(get(baked, 4 + 1, 0) == Rgba{255, 0, 0, 255});
}

TEST_CASE("image.frame.*: add, remove, move, set, cel and sheet change the frames of every layer and keep the tags in place") {
    AssetsProject p;
    make_dot(p, 3);   // frame f: the dot at x = f
    p.ok("image.tag.set", {{"path", kDoc}, {"name", "all"}, {"from", 0}, {"to", 2}});
    p.ok("image.tag.set", {{"path", kDoc}, {"name", "last"}, {"from", 2}, {"to", 2}});

    auto dot_at = [&](int frame) {
        auto doc = load_image_document(p.dir, kDoc);
        REQUIRE(doc.ok());
        const Image img = frame_of(*doc, p.dir, frame);
        for (int x = 0; x < 4; ++x)
            if (get(img, x, 0).a == 255) return x;
        return -1;
    };
    CHECK(dot_at(0) == 0);
    CHECK(dot_at(1) == 1);
    CHECK(dot_at(2) == 2);

    // add: a copy of frame 1 after it; tags after it move along, a tag that contains it grows.
    Json r = p.ok("image.frame.add", {{"path", kDoc}, {"at", 2}, {"from", 1}});
    CHECK(r["animation"]["frameCount"] == 4);
    CHECK(dot_at(2) == 1);
    CHECK(dot_at(3) == 2);
    Json doc = read_doc(p);
    CHECK(doc["tags"][0]["to"] == 3);      // "all" contained the new frame
    CHECK(doc["tags"][1]["from"] == 3);    // "last" moved
    CHECK(doc["tags"][1]["to"] == 3);

    // blank frames, with a duration
    r = p.ok("image.frame.add", {{"path", kDoc}, {"blank", true}, {"duration", 250}});
    CHECK(r["animation"]["frameCount"] == 5);
    CHECK(dot_at(4) == -1);
    CHECK(r["animation"]["frames"][4]["duration"] == 250);

    // move frame 4 to the front, then back
    p.ok("image.frame.move", {{"path", kDoc}, {"frame", 4}, {"to", 0}});
    CHECK(dot_at(0) == -1);
    CHECK(dot_at(1) == 0);
    CHECK(dot_at(4) == 2);
    CHECK(read_doc(p)["frames"][0]["duration"] == 250);
    p.ok("image.frame.move", {{"path", kDoc}, {"frame", 0}, {"to", 4}});
    CHECK(dot_at(0) == 0);
    CHECK(dot_at(4) == -1);

    // remove: tags shrink and move down; a tag that was only that frame goes away with a warning
    r = p.ok("image.frame.remove", {{"path", kDoc}, {"frame", 4}});
    r = p.ok("image.frame.remove", {{"path", kDoc}, {"frame", 3}});
    CHECK(r["animation"]["frameCount"] == 3);
    CHECK(has_warning(r, "last"));
    CHECK(r["animation"]["tags"].size() == 1);
    CHECK(r["animation"]["tags"][0]["to"] == 2);
    CHECK(dot_at(2) == 1);

    // set: one frame, a range, all
    p.ok("image.frame.set", {{"path", kDoc}, {"frame", 1}, {"duration", 40}});
    p.ok("image.frame.set", {{"path", kDoc}, {"frame", Json::array({0, 2})}, {"duration", 60}});
    doc = read_doc(p);
    CHECK(doc["frames"][1]["duration"] == 60);
    r = p.ok("image.frame.set", {{"path", kDoc}, {"frame", "all"}, {"duration", 80}});
    for (const Json& f : r["animation"]["frames"]) CHECK(f["duration"] == 80);
    CHECK(r["sheet"]["frames"] == 3 + 0 * 1);   // uniform durations: a forward tag needs no extra cells

    // cel: frame 2 shows what frame 0 shows; clear shows nothing
    p.ok("image.frame.cel", {{"path", kDoc}, {"layer", "dot"}, {"frame", 2}, {"from", 0}});
    CHECK(dot_at(2) == 0);
    p.ok("image.frame.cel", {{"path", kDoc}, {"layer", "dot"}, {"frame", 1}, {"clear", true}});
    CHECK(dot_at(1) == -1);

    // sheet columns
    r = p.ok("image.frame.sheet", {{"path", kDoc}, {"columns", 3}});
    CHECK(r["sheet"]["columns"] == 3);
    CHECK(r["sheet"]["rows"] == 1);
    r = p.ok("image.frame.sheet", {{"path", kDoc}, {"columns", nullptr}});
    CHECK(r["sheet"]["columns"] == 2);

    // removing down to one frame with a tag keeps it animated; without tags it is a still again
    p.ok("image.tag.remove", {{"path", kDoc}, {"name", "all"}});
    p.ok("image.frame.remove", {{"path", kDoc}, {"frame", 2}});
    p.ok("image.frame.remove", {{"path", kDoc}, {"frame", 1}});
    doc = read_doc(p);
    CHECK_FALSE(doc.contains("frames"));
    CHECK_FALSE(doc.contains("tags"));
    CHECK_FALSE(p.manifest()["assets"][kPng].contains("sheet"));
    CHECK(read_png(p.file(kPng)).width == 4);
}

TEST_CASE("image.frame.*, image.tag.*: errors teach the range and the fix") {
    AssetsProject p;
    make_dot(p, 3);
    CommandResult r = p.call("image.frame.remove", {{"path", kDoc}, {"frame", 5}});
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("0") != std::string::npos);
    CHECK(error_of(r).find("2") != std::string::npos);
    r = p.call("image.frame.set", {{"path", kDoc}, {"frame", "most"}, {"duration", 10}});
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("all") != std::string::npos);
    r = p.call("image.frame.set", {{"path", kDoc}, {"frame", 0}, {"duration", 0}});
    REQUIRE_FALSE(r.ok);
    r = p.call("image.frame.cel", {{"path", kDoc}, {"layer", "dot"}, {"frame", 1}});
    REQUIRE_FALSE(r.ok);
    r = p.call("image.frame.cel", {{"path", kDoc}, {"layer", "dto"}, {"frame", 1}, {"clear", true}});
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("dot") != std::string::npos);   // did you mean
    r = p.call("image.tag.set", {{"path", kDoc}, {"name", "x"}, {"from", 2}, {"to", 1}});
    REQUIRE_FALSE(r.ok);
    r = p.call("image.tag.set", {{"path", kDoc}, {"name", "x"}, {"from", 0}, {"to", 1}, {"direction", "backwards"}});
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("reverse") != std::string::npos);
    r = p.call("image.tag.set", {{"path", kDoc}, {"name", "new"}});
    REQUIRE_FALSE(r.ok);   // a new tag needs its range
    r = p.call("image.tag.remove", {{"path", kDoc}, {"name", "nothing"}});
    REQUIRE_FALSE(r.ok);
    r = p.call("image.frame.add", {{"path", kDoc}, {"count", 2000}});
    REQUIRE_FALSE(r.ok);
    r = p.call("image.frame.sheet", {{"path", kDoc}, {"columns", 0}});
    REQUIRE_FALSE(r.ok);
    r = p.call("image.pixel", {{"path", kDoc}, {"layer", "dot"}, {"frame", 7}, {"pixels", Json::array({Json::array({0, 0, 1})})}});
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("3 frames") != std::string::npos);
    // nothing was written by the failed calls
    CHECK(read_doc(p)["frames"].size() == 3);
}

TEST_CASE("image.tag.set: changing a tag keeps what is not given, and the clip name plays by name") {
    AssetsProject p;
    make_dot(p, 4);
    Json r = p.ok("image.tag.set", {{"path", kDoc}, {"name", "walk"}, {"from", 0}, {"to", 3}, {"direction", "reverse"}});
    CHECK(r["tag"]["direction"] == "reverse");
    CHECK(r["replaced"] == false);
    r = p.ok("image.tag.set", {{"path", kDoc}, {"name", "walk"}, {"to", 2}});
    CHECK(r["replaced"] == true);
    CHECK(r["tag"]["from"] == 0);
    CHECK(r["tag"]["to"] == 2);
    CHECK(r["tag"]["direction"] == "reverse");   // kept
    CHECK(clip_named(r["sheet"], "walk"));
    CHECK(clip_named(p.manifest()["assets"][kPng]["sheet"], "walk"));
    r = p.ok("image.tag.remove", {{"path", kDoc}, {"name", "walk"}});
    CHECK_FALSE(clip_named(p.manifest()["assets"][kPng]["sheet"], "walk"));
    CHECK(read_doc(p)["frames"].size() == 4);
}

TEST_CASE("image.pixel, image.draw, image.edit, image.paint and image.export work on the frame they are given") {
    AssetsProject p;
    make_dot(p, 3);
    // image.pixel / image.draw: only frame 2 changes
    const Json before = read_doc(p);
    Json r = p.ok("image.pixel", {{"path", kDoc}, {"layer", "dot"}, {"frame", 2}, {"pixels", Json::array({Json::array({3, 3, 1})})}});
    CHECK(r["frame"] == 2);
    CHECK(r["frames"] == 3);
    CHECK(r.contains("$image"));
    auto doc = load_image_document(p.dir, kDoc);
    REQUIRE(doc.ok());
    CHECK(get(frame_of(*doc, p.dir, 2), 3, 3).a == 255);
    CHECK(get(frame_of(*doc, p.dir, 1), 3, 3).a == 0);
    CHECK(get(frame_of(*doc, p.dir, 0), 3, 3).a == 0);
    CHECK(get(frame_of(*doc, p.dir, 0), 0, 0).a == 255);
    CHECK(read_doc(p)["frames"] == before["frames"]);

    r = p.ok("image.draw", {{"path", kDoc}, {"layer", "dot"}, {"frame", 1}, {"shapes", Json::array({Json::parse(R"({"type": "rect", "x": 0, "y": 3, "width": 4, "height": 1, "fill": 1, "color": 1})")})}});
    doc = load_image_document(p.dir, kDoc);
    REQUIRE(doc.ok());
    CHECK(get(frame_of(*doc, p.dir, 1), 2, 3).a == 255);
    CHECK(get(frame_of(*doc, p.dir, 0), 2, 3).a == 0);
    CHECK(get(frame_of(*doc, p.dir, 2), 2, 3).a == 0);

    // The onion skin of the preview is a choice of the call; the baked sheet has none.
    r = p.ok("image.pixel", {{"path", kDoc}, {"layer", "dot"}, {"frame", 1}, {"onion", true}, {"pixels", Json::array({Json::array({3, 1, 1})})}});
    CHECK(r.contains("$image"));
    r = p.ok("image.pixel", {{"path", kDoc}, {"layer", "dot"}, {"frame", 1}, {"onion", {{"before", 2}, {"after", 0}, {"opacity", 0.5}}}, {"pixels", Json::array({Json::array({3, 2, 1})})}});
    CHECK(r.contains("$image"));
    CommandResult badOnion = p.call("image.pixel", {{"path", kDoc}, {"layer", "dot"}, {"frame", 1}, {"onion", {{"before", 20}}}, {"pixels", Json::array({Json::array({3, 2, 1})})}});
    REQUIRE_FALSE(badOnion.ok);
    CHECK(error_of(badOnion).find("8") != std::string::npos);

    // image.export writes the picture of one frame
    p.ok("image.export", {{"path", kDoc}, {"frame", 2}, {"out", "assets/art/f2.png"}});
    const Image f2 = read_png(p.file("assets/art/f2.png"));
    CHECK(f2.width == 4);
    CHECK(get(f2, 2, 0).a == 255);
    CHECK(get(f2, 3, 3).a == 255);
    CHECK(get(f2, 1, 0).a == 0);

    // image.info reports the animation
    r = p.ok("image.info", {{"path", kDoc}});
    CHECK(r["animation"]["frameCount"] == 3);
    CHECK(r["animation"]["frames"].size() == 3);
}

TEST_CASE("image.edit and image.paint on a frame of a pixels layer copy the cel (the other frames keep their file)") {
    AssetsProject p;
    put_pixels_pngs(p);
    Json j = pixels_doc();
    j["width"] = 2;
    write_all(p.file(kDoc), j.dump(2));
    p.ok("image.bake", {{"path", kDoc}});

    // paint a stroke in frame 0 only (the red cel)
    p.ok("image.paint", {{"path", kDoc}, {"layer", "body"}, {"frame", 0},
                         {"strokes", Json::array({Json::parse(R"({"points": [[1, 1]], "size": 8, "color": "#ffffff", "hardness": 1})")})}});
    auto doc = load_image_document(p.dir, kDoc);
    REQUIRE(doc.ok());
    CHECK(get(frame_of(*doc, p.dir, 0), 0, 0) == Rgba{255, 255, 255, 255});
    CHECK(get(frame_of(*doc, p.dir, 1), 0, 0) == kGreen);   // frame 1 and the held frame 2 keep their picture
    CHECK(get(frame_of(*doc, p.dir, 2), 0, 0) == kGreen);
    CHECK(get(frame_of(*doc, p.dir, 3), 0, 0) == kBlue);
    // the shared files are untouched: the green file was not edited
    CHECK(get(read_png(p.file("assets/art/green.png")), 0, 0) == kGreen);

    // editing frame 2 (which held frame 1's cel) makes it a cel of its own; frame 1 is unchanged
    p.ok("image.edit", {{"path", kDoc}, {"frame", 2}, {"layer", "body"}, {"selection", "all"}, {"action", {{"type", "recolor"}, {"from", "#00ff00"}, {"to", "#ffff00"}}}});
    doc = load_image_document(p.dir, kDoc);
    REQUIRE(doc.ok());
    const Rgba yellow = get(frame_of(*doc, p.dir, 2), 0, 0);
    CHECK(yellow.r > 200);
    CHECK(yellow.g > 200);
    CHECK(yellow.b < 50);
    CHECK(get(frame_of(*doc, p.dir, 1), 0, 0) == kGreen);
    CHECK(get(frame_of(*doc, p.dir, 3), 0, 0) == kBlue);
    // and the sheet follows
    CHECK(p.ok("image.info", {{"path", kDoc}})["bake"]["state"] == "fresh");
    const Image sheet = read_png(p.file(kPng));
    CHECK(get(sheet, 0, 0) == Rgba{255, 255, 255, 255});
    CHECK(get(sheet, 2, 0) == kGreen);
}

TEST_CASE("image.layer.convert refuses a layer with cels, and says to convert before animating") {
    AssetsProject p;
    make_dot(p, 2);
    CommandResult r = p.call("image.layer.convert", {{"path", kDoc}, {"layer", "dot"}, {"to", "pixels"}});
    REQUIRE_FALSE(r.ok);
    CHECK(error_of(r).find("different pictures") != std::string::npos);
    CHECK(error_of(r).find("/layer") != std::string::npos);
}

// ---- image.select with `frame`, orphan cel pictures, and new layers confined to one frame -----------------------------------------

namespace {

const Json kFullStroke = Json::parse(R"({"points": [[1, 1]], "size": 8, "color": "#ff0000", "hardness": 1})");

// A 4x4 document with a pixels layer "body" (a red square in frame 0; its file is assets/art/a.layers/body.png) and three frames.
void make_body(const AssetsProject& p, int frames = 3) {
    p.ok("image.create", {{"path", kDoc}, {"width", 4}, {"height", 4}});
    p.ok("image.paint", {{"path", kDoc}, {"layer", "body"}, {"create", true}, {"strokes", Json::array({kFullStroke})}});
    p.ok("image.frame.add", {{"path", kDoc}, {"count", frames - 1}});
}

bool exists(const AssetsProject& p, const std::string& rel) { return std::filesystem::exists(p.file(rel)); }

bool listed(const Json& files, const std::string& rel) {
    if (!files.is_array()) return false;
    return std::find(files.begin(), files.end(), Json(rel)) != files.end();
}

Rgba export_pixel(const AssetsProject& p, const std::string& layer, int frame) {
    p.ok("image.export", {{"path", kDoc}, {"out", "assets/art/out.png"}, {"layer", layer}, {"frame", frame}, {"overwrite", true}});
    return get(read_png(p.file("assets/art/out.png")), 1, 1);
}

}  // namespace

TEST_CASE("image.select takes a frame: color, alpha and layer selections read that frame's picture") {
    AssetsProject p;
    make_dot(p, 3);   // the dot is at (frame, 0)
    for (int f = 0; f < 3; ++f) {
        Json r = p.ok("image.select", {{"path", kDoc}, {"name", "dot"}, {"by", "alpha"}, {"frame", f}});
        CHECK(r["selected"] == 1);
        CHECK(r["region"]["x"] == f);
        CHECK(r["region"]["y"] == 0);
    }
    Json byLayer = p.ok("image.select", {{"path", kDoc}, {"name", "layerdot"}, {"by", "layer"}, {"layer", "dot"}, {"frame", 2}});
    CHECK(byLayer["region"]["x"] == 2);
    Json byColor = p.ok("image.select", {{"path", kDoc}, {"name", "red"}, {"by", "color"}, {"color", "#ff0000"}, {"tolerance", 0}, {"frame", 1}});
    CHECK(byColor["selected"] == 1);
    CHECK(byColor["region"]["x"] == 1);
    // without `frame` it is frame 0, as before; the stored selection is one per document and name, whatever the frame
    Json plain = p.ok("image.select", {{"path", kDoc}, {"name", "dot"}, {"by", "alpha"}});
    CHECK(plain["region"]["x"] == 0);
    CHECK(plain["selections"].size() == 3);
    // a frame that does not exist teaches
    CommandResult bad = p.call("image.select", {{"path", kDoc}, {"by", "alpha"}, {"frame", 7}});
    REQUIRE_FALSE(bad.ok);
    CHECK(error_of(bad).find("/frame") != std::string::npos);
    CHECK(error_of(bad).find("0 to 2") != std::string::npos);
    // the selection is usable on any frame: edit frame 2 inside the selection made on frame 2
    p.ok("image.select", {{"path", kDoc}, {"name", "here"}, {"by", "alpha"}, {"frame", 2}});
    CHECK(p.ok("image.select", {{"path", kDoc}, {"name", "here"}, {"then", Json::array({Json{{"grow", 1}}})}})["selected"].get<int>() > 1);
}

TEST_CASE("image.select with a frame on a pixels layer leaves no file behind") {
    AssetsProject p;
    make_body(p);
    p.ok("image.paint", {{"path", kDoc}, {"layer", "body"}, {"frame", 2}, {"strokes", Json::array({Json::parse(R"({"points": [[1, 1]], "size": 2, "color": "#00ff00", "hardness": 1})")})}});
    const std::string before = read_all(p.file(kDoc));
    p.ok("image.select", {{"path", kDoc}, {"by", "layer"}, {"layer", "body"}, {"frame", 2}});
    p.ok("image.select", {{"path", kDoc}, {"by", "color"}, {"color", "#00ff00"}, {"layer", "body"}, {"frame", 2}, {"tolerance", 0}});
    CHECK(read_all(p.file(kDoc)) == before);   // a selection never edits the document
    int pngs = 0;
    for (const auto& e : std::filesystem::directory_iterator(p.file("assets/art/a.layers"))) pngs += e.path().extension() == ".png" ? 1 : 0;
    CHECK(pngs == 2);   // body.png and the cel painted in frame 2; the selection's projections were removed
}

TEST_CASE("orphan cel pictures are deleted in the same save, and the result names them") {
    AssetsProject p;
    make_body(p);
    CHECK(exists(p, "assets/art/a.layers/body.png"));
    // frames 1 and 2 get cels of their own
    p.ok("image.paint", {{"path", kDoc}, {"layer", "body"}, {"frame", 1}, {"strokes", Json::array({Json::parse(R"({"points": [[1, 1]], "size": 8, "color": "#00ff00", "hardness": 1})")})}});
    p.ok("image.paint", {{"path", kDoc}, {"layer", "body"}, {"frame", 2}, {"strokes", Json::array({Json::parse(R"({"points": [[1, 1]], "size": 8, "color": "#0000ff", "hardness": 1})")})}});
    const Json doc = read_doc(p);
    const std::string cel1 = doc["layers"][0]["cels"][0]["source"], cel2 = doc["layers"][0]["cels"][1]["source"];
    REQUIRE(exists(p, cel1));
    REQUIRE(exists(p, cel2));

    // a cel replaced: painting frame 1 again makes a new file and the old one goes
    Json r = p.ok("image.paint", {{"path", kDoc}, {"layer", "body"}, {"frame", 1}, {"strokes", Json::array({Json::parse(R"({"points": [[1, 1]], "size": 8, "color": "#ffff00", "hardness": 1})")})}});
    REQUIRE(r.contains("removedFiles"));
    CHECK(listed(r["removedFiles"], cel1));
    CHECK_FALSE(exists(p, cel1));
    CHECK(exists(p, cel2));
    const Json doc2 = read_doc(p);
    REQUIRE(doc2["layers"][0]["cels"][0]["frame"] == 1);
    const std::string newCel1 = doc2["layers"][0]["cels"][0]["source"];
    CHECK(newCel1 != cel1);
    CHECK(exists(p, newCel1));
    CHECK(p.manifest()["assets"].contains(cel1) == false);
    CHECK(p.manifest()["assets"].contains(newCel1));
    CHECK(p.ok("image.info", {{"path", kDoc}})["bake"]["state"] == "fresh");

    // image.frame.cel clear: the frame shows nothing, its picture goes
    r = p.ok("image.frame.cel", {{"path", kDoc}, {"layer", "body"}, {"frame", 1}, {"clear", true}});
    CHECK(listed(r["removedFiles"], newCel1));
    CHECK_FALSE(exists(p, newCel1));

    // image.frame.remove: the removed frame's picture goes, the others stay
    r = p.ok("image.frame.remove", {{"path", kDoc}, {"frame", 2}});
    CHECK(listed(r["removedFiles"], cel2));
    CHECK_FALSE(exists(p, cel2));
    CHECK(exists(p, "assets/art/a.layers/body.png"));
    // nothing to delete: no `removedFiles`
    CHECK_FALSE(p.ok("image.frame.set", {{"path", kDoc}, {"frame", 0}, {"duration", 90}}).contains("removedFiles"));
}

TEST_CASE("orphan cel pictures: a file another document or the document itself still reads stays") {
    AssetsProject p;
    make_body(p);
    p.ok("image.paint", {{"path", kDoc}, {"layer", "body"}, {"frame", 1}, {"strokes", Json::array({Json::parse(R"({"points": [[1, 1]], "size": 8, "color": "#00ff00", "hardness": 1})")})}});
    const std::string cel1 = read_doc(p)["layers"][0]["cels"][0]["source"];
    // another document draws that picture
    write_all(p.file("assets/art/other.image.json"),
              Json{{"width", 4}, {"height", 4}, {"layers", Json::array({Json{{"kind", "pixels"}, {"source", cel1}}})}}.dump(2));
    // a user file that is not in the layers folder, used as a cel
    put_png(p, "mine.png", kBlue);
    Json doc = read_doc(p);
    doc["layers"][0]["cels"].push_back(Json{{"frame", 2}, {"source", "assets/art/mine.png"}});
    write_all(p.file(kDoc), doc.dump(2));

    Json r = p.ok("image.frame.cel", {{"path", kDoc}, {"layer", "body"}, {"frame", 1}, {"clear", true}});
    CHECK_FALSE(r.contains("removedFiles"));
    CHECK(exists(p, cel1));
    r = p.ok("image.frame.remove", {{"path", kDoc}, {"frame", 2}});
    CHECK_FALSE(r.contains("removedFiles"));
    CHECK(exists(p, "assets/art/mine.png"));
    // the same picture used twice in the document (a link) stays while one frame shows it
    doc = read_doc(p);
    CHECK(doc["layers"][0].contains("source"));
    CHECK(exists(p, doc["layers"][0]["source"]));
}

TEST_CASE("a still image document never loses a layer picture") {
    AssetsProject p;
    p.ok("image.create", {{"path", kDoc}, {"width", 4}, {"height", 4}});
    p.ok("image.paint", {{"path", kDoc}, {"layer", "body"}, {"create", true}, {"strokes", Json::array({kFullStroke})}});
    p.ok("image.layer.remove", {{"path", kDoc}, {"layer", "body"}});
    CHECK(exists(p, "assets/art/a.layers/body.png"));
}

TEST_CASE("image.edit copy and cut and create: true make a layer that shows in the given frame only") {
    AssetsProject p;
    make_body(p);
    // copy in frame 1: the new layer has the picture in frame 1 and nothing in frames 0 and 2
    Json r = p.ok("image.edit", {{"path", kDoc}, {"layer", "body"}, {"frame", 1}, {"selection", "all"}, {"action", {{"type", "copy"}}}, {"name", "dup"}});
    CHECK(r["newLayer"]["name"] == "dup");
    CHECK(export_pixel(p, "dup", 1) == kRed);
    CHECK(export_pixel(p, "dup", 0).a == 0);
    CHECK(export_pixel(p, "dup", 2).a == 0);
    const Json doc = read_doc(p);
    CHECK(doc["layers"][1]["name"] == "dup");
    CHECK(doc["layers"][1]["cels"][0]["frame"] == 1);
    CHECK_FALSE(doc["layers"][1].contains("source"));   // empty in frame 0

    // cut in frame 2: frame 2's body is gone, the cut layer shows only there
    p.ok("image.edit", {{"path", kDoc}, {"layer", "body"}, {"frame", 2}, {"selection", "all"}, {"action", {{"type", "cut"}}}, {"name", "piece"}});
    CHECK(export_pixel(p, "piece", 2) == kRed);
    CHECK(export_pixel(p, "piece", 1).a == 0);
    CHECK(export_pixel(p, "body", 2).a == 0);
    CHECK(export_pixel(p, "body", 1) == kRed);

    // create: true with a frame: painted there, empty elsewhere
    p.ok("image.paint", {{"path", kDoc}, {"layer", "fx"}, {"create", true}, {"frame", 1}, {"strokes", Json::array({kFullStroke})}});
    CHECK(export_pixel(p, "fx", 1) == kRed);
    CHECK(export_pixel(p, "fx", 0).a == 0);
    CHECK(export_pixel(p, "fx", 2).a == 0);
    // an indexed layer (image.pixel needs a palette in the document)
    Json withPalette = read_doc(p);
    withPalette["palette"] = Json::array({"#000000", "#ff0000"});
    write_all(p.file(kDoc), withPalette.dump(2));
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "marks"}, {"create", true}, {"frame", 2}, {"pixels", Json::array({Json::array({1, 1, 1})})}});
    const Json marks = read_doc(p)["layers"].back();
    CHECK(marks["kind"] == "indexed");
    CHECK_FALSE(marks.contains("rows"));   // empty in frame 0
    REQUIRE(marks.contains("cels"));
    CHECK(marks["cels"].size() == 1);
    CHECK(marks["cels"][0]["frame"] == 2);
}

TEST_CASE("image.edit copy without a frame keeps showing the new layer in every frame") {
    AssetsProject p;
    make_body(p);
    p.ok("image.edit", {{"path", kDoc}, {"layer", "body"}, {"selection", "all"}, {"action", {{"type", "copy"}}}, {"name", "dup"}});
    for (int f = 0; f < 3; ++f) CHECK(export_pixel(p, "dup", f) == kRed);
    CHECK_FALSE(read_doc(p)["layers"][1].contains("cels"));
}
