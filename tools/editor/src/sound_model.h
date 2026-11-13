// The logic of the editor's Sound panel with no ImGui and no window: the sound being edited (a *.sfx.json patch, a *.audio.json document or a
// plain .wav/.ogg), what it renders to, the measurements, the variants, the A/B slots and the undo steps. sound_panel.cpp draws it;
// sound_tests.cpp and the autotest drive it.
//
// ONE SET OF CODE. Every edit that is kept is a command call (sfx.tweak, sfx.edit, sfx.preset, sfx.family, audio.edit, audio.create), the same
// call the Console, an AI or a script makes, so the file on disk is what the commands would have written. A knob being dragged only shows
// the render of the patch with that macro value in memory; letting go makes the one sfx.tweak.
//
// Edits are written to disk as they happen and do NOT bake (the sound next to the patch stays as it was until Save). The sound is rendered
// again in the background a few frames after a change (a worker thread; tests render inline). Undo is a table of steps, the before and after
// contents of the files an edit changed; the editor's undo stack holds only {"$sound": {"step": id}} entries that point into it.
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
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/tooling/audio_view.h"
#include "image_model.h"

namespace fa::editor {

using SoundCommandFn = std::function<CommandResult(const std::string& name, const Json& args)>;

enum class SoundKind { None, Patch, Document, File };

using SoundBlob = ImageBlob;
using SoundFileSet = ImageFileSet;

struct SoundStep {
    int id = 0;
    std::string rel;  // the file the panel had open
    std::string label;
    SoundFileSet before, after;
};

struct SoundEditOutcome {
    bool ok = true;
    std::string error;  // what went wrong, with the command's hint
    int step = 0;       // the undo step it recorded (0 = the edit changed nothing on disk)
    Json result;        // the last command's result
};

// A rendered sound with everything the panel draws and measures. Immutable once built (shared between the worker and the UI).
struct SoundRender {
    int rate = 44100;
    int channels = 1;
    std::vector<float> samples;  // interleaved
    double seconds = 0.0;
    double lufs = -70.0, peakDb = -200.0;
    double centroidHz = 0.0, riseSeconds = 0.0;
    AudioViewMetrics view;          // true peak, clipped samples, loop seam
    std::optional<AudioLoop> loop;  // frames
    std::vector<AudioStepReport> steps;
    bool truncated = false;
    int peakBlock = 64;  // frames per entry of peakMin / peakMax (the mid channel)
    std::vector<float> peakMin, peakMax;
    AudioSpectrogram spectrogram;
    std::vector<std::string> inputs;  // documents: the project files the render read
    std::uint64_t id = 0;             // unique per render
    std::size_t frames() const { return channels > 0 ? samples.size() / std::size_t(channels) : 0; }
    // The mid sample of frame `i`.
    float mid(std::size_t i) const;
};
using SoundRenderPtr = std::shared_ptr<const SoundRender>;

// Builds the measurements, peaks and spectrogram of rendered samples.
SoundRenderPtr make_sound_render(const RenderedSound& sound);

// What an A/B slot plays.
enum class SoundSlotKind { Current, Variant, Before, Baked };
struct SoundSlot {
    SoundSlotKind kind = SoundSlotKind::Current;
    int variant = 0;  // 1-based, for Variant
    bool operator==(const SoundSlot& o) const {
        return kind == o.kind && (kind != SoundSlotKind::Variant || variant == o.variant);
    }
};
std::string sound_slot_label(const SoundSlot& s);

// dB to add to A and to B so they play equally loud (the louder is brought down to the quieter, never boosted, so nothing clips).
std::pair<double, double> sound_level_match(double lufsA, double lufsB);

// A knob of the macro list.
struct SoundMacro {
    std::string name;
    std::string what;
    double value = 0.0;  // as saved
    double shown = 0.0;  // with a drag in progress
    bool builtin = true;
};

// One variant of a patch (variations: count / seed / spreads).
struct SoundVariantInfo {
    int count = 0;
    std::uint64_t seed = 0;
    double pitchCents = 0, lengthFraction = 0, gainDb = 0, filterOctaves = 0;
    bool noise = true;
};

// One step of an audio document's chain, for the list.
struct SoundChainStep {
    int index = 0;
    std::string type;
    bool enabled = true;
    Json params;                        // the step as written (type, enabled and the fields)
    double seconds = 0, peakDb = -200;  // after the step, from the last render
    bool reported = false;
};

class SoundModel {
public:
    SoundModel(std::string projectDir, SoundCommandFn call);
    ~SoundModel();
    SoundModel(const SoundModel&) = delete;
    SoundModel& operator=(const SoundModel&) = delete;

