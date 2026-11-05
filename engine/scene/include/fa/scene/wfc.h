// Level generation from an example: Wave Function Collapse, FactorIA's own implementation of the published algorithm
// (the overlapping model and the simple tiled model, lowest-entropy cell observation with a weighted choice, constraint
// propagation, restart on contradiction). Nothing here touches a World: the command tilemap.generate (fa_runtime) and the
// scripts feed it grids of tile values and read grids back.
//
// THE PIECES
//   * A Sample is a grid of SYMBOLS (small integers; the callers map glyphs or tile values to them).
//   * A PatternModel says which patterns exist, how often each one occurs (its weight) and which patterns may stand next to
//     each other in each direction. build_overlapping_model() learns NxN patterns from a Sample; build_terrain_model() reads
//     the adjacency from the autotile rules (fa/scene/autotile.h); both end in the same structure, so the solver does not
//     know which model made it.
//   * A Generator solves a grid of cells of a model. It is STEPPABLE: step(budget) does a bounded amount of work and can be
//     called again next frame; run() steps to the end. A contradiction restarts with the next derived seed up to
//     `maxAttempts`.
//   * GenerateOptions carries the hooks the constraint layer plugs into: `cellRules` (a cell may only hold some symbols; a fixed
//     cell is a rule with one symbol) are applied at the start of every attempt, and `accept` is asked about every finished
//     grid (minimum and maximum tile counts, reachability...) and may refuse it, which counts as a retry.
//
// DETERMINISM. The same model, size, seed and options give the same grid on every platform and standard library: the random
// numbers come from fa::Rng (PCG32) with seeds derived by an integer mixer, the entropy that picks the next cell is computed in
// integer fixed point (a Q20 base-2 logarithm built from integer shifts, no <cmath>), every container that decides an order is
// an ordered one, and ties are broken by a number drawn per cell at the start of the attempt, then by the cell index.
//
// MEMORY AND TIME. The solver keeps, per output cell, a bit per pattern and four 16-bit support counters per pattern, plus a
// stack of pending removals (at most one per cell and pattern) and the entropy heap (at most 4 entries per cell: it is rebuilt
// when stale entries would push it past that); estimate_generator_memory() adds the model's own tables and says how many bytes
// that is before anything is allocated, and create() refuses a request above kWfcMemoryBudget with a message that says what to
// shrink. GenStats::peakBytes is what the vectors really held at the end, always at most the estimate. `ms` in the stats is the
// wall time and `memoryBytes` / `peakBytes` are byte counts of this compiler's containers: they differ between runs and machines and are NOT
// part of the determinism promise; `work` and the other counters are.
//
// CONSTRAINTS. `forbidden` symbols never appear (the patterns that contain them are removed), a CellRule fixes or restricts one
// output cell, a CountRule says how many cells of some symbols the finished grid must hold (min / max): a grid that misses a
// minimum is refused and the next attempt pins the missing cells at positions drawn from its own seed, so a rare tile still
// turns up. `accept` is the last word (reachability, ...). All of it is deterministic.
#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/types.h"
#include "fa/scene/autotile.h"

