// SMIL sampling (fa/tooling/svg_smil.h): an animated SVG at one instant, as a still SVG.
//
// The document is read once into a small XML tree and its animation elements into `Anim` records (timing, values, key
// times and splines already checked). sample(t) then works out, for every animated element, the value of each animated
// attribute at `t` and writes the tree out again with those attributes replaced and the animation elements removed.
#include "fa/tooling/svg_smil.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <format>
#include <limits>
#include <set>
#include <unordered_map>

#include "fa/core/json.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

constexpr double kInf = std::numeric_limits<double>::infinity();
constexpr double kPiD = 3.14159265358979323846;
constexpr int kMaxDepth = 200;

// ---- XML ---------------------------------------------------------------------------------------------------

struct Node;
struct Child {
    std::unique_ptr<Node> node;  // an element, or
    std::string text;            // text (kept as written, entities included, so it is written out unchanged)
};

struct Node {
    std::string name;
    std::vector<std::pair<std::string, std::string>> attrs;
    std::vector<Child> kids;
    Node* parent = nullptr;
    int line = 1;

    const std::string* attr(std::string_view n) const {
        for (const auto& a : attrs)
            if (a.first == n) return &a.second;
        return nullptr;
    }
    std::string attr_or(std::string_view n, std::string fallback = {}) const {
        const std::string* v = attr(n);
        return v ? *v : fallback;
    }
};

std::string escape_text(std::string_view s) {
    std::string out;
    for (char c : s) {
        if (c == '&') out += "&amp;";
        else if (c == '<') out += "&lt;";
        else if (c == '>') out += "&gt;";
        else out += c;
    }
    return out;
}

