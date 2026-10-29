// assets.generate_texture: offline procedural textures that are a pure function of their arguments.
#include <doctest.h>

#include <cmath>

#include "asset_test_helpers.h"

using namespace fa;
using namespace fa::testing;

namespace {

Json texture_args(const std::string& path, const std::string& preset) {
    return Json{{"path", path}, {"preset", preset}, {"width", 64}, {"height", 64}};
}

std::string message(const CommandResult& r) { return r.error["message"].get<std::string>(); }

// The mean absolute difference of two lines of the picture, over the three colour channels.
double line_diff(const Image& img, int ax, int ay, int bx, int by, bool column) {
    double sum = 0;
    const int n = column ? img.height : img.width;
    for (int i = 0; i < n; ++i) {
        const Rgba a = column ? get(img, ax, i) : get(img, i, ay);
        const Rgba b = column ? get(img, bx, i) : get(img, i, by);
        sum += (std::abs(a.r - b.r) + std::abs(a.g - b.g) + std::abs(a.b - b.b)) / 3.0;
    }
    return sum / n;
}

}  // namespace

TEST_CASE("assets.generate_texture: every preset writes a PNG of the asked size with provenance") {
    AssetsProject p;
    const char* presets[] = {"paper", "parchment", "wood", "planks", "leather", "fabric", "stone", "value", "fbm", "cellular", "gradient", "radial", "vignette"};
    for (const char* name : presets) {
        INFO(std::string(name));
        const std::string path = std::string("assets/t/") + name + ".png";
        Json args = texture_args(path, name);
        args["width"] = 80;
        args["height"] = 48;
        const Json r = p.ok("assets.generate_texture", args);
        CHECK(r["path"] == path);
        CHECK(r["width"] == 80);
        CHECK(r["height"] == 48);
        const Image img = read_png(p.file(path));
        CHECK(img.width == 80);
        CHECK(img.height == 48);
        const Json prov = p.manifest()["assets"][path]["provenance"];
        CHECK(prov["origin"] == "original");
        CHECK(prov["ai"] == false);
        CHECK(prov["kind"] == "image");
        CHECK(prov["license"] == "CC0-1.0");
        CHECK(prov["notes"].get<std::string>().find(std::string("\"preset\":\"") + name + "\"") != std::string::npos);
    }
    // a material is not flat: it has real variation in its pixels
    const Image wood = read_png(p.file("assets/t/wood.png"));
    int lo = 255, hi = 0;
    for (int y = 0; y < wood.height; ++y)
        for (int x = 0; x < wood.width; ++x) {
            lo = std::min<int>(lo, get(wood, x, y).g);
            hi = std::max<int>(hi, get(wood, x, y).g);
        }
    CHECK(hi - lo > 25);
    // the material presets are opaque; the vignette is transparent in the middle and opaque at the corner
    CHECK(get(read_png(p.file("assets/t/paper.png")), 3, 3).a == 255);
    const Image vig = read_png(p.file("assets/t/vignette.png"));
    CHECK(get(vig, 40, 24).a == 0);
    CHECK(get(vig, 0, 0).a > 150);
}

TEST_CASE("assets.generate_texture: the same arguments give the same bytes; another seed another picture") {
    AssetsProject p;
    for (const char* preset : {"paper", "wood", "leather", "stone", "fabric", "planks", "parchment"}) {
        INFO(std::string(preset));
        Json a = texture_args("assets/a.png", preset);
        a["seed"] = 7;
        a["overwrite"] = true;
        p.ok("assets.generate_texture", a);
        const std::string first = read_all(p.file("assets/a.png"));
        p.ok("assets.generate_texture", a);
        CHECK(read_all(p.file("assets/a.png")) == first);
        Json b = a;
        b["path"] = "assets/b.png";
        p.ok("assets.generate_texture", b);
        CHECK(read_all(p.file("assets/b.png")) == first);  // the path does not change the picture
        b["seed"] = 8;
        p.ok("assets.generate_texture", b);
        CHECK(read_all(p.file("assets/b.png")) != first);
    }
}

