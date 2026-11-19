// The Graph panel's logic with no window: the model whose edits are one undo step each, whose connects are type-checked by the same checker
// as material.graph.validate and whose save is material.graph.generate (graph_model.h).
#include <filesystem>
#include <fstream>
#include <set>

#include "doctest.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/material_graph.h"
#include "graph_model.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kMat = "materials/dissolve.material.json";

const char* kDissolve = R"({
  "format": "factoria.material/1",
  "doc": "Dissolve.",
  "shader": "shaders/dissolve.surface.glsl",
  "alphaMode": "clip",
  "params": { "dissolve": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "0 shows it, 1 dissolves it." } },
  "graph": {
    "nodes": [
      { "id": "noise", "type": "noise.fbm", "pos": [0, 0], "inputs": { "scale": 6.0 } },
      { "id": "amount", "type": "param", "pos": [0, 120], "param": "dissolve" },
      { "id": "burn", "type": "dissolve", "pos": [220, 60], "inputs": { "edgeWidth": 0.06 } },
      { "id": "out", "type": "output", "pos": [440, 60], "inputs": { "albedo": [0.6, 0.6, 0.65] } }
    ],
    "links": [
      { "from": "noise.value", "to": "burn.noise" },
      { "from": "amount.value", "to": "burn.threshold" },
      { "from": "burn.alpha", "to": "out.alpha" }
    ]
  }
})";

struct GraphProject {
    stdfs::path dir;
    CommandRegistry registry;
    std::unique_ptr<GraphModel> model;
    GraphProject() {
        dir = fs::make_temp_dir("fa_graph_panel").value();
        write(kMat, kDissolve);
        register_material_graph_commands(registry, dir.generic_string());
        model = std::make_unique<GraphModel>(dir.generic_string(), [this](const std::string& name, const Json& args) {
            return registry.call(name, args);
        });
    }
    ~GraphProject() {
        model.reset();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    std::string read(const std::string& rel) const {
        std::ifstream in(dir / rel, std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }
    void open() { REQUIRE_MESSAGE(model->open(kMat), model->error()); }
};

}  // namespace

TEST_CASE("graph model: open reads the graph and the checker's report, a material with no graph is refused") {
    GraphProject p;
    p.open();
    CHECK(p.model->node_count() == 4);
    CHECK(p.model->link_count() == 3);
    CHECK(p.model->report().ok());
    CHECK_FALSE(p.model->dirty());
    CHECK(p.model->snippet_state() == "missing");
    CHECK(p.model->node_type("noise")->type == "noise.fbm");
    CHECK(p.model->node_pos("burn").x == doctest::Approx(220.0f));
    GraphPortId src = p.model->link_source("burn", "threshold");
    CHECK(src.node == "amount");
    CHECK(src.port == "value");

    p.write("materials/plain.material.json",
            R"({"format":"factoria.material/1","shader":"shaders/plain.surface.glsl"})");
    CHECK_FALSE(p.model->open("materials/plain.material.json"));
    CHECK(p.model->error().find("has no \"graph\"") != std::string::npos);
    CHECK(p.model->path() == kMat);  // the document that was open stays
    CHECK(p.model->node_count() == 4);
    CHECK(p.model->open("materials/plain.material.json", true));  // a draft: one output node, never saved
    CHECK(p.model->node_count() == 1);
    CHECK(p.model->dirty());
    CHECK(p.model->snippet_state() == "draft");
}

TEST_CASE("graph model: every edit is one undo step and undo and redo restore the graph exactly") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    const Json original = m.graph();

    GraphEditOutcome a = m.add_node("noise.value", Vec2{100, 200});
    REQUIRE_MESSAGE(a.ok, a.error);
    CHECK(a.step > 0);
    CHECK(a.id == "noise_value");
    CHECK(m.node_count() == 5);
    CHECK(m.is_selected(a.id));
    CHECK(m.dirty());
    GraphEditOutcome b = m.add_node("noise.value", Vec2{100, 260});
    CHECK(b.id == "noise_value2");  // ids stay unique

