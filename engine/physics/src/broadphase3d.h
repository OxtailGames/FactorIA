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
