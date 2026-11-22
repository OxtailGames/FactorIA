// Heightfield erosion (fa/core/erosion.h): thermal slopes and mass, hydraulic determinism, masks, parameters and caps.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#include "fa/core/erosion.h"
#include "fa/core/jobs.h"
#include "fa/core/noise.h"

using namespace fa;

namespace {

struct PoolScope {
    explicit PoolScope(const jobs::Settings& s) { REQUIRE(jobs::start(s).ok()); }
    ~PoolScope() { jobs::stop(); }
};

// A terrain of `w` x `h` samples, heights 0..amplitude metres.
std::vector<float> terrain(int w, int h, float amplitude, float cellSize, std::uint64_t seed = 1) {
    NoiseParams p;
    p.seed = seed;
    p.frequency = 0.02f;
    p.octaves = 5;
    p.output = NoiseOutput::Unit;
    std::vector<float> v(std::size_t(w) * std::size_t(h));
    REQUIRE(fill_noise(v, w, h, p, {}, cellSize).ok());
    for (float& x : v) x *= amplitude;
    return v;
}

// The steepest slope (rise over run) between a cell and its 8 neighbours.
float max_slope(const std::vector<float>& hs, int w, int h, float cell) {
    float worst = 0;
    for (int j = 0; j < h; ++j) {
        for (int i = 0; i < w; ++i) {
            for (int dj = -1; dj <= 1; ++dj) {
                for (int di = -1; di <= 1; ++di) {
                    const int x = i + di, y = j + dj;
                    if ((di == 0 && dj == 0) || x < 0 || y < 0 || x >= w || y >= h) continue;
                    const float run = cell * ((di != 0 && dj != 0) ? 1.41421356f : 1.0f);
                    worst = std::max(worst, std::fabs(hs[std::size_t(j) * w + i] - hs[std::size_t(y) * w + x]) / run);
                }
            }
        }
    }
    return worst;
}

std::size_t cells_over(const std::vector<float>& hs, int w, int h, float cell, float slope) {
    std::size_t n = 0;
    for (int j = 0; j < h; ++j)
        for (int i = 0; i < w; ++i) {
            float worst = 0;
            for (int dj = -1; dj <= 1; ++dj)
                for (int di = -1; di <= 1; ++di) {
                    const int x = i + di, y = j + dj;
                    if ((di == 0 && dj == 0) || x < 0 || y < 0 || x >= w || y >= h) continue;
                    const float run = cell * ((di != 0 && dj != 0) ? 1.41421356f : 1.0f);
                    worst = std::max(worst, (hs[std::size_t(j) * w + i] - hs[std::size_t(y) * w + x]) / run);
                }
            n += worst > slope;
        }
    return n;
}

bool same_bits(const std::vector<float>& a, const std::vector<float>& b) {
    return a.size() == b.size() && std::memcmp(a.data(), b.data(), a.size() * sizeof(float)) == 0;
}

HeightfieldView view(std::vector<float>& v, int w, int h, float cell = 1.0f) { return {v, w, h, cell}; }

}  // namespace

TEST_CASE("thermal erosion: slopes above the talus angle go down and the volume is kept") {
    const int w = 96, h = 96;
    const float cell = 2.0f;
    std::vector<float> v = terrain(w, h, 40.0f, cell);
    const std::vector<float> before = v;
    ThermalErosionParams p;
    p.iterations = 150;
    p.talusAngle = 30.0f;
    const float talus = 0.57735f;  // tan(30 degrees)
    const std::size_t overBefore = cells_over(v, w, h, cell, talus * 1.02f);
    REQUIRE(overBefore > 100);
    auto r = erode_thermal(view(v, w, h, cell), p);
    REQUIRE(r.ok());
    CHECK(v != before);
    CHECK(max_slope(v, w, h, cell) < max_slope(before, w, h, cell));
    CHECK(cells_over(v, w, h, cell, talus * 1.02f) < overBefore / 4);
    CHECK(r->workUnits == std::uint64_t(w) * h * 150);
    CHECK(r->erodedVolume > 0);
    CHECK(r->erodedVolume == r->depositedVolume);
    // Mass: the sum of the heights is kept up to float rounding (well under 5e-5 of the volume that moved).
    CHECK(std::fabs(r->volumeAfter - r->volumeBefore) <= 5e-5 * r->erodedVolume + 1e-7 * std::fabs(r->volumeBefore));
    float lo = 1e9f, hi = -1e9f, lo0 = 1e9f, hi0 = -1e9f;
    for (float x : v) lo = std::min(lo, x), hi = std::max(hi, x);
    for (float x : before) lo0 = std::min(lo0, x), hi0 = std::max(hi0, x);
    CHECK(hi <= hi0);  // material never piles above the old peak
    CHECK(lo >= lo0);  // or sinks below the old floor
}

