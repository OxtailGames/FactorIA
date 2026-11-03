// sfx.render, sfx.bake, sfx.preset and sfx.info: sound patches as project files (docs/SOUND.md). The synthesizer itself is tested in
// fa_audio (engine/audio/tests/test_sfx.cpp); here: the files, the recipe, staleness, the errors and that assets.synth_sound still works.
#include <doctest.h>

#include "asset_test_helpers.h"
#include "fa/audio/analysis.h"
#include <set>

#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"

using namespace fa;
using namespace fa::testing;

namespace {

const char* kBlip = R"({"format": "factoria.sfx/1", "doc": "test blip", "length": 0.15, "layers": [
    {"oscillators": [{"wave": "square", "duty": 0.25}], "pitch": {"note": "A4"}, "amp": {"attack": 0.002, "decay": 0.1, "sustain": 0}}]})";
const char* kBlipLower = R"({"format": "factoria.sfx/1", "doc": "test blip", "length": 0.15, "layers": [
    {"oscillators": [{"wave": "square", "duty": 0.25}], "pitch": {"note": "A3"}, "amp": {"attack": 0.002, "decay": 0.1, "sustain": 0}}]})";

Json recipe_of(const AssetsProject& p, const std::string& rel) { return p.manifest()["assets"][rel]["provenance"]["recipe"]; }

}  // namespace

TEST_CASE("sfx.render: writes the WAV next to the patch with measurements, a picture and a recipe whose input is the patch") {
    AssetsProject p;
    write_all(p.file("assets/audio/blip.sfx.json"), kBlip);
    const Json r = p.ok("sfx.render", {{"path", "assets/audio/blip.sfx.json"}});
    CHECK(r["path"] == "assets/audio/blip.wav");
    CHECK(r["measurements"]["seconds"].get<double>() == doctest::Approx(0.15).epsilon(0.01));
    CHECK(r["measurements"]["lufs"].get<double>() == doctest::Approx(-18.0).epsilon(0.1));
    CHECK(r["measurements"]["peakDb"].get<double>() <= -0.99);
    CHECK(r.contains("$image"));
    CHECK(r["analysis"].is_object());
    const std::string wav = read_all(p.file("assets/audio/blip.wav"));
    REQUIRE(wav.size() > 44);
    CHECK(wav.substr(0, 4) == "RIFF");
    auto loudness = measure_loudness({reinterpret_cast<const std::uint8_t*>(wav.data()), wav.size()}, ".wav");
    REQUIRE(loudness.ok());
    CHECK(loudness->integratedLufs == doctest::Approx(r["measurements"]["lufs"].get<double>()).epsilon(0.05));

    const Json prov = p.manifest()["assets"]["assets/audio/blip.wav"]["provenance"];
    CHECK(prov["origin"] == "original");
    CHECK(prov["ai"] == false);
    const Json recipe = recipe_of(p, "assets/audio/blip.wav");
    CHECK(recipe["command"] == "sfx.render");
    REQUIRE(recipe["inputs"].size() == 1);
    CHECK(recipe["inputs"][0]["path"] == "assets/audio/blip.sfx.json");
    CHECK(recipe["inputs"][0].contains("sha256"));

    // without the picture, the same bytes
    const Json bare = p.ok("sfx.render", {{"path", "assets/audio/blip.sfx.json"}, {"picture", false}});
    CHECK_FALSE(bare.contains("$image"));
    CHECK(read_all(p.file("assets/audio/blip.wav")) == wav);
}

