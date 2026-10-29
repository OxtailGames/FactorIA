// assets.generate_texture: procedural material textures (paper, parchment, wood, planks, leather, fabric, stone, noise,
// gradients, vignettes) written as PNG, offline: no provider, no key, no cost. The picture is a pure function of the
// arguments: every random choice comes from an integer hash of (cell, seed), never from the clock or rand().
//
// Every preset builds a height field and an albedo, shades the albedo with the height (a light from the upper left, so the
// grooves and bumps read), and optionally turns the same height field into a tangent-space normal map. With `tileable` all
// the noise wraps around the image (integer cell counts, wrapped lattice) and so does the shading, so the picture repeats
// without a seam.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <format>
#include <string>
#include <vector>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/asset_import.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

using u32 = std::uint32_t;
constexpr double kPi = 3.14159265358979323846;
constexpr int kMaxSide = 2048;

// ---- hashing and noise ------------------------------------------------------------------------------------------

u32 mix_bits(u32 h) {
    h ^= h >> 16;
    h *= 0x7feb352du;
    h ^= h >> 15;
    h *= 0x846ca68bu;
    h ^= h >> 16;
    return h;
}
u32 hash3(int x, int y, u32 seed) { return mix_bits(u32(x) * 0x9E3779B1u ^ mix_bits(u32(y) * 0x85EBCA77u + seed)); }
double unit(u32 h) { return double(h >> 8) * (1.0 / 16777216.0); }          // [0, 1)
double rand01(int x, int y, u32 seed) { return unit(hash3(x, y, seed)); }
int wrap_cell(int i, int period) { return period > 0 ? ((i % period) + period) % period : i; }

double clamp01(double v) { return std::clamp(v, 0.0, 1.0); }
double lerp(double a, double b, double t) { return a + (b - a) * t; }
double smoothstep(double e0, double e1, double x) {
    if (e0 == e1) return x < e0 ? 0.0 : 1.0;
    const double t = clamp01((x - e0) / (e1 - e0));
    return t * t * (3.0 - 2.0 * t);
}
double fade(double t) { return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); }

// Gradient (Perlin) noise in about [-1, 1]. x and y count lattice cells; a period > 0 wraps the lattice, so the noise repeats
// every `period` cells.
double gnoise(double x, double y, int px, int py, u32 seed) {
    static const double kGrad[8][2] = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}, {0.70710678, 0.70710678}, {-0.70710678, 0.70710678},
                                       {0.70710678, -0.70710678}, {-0.70710678, -0.70710678}};
    const double fx0 = std::floor(x), fy0 = std::floor(y);
    const int x0 = int(fx0), y0 = int(fy0);
    const double fx = x - fx0, fy = y - fy0;
    auto corner = [&](int ix, int iy, double dx, double dy) {
        const u32 h = hash3(wrap_cell(ix, px), wrap_cell(iy, py), seed) & 7u;
        return kGrad[h][0] * dx + kGrad[h][1] * dy;
    };
    const double u = fade(fx), v = fade(fy);
    const double a = lerp(corner(x0, y0, fx, fy), corner(x0 + 1, y0, fx - 1, fy), u);
    const double b = lerp(corner(x0, y0 + 1, fx, fy - 1), corner(x0 + 1, y0 + 1, fx - 1, fy - 1), u);
    return lerp(a, b, v) * 1.4142;
}

// Value noise in [0, 1].
double vnoise(double x, double y, int px, int py, u32 seed) {
    const double fx0 = std::floor(x), fy0 = std::floor(y);
    const int x0 = int(fx0), y0 = int(fy0);
    const double u = smoothstep(0, 1, x - fx0), v = smoothstep(0, 1, y - fy0);
    auto at = [&](int ix, int iy) { return rand01(wrap_cell(ix, px), wrap_cell(iy, py), seed); };
    return lerp(lerp(at(x0, y0), at(x0 + 1, y0), u), lerp(at(x0, y0 + 1), at(x0 + 1, y0 + 1), u), v);
}

// How many lattice cells a layer has across the image.
struct Cells {
    int x = 1, y = 1;
};

struct Grid {
    int w = 0, h = 0;
    bool tile = false;
    u32 seed = 0;
    // Cells of a feature about `perShortSide` times across the shorter side (or `px` pixels wide).
    Cells per_short(double perShortSide) const {
        const double s = std::min(w, h);
        return {std::max(1, int(std::lround(perShortSide * w / s))), std::max(1, int(std::lround(perShortSide * h / s)))};
    }
    Cells per_px(double px, double pxY = 0) const {
        if (pxY <= 0) pxY = px;
        return {std::max(1, int(std::lround(w / px))), std::max(1, int(std::lround(h / pxY)))};
    }
};

// Fractal gradient noise at the unit-square point (u, v), in about [-1, 1]. Each octave doubles the cell count, so the lattice
// of every octave still divides the image evenly and wraps. `gain` is the amplitude ratio between octaves.
double fbm(const Grid& g, double u, double v, Cells base, int octaves, double gain, u32 salt) {
    double sum = 0, amp = 1, norm = 0;
    int cx = base.x, cy = base.y;
    for (int o = 0; o < octaves; ++o) {
        sum += amp * gnoise(u * cx, v * cy, g.tile ? cx : 0, g.tile ? cy : 0, g.seed + salt * 977u + u32(o) * 131u);
        norm += amp;
        amp *= gain;
        cx *= 2;
        cy *= 2;
    }
    return sum / norm;
}

// Cellular (Worley) noise: the distances to the nearest and second nearest feature point, in cell units, and the nearest
// cell's id (a hash that is the same for the same wrapped cell).
struct Worley {
    double f1 = 9, f2 = 9;
    double edge = 9;  // distance to the border between the two nearest cells (the bisector), in the same units
    u32 id = 0;
};
Worley worley(const Grid& g, double u, double v, Cells c, double jitter, u32 salt) {
    const double x = u * c.x, y = v * c.y;
    const int ix = int(std::floor(x)), iy = int(std::floor(y));
    const double sx = double(g.w) / c.x, sy = double(g.h) / c.y, ref = std::min(sx, sy);
    Worley best;
    double p1x = 0, p1y = 0, p2x = 0, p2y = 0;
    const u32 seed = g.seed + salt * 7919u;
    for (int dy = -2; dy <= 2; ++dy) {
        for (int dx = -2; dx <= 2; ++dx) {
            const int cx = ix + dx, cy = iy + dy;
            const int wx = g.tile ? wrap_cell(cx, c.x) : cx, wy = g.tile ? wrap_cell(cy, c.y) : cy;
            const u32 hh = hash3(wx, wy, seed);
            const double fx = cx + 0.5 + (unit(hh) - 0.5) * jitter, fy = cy + 0.5 + (unit(mix_bits(hh ^ 0x68bc21ebu)) - 0.5) * jitter;
            const double ddx = (fx - x) * sx / ref, ddy = (fy - y) * sy / ref;
            const double d = std::sqrt(ddx * ddx + ddy * ddy);
            if (d < best.f1) {
                best.f2 = best.f1;
                p2x = p1x;
                p2y = p1y;
                best.f1 = d;
                p1x = ddx;
                p1y = ddy;
                best.id = hh;
            } else if (d < best.f2) {
                best.f2 = d;
                p2x = ddx;
                p2y = ddy;
            }
        }
    }
    const double sep = std::sqrt((p2x - p1x) * (p2x - p1x) + (p2y - p1y) * (p2y - p1y));
    best.edge = sep > 1e-9 ? (best.f2 * best.f2 - best.f1 * best.f1) / (2.0 * sep) : 0.0;
    return best;
}

// ---- the canvas -----------------------------------------------------------------------------------------------------