bool is_space(char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r'; }
bool is_name_char(char c) { return !is_space(c) && c != '=' && c != '>' && c != '/' && c != '<'; }

class XmlReader {
public:
    explicit XmlReader(const std::string& s) : s_(s) {}

    Result<std::unique_ptr<Node>> read() {
        std::unique_ptr<Node> root;
        std::vector<Node*> open;
        while (p_ < s_.size()) {
            if (s_[p_] != '<') {
                const std::size_t end = std::min(s_.find('<', p_), s_.size());
                if (!open.empty()) open.back()->kids.push_back({nullptr, s_.substr(p_, end - p_)});
                p_ = end;
                continue;
            }
            if (starts("<!--")) {
                const std::size_t end = s_.find("-->", p_ + 4);
                if (end == std::string::npos) return fail("a comment is never closed", "End it with -->.", p_);
                p_ = end + 3;
            } else if (starts("<![CDATA[")) {
                const std::size_t end = s_.find("]]>", p_ + 9);
                if (end == std::string::npos) return fail("a CDATA section is never closed", "End it with ]]>.", p_);
                if (!open.empty()) open.back()->kids.push_back({nullptr, escape_text(s_.substr(p_ + 9, end - p_ - 9))});
                p_ = end + 3;
            } else if (starts("<?")) {
                const std::size_t end = s_.find("?>", p_ + 2);
                if (end == std::string::npos) return fail("a processing instruction is never closed", "End it with ?>.", p_);
                p_ = end + 2;
            } else if (starts("<!")) {  // <!DOCTYPE ...>, with an optional [internal subset]
                int brackets = 0;
                std::size_t q = p_ + 2;
                for (; q < s_.size(); ++q) {
                    if (s_[q] == '[') ++brackets;
                    else if (s_[q] == ']') --brackets;
                    else if (s_[q] == '>' && brackets <= 0) break;
                }
                if (q >= s_.size()) return fail("a <!...> declaration is never closed", "End it with >.", p_);
                p_ = q + 1;
            } else if (starts("</")) {
                const std::size_t start = p_;
                p_ += 2;
                const std::string name = read_name();
                while (p_ < s_.size() && is_space(s_[p_])) ++p_;
                if (p_ >= s_.size() || s_[p_] != '>') return fail("the closing tag </" + name + " has no >", "Write </" + name + ">.", start);
                ++p_;
                if (open.empty()) return fail("</" + name + "> closes an element that is not open", "Remove it, or add the opening tag.", start);
                if (open.back()->name != name)
                    return fail("</" + name + "> does not match <" + open.back()->name + "> (opened at line " + std::to_string(open.back()->line) + ")",
                                "Close the elements in the order they were opened.", start);
                open.pop_back();
            } else {
                auto node = read_start_tag();
                if (!node.ok()) return node.error();
                std::unique_ptr<Node> n = std::move(*node);
                const bool selfClosing = selfClosing_;
                Node* raw = n.get();
                if (open.empty()) {
                    if (root) return fail("a second root element <" + n->name + ">", "An SVG has one <svg> root; put the rest inside it.", p_);
                    root = std::move(n);
                } else {
                    raw->parent = open.back();
                    open.back()->kids.push_back({std::move(n), {}});
                }
                if (!selfClosing) {
                    if (int(open.size()) >= kMaxDepth) return fail("elements are nested more than " + std::to_string(kMaxDepth) + " deep", "Flatten the groups.", p_);
                    open.push_back(raw);
                }
            }
        }
        if (!open.empty()) return fail("<" + open.back()->name + "> (line " + std::to_string(open.back()->line) + ") is never closed", "Add </" + open.back()->name + ">.", s_.size());
        if (!root) return fail("the text has no element", "Start with <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\">.", 0);
        return root;
    }

private:
    const std::string& s_;
    std::size_t p_ = 0;
    bool selfClosing_ = false;

    bool starts(const char* lit) const { return s_.compare(p_, std::strlen(lit), lit) == 0; }

    int line_of(std::size_t pos) const {
        return 1 + int(std::count(s_.begin(), s_.begin() + std::ptrdiff_t(std::min(pos, s_.size())), '\n'));
    }
    int column_of(std::size_t pos) const {
        pos = std::min(pos, s_.size());
        std::size_t lineStart = pos == 0 ? std::string::npos : s_.rfind('\n', pos - 1);
        lineStart = lineStart == std::string::npos ? 0 : lineStart + 1;
        return int(pos - lineStart) + 1;
    }

    Error fail(const std::string& what, const std::string& hint, std::size_t pos) const {
        return Error{std::format("The SVG is not well-formed XML (line {}, column {}): {}.", line_of(pos), column_of(pos), what), hint};
    }

    std::string read_name() {
        const std::size_t start = p_;
        while (p_ < s_.size() && is_name_char(s_[p_])) ++p_;
        return s_.substr(start, p_ - start);
    }

    Result<std::unique_ptr<Node>> read_start_tag() {
        const std::size_t start = p_;
        ++p_;  // <
        auto node = std::make_unique<Node>();
        node->line = line_of(start);
        node->name = read_name();
        if (node->name.empty()) return fail("'<' is not followed by an element name", "Write &lt; for a literal <.", start);
        selfClosing_ = false;
        for (;;) {
            while (p_ < s_.size() && is_space(s_[p_])) ++p_;
            if (p_ >= s_.size()) return fail("<" + node->name + "> has no closing >", "End the tag with > or />.", start);
            if (s_[p_] == '>') {
                ++p_;
                return node;
            }
            if (s_[p_] == '/' && p_ + 1 < s_.size() && s_[p_ + 1] == '>') {
                p_ += 2;
                selfClosing_ = true;
                return node;
            }
            const std::size_t attrStart = p_;
            const std::string name = read_name();
            if (name.empty()) return fail("unexpected '" + std::string(1, s_[p_]) + "' inside <" + node->name + ">", "Attributes are name=\"value\".", attrStart);
            while (p_ < s_.size() && is_space(s_[p_])) ++p_;
            if (p_ >= s_.size() || s_[p_] != '=')
                return fail("attribute '" + name + "' of <" + node->name + "> has no value", "Write " + name + "=\"...\".", attrStart);
            ++p_;
            while (p_ < s_.size() && is_space(s_[p_])) ++p_;
            if (p_ >= s_.size() || (s_[p_] != '"' && s_[p_] != '\''))
                return fail("the value of '" + name + "' is not in quotes", "Write " + name + "=\"...\".", attrStart);
            const char quote = s_[p_++];
            const std::size_t end = s_.find(quote, p_);
            if (end == std::string::npos) return fail("the value of '" + name + "' is never closed", "End it with " + std::string(1, quote) + ".", attrStart);
            node->attrs.emplace_back(name, s_.substr(p_, end - p_));
            p_ = end + 1;
        }
    }
};

std::string local_name(const std::string& n) {
    const std::size_t colon = n.rfind(':');
    return colon == std::string::npos ? n : n.substr(colon + 1);
}

// ---- small parsers -----------------------------------------------------------------------------------------

std::string trimmed(std::string_view s) { return std::string(trim(s)); }

std::vector<std::string> split_list(const std::string& s, char sep) {
    std::vector<std::string> out;
    std::size_t start = 0;
    for (;;) {
        const std::size_t end = s.find(sep, start);
        out.push_back(trimmed(std::string_view(s).substr(start, end == std::string::npos ? std::string::npos : end - start)));
        if (end == std::string::npos) break;
        start = end + 1;
    }
    while (!out.empty() && out.back().empty()) out.pop_back();  // a trailing ';' is allowed
    return out;
}

bool parse_double(std::string_view text, double& out) {
    const std::string s(text);
    if (s.empty()) return false;
    char* end = nullptr;
    out = std::strtod(s.c_str(), &end);
    return end == s.c_str() + s.size() && std::isfinite(out);
}

// "2s", "500ms", "1.5min", "1h", "3" (seconds), "01:30", "1:02:03.5"
bool parse_clock(std::string_view text, double& out) {
    std::string s = trimmed(text);
    if (s.empty()) return false;
    double sign = 1;
    if (s[0] == '+' || s[0] == '-') {
        sign = s[0] == '-' ? -1 : 1;
        s = trimmed(std::string_view(s).substr(1));
    }
    if (s.find(':') != std::string::npos) {
        const auto parts = split_list(s, ':');
        if (parts.size() < 2 || parts.size() > 3) return false;
        double total = 0;
        for (const std::string& p : parts) {
            double v;
            if (!parse_double(p, v) || v < 0) return false;
            total = total * 60 + v;
        }
        out = sign * total;
        return true;
    }
    double scale = 1;
    auto strip = [&](const char* unit, double k) {
        const std::size_t n = std::strlen(unit);
        if (s.size() > n && s.compare(s.size() - n, n, unit) == 0) {
            s.resize(s.size() - n);
            scale = k;
            return true;
        }
        return false;
    };
    if (!strip("ms", 0.001) && !strip("min", 60) && !strip("h", 3600)) strip("s", 1);
    double v;
    if (!parse_double(trimmed(s), v)) return false;
    out = sign * v * scale;
    return true;
}

std::string fmt_num(double v) {
    if (!std::isfinite(v) || std::fabs(v) < 1e-9) return "0";
    return std::format("{:.8g}", v);
}

// ---- values: numbers around fixed text, colours ----------------------------------------------------------------

enum class ValKind { Opaque, Num, Color };

struct Val {
    ValKind kind = ValKind::Opaque;
    std::string raw;
    std::vector<double> nums;       // the numbers (Num), or r g b in 0..255 (Color)
    std::vector<std::string> parts;  // Num: the text before the first number, between numbers, after the last (nums + 1)
};

bool scan_number(const std::string& s, std::size_t& i, double& v) {
    std::size_t j = i;
    if (j < s.size() && (s[j] == '+' || s[j] == '-')) ++j;
    const std::size_t digitsStart = j;
    while (j < s.size() && std::isdigit(static_cast<unsigned char>(s[j]))) ++j;
    if (j < s.size() && s[j] == '.') {
        ++j;
        while (j < s.size() && std::isdigit(static_cast<unsigned char>(s[j]))) ++j;
    }
    if (j == digitsStart || (j == digitsStart + 1 && s[digitsStart] == '.')) return false;
    if (j < s.size() && (s[j] == 'e' || s[j] == 'E')) {
        std::size_t k = j + 1;
        if (k < s.size() && (s[k] == '+' || s[k] == '-')) ++k;
        if (k < s.size() && std::isdigit(static_cast<unsigned char>(s[k]))) {
            while (k < s.size() && std::isdigit(static_cast<unsigned char>(s[k]))) ++k;
            j = k;
        }
    }
    v = std::strtod(s.substr(i, j - i).c_str(), nullptr);
    i = j;
    return true;
}

Val parse_val(const std::string& text, bool colourAttr) {
    Val v;
    v.raw = trimmed(text);
    if (colourAttr) {
        Color c;
        const std::string low = to_lower(v.raw);
        if (low.rfind("rgb(", 0) == 0 && low.back() == ')') {
            std::vector<double> ch;
            std::string inner = low.substr(4, low.size() - 5);
            std::replace(inner.begin(), inner.end(), ',', ' ');
            std::size_t i = 0;
            double n;
            bool ok = true;
            while (i < inner.size()) {
                if (is_space(inner[i])) { ++i; continue; }
                if (!scan_number(inner, i, n)) { ok = false; break; }
                if (i < inner.size() && inner[i] == '%') { n = n * 255.0 / 100.0; ++i; }
                ch.push_back(n);
            }
            if (ok && ch.size() == 3) {
                v.kind = ValKind::Color;
                v.nums = {std::clamp(ch[0], 0.0, 255.0), std::clamp(ch[1], 0.0, 255.0), std::clamp(ch[2], 0.0, 255.0)};
                return v;
            }
        } else if (parse_color(v.raw, c) && low != "none") {
            v.kind = ValKind::Color;
            v.nums = {std::round(c.r * 255.0), std::round(c.g * 255.0), std::round(c.b * 255.0)};
            return v;
        }
        return v;  // none, currentColor, url(...), a name this table lacks: changes at its key time
    }
    v.kind = ValKind::Num;
    std::string part;
    std::size_t i = 0;
    while (i < v.raw.size()) {
        double n;
        const std::size_t before = i;
        if (scan_number(v.raw, i, n)) {
            // a letter glued to the number in front ("a1", "#fff1") is part of a name, not a number
            v.parts.push_back(part);
            part.clear();
            v.nums.push_back(n);
        } else {
            i = before + 1;
            part += v.raw[before];
        }
    }
    v.parts.push_back(part);
    if (v.nums.empty()) v.kind = ValKind::Opaque;
    return v;
}

std::string format_val(const Val& v) {
    if (v.kind == ValKind::Color) {
        auto byte = [](double c) { return int(std::clamp(std::lround(c), 0L, 255L)); };
        return std::format("#{:02x}{:02x}{:02x}", byte(v.nums[0]), byte(v.nums[1]), byte(v.nums[2]));
    }
    if (v.kind == ValKind::Num) {
        std::string out;
        for (std::size_t i = 0; i < v.nums.size(); ++i) out += v.parts[i] + fmt_num(v.nums[i]);
        return out + v.parts.back();
    }
    return v.raw;
}

bool same_shape(const Val& a, const Val& b) {
    return a.kind == b.kind && a.kind != ValKind::Opaque && a.nums.size() == b.nums.size() && (a.kind == ValKind::Color || a.parts == b.parts);
}

// ---- cubic Bezier easing (keySplines) --------------------------------------------------------------------------

double spline_ease(const std::array<double, 4>& k, double x) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;
    auto bez = [](double a, double b, double t) {
        const double u = 1 - t;
        return 3 * u * u * t * a + 3 * u * t * t * b + t * t * t;
    };
    double lo = 0, hi = 1;
    for (int i = 0; i < 48; ++i) {
        const double mid = (lo + hi) * 0.5;
        (bez(k[0], k[2], mid) < x ? lo : hi) = mid;
    }
    return bez(k[1], k[3], (lo + hi) * 0.5);
}

// ---- path geometry for animateMotion ---------------------------------------------------------------------------

struct Pt {
    double x = 0, y = 0;
};

