// The Image panel's model (image_model.h): what the canvas shows while a gesture goes on is what the command writes at the end, every
// edit is one undo step, the selection / move / transform tools, adjustments and effects, saving. No window: the model calls the real
// image.* commands of a temporary project.
#include <algorithm>
#include <chrono>
#include <cmath>
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/tooling/asset_import.h"
#include "fa/tooling/image_doc.h"
#include "image_model.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

struct Project {
    stdfs::path dir;
    CommandRegistry registry;
    std::unique_ptr<ImageModel> model;
    Project() {
        dir = fs::make_temp_dir("fa_image_panel").value();
        register_asset_commands(registry, dir.string());
        model = std::make_unique<ImageModel>(dir.string(), [this](const std::string& name, const Json& args) { return registry.call(name, args); });
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
    Image png(const std::string& rel) const {
        std::ifstream in(file(rel), std::ios::binary);
        std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        auto img = decode_image(reinterpret_cast<const std::uint8_t*>(bytes.data()), bytes.size());
        REQUIRE_MESSAGE(img.ok(), rel);
        return *img;
    }
    std::string text(const std::string& rel) const {
        std::ifstream in(file(rel), std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }
};

constexpr const char* kDoc = "assets/art/t.image.json";

struct Rgba {
    int r, g, b, a;
    bool operator==(const Rgba& o) const { return r == o.r && g == o.g && b == o.b && a == o.a; }
};
Rgba at(const Image& img, int x, int y) {
    const std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
    return {p[0], p[1], p[2], p[3]};
}

// 32x32: a blue background, then (through the model) an empty pixels layer "pixels" that is selected.
void make_pixels_doc(Project& p) {
    p.ok("image.create", Json::object({{"path", kDoc}, {"width", 32}, {"height", 32},
                                       {"layers", Json::array({Json::object({{"kind", "fill"}, {"name", "bg"}, {"color", "#0000ff"}})})}}));
    REQUIRE(p.model->open(kDoc));
    p.model->select_layer("0");
    REQUIRE(p.model->add_layer("pixels").ok);
    REQUIRE(p.model->selected_layer() == "1");
}

ImageBrushSettings red_brush(double size = 4) {
    ImageBrushSettings b;
    b.size = size;
    b.color = Color{1, 0, 0, 1};
    return b;
}

}  // namespace

TEST_CASE("every adjustment and effect type has fields and a default entry the compositor accepts") {
    Project p;
    make_pixels_doc(p);
    for (bool effect : {false, true}) {
        const auto types = effect ? image_effect_types() : image_adjustment_types();
        for (const ImageOpInfo& t : types) {
            INFO("type: " << t.name);
            const Json op = ImageModel::default_operation(t.name, effect);
            CHECK(op["type"] == t.name);
            if (t.name != "invert") CHECK(!image_op_fields(t.name, effect).empty());
            auto r = p.model->add_operation("1", effect, t.name);
            CHECK_MESSAGE(r.ok, r.error);
            CHECK(p.model->valid());
            p.model->picture();
        }
    }
    CHECK(p.model->layer("1")->adjustments.size() == image_adjustment_types().size());
}

TEST_CASE("opening a document lists its layers and draws it") {
    Project p;
    make_pixels_doc(p);
    const auto rows = p.model->layer_rows();
    REQUIRE(rows.size() == 2);
    CHECK(rows[0].name == "pixels");   // top first
    CHECK(rows[1].name == "bg");
    const Image& pic = p.model->picture();
    CHECK(pic.width == 32);
    CHECK(at(pic, 5, 5) == Rgba{0, 0, 255, 255});
    CHECK_FALSE(p.model->open("assets/art/missing.image.json"));
    CHECK(p.model->error().find("missing") != std::string::npos);
}

TEST_CASE("a stroke shows while it is drawn and the command writes the same pixels at the end; undo and redo") {
    Project p;
    make_pixels_doc(p);
    const std::string layerPng = p.model->layer("1")->source;
    const std::string before = p.text(layerPng);
    REQUIRE(p.model->begin_stroke(false, red_brush(), 5.5, 5.5));
    p.model->stroke_to(12.5, 6.5);
    p.model->stroke_to(20.5, 14.5);
    const Image live = p.model->picture();
    CHECK(at(live, 6, 5) == Rgba{255, 0, 0, 255});
    CHECK(p.text(layerPng) == before);   // nothing on disk yet
    const ImageEditOutcome out = p.model->end_stroke();
    REQUIRE(out.ok);
    CHECK(out.step > 0);
    CHECK(p.text(layerPng) != before);
    const Image done = p.model->picture();
    REQUIRE(done.rgba.size() == live.rgba.size());
    CHECK(done.rgba == live.rgba);   // preview == command
    // undo and redo
    REQUIRE(p.model->apply_step(out.step, false));
    CHECK(p.text(layerPng) == before);
    CHECK(at(p.model->picture(), 6, 5) == Rgba{0, 0, 255, 255});
    REQUIRE(p.model->apply_step(out.step, true));
    CHECK(p.model->picture().rgba == live.rgba);
}

TEST_CASE("the eraser, the fill and the picker") {
    Project p;
    make_pixels_doc(p);
    REQUIRE(p.model->begin_stroke(false, red_brush(10), 10, 10));
    REQUIRE(p.model->end_stroke().ok);
    CHECK(at(p.model->picture(), 10, 10) == Rgba{255, 0, 0, 255});
    REQUIRE(p.model->begin_stroke(true, red_brush(4), 10, 10));
    REQUIRE(p.model->end_stroke().ok);
    CHECK(at(p.model->picture(), 10, 10) == Rgba{0, 0, 255, 255});   // the red is erased down to the background
    ImageBrushSettings green;
    green.color = Color{0, 1, 0, 1};
    REQUIRE(p.model->fill_at(0, 0, green, 16).ok);   // the transparent area of the layer
    CHECK(at(p.model->picture(), 0, 0) == Rgba{0, 255, 0, 255});
    CHECK(at(p.model->picture(), 8, 6) == Rgba{255, 0, 0, 255});   // the ring of red around the hole is not the same colour
    const auto c = p.model->pick_color(8, 6);
    REQUIRE(c);
    CHECK(c->r == doctest::Approx(1.0));
}

TEST_CASE("selections: rectangle, add, invert, grow, wand, deselect; each one is an undo step") {
    Project p;
    make_pixels_doc(p);
    auto r = p.model->select_rect(4, 4, 8, 8, SelectOp::Replace);
    REQUIRE(r.ok);
    CHECK(r.step > 0);
    int x = 0, y = 0, w = 0, h = 0;
    REQUIRE(p.model->selection_bounds(x, y, w, h));
    CHECK(std::array<int, 4>{x, y, w, h} == std::array<int, 4>{4, 4, 8, 8});
    CHECK_FALSE(p.model->selection_edges().empty());
    REQUIRE(p.model->select_rect(20, 20, 4, 4, SelectOp::Add).ok);
    CHECK(p.model->selection().at(21, 21) == 255);
    CHECK(p.model->selection().at(5, 5) == 255);
    REQUIRE(p.model->selection_invert().ok);
    CHECK(p.model->selection().at(5, 5) == 0);
    CHECK(p.model->selection().at(0, 0) == 255);
    REQUIRE(p.model->deselect().ok);
    CHECK_FALSE(p.model->has_selection());
    REQUIRE(p.model->select_rect(10, 10, 4, 4, SelectOp::Replace).ok);
    REQUIRE(p.model->selection_grow(2).ok);
    CHECK(p.model->selection().at(9, 9) > 0);
    // magic wand on the flat blue background selects all of it
    p.model->select_layer("0");
    ImageWandSettings wand;
    wand.tolerance = 8;
    REQUIRE(p.model->select_wand(0, 0, wand, SelectOp::Replace).ok);
    CHECK(p.model->selection().at(31, 31) == 255);
    // undo walks back
    const int last = p.model->select_rect(2, 2, 3, 3, SelectOp::Replace).step;
    REQUIRE(last > 0);
    CHECK(p.model->selection().at(31, 31) == 0);
    REQUIRE(p.model->apply_step(last, false));
    CHECK(p.model->selection().at(31, 31) == 255);   // the wand selection is back
    CHECK(p.model->selection().at(2, 2) == 255);
    CHECK_FALSE(p.model->select_rect(100, 100, 4, 4, SelectOp::Replace).ok);   // outside the picture
}

TEST_CASE("move: the selected pixels, and the whole layer without a selection") {
    Project p;
    make_pixels_doc(p);
    REQUIRE(p.model->begin_stroke(false, red_brush(6), 8, 8));
    REQUIRE(p.model->end_stroke().ok);
    REQUIRE(p.model->select_rect(4, 4, 8, 8, SelectOp::Replace).ok);
    REQUIRE(p.model->begin_move());
    p.model->move_by(10, 0);
    CHECK(at(p.model->picture(), 18, 8) == Rgba{255, 0, 0, 255});
    CHECK(at(p.model->picture(), 8, 8) == Rgba{0, 0, 255, 255});
    const Image live = p.model->picture();
    REQUIRE(p.model->end_move().ok);
    CHECK(p.model->picture().rgba == live.rgba);
    CHECK(p.model->selection().at(15, 5) == 255);   // the selection moved with the pixels
    REQUIRE(p.model->deselect().ok);
    const int y0 = p.model->layer("1")->y;
    REQUIRE(p.model->begin_move());
    p.model->move_by(0, 5);
    const ImageEditOutcome out = p.model->end_move();
    REQUIRE(out.ok);
    CHECK(p.model->layer("1")->y == y0 + 5);
    CHECK(at(p.model->picture(), 18, 13) == Rgba{255, 0, 0, 255});
}

TEST_CASE("transform: scale the selected pixels, preview equals the command, undo") {
    Project p;
    make_pixels_doc(p);
    REQUIRE(p.model->begin_stroke(false, red_brush(4), 10, 10));
    REQUIRE(p.model->end_stroke().ok);
    REQUIRE(p.model->begin_transform());
    CHECK(p.model->transform().boxW > 0);
    p.model->set_transform_nearest(true);
    p.model->set_transform(2, 2, 0, false, false, 0, 0);
    const Image live = p.model->picture();
    const ImageEditOutcome out = p.model->apply_transform();
    REQUIRE(out.ok);
    CHECK(p.model->picture().rgba == live.rgba);
    CHECK(at(live, 10, 10) == Rgba{255, 0, 0, 255});
    CHECK(at(live, 6, 10) == Rgba{255, 0, 0, 255});   // 4 px became 8: it reaches 2 px further out than before
    REQUIRE(p.model->apply_step(out.step, false));
    CHECK(at(p.model->picture(), 6, 10) == Rgba{0, 0, 255, 255});
    // cancel leaves the layer alone
    REQUIRE(p.model->begin_transform());
    p.model->set_transform(3, 3, 45, false, false, 0, 0);
    p.model->picture();
    p.model->cancel_transform();
    CHECK(at(p.model->picture(), 6, 10) == Rgba{0, 0, 255, 255});
}

TEST_CASE("indexed layers are painted palette-exact") {
    Project p;
    p.ok("image.create", Json::object({{"path", kDoc}, {"width", 16}, {"height", 16},
                                       {"palette", Json::array({"#000000", "#ff0000", "#00ff00"})},
                                       {"layers", Json::array({Json::object({{"kind", "indexed"}, {"name", "sprite"}})})}}));
    REQUIRE(p.model->open(kDoc));
    p.model->select_layer("0");
    ImageBrushSettings b;
    b.size = 2;
    b.paletteIndex = 1;
    REQUIRE(p.model->begin_stroke(false, b, 3.2, 3.2));
    p.model->stroke_to(9.7, 3.2);
    const Image live = p.model->picture();
    CHECK(at(live, 3, 3) == Rgba{255, 0, 0, 255});
    CHECK(at(live, 9, 3) == Rgba{255, 0, 0, 255});
    CHECK(at(live, 6, 9) == Rgba{0, 0, 0, 0});
    const ImageEditOutcome out = p.model->end_stroke();
    REQUIRE(out.ok);
    CHECK(p.model->picture().rgba == live.rgba);
    // every pixel is transparent or exactly a palette colour (no anti-aliasing)
    const Image& pic = p.model->picture();
    for (int y = 0; y < pic.height; ++y)
        for (int x = 0; x < pic.width; ++x) {
            const Rgba c = at(pic, x, y);
            CHECK((c.a == 0 || c == Rgba{0, 0, 0, 255} || c == Rgba{255, 0, 0, 255} || c == Rgba{0, 255, 0, 255}));
        }
    CHECK(p.model->pick_index(3, 3) == 1);
    // the indexed eraser and fill
    b.paletteIndex = 2;
    REQUIRE(p.model->fill_at(0, 0, b, 0).ok);
    CHECK(at(p.model->picture(), 0, 0) == Rgba{0, 255, 0, 255});
    CHECK(at(p.model->picture(), 3, 3) == Rgba{255, 0, 0, 255});
    REQUIRE(p.model->begin_stroke(true, b, 3, 3));
    REQUIRE(p.model->end_stroke().ok);
    CHECK(at(p.model->picture(), 3, 3) == Rgba{0, 0, 0, 0});
    // palette colour edit
    REQUIRE(p.model->set_palette_color(1, "#0000ff").ok);
    CHECK(at(p.model->picture(), 8, 3) == Rgba{0, 0, 255, 255});
    // a layer that is not pixels or indexed cannot be painted on
    p.model->select_layer("0");
    REQUIRE(p.model->add_layer("fill").ok);
    std::string why;
    CHECK_FALSE(p.model->paintable(p.model->selected_layer(), &why));
    CHECK(why.find("fill") != std::string::npos);
    CHECK_FALSE(p.model->begin_stroke(false, b, 1, 1));
}

TEST_CASE("a locked layer cannot be painted on") {
    Project p;
    make_pixels_doc(p);
    p.model->set_locked("1", true);
    std::string why;
    CHECK_FALSE(p.model->paintable("1", &why));
    CHECK(why.find("locked") != std::string::npos);
    CHECK_FALSE(p.model->begin_stroke(false, red_brush(), 1, 1));
    CHECK_FALSE(p.model->begin_move());
}

TEST_CASE("layers: add, rename, set, duplicate, move, remove; undo restores the files") {
    Project p;
    make_pixels_doc(p);
    REQUIRE(p.model->begin_stroke(false, red_brush(4), 6, 6));
    REQUIRE(p.model->end_stroke().ok);
    const auto dup = p.model->duplicate_layer("1");
    REQUIRE(dup.ok);
    REQUIRE(p.model->layer_rows().size() == 3);
    CHECK(p.model->layer("2")->name == "pixels copy");
    CHECK(p.model->layer("2")->source != p.model->layer("1")->source);   // its own PNG
    CHECK(p.model->selected_layer() == "2");
    // painting on the copy leaves the original alone
    REQUIRE(p.model->begin_stroke(false, red_brush(4), 20, 20));
    REQUIRE(p.model->end_stroke().ok);
    // (a pixels layer's PNG is its box: the canvas pixel 20,20 is at 20 - x, 20 - y in it)
    const ImageLayer* orig = p.model->layer("1");
    const ImageLayer* copy = p.model->layer("2");
    const Image origPng = p.png(orig->source), copyPng = p.png(copy->source);
    CHECK((20 - orig->x >= origPng.width || 20 - orig->y >= origPng.height || at(origPng, 20 - orig->x, 20 - orig->y).a == 0));
    REQUIRE(20 - copy->x < copyPng.width);
    CHECK(at(copyPng, 20 - copy->x, 20 - copy->y).a == 255);
    REQUIRE(p.model->rename_layer("2", "top").ok);
    CHECK(p.model->layer("2")->name == "top");
    CHECK(p.model->selected_layer() == "2");
    REQUIRE(p.model->set_layer("2", Json::object({{"opacity", 0.5}, {"blend", "multiply"}})).ok);
    CHECK(p.model->layer("2")->opacity == doctest::Approx(0.5));
    CHECK(p.model->layer("2")->blend == ImageBlend::Multiply);
    REQUIRE(p.model->move_layer("2", "", 0).ok);
    CHECK(p.model->layer("0")->name == "top");
    CHECK(p.model->selected_layer() == "0");
    const auto removed = p.model->remove_layer("0");
    REQUIRE(removed.ok);
    CHECK(p.model->layer_rows().size() == 2);
    REQUIRE(p.model->apply_step(removed.step, false));
    CHECK(p.model->layer_rows().size() == 3);
    REQUIRE(p.model->apply_step(dup.step, false));   // undoing the duplicate removes the layer AND its PNG
    // (the layer is back in the state after the duplicate's undo only when the later steps were undone first, which the editor's stack guarantees)
    CHECK(p.model->valid());
    // a group
    REQUIRE(p.model->add_layer("group").ok);
    const std::string group = p.model->selected_layer();
    CHECK(p.model->layer(group)->kind == ImageLayerKind::Group);
    p.model->set_open(group, false);
    CHECK_FALSE(p.model->is_open(group));
}

TEST_CASE("adjustments: add, preview a drag without touching the disk, commit as one step, reorder, remove") {
    Project p;
    make_pixels_doc(p);
    REQUIRE(p.model->begin_stroke(false, red_brush(8), 10, 10));
    REQUIRE(p.model->end_stroke().ok);
    REQUIRE(p.model->add_operation("1", false, "invert").ok);
    REQUIRE(p.model->add_operation("1", false, "brightness").ok);
    CHECK(p.model->layer("1")->adjustments.size() == 2);
    const std::string docText = p.text(kDoc);
    p.model->preview_operation("1", false, 1, Json::object({{"amount", -0.5}}));
    const Image previewed = p.model->picture();
    CHECK(p.text(kDoc) == docText);
    CHECK(previewed.rgba != Image{}.rgba);
    const Rgba shown = at(previewed, 10, 10);
    const ImageEditOutcome out = p.model->commit_operation_preview();
    REQUIRE(out.ok);
    CHECK(out.step > 0);
    CHECK(p.model->layer("1")->adjustments[1]["amount"] == -0.5);
    CHECK(at(p.model->picture(), 10, 10) == shown);   // what the drag showed is what was kept
    // an invalid value is not shown and not kept
    p.model->preview_operation("1", false, 1, Json::object({{"amount", "lots"}}));
    p.model->picture();
    p.model->cancel_preview();
    CHECK(p.model->layer("1")->adjustments[1]["amount"] == -0.5);
    REQUIRE(p.model->move_operation("1", false, 0, 1).ok);
    CHECK(p.model->layer("1")->adjustments[0]["type"] == "brightness");
    REQUIRE(p.model->remove_operation("1", false, 0).ok);
    CHECK(p.model->layer("1")->adjustments.size() == 1);
    // a layer preview (opacity slider)
    p.model->preview_layer("1", Json::object({{"opacity", 0.25}}));
    const Image faded = p.model->picture();
    CHECK(at(faded, 10, 10) != shown);
    REQUIRE(p.model->commit_preview().ok);
    CHECK(p.model->layer("1")->opacity == doctest::Approx(0.25));
}

TEST_CASE("save bakes the PNG; an edit marks it stale; an edit made behind the model's back is noticed") {
    Project p;
    make_pixels_doc(p);
    CHECK(p.model->bake_status().state != ImageBakeState::Fresh);
    REQUIRE(p.model->begin_stroke(false, red_brush(6), 16, 16));
    REQUIRE(p.model->end_stroke().ok);
    const ImageEditOutcome saved = p.model->save();
    REQUIRE(saved.ok);
    CHECK(p.model->bake_status().state == ImageBakeState::Fresh);
    const Image baked = p.png("assets/art/t.png");
    CHECK(at(baked, 16, 16) == Rgba{255, 0, 0, 255});
    CHECK(at(baked, 1, 1) == Rgba{0, 0, 255, 255});
    CHECK(baked.rgba == p.model->picture().rgba);
    CHECK_FALSE(p.model->poll_external());
    // someone else edits the document
    p.ok("image.layer.set", Json::object({{"path", kDoc}, {"layer", "pixels"}, {"set", Json::object({{"visible", false}})}, {"bake", false}}));
    CHECK(p.model->poll_external());
    CHECK_FALSE(p.model->layer("1")->visible);
    CHECK(at(p.model->picture(), 16, 16) == Rgba{0, 0, 255, 255});
    CHECK(p.model->bake_status().state == ImageBakeState::Stale);
}

TEST_CASE("steps: merge, retain and an edit that fails changes nothing") {
    Project p;
    make_pixels_doc(p);
    REQUIRE(p.model->begin_stroke(false, red_brush(4), 6, 6));
    const int a = p.model->end_stroke().step;
    REQUIRE(p.model->begin_stroke(false, red_brush(4), 20, 20));
    const int b = p.model->end_stroke().step;
    REQUIRE(a > 0);
    REQUIRE(b > a);
    p.model->merge_steps(a, b);
    CHECK(p.model->step(b) == nullptr);
    REQUIRE(p.model->apply_step(a, false));
    CHECK(at(p.model->picture(), 6, 6) == Rgba{0, 0, 255, 255});
    CHECK(at(p.model->picture(), 20, 20) == Rgba{0, 0, 255, 255});
    p.model->retain_steps({});
    CHECK(p.model->step_count() == 0);
    CHECK_FALSE(p.model->apply_step(a, true));
    // a failing command leaves the document as it was
    const std::string before = p.text(kDoc);
    CHECK_FALSE(p.model->set_layer("1", Json::object({{"blend", "no-such-blend"}})).ok);
    CHECK(p.text(kDoc) == before);
    CHECK(p.model->valid());
}

TEST_CASE("an animated document paints into the current frame") {
    Project p;
    make_pixels_doc(p);
    p.ok("image.frame.add", Json::object({{"path", kDoc}, {"count", 1}, {"bake", false}}));
    REQUIRE(p.model->reload());
    REQUIRE(p.model->animated());
    CHECK(p.model->frame_count() == 2);
    p.model->set_frame(1);
    REQUIRE(p.model->begin_stroke(false, red_brush(4), 8, 8));
    const Image live = p.model->picture();
    CHECK(at(live, 8, 8) == Rgba{255, 0, 0, 255});
    REQUIRE(p.model->end_stroke().ok);
    CHECK(p.model->picture().rgba == live.rgba);
    p.model->set_frame(0);
    CHECK(at(p.model->picture(), 8, 8) == Rgba{0, 0, 255, 255});
    p.model->set_frame(1);
    CHECK(at(p.model->picture(), 8, 8) == Rgba{255, 0, 0, 255});
    p.model->set_onion(true);
    CHECK(p.model->picture().width == 32);
}

// Not an assertion on time (a loaded machine would fail it): it prints what one mouse move of a stroke costs on a 1024x1024 document
// (run `fa_test_editor -tc="*1024*"`), and checks that the live picture is the one the command writes (within one level).
TEST_CASE("painting on a 1024x1024 document: the cost of a mouse move") {
    Project p;
    p.ok("image.create", Json::object({{"path", kDoc}, {"width", 1024}, {"height", 1024},
                                       {"layers", Json::array({Json::object({{"kind", "fill"}, {"name", "bg"}, {"color", "#336699"}}),
                                                               Json::object({{"kind", "gradient"}, {"name", "sky"},
                                                                             {"gradient", Json::object({{"type", "linear"}, {"angle", 90},
                                                                                                        {"stops", Json::array({Json::object({{"at", 0}, {"color", "#000000"}}),
                                                                                                                               Json::object({{"at", 1}, {"color", "#ffffff"}})})}})}})})}}));
    REQUIRE(p.model->open(kDoc));
    p.model->select_layer("1");
    REQUIRE(p.model->add_layer("pixels").ok);
    const std::string top = p.model->selected_layer();
    p.ok("image.layer.add", Json::object({{"path", kDoc}, {"layer", Json::object({{"kind", "fill"}, {"name", "tint"}, {"color", "#ff000010"}})}}));
    REQUIRE(p.model->reload());
    p.model->select_layer(top);
    p.model->picture();
    using Clock = std::chrono::steady_clock;
    const auto ms = [](Clock::time_point a) { return std::chrono::duration<double, std::milli>(Clock::now() - a).count(); };
    ImageBrushSettings b = red_brush(24);
    b.hardness = 0.5;
    const auto t0 = Clock::now();
    REQUIRE(p.model->begin_stroke(false, b, 100, 100));
    p.model->picture();
    const double first = ms(t0);
    const int moves = 120;
    double worst = 0;
    const auto t1 = Clock::now();
    for (int i = 1; i <= moves; ++i) {
        const auto t = Clock::now();
        p.model->stroke_to(100 + i * 6.0, 100 + 300 * std::sin(i / 20.0) + 300);
        p.model->picture();
        worst = std::max(worst, ms(t));
    }
    const double each = ms(t1) / moves;
    const Image live = p.model->picture();
    const double endMs = [&] {
        const auto t = Clock::now();
        REQUIRE(p.model->end_stroke().ok);
        return ms(t);
    }();
    const Image done = p.model->picture();
    std::size_t differing = 0;
    int firstAt = -1, biggest = 0;
    for (std::size_t i = 0; i < done.rgba.size() && i < live.rgba.size(); ++i)
        if (done.rgba[i] != live.rgba[i]) {
            biggest = std::max(biggest, std::abs(int(done.rgba[i]) - int(live.rgba[i])));
            if (!differing) firstAt = int(i / 4);
            ++differing;
        }
    // While a gesture goes on the layers under the edited one are composited once and kept as an 8-bit picture, so the live picture
    // can differ from the finished one by one level of a channel where those layers are translucent (never more).
    CHECK_MESSAGE(biggest <= 1, differing << " bytes differ, the first at pixel " << firstAt % 1024 << "," << firstAt / 1024
                                          << ", by " << biggest << " at most");
    MESSAGE("1024x1024, 4 layers: first frame " << first << " ms, a mouse move " << each << " ms on average (worst " << worst
                                                << " ms), end of the stroke (image.paint + write) " << endMs << " ms");
}

namespace {
void make_indexed_doc(Project& p) {
    p.ok("image.create", Json::object({{"path", kDoc}, {"width", 8}, {"height", 8},
                                       {"palette", Json::array({"#000000", "#ff0000", "#00ff00"})},
                                       {"layers", Json::array({Json::object({{"kind", "indexed"}, {"name", "sprite"}})})}}));
    REQUIRE(p.model->open(kDoc));
    p.model->select_layer("0");
}
void dot(Project& p, int index, double x, double y) {
    ImageBrushSettings b;
    b.size = 1;
    b.paletteIndex = index;
    REQUIRE(p.model->begin_stroke(false, b, x, y));
    REQUIRE(p.model->end_stroke().ok);
}
}  // namespace

TEST_CASE("frames: add blank, duplicate, duration, move and remove; each one undo step") {
    Project p;
    make_indexed_doc(p);
    dot(p, 1, 2.5, 2.5);
    REQUIRE(p.model->frame_count() == 1);
    const ImageEditOutcome add = p.model->add_frame(false);
    REQUIRE(add.ok);
    CHECK(add.step > 0);
    CHECK(p.model->frame_count() == 2);
    CHECK(p.model->frame() == 1);
    CHECK(at(p.model->picture(), 2, 2) == Rgba{0, 0, 0, 0});   // the new frame is empty
    dot(p, 2, 5.5, 5.5);
    const ImageEditOutcome dup = p.model->add_frame(true);
    REQUIRE(dup.ok);
    CHECK(p.model->frame_count() == 3);
    CHECK(at(p.model->picture(), 5, 5) == Rgba{0, 255, 0, 255});   // a copy of frame 2
    REQUIRE(p.model->set_frame_duration(2, 250).ok);
    CHECK(p.model->frame_duration(2) == 250);
    REQUIRE(p.model->move_frame(2, 0).ok);
    p.model->set_frame(0);
    CHECK(p.model->frame_duration(0) == 250);
    const ImageEditOutcome rm = p.model->remove_frame(0);
    REQUIRE(rm.ok);
    CHECK(p.model->frame_count() == 2);
    REQUIRE(p.model->apply_step(rm.step, false));   // undo the removal
    CHECK(p.model->frame_count() == 3);
}

TEST_CASE("the onion skin settings reach the picture") {
    Project p;
    make_indexed_doc(p);
    dot(p, 1, 2.5, 2.5);
    REQUIRE(p.model->add_frame(false).ok);
    p.model->set_onion(false);
    CHECK(at(p.model->picture(), 2, 2).a == 0);
    p.model->set_onion(true);
    CHECK(at(p.model->picture(), 2, 2).a > 0);   // the ghost of frame 1
    ImageModel::OnionSettings o = p.model->onion_settings();
    o.before = 0;
    p.model->set_onion_settings(o);
    CHECK(at(p.model->picture(), 2, 2).a == 0);
    o.before = 1;
    o.opacity = 1.0f;
    p.model->set_onion_settings(o);
    const int strong = at(p.model->picture(), 2, 2).a;
    o.opacity = 0.2f;
    p.model->set_onion_settings(o);
    CHECK(at(p.model->picture(), 2, 2).a < strong);
}

TEST_CASE("palette: add, move and remove colours; the pixels follow; undo restores") {
    Project p;
    make_indexed_doc(p);
    dot(p, 1, 1.5, 1.5);
    dot(p, 2, 3.5, 1.5);
    REQUIRE(p.model->add_palette_color("#0000ff", "sea").ok);
    REQUIRE(p.model->palette().size() == 4);
    CHECK(p.model->palette().find_name("sea") == 3);
    // move the red to the end: the pixel stays red
    const ImageEditOutcome mv = p.model->move_palette_color(1, 3);
    REQUIRE(mv.ok);
    CHECK(mv.step > 0);
    CHECK(at(p.model->picture(), 1, 1) == Rgba{255, 0, 0, 255});
    CHECK(at(p.model->picture(), 3, 1) == Rgba{0, 255, 0, 255});
    CHECK(p.model->pick_index(1, 1) == 3);
    // undo puts the order back
    REQUIRE(p.model->apply_step(mv.step, false));
    CHECK(p.model->pick_index(1, 1) == 1);
    // remove the green: its pixel takes the red (index 1)
    const ImageEditOutcome rm = p.model->remove_palette_color(2, 1);
    REQUIRE(rm.ok);
    CHECK(p.model->palette().size() == 3);
    CHECK(at(p.model->picture(), 3, 1) == Rgba{255, 0, 0, 255});
    REQUIRE(p.model->apply_step(rm.step, false));
    CHECK(p.model->palette().size() == 4);
    CHECK(at(p.model->picture(), 3, 1) == Rgba{0, 255, 0, 255});
    // removing with no replacement makes the pixels transparent
    REQUIRE(p.model->remove_palette_color(2, -1).ok);
    CHECK(at(p.model->picture(), 3, 1).a == 0);
}

TEST_CASE("the terrain preview paints a map with the tileset's autotile tiles") {
    Project p;
    Json parts = Json::object();
    parts["inside"] = Json::object({{"color", "#4a8a2c"}});
    parts["edge"] = Json::object({{"color", "#5fa23a"}});
    parts["corner"] = Json::object({{"color", "#1e4a14"}});
    parts["innerCorner"] = Json::object({{"color", "#2a6a1c"}});
    p.ok("image.tileset.build", Json::object({{"path", kDoc}, {"mode", "blob47"}, {"tileWidth", 8}, {"tileHeight", 8}, {"parts", parts}}));
    REQUIRE(p.model->open(kDoc));
    REQUIRE(p.model->tileset_layer() != nullptr);
    const Image img = p.model->terrain_preview({"###", "###", "###"});
    CHECK(img.width > 0);
    CHECK(img.height > 0);
    CHECK(p.model->terrain_preview({}).width == 0);
}
