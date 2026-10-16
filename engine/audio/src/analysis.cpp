#include "fa/audio/analysis.h"

#include <algorithm>
#include <cmath>
#include <numbers>
#include <numeric>

#include "audio_decoder.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"

namespace fa {

namespace {

constexpr double kPi = std::numbers::pi;
constexpr double kStreamAutoSeconds = 10.0;      // `stream: "auto"` streams clips longer than this
constexpr double kMaxNormalizeGainDb = 24.0;     // normalization never moves a clip further than this ...
constexpr double kNormalizePeakDb = -1.0;        // ... nor past this sample peak (there is no limiter)
constexpr double kAbsoluteGateLufs = -70.0;
constexpr double kRelativeGateLu = -10.0;
constexpr double kLoudnessOffset = -0.691;  // BS.1770: loudness = -0.691 + 10 log10(mean square)

struct Biquad {
    double b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0;
    double z1 = 0, z2 = 0;
    double process(double x) {  // transposed direct form II
        const double y = b0 * x + z1;
        z1 = b1 * x - a1 * y + z2;
        z2 = b2 * x - a2 * y;
        return y;
    }
};

// BS.1770-4 K-weighting: a high shelf (the acoustics of the head) then a high pass (RLB). The standard prints the
// coefficients for 48 kHz only; these are the bilinear transforms of its analogue prototypes at the clip's own rate.
struct KWeighting {
    Biquad shelf, highpass;
    explicit KWeighting(double fs) {
        constexpr double shelfHz = 1681.974450955533, shelfGainDb = 3.999843853973347, shelfQ = 0.7071752369554196;
        double k = std::tan(kPi * shelfHz / fs);
        const double vh = std::pow(10.0, shelfGainDb / 20.0), vb = std::pow(vh, 0.4996667741545416);
        double a0 = 1.0 + k / shelfQ + k * k;
        shelf.b0 = (vh + vb * k / shelfQ + k * k) / a0;
        shelf.b1 = 2.0 * (k * k - vh) / a0;
        shelf.b2 = (vh - vb * k / shelfQ + k * k) / a0;
        shelf.a1 = 2.0 * (k * k - 1.0) / a0;
        shelf.a2 = (1.0 - k / shelfQ + k * k) / a0;

        constexpr double highpassHz = 38.13547087602444, highpassQ = 0.5003270373238773;
        k = std::tan(kPi * highpassHz / fs);
        a0 = 1.0 + k / highpassQ + k * k;
        highpass.b0 = 1.0;
        highpass.b1 = -2.0;
        highpass.b2 = 1.0;
        highpass.a1 = 2.0 * (k * k - 1.0) / a0;
        highpass.a2 = (1.0 - k / highpassQ + k * k) / a0;
    }
    double process(double x) { return highpass.process(shelf.process(x)); }
};

double lufs_of(double meanSquare) { return meanSquare > 0.0 ? kLoudnessOffset + 10.0 * std::log10(meanSquare) : -1e9; }

double mean_of(const std::vector<double>& v) { return std::accumulate(v.begin(), v.end(), 0.0) / double(v.size()); }

}  // namespace

Result<AudioFile> read_audio_file(std::string_view path) {
    AudioFile f;
    f.path = fs::normalize(path);
    auto bytes = fs::read_bytes(f.path);
    if (!bytes && fs::extension(f.path) != ".qoa") {
        if (auto twin = fs::read_bytes(f.path + ".qoa")) {
            f.path += ".qoa";
            bytes = std::move(twin);
        }
    }
    if (!bytes) return bytes.error();
    f.bytes = std::move(*bytes);
    return f;
}

Result<Loudness> measure_loudness(std::span<const std::uint8_t> encoded, std::string_view extension) {
    std::string problem;
    auto dec = audio_detail::open_decoder(encoded.data(), encoded.size(), extension, &problem);
    if (!dec) return make_error("the audio file " + problem);
    const std::size_t channels = std::size_t(dec->channels());
    const double fs = double(dec->rate());
    KWeighting weighting[2] = {KWeighting(fs), KWeighting(fs)};

    // Energy of each 100 ms hop (the K-weighted squares of both sides); a 400 ms block is four hops. One value per block
    // is kept for the gating, so memory grows by 8 bytes per 100 ms of audio, not with the PCM.
    const std::size_t hop = std::max<std::size_t>(1, std::size_t(std::lround(0.1 * fs)));
    const double blockLength = 4.0 * double(hop);
    double ring[4] = {};
    double hopEnergy = 0.0;
    std::size_t hopFill = 0, hops = 0;
    std::vector<double> blocks;
    double peak = 0.0;
    std::uint64_t frames = 0;
    std::vector<float> buffer(4096 * channels);
    for (std::size_t n; (n = dec->read(buffer.data(), 4096)) > 0; frames += n) {
        for (std::size_t i = 0; i < n; ++i) {
            const double l = buffer[i * channels], r = channels > 1 ? buffer[i * channels + 1] : l;
            peak = std::max({peak, std::fabs(l), std::fabs(r)});
            const double yl = weighting[0].process(l), yr = weighting[1].process(r);
            hopEnergy += yl * yl + yr * yr;
            if (++hopFill < hop) continue;
            ring[hops++ % 4] = hopEnergy;
            hopEnergy = 0.0;
            hopFill = 0;
            if (hops >= 4) blocks.push_back((ring[0] + ring[1] + ring[2] + ring[3]) / blockLength);
        }
    }
    if (frames == 0) return make_error("the audio file contains no audio samples");
    if (blocks.empty()) blocks.push_back((ring[0] + ring[1] + ring[2] + ring[3] + hopEnergy) / blockLength);  // shorter than a block

    Loudness out;
    out.seconds = double(frames) / fs;
    out.peakDb = peak > 0.0 ? std::max(-200.0, 20.0 * std::log10(peak)) : -200.0;
    std::vector<double> audible;  // absolute gate
    for (double z : blocks)
        if (lufs_of(z) > kAbsoluteGateLufs) audible.push_back(z);
    if (audible.empty()) return out;  // silence
    const double relativeGate = lufs_of(mean_of(audible)) + kRelativeGateLu;
    std::vector<double> loud;  // relative gate
    for (double z : audible)
        if (lufs_of(z) > relativeGate) loud.push_back(z);
    out.integratedLufs = lufs_of(mean_of(loud));
    return out;
}

double normalization_gain_db(const Loudness& loudness, double targetLufs) {
    if (loudness.integratedLufs <= kSilentLufs) return 0.0;
    const double wanted = std::clamp(targetLufs - loudness.integratedLufs, -kMaxNormalizeGainDb, kMaxNormalizeGainDb);
    return std::min(wanted, kNormalizePeakDb - loudness.peakDb);
}

bool clip_streams(std::string_view stream, double seconds) {
    return stream == "always" || (stream == "auto" && seconds > kStreamAutoSeconds);
}

Json loudness_analysis(const Loudness& loudness, std::span<const std::uint8_t> encoded) {
    return Json::object({{"loudnessLufs", std::round(loudness.integratedLufs * 100.0) / 100.0},
                         {"peakDb", std::round(loudness.peakDb * 100.0) / 100.0},
                         {"seconds", std::round(loudness.seconds * 1000.0) / 1000.0},
                         {"bytes", encoded.size()},
                         {"sha256", sha256_hex(encoded.data(), encoded.size())}});
}

std::optional<Loudness> cached_loudness(const Json& analysis, std::span<const std::uint8_t> encoded) {
    if (!analysis.is_object()) return std::nullopt;
    auto number = [&](const char* key) -> std::optional<double> {
        auto it = analysis.find(key);
        return it != analysis.end() && it->is_number() ? std::optional<double>(it->get<double>()) : std::nullopt;
    };
    const auto lufs = number("loudnessLufs"), peak = number("peakDb"), seconds = number("seconds"), bytes = number("bytes");
    auto hash = analysis.find("sha256");
    if (!lufs || !peak || !seconds || !bytes || hash == analysis.end() || !hash->is_string()) return std::nullopt;
    if (*bytes != double(encoded.size()) || hash->get<std::string>() != sha256_hex(encoded.data(), encoded.size())) return std::nullopt;
    return Loudness{*lufs, *peak, *seconds};
}

}  // namespace fa
