// The song mixer and the instruments (M56.2): the instrument library at its calibrated levels, the drum kits, voices (polyphony, release,
// steals, hat choke), velocity, pitch, the mixer document (parse errors, sends and buses, mute and solo, pan law), the master (limiter and
// loudness normalization) and SoundFont instruments, with a tiny SF2 built in this file (no binary from anywhere).
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <map>
#include <numbers>
#include <set>
#include <string>
#include <vector>

#include "tiny_sf2.h"
#include "fa/audio/song.h"
#include "fa/audio/song_check.h"
#include "fa/audio/song_instruments.h"
#include "fa/audio/song_preview.h"
#include "fa/audio/song_theory.h"
#include "fa/audio/soundfont.h"
#include "fa/core/fs.h"

using namespace fa;
using fa::testing::tiny_sf2;

namespace {

// ---- helpers -----------------------------------------------------------------------------------------------------------

struct T {
    std::string name, instrument, notes;
};

// A song with one track per entry, each playing its pattern once; no master level changes (loudness off, volume 1) so what a track
// plays is what is measured.
Json song_of(const std::vector<T>& tracks, double tempo = 120.0) {
    Json j = Json::parse(R"({"format": "factoria.song/1", "tracks": {}, "sections": [{"name": "main", "play": {}}]})");
    j["tempo"] = tempo;
    j["volume"] = 1.0;
    j["mixer"] = Json{{"master", Json{{"loudness", "off"}}}};
    for (const T& t : tracks) {
        j["tracks"][t.name] = {{"instrument", t.instrument}, {"patterns", {{"a", t.notes}}}};
        j["sections"][0]["play"][t.name] = "a";
    }
    return j;
}

Json drums_song(const Json& instrument, const Json& grid, double tempo = 120.0) {
    Json j = Json::parse(
        R"({"format": "factoria.song/1", "tracks": {}, "sections": [{"name": "main", "play": {"d": "g"}}]})");
    j["tempo"] = tempo;
    j["volume"] = 1.0;
    j["mixer"] = Json{{"master", Json{{"loudness", "off"}}}};
    j["tracks"]["d"] = {{"instrument", instrument}, {"patterns", {{"g", {{"grid", grid}}}}}};
    return j;
}

SongDoc parsed(const Json& j) {
    std::vector<SongIssue> issues;
    auto r = parse_song(j, "test.song.json", &issues);
    INFO((r ? std::string() : r.error().message));
    REQUIRE(bool(r));
    return *r;
}

std::vector<SongIssue> issues_of(const Json& j) {
    std::vector<SongIssue> issues;
    auto r = parse_song(j, "test.song.json", &issues);
    CHECK_FALSE(bool(r));
    return issues;
}

const SongIssue* issue_at(const std::vector<SongIssue>& issues, const std::string& pointer) {
    for (const SongIssue& i : issues)
        if (i.pointer == pointer) return &i;
    return nullptr;
}

Result<SongRender> try_render(const Json& j, int rate = 44100, std::uint64_t seed = 0) {
    SongDoc s = parsed(j);
    auto t = expand_song(s);
    REQUIRE(bool(t));
    SongRenderOptions o;
    o.sampleRate = rate;
    o.seed = seed;
    return render_song(s, *t, o);
}

SongRender render(const Json& j, int rate = 44100) {
    auto r = try_render(j, rate);
    INFO((r ? std::string() : r.error().message));
    REQUIRE(bool(r));
    return *r;
}

double channel_energy(const SongRender& r, int channel, double from = 0.0, double to = 1e9) {
    const std::size_t n = r.clip.frames();
    const std::size_t a = std::min(n, std::size_t(from * r.clip.sampleRate)),
                      b = std::min(n, std::size_t(to * r.clip.sampleRate));
    double e = 0.0;
    for (std::size_t i = a; i < b; ++i) {
        const double v = r.clip.samples[i * 2 + std::size_t(channel)];
        e += v * v;
    }
    return e;
}
double energy(const SongRender& r, double from = 0.0, double to = 1e9) {
    return channel_energy(r, 0, from, to) + channel_energy(r, 1, from, to);
}

double amplitude_at(const SongRender& r, double hz, double from, double to) {
    const std::size_t n = r.clip.frames();
    const std::size_t a = std::min(n, std::size_t(from * r.clip.sampleRate)),
                      b = std::min(n, std::size_t(to * r.clip.sampleRate));
    double re = 0.0, im = 0.0;
    for (std::size_t i = a; i < b; ++i) {
        const double ph = 2.0 * std::numbers::pi * hz * double(i) / double(r.clip.sampleRate);
        const double v = 0.5 * (double(r.clip.samples[i * 2]) + double(r.clip.samples[i * 2 + 1]));
        re += v * std::cos(ph);
        im += v * std::sin(ph);
    }
    return 2.0 * std::sqrt(re * re + im * im) / double(std::max<std::size_t>(1, b - a));
}

// The pitch of the render by autocorrelation of the left channel between `from` and `to` seconds.
double estimate_hz(const SongRender& r, double from, double to) {
    const int rate = r.clip.sampleRate;
    std::vector<double> x;
    for (std::size_t i = std::size_t(from * rate); i < std::min(r.clip.frames(), std::size_t(to * rate)); ++i)
        x.push_back(r.clip.samples[i * 2]);
    const int minLag = rate / 2200, maxLag = rate / 60;
    std::vector<double> corr;
    double best = -1e30;
    for (int lag = minLag; lag <= maxLag && std::size_t(lag) < x.size() / 2; ++lag) {
        double c = 0.0, e = 0.0;
        for (std::size_t i = 0; i + std::size_t(lag) < x.size(); ++i) {
            c += x[i] * x[i + std::size_t(lag)];
            e += x[i] * x[i] + x[i + std::size_t(lag)] * x[i + std::size_t(lag)];
        }
        corr.push_back(e > 0 ? 2.0 * c / e : 0.0);
        best = std::max(best, corr.back());
    }
    // the first local peak that is nearly as high as the best one: a later peak is a multiple of the period
    int bestLag = minLag;
    for (std::size_t k = 1; k + 1 < corr.size(); ++k)
        if (corr[k] >= 0.9 * best && corr[k] >= corr[k - 1] && corr[k] >= corr[k + 1]) {
            bestLag = minLag + int(k);
            break;
        }
    return double(rate) / double(bestLag);
}

double midi_hz(int note) { return 440.0 * std::pow(2.0, (note - 69) / 12.0); }

// the tiny SoundFont comes from tiny_sf2.h

// A project folder in the temp dir; the project root is it while the fixture lives.
struct Project {
    std::filesystem::path dir;
    Project() {
        dir = fs::make_temp_dir("factoria_song_mixer_test").value();
        fs::set_project_root(dir);
    }
    ~Project() { std::filesystem::remove_all(dir); }
    void bytes(const std::string& rel, const std::vector<std::uint8_t>& data) {
        REQUIRE(fs::write_bytes(rel, data.data(), data.size()).ok());
    }
    void text(const std::string& rel, const std::string& body) { REQUIRE(fs::write_text(rel, body).ok()); }
};

}  // namespace

