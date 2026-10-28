// assets.generate_loop and assets.convert_audio: seamless loops made offline, and WAV to Ogg Vorbis.
#include <doctest.h>

#include <cmath>
#include <cstring>

#include "asset_test_helpers.h"
#include "fa/audio/analysis.h"

using namespace fa;
using namespace fa::testing;

namespace {

struct Wav {
    int rate = 0;
    std::vector<double> s;
};

Wav read_wav(const std::string& bytes) {
    Wav w;
    REQUIRE(bytes.size() > 44);
    REQUIRE(bytes.substr(0, 4) == "RIFF");
    std::uint32_t rate = 0;
    std::memcpy(&rate, bytes.data() + 24, 4);
    w.rate = int(rate);
    for (std::size_t i = 44; i + 1 < bytes.size(); i += 2) {
        std::int16_t v = 0;
        std::memcpy(&v, bytes.data() + i, 2);
        w.s.push_back(v / 32768.0);
    }
    return w;
}

double peak_of(const Wav& w) {
    double p = 0;
    for (double v : w.s) p = std::max(p, std::fabs(v));
    return p;
}

// How much louder the jump from the last sample to the first is than the usual step between neighbours (rms of the steps).
double seam_ratio(const Wav& w) {
    double sum = 0;
    for (std::size_t i = 1; i < w.s.size(); ++i) sum += (w.s[i] - w.s[i - 1]) * (w.s[i] - w.s[i - 1]);
    const double rmsStep = std::sqrt(sum / double(w.s.size() - 1));
    return std::fabs(w.s.front() - w.s.back()) / std::max(rmsStep, 1e-9);
}

}  // namespace

TEST_CASE("assets.generate_loop: noise beds are seamless, deterministic, the asked length and peak, with provenance") {
    AssetsProject p;
    const Json wind = {{"kind", "noise"}, {"color", "brown"}, {"cutoff", 900}, {"gusts", 0.6}, {"seconds", 4}, {"sampleRate", 16000}, {"seed", 5}};
    Json args = wind;
    args["path"] = "assets/audio/wind.wav";
    const Json r = p.ok("assets.generate_loop", args);
    CHECK(r["path"] == "assets/audio/wind.wav");
    const std::string first = read_all(p.file("assets/audio/wind.wav"));
    const Wav w = read_wav(first);
    CHECK(w.rate == 16000);
    CHECK(w.s.size() == 64000);
    CHECK(peak_of(w) == doctest::Approx(0.6).epsilon(0.01));
    CHECK(seam_ratio(w) < 4.0);  // the jump across the loop point is no bigger than the sample-to-sample movement elsewhere

    args["path"] = "assets/audio/wind2.wav";
    p.ok("assets.generate_loop", args);
    CHECK(read_all(p.file("assets/audio/wind2.wav")) == first);
    args["path"] = "assets/audio/wind3.wav";
    args["seed"] = 6;
    p.ok("assets.generate_loop", args);
    CHECK(read_all(p.file("assets/audio/wind3.wav")) != first);

    const Json prov = p.manifest()["assets"]["assets/audio/wind.wav"]["provenance"];
    CHECK(prov["origin"] == "original");
    CHECK(prov["ai"] == false);
    CHECK(prov["seed"] == 5);
    CHECK(prov["license"] == "CC0-1.0");

    // pink and white beds, a fire with crackles and a clock of ticks alone
    for (const char* color : {"white", "pink"}) {
        p.ok("assets.generate_loop", {{"path", std::string("assets/audio/") + color + ".wav"}, {"kind", "noise"}, {"color", color}, {"cutoff", 3000}, {"seconds", 2}});
        const Wav n = read_wav(read_all(p.file(std::string("assets/audio/") + color + ".wav")));
        CHECK(n.s.size() == 44100);
        CHECK(seam_ratio(n) < 6.0);
    }
    p.ok("assets.generate_loop", {{"path", "assets/audio/fire.wav"}, {"kind", "noise"}, {"cutoff", 600}, {"crackles", 5}, {"seconds", 3}});
    const Wav clock = [&] {
        p.ok("assets.generate_loop", {{"path", "assets/audio/clock.wav"}, {"kind", "noise"}, {"level", 0}, {"tick", 1}, {"seconds", 4}, {"sampleRate", 11025}});
        return read_wav(read_all(p.file("assets/audio/clock.wav")));
    }();
    CHECK(clock.s.size() == 44100);
    // ticks only: the sound sits in the first 0.25 s of each second, the rest of it is silent
    double tail = 0;
    for (std::size_t i = 11025 * 3 / 10; i < 11025 * 9 / 10; ++i) tail = std::max(tail, std::fabs(clock.s[i]));
    CHECK(tail < 0.01);
    CHECK(peak_of(clock) > 0.5);
}

