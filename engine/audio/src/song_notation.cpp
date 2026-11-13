// The note text and the drum grid of song patterns (fa/audio/song.h, docs/MUSIC.md "Writing notes"). Every problem is reported with the
// line and column of the token inside the text, what is wrong and how to write it.
#include <algorithm>
#include <cctype>
#include <format>

#include "fa/audio/song.h"
#include "fa/audio/song_theory.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

constexpr int kDefaultOctave = 3;  // the root octave of a chord written by name
constexpr int kAccentBoost = 22;
constexpr std::int64_t kMaxPatternBars = 256;

struct Token {
    std::string text;
    int line = 1;
    int column = 1;
};

bool is_digit(char c) { return c >= '0' && c <= '9'; }

std::string tokens_hint() {
    return "Notes are C4 F#3 Bb2 (letter, # or b, octave), r is a rest, [C4 E4 G4] a chord of notes, (Am7) a chord by "
           "name, | a bar line, "
           "{ ... }x2 repeats, & starts another voice; after a note: :8 a duration, ! an accent, ' staccato, ~ a tie, "
           "v100 a velocity.";
}

struct Parser {
    std::string pointer;
    SongMeter meter;
    SongPattern* out = nullptr;
    std::vector<SongIssue>* issues = nullptr;
    std::vector<Token> toks;
    std::vector<int> match;  // for a "{": index of its "}"
    bool failed = false;

    // sticky state
    std::int64_t tick = 0;
    std::int64_t dur = kSongPpq;
    int velocity = 90;
    std::vector<std::int64_t> voiceEnds;
    // tie
    bool tiePending = false;
    std::size_t tieEvent = 0;
    Token tieTok;

    void add(int line, int column, std::string message, std::string hint) {
        failed = true;
        issues->push_back({pointer, std::move(message), std::move(hint), line, column});
    }
    void at(const Token& t, int offset, std::string message, std::string hint) {
        add(t.line, t.column + offset, std::move(message), std::move(hint));
    }

    // ---- tokenizer ---------------------------------------------------------------------------------------------------
    void tokenize(std::string_view text) {
        int line = 1, col = 1;
        std::size_t i = 0;
        auto advance = [&](char c) {
            if (c == '\n') {
                ++line;
                col = 1;
            } else
                ++col;
        };
        while (i < text.size()) {
            const char c = text[i];
            if (std::isspace(static_cast<unsigned char>(c))) {
                advance(c);
                ++i;
                continue;
            }
            Token t;
            t.line = line;
            t.column = col;
            auto take = [&]() {
                t.text += text[i];
                advance(text[i]);
                ++i;
            };
            if (c == '|' || c == '{' || c == '&') {
                take();
            } else {
                if (c == '}') take();
                while (i < text.size()) {
                    const char d = text[i];
                    if (std::isspace(static_cast<unsigned char>(d)) || d == '|' || d == '{' || d == '}' || d == '&')
                        break;
                    if (d == '[' || d == '(') {
                        const char close = d == '[' ? ']' : ')';
                        take();
                        while (i < text.size() && text[i] != close && text[i] != '\n') take();
                        if (i >= text.size() || text[i] != close) {
                            add(t.line, t.column, std::string("`") + d + "` is never closed",
                                std::string("Close it with `") + close +
                                    "` on the same line: " + (d == '[' ? "[C4 E4 G4]:2." : "(Am7):2."));
                            return;
                        }
                        take();
                        continue;
                    }
                    take();
                }
            }
            toks.push_back(std::move(t));
        }
    }

    bool match_braces() {
        match.assign(toks.size(), -1);
        std::vector<int> stack;
        for (std::size_t i = 0; i < toks.size(); ++i) {
            if (toks[i].text == "{")
                stack.push_back(int(i));
            else if (toks[i].text[0] == '}') {
                if (stack.empty()) {
                    at(toks[i], 0, "`}` closes a group that was never opened",
                       "A repeated group is `{ C4 E4 }x2`; add the `{` or remove the `}`.");
                    return false;
                }
                match[stack.back()] = int(i);
                stack.pop_back();
            }
        }
        if (!stack.empty()) {
            at(toks[stack.back()], 0, "this `{` is never closed",
               "Close the group and say how many times it plays: `{ C4 E4 }x2`.");
            return false;
        }
        return true;
    }

    // ---- suffix: :duration and the marks ------------------------------------------------------------------------------
    struct Marks {
        std::optional<std::int64_t> duration;
        std::optional<int> velocity;
        bool accent = false, staccato = false, tie = false;
    };

