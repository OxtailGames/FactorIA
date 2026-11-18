#include "post_fx.h"

#include <algorithm>
#include <cmath>

#include "fa/render/cube_lut.h"

namespace fa::render {

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }
float clean(float v, float lo, float hi, float fallback) { return std::clamp(finite_or(v, fallback), lo, hi); }
Vec2 clean_point(Vec2 v) { return {clean(v.x, 0.0f, 1.0f, 0.5f), clean(v.y, 0.0f, 1.0f, 0.5f)}; }

constexpr float kLumR = 0.2126f, kLumG = 0.7152f, kLumB = 0.0722f;  // Rec. 709 weights
float luma(Vec3 c) { return c.x * kLumR + c.y * kLumG + c.z * kLumB; }

float smooth_step(float e0, float e1, float x) {
    const float t = saturate((x - e0) / (e1 - e0));
    return t * t * (3.0f - 2.0f * t);
}

// White balance as three gains: the temperature moves red against blue, the tint green against red and blue, by up to 20% at +-100;
// divided by their own luminance so the picture does not get brighter or darker.
Vec3 white_balance_gains(float temperature, float tint) {
    const float t = temperature / 100.0f, n = tint / 100.0f;
    Vec3 g{1.0f + 0.2f * t + 0.1f * n, 1.0f - 0.2f * n, 1.0f - 0.2f * t + 0.1f * n};
    return g / luma(g);
}

std::uint32_t pcg(std::uint32_t v) {
    const std::uint32_t s = v * 747796405u + 2891336453u;
    const std::uint32_t w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}

}  // namespace

