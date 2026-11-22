// The CPU side of the 2D GI field (gi2d.h): the settings, the geometry of a camera's field, and the emitters and occluders of its
// rectangle as triangles in field texel coordinates. Nothing here touches the GPU, so the tests run it without one.
#include <algorithm>
#include <cmath>
#include <format>
#include <limits>
#include <utility>

#include "fa/scene/bounds.h"
#include "fa/scene/tilemap.h"

#include "color_space.h"
#include "frame.h"
#include "gi2d.h"

namespace fa::render {

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }

constexpr std::size_t kMaxVertices = std::size_t(kGi2dMaxQuads) * 6;

// An albedo is a fraction of the light a blocker throws back: 0..1 (the bounce's loop gain is bounded by it, kGi2dMaxBounceGain).
Color albedo_of(Color c) {
    c.r = std::clamp(finite_or(c.r, 0.0f), 0.0f, 1.0f);
    c.g = std::clamp(finite_or(c.g, 0.0f), 0.0f, 1.0f);
    c.b = std::clamp(finite_or(c.b, 0.0f), 0.0f, 1.0f);
    c.a = std::clamp(finite_or(c.a, 1.0f), 0.0f, 1.0f);
    return c;
}

// A batch's identity: what two runs must share to be drawn by one call.
bool same_state(const GiBatch& a, const GiBatch& b) {
    return a.mode == b.mode && a.tex == b.tex && a.sampler == b.sampler && a.fix == b.fix && a.threshold == b.threshold;
}

// Appends triangles to one vertex list (an emission list or an occluder list) in the field's texel coordinates.
struct Builder {
    const Gi2dGeometry& g;
    std::vector<GiVertex>& verts;
    std::vector<GiBatch>& batches;
    int& dropped;
    double minX, minY, maxX, maxY;  // the field's world rectangle

    Builder(const Gi2dGeometry& geom, std::vector<GiVertex>& v, std::vector<GiBatch>& b, int& d)
        : g(geom), verts(v), batches(b), dropped(d), minX(geom.originX), minY(geom.originY),
          maxX(geom.originX + geom.world_w()), maxY(geom.originY + geom.world_h()) {}

    // True when the world box touches the field (a texel of slack: a bilinear read near the edge sees what lies just outside).
    bool touches(double x0, double y0, double x1, double y1) const {
        return x1 >= minX - g.texel && x0 <= maxX + g.texel && y1 >= minY - g.texel && y0 <= maxY + g.texel;
    }
    void state(const GiBatch& key) {
        if (!batches.empty() && same_state(batches.back(), key)) return;
        GiBatch b = key;
        b.first = std::uint32_t(verts.size());
        b.count = 0;
        batches.push_back(b);
    }
    // True when not even one more quad fits (what the tilemap loop checks to stop early).
    bool full() const { return verts.size() + 6 > kMaxVertices; }
    bool room(std::size_t vertices) {
        if (verts.size() + vertices <= kMaxVertices) return true;
        ++dropped;
        return false;
    }
    GiVertex vertex(Vec3 world, float u, float v, const Color& c) const {
        return GiVertex{float((double(world.x) - g.originX) / g.texel),
                        float((double(world.y) - g.originY) / g.texel),
                        u,
                        v,
                        c.r,
                        c.g,
                        c.b,
                        c.a};
    }
    // A quad with its corners in order around it (uv per corner).
    void quad(const GiBatch& key, const Vec3 p[4], const float uv[4][2], const Color& c) {
        double x0 = p[0].x, x1 = p[0].x, y0 = p[0].y, y1 = p[0].y;
        for (int i = 1; i < 4; ++i) {
            x0 = std::min<double>(x0, p[i].x);
            x1 = std::max<double>(x1, p[i].x);
            y0 = std::min<double>(y0, p[i].y);
            y1 = std::max<double>(y1, p[i].y);
        }
        if (!std::isfinite(x0 + x1 + y0 + y1) || !touches(x0, y0, x1, y1) || !room(6)) return;
        state(key);
        const GiVertex v[4] = {vertex(p[0], uv[0][0], uv[0][1], c), vertex(p[1], uv[1][0], uv[1][1], c),
                               vertex(p[2], uv[2][0], uv[2][1], c), vertex(p[3], uv[3][0], uv[3][1], c)};
        for (int i : {0, 1, 2, 0, 2, 3}) verts.push_back(v[i]);
        batches.back().count += 6;
    }
    void triangle(const GiBatch& key, Vec3 a, Vec3 b, Vec3 c, const Color& col) {
        if (!room(3)) return;
        state(key);
        for (const Vec3& p : {a, b, c}) verts.push_back(vertex(p, 0.0f, 0.0f, col));
        batches.back().count += 3;
    }
};