    // ---- the document ---------------------------------------------------------------------------------------------
    bool open(const std::string& rel);  // *.sfx.json, *.audio.json, .wav, .ogg; false: error() says why
    void close();
    bool is_open() const { return kind_ != SoundKind::None; }
    SoundKind kind() const { return kind_; }
    bool editable() const { return kind_ == SoundKind::Patch || kind_ == SoundKind::Document; }
    bool valid() const { return valid_; }  // the file parses (it may be open and broken: error() has the reason)
    const std::string& path() const { return rel_; }
    std::string title() const;
    const std::string& error() const { return error_; }
    const std::string& status() const { return status_; }
    void set_status(const std::string& s) { status_ = s; }
    // The file as parsed (patch or document JSON).
    const Json& json() const { return json_; }
    std::uint64_t doc_revision() const { return docRev_; }
    // The files changed on disk behind our back: reads them again. Returns true when it did.
    bool poll_external();
    bool reload();

    // ---- rendering --------------------------------------------------------------------------------------------------
    // Called every UI frame: collects a finished render, starts the next one when the debounce has run out.
    void tick();
    void set_async(bool async) { async_ = async; }
    void set_debounce_ticks(int n) { debounce_ = n; }
    // Renders what is wanted, blocking, until nothing is pending (tests, and the autotest's "wait for the render").
    void settle();
    bool busy() const;      // a render is running or about to start
    void request_render();  // after a change: the next tick (after the debounce) starts it
    SoundRenderPtr
    current() const;  // what the main view shows (the last finished render of this sound; null before the first)
    bool current_is_fresh() const;  // it was rendered from the file as it is now
    const std::string& render_error() const { return renderError_; }
    int render_count() const { return renders_; }  // finished main renders, for tests
    double last_render_ms() const { return renderMs_; }
    void set_render_seed(std::uint64_t seed);
    std::uint64_t render_seed() const { return seed_; }
    // Documents: hear the chain only up to this step (-1 = all).
    void set_stop_after(int index);
    int stop_after() const { return stopAfter_; }

    // ---- patches: macros, variants, fields -------------------------------------------------------------------------
    std::vector<SoundMacro> macros() const;
    // Knob drags: the sound shown is the patch with this macro set to `value`, in memory. commit_macros makes it one sfx.tweak (one undo step).
    void preview_macro(const std::string& name, double value);
    bool macro_previewing() const { return !macroPreview_.empty(); }
    void cancel_macro_preview();
    SoundEditOutcome commit_macros(const std::string& label = "Turn knob");
    SoundVariantInfo variations() const;
    // Variant `n` (1-based) rendered in memory (null until the worker finished it; asking starts it).
    SoundRenderPtr variant(int n);
    // The sound as it was before the last edit (null when nothing was edited).
    SoundRenderPtr before() const { return before_; }
    // The baked file next to the patch / document (null when it is not there or does not read).
    SoundRenderPtr baked();
    // Documents with a loop step: the sound as it is before that step (so a loop end can be dragged past where the loop cuts it). Null until rendered.
    SoundRenderPtr loop_ghost();
    std::string baked_path() const;
    // The render of an A/B slot (null while it is still rendering).
    SoundRenderPtr slot(const SoundSlot& s);
    // Field edits by JSON pointer (sfx.edit): one undo step each.
    SoundEditOutcome set_field(const std::string& pointer, const Json& value, const std::string& label = "");
    SoundEditOutcome remove_field(const std::string& pointer, const std::string& label = "");
    SoundEditOutcome add_item(const std::string& pointer, const Json& value, int index = -1,
                              const std::string& label = "");
    SoundEditOutcome move_item(const std::string& pointer, int from, int to, const std::string& label = "");
    // Slider drags of a field: show the patch with the value in memory; commit_field makes it one edit.
    void preview_field(const std::string& pointer, const Json& value);
    bool field_previewing() const { return jsonPreview_; }
    SoundEditOutcome commit_field(const std::string& label = "");
    void cancel_field_preview();
    // The patch JSON as the panel shows it (with a field preview applied).
    const Json& shown_json() const { return jsonPreview_ ? previewJson_ : json_; }
    // Presets (sfx.preset over this patch) and the family of this patch (sfx.family into <base>_family/).
    SoundEditOutcome apply_preset(const std::string& name);
    SoundEditOutcome make_family(const std::string& preset, bool overwrite = true);
    std::string family_dir() const;

