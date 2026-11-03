// music.create, music.edit, music.info, music.check, music.preview, music.instrument, music.chord, music.scale, music.arpeggio,
// music.bassline and music.drums: song documents as project files (docs/MUSIC.md). The model, the checks and the renderer are tested in
// fa_audio (engine/audio/tests/test_song.cpp); here: the files, the recipe of a preview, validation, the edit operations and their errors.
#include <doctest.h>

#include <algorithm>

#include "asset_test_helpers.h"
#include "fa/audio/analysis.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"

using namespace fa;
using namespace fa::testing;

namespace {

const char* kSong = "assets/music/theme.song.json";

Json make_song(const AssetsProject& p, Json extra = Json::object()) {
    Json args = {{"path", kSong}, {"picture", false}};
    for (auto it = extra.begin(); it != extra.end(); ++it) args[it.key()] = it.value();
    return p.ok("music.create", args);
}

Json song_file(const AssetsProject& p, const std::string& rel = kSong) { return parse_json(read_all(p.file(rel)), rel).value(); }

Json edit(const AssetsProject& p, const Json& ops) { return p.ok("music.edit", {{"path", kSong}, {"ops", ops}}); }

bool issue_mentions(const Json& issues, const std::string& pointer, const std::string& text) {
    for (const Json& i : issues)
        if (i["pointer"] == pointer && i["message"].get<std::string>().find(text) != std::string::npos) return true;
    return false;
}

}  // namespace

TEST_CASE("music.create: writes a valid starting song, returns its summary and a piano roll, and never replaces a file silently") {
    AssetsProject p;
    const Json r = p.ok("music.create", {{"path", kSong}});
    CHECK(r["created"] == true);
    CHECK(r["progression"] == "Am F C G");
    CHECK(r["structure"] == "intro (4 bars) > loop (4 bars) x2 > outro (4 bars)");
    CHECK(r["bars"] == 16);
    CHECK(r["tracks"].size() == 4);
    REQUIRE(r.contains("$image"));
    CHECK(r["$image"]["mimeType"] == "image/png");
    CHECK(std::filesystem::exists(r["$image"]["path"].get<std::string>()));
    const Json doc = song_file(p);
    CHECK(doc["format"] == "factoria.song/1");
    CHECK(doc["tracks"]["drums"]["instrument"] == "kit");

    // the same file again is not replaced unless asked
    CommandResult again = p.call("music.create", {{"path", kSong}});
    REQUIRE_FALSE(again.ok);
    CHECK(again.error["code"] == "exists");
    p.ok("music.create", {{"path", kSong}, {"overwrite", true}, {"picture", false}, {"key", "D"}, {"mode", "dorian"}, {"tempo", 96}, {"style", "funk"}});
    const Json funk = song_file(p);
    CHECK(funk["key"] == "D");
    CHECK(funk["mode"] == "dorian");
    CHECK(funk["tempo"] == 96);
}

TEST_CASE("music.create: Roman numerals, chord names, 3/4 and the errors that say what to write") {
    AssetsProject p;
    const Json roman = make_song(p, {{"progression", "I V vi IV"}, {"key", "G"}, {"mode", "major"}, {"arpeggio", false}});
    CHECK(roman["progression"] == "G D Em C");
    CHECK(roman["tracks"].size() == 3);
    const Json waltz = make_song(p, {{"meter", "3/4"}, {"overwrite", true}});
    CHECK(waltz["meter"] == "3/4");
    CHECK(song_file(p)["tracks"]["drums"]["patterns"]["groove"].contains("grid"));

    CHECK(p.call("music.create", {{"path", "songs/x.song.json"}}).error["code"] == "invalid_argument");
    CHECK(p.call("music.create", {{"path", "assets/music/x.json"}}).error["code"] == "invalid_argument");
    CommandResult key = p.call("music.create", {{"path", "assets/music/x.song.json"}, {"key", "H"}});
    REQUIRE_FALSE(key.ok);
    CHECK(key.error["message"].get<std::string>().find("key 'H'") != std::string::npos);
    CommandResult mode = p.call("music.create", {{"path", "assets/music/x.song.json"}, {"mode", "dorien"}});
    REQUIRE_FALSE(mode.ok);
    CHECK(mode.error["hint"].get<std::string>().find("dorian") != std::string::npos);  // did you mean
    CHECK(p.call("music.create", {{"path", "assets/music/x.song.json"}, {"style", "rok"}}).error["hint"].get<std::string>().find("rock") != std::string::npos);
    CHECK(p.call("music.create", {{"path", "assets/music/x.song.json"}, {"progression", "Am Zz"}}).ok == false);
    CHECK(p.call("music.create", {{"path", "assets/music/x.song.json"}, {"meter", "3/3"}}).ok == false);
    CHECK(p.call("music.create", {{"path", "assets/music/x.song.json"}, {"tempo", 9000}}).ok == false);
    CHECK(p.call("music.create", {{"path", "assets/music/x.song.json"}, {"tempoo", 90}}).ok == false);  // closed schema
    CHECK_FALSE(p.exists("assets/music/x.song.json"));
}

