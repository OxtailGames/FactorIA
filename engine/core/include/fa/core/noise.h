// Seeded noise (M75.5): gradient (Perlin-style) noise, value noise and cellular (Worley) noise in 2D and 3D, the fractal
// combinators on top of them (fBm, ridged, billow, domain warp) and a grid fill that runs on the jobs system. Our own code;
// the terrain generator (`terrain.generate`) and anything else that needs procedural values uses this one module.
//
// Determinism. Every function is a pure function of (seed, parameters, position): no global state, no random generator, no
// clock. They use only + - * / floor and sqrt on floats and integer hashing (a 64-bit mix of the seed and the lattice
// coordinates), never the C library's transcendental functions (sin, cos, pow, exp), and the engine builds with floating
// point contraction off, so the same build gives the same bits on every thread count and the same values on every platform
// that follows IEEE 754 (docs/design/ARCHITECTURE.md, "Determinism of the maths"). `fill_noise` computes each sample
// independently, so a fill with 0, 1 or 16 job threads (or in inline mode) is bit-identical.
//
// Ranges. The primitives and `sample_noise_*` return values in [-1, 1] (never outside, even by rounding). A gradient
// noise reaches +-1 almost never: typical values lie in about [-0.7, 0.7], so remap the result (`output: "unit"` of
// NoiseParams gives [0, 1]) rather than assuming the extremes are used.
//
// Units. Positions are in the caller's world units (metres for terrain). The lattice of a primitive has a cell of 1 unit:
// `NoiseParams::frequency` (cycles per unit) is what scales it. Positions beyond about +-1e9 lattice cells repeat or
// saturate (the lattice index is clamped); float positions lose their fraction long before that.
#pragma once

#include <cstdint>
#include <span>
#include <string_view>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr int kMaxNoiseOctaves = 16;     // the most octaves of a fractal
inline constexpr int kMaxNoiseWarpOctaves = 8;  // the most octaves of the domain warp
// The most samples one fill_noise call computes (2^28: 16384 x 16384, a 1 GB float buffer).
inline constexpr std::uint64_t kMaxNoiseFillSamples = std::uint64_t(1) << 28;
// The most noise evaluations of one fill_noise call: samples x (octaves + warp octaves x axes). A deterministic work
// count (it depends only on the parameters, never on the speed of the machine); 2^31 takes tens of seconds on one thread.
inline constexpr std::uint64_t kMaxNoiseFillWork = std::uint64_t(1) << 31;

// ---------------------------------------------------------------------------------------------------- the primitives
// Gradient noise (improved Perlin: quintic fade, unit gradients from the hash of each lattice corner). Zero at every
// integer lattice point, smooth (continuous first and second derivative). Returns [-1, 1].
float perlin_2d(std::uint64_t seed, float x, float y);
float perlin_3d(std::uint64_t seed, float x, float y, float z);

// Value noise: a random value in [-1, 1] at each lattice point, blended with the quintic fade. Blockier than gradient noise
// (its features follow the lattice axes) but cheaper. Returns [-1, 1].
float value_2d(std::uint64_t seed, float x, float y);
float value_3d(std::uint64_t seed, float x, float y, float z);

// Cellular (Worley) noise: one feature point per lattice cell, at `0.5 + jitter * (random - 0.5)` of the cell on each axis
// (jitter 0 is a regular grid of points, 1 puts them anywhere in the cell). Distances are in lattice cells (the
// search covers the 3x3 or 3x3x3 neighbouring cells, so F1 is exact and F2 is exact except for rare near-ties at jitter 1).
struct CellularSample {
    float f1 = 0;         // distance to the nearest feature point, [0, ~1.5] cells (about 0.5 on average)
    float f2 = 0;         // distance to the second nearest, [f1, ~2] cells
    float f2MinusF1 = 0;  // f2 - f1, [0, ~1] cells: 0 on the borders between cells, which makes "cracks"
    float cellValue = 0;  // a random value in [0, 1) that is the same everywhere in the nearest cell (flat patches)
};
CellularSample cellular_2d(std::uint64_t seed, float x, float y, float jitter = 1.0f);
CellularSample cellular_3d(std::uint64_t seed, float x, float y, float z, float jitter = 1.0f);

// ---------------------------------------------------------------------------------------------------- the parameters
enum class NoiseType { Perlin, Value, Cellular };
enum class NoiseFractal { None, Fbm, Ridged, Billow };
enum class CellularReturn { F1, F2, F2MinusF1 };
enum class NoiseOutput { Signed, Unit };