TEST_CASE("assets.generate_texture: tileable pictures meet at their edges") {
    AssetsProject p;
    for (const char* preset : {"paper", "parchment", "wood", "planks", "leather", "fabric", "stone", "value", "fbm", "cellular"}) {
        INFO(std::string(preset));
        Json a = texture_args(std::string("assets/") + preset + ".png", preset);
        a["width"] = 96;
        a["height"] = 96;
        a["tileable"] = true;
        const Json r = p.ok("assets.generate_texture", a);
        CHECK(r["tileable"] == true);
        const Image img = read_png(p.file(std::string("assets/") + preset + ".png"));
        // The step across the seam (last column to the first) is no bigger than the steps inside the picture, within noise.
        double inside = 0, insideY = 0;
        const int n = 20;
        for (int k = 0; k < n; ++k) {
            inside += line_diff(img, 10 + k, 0, 11 + k, 0, true);
            insideY += line_diff(img, 0, 10 + k, 0, 11 + k, false);
        }
        inside /= n;
        insideY /= n;
        CHECK(line_diff(img, 95, 0, 0, 0, true) <= inside * 2.0 + 4.0);
        CHECK(line_diff(img, 0, 95, 0, 0, false) <= insideY * 2.0 + 4.0);
    }
    // not tileable: the wood is not matched across the top and bottom edges of a smaller picture (control), and the
    // presets with an edge say so
    const Json g = p.ok("assets.generate_texture", Json{{"path", "assets/g.png"}, {"preset", "gradient"}, {"width", 32}, {"height", 32}, {"tileable", true}});
    CHECK(g["tileable"] == false);
    CHECK(has_warning(g, "tileable was ignored"));
}

TEST_CASE("assets.generate_texture: colours, gradient angle, vignette and sizes") {
    AssetsProject p;
    p.ok("assets.generate_texture", Json{{"path", "assets/g.png"}, {"preset", "gradient"}, {"width", 64}, {"height", 64}, {"color", "#ff0000"}, {"accent", "#0000ff"}, {"angle", 90}});
    const Image g = read_png(p.file("assets/g.png"));
    CHECK(get(g, 0, 32).r > 235);   // left end: the colour
    CHECK(get(g, 0, 32).b < 20);
    CHECK(get(g, 63, 32).b > 235);  // right end: the accent
    CHECK(get(g, 63, 32).r < 20);
    CHECK(std::abs(get(g, 10, 5).r - get(g, 10, 60).r) < 6);  // the gradient is horizontal

    // recolouring a material changes its average colour
    p.ok("assets.generate_texture", Json{{"path", "assets/red.png"}, {"preset", "leather"}, {"width", 64}, {"height", 64}, {"color", "#c03030"}, {"accent", "#300808"}});
    const Image red = read_png(p.file("assets/red.png"));
    long r = 0, b = 0;
    for (int y = 0; y < 64; ++y)
        for (int x = 0; x < 64; ++x) {
            r += get(red, x, y).r;
            b += get(red, x, y).b;
        }
    CHECK(r > b * 2);

    // a parchment page gets darker edges, and tileable does not (the edge would not repeat)
    p.ok("assets.generate_texture", Json{{"path", "assets/page.png"}, {"preset", "parchment"}, {"width", 128}, {"height", 128}, {"vignette", 1.0}, {"seed", 2}});
    const Image page = read_png(p.file("assets/page.png"));
    auto luma = [&](int x, int y) { const Rgba c = get(page, x, y); return c.r + c.g + c.b; };
    long edge = 0, middle = 0;
    for (int i = 0; i < 128; i += 4) {
        edge += luma(i, 1) + luma(1, i);
        middle += luma(i / 2 + 32, 64) + luma(64, i / 2 + 32);
    }
    CHECK(edge < middle * 0.85);

    // not square, and the largest side
    p.ok("assets.generate_texture", Json{{"path", "assets/wide.png"}, {"preset", "stone"}, {"width", 200}, {"height", 40}});
    CHECK(read_png(p.file("assets/wide.png")).width == 200);
    auto big = p.call("assets.generate_texture", Json{{"path", "assets/huge.png"}, {"preset", "paper"}, {"width", 4096}});
    CHECK_FALSE(big.ok);
    CHECK(message(big).find("2048") != std::string::npos);
    // only the width given: a square
    p.ok("assets.generate_texture", Json{{"path", "assets/sq.png"}, {"preset", "paper"}, {"width", 40}});
    CHECK(read_png(p.file("assets/sq.png")).height == 40);
}

