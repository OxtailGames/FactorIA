// The editor's command-backed tools (Save as prefab, Import ASCII level, Format scene files, the Audio feed), run against a
// real headless Engine in a temporary project: the same commands the dialogs call, the same results they show. GPU-free.
#include <filesystem>
#include <fstream>
#include <sstream>

#include "doctest.h"
#include "editor_internal.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Editor Tools Test",
  "id": "com.example.editortools",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#102030" } } },
    { "id": "squad", "name": "Squad", "tags": ["enemy", "tilemap:old"],
      "components": { "Transform": { "position": [120, 40, 0] }, "Shape2D": { "size": [30, 20], "color": "#cc3030" } },
      "children": [
        { "id": "gunner", "name": "Gunner",
          "components": { "Transform": { "position": [10, 5, 0] }, "Shape2D": { "shape": "circle", "size": [8, 8] } } }
      ] }
  ]
})";

struct Session {
    stdfs::path dir;
    Engine engine;

    explicit Session(const std::string& name, bool editorMode = true) {
        dir = fs::make_temp_dir("fa_editor_tools_" + name);
        stdfs::create_directories(dir / "scenes");
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.editorMode = editorMode;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
    }
    ~Session() {
        engine.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    const CommandRegistry& commands() { return engine.commands(); }
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
    void tileset() const {  // 64 x 32: two 32 x 32 tiles
        Image img;
        img.width = 64;
        img.height = 32;
        img.rgba.assign(std::size_t(img.width) * img.height * 4, 200);
        REQUIRE(save_png(img, (dir / "assets/tiles.png").generic_string()).ok());
    }
    void wav(const std::string& rel) const {  // 0.1 s of silence, 16-bit mono PCM
        const std::uint32_t n = 4410;
        std::string b;
        auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char((v >> (8 * i)) & 0xff)); };
        auto u16 = [&](std::uint16_t v) { b.push_back(char(v & 0xff)); b.push_back(char(v >> 8)); };
        b += "RIFF"; u32(36 + n * 2); b += "WAVEfmt "; u32(16); u16(1); u16(1); u32(44100); u32(88200); u16(2); u16(16);
        b += "data"; u32(n * 2);
        b.append(std::size_t(n) * 2, '\0');
        write(rel, b);
    }
};

bool has(const std::vector<std::string>& v, const std::string& needle) {
    for (const std::string& s : v)
        if (s.find(needle) != std::string::npos) return true;
    return false;
}

const char* kCoinPrefab = R"({"format":"factoria.prefab/1","entity":{"name":"Coin","components":{"Shape2D":{"shape":"circle","size":[12,12]}}}})";

}  // namespace

// ------------------------------------------------------------------------------------------------- Save as prefab
TEST_CASE("save as prefab: suggests prefabs/<id>.prefab.json") {
    CHECK(suggest_prefab_path("enemy_3") == "prefabs/enemy_3.prefab.json");
    CHECK(suggest_prefab_path("my enemy/1") == "prefabs/my_enemy_1.prefab.json");
    CHECK(suggest_prefab_path("") == "prefabs/entity.prefab.json");
    CHECK(suggest_prefab_path("..") == "prefabs/entity.prefab.json");
}

