// MIDI files and songs (M56.3): the SMF reader on hand-built byte buffers (running status, several tracks, tempo changes, drums), its
// errors, the import into a song document (instruments, drum lanes, velocities, the sustain pedal, quantize, sections, repeated bars)
// and the export, with the round trip import(export(song)).
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <map>
#include <set>
#include <string>
#include <tuple>
#include <vector>

#include "fa/audio/midi.h"
#include "fa/audio/song.h"
#include "fa/audio/song_midi.h"

using namespace fa;

namespace {

// A MIDI file written byte by byte, so the tests do not depend on the writer they test.
struct Bytes {
    std::vector<std::uint8_t> v;
    Bytes& b(std::initializer_list<int> bytes) {
        for (int x : bytes) v.push_back(std::uint8_t(x));
        return *this;
    }
    Bytes& vlq(std::uint32_t n) {
        std::vector<std::uint8_t> tmp = {std::uint8_t(n & 0x7F)};
        while (n >>= 7) tmp.push_back(std::uint8_t((n & 0x7F) | 0x80));
        v.insert(v.end(), tmp.rbegin(), tmp.rend());
        return *this;
    }
    Bytes& text(const std::string& s) {
        v.insert(v.end(), s.begin(), s.end());
        return *this;
    }
};

std::vector<std::uint8_t> chunk(const char* id, const Bytes& body) {
    std::vector<std::uint8_t> out(id, id + 4);
    const auto n = std::uint32_t(body.v.size());
    for (int s = 24; s >= 0; s -= 8) out.push_back(std::uint8_t(n >> s));
    out.insert(out.end(), body.v.begin(), body.v.end());
    return out;
}

std::vector<std::uint8_t> smf(int format, int division, const std::vector<Bytes>& tracks) {
    Bytes head;
    head.b({0, format, int(tracks.size() >> 8), int(tracks.size() & 0xFF), division >> 8, division & 0xFF});
    std::vector<std::uint8_t> out = chunk("MThd", head);
    for (const Bytes& t : tracks) {
        const auto c = chunk("MTrk", t);
        out.insert(out.end(), c.begin(), c.end());
    }
    return out;
}

Bytes meta(std::uint32_t delta, int type, const std::vector<int>& data) {
    Bytes b;
    b.vlq(delta).b({0xFF, type}).vlq(std::uint32_t(data.size()));
    for (int d : data) b.v.push_back(std::uint8_t(d));
    return b;
}

void append(Bytes& to, const Bytes& more) { to.v.insert(to.v.end(), more.v.begin(), more.v.end()); }

Bytes end_of_track(std::uint32_t delta = 0) { return meta(delta, 0x2F, {}); }

// The conductor track: 120 BPM (500000 us), 3/4, key of D major (2 sharps), a marker "intro" at the start and "loop" at tick `loopAt`.
Bytes conductor(int loopAt, std::uint32_t endDelta) {
    Bytes t;
    append(t, meta(0, 0x51, {0x07, 0xA1, 0x20}));
    append(t, meta(0, 0x58, {3, 2, 24, 8}));
    append(t, meta(0, 0x59, {2, 0}));
    Bytes m1;
    m1.vlq(0).b({0xFF, 0x06, 5}).text("intro");
    append(t, m1);
    Bytes m2;
    m2.vlq(std::uint32_t(loopAt)).b({0xFF, 0x06, 4}).text("loop");
    append(t, m2);
    append(t, end_of_track(endDelta));
    return t;
}

Json notes_of(const MidiImportResult& r, const std::string& track, const std::string& pattern) { return r.song["tracks"][track]["patterns"][pattern]; }

// One note of a timeline, reduced to what a round trip keeps.
using Sounded = std::tuple<std::string, std::int64_t, std::int64_t, int, std::string, int>;

std::vector<Sounded> sounded(const SongDoc& song, const SongTimeline& tl) {
    std::vector<Sounded> out;
    for (const SongNote& n : tl.notes) {
        const bool drum = !n.drum.empty();
        out.emplace_back(song.tracks[std::size_t(n.track)].name, n.tick, drum ? 0 : n.gateTicks(), n.pitch, n.drum, n.velocity);
    }
    std::sort(out.begin(), out.end());
    return out;
}

}  // namespace

