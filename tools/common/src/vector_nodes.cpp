// Nodes of a path with their handles and the editing operations on them (fa/tooling/vector_edit.h): the code of vector.nodes, shared
// with the editor's Vector panel so a drag on screen and a command make the same path.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"
#include "fa/tooling/vector_edit.h"
#include "vector.h"

namespace fa {

namespace {

using vec::P;

constexpr double kEps = 1e-9;

P pt(const VecPoint& p) { return {p.x, p.y}; }
VecPoint vp(P p) { return {p.x, p.y}; }
VecPoint operator+(VecPoint a, VecPoint b) { return {a.x + b.x, a.y + b.y}; }
VecPoint operator-(VecPoint a, VecPoint b) { return {a.x - b.x, a.y - b.y}; }
VecPoint operator*(VecPoint a, double k) { return {a.x * k, a.y * k}; }
double length(VecPoint a) { return std::sqrt(a.x * a.x + a.y * a.y); }
double distance(VecPoint a, VecPoint b) { return length(a - b); }
VecPoint lerp(VecPoint a, VecPoint b, double t) { return {a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t}; }
VecPoint unit(VecPoint a) {
    const double l = length(a);
    return l < kEps ? VecPoint{0, 0} : VecPoint{a.x / l, a.y / l};
}

Error err(const std::string& message, const std::string& hint = {}) { return Error{message, hint}; }

Result<VecSubpath*> sub_at(VecNodePath& path, int subpath) {
    if (subpath < 0 || subpath >= int(path.size()))
        return err(std::format("subpath {} does not exist: the path has {} subpath(s).", subpath, path.size()),
                   path.empty() ? "The path has no subpath." : std::format("Use 0 to {}.", path.size() - 1));
    return &path[std::size_t(subpath)];
}

Result<VecNode*> node_at(VecNodePath& path, int subpath, int node) {
    auto s = sub_at(path, subpath);
    if (!s.ok()) return s.error();
    VecSubpath& sp = **s;
    if (node < 0 || node >= int(sp.nodes.size()))
        return err(
            std::format("node {} does not exist in subpath {}: it has {} node(s).", node, subpath, sp.nodes.size()),
            sp.nodes.empty() ? "" : std::format("Use 0 to {}.", sp.nodes.size() - 1));
    return &sp.nodes[std::size_t(node)];
}

// The control points of segment i (from node i to node i+1, wrapping), with the end points.
struct Cubic {
    VecPoint p0, c1, c2, p3;
};
Cubic cubic_of(const VecSubpath& sp, int i) {
    const VecNode& a = sp.nodes[std::size_t(i)];
    const VecNode& b = sp.nodes[std::size_t((i + 1) % int(sp.nodes.size()))];
    return {a.p, a.hasOut ? a.out : a.p, b.hasIn ? b.in : b.p, b.p};
}
VecPoint cubic_at(const Cubic& c, double t) {
    const double u = 1 - t;
    return c.p0 * (u * u * u) + c.c1 * (3 * u * u * t) + c.c2 * (3 * u * t * t) + c.p3 * (t * t * t);
}

}  // namespace

const char* vector_node_kind_name(VecNodeKind kind) {
    switch (kind) {
        case VecNodeKind::Corner: return "corner";
        case VecNodeKind::Smooth: return "smooth";
        case VecNodeKind::Symmetric: return "symmetric";
    }
    return "corner";
}

const char* vector_handle_link_name(VecHandleLink link) {
    switch (link) {
        case VecHandleLink::Auto: return "auto";
        case VecHandleLink::None: return "none";
        case VecHandleLink::Angle: return "angle";
        case VecHandleLink::Mirror: return "mirror";
    }
    return "auto";
}

// ---- path data <-> nodes ------------------------------------------------------------------------------------------------------

VecNodePath nodes_from_path(const vec::Path& path) {
    VecNodePath out;
    for (const vec::SubPath& s : path) {
        VecSubpath sp;
        sp.closed = s.closed;
        VecNode first;
        first.p = vp(s.start);
        sp.nodes.push_back(first);
        for (const vec::Seg& g : s.segs) {
            VecNode& prev = sp.nodes.back();
            if (g.cubic) {
                if (vec::dist(g.c1, pt(prev.p)) > kEps) {
                    prev.hasOut = true;
                    prev.out = vp(g.c1);
                }
            }
            VecNode n;
            n.p = vp(g.p);
            if (g.cubic && vec::dist(g.c2, g.p) > kEps) {
                n.hasIn = true;
                n.in = vp(g.c2);
            }
            sp.nodes.push_back(n);
        }
        // a closed subpath whose last segment ends on the start shares that node with the first
        if (sp.closed && sp.nodes.size() > 1 && distance(sp.nodes.back().p, sp.nodes.front().p) < 1e-7) {
            const VecNode last = sp.nodes.back();
            sp.nodes.pop_back();
            if (last.hasIn) {
                sp.nodes.front().hasIn = true;
                sp.nodes.front().in = last.in;
            }
        }
        out.push_back(std::move(sp));
    }
    return out;
}

Result<VecNodePath> vector_nodes_from_d(const std::string& d) {
    vec::Path path;
    std::string why;
    if (!vec::parse_path_data(d, path, why))
        return err("Path data cannot be read: " + why, "Write it as an SVG path: \"M10 10 L90 10 L50 80 Z\".");
    return nodes_from_path(path);
}

vec::Path path_from_nodes(const VecNodePath& path) {
    vec::Path out;
    for (const VecSubpath& sp : path) {
        if (sp.nodes.empty()) continue;
        vec::SubPath s;
        s.start = pt(sp.nodes[0].p);
        s.closed = sp.closed;
        const int segs = vector_segment_count(sp);
        for (int i = 0; i < segs; ++i) {
            const Cubic c = cubic_of(sp, i);
            vec::Seg g;
            g.p = pt(c.p3);
            if (vector_segment_is_curve(sp, i)) {
                g.cubic = true;
                g.c1 = pt(c.c1);
                g.c2 = pt(c.c2);
            } else if (sp.closed && i == segs - 1) {
                break;  // the straight segment back to the start is the Z
            }
            s.segs.push_back(g);
        }
        out.push_back(std::move(s));
    }
    return out;
}

std::string vector_nodes_to_d(const VecNodePath& path, int decimals) {
    return vec::path_to_data(path_from_nodes(path), decimals);
}

VecNodeKind vector_node_kind(const VecNode& n) {
    if (!n.hasIn || !n.hasOut) return VecNodeKind::Corner;
    const VecPoint a = n.in - n.p, b = n.out - n.p;
    const double la = length(a), lb = length(b);
    if (la < 1e-6 || lb < 1e-6) return VecNodeKind::Corner;
    const double cross = (a.x * b.y - a.y * b.x) / (la * lb);
    const double dot = (a.x * b.x + a.y * b.y) / (la * lb);
    if (std::fabs(cross) > 0.0175 || dot > 0) return VecNodeKind::Corner;
    return std::fabs(la - lb) <= 0.01 * std::max(la, lb) ? VecNodeKind::Symmetric : VecNodeKind::Smooth;
}

int vector_node_count(const VecNodePath& path) {
    int n = 0;
    for (const VecSubpath& s : path) n += int(s.nodes.size());
    return n;
}

int vector_segment_count(const VecSubpath& sp) {
    const int n = int(sp.nodes.size());
    if (n < 2) return 0;
    return sp.closed ? n : n - 1;
}

bool vector_segment_is_curve(const VecSubpath& sp, int i) {
    if (i < 0 || i >= vector_segment_count(sp)) return false;
    const VecNode& a = sp.nodes[std::size_t(i)];
    const VecNode& b = sp.nodes[std::size_t((i + 1) % int(sp.nodes.size()))];
    return a.hasOut || b.hasIn;
}

VecPoint vector_segment_point(const VecSubpath& sp, int i, double t) {
    if (i < 0 || i >= vector_segment_count(sp)) return sp.nodes.empty() ? VecPoint{} : sp.nodes[0].p;
    return cubic_at(cubic_of(sp, i), t);
}

VecNearest vector_nearest_on_path(const VecNodePath& path, VecPoint p) {
    VecNearest best;
    for (int si = 0; si < int(path.size()); ++si) {
        const VecSubpath& sp = path[std::size_t(si)];
        const int segs = vector_segment_count(sp);
        for (int i = 0; i < segs; ++i) {
            const Cubic c = cubic_of(sp, i);
            const bool curve = vector_segment_is_curve(sp, i);
            double bt = 0, bd = 1e300;
            const int steps = curve ? 32 : 1;
            for (int k = 0; k <= steps; ++k) {
                const double t = double(k) / steps;
                const double d = distance(cubic_at(c, t), p);
                if (d < bd) {
                    bd = d;
                    bt = t;
                }
            }
            if (curve) {  // refine by shrinking the bracket around the best sample
                double lo = std::max(0.0, bt - 1.0 / steps), hi = std::min(1.0, bt + 1.0 / steps);
                for (int it = 0; it < 24; ++it) {
                    const double m1 = lo + (hi - lo) / 3, m2 = hi - (hi - lo) / 3;
                    if (distance(cubic_at(c, m1), p) < distance(cubic_at(c, m2), p))
                        hi = m2;
                    else
                        lo = m1;
                }
                bt = (lo + hi) * 0.5;
                bd = distance(cubic_at(c, bt), p);
            } else {  // exact projection on a line
                const VecPoint d = c.p3 - c.p0;
                const double l2 = d.x * d.x + d.y * d.y;
                if (l2 > kEps) {
                    bt = std::clamp(((p.x - c.p0.x) * d.x + (p.y - c.p0.y) * d.y) / l2, 0.0, 1.0);
                    bd = distance(cubic_at(c, bt), p);
                }
            }
            if (bd < best.distance) {
                best.distance = bd;
                best.subpath = si;
                best.segment = i;
                best.t = bt;
                best.point = cubic_at(c, bt);
            }
        }
    }
    return best;
}

// ---- operations ------------------------------------------------------------------------------------------------------------

Result<void> vector_node_move(VecNodePath& path, int subpath, int node, VecPoint to, bool handlesFollow) {
    auto n = node_at(path, subpath, node);
    if (!n.ok()) return n.error();
    VecNode& v = **n;
    const VecPoint delta = to - v.p;
    v.p = to;
    if (handlesFollow) {
        v.in = v.in + delta;
        v.out = v.out + delta;
    }
    return {};
}

Result<void> vector_handle_move(VecNodePath& path, int subpath, int node, bool out, VecPoint to, VecHandleLink link) {
    auto n = node_at(path, subpath, node);
    if (!n.ok()) return n.error();
    VecNode& v = **n;
    if (link == VecHandleLink::Auto) {
        switch (vector_node_kind(v)) {
            case VecNodeKind::Symmetric: link = VecHandleLink::Mirror; break;
            case VecNodeKind::Smooth: link = VecHandleLink::Angle; break;
            case VecNodeKind::Corner: link = VecHandleLink::None; break;
        }
    }
    // the length of the other handle before the move: kept by Angle
    const bool otherHas = out ? v.hasIn : v.hasOut;
    const VecPoint other = out ? v.in : v.out;
    const double otherLen = otherHas ? distance(other, v.p) : 0;
    const bool away = distance(to, v.p) < kEps;
    if (out) {
        v.hasOut = !away;
        v.out = to;
    } else {
        v.hasIn = !away;
        v.in = to;
    }
    if (away || link == VecHandleLink::None || !otherHas) return {};
    const VecPoint dir = unit(v.p - to);
    const double len = link == VecHandleLink::Mirror ? distance(to, v.p) : otherLen;
    if (out)
        v.in = v.p + dir * len;
    else
        v.out = v.p + dir * len;
    return {};
}

Result<int> vector_node_insert(VecNodePath& path, int subpath, int segment, double t) {
    auto s = sub_at(path, subpath);
    if (!s.ok()) return s.error();
    VecSubpath& sp = **s;
    if (segment < 0 || segment >= vector_segment_count(sp))
        return err(std::format("segment {} does not exist in subpath {}: it has {} segment(s).", segment, subpath,
                               vector_segment_count(sp)),
                   "A segment is the piece between node i and node i+1; a closed subpath also has one from the last "
                   "node back to the first.");
    if (!(t > 0 && t < 1))
        return err(std::format("`t` must be between 0 and 1 (exclusive), got {}.", t),
                   "0.5 splits the segment in the middle.");
    const Cubic c = cubic_of(sp, segment);
    const bool curve = vector_segment_is_curve(sp, segment);
    VecNode mid;
    const int next = (segment + 1) % int(sp.nodes.size());
    if (!curve) {
        mid.p = lerp(c.p0, c.p3, t);
    } else {
        const VecPoint a = lerp(c.p0, c.c1, t), b = lerp(c.c1, c.c2, t), cc = lerp(c.c2, c.p3, t);
        const VecPoint d = lerp(a, b, t), e = lerp(b, cc, t);
        mid.p = lerp(d, e, t);
        mid.in = d;
        mid.out = e;
        mid.hasIn = mid.hasOut = true;
        VecNode& n0 = sp.nodes[std::size_t(segment)];
        VecNode& n1 = sp.nodes[std::size_t(next)];
        if (distance(a, n0.p) > kEps) {
            n0.hasOut = true;
            n0.out = a;
        } else {
            n0.hasOut = false;
        }
        if (distance(cc, n1.p) > kEps) {
            n1.hasIn = true;
            n1.in = cc;
        } else {
            n1.hasIn = false;
        }
        if (distance(d, mid.p) < kEps) mid.hasIn = false;
        if (distance(e, mid.p) < kEps) mid.hasOut = false;
    }
    const int at = segment + 1;
    sp.nodes.insert(sp.nodes.begin() + at, mid);
    return at;
}

Result<void> vector_node_delete(VecNodePath& path, int subpath, int node, bool keepShape) {
    auto s = sub_at(path, subpath);
    if (!s.ok()) return s.error();
    VecSubpath& sp = **s;
    auto n = node_at(path, subpath, node);
    if (!n.ok()) return n.error();
    const int count = int(sp.nodes.size());
    const int remaining = count - 1;
    if (remaining < 2) {
        if (path.size() == 1)
            return err("Deleting this node would leave the path with nothing to draw.",
                       "Delete the element instead (vector.delete).");
        path.erase(path.begin() + subpath);
        return {};
    }
    const bool hasPrev = sp.closed || node > 0, hasNext = sp.closed || node < count - 1;
    if (keepShape && hasPrev && hasNext) {
        VecNode& prev = sp.nodes[std::size_t((node + count - 1) % count)];
        VecNode& next = sp.nodes[std::size_t((node + 1) % count)];
        const VecNode& cur = sp.nodes[std::size_t(node)];
        // two curves become one: the handles grow by how much longer the new segment is than the one they belonged to
        if (prev.hasOut && cur.hasIn && cur.hasOut && next.hasIn) {
            const double a = distance(prev.p, cur.p), b = distance(cur.p, next.p);
            if (a > kEps && b > kEps) {
                prev.out = prev.p + (prev.out - prev.p) * ((a + b) / a);
                next.in = next.p + (next.in - next.p) * ((a + b) / b);
            }
        }
    }
    sp.nodes.erase(sp.nodes.begin() + node);
    return {};
}

Result<void> vector_node_convert(VecNodePath& path, int subpath, int node, VecNodeKind kind) {
    auto s = sub_at(path, subpath);
    if (!s.ok()) return s.error();
    VecSubpath& sp = **s;
    auto nr = node_at(path, subpath, node);
    if (!nr.ok()) return nr.error();
    VecNode& v = **nr;
    if (kind == VecNodeKind::Corner) {
        v.hasIn = v.hasOut = false;
        return {};
    }
    const int count = int(sp.nodes.size());
    const bool hasPrev = sp.closed || node > 0, hasNext = sp.closed || node < count - 1;
    const VecNode* prev = hasPrev ? &sp.nodes[std::size_t((node + count - 1) % count)] : nullptr;
    const VecNode* next = hasNext ? &sp.nodes[std::size_t((node + 1) % count)] : nullptr;
    VecPoint dir;
    if (v.hasIn && v.hasOut) {
        dir = unit(unit(v.out - v.p) + unit(v.p - v.in));
        if (length(dir) < kEps) dir = unit(v.out - v.p);
    } else if (v.hasOut) {
        dir = unit(v.out - v.p);
    } else if (v.hasIn) {
        dir = unit(v.p - v.in);
    } else if (prev && next) {
        dir = unit(next->p - prev->p);
    } else if (next) {
        dir = unit(next->p - v.p);
    } else if (prev) {
        dir = unit(v.p - prev->p);
    }
    if (length(dir) < kEps)
        return err("This node has no neighbour to take a direction from, so it cannot be made smooth.",
                   "Add a second node first.");
    double lin = v.hasIn ? distance(v.in, v.p) : (prev ? distance(prev->p, v.p) / 3 : 0);
    double lout = v.hasOut ? distance(v.out, v.p) : (next ? distance(next->p, v.p) / 3 : 0);
    if (kind == VecNodeKind::Symmetric) {
        const double l = (v.hasIn && v.hasOut) ? (lin + lout) * 0.5
                                               : (v.hasIn    ? lin
                                                  : v.hasOut ? lout
                                                             : std::max(lin, lout));
        lin = lout = l;
    }
    if (lout > kEps && (hasNext || v.hasOut)) {
        v.hasOut = true;
        v.out = v.p + dir * lout;
    }
    if (lin > kEps && (hasPrev || v.hasIn)) {
        v.hasIn = true;
        v.in = v.p - dir * lin;
    }
    return {};
}

Result<void> vector_node_break(VecNodePath& path, int subpath, int node) {
    auto s = sub_at(path, subpath);
    if (!s.ok()) return s.error();
    VecSubpath& sp = **s;
    auto nr = node_at(path, subpath, node);
    if (!nr.ok()) return nr.error();
    const int count = int(sp.nodes.size());
    if (sp.closed) {
        std::vector<VecNode> order;
        for (int i = 0; i < count; ++i) order.push_back(sp.nodes[std::size_t((node + i) % count)]);
        VecNode tail = order.front();
        tail.hasOut = false;
        order.front().hasIn = false;
        order.push_back(tail);
        sp.nodes = std::move(order);
        sp.closed = false;
        return {};
    }
    if (node == 0 || node == count - 1)
        return err(std::format("node {} is an end of an open subpath, so there is nothing to cut.", node),
                   "Break a node in the middle of the path, or of a closed one.");
    VecSubpath second;
    second.nodes.assign(sp.nodes.begin() + node, sp.nodes.end());
    second.nodes.front().hasIn = false;
    sp.nodes.resize(std::size_t(node + 1));
    sp.nodes.back().hasOut = false;
    path.insert(path.begin() + subpath + 1, std::move(second));
    return {};
}

namespace {
void reverse_nodes(VecSubpath& sp) {
    std::reverse(sp.nodes.begin(), sp.nodes.end());
    for (VecNode& n : sp.nodes) {
        std::swap(n.in, n.out);
        std::swap(n.hasIn, n.hasOut);
    }
}
}  // namespace

Result<void> vector_subpath_reverse(VecNodePath& path, int subpath) {
    auto s = sub_at(path, subpath);
    if (!s.ok()) return s.error();
    VecSubpath& sp = **s;
    if (sp.closed && !sp.nodes.empty()) {  // keep the first node first: reverse the rest
        VecNode first = sp.nodes.front();
        reverse_nodes(sp);
        std::rotate(sp.nodes.begin(), sp.nodes.end() - 1, sp.nodes.end());
        (void)first;
    } else {
        reverse_nodes(sp);
    }
    return {};
}

Result<void> vector_subpath_close(VecNodePath& path, int subpath) {
    auto s = sub_at(path, subpath);
    if (!s.ok()) return s.error();
    VecSubpath& sp = **s;
    if (sp.closed) return err(std::format("subpath {} is already closed.", subpath));
    if (sp.nodes.size() < 2)
        return err(std::format("subpath {} has {} node(s); closing needs at least 2.", subpath, sp.nodes.size()),
                   "Add more nodes first.");
    if (distance(sp.nodes.back().p, sp.nodes.front().p) < 1e-7 &&
        sp.nodes.size() > 2) {  // the last node sits on the first: they are one
        const VecNode last = sp.nodes.back();
        sp.nodes.pop_back();
        if (last.hasIn) {
            sp.nodes.front().hasIn = true;
            sp.nodes.front().in = last.in;
        }
    }
    sp.closed = true;
    return {};
}

Result<void> vector_nodes_join(VecNodePath& path, int sa, int na, int sb, int nb, bool merge) {
    auto ra = sub_at(path, sa);
    if (!ra.ok()) return ra.error();
    auto rb = sub_at(path, sb);
    if (!rb.ok()) return rb.error();
    VecSubpath& a = **ra;
    VecSubpath& b = **rb;
    if (a.closed || b.closed)
        return err("A closed subpath has no ends to join.", "Break it at a node first (vector.nodes op \"break\").");
    auto is_end = [](const VecSubpath& s, int n) { return n == 0 || n == int(s.nodes.size()) - 1; };
    if (!is_end(a, na) || !is_end(b, nb))
        return err(std::format("Only the first or last node of a subpath can be joined; got node {} of subpath {} and "
                               "node {} of subpath {}.",
                               na, sa, nb, sb),
                   std::format("Subpath {} ends at nodes 0 and {}, subpath {} at 0 and {}.", sa, a.nodes.size() - 1, sb,
                               b.nodes.size() - 1));
    if (sa == sb) {
        if (na == nb) return err("Joining a node with itself does nothing.", "Pick the two ends of the path.");
        if (a.nodes.size() < 2) return err("The subpath has a single node.");
        if (merge) {
            VecNode& first = a.nodes.front();
            const VecNode last = a.nodes.back();
            const VecPoint mid = lerp(first.p, last.p, 0.5);
            const VecPoint dFirst = mid - first.p, dLast = mid - last.p;
            first.p = mid;
            if (first.hasOut) first.out = first.out + dFirst;
            if (last.hasIn) {
                first.hasIn = true;
                first.in = last.in + dLast;
            }
            a.nodes.pop_back();
        }
        a.closed = true;
        return {};
    }
    if (na == 0 && a.nodes.size() > 1)
        reverse_nodes(a);  // a's joined end last
    else if (na == 0 && a.nodes.size() == 1) {
    }
    if (nb != 0 && b.nodes.size() > 1) reverse_nodes(b);  // b's joined end first
    if (merge) {
        VecNode& end = a.nodes.back();
        const VecNode& start = b.nodes.front();
        const VecPoint mid = lerp(end.p, start.p, 0.5);
        const VecPoint dEnd = mid - end.p, dStart = mid - start.p;
        end.p = mid;
        if (end.hasIn) end.in = end.in + dEnd;
        end.hasOut = start.hasOut;
        end.out = start.out + dStart;
        a.nodes.insert(a.nodes.end(), b.nodes.begin() + 1, b.nodes.end());
    } else {
        a.nodes.insert(a.nodes.end(), b.nodes.begin(), b.nodes.end());
    }
    path.erase(path.begin() + sb);
    return {};
}

Result<void> vector_node_append(VecNodePath& path, int subpath, VecPoint at, const VecPoint* out, bool atEnd) {
    VecNode n;
    n.p = at;
    if (out && distance(*out, at) > kEps) {
        n.hasOut = n.hasIn = true;
        n.out = *out;
        n.in = at * 2 - *out;
    }
    if (subpath == int(path.size())) {
        VecSubpath sp;
        sp.nodes.push_back(n);
        path.push_back(std::move(sp));
        return {};
    }
    auto s = sub_at(path, subpath);
    if (!s.ok()) return s.error();
    VecSubpath& sp = **s;
    if (sp.closed)
        return err(std::format("subpath {} is closed, so it has no end to continue.", subpath),
                   "Break it at a node first, or start a new subpath with subpath = " + std::to_string(path.size()) +
                       ".");
    if (atEnd) {
        sp.nodes.push_back(n);
    } else {
        // at the start the handles swap roles: the drag pulls the OUT handle of the new first node
        sp.nodes.insert(sp.nodes.begin(), n);
    }
    return {};
}

// ---- the ops of vector.nodes -----------------------------------------------------------------------------------------------

namespace {

Error op_error(std::size_t i, const std::string& what, const std::string& hint = {}) {
    return Error{std::format("/ops/{}: {}", i, what), hint};
}

bool read_point(const Json& o, const char* key, VecPoint& p) {
    auto it = o.find(key);
    if (it == o.end() || !it->is_array() || it->size() != 2 || !(*it)[0].is_number() || !(*it)[1].is_number())
        return false;
    p = {(*it)[0].get<double>(), (*it)[1].get<double>()};
    return std::isfinite(p.x) && std::isfinite(p.y);
}

}  // namespace

Result<void> vector_nodes_apply(VecNodePath& path, const Json& ops) {
    static const std::vector<std::string> names = {"move",  "handle", "insert", "delete",  "convert",
                                                   "break", "join",   "close",  "reverse", "append"};
    if (!ops.is_array())
        return Error{"`ops` must be a list of operations.",
                     "Example: [{\"op\": \"move\", \"node\": 2, \"to\": [40, 50]}]."};
    for (std::size_t i = 0; i < ops.size(); ++i) {
        const Json& o = ops[i];
        if (!o.is_object() || !o.contains("op") || !o["op"].is_string())
            return op_error(i, "each operation is an object with an `op`.", "One of: " + join(names, ", ") + ".");
        const std::string op = o["op"].get<std::string>();
        if (std::find(names.begin(), names.end(), op) == names.end())
            return op_error(i, "unknown op '" + op + "'.",
                            did_you_mean(op, names) + " The ops: " + join(names, ", ") + ".");
        const int sp = o.contains("subpath") && o["subpath"].is_number_integer() ? o["subpath"].get<int>() : 0;
        const int node = o.contains("node") && o["node"].is_number_integer() ? o["node"].get<int>() : -1;
        auto need_node = [&]() -> bool { return node >= 0; };
        Result<void> r;
        VecPoint to;
        if (op == "move") {
            if (!need_node()) return op_error(i, "`move` needs `node` (a whole number).");
            VecPoint by;
            if (read_point(o, "to", to))
                r = vector_node_move(path, sp, node, to, o.value("handles", true));
            else if (read_point(o, "by", by)) {
                auto n = node_at(path, sp, node);
                if (!n.ok()) return op_error(i, n.error().message, n.error().hint);
                r = vector_node_move(path, sp, node, (*n)->p + by, o.value("handles", true));
            } else
                return op_error(i, "`move` needs `to` [x, y] or `by` [dx, dy].");
        } else if (op == "handle") {
            if (!need_node()) return op_error(i, "`handle` needs `node` (a whole number).");
            const std::string which = o.value("which", std::string());
            if (which != "in" && which != "out") return op_error(i, "`which` must be \"in\" or \"out\".");
            if (!read_point(o, "to", to)) return op_error(i, "`handle` needs `to` [x, y]: where the handle goes.");
            VecHandleLink link = VecHandleLink::Auto;
            const std::string l = o.value("link", std::string("auto"));
            if (l == "none")
                link = VecHandleLink::None;
            else if (l == "angle")
                link = VecHandleLink::Angle;
            else if (l == "mirror")
                link = VecHandleLink::Mirror;
            else if (l != "auto")
                return op_error(i, "`link` must be auto, none, angle or mirror.",
                                did_you_mean(l, std::vector<std::string>{"auto", "none", "angle", "mirror"}));
            r = vector_handle_move(path, sp, node, which == "out", to, link);
        } else if (op == "insert") {
            int segment = o.contains("segment") && o["segment"].is_number_integer() ? o["segment"].get<int>() : -1;
            double t = o.contains("t") && o["t"].is_number() ? o["t"].get<double>() : 0.5;
            if (read_point(o, "at", to)) {
                const VecNearest nr = vector_nearest_on_path(path, to);
                if (nr.segment < 0) return op_error(i, "the path has no segment to insert a node into.");
                if (o.contains("subpath") && nr.subpath != sp) {
                    VecNodePath only{path[std::size_t(std::clamp(sp, 0, int(path.size()) - 1))]};
                    const VecNearest n2 = vector_nearest_on_path(only, to);
                    segment = n2.segment;
                    t = n2.t;
                } else {
                    const int s2 = nr.subpath;
                    auto res = vector_node_insert(path, s2, nr.segment, std::clamp(nr.t, 1e-4, 1 - 1e-4));
                    if (!res.ok()) return op_error(i, res.error().message, res.error().hint);
                    continue;
                }
            }
            if (segment < 0)
                return op_error(
                    i, "`insert` needs `segment` (and `t`, default 0.5) or a point `at` [x, y] near the path.");
            auto res = vector_node_insert(path, sp, segment, t);
            if (!res.ok()) return op_error(i, res.error().message, res.error().hint);
            continue;
        } else if (op == "delete") {
            if (!need_node()) return op_error(i, "`delete` needs `node` (a whole number).");
            r = vector_node_delete(path, sp, node, o.value("keepShape", true));
        } else if (op == "convert") {
            if (!need_node()) return op_error(i, "`convert` needs `node` (a whole number).");
            const std::string k = o.value("to", std::string());
            if (k != "corner" && k != "smooth" && k != "symmetric")
                return op_error(i, "`to` must be corner, smooth or symmetric.",
                                did_you_mean(k, std::vector<std::string>{"corner", "smooth", "symmetric"}));
            r = vector_node_convert(path, sp, node,
                                    k == "corner"   ? VecNodeKind::Corner
                                    : k == "smooth" ? VecNodeKind::Smooth
                                                    : VecNodeKind::Symmetric);
        } else if (op == "break") {
            if (!need_node()) return op_error(i, "`break` needs `node` (a whole number).");
            r = vector_node_break(path, sp, node);
        } else if (op == "join") {
            const int osp = o.contains("other") && o["other"].is_number_integer() ? o["other"].get<int>() : sp;
            const int onode =
                o.contains("otherNode") && o["otherNode"].is_number_integer() ? o["otherNode"].get<int>() : -1;
            if (!need_node() || onode < 0)
                return op_error(
                    i, "`join` needs `node` and `otherNode` (the two ends), and `other` when it is another subpath.");
            r = vector_nodes_join(path, sp, node, osp, onode, o.value("connect", std::string("merge")) != "line");
        } else if (op == "close") {
            r = vector_subpath_close(path, sp);
        } else if (op == "reverse") {
            r = vector_subpath_reverse(path, sp);
        } else if (op == "append") {
            if (!read_point(o, "at", to)) return op_error(i, "`append` needs `at` [x, y].");
            VecPoint out;
            const bool hasOut = read_point(o, "out", out);
            r = vector_node_append(path, sp, to, hasOut ? &out : nullptr,
                                   o.value("end", std::string("end")) != "start");
        }
        if (!r.ok()) return op_error(i, r.error().message, r.error().hint);
    }
    return {};
}

}  // namespace fa
