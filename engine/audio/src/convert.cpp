#include "fa/audio/convert.h"

#include <cstdlib>
#include <memory>

#include "dr_wav.h"
#include "qoa.h"

namespace fa {

Result<std::vector<std::uint8_t>> encode_qoa(std::span<const std::uint8_t> wav) {
    unsigned channels = 0, rate = 0;
    drwav_uint64 frames = 0;
    drwav_int16* pcm = drwav_open_memory_and_read_pcm_frames_s16(wav.data(), wav.size(), &channels, &rate, &frames, nullptr);
    if (!pcm) return make_error("not a valid WAV file", "Use 8/16/24/32-bit PCM or float WAV.");
    std::unique_ptr<drwav_int16, void (*)(drwav_int16*)> release{pcm, [](drwav_int16* p) { drwav_free(p, nullptr); }};
    if (channels > QOA_MAX_CHANNELS)
        return make_error("QOA holds at most " + std::to_string(QOA_MAX_CHANNELS) + " channels, the WAV has " + std::to_string(channels),
                          "Set \"convert\": \"none\" for this file, or mix it down.");
    if (frames == 0 || frames > 0xffffffffu || rate > 0xffffff) return make_error("the WAV has no samples, or too many or too fast ones for QOA");
    qoa_desc desc{};
    desc.channels = channels;
    desc.samplerate = rate;
    desc.samples = unsigned(frames);
    unsigned int size = 0;
    void* encoded = qoa_encode(pcm, &desc, &size);
    if (!encoded) return make_error("QOA could not encode the WAV");
    std::vector<std::uint8_t> out(static_cast<const std::uint8_t*>(encoded), static_cast<const std::uint8_t*>(encoded) + size);
    std::free(encoded);
    return out;
}

}  // namespace fa
