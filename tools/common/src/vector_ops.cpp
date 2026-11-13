// The operations of the vector.* commands (vector_ops.h). Shapes are measured in the drawing space (their transforms and their
// parents' applied), operated on there or in their own space, and written back as <path> data in the element's own space, so the
// element keeps its id, its place in the document, its transform and its style.
#include "vector_ops.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <functional>
#include <map>
#include <set>

#include "assets_internal.h"
#include "fa/core/strings.h"

namespace fa::vec {

using assets_detail::arg_error;
using assets_detail::fail;

namespace {

double r3(double v) { return std::round(v * 1000.0) / 1000.0; }

std::string label(const XNode& n) { return describe_element(n); }

Json rect_json(const Rect& r) { return Json::array({r3(r.x0), r3(r.y0), r3(r.width()), r3(r.height())}); }

int decimals_for(double tol) {
    if (!(tol > 0)) return 3;
    return std::clamp(int(std::ceil(-std::log10(tol))) + 1, 1, 6);
}

struct Loaded {
    XNode* node = nullptr;
    Path local;
    Mat ctm;
};

Loaded load_shape(XNode& n) {
    Loaded l;
    l.node = &n;
    std::string why;
    if (!shape_path(n, l.local, why))
        fail("invalid_svg", std::format("{}: {}.", label(n), why),
             "Fix the element in the SVG, or leave it out of `elements`.");
    l.ctm = element_ctm(n);
    return l;
}

// The drawing-space mapping must be reversible to write results back.
void require_invertible(const Loaded& l, const char* command) {
    if (!l.ctm.invertible())
        fail("invalid_svg",
             std::format("{} {}: its transform scales it to nothing, so a result cannot be written back.", command,
                         label(*l.node)),
             "Fix the transform (a scale of 0 collapses the shape).");
}

ClipGrid grid_of(const Settings& s) { return ClipGrid{s.gridDecimals}; }

bool even_odd(const XNode& n) { return inherited_prop(n, "fill-rule") == "evenodd"; }

// The clean area a shape fills, in the drawing space.
std::vector<Poly> shape_area(const Loaded& l, const Settings& s) {
    const Path canvas = transform_path(l.local, l.ctm);
    return normalize(fill_rings(canvas, s.tol * 0.5), even_odd(*l.node), grid_of(s));
}

std::vector<Ring> rings_of(const std::vector<Poly>& polys) {
    std::vector<Ring> out;
    for (const Poly& p : polys) out.push_back(Ring{p, true});
    return out;
}

// Polygons to a path: Beziers fitted to them, or the polygon itself.
Path polys_to_path(const std::vector<Poly>& polys, const Settings& s) {
    const std::vector<Ring> rings = rings_of(polys);
    if (!s.curves) return path_from_rings(rings);
    return fit_rings(rings, FitOptions{s.tol, s.cornerAngle});
}

// Gives every id in the subtree of `n` the `suffix`, taking the next free name, in place (the attribute keeps its position).
void rename_ids(SvgDoc& doc, XNode& n, const std::string& suffix) {
    if (const std::string* id = n.attr("id"); id && !id->empty()) {
        const std::string renamed = doc.unique_id(*id + suffix);
        n.set_attr("id", renamed);
    }
    for (XNode* k : n.elements()) rename_ids(doc, *k, suffix);
}

// A copy of `src` inserted after `after`; every id in it gets `suffix` (and the copy itself an id if `src` has none).
XNode* insert_copy(SvgDoc& doc, const XNode& src, XNode& after, const std::string& suffix) {
    const bool rootHasId = src.attr("id") && !src.attr("id")->empty();
    XNode* raw = doc.insert_after(&after, SvgDoc::clone(src));
    rename_ids(doc, *raw, suffix);
    if (!rootHasId) raw->set_attr("id", doc.unique_id(src.local() + suffix));
    return raw;
}

std::string id_or_label(const XNode& n) {
    const std::string* id = n.attr("id");
    return id && !id->empty() ? *id : label(n);
}

}  // namespace

// ---- settings --------------------------------------------------------------------------------------------------------

Settings with_tolerance(Settings s, double tol) {
    s.tol = tol;
    s.gridDecimals = std::clamp(int(std::ceil(-std::log10(tol / 20.0))), 0, 6);
    s.outDecimals = decimals_for(tol);
    return s;
}

Settings default_settings(const Rect& canvas) {
    const double side = std::max({canvas.width(), canvas.height(), 1.0});
    return with_tolerance(Settings{}, side / 4000.0);
}

Settings local_settings(const Settings& s, double scale) {
    Settings l = with_tolerance(s, s.tol / std::max(scale, 1e-9));
    l.curves = s.curves;
    l.cornerAngle = s.cornerAngle;
    return l;
}

std::vector<XNode*> expand_shapes(const std::vector<XNode*>& picked, const char* command,
                                  std::vector<std::string>& warnings) {
    std::vector<XNode*> out;
    std::set<XNode*> seen;
    for (XNode* p : picked) {
        std::vector<XNode*> found;
        shapes_under(*p, found);
        if (found.empty())
            warnings.push_back(std::format("{} has no shape in it (only path, rect, circle, ellipse, line, polyline "
                                           "and polygon are read), so it was skipped.",
                                           label(*p)));
        for (XNode* s : found)
            if (seen.insert(s).second) out.push_back(s);
    }
    if (out.empty())
        fail("invalid_argument", std::format("{}: none of the picked elements is a shape.", command),
             "Pick a path, rect, circle, ellipse, line, polyline or polygon, or a group that holds some. Run "
             "vector.info to list them.");
    return out;
}

std::vector<std::string> document_warnings(const SvgDoc& doc) {
    std::vector<std::string> w;
    bool style = false, use = false;
    for (XNode* n : doc.all_elements()) {
        if (n->local() == "style") {
            for (const XItem& k : n->kids)
                if (!k.el && k.text.find_first_not_of(" \t\r\n") != std::string::npos) style = true;
        }
        if (n->local() == "use") use = true;
    }
    if (style)
        w.push_back("The SVG has CSS rules in <style>; fill, stroke and fill-rule are read from attributes and "
                    "style=\"...\" only, so a rule in <style> is not seen by the operations.");
    if (use)
        w.push_back(
            "The SVG has <use> elements; they are not moved, repeated or edited (only the shapes they point to are).");
    return w;
}

// ---- boolean ---------------------------------------------------------------------------------------------------------

Json op_boolean(SvgDoc& doc, BoolOp op, const std::vector<XNode*>& picked, const Settings& s, bool keepInputs,
                std::vector<std::string>& warnings) {
    const char* cmd = "vector.boolean";
    const std::vector<XNode*> shapes = expand_shapes(picked, cmd, warnings);
    if (shapes.size() < 2)
        fail("invalid_argument",
             std::format("{} /elements: a path operation needs at least two shapes, found {} ({}).", cmd, shapes.size(),
                         label(*shapes[0])),
             "Pick two or more shapes, or a group that holds several: [\"outer\", \"hole\"].");
    std::vector<Loaded> in;
    std::vector<std::vector<Poly>> area;
    int before = 0;
    for (XNode* n : shapes) {
        in.push_back(load_shape(*n));
        before += node_count(in.back().local);
        area.push_back(shape_area(in.back(), s));
        if (area.back().empty())
            warnings.push_back(std::format(
                "{} covers no area (an open line, or a shape of zero size), so it takes no part in the result.",
                label(*n)));
    }
    require_invertible(in[0], cmd);
    const ClipGrid g = grid_of(s);
    std::vector<Poly> acc = area[0];
    if (op == BoolOp::Subtract) {
        std::vector<Poly> clip = area[1];
        for (std::size_t i = 2; i < area.size(); ++i) clip = boolean_op(BoolOp::Union, clip, area[i], g);
        acc = boolean_op(BoolOp::Subtract, acc, clip, g);
    } else {
        for (std::size_t i = 1; i < area.size(); ++i) acc = boolean_op(op, acc, area[i], g);
    }
    if (acc.empty()) {
        const char* what = op == BoolOp::Intersect  ? "the shapes do not overlap"
                           : op == BoolOp::Subtract ? "the first shape is covered completely by the others"
                                                    : "nothing is left";
        fail("empty_result", std::format("{} /elements: the result is empty: {}.", cmd, what),
             op == BoolOp::Intersect ? "Intersect keeps only what all the shapes cover; move them so they overlap."
                                     : "Check the order: subtract removes the later shapes from the first.");
    }
    const Path canvas = polys_to_path(acc, s);
    const Mat inv = inverse(in[0].ctm);
    const Settings ls = local_settings(s, in[0].ctm.scale());
    const Path local = transform_path(canvas, inv);
    const int after = node_count(local);
    XNode* first = in[0].node;
    set_path_geometry(*first, path_to_data(local, ls.outDecimals));
    std::vector<std::string> removed;
    if (!keepInputs)
        for (std::size_t i = 1; i < in.size(); ++i) {
            removed.push_back(id_or_label(*in[i].node));
            doc.remove(in[i].node);
        }
    Json r = Json::object(
        {{"result", id_or_label(*first)}, {"nodes", after}, {"nodesBefore", before}, {"curves", has_curves(local)}});
    r["removed"] = removed;
    r["bounds"] = rect_json(path_bounds(canvas));
    return r;
}

// ---- offset ----------------------------------------------------------------------------------------------------------

Json op_offset(SvgDoc& doc, const std::vector<XNode*>& picked, double distance, Join join, double miterLimit, bool copy,
               const Settings& s, std::vector<std::string>& warnings) {
    const char* cmd = "vector.offset";
    const std::vector<XNode*> shapes = expand_shapes(picked, cmd, warnings);
    struct Pending {
        XNode* node;
        std::string data;
        int nodes;
        Rect bounds;
    };
    std::vector<Pending> pending;
    for (XNode* n : shapes) {
        Loaded l = load_shape(*n);
        require_invertible(l, cmd);
        const std::vector<Poly> area = shape_area(l, s);
        if (area.empty()) {
            warnings.push_back(std::format(
                "{} covers no area (an open line has none: use vector.stroke_to_path first), so it was skipped.",
                label(*n)));
            continue;
        }
        const std::vector<Poly> grown = offset_rings(area, distance, join, miterLimit, s.tol * 0.5, grid_of(s));
        if (grown.empty())
            fail("empty_result",
                 std::format("{} /distance: the inset of {} leaves nothing of {}.", cmd, r3(-distance), label(*n)),
                 "Use a smaller distance: the shape is narrower than twice the inset.");
        const Path canvas = polys_to_path(grown, s);
        const Path local = transform_path(canvas, inverse(l.ctm));
        const Settings ls = local_settings(s, l.ctm.scale());
        pending.push_back({n, path_to_data(local, ls.outDecimals), node_count(local), path_bounds(canvas)});
    }
    if (pending.empty())
        fail("invalid_argument", std::format("{} /elements: none of the shapes covers an area.", cmd),
             "Offset grows or shrinks what a shape fills; pick closed shapes.");
    Json items = Json::array();
    for (const Pending& p : pending) {
        XNode* target = p.node;
        if (copy) target = insert_copy(doc, *p.node, *p.node, "-offset");
        set_path_geometry(*target, p.data);
        items.push_back(
            Json::object({{"element", id_or_label(*target)}, {"nodes", p.nodes}, {"bounds", rect_json(p.bounds)}}));
    }
    return Json::object({{"offset", r3(distance)}, {"results", items}});
}

// ---- stroke to path ----------------------------------------------------------------------------------------------------

namespace {

bool visible_paint(const std::string& v) { return !v.empty() && v != "none" && v != "transparent"; }

std::vector<double> parse_dashes(const std::string& v) {
    std::vector<double> out;
    if (v.empty() || v == "none") return out;
    std::size_t i = 0;
    while (i < v.size()) {
        while (i < v.size() && (v[i] == ',' || v[i] == ' ' || v[i] == '\t' || v[i] == '\n')) ++i;
        std::size_t e = i;
        while (e < v.size() && v[e] != ',' && v[e] != ' ' && v[e] != '\t' && v[e] != '\n') ++e;
        if (e > i) {
            double d = 0;
            if (!parse_length(v.substr(i, e - i), d) || d < 0) return {};
            out.push_back(d);
        }
        i = e;
    }
    double sum = 0;
    for (double d : out) sum += d;
    if (sum <= 0) return {};
    return out;
}

double num_prop(const XNode& n, const char* name, double fallback) {
    const std::string v = inherited_prop(n, name);
    double d = 0;
    return !v.empty() && parse_length(v, d) ? d : fallback;
}

}  // namespace

Json op_stroke_to_path(SvgDoc& doc, const std::vector<XNode*>& picked, const StrokeOverrides& ov, const Settings& s,
                       std::vector<std::string>& warnings) {
    const char* cmd = "vector.stroke_to_path";
    const std::vector<XNode*> shapes = expand_shapes(picked, cmd, warnings);
    struct Pending {
        XNode* node;
        std::string data;
        std::string paint, opacity;
        bool keepsFill;
        int nodes;
        Rect bounds;
    };
    std::vector<Pending> pending;
    for (XNode* n : shapes) {
        Loaded l = load_shape(*n);
        std::string paint = inherited_prop(*n, "stroke");
        if (!visible_paint(paint)) {
            if (!ov.paint) {
                warnings.push_back(
                    std::format("{} has no stroke, so it was skipped (give `color` to stroke it anyway).", label(*n)));
                continue;
            }
            paint = *ov.paint;
        }
        require_invertible(l, cmd);
        StrokeStyle st;
        st.width = ov.width ? *ov.width : num_prop(*n, "stroke-width", 1.0);
        if (!(st.width > 0)) {
            warnings.push_back(std::format("{} has a stroke width of 0, so it was skipped.", label(*n)));
            continue;
        }
        const std::string cap = inherited_prop(*n, "stroke-linecap");
        st.cap = ov.cap ? *ov.cap : cap == "round" ? Cap::Round : cap == "square" ? Cap::Square : Cap::Butt;
        const std::string join = inherited_prop(*n, "stroke-linejoin");
        st.join = ov.join ? *ov.join : join == "round" ? Join::Round : join == "bevel" ? Join::Bevel : Join::Miter;
        st.miterLimit = ov.miterLimit ? *ov.miterLimit : num_prop(*n, "stroke-miterlimit", 4.0);
        st.dashes = ov.dashes ? *ov.dashes : parse_dashes(inherited_prop(*n, "stroke-dasharray"));
        st.dashOffset = ov.dashOffset ? *ov.dashOffset : num_prop(*n, "stroke-dashoffset", 0.0);
        if (paint.rfind("url(", 0) == 0)
            warnings.push_back(std::format("{} is stroked with {}: as a fill the gradient or pattern spreads over the "
                                           "outline's own box, so it may look different.",
                                           label(*n), paint));
        const Settings ls = local_settings(s, l.ctm.scale());
        const std::vector<Poly> outline = stroke_outline(l.local, st, ls.tol * 0.5, grid_of(ls));
        if (outline.empty()) {
            warnings.push_back(std::format("{} has a stroke that covers nothing (an empty path, or a zero-length piece "
                                           "with butt caps), so it was skipped.",
                                           label(*n)));
            continue;
        }
        const Path local = polys_to_path(outline, ls);
        const std::string fill = inherited_prop(*n, "fill");
        Pending p;
        p.node = n;
        p.data = path_to_data(local, ls.outDecimals);
        p.paint = paint;
        p.opacity = inherited_prop(*n, "stroke-opacity");
        p.keepsFill = fill.empty() || visible_paint(fill);  // an unset fill is black
        p.nodes = node_count(local);
        p.bounds = path_bounds(transform_path(local, l.ctm));
        pending.push_back(std::move(p));
    }
    if (pending.empty())
        fail("invalid_argument", std::format("{} /elements: none of the shapes has a stroke to convert.", cmd),
             "Give the shape a stroke (stroke=\"#000\" stroke-width=\"4\"), or pass `color` and `width`.");
    static const char* const kStrokeProps[] = {"stroke-width",      "stroke-linecap",   "stroke-linejoin",
                                               "stroke-miterlimit", "stroke-dasharray", "stroke-dashoffset",
                                               "stroke-opacity"};
    auto drop_stroke = [&](XNode& n) {
        set_prop(n, "stroke", "none");
        for (const char* k : kStrokeProps) remove_prop(n, k);
    };
    auto as_fill = [&](XNode& n, const Pending& p) {
        set_prop(n, "fill", p.paint);
        if (!p.opacity.empty() && p.opacity != "1")
            set_prop(n, "fill-opacity", p.opacity);
        else
            remove_prop(n, "fill-opacity");
        drop_stroke(n);
    };
    Json items = Json::array();
    for (const Pending& p : pending) {
        XNode* outline = p.node;
        std::string role = "stroke";
        if (p.keepsFill) {
            // the shape keeps its fill under the original id; the stroke becomes a new element after it
            outline = insert_copy(doc, *p.node, *p.node, "-stroke");
            drop_stroke(*p.node);
            role = "stroke outline added after the fill";
        }
        set_path_geometry(*outline, p.data);
        as_fill(*outline, p);
        items.push_back(Json::object({{"element", id_or_label(*outline)},
                                      {"from", id_or_label(*p.node)},
                                      {"role", role},
                                      {"nodes", p.nodes},
                                      {"bounds", rect_json(p.bounds)}}));
    }
    return Json::object({{"results", items}});
}

// ---- simplify and smooth -----------------------------------------------------------------------------------------------

namespace {

Json rewrite_shapes(SvgDoc&, const std::vector<XNode*>& shapes, const char* cmd, const Settings& s,
                    const std::function<Path(const Path&, const Settings&)>& fn, std::vector<std::string>& warnings) {
    struct Pending {
        XNode* node;
        std::string data;
        int before, after;
    };
    std::vector<Pending> pending;
    Json unchanged = Json::array();
    for (XNode* n : shapes) {
        Loaded l = load_shape(*n);
        if (l.local.empty()) {
            warnings.push_back(std::format("{} has no geometry, so it was skipped.", label(*n)));
            continue;
        }
        const Settings ls = local_settings(s, l.ctm.scale());
        const Path out = fn(l.local, ls);
        const std::string oldData = path_to_data(l.local, ls.outDecimals), newData = path_to_data(out, ls.outDecimals);
        if (oldData == newData) {
            unchanged.push_back(id_or_label(*n));
            continue;
        }
        pending.push_back({n, newData, node_count(l.local), node_count(out)});
    }
    Json items = Json::array();
    for (const Pending& p : pending) {
        set_path_geometry(*p.node, p.data);
        items.push_back(
            Json::object({{"element", id_or_label(*p.node)}, {"nodesBefore", p.before}, {"nodes", p.after}}));
    }
    (void)cmd;
    Json r = Json::object({{"results", items}});
    if (!unchanged.empty()) r["unchanged"] = unchanged;
    return r;
}

}  // namespace

Json op_simplify(SvgDoc& doc, const std::vector<XNode*>& picked, const Settings& s,
                 std::vector<std::string>& warnings) {
    const std::vector<XNode*> shapes = expand_shapes(picked, "vector.simplify", warnings);
    Json r = rewrite_shapes(
        doc, shapes, "vector.simplify", s,
        [&](const Path& p, const Settings& ls) {
            Path out = simplify_path(p, ls.tol, s.cornerAngle);
            // a path with fewer nodes only: never swap a shape for one with more
            return node_count(out) < node_count(p) ? out : p;
        },
        warnings);
    r["tolerance"] = r3(s.tol);
    return r;
}

Json op_smooth(SvgDoc& doc, const std::vector<XNode*>& picked, double smoothness, const Settings& s,
               std::vector<std::string>& warnings) {
    const std::vector<XNode*> shapes = expand_shapes(picked, "vector.smooth", warnings);
    Json r = rewrite_shapes(
        doc, shapes, "vector.smooth", s,
        [&](const Path& p, const Settings&) { return smooth_path(p, smoothness, s.cornerAngle); }, warnings);
    r["smoothness"] = smoothness;
    return r;
}

// ---- bounds, moving ----------------------------------------------------------------------------------------------------

bool unit_bounds(XNode& unit, bool visual, Rect& out, std::string& why) {
    std::vector<XNode*> shapes;
    shapes_under(unit, shapes);
    out = Rect{};
    for (XNode* n : shapes) {
        Path p;
        if (!shape_path(*n, p, why)) {
            why = label(*n) + ": " + why;
            return false;
        }
        if (p.empty()) continue;
        const Mat ctm = element_ctm(*n);
        Rect r = path_bounds(transform_path(p, ctm));
        if (visual && visible_paint(inherited_prop(*n, "stroke"))) {
            const double half = num_prop(*n, "stroke-width", 1.0) * ctm.scale() * 0.5;
            r.x0 -= half;
            r.y0 -= half;
            r.x1 += half;
            r.y1 += half;
        }
        out.add(r);
    }
    if (out.empty()) {
        why = label(unit) + " has no shape with an area or a line to measure";
        return false;
    }
    return true;
}

namespace {

Rect bounds_or_fail(XNode& unit, bool visual, const char* cmd) {
    Rect r;
    std::string why;
    if (!unit_bounds(unit, visual, r, why))
        fail("invalid_argument", std::format("{} /elements: {}.", cmd, why),
             "Pick shapes, or groups that hold shapes.");
    return r;
}

bool near_identity(const Mat& m) {
    return std::fabs(m.a - 1) < 1e-9 && std::fabs(m.d - 1) < 1e-9 && std::fabs(m.b) < 1e-9 && std::fabs(m.c) < 1e-9 &&
           std::fabs(m.e) < 1e-9 && std::fabs(m.f) < 1e-9;
}
bool pure_translation(const Mat& m) {
    return std::fabs(m.a - 1) < 1e-12 && std::fabs(m.d - 1) < 1e-12 && std::fabs(m.b) < 1e-12 && std::fabs(m.c) < 1e-12;
}

std::string translate_text(double dx, double dy) {
    return std::format("translate({} {})", format_number(dx, 4), format_number(dy, 4));
}

}  // namespace

// Applies `m` (a transform of the drawing space, written `mText`) to the element: its own transform becomes the one that, inside
// its parents, moves it by `m`. The attribute keeps the readable form where the parents do not transform.
void apply_canvas_transform(XNode& n, const Mat& m, const std::string& mText, const char* cmd) {
    const Mat P = parent_ctm(n);
    const Mat T = own_transform(n);
    if (near_identity(P)) {
        if (pure_translation(m) && pure_translation(T)) {
            const Mat sum = m * T;
            if (std::fabs(sum.e) < 1e-9 && std::fabs(sum.f) < 1e-9)
                n.remove_attr("transform");
            else
                n.set_attr("transform", transform_to_string(sum, 4));
            return;
        }
        const std::string cur = n.attr_or("transform");
        n.set_attr("transform", cur.empty() ? mText : mText + " " + cur);
        return;
    }
    if (!P.invertible())
        fail("invalid_svg", std::format("{} {}: a parent transform scales it to nothing.", cmd, label(n)),
             "Fix the transform of the group.");
    const Mat nt = inverse(P) * m * P * T;
    if (near_identity(nt))
        n.remove_attr("transform");
    else
        n.set_attr("transform", transform_to_string(nt, 6));
}

// ---- align and distribute ----------------------------------------------------------------------------------------------

Json op_align(SvgDoc& doc, const std::vector<XNode*>& units, const AlignArgs& a, std::vector<std::string>& warnings) {
    const char* cmd = "vector.align";
    (void)warnings;
    if (a.horizontal.empty() && a.vertical.empty())
        arg_error(cmd, "/horizontal", "nothing to align: neither `horizontal` nor `vertical` is set.",
                  "Set horizontal to left, center or right and/or vertical to top, middle or bottom.");
    std::vector<Rect> bounds;
    Rect all;
    for (XNode* u : units) {
        bounds.push_back(bounds_or_fail(*u, a.visual, cmd));
        all.add(bounds.back());
    }
    Rect target = all;
    if (a.to == "canvas")
        target = doc.canvas();
    else if (a.to == "key") {
        if (!a.key)
            arg_error(cmd, "/key", "`to` is \"key\" but no `key` element was given.",
                      "Give the element the others align to: {\"to\": \"key\", \"key\": \"badge\"}.");
        target = bounds_or_fail(*a.key, a.visual, cmd);
    } else if (units.size() < 2) {
        arg_error(cmd, "/elements", "aligning to the selection needs at least two elements.",
                  "Pass several elements, or {\"to\": \"canvas\"}.");
    }
    Json moves = Json::array();
    for (std::size_t i = 0; i < units.size(); ++i) {
        if (a.to == "key" && units[i] == a.key) continue;
        const Rect& b = bounds[i];
        double dx = 0, dy = 0;
        if (a.horizontal == "left")
            dx = target.x0 - b.x0;
        else if (a.horizontal == "center")
            dx = target.center().x - b.center().x;
        else if (a.horizontal == "right")
            dx = target.x1 - b.x1;
        if (a.vertical == "top")
            dy = target.y0 - b.y0;
        else if (a.vertical == "middle")
            dy = target.center().y - b.center().y;
        else if (a.vertical == "bottom")
            dy = target.y1 - b.y1;
        if (std::fabs(dx) < 1e-9 && std::fabs(dy) < 1e-9) continue;
        apply_canvas_transform(*units[i], translation(dx, dy), translate_text(dx, dy), cmd);
        moves.push_back(Json::object({{"element", id_or_label(*units[i])}, {"dx", r3(dx)}, {"dy", r3(dy)}}));
    }
    Json r = Json::object({{"moved", moves}, {"target", rect_json(target)}});
    if (moves.empty()) r["note"] = "Everything was already aligned.";
    return r;
}

Json op_distribute(SvgDoc& doc, const std::vector<XNode*>& units, const DistributeArgs& a,
                   std::vector<std::string>& warnings) {
    const char* cmd = "vector.distribute";
    (void)doc;
    (void)warnings;
    const std::size_t minUnits = a.spacing ? 2 : 3;
    if (units.size() < minUnits)
        arg_error(cmd, "/elements",
                  std::format("distributing {} needs at least {} elements, got {}.",
                              a.spacing ? "with a fixed `spacing`" : "evenly", minUnits, units.size()),
                  a.spacing ? "Pass two or more elements."
                            : "Pass three or more elements, or give `spacing` for a fixed gap.");
    const bool horiz = a.axis == Axis::Horizontal;
    struct Item {
        XNode* node;
        Rect b;
    };
    std::vector<Item> items;
    for (XNode* u : units) items.push_back({u, bounds_or_fail(*u, a.visual, cmd)});
    auto lo = [&](const Rect& r) { return horiz ? r.x0 : r.y0; };
    auto hi = [&](const Rect& r) { return horiz ? r.x1 : r.y1; };
    auto mid = [&](const Rect& r) { return (lo(r) + hi(r)) * 0.5; };
    std::stable_sort(items.begin(), items.end(), [&](const Item& x, const Item& y) { return mid(x.b) < mid(y.b); });
    std::vector<double> shift(items.size(), 0.0);
    const std::size_t n = items.size();
    if (a.spacing) {
        double pos = lo(items[0].b);
        for (std::size_t i = 0; i < n; ++i) {
            shift[i] = pos - lo(items[i].b);
            pos += (hi(items[i].b) - lo(items[i].b)) + *a.spacing;
        }
    } else if (a.by == "centers") {
        const double c0 = mid(items[0].b), cn = mid(items[n - 1].b);
        for (std::size_t i = 0; i < n; ++i) shift[i] = c0 + (cn - c0) * double(i) / double(n - 1) - mid(items[i].b);
    } else {
        double span = hi(items[n - 1].b) - lo(items[0].b), sum = 0;
        for (const Item& it : items) sum += hi(it.b) - lo(it.b);
        const double gap = (span - sum) / double(n - 1);
        double pos = lo(items[0].b);
        for (std::size_t i = 0; i < n; ++i) {
            shift[i] = pos - lo(items[i].b);
            pos += (hi(items[i].b) - lo(items[i].b)) + gap;
        }
    }
    Json moves = Json::array();
    for (std::size_t i = 0; i < n; ++i) {
        if (std::fabs(shift[i]) < 1e-9) continue;
        const double dx = horiz ? shift[i] : 0, dy = horiz ? 0 : shift[i];
        apply_canvas_transform(*items[i].node, translation(dx, dy), translate_text(dx, dy), cmd);
        moves.push_back(Json::object({{"element", id_or_label(*items[i].node)}, {"dx", r3(dx)}, {"dy", r3(dy)}}));
    }
    Json r = Json::object({{"moved", moves}, {"order", Json::array()}});
    for (const Item& it : items) r["order"].push_back(id_or_label(*it.node));
    if (moves.empty()) r["note"] = "The elements were already evenly spaced.";
    return r;
}

// ---- repeat ------------------------------------------------------------------------------------------------------------

Json op_repeat(SvgDoc& doc, XNode& unit, const RepeatArgs& a, std::vector<std::string>& warnings) {
    const char* cmd = "vector.repeat";
    (void)warnings;
    const Rect b = bounds_or_fail(unit, a.visual, cmd);
    const P c0 = b.center();
    struct Copy {
        Mat m;
        std::string text;
    };
    std::vector<Copy> copies;  // not counting the original
    auto spin_of = [&](int index, P about) {
        Copy c;
        if (std::fabs(a.rotation) < 1e-12) return c;
        c.m = rotation(a.rotation * index, about.x, about.y);
        c.text = std::format("rotate({} {} {})", format_number(a.rotation * index, 4), format_number(about.x, 4),
                             format_number(about.y, 4));
        return c;
    };
    auto join = [](const Copy& outer, const Copy& inner) {
        Copy c;
        c.m = outer.m * inner.m;
        c.text = outer.text.empty() ? inner.text : inner.text.empty() ? outer.text : outer.text + " " + inner.text;
        return c;
    };
    if (a.mode == "grid") {
        const double stepX = b.width() + a.gapX, stepY = b.height() + a.gapY;
        int index = 0;
        for (int r = 0; r < a.rows; ++r)
            for (int col = 0; col < a.columns; ++col, ++index) {
                if (index == 0) continue;
                Copy orbit;
                orbit.m = translation(col * stepX, r * stepY);
                orbit.text = translate_text(col * stepX, r * stepY);
                copies.push_back(join(orbit, spin_of(index, c0)));
            }
    } else {
        P centre;
        if (a.center)
            centre = *a.center;
        else if (a.radius)
            centre = {c0.x, c0.y + *a.radius};
        else
            arg_error(cmd, "/center", "radial repeat needs `center` or `radius`.",
                      "Give the circle's centre ({\"center\": [50, 50]}), or a radius ({\"radius\": 30}) to put the "
                      "centre that far below the element.");
        if (dist(centre, c0) < 1e-9)
            arg_error(cmd, "/center", "the centre is at the element's own centre, so every copy would land on it.",
                      "Move the centre away from the element, or give a `radius`.");
        const int count = a.count;
        const double step = a.sweep >= 360.0 - 1e-9 ? a.sweep / count : (count > 1 ? a.sweep / (count - 1) : 0.0);
        for (int i = 1; i < count; ++i) {
            const double ang = step * i;
            Copy orbit;
            if (a.orient) {
                orbit.m = rotation(ang, centre.x, centre.y);
                orbit.text = std::format("rotate({} {} {})", format_number(ang, 4), format_number(centre.x, 4),
                                         format_number(centre.y, 4));
            } else {
                const P moved = rotation(ang, centre.x, centre.y).apply(c0);
                orbit.m = translation(moved.x - c0.x, moved.y - c0.y);
                orbit.text = translate_text(moved.x - c0.x, moved.y - c0.y);
            }
            copies.push_back(join(orbit, spin_of(i, c0)));
        }
    }
    Json ids = Json::array();
    XNode* last = &unit;
    int n = 1;
    for (const Copy& c : copies) {
        XNode* copy = insert_copy(doc, unit, *last, "-" + std::to_string(++n));
        apply_canvas_transform(*copy, c.m, c.text.empty() ? "translate(0 0)" : c.text, cmd);
        ids.push_back(id_or_label(*copy));
        last = copy;
    }
    return Json::object({{"original", id_or_label(unit)}, {"copies", ids}, {"count", int(copies.size()) + 1}});
}

// ---- info --------------------------------------------------------------------------------------------------------------

Json op_info(const SvgDoc& doc, const std::vector<XNode*>& only, std::vector<std::string>& warnings) {
    Json items = Json::array();
    std::vector<XNode*> nodes;
    if (only.empty()) {
        for (XNode* n : doc.all_elements())
            if (n != doc.root()) nodes.push_back(n);
    } else {
        std::set<XNode*> seen;
        for (XNode* p : only) {
            std::vector<XNode*> sub;
            std::function<void(XNode*)> walk = [&](XNode* x) {
                sub.push_back(x);
                for (XNode* k : x->elements()) walk(k);
            };
            walk(p);
            for (XNode* x : sub)
                if (seen.insert(x).second) nodes.push_back(x);
        }
    }
    const std::size_t kMax = 300;
    std::size_t listed = 0;
    for (XNode* n : nodes) {
        const bool shape = is_shape_element(*n), group = is_group_element(*n);
        if (!shape && !group) continue;
        if (!shape && n->parent && in_inert_subtree(*n)) continue;
        if (shape && in_inert_subtree(*n) && only.empty()) continue;
        if (++listed > kMax) {
            warnings.push_back(std::format("The list stops after {} elements; pass `elements` to see the rest.", kMax));
            break;
        }
        Json e = Json::object({{"tag", n->local()}});
        if (const std::string* id = n->attr("id")) e["id"] = *id;
        e["path"] = label(*n);
        Rect r;
        std::string why;
        if (unit_bounds(*n, false, r, why)) e["bounds"] = rect_json(r);
        if (shape) {
            Path p;
            if (shape_path(*n, p, why)) {
                e["nodes"] = node_count(p);
                e["curves"] = has_curves(p);
                e["closed"] = has_closed(p);
            } else {
                e["problem"] = why;
            }
        } else {
            e["children"] = int(n->elements().size());
        }
        for (const char* k : {"fill", "stroke", "stroke-width", "transform"}) {
            const std::string v = std::string(k) == "transform" ? n->attr_or("transform") : own_prop(*n, k);
            if (!v.empty()) e[k] = v;
        }
        items.push_back(std::move(e));
    }
    const Rect c = doc.canvas();
    const P d = doc.declared_size();
    Json r = Json::object(
        {{"canvas", rect_json(c)}, {"declaredSize", Json::array({r3(d.x), r3(d.y)})}, {"elements", items}});
    return r;
}

}  // namespace fa::vec