// ---- the instrument library --------------------------------------------------------------------------------------------

TEST_CASE(
    "instruments: the library has every family, each instrument says what it is and has a range and a polyphony") {
    const auto& families = song_instrument_families();
    std::set<std::string> familyNames;
    for (const SongInstrumentFamily& f : families) {
        familyNames.insert(f.name);
        CHECK_FALSE(f.what.empty());
    }
    for (const char* want : {"keys", "pluck", "bass", "lead", "pad", "bell", "ensemble", "chiptune"})
        CHECK_MESSAGE(familyNames.count(want) == 1, want);
    std::set<std::string> names;
    std::set<std::string> used;
    for (const SongInstrumentInfo& i : song_instruments()) {
        CHECK_MESSAGE(names.insert(i.name).second, "duplicate " << i.name);
        CHECK_MESSAGE(familyNames.count(i.family) == 1, i.name << " is in the unknown family " << i.family);
        CHECK_MESSAGE(i.what.size() > 20, i.name);
        CHECK_MESSAGE(i.low < i.high, i.name);
        CHECK_MESSAGE(i.voices >= 1, i.name);
        CHECK(song_instrument_voices(i.name) == i.voices);
        used.insert(i.family);
    }
    CHECK(names.size() >= 40);
    CHECK(used == familyNames);  // no family without an instrument
    CHECK(song_kits().size() == 3);
    CHECK(song_kit_variant("kit") == "acoustic");
    CHECK(song_kit_variant("kit:electronic") == "electronic");
    CHECK(song_kit_variant("kit:chiptune") == "chiptune");
    CHECK_FALSE(song_kit_variant("kit:jazz").has_value());
    CHECK_FALSE(song_kit_variant("pad").has_value());
}

TEST_CASE(
    "instruments: every pitched instrument plays its C4 at the calibrated level and stays near it across its range") {
    for (const SongInstrumentInfo& i : song_instruments()) {
        const double ref = render(song_of({{"t", i.name, "v100 C4:2 r:2"}})).clip.peakDb;
        CHECK_MESSAGE(std::abs(ref + 12.0) < 0.7, i.name << " C4 peaks at " << ref << " dBFS, not -12");
        for (int note : {i.low, i.high}) {
            const std::string text = "v100 " + song_pitch_name(note) + ":2 r:2";
            const double edge = render(song_of({{"t", i.name, text}})).clip.peakDb;
            CHECK_MESSAGE(edge > -21.0, i.name << " at " << song_pitch_name(note) << " is too quiet: " << edge);
            CHECK_MESSAGE(edge < -5.0, i.name << " at " << song_pitch_name(note) << " is too loud: " << edge);
        }
    }
}

TEST_CASE("instruments: the same song renders to the same samples, and another seed changes only what is random") {
    const Json j = song_of({{"a", "lead_acid", "C3:8 E3 G3 C4 r:2"},
                            {"b", "choir", "[C4 E4 G4]:2 r:2"},
                            {"c", "chip_noise", "C4:4 C4 r:2"}});
    const SongRender a = render(j), b = render(j);
    CHECK(a.clip.samples == b.clip.samples);
}

TEST_CASE("instruments: a note plays at the pitch it names, an octave apart doubles the frequency") {
    for (const std::string name : {"chip_triangle", "chip_square", "lead_saw", "pluck", "flute", "lead"}) {
        for (int note : {48, 60, 69, 76}) {
            const SongRender r = render(song_of({{"t", name, "v100 " + song_pitch_name(note) + ":2 r:2"}}));
            const double hz = estimate_hz(r, 0.1, 0.4);
            CHECK_MESSAGE(hz == doctest::Approx(midi_hz(note)).epsilon(0.03),
                          name << " " << song_pitch_name(note) << " measured " << hz);
        }
    }
}

TEST_CASE("instruments: a saw lead at a high pitch keeps its energy on the harmonics, not between them (no aliasing)") {
    const int note = 86;  // D6, 1174.7 Hz
    const double f0 = midi_hz(note);
    const SongRender r = render(song_of({{"t", "lead_saw", "v100 " + song_pitch_name(note) + ":1"}}));
    double harmonic = 0.0, between = 0.0;
    for (int n = 1; n <= 8; ++n) {
        harmonic += amplitude_at(r, f0 * n, 0.15, 0.45);
        between += amplitude_at(r, f0 * (n + 0.5), 0.15, 0.45);
    }
    CHECK(between < harmonic * 0.1);
}