struct Polyline {
    std::vector<Pt> pts;
    std::vector<double> cum;  // cumulative length at each point
    double length() const { return cum.empty() ? 0 : cum.back(); }

    void add(Pt p) {
        if (pts.empty()) {
            pts.push_back(p);
            cum.push_back(0);
            return;
        }
        cum.push_back(cum.back() + std::hypot(p.x - pts.back().x, p.y - pts.back().y));
        pts.push_back(p);
    }
    // Position and direction (radians) at distance `d` along the path.
    void at(double d, Pt& pos, double& angle) const {
        if (pts.empty()) return;
        if (pts.size() == 1 || length() <= 0) {
            pos = pts[0];
            angle = 0;
            return;
        }
        d = std::clamp(d, 0.0, length());
        std::size_t k = std::upper_bound(cum.begin(), cum.end(), d) - cum.begin();
        k = std::clamp<std::size_t>(k, 1, pts.size() - 1);
        // skip zero-length steps so the direction is that of a real segment
        std::size_t seg = k;
        while (seg > 1 && cum[seg] - cum[seg - 1] <= 0) --seg;
        const double span = cum[k] - cum[k - 1];
        const double u = span > 0 ? (d - cum[k - 1]) / span : 0;
        pos = {pts[k - 1].x + (pts[k].x - pts[k - 1].x) * u, pts[k - 1].y + (pts[k].y - pts[k - 1].y) * u};
        angle = std::atan2(pts[seg].y - pts[seg - 1].y, pts[seg].x - pts[seg - 1].x);
    }
};

void flatten_cubic(Polyline& out, Pt p0, Pt p1, Pt p2, Pt p3) {
    constexpr int kSteps = 48;
    for (int i = 1; i <= kSteps; ++i) {
        const double t = double(i) / kSteps, u = 1 - t;
        out.add({u * u * u * p0.x + 3 * u * u * t * p1.x + 3 * u * t * t * p2.x + t * t * t * p3.x,
                 u * u * u * p0.y + 3 * u * u * t * p1.y + 3 * u * t * t * p2.y + t * t * t * p3.y});
    }
}

void flatten_arc(Polyline& out, Pt p0, double rx, double ry, double rotDeg, bool large, bool sweep, Pt p1) {
    if (rx == 0 || ry == 0 || (p0.x == p1.x && p0.y == p1.y)) {
        out.add(p1);
        return;
    }
    rx = std::fabs(rx);
    ry = std::fabs(ry);
    const double phi = rotDeg * kPiD / 180.0, cp = std::cos(phi), sp = std::sin(phi);
    const double dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2;
    const double x1 = cp * dx + sp * dy, y1 = -sp * dx + cp * dy;
    const double lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry);
    if (lambda > 1) {
        rx *= std::sqrt(lambda);
        ry *= std::sqrt(lambda);
    }
    const double num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1;
    const double den = rx * rx * y1 * y1 + ry * ry * x1 * x1;
    double coef = den == 0 ? 0 : std::sqrt(std::max(0.0, num / den));
    if (large == sweep) coef = -coef;
    const double cxp = coef * rx * y1 / ry, cyp = -coef * ry * x1 / rx;
    const double cx = cp * cxp - sp * cyp + (p0.x + p1.x) / 2, cy = sp * cxp + cp * cyp + (p0.y + p1.y) / 2;
    auto angle = [](double ux, double uy, double vx, double vy) {
        return std::atan2(ux * vy - uy * vx, ux * vx + uy * vy);
    };
    const double th1 = angle(1, 0, (x1 - cxp) / rx, (y1 - cyp) / ry);
    double dth = angle((x1 - cxp) / rx, (y1 - cyp) / ry, (-x1 - cxp) / rx, (-y1 - cyp) / ry);
    if (!sweep && dth > 0) dth -= 2 * kPiD;
    if (sweep && dth < 0) dth += 2 * kPiD;
    constexpr int kSteps = 48;
    for (int i = 1; i <= kSteps; ++i) {
        const double th = th1 + dth * double(i) / kSteps;
        const double ex = rx * std::cos(th), ey = ry * std::sin(th);
        out.add({cp * ex - sp * ey + cx, sp * ex + cp * ey + cy});
    }
}

// Path data to a polyline. False (with `why`) for data it cannot read.
bool flatten_path(const std::string& d, Polyline& out, std::string& why) {
    std::size_t i = 0;
    char cmd = 0;
    Pt cur, start, lastCtl;
    char prev = 0;
    auto skip = [&] {
        while (i < d.size() && (is_space(d[i]) || d[i] == ',')) ++i;
    };
    auto number = [&](double& v) {
        skip();
        return scan_number(d, i, v);
    };
    auto flag = [&](bool& f) {
        skip();
        if (i < d.size() && (d[i] == '0' || d[i] == '1')) {
            f = d[i++] == '1';
            return true;
        }
        return false;
    };
    for (;;) {
        skip();
        if (i >= d.size()) break;
        if (std::isalpha(static_cast<unsigned char>(d[i]))) cmd = d[i++];
        else if (cmd == 0) {
            why = "path data must start with M";
            return false;
        }
        const bool rel = std::islower(static_cast<unsigned char>(cmd));
        const char up = char(std::toupper(static_cast<unsigned char>(cmd)));
        double a[7];
        auto need = [&](int n) {
            for (int k = 0; k < n; ++k)
                if (!number(a[k])) return false;
            return true;
        };
        auto abs_pt = [&](double x, double y) { return Pt{rel ? cur.x + x : x, rel ? cur.y + y : y}; };
        bool ok = true;
        switch (up) {
            case 'M': {
                ok = need(2);
                if (!ok) break;
                cur = abs_pt(a[0], a[1]);
                start = cur;
                out.add(cur);
                cmd = rel ? 'l' : 'L';
                break;
            }
            case 'L': ok = need(2); if (ok) { cur = abs_pt(a[0], a[1]); out.add(cur); } break;
            case 'H': ok = need(1); if (ok) { cur.x = rel ? cur.x + a[0] : a[0]; out.add(cur); } break;
            case 'V': ok = need(1); if (ok) { cur.y = rel ? cur.y + a[0] : a[0]; out.add(cur); } break;
            case 'C': {
                ok = need(6);
                if (!ok) break;
                const Pt c1 = abs_pt(a[0], a[1]), c2 = abs_pt(a[2], a[3]), e = abs_pt(a[4], a[5]);
                flatten_cubic(out, cur, c1, c2, e);
                lastCtl = c2;
                cur = e;
                break;
            }
            case 'S': {
                ok = need(4);
                if (!ok) break;
                const Pt c1 = (prev == 'C' || prev == 'S') ? Pt{2 * cur.x - lastCtl.x, 2 * cur.y - lastCtl.y} : cur;
                const Pt c2 = abs_pt(a[0], a[1]), e = abs_pt(a[2], a[3]);
                flatten_cubic(out, cur, c1, c2, e);
                lastCtl = c2;
                cur = e;
                break;
            }
            case 'Q': {
                ok = need(4);
                if (!ok) break;
                const Pt q = abs_pt(a[0], a[1]), e = abs_pt(a[2], a[3]);
                flatten_cubic(out, cur, {cur.x + 2.0 / 3 * (q.x - cur.x), cur.y + 2.0 / 3 * (q.y - cur.y)},
                              {e.x + 2.0 / 3 * (q.x - e.x), e.y + 2.0 / 3 * (q.y - e.y)}, e);
                lastCtl = q;
                cur = e;
                break;
            }
            case 'T': {
                ok = need(2);
                if (!ok) break;
                const Pt q = (prev == 'Q' || prev == 'T') ? Pt{2 * cur.x - lastCtl.x, 2 * cur.y - lastCtl.y} : cur;
                const Pt e = abs_pt(a[0], a[1]);
                flatten_cubic(out, cur, {cur.x + 2.0 / 3 * (q.x - cur.x), cur.y + 2.0 / 3 * (q.y - cur.y)},
                              {e.x + 2.0 / 3 * (q.x - e.x), e.y + 2.0 / 3 * (q.y - e.y)}, e);
                lastCtl = q;
                cur = e;
                break;
            }
            case 'A': {
                bool large = false, sweep = false;
                double ex = 0, ey = 0;
                ok = need(3) && flag(large) && flag(sweep) && number(ex) && number(ey);
                if (!ok) break;
                const Pt e = abs_pt(ex, ey);
                flatten_arc(out, cur, a[0], a[1], a[2], large, sweep, e);
                cur = e;
                break;
            }
            case 'Z': out.add(start); cur = start; break;
            default:
                why = std::string("unknown path command '") + cmd + "'";
                return false;
        }
        if (!ok) {
            why = std::string("the numbers of path command '") + cmd + "' are missing or malformed";
            return false;
        }
        prev = up;
        if (up == 'Z') cmd = 0;
    }
    return !out.pts.empty();
}

}  // namespace

