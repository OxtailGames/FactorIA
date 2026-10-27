"""Writes the ambience beds and the music of Larkspur Lodge into assets/audio/ (mono 16-bit WAV, seamless loops).

No CC0 pack the project could download has wind, a fire, a clock or a mountain-lodge score, so these are made here, from
nothing but a seeded random generator and a few sines (no recording, no sample, no AI): they are the author's own work and CC0.
The footsteps and the bell are Kenney's Impact Sounds (assets.json says so). Run it again after editing it, then record the
files with the provenance in assets.json (origin "original"):

    python3 -I assets/src/make_sound.py

Every file is a loop: tails wrap round to the start, so there is no click at the seam. The same script always writes the same bytes.
"""
import math
import os
import random
import struct
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "audio"))
TAU = 2 * math.pi


def write(name, samples, rate, peak=0.8):
    """Normalises to `peak` and writes a 16-bit mono WAV."""
    top = max(1e-9, max(abs(s) for s in samples))
    data = struct.pack("<%dh" % len(samples), *[int(max(-1.0, min(1.0, s / top * peak)) * 32767) for s in samples])
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(data)
    print("wrote", path, "%.1f s" % (len(samples) / rate))


def lowpass(x, k):
    """One-pole low-pass, k in 0..1 (bigger = brighter); the state is carried round the loop once so the seam is smooth."""
    y = []
    s = 0.0
    for _ in range(2):
        y = []
        for v in x:
            s += (v - s) * k
            y.append(s)
    return y


def wrap_add(buf, start, signal, gain=1.0):
    """Adds `signal` to the loop at `start`, wrapping round the end."""
    n = len(buf)
    for i, v in enumerate(signal):
        buf[(start + i) % n] += v * gain


# ------------------------------------------------------------------------------------------------------------ ambience
def wind():
    rate, secs = 22050, 20
    n = rate * secs
    rng = random.Random(11)
    noise = [rng.uniform(-1, 1) for _ in range(n)]
    dark = lowpass(noise, 0.035)
    mid = lowpass(noise, 0.12)
    out = []
    for i in range(n):
        t = i / rate
        # gusts: slow swells whose periods divide the loop (20 s), so the end meets the start
        gust = 0.55 + 0.25 * math.sin(TAU * t / 20 * 1) + 0.15 * math.sin(TAU * t / 20 * 3 + 1.3) + 0.08 * math.sin(TAU * t / 20 * 7 + 0.4)
        mix = 0.5 + 0.5 * math.sin(TAU * t / 20 * 2 + 0.7)
        whistle = 0.05 * math.sin(TAU * (380 + 40 * math.sin(TAU * t / 20 * 5)) * t) * max(0.0, math.sin(TAU * t / 20 * 3 + 2.0))
        out.append((dark[i] * (1 - mix) * 3.0 + mid[i] * mix * 1.6) * gust + whistle)
    write("wind.wav", out, rate, 0.7)


def fire():
    rate, secs = 22050, 12
    n = rate * secs
    rng = random.Random(23)
    noise = [rng.uniform(-1, 1) for _ in range(n)]
    out = [v * 0.9 for v in lowpass(noise, 0.02)]  # the low roar of the logs
    flick = lowpass([rng.uniform(-1, 1) for _ in range(n)], 0.0006)
    out = [v * (1.0 + 2.5 * f) for v, f in zip(out, flick)]
    # crackles: short noisy pops with a fast decay
    pops = 46
    for _ in range(pops):
        at = rng.randrange(n)
        length = int(rate * rng.uniform(0.004, 0.03))
        gain = rng.uniform(0.15, 0.9) * (1.6 if rng.random() < 0.12 else 1.0)
        pop = [rng.uniform(-1, 1) * math.exp(-i / (length / 3.5)) for i in range(length)]
        wrap_add(out, at, pop, gain)
    write("fire.wav", out, rate, 0.7)


def clock():
    rate, secs = 22050, 4
    n = rate * secs
    out = [0.0] * n
    for k in range(4):
        # tick (higher), tock (lower): a short click, a woody knock and a faint ring of the movement
        high = k % 2 == 0
        f = 2300 if high else 1750
        body = 640 if high else 520
        length = int(rate * 0.25)
        rng = random.Random(100 + k)
        sig = []
        for i in range(length):
            t = i / rate
            click = rng.uniform(-1, 1) * math.exp(-t / 0.0015) * 0.9
            ring = math.sin(TAU * f * t) * math.exp(-t / 0.012) * 0.5
            knock = math.sin(TAU * body * t) * math.exp(-t / 0.03) * 0.7
            sig.append(click + ring + knock)
        wrap_add(out, int(rate * k * 1.0), sig, 1.0)
    write("clock.wav", out, rate, 0.5)


def cellar():
    rate, secs = 22050, 12
    n = rate * secs
    rng = random.Random(37)
    out = []
    for i in range(n):
        t = i / rate
        hum = 0.5 * math.sin(TAU * 55 * t) + 0.25 * math.sin(TAU * 110 * t + 0.5) * (0.6 + 0.4 * math.sin(TAU * t / 12 * 3))
        out.append(hum)
    air = lowpass([rng.uniform(-1, 1) for _ in range(n)], 0.015)
    out = [h * 0.35 + a * 1.2 for h, a in zip(out, air)]
    for at in (1.3, 4.9, 7.2, 10.6):
        # a drip: a falling little sine, then its echo off the stone
        for echo, gain in ((0.0, 1.0), (0.23, 0.35), (0.41, 0.15)):
            length = int(rate * 0.18)
            sig = [math.sin(TAU * (1500 - 900 * (i / length)) * i / rate) * math.exp(-i / rate / 0.035) * 0.55 for i in range(length)]
            wrap_add(out, int(rate * (at + echo)), sig, gain)
    write("cellar_air.wav", out, rate, 0.6)