TEST_CASE("thermal erosion: a spike spreads into a cone no steeper than the talus angle") {
    const int w = 41, h = 41;
    std::vector<float> v(std::size_t(w) * h, 0.0f);
    v[20 * w + 20] = 50.0f;
    ThermalErosionParams p;
    p.iterations = 400;
    p.talusAngle = 40.0f;
    p.strength = 0.5f;
    auto r = erode_thermal(view(v, w, h), p);
    REQUIRE(r.ok());
    CHECK(v[20 * w + 20] < 5.0f);
    CHECK(max_slope(v, w, h, 1.0f) < 0.8391f * 1.15f);  // tan(40 degrees) plus a margin
    CHECK(std::fabs(r->volumeAfter - 50.0) < 1e-3);
}

namespace {

// One pass at a time: every cell ends within the min/max of its 3 x 3 neighbourhood of the previous pass (the promise of
// erode_thermal, 1e-3 margin), and no height leaves the initial range. The slope checks are what these three shapes do
// at talus 20 on a 21 x 21 grid, not a promise: slopes only tend to fall.
void check_no_overshoot(std::vector<float> v, int w, int h, float strength, int passes, const char* what) {
    float lo0 = 1e9f, hi0 = -1e9f;
    for (float x : v) lo0 = std::min(lo0, x), hi0 = std::max(hi0, x);
    ThermalErosionParams p;
    p.iterations = 1;
    p.talusAngle = 20.0f;
    p.strength = strength;
    const float slope0 = max_slope(v, w, h, 1.0f);
    float slope = slope0;
    for (int it = 0; it < passes; ++it) {
        INFO(what << ", strength " << strength << ", pass " << it);
        const std::vector<float> prev = v;
        auto r = erode_thermal(view(v, w, h), p);
        REQUIRE(r.ok());
        const float next = max_slope(v, w, h, 1.0f);
        CHECK(next <= slope0 * 1.0001f);
        if (it == 0) CHECK(next < slope0 * 0.9f);  // the first pass already flattens the worst slope
        slope = next;
        for (int j = 0; j < h; ++j)
            for (int i = 0; i < w; ++i) {
                float lo = 1e9f, hi = -1e9f;
                for (int dj = -1; dj <= 1; ++dj)
                    for (int di = -1; di <= 1; ++di) {
                        const int x = i + di, y = j + dj;
                        if (x < 0 || y < 0 || x >= w || y >= h) continue;
                        const float q = prev[std::size_t(y) * w + x];
                        lo = std::min(lo, q), hi = std::max(hi, q);
                    }
                const float now = v[std::size_t(j) * w + i];
                REQUIRE(now <= hi + 1e-3f);
                REQUIRE(now >= lo - 1e-3f);
                REQUIRE(now <= hi0 + 1e-3f);
                REQUIRE(now >= lo0 - 1e-3f);
            }
    }
    // 60 passes of strength >= 0.5 on a 21 x 21 grid at talus 20 spread each shape out over most of the grid.
    CHECK(slope < slope0 * 0.25f);
}

}  // namespace