// ---- the document ------------------------------------------------------------------------------------------------

namespace {

enum class Kind { Animate, Set, Transform, Motion };
enum class Calc { Linear, Discrete, Paced, Spline };
enum class Rotate { None, Auto, AutoReverse, Fixed };

struct Anim {
    Node* node = nullptr;
    Node* target = nullptr;
    Kind kind = Kind::Animate;
    std::string attr;   // the attribute it animates ("transform" for animateTransform and animateMotion)
    std::string label;  // `<animate attributeName="r"> on <circle id="sun">`, for warnings
    std::size_t order = 0;
    bool valid = true;

    // timing
    std::vector<std::string> beginSpecs, endSpecs;
    std::vector<double> begins, ends;
    int resolveState = 0;  // 0 not yet, 1 busy (a sync-base cycle), 2 done
    double dur = kInf;     // simple duration, kInf = indefinite
    bool hasRepeatCount = false, hasRepeatDur = false;
    double repeatCount = 1, repeatDur = kInf;
    bool freeze = false;
    double activeDur = kInf;

    // values
    std::vector<std::string> values;  // the strings to go through; an empty first one stands for the underlying value
    bool fromUnderlying = false;
    bool byOnly = false;
    std::vector<double> keyTimes, keyPoints;
    std::vector<std::array<double, 4>> splines;
    Calc calc = Calc::Linear;
    bool additiveSum = false, accumulateSum = false;
    std::string tfType = "translate";

    // animateMotion
    Polyline path;
    Rotate rotate = Rotate::None;
    double rotateAngle = 0;
};

struct ActiveState {
    bool on = false;
    double local = 0;       // seconds into the active interval
    double beginTime = 0;   // when the instance began
    bool atEnd = false;     // frozen after the end
};

bool is_animation_name(const std::string& n) {
    return n == "animate" || n == "set" || n == "animateTransform" || n == "animateMotion" || n == "animateColor" || n == "discard";
}

bool is_colour_attr(const std::string& a) {
    return a == "fill" || a == "stroke" || a == "stop-color" || a == "flood-color" || a == "lighting-color" || a == "color";
}

std::string describe(const Node* n) {
    std::string s = "<" + local_name(n->name);
    if (const std::string* id = n->attr("id")) s += " id=\"" + *id + "\"";
    return s + ">";
}

std::string style_prop(const std::string& style, const std::string& prop) {
    for (const std::string& decl : split_list(style, ';')) {
        const std::size_t colon = decl.find(':');
        if (colon != std::string::npos && trimmed(std::string_view(decl).substr(0, colon)) == prop) return trimmed(std::string_view(decl).substr(colon + 1));
    }
    return {};
}

std::string style_property(const Node* n, const std::string& prop) {
    const std::string* style = n->attr("style");
    return style ? style_prop(*style, prop) : std::string();
}

std::string without_style_property(const std::string& style, const std::string& prop) {
    std::string out;
    for (const std::string& decl : split_list(style, ';')) {
        const std::size_t colon = decl.find(':');
        if (colon != std::string::npos && trimmed(std::string_view(decl).substr(0, colon)) == prop) continue;
        out += (out.empty() ? "" : ";") + decl;
    }
    return out;
}

}  // namespace

struct SmilSvg::Impl {
    std::unique_ptr<Node> root;
    std::vector<std::unique_ptr<Anim>> anims;
    std::unordered_map<std::string, Node*> byId;
    std::unordered_map<std::string, Anim*> animById;
    std::unordered_map<const Node*, std::vector<Anim*>> byTarget;
    std::vector<std::string> warned;
    std::set<std::string> warnedSet;

    void warn(const std::string& text) {
        if (warnedSet.insert(text).second) warned.push_back(text);
    }
    void warn_anim(const Anim& a, const std::string& what) { warn(a.label + ": " + what); }

    // ---- reading ----
    void collect(Node* n) {
        if (const std::string* id = n->attr("id")) byId.emplace(*id, n);
        for (Child& c : n->kids)
            if (c.node) collect(c.node.get());
    }
    void collect_anims(Node* n) {
        const std::string name = local_name(n->name);
        if (is_animation_name(name)) {
            read_anim(n, name);
        } else if (name == "style") {
            std::string css;
            for (const Child& c : n->kids) css += c.text;
            if (css.find("@keyframes") != std::string::npos || css.find("animation") != std::string::npos)
                warn("<style>: CSS animations (@keyframes, animation:) are not sampled; write the motion with <animate>, <animateTransform> or <animateMotion>, or draw it with a code module (`source`).");
        } else if (name == "script") {
            warn("<script>: scripts are not run; the animation must be SMIL (<animate>...) or a code module (`source`).");
        }
        if (name != "style" && n->attr("style") && style_property(n, "animation").size())
            warn(describe(n) + ": the CSS `animation` property is not sampled; use SMIL elements or a code module (`source`).");
        for (Child& c : n->kids)
            if (c.node) collect_anims(c.node.get());
    }

    void read_anim(Node* n, const std::string& name) {
        auto a = std::make_unique<Anim>();
        a->node = n;
        a->order = anims.size();
        const std::string attrName = trimmed(n->attr_or("attributeName"));
        a->label = "<" + name + (attrName.empty() ? "" : " attributeName=\"" + attrName + "\"") + ">";
        if (name == "discard") {
            warn("<discard>: not sampled (the element it names stays).");
            return;
        }
        // target: href / xlink:href, else the parent
        std::string href = n->attr_or("href", n->attr_or("xlink:href"));
        if (!href.empty()) {
            if (href[0] == '#') {
                auto it = byId.find(href.substr(1));
                a->target = it == byId.end() ? nullptr : it->second;
            }
            if (!a->target) {
                warn(a->label + ": its href '" + href + "' names no element of this SVG, so it is ignored.");
                return;
            }
        } else {
            a->target = n->parent;
        }
        if (!a->target) return;
        a->label += " on " + describe(a->target);
        for (const char* unsupported : {"min", "max", "restart"})
            if (n->attr(unsupported)) warn_anim(*a, std::string("`") + unsupported + "` is not sampled (ignored).");

        if (name == "set") a->kind = Kind::Set;
        else if (name == "animateTransform") a->kind = Kind::Transform;
        else if (name == "animateMotion") a->kind = Kind::Motion;
        else a->kind = Kind::Animate;
        if (a->kind == Kind::Transform || a->kind == Kind::Motion) {
            a->attr = "transform";
        } else {
            a->attr = attrName;
            if (a->attr.empty()) {
                warn_anim(*a, "has no attributeName, so it animates nothing (ignored).");
                return;
            }
        }
        if (a->kind == Kind::Transform) {
            if (attrName != "transform" && !attrName.empty())
                warn_anim(*a, "animateTransform animates `transform`; attributeName \"" + attrName + "\" is ignored.");
            a->tfType = trimmed(n->attr_or("type", "translate"));
            static const std::set<std::string> kTypes = {"translate", "scale", "rotate", "skewX", "skewY"};
            if (!kTypes.count(a->tfType)) {
                warn_anim(*a, "type \"" + a->tfType + "\" is not one of translate, scale, rotate, skewX, skewY (ignored).");
                return;
            }
        }

        read_timing(*a, n);
        if (!read_values(*a, n)) a->valid = false;
        anims.push_back(std::move(a));
        Anim* ptr = anims.back().get();
        byTarget[ptr->target].push_back(ptr);
        if (const std::string* id = n->attr("id")) animById.emplace(*id, ptr);
    }

