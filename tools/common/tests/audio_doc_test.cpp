// audio.info, audio.render, audio.bake, audio.create, audio.edit: audio documents as project files (docs/SOUND.md "Audio documents"). The
// format and the DSP are tested in fa_audio (engine/audio/tests/test_audio_doc.cpp); here: the files, the recipe, staleness, loop points
// in assets.json, validation, the editing commands and their errors.
#include <doctest.h>

#include "asset_test_helpers.h"
#include "audio_test_wav.h"
#include "fa/audio/analysis.h"
#include "fa/audio/audio_doc.h"
#include "fa/core/json_schema.h"
#include "fa/tooling/audio_doc.h"
#include "fa/tooling/validate.h"
#include "fa_test_paths.h"

using namespace fa;
using namespace fa::testing;

namespace {

Json recipe_of_entry(const AssetsProject& p, const std::string& rel) { return p.manifest()["assets"][rel]["provenance"]["recipe"]; }

void write_door(const AssetsProject& p) { write_all(p.file("assets/raw/door.wav"), sine_wav(1.0, -20.0)); }

const char* kDoor = R"({"format": "factoria.audio/1", "doc": "test door", "source": "assets/raw/door.wav", "steps": [
    {"type": "trim", "start": 0.2, "end": 0.8}, {"type": "fade", "out": 0.05}, {"type": "normalize", "target": -6}]})";

}  // namespace

TEST_CASE("audio.bake: writes the WAV next to the document with measurements, provenance and a recipe whose inputs are the document and the source") {
    AssetsProject p;
    write_door(p);
    write_all(p.file("assets/audio/door.audio.json"), kDoor);
    const Json r = p.ok("audio.bake", {{"path", "assets/audio/door.audio.json"}});
    REQUIRE(r["count"] == 1);
    CHECK(r["baked"][0]["out"] == "assets/audio/door.wav");
    CHECK(r["baked"][0]["measurements"]["seconds"].get<double>() == doctest::Approx(0.6).epsilon(0.01));
    CHECK(r["baked"][0]["measurements"]["peakDb"].get<double>() == doctest::Approx(-6.0).epsilon(0.1));
    const std::string wav = read_all(p.file("assets/audio/door.wav"));
    REQUIRE(wav.size() > 44);
    auto loudness = measure_loudness({reinterpret_cast<const std::uint8_t*>(wav.data()), wav.size()}, ".wav");
    REQUIRE(loudness.ok());
    CHECK(loudness->peakDb == doctest::Approx(-6.0).epsilon(0.1));

    const Json prov = p.manifest()["assets"]["assets/audio/door.wav"]["provenance"];
    CHECK(prov["provider"] == "factoria audio.bake");
    CHECK(prov["source"] == "assets/audio/door.audio.json");
    const Json recipe = recipe_of_entry(p, "assets/audio/door.wav");
    CHECK(recipe["command"] == "audio.bake");
    CHECK(recipe["args"]["path"] == "assets/audio/door.audio.json");
    REQUIRE(recipe["inputs"].size() == 2);
    CHECK(recipe["inputs"][0]["path"] == "assets/audio/door.audio.json");
    CHECK(recipe["inputs"][1]["path"] == "assets/raw/door.wav");

    // the same bytes again, and nothing to do the second time
    CHECK(p.ok("audio.bake", {})["count"] == 0);
    CHECK(p.ok("audio.bake", {{"path", "assets/audio/door.audio.json"}, {"force", true}})["count"] == 1);
    CHECK(read_all(p.file("assets/audio/door.wav")) == wav);
}

