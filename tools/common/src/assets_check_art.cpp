// assets.check_art: look at pictures the way the game will show them and measure what a viewer needs: do the colours fit the
// house style, does the sprite stand out from what is drawn behind it, does it still read at the size it has on a phone and
// on a desktop screen, are there halos on its alpha edges, and, for several pictures, do they look like one set. The numbers
// are the ones of art_check.h (the style rules are the very ones `project.validate` warns about); the picture has the sprite
// as it is, in value (greyscale), over each background, and at its on-screen size. docs/ASSETS.md, "Checking art".
#include <algorithm>
#include <atomic>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/image_tools.h"
#include "fa/core/screenshot_files.h"
#include "fa/core/strings.h"
#include "fa/scene/world.h"
#include "fa/tooling/art_check.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kCommand = "assets.check_art";
constexpr std::size_t kMaxPaths = 12, kMaxBackgrounds = 8;

// ---- thresholds of the rules that do not depend on the style (documented in docs/ASSETS.md) ---------------------

constexpr double kContrastOk = 3.0, kContrastWarn = 1.5;        // WCAG contrast ratio of the silhouette edge against a background
constexpr double kSizeWarnPx = 16, kSizeFailPx = 8;             // longer side on screen
constexpr double kSilhouetteOk = 0.85, kSilhouetteWarn = 0.6;   // share of the silhouette that survives the downscale
constexpr double kEdgeOk = 0.7, kEdgeWarn = 0.4;                // outline thickness on screen, in screen pixels
constexpr double kFringeOk = 0.1, kFringeWarn = 0.3;            // share of partly transparent pixels that are off-colour
constexpr double kFringeStep = 0.2;                             // luminance beyond the opaque neighbours that makes a fringe
constexpr double kBleedOk = 0.2;                                // share of transparent edge pixels with a foreign colour
constexpr double kDensityOk = 1.15, kDensityWarn = 1.5;         // ratio of the pixel densities in a set
constexpr double kOutlineSetColourOk = 48, kOutlineSetColourWarn = 96;
constexpr double kSharedColourDistance = 24;                    // colours this close count as the same colour in a set
constexpr double kUnsharedOk = 0.6, kUnsharedWarn = 0.9;        // share of pixels with a colour no other picture has

struct Rgb {
    std::uint8_t r = 0, g = 0, b = 0;
};

struct Background {
    std::string label;
    Rgb colour;
};

std::string hex(Rgb c) { return std::format("#{:02x}{:02x}{:02x}", c.r, c.g, c.b); }
std::string num(double v) { return std::format("{:.3g}", v); }
double round4(double v) { return std::round(v * 10000.0) / 10000.0; }

double lin(double c) {
    c /= 255.0;
    return c <= 0.04045 ? c / 12.92 : std::pow((c + 0.055) / 1.055, 2.4);
}
double relative_luminance(double r, double g, double b) { return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b); }
double contrast_ratio(double a, double b) {
    const double hi = std::max(a, b), lo = std::min(a, b);
    return (hi + 0.05) / (lo + 0.05);
}
double rgb_distance(Rgb a, Rgb b) {
    const double dr = double(a.r) - b.r, dg = double(a.g) - b.g, db = double(a.b) - b.b;
    return std::sqrt(dr * dr + dg * dg + db * db);
}
double luma(double r, double g, double b) { return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0; }

const std::uint8_t* px(const Image& im, int x, int y) { return &im.rgba[(std::size_t(y) * im.width + x) * 4]; }

ArtRule make_rule(const char* id, double value, double threshold, std::optional<double> failThreshold, Verdict verdict, std::string message,
                  std::string hint, Json detail = Json()) {
    ArtRule r;
    r.rule = id;
    r.value = value;
    r.threshold = threshold;
    r.failThreshold = failThreshold;
    r.verdict = verdict;
    r.message = std::move(message);
    r.hint = std::move(hint);
    r.detail = std::move(detail);
    return r;
}

Verdict at_least(double v, double ok, double warn) { return v >= ok ? Verdict::Ok : v >= warn ? Verdict::Warn : Verdict::Fail; }
Verdict at_most(double v, double ok, double warn) { return v <= ok ? Verdict::Ok : v <= warn ? Verdict::Warn : Verdict::Fail; }

Json rules_json(const std::vector<ArtRule>& rules) {
    Json a = Json::array();
    for (const ArtRule& r : rules) a.push_back(r.to_json());
    return a;
}

// ---- backgrounds -----------------------------------------------------------------------------------------------

// The colours that stand for an image used as a background: the dark, middle and light parts (by luminance).
std::vector<Background> image_backgrounds(const std::string& label, const Image& im) {
    std::vector<std::pair<double, Rgb>> samples;
    const std::size_t total = std::size_t(im.width) * im.height;
    const std::size_t step = std::max<std::size_t>(1, total / 65536);
    for (std::size_t i = 0; i < total; i += step) {
        const std::uint8_t* p = &im.rgba[i * 4];
        if (p[3] < 128) continue;
        samples.push_back({luma(p[0], p[1], p[2]), Rgb{p[0], p[1], p[2]}});
    }
    std::vector<Background> out;
    if (samples.empty()) return out;
    std::stable_sort(samples.begin(), samples.end(), [](const auto& a, const auto& b) { return a.first < b.first; });
    const char* names[3] = {"dark part", "middle", "light part"};
    const double at[3] = {0.1, 0.5, 0.9};
    for (int k = 0; k < 3; ++k) {
        const std::size_t centre = std::size_t(at[k] * double(samples.size() - 1));
        const std::size_t band = std::max<std::size_t>(1, samples.size() / 40);
        const std::size_t lo = centre > band ? centre - band : 0, hi = std::min(samples.size() - 1, centre + band);
        double r = 0, g = 0, b = 0;
        for (std::size_t i = lo; i <= hi; ++i) {
            r += samples[i].second.r;
            g += samples[i].second.g;
            b += samples[i].second.b;
        }
        const double n = double(hi - lo + 1);
        out.push_back({label + " (" + names[k] + ")", Rgb{std::uint8_t(r / n + 0.5), std::uint8_t(g / n + 0.5), std::uint8_t(b / n + 0.5)}});
    }
    return out;
}

