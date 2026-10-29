// assets.animate_svg: an animation drawn with code (a JS module or SMIL), baked into a sprite sheet.
#include <doctest.h>

#include "asset_test_helpers.h"
#include "fa/core/hash.h"

using namespace fa;
using namespace fa::testing;

namespace {

std::string message(const CommandResult& r) { return r.error["message"].get<std::string>(); }
std::string hint(const CommandResult& r) { return r.error.value("hint", std::string()); }

// A coin that turns: an ellipse whose width follows the progress through the clip.
const char* kCoin =
    "export default function frame({progress, params}) {\n"
    "  const w = Math.abs(Math.cos(progress * Math.PI * 2)) * 30 + 6;\n"
    "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>`\n"
    "    + `<ellipse cx='50' cy='50' rx='${w}' ry='30' fill='${params.color || \"#e8c66a\"}'/></svg>`;\n"
    "}\n";

Json coin_args(const std::string& path = "assets/art/coin.png") {
    return Json{{"path", path}, {"source", "art/coin.anim.js"}, {"frames", 8}, {"fps", 10}, {"frameWidth", 32}, {"frameHeight", 32}};
}

}  // namespace

TEST_CASE("assets.animate_svg: a module gives a byte-identical sheet twice, with its layout and sheet entry") {
    AssetsProject p;
    write_all(p.file("art/coin.anim.js"), kCoin);
    const Json r = p.ok("assets.animate_svg", coin_args());
    CHECK(r["layout"]["columns"] == 3);  // ceil(sqrt(8))
    CHECK(r["layout"]["rows"] == 3);
    CHECK(r["width"] == 96);
    CHECK(r["height"] == 96);
    CHECK(r["layout"]["frames"] == 8);
    CHECK(r.contains("$image"));
    const Image sheet = read_png(p.file("assets/art/coin.png"));
    CHECK(sheet.width == 96);
    CHECK(sheet.height == 96);
    CHECK(get(sheet, 16, 16).a == 255);      // the coin is in the middle of frame 0
    CHECK(get(sheet, 0, 0).a == 0);          // and the corner of the cell is empty
    CHECK(get(sheet, 80, 80).a == 0);        // the ninth cell is unused

    const Json entry = p.manifest()["assets"]["assets/art/coin.png"];
    CHECK(entry["sheet"]["columns"] == 3);
    CHECK(entry["sheet"]["rows"] == 3);
    CHECK(entry["sheet"]["frameWidth"] == 32);
    CHECK(entry["sheet"]["frames"] == 8);
    REQUIRE(entry["sheet"]["clips"].size() == 1);  // one clip named like the file keeps fps and loop
    CHECK(entry["sheet"]["clips"][0]["name"] == "coin");
    CHECK(entry["sheet"]["clips"][0]["lastFrame"] == 7);
    CHECK(entry["sheet"]["clips"][0]["fps"] == 10);
    CHECK(entry["sheet"]["clips"][0]["loop"] == true);
    CHECK_FALSE(entry["sheet"].contains("padding"));
    CHECK_FALSE(entry["sheet"].contains("pivot"));

    const std::string first = read_all(p.file("assets/art/coin.png"));
    p.ok("assets.animate_svg", [&] { Json a = coin_args(); a["overwrite"] = true; return a; }());
    CHECK(read_all(p.file("assets/art/coin.png")) == first);
    p.ok("assets.animate_svg", coin_args("assets/art/coin2.png"));
    CHECK(read_all(p.file("assets/art/coin2.png")) == first);
}

