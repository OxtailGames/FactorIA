// The built-in instruments and drum kits of the song renderer (fa/audio/song_instruments.h), as the JSON of sound patches.
//
// Conventions. Every pitched patch is tuned to C4 (the song renderer transposes it to the note with the synth's own oscillators, so
// a note is synthesized at its pitch, not resampled), has `normalize` none so the levels are the ones written here, and a `tail` long
// enough for its release. The table gives each patch a master `gain` measured so its C4 note, played at velocity 100, peaks about
// -12 dBFS (the test "instruments: every instrument sits at its calibrated level" fails when a patch is edited without re-measuring);
// the kit lanes carry gains of their own. A filter that should follow the pitch has `keytrack`. Drum patches are one-shots: the renderer
// plays them as written.
#include <algorithm>
#include <string>
#include <string_view>

#include "fa/audio/song_instruments.h"

namespace fa {

namespace {

struct Entry {
    const char* name;
    const char* family;
    const char* what;
    int low, high;
    int voices;
    double gain;
    const char* body;  // the patch without "format", "gain" and "master"
};

// ---- pitched instruments ------------------------------------------------------------------------------------------------------

const Entry kPitched[] = {
    // keys
    {"keys", "keys",
     "electric-piano keys: a soft tone with a bright tine that decays by itself; chords, comping, melodies", 33, 96, 16,
     0.4032,
     R"J({"doc": "Keys: a soft electric-piano-like tone that decays by itself.", "length": 0.6, "tail": 0.6,
  "layers": [
    {"name": "body", "gain": 0.5, "pitch": {"note": "C4"},
     "oscillators": [{"wave": "triangle"}, {"wave": "sine", "ratio": 2, "gain": 0.35}, {"wave": "sine", "ratio": 3, "gain": 0.12}],
     "filter": {"mode": "lowpass", "cutoff": 3500, "keytrack": 0.5, "env": {"amount": 1.2, "attack": 0.001, "decay": 0.4, "sustain": 0}},
     "amp": {"attack": 0.003, "decay": 1.4, "sustain": 0, "release": 0.25, "curve": 2.2}},
    {"name": "tine", "gain": 0.25, "pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine", "ratio": 4, "fm": {"ratio": 1, "index": 1.5, "indexEnv": {"attack": 0, "decay": 0.15, "sustain": 0}}}],
     "amp": {"attack": 0.001, "decay": 0.25, "sustain": 0, "release": 0.1, "curve": 2}}]})J"},
    {"piano", "keys",
     "an acoustic-piano-like tone: a hammer thump, bright partials that die before the fundamental; chords, melodies, "
     "ballads",
     21, 108, 24, 0.1371,
     R"J({"doc": "Piano: detuned strings with a hammer thump; the upper partials fade first and the note rings down.", "length": 0.8, "tail": 0.8,
  "layers": [
    {"name": "strings", "pitch": {"note": "C4"},
     "oscillators": [{"wave": "triangle", "detune": -3}, {"wave": "triangle", "detune": 3}, {"wave": "sine", "ratio": 2, "gain": 0.4}, {"wave": "sine", "ratio": 3, "gain": 0.22},
                     {"wave": "sine", "ratio": 4, "gain": 0.12}, {"wave": "sine", "ratio": 5, "gain": 0.06}],
     "filter": {"mode": "lowpass", "cutoff": 2600, "keytrack": 0.7, "env": {"amount": 1.6, "attack": 0.001, "decay": 0.35, "sustain": 0}},
     "amp": {"attack": 0.002, "decay": 2.6, "sustain": 0, "release": 0.3, "curve": 2.6}},
    {"name": "hammer", "gain": 0.12, "length": 0.03, "pitch": {"note": "C4"},
     "oscillators": [{"wave": "noise", "color": "pink"}],
     "filter": {"mode": "bandpass", "cutoff": 1800, "resonance": 0.9, "keytrack": 0.5},
     "amp": {"attack": 0, "decay": 0.03, "sustain": 0, "release": 0.005, "curve": 2}}]})J"},
    {"epiano", "keys",
     "a tine electric piano (FM): a warm bell-like attack that mellows; comping, soft chords, jazz and pop", 28, 96, 16,
     0.1829,
     R"J({"doc": "Electric piano: an FM sine with a decaying modulation, so each note starts bright and settles to a round tone.", "length": 0.7, "tail": 0.7,
  "layers": [
    {"name": "tone", "pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine", "fm": {"ratio": 1, "index": 1.1, "indexEnv": {"attack": 0, "decay": 0.9, "sustain": 0.15, "curve": 1.6}}}, {"wave": "sine", "ratio": 2, "gain": 0.15}],
     "amp": {"attack": 0.002, "decay": 2.0, "sustain": 0, "release": 0.25, "curve": 2.2}},
    {"name": "bark", "gain": 0.3, "pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine", "ratio": 14, "fm": {"ratio": 1, "index": 0.8, "indexEnv": {"attack": 0, "decay": 0.06, "sustain": 0}}}],
     "amp": {"attack": 0.001, "decay": 0.08, "sustain": 0, "release": 0.03, "curve": 2}}]})J"},
    {"clav", "keys",
     "a clavinet: a plucked, funky square-ish tone with a sharp attack and a fast decay; rhythmic chords and riffs", 36,
     88, 12, 0.1306,
     R"J({"doc": "Clavinet: a narrow pulse through a fast-closing filter, short and percussive.", "length": 0.3, "tail": 0.25,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "square", "duty": 0.3}, {"wave": "saw", "gain": 0.3, "ratio": 2}],
     "filter": {"mode": "lowpass", "cutoff": 1500, "resonance": 1.4, "keytrack": 0.8, "env": {"amount": 2.4, "attack": 0.001, "decay": 0.12, "sustain": 0}},
     "amp": {"attack": 0.001, "decay": 0.35, "sustain": 0.0, "release": 0.08, "curve": 2}}]})J"},
    {"organ", "keys", "a drawbar organ: stacked sines, steady level, no decay; sustained chords and held notes", 36, 96,
     16, 0.128,
     R"J({"doc": "Organ: sines at the octave harmonics, an even level while held.", "length": 0.8, "tail": 0.15,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine"}, {"wave": "sine", "ratio": 2, "gain": 0.7}, {"wave": "sine", "ratio": 3, "gain": 0.4}, {"wave": "sine", "ratio": 4, "gain": 0.3},
                     {"wave": "sine", "ratio": 0.5, "gain": 0.5}],
     "tremolo": {"rate": 5.5, "depth": 0.08},
     "amp": {"attack": 0.008, "decay": 0.0, "sustain": 1.0, "release": 0.08, "curve": 1}}]})J"},

    // plucks
    {"pluck", "pluck", "a plucked string, bright then mellow as it dies; arpeggios, melodies, guitar-like parts", 40,
     88, 12, 0.2855,
     R"J({"doc": "Pluck: a plucked string, bright at the start and mellow as it dies.", "length": 0.5, "tail": 0.4,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw", "gain": 0.7}, {"wave": "triangle", "ratio": 2, "gain": 0.25}],
     "filter": {"mode": "lowpass", "cutoff": 1800, "resonance": 1.0, "keytrack": 0.6, "env": {"amount": 2.2, "attack": 0.001, "decay": 0.3, "sustain": 0}},
     "amp": {"attack": 0.002, "decay": 0.9, "sustain": 0, "release": 0.12, "curve": 2}}]})J"},
    {"pluck_soft", "pluck", "a soft, round pluck with little attack noise; background arpeggios and gentle melodies",
     40, 96, 12, 0.2524,
     R"J({"doc": "Soft pluck: a triangle and a sine through a gentle low-pass, quick to fade.", "length": 0.4, "tail": 0.3,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "triangle"}, {"wave": "sine", "ratio": 2, "gain": 0.3}],
     "filter": {"mode": "lowpass", "cutoff": 2200, "keytrack": 0.6, "env": {"amount": 1.0, "attack": 0.001, "decay": 0.2, "sustain": 0}},
     "amp": {"attack": 0.003, "decay": 0.7, "sustain": 0, "release": 0.1, "curve": 2}}]})J"},
    {"pluck_bright", "pluck",
     "a hard, glassy pluck with a lot of top end; fast arpeggios and sequences that must cut through", 45, 100, 12,
     0.1552,
     R"J({"doc": "Bright pluck: a square and a saw with an open, fast filter envelope.", "length": 0.35, "tail": 0.25,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "square", "duty": 0.4}, {"wave": "saw", "detune": 6, "gain": 0.5}],
     "filter": {"mode": "lowpass", "cutoff": 3500, "resonance": 1.2, "keytrack": 0.8, "env": {"amount": 1.6, "attack": 0.001, "decay": 0.12, "sustain": 0}},
     "amp": {"attack": 0.001, "decay": 0.45, "sustain": 0, "release": 0.08, "curve": 2.2}}]})J"},
    {"guitar", "pluck", "a nylon-string guitar: a warm pluck with a body resonance; arpeggios and strummed chords", 40,
     84, 6, 0.3062,
     R"J({"doc": "Guitar: a plucked tone with the body's low resonance under it and a short pick transient.", "length": 0.5, "tail": 0.5,
  "layers": [
    {"name": "string", "pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw", "gain": 0.6}, {"wave": "triangle", "gain": 0.5}, {"wave": "sine", "ratio": 2, "gain": 0.2}],
     "filter": {"mode": "lowpass", "cutoff": 1500, "resonance": 1.1, "keytrack": 0.7, "env": {"amount": 1.8, "attack": 0.001, "decay": 0.25, "sustain": 0}},
     "amp": {"attack": 0.002, "decay": 1.3, "sustain": 0, "release": 0.2, "curve": 2.2}},
    {"name": "pick", "gain": 0.08, "length": 0.02, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 2500, "resonance": 0.8},
     "amp": {"attack": 0, "decay": 0.02, "sustain": 0, "release": 0.005, "curve": 2}}]})J"},
    {"harp", "pluck",
     "a harp: a clear, ringing pluck that sustains softly; glissandi, arpeggios, fairy-tale and lullaby parts", 24, 103,
     24, 0.2705,
     R"J({"doc": "Harp: a pure triangle with a few harmonics, a soft attack and a long, even ring.", "length": 0.6, "tail": 1.0,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "triangle"}, {"wave": "sine", "ratio": 2, "gain": 0.3}, {"wave": "sine", "ratio": 3, "gain": 0.12}],
     "filter": {"mode": "lowpass", "cutoff": 4000, "keytrack": 0.5, "env": {"amount": 0.8, "attack": 0.001, "decay": 0.3, "sustain": 0}},
     "amp": {"attack": 0.002, "decay": 2.2, "sustain": 0, "release": 0.3, "curve": 2.4}}]})J"},

    // bass
    {"bass", "bass", "a round synth bass: a saw over a sine an octave down, with a short punch", 28, 64, 4, 0.1386,
     R"J({"doc": "Bass: a saw over a sine an octave below, filtered, with a short punch.", "length": 0.5, "tail": 0.2,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw", "gain": 0.55}, {"wave": "square", "gain": 0.25, "duty": 0.4, "detune": 6}, {"wave": "sine", "ratio": 0.5, "gain": 0.9}],
     "filter": {"mode": "lowpass", "cutoff": 700, "resonance": 1.2, "keytrack": 0.5, "env": {"amount": 1.5, "attack": 0.001, "decay": 0.18, "sustain": 0.2}},
     "amp": {"attack": 0.004, "decay": 0.25, "sustain": 0.75, "release": 0.12, "curve": 1.5}}]})J"},
    {"bass_sub", "bass",
     "a pure sub bass: a sine with a hint of the second harmonic; felt more than heard, under everything", 24, 60, 2,
     0.2466,
     R"J({"doc": "Sub bass: a sine and a quiet octave above, a clean low end.", "length": 0.5, "tail": 0.15,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine"}, {"wave": "triangle", "ratio": 2, "gain": 0.15}],
     "amp": {"attack": 0.006, "decay": 0.1, "sustain": 0.9, "release": 0.1, "curve": 1.3}}]})J"},
    {"bass_pluck", "bass", "a plucked, punchy bass that dies away between notes; funk, pop and walking lines", 28, 67,
     4, 0.1607,
     R"J({"doc": "Plucked bass: a saw and a square through a quick-closing low-pass, a round thump.", "length": 0.4, "tail": 0.25,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw", "gain": 0.6}, {"wave": "sine", "ratio": 0.5, "gain": 0.8}],
     "filter": {"mode": "lowpass", "cutoff": 500, "resonance": 1.1, "keytrack": 0.6, "env": {"amount": 2.3, "attack": 0.001, "decay": 0.14, "sustain": 0}},
     "amp": {"attack": 0.002, "decay": 0.5, "sustain": 0.05, "release": 0.1, "curve": 2}}]})J"},
    {"bass_acid", "bass",
     "an acid bass: a resonant saw whose filter snaps open on every note; techno, electro, chase themes", 28, 67, 2,
     0.1014,
     R"J({"doc": "Acid bass: a saw through a very resonant low-pass whose cutoff leaps up and falls back on each note.", "length": 0.3, "tail": 0.15,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw"}],
     "filter": {"mode": "lowpass", "cutoff": 350, "resonance": 7, "keytrack": 0.7, "env": {"amount": 3.0, "attack": 0.001, "decay": 0.22, "sustain": 0.05}},
     "amp": {"attack": 0.002, "decay": 0.3, "sustain": 0.7, "release": 0.07, "curve": 1.4}}]})J"},
    {"bass_fm", "bass",
     "an FM bass: a growling, metallic bite on the attack over a solid sine; electronic and game music", 28, 67, 4,
     0.1517,
     R"J({"doc": "FM bass: a sine whose modulation starts hard and dies down to a clean tone.", "length": 0.4, "tail": 0.2,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine", "fm": {"ratio": 1, "index": 3.2, "indexEnv": {"attack": 0, "decay": 0.25, "sustain": 0.12, "curve": 1.8}}}, {"wave": "sine", "ratio": 0.5, "gain": 0.7}],
     "amp": {"attack": 0.002, "decay": 0.35, "sustain": 0.8, "release": 0.1, "curve": 1.4}}]})J"},
    {"bass_square", "bass", "a hollow square bass; chiptune-adjacent, retro and 8-bit-flavoured songs", 28, 67, 2,
     0.1642,
     R"J({"doc": "Square bass: a 50 percent square softened by a low-pass, a hollow, steady tone.", "length": 0.4, "tail": 0.15,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "square", "duty": 0.5}, {"wave": "sine", "ratio": 0.5, "gain": 0.5}],
     "filter": {"mode": "lowpass", "cutoff": 900, "keytrack": 0.6},
     "amp": {"attack": 0.003, "decay": 0.12, "sustain": 0.8, "release": 0.08, "curve": 1.4}}]})J"},

    // leads
    {"lead", "lead", "a solo synth lead: a hollow square with a delayed vibrato; melodies", 55, 96, 2, 0.1573,
     R"J({"doc": "Lead: a square with a soft detuned double and a vibrato that comes in after the attack.", "length": 0.5, "tail": 0.25,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5.5, "depth": 18, "delay": 0.15}},
     "oscillators": [{"wave": "square", "duty": 0.45}, {"wave": "saw", "detune": 8, "gain": 0.4}],
     "filter": {"mode": "lowpass", "cutoff": 4500, "resonance": 1.0, "keytrack": 0.6},
     "amp": {"attack": 0.01, "decay": 0.15, "sustain": 0.7, "release": 0.15, "curve": 1.3}}]})J"},
    {"lead_saw", "lead", "a bright, wide saw lead (five detuned saws); anthems, trance and big melodies", 55, 100, 2,
     0.0507,
     R"J({"doc": "Saw lead: five slightly detuned saws through a low-pass that follows the pitch, with a late vibrato.", "length": 0.5, "tail": 0.25,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5.2, "depth": 14, "delay": 0.2}},
     "oscillators": [{"wave": "saw", "detune": -14}, {"wave": "saw", "detune": -6}, {"wave": "saw", "detune": 0}, {"wave": "saw", "detune": 6}, {"wave": "saw", "detune": 14}],
     "filter": {"mode": "lowpass", "cutoff": 3800, "resonance": 1.0, "keytrack": 0.8},
     "amp": {"attack": 0.012, "decay": 0.2, "sustain": 0.75, "release": 0.18, "curve": 1.3}}]})J"},
    {"lead_soft", "lead",
     "a soft, singing lead: a triangle and a sine with a gentle vibrato; ballads and calm melodies", 55, 100, 2, 0.2529,
     R"J({"doc": "Soft lead: a triangle with a quiet octave sine and a slow vibrato.", "length": 0.5, "tail": 0.3,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5.0, "depth": 20, "delay": 0.2}},
     "oscillators": [{"wave": "triangle"}, {"wave": "sine", "ratio": 2, "gain": 0.25}],
     "amp": {"attack": 0.03, "decay": 0.1, "sustain": 0.85, "release": 0.2, "curve": 1}}]})J"},
    {"lead_fm", "lead",
     "an FM lead: a glassy, slightly metallic tone that sparkles on the attack; synth-pop and sci-fi melodies", 55, 100,
     2, 0.2518,
     R"J({"doc": "FM lead: a sine with a modulator one octave up whose depth eases off after the attack.", "length": 0.5, "tail": 0.25,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5.5, "depth": 12, "delay": 0.2}},
     "oscillators": [{"wave": "sine", "fm": {"ratio": 2, "index": 2.0, "indexEnv": {"attack": 0.005, "decay": 0.3, "sustain": 0.4, "curve": 1.3}}}],
     "amp": {"attack": 0.008, "decay": 0.15, "sustain": 0.8, "release": 0.15, "curve": 1.2}}]})J"},
    {"lead_acid", "lead", "a squelchy resonant lead; electro, acid and pointed hooks that need attitude", 55, 96, 2,
     0.09465,
     R"J({"doc": "Acid lead: a pulse wave through a resonant low-pass that sweeps open on each note.", "length": 0.4, "tail": 0.2,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "square", "duty": 0.35}, {"wave": "saw", "detune": 5, "gain": 0.5}],
     "filter": {"mode": "lowpass", "cutoff": 1200, "resonance": 5, "keytrack": 0.9, "env": {"amount": 2.0, "attack": 0.002, "decay": 0.25, "sustain": 0.2}},
     "amp": {"attack": 0.004, "decay": 0.2, "sustain": 0.75, "release": 0.12, "curve": 1.3}}]})J"},

    // pads
    {"pad", "pad", "a warm pad: detuned saws that swell in slowly and fade out slowly; sustained chords", 36, 84, 16,
     0.076536,
     R"J({"doc": "Pad: three detuned saws, filtered, a slow swell in and a long release.", "length": 1.0, "tail": 1.2,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw", "detune": -9}, {"wave": "saw", "detune": 0}, {"wave": "saw", "detune": 9}, {"wave": "sine", "ratio": 0.5, "gain": 0.6}],
     "filter": {"mode": "lowpass", "cutoff": 1400, "resonance": 0.9, "keytrack": 0.6},
     "amp": {"attack": 0.35, "decay": 0.3, "sustain": 0.85, "release": 1.0, "curve": 1}}]})J"},
    {"pad_glass", "pad",
     "a bright, airy pad of sine and triangle partials with a shimmer; dreamy, magical or open-sky scenes", 48, 96, 16,
     0.1262,
     R"J({"doc": "Glass pad: sines on the first partials with a slow tremolo, a thin shimmer over the top.", "length": 1.0, "tail": 1.4,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine", "detune": -5}, {"wave": "sine", "detune": 5}, {"wave": "sine", "ratio": 2, "gain": 0.5}, {"wave": "sine", "ratio": 3, "gain": 0.3},
                     {"wave": "triangle", "ratio": 4, "gain": 0.12}],
     "tremolo": {"rate": 4.2, "depth": 0.12},
     "amp": {"attack": 0.5, "decay": 0.3, "sustain": 0.85, "release": 1.2, "curve": 1}}]})J"},
    {"pad_dark", "pad", "a dark, low pad: saws behind a closed low-pass; tension, caves, night and slow drones", 24, 72,
     16, 0.091049,
     R"J({"doc": "Dark pad: detuned saws and a sub sine behind a low cutoff, a slow swell.", "length": 1.0, "tail": 1.4,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw", "detune": -11}, {"wave": "saw", "detune": 11}, {"wave": "sine", "ratio": 0.5, "gain": 0.8}],
     "filter": {"mode": "lowpass", "cutoff": 650, "resonance": 1.0, "keytrack": 0.6},
     "amp": {"attack": 0.6, "decay": 0.3, "sustain": 0.85, "release": 1.3, "curve": 1}}]})J"},
    {"pad_sweep", "pad", "a pad whose filter opens slowly after each chord starts; builds, intros and transitions", 36,
     90, 16, 0.082063,
     R"J({"doc": "Sweep pad: detuned saws whose low-pass opens over a second and a half.", "length": 1.5, "tail": 1.2,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw", "detune": -8}, {"wave": "saw", "detune": 8}, {"wave": "square", "duty": 0.5, "gain": 0.3}],
     "filter": {"mode": "lowpass", "cutoff": 500, "resonance": 1.4, "keytrack": 0.7, "env": {"amount": 2.6, "attack": 1.3, "decay": 0.6, "sustain": 0.6}},
     "amp": {"attack": 0.4, "decay": 0.3, "sustain": 0.9, "release": 1.0, "curve": 1}}]})J"},

    // bells and mallets
    {"bell", "bell", "a bell: FM that starts bright and goes mellow; chimes, high accents", 60, 108, 16, 0.202,
     R"J({"doc": "Bell: a sine with inharmonic FM whose brightness dies away, ringing a long time.", "length": 0.3, "tail": 1.6,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine", "fm": {"ratio": 3.5, "index": 2.5, "indexEnv": {"attack": 0, "decay": 0.8, "sustain": 0.05, "curve": 1.5}}},
                     {"wave": "sine", "ratio": 2.76, "gain": 0.25}],
     "amp": {"attack": 0.001, "decay": 1.8, "sustain": 0, "release": 0.3, "curve": 2}}]})J"},
    {"bell_glass", "bell",
     "a glass chime: pure high partials with a quick shimmer; sparkles, magic and UI-like melodies", 72, 120, 16,
     0.1449,
     R"J({"doc": "Glass bell: sines at inharmonic partials, a thin strike and a long soft ring.", "length": 0.2, "tail": 2.0,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine"}, {"wave": "sine", "ratio": 2.4, "gain": 0.45}, {"wave": "sine", "ratio": 4.1, "gain": 0.3}, {"wave": "sine", "ratio": 5.9, "gain": 0.16}],
     "amp": {"attack": 0.001, "decay": 2.2, "sustain": 0, "release": 0.4, "curve": 2.2}}]})J"},
    {"music_box", "bell", "a music box: tiny plucked metal tines; lullabies and nostalgic or eerie melodies", 72, 108,
     12, 0.1867,
     R"J({"doc": "Music box: a sine with a bright second partial and a quick click, short and delicate.", "length": 0.2, "tail": 0.8,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine"}, {"wave": "sine", "ratio": 4, "gain": 0.3}, {"wave": "sine", "ratio": 6.3, "gain": 0.12}],
     "amp": {"attack": 0.001, "decay": 0.9, "sustain": 0, "release": 0.2, "curve": 2.4}}]})J"},
    {"marimba", "bell",
     "a marimba: a wooden mallet tone with a short, round decay; rhythmic patterns and light melodies", 48, 96, 12,
     0.1915,
     R"J({"doc": "Marimba: a sine with a tuned fourth-octave partial and a mallet knock, dying in half a second.", "length": 0.2, "tail": 0.5,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine"}, {"wave": "sine", "ratio": 4, "gain": 0.35}],
     "amp": {"attack": 0.001, "decay": 0.55, "sustain": 0, "release": 0.1, "curve": 2.4}},
    {"name": "knock", "gain": 0.1, "length": 0.02, "oscillators": [{"wave": "noise", "color": "pink"}], "filter": {"mode": "bandpass", "cutoff": 1200, "resonance": 1.0},
     "amp": {"attack": 0, "decay": 0.02, "sustain": 0, "release": 0.005, "curve": 2}}]})J"},
    {"vibraphone", "bell",
     "a vibraphone: a mellow metal bar with a slow tremolo; jazz, lounge and calm, shimmering textures", 53, 96, 12,
     0.2467,
     R"J({"doc": "Vibraphone: a sine with a soft third partial, a slow tremolo and a long, gentle decay.", "length": 0.4, "tail": 1.2,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine"}, {"wave": "sine", "ratio": 4, "gain": 0.12}],
     "tremolo": {"rate": 4.5, "depth": 0.3},
     "amp": {"attack": 0.002, "decay": 1.8, "sustain": 0, "release": 0.3, "curve": 2}}]})J"},

    // ensembles
    {"strings", "ensemble", "a string section: bright detuned saws with a bowed swell and a gentle vibrato", 36, 88, 16,
     0.1295,
     R"J({"doc": "Strings: detuned saws with a slow bow attack and a delayed vibrato.", "length": 1.0, "tail": 0.6,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5.2, "depth": 14, "delay": 0.3}},
     "oscillators": [{"wave": "saw", "detune": -7}, {"wave": "saw", "detune": 7}, {"wave": "saw", "ratio": 2, "gain": 0.15}],
     "filter": {"mode": "lowpass", "cutoff": 3200, "resonance": 0.8, "keytrack": 0.6},
     "amp": {"attack": 0.18, "decay": 0.2, "sustain": 0.9, "release": 0.45, "curve": 1}}]})J"},
    {"strings_soft", "ensemble",
     "a soft string ensemble: a slower, rounder bow with the edge taken off; underscore and tender passages", 36, 88,
     16, 0.23866,
     R"J({"doc": "Soft strings: detuned triangles and a little saw, a long bow and a warm low-pass.", "length": 1.0, "tail": 0.8,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 4.8, "depth": 12, "delay": 0.4}},
     "oscillators": [{"wave": "saw", "detune": -6, "gain": 0.5}, {"wave": "saw", "detune": 6, "gain": 0.5}, {"wave": "triangle", "gain": 0.6}],
     "filter": {"mode": "lowpass", "cutoff": 1800, "resonance": 0.8, "keytrack": 0.7},
     "amp": {"attack": 0.35, "decay": 0.3, "sustain": 0.9, "release": 0.7, "curve": 1}}]})J"},
    {"brass", "ensemble",
     "a brass section: saws with a swelling filter and a firm attack; fanfares, heroic lines and stabs", 40, 84, 8,
     0.1094,
     R"J({"doc": "Brass: detuned saws whose low-pass opens quickly on the attack, then holds with a touch of vibrato.", "length": 0.6, "tail": 0.3,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5.0, "depth": 8, "delay": 0.35}},
     "oscillators": [{"wave": "saw", "detune": -5}, {"wave": "saw", "detune": 5}, {"wave": "square", "duty": 0.5, "gain": 0.3}],
     "filter": {"mode": "lowpass", "cutoff": 1100, "resonance": 1.0, "keytrack": 0.8, "env": {"amount": 2.0, "attack": 0.07, "decay": 0.2, "sustain": 0.55}},
     "amp": {"attack": 0.05, "decay": 0.15, "sustain": 0.85, "release": 0.18, "curve": 1.2}}]})J"},
    {"horns", "ensemble", "French horns: a round, dark brass with a slow attack; warm harmonic beds and noble themes",
     36, 79, 8, 0.1262,
     R"J({"doc": "Horns: saws and a triangle behind a low cutoff that opens slowly, a soft rounded onset.", "length": 0.8, "tail": 0.4,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 4.8, "depth": 7, "delay": 0.4}},
     "oscillators": [{"wave": "saw", "detune": -4}, {"wave": "saw", "detune": 4}, {"wave": "triangle", "gain": 0.5}],
     "filter": {"mode": "lowpass", "cutoff": 800, "resonance": 0.9, "keytrack": 0.8, "env": {"amount": 1.6, "attack": 0.14, "decay": 0.25, "sustain": 0.6}},
     "amp": {"attack": 0.1, "decay": 0.2, "sustain": 0.9, "release": 0.3, "curve": 1.2}}]})J"},
    {"choir", "ensemble",
     "a vowel choir (\"ah\"): saws through formant filters with a slow swell and vibrato; sacred, epic and ethereal "
     "beds",
     48, 84, 16, 0.27943,
     R"J({"doc": "Choir: a saw run through three formant band-pass filters (an open vowel) with a shared slow vibrato and a gentle swell.", "length": 1.0, "tail": 1.0,
  "layers": [
    {"name": "f1", "gain": 0.7, "pitch": {"note": "C4", "vibrato": {"rate": 5.0, "depth": 18, "delay": 0.3}},
     "oscillators": [{"wave": "saw", "detune": -6}, {"wave": "saw", "detune": 6}],
     "filter": {"mode": "bandpass", "cutoff": 800, "resonance": 3},
     "amp": {"attack": 0.3, "decay": 0.2, "sustain": 0.9, "release": 0.6, "curve": 1}},
    {"name": "f2", "gain": 0.5, "pitch": {"note": "C4", "vibrato": {"rate": 5.0, "depth": 18, "delay": 0.3}},
     "oscillators": [{"wave": "saw", "detune": -6}, {"wave": "saw", "detune": 6}],
     "filter": {"mode": "bandpass", "cutoff": 1200, "resonance": 4},
     "amp": {"attack": 0.3, "decay": 0.2, "sustain": 0.9, "release": 0.6, "curve": 1}},
    {"name": "f3", "gain": 0.3, "pitch": {"note": "C4", "vibrato": {"rate": 5.0, "depth": 18, "delay": 0.3}},
     "oscillators": [{"wave": "saw", "detune": -6}, {"wave": "saw", "detune": 6}],
     "filter": {"mode": "bandpass", "cutoff": 2800, "resonance": 5},
     "amp": {"attack": 0.3, "decay": 0.2, "sustain": 0.9, "release": 0.6, "curve": 1}}]})J"},
    {"flute", "ensemble", "a breathy flute: a soft triangle with a little air; gentle melodies", 60, 96, 1, 0.25,
     R"J({"doc": "Flute: a triangle and a sine with breath noise and a slow vibrato.", "length": 0.6, "tail": 0.25,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5, "depth": 22, "delay": 0.25}},
     "oscillators": [{"wave": "triangle"}, {"wave": "sine", "ratio": 2, "gain": 0.2}],
     "amp": {"attack": 0.07, "decay": 0.1, "sustain": 0.9, "release": 0.18, "curve": 1}},
    {"name": "breath", "gain": 0.04,
     "oscillators": [{"wave": "noise", "color": "pink"}],
     "filter": {"mode": "bandpass", "cutoff": 3000, "resonance": 0.8},
     "amp": {"attack": 0.05, "decay": 0.1, "sustain": 0.5, "release": 0.12, "curve": 1}}]})J"},
    {"clarinet", "ensemble",
     "a clarinet: a hollow, woody tone (odd harmonics) with a soft attack; melodies and folk or classical lines", 50,
     91, 1, 0.1977,
     R"J({"doc": "Clarinet: a square wave (odd harmonics only) softened by a low-pass, with a little breath.", "length": 0.6, "tail": 0.2,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5.0, "depth": 10, "delay": 0.4}},
     "oscillators": [{"wave": "square", "duty": 0.5}, {"wave": "sine", "ratio": 2, "gain": 0.06}],
     "filter": {"mode": "lowpass", "cutoff": 1800, "resonance": 0.9, "keytrack": 0.8},
     "amp": {"attack": 0.04, "decay": 0.1, "sustain": 0.85, "release": 0.12, "curve": 1.1}},
    {"name": "breath", "gain": 0.02, "oscillators": [{"wave": "noise", "color": "pink"}], "filter": {"mode": "bandpass", "cutoff": 2500, "resonance": 0.8},
     "amp": {"attack": 0.03, "decay": 0.1, "sustain": 0.5, "release": 0.1, "curve": 1}}]})J"},
    {"oboe", "ensemble", "an oboe: a nasal, reedy tone; plaintive melodies and pastoral lines", 58, 91, 1, 0.3199,
     R"J({"doc": "Oboe: a saw through a resonant band-pass for the reedy, nasal formant, with vibrato.", "length": 0.6, "tail": 0.2,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5.5, "depth": 14, "delay": 0.3}},
     "oscillators": [{"wave": "saw"}],
     "filter": {"mode": "bandpass", "cutoff": 1500, "resonance": 1.6, "keytrack": 0.6},
     "amp": {"attack": 0.035, "decay": 0.1, "sustain": 0.85, "release": 0.12, "curve": 1.1}}]})J"},

    // chiptune
    {"chiptune", "chiptune",
     "an 8-bit pulse wave: a thin square with a fast decay; melodies and arpeggios in a retro game", 48, 100, 1, 0.1699,
     R"J({"doc": "Chiptune: a 25 percent pulse wave with a short punch, like a console sound chip.", "length": 0.3, "tail": 0.1,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "square", "duty": 0.25}],
     "amp": {"attack": 0.001, "decay": 0.12, "sustain": 0.6, "release": 0.05, "curve": 1.5}}]})J"},
    {"chip_square", "chiptune",
     "an 8-bit square (50 percent duty): the hollowest chip voice; bass lines, rhythm parts and leads", 36, 100, 1,
     0.2514,
     R"J({"doc": "Chip square: a 50 percent pulse with a quick decay to a steady level.", "length": 0.3, "tail": 0.1,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "square", "duty": 0.5}],
     "amp": {"attack": 0.001, "decay": 0.1, "sustain": 0.7, "release": 0.04, "curve": 1.5}}]})J"},
    {"chip_pulse", "chiptune",
     "an 8-bit narrow pulse (12.5 percent duty): the thinnest, buzziest chip voice; leads that must cut through", 48,
     105, 1, 0.1463,
     R"J({"doc": "Chip pulse: a 12.5 percent pulse wave, thin and nasal.", "length": 0.3, "tail": 0.1,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "square", "duty": 0.125}],
     "amp": {"attack": 0.001, "decay": 0.1, "sustain": 0.65, "release": 0.04, "curve": 1.5}}]})J"},
    {"chip_triangle", "chiptune",
     "an 8-bit triangle: a soft, flute-like tone with no decay; bass and soft melodies in the console style", 24, 96, 1,
     0.2524,
     R"J({"doc": "Chip triangle: a plain triangle wave held at an even level, the console bass channel.", "length": 0.3, "tail": 0.05,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "triangle"}],
     "amp": {"attack": 0.001, "decay": 0.0, "sustain": 1.0, "release": 0.02, "curve": 1}}]})J"},
    {"chip_wave", "chiptune",
     "an 8-bit wavetable voice: a 32-step, 4-bit wave (a handheld console's wave channel); pads and warm leads", 36, 96,
     1, 0.2891,
     R"J({"doc": "Chip wave: one 32-step cycle quantized to 16 levels, steady while held.", "length": 0.3, "tail": 0.05,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "table", "table": [0.0, 0.4, 0.73, 0.87, 0.87, 0.73, 0.6, 0.47, 0.47, 0.6, 0.73, 0.6, 0.33, 0.07, -0.2, -0.4,
                                              -0.47, -0.47, -0.4, -0.2, 0.07, 0.33, 0.47, 0.33, 0.07, -0.2, -0.47, -0.73, -0.87, -0.87, -0.6, -0.2]}],
     "amp": {"attack": 0.001, "decay": 0.0, "sustain": 1.0, "release": 0.03, "curve": 1}}]})J"},
    {"chip_noise", "chiptune",
     "a pitched noise voice (chip noise channel): a rasp that follows the note; percussive melodic hits and risers", 36,
     96, 1, 0.6547,
     R"J({"doc": "Chip noise: pink noise through a narrow band-pass that follows the pitch (pink keeps the level even over the range), with a faint pulse underneath to set the root.", "length": 0.2, "tail": 0.08,
  "layers": [
    {"name": "root", "gain": 0.05, "pitch": {"note": "C4"}, "oscillators": [{"wave": "square", "duty": 0.5}],
     "amp": {"attack": 0.001, "decay": 0.1, "sustain": 0.5, "release": 0.03, "curve": 1.5}},
    {"name": "rasp", "oscillators": [{"wave": "noise", "color": "pink"}],
     "filter": {"mode": "bandpass", "cutoff": 260, "resonance": 4, "keytrack": 1},
     "amp": {"attack": 0.001, "decay": 0.12, "sustain": 0.6, "release": 0.03, "curve": 1.5}}]})J"},
};