namespace fa::wfc {

constexpr int kMinPatternSize = 2;                          // n of the overlapping model
constexpr int kMaxPatternSize = 5;
constexpr std::size_t kMaxPatterns = 20000;                 // distinct patterns of a model (16-bit pattern ids and counters)
constexpr std::size_t kMaxCompatEntries = 48'000'000;       // adjacency pairs of a model
constexpr std::size_t kMaxSampleCells = 262144;             // 512 x 512
constexpr int kMaxOutputSide = 2048;
constexpr std::size_t kWfcMemoryBudget = 256u * 1024u * 1024u;  // bytes of solver state of one generation
constexpr int kMaxAttempts = 1000;
constexpr std::uint64_t kMaxTotalWeight = 0xFFFFFFFFull;      // the weights of a model add up to less than 2^32 (the weighted choice draws 32 bits)

// Directions of the grid, in the order every per-direction array uses: +x (east), +y (south: rows grow downwards), -x, -y.
// opposite(d) == d ^ 2.
constexpr int kDirs = 4;
constexpr int kDx[kDirs] = {1, 0, -1, 0};
constexpr int kDy[kDirs] = {0, 1, 0, -1};

// A grid of symbols (>= 0), row-major, row 0 = top.
struct Sample {
    int width = 0;
    int height = 0;
    std::vector<int> cells;        // width * height symbol ids
    int symbolCount = 0;           // every id is < symbolCount
};

// What a model needs to run: patterns with weights and adjacency.
struct PatternModel {
    int n = 1;                                   // a pattern is n x n symbols (1 for the tiled model)
    int symbolCount = 0;
    std::vector<std::uint32_t> weights;          // per pattern: how often it occurs (>= 1)
    std::vector<int> symbols;                    // patterns * n * n symbol ids, each pattern row-major
    // compat[d][p]: the patterns (ascending) that may stand in direction d next to pattern p. The relation is symmetric:
    // q is in compat[d][p] exactly when p is in compat[d ^ 2][q].
    std::vector<std::vector<std::uint16_t>> compat[kDirs];
    // edgeOk[p * 4 + d]: pattern p may sit on a map edge with nothing beyond it in direction d (non-periodic output).
    std::vector<std::uint8_t> edgeOk;
    std::size_t sampleCells = 0;                 // how many cells the sample had (stats)

    std::size_t pattern_count() const { return weights.size(); }
    int symbol_at(std::size_t pattern, int dx, int dy) const { return symbols[pattern * std::size_t(n * n) + std::size_t(dy * n + dx)]; }
};

struct OverlapOptions {
    int n = 3;                                   // pattern side, kMinPatternSize..kMaxPatternSize
    int symmetry = 1;                            // 1 as in the sample, 2 + mirrored, 4 the four rotations, 8 rotations and mirrors
    bool periodicInput = false;                  // the sample wraps around its edges (patterns cross them)
};

// Learns the n x n patterns of the sample (and their rotations / mirrors for symmetry > 1) with their counts, and which of them
// overlap consistently in each direction. Errors teach: an empty sample, n out of range, a sample smaller than n, more than
// kMaxPatterns distinct patterns, an adjacency table above kMaxCompatEntries.
Result<std::shared_ptr<PatternModel>> build_overlapping_model(const Sample& sample, const OverlapOptions& options);

// The tiled model made from autotile rules: one pattern per (tile value, slot) of every terrain plus the empty cell. Two
// patterns may be neighbours when the sides they share agree about the terrain: a tile whose east bit is set needs an east
// neighbour of its terrain (or one that terrain joins), and a tile whose east bit is clear needs one that is not. The slot's
// four orthogonal bits are the sockets; the diagonal bits of blob47 are not: run retile_terrain_grid() (fa/scene/autotile.h) on the result. The symbol of a pattern is
// the index of its tile value in `tileValues`. `tileWeights` (tile value -> weight, optional) sets the weight of every
// pattern of that tile value; a tile value not listed weighs 1. The weights of all the patterns together must stay below 2^32
// and the adjacency table below kMaxCompatEntries (the same limits as the overlapping model); an error says what to change.
struct TerrainModel {
    std::shared_ptr<PatternModel> model;
    std::vector<int> tileValues;                 // symbol id -> tile value (-1 = empty is always symbol 0)
    std::vector<std::string> patternTerrain;     // per pattern: its terrain's name ("" = the empty cell)
};
Result<TerrainModel> build_terrain_model(const std::vector<Terrain>& terrains, const std::vector<std::pair<int, std::uint32_t>>& tileWeights);

// ---------------------------------------------------------------------------------------------------------- generator

// The output cell (x, y) may only hold one of `allowed` (symbol ids). A fixed cell has one.
struct CellRule {
    int x = 0;
    int y = 0;
    std::vector<int> allowed;
};

// The finished grid must hold between `min` and `max` cells whose symbol is one of `symbols`.
struct CountRule {
    std::vector<int> symbols;
    int min = 0;
    int max = -1;                                // -1 = no maximum
    std::string name;                            // for messages ("treasure"); empty = the symbol ids
};

struct GenerateOptions {
    int width = 0;                               // output cells
    int height = 0;
    bool periodic = false;                       // the output wraps around its edges
    std::uint64_t seed = 0;
    int maxAttempts = 10;                        // 1..kMaxAttempts; a contradiction or a refused grid uses one
    std::vector<CellRule> cellRules;
    std::vector<int> forbidden;                  // symbols no cell may hold
    std::vector<CountRule> counts;               // minimum / maximum cells per symbol group (checked on every finished grid)
    // Asked about every finished grid (width * height symbols). Return false to refuse it (with `why`): the generator retries
    // with the next seed and, after maxAttempts, fails with the last reason. Must be deterministic.
    std::function<bool(const std::vector<int>& cells, std::string& why)> accept;
};

enum class GenStatus { Running, Done, Failed };

struct GenStats {
    int attempts = 0;                            // attempts started (the successful one included)
    int contradictions = 0;                      // attempts that ended in a cell with no pattern left
    int rejected = 0;                            // finished grids `accept` refused
    std::int64_t observations = 0;               // cells collapsed by choice
    std::int64_t propagations = 0;               // patterns removed from cells
    int patterns = 0;                            // patterns of the model
    int cells = 0;                               // cells of the solver (the pattern grid: smaller than the output for a non-periodic overlapping model)
    std::int64_t work = 0;                       // units of work done (see Generator::step): deterministic, unlike `ms`
    int pinned = 0;                              // cells pinned to a tile a minimum count was missing (see CountRule)
    double ms = 0.0;                             // wall time spent in step(): it differs between runs and machines and is NOT part of the determinism promise
    std::size_t memoryBytes = 0;                 // estimate_generator_memory(): the solver state and the model, an upper bound
    int heapRebuilds = 0;                        // times the entropy heap was rebuilt without its stale entries
    std::size_t heapPeak = 0;                    // most entries the entropy heap held (at most 4 per cell)
    std::size_t peakBytes = 0;                   // what the solver's vectors held at their largest (<= memoryBytes)
    std::uint64_t seedUsed = 0;                  // the derived seed of the attempt that is running or succeeded
    std::vector<int> symbolCounts;               // after Done: how many output cells hold each symbol
};

// Where and why the last failed attempt stopped.
struct GenFailure {
    int attempt = 0;                             // 1-based
    int x = -1;                                  // output cell where the contradiction appeared (-1: the grid was refused)
    int y = -1;
    std::string reason;                          // "contradiction", the count that was missed, or what `accept` said
    int countRule = -1;                          // index into GenerateOptions::counts when a count was missed
};

// An upper bound of the bytes the model's tables and the solver state take for this model and size.
std::size_t estimate_generator_memory(const PatternModel& model, int width, int height, bool periodic);

// The seed of attempt `attempt` (0-based): the same on every platform.
std::uint64_t derive_attempt_seed(std::uint64_t seed, int attempt);

class Generator {
public:
    ~Generator();
    Generator(const Generator&) = delete;
    Generator& operator=(const Generator&) = delete;

