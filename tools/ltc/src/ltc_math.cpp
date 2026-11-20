// Vectors, the library's own sin/cos/exp/log, the table axes, the lobe's density and the bilinear lookup.
#include <algorithm>
#include <cmath>

#include "fa/ltc/ltc.h"
#include "ltc_internal.h"

namespace fa::ltc {

using detail::kPi;

double length(Vec3d a) { return std::sqrt(dot(a, a)); }
Vec3d normalize(Vec3d a) { return a * (1.0 / length(a)); }

// ---------------------------------------------------------------------------------------------------------------- math
void det_sincos(double x, double& s, double& c) {
    // Quadrant and remainder in [-pi/4, pi/4]; the angles of the fit are small, so one rounding constant is enough.
    const double q = std::floor(x * (2.0 / kPi) + 0.5);
    const double r = x - q * (kPi / 2.0);
    const double r2 = r * r;
    double sn = 1.0;
    double cn = 1.0;
    for (int k = 9; k >= 1; --k) {
        sn = 1.0 - sn * r2 / static_cast<double>((2 * k) * (2 * k + 1));
        cn = 1.0 - cn * r2 / static_cast<double>((2 * k - 1) * (2 * k));
    }
    const double sr = r * sn;
    const int quadrant = static_cast<int>(std::fmod(q, 4.0) + 4.0) & 3;  // q is an integer valued double: exact
    switch (quadrant) {
        case 0:
            s = sr;
            c = cn;
            break;
        case 1:
            s = cn;
            c = -sr;
            break;
        case 2:
            s = -sr;
            c = -cn;
            break;
        default:
            s = -cn;
            c = sr;
            break;
    }
}

double det_exp(double x) {
    constexpr double kLn2 = 0.69314718055994530942;
    const double k = std::floor(x / kLn2 + 0.5);
    const double r = x - k * kLn2;
    double e = 1.0;
    for (int n = 17; n >= 1; --n) e = 1.0 + e * r / static_cast<double>(n);
    return std::ldexp(e, static_cast<int>(k));
}

double det_log(double x) {
    constexpr double kLn2 = 0.69314718055994530942;
    int e = 0;
    double m = std::frexp(x, &e);  // m in [0.5, 1)
    if (m < 0.70710678118654752440) {
        m *= 2.0;
        --e;
    }
    const double s = (m - 1.0) / (m + 1.0);
    const double s2 = s * s;
    double t = 0.0;
    for (int k = 14; k >= 0; --k) t = t * s2 + 1.0 / static_cast<double>(2 * k + 1);
    return static_cast<double>(e) * kLn2 + 2.0 * s * t;
}

double det_atan2(double y, double x) {
    const double ax = std::fabs(x);
    const double ay = std::fabs(y);
    if (ax == 0.0 && ay == 0.0) return 0.0;
    // atan of t in [0, 1], then the octant back. Two halvings, atan(t) = 2 atan(t / (1 + sqrt(1 + t^2))), bring t under 0.2.
    const bool swap = ay > ax;
    double t = swap ? ax / ay : ay / ax;
    t = t / (1.0 + std::sqrt(1.0 + t * t));
    t = t / (1.0 + std::sqrt(1.0 + t * t));
    const double t2 = t * t;
    double series = 0.0;
    for (int k = 11; k >= 0; --k) series = (k % 2 == 0 ? 1.0 : -1.0) / static_cast<double>(2 * k + 1) + t2 * series;
    double angle = 4.0 * t * series;
    if (swap) angle = kPi / 2.0 - angle;
    if (x < 0.0) angle = kPi - angle;
    return y < 0.0 ? -angle : angle;
}

// ---------------------------------------------------------------------------------------------------------------- axes
double roughness_at(int i, int size) {
    return kMinRoughness + (1.0 - kMinRoughness) * (static_cast<double>(i) / static_cast<double>(size - 1));
}

double cos_theta_at(int j, int size) {
    const double t = static_cast<double>(j) / static_cast<double>(size - 1);
    return std::max(1.0 - t * t, kMinCosTheta);
}

// ---------------------------------------------------------------------------------------------------------------- lobe
double lobe_density(const Lobe& lobe, Vec3d w) {
    const Vec3d v{lobe.a * w.x + lobe.b * w.z, w.y, lobe.c * w.x + lobe.d * w.z};
    const double det = lobe.a * lobe.d - lobe.b * lobe.c;
    if (!(v.z > 0.0) || !(det > 0.0)) return 0.0;
    const double l2 = dot(v, v);
    return det * v.z / (kPi * l2 * l2);
}

Vec3d lobe_sample(const Lobe& lobe, Vec3d wo) {
    const double det = lobe.a * lobe.d - lobe.b * lobe.c;
    return normalize({lobe.d * wo.x - lobe.b * wo.z, det * wo.y, -lobe.c * wo.x + lobe.a * wo.z});
}

// ---------------------------------------------------------------------------------------------------------------- lookup
Lookup lookup_table(const float* matrix, const float* brdf, int size, double roughness, double cosTheta) {
    const double top = static_cast<double>(size - 1);
    const double u = std::clamp((roughness - kMinRoughness) / (1.0 - kMinRoughness), 0.0, 1.0) * top;
    const double v = std::sqrt(std::clamp(1.0 - cosTheta, 0.0, 1.0)) * top;
    const int i0 = std::min(static_cast<int>(u), size - 2);
    const int j0 = std::min(static_cast<int>(v), size - 2);
    const double fu = u - static_cast<double>(i0);
    const double fv = v - static_cast<double>(j0);
    auto mix = [&](const float* data, int stride, int k) {
        auto at = [&](int i, int j) {
            return static_cast<double>(data[(static_cast<std::size_t>(j) * size + i) * stride + k]);
        };
        const double lo = at(i0, j0) * (1.0 - fu) + at(i0 + 1, j0) * fu;
        const double hi = at(i0, j0 + 1) * (1.0 - fu) + at(i0 + 1, j0 + 1) * fu;
        return lo * (1.0 - fv) + hi * fv;
    };
    Lookup out;
    out.lobe = {mix(matrix, 4, 0), mix(matrix, 4, 1), mix(matrix, 4, 2), mix(matrix, 4, 3)};
    out.magnitude = mix(brdf, 2, 0);
    out.fresnel = mix(brdf, 2, 1);
    return out;
}

}  // namespace fa::ltc
