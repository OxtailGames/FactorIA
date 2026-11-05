// Wave Function Collapse: model builders and the steppable solver. See fa/scene/wfc.h for the design and the determinism rules.
#include "fa/scene/wfc.h"

#include <algorithm>
#include <bit>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <iterator>
#include <limits>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <tuple>
#include <vector>

#include "fa/core/math.h"

namespace fa::wfc {

namespace {

// ------------------------------------------------------------------------------------------------ integer logarithm
// log2(x) in Q20 fixed point (x >= 1), from integer shifts and squarings only, so every platform gets the same value.
std::int64_t log2_q20(std::uint64_t x) {
    if (x <= 1) return 0;
    int ip = 0;
    for (std::uint64_t t = x; t > 1; t >>= 1) ++ip;
    std::uint64_t m = ip <= 30 ? (x << (30 - ip)) : (x >> (ip - 30));  // mantissa in [2^30, 2^31)
    std::int64_t frac = 0;
    for (int i = 0; i < 20; ++i) {
        m = (m * m) >> 30;
        if (m >= (std::uint64_t(1) << 31)) {
            frac |= std::int64_t(1) << (19 - i);
            m >>= 1;
        }
    }
    return (std::int64_t(ip) << 20) | frac;
}

std::string mb(std::uint64_t bytes) {
    const double v = double(bytes) / (1024.0 * 1024.0);
    char buf[32];
    std::snprintf(buf, sizeof buf, "%.0f", v < 1.0 ? 1.0 : v);
    return std::string(buf) + " MB";
}

Error compat_table_error(std::size_t patterns, const char* who) {
    return Error{std::string(who) + " has " + std::to_string(patterns) + " patterns and their adjacency table would hold more than " + std::to_string(kMaxCompatEntries) + " entries",
                 "Use a smaller or less uniform sample, a bigger n (patterns constrain each other more), or symmetry 1; for the tiled model, fewer tiles per terrain."};
}

// ------------------------------------------------------------------------------------------------ pattern transforms
using Pat = std::vector<int>;

Pat reflect(const Pat& p, int n) {
    Pat r(p.size());
    for (int y = 0; y < n; ++y)
        for (int x = 0; x < n; ++x) r[std::size_t(y * n + x)] = p[std::size_t(y * n + (n - 1 - x))];
    return r;
}

Pat rotate(const Pat& p, int n) {
    Pat r(p.size());
    for (int y = 0; y < n; ++y)
        for (int x = 0; x < n; ++x) r[std::size_t(y * n + x)] = p[std::size_t((n - 1 - x) * n + y)];
    return r;
}

std::vector<Pat> variants(const Pat& p, int n, int symmetry) {
    std::vector<Pat> out;
    if (symmetry == 1) {
        out.push_back(p);
    } else if (symmetry == 2) {
        out.push_back(p);
        out.push_back(reflect(p, n));
    } else {
        Pat r = p;
        for (int i = 0; i < 4; ++i) {
            out.push_back(r);
            if (symmetry == 8) out.push_back(reflect(r, n));
            r = rotate(r, n);
        }
    }
    return out;
}

}  // namespace

// ================================================================================================================ models

Result<std::shared_ptr<PatternModel>> build_overlapping_model(const Sample& sample, const OverlapOptions& options) {
    const int n = options.n;
    if (n < kMinPatternSize || n > kMaxPatternSize)
        return make_error("The pattern size n is " + std::to_string(n) + " but it must be between " + std::to_string(kMinPatternSize) + " and " +
                              std::to_string(kMaxPatternSize),
                          "n = 3 is the usual choice: a bigger n copies larger pieces of the sample (more faithful, less varied), a smaller n mixes more freely.");
    if (options.symmetry != 1 && options.symmetry != 2 && options.symmetry != 4 && options.symmetry != 8)
        return make_error("symmetry is " + std::to_string(options.symmetry) + " but it must be 1, 2, 4 or 8",
                          "1 = the sample as it is, 2 = also mirrored left-right, 4 = also turned by 90, 180 and 270 degrees, 8 = turned and mirrored.");
    if (sample.width <= 0 || sample.height <= 0 || sample.cells.empty() || sample.symbolCount <= 0)
        return make_error("The sample is empty: it has no cells to learn patterns from",
                          "Give a sample with at least a few rows and columns: a Tilemap entity or ASCII rows.");
    if (sample.cells.size() != std::size_t(sample.width) * std::size_t(sample.height))
        return make_error("The sample's cell list does not match its size " + std::to_string(sample.width) + " x " + std::to_string(sample.height));
    if (sample.cells.size() > kMaxSampleCells)
        return make_error("The sample has " + std::to_string(sample.cells.size()) + " cells, more than the limit of " + std::to_string(kMaxSampleCells),
                          "Use a smaller sample: a 16 x 16 to 64 x 64 piece shows the same patterns.");
    if (!options.periodicInput && (sample.width < n || sample.height < n))
        return make_error("The sample is " + std::to_string(sample.width) + " x " + std::to_string(sample.height) + " cells, smaller than n = " +
                              std::to_string(n) + ": it has no " + std::to_string(n) + " x " + std::to_string(n) + " window to learn",
                          "Use a bigger sample, a smaller n (n = " + std::to_string(std::max(kMinPatternSize, std::min(sample.width, sample.height))) +
                              " fits), or periodicInput true so the sample wraps around its edges.");
    for (int v : sample.cells)
        if (v < 0 || v >= sample.symbolCount) return make_error("The sample holds symbol " + std::to_string(v) + " outside 0.." + std::to_string(sample.symbolCount - 1));

    auto model = std::make_shared<PatternModel>();
    model->n = n;
    model->symbolCount = sample.symbolCount;
    model->sampleCells = sample.cells.size();
    const std::size_t nn = std::size_t(n) * std::size_t(n);

    // 1. The patterns, numbered in the order they are first met (rows top to bottom, windows left to right, variants in a fixed order).
    std::map<Pat, std::size_t> patternIndex;
    std::vector<Pat> patterns;
    std::vector<std::uint32_t>& weights = model->weights;
    const int xEnd = options.periodicInput ? sample.width : sample.width - n + 1;
    const int yEnd = options.periodicInput ? sample.height : sample.height - n + 1;
    Pat window(nn);
    for (int y = 0; y < yEnd; ++y)
        for (int x = 0; x < xEnd; ++x) {
            for (int dy = 0; dy < n; ++dy)
                for (int dx = 0; dx < n; ++dx)
                    window[std::size_t(dy * n + dx)] = sample.cells[std::size_t((y + dy) % sample.height) * std::size_t(sample.width) + std::size_t((x + dx) % sample.width)];
            for (Pat& v : variants(window, n, options.symmetry)) {
                auto it = patternIndex.find(v);
                if (it == patternIndex.end()) {
                    if (patterns.size() >= kMaxPatterns)
                        return make_error("The sample has more than " + std::to_string(kMaxPatterns) + " distinct " + std::to_string(n) + " x " + std::to_string(n) +
                                              " patterns, more than the generator handles",
                                          "Use a smaller or more regular sample, a smaller n, or a lower symmetry (symmetry 1 keeps only the patterns the sample shows).");
                    it = patternIndex.emplace(v, patterns.size()).first;
                    patterns.push_back(v);
                    weights.push_back(0);
                }
                ++weights[it->second];
            }
        }
    const std::size_t count = patterns.size();
    std::uint64_t totalWeight = 0;
    for (std::uint32_t w : weights) totalWeight += w;
    if (totalWeight > kMaxTotalWeight)
        return make_error("The pattern counts add up to " + std::to_string(totalWeight) + ", more than the " + std::to_string(kMaxTotalWeight) + " the weighted choice can draw from",
                          "Use a smaller sample or a lower symmetry.");
    model->symbols.reserve(count * nn);
    for (const Pat& p : patterns) model->symbols.insert(model->symbols.end(), p.begin(), p.end());

    // 2. Adjacency: pattern q may stand east of p when p's columns 1..n-1 equal q's columns 0..n-2 (and the same for the other three
    //    directions). Group the patterns by the strip they show to each side and look the matching strip up.
    // strip(p, side): the cells of the overlap, side 0 = first n-1 columns, 1 = last n-1 columns, 2 = first n-1 rows, 3 = last n-1 rows.
    auto strip = [&](const Pat& p, int side) {
        Pat s;
        s.reserve(std::size_t(n - 1) * std::size_t(n));
        for (int y = 0; y < n; ++y)
            for (int x = 0; x < n; ++x) {
                const bool keep = side == 0 ? x < n - 1 : side == 1 ? x > 0 : side == 2 ? y < n - 1 : y > 0;
                if (keep) s.push_back(p[std::size_t(y * n + x)]);
            }
        return s;
    };
    // direction d needs: p's strip facing d (E: last columns = side 1; S: last rows = side 3; W: first columns = side 0; N: first rows = side 2)
    // equal to q's strip facing back (E: first columns = side 0; S: side 2; W: side 1; N: side 3).
    static constexpr int kFacing[kDirs] = {1, 3, 0, 2};
    static constexpr int kBack[kDirs] = {0, 2, 1, 3};
    std::size_t entries = 0;
    for (int d = 0; d < kDirs; ++d) {
        std::map<Pat, std::vector<std::uint16_t>> byStrip;
        for (std::size_t q = 0; q < count; ++q) byStrip[strip(patterns[q], kBack[d])].push_back(std::uint16_t(q));
        model->compat[d].resize(count);
        std::vector<const std::vector<std::uint16_t>*> match(count, nullptr);
        for (std::size_t p = 0; p < count; ++p) {
            auto it = byStrip.find(strip(patterns[p], kFacing[d]));
            if (it != byStrip.end()) {
                match[p] = &it->second;
                entries += it->second.size();
            }
        }
        if (entries > kMaxCompatEntries) return compat_table_error(count, "The sample");
        for (std::size_t p = 0; p < count; ++p)
            if (match[p]) model->compat[d][p] = *match[p];
    }
    model->edgeOk.assign(count * kDirs, 1);
    return model;
}

Result<TerrainModel> build_terrain_model(const std::vector<Terrain>& terrains, const std::vector<std::pair<int, std::uint32_t>>& tileWeights) {
    if (terrains.empty())
        return make_error("There are no terrain rules to build the tiled model from",
                          "Give the Tilemap autotile rules (tilemap.set_terrains, or image.tileset.build writes them), or use model \"overlapping\", which needs only a sample.");
    struct P {
        int value;
        int terrain;
        int mask;
    };
    std::vector<P> pats;
    pats.push_back({-1, -1, 0});
    for (std::size_t t = 0; t < terrains.size(); ++t) {
        const auto& masks = autotile_masks(terrains[t].mode);
        for (std::size_t s = 0; s < terrains[t].slots.size(); ++s)
            for (int v : terrains[t].slots[s]) pats.push_back({v, int(t), masks[s]});
    }
    if (pats.size() > kMaxPatterns) return make_error("The terrain rules have " + std::to_string(pats.size()) + " tiles, more than " + std::to_string(kMaxPatterns));

    TerrainModel out;
    out.model = std::make_shared<PatternModel>();
    PatternModel& m = *out.model;
    m.n = 1;
    std::map<int, int> symbolOf;
    for (const P& p : pats) {
        if (symbolOf.emplace(p.value, int(out.tileValues.size())).second) out.tileValues.push_back(p.value);
    }
    m.symbolCount = int(out.tileValues.size());
    std::map<int, std::uint32_t> weightOf;
    for (const auto& tw : tileWeights) weightOf[tw.first] = tw.second;

    std::map<std::string, int> byName;
    for (std::size_t i = 0; i < terrains.size(); ++i) byName[terrains[i].name] = int(i);
    std::vector<std::vector<bool>> joined(terrains.size(), std::vector<bool>(terrains.size(), false));
    for (std::size_t i = 0; i < terrains.size(); ++i) {
        joined[i][i] = true;
        for (const std::string& j : terrains[i].joins) {
            auto it = byName.find(j);
            if (it != byName.end()) joined[i][std::size_t(it->second)] = true;
        }
    }
    auto counts = [&](int a, int b) { return a >= 0 && b >= 0 && joined[std::size_t(a)][std::size_t(b)]; };
    static constexpr int kBit[kDirs] = {kAutoE, kAutoS, kAutoW, kAutoN};
    auto bit = [&](const P& p, int d) { return (p.mask & kBit[d]) != 0; };

    const std::size_t count = pats.size();
    std::uint64_t totalWeight = 0;
    for (const P& p : pats) {
        auto it = weightOf.find(p.value);
        const std::uint32_t w = it == weightOf.end() ? 1u : std::max<std::uint32_t>(1u, it->second);
        m.weights.push_back(w);
        totalWeight += w;
        m.symbols.push_back(symbolOf[p.value]);
        out.patternTerrain.push_back(p.terrain < 0 ? std::string() : terrains[std::size_t(p.terrain)].name);
    }
    if (totalWeight > kMaxTotalWeight)
        return make_error("The tile weights add up to " + std::to_string(totalWeight) + " over the " + std::to_string(count) + " patterns, more than the " +
                              std::to_string(kMaxTotalWeight) + " the weighted choice can draw from",
                          "Use smaller weights.");
    std::size_t entries = 0;
    for (int d = 0; d < kDirs; ++d) {
        m.compat[d].resize(count);
        for (std::size_t p = 0; p < count; ++p) {
            for (std::size_t q = 0; q < count; ++q)
                if (bit(pats[p], d) == counts(pats[p].terrain, pats[q].terrain) && bit(pats[q], d ^ 2) == counts(pats[q].terrain, pats[p].terrain))
                    m.compat[d][p].push_back(std::uint16_t(q));
            entries += m.compat[d][p].size();
            if (entries > kMaxCompatEntries) return compat_table_error(count, "The terrain rules");
        }
    }
    m.edgeOk.assign(count * kDirs, 1);
    for (std::size_t p = 0; p < count; ++p)
        for (int d = 0; d < kDirs; ++d) {
            const bool outside = pats[p].terrain >= 0 && terrains[std::size_t(pats[p].terrain)].outsideIsTerrain;
            m.edgeOk[p * kDirs + std::size_t(d)] = bit(pats[p], d) == outside ? 1 : 0;
        }
    return out;
}

// ================================================================================================================ solver

std::uint64_t derive_attempt_seed(std::uint64_t seed, int attempt) {
    std::uint64_t z = seed + 0x9E3779B97F4A7C15ull * (std::uint64_t(attempt) + 1);
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
    return z ^ (z >> 31);
}

namespace {

int wave_side(int output, int n, bool periodic) { return periodic ? output : output - n + 1; }

}  // namespace


namespace {

constexpr std::uint64_t kHeapEntryBytes = 24;      // sizeof(Impl::HeapEntry), checked by a static_assert below
constexpr std::uint64_t kHeapEntriesPerCell = 4;   // the heap is rebuilt before it grows past this many entries per cell

std::uint64_t sat_add(std::uint64_t a, std::uint64_t b) { return a > UINT64_MAX - b ? UINT64_MAX : a + b; }
std::uint64_t sat_mul(std::uint64_t a, std::uint64_t b) { return (a == 0 || b == 0) ? 0 : (a > UINT64_MAX / b ? UINT64_MAX : a * b); }

std::uint64_t model_bytes(const PatternModel& model) {
    std::uint64_t entries = 0;
    for (int d = 0; d < kDirs; ++d)
        for (const auto& v : model.compat[d]) entries += v.size();
    const std::uint64_t T = model.pattern_count();
    return entries * sizeof(std::uint16_t) + T * kDirs * sizeof(std::vector<std::uint16_t>) + std::uint64_t(model.symbols.size()) * sizeof(int) + T * sizeof(std::uint32_t) +
           model.edgeOk.size();
}

std::string rule_name(const std::vector<CellRule>& rules, std::size_t r) {
    return "Cell rule " + std::to_string(r) + (rules[r].label.empty() ? std::string() : " (" + rules[r].label + ")");
}

// The distance (in cells) from `pos` to the window [start, start + n - 1] along one axis, around the edge when periodic.
int axis_distance(int pos, int start, int n, int size, bool periodic) {
    auto plain = [&](int p) { return p < start ? start - p : (p > start + n - 1 ? p - (start + n - 1) : 0); };
    int d = plain(pos);
    if (periodic) d = std::min({d, plain(pos + size), plain(pos - size)});
    return d;
}

}  // namespace

std::uint64_t estimate_generator_memory(const PatternModel& model, int width, int height, bool periodic) {
    const std::uint64_t cells = sat_mul(std::uint64_t(std::max(1, wave_side(width, model.n, periodic))), std::uint64_t(std::max(1, wave_side(height, model.n, periodic))));
    const std::uint64_t T = model.pattern_count();
    const std::uint64_t words = (T + 63) / 64;
    // Per cell: the wave bits and the bits of the removals still to propagate, four u16 support counters per pattern, remaining, the two
    // sums, noise, stamp, two flags, a dirty entry, a queue entry and up to kHeapEntriesPerCell heap entries. Every one of these has a fixed
    // size (a pattern leaves a cell once; a cell is queued once), so this is a true bound. Then the model and the output.
    const std::uint64_t perCell = sat_add(sat_add(sat_mul(words, 16), sat_mul(T, kDirs * 2)), 4 + 8 + 8 + 4 + 4 + 1 + 1 + 4 + 4 + kHeapEntriesPerCell * kHeapEntryBytes);
    std::uint64_t total = sat_mul(cells, perCell);
    total = sat_add(total, sat_mul(T, 16));
    total = sat_add(total, model_bytes(model));
    total = sat_add(total, sat_mul(sat_mul(std::uint64_t(std::max(width, 0)), std::uint64_t(std::max(height, 0))), 8));
    total = sat_add(total, sat_mul(cells, 4));
    return total;
}

Result<std::uint64_t> check_generator_memory(const PatternModel& model, int width, int height, bool periodic, std::uint64_t extraBytes) {
    const std::uint64_t need = sat_add(estimate_generator_memory(model, width, height, periodic), extraBytes);
    if (need <= kWfcMemoryBudget) return need;
    const std::uint64_t outCells = std::max<std::uint64_t>(1, sat_mul(std::uint64_t(std::max(width, 1)), std::uint64_t(std::max(height, 1))));
    const std::uint64_t perCell = std::max<std::uint64_t>(1, need / outCells);
    const std::uint64_t maxCells = kWfcMemoryBudget / perCell;
    std::uint64_t side = 1;
    while ((side + 1) * (side + 1) <= maxCells) ++side;
    return make_error("Generating " + std::to_string(width) + " x " + std::to_string(height) + " cells from a model with " + std::to_string(model.pattern_count()) +
                          " patterns needs about " + mb(need) + " of memory, above the limit of " + mb(kWfcMemoryBudget),
                      "Ask for a smaller size (about " + std::to_string(side) + " x " + std::to_string(side) + " fits this model), or reduce the patterns: a smaller n, symmetry 1, or a simpler sample.");
}

struct Generator::Impl {
    std::shared_ptr<const PatternModel> model;
    GenerateOptions opt;