float cross2(Vec2 o, Vec2 a, Vec2 b) { return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x); }

bool in_triangle(Vec2 p, Vec2 a, Vec2 b, Vec2 c) {
    const float d1 = cross2(a, b, p), d2 = cross2(b, c, p), d3 = cross2(c, a, p);
    const bool neg = d1 < 0 || d2 < 0 || d3 < 0, pos = d1 > 0 || d2 > 0 || d3 > 0;
    return !(neg && pos);
}

// A sprite's local rectangle and texture coordinates (the same cut as the quad pass: region in pixels of the texture, y down, flips swap).
struct SpriteQuad {
    Vec3 p[4];
    float uv[4][2];
};
SpriteQuad sprite_quad(const Sprite& s, TextureAsset* tex, const Mat4& m) {
    Rect r = s.region;
    if (r.w <= 0 || r.h <= 0) r = Rect{0, 0, float(tex->width), float(tex->height)};
    Vec2 size = s.size;
    if (size.x <= 0 || size.y <= 0) {
        if (s.texture.empty())
            size = {size.x > 0 ? size.x : 32.0f, size.y > 0 ? size.y : 32.0f};
        else
            size = {size.x > 0 ? size.x : r.w, size.y > 0 ? size.y : r.h};
    }
    const float x0 = -s.pivot.x * size.x, x1 = (1.0f - s.pivot.x) * size.x, y0 = -s.pivot.y * size.y,
                y1 = (1.0f - s.pivot.y) * size.y;
    float u0 = 0, v0 = 0, u1 = 1, v1 = 1;
    if (!s.texture.empty()) {
        const Vec2 lo = tex->uv(r.x, r.y), hi = tex->uv(r.x + r.w, r.y + r.h);
        u0 = lo.x;
        v0 = lo.y;
        u1 = hi.x;
        v1 = hi.y;
    }
    if (s.flipX) std::swap(u0, u1);
    if (s.flipY) std::swap(v0, v1);
    SpriteQuad q{};
    // Bottom-left, bottom-right, top-right, top-left of the sprite (the top of the picture is the top of the region: v0).
    q.p[0] = m.transform_point({x0, y0, 0.0f});
    q.p[1] = m.transform_point({x1, y0, 0.0f});
    q.p[2] = m.transform_point({x1, y1, 0.0f});
    q.p[3] = m.transform_point({x0, y1, 0.0f});
    const float uv[4][2] = {{u0, v1}, {u1, v1}, {u1, v0}, {u0, v0}};
    std::copy(&uv[0][0], &uv[0][0] + 8, &q.uv[0][0]);
    return q;
}

SamplerKind sampler_of(bool pixelArt) { return pixelArt ? SamplerKind::Nearest : SamplerKind::Linear; }

// The source position (fractions of the tile image, y down) shown at a corner of the tile (fractions of the tile, y down): as scene2d.cpp.
Vec2 tile_source(int flags, float px, float py) {
    if (flags & kTileFlipY) py = 1.0f - py;
    if (flags & kTileFlipX) px = 1.0f - px;
    if (flags & kTileTranspose) std::swap(px, py);
    return {px, py};
}