TEST_CASE("assets.animate_svg: provenance is generated and AI by default, with a recipe that hashes the module") {
    AssetsProject p;
    write_all(p.file("art/coin.anim.js"), kCoin);
    p.ok("assets.animate_svg", coin_args());
    const Json prov = p.manifest()["assets"]["assets/art/coin.png"]["provenance"];
    CHECK(prov["origin"] == "generated");
    CHECK(prov["ai"] == true);
    CHECK(prov["source"] == "art/coin.anim.js");
    REQUIRE(prov.contains("recipe"));
    CHECK(prov["recipe"]["command"] == "assets.animate_svg");
    CHECK(prov["recipe"]["args"]["source"] == "art/coin.anim.js");
    CHECK(prov["recipe"]["args"]["seed"] == 0);
    CHECK(prov["recipe"]["args"]["frames"] == 8);
    REQUIRE(prov["recipe"]["inputs"].size() == 1);
    CHECK(prov["recipe"]["inputs"][0]["path"] == "art/coin.anim.js");
    CHECK(prov["recipe"]["inputs"][0]["sha256"] == sha256_file_hex(p.file("art/coin.anim.js")).value());
    // the recipe's arguments make the same bytes again
    const std::string first = read_all(p.file("assets/art/coin.png"));
    p.ok("assets.animate_svg", prov["recipe"]["args"]);
    CHECK(read_all(p.file("assets/art/coin.png")) == first);

    Json human = coin_args("assets/art/human.png");
    human["ai"] = false;
    human["author"] = "Ana";
    human["license"] = "CC-BY-4.0";
    p.ok("assets.animate_svg", human);
    const Json hp = p.manifest()["assets"]["assets/art/human.png"]["provenance"];
    CHECK(hp["ai"] == false);
    CHECK(hp["origin"] == "original");
    CHECK(hp["author"] == "Ana");
    CHECK(hp["license"] == "CC-BY-4.0");
}

TEST_CASE("assets.animate_svg: an SVG with SMIL gives a byte-identical sheet twice, one pass of the animation by default") {
    AssetsProject p;
    const std::string svg =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>"
        "<circle cx='20' cy='50' r='12' fill='#d33'><animate attributeName='cx' values='20;80;20' dur='1s' repeatCount='indefinite'/></circle></svg>";
    Json args{{"path", "assets/art/ball.png"}, {"svg", svg}, {"fps", 8}, {"frameWidth", 32}, {"frameHeight", 32}, {"columns", 4}};
    const Json r = p.ok("assets.animate_svg", args);
    CHECK(r["layout"]["frames"] == 8);  // 1 s at 8 fps
    CHECK(r["layout"]["columns"] == 4);
    CHECK(r["layout"]["rows"] == 2);
    CHECK(r["cycleSeconds"] == 1.0);
    const Image sheet = read_png(p.file("assets/art/ball.png"));
    // frame 0 has the ball on the left, frame 4 (half a second) on the right
    CHECK(get(sheet, 6, 16).a == 255);
    CHECK(get(sheet, 26, 16).a == 0);
    CHECK(get(sheet, 32 * 0 + 6, 32 + 16).a == 0);  // second row frame 4: the ball is at cx = 80 -> x ~ 25.6
    CHECK(get(sheet, 25, 32 + 16).a == 255);
    const std::string first = read_all(p.file("assets/art/ball.png"));
    args["overwrite"] = true;
    p.ok("assets.animate_svg", args);
    CHECK(read_all(p.file("assets/art/ball.png")) == first);
    const Json prov = p.manifest()["assets"]["assets/art/ball.png"]["provenance"];
    CHECK(prov["recipe"]["args"]["svg"] == svg);
    CHECK_FALSE(prov["recipe"].contains("inputs"));
}

TEST_CASE("assets.animate_svg: a .svg file of the project is a source too, and it is an input of the recipe") {
    AssetsProject p;
    write_all(p.file("art/spinner.svg"),
              "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><rect x='40' y='10' width='20' height='40' fill='#333'>"
              "<animateTransform attributeName='transform' type='rotate' from='0 50 50' to='360 50 50' dur='1s' repeatCount='indefinite'/></rect></svg>");
    const Json r = p.ok("assets.animate_svg", Json{{"path", "assets/art/spinner.png"}, {"source", "art/spinner.svg"}, {"fps", 4}, {"frameWidth", 16}});
    CHECK(r["layout"]["frames"] == 4);
    const Json prov = p.manifest()["assets"]["assets/art/spinner.png"]["provenance"];
    CHECK(prov["recipe"]["inputs"][0]["path"] == "art/spinner.svg");
}

