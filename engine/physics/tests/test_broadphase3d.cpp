// The 3D broad phase (broadphase3d.h): the dynamic AABB tree finds exactly the overlapping boxes, in an order that does not
// depend on how the tree was built, and keeps its structure valid through inserts, moves and removals.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <numeric>
#include <utility>
#include <vector>

#include "../src/broadphase3d.h"

using namespace fa;
using namespace fa::detail;

namespace {

// A tiny fixed generator (xorshift): the same scenes on every platform and standard library.
struct Lcg {
    std::uint64_t s;
    explicit Lcg(std::uint64_t seed) : s(seed * 2685821657736338717ull + 1) {}
    std::uint32_t next() {
        s ^= s >> 12;
        s ^= s << 25;
        s ^= s >> 27;
        return std::uint32_t((s * 2685821657736338717ull) >> 32);
    }
    float unit() { return float(next() >> 8) / float(1u << 24); }
    float range(float lo, float hi) { return lo + (hi - lo) * unit(); }
};

Aabb3 random_box(Lcg& rng, float world, float maxSize) {
    const Vec3 c{rng.range(0, world), rng.range(0, world), rng.range(0, world)};
    const Vec3 h{rng.range(0.05f, maxSize), rng.range(0.05f, maxSize), rng.range(0.05f, maxSize)};
    return {c - h, c + h};
}

using Pairs = std::vector<std::pair<std::uint32_t, std::uint32_t>>;

Pairs brute_pairs(const std::vector<Aabb3>& boxes, const std::vector<bool>& alive) {
    Pairs out;
    for (std::uint32_t i = 0; i < boxes.size(); ++i)
        for (std::uint32_t k = i + 1; k < boxes.size(); ++k)
            if (alive[i] && alive[k] && aabb_overlap(boxes[i], boxes[k])) out.emplace_back(i, k);
    return out;
}

}  // namespace

TEST_CASE("broadphase3d: an empty tree answers nothing and a single leaf answers itself") {
    Broadphase3D bp;
    std::vector<std::uint32_t> hits;
    bp.sorted_query({{-1e9f, -1e9f, -1e9f}, {1e9f, 1e9f, 1e9f}}, hits);
    CHECK(hits.empty());
    CHECK(bp.height() == 0);
    const int p = bp.create({{0, 0, 0}, {1, 1, 1}}, 7);
    CHECK(bp.size() == 1);
    CHECK(bp.height() == 1);
    bp.sorted_query({{0.5f, 0.5f, 0.5f}, {2, 2, 2}}, hits);
    CHECK(hits == std::vector<std::uint32_t>{7});
    bp.sorted_query({{2, 2, 2}, {3, 3, 3}}, hits);
    CHECK(hits.empty());
    bp.destroy(p);
    CHECK(bp.size() == 0);
    CHECK(bp.height() == 0);
    CHECK(bp.validate().empty());
}

TEST_CASE("broadphase3d: queries and pairs equal brute force on random scenes, through inserts, moves and removals") {
    Lcg rng(12345);
    const int n = 400;
    Broadphase3D bp;
    std::vector<Aabb3> boxes(n);
    std::vector<int> proxy(n, Broadphase3D::kNone);
    std::vector<bool> alive(n, false);
    for (int i = 0; i < n; ++i) {
        boxes[std::size_t(i)] = random_box(rng, 30.0f, 1.5f);
        proxy[std::size_t(i)] = bp.create(boxes[std::size_t(i)], std::uint32_t(i));
        alive[std::size_t(i)] = true;
    }
    CHECK(bp.validate().empty());
    CHECK(bp.size() == std::size_t(n));

    auto check_all = [&](const char* when) {
        INFO(when);
        CHECK(bp.validate().empty());
        Pairs got;
        bp.sorted_pairs(got);
        CHECK(got == brute_pairs(boxes, alive));
        std::vector<std::uint32_t> hits;
        for (int q = 0; q < 40; ++q) {
            const Aabb3 box = random_box(rng, 30.0f, 4.0f);
            bp.sorted_query(box, hits);
            std::vector<std::uint32_t> want;
            for (std::uint32_t i = 0; i < boxes.size(); ++i)
                if (alive[i] && aabb_overlap(boxes[i], box)) want.push_back(i);
            CHECK(hits == want);
        }
    };
    check_all("after the inserts");

    for (int round = 0; round < 6; ++round) {
        for (int i = 0; i < n; ++i) {  // move a third of the boxes, remove a tenth, put some of those back
            const std::size_t u = std::size_t(i);
            const std::uint32_t r = rng.next() % 30;
            if (r < 10 && alive[u]) {
                boxes[u] = random_box(rng, 30.0f, 1.5f);
                bp.move(proxy[u], boxes[u]);
            } else if (r < 13 && alive[u]) {
                bp.destroy(proxy[u]);
                proxy[u] = Broadphase3D::kNone;
                alive[u] = false;
            } else if (r < 20 && !alive[u]) {
                boxes[u] = random_box(rng, 30.0f, 1.5f);
                proxy[u] = bp.create(boxes[u], std::uint32_t(i));
                alive[u] = true;
            }
        }
        check_all("after a round of moves and removals");
    }
    std::size_t live = 0;
    for (bool a : alive) live += a ? 1 : 0;
    CHECK(bp.size() == live);
    for (int i = 0; i < n; ++i)
        if (alive[std::size_t(i)]) bp.destroy(proxy[std::size_t(i)]);
    CHECK(bp.size() == 0);
    CHECK(bp.validate().empty());
}