bool glows(const Color& c, float intensity) {
    return intensity > 0.0f && std::isfinite(intensity) && (c.r > 0.0f || c.g > 0.0f || c.b > 0.0f);
}

}  // namespace

Gi2dSettings gi2d_settings(World& world) {
    Gi2dSettings out;
    bool found = false;
    world.each<GlobalIllumination2D>([&](Entity e, GlobalIllumination2D& c) {
        if (found || !c.enabled || !entity_active(world, e)) return;
        found = true;
        out.on = true;
        out.quality = c.quality;
        out.intensity = std::clamp(finite_or(c.intensity, 1.0f), 0.0f, 16.0f);
        out.bounce = std::clamp(finite_or(c.bounce, 0.5f), 0.0f, 1.0f);
        out.range = std::clamp(finite_or(c.range, 512.0f), 1.0f, 100000.0f);
        out.resolutionScale = std::clamp(finite_or(c.resolutionScale, 0.5f), 0.1f, 1.0f);
    });
    return out;
}

Gi2dGeometry gi2d_geometry(const Rect& visible, float pixelsPerUnit, const Gi2dSettings& s) {
    Gi2dGeometry g;
    if (!(visible.w > 0.0f) || !(visible.h > 0.0f) || !std::isfinite(visible.x + visible.y + visible.w + visible.h) ||
        !(pixelsPerUnit > 0.0f) || !std::isfinite(pixelsPerUnit))
        return g;
    const double margin = std::clamp(double(finite_or(s.range, 512.0f)), 1.0, 100000.0);
    const double scale = std::clamp(double(finite_or(s.resolutionScale, 0.5f)), 0.1, 1.0);
    const double extW = double(visible.w) + 2.0 * margin, extH = double(visible.h) + 2.0 * margin;
    // The texel is a float's value, so every machine computes the same origin and the same number of texels.
    double texel = double(float(1.0 / (double(pixelsPerUnit) * scale)));
    auto count = [&](double extent, double t) { return std::ceil(extent / t) + 2.0; };
    double cw = count(extW, texel), ch = count(extH, texel);
    if (cw > kGi2dMaxSize || ch > kGi2dMaxSize) {
        g.capped = true;
        texel = double(float(std::max(extW, extH) / double(kGi2dMaxSize - 3)));
        cw = count(extW, texel);
        ch = count(extH, texel);
    }
    g.texel = texel;
    // Rounded up to a multiple of kGi2dSizeStep (2048 is one): a zoom that adds a few texels does not change the size, so the images and the
    // bounce's history are kept until the view has grown by a whole step.
    auto stepped = [](double n) {
        const int c = int(std::clamp(n, double(kGi2dMinSize), double(kGi2dMaxSize)));
        return (c + kGi2dSizeStep - 1) / kGi2dSizeStep * kGi2dSizeStep;
    };
    g.width = stepped(cw);
    g.height = stepped(ch);
    g.originX = std::floor((double(visible.x) - margin) / texel) * texel;
    g.originY = std::floor((double(visible.y) - margin) / texel) * texel;
    // kGi2dFieldImages images of the field's size alive together, 8 bytes a texel (never near 2^64: the sides are at most 2048).
    g.bytes = std::uint64_t(g.width) * std::uint64_t(g.height) * 8u * std::uint64_t(kGi2dFieldImages);
    g.valid = true;
    return g;
}

Gi2dQualityCounts gi2d_quality_counts(GI2DQuality q) {
    switch (q) {
        case GI2DQuality::Low: return {4, 3, 20};
        case GI2DQuality::High: return {2, 5, 40};
        case GI2DQuality::Medium: break;
    }
    return {2, 4, 28};
}

double Gi2dCascadePlan::interval_end(int i) const {
    if (i < 0) return 0.0;
    return 2.0 * double(spacing0) * (std::pow(4.0, double(i) + 1.0) - 1.0) / 3.0;
}
double Gi2dCascadePlan::interval_start(int i) const { return interval_end(i - 1); }