TEST_CASE("audio.bake: a changed source or document makes the sound stale; validate warns, regenerate and bake render it again") {
    AssetsProject p;
    write_door(p);
    write_all(p.file("assets/audio/door.audio.json"), kDoor);
    p.ok("audio.bake", {});
    const std::string first = read_all(p.file("assets/audio/door.wav"));
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 0);
    CHECK(p.ok("audio.info", {{"path", "assets/audio/door.audio.json"}})["bake"]["state"] == "fresh");

    write_all(p.file("assets/raw/door.wav"), sine_wav(1.0, -30.0));
    CHECK(p.ok("audio.info", {{"path", "assets/audio/door.audio.json"}, {"render", false}})["bake"]["state"] == "stale");
    bool warned = false;
    for (const ValidationIssue& w : validate_project(p.dir).warnings) warned = warned || w.message.find("'assets/audio/door.wav' is stale") != std::string::npos;
    CHECK(warned);
    const Json plan = p.ok("audio.bake", {{"dryRun", true}});
    REQUIRE(plan["wouldBake"].size() == 1);
    CHECK(plan["wouldBake"][0]["reason"] == "stale");
    CHECK(read_all(p.file("assets/audio/door.wav")) == first);
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 1);
    CHECK(read_all(p.file("assets/audio/door.wav")) != first);
    CHECK(p.ok("audio.bake", {})["count"] == 0);

    // the bake before an export
    write_all(p.file("assets/audio/door.audio.json"), std::string(kDoor) + " ");
    auto status = audio_bake_status(p.dir, "assets/audio/door.audio.json");
    CHECK(status.state == AudioBakeState::Stale);
    auto baked = bake_audio_documents_if_needed(p.dir);
    REQUIRE(baked.ok());
    CHECK(baked->size() == 1);
    CHECK(bake_audio_documents_if_needed(p.dir)->empty());
}

TEST_CASE("audio.bake: a loop step records the loop points as import settings; a document without one erases them") {
    AssetsProject p;
    write_door(p);
    write_all(p.file("assets/audio/hum.audio.json"), R"({"format": "factoria.audio/1", "source": "assets/raw/door.wav", "steps": [
        {"type": "loop", "start": 0.1, "end": 0.9, "crossfade": 0.1}]})");
    const Json r = p.ok("audio.bake", {});
    CHECK(r["baked"][0]["measurements"]["loop"]["startSeconds"].get<double>() == doctest::Approx(0.1).epsilon(0.001));
    const Json entry = p.manifest()["assets"]["assets/audio/hum.wav"];
    CHECK(entry["import"]["loopStart"].get<double>() == doctest::Approx(0.1).epsilon(0.0001));
    CHECK(entry["import"]["loopEnd"].get<double>() == doctest::Approx(0.8).epsilon(0.0001));
    const std::string wav = read_all(p.file("assets/audio/hum.wav"));
    CHECK(wav.find("smpl") != std::string::npos);

    p.ok("audio.edit", {{"path", "assets/audio/hum.audio.json"}, {"op", "remove"}, {"index", 0}});
    const Json after = p.manifest()["assets"]["assets/audio/hum.wav"];
    CHECK_FALSE(after.contains("import"));
    CHECK(read_all(p.file("assets/audio/hum.wav")).find("smpl") == std::string::npos);
}

