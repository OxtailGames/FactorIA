// Song documents (fa/audio/song.h and friends, M56.1): note text, the parser's errors with line and column, theory, expansion with
// swing and mutes, the helpers, every check rule on a crafted song (found and not found), and the preview render.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <set>
#include <string>

#include "fa/audio/sfx.h"
#include "fa/audio/song.h"
#include "fa/audio/song_check.h"
#include "fa/audio/song_helpers.h"
#include "fa/audio/song_instruments.h"
#include "fa/audio/song_preview.h"
#include "fa/audio/song_theory.h"

using namespace fa;

namespace {

Json base_song() {
    return Json::parse(R"({
      "format": "factoria.song/1", "tempo": 120, "meter": "4/4", "key": "C", "mode": "major",
      "tracks": {
        "lead": {"instrument": "keys", "patterns": {"a": "C4:4 E4 G4 C5"}},
        "drums": {"instrument": "kit", "patterns": {"rock": {"grid": {"kick": "x...x...x...x...", "snare": "....x.......x..."}}}}
      },
      "sections": [{"name": "main", "play": {"lead": "a*2", "drums": "rock*2"}}]
    })");
}

SongDoc parsed(const Json& j) {
    std::vector<SongIssue> issues;
    auto r = parse_song(j, "test.song.json", &issues);
    INFO((r ? std::string() : r.error().message));
    REQUIRE(bool(r));
    return *r;
}

SongTimeline expanded(const SongDoc& s) {
    auto t = expand_song(s);
    REQUIRE(bool(t));
    return *t;
}

std::vector<SongIssue> issues_of(const Json& j) {
    std::vector<SongIssue> issues;
    auto r = parse_song(j, "test.song.json", &issues);
    CHECK_FALSE(bool(r));
    return issues;
}

// A song with one pitched track per entry of `tracks` ({name, instrument, notes}), each playing its one pattern for `bars` bars.
struct T {
    std::string name, instrument, notes;
};
Json song_of(const std::vector<T>& tracks, const std::string& key = "C", const std::string& mode = "major") {
    Json j = Json::parse(R"({"format": "factoria.song/1", "tempo": 120, "tracks": {}, "sections": [{"name": "main", "play": {}}]})");
    j["key"] = key;
    j["mode"] = mode;
    for (const T& t : tracks) {
        j["tracks"][t.name] = {{"instrument", t.instrument}, {"patterns", {{"a", t.notes}}}};
        j["sections"][0]["play"][t.name] = "a";
    }
    return j;
}

SongCheckReport check_of(const Json& j, const SongCheckOptions& o = {}) {
    SongDoc s = parsed(j);
    SongTimeline t = expanded(s);
    auto r = check_song(s, t, o);
    REQUIRE(bool(r));
    return *r;
}


SongPattern notes_of(const std::string& text, std::vector<SongIssue>* issues = nullptr, int declaredBars = 0, SongMeter meter = {}) {
    SongPattern p;
    std::vector<SongIssue> local;
    song_parse_note_text(text, "/p", meter, declaredBars, p, issues ? *issues : local);
    return p;
}

}  // namespace

// ---- theory ------------------------------------------------------------------------------------------------------------

TEST_CASE("song theory: pitches and frequencies") {
    CHECK(song_parse_pitch("C4") == 60);
    CHECK(song_parse_pitch("A4") == 69);
    CHECK(song_parse_pitch("F#3") == 54);
    CHECK(song_parse_pitch("Bb-1") == 10);
    CHECK_FALSE(song_parse_pitch("H4").has_value());
    CHECK_FALSE(song_parse_pitch("C").has_value());
    CHECK(song_pitch_name(61) == "C#4");
    CHECK(song_pitch_name(61, true) == "Db4");
    CHECK(song_midi_hz(69) == doctest::Approx(440.0));
    CHECK(song_midi_hz(60) == doctest::Approx(261.6256).epsilon(1e-5));
    CHECK(song_midi_hz(57) == doctest::Approx(220.0));
}

TEST_CASE("song theory: chords by name") {
    auto c = song_parse_chord("Am7");
    REQUIRE(c);
    CHECK(c->root == 9);
    CHECK(c->intervals == std::vector<int>{0, 3, 7, 10});
    auto slash = song_parse_chord("Cmaj7/G");
    REQUIRE(slash);
    CHECK(song_chord_pitches(*slash, 3) == std::vector<int>{43, 48, 52, 55, 59});
    CHECK(song_parse_chord("F#dim")->intervals == std::vector<int>{0, 3, 6});
    CHECK(song_parse_chord("Dsus4")->intervals == std::vector<int>{0, 5, 7});
    CHECK(song_parse_chord("C")->intervals == std::vector<int>{0, 4, 7});
    CHECK(song_parse_chord("Bbm")->root == 10);
    auto bad = song_parse_chord("Cmaj77");
    REQUIRE_FALSE(bad);
    CHECK(bad.error().message.find("Cmaj77") != std::string::npos);
    CHECK_FALSE(bad.error().hint.empty());
    CHECK_FALSE(song_parse_chord("H"));
}

