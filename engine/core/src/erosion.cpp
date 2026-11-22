// Heightfield erosion: see fa/core/erosion.h. Only + - * / and sqrt on floats (and fa::det::tan for the talus angle).
#include "fa/core/erosion.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <limits>
#include <new>
#include <string>
#include <vector>

#include "fa/core/det_math.h"
#include "fa/core/jobs.h"
#include "fa/core/math.h"
#include "param_json.h"

namespace fa {

namespace {

constexpr std::uint64_t kU64Max = std::numeric_limits<std::uint64_t>::max();

std::uint64_t mul_sat(std::uint64_t a, std::uint64_t b) {
    if (a == 0 || b == 0) return 0;
    return a > kU64Max / b ? kU64Max : a * b;
}

// The cheap checks every erosion shares, before any work: grid, buffer size, cell size, finite heights.
Result<void> check_field(const HeightfieldView& f, std::string_view who) {
    if (f.width < 2 || f.height < 2 || f.width > kMaxHeightfieldSide || f.height > kMaxHeightfieldSide)
        return make_error(std::format("{}: the heightfield is {} x {}; each side must be from 2 to {} samples", who,
                                      f.width, f.height, kMaxHeightfieldSide),
                          "Erode in tiles with a margin, or resample the terrain to fewer samples.");
    const std::uint64_t cells = mul_sat(std::uint64_t(f.width), std::uint64_t(f.height));
    if (std::uint64_t(f.heights.size()) != cells)
        return make_error(std::format("{}: the heights array has {} values but a {} x {} heightfield needs {}", who,
                                      f.heights.size(), f.width, f.height, cells),
                          "Pass width * height floats, row by row.");
    if (!std::isfinite(f.cellSize) || f.cellSize <= 0.0f)
        return make_error(
            std::format("{}: cellSize {} is not allowed", who, detail::pj_num(f.cellSize)),
            "cellSize is the distance in metres between neighbouring samples; it must be finite and greater than 0.");
    return {};
}

// After the caps (a request that is refused anyway never scans the grid).
Result<void> check_finite(const HeightfieldView& f, std::string_view who) {
    for (std::size_t i = 0; i < f.heights.size(); ++i) {
        if (!std::isfinite(f.heights[i]))
            return make_error(std::format("{}: the height at x={}, y={} (index {}) is not a finite number", who,
                                          i % std::size_t(f.width), i / std::size_t(f.width), i),
                              "Fix or clamp the heights first (a NaN or infinity spreads to every cell it touches).");
    }
    return {};
}

double volume_of(const HeightfieldView& f) {
    double s = 0;
    for (float h : f.heights) s += double(h);
    return s * double(f.cellSize) * double(f.cellSize);
}

double max_of(std::span<const float> v) {
    float m = 0.0f;
    for (float x : v) m = x > m ? x : m;
    return double(m);
}

std::size_t row_grain(int width) { return std::max<std::size_t>(1, 16384u / std::size_t(width)); }

}  // namespace

// ============================================================================================================ thermal
std::uint64_t thermal_work(int width, int height, const ThermalErosionParams& params) {
    if (width <= 0 || height <= 0 || params.iterations <= 0) return 0;
    return mul_sat(mul_sat(std::uint64_t(width), std::uint64_t(height)), std::uint64_t(params.iterations));
}

Result<void> validate_thermal_params(const ThermalErosionParams& p, std::string_view pointer) {
    if (p.iterations < 1 || p.iterations > kMaxThermalIterations)
        return detail::pj_range_error(pointer, "iterations",
                                      std::format("{} is not allowed (1 to {})", p.iterations, kMaxThermalIterations),
                                      "Each iteration lets material slide one cell further; 20 to 100 is usual.");
    if (!std::isfinite(p.talusAngle) || p.talusAngle <= 0.0f || p.talusAngle > 89.9f)
        return detail::pj_range_error(
            pointer, "talusAngle",
            std::format("{} is not allowed (greater than 0 and at most 89.9 degrees)", detail::pj_num(p.talusAngle)),
            "talusAngle is the steepest stable slope in degrees: loose scree rests at about 35, "
            "packed rock holds 45 or more.");
    if (!std::isfinite(p.strength) || p.strength <= 0.0f || p.strength > 1.0f)
        return detail::pj_range_error(
            pointer, "strength",
            std::format("{} is not allowed (greater than 0 and at most 1)", detail::pj_num(p.strength)),
            "strength is the fraction of the excess slope that slides per iteration; 0.5 is smooth, "
            "1 is the fastest step that stays stable on most terrain.");
    return {};
}

Result<ThermalErosionParams> thermal_params_from_json(const Json& value, std::string_view pointer) {
    static const std::vector<std::string> keys = {"iterations", "talusAngle", "strength"};
    if (auto r = detail::pj_check_object(value, pointer, keys, "the thermal erosion parameters"); !r) return r.error();
    ThermalErosionParams p;
    std::int64_t iv = p.iterations;
    if (auto r = detail::pj_int(value, pointer, "iterations", 1, kMaxThermalIterations, iv); !r) return r.error();
    p.iterations = int(iv);
    if (auto r = detail::pj_float(value, pointer, "talusAngle", p.talusAngle); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "strength", p.strength); !r) return r.error();
    if (auto r = validate_thermal_params(p, pointer); !r) return r.error();
    return p;
}