struct Rgb {
    double r = 0, g = 0, b = 0, a = 1;
};
Rgb mix(const Rgb& p, const Rgb& q, double t) {
    return {lerp(p.r, q.r, t), lerp(p.g, q.g, t), lerp(p.b, q.b, t), lerp(p.a, q.a, t)};
}
Rgb scaled(const Rgb& p, double k) { return {p.r * k, p.g * k, p.b * k, p.a}; }
Rgb from_color(const Color& c) { return {c.r, c.g, c.b, c.a}; }

struct Canvas {
    int w = 0, h = 0;
    bool tile = false;
    std::vector<Rgb> px;
    std::vector<double> height;  // 0..1, drives the shading and the normal map
    Canvas(int w_, int h_, bool tile_) : w(w_), h(h_), tile(tile_), px(std::size_t(w_) * h_), height(std::size_t(w_) * h_, 0.5) {}
    std::size_t at(int x, int y) const { return std::size_t(y) * w + x; }
    double h_at(int x, int y) const {  // height with wrap (tileable) or clamp
        if (tile) {
            x = wrap_cell(x, w);
            y = wrap_cell(y, h);
        } else {
            x = std::clamp(x, 0, w - 1);
            y = std::clamp(y, 0, h - 1);
        }
        return height[at(x, y)];
    }
};

// Height slope per pixel, scaled so a given strength looks the same at every resolution (512 px is the reference).
void slope(const Canvas& c, int x, int y, double& dx, double& dy) {
    const double k = std::min(c.w, c.h) / 512.0;
    dx = (c.h_at(x + 1, y) - c.h_at(x - 1, y)) * 0.5 * k;
    dy = (c.h_at(x, y + 1) - c.h_at(x, y - 1)) * 0.5 * k;
}

// Light from the upper left: a slope rising towards the lower right faces the light.
void shade_by_height(Canvas& c, double strength) {
    if (strength <= 0) return;
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            double dx, dy;
            slope(c, x, y, dx, dy);
            const double s = std::clamp(1.0 + strength * (dx + dy) * 0.75, 0.2, 1.8);
            Rgb& p = c.px[c.at(x, y)];
            p.r = p.r * s;
            p.g = p.g * s;
            p.b = p.b * s;
        }
    }
}

// A thin soft line of `weight` added to a float buffer, with wrap-around for tileable textures.
struct FibreBuffer {
    int w, h;
    bool tile;
    std::vector<double> v;
    FibreBuffer(int w_, int h_, bool tile_) : w(w_), h(h_), tile(tile_), v(std::size_t(w_) * h_, 0.0) {}
    void splat(double x, double y, double weight) {
        const double fx = std::floor(x), fy = std::floor(y), tx = x - fx, ty = y - fy;
        auto add = [&](int ix, int iy, double wgt) {
            if (tile) {
                ix = wrap_cell(ix, w);
                iy = wrap_cell(iy, h);
            } else if (ix < 0 || iy < 0 || ix >= w || iy >= h) {
                return;
            }
            v[std::size_t(iy) * w + ix] += wgt;
        };
        add(int(fx), int(fy), weight * (1 - tx) * (1 - ty));
        add(int(fx) + 1, int(fy), weight * tx * (1 - ty));
        add(int(fx), int(fy) + 1, weight * (1 - tx) * ty);
        add(int(fx) + 1, int(fy) + 1, weight * tx * ty);
    }
};

// Short wavy strands, like the fibres of paper: `count` strands of about `length` pixels at random angles.
void scatter_fibres(FibreBuffer& buf, u32 seed, int count, double length, double weight, double curl) {
    for (int i = 0; i < count; ++i) {
        const u32 hh = hash3(i, 17, seed);
        double x = unit(hh) * buf.w, y = unit(mix_bits(hh ^ 0xa511e9b3u)) * buf.h;
        double angle = unit(mix_bits(hh ^ 0x63d83595u)) * kPi * 2;
        const double len = length * (0.5 + unit(mix_bits(hh ^ 0x1b873593u)));
        for (double s = 0; s < len; s += 0.6) {
            buf.splat(x, y, weight);
            angle += (unit(hash3(i, int(s * 4), seed ^ 0x5bd1e995u)) - 0.5) * curl;
            x += std::cos(angle) * 0.6;
            y += std::sin(angle) * 0.6;
        }
    }
}

// ---- the presets ----------------------------------------------------------------------------------------------------

struct Params {
    int w = 512, h = 512;
    u32 seed = 0;
    Rgb base, accent;
    double scale = 1, rough = 0.5, vignette = -1, vignetteWidth = 0.035, angle = 0;
    bool tile = false;
    // planks only
    int plankCount = 0;           // boards across the picture's height; 0 = derived from `scale`
    double plankLength = 1.0;     // board length as a fraction of the picture's width; 0 = full width, no butt joints
    double gapWidth = 0.015;      // gap between boards as a fraction of a board's width
    double gapDarkness = 0.55;    // 0 = no darkening in the gaps, 1 = as dark as the accent allows
};

struct Preset {
    const char* name;
    const char* what;      // one line for the description of the command
    const char* palette;   // default colours, for the description
    Rgb base, accent;
    double vignette;       // default edge darkening (0 = none)
    bool canTile;
    bool textured;         // has its own grain; the smooth presets get a dither so they do not band
    void (*draw)(Canvas&, const Params&, const Grid&);
};

Rgb hex(u32 rgb) {
    return {((rgb >> 16) & 0xff) / 255.0, ((rgb >> 8) & 0xff) / 255.0, (rgb & 0xff) / 255.0, 1.0};
}

// The height, in 0..1, is stored for shading; the albedo is written by each preset.

void draw_paper(Canvas& c, const Params& p, const Grid& g) {
    FibreBuffer fibres(c.w, c.h, c.tile);
    const double area = double(c.w) * c.h / (512.0 * 512.0);
    scatter_fibres(fibres, p.seed + 11u, int(1400 * area), 9, 0.10, 1.2);
    FibreBuffer light(c.w, c.h, c.tile);
    scatter_fibres(light, p.seed + 12u, int(700 * area), 10, 0.07, 1.0);
    const Cells mottleCells = g.per_short(3.0 / p.scale), blotchCells = g.per_short(9.0 / p.scale), toothCells = g.per_px(2.2);
    const double amount = 0.35 + 0.65 * p.rough;
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            const double mottle = fbm(g, u, v, mottleCells, 4, 0.5, 1) * 0.5 + 0.5;
            const double blotch = fbm(g, u, v, blotchCells, 3, 0.5, 2);
            const double tooth = fbm(g, u, v, toothCells, 2, 0.6, 3);
            const double f = fibres.v[c.at(x, y)], l = light.v[c.at(x, y)];
            const double t = clamp01((mottle - 0.5) * 0.9 * amount + 0.25 + blotch * 0.12 * amount + f * 1.1 * amount);
            Rgb col = mix(p.base, p.accent, t * 0.55);
            col = scaled(col, 1.0 + (tooth * 0.035 + l * 0.9) * amount);
            c.px[c.at(x, y)] = col;
            c.height[c.at(x, y)] = 0.5 + tooth * 0.18 + (f - l) * 0.5;
        }
    }
    shade_by_height(c, 0.55 + 0.6 * p.rough);
}

