// The Graph panel's logic with no window: the model whose edits are one undo step each, whose connects are type-checked
// by the same checker as material.graph.validate and whose save is material.graph.generate (graph_model.h).
#include <chrono>
#include <filesystem>
#include <fstream>
#include <set>

#include "doctest.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/material_graph.h"
#include "graph_model.h"
#include "graph_preview.h"

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

TEST_CASE("graph model: a new sprite graph material has the output of a sprite, its nodes and none of the 3D ones") {
    GraphProject p;
    GraphModel& m = *p.model;
    CHECK(m.new_material_name("sprite") == "assets/materials/sprite_graph.material.json");
    p.write("shaders/sprite_graph.fragment.glsl",
            "// mine\n");  // the snippet of the first name is somebody's: the next one
    CHECK(m.new_material_name("sprite") == "assets/materials/sprite_graph2.material.json");
    CHECK_FALSE(m.create("materials/sky.material.json", "sky").ok);  // no graph for that kind yet
    CHECK_FALSE(stdfs::exists(p.dir / "materials/sky.material.json"));

    const GraphEditOutcome made = m.create("materials/glow.material.json", "sprite");
    REQUIRE_MESSAGE(made.ok, made.error);
    CHECK(m.path() == "materials/glow.material.json");
    CHECK(m.report().kind == "sprite");
    CHECK(m.report().ok());
    CHECK_FALSE(m.dirty());
    const Json file = Json::parse(p.read("materials/glow.material.json"));
    CHECK(file["kind"] == "sprite");
    CHECK(file["shader"] == "shaders/glow.fragment.glsl");
    CHECK(file.contains("graphHash"));
    CHECK(p.read("shaders/glow.fragment.glsl").find("void fragment(in QuadInput i, inout QuadSurface s)") !=
          std::string::npos);
    const GraphNodeType* out = m.node_type("out");
    REQUIRE(out);
    REQUIRE_FALSE(out->inputs.empty());
    CHECK(out->inputs[0].name == "color");  // the output of a sprite, not the mesh's albedo

    // the palette offers the 2D nodes and the shared ones, never the 3D ones
    bool spriteColor = false, noise = false, fresnel = false, meshOutput = false;
    for (const GraphNodeType* t : m.palette("")) {
        spriteColor = spriteColor || t->type == "sprite.color";
        noise = noise || t->type == "noise.fbm";
        fresnel = fresnel || t->type == "fresnel" || t->type == "triplanar" || t->type == "position.world";
        meshOutput = meshOutput || (t->type == "output" && t->inputs[0].name == "albedo");
    }
    CHECK(spriteColor);
    CHECK(noise);
    CHECK_FALSE(fresnel);
    CHECK_FALSE(meshOutput);
    const GraphEditOutcome refused = m.add_node("fresnel", Vec2{0, 0});
    CHECK_FALSE(refused.ok);
    CHECK(refused.error.find("\"sprite\"") != std::string::npos);
    CHECK(refused.error.find("math.smoothstep") != std::string::npos);  // what to use instead
    CHECK(m.node_count() == 1);

    // a noise node into the alpha: the graph checks, saves, and the snippet follows
    const GraphEditOutcome added = m.add_node("noise.fbm", Vec2{0, 0});
    REQUIRE_MESSAGE(added.ok, added.error);
    const GraphEditOutcome linked = m.connect(added.id + ".value", "out.alpha");
    REQUIRE_MESSAGE(linked.ok, linked.error);
    CHECK(m.report().ok());
    CHECK(m.dirty());
    const GraphSaveOutcome saved = m.save(false);
    REQUIRE_MESSAGE(saved.ok, saved.error);
    CHECK(m.snippet_state() == "in_sync");
    CHECK(p.read("shaders/glow.fragment.glsl").find("s.color.a = n_noise_fbm_value;") != std::string::npos);

    // the mesh button is unchanged: a material with no kind is a mesh one
    const GraphEditOutcome mesh = m.create("materials/solid.material.json");
    REQUIRE_MESSAGE(mesh.ok, mesh.error);
    CHECK(m.report().kind == "mesh");
    CHECK_FALSE(Json::parse(p.read("materials/solid.material.json")).contains("kind"));
    CHECK(m.node_type("out")->inputs[0].name == "albedo");
}

