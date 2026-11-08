// Sound patches (`*.sfx.json`, format "factoria.sfx/1", schemas/sfx.schema.json, docs/SOUND.md) and the synthesizer that renders
// them: the engine's own sound design tool (M55.1). A patch is a document an AI can read, diff and edit; this module turns
// it into samples, offline, with no library and no random numbers other than the patch's own seed.
//
// Why it lives in fa_audio and not in the tools: the commands (`sfx.render`, `assets.synth_sound`), the editor's Sound panel
// (M55.4) and the music player (M56: instruments are patches, notes are renders of them, possibly live in a game) all call the
// same functions, and a game ships fa_audio. Everything here needs only fa_core (Json, did_you_mean).
//
// Determinism. The same patch and options give the same samples, bit for bit, on every platform and build type. Rendering is
// done in `double` and uses only + - * / and sqrt (which IEEE 754 rounds identically everywhere) plus its own sine, exp2 and log2
// (sfx_math.h): never the C library's transcendentals, whose last bit differs between glibc, Apple's libm and the MSVC CRT. The
// build disables floating-point contraction (CMakeLists.txt), the noise comes from splitmix64 seeded from the patch's seed, the
// layer index and the oscillator index, and the loudness used to level the sound is measured here (the same BS.1770 as
// measure_loudness, with the same math), so even the normalization gain is identical. The final samples are 32-bit floats.
#pragma once

#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// One problem of a patch: where (a JSON pointer such as "/layers/1/filter/cutoff"), what is wrong, and how to fix it.
struct SfxIssue {
    std::string pointer;
    std::string message;
    std::string hint;
};

enum class SfxWave : std::uint8_t { Sine, Square, Saw, Triangle, Noise, Table };
enum class SfxNoise : std::uint8_t { White, Pink, Brown };
enum class SfxFilterMode : std::uint8_t { LowPass, HighPass, BandPass };
enum class SfxEffectType : std::uint8_t { Filter, Distortion, Bitcrush, Delay, Reverb };
enum class SfxDistortion : std::uint8_t { Soft, Hard, Fold };
enum class SfxNormalizeMode : std::uint8_t { Lufs, Peak, None };

// attack/decay/release in seconds, sustain a level 0..1. `curve` shapes every segment: 1 is a straight line, above 1 the attack
// starts slowly and decay and release fall fast first and slowly at the end, below 1 the opposite.
struct SfxEnvelope {
    double attack = 0.0, decay = 0.0, sustain = 1.0, release = 0.0, curve = 1.0;
    // The level 0..1 at `t` seconds after the note started, for a note held `gate` seconds (the release starts at the gate).
    double level(double t, double gate) const;
};

// An envelope that moves something by `amount` (semitones for a pitch, octaves for a filter cutoff, 0..1 of the index for FM).
struct SfxModulation {
    bool enabled = false;
    double amount = 0.0;
    SfxEnvelope env;
};

struct SfxFm {
    bool enabled = false;
    double ratio = 1.0;          // modulator frequency = ratio * the oscillator's frequency ...
    double hz = 0.0;             // ... or this fixed frequency when > 0
    double index = 1.0;          // peak phase deviation in radians
    SfxWave wave = SfxWave::Sine;
    bool hasIndexEnv = false;    // the index follows `indexEnv` (a bell's brightness dying away) instead of staying put
    SfxEnvelope indexEnv;
};

struct SfxRing {
    bool enabled = false;
    double ratio = 1.0;
    double hz = 0.0;
    double mix = 1.0;            // 0 = no effect, 1 = full ring modulation
    SfxWave wave = SfxWave::Sine;
};

struct SfxOscillator {
    SfxWave wave = SfxWave::Sine;
    double duty = 0.5;                // Square: share of the cycle that is high
    SfxNoise noise = SfxNoise::White; // Noise
    std::vector<double> table;        // Table: one cycle, -1..1, read with linear interpolation
    double ratio = 1.0;               // multiple of the layer's pitch
    double detune = 0.0;              // cents
    double freq = 0.0;                // > 0: a fixed frequency in Hz that ignores the layer's pitch
    double gain = 1.0;
    double phase = 0.0;               // starting phase, 0..1 of a cycle
    SfxFm fm;
    SfxRing ring;
};

struct SfxFilter {
    bool enabled = false;
    SfxFilterMode mode = SfxFilterMode::LowPass;
    double cutoff = 1000.0;           // Hz
    double resonance = 0.707;         // Q
    double cutoffTo = 0.0;            // effects only: > 0 slides the cutoff to this over the whole sound (exponentially)
    SfxModulation env;                // layer filters only: amount in octaves
    double keytrack = 0.0;            // layer filters only, 0..1: how much of a transposed note's pitch ratio the cutoff follows (1: fully)
};

struct SfxEffect {
    SfxEffectType type = SfxEffectType::Filter;
    bool enabled = true;
    double mix = 1.0;
    SfxFilter filter;                 // Filter
    SfxDistortion shape = SfxDistortion::Soft;
    double drive = 4.0, level = 1.0;  // Distortion
    double bits = 8.0, rate = 0.0;    // Bitcrush: rate 0 = the patch's sample rate
    double time = 0.25, feedback = 0.4, tone = 0.0;  // Delay (tone > 0: a low-pass in the feedback, Hz)
    double decay = 1.0, damping = 0.5, size = 1.0, preDelay = 0.0;  // Reverb
};

