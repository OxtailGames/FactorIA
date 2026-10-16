// Gathers sprites, shapes, tilemaps, text and debug draw into quad lists.
#include <algorithm>
#include <cmath>

#include "fa/core/log.h"
#include "fa/scene/tilemap.h"
#include "frame.h"

namespace fa::render {

bool entity_active(const World& w, Entity e) { return w.active_in_hierarchy(e); }

float matrix_scale_x(const Mat4& m) {
    return std::sqrt(m.at(0, 0) * m.at(0, 0) + m.at(0, 1) * m.at(0, 1) + m.at(0, 2) * m.at(0, 2));
}

namespace {

float secondary_key(const Frame& f, const Mat4& m, bool ySort) {
    if (f.cam.perspective) return length(m.translation() - f.cam.position);
    return ySort ? m.translation().y : 0.0f;
}

void line_quad(const QuadEmitter& em, Vec2 a, Vec2 b, float t) {
    Vec2 d = b - a;
    float len = length(d);
    if (len < 1e-6f) return;
    Vec2 n = perp(d / len) * (t * 0.5f);
    auto v = [&](Vec2 p) {
        Vec3 w = em.xf(p.x, p.y);
        return Vertex2D{w.x, w.y, w.z, 0, 0, em.color, kModeTextured, 0};
    };
    em.list.quad(v(a + n), v(a - n), v(b - n), v(b + n));
}

constexpr int kMaxPolygonTips = 64;                      // Shape2D.sides / .points limit
constexpr int kMaxPolygonVerts = 2 * kMaxPolygonTips;    // a star has a tip and a notch per point

// A closed polygon (any winding, local units) drawn filled, as a triangle fan from `centre` (which must see every vertex:
// convex shapes and stars), or as an outline that grows INWARD like the rectangle's: every edge moves `t` towards the
// inside and the corners are mitred, so the tips stay sharp and the silhouette equals the filled one. `t` is capped at
// the distance from `centre` to the nearest edge, where the regular shapes (triangle about its incentre, diamond,
// polygon, star) are entirely stroke instead of inverting.
void polygon_shape(const QuadEmitter& em, const Vec2* p, int n, Vec2 centre, bool filled, float t) {
    auto v = [&](Vec2 q) { Vec3 w = em.xf(q.x, q.y); return Vertex2D{w.x, w.y, w.z, 0, 0, em.color, kModeTextured, 0}; };
    if (filled) {
        for (int i = 0; i < n; ++i) { const Vertex2D b = v(p[(i + 1) % n]); em.list.quad(v(centre), v(p[i]), b, b); }
        return;
    }
    float area2 = 0.0f;  // signed: > 0 = counter-clockwise, whose inside is on the left of every edge
    for (int i = 0; i < n; ++i) area2 += cross(p[i], p[(i + 1) % n]);
    Vec2 inward[kMaxPolygonVerts];  // unit normal of edge i -> i+1, pointing into the shape
    float cap = 1e30f;
    for (int i = 0; i < n; ++i) {
        const Vec2 e = p[(i + 1) % n] - p[i];
        const float len = length(e);
        if (len < 1e-6f) return;  // a zero-size shape has no outline
        inward[i] = perp(e) * ((area2 >= 0.0f ? 1.0f : -1.0f) / len);
        cap = std::min(cap, std::fabs(dot(centre - p[i], inward[i])));
    }
    t = std::min(t, cap);
    Vec2 inner[kMaxPolygonVerts];
    for (int i = 0; i < n; ++i) {
        const Vec2 a = inward[(i + n - 1) % n], b = inward[i];
        inner[i] = p[i] + (a + b) * (t / std::max(1.0f + dot(a, b), 1e-3f));
    }
    for (int i = 0; i < n; ++i) {
        const int j = (i + 1) % n;
        em.list.quad(v(p[i]), v(p[j]), v(inner[j]), v(inner[i]));
    }
}

// Screen-space anchoring: moves the entity's translation by anchor * design size.
void apply_anchor(Mat4& m, Vec2 anchor, const Frame& f) {
    m.at(3, 0) += anchor.x * float(f.targetW);
    m.at(3, 1) += anchor.y * float(f.targetH);
}

bool axis_aligned(const Mat4& m) {
    return std::fabs(m.at(0, 1)) < 1e-4f && std::fabs(m.at(1, 0)) < 1e-4f && std::fabs(m.at(0, 2)) < 1e-4f &&
           std::fabs(m.at(1, 2)) < 1e-4f && std::fabs(m.at(2, 0)) < 1e-4f && std::fabs(m.at(2, 1)) < 1e-4f;
}

}  // namespace

void update_animators(World& world, Frame& f, bool advance) {
    const float dt = advance ? f.dt : 0.0f;
    world.each<SpriteAnimator, Sprite>([&](Entity e, SpriteAnimator& a, Sprite& s) {
        if (!entity_active(world, e)) return;
        int count = std::max(1, a.lastFrame - a.firstFrame + 1);
        if (a.playing && dt > 0) {
            a.time += dt;
            int n = int(std::floor(a.time * std::max(0.0f, a.fps)));
            if (a.loop) {
                a.frame = a.firstFrame + (n % count);
            } else if (n >= count) {
                a.frame = a.lastFrame;
                a.playing = false;
            } else {
                a.frame = a.firstFrame + n;
            }
        } else if (a.frame < a.firstFrame || a.frame > a.lastFrame) {
            a.frame = a.firstFrame;
        }
        TextureAsset* tex = f.assets->texture(s.texture);
        int cols = std::max(1, a.columns), rows = std::max(1, a.rows);
        float fw = float(tex->width) / float(cols), fh = float(tex->height) / float(rows);
        int fr = std::max(0, a.frame);
        s.region = Rect{float(fr % cols) * fw, float((fr / cols) % rows) * fh, fw, fh};
    });
}

void gather_2d(World& world, Frame& f) {
    Assets& assets = *f.assets;
    auto pick = [&](RenderSpace sp) -> QuadList& { return sp == RenderSpace::Screen ? f.screen : f.world; };

    // ---- sprites ----
    world.each<Sprite>([&](Entity e, Sprite& s) {
        if (!entity_active(world, e) || s.color.a <= 0.0f) return;
        TextureAsset* tex = assets.texture(s.texture);
        Rect r = s.region;
        if (r.w <= 0 || r.h <= 0) r = Rect{0, 0, float(tex->width), float(tex->height)};
        Vec2 size = s.size;
        if (size.x <= 0 || size.y <= 0) {
            if (s.texture.empty()) size = {size.x > 0 ? size.x : 32.0f, size.y > 0 ? size.y : 32.0f};
            else size = {size.x > 0 ? size.x : r.w, size.y > 0 ? size.y : r.h};
        }
        Mat4 m = world.world_matrix(e);
        bool screen = s.space == RenderSpace::Screen;
        Rect clip;
        if (screen && !screen_clip(world, e, f, clip)) return;
        if (screen) apply_anchor(m, s.anchor, f);
        QuadList& list = pick(s.space);
        list.begin_item(s.layer, secondary_key(f, m, !screen), tex, s.pixelArt ? SamplerKind::Nearest : SamplerKind::Linear, s.blend, clip);
        QuadEmitter em{list, m, screen, pack_color(s.color), kModeTextured, 0};
        float tw = float(std::max(1, tex->width)), th = float(std::max(1, tex->height));
        float u0 = r.x / tw, u1 = (r.x + r.w) / tw, v0 = r.y / th, v1 = (r.y + r.h) / th;
        if (s.texture.empty()) { u0 = v0 = 0; u1 = v1 = 1; }
        if (s.flipX) std::swap(u0, u1);
        if (s.flipY) std::swap(v0, v1);
        em.rect(-s.pivot.x * size.x, -s.pivot.y * size.y, (1 - s.pivot.x) * size.x, (1 - s.pivot.y) * size.y, u0, v0, u1, v1);
        list.end_item();
        ++f.stats->sprites;
    });

    // ---- shapes ----
    world.each<Shape2D>([&](Entity e, Shape2D& s) {
        if (!entity_active(world, e) || s.color.a <= 0.0f) return;
        Mat4 m = world.world_matrix(e);
        bool screen = s.space == RenderSpace::Screen;
        Rect clip;
        if (screen && !screen_clip(world, e, f, clip)) return;
        if (screen) apply_anchor(m, s.anchor, f);
        QuadList& list = pick(s.space);
        list.begin_item(s.layer, secondary_key(f, m, false), assets.white(), SamplerKind::Nearest, s.blend, clip);
        QuadEmitter em{list, m, screen, pack_color(s.color), kModeTextured, 0};
        // Bounding box [bx0,bx1] x [by0,by1] in local units (y up; screen space flips it): pivot (0,0) = bottom-left.
        float bx0 = -s.pivot.x * s.size.x, bx1 = bx0 + s.size.x;
        float by0 = -s.pivot.y * s.size.y, by1 = by0 + s.size.y;
        float hw = s.size.x * 0.5f, hh = s.size.y * 0.5f;
        float t = std::max(0.0f, s.thickness);
        switch (s.shape) {
            case ShapeType::Rectangle:
                if (s.filled) {
                    em.rect(bx0, by0, bx1, by1, 0, 0, 1, 1);
                } else {
                    t = std::min(t, std::min(hw, hh));
                    em.rect(bx0, by1 - t, bx1, by1, 0, 0, 1, 1);
                    em.rect(bx0, by0, bx1, by0 + t, 0, 0, 1, 1);
                    em.rect(bx0, by0 + t, bx0 + t, by1 - t, 0, 0, 1, 1);
                    em.rect(bx1 - t, by0 + t, bx1, by1 - t, 0, 0, 1, 1);
                }
                break;
            case ShapeType::Circle: {
                float r = hw;  // diameter = size.x; the pivot refers to the circle's bounding square
                float cx = bx0 + r, cy = -s.pivot.y * s.size.x + r;
                em.mode = float(s.filled ? kModeCircle : kModeRing);
                em.aux = s.filled ? 0.0f : std::clamp(1.0f - t / std::max(r, 1e-4f), 0.0f, 1.0f);
                em.rect(cx - r, cy - r, cx + r, cy + r, -1, -1, 1, 1);
                break;
            }
            case ShapeType::Line:
                line_quad(em, {0, 0}, s.size, std::max(t, 0.5f));
                break;
            case ShapeType::Triangle: {
                const Vec2 pts[3] = {{bx0 + hw, by1}, {bx0, by0}, {bx1, by0}};  // apex, bottom-left, bottom-right
                // The incentre is equally far from all three edges, so the inward outline is as thick on every side.
                const float a = distance(pts[1], pts[2]), b = distance(pts[2], pts[0]), c = distance(pts[0], pts[1]);
                const float perimeter = a + b + c;
                const Vec2 incentre = perimeter > 1e-6f ? (pts[0] * a + pts[1] * b + pts[2] * c) / perimeter : pts[0];
                polygon_shape(em, pts, 3, incentre, s.filled, t);
                break;
            }
            case ShapeType::Diamond: {
                // Rhombus whose 4 points are the middles of the size box's edges.
                const float cx = bx0 + hw, cy = by0 + hh;
                const Vec2 pts[4] = {{cx, by1}, {bx0, cy}, {cx, by0}, {bx1, cy}};  // top, left, bottom, right
                polygon_shape(em, pts, 4, {cx, cy}, s.filled, t);
                break;
            }
            case ShapeType::Polygon:
            case ShapeType::Star: {
                // Vertices on the ellipse inscribed in the size box, counter-clockwise, the first one pointing up. A star
                // alternates tips (full radius) and notches (`innerRadius` of it).
                const bool star = s.shape == ShapeType::Star;
                const int n = std::clamp(star ? s.points : s.sides, 3, kMaxPolygonTips) * (star ? 2 : 1);
                const float notch = std::clamp(s.innerRadius, 0.0f, 1.0f), cx = bx0 + hw, cy = by0 + hh;
                Vec2 pts[kMaxPolygonVerts];
                for (int i = 0; i < n; ++i) {
                    const float ang = radians(90.0f) + kTau * float(i) / float(n), k = star && (i & 1) ? notch : 1.0f;
                    pts[i] = {cx + hw * k * std::cos(ang), cy + hh * k * std::sin(ang)};
                }
                polygon_shape(em, pts, n, {cx, cy}, s.filled, t);
                break;
            }
        }
        list.end_item();
        ++f.stats->shapes;
    });

    // ---- tilemaps ----
    world.each<Tilemap>([&](Entity e, Tilemap& tm) {
        if (!entity_active(world, e) || tm.tileSize.x <= 0 || tm.tileSize.y <= 0) return;
        // The same grid 2D physics collides with (rows form: the rows; flat form: width/height).
        const TilemapGrid grid = tilemap_grid(tm);
        if (grid.empty()) return;
        const int w = grid.width, h = grid.height;
        TextureAsset* tex = assets.texture(tm.tileset);
        float tw = tm.tileSize.x, th = tm.tileSize.y;
        // columns = 0 (the default) means: as many whole tiles as fit across the tileset image.
        int cols = std::max(1, tileset_columns(tm, tex->width));
        Mat4 m = world.world_matrix(e);
        QuadList& list = f.world;
        list.begin_item(tm.layer, secondary_key(f, m, false), tex, SamplerKind::Nearest);
        QuadEmitter em{list, m, false, pack_color(tm.color), kModeTextured, 0};
        float texW = float(std::max(1, tex->width)), texH = float(std::max(1, tex->height));
        bool cull = !f.cam.perspective;
        Rect view = f.cam.visible;
        view.x -= 1; view.y -= 1; view.w += 2; view.h += 2;
        for (int r = 0; r < h; ++r) {
            for (int c = 0; c < w; ++c) {
                int idx = grid.tiles[std::size_t(r) * std::size_t(w) + std::size_t(c)];
                if (idx < 0) continue;
                float x0 = float(c) * tw, y1 = -float(r) * th, x1 = x0 + tw, y0 = y1 - th;
                if (cull) {
                    Vec3 a = em.xf(x0, y0), b = em.xf(x1, y1);
                    Rect box{std::min(a.x, b.x), std::min(a.y, b.y), std::fabs(a.x - b.x), std::fabs(a.y - b.y)};
                    if (!box.overlaps(view)) continue;
                }
                float px = float(idx % cols) * tw, py = float(idx / cols) * th;
                em.rect(x0, y0, x1, y1, px / texW, py / texH, (px + tw) / texW, (py + th) / texH);
            }
        }
        list.end_item();
    });

    // ---- text ----
    world.each<Text>([&](Entity e, Text& t) {
        if (!entity_active(world, e) || t.text.empty() || t.color.a <= 0.0f || t.fontSize <= 0.0f) return;
        Mat4 m = world.world_matrix(e);
        bool screen = t.space == RenderSpace::Screen;
        Rect clip;
        if (screen && !screen_clip(world, e, f, clip)) return;
        float scale = matrix_scale_x(m);
        float ppu;
        if (screen) ppu = 1.0f;
        else if (f.cam.perspective) {
            float dist = std::max(0.1f, length(m.translation() - f.cam.position));
            ppu = (float(f.targetH) * 0.5f) / (std::tan(radians(f.cam.fov) * 0.5f) * dist);
        } else ppu = f.cam.pixelsPerUnit;
        float eff = ppu * scale;
        float rasterPx = t.fontSize * eff;
        // Layout in LOCAL units (the entity scale is applied by the matrix), so raster size uses eff.
        float localUnitsPerPx = t.fontSize / std::max(std::round(std::clamp(rasterPx, 4.0f, 400.0f)), 1.0f);
        TextLayout lay = f.fonts->layout(t, rasterPx, localUnitsPerPx);
        if (lay.quads.empty()) return;
        if (screen) apply_anchor(m, t.anchor, f);
        // Pixel-snap the anchor for crisp glyphs when the transform is axis aligned.
        if ((screen || !f.cam.perspective) && axis_aligned(m)) {
            float ox = screen ? 0.0f : f.cam.visible.x, oy = screen ? 0.0f : f.cam.visible.y;
            float k = screen ? 1.0f : f.cam.pixelsPerUnit;
            m.at(3, 0) = std::round((m.at(3, 0) - ox) * k) / k + ox;
            m.at(3, 1) = std::round((m.at(3, 1) - oy) * k) / k + oy;
        }
        QuadList& list = pick(t.space);
        list.begin_item(t.layer, secondary_key(f, m, false), f.fonts->atlas(), SamplerKind::Linear, BlendMode::Alpha, clip);
        QuadEmitter em{list, m, screen, pack_color(t.color), kModeGlyph, 0};
        for (const auto& q : lay.quads) em.rect(q.x0, q.y0, q.x1, q.y1, q.u0, q.v0, q.u1, q.v1);
        list.end_item();
        f.stats->textGlyphs += int(lay.quads.size());
    });
}

// ---------------------------------------------------------------------------
// Debug draw
// ---------------------------------------------------------------------------
void gather_debug(DebugDrawData& dd, Frame& f) {
    if (dd.empty()) return;
    Assets& assets = *f.assets;
    const bool persp = f.cam.perspective;
    const float px = persp ? 1.0f : 1.0f / std::max(f.cam.pixelsPerUnit, 1e-4f);  // one screen pixel in world units
    QuadList& wl = f.debugWorld;

    auto gl_line = [&](Vec3 a, Vec3 b, const Color& c) {
        std::uint32_t col = pack_color(c);
        f.debugLines.push_back({a.x, a.y, a.z, 0, 0, col, kModeTextured, 0});
        f.debugLines.push_back({b.x, b.y, b.z, 0, 0, col, kModeTextured, 0});
    };
    auto quad_line = [&](Vec3 a, Vec3 b, const Color& c, float thick) {
        wl.begin_item(0, 0, assets.white(), SamplerKind::Nearest);
        QuadEmitter em{wl, Mat4::identity(), false, pack_color(c), kModeTextured, 0};
        float t = std::max(thick * px, px);
        Vec2 d = (b - a).xy();
        float len = length(d);
        if (len > 1e-6f) {
            Vec2 n = perp(d / len) * (t * 0.5f);
            auto v = [&](Vec2 p, float z) { return Vertex2D{p.x, p.y, z, 0, 0, em.color, kModeTextured, 0}; };
            wl.quad(v(a.xy() + n, a.z), v(a.xy() - n, a.z), v(b.xy() - n, b.z), v(b.xy() + n, b.z));
        }
        wl.end_item();
    };
    auto line = [&](Vec3 a, Vec3 b, const Color& c, float thick) {
        if (persp) gl_line(a, b, c); else quad_line(a, b, c, thick);
    };

    for (const auto& l : dd.lines) line(l.a, l.b, l.c, l.thickness);
    for (const auto& r : dd.rects) {
        if (r.filled) {
            wl.begin_item(0, 0, assets.white(), SamplerKind::Nearest);
            QuadEmitter em{wl, Mat4::identity(), false, pack_color(r.c), kModeTextured, 0};
            em.rect(r.r.x, r.r.y, r.r.x + r.r.w, r.r.y + r.r.h, 0, 0, 1, 1);
            wl.end_item();
        } else {
            Vec3 a{r.r.x, r.r.y, 0}, b{r.r.x + r.r.w, r.r.y, 0}, c{r.r.x + r.r.w, r.r.y + r.r.h, 0}, d{r.r.x, r.r.y + r.r.h, 0};
            line(a, b, r.c, 1); line(b, c, r.c, 1); line(c, d, r.c, 1); line(d, a, r.c, 1);
        }
    }
    for (const auto& c : dd.circles) {
        if (c.filled && !persp) {
            wl.begin_item(0, 0, assets.white(), SamplerKind::Nearest);
            QuadEmitter em{wl, Mat4::identity(), false, pack_color(c.c), kModeCircle, 0};
            em.rect(c.center.x - c.radius, c.center.y - c.radius, c.center.x + c.radius, c.center.y + c.radius, -1, -1, 1, 1);
            wl.end_item();
        } else {
            const int seg = 48;
            for (int i = 0; i < seg; ++i) {
                float a0 = float(i) / seg * kTau, a1 = float(i + 1) / seg * kTau;
                line({c.center.x + std::cos(a0) * c.radius, c.center.y + std::sin(a0) * c.radius, 0},
                     {c.center.x + std::cos(a1) * c.radius, c.center.y + std::sin(a1) * c.radius, 0}, c.c, 1);
            }
        }
    }
    // Text (screen space, top-left origin).
    for (const auto& t : dd.texts) {
        Text tx;
        tx.text = t.text;
        tx.fontSize = t.size;
        tx.color = t.c;
        tx.pivot = {0, 1};
        TextLayout lay = f.fonts->layout(tx, t.size, 1.0f);
        f.debugScreen.begin_item(0, 0, f.fonts->atlas(), SamplerKind::Linear);
        QuadEmitter em{f.debugScreen, Mat4::translate({std::round(t.pos.x), std::round(t.pos.y), 0}), true,
                       pack_color(t.c), kModeGlyph, 0};
        for (const auto& q : lay.quads) em.rect(q.x0, q.y0, q.x1, q.y1, q.u0, q.v0, q.u1, q.v1);
        f.debugScreen.end_item();
        f.stats->textGlyphs += int(lay.quads.size());
    }
}

}  // namespace fa::render
