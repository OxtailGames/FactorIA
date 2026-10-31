#!/usr/bin/env python3
"""Synthesises the three ambience beds of Tidewater Market (pure Python, standard library only).

    python3 -I assets/src/make_ambience.py OUT_DIR

writes sea.wav, market.wav and wind.wav (16 kHz, mono, 16 bit, 8 s each) into OUT_DIR. Each one is filtered noise shaped
by slow cycles that fit a whole number of times in the loop (waves, a murmur of voices with now and then a clink, gusts),
and the last 0.5 s are cross-faded into the first 0.5 s, so the loop has no click. A fixed pseudo-random generator makes
the same bytes every run. Nothing here is a sample of anyone's recording; the files are imported with the engine's
assets.import (license CC0-1.0, author "Tidewater Market (original, assets/src/make_ambience.py)", ai false).
"""
import math
import random
import struct
import sys
import wave

SR = 16000
SECONDS = 8
N = SR * SECONDS
FADE = SR // 2


def noise(rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(N + FADE)]


def lowpass(x, a):
    y, s = [], 0.0
    for v in x:
        s += a * (v - s)
        y.append(s)
    return y


def highpass(x, a):
    lp = lowpass(x, a)
    return [v - l for v, l in zip(x, lp)]


def cycle(i, per_loop, phase=0.0):
    """A sine that runs `per_loop` whole times in the loop, 0..1."""
    return 0.5 + 0.5 * math.sin(2 * math.pi * (per_loop * i / N + phase))


def loopable(x):
    """Cross-fade the tail (the FADE samples past the loop) into the head, then cut to N samples."""
    out = x[:N]
    for i in range(FADE):
        t = i / FADE
        out[i] = out[i] * t + x[N + i] * (1.0 - t)
    return out


def normalise(x, peak):
    m = max(abs(v) for v in x) or 1.0
    return [v * peak / m for v in x]


def sea(rng):
    base = lowpass(noise(rng), 0.06)
    surf = highpass(lowpass(noise(rng), 0.35), 0.2)
    x = []
    for i in range(N + FADE):
        swell = cycle(i, 4) ** 2 * 0.7 + cycle(i, 1, 0.3) * 0.3
        x.append(base[i] * (0.5 + 0.5 * swell) * 3.0 + surf[i] * swell * 0.9)
    return normalise(loopable(x), 0.8)


def market(rng):
    murmur = highpass(lowpass(noise(rng), 0.16), 0.03)
    x = []
    for i in range(N + FADE):
        talk = 0.55 + 0.45 * cycle(i, 11, 0.1) * cycle(i, 3, 0.6)
        x.append(murmur[i] * talk * 2.2)
    for _ in range(14):  # clinks of coins and pots: short decaying sines
        at = rng.randrange(0, N)
        f = rng.choice([1800, 2400, 3100, 3700])
        amp = rng.uniform(0.1, 0.25)
        for k in range(1800):
            j = (at + k) % N
            x[j] += amp * math.sin(2 * math.pi * f * k / SR) * math.exp(-k / 260.0)
    return normalise(loopable(x), 0.7)


def wind(rng):
    body = highpass(lowpass(noise(rng), 0.12), 0.01)
    x = []
    for i in range(N + FADE):
        gust = 0.25 + 0.75 * cycle(i, 2, 0.2) ** 2
        x.append(body[i] * gust * 3.0)
    return normalise(loopable(x), 0.7)


def write(path, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in samples))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    write(f"{out}/sea.wav", sea(random.Random(101)))
    write(f"{out}/market.wav", market(random.Random(202)))
    write(f"{out}/wind.wav", wind(random.Random(303)))


if __name__ == "__main__":
    main()