TEST_CASE("broadphase3d: the answer does not depend on the order the leaves went in") {
    Lcg rng(777);
    const int n = 300;
    std::vector<Aabb3> boxes;
    for (int i = 0; i < n; ++i) boxes.push_back(random_box(rng, 20.0f, 1.2f));
    std::vector<int> order(n);
    std::iota(order.begin(), order.end(), 0);

    Pairs reference;
    std::vector<std::vector<std::uint32_t>> refQueries;
    std::vector<Aabb3> queries;
    for (int q = 0; q < 25; ++q) queries.push_back(random_box(rng, 20.0f, 3.0f));
    for (int variant = 0; variant < 4; ++variant) {
        if (variant == 1) std::reverse(order.begin(), order.end());
        if (variant >= 2)
            for (int i = n - 1; i > 0; --i) std::swap(order[std::size_t(i)], order[rng.next() % std::uint32_t(i + 1)]);
        Broadphase3D bp;
        for (int i : order) bp.create(boxes[std::size_t(i)], std::uint32_t(i));
        Pairs pairs;
        bp.sorted_pairs(pairs);
        CHECK(std::is_sorted(pairs.begin(), pairs.end()));
        std::vector<std::vector<std::uint32_t>> answers;
        std::vector<std::uint32_t> hits;
        for (const Aabb3& q : queries) {
            bp.sorted_query(q, hits);
            CHECK(std::is_sorted(hits.begin(), hits.end()));
            answers.push_back(hits);
        }
        if (variant == 0) {
            reference = pairs;
            refQueries = answers;
        } else {
            CHECK(pairs == reference);
            CHECK(answers == refQueries);
        }
    }
    CHECK(!reference.empty());
}

TEST_CASE("broadphase3d: the tree stays balanced for leaves inserted in a line, and payloads can be renumbered") {
    Broadphase3D bp;
    const int n = 2000;
    std::vector<int> proxy;
    for (int i = 0; i < n; ++i)
        proxy.push_back(bp.create({{float(i), 0, 0}, {float(i) + 0.9f, 1, 1}}, std::uint32_t(i)));
    CHECK(bp.validate().empty());
    CHECK(bp.height() <= 24);  // 2000 leaves: log2 = 11; a balanced tree is a few levels above it
    for (int i = 0; i < n; ++i) bp.set_payload(proxy[std::size_t(i)], std::uint32_t(n - 1 - i));
    std::vector<std::uint32_t> hits;
    bp.sorted_query({{10.5f, 0.5f, 0.5f}, {10.6f, 0.6f, 0.6f}}, hits);
    CHECK(hits == std::vector<std::uint32_t>{std::uint32_t(n - 1 - 10)});
    CHECK(bp.payload(proxy[10]) == std::uint32_t(n - 1 - 10));
    // Removing every other leaf keeps the structure valid.
    for (int i = 0; i < n; i += 2) bp.destroy(proxy[std::size_t(i)]);
    CHECK(bp.validate().empty());
    CHECK(bp.size() == std::size_t(n / 2));
}

TEST_CASE("broadphase3d: cover leaves the tree alone while the box fits and refits it when it does not") {
    Broadphase3D bp;
    const Aabb3 tight{{0, 0, 0}, {1, 1, 1}};
    const int p = bp.create(Broadphase3D::make_fat(tight, 0.1f, {}), 0);
    bp.create({{5, 5, 5}, {6, 6, 6}}, 1);
    const std::uint64_t before = bp.writes();
    CHECK_FALSE(bp.cover(p, {{0.05f, 0.05f, 0.05f}, {1.05f, 1.05f, 1.05f}}, 0.1f, {}));  // inside the margin
    CHECK(bp.writes() == before);
    CHECK(
        bp.cover(p, {{0.5f, 0.5f, 0.5f}, {1.5f, 1.5f, 1.5f}}, 0.1f, {1, 0, 0}));  // outside: refit, stretched along +x
    CHECK(bp.writes() == before + 1);
    CHECK(bp.fat(p).hi.x == doctest::Approx(1.5f + 0.1f + 1.0f));
    CHECK(bp.fat(p).lo.x == doctest::Approx(0.5f - 0.1f));
    CHECK(aabb_contains(bp.fat(p), {{0.5f, 0.5f, 0.5f}, {1.5f, 1.5f, 1.5f}}));
    // Tightening: the box that grew for a fast move shrinks back once the body is slow.
    CHECK_FALSE(bp.cover(p, {{0.5f, 0.5f, 0.5f}, {1.5f, 1.5f, 1.5f}}, 0.1f, {1, 0, 0}, true));  // still the ideal box
    CHECK(bp.cover(p, {{0.5f, 0.5f, 0.5f}, {1.5f, 1.5f, 1.5f}}, 0.1f, {}, true));
    CHECK(bp.fat(p).hi.x == doctest::Approx(1.6f));
    CHECK(bp.validate().empty());
}

TEST_CASE("broadphase3d: a query with a deep tree and a box that overlaps everything finds every leaf") {
    Broadphase3D bp;
    const int n = 5000;
    for (int i = 0; i < n; ++i)
        bp.create({{float(i % 50), float(i / 50 % 50), float(i / 2500)},
                   {float(i % 50) + 1, float(i / 50 % 50) + 1, float(i / 2500) + 1}},
                  std::uint32_t(i));
    std::vector<std::uint32_t> hits;
    bp.sorted_query({{-1, -1, -1}, {100, 100, 100}}, hits);
    CHECK(hits.size() == std::size_t(n));
    std::vector<std::uint32_t> all(n);
    std::iota(all.begin(), all.end(), 0u);
    CHECK(hits == all);
}
