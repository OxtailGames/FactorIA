// Seeded noise: see fa/core/noise.h. Only + - * / floor and sqrt on floats and 64-bit integer hashing.
#include "fa/core/noise.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <limits>
#include <string>
#include <type_traits>
#include <vector>

#include "fa/core/jobs.h"
#include "param_json.h"

namespace fa {

namespace {

// ------------------------------------------------------------------------------------------------------------ hashing
inline std::uint64_t mix64(std::uint64_t z) {  // the splitmix64 finalizer
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
    return z ^ (z >> 31);
}

inline std::uint64_t seed_state(std::uint64_t seed) { return mix64(seed ^ 0x2545F4914F6CDD1Dull); }

inline std::uint64_t octave_seed(std::uint64_t seed, int octave) {
    return octave == 0 ? seed : mix64(seed + std::uint64_t(octave) * 0x9E3779B97F4A7C15ull);
}

// The hash of one lattice point for a seed state (from seed_state).
inline std::uint64_t lattice_hash(std::uint64_t state, int ix, int iy, int iz) {
    return mix64(state + std::uint64_t(std::uint32_t(ix)) * 0x9E3779B185EBCA87ull +
                 std::uint64_t(std::uint32_t(iy)) * 0xC2B2AE3D27D4EB4Full +
                 std::uint64_t(std::uint32_t(iz)) * 0x165667B19E3779F9ull);
}

// 24 random bits as a float in [0, 1).
inline float unit24(std::uint64_t bits) { return float(std::uint32_t(bits & 0xFFFFFFu)) * (1.0f / 16777216.0f); }

// The lattice cell of v and the position inside it. NaN counts as 0; the index is clamped so the cast cannot overflow.
inline void split(float v, int& cell, float& frac) {
    if (!(v == v)) v = 0.0f;
    float fl = std::floor(v);
    if (fl < -1.0e9f) fl = -1.0e9f;
    if (fl > 1.0e9f) fl = 1.0e9f;
    cell = int(fl);
    frac = v - fl;
    if (!(frac >= 0.0f)) frac = 0.0f;
    if (frac > 1.0f) frac = 1.0f;
}

inline float fade(float t) { return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f); }  // 6t^5 - 15t^4 + 10t^3
inline float lerp1(float a, float b, float t) { return a + t * (b - a); }
inline float clamp_signed(float v) { return v < -1.0f ? -1.0f : (v > 1.0f ? 1.0f : (v == v ? v : 0.0f)); }

// 16 unit gradients every 22.5 degrees (2D) and the 12 edge directions of a cube, scaled to unit length (3D).
constexpr float kG2[16][2] = {
    {1.0f, 0.0f},  {0.92387953f, 0.38268343f},   {0.70710678f, 0.70710678f},   {0.38268343f, 0.92387953f},
    {0.0f, 1.0f},  {-0.38268343f, 0.92387953f},  {-0.70710678f, 0.70710678f},  {-0.92387953f, 0.38268343f},
    {-1.0f, 0.0f}, {-0.92387953f, -0.38268343f}, {-0.70710678f, -0.70710678f}, {-0.38268343f, -0.92387953f},
    {0.0f, -1.0f}, {0.38268343f, -0.92387953f},  {0.70710678f, -0.70710678f},  {0.92387953f, -0.38268343f}};
constexpr float kH = 0.70710678f;
constexpr float kG3[12][3] = {{kH, kH, 0},  {-kH, kH, 0},  {kH, -kH, 0}, {-kH, -kH, 0}, {kH, 0, kH},  {-kH, 0, kH},
                              {kH, 0, -kH}, {-kH, 0, -kH}, {0, kH, kH},  {0, -kH, kH},  {0, kH, -kH}, {0, -kH, -kH}};
// With unit gradients the 2D noise is bounded by sqrt(2)/2 and the 3D noise by sqrt(3)/2: these scales make it [-1, 1].
constexpr float kScale2 = 1.41421356f;
constexpr float kScale3 = 1.15470054f;

inline float grad2(std::uint64_t h, float dx, float dy) {
    const float* g = kG2[(h >> 32) & 15u];
    return g[0] * dx + g[1] * dy;
}
inline float grad3(std::uint64_t h, float dx, float dy, float dz) {
    const float* g = kG3[(h >> 32) % 12u];
    return g[0] * dx + g[1] * dy + g[2] * dz;
}

float perlin2_state(std::uint64_t st, float x, float y) {
    int ix, iy;
    float fx, fy;
    split(x, ix, fx);
    split(y, iy, fy);
    const float u = fade(fx), v = fade(fy);
    const float n00 = grad2(lattice_hash(st, ix, iy, 0), fx, fy);
    const float n10 = grad2(lattice_hash(st, ix + 1, iy, 0), fx - 1.0f, fy);
    const float n01 = grad2(lattice_hash(st, ix, iy + 1, 0), fx, fy - 1.0f);
    const float n11 = grad2(lattice_hash(st, ix + 1, iy + 1, 0), fx - 1.0f, fy - 1.0f);
    return clamp_signed(lerp1(lerp1(n00, n10, u), lerp1(n01, n11, u), v) * kScale2);
}

float perlin3_state(std::uint64_t st, float x, float y, float z) {
    int ix, iy, iz;
    float fx, fy, fz;
    split(x, ix, fx);
    split(y, iy, fy);
    split(z, iz, fz);
    const float u = fade(fx), v = fade(fy), w = fade(fz);
    const float n000 = grad3(lattice_hash(st, ix, iy, iz), fx, fy, fz);
    const float n100 = grad3(lattice_hash(st, ix + 1, iy, iz), fx - 1.0f, fy, fz);
    const float n010 = grad3(lattice_hash(st, ix, iy + 1, iz), fx, fy - 1.0f, fz);
    const float n110 = grad3(lattice_hash(st, ix + 1, iy + 1, iz), fx - 1.0f, fy - 1.0f, fz);
    const float n001 = grad3(lattice_hash(st, ix, iy, iz + 1), fx, fy, fz - 1.0f);
    const float n101 = grad3(lattice_hash(st, ix + 1, iy, iz + 1), fx - 1.0f, fy, fz - 1.0f);
    const float n011 = grad3(lattice_hash(st, ix, iy + 1, iz + 1), fx, fy - 1.0f, fz - 1.0f);
    const float n111 = grad3(lattice_hash(st, ix + 1, iy + 1, iz + 1), fx - 1.0f, fy - 1.0f, fz - 1.0f);
    const float a = lerp1(lerp1(n000, n100, u), lerp1(n010, n110, u), v);
    const float b = lerp1(lerp1(n001, n101, u), lerp1(n011, n111, u), v);
    return clamp_signed(lerp1(a, b, w) * kScale3);
}

// A random value in [-1, 1) for a lattice point.
inline float corner_value(std::uint64_t h) { return float(std::uint32_t(h >> 40)) * (1.0f / 8388608.0f) - 1.0f; }

float value2_state(std::uint64_t st, float x, float y) {
    int ix, iy;
    float fx, fy;
    split(x, ix, fx);
    split(y, iy, fy);
    const float u = fade(fx), v = fade(fy);
    const float a = lerp1(corner_value(lattice_hash(st, ix, iy, 0)), corner_value(lattice_hash(st, ix + 1, iy, 0)), u);
    const float b =
        lerp1(corner_value(lattice_hash(st, ix, iy + 1, 0)), corner_value(lattice_hash(st, ix + 1, iy + 1, 0)), u);
    return clamp_signed(lerp1(a, b, v));
}

float value3_state(std::uint64_t st, float x, float y, float z) {
    int ix, iy, iz;
    float fx, fy, fz;
    split(x, ix, fx);
    split(y, iy, fy);
    split(z, iz, fz);
    const float u = fade(fx), v = fade(fy), w = fade(fz);
    auto c = [&](int dx, int dy, int dz) { return corner_value(lattice_hash(st, ix + dx, iy + dy, iz + dz)); };
    const float a = lerp1(lerp1(c(0, 0, 0), c(1, 0, 0), u), lerp1(c(0, 1, 0), c(1, 1, 0), u), v);
    const float b = lerp1(lerp1(c(0, 0, 1), c(1, 0, 1), u), lerp1(c(0, 1, 1), c(1, 1, 1), u), v);
    return clamp_signed(lerp1(a, b, w));
}

inline float unit_jitter(float jitter) {
    return jitter < 0.0f ? 0.0f : (jitter > 1.0f ? 1.0f : (jitter == jitter ? jitter : 1.0f));
}

// The value of a cellular sample the fractals use: the chosen distance, scaled and clamped to [-1, 1] (a short distance is -1).
float cellular_scalar(const CellularSample& s, CellularReturn r) {
    float d = s.f1, scale = 1.0f;
    if (r == CellularReturn::F2) {
        d = s.f2;
        scale = 1.0f / 1.5f;
    } else if (r == CellularReturn::F2MinusF1) {
        d = s.f2MinusF1;
    }
    d *= scale;
    return clamp_signed(2.0f * (d > 1.0f ? 1.0f : d) - 1.0f);
}

// ------------------------------------------------------------------------------------------------------- the fractal
inline float base_sample(const NoiseParams& p, bool d3, std::uint64_t seed, float x, float y, float z) {
    const std::uint64_t st = seed_state(seed);
    switch (p.type) {
        case NoiseType::Value: return d3 ? value3_state(st, x, y, z) : value2_state(st, x, y);
        case NoiseType::Cellular:
            return cellular_scalar(d3 ? cellular_3d(seed, x, y, z, p.jitter) : cellular_2d(seed, x, y, p.jitter),
                                   p.cellularReturn);
        case NoiseType::Perlin:
        default: return d3 ? perlin3_state(st, x, y, z) : perlin2_state(st, x, y);
    }
}

// An fBm of Perlin noise in [-1, 1], the noise the domain warp displaces with.
float warp_fbm(std::uint64_t seed, bool d3, int octaves, float x, float y, float z) {
    float amp = 1.0f, sum = 0.0f, norm = 0.0f;
    for (int o = 0; o < octaves; ++o) {
        const std::uint64_t st = seed_state(octave_seed(seed, o));
        sum += amp * (d3 ? perlin3_state(st, x, y, z) : perlin2_state(st, x, y));
        norm += amp;
        amp *= 0.5f;
        x *= 2.0f;
        y *= 2.0f;
        z *= 2.0f;
    }
    return sum / norm;
}

float sample_impl(const NoiseParams& p, bool d3, float x, float y, float z) {
    if (p.warpAmplitude > 0.0f) {
        const int wo = std::clamp(p.warpOctaves, 1, kMaxNoiseWarpOctaves);
        const float wf = p.warpFrequency, wa = p.warpAmplitude;
        const std::uint64_t sx = mix64(p.seed ^ 0xA3B195354A39B70Dull), sy = mix64(p.seed ^ 0x1B873593CC9E2D51ull),
                            sz = mix64(p.seed ^ 0xE6546B64D3A5F1C7ull);
        const float qx = x * wf, qy = y * wf, qz = z * wf;
        const float dx = warp_fbm(sx, d3, wo, qx, qy, qz) * wa;
        const float dy = warp_fbm(sy, d3, wo, qx, qy, qz) * wa;
        const float dz = d3 ? warp_fbm(sz, d3, wo, qx, qy, qz) * wa : 0.0f;
        x += dx;
        y += dy;
        z += dz;
    }
    const int octaves = p.fractal == NoiseFractal::None ? 1 : std::clamp(p.octaves, 1, kMaxNoiseOctaves);
    const float off = std::isnan(p.offset) ? 0.0f : std::clamp(p.offset, -1.0f, 1.0f);
    const float invDen = 1.0f / (1.0f + std::fabs(off));
    float px = x * p.frequency, py = y * p.frequency, pz = z * p.frequency;
    float amp = 1.0f, sum = 0.0f, norm = 0.0f;
    for (int o = 0; o < octaves; ++o) {
        const float n = base_sample(p, d3, octave_seed(p.seed, o), px, py, pz);
        float s = n;
        if (p.fractal == NoiseFractal::Ridged) {
            float t = 1.0f - std::fabs(n - off) * invDen;
            if (t < 0.0f) t = 0.0f;
            s = t * t;  // [0, 1]
        } else if (p.fractal == NoiseFractal::Billow) {
            s = std::fabs(n - off) * invDen;  // [0, 1]
        }
        sum += amp * s;
        norm += amp;
        amp *= p.gain;
        px *= p.lacunarity;
        py *= p.lacunarity;
        pz *= p.lacunarity;
    }
    float r = sum / norm;
    if (p.fractal == NoiseFractal::Ridged || p.fractal == NoiseFractal::Billow) r = 2.0f * r - 1.0f;
    return clamp_signed(r);
}

// ------------------------------------------------------------------------------------------------------------ JSON
const std::vector<std::string> kTypeNames = {"perlin", "value", "cellular"};
const std::vector<std::string> kFractalNames = {"none", "fbm", "ridged", "billow"};
const std::vector<std::string> kReturnNames = {"f1", "f2", "f2MinusF1"};
const std::vector<std::string> kOutputNames = {"signed", "unit"};
const std::vector<std::string> kKeys = {"type",      "dimension",     "fractal",       "cellularReturn", "seed",
                                        "frequency", "octaves",       "lacunarity",    "gain",           "offset",
                                        "jitter",    "warpAmplitude", "warpFrequency", "warpOctaves",    "output"};

Error out_of_range(std::string_view pointer, const char* key, float v, std::string_view limits, std::string_view hint) {
    return detail::pj_range_error(pointer, key, std::format("{} is not allowed ({})", detail::pj_num(v), limits), hint);
}

}  // namespace

