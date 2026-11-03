// music.render (the whole song as a game asset: loop points, stems, recipe and staleness), music.import_midi, music.export_midi and the .mid
// route of assets.import. The renderer, the stems and the MIDI converters are tested in fa_audio (engine/audio/tests/test_song_render.cpp,
// test_midi.cpp); here: the files, assets.json, the recipe and what makes a render stale.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <set>

#include "../../../engine/audio/tests/tiny_sf2.h"
#include "asset_test_helpers.h"
#include "fa/tooling/validate.h"

using namespace fa;
using namespace fa::testing;

namespace {

const char* kSong = "assets/music/theme.song.json";
const char* kWav = "assets/music/theme.wav";

Json make_song(const AssetsProject& p) { return p.ok("music.create", {{"path", kSong}, {"picture", false}, {"arpeggio", false}}); }
Json edit(const AssetsProject& p, const Json& ops) { return p.ok("music.edit", {{"path", kSong}, {"ops", ops}}); }

std::uint32_t u32(const std::string& b, std::size_t at) {
    return std::uint32_t(std::uint8_t(b[at])) | std::uint32_t(std::uint8_t(b[at + 1])) << 8 | std::uint32_t(std::uint8_t(b[at + 2])) << 16 | std::uint32_t(std::uint8_t(b[at + 3])) << 24;
}

struct Wav {
    int channels = 0, rate = 0;
    std::vector<std::int16_t> samples;
    bool hasLoop = false;
    std::uint32_t loopStart = 0, loopEnd = 0;  // frames; end inclusive as in the file
    std::size_t frames() const { return channels ? samples.size() / std::size_t(channels) : 0; }
};

Wav read_wav(const std::string& bytes) {
    Wav w;
    REQUIRE(bytes.size() > 44);
    REQUIRE(bytes.substr(0, 4) == "RIFF");
    std::size_t at = 12;
    while (at + 8 <= bytes.size()) {
        const std::string tag = bytes.substr(at, 4);
        const std::uint32_t size = u32(bytes, at + 4);
        if (tag == "fmt ") {
            w.channels = std::uint8_t(bytes[at + 10]);
            w.rate = int(u32(bytes, at + 12));
        } else if (tag == "data") {
            w.samples.resize(size / 2);
            std::memcpy(w.samples.data(), bytes.data() + at + 8, size);
        } else if (tag == "smpl") {
            w.hasLoop = true;
            w.loopStart = u32(bytes, at + 8 + 36 + 8);
            w.loopEnd = u32(bytes, at + 8 + 36 + 12);
        }
        at += 8 + size + (size & 1);
    }
    return w;
}

void write_sf2(const AssetsProject& p, const std::string& rel) {
    const std::vector<std::uint8_t> bytes = fa::testing::tiny_sf2();
    write_all(p.file(rel), std::string(bytes.begin(), bytes.end()));
}

Json entry(const AssetsProject& p, const std::string& rel) { return p.manifest()["assets"][rel]; }

// The dry run of assets.regenerate for one asset: is it stale, and which inputs changed.
Json dry(const AssetsProject& p, const std::string& rel) {
    const Json r = p.ok("assets.regenerate", {{"path", rel}, {"dryRun", true}});
    REQUIRE(r["wouldRun"].size() == 1);
    return r["wouldRun"][0];
}

bool changed_has(const Json& d, const std::string& text) {
    if (!d.contains("changedInputs")) return false;
    for (const Json& c : d["changedInputs"])
        if (c.get<std::string>().find(text) != std::string::npos) return true;
    return false;
}

void set_style_music(const AssetsProject& p, const Json& lufs) {
    Json m = p.manifest();
    if (lufs.is_null()) m.erase("style");
    else m["style"] = Json::object({{"audio", Json::object({{"loudnessLufs", Json::object({{"music", lufs}})}})}});
    write_all(p.file("assets.json"), m.dump(2) + "\n");
}

}  // namespace