TEST_CASE("song theory: scales, modes and diatonic chords") {
    auto major = song_scale_pitch_classes(0, "major");
    REQUIRE(major);
    CHECK(std::set<int>(major->begin(), major->end()) == std::set<int>{0, 2, 4, 5, 7, 9, 11});
    auto minor = song_scale_pitch_classes(9, "minor");
    REQUIRE(minor);
    CHECK(std::set<int>(minor->begin(), minor->end()) == std::set<int>{9, 11, 0, 2, 4, 5, 7});
    auto dorian = song_scale_pitch_classes(2, "dorian");
    REQUIRE(dorian);
    CHECK(std::set<int>(dorian->begin(), dorian->end()) == std::set<int>{2, 4, 5, 7, 9, 11, 0});
    CHECK_FALSE(song_scale_pitch_classes(0, "nonsense").has_value());
    const std::vector<std::string> triads = song_diatonic_chords(0, "major", false);
    CHECK(triads == std::vector<std::string>{"C", "Dm", "Em", "F", "G", "Am", "Bdim"});
    const std::vector<std::string> sevenths = song_diatonic_chords(0, "major", true);
    REQUIRE(sevenths.size() == 7);
    CHECK(sevenths[0] == "Cmaj7");
    CHECK(sevenths[4] == "G7");
    CHECK(song_diatonic_chords(0, "blues", false).empty());
    CHECK(song_prefers_flats(5, "major"));
    CHECK_FALSE(song_prefers_flats(7, "major"));
    const std::vector<int> notes = song_scale_notes(0, "major", 60, 72);
    CHECK(notes == std::vector<int>{60, 62, 64, 65, 67, 69, 71, 72});
}

TEST_CASE("song theory: every instrument and kit lane is a valid patch") {
    for (const SongInstrumentInfo& i : song_instruments()) {
        auto j = song_instrument_patch(i.name);
        REQUIRE_MESSAGE(j.has_value(), i.name);
        CHECK_MESSAGE(bool(parse_sfx(*j, i.name)), i.name);
        CHECK(song_instrument_range(i.name).has_value());
    }
    for (const SongDrumLane& l : song_drum_lanes()) {
        auto j = song_instrument_patch("kit:" + l.name);
        REQUIRE_MESSAGE(j.has_value(), l.name);
        CHECK_MESSAGE(bool(parse_sfx(*j, l.name)), l.name);
    }
    CHECK_FALSE(song_instrument_patch("nonsense").has_value());
}

// ---- notation ----------------------------------------------------------------------------------------------------------

TEST_CASE("song notation: notes, durations, rests, ties, chords, velocity") {
    SongPattern p = notes_of("C4:4 E4 G4 C5");
    REQUIRE(p.events.size() == 4);
    CHECK(p.bars == 1);
    CHECK(p.events[1].tick == 960);
    CHECK(p.events[3].pitches == std::vector<int>{72});
    CHECK(p.events[3].duration == 960);

    p = notes_of("C4:4. D4:8 E4:2");  // 1440 + 480 + 1920
    REQUIRE(p.events.size() == 3);
    CHECK(p.events[0].duration == 1440);
    CHECK(p.events[1].tick == 1440);
    CHECK(p.events[2].tick == 1920);

    p = notes_of("C4:8t D4 E4 r:4 r:2");  // three triplet eighths = one beat
    REQUIRE(p.events.size() == 3);
    CHECK(p.events[0].duration == 320);
    CHECK(p.events[2].tick == 640);
    CHECK(p.bars == 1);

    p = notes_of("C4:2~ C4:2");
    REQUIRE(p.events.size() == 1);
    CHECK(p.events[0].duration == 3840);

    p = notes_of("[C4 E4 G4]:2 (Am7):2");
    REQUIRE(p.events.size() == 2);
    CHECK(p.events[0].pitches == std::vector<int>{60, 64, 67});
    CHECK(p.events[1].chord == "Am7");
    CHECK(p.events[1].pitches.size() == 4);

    p = notes_of("v50 C4:4 D4:4! E4:4' F4:4v100");
    REQUIRE(p.events.size() == 4);
    CHECK(p.events[0].velocity == 50);
    CHECK(p.events[1].velocity == 50 + 22);
    CHECK(p.events[1].accent);
    CHECK(p.events[2].gate == doctest::Approx(0.5));
    CHECK(p.events[3].velocity == 100);

    p = notes_of("{C4:8 D4:8 }x2 E4:2");
    REQUIRE(p.events.size() == 5);
    CHECK(p.events[4].tick == 1920);

    p = notes_of("C4:1 & E3:2 G3:2");
    REQUIRE(p.events.size() == 3);
    CHECK(p.events[1].tick == 0);
    CHECK(p.events[2].tick == 1920);
}

