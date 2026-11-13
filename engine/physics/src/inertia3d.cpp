#include "inertia3d.h"

#include <algorithm>
#include <cmath>

namespace fa::detail {

Vec3 capsule_inertia(float m, float r, float segHalf) {
    const double R = r, H = 2.0 * double(segHalf), pi = 3.14159265358979323846;
    const double vCyl = pi * R * R * H, vHemis = 4.0 / 3.0 * pi * R * R * R;  // the two hemispheres together
    const double v = vCyl + vHemis;
    const double mCyl = double(m) * vCyl / v, mHemis = double(m) * vHemis / v;
    const double axial = mCyl * R * R * 0.5 + mHemis * 0.4 * R * R;
    // Each hemisphere's centre of mass is 3r/8 from its flat face, and the face is H/2 from the middle.
    const double transverse =
        mCyl * (R * R / 4.0 + H * H / 12.0) + mHemis * (0.4 * R * R + H * H / 4.0 + 3.0 * H * R / 8.0);
    return {float(transverse), float(axial), float(transverse)};
}

SolidMoments solid_moments(const std::vector<Vec3>& points, const std::vector<std::uint32_t>& indices) {
    SolidMoments s;
    for (std::size_t t = 0; t + 2 < indices.size(); t += 3) {
        const Vec3 a = points[indices[t]], b = points[indices[t + 1]], c = points[indices[t + 2]];
        const double ax = a.x, ay = a.y, az = a.z, bx = b.x, by = b.y, bz = b.z, cx = c.x, cy = c.y, cz = c.z;
        // Signed volume of the tetrahedron (origin, a, b, c): positive for a triangle seen counter-clockwise from outside.
        const double v = (ax * (by * cz - bz * cy) - ay * (bx * cz - bz * cx) + az * (bx * cy - by * cx)) / 6.0;
        // Integral of x_i^2 over a tetrahedron with a vertex at the origin: V/20 * (sum of squares + square of the sum).
        s.volume += v;
        s.xx += v / 20.0 * (ax * ax + bx * bx + cx * cx + (ax + bx + cx) * (ax + bx + cx));
        s.yy += v / 20.0 * (ay * ay + by * by + cy * cy + (ay + by + cy) * (ay + by + cy));
        s.zz += v / 20.0 * (az * az + bz * bz + cz * cz + (az + bz + cz) * (az + bz + cz));
    }
    return s;
}

bool hull_inertia(float mass, const ShapeData& data, Vec3 scale, Vec3& out) {
    if (!(data.hullMoments.volume > 1e-12)) return false;
    const SolidMoments& s = data.hullMoments;
    // Scaling by (sx, sy, sz) multiplies the volume and every integral of x_i^2 by sx*sy*sz, and x_i^2 by s_i^2 on top.
    const double sx = scale.x * scale.x, sy = scale.y * scale.y, sz = scale.z * scale.z;
    const double m = mass;
    out = {float(m * (s.yy * sy + s.zz * sz) / s.volume), float(m * (s.xx * sx + s.zz * sz) / s.volume),
           float(m * (s.xx * sx + s.yy * sy) / s.volume)};
    return true;
}

}  // namespace fa::detail
