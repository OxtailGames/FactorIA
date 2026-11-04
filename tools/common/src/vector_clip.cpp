// Polygon operations of the vector.* commands on Clipper2 (external/clipper2), and the stroker. See vector.h.
#include <algorithm>
#include <cmath>
#include <exception>

#include "clipper2/clipper.h"
#include "fa/core/command.h"
#include "vector.h"

namespace fa::vec {

namespace {

constexpr double kPi = 3.14159265358979323846;

double grid_scale(const ClipGrid& g) { return std::pow(10.0, std::clamp(g.decimals, 0, 8)); }

Clipper2Lib::Paths64 to_clip(const std::vector<Poly>& rings, double scale) {
    Clipper2Lib::Paths64 out;
    out.reserve(rings.size());
    for (const Poly& r : rings) {
        Clipper2Lib::Path64 p;
        p.reserve(r.size());
        for (const P& q : r) {
            if (!(std::fabs(q.x) * scale < 1e15) || !(std::fabs(q.y) * scale < 1e15))
                throw CommandError("invalid_argument", "A coordinate (" + std::to_string(q.x) + ", " + std::to_string(q.y) + ") is too large for the polygon operations.",
                                   "Keep the drawing within about a million units of the origin, or scale it down.");
            p.push_back({std::llround(q.x * scale), std::llround(q.y * scale)});
        }
        if (p.size() >= 3) out.push_back(std::move(p));
    }
    return out;
}

std::vector<Poly> from_clip(const Clipper2Lib::Paths64& paths, double scale) {
    std::vector<Poly> out;
    out.reserve(paths.size());
    for (const auto& p : paths) {
        if (p.size() < 3) continue;
        Poly r;
        r.reserve(p.size());
        for (const auto& q : p) r.push_back({double(q.x) / scale, double(q.y) / scale});
        out.push_back(std::move(r));
    }
    return out;
}

[[noreturn]] void clip_failed(const std::exception& e) {
    throw CommandError("failed", std::string("The polygon operation failed: ") + e.what(),
                       "The shapes may have coordinates that are too large or not numbers. Check the SVG for huge or NaN values.");
}

Clipper2Lib::FillRule fill_rule(bool evenOdd) { return evenOdd ? Clipper2Lib::FillRule::EvenOdd : Clipper2Lib::FillRule::NonZero; }

// One Clipper2 operation. Collinear points are not preserved: with them on, the result keeps zero-width spikes where pieces meet.
Clipper2Lib::Paths64 run_clip(Clipper2Lib::ClipType type, Clipper2Lib::FillRule rule, const Clipper2Lib::Paths64& subject, const Clipper2Lib::Paths64& clip = {}) {
    Clipper2Lib::Paths64 out;
    Clipper2Lib::Clipper64 c;
    c.PreserveCollinear(false);
    c.AddSubject(subject);
    if (!clip.empty()) c.AddClip(clip);
    c.Execute(type, rule, out);
    return out;
}

}  // namespace

std::vector<Poly> normalize(const std::vector<Poly>& rings, bool evenOdd, const ClipGrid& g) {
    const double s = grid_scale(g);
    try {
        return from_clip(Clipper2Lib::SimplifyPaths(run_clip(Clipper2Lib::ClipType::Union, fill_rule(evenOdd), to_clip(rings, s)), 1.0), s);
    } catch (const CommandError&) {
        throw;
    } catch (const std::exception& e) {
        clip_failed(e);
    }
}

std::vector<Poly> union_pieces(const std::vector<Poly>& pieces, const ClipGrid& g) {
    const double s = grid_scale(g);
    try {
        Clipper2Lib::Paths64 paths = to_clip(pieces, s);
        Clipper2Lib::Paths64 oriented;
        oriented.reserve(paths.size());
        for (auto& p : paths) {
            const double area = Clipper2Lib::Area(p);
            if (area == 0) continue;
            if (area < 0) std::reverse(p.begin(), p.end());
            oriented.push_back(std::move(p));
        }
        return from_clip(run_clip(Clipper2Lib::ClipType::Union, Clipper2Lib::FillRule::NonZero, oriented), s);
    } catch (const CommandError&) {
        throw;
    } catch (const std::exception& e) {
        clip_failed(e);
    }
}

std::vector<Poly> boolean_op(BoolOp op, const std::vector<Poly>& subject, const std::vector<Poly>& clip, const ClipGrid& g) {
    const double s = grid_scale(g);
    try {
        const auto a = to_clip(subject, s), b = to_clip(clip, s);
        Clipper2Lib::Paths64 r;
        switch (op) {
            case BoolOp::Union: r = run_clip(Clipper2Lib::ClipType::Union, Clipper2Lib::FillRule::NonZero, a, b); break;
            case BoolOp::Subtract: r = run_clip(Clipper2Lib::ClipType::Difference, Clipper2Lib::FillRule::NonZero, a, b); break;
            case BoolOp::Intersect: r = run_clip(Clipper2Lib::ClipType::Intersection, Clipper2Lib::FillRule::NonZero, a, b); break;
            case BoolOp::Xor: r = run_clip(Clipper2Lib::ClipType::Xor, Clipper2Lib::FillRule::NonZero, a, b); break;
        }
        return from_clip(Clipper2Lib::SimplifyPaths(r, 1.0), s);
    } catch (const CommandError&) {
        throw;
    } catch (const std::exception& e) {
        clip_failed(e);
    }
}

std::vector<Poly> offset_rings(const std::vector<Poly>& rings, double delta, Join join, double miterLimit, double arcTol, const ClipGrid& g) {
    if (delta == 0) return rings;
    const double s = grid_scale(g);
    try {
        Clipper2Lib::ClipperOffset co(std::max(miterLimit, 1.0), arcTol > 0 ? arcTol * s : 0.0);
        Clipper2Lib::JoinType jt = Clipper2Lib::JoinType::Round;
        switch (join) {
            case Join::Round: jt = Clipper2Lib::JoinType::Round; break;
            case Join::Miter: jt = Clipper2Lib::JoinType::Miter; break;
            case Join::Bevel: jt = Clipper2Lib::JoinType::Bevel; break;
            case Join::Square: jt = Clipper2Lib::JoinType::Square; break;
        }
        co.AddPaths(to_clip(rings, s), jt, Clipper2Lib::EndType::Polygon);
        Clipper2Lib::Paths64 solution;
        co.Execute(delta * s, solution);
        return from_clip(solution, s);
    } catch (const CommandError&) {
        throw;
    } catch (const std::exception& e) {
        clip_failed(e);
    }
}

// ---- the stroker -----------------------------------------------------------------------------------------------------

namespace {

struct Stroker {
    double hw;       // half the stroke width
    double arcStep;  // radians between the points of a round join or cap
    std::vector<Poly> pieces;

