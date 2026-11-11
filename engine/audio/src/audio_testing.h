// Hooks for fa_audio's own tests into the real-time path (private to fa_audio and its tests).
#pragma once

#include <cstddef>
#include <memory>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

#include "fa/audio/audio.h"
#include "fa/audio/music_player.h"
#include "fa/scene/world.h"
#include "music_stream.h"

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
    // The streams of the stems of the music cache's songs (every streamed stem, cache order).
    static std::vector<std::shared_ptr<audio_detail::MusicStemStream>> music_streams(Audio& audio);
    // One pass of the music service (what its thread does every few ms): decodes the streamed stems' missing chunks that the mixer
    // published as read soon. Takes no API lock and needs no call of the game. True when a chunk is still missing.
    static bool music_service_pass(Audio& audio);
    // How long the game waits for a stem the service is decoding (claim_wait, a safety net of 500 ms by default) on every streamed stem
    // of the cache: a test that holds a stem by hand gives it a limit a loaded machine cannot reach.
    static void set_claim_wait_limit(Audio& audio, int milliseconds);
    // Starts the music service's own thread on a manual device, as init() does with a real one (shutdown() stops it).
    static void start_music_thread(Audio& audio);
    // What a frame does with a device: commit, refill, take what came back.
    static void pump(Audio& audio);
    // The voices the game side still has in its mirror, stopped ones included: a voice leaves it only when the mixer says
    // it ended, so 0 means the mixer has acknowledged every stop (active_voices() does not count a stopped voice).
    static std::size_t mirror_voices(Audio& audio);
    // The mixer's position in a voice's clip, in 44100 Hz frames (-1: the mixer has no such voice). Read from the thread that
    // renders (the null device, or a manual device while nothing renders).
    static double voice_position(Audio& audio, VoiceId voice);
    // Commands waiting in the game side's staging queue (a stalled device).
    static std::size_t staged_commands(Audio& audio);
    // Sends `count` commands that must never be dropped (Keep, not mergeable) and do nothing: a stalled device's queue of
    // stops and removals, without the thousands of voices or tables a real one would take.
    static void stage_keeps(Audio& audio, std::size_t count);
    // What the mixer has of the music player of `e`: its transport's loop flag and the bus index of its channel (false /
    // -1 without a channel). Read from the thread that renders.
    static bool music_loop(Audio& audio, World& world, Entity e);
    static int music_channel_bus(Audio& audio, World& world, Entity e);
    // The songs the music cache holds ("song|mode") and their bytes, in key order.
    static std::vector<std::pair<std::string, std::size_t>> music_cache(Audio& audio);
    // Puts a ready-made source in the music cache, as a finished load would (its path and mode make the key): a song the loader would
    // refuse or that a file cannot make, such as one with more stems than a player mixes.
    static void put_music_source(Audio& audio, std::shared_ptr<const MusicSource> src);
};

}  // namespace fa