# ---------------------------------------------------------------------------------------------------------------- music
def note_freq(name):
    names = {"C": 0, "C#": 1, "D": 2, "Eb": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "Ab": 8, "A": 9, "Bb": 10, "B": 11}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + 12 * (octave + 1) - 69) / 12)


def pad(buf, rate, start, secs, freq, gain, bright=0.35):
    """A soft sustained note: three detuned partials with a slow attack and release, wrapped round the loop."""
    length = int(rate * secs)
    att = rate * 1.6
    rel = rate * 2.2
    sig = []
    for i in range(length):
        env = min(1.0, i / att, (length - i) / rel)
        t = i / rate
        v = (math.sin(TAU * freq * t) + 0.5 * math.sin(TAU * freq * 1.003 * t + 1.0) + bright * math.sin(TAU * freq * 2 * t)) * env
        sig.append(v)
    wrap_add(buf, int(rate * start), sig, gain)


def pluck(buf, rate, start, freq, gain, ring=1.6):
    """A music-box note: a bright sine that dies away."""
    length = int(rate * ring * 2)
    sig = [(math.sin(TAU * freq * i / rate) + 0.3 * math.sin(TAU * freq * 3 * i / rate) * math.exp(-i / rate / 0.15)) * math.exp(-i / rate / ring) for i in range(length)]
    wrap_add(buf, int(rate * start), sig, gain)


def piece(name, chords, bar, arp, arp_step, arp_gain, bass=0.5, bright=0.35, seed=1, mood_drone=None):
    """chords: lists of note names, one per bar of `bar` seconds; arp: indexes into the chord played every `arp_step` seconds."""
    rate = 16000
    secs = bar * len(chords)
    buf = [0.0] * int(rate * secs)
    rng = random.Random(seed)
    for b, chord in enumerate(chords):
        start = b * bar
        for note in chord:
            pad(buf, rate, start - 0.2, bar + 1.2, note_freq(note), 0.22, bright)
        pad(buf, rate, start - 0.2, bar + 1.2, note_freq(chord[0]) / 2, bass, 0.1)
        if arp:
            steps = int(bar / arp_step)
            for s in range(steps):
                idx = arp[(b * steps + s) % len(arp)]
                if idx is None:
                    continue
                note = chord[idx % len(chord)]
                oct_up = 2 if idx >= len(chord) else 1
                pluck(buf, rate, start + s * arp_step + rng.uniform(0, 0.02), note_freq(note) * oct_up, arp_gain)
    if mood_drone:
        pad(buf, rate, 0, secs, note_freq(mood_drone), 0.5, 0.05)
    write(name, buf, rate, 0.55)


def music():
    # title: Am F C G, slow, an open music box
    piece("music_title.wav", [["A3", "C4", "E4"], ["F3", "A3", "C4"], ["C3", "E4", "G4"], ["G3", "B3", "D4"]], 6.0, [2, 1, 0, 1, 2, 3, 1, 0], 1.5, 0.22, seed=1)
    # 1 the arrival: warm, a little wistful, lamp-lit (Dm Bb F C)
    piece("music_ch1.wav", [["D3", "F3", "A3"], ["Bb2", "D3", "F3"], ["F3", "A3", "C4"], ["C3", "E3", "G3"]], 6.0, [0, 2, 1, 2, 0, 1, 2, 1], 0.75, 0.16, seed=2, bright=0.25)
    # 2 the guests: gentler, a waltz-ish feel (G Em C D)
    piece("music_ch2.wav", [["G3", "B3", "D4"], ["E3", "G3", "B3"], ["C3", "E3", "G3"], ["D3", "F#3", "A3"]], 6.0, [0, 1, 2, None, 1, 2], 1.0, 0.16, seed=3, bright=0.3)
    # 3 the clues: unease, a repeated figure over minor colours (Em C Am B-ish)
    piece("music_ch3.wav", [["E3", "G3", "B3"], ["C3", "E3", "G3"], ["A2", "C3", "E3"], ["B2", "D#3" if False else "Eb3", "F#3"]], 6.0, [0, 2, 0, 1, 2, 1, 0, 2], 0.5, 0.15, seed=4, bright=0.2)
    # 4 the dark: the power is out - bare fifths, a low drone and a very sparse bell
    piece("music_ch4.wav", [["D2", "A2", "D3"], ["D2", "A2", "Eb3"], ["Bb1", "F2", "Bb2"], ["A1", "E2", "A2"]], 6.0, [2, None, None, None, 1, None, None, None], 1.5, 0.14, bass=0.7, seed=5, bright=0.08, mood_drone="D1")
    # 5 the dawn: the storm has gone, a brighter turn (C G Am F, then Fmaj7 feel)
    piece("music_ch5.wav", [["C3", "E3", "G3"], ["G3", "B3", "D4"], ["A3", "C4", "E4"], ["F3", "A3", "C4"]], 6.0, [0, 1, 2, 1, 2, 1, 0, 1], 0.75, 0.2, seed=6, bright=0.4)


if __name__ == "__main__":
    wind()
    fire()
    clock()
    cellar()
    music()
