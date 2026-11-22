// Seeded noise (fa/core/noise.h): ranges, seeds, continuity, thread-count independence, parameters and caps.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#include "fa/core/jobs.h"
#include "fa/core/noise.h"

using namespace fa;

#define PERLIN2_REF 0.131269f
#define VALUE2_REF 0.0348898f
#define CELL2_REF 0.467177f
#define FBM_REF -0.180554f

namespace {

struct PoolScope {
    explicit PoolScope(const jobs::Settings& s) { REQUIRE(jobs::start(s).ok()); }
    ~PoolScope() { jobs::stop(); }
};

bool same_bits(const std::vector<float>& a, const std::vector<float>& b) {
    return a.size() == b.size() && std::memcmp(a.data(), b.data(), a.size() * sizeof(float)) == 0;
}

std::vector<float> filled(const NoiseParams& p, int w, int h, Vec2 origin = {}, float cell = 1.0f, float z = 0.0f) {
    std::vector<float> v(std::size_t(w) * std::size_t(h), -7.0f);
    auto r = fill_noise(v, w, h, p, origin, cell, z);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return v;
}

}  // namespace

TEST_CASE("noise: every primitive stays in [-1, 1] and uses most of the range") {
    for (std::uint64_t seed : {0ull, 1ull, 0xDEADBEEFCAFEull}) {
        float lo[5] = {1, 1, 1, 1, 1}, hi[5] = {-1, -1, -1, -1, -1};
        auto note = [&](int k, float v) {
            CHECK(v >= -1.0f);
            CHECK(v <= 1.0f);
            lo[k] = std::min(lo[k], v);
            hi[k] = std::max(hi[k], v);
        };
        for (int j = -40; j < 40; ++j) {
            for (int i = -40; i < 40; ++i) {
                const float x = float(i) * 0.173f + 0.011f, y = float(j) * 0.191f - 0.007f, z = float(i + j) * 0.113f;
                note(0, perlin_2d(seed, x, y));
                note(1, perlin_3d(seed, x, y, z));
                note(2, value_2d(seed, x, y));
                note(3, value_3d(seed, x, y, z));
                const CellularSample c = cellular_2d(seed, x, y);
                CHECK(c.f1 >= 0.0f);
                CHECK(c.f1 <= c.f2);
                CHECK(c.f2 < 2.5f);
                CHECK(c.cellValue >= 0.0f);
                CHECK(c.cellValue < 1.0f);
                const CellularSample c3 = cellular_3d(seed, x, y, z);
                CHECK(c3.f1 <= c3.f2);
                CHECK(c3.f2 < 3.0f);
            }
        }
        for (int k = 0; k < 4; ++k) {
            CHECK(hi[k] > 0.5f);
            CHECK(lo[k] < -0.5f);
        }
    }
}

TEST_CASE("noise: the seed changes the result and the same seed gives the same one") {
    int differ = 0, same = 0;
    for (int i = 0; i < 200; ++i) {
        const float x = float(i) * 0.37f + 0.2f, y = float(i) * 0.21f + 0.3f;
        differ += perlin_2d(1, x, y) != perlin_2d(2, x, y);
        differ += value_2d(1, x, y) != value_2d(2, x, y);
        differ += cellular_2d(1, x, y).f1 != cellular_2d(2, x, y).f1;
        same += perlin_2d(1, x, y) == perlin_2d(1, x, y);
        same += perlin_3d(9, x, y, 1.5f) == perlin_3d(9, x, y, 1.5f);
    }
    CHECK(differ >= 590);
    CHECK(same == 400);
    NoiseParams a, b;
    a.seed = 5;
    b.seed = 6;
    CHECK(filled(a, 32, 32) != filled(b, 32, 32));
    CHECK(same_bits(filled(a, 32, 32), filled(a, 32, 32)));
}

