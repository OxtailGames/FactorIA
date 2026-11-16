// scene.copy_entities and scene.paste_entities (tools/authoring/src/scene_clipboard_commands.cpp): the entity clipboard.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <set>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/serialize.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Clipboard Test",
  "id": "com.example.clipboard",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// Joint3D.connected is an Entity field: "link" points at "anchor" (outside a copy of "link" alone), "pair_a" at its sibling
// "pair_b" and the child "pair_c" at its own parent "pair_a".
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "anchor", "name": "Anchor", "components": { "Transform": { "position": [5, 0, 0] } } },
    { "id": "squad", "name": "Squad", "tags": ["enemy"],
      "components": { "Transform": { "position": [120, 40, 0], "scale": [2, 2, 1] }, "Shape2D": { "size": [30, 20] } },
      "children": [
        { "id": "gunner", "name": "Gunner", "components": { "Transform": { "position": [10, 5, 0] } } }
      ] },
    { "id": "link", "name": "Link", "components": { "Joint3D": { "connected": "anchor" } } },
    { "id": "holder", "name": "Holder", "children": [
      { "id": "pair_a", "name": "A", "components": { "Joint3D": { "connected": "pair_b" } },
        "children": [ { "id": "pair_c", "components": { "Joint3D": { "connected": "pair_a" } } } ] },
      { "id": "pair_b", "name": "B" }
    ] },
    { "id": "e7", "name": "Auto" },
    { "prefab": "prefabs/pair.prefab.json", "id": "inst" }
  ]
})";

const char* kOther = R"({
  "format": "factoria.scene/1",
  "entities": [ { "id": "squad", "name": "Other squad" }, { "id": "e7" } ]
})";

const char* kOtherEmpty = R"({ "format": "factoria.scene/1", "entities": [] })";

const char* kPrefab = R"({
  "format": "factoria.prefab/1",
  "entity": { "id": "pair", "name": "Pair", "components": { "Transform": { "position": [1, 2, 0] } },
              "children": [ { "id": "left", "name": "Left" }, { "id": "right", "name": "Right" } ] }
})";

struct Session {
    stdfs::path dir;
    Engine engine;
    Session() {
        dir = fs::make_temp_dir("fa_clipboard_test").value();
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        write("scenes/other.scene.json", kOther);
        write("scenes/empty.scene.json", kOtherEmpty);
        write("prefabs/pair.prefab.json", kPrefab);
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
    }
    ~Session() {
        engine.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    CommandResult call(const std::string& cmd, const Json& args = Json::object()) {
        return engine.commands().call(cmd, args);
    }
    World& world() { return engine.world(); }
    // copy_entities of these ids; the text.
    std::string copy(std::vector<std::string> ids) {
        Json a = Json::object({{"ids", Json::array()}});
        for (const std::string& id : ids) a["ids"].push_back(id);
        CommandResult r = call("scene.copy_entities", a);
        REQUIRE_MESSAGE(r.ok, error_text(r));
        return r.result["text"].get<std::string>();
    }
    static std::string error_text(const CommandResult& r) {
        if (r.ok) return std::string();
        return r.error.value("code", std::string()) + ": " + r.error.value("message", std::string()) + " | " +
               r.error.value("hint", std::string());
    }
    CommandResult paste(const std::string& text, Json extra = Json::object()) {
        extra["text"] = text;
        return call("scene.paste_entities", extra);
    }
    Entity find(const std::string& id) { return world().find_by_id(id); }
    // The Entity a field of a component holds, as an id ("" for none).
    std::string joint_target(const std::string& id) {
        Entity e = find(id);
        REQUIRE_FALSE(e.is_null());
        const TypeInfo* t = TypeRegistry::global().find("Joint3D");
        REQUIRE(t != nullptr);
        const void* obj = world().get(e, *t);
        REQUIRE(obj != nullptr);
        const Entity target = *static_cast<const Entity*>(t->field("connected")->ptr(obj));
        return target.is_null() || !world().alive(target) ? std::string() : world().id_of(target);
    }
};

bool contains(const std::string& s, const std::string& needle) { return s.find(needle) != std::string::npos; }

}  // namespace

