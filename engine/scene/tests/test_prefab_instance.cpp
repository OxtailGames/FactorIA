// A scene saved with PrefabSave::Keep writes the entities a prefab made as {id, prefab, only the differences}.
#include <doctest.h>

#include <chrono>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/scene/serialize.h"

using namespace fa;

namespace {

struct TempProject {
    std::filesystem::path dir, oldRoot;
    TempProject() {
        oldRoot = fs::project_root();
        dir =
            std::filesystem::temp_directory_path() /
            ("fa_test_prefab_instance_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        std::filesystem::create_directories(dir);
        fs::set_project_root(dir);
    }
    ~TempProject() {
        fs::set_project_root(oldRoot);
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
};

const char* kPanel = R"({
  "format": "factoria.prefab/1",
  "entity": {
    "id": "panel", "name": "Panel", "tags": ["ui"],
    "components": { "Sprite": { "layer": 1 } },
    "children": [
      { "id": "title", "name": "Title", "components": { "Text": { "text": "Hello", "fontSize": 30 } } },
      { "name": "Row", "children": [ { "id": "ok", "name": "Ok", "components": { "Text": { "text": "OK" } } } ] }
    ]
  }})";

void write_panel() { REQUIRE(fs::write_text("prefabs/panel.prefab.json", kPanel).ok()); }

// The scene as save_scene(Keep) writes it, in the canonical text of the files.
std::string saved_text(const World& w, std::vector<PrefabExpanded>* expanded = nullptr) {
    SaveSceneOptions o;
    o.skipSpawned = true;
    o.prefabs = PrefabSave::Keep;
    o.prefabsExpanded = expanded;
    return dump_scene_json(save_scene(w, o));
}
std::string saved_entities_text(const World& w, std::vector<PrefabExpanded>* expanded = nullptr) {
    SaveSceneOptions o;
    o.prefabs = PrefabSave::Keep;
    o.prefabsExpanded = expanded;
    return dump_scene_json(save_scene(w, o)["entities"]);
}

Json saved_entity(const World& w, const char* id, std::vector<PrefabExpanded>* expanded = nullptr) {
    SaveSceneOptions o;
    o.prefabs = PrefabSave::Keep;
    o.prefabsExpanded = expanded;
    Json scene = save_scene(w, o);
    for (const Json& e : scene["entities"])
        if (e.value("id", "") == id) return e;
    return Json();
}

World* load(World& w, const std::string& text) {
    LoadReport r = load_scene(w, Json::parse(text), "scenes/main.scene.json");
    INFO(r.summary());
    REQUIRE(r.ok());
    return &w;
}

}  // namespace

TEST_CASE("prefab instances: loading and saving an unedited scene gives the same text") {
    TempProject p;
    write_panel();
    // In the canonical form of the saver: id, prefab, name/tags/active, components, overrides, children.
    const std::string scene = R"({
      "format": "factoria.scene/1",
      "settings": { "gravity2D": [0, -980], "gravity3D": [0, -9.81, 0] },
      "entities": [
        { "id": "plain", "prefab": "prefabs/panel.prefab.json" },
        { "id": "moved", "prefab": "prefabs/panel.prefab.json", "name": "Moved", "tags": ["ui", "big"],
          "components": { "Transform": { "position": [10.0, 20.0, 0.0] }, "Sprite": { "layer": 7 } } },
        { "id": "deep", "prefab": "prefabs/panel.prefab.json",
          "overrides": { "title": { "components": { "Text": { "text": "Bye" } } },
                         "ok": { "name": "Done", "active": false } } },
        { "id": "withkid", "prefab": "prefabs/panel.prefab.json",
          "children": [ { "id": "extra", "components": { "Transform": { "position": [1.0, 2.0, 0.0] } } } ] },
        { "id": "inline", "components": { "Transform": { "position": [5.0, 5.0, 0.0] } } }
      ]})";
    World w;
    load(w, scene);
    // Two instances of one prefab: the second one's ids got a suffix; that must not show in the file.
    CHECK(w.find_by_id("title_2").is_null() == false);
    std::vector<PrefabExpanded> expanded;
    const std::string want = dump_scene_json(Json::parse(scene)["entities"]);
    CHECK(saved_entities_text(w, &expanded) == want);
    CHECK(expanded.empty());

    // Saved with the in-memory snapshot (marks) and loaded again, the origin survives.
    World w2;
    REQUIRE(load_scene(w2, snapshot_scene(w), "<snapshot>").ok());
    CHECK(saved_entities_text(w2) == want);
    CHECK(w2.info(w2.find_by_id("plain")).prefab == "prefabs/panel.prefab.json");
    CHECK(w2.info(w2.find_by_id("title_2")).fromPrefab);
    CHECK_FALSE(w2.info(w2.find_by_id("extra")).fromPrefab);
}

