// scene.import_ascii: ASCII rows + legend -> Tilemap + spawned objects (see engine/runtime/src/level_commands.cpp).
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/runtime/engine.h"
#include "fa/scene/tilemap.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Import Test",
  "id": "com.example.importtest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [ { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#102030" } } } ]
})";

const char* kCoinPrefab = R"({
  "format": "factoria.prefab/1",
  "entity": { "name": "Coin", "tags": ["coin"],
    "components": { "Shape2D": { "shape": "circle", "size": [12, 12], "color": "#ffd700", "layer": 5 },
                   "RigidBody2D": { "type": "static" },
                   "Collider2D": { "shape": "circle", "radius": 6, "isTrigger": true } } } })";

const char* kPlayerPrefab = R"({
  "format": "factoria.prefab/1",
  "entity": { "name": "Player", "tags": ["player"],
    "components": { "Shape2D": { "size": [20, 28], "color": "#00ff00", "layer": 6 },
                    "RigidBody2D": { "type": "dynamic", "fixedRotation": true },
                    "Collider2D": { "shape": "box", "size": [20, 28], "friction": 0 } } } })";

// Level used by most tests: 10x6, ground (tile 0) and bedrock (tile 1), 3 coins, 1 player spawn.
const char* kLevel = R"({
  "rows": [
    "..........",
    "...o..o...",
    "..........",
    ".P......o.",
    "##########",
    "@@@@@@@@@@"
  ],
  "legend": { "#": 0, "@": 1, "o": { "prefab": "prefabs/coin.prefab.json" },
              "P": { "prefab": "prefabs/player.prefab.json", "id": "player" } },
  "tilemap": { "tileset": "assets/tiles.png", "tileSize": [32, 32], "solidTiles": [0, 1] }
})";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name) {
        dir = fs::make_temp_dir("fa_import_test_" + name);
        stdfs::create_directories(dir / "scenes");
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        write("prefabs/coin.prefab.json", kCoinPrefab);
        write("prefabs/player.prefab.json", kPlayerPrefab);
        write("prefabs/enemy.prefab.json", R"({"format":"factoria.prefab/1","entity":{"name":"Crawler","components":{"Shape2D":{"size":[20,20]}}}})");
        // 128x32 tileset: 4 tiles of 32x32 (0 red, 1 blue, 2 green, 3 white).
        Image img;
        img.width = 128;
        img.height = 32;
        img.rgba.assign(std::size_t(128) * 32 * 4, 255);
        const Color colors[4] = {{1, 0, 0, 1}, {0, 0, 1, 1}, {0, 1, 0, 1}, {1, 1, 1, 1}};
        for (int y = 0; y < 32; ++y)
            for (int x = 0; x < 128; ++x) img.set_pixel(x, y, colors[x / 32]);
        std::vector<std::uint8_t> png = encode_png(img);
        stdfs::create_directories(dir / "assets");
        std::ofstream(dir / "assets/tiles.png", std::ios::binary).write(reinterpret_cast<const char*>(png.data()), std::streamsize(png.size()));
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
};

EngineConfig headless_cfg(const TempProject& p) {
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    return c;
}

// `startScene` = EngineConfig::scene (like `factoria call --scene`); empty = the project's mainScene is loaded by default.
struct Session {
    TempProject project;
    Engine engine;
    explicit Session(const std::string& name, const std::string& startScene = {}, bool editorMode = false) : project(name) {
        std::string err;
        EngineConfig cfg = headless_cfg(project);
        cfg.scene = startScene;
        cfg.editorMode = editorMode;
        REQUIRE_MESSAGE(engine.init(cfg, nullptr, &err), err);
    }
    ~Session() { engine.shutdown(); }
    CommandResult call(const std::string& cmd, const Json& args = Json::object()) { return engine.commands().call(cmd, args); }
    CommandResult import(Json args) { return call("scene.import_ascii", args); }
    std::size_t entities() { return engine.world().entity_count(); }
    Json entity(const std::string& id) {
        auto r = call("scene.get_entity", Json{{"id", id}});
        return r.ok ? r.result : Json(nullptr);
    }
};

// The base level with some top-level arguments replaced (whole values, not merged).
Json level(const char* patch = nullptr) {
    Json a = Json::parse(kLevel);
    if (patch) {
        Json p = Json::parse(patch);
        for (auto it = p.begin(); it != p.end(); ++it) a[it.key()] = it.value();
    }
    return a;
}

std::string error_text(const CommandResult& r) {
    return r.error.value("message", std::string()) + " | " + r.error.value("hint", std::string());
}

bool contains(const std::string& s, const std::string& needle) { return s.find(needle) != std::string::npos; }

Vec2 position_of(const Json& entity) {
    const Json& p = entity["components"]["Transform"]["position"];
    return {p[0].get<float>(), p[1].get<float>()};
}

std::vector<std::string> ids_with_tag(Session& s, const std::string& tag) {
    std::vector<std::string> out;
    for (Entity e : s.engine.world().find_by_tag(tag)) out.push_back(s.engine.world().id_of(e));
    return out;
}

}  // namespace

TEST_CASE("import_ascii: command is documented like every built-in") {
    Session s("docs");
    const CommandInfo* info = s.engine.commands().info("scene.import_ascii");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    CHECK(info->category == "scene");
    CHECK(contains(info->description, "Example"));
    CHECK(contains(info->description, "legend"));
    CHECK(contains(info->description, "tilemap:<entity>"));
    for (const char* prop : {"rows", "legend", "tilemap", "entity", "replace", "save", "position", "anchor"})
        CHECK_MESSAGE(info->inputSchema["properties"].contains(prop), prop);
}