    void read_timing(Anim& a, Node* n) {
        const std::string beginSpec = trimmed(n->attr_or("begin", "0s"));
        a.beginSpecs = split_list(beginSpec.empty() ? "0s" : beginSpec, ';');
        if (const std::string* e = n->attr("end")) a.endSpecs = split_list(*e, ';');
        const std::string dur = trimmed(n->attr_or("dur", "indefinite"));
        if (dur != "indefinite" && !dur.empty()) {
            double v;
            if (dur == "media" || !parse_clock(dur, v) || v <= 0)
                warn_anim(a, "dur=\"" + dur + "\" is not a positive time like \"2s\" or \"500ms\"; the duration is treated as indefinite.");
            else
                a.dur = v;
        }
        if (const std::string* rc = n->attr("repeatCount")) {
            a.hasRepeatCount = true;
            double v;
            if (trimmed(*rc) == "indefinite") a.repeatCount = kInf;
            else if (parse_double(trimmed(*rc), v) && v > 0) a.repeatCount = v;
            else {
                warn_anim(a, "repeatCount=\"" + *rc + "\" is not a positive number or \"indefinite\" (it repeats once).");
                a.hasRepeatCount = false;
            }
        }
        if (const std::string* rd = n->attr("repeatDur")) {
            double v;
            if (trimmed(*rd) == "indefinite") {
                a.hasRepeatDur = true;
                a.repeatDur = kInf;
            } else if (parse_clock(*rd, v) && v > 0) {
                a.hasRepeatDur = true;
                a.repeatDur = v;
            } else {
                warn_anim(a, "repeatDur=\"" + *rd + "\" is not a time like \"10s\" or \"indefinite\" (ignored).");
            }
        }
        a.freeze = trimmed(n->attr_or("fill")) == "freeze";
        // active duration (SMIL 3, 3.6.5): no repeat = the simple duration; count and duration both = the shorter
        if (!std::isfinite(a.dur)) {
            a.activeDur = a.hasRepeatDur ? a.repeatDur : kInf;
        } else if (a.hasRepeatCount || a.hasRepeatDur) {
            const double byCount = a.hasRepeatCount ? a.dur * a.repeatCount : kInf;
            const double byDur = a.hasRepeatDur ? a.repeatDur : kInf;
            a.activeDur = std::min(byCount, byDur);
        } else {
            a.activeDur = a.dur;
        }
    }

    // Reads values, keyTimes, keySplines and the rest. False when the animation cannot be sampled.
    bool read_values(Anim& a, Node* n) {
        a.additiveSum = trimmed(n->attr_or("additive")) == "sum";
        a.accumulateSum = trimmed(n->attr_or("accumulate")) == "sum";
        if (a.kind == Kind::Set) {
            const std::string* to = n->attr("to");
            if (!to) {
                warn_anim(a, "has no `to`, so it sets nothing (ignored).");
                return false;
            }
            a.values = {*to};
            return true;
        }
        const std::string calc = trimmed(n->attr_or("calcMode"));
        if (calc == "discrete") a.calc = Calc::Discrete;
        else if (calc == "paced") a.calc = Calc::Paced;
        else if (calc == "spline") a.calc = Calc::Spline;
        else if (calc.empty() || calc == "linear") a.calc = a.kind == Kind::Motion && calc.empty() ? Calc::Paced : Calc::Linear;
        else {
            warn_anim(a, "calcMode=\"" + calc + "\" is not discrete, linear, paced or spline (linear is used).");
            a.calc = Calc::Linear;
        }
        if (a.kind == Kind::Motion) return read_motion(a, n);

        const std::string* values = n->attr("values");
        const std::string* from = n->attr("from");
        const std::string* to = n->attr("to");
        const std::string* by = n->attr("by");
        if (values) {
            a.values = split_list(*values, ';');
            if (a.values.empty()) {
                warn_anim(a, "has an empty `values` (ignored).");
                return false;
            }
        } else if (to) {
            if (from) a.values = {*from, *to};
            else {
                a.values = {std::string(), *to};
                a.fromUnderlying = true;
            }
        } else if (by) {
            if (from) {
                // from + by: both numbers; formatted when sampled
                a.values = {*from, *from};
                a.byOnly = false;
                a.values[1] = "\x01" + *by;  // marker: from + by
            } else {
                a.values = {a.kind == Kind::Transform ? std::string() : std::string("0"), *by};
                a.fromUnderlying = false;
                a.byOnly = true;  // by-animation: the value is added to the underlying
            }
        } else {
            warn_anim(a, "has none of values, from/to or by, so it animates nothing (ignored).");
            return false;
        }
        const std::size_t count = a.values.size();
        if (const std::string* kt = n->attr("keyTimes")) {
            std::vector<double> times;
            bool ok = true;
            for (const std::string& s : split_list(*kt, ';')) {
                double v;
                ok = ok && parse_double(s, v) && v >= 0 && v <= 1;
                times.push_back(ok ? v : 0);
            }
            ok = ok && times.size() == count && std::is_sorted(times.begin(), times.end());
            if (ok && a.calc != Calc::Discrete && count > 1) ok = times.front() == 0 && times.back() == 1;
            if (ok && a.calc == Calc::Discrete) ok = times.front() == 0;
            if (ok) a.keyTimes = times;
            else
                warn_anim(a, std::format("keyTimes=\"{}\" does not fit its {} values (one per value, rising from 0{}); keyTimes are ignored.", *kt,
                                         count, a.calc == Calc::Discrete ? "" : " to 1"));
        }
        if (a.calc == Calc::Spline) {
            const std::string* ks = n->attr("keySplines");
            bool ok = ks != nullptr;
            if (ok) {
                for (const std::string& seg : split_list(*ks, ';')) {
                    std::string s = seg;
                    std::replace(s.begin(), s.end(), ',', ' ');
                    std::array<double, 4> v{};
                    std::size_t i = 0;
                    int got = 0;
                    double d;
                    while (i < s.size() && got < 5) {
                        if (is_space(s[i])) { ++i; continue; }
                        if (!scan_number(s, i, d)) { got = 99; break; }
                        if (got < 4) v[got] = d;
                        ++got;
                    }
                    if (got != 4 || v[0] < 0 || v[0] > 1 || v[2] < 0 || v[2] > 1) {
                        ok = false;
                        break;
                    }
                    a.splines.push_back(v);
                }
                ok = ok && a.splines.size() + 1 == count;
            }
            if (!ok) {
                warn_anim(a, "calcMode=\"spline\" needs keySplines with 4 numbers (x1 y1 x2 y2, x between 0 and 1) for each of the " +
                                 std::to_string(count > 0 ? count - 1 : 0) + " intervals, separated by ';' (linear is used).");
                a.calc = Calc::Linear;
                a.splines.clear();
            }
        }
        return true;
    }

