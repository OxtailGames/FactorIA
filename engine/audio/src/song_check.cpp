// The music checks (fa/audio/song_check.h).
#include "fa/audio/song_check.h"

#include <algorithm>
#include <format>
#include <map>
#include <set>

#include "fa/audio/song_instruments.h"
#include "fa/audio/song_preview.h"
#include "fa/audio/song_theory.h"
#include "fa/core/strings.h"
#include "sfx_math.h"

namespace fa {

const std::vector<SongCheckRule>& song_check_rules() {
    static const std::vector<SongCheckRule> rules = {
        {"off_key", "warning", false,
         "a note whose pitch class is not in the song's key and mode (short off-beat notes of an eighth or less count "
         "as passing tones and are skipped)"},
        {"range", "warning", false,
         "a note outside the range of its instrument (the track's `range`, or the built-in instrument's own)"},
        {"clash", "warning", false,
         "a minor second (or minor ninth) or a tritone sounding together on a strong beat between different tracks or "
         "voices (notes of one chord written by name are skipped)"},
        {"mud", "warning", false,
         "two notes sounding together below C3 closer than a minor third plus one semitone (up to 3 semitones apart): "
         "the low register turns to mud"},
        {"structure", "warning", false,
         "a track that never plays, a section with no notes, a pattern no section uses (info)"},
        {"loudness", "warning", true,
         "needs a render through the mixer: a peak above -1 dBFS or a clip with the master limiter off, a limiter "
         "pulling the level down by more than 3 dB, an integrated loudness more than 3 LU from the target (the style "
         "guide's music bus, when there is one) or below -35 LUFS"},
    };
    return rules;
}

bool SongCheckReport::ok() const {
    for (const SongCheckIssue& i : issues)
        if (i.severity != "info") return false;
    return true;
}

namespace {

int pc_of(int midi) { return ((midi % 12) + 12) % 12; }

// Notes sounding at a tick, advanced in increasing tick order.
struct Sweep {
    const std::vector<SongNote>& notes;
    std::size_t next = 0;
    std::vector<const SongNote*> active;
    explicit Sweep(const std::vector<SongNote>& n) : notes(n) {}
    const std::vector<const SongNote*>& at(std::int64_t t) {
        while (next < notes.size() && notes[next].tick <= t) {
            if (notes[next].pitch >= 0) active.push_back(&notes[next]);
            ++next;
        }
        active.erase(std::remove_if(active.begin(), active.end(),
                                    [&](const SongNote* n) { return n->tick + n->gateTicks() <= t; }),
                     active.end());
        return active;
    }
};

struct Reporter {
    const SongDoc& song;
    const SongTimeline& timeline;
    std::vector<SongCheckIssue> out;
    std::map<std::string, std::size_t> index;  // dedupe key -> position in out

    std::string section_of(const SongNote& n) const {
        if (n.span >= 0 && n.span < int(timeline.spans.size()))
            return song.sections[std::size_t(timeline.spans[std::size_t(n.span)].section)].name;
        return {};
    }
    int bar_of(std::int64_t tick) const { return int(tick / song.meter.barTicks()) + 1; }