// What `sample_noise_*` and `fill_noise` compute. Every field has a default that gives a usable terrain-like fBm.
// JSON (camelCase, every key optional): {"type":"perlin","dimension":2,"fractal":"fbm","cellularReturn":"f1","seed":0,
// "frequency":0.01,"octaves":6,"lacunarity":2,"gain":0.5,"offset":0,"jitter":1,"warpAmplitude":0,"warpFrequency":0.01,
// "warpOctaves":2,"output":"signed"}; noise_params_from_json refuses unknown keys, wrong types and values out of range with
// the JSON pointer of the field.
struct NoiseParams {
    NoiseType type = NoiseType::Perlin;        // "perlin" | "value" | "cellular": the primitive of every octave
    int dimension = 2;                         // fill_noise only: 2 (sample x, y) or 3 (sample x, y and the slice z)
    NoiseFractal fractal = NoiseFractal::Fbm;  // "none" | "fbm" | "ridged" | "billow": how octaves combine
    CellularReturn cellularReturn =
        CellularReturn::F1;       // "f1" | "f2" | "f2MinusF1": the distance a cellular noise returns
    std::uint64_t seed = 0;       // changes every pattern; the same seed always gives the same values
    float frequency = 0.01f;      // cycles per world unit of the first octave, > 0 and at most 1e6
    int octaves = 6;              // layers added by the fractal, 1..kMaxNoiseOctaves ("none" uses 1)
    float lacunarity = 2.0f;      // frequency multiplier between octaves, 1..8
    float gain = 0.5f;            // amplitude multiplier between octaves, 0..1
    float offset = 0.0f;          // ridged/billow: where the ridge line sits in the noise, -1..1 (0 = zero crossing)
    float jitter = 1.0f;          // cellular: how far feature points move from the cell centres, 0..1
    float warpAmplitude = 0.0f;   // domain warp: how far (world units) the position moves, 0 = off, at most 1e6
    float warpFrequency = 0.01f;  // domain warp: cycles per world unit of the warp noise, > 0 and at most 1e6
    int warpOctaves = 2;          // domain warp: fBm octaves of the warp noise, 1..kMaxNoiseWarpOctaves
    NoiseOutput output = NoiseOutput::Signed;  // "signed" = [-1, 1] | "unit" = [0, 1] (what fill_noise writes)

    friend bool operator==(const NoiseParams&, const NoiseParams&) = default;
};

// Checks every field (finite, in range) and says what to change; `pointer` is the JSON pointer of the NoiseParams in the
// caller's document ("/noise"), put in front of the field name in the error.
Result<void> validate_noise_params(const NoiseParams& params, std::string_view pointer = "");
// Reads a JSON object (the shape above), validated. Missing keys keep the defaults.
Result<NoiseParams> noise_params_from_json(const Json& value, std::string_view pointer = "");
// The full JSON object (every key), the inverse of noise_params_from_json.
Json noise_params_to_json(const NoiseParams& params);
// A JSON Schema of the object, with a description on every field (for a command's input schema).
Json noise_params_schema();

// ---------------------------------------------------------------------------------------------------- sampling
// The noise of `params` at one world position: domain warp, then the fractal of the primitive. The range is [-1, 1] for
// every combination (a ridged or billow fractal is remapped to it too); `output` is NOT applied here (only fill_noise
// applies it). Parameters must be valid (validate_noise_params); invalid ones give unspecified values (never a crash).
// sample_noise_2d always samples the plane and sample_noise_3d always the volume, whatever `params.dimension` says.
float sample_noise_2d(const NoiseParams& params, float x, float y);
float sample_noise_3d(const NoiseParams& params, float x, float y, float z);

// Fills a `width` x `height` grid, row by row (index = y * width + x), with the noise of `params`. Sample (i, j) is at the
// world position `origin + (i * cellSize, j * cellSize)` (the vertices of a heightfield), and a 3D noise is sampled on the
// plane `z`. Two grids whose origins differ by (width - 1) * cellSize share their edge samples, so tiles of a terrain line
// up. Values are in [-1, 1], or [0, 1] when `params.output` is Unit.
//
// Runs on the job system (fa/core/jobs.h, rows in chunks of about 16k samples); with no pool, in inline mode or on a web
// build without threads it runs on the calling thread. The result is bit-identical whatever the number of threads: each
// sample depends only on its own position.
//
// Errors, before any work and with a hint: invalid params; width or height below 1; `out.size() != width * height`;
// cellSize not finite or not > 0; origin or z not finite; more than kMaxNoiseFillSamples samples or kMaxNoiseFillWork
// evaluations (both counted in 64 bits, so a 32-bit target refuses a huge request instead of wrapping).
Result<void> fill_noise(std::span<float> out, int width, int height, const NoiseParams& params, Vec2 origin = {},
                        float cellSize = 1.0f, float z = 0.0f);

// The number of primitive evaluations fill_noise makes for this request (what kMaxNoiseFillWork limits), in 64 bits and
// saturating. 0 for a non-positive size.
std::uint64_t noise_fill_work(int width, int height, const NoiseParams& params);

}  // namespace fa