struct SfxPitch {
    double freq = 440.0;              // Hz (a `note` name is converted)
    bool sweep = false;
    double sweepSemitones = 0.0;      // where the sweep ends, relative to freq
    double sweepTime = 0.0;           // 0 = the layer's length
    double sweepCurve = 1.0;
    SfxModulation env;                // amount in semitones
    double vibratoRate = 0.0, vibratoDepth = 0.0, vibratoDelay = 0.0;  // Hz, cents, seconds
    std::vector<double> arpSteps;     // semitones
    double arpRate = 12.0;            // steps per second
    bool arpLoop = true;              // false: stay on the last step
};

struct SfxLayer {
    std::string name;
    double start = 0.0;               // seconds from the start of the sound
    double length = 0.0;              // gate in seconds; 0 = until the end of the patch's length
    double gain = 1.0;
    std::vector<SfxOscillator> oscillators;
    SfxPitch pitch;
    SfxEnvelope amp{0.002, 0.0, 1.0, 0.01, 1.0};
    double tremoloRate = 0.0, tremoloDepth = 0.0;
    SfxFilter filter;
    std::vector<SfxEffect> effects;
};

struct SfxNormalize {
    SfxNormalizeMode mode = SfxNormalizeMode::Lufs;
    double target = -18.0;            // LUFS (mode lufs) or peak dBFS (mode peak)
    double ceilingDb = -1.0;          // the loudest sample stays under this (mode lufs)
};

// ---- macros and variations (M55.2) -------------------------------------------------------------------------------------------
// A macro is a knob from -1 to 1 that moves several parameters of a patch by meaning. Six are built in (sfx_macros()); a patch
// can also declare its own, each bound to numbers of the patch by JSON pointer.
struct SfxMacroBind {
    std::string pointer;              // JSON pointer of a number in the patch, e.g. "/layers/0/filter/cutoff"
    double atMin = 0.0, atMax = 0.0;  // the value the number takes with the macro at -1 and at +1
    bool exponential = false;         // interpolate on a log scale (cutoffs, times): both ends must be above 0
};
struct SfxMacroDef {
    std::string name;
    double value = 0.0;               // -1..1, 0 = the patch as written
    double strength = 1.0;            // built-in macros: how far the knob moves things (0..3, default 1)
    std::string doc;
    std::vector<SfxMacroBind> binds;  // numbers of the patch this macro sets (apply them with sfx_apply_macro_binds)
    bool builtin = false;
};
struct SfxMacroInfo {
    std::string name;
    std::string what;                 // what turning it up and down does
};
const std::vector<SfxMacroInfo>& sfx_macros();

// `variations`: N takes of one patch for sounds that must not repeat. Variant i draws its offsets from the patch's variation seed
// and i, so the same patch always gives the same N sounds. Each spread is the largest offset in either direction.
struct SfxVariations {
    int count = 0;                    // 0 = the patch declares none
    std::uint64_t seed = 0;
    double pitchCents = 25.0;         // +/- cents
    double lengthFraction = 0.05;     // +/- share of the length
    double gainDb = 1.0;              // +/- dB after normalization
    double filterOctaves = 0.15;      // +/- octaves on every filter cutoff
    bool noise = true;                // each variant takes another take of the noise
};
struct SfxVariantParams {
    double pitchCents = 0.0, lengthScale = 1.0, gainDb = 0.0, filterOctaves = 0.0;
    std::uint64_t seedOffset = 0;
};
// The offsets of variant `index` (0-based, below variations.count). Deterministic.
SfxVariantParams sfx_variant_params(const SfxVariations& variations, int index);
// "assets/sfx/step.wav" -> "assets/sfx/step_03.wav" for variant 3 (1-based) of `count`: two digits, more for 100 or more. The one
// naming scheme of baked variants, used by sfx.bake and by AudioSource.variants.
std::string sfx_variant_path(std::string_view clip, int variant, int count);

struct SfxPatch {
    std::string doc;
    int sampleRate = 44100;
    double length = 0.5;              // seconds the note is held (layers without their own length gate this long)
    double tail = 0.0;                // seconds after it for releases, delays and reverbs to die away
    std::uint64_t seed = 0;
    double fadeOut = 0.003;           // seconds: the last stretch of the sound fades to silence so it never ends in a click
    std::vector<SfxLayer> layers;
    std::vector<SfxEffect> effects;   // master chain, after the layers are mixed
    double gain = 1.0;                // master gain before the effects
    SfxNormalize normalize;
    Json macros;                      // the `macros` object as written
    std::vector<SfxMacroDef> macroDefs;  // parsed from `macros`
    SfxVariations variations;

    // The declared value of a macro (0 when not declared).
    double macro_value(std::string_view name) const;

    // The frequency the patch is tuned to: the base pitch of its first layer with a pitched oscillator (A4 = 440 Hz if none).
    double root_hz() const;
};