TEST_CASE("save as prefab: saves, asks before replacing, replaces on request, and explains errors") {
    Session s("prefab");
    // First save: written, with the children and the notes about what the file leaves out.
    PrefabSaveOutcome r = save_prefab(s.commands(), "squad", "prefabs/squad.prefab.json", false);
    REQUIRE_MESSAGE(r.ok, r.message);
    CHECK(r.path == "prefabs/squad.prefab.json");
    CHECK(r.children == 1);
    CHECK_FALSE(r.overwritten);
    CHECK(has(r.notes, "Transform.position"));  // the root position is where this instance stands, not part of the prefab
    CHECK(has(r.notes, "tilemap:old"));         // tags added by scene.import_ascii are dropped
    REQUIRE(s.exists("prefabs/squad.prefab.json"));
    const Json file = s.json("prefabs/squad.prefab.json");
    CHECK(file["format"] == "factoria.prefab/1");
    CHECK(file["entity"]["children"].size() == 1);

    // Second save of the same file: NOT written; the dialog must ask.
    s.write("prefabs/squad.prefab.json", "{\"marker\": true}");
    r = save_prefab(s.commands(), "squad", "prefabs/squad.prefab.json", false);
    CHECK_FALSE(r.ok);
    CHECK(r.alreadyExists);
    CHECK(r.code == "already_exists");
    CHECK(r.message.find("already exists") != std::string::npos);
    CHECK(r.hint.find("overwrite") != std::string::npos);
    CHECK(s.read("prefabs/squad.prefab.json") == "{\"marker\": true}");  // untouched

    // After the user confirms: retried with overwrite.
    r = save_prefab(s.commands(), "squad", "prefabs/squad.prefab.json", true);
    REQUIRE_MESSAGE(r.ok, r.message);
    CHECK(r.overwritten);
    CHECK(s.json("prefabs/squad.prefab.json")["format"] == "factoria.prefab/1");

    // Errors teach: a path that does not end in .prefab.json suggests one; an unknown entity suggests ids.
    r = save_prefab(s.commands(), "squad", "prefabs/squad.json", false);
    CHECK_FALSE(r.ok);
    CHECK_FALSE(r.alreadyExists);
    CHECK(r.hint.find("prefabs/squad.prefab.json") != std::string::npos);
    r = save_prefab(s.commands(), "squd", "prefabs/x.prefab.json", false);
    CHECK_FALSE(r.ok);
    CHECK(r.message.find("squad") != std::string::npos);  // did you mean
    CHECK_FALSE(s.exists("prefabs/x.prefab.json"));
}

// ------------------------------------------------------------------------------------------------- Import ASCII level
TEST_CASE("import ascii: the form becomes command arguments, and wrong boxes say which one") {
    AsciiImportForm f;
    f.rows = "..o..\n#####\n\n";  // trailing blank lines from a paste are dropped
    f.legend = "{\"#\": 0, \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}}";
    f.tilemap = "{\"tileset\": \"assets/tiles.png\", \"tileSize\": [32, 32]}";
    f.options = "{\"entity\": \"map\", \"anchor\": \"bottom-left\"}";
    f.path = " scenes/level1.scene.json ";
    f.from = "scenes/main.scene.json";
    auto a = ascii_import_args(f, true);
    REQUIRE(a.ok());
    CHECK((*a)["rows"] == Json::parse("[\"..o..\",\"#####\"]"));
    CHECK((*a)["legend"]["o"]["prefab"] == "prefabs/coin.prefab.json");
    CHECK((*a)["tilemap"]["tileSize"] == Json::parse("[32,32]"));
    CHECK((*a)["entity"] == "map");
    CHECK((*a)["path"] == "scenes/level1.scene.json");
    CHECK((*a)["from"] == "scenes/main.scene.json");
    CHECK((*a)["dryRun"] == true);
    CHECK_FALSE(a->contains("save"));

    // The running scene: no path, no dryRun; `save` only when asked.
    f.toFile = false;
    f.save = true;
    a = ascii_import_args(f, true);
    REQUIRE(a.ok());
    CHECK_FALSE(a->contains("path"));
    CHECK_FALSE(a->contains("dryRun"));
    CHECK((*a)["save"] == true);

    // Mistakes name the box. Invalid JSON gives line:column.
    AsciiImportForm bad = f;
    bad.rows = "\n\n";
    auto noRows = ascii_import_args(bad, false);
    REQUIRE_FALSE(noRows.ok());
    CHECK(noRows.error().message.find("rows box is empty") != std::string::npos);
    bad = f;
    bad.legend = "{\"#\": 0,\n \"o\": }";
    auto e = ascii_import_args(bad, false);
    REQUIRE_FALSE(e.ok());
    CHECK(e.error().message.find("legend:2:") != std::string::npos);
    bad = f;
    bad.legend = "[1, 2]";
    CHECK(ascii_import_args(bad, false).error().message.find("must be a JSON object") != std::string::npos);
    bad = f;
    bad.legend = "";
    CHECK(ascii_import_args(bad, false).error().message.find("legend box is empty") != std::string::npos);
    bad = f;
    bad.options = "{\"rows\": []}";
    CHECK(ascii_import_args(bad, false).error().message.find("'rows'") != std::string::npos);
    bad = f;
    bad.toFile = true;
    bad.path = "  ";
    CHECK(ascii_import_args(bad, false).error().message.find("target scene file is empty") != std::string::npos);
}

