// assets.rasterize_svg: an SVG file or string to a PNG at a given size, offline, with no provider. nanosvg (external/nanosvg)
// parses the SVG and rasterizes its shapes on the CPU with anti-aliasing, so the same SVG at the same size gives the same
// pixels on every machine. It reads shapes only: paths, rects, circles, ellipses, lines, polylines, polygons, groups, solid
// and gradient fills, strokes (dashes, caps, joins), opacity and transforms. No text, filters, masks, clip paths, images,
// <use> or CSS classes: the command names every unsupported element it finds in the source.
#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <memory>

#define NANOSVG_IMPLEMENTATION
#define NANOSVGRAST_IMPLEMENTATION
#include "nanosvg.h"
#include "nanosvgrast.h"

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/asset_import.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kCommand = "assets.rasterize_svg";
constexpr int kMaxSide = 4096;

struct SvgDeleter {
    void operator()(NSVGimage* p) const { nsvgDelete(p); }
};
struct RastDeleter {
    void operator()(NSVGrasterizer* p) const { nsvgDeleteRasterizer(p); }
};

// The elements and attributes of SVG that nanosvg does not draw, found in the source text (a simple scan, good enough to warn).
std::vector<std::string> unsupported_features(const std::string& svg) {
    const std::string low = to_lower(svg);
    struct Probe {
        const char* needle;
        const char* name;
        const char* hint;
    };
    static const Probe kProbes[] = {
        {"<text", "text", "text is not drawn: convert the letters to <path>, or draw the text in the engine with a Text entity"},
        {"<tspan", "tspan", "text is not drawn: convert the letters to <path>, or draw the text in the engine with a Text entity"},
        {"<filter", "filter", "filters (blur, shadows) are not applied: draw a second, softer shape instead"},
        {" filter=", "filter", "filters (blur, shadows) are not applied: draw a second, softer shape instead"},
        {"<mask", "mask", "masks are ignored: build the shape as a path instead"},
        {"<clippath", "clipPath", "clip paths are ignored: build the clipped shape as a path instead"},
        {"<image", "image", "embedded images are not drawn"},
        {"<use", "use", "<use> references are not followed: repeat the shapes"},
        {"<pattern", "pattern", "pattern fills are not drawn"},
        {"<symbol", "symbol", "<symbol> is not drawn"},
        {"<marker", "marker", "markers are not drawn"},
        {"<foreignobject", "foreignObject", "foreignObject is not drawn"},
    };
    std::vector<std::string> out;
    for (const Probe& p : kProbes) {
        if (low.find(p.needle) == std::string::npos) continue;
        const std::string line = std::string(p.name) + ": " + p.hint + ".";
        if (std::find(out.begin(), out.end(), line) == out.end()) out.push_back(line);
    }
    return out;
}

std::string checked_png_path(const std::string& path) {
    auto norm = fs::normalize_checked(path);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", "The picture goes under assets/, and '" + path + "' is not there.", "Use a path such as \"assets/art/crest.png\".");
    if (to_lower(fs::extension(*norm)) != ".png")
        fail("invalid_argument", std::string(kCommand) + " writes PNG files, and '" + *norm + "' does not end in .png.", "Use a path such as \"assets/art/crest.png\".");
    return *norm;
}

int side_arg(const Json& a, const char* key) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return 0;
    if (!it->is_number_integer() || it->get<long long>() < 1 || it->get<long long>() > kMaxSide)
        arg_error(kCommand, std::string("/") + key, std::format("expected a whole number of pixels from 1 to {}.", kMaxSide),
                  "Leave width and height out to use the size the SVG declares.");
    return int(it->get<long long>());
}