void draw_parchment(Canvas& c, const Params& p, const Grid& g) {
    FibreBuffer fibres(c.w, c.h, c.tile);
    const double area = double(c.w) * c.h / (512.0 * 512.0);
    scatter_fibres(fibres, p.seed + 21u, int(1000 * area), 10, 0.10, 1.4);
    const Cells stainCells = g.per_short(2.4 / p.scale), mottleCells = g.per_short(10.0 / p.scale), creaseCells = g.per_short(5.0 / p.scale),
                toothCells = g.per_px(2.0);
    const double amount = 0.4 + 0.6 * p.rough;
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            // warm stains: big soft blotches of the darker colour
            const double stain = fbm(g, u, v, stainCells, 5, 0.55, 1) * 0.5 + 0.5;
            const double blot = smoothstep(0.30, 0.85, stain);
            const double mottle = fbm(g, u, v, mottleCells, 4, 0.5, 2);
            // creases: thin dark lines where a noise crosses zero
            const double warpU = u + 0.02 * fbm(g, u, v, creaseCells, 2, 0.5, 4), warpV = v + 0.02 * fbm(g, u, v, creaseCells, 2, 0.5, 5);
            const double ridge = std::abs(fbm(g, warpU, warpV, creaseCells, 3, 0.5, 6));
            const double crease = 1.0 - smoothstep(0.0, 0.022, ridge);
            const double tooth = fbm(g, u, v, toothCells, 2, 0.6, 3);
            const double f = fibres.v[c.at(x, y)];
            double t = 0.10 + blot * 0.65 * amount + mottle * 0.10 * amount + crease * 0.12 * amount + f * 0.8;
            Rgb col = mix(p.base, p.accent, clamp01(t) * 0.80);
            col = scaled(col, 1.0 + tooth * 0.03);
            c.px[c.at(x, y)] = col;
            c.height[c.at(x, y)] = 0.5 + tooth * 0.12 - crease * 0.16 + mottle * 0.1;
        }
    }
    shade_by_height(c, 0.9);
}

void draw_wood(Canvas& c, const Params& p, const Grid& g) {
    const int rings = std::max(3, int(std::lround(16.0 / p.scale)));
    const Cells warpCells = {std::max(1, int(std::lround(2.0 / p.scale))), std::max(1, int(std::lround(5.0 / p.scale)))};
    const Cells swayCells = {1, std::max(1, int(std::lround(2.0 / p.scale)))};
    const Cells streakCells = {std::max(1, int(std::lround(4.0 / p.scale))), std::max(1, int(std::lround(c.h / 2.0)))};
    const Cells poreCells = {std::max(1, int(std::lround(c.w / (10.0 * p.scale)))), std::max(1, int(std::lround(c.h / 1.6)))};
    const Cells tintCells = g.per_short(1.5 / p.scale);
    const Cells widthCells = {1, std::max(1, int(std::lround(3.0 / p.scale)))};
    const double amount = 0.4 + 0.6 * p.rough;
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            const double sway = fbm(g, u, v, swayCells, 2, 0.5, 7);
            const double warp = fbm(g, u, v, warpCells, 4, 0.55, 1);
            const double t = v * rings + sway * (0.9 + 1.4 * amount) + warp * (0.25 + 0.7 * amount);
            const double f = t - std::floor(t);
            // early wood fades slowly into a thin dark late-wood band that stops abruptly at the next ring
            const double late = std::pow(f, 3.2);
            const double ringContrast = 0.7 + 0.5 * (fbm(g, u, v, widthCells, 2, 0.5, 8));
            const double streak = fbm(g, u, v, streakCells, 3, 0.6, 2) * 0.5 + 0.5;
            const double pore = vnoise(u * poreCells.x, v * poreCells.y, c.tile ? poreCells.x : 0, c.tile ? poreCells.y : 0, g.seed + 9u);
            const double tint = fbm(g, u, v, tintCells, 3, 0.5, 4);
            const double poreDark = smoothstep(0.80, 0.95, pore);
            const double hair = std::pow(0.5 + 0.5 * std::sin((t * 3.7 + streak * 3.0) * kPi * 2), 8.0);
            double tone = 0.12 + hair * 0.22 * amount + late * 0.55 * ringContrast + (streak - 0.5) * 0.40 * amount + tint * 0.10 - poreDark * 0.20 * amount;
            Rgb col = mix(p.base, p.accent, clamp01(tone));
            col = scaled(col, 1.0 + tint * 0.08 * amount);
            c.px[c.at(x, y)] = col;
            c.height[c.at(x, y)] = 0.5 + (streak - 0.5) * 0.30 - late * 0.12 * ringContrast - poreDark * 0.25;
        }
    }
    shade_by_height(c, 0.8);
}

void draw_planks(Canvas& c, const Params& p, const Grid& g) {
    const int rows = p.plankCount > 0 ? p.plankCount : std::max(2, int(std::lround(6.0 / p.scale)));
    const double ph = double(c.h) / rows;
    const double gap = std::max(1.0, ph * p.gapWidth), bevel = std::max(1.5, ph * 0.04 + gap * 0.5);
    // plankLength 0: every board runs from side to side and has no butt joint; otherwise `segs` boards fill a row
    const bool joined = p.plankLength > 0;
    const int segs = joined ? std::max(1, int(std::lround(1.0 / p.plankLength))) : 1;
    const Cells warpCells = {std::max(1, segs), std::max(1, rows * 3)};
    const Cells streakCells = {std::max(1, segs * 2), std::max(1, int(std::lround(c.h / 2.2)))};
    const double amount = 0.4 + 0.6 * p.rough;
    // joints of each row: `segs` boundaries around the row (the row wraps), jittered, from a per-row offset
    std::vector<std::vector<double>> joints(rows, std::vector<double>(segs));
    for (int r = 0; r < rows; ++r) {
        const double off = rand01(r, 3, p.seed + 31u) * c.w;
        for (int k = 0; joined && k < segs; ++k) {
            joints[r][k] = std::fmod(off + (k + (rand01(r, k + 100, p.seed + 32u) - 0.5) * 0.45) * (double(c.w) / segs) + c.w, double(c.w));
        }
        std::sort(joints[r].begin(), joints[r].end());
        if (!joined) joints[r][0] = 0;
    }
    for (int y = 0; y < c.h; ++y) {
        const int r = std::min(rows - 1, int(y / ph));
        const double local = y + 0.5 - r * ph;                        // pixels from the top of the plank
        const double edge = std::min(local, ph - local);              // pixels from the nearest long edge
        for (int x = 0; x < c.w; ++x) {
            const std::vector<double>& js = joints[r];
            // the plank is the interval between two joints (the last one wraps to the first)
            int seg = int(js.size()) - 1;
            for (int k = 0; k < int(js.size()); ++k) {
                if (x + 0.5 >= js[k]) seg = k;
                else break;
            }
            const double start = js[seg], endp = js[(seg + 1) % js.size()];
            double dStart = x + 0.5 - start;
            if (dStart < 0) dStart += c.w;
            double dEnd = endp - (x + 0.5);
            if (dEnd <= 0) dEnd += c.w;
            const double jointEdge = joined ? std::min(dStart, dEnd) : 1e9;
            const double edgeD = std::min(edge, jointEdge);
            const u32 pid = hash3(r, seg, p.seed + 33u);
            const double tone = 0.80 + 0.40 * unit(pid), shift = unit(mix_bits(pid ^ 0x2545f491u)) * 40.0;
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            const double warp = fbm(g, u, v + shift, warpCells, 3, 0.55, 1);
            const double lv = local / ph;
            const double t = lv * (2.0 + 2.0 * unit(mix_bits(pid ^ 0x9e3779b9u))) + warp * (0.7 + 1.4 * amount) + shift;
            const double f = t - std::floor(t);
            const double ring = 0.6 * std::pow(f, 2.3) + 0.4 * (0.5 + 0.5 * std::sin(f * kPi * 2 - kPi / 2));
            const double streak = fbm(g, u + shift, v, streakCells, 3, 0.6, 2) * 0.5 + 0.5;
            double toneMix = 0.12 + ring * 0.50 + (streak - 0.5) * 0.5 * amount;
            Rgb col = scaled(mix(p.base, p.accent, clamp01(toneMix)), tone);
            double hgt = 0.5 + (streak - 0.5) * 0.15 - ring * 0.08;
            // the gaps between boards are dark, with a rounded edge on each board
            const double inBoard = smoothstep(gap * 0.5, gap * 0.5 + bevel, edgeD);
            const double gapDark = 1.0 - smoothstep(gap * 0.4, gap * 1.4, edgeD);
            col = mix(col, scaled(p.accent, 0.30), gapDark * p.gapDarkness);
            col = scaled(col, 1.0 - (0.14 * p.gapDarkness + 0.04) * (1.0 - inBoard));
            hgt = hgt * 0.25 + inBoard * 0.75;
            c.px[c.at(x, y)] = col;
            c.height[c.at(x, y)] = hgt;
        }
    }
    shade_by_height(c, 1.2);
}

