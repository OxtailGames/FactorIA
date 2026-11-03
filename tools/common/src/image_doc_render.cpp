// The compositor: an ImageDocument to pixels. One CPU implementation, no GPU, no threads, no clock: the same document and
// files give the same bytes with the same build. Colour and alpha rules are in fa/tooling/image_doc.h.
//
// Each layer goes through the same pipeline, bottom layer first:
//   content (the layer's own pixels, at its own coordinates)
//     -> adjustments (colour only)  -> masks (alpha)  -> effects (may grow the raster)
//     -> clipping to the layer below  -> opacity  -> blend onto the canvas at the layer's offset
// A group renders its children onto a transparent canvas of its own (groups are always isolated: a child's blend mode acts
// inside the group), then goes through the same pipeline as a layer of pixels. An adjustment layer instead applies its
// adjustments to the canvas below it, blended in by its masks, clipping and opacity.
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <format>
#include <map>
#include <set>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/render/fonts.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/style_guide.h"
#include "image_doc_internal.h"
#include "util.h"

namespace fa {

namespace {

using namespace imgdoc;
namespace stdfs = std::filesystem;

struct RenderFailure {
    std::string message, hint;
};

struct Ctx {
    const ImageDocument& doc;
    std::string projectDir;
    std::map<std::string, Image> images;
    const std::map<std::string, Image>* stand = nullptr;  // ImageRenderOptions::pictures: read before the disk, never copied
    std::set<std::string> inputs;
    std::vector<std::string> warnings;
    std::optional<StyleGuide> styleGuide;  // read from assets.json the first time an operation asks
    int frame = 0;                         // the frame being drawn: pixels and indexed layers show their cel of it

    const StyleGuide& style() {
        if (!styleGuide) styleGuide = projectDir.empty() ? StyleGuide{} : load_style_guide(projectDir).guide;
        return *styleGuide;
    }
    // The environment of the operations of the layer at `pointer` (`list`: "adjustments" or "effects").
    OpEnv op_env(const std::string& pointer, const char* list) {
        OpEnv env;
        env.image = [this, pointer, list](const std::string& rel) -> const Image& { return image(pointer + "/" + list, rel); };
        env.style = [this]() -> const StyleGuide& { return style(); };
        env.fail = [this, pointer, list](const std::string& message, const std::string& hint) { fail(pointer + "/" + list, message, hint); };
        return env;
    }

    [[noreturn]] void fail(const std::string& pointer, const std::string& message, const std::string& hint) const {
        throw RenderFailure{(doc.file.empty() ? std::string("image document") : doc.file) + " " + pointer + ": " + message, hint};
    }

    const Image& image(const std::string& pointer, const std::string& rel) {
        auto it = images.find(rel);
        if (it != images.end()) return it->second;
        if (stand) {
            auto st = stand->find(rel);
            if (st != stand->end()) return st->second;
        }
        auto path = resolve_project_path(projectDir, rel);
        if (!path.ok()) fail(pointer, path.error().message, path.error().hint);
        auto img = assets_detail::load_image(*path);
        if (!img.ok()) fail(pointer, "Cannot read the picture '" + rel + "': " + img.error().message, img.error().hint.empty() ? "Check that the file exists and is a PNG." : img.error().hint);
        inputs.insert(rel);
        return images.emplace(rel, std::move(*img)).first->second;
    }
};

// ---- content ---------------------------------------------------------------------------------------------------------

Raster solid_box(int w, int h, Color c) {
    Raster r(w, h);
    for (std::size_t i = 0; i < r.px.size(); i += 4) {
        r.px[i] = c.r;
        r.px[i + 1] = c.g;
        r.px[i + 2] = c.b;
        r.px[i + 3] = c.a;
    }
    return r;
}

Raster gradient_box(const ImageGradient& g, int w, int h) {
    Raster r(w, h);
    const float angle = g.angle * 3.14159265358979323846f / 180.0f;
    const float dx = std::sin(angle), dy = std::cos(angle);  // 0 degrees runs down, 90 runs right
    const float lineLength = std::max(1e-6f, std::fabs(float(w) * dx) + std::fabs(float(h) * dy));
    const float cx = float(w) * g.center.x, cy = float(h) * g.center.y;
    const float reach = std::max(1e-6f, 0.5f * std::sqrt(float(w) * float(w) + float(h) * float(h)) * g.radius);
    const auto& stops = g.stops;
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            const float px = float(x) + 0.5f, py = float(y) + 0.5f;
            float t;
            if (g.radial) t = std::sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy)) / reach;
            else t = ((px - float(w) * 0.5f) * dx + (py - float(h) * 0.5f) * dy) / lineLength + 0.5f;
            t = std::clamp(t, 0.0f, 1.0f);
            // premultiplied interpolation between the two stops around t
            float rgba[4];
            std::size_t k = 0;
            while (k + 1 < stops.size() && t > stops[k + 1].at) ++k;
            if (t <= stops.front().at) {
                const Color& c = stops.front().color;
                rgba[0] = c.r; rgba[1] = c.g; rgba[2] = c.b; rgba[3] = c.a;
            } else if (k + 1 >= stops.size()) {
                const Color& c = stops.back().color;
                rgba[0] = c.r; rgba[1] = c.g; rgba[2] = c.b; rgba[3] = c.a;
            } else {
                const ImageGradientStop &a = stops[k], &b = stops[k + 1];
                const float span = b.at - a.at;
                const float u = span <= 0.0f ? 1.0f : (t - a.at) / span;
                const float aa = a.color.a + (b.color.a - a.color.a) * u;
                const float pr = a.color.r * a.color.a + (b.color.r * b.color.a - a.color.r * a.color.a) * u;
                const float pg = a.color.g * a.color.a + (b.color.g * b.color.a - a.color.g * a.color.a) * u;
                const float pb = a.color.b * a.color.a + (b.color.b * b.color.a - a.color.b * a.color.a) * u;
                rgba[3] = aa;
                rgba[0] = aa > 0 ? pr / aa : 0;
                rgba[1] = aa > 0 ? pg / aa : 0;
                rgba[2] = aa > 0 ? pb / aa : 0;
            }
            float* d = r.at(x, y);
            for (int c = 0; c < 4; ++c) d[c] = rgba[c];
        }
    return r;
}

