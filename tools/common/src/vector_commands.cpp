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
#include "vector_cmd.h"
#include "vector_ops.h"
#include "vector_shapes.h"

namespace fa::vec {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using assets_detail::fail;
using tooling_detail::arg_bool;
namespace tooling_detail_ = fa::tooling_detail;

namespace cmd {

namespace stdfs = std::filesystem;

// ---- arguments ---------------------------------------------------------------------------------------------------------

double num_arg(const Json& a, const char* cmd, const char* key, double lo, double hi, double def, const char* hint) {
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

std::string enum_arg(const Json& a, const char* cmd, const char* key, const std::vector<std::string>& names, const std::string& def, bool required) {
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
         {"preview", bool_prop("false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself.", true)},
         {"bake", bool_prop("With `document`: also bake the document's PNG (like image.layer.set).", true)}});
}

Json geometry_props() {
    return Json::object(
        {{"tolerance", num_prop("The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify).")},
         {"curves", bool_prop("Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed.", true)},
         {"cornerAngle", num_prop("Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28.")}});
}

Json placement_props() {
    return Json::object(
        {{"id", str_prop("The id of the new element (default: the kind, \"star\", \"blob\"..., or the next free \"star-2\"). An id the SVG already uses is an error.")},
         {"parent", str_prop("An id or selector of ONE group (<g>) to put the element in, at its end. Default: the top level. Coordinates are the parent's own, so a translated or scaled group moves and scales the shape.")},
         {"before", str_prop("An id or selector of ONE element: the new one goes in front of it in the drawing order (behind it on the picture), in the same group.")},
         {"transform", str_prop("A transform attribute for the new element, e.g. \"rotate(15 50 50)\".")},
         {"fill", str_prop("A CSS fill colour or \"none\". Default: a blue for closed shapes, none for open curves.")},
         {"stroke", str_prop("A CSS stroke colour. Default: none for closed shapes, a dark slate for open curves.")},
         {"strokeWidth", num_prop("Stroke width in the parent's units (default 1% of the drawing's longer side for open curves).")},
         {"opacity", num_prop("0 to 1.")},
         {"attributes", Json::object({{"type", "object"}, {"description", "Any other attributes of the new element: {\"class\": \"body\", \"stroke-linejoin\": \"round\"}."}})}});
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

// A project-relative .svg path. `write`: the file will be written (inside the project for every caller, outside .git and .factoria),
// checked here so that nothing is computed for a path the command may not write.
std::string svg_path_arg(const std::string& projectDir, const std::string& value, const char* cmd, const char* key, stdfs::path& abs, bool write = false) {
    std::string rel = value;
    std::replace(rel.begin(), rel.end(), '\\', '/');
    while (rel.rfind("./", 0) == 0) rel = rel.substr(2);
    if (rel.size() < 5 || to_lower(rel.substr(rel.size() - 4)) != ".svg")
        arg_error(cmd, std::string("/") + key, std::format("'{}' is not an .svg file.", value), "Give a project-relative path that ends in .svg, e.g. \"assets/art/crest.svg\".");
    abs = write ? assets_detail::project_write_file(projectDir, rel) : assets_detail::project_file(projectDir, rel);
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
    const bool wantPreview = arg_bool(a, "preview", true);
    const bool isDoc = a.contains("document");
    if (isDoc && a.contains("out")) arg_error(cmd, "/out", "`out` cannot be used with `document`: the layer is edited inside the document.", "Leave `out` out, or use `source` to edit a .svg file.");
    if (!isDoc && a.contains("layer")) arg_error(cmd, "/layer", "`layer` only goes with `document`.", "Leave `layer` out, or pass `document`.");

    stdfs::path outAbs;
    std::string outRel;
    if (a.contains("out")) {
        // checked before the SVG is read or edited: a path the caller may not write costs nothing
        outRel = svg_path_arg(projectDir, a["out"].get<std::string>(), cmd, "out", outAbs, !readOnly);
        std::error_code ec;
        if (!dryRun && !arg_bool(a, "overwrite", false) && stdfs::exists(outAbs, ec))
            fail("exists", std::format("'{}' already exists.", outRel), "Pass overwrite: true to replace it, or choose another `out`.");
    }

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
        // `source` is rewritten in place when nothing else says where the result goes
        rel = svg_path_arg(projectDir, a["source"].get<std::string>(), cmd, "source", srcAbs, !readOnly && !dryRun && !a.contains("out"));
        auto t = tooling_detail::read_file(srcAbs);
        if (!t) fail("not_found", std::format("{} /source: '{}' does not exist or cannot be read.", cmd, rel), "Check the path (project-relative), or pass the SVG text in `svg`.");
        text = *t;
        what = rel;
    } else if (a.contains("svg")) {
        text = a["svg"].get<std::string>();
        what = "the `svg` argument";
    } else {
        docFile = imgedit::open_doc(projectDir, a["document"].get<std::string>(), cmd, !readOnly && !dryRun);
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
            layerSourceAbs = !readOnly && !dryRun ? assets_detail::project_write_file(projectDir, layerSourceRel) : assets_detail::project_file(projectDir, layerSourceRel);
            auto t = tooling_detail::read_file(layerSourceAbs);
            if (!t) fail("not_found", std::format("{} /document: the svg layer's source '{}' does not exist.", cmd, layerSourceRel), "Fix the layer's `source` with image.layer.set.");
            text = *t;
        }
        what = layerInline ? std::format("{} layer {}", rel, layerRef.indexPath) : layerSourceRel;
        if (wantPreview) before = imgedit::render_document_json(projectDir, docFile.json);
    }

    SvgDoc doc = SvgDoc::parse(text, what);
    std::vector<std::string> warnings = document_warnings(doc);
    // a shape the panel drew from parameters (data-fa-shape) stops being one when any command changes its outline
    // (a command that rewrites the shape together with its data-fa-args, like vector.shape with replace, keeps it)
    std::map<std::string, std::pair<std::string, std::string>> parametric;
    for (XNode* n : doc.all_elements())
        if (n->attr("data-fa-shape") && n->attr("id")) parametric[*n->attr("id")] = {n->attr_or("d"), n->attr_or("data-fa-args")};
    Ctx ctx{cmd, projectDir, a, doc, warnings};
    Json result = body(ctx);
    if (!result.is_object()) result = Json::object();
    for (const auto& [id, was] : parametric)
        if (XNode* n = doc.by_id(id); n && n->attr("data-fa-shape") && n->attr_or("d") != was.first && n->attr_or("data-fa-args") == was.second) {
            n->remove_attr("data-fa-shape");
            n->remove_attr("data-fa-args");
        }