void draw_leather(Canvas& c, const Params& p, const Grid& g) {
    const Cells grainCells = g.per_short(20.0 / p.scale), fineCells = g.per_short(60.0 / p.scale), warpCells = g.per_short(6.0 / p.scale),
                wearCells = g.per_short(3.0 / p.scale), wrinkleCells = g.per_short(8.0 / p.scale);
    const double amount = 0.4 + 0.6 * p.rough;
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            const double wu = u + 0.012 * fbm(g, u, v, warpCells, 2, 0.5, 1), wv = v + 0.012 * fbm(g, u, v, warpCells, 2, 0.5, 2);
            const Worley a = worley(g, wu, wv, grainCells, 0.95, 1);
            const Worley b = worley(g, wu, wv, fineCells, 0.9, 2);
            // pebbles: domed plateaus separated by narrow creases
            const double groove = smoothstep(0.0, 0.10 + 0.10 * (1.0 - amount), a.edge);
            const double dome = 1.0 - clamp01(a.f1 * 0.9);
            const double peb = groove * (0.55 + 0.45 * dome);
            const double fine = smoothstep(0.0, 0.12, b.edge);
            const double wr = std::abs(fbm(g, u, v, wrinkleCells, 3, 0.5, 3));
            const double wrinkle = 1.0 - smoothstep(0.0, 0.05, wr);
            const double wear = fbm(g, u, v, wearCells, 4, 0.55, 4) * 0.5 + 0.5;
            const double cellTone = unit(a.id) - 0.5;
            const double h = peb * 0.7 + fine * 0.10 - wrinkle * 0.18 * amount;
            double lightT = 0.50 + (wear - 0.5) * 0.9 + cellTone * 0.10 * amount;
            Rgb col = scaled(mix(scaled(p.base, 0.82), scaled(p.base, 1.12), clamp01(lightT)), 0.85 + 0.25 * peb);
            col = mix(scaled(p.accent, 0.75), col, 0.55 + 0.45 * groove);
            c.px[c.at(x, y)] = col;
            c.height[c.at(x, y)] = h;
        }
    }
    shade_by_height(c, 1.3 + 0.6 * amount);
    // a soft sheen on the bumps that face the light
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            double dx, dy;
            slope(c, x, y, dx, dy);
            const double sheen = std::pow(clamp01((dx + dy) * 1.2), 1.6) * 0.18;
            Rgb& px = c.px[c.at(x, y)];
            px.r += sheen * px.r;
            px.g += sheen * px.g;
            px.b += sheen * px.b;
        }
    }
}

// How a woven preset differs from another: the number of threads across the short side at scale 1, how uneven the weave, the
// threads' tones and the slubs are (all 1 for fabric), and how deep the relief is shaded.
struct Weave {
    double threads = 52.0, unevenness = 1.0, toneSpread = 1.0, slubs = 1.0, relief = 1.0;
};

void draw_weave(Canvas& c, const Params& p, const Grid& g, const Weave& wv) {
    const double s = std::min(c.w, c.h);
    // thread counts are even so the over-under pattern repeats at the edge of a tileable image
    auto even = [](double v) { return std::max(2, int(std::lround(v / 2.0)) * 2); };
    const int tx = even(wv.threads / p.scale * c.w / s), ty = even(wv.threads / p.scale * c.h / s);
    const Cells warpCells = g.per_short(5.0 / p.scale), fibreCellsA = {tx * 3, ty / 2 > 0 ? ty / 2 : 1}, fibreCellsB = {tx / 2 > 0 ? tx / 2 : 1, ty * 3};
    const Cells mottleCells = g.per_short(2.5 / p.scale);
    const double amount = 0.3 + 0.7 * p.rough;
    // A thread a few pixels wide sampled once per pixel beats against the pixel grid (a plaid of big light and dark blocks): the
    // weave itself is averaged over n x n samples per pixel when a thread is narrower than ~5 pixels.
    const double pitch = std::min(double(c.w) / tx, double(c.h) / ty);
    const int n = std::clamp(int(std::ceil(5.0 / std::max(pitch, 0.25))), 1, 4);
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            // the weave is a little uneven: the grid is pushed around by a slow noise
            const double warpX = 0.16 * wv.unevenness * amount * fbm(g, u, v, warpCells, 2, 0.5, 1), warpY = 0.16 * wv.unevenness * amount * fbm(g, u, v, warpCells, 2, 0.5, 2);
            const double fib0 = fbm(g, u, v, fibreCellsA, 2, 0.5, 3), fib1 = fbm(g, u, v, fibreCellsB, 2, 0.5, 4);
            const double mottle = fbm(g, u, v, mottleCells, 3, 0.5, 5);
            Rgb sum{0, 0, 0, 0};
            double hsum = 0;
            for (int sy = 0; sy < n; ++sy) {
                for (int sx = 0; sx < n; ++sx) {
                    const double su = (x + (sx + 0.5) / n) / c.w, sv = (y + (sy + 0.5) / n) / c.h;
                    const double wx = su * tx + warpX, wy = sv * ty + warpY;
                    const int i = int(std::floor(wx)), j = int(std::floor(wy));
                    const double fx = wx - i, fy = wy - j;
                    const int ci = wrap_cell(i, tx), cj = wrap_cell(j, ty);
                    const bool vertical = ((ci + cj) & 1) == 0;  // which thread is on top in this crossing
                    const double across = vertical ? fx : fy, along = vertical ? fy : fx;
                    const int threadId = vertical ? ci : cj;
                    const u32 th = hash3(threadId, vertical ? 1 : 2, p.seed + 41u);
                    const u32 crossing = hash3(ci, cj, p.seed + 43u);  // a different value at every crossing: no period in the slubs
                    const double profile = std::pow(std::sin(kPi * across), 0.75);
                    const double taper = 0.60 + 0.40 * std::pow(std::sin(kPi * along), 0.8);
                    const double slub = 1.0 - 0.12 * wv.slubs * (0.5 + unit(crossing)) * (0.5 - 0.5 * std::sin(along * 2 * kPi + unit(th) * 6.0));
                    const double hgt = profile * taper * slub;
                    const double fib = vertical ? fib0 : fib1;
                    const double tint = 1.0 + (unit(th) - 0.5) * 0.22 * amount * wv.toneSpread + (unit(crossing) - 0.5) * 0.05 * wv.toneSpread + (vertical ? 0.015 : -0.015) * wv.toneSpread +
                                        mottle * 0.06 * amount * wv.toneSpread + fib * 0.07;
                    const Rgb col = mix(scaled(p.accent, 0.45), scaled(p.base, tint), 0.25 + 0.75 * clamp01(hgt));
                    sum.r += col.r;
                    sum.g += col.g;
                    sum.b += col.b;
                    sum.a += col.a;
                    hsum += hgt;
                }
            }
            const double inv = 1.0 / (n * n);
            c.px[c.at(x, y)] = {sum.r * inv, sum.g * inv, sum.b * inv, sum.a * inv};
            c.height[c.at(x, y)] = hsum * inv * 0.9 + (fib0 + fib1) * 0.02;
        }
    }
    shade_by_height(c, (0.8 + 0.4 * amount) * wv.relief);
}