// ------------------------------------------------------------------------------------------------------- primitives
float perlin_2d(std::uint64_t seed, float x, float y) { return perlin2_state(seed_state(seed), x, y); }
float perlin_3d(std::uint64_t seed, float x, float y, float z) { return perlin3_state(seed_state(seed), x, y, z); }
float value_2d(std::uint64_t seed, float x, float y) { return value2_state(seed_state(seed), x, y); }
float value_3d(std::uint64_t seed, float x, float y, float z) { return value3_state(seed_state(seed), x, y, z); }

CellularSample cellular_2d(std::uint64_t seed, float x, float y, float jitter) {
    const std::uint64_t st = seed_state(seed);
    const float j = unit_jitter(jitter);
    int ix, iy;
    float fx, fy;
    split(x, ix, fx);
    split(y, iy, fy);
    constexpr float kFar = 1.0e30f;
    float best1 = kFar, best2 = kFar, id = 0.0f;
    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            const std::uint64_t h = lattice_hash(st, ix + dx, iy + dy, 0);
            const float px = float(dx) + 0.5f + j * (unit24(h) - 0.5f) - fx;
            const float py = float(dy) + 0.5f + j * (unit24(h >> 24) - 0.5f) - fy;
            const float d2 = px * px + py * py;
            if (d2 < best1) {
                best2 = best1;
                best1 = d2;
                id = float(std::uint32_t(h >> 48)) * (1.0f / 65536.0f);
            } else if (d2 < best2) {
                best2 = d2;
            }
        }
    }
    CellularSample s;
    s.f1 = std::sqrt(best1);
    s.f2 = std::sqrt(best2);
    s.f2MinusF1 = s.f2 - s.f1;
    s.cellValue = id;
    return s;
}

