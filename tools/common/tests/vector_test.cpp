// The vector.* commands (docs/VECTOR.md): path booleans, offset, stroke to path, simplify, smooth, align, distribute, repeat and the
// style guide, all on real SVG with element and parent transforms, and the way the result is written back into the document.
#include <doctest.h>

#include <cmath>
#include <filesystem>
#include <format>

#include "asset_test_helpers.h"

using namespace fa;
using namespace fa::testing;

namespace {

constexpr const char* kHead = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" width=\"100\" height=\"100\">";

std::string svg_of(const std::string& body) { return std::string(kHead) + body + "</svg>"; }

std::string error_of(const CommandResult& r) { return r.error["message"].get<std::string>() + " " + r.error.value("hint", std::string()); }

bool contains(const std::string& text, const std::string& needle) { return text.find(needle) != std::string::npos; }

// A call on SVG text with a 100 px preview (one pixel per drawing unit); the preview picture is read back for pixel checks.
struct Run {
    Json r;
    Image img;
    std::string svg;
};

Run run(const AssetsProject& p, const std::string& cmd, const std::string& svg, Json args) {
    args["svg"] = svg;
    args["previewSize"] = 100;
    Run out;
    out.r = p.ok(cmd, args);
    REQUIRE(out.r.contains("$image"));
    out.img = read_png(std::filesystem::path(out.r["$image"]["path"].get<std::string>()));
    out.svg = out.r.value("svg", std::string());
    return out;
}

// The picture is covered (opaque) at a drawing point.
bool filled(const Run& r, int x, int y) { return get(r.img, x, y).a > 200; }
bool empty(const Run& r, int x, int y) { return get(r.img, x, y).a < 40; }

// The bounds [x, y, w, h] vector.info reports for an element.
std::vector<double> bounds_of(const AssetsProject& p, const std::string& svg, const std::string& id) {
    const Json info = p.ok("vector.info", Json{{"svg", svg}, {"previewSize", 32}});
    for (const Json& e : info["elements"])
        if (e.value("id", std::string()) == id) return {e["bounds"][0].get<double>(), e["bounds"][1].get<double>(), e["bounds"][2].get<double>(), e["bounds"][3].get<double>()};
    FAIL("no element " << id << " in " << info.dump());
    return {};
}

void check_bounds(const std::vector<double>& got, std::vector<double> want, double tol = 0.05) {
    REQUIRE(got.size() == 4);
    for (int i = 0; i < 4; ++i) CHECK_MESSAGE(std::abs(got[i] - want[i]) <= tol, "component " << i << ": " << got[i] << " vs " << want[i]);
}

std::string polygon_circle(double cx, double cy, double r, int n) {
    std::string d;
    for (int i = 0; i < n; ++i) {
        const double a = 2 * 3.14159265358979 * i / n;
        d += std::format("{}{:.3f} {:.3f} ", i ? "L" : "M", cx + r * std::cos(a), cy + r * std::sin(a));
    }
    return d + "Z";
}

}  // namespace

// ---- booleans ---------------------------------------------------------------------------------------------------------

TEST_CASE("vector.boolean: subtract keeps the first shape's id, group and style, honours the group's transform and returns Beziers") {
    AssetsProject p;
    const std::string svg = svg_of(
        "<!-- badge -->\n<g id=\"g1\" transform=\"translate(10 10)\">\n  <circle id=\"disc\" cx=\"40\" cy=\"40\" r=\"30\" fill=\"#ff0000\" class=\"body\"/>\n"
        "  <rect id=\"hole\" x=\"30\" y=\"30\" width=\"20\" height=\"20\" fill=\"#000\"/>\n</g>\n<rect id=\"other\" x=\"0\" y=\"90\" width=\"10\" height=\"10\" fill=\"#00f\"/>\n");
    const Run run1 = run(p, "vector.boolean", svg, {{"op", "subtract"}, {"elements", Json::array({"disc", "hole"})}});
    CHECK(run1.r["changed"] == true);
    CHECK(run1.r["result"] == "disc");
    CHECK(run1.r["removed"] == Json::array({"hole"}));
    CHECK(contains(run1.svg, "<!-- badge -->\n<g id=\"g1\" transform=\"translate(10 10)\">"));
    CHECK(contains(run1.svg, "<path id=\"disc\""));
    CHECK(contains(run1.svg, "fill=\"#ff0000\" class=\"body\"/>"));
    CHECK(contains(run1.svg, " C"));  // the circle's curves come back as Beziers
    CHECK_FALSE(contains(run1.svg, "<circle"));
    CHECK_FALSE(contains(run1.svg, "id=\"hole\""));
    CHECK(contains(run1.svg, "<rect id=\"other\" x=\"0\" y=\"90\" width=\"10\" height=\"10\" fill=\"#00f\"/>\n</svg>"));  // untouched text stays
    // the disc is at (50, 50) in the drawing: the hole (40..60) is empty, the ring is red
    CHECK(empty(run1, 50, 50));
    CHECK(empty(run1, 45, 55));
    CHECK(filled(run1, 25, 50));
    CHECK(filled(run1, 50, 25));
    CHECK(filled(run1, 74, 50));
    CHECK(empty(run1, 80, 50));
    check_bounds(bounds_of(p, run1.svg, "disc"), {20, 20, 60, 60}, 0.1);
    // the same call again gives the same bytes
    const Run again = run(p, "vector.boolean", svg, {{"op", "subtract"}, {"elements", Json::array({"disc", "hole"})}});
    CHECK(again.svg == run1.svg);
}

TEST_CASE("vector.boolean: union, intersect and exclude with element transforms, selectors and keepInputs") {
    AssetsProject p;
    const std::string svg = svg_of(
        "<rect id=\"a\" class=\"s\" x=\"10\" y=\"10\" width=\"40\" height=\"40\" fill=\"red\"/>"
        "<rect id=\"b\" class=\"s\" x=\"0\" y=\"0\" width=\"20\" height=\"20\" fill=\"blue\" transform=\"translate(30 30) scale(2)\"/>");
    // b covers 30..70
    {
        const Run r = run(p, "vector.boolean", svg, {{"op", "union"}, {"elements", ".s"}});
        CHECK(r.r["result"] == "a");
        CHECK(filled(r, 20, 20));
        CHECK(filled(r, 60, 60));
        CHECK(filled(r, 40, 40));
        CHECK(empty(r, 60, 20));
        CHECK(empty(r, 20, 60));
        CHECK(contains(r.svg, "fill=\"red\""));
        CHECK_FALSE(contains(r.svg, "id=\"b\""));
    }
    {
        const Run r = run(p, "vector.boolean", svg, {{"op", "intersect"}, {"elements", Json::array({"#a", "#b"})}});
        CHECK(filled(r, 40, 40));
        CHECK(empty(r, 20, 20));
        CHECK(empty(r, 60, 60));
    }
    {
        const Run r = run(p, "vector.boolean", svg, {{"op", "exclude"}, {"elements", Json::array({"a", "b"})}});
        CHECK(empty(r, 40, 40));
        CHECK(filled(r, 20, 20));
        CHECK(filled(r, 60, 60));
    }
    {
        // the first shape is b: the result is written in b's own (scaled) space, so it lands in the same place
        const Run r = run(p, "vector.boolean", svg, {{"op", "union"}, {"elements", Json::array({"b", "a"})}});
        CHECK(r.r["result"] == "b");
        CHECK(contains(r.svg, "transform=\"translate(30 30) scale(2)\""));
        CHECK(filled(r, 20, 20));
        CHECK(filled(r, 60, 60));
        CHECK(empty(r, 60, 20));
        check_bounds(bounds_of(p, r.svg, "b"), {10, 10, 60, 60});
    }
    {
        const Run r = run(p, "vector.boolean", svg, {{"op", "intersect"}, {"elements", Json::array({"a", "b"})}, {"keepInputs", true}});
        CHECK(contains(r.svg, "id=\"b\""));
        CHECK(r.r["removed"].empty());
    }
}