TEST_CASE("instruments: velocity scales the level on the (v/100)^1.25 curve and brightens a played note") {
    const double loud = render(song_of({{"t", "chip_square", "v100 C4:1"}})).clip.peakDb;
    const double soft = render(song_of({{"t", "chip_square", "v50 C4:1"}})).clip.peakDb;
    CHECK(loud - soft == doctest::Approx(-20.0 * 1.25 * std::log10(0.5)).epsilon(0.05));
    const double quiet = render(song_of({{"t", "lead_saw", "v30 C4:1"}})).clip.peakDb;
    const double hard = render(song_of({{"t", "lead_saw", "v120 C4:1"}})).clip.peakDb;
    CHECK(hard > quiet + 10.0);
    // A hard note has more high partials than a soft one, relative to its fundamental.
    auto color = [&](const char* v) {
        const SongRender r = render(song_of({{"t", "lead_saw", std::string(v) + " C4:1"}}));
        return amplitude_at(r, midi_hz(60) * 6.0, 0.1, 0.4) / amplitude_at(r, midi_hz(60), 0.1, 0.4);
    };
    CHECK(color("v120") > color("v40"));
}

// ---- voices ------------------------------------------------------------------------------------------------------------

TEST_CASE("voices: a released note keeps ringing for its release, and a pad rings longer than a pluck") {
    const SongRender pad = render(song_of({{"t", "pad", "C4:4 r:2 r:4"}}));
    const SongRender pluck = render(song_of({{"t", "pluck_soft", "C4:4' r:2 r:4"}}));
    // the first quarter note ends at 0.5 s: the pad is still sounding after it
    CHECK(energy(pad, 0.55, 0.8) > 0.0);
    CHECK(energy(pad, 0.55, 0.8) / energy(pad, 0.1, 0.45) > 0.05);
    // and a release longer than the note lasts to its end instead of being cut at the note-off
    CHECK(pad.clip.seconds() > pad.seconds + 0.5);
    CHECK(energy(pluck, 0.9, 1.4) < energy(pluck, 0.0, 0.5) * 0.01);
}

TEST_CASE("voices: a new note cuts the oldest voice past the limit; a chord is never cut by its own notes") {
    const std::string notes = "C4:4 E4:4 G4:4 B4:4";
    Json many = song_of({{"t", "pad_dark", notes}});
    Json one = many;
    one["tracks"]["t"]["voices"] = 1;
    const SongRender a = render(many), b = render(one);
    // with one voice every note replaces the one before it, so the long releases do not pile up
    CHECK(energy(b, 1.0, 2.0) < energy(a, 1.0, 2.0) * 0.8);
    // a chord of five notes on a track limited to two voices still plays in full
    Json chord = song_of({{"t", "pad", "[C4 E4 G4 B4 D5]:1"}});
    Json chordLimited = chord;
    chordLimited["tracks"]["t"]["voices"] = 2;
    const SongRender c = render(chord), d = render(chordLimited);
    CHECK(c.clip.samples == d.clip.samples);
    // the track report counts the notes played
    CHECK(c.tracks.size() == 1);
    CHECK(c.tracks[0].notes == 5);
    CHECK(c.tracks[0].name == "t");
}

TEST_CASE("voices: the same key struck again replaces the ringing note instead of doubling it") {
    const Json j = song_of({{"t", "bell", "C5:4 C5:4 C5:4 C5:4"}});
    const SongRender r = render(j);
    // four retriggers of the same bell never get louder than the first strike by more than the overlap of a single tail
    CHECK(r.clip.peakDb < -9.0);
    CHECK(r.notes == 4);
}

TEST_CASE("drum kit: every variant has every lane, each lane renders at a sensible level, and a later hat chokes an "
          "open hat") {
    std::set<std::string> lanes;
    for (const SongDrumLane& l : song_drum_lanes()) lanes.insert(l.name);
    CHECK(lanes.size() == 15);
    for (const char* want : {"kick", "snare", "clap", "rim", "hat", "openhat", "hat_pedal", "shaker", "tambourine",
                             "tom_low", "tom_mid", "tom_high", "ride", "crash", "cowbell"})
        CHECK_MESSAGE(lanes.count(want) == 1, want);
    std::map<std::string, std::vector<float>> kicks;
    for (const char* kit : {"kit", "kit:electronic", "kit:chiptune"}) {
        std::map<std::string, double> level;
        for (const std::string& lane : lanes) {
            Json grid = Json::object();
            grid[lane] = "x...............";
            const SongRender r = render(drums_song(kit, grid));
            level[lane] = r.clip.peakDb;
            CHECK_MESSAGE(r.clip.peakDb > -25.0, kit << " " << lane << " " << r.clip.peakDb);
            CHECK_MESSAGE(r.clip.peakDb < -3.0, kit << " " << lane << " " << r.clip.peakDb);
            if (lane == "kick") kicks[kit] = r.clip.samples;
        }
        if (std::string(kit) != "kit:chiptune") {
            CHECK_MESSAGE(level["kick"] > level["hat"] + 3.0, kit);
            CHECK_MESSAGE(level["snare"] > level["hat"] + 3.0, kit);
        }
    }
    CHECK(kicks["kit"] != kicks["kit:electronic"]);
    CHECK(kicks["kit"] != kicks["kit:chiptune"]);
    CHECK(kicks["kit:electronic"] != kicks["kit:chiptune"]);

    // Choke: an open hat rings for about a quarter second; a closed hat struck at 0.125 s (step 1 of 16 at 120 bpm) cuts it short.
    const SongRender ring = render(drums_song("kit", Json::object({{"openhat", "x..............."}})));
    const SongRender hatOnly = render(drums_song("kit", Json::object({{"hat", ".x.............."}})));
    const SongRender cut =
        render(drums_song("kit", Json::object({{"openhat", "x..............."}, {"hat", ".x.............."}})));
    REQUIRE(cut.clip.samples.size() == hatOnly.clip.samples.size());
    auto window = [&](const SongRender& r, double from, double to) { return energy(r, from, to); };
    // what the open hat still adds after the closed hat: the difference between both together and the closed hat alone
    SongRender rest = cut;
    for (std::size_t i = 0; i < rest.clip.samples.size(); ++i) rest.clip.samples[i] -= hatOnly.clip.samples[i];
    CHECK(window(ring, 0.17, 0.5) > 0.0);
    CHECK(window(rest, 0.17, 0.5) < window(ring, 0.17, 0.5) * 0.2);
    // before the hat the open hat plays as it does alone
    CHECK(window(cut, 0.0, 0.12) == doctest::Approx(window(ring, 0.0, 0.12)).epsilon(0.001));
}

