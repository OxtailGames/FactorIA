// Hooks for fa_audio's own tests into the real-time path (private to fa_audio and its tests).
#pragma once

#include <cstddef>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

#include "fa/audio/audio.h"

namespace fa {

struct AudioTestAccess {
    // Runs the mixer as a device that the test drives: commands are staged and committed as with a real device, and
    // nothing mixes until render() is called (from any one thread at a time, as a device would).
    static void use_manual_device(Audio& audio, int rate);
    // The device callback.
    static void render(Audio& audio, float* out, int frames, int channels);
    // The mutex every API call holds; the callback must never need it.
    static std::recursive_mutex& api_mutex(Audio& audio);
    // The music cache's size limit (default 128 MB).
    static void set_music_cache_budget(Audio& audio, std::size_t bytes);
    // Off: no decode job refills the streamed voices (a test makes underruns).
    static void set_stream_service(Audio& audio, bool on);
    // What a frame does with a device: commit, refill, take what came back.
    static void pump(Audio& audio);
    // The songs the music cache holds ("song|mode") and their bytes, in key order.
    static std::vector<std::pair<std::string, std::size_t>> music_cache(Audio& audio);
};

}  // namespace fa
