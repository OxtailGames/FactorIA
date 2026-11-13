// The Vector panel's model (vector_model.h): every gesture is the vector.* command an AI would run, what the canvas shows while a handle
// is dragged is what the command writes at the end, every edit is one undo step, ids / groups / transforms survive, an svg layer of an
// image document is edited through the same code. No window: the model calls the real commands of a temporary project.
#include <algorithm>
#include <chrono>
#include <cmath>
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/asset_import.h"
#include "vector_model.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kHead =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" width=\"100\" height=\"100\">";
constexpr const char* kSvg = "assets/art/t.svg";
constexpr const char* kDoc = "assets/art/t.image.json";

std::string svg_of(const std::string& body) { return std::string(kHead) + body + "</svg>"; }
bool has(const std::string& text, const std::string& needle) { return text.find(needle) != std::string::npos; }

struct Project {
    stdfs::path dir;
    CommandRegistry registry;
    std::unique_ptr<VectorModel> model;
    Project() {
        dir = fs::make_temp_dir("fa_vector_panel").value();
        register_asset_commands(registry, dir.string());
        model = std::make_unique<VectorModel>(
            dir.string(), [this](const std::string& name, const Json& args) { return registry.call(name, args); });
    }
    ~Project() {
        model.reset();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    Json ok(const std::string& name, const Json& args) {
        CommandResult r = registry.call(name, args);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    }
    stdfs::path file(const std::string& rel) const { return dir / rel; }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories(file(rel).parent_path());
        std::ofstream out(file(rel), std::ios::binary);
        out << text;
    }
    std::string text(const std::string& rel) const {
        std::ifstream in(file(rel), std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }
    // Writes `body` as the drawing and opens it.
    void open_svg(const std::string& body) {
        write(kSvg, svg_of(body));
        REQUIRE_MESSAGE(model->open(kSvg), model->error());
    }
    const VecItem& item(const std::string& id) const {
        const int i = model->scene().find(id);
        REQUIRE_MESSAGE(i >= 0, "no element " << id);
        return model->scene().items[std::size_t(i)];
    }
};

constexpr const char* kTwoRects = "<rect id=\"a\" x=\"10\" y=\"10\" width=\"40\" height=\"40\" fill=\"#ff0000\"/><rect "
                                  "id=\"b\" x=\"30\" y=\"30\" width=\"40\" height=\"40\" fill=\"#0000ff\"/>";

}  // namespace

TEST_CASE("the pen: corners, a dragged curve, closing on the first node; one undo step that redoes the same path") {
    Project p;
    p.open_svg("");
    VectorModel& m = *p.model;
    REQUIRE(m.valid());
    m.style.useStroke = false;
    CHECK_FALSE(m.pen_press({10, 10}, 2));
    m.pen_release();
    CHECK_FALSE(m.pen_press({60, 10}, 2));
    m.pen_drag({80, 20});  // a curve node: the out handle follows, the in handle is its mirror image
    m.pen_release();
    CHECK_FALSE(m.pen_press({60, 60}, 2));
    m.pen_release();
    CHECK(m.pen().active);
    CHECK(m.pen().path[0].nodes[1].hasOut);
    CHECK(m.pen().path[0].nodes[1].in.x == doctest::Approx(40));
    CHECK(m.pen_press({11, 10.5}, 2));  // within reach of the first node: close
    const VectorEditOutcome out = m.pen_finish(true);
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(out.step > 0);
    CHECK_FALSE(m.pen().active);
    REQUIRE(m.scene().items.size() == 1);
    REQUIRE(m.selection().size() == 1);
    const VecItem& it = m.scene().items[0];
    CHECK(it.closed);
    CHECK(it.curves);
    CHECK(it.nodeCount == 3);
    CHECK_FALSE(it.id.empty());
    CHECK(has(p.text(kSvg), it.id));
    const std::string drawn = m.svg();

    REQUIRE(m.apply_step(out.step, false));
    CHECK(m.scene().items.empty());
    CHECK_FALSE(has(p.text(kSvg), "<path"));
    REQUIRE(m.apply_step(out.step, true));
    REQUIRE(m.scene().items.size() == 1);
    CHECK(m.svg() == drawn);
    CHECK(p.text(kSvg) == drawn);
}