void draw_fabric(Canvas& c, const Params& p, const Grid& g) { draw_weave(c, p, g, Weave{}); }
// Linen / bookcloth: a finer, more even weave with little contrast, for a book cover or a tablecloth.
void draw_linen(Canvas& c, const Params& p, const Grid& g) { draw_weave(c, p, g, Weave{92.0, 0.45, 0.4, 0.35, 0.55}); }

void draw_stone(Canvas& c, const Params& p, const Grid& g) {
    const Cells blockCells = g.per_short(4.5 / p.scale), warpCells = g.per_short(3.0 / p.scale), grainCells = g.per_short(24.0 / p.scale),
                crackCells = g.per_short(9.0 / p.scale), cloudCells = g.per_short(2.5 / p.scale), speckCells = g.per_px(1.6);
    const double amount = 0.35 + 0.65 * p.rough;
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            const double wu = u + 0.035 * fbm(g, u, v, warpCells, 3, 0.5, 1), wv = v + 0.035 * fbm(g, u, v, warpCells, 3, 0.5, 2);
            const Worley a = worley(g, wu, wv, blockCells, 0.85, 1);
            const double width = 0.06 + 0.05 * amount;
            const double joint = 1.0 - smoothstep(width * 0.25, width * 0.8, a.edge);
            const double blockTone = unit(a.id) - 0.5;
            const double rock = fbm(g, u, v, grainCells, 5, 0.6, 3);
            const double cloud = fbm(g, u, v, cloudCells, 4, 0.5, 4);
            const double ridged = 1.0 - std::abs(fbm(g, u, v, crackCells, 4, 0.55, 5));
            const double speck = fbm(g, u, v, speckCells, 2, 0.7, 6);
            const double edgeRound = smoothstep(0.0, 0.35, a.edge);
            const double hgt = edgeRound * 0.35 + rock * 0.20 * amount + std::pow(ridged, 5.0) * 0.18 * amount + 0.2;
            double t = 0.5 + blockTone * 0.35 + cloud * 0.30 * amount + rock * 0.18 * amount;
            Rgb col = mix(p.accent, p.base, clamp01(t));
            col = scaled(col, 1.0 + speck * 0.10 * amount - std::pow(ridged, 6.0) * 0.12);
            col = mix(col, scaled(p.accent, 0.35), joint * 0.85);
            c.px[c.at(x, y)] = col;
            c.height[c.at(x, y)] = hgt - joint * 0.22;
        }
    }
    shade_by_height(c, 1.0 + 0.6 * amount);
}

void draw_value(Canvas& c, const Params& p, const Grid& g) {
    const Cells cells = g.per_short(8.0 / p.scale);
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            const double n = vnoise(u * cells.x, v * cells.y, c.tile ? cells.x : 0, c.tile ? cells.y : 0, g.seed + 1u);
            c.px[c.at(x, y)] = mix(p.base, p.accent, n);
            c.height[c.at(x, y)] = n;
        }
    }
}

void draw_fbm(Canvas& c, const Params& p, const Grid& g) {
    const Cells cells = g.per_short(4.0 / p.scale);
    const int octaves = 3 + int(std::lround(p.rough * 4));
    const double gain = 0.35 + 0.35 * p.rough;
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            const double n = clamp01(0.5 + 0.55 * fbm(g, u, v, cells, octaves, gain, 1));
            c.px[c.at(x, y)] = mix(p.base, p.accent, n);
            c.height[c.at(x, y)] = n;
        }
    }
}

void draw_cellular(Canvas& c, const Params& p, const Grid& g) {
    const Cells cells = g.per_short(8.0 / p.scale);
    const double jitter = 0.4 + 0.6 * p.rough;
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            const Worley w = worley(g, u, v, cells, jitter, 1);
            const double n = clamp01(w.f1 * 1.05);
            c.px[c.at(x, y)] = mix(p.base, p.accent, n);
            c.height[c.at(x, y)] = 1.0 - n;
        }
    }
}

void draw_gradient(Canvas& c, const Params& p, const Grid&) {
    const double a = p.angle * kPi / 180.0;
    const double dx = std::sin(a), dy = std::cos(a);  // angle 0: top to bottom; 90: left to right
    const double half = 0.5 * (std::abs(dx) + std::abs(dy));
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w - 0.5, v = (y + 0.5) / c.h - 0.5;
            const double t = clamp01((u * dx + v * dy) / (2 * half * p.scale) + 0.5);
            c.px[c.at(x, y)] = mix(p.base, p.accent, t);
            c.height[c.at(x, y)] = t;
        }
    }
}

// Distance from the middle, 0 at the centre and 1 at the corners (an ellipse that touches the four corners).
double radial_distance(const Canvas& c, int x, int y) {
    const double u = ((x + 0.5) / c.w - 0.5) * 2, v = ((y + 0.5) / c.h - 0.5) * 2;
    return std::sqrt(u * u + v * v) / std::sqrt(2.0);
}

void draw_radial(Canvas& c, const Params& p, const Grid&) {
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double t = clamp01(radial_distance(c, x, y) / p.scale);
            c.px[c.at(x, y)] = mix(p.base, p.accent, smoothstep(0, 1, t));
            c.height[c.at(x, y)] = 1.0 - t;
        }
    }
}

void draw_vignette(Canvas& c, const Params& p, const Grid&) {
    const double outer = std::clamp(1.0 * p.scale, 0.2, 3.0);
    const double inner = outer * (1.0 - (0.15 + 0.85 * p.rough) * 0.95);
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double t = smoothstep(inner, outer, radial_distance(c, x, y));
            Rgb col = p.base;
            col.a = p.base.a * p.vignette * t;
            c.px[c.at(x, y)] = col;
            c.height[c.at(x, y)] = 1.0 - t;
        }
    }
}

const Preset kPresets[] = {
    {"paper", "cream paper: fibres, mottling and a fine tooth", "#efe6d2 paper, #bba67f shadow tone", hex(0xefe6d2), hex(0xbba67f), 0, true, true, draw_paper},
    {"parchment", "old parchment: warm stains, creases and (when not tileable) darkened edges", "#e1c98f skin, #8b5a2b stain", hex(0xe1c98f),
     hex(0x8b5a2b), 0.5, true, true, draw_parchment},
    {"wood", "wood grain: growth rings, streaks and pores along the width", "#b07a45 light wood, #4f2f17 late wood", hex(0xb07a45), hex(0x4f2f17), 0, true, true, draw_wood},
    {"planks", "wooden planks (a floor or a desk top) with joints, gaps and a different grain in every board", "#a9743f wood, #3d2412 gaps and grain",
     hex(0xa9743f), hex(0x3d2412), 0, true, true, draw_planks},
    {"leather", "pebbled leather with creases, wear and a soft sheen", "#7a4a2a leather, #2a150a creases", hex(0x7a4a2a), hex(0x2a150a), 0, true, true, draw_leather},
    {"fabric", "woven cloth (plain weave): threads that go over and under, slubs and uneven tone", "#c4b490 thread, #6b5c3e shadows", hex(0xc4b490),
     hex(0x6b5c3e), 0, true, true, draw_fabric},
    {"linen", "linen or bookcloth: a fine, even, low-contrast weave (finer and quieter than fabric)", "#d9cfb6 thread, #a99d82 shadows", hex(0xd9cfb6),
     hex(0xa99d82), 0, true, true, draw_linen},
    {"stone", "flagstone: blocks with joints, grain, cracks and speckles", "#9a968e stone, #4a4640 joints and cracks", hex(0x9a968e), hex(0x4a4640), 0, true, true, draw_stone},
    {"value", "value noise (smooth blobs) from `color` to `accent`", "#202020 to #f2f2f2", hex(0x202020), hex(0xf2f2f2), 0, true, false, draw_value},
    {"fbm", "fractal noise (clouds; `roughness` adds octaves) from `color` to `accent`", "#202020 to #f2f2f2", hex(0x202020), hex(0xf2f2f2), 0, true, false, draw_fbm},
    {"cellular", "cellular (Worley) noise: distance to the nearest point, from `color` (at a point) to `accent`", "#202020 to #f2f2f2", hex(0x202020),
     hex(0xf2f2f2), 0, true, false, draw_cellular},
    {"gradient", "a linear gradient from `color` to `accent` along `angle` (the alphas of the colours are blended too)", "#f4ead5 to #8c6a42", hex(0xf4ead5),
     hex(0x8c6a42), 0, false, false, draw_gradient},
    {"radial", "a radial gradient: `color` in the middle to `accent` at the corners (`scale` is the radius, 1 = the corners)", "#f4ead5 to #5a3d22",
     hex(0xf4ead5), hex(0x5a3d22), 0, false, false, draw_radial},
    {"vignette", "a transparent middle fading to `color` at the edges (an overlay for a scene: put it over a Sprite); `vignette` is its strongest alpha",
     "#000000", hex(0x000000), hex(0x000000), 0.85, false, false, draw_vignette},
};