    // ---- documents: the chain --------------------------------------------------------------------------------------
    std::vector<SoundChainStep> chain() const;
    SoundEditOutcome add_step(const std::string& type, int index = -1, const Json& fields = Json::object());
    SoundEditOutcome remove_step(int index);
    SoundEditOutcome move_step(int index, int to);
    SoundEditOutcome set_step(int index, const Json& values, const std::string& label = "");
    SoundEditOutcome set_step_enabled(int index, bool enabled);
    void preview_step(int index, const Json& values);  // the same, in memory only (a slider drag)
    SoundEditOutcome commit_step(const std::string& label = "");
    void cancel_step_preview();
    SoundEditOutcome set_document(const Json& values);  // source / seed / output (audio.edit document)
    // ---- documents: loop points -------------------------------------------------------------------------------------
    // The loop of the rendered sound in seconds (the drag preview when there is one); nothing when the sound does not loop.
    std::optional<std::pair<double, double>> loop_seconds() const;
    int loop_step() const;  // index of the `loop` step, -1 when there is none
    double loop_crossfade() const;
    // Drags: the markers move on the waveform at once; commit_loop writes the loop step's start / end (output end + crossfade).
    void preview_loop(double startSeconds, double endSeconds);
    bool loop_previewing() const { return loopPreview_.has_value(); }
    SoundEditOutcome commit_loop();
    void cancel_loop_preview() { loopPreview_.reset(); }
    // The loop points of a plain sound as its import settings say (assets.json loopStart / loopEnd), read-only here.
    std::optional<std::pair<double, double>> import_loop() const;

    // ---- files ------------------------------------------------------------------------------------------------------
    // A plain .wav/.ogg becomes <name>.audio.json (audio.create; the document's output is <name>_edit.wav so the original is never
    // overwritten). The new document is the one that is open afterwards.
    SoundEditOutcome make_document();
    // Bakes the sound next to the patch (sfx.render, with the variants when it declares some) or the document (audio.bake).
    SoundEditOutcome save();
    void set_overwrite_on_save(bool on) { overwriteOnSave_ = on; }  // replace a baked file that nothing of ours made

    // ---- undo -------------------------------------------------------------------------------------------------------
    const SoundStep* step(int id) const;
    bool apply_step(int id, bool forward);
    void retain_steps(const std::set<int>& keep);
    void drop_step(int id) { steps_.erase(id); }
    std::size_t step_count() const { return steps_.size(); }
    std::string step_document(int id) const;

private:
    bool load_from_disk();
    SoundSpec main_spec() const;
    std::string key_of(const SoundSpec& spec) const;
    void start_job(const std::string& key, SoundSpec spec);
    void collect();
    bool want_more();
    // Runs a command body as ONE undo step: the files it changed (the open file, assets.json when `manifest`, everything under `scanDir`).
    SoundEditOutcome run(const std::string& label, const std::function<CommandResult()>& body,
                         const std::string& scanDir = "", bool manifest = false);
    SoundBlob blob_of(const std::string& rel);
    SoundFileSet capture(const std::set<std::string>& paths);
    bool restore(const SoundFileSet& files);
    std::uint64_t compute_stamp() const;
    SoundEditOutcome fail(SoundEditOutcome out, const std::string& message);
    void apply_loaded_text(const std::string& text);
    Json step_target() const;

    std::string projectDir_;
    SoundCommandFn call_;
    SoundKind kind_ = SoundKind::None;
    std::string rel_, error_, status_, renderError_;
    bool valid_ = false;
    Json json_;
    std::string text_;
    std::uint64_t docRev_ = 0;
    std::uint64_t stamp_ = 0;
    std::map<std::string, SoundBlob> fileCache_;
    std::map<int, SoundStep> steps_;
    int nextStep_ = 1;

    // rendering
    bool async_ = true;
    int debounce_ = 4;
    int wait_ = 0;
    bool dirty_ = false;
    std::uint64_t seed_ = 0;
    int stopAfter_ = -1;
    int renders_ = 0;
    double renderMs_ = 0;
    std::uint64_t nextRenderId_ = 1;
    struct Entry {
        std::uint64_t rev = 0;
        SoundRenderPtr render;
        std::string error;
    };
    std::map<std::string, Entry> results_;     // by key_of(spec)
    std::string mainKey_;                      // the key of what the main view should show
    std::map<std::string, SoundSpec> extras_;  // the other renders asked for (variants, the sound before the loop step)
    SoundRenderPtr current_, before_;
    std::optional<SfxPatch> patch_;
    std::optional<AudioDoc> doc_;
    bool jsonPreview_ = false;
    bool overwriteOnSave_ = false;
    SoundRenderPtr baked_;
    std::uint64_t bakedStamp_ = ~0ULL;
    struct Running {
        std::future<std::pair<SoundRenderPtr, std::string>> future;
        std::string key;
        std::uint64_t rev = 0;
        double startedMs = 0;
        bool valid = false;
    } running_;

    // previews
    std::map<std::string, double> macroPreview_;
    std::string fieldPreviewPointer_;
    Json fieldPreviewValue_, previewJson_;
    int stepPreviewIndex_ = -1;
    Json stepPreviewValues_;
    std::optional<std::pair<double, double>> loopPreview_;
};

}  // namespace fa::editor
