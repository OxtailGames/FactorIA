// Editing SVG by hand (docs/VECTOR.md, "Editing by hand"): the node model of fa/tooling/vector_edit.h (parse, edit, write back), the
// scene and its hit tests, and the vector.* commands the Vector panel runs for each gesture (add, nodes, set_path, set, transform, delete,
// duplicate, group, ungroup, reorder, assign_ids, shape with replace). Ids, groups and transforms must survive every edit.
#include <doctest.h>

#include <cmath>
#include <filesystem>
#include <format>

#include "asset_test_helpers.h"
#include "fa/tooling/vector_edit.h"

using namespace fa;
using namespace fa::testing;

namespace {

constexpr const char* kHead =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" width=\"100\" height=\"100\">";
std::string svg_of(const std::string& body) { return std::string(kHead) + body + "</svg>"; }
bool has(const std::string& text, const std::string& needle) { return text.find(needle) != std::string::npos; }
std::string error_of(const CommandResult& r) {
    return r.error["message"].get<std::string>() + " " + r.error.value("hint", std::string());
}

// A command on SVG text; the edited text comes back in "svg".
Json edit(const AssetsProject& p, const std::string& cmd, const std::string& svg, Json args) {
    args["svg"] = svg;
    args["dryRun"] = true;
    args["preview"] = false;
    return p.ok(cmd, args);
}

VecNodePath nodes_of(const std::string& d) {
    auto r = vector_nodes_from_d(d);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().message));
    return r.value();
}

bool near(VecPoint a, double x, double y, double tol = 1e-6) {
    return std::abs(a.x - x) < tol && std::abs(a.y - y) < tol;
}

}  // namespace

TEST_CASE("vector nodes: path data round trip") {
    VecNodePath p = nodes_of("M10 10 L50 10 C60 10 70 20 70 30 L10 30 Z");
    REQUIRE(p.size() == 1);
    CHECK(p[0].closed);
    CHECK(p[0].nodes.size() == 4);
    CHECK(vector_node_count(p) == 4);
    CHECK(vector_segment_count(p[0]) == 4);
    CHECK(vector_segment_is_curve(p[0], 1));
    CHECK_FALSE(vector_segment_is_curve(p[0], 0));
    // a last node on the first one is the same node as the closing segment
    VecNodePath q = nodes_of("M0 0 L10 0 L10 10 L0 0 Z");
    CHECK(q[0].nodes.size() == 3);
    // quadratics and arcs become cubics; relative commands become absolute
    VecNodePath r = nodes_of("m10 10 q 10 -10 20 0 a 10 10 0 0 1 20 0");
    CHECK(vector_node_count(r) >= 3);
    CHECK(has(vector_nodes_to_d(r), "C"));
    CHECK(vector_nodes_to_d(nodes_of("M10 10 L50 10 L50 50 Z")) == "M10 10 L50 10 L50 50 Z");
    auto bad = vector_nodes_from_d("M10 10 L oops");
    CHECK_FALSE(bad.ok());
    CHECK_FALSE(bad.error().hint.empty());
}

TEST_CASE("vector nodes: move, handles and node kinds") {
    VecNodePath p = nodes_of("M0 0 C10 0 20 10 30 10 C40 10 50 0 60 0");
    CHECK(vector_node_kind(p[0].nodes[1]) ==
          VecNodeKind::Symmetric);  // both handles on one line, as long as each other
    REQUIRE(vector_node_move(p, 0, 1, {35, 20}).ok());
    CHECK(near(p[0].nodes[1].p, 35, 20));
    CHECK(near(p[0].nodes[1].in, 25, 20));  // the handles follow the anchor
    CHECK(near(p[0].nodes[1].out, 45, 20));
    REQUIRE(vector_node_move(p, 0, 1, {40, 20}, false).ok());
    CHECK(near(p[0].nodes[1].in, 25, 20));  // not this time
    REQUIRE(vector_node_convert(p, 0, 1, VecNodeKind::Smooth).ok());
    CHECK(vector_node_kind(p[0].nodes[1]) == VecNodeKind::Smooth);
    REQUIRE(vector_node_convert(p, 0, 1, VecNodeKind::Symmetric).ok());
    CHECK(vector_node_kind(p[0].nodes[1]) == VecNodeKind::Symmetric);
    // a smooth node keeps the other handle on the line when one handle moves
    REQUIRE(vector_node_convert(p, 0, 1, VecNodeKind::Smooth).ok());
    REQUIRE(vector_handle_move(p, 0, 1, true, {50, 40}).ok());
    const VecNode& n = p[0].nodes[1];
    const double cross = (n.out.x - n.p.x) * (n.in.y - n.p.y) - (n.out.y - n.p.y) * (n.in.x - n.p.x);
    CHECK(std::abs(cross) < 1e-6);
    // corner: the handle moves alone
    REQUIRE(vector_node_convert(p, 0, 1, VecNodeKind::Corner).ok());
    CHECK_FALSE(p[0].nodes[1].hasIn);
    CHECK_FALSE(p[0].nodes[1].hasOut);
    // errors name the range
    auto e = vector_node_move(p, 0, 9, {0, 0});
    REQUIRE_FALSE(e.ok());
    CHECK(has(e.error().message, "9"));
    CHECK_FALSE(e.error().hint.empty());
}