TEST_CASE("sfx.render: seed, note and an .ogg output change one render; the recipe remembers them") {
    AssetsProject p;
    write_all(p.file("assets/audio/blip.sfx.json"), kBlip);
    p.ok("sfx.render", {{"path", "assets/audio/blip.sfx.json"}, {"picture", false}});
    const std::string base = read_all(p.file("assets/audio/blip.wav"));
    p.ok("sfx.render", {{"path", "assets/audio/blip.sfx.json"}, {"out", "assets/audio/blip_c4.wav"}, {"note", "C4"}, {"picture", false}});
    CHECK(read_all(p.file("assets/audio/blip_c4.wav")) != base);
    CHECK(recipe_of(p, "assets/audio/blip_c4.wav")["args"]["note"] == "C4");
    p.ok("sfx.render", {{"path", "assets/audio/blip.sfx.json"}, {"out", "assets/audio/blip.ogg"}, {"picture", false}});
    const std::string ogg = read_all(p.file("assets/audio/blip.ogg"));
    REQUIRE(ogg.size() > 4);
    CHECK(ogg.substr(0, 4) == "OggS");

    // the same recipe regenerates the same bytes
    write_all(p.file("assets/audio/blip_c4.wav"), "spoiled");
    CHECK(p.ok("assets.regenerate", {{"path", "assets/audio/blip_c4.wav"}})["count"] == 1);
    CHECK(read_all(p.file("assets/audio/blip_c4.wav")) != "spoiled");
    CHECK(read_all(p.file("assets/audio/blip_c4.wav")).substr(0, 4) == "RIFF");
}

TEST_CASE("sfx.render: errors say what is wrong and how to fix it") {
    AssetsProject p;
    write_all(p.file("assets/audio/blip.sfx.json"), kBlip);
    CommandResult missing = p.call("sfx.render", {{"path", "assets/audio/blop.sfx.json"}});
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error["code"] == "not_found");
    CHECK(missing.error["hint"].get<std::string>().find("blip.sfx.json") != std::string::npos);  // did you mean
    CHECK(p.call("sfx.render", {{"path", "assets/audio/blip.json"}}).error["code"] == "invalid_argument");
    CHECK(p.call("sfx.render", {{"path", "sounds/blip.sfx.json"}}).error["code"] == "invalid_argument");
    CHECK(p.call("sfx.render", {{"path", "assets/audio/blip.sfx.json"}, {"freq", 440}, {"note", "A4"}}).error["code"] == "invalid_argument");
    CHECK(p.call("sfx.render", {{"path", "assets/audio/blip.sfx.json"}, {"length", 99}}).ok == false);

    // a file at the output path that sfx.render did not make is not replaced
    write_all(p.file("assets/audio/blip.wav"), "mine");
    CommandResult exists = p.call("sfx.render", {{"path", "assets/audio/blip.sfx.json"}});
    REQUIRE_FALSE(exists.ok);
    CHECK(exists.error["code"] == "exists");
    CHECK(read_all(p.file("assets/audio/blip.wav")) == "mine");
    p.ok("sfx.render", {{"path", "assets/audio/blip.sfx.json"}, {"overwrite", true}, {"picture", false}});
    CHECK(read_all(p.file("assets/audio/blip.wav")).substr(0, 4) == "RIFF");

    // a patch with mistakes: every problem, with its pointer
    write_all(p.file("assets/audio/bad.sfx.json"), R"({"format": "factoria.sfx/1", "layers": [
        {"oscillators": [{"wave": "sqare"}], "filter": {"cutoff": 5}}, {"oscillators": []}]})");
    CommandResult bad = p.call("sfx.render", {{"path", "assets/audio/bad.sfx.json"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["code"] == "invalid_patch");
    const Json issues = bad.error["data"]["issues"];
    REQUIRE(issues.size() >= 3);
    bool sawSquare = false, sawCutoff = false, sawEmpty = false;
    for (const Json& i : issues) {
        const std::string ptr = i["pointer"].get<std::string>();
        if (ptr == "/layers/0/oscillators/0/wave") sawSquare = i["hint"].get<std::string>().find("square") != std::string::npos;
        if (ptr == "/layers/0/filter/cutoff") sawCutoff = true;
        if (ptr == "/layers/1/oscillators") sawEmpty = true;
    }
    CHECK(sawSquare);
    CHECK(sawCutoff);
    CHECK(sawEmpty);
    CHECK_FALSE(p.exists("assets/audio/bad.wav"));
}

TEST_CASE("sfx: a changed patch makes its sound stale, validate warns, regenerate and bake render it again") {
    TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    struct Project {
        std::string dir;
        CommandRegistry registry;
        std::filesystem::path file(const std::string& rel) const { return std::filesystem::path(dir) / rel; }
        CommandResult call(const std::string& name, const Json& args) const { return registry.call(name, args); }
        Json ok(const std::string& name, const Json& args) const {
            CommandResult r = registry.call(name, args);
            REQUIRE_MESSAGE(r.ok, r.error.dump());
            return r.result;
        }
    } p;
    p.dir = tmp.sub("game");
    register_asset_commands(p.registry, p.dir);
    write_all(p.file("assets/audio/blip.sfx.json"), kBlip);
    p.ok("sfx.render", {{"path", "assets/audio/blip.sfx.json"}, {"picture", false}});
    const std::string first = read_all(p.file("assets/audio/blip.wav"));
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 0);
    CHECK(p.ok("sfx.bake", {})["count"] == 0);
    CHECK(p.ok("sfx.info", {{"path", "assets/audio/blip.sfx.json"}})["baked"]["stale"] == false);

    write_all(p.file("assets/audio/blip.sfx.json"), kBlipLower);
    CHECK(p.ok("sfx.info", {{"path", "assets/audio/blip.sfx.json"}})["baked"]["stale"] == true);
    bool warned = false;
    for (const ValidationIssue& w : validate_project(p.dir).warnings)
        warned = warned || w.message.find("'assets/audio/blip.wav' is stale") != std::string::npos;
    CHECK(warned);

    const Json plan = p.ok("sfx.bake", {{"dryRun", true}});
    REQUIRE(plan["wouldBake"].size() == 1);
    CHECK(plan["wouldBake"][0]["reason"] == "stale");
    CHECK(read_all(p.file("assets/audio/blip.wav")) == first);  // dryRun writes nothing
    const Json baked = p.ok("sfx.bake", {});
    REQUIRE(baked["count"] == 1);
    CHECK(baked["baked"][0]["patch"] == "assets/audio/blip.sfx.json");
    CHECK(read_all(p.file("assets/audio/blip.wav")) != first);
    CHECK(p.ok("sfx.bake", {})["count"] == 0);

    // and regenerate does the same through the recipe
    write_all(p.file("assets/audio/blip.sfx.json"), kBlip);
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 1);
    CHECK(read_all(p.file("assets/audio/blip.wav")) == first);
}

