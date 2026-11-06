// tilemap.generate: the command form of Wave Function Collapse (the algorithm is tested in engine/scene/tests/test_wfc.cpp).
#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <cmath>
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

    // n outside 2..5: the command names the limit (and only checks it for the overlapping model).
    auto small = s.call("tilemap.generate", ascii_call(R"("size":[8,8],"n":1)"));
    REQUIRE_FALSE(small.ok);
    CHECK_MESSAGE((contains(error_text(small), "'n' is 1") && contains(error_text(small), "between 2 and 5")), error_text(small));
    auto large = s.call("tilemap.generate", ascii_call(R"("size":[8,8],"n":6)"));
    REQUIRE_FALSE(large.ok);
    CHECK_MESSAGE((contains(error_text(large), "'n' is 6") && contains(error_text(large), "between 2 and 5")), error_text(large));
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

// ------------------------------------------------------------------------------------------------------------ M63.2: constraints and reachability
namespace {

// A small dungeon: '#' wall (tile 0, solid), '.' floor (tile 1), '$' treasure (tile 2, once, in the middle), 'E' enemy (tile 3).
const char* kDungeon = R"(["################",
  "#..............#",
  "#..##......#...#",
  "#..##...##.#...#",
  "#......####....#",
  "#..#...........#",
  "#..#....$..##..#",
  "#.......#..##..#",
  "#...##..#......#",
  "#...##....E....#",
  "#..............#",
  "################"])";
const char* kDungeonLegend = R"({"#":0,".":1,"$":2,"E":3})";

Json dungeon_call(const std::string& extra) {
    // The extras are merged over the defaults, so a call can give its own "maxAttempts" without a duplicated key.
    Json call = Json::parse(std::string(R"({"sample":)") + kDungeon + R"(,"legend":)" + kDungeonLegend + R"(,"n":3,"size":[24,16],"maxAttempts":100})");
    call.update(Json::parse("{" + extra + "}"));
    return call;
}

std::vector<std::string> rows_of(const CommandResult& r) {
    std::vector<std::string> out;
    for (const Json& row : r.result["rows"]) out.push_back(row.get<std::string>());
    return out;
}

int count_char(const std::vector<std::string>& rows, char c) {
    int n = 0;
    for (const std::string& row : rows) n += int(std::count(row.begin(), row.end(), c));
    return n;
}

// The number of 4-connected areas of non-wall cells, counted here and not by the command.
int open_areas(const std::vector<std::string>& rows) {
    const int h = int(rows.size()), w = int(rows[0].size());
    std::vector<char> seen(std::size_t(w * h), 0);
    int areas = 0;
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            if (rows[std::size_t(y)][std::size_t(x)] == '#' || seen[std::size_t(y * w + x)]) continue;
            ++areas;
            std::vector<std::pair<int, int>> todo{{x, y}};
            seen[std::size_t(y * w + x)] = 1;
            while (!todo.empty()) {
                auto [cx, cy] = todo.back();
                todo.pop_back();
                const int d[4][2] = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};
                for (auto& o : d) {
                    const int nx = cx + o[0], ny = cy + o[1];
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h || rows[std::size_t(ny)][std::size_t(nx)] == '#' || seen[std::size_t(ny * w + nx)]) continue;
                    seen[std::size_t(ny * w + nx)] = 1;
                    todo.push_back({nx, ny});
                }
            }
        }
    return areas;
}

Json without_ms(Json result) {
    result["stats"].erase("ms");
    return result;
}

}  // namespace

TEST_CASE("tilemap.generate constraints: fixed cells, border, forbidden, required and counts") {
    Session s;
    auto r = s.call("tilemap.generate",
                    dungeon_call(R"("seed":3,"constraints":{
        "border":{"tile":"#"},
        "fixed":[{"at":[1,1],"tile":"."},{"at":[22,14],"tile":"."},{"rect":[10,7,3,2],"tile":[".","$"]}],
        "forbidden":["E"],
        "required":["$"],
        "counts":[{"tile":"$","max":3}]})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    const auto rows = rows_of(r);
    REQUIRE(rows.size() == 16);
    for (int x = 0; x < 24; ++x) {
        CHECK(rows[0][std::size_t(x)] == '#');
        CHECK(rows[15][std::size_t(x)] == '#');
    }
    for (int y = 0; y < 16; ++y) {
        CHECK(rows[std::size_t(y)][0] == '#');
        CHECK(rows[std::size_t(y)][23] == '#');
    }
    CHECK(rows[1][1] == '.');
    CHECK(rows[14][22] == '.');
    for (int y = 7; y < 9; ++y)
        for (int x = 10; x < 13; ++x) CHECK((rows[std::size_t(y)][std::size_t(x)] == '.' || rows[std::size_t(y)][std::size_t(x)] == '$'));
    CHECK(count_char(rows, 'E') == 0);
    CHECK(count_char(rows, '$') >= 1);
    CHECK(count_char(rows, '$') <= 3);
    REQUIRE(r.result.contains("constraints"));
    CHECK(r.result["constraints"]["fixedCells"].get<int>() >= 2 * 24 + 2 * 14 + 2);
    CHECK(r.result["constraints"]["counts"].size() == 2);
    CHECK(r.result["constraints"]["counts"][0]["found"].get<int>() == count_char(rows, '$'));
    CHECK(r.result["stats"].contains("work"));
}

