#include "subsurface.h"

#include <algorithm>
#include <cmath>

#include "fa/scene/camera_geometry.h"

namespace fa::render {

namespace {
// The d of Burley's profile when the radius that holds 90% of the light is 1 (fit_subsurface_profile.py: r90 = 6.062229 d).
constexpr float kBurleyR90 = 6.062229f;
constexpr float kPi = 3.14159265358979f;
}  // namespace

float sss_erf(float x) {
    const float s = x < 0.0f ? -1.0f : 1.0f;
    x = std::fabs(x);
    const float t = 1.0f / (1.0f + 0.3275911f * x);
    const float y =
        1.0f - (((((1.061405429f * t - 1.453152027f) * t) + 1.421413741f) * t - 0.284496736f) * t + 0.254829592f) * t *
                   std::exp(-x * x);
    return s * y;
}

float sss_kernel(float x) {
    float k = 0.0f;
    for (const SssGaussian& g : kSssGauss) {
        const float z = x / g.sigma;
        k += g.weight * std::exp(-0.5f * z * z) / (g.sigma * 2.50662827463f);
    }
    return k;
}

float sss_profile_2d(float r) {
    const float d = 1.0f / kBurleyR90;
    r = std::max(r, 1e-6f);
    return (std::exp(-r / d) + std::exp(-r / (3.0f * d))) / (8.0f * kPi * d * r);
}

float sss_profile_cdf(float r) {
    const float d = 1.0f / kBurleyR90;
    r = std::max(r, 0.0f);
    return 0.25f * ((1.0f - std::exp(-r / d)) + 3.0f * (1.0f - std::exp(-r / (3.0f * d))));
}

void sss_tap_weights(float ratio, float w[kSssTaps + 1]) {
    ratio = std::isfinite(ratio) ? std::clamp(ratio, 0.02f, 1.0f) : 1.0f;
    float prev[kSssGaussians] = {};
    for (int k = 0; k <= kSssTaps; ++k) {
        const float edge = kSssCell[k] / ratio;
        float m = 0.0f;
        for (int i = 0; i < kSssGaussians; ++i) {
            const float e = sss_erf(edge / (kSssGauss[i].sigma * 1.41421356f));
            m += kSssGauss[i].weight * (e - prev[i]);
            prev[i] = e;
        }
        w[k] = k == 0 ? m : 0.5f * m;  // the centre cell holds both sides; a tap stands for one
    }
}

float sss_tap_offset(int k, float radiusPx) {
    k = std::clamp(k, 1, kSssTaps);
    return 0.5f * (kSssCell[k - 1] + kSssCell[k]) * radiusPx;
}

float sss_radius_px(float radiusM, float depth, float focalPx, bool ortho) {
    if (!std::isfinite(radiusM) || !std::isfinite(depth) || !std::isfinite(focalPx) || radiusM <= 0.0f ||
        focalPx <= 0.0f)
        return 0.0f;
    if (!ortho && depth <= 0.0f) return 0.0f;
    const float px = radiusM * (ortho ? focalPx : focalPx / depth);
    return std::clamp(px, 0.0f, kSssMaxRadiusPx);
}

SssPlan make_sss_plan(const CameraGeometry& cam, int rectW, int rectH) {
    SssPlan p;
    if (rectW < 1 || rectH < 1) return p;
    const float p11 = cam.proj.at(1, 1);
    if (!std::isfinite(p11) || !(std::fabs(p11) > 1e-12f)) return p;
    p.ortho = !cam.perspective;
    p.rectW = rectW;
    p.rectH = rectH;
    p.focalPx = std::fabs(p11) * float(rectH) * 0.5f;
    p.on = std::isfinite(p.focalPx) && p.focalPx > 0.0f;
    return p;
}

}  // namespace fa::render