    const std::string newText = doc.write();
    const bool changed = newText != text;
    if (!readOnly) result["changed"] = changed;

    // write
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
        if (!wantPreview) return std::nullopt;
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
    if (isDoc && dryRun && changed && wantPreview) {
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

}  // namespace cmd

namespace {
using namespace cmd;

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

}  // namespace

namespace cmd {

// ---- shape builders: placement and the new elements -------------------------------------------------------------------------

bool valid_id(const std::string& id) {
    if (id.empty() || !(std::isalpha(static_cast<unsigned char>(id[0])) || id[0] == '_')) return false;
    return std::all_of(id.begin(), id.end(), [](char ch) { return std::isalnum(static_cast<unsigned char>(ch)) || ch == '_' || ch == '-' || ch == '.' || ch == ':'; });
}

std::string str_arg(const Json& a, const char* cmd, const char* key, const std::string& def, const char* hint) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_string() || it->get<std::string>().empty())
        arg_error(cmd, std::string("/") + key, std::format("`{}` must be a non-empty string, got {}.", key, describe_json_value(*it)), hint);
    return it->get<std::string>();
}

bool point_arg(const Json& a, const char* cmd, const char* key, P& out, const char* meaning) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return false;
    if (!it->is_array() || it->size() != 2 || !(*it)[0].is_number() || !(*it)[1].is_number() || !std::isfinite((*it)[0].get<double>()) || !std::isfinite((*it)[1].get<double>()))
        arg_error(cmd, std::string("/") + key, "expected [x, y], got " + describe_json_value(*it) + ".", std::string(meaning) + " Example: [50, 40].");
    out = P{(*it)[0].get<double>(), (*it)[1].get<double>()};
    return true;
}

XNode* single_element(Ctx& c, const char* key) {
    const Json& v = c.a[key];
    if (!v.is_string()) arg_error(c.cmd, std::string("/") + key, "expected one SVG id or selector, got " + describe_json_value(v) + ".", "Run vector.info to list the ids.");
    const std::vector<XNode*> found = select_elements(c.doc, v.get<std::string>(), c.cmd, std::string("/") + key);
    if (found.size() != 1)
        arg_error(c.cmd, std::string("/") + key, std::format("'{}' matches {} elements; exactly one is needed.", v.get<std::string>(), found.size()), "Use an id, or a more specific selector.");
    return found[0];
}

Placement placement_of(Ctx& c, bool lineArt, const Settings& s) {
    Placement at;
    at.lineArt = lineArt;
    at.id = str_arg(c.a, c.cmd, "id", "");
    if (!at.id.empty() && !valid_id(at.id))
        arg_error(c.cmd, "/id", std::format("'{}' is not a usable SVG id.", at.id), "Start with a letter or underscore, then letters, digits, - _ . : only (e.g. \"hero-star\").");
    if (c.a.contains("parent")) {
        at.parent = single_element(c, "parent");
        if (!is_group_element(*at.parent))
            arg_error(c.cmd, "/parent", std::format("{} is not a group, so nothing can be put in it.", describe_element(*at.parent)), "Name a <g> (or leave `parent` out for the top level).");
    }
    if (c.a.contains("before")) {
        at.before = single_element(c, "before");
        if (at.before == c.doc.root()) arg_error(c.cmd, "/before", "the root <svg> has no place before it.", "Name an element inside the drawing.");
        if (at.parent && at.before->parent != at.parent)
            arg_error(c.cmd, "/before", std::format("{} is not inside the `parent` group.", describe_element(*at.before)), "Name an element of that group, or leave `parent` out.");
    }
    at.transform = str_arg(c.a, c.cmd, "transform", "");
    if (!at.transform.empty()) {
        Mat m;
        std::string err;
        if (!parse_transform(at.transform, m, err)) arg_error(c.cmd, "/transform", err, "Example: \"rotate(15 50 50)\" or \"translate(10 0) scale(1.5)\".");
    }
    at.fill = str_arg(c.a, c.cmd, "fill", "", "A CSS colour such as \"#d94f4f\", or \"none\".");
    at.stroke = str_arg(c.a, c.cmd, "stroke", "", "A CSS colour such as \"#101018\", or \"none\".");
    if (c.a.contains("strokeWidth")) at.strokeWidth = num_arg(c.a, c.cmd, "strokeWidth", 0.0, 1e6, 1, "In the units of the parent.");
    if (c.a.contains("opacity")) at.opacity = format_number(num_arg(c.a, c.cmd, "opacity", 0.0, 1.0, 1), 3);
    const Rect canvas = c.doc.canvas();
    at.defaultStrokeWidth = std::max(1.0, std::max(canvas.width(), canvas.height()) / 100.0);
    (void)s;
    if (c.a.contains("attributes")) {
        const Json& at_ = c.a["attributes"];
        if (!at_.is_object()) arg_error(c.cmd, "/attributes", "expected an object of attribute names and values, got " + describe_json_value(at_) + ".", "Example: {\"class\": \"body\", \"stroke-linejoin\": \"round\"}.");
        for (auto it = at_.begin(); it != at_.end(); ++it) {
            if (it.key() == "d" || it.key() == "id" || !valid_id(it.key()) || !(it->is_string() || it->is_number()))
                arg_error(c.cmd, "/attributes/" + it.key(), "cannot be set here: `d` and `id` have their own arguments, names must be plain attribute names and values strings or numbers.", "");
            at.attrs[it.key()] = it->is_string() ? it->get<std::string>() : format_number(it->get<double>(), 6);
        }
    }
    return at;
}

// The parent's coordinates: the drawing's centre and a size to draw at when the call gives none.
Frame frame_of(Ctx& c, const Placement& at) {
    XNode* parent = at.before ? (at.before->parent ? at.before->parent : c.doc.root()) : at.parent ? at.parent : c.doc.root();
    const Mat m = element_ctm(*parent);
    const Rect canvas = c.doc.canvas();
    Frame f;
    f.centre = m.invertible() ? inverse(m).apply(canvas.center()) : canvas.center();
    f.unit = 0.4 * std::min(canvas.width(), canvas.height()) / std::max(m.scale(), 1e-9);
    if (!(f.unit > 0)) f.unit = 40;
    return f;
}

}  // namespace cmd