TEST_CASE("midi: a format 1 file with running status, three tracks, a tempo change and drums is read event by event") {
    // track 2: the lead on channel 1 (program 5), notes written with running status
    Bytes lead;
    append(lead, meta(0, 0x03, {'l', 'e', 'a', 'd'}));
    lead.vlq(0).b({0xC0, 5});
    lead.vlq(0).b({0x90, 60, 100});
    lead.vlq(240).b({62, 80});            // running status: a second note on
    lead.vlq(240).b({60, 0});             // running status, velocity 0 = note off
    lead.vlq(0).b({62, 0});
    lead.vlq(0).b({0xB0, 64, 127});       // sustain pedal down
    append(lead, end_of_track(480));
    // track 3: drums on channel 10
    Bytes drums;
    drums.vlq(0).b({0x99, 36, 127});
    drums.vlq(120).b({0x89, 36, 0});
    drums.vlq(360).b({0x99, 38, 100});
    drums.vlq(120).b({0x89, 38, 0});
    append(drums, end_of_track());
    Bytes cond = conductor(1440, 0);
    // a tempo change at tick 960: 100 BPM = 600000 us
    Bytes cond2;
    append(cond2, meta(0, 0x51, {0x07, 0xA1, 0x20}));
    append(cond2, meta(960, 0x51, {0x09, 0x27, 0xC0}));
    append(cond2, end_of_track());

    auto file = parse_midi(smf(1, 480, {cond2, lead, drums}), "song.mid");
    REQUIRE(file);
    CHECK(file->format == 1);
    CHECK(file->division == 480);
    REQUIRE(file->tracks.size() == 3);
    const auto& ev = file->tracks[1].events;
    REQUIRE(ev.size() >= 8);
    CHECK(ev[1].kind == kMidiProgram);
    CHECK(ev[1].data1 == 5);
    CHECK(ev[2].kind == kMidiNoteOn);
    CHECK(ev[2].data1 == 60);
    CHECK(ev[2].data2 == 100);
    CHECK(ev[3].kind == kMidiNoteOn);   // running status
    CHECK(ev[3].tick == 240);
    CHECK(ev[3].data1 == 62);
    CHECK(ev[3].data2 == 80);
    CHECK(ev[4].tick == 480);
    CHECK(ev[4].data2 == 0);
    CHECK(file->tracks[2].events[0].channel == 9);
    CHECK(file->tracks[0].events[1].tick == 960);

    auto imported = midi_to_song(*file);
    REQUIRE(imported);
    bool tempoWarning = false;
    for (const auto& w : imported->warnings) tempoWarning = tempoWarning || w.find("changes tempo") != std::string::npos;
    CHECK(tempoWarning);
    CHECK(imported->tempo == 120.0);
}

