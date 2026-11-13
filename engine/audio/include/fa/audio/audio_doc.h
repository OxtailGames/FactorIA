// Audio documents (`*.audio.json`, format "factoria.audio/1", schemas/audio.schema.json, docs/SOUND.md "Audio documents"): a
// non-destructive chain of steps over a sound, so an imported CC0 recording or a rendered synth patch becomes a source you can
// keep editing instead of a file you destroyed. The document names a source (a WAV or OGG, an `.sfx.json` patch, or another
// audio document) and a list of steps (trim, fade, normalize, gain, pitch, stretch, speed, eq, compressor, reverb, delay, reverse,
// layer, loop, granular); rendering applies them in order, offline, and bake writes the result next to the document as a WAV or OGG
// (tools/common: audio.render, audio.bake).
//
// Determinism. The same document and the same source files give the same samples, bit for bit, on every platform: the work is
// done in `double` with + - * / and sqrt only plus the synth's own sine, exp2 and log2 (sfx_math.h), never the C library's
// transcendentals; the build disables floating-point contraction; the random numbers (granular, an `.sfx.json` source) come from
// splitmix64 seeded from the document's `seed`, the step's position and its own `seed`. Time stretching is WSOLA and the resampler a
// windowed sinc, both written here.
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/audio/sfx.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr const char* kAudioDocFormat = "factoria.audio/1";
inline constexpr const char* kAudioDocSuffix = ".audio.json";
inline constexpr std::size_t kAudioDocMaxSteps = 64;
inline constexpr double kAudioDocMaxSeconds = 120.0;  // the longest buffer any step may make

// One problem of a document: where (a JSON pointer such as "/steps/2/semitones"), what is wrong, and how to fix it.
using AudioDocIssue = SfxIssue;

// One field of a step, as the catalog lists it (and as the parser checks it).
struct AudioFieldInfo {
    std::string key;
    std::string
        type;  // "number", "integer", "boolean", "string" (a choice when `choices` is not empty), "bands" or "path"
    std::string doc;
    bool required = false;
    std::optional<double> min, max;
    std::optional<Json> def;  // the default, absent for a field without one
    std::vector<std::string> choices;
};
struct AudioStepInfo {
    std::string type;
    std::string doc;  // what the step does, one paragraph
    std::vector<AudioFieldInfo> fields;
};
// Every step type the format knows, in the order the docs describe them.
const std::vector<AudioStepInfo>& audio_step_types();

// The effect steps (eq, filter, compressor, distortion, bitcrush, delay, reverb): the ones that process a sound in place without needing a
// source, so a song's mixer (song.h) can run the same steps on a track, a bus or the master.
bool audio_step_is_effect(std::string_view type);

// Where the sound comes from: a file of the project (.wav, .ogg, .mp3, .qoa), a sound patch (.sfx.json, rendered with `seed` and,
// when `note` is given, transposed to that note) or another audio document.
struct AudioSourceRef {
    std::string path;
    std::uint64_t seed = 0;    // sfx patches: added to the patch's seed
    std::optional<double> hz;  // sfx patches: transpose so the patch's root pitch becomes this
    std::string note;          // the note as written, for messages
};

struct AudioStep {
    std::string type;
    Json params;  // every field of the step with its default filled in; validated
};

struct AudioOutput {
    std::string format = "wav";       // "wav" (16-bit PCM) or "ogg" (the engine's Vorbis encoder)
    std::string channels = "source";  // "source": as many as the source has; "mono": mixed down to one
    double quality = 0.5;             // ogg: 0..1
    std::string
        path;  // where bake writes (project-relative); empty = next to the document, with the format's extension
};

struct AudioDoc {
    std::string doc;
    AudioSourceRef source;
    std::uint64_t seed = 0;
    AudioOutput output;
    std::vector<AudioStep> steps;
};

// Reads a document. Every problem found is listed in `issues` (not only the first), each with its JSON pointer, what is wrong and
// the fix, and "did you mean" for names. `file` only names the document in the message of the error that is returned for the first.
Result<AudioDoc> parse_audio_doc(const Json& json, std::string_view file = {},
                                 std::vector<AudioDocIssue>* issues = nullptr);
