// Tests of the LTC fit and of the CPU reference (docs/design/ARCHITECTURE_AREA_LIGHTS.md). The quick cases run in every build;
// the case marked (slow) fits the whole table again and runs as its own ctest entry, `ltc_tables_up_to_date`.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/jobs.h"
#include "fa/ltc/ltc.h"
#include "fa_test_paths.h"
#include "ltc_tables.h"

using namespace fa::ltc;

namespace {

constexpr double kPi = 3.14159265358979323846;

// The reduced fit of the determinism cases: 6 x 6 cells, a few samples.
TableConfig tiny_config() {
    TableConfig c;
    c.size = 6;
    c.fitSamples = 96;
    c.albedoSamples = 512;
    c.iterations = 40;
    return c;
}

Lookup committed(double roughness, double cosTheta) {
    return lookup_table(fa::ltc_tables::kMatrix, fa::ltc_tables::kBrdf, fa::ltc_tables::kSize, roughness, cosTheta);
}

double rounded(double v) { return std::round(v * 1000.0) / 1000.0; }

// A rectangle of half sizes hx, hy whose center lies `dist` away in the xz plane at `angle` from the normal (negative: on the
// side of the mirror direction of V = (sin, 0, cos)).
struct RectCase {
    double roughness, cosTheta, dist, angle, hx, hy;
};
void rect_of(const RectCase& rc, Vec3d& center, Vec3d& ex, Vec3d& ey) {
    const double s = std::sin(rc.angle), c = std::cos(rc.angle);
    center = Vec3d{s, 0.0, c} * rc.dist;
    ex = Vec3d{c, 0.0, -s} * rc.hx;
    ey = Vec3d{0.0, 1.0, 0.0} * rc.hy;
}

}  // namespace

TEST_CASE("ltc math: the library's own sin, cos, exp, log and atan2 agree with the C library") {
    double worst = 0;
    for (int i = -400; i <= 400; ++i) {
        const double x = static_cast<double>(i) * 0.0173;
        double s = 0, c = 0;
        det_sincos(x, s, c);
        worst = std::max({worst, std::fabs(s - std::sin(x)), std::fabs(c - std::cos(x))});
        worst = std::max(worst, std::fabs(det_exp(x * 4.0) / std::exp(x * 4.0) - 1.0));
        worst = std::max(worst, std::fabs(det_log(std::exp(x)) - x));
        const double y = std::sin(x), xx = std::cos(x) * 1.7;
        worst = std::max(worst, std::fabs(det_atan2(y, xx) - std::atan2(y, xx)));
    }
    CHECK(worst < 1e-13);
}

TEST_CASE("ltc brdf: the importance-sampled albedo matches an independent quadrature") {
    double worst = 0;
    for (double r : {0.05, 0.12, 0.3, 0.6, 1.0}) {
        for (double c : {0.06, 0.1, 0.4, 0.8, 1.0}) {
            const Albedo a = albedo_importance(r, c, 8192);
            const Albedo b = albedo_quadrature(r, c, 512);
            INFO("roughness " << r << " cos " << c << ": " << a.magnitude << " " << a.fresnel << " vs " << b.magnitude
                              << " " << b.fresnel);
            CHECK(a.magnitude == doctest::Approx(b.magnitude).epsilon(2e-3));
            CHECK(std::fabs(a.fresnel - b.fresnel) < 2e-3);
            worst = std::max(worst, std::fabs(a.magnitude - b.magnitude));
            CHECK(a.magnitude > 0.0);
            CHECK(a.magnitude < 1.0 + 1e-3);
        }
    }
    MESSAGE("largest difference of the magnitude: " << worst);
}

TEST_CASE("ltc fit: the same bits with no pool, with 3 workers and on a second run") {
    const TableConfig config = tiny_config();
    std::uint64_t inlineHash = 0, threadsHash = 0, again = 0;
    {
        auto t = fit_table(config);  // no pool: every chunk runs on this thread
        REQUIRE(t.ok());
        inlineHash = table_hash(t.value());
        CHECK(write_header(t.value(), config).find('\r') == std::string::npos);
    }
    REQUIRE(fa::jobs::start(fa::jobs::Settings::threads(3)).ok());
    {
        auto t = fit_table(config);
        REQUIRE(t.ok());
        threadsHash = table_hash(t.value());
        auto u = fit_table(config);
        REQUIRE(u.ok());
        again = table_hash(u.value());
    }
    fa::jobs::stop();
    CHECK(inlineHash == threadsHash);
    CHECK(threadsHash == again);
    CHECK(inlineHash != 0);
}

