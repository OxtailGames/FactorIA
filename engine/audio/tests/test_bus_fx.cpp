// Bus effects: low-pass, reverb, ducking, snapshots and the volume ramps (the buses are summed before the master).
#include <doctest.h>

#include <cmath>
#include <cstring>

#include "audio_test_helpers.h"
#include "fa/audio/audio.h"
#include "fa/audio/snapshots.h"

using namespace fa;
using namespace audio_test;

namespace {

// The amplitude of the sine of `freq` Hz in left[from, to) (Goertzel); a sine of amplitude A reads A.
double tone(const Recording& r, double freq, double fromSec, double toSec, int rate = 44100) {
    const std::size_t from = std::size_t(fromSec * rate), to = std::min(std::size_t(toSec * rate), r.frames());
    REQUIRE(to > from);
    const double w = 2.0 * std::numbers::pi * freq / rate;
    double re = 0, im = 0;
    for (std::size_t i = from; i < to; ++i) {
        re += r.l[i] * std::cos(w * double(i));
        im += r.l[i] * std::sin(w * double(i));
    }
    return 2.0 * std::sqrt(re * re + im * im) / double(to - from);
}

PlayParams looping(const char* bus) {
    PlayParams p;
    p.loop = true;
    p.bus = bus;
    return p;
}

void write_clips(Fixture& fx) {
    write_sine_wav(fx.dir / "sounds/hi.wav", 1.0, 8000.0, 0.5);
    write_sine_wav(fx.dir / "sounds/lo.wav", 1.0, 200.0, 0.5);
    write_sine_wav(fx.dir / "sounds/blip.wav", 1.0, 1000.0, 0.5);
    write_sine_wav(fx.dir / "sounds/click.wav", 0.05, 1000.0, 0.5);
}

}  // namespace

TEST_CASE("bus fx: a low-pass removes a high tone, keeps a low one, and goes away with 0") {
    Fixture fx;
    write_clips(fx);
    fx.audio.play("sounds/hi.wav", looping("sfx"));
    fx.audio.play("sounds/lo.wav", looping("sfx"));
    fx.audio.start_recording();
    fx.run(0.5);
    const Recording before = fx.finish();
    const double hiBefore = tone(before, 8000, 0.1, 0.5), loBefore = tone(before, 200, 0.1, 0.5);
    CHECK(hiBefore == doctest::Approx(0.5).epsilon(0.05));
    CHECK(loBefore == doctest::Approx(0.5).epsilon(0.05));

    REQUIRE(fx.audio.set_bus_lowpass("sfx", 500.0f).ok());
    CHECK(fx.audio.bus_state("sfx")["lowpass"] == 500.0);
    fx.audio.start_recording();
    fx.run(0.5);
    const Recording after = fx.finish();
    // 8000 Hz is four octaves above the 500 Hz cutoff: about -48 dB for a 12 dB per octave filter.
    CHECK(tone(after, 8000, 0.1, 0.5) < hiBefore * 0.02);
    CHECK(tone(after, 200, 0.1, 0.5) == doctest::Approx(loBefore).epsilon(0.05));

    REQUIRE(fx.audio.set_bus_lowpass("sfx", 0.0f).ok());
    CHECK(fx.audio.bus_state("sfx")["lowpass"] == 0.0);
    fx.audio.start_recording();
    fx.run(0.5);
    const Recording off = fx.finish();
    CHECK(tone(off, 8000, 0.1, 0.5) == doctest::Approx(hiBefore).epsilon(0.05));
}

TEST_CASE("bus fx: the filter is per bus and the master has one too") {
    Fixture fx;
    write_clips(fx);
    fx.audio.play("sounds/hi.wav", looping("sfx"));
    PlayParams ui = looping("ui");
    fx.audio.play("sounds/hi.wav", ui);
    REQUIRE(fx.audio.set_bus_lowpass("sfx", 500.0f).ok());
    fx.audio.start_recording();
    fx.run(0.5);
    const Recording r = fx.finish();
    // Only the ui voice is left of the 8 kHz tone (0.5).
    CHECK(tone(r, 8000, 0.1, 0.5) == doctest::Approx(0.5).epsilon(0.05));
    REQUIRE(fx.audio.set_bus_lowpass("master", 500.0f).ok());
    fx.audio.start_recording();
    fx.run(0.5);
    CHECK(tone(fx.finish(), 8000, 0.1, 0.5) < 0.01);
}

