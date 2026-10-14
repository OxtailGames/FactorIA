// prefab.save and scene.format: commands that write scene and prefab files (engine/runtime/src/scene_file_commands.cpp).
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
  "name": "File Commands Test",
  "id": "com.example.filecommands",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// A squad standing at (120, 40) with a gunner child, tagged by an earlier scene.import_ascii.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#102030" } } },
    { "id": "squad", "name": "Squad", "tags": ["enemy", "tilemap:level"],
      "components": { "Transform": { "position": [120, 40, 0], "rotation": [0, 0, 15], "scale": [2, 2, 1] },
                      "Shape2D": { "size": [30, 20], "color": "#cc3030", "layer": 3 } },
      "children": [
        { "id": "gunner", "name": "Gunner", "tags": ["gun"],
          "components": { "Transform": { "position": [10, 5, 0] },
                          "Shape2D": { "shape": "circle", "size": [8, 8], "color": "#ffd700" } } }
      ] },
    { "id": "boss", "name": "Boss",
      "components": { "Transform": { "position": [-60, 0, 0] }, "Shape2D": { "size": [40, 40] } },
      "children": [
        { "id": "turret", "components": { "Transform": { "position": [0, 20, 0] }, "ProbeLink": { "target": "boss", "power": 3 } } }
      ] },
    { "id": "lone", "components": { "ProbeLink": { "target": "cam", "power": 2 } } }
  ]
})";

// Test component with an Entity field, to check which references a saved prefab keeps.
struct ProbeLink {
    Entity target;
    int power = 1;
};

void register_probe_link() {
    auto& reg = TypeRegistry::global();
    if (!reg.of<ProbeLink>())
        reg.add<ProbeLink>("ProbeLink", "Test component pointing at another entity.", "Test")
            .field("target", &ProbeLink::target, "Entity it points at.")
            .field("power", &ProbeLink::power, "Strength.");
}

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name) {
        dir = fs::make_temp_dir("fa_filecmd_test_" + name);
        stdfs::create_directories(dir / "scenes");
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
    }
    ~TempProject() {
        std::error_code ec;
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
    bool exists(const std::string& rel) const { return stdfs::exists(dir / rel); }
    Json json(const std::string& rel) const { return Json::parse(read(rel)); }
};

struct Session {
    TempProject project;
    Engine engine;
    explicit Session(const std::string& name) : project(name) {
        register_probe_link();
        EngineConfig c;
        c.projectDir = project.dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
    }
    ~Session() { engine.shutdown(); }
    CommandResult call(const std::string& cmd, const Json& args = Json::object()) { return engine.commands().call(cmd, args); }
};

std::string error_text(const CommandResult& r) {
    return r.error.value("code", std::string()) + ": " + r.error.value("message", std::string()) + " | " +
           r.error.value("hint", std::string());
}

bool contains(const std::string& s, const std::string& needle) { return s.find(needle) != std::string::npos; }

bool has_note(const Json& result, const std::string& needle) {
    if (!result.contains("notes")) return false;
    for (const Json& n : result["notes"])
        if (contains(n.get<std::string>(), needle)) return true;
    return false;
}

// The saved entity with what a prefab does not carry removed, to compare an instance with its original.
void drop_ids(Json& entity) {
    entity.erase("id");
    if (entity.contains("children"))
        for (Json& c : entity["children"]) drop_ids(c);
}

// A scene written by hand the way people and AIs do: 4-space indent, every array on several lines, a flat tile list.
const char* kMessyScene = R"({
    "format": "factoria.scene/1",
    "settings": {
        "gravity2D": [
            0,
            -980
        ]
    },
    "entities": [
        {
            "id": "map",
            "tags": [
                "level",
                "solid"
            ],
            "components": {
                "Transform": {
                    "position": [ 100, 50, 0 ]
                },
                "Tilemap": {
                    "width": 4,
                    "height": 2,
                    "tileSize": [32,32],
                    "tiles": [-1, -1, 7, -1,
                              0, 0, 0, 12],
                    "solidTiles": [
                        0
                    ]
                }
            }
        }
    ]
})";

const char* kMessyPrefab = R"({"format":"factoria.prefab/1","entity":{"name":"Coin","tags":["coin","pickup"],
"components":{"Shape2D":{"shape":"circle","size":[12,12],"color":[1,0.8,0,1]},
"Transform":{"position":[0,12.5,0]}}}})";

}  // namespace