TEST_CASE("vector.boolean: even-odd shapes, groups as operands and the errors") {
    AssetsProject p;
    // a star-like ring drawn with evenodd: the inner square is a hole
    const std::string svg = svg_of(
        "<path id=\"ring\" fill-rule=\"evenodd\" d=\"M10 10 H90 V90 H10 Z M30 30 H70 V70 H30 Z\" fill=\"#222\"/>"
        "<g id=\"pair\"><rect id=\"p1\" x=\"40\" y=\"0\" width=\"20\" height=\"100\"/><rect id=\"p2\" x=\"0\" y=\"40\" width=\"100\" height=\"20\"/></g>");
    const Run r = run(p, "vector.boolean", svg, {{"op", "subtract"}, {"elements", Json::array({"ring", "pair"})}});
    CHECK(empty(r, 50, 50));  // inside the evenodd hole
    CHECK(empty(r, 50, 20));  // under the vertical bar of the group
    CHECK(filled(r, 20, 20));
    CHECK(filled(r, 80, 80));
    CHECK(r.r["removed"].size() == 2);  // the group is one operand: the shapes in it go
    CHECK_FALSE(contains(r.svg, "id=\"p1\""));

    CommandResult one = p.call("vector.boolean", Json{{"svg", svg}, {"op", "union"}, {"elements", "ring"}});
    REQUIRE_FALSE(one.ok);
    CHECK(one.error["code"] == "invalid_argument");
    CHECK(error_of(one).find("at least two") != std::string::npos);

    CommandResult miss = p.call("vector.boolean", Json{{"svg", svg}, {"op", "union"}, {"elements", Json::array({"ring", "pairs"})}});
    REQUIRE_FALSE(miss.ok);
    CHECK(error_of(miss).find("Did you mean 'pair'") != std::string::npos);
    CHECK(error_of(miss).find("/elements/1") != std::string::npos);

    const std::string apart = svg_of("<rect id=\"x\" width=\"10\" height=\"10\"/><rect id=\"y\" x=\"50\" width=\"10\" height=\"10\"/>");
    CommandResult none = p.call("vector.boolean", Json{{"svg", apart}, {"op", "intersect"}, {"elements", Json::array({"x", "y"})}});
    REQUIRE_FALSE(none.ok);
    CHECK(none.error["code"] == "empty_result");
    CHECK(error_of(none).find("do not overlap") != std::string::npos);

    CommandResult badOp = p.call("vector.boolean", Json{{"svg", apart}, {"op", "unoin"}, {"elements", Json::array({"x", "y"})}});
    REQUIRE_FALSE(badOp.ok);
    CHECK(error_of(badOp).find("union") != std::string::npos);
}

// ---- offset -------------------------------------------------------------------------------------------------------------

TEST_CASE("vector.offset: grow, inset and the join shapes; distances are in the drawing, whatever the shape's transform") {
    AssetsProject p;
    const std::string box = svg_of("<rect id=\"b\" x=\"30\" y=\"30\" width=\"40\" height=\"40\" fill=\"#3a3\"/>");
    {
        const Run r = run(p, "vector.offset", box, {{"elements", "b"}, {"distance", 6}, {"join", "round"}});
        CHECK(contains(r.svg, "<path id=\"b\""));
        CHECK(contains(r.svg, "fill=\"#3a3\""));
        CHECK(filled(r, 25, 50));
        CHECK(empty(r, 22, 50));
        CHECK(empty(r, 25, 25));  // a round corner: 7.07 away from the corner
        CHECK(filled(r, 27, 27));
        CHECK(contains(r.svg, " C"));
        check_bounds(bounds_of(p, r.svg, "b"), {24, 24, 52, 52});
    }
    {
        const Run r = run(p, "vector.offset", box, {{"elements", "b"}, {"distance", 6}, {"join", "miter"}});
        CHECK(filled(r, 25, 25));  // a sharp corner
        CHECK_FALSE(contains(r.svg, " C"));
    }
    {
        const Run r = run(p, "vector.offset", box, {{"elements", "b"}, {"distance", -8}});
        CHECK(empty(r, 36, 50));
        CHECK(filled(r, 40, 50));
        CHECK(filled(r, 50, 50));
        check_bounds(bounds_of(p, r.svg, "b"), {38, 38, 24, 24});
    }
    {
        const Run r = run(p, "vector.offset", box, {{"elements", "b"}, {"distance", 5}, {"copy", true}});
        CHECK(contains(r.svg, "<rect id=\"b\""));
        CHECK(contains(r.svg, "id=\"b-offset\""));
        CHECK(r.r["results"][0]["element"] == "b-offset");
    }
    {
        // a circle scaled by 2 about the origin: radius 10 -> 20 in the drawing, centred (50, 50)
        const std::string c = svg_of("<circle id=\"c\" cx=\"25\" cy=\"25\" r=\"10\" fill=\"#a33\" transform=\"scale(2)\"/>");
        const Run r = run(p, "vector.offset", c, {{"elements", "c"}, {"distance", -5}});
        CHECK(contains(r.svg, "transform=\"scale(2)\""));
        CHECK(filled(r, 50 + 13, 50));
        CHECK(empty(r, 50 + 17, 50));
        CHECK(contains(r.svg, " C"));
        check_bounds(bounds_of(p, r.svg, "c"), {35, 35, 30, 30}, 0.1);
    }
    {
        CommandResult zero = p.call("vector.offset", Json{{"svg", box}, {"elements", "b"}, {"distance", 0}});
        REQUIRE_FALSE(zero.ok);
        CHECK(error_of(zero).find("other than 0") != std::string::npos);
        CommandResult gone = p.call("vector.offset", Json{{"svg", box}, {"elements", "b"}, {"distance", -30}});
        REQUIRE_FALSE(gone.ok);
        CHECK(gone.error["code"] == "empty_result");
    }
}

// ---- stroke to path ------------------------------------------------------------------------------------------------------

TEST_CASE("vector.stroke_to_path: widths, caps, joins and dashes follow SVG") {
    AssetsProject p;
    const std::string line = svg_of("<path id=\"l\" d=\"M20 50 L60 50 L60 20\" fill=\"none\" stroke=\"#00f\" stroke-width=\"10\"/>");
    {
        const Run r = run(p, "vector.stroke_to_path", line, {{"elements", "l"}});
        CHECK(contains(r.svg, "fill=\"#00f\""));
        CHECK(contains(r.svg, "stroke=\"none\""));
        CHECK(contains(r.svg, "id=\"l\""));
        CHECK_FALSE(contains(r.svg, "stroke-width"));
        CHECK(filled(r, 40, 50));
        CHECK(filled(r, 40, 46));
        CHECK(empty(r, 40, 42));
        CHECK(empty(r, 17, 50));       // butt cap: nothing before the start
        CHECK(filled(r, 64, 54));      // miter join: the outer corner is square
        CHECK(empty(r, 60, 14));       // butt cap at the end
        CHECK(filled(r, 60, 22));
    }
    {
        const Run r = run(p, "vector.stroke_to_path", line, {{"elements", "l"}, {"cap", "round"}, {"join", "round"}});
        CHECK(filled(r, 17, 50));      // round cap: 5 units past the start
        CHECK(empty(r, 14, 50));
        CHECK(empty(r, 64, 54));       // round join: the corner is cut
        CHECK(filled(r, 60, 17));
        CHECK(contains(r.svg, " C"));
    }
    {
        const Run r = run(p, "vector.stroke_to_path", line, {{"elements", "l"}, {"cap", "square"}});
        CHECK(filled(r, 17, 50));
        CHECK(filled(r, 20 - 4, 52));  // the square cap reaches 5 units out and is as wide as the line
    }
    {
        const std::string dashed = svg_of("<path id=\"d\" d=\"M0 50 H100\" fill=\"none\" stroke=\"#000\" stroke-width=\"10\" stroke-dasharray=\"20 20\"/>");
        const Run r = run(p, "vector.stroke_to_path", dashed, {{"elements", "d"}});
        CHECK(filled(r, 10, 50));
        CHECK(empty(r, 30, 50));
        CHECK(filled(r, 50, 50));
        CHECK(empty(r, 70, 50));
        CHECK(filled(r, 90, 50));
        const Run solid = run(p, "vector.stroke_to_path", dashed, {{"elements", "d"}, {"dashes", Json::array()}});
        CHECK(filled(solid, 30, 50));
        const Run own = run(p, "vector.stroke_to_path", dashed, {{"elements", "d"}, {"dashes", Json::array({10, 10})}, {"dashOffset", 10}, {"width", 4}});
        CHECK(empty(own, 5, 50));
        CHECK(filled(own, 15, 50));
        CHECK(empty(own, 15, 45));  // 4 wide now
    }
    {
        // a filled shape keeps its fill; the stroke becomes a second path, after it
        const std::string both = svg_of("<rect id=\"r\" x=\"30\" y=\"30\" width=\"40\" height=\"40\" fill=\"#fc0\" stroke=\"#303\" stroke-width=\"8\"/>");
        const Run r = run(p, "vector.stroke_to_path", both, {{"elements", "r"}});
        CHECK(contains(r.svg, "<rect id=\"r\""));
        CHECK(contains(r.svg, "id=\"r-stroke\""));
        CHECK(r.svg.find("id=\"r-stroke\"") > r.svg.find("id=\"r\""));
        CHECK(filled(r, 28, 50));   // the outline reaches 4 units out
        CHECK(empty(r, 24, 50));
    }
    {
        // the stroke width is in the shape's own space: scaled by 2 it is 20 wide in the drawing
        const std::string scaled = svg_of("<path id=\"s\" d=\"M10 25 H40\" fill=\"none\" stroke=\"#000\" stroke-width=\"10\" transform=\"scale(2)\"/>");
        const Run r = run(p, "vector.stroke_to_path", scaled, {{"elements", "s"}});
        CHECK(contains(r.svg, "transform=\"scale(2)\""));
        CHECK(filled(r, 40, 50 - 9));
        CHECK(empty(r, 40, 50 - 12));
        CHECK(empty(r, 15, 50));
    }
    {
        CommandResult noStroke = p.call("vector.stroke_to_path", Json{{"svg", svg_of("<rect id=\"n\" width=\"10\" height=\"10\" fill=\"red\"/>")}, {"elements", "n"}});
        REQUIRE_FALSE(noStroke.ok);
        CHECK(error_of(noStroke).find("stroke") != std::string::npos);
        CommandResult badDash = p.call("vector.stroke_to_path", Json{{"svg", line}, {"elements", "l"}, {"dashes", Json::array({5, -1})}});
        REQUIRE_FALSE(badDash.ok);
        CHECK(error_of(badDash).find("/dashes/1") != std::string::npos);
    }
}