Rgb rgb_of(const Color& c) {
    auto b = [](float v) { return std::uint8_t(std::clamp(std::lround(v * 255.0f), 0L, 255L)); };
    return Rgb{b(c.r), b(c.g), b(c.b)};
}

void add_background(std::vector<Background>& list, Background bg) {
    for (const Background& other : list)
        if (rgb_distance(other.colour, bg.colour) < 8) return;  // the same colour twice says nothing new
    if (list.size() < kMaxBackgrounds) list.push_back(std::move(bg));
}

// ---- the measurements of one picture ---------------------------------------------------------------------------

struct EdgeStats {
    std::vector<std::pair<Rgb, std::uint8_t>> pixels;  // silhouette ring: colour and alpha
};

EdgeStats silhouette_edge(const Image& im) {
    EdgeStats e;
    for (int y = 0; y < im.height; ++y)
        for (int x = 0; x < im.width; ++x) {
            const std::uint8_t* p = px(im, x, y);
            if (p[3] < 128) continue;
            const bool open = (x > 0 && px(im, x - 1, y)[3] < 128) || (x + 1 < im.width && px(im, x + 1, y)[3] < 128) ||
                              (y > 0 && px(im, x, y - 1)[3] < 128) || (y + 1 < im.height && px(im, x, y + 1)[3] < 128);
            if (open) e.pixels.push_back({Rgb{p[0], p[1], p[2]}, p[3]});
        }
    return e;
}

double median(std::vector<double> v) {
    if (v.empty()) return 0;
    std::sort(v.begin(), v.end());
    return v[v.size() / 2];
}

// Halos and fringes on the alpha edge: partly transparent pixels much darker (a dark fringe) or lighter (a halo) than the
// opaque pixels they touch, and the colour of the fully transparent pixels next to the shape (which a smooth filter blends in).
struct Fringe {
    std::uint64_t partial = 0, off = 0, dark = 0, light = 0;
    std::uint64_t transparentEdge = 0, bleeding = 0;
};
Fringe measure_fringe(const Image& im) {
    Fringe f;
    for (int y = 0; y < im.height; ++y)
        for (int x = 0; x < im.width; ++x) {
            const std::uint8_t* p = px(im, x, y);
            if (p[3] >= 8 && p[3] <= 247) {
                double lo = 2, hi = -1;
                int n = 0;
                for (int dy = -1; dy <= 1; ++dy)
                    for (int dx = -1; dx <= 1; ++dx) {
                        const int nx = x + dx, ny = y + dy;
                        if ((dx == 0 && dy == 0) || nx < 0 || ny < 0 || nx >= im.width || ny >= im.height) continue;
                        const std::uint8_t* q = px(im, nx, ny);
                        if (q[3] < 200) continue;
                        const double l = luma(q[0], q[1], q[2]);
                        lo = std::min(lo, l);
                        hi = std::max(hi, l);
                        ++n;
                    }
                if (n == 0) continue;
                ++f.partial;
                const double l = luma(p[0], p[1], p[2]);
                if (l < lo - kFringeStep) {
                    ++f.off;
                    ++f.dark;
                } else if (l > hi + kFringeStep) {
                    ++f.off;
                    ++f.light;
                }
            } else if (p[3] == 0) {
                // a transparent pixel touching a visible one
                const std::uint8_t* near = nullptr;
                const int dxs[4] = {-1, 1, 0, 0}, dys[4] = {0, 0, -1, 1};
                for (int k = 0; k < 4 && !near; ++k) {
                    const int nx = x + dxs[k], ny = y + dys[k];
                    if (nx < 0 || ny < 0 || nx >= im.width || ny >= im.height) continue;
                    if (px(im, nx, ny)[3] >= 128) near = px(im, nx, ny);
                }
                if (!near) continue;
                ++f.transparentEdge;
                if (rgb_distance(Rgb{p[0], p[1], p[2]}, Rgb{near[0], near[1], near[2]}) > 96) ++f.bleeding;
            }
        }
    return f;
}

// ---- the picture -----------------------------------------------------------------------------------------------

Image blank(int w, int h, Rgb c) {
    Image im;
    im.width = w;
    im.height = h;
    im.rgba.resize(std::size_t(w) * h * 4);
    for (std::size_t i = 0; i < std::size_t(w) * h; ++i) {
        im.rgba[i * 4] = c.r;
        im.rgba[i * 4 + 1] = c.g;
        im.rgba[i * 4 + 2] = c.b;
        im.rgba[i * 4 + 3] = 255;
    }
    return im;
}

void over(Image& dst, const Image& src, int ox, int oy) {
    for (int y = 0; y < src.height; ++y)
        for (int x = 0; x < src.width; ++x) {
            const int dx = ox + x, dy = oy + y;
            if (dx < 0 || dy < 0 || dx >= dst.width || dy >= dst.height) continue;
            const std::uint8_t* s = px(src, x, y);
            std::uint8_t* d = &dst.rgba[(std::size_t(dy) * dst.width + dx) * 4];
            const double a = s[3] / 255.0;
            for (int c = 0; c < 3; ++c) d[c] = std::uint8_t(d[c] + (s[c] - d[c]) * a + 0.5);
            d[3] = 255;
        }
}

// `src` centred in a tile x tile square over `base` (a colour, or a checkerboard when `checker`): shrunk to fit with the area
// filter, or magnified by a whole number with the nearest filter.
Image tile_of(const Image& src, int tile, Rgb base, bool checker) {
    Image t = blank(tile, tile, base);
    if (checker)
        for (int y = 0; y < tile; ++y)
            for (int x = 0; x < tile; ++x) {
                const bool light = ((x / 8) + (y / 8)) % 2 == 0;
                std::uint8_t* p = &t.rgba[(std::size_t(y) * tile + x) * 4];
                p[0] = p[1] = std::uint8_t(light ? 74 : 58);
                p[2] = std::uint8_t(light ? 80 : 64);
            }
    if (src.width <= 0 || src.height <= 0) return t;
    Image fitted;
    if (src.width > tile || src.height > tile) {
        const double k = std::min(double(tile) / src.width, double(tile) / src.height);
        fitted = resize_image(src, std::max(1, int(src.width * k)), std::max(1, int(src.height * k)));
    } else {
        const int k = std::max(1, std::min(tile / src.width, tile / src.height));
        fitted = resize_nearest(src, src.width * k, src.height * k);
    }
    over(t, fitted, (tile - fitted.width) / 2, (tile - fitted.height) / 2);
    return t;
}