TEST_CASE("midi: the reader's errors name the byte offset, what was expected and what to do") {
    SUBCASE("not a MIDI file") {
        std::vector<std::uint8_t> junk(40, 'x');
        auto r = parse_midi(junk, "junk.mid");
        REQUIRE_FALSE(r);
        CHECK(r.error().message.find("junk.mid: byte offset 0") != std::string::npos);
        CHECK(r.error().message.find("MThd") != std::string::npos);
        CHECK_FALSE(r.error().hint.empty());
    }
    SUBCASE("too short") {
        auto r = parse_midi({'M', 'T', 'h', 'd'}, "tiny.mid");
        REQUIRE_FALSE(r);
        CHECK(r.error().message.find("byte offset 0") != std::string::npos);
    }
    SUBCASE("format 2 and SMPTE are rejected with the way out") {
        Bytes t;
        append(t, end_of_track());
        auto f2 = smf(2, 480, {t});
        auto r2 = parse_midi(f2, "f2.mid");
        REQUIRE_FALSE(r2);
        CHECK(r2.error().message.find("format 2") != std::string::npos);
        CHECK(r2.error().hint.find("format 1") != std::string::npos);
        auto smpte = smf(1, 0xE728, {t});
        auto rs = parse_midi(smpte, "smpte.mid");
        REQUIRE_FALSE(rs);
        CHECK(rs.error().message.find("SMPTE") != std::string::npos);
    }
    SUBCASE("a data byte where a status byte is expected, without running status") {
        Bytes t;
        t.vlq(0).b({0x40, 0x40});
        append(t, end_of_track());
        auto f = smf(0, 480, {t});
        auto r = parse_midi(f, "bad.mid");
        REQUIRE_FALSE(r);
        // header 14 + chunk header 8 + the delta byte: the offending byte is the 24th (offset 23)
        CHECK(r.error().message.find("byte offset 23") != std::string::npos);
        CHECK(r.error().message.find("status byte") != std::string::npos);
    }
    SUBCASE("a track cut short") {
        Bytes t;
        t.vlq(0).b({0x90, 60});  // the velocity is missing and the chunk ends
        auto f = smf(0, 480, {t});
        auto r = parse_midi(f, "cut.mid");
        REQUIRE_FALSE(r);
        CHECK(r.error().message.find("cut short") != std::string::npos);
    }
    SUBCASE("a chunk longer than the file") {
        Bytes t;
        append(t, end_of_track());
        auto f = smf(0, 480, {t});
        f.resize(f.size() - 2);
        auto r = parse_midi(f, "trunc.mid");
        REQUIRE_FALSE(r);
        CHECK(r.error().message.find("MTrk") != std::string::npos);
        CHECK(r.error().message.find("byte offset") != std::string::npos);
    }
}

