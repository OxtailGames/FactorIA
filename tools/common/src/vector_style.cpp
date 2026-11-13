// vector.style: the project's style guide (assets.json "style") applied to an SVG: the outline around shapes and the colours snapped
// to the palette. The guide is read by fa::load_style_guide (fa/tooling/style_guide.h); this file only edits the SVG.
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <format>
#include <map>
#include <set>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "vector_ops.h"

namespace fa::vec {

namespace {

double r3(double v) { return std::round(v * 1000.0) / 1000.0; }

std::string lower(std::string s) {
    for (char& c : s) c = char(std::tolower((unsigned char)c));
    return s;
}

int hex_value(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

std::string hex_of(const std::array<std::uint8_t, 3>& c) { return std::format("#{:02x}{:02x}{:02x}", c[0], c[1], c[2]); }

}  // namespace

bool parse_css_colour(const std::string& textIn, std::array<std::uint8_t, 3>& rgb, double& alpha) {
    std::string t = textIn;
    while (!t.empty() && (t.back() == ' ' || t.back() == '\t')) t.pop_back();
    std::size_t a = 0;
    while (a < t.size() && (t[a] == ' ' || t[a] == '\t')) ++a;
    t = t.substr(a);
    alpha = 1.0;
    if (t.empty()) return false;
    const std::string l = lower(t);
    if (l == "none" || l == "transparent" || l == "currentcolor" || l == "inherit" || l.rfind("url(", 0) == 0) return false;
    if (l.rfind("rgb", 0) == 0) {
        const std::size_t open = l.find('('), close = l.find(')');
        if (open == std::string::npos || close == std::string::npos || close < open) return false;
        std::vector<double> v;
        std::vector<bool> pct;
        std::string body = l.substr(open + 1, close - open - 1);
        for (char& c : body)
            if (c == ',' || c == '/') c = ' ';
        const char* p = body.c_str();
        while (*p) {
            while (*p == ' ') ++p;
            if (!*p) break;
            char* end = nullptr;
            const double d = std::strtod(p, &end);
            if (end == p) return false;
            const bool pc = *end == '%';
            v.push_back(d);
            pct.push_back(pc);
            p = pc ? end + 1 : end;
        }
        if (v.size() < 3) return false;
        for (int i = 0; i < 3; ++i) rgb[i] = std::uint8_t(std::clamp(std::lround(pct[i] ? v[i] * 2.55 : v[i]), 0L, 255L));
        if (v.size() >= 4) alpha = std::clamp(pct[3] ? v[3] / 100.0 : v[3], 0.0, 1.0);
        return true;
    }
    if (t[0] == '#') {
        const std::string h = t.substr(1);
        int d[8] = {};
        if (h.size() != 3 && h.size() != 4 && h.size() != 6 && h.size() != 8) return false;
        for (std::size_t i = 0; i < h.size(); ++i) {
            d[i] = hex_value(h[i]);
            if (d[i] < 0) return false;
        }
        if (h.size() <= 4) {
            for (int i = 0; i < 3; ++i) rgb[i] = std::uint8_t(d[i] * 17);
            if (h.size() == 4) alpha = d[3] * 17 / 255.0;
        } else {
            for (int i = 0; i < 3; ++i) rgb[i] = std::uint8_t(d[i * 2] * 16 + d[i * 2 + 1]);
            if (h.size() == 8) alpha = (d[6] * 16 + d[7]) / 255.0;
        }
        return true;
    }
    Color c;
    if (!parse_color(t, c)) return false;
    rgb = {std::uint8_t(std::lround(c.r * 255)), std::uint8_t(std::lround(c.g * 255)), std::uint8_t(std::lround(c.b * 255))};
    alpha = c.a;
    return true;
}

Json op_style(SvgDoc& doc, const std::vector<XNode*>& picked, bool wholeDocument, const StyleArgs& a, std::vector<std::string>& warnings) {
    const char* cmd = "vector.style";
    std::vector<XNode*> nodes;
    std::vector<XNode*> shapes;
    if (wholeDocument) {
        for (XNode* n : doc.all_elements()) {
            if (n == doc.root()) continue;
            nodes.push_back(n);
            if (is_shape_element(*n) && !in_inert_subtree(*n)) shapes.push_back(n);
        }
    } else {
        std::set<XNode*> seen;
        for (XNode* p : picked) {
            std::vector<XNode*> stack{p};
            while (!stack.empty()) {
                XNode* x = stack.back();
                stack.pop_back();
                if (seen.insert(x).second) nodes.push_back(x);
                for (XNode* k : x->elements()) stack.push_back(k);
            }
        }
        std::map<XNode*, std::size_t> order;
        for (XNode* x : doc.all_elements()) order.emplace(x, order.size());
        std::sort(nodes.begin(), nodes.end(), [&](XNode* x, XNode* y) { return order[x] < order[y]; });
        shapes = expand_shapes(picked, cmd, warnings);
    }
    Json r = Json::object();
    if (a.outlineWidth) {
        const Rect canvas = doc.canvas();
        const P declared = doc.declared_size();
        const double unitsPerPixel = declared.x > 0 ? canvas.width() / declared.x : 1.0;
        const double wCanvas = *a.outlineWidth * unitsPerPixel;
        int outlined = 0, skipped = 0;
        for (XNode* n : shapes) {
            const std::string fill = inherited_prop(*n, "fill");
            if (fill == "none" || fill == "transparent") {
                ++skipped;
                continue;
            }
            const Mat ctm = element_ctm(*n);
            if (!ctm.invertible()) {
                warnings.push_back(std::format("{} has a transform that scales it to nothing, so it got no outline.", describe_element(*n)));
                continue;
            }
            set_prop(*n, "stroke", a.outlineColour);
            set_prop(*n, "stroke-width", format_number(wCanvas / ctm.scale(), 4));
            ++outlined;
        }
        r["outlined"] = outlined;
        r["outlineWidthUnits"] = r3(wCanvas);
        if (skipped) r["outlineSkippedNoFill"] = skipped;
        if (outlined == 0) warnings.push_back("No shape has a fill, so no outline was added (an outline goes around filled shapes; line art already has its strokes).");
    }
    if (a.palette) {
        const auto& pal = *a.palette;
        int changed = 0;
        std::map<std::string, std::string> mapping;
        for (XNode* n : nodes) {
            for (const char* prop : {"fill", "stroke", "stop-color"}) {
                const std::string v = own_prop(*n, prop);
                std::array<std::uint8_t, 3> rgb{};
                double alpha = 1;
                if (v.empty() || !parse_css_colour(v, rgb, alpha)) continue;
                std::size_t best = 0;
                long bestD = -1;
                for (std::size_t i = 0; i < pal.size(); ++i) {
                    const long dr = long(rgb[0]) - pal[i][0], dg = long(rgb[1]) - pal[i][1], db = long(rgb[2]) - pal[i][2];
                    const long d = dr * dr + dg * dg + db * db;
                    if (bestD < 0 || d < bestD) {
                        bestD = d;
                        best = i;
                    }
                }
                std::string to = hex_of(pal[best]);
                if (alpha < 1.0 - 1e-9) to += std::format("{:02x}", int(std::lround(alpha * 255)));
                if (lower(v) == to) continue;
                set_prop(*n, prop, to);
                mapping[lower(v)] = to;
                ++changed;
            }
        }
        r["recoloured"] = changed;
        Json list = Json::array();
        for (const auto& [from, to] : mapping) {
            if (list.size() >= 24) break;
            list.push_back(Json::object({{"from", from}, {"to", to}}));
        }
        r["colours"] = list;
        if (changed == 0) r["note"] = "Every colour was already in the palette.";
    }
    return r;
}

}  // namespace fa::vec