    bool read_motion(Anim& a, Node* n) {
        std::string d = n->attr_or("path");
        if (d.empty()) {
            for (const Child& c : n->kids)
                if (c.node && local_name(c.node->name) == "mpath") {
                    std::string href = c.node->attr_or("href", c.node->attr_or("xlink:href"));
                    auto it = href.size() > 1 && href[0] == '#' ? byId.find(href.substr(1)) : byId.end();
                    if (it == byId.end() || !it->second->attr("d")) {
                        warn_anim(a, "its <mpath> href '" + href + "' names no <path> with a `d` (ignored).");
                        return false;
                    }
                    d = *it->second->attr("d");
                }
        }
        if (!d.empty()) {
            std::string why;
            if (!flatten_path(d, a.path, why)) {
                warn_anim(a, "cannot read its path: " + why + " (ignored).");
                return false;
            }
        } else if (const std::string* values = n->attr("values")) {
            a.values = split_list(*values, ';');
        } else if (n->attr("to")) {
            a.values = {n->attr("from") ? *n->attr("from") : "0,0", *n->attr("to")};
        } else if (n->attr("by")) {
            a.values = {n->attr("from") ? *n->attr("from") : "0,0", "\x01" + *n->attr("by")};
        } else {
            warn_anim(a, "has no path, mpath, values, from/to or by, so it moves nothing (ignored).");
            return false;
        }
        const std::string rot = trimmed(n->attr_or("rotate"));
        if (rot == "auto") a.rotate = Rotate::Auto;
        else if (rot == "auto-reverse") a.rotate = Rotate::AutoReverse;
        else if (!rot.empty()) {
            if (parse_double(rot, a.rotateAngle)) a.rotate = Rotate::Fixed;
            else warn_anim(a, "rotate=\"" + rot + "\" is not auto, auto-reverse or a number of degrees (ignored).");
        }
        const std::size_t count = !a.path.pts.empty() ? 2 : a.values.size();
        if (const std::string* kp = n->attr("keyPoints")) {
            std::vector<double> pts;
            bool ok = !a.path.pts.empty();
            for (const std::string& s : split_list(*kp, ';')) {
                double v;
                ok = ok && parse_double(s, v) && v >= 0 && v <= 1;
                pts.push_back(ok ? v : 0);
            }
            const std::string* kt = n->attr("keyTimes");
            std::vector<double> times;
            if (ok && kt)
                for (const std::string& s : split_list(*kt, ';')) {
                    double v;
                    ok = ok && parse_double(s, v) && v >= 0 && v <= 1;
                    times.push_back(ok ? v : 0);
                }
            ok = ok && kt && pts.size() == times.size() && pts.size() >= 2 && std::is_sorted(times.begin(), times.end());
            if (ok) {
                a.keyPoints = pts;
                a.keyTimes = times;
            } else {
                warn_anim(a, "keyPoints need a path and a keyTimes with the same number of entries, each 0 to 1 (ignored).");
            }
        } else if (const std::string* kt = n->attr("keyTimes")) {
            std::vector<double> times;
            bool ok = true;
            for (const std::string& s : split_list(*kt, ';')) {
                double v;
                ok = ok && parse_double(s, v) && v >= 0 && v <= 1;
                times.push_back(ok ? v : 0);
            }
            if (ok && times.size() == count && std::is_sorted(times.begin(), times.end())) a.keyTimes = times;
            else warn_anim(a, "keyTimes do not fit the path or values (one per value, rising); they are ignored.");
        }
        if (a.calc == Calc::Spline) {
            warn_anim(a, "calcMode=\"spline\" on a motion is sampled as linear.");
            a.calc = Calc::Linear;
        }
        return true;
    }

    // ---- timing ----
    // The times a begin/end list gives. A sync-base ("id.begin", "id.end+1s") needs the animation it names to be resolved.
    void resolve(Anim& a) {
        if (a.resolveState == 2) return;
        if (a.resolveState == 1) {
            warn_anim(a, "its begin/end refer to each other in a cycle (the cyclic reference is ignored).");
            return;
        }
        a.resolveState = 1;
        auto times = [&](const std::vector<std::string>& specs) {
            std::vector<double> out;
            for (const std::string& spec : specs) {
                if (spec.empty() || spec == "indefinite") continue;
                double v;
                if (parse_clock(spec, v)) {
                    out.push_back(v);
                    continue;
                }
                // id.begin / id.end with an optional +/- offset
                std::size_t dot = spec.find(".begin");
                std::size_t len = 6;
                if (dot == std::string::npos) {
                    dot = spec.find(".end");
                    len = 4;
                }
                if (dot != std::string::npos && dot > 0) {
                    const std::string id = trimmed(std::string_view(spec).substr(0, dot));
                    const bool isEnd = len == 4;
                    double offset = 0;
                    const std::string rest = trimmed(std::string_view(spec).substr(dot + len));
                    if (!rest.empty() && !((rest[0] == '+' || rest[0] == '-') && parse_clock(rest, offset))) {
                        warn_anim(a, "cannot read the time \"" + spec + "\" (only offsets like \"1s\" and sync-bases like \"other.end+0.5s\" are sampled); it is ignored.");
                        continue;
                    }
                    auto it = animById.find(id);
                    if (it == animById.end()) {
                        warn_anim(a, "time \"" + spec + "\" refers to '" + id + "', which is not an animation of this SVG (ignored).");
                        continue;
                    }
                    resolve(*it->second);
                    if (!isEnd) {
                        for (double b : it->second->begins) out.push_back(b + offset);
                    } else {
                        for (std::size_t k = 0; k < it->second->begins.size(); ++k) {
                            const double e = instance_end(*it->second, k);
                            if (std::isfinite(e)) out.push_back(e + offset);
                        }
                    }
                    continue;
                }
                warn_anim(a, "the time \"" + spec + "\" depends on an event or the clock (click, repeat(n), wallclock...), which cannot be sampled; it is ignored. Use an offset such as begin=\"1s\".");
            }
            std::sort(out.begin(), out.end());
            out.erase(std::unique(out.begin(), out.end()), out.end());
            return out;
        };
        a.begins = times(a.beginSpecs);
        a.ends = times(a.endSpecs);
        a.resolveState = 2;
    }

    // End of the instance that starts at begins[k]: the active duration, cut by `end` and by the next begin (restart always).
    static double instance_end(const Anim& a, std::size_t k) {
        const double b = a.begins[k];
        double e = b + a.activeDur;
        if (!a.endSpecs.empty()) {
            auto it = std::upper_bound(a.ends.begin(), a.ends.end(), b);
            if (it != a.ends.end()) e = std::min(e, *it);
            else if (a.ends.empty()) e = std::min(e, b + a.activeDur);  // an end that never comes (an event): no cut
        }
        if (k + 1 < a.begins.size()) e = std::min(e, a.begins[k + 1]);
        return e;
    }

    static ActiveState activity(const Anim& a, double t) {
        ActiveState s;
        if (a.begins.empty() || t < a.begins.front()) return s;
        const std::size_t k = std::size_t(std::upper_bound(a.begins.begin(), a.begins.end(), t) - a.begins.begin()) - 1;
        const double b = a.begins[k], e = instance_end(a, k);
        s.beginTime = b;
        if (t < e) {
            s.on = true;
            s.local = t - b;
        } else if (a.freeze && std::isfinite(e)) {
            s.on = true;
            s.atEnd = true;
            s.local = e - b;
        }
        return s;
    }

    // Iteration (0-based) and the progress f in 0..1 inside it.
    static void iteration(const Anim& a, const ActiveState& s, int& iter, double& f) {
        iter = 0;
        f = 0;
        if (!std::isfinite(a.dur)) return;
        const double ratio = s.local / a.dur;
        double whole = std::floor(ratio + 1e-9);
        f = ratio - whole;
        if (f < 1e-9) f = 0;
        if (s.atEnd && whole > 0 && f == 0) {  // frozen exactly on an iteration boundary: the end of the last one
            whole -= 1;
            f = 1;
        }
        iter = int(std::min(whole, 1e9));
    }

    // ---- values ----
    struct Interp {
        std::vector<double> nums;
        std::size_t discrete = 0;  // for values that cannot be interpolated: which one
        double u = 0;
    };

    // The segment of `kt` (n times) that f falls in, and the position u inside it. `discrete`: the last key time <= f.
    static void locate(const std::vector<double>& kt, double f, std::size_t& k, double& u) {
        const std::size_t n = kt.size();
        if (n < 2) {
            k = 0;
            u = 0;
            return;
        }
        if (f >= kt.back()) {
            k = n - 2;
            u = 1;
            return;
        }
        k = 0;
        for (std::size_t i = 0; i + 1 < n; ++i)
            if (kt[i] <= f) k = i;
        const double span = kt[k + 1] - kt[k];
        u = span > 0 ? std::clamp((f - kt[k]) / span, 0.0, 1.0) : 0;
    }