TEST_CASE(
    "the pen: fewer than two nodes writes nothing; Escape drops the path; continuing an open path appends to it") {
    Project p;
    p.open_svg("<path id=\"line\" d=\"M10 10 L30 10\" fill=\"none\" stroke=\"#000000\" stroke-width=\"2\"/>");
    VectorModel& m = *p.model;
    m.pen_press({50, 50}, 2);
    m.pen_release();
    CHECK_FALSE(m.pen_can_finish());
    CHECK_FALSE(m.pen_finish(false).ok);  // a path needs two nodes
    CHECK_FALSE(m.pen().active);
    CHECK(m.step_count() == 0);
    CHECK(m.scene().items.size() == 1);

    m.pen_press({50, 50}, 2);
    m.pen_cancel();
    CHECK_FALSE(m.pen().active);

    // continue "line" from its end
    REQUIRE(m.pen_continue("line", 0, true));
    CHECK_FALSE(m.pen_can_finish());  // nothing added yet
    m.pen_press({50, 30}, 2);
    m.pen_release();
    CHECK(m.pen_can_finish());
    const VectorEditOutcome out = m.pen_finish(false);
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(p.item("line").nodeCount == 3);
    CHECK(p.item("line").nodes[0].nodes.back().p.x == doctest::Approx(50));
    CHECK(m.scene().items.size() == 1);  // still the same element

    // from its start: the new node comes first
    REQUIRE(m.pen_continue("line", 0, false));
    m.pen_press({10, 80}, 2);
    m.pen_release();
    REQUIRE(m.pen_finish(false).ok);
    CHECK(p.item("line").nodeCount == 4);
    const VecNodePath& np = p.item("line").nodes;
    CHECK(np[0].nodes.front().p.y == doctest::Approx(80));
    CHECK(np[0].nodes.back().p.y == doctest::Approx(30));
}

TEST_CASE("node edits: move, convert and delete are vector.nodes ops, each one undo step; a drag previews without "
          "touching the disk") {
    Project p;
    p.open_svg("<path id=\"tri\" d=\"M10 10 L50 10 L50 50 Z\" fill=\"#00ff00\"/>");
    VectorModel& m = *p.model;
    const std::string before = p.text(kSvg);

    // a live drag: the canvas changes, the file does not
    REQUIRE(m.preview_node_ops(
        "tri",
        Json::array({Json::object({{"op", "move"}, {"subpath", 0}, {"node", 1}, {"by", Json::array({10, 0})}})})));
    CHECK(m.previewing());
    CHECK(p.item("tri").nodes[0].nodes[1].p.x == doctest::Approx(60));
    CHECK(m.svg() != before);
    CHECK(p.text(kSvg) == before);
    m.cancel_preview();
    CHECK_FALSE(m.previewing());
    CHECK(p.item("tri").nodes[0].nodes[1].p.x == doctest::Approx(50));

    // ...and letting go keeps the last position as one step
    REQUIRE(m.preview_node_ops(
        "tri",
        Json::array({Json::object({{"op", "move"}, {"subpath", 0}, {"node", 1}, {"by", Json::array({15, 5})}})})));
    const VectorEditOutcome moved = m.commit_preview("Move nodes");
    REQUIRE_MESSAGE(moved.ok, moved.error);
    CHECK(moved.step > 0);
    CHECK(p.item("tri").nodes[0].nodes[1].p.x == doctest::Approx(65));
    CHECK(p.item("tri").nodes[0].nodes[1].p.y == doctest::Approx(15));
    CHECK(p.text(kSvg) != before);

    const VectorEditOutcome smooth = m.node_ops(
        "tri", Json::array({Json::object({{"op", "convert"}, {"subpath", 0}, {"node", 2}, {"to", "smooth"}})}),
        "Make smooth");
    REQUIRE_MESSAGE(smooth.ok, smooth.error);
    CHECK(p.item("tri").curves);
    const VectorEditOutcome del =
        m.node_ops("tri", Json::array({Json::object({{"op", "delete"}, {"subpath", 0}, {"node", 0}})}), "Delete node");
    REQUIRE_MESSAGE(del.ok, del.error);
    CHECK(p.item("tri").nodeCount == 2);

    REQUIRE(m.apply_step(del.step, false));
    CHECK(p.item("tri").nodeCount == 3);
    REQUIRE(m.apply_step(smooth.step, false));
    CHECK_FALSE(p.item("tri").curves);
    REQUIRE(m.apply_step(moved.step, false));
    CHECK(p.text(kSvg) == before);
    REQUIRE(m.apply_step(moved.step, true));
    REQUIRE(m.apply_step(smooth.step, true));
    REQUIRE(m.apply_step(del.step, true));
    CHECK(p.item("tri").nodeCount == 2);
}