stdfs::path next_art_file(const std::string& projectDir) {
    static std::atomic<int> counter{0};
    const stdfs::path dir = project_file(projectDir, kScreenshotDir);
    std::error_code ec;
    for (;;) {
        const int n = ++counter;
        const stdfs::path file = dir / std::format("frame_{}_art.png", n);
        if (!stdfs::exists(file, ec)) return file;
    }
}

// ---- one asset -------------------------------------------------------------------------------------------------

struct SizeSpec {
    std::string label;  // "phone", "desktop", "onScreenPx"
    double px = 0;      // longer side of the picture on screen
    double sourcePx = 0;  // the texture pixels that side is made of (the frame or region drawn, else the picture)
    std::string scene;  // where it comes from (empty for an explicit size)
};

struct Asset {
    std::string path;
    Image image;
    ArtMeasure measure;
    bool fromCache = false;
    std::vector<const TextureUse*> uses;
    std::vector<ArtRule> rules;
    std::vector<std::string> notes;
    std::vector<Background> backgrounds;
    std::string backgroundSource;
    std::vector<SizeSpec> sizes;
    std::string sizeSource;
    std::vector<std::string> tileKinds;
    int firstTile = 0;
    Verdict verdict = Verdict::Ok;
    std::string role, roleSource;       // the asset's role (ui, icon, effect) and where it was set
    std::vector<StyleSkip> skipped;     // style rules left out by style.ignore or the role
};

void contrast_rules(Asset& a, const EdgeStats& edge) {
    if (edge.pixels.size() < 12) {
        a.notes.push_back("Contrast: the picture has no silhouette (it fills its frame or is nearly empty), so there is no edge to separate from a background.");
        return;
    }
    for (const Background& bg : a.backgrounds) {
        const double bgL = relative_luminance(bg.colour.r, bg.colour.g, bg.colour.b);
        std::vector<double> ratios;
        ratios.reserve(edge.pixels.size());
        for (const auto& [c, alpha] : edge.pixels) {
            const double k = alpha / 255.0;
            ratios.push_back(contrast_ratio(relative_luminance(c.r * k + bg.colour.r * (1 - k), c.g * k + bg.colour.g * (1 - k), c.b * k + bg.colour.b * (1 - k)), bgL));
        }
        const double v = median(ratios);
        const Verdict verdict = at_least(v, kContrastOk, kContrastWarn);
        const bool bgDark = bgL < 0.18;
        a.rules.push_back(make_rule(
            "contrast", round4(v), kContrastOk, kContrastWarn, verdict,
            std::format("Over {} {} the edge of the silhouette has a contrast ratio of {}:1 (median of {} edge pixels; at least {}:1 stands out, below {}:1 it blends in).",
                        bg.label, hex(bg.colour), num(v), edge.pixels.size(), num(kContrastOk), num(kContrastWarn)),
            std::format("Give the sprite an outline that contrasts with {} (style.outline in assets.json), or {} the sprite's edge colours; or change what is behind it "
                        "(Camera.clearColor with scene.set_component, or the background sprite).",
                        bg.label, bgDark ? "lighten" : "darken"),
            Json::object({{"background", bg.label}, {"backgroundColor", hex(bg.colour)}})));
    }
}

void readability_rules(Asset& a, bool nearest) {
    for (const SizeSpec& s : a.sizes) {
        const double longSide = s.sourcePx;
        const int srcW = a.image.width, srcH = a.image.height;
        const std::string where = s.scene.empty() ? std::string() : " in " + s.scene;
        const std::string what = std::format("At {} ({} px{})", s.label, num(s.px), where);
        a.rules.push_back(make_rule("readability.size", round4(s.px), kSizeWarnPx, kSizeFailPx,
                                    s.px >= kSizeWarnPx ? Verdict::Ok : s.px >= kSizeFailPx ? Verdict::Warn : Verdict::Fail,
                                    std::format("{} the sprite is {} px on its longer side; below {} px a shape stops being recognisable.", what, num(s.px), num(kSizeWarnPx)),
                                    "Draw it larger (Sprite.size or the Transform scale with scene.set_component) or, if it is meant to be small, make it a simple, high-contrast shape.",
                                    Json::object({{"size", s.label}, {"scene", s.scene}})));
        const double f = longSide / s.px;  // texture pixels per screen pixel
        if (f <= 1.05) continue;           // drawn at its size or larger: nothing is lost
        const int dw = std::max(1, int(std::lround(srcW / f))), dh = std::max(1, int(std::lround(srcH / f)));  // the whole picture, shrunk
        // Silhouette: how much of it is still there after shrinking.
        std::uint64_t before = 0, after = 0;
        for (std::size_t i = 0; i < std::size_t(a.image.width) * a.image.height; ++i) before += a.image.rgba[i * 4 + 3] >= 128;
        const Image small = nearest ? resize_nearest(a.image, std::max(1, int(std::lround(a.image.width / f))), std::max(1, int(std::lround(a.image.height / f))))
                                    : resize_image(a.image, std::max(1, int(std::lround(a.image.width / f))), std::max(1, int(std::lround(a.image.height / f))));
        for (std::size_t i = 0; i < std::size_t(small.width) * small.height; ++i) after += small.rgba[i * 4 + 3] >= 128;
        if (before > 0) {
            const double kept = std::min(1.0, double(after) * f * f / double(before));
            a.rules.push_back(make_rule("readability.silhouette", round4(kept), kSilhouetteOk, kSilhouetteWarn, at_least(kept, kSilhouetteOk, kSilhouetteWarn),
                                        std::format("{} (shrunk x{} to {}x{}) {} of the silhouette is still there ({}).", what, num(f), dw, dh, num(kept * 100) + "%",
                                                    kept >= kSilhouetteOk ? "most" : "thin parts have vanished"),
                                        std::format("Thin parts are lost when {} texture pixels become one screen pixel: thicken limbs and details to at least {} px in the texture, "
                                                    "or draw the texture nearer its on-screen size (a smaller image, or a larger Sprite).",
                                                    num(f), num(std::ceil(f))),
                                        Json::object({{"size", s.label}, {"shrink", round4(f)}, {"width", dw}, {"height", dh}})));
        }
        // Edge: a line thinner than a screen pixel is blended into its neighbours.
        if (const double line = outline_line_width(a.measure); line > 0) {
            const double clarity = std::min(1.0, line / f);
            a.rules.push_back(make_rule("readability.edge", round4(clarity), kEdgeOk, kEdgeWarn, at_least(clarity, kEdgeOk, kEdgeWarn),
                                        std::format("{} the outline ({} px thick in the texture) is {} screen px thick; under {} it is blended into the fill.", what,
                                                    num(line), num(line / f), num(kEdgeOk)),
                                        std::format("Make the outline about {} px thick in the texture (style.outline.width) so that it stays a line at this size, or draw the sprite at a size near the texture's.",
                                                    num(std::ceil(f))),
                                        Json::object({{"size", s.label}, {"outlinePx", line}})));
        }
    }
}

