// model_view.h: a small deterministic software rasterizer for looking at meshes without a graphics device.
#include "fa/tooling/model_view.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <mutex>

#include "fa/core/det_math.h"
#include "fa/core/json_schema.h"
#include "fa/scene/model_doc.h"

namespace fa {

namespace {

struct V3d {
    double x = 0, y = 0, z = 0;
};
V3d sub(V3d a, V3d b) { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
double dot3(V3d a, V3d b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
V3d cross3(V3d a, V3d b) { return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x}; }
V3d norm3(V3d a) {
    double l = std::sqrt(dot3(a, a));
    return l > 1e-12 ? V3d{a.x / l, a.y / l, a.z / l} : V3d{0, 1, 0};
}

constexpr double kFovDeg = 30.0;
constexpr double kNear = 0.01;

struct Camera {
    V3d eye, right, up, forward;
    bool ortho = false;
    double focal = 1;   // pixels per unit at depth 1 (perspective) or per metre (orthographic)
    double cx = 0, cy = 0;
};

struct Buffers {
    int w = 0, h = 0;
    std::vector<float> r, g, b;
    std::vector<float> key;  // larger = closer
    float bgR = 0, bgG = 0, bgB = 0;  // the background, which a hidden-line view paints surfaces with
};

struct Projected {
    double sx = 0, sy = 0, key = 0;
    bool ok = false;
};

Projected project(const Camera& c, V3d p) {
    V3d d = sub(p, c.eye);
    double x = dot3(d, c.right), y = dot3(d, c.up), z = dot3(d, c.forward);
    Projected out;
    if (z < kNear) return out;
    out.ok = true;
    if (c.ortho) {
        out.sx = c.cx + x * c.focal;
        out.sy = c.cy - y * c.focal;
        out.key = -z;
    } else {
        out.sx = c.cx + x / z * c.focal;
        out.sy = c.cy - y / z * c.focal;
        out.key = 1.0 / z;
    }
    return out;
}

// Straight line with a depth test on the interpolated key (a little bias so an edge lies on its own surface).
void draw_line(Buffers& bf, Projected a, Projected b, float r, float g, float bl, bool depthTest) {
    const double dx = b.sx - a.sx, dy = b.sy - a.sy;
    const int steps = std::max(1, int(std::ceil(std::max(std::fabs(dx), std::fabs(dy)))));
    if (steps > 20000) return;
    for (int i = 0; i <= steps; ++i) {
        const double t = double(i) / steps;
        const int x = int(std::floor(a.sx + dx * t)), y = int(std::floor(a.sy + dy * t));
        if (x < 0 || y < 0 || x >= bf.w || y >= bf.h) continue;
        const std::size_t at = std::size_t(y) * std::size_t(bf.w) + std::size_t(x);
        const double key = a.key + (b.key - a.key) * t;
        if (depthTest) {
            const double stored = bf.key[at];
            if (key < stored - 0.004 * std::fabs(stored) - 1e-9) continue;
        }
        bf.r[at] = r;
        bf.g[at] = g;
        bf.b[at] = bl;
    }
}

struct ShadedVertex {
    Projected p;
    V3d n;                 // view space
    float cr = 1, cg = 1, cb = 1;
};

void fill_triangle(Buffers& bf, const ShadedVertex& v0, const ShadedVertex& v1, const ShadedVertex& v2, bool shaded) {
    const double area = (v1.p.sx - v0.p.sx) * (v2.p.sy - v0.p.sy) - (v2.p.sx - v0.p.sx) * (v1.p.sy - v0.p.sy);
    if (std::fabs(area) < 1e-12) return;
    const bool front = area < 0;  // counter-clockwise seen from the camera is clockwise with y down
    const int x0 = std::max(0, int(std::floor(std::min({v0.p.sx, v1.p.sx, v2.p.sx})))), x1 = std::min(bf.w - 1, int(std::ceil(std::max({v0.p.sx, v1.p.sx, v2.p.sx}))));
    const int y0 = std::max(0, int(std::floor(std::min({v0.p.sy, v1.p.sy, v2.p.sy})))), y1 = std::min(bf.h - 1, int(std::ceil(std::max({v0.p.sy, v1.p.sy, v2.p.sy}))));
    const double inv = 1.0 / area;
    static const V3d toLight = norm3({-0.4, 0.6, -0.7});  // view space: toward the camera, above and to the left
    for (int y = y0; y <= y1; ++y) {
        for (int x = x0; x <= x1; ++x) {
            const double px = x + 0.5, py = y + 0.5;
            const double w0 = ((v1.p.sx - px) * (v2.p.sy - py) - (v2.p.sx - px) * (v1.p.sy - py)) * inv;
            const double w1 = ((v2.p.sx - px) * (v0.p.sy - py) - (v0.p.sx - px) * (v2.p.sy - py)) * inv;
            const double w2 = 1.0 - w0 - w1;
            constexpr double kEdge = -1e-9;
            if (w0 < kEdge || w1 < kEdge || w2 < kEdge) continue;
            const double key = w0 * v0.p.key + w1 * v1.p.key + w2 * v2.p.key;
            const std::size_t at = std::size_t(y) * std::size_t(bf.w) + std::size_t(x);
            if (key <= bf.key[at]) continue;
            bf.key[at] = float(key);
            if (!shaded) {
                bf.r[at] = bf.bgR;  // hidden-line mode: the surface is the background
                bf.g[at] = bf.bgG;
                bf.b[at] = bf.bgB;
                continue;
            }
            V3d n = norm3({w0 * v0.n.x + w1 * v1.n.x + w2 * v2.n.x, w0 * v0.n.y + w1 * v1.n.y + w2 * v2.n.y, w0 * v0.n.z + w1 * v1.n.z + w2 * v2.n.z});
            if (!front) n = {-n.x, -n.y, -n.z};
            const double diffuse = std::max(0.0, dot3(n, toLight));
            const double light = 0.28 + 0.12 * n.y + 0.72 * diffuse;
            double cr = w0 * v0.cr + w1 * v1.cr + w2 * v2.cr, cg = w0 * v0.cg + w1 * v1.cg + w2 * v2.cg, cb = w0 * v0.cb + w1 * v1.cb + w2 * v2.cb;
            if (!front) {  // the inside of a surface: a dark red tint
                cr = cr * 0.2 + 0.85 * 0.8;
                cg = cg * 0.2 + 0.03 * 0.8;
                cb = cb * 0.2 + 0.03 * 0.8;
            }
            bf.r[at] = float(std::sqrt(std::clamp(cr * light, 0.0, 1.0)));  // display gamma, about 2
            bf.g[at] = float(std::sqrt(std::clamp(cg * light, 0.0, 1.0)));
            bf.b[at] = float(std::sqrt(std::clamp(cb * light, 0.0, 1.0)));
        }
    }
}

Camera make_camera(const ModelViewOptions& o, Vec3 center, double radius, int w, int h) {
    float sy, cyaw, sp, cp;
    det::sin_cos(float(o.yawDeg * 3.14159265358979323846 / 180.0), sy, cyaw);
    det::sin_cos(float(std::clamp(o.pitchDeg, -89.0, 89.0) * 3.14159265358979323846 / 180.0), sp, cp);
    const V3d dir = norm3({double(cp) * sy, double(sp), double(cp) * cyaw});  // from the centre to the eye
    Camera c;
    const double half = std::min(w, h) * 0.5;
    const V3d ctr{center.x, center.y, center.z};
    c.ortho = o.orthographic;
    const double zoom = std::max(o.zoom, 0.05);
    if (c.ortho) {
        c.focal = half / (radius * 1.08) * zoom;
        const double dist = radius * 4;
        c.eye = {ctr.x + dir.x * dist, ctr.y + dir.y * dist, ctr.z + dir.z * dist};
    } else {
        double sinHalf, cosHalf;
        {
            float s, c2;
            det::sin_cos(float(kFovDeg * 0.5 * 3.14159265358979323846 / 180.0), s, c2);
            sinHalf = s;
            cosHalf = c2;
        }
        const double dist = radius * 1.08 / sinHalf / zoom;
        c.focal = half * cosHalf / sinHalf;
        c.eye = {ctr.x + dir.x * dist, ctr.y + dir.y * dist, ctr.z + dir.z * dist};
    }
    c.forward = norm3(sub(ctr, c.eye));
    V3d worldUp{0, 1, 0};
    c.right = norm3(cross3(c.forward, worldUp));
    c.up = cross3(c.right, c.forward);
    c.cx = w * 0.5;
    c.cy = h * 0.5;
    return c;
}

bool accent_part(const MeshSubmesh& s, const ModelViewItem& item) { return !item.highlightPart.empty() && s.part == item.highlightPart; }

const char* kFigureDoc = R"({"format":"factoria.model/1","nodes":[
    {"op":"sphere","radius":0.105,"segments":20,"rings":10,"position":[0,1.695,0]},
    {"op":"cylinder","radius":0.05,"height":0.12,"segments":12,"position":[0,1.54,0]},
    {"op":"box","size":[0.36,0.6,0.2],"position":[0,1.2,0]},
    {"op":"cylinder","radius":0.05,"height":0.62,"segments":12,"position":[-0.24,1.19,0]},
    {"op":"cylinder","radius":0.05,"height":0.62,"segments":12,"position":[0.24,1.19,0]},
    {"op":"cylinder","radius":0.075,"height":0.84,"segments":14,"position":[-0.09,0.48,0]},
    {"op":"cylinder","radius":0.075,"height":0.84,"segments":14,"position":[0.09,0.48,0]},
    {"op":"box","size":[0.11,0.06,0.26],"position":[-0.09,0.03,0.06]},
    {"op":"box","size":[0.11,0.06,0.26],"position":[0.09,0.03,0.06]}]})";

}  // namespace