const Preset* find_preset(const std::string& name) {
    for (const Preset& p : kPresets) {
        if (name == p.name) return &p;
    }
    return nullptr;
}

std::vector<std::string> preset_names() {
    std::vector<std::string> out;
    for (const Preset& p : kPresets) out.push_back(p.name);
    return out;
}

// Darkens the edges with a worn border, towards a dark version of the accent colour: a burnt page, a thumbed book. The border
// is `p.vignetteWidth` of the picture's short side wide, and its inner edge is irregular: a slow noise moves it in and out by
// about its own width, and a finer one eats into it, so it reads as wear, not as a frame. (It used to be a uniform band
// about 0.17 wide; vignetteWidth 0.17 gives that width back.)
void apply_edge_vignette(Canvas& c, const Params& p, const Grid& g, double amount) {
    const double width = std::max(p.vignetteWidth, 1e-4);
    const Cells slow = g.per_short(7.0), fine = g.per_short(40.0), grit = g.per_px(1.5);
    const double shortSide = std::min(c.w, c.h);
    const Rgb dark = scaled(p.accent, 0.5);
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const double u = (x + 0.5) / c.w, v = (y + 0.5) / c.h;
            const double d = std::min({u * c.w, (1 - u) * c.w, v * c.h, (1 - v) * c.h}) / shortSide;  // distance to the nearest edge, in short sides
            const double ragged = d - width * (0.55 * fbm(g, u, v, slow, 3, 0.55, 90) + 0.35 * fbm(g, u, v, fine, 3, 0.55, 91));
            double burn = smoothstep(width * 1.15, width * 0.0, ragged);
            burn *= 0.8 + 0.2 * fbm(g, u, v, grit, 2, 0.6, 92);
            burn = clamp01(burn * (0.4 + amount * 1.2));
            Rgb& px = c.px[c.at(x, y)];
            px = mix(px, {dark.r * (px.r + 0.35), dark.g * (px.g + 0.35), dark.b * (px.b + 0.35), px.a}, burn);
        }
    }
}

// ---- output ---------------------------------------------------------------------------------------------------------

std::uint8_t to_byte(double v, double dither) { return std::uint8_t(std::clamp(std::floor(v * 255.0 + 0.5 + dither), 0.0, 255.0)); }

// Triangular dither of about one level, so smooth gradients do not band.
double dither_at(int x, int y, u32 seed) { return rand01(x, y, seed + 0xd17e5u) - rand01(x, y, seed + 0xd17e6u); }

Image to_image(const Canvas& c, u32 seed, bool dither) {
    Image img;
    img.width = c.w;
    img.height = c.h;
    img.rgba.resize(std::size_t(c.w) * c.h * 4);
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            const Rgb& p = c.px[c.at(x, y)];
            std::uint8_t* o = &img.rgba[c.at(x, y) * 4];
            const double d = dither ? dither_at(x, y, seed) : 0.0;
            o[0] = to_byte(p.r, d);
            o[1] = to_byte(p.g, d);
            o[2] = to_byte(p.b, d);
            o[3] = to_byte(p.a, d);
        }
    }
    return img;
}

// Tangent-space normal map (+X right, +Y up the picture, like Sprite.normalMap and glTF) from the height field.
Image normal_map(const Canvas& c, double strength) {
    Image img;
    img.width = c.w;
    img.height = c.h;
    img.rgba.resize(std::size_t(c.w) * c.h * 4);
    for (int y = 0; y < c.h; ++y) {
        for (int x = 0; x < c.w; ++x) {
            double dx, dy;
            slope(c, x, y, dx, dy);
            double nx = -dx * strength * 4.0, ny = dy * strength * 4.0, nz = 1.0;  // up the picture is -y of the pixel grid
            const double len = std::sqrt(nx * nx + ny * ny + nz * nz);
            nx /= len;
            ny /= len;
            nz /= len;
            std::uint8_t* o = &img.rgba[c.at(x, y) * 4];
            o[0] = to_byte(nx * 0.5 + 0.5, 0);
            o[1] = to_byte(ny * 0.5 + 0.5, 0);
            o[2] = to_byte(nz * 0.5 + 0.5, 0);
            o[3] = 255;
        }
    }
    return img;
}

// ---- the command ----------------------------------------------------------------------------------------------------

constexpr const char* kCommand = "assets.generate_texture";

double number_arg(const Json& a, const char* key, double def, double lo, double hi, const char* hint) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number()) arg_error(kCommand, std::string("/") + key, "expected a number.", hint);
    const double v = it->get<double>();
    if (!(v >= lo && v <= hi)) arg_error(kCommand, std::string("/") + key, std::format("{} is outside {} to {}.", v, lo, hi), hint);
    return v;
}

int size_arg(const Json& a, const char* key, int def) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number_integer() || it->get<long long>() < 8 || it->get<long long>() > kMaxSide)
        arg_error(kCommand, std::string("/") + key, std::format("expected a whole number of pixels from 8 to {}.", kMaxSide),
                  std::format("Make a texture up to {0}x{0} and tile it (Sprite.tiled / uvScale) for larger areas.", kMaxSide));
    return int(it->get<long long>());
}

void write_png_asset(const std::string& projectDir, const std::string& rel, const Image& img, const Json& provenance) {
    bool opaque = true;
    for (std::size_t i = 3; i < img.rgba.size(); i += 4) opaque = opaque && img.rgba[i] == 255;
    const std::vector<std::uint8_t> png = opaque ? encode_png_rgb(img) : encode_png(img);
    std::string err;
    if (!tooling_detail::write_file(project_file(projectDir, rel), std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err))
        fail("failed", err);
    ProjectRootGuard root(projectDir);
    auto r = assets::update_entry(rel, [&](Json& e) {
        e.erase("analysis");
        e.erase("sheet");
        e["provenance"] = provenance;
    });
    if (!r.ok()) fail("failed", "'" + rel + "' was written, but assets.json was not updated: " + r.error().message, r.error().hint);
}

std::string checked_png_path(const std::string& path) {
    auto norm = fs::normalize_checked(path);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", "The texture goes under assets/, and '" + path + "' is not there.", "Use a path such as \"assets/textures/paper.png\".");
    if (to_lower(fs::extension(*norm)) != ".png")
        fail("invalid_argument", std::string(kCommand) + " writes PNG files, and '" + *norm + "' does not end in .png.",
             "Use a path such as \"assets/textures/paper.png\".");
    return *norm;
}

