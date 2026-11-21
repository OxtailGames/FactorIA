// ShadowCaster2D outlines and their rasterisation into a light's row of distances (shadow2d.h).
#include "shadow2d.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>
#include <format>
#include <iterator>
#include <limits>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/scene/bounds.h"
#include "fa/scene/sprite_animator.h"
#include "frame.h"

namespace fa::render {

namespace {

constexpr float kInf = 1e30f;
constexpr float kTwoPi = 6.283185307179586f;
constexpr float kTexelsPerRad = float(kShadowAngles) / kTwoPi;

// ---------------------------------------------------------------------------------------------------------------------
// Marching squares
// ---------------------------------------------------------------------------------------------------------------------

struct Grid {
    int W = 0, H = 0;      // padded size in samples
    std::vector<float> f;  // alpha - threshold, in 0..255 units; inside when > 0
    float at(int x, int y) const { return f[std::size_t(y) * std::size_t(W) + std::size_t(x)]; }
};

// The id of the crossing on an edge of the grid: 2 * (y * W + x) for the edge from sample (x, y) to (x + 1, y), and
// that + 1 for the edge from (x, y) to (x, y + 1).
Vec2 edge_point(const Grid& g, std::uint32_t id) {
    const bool vertical = (id & 1u) != 0;
    const std::uint32_t cell = id >> 1;
    const int x = int(cell % std::uint32_t(g.W)), y = int(cell / std::uint32_t(g.W));
    const float va = g.at(x, y), vb = vertical ? g.at(x, y + 1) : g.at(x + 1, y);
    const float t = va / (va - vb);  // one of them is above 0, the other not: the denominator is not 0
    // Sample (x, y) of the padded grid is the centre of pixel (x - 1, y - 1).
    const float px = float(x) - 0.5f, py = float(y) - 0.5f;
    return vertical ? Vec2{px, py + t} : Vec2{px + t, py};
}

struct Seg {
    std::uint32_t a, b;
};

float polygon_area(const std::vector<Vec2>& p) {
    double s = 0;
    for (std::size_t i = 0; i < p.size(); ++i) {
        const Vec2& a = p[i];
        const Vec2& b = p[(i + 1) % p.size()];
        s += double(a.x) * double(b.y) - double(b.x) * double(a.y);
    }
    return float(s * 0.5);
}

// Douglas-Peucker on a closed loop: split at the point farthest from point 0, simplify both halves.
std::vector<Vec2> simplify_loop(const std::vector<Vec2>& p, float eps) {
    const std::size_t n = p.size();
    if (n <= 3) return p;
    std::size_t farIdx = 0;
    float best = -1;
    for (std::size_t i = 1; i < n; ++i) {
        const float dx = p[i].x - p[0].x, dy = p[i].y - p[0].y;
        const float d = dx * dx + dy * dy;
        if (d > best) {
            best = d;
            farIdx = i;
        }
    }
    std::vector<char> keep(n, 0);
    keep[0] = keep[farIdx] = 1;
    struct Range {
        std::size_t lo, hi;  // indices into the cyclic list; hi may be n (= point 0 again)
    };
    std::vector<Range> stack{{0, farIdx}, {farIdx, n}};
    while (!stack.empty()) {
        const Range r = stack.back();
        stack.pop_back();
        if (r.hi <= r.lo + 1) continue;
        const Vec2 a = p[r.lo], b = p[r.hi % n];
        const float ex = b.x - a.x, ey = b.y - a.y;
        const float len2 = ex * ex + ey * ey;
        std::size_t at = r.lo;
        float worst = -1;
        for (std::size_t i = r.lo + 1; i < r.hi; ++i) {
            const float dx = p[i].x - a.x, dy = p[i].y - a.y;
            float d2;
            if (len2 < 1e-12f) {
                d2 = dx * dx + dy * dy;
            } else {
                const float cr = dx * ey - dy * ex;
                d2 = cr * cr / len2;
            }
            if (d2 > worst) {
                worst = d2;
                at = i;
            }
        }
        if (worst > eps * eps) {
            keep[at] = 1;
            stack.push_back({r.lo, at});
            stack.push_back({at, r.hi});
        }
    }
    std::vector<Vec2> out;
    for (std::size_t i = 0; i < n; ++i)
        if (keep[i]) out.push_back(p[i]);
    return out;
}

}  // namespace

ContourLoops contour_from_alpha(const std::uint8_t* alpha, int w, int h, float threshold, int maxPoints) {
    ContourLoops result;
    if (!alpha || w <= 0 || h <= 0) return result;
    // A region over the pixel budget is reduced by blocks (the biggest alpha of each block): the work of a contour is a
    // count of pixels, never more than kMaxContourPixels2D.
    int stride = 1;
    while (std::uint64_t(w / stride + 1) * std::uint64_t(h / stride + 1) > std::uint64_t(kMaxContourPixels2D)) ++stride;
    const int gw = (w + stride - 1) / stride, gh = (h + stride - 1) / stride;
    Grid g;
    g.W = gw + 2;
    g.H = gh + 2;
    const float thr = std::clamp(threshold, 0.0f, 1.0f) * 255.0f;
    g.f.assign(std::size_t(g.W) * std::size_t(g.H), -thr - 1.0f);  // the empty border: outside whatever the threshold
    for (int y = 0; y < gh; ++y)
        for (int x = 0; x < gw; ++x) {
            int a = 0;
            for (int by = y * stride; by < std::min(h, (y + 1) * stride); ++by)
                for (int bx = x * stride; bx < std::min(w, (x + 1) * stride); ++bx)
                    a = std::max(a, int(alpha[std::size_t(by) * std::size_t(w) + std::size_t(bx)]));
            g.f[std::size_t(y + 1) * std::size_t(g.W) + std::size_t(x + 1)] = float(a) - thr;
        }

    auto hid = [&](int x, int y) { return 2u * (std::uint32_t(y) * std::uint32_t(g.W) + std::uint32_t(x)); };
    auto vid = [&](int x, int y) { return hid(x, y) + 1u; };
    std::vector<Seg> segs;
    for (int cy = 0; cy + 1 < g.H; ++cy)
        for (int cx = 0; cx + 1 < g.W; ++cx) {
            const float tl = g.at(cx, cy), tr = g.at(cx + 1, cy), br = g.at(cx + 1, cy + 1), bl = g.at(cx, cy + 1);
            const int idx = (tl > 0 ? 8 : 0) | (tr > 0 ? 4 : 0) | (br > 0 ? 2 : 0) | (bl > 0 ? 1 : 0);
            if (idx == 0 || idx == 15) continue;
            const std::uint32_t T = hid(cx, cy), B = hid(cx, cy + 1), L = vid(cx, cy), R = vid(cx + 1, cy);
            auto add = [&](std::uint32_t a, std::uint32_t b) { segs.push_back({a, b}); };
            switch (idx) {
                case 1: add(L, B); break;
                case 2: add(B, R); break;
                case 3: add(L, R); break;
                case 4: add(T, R); break;
                case 5:
                    if ((tl + tr + br + bl) > 0) {
                        add(T, L);
                        add(B, R);
                    } else {
                        add(T, R);
                        add(L, B);
                    }
                    break;
                case 6: add(T, B); break;
                case 7: add(T, L); break;
                case 8: add(T, L); break;
                case 9: add(T, B); break;
                case 10:
                    if ((tl + tr + br + bl) > 0) {
                        add(T, R);
                        add(L, B);
                    } else {
                        add(T, L);
                        add(B, R);
                    }
                    break;
                case 11: add(T, R); break;
                case 12: add(L, R); break;
                case 13: add(B, R); break;
                case 14: add(L, B); break;
                default: break;
            }
        }
    if (segs.empty()) return result;

    // Every crossing is shared by exactly two segments: chain them into closed loops.
    std::unordered_map<std::uint32_t, std::array<std::int32_t, 2>> at;
    at.reserve(segs.size() * 2);
    auto attach = [&](std::uint32_t id, std::int32_t s) {
        auto it = at.find(id);
        if (it == at.end())
            at.emplace(id, std::array<std::int32_t, 2>{s, -1});
        else
            it->second[1] = s;
    };
    for (std::size_t i = 0; i < segs.size(); ++i) {
        attach(segs[i].a, std::int32_t(i));
        attach(segs[i].b, std::int32_t(i));
    }
    std::vector<char> used(segs.size(), 0);
    std::vector<std::vector<Vec2>> loops;
    for (std::size_t s0 = 0; s0 < segs.size(); ++s0) {
        if (used[s0]) continue;
        std::vector<Vec2> loop;
        std::uint32_t start = segs[s0].a, cur = segs[s0].b;
        std::int32_t seg = std::int32_t(s0);
        used[s0] = 1;
        loop.push_back(edge_point(g, start));
        bool closed = false;
        for (std::size_t guard = 0; guard <= segs.size(); ++guard) {
            if (cur == start) {
                closed = true;
                break;
            }
            loop.push_back(edge_point(g, cur));
            const auto& pair = at[cur];
            const std::int32_t next = pair[0] == seg ? pair[1] : pair[0];
            if (next < 0 || used[std::size_t(next)]) break;
            used[std::size_t(next)] = 1;
            const Seg& ns = segs[std::size_t(next)];
            cur = ns.a == cur ? ns.b : ns.a;
            seg = next;
        }
        if (!closed || loop.size() < 3) continue;
        for (Vec2& v : loop) {  // back to pixels of the region (the reduced grid's unit is `stride` pixels)
            v.x = std::clamp(v.x * float(stride), 0.0f, float(w));
            v.y = std::clamp(v.y * float(stride), 0.0f, float(h));
        }
        loops.push_back(std::move(loop));
    }

    // The biggest loops first, tiny specks dropped, then simplified until they fit the point budget.
    std::vector<std::pair<float, std::size_t>> order;
    for (std::size_t i = 0; i < loops.size(); ++i) {
        const float a = std::fabs(polygon_area(loops[i]));
        if (a >= 1.0f) order.push_back({a, i});
    }
    std::stable_sort(order.begin(), order.end(), [](const auto& x, const auto& y) { return x.first > y.first; });
    if (order.size() > std::size_t(kMaxContourLoops2D)) order.resize(std::size_t(kMaxContourLoops2D));
    float eps = 0.6f * float(stride);
    for (int round = 0; round < 40; ++round) {
        result.clear();
        std::size_t total = 0;
        for (const auto& o : order) {
            std::vector<Vec2> s = simplify_loop(loops[o.second], eps);
            if (s.size() < 3) continue;
            total += s.size();
            result.push_back(std::move(s));
        }
        if (total <= std::size_t(std::max(maxPoints, 3)) || result.empty()) break;
        eps *= 1.5f;
    }
    return result;
}

// ---------------------------------------------------------------------------------------------------------------------
// Casters of a frame
// ---------------------------------------------------------------------------------------------------------------------

void warn_once(ContourCache& c, const std::string& key, const std::string& message, bool perEntity) {
    if (perEntity) {
        if (c.warned.size() >= kMaxEntityWarnings2D || !c.warned.insert(key).second) return;
    } else if (!c.warnedFixed.insert(key).second) {
        return;
    }
    FA_WARN("render", "{}", message);
}

void reset_warnings(ContourCache& c) {
    c.warned.clear();
    c.warnedFixed.clear();
}

namespace {

struct Hasher {
    std::uint64_t h = 1469598103934665603ull;
    void bytes(const void* p, std::size_t n) {
        const auto* b = static_cast<const std::uint8_t*>(p);
        for (std::size_t i = 0; i < n; ++i) h = (h ^ b[i]) * 1099511628211ull;
    }
};

// A closed polygon (local points, +y up) as segments of the world, through `m`.
struct Builder {
    CasterSet& out;
    const Mat4& m;
    ShadowBody body;
    bool open = false;
    void begin(std::int32_t layers, bool self) {
        body = ShadowBody{};
        body.first = std::uint32_t(out.segs.size());
        body.layers = layers;
        body.selfShadow = self;
        body.x0 = body.y0 = kInf;
        body.x1 = body.y1 = -kInf;
        open = true;
    }
    void loop(const Vec2* pts, std::size_t n) {
        if (n < 3) return;
        std::vector<Vec2> w(n);
        for (std::size_t i = 0; i < n; ++i) {
            const Vec3 q = m.transform_point({pts[i].x, pts[i].y, 0.0f});
            w[i] = {q.x, q.y};
            body.x0 = std::min(body.x0, q.x);
            body.x1 = std::max(body.x1, q.x);
            body.y0 = std::min(body.y0, q.y);
            body.y1 = std::max(body.y1, q.y);
        }
        for (std::size_t i = 0; i < n; ++i) {
            const Vec2 a = w[i], b = w[(i + 1) % n];
            if (!std::isfinite(a.x) || !std::isfinite(a.y) || !std::isfinite(b.x) || !std::isfinite(b.y)) continue;
            out.segs.push_back({a.x, a.y, b.x, b.y});
        }
    }
    bool end() {
        open = false;
        body.count = std::uint32_t(out.segs.size()) - body.first;
        if (body.count < 3 || !(body.x0 <= body.x1) || !(body.y0 <= body.y1)) {
            out.segs.resize(body.first);
            return false;
        }
        Hasher h;
        h.bytes(&out.segs[body.first], sizeof(ShadowSegment) * body.count);
        h.bytes(&body.selfShadow, sizeof body.selfShadow);
        body.hash = h.h;
        out.bodies.push_back(body);
        return true;
    }
};

// The alpha channel of a texture file, kept while it is used (budget: 32 MB of planes).
const ContourCache::Alpha& alpha_plane(ContourCache& c, const TextureAsset& tex, const std::string& key,
                                       std::string& problem) {
    // `problem` is the reason the pixels cannot be read, kept in the cached plane so a later region of the same texture
    // reports it too.
    auto it = c.planes.find(key);
    if (it != c.planes.end()) {
        it->second.used = c.tick;
        problem = it->second.problem;
        return it->second;
    }
    ContourCache::Alpha plane;
    plane.used = c.tick;
    if (tex.atlas || tex.placeholder || tex.width <= 0 || tex.height <= 0) {
        problem = tex.atlas ? "the texture is packed into an atlas by an export, so its pixels are not in a file"
                            : "the texture could not be loaded";
    } else if (std::uint64_t(tex.width) * std::uint64_t(tex.height) > (std::uint64_t(1) << 24)) {
        problem = std::format("the texture is {}x{} pixels, over the 16 million pixels a contour reads", tex.width,
                              tex.height);
    } else if (!fs::exists(tex.path)) {
        problem = "the texture has no image file to read (a render target or a generated texture)";
    } else if (auto img = load_image(tex.path); !img) {
        problem = img.error().message;
    } else {
        plane.w = img->width;
        plane.h = img->height;
        plane.a.resize(std::size_t(plane.w) * std::size_t(plane.h));
        for (std::size_t i = 0; i < plane.a.size(); ++i) plane.a[i] = img->rgba[i * 4 + 3];
        plane.ok = true;
    }
    if (c.planeBytes + plane.a.size() >
        (std::size_t(32) << 20)) {  // over budget: forget the least recently used planes
        while (!c.planes.empty() && c.planeBytes + plane.a.size() > (std::size_t(32) << 20)) {
            auto oldest = c.planes.begin();
            for (auto p = c.planes.begin(); p != c.planes.end(); ++p)
                if (p->second.used < oldest->second.used ||
                    (p->second.used == oldest->second.used && p->first < oldest->first))
                    oldest = p;
            c.planeBytes -= oldest->second.a.size();
            c.planes.erase(oldest);
        }
    }
    plane.problem = problem;
    c.planeBytes += plane.a.size();
    return c.planes.emplace(key, std::move(plane)).first->second;
}

}  // namespace

void gather_shadow_casters(World& world, Frame& f, ContourCache& cache, CasterSet& out) {
    out.segs.clear();
    out.bodies.clear();
    ++cache.tick;  // one per gather pass (one per camera of a frame that asks for shadows), never per frame
    bool over = false;
    world.each<ShadowCaster2D>([&](Entity e, ShadowCaster2D& caster) {
        const ShadowCaster2D& sc = caster;
        if (!sc.enabled || !entity_active(world, e) || !f.mask.draws(world, e)) return;
        if (int(out.bodies.size()) >= kMaxShadowCasters2D) {
            over = true;
            return;
        }
        const Mat4 m = visual_world_matrix(world, e);
        Builder b{out, m, {}, false};
        b.begin(sc.lightLayers, sc.selfShadow);
        auto box = [&](float x0, float y0, float x1, float y1) {
            const Vec2 p[4] = {{x0, y0}, {x1, y0}, {x1, y1}, {x0, y1}};
            b.loop(p, 4);
        };
        if (sc.shape == ShadowCaster2DShape::Box) {
            if (sc.size.x > 0 && sc.size.y > 0 && std::isfinite(sc.size.x) && std::isfinite(sc.size.y))
                box(-sc.size.x * 0.5f, -sc.size.y * 0.5f, sc.size.x * 0.5f, sc.size.y * 0.5f);
        } else if (sc.shape == ShadowCaster2DShape::Polygon) {
            std::size_t n = sc.points.size() / 2;
            if (n > std::size_t(kMaxCasterSegments2D)) {
                warn_once(cache, std::format("poly{}", world.id_of(e)),
                          std::format("ShadowCaster2D on '{}' has {} polygon points; at most {} are used (the rest are "
                                      "cut). Hint: simplify the outline, or split it into several casters",
                                      world.id_of(e), n, kMaxCasterSegments2D),
                          true);
                n = std::size_t(kMaxCasterSegments2D);
            }
            std::vector<Vec2> pts;
            for (std::size_t i = 0; i < n; ++i) pts.push_back({sc.points[2 * i], sc.points[2 * i + 1]});
            b.loop(pts.data(), pts.size());
        } else {
            const Sprite* s = world.get<Sprite>(e);
            if (!s) {
                warn_once(
                    cache, std::format("nospr{}", world.id_of(e)),
                    std::format("ShadowCaster2D on '{}' has shape spriteAlpha but the entity has no Sprite, so it "
                                "blocks no light. Hint: add a Sprite, or set shape to box or polygon",
                                world.id_of(e)),
                    true);
            } else {
                TextureAsset* tex = s->texture.empty() || !f.assets ? nullptr : f.assets->texture(s->texture);
                Rect r = s->region;
                if (tex && (r.w <= 0 || r.h <= 0)) r = Rect{0, 0, float(tex->width), float(tex->height)};
                Vec2 size = s->size;
                if (size.x <= 0 || size.y <= 0) {
                    if (!tex || s->texture.empty())
                        size = {size.x > 0 ? size.x : 32.0f, size.y > 0 ? size.y : 32.0f};
                    else
                        size = {size.x > 0 ? size.x : r.w, size.y > 0 ? size.y : r.h};
                }
                Vec2 pivot = s->pivot;
                if (const SpriteAnimator* anim = world.get<SpriteAnimator>(e); anim && tex) {
                    auto sheet = f.sheets.find(s->texture);
                    if (sheet == f.sheets.end()) sheet = f.sheets.emplace(s->texture, assets::sheet(s->texture)).first;
                    pivot =
                        sprite_effective_pivot(*s, *anim, resolve_sprite_animator(*anim, s->texture, sheet->second));
                }
                const float bx0 = -pivot.x * size.x, bx1 = bx0 + size.x, by0 = -pivot.y * size.y, by1 = by0 + size.y;
                bool boxed = true;
                if (tex) {
                    // Region in whole pixels of the file, inside the texture.
                    const int tw = tex->width, th = tex->height;
                    // The pixels the rectangle touches: floor of its first edge, ceil of its far edge (a fractional x
                    // with a fractional width no longer shifts the crop by a texel).
                    const float fx0 = std::clamp(r.x, 0.0f, float(tw)), fy0 = std::clamp(r.y, 0.0f, float(th));
                    const float fx1 = std::clamp(r.x + r.w, fx0, float(tw)),
                                fy1 = std::clamp(r.y + r.h, fy0, float(th));
                    const int rx = std::clamp(int(std::floor(fx0)), 0, tw);
                    const int ry = std::clamp(int(std::floor(fy0)), 0, th);
                    const int rw = std::clamp(int(std::ceil(fx1)) - rx, 0, tw - rx);
                    const int rh = std::clamp(int(std::ceil(fy1)) - ry, 0, th - ry);
                    const int thr = int(std::lround(std::clamp(sc.alphaThreshold, 0.0f, 1.0f) * 255.0f));
                    const std::string planeKey = std::format("{}#{}", tex->path, tex->image.id);
                    const std::string key = std::format("{}|{},{},{},{}|{}", planeKey, rx, ry, rw, rh, thr);
                    auto it = cache.contours.find(key);
                    if (it == cache.contours.end() && rw > 0 && rh > 0) {
                        ContourCache::Entry entry;
                        std::string problem;
                        const ContourCache::Alpha& plane = alpha_plane(cache, *tex, planeKey, problem);
                        if (plane.ok && rx + rw <= plane.w && ry + rh <= plane.h) {
                            std::vector<std::uint8_t> crop(std::size_t(rw) * std::size_t(rh));
                            for (int y = 0; y < rh; ++y)
                                std::memcpy(&crop[std::size_t(y) * std::size_t(rw)],
                                            &plane.a[std::size_t(ry + y) * std::size_t(plane.w) + std::size_t(rx)],
                                            std::size_t(rw));
                            entry.loops =
                                contour_from_alpha(crop.data(), rw, rh, float(thr) / 255.0f, kMaxCasterSegments2D);
                            ++cache.contoursMade;
                        } else {
                            entry.fallbackBox = true;
                            if (problem.empty()) problem = "the image file is smaller than the texture the GPU holds";
                            warn_once(cache, std::format("alpha{}", planeKey),
                                      std::format("ShadowCaster2D on '{}' could not read the alpha of '{}': {}. The "
                                                  "sprite's rectangle blocks light instead. Hint: use shape polygon or "
                                                  "box for this sprite, or keep the texture file in the project",
                                                  world.id_of(e), s->texture, problem),
                                      true);
                        }
                        entry.used = cache.tick;
                        if (cache.contours.size() >=
                            4096) {  // forget what no gather pass used in the last two (a gather pass, not a frame, ages the cache)
                            for (auto c = cache.contours.begin(); c != cache.contours.end();)
                                c = c->second.used + 1 < cache.tick ? cache.contours.erase(c) : std::next(c);
                            if (cache.contours.size() >= 4096)
                                cache.contours.clear();  // a hard bound: they are made again
                        }
                        it = cache.contours.emplace(key, std::move(entry)).first;
                    }
                    if (it != cache.contours.end() && !it->second.fallbackBox) {
                        it->second.used = cache.tick;
                        boxed = false;
                        for (const auto& loop : it->second.loops) {
                            std::vector<Vec2> pts;
                            pts.reserve(loop.size());
                            for (const Vec2& p : loop) {
                                const float u = s->flipX ? float(rw) - p.x : p.x;
                                const float v = s->flipY ? float(rh) - p.y : p.y;
                                pts.push_back({bx0 + u / float(rw) * size.x, by1 - v / float(rh) * size.y});
                            }
                            b.loop(pts.data(), pts.size());
                        }
                    } else if (it != cache.contours.end()) {
                        it->second.used = cache.tick;
                    }
                }
                if (boxed && b.body.first == out.segs.size()) box(bx0, by0, bx1, by1);
            }
        }
        b.end();
    });
    if (over) {
        warn_once(cache, "casters",
                  std::format("More than {} ShadowCaster2D are enabled; the ones after the first {} (in entity order) "
                              "block no light. Hint: merge static props into one polygon caster, or switch off the "
                              "casters far from the camera",
                              kMaxShadowCasters2D, kMaxShadowCasters2D));
    }
}

void casters_in_reach(const CasterSet& set, float px, float py, float radius, std::int32_t layers,
                      std::vector<std::uint32_t>& out, bool& over) {
    out.clear();
    over = false;
    const float r2 = radius * radius;
    for (std::size_t i = 0; i < set.bodies.size(); ++i) {
        const ShadowBody& b = set.bodies[i];
        if ((b.layers & layers) == 0) continue;
        const float dx = std::max({b.x0 - px, 0.0f, px - b.x1}), dy = std::max({b.y0 - py, 0.0f, py - b.y1});
        if (dx * dx + dy * dy >= r2) continue;
        if (int(out.size()) >= kMaxCasterBodiesPerLight) {
            over = true;
            break;
        }
        out.push_back(std::uint32_t(i));
    }
}

std::uint64_t cast_casters(const CasterSet& set, const std::vector<std::uint32_t>& bodies, float px, float py,
                           float radius, float* dist, bool* cut) {
    struct Dir {
        float c, s;
    };
    static const std::vector<Dir> dirs = [] {
        std::vector<Dir> v;
        v.resize(std::size_t(kShadowAngles));
        for (int i = 0; i < kShadowAngles; ++i) {
            const double a = double(i) * 6.283185307179586 / double(kShadowAngles);
            v[std::size_t(i)] = {float(std::cos(a)), float(std::sin(a))};
        }
        return v;
    }();
    std::uint64_t work = 0;
    std::vector<float> near1(std::size_t(kShadowAngles), kInf), near2(std::size_t(kShadowAngles), kInf);
    std::vector<std::uint16_t> touched;
    for (std::uint32_t bi : bodies) {
        if (work >= kMaxRowWork2D) {
            if (cut) *cut = true;
            break;
        }
        const ShadowBody& body = set.bodies[bi];
        const ShadowSegment* segs = &set.segs[body.first];
        // A light inside the outline is not blocked by it (like a light inside a solid tile): even-odd, ray towards +x.
        int crossings = 0;
        for (std::uint32_t k = 0; k < body.count; ++k) {
            const ShadowSegment& s = segs[k];
            if ((s.ay > py) == (s.by > py)) continue;
            const float x = s.ax + (py - s.ay) / (s.by - s.ay) * (s.bx - s.ax);
            if (x > px) ++crossings;
        }
        if (crossings & 1) continue;
        touched.clear();
        for (std::uint32_t k = 0; k < body.count; ++k) {
            if (work >=
                kMaxRowWork2D) {  // a body is cut in the middle of its segments: what it found so far still counts
                if (cut) *cut = true;
                break;
            }
            const ShadowSegment& s = segs[k];
            const float ax = s.ax - px, ay = s.ay - py, bx = s.bx - px, by = s.by - py;
            const float ex = bx - ax, ey = by - ay;
            const float len2 = ex * ex + ey * ey;
            if (!(len2 > 1e-12f)) continue;
            // The nearest point of the segment to the light must be inside the disc.
            const float u0 = std::clamp(-(ax * ex + ay * ey) / len2, 0.0f, 1.0f);
            const float nx = ax + u0 * ex, ny = ay + u0 * ey;
            if (nx * nx + ny * ny >= radius * radius) continue;
            const float cr = ax * by - ay * bx;  // the sign says which way round the light sees the segment
            if (cr == 0.0f) continue;
            float ta = std::atan2(cr > 0 ? ay : by, cr > 0 ? ax : bx);
            float tb = std::atan2(cr > 0 ? by : ay, cr > 0 ? bx : ax);
            ta = (ta < 0 ? ta + kTwoPi : ta) * kTexelsPerRad;
            tb = (tb < 0 ? tb + kTwoPi : tb) * kTexelsPerRad;
            float span = tb - ta;
            if (span < 0) span += float(kShadowAngles);
            const int first = int(std::floor(ta)) - 1;
            const int count = std::min(int(std::ceil(span)) + 3, kShadowAngles);
            for (int n = 0; n < count; ++n) {
                int i = (first + n) % kShadowAngles;
                if (i < 0) i += kShadowAngles;
                ++work;
                const Dir d = dirs[std::size_t(i)];
                // The ray crosses the segment when its endpoints are on different sides of the ray's line (the endpoint
                // on the line counts as the "not above" side, so a ray through a corner crosses once or twice, never
                // between): the same parity rule at every vertex.
                const float sa = d.c * ay - d.s * ax, sb = d.c * by - d.s * bx;
                if ((sa > 0.0f) == (sb > 0.0f)) continue;
                const float u = sa / (sa - sb);
                const float t = (ax + u * ex) * d.c + (ay + u * ey) * d.s;
                if (!(t > 0.0f)) continue;
                const std::size_t ii = std::size_t(i);
                if (near1[ii] >= kInf) touched.push_back(std::uint16_t(i));
                if (t < near1[ii]) {
                    near2[ii] = near1[ii];
                    near1[ii] = t;
                } else if (t < near2[ii]) {
                    near2[ii] = t;
                }
            }
        }
        for (std::uint16_t i : touched) {
            const std::size_t ii = i;
            const float start = body.selfShadow || near2[ii] >= kInf ? near1[ii] : near2[ii];
            dist[ii] = std::min(dist[ii], start);
            near1[ii] = near2[ii] = kInf;
        }
    }
    return work;
}

}  // namespace fa::render
