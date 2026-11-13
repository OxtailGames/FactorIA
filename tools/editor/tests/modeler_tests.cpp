// The Model panel's model (modeler_model.h): every edit is the model.edit call an AI would run and one undo step, a slider being dragged only
// changes the copy the viewport evaluates, the mesh follows the edits, and Save bakes the .glb. No window: the model calls the real commands of
// a temporary project.
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/asset_import.h"
#include "modeler_model.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kModel = "assets/models/t.model.json";

struct ModelerProject {
    stdfs::path dir;
    CommandRegistry registry;
    std::unique_ptr<ModelerModel> model;
    ModelerProject() {
        dir = fs::make_temp_dir("fa_modeler_panel").value();
        register_asset_commands(registry, dir.string());
        model = std::make_unique<ModelerModel>(
            dir.string(), [this](const std::string& name, const Json& args) { return registry.call(name, args); });
        model->set_async(false);
        model->set_debounce_ticks(0);
    }
    ~ModelerProject() {
        model.reset();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    Json ok(const std::string& name, const Json& args) {
        CommandResult r = registry.call(name, args);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    }
    void open() {
        ok("model.create", Json::parse(R"({"path":"assets/models/t.model.json","bake":false,"nodes":[
            {"op":"box","id":"base","size":[1,0.2,1],"part":"base","align":"bottom"},
            {"op":"group","id":"top","part":"top","position":[0,0.2,0],"children":[
                {"op":"cylinder","id":"post","radius":0.2,"height":1,"align":"bottom"},
                {"op":"sphere","id":"ball","radius":0.3,"position":[0,1.3,0]}]}]})"));
        REQUIRE_MESSAGE(model->open(kModel), model->error());
        REQUIRE_MESSAGE(model->valid(), model->error());
        model->settle();
    }
    std::string text(const std::string& rel = kModel) const {
        std::ifstream in(dir / rel, std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }
    double height() const {
        REQUIRE(model->build());
        return double(model->build()->stats.bmax.y - model->build()->stats.bmin.y);
    }
};

}  // namespace

TEST_CASE("a model document opens, lists its nodes and evaluates to a mesh") {
    ModelerProject p;
    p.open();
    CHECK(p.model->is_open());
    (void)p.model->catalog();
    const std::vector<ModelerRow> rows = p.model->rows();
    REQUIRE(rows.size() == 4);
    CHECK(rows[0].op == "box");
    CHECK(rows[0].id == "base");
    CHECK(rows[0].depth == 0);
    CHECK(rows[0].kind == "primitive");
    CHECK(rows[1].op == "group");
    CHECK(rows[1].container);
    CHECK(rows[2].depth == 1);
    CHECK(rows[2].pointer == "/nodes/1/children/0");
    REQUIRE(p.model->build());
    CHECK(p.model->build_is_fresh());
    CHECK(p.model->build()->stats.triangles > 0);
    const std::vector<std::string> parts = p.model->part_names();
    CHECK(std::find(parts.begin(), parts.end(), "base") != parts.end());
    CHECK(std::find(parts.begin(), parts.end(), "top") != parts.end());
    CHECK(p.model->part_of("/nodes/1/children/0") == "top");
    CHECK(p.model->part_of("/nodes/0") == "base");
    CHECK(p.model->pointer_of("ball") == "/nodes/1/children/1");
    CHECK(p.model->pointer_of("nope").empty());
}

TEST_CASE("the catalog gives every field of an operation with its range and default") {
    ModelerProject p;
    p.open();
    const Json* info = p.model->op_info("cylinder");
    REQUIRE(info);
    bool radius = false;
    for (const Json& f : p.model->fields_of("cylinder"))
        if (f.value("key", std::string()) == "radius") {
            radius = true;
            CHECK(f.contains("default"));
            CHECK(f.contains("min"));
        }
    CHECK(radius);
    CHECK(p.model->op_info("no_such_op") == nullptr);
    // The common fields every node has are offered too.
    bool position = false;
    for (const Json& f : p.model->fields_of("cylinder"))
        position = position || f.value("key", std::string()) == "position";
    CHECK(position);
}