TEST_CASE("an edit that fails changes nothing and says why") {
    Project p;
    p.open_svg(kTwoRects);
    VectorModel& m = *p.model;
    const std::string before = p.text(kSvg);
    const VectorEditOutcome bad = m.node_ops(
        "a", Json::array({Json::object({{"op", "move"}, {"subpath", 0}, {"node", 99}, {"to", Json::array({1, 1})}})}),
        "Move");
    CHECK_FALSE(bad.ok);
    CHECK_FALSE(bad.error.empty());
    CHECK(bad.step == 0);
    CHECK(p.text(kSvg) == before);
    CHECK(m.step_count() == 0);
    // nothing selected: the message says to click a shape
    m.clear_selection();
    const VectorEditOutcome none = m.delete_selection();
    CHECK_FALSE(none.ok);
    CHECK(none.error.find("selected") != std::string::npos);
}

TEST_CASE("boolean buttons: union, subtract, intersect and exclude of the selection; undo brings the two shapes back") {
    Project p;
    p.open_svg(kTwoRects);
    VectorModel& m = *p.model;
    const std::string before = p.text(kSvg);
    for (const char* op : {"union", "subtract", "intersect", "exclude"}) {
        m.select({"a", "b"});
        const VectorEditOutcome out = m.boolean_op(op);
        REQUIRE_MESSAGE(out.ok, op << ": " << out.error);
        CHECK_MESSAGE(m.scene().items.size() == 1, op);
        CHECK(m.selection().size() == 1);
        REQUIRE(m.apply_step(out.step, false));
        CHECK(m.scene().items.size() == 2);
        CHECK(p.text(kSvg) == before);
    }
    // the union covers both: its bounds are the union of the boxes
    m.select({"a", "b"});
    REQUIRE(m.boolean_op("union").ok);
    VecRect box;
    REQUIRE(m.selection_bounds(box, false));
    CHECK(box.x0 == doctest::Approx(10).epsilon(0.01));
    CHECK(box.x1 == doctest::Approx(70).epsilon(0.01));
    // one shape is not enough
    m.select({m.scene().items[0].ref});
    CHECK_FALSE(m.boolean_op("union").ok);
}

TEST_CASE("ids, groups and transforms survive the edits; unnamed elements get an id in the same step") {
    Project p;
    p.open_svg("<g id=\"grp\" transform=\"translate(5,5)\"><rect id=\"r1\" x=\"10\" y=\"10\" width=\"20\" "
               "height=\"20\" fill=\"#123456\"/></g>"
               "<circle cx=\"70\" cy=\"70\" r=\"10\" fill=\"#abcdef\"/>");
    VectorModel& m = *p.model;
    const std::string original = p.text(kSvg);
    const double x0 = p.item("r1").bounds.x0;
    m.select({"r1"});
    const VectorEditOutcome out = m.move_selection(10, 0);
    REQUIRE_MESSAGE(out.ok, out.error);
    const std::string now = p.text(kSvg);
    CHECK(has(now, "id=\"grp\""));
    CHECK(has(now, "id=\"r1\""));
    CHECK(has(now, "translate(5"));
    CHECK(p.item("r1").bounds.x0 == doctest::Approx(x0 + 10));
    CHECK(p.item("r1").parent == p.item("grp").index);

    // the circle has no id: an edit names it, and ONE step brings back the original text
    const VecItem& circle = m.scene().items[std::size_t(p.item("grp").index + 2)];
    REQUIRE(circle.tag == "circle");
    CHECK(circle.id.empty());
    m.select({circle.ref});
    const std::size_t steps = m.step_count();
    const VectorEditOutcome moved = m.move_selection(0, 5);
    REQUIRE_MESSAGE(moved.ok, moved.error);
    CHECK(m.step_count() == steps + 1);
    CHECK_MESSAGE(has(p.text(kSvg), "id=\"circle\""), p.text(kSvg));
    REQUIRE(m.selection().size() == 1);
    CHECK_FALSE(m.selection()[0].empty());
    REQUIRE(m.apply_step(moved.step, false));
    CHECK(has(p.text(kSvg), "<circle cx"));
    REQUIRE(m.apply_step(out.step, false));
    CHECK(p.text(kSvg) == original);
}