TEST_CASE("sfx.bake: bakes patches whose sound is missing, skips a file it did not make, lists a broken patch with its issues") {
    AssetsProject p;
    write_all(p.file("assets/audio/a.sfx.json"), kBlip);
    write_all(p.file("assets/audio/b.sfx.json"), kBlip);
    write_all(p.file("assets/audio/b.wav"), "not mine");
    write_all(p.file("assets/audio/c.sfx.json"), R"({"format": "factoria.sfx/1", "layers": [{"oscillators": [{"wave": "sine"}], "pitch": {"freq": 0}}]})");
    const Json r = p.ok("sfx.bake", {});
    CHECK(r["count"] == 1);
    CHECK(r["baked"][0]["patch"] == "assets/audio/a.sfx.json");
    CHECK(p.exists("assets/audio/a.wav"));
    REQUIRE(r["skipped"].size() == 1);
    CHECK(r["skipped"][0]["patch"] == "assets/audio/b.sfx.json");
    CHECK(read_all(p.file("assets/audio/b.wav")) == "not mine");
    REQUIRE(r["failed"].size() == 1);
    CHECK(r["failed"][0]["patch"] == "assets/audio/c.sfx.json");
    CHECK(r["failed"][0]["error"]["issues"][0]["pointer"] == "/layers/0/pitch/freq");
}

