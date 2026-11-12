// What assets_music.cpp (music.info, music.check, music.preview and the project.validate check) and assets_music_edit.cpp
// (music.create, music.edit and the helper commands) share: finding and reading song documents, the issue JSON, the summary of a
// song and its schema helpers. Private to tools/common.
#pragma once

#include <filesystem>
#include <optional>
#include <string>
#include <vector>

#include "assets_internal.h"
#include "fa/audio/song.h"
#include "fa/audio/song_preview.h"

namespace fa::assets_detail::music {

inline constexpr const char* kSuffix = ".song.json";

// The normalized project path of a song argument under assets/, or an error that says what a song path is.
std::string song_path(const std::string& arg, const char* what = "path");
// `rel` without .song.json.
std::string song_stem(const std::string& rel);
// Where music.preview writes by default: the song's path with .preview.wav.
std::string default_preview(const std::string& rel);

// Every song of the project, sorted (project-relative; hidden folders and node_modules skipped).
std::vector<std::string> list_songs(const std::string& projectDir);

Json issues_json(const std::vector<SongIssue>& issues);

struct Loaded {
    std::string rel;       // empty for a song given inline
    Json json;
    SongDoc doc;
};
// Reads and checks the song at `rel`. A song with mistakes throws one `invalid_song` error that carries all of them in data.issues.
Loaded load_song_file(const std::string& projectDir, const std::string& rel);
// Checks a song document that is not on disk yet (`rel` names it in messages); throws invalid_song with every issue. `what` is
// appended to the message ("Nothing was written.").
SongDoc check_song_json(const Json& json, const std::string& rel, const char* what = "");
// Writes the document as canonical JSON (already checked).
void write_song(const std::string& projectDir, const std::string& rel, const Json& json);
// The song of `path` or the inline `song` of a command's arguments (exactly one).
Loaded resolve_song(const std::string& projectDir, const Json& a, const char* command);
SongTimeline expand_or_fail(const SongDoc& doc, const std::string& rel);

// "intro (2 bars) > loop (4 bars) x2 > outro (2 bars)".
std::string structure_text(const SongDoc& doc);
// The compact description of a song every music command returns: tempo, meter, key, bars, seconds, notes, tracks and sections.
Json summary_json(const SongDoc& doc, const SongTimeline& timeline);
// Adds the piano-roll picture (`$image`, `pianoRoll`) of the song to `result`; reads width, fromBar, bars, pictureOut from `a`.
void add_piano_roll(const std::string& projectDir, const Json& a, const SongDoc& doc, const SongTimeline& timeline, Json& result, const char* command);
// Refuses a `pictureOut` the caller may not write (writeProject, inside the project) before the command does any work.
void check_picture_out(const std::string& projectDir, const Json& a, const char* command);

double round_to(double v, int decimals);
inline Json num(double v, int decimals = 2) { return Json(round_to(v, decimals)); }
std::string meter_text(const SongMeter& m);

// ---- schema helpers for the input schemas ----
inline Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}
inline Json str(const char* what) { return Json::object({{"type", "string"}, {"description", what}}); }
inline Json number(const char* what, double lo, double hi) { return Json::object({{"type", "number"}, {"minimum", lo}, {"maximum", hi}, {"description", what}}); }
inline Json integer(const char* what, long lo, long hi) { return Json::object({{"type", "integer"}, {"minimum", lo}, {"maximum", hi}, {"description", what}}); }
inline Json boolean(const char* what, bool def) { return Json::object({{"type", "boolean"}, {"default", def}, {"description", what}}); }
inline Json object_arg(const char* what) { return Json::object({{"type", "object"}, {"description", what}}); }
inline Json strings(const char* what) { return Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})}, {"description", what}}); }

// What a render of the song did (music.mix's `mix` block), and the loudness target a song asks of the style guide (nullopt unless its master
// loudness is "style" and the style guide sets one).
Json music_mix_json(const SongDoc& doc, const SongRender& render, const std::optional<double>& styleTarget);
std::optional<double> music_style_target(const std::string& projectDir, const SongDoc& doc);

// music.render (assets_music_render.cpp) and music.import_midi / music.export_midi (assets_music_midi.cpp).
void register_music_render_commands(CommandRegistry& registry, const std::string& projectDir);
void register_music_midi_commands(CommandRegistry& registry, const std::string& projectDir);
// Imports the Standard MIDI File `source` (an absolute path) as the song `outRel` (see music.import_midi); the result of that command.
Json import_midi_file(const std::string& projectDir, const std::filesystem::path& source, const std::string& sourceLabel, const Json& args, const std::string& outRel);

void register_music_edit_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa::assets_detail::music