    void add(Poly p) {
        // every piece positive (counter-clockwise in the maths sense) so the non-zero union adds them up
        double area = 0;
        for (std::size_t i = 0; i < p.size(); ++i) area += cross(p[i], p[(i + 1) % p.size()]);
        if (area < 0) std::reverse(p.begin(), p.end());
        if (std::fabs(area) > 1e-18) pieces.push_back(std::move(p));
    }

    static P right(P d) { return {d.y, -d.x}; }

    // The points strictly between the ends of the arc around `c` from the direction `from` to `to` (unit vectors): the shorter way,
    // or the half circle counter-clockwise from `from` when `half`.
    void arc(P c, P from, P to, std::vector<P>& out, bool half) const {
        const double a0 = std::atan2(from.y, from.x);
        double sweep = std::atan2(cross(from, to), dot(from, to));
        if (half) sweep = kPi;
        const int n = std::max(1, int(std::ceil(std::fabs(sweep) / arcStep)));
        for (int k = 1; k < n; ++k) {
            const double a = a0 + sweep * k / n;
            out.push_back(c + P{std::cos(a), std::sin(a)} * hw);
        }
    }

    void segment(P a, P b) {
        const P d = unit(b - a);
        if (len(d) < 0.5) return;
        const P n = right(d) * hw;
        add({a + n, b + n, b - n, a - n});
    }

