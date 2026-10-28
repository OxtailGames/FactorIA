// Audio conversion for `factoria export` (import setting `convert: "qoa"`): the encoder lives next to the decoder, in
// the module that vendors qoa.h.
#pragma once

#include <cstdint>
#include <span>
#include <vector>

#include "fa/core/types.h"

namespace fa {

// A WAV file (any PCM or float format dr_wav reads, at most 8 channels) as a QOA file: lossy, about 5x smaller than
// 16-bit PCM, cheap to decode. The sample rate and channel count are kept.
Result<std::vector<std::uint8_t>> encode_qoa(std::span<const std::uint8_t> wav);

// A WAV file (as for encode_qoa, one or two channels) as an Ogg Vorbis file, written by a small encoder of this engine
// (vorbis_encode.cpp: fixed 2048 block, a flat per-frame floor, Huffman-coded residue; no stereo coupling, no bitrate
// control). `quality` 0 to 1 sets how many quantization steps a frame's loudest coefficient gets (0.5: about 52, roughly
// 4 to 6 times smaller than 16-bit PCM). The sample rate and length are kept exactly. Deterministic.
Result<std::vector<std::uint8_t>> encode_vorbis(std::span<const std::uint8_t> wav, double quality = 0.5);

}  // namespace fa