TEST_CASE("ltc fit: a size or a sample count out of range is refused with a hint") {
    TableConfig c = tiny_config();
    c.size = 1;
    auto bad = fit_table(c);
    REQUIRE_FALSE(bad.ok());
    CHECK_FALSE(bad.error().message.empty());
    CHECK_FALSE(bad.error().hint.empty());
    c = tiny_config();
    c.fitSamples = 1 << 28;
    CHECK_FALSE(fit_table(c).ok());
}

TEST_CASE("ltc table: the committed header is intact, finite and smooth") {
    namespace t = fa::ltc_tables;
    const int n = t::kSize;
    REQUIRE(n == kTableSize);
    // Hand edits are caught here without the slow fit: the hash is the one the generator wrote.
    CHECK(table_hash(t::kMatrix, t::kBrdf, n) == t::kHash);
    CHECK(static_cast<double>(t::kMinRoughness) == doctest::Approx(kMinRoughness));
    CHECK(static_cast<double>(t::kMinCosTheta) == doctest::Approx(kMinCosTheta));
    double worstMatrix = 0, worstGrazing = 0, worstBrdf = 0, worstBrdfGrazing = 0;
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i < n; ++i) {
            const std::size_t k = static_cast<std::size_t>(j) * n + i;
            for (int e = 0; e < 4; ++e) REQUIRE(std::isfinite(t::kMatrix[k * 4 + e]));
            for (int e = 0; e < 2; ++e) REQUIRE(std::isfinite(t::kBrdf[k * 2 + e]));
            const double a = t::kMatrix[k * 4], b = t::kMatrix[k * 4 + 1], c = t::kMatrix[k * 4 + 2],
                         d = t::kMatrix[k * 4 + 3];
            REQUIRE(a * d - b * c > 0.0);  // an orientation preserving matrix: the lobe is a lobe
            CHECK(t::kBrdf[k * 2] > 0.0f);
            CHECK(t::kBrdf[k * 2] <= 1.0f + 1e-3f);
            CHECK(t::kBrdf[k * 2 + 1] >= 0.0f);
            CHECK(t::kBrdf[k * 2 + 1] <= t::kBrdf[k * 2] + 1e-4f);  // (1 - V.H)^5 <= 1
            // Neighbours (to the right: rougher, below: more upright) are close: the matrix entries relative to their sizes,
            // the magnitudes in absolute terms.
            for (int dir = 0; dir < 2; ++dir) {
                const int i2 = i + (dir == 0 ? 1 : 0), j2 = j + (dir == 1 ? 1 : 0);
                if (i2 >= n || j2 >= n) continue;
                const std::size_t k2 = static_cast<std::size_t>(j2) * n + i2;
                double diff = 0, size = 0;
                for (int e = 0; e < 4; ++e) {
                    diff += std::fabs(t::kMatrix[k * 4 + e] - t::kMatrix[k2 * 4 + e]);
                    size += std::fabs(t::kMatrix[k * 4 + e]) + std::fabs(t::kMatrix[k2 * 4 + e]);
                }
                if (cos_theta_at(j2, n) >= 0.2)
                    worstMatrix = std::max(worstMatrix, diff / size);
                else
                    worstGrazing = std::max(worstGrazing, diff / size);
                double& worstOf = cos_theta_at(j2, n) >= 0.2 ? worstBrdf : worstBrdfGrazing;
                worstOf = std::max(worstOf, static_cast<double>(std::fabs(t::kBrdf[k * 2] - t::kBrdf[k2 * 2])));
                worstOf = std::max(worstOf, static_cast<double>(std::fabs(t::kBrdf[k * 2 + 1] - t::kBrdf[k2 * 2 + 1])));
            }
        }
    }
    MESSAGE("largest relative step of the matrix between neighbours: "
            << rounded(worstMatrix) << " (grazing cells, cos < 0.2: " << rounded(worstGrazing)
            << "), of the magnitudes: " << rounded(worstBrdf) << " (grazing " << rounded(worstBrdfGrazing) << ")");
    CHECK(worstMatrix < 0.15);
    CHECK(worstBrdf < 0.1);
    // The last rows (cos < 0.2) change fast in the BRDF itself (the horizon cuts its lobe) and the fit is least exact there.
    CHECK(worstGrazing < 0.95);
    CHECK(worstBrdfGrazing < 0.3);
}

TEST_CASE("ltc table: magnitude and fresnel match an independent quadrature of the BRDF") {
    namespace t = fa::ltc_tables;
    double worst = 0;
    // Not the last rows (cos < 0.05): the grid of the quadrature is too coarse for the grazing lobe there, the importance sampler
    // the table comes from is not.
    for (int j : {0, 10, 25, 40, 50, 55}) {
        for (int i : {0, 7, 20, 33, 50, 63}) {
            const double r = roughness_at(i, t::kSize), c = cos_theta_at(j, t::kSize);
            const Albedo q = albedo_quadrature(r, c, 640);
            const std::size_t k = static_cast<std::size_t>(j) * t::kSize + i;
            INFO("roughness " << r << " cos " << c);
            CHECK(std::fabs(t::kBrdf[k * 2] - q.magnitude) < 2e-3);
            CHECK(std::fabs(t::kBrdf[k * 2 + 1] - q.fresnel) < 2e-3);
            worst = std::max(worst, std::fabs(t::kBrdf[k * 2] - q.magnitude));
        }
    }
    MESSAGE("largest difference of the magnitude: " << worst);
}