TEST_CASE("music.info: structure, sections, tracks, preview state; a broken song fails with every issue, a line and a column") {
    AssetsProject p;
    make_song(p);
    const Json info = p.ok("music.info", {{"path", kSong}, {"picture", false}});
    CHECK(info["valid"] == true);
    CHECK(info["tempo"] == 115.0);
    CHECK(info["seconds"].get<double>() == doctest::Approx(33.39).epsilon(0.01));
    CHECK(info["sections"].size() == 3);
    CHECK(info["sections"][1]["startBar"] == 5);
    CHECK(info["sections"][1]["notesByTrack"].contains("bass"));
    CHECK(info["preview"]["exists"] == false);
    CHECK_FALSE(info.contains("$image"));

    const Json zoom = p.ok("music.info", {{"path", kSong}, {"fromBar", 5}, {"bars", 4}, {"width", 600}});
    CHECK(zoom["pianoRoll"]["fromBar"] == 5);
    CHECK(zoom["pianoRoll"]["width"] == 600);

    // inline song
    const Json inline_ = p.ok("music.info", {{"song", {{"tempo", 90}, {"tracks", {{"lead", {{"instrument", "pluck"}, {"patterns", {{"a", "C4:4 E4 G4 r"}}}}}}}, {"sections", Json::array({{{"name", "main"}, {"play", {{"lead", "a*2"}}}}})}}}, {"picture", false}});
    CHECK(inline_["bars"] == 2);
    CHECK_FALSE(inline_.contains("path"));
    CHECK(p.call("music.info", {{"path", kSong}, {"song", Json::object()}}).error["code"] == "invalid_argument");
    CHECK(p.call("music.info", {}).error["code"] == "invalid_argument");

    // a song with two mistakes: both are reported, with where
    Json bad = song_file(p);
    bad["tracks"]["bass"]["patterns"]["line"] = "A1:4 E2 Q9 A1";
    bad["tracks"]["pad"]["instrument"] = "pda";
    write_all(p.file("assets/music/bad.song.json"), dump_json(bad));
    CommandResult r = p.call("music.info", {{"path", "assets/music/bad.song.json"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "invalid_song");
    const Json issues = r.error["data"]["issues"];
    CHECK(issues.size() >= 2);
    CHECK(issue_mentions(issues, "/tracks/bass/patterns/line", "Q9"));
    bool sawLine = false, sawDidYouMean = false;
    for (const Json& i : issues) {
        if (i["pointer"] == "/tracks/bass/patterns/line") sawLine = i["line"] == 1 && i["column"] == 9;
        if (i["pointer"] == "/tracks/pad/instrument") sawDidYouMean = i["hint"].get<std::string>().find("pad") != std::string::npos;
    }
    CHECK(sawLine);
    CHECK(sawDidYouMean);

    CommandResult missing = p.call("music.info", {{"path", "assets/music/them.song.json"}});
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error["code"] == "not_found");
    CHECK(missing.error["hint"].get<std::string>().find("theme.song.json") != std::string::npos);
    write_all(p.file("assets/music/broken.song.json"), "{ not json");
    CHECK(p.call("music.info", {{"path", "assets/music/broken.song.json"}}).error["code"] == "invalid_song");
}

TEST_CASE("music.check: a clean song passes; findings carry the rule, the place and a fix; render adds the loudness") {
    AssetsProject p;
    make_song(p);
    const Json ok = p.ok("music.check", {{"path", kSong}});
    CHECK(ok["ok"] == true);
    CHECK(ok["errors"] == 0);
    CHECK(ok["warnings"] == 0);
    CHECK_FALSE(ok.contains("loudness"));

    const Json rendered = p.ok("music.check", {{"path", kSong}, {"render", true}, {"targetLufs", -18}});
    CHECK(rendered["rulesRun"].back() == "loudness");
    CHECK(rendered["loudness"]["lufs"].get<double>() == doctest::Approx(-18.2).epsilon(0.1));
    CHECK(rendered["target"]["lufs"] == -18);
    // too far from the target
    const Json loud = p.ok("music.check", {{"path", kSong}, {"render", true}, {"targetLufs", -6}});
    CHECK(loud["ok"] == false);
    bool sawLoudness = false;
    for (const Json& i : loud["issues"]) sawLoudness = sawLoudness || i["rule"] == "loudness";
    CHECK(sawLoudness);

    // a wrong note: off_key with the token's pointer, line and column; and a rule filter
    edit(p, Json::array({{{"op", "set_pattern"}, {"track", "bass"}, {"pattern", "line"}, {"notes", "A1:4 C#2 A1 E2 | F2:4 C3 F2 C3 | C2:4 G2 C2 G2 | G1:4 D2 G1 D2"}}}));
    const Json off = p.ok("music.check", {{"path", kSong}});
    CHECK(off["ok"] == false);
    REQUIRE(off["issues"].size() >= 1);
    const Json first = off["issues"][0];
    CHECK(first["rule"] == "off_key");
    CHECK(first["pointer"] == "/tracks/bass/patterns/line");
    CHECK(first["line"] == 1);
    CHECK(first["column"] == 6);
    CHECK(first["token"] == "C#2");
    CHECK_FALSE(first["hint"].get<std::string>().empty());
    CHECK(p.ok("music.check", {{"path", kSong}, {"rules", Json::array({"range"})}})["ok"] == true);

    CommandResult badRule = p.call("music.check", {{"path", kSong}, {"rules", Json::array({"off_ky"})}});
    REQUIRE_FALSE(badRule.ok);
    CHECK(badRule.error["hint"].get<std::string>().find("off_key") != std::string::npos);
    CHECK(p.call("music.check", {{"path", kSong}, {"targetLufs", 5}}).ok == false);
    CHECK(p.call("music.check", {{"path", kSong}, {"rules", "range"}}).ok == false);
}

TEST_CASE("music.preview: a deterministic stereo WAV next to the song, a recipe whose inputs are the song, and a stale preview is made again") {
    AssetsProject p;
    make_song(p, {{"arpeggio", false}});
    const Json r = p.ok("music.preview", {{"path", kSong}, {"sampleRate", 22050}});
    CHECK(r["path"] == "assets/music/theme.preview.wav");
    CHECK(r["measurements"]["channels"] == 2);
    CHECK(r["measurements"]["sampleRate"] == 22050);
    CHECK(r["measurements"]["peakDb"].get<double>() < 0);
    CHECK(r["seconds"].get<double>() == doctest::Approx(33.39).epsilon(0.01));
    CHECK(r.contains("$image"));
    const std::string wav = read_all(p.file("assets/music/theme.preview.wav"));
    REQUIRE(wav.size() > 44);
    CHECK(wav.substr(0, 4) == "RIFF");
    auto loudness = measure_loudness({reinterpret_cast<const std::uint8_t*>(wav.data()), wav.size()}, ".wav");
    REQUIRE(loudness.ok());
    CHECK(loudness->integratedLufs == doctest::Approx(r["measurements"]["lufs"].get<double>()).epsilon(0.05));

    const Json prov = p.manifest()["assets"]["assets/music/theme.preview.wav"]["provenance"];
    CHECK(prov["origin"] == "original");
    CHECK(prov["kind"] == "music");
    CHECK(prov["ai"] == false);
    const Json recipe = prov["recipe"];
    CHECK(recipe["command"] == "music.preview");
    CHECK(recipe["args"]["path"] == kSong);
    CHECK_FALSE(recipe["args"].contains("picture"));
    REQUIRE(recipe["inputs"].size() >= 1);
    CHECK(recipe["inputs"][0]["path"] == kSong);

    // same song and options, same bytes
    p.ok("music.preview", {{"path", kSong}, {"sampleRate", 22050}, {"picture", false}});
    CHECK(read_all(p.file("assets/music/theme.preview.wav")) == wav);

    // info says it is fresh, an edit makes it stale, validate warns, regenerate renders the new song
    CHECK(p.ok("music.info", {{"path", kSong}, {"picture", false}})["preview"]["stale"] == false);
    edit(p, Json::array({{{"op", "set_song"}, {"tempo", 140}}}));
    CHECK(p.ok("music.info", {{"path", kSong}, {"picture", false}})["preview"]["stale"] == true);
    bool warned = false;
    for (const ValidationIssue& w : validate_project(p.dir).warnings) warned = warned || w.message.find("'assets/music/theme.preview.wav' is stale") != std::string::npos;
    CHECK(warned);
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 1);
    CHECK(read_all(p.file("assets/music/theme.preview.wav")) != wav);
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 0);
}

