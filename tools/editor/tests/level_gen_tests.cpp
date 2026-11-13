// The Level generator window's model (level_gen_model.h) against a real headless Engine in a temporary project: the arguments it
// builds, a generation run in small steps, cancelling, a scene load ending a job, the preview and the two ways to keep a level.
// The same commands the panel calls, so these are also the tests of what the window shows. GPU-free.
#include <filesystem>
#include <fstream>
#include <vector>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "level_gen_model.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1", "name": "Level Gen Test", "id": "com.example.levelgen",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "example", "components": { "Transform": { "position": [100, 50] }, "Tilemap": {
        "tileSize": [16, 16], "width": 8, "height": 6, "solidTiles": [1],
        "tiles": [ 0,0,0,0,0,0,0,0,  0,1,1,1,1,1,1,0,  0,1,0,0,1,0,1,0,  0,1,1,1,1,0,1,0,  0,1,0,1,1,1,1,0,  0,0,0,0,0,0,0,0 ] } } }
  ]
})";

const char* kOther =
    R"({"format": "factoria.scene/1", "entities": [ { "id": "cam", "components": { "Camera": {} } } ]})";

// A 16 x 16 sample with walls and one coin ('o') as the level file format of scene.import_ascii.
const char* kSampleFile = R"({
  "rows": ["................","..####..........","..#..#....##....","..#..#....##....","..####..........","................","......#.........",
           "......#....###..","...........#.#..","...........###..","..##............","..##......#.....","................","....#.....o.#...",
           "................","................"],
  "legend": {"#": 0, "o": {"prefab": "prefabs/coin.prefab.json"}},
  "tilemap": {"tileSize": [16, 16], "solidTiles": [0]}
})";

struct Session {
    stdfs::path dir;
    Engine engine;
    Session() {
        dir = fs::make_temp_dir("fa_levelgen_test").value();
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        write("scenes/other.scene.json", kOther);
        write("levels/sample.json", kSampleFile);
        write("prefabs/coin.prefab.json",
              R"({"format":"factoria.prefab/1","entity":{"id":"coin","components":{"Transform":{"position":[0,0]}}}})");
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.editorMode = true;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
        engine.step(1);
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
    std::string read(const std::string& rel) const {
        std::ifstream in(dir / rel, std::ios::binary);
        return std::string(std::istreambuf_iterator<char>(in), {});
    }
    LevelGenCaller caller() {
        return [this](const std::string& name, const Json& args) { return engine.commands().call(name, args); };
    }
    // Runs a started generation to its end; returns the number of ticks (-1: it never finished).
    int finish(LevelGenSession& s, int limit = 2000) {
        for (int i = 0; i < limit; ++i) {
            if (!s.tick(caller(), 4.0)) return i;
        }
        return -1;
    }
};

LevelGenOptions entity_options(int seed = 1) {
    LevelGenOptions o;
    o.sampleEntity = "example";
    o.width = 20;
    o.height = 12;
    o.seed = seed;
    o.n = 2;
    return o;
}

LevelGenOptions file_options(int seed = 1) {
    LevelGenOptions o;
    o.sampleFile = "levels/sample.json";
    o.width = 24;
    o.height = 16;
    o.seed = seed;
    return o;
}

}  // namespace