Json thermal_params_to_json(const ThermalErosionParams& p) {
    return Json{{"iterations", p.iterations}, {"talusAngle", p.talusAngle}, {"strength", p.strength}};
}

Json thermal_params_schema() {
    Json props = Json::object();
    props["iterations"] = {{"type", "integer"},
                           {"minimum", 1},
                           {"maximum", kMaxThermalIterations},
                           {"default", 30},
                           {"description", "Passes over the grid; each lets material slide one cell further."}};
    props["talusAngle"] = {{"type", "number"},
                           {"exclusiveMinimum", 0},
                           {"maximum", 89.9},
                           {"default", 35},
                           {"description",
                            "Steepest stable slope in degrees: a steeper slope slides down. Loose scree rests at "
                            "about 35, packed rock holds 45 or more."}};
    props["strength"] = {{"type", "number"},
                         {"exclusiveMinimum", 0},
                         {"maximum", 1},
                         {"default", 0.5},
                         {"description", "Fraction of the excess slope that slides per pass; lower is smoother."}};
    return Json{{"type", "object"},
                {"description", "Thermal erosion: material slides down slopes steeper than the talus angle."},
                {"properties", props},
                {"additionalProperties", false}};
}

Result<ErosionResult> erode_thermal(const HeightfieldView& field, const ThermalErosionParams& params) {
    if (auto r = validate_thermal_params(params); !r) return r.error();
    if (auto r = check_field(field, "erode_thermal"); !r) return r.error();
    const int w = field.width, h = field.height;
    const std::uint64_t cells = std::uint64_t(w) * std::uint64_t(h);
    const std::uint64_t work = thermal_work(w, h, params);
    if (work > kMaxThermalWork)
        return make_error(
            std::format("erode_thermal: {} x {} cells x {} iterations is {} cell updates, more than the {} "
                        "allowed",
                        w, h, params.iterations, work, kMaxThermalWork),
            "Use fewer iterations or a smaller heightfield (the work is cells x iterations).");
    const std::uint64_t scratch = mul_sat(cells, 3u * sizeof(float));
    if (scratch > kMaxErosionScratchBytes)
        return make_error(
            std::format("erode_thermal: it needs {} MB of working memory for {} x {} cells, more than the {} MB "
                        "allowed",
                        scratch / (1024 * 1024), w, h, kMaxErosionScratchBytes / (1024 * 1024)),
            "Erode the terrain in tiles with a margin of a few cells, or resample it to fewer samples.");
    if (auto r = check_finite(field, "erode_thermal"); !r) return r.error();

    std::vector<float> ratioBuf, acceptBuf, other;  // give per unit of excess, share accepted, the next heights
    try {
        ratioBuf.assign(std::size_t(cells), 0.0f);
        acceptBuf.assign(std::size_t(cells), 0.0f);
        other.assign(std::size_t(cells), 0.0f);
    } catch (const std::bad_alloc&) {
        return make_error(
            std::format("erode_thermal: out of memory for {} MB of working buffers", scratch / (1024 * 1024)),
            "Close other programs, or erode the terrain in tiles.");
    }

    ErosionResult res;
    res.volumeBefore = volume_of(field);
    res.workUnits = work;

    constexpr int kDx[8] = {-1, 0, 1, -1, 1, -1, 0, 1};
    constexpr int kDy[8] = {-1, -1, -1, 0, 0, 1, 1, 1};
    constexpr float kDiag = 1.41421356f;
    const float tanTalus = det::tan(params.talusAngle * (3.14159265f / 180.0f));
    float thr[8];  // the height drop to each neighbour that is still stable
    for (int k = 0; k < 8; ++k) thr[k] = tanTalus * field.cellSize * ((kDx[k] != 0 && kDy[k] != 0) ? kDiag : 1.0f);
    const float give = params.strength * 0.5f;
    const double cs2 = double(field.cellSize) * double(field.cellSize);
    const std::size_t grain = row_grain(w);

    // Per cell: `ratio` = what a donor gives per unit of excess, `accept` = the share (0..1) of what its donors offer that
    // a receiver takes (so it never ends higher than the midpoint to its lowest donor). A donor loses exactly what its
    // receivers take, so the volume is kept and no cell leaves the height range of its 3 x 3 neighbourhood.
    float* src = field.heights.data();
    float* dst = other.data();
    float* ratio = ratioBuf.data();
    float* accept = acceptBuf.data();
    std::vector<double> rowMoved(std::size_t(h), 0.0);
    double movedTotal = 0;
    for (int it = 0; it < params.iterations; ++it) {
        // Pass 1: each cell's give-per-excess ratio: strength/2 of its largest excess, shared by the excesses.
        auto r1 = jobs::parallel_for("erosion.thermal.give", std::size_t(h), grain, [&](const jobs::Chunk& c) {
            for (std::size_t j = c.begin; j < c.end; ++j) {
                for (int i = 0; i < w; ++i) {
                    const std::size_t idx = j * std::size_t(w) + std::size_t(i);
                    const float hc = src[idx];
                    float emax = 0.0f, sum = 0.0f;
                    for (int k = 0; k < 8; ++k) {
                        const int nx = i + kDx[k], ny = int(j) + kDy[k];
                        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                        const float e = (hc - src[std::size_t(ny) * std::size_t(w) + std::size_t(nx)]) - thr[k];
                        if (e > 0.0f) {
                            sum += e;
                            if (e > emax) emax = e;
                        }
                    }
                    ratio[idx] = emax > 0.0f ? give * emax / sum : 0.0f;
                }
            }
        });
        if (!r1) return r1.error();
        // Pass 2: how much of the offered inflow each cell accepts: at most half the way up to its lowest donor.
        auto r2 = jobs::parallel_for("erosion.thermal.accept", std::size_t(h), grain, [&](const jobs::Chunk& c) {
            for (std::size_t j = c.begin; j < c.end; ++j) {
                for (int i = 0; i < w; ++i) {
                    const std::size_t idx = j * std::size_t(w) + std::size_t(i);
                    const float hc = src[idx];
                    float offered = 0.0f, lowest = 0.0f;
                    bool any = false;
                    for (int k = 0; k < 8; ++k) {
                        const int nx = i + kDx[k], ny = int(j) + kDy[k];
                        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                        const std::size_t n = std::size_t(ny) * std::size_t(w) + std::size_t(nx);
                        if (!(ratio[n] > 0.0f)) continue;
                        const float e = (src[n] - hc) - thr[k];
                        if (!(e > 0.0f)) continue;
                        offered += ratio[n] * e;
                        if (!any || src[n] < lowest) lowest = src[n];
                        any = true;
                    }
                    const float room = any ? 0.5f * (lowest - hc) : 0.0f;
                    accept[idx] = (any && offered > room) ? room / offered : 1.0f;
                }
            }
        });
        if (!r2) return r2.error();
        // Pass 3: every cell loses what its receivers accept and gathers what it accepts from its donors.
        auto r3 = jobs::parallel_for("erosion.thermal.take", std::size_t(h), grain, [&](const jobs::Chunk& c) {
            for (std::size_t j = c.begin; j < c.end; ++j) {
                double rowSum = 0.0;
                for (int i = 0; i < w; ++i) {
                    const std::size_t idx = j * std::size_t(w) + std::size_t(i);
                    const float hc = src[idx];
                    float lose = 0.0f, gain = 0.0f;
                    for (int k = 0; k < 8; ++k) {
                        const int nx = i + kDx[k], ny = int(j) + kDy[k];
                        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                        const std::size_t n = std::size_t(ny) * std::size_t(w) + std::size_t(nx);
                        const float down = (hc - src[n]) - thr[k];
                        if (down > 0.0f) lose += down * accept[n];
                        if (ratio[n] > 0.0f) {
                            const float up = (src[n] - hc) - thr[k];
                            if (up > 0.0f) gain += ratio[n] * up;
                        }
                    }
                    gain *= accept[idx];
                    dst[idx] = (hc - ratio[idx] * lose) + gain;
                    rowSum += double(gain);
                }
                rowMoved[j] = rowSum;
            }
        });
        if (!r3) return r3.error();
        for (int j = 0; j < h; ++j) movedTotal += rowMoved[std::size_t(j)];
        std::swap(src, dst);
    }
    if (src != field.heights.data()) std::copy(src, src + std::size_t(cells), field.heights.data());

    res.erodedVolume = res.depositedVolume = movedTotal * cs2;
    res.volumeAfter = volume_of(field);
    return res;
}