TEST_CASE("import_ascii: a 10x6 level yields tiles, 3 coins, the player, at cell centres") {
    Session s("level");
    const std::size_t before = s.entities();
    auto r = s.import(level());
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["tilemap"] == "tilemap");
    CHECK(r.result["created"] == true);
    CHECK(r.result["width"] == 10);
    CHECK(r.result["height"] == 6);
    CHECK(r.result["tileCount"] == 20);
    CHECK(r.result["warnings"].empty());
    CHECK(r.result["tag"] == "tilemap:tilemap");

    // Tilemap entity: tiles are row-major, row 0 on top.
    Entity map = s.engine.world().find_by_id("tilemap");
    REQUIRE(bool(map));
    const Tilemap* tm = s.engine.world().get<Tilemap>(map);
    REQUIRE(tm != nullptr);
    CHECK(tm->width == 10);
    CHECK(tm->height == 6);
    CHECK(tm->columns == 0);  // not set: derived from the 128 px wide tileset
    CHECK(tileset_columns(*tm, 128) == 4);
    REQUIRE(tm->tiles.is_array());
    REQUIRE(tm->tiles.size() == 60);
    for (int i = 0; i < 40; ++i) CHECK(tm->tiles[i] == -1);
    for (int i = 40; i < 50; ++i) CHECK(tm->tiles[i] == 0);
    for (int i = 50; i < 60; ++i) CHECK(tm->tiles[i] == 1);

    // Exactly 3 coins and one player, new entities = tilemap + 3 + 1.
    CHECK(s.entities() == before + 5);
    CHECK(s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"] == 3);
    CHECK(s.call("scene.list_entities", Json{{"tag", "player"}}).result["total"] == 1);
    REQUIRE(r.result["spawned"].size() == 4);

    // Cell centre = ((col + 0.5) * 32, -(row + 0.5) * 32) for a tilemap whose top-left corner is the origin.
    struct Expect { const char* id; int col, row; };
    for (Expect x : {Expect{"coin_1", 3, 1}, Expect{"coin_2", 6, 1}, Expect{"player", 1, 3}, Expect{"coin_3", 8, 3}}) {
        INFO(x.id);
        Json e = s.entity(x.id);
        REQUIRE(e.is_object());
        Vec2 p = position_of(e);
        CHECK(p.x == doctest::Approx((x.col + 0.5f) * 32));
        CHECK(p.y == doctest::Approx(-(x.row + 0.5f) * 32));
    }
    // The output lists them in row-major order with cell and position.
    const Json& sp = r.result["spawned"];
    CHECK(sp[0]["id"] == "coin_1");
    CHECK(sp[0]["prefab"] == "prefabs/coin.prefab.json");
    CHECK(sp[0]["cell"] == Json::parse("[3,1]"));
    CHECK(sp[0]["position"][0] == 112);
    CHECK(sp[0]["position"][1] == -48);
    CHECK(sp[2]["id"] == "player");
    CHECK(sp[3]["id"] == "coin_3");

    // Objects are tagged for `replace`, and are plain top-level entities.
    CHECK(ids_with_tag(s, "tilemap:tilemap") == std::vector<std::string>{"coin_1", "coin_2", "player", "coin_3"});
    CHECK(s.engine.world().parent(s.engine.world().find_by_id("coin_1")).is_null());
}

TEST_CASE("import_ascii: objects line up with the solid tiles (the player stands on the ground)") {
    Session s("physics");
    auto r = s.import(level());
    REQUIRE_MESSAGE(r.ok, error_text(r));
    s.engine.step(90);
    // Ground row 4 has its top edge at y = -128; the player (28 high) rests on it, centre at about -114.
    Vec2 p = position_of(s.entity("player"));
    CHECK(p.y > -128.0f);
    CHECK(p.y < -100.0f);
    CHECK(p.x == doctest::Approx(48.0f).epsilon(0.02));
}