TEST_CASE("song notation: errors name the token's line and column") {
    std::vector<SongIssue> issues;
    notes_of("C4:4 H4 G4 C5", &issues);
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].line == 1);
    CHECK(issues[0].column == 6);
    CHECK(issues[0].message.find("H4") != std::string::npos);
    CHECK_FALSE(issues[0].hint.empty());
    CHECK(song_issue_text(issues[0], "x.song.json").find("(line 1, column 6)") != std::string::npos);

    issues.clear();
    notes_of("C4:4 E4\nG4 X5", &issues);
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].line == 2);
    CHECK(issues[0].column == 4);

    issues.clear();
    notes_of("C4:4 E4 G4 | C5", &issues);  // the bar line comes after 3 beats
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].column == 12);
    CHECK(issues[0].message.find("bar line") != std::string::npos);

    issues.clear();
    notes_of("C4:4 E4 G4", &issues);  // not a whole bar
    REQUIRE_FALSE(issues.empty());
    CHECK_FALSE(issues[0].hint.empty());

    issues.clear();
    notes_of("C4:4 E4 G4 C5 C4:4 E4 G4 C5", &issues, 1);  // longer than the 1 bar declared
    CHECK_FALSE(issues.empty());

    issues.clear();
    notes_of("C4:5 E4 G4 C5", &issues);
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].message.find(":5") != std::string::npos);

    issues.clear();
    notes_of("(Cxyz):1", &issues);
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].column == 2);

    issues.clear();
    notes_of("{C4:4 D4:4 E4:2 ", &issues);  // an unclosed group
    CHECK_FALSE(issues.empty());
}

TEST_CASE("song notation: drum grids") {
    SongPattern p;
    std::vector<SongIssue> issues;
    Json g = Json::parse(R"({"grid": {"kick": "x...x...x...x...", "hat": "XoXoXoXoXoXoXoXo"}})");
    CHECK(song_parse_drum_grid(g, "/p", SongMeter{}, {}, p, issues));
    CHECK(p.bars == 1);
    int kicks = 0, ghosts = 0;
    for (const SongEvent& e : p.events) {
        kicks += e.drum == "kick";
        ghosts += e.drum == "hat" && e.velocity < 60;
    }
    CHECK(kicks == 4);
    CHECK(ghosts == 8);
    issues.clear();
    Json bad = Json::parse(R"({"grid": {"kik": "x...x...x...x...", "snare": "....x...z.......x"}})");
    CHECK_FALSE(song_parse_drum_grid(bad, "/p", SongMeter{}, {}, p, issues));
    REQUIRE(issues.size() >= 2);
    CHECK(issues[0].hint.find("kick") != std::string::npos);
}

// ---- parsing and expansion ----------------------------------------------------------------------------------------------

TEST_CASE("song parse: a valid song, its length and its events") {
    SongDoc s = parsed(base_song());
    CHECK(s.tempo == 120.0);
    CHECK(s.tracks.size() == 2);
    CHECK(s.sections.size() == 1);
    CHECK(s.sections[0].bars == 2);
    SongTimeline t = expanded(s);
    CHECK(t.bars == 2);
    CHECK(t.seconds == doctest::Approx(4.0));
    int lead = 0, drums = 0;
    for (const SongNote& n : t.notes) {
        (n.track == 0 ? lead : drums)++;
        CHECK((n.pitch >= 0) == (n.track == 0));
    }
    CHECK(lead == 8);
    CHECK(drums == 12);  // (4 kicks + 2 snares) x 2 bars
}

TEST_CASE("song parse: every problem is listed with its pointer, a fix and a suggestion") {
    Json j = base_song();
    j["tracks"]["lead"]["instrument"] = "kyes";
    j["tracks"]["lead"]["patterns"]["a"] = "C4:4 E4 G4 Z9";
    j["sections"][0]["play"]["lead"] = "b";
    j["tempo"] = 1000;
    j["bogus"] = 1;
    std::vector<SongIssue> issues;
    auto r = parse_song(j, "x.song.json", &issues);
    REQUIRE_FALSE(r);
    CHECK(issues.size() >= 4);
    CHECK(r.error().message.find("x.song.json") != std::string::npos);
    CHECK(r.error().message.find("more problem") != std::string::npos);
    bool instrument = false, note = false, tempo = false, unknown = false;
    for (const SongIssue& i : issues) {
        if (i.pointer == "/tracks/lead/instrument") { instrument = true; CHECK(i.hint.find("keys") != std::string::npos); }
        if (i.pointer == "/tracks/lead/patterns/a") { note = true; CHECK(i.column == 12); }
        if (i.pointer == "/tempo") tempo = true;
        if (i.pointer.find("bogus") != std::string::npos || i.message.find("bogus") != std::string::npos) unknown = true;
    }
    CHECK(instrument);
    CHECK(note);
    CHECK(tempo);
    CHECK(unknown);
}

