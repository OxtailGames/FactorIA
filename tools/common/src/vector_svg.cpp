// The SVG element tree of the vector.* commands (vector.h): a reader that keeps what it read, ids and selectors, presentation
// properties, transforms and the geometry of the shape elements.
#include "vector_svg.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/core/strings.h"

namespace fa::vec {

using assets_detail::fail;

namespace {

bool is_space(char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r'; }
bool all_space(const std::string& s) {
    return std::all_of(s.begin(), s.end(), [](char c) { return is_space(c); });
}
std::string trimmed(const std::string& s) {
    std::size_t a = 0, b = s.size();
    while (a < b && is_space(s[a])) ++a;
    while (b > a && is_space(s[b - 1])) --b;
    return s.substr(a, b - a);
}

std::string decode_entities(const std::string& s) {
    if (s.find('&') == std::string::npos) return s;
    std::string out;
    for (std::size_t i = 0; i < s.size(); ++i) {
        if (s[i] != '&') {
            out += s[i];
            continue;
        }
        const std::size_t semi = s.find(';', i);
        if (semi == std::string::npos || semi - i > 10) {
            out += s[i];
            continue;
        }
        const std::string name = s.substr(i + 1, semi - i - 1);
        std::string rep;
        if (name == "amp") rep = "&";
        else if (name == "lt") rep = "<";
        else if (name == "gt") rep = ">";
        else if (name == "quot") rep = "\"";
        else if (name == "apos") rep = "'";
        else if (name.size() > 1 && name[0] == '#') {
            const bool hex = name[1] == 'x' || name[1] == 'X';
            const long cp = std::strtol(name.c_str() + (hex ? 2 : 1), nullptr, hex ? 16 : 10);
            if (cp > 0 && cp < 0x80) rep = std::string(1, char(cp));
            else if (cp >= 0x80 && cp < 0x800) {
                rep += char(0xC0 | (cp >> 6));
                rep += char(0x80 | (cp & 0x3F));
            } else if (cp >= 0x800 && cp < 0x10000) {
                rep += char(0xE0 | (cp >> 12));
                rep += char(0x80 | ((cp >> 6) & 0x3F));
                rep += char(0x80 | (cp & 0x3F));
            } else if (cp >= 0x10000 && cp < 0x110000) {
                rep += char(0xF0 | (cp >> 18));
                rep += char(0x80 | ((cp >> 12) & 0x3F));
                rep += char(0x80 | ((cp >> 6) & 0x3F));
                rep += char(0x80 | (cp & 0x3F));
            }
        }
        if (rep.empty()) {
            out += s[i];  // an unknown entity stays as written
            continue;
        }
        out += rep;
        i = semi;
    }
    return out;
}

std::string escape_attr(const std::string& v, char quote) {
    std::string out;
    for (char c : v) {
        if (c == '&') out += "&amp;";
        else if (c == '<') out += "&lt;";
        else if (c == quote) out += quote == '"' ? "&quot;" : "&apos;";
        else out += c;
    }
    return out;
}

// ---- the reader ------------------------------------------------------------------------------------------------------

class Reader {
public:
    Reader(const std::string& text, const std::string& what) : s_(text), what_(what) {
        lineStart_.push_back(0);
        for (std::size_t i = 0; i < s_.size(); ++i)
            if (s_[i] == '\n') lineStart_.push_back(i + 1);
    }

    [[noreturn]] void error(std::size_t at, const std::string& msg, const std::string& hint) const {
        const auto it = std::upper_bound(lineStart_.begin(), lineStart_.end(), at);
        const std::size_t line = std::size_t(it - lineStart_.begin());
        const std::size_t col = at - lineStart_[line - 1] + 1;
        fail("invalid_svg", std::format("{}, line {}, column {}: {}", what_, line, col, msg), hint);
    }
    int line_of(std::size_t at) const {
        return int(std::upper_bound(lineStart_.begin(), lineStart_.end(), at) - lineStart_.begin());
    }

    // The prolog: everything up to the root element's `<`.
    std::size_t skip_prolog() {
        std::size_t i = 0;
        while (i < s_.size()) {
            if (s_.compare(i, 4, "<!--") == 0) {
                const std::size_t e = s_.find("-->", i + 4);
                if (e == std::string::npos) error(i, "this comment is never closed.", "Close it with -->.");
                i = e + 3;
            } else if (s_.compare(i, 2, "<?") == 0) {
                const std::size_t e = s_.find("?>", i + 2);
                if (e == std::string::npos) error(i, "this processing instruction is never closed.", "Close it with ?>.");
                i = e + 2;
            } else if (s_.compare(i, 9, "<!DOCTYPE") == 0) {
                int depth = 0;
                std::size_t j = i + 9;
                for (; j < s_.size(); ++j) {
                    if (s_[j] == '[') ++depth;
                    else if (s_[j] == ']') --depth;
                    else if (s_[j] == '>' && depth <= 0) break;
                }
                if (j >= s_.size()) error(i, "this DOCTYPE is never closed.", "Close it with >.");
                i = j + 1;
            } else if (is_space(s_[i])) {
                ++i;
            } else {
                break;
            }
        }
        return i;
    }

    std::unique_ptr<XNode> element(std::size_t& i, XNode* parent, int depth) {
        if (depth > 200) error(i, "elements are nested more than 200 deep.", "Flatten the document.");
        const std::size_t open = i;
        ++i;  // <
        auto n = std::make_unique<XNode>();
        n->parent = parent;
        n->line = line_of(open);
        const std::size_t nameStart = i;
        while (i < s_.size() && !is_space(s_[i]) && s_[i] != '>' && s_[i] != '/') ++i;
        n->name = s_.substr(nameStart, i - nameStart);
        if (n->name.empty()) error(open, "a '<' with no element name.", "Write '&lt;' for a literal less-than sign.");
        for (;;) {
            while (i < s_.size() && is_space(s_[i])) ++i;
            if (i >= s_.size()) error(open, "<" + n->name + "> is never closed.", "End the tag with > or />.");
            if (s_[i] == '>') {
                ++i;
                break;
            }
            if (s_[i] == '/') {
                if (i + 1 >= s_.size() || s_[i + 1] != '>') error(i, "a '/' inside the tag of <" + n->name + ">.", "A self-closing tag ends with />.");
                i += 2;
                n->selfClosed = true;
                n->rawOpen = s_.substr(open, i - open);
                return n;
            }
            Attr a;
            const std::size_t as = i;
            while (i < s_.size() && !is_space(s_[i]) && s_[i] != '=' && s_[i] != '>' && s_[i] != '/') ++i;
            a.name = s_.substr(as, i - as);
            if (a.name.empty()) error(i, "unexpected character '" + std::string(1, s_[i]) + "' in <" + n->name + ">.", "Attributes are written name=\"value\".");
            while (i < s_.size() && is_space(s_[i])) ++i;
            if (i >= s_.size() || s_[i] != '=') error(i, "the attribute '" + a.name + "' has no value.", "Write " + a.name + "=\"...\".");
            ++i;
            while (i < s_.size() && is_space(s_[i])) ++i;
            if (i >= s_.size() || (s_[i] != '"' && s_[i] != '\'')) error(i, "the value of '" + a.name + "' is not quoted.", "Put the value in double quotes: " + a.name + "=\"...\".");
            a.quote = s_[i];
            const std::size_t vs = i + 1;
            const std::size_t ve = s_.find(a.quote, vs);
            if (ve == std::string::npos) error(i, "the value of '" + a.name + "' is never closed.", "Close it with the same quote character.");
            a.raw = s_.substr(vs, ve - vs);
            a.value = decode_entities(a.raw);
            i = ve + 1;
            if (std::any_of(n->attrs.begin(), n->attrs.end(), [&](const Attr& o) { return o.name == a.name; }))
                error(as, "the attribute '" + a.name + "' appears twice on <" + n->name + ">.", "Remove one of them.");
            n->attrs.push_back(std::move(a));
        }
        n->rawOpen = s_.substr(open, i - open);
        // content
        std::string text;
        auto flush = [&] {
            if (!text.empty()) {
                XItem it;
                it.text = std::move(text);
                n->kids.push_back(std::move(it));
                text.clear();
            }
        };
        for (;;) {
            if (i >= s_.size()) error(open, "<" + n->name + "> is never closed.", "Add </" + n->name + "> where it ends.");
            if (s_[i] != '<') {
                const std::size_t e = s_.find('<', i);
                text += s_.substr(i, e == std::string::npos ? std::string::npos : e - i);
                i = e == std::string::npos ? s_.size() : e;
                continue;
            }
            if (s_.compare(i, 4, "<!--") == 0) {
                const std::size_t e = s_.find("-->", i + 4);
                if (e == std::string::npos) error(i, "this comment is never closed.", "Close it with -->.");
                text += s_.substr(i, e + 3 - i);
                i = e + 3;
            } else if (s_.compare(i, 9, "<![CDATA[") == 0) {
                const std::size_t e = s_.find("]]>", i + 9);
                if (e == std::string::npos) error(i, "this CDATA section is never closed.", "Close it with ]]>.");
                text += s_.substr(i, e + 3 - i);
                i = e + 3;
            } else if (s_.compare(i, 2, "<?") == 0) {
                const std::size_t e = s_.find("?>", i + 2);
                if (e == std::string::npos) error(i, "this processing instruction is never closed.", "Close it with ?>.");
                text += s_.substr(i, e + 2 - i);
                i = e + 2;
            } else if (s_.compare(i, 2, "</") == 0) {
                const std::size_t e = s_.find('>', i);
                if (e == std::string::npos) error(i, "this closing tag never ends.", "End it with >.");
                const std::string closing = trimmed(s_.substr(i + 2, e - i - 2));
                if (closing != n->name)
                    error(i, "</" + closing + "> closes <" + n->name + "> (opened on line " + std::to_string(n->line) + ").",
                          "Close the elements in the order they were opened: </" + n->name + "> comes first.");
                flush();
                i = e + 1;
                return n;
            } else {
                flush();
                XItem it;
                it.el = element(i, n.get(), depth + 1);
                n->kids.push_back(std::move(it));
            }
        }
    }

    const std::string& text() const { return s_; }

private:
    const std::string& s_;
    std::string what_;
    std::vector<std::size_t> lineStart_;
};

void write_node(const XNode& n, std::string& out) {
    const bool useRaw = !n.rawOpen.empty() && (!n.selfClosed || n.kids.empty());
    if (useRaw) {
        out += n.rawOpen;
    } else {
        out += '<';
        out += n.name;
        for (const Attr& a : n.attrs) {
            out += ' ';
            out += a.name;
            out += '=';
            out += a.quote;
            out += a.raw.empty() ? escape_attr(a.value, a.quote) : a.raw;
            out += a.quote;
        }
        if (n.kids.empty() && n.selfClosed) out += "/>";
        else out += '>';
    }
    if (n.kids.empty() && n.selfClosed) return;
    for (const XItem& k : n.kids) {
        if (k.el) write_node(*k.el, out);
        else out += k.text;
    }
    out += "</";
    out += n.name;
    out += '>';
}

void collect(XNode* n, std::vector<XNode*>& out) {
    out.push_back(n);
    for (XItem& k : n->kids)
        if (k.el) collect(k.el.get(), out);
}

std::string ws_before(const XNode& n) {
    if (!n.parent) return {};
    const auto& kids = n.parent->kids;
    for (std::size_t i = 0; i < kids.size(); ++i)
        if (kids[i].el.get() == &n) {
            if (i > 0 && !kids[i - 1].el && all_space(kids[i - 1].text) && !kids[i - 1].text.empty()) return kids[i - 1].text;
            return {};
        }
    return {};
}

std::size_t index_in_parent(const XNode& n) {
    const auto& kids = n.parent->kids;
    for (std::size_t i = 0; i < kids.size(); ++i)
        if (kids[i].el.get() == &n) return i;
    return kids.size();
}

}  // namespace

// ---- XNode -------------------------------------------------------------------------------------------------------------

std::string XNode::local() const {
    const std::size_t c = name.find(':');
    return c == std::string::npos ? name : name.substr(c + 1);
}
const std::string* XNode::attr(const std::string& n) const {
    for (const Attr& a : attrs)
        if (a.name == n) return &a.value;
    return nullptr;
}
std::string XNode::attr_or(const std::string& n, const std::string& fallback) const {
    const std::string* v = attr(n);
    return v ? *v : fallback;
}
void XNode::set_attr(const std::string& n, const std::string& v) {
    rawOpen.clear();
    for (Attr& a : attrs)
        if (a.name == n) {
            a.value = v;
            a.raw.clear();
            return;
        }
    Attr a;
    a.name = n;
    a.value = v;
    a.quote = attrs.empty() ? '"' : attrs.back().quote;
    attrs.push_back(std::move(a));
}
void XNode::remove_attr(const std::string& n) {
    const auto it = std::remove_if(attrs.begin(), attrs.end(), [&](const Attr& a) { return a.name == n; });
    if (it == attrs.end()) return;
    attrs.erase(it, attrs.end());
    rawOpen.clear();
}
std::vector<XNode*> XNode::elements() const {
    std::vector<XNode*> out;
    for (const XItem& k : kids)
        if (k.el) out.push_back(k.el.get());
    return out;
}

std::unique_ptr<XNode> make_element(const std::string& name) {
    auto n = std::make_unique<XNode>();
    n->name = name;
    n->selfClosed = true;
    return n;
}

// ---- SvgDoc ----------------------------------------------------------------------------------------------------------

SvgDoc SvgDoc::parse(const std::string& text, const std::string& what) {
    Reader r(text, what);
    SvgDoc d;
    std::size_t i = r.skip_prolog();
    if (i >= text.size()) r.error(0, "there is no <svg> element.", "Start with <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\"> and put the shapes inside.");
    if (text[i] != '<') r.error(i, "text before the root element.", "An SVG file is one <svg> element.");
    d.before_ = text.substr(0, i);
    d.root_ = r.element(i, nullptr, 0);
    if (d.root_->local() != "svg")
        r.error(text.find('<', d.before_.size()), "the root element is <" + d.root_->name + ">, not <svg>.", "Wrap the shapes in <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\">...</svg>.");
    d.after_ = text.substr(i);
    return d;
}

std::string SvgDoc::write() const {
    std::string out = before_;
    write_node(*root_, out);
    out += after_;
    return out;
}

std::vector<XNode*> SvgDoc::all_elements() const {
    std::vector<XNode*> out;
    collect(root_.get(), out);
    return out;
}

XNode* SvgDoc::by_id(const std::string& id) const {
    for (XNode* n : all_elements()) {
        const std::string* v = n->attr("id");
        if (v && *v == id) return n;
    }
    return nullptr;
}

std::vector<std::string> SvgDoc::ids() const {
    std::vector<std::string> out;
    for (XNode* n : all_elements())
        if (const std::string* v = n->attr("id"); v && !v->empty()) out.push_back(*v);
    return out;
}

std::string SvgDoc::unique_id(const std::string& base) const {
    std::set<std::string> used;
    for (const std::string& s : ids()) used.insert(s);
    if (!used.count(base)) return base;
    for (int i = 2;; ++i) {
        std::string c = base + "-" + std::to_string(i);
        if (!used.count(c)) return c;
    }
}

namespace {
bool parse_numbers(const std::string& s, std::vector<double>& out) {
    out.clear();
    const char* p = s.c_str();
    while (*p) {
        while (*p && (is_space(*p) || *p == ',')) ++p;
        if (!*p) break;
        char* end = nullptr;
        const double v = std::strtod(p, &end);
        if (end == p) return false;
        out.push_back(v);
        p = end;
    }
    return true;
}
}  // namespace

Rect SvgDoc::canvas() const {
    std::vector<double> v;
    if (const std::string* vb = root_->attr("viewBox"); vb && parse_numbers(*vb, v) && v.size() == 4 && v[2] > 0 && v[3] > 0) {
        Rect r;
        r.add(P{v[0], v[1]});
        r.add(P{v[0] + v[2], v[1] + v[3]});
        return r;
    }
    double w = 0, h = 0;
    if (parse_length(root_->attr_or("width"), w) && parse_length(root_->attr_or("height"), h) && w > 0 && h > 0) {
        Rect r;
        r.add(P{0, 0});
        r.add(P{w, h});
        return r;
    }
    Rect b;
    for (XNode* n : all_elements()) {
        if (!is_shape_element(*n) || in_inert_subtree(*n)) continue;
        Path p;
        std::string why;
        if (shape_path(*n, p, why)) b.add(path_bounds(transform_path(p, element_ctm(*n))));
    }
    if (b.empty()) {
        b.add(P{0, 0});
        b.add(P{100, 100});
    }
    return b;
}

P SvgDoc::declared_size() const {
    const Rect c = canvas();
    double w = 0, h = 0;
    const bool hw = parse_length(root_->attr_or("width"), w) && w > 0;
    const bool hh = parse_length(root_->attr_or("height"), h) && h > 0;
    if (hw && hh) return {w, h};
    if (hw) return {w, w * c.height() / std::max(c.width(), 1e-9)};
    if (hh) return {h * c.width() / std::max(c.height(), 1e-9), h};
    return {c.width(), c.height()};
}

XNode* SvgDoc::insert_after(XNode* ref, std::unique_ptr<XNode> node) {
    XNode* parent = ref->parent;
    node->parent = parent;
    const std::size_t at = index_in_parent(*ref);
    const std::string indent = ws_before(*ref);
    XNode* raw = node.get();
    std::vector<XItem> add;
    if (!indent.empty()) {
        XItem t;
        t.text = indent;
        add.push_back(std::move(t));
    }
    XItem it;
    it.el = std::move(node);
    add.push_back(std::move(it));
    parent->kids.insert(parent->kids.begin() + std::ptrdiff_t(at + 1), std::make_move_iterator(add.begin()), std::make_move_iterator(add.end()));
    parent->rawOpen = parent->selfClosed ? std::string() : parent->rawOpen;
    return raw;
}

XNode* SvgDoc::insert_before(XNode* ref, std::unique_ptr<XNode> node) {
    XNode* parent = ref->parent;
    node->parent = parent;
    const std::size_t at = index_in_parent(*ref);
    const std::string indent = ws_before(*ref);
    XNode* raw = node.get();
    std::vector<XItem> add;
    XItem it;
    it.el = std::move(node);
    add.push_back(std::move(it));
    if (!indent.empty()) {
        XItem t;
        t.text = indent;
        add.push_back(std::move(t));
    }
    parent->kids.insert(parent->kids.begin() + std::ptrdiff_t(at), std::make_move_iterator(add.begin()), std::make_move_iterator(add.end()));
    return raw;
}

XNode* SvgDoc::append_child(XNode* parent, std::unique_ptr<XNode> node) {
    node->parent = parent;
    XNode* raw = node.get();
    const std::vector<XNode*> els = parent->elements();
    if (!els.empty()) {
        // after the last element child, with the indentation of its siblings
        return insert_after(els.back(), std::move(node));
    }
    parent->rawOpen.clear();
    parent->selfClosed = false;
    const std::string own = ws_before(*parent);
    XItem it;
    it.el = std::move(node);
    if (!own.empty()) {
        XItem a, b;
        a.text = own + "  ";
        b.text = own;
        parent->kids.push_back(std::move(a));
        parent->kids.push_back(std::move(it));
        parent->kids.push_back(std::move(b));
    } else {
        parent->kids.push_back(std::move(it));
    }
    return raw;
}

void SvgDoc::remove(XNode* node) {
    XNode* parent = node->parent;
    if (!parent) return;
    std::size_t at = index_in_parent(*node);
    if (at >= parent->kids.size()) return;
    parent->kids.erase(parent->kids.begin() + std::ptrdiff_t(at));
    if (at > 0 && !parent->kids[at - 1].el && all_space(parent->kids[at - 1].text) && !parent->kids[at - 1].text.empty())
        parent->kids.erase(parent->kids.begin() + std::ptrdiff_t(at - 1));
}

std::unique_ptr<XNode> SvgDoc::clone(const XNode& n) {
    auto c = std::make_unique<XNode>();
    c->name = n.name;
    c->attrs = n.attrs;
    c->selfClosed = n.selfClosed;
    c->rawOpen = n.rawOpen;
    c->line = n.line;
    for (const XItem& k : n.kids) {
        XItem it;
        if (k.el) {
            it.el = clone(*k.el);
            it.el->parent = c.get();
        } else {
            it.text = k.text;
        }
        c->kids.push_back(std::move(it));
    }
    return c;
}

// ---- elements ----------------------------------------------------------------------------------------------------------

bool is_shape_element(const XNode& n) {
    const std::string l = n.local();
    return l == "path" || l == "rect" || l == "circle" || l == "ellipse" || l == "line" || l == "polyline" || l == "polygon";
}
bool is_group_element(const XNode& n) {
    const std::string l = n.local();
    return l == "g" || l == "svg" || l == "a" || l == "switch";
}

namespace {
bool inert_name(const std::string& l) {
    return l == "defs" || l == "clipPath" || l == "mask" || l == "pattern" || l == "symbol" || l == "marker" || l == "linearGradient" ||
           l == "radialGradient" || l == "filter" || l == "style" || l == "title" || l == "desc" || l == "metadata" || l == "text";
}
}  // namespace

bool in_inert_subtree(const XNode& n) {
    for (const XNode* p = &n; p; p = p->parent)
        if (inert_name(p->local())) return true;
    return false;
}

namespace {
struct Decl {
    std::string name, value;
};
std::vector<Decl> parse_style_attr(const std::string& s) {
    std::vector<Decl> out;
    std::size_t i = 0;
    while (i < s.size()) {
        std::size_t e = s.find(';', i);
        if (e == std::string::npos) e = s.size();
        const std::string d = s.substr(i, e - i);
        const std::size_t c = d.find(':');
        if (c != std::string::npos) out.push_back({trimmed(d.substr(0, c)), trimmed(d.substr(c + 1))});
        i = e + 1;
    }
    return out;
}
}  // namespace

std::string own_prop(const XNode& n, const std::string& name) {
    if (const std::string* st = n.attr("style"))
        for (const Decl& d : parse_style_attr(*st))
            if (d.name == name) return d.value;
    return trimmed(n.attr_or(name));
}

std::string inherited_prop(const XNode& n, const std::string& name) {
    for (const XNode* p = &n; p; p = p->parent) {
        std::string v = own_prop(*p, name);
        if (!v.empty() && v != "inherit") return v;
    }
    return {};
}

void set_prop(XNode& n, const std::string& name, const std::string& value) {
    if (const std::string* st = n.attr("style")) {
        // rewrite the declaration in place
        std::string out;
        std::size_t i = 0;
        bool found = false;
        while (i < st->size()) {
            std::size_t e = st->find(';', i);
            const bool last = e == std::string::npos;
            if (last) e = st->size();
            std::string d = st->substr(i, e - i);
            const std::size_t c = d.find(':');
            if (c != std::string::npos && trimmed(d.substr(0, c)) == name) {
                found = true;
                // keep the leading spacing and the "name:" text
                std::size_t v = c + 1;
                while (v < d.size() && is_space(d[v])) ++v;
                d = d.substr(0, v) + value;
            }
            out += d;
            if (!last) out += ';';
            i = e + 1;
        }
        if (found) {
            n.set_attr("style", out);
            return;
        }
    }
    n.set_attr(name, value);
}

void remove_prop(XNode& n, const std::string& name) {
    n.remove_attr(name);
    if (const std::string* st = n.attr("style")) {
        std::string out;
        for (const Decl& d : parse_style_attr(*st)) {
            if (d.name == name) continue;
            if (!out.empty()) out += ';';
            out += d.name + ":" + d.value;
        }
        if (out.empty()) n.remove_attr("style");
        else n.set_attr("style", out);
    }
}

Mat own_transform(const XNode& n) {
    const std::string* t = n.attr("transform");
    if (!t || trimmed(*t).empty()) return {};
    Mat m;
    std::string err;
    if (!parse_transform(*t, m, err))
        fail("invalid_svg", std::format("{}: the transform \"{}\" cannot be read: {}", describe_element(n), *t, err),
             "Write transforms as translate(x y), rotate(deg), scale(s), skewX(deg), skewY(deg) or matrix(a b c d e f).");
    return m;
}

Mat parent_ctm(const XNode& n) {
    Mat m;
    std::vector<const XNode*> chain;
    for (const XNode* p = n.parent; p; p = p->parent) chain.push_back(p);
    // the root <svg> is the drawing space itself
    for (std::size_t i = chain.size(); i-- > 0;) {
        if (!chain[i]->parent) continue;
        m = m * own_transform(*chain[i]);
    }
    return m;
}

Mat element_ctm(const XNode& n) { return n.parent ? parent_ctm(n) * own_transform(n) : Mat{}; }

bool parse_length(const std::string& text, double& out) {
    const std::string s = trimmed(text);
    if (s.empty()) return false;
    char* end = nullptr;
    const double v = std::strtod(s.c_str(), &end);
    if (end == s.c_str() || !std::isfinite(v)) return false;
    const std::string unit = trimmed(std::string(end));
    double k = 1;
    if (unit.empty() || unit == "px") k = 1;
    else if (unit == "pt") k = 4.0 / 3.0;
    else if (unit == "pc") k = 16;
    else if (unit == "mm") k = 96.0 / 25.4;
    else if (unit == "cm") k = 96.0 / 2.54;
    else if (unit == "in") k = 96;
    else return false;
    out = v * k;
    return true;
}

bool shape_path(const XNode& n, Path& out, std::string& why) {
    out.clear();
    const std::string l = n.local();
    auto num = [&](const char* key, double fallback, bool& ok) {
        const std::string* v = n.attr(key);
        if (!v || trimmed(*v).empty()) return fallback;
        double r = 0;
        if (!parse_length(*v, r)) {
            ok = false;
            why = std::format("{}=\"{}\" is not a length in user units", key, *v);
            return fallback;
        }
        return r;
    };
    bool ok = true;
    if (l == "path") {
        std::string err;
        if (!parse_path_data(n.attr_or("d"), out, err)) {
            why = "the path data cannot be read: " + err;
            return false;
        }
        return true;
    }
    if (l == "rect") {
        const double x = num("x", 0, ok), y = num("y", 0, ok), w = num("width", 0, ok), h = num("height", 0, ok);
        double rx = num("rx", -1, ok), ry = num("ry", -1, ok);
        if (!ok) return false;
        if (rx < 0 && ry < 0) rx = ry = 0;
        else if (rx < 0) rx = ry;
        else if (ry < 0) ry = rx;
        if (w <= 0 || h <= 0) return true;  // draws nothing
        rx = std::min(rx, w / 2);
        ry = std::min(ry, h / 2);
        out = rect_path(x, y, w, h, rx, ry);
        return true;
    }
    if (l == "circle") {
        const double cx = num("cx", 0, ok), cy = num("cy", 0, ok), r = num("r", 0, ok);
        if (!ok) return false;
        if (r > 0) out = ellipse_path(cx, cy, r, r);
        return true;
    }
    if (l == "ellipse") {
        const double cx = num("cx", 0, ok), cy = num("cy", 0, ok);
        double rx = num("rx", -1, ok), ry = num("ry", -1, ok);
        if (!ok) return false;
        if (rx < 0) rx = ry;
        if (ry < 0) ry = rx;
        if (rx > 0 && ry > 0) out = ellipse_path(cx, cy, rx, ry);
        return true;
    }
    if (l == "line") {
        const double x1 = num("x1", 0, ok), y1 = num("y1", 0, ok), x2 = num("x2", 0, ok), y2 = num("y2", 0, ok);
        if (!ok) return false;
        SubPath s;
        s.start = {x1, y1};
        s.segs.push_back({false, {}, {}, {x2, y2}});
        out.push_back(s);
        return true;
    }
    if (l == "polyline" || l == "polygon") {
        std::vector<double> v;
        if (!parse_numbers(n.attr_or("points"), v)) {
            why = "points=\"" + n.attr_or("points") + "\" is not a list of numbers";
            return false;
        }
        if (v.size() % 2 != 0) v.pop_back();  // SVG ignores the odd coordinate
        if (v.size() < 4) return true;
        SubPath s;
        s.start = {v[0], v[1]};
        for (std::size_t i = 2; i + 1 < v.size(); i += 2) s.segs.push_back({false, {}, {}, {v[i], v[i + 1]}});
        s.closed = l == "polygon";
        out.push_back(std::move(s));
        return true;
    }
    why = "<" + n.name + "> is not a shape";
    return false;
}

void set_path_geometry(XNode& n, const std::string& d) {
    static const char* const kGeometry[] = {"x", "y", "width", "height", "rx", "ry", "cx", "cy", "r", "x1", "y1", "x2", "y2", "points"};
    if (n.local() != "path") {
        const std::size_t colon = n.name.find(':');
        n.name = (colon == std::string::npos ? std::string() : n.name.substr(0, colon + 1)) + "path";
        n.rawOpen.clear();
        std::size_t firstAt = n.attrs.size();
        for (std::size_t i = 0; i < n.attrs.size(); ++i)
            if (std::find(std::begin(kGeometry), std::end(kGeometry), n.attrs[i].name) != std::end(kGeometry)) {
                firstAt = i;
                break;
            }
        n.attrs.erase(std::remove_if(n.attrs.begin(), n.attrs.end(),
                                     [&](const Attr& a) { return std::find(std::begin(kGeometry), std::end(kGeometry), a.name) != std::end(kGeometry); }),
                      n.attrs.end());
        if (!n.attr("d")) {
            Attr a;
            a.name = "d";
            a.quote = n.attrs.empty() ? '"' : n.attrs.front().quote;
            n.attrs.insert(n.attrs.begin() + std::ptrdiff_t(std::min(firstAt, n.attrs.size())), std::move(a));
        }
    }
    n.set_attr("d", d);
}

void shapes_under(XNode& n, std::vector<XNode*>& out) {
    if (is_shape_element(n)) {
        out.push_back(&n);
        return;
    }
    if (!is_group_element(n)) return;
    for (XNode* k : n.elements()) {
        if (inert_name(k->local())) continue;
        shapes_under(*k, out);
    }
}

std::string describe_element(const XNode& n) {
    std::string out = n.local();
    if (const std::string* id = n.attr("id"); id && !id->empty()) return out + "#" + *id;
    if (n.parent) {
        const std::vector<XNode*> sib = n.parent->elements();
        for (std::size_t i = 0; i < sib.size(); ++i)
            if (sib[i] == &n) return std::format("{} (child {} of {})", out, i + 1, n.parent->parent ? describe_element(*n.parent) : std::string("the root"));
    }
    return out;
}

// ---- selectors ---------------------------------------------------------------------------------------------------------

namespace {

struct AttrTest {
    std::string name, op, value;
};
struct Compound {
    std::string tag;  // empty = any
    std::string id;
    std::vector<std::string> classes;
    std::vector<AttrTest> attrs;
    struct Pseudo {
        std::string name;
        int a = 0, b = 0;  // nth-child: a*n + b
    };
    std::vector<Pseudo> pseudos;
};
struct Step {
    Compound c;
    char comb = ' ';  // how it relates to the previous step: ' ' descendant, '>' child
};
using Complex = std::vector<Step>;

class SelectorParser {
public:
    SelectorParser(const std::string& s, const char* command, const std::string& pointer) : s_(s), command_(command), pointer_(pointer) {}

