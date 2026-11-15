// The level commands a running game has (engine/runtime/src/level_commands.cpp): scene.place_ascii, tilemap.set_tile,
// tilemap.cell_at, tilemap.cell_to_world, and what the player does NOT have: scene.import_ascii and scene.ascii_edit are authoring
// commands (tools/authoring/tests/tilemap_import_tests.cpp tests them). These tests run in an Engine without fa_authoring.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/runtime/engine.h"
#include "fa/scene/tilemap.h"

using namespace fa;
namespace stdfs = std::filesystem;


namespace {

std::vector<std::int32_t> tiles_of(const Tilemap& tm) {
    return std::vector<std::int32_t>(tm.tiles.cdata(), tm.tiles.cdata() + tm.tiles.size());
}
Json tiles_json(const Tilemap& tm) {
    Json a = Json::array();
    for (std::int32_t t : tiles_of(tm)) a.push_back(t);
    return a;
}

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
        dir = fs::make_temp_dir("fa_place_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        write("prefabs/coin.prefab.json", kCoinPrefab);
        write("prefabs/player.prefab.json", kPlayerPrefab);
        write(
            "prefabs/enemy.prefab.json",
            R"({"format":"factoria.prefab/1","entity":{"name":"Crawler","components":{"Shape2D":{"size":[20,20]}}}})");
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
        std::ofstream(dir / "assets/tiles.png", std::ios::binary)
            .write(reinterpret_cast<const char*>(png.data()), std::streamsize(png.size()));
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
    explicit Session(const std::string& name, const std::string& startScene = {}, bool editorMode = false)
        : project(name) {
        std::string err;
        EngineConfig cfg = headless_cfg(project);
        cfg.scene = startScene;
        cfg.editorMode = editorMode;
        REQUIRE_MESSAGE(engine.init(cfg, nullptr, &err), err);
    }
    ~Session() { engine.shutdown(); }
    CommandResult call(const std::string& cmd, const Json& args = Json::object()) {
        return engine.commands().call(cmd, args);
    }
    CommandResult place(Json args) { return call("scene.place_ascii", args); }
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
    if (r.ok) return std::string();  // doctest -s builds the message on success too
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

TEST_CASE("player commands: scene.place_ascii and the tilemap commands are in the player, scene.import_ascii and scene.ascii_edit "
          "are not (they are authoring commands)") {
    Session s("names");
    const std::vector<std::string> names = s.engine.runtime_command_names();
    auto has = [&](const char* n) { return std::find(names.begin(), names.end(), n) != names.end(); };
    for (const char* n : {"scene.place_ascii", "tilemap.set_tile", "tilemap.cell_at", "tilemap.cell_to_world",
                          "tilemap.generate_start"}) {
        CAPTURE(n);
        CHECK(has(n));
        CHECK(s.engine.commands().info(n) != nullptr);
    }
    for (const char* n : {"scene.import_ascii", "scene.ascii_edit"}) {
        CAPTURE(n);
        CHECK_FALSE(has(n));
        CHECK(s.engine.commands().info(n) == nullptr);
        CHECK_FALSE(s.call(n, Json::object()).ok);
    }
}

TEST_CASE("place_ascii: a 10x6 level yields tiles, 3 coins and the player at cell centres; a bad map teaches") {
    Session s("place");
    auto r = s.place(level());
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["width"] == 10);
    CHECK(r.result["height"] == 6);
    CHECK(r.result["spawned"].size() == 4);
    CHECK(ids_with_tag(s, "tilemap:tilemap") == std::vector<std::string>{"coin_1", "coin_2", "player", "coin_3"});
    // Cell (3, 1) of 32 px tiles: centre ((3 + 0.5) * 32, -(1 + 0.5) * 32) from the map's top-left corner (0, 0).
    Json coin = s.entity("coin_1");
    REQUIRE(coin.is_object());
    CHECK(position_of(coin).x == doctest::Approx(112.0f));
    CHECK(position_of(coin).y == doctest::Approx(-48.0f));

    Json bad = level(R"({"rows": ["#Z#"]})");
    auto e = s.place(bad);
    REQUIRE_FALSE(e.ok);
    CHECK(contains(error_text(e), "legend"));
    CHECK(contains(error_text(e), "'Z'"));
}

// A game script is granted {read, state} (docs/SCRIPTING.md, "What fa.call can do from a game"): the in-memory twin
// scene.place_ascii is what it calls.
TEST_CASE("place_ascii: callable from a script during a frame (fa.call), re-placing there keeps ids stable") {
    Session s("script");
    s.project.write("scripts/importer.js", R"(
import { Behaviour, fa } from "factoria";
export default class Importer extends Behaviour {
  frames = 0;
  onUpdate(dt) {
    this.frames++;
    if (this.frames === 2 || this.frames === 4) {
      const r = fa.call("scene.place_ascii", {
        rows: ["o.o", "###"],
        legend: { "#": 0, "o": { prefab: "prefabs/coin.prefab.json", offset: [0, 2] } },
      });
      this.ids = r.spawned.map((o) => o.id);
      this.removed = r.removed;
    }
  }
}
)");
    REQUIRE(s.call("scene.spawn",
                   Json::parse(R"({"id":"importer","components":{"Script":{"path":"scripts/importer.js"}}})"))
                .ok);
    s.engine.step(6);
    Json state = s.engine.state();
    CHECK_MESSAGE(state["scriptErrors"].empty(), state["scriptErrors"].dump());
    CHECK(s.call("scene.list_entities", Json{{"tag", "coin"}}).result["total"] == 2);
    CHECK(ids_with_tag(s, "tilemap:tilemap") == std::vector<std::string>{"coin_1", "coin_2"});
    Json coin = s.entity("coin_2");
    REQUIRE(coin.is_object());
    CHECK(position_of(coin).x == doctest::Approx(40.0f));         // col 2 of 16 px tiles
    CHECK(position_of(coin).y == doctest::Approx(-8.0f + 2.0f));  // row 0 centre + offset
    // The second call (frame 4) replaced the objects of the first one (frame 2) and got the same ids.
    Json seen =
        s.call("script.eval",
               Json{{"code", "[world.find('importer').behaviour.removed, world.find('importer').behaviour.ids]"}})
            .result["value"];
    CHECK(seen[0] == Json::parse(R"(["coin_1","coin_2"])"));
    CHECK(seen[1] == Json::parse(R"(["coin_1","coin_2"])"));
}

// tilemap.generate with `place` (ember-descent builds its levels so) places the finished level with scene.place_ascii: it needs
// nothing of fa_authoring.
TEST_CASE("tilemap.generate with place builds its level in an Engine that has only the player's commands") {
    Session s("generate");
    REQUIRE(s.engine.commands().info("scene.import_ascii") == nullptr);
    s.project.write("scripts/gen.js", R"(
import { Behaviour, tilemap } from "factoria";
export default class Gen extends Behaviour {
  onStart() {
    globalThis.job = tilemap.generate({ sample: ["##", "##"], legend: { "#": 0 }, size: [4, 4], seed: 1, n: 2,
                                       place: { entity: "generated", tilemap: { tileSize: [16, 16] } } });
  }
}
)");
    REQUIRE(s.call("scene.spawn", Json::parse(R"({"id":"gen","components":{"Script":{"path":"scripts/gen.js"}}})")).ok);
    s.engine.step(12);
    Json state = s.engine.state();
    CHECK_MESSAGE(state["scriptErrors"].empty(), state["scriptErrors"].dump());
    auto ev = [&](const std::string& code) {
        CommandResult r = s.call("script.eval", Json{{"code", code}});
        REQUIRE_MESSAGE(r.ok, error_text(r));
        return r.result["value"];
    };
    CHECK(ev("globalThis.job.done") == true);
    CHECK(ev("globalThis.job.error") == "");
    Entity generated = s.engine.world().find_by_id("generated");
    REQUIRE_FALSE(generated.is_null());
    const Tilemap* tm = s.engine.world().get<Tilemap>(generated);
    REQUIRE(tm != nullptr);
    CHECK(tilemap_size(*tm).width == 4);
    CHECK(tilemap_size(*tm).height == 4);
}

TEST_CASE("tilemap.set_tile changes one tile of the running map in place and refuses bad cells") {
    Session s("set_tile");
    REQUIRE(s.place(level()).ok);
    const Tilemap* tm = s.engine.world().get<Tilemap>(s.engine.world().find("tilemap"));
    REQUIRE(tm);
    const TilemapSize size = tilemap_size(*tm);
    REQUIRE(size.width > 2);
    const int was = tilemap_tile_at(*tm, size, 1, 0);
    auto r = s.call("tilemap.set_tile", Json{{"id", "tilemap"}, {"col", 1}, {"row", 0}, {"tile", 3}});
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["tile"] == 3);
    CHECK(r.result["previous"] == was);
    CHECK(tilemap_tile_at(*tm, size, 1, 0) == 3);
    auto bad = s.call("tilemap.set_tile", Json{{"id", "tilemap"}, {"col", size.width}, {"row", 0}, {"tile", 1}});
    CHECK_FALSE(bad.ok);
    CHECK(contains(error_text(bad), "col is 0.."));
    auto none = s.call("tilemap.set_tile", Json{{"id", "cam"}, {"col", 0}, {"row", 0}, {"tile", 1}});
    CHECK_FALSE(none.ok);
    CHECK(contains(error_text(none), "no Tilemap"));
}

TEST_CASE("tilemap_version: scene.set_component and set_tilemap_tile both move the counter, an equal write does not") {
    Session s("tilemap_version");
    REQUIRE(s.place(level()).ok);
    Entity map = s.engine.world().find_by_id("tilemap");
    REQUIRE_FALSE(map.is_null());
    Tilemap* tm = s.engine.world().get<Tilemap>(map);
    REQUIRE(tm != nullptr);
    const std::uint32_t v0 = tilemap_version(*tm);
    CHECK(tilemap_version(*tm) == v0);
    Json same = Json::object(
        {{"id", "tilemap"}, {"component", "Tilemap"}, {"fields", Json::object({{"tiles", tiles_json(*tm)}})}});
    REQUIRE(s.call("scene.set_component", same).ok);
    tm = s.engine.world().get<Tilemap>(map);
    CHECK(tilemap_version(*tm) == v0);
    Json tiles = tiles_json(*tm);
    tiles[0] = tiles[0].get<int>() == 0 ? 1 : 0;
    Json changed =
        Json::object({{"id", "tilemap"}, {"component", "Tilemap"}, {"fields", Json::object({{"tiles", tiles}})}});
    REQUIRE(s.call("scene.set_component", changed).ok);
    tm = s.engine.world().get<Tilemap>(map);
    const std::uint32_t v1 = tilemap_version(*tm);
    CHECK(v1 > v0);
    REQUIRE(set_tilemap_tile(*tm, 1, 1, 2));
    CHECK(tilemap_version(*tm) > v1);
}

TEST_CASE("place_ascii on an isometric map: objects stand at the diamond centres, anchors use the drawn box, cell_at "
          "inverts cell_to_world") {
    Session s("iso");
    Json a = Json::parse(R"({
      "rows": ["#.#", "...", "#o#"],
      "legend": { "#": 0, ".": 1, "o": { "prefab": "prefabs/coin.prefab.json", "id": "coin" } },
      "tilemap": { "tileset": "assets/tiles.png", "tileSize": [32, 32], "projection": "isometric", "groundHeight": 16,
                   "solidTiles": [0] },
      "position": [500, 200]
    })");
    auto r = s.place(a);
    REQUIRE_MESSAGE(r.ok, error_text(r));
    Json map = s.entity("tilemap");
    CHECK(map["components"]["Tilemap"]["projection"] == "isometric");
    // The top-left anchor is the corner of the box around all the images: its left edge is 3 rows * 16 = 48 left of the top
    // vertex (the image of cell (0, 2) reaches half a tile past its centre) and its top is groundOffset (0) above it, so the
    // entity (the top vertex) sits at (548, 200).
    CHECK(position_of(map).x == doctest::Approx(500.0f + 48.0f));
    CHECK(position_of(map).y == doctest::Approx(200.0f));
    // The coin was written at '(col 1, row 2)': centre ((1 - 2) * 16, -(1 + 2 + 1) * 8) = (-16, -32) from the top vertex.
    Json coin = s.entity("coin");
    REQUIRE(coin.is_object());
    CHECK(position_of(coin).x == doctest::Approx(548.0f - 16.0f));
    CHECK(position_of(coin).y == doctest::Approx(200.0f - 32.0f));

