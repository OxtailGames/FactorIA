// The vector.* commands (docs/VECTOR.md): vector.boolean, offset, stroke_to_path, simplify, smooth, align, distribute, repeat, style
// and info. Each reads an SVG (a project file, text, or an svg layer of an image document), runs one operation from vector_ops.h,
// writes the SVG back and returns a rasterized preview as `$image`.
#include <algorithm>
#include <cmath>
#include <format>
#include <functional>
#include <set>

#include "assets_internal.h"
#include "assets_shots.h"
#include "fa/core/strings.h"
#include "fa/tooling/style_guide.h"
#include "image_edit.h"
#include "util.h"
#include "fa/tooling/image_doc.h"
#include "vector_ops.h"

namespace fa::vec {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using assets_detail::fail;
using tooling_detail::arg_bool;
namespace tooling_detail_ = fa::tooling_detail;

namespace {

namespace stdfs = std::filesystem;

struct Ctx {
    const char* cmd;
    std::string projectDir;
    const Json& a;
    SvgDoc& doc;
    std::vector<std::string>& warnings;
};
using Body = std::function<Json(Ctx&)>;

// ---- arguments ---------------------------------------------------------------------------------------------------------

double num_arg(const Json& a, const char* cmd, const char* key, double lo, double hi, double def, const char* hint = "") {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number() || !std::isfinite(it->get<double>()) || it->get<double>() < lo || it->get<double>() > hi)
        arg_error(cmd, std::string("/") + key, std::format("`{}` must be a number from {} to {}, got {}.", key, lo, hi, describe_json_value(*it)), hint);
    return it->get<double>();
}

int int_arg(const Json& a, const char* cmd, const char* key, int lo, int hi, int def) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi)
        arg_error(cmd, std::string("/") + key, std::format("`{}` must be a whole number from {} to {}, got {}.", key, lo, hi, describe_json_value(*it)), "");
    return int(it->get<long long>());
}

std::string enum_arg(const Json& a, const char* cmd, const char* key, const std::vector<std::string>& names, const std::string& def, bool required = false) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) {
        if (required) {
            std::string list;
            for (const std::string& n : names) list += (list.empty() ? "" : ", ") + n;
            arg_error(cmd, std::string("/") + key, std::format("`{}` is required.", key), "One of: " + list + ".");
        }
        return def;
    }
    if (!it->is_string() || std::find(names.begin(), names.end(), it->get<std::string>()) == names.end()) {
        std::string list;
        for (const std::string& n : names) list += (list.empty() ? "" : ", ") + n;
        arg_error(cmd, std::string("/") + key, std::format("`{}` must be one of {}, got {}.", key, list, describe_json_value(*it)),
                  it->is_string() ? did_you_mean(it->get<std::string>(), names) : "");
    }
    return it->get<std::string>();
}

// `elements`: one id or selector, or a list of them. Duplicates are dropped, the order of the list is kept.
std::vector<XNode*> pick(Ctx& c, const char* key, bool required) {
    std::vector<XNode*> out;
    auto it = c.a.find(key);
    if (it == c.a.end() || it->is_null()) {
        if (required)
            arg_error(c.cmd, std::string("/") + key, std::format("`{}` is required: the SVG ids or selectors to work on.", key),
                      "Example: {\"" + std::string(key) + "\": [\"outer\", \"hole\"]}. Run vector.info to list the ids.");
        return out;
    }
    std::vector<std::string> refs;
    if (it->is_string()) refs.push_back(it->get<std::string>());
    else if (it->is_array()) {
        for (const Json& e : *it) {
            if (!e.is_string()) arg_error(c.cmd, std::string("/") + key, "every entry must be a string (an SVG id or a selector), got " + describe_json_value(e) + ".", "Example: [\"outer\", \"hole\"].");
            refs.push_back(e.get<std::string>());
        }
    } else {
        arg_error(c.cmd, std::string("/") + key, "expected an SVG id, a selector, or a list of them, got " + describe_json_value(*it) + ".", "Example: [\"outer\", \"hole\"].");
    }
    if (refs.empty() && required) arg_error(c.cmd, std::string("/") + key, "the list is empty.", "Give at least one id or selector.");
    std::set<XNode*> seen;
    for (std::size_t i = 0; i < refs.size(); ++i)
        for (XNode* n : select_elements(c.doc, refs[i], c.cmd, it->is_array() ? std::format("/{}/{}", key, i) : std::string("/") + key))
            if (seen.insert(n).second) out.push_back(n);
    return out;
}

// The shapes of the whole drawing when `elements` is left out.
std::vector<XNode*> pick_or_all(Ctx& c) {
    std::vector<XNode*> out = pick(c, "elements", false);
    if (out.empty()) out.push_back(c.doc.root());
    return out;
}

Settings settings_of(Ctx& c, double divisor) {
    const Rect canvas = c.doc.canvas();
    Settings s = default_settings(canvas);
    const double side = std::max({canvas.width(), canvas.height(), 1.0});
    const double dflt = side / divisor;
    s = with_tolerance(s, num_arg(c.a, c.cmd, "tolerance", side * 1e-6, side, dflt, "The largest distance, in drawing units (viewBox units), the result may be from the exact outline."));
    s.curves = arg_bool(c.a, "curves", true);
    s.cornerAngle = num_arg(c.a, c.cmd, "cornerAngle", 1, 89, 28, "Degrees of direction change above which a vertex stays a sharp corner (1 to 89).");
    return s;
}

Join join_of(const std::string& s) { return s == "round" ? Join::Round : s == "bevel" ? Join::Bevel : s == "square" ? Join::Square : Join::Miter; }

// ---- schema pieces -----------------------------------------------------------------------------------------------------

