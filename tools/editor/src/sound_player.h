// Plays a rendered sound for the editor's Sound panels (Sound now, Music later) with no ImGui: a PCM voice of the engine's mixer that the
// player feeds a quarter of a second ahead, so a loop, a selection, a seek and an A/B switch are all just "what to push next". The playhead is
// what has been pushed minus what still waits in the voice's queue, so it is where the sound actually is.
//
// With a real output device the mixer pulls on its own thread. With the null device (the autotest, CI) a paused engine (Edit mode) never mixes, so the
// player advances the null device itself, a frame's worth per update(); that is also what keeps the tests deterministic.
#pragma once

#include <deque>
#include <functional>
#include <string>

#include "fa/audio/audio.h"
#include "sound_model.h"

namespace fa::editor {

struct SoundPlayRequest {
    SoundRenderPtr clip;
    std::string name;             // what the Audio panel's log shows
    double gainDb = 0.0;          // level match
    double from = 0.0;            // seconds: where to start
    double to = -1.0;             // seconds: where the region ends (< 0: the end of the sound)
    bool loop = false;            // wrap at the end of the region ...
    double loopFrom = -1.0;       // ... to here (< 0: the start of the region): an intro before it plays once
};

class SoundPlayer {
public:
    // `engineMixes`: true while the engine itself advances a null device each frame (Play mode); then the player does not.
    SoundPlayer(Audio* audio, std::function<bool()> engineMixes);
    ~SoundPlayer();
    SoundPlayer(const SoundPlayer&) = delete;
    SoundPlayer& operator=(const SoundPlayer&) = delete;

    bool play(const SoundPlayRequest& request);
    void stop();
    bool playing() const { return voice_ != 0; }
    // The audible playhead in seconds of the clip (the end of the region once a one-shot has been heard to its end).
    double position() const;
    // How many times a loop has wrapped since play() (a test reads it).
    int wraps() const { return wraps_; }
    // The same position of another clip (A/B): the voice is replaced, the region, loop and position are kept.
    bool switch_to(SoundRenderPtr clip, double gainDb, const std::string& name);
    // Changes the level of what is playing (the next chunks) without a restart.
    void set_gain_db(double db);
    // Moves the loop of what plays (the loop points were dragged): takes effect at the next wrap.
    void set_loop(double from, double to);
    const SoundPlayRequest& request() const { return req_; }
    // Once per UI frame, after the model's tick: tops the queue up, advances a null device, notices the end.
    void update(double dt);

private:
    struct Chunk {
        std::size_t src;      // first frame of the clip in this chunk
        std::size_t frames;
        double cum;           // frames pushed before it
    };
    void fill();
    void push_run(std::size_t from, std::size_t frames, bool fadeIn, bool fadeOut);

    Audio* audio_;
    std::function<bool()> engineMixes_;
    SoundPlayRequest req_;
    VoiceId voice_ = 0;
    std::size_t cursor_ = 0, regionStart_ = 0, regionEnd_ = 0, loopFrom_ = 0;
    double gain_ = 1.0;
    double pushed_ = 0.0;
    bool ended_ = false;      // everything of a one-shot has been pushed
    bool firstChunk_ = true;
    std::deque<Chunk> chunks_;
    double lastPos_ = 0.0;
    int wraps_ = 0;
};

}  // namespace fa::editor
