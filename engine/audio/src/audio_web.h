// The web's audio device (audio_web.cpp): an AudioWorkletNode fed by messages, a ScriptProcessorNode where worklets are missing.
#pragma once

namespace fa {

using WebAudioCallback = void (*)(float* interleaved, int frames, int channels, void* user);

/// Opens the browser's audio output. `callback` mixes `frames` interleaved frames; it is called on the main thread, in chunks.
/// Returns the context's real sample rate, or 0 when the browser has no WebAudio.
int audio_web_open(int rate, int channels, WebAudioCallback callback, void* user);
void audio_web_close();
void audio_web_unlock();

}  // namespace fa