Gi2dCascadePlan gi2d_cascade_plan(GI2DQuality q, const Gi2dGeometry& g, bool mobile) {
    Gi2dCascadePlan p;
    if (!g.valid || g.width <= 0 || g.height <= 0) {
        p.why = "the field has no size";
        return p;
    }
    const Gi2dQualityCounts c = gi2d_quality_counts(q);
    p.spacing0 = c.spacing0;
    p.steps = c.steps;
    p.rays0 = c.spacing0 * c.spacing0;
    p.gridW = g.width / c.spacing0;
    p.gridH = g.height / c.spacing0;
    // As many cascades as the quality allows, and no more than it takes for the last interval to reach across the field.
    const double diagonal = std::hypot(double(g.width), double(g.height));
    int n = 1;
    while (n < c.cascades && p.interval_end(n - 1) < diagonal) ++n;
    p.cascades = n;
    p.reach = p.interval_end(n - 1);
    const std::uint64_t texels = std::uint64_t(g.width) * std::uint64_t(g.height);
    p.persistentBytes = texels * 8u * 3u + std::uint64_t(p.gridW) * std::uint64_t(p.gridH) * 8u * 2u;
    p.totalBytes = g.bytes + std::uint64_t(p.gridW) * std::uint64_t(p.gridH) * 8u * 2u;
    const std::uint64_t budget = mobile ? kGi2dMaxBytesMobile : kGi2dMaxBytes;
    const int maxCascades = mobile ? kGi2dMaxCascadesMobile : kGi2dMaxCascades;
    const char* const names[3] = {"low", "medium", "high"};
    const char* const name = names[q == GI2DQuality::Low ? 0 : q == GI2DQuality::High ? 2 : 1];
    if (c.cascades > maxCascades) {
        p.why = std::format(
            "GlobalIllumination2D.quality \"{}\" runs up to {} cascade passes and this platform's budget is {}. "
            "Hint: set quality to \"medium\" or \"low\".",
            name, c.cascades, maxCascades);
        return p;
    }
    if (p.totalBytes > budget) {
        p.why = std::format(
            "a {}x{} global illumination field needs about {} MiB of GPU memory and this platform's budget is {} MiB. "
            "Hint: lower GlobalIllumination2D.range or resolutionScale (quality \"{}\" does not change the memory "
            "much).{}",
            g.width, g.height, (p.totalBytes + (1u << 20) - 1) >> 20, budget >> 20, name,
            mobile
                ? " On a phone or a browser, on a view of 1920 x 1080 pixels the defaults (range 512, resolutionScale "
                  "0.5) are over this budget, and range 128 or resolutionScale 0.25 fit."
                : "");
        return p;
    }
    p.ok = true;
    return p;
}

std::string gi2d_total_budget_why(std::uint64_t usedBytes, const Gi2dCascadePlan& plan, bool mobile) {
    const std::uint64_t budget = mobile ? kGi2dMaxTotalBytesMobile : kGi2dMaxTotalBytes;
    constexpr std::uint64_t kMax = std::numeric_limits<std::uint64_t>::max();
    const std::uint64_t sum = usedBytes > kMax - plan.totalBytes ? kMax : usedBytes + plan.totalBytes;  // saturating
    if (sum <= budget) return {};
    return std::format("the global illumination fields of all the 2D cameras of a frame need about {} MiB of GPU "
                       "memory and this platform's budget for "
                       "all of them is {} MiB. Hint: lower GlobalIllumination2D.range or resolutionScale, or draw "
                       "fewer 2D cameras with it (the cameras "
                       "after the budget is used up are drawn without GI).",
                       sum == kMax ? std::uint64_t(kMax >> 20) : (sum + (1u << 20) - 1) >> 20, budget >> 20);
}

