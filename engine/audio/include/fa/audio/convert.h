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

}  // namespace fa