TEST_CASE("scene.copy_entities / scene.paste_entities: a round trip keeps the components, tags and children") {
    Session s;
    const std::size_t before = s.world().entity_count();
    const CommandResult c = s.call("scene.copy_entities", Json::object({{"ids", Json::array({"squad"})}}));
    REQUIRE_MESSAGE(c.ok, Session::error_text(c));
    CHECK(c.result["count"] == 2);
    CHECK(c.result["roots"] == Json::array({"squad"}));
    CHECK(s.world().entity_count() == before);  // copying changes nothing

    const CommandResult p = s.paste(c.result["text"].get<std::string>());
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    CHECK(p.result["count"] == 2);
    CHECK(p.result["cleared"].empty());
    REQUIRE(p.result["ids"].size() == 1);
    const std::string id = p.result["ids"][0].get<std::string>();
    CHECK(id != "squad");
    CHECK(s.world().entity_count() == before + 2);

    const Entity copy = s.find(id);
    REQUIRE_FALSE(copy.is_null());
    CHECK(s.world().info(copy).name == "Squad");
    CHECK(s.world().info(copy).tags == std::vector<std::string>{"enemy"});
    CHECK(s.world().parent(copy).is_null());
    REQUIRE(s.world().children(copy).size() == 1);
    const Entity kid = s.world().children(copy)[0];
    CHECK(s.world().info(kid).name == "Gunner");
    CHECK(s.world().id_of(kid) != "gunner");

    Json a = entity_to_json(s.world(), s.find("squad"));
    Json b = entity_to_json(s.world(), copy);
    for (Json* j : {&a, &b}) {
        j->erase("id");
        (*j)["children"][0].erase("id");
    }
    CHECK(a == b);
}

TEST_CASE("scene.paste_entities: ids are the next free number, and a list with a parent and its child copies once") {
    Session s;
    // coin_3 style numbering and the engine's own e<N> ids.
    CHECK(s.paste(s.copy({"e7"})).result["ids"][0] != "e7");
    const std::string first = s.paste(s.copy({"squad"})).result["ids"][0].get<std::string>();
    const std::string second = s.paste(s.copy({"squad"})).result["ids"][0].get<std::string>();
    CHECK(first == "squad_2");
    CHECK(second == "squad_3");
    CHECK(s.paste(s.copy({"squad_3"})).result["ids"][0] == "squad_4");

    const CommandResult c = s.call("scene.copy_entities", Json::object({{"ids", Json::array({"gunner", "squad"})}}));
    REQUIRE_MESSAGE(c.ok, Session::error_text(c));
    CHECK(c.result["roots"] == Json::array({"squad"}));  // gunner comes with its parent, once
    CHECK(c.result["count"] == 2);
}

TEST_CASE("scene.paste_entities: parent, keepParents and nameSuffix") {
    Session s;
    const std::string text = s.copy({"pair_b", "squad"});
    // Under an explicit parent.
    CommandResult p = s.paste(text, Json::object({{"parent", "anchor"}}));
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    REQUIRE(p.result["ids"].size() == 2);
    for (const Json& id : p.result["ids"])
        CHECK(s.world().id_of(s.world().parent(s.find(id.get<std::string>()))) == "anchor");
    // Each under the parent it had (pair_b was under holder, squad was at the top), with a suffix.
    p = s.paste(text, Json::object({{"keepParents", true}, {"nameSuffix", " copy"}}));
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    const Entity b = s.find(p.result["ids"][0].get<std::string>());
    const Entity sq = s.find(p.result["ids"][1].get<std::string>());
    CHECK(s.world().id_of(s.world().parent(b)) == "holder");
    CHECK(s.world().parent(sq).is_null());
    CHECK(s.world().info(b).name == "B copy");
    CHECK(s.world().info(sq).name == "Squad copy");
    CHECK(s.world().info(s.world().children(sq)[0]).name == "Gunner");  // only the root is renamed
    // Explicit null: the top level.
    p = s.paste(text, Json::object({{"parent", nullptr}}));
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    CHECK(s.world().parent(s.find(p.result["ids"][0].get<std::string>())).is_null());
    // The two together contradict each other, and the world is not touched.
    const std::size_t n = s.world().entity_count();
    p = s.paste(text, Json::object({{"parent", "anchor"}, {"keepParents", true}}));
    CHECK_FALSE(p.ok);
    CHECK(contains(p.error.value("message", std::string()), "/keepParents"));
    CHECK(s.world().entity_count() == n);
}