    // Checks the options (size, periodic size against n, cell rules inside the grid with symbols the model has, constraints that
    // contradict each other or the model, weights, memory budget) and prepares the first attempt. The model is kept alive by the generator.
    static Result<std::unique_ptr<Generator>> create(std::shared_ptr<const PatternModel> model, GenerateOptions options);

    // Does at most `workBudget` units of work (a unit is one pattern removed from a cell or one cell observed; starting an
    // attempt counts one unit per cell and one per cell rule and offset) and returns where it stands. The budget may be overshot by one propagation front.
    GenStatus step(std::int64_t workBudget);
    // step() until Done or Failed.
    GenStatus run();

    GenStatus status() const;
    // Cells already decided (one pattern left) over cells: 0..1, for a progress bar.
    double progress() const;
    // After Done: width * height symbol ids (row-major, row 0 = top).
    const std::vector<int>& output() const;
    const GenStats& stats() const;
    // After Failed (and after a Done that needed retries): the last failed attempt.
    const GenFailure& failure() const;
    // The message of a Failed generator: where the last attempt failed and how many attempts were made.
    std::string failure_message() const;
    // What to try about it (a bigger sample, a smaller n, periodic, fewer constraints), for the Error hint.
    std::string failure_hint() const;

    int width() const;
    int height() const;

private:
    struct Impl;
    explicit Generator(std::unique_ptr<Impl> impl);
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa::wfc
