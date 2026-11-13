// The signed-distance field of model documents: shapes, their combination, the bounding box and the noise. Meshing is model_sdf_mesh.cpp.
#include <algorithm>
#include <cmath>

#include "fa/scene/model_modifiers.h"
#include "fa/scene/model_sdf.h"

namespace fa {

namespace {

Vec3 apply(const float* m, Vec3 p) {
    return {m[0] * p.x + m[1] * p.y + m[2] * p.z + m[3], m[4] * p.x + m[5] * p.y + m[6] * p.z + m[7],
            m[8] * p.x + m[9] * p.y + m[10] * p.z + m[11]};
}

void affine_of(const Mat4& m, float* out) {
    for (int row = 0; row < 3; ++row)
        for (int col = 0; col < 4; ++col) out[row * 4 + col] = m.at(col, row);
}

// d(smooth min) with the share of A: 1 when A alone decides, 0 when B alone does.
struct Mix {
    float d, t;
};
Mix smooth_min(float a, float b, float k) {
    if (k <= 1.0e-9f) return a <= b ? Mix{a, 1.0f} : Mix{b, 0.0f};
    const float t = clamp(0.5f + 0.5f * (b - a) / k, 0.0f, 1.0f);
    return {b + (a - b) * t - k * t * (1.0f - t), t};
}

// Joins `shape` to `acc`. The returned share is the one of `acc`.
Mix combine(float acc, float shape, ModelSdfBlend mode, float k) {
    switch (mode) {
        case ModelSdfBlend::Union: return smooth_min(acc, shape, k);
        case ModelSdfBlend::Intersect: {
            const Mix m = smooth_min(-acc, -shape, k);
            return {-m.d, m.t};
        }
        case ModelSdfBlend::Subtract: {
            const Mix m = smooth_min(-acc, shape, k);
            return {-m.d, m.t};
        }
    }
    return {acc, 1.0f};
}

float length2(float a, float b) { return std::sqrt(a * a + b * b); }

float shape_distance(const ModelSdfShapeParams& s, float capsuleLen, Vec3 p) {
    switch (s.shape) {
        case ModelSdfShape::Sphere: return length(p) - s.radius;
        case ModelSdfShape::Capsule: {
            const float r1 = s.radius, r2 = s.radiusTop < 0 ? s.radius : s.radiusTop, h = capsuleLen;
            if (h < 1.0e-6f) return length(p) - std::max(r1, r2);
            const float b = clamp((r1 - r2) / h, -1.0f, 1.0f);
            const float a = std::sqrt(std::max(0.0f, 1.0f - b * b));
            const float qx = length2(p.x, p.z), qy = p.y + h * 0.5f;  // the bottom ball's centre at y = 0
            const float k = -b * qx + a * qy;
            if (k < 0) return length2(qx, qy) - r1;
            if (k > a * h) return length2(qx, qy - h) - r2;
            return a * qx + b * qy - r1;
        }
        case ModelSdfShape::Ellipsoid: {
            const Vec3 r = s.size;
            const float k0 = length(Vec3{p.x / r.x, p.y / r.y, p.z / r.z});
            const float k1 = length(Vec3{p.x / (r.x * r.x), p.y / (r.y * r.y), p.z / (r.z * r.z)});
            if (k1 < 1.0e-12f) return -std::min(r.x, std::min(r.y, r.z));
            return k0 * (k0 - 1.0f) / k1;
        }
        case ModelSdfShape::Box: {
            const float rd = s.round;
            const float qx = std::fabs(p.x) - s.size.x * 0.5f + rd, qy = std::fabs(p.y) - s.size.y * 0.5f + rd,
                        qz = std::fabs(p.z) - s.size.z * 0.5f + rd;
            const float outside =
                std::sqrt(std::max(qx, 0.0f) * std::max(qx, 0.0f) + std::max(qy, 0.0f) * std::max(qy, 0.0f) +
                          std::max(qz, 0.0f) * std::max(qz, 0.0f));
            return outside + std::min(std::max(qx, std::max(qy, qz)), 0.0f) - rd;
        }
        case ModelSdfShape::Cylinder: {
            const float rd = s.round;
            const float dx = length2(p.x, p.z) - (s.radius - rd), dy = std::fabs(p.y) - (s.height * 0.5f - rd);
            return std::min(std::max(dx, dy), 0.0f) + length2(std::max(dx, 0.0f), std::max(dy, 0.0f)) - rd;
        }
        case ModelSdfShape::Cone: {
            const float h = s.height * 0.5f, r1 = s.radius, r2 = s.radiusTop < 0 ? 0.0f : s.radiusTop;
            const float qx = length2(p.x, p.z), qy = p.y;
            const float k1x = r2, k1y = h, k2x = r2 - r1, k2y = 2.0f * h;
            const float cax = qx - std::min(qx, qy < 0 ? r1 : r2), cay = std::fabs(qy) - h;
            const float t = clamp(((k1x - qx) * k2x + (k1y - qy) * k2y) / (k2x * k2x + k2y * k2y), 0.0f, 1.0f);
            const float cbx = qx - k1x + k2x * t, cby = qy - k1y + k2y * t;
            const float sgn = (cbx < 0 && cay < 0) ? -1.0f : 1.0f;
            return sgn * std::sqrt(std::min(cax * cax + cay * cay, cbx * cbx + cby * cby));
        }
        case ModelSdfShape::Torus: return length2(length2(p.x, p.z) - s.radius, p.y) - s.tube;
        case ModelSdfShape::Volume: return s.volume ? s.volume->sample(p) : 1.0e30f;
    }
    return 0;
}

// The shape's own box, centred as the shape is.
void shape_box(const ModelSdfShapeParams& s, float capsuleLen, Vec3& lo, Vec3& hi) {
    switch (s.shape) {
        case ModelSdfShape::Sphere:
            lo = {-s.radius, -s.radius, -s.radius};
            hi = {s.radius, s.radius, s.radius};
            break;
        case ModelSdfShape::Capsule: {
            const float r1 = s.radius, r2 = s.radiusTop < 0 ? s.radius : s.radiusTop, rm = std::max(r1, r2);
            lo = {-rm, -capsuleLen * 0.5f - r1, -rm};
            hi = {rm, capsuleLen * 0.5f + r2, rm};
            break;
        }
        case ModelSdfShape::Ellipsoid:
            lo = s.size * -1.0f;
            hi = s.size;
            break;
        case ModelSdfShape::Box:
            lo = s.size * -0.5f;
            hi = s.size * 0.5f;
            break;
        case ModelSdfShape::Cylinder:
            lo = {-s.radius, -s.height * 0.5f, -s.radius};
            hi = {s.radius, s.height * 0.5f, s.radius};
            break;
        case ModelSdfShape::Cone: {
            const float rm = std::max(s.radius, s.radiusTop < 0 ? 0.0f : s.radiusTop);
            lo = {-rm, -s.height * 0.5f, -rm};
            hi = {rm, s.height * 0.5f, rm};
            break;
        }
        case ModelSdfShape::Torus: {
            const float r = s.radius + s.tube;
            lo = {-r, -s.tube, -r};
            hi = {r, s.tube, r};
            break;
        }
        case ModelSdfShape::Volume:
            if (s.volume) {
                lo = s.volume->origin;
                hi = lo +
                     Vec3{float(s.volume->nx - 1), float(s.volume->ny - 1), float(s.volume->nz - 1)} * s.volume->cell;
            }
            break;
    }
}

void box_through(const float* m, Vec3 lo, Vec3 hi, Vec3& outLo, Vec3& outHi) {
    for (int c = 0; c < 8; ++c) {
        const Vec3 q = apply(m, {c & 1 ? hi.x : lo.x, c & 2 ? hi.y : lo.y, c & 4 ? hi.z : lo.z});
        if (c == 0) outLo = outHi = q;
        outLo = {std::min(outLo.x, q.x), std::min(outLo.y, q.y), std::min(outLo.z, q.z)};
        outHi = {std::max(outHi.x, q.x), std::max(outHi.y, q.y), std::max(outHi.z, q.z)};
    }
}

Vec4 mix4(Vec4 a, Vec4 b, float tA) { return a * tA + b * (1.0f - tA); }

}  // namespace

float ModelSdfVolume::sample(Vec3 p) const {
    if (nx < 2 || ny < 2 || nz < 2 || values.size() != std::size_t(nx) * std::size_t(ny) * std::size_t(nz))
        return 1.0e30f;
    const float inv = 1.0f / cell;
    const Vec3 g = (p - origin) * inv;
    const Vec3 c{clamp(g.x, 0.0f, float(nx - 1)), clamp(g.y, 0.0f, float(ny - 1)), clamp(g.z, 0.0f, float(nz - 1))};
    const float outside = length(g - c) * cell;
    const int x0 = std::min(int(c.x), nx - 2), y0 = std::min(int(c.y), ny - 2), z0 = std::min(int(c.z), nz - 2);
    const float fx = c.x - float(x0), fy = c.y - float(y0), fz = c.z - float(z0);
    auto at = [&](int x, int y, int z) {
        return values[std::size_t(x) + std::size_t(nx) * (std::size_t(y) + std::size_t(ny) * std::size_t(z))];
    };
    const float c00 = at(x0, y0, z0) * (1 - fx) + at(x0 + 1, y0, z0) * fx,
                c10 = at(x0, y0 + 1, z0) * (1 - fx) + at(x0 + 1, y0 + 1, z0) * fx;
    const float c01 = at(x0, y0, z0 + 1) * (1 - fx) + at(x0 + 1, y0, z0 + 1) * fx,
                c11 = at(x0, y0 + 1, z0 + 1) * (1 - fx) + at(x0 + 1, y0 + 1, z0 + 1) * fx;
    const float c0 = c00 * (1 - fy) + c10 * fy, c1 = c01 * (1 - fy) + c11 * fy;
    return c0 * (1 - fz) + c1 * fz + outside;
}

int ModelSdf::add_node(Node n, const Mat4& local) {
    affine_of(local, n.fwd);
    affine_of(local.inverse(), n.inv);
    float s = 1e30f;
    for (int c = 0; c < 3; ++c) s = std::min(s, length(Vec3{local.at(c, 0), local.at(c, 1), local.at(c, 2)}));
    n.distScale = s;
    nodes_.push_back(std::move(n));
    return int(nodes_.size()) - 1;
}

int ModelSdf::add_shape(const ModelSdfShapeParams& shape, const Mat4& local, ModelSdfBlend blend, float smooth,
                        std::uint32_t group, std::optional<Vec4> color) {
    Node n;
    n.leaf = true;
    n.shape = shape;
    n.blend = blend;
    n.smooth = smooth;
    n.group = group;
    if (color) {
        n.color = *color;
        hasColor_ = true;
    }
    if (shape.shape == ModelSdfShape::Capsule) {
        const float r2 = shape.radiusTop < 0 ? shape.radius : shape.radiusTop;
        n.capsuleLen = std::max(0.0f, shape.height - shape.radius - r2);
    }
    ++leaves_;
    if (!haveGroup_) {
        haveGroup_ = true;
        firstGroup_ = group;
    } else if (group != firstGroup_) {
        severalGroups_ = true;
    }
    return add_node(std::move(n), local);
}

int ModelSdf::add_group(const std::vector<int>& children, const Mat4& local, ModelSdfBlend blend, float smooth,
                        int mirror) {
    Node n;
    n.leaf = false;
    n.children = children;
    n.blend = blend;
    n.smooth = smooth;
    n.mirror = mirror;
    return add_node(std::move(n), local);
}

float ModelSdf::eval_distance(const Node& n, Vec3 p) const {
    Vec3 q = apply(n.inv, p);
    float d;
    if (n.leaf) {
        d = shape_distance(n.shape, n.capsuleLen, q);
    } else {
        if (n.mirror >= 0) q[n.mirror] = std::fabs(q[n.mirror]);
        d = 1.0e30f;
        for (std::size_t i = 0; i < n.children.size(); ++i) {
            const Node& c = nodes_[std::size_t(n.children[i])];
            const float cd = eval_distance(c, q);
            d = i == 0 ? cd : combine(d, cd, c.blend, c.smooth).d;
        }
    }
    return d * n.distScale;
}

ModelSdfSample ModelSdf::eval_sample(const Node& n, Vec3 p) const {
    Vec3 q = apply(n.inv, p);
    ModelSdfSample s;
    if (n.leaf) {
        s.d = shape_distance(n.shape, n.capsuleLen, q);
        s.group = n.group;
        s.color = n.color;
    } else {
        if (n.mirror >= 0) q[n.mirror] = std::fabs(q[n.mirror]);
        for (std::size_t i = 0; i < n.children.size(); ++i) {
            const Node& c = nodes_[std::size_t(n.children[i])];
            const ModelSdfSample cs = eval_sample(c, q);
            if (i == 0) {
                s = cs;
                continue;
            }
            const Mix m = combine(s.d, cs.d, c.blend, c.smooth);
            // The owner is whoever has the larger share; colours melt by the same shares.
            if (m.t < 0.5f) s.group = cs.group;
            s.color = mix4(s.color, cs.color, m.t);
            s.d = m.d;
        }
    }
    s.d *= n.distScale;
    return s;
}

float ModelSdf::distance(Vec3 p) const { return root_ < 0 ? 1.0e30f : eval_distance(nodes_[std::size_t(root_)], p); }
ModelSdfSample ModelSdf::sample(Vec3 p) const {
    if (root_ < 0) return {1.0e30f, 0, {1, 1, 1, 1}};
    return eval_sample(nodes_[std::size_t(root_)], p);
}

bool ModelSdf::node_bounds(const Node& n, Vec3& bmin, Vec3& bmax) const {
    Vec3 lo{}, hi{};
    if (n.leaf) {
        shape_box(n.shape, n.capsuleLen, lo, hi);
    } else {
        bool have = false;
        for (std::size_t i = 0; i < n.children.size(); ++i) {
            const Node& c = nodes_[std::size_t(n.children[i])];
            Vec3 clo{}, chi{};
            const bool cHas = node_bounds(c, clo, chi);
            if (i == 0) {
                have = cHas;
                lo = clo;
                hi = chi;
                continue;
            }
            if (c.blend == ModelSdfBlend::Union) {
                if (!cHas) continue;
                if (have) {
                    lo = {std::min(lo.x, clo.x), std::min(lo.y, clo.y), std::min(lo.z, clo.z)};
                    hi = {std::max(hi.x, chi.x), std::max(hi.y, chi.y), std::max(hi.z, chi.z)};
                } else {
                    lo = clo;
                    hi = chi;
                    have = true;
                }
                const float grow =
                    c.smooth * 0.25f;  // a smooth union bulges by at most a quarter of its blend distance
                lo = lo - Vec3{grow, grow, grow};
                hi = hi + Vec3{grow, grow, grow};
            } else if (c.blend == ModelSdfBlend::Intersect && have) {
                if (!cHas) {
                    have = false;
                    continue;
                }
                lo = {std::max(lo.x, clo.x), std::max(lo.y, clo.y), std::max(lo.z, clo.z)};
                hi = {std::min(hi.x, chi.x), std::min(hi.y, chi.y), std::min(hi.z, chi.z)};
                if (lo.x > hi.x || lo.y > hi.y || lo.z > hi.z) have = false;
            }
        }
        if (!have) return false;
        if (n.mirror >= 0) {
            const int a = n.mirror;
            const float mlo = -hi[a], mhi = -lo[a];
            lo[a] = std::min(lo[a], mlo);
            hi[a] = std::max(hi[a], mhi);
        }
    }
    box_through(n.fwd, lo, hi, bmin, bmax);
    return true;
}

bool ModelSdf::bounds(Vec3& bmin, Vec3& bmax) const {
    if (root_ < 0) return false;
    return node_bounds(nodes_[std::size_t(root_)], bmin, bmax);
}

float model_sdf_noise(Vec3 p, float frequency, int octaves, int seed) {
    float sum = 0, amp = 1, total = 0, freq = frequency;
    for (int o = 0; o < std::max(octaves, 1); ++o) {
        sum +=
            amp * model_value_noise(p * freq, std::uint32_t(seed) * 7919u + 0x5bd1e995u + std::uint32_t(o) * 104729u);
        total += amp;
        amp *= 0.5f;
        freq *= 2.0f;
    }
    return sum / total;
}

}  // namespace fa