    GraphEditOutcome c = m.connect("noise_value.value", "burn.noise");  // replaces the link into burn.noise
    REQUIRE_MESSAGE(c.ok, c.error);
    CHECK(m.link_source("burn", "noise").node == "noise_value");
    CHECK(m.link_count() == 3);
    GraphEditOutcome d = m.set_input("noise_value", "scale", 4.0);
    REQUIRE_MESSAGE(d.ok, d.error);
    CHECK(m.input_value("noise_value", "scale") == 4.0);
    GraphEditOutcome e = m.move_nodes({"noise_value"}, 10, -5);
    CHECK(e.ok);
    CHECK(m.node_pos("noise_value").x == doctest::Approx(110.0f));

    const Json edited = m.graph();
    for (int step : {e.step, d.step, c.step, b.step, a.step}) {
        REQUIRE(step > 0);
        REQUIRE_MESSAGE(m.apply_step(step, false), m.status());
    }
    CHECK(m.graph() == original);
    CHECK_FALSE(m.dirty());
    for (int step : {a.step, b.step, c.step, d.step, e.step}) REQUIRE_MESSAGE(m.apply_step(step, true), m.status());
    CHECK(m.graph() == edited);
    // a step that does not fit the graph is refused and changes nothing
    CHECK_FALSE(m.apply_step(a.step, true));
    CHECK(m.graph() == edited);
}

TEST_CASE("graph model: a link of the wrong type, a cycle and a constant of the wrong size are refused with the "
          "checker's message") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    const Json before = m.graph();
    // vec3 emission into a float input
    GraphEditOutcome t = m.connect("burn.emission", "out.alpha");
    CHECK_FALSE(t.ok);
    CHECK(t.error.find("type mismatch") != std::string::npos);
    CHECK(m.graph() == before);
    // a loop: burn feeds a new node that feeds burn
    REQUIRE(m.add_node("math.add", Vec2{300, 300}).ok);
    REQUIRE_MESSAGE(m.connect("burn.alpha", "math_add.a").ok, m.status());
    const Json withLoopOpen = m.graph();
    GraphEditOutcome loop = m.connect("math_add.result", "burn.noise");
    CHECK_FALSE(loop.ok);
    CHECK(loop.error.find("cycle") != std::string::npos);
    CHECK(m.graph() == withLoopOpen);
    // a constant of the wrong size
    GraphEditOutcome k = m.set_input("out", "roughness", Json::array({1, 2}));
    CHECK_FALSE(k.ok);
    CHECK_FALSE(k.error.empty());
    // unknown nodes and ports teach
    CHECK(m.connect("nope.value", "out.alpha").error.find("no node \"nope\"") != std::string::npos);
    CHECK(m.connect("noise.valu", "out.alpha").error.find("no output \"valu\"") != std::string::npos);
    CHECK(m.connect("burn.alpha", "out.alfa").error.find("no input \"alfa\"") != std::string::npos);
    CHECK(m.connect("burn.alpha", "burn.threshold").error.find("itself") != std::string::npos);
}

