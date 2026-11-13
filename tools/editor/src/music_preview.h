// Plays the song the Music panel edits, with no ImGui: a MusicTransport (the engine's own player, music_transport.h) mixed on the UI thread
// into a PCM voice of the engine's mixer on the "music" bus, fed a third of a second ahead. The transport is the one a game's entity.music uses,
// so the intensity slider, the section jumps and the loops sound exactly as they do in the game; nothing of it is reimplemented here.
//
// The playhead the panel shows is the AUDIBLE one: the transport's position when each chunk was mixed, minus what still waits in the voice's
// queue. With a real output device the mixer pulls the voice on its own thread; with the null device (the autotest, CI) a paused engine (Edit
// mode) never mixes, so update() advances the null device itself, a frame's worth per call.
#pragma once

#include <deque>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "fa/audio/audio.h"
#include "fa/audio/music_transport.h"
#include "music_model.h"

namespace fa::editor {

class MusicPreview {
public:
    // `engineMixes`: true while the engine itself advances a null device each frame (Play mode); then the preview does not.
    MusicPreview(Audio* audio, std::function<bool()> engineMixes);
    ~MusicPreview();
    MusicPreview(const MusicPreview&) = delete;
    MusicPreview& operator=(const MusicPreview&) = delete;

    // Starts `src` at the first pass of section `section` (-1: the beginning of the song) with the layers at `intensity`. False with error().
    bool play(MusicSourcePtr src, int section, float intensity);
    void stop();
    bool playing() const { return voice_ != 0; }
    const std::string& error() const { return error_; }

    // The layers follow `intensity` (0..1) from now on, each fading over the layer fade.
    void set_intensity(float intensity);
    float intensity() const { return intensity_; }
    // The song was rendered again after an edit: at the next bar line the music crosses over to it, at the start of the section that plays.
    bool replace_source(MusicSourcePtr src);
    // Jumps to the first pass of a section at the next bar line, with a short crossfade.
    bool go_to_section(int section);
    // Plays the section again and again (-1: off): when a pass of it ends, it starts over.
    void set_loop_section(int section) { loopSection_ = section; }
    int loop_section() const { return loopSection_; }

    // The audible playhead in song frames (kMusicRate per second); the last one heard once the music stopped.
    double position_frames() const;
    double position_seconds() const { return position_frames() / double(kMusicRate); }
    // 1-based bar and beat and the index of the section pass under the audible playhead (section -1 when it is outside the music).
    struct Where {
        int bar = 1, beat = 1, section = -1, span = -1;
    };
    Where where() const;
    const MusicSource* source() const { return src_.get(); }
    MusicSourcePtr source_ptr() const { return src_; }
    // The gain each layer has now (what the intensity slider is doing), in the order of the source's stems.
    std::vector<float> stem_gains() const;
    // Counters a test reads: section changes and bars the transport has announced since play().
    int section_events() const { return sectionEvents_; }
    int bar_events() const { return barEvents_; }

    // Once per UI frame: tops the queue up, advances a null device, takes the transport's events, keeps a looped section looping.
    void update(double dt);

private:
    struct Chunk {
        double songFrame;  // the transport's position when the chunk started
        std::size_t frames;
        double cum;       // frames pushed before it
        double endFrame;  // the transport's position after mixing it (not songFrame + frames when it jumped)
    };
    void fill();
    void finish();

    Audio* audio_;
    std::function<bool()> engineMixes_;
    std::unique_ptr<MusicTransport> transport_;
    MusicSourcePtr src_;
    VoiceId voice_ = 0;
    double pushed_ = 0.0;
    std::deque<Chunk> chunks_;
    double lastPos_ = 0.0;
    float intensity_ = 0.0f;
    int loopSection_ = -1;
    int sectionEvents_ = 0, barEvents_ = 0;
    std::string error_;
};

}  // namespace fa::editor
