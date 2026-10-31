// The effects of a mixer bus: a gain ramp, a low-pass biquad, a Freeverb-style reverb and the ducking envelope. Private to
// fa_audio (audio.cpp). Everything here is a fixed algorithm over floats with no clock and no random numbers, so the null
// and recording devices mix the same samples every run.
#pragma once

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <vector>

namespace fa::audio_detail {

// A value that moves in a straight line to a target over a number of frames. next() is for per-sample use, skip() moves it
// by a whole block at once (the parameters that change a filter, which is recomputed once per block).
struct Ramp {
    float cur = 1.0f, target = 1.0f, step = 0.0f;
    long frames = 0;

    bool moving() const { return frames > 0; }
    // frames <= 0 jumps.
    void set(float to, long over) {
        if (over <= 0) {
            cur = target = to;
            frames = 0;
            step = 0.0f;
            return;
        }
        target = to;
        frames = over;
        step = (to - cur) / float(over);
    }
    float next() {
        if (frames > 0) {
            cur += step;
            if (--frames == 0) cur = target;
        }
        return cur;
    }
    void skip(long n) {
        if (frames <= 0) return;
        const long m = std::min(n, frames);
        cur += step * float(m);
        frames -= m;
        if (frames == 0) cur = target;
    }
};

// Multiplies `buf` (interleaved stereo) by the ramp's gain, advancing it. Does nothing at unity gain.
inline void apply_gain(float* buf, int frames, Ramp& g) {
    if (!g.moving()) {
        if (g.cur == 1.0f) return;
        const float v = g.cur;
        for (int i = 0; i < frames * 2; ++i) buf[i] *= v;
        return;
    }
    for (int f = 0; f < frames; ++f) {
        const float v = g.next();
        buf[2 * f] *= v;
        buf[2 * f + 1] *= v;
    }
}

inline float flush_denormal(float v) { return std::fabs(v) < 1e-20f ? 0.0f : v; }

// RBJ cookbook low-pass, Q = 1/sqrt(2) (Butterworth), transposed direct form II, one state per channel.
struct Lowpass {
    float b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0;
    float z1[2] = {0, 0}, z2[2] = {0, 0};

    void set_cutoff(float hz, float rate) {
        const float w0 = 6.28318530718f * hz / rate;
        const float c = std::cos(w0), alpha = std::sin(w0) / (2.0f * 0.70710678f);
        const float a0 = 1.0f + alpha;
        b0 = (1.0f - c) * 0.5f / a0;
        b1 = (1.0f - c) / a0;
        b2 = b0;
        a1 = -2.0f * c / a0;
        a2 = (1.0f - alpha) / a0;
    }
    void clear() { z1[0] = z1[1] = z2[0] = z2[1] = 0.0f; }
    void process(float* buf, int frames) {
        for (int c = 0; c < 2; ++c) {
            float s1 = z1[c], s2 = z2[c];
            for (int f = 0; f < frames; ++f) {
                const float x = buf[2 * f + c];
                const float y = b0 * x + s1;
                s1 = b1 * x - a1 * y + s2;
                s2 = b2 * x - a2 * y;
                buf[2 * f + c] = y;
            }
            z1[c] = flush_denormal(s1);
            z2[c] = flush_denormal(s2);
        }
    }
};

// Freeverb (Jezar): eight damped comb filters in parallel then four all-passes, per channel, the right channel's delays a
// few samples longer. The delay lengths are the original ones at 44.1 kHz scaled to the mixer's rate: fixed, so the same
// input always gives the same output. Costs about 24 delay-line reads and writes per frame.
class Reverb {
public:
    explicit Reverb(float rate) {
        static const int combs[8] = {1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617};
        static const int allpasses[4] = {556, 441, 341, 225};
        const float scale = rate / 44100.0f;
        for (int c = 0; c < 2; ++c) {
            const int spread = c * 23;
            for (int i = 0; i < 8; ++i) comb_[c][i].buf.assign(std::size_t(std::max(1, int(float(combs[i] + spread) * scale))), 0.0f);
            for (int i = 0; i < 4; ++i)
                allpass_[c][i].buf.assign(std::size_t(std::max(1, int(float(allpasses[i] + spread) * scale))), 0.0f);
        }
    }
    void clear() {
        for (auto& ch : comb_)
            for (Comb& c : ch) {
                std::fill(c.buf.begin(), c.buf.end(), 0.0f);
                c.store = 0.0f;
            }
        for (auto& ch : allpass_)
            for (Allpass& a : ch) std::fill(a.buf.begin(), a.buf.end(), 0.0f);
    }
    // buf = (1 - mix) * dry + mix * wet.
    void process(float* buf, int frames, float mix) {
        constexpr float kInput = 0.015f, kWet = 3.0f, kFeedback = 0.84f, kDamp = 0.2f;
        const float dry = 1.0f - mix, wetGain = mix * kWet;
        for (int f = 0; f < frames; ++f) {
            const float in = (buf[2 * f] + buf[2 * f + 1]) * kInput;
            for (int c = 0; c < 2; ++c) {
                float out = 0.0f;
                for (Comb& k : comb_[c]) {
                    const float y = k.buf[k.pos];
                    k.store = flush_denormal(y * (1.0f - kDamp) + k.store * kDamp);
                    k.buf[k.pos] = in + k.store * kFeedback;
                    if (++k.pos == k.buf.size()) k.pos = 0;
                    out += y;
                }
                for (Allpass& a : allpass_[c]) {
                    const float held = a.buf[a.pos];
                    a.buf[a.pos] = out + held * 0.5f;
                    if (++a.pos == a.buf.size()) a.pos = 0;
                    out = held - out;
                }
                buf[2 * f + c] = buf[2 * f + c] * dry + out * wetGain;
            }
        }
    }

private:
    struct Comb {
        std::vector<float> buf;
        std::size_t pos = 0;
        float store = 0.0f;
    };
    struct Allpass {
        std::vector<float> buf;
        std::size_t pos = 0;
    };
    Comb comb_[2][8];
    Allpass allpass_[2][4];
};

}  // namespace fa::audio_detail