TEST_CASE("song parse: a section naming a missing pattern or track suggests the right one") {
    Json j = base_song();
    j["sections"][0]["play"]["lead"] = "aa";
    auto issues = issues_of(j);
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].hint.find("'a'") != std::string::npos);

    j = base_song();
    j["sections"][0]["play"]["leed"] = "a";
    issues = issues_of(j);
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].hint.find("lead") != std::string::npos);

    j = base_song();
    j["key"] = "Am";
    issues = issues_of(j);
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].hint.find("minor") != std::string::npos);
}

TEST_CASE("song expand: sections repeat, patterns fill the section, tracks are muted per section") {
    Json j = base_song();
    j["sections"] = Json::parse(R"([
      {"name": "intro", "kind": "intro", "play": {"lead": "a"}},
      {"name": "loop", "kind": "loop", "repeat": 2, "bars": 4, "play": {"lead": "a", "drums": "rock"}, "mute": ["drums"]}
    ])");
    SongDoc s = parsed(j);
    SongTimeline t = expanded(s);
    CHECK(t.spans.size() == 3);
    CHECK(t.bars == 1 + 4 + 4);
    int lead = 0, drums = 0;
    for (const SongNote& n : t.notes) (n.track == 0 ? lead : drums)++;
    CHECK(lead == 4 + 16 + 16);  // the one-bar pattern is cycled to fill 4 bars
    CHECK(drums == 0);           // muted in the loop
    CHECK(s.sections[1].kind == "loop");
    // Notes are sorted by tick.
    for (std::size_t i = 1; i < t.notes.size(); ++i) CHECK(t.notes[i - 1].tick <= t.notes[i].tick);
    CHECK(t.position_text(s, 3840 + 960) == "bar 2, beat 2");
}

TEST_CASE("song expand: swing delays the off-beats and leaves the beats") {
    Json j = song_of({{"lead", "keys", "C4:8 D4 E4 F4 G4 A4 B4 C5"}});
    j["swing"] = 0.5;
    SongDoc s = parsed(j);
    SongTimeline t = expanded(s);
    REQUIRE(t.notes.size() == 8);
    CHECK(t.notes[0].tick == 0);
    CHECK(t.notes[1].tick == 480 + 80);   // 0.5 * 480 / 3
    CHECK(t.notes[2].tick == 960);
    CHECK(t.notes[3].tick == 960 + 480 + 80);
    // A track's own swing overrides the song's.
    j["tracks"]["lead"]["swing"] = 0.0;
    t = expanded(parsed(j));
    CHECK(t.notes[1].tick == 480);
}

TEST_CASE("song expand: compound meters group the strong beats by three eighths") {
    SongMeter m{6, 8};
    CHECK(m.barTicks() == 2880);
    CHECK(m.strongTicks() == 1440);
    SongMeter four{4, 4};
    CHECK(four.strongTicks() == 960);
}

// ---- helpers -----------------------------------------------------------------------------------------------------------

TEST_CASE("song helpers: chord progressions") {
    SongMeter m;
    auto p = song_parse_progression("Am F C G", m);
    REQUIRE(p);
    CHECK(p->size() == 4);
    CHECK((*p)[0].ticks == 3840);
    p = song_parse_progression("Am*2 | F, C", m, 2);
    REQUIRE(p);
    CHECK((*p)[0].ticks == 7680);
    CHECK((*p)[1].ticks == 1920);
    auto bad = song_parse_progression("Am Fx9 C", m);
    REQUIRE_FALSE(bad);
    CHECK(bad.error().message.find("Fx9") != std::string::npos);
    CHECK_FALSE(song_parse_progression("Am*0", m));
    CHECK_FALSE(song_parse_progression("  ", m));
}

TEST_CASE("song helpers: Roman numerals become chord names in the key, and a pad of chords parses back") {
    CHECK(*song_roman_progression("i VI III VII", 9, "minor") == "Am F C G");
    CHECK(*song_roman_progression("I V vi IV", 0, "major") == "C G Am F");
    CHECK(*song_roman_progression("I bVII IV", 7, "major") == "G F C");
    CHECK(*song_roman_progression("ii V7 I*2", 0, "major") == "Dm G7 C*2");
    CHECK(*song_roman_progression("vii\xC2\xB0 viidim", 0, "major") == "Bdim Bdim");
    CHECK(*song_roman_progression("i iv v", 2, "minor") == "Dm Gm Am");
    auto bad = song_roman_progression("I IX", 0, "major");
    REQUIRE_FALSE(bad);
    CHECK(bad.error().message.find("IX") != std::string::npos);
    CHECK_FALSE(song_roman_progression("I V", 0, "nope"));
    CHECK_FALSE(song_roman_progression("   ", 0, "major"));

    SongMeter m;
    auto prog = song_parse_progression("Am F*2 G", m);
    REQUIRE(prog);
    auto pad = song_chord_pad(*prog, m, {});
    REQUIRE(pad);
    std::vector<SongIssue> issues;
    SongPattern p = notes_of(*pad, &issues, 4);
    CHECK(issues.empty());
    CHECK(p.bars == 4);
    CHECK(p.events.front().chord == "Am");
    CHECK(p.events.front().pitches.size() == 3);
    SongPadOptions bad2;
    bad2.octave = 9;
    CHECK_FALSE(song_chord_pad(*prog, m, bad2));
}