Raster text_raster(Ctx& ctx, const ImageLayer& layer) {
    std::vector<std::string> lines = split(layer.text, '\n', false);
    for (std::string& line : lines)
        if (!line.empty() && line.back() == '\r') line.pop_back();
    auto probe = rasterize_text("Hg", layer.font, layer.size);
    if (!probe.ok()) ctx.fail(layer.pointer + "/font", "Cannot draw text with the font '" + layer.font + "': " + probe.error().message, probe.error().hint);
    const float ascent = probe->ascent;
    struct Placed {
        TextBitmap bmp;
        int left, top;
    };
    std::vector<Placed> placed;
    int minX = 0, minY = 0, maxX = 0, maxY = 0;
    bool any = false;
    for (std::size_t i = 0; i < lines.size(); ++i) {
        if (lines[i].empty()) continue;
        auto bmp = rasterize_text(lines[i], layer.font, layer.size);
        if (!bmp.ok()) ctx.fail(layer.pointer + "/text", "Cannot draw the text: " + bmp.error().message, bmp.error().hint);
        if (bmp->width <= 0) continue;
        const float pen = layer.align == "center" ? -bmp->advance * 0.5f : layer.align == "right" ? -bmp->advance : 0.0f;
        const int baseline = int(std::lround(ascent + float(i) * layer.lineHeight * layer.size));
        Placed p{std::move(*bmp), 0, 0};
        p.left = int(std::lround(pen)) - p.bmp.originX;
        p.top = baseline - p.bmp.originY;
        if (!any) {
            minX = p.left; minY = p.top; maxX = p.left + p.bmp.width; maxY = p.top + p.bmp.height;
            any = true;
        } else {
            minX = std::min(minX, p.left); minY = std::min(minY, p.top);
            maxX = std::max(maxX, p.left + p.bmp.width); maxY = std::max(maxY, p.top + p.bmp.height);
        }
        placed.push_back(std::move(p));
    }
    if (!any) {
        ctx.warnings.push_back(layer.pointer + ": the text draws nothing (only spaces, or characters no font has).");
        return Raster();
    }
    Raster r(maxX - minX, maxY - minY, minX, minY);
    for (const Placed& p : placed)
        for (int y = 0; y < p.bmp.height; ++y)
            for (int x = 0; x < p.bmp.width; ++x) {
                const float cov = float(p.bmp.coverage[std::size_t(y) * p.bmp.width + x]) / 255.0f * layer.color.a;
                if (cov <= 0.0f) continue;
                float* d = r.at(p.left + x - minX, p.top + y - minY);
                const float inv = 1.0f - cov, outA = cov + d[3] * inv;
                d[0] = layer.color.r; d[1] = layer.color.g; d[2] = layer.color.b;  // one colour per layer
                d[3] = outA;
            }
    return r;
}