TEST_CASE("setting a parameter is one model.edit, one undo step, and undo and redo restore the file and the mesh") {
    ModelerProject p;
    p.open();
    const std::string original = p.text();
    const double h0 = p.height();
    const ModelerEditOutcome out = p.model->set_values("/nodes/1/children/0", Json::object({{"height", 2.0}}));
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(out.step > 0);
    CHECK(p.text() != original);
    CHECK((*p.model->node("/nodes/1/children/0"))["height"] == 2.0);
    p.model->settle();
    CHECK(p.height() > h0);
    // No bake: the .glb is written by Save.
    CHECK(!stdfs::exists(p.dir / "assets/models/t.glb"));

    REQUIRE(p.model->apply_step(out.step, false));
    CHECK(p.text() == original);
    p.model->settle();
    CHECK(p.height() == doctest::Approx(h0));
    REQUIRE(p.model->apply_step(out.step, true));
    CHECK(p.text() != original);
    p.model->settle();
    CHECK(p.height() > h0);
}

TEST_CASE("a value of null puts the field back to its default and a value that changes nothing records no step") {
    ModelerProject p;
    p.open();
    ModelerEditOutcome out = p.model->set_values("/nodes/1/children/0", Json::object({{"radius", Json()}}));
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(out.step > 0);
    CHECK(!p.model->node("/nodes/1/children/0")->contains("radius"));
    out = p.model->set_values("/nodes/1/children/0", Json::object({{"radius", Json()}}));
    CHECK(out.ok);
    CHECK(out.step == 0);
}

TEST_CASE("an edit the command refuses leaves the file as it was, records no step and says how to fix it") {
    ModelerProject p;
    p.open();
    const std::string original = p.text();
    const ModelerEditOutcome out = p.model->set_values("/nodes/1/children/0", Json::object({{"radius", -3.0}}));
    CHECK(!out.ok);
    CHECK(out.step == 0);
    CHECK(!out.error.empty());
    CHECK(p.text() == original);
    CHECK(p.model->valid());
    const ModelerEditOutcome gone = p.model->set_values("/nodes/9", Json::object({{"radius", 1.0}}));
    CHECK(!gone.ok);
    CHECK(p.text() == original);
}

TEST_CASE("a slider being dragged changes the mesh without writing the file, and letting go writes it") {
    ModelerProject p;
    p.open();
    const std::string original = p.text();
    const double h0 = p.height();
    const std::uint64_t rev0 = p.model->build_revision();
    p.model->set_live("/nodes/1/children/0", Json::object({{"height", 3.0}}));
    CHECK(p.model->has_live());
    CHECK((*p.model->shown_node("/nodes/1/children/0"))["height"] == 3.0);
    CHECK((*p.model->node("/nodes/1/children/0"))["height"] == 1.0);  // the file's value
    p.model->settle();
    CHECK(p.text() == original);
    CHECK(p.model->build_revision() != rev0);
    CHECK(p.height() > h0);
    // Dropping the live value goes back to the file.
    p.model->clear_live();
    p.model->settle();
    CHECK(!p.model->has_live());
    CHECK(p.height() == doctest::Approx(h0));
    // Letting go: the edit is written and the overlay is gone.
    p.model->set_live("/nodes/1/children/0", Json::object({{"height", 3.0}}));
    const ModelerEditOutcome out = p.model->set_values("/nodes/1/children/0", Json::object({{"height", 3.0}}));
    REQUIRE(out.ok);
    CHECK(out.step > 0);
    CHECK(!p.model->has_live());
    p.model->settle();
    CHECK(p.height() > h0);
}

TEST_CASE("a live value the document would refuse shows the error and keeps the last mesh") {
    ModelerProject p;
    p.open();
    p.model->set_live("/nodes/1/children/0", Json::object({{"radius", -1.0}}));
    p.model->settle();
    CHECK(!p.model->eval_error().empty());
    CHECK(p.model->build());
    p.model->clear_live();
    p.model->settle();
    CHECK(p.model->eval_error().empty());
}

