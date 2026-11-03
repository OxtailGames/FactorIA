// Vector shapes of an image document: SVG path data -> polylines, a nonzero scanline fill with anti-aliasing, and the Gaussian
// blur that feathers a mask. Plain float math in a fixed order, so the same shape gives the same coverage on every run.
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <format>

#include "image_doc_internal.h"

namespace fa::imgdoc {

namespace {

constexpr float kPi = 3.14159265358979323846f;
constexpr int kSub = 4;  // sub-scanlines per pixel row

struct Scanner {
    const std::string& s;
    std::size_t i = 0;
    explicit Scanner(const std::string& text) : s(text) {}

    void skip() {
        while (i < s.size() && (s[i] == ' ' || s[i] == ',' || s[i] == '\t' || s[i] == '\n' || s[i] == '\r')) ++i;
    }
    bool at_end() {
        skip();
        return i >= s.size();
    }
    bool at_number() {
        skip();
        if (i >= s.size()) return false;
        const char c = s[i];
        return (c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.';
    }
    bool number(float& out) {
        skip();
        const char* begin = s.c_str() + i;
        char* end = nullptr;
        const double v = std::strtod(begin, &end);
        if (end == begin) return false;
        // strtod would read "1e" or "0x10"; a path number is decimal with an optional exponent
        for (const char* p = begin; p < end; ++p)
            if (*p == 'x' || *p == 'X' || *p == 'n' || *p == 'N' || *p == 'i' || *p == 'I') return false;
        out = float(v);
        i += std::size_t(end - begin);
        return true;
    }
    bool flag(float& out) {  // arc flags are one character and may touch the next number: "a1 1 0 00.5.5"
        skip();
        if (i < s.size() && (s[i] == '0' || s[i] == '1')) {
            out = s[i] == '1' ? 1.0f : 0.0f;
            ++i;
            return true;
        }
        return false;
    }
};

void flatten_cubic(Vec2 p0, Vec2 p1, Vec2 p2, Vec2 p3, std::vector<Vec2>& out) {
    const float len = length(p1 - p0) + length(p2 - p1) + length(p3 - p2);
    const int n = std::clamp(int(std::ceil(len / 2.0f)), 8, 128);
    for (int k = 1; k <= n; ++k) {
        const float t = float(k) / float(n), u = 1.0f - t;
        out.push_back(p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t));
    }
}

void flatten_quad(Vec2 p0, Vec2 p1, Vec2 p2, std::vector<Vec2>& out) {
    flatten_cubic(p0, p0 + (p1 - p0) * (2.0f / 3.0f), p2 + (p1 - p2) * (2.0f / 3.0f), p2, out);
}

// SVG implementation notes F.6: the endpoint parameterization of an arc to its centre one, then points along it.
void flatten_arc(Vec2 from, float rx, float ry, float rotation, bool large, bool sweep, Vec2 to, std::vector<Vec2>& out) {
    if (from.x == to.x && from.y == to.y) return;
    rx = std::fabs(rx);
    ry = std::fabs(ry);
    if (rx == 0.0f || ry == 0.0f) {
        out.push_back(to);
        return;
    }
    const float phi = rotation * kPi / 180.0f, cp = std::cos(phi), sp = std::sin(phi);
    const float dx = (from.x - to.x) * 0.5f, dy = (from.y - to.y) * 0.5f;
    const float x1 = cp * dx + sp * dy, y1 = -sp * dx + cp * dy;
    const float lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry);
    if (lambda > 1.0f) {
        const float k = std::sqrt(lambda);
        rx *= k;
        ry *= k;
    }
    const float num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1;
    const float den = rx * rx * y1 * y1 + ry * ry * x1 * x1;
    float coef = den == 0.0f ? 0.0f : std::sqrt(std::max(0.0f, num / den));
    if (large == sweep) coef = -coef;
    const float cxp = coef * (rx * y1 / ry), cyp = coef * -(ry * x1 / rx);
    const float cx = cp * cxp - sp * cyp + (from.x + to.x) * 0.5f, cy = sp * cxp + cp * cyp + (from.y + to.y) * 0.5f;
    auto angle = [](float ux, float uy, float vx, float vy) {
        const float a = std::atan2(ux * vy - uy * vx, ux * vx + uy * vy);
        return a;
    };
    const float theta1 = angle(1, 0, (x1 - cxp) / rx, (y1 - cyp) / ry);
    float delta = angle((x1 - cxp) / rx, (y1 - cyp) / ry, (-x1 - cxp) / rx, (-y1 - cyp) / ry);
    if (!sweep && delta > 0) delta -= 2 * kPi;
    if (sweep && delta < 0) delta += 2 * kPi;
    const int n = std::clamp(int(std::ceil(std::fabs(delta) * std::max(rx, ry) / 2.0f)), 8, 256);
    for (int k = 1; k <= n; ++k) {
        const float t = theta1 + delta * float(k) / float(n);
        const float ex = rx * std::cos(t), ey = ry * std::sin(t);
        out.push_back({cp * ex - sp * ey + cx, sp * ex + cp * ey + cy});
    }
    out.back() = to;
}

}  // namespace