ModelViewFrame frame_model_items(const std::vector<ModelViewItem>& items) {
    bool any = false;
    Vec3 lo{}, hi{};
    for (const ModelViewItem& it : items) {
        if (!it.mesh) continue;
        const MeshData& m = *it.mesh;
        for (std::size_t i = 0; i + 2 < m.positions.size(); i += 3) {
            Vec3 p{m.positions[i] + it.offset.x, m.positions[i + 1] + it.offset.y, m.positions[i + 2] + it.offset.z};
            if (!any) lo = hi = p, any = true;
            lo = min(lo, p);
            hi = max(hi, p);
        }
    }
    ModelViewFrame f;
    if (!any) return f;
    f.center = (lo + hi) * 0.5f;
    f.radius = std::max(0.05, double(length(hi - lo)) * 0.5);
    return f;
}

const MeshData& model_reference_figure() {
    static MeshData figure;
    static std::once_flag once;
    std::call_once(once, [] {
        auto json = parse_json(kFigureDoc, "reference figure");
        if (!json.ok()) return;
        auto doc = parse_model_doc(*json, "reference_figure.model.json");
        if (!doc.ok()) return;
        auto built = evaluate_model(*doc);
        if (built.ok()) figure = std::move(built->data);
    });
    return figure;
}

Vec3 reference_figure_offset(Vec3 modelMin, Vec3 modelMax) { return {modelMax.x + 0.55f, 0.0f, (modelMin.z + modelMax.z) * 0.5f}; }