TEST_CASE("graph model: a new post graph material starts as the picture unchanged, has the post nodes and none of the "
          "other kinds'") {
    GraphProject p;
    GraphModel& m = *p.model;
    CHECK(m.new_material_name("post") == "assets/materials/post_graph.material.json");
    p.write("shaders/post_graph.post.glsl", "// mine\n");  // the snippet of the first name is somebody's: the next one
    CHECK(m.new_material_name("post") == "assets/materials/post_graph2.material.json");

    const GraphEditOutcome made = m.create("materials/look.material.json", "post");
    REQUIRE_MESSAGE(made.ok, made.error);
    CHECK(m.report().kind == "post");
    CHECK(m.report().ok());
    CHECK_FALSE(m.dirty());
    CHECK(m.node_count() == 2);
    CHECK(m.link_count() == 1);
    const Json file = Json::parse(p.read("materials/look.material.json"));
    CHECK(file["kind"] == "post");
    CHECK(file["shader"] == "shaders/look.post.glsl");
    CHECK(file.contains("graphHash"));
    const std::string snippet = p.read("shaders/look.post.glsl");
    CHECK(snippet.find("void post(in PostInput i, inout PostSurface s)") != std::string::npos);
    CHECK(snippet.find("s.color.rgb = n_scene_rgb;") != std::string::npos);
    const GraphNodeType* out = m.node_type("out");
    REQUIRE(out);
    CHECK(out->inputs[0].name == "color");  // the output of a post pass, not the mesh's albedo

    bool history = false, other = false;
    for (const GraphNodeType* t : m.palette(""))
        if (t->type == "post.history") {
            history = true;
        } else if (t->type == "fresnel" || t->type == "sprite.color" || t->type == "position.world") {
            other = true;
        }
    CHECK(history);
    CHECK_FALSE(other);
    const GraphEditOutcome refused = m.add_node("sprite.color", Vec2{0, 0});
    CHECK_FALSE(refused.ok);
    CHECK(refused.error.find("\"post\"") != std::string::npos);
    CHECK(refused.error.find("post.scene") != std::string::npos);  // what to use instead
    CHECK(m.node_count() == 2);

    // a history node: the generated snippet asks for the history, and the save keeps the graph in step with it
    const GraphEditOutcome added = m.add_node("post.history", Vec2{0, 0});
    REQUIRE_MESSAGE(added.ok, added.error);
    const GraphEditOutcome linked = m.connect(added.id + ".rgb", "out.rgb");
    REQUIRE_MESSAGE(linked.ok, linked.error);
    CHECK(m.report().ok());
    const GraphSaveOutcome saved = m.save(false);
    REQUIRE_MESSAGE(saved.ok, saved.error);
    CHECK(m.snippet_state() == "in_sync");
    CHECK(p.read("shaders/look.post.glsl").find("fa_history(") != std::string::npos);
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

TEST_CASE("graph model: a second outside write of the same size, right after the first, is still found") {
    // Windows steps file times by ~15 ms: two writes in one step keep time and size, so a recent file is told by content.
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    Json doc = Json::parse(kDissolve);
    doc["graph"]["nodes"][0]["inputs"]["scale"] = 12.0;
    p.write(kMat, doc.dump(2));
    CHECK(m.poll_external());
    CHECK(m.input_value("noise", "scale") == 12.0);
    doc["graph"]["nodes"][0]["inputs"]["scale"] = 13.0;  // same number of characters
    p.write(kMat, doc.dump(2));
    CHECK(m.poll_external());
    CHECK(m.input_value("noise", "scale") == 13.0);
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

TEST_CASE("graph model: Set as default writes the file at once, is one undo step, and leaves the unsaved graph alone") {
    GraphProject p;
    p.open();
    const GraphEditOutcome added = p.model->add_node("math.add", Vec2{10, 10});
    REQUIRE(added.ok);
    REQUIRE(p.model->dirty());
    const std::uint64_t savedRev = p.model->saved_revision();

    const GraphEditOutcome set = p.model->set_param_default("dissolve", Json(0.4));
    REQUIRE_MESSAGE(set.ok, set.error);
    CHECK(set.step > 0);
    CHECK(p.model->saved_revision() != savedRev);
    CHECK(p.read(kMat).find("0.4") != std::string::npos);
    CHECK(p.model->dirty());  // the new node is still unsaved
    CHECK(p.model->node_count() == 5);
    CHECK_FALSE(p.model->poll_external());     // our own write is not an outside change
    auto default_of = [&](const char* name) {  // the parsed default (the clip material has an implicit alphaCutoff too)
        for (const MaterialParam& param : p.model->report().material.params)
            if (param.name == name) return param.defaultValue.get<double>();
        return -1.0;
    };
    CHECK(default_of("dissolve") == doctest::Approx(0.4));
    // the saved version has the new default and the graph as it was in the file
    const Json saved = p.model->saved_material_json();
    REQUIRE(saved.is_object());
    CHECK(saved["params"]["dissolve"]["default"].get<double>() == doctest::Approx(0.4));
    CHECK(saved["graph"]["nodes"].size() == 4);

    // the same value again writes nothing and makes no step
    const GraphEditOutcome again = p.model->set_param_default("dissolve", Json(0.4));
    CHECK(again.ok);
    CHECK(again.step == 0);

    // undo and redo go through the command too
    REQUIRE(p.model->apply_step(set.step, false));
    CHECK(p.read(kMat).find("0.4") == std::string::npos);
    CHECK(default_of("dissolve") == doctest::Approx(0.0));
    REQUIRE(p.model->apply_step(set.step, true));
    CHECK(p.read(kMat).find("0.4") != std::string::npos);

    // a file that changed behind our back: the step refuses
    p.write(kMat, std::string(kDissolve));
    REQUIRE(p.model->reload());
    CHECK_FALSE(p.model->apply_step(set.step, false));
    CHECK_FALSE(p.model->status().empty());

    // refused values: the checker's message, nothing written
    const GraphEditOutcome tooBig = p.model->set_param_default("dissolve", Json(7.0));
    CHECK_FALSE(tooBig.ok);
    const GraphEditOutcome unknown = p.model->set_param_default("dissolv", Json(0.1));
    CHECK_FALSE(unknown.ok);
    CHECK(unknown.error.find("dissolve") != std::string::npos);
}

TEST_CASE(
    "graph model: a param is made, renamed and deleted from the panel, each one undo step, and the nodes follow it") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    const std::uint64_t revision = m.revision();

    // create: the file has it at once, the read nodes can name it, the revision moves (the preview compiles again)
    const GraphEditOutcome made =
        m.add_entry(false, "glow", Json::object({{"type", "float"}, {"default", 0.5}, {"min", 0.0}, {"max", 1.0}}));
    REQUIRE_MESSAGE(made.ok, made.error);
    CHECK(made.step > 0);
    CHECK(m.revision() != revision);
    CHECK(Json::parse(p.read(kMat))["params"].contains("glow"));
    CHECK(m.material_json()["params"].contains("glow"));
    CHECK_FALSE(m.dirty());          // the graph was not touched
    CHECK_FALSE(m.poll_external());  // our own write is not an outside change
    const GraphEditOutcome used = m.add_node("param", Vec2{0, 300});
    REQUIRE_MESSAGE(used.ok, used.error);
    REQUIRE(m.set_ref(used.id, "glow").ok);
    CHECK(m.report().ok());
    CHECK(m.entry_readers(false, "glow") == std::vector<std::string>{used.id});

    // refused: taken, reserved, unknown type; nothing changes and no step is made
    const GraphEditOutcome dup = m.add_entry(false, "dissolve", Json::object({{"type", "float"}}));
    CHECK_FALSE(dup.ok);
    CHECK(dup.step == 0);
    CHECK(dup.error.find("already") != std::string::npos);
    const GraphEditOutcome reserved = m.add_entry(false, "gn_mix", Json::object({{"type", "float"}}));
    CHECK_FALSE(reserved.ok);
    CHECK(reserved.error.find("gn_") != std::string::npos);
    CHECK_FALSE(m.add_entry(false, "tint", Json::object({{"type", "flaot"}})).ok);
    CHECK_FALSE(Json::parse(p.read(kMat))["params"].contains("tint"));

    // rename: the nodes of the graph in memory (saved or not) read the new name
    const GraphEditOutcome renamed = m.rename_entry(false, "glow", "shine");
    REQUIRE_MESSAGE(renamed.ok, renamed.error);
    CHECK(m.node_count() == 5);
    CHECK(m.entry_readers(false, "shine") == std::vector<std::string>{used.id});
    CHECK(m.entry_readers(false, "glow").empty());
    CHECK(m.report().ok());
    CHECK(m.rename_entry(false, "shine", "shine").step == 0);  // the same name: nothing
    CHECK_FALSE(m.rename_entry(false, "shine", "dissolve").ok);
    CHECK_FALSE(m.rename_entry(false, "nope", "other").ok);

    // delete of a param that nodes read is refused and names them; the unused one goes
    const GraphEditOutcome refused = m.delete_entry(false, "shine");
    CHECK_FALSE(refused.ok);
    CHECK(refused.nodes == std::vector<std::string>{used.id});
    CHECK(Json::parse(p.read(kMat))["params"].contains("shine"));
    CHECK(m.delete_entry(false, "dissolve").nodes == std::vector<std::string>{"amount"});

    // undo and redo, in the order they were made
    REQUIRE(m.remove_nodes({used.id}).ok);
    const GraphEditOutcome gone = m.delete_entry(false, "shine");
    REQUIRE_MESSAGE(gone.ok, gone.error);
    CHECK_FALSE(Json::parse(p.read(kMat))["params"].contains("shine"));
    REQUIRE_MESSAGE(m.apply_step(gone.step, false), m.status());
    CHECK(Json::parse(p.read(kMat))["params"]["shine"]["default"] == 0.5);
    REQUIRE_MESSAGE(m.apply_step(gone.step, true), m.status());
    REQUIRE_MESSAGE(m.apply_step(gone.step, false), m.status());
    // (the node removal is a step of its own: its undo brings the reader back before the rename is undone)
    CHECK(m.entry_readers(false, "shine").empty());
    REQUIRE_MESSAGE(m.apply_step(renamed.step, false), m.status());
    CHECK(Json::parse(p.read(kMat))["params"].contains("glow"));
    REQUIRE_MESSAGE(m.apply_step(made.step, false), m.status());
    CHECK_FALSE(Json::parse(p.read(kMat))["params"].contains("glow"));
    REQUIRE_MESSAGE(m.apply_step(made.step, true), m.status());
    CHECK(Json::parse(p.read(kMat))["params"].contains("glow"));
    // the file changed behind our back: the step says so and changes nothing
    p.write(kMat, std::string(kDissolve));
    REQUIRE(m.reload());
    CHECK_FALSE(m.apply_step(made.step, false));
    CHECK_FALSE(m.status().empty());
}

TEST_CASE("graph model: a texture is made and deleted from the panel like a param") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    const GraphEditOutcome made = m.add_entry(true, "maskMap", Json::object({{"sampler", "linearRepeat"}}));
    REQUIRE_MESSAGE(made.ok, made.error);
    CHECK(Json::parse(p.read(kMat))["textures"].contains("maskMap"));
    const GraphEditOutcome renamed = m.rename_entry(true, "maskMap", "coverMap");
    REQUIRE_MESSAGE(renamed.ok, renamed.error);
    CHECK(Json::parse(p.read(kMat))["textures"].contains("coverMap"));
    const GraphEditOutcome gone = m.delete_entry(true, "coverMap");
    REQUIRE_MESSAGE(gone.ok, gone.error);
    CHECK_FALSE(Json::parse(p.read(kMat))["textures"].contains("coverMap"));  // the empty section stays
    REQUIRE(m.apply_step(gone.step, false));
    CHECK(Json::parse(p.read(kMat))["textures"].contains("coverMap"));
}