TEST_CASE("assets.animate_svg: clips lay out one after another, each a clip of the sheet with its fps, loop and pivot") {
    AssetsProject p;
    write_all(p.file("art/hero.anim.js"),
              "export default function frame({clip, frame, frames, params}) {\n"
              "  const color = clip === 'idle' ? '#3366cc' : '#cc3333';\n"
              "  const size = clip === 'idle' ? 20 : 20 + frame * 4;\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><circle cx='50' cy='50' r='${size}' fill='${color}'/></svg>`;\n"
              "}\n");
    const Json r = p.ok("assets.animate_svg",
                        Json{{"path", "assets/art/hero.png"}, {"source", "art/hero.anim.js"}, {"frameWidth", 16}, {"frameHeight", 16}, {"columns", 4},
                             {"pivot", Json::array({0.5, 1.0})},
                             {"clips", Json::array({Json{{"name", "idle"}, {"frames", 3}, {"fps", 4}},
                                                    Json{{"name", "run"}, {"frames", 5}, {"fps", 12}, {"loop", false}, {"pivot", Json::array({0.25, 0.75})}}})}});
    CHECK(r["layout"]["frames"] == 8);
    CHECK(r["layout"]["rows"] == 2);
    const Json sheet = p.manifest()["assets"]["assets/art/hero.png"]["sheet"];
    REQUIRE(sheet["clips"].size() == 2);
    CHECK(sheet["clips"][0]["name"] == "idle");
    CHECK(sheet["clips"][0]["firstFrame"] == 0);
    CHECK(sheet["clips"][0]["lastFrame"] == 2);
    CHECK(sheet["clips"][0]["fps"] == 4);
    CHECK(sheet["clips"][0]["loop"] == true);
    CHECK(sheet["clips"][1]["name"] == "run");
    CHECK(sheet["clips"][1]["firstFrame"] == 3);
    CHECK(sheet["clips"][1]["lastFrame"] == 7);
    CHECK(sheet["clips"][1]["fps"] == 12);
    CHECK(sheet["clips"][1]["loop"] == false);
    CHECK(sheet["clips"][1]["pivot"] == Json::array({0.25, 0.75}));
    CHECK_FALSE(sheet["clips"][0].contains("pivot"));
    CHECK(sheet["pivot"] == Json::array({0.5, 1.0}));
    const Image img = read_png(p.file("assets/art/hero.png"));
    CHECK(get(img, 8, 8) == Rgba{0x33, 0x66, 0xcc, 255});        // frame 0, the idle clip
    CHECK(get(img, 3 * 16 + 8, 8) == Rgba{0xcc, 0x33, 0x33, 255});   // frame 3, the first of the run clip: column 3 of row 0
    CHECK(get(img, 3 * 16 + 8, 16 + 8) == Rgba{0xcc, 0x33, 0x33, 255});  // frame 7, its last: column 3 of row 1
    CHECK(get(img, 1 * 16 + 8, 8) == Rgba{0x33, 0x66, 0xcc, 255});   // frame 1, still the idle clip
}

