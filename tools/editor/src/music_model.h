// The logic of the editor's Music panel with no ImGui and no window: the song being edited (a *.song.json), what it renders to for listening,
// the notes of a pattern and the drum grids as an editor sees them, and the undo steps. music_panel.cpp draws it; music_tests.cpp and the
// autotest drive it.
//
// ONE SET OF CODE. Every edit that is kept is a command call (music.edit, music.arpeggio, music.bassline, music.drums), the same call the
// Console, an AI or a script makes, so the file on disk is what the commands would have written. A note being dragged only moves in the
// panel's own copy of the pattern; letting go makes the one music.edit set_pattern (with the notes as a list: tools/common writes them back as
// note text, see docs/MUSIC.md "The Music panel").
//
// Edits are written to disk as they happen and do NOT bake (the stems next to the song stay as they were until Save). The song is rendered
// again in the background a few frames after a change (a worker thread; tests render inline): that render is what Play listens to. Undo is a
// table of steps, the before and after contents of the song file; the editor's undo stack holds only {"$music": {"step": id}} entries that
// point into it.
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <future>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "fa/audio/music_player.h"
#include "fa/audio/song.h"
#include "fa/core/command.h"
#include "fa/core/json.h"
#include "image_model.h"

namespace fa::editor {

using MusicCommandFn = std::function<CommandResult(const std::string& name, const Json& args)>;
using MusicBlob = ImageBlob;
using MusicSourcePtr = std::shared_ptr<const MusicSource>;

struct MusicStep {
    int id = 0;
    std::string rel;     // the song the panel had open
    std::string label;
    MusicBlob before, after;
};

struct MusicEditOutcome {
    bool ok = true;
    std::string error;   // what went wrong, with the command's hint
    int step = 0;        // the undo step it recorded (0 = the edit changed nothing on disk)
    Json result;         // the command's result
};

// ---- drum grids ---------------------------------------------------------------------------------------------------------------------
// A drum pattern as rows of steps: one text per lane, one character per step ('x' hit, 'X' accent, 'o' ghost note, '.' rest).
struct MusicDrumGrid {
    std::vector<std::pair<std::string, std::string>> lanes;   // lane name -> steps (spaces and bar lines taken out)
    std::string step = "16";                                  // the note value of a step: "4", "8", "16", "32", "8t", "16t"
    int bars = 1;
    int steps_per_bar(const SongMeter& meter) const;
    int total_steps(const SongMeter& meter) const { return steps_per_bar(meter) * bars; }
    // The step text of `lane` padded (or cut) to the grid's length; "" for a lane the grid has not got.
    std::string row(const std::string& lane, const SongMeter& meter) const;
    char at(const std::string& lane, int stepIndex, const SongMeter& meter) const;
    // Sets one step (adding the lane when it is missing). `c` is '.', 'x', 'X' or 'o'.
    void set(const std::string& lane, int stepIndex, char c, const SongMeter& meter);
    // The fields of a music.edit set_pattern op: {grid, step, bars}.
    Json op_fields(const SongMeter& meter) const;
};
// Ticks of a step ("16" -> 240, "8t" -> 1280); 0 for a note value the grid does not know.
std::int64_t music_step_ticks(const std::string& step);
// The grid of a drum pattern as written; nullopt for a pattern that is not a drum grid.
std::optional<MusicDrumGrid> music_drum_grid(const SongPattern& pattern);

// Is the MIDI `pitch` a note of the song's key and mode?
bool music_in_scale(const SongDoc& song, int pitch);

class MusicModel {
public:
    MusicModel(std::string projectDir, MusicCommandFn call);
    ~MusicModel();
    MusicModel(const MusicModel&) = delete;
    MusicModel& operator=(const MusicModel&) = delete;

    // ---- the document ---------------------------------------------------------------------------------------------
    bool open(const std::string& rel);   // *.song.json; false: error() says why
    void close();
    bool is_open() const { return open_; }
    bool valid() const { return valid_; }            // the file is a valid song (it may be open and broken: error() has the reason)
    const std::string& path() const { return rel_; }
    std::string title() const;
    const std::string& error() const { return error_; }
    const std::string& status() const { return status_; }
    void set_status(const std::string& s) { status_ = s; }
    const Json& json() const { return json_; }
    // The song as parsed and its arrangement unrolled; null while the file does not load.
    const SongDoc* doc() const { return doc_ ? &*doc_ : nullptr; }
    const SongTimeline* timeline() const { return timeline_ ? &*timeline_ : nullptr; }
    std::uint64_t doc_revision() const { return docRev_; }
    // The file changed on disk behind our back: reads it again. Returns true when it did.
    bool poll_external();
    bool reload();

