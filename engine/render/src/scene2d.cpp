// Gathers sprites, shapes, tilemaps, text and debug draw into quad lists.
#include <algorithm>
#include <cmath>

#include "fa/core/log.h"
#include "fa/scene/bounds.h"
#include "fa/scene/text_fit.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/ui_rect.h"
#include "frame.h"
#include "nine_slice.h"

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

// Rounded rectangle / circle drawn by the SDF shader path (mode kModeShape): corner radius, soft edge, gradient. `cx, cy` is
// the centre and `hw, hh` the half size in local units. The quad is padded by half the softness: the soft edge fades from
// inside the outline to that far outside it. Vertex fields: see Vertex2D and the header of shaders/quad.glsl.
void sdf_shape(QuadEmitter& em, const Shape2D& s, float cx, float cy, float hw, float hh, float radius, float t) {
    const float soft = std::max(0.0f, s.softness);
    const float pad = soft * 0.5f;
    hw = std::max(hw, 1e-3f);
    hh = std::max(hh, 1e-3f);
    em.mode = float(kModeShape);
    if (!s.filled) {
        em.aux = -2.0f - std::clamp(t, 0.0f, std::min(hw, hh));  // outline of that thickness, growing inward
    } else if (s.gradient == ShapeGradient::Linear) {
        float a = std::fmod(radians(s.gradientAngle), kTau);
        if (a < 0.0f) a += kTau;
        em.aux = a;
    } else if (s.gradient == ShapeGradient::Radial) {
        em.aux = 10.0f;
    } else {
        em.aux = -1.0f;
    }
    const std::uint32_t c2 = pack_color(s.color2);
    const std::uint16_t rb = float_to_half_bits(radius), sb = float_to_half_bits(soft);
    const float ux = (hw + pad) / hw, uy = (hh + pad) / hh;
    // rect() gives its (x0, y1) corner the uv (u0, v0): v0 is the uv of the top edge, so uv.y grows upwards like local y.
    const std::size_t first = em.list.raw.size();
    em.rect(cx - hw - pad, cy - hh - pad, cx + hw + pad, cy + hh + pad, -ux, uy, ux, -uy);
    for (std::size_t i = first; i < em.list.raw.size(); ++i) {
        Vertex2D& v = em.list.raw[i];
        v.color2 = c2;
        v.halfW = hw;
        v.halfH = hh;
        v.radius = rb;
        v.softness = sb;
    }
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

// Screen-space anchoring: moves the entity's translation to the anchor point (the safe area when `safeArea`).
// `mirrored` (ui_mirrored, ui.mirrorRtl): the mirror image, anchor.x and the translation x flipped; the caller flips the pivot.
void apply_anchor(Mat4& m, Vec2 anchor, bool safeArea, const World& world, const Frame& f, bool mirrored = false) {
    if (mirrored) {
        anchor.x = 1.0f - anchor.x;
        m.at(3, 0) = -m.at(3, 0);
    }
    const Vec2 a = anchor_point(anchor, safeArea, Vec2{float(f.targetW), float(f.targetH)}, world.safe_insets());
    m.at(3, 0) += a.x;
    m.at(3, 1) += a.y;
}

bool axis_aligned(const Mat4& m) {
    return std::fabs(m.at(0, 1)) < 1e-4f && std::fabs(m.at(1, 0)) < 1e-4f && std::fabs(m.at(0, 2)) < 1e-4f &&
           std::fabs(m.at(1, 2)) < 1e-4f && std::fabs(m.at(2, 0)) < 1e-4f && std::fabs(m.at(2, 1)) < 1e-4f;
}

// The matrix a world-space visual is drawn with: its world matrix moved by Parallax.offset (screen space ignores it). A
// screen-space visual is authored in UI units, so its matrix is scaled by the interface scale (ui_rect.h) here, before the
// anchor point (not scaled) is added: sizes, offsets and glyphs all grow, the anchor stays.
Mat4 draw_matrix(const World& world, Entity e, bool screen) {
    return screen ? Mat4::scale({ui_scale_clamped(world.ui_scale()), ui_scale_clamped(world.ui_scale()), 1.0f}) * world.world_matrix(e)
                  : visual_world_matrix(world, e);
}

// The light frame of a lit quad: `right` and `up` are the directions the picture's right and top edges point to, in the
// entity's local space (y up). The shader needs the angle of the right axis in the world and whether up lies to its left
// (a right-handed frame) or to its right (the picture is mirrored): em.mode = kModeLit (+1 mirrored), em.aux = angle.
void set_light_frame(QuadEmitter& em, const Mat4& m, Vec2 right, Vec2 up) {
    const Vec3 t = m.transform_dir({right.x, right.y, 0.0f});
    const Vec3 b = m.transform_dir({up.x, up.y, 0.0f});
    em.mode = float(kModeLit) + (t.x * b.y - t.y * b.x < 0.0f ? 1.0f : 0.0f);
    em.aux = std::atan2(t.y, t.x);
}

// Where the tile image's right and top edges point to after the tile flags (see tilemap.h), in the tile's local space (y up).
// The image is transposed, then mirrored in x, then in y; the mirrors and the transpose are done in y-down picture
// coordinates, as the flags are defined.
void tile_axes(int flags, Vec2& right, Vec2& up) {
    Vec2 v[2] = {{1, 0}, {0, -1}};  // picture right and up, y down
    for (Vec2& a : v) {
        if (flags & kTileTranspose) a = {a.y, a.x};
        if (flags & kTileFlipX) a.x = -a.x;
        if (flags & kTileFlipY) a.y = -a.y;
    }
    right = {v[0].x, -v[0].y};
    up = {v[1].x, -v[1].y};
}

// The source position (fractions of the tile image, y down) shown at a corner of the tile (fractions of the tile, y down).
Vec2 tile_source(int flags, float px, float py) {
    if (flags & kTileFlipY) py = 1.0f - py;
    if (flags & kTileFlipX) px = 1.0f - px;
    if (flags & kTileTranspose) std::swap(px, py);
    return {px, py};
}

}  // namespace