TEST_CASE("assets.animate_svg: clips are for modules, and frames belongs to the clips") {
    AssetsProject p;
    write_all(p.file("art/coin.anim.js"), kCoin);
    Json both = coin_args();
    both["clips"] = Json::array({Json{{"name", "a"}, {"frames", 2}}});
    CommandResult r = p.call("assets.animate_svg", both);
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("/frames") != std::string::npos);
    r = p.call("assets.animate_svg", Json{{"path", "assets/x.png"}, {"svg", "<svg xmlns='http://www.w3.org/2000/svg'><rect width='1' height='1'/></svg>"},
                                          {"clips", Json::array({Json{{"name", "a"}, {"frames", 2}}})}});
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("clips need a module") != std::string::npos);
    r = p.call("assets.animate_svg", Json{{"path", "assets/x.png"}, {"source", "art/coin.anim.js"}});  // a module needs frames
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("/frames") != std::string::npos);
    r = p.call("assets.animate_svg", Json{{"path", "assets/x.png"}, {"source", "art/coin.anim.js"}, {"svg", "<svg/>"}, {"frames", 2}});
    REQUIRE_FALSE(r.ok);
    r = p.call("assets.animate_svg", Json{{"path", "assets/x.png"}, {"source", "art/coin.anim.js"}, {"frames", 2}, {"frameWidht", 8}});
    REQUIRE_FALSE(r.ok);
    CHECK(hint(r).find("frameWidth") != std::string::npos);  // did you mean
}

TEST_CASE("assets.animate_svg: an error in the module names its file, line, column and the frame") {
    AssetsProject p;
    write_all(p.file("art/bad.anim.js"),
              "export default function frame({frame}) {\n"
              "  if (frame === 2) {\n"
              "    return nothing.here;\n"
              "  }\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><rect width='5' height='5'/></svg>`;\n"
              "}\n");
    const CommandResult r = p.call("assets.animate_svg", Json{{"path", "assets/bad.png"}, {"source", "art/bad.anim.js"}, {"frames", 4}, {"frameWidth", 8}});
    REQUIRE_FALSE(r.ok);
    const std::string m = message(r);
    CHECK(m.find("art/bad.anim.js:3") != std::string::npos);
    CHECK(m.find("nothing is not defined") != std::string::npos);
    CHECK(m.find("frame 2 of 4") != std::string::npos);
    CHECK(m.find("return nothing.here;") != std::string::npos);  // the source line
    CHECK(hint(r).find("no engine bindings") != std::string::npos);
    CHECK_FALSE(p.exists("assets/bad.png"));

    write_all(p.file("art/syntax.anim.js"), "export default function frame( {\n  return 1;\n}\n");
    const CommandResult s = p.call("assets.animate_svg", Json{{"path", "assets/s.png"}, {"source", "art/syntax.anim.js"}, {"frames", 2}});
    REQUIRE_FALSE(s.ok);
    CHECK(message(s).find("art/syntax.anim.js:") != std::string::npos);

    write_all(p.file("art/novalue.anim.js"), "export default function frame() { }\n");
    const CommandResult n = p.call("assets.animate_svg", Json{{"path", "assets/n.png"}, {"source", "art/novalue.anim.js"}, {"frames", 2}});
    REQUIRE_FALSE(n.ok);
    CHECK(message(n).find("returned undefined") != std::string::npos);

    const CommandResult missing = p.call("assets.animate_svg", Json{{"path", "assets/m.png"}, {"source", "art/nope.anim.js"}, {"frames", 2}});
    REQUIRE_FALSE(missing.ok);
    CHECK(message(missing).find("art/nope.anim.js") != std::string::npos);

    write_all(p.file("art/nodefault.anim.js"), "export function frame() { return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><rect width='5' height='5'/></svg>`; }\n");
    const CommandResult nd = p.call("assets.animate_svg", Json{{"path", "assets/nd.png"}, {"source", "art/nodefault.anim.js"}, {"frames", 2}});
    CHECK(nd.ok);  // `export function frame` is accepted as well as the default export
}