TEST_CASE(
    "graph model: linking an input to the output it already has makes no undo step; a drag checks the graph once") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    const Json before = m.graph();
    const GraphEditOutcome same = m.connect("amount.value", "burn.threshold");
    CHECK(same.ok);
    CHECK(same.step == 0);
    CHECK(m.graph() == before);
    const GraphEditOutcome other = m.connect("noise.value", "burn.threshold");
    CHECK(other.ok);
    CHECK(other.step > 0);

    // the checker does not run on every move of a drag: the report is the one of the graph when the drag began
    REQUIRE(m.apply_step(other.step, false));
    (void)m.report();
    const int runs = m.report_runs();
    m.begin_gesture();
    for (int i = 0; i < 20; ++i) {
        m.move_nodes({"noise"}, 1.0f, 0.0f);
        (void)m.report();
    }
    CHECK(m.report_runs() == runs);
    const GraphEditOutcome ended = m.end_gesture("Move node");
    CHECK(ended.step > 0);
    (void)m.report();
    CHECK(m.report_runs() == runs + 1);
}

TEST_CASE("graph model: a file that lost its graph is said once, not at every poll") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    p.write(
        kMat,
        R"({"format":"factoria.material/1","shader":"shaders/dissolve.surface.glsl","doc":"No graph any more, a longer text."})");
    CHECK(m.poll_external());
    CHECK(m.status().find("no \"graph\"") != std::string::npos);
    CHECK(m.node_count() == 4);  // the editor's copy stays
    CHECK(m.dirty());            // and is the only one: Save writes it back
    m.set_status("");
    CHECK_FALSE(m.poll_external());
    CHECK(m.status().empty());
    CHECK(m.error().empty());
}

