// The sounds of `assets.synth_sound` as sound patches (fa/audio/sfx.h). Each is the JSON of a *.sfx.json file, so the patch an AI
// gets from `sfx.preset` is exactly what renders: it can open it, change a number and render again.
//
// Conventions: `length` is the sound's duration; the amp envelope decays to 0 over it (decay + curve = how punchy); a pitch sweep
// covers the layer; noise sits next to the tone with a low-pass whose cutoff sets its colour. Levels are only relative: every
// patch is levelled to -18 LUFS by the default normalization.
#include <string_view>

#include "fa/audio/sfx.h"

namespace fa {

namespace {

struct Preset {
    const char* name;
    const char* what;
    const char* json;
};

const Preset kPresets[] = {
    {"bark", "a dog bark: two short rough barks",
     R"J({"format": "factoria.sfx/1", "doc": "A dog bark: two rough barks, the second a little lower and quieter.", "length": 0.45,
  "layers": [
    {"name": "first bark", "length": 0.22, "pitch": {"freq": 520, "sweep": {"to": 330}},
     "oscillators": [{"wave": "saw"}, {"wave": "noise", "gain": 0.55}],
     "filter": {"mode": "lowpass", "cutoff": 3000},
     "amp": {"attack": 0.004, "decay": 0.216, "sustain": 0, "curve": 2.2}},
    {"name": "second bark", "start": 0.23, "length": 0.22, "gain": 0.8, "pitch": {"freq": 470, "sweep": {"to": 280}},
     "oscillators": [{"wave": "saw"}, {"wave": "noise", "gain": 0.55}],
     "filter": {"mode": "lowpass", "cutoff": 3000},
     "amp": {"attack": 0.004, "decay": 0.216, "sustain": 0, "curve": 2.2}}],
  "master": {"effects": [{"type": "distortion", "mode": "soft", "drive": 1.6}]}})J"},
    {"growl", "a low growl: a rattling low saw with noise",
     R"J({"format": "factoria.sfx/1", "doc": "A low growl: a saw with a slow wobble in its pitch and a fast rattle in its volume.", "length": 0.9,
  "layers": [
    {"pitch": {"freq": 95, "sweep": {"to": 70}, "vibrato": {"rate": 5, "depth": 85}},
     "oscillators": [{"wave": "saw"}, {"wave": "noise", "color": "brown", "gain": 0.7}],
     "filter": {"mode": "lowpass", "cutoff": 1600},
     "tremolo": {"rate": 28, "depth": 0.6},
     "amp": {"attack": 0.08, "decay": 0.82, "sustain": 0, "curve": 0.6}}],
  "master": {"effects": [{"type": "distortion", "mode": "soft", "drive": 1.6}]}})J"},
    {"meow", "a cat meow: a rising then falling vowel-like tone",
     R"J({"format": "factoria.sfx/1", "doc": "A cat meow: a triangle wave whose pitch rises and falls, with a little vibrato and breath.", "length": 0.7,
  "layers": [
    {"pitch": {"freq": 420, "env": {"amount": 6, "attack": 0.3, "decay": 0.4, "sustain": 0}, "vibrato": {"rate": 6, "depth": 50}},
     "oscillators": [{"wave": "triangle"}, {"wave": "noise", "gain": 0.08}],
     "filter": {"mode": "lowpass", "cutoff": 2500},
     "amp": {"attack": 0.06, "decay": 0.64, "sustain": 0, "curve": 1.2}}]})J"},
    {"screech", "a high rough screech",
     R"J({"format": "factoria.sfx/1", "doc": "A screech: a bright saw with a fast, wide vibrato and noise.", "length": 0.6,
  "layers": [
    {"pitch": {"freq": 1500, "sweep": {"to": 1100}, "vibrato": {"rate": 14, "depth": 100}},
     "oscillators": [{"wave": "saw"}, {"wave": "noise", "gain": 0.4}],
     "filter": {"mode": "lowpass", "cutoff": 7000},
     "amp": {"attack": 0.01, "decay": 0.59, "sustain": 0, "curve": 1}}]})J"},
    {"whoosh", "air passing: noise swelling and fading",
     R"J({"format": "factoria.sfx/1", "doc": "Air passing: noise whose filter opens as it swells and closes as it fades.", "length": 0.6,
  "layers": [
    {"oscillators": [{"wave": "noise", "color": "pink"}],
     "filter": {"mode": "lowpass", "cutoff": 600, "resonance": 1.5, "env": {"amount": 2, "attack": 0.2, "decay": 0.4, "sustain": 0}},
     "amp": {"attack": 0.2, "decay": 0.4, "sustain": 0, "curve": 1.5}}]})J"},
    {"explosion", "a blast: low rumble and a noise burst",
     R"J({"format": "factoria.sfx/1", "doc": "A blast: a sine that drops from 90 to 35 Hz under a burst of noise whose filter closes.", "length": 1.1,
  "layers": [
    {"name": "boom", "gain": 0.8, "pitch": {"freq": 90, "sweep": {"to": 35}},
     "oscillators": [{"wave": "sine"}],
     "amp": {"attack": 0.003, "decay": 1.097, "sustain": 0, "curve": 2}},
    {"name": "debris", "oscillators": [{"wave": "noise", "color": "white"}],
     "filter": {"mode": "lowpass", "cutoff": 500, "env": {"amount": 2.5, "decay": 1.0, "sustain": 0}},
     "amp": {"attack": 0.003, "decay": 1.097, "sustain": 0, "curve": 2}}],
  "master": {"effects": [{"type": "distortion", "mode": "soft", "drive": 1.8}]}})J"},
    {"hit", "an impact: a short thump with a click",
     R"J({"format": "factoria.sfx/1", "doc": "An impact: a square thump that drops from 220 to 60 Hz with a burst of noise on top.", "length": 0.18,
  "layers": [
    {"pitch": {"freq": 220, "sweep": {"to": 60}},
     "oscillators": [{"wave": "square"}, {"wave": "noise", "gain": 0.65}],
     "filter": {"mode": "lowpass", "cutoff": 4000},
     "amp": {"attack": 0.001, "decay": 0.179, "sustain": 0, "curve": 2.5}}]})J"},
    {"coin", "a coin pickup: two bright notes",
     R"J({"format": "factoria.sfx/1", "doc": "A coin: a thin square wave playing a note and then one a fourth higher (5 semitones).", "length": 0.35,
  "layers": [
    {"pitch": {"freq": 988, "arpeggio": {"steps": [0, 5], "rate": 7.1, "mode": "once"}},
     "oscillators": [{"wave": "square", "duty": 0.25}],
     "amp": {"attack": 0.002, "decay": 0.348, "sustain": 0, "curve": 1.3}}]})J"},
    {"pickup", "an item pickup: a quick rising blip",
     R"J({"format": "factoria.sfx/1", "doc": "An item pickup: a square wave that glides up an octave.", "length": 0.25,
  "layers": [
    {"pitch": {"freq": 440, "sweep": {"semitones": 12}},
     "oscillators": [{"wave": "square"}],
     "amp": {"attack": 0.002, "decay": 0.248, "sustain": 0, "curve": 1.2}}]})J"},
    {"jump", "a jump: a rising chirp",
     R"J({"format": "factoria.sfx/1", "doc": "A jump: a square wave that chirps up from 260 to 700 Hz.", "length": 0.28,
  "layers": [
    {"pitch": {"freq": 260, "sweep": {"to": 700}},
     "oscillators": [{"wave": "square"}],
     "amp": {"attack": 0.002, "decay": 0.278, "sustain": 0, "curve": 1.1}}]})J"},
    {"powerup", "a power-up: a fast rising arpeggio-like sweep",
     R"J({"format": "factoria.sfx/1", "doc": "A power-up: a square wave that sweeps up two octaves with a fast vibrato.", "length": 0.6,
  "layers": [
    {"pitch": {"freq": 330, "sweep": {"to": 1320}, "vibrato": {"rate": 18, "depth": 50}},
     "oscillators": [{"wave": "square"}],
     "amp": {"attack": 0.002, "decay": 0.598, "sustain": 0, "curve": 0.8}}]})J"},
    {"laser", "a laser shot: a quick falling zap",
     R"J({"format": "factoria.sfx/1", "doc": "A laser: a saw that falls from 1800 to 220 Hz in a third of a second.", "length": 0.3,
  "layers": [
    {"pitch": {"freq": 1800, "sweep": {"to": 220}},
     "oscillators": [{"wave": "saw"}, {"wave": "noise", "gain": 0.05}],
     "filter": {"mode": "lowpass", "cutoff": 7000},
     "amp": {"attack": 0.001, "decay": 0.299, "sustain": 0, "curve": 1.4}}]})J"},
    {"blip", "a UI blip: a very short tone",
     R"J({"format": "factoria.sfx/1", "doc": "A UI blip: a very short square tone.", "length": 0.08,
  "layers": [
    {"pitch": {"freq": 700},
     "oscillators": [{"wave": "square"}],
     "amp": {"attack": 0.001, "decay": 0.079, "sustain": 0, "curve": 1}}]})J"},
    {"click", "a UI click: a tiny noise tick",
     R"J({"format": "factoria.sfx/1", "doc": "A UI click: a tick of noise over a faint 1200 Hz tone.", "length": 0.04,
  "layers": [
    {"pitch": {"freq": 1200},
     "oscillators": [{"wave": "noise", "gain": 1}, {"wave": "sine", "gain": 0.3}],
     "filter": {"mode": "lowpass", "cutoff": 8000},
     "amp": {"attack": 0.0005, "decay": 0.0395, "sustain": 0, "curve": 2.5}}],
  "master": {"effects": [{"type": "distortion", "mode": "soft", "drive": 4}]}})J"},
    {"error", "a refusal buzz: two low square pulses",
     R"J({"format": "factoria.sfx/1", "doc": "A refusal: a low square buzz chopped into pulses.", "length": 0.4,
  "layers": [
    {"pitch": {"freq": 130, "sweep": {"to": 110}},
     "oscillators": [{"wave": "square"}, {"wave": "noise", "gain": 0.08}],
     "filter": {"mode": "lowpass", "cutoff": 3500},
     "tremolo": {"rate": 11, "depth": 0.9},
     "amp": {"attack": 0.003, "decay": 0.397, "sustain": 0, "curve": 0.5}}]})J"},
    {"splash", "water: a noisy plop that fades",
     R"J({"format": "factoria.sfx/1", "doc": "Water: a sine that drops from 500 to 150 Hz inside a wash of noise.", "length": 0.5,
  "layers": [
    {"pitch": {"freq": 500, "sweep": {"to": 150}},
     "oscillators": [{"wave": "sine", "gain": 0.4}, {"wave": "noise", "color": "pink", "gain": 1.2}],
     "filter": {"mode": "lowpass", "cutoff": 2500},
     "amp": {"attack": 0.005, "decay": 0.495, "sustain": 0, "curve": 2}}]})J"},
    {"footstep", "a soft footstep on dirt",
     R"J({"format": "factoria.sfx/1", "doc": "A footstep on dirt: a soft low thud and a puff of dull noise.", "length": 0.14,
  "layers": [
    {"pitch": {"freq": 110, "sweep": {"to": 70}},
     "oscillators": [{"wave": "sine", "gain": 0.4}, {"wave": "noise", "color": "brown", "gain": 1}],
     "filter": {"mode": "lowpass", "cutoff": 900},
     "amp": {"attack": 0.002, "decay": 0.138, "sustain": 0, "curve": 2.5}}]})J"},
};

}  // namespace

const std::vector<SfxPresetInfo>& sfx_presets() {
    static const std::vector<SfxPresetInfo> all = [] {
        std::vector<SfxPresetInfo> out;
        for (const Preset& p : kPresets) out.push_back({p.name, p.what});
        return out;
    }();
    return all;
}

std::optional<Json> sfx_preset_patch(std::string_view name) {
    for (const Preset& p : kPresets) {
        if (name != p.name) continue;
        auto json = parse_json(p.json, std::string("preset ") + p.name);
        if (json) return std::move(*json);  // the presets are checked by the tests, so this holds
        return std::nullopt;
    }
    return std::nullopt;
}

}  // namespace fa