TEST_CASE("bus fx: reverb adds a tail that stops costing after a while; mix 0 removes it") {
    Fixture fx;
    write_clips(fx);
    REQUIRE(fx.audio.set_bus_reverb("sfx", 0.5f).ok());
    fx.audio.start_recording();
    fx.audio.play("sounds/click.wav");
    fx.run(6.5);
    const Recording wet = fx.finish();
    CHECK(wet.sound_end(0.01f) > 44100 * 0.05);                 // the click itself
    CHECK(wet.peak(44100 / 2, 44100) > 0.001f);                 // still ringing half a second later
    CHECK(wet.peak(wet.frames() - 44100) == 0.0f);               // and after four silent seconds the reverb stops working

    REQUIRE(fx.audio.set_bus_reverb("sfx", 0.0f).ok());
    fx.audio.start_recording();
    fx.audio.play("sounds/click.wav");
    fx.run(1.0);
    const Recording dry = fx.finish();
    CHECK(dry.peak(44100 / 2) == 0.0f);

    // A reverb on another bus leaves this one alone.
    REQUIRE(fx.audio.set_bus_reverb("music", 0.5f).ok());
    fx.audio.start_recording();
    fx.audio.play("sounds/click.wav");
    fx.run(1.0);
    CHECK(fx.finish().peak(44100 / 2) == 0.0f);
}

TEST_CASE("bus fx: a ducked bus drops while the other plays and recovers after it stops") {
    Fixture fx;
    write_clips(fx);
    fx.audio.play("sounds/sine.wav", looping("music"));  // 440 Hz, 0.5
    DuckSettings d;
    d.by = "sfx";
    d.amount = 0.8f;
    d.attack = 0.02f;
    d.release = 0.2f;
    REQUIRE(fx.audio.set_bus_duck("music", d).ok());
    CHECK(fx.audio.bus_state("music")["duck"]["by"] == "sfx");
    fx.audio.start_recording();
    fx.run(0.5);
    fx.audio.play("sounds/blip.wav");  // 1 s of 1000 Hz on sfx, from t = 0.5
    fx.run(2.5);
    const Recording r = fx.finish();
    const double full = tone(r, 440, 0.1, 0.5);
    CHECK(full == doctest::Approx(0.5).epsilon(0.05));
    CHECK(tone(r, 1000, 0.8, 1.3) == doctest::Approx(0.5).epsilon(0.05));  // the sfx is not ducked
    CHECK(tone(r, 440, 0.8, 1.3) == doctest::Approx(full * 0.2).epsilon(0.1));  // while the blip plays
    CHECK(tone(r, 440, 2.2, 3.0) == doctest::Approx(full).epsilon(0.05));  // recovered

    // Turn it off: nothing is ducked even while the other plays.
    REQUIRE(fx.audio.set_bus_duck("music", DuckSettings{}).ok());
    CHECK(fx.audio.bus_state("music")["duck"].is_null());
    fx.audio.start_recording();
    fx.audio.play("sounds/blip.wav");
    fx.run(0.8);
    CHECK(tone(fx.finish(), 440, 0.3, 0.8) == doctest::Approx(full).epsilon(0.05));
}

TEST_CASE("bus fx: ducking while the other bus is quiet does nothing, and the ducker itself is not ducked") {
    Fixture fx;
    write_clips(fx);
    DuckSettings d;
    d.by = "sfx";
    d.amount = 1.0f;
    d.attack = 0.0f;
    d.release = 0.0f;
    REQUIRE(fx.audio.set_bus_duck("music", d).ok());
    fx.audio.play("sounds/sine.wav", looping("music"));
    fx.audio.start_recording();
    fx.run(0.3);
    CHECK(tone(fx.finish(), 440, 0.1, 0.3) == doctest::Approx(0.5).epsilon(0.05));  // sfx silent
    PlayParams soft;  // below the -40 dBFS threshold: not a trigger
    soft.volume = 0.01f;
    soft.loop = true;
    fx.audio.play("sounds/blip.wav", soft);
    fx.audio.start_recording();
    fx.run(0.3);
    CHECK(tone(fx.finish(), 440, 0.1, 0.3) == doctest::Approx(0.5).epsilon(0.05));
    fx.audio.stop_all();
    fx.audio.play("sounds/sine.wav", looping("music"));
    fx.audio.play("sounds/blip.wav", looping("sfx"));
    fx.audio.start_recording();
    fx.run(0.4);
    const Recording r = fx.finish();
    CHECK(tone(r, 440, 0.2, 0.4) < 0.01);                                         // amount 1 = silent
    CHECK(tone(r, 1000, 0.2, 0.4) == doctest::Approx(0.5).epsilon(0.05));
}

