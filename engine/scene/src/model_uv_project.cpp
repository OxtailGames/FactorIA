// The projections of the UV maker: box, planar, cylinder and sphere, per part. Every uv is computed from the WELDED position of a corner, so the
// corners of one point of the surface get the same bits and the charts (runs of triangles that share a uv corner) can be found exactly.
#include <algorithm>
#include <cmath>
#include <cstring>
#include <numeric>

#include "fa/core/det_math.h"
#include "model_mesh_ops.h"
#include "model_uv_internal.h"

namespace fa::uv {

namespace {

std::uint32_t bits_of(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof u);
    return u;
}
CornerKey key_of(std::uint32_t weld, std::uint32_t tag) { return {weld, tag}; }

int axis_index(char axis) { return axis == 'x' ? 0 : axis == 'z' ? 2 : 1; }
float component(Vec3 v, int axis) { return axis == 0 ? v.x : axis == 1 ? v.y : v.z; }
Vec3 unit_axis(int axis, float sign = 1) {
    return axis == 0 ? Vec3{sign, 0, 0} : axis == 1 ? Vec3{0, sign, 0} : Vec3{0, 0, sign};
}

// Looking at a face that points along `d` (a unit axis vector, either sign): u runs to the right and v DOWN the picture, +Y being up, except
// for faces that look up or down, where -Z is up. This is the frame in which a texture is seen upright and unmirrored.
struct Frame {
    Vec3 u, v;
    Vec2 map(Vec3 p) const { return {dot(p, u), dot(p, v)}; }
};
Frame frame_of(Vec3 d) {
    Vec3 up{0, 1, 0};
    if (std::fabs(d.y) > 0.5f) up = d.y > 0 ? Vec3{0, 0, -1} : Vec3{0, 0, 1};
    return {cross(up, d), up * -1.0f};
}

// The six directions: 0 +x, 1 -x, 2 +y, 3 -y, 4 +z, 5 -z.
Vec3 direction_vec(int dir) { return unit_axis(dir / 2, dir % 2 == 0 ? 1.0f : -1.0f); }
int dominant_direction(Vec3 n) {
    const float ax = std::fabs(n.x), ay = std::fabs(n.y), az = std::fabs(n.z);
    if (ay >= ax && ay >= az) return n.y >= 0 ? 2 : 3;
    if (ax >= az) return n.x >= 0 ? 0 : 1;
    return n.z >= 0 ? 4 : 5;
}

}  // namespace

Work make_work(const ModelMesh& mesh, const std::vector<std::string>& partNames) {
    Work w;
    w.mesh = &mesh;
    mm::Soup soup = mm::to_soup(mesh, mm::kWeldTolerance, &w.welded);
    w.wpos = std::move(soup.pos);
    const std::size_t tris = mesh.triangle_count();
    w.part.assign(tris, 0);
    for (std::size_t t = 0; t < tris; ++t) {
        const std::uint32_t group = t < mesh.triParts.size() ? mesh.triParts[t] : 0;
        const std::string name = group < partNames.size() ? partNames[group] : std::string();
        auto it = std::find(w.names.begin(), w.names.end(), name);
        if (it == w.names.end()) {
            w.names.push_back(name);
            it = w.names.end() - 1;
        }
        w.part[t] = std::uint32_t(it - w.names.begin());
    }
    w.uv.assign(tris * 3, Vec2{});
    w.chart.assign(tris, -1);
    return w;
}

Vec3 Work::facing(std::size_t t) const {
    Vec3 n{0, 0, 0};
    if (mesh->normals.size() == mesh->positions.size())
        for (int k = 0; k < 3; ++k) n = n + mesh->normals[corner_vertex(t, k)];
    if (length_sq(n) > 1e-6f) return normalize(n);
    const Vec3 a = corner_pos(t, 0), b = corner_pos(t, 1), c = corner_pos(t, 2);
    const Vec3 f = cross(b - a, c - a);
    return length_sq(f) > 0 ? normalize(f) : Vec3{0, 1, 0};
}

float Work::area(std::size_t t) const {
    const Vec3 a = corner_pos(t, 0), b = corner_pos(t, 1), c = corner_pos(t, 2);
    return 0.5f * length(cross(b - a, c - a));
}