TEST_CASE("adding, disabling, moving and removing nodes are undoable steps that change the tree") {
    ModelerProject p;
    p.open();
    const std::string original = p.text();
    const std::size_t tris = p.model->build()->stats.triangles;

    ModelerEditOutcome add =
        p.model->add_node("top", Json::parse(R"({"op":"torus","id":"ring","position":[0,0.5,0]})"));
    REQUIRE_MESSAGE(add.ok, add.error);
    CHECK(add.step > 0);
    CHECK(p.model->rows().size() == 5);
    CHECK(p.model->pointer_of("ring") == "/nodes/1/children/2");
    p.model->settle();
    CHECK(p.model->build()->stats.triangles > tris);

    ModelerEditOutcome off = p.model->set_enabled("/nodes/1/children/2", false);
    REQUIRE_MESSAGE(off.ok, off.error);
    CHECK(!p.model->rows()[4].enabled);
    p.model->settle();
    CHECK(p.model->build()->stats.triangles == tris);
    ModelerEditOutcome on = p.model->set_enabled("/nodes/1/children/2", true);
    REQUIRE_MESSAGE(on.ok, on.error);
    CHECK(p.model->rows()[4].enabled);
    CHECK(!p.model->node("/nodes/1/children/2")->contains("enabled"));

    ModelerEditOutcome mv = p.model->move_node("/nodes/1/children/2", "", 0);
    REQUIRE_MESSAGE(mv.ok, mv.error);
    CHECK(p.model->rows()[0].id == "ring");

    ModelerEditOutcome rm = p.model->remove_node("/nodes/0");
    REQUIRE_MESSAGE(rm.ok, rm.error);
    CHECK(p.model->rows().size() == 4);
    CHECK(p.model->pointer_of("ring").empty());

    // Undo everything, newest first: the document is the one we started with.
    for (int id : {rm.step, mv.step, on.step, off.step, add.step}) REQUIRE(p.model->apply_step(id, false));
    CHECK(p.text() == original);
    p.model->settle();
    CHECK(p.model->build()->stats.triangles == tris);
}

TEST_CASE("steps nobody points to are dropped") {
    ModelerProject p;
    p.open();
    const int a = p.model->set_values("/nodes/0", Json::object({{"size", Json::array({2, 0.2, 2})}})).step;
    const int b = p.model->set_values("/nodes/0", Json::object({{"size", Json::array({3, 0.2, 3})}})).step;
    REQUIRE(a > 0);
    REQUIRE(b > a);
    CHECK(p.model->step_count() == 2);
    p.model->retain_steps({b});
    CHECK(p.model->step_count() == 1);
    CHECK(p.model->step(a) == nullptr);
    CHECK(p.model->step(b) != nullptr);
    CHECK(p.model->step_document(b) == kModel);
    CHECK(!p.model->apply_step(a, false));
}

TEST_CASE("a change on disk behind the panel's back is read again") {
    ModelerProject p;
    p.open();
    CHECK(!p.model->poll_external());
    p.ok("model.edit", Json::object({{"path", kModel},
                                     {"op", "set"},
                                     {"target", "post"},
                                     {"values", Json::object({{"height", 4.0}})},
                                     {"bake", false}}));
    CHECK(p.model->poll_external());
    CHECK((*p.model->node("/nodes/1/children/0"))["height"] == 4.0);
    p.model->settle();
    CHECK(p.height() > 3.0);
}

TEST_CASE("a document that does not load says why and a good one can be opened after it") {
    ModelerProject p;
    p.open();
    {
        std::ofstream f(p.dir / "assets/models/bad.model.json");
        f << R"({"format":"factoria.model/1","nodes":[{"op":"box","size":[1,1,"x"]}]})";
    }
    CHECK(!p.model->open("assets/models/bad.model.json"));
    CHECK(p.model->is_open());
    CHECK(!p.model->valid());
    CHECK(!p.model->error().empty());
    CHECK(p.model->rows().empty());
    CHECK(!p.model->set_values("/nodes/0", Json::object({{"size", 2.0}})).ok);
    CHECK(!p.model->open("assets/music/x.song.json"));
    CHECK(p.model->open(kModel));
    CHECK(p.model->valid());
    p.model->settle();
    CHECK(p.model->build());
    CHECK(p.model->eval_error().empty());
}

TEST_CASE("Save bakes the .glb next to the document and check lists the findings of model.check") {
    ModelerProject p;
    p.open();
    CHECK(p.model->baked_path() == "assets/models/t.glb");
    const ModelerEditOutcome saved = p.model->save();
    CHECK_MESSAGE(saved.ok, saved.error);
    CHECK(stdfs::exists(p.dir / "assets/models/t.glb"));
    const Json check = p.model->check();
    REQUIRE_MESSAGE(check.is_object(), p.model->check_error());
    CHECK(check.contains("findings"));
    CHECK(check["mesh"]["triangles"].get<int>() > 0);
}

TEST_CASE("the document's own fields are edited like a node and are one undo step") {
    ModelerProject p;
    p.open();
    const std::string original = p.text();
    const ModelerEditOutcome out =
        p.model->set_document_field("materials", Json::parse(R"({"wood":{"color":[0.6,0.4,0.2,1]}})"));
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(out.step > 0);
    CHECK(p.model->json().contains("materials"));
    REQUIRE(p.model->apply_step(out.step, false));
    CHECK(p.text() == original);
}