Raster render_content(Ctx& ctx, const ImageLayer& layer, const ImageCelView& cel);

void composite_layers(Ctx& ctx, const std::vector<ImageLayer>& layers, Raster& canvas);

Raster render_content(Ctx& ctx, const ImageLayer& layer, const ImageCelView& cel) {
    const int cw = ctx.doc.width, ch = ctx.doc.height;
    switch (layer.kind) {
        case ImageLayerKind::Pixels:
            if (cel.empty) return Raster();
            return from_image(ctx.image(cel.origin == 0 ? layer.pointer + "/source" : layer.pointer + "/cels", *cel.source));
        case ImageLayerKind::Provider: return from_image(ctx.image(layer.pointer + "/source", layer.source));
        case ImageLayerKind::Fill: return solid_box(layer.width > 0 ? layer.width : cw, layer.height > 0 ? layer.height : ch, layer.color);
        case ImageLayerKind::Gradient: return gradient_box(layer.gradient, layer.width > 0 ? layer.width : cw, layer.height > 0 ? layer.height : ch);
        case ImageLayerKind::Procedural: {
            Json args = layer.texture;
            if (!args.contains("width")) args["width"] = cw;
            if (!args.contains("height")) args["height"] = ch;
            try {
                return from_image(assets_detail::procedural_texture_image(args, "image.bake", layer.pointer + "/texture", ctx.warnings));
            } catch (const CommandError& e) {
                ctx.fail(layer.pointer + "/texture", e.what(), e.hint);
            }
        }
        case ImageLayerKind::Svg: {
            std::string text = layer.svg;
            if (!layer.source.empty()) {
                auto path = resolve_project_path(ctx.projectDir, layer.source);
                auto data = path.ok() ? tooling_detail::read_file(*path) : std::nullopt;
                if (!data) ctx.fail(layer.pointer + "/source", "Cannot read '" + layer.source + "'.", "Check the path; it is relative to the project folder.");
                ctx.inputs.insert(layer.source);
                text = std::move(*data);
            }
            int w = layer.width, h = layer.height;
            if (w == 0 && h == 0) w = cw, h = ch;
            try {
                return from_image(assets_detail::rasterize_svg_text(text, w, h, "none", 0.0, 0, ctx.warnings).image);
            } catch (const CommandError& e) {
                ctx.fail(layer.pointer + (layer.source.empty() ? "/svg" : "/source"), e.what(), e.hint);
            }
        }
        case ImageLayerKind::Text: return text_raster(ctx, layer);
        case ImageLayerKind::Group: {
            Raster inner(cw, ch);
            composite_layers(ctx, layer.children, inner);
            return inner;
        }
        case ImageLayerKind::Indexed: {
            const std::vector<std::string>& rows = *cel.rows;
            if (cel.empty) return Raster();
            const int w = !rows.empty() ? int(rows[0].size()) : layer.width > 0 ? layer.width : cw;
            const int h = !rows.empty() ? int(rows.size()) : layer.height > 0 ? layer.height : ch;
            Raster r(w, h);
            if (rows.empty()) return r;  // a blank layer
            if (ctx.doc.palette.empty())
                ctx.fail(layer.pointer, "The layer is indexed but the document has no palette to look its colours up in.",
                         "Add `palette` to the document (a list of colours), or set style.palette in assets.json and parse the document with its project folder.");
            for (int y = 0; y < h && y < int(rows.size()); ++y)
                for (int x = 0; x < w; ++x) {
                    const int idx = pixel_char_index(rows[std::size_t(y)][std::size_t(x)]);
                    if (idx < 0 || idx >= ctx.doc.palette.size()) continue;
                    float* d = r.at(x, y);
                    const auto& c = ctx.doc.palette.entries[std::size_t(idx)].rgb;
                    d[0] = float(c[0]) / 255.0f;
                    d[1] = float(c[1]) / 255.0f;
                    d[2] = float(c[2]) / 255.0f;
                    d[3] = 1.0f;
                }
            return r;
        }
        case ImageLayerKind::Adjustment: break;
    }
    return Raster();
}

// ---- masks -----------------------------------------------------------------------------------------------------------

