// The inverse builders of the editor's Command undo entries (undo_inverse.h), against a real headless Engine in a temporary
// project: the forward call, then the inverse, gives back the scene JSON exactly. GPU-free.
#include <algorithm>
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/authoring/authoring.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/serialize.h"
#include "fa/scene/terrain.h"
#include "undo_stack.h"
#include "fa/ui/ui.h"
#include "undo_inverse.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Undo Inverse Test",
  "id": "com.example.undoinverse",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// hero and target carry RigidBody2D because Joint2D needs a body on its entity.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "hero", "name": "Hero", "tags": ["player"],
      "components": { "Transform": { "position": [10, 20, 0] }, "RigidBody2D": {}, "Shape2D": { "size": [30, 20], "color": "#cc3030" },
                      "Script": { "props": { "speed": 3, "label": "x" } }, "UiControl": {} } },
    { "id": "target", "name": "Target", "components": { "Transform": { "position": [50, 0, 0] }, "RigidBody2D": {}, "Joint2D": { "connected": "hero" } } }
  ]
})";

// The structural edits: a subtree with references between entities (Joint3D.connected, InteractableVisual.target) in both
// directions, a prefab instance, a Panel that lays out its children, parents with different transforms.
const char* kStructScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "anchor", "name": "Anchor", "components": { "Transform": { "position": [5, 0, 0] } } },
    { "id": "link", "name": "Link", "components": { "Joint3D": { "connected": "gunner" } } },
    { "id": "squad", "name": "Squad", "tags": ["enemy"],
      "components": { "Transform": { "position": [120, 40, 0], "rotation": [0, 0, 30], "scale": [2, 2, 1] }, "Shape2D": { "size": [30, 20] } },
      "children": [
        { "id": "gunner", "name": "Gunner", "components": { "Transform": { "position": [10, 5, 0] }, "Joint3D": { "connected": "anchor" } } },
        { "id": "medic", "name": "Medic", "components": { "Transform": { "position": [-10, 5, 0] }, "Joint3D": { "connected": "gunner" } } }
      ] },
    { "id": "holder", "name": "Holder", "components": { "Transform": { "position": [-40, 10, 0], "scale": [0.5, 0.5, 1] } }, "children": [
      { "id": "pair_a", "name": "A", "components": { "Joint3D": { "connected": "pair_b" } },
        "children": [ { "id": "pair_c", "components": { "Joint3D": { "connected": "pair_a" } } } ] },
      { "id": "pair_b", "name": "B" },
      { "id": "pair_d", "name": "D" }
    ] },
    { "prefab": "prefabs/pair.prefab.json", "id": "inst", "components": { "Transform": { "position": [7, 8, 0] } } },
    { "id": "hud", "name": "Hud", "components": { "Transform": { "position": [10, 10, 0] }, "Panel": { "layout": "column", "size": [200, 150], "padding": [10, 10, 10, 10] } },
      "children": [
        { "id": "ok", "name": "Ok", "components": { "Transform": { "position": [3, 4, 0] }, "Button": { "size": [100, 20] } } },
        { "id": "tint", "name": "Tint", "components": { "InteractableVisual": { "target": "ok" } } },
        { "id": "cancel", "name": "Cancel", "components": { "Button": { "size": [60, 30] } } }
      ] },
    { "id": "free", "name": "Free", "components": { "Transform": { "position": [300, 100, 0] } } }
  ]
})";

const char* kPrefab = R"({
  "format": "factoria.prefab/1",
  "entity": { "id": "pair", "name": "Pair", "components": { "Transform": { "position": [1, 2, 0] } },
              "children": [ { "id": "left", "name": "Left" }, { "id": "right", "name": "Right" } ] }
})";

struct Session {
    stdfs::path dir;
    Engine engine;
    explicit Session(const char* scene = kScene) {
        static const bool installed = (fa::authoring::install(), true);  // scene.paste_entities, bones.create
        (void)installed;
        dir = fs::make_temp_dir("fa_undo_inverse").value();
        stdfs::create_directories(dir / "scenes");
        stdfs::create_directories(dir / "prefabs");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << scene;
        std::ofstream(dir / "prefabs/pair.prefab.json", std::ios::binary) << kPrefab;
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.editorMode = true;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
    }
    ~Session() {
        engine.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    World& world() { return engine.world(); }
    Json scene() { return snapshot_scene(world()); }
    bool run(const std::vector<UndoCommand>& cmds) {
        for (const UndoCommand& c : cmds)
            if (!engine.commands().call(c.cmd, c.args).ok) return false;
        return true;
    }
    // Destroys the top-level entities after `id`, so that `id` is the last one: only the last top-level entity (or a child)
    // gets a destroy plan, since the others would come back last among the roots.
    void trim_roots_after(const char* id) {
        const std::vector<Entity> roots = world().roots();
        bool after = false;
        for (Entity r : roots) {
            const std::string rid = world().id_of(r);
            if (after) REQUIRE(engine.commands().call("scene.destroy", Json::object({{"id", rid}})).ok);
            if (rid == id) after = true;
        }
        REQUIRE(after);
    }
    std::vector<std::string> root_ids() {
        std::vector<std::string> out;
        for (Entity r : world().roots()) out.push_back(world().id_of(r));
        return out;
    }
    // The real call, as Editor::edit_command makes it: plan, run, finish; then undo, redo, undo through the plan's lists.
    // Returns the plan.
    UndoPlan edit_round_trip(const std::string& name, const Json& args) {
        INFO(name << " " << args.dump());
        auto snap = [&] { return scene(); };
        const Json before = snap();
        std::optional<UndoPlan> plan = plan_undo(world(), name, args);
        REQUIRE(plan.has_value());
        const CommandResult r = engine.commands().call(name, args);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        REQUIRE(finish_undo_plan(world(), name, *plan, r.result));
        const Json after = snap();
        CHECK(after != before);
        REQUIRE(run(plan->inverse));
        CHECK(snap() == before);
        REQUIRE(run(plan->forward));
        CHECK(snap() == after);
        REQUIRE(run(plan->inverse));
        CHECK(snap() == before);
        return *plan;
    }
    // Plans `name(args)`, applies the forward commands, and checks that the inverse gives the scene back and the forward
    // again gives the edited scene.
    void round_trip(const std::string& name, const Json& args, bool expectChange = true) {
        INFO(name << " " << args.dump());
        const Json before = scene();
        const std::optional<UndoPlan> plan = plan_undo(world(), name, args);
        REQUIRE(plan.has_value());
        REQUIRE(run(plan->forward));
        const Json after = scene();
        if (expectChange) CHECK(after != before);
        REQUIRE(run(plan->inverse));
        CHECK(scene() == before);
        REQUIRE(run(plan->forward));
        CHECK(scene() == after);
        REQUIRE(run(plan->inverse));
        CHECK(scene() == before);
    }
};

Json set_args(const std::string& id, const std::string& component, Json fields, bool merge = false) {
    Json a = Json::object({{"id", id}, {"component", component}, {"fields", std::move(fields)}});
    if (merge) a["merge"] = true;
    return a;
}

}  // namespace

