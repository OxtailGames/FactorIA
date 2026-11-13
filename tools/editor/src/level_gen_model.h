// The Level generator window's model (View > Level generator): the arguments of `tilemap.generate` built from the window's fields, a
// generation run in small pieces by `tilemap.generate_start` / `generate_step` (so the window keeps drawing), the preview it ends
// with, and the two ways to keep a level: `scene.import_ascii` into the open scene (an undo step, markers become entities) or an
// ASCII level file. No ImGui, no Editor: tests/level_gen_tests.cpp drives it against a headless Engine. The editor never
// reimplements what the commands do; it calls them, so the window, the Console, the AI and a script see the same level.
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::editor {

// Calls a command and returns its result (the editor passes the engine's registry; a test may pass a fake).
using LevelGenCaller = std::function<CommandResult(const std::string& name, const Json& args)>;

struct LevelGenOptions {
    std::string sampleEntity;  // id of an entity with a Tilemap (used when sampleFile is empty)
    std::string
        sampleFile;  // project-relative .json file with rows + legend (scene.import_ascii arguments); wins over the entity
    int width = 48, height = 28;        // the level in cells
    std::int64_t seed = 1;              // 0..2147483647
    std::string model = "overlapping";  // or "tiled" (the sample's autotile rules)
    int n = 3;                          // overlapping: side of the windows, 2..5
    int symmetry = 1;                   // overlapping: 1, 2, 4 or 8
    bool periodic = false;
    std::string
        extra;  // a JSON object merged over the arguments: constraints, reachability, maxAttempts, ... (not the keys the fields above own)
};

inline constexpr std::int64_t kLevelGenMaxSeed = 2147483647;

// The arguments of tilemap.generate for these options. Fails (with what to fix and which field) when the sample is missing, a size
// is out of range or `extra` is not a JSON object; the generator itself checks the rest and its errors are shown as they come.
Result<Json> level_gen_arguments(const LevelGenOptions& o);

// One cell of a preview, as the legend gives it: the glyph (a code point: a big palette uses more than ASCII), the tile number (-1 =
// empty / not a tile) and whether the glyph also spawns a prefab (a marker: spawn point, coin, enemy).
struct LevelGenCell {
    char32_t glyph = 0;
    int tile = -1;
    bool marker = false;
};

// What a finished generation leaves for the window to draw.
struct LevelGenPreview {
    bool valid = false;
    int width = 0, height = 0;
    std::int64_t seed = 0;
    std::vector<std::string> rows;  // row 0 = top, one glyph per cell
    std::vector<LevelGenCell>
        cells;  // width * height, row-major, built once when the generation ends (the legend is not looked up per drawn cell)
    Json legend = Json::object();  // glyph -> tile / object, as tilemap.generate returns it
    Json stats = Json::object();   // attempts, contradictions, work, patterns, ms...
    std::vector<std::string> warnings;
};

// One kept or tried seed, for the history strip of the window.
struct LevelGenTry {
    std::int64_t seed = 0;
    bool ok = false;
    std::string note;  // "3 attempt(s)" or the first line of the error
};

class LevelGenSession {
public:
    enum class State { Idle, Running, Ready, Failed };

    State state() const { return state_; }
    bool running() const { return state_ == State::Running; }
    double progress() const { return progress_; }  // 0..1 while Running
    const LevelGenPreview& preview() const {
        return preview_;
    }  // valid when Ready; kept from the last good run while Running / Failed
    int job() const { return job_; }                     // the engine's job id while Running, else 0
    const std::string& error() const { return error_; }  // Failed: what went wrong
    const std::string& hint() const { return hint_; }    // Failed: how to fix it
    // Why a run stopped without a result and without being a failure ("the scene changed under it"); "" otherwise. Cleared by start / clear.
    const std::string& notice() const { return notice_; }
    const std::vector<LevelGenTry>& tries() const { return tries_; }  // oldest first, at most kMaxTries
    static constexpr std::size_t kMaxTries = 24;

    // Starts a generation with `o` (cancels a running one). A refused start (bad arguments) is a Failed state with the error text.
    void start(const LevelGenOptions& o, const LevelGenCaller& call);
    // Runs the generator for about `budgetMs` of this frame (at least one small step). Returns true while it still runs.
    bool tick(const LevelGenCaller& call, double budgetMs);
    // Stops a running generation and frees the engine's memory for it.
    void cancel(const LevelGenCaller& call);
    // Forgets the preview and the history (a different sample). A running generation is cancelled first through `call`, so its job
    // (and its solver memory) does not stay in the engine; pass an empty function only when the engine itself is gone.
    void clear(const LevelGenCaller& call);

private:
    void fail(const std::string& error, const std::string& hint);
    State state_ = State::Idle;
    int job_ = 0;
    double progress_ = 0;
    std::int64_t seed_ = 0;
    LevelGenPreview preview_;
    std::string error_, hint_, notice_;
    std::vector<LevelGenTry> tries_;
};

// The cell at (col, row) of a preview: see LevelGenPreview::cells (empty / outside the level: tile -1, no marker, glyph 0).
LevelGenCell level_gen_cell(const LevelGenPreview& p, int col, int row);
// The glyph of a cell as UTF-8 text ("" when it has none), for a tooltip or a label.
std::string level_gen_glyph_text(const LevelGenCell& c);

// scene.import_ascii arguments that build the preview in the open scene as the entity `entity`: the rows and legend, the Tilemap fields
// `tilemap` (tileset, tileSize, solidTiles...; copy them from the sample), and the position of its top-left corner.
Json level_gen_keep_arguments(const LevelGenPreview& p, const std::string& entity, const Json& tilemapFields, double x,
                              double y);
// The Tilemap fields worth copying from a sample entity (scene.get_entity's "Tilemap" object) to a generated level: the tileset, its
// geometry and the solid tiles. The size and the tiles themselves come from the preview.
Json level_gen_tilemap_fields(const Json& tilemapComponent);
// The text of an ASCII level file for the preview, in the format `scene.import_ascii @file` and `tilemap.generate` read:
// {"rows", "legend", "tilemap", "entity"}. `scene.ascii_edit` edits it afterwards.
std::string level_gen_file_text(const LevelGenPreview& p, const std::string& entity, const Json& tilemapFields);

// A name for the file / entity the Keep buttons use: letters, digits, '_' and '-' only ("" when nothing is left).
std::string level_gen_safe_name(const std::string& text);

}  // namespace fa::editor