// ========================================================================================================= hydraulic
std::uint64_t hydraulic_work(const HydraulicErosionParams& p) {
    if (p.droplets <= 0 || p.maxLifetime <= 0) return 0;
    return mul_sat(std::uint64_t(p.droplets), std::uint64_t(p.maxLifetime));
}

namespace {

Error hy_error(std::string_view pointer, const char* key, std::string_view problem, std::string_view hint) {
    return detail::pj_range_error(pointer, key, problem, hint);
}

std::string range_text(float v, std::string_view limits) {
    return std::format("{} is not allowed ({})", detail::pj_num(v), limits);
}

}  // namespace

Result<void> validate_hydraulic_params(const HydraulicErosionParams& p, std::string_view pointer) {
    auto finite = [](float v) { return std::isfinite(v); };
    if (p.droplets < 0 || p.droplets > kMaxDroplets)
        return hy_error(pointer, "droplets", std::format("{} is not allowed (0 to {})", p.droplets, kMaxDroplets),
                        "Each droplet is one raindrop's path; 50000 on a 512 x 512 grid is a good start.");
    if (p.maxLifetime < 1 || p.maxLifetime > kMaxDropletLifetime)
        return hy_error(
            pointer, "maxLifetime", std::format("{} is not allowed (1 to {})", p.maxLifetime, kMaxDropletLifetime),
            "A droplet moves about one cell per step: 30 steps suits a 512-cell grid, more for larger ones.");
    const std::uint64_t work = hydraulic_work(p);
    if (work > kMaxHydraulicSteps)
        return hy_error(
            pointer, "droplets",
            std::format("{} droplets x {} steps is {} droplet steps, more than the {} allowed", p.droplets,
                        p.maxLifetime, work, kMaxHydraulicSteps),
            std::format("Use at most {} droplets with maxLifetime {}, or shorten maxLifetime (droplet erosion "
                        "runs on one thread to keep results identical on every machine).",
                        kMaxHydraulicSteps / std::uint64_t(p.maxLifetime), p.maxLifetime));
    if (!finite(p.inertia) || p.inertia < 0.0f || p.inertia > 0.99f)
        return hy_error(
            pointer, "inertia", range_text(p.inertia, "0 to 0.99"),
            "inertia is how much a droplet keeps its direction: 0 follows the slope exactly, 0.3 makes wide "
            "curved gullies.");
    if (!finite(p.capacity) || p.capacity <= 0.0f || p.capacity > 100.0f)
        return hy_error(pointer, "capacity", range_text(p.capacity, "greater than 0 and at most 100"),
                        "capacity scales the sediment a droplet can carry; 4 is the usual value, higher erodes more.");
    if (!finite(p.minSlope) || p.minSlope < 0.0f || p.minSlope > 1.0f)
        return hy_error(pointer, "minSlope", range_text(p.minSlope, "0 to 1"),
                        "minSlope keeps a little capacity on flat ground so droplets do not drop everything at once; "
                        "0.01 is usual.");
    if (!finite(p.deposition) || p.deposition < 0.0f || p.deposition > 1.0f)
        return hy_error(pointer, "deposition", range_text(p.deposition, "0 to 1"),
                        "deposition is the fraction of the surplus sediment dropped per step; 0.3 is usual.");
    if (!finite(p.erosion) || p.erosion < 0.0f || p.erosion > 1.0f)
        return hy_error(pointer, "erosion", range_text(p.erosion, "0 to 1"),
                        "erosion is the fraction of the free capacity picked up per step; 0.3 is usual.");
    if (!finite(p.evaporation) || p.evaporation < 0.0f || p.evaporation > 0.5f)
        return hy_error(pointer, "evaporation", range_text(p.evaporation, "0 to 0.5"),
                        "evaporation is the fraction of its water a droplet loses per step; 0.01 is usual.");
    if (!finite(p.gravity) || p.gravity < 0.0f || p.gravity > 100.0f)
        return hy_error(pointer, "gravity", range_text(p.gravity, "0 to 100"),
                        "gravity makes droplets speed up downhill (more capacity) and slow down uphill; 4 is usual.");
    if (p.radius < 1 || p.radius > kMaxErosionBrushRadius)
        return hy_error(
            pointer, "radius", std::format("{} is not allowed (1 to {})", p.radius, kMaxErosionBrushRadius),
            "radius is how many cells around a droplet lose height: 1 digs one cell (narrow gullies), 3 is usual.");
    return {};
}