CellularSample cellular_3d(std::uint64_t seed, float x, float y, float z, float jitter) {
    const std::uint64_t st = seed_state(seed);
    const float j = unit_jitter(jitter);
    int ix, iy, iz;
    float fx, fy, fz;
    split(x, ix, fx);
    split(y, iy, fy);
    split(z, iz, fz);
    constexpr float kFar = 1.0e30f;
    float best1 = kFar, best2 = kFar, id = 0.0f;
    for (int dz = -1; dz <= 1; ++dz) {
        for (int dy = -1; dy <= 1; ++dy) {
            for (int dx = -1; dx <= 1; ++dx) {
                const std::uint64_t h = lattice_hash(st, ix + dx, iy + dy, iz + dz);
                const float px =
                    float(dx) + 0.5f + j * (float(std::uint32_t(h & 0x1FFFFFu)) * (1.0f / 2097152.0f) - 0.5f) - fx;
                const float py = float(dy) + 0.5f +
                                 j * (float(std::uint32_t((h >> 21) & 0x1FFFFFu)) * (1.0f / 2097152.0f) - 0.5f) - fy;
                const float pz = float(dz) + 0.5f +
                                 j * (float(std::uint32_t((h >> 42) & 0x1FFFFFu)) * (1.0f / 2097152.0f) - 0.5f) - fz;
                const float d2 = px * px + py * py + pz * pz;
                if (d2 < best1) {
                    best2 = best1;
                    best1 = d2;
                    id = float(std::uint32_t(mix64(h) >> 40)) * (1.0f / 16777216.0f);
                } else if (d2 < best2) {
                    best2 = d2;
                }
            }
        }
    }
    CellularSample s;
    s.f1 = std::sqrt(best1);
    s.f2 = std::sqrt(best2);
    s.f2MinusF1 = s.f2 - s.f1;
    s.cellValue = id;
    return s;
}

