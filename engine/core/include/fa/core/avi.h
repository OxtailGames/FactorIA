// AVI files with Motion-JPEG video and optional PCM audio: the video of a headless replay (`factoria run --headless
// --record-video out.avi`). No dependency: the frames are JPEGs (encode_jpeg), the container is plain RIFF, and every
// player and ffmpeg read it.
//
//   AviWriter w;
//   w.begin("out.avi", 1280, 720, 60.0);
//   for each frame: w.add_frame(encode_jpeg(image));
//   w.finish(pcm, sampleFrames, 44100);      // pcm: interleaved stereo int16; nullptr = no audio stream
//
// The frames wait in a spool file next to the output until finish(), which writes the final file with the audio cut into
// one slice per frame (interleaved, as players expect) and removes the spool.
#pragma once

#include <cstdint>
#include <fstream>
#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa {

class AviWriter {
public:
    AviWriter() = default;
    ~AviWriter();
    AviWriter(const AviWriter&) = delete;
    AviWriter& operator=(const AviWriter&) = delete;

    // `path` is the final file (parent folders are created). fps > 0.
    Result<void> begin(const std::string& path, int width, int height, double fps);
    Result<void> add_frame(const std::vector<std::uint8_t>& jpeg);
    // Writes the file. `pcm` is `sampleFrames` stereo frames (2 int16 each) at `sampleRate`; nullptr or 0 = video only.
    Result<void> finish(const std::int16_t* pcm, std::size_t sampleFrames, int sampleRate);
    int frame_count() const { return int(sizes_.size()); }

private:
    std::string path_, spoolPath_;
    int width_ = 0, height_ = 0;
    double fps_ = 0;
    std::ofstream spool_;
    std::vector<std::uint32_t> sizes_;  // JPEG byte count of each frame, in the spool
    bool open_ = false;
};

}  // namespace fa
