#include "audio_mix.h"

#include <algorithm>
#include <cmath>
#include <numbers>

namespace fa::audio_mix {

const char* const kBandNames[kBands] = {"31 Hz", "63 Hz", "125 Hz", "250 Hz", "500 Hz", "1 kHz", "2 kHz", "4 kHz", "8 kHz", "16 kHz"};

namespace {

constexpr double kPi = std::numbers::pi;

// A radix-2 FFT of a fixed power-of-two size.
class Fft {
public:
    explicit Fft(std::size_t n) : n_(n), cos_(n / 2), sin_(n / 2), rev_(n) {
        for (std::size_t i = 0; i < n / 2; ++i) {
            cos_[i] = std::cos(2.0 * kPi * double(i) / double(n));
            sin_[i] = -std::sin(2.0 * kPi * double(i) / double(n));
        }
        std::size_t bits = 0;
        while ((std::size_t(1) << bits) < n) ++bits;
        for (std::size_t i = 0; i < n; ++i) {
            std::size_t r = 0;
            for (std::size_t b = 0; b < bits; ++b)
                if (i & (std::size_t(1) << b)) r |= std::size_t(1) << (bits - 1 - b);
            rev_[i] = r;
        }
    }
    std::size_t size() const { return n_; }
    void forward(std::vector<double>& re, std::vector<double>& im) const {
        for (std::size_t i = 0; i < n_; ++i)
            if (i < rev_[i]) {
                std::swap(re[i], re[rev_[i]]);
                std::swap(im[i], im[rev_[i]]);
            }
        for (std::size_t len = 2; len <= n_; len <<= 1) {
            const std::size_t half = len / 2, step = n_ / len;
            for (std::size_t i = 0; i < n_; i += len)
                for (std::size_t k = 0; k < half; ++k) {
                    const double wr = cos_[k * step], wi = sin_[k * step];
                    const std::size_t a = i + k, b = a + half;
                    const double tr = re[b] * wr - im[b] * wi, ti = re[b] * wi + im[b] * wr;
                    re[b] = re[a] - tr;
                    im[b] = im[a] - ti;
                    re[a] += tr;
                    im[a] += ti;
                }
        }
    }

private:
    std::size_t n_;
    std::vector<double> cos_, sin_;
    std::vector<std::size_t> rev_;
};

std::vector<double> hann(std::size_t n) {
    std::vector<double> w(n);
    for (std::size_t i = 0; i < n; ++i) w[i] = 0.5 - 0.5 * std::cos(2.0 * kPi * double(i) / double(n));
    return w;
}

std::vector<float> mid_of(const DecodedAudio& a) {
    const std::size_t frames = a.frames(), ch = std::size_t(a.channels);
    std::vector<float> mid(frames);
    for (std::size_t i = 0; i < frames; ++i) {
        float s = 0;
        for (std::size_t c = 0; c < ch; ++c) s += a.samples[i * ch + c];
        mid[i] = s / float(ch);
    }
    return mid;
}

double to_db(double linear) { return linear > 1e-10 ? 20.0 * std::log10(linear) : -200.0; }

// The true peak: between two samples the wave can rise above both. Four times oversampling with a Hann-windowed sinc of 16
// taps, evaluated only where a neighbouring sample is within 12 dB of the sample peak (an overshoot is never that large).
double true_peak(const std::vector<float>& x, double samplePeak) {
    constexpr int kHalf = 8;
    static const std::array<std::array<double, 2 * kHalf>, 3> taps = [] {
        std::array<std::array<double, 2 * kHalf>, 3> t{};
        for (int p = 1; p <= 3; ++p)
            for (int j = -kHalf + 1; j <= kHalf; ++j) {
                const double d = double(j) - double(p) / 4.0;
                const double sinc = std::sin(kPi * d) / (kPi * d);
                t[std::size_t(p - 1)][std::size_t(j + kHalf - 1)] = sinc * 0.5 * (1.0 + std::cos(kPi * d / double(kHalf)));
            }
        return t;
    }();
    double peak = samplePeak;
    const double gate = samplePeak * 0.25;
    const std::ptrdiff_t n = std::ptrdiff_t(x.size());
    for (std::ptrdiff_t i = 0; i + 1 < n; ++i) {
        if (std::max(std::fabs(x[std::size_t(i)]), std::fabs(x[std::size_t(i + 1)])) < gate) continue;
        for (const auto& tap : taps) {
            double y = 0;
            for (int j = -kHalf + 1; j <= kHalf; ++j) {
                const std::ptrdiff_t k = i + j;
                if (k >= 0 && k < n) y += double(x[std::size_t(k)]) * tap[std::size_t(j + kHalf - 1)];
            }
            peak = std::max(peak, std::fabs(y));
        }
    }
    return peak;
}

}  // namespace

int band_of(double hz) {
    int b = 0;
    for (int i = 1; i < kBands; ++i)
        if (hz >= kBandCentreHz[i] / std::numbers::sqrt2) b = i;
    return b;
}

Metrics measure(const DecodedAudio& audio, const std::optional<LoopPoints>& loopPoints) {
    Metrics m;
    const std::size_t frames = audio.frames(), ch = std::size_t(audio.channels);
    m.rate = audio.rate;
    m.channels = audio.channels;
    m.seconds = audio.rate > 0 ? double(frames) / audio.rate : 0.0;
    m.bandDb.fill(kBandAbsent);
    if (frames == 0) return m;
    // The frames the loop wraps between: the whole sound unless loop points say otherwise.
    std::size_t seamFirst = 0, seamEnd = frames;
    if (loopPoints && loopPoints->end <= frames && loopPoints->start + 4 <= loopPoints->end) {
        seamFirst = loopPoints->start;
        seamEnd = loopPoints->end;
    }

    double samplePeak = 0, truePeakLinear = 0;
    double bestStepRatio = -1;
    std::vector<float> x(frames);
    for (std::size_t c = 0; c < ch; ++c) {
        for (std::size_t i = 0; i < frames; ++i) x[i] = audio.samples[i * ch + c];
        double chPeak = 0, sumD = 0, sumD2 = 0;
        std::size_t run = 0;
        int runSign = 0;
        for (std::size_t i = 0; i < frames; ++i) {
            const double a = std::fabs(x[i]);
            chPeak = std::max(chPeak, a);
            const bool full = a >= kFullScale;
            if (full) ++m.fullScaleSamples;
            const int sign = x[i] < 0 ? -1 : 1;
            if (full && run > 0 && sign == runSign) {
                ++run;
                m.clippedSamples += run == 2 ? 2 : 1;
            } else {
                run = full ? 1 : 0;
                runSign = sign;
            }
            if (i >= 1) {
                const double d = double(x[i]) - double(x[i - 1]);
                sumD += d * d;
                if (i >= 2) {
                    const double d2 = d - (double(x[i - 1]) - double(x[i - 2]));
                    sumD2 += d2 * d2;
                }
            }
        }
        samplePeak = std::max(samplePeak, chPeak);
        truePeakLinear = std::max(truePeakLinear, true_peak(x, chPeak));
        const double rmsD = frames > 1 ? std::sqrt(sumD / double(frames - 1)) : 0.0;
        const double rmsD2 = frames > 2 ? std::sqrt(sumD2 / double(frames - 2)) : 0.0;
        m.typicalStep = std::max(m.typicalStep, rmsD);
        m.firstSample = std::max(m.firstSample, double(std::fabs(x[0])));
        m.lastSample = std::max(m.lastSample, double(std::fabs(x[frames - 1])));
        // Floors keep a clip of near silence from turning rounding noise into a huge ratio.
        const double stepFloor = std::max(rmsD, 1e-4), slopeFloor = std::max(rmsD2, 1e-5);
        if (frames >= 4) {
            const double fs = std::fabs(double(x[1]) - double(x[0])), ls = std::fabs(double(x[frames - 1]) - double(x[frames - 2]));
            if (std::max(fs, ls) / stepFloor > bestStepRatio) {
                bestStepRatio = std::max(fs, ls) / stepFloor;
                m.firstStep = fs;
                m.lastStep = ls;
            }
            const double jump = std::fabs(double(x[seamFirst]) - double(x[seamEnd - 1]));
            const double slope = std::fabs((double(x[seamFirst + 1]) - double(x[seamFirst])) - (double(x[seamEnd - 1]) - double(x[seamEnd - 2])));
            if (jump / stepFloor > m.seamJumpRatio) {
                m.seamJumpRatio = jump / stepFloor;
                m.seamJump = jump;
            }
            if (slope / slopeFloor > m.seamSlopeRatio) {
                m.seamSlopeRatio = slope / slopeFloor;
                m.seamSlope = slope;
            }
        }
    }
    m.samplePeakDb = to_db(samplePeak);
    m.truePeakDb = to_db(truePeakLinear);
    m.silent = samplePeak < 3.2e-5;  // -90 dBFS
    if (m.silent) return m;

    // Long-term octave band levels: a Welch average of at most 400 frames spread evenly over the sound.
    const std::size_t n = 4096;
    const Fft fft(n);
    const std::vector<double> w = hann(n);
    double w2 = 0;
    for (double v : w) w2 += v * v;
    const std::vector<float> mid = mid_of(audio);
    const std::size_t hop = n / 2;
    std::size_t count = frames > n ? (frames - n) / hop + 1 : 1;
    std::vector<std::size_t> starts;
    if (count <= 400) {
        for (std::size_t i = 0; i < count; ++i) starts.push_back(i * hop);
    } else {
        for (std::size_t i = 0; i < 400; ++i) starts.push_back(std::size_t(double(i) * double(count - 1) / 399.0) * hop);
    }
    std::vector<double> re(n), im(n);
    std::vector<std::vector<double>> framePower;  // per frame: power per band
    std::vector<double> frameTotal;
    for (std::size_t s : starts) {
        for (std::size_t i = 0; i < n; ++i) {
            re[i] = s + i < frames ? double(mid[s + i]) * w[i] : 0.0;
            im[i] = 0.0;
        }
        fft.forward(re, im);
        std::vector<double> bands(kBands, 0.0);
        double total = 0;
        for (std::size_t k = 1; k < n / 2; ++k) {
            const double p = 2.0 * (re[k] * re[k] + im[k] * im[k]) / (double(n) * w2);
            bands[std::size_t(band_of(double(k) * audio.rate / double(n)))] += p;
            total += p;
        }
        framePower.push_back(std::move(bands));
        frameTotal.push_back(total);
    }
    const double loudest = *std::max_element(frameTotal.begin(), frameTotal.end());
    std::vector<double> mean(kBands, 0.0);
    std::size_t used = 0;
    for (std::size_t f = 0; f < framePower.size(); ++f) {
        if (frameTotal[f] < loudest * 1e-4) continue;  // a silent tail does not dilute a short effect
        for (int b = 0; b < kBands; ++b) mean[std::size_t(b)] += framePower[f][std::size_t(b)];
        ++used;
    }
    const double nyquist = audio.rate / 2.0;
    int best = -1;
    for (int b = 0; b < kBands; ++b) {
        const double lowEdge = b == 0 ? 0.0 : kBandCentreHz[b] / std::numbers::sqrt2;
        if (lowEdge >= nyquist) continue;
        const double p = used ? mean[std::size_t(b)] / double(used) : 0.0;
        m.bandDb[std::size_t(b)] = p > 1e-20 ? 10.0 * std::log10(p) : -200.0;
        if (best < 0 || m.bandDb[std::size_t(b)] > m.bandDb[std::size_t(best)]) best = b;
    }
    m.dominantBand = best;
    return m;
}

Spectrogram spectrogram(const DecodedAudio& audio, int columns, int rows) {
    Spectrogram s;
    s.columns = std::max(1, columns);
    s.rows = std::max(1, rows);
    s.maxHz = std::min(20000.0, audio.rate / 2.0);
    s.minHz = std::min(20.0, s.maxHz / 4.0);
    s.db.assign(std::size_t(s.columns) * std::size_t(s.rows), -200.0f);
    const std::size_t frames = audio.frames();
    if (frames == 0) return s;
    const std::size_t n = 2048;
    const Fft fft(n);
    const std::vector<double> w = hann(n);
    double sumW = 0;
    for (double v : w) sumW += v;
    const std::vector<float> mid = mid_of(audio);
    const double df = double(audio.rate) / double(n);
    struct Row { std::size_t k0, k1; double pos; };  // bins covered by a row; pos = its centre in bins
    std::vector<Row> rowBins(std::size_t(s.rows));
    for (int r = 0; r < s.rows; ++r) {
        auto freq = [&](double edge) { return s.minHz * std::pow(s.maxHz / s.minHz, 1.0 - edge / double(s.rows)); };
        const double lo = freq(double(r) + 1.0), hi = freq(double(r)), mid_f = freq(double(r) + 0.5);
        rowBins[std::size_t(r)] = {std::size_t(std::max(1.0, std::floor(lo / df))), std::size_t(std::min(double(n / 2 - 1), std::ceil(hi / df))), mid_f / df};
    }
    std::vector<double> re(n), im(n), amp(n / 2);
    for (int c = 0; c < s.columns; ++c) {
        const double centre = (double(c) + 0.5) / double(s.columns) * double(frames);
        const std::ptrdiff_t start = std::ptrdiff_t(centre) - std::ptrdiff_t(n / 2);
        for (std::size_t i = 0; i < n; ++i) {
            const std::ptrdiff_t k = start + std::ptrdiff_t(i);
            re[i] = k >= 0 && k < std::ptrdiff_t(frames) ? double(mid[std::size_t(k)]) * w[i] : 0.0;
            im[i] = 0.0;
        }
        fft.forward(re, im);
        for (std::size_t k = 0; k < n / 2; ++k) amp[k] = 2.0 * std::sqrt(re[k] * re[k] + im[k] * im[k]) / sumW;
        for (int r = 0; r < s.rows; ++r) {
            const Row& row = rowBins[std::size_t(r)];
            double a;
            if (row.k1 <= row.k0 + 1) {  // a row narrower than a bin: interpolate between its two neighbours
                const std::size_t k = std::min<std::size_t>(std::size_t(row.pos), n / 2 - 2);
                const double t = std::clamp(row.pos - double(k), 0.0, 1.0);
                a = amp[k] * (1.0 - t) + amp[k + 1] * t;
            } else {
                a = 0;
                for (std::size_t k = row.k0; k <= row.k1; ++k) a = std::max(a, amp[k]);
            }
            const float db = float(std::max(-200.0, to_db(a)));
            s.db[std::size_t(r) * std::size_t(s.columns) + std::size_t(c)] = db;
            s.maxDb = std::max(s.maxDb, db);
        }
    }
    return s;
}

}  // namespace fa::audio_mix
