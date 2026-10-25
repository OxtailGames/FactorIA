#!/usr/bin/env python3
"""Synthesises the music LAYERS of Burrow Brigade (P6), with only the standard library:

  python3 -I make_music_layers.py <out-dir>
      writes music_<stratum>_danger.wav and music_<stratum>_fight.wav for topsoil, crystal and magma

A layer is ONE BAR long, the bar of its stratum's track (assets/src/make_music.py: 4 beats at 96, 76 and 112 bpm), and is
nearly all percussion plus a low drone on the tonic, so it fits whatever chord the track plays. scripts/game/music.js starts
a layer on a bar line of the track and stops it on another, which is how the music "rises" in a chase: the engine plays one
music stream and cannot change the volume of a playing sound, so a layer is a short loop that is started and stopped
(FB-0026). Notes that ring past the end of the bar wrap to its start, so the loop has no click. 22050 Hz, mono, 16 bit.
Deterministic (a tiny LCG with a fixed seed); original work of this project, CC0.

  danger  a heartbeat (two low thumps a bar) over a quiet drone: something is hunting
  fight   eighth-note ticks and a snare on beats 2 and 4, a low pulse: the pick is out
"""
import math
import os
import struct
import sys
import wave

RATE = 22050
BPM = {"topsoil": 96, "crystal": 76, "magma": 112}
TONIC = {"topsoil": 38, "crystal": 33, "magma": 38}  # midi: D2, A1, D2


class Lcg:
    def __init__(self, seed):
        self.s = seed & 0xFFFFFFFF

    def noise(self):
        self.s = (self.s * 1664525 + 1013904223) & 0xFFFFFFFF
        return ((self.s >> 8) & 0xFFFF) / 32768.0 - 1.0


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def put(buf, start, samples):
    n = len(buf)
    i0 = int(start * RATE)
    for k, v in enumerate(samples):
        buf[(i0 + k) % n] += v


def thump(length, f0, f1, vol):
    out = []
    ph = 0.0
    for k in range(int(length * RATE)):
        t = k / RATE
        f = f1 + (f0 - f1) * math.exp(-t * 30)
        ph += 2 * math.pi * f / RATE
        out.append(vol * math.sin(ph) * math.exp(-t * 11))
    return out


def tick(rng, length, vol, bright):
    out = []
    last = 0.0
    for k in range(int(length * RATE)):
        t = k / RATE
        x = rng.noise()
        hp = x - last * bright  # a crude high-pass: more of the previous sample removed = brighter
        last = x
        out.append(vol * hp * math.exp(-t * 60))
    return out


def snare(rng, vol):
    body = tick(rng, 0.16, vol, 0.4)
    tone = [vol * 0.5 * math.sin(2 * math.pi * 190 * k / RATE) * math.exp(-k / RATE * 28) for k in range(len(body))]
    return [a + b for a, b in zip(body, tone)]


def drone(buf, midi, vol):
    n = len(buf)
    f = hz(midi)
    # a whole number of cycles per bar so the loop is seamless: round the frequency to the nearest one
    cycles = max(1, round(f * n / RATE))
    f = cycles * RATE / n
    for k in range(n):
        buf[k] += vol * math.sin(2 * math.pi * f * k / RATE)


def render(stratum, kind):
    beat = 60.0 / BPM[stratum]
    n = int(4 * beat * RATE)
    buf = [0.0] * n
    rng = Lcg({"danger": 101, "fight": 202}[kind] + len(stratum))
    if kind == "danger":
        drone(buf, TONIC[stratum], 0.10)
        for b in (0.0, 1.0, 2.0, 3.0):  # a heartbeat: a strong thump and a weak one, twice a bar
            put(buf, b * beat * 1.0, thump(0.3, 95, 48, 0.9 if int(b) % 2 == 0 else 0.55))
            put(buf, b * beat + 0.28 * beat, thump(0.22, 80, 45, 0.45 if int(b) % 2 == 0 else 0.0))
    else:
        for i in range(8):
            put(buf, i * beat * 0.5, tick(rng, 0.05, 0.5 if i % 2 == 0 else 0.3, 0.95))
        for b in (1, 3):
            put(buf, b * beat, snare(rng, 0.7))
        for b in (0, 2):
            put(buf, b * beat, thump(0.25, 110, 55, 0.8))
        drone(buf, TONIC[stratum] + 12, 0.05)
    peak = max(abs(x) for x in buf) or 1.0
    return [x / peak * 0.8 for x in buf]


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
    for stratum in BPM:
        for kind in ("danger", "fight"):
            samples = render(stratum, kind)
            write_wav(os.path.join(out, f"music_{stratum}_{kind}.wav"), samples)
            print(f"music_{stratum}_{kind}.wav: {len(samples) / RATE:.3f} s")


if __name__ == "__main__":
    main()
