# Builds the audio fixtures of the streaming tests (test_streaming.cpp) with Blender's audio library, no other tool needed:
#
#   music_3min.ogg  a quiet 220 Hz tone (-26 dBFS) with a 0.1 s, 1 kHz beep (-6 dBFS) at 10 s, 20 s ... 170 s, so a test can
#                   tell from the samples that played that the whole length was decoded, and where it is. 3 minutes,
#                   mono, 11025 Hz, Vorbis at about 16 kbit/s (about 150 KB).
#   tone_12s.mp3    a 12 s, 440 Hz tone at amplitude 0.3: long enough to stream by default, the only MP3 in the tests.
#
# Run it from the repository root (Blender 5.2 on Windows: "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"):
#
#   blender -b --factory-startup --python engine/audio/tests/fixtures/make_fixtures.py -- engine/audio/tests/fixtures
import os
import sys

import aud

out = sys.argv[sys.argv.index("--") + 1]

RATE, SECONDS, BEEP_EVERY = 11025, 180, 10
music = aud.Sound.sine(220, RATE).volume(0.05).limit(0, SECONDS)
beep = aud.Sound.sine(1000, RATE).volume(0.5).limit(0, 0.1)
for t in range(BEEP_EVERY, SECONDS, BEEP_EVERY):
    music = music.mix(beep.delay(t))
music.write(os.path.join(out, "music_3min.ogg"), rate=RATE, channels=aud.CHANNELS_MONO, format=aud.FORMAT_S16,
            container=aud.CONTAINER_OGG, codec=aud.CODEC_VORBIS, bitrate=16000)

tone = aud.Sound.sine(440, 22050).volume(0.3).limit(0, 12)
tone.write(os.path.join(out, "tone_12s.mp3"), rate=22050, channels=aud.CHANNELS_MONO, format=aud.FORMAT_S16,
           container=aud.CONTAINER_MP3, codec=aud.CODEC_MP3, bitrate=32000)