TEST_CASE("layers: hide, lock, rename, group, ungroup, reorder and regroup are commands with one undo step each") {
    Project p;
    p.open_svg(std::string(kTwoRects) + "<rect id=\"c\" x=\"60\" y=\"5\" width=\"10\" height=\"10\"/>");
    VectorModel& m = *p.model;

    REQUIRE(m.set_hidden("a", true).ok);
    CHECK(p.item("a").hidden);
    CHECK(has(p.text(kSvg), "display=\"none\""));
    REQUIRE(m.set_hidden("a", false).ok);
    CHECK_FALSE(p.item("a").hidden);

    REQUIRE(m.set_locked("b", true).ok);
    CHECK(p.item("b").locked);
    CHECK(has(p.text(kSvg), "data-locked"));
    // a locked shape is not picked
    CHECK(m.pick({40, 40}, 1) == p.item("a").index);
    REQUIRE(m.set_locked("b", false).ok);
    CHECK(m.pick({60, 60}, 1) == p.item("b").index);

    REQUIRE(m.rename("c", "cap").ok);
    CHECK(m.scene().find("cap") >= 0);
    CHECK(m.scene().find("c") < 0);
    CHECK_FALSE(m.rename("cap", "a").ok);  // taken

    m.select({"a", "b"});
    REQUIRE(m.group_selection().ok);
    REQUIRE(m.selection().size() == 1);
    const std::string grp = m.selection()[0];
    CHECK(p.item(grp).isGroup);
    CHECK(p.item(grp).children.size() == 2);
    // drag "cap" into the group, before "b"
    REQUIRE(m.regroup({"cap"}, grp, "b").ok);
    CHECK(p.item("cap").parent == p.item(grp).index);
    CHECK(p.item(grp).children.size() == 3);
    REQUIRE(m.reorder({"cap"}, "front").ok);
    CHECK(p.item(grp).children.back() == p.item("cap").index);
    m.select({grp});
    REQUIRE(m.ungroup_selection().ok);
    CHECK(m.scene().roots().size() == 3);
}

TEST_CASE("selection: click picks at the group level, double click goes in, marquee and nodes") {
    Project p;
    p.open_svg("<g id=\"g1\"><rect id=\"r1\" x=\"10\" y=\"10\" width=\"20\" height=\"20\"/><rect id=\"r2\" x=\"40\" "
               "y=\"10\" width=\"20\" height=\"20\"/></g>"
               "<rect id=\"r3\" x=\"10\" y=\"60\" width=\"20\" height=\"20\"/>");
    VectorModel& m = *p.model;
    CHECK(m.pick({20, 20}, 1) == p.item("g1").index);  // the group, not the rect inside
    m.enter_group("g1");
    CHECK(m.pick({20, 20}, 1) == p.item("r1").index);
    CHECK(m.pick({20, 70}, 1) == p.item("r3").index);  // outside the group: the shape at the top level
    m.leave_group();
    CHECK(m.context().empty());
    CHECK(m.selection() == std::vector<std::string>{"g1"});

    const std::vector<int> all = m.marquee({0, 0, 100, 100}, false);
    CHECK(all.size() == 2);  // g1 and r3
    CHECK(m.marquee({0, 55, 100, 100}, false).size() == 1);
    CHECK(m.marquee({35, 0, 45, 100}, true).size() == 1);  // touches r2 (so g1)
    m.select_all();
    CHECK(m.selection().size() == 2);

    VecRect box;
    REQUIRE(m.selection_bounds(box, false));
    CHECK(box.x0 == doctest::Approx(10));
    CHECK(box.y1 == doctest::Approx(80));

    const VectorNodeRef n{"r3", 0, 1};
    m.toggle_node(n);
    CHECK(m.node_selected(n));
    m.toggle_node(n);
    CHECK_FALSE(m.node_selected(n));
}