Result<HydraulicErosionParams> hydraulic_params_from_json(const Json& value, std::string_view pointer) {
    static const std::vector<std::string> keys = {"seed",        "droplets", "maxLifetime", "inertia",
                                                  "capacity",    "minSlope", "deposition",  "erosion",
                                                  "evaporation", "gravity",  "radius"};
    if (auto r = detail::pj_check_object(value, pointer, keys, "the hydraulic erosion parameters"); !r)
        return r.error();
    HydraulicErosionParams p;
    std::int64_t iv = 0;
    if (auto r = detail::pj_u64(value, pointer, "seed", p.seed); !r) return r.error();
    if (auto r = detail::pj_int(value, pointer, "droplets", 0, kMaxDroplets, p.droplets); !r) return r.error();
    iv = p.maxLifetime;
    if (auto r = detail::pj_int(value, pointer, "maxLifetime", 1, kMaxDropletLifetime, iv); !r) return r.error();
    p.maxLifetime = int(iv);
    if (auto r = detail::pj_float(value, pointer, "inertia", p.inertia); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "capacity", p.capacity); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "minSlope", p.minSlope); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "deposition", p.deposition); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "erosion", p.erosion); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "evaporation", p.evaporation); !r) return r.error();
    if (auto r = detail::pj_float(value, pointer, "gravity", p.gravity); !r) return r.error();
    iv = p.radius;
    if (auto r = detail::pj_int(value, pointer, "radius", 1, kMaxErosionBrushRadius, iv); !r) return r.error();
    p.radius = int(iv);
    if (auto r = validate_hydraulic_params(p, pointer); !r) return r.error();
    return p;
}