    bool parse_suffix(const Token& t, std::size_t from, Marks& m) {
        const std::string& s = t.text;
        std::size_t i = from;
        if (i < s.size() && s[i] == ':') {
            const std::size_t start = i++;
            int den = 0;
            std::size_t digits = 0;
            while (i < s.size() && is_digit(s[i]) && digits < 3) {
                den = den * 10 + (s[i] - '0');
                ++i;
                ++digits;
            }
            if (digits == 0 || (den != 1 && den != 2 && den != 4 && den != 8 && den != 16 && den != 32 && den != 64)) {
                at(t, int(start), "`" + s.substr(start, std::max<std::size_t>(2, i - start)) + "` is not a duration",
                   "A duration is the note value after a colon: :1 whole, :2 half, :4 quarter, :8 eighth, :16 "
                   "sixteenth, :32, :64; add . to dot it (:4.) or t for a triplet (:8t).");
                return false;
            }
            std::int64_t ticks = std::int64_t(4 * kSongPpq / den);
            if (i < s.size() && s[i] == '.') {
                int dots = 0;
                while (i < s.size() && s[i] == '.' && dots < 2) {
                    ++dots;
                    ++i;
                }
                ticks = dots == 1 ? ticks * 3 / 2 : ticks * 7 / 4;
            } else if (i < s.size() && s[i] == 't') {
                ticks = ticks * 2 / 3;
                ++i;
            }
            m.duration = ticks;
        }
        while (i < s.size()) {
            const char c = s[i];
            if (c == '!') {
                m.accent = true;
                ++i;
            } else if (c == '\'') {
                m.staccato = true;
                ++i;
            } else if (c == '~') {
                m.tie = true;
                ++i;
            } else if (c == 'v') {
                const std::size_t start = i++;
                int v = 0;
                std::size_t digits = 0;
                while (i < s.size() && is_digit(s[i]) && digits < 4) {
                    v = v * 10 + (s[i] - '0');
                    ++i;
                    ++digits;
                }
                if (digits == 0 || v < 1 || v > 127) {
                    at(t, int(start),
                       "`" + s.substr(start, std::max<std::size_t>(1, i - start)) + "` is not a velocity",
                       "Write v and a number from 1 to 127: v90 is medium, v110 loud, v50 soft.");
                    return false;
                }
                m.velocity = v;
            } else {
                at(t, int(i), std::string("unexpected `") + c + "` in `" + s + "`",
                   "After the pitch come an optional :duration and marks: ! accent, ' staccato, ~ tie, v100 "
                   "velocity. " +
                       tokens_hint());
                return false;
            }
        }
        return true;
    }

    // ---- pitches -----------------------------------------------------------------------------------------------------
    // Reads "C4", "F#3", "Bb-1" from the front of s[from..]; `used` is the length. Nothing when it is not a note with an octave.
    static std::optional<int> read_note(const std::string& s, std::size_t from, std::size_t& used) {
        std::size_t i = from;
        if (i >= s.size() || s[i] < 'A' || s[i] > 'G') return std::nullopt;
        ++i;
        if (i < s.size() && (s[i] == '#' || s[i] == 'b')) {
            const char acc = s[i];
            int n = 0;
            while (i < s.size() && s[i] == acc && n < 2) {
                ++i;
                ++n;
            }
        }
        if (i < s.size() && s[i] == '-') ++i;
        if (i >= s.size() || !is_digit(s[i])) return std::nullopt;
        ++i;
        auto midi = song_parse_pitch(std::string_view(s).substr(from, i - from));
        if (!midi) return std::nullopt;
        used = i - from;
        return midi;
    }