    std::size_t T = 0;       // patterns
    std::size_t words = 0;   // 64-bit words per cell of the wave
    int wc = 0, hc = 0;      // wave size in cells
    std::size_t cells = 0;
    std::vector<std::int64_t> logw;                    // per pattern, Q20 log2 of its weight
    std::vector<std::uint16_t> supportInit;            // T * 4: the support counters of a fresh cell
    std::vector<std::uint32_t> special;                // patterns that cannot stand in the middle of the map or at an edge in some direction
    std::vector<std::vector<char>> ruleMask;           // per cell rule: allowed symbol flags
    std::vector<std::uint32_t> forbiddenPatterns;      // patterns that hold a forbidden symbol somewhere
    std::vector<std::vector<char>> countMask;          // per count rule: symbol flags
    std::vector<char> ruleCell;                        // per output cell: a cell rule covers it
    std::vector<int> pendingPins;                      // per count rule: cells to pin in the next attempt (a minimum was missed)
    std::vector<char> pinTaken;                        // per output cell: pinned in this attempt

    // state of the attempt
    std::vector<std::uint64_t> wave;
    std::vector<std::uint16_t> support;
    std::vector<std::uint32_t> remaining;
    std::vector<std::uint64_t> sumW;
    std::vector<std::int64_t> sumWL;
    std::vector<std::uint32_t> noise;
    std::vector<std::uint32_t> stamp;
    std::vector<char> dirtyFlag;
    std::vector<std::uint32_t> dirty;
    // Removals not yet propagated: a bit per (cell, pattern) and a stack of the cells that have some (each cell once, flagged in
    // `queued`). The wave's fixed point does not depend on the order the removals are propagated in.
    std::vector<std::uint64_t> pending;
    std::vector<std::uint32_t> queue;
    std::vector<char> queued;
    struct HeapEntry {
        std::int64_t key;
        std::uint32_t noise;
        std::uint32_t cell;
        std::uint32_t stamp;
    };
    static_assert(sizeof(HeapEntry) == kHeapEntryBytes, "estimate_generator_memory assumes the size of HeapEntry");
    std::vector<HeapEntry> heap;
    static bool heap_after(const HeapEntry& a, const HeapEntry& b) {  // "a comes after b": a min-heap on (key, noise, cell)
        if (a.key != b.key) return a.key > b.key;
        if (a.noise != b.noise) return a.noise > b.noise;
        return a.cell > b.cell;
    }
    Rng rng;
    std::size_t undecided = 0;
    bool contradiction = false;
    std::uint32_t contradictionCell = 0;
    bool attemptRunning = false;
    int attempt = 0;  // attempts started