void fringe_rules(Asset& a, bool nearest) {
    const Fringe f = measure_fringe(a.image);
    if (f.partial >= 12) {
        const double share = double(f.off) / double(f.partial);
        const bool darkOnes = f.dark >= f.light;
        a.rules.push_back(make_rule(
            "fringe.partial", round4(share), kFringeOk, kFringeWarn, at_most(share, kFringeOk, kFringeWarn),
            std::format("{} of the {} partly transparent edge pixels are {} than every opaque pixel they touch ({} {}, {} {}): a {} around the shape.", num(share * 100) + "%", f.partial,
                        darkOnes ? "darker" : "lighter", f.dark, "dark", f.light, "light", darkOnes ? "dark fringe" : "halo"),
            "Repaint the edge pixels in the colour of the shape, or export the picture again without a matte colour (straight alpha, edge colour bled outward); "
            "assets.rasterize_svg and assets.draw_icon draw clean edges.",
            Json::object({{"partialPixels", f.partial}, {"darkFringe", f.dark}, {"halo", f.light}})));
    }
    if (!nearest && f.transparentEdge >= 12) {
        const double share = double(f.bleeding) / double(f.transparentEdge);
        a.rules.push_back(make_rule(
            "fringe.bleed", round4(share), kBleedOk, std::nullopt, share <= kBleedOk ? Verdict::Ok : Verdict::Warn,
            std::format("{} of the {} transparent pixels next to the shape hold a colour far from the shape's own (often black): a smooth (bilinear) filter blends it into the edge as a dark line.",
                        num(share * 100) + "%", f.transparentEdge),
            "Fill the colour of the transparent pixels next to the shape with the shape's edge colour when you export, or draw the sprite with the nearest filter (Sprite.pixelArt true)."));
    }
}

// ---- rules of a set of pictures --------------------------------------------------------------------------------

void set_rules(const std::vector<Asset>& assets, std::vector<ArtRule>& out) {
    // pixel density
    std::vector<std::pair<double, const Asset*>> dens;
    for (const Asset& a : assets) {
        const double d = median_texels_per_unit(a.uses);
        if (d > 0) dens.push_back({d, &a});
    }
    if (dens.size() >= 2) {
        auto [lo, hi] = std::minmax_element(dens.begin(), dens.end(), [](const auto& x, const auto& y) { return x.first < y.first; });
        const double ratio = hi->first / lo->first;
        out.push_back(make_rule("set.density", round4(ratio), kDensityOk, kDensityWarn, at_most(ratio, kDensityOk, kDensityWarn),
                                std::format("The scenes draw {} at {} texture pixels per world unit and {} at {}: a ratio of {}. Pictures of one set drawn at different densities look like different sets.",
                                            lo->second->path, num(lo->first), hi->second->path, num(hi->first), num(ratio)),
                                std::format("Draw them at one density: change Sprite.size of {} (scene.set_component) so it has {} texture pixels per unit, or redraw one of the textures at the other size.",
                                            hi->second->path, num(lo->first)),
                                Json::object({{"lowest", lo->second->path}, {"highest", hi->second->path}})));
    }
    std::set<int> blocks;
    for (const Asset& a : assets)
        if (a.measure.blockSize > 0) blocks.insert(a.measure.blockSize);
    if (blocks.size() >= 2) {
        std::string list;
        for (const Asset& a : assets)
            if (a.measure.blockSize > 0) list += (list.empty() ? "" : ", ") + a.path + " (" + std::to_string(a.measure.blockSize) + " px)";
        out.push_back(make_rule("set.pixelSize", double(blocks.size()), 1, std::nullopt, Verdict::Warn,
                                "Pixel art is drawn with different pixel sizes: " + list + ".",
                                "Redraw them with one pixel size, or resize the odd ones by a whole number (assets.generate_image keeps the size it is asked for)."));
    }
    // outline
    std::vector<const Asset*> outlined;
    for (const Asset& a : assets)
        if (a.measure.ringPixels >= 12 && !a.measure.ringColours.empty() && outline_line_width(a.measure) > 0) outlined.push_back(&a);
    if (outlined.size() >= 2) {
        double worst = 0;
        const Asset *wa = outlined[0], *wb = outlined[0];
        double minW = 1e9, maxW = 0;
        const Asset *narrow = outlined[0], *wide = outlined[0];
        for (std::size_t i = 0; i < outlined.size(); ++i) {
            const ArtColour& ci = outlined[i]->measure.ringColours.front();
            for (std::size_t j = i + 1; j < outlined.size(); ++j) {
                const ArtColour& cj = outlined[j]->measure.ringColours.front();
                const double d = rgb_distance(Rgb{ci.r, ci.g, ci.b}, Rgb{cj.r, cj.g, cj.b});
                if (d > worst) { worst = d; wa = outlined[i]; wb = outlined[j]; }
            }
            const double w = outline_line_width(outlined[i]->measure);
            if (w > 0 && w < minW) { minW = w; narrow = outlined[i]; }
            if (w > maxW) { maxW = w; wide = outlined[i]; }
        }
        out.push_back(make_rule("set.outlineColour", round4(worst), kOutlineSetColourOk, std::nullopt, std::min(at_most(worst, kOutlineSetColourOk, kOutlineSetColourWarn), Verdict::Warn),
                                std::format("The commonest edge colour is {} in {} and {} in {} (RGB distance {}).",
                                            hex(Rgb{wa->measure.ringColours.front().r, wa->measure.ringColours.front().g, wa->measure.ringColours.front().b}), wa->path,
                                            hex(Rgb{wb->measure.ringColours.front().r, wb->measure.ringColours.front().g, wb->measure.ringColours.front().b}), wb->path, num(worst)),
                                "Use one outline colour for the set: write it in assets.json style.outline and redraw the odd ones (assets.generate_image {\"overwrite\": true}).",
                                Json::object({{"a", wa->path}, {"b", wb->path}})));
        if (maxW > 0 && minW < 1e9) {
            const double diff = maxW - minW;
            out.push_back(make_rule("set.outlineWidth", round4(diff), 1.0, std::nullopt, diff < 1.0 ? Verdict::Ok : Verdict::Warn,
                                    std::format("The outline is {} px thick in {} and {} px in {}.", num(minW), narrow->path, num(maxW), wide->path),
                                    "Use one outline thickness for the set (style.outline.width) and redraw the odd ones.", Json::object({{"thinnest", narrow->path}, {"thickest", wide->path}})));
        }
    }
    // palette spread
    if (assets.size() >= 2) {
        std::uint64_t total = 0, alone = 0;
        for (std::size_t i = 0; i < assets.size(); ++i)
            for (const ArtColour& c : assets[i].measure.colours) {
                total += c.count;
                bool shared = false;
                for (std::size_t j = 0; j < assets.size() && !shared; ++j) {
                    if (j == i) continue;
                    for (const ArtColour& d : assets[j].measure.colours)
                        if (rgb_distance(Rgb{c.r, c.g, c.b}, Rgb{d.r, d.g, d.b}) <= kSharedColourDistance) { shared = true; break; }
                }
                if (!shared) alone += c.count;
            }
        if (total > 0) {
            const double v = double(alone) / double(total);
            out.push_back(make_rule("set.paletteSpread", round4(v), kUnsharedOk, kUnsharedWarn, at_most(v, kUnsharedOk, kUnsharedWarn),
                                    std::format("{} of the pixels have a colour (within {}) that no other picture of the set uses: the pictures do not share a palette.", num(v * 100) + "%",
                                                num(kSharedColourDistance)),
                                    "Lock the set to one palette: write it in assets.json style.palette, then regenerate or recolour the odd pictures (assets.generate_image applies the palette)."));
        }
    }
}