TEST_CASE("assets.generate_texture: a normal map of the same relief") {
    AssetsProject p;
    const Json r = p.ok("assets.generate_texture", Json{{"path", "assets/stone.png"}, {"preset", "stone"}, {"width", 96}, {"height", 96}, {"normalMap", true}});
    CHECK(r["normalMap"] == "assets/stone_n.png");
    const Image n = read_png(p.file("assets/stone_n.png"));
    CHECK(n.width == 96);
    CHECK(n.height == 96);
    // unit-length tangent-space vectors that mostly point out of the surface, and with some tilt where the relief is
    int tilted = 0;
    for (int y = 0; y < 96; ++y)
        for (int x = 0; x < 96; ++x) {
            const Rgba c = get(n, x, y);
            const double nx = c.r / 127.5 - 1, ny = c.g / 127.5 - 1, nz = c.b / 127.5 - 1;
            CHECK(std::sqrt(nx * nx + ny * ny + nz * nz) == doctest::Approx(1.0).epsilon(0.03));
            CHECK(nz > 0);
            tilted += (std::abs(nx) + std::abs(ny) > 0.15) ? 1 : 0;
            CHECK(c.a == 255);
        }
    CHECK(tilted > 300);
    const Json prov = p.manifest()["assets"]["assets/stone_n.png"]["provenance"];
    CHECK(prov["ai"] == false);
    CHECK(prov["notes"].get<std::string>().find("normal map") != std::string::npos);

    // a flat height field (a gradient has a smooth slope, a tiny one) gives a near-flat map; stronger relief tilts more
    p.ok("assets.generate_texture", Json{{"path", "assets/soft.png"}, {"preset", "stone"}, {"width", 96}, {"height", 96}, {"normalMap", true}, {"normalStrength", 0.5}});
    const Image soft = read_png(p.file("assets/soft_n.png"));
    long tiltStrong = 0, tiltSoft = 0;
    for (int y = 0; y < 96; ++y)
        for (int x = 0; x < 96; ++x) {
            tiltStrong += std::abs(get(n, x, y).r - 128);
            tiltSoft += std::abs(get(soft, x, y).r - 128);
        }
    CHECK(tiltStrong > tiltSoft);
}