TEST_CASE("scene.paste_entities: references inside the copied set name the copies") {
    Session s;
    // pair_a -> pair_b (siblings), pair_c -> pair_a (its parent): the whole "holder" subtree is copied.
    const CommandResult p = s.paste(s.copy({"holder"}));
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    CHECK(p.result["cleared"].empty());
    const Entity holder = s.find(p.result["ids"][0].get<std::string>());
    REQUIRE(s.world().children(holder).size() == 2);
    const std::string a = s.world().id_of(s.world().children(holder)[0]);
    const std::string b = s.world().id_of(s.world().children(holder)[1]);
    CHECK(a != "pair_a");
    CHECK(b != "pair_b");
    CHECK(s.joint_target(a) == b);  // the copy of pair_a points at the copy of pair_b
    const std::string c = s.world().id_of(s.world().children(s.find(a))[0]);
    CHECK(s.joint_target(c) == a);
    // The originals still point at each other.
    CHECK(s.joint_target("pair_a") == "pair_b");
    CHECK(s.joint_target("pair_c") == "pair_a");

    // Two roots of the set that point at each other.
    const CommandResult q = s.paste(s.copy({"pair_a", "pair_b"}));
    REQUIRE_MESSAGE(q.ok, Session::error_text(q));
    REQUIRE(q.result["ids"].size() == 2);
    CHECK(s.joint_target(q.result["ids"][0].get<std::string>()) == q.result["ids"][1].get<std::string>());
}

TEST_CASE(
    "scene.paste_entities: a reference outside the set is kept when the target exists and cleared when it does not") {
    Session s;
    const std::string text = s.copy({"link"});  // link -> anchor, which is not copied
    CommandResult p = s.paste(text);
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    CHECK(p.result["cleared"].empty());
    CHECK(s.joint_target(p.result["ids"][0].get<std::string>()) == "anchor");

    // Another scene without "anchor": the reference is cleared and the result says which.
    REQUIRE(s.call("scene.load", Json::object({{"path", "scenes/other.scene.json"}})).ok);
    p = s.paste(text);
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    const std::string id = p.result["ids"][0].get<std::string>();
    CHECK(id == "link");  // free in this scene: the copied id stays
    CHECK(s.joint_target(id).empty());
    REQUIRE(p.result["cleared"].size() == 1);
    const Json& cl = p.result["cleared"][0];
    CHECK(cl["entity"] == id);
    CHECK(cl["component"] == "Joint3D");
    CHECK(cl["field"] == "connected");
    CHECK(cl["target"] == "anchor");

    // A scene that has an entity with that id: kept (the id is what a reference means).
    REQUIRE(s.call("scene.load", Json::object({{"path", "scenes/main.scene.json"}})).ok);
    REQUIRE(s.call("scene.destroy", Json::object({{"id", "link"}})).ok);
    p = s.paste(text);
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    CHECK(s.joint_target(p.result["ids"][0].get<std::string>()) == "anchor");
}

TEST_CASE("scene.paste_entities: pasting into another scene keeps the free ids and the whole subtree") {
    Session s;
    const std::string text = s.copy({"squad", "holder"});
    REQUIRE(s.call("scene.load", Json::object({{"path", "scenes/empty.scene.json"}})).ok);
    CHECK(s.world().entity_count() == 0);
    const CommandResult p = s.paste(text);
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    CHECK(p.result["ids"] == Json::array({"squad", "holder"}));
    CHECK(p.result["count"] == 6);
    CHECK(s.world().entity_count() == 6);
    CHECK(s.joint_target("pair_a") == "pair_b");  // the references inside the set were rebuilt
    CHECK(s.joint_target("pair_c") == "pair_a");
    CHECK(s.world().info(s.find("gunner")).name == "Gunner");

    // A scene where "squad" exists: the copy gets another id.
    REQUIRE(s.call("scene.load", Json::object({{"path", "scenes/other.scene.json"}})).ok);
    const CommandResult q = s.paste(text);
    REQUIRE_MESSAGE(q.ok, Session::error_text(q));
    CHECK(q.result["ids"] == Json::array({"squad_2", "holder"}));
}