// ---- drum kits ----------------------------------------------------------------------------------------------------------------

struct KitEntry {
    const char* variant;
    const char* lane;
    double gain;
    const char* body;
};

const KitEntry kKit[] = {
    // acoustic
    {"acoustic", "kick", 0.37,
     R"J({"doc": "Kick: a sine that drops from 150 to 48 Hz with a short click.", "length": 0.3, "tail": 0.1,
  "layers": [
    {"name": "body", "pitch": {"freq": 150, "sweep": {"to": 48, "time": 0.09, "curve": 2.5}}, "oscillators": [{"wave": "sine"}],
     "amp": {"attack": 0.001, "decay": 0.28, "sustain": 0, "release": 0.02, "curve": 2}},
    {"name": "click", "gain": 0.3, "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "lowpass", "cutoff": 3000},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}}]})J"},
    {"acoustic", "snare", 0.289,
     R"J({"doc": "Snare: a short tone for the shell and a burst of noise for the wires.", "length": 0.2, "tail": 0.1,
  "layers": [
    {"name": "shell", "gain": 0.6, "pitch": {"freq": 200, "sweep": {"to": 150, "time": 0.05}}, "oscillators": [{"wave": "triangle"}],
     "amp": {"attack": 0.001, "decay": 0.12, "sustain": 0, "release": 0.02, "curve": 2}},
    {"name": "wires", "gain": 0.5, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 1500},
     "amp": {"attack": 0.001, "decay": 0.18, "sustain": 0, "release": 0.02, "curve": 2}}]})J"},
    {"acoustic", "clap", 0.618,
     R"J({"doc": "Clap: three quick bursts of band-passed noise and a tail.", "length": 0.2, "tail": 0.1,
  "layers": [
    {"name": "b1", "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1300, "resonance": 1.2},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}},
    {"name": "b2", "start": 0.011, "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1300, "resonance": 1.2},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}},
    {"name": "b3", "start": 0.022, "length": 0.2, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1300, "resonance": 1.2},
     "amp": {"attack": 0, "decay": 0.16, "sustain": 0, "release": 0.02, "curve": 2}}]})J"},
    {"acoustic", "rim", 0.094,
     R"J({"doc": "Rim shot: a short high click of a square and noise.", "length": 0.05, "tail": 0.03,
  "layers": [
    {"pitch": {"freq": 900}, "oscillators": [{"wave": "square"}, {"wave": "noise", "gain": 0.5}], "filter": {"mode": "highpass", "cutoff": 500},
     "amp": {"attack": 0, "decay": 0.04, "sustain": 0, "release": 0.005, "curve": 2}}]})J"},
    {"acoustic", "hat", 0.1425,
     R"J({"doc": "Closed hi-hat: a very short tick of high-passed noise.", "length": 0.04, "tail": 0.03,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 7000},
     "amp": {"attack": 0, "decay": 0.045, "sustain": 0, "release": 0.005, "curve": 2}}]})J"},
    {"acoustic", "openhat", 0.139,
     R"J({"doc": "Open hi-hat: high-passed noise that rings out.", "length": 0.15, "tail": 0.25,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 6500},
     "amp": {"attack": 0, "decay": 0.3, "sustain": 0, "release": 0.1, "curve": 1.6}}]})J"},
    {"acoustic", "hat_pedal", 0.1443,
     R"J({"doc": "Pedal hi-hat: the soft chick of two cymbals closing, a little lower and duller than the closed hat.", "length": 0.05, "tail": 0.04,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 5500, "resonance": 0.8},
     "amp": {"attack": 0.002, "decay": 0.05, "sustain": 0, "release": 0.005, "curve": 1.8}}]})J"},
    {"acoustic", "shaker", 0.1032,
     R"J({"doc": "Shaker: a soft swish of band-passed noise.", "length": 0.06, "tail": 0.04,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 6500, "resonance": 0.9},
     "amp": {"attack": 0.015, "decay": 0.07, "sustain": 0, "release": 0.01, "curve": 1.2}}]})J"},
    {"acoustic", "tambourine", 0.09016,
     R"J({"doc": "Tambourine: a burst of noise with the ring of the jingles on top.", "length": 0.08, "tail": 0.2,
  "layers": [
    {"name": "hit", "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 5000},
     "amp": {"attack": 0.001, "decay": 0.07, "sustain": 0, "release": 0.01, "curve": 1.6}},
    {"name": "jingles", "gain": 0.25, "oscillators": [{"wave": "sine", "freq": 5200}, {"wave": "sine", "freq": 7300, "gain": 0.7}, {"wave": "sine", "freq": 9100, "gain": 0.5}],
     "amp": {"attack": 0.001, "decay": 0.22, "sustain": 0, "release": 0.03, "curve": 2}}]})J"},
    {"acoustic", "tom_low", 0.244,
     R"J({"doc": "Low tom: a sine that falls from 120 to 80 Hz.", "length": 0.3, "tail": 0.15,
  "layers": [
    {"pitch": {"freq": 120, "sweep": {"to": 80, "time": 0.15}}, "oscillators": [{"wave": "sine"}, {"wave": "triangle", "gain": 0.3}],
     "amp": {"attack": 0.002, "decay": 0.4, "sustain": 0, "release": 0.04, "curve": 2}}]})J"},
    {"acoustic", "tom_mid", 0.247,
     R"J({"doc": "Mid tom: a sine that falls from 170 to 115 Hz.", "length": 0.25, "tail": 0.12,
  "layers": [
    {"pitch": {"freq": 170, "sweep": {"to": 115, "time": 0.12}}, "oscillators": [{"wave": "sine"}, {"wave": "triangle", "gain": 0.3}],
     "amp": {"attack": 0.002, "decay": 0.35, "sustain": 0, "release": 0.04, "curve": 2}}]})J"},
    {"acoustic", "tom_high", 0.246,
     R"J({"doc": "High tom: a sine that falls from 240 to 170 Hz.", "length": 0.22, "tail": 0.1,
  "layers": [
    {"pitch": {"freq": 240, "sweep": {"to": 170, "time": 0.1}}, "oscillators": [{"wave": "sine"}, {"wave": "triangle", "gain": 0.3}],
     "amp": {"attack": 0.002, "decay": 0.3, "sustain": 0, "release": 0.04, "curve": 2}}]})J"},
    {"acoustic", "ride", 0.1111,
     R"J({"doc": "Ride cymbal: a ping of inharmonic partials over a wash of high noise.", "length": 0.4, "tail": 0.6,
  "layers": [
    {"name": "ping", "gain": 0.5, "oscillators": [{"wave": "sine", "freq": 3100}, {"wave": "sine", "freq": 4350, "gain": 0.7}, {"wave": "sine", "freq": 5870, "gain": 0.5}],
     "amp": {"attack": 0.001, "decay": 0.9, "sustain": 0, "release": 0.1, "curve": 2}},
    {"name": "wash", "gain": 0.3, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 7500},
     "amp": {"attack": 0.001, "decay": 0.6, "sustain": 0, "release": 0.1, "curve": 1.8}}]})J"},
    {"acoustic", "crash", 0.189,
     R"J({"doc": "Crash cymbal: a burst of noise with metallic partials that dies away over a second or so.", "length": 0.8, "tail": 0.9,
  "layers": [
    {"name": "metal", "gain": 0.25, "oscillators": [{"wave": "sine", "freq": 2800}, {"wave": "sine", "freq": 4100, "gain": 0.8}, {"wave": "sine", "freq": 6200, "gain": 0.6}],
     "amp": {"attack": 0.001, "decay": 1.2, "sustain": 0, "release": 0.1, "curve": 1.8}},
    {"name": "wash", "gain": 0.5, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 5000},
     "amp": {"attack": 0.001, "decay": 1.4, "sustain": 0, "release": 0.2, "curve": 1.6}}]})J"},
    {"acoustic", "cowbell", 0.1742,
     R"J({"doc": "Cowbell: two square waves a fifth apart through a band-pass, a hollow metallic knock.", "length": 0.1, "tail": 0.3,
  "layers": [
    {"oscillators": [{"wave": "square", "freq": 560}, {"wave": "square", "freq": 845, "gain": 0.8}], "filter": {"mode": "bandpass", "cutoff": 1000, "resonance": 1.4},
     "amp": {"attack": 0.001, "decay": 0.3, "sustain": 0, "release": 0.03, "curve": 2.2}}]})J"},

    // electronic (808 / 909 flavoured)
    {"electronic", "kick", 0.3664,
     R"J({"doc": "Electronic kick: a long sine boom that falls from 160 to 42 Hz, with a short click.", "length": 0.5, "tail": 0.15,
  "layers": [
    {"name": "boom", "pitch": {"freq": 160, "sweep": {"to": 42, "time": 0.14, "curve": 3}}, "oscillators": [{"wave": "sine"}],
     "amp": {"attack": 0.001, "decay": 0.55, "sustain": 0, "release": 0.03, "curve": 1.8}},
    {"name": "click", "gain": 0.2, "length": 0.008, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "lowpass", "cutoff": 4500},
     "amp": {"attack": 0, "decay": 0.008, "sustain": 0, "release": 0}}]})J"},
    {"electronic", "snare", 0.2383,
     R"J({"doc": "Electronic snare: a pitched body and a bright noise burst, tight and snappy.", "length": 0.25, "tail": 0.12,
  "layers": [
    {"name": "body", "gain": 0.6, "pitch": {"freq": 220, "sweep": {"to": 160, "time": 0.04}}, "oscillators": [{"wave": "triangle"}],
     "amp": {"attack": 0.001, "decay": 0.1, "sustain": 0, "release": 0.02, "curve": 2}},
    {"name": "snap", "gain": 0.7, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 1800},
     "amp": {"attack": 0.001, "decay": 0.17, "sustain": 0, "release": 0.02, "curve": 2.2}}]})J"},
    {"electronic", "clap", 0.4886,
     R"J({"doc": "Electronic clap: four noise bursts and a tail through a small room.", "length": 0.25, "tail": 0.2,
  "layers": [
    {"name": "b1", "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1500, "resonance": 1.5},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}},
    {"name": "b2", "start": 0.012, "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1500, "resonance": 1.5},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}},
    {"name": "b3", "start": 0.024, "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1500, "resonance": 1.5},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}},
    {"name": "tail", "start": 0.036, "length": 0.25, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1500, "resonance": 1.5},
     "amp": {"attack": 0, "decay": 0.2, "sustain": 0, "release": 0.03, "curve": 2}}],
  "effects": [{"type": "reverb", "decay": 0.3, "mix": 0.2, "size": 0.5}]})J"},
    {"electronic", "rim", 0.1191,
     R"J({"doc": "Electronic rim: a short pair of tones, one high and one low, with a click.", "length": 0.04, "tail": 0.03,
  "layers": [
    {"oscillators": [{"wave": "sine", "freq": 1700}, {"wave": "sine", "freq": 480, "gain": 0.8}, {"wave": "noise", "gain": 0.15}],
     "amp": {"attack": 0, "decay": 0.03, "sustain": 0, "release": 0.005, "curve": 2}}]})J"},
    {"electronic", "hat", 0.04416,
     R"J({"doc": "Electronic closed hat: metallic square partials and noise, high-passed and very short.", "length": 0.04, "tail": 0.03,
  "layers": [
    {"oscillators": [{"wave": "square", "freq": 4800}, {"wave": "square", "freq": 6200}, {"wave": "square", "freq": 7900}, {"wave": "square", "freq": 9300}, {"wave": "noise", "gain": 1.5}],
     "filter": {"mode": "highpass", "cutoff": 7500},
     "amp": {"attack": 0, "decay": 0.04, "sustain": 0, "release": 0.005, "curve": 2.2}}]})J"},
    {"electronic", "openhat", 0.0389,
     R"J({"doc": "Electronic open hat: the same metallic mix, ringing out.", "length": 0.15, "tail": 0.3,
  "layers": [
    {"oscillators": [{"wave": "square", "freq": 4800}, {"wave": "square", "freq": 6200}, {"wave": "square", "freq": 7900}, {"wave": "square", "freq": 9300}, {"wave": "noise", "gain": 1.5}],
     "filter": {"mode": "highpass", "cutoff": 7000},
     "amp": {"attack": 0, "decay": 0.3, "sustain": 0, "release": 0.1, "curve": 1.8}}]})J"},
    {"electronic", "hat_pedal", 0.03936,
     R"J({"doc": "Electronic pedal hat: a very short, quiet tick of the metallic mix.", "length": 0.03, "tail": 0.03,
  "layers": [
    {"oscillators": [{"wave": "square", "freq": 4800}, {"wave": "square", "freq": 6200}, {"wave": "square", "freq": 7900}, {"wave": "noise", "gain": 1.5}],
     "filter": {"mode": "highpass", "cutoff": 6500},
     "amp": {"attack": 0, "decay": 0.025, "sustain": 0, "release": 0.005, "curve": 2}}]})J"},
    {"electronic", "shaker", 0.1072,
     R"J({"doc": "Electronic shaker: a short swell of band-passed noise.", "length": 0.06, "tail": 0.04,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 7500, "resonance": 1.2},
     "amp": {"attack": 0.012, "decay": 0.05, "sustain": 0, "release": 0.01, "curve": 1.4}}]})J"},
    {"electronic", "tambourine", 0.1059,
     R"J({"doc": "Electronic tambourine: a high noise burst with a ringing square on top.", "length": 0.06, "tail": 0.12,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}, {"wave": "square", "freq": 6100, "gain": 0.3}], "filter": {"mode": "highpass", "cutoff": 6000},
     "amp": {"attack": 0.001, "decay": 0.12, "sustain": 0, "release": 0.02, "curve": 1.8}}]})J"},
    {"electronic", "tom_low", 0.3177,
     R"J({"doc": "Electronic low tom: a long sine that falls from 110 to 62 Hz.", "length": 0.4, "tail": 0.15,
  "layers": [
    {"pitch": {"freq": 110, "sweep": {"to": 62, "time": 0.2, "curve": 2}}, "oscillators": [{"wave": "sine"}],
     "amp": {"attack": 0.001, "decay": 0.5, "sustain": 0, "release": 0.04, "curve": 1.8}}]})J"},
    {"electronic", "tom_mid", 0.3177,
     R"J({"doc": "Electronic mid tom: a sine that falls from 160 to 100 Hz.", "length": 0.35, "tail": 0.12,
  "layers": [
    {"pitch": {"freq": 160, "sweep": {"to": 100, "time": 0.16, "curve": 2}}, "oscillators": [{"wave": "sine"}],
     "amp": {"attack": 0.001, "decay": 0.42, "sustain": 0, "release": 0.04, "curve": 1.8}}]})J"},
    {"electronic", "tom_high", 0.3177,
     R"J({"doc": "Electronic high tom: a sine that falls from 230 to 150 Hz.", "length": 0.3, "tail": 0.1,
  "layers": [
    {"pitch": {"freq": 230, "sweep": {"to": 150, "time": 0.13, "curve": 2}}, "oscillators": [{"wave": "sine"}],
     "amp": {"attack": 0.001, "decay": 0.35, "sustain": 0, "release": 0.04, "curve": 1.8}}]})J"},
    {"electronic", "ride", 0.04732,
     R"J({"doc": "Electronic ride: bright metallic partials with a long shimmer of noise.", "length": 0.5, "tail": 0.8,
  "layers": [
    {"oscillators": [{"wave": "square", "freq": 3300}, {"wave": "square", "freq": 4700, "gain": 0.8}, {"wave": "square", "freq": 6100, "gain": 0.6}, {"wave": "square", "freq": 8300, "gain": 0.5},
                     {"wave": "noise", "gain": 1.0}],
     "filter": {"mode": "highpass", "cutoff": 6500},
     "amp": {"attack": 0.001, "decay": 1.2, "sustain": 0, "release": 0.15, "curve": 2}}]})J"},
    {"electronic", "crash", 0.05957,
     R"J({"doc": "Electronic crash: noise and metallic partials that wash out over a second and a half.", "length": 0.8, "tail": 1.2,
  "layers": [
    {"oscillators": [{"wave": "square", "freq": 3000}, {"wave": "square", "freq": 4400, "gain": 0.8}, {"wave": "square", "freq": 6300, "gain": 0.6}, {"wave": "noise", "gain": 1.5}],
     "filter": {"mode": "highpass", "cutoff": 4500},
     "amp": {"attack": 0.001, "decay": 1.7, "sustain": 0, "release": 0.2, "curve": 1.7}}]})J"},
    {"electronic", "cowbell", 0.1539,
     R"J({"doc": "Electronic cowbell: two squares (540 and 800 Hz) through a band-pass, short and dry.", "length": 0.08, "tail": 0.2,
  "layers": [
    {"oscillators": [{"wave": "square", "freq": 540}, {"wave": "square", "freq": 800}], "filter": {"mode": "bandpass", "cutoff": 2600, "resonance": 0.9},
     "amp": {"attack": 0.001, "decay": 0.25, "sustain": 0, "release": 0.02, "curve": 2.4}}]})J"},

    // chiptune (square and noise channels, crushed)
    {"chiptune", "kick", 0.3909,
     R"J({"doc": "Chip kick: a triangle that dives from 220 to 45 Hz in a few frames.", "length": 0.18, "tail": 0.05,
  "layers": [
    {"pitch": {"freq": 220, "sweep": {"to": 45, "time": 0.07, "curve": 2.5}}, "oscillators": [{"wave": "triangle"}],
     "amp": {"attack": 0.001, "decay": 0.16, "sustain": 0, "release": 0.01, "curve": 1.6}}],
  "effects": [{"type": "bitcrush", "bits": 6, "rate": 16000}]})J"},
    {"chiptune", "snare", 0.2103,
     R"J({"doc": "Chip snare: a burst of crushed white noise over a short square.", "length": 0.14, "tail": 0.05,
  "layers": [
    {"name": "noise", "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 900},
     "amp": {"attack": 0, "decay": 0.12, "sustain": 0, "release": 0.01, "curve": 1.8}},
    {"name": "tone", "gain": 0.5, "pitch": {"freq": 230, "sweep": {"to": 160, "time": 0.04}}, "oscillators": [{"wave": "square", "duty": 0.5}],
     "amp": {"attack": 0, "decay": 0.06, "sustain": 0, "release": 0.005, "curve": 2}}],
  "effects": [{"type": "bitcrush", "bits": 5, "rate": 14000}]})J"},
    {"chiptune", "clap", 0.5334,
     R"J({"doc": "Chip clap: three short crushed noise bursts.", "length": 0.1, "tail": 0.05,
  "layers": [
    {"name": "b1", "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1500, "resonance": 1},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}},
    {"name": "b2", "start": 0.012, "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1500, "resonance": 1},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}},
    {"name": "b3", "start": 0.024, "length": 0.1, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1500, "resonance": 1},
     "amp": {"attack": 0, "decay": 0.08, "sustain": 0, "release": 0.01, "curve": 2}}],
  "effects": [{"type": "bitcrush", "bits": 5, "rate": 12000}]})J"},
    {"chiptune", "rim", 0.1331,
     R"J({"doc": "Chip rim: a very short high pulse.", "length": 0.03, "tail": 0.02,
  "layers": [
    {"pitch": {"freq": 1300}, "oscillators": [{"wave": "square", "duty": 0.25}],
     "amp": {"attack": 0, "decay": 0.025, "sustain": 0, "release": 0.003, "curve": 1.5}}]})J"},
    {"chiptune", "hat", 0.1135,
     R"J({"doc": "Chip hat: a tick of crushed high noise.", "length": 0.03, "tail": 0.02,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 8000},
     "amp": {"attack": 0, "decay": 0.03, "sustain": 0, "release": 0.003, "curve": 1.6}}],
  "effects": [{"type": "bitcrush", "bits": 4, "rate": 22050}]})J"},
    {"chiptune", "openhat", 0.1274,
     R"J({"doc": "Chip open hat: crushed high noise that rings for a fifth of a second.", "length": 0.12, "tail": 0.1,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 7000},
     "amp": {"attack": 0, "decay": 0.2, "sustain": 0, "release": 0.03, "curve": 1.4}}],
  "effects": [{"type": "bitcrush", "bits": 4, "rate": 22050}]})J"},
    {"chiptune", "hat_pedal", 0.09016,
     R"J({"doc": "Chip pedal hat: a shorter, quieter tick than the closed hat.", "length": 0.02, "tail": 0.02,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 6000},
     "amp": {"attack": 0, "decay": 0.02, "sustain": 0, "release": 0.003, "curve": 1.6}}],
  "effects": [{"type": "bitcrush", "bits": 4, "rate": 16000}]})J"},
    {"chiptune", "shaker", 0.1,
     R"J({"doc": "Chip shaker: a short crushed swish.", "length": 0.05, "tail": 0.02,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 6000, "resonance": 1},
     "amp": {"attack": 0.008, "decay": 0.05, "sustain": 0, "release": 0.005, "curve": 1.4}}],
  "effects": [{"type": "bitcrush", "bits": 4, "rate": 14000}]})J"},
    {"chiptune", "tambourine", 0.1362,
     R"J({"doc": "Chip tambourine: a short noise burst with a pulse ping.", "length": 0.05, "tail": 0.08,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}, {"wave": "square", "freq": 4200, "duty": 0.25, "gain": 0.4}], "filter": {"mode": "highpass", "cutoff": 5000},
     "amp": {"attack": 0, "decay": 0.08, "sustain": 0, "release": 0.01, "curve": 1.8}}],
  "effects": [{"type": "bitcrush", "bits": 5, "rate": 16000}]})J"},
    {"chiptune", "tom_low", 0.3366,
     R"J({"doc": "Chip low tom: a triangle that falls from 130 to 80 Hz.", "length": 0.16, "tail": 0.06,
  "layers": [
    {"pitch": {"freq": 130, "sweep": {"to": 80, "time": 0.1}}, "oscillators": [{"wave": "triangle"}],
     "amp": {"attack": 0.001, "decay": 0.18, "sustain": 0, "release": 0.01, "curve": 1.6}}],
  "effects": [{"type": "bitcrush", "bits": 6, "rate": 16000}]})J"},
    {"chiptune", "tom_mid", 0.3366,
     R"J({"doc": "Chip mid tom: a triangle that falls from 190 to 120 Hz.", "length": 0.15, "tail": 0.06,
  "layers": [
    {"pitch": {"freq": 190, "sweep": {"to": 120, "time": 0.09}}, "oscillators": [{"wave": "triangle"}],
     "amp": {"attack": 0.001, "decay": 0.16, "sustain": 0, "release": 0.01, "curve": 1.6}}],
  "effects": [{"type": "bitcrush", "bits": 6, "rate": 16000}]})J"},
    {"chiptune", "tom_high", 0.3366,
     R"J({"doc": "Chip high tom: a triangle that falls from 270 to 180 Hz.", "length": 0.14, "tail": 0.05,
  "layers": [
    {"pitch": {"freq": 270, "sweep": {"to": 180, "time": 0.08}}, "oscillators": [{"wave": "triangle"}],
     "amp": {"attack": 0.001, "decay": 0.14, "sustain": 0, "release": 0.01, "curve": 1.6}}],
  "effects": [{"type": "bitcrush", "bits": 6, "rate": 16000}]})J"},
    {"chiptune", "ride", 0.1135,
     R"J({"doc": "Chip ride: crushed noise and a pulse ping, a quarter of a second long.", "length": 0.2, "tail": 0.25,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}, {"wave": "square", "freq": 5200, "duty": 0.125, "gain": 0.5}], "filter": {"mode": "highpass", "cutoff": 6500},
     "amp": {"attack": 0, "decay": 0.4, "sustain": 0, "release": 0.05, "curve": 1.8}}],
  "effects": [{"type": "bitcrush", "bits": 4, "rate": 20000}]})J"},
    {"chiptune", "crash", 0.1603,
     R"J({"doc": "Chip crash: a long burst of crushed noise.", "length": 0.4, "tail": 0.5,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 4500},
     "amp": {"attack": 0, "decay": 0.8, "sustain": 0, "release": 0.1, "curve": 1.5}}],
  "effects": [{"type": "bitcrush", "bits": 4, "rate": 14000}]})J"},
    {"chiptune", "cowbell", 0.1205,
     R"J({"doc": "Chip cowbell: two pulse waves, short and hollow.", "length": 0.1, "tail": 0.08,
  "layers": [
    {"oscillators": [{"wave": "square", "freq": 800, "duty": 0.25}, {"wave": "square", "freq": 1190, "duty": 0.25, "gain": 0.8}],
     "amp": {"attack": 0.001, "decay": 0.12, "sustain": 0, "release": 0.01, "curve": 1.8}}]})J"},
};