TEST_CASE("song helpers: arpeggios parse back as notes of the right length") {
    SongMeter m;
    auto prog = song_parse_progression("Am F C G", m);
    REQUIRE(prog);
    for (const char* dir : {"up", "down", "updown", "downup", "random"}) {
        SongArpeggioOptions o;
        o.direction = dir;
        o.octaves = 2;
        auto text = song_arpeggio(*prog, m, o);
        REQUIRE_MESSAGE(bool(text), dir);
        std::vector<SongIssue> issues;
        SongPattern p = notes_of(*text, &issues, 4);
        INFO(*text);
        CHECK(issues.empty());
        CHECK(p.bars == 4);
        CHECK(p.events.size() == 64);
    }
    SongArpeggioOptions up;
    auto first = song_arpeggio(*prog, m, up);
    REQUIRE(first);
    SongPattern fp = notes_of(*first, nullptr, 4);
    CHECK(fp.events[0].pitches == std::vector<int>{57});   // A3
    CHECK(fp.events[1].pitches == std::vector<int>{60});   // C4
    CHECK(fp.events[2].pitches == std::vector<int>{64});   // E4
    CHECK(fp.events[3].pitches == std::vector<int>{57});   // and round again
    // Random is a function of the seed.
    SongArpeggioOptions r1, r2, r3;
    r1.direction = r2.direction = r3.direction = "random";
    r1.seed = r2.seed = 7;
    r3.seed = 8;
    CHECK(*song_arpeggio(*prog, m, r1) == *song_arpeggio(*prog, m, r2));
    CHECK(*song_arpeggio(*prog, m, r1) != *song_arpeggio(*prog, m, r3));
    // Triplets and errors.
    SongArpeggioOptions trip;
    trip.rate = 8;
    trip.triplet = true;
    auto t = song_arpeggio(*prog, m, trip);
    REQUIRE(t);
    CHECK(notes_of(*t, nullptr, 4).events.size() == 48);
    SongArpeggioOptions bad;
    bad.direction = "upp";
    auto e = song_arpeggio(*prog, m, bad);
    REQUIRE_FALSE(e);
    CHECK(e.error().hint.find("up") != std::string::npos);
    bad = {};
    bad.rate = 5;
    CHECK_FALSE(song_arpeggio(*prog, m, bad));
}

TEST_CASE("song helpers: basslines follow the chords in every style") {
    SongMeter m;
    auto prog = song_parse_progression("Am F C G", m);
    REQUIRE(prog);
    for (const auto& style : song_bass_styles()) {
        SongBassOptions o;
        o.style = style.first;
        auto text = song_bassline(*prog, m, o);
        REQUIRE_MESSAGE(bool(text), style.first);
        std::vector<SongIssue> issues;
        SongPattern p = notes_of(*text, &issues, 4);
        INFO(style.first << ": " << *text);
        CHECK(issues.empty());
        CHECK(p.bars == 4);
        CHECK(p.events.size() >= 16);
        // The first note of every bar is the chord's root.
        CHECK(p.events[0].pitches[0] % 12 == 9);
        for (const SongEvent& e : p.events) {
            CHECK(e.pitches[0] >= 24);
            CHECK(e.pitches[0] <= 60);
        }
    }
    SongBassOptions walk;
    walk.style = "walking";
    SongPattern w = notes_of(*song_bassline(*prog, m, walk), nullptr, 4);
    CHECK(w.events.size() == 16);
    CHECK(w.events[4].pitches[0] % 12 == 5);  // F
    SongBassOptions bad;
    bad.style = "walkin";
    auto e = song_bassline(*prog, m, bad);
    REQUIRE_FALSE(e);
    CHECK(e.error().hint.find("walking") != std::string::npos);
}