TEST_CASE("ltc table: the lobes follow the BRDF lobes, the hemisphere keeps the albedo") {
    namespace t = fa::ltc_tables;
    // L1 distance of the lobe to the BRDF lobe (0 identical, 2 disjoint) at cells away from grazing, where the fit is good, and
    // the share of the lobe over the horizon: magnitude * share is the albedo the lobe gives over the hemisphere.
    struct Case {
        int i, j;
        double maxError;
    };
    const Case cases[] = {{0, 0, 0.01},  {0, 30, 0.01}, {10, 20, 0.02}, {25, 10, 0.04}, {25, 35, 0.14},
                          {40, 40, 0.2}, {63, 5, 0.07}, {63, 30, 0.08}, {50, 50, 0.2}};
    for (const Case& cs : cases) {
        const double r = roughness_at(cs.i, t::kSize), c = cos_theta_at(cs.j, t::kSize);
        const Lookup cell = committed(r, c);
        const double err = lobe_error(r, c, cell.lobe, 4096);
        INFO("roughness " << r << " cos " << c << " error " << err);
        MESSAGE("cell " << cs.i << "," << cs.j << " cos " << rounded(c) << ": L1 error " << rounded(err));
        CHECK(err < cs.maxError);
        int above = 0;
        const int samples = 4096;
        for (int s = 0; s < samples; ++s) {
            const double u1 = (s + 0.5) / samples;
            const double u2 = std::fmod(s * 0.61803398875, 1.0);
            double sn = 0, cs2 = 0;
            det_sincos(2.0 * kPi * u2, sn, cs2);
            const double rr = std::sqrt(u1);
            const Vec3d w = lobe_sample(cell.lobe, {rr * cs2, rr * sn, std::sqrt(1.0 - u1)});
            if (w.z > 0.0) ++above;
        }
        const double share = static_cast<double>(above) / samples;
        const Albedo q = albedo_quadrature(r, c, 512);
        MESSAGE("  albedo " << rounded(q.magnitude) << " lobe " << rounded(cell.magnitude * share));
        CHECK(cell.magnitude * share == doctest::Approx(q.magnitude).epsilon(0.03));
    }
}

TEST_CASE("ltc polygon: the polynomial edge integral stays close to the exact one, and the winding sets the sign") {
    const Lobe lobes[] = {{1, 0, 0, 1}, {2.5, 0.3, -0.4, 1.8}, {0.4, -0.2, 0.7, 0.9}};
    const Vec3d quad[4] = {{-0.8, -0.5, 1.2}, {0.9, -0.6, 1.0}, {1.0, 0.7, 1.4}, {-0.7, 0.9, 1.1}};
    const Vec3d reversed[4] = {quad[3], quad[2], quad[1], quad[0]};
    for (const Lobe& l : lobes) {
        const double fast = polygon_integral(l, quad, 4);
        const double exact = polygon_integral_exact(l, quad, 4);
        INFO("lobe " << l.a << " " << l.b << " " << l.c << " " << l.d);
        CHECK(std::fabs(fast - exact) < 2e-5);
        CHECK(std::fabs(fast) > 1e-3);
        CHECK(polygon_integral(l, reversed, 4) == doctest::Approx(-fast));
    }
}