struct Family {
    const char* name;
    const char* what;
};
const Family kFamilies[] = {
    {"keys", "pianos, electric pianos, clavinet and organ: chords, comping and melodies"},
    {"pluck", "plucked strings and harp: arpeggios, melodies and strummed parts that fade by themselves"},
    {"bass", "bass voices from a pure sub to an acid squelch: the low line of a song"},
    {"lead", "solo synth leads: the melody that sits on top of the mix"},
    {"pad", "slow, sustained synth beds: chords that glue a song together"},
    {"bell", "bells, chimes, music box and mallets: accents, sparkles and delicate melodies"},
    {"ensemble",
     "strings, brass, horns, a vowel choir and woodwinds: sections and orchestral colour built from sound patches"},
    {"chiptune",
     "console-style voices: pulse widths 12.5/25/50 percent, triangle, a 4-bit wavetable and a pitched noise channel"},
};

struct KitDescription {
    const char* name;
    const char* instrument;
    const char* what;
};
const KitDescription kKits[] = {
    {"acoustic", "kit",
     "an acoustic-flavoured kit: a round kick, a snare with wires, soft noise hats, three toms, ride and crash "
     "cymbals"},
    {"electronic", "kit:electronic",
     "a drum-machine kit (808/909 flavoured): a long sine boom for a kick, a snappy snare, a reverbed clap, metallic "
     "square hats"},
    {"chiptune", "kit:chiptune",
     "an 8-bit kit: a triangle kick, bit-crushed noise for the snare, hats and crash, pulse-wave rim and cowbell"},
};