    void join(P v, P d0, P d1, Join j, double miterLimit) {
        const double cr = cross(d0, d1), dt = dot(d0, d1);
        if (std::fabs(cr) < 1e-9 && dt > 0) return;  // straight on
        const double sgn = cr < -1e-9 ? -1.0 : 1.0;   // the outer side is the right one when turning left (a reversal: the right one too)
        const P a = v + right(d0) * (hw * sgn), b = v + right(d1) * (hw * sgn);
        // The wedge's sides lie on the end edges of the two segments' rectangles; rounded to the integer grid of the union they leave
        // cracks. Pulling the apex back into the body (it stays inside the disc around `v`, which the stroke covers) makes them overlap.
        P back = unit((a - v) + (b - v)) * -1.0;
        if (len(back) < 0.5) back = d0 * -1.0;
        const P apex = v + back * (hw * 0.5);
        // A turn no larger than one arc step (the vertices of a flattened curve) joins with the miter tip whatever the join: it is within
        // the flattening tolerance of the round one, and a bevel's two points would leave a step the size of the turn.
        const double turn = std::fabs(std::atan2(cr, dt));
        if (turn <= arcStep && std::fabs(cr) >= 1e-9) {
            const P tip = v + ((a - v) + (b - v)) * (1.0 / (1.0 + dt));
            add({apex, a, tip, b});
            return;
        }
        if (j == Join::Round) {
            Poly p{apex, a};
            arc(v, unit(a - v), unit(b - v), p, std::fabs(cr) < 1e-9);
            p.push_back(b);
            add(std::move(p));
            return;
        }
        if (j == Join::Miter && std::fabs(cr) >= 1e-9) {
            // the ratio miter length / width is 1 / sin(half the angle between the segments) = 1 / cos(half the turn)
            const double cosHalf = std::sqrt(std::max(0.0, (1 + dt) * 0.5));
            if (cosHalf > 1e-9 && 1.0 / cosHalf <= miterLimit) {
                const P tip = v + ((a - v) + (b - v)) * (1.0 / (1.0 + dt));
                add({apex, a, tip, b});
                return;
            }
        }
        add({apex, a, b});
    }

    void cap(P at, P outward, Cap c) {
        if (c == Cap::Butt) return;
        const P n = right(outward) * hw;
        if (c == Cap::Square) {
            add({at + n, at + n + outward * hw, at - n + outward * hw, at - n});
            return;
        }
        Poly p{at + n};
        arc(at, unit(n), unit(n * -1.0), p, true);
        p.push_back(at - n);
        add(std::move(p));
    }

    void dot_shape(P at, Cap c) {
        if (c == Cap::Round) {
            Poly p;
            const int n = std::max(8, int(std::ceil(2 * kPi / arcStep)));
            for (int k = 0; k < n; ++k) p.push_back(at + P{std::cos(2 * kPi * k / n), std::sin(2 * kPi * k / n)} * hw);
            add(std::move(p));
        } else if (c == Cap::Square) {
            add({at + P{-hw, -hw}, at + P{hw, -hw}, at + P{hw, hw}, at + P{-hw, hw}});
        }
    }