    bool pitched(const Token& t, std::vector<int>& pitches, std::string& chord, std::size_t& suffixAt) {
        const std::string& s = t.text;
        if (s[0] == '[') {
            const std::size_t close = s.find(']');
            std::size_t i = 1;
            while (i < close) {
                if (s[i] == ' ' || s[i] == ',' || s[i] == '\t') {
                    ++i;
                    continue;
                }
                std::size_t used = 0;
                auto p = read_note(s, i, used);
                if (!p) {
                    std::size_t end = i;
                    while (end < close && s[end] != ' ' && s[end] != ',') ++end;
                    at(t, int(i), "`" + s.substr(i, end - i) + "` inside the chord is not a note with an octave",
                       "Write each note as a letter, an optional # or b and an octave: [C4 E4 G4]. For a chord by name "
                       "use parentheses: (Am7).");
                    return false;
                }
                pitches.push_back(*p);
                i += used;
            }
            if (pitches.empty()) {
                at(t, 0, "an empty chord `[]`", "List the notes: [C4 E4 G4].");
                return false;
            }
            std::sort(pitches.begin(), pitches.end());
            pitches.erase(std::unique(pitches.begin(), pitches.end()), pitches.end());
            suffixAt = close + 1;
            return true;
        }
        if (s[0] == '(') {
            const std::size_t close = s.find(')');
            std::string inner = s.substr(1, close - 1);
            int octave = kDefaultOctave;
            const std::size_t atSign = inner.find('@');
            if (atSign != std::string::npos) {
                const std::string oct = inner.substr(atSign + 1);
                bool ok = !oct.empty() && oct.size() <= 2;
                for (char c : oct) ok = ok && (is_digit(c) || c == '-');
                if (!ok) {
                    at(t, int(1 + atSign), "`@" + oct + "` is not an octave",
                       "Put the root's octave after @: (Am7@2) puts the A at A2.");
                    return false;
                }
                octave = std::stoi(oct);
                inner = inner.substr(0, atSign);
            }
            auto chordParsed = song_parse_chord(inner);
            if (!chordParsed) {
                at(t, 1, chordParsed.error().message, chordParsed.error().hint);
                return false;
            }
            pitches = song_chord_pitches(*chordParsed, octave);
            if (pitches.empty()) {
                at(t, 1, "the chord `" + inner + "` at octave " + std::to_string(octave) + " is outside the MIDI range",
                   "Use an octave from 0 to 8: (" + inner + "@3).");
                return false;
            }
            chord = inner;
            suffixAt = close + 1;
            return true;
        }
        std::size_t used = 0;
        auto p = read_note(s, 0, used);
        if (!p) {
            const char c = s[0];
            if (c >= 'A' && c <= 'G') {
                at(t, 0, "`" + s + "` is not a note: a note needs an octave",
                   "Write the octave after the letter: C4, F#3, Bb2. A chord by name goes in parentheses: (Am7), "
                   "(Cmaj7/G).");
            } else {
                at(t, 0, "`" + s + "` is not a note, a rest or a mark", tokens_hint());
            }
            return false;
        }
        pitches.push_back(*p);
        suffixAt = used;
        return true;
    }

    // ---- one event ---------------------------------------------------------------------------------------------------
    // A pending tie that the next thing is not the same pitch is an error.
    void break_tie() {
        if (!tiePending) return;
        tiePending = false;
        const SongEvent& e = out->events[tieEvent];
        const std::string what = e.pitches.empty() ? "C4" : song_pitch_name(e.pitches.front());
        at(tieTok, 0, "the tie `~` on `" + tieTok.text + "` has nothing to tie to",
           "A tie joins a note to the SAME pitch right after it: `" + what + ":2~ " + what +
               ":4`. Remove the `~` or write the same pitch next.");
    }

    void bar_line(const Token& t) {
        const std::int64_t bar = meter.barTicks();
        if (tick % bar != 0) {
            const double into = double(tick % bar) / double(meter.beatTicks());
            const double missing = double(bar - tick % bar) / double(meter.beatTicks());
            at(t, 0,
               std::format("the bar line comes {:g} beat(s) into a bar, but a {}/{} bar has {} beats", into,
                           meter.beats, meter.unit, meter.beats),
               std::format("Add {:g} beat(s) of rest or lengthen a note before it, or move the `|`.", missing));
        }
    }