// ------------------------------------------------------------------------------------------------------ parameters
Result<void> validate_noise_params(const NoiseParams& p, std::string_view pointer) {
    auto finite = [](float v) { return std::isfinite(v); };
    if (p.dimension != 2 && p.dimension != 3)
        return detail::pj_range_error(pointer, "dimension", std::format("{} is not allowed (2 or 3)", p.dimension),
                                      "Use 2 for a heightmap or a texture, 3 to sample a slice of 3D noise.");
    if (!finite(p.frequency) || p.frequency <= 0.0f || p.frequency > 1.0e6f)
        return out_of_range(pointer, "frequency", p.frequency, "must be greater than 0 and at most 1000000",
                            "frequency is cycles per world unit: 0.01 puts a feature every 100 units. A negative value "
                            "would only mirror the pattern; change the seed or the origin for that.");
    if (p.octaves < 1 || p.octaves > kMaxNoiseOctaves)
        return detail::pj_range_error(pointer, "octaves",
                                      std::format("{} is not allowed (1 to {})", p.octaves, kMaxNoiseOctaves),
                                      "Each octave adds finer detail at twice the cost; 4 to 8 is usual, and fractal "
                                      "\"none\" uses a single layer.");
    if (!finite(p.lacunarity) || p.lacunarity < 1.0f || p.lacunarity > 8.0f)
        return out_of_range(pointer, "lacunarity", p.lacunarity, "must be from 1 to 8",
                            "lacunarity multiplies the frequency from one octave to the next; 2 is the usual value.");
    if (!finite(p.gain) || p.gain < 0.0f || p.gain > 1.0f)
        return out_of_range(
            pointer, "gain", p.gain, "must be from 0 to 1",
            "gain multiplies the amplitude from one octave to the next; 0.5 is the usual value (rougher "
            "at 0.7, smoother at 0.3).");
    if (!finite(p.offset) || p.offset < -1.0f || p.offset > 1.0f)
        return out_of_range(
            pointer, "offset", p.offset, "must be from -1 to 1",
            "offset moves the ridge (ridged) or valley (billow) line of the noise; 0 is the zero crossing.");
    if (!finite(p.jitter) || p.jitter < 0.0f || p.jitter > 1.0f)
        return out_of_range(pointer, "jitter", p.jitter, "must be from 0 to 1",
                            "jitter 0 puts the cellular feature points on a regular grid, 1 anywhere in their cell.");
    if (!finite(p.warpAmplitude) || p.warpAmplitude < 0.0f || p.warpAmplitude > 1.0e6f)
        return out_of_range(
            pointer, "warpAmplitude", p.warpAmplitude, "must be from 0 to 1000000",
            "warpAmplitude is how far, in world units, the domain warp moves each position; 0 turns the "
            "warp off.");
    if (!finite(p.warpFrequency) || p.warpFrequency <= 0.0f || p.warpFrequency > 1.0e6f)
        return out_of_range(pointer, "warpFrequency", p.warpFrequency, "must be greater than 0 and at most 1000000",
                            "warpFrequency is cycles per world unit of the noise that displaces the position.");
    if (p.warpOctaves < 1 || p.warpOctaves > kMaxNoiseWarpOctaves)
        return detail::pj_range_error(pointer, "warpOctaves",
                                      std::format("{} is not allowed (1 to {})", p.warpOctaves, kMaxNoiseWarpOctaves),
                                      "Two octaves already give a convincing warp.");
    return {};
}