TEST_CASE("graph model: Save does not replace a file that changed on disk unless it is told to") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    REQUIRE(m.set_input("noise", "scale", 2.0).ok);  // an unsaved edit
    Json outside = Json::parse(kDissolve);
    outside["graph"]["nodes"][0]["inputs"]["scale"] = 12.0;
    outside["doc"] = "Changed by someone else, with a longer text so the size differs.";
    const std::string theirs = outside.dump(2);
    p.write(kMat, theirs);
    // no poll ran (the panel polls every 20 frames): save looks at the file itself
    const GraphSaveOutcome refused = m.save(false);
    CHECK_FALSE(refused.ok);
    CHECK(refused.externalChange);
    CHECK_FALSE(refused.written);
    CHECK(refused.error.find("Overwrite") != std::string::npos);
    CHECK(p.read(kMat) == theirs);  // nothing was written
    CHECK(m.external_conflict());
    CHECK(m.dirty());
    CHECK(m.input_value("noise", "scale") == 2.0);
    // asking again without choosing is refused again
    CHECK(m.save(false).externalChange);
    // Overwrite: the graph as edited replaces the file
    const GraphSaveOutcome forced = m.save(false, true);
    CHECK_MESSAGE(forced.ok, forced.error);
    CHECK_FALSE(forced.externalChange);
    CHECK(Json::parse(p.read(kMat))["graph"]["nodes"][0]["inputs"]["scale"] == 2.0);
    CHECK_FALSE(m.external_conflict());
    CHECK_FALSE(m.dirty());
    CHECK(m.save(false).ok);  // our own write is not an outside change

    // Reload is the other answer: the file as it is, the edits gone
    REQUIRE(m.set_input("noise", "scale", 3.0).ok);
    p.write(kMat, theirs);
    CHECK(m.save(false).externalChange);
    REQUIRE(m.reload());
    CHECK(m.input_value("noise", "scale") == 12.0);
    CHECK_FALSE(m.external_conflict());
    REQUIRE(m.set_input("noise", "scale", 4.0).ok);
    // the other file has no graphHash for the snippet on disk, so the snippet is asked to be rewritten
    const GraphSaveOutcome last = m.save(true);
    CHECK_MESSAGE(last.ok, last.error);
}

