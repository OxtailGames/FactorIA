// See assets_svg_layers.h.
#include "assets_svg_layers.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <format>
#include <map>
#include <memory>
#include <set>

#include "nanosvg.h"
#include "nanosvgrast.h"

#include "fa/core/strings.h"

namespace fa::assets_detail {

namespace {

// ---- a small, tolerant XML tree (elements, attributes, text; comments, processing instructions and doctype are dropped) ----

struct Attr {
    std::string name, value;
    char quote = '"';
};

struct Node {
    std::string name;  // empty for a text node
    std::vector<Attr> attrs;
    std::vector<std::unique_ptr<Node>> kids;
    Node* parent = nullptr;
    std::string text;
};

std::string trims(const std::string& s) { return std::string(trim(s)); }

bool is_space(char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r'; }

std::unique_ptr<Node> parse_xml(const std::string& s) {
    auto root = std::make_unique<Node>();  // a document node; the <svg> element is its child
    Node* cur = root.get();
    std::size_t i = 0;
    const std::size_t n = s.size();
    while (i < n) {
        if (s[i] != '<') {
            const std::size_t e = s.find('<', i);
            const std::size_t end = e == std::string::npos ? n : e;
            if (cur != root.get()) {
                auto t = std::make_unique<Node>();
                t->text = s.substr(i, end - i);
                t->parent = cur;
                cur->kids.push_back(std::move(t));
            }
            i = end;
            continue;
        }
        if (s.compare(i, 4, "<!--") == 0) {
            const std::size_t e = s.find("-->", i + 4);
            i = e == std::string::npos ? n : e + 3;
            continue;
        }
        if (s.compare(i, 9, "<![CDATA[") == 0) {
            const std::size_t e = s.find("]]>", i + 9);
            const std::size_t end = e == std::string::npos ? n : e;
            if (cur != root.get()) {
                auto t = std::make_unique<Node>();
                t->text = s.substr(i + 9, end - i - 9);
                t->parent = cur;
                cur->kids.push_back(std::move(t));
            }
            i = e == std::string::npos ? n : e + 3;
            continue;
        }
        if (s.compare(i, 2, "<?") == 0 || s.compare(i, 2, "<!") == 0) {
            const std::size_t e = s.find('>', i);
            i = e == std::string::npos ? n : e + 1;
            continue;
        }
        if (s.compare(i, 2, "</") == 0) {
            const std::size_t e = s.find('>', i);
            std::string name = s.substr(i + 2, (e == std::string::npos ? n : e) - i - 2);
            while (!name.empty() && is_space(name.back())) name.pop_back();
            for (Node* p = cur; p && p != root.get(); p = p->parent)
                if (p->name == name) {
                    cur = p->parent;
                    break;
                }
            i = e == std::string::npos ? n : e + 1;
            continue;
        }
        // a start tag
        ++i;
        auto el = std::make_unique<Node>();
        while (i < n && !is_space(s[i]) && s[i] != '/' && s[i] != '>') el->name += s[i++];
        bool selfClose = false;
        while (i < n && s[i] != '>') {
            if (is_space(s[i])) {
                ++i;
                continue;
            }
            if (s[i] == '/') {
                selfClose = true;
                ++i;
                continue;
            }
            Attr a;
            while (i < n && !is_space(s[i]) && s[i] != '=' && s[i] != '>' && s[i] != '/') a.name += s[i++];
            while (i < n && is_space(s[i])) ++i;
            if (i < n && s[i] == '=') {
                ++i;
                while (i < n && is_space(s[i])) ++i;
                if (i < n && (s[i] == '"' || s[i] == '\'')) {
                    a.quote = s[i++];
                    while (i < n && s[i] != a.quote) a.value += s[i++];
                    if (i < n) ++i;
                } else {
                    while (i < n && !is_space(s[i]) && s[i] != '>') a.value += s[i++];
                }
            }
            if (!a.name.empty()) el->attrs.push_back(std::move(a));
        }
        if (i < n) ++i;
        el->parent = cur;
        Node* raw = el.get();
        cur->kids.push_back(std::move(el));
        if (!selfClose) cur = raw;
    }
    return root;
}

const std::string* attr_of(const Node& n, const char* name) {
    for (const Attr& a : n.attrs)
        if (a.name == name) return &a.value;
    return nullptr;
}

// A presentation property: from the style attribute when it has it, else from the attribute of the same name.
std::string prop_of(const Node& n, const char* name) {
    if (const std::string* st = attr_of(n, "style")) {
        std::size_t pos = 0;
        std::string found;
        while (pos < st->size()) {
            std::size_t semi = st->find(';', pos);
            if (semi == std::string::npos) semi = st->size();
            const std::string decl = st->substr(pos, semi - pos);
            const std::size_t colon = decl.find(':');
            if (colon != std::string::npos && trims(decl.substr(0, colon)) == name) found = trims(decl.substr(colon + 1));
            pos = semi + 1;
        }
        if (!found.empty()) return found;
    }
    if (const std::string* v = attr_of(n, name)) return trims(*v);
    return {};
}

// "url(#id)" (quotes allowed) to "id"; empty when the value is not a local reference.
std::string url_id(const std::string& v) {
    const std::size_t a = v.find("url(");
    if (a == std::string::npos) return {};
    const std::size_t h = v.find('#', a);
    const std::size_t e = v.find(')', a);
    if (h == std::string::npos || e == std::string::npos || h > e) return {};
    std::string id = v.substr(h + 1, e - h - 1);
    while (!id.empty() && (id.back() == '\'' || id.back() == '"' || is_space(id.back()))) id.pop_back();
    return id;
}

bool is_shape(const std::string& n) { return n == "path" || n == "rect" || n == "circle" || n == "ellipse" || n == "line" || n == "polyline" || n == "polygon"; }

// Elements whose children are definitions or other content that is not drawn where it stands.
bool is_inert(const std::string& n) {
    static const char* const kNames[] = {"defs", "clipPath", "mask", "pattern", "symbol", "marker", "linearGradient", "radialGradient", "style", "title", "desc",
                                         "metadata", "filter", "text", "image", "foreignObject", "script"};
    for (const char* k : kNames)
        if (n == k) return true;
    return false;
}

// ---- affine transforms ----

struct Mat {
    double a = 1, b = 0, c = 0, d = 1, e = 0, f = 0;  // x' = a x + c y + e, y' = b x + d y + f
};

Mat mul(const Mat& p, const Mat& q) {  // apply q first, then p
    return {p.a * q.a + p.c * q.b, p.b * q.a + p.d * q.b, p.a * q.c + p.c * q.d, p.b * q.c + p.d * q.d, p.a * q.e + p.c * q.f + p.e, p.b * q.e + p.d * q.f + p.f};
}

void apply(const Mat& m, double x, double y, double& ox, double& oy) {
    ox = m.a * x + m.c * y + m.e;
    oy = m.b * x + m.d * y + m.f;
}

bool invert(const Mat& m, Mat& out) {
    const double det = m.a * m.d - m.b * m.c;
    if (std::fabs(det) < 1e-12) return false;
    out.a = m.d / det;
    out.b = -m.b / det;
    out.c = -m.c / det;
    out.d = m.a / det;
    out.e = (m.c * m.f - m.d * m.e) / det;
    out.f = (m.b * m.e - m.a * m.f) / det;
    return true;
}

std::vector<double> numbers_of(const std::string& s) {
    std::vector<double> v;
    const char* p = s.c_str();
    while (*p) {
        char* end = nullptr;
        const double d = std::strtod(p, &end);
        if (end == p) {
            ++p;
            continue;
        }
        v.push_back(d);
        p = end;
    }
    return v;
}

Mat parse_transform(const std::string& s) {
    Mat m;
    std::size_t i = 0;
    while (i < s.size()) {
        const std::size_t open = s.find('(', i);
        if (open == std::string::npos) break;
        const std::size_t close = s.find(')', open);
        if (close == std::string::npos) break;
        const std::string name = trims(s.substr(i, open - i));
        const std::vector<double> v = numbers_of(s.substr(open + 1, close - open - 1));
        Mat t;
        const double pi = 3.14159265358979323846;
        if (name.find("matrix") != std::string::npos && v.size() >= 6) t = {v[0], v[1], v[2], v[3], v[4], v[5]};
        else if (name.find("translate") != std::string::npos && !v.empty()) t.e = v[0], t.f = v.size() > 1 ? v[1] : 0;
        else if (name.find("scale") != std::string::npos && !v.empty()) t.a = v[0], t.d = v.size() > 1 ? v[1] : v[0];
        else if (name.find("rotate") != std::string::npos && !v.empty()) {
            const double r = v[0] * pi / 180.0, cs = std::cos(r), sn = std::sin(r);
            t = {cs, sn, -sn, cs, 0, 0};
            if (v.size() >= 3) t = mul(mul(Mat{1, 0, 0, 1, v[1], v[2]}, t), Mat{1, 0, 0, 1, -v[1], -v[2]});
        } else if (name.find("skewX") != std::string::npos && !v.empty()) t.c = std::tan(v[0] * pi / 180.0);
        else if (name.find("skewY") != std::string::npos && !v.empty()) t.b = std::tan(v[0] * pi / 180.0);
        m = mul(m, t);
        i = close + 1;
    }
    return m;
}

Mat transform_of(const Node& n) {
    const std::string* t = attr_of(n, "transform");
    return t ? parse_transform(*t) : Mat{};
}

// ---- serialization ----

std::string open_tag(const Node& n, const std::string& extra, const std::set<std::string>& drop = {}) {
    std::string out = "<" + n.name;
    for (const Attr& a : n.attrs) {
        if (drop.count(a.name)) continue;
        out += " " + a.name + "=" + a.quote + a.value + a.quote;
    }
    return out + extra + ">";
}

void emit_all(const Node& n, const std::string& leafExtra, std::string& out) {
    if (n.name.empty()) {
        out += n.text;
        return;
    }
    out += open_tag(n, is_shape(n.name) ? leafExtra : std::string());
    for (const auto& k : n.kids) emit_all(*k, leafExtra, out);
    out += "</" + n.name + ">";
}

// `path`: the elements from just below <svg> down to the last one; each as a <g> with only its transform.
std::string transform_context_open(const std::vector<const Node*>& path) {
    std::string out;
    for (const Node* n : path) {
        const std::string* t = attr_of(*n, "transform");
        out += t ? "<g transform=\"" + *t + "\">" : "<g>";
    }
    return out;
}

std::string closes(std::size_t count) {
    std::string out;
    for (std::size_t i = 0; i < count; ++i) out += "</g>";
    return out;
}


// ---- the layered renderer ----

struct Ref {
    const Node* owner = nullptr;  // the element that carries clip-path / mask
    const Node* def = nullptr;    // the <clipPath> / <mask>
    std::vector<const Node*> ownerPath;
    bool operator==(const Ref& o) const { return owner == o.owner && def == o.def; }
};

struct Leaf {
    const Node* node = nullptr;
    std::string extra;
    std::vector<const Node*> path;  // from below <svg> down to the leaf (the leaf included)
};

struct Unit {
    std::vector<Leaf> leaves;
    std::vector<Ref> clips, masks;
    const Node* pattern = nullptr;
};

struct Renderer {
    const Node* svgRoot = nullptr;
    std::string head;  // <svg ...><defs>gradients</defs>
    int w = 0, h = 0;
    float tx = 0, ty = 0, scale = 1;
    double mapSx = 1, mapSy = 1, mapTx = 0, mapTy = 0;  // user units of the root -> nanosvg image px
    std::map<std::string, const Node*> ids;
    std::vector<Unit> units;
    std::vector<std::string>* warnings = nullptr;
    bool used = false;
    NSVGrasterizer* rast = nullptr;

    void warn(const std::string& m) {
        if (std::find(warnings->begin(), warnings->end(), m) == warnings->end()) warnings->push_back(m);
    }

    // The RGBA (straight alpha) of a complete SVG document at the output size.
    std::vector<std::uint8_t> render(const std::string& body, NSVGimage** imageOut = nullptr) {
        std::string doc = head + body + "</svg>";
        std::vector<char> buf(doc.begin(), doc.end());
        buf.push_back('\0');
        NSVGimage* img = nsvgParse(buf.data(), "px", 96.0f);
        std::vector<std::uint8_t> px(std::size_t(w) * h * 4, 0);
        if (img) {
            nsvgRasterize(rast, img, tx, ty, scale, px.data(), w, h, w * 4);
            if (imageOut) {
                *imageOut = img;
                return px;
            }
            nsvgDelete(img);
        }
        return px;
    }

    // Bounds [minx,miny,maxx,maxy] in root user units of a shape without its own transform.
    bool user_bounds(const Node& leaf, double out[4]) {
        std::string doc = head + open_tag(leaf, " stroke=\"none\"", {"transform"});
        for (const auto& k : leaf.kids) emit_all(*k, "", doc);
        doc += "</" + leaf.name + "></svg>";
        std::vector<char> buf(doc.begin(), doc.end());
        buf.push_back('\0');
        NSVGimage* img = nsvgParse(buf.data(), "px", 96.0f);
        if (!img) return false;
        bool ok = false;
        if (img->shapes) {
            out[0] = (img->shapes->bounds[0] - mapTx) / mapSx;
            out[1] = (img->shapes->bounds[1] - mapTy) / mapSy;
            out[2] = (img->shapes->bounds[2] - mapTx) / mapSx;
            out[3] = (img->shapes->bounds[3] - mapTy) / mapSy;
            ok = true;
        }
        nsvgDelete(img);
        return ok;
    }

    std::string selection_markup(const std::vector<Leaf>& leaves) {
        std::set<const Node*> keep;
        std::map<const Node*, std::string> extra;
        for (const Leaf& l : leaves) {
            for (const Node* n : l.path) keep.insert(n);
            extra[l.node] = l.extra;
        }
        std::string out;
        emit_selected(*svgRoot, keep, extra, out);
        return out;
    }

    void emit_selected(const Node& parent, const std::set<const Node*>& keep, const std::map<const Node*, std::string>& extra, std::string& out) {
        for (const auto& k : parent.kids) {
            if (k->name.empty() || !keep.count(k.get())) continue;
            auto it = extra.find(k.get());
            if (it != extra.end()) {
                emit_all(*k, it->second, out);
            } else {
                out += open_tag(*k, "");
                emit_selected(*k, keep, extra, out);
                out += "</" + k->name + ">";
            }
        }
    }

    // ---- walking the document in paint order ----

    struct Walk {
        std::vector<const Node*> path;
        std::vector<Ref> clips, masks;
    };

    void add_unit(Unit u) {
        if (!units.empty() && !u.pattern && !units.back().pattern && units.back().clips == u.clips && units.back().masks == u.masks) {
            for (Leaf& l : u.leaves) units.back().leaves.push_back(std::move(l));
            return;
        }
        units.push_back(std::move(u));
    }

    std::string inherited(const std::vector<const Node*>& path, const char* name) {
        for (auto it = path.rbegin(); it != path.rend(); ++it) {
            std::string v = prop_of(**it, name);
            if (!v.empty()) return v;
        }
        return {};
    }

    void add_refs(const Node& n, const Walk& w, Walk& next) {
        next = w;
        const std::string cp = prop_of(n, "clip-path");
        if (!cp.empty() && cp != "none") {
            const std::string id = url_id(cp);
            auto it = ids.find(id);
            if (id.empty() || it == ids.end() || it->second->name != "clipPath") {
                warn("clip-path \"" + cp + "\" does not point to a <clipPath> of this SVG; the element is drawn unclipped.");
            } else if (prop_of(*it->second, "clipPathUnits") == "objectBoundingBox") {
                warn("clipPath \"" + id + "\" uses clipPathUnits=\"objectBoundingBox\", which is not supported; use userSpaceOnUse (real coordinates). The element is drawn unclipped.");
            } else {
                used = true;
                next.clips.push_back({&n, it->second, next.path});
            }
        }
        const std::string mk = prop_of(n, "mask");
        if (!mk.empty() && mk != "none") {
            const std::string id = url_id(mk);
            auto it = ids.find(id);
            if (id.empty() || it == ids.end() || it->second->name != "mask") warn("mask \"" + mk + "\" does not point to a <mask> of this SVG; the element is drawn unmasked.");
            else {
                used = true;
                next.masks.push_back({&n, it->second, next.path});
            }
        }
    }

    void walk(const Node& parent, const Walk& w) {
        for (const auto& k : parent.kids) {
            const Node& n = *k;
            if (n.name.empty() || is_inert(n.name)) continue;
            Walk next;
            next.path = w.path;
            next.path.push_back(&n);
            next.clips = w.clips;
            next.masks = w.masks;
            Walk withRefs;
            withRefs.path = next.path;
            add_refs(n, next, withRefs);
            if (is_shape(n.name)) {
                const std::string fill = inherited(withRefs.path, "fill");
                const std::string fillId = url_id(fill);
                const Node* pat = nullptr;
                if (!fillId.empty()) {
                    auto it = ids.find(fillId);
                    if (it != ids.end() && it->second->name == "pattern") pat = it->second;
                }
                Unit u;
                u.leaves.push_back({&n, "", withRefs.path});
                u.clips = withRefs.clips;
                u.masks = withRefs.masks;
                if (pat) {
                    used = true;
                    u.pattern = pat;
                    add_unit(u);
                    const std::string stroke = inherited(withRefs.path, "stroke");
                    if (!stroke.empty() && stroke != "none") {
                        const std::string sid = url_id(stroke);
                        if (!sid.empty() && ids.count(sid) && ids[sid]->name == "pattern") warn("A pattern as `stroke` is not supported; the stroke of that shape is not drawn.");
                        else {
                            Unit s = u;
                            s.pattern = nullptr;
                            s.leaves[0].extra = " fill=\"none\"";
                            add_unit(std::move(s));
                        }
                    }
                } else {
                    const std::string stroke = inherited(withRefs.path, "stroke");
                    const std::string sid = url_id(stroke);
                    if (!sid.empty() && ids.count(sid) && ids[sid]->name == "pattern") warn("A pattern as `stroke` is not supported; the stroke of that shape is not drawn.");
                    add_unit(std::move(u));
                }
            } else {
                walk(n, withRefs);
            }
        }
    }

    void index_ids(const Node& n) {
        if (const std::string* id = attr_of(n, "id"))
            if (!ids.count(*id)) ids[*id] = &n;
        for (const auto& k : n.kids) index_ids(*k);
    }

    void gradients_into(const Node& n, std::string& out) {
        if (n.name == "linearGradient" || n.name == "radialGradient") {
            emit_all(n, "", out);
            return;
        }
        for (const auto& k : n.kids) gradients_into(*k, out);
    }

    // ---- compositing ----

    static void multiply_alpha(std::vector<std::uint8_t>& layer, const std::vector<std::uint8_t>& mask) {
        for (std::size_t i = 0; i < layer.size(); i += 4) layer[i + 3] = std::uint8_t((int(layer[i + 3]) * int(mask[i + 3]) + 127) / 255);
    }

    // The coverage of a <clipPath> as the alpha channel of an RGBA buffer.
    std::vector<std::uint8_t> clip_mask(const Ref& r) {
        std::vector<const Node*> path = r.ownerPath;
        std::string body = transform_context_open(path);
        const std::string* ct = attr_of(*r.def, "transform");
        body += ct ? "<g transform=\"" + *ct + "\">" : "<g>";
        for (const auto& k : r.def->kids) {
            if (k->name.empty()) continue;
            if (!is_shape(k->name)) {
                warn("<" + k->name + "> inside a <clipPath> is not supported (use path, rect, circle, ellipse, polygon); it does not clip.");
                continue;
            }
            std::string extra = " fill=\"#000000\" fill-opacity=\"1\" opacity=\"1\" stroke=\"none\"";
            const std::string rule = prop_of(*k, "clip-rule");
            if (!rule.empty()) extra += " fill-rule=\"" + rule + "\"";
            else {
                const std::string prule = prop_of(*r.def, "clip-rule");
                if (!prule.empty()) extra += " fill-rule=\"" + prule + "\"";
            }
            emit_all(*k, extra, body);
        }
        body += "</g>" + closes(path.size());
        return render(body);
    }

    // The luminance (times alpha) of a <mask>'s content, in the alpha channel of an RGBA buffer.
    std::vector<std::uint8_t> luminance_mask(const Ref& r) {
        std::string body = transform_context_open(r.ownerPath);
        for (const auto& k : r.def->kids)
            if (!k->name.empty() && !is_inert(k->name)) emit_all(*k, "", body);
        body += closes(r.ownerPath.size());
        std::vector<std::uint8_t> px = render(body);
        for (std::size_t i = 0; i < px.size(); i += 4) {
            const double lum = (0.2126 * px[i] + 0.7152 * px[i + 1] + 0.0722 * px[i + 2]) / 255.0;
            px[i + 3] = std::uint8_t(std::clamp(std::lround(lum * px[i + 3]), 0L, 255L));
        }
        return px;
    }

    static double pattern_number(const std::string& v, double base, bool fraction) {
        if (v.empty()) return 0;
        const double d = std::strtod(v.c_str(), nullptr);
        if (v.find('%') != std::string::npos) return fraction ? d / 100.0 : d / 100.0 * base;
        return d;
    }

    // The pattern's tiles covering the pixels where `coverage` is not empty, as an RGBA layer.
    std::vector<std::uint8_t> pattern_layer(const Unit& u, const std::vector<std::uint8_t>& coverage) {
        const Leaf& leaf = u.leaves[0];
        const Node& pat = *u.pattern;
        std::vector<std::uint8_t> empty(std::size_t(w) * h * 4, 0);
        if (attr_of(pat, "viewBox")) warn("A <pattern> viewBox is ignored; write the pattern's content in the pattern tile's own units.");
        const bool boxUnits = prop_of(pat, "patternUnits") != "userSpaceOnUse";
        const bool contentBox = prop_of(pat, "patternContentUnits") == "objectBoundingBox";
        double bb[4] = {0, 0, 1, 1};
        if ((boxUnits || contentBox) && !user_bounds(*leaf.node, bb)) return empty;
        const double bw = bb[2] - bb[0], bh = bb[3] - bb[1];
        double x = pattern_number(prop_of(pat, "x"), bw, boxUnits), y = pattern_number(prop_of(pat, "y"), bh, boxUnits);
        double pw = pattern_number(prop_of(pat, "width"), bw, boxUnits), ph = pattern_number(prop_of(pat, "height"), bh, boxUnits);
        if (boxUnits) {
            x = bb[0] + x * bw;
            y = bb[1] + y * bh;
            pw *= bw;
            ph *= bh;
        }
        if (!(pw > 1e-6) || !(ph > 1e-6)) {
            warn("A <pattern> needs a width and a height greater than 0; shapes filled with it are not drawn.");
            return empty;
        }
        // the pixels to cover
        int minPx = w, minPy = h, maxPx = -1, maxPy = -1;
        for (int j = 0; j < h; ++j)
            for (int i = 0; i < w; ++i)
                if (coverage[(std::size_t(j) * w + i) * 4 + 3]) {
                    minPx = std::min(minPx, i);
                    maxPx = std::max(maxPx, i);
                    minPy = std::min(minPy, j);
                    maxPy = std::max(maxPy, j);
                }
        if (maxPx < 0) return empty;
        // pattern space -> leaf user space (patternTransform) -> root user space (the transforms of the leaf and its ancestors)
        Mat chain;
        for (const Node* n : leaf.path) chain = mul(chain, transform_of(*n));
        const Mat patT = parse_transform(prop_of(pat, "patternTransform"));
        Mat inv;
        if (!invert(mul(chain, patT), inv)) return empty;
        double pxMin = 1e300, pyMin = 1e300, pxMax = -1e300, pyMax = -1e300;
        const double cx[2] = {double(minPx), double(maxPx + 1)}, cy[2] = {double(minPy), double(maxPy + 1)};
        for (double ox : cx)
            for (double oy : cy) {
                const double ix = (ox - tx) / scale, iy = (oy - ty) / scale;      // nanosvg image px
                const double ux = (ix - mapTx) / mapSx, uy = (iy - mapTy) / mapSy;  // root user units
                double qx, qy;
                apply(inv, ux, uy, qx, qy);
                pxMin = std::min(pxMin, qx);
                pxMax = std::max(pxMax, qx);
                pyMin = std::min(pyMin, qy);
                pyMax = std::max(pyMax, qy);
            }
        const long i0 = long(std::floor((pxMin - x) / pw)), i1 = long(std::floor((pxMax - x) / pw));
        const long j0 = long(std::floor((pyMin - y) / ph)), j1 = long(std::floor((pyMax - y) / ph));
        const double tiles = double(i1 - i0 + 1) * double(j1 - j0 + 1);
        if (tiles > 60000.0) {
            warn(std::format("A <pattern> would need {} tiles on this shape (the tiles are too small for the picture); make its width and height larger. The shape is not drawn.", std::llround(tiles)));
            return empty;
        }
        std::vector<const Node*> ctxPath = leaf.path;
        std::string body = transform_context_open(ctxPath);
        const std::string* ptAttr = attr_of(pat, "patternTransform");
        body += ptAttr ? "<g transform=\"" + *ptAttr + "\">" : "<g>";
        for (long j = j0; j <= j1; ++j)
            for (long i = i0; i <= i1; ++i) {
                body += std::format("<g transform=\"translate({} {}){}\">", x + double(i) * pw, y + double(j) * ph,
                                    contentBox ? std::format(" scale({} {})", bw, bh) : std::string());
                for (const auto& k : pat.kids)
                    if (!k->name.empty() && !is_inert(k->name)) emit_all(*k, "", body);
                body += "</g>";
            }
        body += "</g>" + closes(ctxPath.size());
        return render(body);
    }

    static void composite(Image& out, const std::vector<std::uint8_t>& layer) {
        for (std::size_t i = 0; i < layer.size(); i += 4) {
            const int sa = layer[i + 3];
            if (sa == 0) continue;
            std::uint8_t* d = &out.rgba[i];
            const int da = d[3];
            const double s = sa / 255.0, dd = da / 255.0, oa = s + dd * (1.0 - s);
            for (int c = 0; c < 3; ++c) d[c] = std::uint8_t(std::clamp(std::lround((layer[i + c] * s + d[c] * dd * (1.0 - s)) / oa), 0L, 255L));
            d[3] = std::uint8_t(std::clamp(std::lround(oa * 255.0), 0L, 255L));
        }
    }

    void draw(Image& out) {
        for (const Unit& u : units) {
            std::vector<std::uint8_t> layer;
            if (u.pattern) {
                const std::vector<std::uint8_t> coverage = render(selection_markup_with(u, " fill=\"#ffffff\" stroke=\"none\""));
                layer = pattern_layer(u, coverage);
                multiply_alpha(layer, coverage);
            } else {
                layer = render(selection_markup(u.leaves));
            }
            for (const Ref& c : u.clips) multiply_alpha(layer, clip_mask(c));
            for (const Ref& m : u.masks) multiply_alpha(layer, luminance_mask(m));
            composite(out, layer);
        }
    }

    std::string selection_markup_with(const Unit& u, const std::string& extra) {
        std::vector<Leaf> leaves = u.leaves;
        for (Leaf& l : leaves) l.extra += extra;
        return selection_markup(leaves);
    }
};

}  // namespace

bool render_svg_layers(const std::string& text, const NSVGimage* image, Image& out, float tx, float ty, float scale, std::vector<std::string>& warnings) {
    // a cheap look at the text first: nothing to do for the common SVG
    if (text.find("clip-path") == std::string::npos && text.find("mask") == std::string::npos && text.find("<pattern") == std::string::npos) return false;
    std::unique_ptr<Node> doc = parse_xml(text);
    const Node* svg = nullptr;
    for (const auto& k : doc->kids)
        if (k->name == "svg") svg = k.get();
    if (!svg) return false;

    Renderer r;
    r.warnings = &warnings;
    r.svgRoot = svg;
    r.w = out.width;
    r.h = out.height;
    r.tx = tx;
    r.ty = ty;
    r.scale = scale;
    r.index_ids(*svg);
    Renderer::Walk start;
    r.walk(*svg, start);
    if (!r.used) return false;

    // the root element, with a size and a viewBox, then the gradients
    {
        std::string extra;
        if (!attr_of(*svg, "viewBox")) extra += std::format(" viewBox=\"0 0 {} {}\"", image->width, image->height);
        if (!attr_of(*svg, "width")) extra += std::format(" width=\"{}\"", image->width);
        if (!attr_of(*svg, "height")) extra += std::format(" height=\"{}\"", image->height);
        r.head = open_tag(*svg, extra) + "<defs>";
        r.gradients_into(*svg, r.head);
        r.head += "</defs>";
    }
    r.rast = nsvgCreateRasterizer();
    // calibrate the mapping from user units to nanosvg image pixels with a unit square
    {
        std::string doc2 = r.head + "<rect x=\"0\" y=\"0\" width=\"1\" height=\"1\"/></svg>";
        std::vector<char> buf(doc2.begin(), doc2.end());
        buf.push_back('\0');
        if (NSVGimage* probe = nsvgParse(buf.data(), "px", 96.0f)) {
            if (probe->shapes) {
                r.mapTx = probe->shapes->bounds[0];
                r.mapTy = probe->shapes->bounds[1];
                r.mapSx = std::max(1e-9f, probe->shapes->bounds[2] - probe->shapes->bounds[0]);
                r.mapSy = std::max(1e-9f, probe->shapes->bounds[3] - probe->shapes->bounds[1]);
            }
            nsvgDelete(probe);
        }
    }
    r.draw(out);
    nsvgDeleteRasterizer(r.rast);
    return true;
}

}  // namespace fa::assets_detail
