// Private: the broad phase of the 3D solver (Physics3D): a dynamic AABB tree with fat boxes.
//
// Every collider with a shape owns one leaf. The leaf holds a FAT box: the collider's bounds grown by a margin and, for a
// body in motion, stretched along its velocity, so a body that moves a little (or a lot, in the direction it is going) keeps
// its leaf and the tree is not touched. The owner keeps the invariant "the fat box contains every box a query will ask
// about" (cover()); a query for a box then returns every leaf whose fat box overlaps it, which is a superset of the leaves
// whose real bounds do. The narrow phase decides the rest.
//
// The tree is balanced by rotations on insertion and removal (the height stays O(log n)), and a leaf that outgrows its fat box
// is removed and inserted again. What a query returns is a SET of payloads: callers sort it (sorted_query), so no result
// depends on the shape of the tree, on the order the leaves were inserted in, or on the number of threads that query. The tree
// itself is only read by queries (thread safe while nobody writes).
#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/math.h"

namespace fa::detail {

struct Aabb3 {
    Vec3 lo, hi;
};

inline bool aabb_overlap(const Aabb3& a, const Aabb3& b) {
    return a.lo.x <= b.hi.x && a.hi.x >= b.lo.x && a.lo.y <= b.hi.y && a.hi.y >= b.lo.y && a.lo.z <= b.hi.z &&
           a.hi.z >= b.lo.z;
}
inline bool aabb_contains(const Aabb3& outer, const Aabb3& inner) {
    return outer.lo.x <= inner.lo.x && outer.lo.y <= inner.lo.y && outer.lo.z <= inner.lo.z &&
           outer.hi.x >= inner.hi.x && outer.hi.y >= inner.hi.y && outer.hi.z >= inner.hi.z;
}
inline Aabb3 aabb_union(const Aabb3& a, const Aabb3& b) { return {min(a.lo, b.lo), max(a.hi, b.hi)}; }
inline Aabb3 aabb_grow(const Aabb3& a, float m) { return {a.lo - Vec3{m}, a.hi + Vec3{m}}; }

class Broadphase3D {
public:
    static constexpr int kNone = -1;

    // The fat box of a body: `tight` grown by `margin` on every side and stretched by `stretch` (the distance the body is
    // expected to travel: lo moves down by its negative components, hi up by its positive ones).
    static Aabb3 make_fat(const Aabb3& tight, float margin, Vec3 stretch) {
        return {tight.lo - Vec3{margin} + min(stretch, Vec3{}), tight.hi + Vec3{margin} + max(stretch, Vec3{})};
    }

    // A leaf for `fat` that reports `payload`; returns its proxy id (valid until destroy()).
    int create(const Aabb3& fat, std::uint32_t payload);
    void destroy(int proxy);
    // Gives the leaf a new fat box (removes and inserts it again).
    void move(int proxy, const Aabb3& fat);
    // What query() reports for this leaf (the owner renumbers its bodies, the proxy stays).
    void set_payload(int proxy, std::uint32_t payload) { nodes_[std::size_t(proxy)].payload = payload; }
    const Aabb3& fat(int proxy) const { return nodes_[std::size_t(proxy)].box; }
    std::uint32_t payload(int proxy) const { return nodes_[std::size_t(proxy)].payload; }
    void clear();
    std::size_t size() const { return leaves_; }
    // Number of leaves that were moved or created since construction / clear() (tests, stats).
    std::uint64_t writes() const { return writes_; }
    // Levels of the tree (0 empty, 1 one leaf).
    int height() const { return root_ == kNone ? 0 : nodes_[std::size_t(root_)].height + 1; }

    // Keeps the invariant for a box that must stay inside the leaf's fat box: when `need` is not inside it (or, with
    // `tighten`, when the fat box is more than `slack` bigger than the ideal one on some side) the leaf gets
    // make_fat(need, margin, stretch). Returns true when the tree was written.
    bool cover(int proxy, const Aabb3& need, float margin, Vec3 stretch, bool tighten = false, float slack = 0.25f);