Image render_model_view(const std::vector<ModelViewItem>& items, const ModelViewOptions& o) {
    Image out;
    out.width = std::clamp(o.width, 1, 4096);
    out.height = std::clamp(o.height, 1, 4096);
    const int S = std::clamp(o.supersample, 1, 3);
    Buffers bf;
    bf.w = out.width * S;
    bf.h = out.height * S;
    const std::size_t n = std::size_t(bf.w) * std::size_t(bf.h);
    bf.r.assign(n, o.background.r);
    bf.g.assign(n, o.background.g);
    bf.b.assign(n, o.background.b);
    bf.key.assign(n, -std::numeric_limits<float>::infinity());
    bf.bgR = o.background.r;
    bf.bgG = o.background.g;
    bf.bgB = o.background.b;

    ModelViewFrame frame{o.center, o.radius};
    if (o.radius <= 0) frame = frame_model_items(items);
    const Camera cam = make_camera(o, frame.center, frame.radius, bf.w, bf.h);

    const bool wire = o.wireframe;
    std::vector<ShadedVertex> sv;
    for (const ModelViewItem& item : items) {
        if (!item.mesh) continue;
        const MeshData& m = *item.mesh;
        const std::size_t vc = m.vertex_count();
        const bool hasN = m.normals.size() == m.positions.size();
        const bool hasC = m.colors.size() == vc * 4;
        // Per vertex: screen position, view-space normal. The colour is per submesh (and per vertex colour).
        std::vector<Projected> proj(vc);
        std::vector<V3d> nrm(vc);
        for (std::size_t i = 0; i < vc; ++i) {
            V3d p{m.positions[i * 3] + item.offset.x, m.positions[i * 3 + 1] + item.offset.y, m.positions[i * 3 + 2] + item.offset.z};
            proj[i] = project(cam, p);
            if (hasN) {
                V3d wn{m.normals[i * 3], m.normals[i * 3 + 1], m.normals[i * 3 + 2]};
                nrm[i] = {dot3(wn, cam.right), dot3(wn, cam.up), dot3(wn, cam.forward)};
            }
        }
        for (const MeshSubmesh& sm : m.submeshes) {
            Color base = item.flat ? item.flatColor : sm.material.color;
            if (accent_part(sm, item)) base = Color{base.r * 0.35f + 1.0f * 0.65f, base.g * 0.35f + 0.55f * 0.65f, base.b * 0.35f + 0.1f * 0.65f, 1};
            const std::size_t end = std::min<std::size_t>(std::size_t(sm.start) + sm.count, m.indices.size());
            for (std::size_t k = sm.start; k + 3 <= end; k += 3) {
                std::uint32_t id[3] = {m.indices[k], m.indices[k + 1], m.indices[k + 2]};
                if (id[0] >= vc || id[1] >= vc || id[2] >= vc) continue;
                if (!proj[id[0]].ok || !proj[id[1]].ok || !proj[id[2]].ok) continue;
                ShadedVertex tri[3];
                for (int c = 0; c < 3; ++c) {
                    tri[c].p = proj[id[c]];
                    tri[c].cr = base.r;
                    tri[c].cg = base.g;
                    tri[c].cb = base.b;
                    if (hasC && !item.flat) {
                        tri[c].cr *= m.colors[id[c] * 4];
                        tri[c].cg *= m.colors[id[c] * 4 + 1];
                        tri[c].cb *= m.colors[id[c] * 4 + 2];
                    }
                    if (hasN) tri[c].n = nrm[id[c]];
                }
                if (!hasN) {  // flat normal from the triangle
                    V3d a{m.positions[id[0] * 3], m.positions[id[0] * 3 + 1], m.positions[id[0] * 3 + 2]};
                    V3d b{m.positions[id[1] * 3], m.positions[id[1] * 3 + 1], m.positions[id[1] * 3 + 2]};
                    V3d c{m.positions[id[2] * 3], m.positions[id[2] * 3 + 1], m.positions[id[2] * 3 + 2]};
                    V3d wn = norm3(cross3(sub(b, a), sub(c, a)));
                    V3d vn{dot3(wn, cam.right), dot3(wn, cam.up), dot3(wn, cam.forward)};
                    for (auto& t : tri) t.n = vn;
                }
                fill_triangle(bf, tri[0], tri[1], tri[2], o.shaded || !item.wire);  // an item with no wireframe is always drawn solid
            }
        }
    }

    if (o.ground) {  // a grid on y = 0, behind the model (depth-tested), with the origin's two axes brighter
        const double spacing = frame.radius > 20 ? std::pow(10.0, std::ceil(std::log10(frame.radius / 4))) : frame.radius > 3 ? 1.0 : 0.5;
        const double extent = std::max(1.0, std::ceil(frame.radius * 1.4 / spacing)) * spacing;
        const double cxg = std::round(frame.center.x / spacing) * spacing, czg = std::round(frame.center.z / spacing) * spacing;
        const int lines = std::min(40, int(std::round(extent / spacing)));
        for (int i = -lines; i <= lines; ++i) {
            const double off = i * spacing;
            const double zLine = czg + off, xLine = cxg + off;
            const bool axisZ = std::fabs(zLine) < spacing * 0.01, axisX = std::fabs(xLine) < spacing * 0.01;
            const float dim = 0.30f;
            Projected a = project(cam, {cxg - extent, 0, zLine}), b = project(cam, {cxg + extent, 0, zLine});
            if (a.ok && b.ok) draw_line(bf, a, b, axisZ ? 0.62f : dim, axisZ ? 0.35f : dim + 0.02f, axisZ ? 0.35f : dim + 0.07f, true);
            a = project(cam, {xLine, 0, czg - extent});
            b = project(cam, {xLine, 0, czg + extent});
            if (a.ok && b.ok) draw_line(bf, a, b, axisX ? 0.35f : dim, axisX ? 0.45f : dim + 0.02f, axisX ? 0.65f : dim + 0.07f, true);
        }
    }

    if (wire) {
        const float r = o.shaded ? 0.05f : 0.82f, g = o.shaded ? 0.06f : 0.88f, b = o.shaded ? 0.08f : 0.95f;
        for (const ModelViewItem& item : items) {
            if (!item.mesh || !item.wire) continue;
            const MeshData& m = *item.mesh;
            const std::size_t vc = m.vertex_count();
            std::vector<Projected> proj(vc);
            for (std::size_t i = 0; i < vc; ++i) proj[i] = project(cam, {m.positions[i * 3] + item.offset.x, m.positions[i * 3 + 1] + item.offset.y, m.positions[i * 3 + 2] + item.offset.z});
            for (const MeshSubmesh& sm : m.submeshes) {
                const std::size_t end = std::min<std::size_t>(std::size_t(sm.start) + sm.count, m.indices.size());
                for (std::size_t k = sm.start; k + 3 <= end; k += 3) {
                    std::uint32_t id[3] = {m.indices[k], m.indices[k + 1], m.indices[k + 2]};
                    if (id[0] >= vc || id[1] >= vc || id[2] >= vc) continue;
                    for (int e = 0; e < 3; ++e) {
                        const Projected &p0 = proj[id[e]], &p1 = proj[id[(e + 1) % 3]];
                        if (!p0.ok || !p1.ok) continue;
                        draw_line(bf, p0, p1, r, g, b, true);
                    }
                }
            }
        }
    }

    // Average S x S samples per pixel.
    out.rgba.resize(std::size_t(out.width) * std::size_t(out.height) * 4);
    const float norm = 1.0f / float(S * S);
    for (int y = 0; y < out.height; ++y) {
        for (int x = 0; x < out.width; ++x) {
            float r = 0, g = 0, b = 0;
            for (int sy = 0; sy < S; ++sy)
                for (int sx = 0; sx < S; ++sx) {
                    const std::size_t at = std::size_t(y * S + sy) * std::size_t(bf.w) + std::size_t(x * S + sx);
                    r += bf.r[at];
                    g += bf.g[at];
                    b += bf.b[at];
                }
            std::uint8_t* px = &out.rgba[(std::size_t(y) * std::size_t(out.width) + std::size_t(x)) * 4];
            px[0] = std::uint8_t(std::clamp(r * norm, 0.f, 1.f) * 255.0f + 0.5f);
            px[1] = std::uint8_t(std::clamp(g * norm, 0.f, 1.f) * 255.0f + 0.5f);
            px[2] = std::uint8_t(std::clamp(b * norm, 0.f, 1.f) * 255.0f + 0.5f);
            px[3] = 255;
        }
    }
    return out;
}

}  // namespace fa
