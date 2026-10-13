#include <doctest.h>

#include <chrono>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/json_schema.h"
#include "fa/scene/serialize.h"

using namespace fa;

namespace {
struct TempProject {
    std::filesystem::path dir, oldRoot;
    TempProject() {
        oldRoot = fs::project_root();
        dir = std::filesystem::temp_directory_path() /
              ("fa_test_scene_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        std::filesystem::create_directories(dir);
        fs::set_project_root(dir);
    }
    ~TempProject() {
        fs::set_project_root(oldRoot);
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
};

bool has_message(const LoadReport& r, LoadMessage::Severity sev, const std::string& needle) {
    for (const auto& m : r.messages)
        if (m.severity == sev && m.to_string().find(needle) != std::string::npos) return true;
    return false;
}
const auto kErr = LoadMessage::Severity::Error;
const auto kWarn = LoadMessage::Severity::Warning;

const char* kScene = R"({
  "format": "factoria.scene/1",
  "settings": { "gravity2D": [0, -500], "fogDensity": 0.25, "music": "assets/m.ogg" },
  "entities": [
    { "id": "player", "name": "Player", "tags": ["hero", "x"],
      "components": {
        "Transform": { "position": [10, 20, 0], "rotation": [0, 0, 45] },
        "Sprite": { "texture": "assets/p.png", "color": "#ff8000", "pivot": {"x": 0, "y": 1}, "space": "Screen" },
        "RigidBody2D": { "type": "dynamic", "velocity": [1, 2] },
        "Script": { "path": "scripts/p.js", "props": { "speed": 3, "nested": {"a": [1, 2]} } }
      },
      "children": [
        { "id": "weapon", "components": { "Transform": { "position": [5, 0, 0] }, "Sprite": {} },
          "children": [ { "id": "muzzle", "active": false } ] }
      ] },
    { "id": "camera", "components": { "Camera": { "projection": "perspective", "fov": 70 } } },
    { "id": "boss", "components": { "Collider2D": { "shape": "circle", "radius": 8 } } }
  ]
})";
}  // namespace

TEST_CASE("scene: load a full scene") {
    World w;
    LoadReport r = load_scene(w, Json::parse(kScene), "test.scene.json");
    INFO(r.summary());
    CHECK(r.ok());
    CHECK(r.messages.empty());
    CHECK(r.created.size() == 5);
    CHECK(w.entity_count() == 5);
    Entity player = w.find_by_id("player");
    REQUIRE(!player.is_null());
    CHECK(w.info(player).name == "Player");
    CHECK(w.has_tag(player, "hero"));
    CHECK(w.get<Transform>(player)->position == Vec3{10, 20, 0});
    CHECK(w.get<Transform>(player)->rotation.z == 45.0f);
    const Sprite* s = w.get<Sprite>(player);
    REQUIRE(s != nullptr);
    CHECK(s->texture == "assets/p.png");
    CHECK(s->color.r == 1.0f);
    CHECK(s->color.g == doctest::Approx(128 / 255.0f));
    CHECK(s->pivot == Vec2{0, 1});
    CHECK(s->space == RenderSpace::Screen);
    CHECK(w.get<RigidBody2D>(player)->velocity == Vec2{1, 2});
    CHECK(w.get<Script>(player)->props["nested"]["a"][1] == 2);
    CHECK(w.settings().gravity2D == Vec2{0, -500});
    CHECK(w.settings().fogDensity == 0.25f);
    CHECK(w.scene_path() == "test.scene.json");
    Entity weapon = w.find_by_id("weapon");
    CHECK(w.parent(weapon) == player);
    CHECK(!w.active_in_hierarchy(w.find_by_id("muzzle")));
    CHECK(w.get<Camera>(w.find_by_id("camera"))->projection == Projection::Perspective);
    CHECK(w.get<Collider2D>(w.find_by_id("boss"))->shape == ColliderShape::Circle);
}