TEST_CASE("drum kit: a kit track names its variant and a lane can be replaced by a patch of the song") {
    CHECK(parsed(drums_song("kit:electronic", Json{{"kick", "x..............."}})).tracks[0].drums);
    auto issues = issues_of(drums_song("kit:jazz", Json{{"kick", "x..............."}}));
    const SongIssue* i = issue_at(issues, "/tracks/d/instrument");
    REQUIRE(i != nullptr);
    CHECK(i->hint.find("electronic") != std::string::npos);
}

// ---- the mixer: parse --------------------------------------------------------------------------------------------------

TEST_CASE("mixer: a full mixer parses into the document, with defaults for what is left out") {
    Json j = song_of({{"lead", "lead", "C4:2 r:2"}, {"pad", "pad", "C3:1"}});
    j["mixer"] = Json::parse(R"({
      "buses": {"hall": {"volume": 0.8, "pan": -0.2, "effects": [{"type": "reverb", "decay": 2.0, "mix": 1}]},
                "echo": {"effects": [{"type": "delay", "time": 0.25, "feedback": 0.4, "mix": 1}], "mute": true}},
      "master": {"effects": [{"type": "eq", "bands": [{"type": "highShelf", "freq": 9000, "gainDb": -2}]}], "limiter": {"ceilingDb": -2, "release": 0.2}, "loudness": -18}
    })");
    j["tracks"]["lead"]["sends"] = Json{{"hall", 0.3}, {"echo", 0.2}};
    j["tracks"]["lead"]["effects"] = Json::parse(R"([{"type": "distortion", "drive": 4}])");
    j["tracks"]["lead"]["mute"] = false;
    j["tracks"]["lead"]["solo"] = true;
    j["tracks"]["lead"]["voices"] = 4;
    const SongDoc s = parsed(j);
    REQUIRE(s.mixer.buses.size() == 2);
    const SongBus* hall = s.mixer.find_bus("hall");
    REQUIRE(hall != nullptr);
    CHECK(hall->volume == doctest::Approx(0.8));
    CHECK(hall->pan == doctest::Approx(-0.2));
    CHECK(hall->effects.size() == 1);
    CHECK(s.mixer.find_bus("echo")->mute);
    CHECK(s.mixer.find_bus("nope") == nullptr);
    CHECK(s.mixer.master.effects.size() == 1);
    CHECK(s.mixer.master.limiter);
    CHECK(s.mixer.master.ceilingDb == doctest::Approx(-2.0));
    CHECK(s.mixer.master.limiterRelease == doctest::Approx(0.2));
    CHECK(s.mixer.master.loudness == SongMaster::Loudness::Target);
    CHECK(s.mixer.master.loudnessLufs == doctest::Approx(-18.0));
    const SongTrack* lead = s.find_track("lead");
    REQUIRE(lead != nullptr);
    CHECK(lead->solo);
    CHECK_FALSE(lead->mute);
    CHECK(lead->voices == 4);
    CHECK(lead->effects.size() == 1);
    CHECK(lead->sends.at("hall") == doctest::Approx(0.3));
    // no mixer: the defaults are a limiter at -1 dBFS and the style's loudness
    const SongDoc plain = parsed(Json::parse(
        R"({"format": "factoria.song/1", "tracks": {"a": {"instrument": "pad", "patterns": {"p": "C4:1"}}}, "sections": [{"name": "m", "play": {"a": "p"}}]})"));
    CHECK(plain.mixer.buses.empty());
    CHECK(plain.mixer.master.limiter);
    CHECK(plain.mixer.master.ceilingDb == doctest::Approx(-1.0));
    CHECK(plain.mixer.master.loudness == SongMaster::Loudness::Style);
    CHECK(parsed(song_of({{"a", "pad", "C4:1"}})).mixer.master.loudness == SongMaster::Loudness::Off);
}

