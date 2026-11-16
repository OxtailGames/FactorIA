// prefab.overrides, prefab.revert and prefab.apply (tools/authoring/src/prefab_override_commands.cpp).
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/serialize.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Prefab Overrides Test",
  "id": "com.example.prefaboverrides",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

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

// Instance a is untouched, b overrides Sprite.layer (and stands somewhere else), c is the odd one out.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "a", "prefab": "prefabs/panel.prefab.json" },
    { "id": "b", "prefab": "prefabs/panel.prefab.json",
      "components": { "Transform": { "position": [50, 0, 0] }, "Sprite": { "layer": 5 } } },
    { "id": "plain", "name": "Plain" }
  ]
})";

struct TempProject {
    stdfs::path dir;
    TempProject() {
        dir = fs::make_temp_dir("fa_prefab_overrides_test").value();
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        write("prefabs/panel.prefab.json", kPanel);
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::permissions(dir / "prefabs/panel.prefab.json", stdfs::perms::owner_write, stdfs::perm_options::add, ec);
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    std::string read(const std::string& rel) const {
        std::ifstream in(dir / rel, std::ios::binary);
        std::stringstream ss;
        ss << in.rdbuf();
        return ss.str();
    }
    Json json(const std::string& rel) const { return Json::parse(read(rel)); }
};

struct Session {
    TempProject project;
    Engine engine;
    Session() {
        EngineConfig c;
        c.projectDir = project.dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
    }
    ~Session() { engine.shutdown(); }
    CommandResult call(const std::string& cmd, const Json& args = Json::object()) {
        return engine.commands().call(cmd, args);
    }
    World& world() { return engine.world(); }
    Entity find(const char* id) { return world().find_by_id(id); }
    void set(const char* id, const char* component, const Json& fields) {
        const CommandResult r =
            call("scene.set_component", Json{{"id", id}, {"component", component}, {"fields", fields}});
        REQUIRE_MESSAGE(r.ok, r.error.dump());
    }
    // The scene as scene.save writes it: the entry of one instance.
    Json saved(const char* id) {
        std::vector<PrefabExpanded> expanded;
        SaveSceneOptions o;
        o.prefabs = PrefabSave::Keep;
        o.prefabsExpanded = &expanded;
        const Json scene = save_scene(world(), o);
        for (const PrefabExpanded& x : expanded) MESSAGE("expanded " << x.id << ": " << x.reason);
        for (const Json& e : scene["entities"])
            if (e.value("id", "") == id) return e;
        MESSAGE(scene.dump());
        return Json();
    }
};

std::string error_text(const CommandResult& r) {
    if (r.ok) return std::string();
    return r.error.value("code", std::string()) + ": " + r.error.value("message", std::string()) + " | " +
           r.error.value("hint", std::string());
}

bool contains(const std::string& s, const std::string& needle) { return s.find(needle) != std::string::npos; }

const Json* find_item(const Json& list, const std::string& entity, const std::string& component,
                      const std::string& field = {}) {
    for (const Json& j : list)
        if (j.value("entity", "") == entity && j.value("component", "") == component && j.value("field", "") == field)
            return &j;
    return nullptr;
}

// Instance a with one of every kind of difference.
void make_edits(Session& s) {
    s.set("a", "Sprite", Json{{"layer", 9}});
    s.set("title", "Text", Json{{"text", "Edited"}});
    s.set("ok", "EntityInfo", Json{{"name", "Done"}});
    s.set("ok", "Shape2D", Json{{"layer", 4}});
    const CommandResult r = s.call(
        "scene.spawn", Json{{"id", "extra"}, {"parent", "a"}, {"name", "Extra"}, {"position", Json::array({1, 2})}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
}

}  // namespace

TEST_CASE("prefab commands: documented like every built-in") {
    Session s;
    for (const char* name : {"prefab.overrides", "prefab.revert", "prefab.apply"}) {
        const CommandInfo* info = s.engine.commands().info(name);
        REQUIRE_MESSAGE(info, name);
        CHECK_FALSE(info->description.empty());
        CHECK(contains(info->full_description(), "Example:"));
    }
    CHECK(s.engine.commands().info("prefab.overrides")->readOnly);
    CHECK_FALSE(s.engine.commands().info("prefab.revert")->readOnly);
}

TEST_CASE("prefab.overrides: nothing on a fresh instance, one entry per difference after edits") {
    Session s;
    CommandResult r = s.call("prefab.overrides", Json{{"id", "a"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["expressible"] == true);
    CHECK(r.result["count"] == 0);
    CHECK(r.result["prefab"] == "prefabs/panel.prefab.json");

    make_edits(s);
    r = s.call("prefab.overrides", Json{{"id", "a"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    const Json& list = r.result["overrides"];
    CHECK(r.result["count"] == 5);
    CHECK(list.size() == 5);
    const Json* layer = find_item(list, "a", "Sprite", "/layer");
    REQUIRE(layer);
    CHECK((*layer)["kind"] == "field");
    CHECK((*layer)["value"] == 9);
    CHECK((*layer)["prefabValue"] == 1);
    const Json* text = find_item(list, "title", "Text", "/text");  // a descendant
    REQUIRE(text);
    CHECK((*text)["value"] == "Edited");
    CHECK((*text)["prefabValue"] == "Hello");
    const Json* name = find_item(list, "ok", "EntityInfo", "/name");
    REQUIRE(name);
    CHECK((*name)["prefabValue"] == "Ok");
    const Json* added = find_item(list, "ok", "Shape2D");
    REQUIRE(added);
    CHECK((*added)["kind"] == "component");
    CHECK((*added)["value"]["layer"] == 4);
    const Json* child = find_item(list, "extra", "");
    REQUIRE(child);
    CHECK((*child)["kind"] == "child");

    // Asked of a descendant: that part only. Where the instance stands is listed, not counted.
    r = s.call("prefab.overrides", Json{{"id", "title"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["root"] == "a");
    CHECK(r.result["count"] == 1);
    s.set("a", "Transform", Json{{"position", Json::array({7, 8, 0})}});
    r = s.call("prefab.overrides", Json{{"id", "a"}});
    CHECK(r.result["count"] == 5);
    const Json* pos = find_item(r.result["overrides"], "a", "Transform", "/position");
    REQUIRE(pos);
    CHECK((*pos)["placement"] == true);
}

TEST_CASE("prefab.overrides: not an instance, and an instance whose differences cannot be listed") {
    Session s;
    CommandResult r = s.call("prefab.overrides", Json{{"id", "plain"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_a_prefab_instance");
    CHECK(contains(error_text(r), "scene.spawn"));
    r = s.call("prefab.overrides", Json{{"id", "nope"}});
    CHECK_FALSE(r.ok);

    // A child added under a part of the prefab cannot be written as an override.
    REQUIRE(s.call("scene.spawn", Json{{"id", "deep"}, {"parent", "ok"}}).ok);
    r = s.call("prefab.overrides", Json{{"id", "a"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["expressible"] == false);
    CHECK(contains(r.result["reason"].get<std::string>(), "deep"));
    CHECK(r.result["overrides"].empty());
    r = s.call("prefab.revert", Json{{"id", "a"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_expressible");
    r = s.call("prefab.apply", Json{{"id", "a"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_expressible");
}

TEST_CASE("prefab.revert: one field, one component, a descendant and the whole instance") {
    Session s;
    make_edits(s);
    s.set("a", "Transform", Json{{"position", Json::array({7, 8, 0})}});
    World& w = s.world();

    CommandResult r = s.call("prefab.revert", Json{{"id", "a"}, {"component", "Sprite"}, {"field", "/layer"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["reverted"].size() == 1);
    CHECK(w.get<Sprite>(s.find("a"))->layer == 1);
    CHECK(w.get<Text>(s.find("title"))->text == "Edited");  // the rest stays

    // The same call again has nothing to do, and says so.
    r = s.call("prefab.revert", Json{{"id", "a"}, {"component", "Sprite"}, {"field", "layer"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["reverted"].empty());
    CHECK(contains(r.result["notes"][0].get<std::string>(), "already equals"));

    // A component of a descendant: the one the prefab lacks goes.
    r = s.call("prefab.revert", Json{{"id", "ok"}, {"component", "Shape2D"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(w.get<Shape2D>(s.find("ok")) == nullptr);
    CHECK(w.info(s.find("ok")).name == "Done");

    // A part of the instance: that entity and what is below it.
    r = s.call("prefab.revert", Json{{"id", "title"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(w.get<Text>(s.find("title"))->text == "Hello");

    // The whole instance: the name, the child, and not where it stands.
    r = s.call("prefab.revert", Json{{"id", "a"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(w.info(s.find("ok")).name == "Ok");
    CHECK(s.find("extra").is_null());
    CHECK(w.get<Transform>(s.find("a"))->position.x == 7);
    const Json after = s.call("prefab.overrides", Json{{"id", "a"}}).result;
    CHECK(after["count"] == 0);
    CHECK(s.saved("a")["components"]["Transform"]["position"] == Json::parse("[7,8,0]"));

    // Where it stands, named.
    r = s.call("prefab.revert", Json{{"id", "a"}, {"component", "Transform"}, {"field", "/position"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(w.get<Transform>(s.find("a"))->position.x == 0);
    CHECK(s.saved("a") == Json::parse(R"({"id":"a","prefab":"prefabs/panel.prefab.json"})"));
}

TEST_CASE("prefab.revert: teaching errors") {
    Session s;
    make_edits(s);
    CommandResult r = s.call("prefab.revert", Json{{"id", "a"}, {"component", "Sprit"}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_text(r), "Sprite"));
    r = s.call("prefab.revert", Json{{"id", "a"}, {"component", "Sprite"}, {"field", "/layr"}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_text(r), "layer"));
    r = s.call("prefab.revert", Json{{"id", "a"}, {"field", "/layer"}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_text(r), "component"));
    r = s.call("prefab.revert", Json{{"id", "a"}, {"component", "Transform"}, {"field", "/position/0"}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_text(r), "ONE field"));
}

TEST_CASE("prefab.apply: a field goes into the file and the other instances follow, keeping their own overrides") {
    Session s;
    s.set("a", "Sprite", Json{{"layer", 9}});
    s.set("title", "Text", Json{{"text", "Edited"}});
    s.set("title_2", "Text", Json{{"text", "Mine"}});  // instance b's own override of the same field
    World& w = s.world();

    CommandResult r = s.call("prefab.apply", Json{{"id", "a"}, {"component", "Sprite"}, {"field", "/layer"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["files"] == Json::parse(R"(["prefabs/panel.prefab.json"])"));
    CHECK(r.result["applied"].size() == 1);
    CHECK(r.result["updated"] == Json::parse(R"(["b"])"));
    const Json file = s.project.json("prefabs/panel.prefab.json");
    CHECK(file["entity"]["components"]["Sprite"]["layer"] == 9);
    CHECK(file["entity"]["children"][0]["components"]["Text"]["text"] == "Hello");  // untouched
    CHECK(file["entity"]["children"][1]["children"][0]["id"] == "ok");              // the layout stays
    // b overrode layer 5 itself: kept. Instance a has nothing left to override.
    CHECK(w.get<Sprite>(s.find("b"))->layer == 5);
    CHECK(s.call("prefab.overrides", Json{{"id", "a"}}).result["count"] == 1);  // only the title text

    // A descendant's field: b has its own text, so it keeps it; a plain instance would take it.
    r = s.call("prefab.apply", Json{{"id", "title"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(s.project.json("prefabs/panel.prefab.json")["entity"]["children"][0]["components"]["Text"]["text"] ==
          "Edited");
    CHECK(w.get<Text>(s.find("title_2"))->text == "Mine");
    CHECK(s.call("prefab.overrides", Json{{"id", "a"}}).result["count"] == 0);
    CHECK(s.saved("b")["overrides"]["title"]["components"]["Text"]["text"] == "Mine");
}

TEST_CASE("prefab.apply: a plain instance takes the change; a component and a child added to the prefab") {
    Session s;
    // Instance c has nothing of its own.
    REQUIRE(s.call("scene.spawn", Json{{"prefab", "prefabs/panel.prefab.json"}, {"id", "c"}}).ok);
    make_edits(s);
    World& w = s.world();
    s.set("a", "Transform", Json{{"position", Json::array({7, 8, 0})}});

    CommandResult r = s.call("prefab.apply", Json{{"id", "a"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["applied"].size() == 5);
    const Json file = s.project.json("prefabs/panel.prefab.json");
    const Json& root = file["entity"];
    CHECK(root["components"]["Sprite"]["layer"] == 9);
    CHECK_FALSE(root["components"].contains("Transform"));  // where the instance stands is not the prefab's
    CHECK(root["children"][0]["components"]["Text"]["text"] == "Edited");
    CHECK(root["children"][1]["children"][0]["name"] == "Done");
    CHECK(root["children"][1]["children"][0]["components"]["Shape2D"]["layer"] == 4);
    REQUIRE(root["children"].size() == 3);
    CHECK(root["children"][2]["name"] == "Extra");
    CHECK(root["children"][2]["id"] == "extra");  // the id somebody chose is the prefab's own now

    // The instance applied is the prefab now: nothing to override, the child is the prefab's own.
    const Json after = s.call("prefab.overrides", Json{{"id", "a"}}).result;
    REQUIRE(after["expressible"] == true);
    CHECK(after["count"] == 0);
    CHECK(w.info(s.find("extra")).fromPrefab);
    CHECK(s.saved("a")["components"]["Transform"]["position"] == Json::parse("[7,8,0]"));

    // c and b got all of it (b keeps its layer and position).
    CHECK(r.result["updated"].size() == 2);
    CHECK(w.get<Text>(s.find("title_3"))->text == "Edited");
    CHECK(w.info(s.find("ok_3")).name == "Done");
    CHECK(w.get<Shape2D>(s.find("ok_3")) != nullptr);
    CHECK(w.get<Sprite>(s.find("c"))->layer == 9);
    CHECK(w.get<Sprite>(s.find("b"))->layer == 5);
    REQUIRE(w.children(s.find("c")).size() == 3);
    CHECK(w.info(w.children(s.find("c"))[2]).name == "Extra");
    CHECK(w.info(w.children(s.find("c"))[2]).fromPrefab);
    CHECK(s.call("prefab.overrides", Json{{"id", "c"}}).result["count"] == 0);
    CHECK(s.saved("c") == Json::parse(R"({"id":"c","prefab":"prefabs/panel.prefab.json"})"));
    CHECK(s.call("prefab.overrides", Json{{"id", "b"}}).result["count"] == 1);  // its layer
    // A scene saved now loads back into the same state.
    World again;
    SaveSceneOptions o;
    o.prefabs = PrefabSave::Keep;
    REQUIRE(load_scene(again, save_scene(w, o), "scene").ok());
    CHECK(again.children(again.find_by_id("a")).size() == 3);
}

TEST_CASE("prefab.apply: refuses a read-only file, a change the file has no place for, and changes nothing") {
    Session s;
    s.set("a", "Sprite", Json{{"layer", 9}});
    const std::string before = s.project.read("prefabs/panel.prefab.json");

    stdfs::permissions(s.project.dir / "prefabs/panel.prefab.json",
                       stdfs::perms::owner_write | stdfs::perms::group_write | stdfs::perms::others_write,
                       stdfs::perm_options::remove);
    CommandResult r = s.call("prefab.apply", Json{{"id", "a"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "read_only");
    CHECK(contains(error_text(r), "read-only"));
    CHECK(contains(error_text(r), "prefab.revert"));
    CHECK(s.project.read("prefabs/panel.prefab.json") == before);
    CHECK(s.world().get<Sprite>(s.find("b"))->layer == 5);
    stdfs::permissions(s.project.dir / "prefabs/panel.prefab.json", stdfs::perms::owner_write,
                       stdfs::perm_options::add);

    // A reference to an entity outside the prefab has no id the file could hold: listed as blocked, apply refuses.
    s.set("a", "Sprite", Json{{"layer", 1}});
    const CommandResult none = s.call("prefab.apply", Json{{"id", "a"}});
    REQUIRE_MESSAGE(none.ok, error_text(none));
    CHECK(none.result["applied"].empty());
    CHECK(s.project.read("prefabs/panel.prefab.json") == before);
}

TEST_CASE("prefab.apply: a missing prefab file is a teaching error") {
    Session s;
    s.set("a", "Sprite", Json{{"layer", 9}});
    stdfs::remove(s.project.dir / "prefabs/panel.prefab.json");
    const CommandResult r = s.call("prefab.apply", Json{{"id", "a"}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_text(r), "prefabs/panel.prefab.json"));
}