namespace {
using namespace cmd;

using KeyList = std::vector<std::string>;
// The arguments each kind of vector.shape takes (besides the placement and the file arguments).
const std::vector<std::pair<std::string, KeyList>>& shape_kinds() {
    static const std::vector<std::pair<std::string, KeyList>> kinds = {
        {"star", {"center", "radius", "points", "innerRatio", "roundness", "rotation"}},
        {"gear", {"center", "radius", "teeth", "depth", "toothWidth", "hole", "rotation"}},
        {"polygon", {"center", "radius", "sides", "cornerRadius", "rotation"}},
        {"arrow", {"from", "to", "shaftWidth", "headLength", "headWidth", "curve"}},
        {"bubble", {"center", "width", "height", "cornerRadius", "tail", "tailTo", "tailWidth", "tailRoundness"}},
        {"ribbon", {"center", "width", "height", "extent", "drop", "notch", "foldFill"}},
    };
    return kinds;
}

Json cmd_shape(Ctx& c) {
    std::vector<std::string> names;
    for (const auto& k : shape_kinds()) names.push_back(k.first);
    const std::string kind = enum_arg(c.a, c.cmd, "kind", names, "", true);
    const KeyList* mine = nullptr;
    for (const auto& k : shape_kinds())
        if (k.first == kind) mine = &k.second;
    // an argument of another kind is a mistake worth naming
    for (const auto& k : shape_kinds()) {
        if (k.first == kind) continue;
        for (const std::string& key : k.second) {
            if (c.a.contains(key) && std::find(mine->begin(), mine->end(), key) == mine->end()) {
                std::string list;
                for (const std::string& m : *mine) list += (list.empty() ? "" : ", ") + m;
                arg_error(c.cmd, "/" + key, std::format("`{}` does not apply to kind \"{}\" (it belongs to \"{}\").", key, kind, k.first), "The arguments of \"" + kind + "\": " + list + ".");
            }
        }
    }
    const Settings s = settings_of(c, 4000);
    // replace: the shape is redrawn in an existing element, in that element's own coordinates; its id, style and transform stay
    XNode* replaced = nullptr;
    if (c.a.contains("replace")) {
        for (const char* k : {"id", "parent", "before", "transform", "fill", "stroke", "strokeWidth", "opacity", "attributes"})
            if (c.a.contains(k))
                arg_error(c.cmd, std::string("/") + k, "cannot be combined with `replace`: the element keeps its id, place and style.", "Change them with vector.set, vector.reorder and vector.transform.");
        if (kind == "ribbon") arg_error(c.cmd, "/replace", "a ribbon is a group of five paths, so it cannot replace one shape.", "Delete the ribbon (vector.delete) and add a new one.");
        replaced = single_element(c, "replace");
        if (!is_shape_element(*replaced))
            arg_error(c.cmd, "/replace", std::format("{} is not a shape, so it has no outline to replace.", describe_element(*replaced)), "Name a path, rect, circle, ellipse, line, polyline or polygon.");
    }
    Placement at;
    if (replaced) {
        at.parent = replaced;  // frame_of reads the coordinates of the parent: here the element's own
    } else {
        at = placement_of(c, false, s);
    }
    const Frame fr = frame_of(c, at);
    P centre = fr.centre;
    point_arg(c.a, c.cmd, "center", centre, "The middle of the shape, in the parent's coordinates (default: the middle of the drawing).");
    const double u = fr.unit;
    auto num = [&](const char* key, double lo, double hi, double def, const char* hint) { return num_arg(c.a, c.cmd, key, lo, hi, def, hint); };
    Path path;
    std::vector<RibbonPiece> pieces;
    Json extra = Json::object();
    if (kind == "star") {
        VecStarSpec sp;
        sp.center = {centre.x, centre.y};
        sp.radius = num("radius", 1e-6, 1e7, u, "The distance from the centre to the tips.");
        sp.points = int_arg(c.a, c.cmd, "points", 3, 128, 5);
        sp.innerRatio = num("innerRatio", 0.02, 0.98, 0.5, "The radius of the valleys as a fraction of `radius`: 0.5 is a classic star, 0.8 a fat one, 0.2 a sharp one.");
        sp.roundness = num("roundness", 0, 1, 0, "0 keeps sharp corners, 1 rounds as far as the edges allow.");
        sp.rotation = num("rotation", -3600, 3600, -90, "Degrees, clockwise on screen, 0 points right; -90 (default) puts the first tip up.");
        path = build_star(sp);
        extra["points"] = sp.points;
    } else if (kind == "gear") {
        VecGearSpec sp;
        sp.center = {centre.x, centre.y};
        sp.radius = num("radius", 1e-6, 1e7, u, "The distance from the centre to the tips of the teeth.");
        sp.teeth = int_arg(c.a, c.cmd, "teeth", 3, 128, 8);
        sp.depth = num("depth", 0.02, 0.6, 0.2, "The height of a tooth as a fraction of `radius`.");
        sp.toothWidth = num("toothWidth", 0.1, 0.9, 0.5, "The width of a tooth at its tip as a fraction of the distance between two teeth.");
        sp.hole = num("hole", 0, 0.9, 0.3, "The radius of the centre hole as a fraction of `radius`; 0 for none.");
        sp.rotation = num("rotation", -3600, 3600, -90, "Degrees, clockwise on screen; where the first tooth points (-90 = up).");
        if (sp.hole >= 1 - sp.depth - 0.05) arg_error(c.cmd, "/hole", std::format("a hole of {} of the radius reaches the teeth (their roots are at {}).", sp.hole, 1 - sp.depth), "Use a smaller hole or a smaller depth.");
        path = build_gear(sp);
        extra["teeth"] = sp.teeth;
    } else if (kind == "polygon") {
        VecPolygonSpec sp;
        sp.center = {centre.x, centre.y};
        sp.radius = num("radius", 1e-6, 1e7, u, "The radius of the circle through the corners.");
        sp.sides = int_arg(c.a, c.cmd, "sides", 3, 128, 6);
        sp.cornerRadius = num("cornerRadius", 0, 1e7, 0, "The radius of the rounded corners, in the parent's units. It is cut down where the sides are too short.");
        sp.rotation = num("rotation", -3600, 3600, -90, "Degrees, clockwise on screen; where the first corner points (-90 = up).");
        path = build_polygon(sp);
        extra["sides"] = sp.sides;
    } else if (kind == "arrow") {
        VecArrowSpec sp;
        P from{centre.x - u, centre.y}, to{centre.x + u, centre.y};
        point_arg(c.a, c.cmd, "from", from, "Where the shaft starts, in the parent's coordinates.");
        point_arg(c.a, c.cmd, "to", to, "The tip of the head.");
        if (dist(from, to) < 1e-6) arg_error(c.cmd, "/to", "`from` and `to` are the same point, so the arrow has no length.", "Give two different points.");
        const double len_ = dist(from, to);
        sp.from = {from.x, from.y};
        sp.to = {to.x, to.y};
        sp.shaftWidth = num("shaftWidth", 1e-6, 1e7, len_ * 0.12, "The thickness of the shaft.");
        sp.headLength = num("headLength", 1e-6, 1e7, std::min(len_ * 0.3, sp.shaftWidth * 2.5), "How far the head reaches back from the tip, along the arrow.");
        sp.headWidth = num("headWidth", 1e-6, 1e7, sp.shaftWidth * 2.2, "The width of the head across the arrow.");
        sp.curve = num("curve", -0.5, 0.5, 0, "The bend: 0 is straight; the sagitta as a fraction of the length (0.5 = a half circle); positive bends to the right of from -> to.");
        if (sp.headLength > len_) arg_error(c.cmd, "/headLength", std::format("the head ({}) is longer than the arrow ({}).", sp.headLength, len_), "Use a shorter head or move `from` and `to` apart.");
        path = build_arrow(sp);
    } else if (kind == "bubble") {
        VecBubbleSpec sp;
        sp.center = {centre.x, centre.y};
        sp.width = num("width", 1e-6, 1e7, u * 1.8, "The width of the box.");
        sp.height = num("height", 1e-6, 1e7, u * 1.1, "The height of the box.");
        sp.cornerRadius = num("cornerRadius", 0, 1e7, std::min(sp.width, sp.height) * 0.25, "The radius of the box's corners.");
        sp.hasTail = arg_bool(c.a, "tail", true);
        P tip{centre.x - sp.width * 0.25, centre.y + sp.height * 0.5 + sp.height * 0.55};
        const bool tipGiven = point_arg(c.a, c.cmd, "tailTo", tip, "The tip of the tail, outside the box: it grows from the side of the box nearest to this point.");
        if (!sp.hasTail && tipGiven) c.warnings.push_back("`tailTo` is ignored because `tail` is false.");
        sp.tailTo = {tip.x, tip.y};
        if (sp.hasTail && tip.x > centre.x - sp.width / 2 && tip.x < centre.x + sp.width / 2 && tip.y > centre.y - sp.height / 2 && tip.y < centre.y + sp.height / 2)
            arg_error(c.cmd, "/tailTo", std::format("the tip [{}, {}] is inside the box (x {} to {}, y {} to {}).", tip.x, tip.y, centre.x - sp.width / 2, centre.x + sp.width / 2, centre.y - sp.height / 2, centre.y + sp.height / 2),
                      "Put the tip outside the box, in the direction of whoever is speaking, or pass tail: false.");
        sp.tailWidth = num("tailWidth", 1e-6, 1e7, std::min(sp.width, sp.height) * 0.3, "The width of the tail where it leaves the box.");
        sp.tailRoundness = num("tailRoundness", 0, 1, 0.5, "0 is a sharp tip, 1 a round one.");
        path = build_bubble(sp);
    } else {
        VecRibbonSpec sp;
        sp.center = {centre.x, centre.y};
        sp.width = num("width", 1e-6, 1e7, u * 1.4, "The width of the front band.");
        sp.height = num("height", 1e-6, 1e7, sp.width * 0.27, "The height of the front band.");
        sp.extent = num("extent", 0, 1e7, sp.width * 0.2, "How far each tail sticks out past the band.");
        sp.drop = num("drop", 0, 1e7, sp.height * 0.35, "How much lower the tails sit than the band; also the size of the folds.");
        sp.notch = num("notch", 0, 1e7, std::min(sp.extent, sp.height * 0.3), "The depth of the V cut in the end of a tail; 0 for a straight end.");
        const VecRibbonPieces rp = vector_ribbon_paths(sp, s.outDecimals);
        std::string foldFill = str_arg(c.a, c.cmd, "foldFill", "", "A CSS colour for the folds and tails; default: a darker shade of `fill`.");
        std::string bandFill = !at.fill.empty() ? at.fill : "#d94f4f";
        if (foldFill.empty()) {
            std::array<std::uint8_t, 3> rgb{};
            double al = 1;
            foldFill = parse_css_colour(bandFill, rgb, al) ? oklab_shift(rgb, -1, 0.14) : "#8a2f2f";
        }
        std::string tailFill = foldFill;
        {
            std::array<std::uint8_t, 3> rgb{};
            double al = 1;
            if (c.a.contains("foldFill") == false && parse_css_colour(bandFill, rgb, al)) tailFill = oklab_shift(rgb, -1, 0.07);
        }
        pieces = {{"tail-left", rp.leftTail, tailFill}, {"tail-right", rp.rightTail, tailFill}, {"fold-left", rp.leftFold, foldFill}, {"fold-right", rp.rightFold, foldFill}, {"band", rp.band, bandFill}};
    }
    Placement placed = at;
    Json r;
    const bool parametric = arg_bool(c.a, "parametric", false);
    if (parametric && kind == "ribbon") arg_error(c.cmd, "/parametric", "a ribbon is a group of five paths, so it cannot be kept parametric.", "Use parametric with star, gear, polygon, arrow or bubble.");
    if (replaced) {
        set_path_geometry(*replaced, path_to_data(path, s.outDecimals));
        replaced->remove_attr("data-fa-shape");
        replaced->remove_attr("data-fa-args");
        const Rect b = path_bounds(transform_path(path, element_ctm(*replaced)));
        r = Json::object({{"element", element_ref(*replaced)}, {"nodes", node_count(path)}, {"bounds", Json::array({b.x0, b.y0, b.width(), b.height()})}});
    } else if (kind == "ribbon") {
        placed.fill.clear();
        r = op_add_group(c.doc, placed, "ribbon", pieces, s, c.warnings);
    } else {
        r = op_add_path(c.doc, placed, kind, path, s, c.warnings);
    }
    if (parametric) {
        // the arguments of the kind that were given, plus the centre, so the panel can show them and call again with `replace`
        Json args = Json::object();
        for (const std::string& key : *mine)
            if (c.a.contains(key)) args[key] = c.a[key];
        if (!args.contains("center") && kind != "arrow") args["center"] = Json::array({centre.x, centre.y});
        XNode* el = replaced ? replaced : c.doc.by_id(r.value("element", std::string()));
        if (el) {
            el->set_attr("data-fa-shape", kind);
            el->set_attr("data-fa-args", args.dump());
        }
    }
    r["kind"] = kind;
    for (auto it = extra.begin(); it != extra.end(); ++it) r[it.key()] = it.value();
    return r;
}

Json cmd_blob(Ctx& c) {
    const Settings s = settings_of(c, 4000);
    VecBlobSpec sp;
    auto it = c.a.find("points");
    if (it == c.a.end() || !it->is_array())
        arg_error(c.cmd, "/points", "`points` is required: a list of [x, y] points.", "Example: {\"points\": [[20, 50], [50, 20], [80, 50], [50, 85]]}.");
    for (std::size_t i = 0; i < it->size(); ++i) {
        const Json& p = (*it)[i];
        if (!p.is_array() || p.size() != 2 || !p[0].is_number() || !p[1].is_number() || !std::isfinite(p[0].get<double>()) || !std::isfinite(p[1].get<double>()))
            arg_error(c.cmd, std::format("/points/{}", i), "expected [x, y], got " + describe_json_value(p) + ".", "Each point is two numbers in the parent's coordinates: [50, 20].");
        sp.points.push_back({p[0].get<double>(), p[1].get<double>()});
    }
    sp.closed = arg_bool(c.a, "closed", true);
    const std::string fit = enum_arg(c.a, c.cmd, "fit", {"through", "around"}, "through");
    sp.around = fit == "around";
    sp.tension = num_arg(c.a, c.cmd, "tension", 0, 1.5, 0.5, "0 = straight lines between the points, 0.5 = the usual smooth curve (Catmull-Rom), more overshoots.");
    if (sp.around && c.a.contains("tension")) c.warnings.push_back("`tension` is ignored with fit \"around\" (the curve is a B-spline of the control polygon).");
    const std::size_t need = sp.closed ? 3 : 2;
    if (sp.points.size() < need)
        arg_error(c.cmd, "/points", std::format("{} point(s) are not enough for {}: at least {} are needed.", sp.points.size(), sp.closed ? "a closed blob" : "an open curve", need),
                  sp.closed ? "Add points, or pass closed: false for an open curve." : "Add a second point.");
    const Placement at = placement_of(c, !sp.closed, s);
    Json r = op_add_path(c.doc, at, sp.closed ? "blob" : "curve", build_blob(sp), s, c.warnings);
    r["fit"] = fit;
    r["closed"] = sp.closed;
    return r;
}

Json cmd_mirror(Ctx& c) {
    const std::vector<XNode*> els = pick(c, "elements", true);
    MirrorArgs a;
    a.axis = enum_arg(c.a, c.cmd, "axis", {"vertical", "horizontal"}, "", true) == "vertical" ? Axis::Vertical : Axis::Horizontal;
    auto it = c.a.find("at");
    if (it != c.a.end() && !it->is_null()) {
        if (it->is_number() && std::isfinite(it->get<double>())) {
            a.atMode = "value";
            a.at = it->get<double>();
        } else if (it->is_string() && (it->get<std::string>() == "canvas" || it->get<std::string>() == "start" || it->get<std::string>() == "end")) {
            a.atMode = it->get<std::string>();
        } else {
            arg_error(c.cmd, "/at", "expected a number or \"canvas\", \"start\" or \"end\", got " + describe_json_value(*it) + ".",
                      "A number is the coordinate of the mirror line in the drawing (x for a vertical axis, y for a horizontal one); \"canvas\" is the drawing's middle line (default); \"start\" / \"end\" are the left (top) and right (bottom) edge of each shape.");
        }
    }
    a.weld = arg_bool(c.a, "weld", true);
    const Settings s = settings_of(c, 4000);
    if (c.a.contains("snap")) a.snap = num_arg(c.a, c.cmd, "snap", 0, 1e6, 0, "Points of the shape this close to the axis are put on it, so the halves meet exactly. Drawing units.");
    return op_mirror(c.doc, els, a, s, c.warnings);
}

Json cmd_text(Ctx& c) {
    const Settings s = settings_of(c, 4000);
    const bool hasText = c.a.contains("text"), hasEls = c.a.contains("elements");
    if (hasText == hasEls)
        arg_error(c.cmd, hasText ? "" : "/text", hasText ? "`text` and `elements` were both given." : "neither `text` nor `elements` was given.",
                  "Give `text` to draw new outlines, or `elements` (the ids of <text> elements) to turn the ones in the drawing into paths.");
    const std::string font = str_arg(c.a, c.cmd, "font", "", "\"\" / \"builtin\" (DejaVu Sans), \"builtin:serif\", \"builtin:hand\", \"builtin:display\", \"builtin:blackletter\", \"builtin:pixel\", or a project .ttf / .otf.");
    if (hasEls) {
        for (const char* k : {"size", "at", "anchor", "letterSpacing", "lineSpacing", "id", "parent", "before", "transform", "fill", "stroke", "strokeWidth", "opacity", "attributes"})
            if (c.a.contains(k)) arg_error(c.cmd, std::string("/") + k, std::format("`{}` is for new text; with `elements` each <text> keeps its own position, size, fill and id.", k), "Leave it out, or use `text` instead of `elements`.");
        assets_detail::ProjectRootGuard rootGuard(c.projectDir);
        return op_text_to_path(c.doc, pick(c, "elements", true), font, s, c.warnings);
    }
    if (!c.a["text"].is_string() || c.a["text"].get<std::string>().empty())
        arg_error(c.cmd, "/text", "`text` must be a non-empty string.", "Example: {\"text\": \"LEVEL 3\", \"size\": 24}.");
    const Placement at = placement_of(c, false, s);
    const Frame fr = frame_of(c, at);
    TextArgs t;
    t.text = c.a["text"].get<std::string>();
    t.font = font;
    t.size = num_arg(c.a, c.cmd, "size", 1e-3, 1e6, fr.unit * 0.5, "The height of an em in the parent's units (the font size).");
    t.anchor = enum_arg(c.a, c.cmd, "anchor", {"start", "middle", "end"}, "start");
    t.letterSpacing = num_arg(c.a, c.cmd, "letterSpacing", -2, 5, 0, "Extra space after each letter, in ems.");
    t.lineSpacing = num_arg(c.a, c.cmd, "lineSpacing", 0.2, 5, 1, "A multiplier of the font's line height for texts with several lines.");
    t.at = P{fr.centre.x, fr.centre.y};
    if (t.anchor == "start") t.at.x -= 0.0;
    point_arg(c.a, c.cmd, "at", t.at, "Where the text sits: the start (or middle, or end, see `anchor`) of the first baseline, in the parent's coordinates.");
    if (!c.a.contains("at")) {
        // centred in the drawing when no position is given
        t.anchor = c.a.contains("anchor") ? t.anchor : "middle";
    }
    assets_detail::ProjectRootGuard rootGuard(c.projectDir);
    return op_add_text(c.doc, at, t, s, c.warnings);
}

Json cmd_shade(Ctx& c) {
    const std::vector<XNode*> els = pick(c, "elements", true);
    const Settings s = settings_of(c, 4000);
    ShadeArgs a;
    assets_detail::ProjectRootGuard rootGuard(c.projectDir);
    const StyleParse guide = load_style_guide();
    for (const StyleProblem& p : guide.problems) c.warnings.push_back(std::format("assets.json {}: {}", p.pointer, p.message));
    auto it = c.a.find("light");
    if (it != c.a.end() && !it->is_null()) {
        if (it->is_number() && std::isfinite(it->get<double>())) {
            a.lightDegrees = std::fmod(std::fmod(it->get<double>(), 360.0) + 360.0, 360.0);
            a.lightSource = "argument";
        } else if (it->is_string() && it->get<std::string>() != "style") {
            std::vector<std::string> names;
            bool found = false;
            for (const auto& n : light_direction_names()) {
                names.push_back(n.first);
                if (n.first == it->get<std::string>()) {
                    a.lightDegrees = n.second;
                    found = true;
                }
            }
            if (!found) arg_error(c.cmd, "/light", std::format("'{}' is not a light direction.", it->get<std::string>()), did_you_mean(it->get<std::string>(), names) + " Names: " + [&] { std::string l; for (const auto& n : names) l += (l.empty() ? "" : ", ") + n; return l; }() + "; or degrees.");
            a.lightSource = "argument";
        } else if (!it->is_string()) {
            arg_error(c.cmd, "/light", "expected degrees or a name, got " + describe_json_value(*it) + ".",
                      "The direction TOWARDS the light, counter-clockwise from +x (right): 90 = from above, 135 = upper-left, 0 = from the right. Or a name: \"upper-left\", \"top\"... or \"style\".");
        }
    }
    if (a.lightSource == "default") {
        if (guide.guide.lightDirection) {
            a.lightDegrees = *guide.guide.lightDirection;
            a.lightSource = "style";
        } else if (it != c.a.end() && it->is_string() && it->get<std::string>() == "style") {
            c.warnings.push_back("The style guide (assets.json style.lightDirection) has no light direction; the default upper-left (135) was used.");
        }
    }
    a.shadow = arg_bool(c.a, "shadow", true);
    a.highlight = arg_bool(c.a, "highlight", true);
    if (!a.shadow && !a.highlight) arg_error(c.cmd, "/shadow", "both `shadow` and `highlight` are false, so there is nothing to build.", "Leave one of them on.");
    if (c.a.contains("depth")) a.depth = num_arg(c.a, c.cmd, "depth", 1e-6, 1e7, 1, "The width of the shadow band, in drawing units (default: 10% of the shape's smaller side).");
    if (c.a.contains("highlightDepth")) a.highlightDepth = num_arg(c.a, c.cmd, "highlightDepth", 1e-6, 1e7, 1, "The width of the highlight band (default: 60% of the shadow's).");
    a.strength = num_arg(c.a, c.cmd, "strength", 0.01, 0.6, 0.12, "How much lighter or darker the derived colours are, in OKLab lightness (0 to 1).");
    a.shadowOpacity = num_arg(c.a, c.cmd, "shadowOpacity", 0, 1, 1);
    a.highlightOpacity = num_arg(c.a, c.cmd, "highlightOpacity", 0, 1, 1);
    for (const char* key : {"shadowColour", "highlightColour"}) {
        std::string v = str_arg(c.a, c.cmd, key, "", "A CSS colour such as \"#2a2e5c\".");
        std::array<std::uint8_t, 3> rgb{};
        double al = 1;
        if (!v.empty() && !parse_css_colour(v, rgb, al)) arg_error(c.cmd, std::string("/") + key, "'" + v + "' is not a colour this command can read.", "Use #rgb, #rrggbb, rgb(...), or a CSS colour name.");
        (std::string_view(key) == "shadowColour" ? a.shadowColour : a.highlightColour) = v;
    }
    if (guide.guide.palette && !guide.guide.palette->empty()) a.palette = *guide.guide.palette;
    Json r = op_shade(c.doc, els, a, s, c.warnings);
    r["palette"] = a.palette.has_value() ? int(a.palette->size()) : 0;
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
    using namespace fa::vec::cmd;
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
    // ---- shape builders --------------------------------------------------------------------------------------------------
    const Json placementProps = placement_props();
    auto point_prop = [](const char* desc) { return Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 2}, {"maxItems", 2}, {"description", desc}}); };
    auto int_prop = [](const char* desc, int lo, int hi) { return Json::object({{"type", "integer"}, {"minimum", lo}, {"maximum", hi}, {"description", desc}}); };
    const Json shapeProps = Json::object(
        {{"kind", enum_prop({"star", "gear", "polygon", "arrow", "bubble", "ribbon"}, "The shape to build. star: points, innerRatio, roundness. gear: teeth, depth, toothWidth, hole. polygon: sides, cornerRadius. arrow: from, to, shaftWidth, headLength, headWidth, curve. bubble: width, height, cornerRadius, tailTo, tailWidth. ribbon: width, height, extent, drop, notch, foldFill.")},
         {"center", point_prop("The middle of the shape [x, y] in the parent's coordinates (star, gear, polygon, bubble, ribbon). Default: the middle of the drawing.")},
         {"radius", num_prop("star, gear, polygon: the radius to the tips (star, gear) or corners (polygon). Default: 40% of the drawing's shorter side.")},
         {"rotation", num_prop("star, gear, polygon: degrees clockwise on screen; where the first tip, tooth or corner points. Default -90 (up).")},
         {"points", int_prop("star: the number of tips, 3 to 128. Default 5.", 3, 128)},
         {"innerRatio", num_prop("star: the radius of the valleys as a fraction of `radius` (0.02 to 0.98). Default 0.5.")},
         {"roundness", num_prop("star: 0 sharp corners to 1 as round as the edges allow. Default 0.")},
         {"teeth", int_prop("gear: the number of teeth, 3 to 128. Default 8.", 3, 128)},
         {"depth", num_prop("gear: the height of a tooth as a fraction of `radius` (0.02 to 0.6). Default 0.2.")},
         {"toothWidth", num_prop("gear: the width of a tooth at its tip as a fraction of the distance between two teeth (0.1 to 0.9). Default 0.5.")},
         {"hole", num_prop("gear: the radius of the centre hole as a fraction of `radius` (0 for none). Default 0.3.")},
         {"sides", int_prop("polygon: the number of sides, 3 to 128. Default 6.", 3, 128)},
         {"cornerRadius", num_prop("polygon, bubble: the radius of the rounded corners, in the parent's units. polygon default 0; bubble default a quarter of the smaller side.")},
         {"from", point_prop("arrow: where the shaft starts [x, y].")},
         {"to", point_prop("arrow: the tip of the head [x, y].")},
         {"shaftWidth", num_prop("arrow: the thickness of the shaft. Default 12% of the length.")},
         {"headLength", num_prop("arrow: how far the head reaches back from the tip. Default 2.5 shaft widths.")},
         {"headWidth", num_prop("arrow: the width of the head. Default 2.2 shaft widths.")},
         {"curve", num_prop("arrow: the bend, -0.5 to 0.5 (the sagitta as a fraction of the length; 0.5 is a half circle); positive bends to the right of from -> to. Default 0.")},
         {"width", num_prop("bubble: the width of the box; ribbon: the width of the front band.")},
         {"height", num_prop("bubble: the height of the box; ribbon: the height of the front band.")},
         {"tail", Json::object({{"type", "boolean"}, {"description", "bubble: false for a box without a tail (default true)."}})},
         {"tailTo", point_prop("bubble: the tip of the tail [x, y], outside the box; the tail grows from the side nearest to it. Default: below the lower left.")},
         {"tailWidth", num_prop("bubble: the width of the tail where it leaves the box. Default 30% of the smaller side.")},
         {"tailRoundness", num_prop("bubble: 0 sharp tip to 1 round. Default 0.5.")},
         {"extent", num_prop("ribbon: how far each tail sticks out past the band. Default 20% of the width.")},
         {"drop", num_prop("ribbon: how much lower the tails sit than the band, also the size of the folds. Default 35% of the height.")},
         {"notch", num_prop("ribbon: the depth of the V cut in the tail ends; 0 for straight ends.")},
         {"foldFill", str_prop("ribbon: the colour of the folds (the tails are a step lighter). Default: darker shades of `fill`.")}});
    const Json shapeEditProps = Json::object({
        {"replace", str_prop("Redraw an existing shape (an id or selector of ONE path, rect, circle...) instead of adding one: its outline becomes the new shape, written in the element's own coordinates; its id, style and transform stay. Not with id, parent, before, transform, fill, stroke, strokeWidth, opacity or attributes. Not for a ribbon.")},
        {"parametric", bool_prop("true writes data-fa-shape (the kind) and data-fa-args (its arguments as JSON) on the element, so an editor can show them as parameters and call vector.shape again with `replace`. Any command that changes the outline of such an element removes both. Not for a ribbon.", false)}});
    defs.push_back({"vector.shape", "Add a star, gear, rounded polygon, arrow, speech bubble or ribbon to an SVG.",
        "Inserts a new element with exact geometry (the shapes AIs draw badly by hand) into an SVG file, SVG text or an svg layer of an image document, at the end of the drawing or of `parent`, with the `id`, `fill`, `stroke` and `transform` you give. "
        "kind \"star\" (points, innerRatio, roundness), \"gear\" (teeth, depth, toothWidth, hole), \"polygon\" (sides, cornerRadius: a rounded regular polygon), \"arrow\" (from, to, shaftWidth, headLength, headWidth, curve: straight or bent), "
        "\"bubble\" (width, height, cornerRadius, tailTo: a speech bubble whose tail points at the speaker) and \"ribbon\" (a banner with folded ends, a group of five paths). Curves are cubic Beziers. "
        "Sizes and positions are in the parent's coordinates (the viewBox for the top level); anything left out defaults to a good size in the middle of the drawing, so {\"kind\": \"star\"} works. "
        "Returns the new element, its bounds in the drawing and a preview as `$image`. With `replace` the shape is redrawn in an existing element, and with parametric: true the arguments are kept on it (data-fa-shape, data-fa-args). Example: {\"source\": \"assets/art/badge.svg\", \"kind\": \"gear\", \"teeth\": 12, \"center\": [50, 50], \"radius\": 30, \"fill\": \"#c0c4cc\"}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, merge_props(merge_props(placementProps, shapeProps), shapeEditProps)), geometry_props()), {"kind"}, false, cmd_shape});
    defs.push_back({"vector.blob", "Add a smooth organic shape or curve through or around a few points.",
        "Inserts a smooth closed blob (or, with closed: false, an open curve) built from a few [x, y] points. fit \"through\" (default): the curve passes through every point as a cardinal spline, `tension` 0 (straight lines) to 1.5, 0.5 is the usual smooth curve. "
        "fit \"around\": the points are a control polygon, a uniform B-spline that stays inside it and never touches it, always smooth. A closed blob needs 3 points, an open curve 2 and gets a stroke and no fill by default. "
        "Same placement arguments as vector.shape. Returns the new element and a preview as `$image`. Example: {\"source\": \"assets/art/cloud.svg\", \"points\": [[20,60],[35,35],[60,30],[80,50],[70,75],[40,80]], \"tension\": 0.6, \"fill\": \"#e8eef7\"}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, merge_props(placementProps, geometry_props())),
                    Json::object({{"points", Json::object({{"type", "array"}, {"items", point_prop("One [x, y] point in the parent's coordinates.")}, {"description", "The points the curve goes through or around, in order (3 or more when closed, 2 or more when open)."}})},
                                  {"closed", bool_prop("A closed blob (default) or an open curve.", true)},
                                  {"fit", enum_prop({"through", "around"}, "through: the curve passes through the points (default). around: the points are a control polygon the curve stays inside of.")},
                                  {"tension", num_prop("With fit \"through\": 0 straight lines, 0.5 smooth (default), up to 1.5 loose and overshooting.")}})),
        {"points"}, false, cmd_blob});
    defs.push_back({"vector.mirror", "Mirror shapes across a vertical or horizontal axis and weld the halves, or add the mirrored copy.",
        "For each picked shape, reflects it across the line x = at (axis \"vertical\") or y = at (axis \"horizontal\"). weld: true (default) unions the shape with its reflection into ONE path that keeps the shape's id and style, so you draw half a face, a wing or a vase and get the whole; "
        "points within `snap` of the axis are put on it first, so the halves meet without a hairline. weld: false adds the mirrored copy after the original instead (id <id>-mirror) with the exact curves. "
        "`at` is a number (the coordinate of the axis in the drawing), \"canvas\" (the drawing's middle line, default) or \"start\" / \"end\" (the shape's own left or top / right or bottom edge). Open lines cannot be welded and get a copy. "
        "Transforms are honoured. Returns a preview as `$image`. Example: {\"source\": \"assets/art/face.svg\", \"elements\": [\"half\"], \"axis\": \"vertical\", \"at\": 50}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, merge_props(elementsRequired, geometry_props())),
                    Json::object({{"axis", enum_prop({"vertical", "horizontal"}, "vertical: the mirror line is vertical, left and right swap. horizontal: top and bottom swap.")},
                                  {"at", Json::object({{"description", "Where the mirror line is: a number (x for a vertical axis, y for a horizontal one, in the drawing), \"canvas\" (default), \"start\" or \"end\" (the shape's own edge)."},
                                                       {"oneOf", Json::array({Json::object({{"type", "number"}}), Json::object({{"type", "string"}, {"enum", Json::array({"canvas", "start", "end"})}})})}})},
                                  {"weld", bool_prop("Union the shape with its reflection into one path (default). false adds the reflection as a copy.", true)},
                                  {"snap", num_prop("Points this close to the axis are put on it before welding, in drawing units. Default: twice the tolerance.")}})),
        {"elements", "axis"}, false, cmd_mirror});
    defs.push_back({"vector.text_to_path", "Turn text into path outlines with the engine's fonts, so it needs no font.",
        "Outlines text with the engine's own font stack (HarfBuzz shaping: kerning, ligatures, Arabic and other joining scripts, right-to-left; DejaVu Sans, the built-in families or a project .ttf / .otf) and inserts it as ONE <path> (fill-rule nonzero), "
        "so the picture does not depend on a font being installed. Give `text` (new outlines at `at`, with `size` the em height, `anchor` start / middle / end, `letterSpacing`, `lineSpacing`; \\n starts a line) or `elements` (ids of <text> elements of the drawing, which become paths with their own id, fill, class and transform; "
        "position, font-size and text-anchor are read from them; pass `font` since families cannot be looked up by name). Characters no font has are left out with a warning. "
        "Returns the element, `advance` (the width of the widest line, in the parent's units), `glyphs` and a preview as `$image`. Example: {\"source\": \"assets/art/title.svg\", \"text\": \"LEVEL 3\", \"font\": \"builtin:display\", \"size\": 24, \"at\": [50, 40], \"anchor\": \"middle\"}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, merge_props(placementProps, merge_props(elementsOptional, geometry_props()))),
                    Json::object({{"text", str_prop("The text to outline (UTF-8). A newline starts a new line.")},
                                  {"font", str_prop("\"\" / \"builtin\" (DejaVu Sans, the default), \"builtin:serif\", \"builtin:hand\", \"builtin:display\", \"builtin:blackletter\", \"builtin:pixel\", or a project-relative .ttf / .otf. The built-in DejaVu Sans fills in characters the font lacks.")},
                                  {"size", num_prop("The em height in the parent's units (the font size). Default 20% of the drawing's shorter side.")},
                                  {"at", point_prop("The start (see `anchor`) of the first baseline [x, y] in the parent's coordinates. Default: the middle of the drawing, centred.")},
                                  {"anchor", enum_prop({"start", "middle", "end"}, "Which point of each line sits at `at`: its start (default when `at` is given), middle (default without `at`) or end.")},
                                  {"letterSpacing", num_prop("Extra space after each letter, in ems. Default 0.")},
                                  {"lineSpacing", num_prop("A multiplier of the font's line height for several lines. Default 1.")}})),
        {}, false, cmd_text});
    defs.push_back({"vector.shade", "Add a shadow band and a highlight band to shapes from the light direction.",
        "For each picked shape builds a shadow band (the part of the shape on the side away from the light: the shape minus itself pushed toward the light by `depth`) and a highlight band (on the light side, `highlightDepth` wide), "
        "as two new paths right after the shape (ids <id>-shadow, <id>-highlight) with the shape's transform, so they stay inside it. Colours: if the project's style palette (assets.json style.palette) has the fill, the next darker and lighter palette colours (its ramp when one is declared); otherwise the fill shifted in OKLab by `strength`; `shadowColour` / `highlightColour` override. "
        "`light` is the direction TOWARDS the light in degrees counter-clockwise from +x (90 from above, 135 upper-left) or a name; default: the style guide's lightDirection, else 135. Shapes need a solid fill (or explicit colours). Returns the bands and the light used, plus a preview as `$image`. "
        "Example: {\"source\": \"assets/art/orb.svg\", \"elements\": [\"orb\"], \"light\": \"upper-left\", \"depth\": 6}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, merge_props(elementsRequired, geometry_props())),
                    Json::object({{"light", Json::object({{"description", "The direction TOWARDS the light: degrees counter-clockwise from +x (right) with y up, so 90 is from above and 135 from the upper left; or a name (\"upper-left\", \"top\"...); or \"style\". Default: the style guide's lightDirection, else 135."},
                                                          {"oneOf", Json::array({Json::object({{"type", "number"}}), Json::object({{"type", "string"}})})}})},
                                  {"depth", num_prop("The width of the shadow band in drawing units. Default 10% of the shape's smaller side.")},
                                  {"highlightDepth", num_prop("The width of the highlight band. Default 60% of the shadow's.")},
                                  {"shadow", bool_prop("Build the shadow band.", true)},
                                  {"highlight", bool_prop("Build the highlight band.", true)},
                                  {"shadowColour", str_prop("The shadow's colour. Default: derived from the fill.")},
                                  {"highlightColour", str_prop("The highlight's colour. Default: derived from the fill.")},
                                  {"strength", num_prop("How much lighter or darker the derived colours are, in OKLab lightness 0.01 to 0.6. Default 0.12.")},
                                  {"shadowOpacity", num_prop("0 to 1. Default 1.")},
                                  {"highlightOpacity", num_prop("0 to 1. Default 1.")}})),
        {"elements"}, false, cmd_shade});
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
        // A read-only command (vector.info) writes nothing, so it takes no `out` or `overwrite`: with them in its schema the whole command
        // would carry a write path (readOnlyHint false) and a caller could think it saves a file.
        Json props = d.props;
        if (d.readOnly)
            for (const char* k : {"out", "overwrite"}) props.erase(k);
        Json schema = Json::object({{"type", "object"}, {"properties", props}});
        if (!d.required.empty()) schema["required"] = d.required;
        // `source` and `document` are rewritten by the commands that edit; `out` is always the file to write
        for (const char* k : {"source", "document"})
            if (schema["properties"].contains(k)) schema["properties"][k]["x-fa-path"] = d.readOnly ? "read" : "write";
        if (schema["properties"].contains("out")) schema["properties"]["out"]["x-fa-path"] = "write";
        info.inputSchema = schema;
        const std::string name = d.name;
        auto fn = d.fn;
        const bool ro = d.readOnly;
        registry.add(info, [projectDir, name, fn, props, ro](const Json& args) {
            if (!args.is_object()) fail("invalid_argument", name + ": the arguments must be an object.", "Example: {\"source\": \"assets/art/badge.svg\"}.");
            return fa::vec::run(projectDir, args, name.c_str(), props, ro, [fn](fa::vec::Ctx& c) { return fn(c); });
        });
        registry.declare_capabilities(name, ro ? capability_sets::reads() : capability_sets::writes_project());
    }
    register_vector_rig_command(registry, projectDir);
    register_vector_edit_commands(registry, projectDir);
}

}  // namespace fa::assets_detail