TEST_CASE("level generator: the arguments it builds, and the mistakes it names") {
    LevelGenOptions o = entity_options(7);
    Result<Json> a = level_gen_arguments(o);
    REQUIRE(a.ok());
    CHECK(a.value()["sample"] == "example");
    CHECK(a.value()["size"] == Json::array({20, 12}));
    CHECK(a.value()["seed"] == 7);
    CHECK(a.value()["model"] == "overlapping");
    CHECK(a.value()["n"] == 2);
    CHECK(a.value()["symmetry"] == 1);
    CHECK_FALSE(a.value().contains("periodic"));

    o.sampleFile = "levels/sample.json";  // a file wins over the entity
    CHECK(level_gen_arguments(o).value()["sample"] == "levels/sample.json");

    o.model = "tiled";  // n and symmetry belong to the overlapping model only
    o.periodic = true;
    a = level_gen_arguments(o);
    REQUIRE(a.ok());
    CHECK_FALSE(a.value().contains("n"));
    CHECK(a.value()["periodic"] == true);

    LevelGenOptions none;
    Result<Json> e = level_gen_arguments(none);
    REQUIRE_FALSE(e.ok());
    CHECK(e.error().message.find("No sample") != std::string::npos);
    CHECK_FALSE(e.error().hint.empty());

    o = entity_options();
    o.width = 0;
    CHECK_FALSE(level_gen_arguments(o).ok());
    o = entity_options();
    o.height = 5000;
    CHECK_FALSE(level_gen_arguments(o).ok());
    o = entity_options();
    o.seed = -1;
    CHECK_FALSE(level_gen_arguments(o).ok());
    o.seed = kLevelGenMaxSeed + 1;
    CHECK_FALSE(level_gen_arguments(o).ok());
    o = entity_options();
    o.model = "wave";
    CHECK(level_gen_arguments(o).error().message.find("wave") != std::string::npos);

    o = entity_options();
    o.extra = "  \n ";  // blank = no extra options
    CHECK(level_gen_arguments(o).ok());
    o.extra = R"({"maxAttempts": 3, "constraints": {"border": {"tile": 0}}})";
    a = level_gen_arguments(o);
    REQUIRE(a.ok());
    CHECK(a.value()["maxAttempts"] == 3);
    CHECK(a.value()["constraints"]["border"]["tile"] == 0);
    o.extra = "{not json";
    CHECK(level_gen_arguments(o).error().message.find("not valid JSON") != std::string::npos);
    o.extra = "[1, 2]";
    CHECK(level_gen_arguments(o).error().message.find("JSON object") != std::string::npos);
    for (const char* forbidden : {R"({"into": "x"})", R"({"place": {}})", R"({"rows": []})"}) {
        o.extra = forbidden;
        CHECK_FALSE(level_gen_arguments(o).ok());
    }
    // The fields of the window own sample, size, seed, model, n, symmetry and periodic: a value in the options would change the level
    // without the history and the preview knowing, so each is refused and the field to use is named.
    for (const char* key : {"sample", "size", "seed", "model", "n", "symmetry", "periodic"}) {
        o.extra = std::string("{\"") + key + "\": 5}";
        Result<Json> r = level_gen_arguments(o);
        INFO(o.extra);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find(std::string("'") + key + "'") != std::string::npos);
        CHECK(r.error().hint.find("and use ") != std::string::npos);  // the window control to use
    }
}

TEST_CASE("level generator: a generation runs in steps and ends with a preview; the same seed gives the same level") {
    Session s;
    LevelGenSession g;
    CHECK(g.state() == LevelGenSession::State::Idle);
    CHECK_FALSE(g.preview().valid);

    g.start(entity_options(3), s.caller());
    REQUIRE(g.state() == LevelGenSession::State::Running);
    CHECK(g.running());
    CHECK(s.finish(g) >= 0);
    REQUIRE(g.state() == LevelGenSession::State::Ready);
    const LevelGenPreview first = g.preview();
    REQUIRE(first.valid);
    CHECK(first.width == 20);
    CHECK(first.height == 12);
    CHECK(first.seed == 3);
    REQUIRE(first.rows.size() == 12);
    for (const std::string& row : first.rows) CHECK(row.size() == 20);
    CHECK(first.stats.value("attempts", 0) >= 1);
    CHECK(g.progress() == doctest::Approx(1.0));
    REQUIRE(g.tries().size() == 1);
    CHECK(g.tries()[0].ok);
    CHECK(g.tries()[0].seed == 3);

    // The same options again: the same rows (the contract of tilemap.generate, whichever way the work is cut).
    g.start(entity_options(3), s.caller());
    CHECK(s.finish(g) >= 0);
    CHECK(g.preview().rows == first.rows);
    CHECK(g.preview().stats.value("work", -1) == first.stats.value("work", -2));

    // Other seeds make other levels (at least one of eight differs), and each is a try in the history.
    bool differs = false;
    for (int seed = 4; seed < 12; ++seed) {
        g.start(entity_options(seed), s.caller());
        CHECK(s.finish(g) >= 0);
        REQUIRE(g.state() == LevelGenSession::State::Ready);
        differs = differs || g.preview().rows != first.rows;
    }
    CHECK(differs);
    CHECK(g.tries().size() == 10);
    CHECK(g.tries().back().seed == 11);
}

