// The time and pitch tools of the audio documents (audio_doc.h): a windowed-sinc resampler and a WSOLA time stretcher, both written
// for this engine so they are deterministic (double math with + - * / and sqrt, the sine and cosine of sfx_math.h; see audio_doc.h).
#include <algorithm>
#include <cmath>

#include "fa/audio/audio_doc.h"
#include "sfx_math.h"

namespace fa {

namespace {

using sfx_math::cos_turns;
using sfx_math::sin_turns;

constexpr double kPiD = 3.141592653589793;

double at(const std::vector<double>& x, long long i) { return i >= 0 && i < (long long)x.size() ? x[std::size_t(i)] : 0.0; }

}  // namespace

std::vector<double> audio_resample(const std::vector<double>& x, double step) {
    if (!(step > 0.0) || x.empty()) return {};
    if (std::fabs(step - 1.0) < 1e-12) return x;
    const std::size_t outLen = std::max<std::size_t>(1, std::size_t(std::llround(double(x.size()) / step)));
    // Zero crossings of the kernel on each side. Going down in rate the kernel is stretched so that nothing above the new Nyquist
    // frequency is kept (the cutoff `fc` is a share of the input's Nyquist frequency).
    constexpr double kZeroCrossings = 12.0;
    const double fc = std::min(1.0, 1.0 / step);
    const double halfWidth = kZeroCrossings / fc;
    const long long reach = (long long)std::ceil(halfWidth);
    std::vector<double> out(outLen, 0.0);
    for (std::size_t o = 0; o < outLen; ++o) {
        const double p = double(o) * step;
        const long long base = (long long)std::floor(p);
        double acc = 0.0;
        for (long long i = base - reach + 1; i <= base + reach; ++i) {
            if (i < 0 || i >= (long long)x.size()) continue;
            const double d = double(i) - p;
            if (std::fabs(d) >= halfWidth) continue;
            const double arg = d * fc;
            const double sinc = std::fabs(arg) < 1e-12 ? 1.0 : sin_turns(arg * 0.5) / (kPiD * arg);
            const double window = 0.5 + 0.5 * cos_turns(d / (2.0 * halfWidth));
            acc += x[std::size_t(i)] * fc * sinc * window;
        }
        out[o] = acc;
    }
    return out;
}

void audio_time_stretch(std::vector<std::vector<double>>& x, int rate, double factor) {
    if (x.empty() || x[0].empty() || !(factor > 0.0) || std::fabs(factor - 1.0) < 1e-9) return;
    const std::size_t n = x[0].size();
    const std::size_t outLen = std::max<std::size_t>(1, std::size_t(std::llround(double(n) * factor)));
    // A frame of about 30 ms (long enough to hold a few periods of a low note), half of it overlapped.
    long long frame = (long long)std::llround(0.03 * double(rate)) & ~1LL;
    if ((long long)n < 2 * frame) frame = std::max<long long>(32, ((long long)n / 2) & ~1LL);
    const long long synHop = frame / 2;
    const double anaHop = double(synHop) / factor;
    const long long tolerance = std::min<long long>(frame / 2, (long long)std::llround(0.012 * double(rate)));

    std::vector<double> mid(n, 0.0);
    for (const auto& c : x)
        for (std::size_t i = 0; i < n; ++i) mid[i] += c[i];
    for (double& v : mid) v /= double(x.size());

    std::vector<double> window(static_cast<std::size_t>(frame));  // periodic Hann: overlapped by half it sums to exactly 1
    for (long long j = 0; j < frame; ++j) window[std::size_t(j)] = 0.5 - 0.5 * cos_turns(double(j) / double(frame));

    std::vector<std::vector<double>> out(x.size(), std::vector<double>(outLen, 0.0));
    constexpr long long kCoarse = 4;  // the search looks at every 4th offset and sample, then refines around the best one
    const long long frames = (long long)(outLen / std::size_t(synHop)) + 2;
    long long prev = 0;
    std::vector<double> target(static_cast<std::size_t>(frame));
    for (long long k = 0; k < frames; ++k) {
        const long long outStart = k * synHop - frame / 2;
        const long long nominal = (long long)std::llround(double(k) * anaHop) - frame / 2;
        long long chosen = nominal;
        if (k > 0) {
            // The segment that would follow the previous frame in the input if it just went on: the new frame should look like it.
            for (long long j = 0; j < frame; ++j) target[std::size_t(j)] = at(mid, prev + synHop + j);
            auto score = [&](long long start, long long stride) {
                double dot = 0.0, energy = 0.0;
                for (long long j = 0; j < frame; j += stride) {
                    const double v = at(mid, start + j);
                    dot += v * target[std::size_t(j)];
                    energy += v * v;
                }
                return dot / std::sqrt(energy + 1e-9);
            };
            double best = -1e300;
            long long bestD = 0;
            for (long long d = -tolerance; d <= tolerance; d += kCoarse) {
                const double s = score(nominal + d, kCoarse);
                if (s > best) {
                    best = s;
                    bestD = d;
                }
            }
            best = -1e300;
            long long fine = bestD;
            for (long long d = bestD - kCoarse + 1; d < bestD + kCoarse; ++d) {
                if (d < -tolerance || d > tolerance) continue;
                const double s = score(nominal + d, 2);
                if (s > best) {
                    best = s;
                    fine = d;
                }
            }
            chosen = nominal + fine;
        }
        for (std::size_t c = 0; c < x.size(); ++c) {
            for (long long j = 0; j < frame; ++j) {
                const long long o = outStart + j;
                if (o < 0 || o >= (long long)outLen) continue;
                out[c][std::size_t(o)] += at(x[c], chosen + j) * window[std::size_t(j)];
            }
        }
        prev = chosen;
    }
    x = std::move(out);
}

void audio_pitch_shift(std::vector<std::vector<double>>& x, int rate, double semitones) {
    if (x.empty() || x[0].empty() || std::fabs(semitones) < 1e-9) return;
    const std::size_t n = x[0].size();
    const double ratio = sfx_math::semitones_to_ratio(semitones);
    // Stretching by the ratio and then playing it that much faster raises the pitch by the ratio and gives back the original length.
    audio_time_stretch(x, rate, ratio);
    for (auto& c : x) {
        c = audio_resample(c, ratio);
        c.resize(n, 0.0);
    }
}

}  // namespace fa
