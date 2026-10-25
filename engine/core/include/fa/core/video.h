// MPEG-1 video + MP2 audio decoding (an .mpg file) over pl_mpeg: the same decoder, and so the same pixels and samples,
// on every platform, with no operating-system codec. The Video component (fa/scene/video.h) drives one of these.
#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

struct VideoInfo {
    int width = 0, height = 0;  // pixels of the picture
    double fps = 0;             // frames per second
    double duration = 0;        // seconds
    bool hasAudio = false;
    int sampleRate = 0;         // Hz of the audio (0 without audio)
};

// A video file played front to back by the time you give it. It never reads a clock: advance(dt) moves it forward,
// so a game that pauses its clock pauses the video, and the same dt sequence gives the same frames and samples.
class VideoDecoder {
public:
    ~VideoDecoder();
    VideoDecoder(const VideoDecoder&) = delete;
    VideoDecoder& operator=(const VideoDecoder&) = delete;

    // Opens an .mpg held in memory (`name` is only for messages). The error says what is wrong with the file; a file
    // that is not MPEG-1 video in an MPEG program stream (an .mp4, say) fails with the ffmpeg command that converts it.
    // The first picture is decoded, so picture() works at once.
    static Result<std::unique_ptr<VideoDecoder>> open(std::shared_ptr<const std::vector<std::uint8_t>> bytes,
                                                      std::string_view name);

    const VideoInfo& info() const { return info_; }

    // With loop, advance() wraps to the start at the end of the file instead of stopping.
    void set_loop(bool loop) { loop_ = loop; }
    bool loop() const { return loop_; }

    // Moves forward by `dt` seconds (<= 0 does nothing): decodes the pictures and the audio up to there. Without loop
    // it stops at the end of the file (ended()); with loop it wraps, as often as `dt` covers.
    void advance(double dt);
    // Jumps to `t` seconds (clamped to the file), showing the picture that covers it; a seek to the end counts as
    // ended. Drops the audio decoded so far (audio_epoch() changes). Returns false when the file has no picture there.
    bool seek(double t);

    double time() const { return time_; }        // position in the file, 0 .. duration
    bool ended() const { return ended_; }         // reached the end (never while looping)
    std::uint64_t loops() const { return loops_; }  // times advance() wrapped to the start

    // The current picture: width * height RGBA8, row 0 on top, alpha 255. picture_serial() changes when a different
    // picture was decoded (it is not a frame count: a seek or a long advance shows only the last one).
    const std::uint8_t* picture() const;
    std::uint64_t picture_serial() const { return pictureSerial_; }

    // Audio: stereo float frames at info().sampleRate, one timeline per epoch that starts at the last seek (or the
    // opening) and runs in step with the video, loops included (a loop pads or trims the audio to the length of the
    // video). take_audio() appends to `out` (interleaved) the frames that belong before `lead` seconds ahead of the
    // current position and have not been taken yet; the rest waits for later advances. Returns the frames appended.
    std::uint64_t audio_epoch() const { return audioEpoch_; }
    std::size_t take_audio(double lead, std::vector<float>& out);

private:
    VideoDecoder() = default;
    struct Impl;
    void decode_to(double target);
    void on_audio(const float* interleaved, std::size_t frames, double blockTime);
    void pad_audio_to(std::uint64_t frames);

    std::unique_ptr<Impl> impl_;
    VideoInfo info_;
    bool loop_ = false, ended_ = false;
    double time_ = 0;
    double played_ = 0;  // seconds advanced since the audio epoch began (what the audio timeline runs against)
    double epochStart_ = 0;  // file time at which the epoch began
    std::uint64_t loops_ = 0, pictureSerial_ = 0, audioEpoch_ = 1;
    std::uint64_t audioProduced_ = 0;  // frames of the timeline of this epoch up to the end of audio_ (taken ones included)
    std::vector<float> audio_;         // decoded, not yet taken (interleaved stereo)
    std::uint64_t audioSkip_ = 0;      // frames to drop from the head of the next block
    bool audioFresh_ = true;           // the next block is the first of the epoch
};

}  // namespace fa