// A patch the renderer can use as it stands: the table's body plus the format, the table's gain and a master that does not re-level.
// Effects written at the top of a body belong to the master chain.
Json build(const char* body, double gain) {
    Json j = Json::parse(body);
    j["format"] = "factoria.sfx/1";
    j["gain"] = gain;
    Json master = Json::object();
    if (auto it = j.find("effects"); it != j.end()) {
        master["effects"] = *it;
        j.erase("effects");
    }
    master["normalize"] = Json{{"mode", "none"}};
    j["master"] = std::move(master);
    return j;
}

const Entry* find_pitched(std::string_view name) {
    for (const Entry& e : kPitched)
        if (name == e.name) return &e;
    return nullptr;
}

}  // namespace

const std::vector<SongInstrumentInfo>& song_instruments() {
    static const std::vector<SongInstrumentInfo> list = [] {
        std::vector<SongInstrumentInfo> v;
        for (const Entry& e : kPitched) v.push_back({e.name, e.family, e.what, e.low, e.high, e.voices});
        return v;
    }();
    return list;
}

const std::vector<SongInstrumentFamily>& song_instrument_families() {
    static const std::vector<SongInstrumentFamily> list = [] {
        std::vector<SongInstrumentFamily> v;
        for (const Family& f : kFamilies) v.push_back({f.name, f.what});
        return v;
    }();
    return list;
}

