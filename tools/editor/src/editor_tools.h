// Editor tools that wrap ENGINE COMMANDS: Save as prefab (prefab.save), Import ASCII level (scene.import_ascii),
// Format scene files (scene.format) and the Audio panel's feed (audio.log).
//
// Everything here is plain logic over a CommandRegistry: no ImGui, no Editor, no window. The panels in
// prefab_dialog.cpp, level_dialog.cpp, format_dialog.cpp and audio_panel.cpp only draw it, and tests call it
// directly against a headless Engine. The editor never reimplements what the commands do; it builds their arguments,
// runs them and turns the result (or the error with its hint) into text a person can read.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::editor {

// ------------------------------------------------------------------------------------------------ Save as prefab
// "prefabs/<id>.prefab.json", with characters that do not belong in a file name replaced by '_'.
std::string suggest_prefab_path(const std::string& entityId);

struct PrefabSaveOutcome {
    bool ok = false;
    bool alreadyExists = false;      // not saved: the file exists and `overwrite` was false (ask before replacing it)
    std::string path;                // the file written (the path the command reports)
    std::size_t children = 0;        // descendants saved with the entity
    bool overwritten = false;
    std::vector<std::string> notes;  // what the file does NOT carry (root position, ids, tilemap tags, dangling references)
    std::string code, message, hint; // when !ok
};
// prefab.save {id, path, overwrite}.
PrefabSaveOutcome save_prefab(const CommandRegistry& commands, const std::string& entityId, const std::string& path, bool overwrite);

// ------------------------------------------------------------------------------------------------ Import ASCII level
// The arguments of scene.import_ascii as typed in the dialog.
struct AsciiImportForm {
    std::string rows;      // the map, one row per line, row 0 = TOP
    std::string legend;    // JSON object: glyph -> tile index or {tile?, prefab?, id?, overrides?, offset?}
    std::string tilemap;   // JSON object with Tilemap fields (tileset, tileSize, columns, solidTiles, color, layer) or ""
    std::string options;   // JSON object with the other arguments (entity, position, anchor, replace) or ""
    bool toFile = true;    // true: build the scene FILE `path` (the running game is not touched); false: change the running scene
    std::string path;      // toFile: scene file to write, e.g. scenes/level1.scene.json
    std::string from;      // toFile, optional: scene file to start from instead of `path`
    bool save = false;     // running scene: also write the scene file (like scene.save)
};

// The command arguments for the form. Errors say which box is wrong, with line and column for invalid JSON.
Result<Json> ascii_import_args(const AsciiImportForm& form, bool dryRun);

// Reads a `levels/*.json`-style argument file ({rows, legend, tilemap?, path?, from?, entity?, anchor?, position?, ...}).
Result<AsciiImportForm> load_ascii_form(const std::string& file);

// The project files that look like level argument files (levels/*.json, not scenes), sorted.
std::vector<std::string> level_files(const std::vector<std::string>& projectFiles);

struct AsciiImportOutcome {
    bool ok = false;
    bool dryRun = false;
    std::string code, message, hint;        // when !ok: the command's error (row/column messages live in `message`)
    int width = 0, height = 0, tileCount = 0;
    std::size_t spawned = 0, removed = 0;
    std::vector<std::string> spawnedLines;  // "coin_1  prefabs/coin.prefab.json  cell (3, 1)  at (112, 48)"
    std::vector<std::string> warnings, notes;
    std::string tilemap;                    // id of the Tilemap entity
    std::string path;                       // file mode: the scene file
    std::string saved;                      // the file that was written ("" for a preview)
    std::size_t entityCount = 0;            // file mode: entities in the resulting scene
};
// Runs the command and condenses its result. `dryRun` only applies to file mode; for the running scene it is the
// caller's job to preview with a file (see Editor::preview_ascii_import).
AsciiImportOutcome run_ascii_import(const CommandRegistry& commands, const AsciiImportForm& form, bool dryRun);

// ------------------------------------------------------------------------------------------------ Format scene files
struct FormatOutcome {
    bool ok = false;                  // the command ran (individual files may still be in `errors`)
    bool check = false;               // true: nothing was written, `files` are the non-canonical ones
    std::vector<std::string> files;   // check: files whose layout differs; real run: files rewritten
    std::size_t unchanged = 0;        // files already in the canonical layout
    std::vector<std::string> errors;  // "file:line:col: message" for files that are not valid JSON (left untouched)
    std::vector<std::string> notes;
    std::string code, message, hint;  // when !ok
};
// scene.format {check, paths?}; paths empty = the whole project.
FormatOutcome run_scene_format(const CommandRegistry& commands, bool check, const std::vector<std::string>& paths = {});

// ------------------------------------------------------------------------------------------------ Audio panel
struct AudioPlay {
    std::uint64_t seq = 0, frame = 0;
    double time = 0;
    std::string path, bus, source;
    float volume = 1, pitch = 1, pan = 0;
    bool loop = false, music = false, ok = true;
};

struct AudioLogState {
    std::vector<AudioPlay> plays;   // oldest first, capped at kMax
    std::uint64_t after = 0;        // seq of the newest play seen or cleared: the next poll asks for newer ones
    std::uint64_t dropped = 0;      // plays the engine's own log (4096) forgot
    std::string filter;             // keep plays whose path contains this (case-insensitive)
    bool onlyFailed = false;        // keep only plays whose clip failed to load
    bool autoScroll = true;
    std::uint64_t scrolledTo = 0;   // seq of the newest play the panel already scrolled to
    std::string error;              // last poll error ("" = fine)
    static constexpr std::size_t kMax = 2000;
};
// audio.log {after}: appends the plays newer than state.after. Returns the number of new plays.
std::size_t poll_audio_log(const CommandRegistry& commands, AudioLogState& state);
// Forgets what is shown; later polls only add plays newer than the newest one seen.
void clear_audio_log(AudioLogState& state);
// Forgets everything including the position (a new project has a new log that starts at seq 1).
void reset_audio_log(AudioLogState& state);
bool audio_play_visible(const AudioPlay& play, const AudioLogState& state);

}  // namespace fa::editor