// parse_audio_doc of a file read through the VFS (project-relative).
Result<AudioDoc> load_audio_doc(std::string_view path, std::vector<AudioDocIssue>* issues = nullptr);

// Reads one step on its own (the object of `steps[i]`), with `pointer` as the base of the issues' JSON pointers. Every problem is added to
// `issues`; the error returned is the first one. Used by the song document for the effects of a track.
Result<AudioStep> parse_audio_step(const Json& json, std::string_view pointer,
                                   std::vector<AudioDocIssue>* issues = nullptr);
// Runs an effect step (audio_step_is_effect) over the channels in place, without changing their length: a reverb or delay tail is cut
// where the buffer ends, so leave room for it. `rate` in Hz. An enabled:false step does nothing.
void audio_apply_effect(std::vector<std::vector<double>>& channels, int rate, const AudioStep& step);

// Loop points of a rendered sound: frames of the output where playback wraps (end exclusive).
struct AudioLoop {
    std::size_t start = 0, end = 0;
};

// A rendered sound: interleaved float frames (1 or 2 channels), what it measures, the loop points when a `loop` step made some, and
// what each step did.
struct AudioStepReport {
    std::string type;
    double seconds = 0.0;    // length after the step
    double peakDb = -200.0;  // sample peak after the step
    bool skipped = false;    // the step has "enabled": false
};
struct AudioClip {
    int sampleRate = 44100;
    int channels = 1;
    std::vector<float> samples;  // frames * channels
    double lufs = -70.0;         // integrated loudness (BS.1770; mono is played on both sides), -70 for silence
    double peakDb = -200.0;      // sample peak in dBFS
    std::optional<AudioLoop> loop;
    std::vector<AudioStepReport> steps;
    std::vector<std::string>
        inputs;  // every project file the render read (sources, patches, nested documents), the document itself excluded
    std::size_t frames() const { return channels > 0 ? samples.size() / std::size_t(channels) : 0; }
    double seconds() const { return sampleRate > 0 ? double(frames()) / double(sampleRate) : 0.0; }
    std::vector<float> mono() const;  // the channels averaged
};

struct AudioRenderOptions {
    std::optional<std::uint64_t> seed;  // replaces the document's seed
    int stopAfter = -1;                 // >= 0: apply only steps 0..stopAfter (to hear the chain up to a step)
};

// Applies the chain. `file` names the document in messages and guards against a document that layers itself. Reads the source and
// every layer through the VFS (project-relative). Failures (a missing file, a sound longer than kAudioDocMaxSeconds, a cycle) teach.
Result<AudioClip> render_audio_doc(const AudioDoc& doc, std::string_view file = {},
                                   const AudioRenderOptions& options = {});

// A 16-bit PCM WAV of the clip (1 or 2 channels), with a `smpl` chunk holding the loop points when it has any.
std::vector<std::uint8_t> audio_wav_bytes(const AudioClip& clip);
// The same as `format` ("wav" or "ogg") says, the output channel choice of `output` applied. Ogg uses output.quality.
Result<std::vector<std::uint8_t>> audio_encode(const AudioClip& clip, const AudioOutput& output);

// ---- the DSP the steps are made of, public so tests (and later the editor) can measure them ---------------------------------
// One channel in, one channel out; all deterministic. `rate` in Hz.

// Changes the duration by `factor` (output length = input * factor) keeping the pitch: WSOLA. The offsets are chosen on the mix of the
// channels and applied to every channel of `x`.
void audio_time_stretch(std::vector<std::vector<double>>& x, int rate, double factor);
// Reads `x` at `step` input samples per output sample (2 plays twice as fast and an octave up) through a windowed sinc; below the new
// Nyquist frequency nothing is lost, above it nothing aliases.
std::vector<double> audio_resample(const std::vector<double>& x, double step);
// The pitch moves by `semitones` and the duration stays.
void audio_pitch_shift(std::vector<std::vector<double>>& x, int rate, double semitones);

}  // namespace fa