TEST_CASE("audio.bake: refuses to replace a file nothing baked, and a source it would overwrite; .ogg output") {
    AssetsProject p;
    write_door(p);
    write_all(p.file("assets/audio/door.audio.json"), kDoor);
    write_all(p.file("assets/audio/door.wav"), "not mine");
    const Json r = p.ok("audio.bake", {});
    CHECK(r["count"] == 0);
    REQUIRE(r.contains("failed"));
    CHECK(r["failed"][0]["error"]["message"].get<std::string>().find("already exists") != std::string::npos);
    CHECK(read_all(p.file("assets/audio/door.wav")) == "not mine");
    auto single = p.call("audio.bake", {{"path", "assets/audio/door.audio.json"}});
    CHECK_FALSE(single.ok);
    CHECK(single.error.dump().find("overwrite") != std::string::npos);
    p.ok("audio.bake", {{"path", "assets/audio/door.audio.json"}, {"overwrite", true}});
    CHECK(read_all(p.file("assets/audio/door.wav")) != "not mine");

    // a document next to its own source
    write_all(p.file("assets/raw/door.audio.json"), kDoor);
    auto broken = p.call("audio.bake", {{"path", "assets/raw/door.audio.json"}});
    CHECK_FALSE(broken.ok);  // door.wav in assets/raw is the source: the output would overwrite it
    CHECK(broken.error.dump().find("overwrite its own source") != std::string::npos);
    CHECK(read_all(p.file("assets/raw/door.wav")) == sine_wav(1.0, -20.0));
    const Json all = p.ok("audio.bake", {});
    bool reported = false;
    for (const Json& f : all.value("failed", Json::array())) reported = reported || f["error"]["message"].get<std::string>().find("overwrite its own source") != std::string::npos;
    CHECK(reported);

    write_all(p.file("assets/audio/music.audio.json"), R"({"format": "factoria.audio/1", "source": "assets/raw/door.wav", "output": {"format": "ogg", "quality": 0.4}, "steps": []})");
    p.ok("audio.bake", {{"path", "assets/audio/music.audio.json"}});
    const std::string ogg = read_all(p.file("assets/audio/music.ogg"));
    REQUIRE(ogg.size() > 4);
    CHECK(ogg.substr(0, 4) == "OggS");
}

TEST_CASE("audio.render and audio.info: measurements, per-step results, a picture, stopAfter; nothing is written") {
    AssetsProject p;
    write_door(p);
    write_all(p.file("assets/audio/door.audio.json"), kDoor);
    const Json r = p.ok("audio.render", {{"path", "assets/audio/door.audio.json"}});
    CHECK(r.contains("$image"));
    CHECK(r["steps"].size() == 3);
    CHECK(r["steps"][0]["seconds"].get<double>() == doctest::Approx(0.6).epsilon(0.01));
    CHECK(r["measurements"]["peakDb"].get<double>() == doctest::Approx(-6.0).epsilon(0.1));
    CHECK_FALSE(p.exists("assets/audio/door.wav"));
    const Json early = p.ok("audio.render", {{"path", "assets/audio/door.audio.json"}, {"stopAfter", 0}, {"picture", false}});
    CHECK(early["steps"].size() == 1);
    CHECK(early["measurements"]["peakDb"].get<double>() == doctest::Approx(-20.0).epsilon(0.1));
    auto bad = p.call("audio.render", {{"path", "assets/audio/door.audio.json"}, {"stopAfter", 9}});
    CHECK_FALSE(bad.ok);
    CHECK(bad.error.dump().find("stopAfter") != std::string::npos);

    const Json inlineDoc = p.ok("audio.render", {{"document", Json::parse(R"({"source": "assets/raw/door.wav", "steps": [{"type": "gain", "db": -6}]})")}, {"picture", false}});
    CHECK(inlineDoc["measurements"]["peakDb"].get<double>() == doctest::Approx(-26.0).epsilon(0.1));

    const Json info = p.ok("audio.info", {{"path", "assets/audio/door.audio.json"}});
    CHECK(info["valid"] == true);
    CHECK(info["output"]["path"] == "assets/audio/door.wav");
    CHECK(info["bake"]["state"] == "missing");
    CHECK(info["steps"].size() == 3);
    CHECK(info["steps"][1]["params"]["curve"] == "linear");  // defaults are filled in
    const Json catalog = p.ok("audio.info", {});
    CHECK(catalog["steps"].size() == 18);
    CHECK(catalog["steps"][0]["fields"].size() > 3);
}