TEST_CASE("import ascii: preview writes nothing and reports row/column errors, warnings and the object count") {
    Session s("import_preview");
    s.tileset();
    s.write("prefabs/coin.prefab.json", kCoinPrefab);
    AsciiImportForm f;
    f.rows = "..o..o..\n.o......\n########";
    f.legend = "{\"#\": 0, \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}, \"x\": 1}";  // 'x' is never used
    f.tilemap = "{\"tileset\": \"assets/tiles.png\", \"tileSize\": [32, 32], \"solidTiles\": [0]}";
    f.options = "{\"entity\": \"map\"}";
    f.path = "scenes/level1.scene.json";
    f.from = "scenes/main.scene.json";

    AsciiImportOutcome r = run_ascii_import(s.commands(), f, true);
    REQUIRE_MESSAGE(r.ok, r.message);
    CHECK(r.dryRun);
    CHECK(r.spawned == 3);
    CHECK(r.spawnedLines.size() == 3);
    CHECK(r.spawnedLines[0].find("coin_1") != std::string::npos);
    CHECK(r.spawnedLines[0].find("cell (2, 0)") != std::string::npos);
    CHECK(r.width == 8);
    CHECK(r.height == 3);
    CHECK(r.tileCount == 8);
    CHECK(r.saved.empty());
    CHECK(has(r.warnings, "legend['x']"));  // the unused glyph
    CHECK_FALSE(s.exists("scenes/level1.scene.json"));  // a preview writes nothing

    // A ragged row: the error names the row and the lengths, and nothing changes.
    f.rows = "..o..o..\n.o....\n########";
    r = run_ascii_import(s.commands(), f, true);
    CHECK_FALSE(r.ok);
    CHECK(r.message.find("row 1") != std::string::npos);
    CHECK_FALSE(r.hint.empty());
    // A glyph that is not in the legend: row and column plus a suggestion.
    f.rows = "..o..o..\n.o..?...\n########";
    r = run_ascii_import(s.commands(), f, true);
    CHECK_FALSE(r.ok);
    CHECK(r.message.find("column 4") != std::string::npos);
    // A missing prefab.
    f.rows = "..o..o..";
    f.legend = "{\"o\": {\"prefab\": \"prefabs/coinn.prefab.json\"}}";
    r = run_ascii_import(s.commands(), f, true);
    CHECK_FALSE(r.ok);
    CHECK(r.message.find("prefabs/coin.prefab.json") != std::string::npos);  // did you mean
}

TEST_CASE("import ascii: the import writes the scene file, replaces earlier objects, and leaves the running world alone") {
    Session s("import_file");
    s.tileset();
    s.write("prefabs/coin.prefab.json", kCoinPrefab);
    AsciiImportForm f;
    f.rows = "..o..o..\n########";
    f.legend = "{\"#\": 0, \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}}";
    f.tilemap = "{\"tileset\": \"assets/tiles.png\", \"tileSize\": [32, 32], \"solidTiles\": [0]}";
    f.options = "{\"entity\": \"map\", \"anchor\": \"bottom-left\", \"position\": [0, 0]}";
    f.path = "scenes/level1.scene.json";
    f.from = "scenes/main.scene.json";
    const std::size_t before = s.engine.world().entity_count();

    AsciiImportOutcome r = run_ascii_import(s.commands(), f, false);
    REQUIRE_MESSAGE(r.ok, r.message);
    CHECK(r.spawned == 2);
    CHECK(r.saved == "scenes/level1.scene.json");
    REQUIRE(s.exists("scenes/level1.scene.json"));
    CHECK(s.engine.world().entity_count() == before);  // the running world did not change
    const Json scene = s.json("scenes/level1.scene.json");
    bool hasMap = false, hasCam = false;
    int coins = 0;
    for (const Json& e : scene["entities"]) {
        hasMap = hasMap || e["id"] == "map";
        hasCam = hasCam || e["id"] == "cam";  // `from` brought the base scene along
        coins += e["id"].get<std::string>().rfind("coin_", 0) == 0 ? 1 : 0;
    }
    CHECK(hasMap);
    CHECK(hasCam);
    CHECK(coins == 2);

    // Importing again replaces the objects of the first import instead of duplicating them.
    f.from.clear();
    f.rows = "..o...\n######";
    r = run_ascii_import(s.commands(), f, false);
    REQUIRE_MESSAGE(r.ok, r.message);
    CHECK(r.removed == 2);
    coins = 0;
    const Json again = s.json("scenes/level1.scene.json");
    for (const Json& e : again["entities"]) coins += e["id"].get<std::string>().rfind("coin_", 0) == 0 ? 1 : 0;
    CHECK(coins == 1);
}