TEST_CASE("assets.generate_loop: drones and chord progressions, as WAV and as Ogg") {
    AssetsProject p;
    const Json score = {{"kind", "drone"},
                        {"chords", Json::array({Json::array({"D3", "F3", "A3"}), Json::array({"Bb2", "D3", "F3"})})},
                        {"chordSeconds", 2},
                        {"sampleRate", 16000},
                        {"arpeggio", {{"every", 0.5}, {"pattern", Json::array({0, 2, nullptr, 3})}, {"gain", 0.15}}}};
    Json args = score;
    args["path"] = "assets/music/score.wav";
    const Json r = p.ok("assets.generate_loop", args);
    CHECK(r["seconds"] == 4);  // chords x chordSeconds
    const Wav w = read_wav(read_all(p.file("assets/music/score.wav")));
    CHECK(w.s.size() == 64000);
    CHECK(seam_ratio(w) < 4.0);
    CHECK(peak_of(w) == doctest::Approx(0.6).epsilon(0.01));

    args["path"] = "assets/music/score.ogg";
    const Json o = p.ok("assets.generate_loop", args);
    const std::string ogg = read_all(p.file("assets/music/score.ogg"));
    CHECK(ogg.substr(0, 4) == "OggS");
    CHECK(o["bytes"] == ogg.size());
    auto loud = measure_loudness({reinterpret_cast<const std::uint8_t*>(ogg.data()), ogg.size()}, ".ogg");
    REQUIRE(loud.ok());
    CHECK(loud->seconds == doctest::Approx(4.0).epsilon(0.001));
    CHECK(loud->peakDb < 0);

    // a single chord as a drone with a note in Hz and the seconds given
    p.ok("assets.generate_loop", {{"path", "assets/music/drone.wav"}, {"kind", "drone"}, {"chords", Json::array({Json::array({"A2", 110.0, "E3"})})}, {"seconds", 3}});
    CHECK(read_wav(read_all(p.file("assets/music/drone.wav"))).s.size() == 66150);

    // a note held under the whole loop changes the sound; a wrong one is an error
    p.ok("assets.generate_loop", {{"path", "assets/music/under.wav"}, {"kind", "drone"}, {"chords", Json::array({Json::array({"A2", "E3"})})}, {"seconds", 3}, {"underNote", "D1"}});
    CHECK(read_all(p.file("assets/music/under.wav")) != read_all(p.file("assets/music/drone.wav")));
    CHECK_FALSE(p.call("assets.generate_loop", {{"path", "assets/music/u2.wav"}, {"kind", "drone"}, {"chords", Json::array({Json::array({"A2"})})}, {"underNote", "H9"}}).ok);
}