// ---- simplify and smooth -----------------------------------------------------------------------------------------------

TEST_CASE("vector.simplify: curves are refitted with fewer Beziers, straight runs lose their collinear vertices") {
    AssetsProject p;
    // a polygon of straight lines loses the vertices that lie within the tolerance of the line between their neighbours
    const std::string poly = svg_of("<path id=\"c\" d=\"" + polygon_circle(50, 50, 40, 96) + "\" fill=\"#36c\"/>");
    const Run r = run(p, "vector.simplify", poly, {{"tolerance", 0.3}});
    REQUIRE(r.r["results"].size() == 1);
    CHECK(r.r["results"][0]["nodesBefore"] == 96);
    CHECK(r.r["results"][0]["nodes"].get<int>() <= 40);
    CHECK_FALSE(contains(r.svg, " C"));
    CHECK(contains(r.svg, "fill=\"#36c\""));
    CHECK(filled(r, 50, 50));
    CHECK(filled(r, 50 + 38, 50));
    CHECK(empty(r, 50 + 43, 50));

    // a path of many Beziers is refitted with few
    std::string d = "M90 50";
    const int n = 16;
    const double k = 4.0 / 3.0 * std::tan(3.14159265358979 / (2 * n)), R = 40;
    for (int i = 0; i < n; ++i) {
        const double a0 = 2 * 3.14159265358979 * i / n, a1 = 2 * 3.14159265358979 * (i + 1) / n;
        d += std::format(" C{:.4f} {:.4f} {:.4f} {:.4f} {:.4f} {:.4f}", 50 + R * (std::cos(a0) - k * std::sin(a0)), 50 + R * (std::sin(a0) + k * std::cos(a0)),
                         50 + R * (std::cos(a1) + k * std::sin(a1)), 50 + R * (std::sin(a1) - k * std::cos(a1)), 50 + R * std::cos(a1), 50 + R * std::sin(a1));
    }
    const std::string many = svg_of("<path id=\"m\" d=\"" + d + " Z\" fill=\"#c36\"/>");
    const Run m = run(p, "vector.simplify", many, {{"tolerance", 0.3}});
    CHECK(m.r["results"][0]["nodesBefore"] == 16);
    CHECK(m.r["results"][0]["nodes"].get<int>() <= 8);
    CHECK(contains(m.svg, " C"));
    CHECK(filled(m, 50 + 38, 50));
    CHECK(empty(m, 50 + 42, 50));
    CHECK(filled(m, 50, 50 - 38));
    CHECK(empty(m, 50, 50 - 42));

    const std::string straight = svg_of("<path id=\"s\" d=\"M10 10 L20 10 L30 10 L40 10 L40 25 L40 40 L10 40 Z\" fill=\"#000\"/>");
    const Run s = run(p, "vector.simplify", straight, {{"elements", "s"}});
    CHECK(s.r["results"][0]["nodes"] == 4);
    CHECK_FALSE(contains(s.svg, " C"));
    CHECK(filled(s, 25, 25));

    // nothing to remove: the file is not rewritten and the shape stays a rect
    const std::string rect = svg_of("<rect id=\"r\" x=\"10\" y=\"10\" width=\"30\" height=\"30\"/>");
    const Run same = run(p, "vector.simplify", rect, {});
    CHECK(same.r["changed"] == false);
    CHECK(same.r["unchanged"] == Json::array({"r"}));
    CHECK(same.svg == rect);
}

TEST_CASE("vector.smooth: rounded nodes become Beziers, sharp corners stay, 0 keeps the lines") {
    AssetsProject p;
    const std::string poly = svg_of("<path id=\"p\" d=\"" + polygon_circle(50, 50, 40, 24) + "\" fill=\"#c63\"/>");
    const Run r = run(p, "vector.smooth", poly, {{"elements", "p"}});
    CHECK(r.r["changed"] == true);
    CHECK(contains(r.svg, " C"));
    CHECK(contains(r.svg, "fill=\"#c63\""));
    CHECK(filled(r, 50 + 39, 50));
    CHECK(empty(r, 50 + 42, 50));

    const Run flat = run(p, "vector.smooth", poly, {{"elements", "p"}, {"smoothness", 0}});
    CHECK_FALSE(contains(flat.svg, " C"));

    // a square: all four corners turn 90 degrees, so it stays as it is
    const std::string square = svg_of("<path id=\"q\" d=\"M10 10 L90 10 L90 90 L10 90 Z\" fill=\"#000\"/>");
    const Run q = run(p, "vector.smooth", square, {});
    CHECK(q.r["changed"] == false);
    CHECK(q.svg == square);

    // a bent line keeps its sharp ends but a gentle bend is rounded
    const std::string bent = svg_of("<path id=\"b\" d=\"M10 80 L40 40 L60 36 L90 20\" fill=\"none\" stroke=\"#000\" stroke-width=\"2\"/>");
    const Run b = run(p, "vector.smooth", bent, {{"cornerAngle", 60}});
    CHECK(contains(b.svg, " C"));
    CHECK(contains(b.svg, "M10 80"));
    CHECK(contains(b.svg, "90 20"));
}

// ---- align, distribute, repeat ------------------------------------------------------------------------------------------