Json str_prop(const char* desc) { return Json::object({{"type", "string"}, {"description", desc}}); }
Json num_prop(const char* desc) { return Json::object({{"type", "number"}, {"description", desc}}); }
Json bool_prop(const char* desc, bool def) { return Json::object({{"type", "boolean"}, {"default", def}, {"description", desc}}); }
Json refs_prop(const char* desc) {
    return Json::object({{"description", desc}, {"oneOf", Json::array({Json::object({{"type", "string"}}), Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})}})})}});
}
Json enum_prop(const std::vector<std::string>& names, const char* desc) { return Json::object({{"type", "string"}, {"enum", names}, {"description", desc}}); }

Json common_props() {
    return Json::object(
        {{"source", str_prop("A project-relative .svg file to edit (e.g. \"assets/art/crest.svg\"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`.")},
         {"svg", str_prop("The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`.")},
         {"document", str_prop("A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does.")},
         {"layer", Json::object({{"description", "With `document`: the svg layer to edit, by name or index path (\"1\", \"1/0\"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file."},
                                 {"oneOf", Json::array({Json::object({{"type", "string"}}), Json::object({{"type", "integer"}})})}})},
         {"out", str_prop("Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true.")},
         {"overwrite", bool_prop("Replace `out` when it already exists.", false)},
         {"dryRun", bool_prop("Compute and preview the result without writing anything.", false)},
         {"previewSize", Json::object({{"type", "integer"}, {"minimum", 32}, {"maximum", 2048}, {"default", 512}, {"description", "The longer side of the preview picture returned as `$image`, in pixels."}})},
         {"bake", bool_prop("With `document`: also bake the document's PNG (like image.layer.set).", true)}});
}

Json geometry_props() {
    return Json::object(
        {{"tolerance", num_prop("The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify).")},
         {"curves", bool_prop("Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed.", true)},
         {"cornerAngle", num_prop("Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28.")}});
}

Json merge_props(Json a, const Json& b) {
    for (auto it = b.begin(); it != b.end(); ++it) a[it.key()] = it.value();
    return a;
}

std::vector<std::string> allowed_keys(const Json& props) {
    std::vector<std::string> keys;
    for (auto it = props.begin(); it != props.end(); ++it) keys.push_back(it.key());
    return keys;
}

// ---- input and output ----------------------------------------------------------------------------------------------------

std::string svg_path_arg(const std::string& projectDir, const std::string& value, const char* cmd, const char* key, stdfs::path& abs) {
    std::string rel = value;
    std::replace(rel.begin(), rel.end(), '\\', '/');
    while (rel.rfind("./", 0) == 0) rel = rel.substr(2);
    if (rel.size() < 5 || to_lower(rel.substr(rel.size() - 4)) != ".svg")
        arg_error(cmd, std::string("/") + key, std::format("'{}' is not an .svg file.", value), "Give a project-relative path that ends in .svg, e.g. \"assets/art/crest.svg\".");
    abs = assets_detail::project_file(projectDir, rel);
    return rel;
}

std::vector<std::string> svg_layer_paths(const Json& layers, std::vector<int>& path) {
    std::vector<std::string> out;
    if (!layers.is_array()) return out;
    for (std::size_t i = 0; i < layers.size(); ++i) {
        path.push_back(int(i));
        const Json& l = layers[i];
        if (l.is_object() && l.value("kind", std::string()) == "svg") out.push_back(imgedit::index_path_string(path));
        if (l.is_object() && l.contains("layers")) {
            auto sub = svg_layer_paths(l["layers"], path);
            out.insert(out.end(), sub.begin(), sub.end());
        }
        path.pop_back();
    }
    return out;
}