void update_parallax(World& world, Vec2 camPos) {
    world.each<Parallax>([&](Entity, Parallax& p) { p.offset = {camPos.x * (1.0f - p.factor.x), camPos.y * (1.0f - p.factor.y)}; });
}

namespace {

// Collects the Light2D entities of the frame into f.lights2d, at most kMaxLights2D: directional lights first, then the
// point lights that light the view. A point light whose radius does not reach the camera's visible rectangle shades nothing
// on screen: it is left out and counted as dropped. Among those in view the ones with more of their radius inside the
// rectangle come first, then the more intense ones, then the nearest to the camera, so the lights over the budget are the
// ones that matter least. Counts what it kept and dropped in the frame's stats, then gives the lights with castShadows
// their shadow rows (light2d.cpp).
void gather_lights(World& world, Frame& f) {
    f.lights2d.clear();
    f.shadowData.clear();
    f.shadowRows = 0;
    f.ambient2d = world.settings().ambientLight;
    struct Candidate {
        Light2DData data;
        bool directional = false;
        bool inView = true;
        float inside = 1.0f;     // share of the light's bounding square (2 * radius) that is inside the view
        float intensity = 0.0f;
        float dist2 = 0.0f;      // squared distance to the camera
    };
    std::vector<Candidate> found;
    const Vec2 cam = f.cam.position.xy();
    const Rect view = f.cam.visible;
    const bool useView = !f.cam.perspective && view.w > 0.0f && view.h > 0.0f;
    world.each<Light2D>([&](Entity e, Light2D& l) {
        if (!entity_active(world, e) || l.intensity <= 0.0f) return;
        Candidate c{};
        c.intensity = l.intensity;
        c.data.color[0] = l.color.r * l.intensity;
        c.data.color[1] = l.color.g * l.intensity;
        c.data.color[2] = l.color.b * l.intensity;
        c.data.color[3] = std::max(l.falloff, 0.01f);
        if (l.type == Light2DType::Directional) {
            const float d = radians(l.direction), el = radians(std::clamp(l.elevation, 0.0f, 90.0f));
            c.data.pos[0] = -std::cos(d) * std::cos(el);  // towards the light = against its travel direction
            c.data.pos[1] = -std::sin(d) * std::cos(el);
            c.data.pos[2] = std::sin(el);
            c.data.pos[3] = -1.0f;
            c.directional = true;
        } else {
            if (l.radius <= 0.0f) return;
            const Vec3 p = world.world_matrix(e).translation();
            c.data.pos[0] = p.x;
            c.data.pos[1] = p.y;
            c.data.pos[2] = std::max(l.height, 0.0f);
            c.data.pos[3] = l.radius;
            c.data.extra[1] = l.castShadows ? 1.0f : 0.0f;
            c.dist2 = (p.x - cam.x) * (p.x - cam.x) + (p.y - cam.y) * (p.y - cam.y);
            if (useView) {
                // The light must reach the rectangle itself; "inside" is its bounding square against the view.
                const float cx = std::clamp(p.x, view.x, view.x + view.w), cy = std::clamp(p.y, view.y, view.y + view.h);
                const float dx = p.x - cx, dy = p.y - cy;
                c.inView = dx * dx + dy * dy < l.radius * l.radius;
                const float ox = std::max(0.0f, std::min(p.x + l.radius, view.x + view.w) - std::max(p.x - l.radius, view.x));
                const float oy = std::max(0.0f, std::min(p.y + l.radius, view.y + view.h) - std::max(p.y - l.radius, view.y));
                c.inside = ox * oy / (4.0f * l.radius * l.radius);
            }
        }
        found.push_back(c);
    });
    std::stable_sort(found.begin(), found.end(), [](const Candidate& a, const Candidate& b) {
        if (a.directional != b.directional) return a.directional;
        if (a.directional) return false;
        if (a.inView != b.inView) return a.inView;
        if (a.inside != b.inside) return a.inside > b.inside;
        if (a.intensity != b.intensity) return a.intensity > b.intensity;
        return a.dist2 < b.dist2;
    });
    int inViewCount = 0;
    for (const Candidate& c : found) inViewCount += (c.directional || c.inView) ? 1 : 0;
    const int total = int(found.size());
    // The off-view lights come last and shade nothing on screen, so they never take a place.
    found.resize(std::size_t(std::min(inViewCount, kMaxLights2D)));
    for (const Candidate& c : found) f.lights2d.push_back(c.data);
    if (f.stats) {
        f.stats->lights2d += int(f.lights2d.size());
        f.stats->lights2dDropped += total - int(f.lights2d.size());
    }
    if (inViewCount > kMaxLights2D && f.warnedLights2d && !*f.warnedLights2d) {
        *f.warnedLights2d = true;
        FA_WARN("render", "{} Light2D lights are in view but a frame shades at most {}; the others (the ones with the least of "
                "their radius in view, then the dimmest) are left out. Use fewer or smaller lights, or move them out of view",
                inViewCount, kMaxLights2D);
    }
    assign_shadow_rows(world, f);
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

    if (f.wantWorld) {
        update_parallax(world, f.cam.position.xy());
        gather_lights(world, f);
    }

    // ---- sprites ----
    world.each<Sprite>([&](Entity e, Sprite& s) {
        if (!entity_active(world, e) || s.color.a <= 0.0f) return;
        if (s.space == RenderSpace::Screen ? !f.wantScreen : !f.wantWorld) return;
        TextureAsset* tex = assets.texture(s.texture);
        Rect r = s.region;
        if (r.w <= 0 || r.h <= 0) r = Rect{0, 0, float(tex->width), float(tex->height)};
        Vec2 size = s.size;
        if (size.x <= 0 || size.y <= 0) {
            if (s.texture.empty()) size = {size.x > 0 ? size.x : 32.0f, size.y > 0 ? size.y : 32.0f};
            else size = {size.x > 0 ? size.x : r.w, size.y > 0 ? size.y : r.h};
        }
        bool screen = s.space == RenderSpace::Screen;
        Mat4 m = draw_matrix(world, e, screen);
        Rect clip;
        if (screen && !screen_clip(world, e, f, clip)) return;
        const bool mirrored = screen && ui_mirrored(world, e);
        if (screen) apply_anchor(m, s.anchor, s.safeArea, world, f, mirrored);
        QuadList& list = pick(s.space);
        list.begin_item(s.layer, secondary_key(f, m, !screen), tex, s.pixelArt ? SamplerKind::Nearest : SamplerKind::Linear, s.blend, clip);
        const bool lit = s.lit && !screen;
        if (lit) list.set_lit(s.normalMap.empty() ? nullptr : assets.texture(s.normalMap));
        const bool nine = !s.texture.empty() && (s.slice.x > 0 || s.slice.y > 0 || s.slice.z > 0 || s.slice.w > 0);
        const float pivotX = mirrored ? 1.0f - s.pivot.x : s.pivot.x;
        const float bx0 = -pivotX * size.x, bx1 = (1 - pivotX) * size.x, by0 = -s.pivot.y * size.y, by1 = (1 - s.pivot.y) * size.y;

        // One copy of the sprite drawn with matrix `mm`.
        auto draw = [&](const Mat4& mm) {
            QuadEmitter em{list, mm, screen, pack_color(s.color), kModeTextured, 0};
            if (lit) set_light_frame(em, mm, {s.flipX ? -1.0f : 1.0f, 0.0f}, {0.0f, s.flipY ? -1.0f : 1.0f});
            if (nine) {
                // 9-slice: the borders keep their texture size (1 pixel = 1 unit), the rest stretches. Geometry is laid out
                // unflipped from the top row down, then mirrored about the sprite box for flipX / flipY.
                float border[4], uvBorder[4];
                nine_slice_fit(s.slice, r.w, r.h, size.x, size.y, border, uvBorder);
                const float xs[4] = {bx0, bx0 + border[0], bx1 - border[2], bx1};
                const float ys[4] = {by1, by1 - border[1], by0 + border[3], by0};
                const float us[4] = {0, uvBorder[0], 1 - uvBorder[2], 1}, vs[4] = {0, uvBorder[1], 1 - uvBorder[3], 1};
                auto mx = [&](float x) { return s.flipX ? bx0 + bx1 - x : x; };
                auto my = [&](float y) { return s.flipY ? by0 + by1 - y : y; };
                for (int j = 0; j < 3; ++j)
                    for (int i = 0; i < 3; ++i) {
                        if (xs[i + 1] <= xs[i] || ys[j + 1] >= ys[j]) continue;  // an empty border
                        const Vec2 lo = tex->uv(r.x + us[i] * r.w, r.y + vs[j] * r.h);  // inside the atlas when packed
                        const Vec2 hi = tex->uv(r.x + us[i + 1] * r.w, r.y + vs[j + 1] * r.h);
                        em.rect(mx(xs[i]), my(ys[j + 1]), mx(xs[i + 1]), my(ys[j]), lo.x, lo.y, hi.x, hi.y);
                    }
                return;
            }
            const Vec2 lo = tex->uv(r.x, r.y), hi = tex->uv(r.x + r.w, r.y + r.h);  // inside the atlas when packed
            float u0 = lo.x, u1 = hi.x, v0 = lo.y, v1 = hi.y;
            if (s.texture.empty()) { u0 = v0 = 0; u1 = v1 = 1; }
            if (s.flipX) std::swap(u0, u1);
            if (s.flipY) std::swap(v0, v1);
            em.rect(bx0, by0, bx1, by1, u0, v0, u1, v1);
        };

        const Parallax* par = screen ? nullptr : world.get<Parallax>(e);
        if (par && (par->repeatX || par->repeatY) && !f.cam.perspective) {
            // A repeating background: copies every `step` world units along x and/or y, only those the camera can see.
            float minX = 1e30f, maxX = -1e30f, minY = 1e30f, maxY = -1e30f;
            for (int c = 0; c < 4; ++c) {
                const Vec3 p = m.transform_point({(c & 1) ? bx1 : bx0, (c & 2) ? by1 : by0, 0.0f});
                minX = std::min(minX, p.x); maxX = std::max(maxX, p.x);
                minY = std::min(minY, p.y); maxY = std::max(maxY, p.y);
            }
            const Rect view = f.cam.visible;
            auto range = [&](bool on, float requested, float lo, float hi, float viewLo, float viewHi, float& step, int& n0, int& n1) {
                step = 0.0f; n0 = n1 = 0;
                if (!on) return;
                step = requested > 0.0f ? requested : hi - lo;
                if (step < 1e-3f) { step = 0.0f; return; }
                n0 = int(std::ceil((viewLo - hi) / step));
                n1 = int(std::floor((viewHi - lo) / step));
                n1 = std::min(n1, n0 + 63);  // at most 64 copies per axis
            };
            float stepX, stepY;
            int x0, x1, y0, y1;
            range(par->repeatX, par->repeatSize.x, minX, maxX, view.x, view.x + view.w, stepX, x0, x1);
            range(par->repeatY, par->repeatSize.y, minY, maxY, view.y, view.y + view.h, stepY, y0, y1);
            for (int iy = y0; iy <= y1; ++iy)
                for (int ix = x0; ix <= x1; ++ix) {
                    Mat4 mm = m;
                    mm.at(3, 0) += float(ix) * stepX;
                    mm.at(3, 1) += float(iy) * stepY;
                    draw(mm);
                }
        } else {
            draw(m);
        }
        list.end_item();
        ++f.stats->sprites;
    });

    // ---- shapes ----
    world.each<Shape2D>([&](Entity e, Shape2D& s) {
        if (!entity_active(world, e) || s.color.a <= 0.0f) return;
        if (s.space == RenderSpace::Screen ? !f.wantScreen : !f.wantWorld) return;
        bool screen = s.space == RenderSpace::Screen;
        Mat4 m = draw_matrix(world, e, screen);
        Rect clip;
        if (screen && !screen_clip(world, e, f, clip)) return;
        if (screen) apply_anchor(m, s.anchor, s.safeArea, world, f, screen && ui_mirrored(world, e));
        if (screen && ui_mirrored(world, e)) m = m * Mat4::scale({-1.0f, 1.0f, 1.0f});  // every shape is symmetric about its box, but a line
        QuadList& list = pick(s.space);
        list.begin_item(s.layer, secondary_key(f, m, false), assets.white(), SamplerKind::Nearest, s.blend, clip);
        if (s.lit && !screen) list.set_lit(nullptr);
        QuadEmitter em{list, m, screen, pack_color(s.color), kModeTextured, 0};
        // Bounding box [bx0,bx1] x [by0,by1] in local units (y up; screen space flips it): pivot (0,0) = bottom-left.
        float bx0 = -s.pivot.x * s.size.x, bx1 = bx0 + s.size.x;
        float by0 = -s.pivot.y * s.size.y, by1 = by0 + s.size.y;
        float hw = s.size.x * 0.5f, hh = s.size.y * 0.5f;
        float t = std::max(0.0f, s.thickness);
        // Rounded corners, a soft edge or a gradient go through the SDF shader; plain shapes keep the batched fast path.
        const bool fx = s.softness > 0.0f || (s.filled && s.gradient != ShapeGradient::None);
        switch (s.shape) {
            case ShapeType::Rectangle:
                if (fx || s.cornerRadius > 0.0f) {
                    sdf_shape(em, s, bx0 + hw, by0 + hh, hw, hh, std::min(s.cornerRadius, std::min(hw, hh)), t);
                } else if (s.filled) {
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
                if (fx) {
                    sdf_shape(em, s, cx, cy, r, r, r, t);
                    break;
                }
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
        if (!f.wantWorld || !entity_active(world, e) || tm.tileSize.x <= 0 || tm.tileSize.y <= 0) return;
        // The same size 2D physics collides with (rows form: the rows; flat form: width/height). The tiles are read in
        // place from the component each frame: nothing is copied out of the Json.
        const TilemapSize grid = tilemap_size(tm);
        if (grid.empty()) return;
        const int w = grid.width, h = grid.height;
        TextureAsset* tex = assets.texture(tm.tileset);
        float tw = tm.tileSize.x, th = tm.tileSize.y;
        // columns = 0 (the default) means: as many whole tiles as fit across the tileset image.
        int cols = std::max(1, tileset_columns(tm, tex->width));
        Mat4 m = draw_matrix(world, e, false);
        QuadList& list = f.world;
        list.begin_item(tm.layer, secondary_key(f, m, false), tex, SamplerKind::Nearest);
        if (tm.lit) list.set_lit(tm.normalMap.empty() ? nullptr : assets.texture(tm.normalMap));
        QuadEmitter em{list, m, false, pack_color(tm.color), kModeTextured, 0};
        float texW = float(std::max(1, tex->width)), texH = float(std::max(1, tex->height));
        bool cull = !f.cam.perspective;
        Rect view = f.cam.visible;
        view.x -= 1; view.y -= 1; view.w += 2; view.h += 2;
        // An isometric map is drawn row by row from the top corner: back to front, so a tile covers the edge of the ones
        // behind it. Its tiles are diamonds placed by tilemap_cell_center(); the picture hangs from the diamond's top corner
        // by groundOffset (a taller picture shows the side of a block, or a tree that rises above the ground).
        const bool iso = tilemap_isometric(tm);
        const float isoHw = tw * 0.5f, isoHh = tilemap_ground_height(tm) * 0.5f;
        int c0 = 0, c1 = w - 1, r0 = 0, r1 = h - 1;
        if (iso && cull) {
            // The cells whose picture can reach the view: the view's corners in cell space, widened by the picture's extent.
            float lm[4];
            tilemap_local_to_cell(tm, lm);
            const Mat4 inv = m.inverse();
            float minA = 1e30f, maxA = -1e30f, minB = 1e30f, maxB = -1e30f;
            // The view grows by one picture (tw, th) in every direction, so a picture centred outside still counts.
            const Rect wide{view.x - tw, view.y - th, view.w + 2 * tw, view.h + 2 * th};
            for (int k = 0; k < 4; ++k) {
                const Vec3 q = inv.transform_point({wide.x + ((k & 1) ? wide.w : 0.0f), wide.y + ((k & 2) ? wide.h : 0.0f), 0.0f});
                const float a = lm[0] * q.x + lm[1] * q.y, b = lm[2] * q.x + lm[3] * q.y;
                minA = std::min(minA, a); maxA = std::max(maxA, a);
                minB = std::min(minB, b); maxB = std::max(maxB, b);
            }
            if (std::isfinite(minA + maxA + minB + maxB)) {
                c0 = std::max(0, int(std::floor(minA)) - 1); c1 = std::min(w - 1, int(std::ceil(maxA)) + 1);
                r0 = std::max(0, int(std::floor(minB)) - 1); r1 = std::min(h - 1, int(std::ceil(maxB)) + 1);
            }
        }
        for (int r = r0; r <= r1; ++r) {
            for (int c = c0; c <= c1; ++c) {
                const int value = tilemap_tile_at(tm, grid, c, r);
                if (value < 0) continue;
                const int idx = tile_index(value), flags = tile_flags(value);
                float x0, x1, y0, y1;
                if (iso) {
                    x0 = float(c - r) * isoHw - isoHw;
                    x1 = x0 + tw;
                    y1 = -float(c + r) * isoHh + tm.groundOffset;
                    y0 = y1 - th;
                } else {
                    x0 = float(c) * tw; y1 = -float(r) * th; x1 = x0 + tw; y0 = y1 - th;
                }
                if (cull) {
                    Vec3 a = em.xf(x0, y0), b = em.xf(x1, y1);
                    Rect box{std::min(a.x, b.x), std::min(a.y, b.y), std::fabs(a.x - b.x), std::fabs(a.y - b.y)};
                    if (!box.overlaps(view)) continue;
                }
                float px = float(tm.margin) + float(idx % cols) * (tw + float(tm.spacing));
                float py = float(tm.margin) + float(idx / cols) * (th + float(tm.spacing));
                if (tm.lit) {  // a turned tile turns its normals with it
                    Vec2 right, up;
                    tile_axes(flags, right, up);
                    set_light_frame(em, m, right, up);
                }
                if (flags == 0) {
                    em.rect(x0, y0, x1, y1, px / texW, py / texH, (px + tw) / texW, (py + th) / texH);
                } else {
                    // Corners top-left, bottom-left, bottom-right, top-right of the tile show these spots of its image.
                    static const float kCorner[4][2] = {{0, 0}, {0, 1}, {1, 1}, {1, 0}};
                    Vec2 uv[4];
                    for (int k = 0; k < 4; ++k) {
                        const Vec2 s = tile_source(flags, kCorner[k][0], kCorner[k][1]);
                        uv[k] = {(px + s.x * tw) / texW, (py + s.y * th) / texH};
                    }
                    em.rect_uv(x0, y0, x1, y1, uv);
                }
            }
        }
        list.end_item();
    });

    // ---- text ----
    world.each<Text>([&](Entity e, Text& t) {
        if (!entity_active(world, e) || t.text.empty() || t.color.a <= 0.0f || t.fontSize <= 0.0f) return;
        if (t.space == RenderSpace::Screen ? !f.wantScreen : !f.wantWorld) return;
        bool screen = t.space == RenderSpace::Screen;
        Mat4 m = draw_matrix(world, e, screen);
        Rect clip;
        if (screen && !screen_clip(world, e, f, clip)) return;
        float scale = matrix_scale_x(m);
        float ppu;
        if (screen) ppu = f.renderScale;
        else if (f.cam.perspective) {
            float dist = std::max(0.1f, length(m.translation() - f.cam.position));
            ppu = (float(f.targetH) * f.cam.viewport.h * 0.5f) / (std::tan(radians(f.cam.fov) * 0.5f) * dist);
        } else ppu = f.cam.pixelsPerUnit;
        float eff = ppu * scale * (screen ? 1.0f : f.renderScale);
        // Layout in LOCAL units (the entity scale is applied by the matrix), so the raster size uses eff. Screen-space Text
        // follows the player's text size option; world-space Text is part of the world and does not.
        // align start / end are the edges of the current language's direction; the font layer only knows left / right.
        Text resolved;
        const Text* drawn = &t;
        const bool mirrored = screen && ui_mirrored(world, e);
        const TextDirection dir = world.language().empty() ? t.direction : text_paragraph_direction(t, world.rtl());
        if (t.align == Align::Start || t.align == Align::End || mirrored || dir != t.direction) {
            resolved = t;
            if (t.align == Align::Start || t.align == Align::End)
                resolved.align = (t.align == Align::Start) != text_starts_right(t, world.rtl()) ? Align::Left : Align::Right;
            if (mirrored) resolved.pivot.x = 1.0f - t.pivot.x;
            resolved.direction = dir;
            drawn = &resolved;
        }
        // The size comes from fit_text (text_fit.h): the player's text size capped by maxTextScale, shrunk by autoShrink.
        const TextExtent extent = frame_text_extent(f, screen ? f.uiScale : 1.0f);
        const float px = t.autoShrink ? fit_text(text_fit_spec(t), t.text, t.font, f.textScale, extent).px
                                      : t.fontSize * (screen ? effective_text_scale(f.textScale, t.maxTextScale) : 1.0f);
        TextLayout lay = f.fonts->layout(*drawn, px, eff);
        if (lay.quads.empty() && lay.icons.empty()) return;
        if (t.visibleCharacters == 0) return;
        if (screen) apply_anchor(m, t.anchor, t.safeArea, world, f, mirrored);
        // Pixel-snap the anchor for crisp glyphs when the transform is axis aligned.
        if ((screen || !f.cam.perspective) && axis_aligned(m)) {
            float ox = screen ? 0.0f : f.cam.visible.x, oy = screen ? 0.0f : f.cam.visible.y;
            float k = screen ? 1.0f : f.cam.pixelsPerUnit;
            m.at(3, 0) = std::round((m.at(3, 0) - ox) * k) / k + ox;
            m.at(3, 1) = std::round((m.at(3, 1) - oy) * k) / k + oy;
        }
        f.stats->textGlyphs += emit_text(pick(t.space), m, screen, lay, t.color, *f.fonts, assets, t.layer, secondary_key(f, m, false), clip,
                                         t.visibleCharacters);
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

    // The world-space drawings go into every camera's frame, the screen-space text only into the frame of the screen.
    if (f.wantWorld) {
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
    }
    // Text (screen space, top-left origin).
    if (f.wantScreen) {
        for (const auto& t : dd.texts) {
            Text tx;
            tx.text = t.text;
            tx.fontSize = t.size;
            tx.color = t.c;
            tx.pivot = {0, 1};
            TextLayout lay = f.fonts->layout(tx, t.size, f.renderScale);  // a developer overlay: the text scale does not apply
            f.debugScreen.begin_item(0, 0, f.fonts->atlas(), SamplerKind::Linear);
            QuadEmitter em{f.debugScreen, Mat4::translate({std::round(t.pos.x), std::round(t.pos.y), 0}), true,
                           pack_color(t.c), kModeGlyph, 0};
            for (const auto& q : lay.quads) em.rect(q.x0, q.y0, q.x1, q.y1, q.u0, q.v0, q.u1, q.v1);
            f.debugScreen.end_item();
            f.stats->textGlyphs += int(lay.quads.size());
        }
    }
}

}  // namespace fa::render