PostFx make_post_fx(const PostStack& stack, std::uint64_t frame, float designScale) {
    const float scale = std::clamp(finite_or(designScale, 1.0f), 0.05f, 16.0f);
    PostFx o;
    const PostProcess& f = stack.fx;
    if (stack.has(PostEffect::LensDistortion)) {
        const float intensity = clean(f.lensDistortionIntensity, -1.0f, 1.0f, 0.0f);
        o.lensZoom = clean(f.lensDistortionScale, 0.5f, 2.0f, 1.0f);
        o.lensK = intensity * kLensStrength;
        o.lensCenter = clean_point(f.lensDistortionCenter);
        o.lens = intensity != 0.0f || o.lensZoom != 1.0f;
    }
    if (stack.has(PostEffect::RadialBlur) && f.radialBlurEnabled) {
        const float intensity = clean(f.radialBlurIntensity, 0.0f, 1.0f, 0.0f);
        o.radialCenter = clean_point(f.radialBlurCenter);
        o.radialLength = intensity * kRadialBlurStrength;
        o.radialSamples = std::clamp(int(f.radialBlurSamples), 4, 32);
        o.radialBlur = intensity > 0.0f;
    }
    if (stack.has(PostEffect::ChromaticAberration)) {
        const float intensity = clean(f.chromaticAberrationIntensity, 0.0f, 1.0f, 0.0f);
        o.aberrationAmount = intensity * kAberrationStrength;
        o.aberration = intensity > 0.0f;
    }
    if (stack.has(PostEffect::ColorGrading)) {
        const float temperature = clean(f.colorGradingTemperature, -100.0f, 100.0f, 0.0f);
        const float tint = clean(f.colorGradingTint, -100.0f, 100.0f, 0.0f);
        o.whiteBalance = temperature != 0.0f || tint != 0.0f ? white_balance_gains(temperature, tint) : Vec3{1, 1, 1};
        auto channel = [&](const Color& c, float lo, float hi, float fallback) {
            return Vec3{clean(c.r, lo, hi, fallback), clean(c.g, lo, hi, fallback), clean(c.b, lo, hi, fallback)};
        };
        o.lift = channel(f.colorGradingLift, -1.0f, 1.0f, 0.0f);
        o.gain = channel(f.colorGradingGain, 0.0f, 8.0f, 1.0f);
        const Vec3 gamma = channel(f.colorGradingGamma, 0.1f, 10.0f, 1.0f);
        o.invGamma = {1.0f / gamma.x, 1.0f / gamma.y, 1.0f / gamma.z};
        o.contrast = clean(f.colorGradingContrast, 0.0f, 3.0f, 1.0f);
        o.saturation = clean(f.colorGradingSaturation, 0.0f, 3.0f, 1.0f);
        const float hue = clean(f.colorGradingHueShift, -180.0f, 180.0f, 0.0f);
        const float rad = hue * (3.14159265358979f / 180.0f);
        const float cs = std::cos(rad), sn = std::sin(rad);
        const float k = (1.0f - cs) / 3.0f, s = sn * 0.57735027f;
        o.hueA = cs + k;
        o.hueB = k - s;
        o.hueC = k + s;
        o.grade = temperature != 0.0f || tint != 0.0f || o.lift != Vec3{0, 0, 0} || o.gain != Vec3{1, 1, 1} ||
                  o.invGamma != Vec3{1, 1, 1} || o.contrast != 1.0f || o.saturation != 1.0f || hue != 0.0f;
        o.lutContribution = clean(f.colorGradingLutContribution, 0.0f, 1.0f, 1.0f);
        o.lut = !f.colorGradingLut.empty() && o.lutContribution > 0.0f;
    }
    if (stack.has(PostEffect::Vignette)) {
        o.vignetteIntensity = clean(f.vignetteIntensity, 0.0f, 1.0f, 0.0f);
        o.vignetteSmoothness = clean(f.vignetteSmoothness, 0.0f, 1.0f, 0.5f);
        o.vignetteRoundness = clean(f.vignetteRoundness, 0.0f, 1.0f, 1.0f);
        o.vignetteCenter = clean_point(f.vignetteCenter);
        o.vignetteColor = {clean(f.vignetteColor.r, 0.0f, 1.0f, 0.0f), clean(f.vignetteColor.g, 0.0f, 1.0f, 0.0f),
                           clean(f.vignetteColor.b, 0.0f, 1.0f, 0.0f)};
        o.vignette = o.vignetteIntensity > 0.0f;
    }
    if (stack.has(PostEffect::Sharpen)) {
        const float intensity = clean(f.sharpenIntensity, 0.0f, 2.0f, 0.0f);
        o.sharpenWeight = -0.1f * intensity;
        o.sharpen = intensity > 0.0f;
    }
    if (stack.has(PostEffect::FilmGrain)) {
        o.grainIntensity = clean(f.filmGrainIntensity, 0.0f, 1.0f, 0.0f);
        o.grainSize = clean(f.filmGrainSize, 0.5f, 4.0f, 1.0f);
        o.grainResponse = clean(f.filmGrainLuminanceResponse, 0.0f, 1.0f, 0.8f);
        o.grainSeed = f.filmGrainAnimated ? std::uint32_t(frame & 0xFFFFFFu) : 0u;
        o.grain = o.grainIntensity > 0.0f;
    }
    if (stack.has(PostEffect::Outline)) {
        const float width = clean(f.outlineWidth, 0.0f, 8.0f, 1.0f);
        o.outlineSprite = f.outlineMode == OutlineMode::Sprite;
        o.outlineWidth = width > 0.0f ? std::max(width, 0.5f) * scale : 0.0f;
        o.outlineColor = {clean(f.outlineColor.r, 0.0f, 1.0f, 0.0f), clean(f.outlineColor.g, 0.0f, 1.0f, 0.0f),
                          clean(f.outlineColor.b, 0.0f, 1.0f, 0.0f)};
        o.outlineOpacity = clean(f.outlineColor.a, 0.0f, 1.0f, 1.0f);
        o.outlineDepthThreshold = clean(f.outlineDepthThreshold, 0.001f, 1.0f, 0.1f);
        o.outlineNormalThreshold = clean(f.outlineNormalThreshold, 0.001f, 1.0f, 0.4f);
        o.outlineAlphaThreshold = clean(f.outlineAlphaThreshold, 1.0f / 255.0f, 1.0f, 0.5f);
        o.outline = o.outlineWidth > 0.0f && o.outlineOpacity > 0.0f;
    }
    if (stack.has(PostEffect::Pixelate)) {
        const float size = clean(f.pixelateSize, 1.0f, 64.0f, 1.0f) * scale;
        o.pixelateBlock = std::clamp(int(std::lround(size)), 1, 4096);
        o.pixelate = o.pixelateBlock > 1;
    }
    if (stack.has(PostEffect::Posterize)) {
        o.posterizeLevels = std::clamp(int(f.posterizeLevels), 2, 256);
        o.posterize = o.posterizeLevels < 256;
    }
    return o;
}