TEST_CASE("prefab instances: an edit saves only that override, and editing it back drops it") {
    TempProject p;
    write_panel();
    World w;
    load(w, R"({"format":"factoria.scene/1","entities":[{"id":"a","prefab":"prefabs/panel.prefab.json"}]})");
    Entity a = w.find_by_id("a");
    CHECK(saved_entity(w, "a") == Json::parse(R"({"id":"a","prefab":"prefabs/panel.prefab.json"})"));

    w.get<Sprite>(a)->layer = 9;
    w.get<Transform>(a)->position = Vec3{3, 4, 0};
    w.get<Text>(w.find_by_id("title"))->text = "Edited";
    Json edited = saved_entity(w, "a");
    CHECK(edited == Json::parse(R"({"id":"a","prefab":"prefabs/panel.prefab.json",
        "components":{"Transform":{"position":[3,4,0]},"Sprite":{"layer":9}},
        "overrides":{"title":{"components":{"Text":{"text":"Edited"}}}}})"));

    w.get<Sprite>(a)->layer = 1;  // the prefab's value again
    w.get<Transform>(a)->position = Vec3{0, 0, 0};
    w.get<Text>(w.find_by_id("title"))->text = "Hello";
    CHECK(saved_entity(w, "a") == Json::parse(R"({"id":"a","prefab":"prefabs/panel.prefab.json"})"));

    // A component the prefab does not have is written whole; a prefab file that changes still reaches the scene.
    w.add<Shape2D>(a).layer = 4;
    CHECK(saved_entity(w, "a")["components"]["Shape2D"] == Json::parse(R"({"layer":4})"));
    w.remove<Shape2D>(a);
    const std::string savedBefore = saved_text(w);
    REQUIRE(fs::write_text("prefabs/panel.prefab.json",
                           std::string(kPanel).replace(std::string(kPanel).find("\"layer\": 1"), 10, "\"layer\": 5"))
                .ok());
    World after;
    load(after, savedBefore);
    CHECK(after.get<Sprite>(after.find_by_id("a"))->layer == 5);
}

TEST_CASE("prefab instances: what an instance cannot say is written inline and reported") {
    TempProject p;
    write_panel();
    World w;
    load(w, R"({"format":"factoria.scene/1","entities":[
        {"id":"a","prefab":"prefabs/panel.prefab.json"},{"id":"b","prefab":"prefabs/panel.prefab.json"},
        {"id":"c","prefab":"prefabs/panel.prefab.json"}]})");
    // a: a child of the prefab was removed. b: a child added under a part of the prefab. c: a component removed.
    w.destroy(w.find_by_id("title"));
    w.flush();
    Entity bkid = w.create("kid", "kid");
    w.set_parent(bkid, w.find_by_id("title_2"));
    w.remove<Text>(w.find_by_id("title_3"));
    std::vector<PrefabExpanded> expanded;
    Json scene;
    {
        SaveSceneOptions o;
        o.prefabs = PrefabSave::Keep;
        o.prefabsExpanded = &expanded;
        scene = save_scene(w, o);
    }
    REQUIRE(expanded.size() == 3);
    CHECK(expanded[0].id == "a");
    CHECK(expanded[0].reason.find("removed") != std::string::npos);
    CHECK(expanded[1].id == "b");
    CHECK(expanded[1].reason.find("added under") != std::string::npos);
    CHECK(expanded[2].id == "c");
    CHECK(expanded[2].reason.find("Text") != std::string::npos);
    // They are inline entities: no "prefab" key, the components are there, and nothing is lost on reload.
    CHECK_FALSE(scene["entities"][0].contains("prefab"));
    CHECK(scene["entities"][0]["children"].size() == 1);
    World again;
    REQUIRE(load_scene(again, scene, "x").ok());
    CHECK(again.children(again.find_by_id("b")).size() == 2);
}