TEST_CASE("assets.animate_svg: a module that runs too long fails at its frame, with the limit in the message") {
    AssetsProject p;
    write_all(p.file("art/slow.anim.js"),
              "export default function frame({frame}) {\n"
              "  if (frame === 1) { for (;;) {} }\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><rect width='5' height='5'/></svg>`;\n"
              "}\n");
    const CommandResult r = p.call("assets.animate_svg", Json{{"path", "assets/slow.png"}, {"source", "art/slow.anim.js"}, {"frames", 3}, {"timeLimitMs", 150}});
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("took longer than 0.15 s") != std::string::npos);
    CHECK(message(r).find("frame 1 of 3") != std::string::npos);
    CHECK(message(r).find("art/slow.anim.js:2") != std::string::npos);

    write_all(p.file("art/slowload.anim.js"), "while (true) {}\nexport default function frame() { return ''; }\n");
    const CommandResult l = p.call("assets.animate_svg", Json{{"path", "assets/slow2.png"}, {"source", "art/slowload.anim.js"}, {"frames", 3}, {"timeLimitMs", 150}});
    REQUIRE_FALSE(l.ok);
    CHECK(message(l).find("took longer than") != std::string::npos);
    CHECK(message(l).find("while loading the module") != std::string::npos);
}

TEST_CASE("assets.animate_svg: a module that fills the memory fails with a message about memory") {
    AssetsProject p;
    write_all(p.file("art/hog.anim.js"),
              "export default function frame() {\n"
              "  const keep = [];\n"
              "  for (;;) keep.push(new Array(100000).fill(1));\n"
              "}\n");
    const CommandResult r = p.call("assets.animate_svg", Json{{"path", "assets/hog.png"}, {"source", "art/hog.anim.js"}, {"frames", 1}, {"timeLimitMs", 20000}});
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("ran out of memory") != std::string::npos);
    CHECK(message(r).find("art/hog.anim.js:3") != std::string::npos);
}

TEST_CASE("assets.animate_svg: Math.random, Date and rng are deterministic and follow the seed") {
    AssetsProject p;
    write_all(p.file("art/sparks.anim.js"),
              "export default function frame({rng, rngFor, frame, seed}) {\n"
              "  const stay = rngFor('sparks');\n"
              "  let shapes = '';\n"
              "  for (let i = 0; i < 6; i++) {\n"
              "    const x = 5 + Math.random() * 90, y = 5 + rng() * 90;\n"
              "    shapes += `<circle cx='${x}' cy='${y}' r='3' fill='#fff'/>`;\n"
              "  }\n"
              "  const sx = 10 + stay() * 80;\n"
              "  const day = new Date().getUTCDate() + (Date.now() > 0 ? 0 : 99);\n"
              "  shapes += `<rect x='${sx}' y='0' width='4' height='${day}' fill='#0f0'/>`;\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>${shapes}</svg>`;\n"
              "}\n");
    auto run = [&](const std::string& out, int seed) {
        p.ok("assets.animate_svg", Json{{"path", out}, {"source", "art/sparks.anim.js"}, {"frames", 4}, {"frameWidth", 40}, {"seed", seed}});
        return read_all(p.file(out));
    };
    const std::string a = run("assets/a.png", 5);
    CHECK(a == run("assets/b.png", 5));   // same seed, same bytes
    CHECK(a != run("assets/c.png", 6));   // another seed, another sheet
    // rng differs from frame to frame: the four frames are not the same picture
    const Image img = read_png(p.file("assets/a.png"));
    bool differ = false;
    for (int y = 0; y < 40 && !differ; ++y)
        for (int x = 0; x < 40; ++x)
            if (!(get(img, x, y) == get(img, 40 + x, y))) {
                differ = true;
                break;
            }
    CHECK(differ);
}