    void one(const Token& t) {
        const std::string& s = t.text;
        if (s == "|") {
            bar_line(t);
            return;
        }
        if (s[0] == 'v' && s.size() > 1 && std::all_of(s.begin() + 1, s.end(), is_digit)) {
            const int v = s.size() <= 4 ? std::stoi(s.substr(1)) : 9999;
            if (v < 1 || v > 127) {
                at(t, 0, "`" + s + "` is not a velocity",
                   "Write v and a number from 1 to 127: v90 is medium, v110 loud, v50 soft. It applies to the notes "
                   "after it.");
                return;
            }
            velocity = v;
            return;
        }
        std::vector<int> pitches;
        std::string chord;
        std::size_t suffixAt = 1;
        const bool isRest =
            s[0] == 'r' && (s.size() == 1 || s[1] == ':' || s[1] == '!' || s[1] == '\'' || s[1] == '~' || s[1] == 'v');
        if (!isRest && !pitched(t, pitches, chord, suffixAt)) return;
        Marks m;
        if (!parse_suffix(t, suffixAt, m)) return;
        if (m.duration) dur = *m.duration;
        if (isRest) {
            break_tie();
            tick += dur;
            return;
        }
        const int vel = std::min(127, (m.velocity ? *m.velocity : velocity) + (m.accent ? kAccentBoost : 0));
        if (tiePending && out->events[tieEvent].pitches == pitches) {
            out->events[tieEvent].duration += dur;
            tiePending = false;
            tick += dur;
            if (m.tie) {
                tiePending = true;
                tieTok = t;
            }
            return;
        }
        break_tie();
        if (failed) return;
        SongEvent e;
        e.tick = tick;
        e.duration = dur;
        e.pitches = std::move(pitches);
        e.velocity = std::max(1, vel);
        e.accent = m.accent;
        e.gate = m.staccato ? 0.5 : 1.0;
        e.chord = chord;
        e.source = {pointer, t.line, t.column, int(t.text.size()), t.text};
        out->events.push_back(std::move(e));
        tick += dur;
        if (m.tie) {
            tiePending = true;
            tieEvent = out->events.size() - 1;
            tieTok = t;
        }
    }

    void run(std::size_t begin, std::size_t end) {
        for (std::size_t i = begin; i < end && !failed; ++i) {
            const Token& t = toks[i];
            if (t.text == "{") {
                const std::size_t close = std::size_t(match[i]);
                const Token& ct = toks[close];
                int count = 0;
                const std::string tail = ct.text.substr(1);
                const bool ok = tail.size() >= 2 && tail.size() <= 4 && (tail[0] == 'x' || tail[0] == '*') &&
                                std::all_of(tail.begin() + 1, tail.end(), is_digit);
                if (ok) count = std::stoi(tail.substr(1));
                if (!ok || count < 1 || count > 256) {
                    at(ct, 0, "a repeated group needs a count after the closing brace: `" + ct.text + "` is not one",
                       "Write `{ C4 E4 }x2` to play the group twice (1 to 256).");
                    return;
                }
                for (int r = 0; r < count && !failed; ++r) run(i + 1, close);
                i = close;
                continue;
            }
            if (t.text[0] == '}') continue;  // consumed with its group
            if (t.text == "&") {
                break_tie();
                voiceEnds.push_back(tick);
                tick = 0;
                dur = kSongPpq;
                continue;
            }
            one(t);
        }
    }
};

}  // namespace

bool song_parse_note_text(std::string_view text, const std::string& pointer, const SongMeter& meter, int declaredBars,
                          SongPattern& out, std::vector<SongIssue>& issues) {
    Parser p;
    p.pointer = pointer;
    p.meter = meter;
    p.out = &out;
    p.issues = &issues;
    out.text = std::string(text);
    out.events.clear();
    p.tokenize(text);
    if (p.failed) return false;
    if (p.toks.empty()) {
        issues.push_back({pointer, "the pattern is empty",
                          "Write notes and rests, e.g. \"C4:4 E4 G4 r\" (a bar of 4/4), or remove the pattern.", 1, 1});
        return false;
    }
    if (!p.match_braces()) return false;
    p.run(0, p.toks.size());
    if (p.failed) return false;
    const Token endTok = p.toks.back();
    p.break_tie();
    if (p.failed) return false;
    p.voiceEnds.push_back(p.tick);
    for (std::size_t v = 1; v < p.voiceEnds.size(); ++v)
        if (p.voiceEnds[v] != p.voiceEnds[0]) {
            issues.push_back({pointer,
                              std::format("voice {} is {:g} beats long but voice 1 is {:g}", v + 1,
                                          double(p.voiceEnds[v]) / double(meter.beatTicks()),
                                          double(p.voiceEnds[0]) / double(meter.beatTicks())),
                              "Voices separated by & must be the same length: pad the shorter one with a rest (r).",
                              endTok.line, endTok.column});
            return false;
        }
    const std::int64_t length = p.voiceEnds[0];
    const std::int64_t bar = meter.barTicks();
    if (length <= 0) {
        issues.push_back({pointer, "the pattern has no length", "Give it at least one rest or note.", 1, 1});
        return false;
    }
    std::int64_t bars = (length + bar - 1) / bar;
    if (declaredBars > 0) {
        if (length > std::int64_t(declaredBars) * bar) {
            issues.push_back({pointer,
                              std::format("the pattern is {:g} beats long, longer than the {} bar(s) of \"bars\"",
                                          double(length) / double(meter.beatTicks()), declaredBars),
                              "Raise \"bars\" or shorten the notes.", endTok.line, endTok.column});
            return false;
        }
        bars = declaredBars;
    } else if (length % bar != 0) {
        const double have = double(length) / double(meter.beatTicks());
        const double missing = double(bar - length % bar) / double(meter.beatTicks());
        issues.push_back(
            {pointer,
             std::format("the pattern is {:g} beats long, not a whole number of {}/{} bars ({} beats each)", have,
                         meter.beats, meter.unit, meter.beats),
             std::format("Add {:g} beat(s) of rest at the end (r), or give the pattern as {{\"notes\": \"...\", "
                         "\"bars\": N}} to pad it with silence.",
                         missing),
             endTok.line, endTok.column});
        return false;
    }
    if (bars > kMaxPatternBars) {
        issues.push_back({pointer, std::format("the pattern is {} bars long", bars),
                          "A pattern is at most 256 bars; split it into patterns and arrange them in the sections.", 1,
                          1});
        return false;
    }
    out.bars = int(bars);
    out.lengthTicks = bars * bar;
    std::stable_sort(out.events.begin(), out.events.end(),
                     [](const SongEvent& a, const SongEvent& b) { return a.tick < b.tick; });
    return true;
}