    auto c = s.call("tilemap.cell_at", Json{{"id", "tilemap"}, {"x", position_of(coin).x}, {"y", position_of(coin).y}});
    REQUIRE_MESSAGE(c.ok, error_text(c));
    CHECK(c.result["col"] == 1);
    CHECK(c.result["row"] == 2);
    CHECK(c.result["inside"] == true);
    CHECK(c.result["tile"] == -1);  // an object glyph leaves its cell empty
    auto w = s.call("tilemap.cell_to_world", Json{{"id", "tilemap"}, {"col", 2}, {"row", 0}});
    REQUIRE_MESSAGE(w.ok, error_text(w));
    CHECK(w.result["x"].get<float>() == doctest::Approx(548.0f + 32.0f));
    CHECK(w.result["y"].get<float>() == doctest::Approx(200.0f - 24.0f));
    // A point left of the map is outside, with the cell numbers it would have.
    auto out = s.call("tilemap.cell_at", Json{{"id", "tilemap"}, {"x", 400}, {"y", 100}});
    REQUIRE_MESSAGE(out.ok, error_text(out));
    CHECK(out.result["inside"] == false);
    CHECK(out.result["tile"] == -1);
    // An entity without a Tilemap teaches.
    auto bad = s.call("tilemap.cell_at", Json{{"id", "cam"}, {"x", 0}, {"y", 0}});
    REQUIRE_FALSE(bad.ok);
    CHECK(contains(error_text(bad), "Tilemap"));
}