// ----------------------------------------------------------------------------------------------- prefab.save
TEST_CASE("prefab.save: documented like every built-in") {
    Session s("save_docs");
    const CommandInfo* info = s.engine.commands().info("prefab.save");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    CHECK(info->category == "scene");
    CHECK_FALSE(info->summary.empty());
    CHECK(contains(info->description, "Example"));
    CHECK(contains(info->description, "does NOT carry"));
    CHECK(contains(info->description, "Transform.position"));
    for (const char* prop : {"id", "path", "overwrite"})
        CHECK_MESSAGE(info->inputSchema["properties"].contains(prop), prop);
}

TEST_CASE("prefab.save: an entity with a child round-trips through instantiate_prefab") {
    Session s("save_roundtrip");
    World& w = s.engine.world();
    auto r = s.call("prefab.save", Json{{"id", "squad"}, {"path", "prefabs/squad.prefab.json"}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["path"] == "prefabs/squad.prefab.json");
    CHECK(r.result["entity"] == "squad");
    CHECK(r.result["children"] == 1);
    CHECK(r.result["overwritten"] == false);

    // The file is a prefab in the canonical compact layout.
    REQUIRE(s.project.exists("prefabs/squad.prefab.json"));
    const std::string text = s.project.read("prefabs/squad.prefab.json");
    Json file = Json::parse(text);
    CHECK(text == dump_scene_json(file));
    CHECK(contains(text, "\"scale\": [2.0, 2.0, 1.0]"));
    CHECK(file["format"] == "factoria.prefab/1");
    const Json& root = file["entity"];

    // What belongs to the instance, not to the prefab, is not saved.
    CHECK_FALSE(root.contains("id"));
    CHECK_FALSE(root["children"][0].contains("id"));
    CHECK_FALSE(root["components"]["Transform"].contains("position"));
    CHECK(root["components"]["Transform"]["scale"] == Json::parse("[2, 2, 1]"));
    CHECK(root["components"]["Transform"]["rotation"] == Json::parse("[0, 0, 15]"));
    CHECK(root["tags"] == Json::parse(R"(["enemy"])"));  // tilemap:level belongs to a scene.import_ascii run
    CHECK(root["children"][0]["components"]["Transform"]["position"] == Json::parse("[10, 5, 0]"));  // relative: kept
    CHECK(has_note(r.result, "Transform.position"));
    CHECK(has_note(r.result, "tilemap:level"));
    CHECK(has_note(r.result, "outside prefabs/") == false);

    // Instantiating the file gives back the same components (new ids, position at the origin).
    const std::size_t before = w.entity_count();
    LoadReport report;
    Entity copy = instantiate_prefab(w, "prefabs/squad.prefab.json", kNullEntity, report);
    REQUIRE_MESSAGE(report.ok(), report.summary());
    REQUIRE(bool(copy));
    CHECK(w.entity_count() == before + 2);
    CHECK(w.id_of(copy) != "squad");
    CHECK(w.world_position(copy).x == 0.0f);
    Json original = entity_to_json(w, w.find_by_id("squad"));
    Json instance = entity_to_json(w, copy);
    drop_ids(original);
    drop_ids(instance);
    original["components"]["Transform"].erase("position");
    original["tags"] = Json::parse(R"(["enemy"])");
    CHECK(instance == original);

    // scene.spawn places each instance itself.
    auto spawned = s.call("scene.spawn", Json{{"prefab", "prefabs/squad.prefab.json"}, {"position", Json::parse("[300, -20]")}});
    REQUIRE_MESSAGE(spawned.ok, error_text(spawned));
    CHECK(spawned.result["created"] == 2);
    CHECK(w.world_position(w.find_by_id(spawned.result["id"].get<std::string>())).x == 300.0f);
}

TEST_CASE("prefab.save: refuses to overwrite unless overwrite is true") {
    Session s("save_overwrite");
    const Json args{{"id", "squad"}, {"path", "prefabs/squad.prefab.json"}};
    REQUIRE(s.call("prefab.save", args).ok);
    const std::string first = s.project.read("prefabs/squad.prefab.json");

    REQUIRE(s.call("scene.set_component", Json{{"id", "squad"}, {"component", "Shape2D"}, {"fields", Json{{"layer", 9}}}}).ok);
    auto refused = s.call("prefab.save", args);
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"] == "already_exists");
    CHECK(contains(error_text(refused), "prefabs/squad.prefab.json"));
    CHECK(contains(error_text(refused), "overwrite"));
    CHECK(contains(error_text(refused), "prefabs/squad_2.prefab.json"));
    CHECK(s.project.read("prefabs/squad.prefab.json") == first);  // untouched

    auto explicitFalse = s.call("prefab.save", Json{{"id", "squad"}, {"path", "prefabs/squad.prefab.json"}, {"overwrite", false}});
    CHECK_FALSE(explicitFalse.ok);

    Json again = args;
    again["overwrite"] = true;
    auto replaced = s.call("prefab.save", again);
    REQUIRE_MESSAGE(replaced.ok, error_text(replaced));
    CHECK(replaced.result["overwritten"] == true);
    CHECK(s.project.json("prefabs/squad.prefab.json")["entity"]["components"]["Shape2D"]["layer"] == 9);
}

TEST_CASE("prefab.save: bad paths and unknown ids explain the fix and write nothing") {
    Session s("save_errors");
    auto save = [&](const std::string& id, const std::string& path) {
        return s.call("prefab.save", Json{{"id", id}, {"path", path}});
    };

    auto noExt = save("squad", "prefabs/squad.json");
    REQUIRE_FALSE(noExt.ok);
    CHECK(noExt.error["code"] == "invalid_argument");
    CHECK(contains(error_text(noExt), ".prefab.json"));
    CHECK(contains(error_text(noExt), "prefabs/squad.prefab.json"));  // the corrected name

    auto bare = save("squad", "squad");
    REQUIRE_FALSE(bare.ok);
    CHECK(contains(error_text(bare), "prefabs/squad.prefab.json"));

    auto sceneName = save("squad", "scenes/level.scene.json");
    REQUIRE_FALSE(sceneName.ok);
    CHECK(contains(error_text(sceneName), "scene.save"));
    CHECK(contains(error_text(sceneName), "prefabs/level.prefab.json"));

    auto nameOnly = save("squad", "prefabs/.prefab.json");
    CHECK_FALSE(nameOnly.ok);

    auto escape = save("squad", "../elsewhere.prefab.json");
    REQUIRE_FALSE(escape.ok);
    CHECK(contains(error_text(escape), "escapes the project root"));

    auto outside = save("squad", (stdfs::temp_directory_path() / "fa_filecmd_outside.prefab.json").generic_string());
    REQUIRE_FALSE(outside.ok);
    CHECK(contains(error_text(outside), "outside the project"));
    CHECK_FALSE(stdfs::exists(stdfs::temp_directory_path() / "fa_filecmd_outside.prefab.json"));

    auto typo = save("sqad", "prefabs/x.prefab.json");
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["code"] == "not_found");
    CHECK(contains(error_text(typo), "Did you mean"));
    CHECK(contains(error_text(typo), "squad"));

    auto missingArg = s.call("prefab.save", Json{{"id", "squad"}});
    REQUIRE_FALSE(missingArg.ok);
    CHECK(missingArg.error["code"] == "invalid_arguments");

    CHECK_FALSE(s.project.exists("prefabs"));  // nothing was written by any of the failures

    // An absolute path inside the project is accepted and reported project-relative.
    auto absolute = save("squad", (s.project.dir / "prefabs" / "abs.prefab.json").generic_string());
    REQUIRE_MESSAGE(absolute.ok, error_text(absolute));
    CHECK(absolute.result["path"] == "prefabs/abs.prefab.json");
    CHECK(s.project.exists("prefabs/abs.prefab.json"));

    // Outside prefabs/ works but says that validation and project.info will not see it.
    auto elsewhere = save("squad", "extra/squad.prefab.json");
    REQUIRE_MESSAGE(elsewhere.ok, error_text(elsewhere));
    CHECK(has_note(elsewhere.result, "outside prefabs/"));
}