TEST_CASE("graph model: our own writes do not hide an outside change the poll has not seen") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    Json outside = Json::parse(kDissolve);
    outside["doc"] = "Changed by someone else, with a longer text so the size differs.";
    p.write(kMat, outside.dump(2));
    // a default written through the panel (the file is read-modified-written by the command) must not take the outside
    // change for ours
    REQUIRE(m.set_param_default("dissolve", Json(0.4)).ok);
    CHECK(m.poll_external());
    CHECK(m.material_json().value("doc", std::string()).find("someone else") != std::string::npos);
    CHECK_FALSE(m.poll_external());  // once

    Json again = Json::parse(p.read(kMat));
    again["doc"] = "Changed again by someone else, with an even longer text than before.";
    p.write(kMat, again.dump(2));
    REQUIRE(m.add_entry(false, "glow", Json::object({{"type", "float"}, {"default", 0.5}})).ok);
    CHECK(m.poll_external());  // a param made through the panel does not swallow it either
    CHECK_FALSE(m.poll_external());
}

TEST_CASE(
    "graph model: a new material is published whole, never over a file, and leaves nothing behind when it fails") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    const std::string before = p.read(kMat);
    // an existing file is never touched, and no stray temporary stays next to it
    const GraphEditOutcome same = m.create(kMat);
    CHECK_FALSE(same.ok);
    CHECK(same.error.find("already exists") != std::string::npos);
    CHECK(p.read(kMat) == before);
    CHECK(m.path() == kMat);
    CHECK_FALSE(stdfs::exists(p.dir / "materials/dissolve.material.json.new.tmp"));
    // the snippet cannot be written (its name is a folder): the material file it made is removed again, the open
    // document stays
    stdfs::create_directories(p.dir / "shaders/broken.surface.glsl");
    const GraphEditOutcome broken = m.create("materials/broken.material.json");
    CHECK_FALSE(broken.ok);
    CHECK_FALSE(broken.error.empty());
    CHECK_FALSE(stdfs::exists(p.dir / "materials/broken.material.json"));
    CHECK_FALSE(stdfs::exists(p.dir / "materials/broken.material.json.new.tmp"));
    CHECK(stdfs::is_directory(p.dir / "shaders/broken.surface.glsl"));  // not ours: left alone
    CHECK(m.path() == kMat);
    CHECK(m.node_count() == 4);
    // and a good one still works afterwards, with no temporary left
    const GraphEditOutcome good = m.create("materials/fine.material.json");
    CHECK_MESSAGE(good.ok, good.error);
    CHECK(m.path() == "materials/fine.material.json");
    CHECK_FALSE(stdfs::exists(p.dir / "materials/fine.material.json.new.tmp"));
}

TEST_CASE("graph model: a new material never takes the name of a hand-written snippet, and the button's name is free "
          "for both") {
    GraphProject p;
    GraphModel& m = *p.model;
    CHECK(m.new_material_name() == "assets/materials/graph.material.json");
    p.write("shaders/graph.surface.glsl", "// mine\n");  // the snippet of graph.material.json is taken: the next name
    CHECK(m.new_material_name() == "assets/materials/graph2.material.json");
    p.write("assets/materials/graph2.material.json", "{}");
    CHECK(m.new_material_name() == "assets/materials/graph3.material.json");
    // create() itself: a snippet of that name is somebody's, nothing is written and nothing of it is deleted
    p.write("shaders/clash.surface.glsl", "// hand-written\n");
    const GraphEditOutcome clash = m.create("materials/clash.material.json");
    CHECK_FALSE(clash.ok);
    CHECK(clash.error.find("shaders/clash.surface.glsl") != std::string::npos);
    CHECK(clash.error.find("Pick another name") != std::string::npos);
    CHECK_FALSE(stdfs::exists(p.dir / "materials/clash.material.json"));
    CHECK(p.read("shaders/clash.surface.glsl") == "// hand-written\n");
    CHECK(m.new_material_name() == "assets/materials/graph3.material.json");
    const GraphEditOutcome made = m.create(m.new_material_name());
    CHECK_MESSAGE(made.ok, made.error);
}