TEST_CASE("midi: import maps tempo, meter, key, markers, programs, drums, velocities and the sustain pedal") {
    Bytes lead;
    append(lead, meta(0, 0x03, {'l', 'e', 'a', 'd'}));
    lead.vlq(0).b({0xC0, 4});             // electric piano
    lead.vlq(0).b({0xB0, 7, 100});        // volume
    lead.vlq(0).b({0x90, 62, 97});        // D4 at velocity 97
    lead.vlq(240).b({0x80, 62, 0});       // released after an eighth...
    lead.vlq(0).b({0x90, 64, 55});        // E4, played while the pedal is down
    lead.vlq(0).b({0xB0, 64, 127});
    lead.vlq(240).b({0x80, 64, 0});       // ...key up at 480 but the pedal holds it
    lead.vlq(480).b({0xB0, 64, 0});       // pedal up at 960: the note lasts to 960 + 0
    append(lead, end_of_track(0));
    Bytes drums;
    drums.vlq(0).b({0x99, 36, 127});
    drums.vlq(0).b({0x99, 42, 40});
    drums.vlq(240).b({0x99, 38, 100});
    drums.vlq(0).b({0x99, 42, 100});
    drums.vlq(0).b({0x99, 60, 100});      // bongo: no lane
    append(drums, end_of_track(240));
    auto file = parse_midi(smf(1, 480, {conductor(1440, 2880), lead, drums}), "demo.mid");
    REQUIRE(file);
    MidiImportOptions o;
    o.source = "demo.mid";
    auto r = midi_to_song(*file, o);
    REQUIRE(r);
    CHECK(r->tempo == 120.0);
    CHECK(r->meter == "3/4");
    CHECK(r->key == "D");
    CHECK(r->mode == "major");
    CHECK(r->tracks == 2);

    const Json& tracks = r->song["tracks"];
    REQUIRE(tracks.contains("lead"));
    CHECK(tracks["lead"]["instrument"] == "epiano");
    CHECK(tracks["lead"]["volume"].get<double>() == doctest::Approx(0.79));
    CHECK(tracks["drums"]["instrument"] == "kit");
    const Json& grid = tracks["drums"]["patterns"]["p1"]["grid"];
    CHECK(grid["kick"].get<std::string>() == "X.....");
    CHECK(grid["snare"].get<std::string>() == ".x....");
    CHECK(grid["hat"].get<std::string>() == "ox....");

    // sections from the markers: "intro" at bar 1, "loop" at bar 2 (3/4: a bar is 1440 ticks)
    const Json& sections = r->song["sections"];
    REQUIRE(sections.size() == 2);
    CHECK(sections[0]["name"] == "intro");
    CHECK(sections[0]["kind"] == "intro");
    CHECK(sections[1]["kind"] == "loop");
    CHECK(sections[0]["bars"] == 1);

    // the song parses and plays what was written: D4 v97 (an eighth), E4 v55 held by the pedal to tick 960 (from 480... written at 240)
    auto song = parse_song(r->song, "demo");
    REQUIRE(song);
    auto tl = expand_song(*song);
    REQUIRE(tl);
    std::vector<std::tuple<std::int64_t, std::int64_t, int, int>> lead_notes;
    for (const SongNote& n : tl->notes)
        if (song->tracks[std::size_t(n.track)].name == "lead") lead_notes.emplace_back(n.tick, n.gateTicks(), n.pitch, n.velocity);
    REQUIRE(lead_notes.size() == 2);
    CHECK(lead_notes[0] == std::make_tuple(std::int64_t(0), std::int64_t(480), 62, 97));
    // E4 starts at 480 song ticks (240 file ticks x 960/480... 240 file ticks = 480), the pedal goes up at file tick 960 = 1920
    CHECK(std::get<0>(lead_notes[1]) == 480);
    CHECK(std::get<1>(lead_notes[1]) == 1440);
    CHECK(std::get<2>(lead_notes[1]) == 64);
    CHECK(std::get<3>(lead_notes[1]) == 55);
}

TEST_CASE("midi: programs map to the nearest built-in instrument by family, and the drum keys to the kit's lanes") {
    CHECK(gm_program_instrument(0) == "piano");
    CHECK(gm_program_instrument(4) == "epiano");
    CHECK(gm_program_instrument(19) == "organ");
    CHECK(gm_program_instrument(33) == "bass_pluck");
    CHECK(gm_program_instrument(48) == "strings");
    CHECK(gm_program_instrument(56) == "brass");
    CHECK(gm_program_instrument(73) == "flute");
    CHECK(gm_program_instrument(81) == "lead_saw");
    CHECK(gm_program_instrument(95) == "pad_sweep");
    CHECK(gm_program_instrument(127) == "pad_dark");
    CHECK(*gm_drum_lane(36) == "kick");
    CHECK(*gm_drum_lane(38) == "snare");
    CHECK(*gm_drum_lane(42) == "hat");
    CHECK(*gm_drum_lane(46) == "openhat");
    CHECK(*gm_drum_lane(49) == "crash");
    CHECK_FALSE(gm_drum_lane(60).has_value());
    for (const char* lane : {"kick", "snare", "clap", "rim", "hat", "openhat", "hat_pedal", "shaker", "tambourine", "tom_low", "tom_mid", "tom_high", "ride", "crash", "cowbell"})
        CHECK(*gm_drum_lane(gm_drum_key(lane)) == lane);
    CHECK(gm_drum_key("conga") < 0);
    CHECK(gm_instrument_program("strings") == 48);
    CHECK(gm_instrument_program("nope") < 0);
}

