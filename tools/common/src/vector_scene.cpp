// A read-only scene of an SVG for tools that draw and pick (the editor's Vector panel): every drawable element with its style, bounds
// and outline in the drawing space, hit tests, and the engine's rasterizer for a region (fa/tooling/vector_edit.h).
#include <algorithm>
#include <cmath>
#include <format>

#include "assets_internal.h"
#include "fa/core/command.h"
#include "vector_ops.h"

namespace fa {

using vec::Mat;
using vec::Path;
using vec::Ring;
using vec::SubPath;
using vec::SvgDoc;
using vec::XNode;

namespace {

VecRect to_rect(const vec::Rect& r) { return {r.x0, r.y0, r.x1, r.y1}; }
void unite(VecRect& a, bool& has, const VecRect& b) {
    if (!has) {
        a = b;
        has = true;
        return;
    }
    a.x0 = std::min(a.x0, b.x0);
    a.y0 = std::min(a.y0, b.y0);
    a.x1 = std::max(a.x1, b.x1);
    a.y1 = std::max(a.y1, b.y1);
}

bool paint_visible(const std::string& v) { return v != "none" && v != "transparent"; }

double winding_of(const std::vector<std::vector<VecPoint>>& rings, VecPoint p, bool evenOdd) {
    int wn = 0;
    int crossings = 0;
    for (const auto& r : rings) {
        const std::size_t n = r.size();
        if (n < 3) continue;
        for (std::size_t i = 0; i < n; ++i) {
            const VecPoint a = r[i], b = r[(i + 1) % n];
            if ((a.y <= p.y) != (b.y <= p.y)) {
                const double t = (p.y - a.y) / (b.y - a.y);
                const double x = a.x + t * (b.x - a.x);
                if (x > p.x) {
                    ++crossings;
                    wn += b.y > a.y ? 1 : -1;
                }
            }
        }
    }
    return evenOdd ? double(crossings & 1) : double(wn != 0);
}

double distance_to_segment(VecPoint p, VecPoint a, VecPoint b) {
    const double dx = b.x - a.x, dy = b.y - a.y;
    const double l2 = dx * dx + dy * dy;
    double t = l2 < 1e-18 ? 0 : ((p.x - a.x) * dx + (p.y - a.y) * dy) / l2;
    t = std::clamp(t, 0.0, 1.0);
    const double qx = a.x + t * dx - p.x, qy = a.y + t * dy - p.y;
    return std::sqrt(qx * qx + qy * qy);
}

}  // namespace

int VecScene::find(const std::string& ref) const {
    if (ref.empty()) return -1;
    for (const VecItem& it : items)
        if (it.id == ref) return it.index;
    for (const VecItem& it : items)
        if (it.ref == ref) return it.index;
    return -1;
}

std::vector<int> VecScene::roots() const {
    std::vector<int> out;
    for (const VecItem& it : items)
        if (it.parent < 0) out.push_back(it.index);
    return out;
}

bool VecScene::is_descendant(int item, int ancestor) const {
    if (item < 0 || item >= int(items.size())) return false;
    for (int p = items[std::size_t(item)].parent; p >= 0; p = items[std::size_t(p)].parent)
        if (p == ancestor) return true;
    return false;
}

int VecScene::pick_in_context(int item, int context) const {
    if (item < 0 || item >= int(items.size())) return -1;
    if (context >= 0 && !is_descendant(item, context)) context = -1;
    int cur = item;
    while (items[std::size_t(cur)].parent != context && items[std::size_t(cur)].parent >= 0) cur = items[std::size_t(cur)].parent;
    return cur;
}

Result<VecScene> vector_scene(const std::string& svg) {
    SvgDoc doc;
    try {
        doc = SvgDoc::parse(svg, "the SVG");
    } catch (const CommandError& e) {
        return Error{e.what(), e.hint};
    }
    VecScene sc;
    sc.canvas = to_rect(doc.canvas());
    const vec::P declared = doc.declared_size();
    sc.declaredWidth = declared.x;
    sc.declaredHeight = declared.y;
    sc.warnings = vec::document_warnings(doc);
    const double side = std::max({sc.canvas.width(), sc.canvas.height(), 1.0});
    const double flatTol = std::max(side / 4000.0, 1e-4);

    auto add_children = [&](auto&& self, XNode& parent, int parentItem, int depth) -> void {
        for (XNode* k : parent.elements()) {
            const bool shape = vec::is_shape_element(*k);
            const bool group = !shape && vec::is_group_element(*k) && k->local() != "svg";
            if (!shape && !group) continue;
            if (vec::in_inert_subtree(*k)) continue;
            VecItem it;
            it.index = int(sc.items.size());
            it.parent = parentItem;
            it.depth = depth;
            it.tag = k->local();
            it.id = k->attr_or("id");
            it.ref = it.id.empty() ? vec::element_selector(*k) : it.id;
            if (it.id.empty()) ++sc.unnamed;
            it.isGroup = group;
            it.hidden = vec::own_prop(*k, "display") == "none";
            it.locked = k->attr_or("data-locked") == "true";
            if (parentItem >= 0) {
                const VecItem& par = sc.items[std::size_t(parentItem)];
                it.hiddenByAncestor = par.hidden || par.hiddenByAncestor;
                it.lockedByAncestor = par.locked || par.lockedByAncestor;
                sc.items[std::size_t(parentItem)].children.push_back(it.index);
            }
            it.fill = vec::inherited_prop(*k, "fill");
            it.stroke = vec::inherited_prop(*k, "stroke");
            const std::string fr = vec::inherited_prop(*k, "fill-rule");
            it.fillRule = fr == "evenodd" ? "evenodd" : "nonzero";
            double sw = 1;
            const std::string sws = vec::inherited_prop(*k, "stroke-width");
            if (!sws.empty()) vec::parse_length(sws, sw);
            it.strokeWidth = sw;
            const std::string op = vec::own_prop(*k, "opacity");
            if (!op.empty()) {
                char* end = nullptr;
                const double v = std::strtod(op.c_str(), &end);
                if (end != op.c_str()) it.opacity = std::clamp(v, 0.0, 1.0);
            }
            it.transform = k->attr_or("transform");
            it.shapeKind = k->attr_or("data-fa-shape");
            it.shapeArgs = k->attr_or("data-fa-args");
            const int index = it.index;
            if (shape) {
                Path local;
                std::string why;
                if (!vec::shape_path(*k, local, why)) {
                    it.problem = why;
                } else {
                    const Mat m = vec::element_ctm(*k);
                    const Path dp = vec::transform_path(local, m);
                    it.nodes = nodes_from_path(dp);
                    for (const Ring& r : vec::flatten_path(dp, flatTol)) {
                        std::vector<VecPoint> pts;
                        pts.reserve(r.pts.size());
                        for (const vec::P& q : r.pts) pts.push_back({q.x, q.y});
                        it.rings.push_back(std::move(pts));
                        it.ringClosed.push_back(r.closed);
                    }
                    it.nodeCount = vec::node_count(dp);
                    it.curves = vec::has_curves(dp);
                    it.closed = !dp.empty() && std::all_of(dp.begin(), dp.end(), [](const SubPath& s) { return s.closed; });
                    const vec::Rect b = vec::path_bounds(dp);
                    if (!b.empty()) {
                        it.bounds = to_rect(b);
                        it.hasBounds = true;
                        const double half = !it.stroke.empty() && paint_visible(it.stroke) ? it.strokeWidth * m.scale() * 0.5 : 0;
                        it.visualBounds = {b.x0 - half, b.y0 - half, b.x1 + half, b.y1 + half};
                    }
                }
            }
            sc.items.push_back(std::move(it));
            if (group) self(self, *k, index, depth + 1);
        }
    };
    add_children(add_children, *doc.root(), -1, 0);
    // a group's bounds are the union of what it holds: children come after their parent, so go from the back
    std::vector<char> grouped(sc.items.size(), 0);
    for (int i = int(sc.items.size()) - 1; i >= 0; --i) {
        const VecItem& it = sc.items[std::size_t(i)];
        if (it.parent < 0 || !it.hasBounds) continue;
        VecItem& par = sc.items[std::size_t(it.parent)];
        if (!grouped[std::size_t(it.parent)]) {
            par.bounds = it.bounds;
            par.visualBounds = it.visualBounds;
            par.hasBounds = true;
            grouped[std::size_t(it.parent)] = 1;
        } else {
            bool h = true;
            unite(par.bounds, h, it.bounds);
            unite(par.visualBounds, h, it.visualBounds);
        }
    }
    return sc;
}

int vector_hit_test(const VecScene& scene, VecPoint p, double tolerance, bool skipLocked) {
    for (int i = int(scene.items.size()) - 1; i >= 0; --i) {
        const VecItem& it = scene.items[std::size_t(i)];
        if (it.isGroup || !it.hasBounds || !it.problem.empty()) continue;
        if (it.hidden || it.hiddenByAncestor) continue;
        if (skipLocked && (it.locked || it.lockedByAncestor)) continue;
        const VecRect vb = it.visualBounds;
        if (p.x < vb.x0 - tolerance || p.x > vb.x1 + tolerance || p.y < vb.y0 - tolerance || p.y > vb.y1 + tolerance) continue;
        const bool filled = it.fill.empty() || paint_visible(it.fill);
        const bool stroked = !it.stroke.empty() && paint_visible(it.stroke);
        if (!filled && !stroked) continue;
        if (filled && winding_of(it.rings, p, it.fillRule == "evenodd") > 0) return i;
        // the stroke, or the outline of a shape with no fill; a small tolerance so thin lines can be clicked
        const double reach = stroked ? std::max(tolerance, it.visualBounds.x1 - it.bounds.x1) : tolerance;
        for (std::size_t r = 0; r < it.rings.size(); ++r) {
            const auto& ring = it.rings[r];
            const std::size_t n = ring.size();
            if (n == 1 && distance_to_segment(p, ring[0], ring[0]) <= reach) return i;
            for (std::size_t k = 0; k < n; ++k) {
                if (k + 1 == n && !it.ringClosed[r]) break;
                if (distance_to_segment(p, ring[k], ring[(k + 1) % n]) <= reach) return i;
            }
        }
    }
    return -1;
}

std::vector<int> vector_shapes_in_rect(const VecScene& scene, const VecRect& box, bool touch, bool skipLocked) {
    std::vector<int> out;
    for (const VecItem& it : scene.items) {
        if (it.isGroup || !it.hasBounds) continue;
        if (it.hidden || it.hiddenByAncestor) continue;
        if (skipLocked && (it.locked || it.lockedByAncestor)) continue;
        const VecRect b = it.visualBounds;
        const bool inside = b.x0 >= box.x0 && b.x1 <= box.x1 && b.y0 >= box.y0 && b.y1 <= box.y1;
        if (inside || (touch && b.intersects(box))) out.push_back(it.index);
    }
    return out;
}

Result<Image> vector_rasterize(const std::string& svg, const VecRect* region, int width, int height, std::vector<std::string>* warnings) {
    if (width < 1 || height < 1 || width > 16384 || height > 16384)
        return Error{std::format("The picture size {}x{} is outside 1 to 16384 pixels.", width, height), "Ask for the size of the part of the screen that shows the drawing."};
    try {
        std::string text = svg;
        if (region) {
            SvgDoc doc = SvgDoc::parse(svg, "the SVG");
            VecRect r = *region;
            if (!(r.width() > 0) || !(r.height() > 0)) return Error{"The region to draw is empty.", "Give a region with a width and a height above 0."};
            XNode* root = doc.root();
            root->set_attr("viewBox", std::format("{:.9g} {:.9g} {:.9g} {:.9g}", r.x0, r.y0, r.width(), r.height()));
            root->set_attr("width", std::to_string(width));
            root->set_attr("height", std::to_string(height));
            root->set_attr("preserveAspectRatio", "none");
            text = doc.write();
        }
        std::vector<std::string> w;
        assets_detail::SvgRaster raster = assets_detail::rasterize_svg_text(text, width, height, "none", 0.0, 0, w);
        if (warnings)
            for (const std::string& s : w)
                if (std::find(warnings->begin(), warnings->end(), s) == warnings->end()) warnings->push_back(s);
        return std::move(raster.image);
    } catch (const CommandError& e) {
        return Error{e.what(), e.hint};
    }
}

}  // namespace fa