TEST_CASE("assets.generate_loop: wrong arguments are errors that say what to change") {
    AssetsProject p;
    CommandResult kind = p.call("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "nois"}});
    REQUIRE_FALSE(kind.ok);
    CHECK(kind.error["hint"].get<std::string>().find("noise") != std::string::npos);
    CHECK_FALSE(p.call("assets.generate_loop", {{"path", "assets/a.mp3"}, {"kind", "noise"}}).ok);
    CHECK_FALSE(p.call("assets.generate_loop", {{"path", "sounds/a.wav"}, {"kind", "noise"}}).ok);
    CHECK_FALSE(p.call("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "noise"}, {"color", "grey"}}).ok);
    CHECK_FALSE(p.call("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "noise"}, {"seconds", 500}}).ok);
    CHECK_FALSE(p.call("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "noise"}, {"level", 0}}).ok);  // silence
    CommandResult mixed = p.call("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "noise"}, {"chords", Json::array({Json::array({"A3"})})}});
    REQUIRE_FALSE(mixed.ok);
    CHECK(mixed.error["message"].get<std::string>().find("/chords") != std::string::npos);
    CHECK_FALSE(p.call("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "drone"}}).ok);  // no chords
    CommandResult note = p.call("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "drone"}, {"chords", Json::array({Json::array({"H3"})})}});
    REQUIRE_FALSE(note.ok);
    CHECK(note.error["message"].get<std::string>().find("/chords/0/0") != std::string::npos);
    CHECK_FALSE(p.call("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "drone"}, {"chords", Json::array({Json::array({"A3"})})}, {"chordSeconds", 2}, {"seconds", 7}}).ok);
    CHECK_FALSE(p.call("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "noise"}, {"cutof", 100}}).ok);  // unknown key
    CHECK_FALSE(p.exists("assets/a.wav"));
    p.ok("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "noise"}, {"seconds", 1}});
    CHECK(p.call("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "noise"}}).error["code"] == "exists");
    p.ok("assets.generate_loop", {{"path", "assets/a.wav"}, {"kind", "noise"}, {"seconds", 1}, {"overwrite", true}});
}

TEST_CASE("assets.convert_audio: a WAV becomes a smaller Ogg of the same length, with the provenance carried over") {
    AssetsProject p;
    p.ok("assets.generate_loop", {{"path", "assets/audio/rain.wav"}, {"kind", "noise"}, {"color", "pink"}, {"cutoff", 4000}, {"seconds", 5}, {"seed", 2}});
    const std::string wav = read_all(p.file("assets/audio/rain.wav"));
    const Json r = p.ok("assets.convert_audio", {{"path", "assets/audio/rain.wav"}});
    CHECK(r["path"] == "assets/audio/rain.ogg");
    const std::string ogg = read_all(p.file("assets/audio/rain.ogg"));
    CHECK(ogg.substr(0, 4) == "OggS");
    CHECK(ogg.size() < wav.size() / 2);
    CHECK(read_all(p.file("assets/audio/rain.wav")) == wav);  // the WAV stays
    auto lw = measure_loudness({reinterpret_cast<const std::uint8_t*>(wav.data()), wav.size()}, ".wav");
    auto lo = measure_loudness({reinterpret_cast<const std::uint8_t*>(ogg.data()), ogg.size()}, ".ogg");
    REQUIRE((lw.ok() && lo.ok()));
    CHECK(lo->seconds == doctest::Approx(lw->seconds).epsilon(0.001));
    CHECK(lo->integratedLufs == doctest::Approx(lw->integratedLufs).epsilon(0.05));

    const Json prov = p.manifest()["assets"]["assets/audio/rain.ogg"]["provenance"];
    CHECK(prov["origin"] == "original");
    CHECK(prov["seed"] == 2);
    CHECK(prov["notes"].get<std::string>().find("Converted from assets/audio/rain.wav") != std::string::npos);

    CHECK(p.call("assets.convert_audio", {{"path", "assets/audio/rain.wav"}}).error["code"] == "exists");
    p.ok("assets.convert_audio", {{"path", "assets/audio/rain.wav"}, {"to", "assets/music/rain_hq.ogg"}, {"quality", 1.0}});
    CHECK(read_all(p.file("assets/music/rain_hq.ogg")).size() > ogg.size());
    CHECK_FALSE(p.call("assets.convert_audio", {{"path", "assets/audio/none.wav"}}).ok);
    CHECK_FALSE(p.call("assets.convert_audio", {{"path", "assets/audio/rain.ogg"}, {"to", "assets/x.ogg"}}).ok);  // not a WAV
    CHECK_FALSE(p.call("assets.convert_audio", {{"path", "assets/audio/rain.wav"}, {"to", "assets/x.mp3"}}).ok);
    CHECK_FALSE(p.call("assets.convert_audio", {{"path", "assets/audio/rain.wav"}, {"quality", 2}}).ok);
    write_all(p.file("assets/audio/bad.wav"), "not a wav");
    CommandResult bad = p.call("assets.convert_audio", {{"path", "assets/audio/bad.wav"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("WAV") != std::string::npos);
    CHECK_FALSE(p.exists("assets/audio/bad.ogg"));
}