Json generate_texture(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "assets.generate_texture expects an object.", "See the description of the command for the fields.");
    check_arg_keys(kCommand, a, "",
                   {"path", "preset", "width", "height", "seed", "color", "accent", "scale", "roughness", "tileable", "vignette", "vignetteWidth", "angle",
                    "normalMap", "normalStrength", "overwrite", "author", "plankCount", "plankLength", "gapWidth", "gapDarkness"});
    const std::string presetName = to_lower(tooling_detail::arg_string(a, "preset", true));
    const Preset* preset = find_preset(presetName);
    if (!preset) {
        const auto names = preset_names();
        fail("invalid_argument", "Unknown preset '" + presetName + "'.", did_you_mean(presetName, names) + " Presets: " + join(names, ", ") + ".");
    }
    const std::string rel = checked_png_path(tooling_detail::arg_string(a, "path", true));
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    Params p;
    p.w = size_arg(a, "width", 512);
    p.h = size_arg(a, "height", a.contains("width") ? p.w : 512);
    p.seed = u32(mix_bits(u32(tooling_detail::arg_int(a, "seed", 0))) ^ mix_bits(u32(tooling_detail::arg_int(a, "seed", 0) >> 32) + 0x51ed27u));
    p.base = preset->base;
    p.accent = preset->accent;
    if (a.contains("color")) p.base = from_color(colour_arg(kCommand, a["color"], "/color"));
    if (a.contains("accent")) p.accent = from_color(colour_arg(kCommand, a["accent"], "/accent"));
    p.scale = number_arg(a, "scale", 1.0, 0.1, 10.0, "1 is the preset's natural size; 2 makes every feature twice as big, 0.5 half as big.");
    p.rough = number_arg(a, "roughness", 0.5, 0.0, 1.0, "0 is smooth and even, 1 is rough and uneven; 0.5 is the default.");
    p.vignette = number_arg(a, "vignette", preset->vignette, 0.0, 1.0, "0 is no darkened edge, 1 a strong one.");
    p.vignetteWidth = number_arg(a, "vignetteWidth", p.vignetteWidth, 0.005, 0.5, "A fraction of the picture's short side: 0.035 (the default) is a narrow worn edge, 0.17 a wide frame.");
    p.angle = number_arg(a, "angle", 0.0, -360.0, 360.0, "Degrees: 0 runs from the top to the bottom, 90 from the left to the right.");
    p.tile = tooling_detail::arg_bool(a, "tileable", false);
    if (a.contains("plankCount") && !a["plankCount"].is_null()) {
        const Json& pc = a["plankCount"];
        if (!pc.is_number_integer() || pc.get<long long>() < 1 || pc.get<long long>() > 64)
            arg_error(kCommand, "/plankCount", "expected a whole number of boards from 1 to 64.", "It is how many boards are stacked from the top to the bottom of the picture; leave it out to follow `scale`.");
        p.plankCount = int(pc.get<long long>());
    }
    p.plankLength = number_arg(a, "plankLength", p.plankLength, 0.0, 1.0, "A fraction of the picture's width: 0 is boards that run from side to side, 0.5 is two boards per row, 0.25 four.");
    p.gapWidth = number_arg(a, "gapWidth", p.gapWidth, 0.0, 0.2, "A fraction of a board's width: 0.01 is a fine seam, 0.05 a wide gap.");
    p.gapDarkness = number_arg(a, "gapDarkness", p.gapDarkness, 0.0, 1.0, "0 leaves the gaps the colour of the wood, 1 makes them as dark as the accent allows.");
    const bool wantNormal = tooling_detail::arg_bool(a, "normalMap", false);
    const double normalStrength = number_arg(a, "normalStrength", 3.0, 0.1, 20.0, "3 is a clear relief; 1 is subtle, 10 is deep.");
    const std::string author = tooling_detail::arg_string(a, "author", false, "factoria");

    std::vector<std::string> warnings;
    if (p.tile && !preset->canTile) {
        warnings.push_back(std::format("tileable was ignored: a {} has an edge by nature. Use paper, wood, leather or another material preset to tile.", presetName));
        p.tile = false;
    }
    if (p.tile && a.contains("vignette") && p.vignette > 0 && presetName != "vignette") {
        warnings.push_back("vignette was ignored: a darkened edge does not repeat. Leave tileable off for a page or a cover.");
        p.vignette = 0;
    } else if (p.tile && presetName != "vignette") {
        p.vignette = 0;  // the preset's own edge darkening (parchment) is for single pictures
    }
    if (presetName != "planks") {
        for (const char* key : {"plankCount", "plankLength", "gapWidth", "gapDarkness"})
            if (a.contains(key)) warnings.push_back(std::string(key) + " only changes the planks preset; it was ignored.");
    }
    if (a.contains("vignetteWidth") && !a["vignetteWidth"].is_null() && (presetName == "vignette" || p.vignette <= 0))
        warnings.push_back("vignetteWidth only matters when the edge is darkened (a `vignette` above 0 on a preset other than vignette, not tileable); it was ignored.");
    if (p.angle != 0 && presetName != "gradient") warnings.push_back("angle only turns the gradient preset; it was ignored.");
    if (wantNormal && (presetName == "gradient" || presetName == "radial" || presetName == "vignette"))
        warnings.push_back("a gradient has no relief, so its normal map is flat.");

    std::string normalRel;
    if (wantNormal) {
        const std::string stem = rel.substr(0, rel.size() - 4);
        normalRel = checked_png_path(stem + "_n.png");
    }
    if (!overwrite) {
        for (const std::string& f : {rel, normalRel}) {
            std::error_code ec;
            if (!f.empty() && stdfs::exists(project_file(projectDir, f), ec)) fail("exists", "'" + f + "' already exists.", "Pass overwrite: true to replace it, or choose another `path`.");
        }
    }
    require_usable_manifest(projectDir);

    Grid grid;
    grid.w = p.w;
    grid.h = p.h;
    grid.tile = p.tile;
    grid.seed = p.seed;
    Canvas canvas(p.w, p.h, p.tile);
    preset->draw(canvas, p, grid);
    if (p.vignette > 0 && presetName != "vignette") apply_edge_vignette(canvas, p, grid, p.vignette);
    const Image image = to_image(canvas, p.seed, !preset->textured);

    const long seedArg = tooling_detail::arg_int(a, "seed", 0);
    Json used = Json::object({{"preset", presetName}, {"width", p.w}, {"height", p.h}, {"seed", seedArg}, {"scale", p.scale}, {"roughness", p.rough}});
    if (a.contains("color")) used["color"] = a["color"];
    if (a.contains("accent")) used["accent"] = a["accent"];
    if (p.tile) used["tileable"] = true;
    if (p.vignette > 0 && presetName != "vignette") {
        used["vignette"] = p.vignette;
        used["vignetteWidth"] = p.vignetteWidth;
    }
    if (presetName == "gradient") used["angle"] = p.angle;
    if (presetName == "planks") {
        if (p.plankCount > 0) used["plankCount"] = p.plankCount;
        used["plankLength"] = p.plankLength;
        used["gapWidth"] = p.gapWidth;
        used["gapDarkness"] = p.gapDarkness;
    }
    const std::string notes = "Procedural texture from assets.generate_texture " + used.dump() + ". Same arguments, same picture.";
    const Json recipe = make_recipe(projectDir, kCommand, recipe_args(a, {{"path", rel}, {"seed", seedArg}}), {});
    auto provenance_for = [&](const std::string& extra) {
        return Json::object({{"origin", "original"}, {"ai", false}, {"kind", "image"}, {"provider", "factoria assets.generate_texture"}, {"seed", seedArg},
                             {"license", "CC0-1.0"}, {"author", author}, {"notes", notes + extra}, {"date", assets::today()}, {"recipe", recipe}});
    };
    const Json provenance = provenance_for("");
    write_png_asset(projectDir, rel, image, provenance);
    Json result = Json::object({{"path", rel}, {"preset", presetName}, {"width", p.w}, {"height", p.h}, {"seed", seedArg}, {"tileable", p.tile}, {"provenance", provenance}});
    if (wantNormal) {
        write_png_asset(projectDir, normalRel, normal_map(canvas, normalStrength), provenance_for(" This is its tangent-space normal map (+Y up)."));
        result["normalMap"] = normalRel;
    }
    if (!warnings.empty()) result["warnings"] = warnings;
    result["$image"] = Json::object({{"path", project_file(projectDir, rel).string()}, {"mimeType", "image/png"}});
    Json next = Json::array({"Use it as a Sprite texture (Sprite.texture \"" + rel + "\"), a MeshRenderer texture or a background; look at the picture in this result and change the arguments if it is not what you want."});
    if (p.tile) next.push_back("It tiles: repeat it with several Sprites side by side, or MeshRenderer.uvScale on a 3D surface.");
    if (wantNormal) next.push_back("Set Sprite.normalMap to \"" + normalRel + "\" with lit: true (and a Light2D), or MeshRenderer.normalMap, for relief under light.");
    next.push_back("Another take: change `seed`. A different material: change `preset`, `color` and `accent`.");
    result["nextSteps"] = next;
    return result;
}

}  // namespace