TEST_CASE("music.preview: a range, solo and mute, ogg, and errors that say what to do") {
    AssetsProject p;
    make_song(p, {{"arpeggio", false}});
    const Json whole = p.ok("music.preview", {{"path", kSong}, {"sampleRate", 22050}, {"picture", false}});
    const Json part = p.ok("music.preview", {{"path", kSong}, {"sampleRate", 22050}, {"picture", false}, {"fromBar", 5}, {"bars", 4}, {"out", "assets/music/part.wav"}});
    CHECK(part["seconds"].get<double>() < whole["seconds"].get<double>() / 2);
    CHECK(part["range"]["fromBar"] == 5);
    const Json solo = p.ok("music.preview", {{"path", kSong}, {"sampleRate", 22050}, {"picture", false}, {"solo", Json::array({"bass"})}, {"out", "assets/music/bass.wav"}});
    CHECK(solo["measurements"]["lufs"].get<double>() < whole["measurements"]["lufs"].get<double>());
    CHECK(solo["solo"][0] == "bass");
    p.ok("music.preview", {{"path", kSong}, {"sampleRate", 22050}, {"picture", false}, {"mute", Json::array({"drums"})}, {"out", "assets/music/nodrums.ogg"}});
    CHECK(read_all(p.file("assets/music/nodrums.ogg")).substr(0, 4) == "OggS");

    CommandResult unknown = p.call("music.preview", {{"path", kSong}, {"solo", Json::array({"bas"})}});
    REQUIRE_FALSE(unknown.ok);
    CHECK(unknown.error["hint"].get<std::string>().find("bass") != std::string::npos);
    CHECK(p.call("music.preview", {{"path", kSong}, {"fromBar", 99}}).error["code"] == "invalid_argument");
    CHECK(p.call("music.preview", {{"path", kSong}, {"out", "assets/music/x.mp3"}}).error["code"] == "invalid_argument");
    CHECK(p.call("music.preview", {{"path", kSong}, {"out", "elsewhere/x.wav"}}).error["code"] == "invalid_argument");
    CHECK(p.call("music.preview", {{"path", kSong}, {"sampleRate", 12345}}).ok == false);
    CHECK(p.call("music.preview", {{"path", kSong}, {"seed", -1}}).ok == false);
    CHECK(p.call("music.preview", {}).ok == false);

    // a file this command did not make is not replaced
    write_all(p.file("assets/music/mine.wav"), "mine");
    CommandResult exists = p.call("music.preview", {{"path", kSong}, {"out", "assets/music/mine.wav"}, {"picture", false}});
    REQUIRE_FALSE(exists.ok);
    CHECK(exists.error["code"] == "exists");
    CHECK(read_all(p.file("assets/music/mine.wav")) == "mine");
    p.ok("music.preview", {{"path", kSong}, {"out", "assets/music/mine.wav"}, {"overwrite", true}, {"sampleRate", 22050}, {"picture", false}});
    CHECK(read_all(p.file("assets/music/mine.wav")).substr(0, 4) == "RIFF");
}