TEST_CASE("level generator: the history keeps the last tries only") {
    Session s;
    LevelGenSession g;
    for (int seed = 0; seed < int(LevelGenSession::kMaxTries) + 5; ++seed) {
        LevelGenOptions o = entity_options(seed);
        o.width = 6;
        o.height = 6;
        g.start(o, s.caller());
        REQUIRE(s.finish(g) >= 0);
    }
    CHECK(g.tries().size() == LevelGenSession::kMaxTries);
    CHECK(g.tries().back().seed == int(LevelGenSession::kMaxTries) + 4);
}

TEST_CASE("level generator: mistakes become a Failed state with what to fix, and the last good preview stays") {
    Session s;
    LevelGenSession g;
    g.start(entity_options(1), s.caller());
    REQUIRE(s.finish(g) >= 0);
    REQUIRE(g.preview().valid);
    const auto rows = g.preview().rows;

    LevelGenOptions bad = entity_options(2);
    bad.extra = "{oops";
    g.start(bad, s.caller());
    CHECK(g.state() == LevelGenSession::State::Failed);
    CHECK_FALSE(g.error().empty());
    CHECK_FALSE(g.hint().empty());
    CHECK(g.preview().rows == rows);
    CHECK_FALSE(g.tries().back().ok);

    // A sample the project does not have: the command's own error, with its hint.
    LevelGenOptions missing = entity_options(2);
    missing.sampleEntity = "no_such_entity";
    g.start(missing, s.caller());
    if (g.running()) s.finish(g);
    CHECK(g.state() == LevelGenSession::State::Failed);
    CHECK_FALSE(g.error().empty());
    CHECK(g.preview().rows == rows);

    // And a good run afterwards clears the error.
    g.start(entity_options(5), s.caller());
    REQUIRE(s.finish(g) >= 0);
    CHECK(g.state() == LevelGenSession::State::Ready);
    CHECK(g.error().empty());
}

TEST_CASE("level generator: cancel frees the job; a scene load ends a running one") {
    Session s;
    LevelGenSession g;
    LevelGenOptions big = entity_options(1);
    big.width = 400;
    big.height = 400;
    g.start(big, s.caller());
    REQUIRE(g.running());
    g.tick(s.caller(), 0.5);  // one small step: a 400 x 400 level does not finish in it
    g.cancel(s.caller());
    CHECK_FALSE(g.running());
    CHECK(g.state() == LevelGenSession::State::Idle);  // no preview yet
    CHECK_FALSE(g.tick(s.caller(), 4.0));              // nothing to run

    g.start(big, s.caller());
    REQUIRE(g.running());
    CommandResult load = s.engine.commands().call("scene.load", Json::object({{"path", "scenes/other.scene.json"}}));
    REQUIRE(load.ok);
    s.engine.step(1);
    CHECK_FALSE(g.tick(s.caller(), 4.0));
    // A job belongs to the scene that started it: the engine dropped it, which is a note and not a failure of the options.
    CHECK(g.state() == LevelGenSession::State::Idle);
    CHECK(g.error().empty());
    CHECK_FALSE(g.notice().empty());
    CHECK(g.tries().empty());
    // A new run clears the note.
    g.start(entity_options(2), s.caller());
    CHECK(g.notice().empty());
    g.cancel(s.caller());
}

