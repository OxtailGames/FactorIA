// Wave Function Collapse: model builders and the steppable solver. See fa/scene/wfc.h for the design and the determinism rules.
#include "fa/scene/wfc.h"

#include <algorithm>
#include <bit>
#include <chrono>
#include <cstdio>
#include <map>

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

std::string mb(std::size_t bytes) {
    const double v = double(bytes) / (1024.0 * 1024.0);
    char buf[32];
    std::snprintf(buf, sizeof buf, "%.0f", v < 1.0 ? 1.0 : v);
    return std::string(buf) + " MB";
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
    std::map<Pat, std::size_t> index;
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
                auto it = index.find(v);
                if (it == index.end()) {
                    if (patterns.size() >= kMaxPatterns)
                        return make_error("The sample has more than " + std::to_string(kMaxPatterns) + " distinct " + std::to_string(n) + " x " + std::to_string(n) +
                                              " patterns, more than the generator handles",
                                          "Use a smaller or more regular sample, a smaller n, or a lower symmetry (symmetry 1 keeps only the patterns the sample shows).");
                    it = index.emplace(v, patterns.size()).first;
                    patterns.push_back(v);
                    weights.push_back(0);
                }
                ++weights[it->second];
            }
        }
    const std::size_t count = patterns.size();
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
        if (entries > kMaxCompatEntries)
            return make_error("The sample has " + std::to_string(count) + " patterns and their adjacency table would hold more than " + std::to_string(kMaxCompatEntries) +
                                  " entries",
                              "Use a smaller or less uniform sample, a bigger n (patterns constrain each other more), or symmetry 1.");
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
    for (const P& p : pats) {
        auto it = weightOf.find(p.value);
        m.weights.push_back(it == weightOf.end() ? 1u : std::max<std::uint32_t>(1u, it->second));
        m.symbols.push_back(symbolOf[p.value]);
        out.patternTerrain.push_back(p.terrain < 0 ? std::string() : terrains[std::size_t(p.terrain)].name);
    }
    for (int d = 0; d < kDirs; ++d) {
        m.compat[d].resize(count);
        for (std::size_t p = 0; p < count; ++p)
            for (std::size_t q = 0; q < count; ++q)
                if (bit(pats[p], d) == counts(pats[p].terrain, pats[q].terrain) && bit(pats[q], d ^ 2) == counts(pats[q].terrain, pats[p].terrain))
                    m.compat[d][p].push_back(std::uint16_t(q));
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

std::size_t estimate_generator_memory(const PatternModel& model, int width, int height, bool periodic) {
    const std::size_t cells = std::size_t(std::max(1, wave_side(width, model.n, periodic))) * std::size_t(std::max(1, wave_side(height, model.n, periodic)));
    const std::size_t T = model.pattern_count();
    const std::size_t words = (T + 63) / 64;
    // wave bits, four u16 support counters per pattern, and per cell: remaining, sums, noise, stamp, flags and a heap entry or two.
    return cells * (words * 8 + T * kDirs * 2 + 4 + 8 + 8 + 4 + 4 + 1 + 2 * 24) + T * 16 + width * std::size_t(height) * 8;
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
    struct Removed {
        std::uint32_t cell;
        std::uint32_t pattern;
    };
    std::vector<Removed> stack;
    struct HeapEntry {
        std::int64_t key;
        std::uint32_t noise;
        std::uint32_t cell;
        std::uint32_t stamp;
    };
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

    // ------------------------------------------------------------------------------------------------------------
    bool present(std::size_t cell, std::size_t p) const { return (wave[cell * words + (p >> 6)] >> (p & 63)) & 1u; }

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
        stack.push_back({std::uint32_t(cell), std::uint32_t(p)});
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
        dirty.clear();
        heap.clear();
        stack.clear();
        undecided = T > 1 ? cells : 0;
        for (std::size_t c = 0; c < cells; ++c) touch(c);

        // Patterns that cannot stand where the map has a neighbour (no pattern may follow them) or where it has none (the edge rules).
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
        // Cell rules: every wave cell that covers the output cell loses the patterns that put another symbol there.
        const int n = model->n;
        for (std::size_t r = 0; r < opt.cellRules.size() && !contradiction; ++r) {
            const CellRule& rule = opt.cellRules[r];
            const std::vector<char>& okSymbol = ruleMask[r];
            for (int oy = 0; oy < n; ++oy)
                for (int ox = 0; ox < n; ++ox) {
                    int cx = rule.x - ox, cy = rule.y - oy;
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
    }

    // Removes the support of one banned pattern from its neighbours; false when a cell ran out of patterns.
    void propagate_one() {
        const Removed r = stack.back();
        stack.pop_back();
        ++stats.propagations;
        for (int d = 0; d < kDirs; ++d) {
            std::size_t nb = 0;
            if (!neighbour(r.cell, d, nb)) continue;
            const std::size_t back = std::size_t(d ^ 2);
            for (std::uint16_t q : model->compat[d][r.pattern]) {
                if (!present(nb, q)) continue;
                std::uint16_t& c = support[(nb * T + q) * kDirs + back];
                if (c > 0 && --c == 0) ban(nb, q);
            }
            if (contradiction) return;
        }
    }

    void flush_dirty() {
        for (std::uint32_t c : dirty) {
            dirtyFlag[c] = 0;
            ++stamp[c];
            if (remaining[c] > 1) {
                const std::int64_t entropy = log2_q20(sumW[c]) - sumWL[c] / std::int64_t(sumW[c]);
                heap.push_back({entropy, noise[c], c, stamp[c]});
                std::push_heap(heap.begin(), heap.end(), heap_after);
            }
        }
        dirty.clear();
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

    void fail_attempt(int x, int y, const std::string& reason, bool isContradiction) {
        attemptRunning = false;
        failure.attempt = attempt;
        failure.x = x;
        failure.y = y;
        failure.reason = reason;
        ++failedAttempts;
        if (isContradiction) ++stats.contradictions;
        else ++stats.rejected;
        if (attempt >= opt.maxAttempts) status = GenStatus::Failed;
    }

    void finish_attempt() {
        output.assign(std::size_t(opt.width) * std::size_t(opt.height), 0);
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
        if (opt.accept) {
            std::string why;
            if (!opt.accept(output, why)) {
                fail_attempt(-1, -1, why.empty() ? "the finished level was refused" : why, false);
                return;
            }
        }
        stats.symbolCounts.assign(std::size_t(model->symbolCount), 0);
        for (int s : output) ++stats.symbolCounts[std::size_t(s)];
        attemptRunning = false;
        status = GenStatus::Done;
    }

    GenStatus step(std::int64_t budget) {
        if (status != GenStatus::Running) return status;
        const auto t0 = std::chrono::steady_clock::now();
        std::int64_t work = 0;
        while (status == GenStatus::Running && work < budget) {
            if (!attemptRunning) {
                begin_attempt();
                work += std::int64_t(cells);
            }
            if (contradiction) {
                fail_attempt(int(contradictionCell % std::uint32_t(wc)), int(contradictionCell / std::uint32_t(wc)), "contradiction", true);
                continue;
            }
            if (!stack.empty()) {
                propagate_one();
                ++work;
                continue;
            }
            flush_dirty();
            std::size_t cell = 0;
            if (!pick_cell(cell)) {
                finish_attempt();
                continue;
            }
            observe(cell);
            ++work;
        }
        stats.ms += std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
        return status;
    }
};

Generator::Generator(std::unique_ptr<Impl> impl) : impl_(std::move(impl)) {}
Generator::~Generator() = default;

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
    for (std::size_t r = 0; r < options.cellRules.size(); ++r) {
        const CellRule& rule = options.cellRules[r];
        if (rule.x < 0 || rule.y < 0 || rule.x >= options.width || rule.y >= options.height)
            return make_error("Cell rule " + std::to_string(r) + " names the cell (" + std::to_string(rule.x) + ", " + std::to_string(rule.y) + ") outside the " +
                                  std::to_string(options.width) + " x " + std::to_string(options.height) + " output",
                              "Cells count from 0 at the top-left; x is the column, y the row.");
        if (rule.allowed.empty()) return make_error("Cell rule " + std::to_string(r) + " allows no symbol at all", "List at least one symbol the cell may hold.");
        for (int s : rule.allowed)
            if (s < 0 || s >= model->symbolCount)
                return make_error("Cell rule " + std::to_string(r) + " allows symbol " + std::to_string(s) + " but the model has symbols 0.." + std::to_string(model->symbolCount - 1));
    }
    const std::size_t need = estimate_generator_memory(*model, options.width, options.height, options.periodic);
    if (need > kWfcMemoryBudget) {
        const std::size_t perCell = std::max<std::size_t>(1, need / (std::size_t(options.width) * std::size_t(options.height)));
        const std::size_t maxCells = kWfcMemoryBudget / perCell;
        int side = 1;
        while (std::size_t(side + 1) * std::size_t(side + 1) <= maxCells) ++side;
        return make_error("Generating " + std::to_string(options.width) + " x " + std::to_string(options.height) + " cells from a model with " +
                              std::to_string(model->pattern_count()) + " patterns needs about " + mb(need) + " of memory, above the limit of " + mb(kWfcMemoryBudget),
                          "Ask for a smaller size (about " + std::to_string(side) + " x " + std::to_string(side) + " fits this model), or reduce the patterns: a smaller n, symmetry 1, or a simpler sample.");
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
    I.wave.resize(I.cells * I.words);
    I.support.resize(I.cells * I.T * kDirs);
    I.remaining.resize(I.cells);
    I.sumW.resize(I.cells);
    I.sumWL.resize(I.cells);
    I.noise.resize(I.cells);
    I.stamp.resize(I.cells);
    I.dirtyFlag.resize(I.cells);
    I.stats.patterns = int(I.T);
    I.stats.cells = int(I.cells);
    I.stats.memoryBytes = need;
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
    std::string m = "No level came out after " + std::to_string(s.attempts) + (s.attempts == 1 ? " attempt" : " attempts");
    if (s.contradictions > 0) m += " (" + std::to_string(s.contradictions) + " ended in a contradiction";
    if (s.rejected > 0) m += std::string(s.contradictions > 0 ? ", " : " (") + std::to_string(s.rejected) + " finished but were refused";
    if (s.contradictions > 0 || s.rejected > 0) m += ")";
    if (f.x >= 0)
        m += ". The last one failed at cell (" + std::to_string(f.x) + ", " + std::to_string(f.y) + "): every pattern that could stand there was ruled out by its neighbours";
    else
        m += ". The last finished level was refused: " + f.reason;
    return m;
}

std::string Generator::failure_hint() const {
    const GenFailure& f = impl_->failure;
    std::string h;
    if (f.x >= 0) {
        h = "Try a bigger or more varied sample (patterns that never meet in the sample cannot meet in the level), a smaller n, "
            "symmetry 2, 4 or 8 to learn rotated and mirrored patterns, periodic true, more attempts (maxAttempts), another seed";
        if (!impl_->opt.cellRules.empty()) h += ", or fewer fixed cells";
        h += ".";
    } else {
        h = "Relax what the finished level has to satisfy, give more attempts (maxAttempts), or use another seed.";
    }
    return h;
}

}  // namespace fa::wfc