TEST_CASE("sfx.preset: lists, returns, writes; an existing file needs overwrite; an unknown name suggests") {
    AssetsProject p;
    const Json list = p.ok("sfx.preset", {});
    CHECK(list["presets"].size() == 17);
    const Json coin = p.ok("sfx.preset", {{"name", "coin"}});
    CHECK(coin["patch"]["format"] == "factoria.sfx/1");
    CHECK(coin["patch"]["layers"].is_array());
    CHECK(p.ok("sfx.info", {{"patch", coin["patch"]}})["valid"] == true);

    const Json written = p.ok("sfx.preset", {{"name", "coin"}, {"path", "assets/audio/coin.sfx.json"}});
    CHECK(written["path"] == "assets/audio/coin.sfx.json");
    CHECK(parse_json(read_all(p.file("assets/audio/coin.sfx.json")), "coin").value() == coin["patch"]);
    CommandResult again = p.call("sfx.preset", {{"name", "coin"}, {"path", "assets/audio/coin.sfx.json"}});
    REQUIRE_FALSE(again.ok);
    CHECK(again.error["code"] == "exists");
    CHECK(p.call("sfx.preset", {{"name", "coin"}, {"path", "assets/audio/coin.sfx.json"}, {"overwrite", true}}).ok);

    CommandResult bad = p.call("sfx.preset", {{"name", "lasser"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["hint"].get<std::string>().find("laser") != std::string::npos);
    CHECK(p.call("sfx.preset", {{"name", "coin"}, {"path", "assets/audio/coin.json"}}).error["code"] == "invalid_argument");

    // a written preset renders
    const Json r = p.ok("sfx.render", {{"path", "assets/audio/coin.sfx.json"}, {"picture", false}});
    CHECK(r["measurements"]["lufs"].get<double>() == doctest::Approx(-18.0).epsilon(0.1));
}

TEST_CASE("sfx.info: a valid patch says what it holds, an invalid one lists every problem") {
    AssetsProject p;
    write_all(p.file("assets/audio/blip.sfx.json"), kBlip);
    const Json info = p.ok("sfx.info", {{"path", "assets/audio/blip.sfx.json"}});
    CHECK(info["valid"] == true);
    CHECK(info["rootHz"].get<double>() == doctest::Approx(440.0));
    CHECK(info["layers"].size() == 1);
    CHECK(info["layers"][0]["oscillators"][0] == "square");
    CHECK(info["baked"]["exists"] == false);
    CHECK(info["measurements"]["seconds"].get<double>() == doctest::Approx(0.15).epsilon(0.01));
    CHECK_FALSE(p.exists("assets/audio/blip.wav"));  // read-only

    const Json bad = p.ok("sfx.info", {{"patch", parse_json(R"({"format": "factoria.sfx/2", "length": 0, "layerz": [], "layers": [{"oscillators": [{"wave": "sine", "detune": 99999}]}]})", "patch").value()}});
    CHECK(bad["valid"] == false);
    std::set<std::string> pointers;
    for (const Json& i : bad["issues"]) {
        pointers.insert(i["pointer"].get<std::string>());
        CHECK_FALSE(i["message"].get<std::string>().empty());
        CHECK_FALSE(i["hint"].get<std::string>().empty());
    }
    CHECK(pointers.count("/format"));
    CHECK(pointers.count("/length"));
    CHECK(pointers.count("/layerz"));  // the unknown key
    CHECK(pointers.count("/layers/0/oscillators/0/detune"));
    bool suggested = false;
    for (const Json& i : bad["issues"])
        if (i["hint"].get<std::string>().find("layers") != std::string::npos && i["message"].get<std::string>().find("layerz") != std::string::npos) suggested = true;
    CHECK(suggested);

    CHECK(p.call("sfx.info", {}).error["code"] == "invalid_argument");
    CHECK(p.call("sfx.info", {{"preset", "nope"}}).error["code"] == "not_found");
}

TEST_CASE("assets.synth_sound is a preset rendered through the patch synthesizer: same arguments, same bytes as sfx.render of the preset") {
    AssetsProject p;
    p.ok("assets.synth_sound", {{"path", "assets/audio/hit.wav"}, {"preset", "hit"}, {"seed", 5}});
    const std::string a = read_all(p.file("assets/audio/hit.wav"));
    CHECK(a.substr(0, 4) == "RIFF");
    p.ok("assets.synth_sound", {{"path", "assets/audio/hit2.wav"}, {"preset", "hit"}, {"seed", 5}});
    CHECK(read_all(p.file("assets/audio/hit2.wav")) == a);
    p.ok("assets.synth_sound", {{"path", "assets/audio/short.wav"}, {"preset", "whoosh"}, {"seconds", 0.3}});
    const std::string wav = read_all(p.file("assets/audio/short.wav"));
    auto loudness = measure_loudness({reinterpret_cast<const std::uint8_t*>(wav.data()), wav.size()}, ".wav");
    REQUIRE(loudness.ok());
    CHECK(loudness->seconds == doctest::Approx(0.3).epsilon(0.05));
    CHECK(p.manifest()["assets"]["assets/audio/hit.wav"]["provenance"]["recipe"]["command"] == "assets.synth_sound");
}