TEST_CASE(
    "graph model: Overwrite answered once is not asked again for the snippet, and a deleted file is written again") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    REQUIRE(m.save(false).ok);
    // the snippet is edited by hand and the file is changed by someone else
    p.write("shaders/dissolve.surface.glsl", p.read("shaders/dissolve.surface.glsl") + "// my tweak\n");
    Json doc = Json::parse(p.read(kMat));
    doc["doc"] = "Changed by an AI, and long enough to change the size too.";
    p.write(kMat, doc.dump(2));
    REQUIRE(m.add_node("math.add", Vec2{10, 10}).ok);
    const GraphSaveOutcome conflict = m.save(false);
    CHECK(conflict.externalChange);
    // Overwrite of the file: now the snippet is the question
    const GraphSaveOutcome asked = m.save(false, true);
    CHECK_FALSE(asked.ok);
    CHECK(asked.needsForce);
    CHECK_FALSE(asked.externalChange);
    // the panel remembers the answer and passes it on: one question each, never the file's again
    const GraphSaveOutcome forced = m.save(true, true);
    REQUIRE_MESSAGE(forced.ok, forced.error);
    CHECK(p.read("shaders/dissolve.surface.glsl").find("my tweak") == std::string::npos);
    CHECK_FALSE(m.poll_external());  // a successful save leaves nothing for the poll to ask about
    CHECK_FALSE(m.external_conflict());

    // the file was deleted: Overwrite writes it again from the document that was read
    stdfs::remove(p.dir / kMat);
    REQUIRE(m.add_node("math.add", Vec2{10, 60}).ok);
    CHECK(m.save(false).externalChange);
    const GraphSaveOutcome again = m.save(false, true);
    REQUIRE_MESSAGE(again.ok, again.error);
    const Json back = Json::parse(p.read(kMat));
    CHECK(back["graph"]["nodes"].size() == 6);
    CHECK(back.contains("graphHash"));
    CHECK(back["shader"] == "shaders/dissolve.surface.glsl");
    CHECK(m.snippet_state() == "in_sync");

    // a hand-edited snippet and a deleted file: Overwrite writes the file, the generator then asks about the snippet.
    // The editor's own write is not an external change, so no conflict is left and the poll does not ask "The file
    // changed on disk" again
    p.write("shaders/dissolve.surface.glsl", p.read("shaders/dissolve.surface.glsl") + "// my tweak\n");
    stdfs::remove(p.dir / kMat);
    REQUIRE(m.add_node("math.add", Vec2{10, 110}).ok);
    CHECK(m.save(false).externalChange);
    const GraphSaveOutcome asked2 = m.save(false, true);
    CHECK_FALSE(asked2.ok);
    CHECK(asked2.needsForce);
    CHECK_FALSE(m.external_conflict());
    CHECK_FALSE(m.poll_external());
    CHECK_FALSE(m.external_conflict());
}

TEST_CASE("graph preview: errors name the material and the snippet, not the stage files that are gone") {
    const std::string text = "/p/.factoria/material-preview/stage-1-ab.surface.glsl:5:3: error: bad\n"
                             "stage-1-ab.material.json: /shader is not a file; stage-1-ab.surface.glsl\n";
    const std::string out = name_real_files(text, "/p", ".factoria/material-preview/stage-1-ab.material.json",
                                            ".factoria/material-preview/stage-1-ab.surface.glsl",
                                            "materials/dissolve.material.json", "shaders/dissolve.surface.glsl");
    CHECK(out.find("stage-1-ab") == std::string::npos);
    CHECK(out.find("shaders/dissolve.surface.glsl:5:3: error: bad") != std::string::npos);
    CHECK(out.find("/p") == std::string::npos);

    // the same on Windows, where a compiler prints the stage files with '\' or a mix of both
    const std::string win = "C:\\p\\.factoria\\material-preview\\stage-1-ab.surface.glsl:5:3: error: bad\n"
                            "C:/p\\.factoria\\material-preview\\stage-1-ab.material.json: /shader\n"
                            ".factoria\\material-preview\\stage-1-ab.surface.glsl\n";
    const std::string outWin = name_real_files(win, "C:/p", ".factoria/material-preview/stage-1-ab.material.json",
                                               ".factoria/material-preview/stage-1-ab.surface.glsl",
                                               "materials/dissolve.material.json", "shaders/dissolve.surface.glsl");
    CHECK(outWin.find("stage-1-ab") == std::string::npos);
    CHECK(outWin.find("material-preview") == std::string::npos);
    CHECK(outWin.find("shaders/dissolve.surface.glsl:5:3: error: bad") != std::string::npos);
    CHECK(outWin.find("materials/dissolve.material.json: /shader") != std::string::npos);
}