Json rasterize_svg(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "assets.rasterize_svg expects an object.", "See the description of the command for the fields.");
    check_arg_keys(kCommand, a, "", {"path", "svg", "source", "width", "height", "background", "overwrite", "ai", "author", "license", "style", "styleStrength", "seed"});
    const std::string rel = checked_png_path(tooling_detail::arg_string(a, "path", true));
    const bool hasSvg = a.contains("svg"), hasSource = a.contains("source");
    if (hasSvg == hasSource)
        fail("invalid_argument", hasSvg ? "Give either `svg` (the SVG text) or `source` (a file), not both." : "Give `svg` (the SVG text) or `source` (an .svg file in the project).",
             "Example: {\"path\":\"assets/art/crest.png\",\"svg\":\"<svg xmlns=...>...</svg>\",\"width\":256}");
    std::string text;
    std::string sourceRel;
    if (hasSvg) {
        text = tooling_detail::arg_string(a, "svg", true);
    } else {
        auto norm = fs::normalize_checked(tooling_detail::arg_string(a, "source", true));
        if (!norm.ok() || norm->empty()) fail("invalid_argument", "'source' is not a project path.", "Use a project-relative path such as \"assets/art/crest.svg\".");
        sourceRel = *norm;
        if (to_lower(fs::extension(sourceRel)) != ".svg") fail("invalid_argument", "source '" + sourceRel + "' is not an .svg file.", "Pass SVG text in `svg` instead, or name an .svg file.");
        auto data = tooling_detail::read_file(project_file(projectDir, sourceRel));
        if (!data) fail("not_found", "Cannot read '" + sourceRel + "'.", "Check the path; it is relative to the project folder.");
        text = std::move(*data);
    }
    if (text.find("<svg") == std::string::npos)
        fail("invalid_svg", "The text has no <svg> element.", "Start with <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" width=\"100\" height=\"100\"> and put the shapes inside.");

    std::vector<std::string> warnings = unsupported_features(text);
    std::vector<char> buffer(text.begin(), text.end());  // nsvgParse edits the buffer in place
    buffer.push_back('\0');
    std::unique_ptr<NSVGimage, SvgDeleter> image(nsvgParse(buffer.data(), "px", 96.0f));
    if (!image || image->width <= 0 || image->height <= 0)
        fail("invalid_svg", "The SVG could not be read, or declares no size.",
             "Give the <svg> element a viewBox (viewBox=\"0 0 100 100\") or width and height, and write well-formed XML.");
    if (!image->shapes)
        fail("no_shapes", "The SVG has no shape this rasterizer can draw.",
             "Draw with <path>, <rect>, <circle>, <ellipse>, <line>, <polyline> or <polygon>." +
                 (warnings.empty() ? std::string() : " Found, but not supported: " + join(warnings, " ")));

    const double svgW = image->width, svgH = image->height;
    int w = side_arg(a, "width"), h = side_arg(a, "height");
    if (w == 0 && h == 0) {
        w = std::max(1, int(std::lround(svgW)));
        h = std::max(1, int(std::lround(svgH)));
        if (w > kMaxSide || h > kMaxSide) {
            const double k = double(kMaxSide) / std::max(w, h);
            w = std::max(1, int(std::lround(w * k)));
            h = std::max(1, int(std::lround(h * k)));
            warnings.push_back(std::format("The SVG declares {}x{} px; it was scaled down to {}x{}. Pass width and height to choose.", int(svgW), int(svgH), w, h));
        }
    } else if (h == 0) {
        h = std::max(1, int(std::lround(w * svgH / svgW)));
    } else if (w == 0) {
        w = std::max(1, int(std::lround(h * svgW / svgH)));
    }
    if (w > kMaxSide || h > kMaxSide) fail("invalid_argument", std::format("{}x{} is larger than {} px on a side.", w, h, kMaxSide), "Ask for a smaller picture.");
    // fit inside w x h keeping the aspect ratio, centred
    const double scale = std::min(w / svgW, h / svgH);
    const float tx = float((w - svgW * scale) * 0.5), ty = float((h - svgH * scale) * 0.5);

    std::optional<Color> background;
    if (a.contains("background") && !a["background"].is_null()) background = colour_arg(kCommand, a["background"], "/background");

    std::string style = "none";
    if (a.contains("style") && !a["style"].is_null()) {
        if (!a["style"].is_string()) arg_error(kCommand, "/style", "expected a string.", "One of: " + join(image_style_names(), ", ") + ".");
        style = to_lower(a["style"].get<std::string>());
        const auto& names = image_style_names();
        if (std::find(names.begin(), names.end(), style) == names.end())
            arg_error(kCommand, "/style", "unknown style '" + a["style"].get<std::string>() + "'.", did_you_mean(style, names) + " Styles: " + join(names, ", ") + ".");
    }
    double styleStrength = 1.0;
    if (a.contains("styleStrength") && !a["styleStrength"].is_null()) {
        if (!a["styleStrength"].is_number() || !(a["styleStrength"].get<double>() >= 0.0 && a["styleStrength"].get<double>() <= 1.0))
            arg_error(kCommand, "/styleStrength", "expected a number from 0 to 1.", "0 leaves the picture as drawn, 1 is the full effect (the default); 0.5 is subtle.");
        styleStrength = a["styleStrength"].get<double>();
    }
    const long long seedArg = tooling_detail::arg_int(a, "seed", 0);
    if (style == "none" && (a.contains("styleStrength") || a.contains("seed")))
        warnings.push_back("styleStrength and seed only matter with a `style`; they were ignored.");

    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    const stdfs::path file = project_file(projectDir, rel);
    std::error_code ec;
    if (!overwrite && stdfs::exists(file, ec)) fail("exists", "'" + rel + "' already exists.", "Pass overwrite: true to replace it, or choose another `path`.");
    require_usable_manifest(projectDir);

    std::unique_ptr<NSVGrasterizer, RastDeleter> rast(nsvgCreateRasterizer());
    Image out;
    out.width = w;
    out.height = h;
    out.rgba.assign(std::size_t(w) * h * 4, 0);
    nsvgRasterize(rast.get(), image.get(), tx, ty, float(scale), out.rgba.data(), w, h, w * 4);
    if (style != "none") apply_image_style(out, style, styleStrength, std::uint32_t(seedArg) ^ std::uint32_t(seedArg >> 32));
    if (background) {
        // composite over the background colour (straight alpha)
        const double br = background->r * 255.0, bg = background->g * 255.0, bb = background->b * 255.0, ba = background->a;
        for (std::size_t i = 0; i < out.rgba.size(); i += 4) {
            const double sa = out.rgba[i + 3] / 255.0, oa = sa + ba * (1.0 - sa);
            auto mixc = [&](double s, double b) { return oa <= 0 ? 0.0 : (s * sa + b * ba * (1.0 - sa)) / oa; };
            const double r = mixc(out.rgba[i], br), g = mixc(out.rgba[i + 1], bg), bl = mixc(out.rgba[i + 2], bb);
            out.rgba[i] = std::uint8_t(std::clamp(std::lround(r), 0L, 255L));
            out.rgba[i + 1] = std::uint8_t(std::clamp(std::lround(g), 0L, 255L));
            out.rgba[i + 2] = std::uint8_t(std::clamp(std::lround(bl), 0L, 255L));
            out.rgba[i + 3] = std::uint8_t(std::clamp(std::lround(oa * 255.0), 0L, 255L));
        }
    }
    bool anyInk = false;
    for (std::size_t i = 3; i < out.rgba.size() && !anyInk; i += 4) anyInk = out.rgba[i] != 0;
    if (!anyInk) warnings.push_back("The picture is fully transparent: the shapes are outside the viewBox, or have no fill and no stroke.");

    bool opaque = true;
    for (std::size_t i = 3; i < out.rgba.size() && opaque; i += 4) opaque = out.rgba[i] == 255;
    const std::vector<std::uint8_t> png = opaque ? encode_png_rgb(out) : encode_png(out);
    std::string err;
    if (!tooling_detail::write_file(file, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err)) fail("failed", err);

    // The agent that calls this wrote the SVG, so by default the picture counts as AI-made (Steam's disclosure); pass ai: false
    // for an SVG a person drew or a licensed one.
    const bool ai = tooling_detail::arg_bool(a, "ai", true);
    const std::string author = tooling_detail::arg_string(a, "author", false, ai ? "" : "factoria");
    const std::string license = tooling_detail::arg_string(a, "license", false, "CC0-1.0");
    Json provenance = Json::object({{"origin", ai ? "generated" : "original"},
                                    {"ai", ai},
                                    {"kind", "image"},
                                    {"provider", "factoria assets.rasterize_svg"},
                                    {"license", license},
                                    {"notes", std::format("Rasterized from SVG {} at {}x{}{}.", sourceRel.empty() ? "text given to the command" : "'" + sourceRel + "'", w, h,
                                                         style == "none" ? std::string() : std::format(" with style {} (strength {}, seed {})", style, styleStrength, seedArg))},
                                    {"date", assets::today()}});
    if (!author.empty()) provenance["author"] = author;
    if (!sourceRel.empty()) provenance["source"] = sourceRel;
    {
        ProjectRootGuard root(projectDir);
        auto r = assets::update_entry(rel, [&](Json& e) {
            e.erase("analysis");
            e.erase("sheet");
            e["provenance"] = provenance;
        });
        if (!r.ok()) fail("failed", "The picture was written, but assets.json was not updated: " + r.error().message, r.error().hint);
    }
    Json result = Json::object({{"path", rel}, {"width", w}, {"height", h}, {"svgWidth", svgW}, {"svgHeight", svgH}, {"provenance", provenance}});
    if (!warnings.empty()) result["warnings"] = warnings;
    result["$image"] = Json::object({{"path", file.string()}, {"mimeType", "image/png"}});
    result["nextSteps"] = Json::array({"Use it as a Sprite texture: Sprite.texture \"" + rel + "\". Look at the image in this result and edit the SVG if it is not right.",
                                       "Sharper at another size: call again with a larger width (the SVG is vector; nothing is lost)."});
    return result;
}

}  // namespace

