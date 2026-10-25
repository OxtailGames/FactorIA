#!/usr/bin/env python3
"""Synthesises the three looping music tracks of Burrow Brigade, one per stratum, with only the standard library:

  python3 -I make_music.py <out-dir>      # writes music_topsoil.wav, music_crystal.wav, music_magma.wav

Each track is 8 bars of 4 beats made of a bass line, a slow pad and a seeded melody on a fixed scale (a tiny LCG with
a fixed seed, so running it again gives the same bytes). Notes that ring past the last sample wrap around to the
start, so the loop has no click and no gap. 22050 Hz, mono, 16 bit. The tracks are original work of this project and
CC0 (the notes are generated, not taken from anywhere). They are imported with assets.import, which records the
provenance in assets.json.

  topsoil  96 bpm, D major pentatonic, plucked and warm
  crystal  76 bpm, A minor with a raised 4th, glassy bell notes over a wide pad
  magma    112 bpm, D phrygian, a low pulsing bass with a dark pad and a sparse brass-like lead
"""
import math
import os
import struct
import sys
import wave

RATE = 22050


class Lcg:
    def __init__(self, seed):
        self.s = seed & 0xFFFFFFFF

    def next(self):
        self.s = (self.s * 1664525 + 1013904223) & 0xFFFFFFFF
        return self.s >> 8

    def pick(self, items):
        return items[self.next() % len(items)]


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def tone(kind, f, t):
    ph = (f * t) % 1.0
    if kind == "sine":
        return math.sin(2 * math.pi * ph)
    if kind == "tri":
        return 4 * abs(ph - 0.5) - 1
    if kind == "saw":
        return 2 * ph - 1
    if kind == "square":
        return 1.0 if ph < 0.5 else -1.0
    raise ValueError(kind)


def add_note(buf, start, length, midi, kind, vol, attack=0.01, release=0.25, decay=0.0, vibrato=0.0):
    """Mixes one note into the loop; what rings past the end wraps to the start."""
    n = len(buf)
    f = hz(midi)
    total = int((length + release) * RATE)
    i0 = int(start * RATE)
    for k in range(total):
        t = k / RATE
        if t < attack:
            env = t / attack
        elif t < length:
            env = math.exp(-decay * (t - attack))
        else:
            env = math.exp(-decay * (length - attack)) * max(0.0, 1.0 - (t - length) / release)
        ff = f * (1.0 + vibrato * math.sin(2 * math.pi * 5.0 * t)) if vibrato else f
        buf[(i0 + k) % n] += vol * env * tone(kind, ff, t)


def render(spec):
    beat = 60.0 / spec["bpm"]
    bars = 8
    n = int(bars * 4 * beat * RATE)
    buf = [0.0] * n
    rng = Lcg(spec["seed"])
    for bar in range(bars):
        root = spec["chords"][bar % len(spec["chords"])]
        t0 = bar * 4 * beat
        # pad: the chord held for the whole bar
        for i, iv in enumerate(spec["chord"]):
            add_note(buf, t0, 4 * beat, root + 12 + iv, spec["pad"], spec["padVol"], attack=0.4, release=0.8)
        # bass
        for b, step in enumerate(spec["bassPattern"]):
            if step is None:
                continue
            add_note(buf, t0 + b * beat * spec["bassStep"], beat * spec["bassStep"] * 0.9, root + step, spec["bass"],
                     spec["bassVol"], attack=0.01, release=0.12, decay=spec["bassDecay"])
        # melody: on some eighth slots, a note of the scale
        for slot in range(8):
            if rng.next() % 100 < spec["density"]:
                note = root + 12 + rng.pick(spec["scale"]) + (12 if rng.next() % 4 == 0 else 0)
                add_note(buf, t0 + slot * beat * 0.5, beat * 0.5 * spec["noteLen"], note, spec["lead"], spec["leadVol"],
                         attack=0.005, release=spec["leadRelease"], decay=spec["leadDecay"], vibrato=spec["vibrato"])
    peak = max(abs(x) for x in buf) or 1.0
    return [x / peak * 0.8 for x in buf]


SPECS = {
    "topsoil": dict(
        seed=11, bpm=96, chords=[50, 55, 57, 55, 50, 55, 59, 57], chord=[0, 7, 12], pad="tri", padVol=0.10,
        bass="tri", bassVol=0.35, bassStep=1.0, bassPattern=[0, None, 7, None], bassDecay=2.0,
        scale=[0, 2, 4, 7, 9], density=55, noteLen=1.6, lead="tri", leadVol=0.30, leadRelease=0.25, leadDecay=5.0,
        vibrato=0.0),
    "crystal": dict(
        seed=23, bpm=76, chords=[45, 41, 43, 40, 45, 41, 38, 40], chord=[0, 7, 15], pad="sine", padVol=0.16,
        bass="sine", bassVol=0.30, bassStep=2.0, bassPattern=[0, None], bassDecay=0.6,
        scale=[0, 3, 6, 7, 10], density=45, noteLen=3.0, lead="sine", leadVol=0.34, leadRelease=0.9, leadDecay=2.5,
        vibrato=0.003),
    "magma": dict(
        seed=37, bpm=112, chords=[38, 38, 39, 38, 41, 38, 39, 37], chord=[0, 7, 12], pad="saw", padVol=0.045,
        bass="square", bassVol=0.17, bassStep=0.5, bassPattern=[0, 0, None, 0, 0, None, 7, 0], bassDecay=4.5,
        scale=[0, 1, 4, 5, 7], density=30, noteLen=2.0, lead="saw", leadVol=0.14, leadRelease=0.2, leadDecay=3.0,
        vibrato=0.004),
}


def write_wav(path, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, spec in SPECS.items():
        samples = render(spec)
        write_wav(os.path.join(out, f"music_{name}.wav"), samples)
        print(f"music_{name}.wav: {len(samples) / RATE:.1f} s")


if __name__ == "__main__":
    main()