    GenStatus status = GenStatus::Running;
    std::vector<int> output;
    GenStats stats;
    GenFailure failure;
    int failedAttempts = 0;
    std::int64_t stepWork = 0;   // work charged in the current step() call

    // ------------------------------------------------------------------------------------------------------------
    bool present(std::size_t cell, std::size_t p) const { return (wave[cell * words + (p >> 6)] >> (p & 63)) & 1u; }

    void charge(std::int64_t units) {
        stats.work += units;
        stepWork += units;
    }
    bool over_cap() const { return opt.maxWork > 0 && stats.work > opt.maxWork; }

    void touch(std::size_t cell) {
        if (!dirtyFlag[cell]) {
            dirtyFlag[cell] = 1;
            dirty.push_back(std::uint32_t(cell));
        }
    }

    void ban(std::size_t cell, std::size_t p) {
        std::uint64_t& w = wave[cell * words + (p >> 6)];
        const std::uint64_t bitMask = std::uint64_t(1) << (p & 63);
        if (!(w & bitMask)) return;
        w &= ~bitMask;
        const std::uint32_t before = remaining[cell]--;
        sumW[cell] -= model->weights[p];
        sumWL[cell] -= std::int64_t(model->weights[p]) * logw[p];
        pending[cell * words + (p >> 6)] |= bitMask;
        if (!queued[cell]) {
            queued[cell] = 1;
            queue.push_back(std::uint32_t(cell));
        }
        touch(cell);
        if (before == 2) --undecided;
        if (before == 1 && !contradiction) {
            contradiction = true;
            contradictionCell = std::uint32_t(cell);
        }
    }

    bool neighbour(std::size_t cell, int d, std::size_t& nb) const {
        int x = int(cell % std::size_t(wc)) + kDx[d], y = int(cell / std::size_t(wc)) + kDy[d];
        if (opt.periodic) {
            x = (x + wc) % wc;
            y = (y + hc) % hc;
        } else if (x < 0 || y < 0 || x >= wc || y >= hc) {
            return false;
        }
        nb = std::size_t(y) * std::size_t(wc) + std::size_t(x);
        return true;
    }

    // The wave cells that cover output cell (x, y) lose every pattern that puts a symbol outside `okSymbol` there.
    void restrict_output_cell(int x, int y, const std::vector<char>& okSymbol) {
        const int n = model->n;
        for (int oy = 0; oy < n; ++oy)
            for (int ox = 0; ox < n; ++ox) {
                int cx = x - ox, cy = y - oy;
                if (opt.periodic) {
                    cx = ((cx % wc) + wc) % wc;
                    cy = ((cy % hc) + hc) % hc;
                } else if (cx < 0 || cy < 0 || cx >= wc || cy >= hc) {
                    continue;
                }
                const std::size_t cell = std::size_t(cy) * std::size_t(wc) + std::size_t(cx);
                for (std::size_t p = 0; p < T; ++p)
                    if (present(cell, p) && !okSymbol[std::size_t(model->symbol_at(p, ox, oy))]) ban(cell, p);
            }
    }

