// The fit: Nelder-Mead on the cubic error of every cell of the table, each cell starting from its neighbour's parameters.
#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>

#include "fa/core/jobs.h"
#include "fa/ltc/ltc.h"
#include "ltc_internal.h"

namespace fa::ltc {
namespace {

// What the fit moves: the angle of the lobe's center away from the BRDF's mean direction (rotation about y), the natural log of
// the lobe's width along x and along y, and the skew of its x axis towards z. M = R_y(psi) [[sx, 0, 0], [0, sy, 0], [sk, 0, 1]]
// (psi = the mean direction's angle + the first parameter): R_y(psi) sends +z to the lobe's center, so the center depends on
// psi alone. M^-1 is written as the Lobe with its middle entry scaled to 1.
using Params = std::array<double, 4>;  // psi offset, ln sx, sk, ln sy

Lobe lobe_of(const Params& p, double psiMean) {
    double s = 0, c = 0;
    det_sincos(psiMean + p[0], s, c);
    const double sx = det_exp(p[1]);
    const double sy = det_exp(p[3]);
    const double k = p[2];
    const double r = sy / sx;
    return {r * c, -r * s, sy * (s - k * c / sx), sy * (c + k * s / sx)};
}

constexpr double kBadError = 1e300;

// Nelder-Mead (reflection 1, expansion 2, contraction 1/2, shrink 1/2) with a fixed iteration cap. Ties are broken by the
// position in the simplex, never by anything that depends on the machine.
template <class F>
Params nelder_mead(const F& f, const Params& start, const Params& step, int maxIterations, double* best) {
    constexpr int kN = 4;
    std::array<Params, kN + 1> pts;
    std::array<double, kN + 1> fv{};
    pts[0] = start;
    for (int i = 0; i < kN; ++i) {
        pts[i + 1] = start;
        pts[i + 1][i] += step[i];
    }
    for (int i = 0; i <= kN; ++i) fv[i] = f(pts[i]);
    auto order = [&] {
        for (int i = 1; i <= kN; ++i) {  // insertion sort, stable
            const Params p = pts[i];
            const double v = fv[i];
            int j = i - 1;
            while (j >= 0 && fv[j] > v) {
                pts[j + 1] = pts[j];
                fv[j + 1] = fv[j];
                --j;
            }
            pts[j + 1] = p;
            fv[j + 1] = v;
        }
    };
    auto combine = [&](const Params& c, const Params& x, double t) {  // c + t (x - c)
        Params r;
        for (int i = 0; i < kN; ++i) r[i] = c[i] + t * (x[i] - c[i]);
        return r;
    };
    for (int it = 0; it < maxIterations; ++it) {
        order();
        double diameter = 0.0;
        for (int i = 1; i <= kN; ++i)
            for (int k = 0; k < kN; ++k) diameter = std::max(diameter, std::fabs(pts[i][k] - pts[0][k]));
        if (diameter < 1e-9 || fv[kN] - fv[0] <= 1e-7 * fv[0]) break;
        Params centroid{};
        for (int i = 0; i < kN; ++i)
            for (int k = 0; k < kN; ++k) centroid[k] += pts[i][k] * 0.25;
        const Params worst = pts[kN];
        const Params reflected = combine(centroid, worst, -1.0);
        const double fr = f(reflected);
        bool shrink = false;
        if (fr < fv[0]) {
            const Params expanded = combine(centroid, worst, -2.0);
            const double fe = f(expanded);
            if (fe < fr) {
                pts[kN] = expanded;
                fv[kN] = fe;
            } else {
                pts[kN] = reflected;
                fv[kN] = fr;
            }
        } else if (fr < fv[kN - 1]) {
            pts[kN] = reflected;
            fv[kN] = fr;
        } else if (fr < fv[kN]) {
            const Params outside = combine(centroid, worst, -0.5);
            const double fo = f(outside);
            if (fo <= fr) {
                pts[kN] = outside;
                fv[kN] = fo;
            } else {
                shrink = true;
            }
        } else {
            const Params inside = combine(centroid, worst, 0.5);
            const double fi = f(inside);
            if (fi < fv[kN]) {
                pts[kN] = inside;
                fv[kN] = fi;
            } else {
                shrink = true;
            }
        }
        if (shrink) {
            for (int i = 1; i <= kN; ++i) {
                pts[i] = combine(pts[0], pts[i], 0.5);
                fv[i] = f(pts[i]);
            }
        }
    }
    order();
    *best = fv[0];
    return pts[0];
}

struct CellFit {
    Params params{};
    Lobe lobe;
    Albedo albedo;
    double error = 0;
};

CellFit fit_cell(double roughness, double cosTheta, const Params& start, const TableConfig& config) {
    const detail::CellProblem problem(roughness, cosTheta, config.fitSamples, config.albedoSamples);
    const double psiMean = problem.mean_angle();
    auto objective = [&](const Params& p) {
        const double v = problem.cubic_error(lobe_of(p, psiMean));
        return std::isfinite(v) ? v : kBadError;
    };
    // The steps of the center and the skew follow the lobe's width (angles of a narrow lobe are tiny), those of the widths
    // are fractions.
    const double width = std::min(1.0, det_exp(start[1]));
    double best = 0.0;
    Params p = nelder_mead(objective, start, {0.25 * width, 0.12, 0.25 * width, 0.12}, config.iterations, &best);
    p = nelder_mead(objective, p, {0.05 * width, 0.03, 0.05 * width, 0.03}, config.iterations, &best);
    CellFit out;
    out.params = p;
    out.lobe = lobe_of(p, psiMean);
    out.albedo = problem.albedo();
    out.error = problem.l1_error(out.lobe);
    return out;
}

Error bad_config(const char* field, const std::string& what, const std::string& hint) {
    return Error{std::string("TableConfig.") + field + " " + what, hint};
}

}  // namespace

Result<Table> fit_table(const TableConfig& config) {
    if (config.size < 2 || config.size > 256)
        return bad_config("size", "is " + std::to_string(config.size) + ", not between 2 and 256",
                          "the shipped table is 64; use a small size (8) for tests");
    if (config.fitSamples < 16 || config.fitSamples > 65536)
        return bad_config("fitSamples", "is " + std::to_string(config.fitSamples) + ", not between 16 and 65536",
                          "the shipped table uses 768 samples of each density");
    if (config.albedoSamples < 16 || config.albedoSamples > (1 << 22))
        return bad_config("albedoSamples",
                          "is " + std::to_string(config.albedoSamples) + ", not between 16 and 4194304",
                          "the shipped table uses 8192");
    if (config.iterations < 1 || config.iterations > 100000)
        return bad_config("iterations", "is " + std::to_string(config.iterations) + ", not between 1 and 100000",
                          "the shipped table uses 220");

    const int n = config.size;
    const std::size_t cells = static_cast<std::size_t>(n) * static_cast<std::size_t>(n);  // checked: 256 x 256 at most
    std::vector<CellFit> fits(cells);
    auto at = [&](int i, int j) -> CellFit& {
        return fits[static_cast<std::size_t>(j) * static_cast<std::size_t>(n) + i];
    };

    // The first view cell of every roughness, from the roughest to the smoothest: the lobe of the cell above, narrowed in
    // proportion to alpha. The roughest cell starts from the identity (D = cos / pi).
    for (int i = n - 1; i >= 0; --i) {
        Params start{0.0, 0.0, 0.0, 0.0};
        if (i < n - 1) {
            start = at(i + 1, 0).params;
            const double a0 = roughness_at(i + 1, n);
            const double a1 = roughness_at(i, n);
            const double shift = 2.0 * det_log(a1 / a0);  // alpha = roughness^2
            start[1] += shift;
            start[3] += shift;
        }
        at(i, 0) = fit_cell(roughness_at(i, n), cos_theta_at(0, n), start, config);
    }
    // Every roughness walks along the view axis on its own: rows of the table are independent, so any number of threads
    // gives the same cells.
    auto rows = jobs::parallel_for("ltc.fit", static_cast<std::size_t>(n), 1, [&](const jobs::Chunk& chunk) {
        for (std::size_t row = chunk.begin; row < chunk.end; ++row) {
            const int i = static_cast<int>(row);
            for (int j = 1; j < n; ++j)
                at(i, j) = fit_cell(roughness_at(i, n), cos_theta_at(j, n), at(i, j - 1).params, config);
        }
    });
    if (!rows) return rows.error();

    Table table;
    table.size = n;
    table.matrix.resize(cells * 4);
    table.brdf.resize(cells * 2);
    table.error.resize(cells);
    for (std::size_t k = 0; k < cells; ++k) {
        const CellFit& c = fits[k];
        table.matrix[k * 4 + 0] = static_cast<float>(c.lobe.a);
        table.matrix[k * 4 + 1] = static_cast<float>(c.lobe.b);
        table.matrix[k * 4 + 2] = static_cast<float>(c.lobe.c);
        table.matrix[k * 4 + 3] = static_cast<float>(c.lobe.d);
        table.brdf[k * 2 + 0] = static_cast<float>(c.albedo.magnitude);
        table.brdf[k * 2 + 1] = static_cast<float>(c.albedo.fresnel);
        table.error[k] = static_cast<float>(c.error);
    }
    return table;
}

std::uint64_t table_hash(const float* matrix, const float* brdf, int size) {
    std::uint64_t h = 1469598103934665603ull;
    auto feed = [&](const float* data, std::size_t count) {
        for (std::size_t i = 0; i < count; ++i) {
            std::uint32_t bits = 0;
            std::memcpy(&bits, &data[i], sizeof bits);
            for (int b = 0; b < 4; ++b) {
                h ^= (bits >> (8 * b)) & 0xFFu;
                h *= 1099511628211ull;
            }
        }
    };
    const std::size_t cells = static_cast<std::size_t>(size) * static_cast<std::size_t>(size);
    feed(matrix, cells * 4);
    feed(brdf, cells * 2);
    return h;
}

std::uint64_t table_hash(const Table& table) { return table_hash(table.matrix.data(), table.brdf.data(), table.size); }

}  // namespace fa::ltc