TEST_CASE("shapes: rectangle, ellipse, line and a parametric star drawn by the tools keep their parameters; the "
          "inspector redraws them") {
    Project p;
    p.open_svg("");
    VectorModel& m = *p.model;
    REQUIRE(m.add_rect({10, 10}, {40, 30}).ok);
    CHECK(m.scene().items.size() == 1);
    CHECK(p.item(m.selection()[0]).bounds.width() == doctest::Approx(30));
    REQUIRE(m.add_ellipse({50, 10}, {90, 30}).ok);
    REQUIRE(m.add_line({10, 90}, {90, 90}).ok);
    CHECK(m.scene().items.size() == 3);
    CHECK_FALSE(m.add_rect({5, 5}, {5, 20}).ok);  // no width
    CHECK(m.scene().items.size() == 3);

    const VectorEditOutcome star = m.add_shape("star", {20, 40}, {60, 80}, Json::object({{"points", 6}}));
    REQUIRE_MESSAGE(star.ok, star.error);
    const std::string ref = m.selection()[0];
    CHECK(p.item(ref).shapeKind == "star");
    CHECK_FALSE(p.item(ref).shapeArgs.empty());
    const int before = p.item(ref).nodeCount;
    // a live preview of a parameter, then the commit
    REQUIRE(m.preview_shape_args(ref, "star",
                                 Json::object({{"points", 9}, {"radius", 20}, {"center", Json::array({40, 60})}})));
    CHECK(m.previewing());
    CHECK(p.item(ref).nodeCount > before);
    REQUIRE(m.commit_preview("Change star").ok);
    CHECK(p.item(ref).shapeKind == "star");
    CHECK(p.item(ref).nodeCount > before);
    // the shape stays parametric: a node edit turns it into a plain path
    REQUIRE(m.node_ops(ref,
                       Json::array(
                           {Json::object({{"op", "move"}, {"subpath", 0}, {"node", 0}, {"by", Json::array({1, 1})}})}),
                       "Move node")
                .ok);
    CHECK(p.item(ref).shapeKind.empty());
}

TEST_CASE("snapping: grid, guides, points of other shapes; the moving shape does not attract itself") {
    Project p;
    p.open_svg(kTwoRects);
    VectorModel& m = *p.model;
    m.snapping.points = false;
    m.snapping.guides = false;
    m.snapping.grid = true;
    m.snapping.gridSize = 10;
    VectorSnapKind kind = VectorSnapKind::None;
    VecPoint s = m.snap_point({12.5, 7.9}, 3, {}, &kind);
    CHECK(s.x == doctest::Approx(10));
    CHECK(s.y == doctest::Approx(10));
    CHECK(kind == VectorSnapKind::Grid);
    s = m.snap_point({15, 15}, 3, {}, &kind);  // too far from every line
    CHECK(kind == VectorSnapKind::None);
    CHECK(s.x == doctest::Approx(15));

    m.snapping.grid = false;
    m.snapping.guides = true;
    m.guidesX = {33};
    s = m.snap_point({34, 50}, 2, {}, &kind);
    CHECK(s.x == doctest::Approx(33));
    CHECK(s.y == doctest::Approx(50));
    CHECK(kind == VectorSnapKind::Guide);

    m.snapping.guides = false;
    m.snapping.points = true;
    s = m.snap_point({50.8, 10.4}, 3, {}, &kind);  // the corner of "a"
    CHECK(kind == VectorSnapKind::Point);
    CHECK(s.x == doctest::Approx(50));
    CHECK(s.y == doctest::Approx(10));
    // "a" is being moved: its own corner does not hold it
    s = m.snap_point({50.8, 10.4}, 1.2, {"a"}, &kind);
    CHECK(kind != VectorSnapKind::Point);
    // moving the box of "a" by (19, 0): its right edge x=50+19 is near b's left edge? b spans 30..70, so its edges are 30, 50, 70
    const VecRect box = p.item("a").bounds;
    const VecPoint d = m.snap_move(box, {19.4, 0}, 1.5, {"a"});
    CHECK(d.x == doctest::Approx(20));  // a's right edge lands on 70
}