    // Calls visit(payload) for every leaf whose fat box overlaps `box` (any order).
    template <class F>
    void query(const Aabb3& box, F&& visit) const {
        if (root_ == kNone || !aabb_overlap(nodes_[std::size_t(root_)].box, box)) return;
        int stack[kStack];
        int top = 0;
        stack[top++] = root_;
        while (top > 0) {  // a node on the stack overlaps `box`: its children are tested before they are pushed
            const Node& n = nodes_[std::size_t(stack[--top])];
            if (n.child1 == kNone) {
                visit(n.payload);
            } else if (top + 2 <= kStack) {
                if (aabb_overlap(nodes_[std::size_t(n.child1)].box, box)) stack[top++] = n.child1;
                if (aabb_overlap(nodes_[std::size_t(n.child2)].box, box)) stack[top++] = n.child2;
            } else {
                query_deep(n, box, visit);
            }
        }
    }
    // Calls visit(payload) for every leaf whose fat box the ray origin + t * dir, 0 <= t <= maxT, touches (the box padded by
    // 1e-3). visit returns the new maxT: a hit that shortens the ray prunes every subtree that starts beyond it (return the
    // value you were given, or the one you keep, to prune nothing). The nearer child is visited first, so the usual closest
    // hit query touches few leaves; WHICH leaves are visited depends on the tree, so the caller's result must not depend on the
    // order (break ties by payload). `dir` need not be unit length but t is then in its units.
    template <class F>
    void ray_query(Vec3 origin, Vec3 dir, float maxT, F&& visit) const {
        if (root_ == kNone) return;
        const Vec3 inv{ray_inv(dir.x), ray_inv(dir.y), ray_inv(dir.z)};
        float tn = 0.0f;
        if (!ray_slab(nodes_[std::size_t(root_)].box, origin, dir, inv, maxT, tn)) return;
        struct Item {
            int node;
            float t;
        };
        Item stack[kStack];
        int top = 0;
        stack[top++] = {root_, tn};
        while (top > 0) {
            const Item it = stack[--top];
            if (it.t > maxT) continue;  // the ray was shortened since this node was pushed
            const Node& n = nodes_[std::size_t(it.node)];
            if (n.child1 == kNone) {
                maxT = visit(n.payload);
            } else if (top + 2 <= kStack) {
                float t1 = 0.0f, t2 = 0.0f;
                const bool h1 = ray_slab(nodes_[std::size_t(n.child1)].box, origin, dir, inv, maxT, t1);
                const bool h2 = ray_slab(nodes_[std::size_t(n.child2)].box, origin, dir, inv, maxT, t2);
                if (h1 && h2) {  // the nearer one is popped first
                    if (t1 <= t2) {
                        stack[top++] = {n.child2, t2};
                        stack[top++] = {n.child1, t1};
                    } else {
                        stack[top++] = {n.child1, t1};
                        stack[top++] = {n.child2, t2};
                    }
                } else if (h1) {
                    stack[top++] = {n.child1, t1};
                } else if (h2) {
                    stack[top++] = {n.child2, t2};
                }
            } else {
                ray_deep(it.node, origin, dir, inv, maxT, visit);
            }
        }
    }
    // The payloads of the leaves overlapping `box`, ascending, appended to `out` after clearing it.
    void sorted_query(const Aabb3& box, std::vector<std::uint32_t>& out) const {
        out.clear();
        query(box, [&](std::uint32_t p) { out.push_back(p); });
        std::sort(out.begin(), out.end());
    }
    // Every pair of leaves whose fat boxes overlap, as (lower payload, higher payload), sorted ascending: the same list
    // whatever order the leaves were inserted in. (Tests and tools; the solver asks row by row.)
    void sorted_pairs(std::vector<std::pair<std::uint32_t, std::uint32_t>>& out) const;
    // Structure check for tests: parents, heights and boxes are consistent. Empty string when fine.
    std::string validate() const;

private:
    static constexpr int kStack = 128;
    struct Node {
        Aabb3 box;
        int parent = kNone;  // the next free node while the node is free
        int child1 = kNone, child2 = kNone;
        int height = 0;  // 0 for a leaf
        std::uint32_t payload = 0;
        bool used = false;
    };
    static float ray_inv(float d) { return std::fabs(d) < 1e-9f ? 0.0f : 1.0f / d; }
    // Does the ray reach `box` (padded) within [0, maxT]? tNear = where it enters (0 when the origin is inside).
    static bool ray_slab(const Aabb3& box, Vec3 o, Vec3 d, Vec3 inv, float maxT, float& tNear) {
        constexpr float kPad = 1e-3f;
        float tmin = 0.0f, tmax = maxT;
        for (int i = 0; i < 3; ++i) {
            const float lo = box.lo[i] - kPad, hi = box.hi[i] + kPad;
            if (std::fabs(d[i]) < 1e-9f) {
                if (o[i] < lo || o[i] > hi) return false;
                continue;
            }
            float t1 = (lo - o[i]) * inv[i], t2 = (hi - o[i]) * inv[i];
            if (t1 > t2) std::swap(t1, t2);
            tmin = std::max(tmin, t1);
            tmax = std::min(tmax, t2);
            if (tmin > tmax) return false;
        }
        tNear = tmin;
        return true;
    }
    template <class F>
    void ray_deep(int node, Vec3 o, Vec3 d, Vec3 inv, float& maxT, F& visit) const {  // recursion for a very deep tree
        const Node& n = nodes_[std::size_t(node)];
        float t = 0.0f;
        if (!ray_slab(n.box, o, d, inv, maxT, t)) return;
        if (n.child1 == kNone) {
            maxT = visit(n.payload);
            return;
        }
        ray_deep(n.child1, o, d, inv, maxT, visit);
        ray_deep(n.child2, o, d, inv, maxT, visit);
    }
    int alloc();
    void release(int n);
    void insert_leaf(int leaf);
    void remove_leaf(int leaf);
    int balance(int a);
    void replace_child(int parent, int oldChild, int newChild);
    template <class F>
    void query_deep(const Node& from, const Aabb3& box,
                    F& visit) const {  // recursion: the tree is far deeper than expected
        if (!aabb_overlap(from.box, box)) return;
        if (from.child1 == kNone) {
            visit(from.payload);
            return;
        }
        query_deep(nodes_[std::size_t(from.child1)], box, visit);
        query_deep(nodes_[std::size_t(from.child2)], box, visit);
    }

    std::vector<Node> nodes_;
    int root_ = kNone;
    int free_ = kNone;
    std::size_t leaves_ = 0;
    std::uint64_t writes_ = 0;
};

}  // namespace fa::detail