Json hydraulic_params_to_json(const HydraulicErosionParams& p) {
    Json j = Json::object();
    j["seed"] = p.seed;
    j["droplets"] = p.droplets;
    j["maxLifetime"] = p.maxLifetime;
    j["inertia"] = p.inertia;
    j["capacity"] = p.capacity;
    j["minSlope"] = p.minSlope;
    j["deposition"] = p.deposition;
    j["erosion"] = p.erosion;
    j["evaporation"] = p.evaporation;
    j["gravity"] = p.gravity;
    j["radius"] = p.radius;
    return j;
}

Json hydraulic_params_schema() {
    auto num = [](const char* desc, double lo, double hi, double def, bool exclusiveLo = false) {
        Json f = {{"type", "number"}, {"description", desc}, {"maximum", hi}, {"default", def}};
        f[exclusiveLo ? "exclusiveMinimum" : "minimum"] = lo;
        return f;
    };
    Json props = Json::object();
    props["seed"] = {{"type", "integer"},
                     {"minimum", 0},
                     {"default", 0},
                     {"description", "Seeds where droplets start; the same seed always gives the same terrain."}};
    props["droplets"] = {
        {"type", "integer"},
        {"minimum", 0},
        {"maximum", kMaxDroplets},
        {"default", 50000},
        {"description", "Raindrops to simulate; droplets x maxLifetime may not exceed 268435456 steps."}};
    props["maxLifetime"] = {
        {"type", "integer"},
        {"minimum", 1},
        {"maximum", kMaxDropletLifetime},
        {"default", 30},
        {"description", "Most steps a droplet takes (about one cell each) before it drops its sediment."}};
    props["inertia"] = num(
        "How much a droplet keeps its direction instead of following the slope; 0 follows it exactly.", 0, 0.99, 0.05);
    props["capacity"] =
        num("Sediment a droplet can carry per unit of slope, speed and water; higher erodes more.", 0, 100, 4, true);
    props["minSlope"] =
        num("Slope used for the capacity on flat ground, so droplets still carry a little.", 0, 1, 0.01);
    props["deposition"] = num("Fraction of the surplus sediment dropped per step when over capacity.", 0, 1, 0.3);
    props["erosion"] = num("Fraction of the free capacity picked up per step.", 0, 1, 0.3);
    props["evaporation"] =
        num("Fraction of its water a droplet loses per step (less water carries less sediment).", 0, 0.5, 0.01);
    props["gravity"] = num("How strongly a drop in height speeds a droplet up and a rise slows it down.", 0, 100, 4);
    props["radius"] = {
        {"type", "integer"},
        {"minimum", 1},
        {"maximum", kMaxErosionBrushRadius},
        {"default", 3},
        {"description", "Cells around a droplet that lose height when it erodes: 1 digs narrow gullies."}};
    return Json{{"type", "object"},
                {"description", "Droplet-based hydraulic erosion: serial, deterministic for a seed."},
                {"properties", props},
                {"additionalProperties", false}};
}