    // Adds an issue or counts one more of the same `key`.
    void add(const std::string& key, SongCheckIssue issue, const SongNote* at, std::int64_t tick) {
        auto it = index.find(key);
        if (it != index.end()) {
            ++out[it->second].count;
            return;
        }
        issue.bar = bar_of(tick);
        issue.position = timeline.position_text(song, tick);
        if (at) {
            issue.source = at->source;
            issue.section = section_of(*at);
            issue.pattern = at->pattern;
        }
        index[key] = out.size();
        out.push_back(std::move(issue));
    }
};

std::string note_name(const SongDoc& song, int pitch) {
    return song_pitch_name(pitch, song_prefers_flats(song.keyRoot, song.mode));
}

std::string scale_text(const SongDoc& song) {
    auto pcs = song_scale_pitch_classes(song.keyRoot, song.mode);
    std::string s;
    if (pcs)
        for (int pc : *pcs)
            s += (s.empty() ? "" : " ") + song_pitch_class_name(pc, song_prefers_flats(song.keyRoot, song.mode));
    return s;
}

void rule_off_key(Reporter& r) {
    const SongDoc& song = r.song;
    if (song.mode == "chromatic") return;
    const std::vector<int> scale = song.scale_pitch_classes();
    if (scale.empty()) return;
    std::set<int> in(scale.begin(), scale.end());
    for (const SongNote& n : r.timeline.notes) {
        if (n.pitch < 0) continue;
        const int pc = pc_of(n.pitch);
        if (in.count(pc)) continue;
        if (n.duration <= kSongPpq / 2 && n.tick % song.meter.strongTicks() != 0) continue;  // a passing tone
        const SongTrack& track = song.tracks[std::size_t(n.track)];
        // The nearest notes of the key, below and above.
        int below = pc, above = pc;
        while (!in.count(pc_of(below))) --below;
        while (!in.count(pc_of(above))) ++above;
        const bool flats = song_prefers_flats(song.keyRoot, song.mode);
        SongCheckIssue i;
        i.rule = "off_key";
        i.severity = "warning";
        i.track = track.name;
        i.message = std::format("track `{}` plays {} in pattern `{}`, which is not in {} {} ({})", track.name,
                                note_name(song, n.pitch), n.pattern, song.key, song.mode, scale_text(song));
        i.hint = std::format("Change it to {} or {} (the nearest notes of the key), or, if the chromatic note is on "
                             "purpose, change the song's key or mode so it fits, or play it short on an off-beat.",
                             song_pitch_class_name(pc_of(below), flats), song_pitch_class_name(pc_of(above), flats));
        r.add("off_key|" + track.name + "|" + n.pattern + "|" + std::to_string(pc), std::move(i), &n, n.tick);
    }
}

void rule_range(Reporter& r) {
    const SongDoc& song = r.song;
    for (const SongNote& n : r.timeline.notes) {
        if (n.pitch < 0) continue;
        const SongTrack& track = song.tracks[std::size_t(n.track)];
        int lo = track.rangeLow, hi = track.rangeHigh;
        if (lo < 0) {
            auto range = song_instrument_range(track.instrument);
            if (!range) continue;
            lo = range->first;
            hi = range->second;
        }
        if (n.pitch >= lo && n.pitch <= hi) continue;
        const bool low = n.pitch < lo;
        SongCheckIssue i;
        i.rule = "range";
        i.severity = "warning";
        i.track = track.name;
        i.message = std::format("track `{}` plays {} in pattern `{}`, {} the range of `{}` ({} to {})", track.name,
                                note_name(song, n.pitch), n.pattern, low ? "below" : "above", track.instrument,
                                note_name(song, lo), note_name(song, hi));
        i.hint = std::format("Move it {} an octave or more, use `transpose` on the track, or set the track's `range` "
                             "if the instrument really sounds good there.",
                             low ? "up" : "down");
        r.add("range|" + track.name + "|" + n.pattern + "|" + (low ? "low" : "high"), std::move(i), &n, n.tick);
    }
}

void rule_clash(Reporter& r) {
    const SongDoc& song = r.song;
    Sweep sweep(r.timeline.notes);
    const std::int64_t strong = song.meter.strongTicks();
    for (std::int64_t t = 0; t < r.timeline.totalTicks; t += strong) {
        const auto& act = sweep.at(t);
        for (std::size_t a = 0; a < act.size(); ++a)
            for (std::size_t b = a + 1; b < act.size(); ++b) {
                const SongNote* x = act[a];
                const SongNote* y = act[b];
                if (x->chordId >= 0 && x->chordId == y->chordId && x->track == y->track) continue;
                if (x->pitch > y->pitch) std::swap(x, y);
                const int d = y->pitch - x->pitch;
                const char* kind = nullptr;
                if (d == 1 || d == 13)
                    kind = d == 1 ? "minor second" : "minor ninth";
                else if (d % 12 == 6 && d <= 18)
                    kind = "tritone";
                if (!kind) continue;
                const SongTrack& tx = song.tracks[std::size_t(x->track)];
                const SongTrack& ty = song.tracks[std::size_t(y->track)];
                // Report the later-starting note as the one to move.
                const SongNote* later = x->tick >= y->tick ? x : y;
                SongCheckIssue i;
                i.rule = "clash";
                i.severity = "warning";
                i.track = song.tracks[std::size_t(later->track)].name;
                i.message = std::format("{} (track `{}`, pattern `{}`) and {} (track `{}`, pattern `{}`) sound "
                                        "together on a strong beat: a {}",
                                        note_name(song, x->pitch), tx.name, x->pattern, note_name(song, y->pitch),
                                        ty.name, y->pattern, kind);
                i.hint = std::string("Move one of them a step to a note that belongs to the chord, shorten it so it "
                                     "ends before the strong beat, or make it a passing tone on an off-beat.") +
                         (std::string(kind) == "tritone" ? " A tritone is fine inside a dominant 7th chord; write that "
                                                           "chord by name so its notes are skipped."
                                                         : "");
                r.add("clash|" + tx.name + "|" + ty.name + "|" + std::to_string(x->pitch) + "|" +
                          std::to_string(y->pitch),
                      std::move(i), later, t);
            }
    }
}

void rule_mud(Reporter& r) {
    const SongDoc& song = r.song;
    Sweep sweep(r.timeline.notes);
    std::int64_t last = -1;
    for (const SongNote& onset : r.timeline.notes) {
        if (onset.tick == last) continue;
        last = onset.tick;
        const auto& act = sweep.at(onset.tick);
        for (std::size_t a = 0; a < act.size(); ++a)
            for (std::size_t b = a + 1; b < act.size(); ++b) {
                const SongNote* x = act[a];
                const SongNote* y = act[b];
                if (x->pitch > y->pitch) std::swap(x, y);
                const int d = y->pitch - x->pitch;
                if (x->pitch >= 48 || d < 1 || d > 3) continue;
                if (x->tick != onset.tick && y->tick != onset.tick) continue;  // reported when it started
                const SongTrack& tx = song.tracks[std::size_t(x->track)];
                const SongTrack& ty = song.tracks[std::size_t(y->track)];
                SongCheckIssue i;
                i.rule = "mud";
                i.severity = "warning";
                i.track = ty.name;
                i.message = std::format(
                    "{} ({}) and {} ({}) sound together {} semitone(s) apart below C3: the low register turns to mud",
                    note_name(song, x->pitch), tx.name, note_name(song, y->pitch), ty.name, d);
                i.hint = "Move the upper note up an octave (or the lower one down), or drop one of them: low notes "
                         "need at least a fourth between them.";
                r.add("mud|" + tx.name + "|" + ty.name + "|" + std::to_string(x->pitch) + "|" +
                          std::to_string(y->pitch),
                      std::move(i), y->tick == onset.tick ? y : x, onset.tick);
            }
    }
}

void rule_structure(Reporter& r) {
    const SongDoc& song = r.song;
    std::vector<int> notesOfTrack(song.tracks.size(), 0);
    std::vector<int> notesOfSpan(r.timeline.spans.size(), 0);
    for (const SongNote& n : r.timeline.notes) {
        ++notesOfTrack[std::size_t(n.track)];
        if (n.span >= 0 && n.span < int(notesOfSpan.size())) ++notesOfSpan[std::size_t(n.span)];
    }
    auto simple = [&](std::string severity, std::string message, std::string hint, std::string track, std::string key) {
        SongCheckIssue i;
        i.rule = "structure";
        i.severity = std::move(severity);
        i.message = std::move(message);
        i.hint = std::move(hint);
        i.track = std::move(track);
        const std::size_t at = r.out.size();
        r.index[key] = at;
        r.out.push_back(std::move(i));
    };
    for (std::size_t t = 0; t < song.tracks.size(); ++t)
        if (notesOfTrack[t] == 0)
            simple("warning", "the track `" + song.tracks[t].name + "` never plays a note",
                   "List it in a section's `play` (not muted there) or delete it with music.edit remove_track.",
                   song.tracks[t].name, "structure|track|" + song.tracks[t].name);
    for (std::size_t s = 0; s < song.sections.size(); ++s) {
        int total = 0;
        for (std::size_t sp = 0; sp < r.timeline.spans.size(); ++sp)
            if (std::size_t(r.timeline.spans[sp].section) == s) total += notesOfSpan[sp];
        if (total == 0)
            simple("warning", "the section `" + song.sections[s].name + "` has no notes",
                   "Give it a `play` entry for at least one track, or unmute a track there.", "",
                   "structure|section|" + song.sections[s].name);
    }
    for (const SongTrack& t : song.tracks)
        for (const SongPattern& p : t.patterns) {
            bool used = false;
            for (const SongSection& s : song.sections)
                for (const SongSectionTrack& st : s.play)
                    if (st.track == t.name)
                        for (const SongPlayEntry& e : st.entries) used = used || e.pattern == p.name;
            if (!used)
                simple("info", "the pattern `" + p.name + "` of track `" + t.name + "` is not used in any section",
                       "Add it to a section's play list for that track, or remove it with music.edit remove_pattern.",
                       t.name, "structure|pattern|" + t.name + "|" + p.name);
        }
}

void rule_loudness(Reporter& r, const SongCheckOptions& o, SongCheckReport& report, Result<std::monostate>& status) {
    SongRenderOptions ro;
    ro.sampleRate = o.sampleRate;
    ro.tailSeconds = 0.5;
    ro.maxSeconds = 600.0;
    ro.targetLufs = o.targetLufs;
    auto rendered = render_song(r.song, r.timeline, ro);
    if (!rendered) {
        status = rendered.error();
        return;
    }
    report.rendered = true;
    report.lufs = rendered->clip.lufs;
    report.peakDb = rendered->clip.peakDb;
    auto add = [&](std::string severity, std::string message, std::string hint) {
        SongCheckIssue i;
        i.rule = "loudness";
        i.severity = std::move(severity);
        i.message = std::move(message);
        i.hint = std::move(hint);
        r.out.push_back(std::move(i));
    };
    const SongMasterStats& ms = rendered->master;
    report.limiterReductionDb = ms.limiterReductionDb;
    if (!ms.limiter && report.peakDb > 0.0)
        add("error", std::format("the mix clips: its peak is {:.1f} dBFS and the master limiter is off", report.peakDb),
            std::format("Turn the limiter on (mixer.master.limiter: true), or lower the song's `volume` by about "
                        "{:.0f} dB (multiply it by {:.2f}).",
                        report.peakDb + 1.0, sfx_math::db_to_gain(-(report.peakDb + 1.0))));
    else if (!ms.limiter && report.peakDb > -1.0)
        add("warning", std::format("the mix peaks at {:.1f} dBFS, which leaves no headroom", report.peakDb),
            "Lower the song's `volume` by 2 dB or more (0.8 -> 0.6), or turn the master limiter on.");
    if (ms.limiter && ms.limiterReductionDb > 6.0)
        add("warning",
            std::format("the master limiter pulls the level down by {:.1f} dB: the mix is far too hot and its dynamics "
                        "are squashed",
                        ms.limiterReductionDb),
            "Lower the loud tracks' `volume` (or the song's), thin out what plays together, or lower the master's "
            "loudness target so peaks stay under the ceiling.");
    else if (ms.limiter && ms.limiterReductionDb > 3.0)
        add("info",
            std::format("the master limiter pulls the level down by {:.1f} dB at its deepest", ms.limiterReductionDb),
            "That is audible pumping if it happens often: lower the loudest track's `volume` or the master's loudness "
            "target.");
    if (report.lufs < -35.0)
        add("warning", std::format("the mix is very quiet: {:.1f} LUFS", report.lufs),
            "Raise the song's `volume` or the quiet tracks' `volume`; check that no track is muted by mistake.");
    else if (o.targetLufs && std::abs(report.lufs - *o.targetLufs) > 3.0 && !ms.targetLufs)
        add("warning",
            std::format("the mix is {:.1f} LUFS, {:.1f} LU {} the target {:.1f} LUFS of the music bus", report.lufs,
                        std::abs(report.lufs - *o.targetLufs), report.lufs > *o.targetLufs ? "above" : "below",
                        *o.targetLufs),
            std::format("The master's loudness is \"off\": set mixer.master.loudness to \"style\" to bring it to the "
                        "target, or multiply the song's `volume` by {:.2f} ({:+.1f} dB).",
                        sfx_math::db_to_gain(*o.targetLufs - report.lufs), *o.targetLufs - report.lufs));
    else if (ms.targetLufs && std::abs(report.lufs - *ms.targetLufs) > 3.0)
        add("warning",
            std::format("the master could not bring the mix to {:.1f} LUFS: it ends at {:.1f} LUFS", *ms.targetLufs,
                        report.lufs),
            ms.limiter
                ? "The limiter's ceiling stops a louder mix (peaks are in the way) or the gain needed is more than the "
                  "+18 dB the normalization adds: raise the quiet tracks' `volume` or lower the target."
                : "The gain needed is more than the +18 dB the normalization adds: raise the quiet tracks' `volume`.");
}

}  // namespace

Result<SongCheckReport> check_song(const SongDoc& song, const SongTimeline& timeline, const SongCheckOptions& options) {
    std::vector<std::string> names;
    for (const SongCheckRule& rule : song_check_rules()) names.push_back(rule.name);
    for (const std::string& n : options.rules)
        if (std::find(names.begin(), names.end(), n) == names.end())
            return make_error(
                "unknown check rule `" + n + "`", did_you_mean(n, names) + " Rules: " + [&] {
                    std::string s;
                    for (const auto& x : names) s += (s.empty() ? "" : ", ") + x;
                    return s;
                }() + ".");
    auto wanted = [&](const SongCheckRule& rule) {
        if (!options.rules.empty())
            return std::find(options.rules.begin(), options.rules.end(), rule.name) != options.rules.end();
        return !rule.needsRender || options.render;
    };
    SongCheckReport report;
    report.notes = int(timeline.notes.size());
    Reporter r{song, timeline, {}, {}};
    Result<std::monostate> status = std::monostate{};
    for (const SongCheckRule& rule : song_check_rules()) {
        if (!wanted(rule)) continue;
        report.rulesRun.push_back(rule.name);
        if (rule.name == "off_key")
            rule_off_key(r);
        else if (rule.name == "range")
            rule_range(r);
        else if (rule.name == "clash")
            rule_clash(r);
        else if (rule.name == "mud")
            rule_mud(r);
        else if (rule.name == "structure")
            rule_structure(r);
        else if (rule.name == "loudness") {
            rule_loudness(r, options, report, status);
            if (!status) return status.error();
        }
    }
    auto order = [](const std::string& s) { return s == "error" ? 0 : s == "warning" ? 1 : 2; };
    std::stable_sort(r.out.begin(), r.out.end(), [&](const SongCheckIssue& a, const SongCheckIssue& b) {
        return order(a.severity) < order(b.severity);
    });
    report.issues = std::move(r.out);
    return report;
}

}  // namespace fa
