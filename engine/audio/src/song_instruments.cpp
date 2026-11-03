// The built-in instruments and drum kit of the song preview (fa/audio/song_instruments.h), as the JSON of sound patches.
//
// Conventions: every pitched patch is tuned to C4 (the song renderer transposes it to the note), has `normalize` none so levels are the
// ones written here, and a `tail` long enough for its release. Each pitched patch carries a master "gain" measured so its C4 note,
// played at velocity 100, peaks about -12 dBFS (a patch of the user's is levelled the same way when the preview renders it); the kit lanes
// carry gains of their own. Filters do not follow pitch, so cutoffs are generous. Drum patches are
// one-shots: the renderer plays them as written.
#include <string>
#include <string_view>

#include "fa/audio/song_instruments.h"

namespace fa {

namespace {

struct Entry {
    const char* name;
    const char* what;
    int low, high;
    const char* json;
};

const Entry kPitched[] = {
    {"keys", "electric-piano keys: a soft tone with a bright tine that decays by itself; chords, comping, melodies", 33, 96,
     R"J({"format": "factoria.sfx/1", "gain": 0.394, "doc": "Keys: a soft electric-piano-like tone that decays by itself.", "length": 0.6, "tail": 0.6,
  "layers": [
    {"name": "body", "gain": 0.5, "pitch": {"note": "C4"},
     "oscillators": [{"wave": "triangle"}, {"wave": "sine", "ratio": 2, "gain": 0.35}, {"wave": "sine", "ratio": 3, "gain": 0.12}],
     "filter": {"mode": "lowpass", "cutoff": 3500, "env": {"amount": 1.2, "attack": 0.001, "decay": 0.4, "sustain": 0}},
     "amp": {"attack": 0.003, "decay": 1.4, "sustain": 0, "release": 0.25, "curve": 2.2}},
    {"name": "tine", "gain": 0.25, "pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine", "ratio": 4, "fm": {"ratio": 1, "index": 1.5, "indexEnv": {"attack": 0, "decay": 0.15, "sustain": 0}}}],
     "amp": {"attack": 0.001, "decay": 0.25, "sustain": 0, "release": 0.1, "curve": 2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"pluck", "a plucked string, bright then mellow as it dies; arpeggios, melodies, guitar-like parts", 40, 88,
     R"J({"format": "factoria.sfx/1", "gain": 0.299, "doc": "Pluck: a plucked string, bright at the start and mellow as it dies.", "length": 0.5, "tail": 0.4,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw", "gain": 0.7}, {"wave": "triangle", "ratio": 2, "gain": 0.25}],
     "filter": {"mode": "lowpass", "cutoff": 1800, "resonance": 1.0, "env": {"amount": 2.2, "attack": 0.001, "decay": 0.3, "sustain": 0}},
     "amp": {"attack": 0.002, "decay": 0.9, "sustain": 0, "release": 0.12, "curve": 2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"bass", "a round synth bass: a saw over a sine an octave down, with a short punch", 28, 64,
     R"J({"format": "factoria.sfx/1", "gain": 0.137, "doc": "Bass: a saw over a sine an octave below, filtered, with a short punch.", "length": 0.5, "tail": 0.2,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw", "gain": 0.55}, {"wave": "square", "gain": 0.25, "duty": 0.4, "detune": 6}, {"wave": "sine", "ratio": 0.5, "gain": 0.9}],
     "filter": {"mode": "lowpass", "cutoff": 700, "resonance": 1.2, "env": {"amount": 1.5, "attack": 0.001, "decay": 0.18, "sustain": 0.2}},
     "amp": {"attack": 0.004, "decay": 0.25, "sustain": 0.75, "release": 0.12, "curve": 1.5}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"pad", "a warm pad: detuned saws that swell in slowly and fade out slowly; sustained chords", 36, 84,
     R"J({"format": "factoria.sfx/1", "gain": 0.094, "doc": "Pad: three detuned saws, filtered, a slow swell in and a long release.", "length": 1.0, "tail": 1.2,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "saw", "detune": -9}, {"wave": "saw", "detune": 0}, {"wave": "saw", "detune": 9}, {"wave": "sine", "ratio": 0.5, "gain": 0.6}],
     "filter": {"mode": "lowpass", "cutoff": 1400, "resonance": 0.9},
     "amp": {"attack": 0.35, "decay": 0.3, "sustain": 0.85, "release": 1.0, "curve": 1}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"strings", "a string section: bright detuned saws with a bowed swell and a gentle vibrato", 36, 88,
     R"J({"format": "factoria.sfx/1", "gain": 0.142, "doc": "Strings: detuned saws with a slow bow attack and a delayed vibrato.", "length": 1.0, "tail": 0.6,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5.2, "depth": 14, "delay": 0.3}},
     "oscillators": [{"wave": "saw", "detune": -7}, {"wave": "saw", "detune": 7}, {"wave": "saw", "ratio": 2, "gain": 0.15}],
     "filter": {"mode": "lowpass", "cutoff": 3200, "resonance": 0.8},
     "amp": {"attack": 0.18, "decay": 0.2, "sustain": 0.9, "release": 0.45, "curve": 1}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"organ", "a drawbar organ: stacked sines, steady level, no decay; sustained chords and held notes", 36, 96,
     R"J({"format": "factoria.sfx/1", "gain": 0.128, "doc": "Organ: sines at the octave harmonics, an even level while held.", "length": 0.8, "tail": 0.15,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine"}, {"wave": "sine", "ratio": 2, "gain": 0.7}, {"wave": "sine", "ratio": 3, "gain": 0.4}, {"wave": "sine", "ratio": 4, "gain": 0.3},
                     {"wave": "sine", "ratio": 0.5, "gain": 0.5}],
     "tremolo": {"rate": 5.5, "depth": 0.08},
     "amp": {"attack": 0.008, "decay": 0.0, "sustain": 1.0, "release": 0.08, "curve": 1}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"lead", "a solo synth lead: a hollow square with a delayed vibrato; melodies", 55, 96,
     R"J({"format": "factoria.sfx/1", "gain": 0.152, "doc": "Lead: a square with a soft detuned double and a vibrato that comes in after the attack.", "length": 0.5, "tail": 0.25,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5.5, "depth": 18, "delay": 0.15}},
     "oscillators": [{"wave": "square", "duty": 0.45}, {"wave": "saw", "detune": 8, "gain": 0.4}],
     "filter": {"mode": "lowpass", "cutoff": 4500, "resonance": 1.0},
     "amp": {"attack": 0.01, "decay": 0.15, "sustain": 0.7, "release": 0.15, "curve": 1.3}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"chiptune", "an 8-bit pulse wave: a thin square with a fast decay; melodies and arpeggios in a retro game", 48, 100,
     R"J({"format": "factoria.sfx/1", "gain": 0.168, "doc": "Chiptune: a 25 percent pulse wave with a short punch, like a console sound chip.", "length": 0.3, "tail": 0.1,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "square", "duty": 0.25}],
     "amp": {"attack": 0.001, "decay": 0.12, "sustain": 0.6, "release": 0.05, "curve": 1.5}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"flute", "a breathy flute: a soft triangle with a little air; gentle melodies", 60, 96,
     R"J({"format": "factoria.sfx/1", "gain": 0.250, "doc": "Flute: a triangle and a sine with breath noise and a slow vibrato.", "length": 0.6, "tail": 0.25,
  "layers": [
    {"pitch": {"note": "C4", "vibrato": {"rate": 5, "depth": 22, "delay": 0.25}},
     "oscillators": [{"wave": "triangle"}, {"wave": "sine", "ratio": 2, "gain": 0.2}],
     "amp": {"attack": 0.07, "decay": 0.1, "sustain": 0.9, "release": 0.18, "curve": 1}},
    {"name": "breath", "gain": 0.04,
     "oscillators": [{"wave": "noise", "color": "pink"}],
     "filter": {"mode": "bandpass", "cutoff": 3000, "resonance": 0.8},
     "amp": {"attack": 0.05, "decay": 0.1, "sustain": 0.5, "release": 0.12, "curve": 1}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"bell", "a bell: FM that starts bright and goes mellow; chimes, high accents", 60, 108,
     R"J({"format": "factoria.sfx/1", "gain": 0.202, "doc": "Bell: a sine with inharmonic FM whose brightness dies away, ringing a long time.", "length": 0.3, "tail": 1.6,
  "layers": [
    {"pitch": {"note": "C4"},
     "oscillators": [{"wave": "sine", "fm": {"ratio": 3.5, "index": 2.5, "indexEnv": {"attack": 0, "decay": 0.8, "sustain": 0.05, "curve": 1.5}}},
                     {"wave": "sine", "ratio": 2.76, "gain": 0.25}],
     "amp": {"attack": 0.001, "decay": 1.8, "sustain": 0, "release": 0.3, "curve": 2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
};

const Entry kKit[] = {
    {"kick", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.370, "doc": "Kick: a sine that drops from 150 to 48 Hz with a short click.", "length": 0.3, "tail": 0.1,
  "layers": [
    {"name": "body", "pitch": {"freq": 150, "sweep": {"to": 48, "time": 0.09, "curve": 2.5}},
     "oscillators": [{"wave": "sine"}],
     "amp": {"attack": 0.001, "decay": 0.28, "sustain": 0, "release": 0.02, "curve": 2}},
    {"name": "click", "gain": 0.3, "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "lowpass", "cutoff": 3000},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"snare", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.289, "doc": "Snare: a short tone for the shell and a burst of noise for the wires.", "length": 0.2, "tail": 0.1,
  "layers": [
    {"name": "shell", "gain": 0.6, "pitch": {"freq": 200, "sweep": {"to": 150, "time": 0.05}}, "oscillators": [{"wave": "triangle"}],
     "amp": {"attack": 0.001, "decay": 0.12, "sustain": 0, "release": 0.02, "curve": 2}},
    {"name": "wires", "gain": 0.5, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 1500},
     "amp": {"attack": 0.001, "decay": 0.18, "sustain": 0, "release": 0.02, "curve": 2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"clap", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.618, "doc": "Clap: three quick bursts of band-passed noise and a tail.", "length": 0.2, "tail": 0.1,
  "layers": [
    {"name": "b1", "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1300, "resonance": 1.2},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}},
    {"name": "b2", "start": 0.011, "length": 0.01, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1300, "resonance": 1.2},
     "amp": {"attack": 0, "decay": 0.01, "sustain": 0, "release": 0}},
    {"name": "b3", "start": 0.022, "length": 0.2, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 1300, "resonance": 1.2},
     "amp": {"attack": 0, "decay": 0.16, "sustain": 0, "release": 0.02, "curve": 2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"rim", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.094, "doc": "Rim shot: a short high click of a square and noise.", "length": 0.05, "tail": 0.03,
  "layers": [
    {"pitch": {"freq": 900}, "oscillators": [{"wave": "square"}, {"wave": "noise", "gain": 0.5}], "filter": {"mode": "highpass", "cutoff": 500},
     "amp": {"attack": 0, "decay": 0.04, "sustain": 0, "release": 0.005, "curve": 2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"hat", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.127, "doc": "Closed hi-hat: a very short tick of high-passed noise.", "length": 0.04, "tail": 0.03,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 7000},
     "amp": {"attack": 0, "decay": 0.045, "sustain": 0, "release": 0.005, "curve": 2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"openhat", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.139, "doc": "Open hi-hat: high-passed noise that rings out.", "length": 0.15, "tail": 0.25,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 6500},
     "amp": {"attack": 0, "decay": 0.3, "sustain": 0, "release": 0.1, "curve": 1.6}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"shaker", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.092, "doc": "Shaker: a soft swish of band-passed noise.", "length": 0.06, "tail": 0.04,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "bandpass", "cutoff": 6500, "resonance": 0.9},
     "amp": {"attack": 0.015, "decay": 0.07, "sustain": 0, "release": 0.01, "curve": 1.2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"tom_low", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.244, "doc": "Low tom: a sine that falls from 120 to 80 Hz.", "length": 0.3, "tail": 0.15,
  "layers": [
    {"pitch": {"freq": 120, "sweep": {"to": 80, "time": 0.15}}, "oscillators": [{"wave": "sine"}, {"wave": "triangle", "gain": 0.3}],
     "amp": {"attack": 0.002, "decay": 0.4, "sustain": 0, "release": 0.04, "curve": 2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"tom_mid", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.247, "doc": "Mid tom: a sine that falls from 170 to 115 Hz.", "length": 0.25, "tail": 0.12,
  "layers": [
    {"pitch": {"freq": 170, "sweep": {"to": 115, "time": 0.12}}, "oscillators": [{"wave": "sine"}, {"wave": "triangle", "gain": 0.3}],
     "amp": {"attack": 0.002, "decay": 0.35, "sustain": 0, "release": 0.04, "curve": 2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"tom_high", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.246, "doc": "High tom: a sine that falls from 240 to 170 Hz.", "length": 0.22, "tail": 0.1,
  "layers": [
    {"pitch": {"freq": 240, "sweep": {"to": 170, "time": 0.1}}, "oscillators": [{"wave": "sine"}, {"wave": "triangle", "gain": 0.3}],
     "amp": {"attack": 0.002, "decay": 0.3, "sustain": 0, "release": 0.04, "curve": 2}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"ride", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.099, "doc": "Ride cymbal: a ping of inharmonic partials over a wash of high noise.", "length": 0.4, "tail": 0.6,
  "layers": [
    {"name": "ping", "gain": 0.5, "oscillators": [{"wave": "sine", "freq": 3100}, {"wave": "sine", "freq": 4350, "gain": 0.7}, {"wave": "sine", "freq": 5870, "gain": 0.5}],
     "amp": {"attack": 0.001, "decay": 0.9, "sustain": 0, "release": 0.1, "curve": 2}},
    {"name": "wash", "gain": 0.3, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 7500},
     "amp": {"attack": 0.001, "decay": 0.6, "sustain": 0, "release": 0.1, "curve": 1.8}}],
  "master": {"normalize": {"mode": "none"}}})J"},
    {"crash", "", 0, 0,
     R"J({"format": "factoria.sfx/1", "gain": 0.189, "doc": "Crash cymbal: a burst of noise with metallic partials that dies away over a second or so.", "length": 0.8, "tail": 0.9,
  "layers": [
    {"name": "metal", "gain": 0.25, "oscillators": [{"wave": "sine", "freq": 2800}, {"wave": "sine", "freq": 4100, "gain": 0.8}, {"wave": "sine", "freq": 6200, "gain": 0.6}],
     "amp": {"attack": 0.001, "decay": 1.2, "sustain": 0, "release": 0.1, "curve": 1.8}},
    {"name": "wash", "gain": 0.5, "oscillators": [{"wave": "noise", "color": "white"}], "filter": {"mode": "highpass", "cutoff": 5000},
     "amp": {"attack": 0.001, "decay": 1.4, "sustain": 0, "release": 0.2, "curve": 1.6}}],
  "master": {"normalize": {"mode": "none"}}})J"},
};

}  // namespace

const std::vector<SongInstrumentInfo>& song_instruments() {
    static const std::vector<SongInstrumentInfo> list = [] {
        std::vector<SongInstrumentInfo> v;
        for (const Entry& e : kPitched) v.push_back({e.name, e.what, e.low, e.high});
        return v;
    }();
    return list;
}

std::optional<Json> song_instrument_patch(std::string_view name) {
    constexpr std::string_view kitPrefix = "kit:";
    if (name.substr(0, kitPrefix.size()) == kitPrefix) {
        const std::string_view lane = name.substr(kitPrefix.size());
        for (const Entry& e : kKit)
            if (lane == e.name) return Json::parse(e.json);
        return std::nullopt;
    }
    for (const Entry& e : kPitched)
        if (name == e.name) return Json::parse(e.json);
    return std::nullopt;
}

std::optional<std::pair<int, int>> song_instrument_range(std::string_view name) {
    for (const Entry& e : kPitched)
        if (name == e.name) return std::make_pair(e.low, e.high);
    return std::nullopt;
}

}  // namespace fa
