// assets.spectrogram and assets.check_mix (tools/common/src/audio_mix_commands.cpp) on generated signals.
#include <doctest.h>

#include <cmath>
#include <filesystem>
#include <numbers>
#include <vector>

#include "fa/audio/convert.h"
#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/tooling/tooling.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

constexpr double kPiD = std::numbers::pi;
constexpr int kRate = 44100;

// A mono 16-bit WAV of the samples (clamped to full scale).
std::string wav_of(const std::vector<double>& x) {
    std::string b;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char(v >> (8 * i))); };
    auto u16 = [&](std::uint16_t v) { b.push_back(char(v)); b.push_back(char(v >> 8)); };
    b += "RIFF"; u32(std::uint32_t(36 + x.size() * 2)); b += "WAVEfmt "; u32(16); u16(1); u16(1);
    u32(kRate); u32(kRate * 2); u16(2); u16(16);
    b += "data"; u32(std::uint32_t(x.size() * 2));
    for (double v : x) u16(std::uint16_t(std::int16_t(std::lround(std::clamp(v, -1.0, 1.0) * 32767.0))));
    return b;
}

// A sine of `hz` and `amp` for `seconds`, starting at `phase`, with a fade of `fadeSeconds` at both ends.
std::vector<double> tone(double hz, double amp, double seconds, double phase = 0.0, double fadeSeconds = 0.0) {
    std::vector<double> x(std::size_t(seconds * kRate));
    for (std::size_t i = 0; i < x.size(); ++i) {
        const double t = double(i) / kRate;
        double env = 1.0;
        if (fadeSeconds > 0) env = std::min({1.0, t / fadeSeconds, (seconds - t) / fadeSeconds});
        x[i] = amp * env * std::sin(2.0 * kPiD * hz * t + phase);
    }
    return x;
}

struct Project {
    testing::TempDir tmp;
    CommandRegistry registry;
    Project() { register_tooling_commands(registry, tmp.str()); }
    void write(const std::string& rel, const std::string& data) { testing::write_all(tmp.path / rel, data); }
    void scene(const std::string& body) { write("scenes/main.scene.json", R"({"format":"factoria.scene/1",)" + body + "}"); }
    CommandResult mix(const Json& args = Json::object()) { return registry.call("assets.check_mix", args); }
};

const Json* find(const Json& findings, const std::string& sound, const std::string& rule) {
    for (const Json& f : findings)
        if (f["sound"] == sound && f["rule"] == rule) return &f;
    return nullptr;
}

}  // namespace