TEST_CASE("prefab.save: Entity fields keep the ids they need and drop references that would dangle") {
    Session s("save_refs");
    World& w = s.engine.world();

    // boss -> turret (child) -> points at boss: both ends are in the saved tree, so the boss id stays.
    auto boss = s.call("prefab.save", Json{{"id", "boss"}, {"path", "prefabs/boss.prefab.json"}});
    REQUIRE_MESSAGE(boss.ok, error_text(boss));
    Json bossFile = s.project.json("prefabs/boss.prefab.json");
    CHECK(bossFile["entity"]["id"] == "boss");
    CHECK_FALSE(bossFile["entity"]["children"][0].contains("id"));
    CHECK(bossFile["entity"]["children"][0]["components"]["ProbeLink"]["target"] == "boss");
    CHECK(bossFile["entity"]["children"][0]["components"]["ProbeLink"]["power"] == 3);
    CHECK_FALSE(has_note(boss.result, "outside the saved entity"));

    // The saved references work: with the original gone, the instance's turret points at the instance's boss.
    REQUIRE(s.call("scene.destroy", Json{{"id", "boss"}}).ok);
    LoadReport report;
    Entity copy = instantiate_prefab(w, "prefabs/boss.prefab.json", kNullEntity, report);
    REQUIRE_MESSAGE(report.ok(), report.summary());
    CHECK(w.id_of(copy) == "boss");
    Entity turret = w.children(copy)[0];
    CHECK(w.get<ProbeLink>(turret)->target == copy);

    // lone -> cam: cam is not part of the saved tree, so the reference is dropped (it would dangle in every instance).
    auto lone = s.call("prefab.save", Json{{"id", "lone"}, {"path", "prefabs/lone.prefab.json"}});
    REQUIRE_MESSAGE(lone.ok, error_text(lone));
    Json loneFile = s.project.json("prefabs/lone.prefab.json");
    CHECK_FALSE(loneFile["entity"].contains("id"));
    CHECK_FALSE(loneFile["entity"]["components"]["ProbeLink"].contains("target"));
    CHECK(loneFile["entity"]["components"]["ProbeLink"]["power"] == 2);
    CHECK(has_note(lone.result, "ProbeLink.target"));
    CHECK(has_note(lone.result, "'cam'"));
}