TEST_CASE("bus fx: a snapshot fades the bus volumes and effects in its time") {
    Fixture fx;
    write_clips(fx);
    AudioSnapshots catalog;
    AudioSnapshot& dim = catalog["dim"];
    dim.fade = 1.0f;
    dim.buses["music"].volume = 0.2f;
    dim.buses["sfx"].lowpass = 500.0f;
    catalog["normal"];  // neutral
    fx.audio.set_snapshots(catalog);
    CHECK(fx.audio.snapshot_names() == std::vector<std::string>{"dim", "normal"});

    fx.audio.set_bus_volume("music", 0.8f);  // the player's setting
    fx.audio.play("sounds/sine.wav", looping("music"));
    fx.audio.play("sounds/hi.wav", looping("sfx"));
    fx.run(0.2);  // the player's volume settles
    fx.audio.start_recording();
    fx.run(0.5);
    REQUIRE(fx.audio.apply_snapshot("dim").ok());  // the catalog's fade: 1 s, from t = 0.5
    CHECK(fx.audio.current_snapshot() == "dim");
    fx.run(2.0);
    const Recording r = fx.finish();
    const double base = tone(r, 440, 0.2, 0.5);  // 0.5 * 0.8
    CHECK(base == doctest::Approx(0.4).epsilon(0.05));
    // The volume scale goes from 1 to 0.2 in a straight line between t = 0.5 s and 1.5 s.
    const auto ratio = [&](double from, double to) { return tone(r, 440, from, to) / base; };
    CHECK(std::fabs((ratio(0.5, 0.6)) - (0.96)) < 0.05);
    CHECK(std::fabs((ratio(0.95, 1.05)) - (0.6)) < 0.05);
    CHECK(std::fabs((ratio(1.4, 1.5)) - (0.23)) < 0.05);
    CHECK(std::fabs((ratio(1.7, 2.5)) - (0.2)) < 0.02);  // stays there
    // The 8 kHz tone on sfx goes the same way: the cutoff slides down in a second and then it is gone.
    CHECK(tone(r, 8000, 0.2, 0.5) == doctest::Approx(0.5).epsilon(0.05));
    CHECK(tone(r, 8000, 1.7, 2.5) < 0.01);
    CHECK(fx.audio.bus_volume("music") == 0.8f);  // the player's volume is untouched

    // A snapshot that lists nothing is the neutral state: effects off, scale 1. An explicit time overrides the catalog's.
    REQUIRE(fx.audio.apply_snapshot("normal", 0.0f).ok());
    fx.audio.start_recording();
    fx.run(0.5);
    const Recording back = fx.finish();
    CHECK(tone(back, 440, 0.2, 0.5) == doctest::Approx(base).epsilon(0.05));
    CHECK(tone(back, 8000, 0.2, 0.5) == doctest::Approx(0.5).epsilon(0.05));
    CHECK(fx.audio.bus_state("sfx")["lowpass"] == 0.0);

    Json st = fx.audio.stats();
    CHECK(st["snapshot"] == "normal");
    CHECK(st["busEffects"]["music"]["snapshotVolume"] == 1.0);
}

TEST_CASE("bus fx: a snapshot sets ducking at once and a bad name says what exists") {
    Fixture fx;
    AudioSnapshots catalog;
    AudioSnapshot& talk = catalog["talk"];
    BusSnapshot& music = talk.buses["music"];
    DuckSettings d;
    d.by = "ui";
    d.amount = 0.5f;
    music.duck = d;
    fx.audio.set_snapshots(catalog);
    REQUIRE(fx.audio.apply_snapshot("talk").ok());
    CHECK(fx.audio.bus_state("music")["duck"]["by"] == "ui");
    CHECK(fx.audio.bus_state("music")["duck"]["amount"] == 0.5);

    auto bad = fx.audio.apply_snapshot("tak");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("Did you mean 'talk'") != std::string::npos);
    Audio empty;
    std::string err;
    REQUIRE(empty.init(false, &err));
    auto none = empty.apply_snapshot("x");
    REQUIRE_FALSE(none.ok());
    CHECK(none.error().hint.find("audio") != std::string::npos);
}