TEST_CASE("import ascii: into the running scene, the editor may also save it (no unsafe_save), other callers may not") {
    AsciiImportForm f;
    f.rows = "...\n###";
    f.legend = "{\"#\": 0}";
    f.options = "{\"entity\": \"map\"}";
    f.toFile = false;
    f.save = true;
    {
        Session editor("import_running_editor", true);
        const std::size_t before = editor.engine.world().entity_count();
        AsciiImportOutcome r = run_ascii_import(editor.commands(), f, false);
        REQUIRE_MESSAGE(r.ok, r.message);
        CHECK(editor.engine.world().entity_count() == before + 1);  // the Tilemap entity
        CHECK(r.saved == "scenes/main.scene.json");
        bool found = false;
        const Json saved = editor.json("scenes/main.scene.json");
        for (const Json& e : saved["entities"]) found = found || e["id"] == "map";
        CHECK(found);
    }
    {
        Session game("import_running_game", false);  // a plain `factoria call`: the running scene is only the default mainScene
        AsciiImportOutcome r = run_ascii_import(game.commands(), f, false);
        CHECK_FALSE(r.ok);
        CHECK(r.code == "unsafe_save");
        CHECK(r.hint.find("path") != std::string::npos);
        const Json untouched = game.json("scenes/main.scene.json");
        CHECK(untouched["entities"].size() == 2);
    }
}

TEST_CASE("import ascii: level argument files load into the form") {
    Session s("import_load");
    s.write("levels/level1.json", R"({
  "rows": ["..o..", "#####"],
  "legend": { "#": 0, "o": { "prefab": "prefabs/coin.prefab.json" } },
  "entity": "map",
  "tilemap": { "tileset": "assets/tiles.png", "tileSize": [32, 32] },
  "anchor": "bottom-left",
  "position": [0, 0],
  "path": "scenes/level1.scene.json"
})");
    s.write("levels/levels.json", "[{\"name\": \"x\", \"map\": [\"#\"]}]");
    s.write("levels/nolegend.json", "{\"rows\": [\"#\"]}");
    s.write("levels/other.scene.json", "{}");
    auto f = load_ascii_form((s.dir / "levels/level1.json").generic_string());
    REQUIRE_MESSAGE(f.ok(), f.error().message);
    CHECK(f->rows == "..o..\n#####");
    CHECK(f->path == "scenes/level1.scene.json");
    CHECK(f->toFile);
    CHECK(f->legend.find("prefabs/coin.prefab.json") != std::string::npos);
    CHECK(f->tilemap.find("tileSize") != std::string::npos);
    CHECK(f->options.find("\"entity\"") != std::string::npos);
    CHECK(f->options.find("anchor") != std::string::npos);
    CHECK(f->options.find("rows") == std::string::npos);
    auto args = ascii_import_args(*f, false);
    REQUIRE(args.ok());
    CHECK((*args)["entity"] == "map");
    CHECK((*args)["position"] == Json::parse("[0,0]"));

    // Files that are not level arguments explain what is expected.
    auto arr = load_ascii_form((s.dir / "levels/levels.json").generic_string());
    REQUIRE_FALSE(arr.ok());
    CHECK(arr.error().message.find("array of 1 entries") != std::string::npos);
    CHECK_FALSE(arr.error().hint.empty());
    auto nol = load_ascii_form((s.dir / "levels/nolegend.json").generic_string());
    REQUIRE_FALSE(nol.ok());
    CHECK(nol.error().message.find("missing \"legend\"") != std::string::npos);
    CHECK_FALSE(load_ascii_form((s.dir / "levels/none.json").generic_string()).ok());

    const std::vector<std::string> files = {"levels/level2.json", "levels/level1.json", "levels/x.scene.json", "scenes/main.scene.json", "levels/a/b.json"};
    const std::vector<std::string> levels = level_files(files);
    REQUIRE(levels.size() == 3);
    CHECK(levels[0] == "levels/a/b.json");
    CHECK(levels[1] == "levels/level1.json");
}