TEST_CASE("assets.animate_svg: the module has the language and nothing else") {
    AssetsProject p;
    write_all(p.file("art/peek.anim.js"),
              "export default function frame() {\n"
              "  const seen = [typeof factoria, typeof process, typeof require, typeof setTimeout, typeof fetch, typeof document, typeof window].join(',');\n"
              "  console.log('seen', seen);\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><rect width='5' height='5'/></svg>`;\n"
              "}\n");
    const Json r = p.ok("assets.animate_svg", Json{{"path", "assets/peek.png"}, {"source", "art/peek.anim.js"}, {"frames", 1}, {"frameWidth", 8}});
    REQUIRE(r.contains("console"));
    CHECK(r["console"][0] == "log: seen undefined,undefined,undefined,undefined,undefined,undefined,undefined");

    write_all(p.file("art/imp.anim.js"), "import fs from 'fs';\nexport default () => '';\n");
    const CommandResult bare = p.call("assets.animate_svg", Json{{"path", "assets/imp.png"}, {"source", "art/imp.anim.js"}, {"frames", 1}});
    REQUIRE_FALSE(bare.ok);
    CHECK(message(bare).find("no packages") != std::string::npos);
    write_all(p.file("art/up.anim.js"), "import x from '../../outside.js';\nexport default () => '';\n");
    const CommandResult up = p.call("assets.animate_svg", Json{{"path", "assets/up.png"}, {"source", "art/up.anim.js"}, {"frames", 1}});
    REQUIRE_FALSE(up.ok);
    CHECK(message(up).find("leaves the project") != std::string::npos);
}

TEST_CASE("assets.animate_svg: a module may import project files, and they become inputs of the recipe") {
    AssetsProject p;
    write_all(p.file("art/lib/shapes.js"), "export const disc = (r, fill) => `<circle cx='50' cy='50' r='${r}' fill='${fill}'/>`;\n");
    write_all(p.file("art/pulse.anim.js"),
              "import { disc } from './lib/shapes.js';\n"
              "export default function frame({progress}) {\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>${disc(10 + 30 * progress, '#09c')}</svg>`;\n"
              "}\n");
    p.ok("assets.animate_svg", Json{{"path", "assets/pulse.png"}, {"source", "art/pulse.anim.js"}, {"frames", 4}, {"frameWidth", 16}});
    const Json inputs = p.manifest()["assets"]["assets/pulse.png"]["provenance"]["recipe"]["inputs"];
    REQUIRE(inputs.size() == 2);
    CHECK(inputs[0]["path"] == "art/pulse.anim.js");
    CHECK(inputs[1]["path"] == "art/lib/shapes.js");
}

TEST_CASE("assets.animate_svg: palette snapping uses only palette colours, alpha is kept") {
    AssetsProject p;
    write_all(p.file("art/coin.anim.js"), kCoin);
    Json a = coin_args();
    a["palette"] = Json::array({"#000000", "#ffffff", "#ff0000"});
    a["params"] = Json{{"color", "#ee3322"}};
    p.ok("assets.animate_svg", a);
    const Image img = read_png(p.file("assets/art/coin.png"));
    int solid = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Rgba c = get(img, x, y);
            if (c.a == 0) continue;
            ++solid;
            const bool inPalette = (c.r == 0 && c.g == 0 && c.b == 0) || (c.r == 255 && c.g == 255 && c.b == 255) || (c.r == 255 && c.g == 0 && c.b == 0);
            CHECK(inPalette);
        }
    CHECK(solid > 100);
    CHECK(get(img, 16, 16) == Rgba{255, 0, 0, 255});

    Json bad = coin_args("assets/art/bad.png");
    bad["palette"] = Json::array({"not-a-colour"});
    const CommandResult r = p.call("assets.animate_svg", bad);
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("/palette") != std::string::npos);
}