TEST_CASE(
    "mixer: a mistake names its pointer, what is wrong and how to fix it, with a suggestion when a name is close") {
    auto base = [] { return song_of({{"lead", "lead", "C4:2 r:2"}}); };
    {
        Json j = base();
        j["mixer"] = Json{{"mastr", Json::object()}};
        const auto issues = issues_of(j);
        const SongIssue* i = issue_at(issues, "/mixer/mastr");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("master") != std::string::npos);
    }
    {
        Json j = base();
        j["mixer"] = Json{{"buses", Json{{"hall", Json{{"effects", Json::array({Json{{"type", "reverbb"}}})}}}}}};
        const auto issues = issues_of(j);
        const SongIssue* i = issue_at(issues, "/mixer/buses/hall/effects/0/type");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("reverb") != std::string::npos);
    }
    {
        Json j = base();
        j["mixer"] =
            Json{{"buses", Json{{"hall", Json{{"effects", Json::array({Json{{"type", "reverb"}, {"deccay", 2}}})}}}}}};
        const auto issues = issues_of(j);
        const SongIssue* i = issue_at(issues, "/mixer/buses/hall/effects/0/deccay");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("decay") != std::string::npos);
    }
    {
        Json j = base();
        j["mixer"] =
            Json{{"buses", Json{{"hall", Json{{"effects", Json::array({Json{{"type", "trim"}, {"start", 0}}})}}}}}};
        const auto issues = issues_of(j);
        const SongIssue* i = issue_at(issues, "/mixer/buses/hall/effects/0/type");
        REQUIRE(i != nullptr);
        CHECK(i->message.find("not an effect") != std::string::npos);
    }
    {
        Json j = base();
        j["mixer"] = Json{{"buses", Json{{"hall", Json::object()}}}};
        j["tracks"]["lead"]["sends"] = Json{{"hal", 0.3}};
        const auto issues = issues_of(j);
        const SongIssue* i = issue_at(issues, "/tracks/lead/sends/hal");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("hall") != std::string::npos);
        CHECK(i->hint[0] != ' ');
    }
    {
        Json j = base();
        j["tracks"]["lead"]["sends"] = Json{{"hall", 3.0}};
        j["mixer"] = Json{{"buses", Json{{"hall", Json::object()}}}};
        CHECK(issue_at(issues_of(j), "/tracks/lead/sends/hall") != nullptr);
    }
    {
        Json j = base();
        Json buses = Json::object();
        for (int i = 0; i < 9; ++i) buses["b" + std::to_string(i)] = Json::object();
        j["mixer"] = Json{{"buses", buses}};
        CHECK(issue_at(issues_of(j), "/mixer/buses") != nullptr);
    }
    {
        Json j = base();
        j["mixer"] = Json{{"master", Json{{"loudness", -3}}}};
        const std::vector<SongIssue> issues = issues_of(j);
        const SongIssue* i = issue_at(issues, "/mixer/master/loudness");
        REQUIRE(i != nullptr);
        CHECK_MESSAGE(i->message.find("-40 to -5") != std::string::npos, i->message);
    }
    {
        Json j = base();
        j["mixer"] = Json{{"master", Json{{"loudness", "loud"}}}};
        CHECK(issue_at(issues_of(j), "/mixer/master/loudness") != nullptr);
    }
    {
        Json j = base();
        j["mixer"] = Json{{"master", Json{{"limiter", "on"}}}};
        CHECK(issue_at(issues_of(j), "/mixer/master/limiter") != nullptr);
    }
    {
        Json j = base();
        j["mixer"] = Json{{"master", Json{{"limiter", Json{{"ceilingDb", 3}}}}}};
        CHECK(issue_at(issues_of(j), "/mixer/master/limiter/ceilingDb") != nullptr);
    }
    {
        Json j = base();
        j["mixer"] = Json{{"buses", Json{{"hall", Json{{"pan", 2}}}}}};
        CHECK(issue_at(issues_of(j), "/mixer/buses/hall/pan") != nullptr);
    }
    {
        Json j = base();
        j["tracks"]["lead"]["voices"] = 200;
        CHECK(issue_at(issues_of(j), "/tracks/lead/voices") != nullptr);
    }
    {
        Json j = base();
        Json fx = Json::array();
        for (int i = 0; i < 9; ++i) fx.push_back(Json{{"type", "eq"}});
        j["tracks"]["lead"]["effects"] = fx;
        CHECK(issue_at(issues_of(j), "/tracks/lead/effects") != nullptr);
    }
    {
        Json j = base();
        j["tracks"]["lead"]["solo"] = "yes";
        CHECK(issue_at(issues_of(j), "/tracks/lead/solo") != nullptr);
    }
    {
        Json j = base();
        j["tracks"]["lead"]["efects"] = Json::array();
        const std::vector<SongIssue> issues = issues_of(j);
        const SongIssue* i = issue_at(issues, "/tracks/lead/efects");
        REQUIRE(i != nullptr);
        CHECK_MESSAGE(i->hint.find("effects") != std::string::npos, i->hint);
    }
}

// ---- the mixer: sound --------------------------------------------------------------------------------------------------

TEST_CASE("mixer: pan keeps the power of a sound (constant-power law) and hard pan silences the other side") {
    auto at = [&](double pan) {
        Json j = song_of({{"t", "organ", "C4:1"}});
        j["tracks"]["t"]["pan"] = pan;
        return render(j);
    };
    const SongRender center = at(0.0), half = at(0.5), left = at(-1.0), right = at(1.0);
    const double total = energy(center);
    CHECK(energy(half) == doctest::Approx(total).epsilon(0.02));
    CHECK(energy(left) == doctest::Approx(total).epsilon(0.02));
    CHECK(energy(right) == doctest::Approx(total).epsilon(0.02));
    CHECK(channel_energy(left, 1) < total * 1e-6);
    CHECK(channel_energy(right, 0) < total * 1e-6);
    CHECK(channel_energy(center, 0) == doctest::Approx(channel_energy(center, 1)).epsilon(0.001));
    CHECK(channel_energy(half, 1) > channel_energy(half, 0) * 2.0);
}

TEST_CASE("mixer: volume is the fader, mute silences a track and solo leaves only the soloed ones") {
    Json j = song_of({{"a", "organ", "C4:1"}, {"b", "organ", "E4:1"}});
    const SongRender both = render(j);
    CHECK(both.tracks.size() == 2);
    Json quiet = j;
    quiet["tracks"]["a"]["volume"] = 0.5;
    quiet["tracks"]["b"]["volume"] = 0.5;
    CHECK(render(quiet).clip.peakDb == doctest::Approx(both.clip.peakDb - 6.02).epsilon(0.03));
    Json muted = j;
    muted["tracks"]["b"]["mute"] = true;
    const SongRender m = render(muted);
    REQUIRE(m.tracks.size() == 1);
    CHECK(m.tracks[0].name == "a");
    Json solo = j;
    solo["tracks"]["b"]["solo"] = true;
    const SongRender s = render(solo);
    REQUIRE(s.tracks.size() == 1);
    CHECK(s.tracks[0].name == "b");
    CHECK(m.clip.samples != s.clip.samples);
    // a track that is both muted and soloed is silent
    Json both2 = j;
    both2["tracks"]["b"]["solo"] = true;
    both2["tracks"]["b"]["mute"] = true;
    const SongRender silent = render(both2);
    CHECK(silent.tracks.empty());
    CHECK(silent.clip.peakDb < -100.0);
}