// ---- argument parsing ------------------------------------------------------------------------------------------

std::vector<double> parse_sizes(const Json& v) {
    std::vector<double> out;
    auto one = [&](const Json& n, const std::string& pointer) {
        if (!n.is_number() || n.get<double>() < 1 || n.get<double>() > 8192)
            arg_error(kCommand, pointer, "expected a size in screen pixels between 1 and 8192, got " + describe_json_value(n),
                      "Pass the longer side of the sprite on screen, e.g. {\"onScreenPx\": 48} or [32, 64].");
        out.push_back(n.get<double>());
    };
    if (v.is_array()) {
        if (v.empty() || v.size() > 4) arg_error(kCommand, "/onScreenPx", "expected 1 to 4 sizes", "Pass a number or a list such as [32, 64].");
        for (std::size_t i = 0; i < v.size(); ++i) one(v[i], "/onScreenPx/" + std::to_string(i));
    } else {
        one(v, "/onScreenPx");
    }
    return out;
}

Json check(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "assets.check_art expects an object.", "Pass {\"path\": \"assets/hero.png\"}.");
    check_arg_keys(kCommand, a, "", {"path", "paths", "backgrounds", "onScreenPx", "style"});
    if (a.contains("path") == a.contains("paths"))
        fail("invalid_argument", "Pass exactly one of `path` (one picture) and `paths` (several, checked as a set).",
             "Use {\"path\": \"assets/hero.png\"} or {\"paths\": [\"assets/hero.png\", \"assets/enemy.png\"]}.");
    std::vector<std::string> paths;
    if (a.contains("path")) {
        paths.push_back(tooling_detail::arg_string(a, "path", true));
    } else {
        if (!a["paths"].is_array() || a["paths"].empty() || a["paths"].size() > kMaxPaths)
            arg_error(kCommand, "/paths", "expected a list of 1 to " + std::to_string(kMaxPaths) + " picture paths",
                      "Pass {\"paths\": [\"assets/a.png\", \"assets/b.png\"]}; check a bigger set in groups.");
        for (std::size_t i = 0; i < a["paths"].size(); ++i) {
            if (!a["paths"][i].is_string()) arg_error(kCommand, "/paths/" + std::to_string(i), "expected a path string", "Use project-relative paths such as \"assets/hero.png\".");
            const std::string p = a["paths"][i].get<std::string>();
            if (std::find(paths.begin(), paths.end(), p) == paths.end()) paths.push_back(p);
        }
    }
    const bool applyStyle = tooling_detail::arg_bool(a, "style", true);

    ProjectRootGuard root(projectDir);
    // explicit backgrounds
    std::vector<Background> explicitBackgrounds;
    if (a.contains("backgrounds")) {
        const Json& list = a["backgrounds"];
        if (!list.is_array() || list.empty() || list.size() > kMaxBackgrounds)
            arg_error(kCommand, "/backgrounds", "expected 1 to " + std::to_string(kMaxBackgrounds) + " colours or image paths",
                      "Pass {\"backgrounds\": [\"#203040\", \"assets/sky.png\"]}.");
        for (std::size_t i = 0; i < list.size(); ++i) {
            const std::string pointer = "/backgrounds/" + std::to_string(i);
            if (!list[i].is_string() && !list[i].is_array())
                arg_error(kCommand, pointer, "expected a colour (\"#rrggbb\", a name, [r, g, b]) or a project image path, got " + describe_json_value(list[i]), "Example: \"#203040\" or \"assets/sky.png\".");
            const bool looksLikePath = list[i].is_string() && list[i].get<std::string>().find_first_of("./\\") != std::string::npos && list[i].get<std::string>()[0] != '#';
            if (looksLikePath) {
                const std::string rel = list[i].get<std::string>();
                std::error_code ec;
                if (!stdfs::is_regular_file(project_file(projectDir, rel), ec))
                    arg_error(kCommand, pointer, "'" + rel + "' is not an image of the project", "Use assets.list to see the images, or pass a colour such as \"#203040\".");
                auto im = load_image(project_file(projectDir, rel));
                if (!im.ok()) arg_error(kCommand, pointer, "'" + rel + "': " + im.error().message, im.error().hint);
                for (Background& b : image_backgrounds(rel, *im)) add_background(explicitBackgrounds, std::move(b));
            } else {
                const Rgb c = rgb_of(colour_arg(kCommand, list[i], pointer));
                add_background(explicitBackgrounds, {hex(c), c});
            }
        }
    }
    std::vector<double> explicitSizes;
    if (a.contains("onScreenPx")) explicitSizes = parse_sizes(a["onScreenPx"]);

    StyleParse styleParse;
    if (applyStyle) styleParse = load_style_guide(projectDir);
    const StyleGuide& style = styleParse.guide;
    const Json manifest = assets::manifest();
    const ProjectArtUse project = scan_art_use(projectDir);
    const ReferenceScreens screens = reference_screens(project);

    std::vector<Asset> assets;
    for (const std::string& rel : paths) {
        const stdfs::path file = project_file(projectDir, rel);
        std::error_code ec;
        if (!stdfs::is_regular_file(file, ec)) fail("not_found", "'" + rel + "' does not exist.", "Use assets.list to see the images of the project.");
        Asset asset;
        asset.path = fs::normalize(rel);
        auto loaded = load_image(file);
        if (!loaded.ok()) fail("invalid_argument", "'" + rel + "': " + loaded.error().message, loaded.error().hint);
        asset.image = std::move(*loaded);
        auto measure = measure_art_file(projectDir, asset.path, &asset.fromCache);
        if (!measure.ok()) fail("invalid_argument", "'" + rel + "': " + measure.error().message, measure.error().hint);
        asset.measure = std::move(*measure);
        asset.uses = project.of(asset.path);
        assets.push_back(std::move(asset));
    }

    for (Asset& asset : assets) {
        const bool pixelArt = (applyStyle && style.pixelArt.value_or(false)) || (!asset.uses.empty() && std::all_of(asset.uses.begin(), asset.uses.end(), [](const TextureUse* u) { return u->nearest; }));

        // backgrounds: explicit, else what the scenes draw behind it, else a light and a dark default
        if (!explicitBackgrounds.empty()) {
            asset.backgrounds = explicitBackgrounds;
            asset.backgroundSource = "explicit";
        } else {
            std::set<std::string> seenScenes;
            for (const TextureUse* u : asset.uses) {
                if (!seenScenes.insert(u->scene).second) continue;
                const SceneView* view = project.view_of(u->scene);
                if (!view) continue;
                if (view->clears) add_background(asset.backgrounds, {"clear colour of " + u->scene, rgb_of(view->clear)});
                for (const SceneView::Backdrop& b : view->backdrops) {
                    if (b.texture == asset.path || b.layer > u->layer) continue;
                    auto im = load_image(project_file(projectDir, b.texture));
                    if (!im.ok()) continue;
                    for (Background& bg : image_backgrounds(b.texture + " in " + u->scene, *im)) add_background(asset.backgrounds, std::move(bg));
                }
            }
            if (!asset.backgrounds.empty()) {
                asset.backgroundSource = "scenes";
            } else {
                asset.backgrounds = {{"default light", Rgb{240, 240, 240}}, {"default dark", Rgb{32, 32, 32}}};
                asset.backgroundSource = "default";
                asset.notes.push_back(asset.uses.empty() ? "No scene draws this picture, so the backgrounds are a light and a dark default; pass `backgrounds` to judge it over the real ones."
                                                         : "The scenes that draw it have no clear colour or background sprite to read, so the backgrounds are a light and a dark default; pass `backgrounds`.");
            }
        }

        // on-screen sizes: explicit, else from the scenes at the phone and desktop reference screens
        if (!explicitSizes.empty()) {
            const double whole = std::max(asset.measure.cellWidth > 0 ? asset.measure.cellWidth : asset.image.width,
                                          asset.measure.cellHeight > 0 ? asset.measure.cellHeight : asset.image.height);
            for (double s : explicitSizes) asset.sizes.push_back({"onScreenPx", s, whole, ""});
            asset.sizeSource = "explicit";
        } else if (!asset.uses.empty()) {
            const struct { const char* name; double w, h; } refs[2] = {{"phone", screens.phoneWidth, screens.phoneHeight}, {"desktop", screens.desktopWidth, screens.desktopHeight}};
            for (const auto& ref : refs) {
                double best = 0, source = 0;
                std::string scene;
                for (const TextureUse* u : asset.uses) {
                    const double s = on_screen_px(*u, project.view_of(u->scene), project, ref.w, ref.h);
                    if (s > 0 && (best == 0 || s < best)) { best = s; scene = u->scene; source = std::max(u->framePx[0], u->framePx[1]); }
                }
                if (best > 0) asset.sizes.push_back({std::format("{} ({}x{})", ref.name, int(ref.w), int(ref.h)), best, source, scene});
            }
            asset.sizeSource = "scenes";
        } else {
            asset.sizeSource = "none";
            asset.notes.push_back("No scene draws this picture, so its on-screen size is unknown and readability is not judged; pass `onScreenPx` (the longer side of the sprite on screen).");
        }

        // rules
        const EdgeStats edge = silhouette_edge(asset.image);
        contrast_rules(asset, edge);
        readability_rules(asset, pixelArt);
        fringe_rules(asset, pixelArt);
        if (applyStyle) {
            std::vector<ArtRule> styleRules = evaluate_style_rules(asset.measure, style, asset.uses);
            asset.role = style_role_of(manifest, style, asset.path, &asset.roleSource);
            apply_style_scope(style, asset.path, asset.role, asset.roleSource, styleRules, asset.skipped);
            for (ArtRule& r : styleRules) asset.rules.push_back(std::move(r));
        }
        for (const ArtRule& r : asset.rules) asset.verdict = worse(asset.verdict, r.verdict);
    }
    std::vector<ArtRule> setRules;
    if (assets.size() >= 2) set_rules(assets, setRules);

    // ---- the picture: per asset a row of tiles ----
    std::size_t maxTiles = 0;
    for (const Asset& asset : assets) maxTiles = std::max(maxTiles, std::size_t(2 + asset.backgrounds.size() + asset.sizes.size()));
    const int tile = int(std::clamp<std::size_t>(1900 / std::max<std::size_t>(1, maxTiles) - 12, 64, 160));
    std::vector<Image> tiles;
    std::vector<std::string> labels;
    for (Asset& asset : assets) {
        asset.firstTile = int(tiles.size()) + 1;
        auto push = [&](Image t, const std::string& kind) {
            tiles.push_back(std::move(t));
            labels.push_back(std::to_string(tiles.size()));
            asset.tileKinds.push_back(kind);
        };
        push(tile_of(asset.image, tile, Rgb{0, 0, 0}, true), "the picture on a checkerboard");
        Image grey = asset.image;
        simulate_color_vision(grey, ColorSimulation::Greyscale);
        push(tile_of(grey, tile, Rgb{128, 128, 128}, false), "value: the picture in greyscale on mid grey (is the shape readable without colour?)");
        for (const Background& bg : asset.backgrounds) push(tile_of(asset.image, tile, bg.colour, false), "over " + bg.label + " " + hex(bg.colour));
        for (const SizeSpec& s : asset.sizes) {
            const double f = s.sourcePx / s.px;
            Image small = asset.image;
            if (f > 1.05) {
                const int w = std::max(1, int(std::lround(asset.image.width / f))), h = std::max(1, int(std::lround(asset.image.height / f)));
                small = resize_image(asset.image, w, h);
            }
            const Background& bg = asset.backgrounds.front();
            push(tile_of(small, tile, bg.colour, false), std::format("at {} px on screen ({}), magnified with whole-number steps, over {}", num(s.px), s.label, bg.label));
        }
    }
    const int columns = int(maxTiles);
    // pad each row to the same number of tiles so a row is one asset
    {
        std::vector<Image> padded;
        std::vector<std::string> paddedLabels;
        std::size_t at = 0;
        for (const Asset& asset : assets) {
            for (std::size_t i = 0; i < asset.tileKinds.size(); ++i, ++at) {
                padded.push_back(std::move(tiles[at]));
                paddedLabels.push_back(labels[at]);
            }
            for (std::size_t i = asset.tileKinds.size(); i < maxTiles; ++i) {
                padded.push_back(blank(tile, tile, Rgb{22, 22, 26}));
                paddedLabels.push_back("");
            }
        }
        tiles = std::move(padded);
        labels = std::move(paddedLabels);
    }
    SheetLayout layout;
    const Image picture = contact_sheet(tiles, labels, columns, -1, &layout);
    const stdfs::path out = next_art_file(projectDir);
    const std::vector<std::uint8_t> png = encode_png(picture);
    std::string err;
    if (!tooling_detail::write_file(out, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err)) fail("failed", err);

    // ---- the result ----
    int counts[3] = {0, 0, 0};
    Verdict overall = Verdict::Ok;
    Json assetsJson = Json::array();
    for (const Asset& asset : assets) {
        for (const ArtRule& r : asset.rules) ++counts[int(r.verdict)];
        overall = worse(overall, asset.verdict);
        Json j = Json::object({{"path", asset.path}, {"width", asset.image.width}, {"height", asset.image.height}, {"verdict", verdict_name(asset.verdict)}});
        Json top = Json::array();
        std::uint64_t pixels = 0;
        for (const ArtColour& c : asset.measure.colours) pixels += c.count;
        for (std::size_t i = 0; i < asset.measure.colours.size() && i < 6; ++i) {
            const ArtColour& c = asset.measure.colours[i];
            top.push_back(Json::object({{"color", hex(Rgb{c.r, c.g, c.b})}, {"share", round4(pixels ? double(c.count) / double(pixels) : 0.0)}}));
        }
        j["palette"] = Json::object({{"distinctColours", asset.measure.distinct}, {"exactColours", asset.measure.exact}, {"mostUsed", top},
                                     {"styleColours", style.palette ? Json(style.palette->size()) : Json(nullptr)}});
        j["measure"] = Json::object({{"visiblePixels", asset.measure.visible}, {"valueLow", round4(asset.measure.valueLow)}, {"valueHigh", round4(asset.measure.valueHigh)},
                                     {"saturation", round4(asset.measure.saturationMean)}, {"partialAlphaShare", round4(asset.measure.partialShare)},
                                     {"lightDegrees", round4(asset.measure.lightDegrees)}, {"lightStrength", round4(asset.measure.lightStrength)},
                                     {"pixelBlock", asset.measure.blockSize}, {"outlineWidth", round4(asset.measure.ringWidth)}, {"fromCache", asset.fromCache}});
        Json bgs = Json::array();
        for (const Background& b : asset.backgrounds) bgs.push_back(Json::object({{"label", b.label}, {"color", hex(b.colour)}}));
        j["backgrounds"] = Json::object({{"source", asset.backgroundSource}, {"used", bgs}});
        Json sizes = Json::array();
        for (const SizeSpec& s : asset.sizes) {
            Json sj = Json::object({{"label", s.label}, {"px", round4(s.px)}});
            if (!s.scene.empty()) sj["scene"] = s.scene;
            sizes.push_back(sj);
        }
        j["onScreen"] = Json::object({{"source", asset.sizeSource}, {"sizes", sizes}});
        Json uses = Json::array();
        std::set<std::string> scenes;
        for (const TextureUse* u : asset.uses) scenes.insert(u->scene);
        for (const std::string& s : scenes) uses.push_back(s);
        j["scenes"] = uses;
        j["rules"] = rules_json(asset.rules);
        if (!asset.role.empty()) j["role"] = Json::object({{"role", asset.role}, {"from", asset.roleSource}});
        if (!asset.skipped.empty()) {
            Json skipped = Json::array();
            for (const StyleSkip& sk : asset.skipped) skipped.push_back(Json::object({{"rule", sk.rule}, {"reason", sk.reason}}));
            j["styleSkipped"] = skipped;
        }
        Json tilesJson = Json::array();
        for (std::size_t i = 0; i < asset.tileKinds.size(); ++i) tilesJson.push_back(Json::object({{"tile", asset.firstTile + int(i)}, {"shows", asset.tileKinds[i]}}));
        j["tiles"] = tilesJson;
        if (!asset.notes.empty()) j["notes"] = asset.notes;
        assetsJson.push_back(j);
    }
    Json result = Json::object({{"verdict", verdict_name(overall)}, {"counts", Json::object({{"ok", counts[0]}, {"warn", counts[1]}, {"fail", counts[2]}})}, {"assets", assetsJson}});
    if (!setRules.empty()) {
        Json sj = Json::array();
        int setCounts[3] = {0, 0, 0};
        for (const ArtRule& r : setRules) {
            sj.push_back(r.to_json());
            ++setCounts[int(r.verdict)];
            overall = worse(overall, r.verdict);
        }
        result["set"] = Json::object({{"rules", sj}});
        result["verdict"] = verdict_name(overall);
        result["counts"] = Json::object({{"ok", counts[0] + setCounts[0]}, {"warn", counts[1] + setCounts[1]}, {"fail", counts[2] + setCounts[2]}});
    }
    Json styleJson = Json::object({{"applied", applyStyle && style.has_art_rules()}});
    if (applyStyle && !style.has_art_rules()) styleJson["note"] = "assets.json sets no style rule that a picture can be measured against (outline, lightDirection, texelsPerUnit, pixelArt, value, saturation, palette): only the checks that need no style ran. See docs/ASSETS.md, \"House style\".";
    if (!applyStyle) styleJson["note"] = "style: false: the house style was not applied.";
    if (!styleParse.problems.empty()) {
        Json pj = Json::array();
        for (const StyleProblem& p : styleParse.problems) pj.push_back(Json::object({{"pointer", p.pointer}, {"message", p.message}, {"hint", p.hint}}));
        styleJson["problems"] = pj;
    }
    result["style"] = styleJson;
    result["picture"] = Json::object({{"width", picture.width}, {"height", picture.height}, {"tileColumns", layout.columns}, {"tileSize", tile}});
    std::vector<std::string> steps;
    steps.push_back("Read the picture: one row per asset, left to right the tiles listed in `assets[].tiles` (numbers in the corner): the picture, its value (greyscale), over each background and at each on-screen size.");
    if (overall != Verdict::Ok) steps.push_back("Fix the rules with verdict warn or fail (each has a `hint`), then run assets.check_art again.");
    for (const Asset& asset : assets)
        if (asset.backgroundSource == "default") {
            steps.push_back("The backgrounds of " + asset.path + " are defaults: pass `backgrounds` (colours or images) to judge it over the real ones.");
            break;
        }
    result["nextSteps"] = steps;
    result["$image"] = Json::object({{"path", out.string()}, {"mimeType", "image/png"}, {"temporary", true}});
    return result;
}

}  // namespace