namespace {

struct BrushCell {
    int dx, dy;
    float weight;
};

// Bilinear weights of the 4 cells around a position inside cell (ix, iy).
struct Corners {
    std::size_t i00;
    float w00, w10, w01, w11;
};

inline Corners corners_at(int ix, int iy, float fx, float fy, int width) {
    Corners c;
    c.i00 = std::size_t(iy) * std::size_t(width) + std::size_t(ix);
    c.w00 = (1.0f - fx) * (1.0f - fy);
    c.w10 = fx * (1.0f - fy);
    c.w01 = (1.0f - fx) * fy;
    c.w11 = fx * fy;
    return c;
}

inline void add4(float* data, const Corners& c, int width, float amount) {
    data[c.i00] += amount * c.w00;
    data[c.i00 + 1] += amount * c.w10;
    data[c.i00 + std::size_t(width)] += amount * c.w01;
    data[c.i00 + std::size_t(width) + 1] += amount * c.w11;
}

// A unit vector from the PCG stream, without sin and cos: rejection sampling in the unit disc (8 tries, then +x).
void random_direction(Rng& rng, float& dx, float& dy) {
    for (int k = 0; k < 8; ++k) {
        const float x = rng.range(-1.0f, 1.0f), y = rng.range(-1.0f, 1.0f);
        const float r2 = x * x + y * y;
        if (r2 > 1.0e-4f && r2 <= 1.0f) {
            const float inv = 1.0f / std::sqrt(r2);
            dx = x * inv;
            dy = y * inv;
            return;
        }
    }
    dx = 1.0f;
    dy = 0.0f;
}

}  // namespace