TEST_CASE("song helpers: drum styles parse as grids and fit the meter") {
    SongMeter four;
    SongMeter three{3, 4};
    for (const SongDrumStyle& style : song_drum_styles()) {
        const SongMeter& m = style.meter == "3/4" ? three : four;
        for (bool fill : {false, true}) {
            auto j = song_drum_pattern(style.name, m, 2, fill);
            REQUIRE_MESSAGE(bool(j), style.name);
            SongPattern p;
            std::vector<SongIssue> issues;
            const bool ok = song_parse_drum_grid(*j, "/p", m, {}, p, issues);
            INFO(style.name << " " << j->dump());
            CHECK(ok);
            CHECK(p.bars == 2);
        }
    }
    auto wrong = song_drum_pattern("waltz", four, 1, false);
    REQUIRE_FALSE(wrong);
    CHECK(wrong.error().message.find("3/4") != std::string::npos);
    auto typo = song_drum_pattern("rok", four, 1, false);
    REQUIRE_FALSE(typo);
    CHECK(typo.error().hint.find("rock") != std::string::npos);
    // A fill puts toms in the last beat and takes the kick out of it.
    auto f = song_drum_pattern("rock", four, 1, true);
    REQUIRE(f);
    CHECK((*f)["grid"].contains("tom_low"));
    CHECK((*f)["grid"]["kick"].get<std::string>().substr(12) == "....");
}

// ---- checks ------------------------------------------------------------------------------------------------------------

TEST_CASE("check off_key: a note outside the key is reported once with a count; passing tones and in-key notes are not") {
    SongCheckOptions o;
    o.rules = {"off_key"};
    Json bad = song_of({{"lead", "keys", "C4:4 F#4 G4 F#4"}});
    SongCheckReport r = check_of(bad, o);
    REQUIRE(r.issues.size() == 1);
    CHECK(r.issues[0].count == 2);
    CHECK(r.issues[0].track == "lead");
    CHECK(r.issues[0].rule == "off_key");
    CHECK(r.issues[0].position == "bar 1, beat 2");
    CHECK(r.issues[0].source.line == 1);
    CHECK(r.issues[0].source.column == 6);
    CHECK(r.issues[0].hint.find("F or G") != std::string::npos);
    CHECK_FALSE(r.ok());

    CHECK(check_of(song_of({{"lead", "keys", "C4:4 D4 E4 G4"}}), o).issues.empty());
    // A short off-beat chromatic note is a passing tone.
    CHECK(check_of(song_of({{"lead", "keys", "C4:4 D4:8 C#4:8 E4:4 G4:4"}}), o).issues.empty());
    // The same note is fine in the key that has it.
    CHECK(check_of(song_of({{"lead", "keys", "C4:4 F#4 G4 F#4"}}, "G", "major"), o).issues.empty());
    // A chord by name with a note outside the key is found too.
    CHECK(check_of(song_of({{"pad", "pad", "(D):1"}}), o).issues.size() == 1);
}

TEST_CASE("check range: a note outside the instrument's range, or the track's own range") {
    SongCheckOptions o;
    o.rules = {"range"};
    SongCheckReport r = check_of(song_of({{"bass", "bass", "C6:1"}}), o);
    REQUIRE(r.issues.size() == 1);
    CHECK(r.issues[0].rule == "range");
    CHECK(r.issues[0].message.find("above") != std::string::npos);
    r = check_of(song_of({{"bass", "bass", "C0:1"}}), o);
    REQUIRE(r.issues.size() == 1);
    CHECK(r.issues[0].message.find("below") != std::string::npos);
    CHECK(check_of(song_of({{"bass", "bass", "C2:1"}}), o).issues.empty());
    Json custom = song_of({{"bass", "bass", "C6:1"}});
    custom["tracks"]["bass"]["range"] = Json::array({"C5", "C7"});
    CHECK(check_of(custom, o).issues.empty());
    // Transposing moves the note into or out of the range.
    Json transposed = song_of({{"bass", "bass", "C2:1"}});
    transposed["tracks"]["bass"]["transpose"] = 48;
    CHECK(check_of(transposed, o).issues.size() == 1);
}

TEST_CASE("check clash: minor seconds and tritones together on a strong beat") {
    SongCheckOptions o;
    o.rules = {"clash"};
    SongCheckReport r = check_of(song_of({{"a", "keys", "C4:1"}, {"b", "pad", "C#4:1"}}), o);
    REQUIRE(r.issues.size() == 1);
    CHECK(r.issues[0].message.find("minor second") != std::string::npos);
    CHECK(r.issues[0].count == 4);  // sounding together on 4 strong beats
    r = check_of(song_of({{"a", "keys", "F4:1"}, {"b", "pad", "B4:1"}}), o);
    REQUIRE(r.issues.size() == 1);
    CHECK(r.issues[0].message.find("tritone") != std::string::npos);
    CHECK(check_of(song_of({{"a", "keys", "C4:1"}, {"b", "pad", "E4:1"}}), o).issues.empty());
    // The tritone inside a G7 chord written by name is the chord's own.
    CHECK(check_of(song_of({{"a", "keys", "(G7):1"}}), o).issues.empty());
    // A clash only on an off-beat is not on a strong beat.
    CHECK(check_of(song_of({{"a", "keys", "r:8 C4:8 r:4 r:2"}, {"b", "pad", "r:8 C#4:8 r:4 r:2"}}), o).issues.empty());
}