const std::vector<SongDrumLane>& song_drum_lanes() {
    static const std::vector<SongDrumLane> lanes = {
        {"kick", "bass drum"},         {"snare", "snare drum"},
        {"clap", "hand clap"},         {"rim", "rim shot / side stick"},
        {"hat", "closed hi-hat"},      {"openhat", "open hi-hat"},
        {"hat_pedal", "pedal hi-hat"}, {"shaker", "shaker"},
        {"tambourine", "tambourine"},  {"tom_low", "low tom"},
        {"tom_mid", "mid tom"},        {"tom_high", "high tom"},
        {"ride", "ride cymbal"},       {"crash", "crash cymbal"},
        {"cowbell", "cowbell"},
    };
    return lanes;
}

bool song_parse_drum_grid(const Json& pattern, const std::string& pointer, const SongMeter& meter,
                          const std::map<std::string, std::string>& kit, SongPattern& out,
                          std::vector<SongIssue>& issues) {
    bool ok = true;
    auto err = [&](const std::string& ptr, std::string message, std::string hint, int column = 0) {
        ok = false;
        issues.push_back({ptr, std::move(message), std::move(hint), column > 0 ? 1 : 0, column});
    };
    const std::string example =
        "{\"grid\": {\"kick\": \"x...x...x...x...\", \"snare\": \"....x.......x...\", \"hat\": \"x.x.x.x.x.x.x.x.\"}}";
    if (!pattern.is_object()) {
        err(pointer, "a drum pattern must be an object, got " + describe_json_value(pattern), "Write " + example + ".");
        return false;
    }
    for (auto it = pattern.begin(); it != pattern.end(); ++it) {
        const std::string& key = it.key();
        if (key != "grid" && key != "step" && key != "bars")
            err(pointer + "/" + key, "unknown key `" + key + "` in a drum pattern",
                did_you_mean(key, std::vector<std::string>{"grid", "step", "bars"}));
    }
    out.grid = pattern;
    out.events.clear();
    std::int64_t stepTicks = kSongPpq / 4;
    if (auto s = pattern.find("step"); s != pattern.end()) {
        std::string v = s->is_string() ? s->get<std::string>() : std::string();
        if (v == "8")
            stepTicks = kSongPpq / 2;
        else if (v == "16")
            stepTicks = kSongPpq / 4;
        else if (v == "32")
            stepTicks = kSongPpq / 8;
        else if (v == "8t")
            stepTicks = kSongPpq / 3;
        else if (v == "16t")
            stepTicks = kSongPpq / 6;
        else
            err(pointer + "/step",
                "`step` is " + describe_json_value(*s) + ", not one of \"8\", \"16\", \"32\", \"8t\", \"16t\"",
                "The length of one character of the grid: \"16\" (the default) is a sixteenth note, \"8t\" an "
                "eighth-note triplet.");
    }
    int declaredBars = 0;
    if (auto b = pattern.find("bars"); b != pattern.end()) {
        if (!b->is_number_integer() || b->get<int>() < 1 || b->get<int>() > int(kMaxPatternBars))
            err(pointer + "/bars", "`bars` must be a whole number from 1 to 256, got " + describe_json_value(*b),
                "Write the length of the pattern in bars, e.g. 2.");
        else
            declaredBars = b->get<int>();
    }
    auto g = pattern.find("grid");
    if (g == pattern.end() || !g->is_object() || g->empty()) {
        err(pointer + "/grid",
            g == pattern.end()
                ? "a drum pattern needs a `grid`"
                : "`grid` must be an object with one string per drum lane, got " + describe_json_value(*g),
            "Write " + example + ". x is a hit, X an accent, o a soft ghost note, . a rest.");
        return false;
    }
    std::vector<std::string> laneNames;
    for (const SongDrumLane& l : song_drum_lanes()) laneNames.push_back(l.name);
    for (const auto& entry : kit)
        if (std::find(laneNames.begin(), laneNames.end(), entry.first) == laneNames.end())
            laneNames.push_back(entry.first);
    std::int64_t steps = -1;
    for (auto it = g->begin(); it != g->end(); ++it) {
        const std::string lane = it.key();
        const std::string lanePointer = pointer + "/grid/" + lane;
        if (std::find(laneNames.begin(), laneNames.end(), lane) == laneNames.end()) {
            std::string all;
            for (const std::string& n : laneNames) all += (all.empty() ? "" : ", ") + n;
            err(lanePointer, "unknown drum lane `" + lane + "`",
                did_you_mean(lane, laneNames) + " Lanes: " + all + ".");
            continue;
        }
        if (!it->is_string()) {
            err(lanePointer, "a lane must be a string of steps, got " + describe_json_value(*it),
                "Write e.g. \"x...x...x...x...\" (16 steps = one bar of 4/4).");
            continue;
        }
        const std::string text = it->get<std::string>();
        std::int64_t count = 0;
        for (std::size_t i = 0; i < text.size(); ++i) {
            const char c = text[i];
            if (c == ' ' || c == '|') continue;
            int vel = 0;
            bool accent = false;
            if (c == 'x')
                vel = 100;
            else if (c == 'X') {
                vel = 124;
                accent = true;
            } else if (c == 'o')
                vel = 52;
            else if (c == '.' || c == '-' || c == '_')
                vel = 0;
            else {
                err(lanePointer, std::format("`{}` at column {} is not a step", c, i + 1),
                    "Steps are x (hit), X (accent), o (soft ghost note) and . (rest); spaces and | are ignored: \"x... "
                    "x... x... x...\".",
                    int(i + 1));
                break;
            }
            if (vel > 0) {
                SongEvent e;
                e.tick = count * stepTicks;
                e.duration = stepTicks;
                e.drum = lane;
                e.velocity = vel;
                e.accent = accent;
                e.source = {lanePointer, 1, int(i + 1), 1, lane + " step " + std::to_string(count + 1)};
                out.events.push_back(std::move(e));
            }
            ++count;
        }
        if (steps < 0)
            steps = count;
        else if (count != steps)
            err(lanePointer, std::format("lane `{}` has {} steps but the lanes before it have {}", lane, count, steps),
                "Every lane of a grid has the same number of steps (spaces and | do not count); pad with . to make "
                "them equal.");
    }
    if (!ok) return false;
    if (steps <= 0) {
        err(pointer + "/grid", "the grid has no steps", "Give each lane a string such as \"x...x...x...x...\".");
        return false;
    }
    const std::int64_t length = steps * stepTicks;
    const std::int64_t bar = meter.barTicks();
    std::int64_t bars = (length + bar - 1) / bar;
    if (declaredBars > 0) {
        if (length > std::int64_t(declaredBars) * bar) {
            err(pointer + "/bars", std::format("the grid has {} steps, more than {} bar(s) hold", steps, declaredBars),
                "Raise `bars` or shorten the lanes.");
            return false;
        }
        bars = declaredBars;
    } else if (length % bar != 0) {
        const std::int64_t perBar = std::max<std::int64_t>(1, bar / stepTicks);
        err(pointer + "/grid",
            std::format("the grid has {} steps, which is not a whole number of {}/{} bars", steps, meter.beats,
                        meter.unit),
            std::format("One bar is {} steps at this step size; make the lanes {} or {} steps long, or set `bars`.",
                        perBar, (length / bar) * perBar, (length / bar + 1) * perBar));
        return false;
    }
    std::stable_sort(out.events.begin(), out.events.end(),
                     [](const SongEvent& a, const SongEvent& b) { return a.tick < b.tick; });
    out.bars = int(bars);
    out.lengthTicks = bars * bar;
    return true;
}

}  // namespace fa