TEST_CASE("assets.check_mix: a click at the start and the end, and a faded sound without one") {
    Project p;
    p.write("assets/click.wav", wav_of(tone(440, 0.4, 1.0, kPiD / 2)));          // starts and ends away from zero
    p.write("assets/clean.wav", wav_of(tone(440, 0.4, 1.0, 0.0, 0.01)));        // faded over 10 ms
    CommandResult r = p.mix({{"includeOk", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& f = r.result["findings"];
    const Json* start = find(f, "assets/click.wav", "click_start");
    REQUIRE(start);
    CHECK((*start)["verdict"] == "fail");
    CHECK((*start)["value"].get<double>() == doctest::Approx(-8.0).epsilon(0.1));  // 0.4 = -8 dBFS
    CHECK((*start)["hint"].get<std::string>().find("Fade") != std::string::npos);
    const Json* end = find(f, "assets/click.wav", "click_end");
    REQUIRE(end);
    CHECK((*end)["verdict"] != "ok");
    REQUIRE(find(f, "assets/clean.wav", "click_start"));
    CHECK((*find(f, "assets/clean.wav", "click_start"))["verdict"] == "ok");
    CHECK((*find(f, "assets/clean.wav", "click_end"))["verdict"] == "ok");
}

TEST_CASE("assets.check_mix: clipping is counted and the true peak is measured") {
    Project p;
    std::vector<double> square(kRate / 2);
    for (std::size_t i = 0; i < square.size(); ++i) square[i] = (i / 50) % 2 ? -1.5 : 1.5;  // clamps to full scale
    p.write("assets/square.wav", wav_of(square));
    p.write("assets/quiet.wav", wav_of(tone(300, 0.2, 0.5, 0.0, 0.01)));
    CommandResult r = p.mix({{"includeOk", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& f = r.result["findings"];
    const Json* clip = find(f, "assets/square.wav", "clipping");
    REQUIRE(clip);
    CHECK((*clip)["verdict"] == "fail");
    CHECK((*clip)["value"].get<double>() >= 20000);
    CHECK((*find(f, "assets/quiet.wav", "clipping"))["verdict"] == "ok");
    CHECK((*find(f, "assets/quiet.wav", "true_peak"))["verdict"] == "ok");
    // A sine at a quarter of the sample rate peaking between samples reads higher as a true peak than as a sample peak.
    std::vector<double> between(kRate / 4);
    for (std::size_t i = 0; i < between.size(); ++i) between[i] = 0.99 * std::sin(2.0 * kPiD * (kRate / 4.0) * double(i) / kRate + kPiD / 4.0);
    p.write("assets/between.wav", wav_of(between));
    r = p.mix({{"paths", Json::array({"assets/between.wav"})}, {"includeOk", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& row = r.result["sounds"][0];
    CHECK(row["samplePeakDb"].get<double>() < -2.5);  // the samples reach 0.7
    CHECK(row["truePeakDb"].get<double>() > row["samplePeakDb"].get<double>() + 2.0);
    CHECK(row["truePeakDb"].get<double>() == doctest::Approx(-0.09).epsilon(0.5));
}

TEST_CASE("assets.check_mix: a loop seam is found only for sounds played looping") {
    Project p;
    p.write("assets/seam.wav", wav_of(tone(100, 0.5, 1.005, kPiD / 2)));  // 100.5 periods of a cosine: the end is at -0.5, the start at 0.5
    p.write("assets/bend.wav", wav_of(tone(100, 0.5, 1.005, 0.0)));  // a sine: both ends at zero, but the slope turns round
    p.write("assets/seamless.wav", wav_of(tone(100, 0.5, 1.0, 0.0)));  // 100 periods
    p.write("assets/once.wav", wav_of(tone(100, 0.5, 1.005, 0.0, 0.01)));
    p.scene(R"("entities":[
        {"id":"a","components":{"AudioSource":{"clip":"assets/seam.wav","loop":true}}},
        {"id":"b","components":{"AudioSource":{"clip":"assets/seamless.wav","loop":true}}},
        {"id":"d","components":{"AudioSource":{"clip":"assets/bend.wav","loop":true}}},
        {"id":"c","components":{"AudioSource":{"clip":"assets/once.wav"}}}])");
    CommandResult r = p.mix({{"includeOk", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& f = r.result["findings"];
    const Json* jump = find(f, "assets/seam.wav", "loop_seam_jump");
    REQUIRE(jump);
    CHECK((*jump)["verdict"] == "fail");
    CHECK((*jump)["hint"].get<std::string>().find("assets.generate_loop") != std::string::npos);
    CHECK((*find(f, "assets/bend.wav", "loop_seam_jump"))["verdict"] == "ok");
    CHECK((*find(f, "assets/bend.wav", "loop_seam_slope"))["verdict"] == "fail");
    REQUIRE(find(f, "assets/seamless.wav", "loop_seam_jump"));
    CHECK((*find(f, "assets/seamless.wav", "loop_seam_jump"))["verdict"] == "ok");
    CHECK((*find(f, "assets/seamless.wav", "loop_seam_slope"))["verdict"] == "ok");
    CHECK(find(f, "assets/once.wav", "loop_seam_jump") == nullptr);
    CHECK(find(f, "assets/seam.wav", "click_start") == nullptr);  // a loop is judged by its seam
    CHECK(find(f, "assets/once.wav", "click_start") != nullptr);
}

TEST_CASE("assets.check_mix: music masks an effect in the same band but not one in another band") {
    Project p;
    std::vector<double> bed = tone(250, 0.25, 3.0, 0.0, 0.05);
    const std::vector<double> more = tone(300, 0.25, 3.0, 0.0, 0.05);
    for (std::size_t i = 0; i < bed.size(); ++i) bed[i] += more[i];
    p.write("assets/bed.wav", wav_of(bed));
    p.write("assets/low.wav", wav_of(tone(250, 0.1, 0.4, 0.0, 0.01)));
    p.write("assets/high.wav", wav_of(tone(4000, 0.1, 0.4, 0.0, 0.01)));
    p.scene(R"("settings":{"music":"assets/bed.wav"},"entities":[
        {"id":"a","components":{"AudioSource":{"clip":"assets/low.wav"}}},
        {"id":"b","components":{"AudioSource":{"clip":"assets/high.wav"}}}])");
    CommandResult r = p.mix({{"includeOk", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& f = r.result["findings"];
    const Json* low = find(f, "assets/low.wav", "music_masking");
    REQUIRE(low);
    CHECK((*low)["verdict"] != "ok");
    CHECK((*low)["detail"]["music"] == "assets/bed.wav");
    CHECK((*low)["detail"]["loudestBand"] == "250 Hz");
    CHECK((*low)["hint"].get<std::string>().find("duck") != std::string::npos);
    const Json* high = find(f, "assets/high.wav", "music_masking");
    REQUIRE(high);
    CHECK((*high)["verdict"] == "ok");
    CHECK((*high)["detail"]["loudestBand"] == "4 kHz");
    // The music itself is on the music bus; the effects on sfx.
    for (const Json& s : r.result["sounds"]) {
        if (s["path"] == "assets/bed.wav") CHECK(s["bus"] == "music");
        if (s["path"] == "assets/low.wav") CHECK(s["bus"] == "sfx");
    }
}

TEST_CASE("assets.check_mix: loudness against a target per bus, the spread without one, and the unknown bus") {
    Project p;
    p.write("assets/loud.wav", wav_of(tone(1000, 0.5, 1.0, 0.0, 0.01)));
    p.write("assets/soft.wav", wav_of(tone(1000, 0.02, 1.0, 0.0, 0.01)));
    p.write("assets/nowhere.wav", wav_of(tone(1000, 0.1, 1.0, 0.0, 0.01)));
    p.scene(R"("entities":[
        {"id":"a","components":{"AudioSource":{"clip":"assets/loud.wav"}}},
        {"id":"b","components":{"AudioSource":{"clip":"assets/soft.wav"}}}])");
    p.write("scripts/s.js", "audio.play(\"assets/nowhere.wav\", { volume: 1, bus: \"ui\" });");

    CommandResult r = p.mix({{"includeOk", true}});  // no target: the spread inside the sfx bus (28 LU apart)
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(find(r.result["findings"], "assets/loud.wav", "loudness_spread") != nullptr);
    CHECK((*find(r.result["findings"], "assets/loud.wav", "loudness_spread"))["verdict"] == "fail");
    CHECK(find(r.result["findings"], "assets/nowhere.wav", "loudness_spread") == nullptr);  // alone on the ui bus

    r = p.mix({{"targets", Json::object({{"sfx", Json::object({{"lufs", -20}, {"toleranceLu", 2}})}})}, {"includeOk", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json* t = find(r.result["findings"], "assets/loud.wav", "loudness_target");
    REQUIRE(t);
    CHECK((*t)["verdict"] != "ok");
    CHECK((*t)["threshold"].get<double>() == 2.0);
    CHECK((*t)["hint"].get<std::string>().find("targetLufs") != std::string::npos);
    CHECK(r.result["targetSource"] == "targets argument");

    // style.audio of assets.json is the default target; a sound no scene plays is on the unknown bus.
    p.write("assets.json", R"({"format":"factoria.assets/1","style":{"audio":{"loudnessLufs":{"default":-14},"toleranceLu":1}},"assets":{}})");
    p.write("scripts/s.js", "");
    r = p.mix({{"includeOk", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json* u = find(r.result["findings"], "assets/nowhere.wav", "loudness_target");
    REQUIRE(u);
    CHECK((*u)["bus"] == "unknown bus");
    CHECK((*u)["threshold"].get<double>() == 1.0);
}

TEST_CASE("assets.check_mix: teaching errors, silence and an empty project") {
    Project p;
    CommandResult r = p.mix();
    REQUIRE(r.ok);
    CHECK(r.result["summary"]["sounds"] == 0);
    CHECK(r.result.contains("note"));
    r = p.mix({{"paths", Json::array({"assets/x.png"})}});
    CHECK_FALSE(r.ok);
    r = p.mix({{"pahts", Json::array()}});
    CHECK_FALSE(r.ok);
}

TEST_CASE("assets.spectrogram: a picture with the numbers, kept with out") {
    Project p;
    p.write("assets/tone.wav", wav_of(tone(1000, 0.5, 1.0, kPiD / 2)));
    CommandResult r = p.registry.call("assets.spectrogram", {{"path", "assets/tone.wav"}, {"width", 600}, {"height", 400}, {"loop", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["picture"]["width"] == 600);
    CHECK(r.result["seconds"].get<double>() == doctest::Approx(1.0));
    CHECK(r.result["dominantBand"]["band"] == "1 kHz");
    CHECK(r.result["loops"] == true);
    CHECK(r.result["loopSeam"]["jumpRatio"].get<double>() >= 0.0);
    CHECK(r.result["clippedSamples"] == 0);
    REQUIRE(r.result.contains("$image"));
    CHECK(r.result["$image"]["temporary"] == true);
    const stdfs::path temp = r.result["$image"]["path"].get<std::string>();
    CHECK(stdfs::exists(temp));
    CHECK(testing::read_all(temp).substr(1, 3) == "PNG");

    r = p.registry.call("assets.spectrogram", {{"path", "assets/tone.wav"}, {"out", "assets/src/tone.png"}, {"channels", "each"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(stdfs::exists(p.tmp.path / "assets/src/tone.png"));
    CHECK_FALSE(r.result["$image"].contains("temporary"));

    r = p.registry.call("assets.spectrogram", {{"path", "assets/missing.wav"}});
    CHECK_FALSE(r.ok);
    r = p.registry.call("assets.spectrogram", {{"path", "assets/tone.wav"}, {"out", "x.jpg"}});
    CHECK_FALSE(r.ok);
}

namespace {

// `wav` with a `smpl` chunk after its data: one loop over frames [start, last] (both inclusive); `cut` bytes of the body at most.
std::string with_smpl(std::string wav, std::uint32_t start, std::uint32_t last, std::size_t cut = 60) {
    std::string body;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) body.push_back(char(v >> (8 * i))); };
    for (int i = 0; i < 7; ++i) u32(0);
    u32(1); u32(0);                                         // loop count, sampler data
    u32(0); u32(0); u32(start); u32(last); u32(0); u32(0);  // id, type, start, end, fraction, play count
    body.resize(std::min(body.size(), cut));
    wav += "smpl";
    for (int i = 0; i < 4; ++i) wav.push_back(char(std::uint32_t(body.size()) >> (8 * i)));
    return wav + body;
}

}  // namespace

TEST_CASE("assets.check_mix: loop points come from assets.json first and the smpl chunk is the fallback") {
    Project p;
    const std::string seam = wav_of(tone(100, 0.5, 1.005, kPiD / 2));  // the ends differ by a jump; frames 0..44099 are 100 whole periods
    p.write("assets/smpl.wav", with_smpl(seam, 0, 44099));             // the chunk says: loop the clean part
    p.write("assets/both.wav", with_smpl(seam, 0, 44099));             // the same, but assets.json says the whole file
    p.write("assets/cut.wav", with_smpl(seam, 0, 44099, 40));          // a chunk cut short is ignored, not read past its end
    p.write("assets.json", R"({"assets": {"assets/both.wav": {"import": {"loopStart": 0.0, "loopEnd": 1.005}}}})");
    p.scene(R"("entities":[
        {"id":"a","components":{"AudioSource":{"clip":"assets/smpl.wav","loop":true}}},
        {"id":"b","components":{"AudioSource":{"clip":"assets/both.wav","loop":true}}},
        {"id":"c","components":{"AudioSource":{"clip":"assets/cut.wav","loop":true}}}])");
    CommandResult r = p.mix({{"includeOk", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& f = r.result["findings"];
    REQUIRE(find(f, "assets/smpl.wav", "loop_seam_jump"));
    CHECK((*find(f, "assets/smpl.wav", "loop_seam_jump"))["verdict"] == "ok");    // the smpl chunk, nothing in assets.json
    REQUIRE(find(f, "assets/both.wav", "loop_seam_jump"));
    CHECK((*find(f, "assets/both.wav", "loop_seam_jump"))["verdict"] == "fail");  // assets.json wins: the engine plays that
    REQUIRE(find(f, "assets/cut.wav", "loop_seam_jump"));
    CHECK((*find(f, "assets/cut.wav", "loop_seam_jump"))["verdict"] == "fail");   // truncated chunk: the whole file's seam
}

TEST_CASE("assets.check_mix: an .ogg is judged across the loopStart and loopEnd of assets.json") {
    Project p;
    const std::string wav = wav_of(tone(100, 0.5, 2.005, kPiD / 2));
    auto ogg = encode_vorbis(std::span<const std::uint8_t>(reinterpret_cast<const std::uint8_t*>(wav.data()), wav.size()), 0.9);
    REQUIRE(ogg.ok());
    const std::string bytes(ogg->begin(), ogg->end());
    p.write("assets/open.ogg", bytes);
    p.write("assets/loop.ogg", bytes);
    p.write("assets.json", R"({"assets": {"assets/loop.ogg": {"import": {"loopStart": 0.5, "loopEnd": 1.5}}}})");
    p.scene(R"("entities":[
        {"id":"a","components":{"AudioSource":{"clip":"assets/open.ogg","loop":true}}},
        {"id":"b","components":{"AudioSource":{"clip":"assets/loop.ogg","loop":true}}}])");
    CommandResult r = p.mix({{"includeOk", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& f = r.result["findings"];
    REQUIRE(find(f, "assets/open.ogg", "loop_seam_jump"));
    CHECK((*find(f, "assets/open.ogg", "loop_seam_jump"))["verdict"] == "fail");
    REQUIRE(find(f, "assets/loop.ogg", "loop_seam_jump"));
    CHECK((*find(f, "assets/loop.ogg", "loop_seam_jump"))["verdict"] == "ok");  // 0.5 to 1.5 s is 100 whole periods
}

TEST_CASE("assets.check_mix: when every sound is a recipe input the note says they were skipped") {
    Project p;
    p.write("assets/raw/a.wav", wav_of(tone(200, 0.3, 0.5)));
    p.write("assets.json", R"({"assets": {"assets/mix.wav": {"provenance": {"recipe": {"command": "audio.bake", "args": {}, "inputs": [{"path": "assets/raw/a.wav", "sha256": "x"}]}}}}})");
    CommandResult r = p.mix();
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["skipped"].size() == 1);
    CHECK(r.result["skipped"][0]["reason"].get<std::string>().find("`paths`") != std::string::npos);
    REQUIRE(r.result.contains("note"));
    CHECK(r.result["note"].get<std::string>().find("skipped") != std::string::npos);
    CHECK(r.result["note"].get<std::string>().find("No sounds found") == std::string::npos);
}