TEST_CASE("graph preview: stage files an editor left behind are removed once they are old, and nothing else is") {
    GraphProject p;
    const stdfs::path dir = p.dir / ".factoria/material-preview";
    p.write(".factoria/material-preview/stage-7-aa.material.json", "{}");
    p.write(".factoria/material-preview/stage-7-aa.surface.glsl", "x");
    p.write(".factoria/material-preview/saved-stage-7-aa.surface.glsl", "x");
    p.write(".factoria/material-preview/stage-7-aa.post.glsl", "x");  // the snippet of a post material's compile
    p.write(".factoria/material-preview/stage-8-bb.surface.glsl",
            "x");                                                       // a recent one: another editor may be compiling
    p.write(".factoria/material-preview/preview.material.json", "{}");  // the live copies stay, old or not
    p.write(".factoria/material-preview/stage-notes.txt", "x");         // not a stage file
    const auto old = stdfs::file_time_type::clock::now() - std::chrono::hours(2);
    for (const char* f : {"stage-7-aa.material.json", "stage-7-aa.surface.glsl", "saved-stage-7-aa.surface.glsl",
                          "stage-7-aa.post.glsl", "preview.material.json", "stage-notes.txt"})
        stdfs::last_write_time(dir / f, old);
    CHECK(GraphPreview::remove_stale_stage_files(p.dir.generic_string()) == 4);
    CHECK_FALSE(stdfs::exists(dir / "stage-7-aa.material.json"));
    CHECK_FALSE(stdfs::exists(dir / "stage-7-aa.surface.glsl"));
    CHECK_FALSE(stdfs::exists(dir / "saved-stage-7-aa.surface.glsl"));
    CHECK_FALSE(stdfs::exists(dir / "stage-7-aa.post.glsl"));
    CHECK(stdfs::exists(dir / "stage-8-bb.surface.glsl"));
    CHECK(stdfs::exists(dir / "preview.material.json"));
    CHECK(stdfs::exists(dir / "stage-notes.txt"));
    // the constructor does it: no error for a project with no such folder, and an old file goes
    GraphProject q;
    GraphPreview none(q.dir.generic_string());
    p.write(".factoria/material-preview/stage-9-cc.material.json", "{}");
    stdfs::last_write_time(dir / "stage-9-cc.material.json", old);
    GraphPreview made(p.dir.generic_string());
    CHECK_FALSE(stdfs::exists(dir / "stage-9-cc.material.json"));
}

TEST_CASE("graph model: undo of a delete puts the param back in its place; what the command warns about is shown") {
    GraphProject p;
    p.open();
    GraphModel& m = *p.model;
    for (const char* name : {"zeta", "alpha", "mid"})
        REQUIRE(m.add_entry(false, name, Json::object({{"type", "float"}, {"default", 0.5}})).ok);
    auto order = [&] {
        std::vector<std::string> names;
        const Json file = Json::parse(p.read(kMat));  // kept alive: items() only refers to it
        for (const auto& item : file["params"].items()) names.push_back(item.key());
        return names;
    };
    CHECK(order() == std::vector<std::string>{"dissolve", "zeta", "alpha", "mid"});
    const GraphEditOutcome gone = m.delete_entry(false, "alpha");
    REQUIRE_MESSAGE(gone.ok, gone.error);
    CHECK(order() == std::vector<std::string>{"dissolve", "zeta", "mid"});
    REQUIRE(m.apply_step(gone.step, false));
    CHECK(order() == std::vector<std::string>{"dissolve", "zeta", "alpha", "mid"});  // not at the end
    REQUIRE(m.apply_step(gone.step, true));
    CHECK(order() == std::vector<std::string>{"dissolve", "zeta", "mid"});

    // a snippet nobody generates that still uses the old name: the rename goes through and says so
    p.write("shaders/dissolve.surface.glsl", "void main() { float x = zeta; }\n");
    const GraphEditOutcome renamed = m.rename_entry(false, "zeta", "omega");
    REQUIRE_MESSAGE(renamed.ok, renamed.error);
    CHECK(renamed.note.find("zeta") != std::string::npos);
    CHECK(m.status() == renamed.note);
    // an edit that has nothing to say clears it
    const GraphEditOutcome quiet = m.add_entry(false, "calm", Json::object({{"type", "float"}, {"default", 0.5}}));
    REQUIRE(quiet.ok);
    CHECK(quiet.note.empty());
    CHECK(m.status().empty());
}