TEST_CASE("audio.info and project.validate: a broken document lists every issue with its pointer; unknown names get a suggestion") {
    AssetsProject p;
    write_door(p);
    write_all(p.file("assets/audio/bad.audio.json"), R"({"format": "factoria.audio/1", "source": "assets/raw/door.wav", "steps": [{"type": "fad", "out": 0.1}, {"type": "gain"}]})");
    const Json info = p.ok("audio.info", {{"path", "assets/audio/bad.audio.json"}});
    CHECK(info["valid"] == false);
    REQUIRE(info["issues"].size() >= 2);
    CHECK(info["issues"][0]["pointer"] == "/steps/0/type");
    CHECK(info["issues"][0]["hint"].get<std::string>().find("fade") != std::string::npos);
    const ValidationReport report = validate_project(p.dir);
    int errors = 0;
    for (const ValidationIssue& e : report.errors)
        if (e.file == "assets/audio/bad.audio.json") ++errors;
    CHECK(errors >= 2);

    auto bake = p.call("audio.bake", {{"path", "assets/audio/bad.audio.json"}});
    CHECK_FALSE(bake.ok);
    auto missing = p.call("audio.info", {{"path", "assets/audio/nope.audio.json"}});
    CHECK_FALSE(missing.ok);
    auto notDoc = p.call("audio.info", {{"path", "assets/audio/bad.json"}});
    CHECK_FALSE(notDoc.ok);
    CHECK(notDoc.error.dump().find(".audio.json") != std::string::npos);
    auto typo = p.call("audio.render", {{"path", "assets/audio/bad.audio.json"}, {"stopafter", 1}});
    CHECK_FALSE(typo.ok);
    CHECK(typo.error.dump().find("stopAfter") != std::string::npos);
}

TEST_CASE("audio.create and audio.edit: write a checked document, bake it, change one step; a bad edit writes nothing") {
    AssetsProject p;
    write_door(p);
    const Json created = p.ok("audio.create", {{"path", "assets/audio/door.audio.json"}, {"source", "assets/raw/door.wav"},
                                              {"steps", Json::parse(R"([{"type": "trim", "start": 0.2, "end": 0.8}, {"type": "normalize", "target": -6}])")}});
    CHECK(created["output"] == "assets/audio/door.wav");
    CHECK(created["measurements"]["peakDb"].get<double>() == doctest::Approx(-6.0).epsilon(0.1));
    CHECK(p.exists("assets/audio/door.wav"));
    auto again = p.call("audio.create", {{"path", "assets/audio/door.audio.json"}, {"source", "assets/raw/door.wav"}});
    CHECK_FALSE(again.ok);
    CHECK(again.error.dump().find("overwrite") != std::string::npos);

    const std::string before = read_all(p.file("assets/audio/door.audio.json"));
    const Json set = p.ok("audio.edit", {{"path", "assets/audio/door.audio.json"}, {"op", "set"}, {"index", 1}, {"values", {{"target", -12}}}});
    CHECK(set["measurements"]["peakDb"].get<double>() == doctest::Approx(-12.0).epsilon(0.1));
    const Json add = p.ok("audio.edit", {{"path", "assets/audio/door.audio.json"}, {"op", "add"}, {"index", 1}, {"step", {{"type", "fade"}, {"out", 0.05}}}, {"bake", false}});
    CHECK(add["steps"] == 3);
    CHECK(add["bake"]["state"] == "stale");
    const Json moved = p.ok("audio.edit", {{"path", "assets/audio/door.audio.json"}, {"op", "move"}, {"index", 1}, {"to", 2}, {"bake", false}});
    CHECK(parse_json(read_all(p.file("assets/audio/door.audio.json"))).value()["steps"][2]["type"] == "fade");
    (void)moved;

    const std::string good = read_all(p.file("assets/audio/door.audio.json"));
    auto bad = p.call("audio.edit", {{"path", "assets/audio/door.audio.json"}, {"op", "set"}, {"index", 0}, {"values", {{"strt", 1}}}});
    CHECK_FALSE(bad.ok);
    CHECK(bad.error.dump().find("/steps/0/strt") != std::string::npos);
    CHECK(read_all(p.file("assets/audio/door.audio.json")) == good);
    auto range = p.call("audio.edit", {{"path", "assets/audio/door.audio.json"}, {"op", "remove"}, {"index", 7}});
    CHECK_FALSE(range.ok);
    auto op = p.call("audio.edit", {{"path", "assets/audio/door.audio.json"}, {"op", "ad"}});
    CHECK_FALSE(op.ok);
    CHECK(op.error.dump().find("add") != std::string::npos);
    p.ok("audio.edit", {{"path", "assets/audio/door.audio.json"}, {"op", "document"}, {"output", {{"format", "ogg"}}}, {"bake", false}});
    CHECK(parse_json(read_all(p.file("assets/audio/door.audio.json"))).value()["output"]["format"] == "ogg");
    (void)before;
}

