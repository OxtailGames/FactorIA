// The pixel operations image.paint and image.edit share with the editor's Image panel (fa/tooling/image_paint.h).
#include "fa/tooling/image_paint.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/tooling/image_tile.h"
#include "image_edit.h"
#include "image_frames.h"

namespace fa {

namespace {

constexpr double kPiD = 3.14159265358979323846;

std::uint8_t to_byte(double v) { return std::uint8_t(std::lround(std::clamp(v, 0.0, 255.0))); }

}  // namespace

std::optional<ImageSelection> read_image_selection(const std::string& projectDir, const std::string& rel,
                                                   const std::string& name, int canvasW, int canvasH) {
    if (name == "all") return ImageSelection(canvasW, canvasH, 255);
    if (!imgedit::valid_selection_name(name) || !imgedit::selection_exists(projectDir, rel, name)) return std::nullopt;
    try {
        return imgedit::load_selection(projectDir, rel, name, canvasW, canvasH, "image.select");
    } catch (const CommandError&) {
        return std::nullopt;
    }
}

Result<void> write_image_selection(const std::string& projectDir, const std::string& rel, const std::string& name,
                                   const ImageSelection& selection) {
    if (!imgedit::valid_selection_name(name))
        return make_error("'" + name + "' is not a selection name.", "A name is 1 to 40 letters, digits, '-' and '_'.");
    try {
        imgedit::Mask m;
        static_cast<ImageSelection&>(m) = selection;
        imgedit::save_selection(projectDir, rel, name, m);
    } catch (const CommandError& e) {
        return make_error(e.what(), e.hint);
    }
    return {};
}

void image_over_pixel(std::uint8_t* p, double r, double g, double b, double a) {
    if (a <= 0) return;
    const double da = p[3] / 255.0;
    const double oa = a + da * (1 - a);
    if (oa <= 0) return;
    p[0] = to_byte((r * a + p[0] * da * (1 - a)) / oa);
    p[1] = to_byte((g * a + p[1] * da * (1 - a)) / oa);
    p[2] = to_byte((b * a + p[2] * da * (1 - a)) / oa);
    p[3] = to_byte(oa * 255.0);
    if (p[3] == 0) p[0] = p[1] = p[2] = 0;
}

std::size_t paint_image_stroke(Image& img, int originX, int originY, const std::vector<std::pair<double, double>>& pts,
                               const ImageBrush& brush, const ImageSelection* selection, const TileGrid* tiles) {
    if (pts.empty() || img.width <= 0 || img.height <= 0) return 0;
    const double size = brush.size, hardness = brush.hardness, opacity = brush.opacity;
    const double spacing = std::max(0.25, brush.spacing > 0 ? brush.spacing : std::max(1.0, size * 0.2));
    // the stroke's coverage: the largest value any stamp gives a pixel, so a stroke does not darken where it overlaps itself
    std::vector<float> cov(std::size_t(img.width) * img.height, 0.0f);
    const double r = size / 2, inner = r * hardness;
    std::size_t stamped = 0;
    int minX = img.width, minY = img.height, maxX = -1, maxY = -1;  // the box the stamps touched: only it is blended
    const bool wrap = tiles && tiles->on;
    // tile mode: the stroke wraps inside the tile that holds its first point, so a stamp is drawn once per copy of the tile that reaches it
    const int cellX = wrap ? tiles->cell_x(int(std::floor(pts[0].first))) : 0,
              cellY = wrap ? tiles->cell_y(int(std::floor(pts[0].second))) : 0;
    auto stamp_one = [&](double cx, double cy, int clipX0, int clipY0, int clipX1,
                         int clipY1) {  // clip: buffer pixels [x0, x1] x [y0, y1]
        const int x0 = std::max(clipX0, int(std::floor(cx - r - 1 - originX))),
                  x1 = std::min(clipX1, int(std::ceil(cx + r + 1 - originX)));
        const int y0 = std::max(clipY0, int(std::floor(cy - r - 1 - originY))),
                  y1 = std::min(clipY1, int(std::ceil(cy + r + 1 - originY)));
        if (x0 <= x1 && y0 <= y1) {
            minX = std::min(minX, x0);
            maxX = std::max(maxX, x1);
            minY = std::min(minY, y0);
            maxY = std::max(maxY, y1);
        }
        for (int y = y0; y <= y1; ++y)
            for (int x = x0; x <= x1; ++x) {
                const double dist = std::hypot(originX + x + 0.5 - cx, originY + y + 0.5 - cy);
                double c;
                if (dist <= inner)
                    c = 1;
                else if (r + 0.5 - inner <= 1e-9)
                    c = 0;
                else
                    c = std::clamp((r + 0.5 - dist) / (r + 0.5 - inner), 0.0, 1.0);
                if (hardness >= 1 && dist > r + 0.5) c = 0;
                float& slot = cov[std::size_t(y) * img.width + x];
                if (c > slot) slot = float(c);
            }
    };
    auto stamp = [&](double cx, double cy) {
        ++stamped;
        if (!wrap) return stamp_one(cx, cy, 0, 0, img.width - 1, img.height - 1);
        // the centre moves into the cell, then every copy of the cell around it is tried: a brush wider than a tile touches several
        const double fx = std::fmod(cx - cellX, double(tiles->tw)), fy = std::fmod(cy - cellY, double(tiles->th));
        cx = cellX + (fx < 0 ? fx + tiles->tw : fx);
        cy = cellY + (fy < 0 ? fy + tiles->th : fy);
        const int clipX0 = std::max(0, cellX - originX), clipY0 = std::max(0, cellY - originY);
        const int clipX1 = std::min(img.width - 1, cellX + tiles->tw - 1 - originX),
                  clipY1 = std::min(img.height - 1, cellY + tiles->th - 1 - originY);
        const int nx = int(std::ceil((r + 1) / tiles->tw)), ny = int(std::ceil((r + 1) / tiles->th));
        for (int j = -ny; j <= ny; ++j)
            for (int i = -nx; i <= nx; ++i)
                stamp_one(cx + i * tiles->tw, cy + j * tiles->th, clipX0, clipY0, clipX1, clipY1);
    };
    stamp(pts[0].first, pts[0].second);
    double carry = 0;
    for (std::size_t k = 1; k < pts.size(); ++k) {
        const double sx = pts[k - 1].first, sy = pts[k - 1].second, ex = pts[k].first, ey = pts[k].second;
        const double len = std::hypot(ex - sx, ey - sy);
        double pos = spacing - carry;
        for (; pos <= len + 1e-9; pos += spacing) stamp(sx + (ex - sx) * pos / len, sy + (ey - sy) * pos / len);
        carry = len - (pos - spacing);
    }
    if (pts.size() > 1) stamp(pts.back().first, pts.back().second);
    for (int y = minY; y <= maxY; ++y)
        for (int x = minX; x <= maxX; ++x) {
            float c = cov[std::size_t(y) * img.width + x];
            if (c <= 0) continue;
            if (selection) c *= selection->at(originX + x, originY + y) / 255.0f;
            if (c <= 0) continue;
            std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
            if (brush.erase) {
                p[3] = to_byte(p[3] * (1 - c * opacity));
                if (!p[3]) p[0] = p[1] = p[2] = 0;
            } else {
                image_over_pixel(p, brush.color.r * 255.0, brush.color.g * 255.0, brush.color.b * 255.0,
                                 c * opacity * brush.color.a);
            }
        }
    return stamped;
}

std::size_t image_patch_draw_wrapped(Image& img, int originX, int originY, const ImagePatch& p, int fromX, int fromY,
                                     const TileGrid& tiles) {
    std::size_t dropped = 0;
    for (int y = 0; y < p.img.height; ++y)
        for (int x = 0; x < p.img.width; ++x) {
            const std::uint8_t* s = &p.img.rgba[(std::size_t(y) * p.img.width + x) * 4];
            if (!s[3]) continue;
            const int cx = tiles.cell_x(fromX + x), cy = tiles.cell_y(fromY + y);
            const int bx = tiles.wrap_x(p.x + x, cx) - originX, by = tiles.wrap_y(p.y + y, cy) - originY;
            if (bx < 0 || by < 0 || bx >= img.width || by >= img.height) {
                ++dropped;
                continue;
            }
            image_over_pixel(&img.rgba[(std::size_t(by) * img.width + bx) * 4], s[0], s[1], s[2], s[3] / 255.0);
        }
    return dropped;
}

ImagePatch image_patch_extract(const Image& img, int originX, int originY, const ImageSelection& sel) {
    ImagePatch p;
    int x0 = img.width, y0 = img.height, x1 = -1, y1 = -1;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x)
            if (sel.at(originX + x, originY + y) && img.rgba[(std::size_t(y) * img.width + x) * 4 + 3]) {
                x0 = std::min(x0, x);
                x1 = std::max(x1, x);
                y0 = std::min(y0, y);
                y1 = std::max(y1, y);
            }
    if (x1 < 0) return p;
    p.x = originX + x0;
    p.y = originY + y0;
    p.img.width = x1 - x0 + 1;
    p.img.height = y1 - y0 + 1;
    p.img.rgba.assign(std::size_t(p.img.width) * p.img.height * 4, 0);
    for (int y = 0; y < p.img.height; ++y)
        for (int x = 0; x < p.img.width; ++x) {
            const std::uint8_t* s = &img.rgba[(std::size_t(y + y0) * img.width + x + x0) * 4];
            std::uint8_t* d = &p.img.rgba[(std::size_t(y) * p.img.width + x) * 4];
            const double a = s[3] * (sel.at(p.x + x, p.y + y) / 255.0f);
            if (a < 0.5) continue;
            d[0] = s[0];
            d[1] = s[1];
            d[2] = s[2];
            d[3] = to_byte(a);
        }
    return p;
}