// The coverage of `mask` over the rectangle (ox, oy, w, h) of the layer's own coordinates.
Plane mask_plane(Ctx& ctx, const ImageMask& mask, int ox, int oy, int w, int h) {
    const int pad = mask.feather > 0 ? int(std::ceil(mask.feather * 1.5f)) : 0;  // sigma = feather / 2, reach 3 sigma
    const int pw = w + 2 * pad, ph = h + 2 * pad, pox = ox - pad, poy = oy - pad;
    Plane plane(pw, ph, pox, poy, 0.0f);
    switch (mask.type) {
        case ImageMask::Type::Pixels: {
            const Image& img = ctx.image(mask.pointer + "/source", mask.source);
            for (int y = 0; y < ph; ++y)
                for (int x = 0; x < pw; ++x) {
                    const int ix = pox + x - mask.x, iy = poy + y - mask.y;
                    if (ix < 0 || iy < 0 || ix >= img.width || iy >= img.height) continue;
                    const std::uint8_t* p = &img.rgba[(std::size_t(iy) * img.width + ix) * 4];
                    const float lum = (0.3f * p[0] + 0.59f * p[1] + 0.11f * p[2]) / 255.0f;
                    plane.at(x, y) = lum * (p[3] / 255.0f);
                }
            break;
        }
        case ImageMask::Type::Rect:
            for (int y = 0; y < ph; ++y)
                for (int x = 0; x < pw; ++x) {
                    const int lx = pox + x, ly = poy + y;
                    if (lx >= mask.x && lx < mask.x + mask.width && ly >= mask.y && ly < mask.y + mask.height) plane.at(x, y) = 1.0f;
                }
            break;
        case ImageMask::Type::Ellipse: plane = fill_shapes({ellipse_polyline(float(mask.x), float(mask.y), float(mask.width), float(mask.height))}, pw, ph, pox, poy); break;
        case ImageMask::Type::Polygon: plane = fill_shapes({Polyline{mask.points}}, pw, ph, pox, poy); break;
        case ImageMask::Type::Path: {
            std::vector<Polyline> shapes;
            std::string err;
            if (!parse_svg_path(mask.path, shapes, err)) ctx.fail(mask.pointer + "/path", "The path data is not valid: " + err + ".", "Write SVG path data such as \"M10 10 L90 10 L50 80 Z\".");
            plane = fill_shapes(shapes, pw, ph, pox, poy);
            break;
        }
    }
    if (mask.feather > 0) blur_plane(plane, mask.feather * 0.5f);
    Plane out(w, h, ox, oy, 0.0f);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            const float v = plane.at(x + pad, y + pad);
            out.at(x, y) = mask.invert ? 1.0f - v : v;
        }
    return out;
}

// The product of all the masks of a layer over a rectangle (all ones without masks).
Plane masks_plane(Ctx& ctx, const std::vector<ImageMask>& masks, int ox, int oy, int w, int h) {
    Plane total(w, h, ox, oy, 1.0f);
    for (const ImageMask& m : masks) {
        const Plane p = mask_plane(ctx, m, ox, oy, w, h);
        for (std::size_t i = 0; i < total.v.size(); ++i) total.v[i] *= p.v[i];
    }
    return total;
}

// ---- the layer pipeline ----------------------------------------------------------------------------------------------

struct ClipBase {
    bool valid = false;  // a visible layer below, whose shape clipped layers follow
    Plane alpha;         // its alpha over the canvas (before its opacity)
};