TEST_CASE("thermal erosion: a pit, a spike and a checkerboard never overshoot, whatever the strength") {
    const int w = 21, h = 21;
    for (float strength : {0.5f, 1.0f}) {
        std::vector<float> pit(std::size_t(w) * h, 100.0f);
        pit[10 * w + 10] = 0.0f;
        check_no_overshoot(pit, w, h, strength, 60, "pit");

        std::vector<float> spike(std::size_t(w) * h, 0.0f);
        spike[10 * w + 10] = 100.0f;
        check_no_overshoot(spike, w, h, strength, 60, "spike");

        std::vector<float> checker(std::size_t(w) * h, 0.0f);
        for (int j = 0; j < h; ++j)
            for (int i = 0; i < w; ++i) checker[std::size_t(j) * w + i] = ((i + j) & 1) ? 100.0f : 0.0f;
        check_no_overshoot(checker, w, h, strength, 60, "checkerboard");
    }
    // The pit in particular: after one pass it is filled to at most halfway, never above the plateau it was cut into.
    std::vector<float> pit(std::size_t(w) * h, 100.0f);
    pit[10 * w + 10] = 0.0f;
    ThermalErosionParams p;
    p.iterations = 1;
    p.talusAngle = 35.0f;
    p.strength = 0.5f;
    auto r = erode_thermal(view(pit, w, h), p);
    REQUIRE(r.ok());
    CHECK(pit[10 * w + 10] <= 50.0f + 1e-3f);
    CHECK(pit[10 * w + 10] > 20.0f);  // talus 35, strength 0.5: the 8 donors offer ~100 each, so it is ~half filled
    CHECK(std::fabs(r->volumeAfter - r->volumeBefore) < 1e-2);
}

TEST_CASE("thermal erosion: flat ground is left alone, and the result does not depend on the threads") {
    std::vector<float> flat(30 * 30, 12.5f);
    const std::vector<float> flat0 = flat;
    REQUIRE(erode_thermal(view(flat, 30, 30), ThermalErosionParams{}).ok());
    CHECK(flat == flat0);

    const int w = 150, h = 130;  // many chunks
    const std::vector<float> start = terrain(w, h, 200.0f, 1.0f, 5);
    ThermalErosionParams p;
    p.iterations = 12;
    p.talusAngle = 25.0f;
    std::vector<float> reference = start;
    REQUIRE(erode_thermal(view(reference, w, h), p).ok());  // no pool
    CHECK(reference != start);
    for (const jobs::Settings& s : {jobs::Settings::inline_jobs(), jobs::Settings::threads(0),
                                    jobs::Settings::threads(1), jobs::Settings::threads(4)}) {
        PoolScope pool(s);
        std::vector<float> v = start;
        REQUIRE(erode_thermal(view(v, w, h), p).ok());
        CHECK(same_bits(v, reference));
    }
}

TEST_CASE("thermal erosion: bad input is refused before any change, with a hint") {
    std::vector<float> v(16 * 16, 1.0f);
    ThermalErosionParams p;
    CHECK_FALSE(erode_thermal(view(v, 16, 8), p).ok());  // size mismatch
    CHECK_FALSE(erode_thermal(view(v, 16, 16, 0.0f), p).ok());
    CHECK_FALSE(erode_thermal(view(v, 1, 256), p).ok());
    v[3 * 16 + 5] = std::nanf("");
    auto nanResult = erode_thermal(view(v, 16, 16), p);
    REQUIRE_FALSE(nanResult.ok());
    CHECK(nanResult.error().message.find("x=5, y=3") != std::string::npos);
    v[3 * 16 + 5] = 1.0f;
    p.talusAngle = 90.0f;
    auto angleResult = erode_thermal(view(v, 16, 16), p);
    REQUIRE_FALSE(angleResult.ok());
    CHECK(angleResult.error().message.find("/talusAngle") != std::string::npos);
    CHECK_FALSE(angleResult.error().hint.empty());
    p = {};
    p.strength = 0.0f;
    CHECK_FALSE(erode_thermal(view(v, 16, 16), p).ok());
    // Work cap: cells x iterations, refused before the buffers are allocated.
    std::vector<float> big(1024 * 1024, 0.0f);
    p = {};
    p.iterations = kMaxThermalIterations;
    auto capResult = erode_thermal(view(big, 1024, 1024), p);
    REQUIRE_FALSE(capResult.ok());
    CHECK(capResult.error().message.find("cell updates") != std::string::npos);
    CHECK(capResult.error().hint.find("iterations") != std::string::npos);
    CHECK(thermal_work(1024, 1024, p) == std::uint64_t(1024) * 1024 * kMaxThermalIterations);
    CHECK(thermal_work(0, 5, p) == 0);
}

