// assets.analyze_audio and the loudness check of project.validate (tools/common/src/audio_analysis.cpp).
#include <doctest.h>

#include <cmath>
#include <filesystem>

#include "fa/core/command.h"
#include "fa/core/hash.h"
#include "fa/core/json.h"
#include "fa/tooling/tooling.h"
#include "fa/tooling/validate.h"
#include "audio_test_wav.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;
using testing::sine_wav;

namespace {

struct Project {
    testing::TempDir tmp;
    CommandRegistry registry;
    Project() { register_tooling_commands(registry, tmp.str()); }
    void write(const std::string& rel, const std::string& data) { testing::write_all(tmp.path / rel, data); }
    Json manifest() { return *parse_json(testing::read_all(tmp.path / "assets.json")); }
    CommandResult analyze(const Json& args = Json::object()) { return registry.call("assets.analyze_audio", args); }
};

bool has_warning(const ValidationReport& r, const std::string& file, const std::string& text) {
    for (const ValidationIssue& w : r.warnings)
        if (w.file == file && w.message.find(text) != std::string::npos) return true;
    return false;
}

}  // namespace

TEST_CASE("assets.analyze_audio: measures a sound, keeps the result in assets.json and reuses it while the file is the same") {
    Project p;
    p.write("assets/tone.wav", sine_wav(5.0, -23.0));
    p.write("assets.json", R"({"format": "factoria.assets/1", "assets": {"assets/tone.wav": {
        "import": {"normalize": true, "stream": "always"}, "provenance": {"origin": "original", "date": "2026-10-16"}}}})");

    CommandResult r = p.analyze({{"path", "assets/tone.wav"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["files"].size() == 1);
    const Json& f = r.result["files"][0];
    CHECK(f["path"] == "assets/tone.wav");
    CHECK(f["loudnessLufs"].get<double>() == doctest::Approx(-23.0).epsilon(0.1 / 23.0));
    CHECK(f["peakDb"].get<double>() == doctest::Approx(-23.0).epsilon(0.1 / 23.0));
    CHECK(f["seconds"].get<double>() == doctest::Approx(5.0));
    CHECK(f["streams"] == true);  // the import setting forces it
    CHECK(f["normalize"] == true);
    CHECK(f["gainDb"].get<double>() == doctest::Approx(7.0).epsilon(0.1 / 7.0));  // -23 LUFS to the default -16
    CHECK(f["cached"] == false);
    CHECK(f["stored"] == true);
    CHECK(r.result["measured"] == 1);

    const Json stored = p.manifest()["assets"]["assets/tone.wav"];
    CHECK(stored["analysis"]["loudnessLufs"] == f["loudnessLufs"]);
    CHECK(stored["analysis"]["bytes"] == sine_wav(5.0, -23.0).size());
    CHECK(stored["analysis"]["sha256"] == sha256_hex(sine_wav(5.0, -23.0)));
    CHECK(stored["import"]["normalize"] == true);          // what was there stays
    CHECK(stored["provenance"]["origin"] == "original");

    for (const ValidationIssue& e : validate_project(p.tmp.str()).errors) CHECK(e.file != "assets.json");  // the schema accepts it

    CommandResult again = p.analyze({{"path", "assets/tone.wav"}});
    REQUIRE(again.ok);
    CHECK(again.result["files"][0]["cached"] == true);
    CHECK(again.result["files"][0]["stored"] == false);
    CHECK(again.result["cached"] == 1);

    p.write("assets/tone.wav", sine_wav(5.0, -17.0));  // edited: the record no longer describes it
    CommandResult edited = p.analyze({{"path", "assets/tone.wav"}});
    REQUIRE(edited.ok);
    CHECK(edited.result["files"][0]["cached"] == false);
    CHECK(edited.result["files"][0]["loudnessLufs"].get<double>() == doctest::Approx(-17.0).epsilon(0.1 / 17.0));
    CHECK(p.manifest()["assets"]["assets/tone.wav"]["analysis"]["sha256"] == sha256_hex(sine_wav(5.0, -17.0)));
}

TEST_CASE("assets.analyze_audio: without a path it analyzes every sound the project has, and explains what it cannot") {
    Project p;
    p.write("assets/a.wav", sine_wav(1.0, -20.0));
    p.write("assets/sub/b.wav", sine_wav(1.0, -30.0));
    p.write("assets/broken.ogg", "not an ogg file");
    p.write("sounds/outside.wav", sine_wav(1.0, -25.0));  // only the scene names it
    p.write("scenes/main.scene.json", R"({"format": "factoria.scene/1", "entities": [{"id": "e", "name": "e",
        "components": {"AudioSource": {"clip": "sounds/outside.wav"}}}]})");
    p.write("assets/notes.txt", "not a sound");

    CommandResult all = p.analyze();
    REQUIRE_MESSAGE(all.ok, all.error.dump());
    CHECK(all.result["measured"] == 3);
    CHECK(all.result["failed"] == 1);
    std::vector<std::string> paths;
    for (const Json& f : all.result["files"]) paths.push_back(f["path"]);
    CHECK(paths == std::vector<std::string>{"assets/a.wav", "assets/broken.ogg", "assets/sub/b.wav", "sounds/outside.wav"});
    CHECK(all.result["files"][1].contains("error"));
    CHECK(p.manifest()["assets"].contains("sounds/outside.wav"));
    CHECK_FALSE(p.manifest()["assets"].contains("assets/broken.ogg"));

    CommandResult text = p.analyze({{"path", "assets/notes.txt"}});
    CHECK_FALSE(text.ok);
    CHECK(text.error["message"].get<std::string>().find("not a sound file") != std::string::npos);
    CommandResult missing = p.analyze({{"path", "assets/b.wav"}});
    CHECK_FALSE(missing.ok);
    INFO(missing.error.dump());
    CHECK(missing.error["hint"].get<std::string>().find("assets/a.wav") != std::string::npos);  // did you mean
    CommandResult bad = p.analyze({{"path", "assets/broken.ogg"}});
    CHECK_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("assets/broken.ogg") != std::string::npos);

    Project empty;
    CommandResult none = empty.analyze();
    REQUIRE(none.ok);
    CHECK(none.result["files"].empty());
    CHECK(none.result.contains("note"));
    CHECK_FALSE(stdfs::exists(empty.tmp.path / "assets.json"));  // nothing measured, nothing written
}