void composite_layers(Ctx& ctx, const std::vector<ImageLayer>& layers, Raster& canvas) {
    ClipBase base;
    for (std::size_t li = 0; li < layers.size(); ++li) {
        const ImageLayer& layer = layers[li];
        const bool nextClips = li + 1 < layers.size() && layers[li + 1].clip;
        if (!layer.visible) {
            if (!layer.clip) base.valid = false;  // a hidden base hides the layers clipped to it
            continue;
        }
        if (layer.clip && !base.valid) continue;

        if (layer.kind == ImageLayerKind::Adjustment) {
            // coverage over the canvas, in canvas coordinates; masks are in the layer's own coordinates (offset x, y)
            Plane cov = masks_plane(ctx, layer.masks, -layer.x, -layer.y, canvas.w, canvas.h);
            if (nextClips && !layer.clip) {
                base.alpha = Plane(canvas.w, canvas.h, 0, 0, 0.0f);
                base.alpha.v = cov.v;
                base.valid = true;
            } else if (!layer.clip) {
                base.valid = false;
            }
            Raster adjusted = canvas;
            apply_adjustments(layer.adjustments, adjusted, ctx.op_env(layer.pointer, "adjustments"));
            for (std::size_t i = 0; i < cov.v.size(); ++i) {
                float c = cov.v[i] * layer.opacity;
                if (layer.clip) c *= base.alpha.v[i];
                if (c <= 0.0f) continue;
                float* d = &canvas.px[i * 4];
                const float* a = &adjusted.px[i * 4];
                for (int k = 0; k < 3; ++k) d[k] += (a[k] - d[k]) * c;
            }
            continue;
        }

        const ImageCelView cel = image_layer_cel(layer, ctx.frame);
        const int layerX = cel.x, layerY = cel.y;
        const float layerOpacity = layer.opacity * cel.opacity;
        Raster r = render_content(ctx, layer, cel);
        if (!r.empty()) {
            apply_adjustments(layer.adjustments, r, ctx.op_env(layer.pointer, "adjustments"));
            if (!layer.masks.empty()) {
                const Plane cov = masks_plane(ctx, layer.masks, r.ox, r.oy, r.w, r.h);
                for (std::size_t i = 0; i < cov.v.size(); ++i) r.px[i * 4 + 3] *= cov.v[i];
            }
            apply_effects(layer.effects, r, ctx.op_env(layer.pointer, "effects"));
        }
        // r's pixel (i, j) lies at canvas (layer.x + r.ox + i, layer.y + r.oy + j)
        const int cx0 = layerX + r.ox, cy0 = layerY + r.oy;
        if (!layer.clip && nextClips) {
            base.alpha = Plane(canvas.w, canvas.h, 0, 0, 0.0f);
            for (int j = 0; j < r.h; ++j)
                for (int i = 0; i < r.w; ++i) {
                    const int x = cx0 + i, y = cy0 + j;
                    if (x < 0 || y < 0 || x >= canvas.w || y >= canvas.h) continue;
                    base.alpha.at(x, y) = r.at(i, j)[3];
                }
            base.valid = true;
        } else if (!layer.clip) {
            base.valid = false;
        }
        for (int j = 0; j < r.h; ++j) {
            const int y = cy0 + j;
            if (y < 0 || y >= canvas.h) continue;
            for (int i = 0; i < r.w; ++i) {
                const int x = cx0 + i;
                if (x < 0 || x >= canvas.w) continue;
                float s[4];
                const float* src = r.at(i, j);
                s[0] = src[0]; s[1] = src[1]; s[2] = src[2];
                s[3] = src[3] * layerOpacity;
                if (layer.clip) s[3] *= base.alpha.at(x, y);
                if (s[3] <= 0.0f) continue;
                float* d = canvas.at(x, y);
                composite_pixel(layer.blend, d, s, d);
            }
        }
    }
}

}  // namespace

namespace {

Raster blank_canvas(const ImageDocument& doc, bool withBackground) {
    Raster canvas(doc.width, doc.height);
    if (withBackground && doc.background) {
        for (std::size_t i = 0; i < canvas.px.size(); i += 4) {
            canvas.px[i] = doc.background->r;
            canvas.px[i + 1] = doc.background->g;
            canvas.px[i + 2] = doc.background->b;
            canvas.px[i + 3] = doc.background->a;
        }
    }
    return canvas;
}

Raster draw_frame(Ctx& ctx, int frame, bool withBackground) {
    ctx.frame = frame;
    Raster canvas = blank_canvas(ctx.doc, withBackground);
    composite_layers(ctx, ctx.doc.layers, canvas);
    return canvas;
}

// `r` over `canvas`, pixel for pixel (both are the size of the document).
void draw_over(Raster& canvas, const Raster& r) {
    for (std::size_t i = 0; i < canvas.px.size(); i += 4) {
        if (r.px[i + 3] <= 0.0f) continue;
        composite_pixel(ImageBlend::Normal, &canvas.px[i], &r.px[i], &canvas.px[i]);
    }
}

// The ghosts of the frames around `frame` under the frame itself.
Raster draw_with_onion(Ctx& ctx, int frame, const ImageOnionSkin& onion) {
    const int n = image_frame_count(ctx.doc);
    Raster canvas = blank_canvas(ctx.doc, true);
    auto ghost = [&](int distance, int sign) {
        int f = frame + sign * distance;
        if (onion.loop && n > 1) f = ((f % n) + n) % n;
        if (f < 0 || f >= n || f == frame) return;
        Raster g = draw_frame(ctx, f, false);
        const Color tint = sign < 0 ? onion.beforeColor : onion.afterColor;
        const float alpha = onion.opacity / float(distance);
        for (std::size_t i = 0; i < g.px.size(); i += 4) {
            if (g.px[i + 3] <= 0.0f) continue;
            g.px[i] = g.px[i] * 0.4f + tint.r * 0.6f;
            g.px[i + 1] = g.px[i + 1] * 0.4f + tint.g * 0.6f;
            g.px[i + 2] = g.px[i + 2] * 0.4f + tint.b * 0.6f;
            g.px[i + 3] *= alpha;
        }
        draw_over(canvas, g);
    };
    for (int d = onion.before; d >= 1; --d) ghost(d, -1);   // the farthest first
    for (int d = onion.after; d >= 1; --d) ghost(d, +1);
    draw_over(canvas, draw_frame(ctx, frame, false));
    return canvas;
}

Result<void> check_canvas(const ImageDocument& doc) {
    if (doc.width < 1 || doc.height < 1 || doc.width > kImageDocMaxSide || doc.height > kImageDocMaxSide)
        return make_error(std::format("The canvas is {}x{}, which is not from 1 to {} on each side.", doc.width, doc.height, kImageDocMaxSide), "Set width and height of the document.");
    return {};
}

// A warning a layer makes while it is drawn is made again for every frame: say it once.
std::vector<std::string> unique_warnings(std::vector<std::string> list) {
    std::vector<std::string> out;
    for (std::string& w : list)
        if (std::find(out.begin(), out.end(), w) == out.end()) out.push_back(std::move(w));
    return out;
}

ImageRender finish(Ctx& ctx, const Raster& canvas) {
    ImageRender out;
    out.image = to_image(canvas);
    out.inputs.assign(ctx.inputs.begin(), ctx.inputs.end());
    out.warnings = unique_warnings(std::move(ctx.warnings));
    return out;
}

}  // namespace