    std::vector<Complex> parse() {
        std::vector<Complex> out;
        for (;;) {
            out.push_back(complex());
            skip_ws();
            if (i_ >= s_.size()) break;
            if (s_[i_] == ',') {
                ++i_;
                continue;
            }
            bad("unexpected '" + std::string(1, s_[i_]) + "'");
        }
        return out;
    }

private:
    [[noreturn]] void bad(const std::string& what) const {
        assets_detail::arg_error(command_, pointer_, std::format("the selector \"{}\" is not valid: {} (at character {}).", s_, what, i_ + 1),
                                 "Use an id (\"badge\"), #id, .class, a tag (path), [attr=value], g > path, path:first-child, :nth-child(2) or a list separated by commas.");
    }
    void skip_ws() {
        while (i_ < s_.size() && is_space(s_[i_])) ++i_;
    }
    static bool ident_char(char c) { return std::isalnum((unsigned char)c) || c == '-' || c == '_'; }
    std::string ident() {
        const std::size_t a = i_;
        while (i_ < s_.size() && ident_char(s_[i_])) ++i_;
        if (a == i_) bad("a name is missing");
        return s_.substr(a, i_ - a);
    }
    Complex complex() {
        Complex c;
        char comb = ' ';
        for (;;) {
            skip_ws();
            Step st;
            st.comb = comb;
            st.c = compound();
            c.push_back(std::move(st));
            const std::size_t save = i_;
            skip_ws();
            if (i_ >= s_.size() || s_[i_] == ',') break;
            if (s_[i_] == '>') {
                ++i_;
                comb = '>';
                skip_ws();
                if (i_ >= s_.size() || s_[i_] == ',') bad("a selector is missing after '>'");
                continue;
            }
            comb = ' ';
            if (save == i_) bad("two selectors need a space or '>' between them");
        }
        return c;
    }
    Compound compound() {
        Compound c;
        bool any = false;
        for (;;) {
            if (i_ >= s_.size()) break;
            const char ch = s_[i_];
            if (ch == '*') {
                ++i_;
                any = true;
            } else if (std::isalpha((unsigned char)ch) && !any && c.tag.empty() && c.id.empty() && c.classes.empty() && c.attrs.empty() && c.pseudos.empty()) {
                c.tag = ident();
                any = true;
            } else if (ch == '#') {
                ++i_;
                c.id = ident();
                any = true;
            } else if (ch == '.') {
                ++i_;
                c.classes.push_back(ident());
                any = true;
            } else if (ch == '[') {
                ++i_;
                AttrTest t;
                skip_ws();
                const std::size_t a = i_;
                while (i_ < s_.size() && (ident_char(s_[i_]) || s_[i_] == ':')) ++i_;
                t.name = s_.substr(a, i_ - a);
                if (t.name.empty()) bad("an attribute name is missing inside [ ]");
                skip_ws();
                if (i_ < s_.size() && s_[i_] != ']') {
                    const std::size_t o = i_;
                    while (i_ < s_.size() && (s_[i_] == '=' || s_[i_] == '~' || s_[i_] == '^' || s_[i_] == '$' || s_[i_] == '*' || s_[i_] == '|')) ++i_;
                    t.op = s_.substr(o, i_ - o);
                    if (t.op != "=" && t.op != "~=" && t.op != "^=" && t.op != "$=" && t.op != "*=" && t.op != "|=")
                        bad("the operator '" + t.op + "' is not one of =, ~=, ^=, $=, *=, |=");
                    skip_ws();
                    if (i_ < s_.size() && (s_[i_] == '"' || s_[i_] == '\'')) {
                        const char q = s_[i_++];
                        const std::size_t e = s_.find(q, i_);
                        if (e == std::string::npos) bad("a quote is never closed");
                        t.value = s_.substr(i_, e - i_);
                        i_ = e + 1;
                    } else {
                        const std::size_t v = i_;
                        while (i_ < s_.size() && s_[i_] != ']' && !is_space(s_[i_])) ++i_;
                        t.value = s_.substr(v, i_ - v);
                    }
                    skip_ws();
                }
                if (i_ >= s_.size() || s_[i_] != ']') bad("the [ ] is never closed");
                ++i_;
                c.attrs.push_back(std::move(t));
                any = true;
            } else if (ch == ':') {
                ++i_;
                Compound::Pseudo p;
                p.name = ident();
                static const std::vector<std::string> known = {"first-child", "last-child", "only-child", "nth-child"};
                if (std::find(known.begin(), known.end(), p.name) == known.end())
                    bad("the pseudo-class ':" + p.name + "' is not supported. " + did_you_mean(p.name, known));
                if (p.name == "nth-child") {
                    if (i_ >= s_.size() || s_[i_] != '(') bad(":nth-child needs an argument, e.g. :nth-child(2)");
                    ++i_;
                    const std::size_t e = s_.find(')', i_);
                    if (e == std::string::npos) bad("the ( ) is never closed");
                    const std::string arg = trimmed(s_.substr(i_, e - i_));
                    i_ = e + 1;
                    if (arg == "odd") p.a = 2, p.b = 1;
                    else if (arg == "even") p.a = 2, p.b = 0;
                    else {
                        char* end = nullptr;
                        const long k = std::strtol(arg.c_str(), &end, 10);
                        if (arg.empty() || *end) bad("nth-child takes a number, odd or even");
                        p.a = 0;
                        p.b = int(k);
                    }
                }
                c.pseudos.push_back(p);
                any = true;
            } else {
                break;
            }
        }
        if (!any) bad(i_ < s_.size() ? "unexpected '" + std::string(1, s_[i_]) + "'" : "the selector ends too early");
        return c;
    }