TEST_CASE("music.preview: a project patch is the instrument, and it is an input of the recipe") {
    AssetsProject p;
    make_song(p, {{"arpeggio", false}});
    p.ok("music.instrument", {{"name", "pluck"}, {"path", "assets/audio/my_pluck.sfx.json"}});
    CHECK(p.exists("assets/audio/my_pluck.sfx.json"));
    edit(p, Json::array({{{"op", "set_track"}, {"track", "pad"}, {"instrument", "assets/audio/my_pluck.sfx.json"}}}));
    p.ok("music.preview", {{"path", kSong}, {"sampleRate", 22050}, {"picture", false}});
    const Json recipe = p.manifest()["assets"]["assets/music/theme.preview.wav"]["provenance"]["recipe"];
    bool sawPatch = false;
    for (const Json& in : recipe["inputs"]) sawPatch = sawPatch || in["path"] == "assets/audio/my_pluck.sfx.json";
    CHECK(sawPatch);
    CHECK(p.ok("music.info", {{"path", kSong}, {"picture", false}})["preview"]["stale"] == false);
    write_all(p.file("assets/audio/my_pluck.sfx.json"), read_all(p.file("assets/audio/my_pluck.sfx.json")) + " ");
    CHECK(p.ok("music.info", {{"path", kSong}, {"picture", false}})["preview"]["stale"] == true);
}