Json run(const std::string& projectDir, const Json& a, const char* cmd, const Json& props, bool readOnly, const Body& body) {
    check_arg_keys(cmd, a, "", allowed_keys(props));
    const int given = int(a.contains("source")) + int(a.contains("svg")) + int(a.contains("document"));
    if (given != 1)
        arg_error(cmd, given == 0 ? "/source" : "", given == 0 ? "no SVG was given." : "more than one of `source`, `svg` and `document` was given.",
                  "Give exactly one: {\"source\": \"assets/art/crest.svg\"}, {\"svg\": \"<svg ...>\"} or {\"document\": \"assets/art/hero.image.json\", \"layer\": \"crest\"}.");
    for (const char* k : {"source", "svg", "document", "out"})
        if (a.contains(k) && !a[k].is_string()) arg_error(cmd, std::string("/") + k, "expected a string, got " + describe_json_value(a[k]) + ".", "");
    const bool dryRun = arg_bool(a, "dryRun", false);
    const int previewSize = int_arg(a, cmd, "previewSize", 32, 2048, 512);
    const bool isDoc = a.contains("document");
    if (isDoc && a.contains("out")) arg_error(cmd, "/out", "`out` cannot be used with `document`: the layer is edited inside the document.", "Leave `out` out, or use `source` to edit a .svg file.");
    if (!isDoc && a.contains("layer")) arg_error(cmd, "/layer", "`layer` only goes with `document`.", "Leave `layer` out, or pass `document`.");

    // read
    std::string text, rel, what;
    stdfs::path srcAbs;
    imgedit::DocFile docFile;
    imgedit::LayerRef layerRef;
    bool layerInline = false;
    std::string layerSourceRel;
    stdfs::path layerSourceAbs;
    std::optional<Image> before;
    if (a.contains("source")) {
        rel = svg_path_arg(projectDir, a["source"].get<std::string>(), cmd, "source", srcAbs);
        auto t = tooling_detail::read_file(srcAbs);
        if (!t) fail("not_found", std::format("{} /source: '{}' does not exist or cannot be read.", cmd, rel), "Check the path (project-relative), or pass the SVG text in `svg`.");
        text = *t;
        what = rel;
    } else if (a.contains("svg")) {
        text = a["svg"].get<std::string>();
        what = "the `svg` argument";
    } else {
        docFile = imgedit::open_doc(projectDir, a["document"].get<std::string>(), cmd);
        rel = docFile.rel;
        Json ref;
        if (a.contains("layer") && !a["layer"].is_null()) ref = a["layer"];
        else {
            std::vector<int> path;
            const std::vector<std::string> svgLayers = svg_layer_paths(docFile.json["layers"], path);
            if (svgLayers.size() != 1)
                arg_error(cmd, "/layer", svgLayers.empty() ? std::format("'{}' has no svg layer.", rel) : std::format("'{}' has {} svg layers, so `layer` must say which.", rel, svgLayers.size()),
                          svgLayers.empty() ? "Add one with image.layer.add {\"kind\": \"svg\", \"svg\": \"<svg ...>\"}. Layers: " + imgedit::describe_layers(docFile.json) : "Svg layers: " + [&] {
                              std::string s;
                              for (const auto& p : svgLayers) s += (s.empty() ? "" : ", ") + p;
                              return s;
                          }() + ".");
            ref = svgLayers[0];
        }
        layerRef = imgedit::find_layer(docFile.json, ref, cmd, "layer");
        if (layerRef.layer->value("kind", std::string()) != "svg")
            arg_error(cmd, "/layer", std::format("layer {} is a {} layer, not an svg layer.", layerRef.indexPath, layerRef.layer->value("kind", std::string())),
                      "Pick an svg layer. Layers: " + imgedit::describe_layers(docFile.json));
        layerInline = layerRef.layer->contains("svg");
        if (layerInline) text = (*layerRef.layer)["svg"].get<std::string>();
        else {
            layerSourceRel = (*layerRef.layer)["source"].get<std::string>();
            layerSourceAbs = assets_detail::project_file(projectDir, layerSourceRel);
            auto t = tooling_detail::read_file(layerSourceAbs);
            if (!t) fail("not_found", std::format("{} /document: the svg layer's source '{}' does not exist.", cmd, layerSourceRel), "Fix the layer's `source` with image.layer.set.");
            text = *t;
        }
        what = layerInline ? std::format("{} layer {}", rel, layerRef.indexPath) : layerSourceRel;
        before = imgedit::render_document_json(projectDir, docFile.json);
    }

    SvgDoc doc = SvgDoc::parse(text, what);
    std::vector<std::string> warnings = document_warnings(doc);
    Ctx ctx{cmd, projectDir, a, doc, warnings};
    Json result = body(ctx);
    if (!result.is_object()) result = Json::object();

    const std::string newText = doc.write();
    const bool changed = newText != text;
    if (!readOnly) result["changed"] = changed;

    // write
    stdfs::path outAbs;
    std::string outRel;
    if (a.contains("out")) {
        outRel = svg_path_arg(projectDir, a["out"].get<std::string>(), cmd, "out", outAbs);
        std::error_code ec;
        if (!dryRun && !arg_bool(a, "overwrite", false) && stdfs::exists(outAbs, ec))
            fail("exists", std::format("'{}' already exists.", outRel), "Pass overwrite: true to replace it, or choose another `out`.");
    }
    auto write_svg = [&](const stdfs::path& abs, const std::string& relPath) {
        std::string err;
        if (!tooling_detail::write_file(abs, newText, &err)) fail("failed", err);
        result["written"] = relPath;
    };
    Json extra = Json::object();
    if (isDoc) {
        if (!readOnly && changed && !dryRun) {
            if (layerInline) (*layerRef.layer)["svg"] = newText;
            else write_svg(layerSourceAbs, layerSourceRel);
        }
        result["document"] = rel;
        result["layer"] = layerRef.indexPath;
    } else {
        if (!readOnly && !dryRun) {
            if (!outRel.empty()) write_svg(outAbs, outRel);
            else if (a.contains("source") && changed) write_svg(srcAbs, rel);
        }
        if (a.contains("source")) result["path"] = rel;
        if (!readOnly && (a.contains("svg") || (dryRun && a.contains("source")))) result["svg"] = newText;
    }
    if (dryRun) result["dryRun"] = true;

    // the picture
    auto preview = [&]() -> std::optional<Json> {
        try {
            const Rect c = doc.canvas();
            const bool wide = c.width() >= c.height();
            std::vector<std::string> renderWarnings;
            assets_detail::SvgRaster raster = assets_detail::rasterize_svg_text(newText, wide ? previewSize : 0, wide ? 0 : previewSize, "none", 0.0, 0, renderWarnings);
            for (const std::string& w : renderWarnings)
                if (std::find(warnings.begin(), warnings.end(), w) == warnings.end()) warnings.push_back(w);
            return assets_detail::image_member(assets_detail::write_temporary_picture(projectDir, raster.image, "vector"), true);
        } catch (const CommandError& e) {
            warnings.push_back(std::string("The preview could not be drawn: ") + e.what());
            return std::nullopt;
        }
    };
    if (isDoc && !readOnly && !dryRun && changed) {
        result["svgBytes"] = int(newText.size());
        extra = result;
        Json out = imgedit::commit_document(projectDir, rel, docFile.json, before, arg_bool(a, "bake", true), extra, warnings, cmd);
        return out;
    }
    if (isDoc && dryRun && changed) {
        Json tmp = docFile.json;
        // the layer lives in `tmp` by pointer into docFile.json; render the changed copy
        if (layerInline) (*layerRef.layer)["svg"] = newText;
        std::optional<Image> after = imgedit::render_document_json(projectDir, docFile.json);
        if (after) result["$image"] = assets_detail::image_member(assets_detail::write_temporary_picture(projectDir, *after, "vector"), true);
        (void)tmp;
    } else if (!isDoc || !changed) {
        if (auto p = preview()) result["$image"] = *p;
    }
    if (!warnings.empty()) result["warnings"] = warnings;
    return result;
}

Json info_with_next(Json r, std::initializer_list<std::string> next) {
    r["nextSteps"] = std::vector<std::string>(next);
    return r;
}

// ---- the commands ----------------------------------------------------------------------------------------------------------