    void polyline(const Poly& pts, bool closed, const StrokeStyle& st) {
        Poly q;
        for (const P& p : pts)
            if (q.empty() || dist(q.back(), p) > 1e-9) q.push_back(p);
        while (closed && q.size() > 1 && dist(q.front(), q.back()) <= 1e-9) q.pop_back();
        if (q.size() == 1) {
            dot_shape(q[0], st.cap);
            return;
        }
        if (q.size() < 2) return;
        const std::size_t n = q.size(), edges = closed ? n : n - 1;
        for (std::size_t i = 0; i < edges; ++i) segment(q[i], q[(i + 1) % n]);
        const std::size_t firstJoin = closed ? 0 : 1, endJoin = closed ? n : n - 1;
        for (std::size_t i = firstJoin; i < endJoin; ++i) join(q[i], unit(q[i] - q[(i + n - 1) % n]), unit(q[(i + 1) % n] - q[i]), st.join, st.miterLimit);
        if (!closed) {
            cap(q[0], unit(q[0] - q[1]), st.cap);
            cap(q[n - 1], unit(q[n - 1] - q[n - 2]), st.cap);
        }
    }
};

// The dash pattern applied to one polyline: open pieces. A closed ring whose first and last pieces are both "on" has them joined.
std::vector<Poly> dash_polyline(const Poly& pts, bool closed, const std::vector<double>& pattern, double offset) {
    Poly q = pts;
    if (closed && q.size() > 1) q.push_back(q[0]);
    double total = 0;
    for (double d : pattern) total += d;
    std::vector<Poly> pieces;
    if (!(total > 0) || q.size() < 2) return {pts};
    // where in the pattern we start
    double off = std::fmod(offset, total);
    if (off < 0) off += total;
    std::size_t idx = 0;
    while (off >= pattern[idx]) {
        off -= pattern[idx];
        idx = (idx + 1) % pattern.size();
    }
    double remain = pattern[idx] - off;
    bool on = idx % 2 == 0;
    Poly cur;
    if (on) cur.push_back(q[0]);
    const bool startedOn = on;
    for (std::size_t i = 0; i + 1 < q.size(); ++i) {
        P a = q[i];
        const P b = q[i + 1];
        double segLen = dist(a, b);
        const P d = unit(b - a);
        while (segLen > remain + 1e-12) {
            a = a + d * remain;
            segLen -= remain;
            if (on) {
                cur.push_back(a);
                pieces.push_back(std::move(cur));
                cur.clear();
            } else {
                cur.push_back(a);
            }
            on = !on;
            idx = (idx + 1) % pattern.size();
            remain = pattern[idx];
            if (remain <= 0) remain = 1e-9;
        }
        remain -= segLen;
        if (on) cur.push_back(b);
    }
    if (on && cur.size() >= 1) {
        if (closed && startedOn && !pieces.empty()) {
            // the last piece runs into the first: one dash across the start
            Poly& first = pieces.front();
            cur.insert(cur.end(), first.begin() + (first.empty() ? 0 : 1), first.end());
            first = std::move(cur);
        } else {
            pieces.push_back(std::move(cur));
        }
    }
    return pieces;
}

}  // namespace

std::vector<Poly> stroke_outline(const Path& p, const StrokeStyle& style, double flatTol, const ClipGrid& g) {
    Stroker st;
    st.hw = style.width * 0.5;
    if (!(st.hw > 0)) return {};
    st.arcStep = st.hw <= flatTol ? kPi / 3 : std::clamp(2 * std::acos(std::clamp(1 - flatTol / st.hw, -1.0, 1.0)), 0.05, kPi / 3);
    std::vector<double> pattern = style.dashes;
    bool anyDash = false;
    for (double d : pattern) anyDash = anyDash || d > 0;
    if (pattern.size() % 2 == 1) pattern.insert(pattern.end(), style.dashes.begin(), style.dashes.end());
    for (const Ring& r : flatten_path(p, flatTol)) {
        if (!anyDash) {
            st.polyline(r.pts, r.closed, style);
            continue;
        }
        const std::vector<Poly> pieces = dash_polyline(r.pts, r.closed, pattern, style.dashOffset);
        // a ring that is not cut stays closed
        if (pieces.size() == 1 && r.closed && pieces[0].size() >= r.pts.size() && dist(pieces[0].front(), r.pts.front()) < 1e-9 && dist(pieces[0].back(), r.pts.front()) < 1e-9)
            st.polyline(r.pts, true, style);
        else
            for (const Poly& piece : pieces) st.polyline(piece, false, style);
    }
    return union_pieces(st.pieces, g);
}

}  // namespace fa::vec