TEST_CASE("noise: gradient noise is zero on the lattice and continuous everywhere") {
    CHECK(perlin_2d(3, 4.0f, -7.0f) == 0.0f);
    CHECK(perlin_3d(3, 4.0f, -7.0f, 2.0f) == 0.0f);
    constexpr float kStep = 0.002f;
    float worst = 0, worstValue = 0, worstCell = 0;
    for (int j = 0; j < 60; ++j) {
        for (int i = 0; i < 60; ++i) {
            const float x = float(i) * 0.1371f, y = float(j) * 0.1219f;
            worst = std::max(worst, std::fabs(perlin_2d(7, x + kStep, y) - perlin_2d(7, x, y)));
            worst = std::max(worst, std::fabs(perlin_3d(7, x, y + kStep, 0.4f) - perlin_3d(7, x, y, 0.4f)));
            worstValue = std::max(worstValue, std::fabs(value_2d(7, x, y + kStep) - value_2d(7, x, y)));
            worstCell = std::max(worstCell, std::fabs(cellular_2d(7, x + kStep, y).f1 - cellular_2d(7, x, y).f1));
        }
    }
    CHECK(worst < 0.012f);  // a slope of at most 6 per unit
    CHECK(worstValue < 0.012f);
    CHECK(worstCell <= kStep * 1.001f);  // a distance field is 1-Lipschitz
}

TEST_CASE("noise: cellular noise: regular grid at jitter 0, F2-F1 vanishes on cell borders") {
    // jitter 0: the points sit at the cell centres, so F1 is 0 there and F2 is 1 (the next centre).
    const CellularSample c = cellular_2d(4, 3.5f, 2.5f, 0.0f);
    CHECK(c.f1 == doctest::Approx(0.0f).epsilon(1e-6));
    CHECK(c.f2 == doctest::Approx(1.0f));
    CHECK(cellular_2d(4, 3.0f, 2.5f, 0.0f).f2MinusF1 == doctest::Approx(0.0f).epsilon(1e-6));
    // The nearest-cell value is constant inside a Voronoi cell.
    CHECK(cellular_2d(4, 3.5f, 2.5f, 0.0f).cellValue == cellular_2d(4, 3.52f, 2.49f, 0.0f).cellValue);
    // 3D too.
    const CellularSample c3 = cellular_3d(4, 3.5f, 2.5f, 1.5f, 0.0f);
    CHECK(c3.f1 == doctest::Approx(0.0f).epsilon(1e-6));
    CHECK(c3.f2 == doctest::Approx(1.0f));
}

TEST_CASE("noise: every fractal and primitive stays in [-1, 1] and the fractals differ") {
    for (NoiseType t : {NoiseType::Perlin, NoiseType::Value, NoiseType::Cellular}) {
        for (NoiseFractal f : {NoiseFractal::None, NoiseFractal::Fbm, NoiseFractal::Ridged, NoiseFractal::Billow}) {
            for (float offset : {0.0f, -0.6f, 1.0f}) {
                NoiseParams p;
                p.type = t;
                p.fractal = f;
                p.offset = offset;
                p.frequency = 0.07f;
                p.octaves = 5;
                p.gain = 0.9f;
                p.warpAmplitude = 8.0f;
                p.cellularReturn = CellularReturn::F2MinusF1;
                REQUIRE(validate_noise_params(p).ok());
                float lo = 1, hi = -1;
                for (int i = 0; i < 600; ++i) {
                    const float v2 = sample_noise_2d(p, float(i) * 1.7f, float(i % 37) * 2.3f);
                    const float v3 = sample_noise_3d(p, float(i) * 1.7f, float(i % 37) * 2.3f, float(i % 11));
                    for (float v : {v2, v3}) {
                        REQUIRE(v >= -1.0f);
                        REQUIRE(v <= 1.0f);
                        lo = std::min(lo, v);
                        hi = std::max(hi, v);
                    }
                }
                CHECK(hi - lo > 0.4f);
            }
        }
    }
    NoiseParams fbm, ridged, billow, none;
    ridged.fractal = NoiseFractal::Ridged;
    billow.fractal = NoiseFractal::Billow;
    none.fractal = NoiseFractal::None;
    int different = 0;
    for (int i = 0; i < 50; ++i) {
        const float x = 13.0f * float(i), y = 7.0f * float(i);
        different += sample_noise_2d(fbm, x, y) != sample_noise_2d(ridged, x, y);
        different += sample_noise_2d(fbm, x, y) != sample_noise_2d(billow, x, y);
        different += sample_noise_2d(fbm, x, y) != sample_noise_2d(none, x, y);
    }
    CHECK(different >= 145);
    // Fractal "none" is the primitive itself (octave 0 uses the seed as it is).
    none.frequency = 0.5f;
    none.seed = 77;
    CHECK(sample_noise_2d(none, 3.3f, 1.9f) == perlin_2d(77, 1.65f, 0.95f));
}

