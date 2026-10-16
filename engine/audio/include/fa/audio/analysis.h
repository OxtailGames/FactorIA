// What the engine and the tools know about an audio file without playing it: where its bytes come from, how loud it
// is (ITU-R BS.1770-4 / EBU R128), whether it streams, and the `analysis` record that keeps a measurement in assets.json.
//
// The measurement is cached per file in assets.json ("analysis": loudnessLufs, peakDb, seconds, bytes, sha256), written
// by `assets.analyze_audio` and by exports (docs/ASSETS.md). A cached value only counts while `bytes` and `sha256` still
// describe the file, so editing a sound never leaves a stale gain behind.
#pragma once

#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// What integrated loudness reads for a clip with nothing above the -70 LUFS gate (silence).
inline constexpr double kSilentLufs = -70.0;

// A clip file read through the VFS: `path` when it exists, else its twin `<path>.qoa` (an export replaces
// assets/x.wav by assets/x.wav.qoa). AudioFile::path is the file that was read. The error is the VFS's, for `path`.
struct AudioFile {
    std::string path;
    std::vector<std::uint8_t> bytes;
};
Result<AudioFile> read_audio_file(std::string_view path);

// How loud a clip plays: the mixer feeds a mono clip to both sides and takes the first two channels of any other, and
// that is what is measured. K-weighting filters derived for the file's own rate, 400 ms blocks every 100 ms, absolute
// gate -70 LUFS, relative gate -10 LU. A clip shorter than one block is measured as a single block padded with silence.
// Decodes a little at a time, so a long track costs time but no memory. `extension` is ".wav", ".ogg", ".mp3" or ".qoa".
struct Loudness {
    double integratedLufs = kSilentLufs;
    double peakDb = -200.0;  // sample peak in dBFS (-200 for digital silence)
    double seconds = 0.0;
};
Result<Loudness> measure_loudness(std::span<const std::uint8_t> encoded, std::string_view extension);

// Gain in dB that plays a clip of this loudness at `targetLufs`: at most 24 dB either way, and cut where the loudest
// sample would pass -1 dBFS (there is no limiter). 0 for a silent clip.
double normalization_gain_db(const Loudness& loudness, double targetLufs);

// Whether a clip of `seconds` streams for the import setting `stream`: "always", or "auto" and longer than 10 seconds.
bool clip_streams(std::string_view stream, double seconds);

// The `analysis` keys that record a measurement of `encoded` (the exact bytes measured), to merge into an asset's entry.
Json loudness_analysis(const Loudness& loudness, std::span<const std::uint8_t> encoded);
// The measurement an entry's `analysis` holds for `encoded`; nothing when it is missing or does not describe these bytes.
std::optional<Loudness> cached_loudness(const Json& analysis, std::span<const std::uint8_t> encoded);

}  // namespace fa