void register_svg_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Turn an SVG (text or a project file) into a PNG at a given size, offline: art you write as vector shapes, no provider and no key.";
    info.description =
        "Rasterizes an SVG to a PNG at `path` (under assets/, ending in .png) with no AI provider and no key, anti-aliased, on the CPU (no GPU, so it works headless and in CI). Pass the SVG text in `svg` or an .svg file of the project in `source`. This is how an agent without an image provider draws a "
        "subject (a crest, a portrait silhouette, an ornament, a map symbol): write the shapes as SVG, rasterize, look at the picture in the "
        "result, edit the SVG, repeat. The size is `width` x `height` (the SVG is fitted inside, aspect kept, centred; give one and the other "
        "follows the SVG's proportions); leave both out for the size the SVG declares. Supported: path (all commands), rect (with rx, ry), "
        "circle, ellipse, line, polyline, polygon, g, defs, linearGradient and radialGradient fills (stops, gradientTransform, "
        "gradientUnits; write gradient coordinates in percent, x2=\"100%\", or with gradientUnits=\"userSpaceOnUse\" and real coordinates: a bare 0..1 such as x2=\"1\" is read as one pixel), fill, stroke, stroke-width, stroke-linecap, stroke-linejoin, stroke-miterlimit, stroke-dasharray, fill-rule, opacity, "
        "fill-opacity, stroke-opacity, transform, the style attribute, viewBox and preserveAspectRatio. NOT supported (drawn as nothing, and "
        "named in `warnings`): text and tspan (convert letters to paths, or draw text in the engine with a Text entity), filters (blur, drop "
        "shadow), masks, clip paths, embedded images, <use>, patterns, markers and CSS classes in <style>. For a texture of a material "
        "(wood, paper, stone) use assets.generate_texture instead. Provenance is recorded in assets.json: by default as AI-made "
        "(origin generated, ai true, because the calling agent wrote the SVG, which counts for Steam's AI disclosure); pass ai: false for an SVG "
        "a person drew or licensed, with `author` and `license`. "
        "Example: {\"path\":\"assets/art/crest.png\",\"width\":256,\"svg\":\"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>"
        "<path d='M50 6 L90 22 V52 C90 76 70 90 50 96 C30 90 10 76 10 52 V22 Z' fill='#8b1e1e' stroke='#e8c66a' stroke-width='4'/>"
        "<circle cx='50' cy='48' r='14' fill='#e8c66a'/></svg>\"}";
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"path"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"path", Json::object({{"type", "string"}, {"description", "Where to write the PNG, project-relative, under assets/ and ending in .png."}})},
               {"svg", Json::object({{"type", "string"}, {"description", "The SVG document as text, starting with <svg ...>. Give this or `source`."}})},
               {"source", Json::object({{"type", "string"}, {"description", "A project-relative .svg file, e.g. \"assets/art/crest.svg\". Give this or `svg`."}})},
               {"width", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", kMaxSide}, {"description", "Width in pixels. With only the height given, it follows the SVG's proportions. Default: the SVG's own size."}})},
               {"height", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", kMaxSide}, {"description", "Height in pixels. With only the width given, it follows the SVG's proportions."}})},
               {"background", Json::object({{"description", "A colour to put the picture over (\"#rrggbb\", \"#rrggbbaa\", a name or [r, g, b]). Default: transparent."}})},
               {"style", Json::object({{"type", "string"}, {"enum", image_style_names()}, {"description", "Default none. A painterly look added to the pixels after rasterizing (nanosvg has no filters, masks or clip paths, so the effects are applied to the picture, seeded and deterministic, and cost no SVG size). \"watercolor\": edges wobble and soften, pigment pools darker along the borders of every shape, pale and strong blotches, paper granulation. \"ink\": a wobbling pen line (dark brown, thicker and thinner) along every border. \"inkwash\": both, with a little paper tooth: storybook ink and watercolour. \"paper\": only fine paper fibres and mottling, edges untouched. Draw flat fills with a few shapes: the style supplies the texture. The effects scale with the picture's size."}})},
               {"styleStrength", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "How strong the `style` is: 0 leaves the picture as drawn, 1 (the default) is the full effect, 0.5 is subtle. Ignored without a `style`."}})},
               {"seed", Json::object({{"type", "integer"}, {"description", "Chooses the take of the `style` (where the blotches, wobble and grain fall): the same SVG, size, style and seed always give the same picture; change it for another take. Ignored without a `style`."}})},
               {"overwrite", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Replace the file when it already exists."}})},
               {"ai", Json::object({{"type", "boolean"}, {"default", true}, {"description", "Whether the SVG was written by an AI (the default, since the caller is an agent). Set false for an SVG a person drew or a licensed one; it then counts as original work in the AI disclosure."}})},
               {"author", Json::object({{"type", "string"}, {"description", "Who gets the credit in the provenance record."}})},
               {"license", Json::object({{"type", "string"}, {"default", "CC0-1.0"}, {"description", "License of the picture for the provenance record."}})}})}});
    registry.add(info, [projectDir](const Json& args) { return rasterize_svg(projectDir, args); });
}

}  // namespace fa::assets_detail