void register_texture_command(CommandRegistry& registry, const std::string& projectDir) {
    std::string presets;
    for (const Preset& p : kPresets) presets += std::string("\n- ") + p.name + ": " + p.what + " (default colours " + p.palette + ").";
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Make a material texture (paper, parchment, wood, planks, leather, fabric, stone, noise, gradient, vignette) offline: a seeded PNG, no provider and no key.";
    info.description =
        "Paints a procedural texture at `path` (under assets/, ending in .png) with no AI provider and no key: free, offline and seeded "
        "(the same arguments give the same picture with the same build of factoria; another `seed` is another take of the material). Use it for backgrounds, "
        "desks, book covers and pages, floors, walls and surfaces when no image provider is configured (assets.generate_image would fail with "
        "no_provider), or when you want a flat material you can tune: `color` and `accent` recolour it, `scale` makes the features bigger or "
        "smaller, `roughness` goes from smooth and even (0) to worn and uneven (1), `tileable` makes the picture repeat with no seam, "
        "`normalMap` also writes a tangent-space normal map next to it (`<name>_n.png`, +Y up) for lit sprites and 3D materials. "
        "Textures are lit from the upper left, so grooves and bumps read. It makes surfaces, not drawings: for a picture of a subject (a "
        "portrait, an icon, an ornament) write an SVG and call assets.rasterize_svg. Records provenance in assets.json (origin original, ai false, "
        "license CC0, the arguments in the notes). Look at the picture in the result and adjust. Presets:" + presets +
        "\nExamples: {\"path\":\"assets/textures/desk.png\",\"preset\":\"planks\",\"width\":1280,\"height\":720,\"seed\":4} / "
        "{\"path\":\"assets/textures/long_planks.png\",\"preset\":\"planks\",\"plankCount\":7,\"plankLength\":0,\"gapWidth\":0.01} / "
        "{\"path\":\"assets/textures/cover.png\",\"preset\":\"leather\",\"color\":\"#5b2a1a\",\"accent\":\"#1d0d07\",\"normalMap\":true} / "
        "{\"path\":\"assets/textures/page.png\",\"preset\":\"parchment\",\"width\":640,\"height\":900,\"vignette\":0.6} / "
        "{\"path\":\"assets/textures/floor.png\",\"preset\":\"stone\",\"tileable\":true,\"scale\":2}";
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"path", "preset"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"path", Json::object({{"type", "string"}, {"description", "Where to write the PNG, project-relative, under assets/ and ending in .png, e.g. \"assets/textures/paper.png\"."}})},
               {"preset", Json::object({{"type", "string"}, {"enum", preset_names()}, {"description", "The material or pattern. See the list in the command description."}})},
               {"width", Json::object({{"type", "integer"}, {"minimum", 8}, {"maximum", kMaxSide}, {"default", 512}, {"description", "Width in pixels (up to 2048; tile it for larger areas)."}})},
               {"height", Json::object({{"type", "integer"}, {"minimum", 8}, {"maximum", kMaxSide}, {"description", "Height in pixels. Default: the width (512 when neither is given)."}})},
               {"seed", Json::object({{"type", "integer"}, {"default", 0}, {"description", "Chooses the take: the same arguments always give the same file; change it for another sample of the material."}})},
               {"color", Json::object({{"description", "The main colour: \"#rrggbb\", \"#rrggbbaa\", a name like \"white\" or [r, g, b] in 0..1. Default: the preset's own (see the preset list). For vignette, the colour of the shade; for gradient, the start."}})},
               {"accent", Json::object({{"description", "The second colour (shadow, late wood, creases, joints, the far end of a gradient). Same formats as `color`. Default: the preset's own."}})},
               {"scale", Json::object({{"type", "number"}, {"minimum", 0.1}, {"maximum", 10}, {"default", 1}, {"description", "Size of the features: 1 is the preset's natural size relative to the picture, 2 makes them twice as big, 0.5 half as big (more planks, finer weave, smaller pebbles). For radial and vignette it is the radius (1 reaches the corners); for gradient it stretches the ramp."}})},
               {"roughness", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"default", 0.5}, {"description", "0 is smooth and even, 1 is worn and uneven (more stains, deeper creases, a rougher weave). For vignette: the softness of the edge; for cellular: how irregular the cells are."}})},
               {"tileable", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Make the picture repeat with no seam at its edges. The material presets and the noises can; gradient, radial and vignette have an edge by nature and ignore it (with a warning)."}})},
               {"vignette", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "Darkens the edge with a narrow, irregular worn border (a thumbed page, a burnt corner) on any preset except gradient and radial; ignored when tileable. How strong: 0.5 for parchment by default, 0 for the others. How wide: `vignetteWidth`. For the vignette preset it is the alpha at the edge (default 0.85)."}})},
               {"vignetteWidth", Json::object({{"type", "number"}, {"minimum", 0.005}, {"maximum", 0.5}, {"description", "How wide the darkened edge is (see `vignette`), as a fraction of the picture's short side. Default 0.035: a narrow band whose inner edge is ragged, like wear. 0.1 is a visible frame; 0.17 gives the wide uniform frame that earlier versions drew. Ignored when no edge is darkened."}})},
               {"angle", Json::object({{"type", "number"}, {"minimum", -360}, {"maximum", 360}, {"default", 0}, {"description", "gradient only: direction in degrees. 0 runs from the top to the bottom, 90 from the left to the right."}})},
               {"normalMap", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Also write the tangent-space normal map of the same relief as <path without .png>_n.png (+X right, +Y up the picture, the convention of Sprite.normalMap and glTF), with its own provenance record."}})},
               {"normalStrength", Json::object({{"type", "number"}, {"minimum", 0.1}, {"maximum", 20}, {"default", 3}, {"description", "How deep the relief of the normal map is: 1 subtle, 3 clear, 10 deep."}})},
               {"plankCount", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", 64}, {"description", "planks only: how many boards are stacked from the top to the bottom of the picture (each runs from left to right). Default: follows `scale` (6 at scale 1)."}})},
               {"plankLength", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "planks only (default 1): the length of a board as a fraction of the picture's width. 0 makes every board run from side to side with no butt joint (a desk top); 1 (the default) gives each row one joint, 0.5 two boards per row, 0.25 four. Joints are staggered row by row."}})},
               {"gapWidth", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 0.2}, {"description", "planks only (default 0.015): the gap between boards as a fraction of a board's width (at least one pixel). 0.015 is a fine seam, 0.05 a wide gap."}})},
               {"gapDarkness", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "planks only (default 0.55): how dark the gaps are. 0 leaves them the colour of the wood (only the bevel shows), 1 makes them nearly as dark as `accent` allows."}})},
               {"overwrite", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Replace the file when it already exists."}})},
               {"author", Json::object({{"type", "string"}, {"description", "Who gets the credit in the provenance record. Default: \"factoria\"."}})}})}});
    registry.add(info, [projectDir](const Json& args) { return generate_texture(projectDir, args); });
}

}  // namespace fa::assets_detail