TEST_CASE("bus fx: wrong buses and values are errors that teach") {
    Fixture fx;
    auto r = fx.audio.set_bus_lowpass("musik", 500.0f);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("music") != std::string::npos);
    CHECK_FALSE(fx.audio.set_bus_lowpass("sfx", -5.0f).ok());
    CHECK_FALSE(fx.audio.set_bus_reverb("sfx", 1.5f).ok());
    DuckSettings d;
    d.by = "sfx";
    d.amount = 0.5f;
    CHECK_FALSE(fx.audio.set_bus_duck("sfx", d).ok());      // itself
    CHECK_FALSE(fx.audio.set_bus_duck("master", d).ok());   // the master has no ducking
    d.by = "master";
    CHECK_FALSE(fx.audio.set_bus_duck("music", d).ok());
    d.by = "sfx";
    d.amount = 2.0f;
    CHECK_FALSE(fx.audio.set_bus_duck("music", d).ok());
    CHECK(fx.audio.bus_state("nope").is_null());
}

TEST_CASE("bus fx: a volume change ramps instead of clicking") {
    Fixture fx;
    fx.audio.play("sounds/sine.wav", looping("sfx"));
    fx.run(0.1);
    fx.audio.start_recording();
    fx.run(0.05);
    fx.audio.set_bus_volume("sfx", 0.0f);
    fx.run(0.1);
    const Recording r = fx.finish();
    float worst = 0.0f;
    for (std::size_t i = 1; i < r.frames(); ++i) worst = std::max(worst, std::fabs(r.l[i] - r.l[i - 1]));
    CHECK(worst < 0.045f);  // a 0.5 sine moves at most 0.031 per sample on its own; a hard cut would jump by up to 0.5
    CHECK(r.peak(r.frames() - 1000) == 0.0f);

    // A fade takes the time it is given: halfway through, the gain is halfway.
    fx.audio.set_bus_volume("sfx", 1.0f, 2.0f);
    fx.audio.start_recording();
    fx.run(2.5);
    const Recording up = fx.finish();
    CHECK(std::fabs((tone(up, 440, 0.95, 1.05)) - (0.25)) < 0.04);
    CHECK(tone(up, 440, 2.1, 2.5) == doctest::Approx(0.5).epsilon(0.05));
}

TEST_CASE("bus fx: the mix with effects is deterministic") {
    auto run = [] {
        Fixture fx;
        write_clips(fx);
        REQUIRE(fx.audio.set_bus_lowpass("sfx", 1500.0f).ok());
        REQUIRE(fx.audio.set_bus_reverb("music", 0.4f).ok());
        REQUIRE(fx.audio.set_bus_reverb("master", 0.1f).ok());
        DuckSettings d;
        d.by = "sfx";
        d.amount = 0.6f;
        REQUIRE(fx.audio.set_bus_duck("music", d).ok());
        AudioSnapshots catalog;
        catalog["a"].buses["sfx"].volume = 0.5f;
        fx.audio.set_snapshots(catalog);
        fx.audio.start_recording();
        fx.audio.play("sounds/sine.wav", looping("music"));
        fx.run(0.3);
        PlayParams a;
        a.pitch = 1.3f;
        fx.audio.play("sounds/blip.wav", a);
        REQUIRE(fx.audio.apply_snapshot("a", 0.4f).ok());
        fx.run(1.5);
        return fx.finish();
    };
    const Recording a = run(), b = run();
    REQUIRE(a.frames() == b.frames());
    CHECK(std::memcmp(a.l.data(), b.l.data(), a.l.size() * sizeof(float)) == 0);
    CHECK(std::memcmp(a.r.data(), b.r.data(), a.r.size() * sizeof(float)) == 0);
}