TEST_CASE("undo inverse: set_component of a field gives the old value back") {
    Session s;
    s.round_trip("scene.set_component",
                 set_args("hero", "Transform", Json::object({{"position", Json::array({1, 2, 3})}})));
    s.round_trip("scene.set_component",
                 set_args("hero", "Shape2D", Json::object({{"color", "#00ff00"}, {"shape", "circle"}})));
    s.round_trip("scene.set_component",
                 set_args("hero", "EntityInfo", Json::object({{"name", "Renamed"}, {"active", false}})));
    s.round_trip("scene.set_component",
                 set_args("hero", "EntityInfo", Json::object({{"tags", Json::array({"a", "b"})}})));
    // the entity named by its display name: the plan spells the id out
    const auto plan = plan_undo(s.world(), "scene.set_component",
                                set_args("Hero", "Transform", Json::object({{"position", Json::array({1, 1, 1})}})));
    REQUIRE(plan.has_value());
    CHECK(plan->forward[0].args["id"] == "hero");
    CHECK(plan->inverse[0].args["id"] == "hero");
    // the inverse holds exactly the fields the call names
    CHECK(plan->inverse[0].args["fields"].size() == 1);
    CHECK(plan->inverse[0].args["fields"]["position"] == Json::array({10, 20, 0}));
}

TEST_CASE("undo inverse: set_component with merge restores a Json field as a whole") {
    Session s;
    s.round_trip(
        "scene.set_component",
        set_args("hero", "Script", Json::object({{"props", Json::object({{"speed", 9}, {"label", nullptr}})}}), true));
    s.round_trip("scene.set_component",
                 set_args("hero", "Script", Json::object({{"props", Json::object({{"extra", 1}})}})));
}

TEST_CASE("undo inverse: an Entity field, and merge with null on a plain field") {
    Session s;
    const auto plan = plan_undo(s.world(), "scene.set_component",
                                set_args("target", "Joint2D", Json::object({{"connected", "target"}})));
    REQUIRE(plan.has_value());
    CHECK(plan->inverse[0].args["fields"]["connected"] == "hero");  // the id, not a handle
    s.round_trip("scene.set_component", set_args("target", "Joint2D", Json::object({{"connected", "target"}})));
    s.round_trip("scene.set_component", set_args("target", "Joint2D", Json::object({{"connected", ""}})));
    // merge:true with null on a plain field: the inverse still holds the whole old value
    const auto m = plan_undo(s.world(), "scene.set_component",
                             set_args("hero", "Shape2D", Json::object({{"color", nullptr}}), true));
    REQUIRE(m.has_value());
    CHECK(m->inverse[0].args["fields"]["color"].is_array());  // the whole old colour, not null
    CHECK(m->forward[0].args["merge"] == true);
    s.round_trip("scene.set_component", set_args("hero", "Shape2D", Json::object({{"color", nullptr}}), true));
}

TEST_CASE("undo inverse: a runtime or read-only field gives no plan") {
    Session s;
    CHECK_FALSE(
        plan_undo(s.world(), "scene.set_component", set_args("hero", "UiControl", Json::object({{"focused", true}})))
            .has_value());
    CHECK_FALSE(
        plan_undo(s.world(), "scene.set_component", set_args("hero", "UiControl", Json::object({{"hovered", true}})))
            .has_value());
}

TEST_CASE("undo inverse: a call by name after a rename names the entity by its id") {
    Session s;
    const auto before = plan_undo(s.world(), "scene.set_component",
                                  set_args("Hero", "Transform", Json::object({{"scale", Json::array({2, 2, 2})}})));
    REQUIRE(before.has_value());
    CHECK(before->forward[0].args["id"] == "hero");
    REQUIRE(s.run(
        plan_undo(s.world(), "scene.set_component", set_args("hero", "EntityInfo", Json::object({{"name", "Renamed"}})))
            ->forward));
    // the plan made before the rename still runs: it holds the id
    CHECK(s.run(before->forward));
    CHECK(s.run(before->inverse));
    const auto after = plan_undo(s.world(), "scene.set_component",
                                 set_args("Renamed", "Transform", Json::object({{"scale", Json::array({3, 3, 3})}})));
    REQUIRE(after.has_value());
    CHECK(after->forward[0].args["id"] == "hero");
    CHECK(after->forward[0].target == before->forward[0].target);
    CHECK_FALSE(plan_undo(s.world(), "scene.set_component",
                          set_args("Hero", "Transform", Json::object({{"scale", Json::array({3, 3, 3})}})))
                    .has_value());
}

TEST_CASE("undo inverse: a component that was absent is removed again, and a removed one comes back whole") {
    Session s;
    const Json add = set_args("target", "Shape2D", Json::object({{"size", Json::array({8, 9})}}));
    const auto plan = plan_undo(s.world(), "scene.set_component", add);
    REQUIRE(plan.has_value());
    CHECK(plan->inverse[0].cmd == "scene.remove_component");
    s.round_trip("scene.set_component", add);
    s.round_trip("scene.set_component", set_args("target", "Light", Json::object()));
    const Json remove = Json::object({{"id", "hero"}, {"component", "Shape2D"}});
    s.round_trip("scene.remove_component", remove);
    s.round_trip("scene.remove_component", Json::object({{"id", "hero"}, {"component", "Script"}}));
    const auto rm = plan_undo(s.world(), "scene.remove_component", remove);
    REQUIRE(rm.has_value());
    CHECK(rm->inverse[0].cmd == "scene.set_component");
    CHECK(rm->inverse[0].args["fields"].contains("color"));
}