TEST_CASE("music.render: the whole song as a WAV whose loop points are the loop section's bars, in assets.json and the smpl chunk") {
    AssetsProject p;
    make_song(p);  // intro 4 bars > loop 4 bars x2 > outro 4 bars
    const Json r = p.ok("music.render", {{"path", kSong}, {"sampleRate", 22050}});
    CHECK(r["path"] == kWav);
    CHECK(r["sampleRate"] == 22050);
    REQUIRE(r.contains("loop"));
    CHECK(r["loop"]["startBar"] == 5);
    CHECK(r["loop"]["bars"] == 8);  // the loop section, both of its repeats

    const Wav w = read_wav(read_all(p.file(kWav)));
    CHECK(w.channels == 2);
    CHECK(w.rate == 22050);
    CHECK(w.frames() == r["frames"].get<std::size_t>());
    const double tempo = p.ok("music.info", {{"path", kSong}, {"picture", false}})["tempo"].get<double>();
    const double barFrames = 4.0 * 60.0 / tempo * 22050.0;  // 4/4
    CHECK(double(r["loop"]["startFrame"].get<std::size_t>()) == doctest::Approx(4.0 * barFrames).epsilon(1.0 / (4.0 * barFrames)));
    CHECK(double(r["loop"]["endFrame"].get<std::size_t>()) == doctest::Approx(12.0 * barFrames).epsilon(1.0 / (12.0 * barFrames)));
    REQUIRE(w.hasLoop);
    CHECK(w.loopStart == r["loop"]["startFrame"].get<std::uint32_t>());
    CHECK(w.loopEnd + 1 == r["loop"]["endFrame"].get<std::uint32_t>());

    const Json e = entry(p, kWav);
    CHECK(std::llround(e["import"]["loopStart"].get<double>() * 22050.0) == w.loopStart);
    CHECK(std::llround(e["import"]["loopEnd"].get<double>() * 22050.0) == w.loopEnd + 1);
    CHECK(e["import"]["music"]["role"] == "mix");
    CHECK(e["provenance"]["provider"] == "factoria music.render");
    CHECK(e["provenance"]["recipe"]["command"] == "music.render");
    CHECK(e["provenance"]["recipe"]["args"]["out"] == kWav);
    CHECK(e["provenance"]["recipe"]["inputs"][0]["path"] == kSong);

    // again: same bytes, updated in place, and a license a person wrote stays
    const std::string bytes = read_all(p.file(kWav));
    Json m = p.manifest();
    m["assets"][kWav]["provenance"]["license"] = "CC-BY-4.0";
    write_all(p.file("assets.json"), m.dump(2) + "\n");
    p.ok("music.render", {{"path", kSong}, {"sampleRate", 22050}});
    CHECK(read_all(p.file(kWav)) == bytes);
    CHECK(entry(p, kWav)["provenance"]["license"] == "CC-BY-4.0");

    // no loop: no points, anywhere
    const Json once = p.ok("music.render", {{"path", kSong}, {"sampleRate", 22050}, {"loop", false}, {"out", "assets/music/once.wav"}});
    CHECK_FALSE(once.contains("loop"));
    CHECK_FALSE(read_wav(read_all(p.file("assets/music/once.wav"))).hasLoop);
    CHECK_FALSE(entry(p, "assets/music/once.wav")["import"].contains("loopStart"));
}

