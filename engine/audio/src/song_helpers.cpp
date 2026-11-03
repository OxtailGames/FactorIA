// Chord progressions, arpeggiators, basslines and drum styles (fa/audio/song_helpers.h).
#include "fa/audio/song_helpers.h"

#include <algorithm>
#include <cctype>
#include <format>

#include "fa/core/strings.h"
#include "sfx_math.h"

namespace fa {

namespace {

// ---- writing note text -------------------------------------------------------------------------------------------------------

// Appends notes to a note text, writing a duration only when it changes and a bar line at every bar boundary.
struct TextWriter {
    const SongMeter& meter;
    std::string text;
    std::int64_t tick = 0;
    std::int64_t lastDur = -1;
    int lastVel = 90;
    bool pendingBar = false;

    static std::string dur_text(std::int64_t ticks) {
        // The shortest spelling of a tick count: a note value, dotted, or triplet.
        for (int den : {1, 2, 4, 8, 16, 32, 64}) {
            const std::int64_t base = 4 * kSongPpq / den;
            if (ticks == base) return std::to_string(den);
            if (ticks == base * 3 / 2) return std::to_string(den) + ".";
            if (ticks == base * 2 / 3) return std::to_string(den) + "t";
        }
        return "";
    }
    void token(const std::string& t) {
        if (!text.empty()) text += ' ';
        text += t;
    }
    // A note or rest of `ticks`; longer than one note value is split with ties (or rests).
    void put(const std::string& pitch, std::int64_t ticks, int velocity, bool accent, bool staccato) {
        std::int64_t left = ticks;
        const std::int64_t bar = meter.barTicks();
        while (left > 0) {
            // Never write a note across a bar line: it cannot be tied across without breaking the line check.
            std::int64_t chunk = std::min(left, bar - tick % bar);
            std::string d = dur_text(chunk);
            if (d.empty()) {
                // Split into the largest spellable pieces.
                for (int den : {1, 2, 4, 8, 16, 32, 64}) {
                    const std::int64_t base = 4 * kSongPpq / den;
                    if (base <= chunk) { chunk = base; d = std::to_string(den); break; }
                }
            }
            std::string t = pitch;
            if (chunk != lastDur) { t += ":" + d; lastDur = chunk; }
            if (pitch != "r") {
                if (velocity != lastVel && velocity > 0) { t = "v" + std::to_string(velocity) + " " + t; lastVel = velocity; }
                if (accent) t += "!";
                if (staccato) t += "'";
            }
            left -= chunk;
            if (left > 0 && pitch != "r") t += "~";
            token(t);
            tick += chunk;
            if (tick % bar == 0) token("|");
        }
    }
    std::string finish() {
        if (text.size() >= 2 && text.compare(text.size() - 2, 2, " |") == 0) text.resize(text.size() - 2);
        return text;
    }
};

std::string chord_token(const SongChord& c) { return c.name; }

int root_midi(int rootPc, int octave) {
    int m = (octave + 1) * 12 + rootPc;
    if (rootPc >= 7) m -= 12;
    return m;
}

}  // namespace

Result<std::vector<SongChordStep>> song_parse_progression(std::string_view text, const SongMeter& meter, double beatsPerChord) {
    std::vector<SongChordStep> out;
    const std::int64_t defaultTicks = beatsPerChord > 0 ? std::int64_t(beatsPerChord * double(meter.beatTicks()) + 0.5) : meter.barTicks();
    std::size_t i = 0;
    while (i < text.size()) {
        while (i < text.size() && (std::isspace(static_cast<unsigned char>(text[i])) || text[i] == '|' || text[i] == ',')) ++i;
        if (i >= text.size()) break;
        std::size_t j = i;
        while (j < text.size() && !std::isspace(static_cast<unsigned char>(text[j])) && text[j] != '|' && text[j] != ',') ++j;
        std::string word(text.substr(i, j - i));
        i = j;
        std::int64_t ticks = defaultTicks;
        if (const std::size_t star = word.find('*'); star != std::string::npos) {
            const std::string n = word.substr(star + 1);
            if (n.empty() || n.size() > 3 || !std::all_of(n.begin(), n.end(), [](char c) { return c >= '0' && c <= '9'; }) || std::stoi(n) < 1)
                return make_error("`" + word + "`: the number of bars after * must be a whole number", "Write Am*2 to hold Am for two bars.");
            ticks = meter.barTicks() * std::stoi(n);
            word = word.substr(0, star);
        }
        auto chord = song_parse_chord(word);
        if (!chord) return make_error("chord progression: " + chord.error().message, chord.error().hint);
        out.push_back({*chord, ticks});
    }
    if (out.empty()) return make_error("the chord progression is empty", "Write chord names separated by spaces: \"Am F C G\".");
    if (out.size() > 256) return make_error("the chord progression has more than 256 chords", "Split it.");
    return out;
}

Result<std::string> song_roman_progression(std::string_view text, int keyRoot, std::string_view mode) {
    auto scale = song_scale_pitch_classes(((keyRoot % 12) + 12) % 12, mode);
    if (!scale) return make_error("unknown mode \"" + std::string(mode) + "\"", "Modes: major, minor, dorian, phrygian, lydian, mixolydian, locrian.");
    if (scale->size() != 7) return make_error("the mode \"" + std::string(mode) + "\" has " + std::to_string(scale->size()) + " notes, so Roman numerals do not apply", "Write the chords by name: \"Am F C G\".");
    const bool flats = song_prefers_flats(keyRoot, mode);
    std::string out;
    std::size_t i = 0;
    int count = 0;
    while (i < text.size()) {
        while (i < text.size() && (std::isspace(static_cast<unsigned char>(text[i])) || text[i] == '|' || text[i] == ',')) ++i;
        if (i >= text.size()) break;
        std::size_t j = i;
        while (j < text.size() && !std::isspace(static_cast<unsigned char>(text[j])) && text[j] != '|' && text[j] != ',') ++j;
        const std::string word(text.substr(i, j - i));
        i = j;
        std::string body = word, repeat;
        if (const std::size_t star = body.find('*'); star != std::string::npos) {
            repeat = body.substr(star);
            body.resize(star);
        }
        std::size_t p = 0;
        int shift = 0;
        if (p < body.size() && (body[p] == 'b' || body[p] == '#')) {
            shift = body[p] == 'b' ? -1 : 1;
            ++p;
        }
        const std::size_t numStart = p;
        while (p < body.size() && std::string_view("ivIV").find(body[p]) != std::string_view::npos) ++p;
        const std::string numeral = body.substr(numStart, p - numStart);
        static const char* const kNumerals[] = {"i", "ii", "iii", "iv", "v", "vi", "vii"};
        int degree = -1;
        std::string lower = numeral;
        for (char& ch : lower) ch = char(std::tolower(static_cast<unsigned char>(ch)));
        for (int d = 0; d < 7; ++d)
            if (lower == kNumerals[d]) degree = d;
        if (degree < 0)
            return make_error("`" + word + "` is not a Roman numeral chord", "Write I to VII (upper case major, lower case minor), e.g. \"i VI III VII\"; \"bVII\" lowers the degree, \"V7\" adds a seventh.");
        const bool minor = std::islower(static_cast<unsigned char>(numeral[0])) != 0;
        std::string suffix = body.substr(p);
        std::string quality = minor ? "m" : "";
        if (suffix.rfind("\xC2\xB0", 0) == 0) { suffix = "dim" + suffix.substr(2); quality = ""; }       // the degree sign
        else if (suffix.rfind("dim", 0) == 0) quality = "";
        else if (minor && suffix.rfind("maj", 0) == 0) quality = "m";                                      // "imaj7" is a minor-major seventh
        const int pc = (((*scale)[std::size_t(degree)] + shift) % 12 + 12) % 12;
        const std::string name = song_pitch_class_name(pc, flats || shift < 0) + quality + suffix;
        auto chord = song_parse_chord(name);
        if (!chord) return make_error("`" + word + "` (the chord " + name + "): " + chord.error().message, chord.error().hint);
        if (!out.empty()) out += ' ';
        out += name + repeat;
        ++count;
    }
    if (count == 0) return make_error("the chord progression is empty", "Write Roman numerals separated by spaces: \"i VI III VII\".");
    return out;
}

Result<std::string> song_chord_pad(const std::vector<SongChordStep>& progression, const SongMeter& meter, const SongPadOptions& o) {
    if (o.octave < 0 || o.octave > 7) return make_error("octave must be 0 to 7, got " + std::to_string(o.octave), "The root octave of the chords; 3 is a normal pad register.");
    if (o.velocity < 1 || o.velocity > 127) return make_error("velocity must be 1 to 127", "");
    TextWriter w{meter};
    w.lastVel = 90;
    for (const SongChordStep& step : progression) w.put("(" + step.chord.name + "@" + std::to_string(o.octave) + ")", step.ticks, o.velocity, false, false);
    return w.finish();
}

// ---- arpeggio -----------------------------------------------------------------------------------------------------------------

Result<std::string> song_arpeggio(const std::vector<SongChordStep>& progression, const SongMeter& meter, const SongArpeggioOptions& o) {
    static const std::vector<std::string> directions = {"up", "down", "updown", "downup", "random"};
    if (std::find(directions.begin(), directions.end(), o.direction) == directions.end())
        return make_error("unknown arpeggio direction \"" + o.direction + "\"", did_you_mean(o.direction, directions));
    if (o.octaves < 1 || o.octaves > 4) return make_error("octaves must be 1 to 4, got " + std::to_string(o.octaves), "How many octaves the arpeggio climbs before it turns.");
    if (o.rate != 4 && o.rate != 8 && o.rate != 16 && o.rate != 32) return make_error("rate must be 4, 8, 16 or 32, got " + std::to_string(o.rate), "The note value of each step: 16 is sixteenth notes.");
    if (o.velocity < 1 || o.velocity > 127) return make_error("velocity must be 1 to 127", "");
    std::int64_t stepTicks = 4 * kSongPpq / o.rate;
    if (o.triplet) stepTicks = stepTicks * 2 / 3;
    TextWriter w{meter};
    w.lastVel = 90;
    sfx_math::SfxRng rng{o.seed * 0x9E3779B97F4A7C15ull + 12345};
    for (std::size_t ci = 0; ci < progression.size(); ++ci) {
        const SongChordStep& step = progression[ci];
        if (step.ticks % stepTicks != 0)
            return make_error(std::format("the chord {} lasts {:g} beats, which is not a whole number of steps of the arpeggio", chord_token(step.chord), double(step.ticks) / double(meter.beatTicks())),
                              "Pick a rate that divides the chord's length (a 4/4 bar is 16 sixteenths, 8 eighths, 12 triplet eighths).");
        std::vector<int> base = song_chord_pitches(step.chord, o.octave);
        if (step.chord.bass >= 0 && base.size() > 1) base.erase(base.begin());  // the slash bass is not part of the arpeggio
        std::vector<int> pool;
        for (int oct = 0; oct < o.octaves; ++oct)
            for (int p : base)
                if (p + 12 * oct <= 127) pool.push_back(p + 12 * oct);
        if (pool.empty()) return make_error("the chord " + step.chord.name + " is out of range at octave " + std::to_string(o.octave), "Use a lower octave.");
        // The order of one pass.
        std::vector<int> order;
        const int n = int(pool.size());
        if (o.direction == "up") for (int k = 0; k < n; ++k) order.push_back(pool[k]);
        else if (o.direction == "down") for (int k = n - 1; k >= 0; --k) order.push_back(pool[k]);
        else if (o.direction == "updown") {
            for (int k = 0; k < n; ++k) order.push_back(pool[k]);
            for (int k = n - 2; k >= 1; --k) order.push_back(pool[k]);
        } else if (o.direction == "downup") {
            for (int k = n - 1; k >= 0; --k) order.push_back(pool[k]);
            for (int k = 1; k <= n - 2; ++k) order.push_back(pool[k]);
        }
        const std::int64_t count = step.ticks / stepTicks;
        const std::int64_t beat = meter.beatTicks();
        int prev = -1;
        for (std::int64_t k = 0; k < count; ++k) {
            int pitch;
            if (o.direction == "random") {
                int idx = int(rng.next() % std::uint64_t(n));
                if (n > 1 && idx == prev) idx = (idx + 1 + int(rng.next() % std::uint64_t(n - 1))) % n;
                prev = idx;
                pitch = pool[std::size_t(idx)];
            } else {
                pitch = order[std::size_t(k) % order.size()];
            }
            const bool onBeat = ((k * stepTicks) % beat) == 0;
            w.put(song_pitch_name(pitch), stepTicks, o.velocity, o.accent && onBeat, o.staccato);
        }
    }
    return w.finish();
}

// ---- bassline -----------------------------------------------------------------------------------------------------------------

const std::vector<std::pair<std::string, std::string>>& song_bass_styles() {
    static const std::vector<std::pair<std::string, std::string>> styles = {
        {"root", "the root of the chord on every beat: solid, simple"},
        {"root_fifth", "root and fifth alternating on the beats: country, pop, folk"},
        {"octave", "the root jumping an octave on the eighth notes: disco, dance"},
        {"walking", "one note per beat that walks root, third, fifth and a step into the next chord: jazz, blues, swing"},
    };
    return styles;
}

Result<std::string> song_bassline(const std::vector<SongChordStep>& progression, const SongMeter& meter, const SongBassOptions& o) {
    bool known = false;
    std::vector<std::string> names;
    for (const auto& s : song_bass_styles()) { names.push_back(s.first); known = known || s.first == o.style; }
    if (!known) return make_error("unknown bass style \"" + o.style + "\"", did_you_mean(o.style, names));
    if (o.octave < 0 || o.octave > 4) return make_error("octave must be 0 to 4, got " + std::to_string(o.octave), "The octave of C for the bass; 2 is a normal bass register.");
    if (o.rate != 0 && o.rate != 4 && o.rate != 8) return make_error("rate must be 4 or 8 (or 0 for the style's own)", "A quarter or an eighth note per step.");
    const int rate = o.rate ? o.rate : (o.style == "octave" ? 8 : 4);
    const std::int64_t stepTicks = 4 * kSongPpq / rate;
    TextWriter w{meter};
    w.lastVel = 90;
    for (std::size_t ci = 0; ci < progression.size(); ++ci) {
        const SongChordStep& step = progression[ci];
        const SongChord& chord = step.chord;
        if (step.ticks % stepTicks != 0)
            return make_error(std::format("the chord {} lasts {:g} beats, which is not a whole number of bass notes", chord.name, double(step.ticks) / double(meter.beatTicks())), "Use rate 4 for chords that last whole beats.");
        const int root = root_midi(chord.bass >= 0 ? chord.bass : chord.root, o.octave);
        const SongChord& nextChord = progression[(ci + 1) % progression.size()].chord;
        const int nextRoot = root_midi(nextChord.bass >= 0 ? nextChord.bass : nextChord.root, o.octave);
        const int third = root_midi(chord.root, o.octave) + (chord.intervals.size() > 1 ? chord.intervals[1] : 4);
        const int fifth = root_midi(chord.root, o.octave) + (chord.intervals.size() > 2 ? chord.intervals[2] : 7);
        const std::int64_t count = step.ticks / stepTicks;
        for (std::int64_t k = 0; k < count; ++k) {
            int pitch = root;
            if (o.style == "root_fifth") pitch = (k % 2 == 0) ? root : root + 7;
            else if (o.style == "octave") pitch = (k % 2 == 0) ? root : root + 12;
            else if (o.style == "walking") {
                const std::int64_t last = count - 1;
                if (k == 0) pitch = root;
                else if (k == last && count > 1) pitch = nextRoot > root ? nextRoot - 1 : nextRoot + 1;
                else {
                    static const int shape[] = {0, 1, 2, 1, 2, 1, 2, 3};  // root, third, fifth, ...
                    const int s = shape[std::min<std::int64_t>(k, 7)];
                    pitch = s == 0 ? root : s == 1 ? third : s == 2 ? fifth : fifth + 2;
                }
                if (nextRoot == root && k == last && count > 1) pitch = root - 1;
            }
            // Keep the bass low: fold anything above the register down an octave.
            while (pitch > root + 14) pitch -= 12;
            const bool accent = (k * stepTicks) % meter.barTicks() == 0;
            w.put(song_pitch_name(std::clamp(pitch, 0, 127)), stepTicks, o.velocity, accent, false);
        }
    }
    return w.finish();
}

// ---- drum styles -------------------------------------------------------------------------------------------------------------

namespace {

struct StyleDef {
    SongDrumStyle info;
    std::vector<std::pair<const char*, const char*>> lanes;  // lane -> one bar of steps
    const char* step = "16";
};

const std::vector<StyleDef>& style_defs() {
    static const std::vector<StyleDef> defs = {
        {{"rock", "straight rock: kick on 1 and 3 (plus a push), snare on 2 and 4, eighth-note hats", "4/4", 90, 140},
         {{"kick", "x.......x.x....."}, {"snare", "....x.......x..."}, {"hat", "x.x.x.x.x.x.x.x."}}},
        {{"four_on_floor", "house and techno: a kick on every beat, claps on 2 and 4, open hats on the off-beats", "4/4", 118, 150},
         {{"kick", "x...x...x...x..."}, {"clap", "....x.......x..."}, {"hat", "xoxoxoxoxoxoxoxo"}, {"openhat", "..x...x...x...x."}}},
        {{"disco", "disco: four on the floor, snare on 2 and 4, sixteenth hats, open hat on the off-beats", "4/4", 105, 130},
         {{"kick", "x...x...x...x..."}, {"snare", "....x.......x..."}, {"hat", "xoxoxoxoxoxoxoxo"}, {"openhat", "..x...x...x...x."}}},
        {{"hiphop", "boom bap: a lazy kick, snare on 2 and 4, eighth hats; play it with swing 0.2 to 0.4", "4/4", 75, 100},
         {{"kick", "x.....x...x....."}, {"snare", "....x.......x..."}, {"hat", "x.x.x.x.x.x.x.x."}}},
        {{"trap", "trap: half-time snare on 3, sparse kicks, hats that roll", "4/4", 130, 160},
         {{"kick", "x.....x.....x..."}, {"snare", "........x......."}, {"hat", "x.x.x.x.x.xxx.xx"}}},
        {{"dnb", "drum and bass: a broken kick, snare on 2 and 4, fast hats", "4/4", 160, 180},
         {{"kick", "x.........x....."}, {"snare", "....x.......x..."}, {"hat", "x.x.x.x.x.x.x.x."}}},
        {{"breakbeat", "breakbeat: a syncopated kick and a snare that pushes into 4", "4/4", 120, 140},
         {{"kick", "x.....x.x......."}, {"snare", "....x.......x..x"}, {"hat", "x.x.x.x.x.x.x.x."}}},
        {{"funk", "funk: syncopated kick, snare on 2 and 4 with ghost notes, sixteenth hats", "4/4", 95, 115},
         {{"kick", "x..x..x...x..x.."}, {"snare", "....X..o.o..X..o"}, {"hat", "XoxoXoxoXoxoXoxo"}}},
        {{"metal", "metal: double kick, snare on 2 and 4, a crash on 1", "4/4", 140, 200},
         {{"kick", "xxxxxxxxxxxxxxxx"}, {"snare", "....x.......x..."}, {"crash", "x..............."}, {"hat", "x.x.x.x.x.x.x.x."}}},
        {{"ballad", "ballad: a slow kick, a side stick on 3, soft hats", "4/4", 60, 85},
         {{"kick", "x.........x....."}, {"rim", "........x......."}, {"hat", "o.o.o.o.o.o.o.o."}}},
        {{"reggae", "reggae one drop: the kick and rim fall together on 3, hats on every off-beat", "4/4", 65, 90},
         {{"kick", "........x......."}, {"rim", "........x......."}, {"hat", "..x...x...x...x."}, {"shaker", "x.x.x.x.x.x.x.x."}}},
        {{"march", "march: a snare roll on every eighth, kick on 1 and 3", "4/4", 100, 125},
         {{"kick", "x.......x......."}, {"snare", "x.xxx.x.x.xxx.x."}}},
        {{"shuffle", "shuffle or blues: triplet feel, snare on 2 and 4, hats on the first and third triplet notes", "4/4", 70, 130},
         {{"kick", "x.....x....."}, {"snare", "...x.....x.."}, {"hat", "x.xx.xx.xx.x"}}, "8t"},
        {{"waltz", "waltz: kick on 1, snare on 2 and 3, hats on every beat", "3/4", 90, 180},
         {{"kick", "x..........."}, {"snare", "....x...x..."}, {"hat", "x...x...x..."}}},
    };
    return defs;
}

}  // namespace

const std::vector<SongDrumStyle>& song_drum_styles() {
    static const std::vector<SongDrumStyle> styles = [] {
        std::vector<SongDrumStyle> v;
        for (const StyleDef& d : style_defs()) v.push_back(d.info);
        return v;
    }();
    return styles;
}

Result<Json> song_drum_pattern(std::string_view style, const SongMeter& meter, int bars, bool fill) {
    if (bars < 1 || bars > 64) return make_error("bars must be 1 to 64, got " + std::to_string(bars), "How many bars the pattern lasts.");
    const StyleDef* def = nullptr;
    std::vector<std::string> names;
    for (const StyleDef& d : style_defs()) {
        names.push_back(d.info.name);
        if (d.info.name == style) def = &d;
    }
    if (!def) return make_error("unknown drum style \"" + std::string(style) + "\"", did_you_mean(style, names));
    if (def->info.meter != std::format("{}/{}", meter.beats, meter.unit))
        return make_error(std::format("the style {} is written for {}, but the song is in {}/{}", def->info.name, def->info.meter, meter.beats, meter.unit),
                          "Pick a style for this meter (waltz is 3/4) or write the grid by hand: {\"grid\": {\"kick\": \"...\"}}.");
    Json grid = Json::object();
    const std::size_t barSteps = std::string(def->lanes.front().second).size();
    for (const auto& [lane, steps] : def->lanes) {
        std::string s;
        for (int b = 0; b < bars; ++b) s += steps;
        grid[lane] = s;
    }
    if (fill) {
        // The last beat of the last bar: the kick and hats drop out, the snare and toms play a run into the next bar.
        const std::size_t perBeat = barSteps / std::size_t(meter.beats);
        const std::size_t from = (std::size_t(bars) - 1) * barSteps + barSteps - perBeat;
        // Create every lane first: adding a key can move the strings already in the object.
        for (const char* name : {"snare", "tom_high", "tom_mid", "tom_low"})
            if (!grid.contains(name)) grid[name] = std::string(std::size_t(bars) * barSteps, '.');
        auto lane = [&](const char* name) -> std::string& { return grid[name].get_ref<std::string&>(); };
        for (auto& kv : grid.items()) {
            std::string& s = kv.value().get_ref<std::string&>();
            if (kv.key() == "kick" || kv.key() == "hat" || kv.key() == "openhat" || kv.key() == "shaker")
                for (std::size_t i = from; i < s.size(); ++i) s[i] = '.';
        }
        std::string& snare = lane("snare");
        std::string& hi = lane("tom_high");
        std::string& mid = lane("tom_mid");
        std::string& low = lane("tom_low");
        for (std::size_t i = from; i < snare.size(); ++i) snare[i] = '.';
        const std::size_t n = snare.size() - from;
        for (std::size_t i = 0; i < n; ++i) {
            if (i * 4 < n) snare[from + i] = 'x';          // first quarter of the beat
            else if (i * 2 < n) hi[from + i] = 'x';        // second
            else if (i * 4 < n * 3) mid[from + i] = 'x';   // third
            else low[from + i] = 'X';                  // last
        }
    }
    Json out = Json::object();
    out["grid"] = grid;
    if (std::string(def->step) != "16") out["step"] = def->step;
    return out;
}

}  // namespace fa
