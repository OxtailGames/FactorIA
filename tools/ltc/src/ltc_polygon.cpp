// The integral of a lobe over a polygon (closed form after M^-1), and the brute-force integral of the BRDF over a rectangle that
// the tests compare it with. fa_ltc_quad in engine/render/shaders/ltc.glsl is the same algorithm.
#include <algorithm>
#include <cmath>

#include "fa/ltc/ltc.h"
#include "ltc_internal.h"

namespace fa::ltc {
namespace {

using detail::kPi;

// acos(y) / sqrt(1 - y^2) for y in [0, 1] (1 at y = 1, pi/2 at 0): a degree-6 polynomial, 5e-6 from the function. The
// coefficients are a Chebyshev interpolation of that function made for this file (tools/ltc, see the architecture page).
double edge_factor_poly(double y) {
    constexpr double c[7] = {1.5707917009694146, -0.9995423990187176, 0.7777224167319281, -0.6160572217483093,
                             0.4179156120778016, -0.1924748645577205, 0.04164716762962988};
    double r = c[6];
    for (int i = 5; i >= 0; --i) r = r * y + c[i];
    return r;
}

double edge_factor_exact(double y) {
    const double s2 = 1.0 - y * y;
    if (s2 < 1e-12) return 1.0;
    return std::acos(std::min(y, 1.0)) / std::sqrt(s2);
}

// The integral over the arc of the great circle from a to b of the vector the form factor is made of: cross(a, b) theta /
// sin(theta), for the unit vectors of a and b. Its z is what the sum adds up.
Vec3d edge_vector(Vec3d a, Vec3d b, bool exact) {
    const double la = length(a);
    const double lb = length(b);
    if (!(la > 1e-12) || !(lb > 1e-12)) return {};
    const Vec3d na = a * (1.0 / la);
    const Vec3d nb = b * (1.0 / lb);
    const double x = dot(na, nb);
    const double y = std::fabs(x);
    double g = exact ? edge_factor_exact(y) : edge_factor_poly(y);
    if (x < 0.0) g = kPi / std::sqrt(std::max(1.0 - x * x, 1e-7)) - g;  // acos(-y) = pi - acos(y)
    return cross(na, nb) * g;
}

double integral(const Lobe& lobe, const Vec3d* points, int count, bool exact) {
    if (count < 3 || count > 16) return 0.0;
    Vec3d q[16];
    for (int i = 0; i < count; ++i) {
        const Vec3d& p = points[i];
        q[i] = {lobe.a * p.x + lobe.b * p.z, p.y, lobe.c * p.x + lobe.d * p.z};
    }
    // The part above the horizon of the transformed polygon (convex: it leaves and comes back once), edge by edge: the arcs
    // that are above, and the one along the horizon between where it left and where it came back.
    Vec3d sum;
    Vec3d leave, enter;
    bool left = false, entered = false;
    for (int i = 0; i < count; ++i) {
        const Vec3d a = q[i];
        const Vec3d b = q[(i + 1) % count];
        const bool inA = a.z > 0.0;
        const bool inB = b.z > 0.0;
        if (inA && inB) {
            sum = sum + edge_vector(a, b, exact);
        } else if (inA != inB) {
            const double t = a.z / (a.z - b.z);
            Vec3d c = a + (b - a) * t;
            c.z = 0.0;
            if (inA) {
                sum = sum + edge_vector(a, c, exact);
                leave = c;
                left = true;
            } else {
                sum = sum + edge_vector(c, b, exact);
                enter = c;
                entered = true;
            }
        }
    }
    if (left && entered) sum = sum + edge_vector(leave, enter, exact);
    return sum.z / (2.0 * kPi);
}

}  // namespace

double polygon_integral(const Lobe& lobe, const Vec3d* points, int count) {
    return integral(lobe, points, count, false);
}
double polygon_integral_exact(const Lobe& lobe, const Vec3d* points, int count) {
    return integral(lobe, points, count, true);
}

double rect_brdf_integral(double roughness, double cosTheta, Vec3d center, Vec3d ex, Vec3d ey, int grid) {
    const detail::BrdfCtx ctx = detail::make_brdf(roughness, cosTheta);
    const Vec3d nl = cross(ex, ey);
    const double area = 4.0 * length(nl);
    const Vec3d unit = normalize(nl);
    const double cell = area / (static_cast<double>(grid) * static_cast<double>(grid));
    double sum = 0.0;
    for (int iy = 0; iy < grid; ++iy) {
        const double v = 2.0 * (static_cast<double>(iy) + 0.5) / static_cast<double>(grid) - 1.0;
        for (int ix = 0; ix < grid; ++ix) {
            const double u = 2.0 * (static_cast<double>(ix) + 0.5) / static_cast<double>(grid) - 1.0;
            const Vec3d p = center + ex * u + ey * v;
            const double dist2 = dot(p, p);
            const Vec3d dir = p * (1.0 / std::sqrt(dist2));
            const double solid = std::fabs(dot(unit, dir)) * cell / dist2;  // lit on both sides
            sum += detail::brdf_fcos(ctx, dir) * solid;
        }
    }
    return sum;
}

double rect_ltc_integral(const Lookup& cell, Vec3d center, Vec3d ex, Vec3d ey) {
    const Vec3d pts[4] = {center - ex - ey, center + ex - ey, center + ex + ey, center - ex + ey};
    return cell.magnitude * std::fabs(polygon_integral(cell.lobe, pts, 4));
}

}  // namespace fa::ltc