std::vector<std::int32_t> components(const std::vector<CornerKey>& keys, std::size_t triangles, std::int32_t& count) {
    std::vector<std::uint32_t> parent(triangles);
    std::iota(parent.begin(), parent.end(), 0u);
    auto find = [&](std::uint32_t x) {
        while (parent[x] != x) {
            parent[x] = parent[parent[x]];
            x = parent[x];
        }
        return x;
    };
    // sort the corners by key; consecutive equal keys join their triangles
    std::vector<std::uint32_t> order(triangles * 3);
    std::iota(order.begin(), order.end(), 0u);
    std::stable_sort(order.begin(), order.end(), [&](std::uint32_t a, std::uint32_t b) { return keys[a] < keys[b]; });
    for (std::size_t i = 1; i < order.size(); ++i) {
        if (!(keys[order[i]] == keys[order[i - 1]])) continue;
        const std::uint32_t a = find(order[i] / 3), b = find(order[i - 1] / 3);
        if (a != b) parent[std::max(a, b)] = std::min(a, b);
    }
    std::vector<std::int32_t> id(triangles, -1), out(triangles);
    count = 0;
    for (std::size_t i = 0; i < triangles; ++i) {
        const std::uint32_t root = find(std::uint32_t(i));
        if (id[root] < 0) id[root] = count++;
        out[i] = id[root];
    }
    return out;
}

void assign_charts(Work& w, const std::vector<std::uint32_t>& tris, const std::vector<CornerKey>& keys) {
    std::int32_t count = 0;
    const std::vector<std::int32_t> id = components(keys, tris.size(), count);
    for (std::size_t i = 0; i < tris.size(); ++i) w.chart[tris[i]] = w.chartCount + id[i];
    w.chartCount += count;
}

void project_box(Work& w, const std::vector<std::uint32_t>& tris) {
    std::vector<CornerKey> keys(tris.size() * 3);
    for (std::size_t i = 0; i < tris.size(); ++i) {
        const std::uint32_t t = tris[i];
        const int dir = dominant_direction(w.facing(t));
        const Frame f = frame_of(direction_vec(dir));
        for (int k = 0; k < 3; ++k) {
            w.uv[t * 3 + std::size_t(k)] = f.map(w.corner_pos(t, k));
            keys[i * 3 + std::size_t(k)] = key_of(w.corner_weld(t, k), std::uint32_t(dir));
        }
    }
    assign_charts(w, tris, keys);
}

void project_planar(Work& w, const std::vector<std::uint32_t>& tris, char axis) {
    const Frame f = frame_of(unit_axis(axis_index(axis)));
    std::vector<CornerKey> keys(tris.size() * 3);
    for (std::size_t i = 0; i < tris.size(); ++i) {
        const std::uint32_t t = tris[i];
        for (int k = 0; k < 3; ++k) {
            w.uv[t * 3 + std::size_t(k)] = f.map(w.corner_pos(t, k));
            keys[i * 3 + std::size_t(k)] = key_of(w.corner_weld(t, k), 0);
        }
    }
    assign_charts(w, tris, keys);
}

namespace {

// Round shapes: the centre of the part's bounding box, the axis, and the mean radius that turns an angle into metres.
struct Round {
    Vec3 centre{};
    int axis = 1, e1 = 2, e2 = 0;  // e1 x e2 = axis (counter-clockwise seen from +axis)
    float radius = 1;
    float eps = 1e-6f;
};

Round round_of(const Work& w, const std::vector<std::uint32_t>& tris, char axisChar, bool sphere) {
    Round r;
    r.axis = axis_index(axisChar);
    r.e1 = (r.axis + 1) % 3;
    r.e2 = (r.axis + 2) % 3;
    Vec3 lo{1e30f, 1e30f, 1e30f}, hi{-1e30f, -1e30f, -1e30f};
    for (std::uint32_t t : tris)
        for (int k = 0; k < 3; ++k) {
            const Vec3 p = w.corner_pos(t, k);
            lo = {std::min(lo.x, p.x), std::min(lo.y, p.y), std::min(lo.z, p.z)};
            hi = {std::max(hi.x, p.x), std::max(hi.y, p.y), std::max(hi.z, p.z)};
        }
    r.centre = (lo + hi) * 0.5f;
    double sum = 0;
    std::size_t count = 0;
    for (std::uint32_t t : tris) {
        // a cylinder's radius is the sides': the caps' corners (and their centre on the axis) would pull it down
        if (!sphere && std::fabs(component(w.facing(t), r.axis)) >= 0.8660254f) continue;
        for (int k = 0; k < 3; ++k) {
            const Vec3 d = w.corner_pos(t, k) - r.centre;
            const float a = component(d, r.e1), b = component(d, r.e2), h = component(d, r.axis);
            sum += sphere ? std::sqrt(a * a + b * b + h * h) : std::sqrt(a * a + b * b);
            ++count;
        }
    }
    const float mean = count ? float(sum / double(count)) : 0.0f;
    r.radius = mean > 1e-5f ? mean : 1.0f;
    r.eps = std::max(1e-6f, r.radius * 1e-4f);
    return r;
}

struct Polar {
    float theta = 0;
    float rho = 0;     // distance from the axis
    float height = 0;  // along the axis from the centre
    float dist = 0;    // from the centre
    bool onAxis = false;
};

Polar polar_of(const Round& r, Vec3 p) {
    const Vec3 d = p - r.centre;
    const float a = component(d, r.e1), b = component(d, r.e2);
    Polar o;
    o.height = component(d, r.axis);
    o.rho = std::sqrt(a * a + b * b);
    o.dist = std::sqrt(o.rho * o.rho + o.height * o.height);
    o.onAxis = o.rho <= r.eps;
    o.theta = o.onAxis ? 0.0f : det::atan2(b, a);
    return o;
}

// The angles of a triangle's corners as one run of numbers: a triangle that crosses the seam (theta = +-pi) is moved to its right side, and a
// corner on the axis (no angle) takes the mean of the others.
void unwrap_angles(const Polar (&c)[3], float (&theta)[3]) {
    float lo = 1e30f, hi = -1e30f;
    int valid = 0;
    for (int k = 0; k < 3; ++k)
        if (!c[k].onAxis) {
            lo = std::min(lo, c[k].theta);
            hi = std::max(hi, c[k].theta);
            ++valid;
        }
    const bool crosses = valid > 1 && hi - lo > kPi;
    float sum = 0;
    for (int k = 0; k < 3; ++k) {
        theta[k] = c[k].theta;
        if (crosses && !c[k].onAxis && theta[k] < 0) theta[k] += kTau;
        if (!c[k].onAxis) sum += theta[k];
    }
    const float mean = valid ? sum / float(valid) : 0.0f;
    for (int k = 0; k < 3; ++k)
        if (c[k].onAxis) theta[k] = mean;
}

}  // namespace