std::vector<std::uint32_t> gi2d_triangulate(const std::vector<Vec2>& pts, std::size_t* work) {
    std::vector<std::uint32_t> out;
    const std::size_t n = pts.size();
    if (n < 3 || n > kGi2dMaxPolygonPoints) return out;
    std::size_t ownWork = kGi2dMaxTriangulateWork;
    std::size_t& left = work ? *work : ownWork;
    for (const Vec2& p : pts)
        if (!std::isfinite(p.x) || !std::isfinite(p.y)) return out;
    double area = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        const Vec2 a = pts[i], b = pts[(i + 1) % n];
        area += double(a.x) * double(b.y) - double(b.x) * double(a.y);
    }
    if (area == 0.0) return out;
    const bool ccw = area > 0.0;
    std::vector<std::uint32_t> idx(n);
    for (std::size_t i = 0; i < n; ++i) idx[i] = std::uint32_t(i);
    // Ear clipping: a polygon with crossing edges ends when a whole turn clips nothing (the rest is left out), and the point-in-triangle tests
    // (what makes it up to n^3) are counted against `left`: when it is spent the cutting stops with what is cut. A count, so the result is the
    // same on a slow machine and a fast one.
    std::size_t guard = 0;
    while (idx.size() > 3 && left > 0) {
        bool clipped = false;
        const std::size_t m = idx.size();
        for (std::size_t i = 0; i < m; ++i) {
            const std::uint32_t ia = idx[(i + m - 1) % m], ib = idx[i], ic = idx[(i + 1) % m];
            const Vec2 a = pts[ia], b = pts[ib], c = pts[ic];
            const float cr = cross2(a, b, c);
            if (ccw ? cr <= 0.0f : cr >= 0.0f) continue;  // a reflex (or flat) corner is no ear
            bool inside = false;
            for (std::size_t k = 0; k < m && !inside; ++k) {
                if (left > 0) --left;
                const std::uint32_t ik = idx[k];
                if (ik == ia || ik == ib || ik == ic) continue;
                const Vec2 p = pts[ik];
                if ((p.x == a.x && p.y == a.y) || (p.x == b.x && p.y == b.y) || (p.x == c.x && p.y == c.y)) continue;
                inside = in_triangle(p, a, b, c);
            }
            if (inside) continue;
            out.insert(out.end(), {ia, ib, ic});
            idx.erase(idx.begin() + std::ptrdiff_t(i));
            clipped = true;
            break;
        }
        if (!clipped || ++guard > n) break;
    }
    if (idx.size() == 3) out.insert(out.end(), {idx[0], idx[1], idx[2]});
    return out;
}