TEST_CASE("check mud: close low notes") {
    SongCheckOptions o;
    o.rules = {"mud"};
    SongCheckReport r = check_of(song_of({{"a", "bass", "C2:1"}, {"b", "organ", "D2:1"}}), o);
    REQUIRE(r.issues.size() == 1);
    CHECK(r.issues[0].rule == "mud");
    CHECK(check_of(song_of({{"a", "bass", "C2:1"}, {"b", "organ", "G2:1"}}), o).issues.empty());
    // The same interval above C3 is fine.
    CHECK(check_of(song_of({{"a", "bass", "C3:1"}, {"b", "organ", "D3:1"}}), o).issues.empty());
}

TEST_CASE("check structure: silent tracks and sections, unused patterns") {
    SongCheckOptions o;
    o.rules = {"structure"};
    Json j = song_of({{"lead", "keys", "C4:1"}});
    j["tracks"]["spare"] = {{"instrument", "pad"}, {"patterns", {{"a", "C3:1"}, {"b", "D3:1"}}}};
    j["sections"][0]["play"]["spare"] = "a";
    j["sections"][0]["mute"] = Json::array({"spare"});
    SongCheckReport r = check_of(j, o);
    bool silentTrack = false, unused = false;
    for (const SongCheckIssue& i : r.issues) {
        silentTrack |= i.severity == "warning" && i.message.find("`spare` never plays") != std::string::npos;
        unused |= i.severity == "info" && i.message.find("`b`") != std::string::npos;
    }
    CHECK(silentTrack);
    CHECK(unused);
    // Info alone does not fail ok().
    Json fine = song_of({{"lead", "keys", "C4:1"}});
    fine["tracks"]["lead"]["patterns"]["extra"] = "D4:1";
    r = check_of(fine, o);
    CHECK(r.issues.size() == 1);
    CHECK(r.ok());
    CHECK(check_of(song_of({{"lead", "keys", "C4:1"}}), o).issues.empty());
    // A section where everything is muted has no notes.
    Json silent = song_of({{"lead", "keys", "C4:1"}});
    silent["sections"].push_back(Json::parse(R"({"name": "quiet", "bars": 1, "play": {"lead": "a"}, "mute": ["lead"]})"));
    r = check_of(silent, o);
    bool section = false;
    for (const SongCheckIssue& i : r.issues) section |= i.message.find("section `quiet`") != std::string::npos;
    CHECK(section);
}

TEST_CASE("check: unknown rule suggests, severity order, rule catalog") {
    SongDoc s = parsed(base_song());
    SongTimeline t = expanded(s);
    SongCheckOptions o;
    o.rules = {"of_key"};
    auto r = check_song(s, t, o);
    REQUIRE_FALSE(r);
    CHECK(r.error().hint.find("off_key") != std::string::npos);
    std::set<std::string> names;
    for (const SongCheckRule& rule : song_check_rules()) names.insert(rule.name);
    CHECK(names == std::set<std::string>{"off_key", "range", "clash", "mud", "structure", "loudness"});
    // By default the loudness rule (a render) does not run.
    CHECK(check_of(base_song()).rulesRun.size() == 5);
}

TEST_CASE("check loudness: renders the song, finds clipping and a loudness off the target") {
    SongCheckOptions o;
    o.rules = {"loudness"};
    o.sampleRate = 16000;
    Json quiet = song_of({{"lead", "keys", "C4:1"}});
    quiet["volume"] = 0.8;
    SongCheckReport r = check_of(quiet, o);
    CHECK(r.rendered);
    CHECK(r.lufs < 0.0);
    CHECK(r.lufs > -60.0);
    CHECK(r.peakDb < -1.0);
    CHECK(r.issues.empty());
    // A target far from the measured loudness is a warning with the factor to apply.
    o.targetLufs = r.lufs + 8.0;
    SongCheckReport off = check_of(quiet, o);
    REQUIRE(off.issues.size() == 1);
    CHECK(off.issues[0].message.find("target") != std::string::npos);
    CHECK(off.issues[0].hint.find("volume") != std::string::npos);
    o.targetLufs = r.lufs + 1.0;
    CHECK(check_of(quiet, o).issues.empty());
    // Many loud tracks at a high master volume clip.
    std::vector<T> loud;
    for (int i = 0; i < 8; ++i) loud.push_back({"t" + std::to_string(i), "organ", "C3:1"});
    Json clip = song_of(loud);
    clip["volume"] = 1.5;
    for (auto& kv : clip["tracks"].items()) kv.value()["volume"] = 2.0;
    SongCheckReport c = check_of(clip, o);
    bool error = false;
    for (const SongCheckIssue& i : c.issues) error |= i.severity == "error" && i.message.find("clips") != std::string::npos;
    CHECK(error);
    CHECK(c.peakDb > 0.0);
    // The default run does not render.
    CHECK_FALSE(check_of(quiet).rendered);
}