void project_cylinder(Work& w, const std::vector<std::uint32_t>& tris, char axisChar) {
    const Round r = round_of(w, tris, axisChar, false);
    std::vector<CornerKey> keys(tris.size() * 3);
    for (std::size_t i = 0; i < tris.size(); ++i) {
        const std::uint32_t t = tris[i];
        const Vec3 n = w.facing(t);
        const float along = component(n, r.axis);
        if (std::fabs(along) >= 0.8660254f) {
            // a cap: looks along the axis, projected flat
            const int dir = r.axis * 2 + (along >= 0 ? 0 : 1);
            const Frame f = frame_of(direction_vec(dir));
            for (int k = 0; k < 3; ++k) {
                w.uv[t * 3 + std::size_t(k)] = f.map(w.corner_pos(t, k));
                keys[i * 3 + std::size_t(k)] = key_of(w.corner_weld(t, k), 1u + std::uint32_t(dir));
            }
            continue;
        }
        Polar c[3];
        float theta[3];
        for (int k = 0; k < 3; ++k) c[k] = polar_of(r, w.corner_pos(t, k));
        unwrap_angles(c, theta);
        for (int k = 0; k < 3; ++k) {
            const Vec2 uv{theta[k] * r.radius, -c[k].height};
            w.uv[t * 3 + std::size_t(k)] = uv;
            keys[i * 3 + std::size_t(k)] = key_of(w.corner_weld(t, k), 8u + bits_of(uv.x));
        }
    }
    assign_charts(w, tris, keys);
}

void project_sphere(Work& w, const std::vector<std::uint32_t>& tris, char axisChar) {
    const Round r = round_of(w, tris, axisChar, true);
    std::vector<CornerKey> keys(tris.size() * 3);
    for (std::size_t i = 0; i < tris.size(); ++i) {
        const std::uint32_t t = tris[i];
        Polar c[3];
        float theta[3];
        for (int k = 0; k < 3; ++k) c[k] = polar_of(r, w.corner_pos(t, k));
        unwrap_angles(c, theta);
        for (int k = 0; k < 3; ++k) {
            // the angle from the +axis pole: 0 at the top, pi at the bottom, so v grows downwards
            const float cosPsi = c[k].dist > r.eps ? std::clamp(c[k].height / c[k].dist, -1.0f, 1.0f) : 0.0f;
            const float psi = det::acos(cosPsi);
            const Vec2 uv{theta[k] * r.radius, psi * r.radius};
            w.uv[t * 3 + std::size_t(k)] = uv;
            keys[i * 3 + std::size_t(k)] = key_of(w.corner_weld(t, k), bits_of(uv.x));
        }
    }
    assign_charts(w, tris, keys);
}

}  // namespace fa::uv