void gi2d_gather(World& world, Frame& fr, const Gi2dGeometry& g, Gi2dGather& out) {
    out = Gi2dGather{};
    if (!g.valid || !fr.assets) return;
    Assets& assets = *fr.assets;
    Builder emit(g, out.emitVerts, out.emitBatches, out.dropped);
    Builder occ(g, out.occVerts, out.occBatches, out.dropped);
    std::size_t triangulateLeft = kGi2dMaxTriangulateWork;  // for every polygon of this gather together
    const bool linear = fr.linear;
    const Color grey =
        to_scene(Color{0.5f, 0.5f, 0.5f, 1.0f}, linear);  // the albedo of a caster that has no Sprite to take it from

    // ---- sprites that glow ----
    world.each<Sprite>([&](Entity e, Sprite& s) {
        if (s.space == RenderSpace::Screen || !glows(s.emissive, s.emissiveIntensity)) return;
        if (!entity_active(world, fr, e) || !fr.mask.draws(world, e)) return;
        const Color tinted = s.color * inherited_tint(world, fr, e);
        if (tinted.a <= 0.0f) return;
        const bool mapped = !s.emissiveMap.empty();
        TextureAsset* tex = assets.texture(mapped ? s.emissiveMap : s.texture);
        if (!tex || !tex->gpu_view().id) return;
        const Color em = to_scene(s.emissive, linear);
        const float k = s.emissiveIntensity;
        const Color col{em.r * k, em.g * k, em.b * k, tinted.a};
        GiBatch key;
        key.mode = mapped ? 0 : 3;
        key.tex = tex;
        key.sampler = sampler_of(s.pixelArt);
        key.fix = tex->tex_fix(linear, true);
        // The emission map is laid out like the texture: its own size is what the region is cut from.
        const SpriteQuad q = sprite_quad(s, tex, drawn_visual_matrix(world, e));
        const std::size_t before = out.emitVerts.size();
        emit.quad(key, q.p, q.uv, col);
        if (out.emitVerts.size() != before) ++out.emissiveSprites;
    });

    // ---- tilemaps: emissive cells and solid cells ----
    world.each<Tilemap>([&](Entity e, Tilemap& tm) {
        const bool emits = glows(tm.emissive, tm.emissiveIntensity);
        std::vector<int> solid;
        if (tm.occludesLight && tm.solidTiles.is_array())
            for (const Json& j : tm.solidTiles)
                if (j.is_number()) solid.push_back(tile_index(int(std::clamp(j.get<double>(), -1.0, 1.0e9))));
        std::sort(solid.begin(), solid.end());
        if (!emits && solid.empty()) return;
        if (tm.tileSize.x <= 0 || tm.tileSize.y <= 0 || !entity_active(world, fr, e) || !fr.mask.draws(world, e))
            return;
        const TilemapSize grid = tilemap_size(tm);
        if (grid.empty()) return;
        const Color tmColor = tm.color * inherited_tint(world, fr, e);
        if (tmColor.a <= 0.0f) return;
        TextureAsset* tex = assets.texture(tm.tileset);
        if (!tex || !tex->gpu_view().id) return;
        const float tw = tm.tileSize.x, th = tm.tileSize.y;
        const int cols = std::max(1, tileset_columns(tm, tex->width));
        const Mat4 m = drawn_visual_matrix(world, e);
        const bool iso = tilemap_isometric(tm);
        const float isoHw = tw * 0.5f, isoHh = tilemap_ground_height(tm) * 0.5f;
        // The cells whose picture can reach the field: its corners in cell space, widened by one picture.
        int c0 = 0, c1 = grid.width - 1, r0 = 0, r1 = grid.height - 1;
        {
            float lm[4];
            tilemap_local_to_cell(tm, lm);
            const Mat4 inv = m.inverse();
            const double wx0 = g.originX - double(tw), wy0 = g.originY - double(th);
            const double wx1 = g.originX + g.world_w() + double(tw), wy1 = g.originY + g.world_h() + double(th);
            float minA = 1e30f, maxA = -1e30f, minB = 1e30f, maxB = -1e30f;
            for (int k = 0; k < 4; ++k) {
                const Vec3 q = inv.transform_point({float((k & 1) ? wx1 : wx0), float((k & 2) ? wy1 : wy0), 0.0f});
                const float a = lm[0] * q.x + lm[1] * q.y, b = lm[2] * q.x + lm[3] * q.y;
                minA = std::min(minA, a);
                maxA = std::max(maxA, a);
                minB = std::min(minB, b);
                maxB = std::max(maxB, b);
            }
            if (std::isfinite(minA + maxA + minB + maxB)) {
                c0 = std::max(0, int(std::floor(std::max(minA, -1.0e6f))) - 1);
                c1 = std::min(grid.width - 1, int(std::ceil(std::min(maxA, 1.0e6f))) + 1);
                r0 = std::max(0, int(std::floor(std::max(minB, -1.0e6f))) - 1);
                r1 = std::min(grid.height - 1, int(std::ceil(std::min(maxB, 1.0e6f))) + 1);
            }
        }
        const Color glow = to_scene(tm.emissive, linear);
        const Color glowCol{glow.r * tm.emissiveIntensity, glow.g * tm.emissiveIntensity, glow.b * tm.emissiveIntensity,
                            tmColor.a};
        const Color albedo = albedo_of(to_scene(tmColor, linear));
        GiBatch emitKey;
        emitKey.mode = 3;
        emitKey.tex = tex;
        emitKey.sampler = SamplerKind::Nearest;
        emitKey.fix = tex->tex_fix(linear, true);
        GiBatch occKey = emitKey;
        occKey.mode = 4;
        bool full = false;  // every list this tilemap writes is at kGi2dMaxQuads: the rest of the cells cannot be drawn
        for (int r = r0; r <= r1 && !full; ++r) {
            for (int c = c0; c <= c1; ++c) {
                const int value = tilemap_tile_at(tm, grid, c, r);
                if (value < 0) continue;
                const int idx = tile_index(value), flags = tile_flags(value);
                const bool isSolid = !solid.empty() && std::binary_search(solid.begin(), solid.end(), idx);
                if (!emits && !isSolid) continue;
                if ((!emits || emit.full()) && (!isSolid || occ.full())) {
                    ++out.dropped;  // this cell and every cell after it: not walked (a map of tiny cells would take the whole frame)
                    full = true;
                    break;
                }
                float x0, x1, y0, y1;
                if (iso) {
                    x0 = float(c - r) * isoHw - isoHw;
                    x1 = x0 + tw;
                    y1 = -float(c + r) * isoHh + tm.groundOffset;
                    y0 = y1 - th;
                } else {
                    x0 = float(c) * tw;
                    y1 = -float(r) * th;
                    x1 = x0 + tw;
                    y0 = y1 - th;
                }
                const float px = float(tm.margin) + float(idx % cols) * (tw + float(tm.spacing));
                const float py = float(tm.margin) + float(idx / cols) * (th + float(tm.spacing));
                // Corners top-left, bottom-left, bottom-right, top-right of the tile show these spots of its image.
                static const float kCorner[4][2] = {{0, 0}, {0, 1}, {1, 1}, {1, 0}};
                float uv[4][2];
                for (int k = 0; k < 4; ++k) {
                    const Vec2 sp = tile_source(flags, kCorner[k][0], kCorner[k][1]);
                    const Vec2 t = tex->uv(px + sp.x * tw, py + sp.y * th);
                    uv[k][0] = t.x;
                    uv[k][1] = t.y;
                }
                const Vec3 p[4] = {m.transform_point({x0, y1, 0.0f}), m.transform_point({x0, y0, 0.0f}),
                                   m.transform_point({x1, y0, 0.0f}), m.transform_point({x1, y1, 0.0f})};
                if (emits) {
                    const std::size_t before = out.emitVerts.size();
                    emit.quad(emitKey, p, uv, glowCol);
                    if (out.emitVerts.size() != before) ++out.emissiveTiles;
                }
                if (isSolid) {
                    const std::size_t before = out.occVerts.size();
                    occ.quad(occKey, p, uv, albedo);
                    if (out.occVerts.size() != before) ++out.solidTiles;
                }
            }
        }
    });

    // ---- lights: a small emitting disc each ----
    const double minRadius = g.texel;
    world.each<Light2D>([&](Entity e, Light2D& l) {
        if (l.type != Light2DType::Point || !(l.intensity > 0.0f) || !std::isfinite(l.intensity) ||
            !entity_active(world, e))
            return;
        const Vec3 pos = world.world_matrix(e).translation();
        const double radius = std::max(double(finite_or(l.size, 0.0f)), minRadius);
        const Color lc = to_scene(l.color, linear);
        const Color col{lc.r * l.intensity, lc.g * l.intensity, lc.b * l.intensity, 1.0f};
        GiBatch key;
        key.mode = 2;
        const Vec3 p[4] = {{float(pos.x - radius), float(pos.y - radius), 0.0f},
                           {float(pos.x + radius), float(pos.y - radius), 0.0f},
                           {float(pos.x + radius), float(pos.y + radius), 0.0f},
                           {float(pos.x - radius), float(pos.y + radius), 0.0f}};
        static const float kDisc[4][2] = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}};
        const std::size_t before = out.emitVerts.size();
        emit.quad(key, p, kDisc, col);
        if (out.emitVerts.size() != before) ++out.lights;
    });

    // ---- ShadowCaster2D: boxes, polygons and the alpha of a sprite ----
    world.each<ShadowCaster2D>([&](Entity e, ShadowCaster2D& sc) {
        if (!sc.enabled || !entity_active(world, fr, e) || !fr.mask.draws(world, e)) return;
        const Mat4 m = drawn_visual_matrix(world, e);
        const Sprite* sprite = world.get<Sprite>(e);
        Color albedo = grey;
        if (sprite) albedo = albedo_of(to_scene(sprite->color, linear));
        albedo.a = 1.0f;
        GiBatch solidKey;
        solidKey.mode = 1;
        if (sc.shape == ShadowCaster2DShape::Box) {
            const float hx = std::max(0.0f, finite_or(sc.size.x, 0.0f)) * 0.5f,
                        hy = std::max(0.0f, finite_or(sc.size.y, 0.0f)) * 0.5f;
            if (hx <= 0.0f || hy <= 0.0f) {
                ++out.skippedCasters;
                return;
            }
            const Vec3 p[4] = {m.transform_point({-hx, -hy, 0.0f}), m.transform_point({hx, -hy, 0.0f}),
                               m.transform_point({hx, hy, 0.0f}), m.transform_point({-hx, hy, 0.0f})};
            static const float kZero[4][2] = {};
            const std::size_t before = out.occVerts.size();
            occ.quad(solidKey, p, kZero, albedo);
            if (out.occVerts.size() != before) ++out.boxes;
        } else if (sc.shape == ShadowCaster2DShape::Polygon) {
            const std::size_t count = sc.points.size() / 2;
            if (count < 3 || count > kGi2dMaxPolygonPoints) {
                ++out.skippedCasters;
                return;
            }
            const float* d = sc.points.cdata();
            std::vector<Vec2> pts(count);
            for (std::size_t i = 0; i < count; ++i) pts[i] = {d[i * 2], d[i * 2 + 1]};
            const std::vector<std::uint32_t> tris = gi2d_triangulate(pts, &triangulateLeft);
            if (tris.empty()) {
                ++out.skippedCasters;
                return;
            }
            const std::size_t before = out.occVerts.size();
            for (std::size_t i = 0; i + 2 < tris.size(); i += 3) {
                const Vec2 a = pts[tris[i]], b = pts[tris[i + 1]], c = pts[tris[i + 2]];
                occ.triangle(solidKey, m.transform_point({a.x, a.y, 0.0f}), m.transform_point({b.x, b.y, 0.0f}),
                             m.transform_point({c.x, c.y, 0.0f}), albedo);
            }
            if (out.occVerts.size() != before) ++out.polygons;
        } else {
            if (!sprite || sprite->space == RenderSpace::Screen) {
                ++out.skippedCasters;
                return;
            }
            TextureAsset* tex = assets.texture(sprite->texture);
            if (!tex || !tex->gpu_view().id) return;
            GiBatch key;
            key.mode = 5;
            key.tex = tex;
            key.sampler = sampler_of(sprite->pixelArt);
            key.fix = tex->tex_fix(linear, true);
            key.threshold = std::clamp(finite_or(sc.alphaThreshold, 0.5f), 0.0f, 1.0f);
            const SpriteQuad q = sprite_quad(*sprite, tex, m);
            const std::size_t before = out.occVerts.size();
            occ.quad(key, q.p, q.uv, albedo);
            if (out.occVerts.size() != before) ++out.spriteCasters;
        }
    });
}

}  // namespace fa::render