TEST_CASE(
    "level generator: the preview reads a command answer with odd types and glyphs beyond ASCII without throwing") {
    LevelGenSession g;
    int steps = 0;
    const LevelGenCaller fake = [&](const std::string& name, const Json&) {
        CommandResult r;
        r.ok = true;
        if (name == "tilemap.generate_start") {
            r.result = Json::object({{"job", 1}});
        } else if (name == "tilemap.generate_step") {
            ++steps;
            r.result = Json::parse(
                R"({"done":true,"progress":1,"result":{"width":"4","height":null,"seed":"x","rows":["\u00e9#\u00e9.","#\u00e9..",5],
                "legend":{"\u00e9":{"tile":3,"prefab":"p.prefab.json"},"#":0,".":-1},"stats":{"attempts":"many"}}})");
        }
        return r;
    };
    g.start(entity_options(9), fake);
    REQUIRE(g.running());
    CHECK_FALSE(g.tick(fake, 4.0));
    REQUIRE(g.state() == LevelGenSession::State::Ready);
    const LevelGenPreview& p = g.preview();
    CHECK(p.seed == 9);    // a seed of the wrong type is the one the run was started with
    CHECK(p.width == 4);   // "4" is not a number: the longest row (4 cells) gives the width
    CHECK(p.height == 3);  // null: the number of rows
    REQUIRE(p.cells.size() == 12);
    const LevelGenCell e = level_gen_cell(p, 0, 0);
    CHECK(e.glyph == U'\u00e9');
    CHECK(e.tile == 3);
    CHECK(e.marker);
    CHECK(level_gen_glyph_text(e) == "\xC3\xA9");  // two bytes, one cell
    CHECK(level_gen_cell(p, 1, 0).tile == 0);
    CHECK(level_gen_cell(p, 1, 0).glyph == U'#');
    CHECK(level_gen_cell(p, 2, 0).marker);  // the second \u00e9 of the row, not the second byte of the first
    CHECK(level_gen_cell(p, 3, 0).tile == -1);
    CHECK(level_gen_cell(p, 1, 1).marker);
    CHECK(level_gen_cell(p, 0, 2).tile == -1);  // a row that is not text has no cells
    CHECK(level_gen_cell(p, 0, 2).glyph == 0);
    CHECK(steps == 1);
}

TEST_CASE("level generator: clear forgets the preview and the history") {
    Session s;
    LevelGenSession g;
    g.start(entity_options(1), s.caller());
    REQUIRE(s.finish(g) >= 0);
    REQUIRE(g.preview().valid);
    g.clear(s.caller());
    CHECK_FALSE(g.preview().valid);
    CHECK(g.tries().empty());
    CHECK(g.state() == LevelGenSession::State::Idle);
}

TEST_CASE("level generator: clear cancels a running job: no leaked job, all 8 slots free") {
    Session s;
    LevelGenSession g;
    LevelGenOptions big = entity_options(1);
    big.width = 400;
    big.height = 400;
    g.start(big, s.caller());
    REQUIRE(g.running());
    const int job = g.job();
    REQUIRE(job != 0);
    g.tick(s.caller(), 0.5);
    REQUIRE(g.running());
    g.clear(s.caller());
    CHECK(g.state() == LevelGenSession::State::Idle);
    CHECK(g.job() == 0);
    // The old job is gone from the engine ...
    const CommandResult stale = s.caller()("tilemap.generate_step", Json::object({{"job", job}, {"budgetMs", 1.0}}));
    CHECK_FALSE(stale.ok);
    // ... and it did not take one of the 8 slots: 8 new jobs start (a leaked one would make the 8th refuse).
    LevelGenOptions small =
        big;  // eight 400 x 400 solvers would pass the 256 MB the jobs may hold together: the count is what is tested
    small.width = 60;
    small.height = 60;
    Result<Json> args = level_gen_arguments(small);
    REQUIRE(args.ok());
    std::vector<int> jobs;
    for (int i = 0; i < 8; ++i) {
        const CommandResult r = s.caller()("tilemap.generate_start", args.value());
        INFO("job " << i << ": " << r.error.dump());
        REQUIRE(r.ok);
        jobs.push_back(r.result.value("job", 0));
    }
    for (int j : jobs) s.caller()("tilemap.generate_cancel", Json::object({{"job", j}}));
}