Json cmd_boolean(Ctx& c) {
    const BoolOp op = [&] {
        const std::string s = enum_arg(c.a, c.cmd, "op", {"union", "subtract", "intersect", "exclude"}, "", true);
        return s == "union" ? BoolOp::Union : s == "subtract" ? BoolOp::Subtract : s == "intersect" ? BoolOp::Intersect : BoolOp::Xor;
    }();
    const Settings s = settings_of(c, 4000);
    Json r = op_boolean(c.doc, op, pick(c, "elements", true), s, arg_bool(c.a, "keepInputs", false), c.warnings);
    return info_with_next(r, {"Look at the preview. vector.simplify reduces the nodes of the result; vector.offset grows or shrinks it."});
}

Json cmd_offset(Ctx& c) {
    const std::vector<XNode*> els = pick(c, "elements", true);
    auto it = c.a.find("distance");
    if (it == c.a.end() || !it->is_number() || !std::isfinite(it->get<double>()) || it->get<double>() == 0)
        arg_error(c.cmd, "/distance", "`distance` is required and must be a number other than 0 (positive grows, negative insets).", "Example: {\"distance\": -4} insets the shape by 4 units.");
    const std::string join = enum_arg(c.a, c.cmd, "join", {"round", "miter", "bevel", "square"}, "round");
    const double miter = num_arg(c.a, c.cmd, "miterLimit", 1, 100, 4, "The longest miter, as a multiple of the offset distance, before the corner is squared off (like SVG's stroke-miterlimit).");
    const Settings s = settings_of(c, 4000);
    return op_offset(c.doc, els, it->get<double>(), join_of(join), miter, arg_bool(c.a, "copy", false), s, c.warnings);
}

Json cmd_stroke(Ctx& c) {
    const std::vector<XNode*> els = pick(c, "elements", true);
    StrokeOverrides ov;
    if (c.a.contains("width")) ov.width = num_arg(c.a, c.cmd, "width", 1e-6, 1e6, 1, "A stroke width in the shape's own units, above 0.");
    if (c.a.contains("cap")) {
        const std::string v = enum_arg(c.a, c.cmd, "cap", {"butt", "round", "square"}, "butt");
        ov.cap = v == "round" ? Cap::Round : v == "square" ? Cap::Square : Cap::Butt;
    }
    if (c.a.contains("join")) ov.join = join_of(enum_arg(c.a, c.cmd, "join", {"miter", "round", "bevel"}, "miter"));
    if (c.a.contains("miterLimit")) ov.miterLimit = num_arg(c.a, c.cmd, "miterLimit", 1, 100, 4);
    if (c.a.contains("dashOffset")) ov.dashOffset = num_arg(c.a, c.cmd, "dashOffset", -1e6, 1e6, 0);
    if (c.a.contains("dashes")) {
        const Json& d = c.a["dashes"];
        if (!d.is_array()) arg_error(c.cmd, "/dashes", "expected a list of lengths, got " + describe_json_value(d) + ".", "Example: [6, 4] draws 6 units, skips 4. [] makes the stroke solid.");
        std::vector<double> v;
        for (std::size_t i = 0; i < d.size(); ++i) {
            if (!d[i].is_number() || d[i].get<double>() < 0)
                arg_error(c.cmd, std::format("/dashes/{}", i), "every length must be a number of 0 or more, got " + describe_json_value(d[i]) + ".", "Example: [6, 4].");
            v.push_back(d[i].get<double>());
        }
        ov.dashes = v;
    }
    if (c.a.contains("color")) {
        if (!c.a["color"].is_string()) arg_error(c.cmd, "/color", "expected a CSS colour string, got " + describe_json_value(c.a["color"]) + ".", "Example: \"#203040\".");
        ov.paint = c.a["color"].get<std::string>();
    }
    const Settings s = settings_of(c, 4000);
    return op_stroke_to_path(c.doc, els, ov, s, c.warnings);
}

Json cmd_simplify(Ctx& c) { return op_simplify(c.doc, pick_or_all(c), settings_of(c, 500), c.warnings); }

Json cmd_smooth(Ctx& c) {
    const double sm = num_arg(c.a, c.cmd, "smoothness", 0, 1, 1, "0 leaves the segments straight, 1 is the usual round curve through the nodes.");
    return op_smooth(c.doc, pick_or_all(c), sm, settings_of(c, 4000), c.warnings);
}

Json cmd_align(Ctx& c) {
    const std::vector<XNode*> els = pick(c, "elements", true);
    AlignArgs a;
    a.horizontal = enum_arg(c.a, c.cmd, "horizontal", {"left", "center", "right"}, "");
    a.vertical = enum_arg(c.a, c.cmd, "vertical", {"top", "middle", "bottom"}, "");
    a.to = enum_arg(c.a, c.cmd, "to", {"selection", "canvas", "key"}, els.size() >= 2 ? "selection" : "canvas");
    a.visual = enum_arg(c.a, c.cmd, "bounds", {"visual", "geometry"}, "visual") == "visual";
    if (c.a.contains("key")) {
        if (!c.a["key"].is_string()) arg_error(c.cmd, "/key", "expected an SVG id or a selector, got " + describe_json_value(c.a["key"]) + ".", "");
        const std::vector<XNode*> k = select_elements(c.doc, c.a["key"].get<std::string>(), c.cmd, "/key");
        if (k.size() != 1) arg_error(c.cmd, "/key", std::format("`key` matches {} elements; it must be exactly one.", k.size()), "Use an id: the element the others align to.");
        a.key = k[0];
        if (!c.a.contains("to")) a.to = "key";
    }
    return op_align(c.doc, els, a, c.warnings);
}