TEST_CASE("scene.copy_entities: an instance of a prefab stays linked to it in the copy") {
    Session s;
    const Entity inst = s.find("inst");
    REQUIRE_FALSE(inst.is_null());
    REQUIRE(s.world().info(inst).prefab == "prefabs/pair.prefab.json");
    const CommandResult p = s.paste(s.copy({"inst"}));
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    const Entity copy = s.find(p.result["ids"][0].get<std::string>());
    REQUIRE_FALSE(copy.is_null());
    CHECK(s.world().info(copy).prefab == "prefabs/pair.prefab.json");
    REQUIRE(s.world().children(copy).size() == 2);
    CHECK(s.world().info(s.world().children(copy)[0]).fromPrefab);
    CHECK(s.world().info(s.world().children(copy)[0]).name == "Left");
}

TEST_CASE("scene.paste_entities: text that is not an entity clipboard is an error that says where and how to fix it") {
    Session s;
    const std::size_t n = s.world().entity_count();
    struct Case {
        std::string text;
        std::string pointer;
        std::string words;
    };
    const std::string scene = R"({"format":"factoria.scene/1","entities":[]})";
    const std::vector<Case> cases = {
        {"", "/text", "empty"},
        {"   \n", "/text", "empty"},
        {"hello world", "/text", "not an entity clipboard"},
        {"{\"entities\":[]}", "/format", "no \"format\" key"},
        {"[1,2]", "/format", "no \"format\" key"},
        {scene, "/format", "scene.load"},
        {R"({"format":"factoria.entities/9","entities":[]})", "/format", "version '9'"},
        {R"({"format":"factoria.entities/1"})", "/entities", "non-empty array"},
        {R"({"format":"factoria.entities/1","entities":[]})", "/entities", "non-empty array"},
        {R"({"format":"factoria.entities/1","entities":[5]})", "/entities/0", "entity"},
        {R"({"format":"factoria.entities/1","entities":[{"entity":{"id":4}}]})", "/entities/0/entity/id", "string"},
        {R"({"format":"factoria.entities/1","entities":[{"entity":{"children":3}}]})", "/entities/0/entity/children",
         "array"},
    };
    for (const Case& c : cases) {
        const CommandResult r = s.paste(c.text);
        INFO(c.text);
        REQUIRE_FALSE(r.ok);
        const std::string message = r.error.value("message", std::string());
        CHECK(r.error.value("code", std::string()) == "invalid_argument");
        CHECK_MESSAGE(contains(message, c.pointer), message);
        CHECK_MESSAGE(contains(message + r.error.value("hint", std::string()), c.words), message);
        CHECK_FALSE(r.error.value("hint", std::string()).empty());
    }
    // A component the engine does not know: refused, and nothing of the text is left behind.
    const std::string bad =
        R"({"format":"factoria.entities/1","entities":[{"entity":{"id":"ok"}},{"entity":{"id":"bad","components":{"Nope":{}}}}]})";
    const CommandResult r = s.paste(bad);
    CHECK_FALSE(r.ok);
    CHECK(s.world().entity_count() == n);
    CHECK(s.find("ok").is_null());
}

TEST_CASE("scene.copy_entities: an unknown id is an error with suggestions, and no ids is refused") {
    Session s;
    CommandResult r = s.call("scene.copy_entities", Json::object({{"ids", Json::array({"squda"})}}));
    CHECK_FALSE(r.ok);
    CHECK(contains(r.error.value("message", std::string()), "squad"));
    r = s.call("scene.copy_entities", Json::object({{"ids", Json::array()}}));
    CHECK_FALSE(r.ok);
}