    // ---- reading a pattern ----------------------------------------------------------------------------------------
    const SongTrack* track(const std::string& name) const;
    const SongPattern* pattern(const std::string& track, const std::string& pattern) const;
    std::vector<SongRollNote> notes(const std::string& track, const std::string& pattern) const;
    // The pitched tracks and the drum tracks, in the song's order.
    std::vector<std::string> pitched_tracks() const;
    std::vector<std::string> drum_tracks() const;
    // Where `frame` of the song (kMusicRate per second, as the player counts) is inside `pattern` of `track`, in ticks from its start; nullopt
    // when the track plays another pattern there, is muted in that section or the frame is outside the music.
    std::optional<double> pattern_tick(const MusicMap& map, double frame, const std::string& track, const std::string& pattern) const;
    // A name for a new pattern/track/section that no other uses: "pattern", "pattern2", ...
    std::string free_name(const std::string& base, const std::vector<std::string>& used) const;

    // ---- editing (each is ONE undo step) ---------------------------------------------------------------------------
    // Any music.edit ops.
    MusicEditOutcome edit(const std::string& label, const Json& ops);
    // The notes of a pitched pattern (created when missing; `bars` 0: as long as the pattern is, or the notes need).
    MusicEditOutcome set_notes(const std::string& track, const std::string& pattern, const std::vector<SongRollNote>& notes, int bars = 0, const std::string& label = "Edit notes");
    MusicEditOutcome set_grid(const std::string& track, const std::string& pattern, const MusicDrumGrid& grid, const std::string& label = "Edit drums");
    MusicEditOutcome add_pattern(const std::string& track, const std::string& pattern, int bars, bool drums);
    MusicEditOutcome remove_pattern(const std::string& track, const std::string& pattern);
    MusicEditOutcome set_track(const std::string& track, const Json& fields, const std::string& label = "");
    MusicEditOutcome set_mixer(const Json& fields, const std::string& label = "");   // {buses: {...}, master: {...}}
    MusicEditOutcome set_song(const Json& fields, const std::string& label = "");
    MusicEditOutcome set_section(const std::string& section, const Json& fields, const std::string& label = "");
    MusicEditOutcome set_layers(const Json& layers);
    // The helpers that write a pattern: music.arpeggio / music.bassline / music.drums over a progression, into `track`/`pattern`.
    MusicEditOutcome generate(const std::string& command, const Json& args);
    // The MIDI notes of a chord by name (music.chord, read-only); empty and `error` set when the name is not a chord.
    std::vector<int> chord_pitches(const std::string& name, int octave, std::string* error = nullptr);
    // The loudness of the mixed song (music.mix, read-only): {lufs, peakDb, limiterReductionDb, ...}; null on failure.
    Json measure();

    // ---- files ------------------------------------------------------------------------------------------------------
    // Bakes the song for the game next to it (music.render: the mix and, when the song declares layers, one stem per layer).
    MusicEditOutcome save();
    void set_overwrite_on_save(bool on) { overwriteOnSave_ = on; }
    // The baked mix next to the song (what music.render writes by default); "" when it is not there.
    std::string baked_path() const;

    // ---- the render the panel plays ------------------------------------------------------------------------------------
    // Called every UI frame: collects a finished render, starts the next one when the debounce has run out.
    void tick();
    void set_async(bool async) { async_ = async; }
    void set_debounce_ticks(int n) { debounce_ = n; }
    // Renders what is wanted, blocking, until nothing is pending (tests, and the autotest's "wait for the render").
    void settle();
    bool busy() const;                         // a render is running or about to start
    void request_render();
    MusicSourcePtr source() const { return src_; }     // the last finished render (null before the first)
    bool source_is_fresh() const { return src_ && srcRev_ == docRev_; }
    const std::string& render_error() const { return renderError_; }
    int render_count() const { return renders_; }
    double last_render_ms() const { return renderMs_; }

    // ---- undo -------------------------------------------------------------------------------------------------------
    const MusicStep* step(int id) const;
    bool apply_step(int id, bool forward);
    void retain_steps(const std::set<int>& keep);
    std::string step_document(int id) const;
    std::size_t step_count() const { return steps_.size(); }

private:
    bool load_from_disk();
    std::uint64_t compute_stamp() const;
    MusicBlob read_blob(const std::string& rel);
    bool write_blob(const MusicBlob& blob);
    MusicEditOutcome fail(MusicEditOutcome out, const std::string& message);
    // Runs a command as ONE undo step over the song file.
    MusicEditOutcome run(const std::string& label, const std::function<CommandResult()>& body);
    void start_job();
    void collect();

    std::string projectDir_;
    MusicCommandFn call_;
    bool open_ = false, valid_ = false;
    std::string rel_, error_, status_, renderError_;
    Json json_;
    std::string text_;
    std::optional<SongDoc> doc_;
    std::optional<SongTimeline> timeline_;
    std::uint64_t docRev_ = 0, stamp_ = 0;
    std::map<int, MusicStep> steps_;
    int nextStep_ = 1;
    bool overwriteOnSave_ = false;

    // rendering
    bool async_ = true;
    int debounce_ = 4, wait_ = 0;
    bool dirty_ = false;
    MusicSourcePtr src_;
    std::uint64_t srcRev_ = ~0ULL, failedRev_ = ~0ULL;
    int renders_ = 0;
    double renderMs_ = 0;
    struct Running {
        std::future<std::pair<MusicSourcePtr, std::string>> future;
        std::uint64_t rev = 0;
        double startedMs = 0;
        bool valid = false;
    } running_;
};

}  // namespace fa::editor