Json cmd_distribute(Ctx& c) {
    const std::vector<XNode*> els = pick(c, "elements", true);
    DistributeArgs a;
    a.axis = enum_arg(c.a, c.cmd, "axis", {"horizontal", "vertical"}, "", true) == "horizontal" ? Axis::Horizontal : Axis::Vertical;
    a.by = enum_arg(c.a, c.cmd, "by", {"gaps", "centers"}, "gaps");
    a.visual = enum_arg(c.a, c.cmd, "bounds", {"visual", "geometry"}, "visual") == "visual";
    if (c.a.contains("spacing")) {
        a.spacing = num_arg(c.a, c.cmd, "spacing", -1e6, 1e6, 0, "The gap between neighbouring elements, in drawing units.");
        if (c.a.contains("by")) c.warnings.push_back("`by` is ignored when `spacing` is given.");
    }
    return op_distribute(c.doc, els, a, c.warnings);
}

Json cmd_repeat(Ctx& c) {
    const std::vector<XNode*> els = pick(c, "element", true);
    if (els.size() != 1) arg_error(c.cmd, "/element", std::format("`element` matches {} elements; repeat needs exactly one.", els.size()), "Group the shapes in a <g id=\"...\"> and repeat the group, or use an id.");
    RepeatArgs a;
    a.mode = enum_arg(c.a, c.cmd, "mode", {"grid", "radial"}, "", true);
    a.visual = enum_arg(c.a, c.cmd, "bounds", {"visual", "geometry"}, "visual") == "visual";
    a.rotation = num_arg(c.a, c.cmd, "rotation", -3600, 3600, 0, "Degrees each copy turns more than the one before, about its own centre.");
    auto ignored = [&](std::initializer_list<const char*> keys) {
        for (const char* k : keys)
            if (c.a.contains(k)) c.warnings.push_back(std::format("`{}` is ignored in {} mode.", k, a.mode));
    };
    if (a.mode == "grid") {
        ignored({"count", "center", "radius", "sweep"});
        if (c.a.contains("orient") && !arg_bool(c.a, "orient", true)) c.warnings.push_back("`orient` is ignored in grid mode.");
        a.columns = int_arg(c.a, c.cmd, "columns", 1, 500, 1);
        a.rows = int_arg(c.a, c.cmd, "rows", 1, 500, 1);
        if (a.columns * a.rows > 2000) arg_error(c.cmd, "/columns", std::format("{} x {} is {} copies; the limit is 2000.", a.columns, a.rows, a.columns * a.rows), "Use fewer columns or rows.");
        if (a.columns * a.rows == 1) arg_error(c.cmd, "/columns", "`columns` x `rows` is 1, so nothing would be repeated.", "Set columns and/or rows above 1.");
        if (c.a.contains("spacing")) {
            const Json& sp = c.a["spacing"];
            if (sp.is_number()) a.gapX = a.gapY = sp.get<double>();
            else if (sp.is_array() && sp.size() == 2 && sp[0].is_number() && sp[1].is_number()) {
                a.gapX = sp[0].get<double>();
                a.gapY = sp[1].get<double>();
            } else {
                arg_error(c.cmd, "/spacing", "expected a number or [x, y], got " + describe_json_value(sp) + ".", "The gap between neighbouring copies' bounds, e.g. 8 or [8, 4].");
            }
        }
    } else {
        ignored({"columns", "rows", "spacing"});
        a.count = int_arg(c.a, c.cmd, "count", 2, 1000, 0);
        if (a.count == 0) arg_error(c.cmd, "/count", "`count` is required in radial mode: the number of copies including the original.", "Example: {\"mode\": \"radial\", \"count\": 8, \"radius\": 30}.");
        a.sweep = num_arg(c.a, c.cmd, "sweep", 1, 360, 360, "The angle the copies cover, in degrees (360 = a full circle).");
        a.orient = arg_bool(c.a, "orient", true);
        if (c.a.contains("center")) {
            const Json& ce = c.a["center"];
            if (!ce.is_array() || ce.size() != 2 || !ce[0].is_number() || !ce[1].is_number()) arg_error(c.cmd, "/center", "expected [x, y], got " + describe_json_value(ce) + ".", "The point the copies turn around, in drawing units, e.g. [50, 50].");
            a.center = P{ce[0].get<double>(), ce[1].get<double>()};
        }
        if (c.a.contains("radius")) a.radius = num_arg(c.a, c.cmd, "radius", 1e-6, 1e6, 1);
        if (a.center && a.radius) c.warnings.push_back("`radius` is ignored because `center` is given.");
    }
    Json r = op_repeat(c.doc, *els[0], a, c.warnings);
    return r;
}