TEST_CASE("noise: the domain warp moves the pattern and stays continuous") {
    NoiseParams plain, warped;
    warped.warpAmplitude = 30.0f;
    int moved = 0;
    float worst = 0;
    for (int i = 0; i < 100; ++i) {
        const float x = 9.0f * float(i), y = 5.0f * float(i);
        moved += sample_noise_2d(plain, x, y) != sample_noise_2d(warped, x, y);
        worst = std::max(worst, std::fabs(sample_noise_2d(warped, x + 0.1f, y) - sample_noise_2d(warped, x, y)));
    }
    CHECK(moved > 95);
    CHECK(worst < 0.1f);
}

TEST_CASE("noise: fill_noise is bit-identical with 0, 1 and many job threads and in inline mode") {
    NoiseParams p;
    p.seed = 12345;
    p.fractal = NoiseFractal::Ridged;
    p.octaves = 5;
    p.warpAmplitude = 20.0f;
    p.frequency = 0.02f;
    p.output = NoiseOutput::Unit;
    const int w = 97, h = 71;  // not a multiple of the chunk size
    const std::vector<float> reference = filled(p, w, h, Vec2(-50.5f, 12.25f), 0.75f);  // no pool: runs on this thread
    for (const jobs::Settings& s : {jobs::Settings::inline_jobs(), jobs::Settings::threads(0),
                                    jobs::Settings::threads(1), jobs::Settings::threads(4)}) {
        PoolScope pool(s);
        CHECK(same_bits(filled(p, w, h, Vec2(-50.5f, 12.25f), 0.75f), reference));
    }
    // A bigger grid, so there are many chunks.
    const std::vector<float> big = filled(p, 400, 300);
    PoolScope pool(jobs::Settings::threads(3));
    CHECK(same_bits(filled(p, 400, 300), big));
}

TEST_CASE("noise: fill_noise writes the samples at origin + index * cellSize, in the documented range") {
    NoiseParams p;
    p.seed = 3;
    p.frequency = 0.05f;
    const std::vector<float> v = filled(p, 40, 30, Vec2(10.0f, -20.0f), 2.0f);
    for (int j = 0; j < 30; j += 7)
        for (int i = 0; i < 40; i += 5)
            CHECK(v[std::size_t(j) * 40 + std::size_t(i)] ==
                  sample_noise_2d(p, 10.0f + float(i) * 2.0f, -20.0f + float(j) * 2.0f));
    for (float x : v) {
        CHECK(x >= -1.0f);
        CHECK(x <= 1.0f);
    }
    p.output = NoiseOutput::Unit;
    const std::vector<float> u = filled(p, 40, 30, Vec2(10.0f, -20.0f), 2.0f);
    for (std::size_t i = 0; i < u.size(); ++i) {
        CHECK(u[i] >= 0.0f);
        CHECK(u[i] <= 1.0f);
        CHECK(u[i] == doctest::Approx(v[i] * 0.5f + 0.5f));
    }
    // 3D: a slice of the volume.
    p.dimension = 3;
    p.output = NoiseOutput::Signed;
    const std::vector<float> s3 = filled(p, 16, 16, Vec2(0, 0), 1.0f, 4.5f);
    CHECK(s3[5 * 16 + 3] == sample_noise_3d(p, 3.0f, 5.0f, 4.5f));
    CHECK(s3 != filled(p, 16, 16, Vec2(0, 0), 1.0f, 9.5f));
}