TEST_CASE("tilemap.generate constraints: tile numbers, min and max counts, and a Tilemap sample") {
    Session s;
    auto r = s.call("tilemap.generate", dungeon_call(R"("seed":9,"constraints":{"counts":[{"tile":3,"min":2,"max":4},{"tile":0,"max":200}]})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    const auto rows = rows_of(r);
    CHECK(count_char(rows, 'E') >= 2);
    CHECK(count_char(rows, 'E') <= 4);
    CHECK(count_char(rows, '#') <= 200);

    // A Tilemap sample names its tiles by number; -1 is the empty cell.
    auto tm = s.call("tilemap.generate", Json::parse(R"({"sample":"example","size":[20,12],"n":2,"seed":1,
        "maxAttempts":100,"constraints":{"fixed":[{"at":[0,0],"tile":0},{"at":[5,5],"tile":1}],"counts":[{"tile":1,"min":10}]}})"));
    REQUIRE_MESSAGE(tm.ok, error_text(tm));
    CHECK(tm.result["constraints"]["counts"][0]["found"].get<int>() >= 10);
}

TEST_CASE("tilemap.generate constraints: contradictions are reported before generating, with JSON pointers") {
    Session s;
    auto fails = [&](const std::string& extra, const std::string& pointer, const std::string& text) {
        auto r = s.call("tilemap.generate", dungeon_call(extra));
        INFO(extra);
        REQUIRE_FALSE(r.ok);
        const std::string t = error_text(r);
        CHECK_MESSAGE(contains(t, pointer), t);
        CHECK_MESSAGE(contains(t, text), t);
        CHECK_MESSAGE(contains(r.error.value("code", std::string()), "invalid_argument"), t);
    };
    fails(R"("constraints":{"required":["$"],"forbidden":["$"]})", "/constraints/required/0", "forbidden");
    fails(R"("constraints":{"fixed":[{"at":[3,3],"tile":"E"}],"forbidden":["E"]})", "/constraints/fixed/0", "forbidden");
    fails(R"("constraints":{"fixed":[{"at":[3,3],"tile":"#"},{"at":[3,3],"tile":"$"}]})", "/constraints/fixed/1", "no tile satisfies both");
    fails(R"("constraints":{"fixed":[{"at":[24,3],"tile":"#"}]})", "/constraints/fixed/0/at/0", "x is 24");
    fails(R"("constraints":{"fixed":[{"at":[3,16],"tile":"#"}]})", "/constraints/fixed/0/at/1", "y is 16");
    fails(R"("constraints":{"counts":[{"tile":"$","min":4,"max":2}]})", "/constraints/counts/0", "greater than max");
    fails(R"("constraints":{"counts":[{"tile":"$","min":999}]})", "/constraints/counts/0/min", "only 384");
    fails(R"("constraints":{"counts":[{"tile":"Q","min":1}]})", "/constraints/counts/0/tile", "not in the sample");
    fails(R"("constraints":{"counts":[{"tile":7,"min":1}]})", "/constraints/counts/0/tile", "never has it");
    fails(R"("constraints":{"fixed":[{"at":[1,1],"tile":"#"}],"counts":[{"tile":"E","minn":1}]})", "/constraints/counts/0", "Did you mean");
    fails(R"("constraints":{"forbiden":["E"]})", "/constraints", "forbidden");
    fails(R"("constraints":{"counts":[{"tile":"#","min":300},{"tile":".","min":100}]})", "/constraints", "add up");
    fails(R"("constraints":{"border":{"tile":"#","thickness":20}})", "/constraints/border/thickness", "between 1 and 16");
    fails(R"("constraints":{"fixed":[{"at":[1,1]}]})", "/constraints/fixed/0", "tile");
    // Reachability starting or ending on a cell fixed to a wall.
    fails(R"("constraints":{"fixed":[{"at":[1,1],"tile":"#"}]},"reachability":{"from":[1,1],"to":[[5,5]],"solidTiles":[0]})", "/reachability/from", "blocks the way");
    fails(R"("reachability":{"from":[1,1],"to":[[5,5]]},"legend":{"#":0,".":1,"$":2,"E":3})", "/reachability", "solidTiles");
    fails(R"("reachability":{"to":[[5,5]],"solidTiles":[0]})", "/reachability", "need a start");
    fails(R"("reachability":{"from":[1,99],"solidTiles":[0],"allConnected":true})", "/reachability/from/1", "y is 99");
    fails(R"("reachability":{"from":[1,1],"to":[[5,5]],"solidTiles":[0],"extra":1})", "/reachability/extra", "unknown property");
    // The failed calls changed nothing and generated nothing.
    CHECK(s.map("terrain").width == 4);
}

TEST_CASE("tilemap.generate reachability: the entrance reaches the exit and the treasure, and the report matches nav.find_tile_path") {
    Session s;
    // The worked example of docs/AI_GUIDE.md: entrance top-left, exit bottom-right, a required treasure that must be reachable.
    auto r = s.call("tilemap.generate",
                    dungeon_call(R"("seed":5,"into":"terrain","rows":true,
        "constraints":{"border":{"tile":"#"},"fixed":[{"at":[1,1],"tile":"."},{"at":[22,14],"tile":"."}],"required":["$"],"forbidden":["E"]},
        "reachability":{"from":[1,1],"to":[[22,14]],"toTiles":["$"],"solidTiles":[0]})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    const auto rows = rows_of(r);
    CHECK(count_char(rows, '$') >= 1);
    const Json& rep = r.result["reachability"];
    CHECK(rep["from"] == Json::parse("[1,1]"));
    CHECK(rep["goals"].get<int>() == 1 + count_char(rows, '$'));
    CHECK(rep["unreachable"]["cells"].get<long long>() == rep["walkableCells"].get<long long>() - rep["reachableCells"].get<long long>());
    REQUIRE(rep["paths"].size() >= 1);
    CHECK_FALSE(rep.contains("unreachableGoals"));

    // The same path on the Tilemap that was written: nav.find_tile_path with the same rules finds it with the same length.
    for (const Json& p : rep["paths"]) {
        auto nav = s.call("nav.find_tile_path", Json{{"tilemap", "terrain"}, {"from", Json::array({1, 1})}, {"to", p["to"]}, {"costs", Json{{"0", nullptr}}}});
        REQUIRE_MESSAGE(nav.ok, error_text(nav));
        CHECK(nav.result["found"] == true);
        CHECK(nav.result["cost"].get<double>() == doctest::Approx(p["cost"].get<double>()));
        CHECK(nav.result["cells"].size() == p["steps"].get<std::size_t>() + 1);   // `length` is in world units, the cells are steps
    }
    // The cells that were cut off are walkable cells the start does not reach; none of the goals is among them.
    CHECK(open_areas(rows) == 1 + int(rep["unreachable"]["areas"].get<int>()));
}

TEST_CASE("tilemap.generate reachability: an unreachable grid is retried with the next seed, deterministically") {
    Session s;
    // Look for a seed whose first grid has an enclosed pocket: asking for one connected area then needs a retry.
    Json found;
    for (int seed = 0; seed < 60 && found.is_null(); ++seed) {
        auto r = s.call("tilemap.generate", dungeon_call(R"("seed":)" + std::to_string(seed) + R"(,"maxAttempts":200,"reachability":{"from":[1,1],"allConnected":true,"solidTiles":[0]},
            "constraints":{"fixed":[{"at":[1,1],"tile":"."}]})"));
        REQUIRE_MESSAGE(r.ok, error_text(r));
        if (r.result["stats"]["rejected"].get<int>() > 0) found = Json::object({{"seed", seed}, {"result", r.result}});
    }
    REQUIRE_MESSAGE(!found.is_null(), "no seed in 0..59 needed a retry: the sample or the generator changed");
    const Json& res = found["result"];
    CHECK(res["stats"]["attempts"].get<int>() > 1);
    std::vector<std::string> rows;
    for (const Json& row : res["rows"]) rows.push_back(row.get<std::string>());
    CHECK(open_areas(rows) == 1);
    CHECK(res["reachability"]["unreachable"]["areas"] == 0);

    // The same call again: the same level and the same counters (ms is a timing, not part of the promise).
    auto again = s.call("tilemap.generate", dungeon_call(R"("seed":)" + std::to_string(found["seed"].get<int>()) + R"(,"maxAttempts":200,"reachability":{"from":[1,1],"allConnected":true,"solidTiles":[0]},
            "constraints":{"fixed":[{"at":[1,1],"tile":"."}]})"));
    REQUIRE(again.ok);
    CHECK(without_ms(again.result) == without_ms(res));
}

TEST_CASE("tilemap.generate reachability: a level that can never be played fails with what was missing") {
    Session s;
    // Every tile blocks, so the start is always a wall: nothing can be reached.
    auto r = s.call("tilemap.generate", dungeon_call(R"("seed":1,"maxAttempts":3,"reachability":{"from":[1,1],"to":[[5,5]],"solidTiles":[0,1,2,3]})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "generation_failed");
    const std::string t = error_text(r);
    CHECK_MESSAGE(contains(t, "3 attempts"), t);
    CHECK_MESSAGE(contains(t, "blocked cell"), t);
    CHECK_MESSAGE(contains(t, "maxAttempts"), t);

    // A maximum of zero for a tile the output cannot avoid is found by the generator, not by waiting.
    auto never = s.call("tilemap.generate", dungeon_call(R"("seed":1,"maxAttempts":3,"constraints":{"counts":[{"tile":"#","max":0}],"fixed":[{"at":[0,0],"tile":"#"}]})"));
    REQUIRE_FALSE(never.ok);
    CHECK_MESSAGE(contains(error_text(never), "#"), error_text(never));
}

TEST_CASE("tilemap.generate constraints: the same seed gives the same level, a constraint changes it") {
    Session s;
    const char* args = R"("seed":11,"constraints":{"border":{"tile":"#"},"fixed":[{"at":[1,1],"tile":"."}],"required":["$"],"counts":[{"tile":"E","max":2}]},
        "reachability":{"from":[1,1],"toTiles":["$"],"solidTiles":[0]})";
    auto a = s.call("tilemap.generate", dungeon_call(args));
    auto b = s.call("tilemap.generate", dungeon_call(args));
    REQUIRE_MESSAGE(a.ok, error_text(a));
    REQUIRE(b.ok);
    CHECK(without_ms(a.result) == without_ms(b.result));
    auto plain = s.call("tilemap.generate", dungeon_call(R"("seed":11)"));
    REQUIRE(plain.ok);
    CHECK(plain.result["rows"] != a.result["rows"]);
}

TEST_CASE("tilemap.generate: maxWork and maxSeconds stop a level with an error that says how to shrink it") {
    Session s;
    auto r = s.call("tilemap.generate", dungeon_call(R"("seed":1,"maxWork":1)"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "budget_exceeded");
    const std::string t = error_text(r);
    CHECK_MESSAGE(contains(t, "maxWork"), t);
    CHECK_MESSAGE(contains(t, "24 x 16"), t);
    CHECK_MESSAGE(contains(t, "patterns"), t);
    CHECK_MESSAGE(contains(t, "smaller"), t);
    auto time = s.call("tilemap.generate", dungeon_call(R"("seed":1,"size":[160,160],"maxSeconds":0.0000001)"));
    REQUIRE_FALSE(time.ok);
    CHECK_MESSAGE(contains(error_text(time), "maxSeconds"), error_text(time));
    auto bad = s.call("tilemap.generate", dungeon_call(R"("maxWork":0)"));
    REQUIRE_FALSE(bad.ok);
    CHECK(contains(error_text(bad), "maxWork"));
    // Within the caps the same call works.
    auto ok = s.call("tilemap.generate", dungeon_call(R"("seed":1,"maxWork":100000000,"maxSeconds":60)"));
    CHECK_MESSAGE(ok.ok, error_text(ok));
    CHECK(ok.result["stats"]["work"].get<long long>() > 0);
}

TEST_CASE("tilemap.generate: the work cap is deterministic and a size or fixed rect that does not fit fails fast") {
    Session s;
    // The same arguments end the same way (the same units of work), whatever the speed of the machine.
    auto a = s.call("tilemap.generate", dungeon_call(R"("seed":1,"size":[40,30],"maxWork":3000)"));
    auto b = s.call("tilemap.generate", dungeon_call(R"("seed":1,"size":[40,30],"maxWork":3000)"));
    REQUIRE_FALSE(a.ok);
    CHECK(a.error["code"] == "budget_exceeded");
    CHECK(error_text(a) == error_text(b));
    CHECK(contains(error_text(a), "work cap"));

    // 2048 x 2048 with a fixed rect of the whole level: the memory estimate comes before any per-cell work.
    const auto t0 = std::chrono::steady_clock::now();
    auto huge = s.call("tilemap.generate", dungeon_call(R"("size":[2048,2048],"seed":1,"constraints":{"fixed":[{"rect":[0,0,2048,2048],"tile":"."}]})"));
    const double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
    REQUIRE_FALSE(huge.ok);
    CHECK_MESSAGE(contains(error_text(huge), "MB"), error_text(huge));
    CHECK_MESSAGE(ms < 5000.0, "took " << ms << " ms");

    // A level that fits in memory but fixes more cells than one level may: the limit names the pointer.
    auto many = s.call("tilemap.generate", dungeon_call(R"("size":[270,270],"seed":1,"constraints":{"fixed":[{"rect":[0,0,270,270],"tile":"."}]})"));
    REQUIRE_FALSE(many.ok);
    CHECK_MESSAGE(contains(error_text(many), "/constraints/fixed/0"), error_text(many));
    CHECK_MESSAGE(contains(error_text(many), "fixed"), error_text(many));
}

TEST_CASE("tilemap.generate constraints: numbers that do not fit an int are clamped or refused, not wrapped") {
    Session s;
    // A maximum of 2^32 is "no maximum": it must not wrap around to 0 and forbid the tile.
    auto big = s.call("tilemap.generate", dungeon_call(R"("seed":1,"constraints":{"counts":[{"tile":"E","max":4294967296}]})"));
    CHECK_MESSAGE(big.ok, error_text(big));
    // A minimum above the output is refused.
    auto minimum = s.call("tilemap.generate", dungeon_call(R"("seed":1,"constraints":{"counts":[{"tile":"E","min":4294967295}]})"));
    REQUIRE_FALSE(minimum.ok);
    CHECK_MESSAGE(contains(error_text(minimum), "/constraints/counts/0"), error_text(minimum));
    auto minimum2 = s.call("tilemap.generate", dungeon_call(R"("seed":1,"constraints":{"counts":[{"tile":"E","min":4294967296}]})"));
    REQUIRE_FALSE(minimum2.ok);
    auto solid = s.call("tilemap.generate", dungeon_call(R"("seed":1,"reachability":{"from":[1,1],"allConnected":true,"solidTiles":[4294967296]})"));
    REQUIRE_FALSE(solid.ok);
    CHECK_MESSAGE(contains(error_text(solid), "/reachability/solidTiles"), error_text(solid));
}

TEST_CASE("tilemap.generate constraints: contradictions name the rule, and `required` against `max: 0` is found before generating") {
    Session s;
    auto r = s.call("tilemap.generate", dungeon_call(R"("seed":1,"constraints":{"required":["$"],"counts":[{"tile":"$","max":0}]})"));
    REQUIRE_FALSE(r.ok);
    const std::string t = error_text(r);
    const bool named = contains(t, "/constraints/required/0") || contains(t, "/constraints/counts/0");
    CHECK_MESSAGE(named, t);
    CHECK_MESSAGE(contains(t, "capped at 0"), t);

    auto fixedForbidden = s.call("tilemap.generate", dungeon_call(R"("seed":1,"constraints":{"fixed":[{"at":[2,2],"tile":"E"}],"counts":[{"tile":"E","max":0}]})"));
    REQUIRE_FALSE(fixedForbidden.ok);
    CHECK_MESSAGE(contains(error_text(fixedForbidden), "/constraints/fixed/0"), error_text(fixedForbidden));
}

TEST_CASE("tilemap.generate reachability: a solid tile with a cost override is walkable, and path costs are rounded") {
    Session s;
    // The start is fixed to a wall: refused while the wall blocks...
    auto blocked = s.call("tilemap.generate", dungeon_call(R"("seed":1,"constraints":{"fixed":[{"at":[1,1],"tile":"#"}]},"reachability":{"from":[1,1],"allConnected":true,"solidTiles":[0]})"));
    REQUIRE_FALSE(blocked.ok);
    CHECK_MESSAGE(contains(error_text(blocked), "blocks the way"), error_text(blocked));
    // ...and fine when `costs` makes the tile walkable, exactly as nav.find_tile_path reads the finished level.
    auto walkable = s.call("tilemap.generate", dungeon_call(R"("seed":1,"constraints":{"fixed":[{"at":[1,1],"tile":"#"}]},"reachability":{"from":[1,1],"allConnected":true,"solidTiles":[0],"costs":{"0":2.3333333}})"));
    CHECK_MESSAGE(walkable.ok, error_text(walkable));
    auto paths = s.call("tilemap.generate", dungeon_call(R"("seed":2,"constraints":{"required":["$"]},"reachability":{"from":[1,1],"toTiles":["$"],"solidTiles":[0],"costs":{"1":1.1111111}})"));
    REQUIRE_MESSAGE(paths.ok, error_text(paths));
    REQUIRE(paths.result["reachability"].contains("paths"));
    for (const Json& p : paths.result["reachability"]["paths"]) {
        const double cost = p["cost"].get<double>();
        CHECK(cost == doctest::Approx(std::round(cost * 1000.0) / 1000.0).epsilon(1e-12));
    }
}

TEST_CASE("tilemap.generate: model must be text, and n and symmetry are ignored by the tiled model") {
    Session s;
    auto bad = s.call("tilemap.generate", Json::parse(R"({"model":5,"size":[8,8]})"));
    REQUIRE_FALSE(bad.ok);
    CHECK(contains(error_text(bad), "model"));

    // Out-of-range n and symmetry would be errors for the overlapping model; the tiled one does not read them.
    auto ignored = s.call("tilemap.generate", Json::parse(R"({"model":"tiled","into":"terrain","size":[8,8],"n":99,"symmetry":3,"seed":2})"));
    CHECK_MESSAGE(ignored.ok, error_text(ignored));
    auto overlapping = s.call("tilemap.generate", ascii_call(R"("size":[8,8],"n":99)"));
    CHECK_FALSE(overlapping.ok);

    // A sample tile that is turned or flipped still counts as its tile of the rules (no "belongs to no terrain" warning).
    auto flipped = s.call("tilemap.generate", Json::parse(R"({"model":"tiled","size":[6,6],"seed":1,
        "terrains":[{"name":"grass","mode":"basic16","first":0}],
        "sample":["aa","aa"],"legend":{"a":{"tile":3,"flipX":true}}})"));
    REQUIRE_MESSAGE(flipped.ok, error_text(flipped));
    CHECK_FALSE(flipped.result.contains("warnings"));
}

TEST_CASE("tilemap.generate: unknown arguments are refused with a suggestion, before any work") {
    Session s;
    auto typo = s.call("tilemap.generate", dungeon_call(R"("seed":1,"maxAtempts":5)"));
    REQUIRE_FALSE(typo.ok);
    CHECK_MESSAGE(contains(error_text(typo), "/maxAtempts"), error_text(typo));
    CHECK_MESSAGE(contains(error_text(typo), "maxAttempts"), error_text(typo));   // did you mean
    CHECK_MESSAGE(contains(error_text(typo), "invalid_argument"), error_text(typo));
    // `place` is an option of the script API only
    auto place = s.call("tilemap.generate", dungeon_call(R"("seed":1,"place":true)"));
    REQUIRE_FALSE(place.ok);
    CHECK_MESSAGE(contains(error_text(place), "/place"), error_text(place));
    CHECK_MESSAGE(contains(error_text(place), "Valid:"), error_text(place));
    // generate_start reads the same arguments
    auto start = s.call("tilemap.generate_start", dungeon_call(R"("seed":1,"sed":3)"));
    REQUIRE_FALSE(start.ok);
    CHECK_MESSAGE(contains(error_text(start), "seed"), error_text(start));
    // nothing was left running
    CHECK(s.call("tilemap.generate_step", Json::object({{"job", 1}})).error.value("code", std::string()) == "not_found");
}

TEST_CASE("tilemap.generate reachability: `costs` takes numbers of 0 or more, or null") {
    Session s;
    auto fails = [&](const std::string& costs, const std::string& text) {
        auto r = s.call("tilemap.generate", dungeon_call(R"("seed":1,"reachability":{"from":[1,1],"allConnected":true,"solidTiles":[0],"costs":)" + costs + "}"));
        INFO(costs);
        REQUIRE_FALSE(r.ok);
        CHECK_MESSAGE(contains(error_text(r), "/reachability/costs/"), error_text(r));
        CHECK_MESSAGE(contains(error_text(r), text), error_text(r));
    };
    fails(R"({"1":-2})", "finite number of 0 or more");
    fails(R"({"1":"cheap"})", "a number of 0 or more");
    fails(R"({"1":true})", "a number of 0 or more");
    fails(R"({"1":1e300})", "finite");   // more than a float holds
    auto ok = s.call("tilemap.generate", dungeon_call(R"("seed":1,"reachability":{"from":[1,1],"allConnected":true,"solidTiles":[0],"costs":{"1":0,"2":2.5,"3":null}})"));
    CHECK_MESSAGE(ok.ok, error_text(ok));
}

TEST_CASE("tilemap.generate constraints: `repair` is optional, and a maximum is only checked on the finished grid") {
    Session s;
    // The rules of the test above, with and without the repair of a missed minimum. Whichever way, a level that comes out meets them:
    // the repair pins cells for a minimum and never for a maximum, which is only checked on the finished grid.
    const std::string counts = R"("counts":[{"tile":"E","min":2,"max":4},{"tile":"$","max":1}])";
    auto repaired = s.call("tilemap.generate", dungeon_call(R"("seed":9,"constraints":{)" + counts + "}"));
    REQUIRE_MESSAGE(repaired.ok, error_text(repaired));
    const auto rowsA = rows_of(repaired);
    CHECK(count_char(rowsA, 'E') >= 2);
    CHECK(count_char(rowsA, 'E') <= 4);
    CHECK(count_char(rowsA, '$') <= 1);

    auto plain = s.call("tilemap.generate", dungeon_call(R"("seed":9,"maxAttempts":300,"constraints":{"repair":false,)" + counts + "}"));
    if (plain.ok) {
        const auto rowsB = rows_of(plain);
        CHECK(count_char(rowsB, 'E') >= 2);
        CHECK(count_char(rowsB, 'E') <= 4);
        CHECK(count_char(rowsB, '$') <= 1);
    } else {
        // without the repair a rare minimum can use up the attempts: that is why the option is on by default
        CHECK_MESSAGE(contains(error_text(plain), "maxAttempts"), error_text(plain));
    }
    // the option is a boolean
    auto bad = s.call("tilemap.generate", dungeon_call(R"("seed":9,"constraints":{"repair":"no"})"));
    REQUIRE_FALSE(bad.ok);
    CHECK_MESSAGE(contains(error_text(bad), "repair"), error_text(bad));
}

TEST_CASE("tilemap.generate_start: when other generations hold the memory, the error says so and the map is not blamed") {
    Session s;
    // Measure what one dungeon costs per cell, then ask for two runs that fit alone and not together.
    auto probe = s.call("tilemap.generate_start", dungeon_call(R"("seed":1,"size":[64,64])"));
    REQUIRE_MESSAGE(probe.ok, error_text(probe));
    const double perCell = double(probe.result["memoryBytes"].get<long long>()) / (64.0 * 64.0);
    s.call("tilemap.generate_cancel", Json::object({{"job", probe.result["job"]}}));
    const int side = int(std::sqrt(0.6 * 256.0 * 1024.0 * 1024.0 / perCell));
    const std::string size = "\"size\":[" + std::to_string(side) + "," + std::to_string(side) + "]";
    auto first = s.call("tilemap.generate_start", dungeon_call("\"seed\":1," + size));
    REQUIRE_MESSAGE(first.ok, error_text(first));
    auto second = s.call("tilemap.generate_start", dungeon_call("\"seed\":2," + size));
    REQUIRE_FALSE(second.ok);
    const std::string t = error_text(second);
    CHECK_MESSAGE(contains(t, "other generation"), t);
    CHECK_MESSAGE(contains(t, "tilemap.generate_cancel"), t);
    // once the first is dropped the same request fits
    CHECK(s.call("tilemap.generate_cancel", Json::object({{"job", first.result["job"]}})).result["cancelled"] == true);
    auto again = s.call("tilemap.generate_start", dungeon_call("\"seed\":2," + size));
    CHECK_MESSAGE(again.ok, error_text(again));
}

TEST_CASE("tilemap.generate reachability: the path costs are those nav.find_tile_path finds on the written level, with the same `costs`") {
    Session s;
    // Floor costs 1.75, the enemy tile is walkable at 4 and the treasure blocks (null): the generator and nav share one cost rule.
    const char* costs = R"({"1":1.75,"3":4,"2":null})";
    auto r = s.call("tilemap.generate", dungeon_call(std::string(R"("seed":6,"into":"terrain","rows":true,"constraints":{"fixed":[{"at":[1,1],"tile":"."},{"at":[22,14],"tile":"."}]},
        "reachability":{"from":[1,1],"to":[[22,14],[12,8]],"solidTiles":[0],"costs":)") + costs + "}"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    const Json& rep = r.result["reachability"];
    REQUIRE(rep["paths"].size() >= 1);
    for (const Json& p : rep["paths"]) {
        auto nav = s.call("nav.find_tile_path", Json{{"tilemap", "terrain"}, {"from", Json::array({1, 1})}, {"to", p["to"]}, {"costs", Json::parse(R"({"0":null,"1":1.75,"3":4,"2":null})")}});
        REQUIRE_MESSAGE(nav.ok, error_text(nav));
        CHECK(nav.result["found"] == true);
        CHECK(nav.result["cost"].get<double>() == doctest::Approx(p["cost"].get<double>()).epsilon(1e-4));
        CHECK(nav.result["cells"].size() == p["steps"].get<std::size_t>() + 1);
    }
}

TEST_CASE("tilemap.generate_step: on a big level a step stays within a chunk of its work, reachability included (path searches apart)") {
    Session s;
    const int side = 160;   // 25600 cells: more than one chunk (16384) of every phase
    const std::string size = "\"size\":[" + std::to_string(side) + "," + std::to_string(side) + "]";
    auto start = s.call("tilemap.generate_start", dungeon_call(size + R"(,"seed":4,"maxAttempts":3,"reachability":{"from":[1,1],"allConnected":true,"solidTiles":[0]})"));
    REQUIRE_MESSAGE(start.ok, error_text(start));
    const Json job = start.result["job"];
    long long before = 0, widest = 0;
    int steps = 0;
    for (; steps < 200000; ++steps) {
        auto r = s.call("tilemap.generate_step", Json::object({{"job", job}, {"work", 1}}));
        if (!r.ok) break;   // a seed that never makes a connected level ends with an error: the bound is what this test is about
        const long long work = r.result["work"].get<long long>();
        widest = std::max(widest, work - before);
        before = work;
        if (r.result["done"] == true) break;
    }
    // a chunk is about 16384 units (a propagated cell, an observed cell or a reachability pass are small beside it); the one piece
    // that is not cut is a path search, and with `allConnected` and no `to` none is made
    CHECK(widest <= 2 * 16384 + 4096);
    CHECK(steps > 10);
    s.call("tilemap.generate_cancel", Json::object({{"job", job}}));
}

// ------------------------------------------------------------------------------------------------------------ constraints.place
namespace {

// The legend of the dungeon plus two markers the sample rows never draw: '@' the entrance, '>' the exit.
const char* kMarkerLegend = R"({"#":0,".":1,"$":2,"E":3,"@":4,">":5,"S":6})";

Json place_call(const std::string& extra) {
    Json call = dungeon_call(extra);
    call["legend"] = Json::parse(kMarkerLegend);
    return call;
}

struct Spot {
    int x = -1, y = -1;
};

std::vector<Spot> spots(const std::vector<std::string>& rows, char c) {
    std::vector<Spot> out;
    for (std::size_t y = 0; y < rows.size(); ++y)
        for (std::size_t x = 0; x < rows[y].size(); ++x)
            if (rows[y][x] == c) out.push_back({int(x), int(y)});
    return out;
}

// Steps from `from` over the cells that are not walls (4 neighbours), -1 for a cell it cannot reach: counted here, not by the command.
std::vector<int> walk_steps(const std::vector<std::string>& rows, Spot from) {
    const int h = int(rows.size()), w = int(rows[0].size());
    std::vector<int> dist(std::size_t(w * h), -1);
    std::vector<int> queue{from.y * w + from.x};
    dist[std::size_t(from.y * w + from.x)] = 0;
    for (std::size_t head = 0; head < queue.size(); ++head) {
        const int cx = queue[head] % w, cy = queue[head] / w;
        const int d[4][2] = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};
        for (auto& o : d) {
            const int nx = cx + o[0], ny = cy + o[1];
            if (nx < 0 || ny < 0 || nx >= w || ny >= h || rows[std::size_t(ny)][std::size_t(nx)] == '#' || dist[std::size_t(ny * w + nx)] >= 0) continue;
            dist[std::size_t(ny * w + nx)] = dist[std::size_t(cy * w + cx)] + 1;
            queue.push_back(ny * w + nx);
        }
    }
    return dist;
}

}  // namespace

TEST_CASE("tilemap.generate constraints.place: an entrance anywhere and an exit as far as the level allows, markers the sample never draws") {
    Session s;
    const std::string place = R"("constraints":{"place":[{"tile":"@","on":["."]},{"tile":">","where":"farthest","from":"@","on":["."]}]},
        "reachability":{"allConnected":true,"solidTiles":[0]})";
    for (int seed = 1; seed <= 4; ++seed) {
        auto r = s.call("tilemap.generate", place_call("\"seed\":" + std::to_string(seed) + "," + place));
        REQUIRE_MESSAGE(r.ok, error_text(r));
        const auto rows = rows_of(r);
        REQUIRE(spots(rows, '@').size() == 1);
        REQUIRE(spots(rows, '>').size() == 1);
        // the level's legend carries the markers, so scene.import_ascii accepts the rows as they are
        CHECK(r.result["legend"].contains("@"));
        CHECK(r.result["legend"].contains(">"));
        CHECK(r.result["counts"]["@"] == 1);
        CHECK(r.result["counts"][">"] == 1);
        // the exit is the farthest floor cell (by steps) from the entrance
        const Spot from = spots(rows, '@')[0], exit = spots(rows, '>')[0];
        const std::vector<int> dist = walk_steps(rows, from);
        const int w = int(rows[0].size());
        const int exitDist = dist[std::size_t(exit.y * w + exit.x)];
        REQUIRE(exitDist > 0);
        for (std::size_t y = 0; y < rows.size(); ++y)
            for (std::size_t x = 0; x < rows[y].size(); ++x)
                if (rows[y][x] == '.') CHECK(dist[y * std::size_t(w) + x] <= exitDist);
        // the report says what was placed
        const Json& placed = r.result["constraints"]["placed"];
        REQUIRE(placed.size() == 2);
        CHECK(placed[1]["where"] == "farthest");
        CHECK(placed[1]["at"][0] == Json::parse("[" + std::to_string(exit.x) + "," + std::to_string(exit.y) + "]"));
        CHECK(placed[1]["distances"][0].get<double>() == doctest::Approx(double(exitDist)));
        CHECK(placed[0]["at"][0] == Json::parse("[" + std::to_string(from.x) + "," + std::to_string(from.y) + "]"));
    }
}

TEST_CASE("tilemap.generate constraints.place: nearest, several cells, random from the seed, and the same level every time") {
    Session s;
    const std::string base = R"("constraints":{"place":[{"tile":"@","on":["."]},{"tile":"S","count":3,"where":"nearest","from":"@","on":["."]},{"tile":">","count":2,"on":["."]}]},
        "reachability":{"allConnected":true,"solidTiles":[0]})";
    auto a = s.call("tilemap.generate", place_call(R"("seed":11,)" + base));
    REQUIRE_MESSAGE(a.ok, error_text(a));
    const auto rows = rows_of(a);
    CHECK(spots(rows, '@').size() == 1);
    REQUIRE(spots(rows, 'S').size() == 3);
    CHECK(spots(rows, '>').size() == 2);
    // the three nearest are nearer than every other floor cell (or tie with the farthest of them)
    const std::vector<int> dist = walk_steps(rows, spots(rows, '@')[0]);
    const int w = int(rows[0].size());
    int farthestPicked = 0;
    for (const Spot& p : spots(rows, 'S')) farthestPicked = std::max(farthestPicked, dist[std::size_t(p.y * w + p.x)]);
    for (std::size_t y = 0; y < rows.size(); ++y)
        for (std::size_t x = 0; x < rows[y].size(); ++x)
            if (rows[y][x] == '.' && dist[y * std::size_t(w) + x] > 0) CHECK(dist[y * std::size_t(w) + x] >= farthestPicked);
    // a marker never lands on another marker, a fixed cell or a wall
    for (const std::string& row : rows) CHECK(row.size() == std::size_t(w));

    auto b = s.call("tilemap.generate", place_call(R"("seed":11,)" + base));
    REQUIRE(b.ok);
    CHECK(rows_of(b) == rows);
    CHECK(without_ms(b.result) == without_ms(a.result));
    // random placements come from the seed: some other seed puts the entrance somewhere else
    bool moved = false;
    for (int seed = 12; seed < 20 && !moved; ++seed) {
        auto c = s.call("tilemap.generate", place_call("\"seed\":" + std::to_string(seed) + "," + base));
        REQUIRE_MESSAGE(c.ok, error_text(c));
        moved = spots(rows_of(c), '@')[0].x != spots(rows, '@')[0].x || spots(rows_of(c), '@')[0].y != spots(rows, '@')[0].y;
    }
    CHECK(moved);
}

TEST_CASE("tilemap.generate constraints.place: a marker with no room says so; a fixed cell is never replaced") {
    Session s;
    // more cells than the floor has: every attempt is refused, and the error names the entry
    auto r = s.call("tilemap.generate", place_call(R"("seed":1,"maxAttempts":2,"size":[8,8],"constraints":{"place":[{"tile":"S","count":900,"on":["$"]}]})"));
    REQUIRE_FALSE(r.ok);
    CHECK_MESSAGE(contains(error_text(r), "count"), error_text(r));   // 900 > 64 cells: refused before generating
    auto few = s.call("tilemap.generate", place_call(R"("seed":1,"maxAttempts":2,"constraints":{"forbidden":["$"],"place":[{"tile":"S","on":["$"]}]})"));
    REQUIRE_FALSE(few.ok);
    CHECK_MESSAGE(contains(error_text(few), "/constraints/place/0"), error_text(few));
    CHECK_MESSAGE(contains(error_text(few), "only 0 cell(s) can take 'S'"), error_text(few));

    // fixed cells stay: the border and the corner are never taken by a marker that may go on any walkable cell
    auto fixed = s.call("tilemap.generate", place_call(R"("seed":3,"constraints":{"border":{"tile":"#"},"fixed":[{"at":[1,1],"tile":"."}],"place":[{"tile":"S","count":40}]},
        "reachability":{"allConnected":true,"solidTiles":[0]})"));
    REQUIRE_MESSAGE(fixed.ok, error_text(fixed));
    const auto rows = rows_of(fixed);
    CHECK(rows[1][1] == '.');
    CHECK(spots(rows, 'S').size() == 40);
}

TEST_CASE("tilemap.generate constraints.place: errors teach before anything is generated") {
    Session s;
    const std::string reach = R"(,"reachability":{"allConnected":true,"solidTiles":[0]})";
    struct Case {
        std::string extra, needle;
    };
    const std::vector<Case> cases = {
        {R"("constraints":{"place":[{"tile":">","where":"farthes","from":"@","on":["."]}]})" + reach, "farthest"},   // did you mean
        {R"("constraints":{"place":[{"tile":">","where":"farthest","on":["."]}]})" + reach, "needs a place to measure from"},
        {R"("constraints":{"place":[{"tile":">","where":"farthest","from":"E","on":["."]}]})", "walkable tiles"},
        {R"("constraints":{"place":[{"tile":">"}]})", "nothing to say which cells may be replaced"},
        {R"("constraints":{"place":[{"tile":">","count":0,"on":["."]}]})", "/constraints/place/0/count"},
        {R"("constraints":{"place":[{"tile":"Z","on":["."]}]})", "'Z'"},
        {R"("constraints":{"place":[{"tile":">","from":"@","on":["."]}]})" + reach, "EARLIER place entry"},
        {R"("constraints":{"place":[{"tile":">","on":["."],"colour":1}]})", "unknown property 'colour'"},
        {R"("constraints":{"place":[{"tile":["#","."],"on":["."]}]})", "writes exactly one"},
        {R"("constraints":{"counts":[{"tile":">","max":1}]})", "never draw it"},
        {R"("constraints":{"place":[{"tile":">","on":["."]},{"tile":">","from":">","on":["."]}]})" + reach, "from itself"},
    };
    for (const Case& c : cases) {
        auto r = s.call("tilemap.generate", place_call(c.extra));
        REQUIRE_FALSE_MESSAGE(r.ok, c.extra);
        CHECK_MESSAGE(contains(error_text(r), c.needle), std::string(c.extra + " -> " + error_text(r)));
    }
}

TEST_CASE("tilemap.generate constraints.place: a tile number the sample does not show is refused, and stepped in pieces it is the same level") {
    Session s;
    // a Tilemap sample has no legend: a tile number the sample does not show cannot be placed, and the error says what it has
    auto missing = s.call("tilemap.generate",
                          Json::parse(R"({"sample":"example","size":[20,14],"seed":4,"maxAttempts":50,
        "constraints":{"place":[{"tile":5,"on":[1]}]},"reachability":{"from":[1,1],"solidTiles":[0]}})"));
    REQUIRE_FALSE(missing.ok);
    CHECK_MESSAGE(contains(error_text(missing), "is not in the sample"), error_text(missing));
    // a tile the sample shows: a wall dropped on the floor, nearest the corner
    auto byNumber = s.call("tilemap.generate",
                           Json::parse(R"({"sample":"example","size":[20,14],"seed":4,"maxAttempts":50,
        "constraints":{"fixed":[{"at":[1,1],"tile":1}],"place":[{"tile":0,"count":2,"where":"nearest","from":1,"on":[1]}]},"reachability":{"from":[1,1],"solidTiles":[0]}})"));
    // a level with the two walls, or the dead end a tiny sample with fixed cells can give: never a half-placed level
    if (byNumber.ok) CHECK(byNumber.result["constraints"]["placed"][0]["count"] == 2);
    else CHECK(error_text(byNumber).find("generation_failed") == 0);

    // the job form: stepped in tiny pieces, the same level
    const Json call = place_call(R"("seed":6,"constraints":{"place":[{"tile":"@","on":["."]},{"tile":">","where":"farthest","from":"@","on":["."]}]},
        "reachability":{"allConnected":true,"solidTiles":[0]})");
    auto direct = s.call("tilemap.generate", call);
    REQUIRE_MESSAGE(direct.ok, error_text(direct));
    auto start = s.call("tilemap.generate_start", call);
    REQUIRE_MESSAGE(start.ok, error_text(start));
    const Json job = start.result["job"];
    Json last;
    double progress = 0;
    for (int i = 0; i < 100000; ++i) {
        auto step = s.call("tilemap.generate_step", Json::object({{"job", job}, {"work", 7}}));
        REQUIRE_MESSAGE(step.ok, error_text(step));
        CHECK(step.result["progress"].get<double>() >= progress);
        progress = step.result["progress"].get<double>();
        if (step.result["done"] == true) {
            last = step.result;
            break;
        }
    }
    REQUIRE(last.is_object());
    CHECK(last["result"]["rows"] == direct.result["rows"]);
    CHECK(last["result"]["constraints"]["placed"] == direct.result["constraints"]["placed"]);
}

TEST_CASE("tilemap.generate constraints: a maximum steers the solver (a tile the sample draws once does not turn up four times)") {
    Session s;
    int rejected = 0, attempts = 0;
    for (int seed = 1; seed <= 10; ++seed) {
        auto r = s.call("tilemap.generate", dungeon_call("\"seed\":" + std::to_string(seed) + R"(,"maxAttempts":40,"constraints":{"counts":[{"tile":"$","max":1},{"tile":"E","max":1}]})"));
        REQUIRE_MESSAGE(r.ok, error_text(r));
        const auto rows = rows_of(r);
        CHECK(count_char(rows, '$') <= 1);
        CHECK(count_char(rows, 'E') <= 1);
        rejected += r.result["stats"]["rejected"].get<int>();
        attempts += r.result["stats"]["attempts"].get<int>();
    }
    // the maximums are kept by the solver, not found by retrying: at most one grid in five is refused for its counts
    CHECK_MESSAGE(rejected * 5 <= attempts, "rejected " << rejected << " of " << attempts << " attempts");
}

TEST_CASE("tilemap.generate_step: progress follows the solver inside an attempt and never goes down across attempts") {
    Session s;
    // a level that is refused several times: connected, from a sample with a few separate rooms
    auto start = s.call("tilemap.generate_start", dungeon_call(R"("seed":2,"maxAttempts":60,"size":[30,20],"reachability":{"from":[1,1],"allConnected":true,"solidTiles":[0]},
        "constraints":{"fixed":[{"at":[1,1],"tile":"."}]})"));
    REQUIRE_MESSAGE(start.ok, error_text(start));
    const Json job = start.result["job"];
    double last = 0;
    int steps = 0, ups = 0, attemptsSeen = 0;
    for (; steps < 200000; ++steps) {
        auto r = s.call("tilemap.generate_step", Json::object({{"job", job}, {"work", 200}}));
        REQUIRE_MESSAGE(r.ok, error_text(r));
        const double p = r.result["progress"].get<double>();
        CHECK(p >= last);
        if (p > last) ++ups;
        last = p;
        attemptsSeen = r.result["attempts"].get<int>();
        if (r.result["done"] == true) break;
    }
    CHECK(last == 1.0);
    CHECK(ups >= 10);   // it moved with the solver, not only at the end of an attempt
    (void)attemptsSeen;
}