TEST_CASE("midi: quantize moves notes to a grid, and 'off' keeps the timing the note text can write") {
    Bytes t;
    append(t, meta(0, 0x58, {4, 2, 24, 8}));
    t.vlq(0).b({0x90, 60, 90});
    t.vlq(250).b({0x80, 60, 0});       // 250 ticks at 480 ppq: a bit over a sixteenth (120)... = 500 song ticks
    t.vlq(230).b({0x90, 62, 90});
    t.vlq(250).b({0x80, 62, 0});
    append(t, end_of_track(1000));
    auto file = parse_midi(smf(0, 480, {t}), "q.mid");
    REQUIRE(file);
    auto count_starts = [&](const std::string& q, std::set<std::int64_t>& starts) {
        MidiImportOptions o;
        o.quantize = q;
        auto r = midi_to_song(*file, o);
        REQUIRE(r);
        auto song = parse_song(r->song, "q");
        REQUIRE(song);
        auto tl = expand_song(*song);
        REQUIRE(tl);
        starts.clear();
        for (const SongNote& n : tl->notes) starts.insert(n.tick);
    };
    std::set<std::int64_t> off, sixteenth;
    count_starts("off", off);
    count_starts("16", sixteenth);
    CHECK(off == std::set<std::int64_t>{0, 960});       // 230 + 250 file ticks = 480 = 960 song ticks
    CHECK(sixteenth == std::set<std::int64_t>{0, 960});
    MidiImportOptions bad;
    bad.quantize = "7";
    auto r = midi_to_song(*file, bad);
    REQUIRE_FALSE(r);
    CHECK(r.error().message.find("quantize") != std::string::npos);
    CHECK(r.error().hint.find("\"16\"") != std::string::npos);
}

TEST_CASE("midi: exact repeats of a bar are one pattern played several times") {
    Bytes t;
    // four identical bars of 4/4 at 480 ppq: C4 on every beat
    for (int bar = 0; bar < 4; ++bar)
        for (int beat = 0; beat < 4; ++beat) {
            t.vlq(0).b({0x90, 60, 90});
            t.vlq(240).b({0x80, 60, 0});
            t.vlq(0).b({0x90, 62, 90});  // a different note in the second half so the bar is not trivially one note
            t.vlq(240).b({0x80, 62, 0});
        }
    append(t, end_of_track());
    auto file = parse_midi(smf(0, 480, {t}), "rep.mid");
    REQUIRE(file);
    auto r = midi_to_song(*file);
    INFO(std::string(r.ok() ? "" : r.error().message));
    REQUIRE(r);
    CHECK(r->patterns == 1);
    const Json& play = r->song["sections"][0]["play"];
    REQUIRE(play.size() == 1);
    const std::string text = play.begin()->get<std::string>();
    CHECK(text.find("*") != std::string::npos);
}

