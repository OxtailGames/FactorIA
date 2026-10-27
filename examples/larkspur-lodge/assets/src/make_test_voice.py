"""Writes tests/fixtures/test_voice.wav: 2.5 seconds of a soft 220 Hz tone, 8 kHz mono 8-bit.

It stands in for a voice clip in tests/cutscene.test.js (the captions must last as long as the clip). It is NOT game audio and is not
shipped in the game: the real voice lines are made with assets.generate_voice (see README, "Cut-scenes (P4)").

    python3 -I assets/src/make_test_voice.py
"""
import math
import os
import wave

RATE = 8000
SECONDS = 2.5

here = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(here, "..", "..", "tests", "fixtures", "test_voice.wav")
frames = bytearray()
for i in range(int(RATE * SECONDS)):
    env = min(1.0, i / 400, (RATE * SECONDS - i) / 400)
    frames.append(int(128 + 40 * env * math.sin(2 * math.pi * 220 * i / RATE)))
with wave.open(out, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(1)
    w.setframerate(RATE)
    w.writeframes(bytes(frames))
print("wrote", os.path.normpath(out))