TEST_CASE("scene.copy_entities: 'primary' comes back as the pasted root that is or holds its copy") {
    Session s;
    // primary is the child of the second root: paste reports the copy of that root.
    CommandResult c =
        s.call("scene.copy_entities", Json::object({{"ids", Json::array({"anchor", "squad"})}, {"primary", "gunner"}}));
    REQUIRE_MESSAGE(c.ok, Session::error_text(c));
    CommandResult p = s.paste(c.result["text"].get<std::string>());
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    REQUIRE(p.result["ids"].size() == 2);
    CHECK(p.result["primary"] == p.result["ids"][1]);
    // Without 'primary' the result has none.
    p = s.paste(s.copy({"anchor"}));
    REQUIRE(p.ok);
    CHECK_FALSE(p.result.contains("primary"));
    // A primary outside the copied set is refused with its pointer.
    c = s.call("scene.copy_entities", Json::object({{"ids", Json::array({"anchor"})}, {"primary", "squad"}}));
    CHECK_FALSE(c.ok);
    CHECK(contains(c.error.value("message", std::string()), "/primary"));
}

TEST_CASE("scene.paste_entities: a text that was cut short says so") {
    Session s;
    const std::string whole = s.copy({"squad"});
    const CommandResult r = s.paste(whole.substr(0, whole.size() / 2));
    REQUIRE_FALSE(r.ok);
    CHECK(contains(r.error.value("message", std::string()), "cut short"));
    CHECK(contains(r.error.value("hint", std::string()), "fewer entities"));
}

TEST_CASE("scene.paste_entities: hostile or hand-edited texts are refused with a pointer, and leave nothing behind") {
    Session s;
    const std::size_t n = s.world().entity_count();
    auto entry = [](const std::string& entity) {
        return R"({"format":"factoria.entities/1","entities":[{"entity":)" + entity + "}]}";
    };
    struct Case {
        std::string text;
        Json extra;
        std::string pointer;
    };
    std::string deep = R"({"id":"leaf"})";
    for (int i = 0; i < 70; ++i) deep = R"({"id":"n)" + std::to_string(i) + R"(","children":[)" + deep + "]}";
    const std::vector<Case> cases = {
        // a non-string name with nameSuffix used to throw from the middle of the paste
        {entry(R"({"id":"ok","name":5})"), Json::object({{"nameSuffix", " copy"}}), "/entities/0/entity/name"},
        // a non-string id with a primary named in the text used to be an internal error
        {R"({"format":"factoria.entities/1","primary":"x","entities":[{"entity":{"id":4}}]})", Json::object(),
         "/entities/0/entity/id"},
        {R"({"format":"factoria.entities/1","primary":3,"entities":[{"entity":{"id":"a"}}]})", Json::object(),
         "/primary"},
        {entry(deep), Json::object(), "/children/"},
        {entry(R"({"prefab":"prefabs/pair.prefab.json"})"), Json::object(), "/entities/0/entity/prefab"},
        {entry(R"({"id":"ok","children":[{"prefab":"x"}]})"), Json::object(), "/entities/0/entity/children/0/prefab"},
        {entry(R"({"id":"ok","$prefab":"/etc/passwd"})"), Json::object(), "/entities/0/entity/$prefab"},
        {entry(R"({"id":"ok","$prefab":"../outside.prefab.json"})"), Json::object(), "/entities/0/entity/$prefab"},
    };
    for (const Case& c : cases) {
        const CommandResult r = s.paste(c.text, c.extra);
        INFO(c.text.substr(0, 120));
        REQUIRE_FALSE(r.ok);
        const std::string message = r.error.value("message", std::string());
        CHECK(r.error.value("code", std::string()) == "invalid_argument");
        CHECK_MESSAGE(contains(message, c.pointer), message);
        CHECK_FALSE(r.error.value("hint", std::string()).empty());
        CHECK(s.world().entity_count() == n);
    }
    // A $prefab inside the project is kept.
    const CommandResult ok = s.paste(entry(R"({"id":"ok2","$prefab":"prefabs/pair.prefab.json"})"));
    CHECK_MESSAGE(ok.ok, Session::error_text(ok));
    // `..` is refused as a path segment, never as part of a name.
    const CommandResult up = s.paste(entry(R"({"id":"ok3","$prefab":"prefabs/../prefabs/pair.prefab.json"})"));
    CHECK_FALSE(up.ok);
    const CommandResult dots = s.paste(entry(R"({"id":"ok4","$prefab":"prefabs/a..b.prefab.json"})"));
    CHECK_MESSAGE(!contains(Session::error_text(dots), "is not a project-relative prefab path"),
                  Session::error_text(dots));
}