bool parse_svg_path(const std::string& d, std::vector<Polyline>& out, std::string& err) {
    Scanner sc(d);
    Vec2 cur{0, 0}, start{0, 0}, lastCtrl{0, 0};
    char cmd = 0, prev = 0;
    bool haveStart = false;
    std::vector<Vec2> pts;
    auto flush = [&] {
        if (pts.size() >= 2) out.push_back({pts});
        pts.clear();
    };
    auto bad = [&](const std::string& what) {
        err = std::format("{} at character {} of the path data", what, sc.i);
        return false;
    };
    while (!sc.at_end()) {
        const char c = d[sc.i];
        const bool isLetter = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
        if (isLetter) {
            if (std::string("MmLlHhVvCcSsQqTtAaZz").find(c) == std::string::npos) return bad(std::format("unknown path command '{}'", c));
            cmd = c;
            ++sc.i;
        } else if (cmd == 0) {
            return bad("the path data must start with M (move to)");
        } else if (cmd == 'M') {
            cmd = 'L';
        } else if (cmd == 'm') {
            cmd = 'l';
        } else if (cmd == 'Z' || cmd == 'z') {
            return bad("numbers after Z");
        }
        const bool rel = cmd >= 'a';
        const char up = char(rel ? cmd - 32 : cmd);
        if (!haveStart && up != 'M') return bad("the path data must start with M (move to)");
        float v[7];
        auto read = [&](int n) {
            for (int k = 0; k < n; ++k)
                if (!sc.number(v[k])) return false;
            return true;
        };
        const Vec2 base = rel ? cur : Vec2{0, 0};
        switch (up) {
            case 'M':
                if (!read(2)) return bad("expected two numbers after M");
                flush();
                cur = start = {base.x + v[0], base.y + v[1]};
                pts.push_back(cur);
                haveStart = true;
                break;
            case 'L':
                if (!read(2)) return bad("expected two numbers after L");
                cur = {base.x + v[0], base.y + v[1]};
                pts.push_back(cur);
                break;
            case 'H':
                if (!read(1)) return bad("expected a number after H");
                cur.x = base.x + v[0];
                pts.push_back(cur);
                break;
            case 'V':
                if (!read(1)) return bad("expected a number after V");
                cur.y = (rel ? cur.y : 0.0f) + v[0];
                pts.push_back(cur);
                break;
            case 'C': {
                if (!read(6)) return bad("expected six numbers after C");
                const Vec2 p1{base.x + v[0], base.y + v[1]}, p2{base.x + v[2], base.y + v[3]}, p3{base.x + v[4], base.y + v[5]};
                flatten_cubic(cur, p1, p2, p3, pts);
                lastCtrl = p2;
                cur = p3;
                break;
            }
            case 'S': {
                if (!read(4)) return bad("expected four numbers after S");
                const Vec2 p1 = (prev == 'C' || prev == 'S') ? cur * 2.0f - lastCtrl : cur;
                const Vec2 p2{base.x + v[0], base.y + v[1]}, p3{base.x + v[2], base.y + v[3]};
                flatten_cubic(cur, p1, p2, p3, pts);
                lastCtrl = p2;
                cur = p3;
                break;
            }
            case 'Q': {
                if (!read(4)) return bad("expected four numbers after Q");
                const Vec2 p1{base.x + v[0], base.y + v[1]}, p2{base.x + v[2], base.y + v[3]};
                flatten_quad(cur, p1, p2, pts);
                lastCtrl = p1;
                cur = p2;
                break;
            }
            case 'T': {
                if (!read(2)) return bad("expected two numbers after T");
                const Vec2 p1 = (prev == 'Q' || prev == 'T') ? cur * 2.0f - lastCtrl : cur;
                const Vec2 p2{base.x + v[0], base.y + v[1]};
                flatten_quad(cur, p1, p2, pts);
                lastCtrl = p1;
                cur = p2;
                break;
            }
            case 'A': {
                if (!read(3) || !sc.flag(v[3]) || !sc.flag(v[4]) || !read(2)) return bad("expected rx ry rotation large-arc sweep x y after A");
                const Vec2 to{base.x + v[5], base.y + v[6]};
                flatten_arc(cur, v[0], v[1], v[2], v[3] != 0.0f, v[4] != 0.0f, to, pts);
                cur = to;
                break;
            }
            case 'Z':
                if (!pts.empty()) {
                    flush();
                    cur = start;
                    pts.push_back(cur);  // a path may go on drawing from the start point
                }
                break;
        }
        prev = up;
    }
    flush();
    if (out.empty()) {
        err = "the path data draws nothing";
        return false;
    }
    return true;
}