TEST_CASE("noise: tiles whose origins differ by (width - 1) * cellSize share their edge samples") {
    NoiseParams p;
    p.seed = 99;
    p.frequency = 0.03f;
    const int w = 33, h = 33;
    const float cell = 4.0f;
    const std::vector<float> a = filled(p, w, h, Vec2(0, 0), cell);
    const std::vector<float> b = filled(p, w, h, Vec2(float(w - 1) * cell, 0), cell);
    const std::vector<float> whole = filled(p, 2 * w - 1, h, Vec2(0, 0), cell);
    for (int j = 0; j < h; ++j) {
        CHECK(a[std::size_t(j) * w + (w - 1)] == b[std::size_t(j) * w]);
        for (int i = 0; i < w; ++i) {
            CHECK(a[std::size_t(j) * w + i] == whole[std::size_t(j) * (2 * w - 1) + i]);
            CHECK(b[std::size_t(j) * w + i] == whole[std::size_t(j) * (2 * w - 1) + (w - 1 + i)]);
        }
    }
}

TEST_CASE("noise: parameters are validated with the field's JSON pointer and a hint") {
    NoiseParams p;
    p.frequency = -0.5f;
    auto r = validate_noise_params(p, "/noise");
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("/noise/frequency") != std::string::npos);
    CHECK(r.error().message.find("-0.5") != std::string::npos);
    CHECK_FALSE(r.error().hint.empty());

    p = NoiseParams{};
    p.octaves = 0;
    CHECK_FALSE(validate_noise_params(p).ok());
    p.octaves = kMaxNoiseOctaves + 1;
    CHECK_FALSE(validate_noise_params(p).ok());
    p = NoiseParams{};
    p.gain = 1.5f;
    CHECK(validate_noise_params(p).error().message.find("/gain") != std::string::npos);
    p = NoiseParams{};
    p.lacunarity = 0.5f;
    CHECK_FALSE(validate_noise_params(p).ok());
    p = NoiseParams{};
    p.frequency = std::nanf("");
    CHECK_FALSE(validate_noise_params(p).ok());
    p = NoiseParams{};
    p.warpOctaves = 99;
    CHECK(validate_noise_params(p).error().message.find("/warpOctaves") != std::string::npos);
    p = NoiseParams{};
    p.dimension = 4;
    CHECK_FALSE(validate_noise_params(p).ok());
    CHECK(validate_noise_params(NoiseParams{}).ok());
}

TEST_CASE("noise: parameters read from JSON, round-trip, and misspellings teach") {
    auto parsed = noise_params_from_json(Json::parse(R"({"type":"cellular","fractal":"ridged","seed":42,"frequency":0.5,
        "octaves":3,"cellularReturn":"f2MinusF1","warpAmplitude":4,"output":"unit"})"),
                                         "/noise");
    REQUIRE(parsed.ok());
    CHECK(parsed->type == NoiseType::Cellular);
    CHECK(parsed->fractal == NoiseFractal::Ridged);
    CHECK(parsed->seed == 42);
    CHECK(parsed->octaves == 3);
    CHECK(parsed->cellularReturn == CellularReturn::F2MinusF1);
    CHECK(parsed->output == NoiseOutput::Unit);
    auto again = noise_params_from_json(noise_params_to_json(*parsed));
    REQUIRE(again.ok());
    CHECK(*again == *parsed);
    CHECK(noise_params_from_json(Json::object()).ok());

    auto typo = noise_params_from_json(Json::parse(R"({"octave":3})"), "/noise");
    REQUIRE_FALSE(typo.ok());
    CHECK(typo.error().message.find("/noise/octave") != std::string::npos);
    CHECK(typo.error().hint.find("octaves") != std::string::npos);
    auto word = noise_params_from_json(Json::parse(R"({"type":"perlinn"})"), "/noise");
    REQUIRE_FALSE(word.ok());
    CHECK(word.error().hint.find("Did you mean 'perlin'") != std::string::npos);
    CHECK_FALSE(noise_params_from_json(Json::parse(R"({"seed":-1})")).ok());
    CHECK_FALSE(noise_params_from_json(Json::parse(R"({"seed":1.5})")).ok());
    CHECK_FALSE(noise_params_from_json(Json::parse(R"({"octaves":2.5})")).ok());
    CHECK_FALSE(noise_params_from_json(Json::parse(R"({"octaves":"4"})")).ok());
    CHECK_FALSE(noise_params_from_json(Json::parse(R"({"octaves":99999999999})")).ok());
    CHECK_FALSE(noise_params_from_json(Json::parse(R"({"frequency":-1})")).ok());
    CHECK_FALSE(noise_params_from_json(Json::parse("[1]")).ok());
    const Json schema = noise_params_schema();
    for (auto it = schema["properties"].begin(); it != schema["properties"].end(); ++it)
        CHECK_MESSAGE(it.value().contains("description"), it.key());
    CHECK(schema["properties"].size() == noise_params_to_json(NoiseParams{}).size());
}