// ---- preview -----------------------------------------------------------------------------------------------------------

TEST_CASE("song preview: deterministic stereo render of the right length") {
    SongDoc s = parsed(base_song());
    SongTimeline t = expanded(s);
    SongRenderOptions o;
    o.sampleRate = 16000;
    o.tailSeconds = 1.0;
    auto a = render_song(s, t, o);
    auto b = render_song(s, t, o);
    REQUIRE(a);
    REQUIRE(b);
    CHECK(a->clip.channels == 2);
    CHECK(a->clip.sampleRate == 16000);
    CHECK(a->clip.seconds() == doctest::Approx(5.0).epsilon(0.01));
    CHECK(a->seconds == doctest::Approx(4.0));
    CHECK(a->notes == 20);
    CHECK(a->renders > 0);
    CHECK(a->renders <= a->notes);
    CHECK(a->clip.samples == b->clip.samples);
    CHECK(a->clip.peakDb < 0.0);
    CHECK(a->clip.peakDb > -40.0);
    CHECK(a->clip.lufs > -50.0);
    // Another seed changes the noise of the drums.
    o.seed = 3;
    auto c = render_song(s, t, o);
    REQUIRE(c);
    CHECK(c->clip.samples != a->clip.samples);
}

TEST_CASE("song preview: pan, volume lanes, solo, mute and a range of bars") {
    Json j = song_of({{"lead", "keys", "C4:2 E4:2"}});
    j["tracks"]["lead"]["pan"] = -1.0;
    SongDoc s = parsed(j);
    SongTimeline t = expanded(s);
    SongRenderOptions o;
    o.sampleRate = 16000;
    auto r = render_song(s, t, o);
    REQUIRE(r);
    double left = 0, right = 0;
    for (std::size_t i = 0; i + 1 < r->clip.samples.size(); i += 2) {
        left = std::max(left, double(std::abs(r->clip.samples[i])));
        right = std::max(right, double(std::abs(r->clip.samples[i + 1])));
    }
    CHECK(left > 0.01);
    CHECK(right < 1e-6);

    // A volume lane at 0 silences the track.
    j["tracks"]["lead"]["automation"] = Json::parse(R"([{"param": "volume", "points": [[0, 0], [8, 0]]}])");
    s = parsed(j);
    r = render_song(s, expanded(s), o);
    REQUIRE(r);
    CHECK(r->clip.peakDb < -100.0);

    // Solo and mute.
    s = parsed(base_song());
    t = expanded(s);
    o.solo = {"drums"};
    auto solo = render_song(s, t, o);
    REQUIRE(solo);
    CHECK(solo->notes == 12);
    o.solo.clear();
    o.mute = {"drums"};
    auto muted = render_song(s, t, o);
    REQUIRE(muted);
    CHECK(muted->notes == 8);
    o.mute = {"drumz"};
    auto bad = render_song(s, t, o);
    REQUIRE_FALSE(bad);
    CHECK(bad.error().hint.find("drums") != std::string::npos);

    // A range: the second bar only.
    o = {};
    o.sampleRate = 16000;
    o.fromBar = 2;
    o.bars = 1;
    o.tailSeconds = 0.5;
    auto part = render_song(s, t, o);
    REQUIRE(part);
    CHECK(part->seconds == doctest::Approx(2.0));
    CHECK(part->notes == 4 + 6);
    // Too long for maxSeconds, a bar past the end.
    o = {};
    o.maxSeconds = 1.0;
    auto longer = render_song(s, t, o);
    REQUIRE_FALSE(longer);
    CHECK(longer.error().hint.find("fromBar") != std::string::npos);
    o = {};
    o.fromBar = 9;
    CHECK_FALSE(render_song(s, t, o));
}

TEST_CASE("song preview: a filter lane darkens the track and a macro lane reaches the instrument") {
    Json j = song_of({{"lead", "lead", "C5:2 E5:2"}});
    SongDoc open = parsed(j);
    j["tracks"]["lead"]["automation"] = Json::parse(R"([{"param": "filter", "points": [[0, 200], [4, 200]]}])");
    SongDoc closed = parsed(j);
    SongRenderOptions o;
    o.sampleRate = 16000;
    auto a = render_song(open, expanded(open), o);
    auto b = render_song(closed, expanded(closed), o);
    REQUIRE(a);
    REQUIRE(b);
    CHECK(b->clip.peakDb < a->clip.peakDb - 6.0);
    j = song_of({{"lead", "lead", "C5:2 E5:2"}});
    j["tracks"]["lead"]["automation"] = Json::parse(R"([{"param": "macro.brightness", "points": [[0, 1], [4, 1]]}])");
    SongDoc bright = parsed(j);
    auto c = render_song(bright, expanded(bright), o);
    REQUIRE(c);
    CHECK(c->clip.samples != a->clip.samples);
}