TEST_CASE("graph model: remove, disconnect, copy, paste and duplicate") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    // the output node stays
    CHECK_FALSE(m.remove_nodes({"out"}).ok);
    CHECK(m.node_count() == 4);
    // cutting a link
    GraphEditOutcome dis = m.disconnect("out.alpha");
    CHECK(dis.ok);
    CHECK(m.link_count() == 2);
    CHECK_FALSE(m.disconnect("out.alpha").ok);
    // removing a node removes its links
    GraphEditOutcome rm = m.remove_nodes({"burn"});
    CHECK(rm.ok);
    CHECK(m.node_count() == 3);
    CHECK(m.link_count() == 0);
    REQUIRE(m.apply_step(rm.step, false));
    CHECK(m.link_count() == 2);

    // copy two linked nodes and paste them: new ids, the link between them is kept, none to the rest
    const std::string clip = m.copy({"noise", "burn", "out"});
    CHECK_FALSE(clip.empty());
    GraphEditOutcome pasted = m.paste(clip, Vec2{500, 500});
    REQUIRE_MESSAGE(pasted.ok, pasted.error);
    CHECK(m.node_count() == 6);  // the output node is not copied
    CHECK(m.selection().size() == 2);
    CHECK(m.node_index("noise2") >= 0);
    CHECK(m.node_index("burn2") >= 0);
    CHECK(m.link_source("burn2", "noise").node == "noise2");
    CHECK(m.node_pos("noise2").x == doctest::Approx(500.0f));
    CHECK(m.node_pos("burn2").x == doctest::Approx(720.0f));
    CHECK_FALSE(m.paste("not a clip", Vec2{0, 0}).ok);
    // duplicate pastes a bit down and right of the originals
    GraphEditOutcome dup = m.duplicate({"amount"});
    REQUIRE(dup.ok);
    CHECK(m.node_pos("amount2").x == doctest::Approx(30.0f));
    // cut = copy + remove
    std::string cutClip;
    CHECK(m.cut({"amount2"}, &cutClip).ok);
    CHECK(m.node_index("amount2") < 0);
    CHECK_FALSE(cutClip.empty());
}

TEST_CASE("graph model: a drag is one step however many moves it takes") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    const Json before = m.graph();
    m.begin_gesture();
    for (int i = 0; i < 10; ++i) {
        const GraphEditOutcome out = m.move_nodes({"noise", "amount"}, 3, 2);
        CHECK(out.ok);
        CHECK(out.step == 0);  // live: no step yet
    }
    const GraphEditOutcome done = m.end_gesture("Move nodes");
    CHECK(done.step > 0);
    CHECK(m.node_pos("noise").x == doctest::Approx(30.0f));
    CHECK(m.apply_step(done.step, false));
    CHECK(m.graph() == before);
    // a gesture that changed nothing makes no step; a cancelled one restores the graph
    m.begin_gesture();
    CHECK(m.end_gesture("nothing").step == 0);
    m.begin_gesture();
    m.move_nodes({"noise"}, 50, 50);
    m.cancel_gesture();
    CHECK(m.graph() == before);
}

TEST_CASE("graph model: errors are found on the node and the link their pointer names") {
    GraphProject p;
    Json doc = Json::parse(kDissolve);
    doc["graph"]["nodes"][1]["param"] = "dissolv";  // a param that does not exist
    doc["graph"]["links"][0]["from"] = "noise.valu";
    p.write(kMat, doc.dump(2));
    p.open();
    GraphModel& m = *p.model;
    CHECK_FALSE(m.report().ok());
    const auto amount = m.node_issues("amount");
    REQUIRE_FALSE(amount.empty());
    CHECK(amount[0].issue.pointer == "/graph/nodes/1/param");
    CHECK(amount[0].issue.message.find("no param") != std::string::npos);
    CHECK(m.node_issues("noise").empty());
    const auto link = m.link_issues(0);
    REQUIRE_FALSE(link.empty());
    CHECK(link[0].issue.pointer == "/graph/links/0/from");
    CHECK(m.link_issues(2).empty());
    // the editor can not save a graph that does not check
    const GraphSaveOutcome s = m.save(false);
    CHECK_FALSE(s.ok);
    CHECK(s.error.find("errors") != std::string::npos);
    CHECK_FALSE(stdfs::exists(p.dir / "shaders/dissolve.surface.glsl"));
}