Vec3 grade_color(const PostFx& fx, Vec3 c) {
    Vec3 v = c * fx.whiteBalance * fx.gain;
    for (int i = 0; i < 3; ++i) {
        float x = v[i];
        x += fx.lift[i] * (1.0f - saturate(x));  // the lift only reaches what is below white
        x = std::pow(std::max(x, 0.0f), fx.invGamma[i]);
        x = std::max((x - 0.5f) * fx.contrast + 0.5f, 0.0f);
        v[i] = x;
    }
    const float l = luma(v);
    v = Vec3{l, l, l} + (v - Vec3{l, l, l}) * fx.saturation;
    v = {fx.hueA * v.x + fx.hueB * v.y + fx.hueC * v.z, fx.hueC * v.x + fx.hueA * v.y + fx.hueB * v.z,
         fx.hueB * v.x + fx.hueC * v.y + fx.hueA * v.z};
    return {std::max(v.x, 0.0f), std::max(v.y, 0.0f), std::max(v.z, 0.0f)};
}

Vec3 apply_lut(const CubeLut& lut, float contribution, Vec3 c) {
    const Vec3 x{saturate(c.x), saturate(c.y), saturate(c.z)};
    return c + (lut.sample(x) - x) * contribution;
}

float vignette_amount(const PostFx& fx, Vec2 uv, float aspect) {
    Vec2 q = uv - fx.vignetteCenter;
    q.x *= lerp(1.0f, aspect, fx.vignetteRoundness);
    const float r = length(q) * 1.41421356f;  // 1 at a corner of the screen when the shape follows it
    const float width = lerp(0.02f, 1.0f, fx.vignetteSmoothness);
    return fx.vignetteIntensity * smooth_step(1.0f - width, 1.0f, r);
}

Vec2 lens_source(const PostFx& fx, Vec2 uv, float aspect) {
    Vec2 q = uv - fx.lensCenter;
    q.x *= aspect;
    const float r2 = dot(q, q) / (0.25f * (aspect * aspect + 1.0f));  // 1 at a corner when the lens axis is the middle
    q *= (1.0f + fx.lensK * r2) / fx.lensZoom;
    q.x /= aspect;
    return fx.lensCenter + q;
}

Vec3 sharpen_color(const PostFx& fx, Vec3 c, Vec3 up, Vec3 down, Vec3 left, Vec3 right) {
    Vec3 out;
    for (int i = 0; i < 3; ++i) {
        const float mn = std::min({c[i], up[i], down[i], left[i], right[i]});
        const float mx = std::max({c[i], up[i], down[i], left[i], right[i]});
        // Contrast adaptive (AMD CAS): the closer the neighbourhood is to the limits of the range, the less the pixel is pushed.
        const float amp = std::sqrt(saturate(std::min(mn, 1.0f - mx) / std::max(mx, 1e-4f)));
        const float w = amp * fx.sharpenWeight;
        out[i] = std::max((c[i] + w * (up[i] + down[i] + left[i] + right[i])) / (1.0f + 4.0f * w), 0.0f);
    }
    return out;
}

float grain_noise(int x, int y, const PostFx& fx) {
    // 0.51, not 0.5: a pixel centre on the border of a cell (a size of 3, 5, 6...) would round either way on the GPU and the CPU.
    const auto cx = std::uint32_t(int(std::floor((float(x) + 0.51f) / fx.grainSize)));
    const auto cy = std::uint32_t(int(std::floor((float(y) + 0.51f) / fx.grainSize)));
    const std::uint32_t h1 = pcg(cx + pcg(cy + pcg(fx.grainSeed)));
    const std::uint32_t h2 = pcg(h1 ^ 0x68E31DA4u);
    const float u1 = float(h1 >> 8u) * (1.0f / 16777216.0f), u2 = float(h2 >> 8u) * (1.0f / 16777216.0f);
    return u1 + u2 - 1.0f;
}

