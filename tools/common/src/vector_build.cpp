// The shape builders on an SvgDoc (vector_ops.h): new elements at a placement, mirror with weld, text to paths and the shadow and
// highlight pass.
#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <functional>
#include <set>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/tooling/pixel_art.h"
#include "fa/tooling/style_guide.h"
#include "vector_ops.h"
#include "vector_shapes.h"

namespace fa::vec {

using assets_detail::arg_error;
using assets_detail::fail;

namespace {

double r3(double v) { return std::round(v * 1000.0) / 1000.0; }
Json rect_json(const Rect& r) { return Json::array({r3(r.x0), r3(r.y0), r3(r.width()), r3(r.height())}); }
std::string label(const XNode& n) { return describe_element(n); }
std::string id_or_label(const XNode& n) {
    const std::string* id = n.attr("id");
    return id && !id->empty() ? *id : label(n);
}
ClipGrid grid_of(const Settings& s) { return ClipGrid{s.gridDecimals}; }

std::string hex_of(const std::array<std::uint8_t, 3>& c) { return std::format("#{:02x}{:02x}{:02x}", c[0], c[1], c[2]); }

// ---- OKLab --------------------------------------------------------------------------------------------------------------

double to_linear(double c) { return c <= 0.04045 ? c / 12.92 : std::pow((c + 0.055) / 1.055, 2.4); }
double from_linear(double c) { return c <= 0.0031308 ? 12.92 * c : 1.055 * std::pow(c, 1 / 2.4) - 0.055; }

std::array<double, 3> to_oklab(const std::array<std::uint8_t, 3>& c) {
    const double r = to_linear(c[0] / 255.0), g = to_linear(c[1] / 255.0), b = to_linear(c[2] / 255.0);
    const double l = std::cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const double m = std::cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const double s = std::cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return {0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s, 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s};
}

std::array<std::uint8_t, 3> from_oklab(const std::array<double, 3>& lab) {
    const double l = std::pow(lab[0] + 0.3963377774 * lab[1] + 0.2158037573 * lab[2], 3);
    const double m = std::pow(lab[0] - 0.1055613458 * lab[1] - 0.0638541728 * lab[2], 3);
    const double s = std::pow(lab[0] - 0.0894841775 * lab[1] - 1.2914855480 * lab[2], 3);
    const double rgb[3] = {4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                           -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s};
    std::array<std::uint8_t, 3> out{};
    for (int i = 0; i < 3; ++i) out[std::size_t(i)] = std::uint8_t(std::lround(std::clamp(from_linear(std::clamp(rgb[i], 0.0, 1.0)), 0.0, 1.0) * 255.0));
    return out;
}

std::array<std::uint8_t, 3> oklab_shifted(const std::array<std::uint8_t, 3>& rgb, int direction, double amount) {
    auto lab = to_oklab(rgb);
    lab[0] = std::clamp(lab[0] + direction * amount, 0.0, 1.0);
    // shadows get a little more colour and highlights a little less, the way painted light behaves
    const double chroma = direction < 0 ? 1.08 : 0.92;
    lab[1] *= chroma;
    lab[2] *= chroma;
    return from_oklab(lab);
}

bool visible_paint(const std::string& v) { return !v.empty() && v != "none" && v != "transparent"; }

// The placement's parent node and the element to insert in front of (or null).
XNode* parent_of(SvgDoc& doc, const Placement& at) {
    if (at.before) return at.before->parent ? at.before->parent : doc.root();
    return at.parent ? at.parent : doc.root();
}

XNode* insert_node(SvgDoc& doc, const Placement& at, std::unique_ptr<XNode> node) {
    if (at.before) return doc.insert_before(at.before, std::move(node));
    return doc.append_child(parent_of(doc, at), std::move(node));
}

void apply_placement_style(XNode& n, const Placement& at, const std::string& fillOverride) {
    const std::string fill = !fillOverride.empty() ? fillOverride : !at.fill.empty() ? at.fill : at.lineArt ? "none" : "#6d9eeb";
    n.set_attr("fill", fill);
    const std::string stroke = !at.stroke.empty() ? at.stroke : at.lineArt ? "#334155" : std::string();
    if (!stroke.empty() && stroke != "none") {
        n.set_attr("stroke", stroke);
        n.set_attr("stroke-width", format_number(at.strokeWidth.value_or(at.defaultStrokeWidth), 3));
        if (at.lineArt) {
            n.set_attr("stroke-linecap", "round");
            n.set_attr("stroke-linejoin", "round");
        }
    } else if (at.strokeWidth && !stroke.empty()) {
        n.set_attr("stroke-width", format_number(*at.strokeWidth, 3));
    }
    if (!at.opacity.empty()) n.set_attr("opacity", at.opacity);
    for (const auto& [k, v] : at.attrs) n.set_attr(k, v);
    if (!at.transform.empty()) n.set_attr("transform", at.transform);
}

}  // namespace

std::string oklab_shift(const std::array<std::uint8_t, 3>& rgb, int direction, double amount) { return hex_of(oklab_shifted(rgb, direction, amount)); }

// ---- new elements ----------------------------------------------------------------------------------------------------------

namespace {
std::string claim_id(SvgDoc& doc, const Placement& at, const std::string& base, const char* command) {
    if (!at.id.empty()) {
        if (doc.by_id(at.id))
            fail("exists", std::format("{} /id: the SVG already has an element with id '{}'.", command, at.id),
                 "Pick another id (" + doc.unique_id(at.id) + " is free), or leave `id` out and a free one is chosen.");
        return at.id;
    }
    return doc.unique_id(base);
}
}  // namespace

Json op_add_path(SvgDoc& doc, const Placement& at, const std::string& baseId, const Path& path, const Settings& s, std::vector<std::string>&) {
    const char* cmd = "vector.shape";
    if (path.empty()) fail("empty_result", std::format("{}: the shape has no outline.", cmd), "Check the sizes: a zero radius or two equal points draw nothing.");
    const std::string id = claim_id(doc, at, baseId, cmd);
    auto node = make_element("path");
    node->set_attr("id", id);
    node->set_attr("d", path_to_data(path, s.outDecimals));
    apply_placement_style(*node, at, "");
    XNode* raw = insert_node(doc, at, std::move(node));
    const Rect b = path_bounds(transform_path(path, element_ctm(*raw)));
    return Json::object({{"element", id}, {"nodes", node_count(path)}, {"curves", has_curves(path)}, {"bounds", rect_json(b)}, {"parent", id_or_label(*raw->parent)}});
}

Json op_add_node(SvgDoc& doc, const Placement& at, const std::string& baseId, const std::string& tag,
                 const std::vector<std::pair<std::string, std::string>>& attrs, const char* command) {
    const std::string id = claim_id(doc, at, baseId, command);
    auto node = make_element(tag);
    node->set_attr("id", id);
    for (const auto& [k, v] : attrs) node->set_attr(k, v);
    apply_placement_style(*node, at, "");
    XNode* raw = insert_node(doc, at, std::move(node));
    Rect b;
    Path p;
    std::string why;
    if (shape_path(*raw, p, why)) b = path_bounds(transform_path(p, element_ctm(*raw)));
    return Json::object({{"element", id}, {"bounds", rect_json(b)}, {"parent", id_or_label(*raw->parent)}});
}

Json op_add_group(SvgDoc& doc, const Placement& at, const std::string& baseId, const std::vector<RibbonPiece>& pieces, const Settings& s, std::vector<std::string>&) {
    const char* cmd = "vector.shape";
    const std::string gid = claim_id(doc, at, baseId, cmd);
    auto g = make_element("g");
    g->set_attr("id", gid);
    if (!at.opacity.empty()) g->set_attr("opacity", at.opacity);
    for (const auto& [k, v] : at.attrs) g->set_attr(k, v);
    if (!at.transform.empty()) g->set_attr("transform", at.transform);
    XNode* graw = insert_node(doc, at, std::move(g));
    Json ids = Json::array();
    for (const RibbonPiece& p : pieces) {
        auto n = make_element("path");
        const std::string pid = doc.unique_id(gid + "-" + p.suffix);
        n->set_attr("id", pid);
        n->set_attr("d", p.d);
        Placement style = at;
        style.transform.clear();
        style.opacity.clear();
        style.attrs.clear();
        apply_placement_style(*n, style, p.fill);
        doc.append_child(graw, std::move(n));
        ids.push_back(pid);
    }
    Rect b;
    std::vector<XNode*> shapes;
    shapes_under(*graw, shapes);
    for (XNode* n : shapes) {
        Path p;
        std::string why;
        if (shape_path(*n, p, why)) b.add(path_bounds(transform_path(p, element_ctm(*n))));
    }
    (void)s;
    return Json::object({{"element", gid}, {"parts", ids}, {"bounds", rect_json(b)}, {"parent", id_or_label(*graw->parent)}});
}

// ---- text ---------------------------------------------------------------------------------------------------------------------

Json op_add_text(SvgDoc& doc, const Placement& at, const TextArgs& a, const Settings& s, std::vector<std::string>& warnings) {
    TextMetrics m;
    auto path = build_text(a.text, a.font, a.size, a.at, a.anchor, a.letterSpacing, a.lineSpacing, &m);
    if (!path) fail("invalid_argument", std::format("vector.text_to_path /font: {}", path.error().message), path.error().hint);
    if (path->empty())
        fail("empty_result", "vector.text_to_path /text: the text has no visible character, so there is no outline.", "Use at least one letter, digit or symbol the font has.");
    if (!m.missing.empty()) {
        std::string list;
        for (char32_t c : m.missing) {
            std::string u;
            const unsigned cp = unsigned(c);
            if (cp < 0x80) u += char(cp);
            else if (cp < 0x800) u += {char(0xC0 | (cp >> 6)), char(0x80 | (cp & 0x3F))};
            else if (cp < 0x10000) u += {char(0xE0 | (cp >> 12)), char(0x80 | ((cp >> 6) & 0x3F)), char(0x80 | (cp & 0x3F))};
            else u += {char(0xF0 | (cp >> 18)), char(0x80 | ((cp >> 12) & 0x3F)), char(0x80 | ((cp >> 6) & 0x3F)), char(0x80 | (cp & 0x3F))};
            list += (list.empty() ? "" : " ") + u + std::format(" (U+{:04X})", unsigned(c));
        }
        warnings.push_back("No font of the chain has " + list + ", so it is left out. Use a font that has it (`font`).");
    }
    Placement p = at;
    p.attrs.emplace("fill-rule", "nonzero");
    Json r = op_add_path(doc, p, "text", *path, s, warnings);
    r["advance"] = r3(m.advance);
    r["lines"] = m.lines;
    r["glyphs"] = m.glyphs;
    r["lineHeight"] = r3(m.lineHeight);
    return r;
}

namespace {
bool parse_font_size(const XNode& n, double& out) {
    const std::string v = inherited_prop(n, "font-size");
    if (v.empty()) return false;
    return parse_length(v, out) && out > 0;
}
std::string collect_text(const XNode& n, bool& hasPositionedChild) {
    std::string out;
    for (const XItem& k : n.kids) {
        if (!k.el) {
            // entities are kept as the parser delivered them: plain text only
            out += k.text;
        } else {
            if (k.el->attr("x") || k.el->attr("y") || k.el->attr("dx") || k.el->attr("dy")) hasPositionedChild = true;
            out += collect_text(*k.el, hasPositionedChild);
        }
    }
    return out;
}
std::string decode_entities(std::string s) {
    const std::pair<const char*, const char*> table[] = {{"&lt;", "<"}, {"&gt;", ">"}, {"&quot;", "\""}, {"&apos;", "'"}, {"&amp;", "&"}};
    for (const auto& [from, to] : table) {
        std::size_t at = 0;
        while ((at = s.find(from, at)) != std::string::npos) {
            s.replace(at, std::strlen(from), to);
            at += std::strlen(to);
        }
    }
    return s;
}
std::string squeeze_space(const std::string& s) {
    std::string out;
    bool space = true;
    for (char c : s) {
        if (c == '\n' || c == '\r' || c == '\t' || c == ' ') {
            if (!space) out += ' ';
            space = true;
        } else {
            out += c;
            space = false;
        }
    }
    while (!out.empty() && out.back() == ' ') out.pop_back();
    return out;
}
}  // namespace

Json op_text_to_path(SvgDoc& doc, const std::vector<XNode*>& picked, const std::string& font, const Settings& s, std::vector<std::string>& warnings) {
    (void)doc;
    const char* cmd = "vector.text_to_path";
    std::vector<XNode*> texts;
    std::set<XNode*> seen;
    std::function<void(XNode*)> walk = [&](XNode* n) {
        if (n->local() == "text") {
            if (seen.insert(n).second) texts.push_back(n);
            return;
        }
        for (XNode* k : n->elements()) walk(k);
    };
    for (XNode* p : picked) walk(p);
    if (texts.empty())
        fail("invalid_argument", std::format("{} /elements: none of the picked elements is (or holds) a <text>.", cmd),
             "Pick a <text> element or a group of them, or give `text` to make new outlines.");
    struct Pending {
        XNode* node;
        Path path;
        TextMetrics m;
    };
    std::vector<Pending> pending;
    for (XNode* n : texts) {
        bool positioned = false;
        const std::string content = squeeze_space(decode_entities(collect_text(*n, positioned)));
        if (content.empty()) {
            warnings.push_back(std::format("{} has no text, so it was skipped.", label(*n)));
            continue;
        }
        if (positioned) warnings.push_back(std::format("{} has <tspan>s with their own x, y, dx or dy; their text is joined on one line.", label(*n)));
        double size = 16;
        if (!parse_font_size(*n, size)) warnings.push_back(std::format("{} has no font-size; 16 was used.", label(*n)));
        double x = 0, y = 0;
        auto first_number = [&](const char* name, double& out) {
            const std::string v = n->attr_or(name);
            if (v.empty()) return;
            std::string head = v.substr(0, v.find_first_of(", \t"));
            parse_length(head, out);
        };
        first_number("x", x);
        first_number("y", y);
        const std::string anchor = inherited_prop(*n, "text-anchor");
        const std::string family = inherited_prop(*n, "font-family");
        if (!family.empty() && font.empty())
            warnings.push_back(std::format("{} asks for font-family \"{}\"; the outline uses the default font because the engine cannot look fonts up by family name (pass `font`: \"builtin:serif\" or a project .ttf).", label(*n), family));
        if (!inherited_prop(*n, "font-weight").empty() && inherited_prop(*n, "font-weight") != "normal" && inherited_prop(*n, "font-weight") != "400")
            warnings.push_back(std::format("{} is {}; the outline uses the font's regular face.", label(*n), inherited_prop(*n, "font-weight")));
        Pending p;
        p.node = n;
        auto path = build_text(content, font, size, {x, y}, anchor == "middle" || anchor == "end" ? anchor : "start", 0, 1.0, &p.m);
        if (!path) fail("invalid_argument", std::format("{} /font: {}", cmd, path.error().message), path.error().hint);
        if (path->empty()) {
            warnings.push_back(std::format("{} has no character with an outline, so it was skipped.", label(*n)));
            continue;
        }
        if (!p.m.missing.empty()) warnings.push_back(std::format("{} has characters no font has ({} of them); they are left out.", label(*n), p.m.missing.size()));
        p.path = std::move(*path);
        pending.push_back(std::move(p));
    }
    if (pending.empty()) fail("empty_result", std::format("{}: none of the <text> elements has an outline to make.", cmd), "Give them text and check the font has its characters.");
    Json items = Json::array();
    for (Pending& p : pending) {
        XNode& n = *p.node;
        static const char* kTextAttrs[] = {"x", "y", "dx", "dy", "font-family", "font-size", "font-weight", "font-style", "text-anchor", "letter-spacing",
                                           "xml:space", "textLength", "lengthAdjust", "dominant-baseline", "text-decoration", "word-spacing"};
        for (const char* a : kTextAttrs) n.remove_attr(a);
        if (const std::string* st = n.attr("style")) {
            // drop the font declarations from the style attribute too
            std::string kept;
            std::size_t i = 0;
            while (i <= st->size()) {
                std::size_t e = st->find(';', i);
                if (e == std::string::npos) e = st->size();
                const std::string decl = st->substr(i, e - i);
                const std::string name(trim(decl.substr(0, decl.find(':'))));
                bool text = name.rfind("font", 0) == 0 || name == "text-anchor" || name == "letter-spacing" || name == "dominant-baseline" || name == "text-decoration" || name == "word-spacing";
                if (!decl.empty() && !text) kept += (kept.empty() ? "" : ";") + decl;
                i = e + 1;
            }
            if (kept.empty()) n.remove_attr("style");
            else n.set_attr("style", kept);
        }
        n.name = n.name.find(':') != std::string::npos ? n.name.substr(0, n.name.find(':') + 1) + "path" : "path";
        n.kids.clear();
        n.selfClosed = true;
        n.set_attr("d", path_to_data(p.path, s.outDecimals));
        const Rect b = path_bounds(transform_path(p.path, element_ctm(n)));
        items.push_back(Json::object({{"element", id_or_label(n)}, {"advance", r3(p.m.advance)}, {"glyphs", p.m.glyphs}, {"bounds", rect_json(b)}}));
    }
    return Json::object({{"results", items}});
}

// ---- mirror ---------------------------------------------------------------------------------------------------------------------

namespace {

struct Reflect {
    Axis axis;
    double at;
    P map(P p) const { return axis == Axis::Vertical ? P{2 * at - p.x, p.y} : P{p.x, 2 * at - p.y}; }
    Mat mat() const { return axis == Axis::Vertical ? Mat{-1, 0, 0, 1, 2 * at, 0} : Mat{1, 0, 0, -1, 0, 2 * at}; }
    double coord(P p) const { return axis == Axis::Vertical ? p.x : p.y; }
    P set(P p, double v) const { return axis == Axis::Vertical ? P{v, p.y} : P{p.x, v}; }
};

std::vector<Poly> snap_to_axis(std::vector<Poly> polys, const Reflect& r, double snap) {
    for (Poly& poly : polys)
        for (P& p : poly)
            if (std::fabs(r.coord(p) - r.at) <= snap) p = r.set(p, r.at);
    return polys;
}

}  // namespace

Json op_mirror(SvgDoc& doc, const std::vector<XNode*>& picked, const MirrorArgs& a, const Settings& s, std::vector<std::string>& warnings) {
    const char* cmd = "vector.mirror";
    const std::vector<XNode*> shapes = expand_shapes(picked, cmd, warnings);
    const Rect canvas = doc.canvas();
    struct Pending {
        XNode* node;
        Path local;
        Mat ctm;
        Reflect refl;
        std::vector<Poly> area;  // welded result, canvas space
        bool welded = false;
    };
    std::vector<Pending> pending;
    for (XNode* n : shapes) {
        Pending p;
        p.node = n;
        std::string why;
        if (!shape_path(*n, p.local, why)) fail("invalid_svg", std::format("{}: {}.", label(*n), why), "Fix the element in the SVG, or leave it out of `elements`.");
        p.ctm = element_ctm(*n);
        if (!p.ctm.invertible()) fail("invalid_svg", std::format("{} {}: its transform scales it to nothing, so a result cannot be written back.", cmd, label(*n)), "Fix the transform.");
        const Rect b = path_bounds(transform_path(p.local, p.ctm));
        p.refl.axis = a.axis;
        const bool v = a.axis == Axis::Vertical;
        if (a.atMode == "value") p.refl.at = a.at;
        else if (a.atMode == "start") p.refl.at = v ? b.x0 : b.y0;
        else if (a.atMode == "end") p.refl.at = v ? b.x1 : b.y1;
        else p.refl.at = v ? canvas.center().x : canvas.center().y;
        if (a.weld) {
            const Path drawn = transform_path(p.local, p.ctm);
            const bool evenOdd = inherited_prop(*n, "fill-rule") == "evenodd";
            std::vector<Poly> rings = fill_rings(drawn, s.tol * 0.5);
            if (rings.empty()) {
                warnings.push_back(std::format("{} is an open line with no area, so it cannot be welded; a mirrored copy was added instead.", label(*n)));
            } else {
                const double snap = a.snap.value_or(s.tol * 2);
                std::vector<Poly> own = snap_to_axis(normalize(rings, evenOdd, grid_of(s)), p.refl, snap);
                std::vector<Poly> twin;
                for (const Poly& poly : own) {
                    Poly m;
                    for (const P& q : poly) m.push_back(p.refl.map(q));
                    twin.push_back(std::move(m));
                }
                twin = normalize(twin, false, grid_of(s));
                own = normalize(own, false, grid_of(s));
                p.area = boolean_op(BoolOp::Union, own, twin, grid_of(s));
                p.welded = !p.area.empty();
            }
        }
        pending.push_back(std::move(p));
    }
    Json items = Json::array();
    for (Pending& p : pending) {
        XNode* n = p.node;
        const std::string id = id_or_label(*n);
        if (p.welded) {
            std::vector<Ring> rings;
            for (const Poly& poly : p.area) rings.push_back(Ring{poly, true});
            const Path canvasPath = s.curves ? fit_rings(rings, FitOptions{s.tol, s.cornerAngle}) : path_from_rings(rings);
            const Path local = transform_path(canvasPath, inverse(p.ctm));
            const Settings ls = local_settings(s, p.ctm.scale());
            set_path_geometry(*n, path_to_data(local, ls.outDecimals));
            items.push_back(Json::object({{"element", id}, {"welded", true}, {"nodes", node_count(local)}, {"axis", a.axis == Axis::Vertical ? "vertical" : "horizontal"},
                                          {"at", r3(p.refl.at)}, {"bounds", rect_json(path_bounds(canvasPath))}}));
        } else {
            // the mirrored copy: the same path through the reflection, written back in the shape's own space
            const Mat local = inverse(p.ctm) * p.refl.mat() * p.ctm;
            const Path mirrored = transform_path(p.local, local);
            std::unique_ptr<XNode> copy = SvgDoc::clone(*n);
            XNode* raw = doc.insert_after(n, std::move(copy));
            // ids inside the copy (a shape has only its own) get the suffix
            raw->set_attr("id", doc.unique_id((n->attr("id") && !n->attr("id")->empty() ? *n->attr("id") : n->local()) + "-mirror"));
            const Settings ls = local_settings(s, p.ctm.scale());
            set_path_geometry(*raw, path_to_data(mirrored, ls.outDecimals));
            items.push_back(Json::object({{"element", *raw->attr("id")}, {"mirrorOf", id}, {"welded", false}, {"axis", a.axis == Axis::Vertical ? "vertical" : "horizontal"},
                                          {"at", r3(p.refl.at)}, {"bounds", rect_json(path_bounds(transform_path(mirrored, p.ctm)))}}));
        }
    }
    return Json::object({{"results", items}});
}

// ---- shade ----------------------------------------------------------------------------------------------------------------------

namespace {

std::vector<Poly> shifted(const std::vector<Poly>& polys, P d) {
    std::vector<Poly> out = polys;
    for (Poly& poly : out)
        for (P& p : poly) p = p + d;
    return out;
}

}  // namespace

Json op_shade(SvgDoc& doc, const std::vector<XNode*>& picked, const ShadeArgs& a, const Settings& s, std::vector<std::string>& warnings) {
    const char* cmd = "vector.shade";
    const std::vector<XNode*> shapes = expand_shapes(picked, cmd, warnings);
    const double rad = a.lightDegrees * 3.14159265358979323846 / 180.0;
    const P toLight{std::cos(rad), -std::sin(rad)};  // screen space: y down
    PixelPalette pal;
    if (a.palette)
        for (const auto& c : *a.palette) pal.entries.push_back({"", c});
    bool warnedPalette = false;
    struct Band {
        std::string suffix, colour, opacity, source;
        std::vector<Poly> polys;
    };
    struct Pending {
        XNode* node;
        Mat ctm;
        std::vector<Band> bands;
        double depth;
    };
    std::vector<Pending> pending;
    const ClipGrid g = grid_of(s);
    for (XNode* n : shapes) {
        std::string why;
        Path local;
        if (!shape_path(*n, local, why)) fail("invalid_svg", std::format("{}: {}.", label(*n), why), "Fix the element in the SVG, or leave it out of `elements`.");
        const Mat ctm = element_ctm(*n);
        if (!ctm.invertible()) fail("invalid_svg", std::format("{} {}: its transform scales it to nothing, so a result cannot be written back.", cmd, label(*n)), "Fix the transform.");
        const Path drawn = transform_path(local, ctm);
        const std::vector<Poly> area = normalize(fill_rings(drawn, s.tol * 0.5), inherited_prop(*n, "fill-rule") == "evenodd", g);
        if (area.empty()) {
            warnings.push_back(std::format("{} covers no area (an open line has none), so it has no shading.", label(*n)));
            continue;
        }
        const Rect b = path_bounds(drawn);
        const double depth = a.depth.value_or(0.1 * std::min(b.width(), b.height()));
        if (!(depth > 0)) {
            warnings.push_back(std::format("{} is too thin to shade.", label(*n)));
            continue;
        }
        const double hdepth = a.highlightDepth.value_or(depth * 0.6);
        // the colours: the fill, shifted along the style palette's steps or in OKLab
        const std::string fill = inherited_prop(*n, "fill");
        std::array<std::uint8_t, 3> rgb{};
        double alpha = 1;
        const bool haveFill = parse_css_colour(fill.empty() ? "#000000" : fill, rgb, alpha) && !fill.empty();
        auto colour_for = [&](int direction, const std::string& given, std::string& source) -> std::string {
            if (!given.empty()) {
                source = "argument";
                return given;
            }
            if (!haveFill) return "";
            if (!pal.empty()) {
                if (auto idx = pal.find_rgb(rgb[0], rgb[1], rgb[2])) {
                    const int step = pal.step(*idx, direction);
                    if (step != *idx) {
                        source = pal.ramp_of(*idx) ? "palette ramp" : "palette";
                        return pal.hex(step);
                    }
                } else if (!warnedPalette) {
                    warnings.push_back(std::format("The fill {} of {} is not in the style palette, so the bands are OKLab shifts of it (vector.style with the palette snaps them afterwards).", hex_of(rgb), label(*n)));
                    warnedPalette = true;
                }
            }
            source = "oklab";
            return hex_of(oklab_shifted(rgb, direction, a.strength));
        };
        Pending p{n, ctm, {}, depth};
        auto add_band = [&](const char* suffix, bool wantIt, int direction, const std::string& given, double opacity, P away, double d) {
            if (!wantIt) return;
            std::string source;
            const std::string colour = colour_for(direction, given, source);
            if (colour.empty()) {
                warnings.push_back(std::format("{} is filled with {}: no colour to derive the {} from (pass `{}Colour`).", label(*n), fill.empty() ? "nothing" : fill, suffix, suffix));
                return;
            }
            // the shape minus itself pushed towards the light (shadow) or away from it (highlight) is what the push uncovers
            std::vector<Poly> band = boolean_op(BoolOp::Subtract, area, shifted(area, away * d), g);
            if (band.empty()) {
                warnings.push_back(std::format("The {} of {} is empty: the shape is thinner than the depth {}.", suffix, label(*n), r3(d)));
                return;
            }
            p.bands.push_back({suffix, colour, opacity < 1 ? format_number(opacity, 3) : std::string(), source, std::move(band)});
        };
        add_band("shadow", a.shadow, -1, a.shadowColour, a.shadowOpacity, toLight, depth);
        add_band("highlight", a.highlight, +1, a.highlightColour, a.highlightOpacity, toLight * -1.0, hdepth);
        if (!p.bands.empty()) pending.push_back(std::move(p));
    }
    if (pending.empty()) fail("empty_result", std::format("{}: no shape got a band.", cmd), "The shapes need a solid fill (or pass shadowColour / highlightColour) and a closed outline thicker than the depth.");
    Json items = Json::array();
    for (Pending& p : pending) {
        XNode* after = p.node;
        const Settings ls = local_settings(s, p.ctm.scale());
        Json made = Json::array();
        const std::string base = p.node->attr("id") && !p.node->attr("id")->empty() ? *p.node->attr("id") : p.node->local();
        for (Band& b : p.bands) {
            std::vector<Ring> rings;
            for (const Poly& poly : b.polys) rings.push_back(Ring{poly, true});
            const Path canvasPath = s.curves ? fit_rings(rings, FitOptions{s.tol, s.cornerAngle}) : path_from_rings(rings);
            const Path local = transform_path(canvasPath, inverse(p.ctm));
            auto node = make_element("path");
            const std::string id = doc.unique_id(base + "-" + b.suffix);
            node->set_attr("id", id);
            node->set_attr("d", path_to_data(local, ls.outDecimals));
            node->set_attr("fill", b.colour);
            node->set_attr("stroke", "none");
            if (!b.opacity.empty()) node->set_attr("opacity", b.opacity);
            if (const std::string* t = p.node->attr("transform")) node->set_attr("transform", *t);
            after = doc.insert_after(after, std::move(node));
            made.push_back(Json::object({{"element", id}, {"band", b.suffix}, {"fill", b.colour}, {"colourFrom", b.source}, {"nodes", node_count(local)}, {"bounds", rect_json(path_bounds(canvasPath))}}));
        }
        items.push_back(Json::object({{"shape", id_or_label(*p.node)}, {"depth", r3(p.depth)}, {"bands", made}}));
    }
    return Json::object({{"light", Json::object({{"degrees", r3(a.lightDegrees)}, {"label", light_direction_label(a.lightDegrees)}, {"from", a.lightSource}})}, {"results", items}});
}

}  // namespace fa::vec