TEST_CASE("scene: save is canonical and round trips") {
    World a;
    LoadReport r = load_scene(a, Json::parse(kScene), "t");
    REQUIRE(r.ok());
    Json saved = save_scene(a);
    CHECK(saved["format"] == "factoria.scene/1");
    CHECK(saved["settings"].size() == 3);                       // only non-default fields
    CHECK(saved["settings"].contains("gravity2D"));
    CHECK(!saved["settings"].contains("gravity3D"));
    REQUIRE(saved["entities"].size() == 3);
    const Json& player = saved["entities"][0];
    CHECK(player["id"] == "player");
    CHECK(player["tags"].size() == 2);
    CHECK(player["components"]["Transform"]["position"] == Json::parse("[10.0,20.0,0.0]"));
    CHECK(!player["components"]["Transform"].contains("scale"));
    CHECK(player["components"]["Sprite"]["space"] == "screen");
    CHECK(!player["components"]["Sprite"].contains("flipX"));
    CHECK(player["children"][0]["id"] == "weapon");
    CHECK(!player["children"][0]["components"].contains("Transform") == false);  // weapon has a non-default Transform
    CHECK(player["children"][0]["components"]["Sprite"].is_object());          // present even with all defaults
    const Json& muzzle = player["children"][0]["children"][0];
    CHECK(muzzle["active"] == false);
    CHECK(!muzzle.contains("components"));
    CHECK(saved["entities"][0].begin().key() == "id");

    World b;
    LoadReport r2 = load_scene(b, saved, "t2");
    CHECK(r2.ok());
    CHECK(r2.messages.empty());
    CHECK(save_scene(b) == saved);
    CHECK(dump_json(save_scene(b)) == dump_json(saved));
}

TEST_CASE("scene: errors carry pointers and suggestions, loading continues") {
    const char* text = R"({
      "format": "factoria.scene/1",
      "entities": [
        { "id": "a", "components": {
            "Sprit": { "layer": 1 },
            "sprite": { "layer": 2 },
            "Camera": { "fov": "wide", "fvo": 3, "projection": "perspectiv" },
            "Light": { "intensity": 2 } },
          "colour": "red", "Sprite": {} },
        { "id": "b", "components": { "Sprite": { "colour": [1, 0, 0] } } }
      ]
    })";
    World w;
    LoadReport r = load_scene(w, Json::parse(text), "bad.scene.json");
    CHECK(!r.ok());
    CHECK(w.entity_count() == 2);  // everything else still loaded
    CHECK(has_message(r, kErr, "bad.scene.json#/entities/0/components/Sprit: Unknown component 'Sprit'"));
    CHECK(has_message(r, kErr, "Did you mean 'Sprite'?"));
    CHECK(has_message(r, kWarn, "#/entities/0/components/sprite: Component 'sprite' should be spelled 'Sprite'"));
    CHECK(has_message(r, kErr, "#/entities/0/components/Camera/fov: Field 'fov': expected a number"));
    CHECK(has_message(r, kErr, "#/entities/0/components/Camera/fvo: Unknown field 'fvo' on Camera"));
    CHECK(has_message(r, kErr, "#/entities/0/components/Camera/projection: Field 'projection': unknown value \"perspectiv\""));
    CHECK(has_message(r, kErr, "Did you mean 'perspective'?"));
    CHECK(has_message(r, kWarn, "#/entities/0/colour: Unknown entity key 'colour'"));
    CHECK(has_message(r, kWarn, "put it under \"components\""));
    CHECK(has_message(r, kErr, "#/entities/1/components/Sprite/colour"));
    CHECK(has_message(r, kErr, "Did you mean 'color'?"));
    Entity a = w.find_by_id("a");
    REQUIRE(!a.is_null());
    CHECK(w.get<Sprite>(a)->layer == 2);          // the case-mismatched one was accepted
    CHECK(w.get<Camera>(a)->fov == 60.0f);        // bad value keeps default
    CHECK(w.get<Light>(a)->intensity == 2.0f);
    CHECK(r.summary().find("[error]") != std::string::npos);
    CHECK(r.error_count() >= 5);
}

TEST_CASE("scene: structural problems are reported, not crashed on") {
    World w;
    CHECK(!load_scene(w, Json::array(), "x").ok());
    CHECK(!load_scene(w, Json::parse(R"({"format":"factoria.prefab/1","entity":{}})"), "x").ok());
    LoadReport r = load_scene(w, Json::parse(R"({"entities": {"a":1}})"), "x");
    CHECK(has_message(r, kWarn, "Missing \"format\""));
    CHECK(has_message(r, kErr, "'entities' must be an array"));
    r = load_scene(w, Json::parse(R"({"format":"factoria.scene/1","entties":[], "entities":[5, {"components":[{"type":"Sprite"}]}, {"tags":"x"}]})"), "x");
    CHECK(has_message(r, kWarn, "Unknown top-level key 'entties'"));
    CHECK(has_message(r, kWarn, "Did you mean 'entities'"));
    CHECK(has_message(r, kErr, "#/entities/0: entity must be a JSON object"));
    CHECK(has_message(r, kErr, "'components' must be an object"));
    CHECK(has_message(r, kErr, "'tags' must be an array of strings"));
    r = load_scene(w, Json::parse(R"({"format":"factoria.scene/1","settings":{"gravty2D":[0,0]},"entities":[]})"), "x");
    CHECK(has_message(r, kErr, "#/settings/gravty2D: Unknown scene setting"));
    CHECK(has_message(r, kErr, "Did you mean 'gravity2D'"));
    r = load_scene(w, Json::parse(R"({"format":"factoria.scene/1","entities":[{"components":{"EntityInfo":{}}}]})"), "x");
    CHECK(has_message(r, kErr, "EntityInfo is not a component entry"));
    auto f = load_scene_file(w, "nope/missing.scene.json");
    CHECK(!f.ok());
    CHECK(f.messages[0].message.find("File not found") != std::string::npos);
}