TEST_CASE(
    "mixer: a track's insert effects change its sound, a bus effect is only the effect and a send adds it to the mix") {
    Json plain = song_of({{"t", "keys", "C4:4 r r r"}});
    Json filtered = plain;
    filtered["tracks"]["t"]["effects"] = Json::parse(R"([{"type": "filter", "mode": "lowpass", "cutoff": 300}])");
    const SongRender a = render(plain), b = render(filtered);
    CHECK(a.clip.samples != b.clip.samples);
    CHECK(amplitude_at(b, midi_hz(60) * 6.0, 0.05, 0.4) < amplitude_at(a, midi_hz(60) * 6.0, 0.05, 0.4) * 0.5);

    // a reverb bus: the first milliseconds are the dry track alone, the sound goes on after the track and the file grows by the tail
    Json send = plain;
    send["mixer"]["buses"] =
        Json::parse(R"({"hall": {"effects": [{"type": "reverb", "decay": 2.5, "mix": 1, "preDelay": 0.03}]}})");
    send["tracks"]["t"]["sends"] = Json{{"hall", 1.0}};
    const SongRender dry = render(plain), wet = render(send);
    const std::size_t early = std::size_t(0.025 * 44100);
    double worst = 0.0;
    for (std::size_t i = 0; i < early * 2; ++i)
        worst = std::max(worst, double(std::abs(dry.clip.samples[i] - wet.clip.samples[i])));
    CHECK(worst < 1e-4);  // a bus that passed the dry sound too would be twice as loud here
    CHECK(energy(wet, 1.5, 3.0) > energy(dry, 1.5, 3.0) * 4.0 + 1e-9);
    CHECK(wet.clip.seconds() > dry.clip.seconds() + 0.5);
    // a muted bus plays nothing, and the send level scales the wet sound
    Json mutedBus = send;
    mutedBus["mixer"]["buses"]["hall"]["mute"] = true;
    const SongRender silentBus = render(mutedBus);
    REQUIRE(silentBus.clip.samples.size() >= dry.clip.samples.size());
    CHECK(std::equal(dry.clip.samples.begin(), dry.clip.samples.end(), silentBus.clip.samples.begin()));
    CHECK(energy(silentBus, dry.clip.seconds()) == 0.0);
    Json lowSend = send;
    lowSend["tracks"]["t"]["sends"]["hall"] = 0.25;
    const SongRender low = render(lowSend);
    CHECK(energy(low, 1.5, 3.0) < energy(wet, 1.5, 3.0));
    CHECK(energy(low, 1.5, 3.0) > energy(dry, 1.5, 3.0));
    // master effects run on the sum
    Json masterFx = plain;
    masterFx["mixer"]["master"]["effects"] = Json::parse(R"([{"type": "filter", "mode": "lowpass", "cutoff": 300}])");
    CHECK(amplitude_at(render(masterFx), midi_hz(60) * 6.0, 0.05, 0.4) <
          amplitude_at(a, midi_hz(60) * 6.0, 0.05, 0.4) * 0.5);
}

TEST_CASE("mixer: the render reports each track's level and the master's work") {
    Json j = song_of({{"a", "organ", "C4:1"}, {"b", "bass", "C2:1"}});
    j["tracks"]["b"]["volume"] = 0.25;
    const SongRender r = render(j);
    REQUIRE(r.tracks.size() == 2);
    CHECK(r.tracks[0].notes == 1);
    CHECK(r.tracks[0].peakDb > r.tracks[1].peakDb + 6.0);
    CHECK(r.tracks[0].lufs > r.tracks[1].lufs);
    CHECK(r.master.limiter);
    CHECK(r.master.ceilingDb == doctest::Approx(-1.0));
    CHECK_FALSE(r.master.targetLufs.has_value());
    CHECK(r.master.normalizeGainDb == doctest::Approx(0.0));
    CHECK(r.master.limiterReductionDb == doctest::Approx(0.0));
}

// ---- the master --------------------------------------------------------------------------------------------------------

TEST_CASE(
    "master: the limiter keeps every sample under its ceiling, however hot the mix, and reports how hard it worked") {
    std::vector<T> loud;
    for (int i = 0; i < 8; ++i) loud.push_back({"t" + std::to_string(i), "organ", "[C3 E3 G3]:1"});
    Json j = song_of(loud);
    for (auto& kv : j["tracks"].items()) kv.value()["volume"] = 2.0;
    j["mixer"]["master"]["limiter"] = false;
    const SongRender raw = render(j);
    CHECK(raw.clip.peakDb > 3.0);  // it clips without the limiter
    CHECK_FALSE(raw.master.limiter);
    for (double ceiling : {-1.0, -3.0, -6.0}) {
        Json limited = j;
        limited["mixer"]["master"]["limiter"] = Json{{"ceilingDb", ceiling}};
        const SongRender r = render(limited);
        CHECK_MESSAGE(r.clip.peakDb <= ceiling + 0.01, "ceiling " << ceiling << " peak " << r.clip.peakDb);
        CHECK(r.clip.peakDb > ceiling - 3.0);  // it does not squash far below the ceiling
        CHECK(r.master.limiter);
        CHECK(r.master.ceilingDb == doctest::Approx(ceiling));
        CHECK(r.master.limiterReductionDb > 3.0);
        for (float v : r.clip.samples) REQUIRE(std::abs(double(v)) <= std::pow(10.0, ceiling / 20.0) + 1e-6);
    }
    // a quiet song is left alone
    Json quiet = song_of({{"t", "organ", "C4:1"}});
    const SongRender q = render(quiet);
    CHECK(q.master.limiterReductionDb == doctest::Approx(0.0));
}