TEST_CASE("music.render: ogg keeps the loop points in assets.json only, and the errors say what to do") {
    AssetsProject p;
    make_song(p);
    const Json r = p.ok("music.render", {{"path", kSong}, {"sampleRate", 22050}, {"format", "ogg"}});
    CHECK(r["path"] == "assets/music/theme.ogg");
    CHECK(read_all(p.file("assets/music/theme.ogg")).substr(0, 4) == "OggS");
    const Json e = entry(p, "assets/music/theme.ogg");
    CHECK(e["import"].contains("loopStart"));
    CHECK(e["import"]["loopEnd"].get<double>() > e["import"]["loopStart"].get<double>());

    CHECK(p.call("music.render", {{"path", kSong}, {"format", "mp3"}}).ok == false);
    CHECK(p.call("music.render", {{"path", kSong}, {"format", "ogg"}, {"out", "assets/music/x.wav"}}).error["code"] == "invalid_argument");
    CHECK(p.call("music.render", {{"path", kSong}, {"out", "elsewhere/x.wav"}}).error["code"] == "invalid_argument");
    CHECK(p.call("music.render", {{"path", kSong}, {"sampleRate", 12345}}).ok == false);
    CHECK(p.call("music.render", {}).ok == false);
    write_all(p.file("assets/music/mine.wav"), "mine");
    CHECK(p.call("music.render", {{"path", kSong}, {"out", "assets/music/mine.wav"}}).error["code"] == "exists");
    CHECK(read_all(p.file("assets/music/mine.wav")) == "mine");
    // a song with no layers cannot give layer stems, and the error says how to
    CommandResult none = p.call("music.render", {{"path", kSong}, {"stems", "layers"}});
    REQUIRE_FALSE(none.ok);
    CHECK(none.error["hint"].get<std::string>().find("set_layers") != std::string::npos);
    CHECK(p.call("music.render", {{"path", kSong}, {"stems", "everything"}}).ok == false);
}

TEST_CASE("music.render: one stem per layer, same length and loop points, adding up to the mix; one recipe for all") {
    AssetsProject p;
    make_song(p);
    edit(p, Json::array({{{"op", "set_layers"}, {"layers", {{"rhythm", Json::array({"drums", "bass"})}, {"harmony", {{"tracks", Json::array({"pad"})}, {"intensity", 0.6}}}}}}}));
    const Json info = p.ok("music.info", {{"path", kSong}, {"picture", false}});
    REQUIRE(info["layers"].size() == 2);
    CHECK(info["layers"][1]["intensity"] == 0.6);

    const Json r = p.ok("music.render", {{"path", kSong}, {"sampleRate", 22050}, {"stems", "layers"}});
    REQUIRE(r["stems"].size() == 2);
    CHECK(r["stems"][0]["path"] == "assets/music/theme.stem.rhythm.wav");
    CHECK(r["stems"][0]["kind"] == "layer");
    CHECK(r["stemSum"]["exact"] == true);
    CHECK(r["stemSum"]["errorDb"].get<double>() < -80.0);

    const Wav mix = read_wav(read_all(p.file(kWav)));
    std::vector<std::int64_t> sum(mix.samples.size(), 0);
    for (const Json& s : r["stems"]) {
        const Wav w = read_wav(read_all(p.file(s["path"].get<std::string>())));
        REQUIRE(w.samples.size() == mix.samples.size());
        CHECK(w.rate == mix.rate);
        CHECK(w.hasLoop);
        CHECK(w.loopStart == mix.loopStart);
        CHECK(w.loopEnd == mix.loopEnd);
        for (std::size_t i = 0; i < sum.size(); ++i) sum[i] += w.samples[i];
    }
    std::int64_t worst = 0;
    for (std::size_t i = 0; i < sum.size(); ++i) worst = std::max<std::int64_t>(worst, std::llabs(sum[i] - mix.samples[i]));
    CHECK(worst <= 3);  // each file is rounded to 16 bits on its own: at most one step per stem and one for the mix

    // assets.json: every file says what it is, and all share the recipe, so the regenerate group runs once
    const Json mixEntry = entry(p, kWav);
    CHECK(mixEntry["import"]["music"]["stemGrouping"] == "layers");
    REQUIRE(mixEntry["import"]["music"]["stems"].size() == 2);
    const Json stemEntry = entry(p, "assets/music/theme.stem.harmony.wav");
    CHECK(stemEntry["import"]["music"]["role"] == "stem");
    CHECK(stemEntry["import"]["music"]["mix"] == kWav);
    CHECK(stemEntry["import"]["music"]["intensity"] == 0.6);
    CHECK(stemEntry["import"]["music"]["tracks"] == Json::array({"pad"}));
    CHECK(stemEntry["provenance"]["recipe"] == mixEntry["provenance"]["recipe"]);
    const Json all = p.ok("assets.regenerate", {{"all", true}});
    CHECK(all["count"] == 1);
    CHECK(all["regenerated"][0]["outputs"].size() == 3);

    // fewer layers: the stem of the layer that went is deleted
    edit(p, Json::array({{{"op", "set_layers"}, {"layers", {{"harmony", nullptr}}}}}));
    const Json again = p.ok("music.render", {{"path", kSong}, {"sampleRate", 22050}, {"stems", "layers"}});
    CHECK(again["stems"].size() == 2);  // rhythm and the rest, "other" (pad)
    CHECK(again["stems"][1]["name"] == "other");
    CHECK(again.contains("removedStems"));
    CHECK_FALSE(p.exists("assets/music/theme.stem.harmony.wav"));
    CHECK_FALSE(p.manifest()["assets"].contains("assets/music/theme.stem.harmony.wav"));

    // tracks and buses
    CHECK(p.ok("music.render", {{"path", kSong}, {"sampleRate", 22050}, {"stems", "tracks"}, {"out", "assets/music/t.wav"}})["stems"].size() == 3);
}