    static std::vector<double> even_times(std::size_t n, bool discrete) {
        std::vector<double> kt(n);
        for (std::size_t i = 0; i < n; ++i) kt[i] = n < 2 ? 0 : double(i) / double(discrete ? n : n - 1);
        return kt;
    }

    // vectors: the numbers of each value (all the same length) when interpolable, else empty vectors of the right count.
    static Interp interpolate(const Anim& a, const std::vector<std::vector<double>>& vectors, bool interpolable, double f) {
        const std::size_t n = vectors.size();
        Interp r;
        if (n == 1) {
            r.nums = vectors[0];
            return r;
        }
        const bool discrete = a.calc == Calc::Discrete || !interpolable;
        std::vector<double> kt = a.keyTimes;
        if (kt.empty() && a.calc == Calc::Paced && interpolable) {
            double total = 0;
            std::vector<double> cum(n, 0.0);
            for (std::size_t i = 1; i < n; ++i) {
                double d2 = 0;
                for (std::size_t c = 0; c < vectors[i].size(); ++c) d2 += (vectors[i][c] - vectors[i - 1][c]) * (vectors[i][c] - vectors[i - 1][c]);
                total += std::sqrt(d2);
                cum[i] = total;
            }
            if (total > 0) {
                kt = cum;
                for (double& v : kt) v /= total;
            }
        }
        if (kt.empty()) kt = even_times(n, discrete);
        if (discrete) {
            std::size_t k = 0;
            for (std::size_t i = 0; i < n; ++i)
                if (kt[i] <= f) k = i;
            r.discrete = k;
            r.nums = vectors[k];
            return r;
        }
        std::size_t k;
        double u;
        locate(kt, f, k, u);
        if (a.calc == Calc::Spline && k < a.splines.size()) u = spline_ease(a.splines[k], u);
        r.nums.resize(vectors[k].size());
        for (std::size_t c = 0; c < r.nums.size(); ++c) r.nums[c] = vectors[k][c] + (vectors[k + 1][c] - vectors[k][c]) * u;
        return r;
    }

    // What an attribute holds when the SVG does not set it (to-animations start from it).
    static std::string default_value(const std::string& attr) {
        if (attr == "opacity" || attr == "fill-opacity" || attr == "stroke-opacity" || attr == "stop-opacity" || attr == "stroke-width" || attr == "stroke-miterlimit") return "1";
        if (attr == "fill" || attr == "stop-color" || attr == "color") return "#000000";
        if (attr == "stroke") return "none";
        return "0";
    }

    // Value of an <animate>/<set> at the given progress, as attribute text. `underlying` is the value below it.
    std::string eval_animate(Anim& a, const ActiveState& s, const std::string& underlying) {
        int iter;
        double f;
        iteration(a, s, iter, f);
        if (a.kind == Kind::Set) return a.values[0];
        const bool colour = is_colour_attr(a.attr);
        const Val base = parse_val(underlying.empty() ? default_value(a.attr) : underlying, colour);
        std::vector<Val> vals;
        for (std::size_t i = 0; i < a.values.size(); ++i) {
            std::string text = a.values[i];
            if (i == 0 && a.fromUnderlying) text = underlying.empty() ? default_value(a.attr) : underlying;
            if (!text.empty() && text[0] == '\x01') {  // from + by
                Val from = parse_val(a.values[0], colour), by = parse_val(text.substr(1), colour);
                if (same_shape(from, by)) {
                    for (std::size_t c = 0; c < from.nums.size(); ++c) from.nums[c] += by.nums[c];
                    vals.push_back(from);
                } else {
                    warn_anim(a, "its from and by values are not numbers of the same shape (by is ignored).");
                    vals.push_back(from);
                }
                continue;
            }
            vals.push_back(parse_val(text, colour));
        }
        if (a.byOnly && vals.size() == 2) {  // by-animation: from 0 (in the shape of `by`) to by, added to the underlying value
            vals[0] = vals[1];
            std::fill(vals[0].nums.begin(), vals[0].nums.end(), 0.0);
        }
        bool interpolable = vals.size() > 1;
        for (const Val& v : vals) interpolable = interpolable && same_shape(v, vals[0]);
        if (!interpolable && vals.size() > 1 && a.calc != Calc::Discrete) {
            bool allNum = true;
            for (const Val& v : vals) allNum = allNum && v.kind != ValKind::Opaque;
            warn_anim(a, allNum ? "its values do not have the same structure (the same text around the numbers), so they change at their key times instead of blending."
                                : "its values are not numbers or colours, so they change at their key times instead of blending.");
        }
        std::vector<std::vector<double>> vectors;
        for (const Val& v : vals) vectors.push_back(interpolable ? v.nums : std::vector<double>());
        Interp r = interpolate(a, vectors, interpolable, f);
        Val out = vals[interpolable ? 0 : r.discrete];
        if (interpolable) out.nums = r.nums;
        if (a.accumulateSum && iter > 0 && out.kind == ValKind::Num && same_shape(out, vals.back()))
            for (std::size_t c = 0; c < out.nums.size(); ++c) out.nums[c] += double(iter) * vals.back().nums[c];
        if ((a.additiveSum || a.byOnly) && out.kind == ValKind::Num) {
            if (same_shape(out, base)) {
                for (std::size_t c = 0; c < out.nums.size(); ++c) out.nums[c] += base.nums[c];
                out.parts = base.parts;
            } else {
                warn_anim(a, "additive=\"sum\" needs the attribute to hold numbers of the same shape as the animated value; the animated value replaces it.");
            }
        }
        return format_val(out);
    }

    static std::vector<double> numbers_of(const std::string& s) {
        std::vector<double> out;
        std::size_t i = 0;
        while (i < s.size()) {
            double v;
            if (is_space(s[i]) || s[i] == ',') ++i;
            else if (scan_number(s, i, v)) out.push_back(v);
            else ++i;
        }
        return out;
    }

    std::string eval_transform(Anim& a, const ActiveState& s, const std::string& underlying) {
        int iter;
        double f;
        iteration(a, s, iter, f);
        const std::size_t arity = a.tfType == "translate" || a.tfType == "scale" ? 2 : a.tfType == "rotate" ? 3 : 1;
        auto vec = [&](const std::string& text, bool identity) {
            std::vector<double> v = numbers_of(text);
            if (identity && v.empty()) v = a.tfType == "scale" ? std::vector<double>{1, 1} : std::vector<double>{0};
            if (v.empty()) v = {0};
            if (a.tfType == "scale" && v.size() == 1) v.push_back(v[0]);
            v.resize(arity, 0.0);
            return v;
        };
        std::vector<std::vector<double>> vectors;
        for (std::size_t i = 0; i < a.values.size(); ++i) {
            const std::string& text = a.values[i];
            if (!text.empty() && text[0] == '\x01') {
                std::vector<double> from = vec(a.values[0], false), by = vec(text.substr(1), false);
                for (std::size_t c = 0; c < arity; ++c) from[c] += by[c];
                vectors.push_back(from);
            } else {
                vectors.push_back(vec(text, text.empty()));
            }
        }
        Interp r = interpolate(a, vectors, true, f);
        if (a.accumulateSum && iter > 0)
            for (std::size_t c = 0; c < r.nums.size(); ++c) r.nums[c] += double(iter) * vectors.back()[c];
        std::string out = a.tfType + "(";
        for (std::size_t c = 0; c < r.nums.size(); ++c) out += (c ? " " : "") + fmt_num(r.nums[c]);
        out += ")";
        if (a.additiveSum || a.byOnly) return underlying.empty() ? out : underlying + " " + out;
        return out;
    }