Result<ImageRender> composite_image_document(const ImageDocument& doc, const ImageRenderOptions& options) {
    if (auto ok = check_canvas(doc); !ok.ok()) return ok.error();
    const int frames = image_frame_count(doc);
    if (options.frame < 0 || options.frame >= frames)
        return make_error(std::format("Frame {} does not exist: the document has {} frame{} (0 to {}).", options.frame, frames, frames == 1 ? "" : "s", frames - 1),
                          frames == 1 ? "Add frames with image.frame.add, or draw frame 0." : "Use a frame from 0 to " + std::to_string(frames - 1) + ".");
    Ctx ctx{doc, options.projectDir, {}, options.pictures, {}, {}};
    assets_detail::ProjectRootGuard root(options.projectDir);  // fonts are read through the VFS
    try {
        if (options.onion && frames > 1) return finish(ctx, draw_with_onion(ctx, options.frame, *options.onion));
        return finish(ctx, draw_frame(ctx, options.frame, true));
    } catch (const RenderFailure& f) {
        return make_error(f.message, f.hint);
    }
}

Result<ImageRender> composite_image_sheet(const ImageDocument& doc, const ImageSheetPlan& plan, const ImageRenderOptions& options) {
    if (auto ok = check_canvas(doc); !ok.ok()) return ok.error();
    Ctx ctx{doc, options.projectDir, {}, options.pictures, {}, {}};
    assets_detail::ProjectRootGuard root(options.projectDir);
    try {
        Image sheet;
        sheet.width = plan.columns * doc.width;
        sheet.height = plan.rows * doc.height;
        sheet.rgba.assign(std::size_t(sheet.width) * sheet.height * 4, 0);
        std::map<int, Image> drawn;  // a frame appears in several cells (the extra cells of a tag): draw it once
        for (int cell = 0; cell < plan.cells; ++cell) {
            const int f = plan.cellFrame[std::size_t(cell)];
            auto it = drawn.find(f);
            if (it == drawn.end()) it = drawn.emplace(f, to_image(draw_frame(ctx, f, true))).first;
            const Image& frame = it->second;
            const int ox = (cell % plan.columns) * doc.width, oy = (cell / plan.columns) * doc.height;
            for (int y = 0; y < doc.height; ++y)
                std::copy_n(&frame.rgba[std::size_t(y) * doc.width * 4], std::size_t(doc.width) * 4, &sheet.rgba[(std::size_t(oy + y) * sheet.width + ox) * 4]);
        }
        ImageRender out;
        out.image = std::move(sheet);
        out.inputs.assign(ctx.inputs.begin(), ctx.inputs.end());
        out.warnings = unique_warnings(std::move(ctx.warnings));
        return out;
    } catch (const RenderFailure& f) {
        return make_error(f.message, f.hint);
    }
}

}  // namespace fa