Vec3 grain_color(const PostFx& fx, Vec3 c, int x, int y) {
    const float l = saturate(luma(c));
    const float weight = lerp(1.0f, 4.0f * l * (1.0f - l), fx.grainResponse);
    const float n = grain_noise(x, y, fx) * fx.grainIntensity * kGrainStrength * weight;
    return {std::max(c.x + n, 0.0f), std::max(c.y + n, 0.0f), std::max(c.z + n, 0.0f)};
}

void pixelate_pixel(const PostFx& fx, int x, int y, int w, int h, int& outX, int& outY) {
    const int b = std::max(fx.pixelateBlock, 1);
    outX = std::min((x / b) * b + b / 2, std::max(w - 1, 0));
    outY = std::min((y / b) * b + b / 2, std::max(h - 1, 0));
}

Vec3 posterize_color(const PostFx& fx, Vec3 c) {
    const float n = float(std::max(fx.posterizeLevels, 2) - 1);
    Vec3 out;
    for (int i = 0; i < 3; ++i) {
        const float b = saturate(c[i]);
        out[i] = std::floor(b * n + 0.5f) / n + (c[i] - b);
    }
    return out;
}

// ---- the transient screen effects ---------------------------------------------------------------------------------------------------

void add_screen_fx(PostFx& fx, const std::vector<ScreenFx>& live, const Mat4& viewProj) {
    if (live.empty()) return;
    // The centre of an effect in camera-local uv; false for a world point behind a perspective camera (or not finite).
    auto centre = [&](const ScreenFxOptions& o, Vec2& out) {
        if (!o.atWorld) {
            out = clean_point(o.screen);
            return true;
        }
        const Vec4 c = viewProj * Vec4{o.world, 1.0f};
        if (!std::isfinite(c.x) || !std::isfinite(c.y) || !std::isfinite(c.w) || c.w <= 1e-6f) return false;
        out = {c.x / c.w * 0.5f + 0.5f, 0.5f - c.y / c.w * 0.5f};
        return true;
    };
    float overlayR = 0.0f, overlayG = 0.0f, overlayB = 0.0f, overlayA = 0.0f;  // premultiplied by the opacity
    float bestBlur = fx.radialBlur ? fx.radialLength : 0.0f;
    for (const ScreenFx& e : live) {      // oldest first: the newest rings and hazes are the last ones, kept below
        if (screen_fx_done(e)) continue;  // (a held fade is not done)
        const ScreenFxOptions& o = e.o;
        switch (o.kind) {
            case ScreenFxKind::Shockwave: {
                Vec2 c;
                const float push = clean(o.strength, 0.0f, 1.0f, 0.0f) * screen_fx_envelope(e);
                if (push <= 0.0f || !centre(o, c)) break;
                ShockRing r;
                r.center = c;
                r.radius = screen_fx_ring_radius(e);
                r.halfWidth = std::max(clean(o.width, 0.0f, 4.0f, 0.1f) * 0.5f, 1e-4f);
                r.push = push;
                if (fx.ringCount == kMaxScreenRings) {  // drop the oldest of the drawn ones
                    for (int i = 1; i < kMaxScreenRings; ++i) fx.rings[std::size_t(i - 1)] = fx.rings[std::size_t(i)];
                    --fx.ringCount;
                }
                fx.rings[std::size_t(fx.ringCount++)] = r;
                break;
            }
            case ScreenFxKind::HeatHaze: {
                const float strength = clean(o.strength, 0.0f, 1.0f, 0.0f) * screen_fx_envelope(e);
                if (strength <= 0.0f) break;
                HazeBand h;
                h.region = o.region;
                h.strength = strength;
                h.frequency = clean(o.frequency, 0.0f, 200.0f, 10.0f);
                h.phase = std::fmod(clean(o.speed, -100.0f, 100.0f, 1.0f) * e.elapsed, 1.0f);
                if (fx.hazeCount == kMaxScreenHaze) {
                    for (int i = 1; i < kMaxScreenHaze; ++i) fx.hazes[std::size_t(i - 1)] = fx.hazes[std::size_t(i)];
                    --fx.hazeCount;
                }
                fx.hazes[std::size_t(fx.hazeCount++)] = h;
                break;
            }
            case ScreenFxKind::RadialBlur: {
                Vec2 c;
                const float length = clean(o.intensity, 0.0f, 1.0f, 0.0f) * screen_fx_envelope(e) * kRadialBlurStrength;
                if (length <= bestBlur || !centre(o, c)) break;
                bestBlur = length;
                fx.radialBlur = true;
                fx.radialLength = length;
                fx.radialCenter = c;
                fx.radialSamples = std::clamp(int(o.samples), 4, 32);
                break;
            }
            case ScreenFxKind::Flash:
            case ScreenFxKind::Fade: {
                const float a = clean(screen_fx_alpha(e), 0.0f, 1.0f, 0.0f);
                if (a <= 0.0f) break;
                const float keep = 1.0f - a;  // what of the layers below stays
                overlayR = overlayR * keep + clean(o.color.r, 0.0f, 1.0f, 0.0f) * a;
                overlayG = overlayG * keep + clean(o.color.g, 0.0f, 1.0f, 0.0f) * a;
                overlayB = overlayB * keep + clean(o.color.b, 0.0f, 1.0f, 0.0f) * a;
                overlayA = overlayA * keep + a;
                break;
            }
        }
    }
    if (overlayA > 0.0f) {
        fx.overlay = true;
        fx.overlayAlpha = std::min(overlayA, 1.0f);
        fx.overlayColor = {overlayR / overlayA, overlayG / overlayA, overlayB / overlayA};
    }
}