TEST_CASE("scene: duplicate ids are renamed with a warning") {
    World w;
    LoadReport r = load_scene(w, Json::parse(R"({"format":"factoria.scene/1","entities":[{"id":"x"},{"id":"x"}]})"), "d");
    CHECK(r.ok());
    CHECK(has_message(r, kWarn, "id 'x' is already used; renamed to 'x_2'"));
    CHECK(!w.find_by_id("x_2").is_null());
}

TEST_CASE("scene: Entity fields reference entities defined later") {
    // A test component with an Entity field.
    struct Follow { Entity target; float speed = 1; };
    auto& reg = TypeRegistry::global();
    if (!reg.of<Follow>()) {
        reg.add<Follow>("FollowTest", "Follows a target.", "Test")
            .field("target", &Follow::target, "Entity to follow.")
            .field("speed", &Follow::speed, "Speed.");
    }
    const TypeInfo& ft = *reg.of<Follow>();

    World w;
    LoadReport r = load_scene(w, Json::parse(R"({
      "format":"factoria.scene/1",
      "entities":[
        {"id":"chaser","components":{"FollowTest":{"target":"prey","speed":3}}},
        {"id":"prey"},
        {"id":"lost","components":{"FollowTest":{"target":"prye"}}},
        {"id":"nullref","components":{"FollowTest":{"target":null}}},
        {"id":"bad","components":{"FollowTest":{"target":5}}}
      ]})"), "e");
    CHECK(has_message(r, kErr, "#/entities/2/components/FollowTest/target: No entity with id 'prye'"));
    CHECK(has_message(r, kErr, "Did you mean 'prey'"));
    CHECK(has_message(r, kErr, "#/entities/4/components/FollowTest/target"));
    CHECK(r.error_count() == 2);
    Entity chaser = w.find_by_id("chaser");
    CHECK(w.get<Follow>(chaser)->target == w.find_by_id("prey"));
    CHECK(w.get<Follow>(chaser)->speed == 3.0f);
    CHECK(w.get<Follow>(w.find_by_id("lost"))->target.is_null());

    Json saved = save_scene(w);
    CHECK(saved["entities"][0]["components"]["FollowTest"]["target"] == "prey");
    CHECK(!saved["entities"][3]["components"]["FollowTest"].contains("target"));

    // patch_component resolves ids immediately.
    Entity prey = w.find_by_id("prey");
    CHECK(patch_component(w, prey, ft, Json::parse(R"({"target":"chaser"})")).ok());
    CHECK(w.get<Follow>(prey)->target == chaser);
    auto bad = patch_component(w, prey, ft, Json::parse(R"({"target":"nobody","speed":9})"));
    CHECK(!bad.ok());
    CHECK(w.get<Follow>(prey)->speed == 1.0f);  // all-or-nothing
}

TEST_CASE("scene: patch_component adds, patches and rolls back") {
    World w;
    Entity e = w.create("e", "e");
    const TypeInfo& sprite = World::type_of<Sprite>();
    REQUIRE(patch_component(w, e, sprite, Json::parse(R"({"layer": 3, "color": "blue"})")).ok());
    CHECK(w.get<Sprite>(e)->layer == 3);
    CHECK(w.get<Sprite>(e)->color == Color::blue());
    auto bad = patch_component(w, e, sprite, Json::parse(R"({"layer": 9, "flipX": "yes"})"));
    REQUIRE(!bad.ok());
    CHECK(bad.error().message.find("flipX") != std::string::npos);
    CHECK(w.get<Sprite>(e)->layer == 3);

    const TypeInfo& cam = World::type_of<Camera>();
    CHECK(!patch_component(w, e, cam, Json::parse(R"({"fov": 500})")).ok());
    CHECK(!w.has<Camera>(e));  // newly added component rolled back

    // EntityInfo patches go through the id table.
    const TypeInfo& info = World::type_of<EntityInfo>();
    CHECK(patch_component(w, e, info, Json::parse(R"({"id":"renamed","tags":["t"],"name":"N"})")).ok());
    CHECK(w.find_by_id("renamed") == e);
    CHECK(w.find_by_id("e").is_null());
    CHECK(w.has_tag(e, "t"));
}