TEST_CASE("music.edit set_layers: it follows a renamed or removed track, and bad layers name the fix") {
    AssetsProject p;
    make_song(p);
    edit(p, Json::array({{{"op", "set_layers"}, {"layers", {{"rhythm", Json::array({"drums", "bass"})}}}}}));
    edit(p, Json::array({{{"op", "set_track"}, {"track", "bass"}, {"name", "low"}}}));
    CHECK(parse_json(read_all(p.file(kSong)), kSong).value()["layers"]["rhythm"] == Json::array({"drums", "low"}));
    edit(p, Json::array({{{"op", "remove_track"}, {"track", "low"}}}));
    CHECK(parse_json(read_all(p.file(kSong)), kSong).value()["layers"]["rhythm"] == Json::array({"drums"}));
    edit(p, Json::array({{{"op", "remove_track"}, {"track", "drums"}}}));
    CHECK_FALSE(parse_json(read_all(p.file(kSong)), kSong).value().contains("layers"));

    CommandResult bad = p.call("music.edit", {{"path", kSong}, {"ops", Json::array({{{"op", "set_layers"}, {"layers", {{"x", Json::array({"pda"})}}}}})}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("pad") != std::string::npos);  // did you mean
    CHECK(p.call("music.edit", {{"path", kSong}, {"ops", Json::array({{{"op", "set_layers"}, {"layers", {{"other", Json::array({"pad"})}}}}})}}).ok == false);
    CHECK(p.call("music.edit", {{"path", kSong}, {"ops", Json::array({{{"op", "set_layers"}, {"layers", {{"nope", nullptr}}}}})}}).ok == false);
}

TEST_CASE("music.render: stale when the song, a sound patch, a SoundFont or the style's music loudness changes; regenerate makes it fresh") {
    AssetsProject p;
    make_song(p);
    p.ok("music.instrument", {{"name", "pluck"}, {"path", "assets/audio/my_pluck.sfx.json"}});
    write_sf2(p, "assets/audio/tiny.sf2");
    edit(p, Json::array({{{"op", "set_track"}, {"track", "pad"}, {"instrument", "assets/audio/my_pluck.sfx.json"}},
                         {{"op", "set_track"}, {"track", "bass"}, {"instrument", {{"soundfont", "assets/audio/tiny.sf2"}, {"preset", "Test Sine"}}}}}));
    p.ok("music.render", {{"path", kSong}, {"sampleRate", 22050}});
    p.ok("music.preview", {{"path", kSong}, {"sampleRate", 22050}, {"picture", false}});
    const Json recipe = entry(p, kWav)["provenance"]["recipe"];
    std::set<std::string> inputs;
    for (const Json& in : recipe["inputs"]) inputs.insert(in["path"].get<std::string>());
    INFO(recipe["inputs"].dump());
    CHECK(inputs == std::set<std::string>{kSong, "assets/audio/my_pluck.sfx.json", "assets/audio/tiny.sf2"});
    CHECK(recipe["context"]["styleMusicLufs"].is_null());
    CHECK(dry(p, kWav)["stale"] == false);

    // a project .sfx.json
    const std::string patch = read_all(p.file("assets/audio/my_pluck.sfx.json"));
    write_all(p.file("assets/audio/my_pluck.sfx.json"), patch + " ");
    Json d = dry(p, kWav);
    CHECK(d["stale"] == true);
    CHECK(changed_has(d, "my_pluck.sfx.json"));
    write_all(p.file("assets/audio/my_pluck.sfx.json"), patch);
    CHECK(dry(p, kWav)["stale"] == false);

    // a SoundFont
    const std::string sf2 = read_all(p.file("assets/audio/tiny.sf2"));
    write_all(p.file("assets/audio/tiny.sf2"), sf2 + std::string(4, '\0'));
    d = dry(p, kWav);
    CHECK(d["stale"] == true);
    CHECK(changed_has(d, "tiny.sf2"));
    write_all(p.file("assets/audio/tiny.sf2"), sf2);
    CHECK(dry(p, kWav)["stale"] == false);

    // the style guide's music loudness: the render and the preview were made with none; now it asks -20
    set_style_music(p, -20);
    d = dry(p, kWav);
    CHECK(d["stale"] == true);
    CHECK(changed_has(d, "style.audio.loudnessLufs.music"));
    CHECK(dry(p, "assets/music/theme.preview.wav")["stale"] == true);
    bool warned = false;
    for (const ValidationIssue& w : validate_project(p.dir).warnings) warned = warned || w.message.find("'assets/music/theme.wav' is stale") != std::string::npos;
    CHECK(warned);
    const std::string before = read_all(p.file(kWav));
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 2);
    CHECK(read_all(p.file(kWav)) != before);  // the level follows the style
    CHECK(entry(p, kWav)["provenance"]["recipe"]["context"]["styleMusicLufs"] == -20);
    CHECK(dry(p, kWav)["stale"] == false);
    // the same number again is not a change; another one is
    set_style_music(p, -20);
    CHECK(dry(p, kWav)["stale"] == false);
    set_style_music(p, -14);
    CHECK(dry(p, kWav)["stale"] == true);

    // the song itself
    set_style_music(p, nullptr);
    p.ok("assets.regenerate", {{"stale", true}});
    edit(p, Json::array({{{"op", "set_song"}, {"tempo", 150}}}));
    CHECK(dry(p, kWav)["stale"] == true);
    p.ok("assets.regenerate", {{"stale", true}});
    CHECK(dry(p, kWav)["stale"] == false);

    // a song whose master loudness is a number does not depend on the style guide
    edit(p, Json::array({{{"op", "set_mixer"}, {"master", {{"loudness", -16}}}}}));
    p.ok("music.render", {{"path", kSong}, {"sampleRate", 22050}});
    CHECK_FALSE(entry(p, kWav)["provenance"]["recipe"].contains("context"));
    set_style_music(p, -20);
    CHECK(dry(p, kWav)["stale"] == false);
}

