// Music checks (M56.1): `music.check` runs these on a song and returns what an AI should fix before it listens. Every rule says
// where (track, pattern, bar and beat, and the token inside the note text), what is wrong, and a fix. Equal problems are reported
// once with a count, so a wrong note in a looped pattern is one finding, not forty.
//
// Rules (song_check_rules()): off_key, range, clash, mud, structure; and loudness, which renders the song (song_preview.h).
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "fa/audio/song.h"

namespace fa {

struct SongCheckRule {
    std::string name;
    std::string severity;             // the usual severity of its findings: "warning", "error" or "info"
    bool needsRender = false;         // true for loudness
    std::string what;                 // what it looks for
};
const std::vector<SongCheckRule>& song_check_rules();

struct SongCheckOptions {
    std::vector<std::string> rules;   // empty = every rule that does not need a render
    bool render = false;              // also run the loudness rule (renders the whole song)
    std::optional<double> targetLufs; // loudness rule: the integrated loudness the music bus should have (the style guide's); +-3 LU is accepted
    int sampleRate = 22050;           // the loudness render's rate (lower than the preview's: it only measures)
};

struct SongCheckIssue {
    std::string rule;
    std::string severity;             // "error", "warning" or "info"
    std::string message;
    std::string hint;
    std::string track;                // "" when the finding is about the whole song
    std::string pattern;
    std::string section;
    int bar = 0;                      // 1-based bar of the first occurrence (0 = none)
    std::string position;             // "bar 2, beat 3" of the first occurrence
    SongSource source;                // the token of the first occurrence (pointer empty if none)
    int count = 1;                    // how many times it happens
};

struct SongCheckReport {
    std::vector<SongCheckIssue> issues;   // errors first, then warnings, then info; stable inside
    std::vector<std::string> rulesRun;
    int notes = 0;                    // notes of the timeline
    bool rendered = false;
    double lufs = 0.0, peakDb = 0.0;  // when rendered
    // Whether there is no error and no warning (info findings do not count).
    bool ok() const;
};

Result<SongCheckReport> check_song(const SongDoc& song, const SongTimeline& timeline, const SongCheckOptions& options = {});

}  // namespace fa