TEST_CASE("graph preview: a kind it never draws says why even with no GPU renderer, the others say there is none") {
    GraphProject p;
    GraphPreview pv(p.dir.generic_string());
    pv.set_document(Json::parse(R"({"format":"factoria.material/1","kind":"sky","shader":"shaders/a.sky.glsl"})"), 1);
    pv.tick(nullptr);
    CHECK(pv.state() == PreviewState::Unsupported);
    CHECK(pv.message().find("skyMaterial") != std::string::npos);
    pv.set_document(Json::parse(R"({"format":"factoria.material/1","shader":"shaders/a.surface.glsl"})"), 2);
    pv.tick(nullptr);
    CHECK(pv.state() == PreviewState::NoRenderer);
    // a post material is drawn like the others (a camera's pass over a small scene): with no GPU it says there is none
    pv.set_document(Json::parse(R"({"format":"factoria.material/1","kind":"post","shader":"shaders/a.post.glsl"})"), 3);
    pv.tick(nullptr);
    CHECK(pv.state() == PreviewState::NoRenderer);
    CHECK(pv.message().find("PostProcess.customPasses") == std::string::npos);
}

TEST_CASE("graph preview: every instance stages its compile in files of its own") {
    GraphProject p;
    GraphPreview a(p.dir.generic_string());
    GraphPreview b(p.dir.generic_string());
    CHECK(a.stage_material_path() != b.stage_material_path());
    CHECK(a.stage_material_path().find("stage-") != std::string::npos);
}

TEST_CASE("graph model: the saved version is the graph as last read from the file; a draft has none") {
    GraphProject p;
    p.open();
    CHECK(p.model->has_saved());
    const std::uint64_t first = p.model->saved_revision();
    REQUIRE(p.model->add_node("math.add", Vec2{10, 10}).ok);
    CHECK(p.model->saved_revision() == first);  // an edit is not a new saved version
    CHECK(p.model->saved_material_json()["graph"]["nodes"].size() == 4);
    REQUIRE(p.model->save(false).ok);
    CHECK(p.model->saved_revision() != first);
    CHECK(p.model->saved_material_json()["graph"]["nodes"].size() == 5);

    p.write("materials/plain.material.json",
            R"({"format":"factoria.material/1","shader":"shaders/plain.surface.glsl"})");
    REQUIRE(p.model->open("materials/plain.material.json", true));
    CHECK_FALSE(p.model->has_saved());
    CHECK(p.model->saved_material_json().is_null());
}

TEST_CASE("graph preview: which kinds it draws, which it says why not") {
    CHECK(preview_plan("mesh").kind == PreviewKind::Mesh);
    CHECK(preview_plan("sprite").kind == PreviewKind::Sprite);
    CHECK(preview_plan("post").kind == PreviewKind::Post);
    CHECK(preview_plan("post").reason.empty());
    for (const char* kind : {"sky", "compute"}) {
        const PreviewPlan plan = preview_plan(kind);
        CHECK(plan.kind == PreviewKind::None);
        CHECK_FALSE(plan.reason.empty());
    }
    CHECK(preview_plan("sky").reason.find("skyMaterial") != std::string::npos);
    CHECK(preview_plan("hologram").kind == PreviewKind::Unknown);
}

TEST_CASE("graph preview: overrides keep only the params that still exist, with the right number of components") {
    const Json material = Json::parse(R"({"params":{
        "a":{"type":"float","default":0.5},
        "b":{"type":"vec2","default":[0,0]},
        "c":{"type":"vec3","default":[0,0,0]},
        "tint":{"type":"color","default":[1,1,1,1]}}})");
    const Json overrides = Json::parse(R"({"a":0.25,"b":[1,2],"c":[1,2],"tint":[1,0,0,1],"gone":3,"d":"x"})");
    const Json kept = GraphPreview::fitting_overrides(overrides, material);
    CHECK(kept.contains("a"));
    CHECK(kept.contains("b"));
    CHECK_FALSE(kept.contains("c"));  // vec3 needs three numbers
    CHECK(kept.contains("tint"));
    CHECK_FALSE(kept.contains("gone"));  // no such param any more
    CHECK_FALSE(kept.contains("d"));
    CHECK(GraphPreview::fitting_overrides(overrides, Json::object()).empty());
}

TEST_CASE("graph preview: compile errors on a node's line name the node, the others stay out") {
    const std::vector<std::string> lineNodes = {"", "", "noise", "noise", "", "burn", "out"};
    ShaderIssue onNode;
    onNode.line = 4;
    onNode.message = "undeclared identifier";
    onNode.hint = "declare it";
    ShaderIssue onHelper;
    onHelper.line = 1;
    onHelper.message = "bad helper";
    ShaderIssue ofFile;  // a JSON error of the material: no line
    ofFile.message = "bad json";
    ShaderIssue outside;
    outside.line = 99;
    outside.message = "past the end";
    const ShaderIssue second = onNode;  // the same line twice: one entry
    const std::vector<PreviewNodeError> errors =
        map_compile_errors({onNode, onHelper, ofFile, outside, second}, lineNodes);
    REQUIRE(errors.size() == 1);
    CHECK(errors[0].node == "noise");
    CHECK(errors[0].line == 4);
    CHECK(errors[0].message.find("undeclared identifier") != std::string::npos);
    CHECK(errors[0].message.find("declare it") != std::string::npos);
    CHECK(map_compile_errors({}, lineNodes).empty());
}