TEST_CASE("assets.generate_texture: errors teach") {
    AssetsProject p;
    auto typo = p.call("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "woood"}});
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["code"] == "invalid_arguments");  // the schema enum refuses it and suggests
    CHECK(typo.error["hint"].get<std::string>().find("wood") != std::string::npos);
    CHECK(typo.error["hint"].get<std::string>().find("parchment") != std::string::npos);

    auto outside = p.call("assets.generate_texture", Json{{"path", "textures/a.png"}, {"preset", "wood"}});
    CHECK(message(outside).find("under assets/") != std::string::npos);
    auto jpg = p.call("assets.generate_texture", Json{{"path", "assets/a.jpg"}, {"preset", "wood"}});
    CHECK(message(jpg).find(".png") != std::string::npos);
    auto badColour = p.call("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "wood"}, {"color", "notacolour"}});
    REQUIRE_FALSE(badColour.ok);
    CHECK(message(badColour).find("/color") != std::string::npos);
    auto badScale = p.call("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "wood"}, {"scale", 100}});
    CHECK_FALSE(badScale.ok);
    CHECK_FALSE(p.call("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "wood"}, {"sizee", 3}}).ok);
    CHECK_FALSE(p.exists("assets/a.png"));

    p.ok("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "wood"}, {"width", 16}});
    auto again = p.call("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "wood"}, {"width", 16}});
    REQUIRE_FALSE(again.ok);
    CHECK(again.error["code"] == "exists");
    p.ok("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "stone"}, {"width", 16}, {"overwrite", true}});
}

namespace {

// The darkest column of the middle of the first board, relative to the mean: a butt joint is a dark column.
double darkest_column_ratio(const Image& img, int rows) {
    const int y = img.height / (2 * rows);
    double sum = 0, lowest = 1e9;
    for (int x = 0; x < img.width; ++x) {
        const Rgba c = get(img, x, y);
        const double lum = 0.3 * c.r + 0.59 * c.g + 0.11 * c.b;
        sum += lum;
        lowest = std::min(lowest, lum);
    }
    return lowest / (sum / img.width);
}

double mean_luminance_at_row_edge(const Image& img, int y) {
    double sum = 0;
    for (int x = 0; x < img.width; ++x) {
        const Rgba c = get(img, x, y);
        sum += 0.3 * c.r + 0.59 * c.g + 0.11 * c.b;
    }
    return sum / img.width;
}

}  // namespace

TEST_CASE("assets.generate_texture: planks options set the board length, the gap and how dark it is") {
    AssetsProject p;
    Json a = texture_args("assets/p.png", "planks");
    a["width"] = 512;
    a["height"] = 504;
    a["plankCount"] = 7;
    a["seed"] = 3;
    a["gapWidth"] = 0.05;
    a["gapDarkness"] = 1.0;
    a["overwrite"] = true;

    a["plankLength"] = 0;  // boards from side to side: no butt joint
    const Json r = p.ok("assets.generate_texture", a);
    CHECK_FALSE(r.contains("warnings"));
    CHECK(r["provenance"]["notes"].get<std::string>().find("\"plankLength\":0.0") != std::string::npos);
    const Image full = read_png(p.file("assets/p.png"));
    CHECK(darkest_column_ratio(full, 7) > 0.6);

    a["plankLength"] = 0.25;  // four boards per row: joints show as dark columns
    p.ok("assets.generate_texture", a);
    const Image shortBoards = read_png(p.file("assets/p.png"));
    CHECK(darkest_column_ratio(shortBoards, 7) < 0.5);

    // plankCount: the seams between 7 boards sit at multiples of 72 px; the dark gap row is there, not at 6 boards' spacing
    CHECK(mean_luminance_at_row_edge(full, 72) < mean_luminance_at_row_edge(full, 36));

    // gapDarkness 0 leaves the seam as light as the wood around it, gapDarkness 1 darkens it
    a["plankLength"] = 0;
    a["gapDarkness"] = 0.0;
    p.ok("assets.generate_texture", a);
    const Image pale = read_png(p.file("assets/p.png"));
    CHECK(mean_luminance_at_row_edge(pale, 72) > mean_luminance_at_row_edge(full, 72) * 1.3);

    // same arguments, same bytes
    const std::string first = read_all(p.file("assets/p.png"));
    p.ok("assets.generate_texture", a);
    CHECK(read_all(p.file("assets/p.png")) == first);
}

TEST_CASE("assets.generate_texture: planks options are checked and ignored by other presets") {
    AssetsProject p;
    auto bad = p.call("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "planks"}, {"plankCount", 0}});
    REQUIRE_FALSE(bad.ok);
    CHECK(message(bad).find("/plankCount") != std::string::npos);
    CHECK_FALSE(p.call("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "planks"}, {"plankLength", 2}}).ok);
    CHECK_FALSE(p.call("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "planks"}, {"gapDarkness", -1}}).ok);
    CHECK_FALSE(p.call("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "planks"}, {"plankLenght", 1}}).ok);
    const Json r = p.ok("assets.generate_texture", Json{{"path", "assets/a.png"}, {"preset", "wood"}, {"width", 16}, {"gapWidth", 0.1}});
    REQUIRE(r.contains("warnings"));
    CHECK(r["warnings"][0].get<std::string>().find("gapWidth only changes the planks preset") != std::string::npos);
}
