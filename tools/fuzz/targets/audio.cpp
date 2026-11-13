// Audio decoding (dr_wav, stb_vorbis, dr_mp3, qoa): the first input byte picks the format (0 .wav, 1 .ogg, 2 .mp3, 3 .qoa),
// the rest is the file. decode_audio must refuse a damaged file and must not size a buffer from a header.
#include <cstddef>
#include <cstdint>
#include <span>

#include "fa/audio/analysis.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    if (size == 0) return 0;
    static const char* const kExt[] = {".wav", ".ogg", ".mp3", ".qoa"};
    const char* ext = kExt[data[0] & 3];
    const std::span<const std::uint8_t> file(data + 1, size - 1);
    // Four seconds at most: a header that promises hours must not make the fuzzer wait for them.
    const auto clip = fa::decode_audio(file, ext, 4.0);
    if (clip && (clip.value().channels < 1 || clip.value().samples.size() % std::size_t(clip.value().channels) != 0))
        fa::fuzz::fail("decode_audio: the samples are not whole frames");
    return 0;
}