TEST_CASE("prefab instances: a part whose id differs from the prefab's stays an instance unless a string elsewhere "
          "names it") {
    TempProject p;
    write_panel();
    const char* withTwo = R"({"format":"factoria.scene/1","entities":[
        {"id":"a","prefab":"prefabs/panel.prefab.json"},{"id":"b","prefab":"prefabs/panel.prefab.json"}%s]})";
    char buf[1024];
    {
        std::snprintf(buf, sizeof buf, withTwo, "");
        World w;
        load(w, buf);
        REQUIRE(w.find_by_id("title_2").is_null() == false);  // the second instance's part got the suffixed id
        std::vector<PrefabExpanded> expanded;
        Json scene = Json::parse(saved_text(w, &expanded));
        CHECK(expanded.empty());
        CHECK(scene["entities"][1]["prefab"] == "prefabs/panel.prefab.json");
    }
    {
        std::snprintf(buf, sizeof buf, withTwo, R"(,{"id":"label","components":{"Text":{"text":"title_2"}}})");
        World w;
        load(w, buf);
        std::vector<PrefabExpanded> expanded;
        Json scene = Json::parse(saved_text(w, &expanded));
        REQUIRE(expanded.size() == 1);
        CHECK(expanded[0].id == "b");
        CHECK(expanded[0].reason.find("title_2") != std::string::npos);
        CHECK(expanded[0].reason.find("string") != std::string::npos);
        CHECK_FALSE(scene["entities"][1].contains("prefab"));
        World again;
        REQUIRE(load_scene(again, scene, "x").ok());
        CHECK_FALSE(again.find_by_id("title_2").is_null());  // the id the string names still exists
    }
}

TEST_CASE("prefab instances: diff_entity_with_prefab compares an entity built by hand") {
    TempProject p;
    write_panel();
    World w;
    // The prefab's content written inline (no marks): the first children are taken to be the prefab's.
    load(w, R"({"format":"factoria.scene/1","entities":[{"id":"copy","name":"Panel","tags":["ui"],
        "components":{"Sprite":{"layer":2}},
        "children":[{"id":"title","name":"Title","components":{"Text":{"text":"Hello","fontSize":30}}},
                    {"name":"Row","children":[{"id":"ok","name":"Ok","components":{"Text":{"text":"OK"}}}]}]}]})");
    PrefabDiff d = diff_entity_with_prefab(w, w.find_by_id("copy"), "prefabs/panel.prefab.json");
    INFO(d.reason);
    REQUIRE(d.expressible);
    CHECK(d.changes == 1);  // the Sprite layer
    CHECK(d.entry ==
          Json::parse(R"({"id":"copy","prefab":"prefabs/panel.prefab.json","components":{"Sprite":{"layer":2}}})"));

    PrefabDiff none = diff_entity_with_prefab(w, w.find_by_id("copy"), "prefabs/nope.prefab.json");
    CHECK_FALSE(none.expressible);
    CHECK(none.reason.find("nope") != std::string::npos);
}

TEST_CASE("prefab instances: an instance added as a child of an instance stays an instance") {
    TempProject p;
    write_panel();
    // Canonical form: the added children are instances of their own (one with a Transform and an override).
    const std::string scene = R"({
      "format": "factoria.scene/1",
      "settings": { "gravity2D": [0, -980], "gravity3D": [0, -9.81, 0] },
      "entities": [
        { "id": "host", "prefab": "prefabs/panel.prefab.json",
          "children": [
            { "id": "inner", "prefab": "prefabs/panel.prefab.json",
              "components": { "Transform": { "position": [4.0, 5.0, 0.0] } },
              "overrides": { "title": { "components": { "Text": { "text": "Inner" } } } } },
            { "id": "bare", "prefab": "prefabs/panel.prefab.json" } ] },
        { "id": "other", "prefab": "prefabs/panel.prefab.json" }
      ]})";
    World w;
    load(w, scene);
    CHECK(w.children(w.find_by_id("host")).size() == 4);  // title, Row, inner, bare
    std::vector<PrefabExpanded> expanded;
    const std::string want = dump_scene_json(Json::parse(scene)["entities"]);
    CHECK(saved_entities_text(w, &expanded) == want);
    CHECK(expanded.empty());

    // The marks of the in-memory snapshot keep it too.
    World w2;
    REQUIRE(load_scene(w2, snapshot_scene(w), "<snapshot>").ok());
    CHECK(saved_entities_text(w2, &expanded) == want);
    CHECK(expanded.empty());
    CHECK_FALSE(w2.info(w2.find_by_id("inner")).fromPrefab);

    // An edit inside the added instance and one in the host are both kept, each at its own level.
    w.get<Sprite>(w.find_by_id("inner"))->layer = 8;
    w.get<Text>(w.find_by_id("title"))->text = "Host title";
    Json host = saved_entity(w, "host", &expanded);
    CHECK(expanded.empty());
    CHECK(host["overrides"]["title"]["components"]["Text"]["text"] == "Host title");
    CHECK(host["children"][0]["components"]["Sprite"]["layer"] == 8);
    CHECK(host["children"][0]["prefab"] == "prefabs/panel.prefab.json");
}