TEST_CASE("an svg layer of an image document is edited through the same code, and Save bakes the PNG") {
    Project p;
    p.ok("image.create",
         Json::object(
             {{"path", kDoc},
              {"width", 64},
              {"height", 64},
              {"layers", Json::array({Json::object({{"kind", "fill"}, {"name", "bg"}, {"color", "#ffffff"}}),
                                      Json::object({{"kind", "svg"},
                                                    {"name", "art"},
                                                    {"width", 64},
                                                    {"height", 64},
                                                    {"svg", svg_of("<rect id=\"box\" x=\"10\" y=\"10\" width=\"30\" "
                                                                   "height=\"30\" fill=\"#ff0000\"/>")}})})}}));
    VectorModel& m = *p.model;
    REQUIRE_MESSAGE(m.open_layer(kDoc, "art"), m.error());
    CHECK(m.is_layer());
    CHECK(m.layer_path() == "1");
    REQUIRE(m.scene().items.size() == 1);
    const std::string docBefore = p.text(kDoc);

    REQUIRE(m.add_ellipse({40, 40}, {60, 60}).ok);
    CHECK(m.scene().items.size() == 2);
    const std::string docAfter = p.text(kDoc);
    CHECK(docAfter != docBefore);
    CHECK(has(docAfter, "<circle"));         // a 20 x 20 ellipse is a circle
    CHECK(has(docAfter, "id=\\\"box\\\""));  // the JSON string keeps the id

    m.select({"box"});
    const VectorEditOutcome out = m.move_selection(5, 5);
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(m.step_document(out.step) == kDoc);
    CHECK(m.step_layer(out.step) == "art");
    REQUIRE(m.apply_step(out.step, false));
    CHECK(p.item("box").bounds.x0 == doctest::Approx(10));

    const VectorEditOutcome saved = m.save();
    REQUIRE_MESSAGE(saved.ok, saved.error);
    // the layer is still an svg layer and the document is valid for the Image panel
    CHECK(has(p.text(kDoc), "\"svg\""));
}

TEST_CASE("a file changed behind the model's back is read again") {
    Project p;
    p.open_svg(kTwoRects);
    VectorModel& m = *p.model;
    CHECK_FALSE(m.poll_external());
    p.write(kSvg, svg_of(std::string(kTwoRects) + "<circle id=\"extra\" cx=\"80\" cy=\"20\" r=\"10\"/>"));
    CHECK(m.poll_external());
    CHECK(m.scene().items.size() == 3);
    CHECK_FALSE(m.poll_external());
    // a file that no longer parses: the model says so and keeps the reason
    p.write(kSvg, "<svg><g></svg>");
    m.poll_external();
    CHECK_FALSE(m.valid());
    CHECK_FALSE(m.error().empty());
    p.write(kSvg, svg_of(kTwoRects));
    REQUIRE(m.reload());
    CHECK(m.valid());
}

TEST_CASE("the picture: the engine's rasterizer draws a region of the drawing") {
    Project p;
    p.open_svg("<rect id=\"a\" x=\"0\" y=\"0\" width=\"50\" height=\"100\" fill=\"#ff0000\"/>");
    VectorModel& m = *p.model;
    auto img = m.rasterize(nullptr, 100, 100);
    REQUIRE(img.ok());
    auto px = [&](const Image& i, int x, int y) {
        return &i.rgba[(std::size_t(y) * std::size_t(i.width) + std::size_t(x)) * 4];
    };
    CHECK(px(*img, 10, 50)[0] == 255);
    CHECK(px(*img, 10, 50)[3] == 255);
    CHECK(px(*img, 90, 50)[3] == 0);
    const VecRect right{50, 0, 100, 100};
    auto half = m.rasterize(&right, 50, 100);
    REQUIRE(half.ok());
    CHECK(px(*half, 5, 50)[3] == 0);  // that half is empty
    CHECK(m.last_raster_ms() >= 0);
}