TEST_CASE("assets.animate_svg: padding puts a transparent gutter around every cell and is recorded") {
    AssetsProject p;
    write_all(p.file("art/box.anim.js"),
              "export default function frame({frame}) {\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><rect width='10' height='10' fill='${frame === 0 ? \"#ff0000\" : \"#0000ff\"}'/></svg>`;\n"
              "}\n");
    const Json r = p.ok("assets.animate_svg", Json{{"path", "assets/box.png"}, {"source", "art/box.anim.js"}, {"frames", 2}, {"columns", 2},
                                                    {"frameWidth", 8}, {"frameHeight", 8}, {"padding", 2}, {"pivot", Json::array({0.5, 0.0})}});
    CHECK(r["width"] == 24);  // 2 columns * (8 + 2 * 2)
    CHECK(r["height"] == 12);
    CHECK(r["layout"]["cellWidth"] == 12);
    const Image img = read_png(p.file("assets/box.png"));
    CHECK(get(img, 2, 2) == Rgba{255, 0, 0, 255});          // frame 0 starts at x = padding
    CHECK(get(img, 9, 9) == Rgba{255, 0, 0, 255});
    CHECK(get(img, 1, 5).a == 0);                           // the gutter
    CHECK(get(img, 10, 5).a == 0);
    CHECK(get(img, 11, 5).a == 0);
    CHECK(get(img, 12 + 2, 2) == Rgba{0, 0, 255, 255});     // frame 1 starts at x = padding + 1 * (8 + 2 * 2)
    CHECK(get(img, 12 + 9, 9) == Rgba{0, 0, 255, 255});
    CHECK(get(img, 12 + 10, 5).a == 0);
    const Json sheet = p.manifest()["assets"]["assets/box.png"]["sheet"];
    CHECK(sheet["padding"] == 2);
    CHECK(sheet["pivot"] == Json::array({0.5, 0.0}));
    CHECK(sheet["frameWidth"] == 8);
    CHECK(has_text(r["nextSteps"], "skips it by itself"));  // the SpriteAnimator reads the gutter from the sheet entry
    CHECK_FALSE(has_text(r["nextSteps"], "no gutter"));
    CHECK(has_text(r["nextSteps"], "assets.preview_sheet"));
}

