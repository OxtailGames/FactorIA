// Heightfield erosion (M75.5): thermal erosion (material slides down slopes steeper than the talus angle) and droplet-based
// hydraulic erosion (rain droplets pick up sediment on slopes and drop it where they slow down), on a float grid of heights
// in metres. Pure CPU, our own code; the terrain generator (`terrain.generate`) runs it after the noise of fa/core/noise.h.
//
// The grid. `HeightfieldView` is a window on the caller's memory: `width` x `height` heights, row by row (index =
// y * width + x), vertices `cellSize` metres apart. Heights are changed in place.
//
// Determinism. Both functions give the same result for the same input and parameters on every thread count and on every
// platform that follows IEEE 754 (only + - * / and sqrt on floats, plus fa::det::tan for the talus angle; the engine
// builds with floating point contraction off):
//  - Thermal erosion is a Jacobi step (every cell reads the heights of the previous iteration and writes its own new
//    height), run on the jobs system in chunks of rows: the result does not depend on the number of threads.
//  - Hydraulic erosion is SERIAL, on purpose: droplets change the heights the next droplet reads, so any split of the
//    droplets over threads would make the result depend on the order the threads run. Droplets run one after the other from
//    a PCG stream seeded with `seed`. The cost: one thread, about 15 to 40 ns per droplet step, so the work cap
//    (kMaxHydraulicSteps = droplets x maxLifetime) is 2^28 steps, a few seconds at the cap.
//
// Mass. Thermal erosion moves height from a cell to its lower neighbours and nothing leaves the grid; a droplet deposits what
// it carries when it ends (lifetime over, or about to leave the grid) at its last position. So the sum of the heights
// is conserved up to float rounding: ErosionResult::volumeAfter - volumeBefore stays within about 1e-4 of the volume moved.
//
// Work caps are deterministic counts (cells x iterations, droplets x lifetime), checked with a teaching error before any
// memory is allocated or any height changes; sizes are computed in 64 bits and saturate (wasm32 safe).
#pragma once

#include <cstdint>
#include <span>
#include <string_view>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr int kMaxHeightfieldSide = 16384;  // the longest side of a heightfield, in samples
// The most extra memory erode_thermal allocates (three float buffers of the grid's size, 12 bytes a cell: about 9400 x 9400
// cells at most, less than the side cap allows); checked before it allocates.
inline constexpr std::uint64_t kMaxErosionScratchBytes = std::uint64_t(1) << 30;
// The most cell updates of one erode_thermal call: cells x iterations (2^30, about half a minute on one thread).
inline constexpr std::uint64_t kMaxThermalWork = std::uint64_t(1) << 30;
// The most droplet steps of one erode_hydraulic call: droplets x maxLifetime (2^28, a few seconds on one thread).
inline constexpr std::uint64_t kMaxHydraulicSteps = std::uint64_t(1) << 28;
inline constexpr int kMaxThermalIterations = 100000;
inline constexpr int kMaxDropletLifetime = 1024;
inline constexpr int kMaxErosionBrushRadius = 8;
inline constexpr std::int64_t kMaxDroplets = 100000000;

// A window on a heightfield the caller owns. `heights.size()` must be width * height.
struct HeightfieldView {
    std::span<float> heights;
    int width = 0;
    int height = 0;
    float cellSize = 1.0f;  // metres between neighbouring samples, finite and > 0
};

// What a run reports. Volumes are cubic metres: the sum of heights x cellSize^2 (summed in double, in row order).
struct ErosionResult {
    std::uint64_t workUnits = 0;  // thermal: cell updates (cells x iterations); hydraulic: droplet steps taken
    std::uint64_t droplets = 0;   // hydraulic: droplets simulated
    double volumeBefore = 0;      // the sum over the whole grid before
    double volumeAfter = 0;       // ... and after: equal to volumeBefore up to float rounding
    double erodedVolume = 0;      // volume taken out of cells (thermal: moved down a slope)
    double depositedVolume = 0;   // volume put into cells
    // Hydraulic with masks: the largest value written to each mask (0 without), to normalise them.
    double maxFlow = 0, maxErosion = 0, maxDeposition = 0;
};

// Optional hydraulic outputs, each empty (not written) or exactly width * height floats; they are cleared first.
// Useful later to paint splat layers: rock where the erosion is high, sand where sediment settled, a river bed where water
// flowed.
struct ErosionMasks {
    std::span<float>
        flow;  // water that passed over each cell: each step adds the droplet's water (starts at 1) bilinearly
    std::span<float> erosion;     // metres of height removed from each cell, >= 0
    std::span<float> deposition;  // metres of height added to each cell, >= 0
};

// ---------------------------------------------------------------------------------------------------------- thermal
// JSON: {"iterations":30,"talusAngle":35,"strength":0.5}, every key optional.
struct ThermalErosionParams {
    int iterations = 30;  // passes over the grid, 1..kMaxThermalIterations; more passes spread the material further
    float talusAngle =
        35.0f;  // degrees, > 0 and at most 89.9: a slope steeper than this slides (rock holds about 35 to 45)
    float strength =
        0.5f;  // fraction of the excess that moves per pass, > 0 and at most 1 (1 is the fastest stable step)