Json cmd_style(Ctx& c) {
    const std::vector<XNode*> els = pick(c, "elements", false);
    assets_detail::ProjectRootGuard rootGuard(c.projectDir);
    const StyleParse guide = load_style_guide();
    for (const StyleProblem& p : guide.problems) c.warnings.push_back(std::format("assets.json {}: {}", p.pointer, p.message));
    StyleArgs a;
    // A key left out is on, unless the other one was asked for ({"outline": true} alone is only the outline; {"outline": false}
    // alone is everything but the outline).
    auto asked = [&](const char* key) { return c.a.contains(key) && !(c.a[key].is_boolean() && !c.a[key].get<bool>()); };
    auto want = [&](const char* key) { return c.a.contains(key) ? c.a[key] : Json(!asked(std::string_view(key) == "outline" ? "palette" : "outline")); };
    // outline
    const Json outline = want("outline");
    if (outline.is_object() || (outline.is_boolean() && outline.get<bool>())) {
        double width = 0;
        std::string colour;
        if (guide.guide.outline) {
            width = guide.guide.outline->width;
            const Color& k = guide.guide.outline->color;
            colour = std::format("#{:02x}{:02x}{:02x}", int(std::lround(k.r * 255)), int(std::lround(k.g * 255)), int(std::lround(k.b * 255)));
        }
        if (outline.is_object()) {
            check_arg_keys(c.cmd, outline, "/outline", {"width", "color"});
            if (outline.contains("width")) width = num_arg(outline, c.cmd, "width", 0.001, 1000, 1, "Pixels of the SVG's declared size.");
            if (outline.contains("color")) {
                std::array<std::uint8_t, 3> rgb{};
                double al = 1;
                if (!outline["color"].is_string() || !parse_css_colour(outline["color"].get<std::string>(), rgb, al))
                    arg_error(c.cmd, "/outline/color", "expected a CSS colour such as \"#101018\", got " + describe_json_value(outline["color"]) + ".", "");
                colour = outline["color"].get<std::string>();
            }
        }
        if (width <= 0 || colour.empty()) {
            if (c.a.contains("outline"))
                arg_error(c.cmd, "/outline", "the project's style guide has no `outline` (assets.json style.outline) and none was given here.",
                          "Add \"style\": {\"outline\": {\"color\": \"#101018\", \"width\": 2}} to assets.json, or pass {\"outline\": {\"width\": 2, \"color\": \"#101018\"}}.");
        } else {
            a.outlineWidth = width;
            a.outlineColour = colour;
        }
    } else if (!outline.is_boolean()) {
        arg_error(c.cmd, "/outline", "expected true, false or {\"width\", \"color\"}, got " + describe_json_value(outline) + ".", "");
    }
    // palette
    const Json palette = want("palette");
    if (palette.is_array()) {
        std::vector<std::array<std::uint8_t, 3>> pal;
        for (std::size_t i = 0; i < palette.size(); ++i) {
            std::array<std::uint8_t, 3> rgb{};
            double al = 1;
            if (!palette[i].is_string() || !parse_css_colour(palette[i].get<std::string>(), rgb, al))
                arg_error(c.cmd, std::format("/palette/{}", i), "expected a colour such as \"#101018\", got " + describe_json_value(palette[i]) + ".", "");
            pal.push_back(rgb);
        }
        if (pal.empty()) arg_error(c.cmd, "/palette", "the palette is empty.", "List at least one colour.");
        a.palette = pal;
    } else if (palette.is_boolean() && palette.get<bool>()) {
        if (guide.guide.palette && !guide.guide.palette->empty()) a.palette = *guide.guide.palette;
        else if (c.a.contains("palette"))
            arg_error(c.cmd, "/palette", "the project's style guide has no `palette` (assets.json style.palette) and none was given here.",
                      "Add \"style\": {\"palette\": [\"#101018\", \"#e8e0d0\"]} to assets.json, or pass the colours: {\"palette\": [\"#101018\", \"#e8e0d0\"]}.");
    } else if (!palette.is_boolean()) {
        arg_error(c.cmd, "/palette", "expected true, false or a list of colours, got " + describe_json_value(palette) + ".", "");
    }
    if (!a.outlineWidth && !a.palette)
        fail("invalid_argument", std::format("{}: there is nothing to apply: the project's style guide has no outline and no palette.", c.cmd),
             "Add a `style` section to assets.json (docs.read ASSETS, \"House style\"), or pass `outline` and/or `palette` here.");
    Json r = op_style(c.doc, els, els.empty(), a, c.warnings);
    r["guide"] = Json::object({{"outline", a.outlineWidth.has_value()}, {"palette", a.palette.has_value() ? int(a.palette->size()) : 0}});
    return r;
}

Json cmd_info(Ctx& c) {
    const std::vector<XNode*> els = pick(c, "elements", false);
    return op_info(c.doc, els, c.warnings);
}

}  // namespace

}  // namespace fa::vec