// What changes in one render without editing the patch. Defaults render the patch exactly as written.
struct SfxRenderOptions {
    std::uint64_t seed = 0;           // added to the patch's seed: another take of every noise
    double freqHz = 0.0;              // > 0: transposes the patch so its root_hz() becomes this (fixed-frequency oscillators stay)
    double length = -1.0;             // >= 0: replaces the patch's length (seconds held)
    double tail = -1.0;               // >= 0: replaces the patch's tail
    double velocity = 1.0;            // linear gain applied after normalization
    std::optional<SfxNormalize> normalize;  // replaces the patch's normalization (instruments use mode None)
    std::map<std::string, double> macros;   // built-in macro values (-1..1) that replace the ones the patch declares
    int variant = -1;                 // >= 0: render variant `variant` (0-based) of patch.variations
};

struct SfxAudio {
    int sampleRate = 44100;
    std::vector<float> samples;       // mono
    double lufs = -70.0;              // integrated loudness of `samples` (BS.1770, mono played on both sides), -70 for silence
    double peakDb = -200.0;           // sample peak in dBFS
    double seconds() const { return sampleRate > 0 ? double(samples.size()) / double(sampleRate) : 0.0; }
};

// Reads a patch. Every problem found is listed in `issues` (not only the first), each with its JSON pointer, the problem and the
// fix, and "did you mean" for names. `file` only names the source in the message of the error that is returned for the first one.
Result<SfxPatch> parse_sfx(const Json& json, std::string_view file = {}, std::vector<SfxIssue>* issues = nullptr);
// parse_sfx of a file read through the VFS (project-relative).
Result<SfxPatch> load_sfx(std::string_view path, std::vector<SfxIssue>* issues = nullptr);

// Renders a patch: (length + tail) * sampleRate samples. Deterministic (see above). The only failure is a sound longer than
// kSfxMaxSeconds.
Result<SfxAudio> render_sfx(const SfxPatch& patch, const SfxRenderOptions& options = {});

// Sets the numbers the macro binds of `parsed` point at, for the declared macro values replaced by `overrides`, in a copy of the
// patch JSON. Parse the result again with parse_sfx (it checks the ranges). An unresolvable pointer is an error.
Result<Json> sfx_apply_macro_binds(const Json& patchJson, const SfxPatch& parsed, const std::map<std::string, double>& overrides);

// Measurements of a rendered sound: the spectral centroid in Hz (the "brightness": where the energy sits, weighted over time)
// and the seconds it takes to reach 90 percent of its peak level (how fast the attack is).
double sfx_centroid_hz(const SfxAudio& audio);
double sfx_rise_seconds(const SfxAudio& audio);

// Makes the patch `factor` times as long (0.5 = twice as fast): the length and tail, every layer's start and length, all
// envelope times, pitch sweeps, arpeggio speed, vibrato delay and the delay time. Rates that are pitch-like (vibrato and
// tremolo speed, filter cutoffs, FM) stay, so a stretched sound keeps its character. `factor` must be above 0.
void stretch_sfx(SfxPatch& patch, double factor);

// The synth's own building blocks, for the audio documents (audio_doc.h) that run the same effects and the same loudness measure:
// `effects` (filter, distortion, bitcrush, delay, reverb) in order over one channel of samples in place, and the BS.1770 integrated
// loudness (-70 for silence) and sample peak (linear) of one channel (played on both sides) or two (left and right), all the same length.
void sfx_run_effects(std::vector<double>& buf, const std::vector<SfxEffect>& effects, int rate);
void sfx_measure_loudness(const std::vector<std::vector<double>>& channels, int rate, double& lufs, double& peak);

// A 16-bit PCM mono WAV file of the audio.
std::vector<std::uint8_t> sfx_wav_bytes(const SfxAudio& audio);

inline constexpr double kSfxMaxSeconds = 30.0;

// render_sfx renders the layers of a patch as jobs (fa::jobs, only while the pool runs) when the patch has at least two layers
// and at least kSfxJobMinSamples samples (a sound of about half a second at 48 kHz), and the layers' buffers together fit
// kSfxJobBufferBytes; otherwise they render one after the other. The samples are the same either way. Neither the device
// callback nor anything else on the audio thread ever waits for a job: only offline renders (sfx.render, previews, builds).
inline constexpr std::size_t kSfxJobMinSamples = 24000;
inline constexpr double kSfxJobBufferBytes = 256.0 * 1024.0 * 1024.0;

// The notes of a name like "A4", "C#3", "Bb2" (C4 = middle C = MIDI 60, A4 = 440 Hz) as a frequency; nothing for other text.
std::optional<double> sfx_note_hz(std::string_view note);

// ---- presets -----------------------------------------------------------------------------------------------------------
// The sounds of `assets.synth_sound`, as patches an AI can open and change.
struct SfxPresetInfo {
    std::string name;
    std::string what;                 // one line: "a dog bark: two short rough barks"
};
const std::vector<SfxPresetInfo>& sfx_presets();
// The patch of a preset; nothing for an unknown name.
std::optional<Json> sfx_preset_patch(std::string_view name);

}  // namespace fa