TEST_CASE("midi: the export writes a format 1 file with tempo, meter, key, markers, programs and drums on channel 10") {
    const Json doc = Json::parse(R"({
      "format": "factoria.song/1", "tempo": 96, "meter": "3/4", "key": "A", "mode": "minor",
      "tracks": {
        "pad": {"instrument": "pad", "volume": 0.5, "pan": -1, "patterns": {"a": "(Am@3):2. | (F@3):2."}},
        "beat": {"instrument": "kit", "patterns": {"g": {"step": "8", "grid": {"kick": "x.x.x.", "snare": ".X.o.."}}}}
      },
      "sections": [{"name": "intro", "kind": "intro", "play": {"pad": "a"}},
                   {"name": "main", "kind": "loop", "play": {"pad": "a", "beat": "g"}}]})");
    auto song = parse_song(doc, "export");
    REQUIRE(song);
    auto tl = expand_song(*song);
    REQUIRE(tl);
    auto out = song_to_midi(*song, *tl);
    REQUIRE(out);
    CHECK(out->tracks == 2);
    auto file = parse_midi(out->bytes, "export.mid");
    REQUIRE(file);
    CHECK(file->format == 1);
    CHECK(file->division == 960);
    REQUIRE(file->tracks.size() == 3);
    // the conductor
    std::map<int, MidiEvent> metas;
    std::vector<std::string> markers;
    for (const MidiEvent& e : file->tracks[0].events) {
        if (e.kind != kMidiMeta) continue;
        if (e.metaType == kMetaMarker) markers.push_back(e.text());
        else metas[e.metaType] = e;
    }
    CHECK(metas[kMetaTempo].data == std::vector<std::uint8_t>{0x09, 0x89, 0x68});  // 625000 us
    CHECK(metas[kMetaTimeSignature].data[0] == 3);
    CHECK(metas[kMetaTimeSignature].data[1] == 2);
    CHECK(metas[kMetaKeySignature].data[0] == 0);  // A minor: no sharps
    CHECK(metas[kMetaKeySignature].data[1] == 1);
    CHECK(markers == std::vector<std::string>{"intro", "loop:main"});
    // the pad: channel 0, program 88, volume 64, pan 0
    int program = -1, volume = -1, pan = -1;
    int ons = 0;
    for (const MidiEvent& e : file->tracks[1].events) {
        if (e.kind == kMidiProgram) program = e.data1;
        if (e.kind == kMidiController && e.data1 == 7) volume = e.data2;
        if (e.kind == kMidiController && e.data1 == 10) pan = e.data2;
        if (e.kind == kMidiNoteOn) {
            CHECK(e.channel == 0);
            ++ons;
        }
    }
    CHECK(program == 88);
    CHECK(volume == 64);
    CHECK(pan == 0);
    CHECK(ons > 0);
    // the drums: channel 10 (index 9), kick 36, snare 38, velocities 100 / 124 / 52
    std::set<std::pair<int, int>> keyVel;
    for (const MidiEvent& e : file->tracks[2].events)
        if (e.kind == kMidiNoteOn) {
            CHECK(e.channel == 9);
            keyVel.insert({e.data1, e.data2});
        }
    CHECK(keyVel == std::set<std::pair<int, int>>{{36, 100}, {38, 124}, {38, 52}});
}

TEST_CASE("midi: import(export(song)) gives back the same notes, times and velocities") {
    const Json doc = Json::parse(R"({
      "format": "factoria.song/1", "tempo": 110, "meter": "4/4", "key": "D", "mode": "dorian",
      "tracks": {
        "lead": {"instrument": "lead_saw", "patterns": {
            "a": "v96 D4:8 F4 A4:4 C5:8. D5:16 v70 E5:4 | v110 [D4 F4 A4]:4! r:8 G4:8 A4:8t B4 C5 D5:4",
            "b": "v64 C4:4~ C4:2. | D4:1 & v80 A2:1 | G2:2 r:2"}},
        "bass": {"instrument": "bass", "patterns": {"r": "v100 D2:4 D2 A2 D2 | D2:4 D2 C3 A2"}},
        "keys": {"instrument": "piano", "patterns": {"c": "(Dm7@3):2 (G7@3):4' r:4 | (Cmaj7@3):1"}},
        "beat": {"instrument": "kit:electronic", "patterns": {
            "g": {"step": "16", "grid": {"kick": "x...x...x..xx...", "snare": "....X.......o..x", "hat": "x.xxx.xxx.xxx.xx", "crash": "X..............."}}}}},
      "sections": [
        {"name": "intro", "kind": "intro", "play": {"lead": "a", "keys": "c"}},
        {"name": "verse", "kind": "loop", "repeat": 2, "play": {"lead": "b", "bass": "r*2", "beat": "g*2", "keys": "c"}},
        {"name": "end", "kind": "outro", "play": {"lead": "a", "beat": "g"}}]})");
    std::vector<SongIssue> issues;
    auto song = parse_song(doc, "rt", &issues);
    for (const SongIssue& i : issues) MESSAGE(song_issue_text(i));
    REQUIRE(song);
    auto tl = expand_song(*song);
    REQUIRE(tl);
    auto exported = song_to_midi(*song, *tl);
    REQUIRE(exported);
    auto file = parse_midi(exported->bytes, "rt.mid");
    REQUIRE(file);
    auto imported = midi_to_song(*file);
    REQUIRE(imported);
    auto song2 = parse_song(imported->song, "rt2");
    INFO(std::string(song2.ok() ? "" : song2.error().message));
    REQUIRE(song2);
    auto tl2 = expand_song(*song2);
    REQUIRE(tl2);
    const auto a = sounded(*song, *tl);
    const auto b = sounded(*song2, *tl2);
    REQUIRE(a.size() == b.size());
    CHECK(a == b);
    CHECK(song2->tempo == doctest::Approx(110.0));
    CHECK(song2->meter.beats == 4);
    CHECK(song2->keyRoot == song->keyRoot);
    // the instruments come back through the Instrument Name; the sections through the markers
    CHECK(song2->find_track("lead")->instrument == "lead_saw");
    CHECK(song2->find_track("beat")->drums);
    REQUIRE(song2->sections.size() == 3);
    CHECK(song2->sections[0].kind == "intro");
    CHECK(song2->sections[1].kind == "loop");
    CHECK(song2->sections[2].kind == "outro");
    // exact repeats collapsed: far fewer patterns than bars
    CHECK(imported->patterns < imported->bars * imported->tracks);
}