Vec2 shockwave_offset(const PostFx& fx, Vec2 uv, float aspect) {
    Vec2 o{0.0f, 0.0f};
    for (int i = 0; i < fx.ringCount; ++i) {
        const ShockRing& r = fx.rings[std::size_t(i)];
        if (r.push <= 0.0f) continue;
        Vec2 d = uv - r.center;
        d.x *= aspect;
        const float dist = std::sqrt(d.x * d.x + d.y * d.y);
        const float x = (dist - r.radius) / r.halfWidth;
        if (std::fabs(x) >= 1.0f || dist < 1e-5f) continue;
        const float b = 1.0f - x * x;
        Vec2 dir = d * (1.0f / dist);
        dir.x /= aspect;
        o = o - dir * (r.push * b * b);
    }
    return o;
}

Vec2 haze_offset(const PostFx& fx, Vec2 uv, float aspect) {
    Vec2 o{0.0f, 0.0f};
    for (int i = 0; i < fx.hazeCount; ++i) {
        const HazeBand& h = fx.hazes[std::size_t(i)];
        if (h.strength <= 0.0f) continue;
        const float ex = std::min(uv.x - h.region[0], h.region[0] + h.region[2] - uv.x);
        const float ey = std::min(uv.y - h.region[1], h.region[1] + h.region[3] - uv.y);
        const float m = smooth_step(0.0f, 0.05f, std::min(ex, ey));
        o.x += h.strength * m * std::sin(6.28318530718f * (uv.y * h.frequency + h.phase)) / aspect;
    }
    return o;
}

int radial_blur_taps(const PostFx& fx, Vec2 uv, Vec2* out) {
    if (!fx.radialBlur) return 0;
    const int n = std::clamp(fx.radialSamples, 4, 32);
    for (int i = 0; i < n; ++i) {
        const float f = float(i) / float(std::max(n - 1, 1));
        out[i] = fx.radialCenter + (uv - fx.radialCenter) * (1.0f - fx.radialLength * f);
    }
    return n;
}

Vec3 overlay_color(const PostFx& fx, Vec3 c) {
    if (!fx.overlay) return c;
    return c + (fx.overlayColor - c) * fx.overlayAlpha;
}

float lens_coverage(Vec2 source, int w, int h) {
    const float ix = std::min(source.x, 1.0f - source.x) * float(w);
    const float iy = std::min(source.y, 1.0f - source.y) * float(h);
    const float t = std::clamp((std::min(ix, iy) + 0.5f), 0.0f, 1.0f);  // smoothstep(-0.5, 0.5, d)
    return t * t * (3.0f - 2.0f * t);
}

std::uint32_t grain_seed_for_camera(std::uint32_t seed, int cameraIndex) {
    if (cameraIndex <= 0) return seed;
    return (seed + std::uint32_t(cameraIndex) * 0x9E3779B1u) & 0xFFFFFFu;
}

}  // namespace fa::render
