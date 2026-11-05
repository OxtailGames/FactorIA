// tilemap.generate: the command form of Wave Function Collapse (the algorithm is tested in engine/scene/tests/test_wfc.cpp).
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <set>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/tilemap.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1", "name": "Wfc Test", "id": "com.example.wfctest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// "example": a small hand-made level (tiles 0 = wall, 1 = floor); "terrain": an empty map with autotile rules; "plain": no tilemap.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#102030" } } },
    { "id": "example", "name": "Example", "components": { "Tilemap": {
        "tileSize": [16, 16], "width": 8, "height": 6,
        "tiles": [ 0,0,0,0,0,0,0,0,  0,1,1,1,1,1,1,0,  0,1,0,0,1,0,1,0,  0,1,1,1,1,0,1,0,  0,1,0,1,1,1,1,0,  0,0,0,0,0,0,0,0 ] } } },
    { "id": "terrain", "name": "Terrain", "components": { "Tilemap": {
        "tileSize": [16, 16], "width": 4, "height": 4,
        "tiles": [-1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1],
        "terrains": [ { "name": "grass", "mode": "basic16", "first": 0, "seed": 1 },
                      { "name": "water", "mode": "basic16", "first": 16, "seed": 1 } ] } } },
    { "id": "plain", "name": "Plain", "components": { "Transform": { "position": [0, 0] } } }
  ]
})";

const char* kRows = R"(["................","..####..........","..#..#....##....","..#..#....##....","..####..........","................","......#.........",
  "......#....###..","...........#.#..","...........###..","..##............","..##......#.....","................","....#......#....",
  "................","................"])";