    const std::string& s_;
    const char* command_;
    std::string pointer_;
    std::size_t i_ = 0;
};

bool match_attr(const XNode& n, const AttrTest& t) {
    const std::string* v = n.attr(t.name);
    if (!v) return false;
    if (t.op.empty()) return true;
    if (t.op == "=") return *v == t.value;
    if (t.op == "^=") return !t.value.empty() && v->rfind(t.value, 0) == 0;
    if (t.op == "$=") return !t.value.empty() && v->size() >= t.value.size() && v->compare(v->size() - t.value.size(), t.value.size(), t.value) == 0;
    if (t.op == "*=") return !t.value.empty() && v->find(t.value) != std::string::npos;
    if (t.op == "|=") return *v == t.value || v->rfind(t.value + "-", 0) == 0;
    if (t.op == "~=") {
        std::size_t i = 0;
        while (i < v->size()) {
            while (i < v->size() && is_space((*v)[i])) ++i;
            std::size_t e = i;
            while (e < v->size() && !is_space((*v)[e])) ++e;
            if (e > i && v->substr(i, e - i) == t.value) return true;
            i = e;
        }
    }
    return false;
}

bool match_compound(const XNode& n, const Compound& c) {
    if (!c.tag.empty() && n.local() != c.tag) return false;
    if (!c.id.empty() && n.attr_or("id") != c.id) return false;
    for (const std::string& cl : c.classes)
        if (!match_attr(n, {"class", "~=", cl})) return false;
    for (const AttrTest& t : c.attrs)
        if (!match_attr(n, t)) return false;
    for (const auto& p : c.pseudos) {
        if (!n.parent) return false;
        const std::vector<XNode*> sib = n.parent->elements();
        const std::size_t idx = std::size_t(std::find(sib.begin(), sib.end(), &n) - sib.begin());
        if (p.name == "first-child" && idx != 0) return false;
        if (p.name == "last-child" && idx + 1 != sib.size()) return false;
        if (p.name == "only-child" && sib.size() != 1) return false;
        if (p.name == "nth-child") {
            const int pos = int(idx) + 1;
            if (p.a == 0 ? pos != p.b : ((pos - p.b) % p.a != 0 || (pos - p.b) / p.a < 0)) return false;
        }
    }
    return true;
}

bool match_complex(const XNode& n, const Complex& c, std::size_t i) {
    if (!match_compound(n, c[i].c)) return false;
    if (i == 0) return true;
    if (c[i].comb == '>') return n.parent && match_complex(*n.parent, c, i - 1);
    for (const XNode* p = n.parent; p; p = p->parent)
        if (match_complex(*p, c, i - 1)) return true;
    return false;
}

}  // namespace

std::vector<XNode*> select_elements(const SvgDoc& doc, const std::string& refIn, const char* command, const std::string& pointer) {
    const std::string ref = trimmed(refIn);
    if (ref.empty()) assets_detail::arg_error(command, pointer, "the element reference is empty.", "Pass an SVG id (\"badge\") or a selector (\"g.ring path\").");
    if (XNode* n = doc.by_id(ref)) return {n};
    const std::vector<XNode*> all = doc.all_elements();
    std::vector<XNode*> out;
    const bool plain = ref.find_first_of("#.[]:>,* \t()") == std::string::npos;
    if (plain) {
        for (XNode* n : all)
            if (n != doc.root() && n->local() == ref) out.push_back(n);
    } else {
        SelectorParser sp(ref, command, pointer);
        const std::vector<Complex> sel = sp.parse();
        for (XNode* n : all)
            for (const Complex& c : sel)
                if (match_complex(*n, c, c.size() - 1)) {
                    out.push_back(n);
                    break;
                }
    }
    if (out.empty()) {
        const std::vector<std::string> ids = doc.ids();
        std::string list;
        for (std::size_t i = 0; i < ids.size() && i < 20; ++i) list += (i ? ", " : "") + ids[i];
        if (ids.size() > 20) list += ", ...";
        assets_detail::fail("not_found", std::format("{} {}: no element has the id or matches the selector '{}'.", command, pointer, ref),
                            (ids.empty() ? "This SVG has no ids: give the shapes id=\"...\" attributes, or use a selector such as \"path:first-child\" or \".ring\"."
                                         : did_you_mean(ref, ids) + " Ids in this SVG: " + list + ".") +
                                " Run vector.info to list the shapes.");
    }
    return out;
}

}  // namespace fa::vec