TEST_CASE("level generator: the preview's cells follow the legend") {
    Session s;
    LevelGenSession g;
    LevelGenOptions withCoin = file_options(2);
    withCoin.extra =
        R"({"constraints": {"required": ["o"]}})";  // the sample draws one coin: the level has at least one marker
    g.start(withCoin, s.caller());
    REQUIRE(s.finish(g) >= 0);
    REQUIRE_MESSAGE(g.state() == LevelGenSession::State::Ready, g.error());
    const LevelGenPreview& p = g.preview();
    REQUIRE(p.valid);
    CHECK(p.cells.size() == std::size_t(p.width) * std::size_t(p.height));
    CHECK(p.legend.contains("#"));
    int walls = 0, markers = 0, open = 0, coinGlyphs = 0;
    for (int row = 0; row < p.height; ++row)
        for (int col = 0; col < p.width; ++col) {
            const LevelGenCell c = level_gen_cell(p, col, row);
            if (p.rows[std::size_t(row)][std::size_t(col)] == '#') {
                CHECK(c.tile == 0);
                ++walls;
            }
            markers += c.marker ? 1 : 0;
            if (p.rows[std::size_t(row)][std::size_t(col)] == 'o') {
                CHECK(c.marker);  // the coin glyph carries a prefab
                ++coinGlyphs;
            }
            CHECK(c.glyph == char32_t(static_cast<unsigned char>(p.rows[std::size_t(row)][std::size_t(col)])));
            open += c.tile < 0 && !c.marker ? 1 : 0;
        }
    CHECK(walls > 0);
    CHECK(open > 0);
    CHECK(markers >= 1);
    CHECK(markers == coinGlyphs);  // only the coin glyph is a marker
    CHECK(level_gen_cell(p, -1, 0).tile == -1);
    CHECK(level_gen_cell(p, 0, p.height).tile == -1);
    CHECK(level_gen_cell(p, p.width, 0).tile == -1);
}

TEST_CASE("level generator: Keep builds the preview in the scene with scene.import_ascii") {
    Session s;
    LevelGenSession g;
    g.start(file_options(4), s.caller());
    REQUIRE(s.finish(g) >= 0);
    const LevelGenPreview& p = g.preview();
    REQUIRE(p.valid);

    const Json fields = level_gen_tilemap_fields(
        Json::parse(R"({"tileSize":[16,16],"solidTiles":[0],"tiles":[1,2],"width":9,"junk":1})"));
    CHECK(fields.contains("tileSize"));
    CHECK(fields.contains("solidTiles"));
    CHECK_FALSE(fields.contains("tiles"));  // the preview brings the tiles and the size
    CHECK_FALSE(fields.contains("width"));
    CHECK_FALSE(fields.contains("junk"));

    const Json args = level_gen_keep_arguments(p, "kept", fields, 10.0, 20.0);
    CHECK(args["entity"] == "kept");
    CHECK(args["anchor"] == "top-left");
    CommandResult r = s.engine.commands().call("scene.import_ascii", args);
    INFO(r.error.dump());
    REQUIRE(r.ok);
    s.engine.step(1);
    CommandResult e = s.engine.commands().call("scene.get_entity", Json::object({{"id", "kept"}}));
    REQUIRE(e.ok);
    const Json& tm = e.result["components"]["Tilemap"];
    CHECK(tm["width"] == p.width);
    CHECK(tm["height"] == p.height);
    CHECK(tm["solidTiles"] == Json::array({0}));

    // Keeping again replaces the entity: still one 'kept', and the coins of the first keep are not doubled.
    auto count_coins = [&] {
        CommandResult l = s.engine.commands().call("scene.list_entities", Json::object());
        REQUIRE(l.ok);
        int coins = 0;
        for (const Json& ent : l.result["entities"])
            if (ent.value("id", "").rfind("coin", 0) == 0) ++coins;
        return coins;
    };
    const int coins = count_coins();
    r = s.engine.commands().call("scene.import_ascii", args);
    REQUIRE(r.ok);
    s.engine.step(1);
    CHECK(count_coins() == coins);
}