    // Starts an attempt and charges its work. It stops early once the work cap is passed (the attempt is then never run).
    void begin_attempt() {
        ++attempt;
        ++stats.attempts;
        attemptRunning = true;
        contradiction = false;
        stats.seedUsed = derive_attempt_seed(opt.seed, attempt - 1);
        rng.reseed(stats.seedUsed);
        const std::size_t patternBits = T;
        std::fill(wave.begin(), wave.end(), ~std::uint64_t(0));
        if (patternBits % 64 != 0)
            for (std::size_t c = 0; c < cells; ++c) wave[c * words + words - 1] = (std::uint64_t(1) << (patternBits % 64)) - 1;
        std::uint64_t totalW = 0;
        std::int64_t totalWL = 0;
        for (std::size_t p = 0; p < T; ++p) {
            totalW += model->weights[p];
            totalWL += std::int64_t(model->weights[p]) * logw[p];
        }
        std::fill(remaining.begin(), remaining.end(), std::uint32_t(T));
        std::fill(sumW.begin(), sumW.end(), totalW);
        std::fill(sumWL.begin(), sumWL.end(), totalWL);
        for (std::size_t c = 0; c < cells; ++c) std::copy(supportInit.begin(), supportInit.end(), support.begin() + std::ptrdiff_t(c * T * kDirs));
        for (std::size_t c = 0; c < cells; ++c) noise[c] = rng.next_u32();
        std::fill(stamp.begin(), stamp.end(), 0u);
        std::fill(dirtyFlag.begin(), dirtyFlag.end(), char(0));
        std::fill(pending.begin(), pending.end(), std::uint64_t(0));
        std::fill(queued.begin(), queued.end(), char(0));
        dirty.clear();
        heap.clear();
        queue.clear();
        undecided = T > 1 ? cells : 0;
        for (std::size_t c = 0; c < cells; ++c) touch(c);
        charge(std::int64_t(cells) + std::int64_t(cells) * std::int64_t(T) / 16);   // resetting the state of every cell

        // Patterns that cannot stand where the map has a neighbour (no pattern may follow them) or where it has none (the edge rules).
        charge(std::int64_t(cells) * std::int64_t(special.size()));
        if (over_cap()) return;
        for (std::size_t c = 0; c < cells && !contradiction; ++c)
            for (std::uint32_t p : special) {
                for (int d = 0; d < kDirs; ++d) {
                    std::size_t nb = 0;
                    if (neighbour(c, d, nb) ? model->compat[d][p].empty() : !model->edgeOk[std::size_t(p) * kDirs + std::size_t(d)]) {
                        ban(c, p);
                        break;
                    }
                }
            }
        // Forbidden symbols: the patterns that hold one anywhere are out of every cell.
        charge(std::int64_t(cells) * std::int64_t(forbiddenPatterns.size()));
        if (over_cap()) return;
        for (std::size_t c = 0; c < cells && !contradiction; ++c)
            for (std::uint32_t p : forbiddenPatterns) ban(c, p);
        // Cell rules: every wave cell that covers the output cell loses the patterns that put another symbol there.
        const std::int64_t perRule = std::int64_t(model->n) * model->n * std::int64_t(T);
        for (std::size_t r = 0; r < opt.cellRules.size() && !contradiction; ++r) {
            charge(perRule);
            if (over_cap()) return;
            restrict_output_cell(opt.cellRules[r].x, opt.cellRules[r].y, ruleMask[r]);
        }
        // A minimum the last finished grid missed: pin the missing cells at positions drawn from this attempt's seed.
        const std::size_t outCells = std::size_t(opt.width) * std::size_t(opt.height);
        bool anyPin = false;
        for (int need : pendingPins) anyPin = anyPin || need > 0;
        if (anyPin && !contradiction) {
            Rng pinRng(derive_attempt_seed(stats.seedUsed, 0x7F31));
            pinTaken.assign(outCells, 0);
            for (std::size_t r = 0; r < pendingPins.size() && !contradiction; ++r) {
                int placed = 0;
                for (int tries = 0; placed < pendingPins[r] && tries < pendingPins[r] * 16 + 64 && !contradiction; ++tries) {
                    const std::size_t at = std::size_t(pinRng.next_u32()) % outCells;
                    if (ruleCell[at] || pinTaken[at]) continue;
                    charge(perRule);
                    if (over_cap()) return;
                    pinTaken[at] = 1;
                    restrict_output_cell(int(at % std::size_t(opt.width)), int(at / std::size_t(opt.width)), countMask[r]);
                    ++placed;
                    ++stats.pinned;
                }
            }
        }
    }

    // Propagates the removals pending in the cell on top of the queue; returns the work it took.
    std::int64_t propagate_cell() {
        const std::size_t cell = queue.back();
        queue.pop_back();
        queued[cell] = 0;
        std::int64_t units = 0;
        for (std::size_t wi = 0; wi < words && !contradiction; ++wi) {
            std::uint64_t bits = pending[cell * words + wi];
            if (!bits) continue;
            pending[cell * words + wi] = 0;
            while (bits && !contradiction) {
                const std::size_t p = wi * 64 + std::size_t(std::countr_zero(bits));
                bits &= bits - 1;
                units += propagate_pattern(cell, p);
            }
        }
        return std::max<std::int64_t>(units, 1);
    }

    // Removes the support of one banned pattern from its neighbours. Returns the work: one unit for the pattern and one for every
    // neighbouring pattern whose support counter it looks at (the real cost: it grows with the model's adjacency lists).
    std::int64_t propagate_pattern(std::size_t cell, std::size_t pattern) {
        ++stats.propagations;
        std::int64_t units = 1;
        for (int d = 0; d < kDirs; ++d) {
            std::size_t nb = 0;
            if (!neighbour(cell, d, nb)) continue;
            const std::size_t back = std::size_t(d ^ 2);
            units += std::int64_t(model->compat[d][pattern].size());
            for (std::uint16_t q : model->compat[d][pattern]) {
                if (!present(nb, q)) continue;
                std::uint16_t& c = support[(nb * T + q) * kDirs + back];
                if (c > 0 && --c == 0) ban(nb, q);
            }
            if (contradiction) break;
        }
        return units;
    }

    void flush_dirty() {
        for (std::uint32_t c : dirty) {
            dirtyFlag[c] = 0;
            ++stamp[c];
        }
        // Stale entries pile up (every change of a cell leaves its old entry behind): when the heap could pass its allowance, keep
        // only the entry each undecided cell still has valid. The order of a heap of distinct (key, noise, cell) triples does not
        // depend on how it was built, so this changes no result.
        if (heap.size() + dirty.size() > kHeapEntriesPerCell * cells) {
            std::size_t kept = 0;
            for (const HeapEntry& e : heap)
                if (e.stamp == stamp[e.cell] && remaining[e.cell] > 1) heap[kept++] = e;
            heap.resize(kept);
            std::make_heap(heap.begin(), heap.end(), heap_after);
            ++stats.heapRebuilds;
        }
        for (std::uint32_t c : dirty) {
            if (remaining[c] > 1) {
                const std::int64_t entropy = log2_q20(sumW[c]) - sumWL[c] / std::int64_t(sumW[c]);
                heap.push_back({entropy, noise[c], c, stamp[c]});
                std::push_heap(heap.begin(), heap.end(), heap_after);
            }
        }
        dirty.clear();
        stats.heapPeak = std::max(stats.heapPeak, heap.size());
    }

    // The cell with the lowest entropy that is still undecided; false when every cell holds one pattern.
    bool pick_cell(std::size_t& cell) {
        while (!heap.empty()) {
            std::pop_heap(heap.begin(), heap.end(), heap_after);
            const HeapEntry e = heap.back();
            heap.pop_back();
            if (e.stamp != stamp[e.cell] || remaining[e.cell] <= 1) continue;
            cell = e.cell;
            return true;
        }
        return false;
    }