struct Session {
    stdfs::path dir;
    Engine engine;
    Session() {
        dir = fs::make_temp_dir("fa_wfc_test");
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        write("prefabs/coin.prefab.json", R"({"format":"factoria.prefab/1","entity":{"id":"coin","components":{"Transform":{"position":[0,0]}}}})");
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
    CommandResult call(const std::string& cmd, const Json& args) { return engine.commands().call(cmd, args); }
    const Tilemap& map(const char* id) {
        const Tilemap* tm = engine.world().get<Tilemap>(engine.world().find(id));
        REQUIRE(tm != nullptr);
        return *tm;
    }
};

std::string error_text(const CommandResult& r) { return r.error.value("code", std::string()) + ": " + r.error.value("message", std::string()) + " | " + r.error.value("hint", std::string()); }
bool contains(const std::string& s, const std::string& n) { return s.find(n) != std::string::npos; }

Json ascii_call(const std::string& extra) { return Json::parse(std::string(R"({"sample":)") + kRows + R"(,"legend":{"#":0},)" + extra + "}"); }

}  // namespace

TEST_CASE("tilemap.generate: ASCII sample to ASCII rows, same seed same level") {
    Session s;
    auto a = s.call("tilemap.generate", ascii_call(R"("size":[30,20],"seed":4,"n":3)"));
    REQUIRE_MESSAGE(a.ok, error_text(a));
    REQUIRE(a.result["rows"].size() == 20);
    for (const Json& row : a.result["rows"]) CHECK(row.get<std::string>().size() == 30);
    CHECK(a.result["width"] == 30);
    CHECK(a.result["height"] == 20);
    CHECK(a.result["model"] == "overlapping");
    CHECK(a.result["legend"]["#"] == 0);
    CHECK(a.result["stats"]["patterns"].get<int>() > 1);
    CHECK(a.result["stats"]["attempts"].get<int>() >= 1);
    CHECK(a.result["stats"].contains("ms"));
    CHECK(a.result["sample"]["width"] == 16);
    int walls = 0;
    for (const Json& row : a.result["rows"])
        for (char c : row.get<std::string>()) {
            CHECK((c == '#' || c == '.'));
            walls += c == '#';
        }
    CHECK(a.result["counts"]["#"] == walls);
    CHECK(walls > 0);

    auto b = s.call("tilemap.generate", ascii_call(R"("size":[30,20],"seed":4,"n":3)"));
    auto c = s.call("tilemap.generate", ascii_call(R"("size":[30,20],"seed":5,"n":3)"));
    REQUIRE(b.ok);
    REQUIRE(c.ok);
    CHECK(a.result["rows"] == b.result["rows"]);
    CHECK(a.result["rows"] != c.result["rows"]);

    // The output feeds scene.import_ascii: rows and legend are in its format.
    Json imp = Json::object();
    imp["rows"] = a.result["rows"];
    imp["legend"] = a.result["legend"];
    auto im = s.call("scene.import_ascii", imp);
    CHECK_MESSAGE(im.ok, error_text(im));
}

TEST_CASE("tilemap.generate: the sample as one string with line breaks, size as a number or an object") {
    Session s;
    auto r = s.call("tilemap.generate", Json::parse(R"({"sample":"..##.\n..##.\n.....\n.#...","legend":{"#":3},"size":12,"n":2,"periodic":true})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["width"] == 12);
    CHECK(r.result["height"] == 12);
    CHECK(r.result["legend"]["#"] == 3);

    auto o = s.call("tilemap.generate", Json::parse(R"({"sample":["..##.","..##.",".....",".#..."],"legend":{"#":3},"size":{"width":9,"height":7},"n":2})"));
    REQUIRE_MESSAGE(o.ok, error_text(o));
    CHECK(o.result["rows"].size() == 7);
}

TEST_CASE("tilemap.generate: a Tilemap sample written into another Tilemap") {
    Session s;
    auto r = s.call("tilemap.generate", Json::parse(R"({"sample":"example","into":"terrain","size":[20,12],"seed":3,"n":2,"symmetry":8})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["into"] == "terrain");
    CHECK_FALSE(r.result.contains("rows"));  // `into` given: rows only on request
    const Tilemap& tm = s.map("terrain");
    const TilemapGrid g = tilemap_grid(tm);
    CHECK(g.width == 20);
    CHECK(g.height == 12);
    int walls = 0, floors = 0;
    for (int t : g.tiles) {
        CHECK((t == 0 || t == 1));
        walls += t == 0;
        floors += t == 1;
    }
    CHECK(walls > 0);
    CHECK(floors > 0);
    CHECK(tm.terrains.size() == 2);  // the rules stay

    auto both = s.call("tilemap.generate", Json::parse(R"({"sample":"example","into":"terrain","rows":true,"size":[10,10],"n":2})"));
    REQUIRE_MESSAGE(both.ok, error_text(both));
    CHECK(both.result["rows"].size() == 10);
}

TEST_CASE("tilemap.generate: the tiled model follows the autotile rules of the Tilemap") {
    Session s;
    auto r = s.call("tilemap.generate", Json::parse(R"({"model":"tiled","into":"terrain","size":[14,10],"seed":8,"rows":true})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["model"] == "tiled");
    const TilemapGrid g = tilemap_grid(s.map("terrain"));
    REQUIRE(g.width == 14);
    REQUIRE(g.height == 10);
    auto terrain = [&](int x, int y) {  // 0 none, 1 grass, 2 water
        const int t = g.at(x, y);
        return t < 0 ? 0 : t < 16 ? 1 : 2;
    };
    for (int y = 0; y < g.height; ++y)
        for (int x = 0; x < g.width; ++x) {
            const int me = terrain(x, y);
            if (me == 0) continue;
            const int slot = g.at(x, y) % 16;  // basic16: N*1 + E*2 + S*4 + W*8
            CHECK(((slot & 1) != 0) == (terrain(x, y - 1) == me));
            CHECK(((slot & 2) != 0) == (terrain(x + 1, y) == me));
            CHECK(((slot & 4) != 0) == (terrain(x, y + 1) == me));
            CHECK(((slot & 8) != 0) == (terrain(x - 1, y) == me));
        }
    CHECK(r.result["rows"].size() == 10);

    // Rules can also come with the call; a sample then only weighs the tiles.
    auto withRules = s.call("tilemap.generate",
                            Json::parse(R"({"model":"tiled","sample":"plain","size":[6,6]})"));
    CHECK_FALSE(withRules.ok);  // `plain` has no Tilemap
    CHECK(contains(error_text(withRules), "Tilemap"));
    auto given = s.call("tilemap.generate", Json::parse(R"({"model":"tiled","terrains":[{"name":"rock","mode":"basic16","first":40}],"size":[6,6]})"));
    REQUIRE_MESSAGE(given.ok, error_text(given));
}

TEST_CASE("tilemap.generate: the tiled model without rules says how to add them") {
    Session s;
    auto r = s.call("tilemap.generate", Json::parse(R"({"model":"tiled","sample":"example","size":[8,8]})"));
    REQUIRE_FALSE(r.ok);
    const std::string t = error_text(r);
    CHECK(contains(t, "autotile rules"));
    CHECK(contains(t, "tilemap.set_terrains"));
    CHECK(contains(t, "overlapping"));
}

TEST_CASE("tilemap.generate: glyphs that spawn prefabs come back as glyphs and a warning says so") {
    Session s;
    auto r = s.call("tilemap.generate", Json::parse(R"({"sample":["#####","#.c.#","#...#","#.c.#","#####"],
        "legend":{"#":0,"c":{"prefab":"prefabs/coin.prefab.json"}},"size":[12,9],"n":2,"symmetry":8,"periodic":true,"seed":2})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["legend"].contains("c"));
    CHECK(r.result["legend"].contains("#"));
    CHECK(r.result["counts"]["c"].get<int>() > 0);
    REQUIRE(r.result.contains("warnings"));
    CHECK(contains(r.result["warnings"][0].get<std::string>(), "scene.import_ascii"));
}

TEST_CASE("tilemap.generate: errors teach") {
    Session s;
    // A bad enum value: the schema answers with a suggestion.
    auto model = s.call("tilemap.generate", ascii_call(R"("size":[8,8],"model":"overlaping")"));
    REQUIRE_FALSE(model.ok);
    CHECK(contains(error_text(model), "overlapping"));

    // n outside 2..5: the schema names the limit.
    auto small = s.call("tilemap.generate", ascii_call(R"("size":[8,8],"n":1)"));
    REQUIRE_FALSE(small.ok);
    CHECK_MESSAGE((contains(error_text(small), "/n") && contains(error_text(small), "minimum 2")), error_text(small));
    auto large = s.call("tilemap.generate", ascii_call(R"("size":[8,8],"n":6)"));
    REQUIRE_FALSE(large.ok);
    CHECK_MESSAGE((contains(error_text(large), "/n") && contains(error_text(large), "maximum 5")), error_text(large));
    auto sym = s.call("tilemap.generate", ascii_call(R"("size":[8,8],"symmetry":3)"));
    REQUIRE_FALSE(sym.ok);
    CHECK(contains(error_text(sym), "symmetry"));

    auto big = s.call("tilemap.generate", ascii_call(R"("size":[100000,100000])"));
    REQUIRE_FALSE(big.ok);
    CHECK(contains(error_text(big), "size"));

    auto memory = s.call("tilemap.generate", ascii_call(R"("size":[2048,2048],"n":3,"symmetry":8)"));
    REQUIRE_FALSE(memory.ok);
    CHECK_MESSAGE(contains(error_text(memory), "MB"), error_text(memory));

    auto empty = s.call("tilemap.generate", Json::parse(R"({"sample":"","size":[8,8]})"));
    REQUIRE_FALSE(empty.ok);
    CHECK(contains(error_text(empty), "empty"));
    auto emptyRows = s.call("tilemap.generate", Json::parse(R"({"sample":[],"size":[8,8]})"));
    REQUIRE_FALSE(emptyRows.ok);

    auto missing = s.call("tilemap.generate", Json::parse(R"({"size":[8,8]})"));
    REQUIRE_FALSE(missing.ok);
    CHECK(contains(error_text(missing), "sample"));

    auto unknown = s.call("tilemap.generate", Json::parse(R"({"sample":"exampel","size":[8,8]})"));
    REQUIRE_FALSE(unknown.ok);
    CHECK(contains(error_text(unknown), "example"));  // did you mean

    auto noMap = s.call("tilemap.generate", Json::parse(R"({"sample":"plain","size":[8,8]})"));
    REQUIRE_FALSE(noMap.ok);
    CHECK(contains(error_text(noMap), "no Tilemap"));

    auto intoNone = s.call("tilemap.generate", ascii_call(R"("size":[8,8],"into":"plain")"));
    REQUIRE_FALSE(intoNone.ok);
    CHECK(contains(error_text(intoNone), "no Tilemap"));

    auto smaller = s.call("tilemap.generate", ascii_call(R"("size":[2,8],"n":3)"));
    REQUIRE_FALSE(smaller.ok);
    CHECK(contains(error_text(smaller), "smaller than"));

    auto noSize = s.call("tilemap.generate", Json::parse(R"({"sample":"example"})"));
    REQUIRE_FALSE(noSize.ok);
}

TEST_CASE("tilemap.generate: a contradiction after every attempt names the cell, the attempts and what to try") {
    Session s;
    auto r = s.call("tilemap.generate", Json::parse(R"({"sample":["#####","#...#","#.#.#","#...#","#####"],"legend":{"#":0},"size":[24,10],"seed":7,"maxAttempts":3})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "generation_failed");
    const std::string t = error_text(r);
    CHECK(contains(t, "3 attempts"));
    CHECK(contains(t, "cell ("));
    CHECK(contains(t, "bigger"));
    CHECK(contains(t, "periodic"));
    CHECK(contains(t, "maxAttempts"));
    // The failed call changed nothing.
    auto into = s.call("tilemap.generate", Json::parse(R"({"sample":["#####","#...#","#.#.#","#...#","#####"],"legend":{"#":0},"size":[24,10],"seed":7,"maxAttempts":2,"into":"terrain"})"));
    REQUIRE_FALSE(into.ok);
    CHECK(s.map("terrain").width == 4);
}

TEST_CASE("tilemap.generate: periodic on and off give different windows at the edges") {
    Session s;
    auto off = s.call("tilemap.generate", ascii_call(R"("size":[20,20],"seed":1,"n":3,"periodic":false)"));
    auto on = s.call("tilemap.generate", ascii_call(R"("size":[20,20],"seed":1,"n":3,"periodic":true)"));
    REQUIRE_MESSAGE(off.ok, error_text(off));
    REQUIRE_MESSAGE(on.ok, error_text(on));
    CHECK(on.result["stats"]["cells"] == 400);
    CHECK(off.result["stats"]["cells"] == 18 * 18);
}
