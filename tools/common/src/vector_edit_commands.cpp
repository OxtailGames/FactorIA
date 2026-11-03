// The vector.* commands that edit a drawing by hand (docs/VECTOR.md, "Editing by hand"): vector.add, nodes, set_path, set, transform,
// delete, duplicate, group, ungroup, reorder and assign_ids. They are what the editor's Vector panel runs for every gesture, and what an
// AI calls to draw and fix SVG without writing the markup. Like the other vector.* commands they keep ids, groups and transforms, take
// `source` | `svg` | `document` + `layer`, and return a preview.
#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/tooling/vector_edit.h"
#include "vector_cmd.h"

namespace fa::vec {

using assets_detail::arg_error;
using assets_detail::fail;
using namespace cmd;

namespace {

double r3(double v) { return std::round(v * 1000.0) / 1000.0; }
Json rect_json(const Rect& r) { return Json::array({r3(r.x0), r3(r.y0), r3(r.width()), r3(r.height())}); }

bool is_ancestor(const XNode* a, const XNode* n) {
    for (const XNode* p = n->parent; p; p = p->parent)
        if (p == a) return true;
    return false;
}

// Drops the elements that sit inside another picked element (a group moves its children already).
std::vector<XNode*> outermost(const std::vector<XNode*>& picked) {
    std::vector<XNode*> out;
    for (XNode* n : picked) {
        bool inside = false;
        for (XNode* o : picked)
            if (o != n && is_ancestor(o, n)) inside = true;
        if (!inside) out.push_back(n);
    }
    return out;
}

void refuse_root(Ctx& c, const std::vector<XNode*>& els, const char* key) {
    for (XNode* n : els)
        if (n == c.doc.root())
            arg_error(c.cmd, std::string("/") + key, "the root <svg> cannot be picked here.", "Name a shape or a group inside the drawing (vector.info lists them).");
}

std::vector<XNode*> in_document_order(Ctx& c, const std::vector<XNode*>& els) {
    std::set<XNode*> want(els.begin(), els.end());
    std::vector<XNode*> out;
    for (XNode* n : c.doc.all_elements())
        if (want.count(n)) out.push_back(n);
    return out;
}

// A schema property that also accepts null (null removes the property).
Json nullable(Json prop) {
    if (prop.contains("type") && prop["type"].is_string()) prop["type"] = Json::array({prop["type"].get<std::string>(), "null"});
    if (prop.contains("enum")) prop["enum"].push_back(nullptr);
    return prop;
}

Json refs_json(const std::vector<std::string>& v) {
    Json a = Json::array();
    for (const std::string& s : v) a.push_back(s);
    return a;
}

Mat inverse_or_fail(const Mat& m, Ctx& c, const XNode& n) {
    if (!m.invertible()) fail("invalid_svg", std::format("{}: {} sits inside a transform that scales it to nothing.", c.cmd, describe_element(n)), "Fix the transform of the group.");
    return inverse(m);
}

// Moves `node` (and everything in it) under `parent`, in front of `before` (null = at the end). The element is rebuilt by clone, so the
// pointer you had is dead; the new one is returned.
XNode* move_node(SvgDoc& doc, XNode* node, XNode* parent, XNode* before) {
    std::unique_ptr<XNode> copy = SvgDoc::clone(*node);
    doc.remove(node);
    if (before) return doc.insert_before(before, std::move(copy));
    return doc.append_child(parent, std::move(copy));
}

void set_transform_attr(XNode& n, const Mat& m) {
    const bool identity = std::fabs(m.a - 1) < 1e-9 && std::fabs(m.d - 1) < 1e-9 && std::fabs(m.b) < 1e-9 && std::fabs(m.c) < 1e-9 && std::fabs(m.e) < 1e-9 && std::fabs(m.f) < 1e-9;
    if (identity) n.remove_attr("transform");
    else n.set_attr("transform", transform_to_string(m, 6));
}

bool is_identity_like(const Mat& m) {
    return std::fabs(m.a - 1) < 1e-12 && std::fabs(m.d - 1) < 1e-12 && std::fabs(m.b) < 1e-12 && std::fabs(m.c) < 1e-12 && std::fabs(m.e) < 1e-12 && std::fabs(m.f) < 1e-12;
}

// ---- vector.add -------------------------------------------------------------------------------------------------------------

std::vector<double> numbers_arg(Ctx& c, const char* key, std::size_t count, const char* meaning) {
    const Json& v = c.a[key];
    std::vector<double> out;
    if (v.is_array() && v.size() == count) {
        for (const Json& e : v)
            if (e.is_number() && std::isfinite(e.get<double>())) out.push_back(e.get<double>());
    }
    if (out.size() != count) arg_error(c.cmd, std::string("/") + key, "expected a list of " + std::to_string(count) + " numbers, got " + describe_json_value(v) + ".", meaning);
    return out;
}

Json cmd_add(Ctx& c) {
    const std::string kind = enum_arg(c.a, c.cmd, "kind", {"path", "rect", "ellipse", "line"}, "", true);
    const Settings s = settings_of(c, 4000);
    const std::string space = enum_arg(c.a, c.cmd, "space", {"drawing", "local"}, "drawing");
    auto reject = [&](std::initializer_list<const char*> keys) {
        for (const char* k : keys)
            if (c.a.contains(k)) arg_error(c.cmd, std::string("/") + k, std::format("`{}` does not apply to kind \"{}\".", k, kind), "");
    };
    if (kind != "path") reject({"d"});
    if (kind != "rect") reject({"x", "y", "width", "height", "cornerRadius"});
    if (kind != "ellipse") reject({"center", "rx", "ry"});
    if (kind != "line") reject({"from", "to"});
    Path path;           // the outline in the coordinates the caller gave
    bool open = false;
    std::vector<std::pair<std::string, std::string>> native;
    std::string tag = kind;
    std::string base = kind;
    auto num = [&](const char* key, double def, double lo, double hi, const char* hint) { return num_arg(c.a, c.cmd, key, lo, hi, def, hint); };
    if (kind == "path") {
        if (!c.a.contains("d") || !c.a["d"].is_string()) arg_error(c.cmd, "/d", "`d` is required: the SVG path data.", "Example: {\"kind\": \"path\", \"d\": \"M10 10 L90 10 L50 80 Z\"}.");
        std::string why;
        if (!parse_path_data(c.a["d"].get<std::string>(), path, why)) arg_error(c.cmd, "/d", "the path data cannot be read: " + why, "Example: \"M10 10 C30 0 70 0 90 10 L50 80 Z\".");
        if (path.empty()) arg_error(c.cmd, "/d", "the path data draws nothing.", "Start with M x y and add at least one segment.");
        open = !has_closed(path);
    } else if (kind == "rect") {
        const double x = num("x", 0, -1e9, 1e9, ""), y = num("y", 0, -1e9, 1e9, "");
        const double w = num("width", 0, 0, 1e9, ""), h = num("height", 0, 0, 1e9, "");
        if (!(w > 0) || !(h > 0)) arg_error(c.cmd, !(w > 0) ? "/width" : "/height", "`width` and `height` are required and must be above 0.", "Example: {\"kind\": \"rect\", \"x\": 10, \"y\": 10, \"width\": 40, \"height\": 20}.");
        const double rr = num("cornerRadius", 0, 0, 1e9, "The radius of the rounded corners, in the same units.");
        path = rect_path(x, y, w, h, rr, rr);
        native = {{"x", format_number(x, 4)}, {"y", format_number(y, 4)}, {"width", format_number(w, 4)}, {"height", format_number(h, 4)}};
        if (rr > 0) native.push_back({"rx", format_number(rr, 4)});
    } else if (kind == "ellipse") {
        P ce{0, 0};
        if (!point_arg(c.a, c.cmd, "center", ce, "The middle of the ellipse.")) arg_error(c.cmd, "/center", "`center` is required: [x, y].", "Example: {\"kind\": \"ellipse\", \"center\": [50, 50], \"rx\": 30, \"ry\": 20}.");
        const double rx = num("rx", 0, 0, 1e9, "");
        if (!(rx > 0)) arg_error(c.cmd, "/rx", "`rx` is required and must be above 0.", "Give the horizontal radius; `ry` defaults to `rx` (a circle).");
        const double ry = num("ry", rx, 0, 1e9, "");
        if (!(ry > 0)) arg_error(c.cmd, "/ry", "`ry` must be above 0.", "");
        path = ellipse_path(ce.x, ce.y, rx, ry);
        if (rx == ry) {
            tag = "circle";
            base = "circle";
            native = {{"cx", format_number(ce.x, 4)}, {"cy", format_number(ce.y, 4)}, {"r", format_number(rx, 4)}};
        } else {
            native = {{"cx", format_number(ce.x, 4)}, {"cy", format_number(ce.y, 4)}, {"rx", format_number(rx, 4)}, {"ry", format_number(ry, 4)}};
        }
    } else {
        P from{0, 0}, to{0, 0};
        if (!point_arg(c.a, c.cmd, "from", from, "The start of the line.") || !point_arg(c.a, c.cmd, "to", to, "The end of the line."))
            arg_error(c.cmd, "/from", "`from` and `to` are required: [x, y] each.", "Example: {\"kind\": \"line\", \"from\": [10, 10], \"to\": [90, 40]}.");
        if (dist(from, to) < 1e-9) arg_error(c.cmd, "/to", "`from` and `to` are the same point, so the line has no length.", "Give two different points.");
        SubPath sp;
        sp.start = from;
        Seg g;
        g.p = to;
        sp.segs.push_back(g);
        path.push_back(sp);
        open = true;
        native = {{"x1", format_number(from.x, 4)}, {"y1", format_number(from.y, 4)}, {"x2", format_number(to.x, 4)}, {"y2", format_number(to.y, 4)}};
    }
    Placement at = placement_of(c, open, s);
    // the coordinates are the drawing's unless the call says otherwise; the new element lives in its parent's coordinates
    XNode* parent = at.before ? (at.before->parent ? at.before->parent : c.doc.root()) : at.parent ? at.parent : c.doc.root();
    Mat toLocal;
    if (space == "drawing" && at.transform.empty()) {
        const Mat pm = element_ctm(*parent);
        if (!pm.invertible()) fail("invalid_svg", std::format("{}: the parent {} scales to nothing.", c.cmd, describe_element(*parent)), "Fix the transform of the group.");
        toLocal = inverse(pm);
    }
    Json r;
    if (is_identity_like(toLocal) && kind != "path") {
        r = op_add_node(c.doc, at, base, tag, native, c.cmd);
    } else {
        if (!is_identity_like(toLocal)) path = transform_path(path, toLocal);
        r = op_add_path(c.doc, at, kind == "path" ? "path" : kind, path, s, c.warnings);
    }
    r["kind"] = kind;
    if (const XNode* n = c.doc.by_id(r.value("element", std::string()))) r["ref"] = element_ref(*n);
    return r;
}

// ---- vector.nodes and vector.set_path -----------------------------------------------------------------------------------------

XNode* one_shape(Ctx& c, const char* key) {
    if (!c.a.contains(key)) arg_error(c.cmd, std::string("/") + key, std::format("`{}` is required: the id or selector of ONE shape.", key), "Run vector.info to list the ids.");
    XNode* n = single_element(c, key);
    if (!is_shape_element(*n))
        arg_error(c.cmd, std::string("/") + key, std::format("{} is not a shape, so it has no outline to edit.", describe_element(*n)), "Name a path, rect, circle, ellipse, line, polyline or polygon (a group has none).");
    return n;
}

// Maps the points of one op of vector.nodes from the drawing space to the shape's own space.
Json ops_to_local(const Json& ops, const Mat& inv) {
    Json out = ops;
    if (!out.is_array()) return out;
    for (Json& o : out) {
        if (!o.is_object()) continue;
        for (const char* key : {"to", "at", "out"}) {
            auto it = o.find(key);
            if (it == o.end() || !it->is_array() || it->size() != 2 || !(*it)[0].is_number() || !(*it)[1].is_number()) continue;
            const P q = inv.apply(P{(*it)[0].get<double>(), (*it)[1].get<double>()});
            *it = Json::array({q.x, q.y});
        }
        if (auto it = o.find("by"); it != o.end() && it->is_array() && it->size() == 2 && (*it)[0].is_number() && (*it)[1].is_number()) {
            const P q = inv.apply_vector(P{(*it)[0].get<double>(), (*it)[1].get<double>()});
            *it = Json::array({q.x, q.y});
        }
    }
    return out;
}

Json cmd_nodes(Ctx& c) {
    XNode* el = one_shape(c, "element");
    const Settings s = settings_of(c, 4000);
    if (!c.a.contains("ops")) arg_error(c.cmd, "/ops", "`ops` is required: the list of node operations.", "Example: [{\"op\": \"move\", \"node\": 1, \"to\": [40, 50]}, {\"op\": \"convert\", \"node\": 2, \"to\": \"smooth\"}].");
    const std::string space = enum_arg(c.a, c.cmd, "space", {"drawing", "local"}, "drawing");
    Path local;
    std::string why;
    if (!shape_path(*el, local, why)) fail("invalid_svg", std::format("{} /element: {} cannot be read: {}.", c.cmd, describe_element(*el), why), "Fix the attributes of the shape first.");
    Json ops = c.a["ops"];
    if (space == "drawing") {
        const Mat m = element_ctm(*el);
        if (!m.invertible()) fail("invalid_svg", std::format("{} /element: {} sits inside a transform that scales it to nothing.", c.cmd, describe_element(*el)), "Fix the transform of the group.");
        if (!is_identity_like(m)) ops = ops_to_local(ops, inverse(m));
    }
    VecNodePath nodes = nodes_from_path(local);
    auto r = vector_nodes_apply(nodes, ops);
    if (!r.ok()) arg_error(c.cmd, "/ops", r.error().message, r.error().hint);
    if (nodes.empty() || vector_node_count(nodes) == 0) fail("invalid_argument", c.cmd + std::string(" /ops: the path would have no node left."), "Delete the element instead (vector.delete).");
    const Path edited = path_from_nodes(nodes);
    set_path_geometry(*el, path_to_data(edited, std::max(s.outDecimals, 4)));
    const Rect b = path_bounds(transform_path(edited, element_ctm(*el)));
    (void)s;
    return Json::object({{"element", element_ref(*el)}, {"nodes", vector_node_count(nodes)}, {"subpaths", int(nodes.size())}, {"bounds", rect_json(b)}, {"d", el->attr_or("d")}});
}

Json cmd_set_path(Ctx& c) {
    XNode* el = one_shape(c, "element");
    const Settings s = settings_of(c, 4000);
    if (!c.a.contains("d") || !c.a["d"].is_string()) arg_error(c.cmd, "/d", "`d` is required: the new path data.", "Example: {\"element\": \"leaf\", \"d\": \"M10 10 L90 10 L50 80 Z\"}.");
    const std::string space = enum_arg(c.a, c.cmd, "space", {"local", "drawing"}, "local");
    Path p;
    std::string why;
    if (!parse_path_data(c.a["d"].get<std::string>(), p, why)) arg_error(c.cmd, "/d", "the path data cannot be read: " + why, "Example: \"M10 10 C30 0 70 0 90 10 L50 80 Z\".");
    if (p.empty()) arg_error(c.cmd, "/d", "the path data draws nothing.", "Start with M x y and add at least one segment.");
    if (space == "drawing") {
        const Mat m = element_ctm(*el);
        if (!m.invertible()) fail("invalid_svg", std::format("{} /element: {} sits inside a transform that scales it to nothing.", c.cmd, describe_element(*el)), "Fix the transform of the group.");
        if (!is_identity_like(m)) p = transform_path(p, inverse(m));
    }
    set_path_geometry(*el, path_to_data(p, std::max(s.outDecimals, 4)));
    const Rect b = path_bounds(transform_path(p, element_ctm(*el)));
    return Json::object({{"element", element_ref(*el)}, {"nodes", node_count(p)}, {"bounds", rect_json(b)}});
}

// ---- vector.set -------------------------------------------------------------------------------------------------------------

bool paint_ok(const std::string& v) {
    if (v == "none" || v == "currentColor" || v == "transparent" || v == "inherit" || v.rfind("url(", 0) == 0) return true;
    std::array<std::uint8_t, 3> rgb{};
    double al = 1;
    return parse_css_colour(v, rgb, al);
}

std::string num_text(const Json& v) { return format_number(v.get<double>(), 4); }

void rename_references(SvgDoc& doc, const std::string& from, const std::string& to) {
    for (XNode* n : doc.all_elements())
        for (Attr& a : n->attrs) {
            if (a.name == "id") continue;
            std::string v = a.value;
            bool changed = false;
            if ((a.name == "href" || a.name == "xlink:href") && v == "#" + from) {
                v = "#" + to;
                changed = true;
            }
            const std::string needle = "url(#" + from + ")";
            for (std::size_t p = v.find(needle); p != std::string::npos; p = v.find(needle, p)) {
                v.replace(p, needle.size(), "url(#" + to + ")");
                changed = true;
                p += to.size();
            }
            if (changed) n->set_attr(a.name, v);
        }
}

Json cmd_set(Ctx& c) {
    const std::vector<XNode*> els = pick(c, "elements", true);
    refuse_root(c, els, "elements");
    struct Prop {
        const char* key;      // the argument
        const char* css;      // the property
        int kind;             // 0 paint, 1 number >= 0, 2 number 0..1, 3 enum, 4 free text
        std::vector<std::string> names;
    };
    static const std::vector<Prop> props = {
        {"fill", "fill", 0, {}},
        {"stroke", "stroke", 0, {}},
        {"strokeWidth", "stroke-width", 1, {}},
        {"opacity", "opacity", 2, {}},
        {"fillOpacity", "fill-opacity", 2, {}},
        {"strokeOpacity", "stroke-opacity", 2, {}},
        {"fillRule", "fill-rule", 3, {"nonzero", "evenodd"}},
        {"lineCap", "stroke-linecap", 3, {"butt", "round", "square"}},
        {"lineJoin", "stroke-linejoin", 3, {"miter", "round", "bevel"}},
        {"miterLimit", "stroke-miterlimit", 1, {}},
    };
    Json changed = Json::array();
    int touched = 0;
    for (const Prop& p : props) {
        auto it = c.a.find(p.key);
        if (it == c.a.end()) continue;
        std::string value;
        const bool remove = it->is_null();
        if (!remove) {
            switch (p.kind) {
                case 0:
                    if (!it->is_string() || !paint_ok(it->get<std::string>()))
                        arg_error(c.cmd, std::string("/") + p.key, "expected a CSS colour such as \"#d94f4f\", \"none\" or url(#gradient), got " + describe_json_value(*it) + ".", "null removes the property, so the element takes the colour of its group.");
                    value = it->get<std::string>();
                    break;
                case 1:
                    if (!it->is_number() || it->get<double>() < 0 || !std::isfinite(it->get<double>())) arg_error(c.cmd, std::string("/") + p.key, "expected a number of 0 or more, got " + describe_json_value(*it) + ".", "");
                    value = num_text(*it);
                    break;
                case 2:
                    if (!it->is_number() || it->get<double>() < 0 || it->get<double>() > 1) arg_error(c.cmd, std::string("/") + p.key, "expected a number from 0 to 1, got " + describe_json_value(*it) + ".", "");
                    value = num_text(*it);
                    break;
                default:
                    value = enum_arg(c.a, c.cmd, p.key, p.names, "");
                    break;
            }
        }
        for (XNode* n : els) {
            if (remove) remove_prop(*n, p.css);
            else set_prop(*n, p.css, value);
        }
        changed.push_back(p.key);
    }
    if (c.a.contains("dashes")) {
        const Json& d = c.a["dashes"];
        if (d.is_null() || (d.is_array() && d.empty())) {
            for (XNode* n : els) remove_prop(*n, "stroke-dasharray");
        } else {
            if (!d.is_array()) arg_error(c.cmd, "/dashes", "expected a list of lengths, got " + describe_json_value(d) + ".", "Example: [6, 4]. [] makes the stroke solid.");
            std::string text;
            for (std::size_t i = 0; i < d.size(); ++i) {
                if (!d[i].is_number() || d[i].get<double>() < 0) arg_error(c.cmd, std::format("/dashes/{}", i), "every length must be a number of 0 or more.", "");
                text += (i ? " " : "") + num_text(d[i]);
            }
            for (XNode* n : els) set_prop(*n, "stroke-dasharray", text);
        }
        changed.push_back("dashes");
    }
    if (c.a.contains("hidden")) {
        if (!c.a["hidden"].is_boolean()) arg_error(c.cmd, "/hidden", "expected true or false, got " + describe_json_value(c.a["hidden"]) + ".", "");
        for (XNode* n : els) {
            if (c.a["hidden"].get<bool>()) set_prop(*n, "display", "none");
            else remove_prop(*n, "display");
        }
        changed.push_back("hidden");
    }
    if (c.a.contains("locked")) {
        if (!c.a["locked"].is_boolean()) arg_error(c.cmd, "/locked", "expected true or false, got " + describe_json_value(c.a["locked"]) + ".", "");
        for (XNode* n : els) {
            if (c.a["locked"].get<bool>()) n->set_attr("data-locked", "true");
            else n->remove_attr("data-locked");
        }
        changed.push_back("locked");
    }
    if (c.a.contains("attributes")) {
        const Json& at = c.a["attributes"];
        if (!at.is_object()) arg_error(c.cmd, "/attributes", "expected an object of attribute names and values, got " + describe_json_value(at) + ".", "Example: {\"class\": \"body\", \"stroke-dasharray\": null}. null removes the attribute.");
        for (auto it = at.begin(); it != at.end(); ++it) {
            if (it.key() == "id" || it.key() == "d" || !valid_id(it.key()) || !(it->is_string() || it->is_number() || it->is_null()))
                arg_error(c.cmd, "/attributes/" + it.key(), "cannot be set here: `id` has its own argument, `d` is set by vector.set_path or vector.nodes, names must be plain attribute names and values strings, numbers or null.", "");
            for (XNode* n : els) {
                if (it->is_null()) n->remove_attr(it.key());
                else n->set_attr(it.key(), it->is_string() ? it->get<std::string>() : format_number(it->get<double>(), 6));
            }
            changed.push_back("attributes." + it.key());
        }
    }
    std::string renamed;
    if (c.a.contains("id")) {
        if (els.size() != 1) arg_error(c.cmd, "/id", std::format("`id` renames one element, but `elements` matches {}.", els.size()), "Pick one element, or leave `id` out.");
        if (!c.a["id"].is_string() || !valid_id(c.a["id"].get<std::string>()))
            arg_error(c.cmd, "/id", "expected a usable SVG id, got " + describe_json_value(c.a["id"]) + ".", "Start with a letter or underscore, then letters, digits, - _ . : only (e.g. \"hero-star\").");
        const std::string nid = c.a["id"].get<std::string>();
        const std::string old = els[0]->attr_or("id");
        if (nid != old) {
            if (c.doc.by_id(nid)) fail("exists", std::format("{} /id: the SVG already has an element with id '{}'.", c.cmd, nid), "Pick another id (" + c.doc.unique_id(nid) + " is free).");
            els[0]->set_attr("id", nid);
            if (!old.empty()) rename_references(c.doc, old, nid);
            changed.push_back("id");
            renamed = nid;
        }
    }
    if (changed.empty())
        arg_error(c.cmd, "", "nothing to set: no property was given.", "Pass fill, stroke, strokeWidth, opacity, fillOpacity, strokeOpacity, fillRule, lineCap, lineJoin, miterLimit, dashes, hidden, locked, id or attributes.");
    std::vector<std::string> refs;
    for (XNode* n : els) {
        refs.push_back(element_ref(*n));
        ++touched;
    }
    Json r = Json::object({{"elements", refs_json(refs)}, {"set", changed}, {"count", touched}});
    if (!renamed.empty()) r["id"] = renamed;
    return r;
}

// ---- vector.transform -------------------------------------------------------------------------------------------------------

Json cmd_transform(Ctx& c) {
    const std::vector<XNode*> picked = pick(c, "elements", true);
    refuse_root(c, picked, "elements");
    const std::vector<XNode*> units = in_document_order(c, outermost(picked));
    if (!c.a.contains("translate") && !c.a.contains("scale") && !c.a.contains("rotate") && !c.a.contains("flip") && !c.a.contains("matrix"))
        arg_error(c.cmd, "", "nothing to do: no transform was given.", "Pass translate [dx, dy], scale (a number or [sx, sy]), rotate (degrees), flip (\"horizontal\" or \"vertical\") or matrix [a, b, c, d, e, f], all in the drawing space.");
    // the centre the scale, rotation and flip turn about
    P centre{0, 0};
    bool haveCentre = false;
    if (c.a.contains("about")) {
        const Json& ab = c.a["about"];
        if (ab.is_string() && ab.get<std::string>() == "center") {
        } else if (point_arg(c.a, c.cmd, "about", centre, "The point the scale, rotation and flip turn about, in the drawing space.")) {
            haveCentre = true;
        } else {
            arg_error(c.cmd, "/about", "expected [x, y] or \"center\", got " + describe_json_value(ab) + ".", "\"center\" (the default) is the middle of the picked elements.");
        }
    }
    if (!haveCentre) {
        Rect all;
        for (XNode* u : units) {
            Rect r;
            std::string why;
            if (!unit_bounds(*u, false, r, why)) fail("invalid_argument", std::format("{} /elements: {}.", c.cmd, why), "Pick shapes, or groups that hold shapes.");
            all.add(r);
        }
        centre = all.center();
    }
    Mat m;  // applied in this order: matrix, flip, scale, rotate, translate
    if (c.a.contains("matrix")) {
        const std::vector<double> v = numbers_arg(c, "matrix", 6, "The SVG matrix(a b c d e f) of the drawing space, e.g. [1, 0, 0, 1, 10, 5] moves by 10, 5.");
        m = Mat{v[0], v[1], v[2], v[3], v[4], v[5]};
    }
    if (c.a.contains("flip")) {
        const std::string f = enum_arg(c.a, c.cmd, "flip", {"horizontal", "vertical", "both"}, "", true);
        const double sx = f == "vertical" ? 1 : -1, sy = f == "horizontal" ? 1 : -1;
        m = Mat{sx, 0, 0, sy, centre.x - sx * centre.x, centre.y - sy * centre.y} * m;
    }
    if (c.a.contains("scale")) {
        double sx = 1, sy = 1;
        const Json& v = c.a["scale"];
        if (v.is_number()) sx = sy = v.get<double>();
        else if (v.is_array() && v.size() == 2 && v[0].is_number() && v[1].is_number()) {
            sx = v[0].get<double>();
            sy = v[1].get<double>();
        } else {
            arg_error(c.cmd, "/scale", "expected a number or [sx, sy], got " + describe_json_value(v) + ".", "2 doubles the size; [1, -1] flips vertically.");
        }
        if (!std::isfinite(sx) || !std::isfinite(sy) || std::fabs(sx) < 1e-9 || std::fabs(sy) < 1e-9) arg_error(c.cmd, "/scale", "a scale of 0 would squash the elements to nothing.", "Use a factor other than 0.");
        m = Mat{sx, 0, 0, sy, centre.x - sx * centre.x, centre.y - sy * centre.y} * m;
    }
    if (c.a.contains("rotate")) m = rotation(num_arg(c.a, c.cmd, "rotate", -36000, 36000, 0, "Degrees, clockwise on screen."), centre.x, centre.y) * m;
    if (c.a.contains("translate")) {
        const std::vector<double> v = numbers_arg(c, "translate", 2, "How far to move, in the drawing space: [dx, dy].");
        m = translation(v[0], v[1]) * m;
    }
    if (!m.invertible()) arg_error(c.cmd, "", "the transform squashes the elements to nothing.", "Check the scale or the matrix.");
    const std::string text = transform_to_string(m, 4);
    std::vector<std::string> refs;
    for (XNode* u : units) {
        apply_canvas_transform(*u, m, text, c.cmd);
        refs.push_back(element_ref(*u));
    }
    Rect all;
    for (XNode* u : units) {
        Rect r;
        std::string why;
        if (unit_bounds(*u, false, r, why)) all.add(r);
    }
    Json r = Json::object({{"elements", refs_json(refs)}, {"transform", text}});
    if (!all.empty()) r["bounds"] = rect_json(all);
    return r;
}

// ---- vector.delete, duplicate -------------------------------------------------------------------------------------------------

Json cmd_delete(Ctx& c) {
    const std::vector<XNode*> picked = pick(c, "elements", true);
    refuse_root(c, picked, "elements");
    const std::vector<XNode*> units = outermost(picked);
    std::vector<std::string> refs;
    for (XNode* u : units) refs.push_back(element_ref(*u));
    int shapes = 0;
    for (XNode* u : units) {
        std::vector<XNode*> in;
        shapes_under(*u, in);
        shapes += int(in.size());
    }
    for (XNode* u : units) c.doc.remove(u);
    return Json::object({{"removed", refs_json(refs)}, {"count", int(units.size())}, {"shapes", shapes}});
}

void rename_ids_in_copy(SvgDoc& doc, XNode& copy) {
    std::vector<XNode*> todo;
    auto walk = [&](auto&& self, XNode& n) -> void {
        todo.push_back(&n);
        for (XNode* k : n.elements()) self(self, *k);
    };
    walk(walk, copy);
    for (XNode* n : todo) {
        const std::string id = n->attr_or("id");
        if (id.empty()) continue;
        n->set_attr("id", "\x01" + id);  // out of the way while the new ids are chosen
    }
    for (XNode* n : todo) {
        const std::string id = n->attr_or("id");
        if (id.empty() || id[0] != '\x01') continue;
        n->set_attr("id", doc.unique_id(id.substr(1) + "-copy"));
    }
}

Json cmd_duplicate(Ctx& c) {
    const std::vector<XNode*> units = in_document_order(c, outermost(pick(c, "elements", true)));
    refuse_root(c, units, "elements");
    P offset{0, 0};
    const bool moved = point_arg(c.a, c.cmd, "offset", offset, "How far the copies sit from the originals, in the drawing space: [dx, dy].");
    Json copies = Json::array();
    std::vector<XNode*> made;
    for (XNode* u : units) {
        std::unique_ptr<XNode> copy = SvgDoc::clone(*u);
        // the copy's ids are chosen once it is in the document (unique_id looks there)
        XNode* raw = c.doc.insert_after(u, std::move(copy));
        rename_ids_in_copy(c.doc, *raw);
        if (moved) {
            const Mat t = translation(offset.x, offset.y);
            apply_canvas_transform(*raw, t, transform_to_string(t, 4), c.cmd);
        }
        copies.push_back(Json::object({{"from", element_ref(*u)}, {"to", element_ref(*raw)}}));
        made.push_back(raw);
    }
    return Json::object({{"copies", copies}, {"count", int(units.size())}});
}

// ---- vector.group, ungroup ----------------------------------------------------------------------------------------------------

Json cmd_group(Ctx& c) {
    const std::vector<XNode*> units = in_document_order(c, outermost(pick(c, "elements", true)));
    refuse_root(c, units, "elements");
    XNode* parent = units[0]->parent;
    for (XNode* u : units)
        if (u->parent != parent)
            arg_error(c.cmd, "/elements", std::format("{} and {} are in different groups, so they cannot be wrapped together.", describe_element(*units[0]), describe_element(*u)),
                      "Move them into one group first with vector.reorder (parent), then group them.");
    std::string id = str_arg(c.a, c.cmd, "id", "");
    if (!id.empty()) {
        if (!valid_id(id)) arg_error(c.cmd, "/id", std::format("'{}' is not a usable SVG id.", id), "Start with a letter or underscore, then letters, digits, - _ . : only.");
        if (c.doc.by_id(id)) fail("exists", std::format("{} /id: the SVG already has an element with id '{}'.", c.cmd, id), "Pick another id (" + c.doc.unique_id(id) + " is free).");
    } else {
        id = c.doc.unique_id("group");
    }
    auto g = make_element("g");
    g->set_attr("id", id);
    // the group takes the place of the topmost picked element
    XNode* group = c.doc.insert_after(units.back(), std::move(g));
    std::vector<std::string> refs;
    for (XNode* u : units) {
        refs.push_back(element_ref(*u));
        move_node(c.doc, u, group, nullptr);
    }
    return Json::object({{"element", id}, {"ref", element_ref(*group)}, {"members", refs_json(refs)}});
}

Json cmd_ungroup(Ctx& c) {
    const std::vector<XNode*> units = in_document_order(c, pick(c, "elements", true));
    refuse_root(c, units, "elements");
    static const std::vector<std::string> inherited = {"fill", "stroke", "stroke-width", "fill-rule", "stroke-linecap", "stroke-linejoin", "stroke-miterlimit",
                                                       "stroke-dasharray", "stroke-dashoffset", "fill-opacity", "stroke-opacity"};
    for (XNode* g : units) {
        if (!is_group_element(*g)) arg_error(c.cmd, "/elements", std::format("{} is not a group.", describe_element(*g)), "Pick a <g>.");
        for (const char* k : {"clip-path", "mask", "filter"})
            if (!own_prop(*g, k).empty())
                fail("invalid_argument", std::format("{} /elements: {} has a {} that applies to the group as a whole, so ungrouping would change the picture.", c.cmd, describe_element(*g), k),
                     "Remove the " + std::string(k) + " first (vector.set attributes {\"" + k + "\": null}), then ungroup.");
    }
    std::vector<std::string> out;
    for (XNode* g : units) {
        const Mat gm = own_transform(*g);
        const std::string gOpacity = own_prop(*g, "opacity");
        std::vector<std::pair<std::string, std::string>> push;
        for (const std::string& p : inherited) {
            const std::string v = own_prop(*g, p);
            if (!v.empty() && v != "inherit") push.push_back({p, v});
        }
        std::vector<XNode*> kids = g->elements();
        XNode* next = nullptr;  // the element after the group: the children go in front of it
        {
            const std::vector<XNode*> sib = g->parent->elements();
            auto it = std::find(sib.begin(), sib.end(), g);
            if (it != sib.end() && it + 1 != sib.end()) next = *(it + 1);
        }
        XNode* parent = g->parent;
        // children first (the group is still in place), then the group goes
        for (XNode* k : kids) {
            const Mat kt = own_transform(*k);
            for (const auto& [p, v] : push)
                if (own_prop(*k, p).empty()) set_prop(*k, p, v);
            if (!gOpacity.empty() && gOpacity != "1") {
                double go = std::strtod(gOpacity.c_str(), nullptr);
                const std::string ko = own_prop(*k, "opacity");
                const double kv = ko.empty() ? 1.0 : std::strtod(ko.c_str(), nullptr);
                set_prop(*k, "opacity", format_number(go * kv, 4));
                c.warnings.push_back(std::format("{} had an opacity; each child took it, which differs where children overlap.", describe_element(*g)));
            }
            if (!is_identity_like(gm)) set_transform_attr(*k, gm * kt);
            XNode* moved = move_node(c.doc, k, parent, next ? next : nullptr);
            out.push_back(element_ref(*moved));
            // `next` stays valid: it is not touched
        }
        out.size();
        c.doc.remove(g);
    }
    return Json::object({{"children", refs_json(out)}, {"ungrouped", int(units.size())}});
}

// ---- vector.reorder ---------------------------------------------------------------------------------------------------------------

bool drawable(const XNode& n) { return (is_shape_element(n) || (is_group_element(n) && n.local() != "svg")) && !in_inert_subtree(n); }

Json cmd_reorder(Ctx& c) {
    const std::vector<XNode*> units = in_document_order(c, outermost(pick(c, "elements", true)));
    refuse_root(c, units, "elements");
    const bool hasTo = c.a.contains("to"), hasParent = c.a.contains("parent"), hasBefore = c.a.contains("before");
    if (hasTo == (hasParent || hasBefore))
        arg_error(c.cmd, hasTo ? "/to" : "", hasTo ? "`to` cannot be combined with `parent` or `before`." : "nothing to do: give `to` or `parent` / `before`.",
                  "to: \"front\", \"back\", \"forward\" or \"backward\" changes the order inside the group; `parent` (a group id or \"root\") and/or `before` (an element id) move the elements elsewhere.");
    std::vector<std::string> refs;
    if (hasTo) {
        const std::string to = enum_arg(c.a, c.cmd, "to", {"front", "back", "forward", "backward"}, "", true);
        std::vector<XNode*> list = units;
        if (to == "front" || to == "forward") std::reverse(list.begin(), list.end());
        for (XNode* u : list) {
            XNode* parent = u->parent;
            std::vector<XNode*> sib;
            for (XNode* k : parent->elements())
                if (drawable(*k)) sib.push_back(k);
            const std::size_t at = std::size_t(std::find(sib.begin(), sib.end(), u) - sib.begin());
            if (at >= sib.size()) continue;
            if (to == "front") {
                if (at + 1 < sib.size()) u = move_node(c.doc, u, parent, nullptr);
            } else if (to == "back") {
                if (at > 0) u = move_node(c.doc, u, parent, sib.front());
            } else if (to == "forward") {
                if (at + 1 < sib.size()) {
                    XNode* after = at + 2 < sib.size() ? sib[at + 2] : nullptr;
                    u = move_node(c.doc, u, parent, after);
                }
            } else if (at > 0) {
                u = move_node(c.doc, u, parent, sib[at - 1]);
            }
            refs.push_back(element_ref(*u));
        }
        return Json::object({{"elements", refs_json(refs)}, {"to", to}});
    }
    XNode* before = hasBefore ? single_element(c, "before") : nullptr;
    XNode* parent = nullptr;
    if (hasParent) {
        const Json& pv = c.a["parent"];
        if (pv.is_string() && (pv.get<std::string>() == "root")) {
            parent = c.doc.root();
        } else {
            parent = single_element(c, "parent");
            if (!is_group_element(*parent)) arg_error(c.cmd, "/parent", std::format("{} is not a group, so nothing can be put in it.", describe_element(*parent)), "Name a <g>, or \"root\" for the top level.");
        }
    }
    if (before) {
        if (!before->parent) arg_error(c.cmd, "/before", "the root <svg> has no place before it.", "Name an element inside the drawing.");
        if (parent && before->parent != parent) arg_error(c.cmd, "/before", std::format("{} is not inside `parent`.", describe_element(*before)), "Name an element of that group, or leave `parent` out.");
        parent = before->parent;
    }
    for (XNode* u : units) {
        if (u == parent || is_ancestor(u, parent)) arg_error(c.cmd, "/parent", std::format("{} cannot go inside itself.", describe_element(*u)), "Pick a group outside the elements you move.");
        if (u == before) arg_error(c.cmd, "/before", std::format("{} cannot go in front of itself.", describe_element(*u)), "");
    }
    // the elements keep their look: a different parent may have another transform
    const Mat newBase = element_ctm(*parent);
    if (!newBase.invertible()) fail("invalid_svg", std::format("{}: {} scales to nothing.", c.cmd, describe_element(*parent)), "Fix the transform of the group.");
    const Mat newInv = inverse(newBase);
    // `before` must survive the moves: it is found again by its position among the siblings that stay
    for (XNode* u : units) {
        const Mat oldBase = parent_ctm(*u);
        const Mat own = own_transform(*u);
        const Mat now = newInv * oldBase * own;
        const bool changesFrame = !(is_identity_like(newInv * oldBase));
        if (changesFrame) set_transform_attr(*u, now);
        u = move_node(c.doc, u, parent, before);
        refs.push_back(element_ref(*u));
    }
    return Json::object({{"elements", refs_json(refs)}, {"parent", parent == c.doc.root() ? std::string("root") : element_ref(*parent)}});
}

// ---- vector.assign_ids ---------------------------------------------------------------------------------------------------------

Json cmd_assign_ids(Ctx& c) {
    const std::vector<XNode*> all = drawable_elements(c.doc);
    std::set<XNode*> scope;
    if (c.a.contains("elements")) {
        for (XNode* p : pick(c, "elements", true)) {
            std::vector<XNode*> in;
            auto walk = [&](auto&& self, XNode& n) -> void {
                in.push_back(&n);
                for (XNode* k : n.elements()) self(self, *k);
            };
            walk(walk, *p);
            scope.insert(in.begin(), in.end());
        }
    }
    // the selectors are read before any id is written: they describe the document as it was
    Json list = Json::array();
    std::vector<std::pair<XNode*, std::string>> todo;
    for (XNode* n : all) {
        if (!n->attr_or("id").empty()) continue;
        if (!scope.empty() && !scope.count(n)) continue;
        todo.push_back({n, element_selector(*n)});
    }
    for (auto& [n, selector] : todo) {
        const std::string id = c.doc.unique_id(n->local());
        n->set_attr("id", id);
        list.push_back(Json::object({{"selector", selector}, {"id", id}}));
    }
    return Json::object({{"assigned", list}, {"count", int(todo.size())}});
}

}  // namespace

}  // namespace fa::vec