TEST_CASE("level generator: the level file is the format scene.import_ascii and tilemap.generate read") {
    Session s;
    LevelGenSession g;
    g.start(file_options(6), s.caller());
    REQUIRE(s.finish(g) >= 0);
    const LevelGenPreview& p = g.preview();
    REQUIRE(p.valid);

    const Json fields = Json::parse(R"({"tileSize":[16,16],"solidTiles":[0]})");
    const std::string text = level_gen_file_text(p, "generated", fields);
    // One row per line, so the file is easy to read and to edit by hand.
    std::size_t lines = 0;
    for (char c : text) lines += c == '\n' ? 1 : 0;
    CHECK(lines >= std::size_t(p.height) + 5);
    CHECK(text.find("\r") == std::string::npos);
    Result<Json> doc = parse_json(text, "level file");
    REQUIRE(doc.ok());
    CHECK(doc.value()["rows"].size() == std::size_t(p.height));
    CHECK(doc.value()["entity"] == "generated");
    CHECK(doc.value()["tilemap"]["solidTiles"] == Json::array({0}));
    for (std::size_t i = 0; i < p.rows.size(); ++i) CHECK(doc.value()["rows"][i] == p.rows[i]);

    s.write("levels/generated.json", text);
    // `factoria call scene.import_ascii @levels/generated.json`: the file is the arguments.
    Result<Json> fileArgs = parse_json(s.read("levels/generated.json"), "levels/generated.json");
    REQUIRE(fileArgs.ok());
    CommandResult r = s.engine.commands().call("scene.import_ascii", fileArgs.value());
    INFO(r.error.dump());
    REQUIRE(r.ok);
    s.engine.step(1);
    CommandResult e = s.engine.commands().call("scene.get_entity", Json::object({{"id", "generated"}}));
    REQUIRE(e.ok);
    CHECK(e.result["components"]["Tilemap"]["width"] == p.width);

    // And it can be a sample itself: a generated level is a level file.
    LevelGenOptions again = file_options(1);
    again.sampleFile = "levels/generated.json";
    again.width = 10;
    again.height = 10;
    again.n = 2;
    LevelGenSession g2;
    g2.start(again, s.caller());
    REQUIRE_MESSAGE(g2.running(), g2.error());
    REQUIRE(s.finish(g2) >= 0);
    CHECK_MESSAGE(g2.state() == LevelGenSession::State::Ready, g2.error());
    CHECK(g2.preview().width == 10);
}

TEST_CASE("level generator: names for kept entities and files") {
    CHECK(level_gen_safe_name("generated") == "generated");
    CHECK(level_gen_safe_name("  my level/1!  ") == "mylevel1");
    CHECK(level_gen_safe_name("floor_2-b") == "floor_2-b");
    CHECK(level_gen_safe_name("../a.b").size() == 2);  // dots and slashes go, the letters stay
    CHECK(level_gen_safe_name("../..").empty());
    CHECK(level_gen_safe_name("///").empty());
}