TEST_CASE("vector nodes: insert keeps the curve, delete keeps the shape, break and join") {
    VecNodePath p = nodes_of("M0 0 C0 20 40 20 40 0");
    const VecPoint mid = vector_segment_point(p[0], 0, 0.5);
    auto at = vector_node_insert(p, 0, 0, 0.5);
    REQUIRE(at.ok());
    CHECK(at.value() == 1);
    CHECK(p[0].nodes.size() == 3);
    CHECK(near(p[0].nodes[1].p, mid.x, mid.y, 1e-6));
    CHECK(vector_node_kind(p[0].nodes[1]) != VecNodeKind::Corner);
    REQUIRE(vector_node_delete(p, 0, 1, true).ok());
    CHECK(p[0].nodes.size() == 2);
    CHECK(near(vector_segment_point(p[0], 0, 0.5), mid.x, mid.y, 0.6));  // close to where it was
    // break a closed square, then join its ends again
    VecNodePath sq = nodes_of("M0 0 L10 0 L10 10 L0 10 Z");
    REQUIRE(vector_node_break(sq, 0, 2).ok());
    CHECK_FALSE(sq[0].closed);
    CHECK(vector_node_count(sq) == 5);
    REQUIRE(vector_node_break(sq, 0, 1).ok() == true);
    // an open path closes by joining its ends
    VecNodePath open = nodes_of("M0 0 L10 0 L10 10");
    REQUIRE(vector_nodes_join(open, 0, 0, 0, 2, false).ok());
    CHECK(open[0].closed);
    // append continues an open path; a drag makes the node smooth
    VecNodePath line = nodes_of("M0 0 L10 0");
    const VecPoint out{25, -5};
    REQUIRE(vector_node_append(line, 0, {20, 0}, &out).ok());
    CHECK(line[0].nodes.size() == 3);
    CHECK(near(line[0].nodes[2].out, 25, -5));
    CHECK(near(line[0].nodes[2].in, 15, 5));
    REQUIRE(vector_node_append(line, 1, {50, 50}).ok());  // a new subpath
    CHECK(line.size() == 2);
    // the last node of a path cannot be removed
    VecNodePath one = nodes_of("M0 0 L10 0");
    CHECK_FALSE(vector_node_delete(one, 0, 0).ok());
    VecNodePath two = nodes_of("M0 0 L10 0 M20 20 L30 30");
    REQUIRE(vector_node_delete(two, 0, 0).ok());
    CHECK(two.size() == 1);  // a subpath left with one node is gone
}

TEST_CASE("vector nodes: nearest point on a path") {
    VecNodePath p = nodes_of("M0 0 L10 0 L10 10");
    const VecNearest n = vector_nearest_on_path(p, {5, 2});
    CHECK(n.segment == 0);
    CHECK(std::abs(n.t - 0.5) < 1e-3);
    CHECK(std::abs(n.distance - 2) < 1e-3);
    CHECK(near(n.point, 5, 0, 1e-3));
}