TEST_CASE("hydraulic erosion: same seed same terrain, another seed another one") {
    const int w = 96, h = 96;
    const std::vector<float> start = terrain(w, h, 80.0f, 1.0f);
    HydraulicErosionParams p;
    p.seed = 11;
    p.droplets = 8000;
    std::vector<float> a = start, b = start, c = start;
    auto ra = erode_hydraulic(view(a, w, h), p);
    REQUIRE(ra.ok());
    REQUIRE(erode_hydraulic(view(b, w, h), p).ok());
    CHECK(same_bits(a, b));
    CHECK(a != start);
    p.seed = 12;
    REQUIRE(erode_hydraulic(view(c, w, h), p).ok());
    CHECK(c != a);
    CHECK(ra->droplets == 8000);
    CHECK(ra->workUnits > 8000);
    CHECK(ra->workUnits <= 8000u * 30u);
    // A running job pool changes nothing (the erosion is serial on purpose).
    PoolScope pool(jobs::Settings::threads(4));
    std::vector<float> d = start;
    p.seed = 11;
    REQUIRE(erode_hydraulic(view(d, w, h), p).ok());
    CHECK(same_bits(a, d));
}

TEST_CASE("hydraulic erosion: the volume is kept, peaks come down and the masks add up") {
    const int w = 96, h = 96;
    const float cell = 1.5f;
    const std::vector<float> start = terrain(w, h, 90.0f, cell, 3);
    std::vector<float> v = start;
    std::vector<float> flow(v.size()), erosion(v.size()), deposition(v.size());
    HydraulicErosionParams p;
    p.seed = 5;
    p.droplets = 20000;
    auto r = erode_hydraulic(view(v, w, h, cell), p, {flow, erosion, deposition});
    REQUIRE(r.ok());
    CHECK(r->erodedVolume > 0);
    CHECK(r->depositedVolume > 0);
    // Mass: what was taken was put back (float rounding only).
    CHECK(std::fabs(r->volumeAfter - r->volumeBefore) <= 1e-3 * r->erodedVolume);
    CHECK(std::fabs(r->erodedVolume - r->depositedVolume) <= 1e-3 * r->erodedVolume);
    // The masks are the same quantities cell by cell.
    double e = 0, d = 0, f = 0;
    for (std::size_t i = 0; i < v.size(); ++i) {
        CHECK(erosion[i] >= 0.0f);
        CHECK(deposition[i] >= 0.0f);
        CHECK(flow[i] >= 0.0f);
        e += double(erosion[i]);
        d += double(deposition[i]);
        f += double(flow[i]);
        CHECK(std::fabs((v[i] - start[i]) - (deposition[i] - erosion[i])) < 5e-3f);
    }
    const double cs2 = double(cell) * double(cell);
    CHECK(e * cs2 == doctest::Approx(r->erodedVolume).epsilon(1e-3));
    CHECK(d * cs2 == doctest::Approx(r->depositedVolume).epsilon(1e-3));
    CHECK(f > double(r->workUnits) * 0.5);  // each step adds the droplet's water (1 at first, then less)
    CHECK(r->maxFlow > 1.0);
    CHECK(r->maxErosion > 0.0);
    CHECK(r->maxDeposition > 0.0);
    // Erosion cuts the terrain: the highest point does not go up and the roughness (slopes) changes.
    CHECK(*std::max_element(v.begin(), v.end()) <= *std::max_element(start.begin(), start.end()) + 1e-3f);
    CHECK(max_slope(v, w, h, cell) != max_slope(start, w, h, cell));
    // Masks left out are not written, and a cleared mask does not keep an earlier run.
    std::vector<float> v2 = start;
    std::vector<float> dirty(v.size(), 9.0f);
    auto r2 = erode_hydraulic(view(v2, w, h, cell), p, {{}, dirty, {}});
    REQUIRE(r2.ok());
    CHECK(same_bits(v, v2));           // the masks never change the heights
    CHECK(same_bits(dirty, erosion));  // cleared first: the 9s are gone and it equals the first run's mask
}

TEST_CASE("hydraulic erosion: a lone hill is cut down and the sediment settles lower") {
    const int w = 64, h = 64;
    std::vector<float> v(std::size_t(w) * h, 0.0f);
    for (int j = 0; j < h; ++j)
        for (int i = 0; i < w; ++i) {
            const float dx = float(i - 32), dy = float(j - 32);
            v[std::size_t(j) * w + i] = std::max(0.0f, 20.0f - std::sqrt(dx * dx + dy * dy) * 0.8f);
        }
    const std::vector<float> start = v;
    HydraulicErosionParams p;
    p.droplets = 15000;
    auto r = erode_hydraulic(view(v, w, h), p);
    REQUIRE(r.ok());
    CHECK(v[32 * w + 32] < start[32 * w + 32]);  // the summit lost height
    CHECK(std::fabs(r->volumeAfter - r->volumeBefore) <= 1e-3 * r->erodedVolume);
}