    std::string eval_motion(Anim& a, const ActiveState& s) {
        int iter;
        double f;
        iteration(a, s, iter, f);
        Pt pos;
        double angle = 0;
        if (!a.path.pts.empty()) {
            std::vector<std::vector<double>> scalars;
            std::vector<double> kps = a.keyPoints.empty() ? std::vector<double>{0, 1} : a.keyPoints;
            for (double v : kps) scalars.push_back({v});
            Anim shaped;  // only calc and keyTimes matter here
            shaped.calc = a.calc == Calc::Discrete ? Calc::Discrete : Calc::Linear;
            shaped.keyTimes = a.keyTimes;
            const double p = interpolate(shaped, scalars, true, f).nums[0];
            a.path.at(p * a.path.length(), pos, angle);
            if (a.accumulateSum && iter > 0) {
                Pt endPos;
                double ignored;
                a.path.at(a.path.length(), endPos, ignored);
                pos.x += iter * endPos.x;
                pos.y += iter * endPos.y;
            }
        } else {
            std::vector<std::vector<double>> pts;
            for (std::size_t i = 0; i < a.values.size(); ++i) {
                const bool isBy = !a.values[i].empty() && a.values[i][0] == '\x01';
                std::vector<double> v = numbers_of(isBy ? a.values[i].substr(1) : a.values[i]);
                v.resize(2, 0.0);
                if (isBy) {
                    const std::vector<double> from = numbers_of(a.values[0]);
                    v[0] += from.size() > 0 ? from[0] : 0;
                    v[1] += from.size() > 1 ? from[1] : 0;
                }
                pts.push_back(v);
            }
            if (pts.empty()) return {};
            const Interp r = interpolate(a, pts, true, f);
            pos = {r.nums[0], r.nums[1]};
            if (a.accumulateSum && iter > 0) {
                pos.x += iter * pts.back()[0];
                pos.y += iter * pts.back()[1];
            }
            if (pts.size() > 1 && a.rotate != Rotate::None && a.rotate != Rotate::Fixed) {
                std::size_t k;
                double u;
                locate(a.keyTimes.empty() ? even_times(pts.size(), false) : a.keyTimes, f, k, u);
                k = std::min(k, pts.size() - 2);
                angle = std::atan2(pts[k + 1][1] - pts[k][1], pts[k + 1][0] - pts[k][0]);
            }
        }
        std::string out = "translate(" + fmt_num(pos.x) + " " + fmt_num(pos.y) + ")";
        if (a.rotate == Rotate::Auto) out += " rotate(" + fmt_num(angle * 180.0 / kPiD) + ")";
        else if (a.rotate == Rotate::AutoReverse) out += " rotate(" + fmt_num(angle * 180.0 / kPiD + 180.0) + ")";
        else if (a.rotate == Rotate::Fixed) out += " rotate(" + fmt_num(a.rotateAngle) + ")";
        return out;
    }

    // ---- writing ----
    using Overrides = std::unordered_map<const Node*, std::vector<std::pair<std::string, std::string>>>;

    static void set_override(std::vector<std::pair<std::string, std::string>>& list, const std::string& name, const std::string& value) {
        for (auto& p : list)
            if (p.first == name) {
                p.second = value;
                return;
            }
        list.emplace_back(name, value);
    }

    std::string sample(double t) {
        Overrides overrides;
        for (auto& [target, list] : byTarget) {
            std::vector<std::pair<Anim*, ActiveState>> active;
            for (Anim* a : list)
                if (a->valid) {
                    const ActiveState s = activity(*a, t);
                    if (s.on) active.emplace_back(a, s);
                }
            if (active.empty()) continue;
            // the later an instance began, the later it is applied (ties: document order)
            std::stable_sort(active.begin(), active.end(), [](const auto& x, const auto& y) {
                if (x.second.beginTime != y.second.beginTime) return x.second.beginTime < y.second.beginTime;
                return x.first->order < y.first->order;
            });
            auto& out = overrides[target];
            auto underlying = [&](const std::string& attr) {
                for (const auto& p : out)
                    if (p.first == attr) return p.second;
                if (const std::string* v = target->attr(attr)) return trimmed(*v);
                return style_property(target, attr);
            };
            for (int pass = 0; pass < 2; ++pass) {  // motion last: it is appended to the transform list
                for (auto& [a, s] : active) {
                    if ((a->kind == Kind::Motion) != (pass == 1)) continue;
                    std::string value;
                    switch (a->kind) {
                        case Kind::Animate:
                        case Kind::Set: value = eval_animate(*a, s, underlying(a->attr)); break;
                        case Kind::Transform: value = eval_transform(*a, s, underlying("transform")); break;
                        case Kind::Motion: {
                            const std::string motion = eval_motion(*a, s);
                            const std::string base = underlying("transform");
                            value = base.empty() ? motion : base + " " + motion;
                            break;
                        }
                    }
                    if (a->kind == Kind::Motion && value.empty()) continue;
                    set_override(out, a->attr, value);
                    if (const std::string* style = target->attr("style")) {  // a style="fill:red" would beat the animated attribute
                        const std::string current = current_style(out, *style);
                        if (!style_prop(current, a->attr).empty()) set_override(out, "style", without_style_property(current, a->attr));
                    }
                }
            }
        }
        std::string text;
        write(*root, overrides, text);
        return text;
    }

    static std::string current_style(const std::vector<std::pair<std::string, std::string>>& out, const std::string& original) {
        for (const auto& p : out)
            if (p.first == "style") return p.second;
        return original;
    }

    void write(const Node& n, const Overrides& overrides, std::string& out) const {
        const std::string name = local_name(n.name);
        if (is_animation_name(name)) return;
        out += "<" + n.name;
        auto it = overrides.find(&n);
        std::set<std::string> written;
        for (const auto& [k, v] : n.attrs) {
            std::string value = v;
            if (it != overrides.end())
                for (const auto& o : it->second)
                    if (o.first == k) {
                        value = o.second;
                        written.insert(k);
                    }
            out += " " + k + "=\"" + escape_attr(value) + "\"";
        }
        if (it != overrides.end())
            for (const auto& o : it->second)
                if (!written.count(o.first)) out += " " + o.first + "=\"" + escape_attr(o.second) + "\"";
        bool any = false;
        for (const Child& c : n.kids)
            if (c.node ? !is_animation_name(local_name(c.node->name)) : !c.text.empty()) any = true;
        if (!any) {
            out += "/>";
            return;
        }
        out += ">";
        for (const Child& c : n.kids) {
            if (c.node) write(*c.node, overrides, out);
            else out += c.text;
        }
        out += "</" + n.name + ">";
    }

    static std::string escape_attr(const std::string& v) {
        if (v.find('"') == std::string::npos) return v;
        std::string out;
        for (char c : v) {
            if (c == '"') out += "&quot;";
            else out += c;
        }
        return out;
    }

    double cycle() {
        double cycle = 0;
        for (auto& a : anims) {
            if (!a->valid) continue;
            for (std::size_t k = 0; k < a->begins.size(); ++k) {
                double e = instance_end(*a, k);
                if (!std::isfinite(e)) e = std::isfinite(a->dur) ? a->begins[k] + a->dur : a->begins[k];
                cycle = std::max(cycle, e);
            }
        }
        return cycle;
    }
};

Result<SmilSvg> SmilSvg::parse(const std::string& svg) {
    XmlReader reader(svg);
    auto root = reader.read();
    if (!root.ok()) return root.error();
    if (local_name((*root)->name) != "svg")
        return Error{"The document's root element is <" + (*root)->name + ">, not <svg>.",
                     "Start with <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" width=\"100\" height=\"100\">."};
    SmilSvg out;
    out.impl_ = std::make_shared<Impl>();
    Impl& im = *out.impl_;
    im.root = std::move(*root);
    im.collect(im.root.get());
    im.collect_anims(im.root.get());
    for (auto& a : im.anims) im.resolve(*a);
    for (auto& a : im.anims)
        if (a->valid && a->begins.empty())
            im.warn_anim(*a, "never begins (its begin is an event or indefinite, which cannot be sampled), so it has no effect. Use begin=\"0s\" or another offset.");
    return out;
}

double SmilSvg::cycle_seconds() const { return impl_->cycle(); }

int SmilSvg::animation_count() const {
    int n = 0;
    for (const auto& a : impl_->anims) n += a->valid ? 1 : 0;
    return n;
}

std::string SmilSvg::sample(double t) const { return impl_->sample(t); }

const std::vector<std::string>& SmilSvg::warnings() const { return impl_->warned; }

}  // namespace fa