namespace fa::assets_detail {

void register_vector_commands(CommandRegistry& registry, const std::string& projectDir) {
    using namespace fa::vec;
    struct Def {
        const char* name;
        const char* summary;
        std::string description;
        Json props;
        std::vector<std::string> required;
        bool readOnly;
        Json (*fn)(Ctx&);
    };
    const Json common = common_props();
    const Json elementsRequired = Json::object({{"elements", refs_prop("The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Selectors: #id, .class, tag, [attr=value], g > path, path:first-child, :nth-child(2), lists with commas.")}});
    const Json elementsOptional = Json::object({{"elements", refs_prop("The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Default: every shape in the drawing.")}});
    const Json units = Json::object({{"elements", refs_prop("The elements to move: SVG ids or selectors. A group moves as one piece (it is measured as the union of its shapes). Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas.")},
                                     {"bounds", enum_prop({"visual", "geometry"}, "What is measured: \"visual\" (default) includes half the stroke width, \"geometry\" only the outline of the shapes.")}});

    std::vector<Def> defs;
    defs.push_back({"vector.boolean", "Union, subtract, intersect or exclude SVG shapes into one path.",
        "Combines the picked shapes with a path boolean (Clipper2, integer-exact) and writes the result as ONE <path> whose curves are cubic Beziers again (the polygon the operation computes is refitted). "
        "The first shape keeps its id, style, transform and place in the drawing and takes the new outline; the others are removed (keepInputs: true keeps them). "
        "`union` merges all; `subtract` removes the later shapes from the first; `intersect` keeps what all cover; `exclude` keeps what an odd number of them cover. "
        "Transforms of the shapes and their groups are honoured: each shape is measured in the drawing space and the result is written back in the first shape's own space. fill-rule is read per shape. "
        "Returns a rasterized preview as `$image`. Example: {\"source\": \"assets/art/badge.svg\", \"op\": \"subtract\", \"elements\": [\"disc\", \"hole\"]}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, merge_props(elementsRequired, geometry_props())),
                    Json::object({{"op", enum_prop({"union", "subtract", "intersect", "exclude"}, "The path operation.")},
                                  {"keepInputs", bool_prop("Keep the other shapes instead of removing them (the result still goes into the first).", false)}})),
        {"op", "elements"}, false, cmd_boolean});
    defs.push_back({"vector.offset", "Grow or shrink SVG shapes by a distance (offset path, inset).",
        "Offsets the outline of each picked shape by `distance` drawing units (positive grows, negative insets) with round, miter, bevel or square corners, and writes it back as a <path> (curves refitted as Beziers). "
        "Each shape keeps its id, style and transform; copy: true leaves the original and adds the offset shape after it (id <id>-offset). Holes grow the opposite way, as in any offset. "
        "Distances are in the drawing space (viewBox units), whatever the shape's transform. Returns a preview as `$image`. "
        "Example: {\"source\": \"assets/art/badge.svg\", \"elements\": [\"disc\"], \"distance\": -3, \"join\": \"round\", \"copy\": true}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, merge_props(elementsRequired, geometry_props())),
                    Json::object({{"distance", num_prop("How far to move the outline, in drawing units. Positive grows the shape, negative shrinks it. Not 0.")},
                                  {"join", enum_prop({"round", "miter", "bevel", "square"}, "The corner shape of a grown outline: round (default), miter (sharp, up to miterLimit), bevel (cut) or square.")},
                                  {"miterLimit", num_prop("With join \"miter\": the longest miter, as a multiple of the distance, before the corner is squared off. Default 4.")},
                                  {"copy", bool_prop("Add the offset shape after the original instead of replacing it.", false)}})),
        {"elements", "distance"}, false, cmd_offset});
    defs.push_back({"vector.stroke_to_path", "Turn the stroke of SVG shapes into a filled outline path.",
        "Converts the stroke of each picked shape (its stroke-width, linecap, linejoin, miterlimit, dasharray and dashoffset, read with inheritance, or the overrides given here) into a filled <path> outline, with SVG's own cap, join and dash rules. "
        "A shape with no fill becomes the outline (fill = its stroke colour, stroke none). A filled shape keeps its fill and id, and the outline is added after it with the id <id>-stroke. "
        "Stroke widths are in the shape's own space, so a scaled shape keeps its look. Returns a preview as `$image`. "
        "Example: {\"source\": \"assets/art/logo.svg\", \"elements\": [\"swoosh\"], \"cap\": \"round\"}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, merge_props(elementsRequired, geometry_props())),
                    Json::object({{"width", num_prop("Stroke width to use instead of the shape's stroke-width, in the shape's own units.")},
                                  {"cap", enum_prop({"butt", "round", "square"}, "Line caps of open paths. Default: the shape's stroke-linecap.")},
                                  {"join", enum_prop({"miter", "round", "bevel"}, "Corner joins. Default: the shape's stroke-linejoin.")},
                                  {"miterLimit", num_prop("Miter limit (a miter longer than this times the width becomes a bevel). Default: stroke-miterlimit, else 4.")},
                                  {"dashes", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"description", "Dash pattern: on, off, on, off... lengths in the shape's units. [] makes the stroke solid. Default: the shape's stroke-dasharray."}})},
                                  {"dashOffset", num_prop("Where in the dash pattern the line starts. Default: the shape's stroke-dashoffset.")},
                                  {"color", str_prop("A CSS colour to use for shapes that have no stroke (the outline's fill). Shapes with a stroke keep its colour.")}})),
        {"elements"}, false, cmd_stroke});
    defs.push_back({"vector.simplify", "Reduce the nodes of SVG paths within a tolerance.",
        "Rewrites each picked shape (default: every shape) with fewer nodes: a path with curves is refitted from its outline as few cubic Beziers as `tolerance` allows, a path of straight lines loses the vertices within `tolerance` of the line between their neighbours. "
        "Corners stay corners. A shape that cannot lose nodes is left as it is (listed in `unchanged`), so a rect or circle is not turned into a path for nothing. Returns a preview as `$image`. "
        "Example: {\"source\": \"assets/art/tree.svg\", \"tolerance\": 0.4}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, merge_props(elementsOptional, geometry_props())), Json::object()), {}, false, cmd_simplify});
    defs.push_back({"vector.smooth", "Round the corners of SVG paths into smooth Bezier curves.",
        "Gives every node that is not a sharp corner smooth handles, so a polygon or a rough hand-drawn path becomes a flowing curve through the same nodes. `smoothness` 0 keeps the segments straight, 1 is the usual round curve. "
        "Nodes that turn more than `cornerAngle` stay sharp. Applies to the picked shapes (default: every shape). Returns a preview as `$image`. "
        "Example: {\"source\": \"assets/art/blob.svg\", \"elements\": [\"blob\"], \"smoothness\": 0.8}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, merge_props(elementsOptional, geometry_props())), Json::object({{"smoothness", num_prop("0 to 1: how round the curves are. Default 1.")}})), {}, false, cmd_smooth});
    defs.push_back({"vector.align", "Align SVG elements to each other, the canvas or a key element.",
        "Moves the picked elements (shapes or whole groups) so their bounds line up: horizontal left/center/right and/or vertical top/middle/bottom, relative to the selection's bounds, the canvas (the viewBox) or a key element that stays put. "
        "Elements are moved by their own transform attribute, so ids, groups and styles stay as they are; parent transforms are honoured. Returns a preview as `$image`. "
        "Example: {\"source\": \"assets/art/ui.svg\", \"elements\": [\"a\", \"b\", \"c\"], \"vertical\": \"middle\", \"to\": \"key\", \"key\": \"a\"}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, units),
                    Json::object({{"horizontal", enum_prop({"left", "center", "right"}, "Align the left edges, the centres or the right edges.")},
                                  {"vertical", enum_prop({"top", "middle", "bottom"}, "Align the top edges, the middles or the bottom edges.")},
                                  {"to", enum_prop({"selection", "canvas", "key"}, "What to align to: the bounds of the selection (default with two or more elements), the canvas (default with one element) or the `key` element.")},
                                  {"key", str_prop("With to \"key\" (implied when given): the element the others align to; it does not move.")}})),
        {"elements"}, false, cmd_align});
    defs.push_back({"vector.distribute", "Space SVG elements evenly along an axis.",
        "Moves the picked elements along `axis` so the gaps between them (by: \"gaps\", default) or their centres (by: \"centers\") are equal; the first and the last stay put. "
        "With `spacing` the gap is fixed instead and the first element stays. Elements are ordered by position, and moved by their own transform attribute. Returns a preview as `$image`. "
        "Example: {\"source\": \"assets/art/row.svg\", \"elements\": [\"i1\", \"i2\", \"i3\", \"i4\"], \"axis\": \"horizontal\"}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, units),
                    Json::object({{"axis", enum_prop({"horizontal", "vertical"}, "The direction to spread along.")},
                                  {"by", enum_prop({"gaps", "centers"}, "Equal gaps between the elements' edges (default) or equal distance between their centres.")},
                                  {"spacing", num_prop("A fixed gap between neighbouring elements, in drawing units (negative overlaps). The first element stays; the rest follow.")}})),
        {"elements", "axis"}, false, cmd_distribute});
    defs.push_back({"vector.repeat", "Repeat an SVG element in a grid or around a circle.",
        "Adds copies of one element (a shape or a group): mode \"grid\" lays out `columns` x `rows` with `spacing` between their bounds; mode \"radial\" puts `count` copies (the original included) around `center` (or `radius` away) over `sweep` degrees, turned to follow the circle unless orient is false. "
        "`rotation` turns each copy a little more than the last, about its own centre. Copies are placed with a transform attribute and get ids <id>-2, <id>-3... (ids inside a copied group get the same suffix); they follow the original in the drawing. "
        "Angles are in degrees, clockwise on screen, 0 pointing right. Returns a preview as `$image`. "
        "Example: {\"source\": \"assets/art/flower.svg\", \"element\": \"petal\", \"mode\": \"radial\", \"count\": 8, \"center\": [50, 50]}. Docs: docs.read VECTOR.",
        merge_props(common,
                    Json::object({{"element", Json::object({{"type", "string"}, {"description", "The element to repeat: an SVG id or a selector that matches exactly one element (a shape or a group)."}})},
                                  {"mode", enum_prop({"grid", "radial"}, "grid: columns x rows. radial: copies around a centre.")},
                                  {"columns", Json::object({{"type", "integer"}, {"minimum", 1}, {"description", "Grid: copies per row, the original included. Default 1."}})},
                                  {"rows", Json::object({{"type", "integer"}, {"minimum", 1}, {"description", "Grid: number of rows, the original included. Default 1."}})},
                                  {"spacing", Json::object({{"description", "Grid: the gap between neighbouring copies' bounds, a number or [x, y], in drawing units. Default 0 (touching)."}})},
                                  {"count", Json::object({{"type", "integer"}, {"minimum", 2}, {"description", "Radial: how many elements in total, the original included."}})},
                                  {"center", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"description", "Radial: the point [x, y] the copies turn around, in drawing units."}})},
                                  {"radius", num_prop("Radial, without `center`: the circle's radius; the centre is put that far below the element.")},
                                  {"sweep", num_prop("Radial: the angle the copies cover, 1 to 360 degrees. Default 360.")},
                                  {"orient", bool_prop("Radial: turn each copy to follow the circle (default). false keeps every copy upright.", true)},
                                  {"rotation", num_prop("Degrees each copy turns more than the previous one, about its own centre. Default 0.")},
                                  {"bounds", enum_prop({"visual", "geometry"}, "What a copy's size is measured with: \"visual\" (default) includes the stroke.")}})),
        {"element", "mode"}, false, cmd_repeat});
    defs.push_back({"vector.style", "Apply the project's style guide to an SVG: outline and palette.",
        "Applies assets.json `style` to the SVG: `outline` puts the guide's outline colour and width (pixels of the SVG's declared size) as a stroke on every filled shape; `palette` snaps every fill, stroke and gradient stop colour to the nearest colour of the guide's palette. "
        "With neither argument it applies both, whichever the guide defines; one of them asked for alone applies only that one (outline: true = just the outline), and one switched off alone applies the other (outline: false = just the palette). Pass {\"outline\": {\"width\": 2, \"color\": \"#101018\"}} or {\"palette\": [\"#101018\", \"#e8e0d0\"]} to use values other than the guide's. "
        "Applies to the picked elements (default: the whole drawing). Returns a preview as `$image`. Example: {\"source\": \"assets/art/crest.svg\"}. Docs: docs.read VECTOR.",
        merge_props(common, merge_props(elementsOptional,
                    Json::object({{"outline", Json::object({{"description", "true: the guide's outline. An object {\"width\", \"color\"}: that outline. false: none. Width is in pixels of the SVG's declared size."}})},
                                  {"palette", Json::object({{"description", "true: snap to the guide's palette. A list of colours: snap to those. false: leave colours."}})}}))),
        {}, false, cmd_style});
    defs.push_back({"vector.info", "List the shapes and groups of an SVG with ids, bounds and node counts.",
        "Reads an SVG and lists its drawable elements: id, tag, bounds in the drawing space (viewBox units), node count, fill, stroke and transform, plus the canvas. Use it to find the ids the other vector.* commands take. Changes nothing. "
        "Example: {\"source\": \"assets/art/badge.svg\"}. Docs: docs.read VECTOR.",
        merge_props(common, elementsOptional), {}, true, cmd_info});

    for (Def& d : defs) {
        CommandInfo info;
        info.name = d.name;
        info.summary = d.summary;
        info.description = d.description;
        info.category = "assets";
        info.readOnly = d.readOnly;
        Json schema = Json::object({{"type", "object"}, {"properties", d.props}});
        if (!d.required.empty()) schema["required"] = d.required;
        info.inputSchema = schema;
        const std::string name = d.name;
        auto fn = d.fn;
        const Json props = d.props;
        const bool ro = d.readOnly;
        registry.add(info, [projectDir, name, fn, props, ro](const Json& args) {
            if (!args.is_object()) fail("invalid_argument", name + ": the arguments must be an object.", "Example: {\"source\": \"assets/art/badge.svg\"}.");
            return fa::vec::run(projectDir, args, name.c_str(), props, ro, [fn](fa::vec::Ctx& c) { return fn(c); });
        });
    }
}

}  // namespace fa::assets_detail