TEST_CASE("scene: component_to_json and entity_to_json options") {
    World w;
    Entity e = w.create("Box", "box");
    w.add<SpriteAnimator>(e).time = 2.5f;
    CHECK(component_to_json(w, e, World::type_of<SpriteAnimator>()).empty());  // runtime-only + defaults
    Json rt = component_to_json(w, e, World::type_of<SpriteAnimator>(), false, true);
    CHECK(rt["time"] == 2.5);
    Json full = component_to_json(w, e, World::type_of<Transform>(), true);
    CHECK(full.size() == 3);

    EntityJsonOptions all;
    all.includeDefaults = true;
    Json j = entity_to_json(w, e, all);
    CHECK(j["tags"].is_array());
    CHECK(j["active"] == true);
    CHECK(j["components"]["Transform"]["scale"] == Json::parse("[1.0,1.0,1.0]"));
    EntityJsonOptions noKids;
    noKids.includeChildren = false;
    Entity kid = w.create("Kid", "kid");
    w.set_parent(kid, e);
    CHECK(entity_to_json(w, e).contains("children"));
    CHECK(!entity_to_json(w, e, noKids).contains("children"));
}

TEST_CASE("scene: additive load and parent option") {
    World w;
    load_scene(w, Json::parse(R"({"format":"factoria.scene/1","settings":{"fogDensity":1},"entities":[{"id":"holder"}]})"), "a");
    SceneLoadOptions opts;
    opts.additive = true;
    opts.parent = w.find_by_id("holder");
    LoadReport r = load_scene(w, Json::parse(R"({"format":"factoria.scene/1","settings":{"fogDensity":5},"entities":[{"id":"x"},{"id":"y"}]})"), "b", opts);
    CHECK(r.ok());
    CHECK(w.entity_count() == 3);
    CHECK(w.children(opts.parent).size() == 2);
    CHECK(w.settings().fogDensity == 1.0f);  // additive loads keep existing settings
    // Non-additive replaces everything.
    load_scene(w, Json::parse(R"({"format":"factoria.scene/1","entities":[{"id":"only"}]})"), "c");
    CHECK(w.entity_count() == 1);
    CHECK(w.settings().fogDensity == 0.0f);
}