Result<NoiseParams> noise_params_from_json(const Json& value, std::string_view pointer) {
    if (auto r = detail::pj_check_object(value, pointer, kKeys, "the noise parameters"); !r) return r.error();
    NoiseParams p;
    int idx = 0;
    std::int64_t iv = 0;
    auto enum_field = [&](const char* key, const std::vector<std::string>& names, auto& field) -> Result<void> {
        idx = int(field);
        if (auto r = detail::pj_enum(value, pointer, key, names, idx); !r) return r;
        field = std::remove_reference_t<decltype(field)>(idx);
        return {};
    };
    auto int_field = [&](const char* key, std::int64_t lo, std::int64_t hi, int& field) -> Result<void> {
        iv = field;
        if (auto r = detail::pj_int(value, pointer, key, lo, hi, iv); !r) return r;
        field = int(iv);
        return {};
    };
    if (auto r = enum_field("type", kTypeNames, p.type); !r) return r.error();
    if (auto r = int_field("dimension", 2, 3, p.dimension); !r) return r.error();
    if (auto r = enum_field("fractal", kFractalNames, p.fractal); !r) return r.error();
    if (auto r = enum_field("cellularReturn", kReturnNames, p.cellularReturn); !r) return r.error();
    if (auto r = detail::pj_u64(value, pointer, "seed", p.seed); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "frequency", p.frequency); !r) return r.error();
    if (auto r = int_field("octaves", 1, kMaxNoiseOctaves, p.octaves); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "lacunarity", p.lacunarity); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "gain", p.gain); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "offset", p.offset); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "jitter", p.jitter); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "warpAmplitude", p.warpAmplitude); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "warpFrequency", p.warpFrequency); !r) return r.error();
    if (auto r = int_field("warpOctaves", 1, kMaxNoiseWarpOctaves, p.warpOctaves); !r) return r.error();
    if (auto r = enum_field("output", kOutputNames, p.output); !r) return r.error();
    if (auto r = validate_noise_params(p, pointer); !r) return r.error();
    return p;
}