TEST_CASE("music.edit: tracks, patterns, sections, arrangement, mutes and automation, and a bad edit writes nothing") {
    AssetsProject p;
    make_song(p);
    const Json r = edit(p, Json::array({{{"op", "set_song"}, {"tempo", 100}, {"swing", 0.2}},
                                        {{"op", "add_track"}, {"track", "lead"}, {"instrument", "flute"}, {"volume", 0.5}, {"patterns", {{"tune", "A4:4 C5 E5 r | A4:2 G4"}}}, {"play", {{"loop", "tune*2"}}}},
                                        {{"op", "set_pattern"}, {"track", "lead"}, {"pattern", "b"}, {"notes", "E5:2 D5 | C5:1"}, {"play", {{"outro", "b"}}}},
                                        {{"op", "mute"}, {"section", "intro"}, {"tracks", Json::array({"arp", "pad"})}},
                                        {{"op", "mute"}, {"section", "intro"}, {"tracks", Json::array({"pad"})}, {"muted", false}},
                                        {{"op", "set_automation"}, {"track", "pad"}, {"param", "volume"}, {"points", Json::array({Json::array({0, 0.2}), Json::array({16, 1})})}},
                                        {{"op", "set_automation"}, {"param", "filter"}, {"points", Json::array({Json::array({0, 800})})}, {"curve", "step"}},
                                        {{"op", "add_section"}, {"section", "bridge"}, {"kind", "section"}, {"index", 3}, {"play", {{"pad", "chords"}}}},
                                        {{"op", "arrange"}, {"section", "bridge"}, {"track", "bass"}, {"entries", "line rest"}},
                                        {{"op", "move_section"}, {"section", "bridge"}, {"index", 1}},
                                        {{"op", "set_section"}, {"section", "loop"}, {"repeat", 3}, {"play", {{"drums", nullptr}}}}}));
    CHECK(r["edits"].size() == 11);
    CHECK(r["tempo"] == 100.0);
    CHECK(r["structure"].get<std::string>().rfind("bridge", 0) == 0);
    const Json doc = song_file(p);
    CHECK(doc["swing"] == 0.2);
    CHECK(doc["tracks"]["lead"]["patterns"].contains("b"));
    CHECK(doc["sections"][1]["mute"] == Json::array({"arp"}));
    CHECK(doc["tracks"]["pad"]["automation"][0]["param"] == "volume");
    CHECK(doc["automation"][0]["curve"] == "step");
    CHECK_FALSE(doc["sections"][2]["play"].contains("drums"));
    CHECK(doc["sections"][2]["repeat"] == 3);

    // lanes removed with no points
    const Json cleared = edit(p, Json::array({{{"op", "set_automation"}, {"track", "pad"}, {"param", "volume"}}}));
    CHECK_FALSE(song_file(p)["tracks"]["pad"].contains("automation"));
    (void)cleared;

    // rename a track and a section; remove a pattern, a section, a track: nothing keeps pointing at them
    edit(p, Json::array({{{"op", "set_track"}, {"track", "lead"}, {"name", "melody"}}, {{"op", "set_section"}, {"section", "bridge"}, {"name", "break"}}}));
    Json doc2 = song_file(p);
    CHECK(doc2["tracks"].contains("melody"));
    CHECK_FALSE(doc2["tracks"].contains("lead"));
    CHECK(doc2["sections"][1]["play"].contains("melody") == false);  // melody plays in loop, not in the section at 1
    bool melodyInLoop = false;
    for (const Json& s : doc2["sections"]) melodyInLoop = melodyInLoop || (s["name"] == "loop" && s["play"].contains("melody"));
    CHECK(melodyInLoop);
    edit(p, Json::array({{{"op", "remove_pattern"}, {"track", "melody"}, {"pattern", "b"}}}));
    for (const Json& s : song_file(p)["sections"])
        if (s["name"] == "outro") CHECK_FALSE(s["play"].contains("melody"));
    edit(p, Json::array({{{"op", "remove_track"}, {"track", "melody"}}, {{"op", "remove_section"}, {"section", "break"}}}));
    CHECK_FALSE(song_file(p)["tracks"].contains("melody"));
    CHECK(song_file(p)["sections"].size() == 3);

    // an op the song would not survive: nothing is written
    const std::string before = read_all(p.file(kSong));
    CommandResult bad = p.call("music.edit", {{"path", kSong}, {"ops", Json::array({{{"op", "set_song"}, {"tempo", 90}}, {{"op", "set_pattern"}, {"track", "bass"}, {"pattern", "line"}, {"notes", "A1:4 E2 Q9"}}})}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["code"] == "invalid_song");
    CHECK(bad.error["message"].get<std::string>().find("Nothing was written") != std::string::npos);
    CHECK(read_all(p.file(kSong)) == before);
}

TEST_CASE("music.edit: errors name the operation, the field and a fix") {
    AssetsProject p;
    make_song(p);
    auto fails = [&](const Json& op, const std::string& needle) {
        CommandResult r = p.call("music.edit", {{"path", kSong}, {"ops", Json::array({op})}});
        REQUIRE_FALSE(r.ok);
        const std::string text = r.error["message"].get<std::string>() + " " + r.error["hint"].get<std::string>();
        INFO(text);
        CHECK(text.find(needle) != std::string::npos);
    };
    fails({{"op", "set_pattrn"}}, "set_pattern");                                                                    // did you mean
    fails({{"op", "mute"}, {"section", "intr"}, {"tracks", Json::array({"drums"})}}, "intro");                       // unknown section
    fails({{"op", "mute"}, {"section", "intro"}, {"tracks", Json::array({"drum"})}}, "drums");                       // unknown track
    fails({{"op", "set_pattern"}, {"track", "bass"}, {"pattern", "x"}}, "exactly one of `notes`");                  // neither notes nor grid
    fails({{"op", "set_pattern"}, {"track", "bass"}, {"pattern", "x"}, {"notes", "A1"}, {"grid", Json::object()}}, "exactly one");
    fails({{"op", "set_pattern"}, {"track", "bass"}, {"pattern", "x"}, {"notez", "A1"}}, "notes");                  // unknown field
    fails({{"op", "add_track"}, {"track", "bass"}, {"instrument", "bass"}}, "set_track");                           // exists
    fails({{"op", "add_track"}, {"track", "new"}}, "instrument");
    fails({{"op", "remove_pattern"}, {"track", "bass"}, {"pattern", "line"}}, "only pattern");
    fails({{"op", "remove_pattern"}, {"track", "bass"}, {"pattern", "lin"}}, "Patterns");
    fails({{"op", "add_section"}, {"section", "loop"}}, "exists");
    fails({{"op", "add_section"}, {"section", "x"}, {"index", 9}}, "1 to 4");
    fails({{"op", "move_section"}, {"section", "loop"}, {"index", 0}}, "1 to 3");
    fails({{"op", "set_track"}, {"track", "pad"}, {"name", "bass"}}, "exists");
    fails({{"op", "set_track"}, {"track", "pad"}, {"instrument", nullptr}}, "instrument");
    fails({{"op", "set_track"}, {"track", "pad"}}, "nothing to change");
    fails({{"op", "set_song"}}, "nothing to set");
    fails({{"op", "arrange"}, {"section", "loop"}, {"track", "pad"}}, "entries");
    fails({{"op", "set_automation"}, {"track", "nobody"}, {"param", "volume"}}, "Tracks");
    CHECK(p.call("music.edit", {{"path", kSong}, {"ops", Json::array()}}).ok == false);
    CHECK(p.call("music.edit", {{"path", kSong}}).ok == false);
    CHECK(p.call("music.edit", {{"path", kSong}, {"ops", Json::array({"mute"})}}).ok == false);
    // an arrangement that names a pattern that does not exist is the parser's error, with its pointer
    CommandResult arr = p.call("music.edit", {{"path", kSong}, {"ops", Json::array({{{"op", "arrange"}, {"section", "loop"}, {"track", "bass"}, {"entries", "lien"}}})}});
    REQUIRE_FALSE(arr.ok);
    CHECK(arr.error["code"] == "invalid_song");
    CHECK(arr.error["data"]["issues"][0]["hint"].get<std::string>().find("line") != std::string::npos);
}

TEST_CASE("music.edit: a drum pattern by grid and a section arrangement by list") {
    AssetsProject p;
    make_song(p);
    edit(p, Json::array({{{"op", "set_pattern"}, {"track", "drums"}, {"pattern", "half"}, {"grid", {{"kick", "x......."}, {"snare", "....x..."}}}, {"step", "8"}, {"bars", 1}},
                         {{"op", "arrange"}, {"section", "loop"}, {"track", "drums"}, {"entries", Json::array({"groove", {{"pattern", "half"}, {"repeat", 2}}})}}}));
    const Json info = p.ok("music.info", {{"path", kSong}, {"picture", false}});
    bool sawHalf = false;
    for (const Json& s : info["sections"])
        if (s["name"] == "loop") sawHalf = s["play"]["drums"] == "groove half*2";
    CHECK(sawHalf);
    // removing it takes it out of the list in the arrangement
    edit(p, Json::array({{{"op", "remove_pattern"}, {"track", "drums"}, {"pattern", "half"}}}));
    for (const Json& s : song_file(p)["sections"])
        if (s["name"] == "loop") CHECK(s["play"]["drums"] == "groove");
}

TEST_CASE("music.instrument, music.chord, music.scale: lists, detail and errors") {
    AssetsProject p;
    const Json list = p.ok("music.instrument", {});
    CHECK(list["instruments"].size() >= 8);
    CHECK(list["kitLanes"].size() >= 4);
    CHECK(list["sfxPresets"].is_array());
    const Json patch = p.ok("music.instrument", {{"name", "kick"}});
    CHECK(patch["name"] == "kit:kick");
    CHECK(patch["patch"]["format"] == "factoria.sfx/1");
    CHECK(p.call("music.instrument", {{"name", "plucc"}}).error["hint"].get<std::string>().find("pluck") != std::string::npos);
    CHECK(p.call("music.instrument", {{"name", "pluck"}, {"path", "assets/x.json"}}).error["code"] == "invalid_argument");
    p.ok("music.instrument", {{"name", "pluck"}, {"path", "assets/audio/p.sfx.json"}});
    CHECK(p.call("music.instrument", {{"name", "pluck"}, {"path", "assets/audio/p.sfx.json"}}).error["code"] == "exists");
    p.ok("music.instrument", {{"name", "pluck"}, {"path", "assets/audio/p.sfx.json"}, {"overwrite", true}});

    const Json chord = p.ok("music.chord", {{"name", "Am7"}, {"octave", 3}});
    CHECK(chord["midi"] == Json::array({57, 60, 64, 67}));
    CHECK(chord["byName"] == "(Am7@3)");
    CHECK(chord["asNotes"] == "[A3 C4 E4 G4]");
    const Json prog = p.ok("music.chord", {{"progression", "i VI III VII"}, {"key", "A"}, {"mode", "minor"}});
    CHECK(prog["progression"] == "Am F C G");
    CHECK(prog["chords"].size() == 4);
    CHECK(prog["pad"].get<std::string>().find("(Am@3)") != std::string::npos);
    CHECK(p.ok("music.chord", {})["qualities"].size() > 10);
    CHECK(p.call("music.chord", {{"name", "Am7x"}}).ok == false);
    CHECK(p.call("music.chord", {{"name", "Am"}, {"progression", "C"}}).error["code"] == "invalid_argument");
    CHECK(p.call("music.chord", {{"progression", "Am Qq"}}).ok == false);

    const Json scale = p.ok("music.scale", {{"key", "D"}, {"mode", "dorian"}});
    CHECK(scale["notes"] == Json::array({"D", "E", "F", "G", "A", "B", "C"}));
    CHECK(scale["triads"][0]["roman"] == "i");
    CHECK(scale["triads"][3]["chord"] == "G");
    CHECK(scale["sevenths"].size() == 7);
    CHECK(p.ok("music.scale", {})["scales"].size() >= 7);
    CHECK(p.call("music.scale", {{"key", "D"}, {"mode", "dorien"}}).error["hint"].get<std::string>().find("dorian") != std::string::npos);
    CHECK(p.call("music.scale", {{"key", "Z"}}).ok == false);
}

TEST_CASE("music.arpeggio, music.bassline, music.drums: text for a pattern, or written into a song and played in a section") {
    AssetsProject p;
    make_song(p, {{"arpeggio", false}});
    const Json arp = p.ok("music.arpeggio", {{"progression", "Am F C G"}, {"direction", "down"}, {"octaves", 2}, {"rate", 8}});
    CHECK(arp["bars"] == 4);
    CHECK(arp["notes"].get<std::string>().find('|') != std::string::npos);
    CHECK(p.call("music.arpeggio", {{"progression", "Am F"}, {"direction", "sideways"}}).ok == false);
    CHECK(p.call("music.arpeggio", {{"progression", "Am F"}, {"octaves", 9}}).ok == false);
    CHECK(p.call("music.arpeggio", {}).ok == false);

    const Json wrote = p.ok("music.arpeggio", {{"progression", "i VI III VII"}, {"path", kSong}, {"section", "loop"}, {"picture", false}});
    CHECK(wrote["edits"].size() == 2);
    CHECK(wrote["notes"].is_string());
    CHECK(song_file(p)["tracks"]["arp"]["instrument"] == "pluck");
    CHECK(song_file(p)["sections"][1]["play"]["arp"] == "arp");

    const Json bass = p.ok("music.bassline", {{"progression", "Am F C G"}, {"style", "walking"}, {"path", kSong}, {"track", "bass"}, {"pattern", "walk"}, {"section", "outro"}, {"picture", false}});
    CHECK(bass["edits"][0] == "added pattern bass/walk");
    CHECK(song_file(p)["sections"][2]["play"]["bass"] == "line walk");
    CHECK(p.call("music.bassline", {{"progression", "Am F"}, {"style", "wlking"}}).error["hint"].get<std::string>().find("walking") != std::string::npos);

    const Json drums = p.ok("music.drums", {{"style", "funk"}, {"bars", 2}, {"fill", true}});
    CHECK(drums["pattern"]["grid"].contains("kick"));
    CHECK(p.ok("music.drums", {})["styles"].size() >= 3);
    const Json put = p.ok("music.drums", {{"style", "rock"}, {"bars", 4}, {"path", kSong}, {"pattern", "rock2"}, {"section", "intro"}, {"picture", false}});
    CHECK(put["edits"].size() == 2);
    CHECK(song_file(p)["sections"][0]["play"]["drums"] == "rock2");
    CHECK(p.call("music.drums", {{"style", "rok"}}).error["hint"].get<std::string>().find("rock") != std::string::npos);
    CHECK(p.call("music.drums", {{"style", "rock"}, {"meter", "3/4"}}).ok == false);  // a 4/4 style does not fit 3/4
    CHECK(p.call("music.drums", {{"style", "rock"}, {"path", kSong}, {"section", "nowhere"}}).ok == false);

    // a pattern that does not fit the song is the parser's error, and the song is unchanged
    const std::string before = read_all(p.file(kSong));
    CHECK(p.call("music.arpeggio", {{"progression", "Am F"}, {"path", kSong}, {"track", "drums"}}).ok == false);
    CHECK(read_all(p.file(kSong)) == before);
}

TEST_CASE("project.validate: a broken song is an error with its pointer and column, a missing instrument file is an error, findings are warnings") {
    AssetsProject p;  // a real project (factoria.json, a scene) so only the songs can be wrong
    REQUIRE(create_project(p.dir, "2d-empty").ok());
    make_song(p);
    CHECK(validate_project(p.dir).errors.empty());

    Json bad = song_file(p);
    bad["tracks"]["bass"]["patterns"]["line"] = "A1:4 E2 Q9 A1";
    write_all(p.file("assets/music/bad.song.json"), dump_json(bad));
    bool sawError = false;
    for (const ValidationIssue& e : validate_project(p.dir).errors)
        if (e.file == "assets/music/bad.song.json" && e.pointer == "/tracks/bass/patterns/line") sawError = e.message.find("line 1, column 9") != std::string::npos && e.message.find("Q9") != std::string::npos;
    CHECK(sawError);
    std::filesystem::remove(p.file("assets/music/bad.song.json"));

    Json missing = song_file(p);
    missing["tracks"]["pad"]["instrument"] = "assets/audio/nope.sfx.json";
    write_all(p.file("assets/music/missing.song.json"), dump_json(missing));
    bool sawMissing = false;
    for (const ValidationIssue& e : validate_project(p.dir).errors)
        if (e.file == "assets/music/missing.song.json" && e.pointer == "/tracks/pad/instrument") sawMissing = e.message.find("nope.sfx.json") != std::string::npos;
    CHECK(sawMissing);
    write_all(p.file("assets/audio/nope.sfx.json"), R"({"format": "factoria.sfx/1", "layers": []})");
    bool sawInvalid = false;
    for (const ValidationIssue& e : validate_project(p.dir).errors)
        if (e.file == "assets/music/missing.song.json") sawInvalid = sawInvalid || e.message.find("not a valid sound patch") != std::string::npos;
    CHECK(sawInvalid);
    std::filesystem::remove(p.file("assets/music/missing.song.json"));

    // a note outside the key is a warning, not an error
    edit(p, Json::array({{{"op", "set_pattern"}, {"track", "bass"}, {"pattern", "line"}, {"notes", "A1:4 C#2 A1 E2 | F2:4 C3 F2 C3 | C2:4 G2 C2 G2 | G1:4 D2 G1 D2"}}}));
    const ValidationReport report = validate_project(p.dir);
    CHECK(report.errors.empty());
    bool sawWarning = false;
    for (const ValidationIssue& w : report.warnings)
        if (w.file == kSong && w.message.find("off_key") != std::string::npos) sawWarning = w.pointer == "/tracks/bass/patterns/line" && !w.hint.empty();
    CHECK(sawWarning);
}