const std::vector<SongKitInfo>& song_kits() {
    static const std::vector<SongKitInfo> list = [] {
        std::vector<SongKitInfo> v;
        for (const KitDescription& k : kKits) v.push_back({k.name, k.what, k.instrument});
        return v;
    }();
    return list;
}

std::optional<std::string> song_kit_variant(std::string_view instrument) {
    if (instrument == "kit") return std::string("acoustic");
    constexpr std::string_view prefix = "kit:";
    if (instrument.substr(0, prefix.size()) != prefix) return std::nullopt;
    const std::string_view variant = instrument.substr(prefix.size());
    for (const KitDescription& k : kKits)
        if (variant == k.name) return std::string(variant);
    return std::nullopt;
}

std::optional<Json> song_instrument_patch(std::string_view name) {
    constexpr std::string_view prefix = "kit:";
    if (name.substr(0, prefix.size()) == prefix) {
        std::string_view rest = name.substr(prefix.size());
        std::string variant = "acoustic";
        if (const std::size_t colon = rest.find(':'); colon != std::string_view::npos) {
            variant = std::string(rest.substr(0, colon));
            rest = rest.substr(colon + 1);
        }
        for (const KitEntry& e : kKit)
            if (variant == e.variant && rest == e.lane) return build(e.body, e.gain);
        return std::nullopt;
    }
    if (const Entry* e = find_pitched(name)) return build(e->body, e->gain);
    return std::nullopt;
}

std::optional<std::pair<int, int>> song_instrument_range(std::string_view name) {
    if (const Entry* e = find_pitched(name)) return std::make_pair(e->low, e->high);
    return std::nullopt;
}

std::optional<int> song_instrument_voices(std::string_view name) {
    if (const Entry* e = find_pitched(name)) return e->voices;
    return std::nullopt;
}

}  // namespace fa