TEST_CASE("vector nodes: the operations of vector.nodes") {
    VecNodePath p = nodes_of("M0 0 L10 0 L10 10 L0 10 Z");
    auto r = vector_nodes_apply(
        p,
        Json::parse(
            R"X([{"op":"move","node":1,"to":[20,0]},{"op":"insert","segment":1,"t":0.5},{"op":"convert","node":2,"to":"smooth"}])X"));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().message));
    CHECK(p[0].nodes.size() == 5);
    CHECK(near(p[0].nodes[1].p, 20, 0));
    auto bad = vector_nodes_apply(p, Json::parse(R"X([{"op":"move","node":1,"to":[1,1]},{"op":"mvoe","node":0}])X"));
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().message, "/ops/1"));
    CHECK(has(bad.error().hint, "move"));
}

TEST_CASE("vector scene: items, ids, bounds and hit tests") {
    const std::string svg = svg_of(
        R"X(<g id="a" transform="translate(10 10)"><rect id="r" x="0" y="0" width="30" height="20" fill="#f00"/><circle id="c" cx="60" cy="40" r="10" fill="none" stroke="#000" stroke-width="4"/></g><path d="M70 70 L90 70 L90 90 Z" data-locked="true"/>)X");
    auto sc = vector_scene(svg);
    REQUIRE_MESSAGE(sc.ok(), (sc.ok() ? std::string() : sc.error().message));
    const VecScene& s = sc.value();
    REQUIRE(s.items.size() == 4);
    CHECK(s.unnamed == 1);
    CHECK(s.items[0].isGroup);
    CHECK(s.items[1].parent == 0);
    CHECK(s.find("r") == 1);
    CHECK(s.find("nope") == -1);
    CHECK(s.items[3].locked);
    CHECK(s.items[3].id.empty());
    CHECK(s.find(s.items[3].ref) == 3);
    // bounds are in the drawing space: the group's translate is applied
    CHECK(near({s.items[1].bounds.x0, s.items[1].bounds.y0}, 10, 10));
    CHECK(near({s.items[1].bounds.x1, s.items[1].bounds.y1}, 40, 30));
    CHECK(s.items[0].hasBounds);
    CHECK(s.items[0].bounds.x1 >= 80);
    CHECK(vector_hit_test(s, {20, 20}, 0.5) == 1);
    CHECK(vector_hit_test(s, {80, 50}, 0.5) == 2);   // the ring of an unfilled circle: its stroke
    CHECK(vector_hit_test(s, {70, 50}, 0.5) == -1);  // its empty middle
    CHECK(vector_hit_test(s, {5, 90}, 0.5) == -1);
    CHECK(vector_hit_test(s, {85, 80}, 0.5, true) == -1);  // locked
    CHECK(vector_hit_test(s, {85, 85}, 0.5, false) == 3);
    // a click selects the group at the top level, the shape inside it
    CHECK(s.pick_in_context(1, -1) == 0);
    CHECK(s.pick_in_context(1, 0) == 1);
    const auto in = vector_shapes_in_rect(s, {0, 0, 45, 35}, false);
    REQUIRE(in.size() == 1);
    CHECK(in[0] == 1);
    CHECK(vector_shapes_in_rect(s, {0, 0, 45, 35}, true).size() >= 1);
    CHECK_FALSE(vector_scene("<svg><g></svg>").ok());
}

TEST_CASE("vector scene: rasterizing a region of the drawing") {
    const std::string svg = svg_of(R"X(<rect x="50" y="50" width="50" height="50" fill="#ff0000"/>)X");
    const VecRect region{50, 50, 100, 100};
    auto img = vector_rasterize(svg, &region, 25, 25);
    REQUIRE_MESSAGE(img.ok(), (img.ok() ? std::string() : img.error().message));
    CHECK(img.value().width == 25);
    const Image& im = img.value();
    CHECK(im.rgba[(12 * 25 + 12) * 4 + 0] > 200);
    CHECK(im.rgba[(12 * 25 + 12) * 4 + 3] > 200);
    auto whole = vector_rasterize(svg, nullptr, 20, 20);
    REQUIRE(whole.ok());
    CHECK(whole.value().rgba[(2 * 20 + 2) * 4 + 3] < 40);
    CHECK_FALSE(vector_rasterize(svg, nullptr, 0, 20).ok());
}

TEST_CASE("vector.add: native shapes and paths, in the drawing space") {
    AssetsProject p;
    const std::string base = svg_of(R"X(<g id="g" transform="translate(10 20)"></g>)X");
    Json r = edit(p, "vector.add", base,
                  Json{{"kind", "rect"},
                       {"x", 5},
                       {"y", 5},
                       {"width", 40},
                       {"height", 20},
                       {"cornerRadius", 3},
                       {"fill", "#d94f4f"},
                       {"id", "box"}});
    std::string svg = r["svg"];
    CHECK(has(svg, "<rect id=\"box\""));
    CHECK(has(svg, "rx=\"3\""));
    CHECK(has(svg, "<g id=\"g\" transform=\"translate(10 20)\">"));
    // inside a translated group the drawing-space numbers become the group's: the rect goes native only when nothing moves
    r = edit(
        p, "vector.add", base,
        Json{{"kind", "rect"}, {"x", 20}, {"y", 30}, {"width", 10}, {"height", 10}, {"parent", "g"}, {"id", "in"}});
    svg = r["svg"];
    CHECK(has(svg, "id=\"in\""));
    CHECK(r["bounds"][0].get<double>() == doctest::Approx(20));
    CHECK(r["bounds"][1].get<double>() == doctest::Approx(30));
    // local space: the numbers are the element's
    r = edit(p, "vector.add", base,
             Json{{"kind", "rect"},
                  {"x", 20},
                  {"y", 30},
                  {"width", 10},
                  {"height", 10},
                  {"parent", "g"},
                  {"space", "local"},
                  {"id", "in"}});
    CHECK(r["bounds"][0].get<double>() == doctest::Approx(30));
    CHECK(has(std::string(r["svg"]), "x=\"20\""));
    // a circle when the radii agree
    r = edit(p, "vector.add", base, Json{{"kind", "ellipse"}, {"center", Json::array({50, 50})}, {"rx", 10}});
    CHECK(has(std::string(r["svg"]), "<circle"));
    r = edit(p, "vector.add", base,
             Json{{"kind", "ellipse"}, {"center", Json::array({50, 50})}, {"rx", 10}, {"ry", 5}});
    CHECK(has(std::string(r["svg"]), "<ellipse"));
    r = edit(p, "vector.add", base,
             Json{{"kind", "line"}, {"from", Json::array({10, 10})}, {"to", Json::array({90, 40})}});
    CHECK(has(std::string(r["svg"]), "<line"));
    CHECK(has(std::string(r["svg"]), "stroke="));
    r = edit(p, "vector.add", base, Json{{"kind", "path"}, {"d", "M10 10 L90 10 L50 80 Z"}, {"id", "tri"}});
    CHECK(has(std::string(r["svg"]), "id=\"tri\""));
    // mistakes teach
    CommandResult bad = p.call("vector.add", Json{{"svg", base}, {"kind", "rect"}, {"x", 1}});
    REQUIRE_FALSE(bad.ok);
    CHECK(has(error_of(bad), "width"));
    bad = p.call("vector.add", Json{{"svg", base}, {"kind", "rectangle"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(has(error_of(bad), "rect"));
    bad = p.call("vector.add", Json{{"svg", base}, {"kind", "path"}, {"d", "M0 0"}, {"radius", 3}});
    REQUIRE_FALSE(bad.ok);
}

TEST_CASE("vector.nodes: edits a shape in its own space and keeps everything else") {
    AssetsProject p;
    const std::string base = svg_of(
        R"X(<g id="g" transform="translate(10 10)"><path id="p" d="M0 0 L40 0 L40 20 L0 20 Z" fill="#00f"/><rect id="r" x="0" y="30" width="20" height="10"/></g>)X");
    Json r = edit(p, "vector.nodes", base,
                  Json{{"element", "p"}, {"ops", Json::parse(R"X([{"op":"move","node":1,"to":[60,10]}])X")}});
    std::string svg = r["svg"];
    CHECK(has(svg, "d=\"M0 0 L50 0 L40 20 L0 20 Z\""));  // [60,10] in the drawing is [50,0] in the group
    CHECK(has(svg, "<g id=\"g\" transform=\"translate(10 10)\">"));
    CHECK(has(svg, "fill=\"#00f\""));
    CHECK(has(svg, "<rect id=\"r\""));
    CHECK(r["nodes"] == 4);
    // a rect becomes a path with the same outline
    r = edit(p, "vector.nodes", base,
             Json{{"element", "r"}, {"ops", Json::parse(R"X([{"op":"insert","segment":0,"t":0.5}])X")}});
    svg = r["svg"];
    CHECK(has(svg, "<path id=\"r\""));
    CHECK(r["nodes"] == 5);
    // an error is located in the op list
    CommandResult bad =
        p.call("vector.nodes",
               Json{{"svg", base}, {"element", "p"}, {"ops", Json::parse(R"X([{"op":"move","node":9,"to":[1,1]}])X")}});
    REQUIRE_FALSE(bad.ok);
    CHECK(has(error_of(bad), "/ops/0"));
    // a parametric shape stops being one
    const std::string par =
        svg_of(R"X(<path id="s" d="M0 0 L10 0 L10 10 Z" data-fa-shape="polygon" data-fa-args="{}"/>)X");
    r = edit(p, "vector.nodes", par,
             Json{{"element", "s"}, {"ops", Json::parse(R"X([{"op":"move","node":0,"to":[1,1]}])X")}});
    CHECK_FALSE(has(std::string(r["svg"]), "data-fa-shape"));
    CHECK_FALSE(has(std::string(r["svg"]), "data-fa-args"));
    // set_path replaces the data, in local or drawing space
    r = edit(p, "vector.set_path", base, Json{{"element", "p"}, {"d", "M0 0 L5 5"}});
    CHECK(has(std::string(r["svg"]), "d=\"M0 0 L5 5\""));
    r = edit(p, "vector.set_path", base, Json{{"element", "p"}, {"d", "M10 10 L15 15"}, {"space", "drawing"}});
    CHECK(has(std::string(r["svg"]), "d=\"M0 0 L5 5\""));
}

TEST_CASE("vector.set: style, visibility, lock and renaming that follows references") {
    AssetsProject p;
    const std::string base = svg_of(
        R"X(<defs><linearGradient id="grad"><stop offset="0" stop-color="#000"/><stop offset="1" stop-color="#fff"/></linearGradient></defs><rect id="r" width="50" height="50" fill="url(#grad)"/><use id="u" href="#r"/>)X");
    Json r = edit(p, "vector.set", base,
                  Json{{"elements", "r"},
                       {"fill", "#112233"},
                       {"stroke", "#fff"},
                       {"strokeWidth", 3},
                       {"opacity", 0.5},
                       {"hidden", true},
                       {"locked", true}});
    std::string svg = r["svg"];
    CHECK(has(svg, "#112233"));
    CHECK(has(svg, "display=\"none\""));
    CHECK(has(svg, "data-locked=\"true\""));
    r = edit(p, "vector.set", svg, Json{{"elements", "r"}, {"hidden", false}, {"locked", false}, {"stroke", nullptr}});
    svg = r["svg"];
    CHECK_FALSE(has(svg, "display"));
    CHECK_FALSE(has(svg, "data-locked"));
    CHECK_FALSE(has(svg, "stroke=\"#fff\""));
    // renaming updates the href that points at it; a gradient rename updates url(#...)
    r = edit(p, "vector.set", base, Json{{"elements", "r"}, {"id", "box"}});
    CHECK(has(std::string(r["svg"]), "href=\"#box\""));
    r = edit(p, "vector.set", base, Json{{"elements", "grad"}, {"id", "sky"}});
    (void)r;
    CommandResult bad = p.call("vector.set", Json{{"svg", base}, {"elements", "r"}, {"id", "u"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(has(error_of(bad), "u"));
    bad = p.call("vector.set", Json{{"svg", base}, {"elements", "r"}, {"fill", "reddish"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(has(error_of(bad), "/fill"));
    bad = p.call("vector.set", Json{{"svg", base}, {"elements", "r"}});
    REQUIRE_FALSE(bad.ok);
}

TEST_CASE("vector.transform: moves, scales and rotates in the drawing space") {
    AssetsProject p;
    const std::string base = svg_of(
        R"X(<g id="g" transform="translate(10 10)"><rect id="r" x="0" y="0" width="20" height="10"/></g><rect id="s" x="60" y="60" width="10" height="10"/>)X");
    Json r = edit(p, "vector.transform", base, Json{{"elements", "s"}, {"translate", Json::array({5, -5})}});
    CHECK(r["bounds"][0].get<double>() == doctest::Approx(65));
    CHECK(r["bounds"][1].get<double>() == doctest::Approx(55));
    CHECK(has(std::string(r["svg"]), "id=\"s\""));
    // a scale about the centre keeps the centre
    r = edit(p, "vector.transform", base, Json{{"elements", "s"}, {"scale", 2}});
    CHECK(r["bounds"][0].get<double>() == doctest::Approx(55));
    CHECK(r["bounds"][2].get<double>() == doctest::Approx(20));
    // an element inside a group: the drawing-space move is compensated
    r = edit(p, "vector.transform", base, Json{{"elements", "r"}, {"translate", Json::array({30, 0})}});
    CHECK(r["bounds"][0].get<double>() == doctest::Approx(40));
    // a group and a child of it: only the group moves
    r = edit(p, "vector.transform", base,
             Json{{"elements", Json::array({"g", "r"})}, {"translate", Json::array({10, 0})}});
    CHECK(r["elements"].size() == 1);
    CHECK(r["bounds"][0].get<double>() == doctest::Approx(20));
    // flip about the centre
    r = edit(p, "vector.transform", base,
             Json{{"elements", "s"}, {"flip", "horizontal"}, {"about", Json::array({50, 0})}});
    CHECK(r["bounds"][0].get<double>() == doctest::Approx(30));
    // a rotation by 90 swaps the sides
    r = edit(p, "vector.transform", base, Json{{"elements", "r"}, {"rotate", 90}});
    CHECK(r["bounds"][2].get<double>() == doctest::Approx(10));
    CHECK(r["bounds"][3].get<double>() == doctest::Approx(20));
    CommandResult bad = p.call("vector.transform", Json{{"svg", base}, {"elements", "r"}});
    REQUIRE_FALSE(bad.ok);
    bad = p.call("vector.transform", Json{{"svg", base}, {"elements", "r"}, {"scale", 0}});
    REQUIRE_FALSE(bad.ok);
}

TEST_CASE("vector.delete, duplicate, group and ungroup keep ids and looks") {
    AssetsProject p;
    const std::string base = svg_of(
        R"X(<g id="g" transform="translate(10 10)" fill="#0f0"><rect id="a" width="10" height="10"/><rect id="b" x="20" width="10" height="10" fill="#f00"/></g><circle id="c" cx="70" cy="70" r="5"/>)X");
    Json r = edit(p, "vector.delete", base, Json{{"elements", Json::array({"a", "c"})}});
    std::string svg = r["svg"];
    CHECK_FALSE(has(svg, "id=\"a\""));
    CHECK_FALSE(has(svg, "id=\"c\""));
    CHECK(has(svg, "id=\"b\""));
    CHECK(r["count"] == 2);
    r = edit(p, "vector.duplicate", base, Json{{"elements", "g"}, {"offset", Json::array({5, 5})}});
    svg = r["svg"];
    CHECK(has(svg, "id=\"g-copy\""));
    CHECK(has(svg, "id=\"a-copy\""));
    CHECK(has(svg, "id=\"b-copy\""));
    r = edit(p, "vector.duplicate", svg, Json{{"elements", "a"}});
    CHECK(has(std::string(r["svg"]), "id=\"a-copy-2\""));
    // group two shapes of the same parent
    r = edit(p, "vector.group", base, Json{{"elements", Json::array({"a", "b"})}, {"id", "pair"}});
    svg = r["svg"];
    CHECK(has(svg, "<g id=\"pair\">"));
    CHECK(has(svg, "id=\"a\""));
    CommandResult bad = p.call("vector.group", Json{{"svg", base}, {"elements", Json::array({"a", "c"})}});
    REQUIRE_FALSE(bad.ok);
    CHECK(has(error_of(bad), "different groups"));
    // ungroup: the transform and the fill the group set go to the children
    r = edit(p, "vector.ungroup", base, Json{{"elements", "g"}});
    svg = r["svg"];
    CHECK_FALSE(has(svg, "id=\"g\""));
    CHECK(has(svg, "id=\"a\""));
    CHECK(has(svg, "translate(10 10)"));
    CHECK(has(svg, "fill=\"#0f0\""));
    CHECK(has(svg, "fill=\"#f00\""));
    bad = p.call("vector.ungroup", Json{{"svg", base}, {"elements", "a"}});
    REQUIRE_FALSE(bad.ok);
    bad = p.call("vector.ungroup",
                 Json{{"svg", svg_of(R"X(<g id="m" clip-path="url(#x)"><rect id="a" width="1" height="1"/></g>)X")},
                      {"elements", "m"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(has(error_of(bad), "clip-path"));
}

TEST_CASE("vector.reorder: z order and regrouping keep the look") {
    AssetsProject p;
    const std::string base = svg_of(
        R"X(<rect id="a" width="10" height="10"/><rect id="b" width="10" height="10"/><rect id="c" width="10" height="10"/><g id="g" transform="translate(30 0)"></g>)X");
    auto order = [](const std::string& svg) {
        std::string out;
        for (const char* id : {"a", "b", "c"})
            out += (svg.find(std::string("id=\"") + id + "\"") < svg.size() ? std::string(1, id[0]) : "");
        return out;
    };
    (void)order;
    Json r = edit(p, "vector.reorder", base, Json{{"elements", "a"}, {"to", "front"}});
    std::string svg = r["svg"];
    CHECK(svg.find("id=\"a\"") > svg.find("id=\"c\""));
    r = edit(p, "vector.reorder", svg, Json{{"elements", "a"}, {"to", "back"}});
    CHECK(std::string(r["svg"]).find("id=\"a\"") < std::string(r["svg"]).find("id=\"b\""));
    r = edit(p, "vector.reorder", base, Json{{"elements", "b"}, {"to", "forward"}});
    svg = r["svg"];
    CHECK(svg.find("id=\"b\"") > svg.find("id=\"c\""));
    r = edit(p, "vector.reorder", base, Json{{"elements", "c"}, {"to", "backward"}});
    svg = r["svg"];
    CHECK(svg.find("id=\"c\"") < svg.find("id=\"b\""));
    // moved into a translated group, the rect stays where it was in the drawing
    r = edit(p, "vector.reorder", base, Json{{"elements", "a"}, {"parent", "g"}});
    svg = r["svg"];
    CHECK(has(svg, "translate(-30 0)"));
    CHECK(svg.find("id=\"a\"") > svg.find("id=\"g\""));
    // before: in front of an element
    r = edit(p, "vector.reorder", base, Json{{"elements", "c"}, {"before", "a"}});
    CHECK(std::string(r["svg"]).find("id=\"c\"") < std::string(r["svg"]).find("id=\"a\""));
    // a group cannot go inside itself
    CommandResult bad = p.call("vector.reorder", Json{{"svg", base}, {"elements", "g"}, {"parent", "g"}});
    REQUIRE_FALSE(bad.ok);
    bad = p.call("vector.reorder", Json{{"svg", base}, {"elements", "a"}});
    REQUIRE_FALSE(bad.ok);
}

TEST_CASE("vector.assign_ids names unnamed elements and tells which was which") {
    AssetsProject p;
    const std::string base = svg_of(
        R"X(<g><path d="M0 0 L10 0 L10 10 Z"/><path id="named" d="M0 0 L5 5"/></g><circle cx="5" cy="5" r="2"/>)X");
    Json r = edit(p, "vector.assign_ids", base, Json::object());
    CHECK(r["count"] == 3);
    const std::string svg = r["svg"];
    CHECK(has(svg, "id=\"g\""));
    CHECK(has(svg, "id=\"path\""));
    CHECK(has(svg, "id=\"circle\""));
    CHECK(has(svg, "id=\"named\""));
    REQUIRE(r["assigned"].size() == 3);
    CHECK(r["assigned"][0].contains("selector"));
    // after naming, nothing is left
    r = edit(p, "vector.assign_ids", svg, Json::object());
    CHECK(r["count"] == 0);
    // the scene refs of unnamed elements pick exactly them
    auto sc = vector_scene(base);
    REQUIRE(sc.ok());
    int unnamed = 0;
    for (const VecItem& it : sc.value().items)
        if (it.id.empty()) {
            ++unnamed;
            r = edit(p, "vector.set", base, Json{{"elements", it.ref}, {"fill", "#123456"}});
            CHECK(r["count"] == 1);
        }
    CHECK(unnamed == 3);
}

TEST_CASE("vector.shape: replace redraws an element, parametric keeps its arguments") {
    AssetsProject p;
    const std::string base =
        svg_of(R"X(<g transform="translate(10 0)"><path id="s" d="M0 0 L1 1" fill="#abc" stroke="#000"/></g>)X");
    Json r = edit(p, "vector.shape", base,
                  Json{{"kind", "star"},
                       {"replace", "s"},
                       {"center", Json::array({20, 20})},
                       {"radius", 10},
                       {"points", 6},
                       {"parametric", true}});
    std::string svg = r["svg"];
    CHECK(has(svg, "data-fa-shape=\"star\""));
    CHECK(has(svg, "data-fa-args="));
    CHECK(has(svg, "id=\"s\""));
    CHECK(has(svg, "fill=\"#abc\""));
    CHECK(has(svg, "translate(10 0)"));
    CHECK(r["nodes"] == 12);
    // again with another kind: the arguments change with it
    r = edit(p, "vector.shape", svg,
             Json{{"kind", "polygon"},
                  {"replace", "s"},
                  {"center", Json::array({20, 20})},
                  {"radius", 10},
                  {"sides", 5},
                  {"parametric", true}});
    CHECK(has(std::string(r["svg"]), "data-fa-shape=\"polygon\""));
    // without parametric the marks go
    r = edit(p, "vector.shape", svg,
             Json{{"kind", "polygon"}, {"replace", "s"}, {"center", Json::array({20, 20})}, {"radius", 10}});
    CHECK_FALSE(has(std::string(r["svg"]), "data-fa-shape"));
    // style and placement belong to the element
    CommandResult bad =
        p.call("vector.shape", Json{{"svg", base}, {"kind", "star"}, {"replace", "s"}, {"fill", "#f00"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(has(error_of(bad), "replace"));
    bad = p.call("vector.shape", Json{{"svg", base}, {"kind", "ribbon"}, {"replace", "s"}});
    REQUIRE_FALSE(bad.ok);
    // other commands that change the outline drop the marks
    r = edit(p, "vector.nodes", svg,
             Json{{"element", "s"}, {"ops", Json::parse(R"X([{"op":"move","node":0,"by":[1,1]}])X")}});
    CHECK_FALSE(has(std::string(r["svg"]), "data-fa-shape"));
}

TEST_CASE("vector edit commands: an svg layer of an image document and a file on disk") {
    AssetsProject p;
    std::filesystem::create_directories(p.file("assets"));
    write_all(p.file("assets/badge.svg"), svg_of(R"X(<rect id="r" width="50" height="50" fill="#f00"/>)X"));
    Json r = p.ok("vector.set",
                  Json{{"source", "assets/badge.svg"}, {"elements", "r"}, {"fill", "#00f"}, {"preview", false}});
    CHECK(r["changed"] == true);
    const std::string onDisk = read_all(p.file("assets/badge.svg"));
    CHECK(has(onDisk, "fill=\"#00f\""));
    CHECK(has(onDisk, "id=\"r\""));
    // dry run leaves the file alone
    r = p.ok("vector.delete",
             Json{{"source", "assets/badge.svg"}, {"elements", "r"}, {"dryRun", true}, {"preview", false}});
    CHECK(read_all(p.file("assets/badge.svg")) == onDisk);
    // preview:false skips the picture
    CHECK_FALSE(r.contains("$image"));
    r = p.ok("vector.add", Json{{"source", "assets/badge.svg"},
                                {"kind", "line"},
                                {"from", Json::array({0, 0})},
                                {"to", Json::array({9, 9})},
                                {"dryRun", true},
                                {"previewSize", 64}});
    CHECK(r.contains("$image"));
}