TEST_CASE("graph model: save is material.graph.generate, and a hand-edited snippet asks before it is overwritten") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    REQUIRE(m.set_input("noise", "scale", 9.0).ok);
    CHECK(m.dirty());
    m.set_view(1.5f, 20, -30);
    const GraphSaveOutcome s = m.save(false);
    REQUIRE_MESSAGE(s.ok, s.error);
    CHECK(s.written);
    CHECK_FALSE(m.dirty());
    CHECK(m.snippet_state() == "in_sync");
    const Json file = Json::parse(p.read(kMat));
    CHECK(file["graph"]["version"] == 1);
    CHECK(file["graph"]["nodes"][0]["inputs"]["scale"] == 9.0);
    CHECK(file["graph"]["editor"]["view"]["zoom"] == 1.5);
    CHECK(file.contains("graphHash"));
    // the same command run by anyone else leaves the file alone: the editor wrote what the command writes
    auto again = p.registry.call("material.graph.generate", Json::object({{"material", kMat}}));
    REQUIRE(again.ok);
    CHECK(again.result["written"] == false);
    CHECK(again.result["state"] == "in_sync");
    // the snippet text is what the checker generated
    CHECK(p.read("shaders/dissolve.surface.glsl") == m.report().snippet);

    // undo after the save still works (the keys a save adds are not part of the step) and makes the graph dirty again
    REQUIRE(m.set_input("noise", "scale", 3.0).ok);
    const GraphEditOutcome e = m.set_input("noise", "gain", 0.7);
    REQUIRE(e.ok);
    REQUIRE(m.apply_step(e.step, false));

    // hand-edit the snippet: the editor says so and does not overwrite without force
    p.write("shaders/dissolve.surface.glsl", p.read("shaders/dissolve.surface.glsl") + "// my tweak\n");
    m.refresh_snippet_state();
    CHECK(m.snippet_state() == "hand_edited");
    const GraphSaveOutcome refused = m.save(false);
    CHECK_FALSE(refused.ok);
    CHECK(refused.needsForce);
    CHECK(refused.state == "hand_edited");
    CHECK(p.read("shaders/dissolve.surface.glsl").find("my tweak") != std::string::npos);
    const GraphSaveOutcome forced = m.save(true);
    REQUIRE_MESSAGE(forced.ok, forced.error);
    CHECK(p.read("shaders/dissolve.surface.glsl").find("my tweak") == std::string::npos);
    CHECK(m.snippet_state() == "in_sync");
}

TEST_CASE("graph model: a new graph material is a valid one-node graph, never overwriting a file") {
    GraphProject p;
    GraphModel& m = *p.model;
    const GraphEditOutcome made = m.create("materials/fresh.material.json");
    REQUIRE_MESSAGE(made.ok, made.error);
    CHECK(m.path() == "materials/fresh.material.json");
    CHECK(m.node_count() == 1);
    CHECK_FALSE(m.dirty());
    CHECK(m.report().ok());
    CHECK(stdfs::exists(p.dir / "shaders/fresh.surface.glsl"));
    CHECK(Json::parse(p.read("materials/fresh.material.json")).contains("graphHash"));
    CHECK_FALSE(m.create("materials/fresh.material.json").ok);  // exists
    CHECK_FALSE(m.create("materials/fresh.json").ok);
}

TEST_CASE("graph model: the file changing on disk is found; unsaved edits are not overwritten") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    CHECK_FALSE(m.poll_external());
    // an outside change with nothing unsaved is read at once
    Json doc = Json::parse(kDissolve);
    doc["graph"]["nodes"][0]["inputs"]["scale"] = 12.0;
    doc["doc"] = "A longer description so the size differs.";
    p.write(kMat, doc.dump(2));
    CHECK(m.poll_external());
    CHECK(m.input_value("noise", "scale") == 12.0);
    CHECK_FALSE(m.external_conflict());
    // with unsaved edits it is a conflict and the graph stays
    REQUIRE(m.set_input("noise", "scale", 2.0).ok);
    doc["doc"] = "Another description of another length, again.";
    p.write(kMat, doc.dump(2));
    CHECK(m.poll_external());
    CHECK(m.external_conflict());
    CHECK(m.input_value("noise", "scale") == 2.0);
    CHECK(m.reload());
    CHECK(m.input_value("noise", "scale") == 12.0);
    CHECK_FALSE(m.external_conflict());
}