TEST_CASE("master: the loudness is brought to the target of the style, a number of LUFS, or left alone") {
    const Json base =
        song_of({{"pad", "pad", "[C3 G3 E4]:1 [F3 A3 C4]:1"}, {"lead", "lead", "E5:4 G5 C6 G5 | F5:4 A5 C6 A5"}});
    const SongRender off = render(base);
    CHECK_FALSE(off.master.targetLufs.has_value());
    for (double target : {-14.0, -20.0, -26.0}) {
        Json number = base;
        number["mixer"]["master"]["loudness"] = target;
        const SongRender r = render(number);
        CHECK_MESSAGE(r.clip.lufs == doctest::Approx(target).epsilon(0.02),
                      "target " << target << " got " << r.clip.lufs);
        CHECK(r.master.targetLufs == target);
        CHECK(r.master.normalizeGainDb == doctest::Approx(target - off.clip.lufs).epsilon(0.1));
    }
    // "style" takes the target from the render options, as music.preview does from the project's style guide
    Json style = base;
    style["mixer"]["master"]["loudness"] = "style";
    SongDoc s = parsed(style);
    auto tl = expand_song(s);
    REQUIRE(bool(tl));
    SongRenderOptions o;
    o.targetLufs = -22.0;
    auto r = render_song(s, *tl, o);
    REQUIRE(bool(r));
    CHECK(r->clip.lufs == doctest::Approx(-22.0).epsilon(0.02));
    CHECK(r->master.targetLufs == -22.0);
    // without a style target "style" leaves the level as the mix adds up to
    auto none = render_song(s, *tl, SongRenderOptions{});
    REQUIRE(bool(none));
    CHECK(none->clip.lufs == doctest::Approx(off.clip.lufs).epsilon(0.001));
    CHECK_FALSE(none->master.targetLufs.has_value());
    // a target the limiter prevents reaching ends under it, never over the ceiling
    Json hot = base;
    hot["mixer"]["master"]["loudness"] = -6.0 - 0.0;
    hot["mixer"]["master"]["loudness"] = -8.0;
    const SongRender h = render(hot);
    CHECK(h.clip.peakDb <= -0.99);
}

TEST_CASE("check loudness: the report follows the mixer, a song that normalizes itself is not flagged") {
    Json j = song_of({{"pad", "pad", "[C3 G3 E4]:1"}});
    j["mixer"]["master"]["loudness"] = -20.0;
    SongDoc s = parsed(j);
    auto tl = expand_song(s);
    REQUIRE(bool(tl));
    SongCheckOptions o;
    o.rules = {"loudness"};
    o.targetLufs = -20.0;
    o.sampleRate = 22050;
    auto report = check_song(s, *tl, o);
    REQUIRE(bool(report));
    CHECK(report->rendered);
    CHECK(report->lufs == doctest::Approx(-20.0).epsilon(0.02));
    CHECK(report->issues.empty());
}

// ---- SoundFont ---------------------------------------------------------------------------------------------------------

TEST_CASE("soundfont: a file lists its presets, finds one by name or number, and says what to do when it cannot") {
    const auto bytes = tiny_sf2();
    auto font = Soundfont::from_memory(bytes, "tiny.sf2");
    REQUIRE_MESSAGE(font.ok(), (font.ok() ? "" : font.error().message));
    REQUIRE(font->presets().size() == 3);
    CHECK(font->presets()[0].name == "Test Sine");
    CHECK(font->presets()[1].program == 5);
    CHECK(font->presets()[2].bank == 128);
    CHECK(*font->find_preset("Test Sine") == 0);
    CHECK(*font->find_preset("test sine two") == 1);
    CHECK(*font->find_preset(0, 5) == 1);
    CHECK(*font->find_preset(128, 0) == 2);
    auto missing = font->find_preset("Test Sin");
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("Test Sin") != std::string::npos);
    CHECK(missing.error().hint.find("Test Sine") != std::string::npos);
    auto badNumber = font->find_preset(0, 99);
    REQUIRE_FALSE(badNumber.ok());
    CHECK_FALSE(badNumber.error().hint.empty());

    auto notFont = Soundfont::from_memory(std::vector<std::uint8_t>{'h', 'e', 'l', 'l', 'o', 'h', 'e', 'l', 'l', 'o',
                                                                    'h', 'e', 'l', 'l', 'o', 'h', 'e', 'l', 'l', 'o'},
                                          "x.sf2");
    REQUIRE_FALSE(notFont.ok());
    CHECK(notFont.error().message.find("x.sf2") != std::string::npos);
    CHECK_FALSE(notFont.error().hint.empty());
    CHECK_FALSE(Soundfont::from_memory({}, "empty.sf2").ok());
    std::vector<std::uint8_t> cut(bytes.begin(), bytes.begin() + 120);
    CHECK_FALSE(Soundfont::from_memory(cut, "cut.sf2").ok());
}

TEST_CASE("soundfont: a preset renders the note's pitch deterministically, held then released") {
    auto font = Soundfont::from_memory(tiny_sf2(), "tiny.sf2");
    REQUIRE(font.ok());
    const int rate = 44100;
    auto play = [&](int key) {
        std::vector<double> l, r;
        SoundfontNote n;
        n.key = key;
        n.velocity = 100.0f / 127.0f;
        n.heldFrames = rate / 2;
        auto ok = font->render(0, rate, {n}, std::size_t(rate), l, r);
        REQUIRE_MESSAGE(ok.ok(), (ok.ok() ? "" : ok.error().message));
        return std::pair{l, r};
    };
    auto crossings = [&](const std::vector<double>& x, double t0, double t1) {
        int n = 0;
        for (std::size_t i = std::size_t(t0 * rate) + 1; i < std::size_t(t1 * rate); ++i)
            n += x[i - 1] < 0 && x[i] >= 0;
        return n / (t1 - t0);
    };
    const auto a4 = play(69), a5 = play(81), again = play(69);
    CHECK(a4.first == again.first);
    CHECK(a4.second == again.second);
    CHECK(crossings(a4.first, 0.1, 0.4) == doctest::Approx(441.0).epsilon(0.03));
    CHECK(crossings(a5.first, 0.1, 0.4) == doctest::Approx(882.0).epsilon(0.03));
    double sound = 0.0, tail = 0.0;
    for (std::size_t i = std::size_t(0.1 * rate); i < std::size_t(0.4 * rate); ++i)
        sound = std::max(sound, std::abs(a4.first[i]));
    for (std::size_t i = std::size_t(0.95 * rate); i < std::size_t(rate); ++i)
        tail = std::max(tail, std::abs(a4.first[i]));
    CHECK(sound > 0.05);
    CHECK(tail < sound * 0.05);  // released at 0.5 s: it has died away by the end
}