TEST_CASE("vector.align: to the selection, the canvas or a key; parent and own transforms are honoured; ids and styles stay") {
    AssetsProject p;
    const std::string svg = svg_of(
        "<g id=\"scaled\" transform=\"translate(10 10) scale(2)\"><rect id=\"a\" x=\"0\" y=\"0\" width=\"10\" height=\"10\" fill=\"red\"/>"
        "<rect id=\"b\" x=\"20\" y=\"5\" width=\"5\" height=\"5\" fill=\"green\"/></g>"
        "<rect id=\"c\" x=\"70\" y=\"60\" width=\"10\" height=\"10\" fill=\"blue\" stroke=\"#000\" stroke-width=\"4\"/>");
    check_bounds(bounds_of(p, svg, "b"), {50, 20, 10, 10});
    {
        const Run r = run(p, "vector.align", svg, {{"elements", Json::array({"a", "b", "c"})}, {"horizontal", "left"}, {"bounds", "geometry"}});
        CHECK(r.r["changed"] == true);
        check_bounds(bounds_of(p, r.svg, "a"), {10, 10, 20, 20});
        check_bounds(bounds_of(p, r.svg, "b"), {10, 20, 10, 10});
        check_bounds(bounds_of(p, r.svg, "c"), {10, 60, 10, 10});
        CHECK(contains(r.svg, "id=\"c\""));
        CHECK(contains(r.svg, "fill=\"blue\" stroke=\"#000\" stroke-width=\"4\""));
        CHECK(contains(r.svg, "<g id=\"scaled\" transform=\"translate(10 10) scale(2)\">"));  // the group is left alone
    }
    {
        // visual bounds include half of c's stroke, so its geometry ends up 2 units right of the others
        const Run r = run(p, "vector.align", svg, {{"elements", Json::array({"a", "c"})}, {"horizontal", "left"}});
        check_bounds(bounds_of(p, r.svg, "c"), {12, 60, 10, 10});
    }
    {
        const Run r = run(p, "vector.align", svg, {{"elements", Json::array({"a", "b", "c"})}, {"vertical", "bottom"}, {"to", "canvas"}, {"bounds", "geometry"}});
        check_bounds(bounds_of(p, r.svg, "a"), {10, 80, 20, 20});
        check_bounds(bounds_of(p, r.svg, "b"), {50, 90, 10, 10});
        check_bounds(bounds_of(p, r.svg, "c"), {70, 90, 10, 10});
    }
    {
        // the whole group moves as one piece
        const Run r = run(p, "vector.align", svg, {{"elements", Json::array({"scaled", "c"})}, {"horizontal", "right"}, {"to", "canvas"}, {"bounds", "geometry"}});
        check_bounds(bounds_of(p, r.svg, "b"), {90, 20, 10, 10});  // the group's right edge (60) goes to 100: everything in it moves 40
        check_bounds(bounds_of(p, r.svg, "c"), {90, 60, 10, 10});
    }
    {
        const Run r = run(p, "vector.align", svg, {{"elements", Json::array({"b", "c"})}, {"vertical", "middle"}, {"key", "c"}, {"bounds", "geometry"}});
        check_bounds(bounds_of(p, r.svg, "c"), {70, 60, 10, 10});
        check_bounds(bounds_of(p, r.svg, "b"), {50, 60, 10, 10});
    }
    {
        // a single element with no `to` goes to the canvas
        const Run r = run(p, "vector.align", svg, {{"elements", "c"}, {"horizontal", "center"}, {"vertical", "middle"}, {"bounds", "geometry"}});
        check_bounds(bounds_of(p, r.svg, "c"), {45, 45, 10, 10});
        CHECK(contains(r.svg, "transform=\"translate("));
    }
    {
        CommandResult nothing = p.call("vector.align", Json{{"svg", svg}, {"elements", Json::array({"a", "c"})}});
        REQUIRE_FALSE(nothing.ok);
        CHECK(error_of(nothing).find("horizontal") != std::string::npos);
        CommandResult badKey = p.call("vector.align", Json{{"svg", svg}, {"elements", Json::array({"a", "c"})}, {"horizontal", "left"}, {"key", "cc"}});
        REQUIRE_FALSE(badKey.ok);
        CHECK(error_of(badKey).find("Did you mean 'c'") != std::string::npos);
    }
}

TEST_CASE("vector.distribute: equal gaps or centres, a fixed spacing, either axis") {
    AssetsProject p;
    const std::string svg = svg_of(
        "<rect id=\"r1\" x=\"0\" y=\"0\" width=\"10\" height=\"10\"/>"
        "<rect id=\"r2\" x=\"20\" y=\"30\" width=\"20\" height=\"10\"/>"
        "<g transform=\"translate(60 0)\"><rect id=\"r3\" x=\"0\" y=\"60\" width=\"30\" height=\"10\"/></g>");
    {
        const Run r = run(p, "vector.distribute", svg, {{"elements", Json::array({"r1", "r2", "r3"})}, {"axis", "horizontal"}, {"bounds", "geometry"}});
        // span 0..90, widths 10+20+30 = 60, so both gaps are 15
        check_bounds(bounds_of(p, r.svg, "r1"), {0, 0, 10, 10});
        check_bounds(bounds_of(p, r.svg, "r2"), {25, 30, 20, 10});
        check_bounds(bounds_of(p, r.svg, "r3"), {60, 60, 30, 10});
    }
    {
        const Run r = run(p, "vector.distribute", svg, {{"elements", Json::array({"r3", "r1", "r2"})}, {"axis", "horizontal"}, {"by", "centers"}, {"bounds", "geometry"}});
        // centres 5, 30, 75 -> 5, 40, 75
        check_bounds(bounds_of(p, r.svg, "r2"), {30, 30, 20, 10});
    }
    {
        const Run r = run(p, "vector.distribute", svg, {{"elements", Json::array({"r1", "r2", "r3"})}, {"axis", "horizontal"}, {"spacing", 4}, {"bounds", "geometry"}});
        check_bounds(bounds_of(p, r.svg, "r1"), {0, 0, 10, 10});
        check_bounds(bounds_of(p, r.svg, "r2"), {14, 30, 20, 10});
        check_bounds(bounds_of(p, r.svg, "r3"), {38, 60, 30, 10});
    }
    {
        const Run r = run(p, "vector.distribute", svg, {{"elements", Json::array({"r1", "r2", "r3"})}, {"axis", "vertical"}, {"bounds", "geometry"}});
        // span 0..70, heights 30 -> gaps 20
        check_bounds(bounds_of(p, r.svg, "r2"), {20, 30, 20, 10});
    }
    CommandResult two = p.call("vector.distribute", Json{{"svg", svg}, {"elements", Json::array({"r1", "r2"})}, {"axis", "horizontal"}});
    REQUIRE_FALSE(two.ok);
    CHECK(error_of(two).find("three") != std::string::npos);
}

TEST_CASE("vector.repeat: grids and circles, copies get suffixed ids, the original stays") {
    AssetsProject p;
    const std::string svg = svg_of("<g id=\"cell\" transform=\"translate(5 5)\"><rect id=\"r\" x=\"0\" y=\"0\" width=\"10\" height=\"10\" fill=\"red\"/></g><circle id=\"dot\" cx=\"50\" cy=\"20\" r=\"5\"/>");
    {
        const Run r = run(p, "vector.repeat", svg, {{"element", "cell"}, {"mode", "grid"}, {"columns", 3}, {"rows", 2}, {"spacing", 2}});
        CHECK(r.r["count"] == 6);
        CHECK(r.r["copies"] == Json::array({"cell-2", "cell-3", "cell-4", "cell-5", "cell-6"}));
        CHECK(contains(r.svg, "id=\"r-2\""));  // ids inside a copied group follow
        CHECK(contains(r.svg, "<g id=\"cell\" transform=\"translate(5 5)\">"));
        check_bounds(bounds_of(p, r.svg, "r"), {5, 5, 10, 10});
        check_bounds(bounds_of(p, r.svg, "r-3"), {29, 5, 10, 10});
        check_bounds(bounds_of(p, r.svg, "r-5"), {17, 17, 10, 10});
        CHECK(filled(r, 34, 10));
    }
    {
        const Run r = run(p, "vector.repeat", svg, {{"element", "dot"}, {"mode", "radial"}, {"count", 4}, {"center", Json::array({50, 50})}});
        CHECK(r.r["copies"].size() == 3);
        check_bounds(bounds_of(p, r.svg, "dot-2"), {75, 45, 10, 10}, 0.1);
        check_bounds(bounds_of(p, r.svg, "dot-3"), {45, 75, 10, 10}, 0.1);
        check_bounds(bounds_of(p, r.svg, "dot-4"), {15, 45, 10, 10}, 0.1);
        CHECK(filled(r, 50, 20));
        CHECK(filled(r, 80, 50));
        CHECK(contains(r.svg, "<circle id=\"dot\" cx=\"50\" cy=\"20\" r=\"5\"/>"));
    }
    {
        const Run r = run(p, "vector.repeat", svg, {{"element", "dot"}, {"mode", "radial"}, {"count", 3}, {"radius", 20}, {"sweep", 180}});
        CHECK(r.r["copies"].size() == 2);
    }
    {
        CommandResult one = p.call("vector.repeat", Json{{"svg", svg}, {"element", "dot"}, {"mode", "grid"}});
        REQUIRE_FALSE(one.ok);
        CHECK(error_of(one).find("columns") != std::string::npos);
        CommandResult noCount = p.call("vector.repeat", Json{{"svg", svg}, {"element", "dot"}, {"mode", "radial"}});
        REQUIRE_FALSE(noCount.ok);
        CHECK(error_of(noCount).find("count") != std::string::npos);
        CommandResult many = p.call("vector.repeat", Json{{"svg", svg}, {"element", "dot"}, {"mode", "grid"}, {"columns", 100}, {"rows", 100}});
        REQUIRE_FALSE(many.ok);
    }
}

// ---- style ------------------------------------------------------------------------------------------------------------