Polyline ellipse_polyline(float x, float y, float width, float height) {
    const float rx = width * 0.5f, ry = height * 0.5f, cx = x + rx, cy = y + ry;
    const int n = std::clamp(int(std::ceil(kPi * std::max(rx, ry))), 32, 512);
    Polyline p;
    for (int k = 0; k < n; ++k) {
        const float t = 2.0f * kPi * float(k) / float(n);
        p.pts.push_back({cx + rx * std::cos(t), cy + ry * std::sin(t)});
    }
    return p;
}

Plane fill_shapes(const std::vector<Polyline>& shapes, int w, int h, int ox, int oy) {
    Plane plane(w, h, ox, oy, 0.0f);
    struct Crossing {
        float x;
        int dir;
    };
    std::vector<Crossing> cross;
    for (int row = 0; row < h; ++row) {
        float* line = &plane.v[std::size_t(row) * w];
        for (int sub = 0; sub < kSub; ++sub) {
            const float ys = float(oy + row) + (float(sub) + 0.5f) / float(kSub);
            cross.clear();
            for (const Polyline& poly : shapes) {
                const std::size_t n = poly.pts.size();
                for (std::size_t k = 0; k < n; ++k) {
                    const Vec2 a = poly.pts[k], b = poly.pts[(k + 1) % n];
                    if (a.y == b.y) continue;
                    const bool down = b.y > a.y;
                    const float lo = down ? a.y : b.y, hi = down ? b.y : a.y;
                    if (ys < lo || ys >= hi) continue;
                    cross.push_back({a.x + (ys - a.y) * (b.x - a.x) / (b.y - a.y), down ? 1 : -1});
                }
            }
            if (cross.size() < 2) continue;
            std::sort(cross.begin(), cross.end(), [](const Crossing& p, const Crossing& q) { return p.x < q.x; });
            int winding = 0;
            for (std::size_t k = 0; k + 1 < cross.size(); ++k) {
                winding += cross[k].dir;
                if (winding == 0) continue;
                const float xa = std::max(cross[k].x - float(ox), 0.0f), xb = std::min(cross[k + 1].x - float(ox), float(w));
                if (xb <= xa) continue;
                const int ia = int(std::floor(xa)), ib = std::min(int(std::floor(xb)), w - 1);
                const float weight = 1.0f / float(kSub);
                if (ia == ib) {
                    line[ia] += (xb - xa) * weight;
                } else {
                    line[ia] += (float(ia + 1) - xa) * weight;
                    for (int px = ia + 1; px < ib; ++px) line[px] += weight;
                    if (ib < w) line[ib] += (xb - float(ib)) * weight;
                }
            }
        }
        for (int px = 0; px < w; ++px) line[px] = std::min(line[px], 1.0f);
    }
    return plane;
}

void blur_plane(Plane& plane, float sigma) {
    if (sigma <= 0.0f || plane.w <= 0 || plane.h <= 0) return;
    const int radius = std::max(1, int(std::ceil(sigma * 3.0f)));
    std::vector<float> kernel(std::size_t(radius) * 2 + 1);
    float sum = 0;
    for (int k = -radius; k <= radius; ++k) {
        kernel[std::size_t(k + radius)] = std::exp(-float(k * k) / (2.0f * sigma * sigma));
        sum += kernel[std::size_t(k + radius)];
    }
    for (float& k : kernel) k /= sum;
    std::vector<float> tmp(plane.v.size(), 0.0f);
    for (int y = 0; y < plane.h; ++y)
        for (int x = 0; x < plane.w; ++x) {
            float acc = 0;
            for (int k = -radius; k <= radius; ++k) {
                const int sx = x + k;
                if (sx >= 0 && sx < plane.w) acc += plane.at(sx, y) * kernel[std::size_t(k + radius)];
            }
            tmp[std::size_t(y) * plane.w + x] = acc;
        }
    for (int y = 0; y < plane.h; ++y)
        for (int x = 0; x < plane.w; ++x) {
            float acc = 0;
            for (int k = -radius; k <= radius; ++k) {
                const int sy = y + k;
                if (sy >= 0 && sy < plane.h) acc += tmp[std::size_t(sy) * plane.w + x] * kernel[std::size_t(k + radius)];
            }
            plane.at(x, y) = acc;
        }
}

}  // namespace fa::imgdoc