// ----------------------------------------------------------------------------------------------- scene.format
TEST_CASE("scene.format: documented like every built-in") {
    Session s("format_docs");
    const CommandInfo* info = s.engine.commands().info("scene.format");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    CHECK(info->category == "scene");
    CHECK_FALSE(info->summary.empty());
    CHECK(contains(info->description, "Example"));
    CHECK(contains(info->description, "notCanonical"));
    for (const char* prop : {"paths", "check"}) CHECK_MESSAGE(info->inputSchema["properties"].contains(prop), prop);
}

TEST_CASE("scene.format: rewrites messy scenes and prefabs to exactly the dump_scene_json layout, twice is a no-op") {
    Session s("format_exact");
    const TempProject& p = s.project;
    // main.scene.json starts canonical so that the lists below are about the two messy files only.
    p.write("scenes/main.scene.json", dump_scene_json(Json::parse(kScene)));
    p.write("scenes/messy.scene.json", kMessyScene);
    p.write("prefabs/coin.prefab.json", kMessyPrefab);
    const Json sceneData = Json::parse(kMessyScene);
    const Json prefabData = Json::parse(kMessyPrefab);

    auto r = s.call("scene.format");
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["formatted"] == Json::parse(R"(["prefabs/coin.prefab.json", "scenes/messy.scene.json"])"));
    CHECK(r.result["unchanged"] == 1);
    CHECK(r.result["errors"].empty());
    CHECK_FALSE(r.result.contains("notCanonical"));

    const std::string scene = p.read("scenes/messy.scene.json");
    const std::string prefab = p.read("prefabs/coin.prefab.json");
    CHECK(scene == dump_scene_json(sceneData));
    CHECK(prefab == dump_scene_json(prefabData));
    CHECK(Json::parse(scene) == sceneData);  // the data is identical, key order included
    CHECK(Json::parse(prefab) == prefabData);
    // Spot checks of the layout itself.
    CHECK(contains(scene, "\"gravity2D\": [0, -980]"));
    CHECK(contains(scene, "\"tags\": [\"level\", \"solid\"]"));
    CHECK(contains(scene, "\"position\": [100, 50, 0]"));
    CHECK(contains(scene, "\"tiles\": [\n"));
    CHECK(contains(scene, "-1, -1,  7, -1,\n"));  // a Tilemap's tiles: one map row per line, columns aligned
    CHECK(contains(scene, " 0,  0,  0, 12"));
    CHECK(contains(prefab, "\"color\": [1, 0.8, 0, 1]"));
    CHECK(contains(prefab, "\"position\": [0, 12.5, 0]"));

    // A second run changes nothing: no file is listed or touched.
    const auto stamp = stdfs::last_write_time(p.dir / "scenes/messy.scene.json");
    auto second = s.call("scene.format");
    REQUIRE_MESSAGE(second.ok, error_text(second));
    CHECK(second.result["formatted"].empty());
    CHECK(second.result["unchanged"] == 3);
    CHECK(second.result["errors"].empty());
    CHECK(p.read("scenes/messy.scene.json") == scene);
    CHECK(p.read("prefabs/coin.prefab.json") == prefab);
    CHECK(stdfs::last_write_time(p.dir / "scenes/messy.scene.json") == stamp);
}