TEST_CASE("vector.style: the guide's outline and palette, or values given in the call") {
    AssetsProject p;
    const std::string svg =
        "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" width=\"200\" height=\"200\">"
        "<defs><linearGradient id=\"g\"><stop offset=\"0\" stop-color=\"#fe0000\"/><stop offset=\"1\" stop-color=\"#0000fe\"/></linearGradient></defs>"
        "<rect id=\"a\" x=\"10\" y=\"10\" width=\"30\" height=\"30\" fill=\"#fd0201\"/>"
        "<path id=\"l\" d=\"M10 60 H90\" fill=\"none\" stroke=\"#e8e0d1\" stroke-width=\"3\"/>"
        "<circle id=\"c\" cx=\"70\" cy=\"30\" r=\"15\" fill=\"url(#g)\"/></svg>";
    {
        AssetsProject bare;  // no assets.json style yet
        CommandResult none = bare.call("vector.style", Json{{"svg", svg}});
        REQUIRE_FALSE(none.ok);
        CHECK(error_of(none).find("style") != std::string::npos);
        CommandResult needs = bare.call("vector.style", Json{{"svg", svg}, {"outline", true}});
        REQUIRE_FALSE(needs.ok);
        CHECK(error_of(needs).find("assets.json") != std::string::npos);
    }
    write_all(p.file("assets.json"),
              Json::object({{"format", "factoria.assets/1"},
                            {"style", Json::object({{"outline", Json::object({{"color", "#101018"}, {"width", 2}})},
                                                    {"palette", Json::array({"#101018", "#ff0000", "#0000ff", "#e8e0d0"})}})}})
                  .dump());
    const Run r = run(p, "vector.style", svg, {});
    CHECK(r.r["outlined"] == 2);  // the rect and the circle; the line has no fill
    CHECK(r.r["outlineSkippedNoFill"] == 1);
    CHECK(contains(r.svg, "<rect id=\"a\" x=\"10\" y=\"10\" width=\"30\" height=\"30\" fill=\"#ff0000\" stroke=\"#101018\" stroke-width=\"1\"/>"));  // 2 px of a 200 px picture = 1 unit
    CHECK(contains(r.svg, "stroke=\"#e8e0d0\" stroke-width=\"3\""));
    CHECK(contains(r.svg, "stop-color=\"#ff0000\""));
    CHECK(contains(r.svg, "stop-color=\"#0000ff\""));
    CHECK(contains(r.svg, "fill=\"url(#g)\""));  // a gradient reference is not a colour
    CHECK(r.r["guide"]["palette"] == 4);

    const Run onlyPalette = run(p, "vector.style", svg, {{"outline", false}});
    CHECK_FALSE(contains(onlyPalette.svg, "stroke=\"#101018\""));
    CHECK(contains(onlyPalette.svg, "fill=\"#ff0000\""));

    const Run own = run(p, "vector.style", svg, {{"outline", Json{{"width", 4}, {"color", "#fff"}}}, {"palette", false}, {"elements", "a"}});
    CHECK(contains(own.svg, "stroke=\"#fff\" stroke-width=\"2\""));
    CHECK(contains(own.svg, "fill=\"#fd0201\""));  // not touched
    CHECK(contains(own.svg, "<circle id=\"c\" cx=\"70\" cy=\"30\" r=\"15\" fill=\"url(#g)\"/>"));

    const Run pal = run(p, "vector.style", svg, {{"outline", false}, {"palette", Json::array({"#000000", "#ffffff"})}});
    CHECK(contains(pal.svg, "fill=\"#000000\""));
    CHECK(contains(pal.svg, "stroke=\"#ffffff\""));

    CommandResult badColour = p.call("vector.style", Json{{"svg", svg}, {"palette", Json::array({"#12"})}});
    REQUIRE_FALSE(badColour.ok);
    CHECK(error_of(badColour).find("/palette/0") != std::string::npos);
}

// ---- files, documents and the shared behaviour ---------------------------------------------------------------------------

TEST_CASE("vector.*: source files, out, overwrite, dryRun and arguments") {
    AssetsProject p;
    const std::string svg = svg_of("<rect id=\"a\" x=\"10\" y=\"10\" width=\"30\" height=\"30\"/><rect id=\"b\" x=\"30\" y=\"30\" width=\"30\" height=\"30\"/>");
    write_all(p.file("assets/art/two.svg"), svg);
    const Json args = {{"source", "assets/art/two.svg"}, {"op", "union"}, {"elements", Json::array({"a", "b"})}, {"previewSize", 64}};

    Json dry = args;
    dry["dryRun"] = true;
    const Json d = p.ok("vector.boolean", dry);
    CHECK(d["dryRun"] == true);
    CHECK(d["changed"] == true);
    CHECK(d.contains("svg"));
    CHECK(d.contains("$image"));
    CHECK(read_all(p.file("assets/art/two.svg")) == svg);

    Json out = args;
    out["out"] = "assets/art/union.svg";
    const Json o = p.ok("vector.boolean", out);
    CHECK(o["written"] == "assets/art/union.svg");
    CHECK(read_all(p.file("assets/art/two.svg")) == svg);
    CHECK(contains(read_all(p.file("assets/art/union.svg")), "<path id=\"a\""));
    CommandResult again = p.call("vector.boolean", out);
    REQUIRE_FALSE(again.ok);
    CHECK(again.error["code"] == "exists");
    out["overwrite"] = true;
    CHECK(p.call("vector.boolean", out).ok);

    // in place, and the read-only listing changes nothing
    const Json inPlace = p.ok("vector.boolean", args);
    CHECK(inPlace["written"] == "assets/art/two.svg");
    CHECK(contains(read_all(p.file("assets/art/two.svg")), "<path id=\"a\""));
    const Json info = p.ok("vector.info", Json{{"source", "assets/art/two.svg"}});
    CHECK_FALSE(info.contains("changed"));
    CHECK(info["canvas"][2] == 100);

    // a failing call leaves the file as it was
    write_all(p.file("assets/art/keep.svg"), svg);
    CHECK_FALSE(p.call("vector.boolean", Json{{"source", "assets/art/keep.svg"}, {"op", "union"}, {"elements", Json::array({"a", "nope"})}}).ok);
    CHECK(read_all(p.file("assets/art/keep.svg")) == svg);

    // the arguments
    auto err = [&](Json a) {
        CommandResult r = p.call("vector.boolean", a);
        REQUIRE_FALSE(r.ok);
        return error_of(r);
    };
    CHECK(err({{"op", "union"}, {"elements", "a"}}).find("no SVG was given") != std::string::npos);
    CHECK(err({{"svg", svg}, {"source", "assets/art/two.svg"}, {"op", "union"}, {"elements", "a"}}).find("exactly one") != std::string::npos);
    CHECK(err({{"source", "assets/art/missing.svg"}, {"op", "union"}, {"elements", "a"}}).find("does not exist") != std::string::npos);
    CHECK(err({{"source", "assets/art/two.png"}, {"op", "union"}, {"elements", "a"}}).find(".svg") != std::string::npos);
    CHECK(err({{"svg", svg}, {"op", "union"}, {"elements", "a"}, {"tolerence", 1}}).find("tolerance") != std::string::npos);
    CHECK(err({{"svg", svg}, {"op", "union"}, {"elements", "a"}, {"layer", "x"}}).find("`layer` only goes with `document`") != std::string::npos);
    CHECK(err({{"svg", "<svg><rect id=\"a\"></svg>"}, {"op", "union"}, {"elements", "a"}}).find("line 1") != std::string::npos);
    CHECK(err({{"svg", "<html></html>"}, {"op", "union"}, {"elements", "a"}}).find("svg") != std::string::npos);
    CHECK(err({{"svg", svg}, {"op", "union"}, {"elements", "a, b"}, {"tolerance", 1e9}}).find("tolerance") != std::string::npos);
    CHECK(err({{"svg", svg}, {"op", "union"}, {"elements", Json::array({"a", "b"})}, {"out", "../x.svg"}}).size() > 0);
}

TEST_CASE("vector.*: the round trip keeps comments, whitespace, namespaces, CDATA and untouched attributes byte for byte") {
    AssetsProject p;
    const std::string svg =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"\n"
        "     viewBox=\"0 0 100 100\" width=\"100\" height=\"100\">\n  <!-- the art -->\n  <style><![CDATA[ .x { fill: red; } ]]></style>\n"
        "  <defs>\n    <linearGradient id=\"g\"><stop offset=\"0\" stop-color=\"#fff\"/></linearGradient>\n  </defs>\n"
        "  <g id=\"grp\" data-note=\"a &amp; b\">\n    <rect   id='a'  x=\"10\" y=\"10\" width=\"20\" height=\"20\" fill=\"url(#g)\" />\n"
        "    <rect id=\"b\" x=\"60\" y=\"50\" width=\"20\" height=\"20\"/>\n  </g>\n</svg>\n";
    const Run r = run(p, "vector.align", svg, {{"elements", Json::array({"a", "b"})}, {"horizontal", "left"}, {"bounds", "geometry"}});
    REQUIRE(r.r["changed"] == true);
    // only b changed: its start tag got one attribute, nothing else moved
    std::string expect = svg;
    const std::string from = "<rect id=\"b\" x=\"60\" y=\"50\" width=\"20\" height=\"20\"/>";
    const std::size_t at = expect.find(from);
    REQUIRE(at != std::string::npos);
    expect.replace(at, from.size(), "<rect id=\"b\" x=\"60\" y=\"50\" width=\"20\" height=\"20\" transform=\"translate(-50 0)\"/>");
    CHECK(r.svg == expect);
    // the CSS rule in <style> is something the commands cannot follow
    CHECK(has_warning(r.r, "<style>"));
}