TEST_CASE("graph model: the palette lists the nodes of the material's kind and filters by name, category and doc") {
    GraphProject p;
    p.open();
    const auto all = p.model->palette("");
    CHECK(all.size() > 20);
    const auto noise = p.model->palette("NOISE");
    REQUIRE_FALSE(noise.empty());
    bool hasFbm = false, hasAdd = false;
    for (const GraphNodeType* t : noise) {
        hasFbm = hasFbm || t->type == "noise.fbm";
        hasAdd = hasAdd || t->type == "math.add";
    }
    CHECK(hasFbm);
    CHECK_FALSE(hasAdd);
    CHECK(noise.size() < all.size());
    CHECK(p.model->palette("zzzz-no-such-node").empty());
    CHECK(graph_ports_may_link("float", "vec3"));
    CHECK(graph_ports_may_link("gen", "vec2"));
    CHECK_FALSE(graph_ports_may_link("vec3", "vec2"));
    CHECK(graph_port_class("vec3") != graph_port_class("vec2"));
}

TEST_CASE("graph model: opening the open material again keeps its unsaved edits, a failed open changes nothing") {
    GraphProject p;
    p.open();
    REQUIRE(p.model->add_node("math.add", Vec2{10, 10}).ok);
    REQUIRE(p.model->dirty());
    const int nodes = p.model->node_count();
    const std::uint64_t rev = p.model->revision();

    CHECK(p.model->open(kMat));  // the same document: nothing is read again
    CHECK(p.model->dirty());
    CHECK(p.model->node_count() == nodes);
    CHECK(p.model->revision() == rev);

    // a material with no graph: refused, and the document that was open is exactly as it was (edits included)
    p.write("materials/plain.material.json",
            R"({"format":"factoria.material/1","shader":"shaders/plain.surface.glsl"})");
    CHECK_FALSE(p.model->open("materials/plain.material.json"));
    CHECK(p.model->error().find("has no \"graph\"") != std::string::npos);
    CHECK(p.model->path() == kMat);
    CHECK(p.model->dirty());
    CHECK(p.model->node_count() == nodes);
    CHECK_FALSE(p.model->open("materials/missing.material.json"));
    CHECK(p.model->node_count() == nodes);

    // with the flag, the same file opens as a new graph
    CHECK(p.model->open("materials/plain.material.json", true));
    CHECK(p.model->path() == "materials/plain.material.json");
    CHECK(p.model->node_count() == 1);
}

TEST_CASE(
    "graph model: a graph with no nodes list is refused with its pointer and never crashes a document that is open") {
    GraphProject p;
    p.write("materials/empty.material.json",
            R"({"format":"factoria.material/1","shader":"shaders/e.surface.glsl","graph":{"links":[]}})");
    CHECK_FALSE(p.model->open("materials/empty.material.json"));
    CHECK(p.model->error().find("/graph/nodes") != std::string::npos);
    CHECK(p.model->error().find("material.graph.validate") != std::string::npos);
    CHECK_FALSE(p.model->is_open());
    CHECK(p.model->node_count() == 0);

    // the open document's file is replaced by one with no nodes: the next poll refuses it and keeps what is shown
    p.open();
    REQUIRE(p.model->node_count() == 4);
    p.write(kMat, R"({"format":"factoria.material/1","shader":"shaders/dissolve.surface.glsl","graph":{"links":[]}})");
    p.model->poll_external();
    CHECK(p.model->node_count() == 4);
    CHECK(p.model->node_index("noise") == 0);
    CHECK(p.model->node_type("out") != nullptr);
}