TEST_CASE("scene.paste_entities: a text with CRLF line ends (a Windows clipboard) pastes like the same text with LF") {
    Session s;
    const Json parsed = Json::parse(s.copy({"squad", "link"}));
    std::string crlf;
    for (const char c : parsed.dump(2)) {
        if (c == '\n') crlf += '\r';
        crlf += c;
    }
    REQUIRE(crlf.find("\r\n") != std::string::npos);
    const CommandResult p = s.paste(crlf);
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    CHECK(p.result["ids"].size() == 2);
    CHECK(p.result["count"] == 3);
}

TEST_CASE("scene.paste_entities: a renumbered id never takes the id another entity of the text keeps") {
    Session s;
    // The text holds squad, squad_2 and squad_3; the scene has "squad" only, so squad_2 and squad_3 keep their ids and
    // squad goes to the next number that nothing wants: squad_4.
    Json payload = Json::parse(s.copy({"squad"}));
    const Json entry = payload["entities"][0];
    for (const char* id : {"squad_2", "squad_3"}) {
        Json more = entry;
        more["entity"]["id"] = id;
        more["entity"]["children"][0]["id"] = std::string(id) + "_gunner";
        payload["entities"].push_back(more);
    }
    const CommandResult p = s.paste(payload.dump());
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    CHECK(p.result["ids"] == Json::array({"squad_4", "squad_2", "squad_3"}));
    // A second paste of the same text: all three are taken, and nothing collides.
    const CommandResult q = s.paste(payload.dump());
    REQUIRE_MESSAGE(q.ok, Session::error_text(q));
    std::set<std::string> seen;
    for (const Json& id : q.result["ids"]) CHECK(seen.insert(id.get<std::string>()).second);
    CHECK(seen.size() == 3);
}

TEST_CASE("scene.paste_entities: keepParents with a parent that is not in this scene puts the root at the top level") {
    Session s;
    Json payload = Json::parse(s.copy({"pair_b"}));  // pair_b was under holder
    payload["entities"][0]["parent"] = "gone";
    const CommandResult p = s.paste(payload.dump(), Json::object({{"keepParents", true}}));
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    CHECK(s.world().parent(s.find(p.result["ids"][0].get<std::string>())).is_null());
}

TEST_CASE("scene.paste_entities: what the editor's Duplicate sends remaps references between selected siblings") {
    Session s;
    // pair_a points at its sibling pair_b; both are selected, so one text holds both roots, each under holder.
    const CommandResult p =
        s.paste(s.copy({"pair_a", "pair_b"}), Json::object({{"keepParents", true}, {"nameSuffix", " copy"}}));
    REQUIRE_MESSAGE(p.ok, Session::error_text(p));
    REQUIRE(p.result["ids"].size() == 2);
    const std::string a = p.result["ids"][0].get<std::string>();
    const std::string b = p.result["ids"][1].get<std::string>();
    CHECK(s.joint_target(a) == b);  // the copy of pair_a names the copy of pair_b, not the original
    CHECK(s.joint_target("pair_a") == "pair_b");
    CHECK(s.world().id_of(s.world().parent(s.find(a))) == "holder");
    CHECK(s.world().info(s.find(a)).name == "A copy");
    // The copy of pair_c (a child of the copy of pair_a) names the copy of pair_a.
    const std::string c = s.world().id_of(s.world().children(s.find(a))[0]);
    CHECK(s.joint_target(c) == a);
}

TEST_CASE("scene.copy_entities: a name that is not valid UTF-8 does not make the copy throw") {
    Session s;
    Entity e = s.find("anchor");
    REQUIRE_FALSE(e.is_null());
    s.world().info(e).name = "bad \xFF name";
    const CommandResult c = s.call("scene.copy_entities", Json::object({{"ids", Json::array({"anchor"})}}));
    REQUIRE_MESSAGE(c.ok, Session::error_text(c));
    CHECK(contains(c.result["text"].get<std::string>(), "bad "));
}