TEST_CASE("vector.*: an svg layer of an image document, inline or from a source file") {
    AssetsProject p;
    const std::string svg = svg_of("<circle id=\"disc\" cx=\"50\" cy=\"50\" r=\"40\" fill=\"#ff0000\"/><rect id=\"hole\" x=\"40\" y=\"40\" width=\"20\" height=\"20\"/>");
    write_all(p.file("assets/art/badge.svg"), svg);
    p.ok("image.create", Json{{"path", "assets/art/hero.image.json"},
                              {"width", 100},
                              {"height", 100},
                              {"layers", Json::array({Json{{"kind", "fill"}, {"name", "bg"}, {"color", "#ffffff"}},
                                                      Json{{"kind", "svg"}, {"name", "inline"}, {"svg", svg}, {"width", 100}, {"height", 100}},
                                                      Json{{"kind", "svg"}, {"name", "file"}, {"source", "assets/art/badge.svg"}, {"width", 100}, {"height", 100}, {"visible", false}}})}});
    // two svg layers: `layer` is needed
    CommandResult amb = p.call("vector.boolean", Json{{"document", "assets/art/hero.image.json"}, {"op", "subtract"}, {"elements", Json::array({"disc", "hole"})}});
    REQUIRE_FALSE(amb.ok);
    CHECK(error_of(amb).find("svg layers") != std::string::npos);
    CHECK(error_of(amb).find("1, 2") != std::string::npos);

    const Json r = p.ok("vector.boolean", Json{{"document", "assets/art/hero.image.json"}, {"layer", "inline"}, {"op", "subtract"}, {"elements", Json::array({"disc", "hole"})}});
    CHECK(r["changed"] == true);
    CHECK(r.contains("$image"));
    const Json doc = parse_json(read_all(p.file("assets/art/hero.image.json")), "doc").value();
    CHECK(contains(doc["layers"][1]["svg"].get<std::string>(), "<path id=\"disc\""));
    CHECK(doc["layers"][1]["name"] == "inline");
    CHECK(contains(read_all(p.file("assets/art/badge.svg")), "<circle id=\"disc\""));  // the other layer's file is untouched
    const Image baked = read_png(p.file("assets/art/hero.png"));
    CHECK(get(baked, 50, 50) == Rgba{255, 255, 255, 255});  // the hole shows the background
    CHECK(get(baked, 25, 50) == Rgba{255, 0, 0, 255});

    // a layer with `source` rewrites the .svg file and leaves the document's JSON alone
    const std::string docBefore = read_all(p.file("assets/art/hero.image.json"));
    const Json s = p.ok("vector.offset", Json{{"document", "assets/art/hero.image.json"}, {"layer", "2"}, {"elements", "disc"}, {"distance", -10}});
    CHECK(s["changed"] == true);
    CHECK(contains(read_all(p.file("assets/art/badge.svg")), "<path id=\"disc\""));
    CHECK(read_all(p.file("assets/art/hero.image.json")) == docBefore);

    // dryRun changes nothing, a non-svg layer is explained
    const std::string fileBefore = read_all(p.file("assets/art/badge.svg"));
    const Json dry = p.ok("vector.offset", Json{{"document", "assets/art/hero.image.json"}, {"layer", 1}, {"elements", "disc"}, {"distance", -5}, {"dryRun", true}});
    CHECK(dry["dryRun"] == true);
    CHECK(read_all(p.file("assets/art/hero.image.json")) == docBefore);
    CHECK(read_all(p.file("assets/art/badge.svg")) == fileBefore);
    CommandResult notSvg = p.call("vector.info", Json{{"document", "assets/art/hero.image.json"}, {"layer", "bg"}});
    REQUIRE_FALSE(notSvg.ok);
    CHECK(error_of(notSvg).find("not an svg layer") != std::string::npos);
    CommandResult noDoc = p.call("vector.info", Json{{"document", "assets/art/none.image.json"}});
    CHECK_FALSE(noDoc.ok);
}

TEST_CASE("vector.info is read-only: its schema has no `out` (a write path) and the argument is refused") {
    AssetsProject p;
    const CommandInfo* info = p.registry.info("vector.info");
    REQUIRE(info != nullptr);
    CHECK(info->readOnly);
    CHECK_FALSE(info->inputSchema["properties"].contains("out"));
    CHECK(info->inputSchema.dump().find("\"x-fa-path\":\"write\"") == std::string::npos);
    CommandResult r = p.call("vector.info", Json{{"svg", svg_of("<rect width=\"4\" height=\"4\"/>")}, {"out", "assets/art/x.svg"}});
    CHECK_FALSE(r.ok);
    // A command that writes keeps it.
    const CommandInfo* add = p.registry.info("vector.add");
    REQUIRE(add != nullptr);
    CHECK(add->inputSchema["properties"].contains("out"));
}

TEST_CASE("vector.info: lists shapes with ids, bounds in the drawing space and node counts") {
    AssetsProject p;
    const std::string svg = svg_of("<g id=\"g\" transform=\"translate(10 20)\"><path id=\"p\" d=\"M0 0 C10 0 10 10 0 10 Z\" fill=\"#123\"/></g><rect x=\"1\" y=\"2\" width=\"3\" height=\"4\" class=\"k\"/>");
    const Json r = p.ok("vector.info", Json{{"svg", svg}, {"previewSize", 32}});
    CHECK(r["canvas"] == Json::array({0.0, 0.0, 100.0, 100.0}));
    bool sawPath = false;
    for (const Json& e : r["elements"])
        if (e.value("id", std::string()) == "p") {
            sawPath = true;
            CHECK(e["tag"] == "path");
            CHECK(e["nodes"] == 2);
            CHECK(e["curves"] == true);
            CHECK(e["fill"] == "#123");
            CHECK(e["bounds"][0].get<double>() == doctest::Approx(10));
            CHECK(e["bounds"][1].get<double>() == doctest::Approx(20));
        }
    CHECK(sawPath);
    CHECK_FALSE(r.contains("changed"));
    CHECK_FALSE(r.contains("svg"));
}

// ---- shape builders (docs/VECTOR.md, "Shapes") -------------------------------------------------------------------------

#include <algorithm>
#include <regex>

#include "fa/tooling/vector.h"

namespace {

// Every number of a path's `d`, in pairs: anchors and control points alike.
std::vector<std::pair<double, double>> pairs_of(const std::string& d) {
    std::vector<double> nums;
    static const std::regex num("-?[0-9]+(\\.[0-9]+)?(e-?[0-9]+)?");
    for (auto it = std::sregex_iterator(d.begin(), d.end(), num); it != std::sregex_iterator(); ++it) nums.push_back(std::stod(it->str()));
    std::vector<std::pair<double, double>> out;
    for (std::size_t i = 0; i + 1 < nums.size(); i += 2) out.push_back({nums[i], nums[i + 1]});
    return out;
}

// The anchors only (the end point of each M, L and C), which is where a curve actually passes.
std::vector<std::pair<double, double>> anchors_of(const std::string& d) {
    std::vector<std::pair<double, double>> out;
    std::size_t i = 0;
    while (i < d.size()) {
        const char ch = d[i];
        if (ch == 'M' || ch == 'L' || ch == 'C') {
            std::size_t j = i + 1;
            while (j < d.size() && d[j] != 'M' && d[j] != 'L' && d[j] != 'C' && d[j] != 'Z') ++j;
            const auto ps = pairs_of(d.substr(i + 1, j - i - 1));
            if (!ps.empty()) out.push_back(ps.back());
            i = j;
        } else {
            ++i;
        }
    }
    return out;
}

double radius_of(std::pair<double, double> p, double cx, double cy) { return std::hypot(p.first - cx, p.second - cy); }

// The d of the element with an id in a result svg.
std::string d_of(const std::string& svg, const std::string& id) {
    const std::size_t at = svg.find("id=\"" + id + "\"");
    REQUIRE(at != std::string::npos);
    const std::size_t d = svg.find(" d=\"", at);
    REQUIRE(d != std::string::npos);
    return svg.substr(d + 4, svg.find('"', d + 4) - d - 4);
}

}  // namespace