TEST_CASE("undo inverse: postprocess.set and postprocess.apply_preset are one undo step each") {
    Session s;
    CHECK(has_undo_builder("postprocess.set"));
    CHECK(has_undo_builder("postprocess.apply_preset"));
    // The component the entity did not have is added, and removed again by undo.
    const Json set =
        Json::object({{"id", "hero"}, {"fields", Json::object({{"bloomEnabled", true}, {"bloomIntensity", 0.4}})}});
    const auto plan = plan_undo(s.world(), "postprocess.set", set);
    REQUIRE(plan.has_value());
    CHECK(plan->inverse[0].cmd == "scene.remove_component");
    CHECK(plan->forward[0].args["component"] == "PostProcess");
    s.round_trip("postprocess.set", set);
    // With the component there, undo gives back exactly the named fields; merge null resets.
    REQUIRE(s.engine.commands().call("postprocess.set", set).ok);
    const Json second = Json::object({{"id", "hero"}, {"fields", Json::object({{"bloomIntensity", 2.5}})}});
    s.round_trip("postprocess.set", second);
    const Json reset =
        Json::object({{"id", "hero"}, {"fields", Json::object({{"bloomIntensity", nullptr}})}, {"merge", true}});
    s.round_trip("postprocess.set", reset);
    // The custom passes are replaced as a whole and come back exactly (an add, a reorder or a removal is one such
    // call).
    s.round_trip(
        "postprocess.set",
        Json::object({{"id", "hero"},
                      {"fields", Json::object({{"customPasses", Json::parse(R"([{"material":"materials/a.material.json",
                                                             "materialParams":{"amount":0.5},"position":"after:bloom"},
                                                             {"material":"materials/b.material.json","enabled":false}])")}})}}));
    // A preset writes every effect field (replace) or only its own (keep); both undo to the scene as it was.
    s.round_trip("postprocess.apply_preset", Json::object({{"id", "hero"}, {"preset", "noir"}}));
    s.round_trip("postprocess.apply_preset", Json::object({{"id", "hero"}, {"preset", "vivid"}, {"keep", true}}));
    s.round_trip("postprocess.apply_preset", Json::object({{"id", "target"}, {"preset", "cinematic"}}));
    const auto replace =
        plan_undo(s.world(), "postprocess.apply_preset", Json::object({{"id", "hero"}, {"preset", "noir"}}));
    const auto keep = plan_undo(s.world(), "postprocess.apply_preset",
                                Json::object({{"id", "hero"}, {"preset", "noir"}, {"keep", true}}));
    REQUIRE(replace.has_value());
    REQUIRE(keep.has_value());
    CHECK(replace->inverse[0].args["fields"].size() > keep->inverse[0].args["fields"].size());
    CHECK_FALSE(plan_undo(s.world(), "postprocess.apply_preset", Json::object({{"id", "hero"}, {"preset", "nope"}}))
                    .has_value());
    CHECK_FALSE(plan_undo(s.world(), "postprocess.apply_preset", Json::object({{"id", "nobody"}, {"preset", "noir"}}))
                    .has_value());
}

TEST_CASE("undo inverse: a call that is wrong, or has no builder, gives no plan") {
    Session s;
    CHECK_FALSE(
        plan_undo(s.world(), "scene.set_component", set_args("nobody", "Transform", Json::object())).has_value());
    CHECK_FALSE(
        plan_undo(s.world(), "scene.set_component", set_args("hero", "NoSuchComponent", Json::object())).has_value());
    CHECK_FALSE(plan_undo(s.world(), "scene.set_component", set_args("hero", "Transform", Json::object({{"nope", 1}})))
                    .has_value());
    CHECK_FALSE(
        plan_undo(s.world(), "scene.set_component", set_args("hero", "EntityInfo", Json::object({{"id", "other"}})))
            .has_value());
    CHECK_FALSE(
        plan_undo(s.world(), "scene.remove_component", Json::object({{"id", "hero"}, {"component", "Transform"}}))
            .has_value());
    CHECK_FALSE(plan_undo(s.world(), "scene.remove_component", Json::object({{"id", "hero"}, {"component", "Light"}}))
                    .has_value());
    CHECK_FALSE(plan_undo(s.world(), "scene.spawn", Json::object()).has_value());
    CHECK(has_undo_builder("scene.set_component"));
    CHECK(has_undo_builder("scene.remove_component"));
    CHECK_FALSE(has_undo_builder("scene.import_ascii"));
}

TEST_CASE("undo inverse: the forward command carries a target that names what it sets") {
    Session s;
    const auto a = plan_undo(s.world(), "scene.set_component",
                             set_args("hero", "Transform", Json::object({{"position", Json::array({1, 2, 3})}})));
    const auto b = plan_undo(s.world(), "scene.set_component",
                             set_args("Hero", "Transform", Json::object({{"position", Json::array({4, 5, 6})}})));
    const auto c = plan_undo(s.world(), "scene.set_component",
                             set_args("hero", "Transform", Json::object({{"scale", Json::array({2, 2, 2})}})));
    const auto d = plan_undo(s.world(), "scene.set_component",
                             set_args("target", "Transform", Json::object({{"position", Json::array({4, 5, 6})}})));
    REQUIRE((a && b && c && d));
    CHECK_FALSE(a->forward[0].target.empty());
    CHECK(a->forward[0].target == b->forward[0].target);
    CHECK(a->forward[0].target != c->forward[0].target);
    CHECK(a->forward[0].target != d->forward[0].target);
}

TEST_CASE("undo inverse: 100 plans cost far less than one snapshot of a big scene") {
    Session s;
    // a scene as big as a real level: a thousand entities with a few components each
    for (int i = 0; i < 1000; ++i)
        REQUIRE(s.engine.commands()
                    .call("scene.spawn",
                          Json::object(
                              {{"name", "e" + std::to_string(i)},
                               {"components",
                                Json::object(
                                    {{"Transform", Json::object({{"position", Json::array({i, 5, 0})}})},
                                     {"Shape2D", Json::object({{"size", Json::array({8, 9})}, {"color", "#336699"}})},
                                     {"Script",
                                      Json::object({{"props", Json::object({{"speed", 3}, {"label", "enemy"}})}})}})}}))
                    .ok);
    const size_t sceneBytes = estimate_json_bytes(s.scene());
    UndoStack st;
    for (int i = 0; i < 100; ++i) {
        const Json args =
            set_args("e" + std::to_string(i), "Transform", Json::object({{"position", Json::array({i, 0, 0})}}));
        std::optional<UndoPlan> plan = plan_undo(s.world(), "scene.set_component", args);
        REQUIRE(plan.has_value());
        st.push_command(std::move(plan->forward), std::move(plan->inverse), false);
    }
    CHECK(st.size() == 100);
    INFO(st.bytes() << " bytes of 100 entries against " << sceneBytes << " of one snapshot");
    CHECK(st.bytes() * 4 < sceneBytes);
}

// ---------------------------------------------------------------------------------------------------- structure ----

TEST_CASE("undo inverse: structural commands have builders, the large ones stay snapshots") {
    for (const char* name :
         {"scene.spawn", "scene.destroy", "scene.set_parent", "scene.paste_entities", "bones.create"})
        CHECK(has_undo_builder(name));
    for (const char* name : {"scene.import_ascii", "scene.ascii_edit", "skin.set_weights"})
        CHECK_FALSE(has_undo_builder(name));
}

TEST_CASE("undo inverse: destroy brings the subtree back with its ids, order, components and references") {
    {
        // a subtree: the children, a Joint3D that names an entity outside it and one inside, and a reference from OUTSIDE into it
        Session s(kStructScene);
        s.trim_roots_after("squad");
        s.edit_round_trip("scene.destroy", Json::object({{"id", "squad"}}));
    }
    {
        Session s(kStructScene);
        // a child in the middle of its siblings goes back to its place (index 0 of holder)
        s.edit_round_trip("scene.destroy", Json::object({{"id", "pair_a"}}));
        s.edit_round_trip("scene.destroy", Json::object({{"id", "pair_b"}}));
    }
    {
        Session s(kStructScene);
        s.trim_roots_after("holder");
        s.edit_round_trip("scene.destroy", Json::object({{"id", "holder"}}));
    }
    {
        Session s(kStructScene);
        s.edit_round_trip("scene.destroy", Json::object({{"id", "Free"}}));  // by name; the last top-level entity
    }
    Session s(kStructScene);
    // the reference from outside is set again, with the entity itself
    const auto plan = plan_undo(s.world(), "scene.destroy", Json::object({{"id", "gunner"}}));
    REQUIRE(plan.has_value());
    bool setsLink = false;
    for (const UndoCommand& c : plan->inverse)
        setsLink = setsLink || (c.cmd == "scene.set_component" && c.args["id"] == "link" &&
                                c.args["fields"]["connected"] == "gunner");
    CHECK(setsLink);
    CHECK(plan->inverse[0].cmd == "scene.paste_entities");
    CHECK(plan->inverse[0].args["text"].is_string());
}

TEST_CASE(
    "undo inverse: a top-level entity before other top-level ones has no plan, so the order of the roots is kept") {
    Session s(kStructScene);
    const std::vector<std::string> order = s.root_ids();
    REQUIRE(order.size() >= 4);
    // not the last root: an inverse would put it last (the order of the roots is the file's order and the drawing ties')
    for (size_t i = 0; i + 1 < order.size(); ++i)
        CHECK_FALSE(plan_undo(s.world(), "scene.destroy", Json::object({{"id", order[i]}})).has_value());
    // the last root and a child have one
    CHECK(plan_undo(s.world(), "scene.destroy", Json::object({{"id", order.back()}})).has_value());
    CHECK(plan_undo(s.world(), "scene.destroy", Json::object({{"id", "gunner"}})).has_value());
    // undo of the last one, and of a child, leaves the roots exactly in the order they had (no sorting)
    s.edit_round_trip("scene.destroy", Json::object({{"id", order.back()}}));
    CHECK(s.root_ids() == order);
    s.edit_round_trip("scene.destroy", Json::object({{"id", "gunner"}}));
    CHECK(s.root_ids() == order);
    // a root moved under a parent and back keeps its place
    const UndoPlan plan = s.edit_round_trip("scene.set_parent", Json::object({{"id", order[1]}, {"parent", "anchor"}}));
    (void)plan;
    CHECK(s.root_ids() == order);
}

TEST_CASE("undo inverse: the ids and handles are the same after undo, and a field names the entity again") {
    Session s(kStructScene);
    s.trim_roots_after("squad");
    const std::string squad = "squad";
    auto plan = plan_undo(s.world(), "scene.destroy", Json::object({{"id", squad}}));
    REQUIRE(plan.has_value());
    REQUIRE(s.run(plan->forward));
    CHECK(s.world().find_by_id("gunner").is_null());
    REQUIRE(s.run(plan->inverse));
    const Entity gunner = s.world().find_by_id("gunner");
    REQUIRE_FALSE(gunner.is_null());
    CHECK(s.world().id_of(s.world().parent(gunner)) == "squad");
    const TypeInfo* joint = TypeRegistry::global().find("Joint3D");
    const void* link = s.world().get(s.world().find_by_id("link"), *joint);
    REQUIRE(link != nullptr);
    CHECK(*static_cast<const Entity*>(joint->field("connected")->ptr(link)) == gunner);
    const void* medic = s.world().get(s.world().find_by_id("medic"), *joint);
    CHECK(*static_cast<const Entity*>(joint->field("connected")->ptr(medic)) == gunner);
    const auto kids = s.world().children(s.world().find_by_id("squad"));
    REQUIRE(kids.size() == 2);
    CHECK(s.world().id_of(kids[0]) == "gunner");
    CHECK(s.world().id_of(kids[1]) == "medic");
}

TEST_CASE("undo inverse: a destroyed prefab instance comes back linked to its prefab") {
    Session s(kStructScene);
    const Entity inst = s.world().find_by_id("inst");
    REQUIRE_FALSE(inst.is_null());
    REQUIRE(s.world().info(inst).prefab == "prefabs/pair.prefab.json");
    s.trim_roots_after("inst");
    s.edit_round_trip("scene.destroy", Json::object({{"id", "inst"}}));
    auto plan = plan_undo(s.world(), "scene.destroy", Json::object({{"id", "inst"}}));
    REQUIRE(plan.has_value());
    REQUIRE(s.run(plan->forward));
    REQUIRE(s.run(plan->inverse));
    const Entity back = s.world().find_by_id("inst");
    REQUIRE_FALSE(back.is_null());
    CHECK(s.world().info(back).prefab == "prefabs/pair.prefab.json");
    REQUIRE(s.world().children(back).size() == 2);
    CHECK(s.world().info(s.world().children(back)[0]).fromPrefab);
    CHECK(s.world().info(s.world().children(back)[0]).name == "Left");
    CHECK(s.world().get<Transform>(back)->position == Vec3{7, 8, 0});
    // overrides on the instance (a changed field of the root and of a part, a component the prefab has not, a child it has
    // not) are the same overrides after Undo and after Redo, as prefab.overrides lists them
    auto call = [&](const char* cmd, Json a) {
        const CommandResult r = s.engine.commands().call(cmd, a);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    };
    call("scene.set_component", set_args("left", "Transform", Json::object({{"position", Json::array({9, 9, 0})}})));
    call("scene.set_component", set_args("inst", "Shape2D", Json::object({{"size", Json::array({5, 6})}})));
    call("scene.spawn", Json::object({{"name", "Extra"}, {"parent", "inst"}}));
    const Json overrides = call("prefab.overrides", Json::object({{"id", "inst"}}));
    REQUIRE(overrides["count"].get<int>() >= 3);
    const Json before = s.scene();
    plan = plan_undo(s.world(), "scene.destroy", Json::object({{"id", "inst"}}));
    REQUIRE(plan.has_value());
    REQUIRE(s.run(plan->forward));
    CHECK(s.world().find_by_id("inst").is_null());
    REQUIRE(s.run(plan->inverse));
    CHECK(call("prefab.overrides", Json::object({{"id", "inst"}})) == overrides);
    CHECK(s.scene() == before);
    REQUIRE(s.run(plan->forward));
    REQUIRE(s.run(plan->inverse));
    CHECK(call("prefab.overrides", Json::object({{"id", "inst"}})) == overrides);
}

TEST_CASE("undo inverse: a spawn is undone by destroying it and redone with the same ids") {
    Session s(kStructScene);
    UndoPlan plan = s.edit_round_trip(
        "scene.spawn",
        Json::object({{"name", "Coin"},
                      {"components", Json::object({{"Shape2D", Json::object({{"size", Json::array({4, 4})}})}})}}));
    CHECK(plan.inverse.size() == 1);
    CHECK(plan.inverse[0].cmd == "scene.destroy");
    CHECK(plan.forward[0].cmd == "scene.paste_entities");  // redo re-creates what the call made
    const std::string id = plan.inverse[0].args["id"].get<std::string>();
    REQUIRE(s.run(plan.forward));
    CHECK_FALSE(s.world().find_by_id(id).is_null());
    REQUIRE(s.run(plan.inverse));
    // under a parent, at an index; and a prefab with children
    s.edit_round_trip("scene.spawn", Json::object({{"name", "Mid"}, {"parent", "holder"}, {"index", 1}}));
    s.edit_round_trip("scene.spawn",
                      Json::object({{"prefab", "prefabs/pair.prefab.json"}, {"position", Json::array({3, 4})}}));
    CHECK_FALSE(plan_undo(s.world(), "scene.spawn", Json::object()).has_value());
}

TEST_CASE("undo inverse: a paste is undone by destroying its roots and redone with the same ids") {
    Session s(kStructScene);
    const CommandResult copied =
        s.engine.commands().call("scene.copy_entities", Json::object({{"ids", Json::array({"squad", "link"})}}));
    REQUIRE(copied.ok);
    const std::string text = copied.result["text"].get<std::string>();
    UndoPlan plan = s.edit_round_trip("scene.paste_entities", Json::object({{"text", text}, {"parent", "holder"}}));
    CHECK(plan.inverse.size() == 2);
    // a duplicate: each copy next to its original, named "copy"; the copy of link names the copy of gunner
    s.edit_round_trip("scene.paste_entities",
                      Json::object({{"text", text}, {"keepParents", true}, {"nameSuffix", " copy"}}));
    // a paste under the top level
    s.edit_round_trip("scene.paste_entities", Json::object({{"text", text}, {"parent", nullptr}}));
}

TEST_CASE("undo inverse: set_parent gives the parent, the index and the exact local Transform back") {
    Session s(kStructScene);
    // keepWorldTransform across parents with different transforms (squad is rotated and scaled, holder scaled)
    UndoPlan plan = s.edit_round_trip("scene.set_parent", Json::object({{"id", "gunner"}, {"parent", "holder"}}));
    CHECK(plan.inverse.size() == 2);
    CHECK(plan.inverse[0].args["parent"] == "squad");
    CHECK(plan.inverse[0].args["index"] == 0);
    CHECK(plan.inverse[0].args["keepWorldTransform"] == false);
    CHECK(plan.inverse[1].cmd == "scene.set_component");
    s.edit_round_trip("scene.set_parent", Json::object({{"id", "medic"}, {"parent", nullptr}}));
    s.edit_round_trip("scene.set_parent", Json::object({{"id", "free"}, {"parent", "squad"}}));
    s.edit_round_trip("scene.set_parent", Json::object({{"id", "pair_c"}, {"parent", "holder"}, {"index", 0}}));
    // keepWorldTransform false: the local values stay, the entity moves
    s.edit_round_trip("scene.set_parent",
                      Json::object({{"id", "free"}, {"parent", "holder"}, {"keepWorldTransform", false}}));
    // a move within the same parent only reorders
    UndoPlan reorder =
        s.edit_round_trip("scene.set_parent", Json::object({{"id", "pair_d"}, {"parent", "holder"}, {"index", 0}}));
    CHECK(reorder.inverse.size() == 1);
    CHECK(reorder.inverse[0].args["index"] == 2);
    // an entity named by its display name is spelled out by id
    const auto named = plan_undo(s.world(), "scene.set_parent", Json::object({{"id", "Free"}, {"parent", "Holder"}}));
    REQUIRE(named.has_value());
    CHECK(named->forward[0].args["id"] == "free");
    CHECK(named->forward[0].args["parent"] == "holder");
    // a call that cannot succeed gives no plan or one that is never pushed
    CHECK_FALSE(plan_undo(s.world(), "scene.set_parent", Json::object({{"id", "nobody"}})).has_value());
    CHECK_FALSE(
        plan_undo(s.world(), "scene.set_parent", Json::object({{"id", "free"}, {"parent", "nobody"}})).has_value());
}

TEST_CASE("undo inverse: a widget moved out of a laid-out Panel and undone is where it was, nudge and slot") {
    Session s(kStructScene);
    UiSystem* ui = s.engine.ui();
    REQUIRE(ui != nullptr);
    const Vec2 design{320, 180};
    for (int i = 0; i < 3; ++i) ui->layout(s.world(), design, {});
    const Entity ok = s.world().find_by_id("ok");
    REQUIRE_FALSE(ok.is_null());
    const Vec3 nudge = s.world().get<Transform>(ok)->position;  // the author's nudge from the slot
    CHECK(nudge == Vec3{3, 4, 0});
    const Vec2 slot = s.world().ui_layout_offset(ok);
    CHECK(slot != Vec2{0, 0});  // the column puts it below the top of the Panel
    const Vec3 worldBefore = s.world().world_matrix(ok).translation();
    const Json before = s.scene();

    const Json args = Json::object({{"id", "ok"}, {"parent", nullptr}});
    auto plan = plan_undo(s.world(), "scene.set_parent", args);
    REQUIRE(plan.has_value());
    REQUIRE(s.engine.commands().call("scene.set_parent", args).ok);
    CHECK(s.world().ui_layout_offset(ok) == Vec2{0, 0});
    CHECK(s.world().get<Transform>(ok)->position.x ==
          doctest::Approx(worldBefore.x));  // the whole placement went into it
    REQUIRE(s.run(plan->inverse));
    for (int i = 0; i < 3; ++i) ui->layout(s.world(), design, {});
    CHECK(s.scene() == before);
    CHECK(s.world().get<Transform>(ok)->position == nudge);  // exactly the nudge, not nudge + slot
    CHECK(s.world().ui_layout_offset(ok) == slot);
    CHECK(s.world().world_matrix(ok).translation() == worldBefore);
    // redo and undo again, with a layout pass in between
    REQUIRE(s.run(plan->forward));
    for (int i = 0; i < 3; ++i) ui->layout(s.world(), design, {});
    REQUIRE(s.run(plan->inverse));
    for (int i = 0; i < 3; ++i) ui->layout(s.world(), design, {});
    CHECK(s.scene() == before);
    CHECK(s.world().world_matrix(ok).translation() == worldBefore);
}

TEST_CASE("undo inverse: a widget with a UI target in a destroyed Panel comes back with the target") {
    Session s(kStructScene);
    s.trim_roots_after("hud");
    s.edit_round_trip("scene.destroy", Json::object({{"id", "hud"}}));
    s.edit_round_trip("scene.destroy", Json::object({{"id", "ok"}}));  // `tint` names it from outside the subtree
}

TEST_CASE("undo inverse: several destroys chained in one step come back in order, references included") {
    Session s(kStructScene);
    const Json before = s.scene();
    UndoStack st;
    // pair_b first (pair_a names it), then pair_a (pair_c names it): the way a multi-selection delete records
    for (const char* id : {"pair_b", "pair_a"}) {
        const Json args = Json::object({{"id", id}});
        std::optional<UndoPlan> plan = plan_undo(s.world(), "scene.destroy", args);
        REQUIRE(plan.has_value());
        REQUIRE(s.engine.commands().call("scene.destroy", args).ok);
        st.push_command(std::move(plan->forward), std::move(plan->inverse), st.size() > 0, CoalesceMode::Merge);
    }
    CHECK(st.size() == 1);
    CHECK(s.world().find_by_id("pair_a").is_null());
    CHECK(s.world().find_by_id("pair_c").is_null());
    const Json after = s.scene();
    UndoEntry e = st.take_back();
    REQUIRE(s.run(e.inverse));
    const TypeInfo* joint = TypeRegistry::global().find("Joint3D");
    const Entity a = s.world().find_by_id("pair_a");
    REQUIRE_FALSE(a.is_null());
    CHECK(*static_cast<const Entity*>(joint->field("connected")->ptr(s.world().get(a, *joint))) ==
          s.world().find_by_id("pair_b"));
    CHECK(s.world().id_of(s.world().children(s.world().find_by_id("holder"))[0]) == "pair_a");
    REQUIRE(s.run(e.forward));
    CHECK(s.scene() == after);
    REQUIRE(s.run(e.inverse));
    // the whole scene is the original one but for the order of the children it had (kept) and of the roots (not touched here)
    CHECK(s.scene() == before);
}

TEST_CASE("undo inverse: bones.create is undone by destroying the chain and redone with the same ids") {
    Session s(kStructScene);
    UndoPlan plan = s.edit_round_trip(
        "bones.create",
        Json::object({{"parent", "free"},
                      {"points", Json::array({Json::array({0, 20}), Json::array({0, 10}), Json::array({0, 0})})}}));
    CHECK(plan.inverse.size() == 1);
    CHECK(plan.inverse[0].cmd == "scene.destroy");
}

TEST_CASE("undo inverse: a failed finish is reported, and a plan is never made for an unusable call") {
    Session s(kStructScene);
    auto plan = plan_undo(s.world(), "scene.spawn", Json::object({{"name", "x"}}));
    REQUIRE(plan.has_value());
    CHECK_FALSE(finish_undo_plan(s.world(), "scene.spawn", *plan, Json::object()));
    CHECK_FALSE(finish_undo_plan(s.world(), "scene.paste_entities", *plan, Json::object({{"ids", Json::array()}})));
    CHECK(finish_undo_plan(s.world(), "scene.destroy", *plan, Json::object()));  // needs nothing from the result
}

// ------------------------------------------------------------------------------------------------ polish (M98) ----

namespace {

// A chain of `levels` entities, each the child of the one before (the first at the top level, last among the roots).
void make_chain(Session& s, int levels, const std::string& prefix) {
    std::string parent;
    for (int i = 0; i < levels; ++i) {
        Json args = Json::object({{"id", prefix + std::to_string(i)}});
        if (!parent.empty()) args["parent"] = parent;
        REQUIRE(s.engine.commands().call("scene.spawn", args).ok);
        parent = prefix + std::to_string(i);
    }
}

}  // namespace

TEST_CASE("undo inverse: a subtree deeper than a paste accepts has no plan (the snapshot undoes it)") {
    Session s(kStructScene);
    make_chain(s, 66, "deep");  // levels 0..65: the root has a descendant 65 levels below it
    CHECK_FALSE(plan_undo(s.world(), "scene.destroy", Json::object({{"id", "deep0"}})).has_value());
    CHECK_FALSE(has_undo_plan(s.world(), "scene.destroy", Json::object({{"id", "deep0"}})));
    // a child whose own subtree is 64 levels deep is the limit: a plan, and its inverse really pastes
    CHECK(has_undo_plan(s.world(), "scene.destroy", Json::object({{"id", "deep1"}})));
    s.edit_round_trip("scene.destroy", Json::object({{"id", "deep1"}}));
    // the call that spawns that much nesting is not planned either
    Json spec = Json::object({{"id", "leaf"}});
    for (int i = 0; i < 70; ++i)
        spec = Json::object({{"id", "n" + std::to_string(i)}, {"children", Json::array({spec})}});
    CHECK_FALSE(plan_undo(s.world(), "scene.spawn", spec).has_value());
    // bones.create: N points make a chain N-2 levels deep
    Json points = Json::array();
    for (int i = 0; i < 70; ++i) points.push_back(Json::array({0, i * 3}));
    CHECK_FALSE(
        plan_undo(s.world(), "bones.create", Json::object({{"parent", "free"}, {"points", points}})).has_value());
}

TEST_CASE("undo inverse: has_undo_plan agrees with plan_undo") {
    Session s(kStructScene);
    for (const char* id : {"anchor", "squad", "gunner", "holder", "free", "inst", "nobody"}) {
        const Json args = Json::object({{"id", id}});
        CHECK(has_undo_plan(s.world(), "scene.destroy", args) ==
              plan_undo(s.world(), "scene.destroy", args).has_value());
    }
    CHECK(has_undo_plan(s.world(), "scene.set_component",
                        Json::object({{"id", "anchor"}, {"component", "Transform"}, {"fields", Json::object()}})));
    CHECK_FALSE(has_undo_plan(s.world(), "scene.import_ascii", Json::object()));
}

TEST_CASE("undo inverse: a reparent that changes nothing is a no-op plan, a real one is not") {
    Session s(kStructScene);
    auto noop = [&](const Json& args) {
        const auto plan = plan_undo(s.world(), "scene.set_parent", args);
        REQUIRE(plan.has_value());
        return plan->noop;
    };
    CHECK(noop(Json::object({{"id", "free"}, {"parent", nullptr}})));                         // a root made a root
    CHECK(noop(Json::object({{"id", "pair_d"}, {"parent", "holder"}})));                      // already the last child
    CHECK(noop(Json::object({{"id", "pair_a"}, {"parent", "holder"}, {"index", 0}})));        // already first
    CHECK_FALSE(noop(Json::object({{"id", "pair_a"}, {"parent", "holder"}})));                // would go last
    CHECK_FALSE(noop(Json::object({{"id", "pair_d"}, {"parent", "holder"}, {"index", 0}})));  // would go first
    CHECK_FALSE(noop(Json::object({{"id", "free"}, {"parent", "holder"}})));                  // another parent
    CHECK_FALSE(noop(Json::object({{"id", "pair_a"}, {"parent", nullptr}})));                 // to the top level
}

TEST_CASE("undo inverse: restoring several roots under one parent adds a set_parent only where a place differs") {
    Session s(kStructScene);
    // pair_d is the last child of holder: a paste puts it there, so no set_parent
    const auto first = plan_undo(s.world(), "scene.destroy", Json::object({{"id", "pair_d"}}));
    REQUIRE(first.has_value());
    CHECK(first->inverse[0].cmd == "scene.paste_entities");
    for (const UndoCommand& c : first->inverse) CHECK(c.cmd != "scene.set_parent");
    // a paste of two roots under holder leaves them last, in order: redo needs no reorder either
    const CommandResult copied =
        s.engine.commands().call("scene.copy_entities", Json::object({{"ids", Json::array({"anchor", "free"})}}));
    REQUIRE(copied.ok);
    const UndoPlan plan = s.edit_round_trip("scene.paste_entities",
                                            Json::object({{"text", copied.result["text"]}, {"parent", "holder"}}));
    for (const UndoCommand& c : plan.forward) CHECK(c.cmd != "scene.set_parent");
    // The round trip undid the paste, so only pair_d is after pair_b: one set_parent puts it back, and the trip is exact
    const UndoPlan mid = s.edit_round_trip("scene.destroy", Json::object({{"id", "pair_b"}}));
    int reorders = 0;
    for (const UndoCommand& c : mid.inverse) reorders += c.cmd == "scene.set_parent";
    CHECK(reorders == 1);
}

TEST_CASE("undo inverse: terrain.sculpt, paint and holes are one terrain.redo / terrain.undo entry, a continued stroke "
          "none") {
    Session s;
    REQUIRE(
        s.engine.commands().call("terrain.create", Json::parse(R"({"name":"g","size":[64,64],"resolution":65})")).ok);
    CHECK(has_undo_builder("terrain.sculpt"));
    CHECK(has_undo_builder("terrain.paint"));
    CHECK(has_undo_builder("terrain.holes"));
    CHECK(has_undo_builder("terrain.generate"));
    const Json args = Json::parse(R"({"entity":"g","tool":"raise","center":[0,0],"radius":8,"amount":5,"strength":1})");
    std::optional<UndoPlan> plan = plan_undo(s.world(), "terrain.sculpt", args);
    REQUIRE(plan.has_value());
    REQUIRE(plan->forward.size() == 1);
    REQUIRE(plan->inverse.size() == 1);
    CHECK(plan->forward[0].cmd == "terrain.redo");
    CHECK(plan->inverse[0].cmd == "terrain.undo");
    CHECK(plan->inverse[0].args["entity"] == "g");
    CHECK_FALSE(plan->noop);
    const CommandResult r = s.engine.commands().call("terrain.sculpt", args);
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(finish_undo_plan(s.world(), "terrain.sculpt", *plan, r.result));
    CHECK_FALSE(plan->noop);
    // undo and redo through the plan
    const std::shared_ptr<TerrainHeights> h = s.world().terrain().find(s.world().find("g"));
    REQUIRE(h);
    const std::vector<std::uint16_t> edited = h->data;
    REQUIRE(s.run(plan->inverse));
    CHECK(h->data != edited);
    REQUIRE(s.run(plan->forward));
    CHECK(h->data == edited);
    // a stroke that changes nothing (the tool "smooth" on flat ground) makes no entry
    const Json flat =
        Json::parse(R"({"entity":"g","tool":"smooth","center":[30,30],"radius":4,"amount":1,"strength":1})");
    std::optional<UndoPlan> none = plan_undo(s.world(), "terrain.sculpt", flat);
    REQUIRE(none.has_value());
    const CommandResult r2 = s.engine.commands().call("terrain.sculpt", flat);
    REQUIRE_MESSAGE(r2.ok, r2.error.dump());
    REQUIRE(finish_undo_plan(s.world(), "terrain.sculpt", *none, r2.result));
    CHECK(none->noop);
    // a piece that continues the stroke joins the newest step: no entry of its own
    Json cont = args;
    cont["continueStroke"] = true;
    const std::optional<UndoPlan> piece = plan_undo(s.world(), "terrain.sculpt", cont);
    REQUIRE(piece.has_value());
    CHECK(piece->noop);
    // a terrain that does not exist has no plan
    CHECK_FALSE(plan_undo(s.world(), "terrain.sculpt", Json::parse(R"({"entity":"nobody"})")).has_value());
}

TEST_CASE("undo inverse: the terrain steps its history let go leave the oldest entries, nothing else does") {
    auto terrain_entry = [](const char* id) {
        const Json args = Json::object({{"entity", id}});
        return UndoEntry::command({{"terrain.redo", args, ""}}, {{"terrain.undo", args, ""}});
    };
    UndoStack st;
    st.push_back(terrain_entry("g"));
    st.push_back(UndoEntry::command({{"scene.destroy", Json::object({{"id", "x"}}), ""}}, {}));
    st.push_back(terrain_entry("other"));
    st.push_back(terrain_entry("g"));
    st.push_back(terrain_entry("g"));
    CHECK(terrain_undo_count(st[0], "g") == 1);
    CHECK(terrain_undo_count(st[1], "g") == 0);
    CHECK(terrain_undo_count(st[2], "g") == 0);
    CHECK(drop_terrain_steps(st, "g", 0).steps == 0);  // the history let go of nothing
    CHECK(st.size() == 5);
    // The count is what the terrain let go, not the number of entries: entries beyond the history (an orphan left by a
    // terrain.undo run by hand) are never mistaken for lost steps.
    const TerrainDrop one = drop_terrain_steps(st, "g", 1);
    CHECK(one.steps == 1);
    CHECK(one.entries == 1);
    REQUIRE(st.size() == 4);
    CHECK(st[0].forward[0].cmd == "scene.destroy");
    CHECK(terrain_undo_count(st[1], "other") == 1);
    CHECK(terrain_undo_count(st[2], "g") == 1);
    const TerrainDrop two = drop_terrain_steps(st, "g", 5);  // more than the list holds: all of the terrain's, no more
    CHECK(two.steps == 2);
    CHECK(st.size() == 2);
}

TEST_CASE(
    "undo inverse: foliage.scatter, paint and clear are one foliage.redo / foliage.undo entry, a continued stroke or a "
    "dry run none") {
    Session s;
    auto call = [&](const char* name, const char* args) {
        const CommandResult r = s.engine.commands().call(name, Json::parse(args));
        REQUIRE_MESSAGE(r.ok, name << " " << args << " -> " << r.error.dump());
        return r.result;
    };
    call("terrain.create", R"({"name":"g","size":[64,64],"resolution":65})");
    call("scene.spawn", R"({"id":"grass","components":{"Foliage":{},"ScatterRule":{"terrain":"g",
         "meshes":[{"mesh":"assets/models/pine.glb"}],"density":0.5,"seed":3}}})");
    for (const char* name : {"foliage.scatter", "foliage.paint", "foliage.clear"}) CHECK(has_undo_builder(name));
    const Json args = Json::parse(R"({"entity":"grass"})");
    std::optional<UndoPlan> plan = plan_undo(s.world(), "foliage.scatter", args);
    REQUIRE(plan.has_value());
    REQUIRE(plan->forward.size() == 1);
    REQUIRE(plan->inverse.size() == 1);
    CHECK(plan->forward[0].cmd == "foliage.redo");
    CHECK(plan->inverse[0].cmd == "foliage.undo");
    CHECK(plan->inverse[0].args["entity"] == "grass");
    CHECK_FALSE(plan->noop);
    const Json r = call("foliage.scatter", R"({"entity":"grass"})");
    REQUIRE(finish_undo_plan(s.world(), "foliage.scatter", *plan, r));
    CHECK_FALSE(plan->noop);
    // both commands carry the history's id and the step's absolute number (steps lost + depth)
    CHECK(plan->inverse[0].historyId == r["historyId"].get<std::uint64_t>());
    CHECK(plan->inverse[0].historyStep == r["historyLost"].get<std::uint64_t>() + r["undoDepth"].get<std::uint64_t>());
    CHECK(plan->forward[0].historyId == plan->inverse[0].historyId);
    CHECK(plan->forward[0].historyStep == plan->inverse[0].historyStep);
    const std::string file = r["file"].get<std::string>();
    REQUIRE(fs::exists(file));
    // undo and redo through the plan
    REQUIRE(s.run(plan->inverse));
    CHECK_FALSE(fs::exists(file));
    REQUIRE(s.run(plan->forward));
    CHECK(fs::exists(file));
    // a clear of an empty region changes nothing: no entry
    const Json none = Json::parse(R"({"entity":"grass","region":[500,500,501,501]})");
    std::optional<UndoPlan> noneplan = plan_undo(s.world(), "foliage.clear", none);
    REQUIRE(noneplan.has_value());
    REQUIRE(finish_undo_plan(s.world(), "foliage.clear", *noneplan,
                             call("foliage.clear", R"({"entity":"grass","region":[500,500,501,501]})")));
    CHECK(noneplan->noop);
    // a dry run and a continued stroke make no entry of their own
    const std::optional<UndoPlan> dry =
        plan_undo(s.world(), "foliage.scatter", Json::parse(R"({"entity":"grass","dryRun":true})"));
    REQUIRE(dry.has_value());
    CHECK(dry->noop);
    const std::optional<UndoPlan> piece =
        plan_undo(s.world(), "foliage.paint",
                  Json::parse(R"({"entity":"grass","center":[0,0],"radius":3,"continueStroke":true})"));
    REQUIRE(piece.has_value());
    CHECK(piece->noop);
    // an entity with no Foliage has no plan
    CHECK_FALSE(plan_undo(s.world(), "foliage.paint", Json::parse(R"({"entity":"nobody"})")).has_value());
    CHECK_FALSE(plan_undo(s.world(), "foliage.paint", Json::parse(R"({"entity":"g"})")).has_value());
}

namespace {
UndoEntry foliage_entry(const char* id, std::uint64_t history, std::uint64_t step) {
    const Json args = Json::object({{"entity", id}});
    UndoCommand redo{"foliage.redo", args, "", history, step}, undo{"foliage.undo", args, "", history, step};
    return UndoEntry::command({redo}, {undo});
}
}  // namespace

TEST_CASE("undo inverse: foliage rows numbered at or below the steps the history lost go, a trimmed list does not confuse it") {
    // The editor list holds 3 rows of a history that has made 10 steps and let go of the first 8 (steps 9 and 10 are what it still
    // has); the list itself trimmed its oldest rows long ago, so counting lost steps against the oldest rows would drop live ones.
    UndoStack st(3, size_t(1) << 20);
    st.push_back(foliage_entry("grass", 7, 7));  // pushed first: trimmed below, together with 8
    st.push_back(foliage_entry("grass", 7, 8));
    st.push_back(UndoEntry::command({{"scene.destroy", Json::object({{"id", "x"}}), ""}}, {}));
    st.push_back(foliage_entry("grass", 7, 9));
    st.push_back(foliage_entry("grass", 7, 10));
    REQUIRE(st.size() == 3);  // 8 and the destroy were trimmed too
    CHECK(drop_foliage_steps(st, "grass", 7, 8).steps == 0);  // the rows left are 9 and 10: both still work
    CHECK(st.size() == 3);
    const FoliageDrop one = drop_foliage_steps(st, "grass", 7, 9);
    CHECK(one.steps == 1);
    CHECK(one.entries == 1);
    REQUIRE(st.size() == 2);
    CHECK(st[1].inverse[0].historyStep == 10);
    // the numbers repeat in another history of the same entity (it was destroyed and came back): its rows are not touched by the
    // old one's count, and the old one's rows go when the new history shows itself
    st.push_back(foliage_entry("grass", 8, 1));
    CHECK(drop_foliage_steps(st, "grass", 8, 0).steps == 0 + 1);  // history 7's step 10 is of another history: gone
    REQUIRE(st.size() == 2);
    CHECK(st[1].inverse[0].historyId == 8);
    // another entity is never touched
    st.push_back(foliage_entry("trees", 9, 1));
    CHECK(drop_foliage_steps(st, "grass", 8, 5).steps == 1);
    REQUIRE(st.size() == 2);
    CHECK(st[1].inverse[0].args["entity"] == "trees");
}

TEST_CASE("undo inverse: a Chain entry that lost one foliage step keeps its other commands and its bytes are estimated again") {
    const Json g = Json::object({{"entity", "grass"}}), t = Json::object({{"entity", "g"}});
    UndoStack st;
    st.push_back(UndoEntry::command(
        {{"foliage.redo", g, "", 3, 2}, {"terrain.redo", t, ""}, {"foliage.redo", g, "", 3, 3}},
        {{"foliage.undo", g, "", 3, 3}, {"terrain.undo", t, ""}, {"foliage.undo", g, "", 3, 2}}));
    const std::size_t before = st.bytes();
    const FoliageDrop d = drop_foliage_steps(st, "grass", 3, 2);  // the history let go of steps 1 and 2
    CHECK(d.steps == 1);
    CHECK(d.entries == 0);
    REQUIRE(st.size() == 1);
    REQUIRE(st[0].inverse.size() == 2);
    CHECK(st[0].inverse[0].historyStep == 3);  // number 3 still works
    CHECK(st[0].inverse[1].cmd == "terrain.undo");
    REQUIRE(st[0].forward.size() == 2);
    CHECK(st[0].forward[1].cmd == "foliage.redo");
    CHECK(st[0].forward[1].historyStep == 3);
    CHECK(st.bytes() < before);
    CHECK(st.bytes() == st[0].bytes);
    // a history that was cleared takes every foliage command of the entity, numbered or not
    st.push_back(UndoEntry::command({{"foliage.redo", g, ""}}, {{"foliage.undo", g, ""}}));
    const FoliageDrop all = drop_foliage_all(st, "grass");
    CHECK(all.steps == 2);
    CHECK(all.entries == 1);
    REQUIRE(st.size() == 1);
    REQUIRE(st[0].inverse.size() == 1);
    CHECK(st[0].inverse[0].cmd == "terrain.undo");
}

TEST_CASE("undo inverse: a Chain entry that lost its terrain step keeps its other inverses") {
    const Json g = Json::object({{"entity", "g"}});
    UndoStack st;
    st.push_back(
        UndoEntry::command({{"terrain.redo", g, ""}, {"scene.set", Json::object({{"id", "x"}}), ""}},
                           {{"scene.set", Json::object({{"id", "x"}, {"old", 1}}), ""}, {"terrain.undo", g, ""}}));
    st.push_back(UndoEntry::command({{"terrain.redo", g, ""}}, {{"terrain.undo", g, ""}}));
    const TerrainDrop d = drop_terrain_steps(st, "g", 1);
    CHECK(d.steps == 1);
    CHECK(d.entries == 0);  // the chain stays: it still undoes the other edit
    REQUIRE(st.size() == 2);
    CHECK(terrain_undo_count(st[0], "g") == 0);
    REQUIRE(st[0].inverse.size() == 1);
    CHECK(st[0].inverse[0].cmd == "scene.set");
    REQUIRE(st[0].forward.size() == 1);
    CHECK(st[0].forward[0].cmd == "scene.set");  // its terrain.redo went with the step
    CHECK(terrain_undo_count(st[1], "g") == 1);  // the newer terrain step is untouched
}