TEST_CASE("scene.format: check lists the files that are not canonical and writes nothing") {
    Session s("format_check");
    const TempProject& p = s.project;
    p.write("scenes/main.scene.json", dump_scene_json(Json::parse(kScene)));
    p.write("scenes/messy.scene.json", kMessyScene);
    p.write("prefabs/coin.prefab.json", kMessyPrefab);
    p.write("prefabs/ok.prefab.json", dump_scene_json(Json::parse(kMessyPrefab)));

    auto r = s.call("scene.format", Json{{"check", true}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["notCanonical"] == Json::parse(R"(["prefabs/coin.prefab.json", "scenes/messy.scene.json"])"));
    CHECK(r.result["unchanged"] == 2);
    CHECK(r.result["errors"].empty());
    CHECK_FALSE(r.result.contains("formatted"));
    CHECK(p.read("scenes/messy.scene.json") == kMessyScene);
    CHECK(p.read("prefabs/coin.prefab.json") == kMessyPrefab);

    // Once formatted, check has nothing to list.
    REQUIRE(s.call("scene.format").ok);
    auto clean = s.call("scene.format", Json{{"check", true}});
    REQUIRE(clean.ok);
    CHECK(clean.result["notCanonical"].empty());
    CHECK(clean.result["unchanged"] == 4);
}

TEST_CASE("scene.format: check + strict fails with the files listed, and passes once they are canonical") {
    Session s("format_strict");
    const TempProject& p = s.project;
    p.write("scenes/main.scene.json", dump_scene_json(Json::parse(kScene)));
    p.write("scenes/messy.scene.json", kMessyScene);
    p.write("prefabs/coin.prefab.json", kMessyPrefab);

    // Without strict, check only lists; with strict it is an error whose message names every file and whose hint says what to run.
    CHECK(s.call("scene.format", Json{{"check", true}}).ok);
    auto bad = s.call("scene.format", Json{{"check", true}, {"strict", true}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["code"] == "not_canonical");
    CHECK(contains(error_text(bad), "scenes/messy.scene.json"));
    CHECK(contains(error_text(bad), "prefabs/coin.prefab.json"));
    CHECK(contains(error_text(bad), "2 scene/prefab file(s)"));
    CHECK(contains(bad.error["hint"].get<std::string>(), "scene.format without 'check'"));
    CHECK(p.read("scenes/messy.scene.json") == kMessyScene);  // check writes nothing, strict or not

    // strict is about check: on its own the command formats, as ever.
    auto fixed = s.call("scene.format", Json{{"strict", true}});
    REQUIRE_MESSAGE(fixed.ok, error_text(fixed));
    CHECK(fixed.result["formatted"].size() == 2);
    auto clean = s.call("scene.format", Json{{"check", true}, {"strict", true}});
    REQUIRE_MESSAGE(clean.ok, error_text(clean));
    CHECK(clean.result["notCanonical"].empty());

    const CommandInfo* info = s.engine.commands().info("scene.format");
    REQUIRE(info != nullptr);
    CHECK(info->inputSchema["properties"].contains("strict"));
    CHECK(contains(info->description, "not_canonical"));
}

TEST_CASE("scene.format: invalid JSON is reported with file, line and column and skipped") {
    Session s("format_invalid");
    const TempProject& p = s.project;
    p.write("scenes/main.scene.json", dump_scene_json(Json::parse(kScene)));
    p.write("scenes/messy.scene.json", kMessyScene);
    const std::string broken = "{\n  \"format\": \"factoria.scene/1\",\n  \"entities\": [\n    { \"id\": \"a\", }\n  ]\n}\n";
    p.write("scenes/broken.scene.json", broken);
    p.write("prefabs/list.prefab.json", "[1, 2]");

    for (bool check : {true, false}) {
        INFO(check);
        auto r = s.call("scene.format", Json{{"check", check}});
        REQUIRE_MESSAGE(r.ok, error_text(r));
        REQUIRE(r.result["errors"].size() == 2);
        const Json& e = r.result["errors"][0];
        CHECK(e["file"] == "prefabs/list.prefab.json");
        CHECK(contains(e["message"].get<std::string>(), "must be a JSON object"));
        const Json& bad = r.result["errors"][1];
        CHECK(bad["file"] == "scenes/broken.scene.json");
        CHECK(bad["line"] == 4);
        CHECK(bad["column"].get<int>() > 0);
        CHECK(contains(bad["message"].get<std::string>(), "scenes/broken.scene.json:4:"));
        CHECK(contains(bad["hint"].get<std::string>(), "trailing comma"));
        CHECK(contains(bad["hint"].get<std::string>(), "left unchanged"));
        CHECK(p.read("scenes/broken.scene.json") == broken);  // skipped, not touched
        CHECK(p.read("prefabs/list.prefab.json") == "[1, 2]");
        if (check) {
            CHECK(r.result["notCanonical"] == Json::parse(R"(["scenes/messy.scene.json"])"));
            CHECK(p.read("scenes/messy.scene.json") == kMessyScene);
        } else {
            CHECK(r.result["formatted"] == Json::parse(R"(["scenes/messy.scene.json"])"));  // the others were still done
            CHECK(p.read("scenes/messy.scene.json") == dump_scene_json(Json::parse(kMessyScene)));
        }
    }
}

TEST_CASE("scene.format: paths are files or folders; the default skips tool and export folders") {
    Session s("format_paths");
    const TempProject& p = s.project;
    p.write("scenes/main.scene.json", dump_scene_json(Json::parse(kScene)));
    p.write("scenes/a/messy.scene.json", kMessyScene);
    p.write("prefabs/coin.prefab.json", kMessyPrefab);
    p.write("prefabs/deep/coin2.prefab.json", kMessyPrefab);
    p.write(".factoria/cache/x.scene.json", kMessyScene);
    p.write("build/export/game/scenes/y.scene.json", kMessyScene);
    p.write("node_modules/pkg/z.prefab.json", kMessyPrefab);
    p.write("data/levels.json", "{ \"a\":   [1,\n 2] }");

    // One folder.
    auto folder = s.call("scene.format", Json{{"paths", Json::array({"prefabs"})}, {"check", true}});
    REQUIRE_MESSAGE(folder.ok, error_text(folder));
    CHECK(folder.result["notCanonical"] == Json::parse(R"(["prefabs/coin.prefab.json", "prefabs/deep/coin2.prefab.json"])"));

    // One file and an absolute path inside the project; the same file given twice counts once.
    auto file = s.call("scene.format", Json{{"paths", Json::array({"scenes/a/messy.scene.json", (p.dir / "scenes/a/messy.scene.json").generic_string()})}});
    REQUIRE_MESSAGE(file.ok, error_text(file));
    CHECK(file.result["formatted"] == Json::parse(R"(["scenes/a/messy.scene.json"])"));
    CHECK(p.read("prefabs/coin.prefab.json") == kMessyPrefab);  // not selected, not touched

    // The default run: the project, without .factoria, node_modules, a top-level build/ and non-scene JSON.
    auto all = s.call("scene.format", Json{{"check", true}});
    REQUIRE_MESSAGE(all.ok, error_text(all));
    CHECK(all.result["notCanonical"] == Json::parse(R"(["prefabs/coin.prefab.json", "prefabs/deep/coin2.prefab.json"])"));
    CHECK(all.result["unchanged"] == 2);
    CHECK(p.read("data/levels.json") == "{ \"a\":   [1,\n 2] }");

    // A folder with no scenes says so.
    auto none = s.call("scene.format", Json{{"paths", Json::array({"data"})}});
    REQUIRE(none.ok);
    CHECK(none.result["formatted"].empty());
    CHECK(has_note(none.result, "No .scene.json or .prefab.json files found in 'data'"));
}

TEST_CASE("scene.format: bad arguments are refused before any file is written") {
    Session s("format_args");
    const TempProject& p = s.project;
    p.write("scenes/messy.scene.json", kMessyScene);

    auto typo = s.call("scene.format", Json{{"paths", Json::array({"scenes/messy.scene.json", "scenes/mesy.scene.json"})}});
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["code"] == "not_found");
    CHECK(contains(error_text(typo), "paths[1]"));
    CHECK(contains(error_text(typo), "Did you mean"));
    CHECK(contains(error_text(typo), "scenes/messy.scene.json"));

    auto notScene = s.call("scene.format", Json{{"paths", Json::array({"scenes/messy.scene.json", "factoria.json"})}});
    REQUIRE_FALSE(notScene.ok);
    CHECK(notScene.error["code"] == "invalid_argument");
    CHECK(contains(error_text(notScene), "not a scene or prefab file"));
    CHECK(contains(error_text(notScene), ".scene.json"));

    auto escape = s.call("scene.format", Json{{"paths", Json::array({"../elsewhere"})}});
    REQUIRE_FALSE(escape.ok);
    CHECK(contains(error_text(escape), "escapes the project root"));

    auto outside = s.call("scene.format", Json{{"paths", Json::array({stdfs::temp_directory_path().generic_string()})}});
    REQUIRE_FALSE(outside.ok);
    CHECK(contains(error_text(outside), "outside the project"));

    CHECK_FALSE(s.call("scene.format", Json{{"paths", Json::array()}}).ok);
    CHECK_FALSE(s.call("scene.format", Json{{"paths", "scenes"}}).ok);
    CHECK_FALSE(s.call("scene.format", Json{{"check", "yes"}}).ok);

    CHECK(p.read("scenes/messy.scene.json") == kMessyScene);  // none of the failed calls wrote anything
}

TEST_CASE("scene.format: a byte order mark and CRLF line endings are canonicalised, the data is kept") {
    Session s("format_bom");
    const TempProject& p = s.project;
    const Json data = Json::parse(kMessyPrefab);
    std::string crlf;
    for (char c : dump_scene_json(data)) {
        if (c == '\n') crlf += '\r';
        crlf += c;
    }
    p.write("scenes/main.scene.json", dump_scene_json(Json::parse(kScene)));
    p.write("prefabs/windows.prefab.json", "\xEF\xBB\xBF" + crlf);

    auto check = s.call("scene.format", Json{{"check", true}});
    REQUIRE(check.ok);
    CHECK(check.result["notCanonical"] == Json::parse(R"(["prefabs/windows.prefab.json"])"));

    REQUIRE(s.call("scene.format").ok);
    CHECK(p.read("prefabs/windows.prefab.json") == dump_scene_json(data));
    CHECK(p.json("prefabs/windows.prefab.json") == data);
}

TEST_CASE("scene.format: formats what prefab.save wrote, and a hand-formatted copy of it") {
    Session s("format_after_save");
    REQUIRE(s.call("prefab.save", Json{{"id", "squad"}, {"path", "prefabs/squad.prefab.json"}}).ok);
    auto clean = s.call("scene.format", Json{{"paths", Json::array({"prefabs"})}, {"check", true}});
    REQUIRE(clean.ok);
    CHECK(clean.result["notCanonical"].empty());  // prefab.save already writes the canonical layout
    CHECK(clean.result["unchanged"] == 1);

    // Hand-edited into a 4-space layout, it is canonical again after one scene.format.
    const std::string canonical = s.project.read("prefabs/squad.prefab.json");
    s.project.write("prefabs/squad.prefab.json", Json::parse(canonical).dump(4));
    auto dirty = s.call("scene.format", Json{{"paths", Json::array({"prefabs/squad.prefab.json"})}});
    REQUIRE(dirty.ok);
    CHECK(dirty.result["formatted"].size() == 1);
    CHECK(s.project.read("prefabs/squad.prefab.json") == canonical);
}