TEST_CASE("bus fx: reset_bus_effects clears effects and snapshot scales but not the player's volumes") {
    Fixture fx;
    AudioSnapshots catalog;
    catalog["s"].buses["music"].volume = 0.5f;
    catalog["s"].buses["music"].lowpass = 400.0f;
    fx.audio.set_snapshots(catalog);
    fx.audio.set_bus_volume("music", 0.7f);
    REQUIRE(fx.audio.apply_snapshot("s", 0.0f).ok());
    REQUIRE(fx.audio.set_bus_reverb("ui", 0.3f).ok());
    fx.audio.reset_bus_effects();
    CHECK(fx.audio.bus_state("music")["lowpass"] == 0.0);
    CHECK(fx.audio.bus_state("music")["snapshotVolume"] == 1.0);
    CHECK(fx.audio.bus_state("ui")["reverb"] == 0.0);
    CHECK(fx.audio.bus_volume("music") == 0.7f);
    CHECK(fx.audio.current_snapshot().empty());
}

TEST_CASE("audio settings: the snapshot catalog parses, and every mistake names its place and a fix") {
    const Json good = Json::parse(R"({"snapshots": {
        "underwater": {"fade": 0.8, "buses": {
            "sfx": {"volume": 0.8, "lowpass": 600, "reverb": 0.3},
            "music": {"lowpass": 400, "duck": {"by": "ui", "amount": 0.5, "attack": 0.05, "release": 0.5}},
            "master": {"volume": 0.9}}},
        "normal": {}}})");
    AudioSettingsParse p = parse_audio_settings(good);
    REQUIRE(p.ok());
    CHECK(p.warnings.empty());
    REQUIRE(p.snapshots.size() == 2);
    const AudioSnapshot& u = p.snapshots["underwater"];
    CHECK(u.fade == doctest::Approx(0.8f));
    CHECK(u.buses.at("sfx").lowpass == 600.0f);
    CHECK(u.buses.at("sfx").reverb == doctest::Approx(0.3f));
    REQUIRE(u.buses.at("music").duck.has_value());
    CHECK(u.buses.at("music").duck->by == "ui");
    CHECK(p.snapshots["normal"].fade == 0.5f);
    CHECK(parse_audio_settings(Json()).ok());

    const Json bad = Json::parse(R"({"snapshotz": {}, "snapshots": {
        "a": {"buses": {"musik": {}, "sfx": {"lowpass": 5, "reverb": 2, "volume": "loud", "duck": {"by": "sfx"}}}},
        "b": {"fade": -1, "bus": {}},
        "c": {"buses": {"music": {"duck": {"by": "master"}}, "master": {"duck": {"by": "sfx"}}}}}})");
    p = parse_audio_settings(bad);
    CHECK_FALSE(p.ok());
    const auto has = [&](const std::vector<AudioIssue>& list, const std::string& pointer, const std::string& text) {
        for (const AudioIssue& i : list)
            if (i.pointer == pointer && i.message.find(text) != std::string::npos) return true;
        return false;
    };
    CHECK(has(p.issues, "/audio/snapshots/a/buses/musik", "Did you mean 'music'"));
    CHECK(has(p.issues, "/audio/snapshots/a/buses/sfx/lowpass", "below hearing"));
    CHECK(has(p.issues, "/audio/snapshots/a/buses/sfx/reverb", "from 0 to 1"));
    CHECK(has(p.issues, "/audio/snapshots/a/buses/sfx/volume", "expected a number"));
    CHECK(has(p.issues, "/audio/snapshots/a/buses/sfx/duck/by", "cannot duck itself"));
    CHECK(has(p.issues, "/audio/snapshots/b/fade", "from 0 to 60"));
    CHECK(has(p.issues, "/audio/snapshots/c/buses/music/duck/by", "not a bus that can duck"));
    CHECK(has(p.issues, "/audio/snapshots/c/buses/master/duck", "master cannot be ducked"));
    CHECK(has(p.warnings, "/audio/snapshotz", "Did you mean 'snapshots'"));
    CHECK(has(p.warnings, "/audio/snapshots/b/bus", "Did you mean 'buses'"));

    CHECK_FALSE(parse_audio_settings(Json::parse(R"([1])")).ok());
    CHECK_FALSE(parse_audio_settings(Json::parse(R"({"snapshots": 3})")).ok());
}
