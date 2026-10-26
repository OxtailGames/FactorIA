#!/usr/bin/env python3
"""Synthesises the four seasonal music loops of Tidewater Market (pure Python, standard library only).

    python3 -I assets/src/make_music.py OUT_DIR

writes spring.wav, summer.wav, autumn.wav and winter.wav (16 kHz, mono, 16 bit, about 12 s each) into OUT_DIR. The
loops are made of a soft pad (one chord a bar), a bass note on the first beat and a melody picked from the scale by a
fixed pseudo-random sequence, so running the script again gives the same bytes. Every note is rendered into a ring
buffer (the tail of a note at the end of the loop wraps around to the start), so the loop has no click and no gap.

The files are then brought into the game with the engine's assets.import (license CC0-1.0, author "Tidewater Market
(original, assets/src/make_music.py)", ai false); see assets.json. Nothing here is a sample of anyone's recording.
"""
import math
import struct
import sys
import wave

SR = 16000

# Notes as semitones above C4 (MIDI 60); a scale is a list of offsets from its root.
MAJOR = [0, 2, 4, 5, 7, 9, 11]
PENTA = [0, 2, 4, 7, 9]
MINOR = [0, 2, 3, 5, 7, 8, 10]
DORIAN = [0, 2, 3, 5, 7, 9, 10]

SEASONS = {
    # root = semitone of the key, chords = the root of each bar's chord as a scale degree offset in semitones and its quality
    "spring": dict(bpm=80, root=0, scale=PENTA, chords=[(0, "maj"), (5, "maj"), (7, "maj"), (5, "maj")], pluck=1.0, pad=0.55, shaker=0.0, density=0.55, seed=11),
    "summer": dict(bpm=92, root=7, scale=MAJOR, chords=[(0, "maj"), (7, "maj"), (9, "min"), (5, "maj")], pluck=0.9, pad=0.45, shaker=0.5, density=0.8, seed=23),
    "autumn": dict(bpm=76, root=9, scale=MINOR, chords=[(0, "min"), (8, "maj"), (3, "maj"), (7, "maj")], pluck=0.8, pad=0.8, shaker=0.0, density=0.45, seed=37),
    "winter": dict(bpm=64, root=2, scale=DORIAN, chords=[(0, "min"), (5, "maj"), (10, "maj"), (7, "min")], pluck=0.7, pad=0.7, shaker=0.0, density=0.3, seed=53),
}
CHORD = {"maj": [0, 4, 7], "min": [0, 3, 7]}


def freq(semitones_above_c4):
    return 261.6256 * 2 ** (semitones_above_c4 / 12.0)


class Lcg:
    """A tiny deterministic random sequence (the loops must come out the same every time)."""

    def __init__(self, seed):
        self.s = seed * 2654435761 % 2**32

    def next(self):
        self.s = (self.s * 1664525 + 1013904223) % 2**32
        return self.s / 2**32


class Loop:
    def __init__(self, seconds):
        self.n = int(round(seconds * SR))
        self.buf = [0.0] * self.n

    def add(self, start, dur, hz, amp, harmonics, attack, decay_rate):
        """A note: sum of harmonics with a fast attack and an exponential decay, wrapped around the loop end."""
        n0 = int(start * SR)
        count = int(dur * SR)
        buf = self.buf
        size = self.n
        att = max(1, int(attack * SR))
        for i in range(count):
            t = i / SR
            env = math.exp(-decay_rate * t)
            if i < att:
                env *= i / att
            if i > count - 400:
                env *= (count - i) / 400.0
            ph = 2 * math.pi * hz * t
            v = 0.0
            for k, a in harmonics:
                v += a * math.sin(ph * k)
            buf[(n0 + i) % size] += amp * env * v

    def noise(self, start, dur, amp, rng):
        n0 = int(start * SR)
        count = int(dur * SR)
        for i in range(count):
            env = math.exp(-60.0 * i / SR)
            self.buf[(n0 + i) % self.n] += amp * env * (rng.next() * 2 - 1)

    def write(self, path, peak=0.55):
        top = max(abs(x) for x in self.buf) or 1.0
        scale = peak / top
        with wave.open(path, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x * scale)) * 32767)) for x in self.buf))


def make(name, cfg):
    rng = Lcg(cfg["seed"])
    beat = 60.0 / cfg["bpm"]
    bar = 4 * beat
    bars = len(cfg["chords"])
    loop = Loop(bar * bars)
    root = cfg["root"]
    soft = [(1, 1.0), (2, 0.25), (3, 0.08)]
    bell = [(1, 1.0), (2.76, 0.35), (5.4, 0.12)]
    pluck = [(1, 1.0), (2, 0.5), (3, 0.25), (4, 0.1)]
    for b, (offset, quality) in enumerate(cfg["chords"]):
        t0 = b * bar
        base = root + offset
        # pad: the chord held for the whole bar, with a slow swell
        for tone in CHORD[quality]:
            loop.add(t0, bar * 1.15, freq(base + tone - 12), 0.16 * cfg["pad"], soft, 0.6, 0.35)
        # bass on the first beat and (spring/summer) the third
        loop.add(t0, beat * 1.8, freq(base - 24), 0.30, [(1, 1.0), (2, 0.3)], 0.02, 1.6)
        if cfg["bpm"] > 85:
            loop.add(t0 + 2 * beat, beat * 1.2, freq(base - 24 + 7), 0.2, [(1, 1.0), (2, 0.3)], 0.02, 2.0)
        # melody: eighth-note slots, each played with probability `density`, a note of the scale around the chord
        degrees = cfg["scale"]
        for slot in range(8):
            if rng.next() > cfg["density"]:
                continue
            step = int(rng.next() * len(degrees) * 2)
            note = root + degrees[step % len(degrees)] + 12 * (step // len(degrees)) + 12
            ts = t0 + slot * beat / 2
            timbre = bell if name == "winter" else pluck
            loop.add(ts, beat * (3.0 if name == "winter" else 1.6), freq(note), 0.22 * cfg["pluck"], timbre, 0.008, 2.4 if name != "winter" else 1.3)
        if cfg["shaker"] > 0:
            for slot in range(8):
                loop.noise(t0 + slot * beat / 2, 0.06, 0.05 * cfg["shaker"] * (1.0 if slot % 2 else 0.6), rng)
    return loop


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    out = sys.argv[1]
    for name, cfg in SEASONS.items():
        loop = make(name, cfg)
        loop.write(f"{out}/{name}.wav")
        print(f"{name}.wav  {loop.n / SR:.1f} s")


if __name__ == "__main__":
    main()