    friend bool operator==(const ThermalErosionParams&, const ThermalErosionParams&) = default;
};

Result<void> validate_thermal_params(const ThermalErosionParams& params, std::string_view pointer = "");
Result<ThermalErosionParams> thermal_params_from_json(const Json& value, std::string_view pointer = "");
Json thermal_params_to_json(const ThermalErosionParams& params);
Json thermal_params_schema();  // a JSON Schema with a description on every field

// Cell updates erode_thermal makes (cells x iterations), in 64 bits and saturating; 0 for a non-positive size.
std::uint64_t thermal_work(int width, int height, const ThermalErosionParams& params);

// Thermal erosion in place. Each pass, a cell whose drop to a neighbour (8 directions; the drop is divided by the
// distance to the neighbour) is steeper than tan(talusAngle) offers `strength / 2` of its largest excess to its lower
// neighbours in proportion to their excess. A receiver takes at most half the way up to its lowest donor (when its
// donors offer more, each gives proportionally less, and donors lose only what was taken). What holds: the sum of the
// heights is kept (up to float rounding; nothing leaves the grid), and every cell ends a pass within the range of its 3
// x 3 neighbourhood of the previous pass, so a 1-cell pit or spike does not overshoot (tested). Slopes tend to fall,
// but there is no bound per pass and none on the steepest slope. `strength` is how much of the excess a cell offers per
// pass: 1 is the fastest, lower smooths more slowly. Errors, before any change: a grid that is not 2 x 2 to
// kMaxHeightfieldSide, a `heights` size that is not width * height, a cellSize that is not finite and > 0, a height
// that is not finite (with its position), invalid params, a work or memory cap (kMaxThermalWork,
// kMaxErosionScratchBytes).
Result<ErosionResult> erode_thermal(const HeightfieldView& field, const ThermalErosionParams& params);

// --------------------------------------------------------------------------------------------------------- hydraulic
// JSON: {"seed":0,"droplets":50000,"maxLifetime":30,"inertia":0.05,"capacity":4,"minSlope":0.01,"deposition":0.3,
// "erosion":0.3,"evaporation":0.01,"gravity":4,"radius":3}, every key optional.
// Slopes are rise over run (dimensionless): the same terrain at a different cellSize erodes differently, as in nature.
struct HydraulicErosionParams {
    std::uint64_t seed = 0;  // seeds where droplets start (and which way a droplet on flat ground goes)
    std::int64_t droplets =
        50000;               // droplets to simulate, 0..kMaxDroplets (and droplets x maxLifetime <= kMaxHydraulicSteps)
    int maxLifetime = 30;    // steps a droplet takes at most, 1..kMaxDropletLifetime (one step is about one cell)
    float inertia = 0.05f;   // 0..0.99: how much a droplet keeps its direction instead of following the slope
    float capacity = 4.0f;   // > 0, at most 100: sediment a droplet can carry per unit of slope, speed and water
    float minSlope = 0.01f;  // 0..1: slope used for the capacity on flat ground, so droplets still carry a little
    float deposition = 0.3f;    // 0..1: fraction of the surplus sediment dropped per step when over capacity
    float erosion = 0.3f;       // 0..1: fraction of the free capacity picked up per step
    float evaporation = 0.01f;  // 0..0.5: fraction of its water a droplet loses per step (less water, less capacity)
    float gravity = 4.0f;       // 0..100: how strongly a drop in height speeds a droplet up (and a rise slows it)
    int radius = 3;             // 1..kMaxErosionBrushRadius: erosion is spread over the cells within this many cells

    friend bool operator==(const HydraulicErosionParams&, const HydraulicErosionParams&) = default;
};

Result<void> validate_hydraulic_params(const HydraulicErosionParams& params, std::string_view pointer = "");
Result<HydraulicErosionParams> hydraulic_params_from_json(const Json& value, std::string_view pointer = "");
Json hydraulic_params_to_json(const HydraulicErosionParams& params);
Json hydraulic_params_schema();  // a JSON Schema with a description on every field

// droplets x maxLifetime, in 64 bits and saturating (what kMaxHydraulicSteps limits); 0 for a negative count.
std::uint64_t hydraulic_work(const HydraulicErosionParams& params);

// Droplet erosion in place (serial, see the header comment). Every droplet starts at a random position with some water and no
// sediment and follows the downhill direction (blended with its previous one by `inertia`); on each step it carries up to
// capacity x slope x speed x water of sediment: above that (or going uphill) it drops sediment, below it it erodes the cells
// around it (a brush of `radius` cells, the removed height spread by distance, never digging below the cell it moves to).
// Speed follows the height drop (gravity), water evaporates. It ends after maxLifetime steps or when it would leave the grid,
// dropping what it still carries. Same errors as erode_thermal for the grid, the params and the caps; `masks` must each be
// empty or width * height floats.
Result<ErosionResult> erode_hydraulic(const HeightfieldView& field, const HydraulicErosionParams& params,
                                      const ErosionMasks& masks = {});

}  // namespace fa