namespace {

// A format-0 file: tempo 120, one note (middle C, velocity 90) lasting one quarter note, 480 ticks per quarter.
std::string tiny_midi() {
    const unsigned char bytes[] = {'M', 'T', 'h', 'd', 0, 0, 0, 6, 0, 0, 0, 1, 0x01, 0xE0, 'M', 'T', 'r', 'k', 0, 0, 0, 20,
                                   0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20, 0x00, 0x90, 0x3C, 0x5A, 0x83, 0x60, 0x80, 0x3C, 0x40, 0x00, 0xFF, 0x2F, 0x00};
    return std::string(reinterpret_cast<const char*>(bytes), sizeof bytes);
}

}  // namespace

TEST_CASE("music.import_midi: a file becomes a valid song, assets.import takes a .mid, and errors name the byte offset") {
    AssetsProject p;
    write_all(p.file("assets/music/tiny.mid"), tiny_midi());
    const Json r = p.ok("music.import_midi", {{"path", "assets/music/tiny.mid"}, {"license", "CC0"}});
    CHECK(r["path"] == "assets/music/tiny.song.json");
    CHECK(r["tempo"] == 120);
    CHECK(r["notes"] == 1);
    CHECK(r["import"]["format"] == 0);
    CHECK(r["import"]["ticksPerQuarter"] == 480);
    CHECK(entry(p, "assets/music/tiny.song.json")["provenance"]["origin"] == "imported");
    CHECK(entry(p, "assets/music/tiny.song.json")["provenance"]["license"] == "CC0");
    p.ok("music.check", {{"path", "assets/music/tiny.song.json"}});
    CHECK(p.ok("music.preview", {{"path", "assets/music/tiny.song.json"}, {"sampleRate", 22050}, {"picture", false}})["notes"] == 1);

    CHECK(p.call("music.import_midi", {{"path", "assets/music/tiny.mid"}}).error["code"] == "exists");
    p.ok("music.import_midi", {{"path", "assets/music/tiny.mid"}, {"overwrite", true}, {"quantize", "16"}, {"out", "assets/music/other.song.json"}});
    CHECK(p.exists("assets/music/other.song.json"));
    CHECK(p.call("music.import_midi", {{"path", "assets/music/tiny.mid"}, {"quantize", "7"}, {"overwrite", true}}).ok == false);
    CHECK(p.call("music.import_midi", {{"path", "assets/music/tiny.png"}}).error["code"] == "invalid_argument");
    CHECK(p.call("music.import_midi", {{"path", "assets/music/missing.mid"}}).error["code"] == "not_found");

    // assets.import routes a .mid here
    const Json imp = p.ok("assets.import", {{"source", "assets/music/tiny.mid"}, {"path", "assets/music/viaimport.song.json"}, {"author", "Ana"}});
    CHECK(imp["importer"] == "midi");
    CHECK(imp["path"] == "assets/music/viaimport.song.json");
    CHECK(entry(p, "assets/music/viaimport.song.json")["provenance"]["author"] == "Ana");

    // a truncated file: the error says where
    write_all(p.file("assets/music/cut.mid"), tiny_midi().substr(0, 30));
    CommandResult cut = p.call("music.import_midi", {{"path", "assets/music/cut.mid"}});
    REQUIRE_FALSE(cut.ok);
    CHECK(cut.error["code"] == "invalid_midi");
    CHECK(cut.error["message"].get<std::string>().find("byte offset") != std::string::npos);
    CHECK_FALSE(p.exists("assets/music/cut.song.json"));
    write_all(p.file("assets/music/text.mid"), "this is not a midi file");
    CommandResult text = p.call("music.import_midi", {{"path", "assets/music/text.mid"}});
    REQUIRE_FALSE(text.ok);
    CHECK(text.error["message"].get<std::string>().find("byte offset 0") != std::string::npos);
}