TEST_CASE("assets.animate_svg: the style is the one of rasterize_svg, applied to every frame") {
    AssetsProject p;
    write_all(p.file("art/coin.anim.js"), kCoin);
    Json styled = coin_args("assets/art/styled.png");
    styled["style"] = "watercolor";
    styled["seed"] = 3;
    p.ok("assets.animate_svg", styled);
    p.ok("assets.animate_svg", coin_args("assets/art/plain.png"));
    CHECK(read_all(p.file("assets/art/styled.png")) != read_all(p.file("assets/art/plain.png")));
    const std::string first = read_all(p.file("assets/art/styled.png"));
    styled["overwrite"] = true;
    p.ok("assets.animate_svg", styled);
    CHECK(read_all(p.file("assets/art/styled.png")) == first);

    // the same SVG through rasterize_svg and through a one-frame sheet gives the same pixels
    const std::string svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><circle cx='50' cy='50' r='30' fill='#cc3333'/></svg>";
    p.ok("assets.rasterize_svg", Json{{"path", "assets/art/one.png"}, {"svg", svg}, {"width", 48}, {"height", 48}, {"style", "ink"}, {"seed", 9}});
    p.ok("assets.animate_svg", Json{{"path", "assets/art/oneframe.png"}, {"svg", svg}, {"frames", 1}, {"frameWidth", 48}, {"frameHeight", 48}, {"style", "ink"}, {"seed", 9}});
    CHECK(read_all(p.file("assets/art/oneframe.png")) == read_all(p.file("assets/art/one.png")));

    const CommandResult bad = p.call("assets.animate_svg", Json{{"path", "assets/art/b.png"}, {"svg", svg}, {"frames", 1}, {"style", "watercolour"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(hint(bad).find("watercolor") != std::string::npos);
}

TEST_CASE("assets.animate_svg: warnings for empty frames, shapes on the cell edge and a loop that jumps") {
    AssetsProject p;
    write_all(p.file("art/blink.anim.js"),
              "export default function frame({frame}) {\n"
              "  if (frame === 1) return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'></svg>`;\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><circle cx='5' cy='5' r='2' fill='#fff'/></svg>`;\n"
              "}\n");
    Json r = p.ok("assets.animate_svg", Json{{"path", "assets/blink.png"}, {"source", "art/blink.anim.js"}, {"frames", 3}, {"frameWidth", 16}});
    CHECK(has_warning(r, "draw nothing (frame 1)"));

    write_all(p.file("art/wide.anim.js"),
              "export default function frame({frame}) {\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><rect width='${frame ? 10 : 4}' height='${frame ? 10 : 4}' x='${frame ? 0 : 3}' y='${frame ? 0 : 3}' fill='#fff'/></svg>`;\n"
              "}\n");
    r = p.ok("assets.animate_svg", Json{{"path", "assets/wide.png"}, {"source", "art/wide.anim.js"}, {"frames", 2}, {"frameWidth", 16}, {"loop", false}});
    CHECK(has_warning(r, "touch the edge of the cell in 1 frame(s) (frame 1)"));

    // the last frame is far from the first: a loop that pops
    write_all(p.file("art/grow.anim.js"),
              "export default function frame({frame, frames}) {\n"
              "  const r = 1 + 4 * frame / (frames - 1);\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><circle cx='5' cy='5' r='${r}' fill='#fff'/></svg>`;\n"
              "}\n");
    r = p.ok("assets.animate_svg", Json{{"path", "assets/grow.png"}, {"source", "art/grow.anim.js"}, {"frames", 8}, {"frameWidth", 32}, {"loop", true}});
    CHECK(has_warning(r, "The loop jumps"));
    r = p.ok("assets.animate_svg", Json{{"path", "assets/grow2.png"}, {"source", "art/grow.anim.js"}, {"frames", 8}, {"frameWidth", 32}, {"loop", false}});
    CHECK_FALSE(has_warning(r, "The loop"));

    // a smooth loop warns of nothing
    write_all(p.file("art/spin.anim.js"),
              "export default function frame({progress}) {\n"
              "  const r = 3 + Math.sin(progress * Math.PI * 2);\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><circle cx='5' cy='5' r='${r}' fill='#fff'/></svg>`;\n"
              "}\n");
    r = p.ok("assets.animate_svg", Json{{"path", "assets/spin.png"}, {"source", "art/spin.anim.js"}, {"frames", 8}, {"frameWidth", 32}});
    CHECK_FALSE(r.contains("warnings"));
}

TEST_CASE("assets.animate_svg: SMIL features that cannot be sampled are warnings, not errors") {
    AssetsProject p;
    const std::string svg =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><rect x='10' y='10' width='40' height='40' fill='#fff'>"
        "<animate attributeName='x' from='10' to='50' dur='1s' begin='click'/></rect></svg>";
    const Json r = p.ok("assets.animate_svg", Json{{"path", "assets/ev.png"}, {"svg", svg}, {"frames", 2}, {"frameWidth", 32}});
    CHECK(has_warning(r, "<animate attributeName=\"x\"> on <rect>"));
    CHECK(has_warning(r, "click"));
}

TEST_CASE("assets.animate_svg: the sheet must fit, the path is checked and an existing file needs overwrite") {
    AssetsProject p;
    write_all(p.file("art/coin.anim.js"), kCoin);
    Json huge = coin_args();
    huge["frames"] = 200;
    huge["frameWidth"] = 1024;
    CommandResult r = p.call("assets.animate_svg", huge);
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("8192") != std::string::npos);
    r = p.call("assets.animate_svg", coin_args("art/coin.png"));  // not under assets/
    REQUIRE_FALSE(r.ok);
    r = p.call("assets.animate_svg", coin_args("assets/art/coin.jpg"));
    REQUIRE_FALSE(r.ok);
    p.ok("assets.animate_svg", coin_args());
    r = p.call("assets.animate_svg", coin_args());
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "exists");
}