TEST_CASE("midi: a mixed straight and triplet bar is reported when a drum hit has to move") {
    Bytes t;
    t.vlq(0).b({0x99, 36, 100});
    t.vlq(0).b({0x89, 36, 0});
    t.vlq(100).b({0x99, 38, 100});       // 100 file ticks = 200 song ticks: not on any drum grid except by moving
    t.vlq(0).b({0x89, 38, 0});
    append(t, end_of_track(1700));
    auto file = parse_midi(smf(0, 480, {t}), "d.mid");
    REQUIRE(file);
    auto r = midi_to_song(*file);
    REQUIRE(r);
    bool warned = false;
    for (const auto& w : r->warnings) warned = warned || w.find("drum hit") != std::string::npos;
    CHECK(warned);
}

TEST_CASE("midi: a file without notes is an error that says what to check") {
    Bytes t;
    append(t, meta(0, 0x51, {0x07, 0xA1, 0x20}));
    append(t, end_of_track());
    auto file = parse_midi(smf(0, 480, {t}), "empty.mid");
    REQUIRE(file);
    auto r = midi_to_song(*file);
    REQUIRE_FALSE(r);
    CHECK(r.error().message.find("no notes") != std::string::npos);
}

TEST_CASE("midi: slivers the note text cannot write (a 1/48 note or gap) are closed, and the song still parses") {
    Bytes t;
    t.vlq(0).b({0x90, 60, 90});
    t.vlq(10).b({0x80, 60, 0});         // 10 file ticks = 20 song ticks long
    t.vlq(250).b({0x90, 62, 90});       // 250 file ticks later = a gap of 480 + 20 ... then odd lengths
    t.vlq(235).b({0x80, 62, 0});
    t.vlq(10).b({0x90, 64, 90});        // starts 10 file ticks (20 song ticks) after the last one ended
    t.vlq(7).b({0x80, 64, 0});
    append(t, end_of_track(1000));
    auto file = parse_midi(smf(0, 480, {t}), "sliver.mid");
    REQUIRE(file);
    auto r = midi_to_song(*file);
    INFO(std::string(r.ok() ? "" : r.error().message));
    REQUIRE(r);
    auto song = parse_song(r->song, "sliver");
    REQUIRE(song);
    auto tl = expand_song(*song);
    REQUIRE(tl);
    CHECK(tl->notes.size() == 3);
    for (const SongNote& n : tl->notes) CHECK(n.duration >= 40);
}
