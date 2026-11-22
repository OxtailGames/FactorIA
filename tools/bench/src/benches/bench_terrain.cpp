// Terrain generation benchmarks (fa/core/noise.h, fa/core/erosion.h): the noise grid fill and the droplet erosion, the two
// costs of `terrain.generate`. Every run returns a checksum of the result, the same whatever the threads.
#include <cstddef>
#include <cstdint>
#include <memory>
#include <vector>

#include "benches.h"
#include "fa/core/erosion.h"
#include "fa/core/noise.h"

namespace fa::bench {

namespace {

// The checksum of a grid: a few samples summed in a fixed order, rounded.
double checksum(const std::vector<float>& v) {
    double s = 0;
    for (std::size_t i = 0; i < v.size(); i += 997) s += double(v[i]);
    return double(std::int64_t(s * 1000.0) % 1000003);
}

Bench noise_fill() {
    Bench b;
    b.name = "terrain.noise_fill";
    b.summary = "fill_noise: a 1024 x 1024 grid of Perlin fBm, 6 octaves (6.3 million noise evaluations)";
    b.warnRatio = 1.8;  // with `--jobs` > 0 the time depends on how busy the machine is
    b.failRatio = 3.0;
    b.make = [] {
        constexpr int kSide = 1024;
        auto out = std::make_shared<std::vector<float>>(std::size_t(kSide) * kSide, 0.0f);
        Prepared p;
        p.items = std::int64_t(kSide) * kSide;
        p.unit = "samples";
        p.run = [out] {
            NoiseParams params;
            params.seed = 42;
            params.frequency = 0.004f;
            params.octaves = 6;
            (void)fill_noise(*out, kSide, kSide, params);
            return checksum(*out);
        };
        return p;
    };
    return b;
}

Bench hydraulic() {
    Bench b;
    b.name = "terrain.hydraulic_erosion";
    b.summary = "erode_hydraulic: 50000 droplets on a 512 x 512 heightfield of ridged noise (serial)";
    b.make = [] {
        constexpr int kSide = 512;
        NoiseParams np;
        np.seed = 7;
        np.frequency = 0.004f;
        np.fractal = NoiseFractal::Ridged;
        np.output = NoiseOutput::Unit;
        auto base = std::make_shared<std::vector<float>>(std::size_t(kSide) * kSide, 0.0f);
        (void)fill_noise(*base, kSide, kSide, np);
        for (float& h : *base) h *= 150.0f;
        auto work = std::make_shared<std::vector<float>>(*base);
        Prepared p;
        p.items = 50000;
        p.unit = "droplets";
        p.prepare = [base, work] { *work = *base; };
        p.run = [work] {
            HydraulicErosionParams params;
            params.seed = 1;
            params.droplets = 50000;
            (void)erode_hydraulic({*work, kSide, kSide, 1.0f}, params);
            return checksum(*work);
        };
        return p;
    };
    return b;
}

Bench thermal() {
    Bench b;
    b.name = "terrain.thermal_erosion";
    b.summary = "erode_thermal: 20 iterations on a 512 x 512 heightfield of ridged noise";
    b.warnRatio = 1.8;
    b.failRatio = 3.0;
    b.make = [] {
        constexpr int kSide = 512;
        NoiseParams np;
        np.seed = 7;
        np.frequency = 0.004f;
        np.fractal = NoiseFractal::Ridged;
        np.output = NoiseOutput::Unit;
        auto base = std::make_shared<std::vector<float>>(std::size_t(kSide) * kSide, 0.0f);
        (void)fill_noise(*base, kSide, kSide, np);
        for (float& h : *base) h *= 150.0f;
        auto work = std::make_shared<std::vector<float>>(*base);
        Prepared p;
        p.items = std::int64_t(kSide) * kSide * 20;
        p.unit = "cell updates";
        p.prepare = [base, work] { *work = *base; };
        p.run = [work] {
            ThermalErosionParams params;
            params.iterations = 20;
            (void)erode_thermal({*work, kSide, kSide, 1.0f}, params);
            return checksum(*work);
        };
        return p;
    };
    return b;
}

}  // namespace

void add_terrain_benches(std::vector<Bench>& out) {
    out.push_back(noise_fill());
    out.push_back(hydraulic());
    out.push_back(thermal());
}

}  // namespace fa::bench
