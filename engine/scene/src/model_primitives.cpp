// The parametric primitives of the model kernel (fa/scene/model_kernel.h). Everything is a grid of quads (box, grid, stairs,
// rounded box) or a surface of revolution (cylinder, cone, sphere, capsule, torus, pipe); arch and text are extrusions
// (model_extrude.cpp). Winding and normals are decided here once and checked by the tests with the mesh's signed volume.
#include <algorithm>
#include <cmath>
#include <utility>

#include "fa/scene/model_kernel.h"

namespace fa {

namespace {


int clamp_int(int v, int lo, int hi) { return std::max(lo, std::min(hi, v)); }

struct Builder {
    ModelMesh m;
    std::uint32_t vertex(Vec3 p, Vec3 n, Vec2 uv) {
        m.positions.push_back(p);
        m.normals.push_back(n);
        m.uvs.push_back(uv);
        return std::uint32_t(m.positions.size() - 1);
    }
    void tri(std::uint32_t a, std::uint32_t b, std::uint32_t c) {
        m.indices.push_back(a);
        m.indices.push_back(b);
        m.indices.push_back(c);
        m.triParts.push_back(0);
    }
    // a, b, c, d counter-clockwise seen from the front
    void quad(std::uint32_t a, std::uint32_t b, std::uint32_t c, std::uint32_t d) {
        tri(a, b, c);
        tri(a, c, d);
    }
};

// A (nu x nv) grid of quads from `origin`, running along `du` then `dv`; it faces du x dv. uv = uv0 + uvu * (i / nu) + uvv * (j / nv).
void add_grid(Builder& b, Vec3 origin, Vec3 du, Vec3 dv, int nu, int nv, Vec2 uv0, Vec2 uvu, Vec2 uvv) {
    const Vec3 normal = normalize(cross(du, dv));
    const std::uint32_t base = std::uint32_t(b.m.positions.size());
    for (int j = 0; j <= nv; ++j)
        for (int i = 0; i <= nu; ++i) {
            const float fu = float(i) / float(nu), fv = float(j) / float(nv);
            b.vertex(origin + du * fu + dv * fv, normal, uv0 + uvu * fu + uvv * fv);
        }
    const std::uint32_t stride = std::uint32_t(nu + 1);
    for (int j = 0; j < nv; ++j)
        for (int i = 0; i < nu; ++i) {
            const std::uint32_t a = base + std::uint32_t(j) * stride + std::uint32_t(i);
            b.quad(a, a + 1, a + stride + 1, a + stride);
        }
}

Vec3 axis_vec(int axis, float v) {
    Vec3 r{};
    r[axis] = v;
    return r;
}

// The six faces of a box: the axis it faces along, the side, then the axis the u coordinate runs along (with its sign) and the same
// for v. u x v is the face's outward normal; viewed from outside, u goes left to right and v bottom to top.
struct FaceSpec {
    int n, ns, ua, us, va, vs;
};
constexpr FaceSpec kFaces[6] = {{2, 1, 0, 1, 1, 1},  {2, -1, 0, -1, 1, 1}, {0, 1, 2, -1, 1, 1},
                                {0, -1, 2, 1, 1, 1}, {1, 1, 0, 1, 2, -1},  {1, -1, 0, 1, 2, 1}};

// sin and cos of an angle in degrees
void sc(float deg, float& s, float& c) { det::sin_cos(radians(deg), s, c); }

// ---- surfaces of revolution -------------------------------------------------------------------------------------------

// A point of a profile in the (radius, height) half-plane with its normal there. Walking a strip with the solid on the left makes the
// triangles face outwards. `planar`: the uv is the top-down projection (caps) instead of (angle, v).
struct Rev {
    float r, y, nr, ny, v;
    bool planar = false;
};
using Strip = std::vector<Rev>;

void lathe(Builder& b, const std::vector<Strip>& strips, int segments, float capRadius) {
    segments = std::max(segments, 3);
    std::vector<float> sins(std::size_t(segments) + 1), coss(std::size_t(segments) + 1);
    for (int j = 0; j <= segments; ++j) {
        if (j == segments) {
            sins[std::size_t(j)] = sins[0];
            coss[std::size_t(j)] = coss[0];
        } else {
            det::sin_cos(kTau * float(j) / float(segments), sins[std::size_t(j)], coss[std::size_t(j)]);
        }
    }
    for (const Strip& strip : strips) {
        if (strip.size() < 2) continue;
        const std::uint32_t base = std::uint32_t(b.m.positions.size());
        for (const Rev& p : strip)
            for (int j = 0; j <= segments; ++j) {
                const float s = sins[std::size_t(j)], c = coss[std::size_t(j)];
                const Vec3 pos{p.r * s, p.y, p.r * c};
                const Vec3 nor = normalize(Vec3{p.nr * s, p.ny, p.nr * c});
                Vec2 uv{float(j) / float(segments), p.v};
                if (p.planar) uv = {0.5f + 0.5f * pos.x / capRadius, 0.5f + 0.5f * pos.z / capRadius};
                b.vertex(pos, nor, uv);
            }
        const std::uint32_t stride = std::uint32_t(segments + 1);
        for (std::size_t k = 0; k + 1 < strip.size(); ++k) {
            const bool lowPole = strip[k].r == 0, highPole = strip[k + 1].r == 0;
            if (lowPole && highPole) continue;
            for (int j = 0; j < segments; ++j) {
                const std::uint32_t a = base + std::uint32_t(k) * stride + std::uint32_t(j), bb = a + 1, d = a + stride, c = d + 1;
                if (lowPole) b.tri(a, c, d);
                else if (highPole) b.tri(a, bb, c);
                else b.quad(a, bb, c, d);
            }
        }
    }
}

// The circle arc of a sphere-like end: `rings` steps of the angle from a0 to a1 degrees (0 is the equator, +90 the top pole), around a
// centre at height cy. Poles get exactly r = 0.
void arc_points(Strip& out, float radius, float cy, float a0, float a1, int rings) {
    for (int i = 0; i <= rings; ++i) {
        const float a = a0 + (a1 - a0) * float(i) / float(rings);
        float s, c;
        sc(a, s, c);
        if (std::fabs(a) >= 90.0f) c = 0, s = a > 0 ? 1.0f : -1.0f;
        if (a == 0) s = 0, c = 1;
        out.push_back({radius * c, cy + radius * s, c, s, 0});
    }
}

// v = 1 at the first point of the strip and 0 at the last, by distance along it.
void spread_v(Strip& strip) {
    float total = 0;
    for (std::size_t i = 1; i < strip.size(); ++i) total += std::hypot(strip[i].r - strip[i - 1].r, strip[i].y - strip[i - 1].y);
    float run = 0;
    for (std::size_t i = 0; i < strip.size(); ++i) {
        if (i) run += std::hypot(strip[i].r - strip[i - 1].r, strip[i].y - strip[i - 1].y);
        strip[i].v = total > 0 ? 1.0f - run / total : 0.0f;
    }
}

ModelMesh frustum(float rb, float rt, float height, int segments, int heightSegments, bool capBottom, bool capTop) {
    Builder b;
    const float h2 = height * 0.5f;
    std::vector<Strip> strips;
    if (capBottom && rb > 0) strips.push_back({{0, -h2, 0, -1, 0, true}, {rb, -h2, 0, -1, 0, true}});
    Strip side;
    const Vec2 slope = normalize(Vec2{height, rb - rt});  // outward normal in the (r, y) plane
    heightSegments = clamp_int(heightSegments, 1, 256);
    for (int i = 0; i <= heightSegments; ++i) {
        const float t = float(i) / float(heightSegments);
        side.push_back({lerp(rb, rt, t), -h2 + height * t, slope.x, slope.y, 1.0f - t});
    }
    strips.push_back(side);
    if (capTop && rt > 0) strips.push_back({{rt, h2, 0, 1, 0, true}, {0, h2, 0, 1, 0, true}});
    lathe(b, strips, segments, std::max(std::max(rb, rt), 1e-6f));
    return std::move(b.m);
}

}  // namespace

ModelMesh model_box(const ModelBoxParams& p) {
    Builder b;
    const Vec3 size{std::max(p.size.x, 1e-4f), std::max(p.size.y, 1e-4f), std::max(p.size.z, 1e-4f)};
    const int seg[3] = {clamp_int(p.segX, 1, 256), clamp_int(p.segY, 1, 256), clamp_int(p.segZ, 1, 256)};
    for (const FaceSpec& f : kFaces) {
        const Vec3 du = axis_vec(f.ua, float(f.us) * size[f.ua]), dv = axis_vec(f.va, float(f.vs) * size[f.va]);
        const Vec3 origin = axis_vec(f.n, float(f.ns) * size[f.n] * 0.5f) - du * 0.5f - dv * 0.5f;
        add_grid(b, origin, du, dv, seg[f.ua], seg[f.va], {0, 1}, {1, 0}, {0, -1});
    }
    return std::move(b.m);
}

ModelMesh model_rounded_box(const ModelRoundedBoxParams& p) {
    const Vec3 size{std::max(p.size.x, 1e-3f), std::max(p.size.y, 1e-3f), std::max(p.size.z, 1e-3f)};
    const Vec3 half = size * 0.5f;
    const float r = std::min(p.radius, std::min(half.x, std::min(half.y, half.z)));
    if (r <= 1e-5f) return model_box({size, 1, 1, 1});
    const int seg = clamp_int(p.segments, 1, 32);
    const Vec3 inner{half.x - r, half.y - r, half.z - r};
    // Along each axis the grid has 2 * (seg + 1) stations: the arc of the low corner, then the arc of the high one. A station is the
    // direction tan(phi) of the cube-to-sphere map and which side of the box (low or high) its inner point sits on.
    const int K = 2 * (seg + 1);
    std::vector<float> tanv(static_cast<std::size_t>(K), 0.0f);
    for (int i = 0; i < K; ++i) {
        const int k = i <= seg ? i : i - seg - 1;  // 0..seg within the arc
        const float phi = i <= seg ? -45.0f + 45.0f * float(k) / float(seg) : 45.0f * float(k) / float(seg);
        float s, c;
        sc(phi, s, c);
        float t = s / c;
        if (k == 0 && i <= seg) t = -1.0f;
        else if (k == seg && i > seg) t = 1.0f;
        else if ((i == seg) || (i == seg + 1)) t = 0.0f;
        tanv[std::size_t(i)] = t;
    }
    Builder b;
    for (const FaceSpec& f : kFaces) {
        const std::uint32_t base = std::uint32_t(b.m.positions.size());
        for (int j = 0; j < K; ++j)
            for (int i = 0; i < K; ++i) {
                const int si = f.us > 0 ? i : K - 1 - i, sj = f.vs > 0 ? j : K - 1 - j;
                Vec3 d{}, q{};
                d[f.n] = float(f.ns);
                d[f.ua] = tanv[std::size_t(si)];
                d[f.va] = tanv[std::size_t(sj)];
                q[f.n] = float(f.ns) * inner[f.n];
                q[f.ua] = si > seg ? inner[f.ua] : -inner[f.ua];
                q[f.va] = sj > seg ? inner[f.va] : -inner[f.va];
                const Vec3 n = normalize(d);
                const Vec3 pos = q + n * r;
                const float u = (float(f.us) * pos[f.ua] + half[f.ua]) / size[f.ua];
                const float v = 1.0f - (float(f.vs) * pos[f.va] + half[f.va]) / size[f.va];
                b.vertex(pos, n, {u, v});
            }
        for (int j = 0; j + 1 < K; ++j)
            for (int i = 0; i + 1 < K; ++i) {
                const std::uint32_t a = base + std::uint32_t(j * K + i);
                b.quad(a, a + 1, a + std::uint32_t(K) + 1, a + std::uint32_t(K));
            }
    }
    return std::move(b.m);
}

ModelMesh model_cylinder(const ModelCylinderParams& p) {
    const float rb = std::max(p.radius, 0.0f);
    const float rt = p.radiusTop < 0 ? rb : p.radiusTop;
    return frustum(rb, rt, std::max(p.height, 1e-4f), clamp_int(p.segments, 3, 512), p.heightSegments, p.capBottom, p.capTop);
}

ModelMesh model_cone(const ModelConeParams& p) {
    return frustum(std::max(p.radius, 0.0f), std::max(p.radiusTop, 0.0f), std::max(p.height, 1e-4f), clamp_int(p.segments, 3, 512), p.heightSegments,
                   p.cap, p.radiusTop > 0);
}

ModelMesh model_sphere(const ModelSphereParams& p) {
    Builder b;
    const int segments = clamp_int(p.segments, 3, 512);
    const int rings = clamp_int(p.rings > 0 ? p.rings : segments / 2, 2, 512);
    Strip s;
    arc_points(s, std::max(p.radius, 1e-5f), 0, -90.0f, 90.0f, rings);
    spread_v(s);
    lathe(b, {s}, segments, 1);
    return std::move(b.m);
}

ModelMesh model_capsule(const ModelCapsuleParams& p) {
    Builder b;
    const float radius = std::max(p.radius, 1e-5f);
    const float c = std::max(p.height * 0.5f - radius, 0.0f);  // half the length of the straight part
    const int rings = clamp_int(p.rings, 1, 256), hs = c > 0 ? clamp_int(p.heightSegments, 1, 256) : 1;
    Strip s;
    arc_points(s, radius, -c, -90.0f, 0.0f, rings);
    for (int k = 1; k < hs; ++k) s.push_back({radius, -c + 2 * c * float(k) / float(hs), 1, 0, 0});
    arc_points(s, radius, c, 0.0f, 90.0f, rings);
    if (c == 0) s.erase(s.begin() + (rings + 1));  // the two equators are the same ring
    spread_v(s);
    lathe(b, {s}, clamp_int(p.segments, 3, 512), 1);
    return std::move(b.m);
}

ModelMesh model_torus(const ModelTorusParams& p) {
    Builder b;
    const int sides = clamp_int(p.sides, 3, 256);
    const float tube = std::max(p.tube, 1e-5f), ring = std::max(p.radius, tube);
    Strip s;
    for (int i = 0; i <= sides; ++i) {
        float sn, cs;
        if (i == sides) sn = 0, cs = 1;
        else sc(360.0f * float(i) / float(sides), sn, cs);
        s.push_back({ring + tube * cs, tube * sn, cs, sn, float(i) / float(sides)});
    }
    lathe(b, {s}, clamp_int(p.segments, 3, 512), 1);
    return std::move(b.m);
}

ModelMesh model_grid(const ModelGridParams& p) {
    Builder b;
    const float w = std::max(p.width, 1e-4f), d = std::max(p.depth, 1e-4f);
    add_grid(b, {-w * 0.5f, 0, d * 0.5f}, {w, 0, 0}, {0, 0, -d}, clamp_int(p.segX, 1, 512), clamp_int(p.segZ, 1, 512), {0, 1}, {1, 0}, {0, -1});
    return std::move(b.m);
}

ModelMesh model_stairs(const ModelStairsParams& p) {
    const int n = clamp_int(p.steps, 1, 256);
    const float W = std::max(p.width, 1e-4f), H = std::max(p.height, 1e-4f), D = std::max(p.depth, 1e-4f);
    const float rise = H / float(n), run = D / float(n), y0 = -H * 0.5f;
    // The side profile, counter-clockwise, in (x, y) with x = -z of the model (so the steps climb towards -Z); the stairs are that
    // profile pushed along Z by the width and turned a quarter so the push runs along X.
    ModelPolygon poly;
    poly.outer.push_back({-D * 0.5f, y0});
    poly.outer.push_back({D * 0.5f, y0});
    poly.outer.push_back({D * 0.5f, y0 + H});
    for (int i = n - 1; i >= 0; --i) {
        const float xs = -D * 0.5f + float(i) * run;
        poly.outer.push_back({xs, y0 + float(i + 1) * rise});
        if (i > 0) poly.outer.push_back({xs, y0 + float(i) * rise});
    }
    ModelMesh m = extrude_polygons({poly}, W, 40.0f);
    m.transform(Mat4::rotate_euler_deg({0, 90, 0}));
    return m;
}

ModelMesh model_arch(const ModelArchParams& p) {
    const float W = std::max(p.width, 1e-3f), H = std::max(p.height, 1e-3f), D = std::max(p.depth, 1e-3f);
    const float ow = std::min(std::max(p.openingWidth, 1e-3f), W * 0.99f);
    const float rad = ow * 0.5f;
    const float oh = std::min(std::max(p.openingHeight, rad), H * 0.99f);  // the half circle needs rad of height
    const float ys = oh - rad;                                              // where the half circle starts
    const int n = clamp_int(p.segments, 2, 256);
    ModelPolygon poly;
    poly.outer.push_back({-W * 0.5f, 0});
    poly.outer.push_back({-rad, 0});
    poly.outer.push_back({-rad, ys});
    for (int k = 1; k < n; ++k) {
        float s, c;
        sc(180.0f - 180.0f * float(k) / float(n), s, c);
        poly.outer.push_back({rad * c, ys + rad * s});
    }
    poly.outer.push_back({rad, ys});
    poly.outer.push_back({rad, 0});
    poly.outer.push_back({W * 0.5f, 0});
    poly.outer.push_back({W * 0.5f, H});
    poly.outer.push_back({-W * 0.5f, H});
    ModelMesh m = extrude_polygons({poly}, D, 40.0f);
    m.transform(Mat4::translate({0, -H * 0.5f, 0}));
    return m;
}

ModelMesh model_pipe(const ModelPipeParams& p) {
    Builder b;
    const float R = std::max(p.radius, 2e-5f);
    const float ri = std::max(std::min(p.innerRadius, R - 1e-5f), 1e-5f);
    const float h2 = std::max(p.height, 1e-4f) * 0.5f;
    std::vector<Strip> strips;
    strips.push_back({{ri, -h2, 0, -1, 0, true}, {R, -h2, 0, -1, 0, true}});  // underside ring
    strips.push_back({{R, -h2, 1, 0, 1}, {R, h2, 1, 0, 0}});                  // outer wall
    strips.push_back({{R, h2, 0, 1, 0, true}, {ri, h2, 0, 1, 0, true}});      // top ring
    strips.push_back({{ri, h2, -1, 0, 0}, {ri, -h2, -1, 0, 1}});              // inner wall
    lathe(b, strips, clamp_int(p.segments, 3, 512), R);
    return std::move(b.m);
}

}  // namespace fa