TEST_CASE("scene: prefab instantiation with overrides") {
    TempProject p;
    REQUIRE(fs::write_text("prefabs/enemy.prefab.json", R"({
      "format": "factoria.prefab/1",
      "entity": {
        "id": "enemy", "name": "Enemy", "tags": ["enemy"],
        "components": {
          "Transform": { "scale": [2, 2, 1] },
          "Sprite": { "texture": "assets/enemy.png", "layer": 3 },
          "RigidBody2D": {}
        },
        "children": [ { "id": "eye", "components": { "Sprite": { "color": "red" } } } ]
      }})").ok());

    World w;
    LoadReport report;
    Entity a = instantiate_prefab(w, "prefabs/enemy.prefab.json", kNullEntity, report);
    Entity b = instantiate_prefab(w, "prefabs/enemy.prefab.json", kNullEntity, report,
                                  Json::parse(R"({"name":"Boss","components":{"Transform":{"position":[5,6,0]},"Sprite":{"layer":9}},"children":[{"id":"hat"}]})"));
    INFO(report.summary());
    CHECK(report.ok());
    CHECK(report.messages.empty());  // id collisions from prefab instances are silent
    REQUIRE(!a.is_null());
    REQUIRE(!b.is_null());
    CHECK(w.id_of(a) == "enemy");
    CHECK(w.id_of(b) == "enemy_2");
    CHECK(w.info(b).name == "Boss");
    CHECK(w.has_tag(b, "enemy"));
    CHECK(w.get<Transform>(b)->position == Vec3{5, 6, 0});
    CHECK(w.get<Transform>(b)->scale == Vec3{2, 2, 1});  // deep merge kept the prefab's scale
    CHECK(w.get<Sprite>(b)->layer == 9);
    CHECK(w.get<Sprite>(b)->texture == "assets/enemy.png");
    CHECK(w.get<Sprite>(a)->layer == 3);
    CHECK(w.children(b).size() == 2);  // eye + hat
    CHECK(w.children(a).size() == 1);
    CHECK(report.created.size() == 5);

    // Scene entity referencing a prefab, placed under a parent.
    Entity parent = w.create("p", "p");
    LoadReport r2;
    Entity c = instantiate_prefab(w, "prefabs/enemy.prefab.json", parent, r2);
    CHECK(w.parent(c) == parent);

    World s;
    LoadReport r3 = load_scene(s, Json::parse(R"({"format":"factoria.scene/1","entities":[
        {"id":"g1","prefab":"prefabs/enemy.prefab.json","components":{"Sprite":{"layer":"top"}}},
        {"id":"g2","prefab":"prefabs/nope.prefab.json"}]})"), "main.scene.json");
    CHECK(has_message(r3, kErr, "#/entities/0/components/Sprite/layer"));
    CHECK(has_message(r3, kErr, "expanded from prefab 'prefabs/enemy.prefab.json'"));
    CHECK(has_message(r3, kErr, "#/entities/1/prefab: File not found"));
    CHECK(s.entity_count() == 3);  // g1 + eye, plus empty g2 (error reported)

    // make_prefab -> save -> instantiate round trip.
    Json prefab = make_prefab(w, a);
    CHECK(prefab["format"] == "factoria.prefab/1");
    REQUIRE(save_json_file("prefabs/copy.prefab.json", prefab).ok());
    World w2;
    LoadReport r4;
    Entity copy = instantiate_prefab(w2, "prefabs/copy.prefab.json", kNullEntity, r4);
    CHECK(r4.ok());
    CHECK(entity_to_json(w2, copy) == entity_to_json(w, a));
}

TEST_CASE("scene: scene files save and load via fs") {
    TempProject p;
    World a;
    REQUIRE(load_scene(a, Json::parse(kScene), "t").ok());
    REQUIRE(save_scene_file(a, "scenes/out.scene.json").ok());
    World b;
    LoadReport r = load_scene_file(b, "scenes/out.scene.json");
    CHECK(r.ok());
    CHECK(b.scene_path() == "scenes/out.scene.json");
    CHECK(save_scene(a) == save_scene(b));
}

TEST_CASE("scene: generated JSON schemas validate scenes") {
    Json schema = scene_json_schema();
    CHECK(schema["$defs"].contains("Sprite"));
    CHECK(schema["$defs"].contains("Entity"));
    CHECK(schema["$defs"]["Sprite"]["properties"]["space"]["enum"] == Json::parse(R"(["world","screen"])"));
    CHECK(schema["$defs"]["Sprite"]["properties"]["texture"]["description"].get<std::string>().size() > 10);
    CHECK(!schema["$defs"].contains("EntityInfo"));
    CHECK(schema["$defs"]["Entity"]["properties"]["components"]["properties"].contains("Transform"));
    CHECK(!schema["$defs"]["Entity"]["properties"]["components"]["properties"].contains("SceneSettings"));

    World w;
    REQUIRE(load_scene(w, Json::parse(kScene), "t").ok());
    auto errors = validate_json(schema, save_scene(w));
    for (auto& e : errors) INFO(e.to_string());
    CHECK(errors.empty());

    auto bad = validate_json(schema, Json::parse(R"({"format":"factoria.scene/1","entities":[
        {"id":"a","children":[{"components":{"Sprite":{"space":"wrold"},"Sprit":{}}}]}]})"));
    REQUIRE(bad.size() == 2);
    bool sawEnum = false, sawComp = false;
    for (auto& e : bad) {
        if (e.pointer == "/entities/0/children/0/components/Sprite/space") {
            sawEnum = true;
            CHECK(e.hint.find("Did you mean 'world'") != std::string::npos);
        }
        if (e.pointer == "/entities/0/children/0/components/Sprit") {
            sawComp = true;
            CHECK(e.hint.find("Did you mean 'Sprite'") != std::string::npos);
        }
    }
    CHECK(sawEnum);
    CHECK(sawComp);

    Json prefab = prefab_json_schema();
    CHECK(prefab["required"].size() == 2);
    CHECK(validate_json(prefab, make_prefab(w, w.find_by_id("player"))).empty());
}