TEST_CASE(
    "soundfont: a track plays a preset from a project file at the calibrated level, in every form of the instrument") {
    Project p;
    p.bytes("assets/audio/tiny.sf2", tiny_sf2());
    const std::vector<Json> forms = {Json{{"soundfont", "assets/audio/tiny.sf2"}, {"preset", "Test Sine"}},
                                     Json{{"soundfont", "assets/audio/tiny.sf2"}, {"preset", 5}},
                                     Json{{"soundfont", "assets/audio/tiny.sf2"}, {"preset", 0}},
                                     Json("assets/audio/tiny.sf2#Test Sine"),
                                     Json("assets/audio/tiny.sf2#0:5"),
                                     Json("assets/audio/tiny.sf2")};
    std::vector<std::vector<float>> sounds;
    for (const Json& form : forms) {
        Json j = song_of({{"t", "x", "v100 C4:1"}});
        j["tracks"]["t"]["instrument"] = form;
        const SongRender r = render(j);
        CHECK_MESSAGE(std::abs(r.clip.peakDb + 12.0) < 0.7, form.dump() << " peaks at " << r.clip.peakDb);
        CHECK(std::find(r.inputs.begin(), r.inputs.end(), "assets/audio/tiny.sf2") != r.inputs.end());
        sounds.push_back(r.clip.samples);
        const SongDoc s = parsed(j);
        CHECK(s.tracks[0].soundfont.present());
        CHECK(s.tracks[0].soundfont.path == "assets/audio/tiny.sf2");
    }
    CHECK(sounds[0] == sounds[3]);  // the shorthand is the object
    CHECK(sounds[1] == sounds[4]);
    CHECK(sounds[0] == sounds[2]);  // the same sample, whichever preset
    // notes at other pitches sound at those pitches
    Json j = song_of({{"t", "x", "A4:1"}});
    j["tracks"]["t"]["instrument"] = forms[3];
    const SongRender a4 = render(j);
    CHECK(estimate_hz(a4, 0.1, 0.4) == doctest::Approx(440.0).epsilon(0.03));
    // the mixer works on it as on any track: pan and a send
    j["tracks"]["t"]["pan"] = -1.0;
    const SongRender panned = render(j);
    CHECK(channel_energy(panned, 1) < channel_energy(panned, 0) * 1e-4);
    // a drum preset (bank 128) plays a kit track's lanes by General MIDI key
    Json drums = drums_song(Json{{"soundfont", "assets/audio/tiny.sf2"}, {"preset", "Test Kit"}, {"drums", true}},
                            Json{{"kick", "x..............."}, {"snare", "........x......."}});
    const SongRender kit = render(drums);
    CHECK(kit.clip.peakDb > -20.0);
    CHECK(kit.clip.peakDb < -4.0);
    CHECK(kit.tracks[0].notes == 2);
    CHECK(render(drums).clip.samples == kit.clip.samples);
}

TEST_CASE("soundfont: mistakes say which file, which track and how to fix them") {
    Project p;
    p.bytes("assets/audio/tiny.sf2", tiny_sf2());
    p.text("assets/audio/notfont.sf2", "this is not a soundfont, only text that is long enough to be read as a file");
    auto song = [&](const Json& instrument) {
        Json j = song_of({{"keys", "x", "C4:1"}});
        j["tracks"]["keys"]["instrument"] = instrument;
        return j;
    };
    // missing file: the render fails with the track and the path
    auto missing = try_render(song(Json("assets/audio/nothere.sf2#Piano")));
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("keys") != std::string::npos);
    CHECK(missing.error().message.find("assets/audio/nothere.sf2") != std::string::npos);
    CHECK_FALSE(missing.error().hint.empty());
    // missing preset: the close names are suggested
    auto preset = try_render(song(Json("assets/audio/tiny.sf2#Test Sin")));
    REQUIRE_FALSE(preset.ok());
    CHECK(preset.error().message.find("Test Sin") != std::string::npos);
    CHECK(preset.error().hint.find("Test Sine") != std::string::npos);
    auto number = try_render(song(Json{{"soundfont", "assets/audio/tiny.sf2"}, {"preset", 99}}));
    REQUIRE_FALSE(number.ok());
    CHECK(number.error().message.find("99") != std::string::npos);
    // a file that is not a SoundFont
    auto bad = try_render(song(Json("assets/audio/notfont.sf2")));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("notfont.sf2") != std::string::npos);
    // parse errors of the instrument object
    {
        const auto issues = issues_of(song(Json{{"preset", "Piano"}}));
        const SongIssue* i = issue_at(issues, "/tracks/keys/instrument/soundfont");
        REQUIRE(i != nullptr);
        CHECK(i->message.find("soundfont") != std::string::npos);
    }
    {
        const auto issues = issues_of(song(Json{{"soundfont", "assets/audio/tiny.sf2"}, {"presets", "Piano"}}));
        const SongIssue* i = issue_at(issues, "/tracks/keys/instrument/presets");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("preset") != std::string::npos);
    }
    CHECK(issue_at(issues_of(song(Json{{"soundfont", "assets/audio/tiny.sf2"}, {"preset", 200}})),
                   "/tracks/keys/instrument/preset") != nullptr);
    CHECK(issue_at(issues_of(song(Json{{"soundfont", "assets/audio/tiny.sf2"}, {"preset", 1.5}})),
                   "/tracks/keys/instrument/preset") != nullptr);
    CHECK(issue_at(issues_of(song(Json{{"soundfont", "assets/audio/tiny.sf2"}, {"preset", "A"}, {"bank", 1}})),
                   "/tracks/keys/instrument/bank") != nullptr);
    CHECK(issue_at(issues_of(song(Json{{"soundfont", "../tiny.sf2"}})), "/tracks/keys/instrument/soundfont") !=
          nullptr);
}
