// Private to fa_audio: pull decoders over the encoded bytes of a clip (wav, ogg, mp3, qoa), and the stateful
// resampler that turns what they produce into the mixer's 44.1 kHz stereo. Whole clips, streamed clips and the loudness
// measurement all read through these, so they hear the same samples.
#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

namespace fa::audio_detail {

using Bytes = std::vector<std::uint8_t>;

inline constexpr int kMaxChannels = 32;  // the most channels a clip may have (a clip plays its first two)
inline constexpr int kMixRate = 44100;   // the rate and layout (stereo float) the mixer works in

// .wav .ogg .mp3 .qoa
bool is_audio_extension(std::string_view ext);

// A decoder reads one clip front to back: interleaved float frames at the file's own channel count and rate. It points
// into the bytes it was opened on, which must outlive it.
class Decoder {
public:
    virtual ~Decoder() = default;
    int channels() const { return channels_; }
    int rate() const { return rate_; }
    // Length in frames from the file's header (an mp3 scans its frame headers once); 0 when it cannot be told.
    virtual std::uint64_t frames() { return frames_; }
    // Reads up to `frames` frames; fewer than asked (0 included) only at the end of the stream.
    virtual std::size_t read(float* out, std::size_t frames) = 0;
    virtual bool rewind() = 0;  // back to the first frame
    // The next read returns frame `frame` of the file, exactly the samples a read from the start would make there (music
    // streams jump to the chunk they need). false when the format cannot seek that way (only .ogg does).
    virtual bool seek(std::uint64_t frame) {
        (void)frame;
        return false;
    }

protected:
    int channels_ = 0, rate_ = 0;
    std::uint64_t frames_ = 0;
};

// The decoder for `ext` (".ogg"...), or null with a sentence in *error that finishes "Audio clip 'x' ".
std::unique_ptr<Decoder> open_decoder(const std::uint8_t* data, std::size_t size, std::string_view ext,
                                      std::string* error);

// Decoder output as the mixer wants it: stereo at kMixRate, linear interpolation between source frames (a mono source
// feeds both sides, a source with more than two channels contributes its first two). With `loop` the decoder rewinds
// at its end and the output continues without a seam, so pull() only comes up short at the end of a clip that does
// not loop. Owns the bytes the decoder points into.
class Resampler {
public:
    Resampler(std::shared_ptr<const Bytes> bytes, std::unique_ptr<Decoder> decoder, bool loop);
    std::size_t pull(float* out, std::size_t frames);  // stereo frames
    std::size_t resident_bytes() const { return src_.size() * sizeof(float); }

private:
    void refill(std::size_t used);

    std::shared_ptr<const Bytes> bytes_;
    std::unique_ptr<Decoder> dec_;
    std::vector<float> src_;  // decoded source frames, interleaved
    std::size_t count_ = 0;   // frames in src_
    double phase_ = 0.0;      // where the next output frame falls in src_, in source frames
    double ratio_ = 1.0;      // source rate / kMixRate
    int channels_ = 1;
    bool loop_, done_ = false;
};

}  // namespace fa::audio_detail
