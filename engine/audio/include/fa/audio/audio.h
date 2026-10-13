// Audio: software mixer (sokol_audio output) with WAV / OGG / MP3 clips.
//
// Headless runs use a null device: the mixer still runs deterministically and
// can record the mixed output to a WAV file, so AIs can verify that sounds
// play (`factoria run --headless --record-audio out.wav`). Every play request
// is also kept in a play log (play_log()) that tests and the `audio.log`
// command read to assert which sounds played, when, and on which bus.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/scene/world.h"

namespace fa {

using VoiceId = std::uint32_t;  // 0 = invalid

struct PlayParams {
    float volume = 1.0f;
    float pitch = 1.0f;
    float pan = 0.0f;  // -1 left .. 1 right
    bool loop = false;
    std::string bus = "sfx";  // "sfx" | "music" | "ui" — each bus has its own volume
};

// One play request, as recorded in the play log: play() calls (scripts), AudioSource components starting a clip and
// play_music() (scripts and SceneSettings.music). Failed requests are logged too, with ok = false.
struct AudioEvent {
    std::uint64_t seq = 0;    // increasing id (1, 2, ...); never reused, survives clear_play_log()
    std::uint64_t frame = 0;  // World::frame() of the clock world when requested (what scripts see as time.frame)
    double time = 0.0;        // World::time() of the clock world
    std::string path;         // normalized project-relative clip path
    float volume = 1.0f, pitch = 1.0f, pan = 0.0f;
    std::string bus = "sfx";
    bool loop = false;
    bool music = false;   // started through play_music()
    std::string source;   // entity id when an AudioSource component started it, "" otherwise
    bool ok = true;       // false when the clip could not be loaded (the error is logged once)
    Json to_json() const;
};

class Audio {
public:
    Audio();
    ~Audio();

    // device=false -> null output (headless). sampleRate 44100 stereo float.
    bool init(bool device, std::string* error);
    void shutdown();

    // Preload (optional; play() loads on demand). Returns false + logs a
    // helpful error if the file is missing or unsupported.
    bool load(std::string_view clipPath);
    VoiceId play(std::string_view clipPath, const PlayParams& params = {});
    void stop(VoiceId voice);
    void stop_all();
    bool is_playing(VoiceId voice) const;
    void set_voice_volume(VoiceId voice, float volume);
    void set_bus_volume(std::string_view bus, float volume);
    void set_master_volume(float volume);
    void play_music(std::string_view clipPath, float volume = 0.6f, float fadeSeconds = 0.5f);
    void stop_music(float fadeSeconds = 0.5f);

    // Play log (game thread). Entries are stamped with the frame/time of `world` (the engine passes its World; null =
    // the world of the last update()). The log keeps the newest 4096 entries; play_log_dropped() counts the rest.
    void set_clock(const World* world);
    std::vector<AudioEvent> play_log(std::uint64_t afterSeq = 0) const;
    void clear_play_log();
    std::uint64_t play_log_dropped() const;

    // Drives AudioSource/AudioListener components and scene music.
    void update(World& world, float dt);

    // Headless: mix `seconds` of audio (called by the engine per frame with dt).
    void advance_null_device(double seconds);
    // Recording of the mixed output (any mode). Stops + writes on stop_recording.
    void start_recording();
    bool stop_recording(std::string_view wavPath, std::string* error);

    Json stats() const;  // active voices, loaded clips, peak level of last frame

    void reload_clip(std::string_view path);  // hot reload

    struct Impl;

private:
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