TEST_CASE("music.export_midi: a format-1 file that music.import_midi reads back as the same song") {
    AssetsProject p;
    make_song(p);
    const Json r = p.ok("music.export_midi", {{"path", kSong}});
    CHECK(r["path"] == "assets/music/theme.mid");
    CHECK(r["format"] == 1);
    const std::string bytes = read_all(p.file("assets/music/theme.mid"));
    CHECK(bytes.substr(0, 4) == "MThd");
    CHECK(std::uint8_t(bytes[9]) == 1);  // format 1
    CHECK(r["tracks"] == 3);

    const Json back = p.ok("music.import_midi", {{"path", "assets/music/theme.mid"}, {"out", "assets/music/back.song.json"}});
    const Json orig = p.ok("music.info", {{"path", kSong}, {"picture", false}});
    CHECK(back["notes"] == orig["notes"]);
    CHECK(back["bars"] == orig["bars"]);
    CHECK(back["tempo"] == orig["tempo"]);
    CHECK(back["key"] == orig["key"]);
    CHECK(back["structure"] == "intro (4 bars) > loop (8 bars) > outro (4 bars)");  // the repeat is notes now
    CHECK(back["tracks"].size() == orig["tracks"].size());

    CHECK(p.call("music.export_midi", {{"path", kSong}}).error["code"] == "exists");
    CHECK(p.call("music.export_midi", {{"path", kSong}, {"out", "assets/music/x.wav"}}).error["code"] == "invalid_argument");
    p.ok("music.export_midi", {{"path", kSong}, {"overwrite", true}});
}