TEST_CASE("noise: fill_noise refuses bad requests before any work, with a hint") {
    NoiseParams p;
    std::vector<float> v(16);
    CHECK_FALSE(fill_noise(v, 0, 4, p).ok());
    CHECK_FALSE(fill_noise(v, 4, 4, p, {}, 0.0f).ok());
    CHECK_FALSE(fill_noise(v, 4, 4, p, {}, -1.0f).ok());
    CHECK_FALSE(fill_noise(v, 4, 4, p, Vec2(std::nanf(""), 0)).ok());
    auto size = fill_noise(v, 5, 4, p);
    REQUIRE_FALSE(size.ok());
    CHECK(size.error().message.find("20") != std::string::npos);
    CHECK_FALSE(size.error().hint.empty());
    NoiseParams bad;
    bad.octaves = 0;
    CHECK(fill_noise(v, 4, 4, bad).error().message.find("/octaves") != std::string::npos);

    // Caps: refused from the sizes alone, nothing is allocated (the span is empty).
    auto samples = fill_noise({}, 20000, 20000, p);
    REQUIRE_FALSE(samples.ok());
    CHECK(samples.error().message.find("samples") != std::string::npos);
    NoiseParams heavy;
    heavy.octaves = 16;
    heavy.warpAmplitude = 10.0f;
    auto work = fill_noise({}, 16384, 16384, heavy);
    REQUIRE_FALSE(work.ok());
    CHECK(work.error().message.find("noise evaluations") != std::string::npos);
    CHECK(work.error().hint.find("octaves") != std::string::npos);
    CHECK(noise_fill_work(16384, 16384, heavy) == std::uint64_t(16384) * 16384 * (16 + 4));
    CHECK(noise_fill_work(0, 5, heavy) == 0);
    CHECK(noise_fill_work(1024, 1024, NoiseParams{}) == std::uint64_t(1024) * 1024 * 6);
}

TEST_CASE("noise: reference values stay put (the design is bit-identical on every platform)") {
    // The literals have 6 significant digits, so the tolerance is their rounding (5e-7), not a platform difference.
    CHECK(perlin_2d(1, 0.37f, 0.81f) == doctest::Approx(PERLIN2_REF).epsilon(1e-5));
    CHECK(value_2d(1, 0.37f, 0.81f) == doctest::Approx(VALUE2_REF).epsilon(1e-5));
    CHECK(cellular_2d(1, 0.37f, 0.81f).f1 == doctest::Approx(CELL2_REF).epsilon(1e-5));
    NoiseParams p;
    p.seed = 9;
    CHECK(sample_noise_2d(p, 123.4f, 56.7f) == doctest::Approx(FBM_REF).epsilon(1e-5));
}
