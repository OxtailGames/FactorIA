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

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "hero", "name": "Hero", "tags": ["player"],
      "components": { "Transform": { "position": [10, 20, 0] }, "Shape2D": { "size": [30, 20], "color": "#cc3030" },
                      "Script": { "props": { "speed": 3, "label": "x" } }, "UiControl": {} } },
    { "id": "target", "name": "Target", "components": { "Transform": { "position": [50, 0, 0] }, "Joint2D": { "connected": "hero" } } }
  ]
})";

// The structural edits: a subtree with references between entities (Joint3D.connected, InteractableVisual.target) in both
// directions, a prefab instance, a Panel that lays out its children, parents with different transforms.
const char* kStructScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "anchor", "name": "Anchor", "components": { "Transform": { "position": [5, 0, 0] } } },
    { "id": "squad", "name": "Squad", "tags": ["enemy"],
      "components": { "Transform": { "position": [120, 40, 0], "rotation": [0, 0, 30], "scale": [2, 2, 1] }, "Shape2D": { "size": [30, 20] } },
      "children": [
        { "id": "gunner", "name": "Gunner", "components": { "Transform": { "position": [10, 5, 0] }, "Joint3D": { "connected": "anchor" } } },
        { "id": "medic", "name": "Medic", "components": { "Transform": { "position": [-10, 5, 0] }, "Joint3D": { "connected": "gunner" } } }
      ] },
    { "id": "link", "name": "Link", "components": { "Joint3D": { "connected": "gunner" } } },
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
    // The scene with its top-level entities sorted by id: a destroyed top-level entity comes back last among them.
    Json sorted_scene() {
        Json j = scene();
        std::vector<Json> ents(j["entities"].begin(), j["entities"].end());
        std::sort(ents.begin(), ents.end(), [](const Json& a, const Json& b) { return a["id"] < b["id"]; });
        j["entities"] = Json(ents);
        return j;
    }
    // The real call, as Editor::edit_command makes it: plan, run, finish; then undo, redo, undo through the plan's lists.
    // Returns the plan. `sortRoots` compares the scenes with the top-level entities sorted.
    UndoPlan edit_round_trip(const std::string& name, const Json& args, bool sortRoots = false) {
        INFO(name << " " << args.dump());
        auto snap = [&] { return sortRoots ? sorted_scene() : scene(); };
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
    for (const char* name : {"scene.spawn", "scene.destroy", "scene.set_parent", "scene.paste_entities", "bones.create"})
        CHECK(has_undo_builder(name));
    for (const char* name : {"scene.import_ascii", "scene.ascii_edit", "skin.set_weights"})
        CHECK_FALSE(has_undo_builder(name));
}

TEST_CASE("undo inverse: destroy brings the subtree back with its ids, order, components and references") {
    Session s(kStructScene);
    // a subtree: the children, a Joint3D that names an entity outside it and one inside, and a reference from OUTSIDE into it
    s.edit_round_trip("scene.destroy", Json::object({{"id", "squad"}}), true);
    // a child in the middle of its siblings goes back to its place (index 0 of holder)
    s.edit_round_trip("scene.destroy", Json::object({{"id", "pair_a"}}));
    s.edit_round_trip("scene.destroy", Json::object({{"id", "pair_b"}}));
    s.edit_round_trip("scene.destroy", Json::object({{"id", "holder"}}), true);
    s.edit_round_trip("scene.destroy", Json::object({{"id", "Free"}}), true);  // by name
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

TEST_CASE("undo inverse: the ids and handles are the same after undo, and a field names the entity again") {
    Session s(kStructScene);
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
    s.edit_round_trip("scene.destroy", Json::object({{"id", "inst"}}), true);
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
    // an override on the instance (a changed child) survives the round trip too
    REQUIRE(s.engine.commands()
                .call("scene.set_component", set_args("left", "Transform", Json::object({{"position", Json::array({9, 9, 0})}})))
                .ok);
    s.edit_round_trip("scene.destroy", Json::object({{"id", "inst"}}), true);
}

TEST_CASE("undo inverse: a spawn is undone by destroying it and redone with the same ids") {
    Session s(kStructScene);
    UndoPlan plan = s.edit_round_trip(
        "scene.spawn",
        Json::object({{"name", "Coin"}, {"components", Json::object({{"Shape2D", Json::object({{"size", Json::array({4, 4})}})}})}}),
        true);
    CHECK(plan.inverse.size() == 1);
    CHECK(plan.inverse[0].cmd == "scene.destroy");
    CHECK(plan.forward[0].cmd == "scene.paste_entities");  // redo re-creates what the call made
    const std::string id = plan.inverse[0].args["id"].get<std::string>();
    REQUIRE(s.run(plan.forward));
    CHECK_FALSE(s.world().find_by_id(id).is_null());
    REQUIRE(s.run(plan.inverse));
    // under a parent, at an index; and a prefab with children
    s.edit_round_trip("scene.spawn",
                      Json::object({{"name", "Mid"}, {"parent", "holder"}, {"index", 1}}));
    s.edit_round_trip("scene.spawn", Json::object({{"prefab", "prefabs/pair.prefab.json"}, {"position", Json::array({3, 4})}}),
                      true);
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
    s.edit_round_trip(
        "scene.paste_entities",
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
    CHECK_FALSE(plan_undo(s.world(), "scene.set_parent", Json::object({{"id", "free"}, {"parent", "nobody"}})).has_value());
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
    CHECK(slot.x != 0.0f);
    const Vec3 worldBefore = s.world().world_matrix(ok).translation();
    const Json before = s.scene();

    const Json args = Json::object({{"id", "ok"}, {"parent", nullptr}});
    auto plan = plan_undo(s.world(), "scene.set_parent", args);
    REQUIRE(plan.has_value());
    REQUIRE(s.engine.commands().call("scene.set_parent", args).ok);
    CHECK(s.world().ui_layout_offset(ok) == Vec2{0, 0});
    CHECK(s.world().get<Transform>(ok)->position.x == doctest::Approx(worldBefore.x));  // the whole placement went into it
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
    s.edit_round_trip("scene.destroy", Json::object({{"id", "hud"}}), true);
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
    CHECK(s.sorted_scene() != Json());
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
        Json::object({{"parent", "free"}, {"points", Json::array({Json::array({0, 20}), Json::array({0, 10}), Json::array({0, 0})})}}),
        true);
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