    void observe(std::size_t cell) {
        ++stats.observations;
        std::uint64_t r = (std::uint64_t(rng.next_u32()) * sumW[cell]) >> 32;
        std::size_t chosen = T;
        for (std::size_t wi = 0; wi < words && chosen == T; ++wi) {
            std::uint64_t bits = wave[cell * words + wi];
            while (bits) {
                const std::size_t p = wi * 64 + std::size_t(std::countr_zero(bits));
                bits &= bits - 1;
                const std::uint64_t w = model->weights[p];
                if (r < w) {
                    chosen = p;
                    break;
                }
                r -= w;
            }
        }
        if (chosen == T) {  // unreachable: r < sumW. Fall back to the first pattern left.
            for (std::size_t p = 0; p < T; ++p)
                if (present(cell, p)) {
                    chosen = p;
                    break;
                }
        }
        for (std::size_t wi = 0; wi < words; ++wi) {
            std::uint64_t bits = wave[cell * words + wi];
            while (bits) {
                const std::size_t p = wi * 64 + std::size_t(std::countr_zero(bits));
                bits &= bits - 1;
                if (p != chosen) ban(cell, p);
            }
        }
    }

    // The cell rule nearest to the wave cell (cx, cy), when it is within n cells of it; -1 when none is.
    int nearest_cell_rule(int cx, int cy) const {
        const int n = model->n;
        int best = -1, bestD = n + 1;
        for (std::size_t r = 0; r < opt.cellRules.size(); ++r) {
            const CellRule& rule = opt.cellRules[r];
            const int d = std::max(axis_distance(rule.x, cx, n, opt.width, opt.periodic), axis_distance(rule.y, cy, n, opt.height, opt.periodic));
            if (d < bestD) {
                bestD = d;
                best = int(r);
            }
        }
        return best;
    }

    void fail_attempt(int x, int y, const std::string& reason, bool isContradiction, int countRule = -1) {
        attemptRunning = false;
        failure.attempt = attempt;
        failure.x = x;
        failure.y = y;
        failure.reason = reason;
        failure.countRule = countRule;
        failure.cellRule = -1;
        ++failedAttempts;
        if (isContradiction) ++stats.contradictions;
        else ++stats.rejected;
        if (attempt >= opt.maxAttempts) {
            status = GenStatus::Failed;
            if (isContradiction) failure.cellRule = nearest_cell_rule(x, y);
        }
    }

    void fail_work_limit() {
        attemptRunning = false;
        status = GenStatus::Failed;
        failure.attempt = attempt;
        failure.reason = "the work limit was reached";
        failure.workLimit = true;
    }

    void finish_attempt() {
        output.assign(std::size_t(opt.width) * std::size_t(opt.height), 0);
        charge(std::int64_t(output.size() + cells));
        std::vector<std::uint32_t> chosen(cells);
        for (std::size_t c = 0; c < cells; ++c)
            for (std::size_t wi = 0; wi < words; ++wi) {
                const std::uint64_t w = wave[c * words + wi];
                if (w) {
                    chosen[c] = std::uint32_t(wi * 64 + std::size_t(std::countr_zero(w)));
                    break;
                }
            }
        for (int y = 0; y < opt.height; ++y)
            for (int x = 0; x < opt.width; ++x) {
                const int cx = x < wc ? x : wc - 1, cy = y < hc ? y : hc - 1;
                output[std::size_t(y) * std::size_t(opt.width) + std::size_t(x)] =
                    model->symbol_at(chosen[std::size_t(cy) * std::size_t(wc) + std::size_t(cx)], x - cx, y - cy);
            }
        if (!opt.counts.empty()) {
            std::vector<std::int64_t> perSymbol(std::size_t(model->symbolCount), 0);
            for (int sym : output) ++perSymbol[std::size_t(sym)];
            std::string why;
            int firstBad = -1;
            for (std::size_t r = 0; r < opt.counts.size(); ++r) {
                const CountRule& rule = opt.counts[r];
                std::int64_t found = 0;
                for (int sym : rule.symbols) found += perSymbol[std::size_t(sym)];
                const std::string name = count_rule_name(rule);
                if (found < rule.min) {
                    pendingPins[r] = int(std::min<std::int64_t>(rule.min - found, kMaxPins));
                    if (firstBad < 0) {
                        firstBad = int(r);
                        why = "only " + std::to_string(found) + " cell(s) hold " + name + ", at least " + std::to_string(rule.min) + " are required";
                    }
                } else {
                    pendingPins[r] = 0;
                    if (rule.max >= 0 && found > rule.max && firstBad < 0) {
                        firstBad = int(r);
                        why = std::to_string(found) + " cells hold " + name + ", at most " + std::to_string(rule.max) + " are allowed";
                    }
                }
            }
            if (firstBad >= 0) {
                fail_attempt(-1, -1, why, false, firstBad);
                return;
            }
        }
        if (opt.accept) {
            std::string why;
            std::int64_t acceptWork = 0;
            const bool ok = opt.accept(output, why, acceptWork);
            charge(std::max<std::int64_t>(acceptWork, 0));
            if (!ok) {
                fail_attempt(-1, -1, why.empty() ? "the finished level was refused" : why, false);
                return;
            }
        }
        stats.symbolCounts.assign(std::size_t(model->symbolCount), 0);
        for (int s : output) ++stats.symbolCounts[std::size_t(s)];
        std::fill(pendingPins.begin(), pendingPins.end(), 0);
        attemptRunning = false;
        status = GenStatus::Done;
    }

    static constexpr std::int64_t kMaxPins = 1 << 20;

    std::string count_rule_name(const CountRule& rule) const {
        if (!rule.name.empty()) return rule.name;
        std::string out = "symbol";
        for (std::size_t i = 0; i < rule.symbols.size(); ++i) out += (i == 0 ? " " : ", ") + std::to_string(rule.symbols[i]);
        return out;
    }

    std::size_t bytes_held() const {
        return wave.capacity() * sizeof(std::uint64_t) + support.capacity() * sizeof(std::uint16_t) + remaining.capacity() * sizeof(std::uint32_t) +
               sumW.capacity() * sizeof(std::uint64_t) + sumWL.capacity() * sizeof(std::int64_t) + noise.capacity() * sizeof(std::uint32_t) +
               stamp.capacity() * sizeof(std::uint32_t) + dirtyFlag.capacity() + dirty.capacity() * sizeof(std::uint32_t) + pending.capacity() * sizeof(std::uint64_t) +
               queue.capacity() * sizeof(std::uint32_t) + queued.capacity() + heap.capacity() * sizeof(HeapEntry) + output.capacity() * sizeof(int) + pinTaken.capacity() +
               logw.capacity() * sizeof(std::int64_t) + supportInit.capacity() * sizeof(std::uint16_t) + std::size_t(model_bytes(*model));
    }