TEST_CASE("steps: retain keeps only the ones the editor's stacks point at") {
    Project p;
    p.open_svg(kTwoRects);
    VectorModel& m = *p.model;
    m.select({"a"});
    const int s1 = m.move_selection(1, 0).step;
    const int s2 = m.move_selection(1, 0).step;
    const int s3 = m.move_selection(1, 0).step;
    CHECK(m.step_count() == 3);
    m.retain_steps({s1, s3});
    CHECK(m.step_count() == 2);
    CHECK(m.step(s2) == nullptr);
    CHECK_FALSE(m.apply_step(s2, false));
}

TEST_CASE("a drawing of several hundred paths: the cost of reading it, of a drag and of the picture") {
    Project p;
    std::string body;
    constexpr int kCount = 600;
    for (int i = 0; i < kCount; ++i) {
        const double x = (i % 30) * 33.0 + 4, y = (i / 30) * 48.0 + 4;
        body += "<path id=\"p" + std::to_string(i) + "\" d=\"M" + std::to_string(x) + " " + std::to_string(y) + " C" +
                std::to_string(x + 20) + " " + std::to_string(y) + " " + std::to_string(x + 30) + " " +
                std::to_string(y + 20) + " " + std::to_string(x + 10) + " " + std::to_string(y + 30) + " L" +
                std::to_string(x) + " " + std::to_string(y + 30) + " Z\" fill=\"#" + (i % 2 ? "3366cc" : "cc6633") +
                "\" stroke=\"#101018\" stroke-width=\"1\"/>";
    }
    p.write(kSvg,
            std::string(
                "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 1000 1000\" width=\"1000\" height=\"1000\">") +
                body + "</svg>");
    using Clock = std::chrono::steady_clock;
    const auto ms = [](Clock::time_point a) {
        return std::chrono::duration<double, std::milli>(Clock::now() - a).count();
    };
    VectorModel& m = *p.model;
    const auto t0 = Clock::now();
    REQUIRE_MESSAGE(m.open(kSvg), m.error());
    const double openMs = ms(t0);
    REQUIRE(m.scene().items.size() == std::size_t(kCount));

    const auto t1 = Clock::now();
    int hits = 0;
    for (int i = 0; i < 100; ++i) hits += m.pick({double(i * 9 % 990), double(i * 7 % 990)}, 2) >= 0 ? 1 : 0;
    const double pickMs = ms(t1) / 100;

    m.select({"p10"});
    double worst = 0, total = 0;
    constexpr int kMoves = 20;
    for (int i = 1; i <= kMoves; ++i) {
        const auto t = Clock::now();
        REQUIRE(m.preview_edit("vector.transform", Json::object({{"elements", Json::array({"p10"})},
                                                                 {"translate", Json::array({double(i), 0.0})}})));
        const double e = ms(t);
        worst = std::max(worst, e);
        total += e;
    }
    const auto t2 = Clock::now();
    const VectorEditOutcome done = m.commit_preview("Move");
    const double commitMs = ms(t2);
    REQUIRE_MESSAGE(done.ok, done.error);

    const auto t3 = Clock::now();
    auto img = m.rasterize(nullptr, 1024, 1024);
    const double rasterMs = ms(t3);
    REQUIRE(img.ok());

    MESSAGE(kCount << " paths: open + read " << openMs << " ms, a hit test " << pickMs << " ms (" << hits
                   << " hits of 100), a drag step " << total / kMoves << " ms on average (worst " << worst
                   << " ms), the edit written " << commitMs << " ms, the 1024x1024 picture " << rasterMs << " ms");
    // generous: a debug build on a loaded machine; the numbers above are what is reported
    CHECK(total / kMoves < 4000);
}