void image_patch_erase(Image& img, int originX, int originY, const ImageSelection& sel) {
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
            const float s = sel.at(originX + x, originY + y) / 255.0f;
            if (s <= 0 || !p[3]) continue;
            p[3] = to_byte(p[3] * (1 - s));
            if (!p[3]) p[0] = p[1] = p[2] = 0;
        }
}

std::size_t image_patch_draw(Image& img, int originX, int originY, const ImagePatch& p) {
    std::size_t dropped = 0;
    for (int y = 0; y < p.img.height; ++y)
        for (int x = 0; x < p.img.width; ++x) {
            const std::uint8_t* s = &p.img.rgba[(std::size_t(y) * p.img.width + x) * 4];
            if (!s[3]) continue;
            const int bx = p.x + x - originX, by = p.y + y - originY;
            if (bx < 0 || by < 0 || bx >= img.width || by >= img.height) {
                ++dropped;
                continue;
            }
            image_over_pixel(&img.rgba[(std::size_t(by) * img.width + bx) * 4], s[0], s[1], s[2], s[3] / 255.0);
        }
    return dropped;
}

Result<ImagePatch> image_patch_transform(const ImagePatch& p, const ImageTransform& t) {
    const double sx = t.scaleX, sy = t.scaleY, pvx = t.pivotX, pvy = t.pivotY;
    const double th = t.rotate * kPiD / 180.0, c = std::cos(th), s = std::sin(th);
    const double fx = t.flipH ? -1 : 1, fy = t.flipV ? -1 : 1;
    auto fwd = [&](double px, double py, double& ox, double& oy) {
        double x = (px - pvx) * fx * sx, y = (py - pvy) * fy * sy;
        ox = pvx + x * c - y * s;
        oy = pvy + x * s + y * c;
    };
    double minx = 1e18, miny = 1e18, maxx = -1e18, maxy = -1e18;
    const double cx[4] = {double(p.x), double(p.x + p.img.width), double(p.x), double(p.x + p.img.width)};
    const double cy[4] = {double(p.y), double(p.y), double(p.y + p.img.height), double(p.y + p.img.height)};
    for (int k = 0; k < 4; ++k) {
        double ox, oy;
        fwd(cx[k], cy[k], ox, oy);
        minx = std::min(minx, ox);
        maxx = std::max(maxx, ox);
        miny = std::min(miny, oy);
        maxy = std::max(maxy, oy);
    }
    ImagePatch out;
    out.x = int(std::floor(minx + 1e-9));
    out.y = int(std::floor(miny + 1e-9));
    const int w = int(std::ceil(maxx - 1e-9)) - out.x, h = int(std::ceil(maxy - 1e-9)) - out.y;
    if (w <= 0 || h <= 0 || std::int64_t(w) * h > 64'000'000)
        return make_error(std::format("the transformed selection would be {}x{} pixels.", w, h),
                          "Use a smaller scale (the limit is 64 million pixels).");
    out.img.width = w;
    out.img.height = h;
    out.img.rgba.assign(std::size_t(w) * h * 4, 0);
    const auto& src = p.img;
    auto fetch = [&](int ix, int iy, double& r, double& g, double& b, double& a) {
        if (ix < 0 || iy < 0 || ix >= src.width || iy >= src.height) {
            r = g = b = a = 0;
            return;
        }
        const std::uint8_t* q = &src.rgba[(std::size_t(iy) * src.width + ix) * 4];
        a = q[3] / 255.0;
        r = q[0] * a;
        g = q[1] * a;
        b = q[2] * a;
    };
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            // the destination pixel's centre, back to the source
            const double dx = out.x + x + 0.5 - pvx, dy = out.y + y + 0.5 - pvy;
            const double ux = dx * c + dy * s, uy = -dx * s + dy * c;
            const double u = pvx + ux / (sx * fx) - p.x, v = pvy + uy / (sy * fy) - p.y;
            std::uint8_t* d = &out.img.rgba[(std::size_t(y) * w + x) * 4];
            if (t.nearest) {
                const int ix = int(std::floor(u)), iy = int(std::floor(v));
                if (ix < 0 || iy < 0 || ix >= src.width || iy >= src.height) continue;
                std::copy_n(&src.rgba[(std::size_t(iy) * src.width + ix) * 4], 4, d);
            } else {
                if (u < -0.5 || v < -0.5 || u > src.width + 0.5 || v > src.height + 0.5) continue;
                const double gx = u - 0.5, gy = v - 0.5;
                const int ix = int(std::floor(gx)), iy = int(std::floor(gy));
                const double tx = gx - ix, ty = gy - iy;
                double acc[4] = {0, 0, 0, 0};
                for (int j = 0; j < 2; ++j)
                    for (int i = 0; i < 2; ++i) {
                        double r, g, b, a;
                        fetch(ix + i, iy + j, r, g, b, a);
                        const double wgt = (i ? tx : 1 - tx) * (j ? ty : 1 - ty);
                        acc[0] += r * wgt;
                        acc[1] += g * wgt;
                        acc[2] += b * wgt;
                        acc[3] += a * wgt;
                    }
                if (acc[3] <= 1e-6) continue;
                d[0] = to_byte(acc[0] / acc[3]);
                d[1] = to_byte(acc[1] / acc[3]);
                d[2] = to_byte(acc[2] / acc[3]);
                d[3] = to_byte(acc[3] * 255);
                if (!d[3]) d[0] = d[1] = d[2] = 0;
            }
        }
    return out;
}

Result<ImageEditBuffer> open_image_edit_buffer(const std::string& projectDir, const std::string& rel,
                                               const Json& document, const std::string& layerPath, int frame) {
    try {
        Json doc = document;
        Json args = Json::object();
        if (frame > 0 || imgedit::json_animated(doc)) args["frame"] = frame;
        imgedit::FrameScope scope(projectDir, rel, doc, args, "image.paint");
        imgedit::LayerRef ref = imgedit::find_layer(doc, Json(layerPath), "image.paint");
        imgedit::Work w = imgedit::open_work(projectDir, doc, ref, "image.paint", true, false);
        ImageEditBuffer out;
        out.img = std::move(w.img);
        out.ox = w.ox;
        out.oy = w.oy;
        out.fixedRect = w.fixedRect;
        out.kind = w.kind;
        return out;
    } catch (const CommandError& e) {
        return make_error(e.what(), e.hint);
    }
}

}  // namespace fa