TEST_CASE("project.validate: warns about clipped, very loud and very quiet sounds, and writes nothing") {
    testing::TempDir tmp;
    testing::write_all(tmp.path / "assets/clipped.wav", sine_wav(2.0, 0.0));
    testing::write_all(tmp.path / "assets/loud.wav", sine_wav(2.0, -6.0));
    testing::write_all(tmp.path / "assets/quiet.wav", sine_wav(2.0, -46.0));
    testing::write_all(tmp.path / "assets/fine.wav", sine_wav(2.0, -16.0));
    testing::write_all(tmp.path / "assets/broken.mp3", "nothing to hear");
    ValidationReport r = validate_project(tmp.str());
    CHECK(has_warning(r, "assets/clipped.wav", "Peaks at"));
    CHECK(has_warning(r, "assets/loud.wav", "Very loud"));
    CHECK(has_warning(r, "assets/quiet.wav", "Very quiet"));
    CHECK(has_warning(r, "assets/broken.mp3", "Cannot measure"));
    for (const ValidationIssue& w : r.warnings) CHECK(w.file != "assets/fine.wav");
    for (const ValidationIssue& w : r.warnings)
        if (w.file.rfind("assets/", 0) == 0 && w.message.find("Cannot measure") == std::string::npos) CHECK_FALSE(w.hint.empty());
    CHECK_FALSE(stdfs::exists(tmp.path / "assets.json"));  // validate never writes

    testing::write_all(tmp.path / "assets.json", R"({"format": "factoria.assets/1"})");
    validate_project(tmp.str());
    CHECK(testing::read_all(tmp.path / "assets.json") == R"({"format": "factoria.assets/1"})");
}

TEST_CASE("project.validate: uses the analysis of assets.json while it describes the file") {
    testing::TempDir tmp;
    const std::string wav = sine_wav(2.0, -16.0);
    testing::write_all(tmp.path / "assets/clip.wav", wav);
    const std::string record = R"({"loudnessLufs": -50.0, "peakDb": -45.0, "seconds": 2.0, "bytes": )" + std::to_string(wav.size()) +
                               R"(, "sha256": ")" + sha256_hex(wav) + R"("})";
    testing::write_all(tmp.path / "assets.json", R"({"format": "factoria.assets/1", "assets": {"assets/clip.wav": {"analysis": )" + record + "}}}");
    CHECK(has_warning(validate_project(tmp.str()), "assets/clip.wav", "-50.0 LUFS"));  // the record is believed

    testing::write_all(tmp.path / "assets/clip.wav", sine_wav(2.0, -15.5));  // another file: the record is stale
    for (const ValidationIssue& w : validate_project(tmp.str()).warnings) CHECK(w.file != "assets/clip.wav");
}

TEST_CASE("project.validate: warns when sound effects differ by more than 12 LU, unless they are normalized") {
    testing::TempDir fx;  // two effects 16 LU apart
    testing::write_all(fx.path / "assets/a.wav", sine_wav(1.0, -12.0));
    testing::write_all(fx.path / "assets/b.wav", sine_wav(1.0, -28.0));
    ValidationReport spread = validate_project(fx.str());
    CHECK(has_warning(spread, "assets/a.wav", "differ by 16.0 LU"));
    for (const ValidationIssue& w : spread.warnings)
        if (w.message.find("differ by") != std::string::npos) CHECK(w.message.find("assets/b.wav") != std::string::npos);  // names the quietest

    testing::write_all(fx.path / "assets.json",  // normalized, they play equally loud
                       R"({"format": "factoria.assets/1", "defaults": {"audio": {"normalize": true}}})");
    for (const ValidationIssue& w : validate_project(fx.str()).warnings) CHECK(w.message.find("differ by") == std::string::npos);

    testing::TempDir music;  // long clips (music) are not effects
    testing::write_all(music.path / "assets/a.wav", sine_wav(12.0, -12.0));
    testing::write_all(music.path / "assets/b.wav", sine_wav(12.0, -28.0));
    for (const ValidationIssue& w : validate_project(music.str()).warnings) CHECK(w.message.find("differ by") == std::string::npos);
}