TEST_CASE("vector shapes: a star has its points at the outer radius and its valleys at the inner one") {
    VecStarSpec s;
    s.center = {50, 50};
    s.radius = 40;
    s.points = 7;
    s.innerRatio = 0.4;
    const auto a = anchors_of(vector_star_path(s));
    REQUIRE(a.size() == 14);
    for (std::size_t i = 0; i < a.size(); ++i) CHECK(radius_of(a[i], 50, 50) == doctest::Approx(i % 2 == 0 ? 40.0 : 16.0).epsilon(0.001));
    CHECK(a[0].first == doctest::Approx(50).epsilon(0.001));  // the first tip points up
    CHECK(a[0].second == doctest::Approx(10).epsilon(0.001));
    s.roundness = 1;
    const std::string round = vector_star_path(s);
    CHECK(contains(round, "C"));
    for (const auto& p : pairs_of(round)) CHECK(radius_of(p, 50, 50) <= 40.01);  // rounding only cuts the tips
}

TEST_CASE("vector shapes: a gear has its teeth around the rim and a hole in the middle") {
    VecGearSpec g;
    g.center = {50, 50};
    g.radius = 40;
    g.teeth = 9;
    g.depth = 0.25;
    g.hole = 0.3;
    const std::string d = vector_gear_path(g);
    CHECK(std::count(d.begin(), d.end(), 'M') == 2);  // the rim and the hole
    // the teeth: clusters of points on the outer half of the rim, by angle
    std::vector<double> angles;
    double maxR = 0;
    for (const auto& p : anchors_of(d)) {
        const double r = radius_of(p, 50, 50);
        maxR = std::max(maxR, r);
        if (r > 40 * (1 - 0.125) && r < 40 * 1.001) angles.push_back(std::atan2(p.second - 50, p.first - 50));
    }
    CHECK(maxR == doctest::Approx(40).epsilon(0.001));
    std::sort(angles.begin(), angles.end());
    REQUIRE(angles.size() == 18);  // two corners at the tip of each of the 9 teeth
    const double pitch = 2 * 3.14159265358979 / 9;
    for (std::size_t i = 0; i < angles.size(); i += 2) CHECK(angles[i + 1] - angles[i] == doctest::Approx(0.5 * pitch).epsilon(0.1));
    double minR = 1e9;
    for (const auto& p : anchors_of(d.substr(d.find('M', 1)))) minR = std::min(minR, radius_of(p, 50, 50));
    CHECK(minR == doctest::Approx(12).epsilon(0.01));  // the hole
}

TEST_CASE("vector shapes: a polygon has its corners on the circle and rounding keeps it inside") {
    VecPolygonSpec s;
    s.center = {50, 50};
    s.radius = 40;
    s.sides = 5;
    const auto a = anchors_of(vector_polygon_path(s));
    REQUIRE(a.size() == 5);
    for (const auto& p : a) CHECK(radius_of(p, 50, 50) == doctest::Approx(40).epsilon(0.001));
    s.cornerRadius = 8;
    const std::string d = vector_polygon_path(s);
    CHECK(anchors_of(d).size() == 11);  // the start, then a line and a fillet per corner (the last fillet ends at the start)
    for (const auto& p : pairs_of(d)) CHECK(radius_of(p, 50, 50) < 40.0);
    // a fillet of radius r on a corner of angle 108 degrees cuts the corner at tan(36deg) * r from it, on the sides
    const double cut = 8 / std::tan(108.0 / 2 * 3.14159265 / 180);
    CHECK(std::hypot(a[0].first - anchors_of(d)[0].first, a[0].second - anchors_of(d)[0].second) == doctest::Approx(cut).epsilon(0.02));
}

TEST_CASE("vector shapes: an arrow runs from the tail to the tip, and a curved one bends to the side asked for") {
    VecArrowSpec a;
    a.from = {10, 50};
    a.to = {90, 50};
    a.shaftWidth = 8;
    a.headLength = 20;
    a.headWidth = 24;
    const auto pts = anchors_of(vector_arrow_path(a));
    REQUIRE(pts.size() == 7);
    CHECK(std::any_of(pts.begin(), pts.end(), [](auto p) { return std::abs(p.first - 90) < 1e-6 && std::abs(p.second - 50) < 1e-6; }));
    double minX = 1e9, minY = 1e9, maxY = -1e9;
    for (const auto& p : pts) {
        minX = std::min(minX, p.first);
        minY = std::min(minY, p.second);
        maxY = std::max(maxY, p.second);
    }
    CHECK(minX == doctest::Approx(10));
    CHECK(minY == doctest::Approx(38));  // half the head width
    CHECK(maxY == doctest::Approx(62));
    a.curve = 0.2;  // positive = right of from -> to, which is DOWN on the screen for an arrow pointing right
    double midY = 0;
    for (const auto& p : pairs_of(vector_arrow_path(a))) midY = std::max(midY, p.second);
    CHECK(midY > 62.5);
}

TEST_CASE("vector shapes: a speech bubble's tail points at its target, which must lie outside the box") {
    VecBubbleSpec b;
    b.center = {50, 40};
    b.width = 70;
    b.height = 40;
    b.cornerRadius = 8;
    b.tailTo = {30, 80};
    b.tailRoundness = 0;
    const auto a = anchors_of(vector_bubble_path(b));
    CHECK(std::any_of(a.begin(), a.end(), [](auto p) { return std::abs(p.first - 30) < 0.01 && std::abs(p.second - 80) < 0.01; }));
    double minX = 1e9, maxX = -1e9, minY = 1e9, maxY = -1e9;
    for (const auto& p : pairs_of(vector_bubble_path(b))) {
        minX = std::min(minX, p.first);
        maxX = std::max(maxX, p.first);
        minY = std::min(minY, p.second);
        maxY = std::max(maxY, p.second);
    }
    CHECK(minX == doctest::Approx(15));
    CHECK(maxX == doctest::Approx(85));
    CHECK(minY == doctest::Approx(20));
    CHECK(maxY == doctest::Approx(80));
    AssetsProject p;
    const CommandResult inside = p.call("vector.shape", Json{{"svg", svg_of("")}, {"kind", "bubble"}, {"center", Json::array({50, 40})}, {"tailTo", Json::array({50, 40})}});
    REQUIRE_FALSE(inside.ok);
    CHECK(contains(error_of(inside), "inside the box"));
    const CommandResult wrong = p.call("vector.shape", Json{{"svg", svg_of("")}, {"kind", "star"}, {"teeth", 4}});
    REQUIRE_FALSE(wrong.ok);
    CHECK(contains(error_of(wrong), "gear"));
}

TEST_CASE("vector.shape: ids, parents, styles and a ribbon group, with the same bytes on a repeat") {
    AssetsProject p;
    const std::string svg = svg_of("<g id=\"layer\" transform=\"translate(10 0)\"><rect id=\"bg\" width=\"10\" height=\"10\"/></g>");
    const Run r = run(p, "vector.shape", svg, {{"kind", "star"}, {"id", "s1"}, {"parent", "layer"}, {"center", Json::array({20, 50})}, {"radius", 15}, {"fill", "#ff0000"}, {"opacity", 0.5}});
    CHECK(r.r["element"] == "s1");
    CHECK(contains(r.svg, "fill=\"#ff0000\""));
    CHECK(contains(r.svg, "opacity=\"0.5\""));
    CHECK(r.svg.find("id=\"s1\"") < r.svg.find("</g>"));  // inside the group
    check_bounds(bounds_of(p, r.svg, "s1"), {30 - 15 * 0.951057, 50 - 15, 2 * 15 * 0.951057, 15 + 15 * 0.809017}, 0.05);  // the group moves it by 10
    CHECK(get(r.img, 30, 50).a > 100);  // half opaque
    CHECK(empty(r, 5, 50));
    const CommandResult dup = p.call("vector.shape", Json{{"svg", r.svg}, {"kind", "star"}, {"id", "s1"}});
    REQUIRE_FALSE(dup.ok);
    CHECK(contains(error_of(dup), "s1"));
    const Run rib = run(p, "vector.shape", svg_of(""), {{"kind", "ribbon"}, {"fill", "#c62e36"}});
    CHECK(rib.r["parts"].size() == 5);
    CHECK(filled(rib, 50, 50));
    CHECK(run(p, "vector.shape", svg_of(""), {{"kind", "ribbon"}, {"fill", "#c62e36"}}).svg == rib.svg);
}