    GenStatus step(std::int64_t budget) {
        if (status != GenStatus::Running) return status;
        const auto t0 = std::chrono::steady_clock::now();
        stepWork = 0;
        while (status == GenStatus::Running && stepWork < budget) {
            if (over_cap()) {
                fail_work_limit();
                break;
            }
            if (!attemptRunning) {
                begin_attempt();
                continue;
            }
            if (contradiction) {
                fail_attempt(int(contradictionCell % std::uint32_t(wc)), int(contradictionCell / std::uint32_t(wc)), "contradiction", true);
                continue;
            }
            if (!queue.empty()) {
                charge(propagate_cell());
                continue;
            }
            charge(std::int64_t(dirty.size()));   // one heap entry per cell that changed
            flush_dirty();
            std::size_t cell = 0;
            if (!pick_cell(cell)) {
                finish_attempt();
                continue;
            }
            observe(cell);
            charge(std::int64_t(words) + 1);
        }
        stats.peakBytes = std::max(stats.peakBytes, bytes_held());
        stats.ms += std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
        return status;
    }
};

Generator::Generator(std::unique_ptr<Impl> impl) : impl_(std::move(impl)) {}
Generator::~Generator() = default;

namespace {

// The tiles a count rule or a pattern may not hold, and why: the user's `forbidden` list, or a count rule with a maximum of 0.
struct Barred {
    std::vector<char> flag;
    std::vector<int> byRule;   // per symbol: -1 = the forbidden list, else the index of the count rule with max 0
    bool is(int sym) const { return flag[std::size_t(sym)] != 0; }
};

std::string count_name(const std::vector<CountRule>& rules, std::size_t r) {
    return "Count rule " + std::to_string(r) + (rules[r].name.empty() ? std::string() : " (" + rules[r].name + ")");
}

std::string barred_text(const Barred& b, const std::vector<CountRule>& rules, int sym) {
    const int by = b.byRule[std::size_t(sym)];
    return by < 0 ? std::string("it is forbidden") : "it is capped at 0 by " + count_name(rules, std::size_t(by));
}

std::string symbol_text(int sym) { return "symbol " + std::to_string(sym); }

// For every (offset in a pattern, symbol): which edge situations of a wave cell (bit m = the neighbours that exist, one bit per
// direction; periodic output: only 15) some pattern can stand in with that symbol at that offset. `skipBarred` leaves out the patterns that hold a barred symbol.
std::vector<std::uint16_t> placement_table(const PatternModel& model, const Barred& barred, bool skipBarred) {
    const std::size_t n2 = std::size_t(model.n) * std::size_t(model.n);
    const std::size_t symbols = std::size_t(model.symbolCount);
    std::vector<std::uint16_t> table(n2 * symbols, 0);
    for (std::size_t p = 0; p < model.pattern_count(); ++p) {
        if (skipBarred) {
            bool bad = false;
            for (std::size_t k = 0; k < n2 && !bad; ++k) bad = barred.is(model.symbols[p * n2 + k]);
            if (bad) continue;
        }
        std::uint16_t valid = 0;
        for (int mask = 0; mask < 16; ++mask) {
            bool ok = true;
            for (int d = 0; d < kDirs && ok; ++d) ok = (mask >> d) & 1 ? !model.compat[d][p].empty() : model.edgeOk[p * kDirs + std::size_t(d)] != 0;
            if (ok) valid = std::uint16_t(valid | (1u << mask));
        }
        if (!valid) continue;
        for (std::size_t k = 0; k < n2; ++k) table[k * symbols + std::size_t(model.symbols[p * n2 + k])] = std::uint16_t(table[k * symbols + std::size_t(model.symbols[p * n2 + k])] | valid);
    }
    return table;
}

}  // namespace

Result<std::unique_ptr<Generator>> Generator::create(std::shared_ptr<const PatternModel> model, GenerateOptions options) {
    if (!model || model->pattern_count() == 0) return make_error("The model has no patterns to place");
    const int n = model->n;
    if (options.width < 1 || options.height < 1 || options.width > kMaxOutputSide || options.height > kMaxOutputSide)
        return make_error("The output size " + std::to_string(options.width) + " x " + std::to_string(options.height) + " is outside 1.." + std::to_string(kMaxOutputSide) + " cells per side",
                          "Generate a smaller level; for a bigger world generate several chunks.");
    if (options.width < n || options.height < n)
        return make_error("The output size " + std::to_string(options.width) + " x " + std::to_string(options.height) + " is smaller than the pattern size n = " + std::to_string(n),
                          "Make the output at least " + std::to_string(n) + " x " + std::to_string(n) + " cells, or use a smaller n.");
    if (options.maxAttempts < 1 || options.maxAttempts > kMaxAttempts)
        return make_error("maxAttempts is " + std::to_string(options.maxAttempts) + " but it must be between 1 and " + std::to_string(kMaxAttempts),
                          "Each attempt restarts from the next derived seed; 10 is the default and enough unless the sample is very restrictive.");
    if (options.maxWork < 0) return make_error("maxWork is " + std::to_string(options.maxWork) + " but it cannot be negative", "Use 0 for no cap, or the units of work to allow.");
    // The size comes before everything that allocates per cell or per fixed cell.
    auto memory = check_generator_memory(*model, options.width, options.height, options.periodic);
    if (!memory.ok()) return memory.error();
    const std::uint64_t need = *memory;
    if (options.cellRules.size() > kMaxCellRules)
        return make_error(std::to_string(options.cellRules.size()) + " cells are fixed, more than the limit of " + std::to_string(kMaxCellRules),
                          "Fix only what the level needs (an entrance, an exit, a border) and let the sample fill the rest.");
    for (std::size_t r = 0; r < options.cellRules.size(); ++r) {
        const CellRule& rule = options.cellRules[r];
        const std::string who = rule_name(options.cellRules, r);
        if (rule.x < 0 || rule.y < 0 || rule.x >= options.width || rule.y >= options.height)
            return make_error(who + " names the cell (" + std::to_string(rule.x) + ", " + std::to_string(rule.y) + ") outside the " + std::to_string(options.width) + " x " +
                                  std::to_string(options.height) + " output",
                              "Cells count from 0 at the top-left; x is the column, y the row.");
        if (rule.allowed.empty()) return make_error(who + " allows no symbol at all", "List at least one symbol the cell may hold.");
        for (int s : rule.allowed)
            if (s < 0 || s >= model->symbolCount)
                return make_error(who + " allows symbol " + std::to_string(s) + " but the model has symbols 0.." + std::to_string(model->symbolCount - 1));
    }
    // ---- weights, forbidden symbols, count rules: what contradicts itself or the model is refused before anything runs
    const std::size_t symbols = std::size_t(model->symbolCount);
    std::uint64_t totalWeight = 0;
    for (std::uint32_t w : model->weights) {
        if (w == 0) return make_error("The model has a pattern with weight 0", "Every pattern weighs at least 1.");
        totalWeight += w;
    }
    if (totalWeight > kMaxTotalWeight)
        return make_error("The pattern weights add up to " + std::to_string(totalWeight) + ", more than the " + std::to_string(kMaxTotalWeight) + " the weighted choice can draw from",
                          "Use smaller weights or a smaller sample.");
    Barred barred;
    barred.flag.assign(symbols, 0);
    barred.byRule.assign(symbols, -1);
    for (std::size_t i = 0; i < options.forbidden.size(); ++i) {
        const int sym = options.forbidden[i];
        if (sym < 0 || sym >= model->symbolCount)
            return make_error("Forbidden symbol " + std::to_string(sym) + " is not one of the model's symbols 0.." + std::to_string(model->symbolCount - 1));
        barred.flag[std::size_t(sym)] = 1;
    }
    const std::int64_t outputCells = std::int64_t(options.width) * options.height;
    // Count rules, part 1: their own numbers. A tile with a maximum of 0 is forbidden from the start (cheaper than refusing grids).
    for (std::size_t r = 0; r < options.counts.size(); ++r) {
        const CountRule& rule = options.counts[r];
        const std::string who = count_name(options.counts, r);
        if (rule.symbols.empty()) return make_error(who + " names no symbol", "List the symbols that count together.");
        for (int sym : rule.symbols)
            if (sym < 0 || sym >= model->symbolCount) return make_error(who + " names symbol " + std::to_string(sym) + " but the model has symbols 0.." + std::to_string(model->symbolCount - 1));
        if (rule.min < 0) return make_error(who + " has min " + std::to_string(rule.min) + " but a count cannot be negative");
        if (rule.max >= 0 && rule.min > rule.max)
            return make_error(who + " has min " + std::to_string(rule.min) + " greater than max " + std::to_string(rule.max), "Make min at most max.");
        if (rule.min > outputCells)
            return make_error(who + " needs at least " + std::to_string(rule.min) + " cells but the output has only " + std::to_string(outputCells),
                              "Ask for a bigger output or a smaller minimum.");
        if (rule.max == 0)
            for (int sym : rule.symbols)
                if (!barred.flag[std::size_t(sym)]) {
                    barred.flag[std::size_t(sym)] = 1;
                    barred.byRule[std::size_t(sym)] = int(r);
                }
    }
    const std::size_t patternCells = std::size_t(n) * std::size_t(n);
    std::vector<char> patternForbidden(model->pattern_count(), 0);
    std::size_t forbiddenCount = 0;
    for (std::size_t p = 0; p < model->pattern_count(); ++p) {
        for (std::size_t k = 0; k < patternCells && !patternForbidden[p]; ++k)
            if (barred.is(model->symbols[p * patternCells + k])) patternForbidden[p] = 1;
        forbiddenCount += patternForbidden[p] ? 1u : 0u;
    }
    if (forbiddenCount == model->pattern_count())
        return make_error("Every pattern of the model holds a tile that is forbidden or capped at a maximum of 0, so nothing can be placed",
                          "Forbid fewer tiles or drop a `max: 0`: the sample is made of them.");
    // The cell rules of one output cell narrow each other down (sorted symbol lists, not a flag per symbol: a level can fix thousands
    // of cells); a cell with nothing left, or only barred symbols, cannot be filled.
    struct Effective {
        std::vector<int> allowed;
        std::size_t first = 0;   // the first rule that named the cell
        std::size_t last = 0;    // the last one
    };
    std::map<std::size_t, Effective> effective;  // output cell -> symbols every rule on it allows
    for (std::size_t r = 0; r < options.cellRules.size(); ++r) {
        const CellRule& rule = options.cellRules[r];
        const std::size_t at = std::size_t(rule.y) * std::size_t(options.width) + std::size_t(rule.x);
        std::vector<int> own = rule.allowed;
        std::sort(own.begin(), own.end());
        own.erase(std::unique(own.begin(), own.end()), own.end());
        auto it = effective.find(at);
        if (it == effective.end()) {
            it = effective.emplace(at, Effective{own, r, r}).first;
        } else {
            std::vector<int> both;
            std::set_intersection(it->second.allowed.begin(), it->second.allowed.end(), own.begin(), own.end(), std::back_inserter(both));
            it->second.allowed = std::move(both);
            it->second.last = r;
        }
        const std::string who = rule_name(options.cellRules, r);
        if (it->second.allowed.empty())
            return make_error(who + " leaves no symbol for the cell (" + std::to_string(rule.x) + ", " + std::to_string(rule.y) + "): it shares no tile with " +
                                  rule_name(options.cellRules, it->second.first),
                              "Give each cell one fixed tile; a cell named twice must share a tile.");
        int usable = -1;
        for (int sym : it->second.allowed)
            if (!barred.is(sym)) {
                usable = sym;
                break;
            }
        if (usable < 0)
            return make_error(who + " allows only barred tiles for the cell (" + std::to_string(rule.x) + ", " + std::to_string(rule.y) + "): " +
                                  symbol_text(it->second.allowed.front()) + " cannot be placed because " + barred_text(barred, options.counts, it->second.allowed.front()),
                              "Remove the tile from the forbidden list or from the `max: 0` count, or fix the cell to another tile.");
    }
    // A fixed cell must have a place in the model: some pattern (without the barred tiles) that puts one of its tiles there, also at the
    // edge of the map when the cell is near it. The sample may show a tile only in the middle, or only next to a tile that is forbidden.
    if (!effective.empty()) {
        const std::vector<std::uint16_t> table = placement_table(*model, barred, true);
        std::vector<std::uint16_t> tableAll;   // built when a cell fails, to say why
        const int wcCheck = options.periodic ? options.width : options.width - n + 1;
        const int hcCheck = options.periodic ? options.height : options.height - n + 1;
        std::map<std::tuple<std::vector<int>, int, int, int>, bool> memo;   // (allowed, offset, offset, edge situation) -> a pattern exists
        for (const auto& entry : effective) {
            const int x = int(entry.first % std::size_t(options.width)), y = int(entry.first / std::size_t(options.width));
            std::vector<int> usable;
            for (int sym : entry.second.allowed)
                if (!barred.is(sym)) usable.push_back(sym);
            for (int oy = 0; oy < n; ++oy)
                for (int ox = 0; ox < n; ++ox) {
                    int cx = x - ox, cy = y - oy;
                    int mask = 15;
                    if (options.periodic) {
                        cx = ((cx % wcCheck) + wcCheck) % wcCheck;
                        cy = ((cy % hcCheck) + hcCheck) % hcCheck;
                    } else if (cx < 0 || cy < 0 || cx >= wcCheck || cy >= hcCheck) {
                        continue;
                    } else {
                        mask = (cx + 1 < wcCheck ? 1 : 0) | (cy + 1 < hcCheck ? 2 : 0) | (cx > 0 ? 4 : 0) | (cy > 0 ? 8 : 0);
                    }
                    const auto key = std::make_tuple(usable, ox, oy, mask);
                    auto found = memo.find(key);
                    if (found == memo.end()) {
                        bool ok = false;
                        for (int sym : usable)
                            if ((table[std::size_t(oy * n + ox) * symbols + std::size_t(sym)] >> mask) & 1u) {
                                ok = true;
                                break;
                            }
                        found = memo.emplace(key, ok).first;
                    }
                    if (found->second) continue;
                    if (tableAll.empty()) tableAll = placement_table(*model, barred, false);
                    bool withBarred = false;
                    for (int sym : usable)
                        if ((tableAll[std::size_t(oy * n + ox) * symbols + std::size_t(sym)] >> mask) & 1u) withBarred = true;
                    const std::string who = rule_name(options.cellRules, entry.second.last);
                    std::string list;
                    for (std::size_t i = 0; i < usable.size() && i < 4; ++i) list += (i ? ", " : "") + std::to_string(usable[i]);
                    return make_error(who + " fixes the cell (" + std::to_string(x) + ", " + std::to_string(y) + ") to symbol(s) " + list + " but " +
                                          (withBarred ? "every pattern of the model that can put it there also holds a forbidden tile (or one capped at a maximum of 0)"
                                                      : "no pattern of the model can put it there: the sample shows it only in other places (for example away from the edge of a level, "
                                                        "where a border or a corner needs it, or never next to the tiles around it)"),
                                      "Draw the tile at that kind of place in the sample (a border or corner tile must appear along the sample's own edge), fix another tile, "
                                      "or remove the tile that conflicts from `forbidden` / `max: 0` counts.");
                }
        }
    }
    // Count rules, part 2: against each other, the barred tiles and the fixed cells.
    std::vector<std::vector<char>> inRule(options.counts.size());
    std::vector<std::int64_t> forcedOf(options.counts.size(), 0);
    std::vector<std::size_t> forcedFirst(options.counts.size(), 0);
    for (std::size_t r = 0; r < options.counts.size(); ++r) {
        const CountRule& rule = options.counts[r];
        const std::string who = count_name(options.counts, r);
        std::vector<char>& in = inRule[r];
        in.assign(symbols, 0);
        for (int sym : rule.symbols) in[std::size_t(sym)] = 1;
        std::int64_t forced = 0, possible = outputCells;
        for (const auto& entry : effective) {
            bool allInside = true, anyInside = false, anyUsable = false;
            for (int sym : entry.second.allowed) {
                if (barred.is(sym)) continue;
                anyUsable = true;
                allInside = allInside && in[std::size_t(sym)];
                anyInside = anyInside || in[std::size_t(sym)];
            }
            if (anyUsable && allInside) {
                if (forced++ == 0) forcedFirst[r] = entry.second.first;
            }
            if (!anyInside) --possible;
        }
        forcedOf[r] = forced;
        if (rule.max >= 0 && forced > rule.max)
            return make_error(who + " allows at most " + std::to_string(rule.max) + " cells but " + std::to_string(forced) + " fixed cells already hold it (the first: " +
                                  rule_name(options.cellRules, forcedFirst[r]) + ")",
                              "Raise the maximum or fix fewer cells to it.");
        if (rule.min > 0) {
            int usableSym = -1;
            for (int sym : rule.symbols)
                if (!barred.is(sym)) {
                    usableSym = sym;
                    break;
                }
            if (usableSym < 0)
                return make_error(who + " needs at least " + std::to_string(rule.min) + " cells but none of its tiles can be placed: " + barred_text(barred, options.counts, rule.symbols.front()),
                                  "Remove the tile from `forbidden` or from the `max: 0` count, or drop the minimum.");
        }
        if (rule.min > possible)
            return make_error(who + " needs at least " + std::to_string(rule.min) + " cells but only " + std::to_string(possible) + " cells can hold it (the others are fixed to other tiles)",
                              "Lower the minimum, ask for a bigger output or fix fewer cells to other tiles.");
        if (rule.min > 0) {
            bool placeable = false;
            for (std::size_t p = 0; p < model->pattern_count() && !placeable; ++p) {
                if (patternForbidden[p]) continue;
                for (std::size_t k = 0; k < patternCells && !placeable; ++k) placeable = in[std::size_t(model->symbols[p * patternCells + k])] != 0;
            }
            if (!placeable)
                return make_error(who + " needs at least " + std::to_string(rule.min) + " cells but no pattern of the model holds it" + (forbiddenCount > 0 ? " (once the forbidden tiles are out)" : ""),
                                  "Draw it in the sample (the model only places what the sample shows) or drop the minimum.");
        }
    }
    // A minimum on tiles that all belong to another rule's group counts toward that group's maximum (and so do the fixed cells).
    for (std::size_t b = 0; b < options.counts.size(); ++b) {
        const CountRule& cap = options.counts[b];
        if (cap.max < 0) continue;
        for (std::size_t a = 0; a < options.counts.size(); ++a) {
            const CountRule& floorRule = options.counts[a];
            if (a == b || floorRule.min <= cap.max) continue;
            bool inside = true;
            for (int sym : floorRule.symbols)
                if (!barred.is(sym) && !inRule[b][std::size_t(sym)]) inside = false;
            if (inside)
                return make_error(count_name(options.counts, a) + " needs at least " + std::to_string(floorRule.min) + " cells, all of them tiles that " + count_name(options.counts, b) +
                                      " allows at most " + std::to_string(cap.max) + " of",
                                  "Lower the minimum, raise the maximum, or make the minimum name a tile outside the capped group.");
        }
    }

    auto impl = std::make_unique<Impl>();
    Impl& I = *impl;
    I.model = std::move(model);
    I.opt = std::move(options);
    const PatternModel& m = *I.model;
    I.T = m.pattern_count();
    I.words = (I.T + 63) / 64;
    I.wc = wave_side(I.opt.width, n, I.opt.periodic);
    I.hc = wave_side(I.opt.height, n, I.opt.periodic);
    I.cells = std::size_t(I.wc) * std::size_t(I.hc);
    I.logw.resize(I.T);
    for (std::size_t p = 0; p < I.T; ++p) I.logw[p] = log2_q20(m.weights[p]);
    I.supportInit.resize(I.T * kDirs);
    for (std::size_t p = 0; p < I.T; ++p) {
        bool isSpecial = false;
        for (int d = 0; d < kDirs; ++d) {
            I.supportInit[p * kDirs + std::size_t(d)] = std::uint16_t(m.compat[d][p].size());
            if (m.compat[d][p].empty() || !m.edgeOk[p * kDirs + std::size_t(d)]) isSpecial = true;
        }
        if (isSpecial) I.special.push_back(std::uint32_t(p));
    }
    for (const CellRule& rule : I.opt.cellRules) {
        std::vector<char> ok(std::size_t(m.symbolCount), 0);
        for (int s : rule.allowed) ok[std::size_t(s)] = 1;
        I.ruleMask.push_back(std::move(ok));
    }
    for (std::size_t p = 0; p < m.pattern_count(); ++p)
        if (patternForbidden[p]) I.forbiddenPatterns.push_back(std::uint32_t(p));
    I.ruleCell.assign(std::size_t(I.opt.width) * std::size_t(I.opt.height), 0);
    for (const CellRule& rule : I.opt.cellRules) I.ruleCell[std::size_t(rule.y) * std::size_t(I.opt.width) + std::size_t(rule.x)] = 1;
    for (const CountRule& rule : I.opt.counts) {
        std::vector<char> in(std::size_t(m.symbolCount), 0);
        for (int s : rule.symbols)
            if (!barred.is(s)) in[std::size_t(s)] = 1;
        I.countMask.push_back(std::move(in));
    }
    I.pendingPins.assign(I.opt.counts.size(), 0);
    I.heap.reserve(std::size_t(kHeapEntriesPerCell) * I.cells);
    I.dirty.reserve(I.cells);
    I.queue.reserve(I.cells);
    I.wave.resize(I.cells * I.words);
    I.pending.resize(I.cells * I.words);
    I.support.resize(I.cells * I.T * kDirs);
    I.remaining.resize(I.cells);
    I.sumW.resize(I.cells);
    I.sumWL.resize(I.cells);
    I.noise.resize(I.cells);
    I.stamp.resize(I.cells);
    I.dirtyFlag.resize(I.cells);
    I.queued.resize(I.cells);
    I.stats.patterns = int(I.T);
    I.stats.cells = int(I.cells);
    I.stats.memoryBytes = std::size_t(std::min<std::uint64_t>(need, SIZE_MAX));
    return std::unique_ptr<Generator>(new Generator(std::move(impl)));
}

GenStatus Generator::step(std::int64_t workBudget) { return impl_->step(workBudget); }

GenStatus Generator::run() {
    while (impl_->step(std::int64_t(1) << 20) == GenStatus::Running) {
    }
    return impl_->status;
}

GenStatus Generator::status() const { return impl_->status; }

double Generator::progress() const {
    if (impl_->status == GenStatus::Done) return 1.0;
    if (!impl_->attemptRunning || impl_->cells == 0) return 0.0;
    return 1.0 - double(impl_->undecided) / double(impl_->cells);
}

const std::vector<int>& Generator::output() const { return impl_->output; }
const GenStats& Generator::stats() const { return impl_->stats; }
const GenFailure& Generator::failure() const { return impl_->failure; }
int Generator::width() const { return impl_->opt.width; }
int Generator::height() const { return impl_->opt.height; }

std::string Generator::failure_message() const {
    const GenFailure& f = impl_->failure;
    const GenStats& s = impl_->stats;
    if (f.workLimit) {
        return "The work limit of " + std::to_string(impl_->opt.maxWork) + " units was reached after " + std::to_string(s.attempts) + (s.attempts == 1 ? " attempt" : " attempts") + " (" +
               std::to_string(s.work) + " units of work done)";
    }
    std::string m = "No level came out after " + std::to_string(s.attempts) + (s.attempts == 1 ? " attempt" : " attempts");
    if (s.contradictions > 0) m += " (" + std::to_string(s.contradictions) + " ended in a contradiction";
    if (s.rejected > 0) m += std::string(s.contradictions > 0 ? ", " : " (") + std::to_string(s.rejected) + " finished but were refused";
    if (s.contradictions > 0 || s.rejected > 0) m += ")";
    if (f.x >= 0) {
        m += ". The last one failed at cell (" + std::to_string(f.x) + ", " + std::to_string(f.y) + "): every pattern that could stand there was ruled out by its neighbours";
        if (f.cellRule >= 0) {
            const CellRule& rule = impl_->opt.cellRules[std::size_t(f.cellRule)];
            const int n = impl_->model->n;
            const int d = std::max(axis_distance(rule.x, f.x, n, impl_->opt.width, impl_->opt.periodic), axis_distance(rule.y, f.y, n, impl_->opt.height, impl_->opt.periodic));
            m += std::string("; the fixed cell (") + std::to_string(rule.x) + ", " + std::to_string(rule.y) + ") of " + rule_name(impl_->opt.cellRules, std::size_t(f.cellRule)) +
                 (d == 0 ? " is inside the pattern window there" : " is " + std::to_string(d) + " cell(s) from it");
        }
    } else {
        m += ". The last finished level was refused: " + f.reason;
    }
    return m;
}

std::string Generator::failure_hint() const {
    const GenFailure& f = impl_->failure;
    const GenerateOptions& o = impl_->opt;
    std::string h;
    if (f.workLimit) {
        h = "Make the level smaller, use a smaller n or symmetry 1 (fewer patterns), a simpler sample, fewer constraints, or raise the work limit.";
    } else if (f.x >= 0) {
        h = "Try a bigger or more varied sample (patterns that never meet in the sample cannot meet in the level), a smaller n, "
            "symmetry 2, 4 or 8 to learn rotated and mirrored patterns, periodic true, more attempts (maxAttempts), another seed";
        if (!o.cellRules.empty())
            h += ", or fewer and looser fixed cells and borders (a border or a rect longer than the sample's own straight pieces, or a tile next to one the sample never shows beside it, cannot be built)";
        bool anyMin = false;
        for (const CountRule& c : o.counts) anyMin = anyMin || c.min > 0;
        if (!o.forbidden.empty()) h += ", fewer forbidden tiles (they remove every pattern that holds them)";
        if (anyMin) h += ", lower minimums (a missing tile is pinned at a cell drawn from the seed, which can clash with its neighbours)";
        h += ".";
    } else if (f.countRule >= 0) {
        h = "Lower the minimum or raise the maximum, ask for a bigger output, make the sample show the tile (a tile that is rare in the sample is rare in the level, and one drawn only on the sample's edge can hardly be placed), "
            "give more attempts (maxAttempts), or use another seed.";
    } else {
        h = "Relax what the finished level has to satisfy, give more attempts (maxAttempts), or use another seed.";
    }
    return h;
}

}  // namespace fa::wfc