// ------------------------------------------------------------------------------------------------- Format scene files
namespace {
const char* kMessyScene = R"({
    "format": "factoria.scene/1",
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
                }
            }
        }
    ]
})";
}  // namespace

TEST_CASE("format scene files: check lists the files, the real run rewrites them, errors keep file and position") {
    Session s("format");
    (void)run_scene_format(s.commands(), false);  // the hand-written fixtures above are not canonical either: start clean
    s.write("scenes/messy.scene.json", kMessyScene);
    s.write("prefabs/broken.prefab.json", "{\n  \"format\": \"factoria.prefab/1\",\n  \"entity\": {,}\n}");
    const std::string before = s.read("scenes/messy.scene.json");

    // 1. check: nothing is written.
    FormatOutcome c = run_scene_format(s.commands(), true);
    REQUIRE_MESSAGE(c.ok, c.message);
    CHECK(c.check);
    REQUIRE(c.files.size() == 1);
    CHECK(c.files[0] == "scenes/messy.scene.json");
    CHECK(c.unchanged >= 1);  // main.scene.json
    REQUIRE(c.errors.size() == 1);
    CHECK(c.errors[0].find("prefabs/broken.prefab.json:3:") != std::string::npos);  // line:column of the syntax error
    CHECK(s.read("scenes/messy.scene.json") == before);

    // 2. real run (what the confirmation button does).
    FormatOutcome r = run_scene_format(s.commands(), false);
    REQUIRE_MESSAGE(r.ok, r.message);
    CHECK_FALSE(r.check);
    REQUIRE(r.files.size() == 1);
    CHECK(r.files[0] == "scenes/messy.scene.json");
    CHECK(s.read("scenes/messy.scene.json") != before);
    CHECK(s.read("scenes/messy.scene.json").find("\"position\": [100, 50, 0]") != std::string::npos);
    CHECK(s.read("prefabs/broken.prefab.json").find("{,}") != std::string::npos);  // left unchanged

    // 3. now clean.
    c = run_scene_format(s.commands(), true);
    CHECK(c.files.empty());

    // Only the given paths.
    s.write("scenes/other.scene.json", kMessyScene);
    c = run_scene_format(s.commands(), true, {"scenes/other.scene.json"});
    REQUIRE(c.files.size() == 1);
    CHECK(c.files[0] == "scenes/other.scene.json");
    FormatOutcome bad = run_scene_format(s.commands(), true, {"scenes/typo.scene.json"});
    CHECK_FALSE(bad.ok);
    CHECK(bad.code == "not_found");
}