Json noise_params_to_json(const NoiseParams& p) {
    Json j = Json::object();
    j["type"] = kTypeNames[std::size_t(p.type)];
    j["dimension"] = p.dimension;
    j["fractal"] = kFractalNames[std::size_t(p.fractal)];
    j["cellularReturn"] = kReturnNames[std::size_t(p.cellularReturn)];
    j["seed"] = p.seed;
    j["frequency"] = p.frequency;
    j["octaves"] = p.octaves;
    j["lacunarity"] = p.lacunarity;
    j["gain"] = p.gain;
    j["offset"] = p.offset;
    j["jitter"] = p.jitter;
    j["warpAmplitude"] = p.warpAmplitude;
    j["warpFrequency"] = p.warpFrequency;
    j["warpOctaves"] = p.warpOctaves;
    j["output"] = kOutputNames[std::size_t(p.output)];
    return j;
}

Json noise_params_schema() {
    auto num = [](const char* desc, double lo, double hi, double def) {
        Json f = {{"type", "number"}, {"description", desc}, {"minimum", lo}, {"maximum", hi}, {"default", def}};
        return f;
    };
    auto integer = [](const char* desc, int lo, int hi, int def) {
        Json f = {{"type", "integer"}, {"description", desc}, {"minimum", lo}, {"maximum", hi}, {"default", def}};
        return f;
    };
    auto word = [](const char* desc, const std::vector<std::string>& names, const char* def) {
        Json f = {{"type", "string"}, {"description", desc}, {"enum", names}, {"default", def}};
        return f;
    };
    Json props = Json::object();
    props["type"] =
        word("The primitive noise of every octave: perlin (smooth gradient noise), value (blockier, cheaper) or "
             "cellular (Worley: distance to scattered points).",
             kTypeNames, "perlin");
    props["dimension"] =
        integer("2 samples the plane; 3 samples the slice z of 3D noise (a cave or a volume).", 2, 3, 2);
    props["fractal"] =
        word("How octaves combine: none (one layer), fbm (smooth hills), ridged (sharp ridges) or billow "
             "(rounded lumps).",
             kFractalNames, "fbm");
    props["cellularReturn"] = word("Cellular only: f1 (distance to the nearest point), f2 (to the second nearest) or "
                                   "f2MinusF1 (cell borders).",
                                   kReturnNames, "f1");
    props["seed"] = {{"type", "integer"},
                     {"minimum", 0},
                     {"description", "Changes every pattern; the same seed always gives the same values."},
                     {"default", 0}};
    props["frequency"] =
        num("Cycles per world unit of the first octave: 0.01 puts a feature every 100 units.", 1e-9, 1e6, 0.01);
    props["octaves"] =
        integer("Layers of detail the fractal adds (fractal none uses one); each costs one more evaluation.", 1,
                kMaxNoiseOctaves, 6);
    props["lacunarity"] = num("Frequency multiplier from one octave to the next.", 1, 8, 2);
    props["gain"] =
        num("Amplitude multiplier from one octave to the next: lower is smoother, higher rougher.", 0, 1, 0.5);
    props["offset"] =
        num("Ridged and billow: where the ridge or valley line sits in the noise (0 = the zero crossing).", -1, 1, 0);
    props["jitter"] =
        num("Cellular only: 0 puts the feature points on a regular grid, 1 anywhere in their cell.", 0, 1, 1);
    props["warpAmplitude"] =
        num("Domain warp: how far, in world units, positions are displaced before sampling; 0 is off.", 0, 1e6, 0);
    props["warpFrequency"] =
        num("Domain warp: cycles per world unit of the noise that displaces the position.", 1e-9, 1e6, 0.01);
    props["warpOctaves"] = integer("Domain warp: octaves of the warp noise.", 1, kMaxNoiseWarpOctaves, 2);
    props["output"] = word("The range fill_noise writes: signed is -1 to 1, unit is 0 to 1.", kOutputNames, "signed");
    return Json{{"type", "object"},
                {"description",
                 "Seeded noise: a primitive, a fractal combinator, an optional domain warp and an output range."},
                {"properties", props},
                {"additionalProperties", false}};
}