Result<ErosionResult> erode_hydraulic(const HeightfieldView& field, const HydraulicErosionParams& params,
                                      const ErosionMasks& masks) {
    if (auto r = validate_hydraulic_params(params); !r) return r.error();
    if (auto r = check_field(field, "erode_hydraulic"); !r) return r.error();
    const int w = field.width, h = field.height;
    const std::uint64_t cells = std::uint64_t(w) * std::uint64_t(h);
    struct NamedMask {
        const char* name;
        std::span<float> data;
    };
    for (const NamedMask& m : {NamedMask{"flow", masks.flow}, NamedMask{"erosion", masks.erosion},
                               NamedMask{"deposition", masks.deposition}}) {
        if (!m.data.empty() && std::uint64_t(m.data.size()) != cells)
            return make_error(
                std::format("erode_hydraulic: the {} mask has {} values but the {} x {} heightfield needs {}", m.name,
                            m.data.size(), w, h, cells),
                "Pass an empty span to skip a mask, or width * height floats.");
    }

    if (auto r = check_finite(field, "erode_hydraulic"); !r) return r.error();

    ErosionResult res;
    res.volumeBefore = volume_of(field);
    res.droplets = std::uint64_t(params.droplets);
    for (std::span<float> m : {masks.flow, masks.erosion, masks.deposition}) std::fill(m.begin(), m.end(), 0.0f);

    // The erosion brush: cells within `radius` of the droplet, weighted by 1 - distance / radius.
    std::vector<BrushCell> brush;
    float brushTotal = 0.0f;
    const int rad = params.radius;
    for (int dy = -rad; dy <= rad; ++dy) {
        for (int dx = -rad; dx <= rad; ++dx) {
            const float d = std::sqrt(float(dx * dx + dy * dy));
            const float wt = 1.0f - d / float(rad);
            if (wt > 0.0f) {
                brush.push_back({dx, dy, wt});
                brushTotal += wt;
            }
        }
    }

    float* hs = field.heights.data();
    float* flow = masks.flow.empty() ? nullptr : masks.flow.data();
    float* erosionMask = masks.erosion.empty() ? nullptr : masks.erosion.data();
    float* depositMask = masks.deposition.empty() ? nullptr : masks.deposition.data();
    const float cs = field.cellSize, inv = 1.0f / field.cellSize;
    const double cs3 =
        double(cs) * double(cs) * double(cs);  // volume of a height of 1 grid unit (cs metres) over a cell
    Rng rng(params.seed);
    const float maxX = float(w - 1), maxY = float(h - 1);
    double eroded = 0, deposited = 0;
    std::uint64_t steps = 0;

    // Drops `amount` (grid units) at the position inside cell (ix, iy).
    auto deposit = [&](int ix, int iy, float fx, float fy, float amount) {
        if (!(amount > 0.0f)) return;
        const Corners c = corners_at(ix, iy, fx, fy, w);
        const float metres = amount * cs;
        add4(hs, c, w, metres);
        if (depositMask) add4(depositMask, c, w, metres);
        deposited += double(amount) * cs3;
    };

    for (std::int64_t d = 0; d < params.droplets; ++d) {
        float px = rng.next_float() * maxX, py = rng.next_float() * maxY;
        float dx = 0.0f, dy = 0.0f, speed = 1.0f, water = 1.0f, sediment = 0.0f;
        bool dropped = false;
        for (int life = 0; life < params.maxLifetime; ++life) {
            int ix = int(px), iy = int(py);
            if (ix > w - 2) ix = w - 2;
            if (iy > h - 2) iy = h - 2;
            const float fx = px - float(ix), fy = py - float(iy);
            const std::size_t i00 = std::size_t(iy) * std::size_t(w) + std::size_t(ix);
            const float h00 = hs[i00], h10 = hs[i00 + 1], h01 = hs[i00 + std::size_t(w)],
                        h11 = hs[i00 + std::size_t(w) + 1];
            const float gx = ((h10 - h00) * (1.0f - fy) + (h11 - h01) * fy) * inv;  // slope along x (rise over run)
            const float gy = ((h01 - h00) * (1.0f - fx) + (h11 - h10) * fx) * inv;
            const float hOld =
                h00 * (1.0f - fx) * (1.0f - fy) + h10 * fx * (1.0f - fy) + h01 * (1.0f - fx) * fy + h11 * fx * fy;

            dx = dx * params.inertia - gx * (1.0f - params.inertia);
            dy = dy * params.inertia - gy * (1.0f - params.inertia);
            const float len = std::sqrt(dx * dx + dy * dy);
            if (len < 1.0e-6f) {
                random_direction(rng, dx, dy);
            } else {
                dx /= len;
                dy /= len;
            }
            const float nx = px + dx, ny = py + dy;
            if (!(nx >= 0.0f && nx < maxX && ny >= 0.0f && ny < maxY)) {
                deposit(ix, iy, fx, fy, sediment);  // about to leave the grid: settle here
                sediment = 0.0f;
                dropped = true;
                break;
            }
            ++steps;
            if (flow) add4(flow, corners_at(ix, iy, fx, fy, w), w, water);

            int nix = int(nx), niy = int(ny);
            if (nix > w - 2) nix = w - 2;
            if (niy > h - 2) niy = h - 2;
            const float nfx = nx - float(nix), nfy = ny - float(niy);
            const std::size_t n00 = std::size_t(niy) * std::size_t(w) + std::size_t(nix);
            const float hNew = hs[n00] * (1.0f - nfx) * (1.0f - nfy) + hs[n00 + 1] * nfx * (1.0f - nfy) +
                               hs[n00 + std::size_t(w)] * (1.0f - nfx) * nfy + hs[n00 + std::size_t(w) + 1] * nfx * nfy;
            const float deltaH = (hNew - hOld) * inv;  // grid units; > 0 is uphill

            const float minS = -deltaH > params.minSlope ? -deltaH : params.minSlope;
            const float cap = minS * speed * water * params.capacity;
            if (sediment > cap || deltaH > 0.0f) {
                const float amount =
                    deltaH > 0.0f ? (deltaH < sediment ? deltaH : sediment) : (sediment - cap) * params.deposition;
                sediment -= amount;
                deposit(ix, iy, fx, fy, amount);
            } else {
                float amount = (cap - sediment) * params.erosion;
                if (amount > -deltaH) amount = -deltaH;
                if (amount > 0.0f) {
                    const bool interior = ix >= rad && ix < w - rad && iy >= rad && iy < h - rad;
                    float total = brushTotal;
                    if (!interior) {
                        total = 0.0f;
                        for (const BrushCell& b : brush) {
                            const int cx = ix + b.dx, cy = iy + b.dy;
                            if (cx >= 0 && cx < w && cy >= 0 && cy < h) total += b.weight;
                        }
                    }
                    const float perWeight = amount * cs / total;  // metres per unit of brush weight
                    for (const BrushCell& b : brush) {
                        const int cx = ix + b.dx, cy = iy + b.dy;
                        if (cx < 0 || cx >= w || cy < 0 || cy >= h) continue;
                        const std::size_t ci = std::size_t(cy) * std::size_t(w) + std::size_t(cx);
                        const float m = perWeight * b.weight;
                        hs[ci] -= m;
                        if (erosionMask) erosionMask[ci] += m;
                    }
                    sediment += amount;
                    eroded += double(amount) * cs3;
                }
            }
            const float s2 = speed * speed + deltaH * params.gravity;
            speed = s2 > 0.0f ? std::sqrt(s2) : 0.0f;
            water *= 1.0f - params.evaporation;
            px = nx;
            py = ny;
        }
        if (!dropped && sediment > 0.0f) {  // lifetime over: the water is gone, the sediment settles
            int ix = int(px), iy = int(py);
            if (ix > w - 2) ix = w - 2;
            if (iy > h - 2) iy = h - 2;
            deposit(ix, iy, px - float(ix), py - float(iy), sediment);
        }
    }

    res.workUnits = steps;
    res.erodedVolume = eroded;
    res.depositedVolume = deposited;
    res.volumeAfter = volume_of(field);
    res.maxFlow = max_of(masks.flow);
    res.maxErosion = max_of(masks.erosion);
    res.maxDeposition = max_of(masks.deposition);
    return res;
}

}  // namespace fa
