// music.import_midi and music.export_midi: Standard MIDI Files to and from song documents (docs/MUSIC.md, "MIDI").
// The parser, the converters and the exact rules are in engine/audio (midi.h, song_midi.h); this file is the commands around them.
#include <algorithm>
#include <format>

#include "assets_internal.h"
#include "fa/audio/midi.h"
#include "fa/audio/song.h"
#include "fa/audio/song_midi.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "music_internal.h"
#include "util.h"

namespace fa::assets_detail::music {

namespace {

constexpr const char* kImport = "music.import_midi";
constexpr const char* kExport = "music.export_midi";

bool is_midi_name(const std::string& path) {
    const std::string ext = to_lower(fs::extension(path));
    return ext == ".mid" || ext == ".midi";
}

// The file of a `path` argument that is read: absolute on this machine, or relative to the project.
stdfs::path source_file(const std::string& projectDir, const std::string& arg, const char* command) {
    if (arg.find("://") != std::string::npos)
        fail("invalid_argument", std::string(command) + " reads files on this machine, and '" + arg + "' is a URL.",
             "Download the file first, then pass its local path.");
    const stdfs::path path = stdfs::path(arg).is_absolute() ? stdfs::path(arg) : project_file(projectDir, arg);
    std::error_code ec;
    if (!stdfs::is_regular_file(path, ec))
        fail("not_found",
             "The file '" + arg + "' does not exist" + (stdfs::is_directory(path, ec) ? " (it is a folder)." : "."),
             "Pass the absolute path of the .mid file, or a path relative to the project folder.");
    if (stdfs::file_size(path, ec) > (std::uintmax_t(64) << 20))
        fail("too_large", "'" + arg + "' is larger than 64 MB, which is not a MIDI file of a song.",
             "Check that it is a Standard MIDI File.");
    return path;
}

}  // namespace

Json import_midi_file(const std::string& projectDir, const stdfs::path& source, const std::string& sourceLabel,
                      const Json& a, const std::string& outRel) {
    const std::string out =
        outRel.empty() ? "assets/music/" + safe_file_name(source.stem().string(), "song") + kSuffix : outRel;
    const std::string rel = song_path(out, "out");
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    std::error_code ec;
    if (!overwrite && stdfs::exists(project_write_file(projectDir, rel), ec))
        fail("exists", "'" + rel + "' already exists.", "Pass overwrite: true to replace it, or choose another `out`.");
    (void)project_write_file(projectDir, rel);
    require_usable_manifest(projectDir);

    const std::string text = tooling_detail::read_file(source).value_or(std::string());
    if (text.empty())
        fail("failed", "Cannot read '" + sourceLabel + "' (or it is empty).",
             "Check that the file exists and is readable.");
    auto file = parse_midi(std::vector<std::uint8_t>(text.begin(), text.end()), sourceLabel);
    if (!file.ok())
        fail("invalid_midi", file.error().message,
             file.error().hint.empty()
                 ? "The file must be a Standard MIDI File (format 0 or 1, ticks per quarter note)."
                 : file.error().hint);

    MidiImportOptions options;
    options.source = source.filename().string();
    options.quantize = tooling_detail::arg_string(a, "quantize", false, "off");
    options.soundfont = tooling_detail::arg_string(a, "soundfont", false);
    options.loopWhole = tooling_detail::arg_bool(a, "loop", false);
    if (!options.soundfont.empty()) {
        // The path before '#' is a project file; it must exist so the song plays.
        auto norm = fs::normalize_checked(options.soundfont);
        if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/") || to_lower(fs::extension(*norm)) != ".sf2")
            fail("invalid_argument", "`soundfont` '" + options.soundfont + "' is not a SoundFont (.sf2) under assets/.",
                 "Example: \"assets/music/gm.sf2\".");
        options.soundfont = *norm;
    }
    Result<MidiImportResult> imported = [&] {
        ProjectRootGuard root(projectDir);
        return midi_to_song(*file, options);
    }();
    if (!imported.ok()) fail("failed", sourceLabel + ": " + imported.error().message, imported.error().hint);

    SongDoc doc = check_song_json(imported->song, rel, "Nothing was written.");
    const SongTimeline tl = expand_or_fail(doc, rel);
    write_song(projectDir, rel, imported->song);

    // Where the song came from, for the credits.
    Json provenance = Json::object(
        {{"origin", "imported"},
         {"date", assets::today()},
         {"source", tooling_detail::arg_string(a, "sourceUrl", false, replace_all(sourceLabel, "\\", "/"))}});
    for (const char* key : {"license", "author"})
        if (const std::string v = tooling_detail::arg_string(a, key, false); !v.empty()) provenance[key] = v;
    {
        ProjectRootGuard root(projectDir);
        auto r = assets::update_entry(rel, [&](Json& e) { e["provenance"] = provenance; });
        if (!r.ok())
            fail("failed", "The song was written, but assets.json was not updated: " + r.error().message,
                 r.error().hint);
    }

    Json result = Json::object({{"path", rel}, {"source", sourceLabel}});
    Json summary = summary_json(doc, tl);
    for (auto it = summary.begin(); it != summary.end(); ++it) result[it.key()] = it.value();
    result["import"] = Json::object({{"midiTracks", file->tracks.size()},
                                     {"songTracks", imported->tracks},
                                     {"notes", imported->notes},
                                     {"bars", imported->bars},
                                     {"sections", imported->sections},
                                     {"patterns", imported->patterns},
                                     {"quantize", options.quantize},
                                     {"ticksPerQuarter", file->division},
                                     {"format", file->format}});
    if (!imported->warnings.empty()) result["warnings"] = imported->warnings;
    Json steps = Json::array();
    steps.push_back("Listen with music.preview {\"path\":\"" + rel +
                    "\"} and look at the piano roll music.info draws. Instruments are the nearest built-in ones to the "
                    "General MIDI programs: change one with music.edit set_track (or pass `soundfont`).");
    steps.push_back(
        "music.check finds notes the instruments cannot play and clashes; music.edit changes patterns, sections and "
        "the mixer. Record the license of the file with `license` and `author` when it is not yours.");
    if (!imported->warnings.empty())
        steps.push_back("Read `warnings`: they say what the song cannot hold (tempo or meter changes, notes dropped, "
                        "drum keys without a lane).");
    result["nextSteps"] = steps;
    return result;
}

namespace {

Json music_import_midi_command(const std::string& projectDir, const Json& a) {
    check_arg_keys(kImport, a, "",
                   {"path", "out", "quantize", "soundfont", "loop", "overwrite", "license", "author", "sourceUrl"});
    const std::string arg = tooling_detail::arg_string(a, "path", true);
    if (!is_midi_name(arg))
        fail("invalid_argument", "`path` '" + arg + "' is not a .mid file.",
             "Pass a Standard MIDI File (.mid or .midi), e.g. \"C:/music/theme.mid\" or \"assets/music/theme.mid\".");
    return import_midi_file(projectDir, source_file(projectDir, arg, kImport), arg, a,
                            tooling_detail::arg_string(a, "out", false));
}

Json music_export_midi_command(const std::string& projectDir, const Json& a) {
    check_arg_keys(kExport, a, "", {"path", "out", "overwrite"});
    const std::string rel = song_path(tooling_detail::arg_string(a, "path", true));
    Loaded loaded = load_song_file(projectDir, rel);
    const SongTimeline tl = expand_or_fail(loaded.doc, rel);
    const std::string outArg = tooling_detail::arg_string(a, "out", false);
    const std::string out = outArg.empty() ? song_stem(rel) + ".mid" : outArg;
    auto norm = fs::normalize_checked(out);
    if (!norm.ok() || norm->empty() || !is_midi_name(*norm))
        fail("invalid_argument", "`out` '" + out + "' must be a project path ending in .mid.",
             "Example: \"out\": \"" + song_stem(rel) + ".mid\".");
    const stdfs::path file = project_write_file(projectDir, *norm);
    std::error_code ec;
    if (!tooling_detail::arg_bool(a, "overwrite", false) && stdfs::exists(file, ec))
        fail("exists", "'" + *norm + "' already exists.",
             "Pass overwrite: true to replace it, or choose another `out`.");
    auto exported = song_to_midi(loaded.doc, tl);
    if (!exported.ok()) fail("failed", rel + ": " + exported.error().message, exported.error().hint);
    std::string err;
    if (!tooling_detail::write_file(
            file, std::string_view(reinterpret_cast<const char*>(exported->bytes.data()), exported->bytes.size()),
            &err))
        fail("failed", err);
    Json result = Json::object({{"song", rel},
                                {"path", *norm},
                                {"bytes", exported->bytes.size()},
                                {"format", 1},
                                {"tracks", exported->tracks},
                                {"notes", exported->notes},
                                {"ticksPerQuarter", kSongPpq}});
    if (!exported->warnings.empty()) result["warnings"] = exported->warnings;
    result["nextSteps"] =
        Json::array({"Open it in a DAW or notation program. music.import_midi reads it back as the same notes, timing "
                     "and velocities; the mixer, effects, buses and automation are not part of a MIDI file."});
    return result;
}

}  // namespace

void register_music_midi_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = kImport;
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Turn a Standard MIDI File (.mid) into a song document: tracks, patterns, sections from "
                       "markers, drums as grids.";
        info.description =
            "Reads the MIDI file `path` (absolute on this machine, or in the project) with the engine's own "
            "parser (format 0 and 1, running status, meta events, any number of tracks and channels; format "
            "2 and SMPTE timing are errors) and writes a song document at `out` (default "
            "assets/music/<name>.song.json; assets.import does the same for a .mid). Every (track, channel, "
            "program) that plays notes becomes a song track: channel 10 is a drum track (General MIDI "
            "percussion keys become the lanes of the built-in kit, as a step grid with ghost / hit / accent "
            "velocities), the others take the built-in instrument nearest to the General MIDI program (an "
            "Instrument Name that names a built-in instrument wins; with `soundfont` the track plays that "
            "SoundFont's preset of the program). Velocities are kept, the sustain pedal lengthens notes, "
            "controllers 7 and 10 become the track's volume and pan. `quantize` (\"off\" keeps the written "
            "times to 1/48 of a quarter note; \"16\", \"8t\", \"32\"...) snaps starts and ends. Example: "
            "{\"path\":\"C:/music/theme.mid\",\"out\":\"assets/music/"
            "theme.song.json\",\"quantize\":\"16\"}" FA_COMMAND_DETAILS
            "Markers become sections (a name starting with intro, loop or outro, or written \"loop:name\"); "
            "without markers the song is one section `main`, a loop when `loop` is true. Repeated bars of a "
            "track become one pattern played several times. Tempo, meter and key come from the first such "
            "event; a later change cannot be held by a song and is listed in `warnings`. Errors name the "
            "byte offset in the file. The result is the song summary (as music.info) plus `import` (what was "
            "read) and `warnings`; `license`, `author` and `sourceUrl` go to the song's provenance in "
            "assets.json. An existing song is an `exists` error unless overwrite is true.";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"required", Json::array({"path"})},
             {"additionalProperties", false},
             {"properties",
              obj({{"path", str("The MIDI file: an absolute path on this machine, or relative to the project. Ends in "
                                ".mid or .midi.")},
                   {"out", str("The song to write: under assets/, ending in .song.json. Default: "
                               "assets/music/<name>.song.json.")},
                   {"quantize", str("\"off\" (default) or a note value to snap starts and ends to: \"4\", \"8\", "
                                    "\"16\", \"32\", \"64\", \"8t\", \"16t\"...")},
                   {"soundfont", str("A SoundFont (.sf2) under assets/: pitched tracks play its preset with their "
                                     "General MIDI program and drums its drum kit.")},
                   {"loop",
                    boolean(
                        "A file with no markers: make its one section the song's loop (default: an ordinary section).",
                        false)},
                   {"overwrite", boolean("Replace the song when it exists.", false)},
                   {"license", str("License of the MIDI file (\"CC0\", \"CC-BY 4.0\"), for the credits.")},
                   {"author", str("Who made the MIDI file.")},
                   {"sourceUrl", str("The page the file came from, for the credits.")}})}});
        mark_paths(info.inputSchema, "read", {"path"});
        mark_paths(info.inputSchema, "write", {"out"});
        registry.add(info, [projectDir](const Json& args) {
            return music_import_midi_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = kExport;
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Write a song as a format-1 Standard MIDI File that a DAW or notation program opens.";
        info.description = "Writes the song at `path` as a Standard MIDI File (format 1, 960 ticks per quarter note) "
                           "at `out` (default: the song's path with .mid). Track 1 holds the tempo, time signature, "
                           "key signature (major or minor) and one marker "
                           "per section (\"kind:name\"); then one track per song track with its name, instrument "
                           "(Instrument Name and the General MIDI program), volume and pan controllers and its notes "
                           "with the length they sound; drum tracks use channel 10 and the General MIDI "
                           "percussion keys. The sounded timeline is written: swing is in the note times, `transpose` "
                           "in the pitches, and muted tracks (or tracks not soloed) are left out. The mixer, effects, "
                           "buses and automation are not part of a MIDI file. "
                           "music.import_midi reads the file back as the same notes, timing and velocities. Example: "
                           "{\"path\":\"assets/music/theme.song.json\"}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"required", Json::array({"path"})},
             {"additionalProperties", false},
             {"properties",
              obj({{"path", str("The song, project-relative, under assets/ and ending in .song.json.")},
                   {"out",
                    str("The MIDI file to write: a project path ending in .mid. Default: the song's path with .mid.")},
                   {"overwrite", boolean("Replace the file when it exists.", false)}})}});
        mark_paths(info.inputSchema, "read", {"path"});
        mark_paths(info.inputSchema, "write", {"out"});
        registry.add(info, [projectDir](const Json& args) {
            return music_export_midi_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    using namespace capability_sets;  // capability.h: both write a file of the project
    declare_command_capabilities(registry, {{kImport, writes_project()}, {kExport, writes_project()}});
}

}  // namespace fa::assets_detail::music