TEST_CASE("hydraulic erosion: parameters are validated and read from JSON") {
    auto ok =
        hydraulic_params_from_json(Json::parse(R"({"seed":7,"droplets":1000,"radius":2,"inertia":0.1})"), "/erosion");
    REQUIRE(ok.ok());
    CHECK(ok->seed == 7);
    CHECK(ok->droplets == 1000);
    CHECK(ok->radius == 2);
    auto again = hydraulic_params_from_json(hydraulic_params_to_json(*ok));
    REQUIRE(again.ok());
    CHECK(*again == *ok);
    auto typo = hydraulic_params_from_json(Json::parse(R"({"droplet":5})"), "/erosion");
    REQUIRE_FALSE(typo.ok());
    CHECK(typo.error().message.find("/erosion/droplet") != std::string::npos);
    CHECK(typo.error().hint.find("droplets") != std::string::npos);
    CHECK_FALSE(hydraulic_params_from_json(Json::parse(R"({"droplets":-5})")).ok());
    CHECK_FALSE(hydraulic_params_from_json(Json::parse(R"({"radius":99})")).ok());
    CHECK_FALSE(hydraulic_params_from_json(Json::parse(R"({"inertia":1})")).ok());
    CHECK_FALSE(hydraulic_params_from_json(Json::parse(R"({"capacity":0})")).ok());
    CHECK_FALSE(hydraulic_params_from_json(Json::parse(R"({"evaporation":"x"})")).ok());
    for (const Json& schema : {hydraulic_params_schema(), thermal_params_schema()})
        for (auto it = schema["properties"].begin(); it != schema["properties"].end(); ++it)
            CHECK_MESSAGE(it.value().contains("description"), it.key());
    CHECK(hydraulic_params_schema()["properties"].size() == hydraulic_params_to_json({}).size());
    auto th = thermal_params_from_json(Json::parse(R"({"talusAngle":45})"));
    REQUIRE(th.ok());
    CHECK(th->talusAngle == 45.0f);
    CHECK_FALSE(thermal_params_from_json(Json::parse(R"({"iteration":4})")).ok());
    auto rounded = thermal_params_from_json(thermal_params_to_json(*th));
    REQUIRE(rounded.ok());
    CHECK(*rounded == *th);
}

TEST_CASE("hydraulic erosion: the work cap is a count of droplet steps, refused up front") {
    HydraulicErosionParams p;
    p.droplets = 20000000;
    p.maxLifetime = 100;  // 2e9 steps
    auto r = validate_hydraulic_params(p, "/erosion");
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("/erosion/droplets") != std::string::npos);
    CHECK(r.error().message.find("droplet steps") != std::string::npos);
    CHECK_FALSE(r.error().hint.empty());
    std::vector<float> v(16 * 16, 1.0f);
    CHECK_FALSE(erode_hydraulic(view(v, 16, 16), p).ok());
    CHECK(v == std::vector<float>(16 * 16, 1.0f));
    CHECK(hydraulic_work(p) == std::uint64_t(2000000000));
    p.droplets = kMaxHydraulicSteps / 100;
    CHECK(validate_hydraulic_params(p).ok());
    p.droplets = kMaxHydraulicSteps / 100 + 1;
    CHECK_FALSE(validate_hydraulic_params(p).ok());
    // Masks of the wrong size, a bad grid and non-finite heights.
    p = {};
    p.droplets = 10;
    std::vector<float> small(10);
    auto mask = erode_hydraulic(view(v, 16, 16), p, {small, {}, {}});
    REQUIRE_FALSE(mask.ok());
    CHECK(mask.error().message.find("flow mask") != std::string::npos);
    CHECK_FALSE(erode_hydraulic(view(v, 16, 8), p).ok());
    v[40] = INFINITY;
    CHECK(erode_hydraulic(view(v, 16, 16), p).error().message.find("x=8, y=2") != std::string::npos);
    // Zero droplets is a valid no-op.
    v[40] = 1.0f;
    p.droplets = 0;
    auto none = erode_hydraulic(view(v, 16, 16), p);
    REQUIRE(none.ok());
    CHECK(none->workUnits == 0);
    CHECK(v == std::vector<float>(16 * 16, 1.0f));
}