namespace fa::assets_detail {

void register_vector_edit_commands(CommandRegistry& registry, const std::string& projectDir) {
    using namespace fa::vec;
    using namespace fa::vec::cmd;
    struct Def {
        const char* name;
        const char* summary;
        std::string description;
        Json props;
        std::vector<std::string> required;
        Json (*fn)(Ctx&);
    };
    const Json common = common_props();
    const Json elements = Json::object({{"elements", refs_prop("The elements to work on: an SVG id, a selector, or a list of them. A group is one element. Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas.")}});
    auto point_prop = [](const char* desc) { return Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 2}, {"maxItems", 2}, {"description", desc}}); };
    auto spaceProp = [](const char* doc) { return enum_prop({"drawing", "local"}, doc); };
    std::vector<Def> defs;
    defs.push_back({"vector.add", "Add a path, rectangle, ellipse or line to an SVG.",
        "Inserts one new element into an SVG file, SVG text or an svg layer of an image document, at the end of the drawing or of `parent` (or in front of `before`). kind \"path\" takes `d` (SVG path data); \"rect\" takes x, y, width, height and cornerRadius and writes a <rect>; "
        "\"ellipse\" takes center, rx and ry (a circle when ry is left out) and writes an <ellipse> or <circle>; \"line\" takes from and to. Coordinates are in the DRAWING space (the viewBox) by default and are converted into the parent's own space; "
        "space \"local\" (or a `transform`) means the element's own numbers. Style with fill, stroke, strokeWidth, opacity and attributes (same as vector.shape). Open paths and lines get a stroke and no fill by default. "
        "Returns the new element's id, its bounds in the drawing and a preview as `$image`. Example: {\"source\": \"assets/art/badge.svg\", \"kind\": \"rect\", \"x\": 10, \"y\": 10, \"width\": 40, \"height\": 20, \"cornerRadius\": 4, \"fill\": \"#d94f4f\"}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, placement_props()),
                    Json::object({{"kind", enum_prop({"path", "rect", "ellipse", "line"}, "What to add.")},
                                  {"space", spaceProp("drawing (default): the numbers are in the drawing space and are converted into the parent's. local: the element's own numbers.")},
                                  {"d", str_prop("path: the SVG path data.")},
                                  {"x", num_prop("rect: the left edge.")}, {"y", num_prop("rect: the top edge.")},
                                  {"width", num_prop("rect: the width (above 0).")}, {"height", num_prop("rect: the height (above 0).")},
                                  {"cornerRadius", num_prop("rect: the radius of the rounded corners.")},
                                  {"center", point_prop("ellipse: the middle [x, y].")},
                                  {"rx", num_prop("ellipse: the horizontal radius.")}, {"ry", num_prop("ellipse: the vertical radius. Default: rx (a circle).")},
                                  {"from", point_prop("line: the start [x, y].")}, {"to", point_prop("line: the end [x, y].")}})),
        {"kind"}, cmd_add});
    defs.push_back({"vector.nodes", "Edit the nodes of a path: move anchors and handles, insert, delete, convert, break, join, close, append.",
        "Applies a list of node operations, in order, to ONE shape (a rect or circle becomes a <path> with the same outline; the id, style and transform stay). Nodes are numbered from 0 in the order of the path data, per subpath (`subpath`, default 0). "
        "Points are in the drawing space by default (space \"local\" for the path's own numbers). Ops: {\"op\": \"move\", \"node\": n, \"to\": [x, y]} or \"by\": [dx, dy] (the handles go with it unless handles: false); "
        "{\"op\": \"handle\", \"node\": n, \"which\": \"in\"|\"out\", \"to\": [x, y], \"link\": \"auto\"|\"none\"|\"angle\"|\"mirror\"} (auto: a smooth node keeps its handles on one line, a symmetric one mirrors them; a handle moved onto its node is removed); "
        "{\"op\": \"insert\", \"segment\": s, \"t\": 0.5} or \"at\": [x, y] near the path (the curve keeps its shape); {\"op\": \"delete\", \"node\": n, \"keepShape\": true}; {\"op\": \"convert\", \"node\": n, \"to\": \"corner\"|\"smooth\"|\"symmetric\"}; "
        "{\"op\": \"break\", \"node\": n} (open a closed subpath there, or split an open one); {\"op\": \"join\", \"node\": a, \"otherNode\": b, \"other\": subpath, \"connect\": \"merge\"|\"line\"} (two ends); {\"op\": \"close\"}; {\"op\": \"reverse\"}; "
        "{\"op\": \"append\", \"at\": [x, y], \"out\": [x, y], \"end\": \"end\"|\"start\"} (continue an open path; subpath = the number of subpaths starts a new one). A shape drawn by vector.shape with parametric: true stops being parametric. Returns the new node count and bounds and a preview as `$image`. "
        "Example: {\"source\": \"assets/art/leaf.svg\", \"element\": \"leaf\", \"ops\": [{\"op\": \"move\", \"node\": 1, \"to\": [40, 50]}, {\"op\": \"convert\", \"node\": 2, \"to\": \"smooth\"}]}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, geometry_props()),
                    Json::object({{"element", str_prop("The shape to edit: an SVG id or a selector that matches exactly one element.")},
                                  {"ops", Json::object({{"type", "array"}, {"items", Json::object({{"type", "object"}})}, {"description", "The node operations, applied in order. Each is an object with an `op` (move, handle, insert, delete, convert, break, join, close, reverse, append) and its arguments."}})},
                                  {"space", spaceProp("drawing (default): points in the ops are in the drawing space. local: the path's own coordinates.")}})),
        {"element", "ops"}, cmd_nodes});
    defs.push_back({"vector.set_path", "Replace the path data of a shape.",
        "Sets the outline of ONE shape to the path data `d`: a rect or circle becomes a <path>; the id, style and transform stay. `space` \"local\" (default) means `d` is written in the shape's own coordinates, \"drawing\" that it is in the drawing space "
        "(converted through the shape's transforms). A shape drawn by vector.shape with parametric: true stops being parametric. Returns the node count, the bounds and a preview as `$image`. Example: {\"source\": \"assets/art/leaf.svg\", \"element\": \"leaf\", \"d\": \"M10 10 L90 10 L50 80 Z\"}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, geometry_props()),
                    Json::object({{"element", str_prop("The shape: an SVG id or a selector that matches exactly one element.")},
                                  {"d", str_prop("The new SVG path data.")},
                                  {"space", enum_prop({"local", "drawing"}, "local (default): the shape's own coordinates. drawing: the drawing space.")}})),
        {"element", "d"}, cmd_set_path});
    defs.push_back({"vector.set", "Set the style, visibility, lock, id or attributes of SVG elements.",
        "Sets presentation properties on the picked elements (shapes or groups): fill, stroke (a CSS colour, \"none\" or url(#gradient)), strokeWidth, opacity, fillOpacity, strokeOpacity, fillRule, lineCap, lineJoin, miterLimit, dashes ([] = solid); "
        "hidden (display=\"none\", which every renderer honours) and locked (data-locked=\"true\", which the Vector panel honours); `id` renames ONE element and updates the href and url(#...) that point to it; `attributes` sets any other attribute (null removes it). "
        "A null value removes the property, so the element takes it from its group again. A property the element already writes in its style attribute is changed there. Returns the elements and what was set, and a preview as `$image`. "
        "Example: {\"source\": \"assets/art/badge.svg\", \"elements\": [\"disc\"], \"fill\": \"#d94f4f\", \"stroke\": \"#101018\", \"strokeWidth\": 2}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, elements),
                    Json::object({{"fill", nullable(str_prop("A CSS fill colour, \"none\" or url(#id); null removes it."))},
                                  {"stroke", nullable(str_prop("A CSS stroke colour, \"none\" or url(#id); null removes it."))},
                                  {"strokeWidth", nullable(num_prop("Stroke width in the element's units; null removes it."))},
                                  {"opacity", nullable(num_prop("0 to 1; null removes it."))}, {"fillOpacity", nullable(num_prop("0 to 1; null removes it."))},
                                  {"strokeOpacity", nullable(num_prop("0 to 1; null removes it."))},
                                  {"fillRule", nullable(enum_prop({"nonzero", "evenodd"}, "How overlapping subpaths fill; null removes it."))},
                                  {"lineCap", nullable(enum_prop({"butt", "round", "square"}, "The ends of open lines; null removes it."))},
                                  {"lineJoin", nullable(enum_prop({"miter", "round", "bevel"}, "The corners of lines; null removes it."))},
                                  {"miterLimit", nullable(num_prop("The longest miter before a corner is bevelled; null removes it."))},
                                  {"dashes", Json::object({{"type", Json::array({"array", "null"})}, {"items", Json::object({{"type", "number"}})}, {"description", "Dash pattern lengths; [] or null makes the stroke solid."}})},
                                  {"hidden", Json::object({{"type", "boolean"}, {"description", "true hides the elements (display=\"none\"); false shows them."}})},
                                  {"locked", Json::object({{"type", "boolean"}, {"description", "true marks the elements locked (data-locked=\"true\") so the Vector panel does not pick or move them; false unlocks them."}})},
                                  {"id", str_prop("Rename: the new id (one element only).")},
                                  {"attributes", Json::object({{"type", "object"}, {"description", "Other attributes to set: {\"class\": \"body\", \"clip-path\": null}."}})}})),
        {"elements"}, cmd_set});
    defs.push_back({"vector.transform", "Move, scale, rotate or flip SVG elements in the drawing space.",
        "Applies a transform of the DRAWING space to the picked elements (shapes or whole groups) by writing their transform attribute, so ids, groups, styles and the nodes stay exactly as they are; parent transforms are honoured. "
        "Give any of translate [dx, dy], scale (a number or [sx, sy]), rotate (degrees, clockwise on screen), flip (\"horizontal\", \"vertical\" or \"both\") and matrix [a, b, c, d, e, f]; scale, rotate and flip turn about `about` ([x, y] or \"center\", the middle of the picked elements; default center). "
        "Order: matrix, flip, scale, rotate, then translate. Returns the transform and the bounds after it, and a preview as `$image`. Example: {\"source\": \"assets/art/ui.svg\", \"elements\": [\"icon\"], \"rotate\": 15, \"translate\": [10, 0]}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, elements),
                    Json::object({{"translate", point_prop("Move by [dx, dy] in the drawing space.")},
                                  {"scale", Json::object({{"description", "A factor, or [sx, sy]."}, {"oneOf", Json::array({Json::object({{"type", "number"}}), point_prop("[sx, sy]")})}})},
                                  {"rotate", num_prop("Degrees, clockwise on screen.")},
                                  {"flip", enum_prop({"horizontal", "vertical", "both"}, "Mirror about `about`: horizontal swaps left and right.")},
                                  {"matrix", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 6}, {"maxItems", 6}, {"description", "A drawing-space matrix [a, b, c, d, e, f] (SVG matrix(a b c d e f))."}})},
                                  {"about", Json::object({{"description", "The point scale, rotate and flip turn about: [x, y] or \"center\" (default)."}})}})),
        {"elements"}, cmd_transform});
    defs.push_back({"vector.delete", "Delete SVG elements.",
        "Removes the picked shapes or groups (a group takes everything in it). The rest of the drawing is not touched. Returns the removed refs and a preview as `$image`. Example: {\"source\": \"assets/art/badge.svg\", \"elements\": [\"hole\"]}. Docs: docs.read VECTOR.",
        merge_props(common, elements), {"elements"}, cmd_delete});
    defs.push_back({"vector.duplicate", "Copy SVG elements right after the originals.",
        "Inserts a copy of each picked element (shape or group, with everything in it) right after it, with new ids (<id>-copy, <id>-copy-2...). `offset` [dx, dy] moves the copies in the drawing space. Returns the pairs {from, to} and a preview as `$image`. "
        "Example: {\"source\": \"assets/art/badge.svg\", \"elements\": [\"star\"], \"offset\": [12, 12]}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, elements), Json::object({{"offset", point_prop("Move the copies by [dx, dy] in the drawing space.")}})), {"elements"}, cmd_duplicate});
    defs.push_back({"vector.group", "Wrap SVG elements in a new group.",
        "Puts the picked elements (all in the same group) into a new <g>, which takes the place of the topmost one; their order, ids and transforms stay. `id` names the group (default group, group-2...). Returns the group and a preview as `$image`. "
        "Example: {\"source\": \"assets/art/face.svg\", \"elements\": [\"eye-l\", \"eye-r\"], \"id\": \"eyes\"}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, elements), Json::object({{"id", str_prop("The id of the new group.")}})), {"elements"}, cmd_group});
    defs.push_back({"vector.ungroup", "Dissolve SVG groups, keeping what is in them where it was.",
        "Moves the children of each picked <g> out into the group's parent, at the group's place, and removes the group. The group's transform is folded into each child's, and the style it set (fill, stroke, stroke-width...) is written on the children that do not set it. "
        "A group with clip-path, mask or filter is refused (it would change the picture). Returns the children and a preview as `$image`. Example: {\"source\": \"assets/art/face.svg\", \"elements\": [\"eyes\"]}. Docs: docs.read VECTOR.",
        merge_props(common, elements), {"elements"}, cmd_ungroup});
    defs.push_back({"vector.reorder", "Change the drawing order of SVG elements or move them into another group.",
        "`to` changes the order inside the group: \"front\" (drawn last, on top), \"back\", \"forward\" or \"backward\" by one place. `parent` (a group id, or \"root\") and/or `before` (an element id) move the elements there: into the group at its end, or in front of that element; "
        "the elements keep their look (the transforms of the old and new group are compensated). Ids stay. Returns the elements and a preview as `$image`. Example: {\"source\": \"assets/art/badge.svg\", \"elements\": [\"star\"], \"to\": \"front\"}. Docs: docs.read VECTOR.",
        merge_props(merge_props(common, elements),
                    Json::object({{"to", enum_prop({"front", "back", "forward", "backward"}, "Change the order inside the group.")},
                                  {"parent", str_prop("A group id or selector, or \"root\": move the elements into it (at its end unless `before`).")},
                                  {"before", str_prop("An element id or selector: the elements go in front of it (behind it in the picture), in its group.")}})),
        {"elements"}, cmd_reorder});
    defs.push_back({"vector.assign_ids", "Give every drawn element without an id one.",
        "Names the shapes and groups that have no id (path, path-2, g, g-2...) so the other vector.* commands can pick them by id; picked `elements` limit it (with what is inside them). Returns the new ids with the selector each one had before. "
        "Example: {\"source\": \"assets/art/traced.svg\"}. Docs: docs.read VECTOR.",
        merge_props(common, elements), {}, cmd_assign_ids});

    for (Def& d : defs) {
        CommandInfo info;
        info.name = d.name;
        info.summary = d.summary;
        info.description = d.description;
        info.category = "assets";
        info.readOnly = false;
        Json schema = Json::object({{"type", "object"}, {"properties", d.props}});
        if (!d.required.empty()) schema["required"] = d.required;
        info.inputSchema = schema;
        const std::string name = d.name;
        auto fn = d.fn;
        const Json props = d.props;
        registry.add(info, [projectDir, name, fn, props](const Json& args) {
            if (!args.is_object()) fail("invalid_argument", name + ": the arguments must be an object.", "Example: {\"source\": \"assets/art/badge.svg\"}.");
            return fa::vec::cmd::run(projectDir, args, name.c_str(), props, false, [fn](Ctx& c) { return fn(c); });
        });
    }
}

}  // namespace fa::assets_detail