TEST_CASE("audio documents: a document can layer another and a synth patch; changing the innermost makes the outer stale") {
    AssetsProject p;
    write_door(p);
    write_all(p.file("assets/audio/blip.sfx.json"), R"({"format": "factoria.sfx/1", "length": 0.15, "layers": [
        {"oscillators": [{"wave": "square", "duty": 0.25}], "pitch": {"note": "A4"}, "amp": {"attack": 0.002, "decay": 0.1, "sustain": 0}}]})");
    write_all(p.file("assets/audio/inner.audio.json"), R"({"format": "factoria.audio/1", "source": "assets/audio/blip.sfx.json", "steps": [{"type": "gain", "db": -6}]})");
    write_all(p.file("assets/audio/outer.audio.json"), R"({"format": "factoria.audio/1", "source": "assets/raw/door.wav", "steps": [
        {"type": "layer", "source": "assets/audio/inner.audio.json", "offset": 0.5}]})");
    p.ok("audio.bake", {});
    const Json recipe = recipe_of_entry(p, "assets/audio/outer.wav");
    std::vector<std::string> inputs;
    for (const Json& i : recipe["inputs"]) inputs.push_back(i["path"]);
    CHECK(inputs == std::vector<std::string>{"assets/audio/outer.audio.json", "assets/audio/blip.sfx.json", "assets/audio/inner.audio.json", "assets/raw/door.wav"});
    CHECK(p.ok("audio.bake", {})["count"] == 0);
    write_all(p.file("assets/audio/inner.audio.json"), R"({"format": "factoria.audio/1", "source": "assets/audio/blip.sfx.json", "steps": [{"type": "gain", "db": -12}]})");
    const Json plan = p.ok("audio.bake", {{"dryRun", true}});
    CHECK(plan["wouldBake"].size() == 2);  // the inner document's own sound and the outer one that layers it
}

TEST_CASE("audio schema: lists every step and field of the code, and valid documents pass it") {
    namespace stdfs = std::filesystem;
    auto schema = parse_json(read_all(stdfs::path(FA_REPO_ROOT) / "schemas" / "audio.schema.json"), "audio.schema.json");
    REQUIRE(schema.ok());
    for (const AudioStepInfo& step : audio_step_types()) {
        REQUIRE((*schema)["$defs"].contains(step.type));
        const Json& props = (*schema)["$defs"][step.type]["properties"];
        CHECK(props["type"]["const"] == step.type);
        for (const AudioFieldInfo& f : step.fields) {
            CAPTURE(step.type + "." + f.key);
            CHECK(props.contains(f.key));
        }
    }
    CHECK((*schema)["$defs"].size() == audio_step_types().size());
    auto sample = parse_json(kDoor, "door");
    REQUIRE(sample.ok());
    CHECK(validate_json(*schema, *sample).empty());
    Json eq = {{"format", "factoria.audio/1"}, {"source", {{"path", "a.sfx.json"}, {"note", "C4"}}},
               {"output", {{"format", "ogg"}, {"quality", 0.4}}},
               {"steps", Json::array({{{"type", "eq"}, {"bands", Json::array({{{"type", "peak"}, {"freq", 800}, {"gainDb", 3}}})}}, {{"type", "granular"}, {"length", 2.0}, {"enabled", false}}})}};
    CHECK(validate_json(*schema, eq).empty());
    Json broken = *sample;
    broken["steps"][1]["outt"] = 0.1;
    CHECK_FALSE(validate_json(*schema, broken).empty());
}