TEST_CASE("scenes saved by the editor are already in the canonical layout") {
    Session s("canonical");
    s.tileset();
    s.write("prefabs/coin.prefab.json", kCoinPrefab);
    (void)run_scene_format(s.commands(), false);  // the hand-written fixtures are not canonical; what the editor writes below is
    // Build a scene with the things whose layout used to differ by hand: short arrays, colours, a Tilemap's rows.
    REQUIRE(s.engine.commands().call("scene.import_ascii", Json::parse(R"({
      "rows": ["..o..o..", ".o......", "########"],
      "legend": {"#": 0, "o": {"prefab": "prefabs/coin.prefab.json"}},
      "tilemap": {"tileset": "assets/tiles.png", "tileSize": [32, 32], "solidTiles": [0]}, "entity": "map"})")).ok);
    // The editor saves with save_scene_file (Editor::save_scene_now and its scene.save override).
    REQUIRE(save_scene_file(s.engine.world(), "scenes/main.scene.json").ok());
    REQUIRE(save_scene_file(s.engine.world(), "scenes/copy.scene.json").ok());
    const FormatOutcome c = run_scene_format(s.commands(), true);
    REQUIRE_MESSAGE(c.ok, c.message);
    CHECK_MESSAGE(c.files.empty(), "not canonical: " << join(c.files, ", "));
    CHECK(c.errors.empty());
    CHECK(c.unchanged >= 2);
    // And a prefab saved from the editor's context menu.
    REQUIRE(save_prefab(s.commands(), "squad", "prefabs/squad.prefab.json", false).ok);
    CHECK(run_scene_format(s.commands(), true, {"prefabs"}).files.empty());
    // The text itself: Tilemap rows on separate lines, short arrays on one line.
    const std::string text = s.read("scenes/main.scene.json");
    CHECK(text.find("\"tileSize\": [32.0, 32.0]") != std::string::npos);
    CHECK(text.find("0,  0,  0,  0,  0,  0,  0,  0\n") != std::string::npos);  // the last map row on one line, columns aligned
}

// ------------------------------------------------------------------------------------------------- Audio panel
TEST_CASE("audio feed: polls only newer plays, keeps failed loads visible, filters and clears") {
    Session s("audio");
    s.wav("assets/blip.wav");
    s.engine.step(2);
    AudioLogState a;
    CHECK(poll_audio_log(s.commands(), a) == 0);
    CHECK(a.error.empty());
    CHECK(a.plays.empty());

    REQUIRE(s.commands().call("script.eval", Json::parse(R"({"code":"audio.play('assets/blip.wav', {bus: 'ui', volume: 0.5}); audio.play('assets/missing.wav');"})")).ok);
    CHECK(poll_audio_log(s.commands(), a) == 2);
    REQUIRE(a.plays.size() == 2);
    CHECK(a.plays[0].path == "assets/blip.wav");
    CHECK(a.plays[0].bus == "ui");
    CHECK(a.plays[0].volume == doctest::Approx(0.5f));
    CHECK(a.plays[0].ok);
    CHECK(a.plays[0].seq == 1);
    CHECK(a.plays[0].frame == s.engine.world().frame());
    CHECK(a.plays[1].path == "assets/missing.wav");
    CHECK_FALSE(a.plays[1].ok);  // a failed load is in the log, flagged
    CHECK(a.after == 2);

    // Nothing new: nothing added (the poll asks `after` the last seq).
    CHECK(poll_audio_log(s.commands(), a) == 0);
    CHECK(a.plays.size() == 2);

    // Filters.
    a.filter = "BLIP";
    CHECK(audio_play_visible(a.plays[0], a));
    CHECK_FALSE(audio_play_visible(a.plays[1], a));
    a.filter.clear();
    a.onlyFailed = true;
    CHECK_FALSE(audio_play_visible(a.plays[0], a));
    CHECK(audio_play_visible(a.plays[1], a));
    a.onlyFailed = false;

    // Clear forgets what was shown but not the position: only later plays appear.
    clear_audio_log(a);
    CHECK(a.plays.empty());
    CHECK(poll_audio_log(s.commands(), a) == 0);
    REQUIRE(s.commands().call("script.eval", Json::parse(R"({"code":"audio.play('assets/blip.wav');"})")).ok);
    CHECK(poll_audio_log(s.commands(), a) == 1);
    REQUIRE(a.plays.size() == 1);
    CHECK(a.plays[0].seq == 3);

    // A new project starts a new log at seq 1.
    reset_audio_log(a);
    CHECK(a.after == 0);
    CHECK(poll_audio_log(s.commands(), a) == 3);
}