// ----------------------------------------------------------------------------------------------------------- sampling
float sample_noise_2d(const NoiseParams& params, float x, float y) { return sample_impl(params, false, x, y, 0.0f); }
float sample_noise_3d(const NoiseParams& params, float x, float y, float z) {
    return sample_impl(params, true, x, y, z);
}

std::uint64_t noise_fill_work(int width, int height, const NoiseParams& params) {
    if (width <= 0 || height <= 0) return 0;
    constexpr std::uint64_t kMax = std::numeric_limits<std::uint64_t>::max();
    const std::uint64_t w = std::uint64_t(width), h = std::uint64_t(height);
    if (w > kMax / h) return kMax;
    const std::uint64_t samples = w * h;
    const std::uint64_t oct =
        params.fractal == NoiseFractal::None ? 1u : std::uint64_t(std::clamp(params.octaves, 1, 64));
    const std::uint64_t warp = params.warpAmplitude > 0.0f ? std::uint64_t(std::clamp(params.warpOctaves, 1, 64)) *
                                                                 (params.dimension == 3 ? 3u : 2u)
                                                           : 0u;
    const std::uint64_t perSample = oct + warp;
    if (samples > kMax / perSample) return kMax;
    return samples * perSample;
}

Result<void> fill_noise(std::span<float> out, int width, int height, const NoiseParams& params, Vec2 origin,
                        float cellSize, float z) {
    if (auto r = validate_noise_params(params); !r) return r;
    if (width < 1 || height < 1)
        return make_error(std::format("fill_noise: the grid is {} x {}; both sides must be at least 1", width, height),
                          "Pass the width and height of the heightfield or texture in samples.");
    const std::uint64_t samples =
        std::uint64_t(width) * std::uint64_t(height);  // both fit 31 bits: no overflow in 64 bits
    if (samples > kMaxNoiseFillSamples)
        return make_error(std::format("fill_noise: {} x {} is {} samples, more than the {} the engine fills at once",
                                      width, height, samples, kMaxNoiseFillSamples),
                          "Fill the grid in tiles (origin moves by (width - 1) * cellSize), or use fewer samples.");
    if (!std::isfinite(cellSize) || cellSize <= 0.0f)
        return make_error(std::format("fill_noise: cellSize {} is not allowed", detail::pj_num(cellSize)),
                          "cellSize is the distance in world units between neighbouring samples; it must be finite and "
                          "greater than 0.");
    if (!std::isfinite(origin.x) || !std::isfinite(origin.y) || !std::isfinite(z))
        return make_error("fill_noise: origin and z must be finite numbers",
                          "Pass the world position of the first sample.");
    const std::uint64_t work = noise_fill_work(width, height, params);
    if (work > kMaxNoiseFillWork)
        return make_error(
            std::format("fill_noise: this request needs {} noise evaluations, more than the {} allowed ({} "
                        "samples x {} per sample)",
                        work, kMaxNoiseFillWork, samples, work / samples),
            "Use fewer octaves, no domain warp, or a smaller grid; fill big areas in tiles.");

    if (std::uint64_t(out.size()) != samples)
        return make_error(std::format("fill_noise: the output has {} values but a {} x {} grid needs {}", out.size(),
                                      width, height, samples),
                          "Size the buffer to width * height floats.");

    const bool d3 = params.dimension == 3;
    const bool unit = params.output == NoiseOutput::Unit;
    const double ox = double(origin.x), oy = double(origin.y), cs = double(cellSize);
    // About 16k samples per chunk; the chunk bounds depend only on the grid, and each sample only on its own position.
    const std::size_t grain = std::max<std::size_t>(1, 16384u / std::size_t(width));
    float* data = out.data();
    auto r = jobs::parallel_for("noise.fill", std::size_t(height), grain, [&](const jobs::Chunk& c) {
        for (std::size_t j = c.begin; j < c.end; ++j) {
            const float y = float(oy + double(j) * cs);
            float* row = data + j * std::size_t(width);
            for (int i = 0; i < width; ++i) {
                const float x = float(ox + double(i) * cs);
                float v = d3 ? sample_impl(params, true, x, y, z) : sample_impl(params, false, x, y, 0.0f);
                if (unit) v = v * 0.5f + 0.5f;
                row[i] = v;
            }
        }
    });
    if (!r) return r.error();
    return {};
}

}  // namespace fa
