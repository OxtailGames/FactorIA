#include "broadphase3d.h"

#include <format>

namespace fa::detail {

namespace {
float perimeter(const Aabb3& b) {
    const Vec3 d = b.hi - b.lo;
    return 2.0f * (d.x * d.y + d.y * d.z + d.z * d.x);
}
}  // namespace

int Broadphase3D::alloc() {
    if (free_ != kNone) {
        const int n = free_;
        free_ = nodes_[std::size_t(n)].parent;
        nodes_[std::size_t(n)] = Node{};
        nodes_[std::size_t(n)].used = true;
        return n;
    }
    nodes_.emplace_back();
    nodes_.back().used = true;
    return int(nodes_.size()) - 1;
}

void Broadphase3D::release(int n) {
    Node& node = nodes_[std::size_t(n)];
    node = Node{};
    node.parent = free_;
    free_ = n;
}

void Broadphase3D::clear() {
    nodes_.clear();
    root_ = free_ = kNone;
    leaves_ = 0;
    writes_ = 0;
}

int Broadphase3D::create(const Aabb3& fat, std::uint32_t payload) {
    const int n = alloc();
    Node& node = nodes_[std::size_t(n)];
    node.box = fat;
    node.payload = payload;
    ++leaves_;
    ++writes_;
    insert_leaf(n);
    return n;
}

void Broadphase3D::destroy(int proxy) {
    if (proxy < 0) return;
    remove_leaf(proxy);
    release(proxy);
    --leaves_;
}

void Broadphase3D::move(int proxy, const Aabb3& fat) {
    remove_leaf(proxy);
    nodes_[std::size_t(proxy)].box = fat;
    insert_leaf(proxy);
    ++writes_;
}

bool Broadphase3D::cover(int proxy, const Aabb3& need, float margin, Vec3 stretch, bool tighten, float slack) {
    const Aabb3& cur = nodes_[std::size_t(proxy)].box;
    const Aabb3 ideal = make_fat(need, margin, stretch);
    const bool refit = !aabb_contains(cur, need) || (tighten && !aabb_contains(aabb_grow(ideal, slack), cur));
    if (!refit) return false;
    move(proxy, ideal);
    return true;
}

// The node under `parent` that was `oldChild` is now `newChild`.
void Broadphase3D::replace_child(int parent, int oldChild, int newChild) {
    Node& p = nodes_[std::size_t(parent)];
    if (p.child1 == oldChild)
        p.child1 = newChild;
    else
        p.child2 = newChild;
}

void Broadphase3D::insert_leaf(int leaf) {
    nodes_[std::size_t(leaf)].parent = kNone;
    if (root_ == kNone) {
        root_ = leaf;
        return;
    }
    const Aabb3 box = nodes_[std::size_t(leaf)].box;
    // Walk down to the sibling that grows the tree's surface the least (the surface-area heuristic, greedy).
    int index = root_;
    while (nodes_[std::size_t(index)].child1 != kNone) {
        const Node& n = nodes_[std::size_t(index)];
        const float area = perimeter(n.box);
        const float combinedArea = perimeter(aabb_union(n.box, box));
        const float cost = 2.0f * combinedArea;              // a new parent here
        const float inherit = 2.0f * (combinedArea - area);  // what going down costs every ancestor
        auto child_cost = [&](int c) {
            const Node& ch = nodes_[std::size_t(c)];
            const float grown = perimeter(aabb_union(box, ch.box));
            return (ch.child1 == kNone ? grown : grown - perimeter(ch.box)) + inherit;
        };
        const float cost1 = child_cost(n.child1), cost2 = child_cost(n.child2);
        if (cost < cost1 && cost < cost2) break;
        index = cost1 < cost2 ? n.child1 : n.child2;
    }
    const int sibling = index;
    const int oldParent = nodes_[std::size_t(sibling)].parent;
    const int parent = alloc();  // (may reallocate nodes_)
    Node& np = nodes_[std::size_t(parent)];
    np.parent = oldParent;
    np.box = aabb_union(box, nodes_[std::size_t(sibling)].box);
    np.height = nodes_[std::size_t(sibling)].height + 1;
    np.child1 = sibling;
    np.child2 = leaf;
    nodes_[std::size_t(sibling)].parent = parent;
    nodes_[std::size_t(leaf)].parent = parent;
    if (oldParent != kNone)
        replace_child(oldParent, sibling, parent);
    else
        root_ = parent;
    // Walk back up fixing heights and boxes, rotating where one side got too tall.
    for (int i = nodes_[std::size_t(leaf)].parent; i != kNone; i = nodes_[std::size_t(i)].parent) {
        i = balance(i);
        Node& n = nodes_[std::size_t(i)];
        const Node& c1 = nodes_[std::size_t(n.child1)];
        const Node& c2 = nodes_[std::size_t(n.child2)];
        n.height = 1 + std::max(c1.height, c2.height);
        n.box = aabb_union(c1.box, c2.box);
    }
}

void Broadphase3D::remove_leaf(int leaf) {
    if (leaf == root_) {
        root_ = kNone;
        return;
    }
    const int parent = nodes_[std::size_t(leaf)].parent;
    const int grand = nodes_[std::size_t(parent)].parent;
    const int sibling = nodes_[std::size_t(parent)].child1 == leaf ? nodes_[std::size_t(parent)].child2
                                                                   : nodes_[std::size_t(parent)].child1;
    nodes_[std::size_t(leaf)].parent = kNone;
    if (grand == kNone) {
        root_ = sibling;
        nodes_[std::size_t(sibling)].parent = kNone;
        release(parent);
        return;
    }
    replace_child(grand, parent, sibling);
    nodes_[std::size_t(sibling)].parent = grand;
    release(parent);
    for (int i = grand; i != kNone; i = nodes_[std::size_t(i)].parent) {
        i = balance(i);
        Node& n = nodes_[std::size_t(i)];
        const Node& c1 = nodes_[std::size_t(n.child1)];
        const Node& c2 = nodes_[std::size_t(n.child2)];
        n.box = aabb_union(c1.box, c2.box);
        n.height = 1 + std::max(c1.height, c2.height);
    }
}

// Rotates node `ia` when one child is more than one level taller than the other; returns the node now at its place.
int Broadphase3D::balance(int ia) {
    Node& a = nodes_[std::size_t(ia)];
    if (a.child1 == kNone || a.height < 2) return ia;
    const int ib = a.child1, ic = a.child2;
    const int factor = nodes_[std::size_t(ic)].height - nodes_[std::size_t(ib)].height;
    if (factor > 1) {  // C rises above A
        const int iF = nodes_[std::size_t(ic)].child1, iG = nodes_[std::size_t(ic)].child2;
        Node& c = nodes_[std::size_t(ic)];
        c.child1 = ia;
        c.parent = a.parent;
        a.parent = ic;
        if (c.parent != kNone)
            replace_child(c.parent, ia, ic);
        else
            root_ = ic;
        Node& f = nodes_[std::size_t(iF)];
        Node& g = nodes_[std::size_t(iG)];
        const Node& b = nodes_[std::size_t(ib)];
        const bool fTaller = f.height > g.height;
        const int keep = fTaller ? iF : iG, give = fTaller ? iG : iF;  // `keep` stays under C, `give` goes under A
        c.child2 = keep;
        a.child2 = give;
        nodes_[std::size_t(give)].parent = ia;
        a.box = aabb_union(b.box, nodes_[std::size_t(give)].box);
        c.box = aabb_union(a.box, nodes_[std::size_t(keep)].box);
        a.height = 1 + std::max(b.height, nodes_[std::size_t(give)].height);
        c.height = 1 + std::max(a.height, nodes_[std::size_t(keep)].height);
        return ic;
    }
    if (factor < -1) {  // B rises above A
        const int iD = nodes_[std::size_t(ib)].child1, iE = nodes_[std::size_t(ib)].child2;
        Node& b = nodes_[std::size_t(ib)];
        b.child1 = ia;
        b.parent = a.parent;
        a.parent = ib;
        if (b.parent != kNone)
            replace_child(b.parent, ia, ib);
        else
            root_ = ib;
        const Node& c = nodes_[std::size_t(ic)];
        const bool dTaller = nodes_[std::size_t(iD)].height > nodes_[std::size_t(iE)].height;
        const int keep = dTaller ? iD : iE, give = dTaller ? iE : iD;
        b.child2 = keep;
        a.child1 = give;
        nodes_[std::size_t(give)].parent = ia;
        a.box = aabb_union(c.box, nodes_[std::size_t(give)].box);
        b.box = aabb_union(a.box, nodes_[std::size_t(keep)].box);
        a.height = 1 + std::max(c.height, nodes_[std::size_t(give)].height);
        b.height = 1 + std::max(a.height, nodes_[std::size_t(keep)].height);
        return ib;
    }
    return ia;
}

void Broadphase3D::sorted_pairs(std::vector<std::pair<std::uint32_t, std::uint32_t>>& out) const {
    out.clear();
    std::vector<std::uint32_t> hits;
    for (const Node& n : nodes_) {
        if (!n.used || n.child1 != kNone) continue;
        sorted_query(n.box, hits);
        for (std::uint32_t p : hits)
            if (p > n.payload) out.emplace_back(n.payload, p);
    }
    std::sort(out.begin(), out.end());
}

std::string Broadphase3D::validate(bool checkBalance) const {
    constexpr std::size_t kMaxReported = 8;  // a broken tree can have thousands of bad nodes: the first ones tell enough
    std::string problems;
    std::size_t count = 0;
    auto report = [&](const std::string& what) {
        if (++count > kMaxReported) return;
        if (!problems.empty()) problems += "; ";
        problems += what;
    };
    std::size_t leaves = 0;
    std::vector<int> stack;
    if (root_ != kNone) {
        if (nodes_[std::size_t(root_)].parent != kNone) report("the root has a parent");
        stack.push_back(root_);
    }
    while (!stack.empty()) {
        const int i = stack.back();
        stack.pop_back();
        const Node& n = nodes_[std::size_t(i)];
        if (!n.used) {
            report(std::format("node {} is reachable but free", i));
            continue;
        }
        if (n.child1 == kNone) {
            ++leaves;
            if (n.height != 0) report(std::format("leaf {} has height {}", i, n.height));
            continue;
        }
        const Node& c1 = nodes_[std::size_t(n.child1)];
        const Node& c2 = nodes_[std::size_t(n.child2)];
        if (c1.parent != i || c2.parent != i) report(std::format("node {}: a child does not point back", i));
        if (n.height != 1 + std::max(c1.height, c2.height)) report(std::format("node {}: wrong height", i));
        if (!aabb_contains(n.box, c1.box) || !aabb_contains(n.box, c2.box))
            report(std::format("node {}: its box does not contain its children's", i));
        if (checkBalance && (c1.height - c2.height > 1 || c2.height - c1.height > 1))
            report(std::format("node {}: unbalanced", i));
        stack.push_back(n.child1);
        stack.push_back(n.child2);
    }
    if (leaves != leaves_) report(std::format("{} leaves reachable, {} counted", leaves, leaves_));
    if (count > kMaxReported) problems += std::format("; ... and {} more", count - kMaxReported);
    return problems;
}

}  // namespace fa::detail