TEST_CASE("ltc polygon: with the identity lobe it is the cosine form factor, also across the horizon") {
    // D = cos / pi: the integral over a polygon is the integral of cos(w)/pi over the part of its solid angle above the horizon,
    // here by a grid over the polygon.
    auto brute = [](const Vec3d& center, const Vec3d& ex, const Vec3d& ey) {
        const int grid = 500;
        const Vec3d nl = cross(ex, ey);
        const double cell = 4.0 * length(nl) / (grid * grid);
        const Vec3d unit = normalize(nl);
        double sum = 0;
        for (int iy = 0; iy < grid; ++iy)
            for (int ix = 0; ix < grid; ++ix) {
                const double u = 2.0 * (ix + 0.5) / grid - 1.0, v = 2.0 * (iy + 0.5) / grid - 1.0;
                const Vec3d p = center + ex * u + ey * v;
                const double d2 = dot(p, p);
                const Vec3d dir = p * (1.0 / std::sqrt(d2));
                if (dir.z > 0.0) sum += dir.z / kPi * std::fabs(dot(unit, dir)) * cell / d2;
            }
        return sum;
    };
    struct Case {
        Vec3d center, ex, ey;
    };
    const Case cases[] = {
        {{0, 0, 2}, {1, 0, 0}, {0, 1, 0}},              // above, inside the hemisphere
        {{0.5, 0.2, 1.0}, {0.7, 0, 0.1}, {0, 0.6, 0}},  // tilted
        {{0, 0, 0.3}, {0.6, 0, -0.6}, {0, 1.0, 0}},     // a plane through the point's horizon: part of it is below
        {{1.5, 0, 0.2}, {0, 0, 1.0}, {0, 1.0, 0}},      // a wall that crosses the horizon
    };
    const Lobe identity;
    for (const Case& cs : cases) {
        const Vec3d pts[4] = {cs.center - cs.ex - cs.ey, cs.center + cs.ex - cs.ey, cs.center + cs.ex + cs.ey,
                              cs.center - cs.ex + cs.ey};
        const double expected = brute(cs.center, cs.ex, cs.ey);
        const double got = std::fabs(polygon_integral_exact(identity, pts, 4));
        INFO("center " << cs.center.x << " " << cs.center.y << " " << cs.center.z << ": brute " << expected << " exact "
                       << got);
        CHECK(std::fabs(got - expected) < 4e-3);
        CHECK(std::fabs(std::fabs(polygon_integral(identity, pts, 4)) - got) < 2e-5);
    }
}

TEST_CASE("ltc area light: the LTC integral of a rectangle matches the brute force integral of the BRDF") {
    const RectCase cases[] = {
        {0.30, 0.95, 2.0, -0.30, 0.8, 0.8}, {0.30, 0.95, 2.0, 0.60, 0.8, 0.8},  {0.55, 0.80, 2.5, -0.70, 1.0, 0.7},
        {0.55, 0.50, 2.0, -0.90, 0.9, 1.0}, {0.80, 0.30, 3.0, -0.50, 1.2, 1.2}, {0.80, 0.90, 1.5, 0.30, 1.0, 0.6},
        {1.00, 0.70, 2.0, 0.00, 1.0, 1.0},  {0.20, 0.85, 2.2, -0.55, 0.7, 0.7}, {0.12, 0.90, 3.0, -0.45, 0.9, 0.5},
    };
    double worstRel = 0;
    for (const RectCase& rc : cases) {
        Vec3d center, ex, ey;
        rect_of(rc, center, ex, ey);
        const double brute = rect_brdf_integral(rc.roughness, rc.cosTheta, center, ex, ey, 300);
        const double ltc = rect_ltc_integral(committed(rc.roughness, rc.cosTheta), center, ex, ey);
        const double rel = std::fabs(ltc - brute) / std::max(brute, 0.02);
        worstRel = std::max(worstRel, rel);
        MESSAGE("roughness " << rc.roughness << " cos " << rc.cosTheta << " dist " << rc.dist << " angle " << rc.angle
                             << ": brute " << rounded(brute) << " ltc " << rounded(ltc));
        CHECK(rel < 0.06);
    }
    MESSAGE("largest relative error of the LTC rectangle integral: " << rounded(worstRel));
}

TEST_CASE("ltc generated header (slow): the committed engine/render/src/ltc_tables.h is what the tool produces") {
    const TableConfig config;  // the defaults are what the tool uses
    REQUIRE(fa::jobs::start(fa::jobs::Settings::automatic()).ok());
    auto table = fit_table(config);
    fa::jobs::stop();
    REQUIRE(table.ok());
    const std::string produced = write_header(table.value(), config);
    auto committedText = fa::fs::read_text(std::string(FA_REPO_ROOT) + "/engine/render/src/ltc_tables.h");
    REQUIRE(committedText.ok());
    std::string have = committedText.value();
    have.erase(std::remove(have.begin(), have.end(), '\r'), have.end());  // a checkout on Windows may have CRLF
    // Compared into a bool: a failing CHECK(have == produced) would print both texts (2 x 370 KB). Say where the first difference is.
    const bool same = have == produced;
    std::size_t at = 0;
    while (!same && at < have.size() && at < produced.size() && have[at] == produced[at]) ++at;
    const std::size_t line =
        std::size_t(std::count(have.begin(), have.begin() + std::ptrdiff_t(std::min(at, have.size())), '\n')) + 1;
    CHECK_MESSAGE(same,
                  "run tools/ltc/generate_ltc.sh and commit engine/render/src/ltc_tables.h (first difference at line "
                      << line << ", table hash now " << table_hash(table.value()) << ")");
    CHECK(table_hash(table.value()) == fa::ltc_tables::kHash);
}