void register_check_art_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = true;
    info.summary = "Check pictures against the house style and how they read in the game: palette fit, contrast over the real backgrounds, readability at phone and desktop size, halos on alpha edges, and set consistency; returns an annotated picture.";
    info.description =
        "Measures one picture (`path`) or a set (`paths`, up to 12) and returns an annotated picture plus "
        "rules, each with `value`, `threshold`, `verdict` (ok, warn or fail) and, unless ok, a `hint` naming "
        "the command or setting that fixes it. Palette fit: the colour count, and when assets.json "
        "style.palette is set the distance of the colours to it and the share of pixels off the palette "
        "(strict with style.pixelArt). Contrast: the WCAG contrast ratio between the silhouette edge and "
        "each background the picture is drawn over: `backgrounds` (colours \"#rrggbb\" or project image "
        "paths) when given, else the clear colour and the large background sprites of the scenes that use "
        "the picture, else a light and a dark default; the result says which (`backgrounds.source`). "
        "Example: {\"path\":\"assets/hero.png\",\"backgrounds\":[\"#203040\"],\"onScreenPx\":48}."
        FA_COMMAND_DETAILS
        "Readability: the picture shrunk to the size it has on screen (`onScreenPx`, the longer side in "
        "screen pixels, when given; else derived from the scenes' Sprite size, scale and camera at a phone, "
        "844x390, and a desktop, 1920x1080, screen): its size, how much of the silhouette survives and "
        "whether the outline is still a line. Halos and fringes: partly transparent edge pixels that are "
        "darker or lighter than the pixels they touch, and transparent pixels next to the shape that hold a "
        "foreign colour. Style rules set in assets.json style (outline, lightDirection, texelsPerUnit, "
        "pixelArt, value, saturation) are judged too, with the same numbers as the `project.validate` "
        "warnings; rules the style does not set are not judged, and `style: false` skips them. With several "
        "paths it also compares the set: pixel density, pixel size, outline colour and thickness, and how "
        "many colours the pictures share. The picture has one row per asset: the picture itself, its value "
        "(greyscale), over each background and at each on-screen size. It is a temporary screenshot in "
        ".factoria/screenshots; measuring is cached in .factoria/art-cache. Thresholds and the rules are "
        "listed in docs/ASSETS.md (\"Checking art: assets.check_art\").";
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"path", Json::object({{"type", "string"}, {"description", "Project-relative path of the picture to check. Give this or `paths`."}})},
               {"paths", Json::object({{"type", "array"}, {"minItems", 1}, {"maxItems", int(kMaxPaths)}, {"items", Json::object({{"type", "string"}})},
                                       {"description", "Several pictures to check one by one and as a set (pixel density, outline, palette spread). Give this or `path`."}})},
               {"backgrounds", Json::object({{"type", "array"}, {"minItems", 1}, {"maxItems", int(kMaxBackgrounds)},
                                             {"items", Json::object({{"description", "A colour (\"#rrggbb\", a name, or [r, g, b]) or the project path of an image (its dark, middle and light parts are used)."}})},
                                             {"description", "What the picture is drawn over. Default: the camera clear colour and background sprites of the scenes that use it, else a light and a dark default."}})},
               {"onScreenPx", Json::object({{"description", "The longer side of the sprite on screen, in screen pixels: a number, or a list of up to 4. Default: derived from the scenes (Sprite size, scale, camera) at a phone and a desktop screen."}})},
               {"style", Json::object({{"type", "boolean"}, {"default", true}, {"description", "Judge the rules set in assets.json style (outline, lightDirection, texelsPerUnit, pixelArt, value, saturation, palette). False skips them."}})}})}});
    registry.add(info, [projectDir](const Json& args) { return check(projectDir, args); });
}

}  // namespace fa::assets_detail