TEST_CASE("vector.blob: through passes through the points, around stays inside their polygon, open curves get a stroke") {
    AssetsProject p;
    const Json pts = Json::array({Json::array({20, 50}), Json::array({50, 20}), Json::array({80, 50}), Json::array({50, 80})});
    const Run through = run(p, "vector.blob", svg_of(""), {{"points", pts}, {"id", "b"}});
    const auto a = anchors_of(d_of(through.svg, "b"));
    for (const Json& pt : pts)
        CHECK(std::any_of(a.begin(), a.end(), [&](auto q) { return std::hypot(q.first - pt[0].get<double>(), q.second - pt[1].get<double>()) < 0.05; }));
    CHECK(filled(through, 50, 50));
    const Run around = run(p, "vector.blob", svg_of(""), {{"points", pts}, {"id", "b"}, {"fit", "around"}});
    // the diamond's inscribed curve: no point of it reaches the corners of the control polygon
    for (const auto& q : anchors_of(d_of(around.svg, "b"))) CHECK(std::abs(q.first - 50) + std::abs(q.second - 50) < 30.0);
    CHECK(filled(around, 50, 50));
    CHECK(empty(around, 22, 22));
    const Run open = run(p, "vector.blob", svg_of(""), {{"points", Json::array({Json::array({10, 80}), Json::array({50, 20}), Json::array({90, 80})})}, {"closed", false}, {"id", "c"}});
    CHECK(contains(open.svg, "stroke="));
    CHECK(contains(open.svg, "fill=\"none\""));
    CHECK_FALSE(contains(d_of(open.svg, "c"), "Z"));
    CHECK_FALSE(p.call("vector.blob", Json{{"svg", svg_of("")}, {"points", Json::array({Json::array({1, 1}), Json::array({2, 2})})}}).ok);
}

TEST_CASE("vector.mirror: the weld unions the shape with its reflection, the copy keeps the original") {
    AssetsProject p;
    const std::string half = svg_of("<path id=\"half\" d=\"M50 10 L80 30 L70 90 L50 90 Z\" fill=\"#333\"/>");
    const Run w = run(p, "vector.mirror", half, {{"elements", "half"}, {"axis", "vertical"}, {"at", 50}});
    CHECK(w.r["changed"] == true);
    check_bounds(bounds_of(p, w.svg, "half"), {20, 10, 60, 80}, 0.1);
    for (int y = 0; y < 100; y += 7)
        for (int x = 0; x < 50; x += 3)
            if (std::abs(x - 50) > 1.5) CHECK_MESSAGE(filled(w, x, y) == filled(w, 99 - x, y), "x " << x << " y " << y);
    CHECK(filled(w, 50, 50));
    CHECK(std::count(w.svg.begin(), w.svg.end(), 'M') == 1);  // one outline, no seam
    const Run c = run(p, "vector.mirror", half, {{"elements", "half"}, {"axis", "vertical"}, {"weld", false}});
    CHECK(contains(c.svg, "id=\"half-mirror\""));
    CHECK(contains(c.svg, "id=\"half\""));
    check_bounds(bounds_of(p, c.svg, "half-mirror"), {20, 10, 30, 80}, 0.1);
    const Run h = run(p, "vector.mirror", half, {{"elements", "half"}, {"axis", "horizontal"}, {"at", "end"}});
    check_bounds(bounds_of(p, h.svg, "half"), {50, 10, 30, 160}, 0.1);
    CHECK_FALSE(p.call("vector.mirror", Json{{"svg", half}, {"elements", "half"}, {"axis", "diagonal"}}).ok);
}

TEST_CASE("vector.text_to_path: outlines with the engine's font, the advance grows with the text, existing <text> becomes a path") {
    AssetsProject p;
    double advI = 0, advII = 0;
    int glyphs = 0;
    const auto one = vector_text_path("i", "", 40, {10, 60}, "start", 0, 3, &advI, &glyphs);
    REQUIRE(one.ok());
    CHECK_FALSE(one.value().empty());
    CHECK(glyphs == 1);
    const auto two = vector_text_path("ii", "", 40, {10, 60}, "start", 0, 3, &advII, &glyphs);
    REQUIRE(two.ok());
    CHECK(glyphs == 2);
    CHECK(advI > 5);
    CHECK(advII == doctest::Approx(2 * advI).epsilon(0.01));
    // an anchored text is placed by its middle
    const Run r = run(p, "vector.text_to_path", svg_of(""), {{"text", "HI"}, {"size", 50}, {"at", Json::array({50, 70})}, {"anchor", "middle"}, {"id", "t"}, {"fill", "#000"}});
    CHECK(r.r["glyphs"] == 2);
    CHECK(r.r["advance"].get<double>() > 30);
    const auto bb = bounds_of(p, r.svg, "t");
    CHECK(bb[0] + bb[2] / 2 == doctest::Approx(50).epsilon(0.08));
    CHECK(bb[1] + bb[3] <= 70.5);  // capitals sit on the baseline
    CHECK(bb[3] > 25);
    CHECK_FALSE(contains(r.svg, "<text"));
    const Run conv = run(p, "vector.text_to_path", svg_of("<text id=\"label\" x=\"10\" y=\"60\" font-size=\"30\" fill=\"#123456\">Go</text>"), {{"elements", "label"}});
    CHECK(conv.r["changed"] == true);
    CHECK(contains(conv.svg, "<path id=\"label\""));
    CHECK(contains(conv.svg, "#123456"));
    CHECK_FALSE(contains(conv.svg, "<text"));
    CHECK_FALSE(p.call("vector.text_to_path", Json{{"svg", svg_of("")}}).ok);
}

TEST_CASE("vector.shade: the shadow lands on the side away from the light, the highlight on the light's side, both inside the shape") {
    AssetsProject p;
    const std::string svg = svg_of("<circle id=\"orb\" cx=\"50\" cy=\"50\" r=\"40\" fill=\"#cc3333\"/>");
    const Run r = run(p, "vector.shade", svg, {{"elements", "orb"}, {"light", "upper-left"}, {"depth", 10}});
    CHECK(r.r["changed"] == true);
    CHECK(contains(r.svg, "id=\"orb-shadow\""));
    CHECK(contains(r.svg, "id=\"orb-highlight\""));
    const Rgba base = get(r.img, 50, 50);
    const Rgba shade = get(r.img, 78, 78);  // lower right, near the rim
    const Rgba light = get(r.img, 22, 22);  // upper left
    CHECK(shade.r < base.r);
    CHECK(light.r > base.r);
    CHECK(empty(r, 5, 5));  // nothing leaks outside the disc
    CHECK(empty(r, 95, 95));
    CHECK(empty(r, 5, 95));
    // the other way round with the light from the lower right (315 degrees counter-clockwise from +x with y up)
    const Run flip = run(p, "vector.shade", svg, {{"elements", "orb"}, {"light", 315}, {"depth", 10}});
    CHECK(get(flip.img, 78, 78).r > get(flip.img, 50, 50).r);
    CHECK(get(flip.img, 22, 22).r < get(flip.img, 50, 50).r);
    // explicit colours
    const Run c = run(p, "vector.shade", svg, {{"elements", "orb"}, {"shadowColour", "#000080"}, {"highlight", false}});
    CHECK(contains(c.svg, "#000080"));
    CHECK_FALSE(contains(c.svg, "orb-highlight"));
    const CommandResult bad = p.call("vector.shade", Json{{"svg", svg}, {"elements", "orb"}, {"light", "upper-lef"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(contains(error_of(bad), "upper-left"));
}

TEST_CASE("vector.shade: the light direction defaults to the style guide's and the palette ramps colour the bands") {
    AssetsProject p;
    write_all(p.file("assets.json"), R"({"style":{"lightDirection":315,"palette":["#202020","#808080","#e0e0e0"]}})");
    const std::string svg = svg_of("<circle id=\"orb\" cx=\"50\" cy=\"50\" r=\"40\" fill=\"#808080\"/>");
    const Run r = run(p, "vector.shade", svg, {{"elements", "orb"}, {"depth", 10}});
    CHECK(r.r["light"]["from"] == "style");
    CHECK(get(r.img, 22, 22).r < get(r.img, 50, 50).r);  // the style's light is lower right: the upper left is the shade
    CHECK(get(r.img, 78, 78).r > get(r.img, 50, 50).r);
}