TEST_CASE("import_ascii: position and anchor place the map (bottom-left floor at y=0)") {
    Session s("anchor");
    auto r = s.import(level(R"({"anchor":"bottom-left","position":[0,0]})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    // 6 rows x 32 = 192 high: the top-left corner is at y = 192.
    CHECK(position_of(s.entity("tilemap")).y == doctest::Approx(192.0f));
    CHECK(position_of(s.entity("tilemap")).x == doctest::Approx(0.0f));
    Vec2 coin = position_of(s.entity("coin_1"));
    CHECK(coin.x == doctest::Approx(112.0f));
    CHECK(coin.y == doctest::Approx(192.0f - 48.0f));

    r = s.import(level(R"({"anchor":"center","position":[0,0]})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(position_of(s.entity("tilemap")).x == doctest::Approx(-160.0f));
    CHECK(position_of(s.entity("tilemap")).y == doctest::Approx(96.0f));
    CHECK(position_of(s.entity("coin_1")).x == doctest::Approx(-160.0f + 112.0f));

    // Without position/anchor an existing tilemap stays where it is.
    r = s.import(level());
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["created"] == false);
    CHECK(position_of(s.entity("tilemap")).y == doctest::Approx(96.0f));
}

TEST_CASE("import_ascii: legend offset, overrides, tile + prefab on one glyph, other tilemap entity") {
    Session s("legend");
    Json a = Json::parse(R"({
      "rows": ["..e.", "#..b"],
      "legend": {
        "#": 2,
        "e": { "prefab": "prefabs/enemy.prefab.json", "offset": [0, -4], "overrides": { "Shape2D": { "color": "#ff0000" } } },
        "b": { "tile": 3, "prefab": "prefabs/coin.prefab.json", "id": "bonus" }
      },
      "entity": "level", "tilemap": { "tileset": "assets/tiles.png", "tileSize": [32, 32] } })");
    auto r = s.import(a);
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["tilemap"] == "level");
    CHECK(r.result["tileCount"] == 2);  // '#' and the tile of 'b'
    Entity map = s.engine.world().find_by_id("level");
    REQUIRE(bool(map));
    const Tilemap* tm = s.engine.world().get<Tilemap>(map);
    CHECK(tm->tiles == Json::parse("[-1,-1,-1,-1,2,-1,-1,3]"));
    Json enemy = s.entity("enemy_1");
    REQUIRE(enemy.is_object());
    CHECK(position_of(enemy).x == doctest::Approx(2.5f * 32));
    CHECK(position_of(enemy).y == doctest::Approx(-16.0f - 4.0f));
    CHECK(enemy["components"]["Shape2D"]["color"] == Json::parse("[1,0,0,1]"));
    CHECK(enemy["tags"][0] == "tilemap:level");
    Json bonus = s.entity("bonus");
    REQUIRE(bonus.is_object());
    CHECK(position_of(bonus).x == doctest::Approx(3.5f * 32));
    CHECK(contains(bonus["tags"].dump(), "coin"));  // the prefab's own tag is kept
    CHECK(contains(bonus["tags"].dump(), "tilemap:level"));
}

TEST_CASE("import_ascii: columns stay 0 (derived from the tileset) unless the caller sets them") {
    Session s("columns");
    auto r = s.import(level());
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK_FALSE(r.result.contains("notes"));
    const Entity map = s.engine.world().find_by_id("tilemap");
    CHECK(s.engine.world().get<Tilemap>(map)->columns == 0);

    // 16x16 tiles in the same 128x32 image: 8 columns, 16 tiles, still nothing to set.
    r = s.import(level(R"({"tilemap":{"tileSize":[16,16]}})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(s.engine.world().get<Tilemap>(map)->columns == 0);
    CHECK(tileset_columns(*s.engine.world().get<Tilemap>(map), 128) == 8);
    CHECK_FALSE(r.result.contains("notes"));

    // An explicit value always wins (and is range-checked against the image).
    r = s.import(level(R"({"tilemap":{"tileSize":[16,16],"columns":2}})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(s.engine.world().get<Tilemap>(map)->columns == 2);
    CHECK_FALSE(r.result.contains("notes"));

    // An explicit columns from before describes the OLD tileSize: changing it without columns goes back to 0.
    r = s.import(level(R"({"tilemap":{"tileSize":[32,32]}})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(s.engine.world().get<Tilemap>(map)->columns == 0);
    REQUIRE(r.result.contains("notes"));
    CHECK(r.result["notes"][0].get<std::string>().find("columns was 2") != std::string::npos);

    // Untouched tileset/tileSize leave an explicit value alone.
    s.engine.world().get<Tilemap>(map)->columns = 4;
    r = s.import(level(R"({"tilemap":{"layer":-5}})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(s.engine.world().get<Tilemap>(map)->columns == 4);
}

TEST_CASE("import_ascii: scene.save round trip keeps tiles and objects") {
    Session s("roundtrip");
    auto r = s.import(level());
    REQUIRE_MESSAGE(r.ok, error_text(r));
    Json before = s.call("scene.list_entities", Json{{"limit", 100}}).result;
    const Json tilesBefore = s.engine.world().get<Tilemap>(s.engine.world().find_by_id("tilemap"))->tiles;

    REQUIRE(s.call("scene.save").ok);
    // The scene file has the tilemap and the objects as ordinary top-level entities.
    auto file = load_json_file((s.project.dir / "scenes/main.scene.json").generic_string());
    REQUIRE(file.ok());
    int coins = 0;
    bool hasPlayer = false;
    for (const Json& e : (*file)["entities"]) {
        if (e["id"].get<std::string>().rfind("coin_", 0) == 0) ++coins;
        if (e["id"] == "player") hasPlayer = true;
    }
    CHECK(coins == 3);
    CHECK(hasPlayer);

    auto rl = s.call("scene.reload");
    REQUIRE(rl.ok);
    CHECK(rl.result["ok"] == true);
    CHECK(rl.result["messages"].empty());
    Json after = s.call("scene.list_entities", Json{{"limit", 100}}).result;
    CHECK(after["total"] == before["total"]);
    for (std::size_t i = 0; i < before["entities"].size(); ++i) {
        CHECK(after["entities"][i]["id"] == before["entities"][i]["id"]);
        CHECK(after["entities"][i]["position"] == before["entities"][i]["position"]);
        CHECK(after["entities"][i]["tags"] == before["entities"][i]["tags"]);
    }
    const Tilemap* tm = s.engine.world().get<Tilemap>(s.engine.world().find_by_id("tilemap"));
    REQUIRE(tm != nullptr);
    CHECK(tm->tiles == tilesBefore);
    CHECK(tm->width == 10);
    CHECK(tm->height == 6);

    // Re-importing after the reload still finds the objects (tags are saved) and replaces them.
    r = s.import(level());
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["removed"].size() == 4);
    CHECK(s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"] == 3);
}

std::string slurp(const stdfs::path& p) {
    std::ifstream f(p, std::ios::binary);
    std::stringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

TEST_CASE("import_ascii: save:true writes a scene that was chosen, and says so loudly") {
    SUBCASE("after scene.load") {
        Session s("save");
        REQUIRE(s.call("scene.load", Json{{"path", "scenes/main.scene.json"}}).ok);
        auto r = s.import(level(R"({"save":true})"));
        REQUIRE_MESSAGE(r.ok, error_text(r));
        CHECK(r.result["saved"] == "scenes/main.scene.json");
        CHECK(contains(r.result["notes"].dump(), "SAVED 'scenes/main.scene.json'"));
        CHECK(contains(r.result["notes"][0].get<std::string>(), "\"path\""));
        auto file = load_json_file((s.project.dir / "scenes/main.scene.json").generic_string());
        REQUIRE(file.ok());
        CHECK((*file)["entities"].size() == 6);  // cam, tilemap, 3 coins, player
    }
    SUBCASE("with a start scene (factoria call --scene)") {
        Session s("save_cfg", "scenes/main.scene.json");
        auto r = s.import(level(R"({"save":true})"));
        REQUIRE_MESSAGE(r.ok, error_text(r));
        CHECK(r.result["saved"] == "scenes/main.scene.json");
    }
    SUBCASE("in the editor the open scene is always a choice") {
        Session s("save_editor", {}, true);
        auto r = s.import(level(R"({"save":true})"));
        REQUIRE_MESSAGE(r.ok, error_text(r));
        CHECK(r.result["saved"] == "scenes/main.scene.json");
    }
}

TEST_CASE("import_ascii: save:true without path is refused while the running scene is only the default mainScene") {
    Session s("save_refused");
    const std::string before = slurp(s.project.dir / "scenes/main.scene.json");
    auto r = s.import(level(R"({"save":true})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "unsafe_save");
    const std::string text = error_text(r);
    CHECK(contains(text, "scenes/main.scene.json"));  // names the file it would have overwritten
    CHECK(contains(text, "main scene"));
    CHECK(contains(text, "\"path\""));                // the fix
    CHECK(contains(text, "--scene"));
    CHECK(slurp(s.project.dir / "scenes/main.scene.json") == before);
    CHECK(s.entities() == 1);  // refused before anything was built: just the camera

    // Without save the same map is fine (it only changes the running world), and so is path.
    CHECK(s.import(level()).ok);
    CHECK(s.import(level(R"({"save":true,"path":"scenes/other.scene.json"})")).ok);
    CHECK(slurp(s.project.dir / "scenes/main.scene.json") == before);

    // Choosing the scene (even the same one) lifts the refusal.
    REQUIRE(s.call("scene.reload").ok);
    r = s.import(level(R"({"save":true})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["saved"] == "scenes/main.scene.json");
}

TEST_CASE("import_ascii: replace (default) does not duplicate objects, replace:false does") {
    Session s("replace");
    REQUIRE(s.import(level()).ok);
    const std::size_t count = s.entities();

    auto r = s.import(level());  // edited re-import: same objects again
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["created"] == false);
    CHECK(s.entities() == count);
    CHECK(r.result["removed"].size() == 4);
    CHECK(s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"] == 3);
    CHECK(r.result["spawned"][0]["id"] == "coin_1");  // ids are stable across re-imports

    // An edited map: one coin removed, one moved.
    Json edited = level();
    edited["rows"] = Json::parse(R"(["..........","...o......","..........",".P........","##########","@@@@@@@@@@"])");
    r = s.import(edited);
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"] == 1);
    CHECK(s.entities() == count - 2);

    // replace:false keeps the previous coins and adds new ones with fresh ids.
    Json coins = Json::parse(R"({"rows":["o.o"],"legend":{"o":{"prefab":"prefabs/coin.prefab.json"}},"replace":false})");
    const std::size_t beforeCoins = s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"].get<std::size_t>();
    r = s.import(coins);
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["removed"].empty());
    CHECK(s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"].get<std::size_t>() == beforeCoins + 2);
    CHECK(r.result["spawned"][0]["id"] == "coin_2");  // coin_1 is still alive
    CHECK(r.result["spawned"][1]["id"] == "coin_3");
    r = s.import(coins);
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"].get<std::size_t>() == beforeCoins + 4);

    // The default replace wipes all of them (they all belong to this tilemap).
    r = s.import(level());
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"] == 3);

    // Another tilemap entity has its own set of objects.
    Json other = level(R"({"entity":"background"})");
    other["legend"].erase("P");
    other["rows"][3] = ".......o..";
    r = s.import(other);
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["removed"].empty());
    CHECK(ids_with_tag(s, "tilemap:background").size() == 3);
    CHECK(ids_with_tag(s, "tilemap:tilemap").size() == 4);
}

TEST_CASE("import_ascii: errors teach, and a failed import changes nothing") {
    Session s("errors");
    REQUIRE(s.import(level()).ok);
    const Json snapshot = s.call("game.state", Json{{"maxEntities", 100}}).result["entities"];
    const std::size_t count = s.entities();
    auto expect_unchanged = [&] {
        CHECK(s.entities() == count);
        CHECK(s.call("game.state", Json{{"maxEntities", 100}}).result["entities"] == snapshot);
    };

    SUBCASE("ragged rows name the rows and their lengths") {
        auto r = s.import(level(R"({"rows":["..........","....","..........","..........","##########","@@@@@@@@@@@"]})"));
        REQUIRE_FALSE(r.ok);
        std::string t = error_text(r);
        CHECK(contains(t, "same length"));
        CHECK(contains(t, "row 0 has 10"));
        CHECK(contains(t, "row 1 has 4"));
        CHECK(contains(t, "row 5 has 11"));
        CHECK(contains(t, "Pad"));
        expect_unchanged();
    }
    SUBCASE("unknown glyph: row, column, glyph, legend glyphs and a did-you-mean") {
        auto r = s.import(level(R"({"rows":["..........","...O..x...","..........",".P........","##########","@@@@@@@@@@"]})"));
        REQUIRE_FALSE(r.ok);
        std::string t = error_text(r);
        CHECK(contains(t, "'O' first at row 1, column 3"));
        CHECK(contains(t, "'x' first at row 1, column 6"));
        CHECK(contains(t, "Did you mean 'o'"));
        CHECK(contains(t, "'#'"));
        CHECK(contains(t, "'P'"));
        CHECK(contains(t, "legend"));
        expect_unchanged();
    }
    SUBCASE("a legend value that is neither an integer nor an object") {
        auto r = s.import(level(R"({"legend":{"#":0,"o":"prefabs/coin.prefab.json"}})"));
        REQUIRE_FALSE(r.ok);
        std::string t = error_text(r);
        CHECK(contains(t, "legend['o']"));
        CHECK(contains(t, "tile index"));
        CHECK(contains(t, "{\"prefab\": \"prefabs/coin.prefab.json\"}"));
        expect_unchanged();
    }
    SUBCASE("a legend object with neither tile nor prefab, unknown keys, id without prefab") {
        auto r = s.import(level(R"({"legend":{"#":0,"@":1,"o":{"id":"x"},"P":{"prefab":"prefabs/player.prefab.json"}}})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "legend['o']"));
        CHECK(contains(error_text(r), "'id' but no 'prefab'"));
        r = s.import(level(R"({"legend":{"#":0,"@":1,"o":{"tile":null},"P":{"prefab":"prefabs/player.prefab.json"}}})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "legend['o'].tile"));
        r = s.import(level(R"({"legend":{"#":0,"@":1,"o":{}}})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "neither \"tile\" nor \"prefab\""));
        r = s.import(level(R"({"legend":{"#":0,"@":1,"o":{"prefabs":"prefabs/coin.prefab.json"}}})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "unknown key 'prefabs'"));
        CHECK(contains(error_text(r), "Did you mean 'prefab'"));
        r = s.import(level(R"({"legend":{"#":0,"@":1,"oo":3}})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "exactly one character"));
        expect_unchanged();
    }
    SUBCASE("a prefab that does not exist suggests the closest one") {
        auto r = s.import(level(R"({"legend":{"#":0,"@":1,"o":{"prefab":"prefabs/coins.prefab.json"},"P":{"prefab":"prefabs/player.prefab.json"}}})"));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "not_found");
        std::string t = error_text(r);
        CHECK(contains(t, "legend['o'].prefab 'prefabs/coins.prefab.json' does not exist"));
        CHECK(contains(t, "Did you mean 'prefabs/coin.prefab.json'"));
        expect_unchanged();
    }
    SUBCASE("a fixed id used by two cells names both") {
        auto r = s.import(level(R"({"legend":{"#":0,"@":1,"o":{"prefab":"prefabs/coin.prefab.json","id":"coin"},"P":{"prefab":"prefabs/player.prefab.json"}}})"));
        REQUIRE_FALSE(r.ok);
        std::string t = error_text(r);
        CHECK(contains(t, "id 'coin' is used by two cells"));
        CHECK(contains(t, "row 1, column 3"));
        CHECK(contains(t, "row 1, column 6"));
        expect_unchanged();
    }
    SUBCASE("a fixed id already used by another entity") {
        auto r = s.import(level(R"({"legend":{"#":0,"@":1,"o":{"prefab":"prefabs/coin.prefab.json"},"P":{"prefab":"prefabs/player.prefab.json","id":"cam"}}})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "id 'cam'"));
        CHECK(contains(error_text(r), "already used"));
        expect_unchanged();
    }
    SUBCASE("tile indices: negative, and outside the tileset when it is known") {
        auto r = s.import(level(R"({"legend":{"#":-5,"@":1}})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "legend['#']"));
        CHECK(contains(error_text(r), "-5"));
        r = s.import(level(R"({"legend":{"#":0,"@":9,"o":{"prefab":"prefabs/coin.prefab.json"},"P":{"prefab":"prefabs/player.prefab.json","id":"player"}}})"));
        REQUIRE_FALSE(r.ok);
        std::string t = error_text(r);
        CHECK(contains(t, "legend['@'] uses tile 9"));
        CHECK(contains(t, "holds only 4 tiles"));
        CHECK(contains(t, "0..3"));
        expect_unchanged();
    }
    SUBCASE("bad override component or field, and a bad 'tilemap' value, are rolled back") {
        auto r = s.import(level(R"({"legend":{"#":0,"@":1,"o":{"prefab":"prefabs/coin.prefab.json","overrides":{"Shapee2D":{"size":[1,1]}}},"P":{"prefab":"prefabs/player.prefab.json","id":"player"}}})"));
        REQUIRE_FALSE(r.ok);
        std::string t = error_text(r);
        CHECK(contains(t, "legend['o']"));
        CHECK(contains(t, "row 1, column 3"));
        CHECK(contains(t, "Shapee2D"));
        expect_unchanged();
        r = s.import(level(R"({"tilemap":{"tileSizee":[8,8]}})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "tileSizee"));
        CHECK(contains(error_text(r), "tileSize"));
        expect_unchanged();
        r = s.import(level(R"({"tilemap":{"tiles":[1,2]}})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "'tilemap.tiles' cannot be set"));
        expect_unchanged();
    }
    SUBCASE("the entity must be a Tilemap, rows must exist, anchor is checked") {
        auto r = s.import(level(R"({"entity":"cam"})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "exists but has no Tilemap"));
        r = s.import(level(R"({"rows":[]})"));
        REQUIRE_FALSE(r.ok);
        r = s.import(level(R"({"anchor":"middle"})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "middle"));
        CHECK(contains(error_text(r), "center"));
        r = s.call("scene.import_ascii", Json::parse(R"({"rows":["#"]})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "legend"));
        expect_unchanged();
    }
}

TEST_CASE("import_ascii: unknown glyphs are reported together and warnings point at likely mistakes") {
    Session s("warnings");
    auto r = s.import(Json::parse(R"({"rows":["ab.c","..cc"],"legend":{"a":0}})"));
    REQUIRE_FALSE(r.ok);
    std::string t = error_text(r);
    CHECK(contains(t, "'b' first at row 0, column 1"));
    CHECK(contains(t, "'c' first at row 0, column 3 (3 times)"));

    // New tilemap without tileset/solidTiles, and a legend glyph that never appears.
    r = s.import(Json::parse(R"({"rows":["a.","..."],"legend":{"a":0,"z":1}})"));
    REQUIRE_FALSE(r.ok);  // ragged
    r = s.import(Json::parse(R"({"rows":["a.","a."],"legend":{"a":0,"z":1}})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    std::string w = r.result["warnings"].dump();
    CHECK(contains(w, "legend['z'] is not used"));
    CHECK(contains(w, "tileset is empty"));
    CHECK(contains(w, "solidTiles is empty"));
}

TEST_CASE("import_ascii: callable from a script during a frame (fa.call), re-importing there keeps ids stable") {
    Session s("script");
    s.project.write("scripts/importer.js", R"(
import { Behaviour, fa } from "factoria";
export default class Importer extends Behaviour {
  frames = 0;
  onUpdate(dt) {
    this.frames++;
    if (this.frames === 2 || this.frames === 4) {
      const r = fa.call("scene.import_ascii", {
        rows: ["o.o", "###"],
        legend: { "#": 0, "o": { prefab: "prefabs/coin.prefab.json", offset: [0, 2] } },
      });
      this.ids = r.spawned.map((o) => o.id);
      this.removed = r.removed;
    }
  }
}
)");
    REQUIRE(s.call("scene.spawn", Json::parse(R"({"id":"importer","components":{"Script":{"path":"scripts/importer.js"}}})")).ok);
    s.engine.step(6);
    Json state = s.engine.state();
    CHECK_MESSAGE(state["scriptErrors"].empty(), state["scriptErrors"].dump());
    CHECK(s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"] == 2);
    CHECK(ids_with_tag(s, "tilemap:tilemap") == std::vector<std::string>{"coin_1", "coin_2"});
    Json coin = s.entity("coin_2");
    REQUIRE(coin.is_object());
    CHECK(position_of(coin).x == doctest::Approx(40.0f));          // col 2 of 16 px tiles
    CHECK(position_of(coin).y == doctest::Approx(-8.0f + 2.0f));   // row 0 centre + offset
    // The second call (frame 4) replaced the objects of the first one (frame 2) and got the same ids.
    Json seen = s.call("script.eval", Json{{"code", "[world.find('importer').behaviour.removed, world.find('importer').behaviour.ids]"}}).result["value"];
    CHECK(seen[0] == Json::parse(R"(["coin_1","coin_2"])"));
    CHECK(seen[1] == Json::parse(R"(["coin_1","coin_2"])"));
}

TEST_CASE("import_ascii: unicode glyphs and an all-empty map") {
    Session s("unicode");
    auto r = s.import(Json::parse(R"({"rows":["░█░","█o█"],"legend":{"█":4,"░":-1,"o":{"prefab":"prefabs/coin.prefab.json"}}})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["width"] == 3);
    CHECK(r.result["height"] == 2);
    CHECK(r.result["tileCount"] == 3);
    CHECK(r.result["spawned"][0]["cell"] == Json::parse("[1,1]"));
    r = s.import(Json::parse(R"({"rows":["..",".."],"legend":{"#":0}})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["tileCount"] == 0);
    CHECK(r.result["spawned"].empty());
    CHECK(r.result["removed"].size() == 1);
}

TEST_CASE("import_ascii: the tilemap is drawn where the objects are (screenshot)") {
    Session s("screenshot");
    // 10x6 tiles of 32 = 320x192 centred in the 320x180 view.
    auto r = s.import(level(R"({"anchor":"center","position":[0,0]})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    s.engine.step(1);
    std::string shot = (s.project.dir / "shots/level.png").generic_string();
    REQUIRE(s.call("game.screenshot", Json{{"path", shot}}).ok);
    auto img = load_image(shot);
    REQUIRE(img.ok());
    REQUIRE(img->width == 320);
    // View y in [-90, 90] -> pixel row = 90 - y. Map top-left = (-160, 96): col c, row r centre = (-160 + 32c + 16, 96 - 32r - 16).
    auto px = [&](int col, int row) {
        return img->pixel(32 * col + 16, int(90 - (96 - 32.0f * row - 16)));
    };
    Color ground = px(0, 4);    // tile 0 = red
    CHECK(ground.r > 0.9f);
    CHECK(ground.b < 0.1f);
    Color bedrock = px(0, 5);   // tile 1 = blue
    CHECK(bedrock.b > 0.9f);
    CHECK(bedrock.r < 0.1f);
    Color coin = px(3, 1);      // coin_1 = gold circle drawn on the empty cell (3, 1)
    CHECK(coin.r > 0.9f);
    CHECK(coin.g > 0.7f);
    CHECK(coin.b < 0.2f);
    Color sky = px(5, 0);       // empty cell = clear colour
    CHECK(sky.r < 0.2f);
    CHECK(sky.b > 0.1f);
}

// ------------------------------------------------------------------------------------------------ file mode (path)
// scene.import_ascii {path, from, dryRun} edits a scene FILE in a scratch World. The running engine must not notice.
namespace {

const char* kBaseScene = R"({
  "format": "factoria.scene/1",
  "settings": { "gravity2D": [0, -500] },
  "entities": [
    { "id": "camera", "components": { "Camera": { "clearColor": "#304050" }, "Transform": { "position": [160, 96, 0] } } },
    { "id": "hud", "components": { "Transform": { "position": [4, 4, 0] } } }
  ]
})";

Json scene_file(const Session& s, const std::string& rel) {
    auto j = load_json_file((s.project.dir / rel).generic_string());
    REQUIRE_MESSAGE(j.ok(), rel);
    return *j;
}

std::vector<std::string> entity_ids(const Json& scene) {
    std::vector<std::string> out;
    for (const Json& e : scene["entities"]) out.push_back(e["id"].get<std::string>());
    return out;
}

bool has(const std::vector<std::string>& v, const std::string& x) { return std::find(v.begin(), v.end(), x) != v.end(); }

}  // namespace

TEST_CASE("import_ascii path: builds a new scene file from an empty scene and leaves the running world alone") {
    Session s("file_new");
    // Something that a reload or a stray import into the running world would change.
    REQUIRE(s.call("scene.set_component", Json::parse(R"({"id":"cam","component":"Camera","fields":{"clearColor":"#ff0000"}})")).ok);
    s.engine.step(3);
    const Json worldBefore = s.call("game.state", Json{{"maxEntities", 100}}).result;
    const std::uint64_t frame = s.engine.frame_index();

    auto r = s.import(level(R"({"path":"scenes/zzz_new_level.scene.json"})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["path"] == "scenes/zzz_new_level.scene.json");
    CHECK(r.result["saved"] == "scenes/zzz_new_level.scene.json");
    CHECK(r.result["from"].is_null());  // started as an empty scene
    CHECK(r.result["dryRun"] == false);
    CHECK(r.result["created"] == true);
    CHECK(r.result["entityCount"] == 5);  // tilemap, 3 coins, player
    CHECK(r.result["spawned"].size() == 4);
    CHECK(contains(r.result["notes"].dump(), "empty scene"));
    CHECK(r.result["warnings"].empty());

    Json file = scene_file(s, "scenes/zzz_new_level.scene.json");
    CHECK(entity_ids(file) == std::vector<std::string>{"tilemap", "coin_1", "coin_2", "player", "coin_3"});
    CHECK(file["entities"][0]["components"]["Tilemap"]["width"] == 10);

    // Nothing of the running engine changed: its entities, its edited camera, the frame, the scene path.
    CHECK(s.engine.frame_index() == frame);
    CHECK(s.entities() == 1);
    CHECK_FALSE(s.engine.world().find_by_id("tilemap"));
    CHECK(s.call("scene.get_entity", Json{{"id", "cam"}}).result["components"]["Camera"]["clearColor"] == Json::parse("[1,0,0,1]"));
    CHECK(s.call("project.info").result["currentScene"] == "scenes/main.scene.json");
    const Json worldAfter = s.call("game.state", Json{{"maxEntities", 100}}).result;
    CHECK(worldAfter["entities"] == worldBefore["entities"]);
    CHECK(worldAfter["frame"] == worldBefore["frame"]);
}

TEST_CASE("import_ascii path: the file is exactly what the running-world import plus scene.save writes") {
    Session s("file_canonical");
    auto f = s.import(level(R"({"path":".factoria/tmp/by_file.scene.json","from":"scenes/main.scene.json"})"));
    REQUIRE_MESSAGE(f.ok, error_text(f));
    REQUIRE(s.import(level()).ok);
    REQUIRE(s.call("scene.save", Json{{"path", ".factoria/tmp/by_world.scene.json"}}).ok);
    const std::string byFile = slurp(s.project.dir / ".factoria/tmp/by_file.scene.json");
    CHECK_FALSE(byFile.empty());
    CHECK(byFile == slurp(s.project.dir / ".factoria/tmp/by_world.scene.json"));
    // Re-running the file import is idempotent: same bytes.
    REQUIRE(s.import(level(R"({"path":".factoria/tmp/by_file.scene.json","from":"scenes/main.scene.json"})")).ok);
    CHECK(slurp(s.project.dir / ".factoria/tmp/by_file.scene.json") == byFile);
}

TEST_CASE("import_ascii path: edits an existing scene in place, replacing the objects of the earlier import") {
    Session s("file_edit");
    s.project.write("scenes/level.scene.json", kBaseScene);
    auto r = s.import(level(R"({"path":"scenes/level.scene.json"})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["from"] == "scenes/level.scene.json");  // started from the file itself
    CHECK(r.result["created"] == true);                    // the tilemap entity was new in that scene
    CHECK(has(entity_ids(scene_file(s, "scenes/level.scene.json")), "camera"));  // kept
    CHECK(has(entity_ids(scene_file(s, "scenes/level.scene.json")), "hud"));
    CHECK(scene_file(s, "scenes/level.scene.json")["settings"]["gravity2D"] == Json::parse("[0,-500]"));

    // Edit the map and import again: same ids, no duplicates, the other entities untouched.
    Json edited = level(R"({"path":"scenes/level.scene.json"})");
    edited["rows"] = Json::parse(R"(["..........","...o......","..........",".P........","##########","@@@@@@@@@@"])");
    r = s.import(edited);
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["created"] == false);
    CHECK(r.result["removed"].size() == 4);
    CHECK(entity_ids(scene_file(s, "scenes/level.scene.json")) ==
          std::vector<std::string>{"camera", "hud", "tilemap", "coin_1", "player"});
    CHECK(s.entities() == 1);  // the running world still has only cam
}

TEST_CASE("import_ascii path: from starts the scene from a base scene and replaces path") {
    Session s("file_from");
    s.project.write("levels/base.scene.json", kBaseScene);
    s.project.write("scenes/out.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"old"}]})");
    const std::string baseBefore = slurp(s.project.dir / "levels/base.scene.json");
    auto r = s.import(level(R"({"path":"scenes/out.scene.json","from":"levels/base.scene.json"})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["from"] == "levels/base.scene.json");
    CHECK(contains(r.result["notes"].dump(), "was replaced"));
    Json out = scene_file(s, "scenes/out.scene.json");
    CHECK(entity_ids(out) == std::vector<std::string>{"camera", "hud", "tilemap", "coin_1", "coin_2", "player", "coin_3"});
    CHECK(out["settings"]["gravity2D"] == Json::parse("[0,-500]"));
    CHECK(slurp(s.project.dir / "levels/base.scene.json") == baseBefore);  // the base is only read

    // A missing base is an error with a did-you-mean over ALL scene files, and nothing is written.
    r = s.import(level(R"({"path":"scenes/second.scene.json","from":"levels/bse.scene.json"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_found");
    CHECK(contains(error_text(r), "levels/base.scene.json"));
    CHECK_FALSE(stdfs::exists(s.project.dir / "scenes/second.scene.json"));
}

TEST_CASE("import_ascii path: a typo in path warns with a did-you-mean instead of silently creating a different scene") {
    Session s("file_typo");
    auto r = s.import(level(R"({"path":"scenes/mian.scene.json"})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));  // it is a valid way to create a scene, so it works ...
    CHECK(contains(r.result["warnings"].dump(), "Did you mean 'scenes/main.scene.json'"));  // ... but says what it did
    CHECK(contains(r.result["warnings"].dump(), "empty scene"));
    CHECK(stdfs::exists(s.project.dir / "scenes/mian.scene.json"));
    // The scene that was meant is untouched.
    CHECK(entity_ids(scene_file(s, "scenes/main.scene.json")) == std::vector<std::string>{"cam"});
}

TEST_CASE("import_ascii path: dryRun returns the scene and writes nothing") {
    Session s("file_dry");
    const std::string mainBefore = slurp(s.project.dir / "scenes/main.scene.json");
    auto r = s.import(level(R"({"path":"scenes/main.scene.json","dryRun":true})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["dryRun"] == true);
    CHECK_FALSE(r.result.contains("saved"));
    CHECK(slurp(s.project.dir / "scenes/main.scene.json") == mainBefore);
    REQUIRE(r.result.contains("scene"));
    CHECK(r.result["scene"]["format"] == "factoria.scene/1");
    CHECK(entity_ids(r.result["scene"]) == std::vector<std::string>{"cam", "tilemap", "coin_1", "coin_2", "player", "coin_3"});

    // A new path stays absent, and the same call without dryRun writes exactly the scene the dry run returned.
    r = s.import(level(R"({"path":"scenes/preview.scene.json","dryRun":true})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK_FALSE(stdfs::exists(s.project.dir / "scenes/preview.scene.json"));
    const Json preview = r.result["scene"];
    REQUIRE(s.import(level(R"({"path":"scenes/preview.scene.json"})")).ok);
    CHECK(scene_file(s, "scenes/preview.scene.json") == preview);
}

TEST_CASE("import_ascii path: the base scene's entities count for ids, and a failed import writes nothing") {
    Session s("file_fail");
    s.project.write("levels/base.scene.json", kBaseScene);
    s.project.write("scenes/taken.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"player"}]})");
    const std::string takenBefore = slurp(s.project.dir / "scenes/taken.scene.json");

    SUBCASE("a legend id that the scene already uses") {
        auto r = s.import(level(R"({"path":"scenes/taken.scene.json"})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "'player'"));
        CHECK(contains(error_text(r), "already used"));
        CHECK(slurp(s.project.dir / "scenes/taken.scene.json") == takenBefore);
    }
    SUBCASE("a tile outside the tileset (the tileset is read in the scratch import too)") {
        Json a = level(R"({"path":"scenes/taken.scene.json","from":"levels/base.scene.json"})");
        a["legend"]["#"] = 9;
        auto r = s.import(a);
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "tile 9"));
        CHECK(contains(error_text(r), "holds only 4 tiles"));
        CHECK(slurp(s.project.dir / "scenes/taken.scene.json") == takenBefore);
        a["path"] = "scenes/never.scene.json";
        CHECK_FALSE(s.import(a).ok);
        CHECK_FALSE(stdfs::exists(s.project.dir / "scenes/never.scene.json"));
    }
    SUBCASE("a prefab that does not exist") {
        Json a = level(R"({"path":"scenes/never.scene.json"})");
        a["legend"]["o"]["prefab"] = "prefabs/coin2.prefab.json";
        auto r = s.import(a);
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "prefabs/coin.prefab.json"));
        CHECK_FALSE(stdfs::exists(s.project.dir / "scenes/never.scene.json"));
    }
    SUBCASE("a scene with load errors is not rewritten (the entries that failed would be dropped)") {
        s.project.write("scenes/broken.scene.json",
                        R"({"format":"factoria.scene/1","entities":[{"id":"ok"},{"id":"bad","components":{"Sprit":{"color":"red"}}}]})");
        const std::string brokenBefore = slurp(s.project.dir / "scenes/broken.scene.json");
        auto r = s.import(level(R"({"path":"scenes/broken.scene.json"})"));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), "scenes/broken.scene.json"));
        CHECK(contains(error_text(r), "Sprit"));
        CHECK(contains(error_text(r), "Nothing was written"));
        CHECK(slurp(s.project.dir / "scenes/broken.scene.json") == brokenBefore);
        // Starting from a good base works.
        CHECK(s.import(level(R"({"path":"scenes/broken.scene.json","from":"levels/base.scene.json"})")).ok);
    }
}

TEST_CASE("import_ascii path: arguments are checked, and writes follow the same rule as scene.save and fs.write") {
    Session s("file_args");
    auto fails = [&](const char* patch, const char* needle) {
        auto r = s.import(level(patch));
        CAPTURE(patch);
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), needle));
        CHECK(s.entities() == 1);
    };
    fails(R"({"from":"scenes/main.scene.json"})", "'from' needs 'path'");
    fails(R"({"dryRun":true})", "'dryRun' needs 'path'");
    fails(R"({"path":""})", "'path'");
    fails(R"({"path":"scenes"})", "folder");
    fails(R"({"path":"../outside.scene.json"})", "escapes");
    fails(R"({"path":"/tmp/abs.scene.json"})", "absolute");
    fails(R"({"path":"scenes/a.scene.json","from":"/etc/x.scene.json"})", "absolute");
    // .factoria/ is managed by the engine: only .factoria/tmp/ is writable (scene.save, fs.write and fs.delete agree).
    for (const char* bad : {".factoria/screenshots/a.scene.json", ".factoria/save/a.scene.json", ".factoria/a.scene.json"}) {
        Json a = level();
        a["path"] = bad;
        auto r = s.import(a);
        CAPTURE(bad);
        REQUIRE_FALSE(r.ok);
        CHECK(contains(error_text(r), ".factoria/tmp/"));
        CHECK_FALSE(stdfs::exists(s.project.dir / bad));
    }
    // dryRun predicts the real call, so it refuses the same paths.
    auto dry = s.import(level(R"({"path":".factoria/save/a.scene.json","dryRun":true})"));
    CHECK_FALSE(dry.ok);
    auto ok = s.import(level(R"({"path":".factoria/tmp/a.scene.json"})"));
    REQUIRE_MESSAGE(ok.ok, error_text(ok));
    CHECK(stdfs::exists(s.project.dir / ".factoria/tmp/a.scene.json"));
    // A path that is not *.scene.json still works but is flagged.
    ok = s.import(level(R"({"path":"scenes/odd.json"})"));
    REQUIRE_MESSAGE(ok.ok, error_text(ok));
    CHECK(contains(ok.result["warnings"].dump(), ".scene.json"));
}

TEST_CASE("scene.save writes where commands may write: .factoria/tmp yes, the rest of .factoria no") {
    Session s("save_rule");
    auto bad = s.call("scene.save", Json{{"path", ".factoria/test/x.scene.json"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["code"] == "invalid_argument");
    CHECK(contains(error_text(bad), ".factoria/test/x.scene.json"));
    CHECK(contains(error_text(bad), ".factoria/tmp/"));
    CHECK_FALSE(stdfs::exists(s.project.dir / ".factoria/test"));
    CHECK_FALSE(s.call("scene.save", Json{{"path", ".factoria/save/slot.scene.json"}}).ok);
    CHECK_FALSE(s.call("scene.save", Json{{"path", "../escape.scene.json"}}).ok);

    auto ok = s.call("scene.save", Json{{"path", ".factoria/tmp/x.scene.json"}});
    REQUIRE_MESSAGE(ok.ok, error_text(ok));
    CHECK(stdfs::exists(s.project.dir / ".factoria/tmp/x.scene.json"));
    CHECK(s.call("scene.save", Json{{"path", "scenes/y.scene.json"}}).ok);
    // The command says so in its own description.
    const CommandInfo* info = s.engine.commands().info("scene.save");
    REQUIRE(info != nullptr);
    CHECK(contains(info->description, ".factoria/tmp/"));
}

TEST_CASE("import_ascii path: works inside a frame too (a script can build a scene file)") {
    Session s("file_frame");
    s.project.write("scripts/builder.js", R"(
import { Behaviour, fa } from "factoria";
export default class Builder extends Behaviour {
  frames = 0;
  onUpdate(dt) {
    if (++this.frames !== 2) return;
    const r = fa.call("scene.import_ascii", {
      rows: ["o.o", "###"],
      legend: { "#": 0, "o": { prefab: "prefabs/coin.prefab.json" } },
      path: ".factoria/tmp/from_script.scene.json",
    });
    this.saved = r.saved;
  }
}
)");
    REQUIRE(s.call("scene.spawn", Json::parse(R"({"id":"builder","components":{"Script":{"path":"scripts/builder.js"}}})")).ok);
    s.engine.step(4);
    Json state = s.engine.state();
    CHECK_MESSAGE(state["scriptErrors"].empty(), state["scriptErrors"].dump());
    CHECK(s.call("script.eval", Json{{"code", "world.find('builder').behaviour.saved"}}).result["value"] == ".factoria/tmp/from_script.scene.json");
    CHECK(entity_ids(scene_file(s, ".factoria/tmp/from_script.scene.json")) == std::vector<std::string>{"tilemap", "coin_1", "coin_2"});
    CHECK(s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"] == 0);  // the running world has no coins
}

TEST_CASE("import_ascii: documented path, from and dryRun") {
    Session s("docs_file");
    const CommandInfo* info = s.engine.commands().info("scene.import_ascii");
    REQUIRE(info != nullptr);
    for (const char* prop : {"path", "from", "dryRun"}) {
        CAPTURE(prop);
        REQUIRE(info->inputSchema["properties"].contains(prop));
        CHECK(info->inputSchema["properties"][prop]["description"].get<std::string>().size() > 40);
    }
    CHECK(contains(info->description, "RUNNING"));
    CHECK(contains(info->description, "unsafe_save"));
    CHECK(contains(info->description, "dryRun"));
    CHECK(contains(info->description, "scratch"));
}
