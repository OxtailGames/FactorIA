// Wave Function Collapse (fa/scene/wfc.h): the models, the solver, its determinism and its errors.
#include <doctest.h>

#include <chrono>
#include <cstdint>
#include <set>
#include <string>
#include <vector>

#include "fa/scene/autotile.h"
#include "fa/scene/wfc.h"

using namespace fa;

namespace {

using Rows = std::vector<std::string>;

// '.' = symbol 0, '#' = 1, 'o' = 2 ... in order of first appearance.
wfc::Sample sample_of(const Rows& rows) {
    wfc::Sample s;
    s.height = int(rows.size());
    s.width = int(rows[0].size());
    std::string seen;
    for (const std::string& r : rows)
        for (char c : r) {
            std::size_t at = seen.find(c);
            if (at == std::string::npos) {
                at = seen.size();
                seen += c;
            }
            s.cells.push_back(int(at));
        }
    s.symbolCount = int(seen.size());
    return s;
}

std::shared_ptr<wfc::PatternModel> overlapping(const Rows& rows, int n, int symmetry, bool periodicInput) {
    wfc::OverlapOptions o;
    o.n = n;
    o.symmetry = symmetry;
    o.periodicInput = periodicInput;
    auto m = wfc::build_overlapping_model(sample_of(rows), o);
    REQUIRE_MESSAGE(m.ok(), (m.ok() ? std::string() : m.error().to_string()));
    return *m;
}

struct Run {
    bool ok = false;
    std::vector<int> cells;
    wfc::GenStats stats;
    std::string message, hint;
};

Run generate(std::shared_ptr<const wfc::PatternModel> model, int w, int h, std::uint64_t seed, bool periodic = false, int maxAttempts = 10) {
    wfc::GenerateOptions go;
    go.width = w;
    go.height = h;
    go.seed = seed;
    go.periodic = periodic;
    go.maxAttempts = maxAttempts;
    auto g = wfc::Generator::create(model, go);
    REQUIRE_MESSAGE(g.ok(), (g.ok() ? std::string() : g.error().to_string()));
    Run r;
    r.ok = (*g)->run() == wfc::GenStatus::Done;
    r.stats = (*g)->stats();
    if (r.ok) r.cells = (*g)->output();
    else {
        r.message = (*g)->failure_message();
        r.hint = (*g)->failure_hint();
    }
    return r;
}

// The n x n windows of a grid of symbols as strings of symbol digits.
std::set<std::string> windows(const std::vector<int>& cells, int w, int h, int n, bool wrap) {
    std::set<std::string> out;
    const int xs = wrap ? w : w - n + 1, ys = wrap ? h : h - n + 1;
    for (int y = 0; y < ys; ++y)
        for (int x = 0; x < xs; ++x) {
            std::string key;
            for (int dy = 0; dy < n; ++dy)
                for (int dx = 0; dx < n; ++dx) key += char('0' + cells[std::size_t((y + dy) % h) * std::size_t(w) + std::size_t((x + dx) % w)]);
            out.insert(key);
        }
    return out;
}

// The windows a sample may teach, with the rotations / mirrors `symmetry` asks for, computed here independently of the engine.
std::set<std::string> learnable(const Rows& rows, int n, int symmetry, bool wrap) {
    wfc::Sample s = sample_of(rows);
    std::set<std::string> out;
    const int xs = wrap ? s.width : s.width - n + 1, ys = wrap ? s.height : s.height - n + 1;
    for (int y = 0; y < ys; ++y)
        for (int x = 0; x < xs; ++x) {
            std::vector<int> p;
            for (int dy = 0; dy < n; ++dy)
                for (int dx = 0; dx < n; ++dx) p.push_back(s.cells[std::size_t((y + dy) % s.height) * std::size_t(s.width) + std::size_t((x + dx) % s.width)]);
            std::vector<std::vector<int>> forms;
            auto rot = [&](const std::vector<int>& q) {
                std::vector<int> r(q.size());
                for (int yy = 0; yy < n; ++yy)
                    for (int xx = 0; xx < n; ++xx) r[std::size_t(yy * n + xx)] = q[std::size_t((n - 1 - xx) * n + yy)];
                return r;
            };
            auto mir = [&](const std::vector<int>& q) {
                std::vector<int> r(q.size());
                for (int yy = 0; yy < n; ++yy)
                    for (int xx = 0; xx < n; ++xx) r[std::size_t(yy * n + xx)] = q[std::size_t(yy * n + (n - 1 - xx))];
                return r;
            };
            forms.push_back(p);
            if (symmetry == 2) forms.push_back(mir(p));
            if (symmetry >= 4) {
                std::vector<int> r = p;
                for (int k = 0; k < 4; ++k) {
                    if (k > 0) forms.push_back(r);
                    if (symmetry == 8) forms.push_back(mir(r));
                    r = rot(r);
                }
            }
            for (const auto& f : forms) {
                std::string key;
                for (int v : f) key += char('0' + v);
                out.insert(key);
            }
        }
    return out;
}

std::uint64_t fingerprint(const std::vector<int>& cells) {
    std::uint64_t h = 1469598103934665603ull;  // FNV-1a
    for (int c : cells) {
        h ^= std::uint64_t(c + 1);
        h *= 1099511628211ull;
    }
    return h;
}

const Rows kRooms = {
    "..........",
    ".##.......",
    ".##...#...",
    "......#...",
    "..#.......",
    "..#...##..",
    "..........",
    "...#......",
};

constexpr std::uint64_t FINGERPRINT_ROOMS = 1276986090499406791ull;
constexpr std::uint64_t FINGERPRINT_TILED = 17566608511428345258ull;

const Rows kMap16 = {
    "................", "..####..........", "..#..#....##....", "..#..#....##....", "..####..........", "................",
    "......#.........", "......#....###..", "...........#.#..", "...........###..", "..##............", "..##......#.....",
    "................", "....#......#....", "................", "................",
};

const Rows kRing = {"#####", "#...#", "#.#.#", "#...#", "#####"};

std::vector<Terrain> grass_water() {
    auto t = parse_terrains(Json::parse(R"([{"name":"grass","mode":"basic16","first":0},{"name":"water","mode":"basic16","first":16}])"));
    REQUIRE(t.ok());
    return *t;
}

}  // namespace

TEST_CASE("wfc overlapping: every window of the output exists in the sample") {
    for (bool wrapInput : {false, true}) {
        auto model = overlapping(kRooms, 3, 1, wrapInput);
        const std::set<std::string> allowed = learnable(kRooms, 3, 1, wrapInput);
        CHECK(model->pattern_count() == allowed.size());
        for (std::uint64_t seed = 0; seed < 6; ++seed) {
            Run r = generate(model, 24, 16, seed);
            REQUIRE_MESSAGE(r.ok, r.message);
            REQUIRE(r.cells.size() == 24u * 16u);
            for (const std::string& w : windows(r.cells, 24, 16, 3, false)) CHECK(allowed.count(w) == 1);
        }
    }
}

TEST_CASE("wfc overlapping: symmetry adds exactly the rotated and mirrored patterns") {
    for (int symmetry : {1, 2, 4, 8}) {
        auto model = overlapping(kRooms, 2, symmetry, false);
        const std::set<std::string> allowed = learnable(kRooms, 2, symmetry, false);
        CHECK_MESSAGE(model->pattern_count() == allowed.size(), "symmetry " << symmetry);
        Run r = generate(model, 20, 20, 3);
        REQUIRE_MESSAGE(r.ok, r.message);
        for (const std::string& w : windows(r.cells, 20, 20, 2, false)) CHECK_MESSAGE(allowed.count(w) == 1, "symmetry " << symmetry);
    }
    CHECK(overlapping(kRooms, 3, 8, false)->pattern_count() > overlapping(kRooms, 3, 1, false)->pattern_count());
}

TEST_CASE("wfc overlapping: a periodic output wraps around its edges and only uses windows of a wrapping sample") {
    auto model = overlapping(kRooms, 3, 1, true);
    const std::set<std::string> allowed = learnable(kRooms, 3, 1, true);
    for (std::uint64_t seed = 0; seed < 4; ++seed) {
        Run r = generate(model, 20, 12, seed, true);
        REQUIRE_MESSAGE(r.ok, r.message);
        for (const std::string& w : windows(r.cells, 20, 12, 3, true)) CHECK(allowed.count(w) == 1);
        CHECK(r.stats.cells == 20 * 12);
    }
    // Non-periodic output: the pattern grid is smaller than the output.
    Run plain = generate(overlapping(kRooms, 3, 1, false), 20, 12, 1, false);
    REQUIRE(plain.ok);
    CHECK(plain.stats.cells == 18 * 10);
}

TEST_CASE("wfc tiled: neighbours agree about the terrain and re-tiling changes nothing") {
    const std::vector<Terrain> terrains = grass_water();
    auto built = wfc::build_terrain_model(terrains, {});
    REQUIRE(built.ok());
    for (std::uint64_t seed = 0; seed < 5; ++seed) {
        Run r = generate(built->model, 16, 12, seed);
        REQUIRE_MESSAGE(r.ok, r.message);
        std::vector<int> tiles;
        for (int s : r.cells) tiles.push_back(built->tileValues[std::size_t(s)]);
        auto terrain_at = [&](int x, int y) -> std::string {
            if (x < 0 || y < 0 || x >= 16 || y >= 12) return "";
            return terrain_of_tile(terrains, tiles[std::size_t(y) * 16 + std::size_t(x)]).terrain;
        };
        for (int y = 0; y < 12; ++y)
            for (int x = 0; x < 16; ++x) {
                const TerrainOfTile me = terrain_of_tile(terrains, tiles[std::size_t(y) * 16 + std::size_t(x)]);
                if (me.terrain.empty()) continue;
                // basic16: slot = N*1 + E*2 + S*4 + W*8; a set bit means a neighbour of the same terrain there.
                CHECK(((me.slot & 1) != 0) == (terrain_at(x, y - 1) == me.terrain));
                CHECK(((me.slot & 2) != 0) == (terrain_at(x + 1, y) == me.terrain));
                CHECK(((me.slot & 4) != 0) == (terrain_at(x, y + 1) == me.terrain));
                CHECK(((me.slot & 8) != 0) == (terrain_at(x - 1, y) == me.terrain));
            }
        std::vector<int> again = tiles;
        retile_terrain_grid(terrains, 16, 12, again);
        CHECK(again == tiles);
    }
}

TEST_CASE("wfc tiled: tile weights steer the choice") {
    const std::vector<Terrain> terrains = grass_water();
    auto count_water = [&](std::uint32_t waterWeight) {
        std::vector<std::pair<int, std::uint32_t>> weights;
        for (int v = 0; v < 16; ++v) weights.push_back({v, 1});
        for (int v = 16; v < 32; ++v) weights.push_back({v, waterWeight});
        auto built = wfc::build_terrain_model(terrains, weights);
        REQUIRE(built.ok());
        int water = 0;
        for (std::uint64_t seed = 0; seed < 8; ++seed) {
            Run r = generate(built->model, 20, 20, seed);
            REQUIRE(r.ok);
            for (int s : r.cells) water += built->tileValues[std::size_t(s)] >= 16 ? 1 : 0;
        }
        return water;
    };
    CHECK(count_water(50) > count_water(1));
}

TEST_CASE("wfc: the same seed gives the same level, a fixed fingerprint pins it on every platform") {
    auto model = overlapping(kRooms, 3, 8, false);
    Run a = generate(model, 40, 30, 12345);
    Run b = generate(model, 40, 30, 12345);
    Run c = generate(model, 40, 30, 12346);
    REQUIRE(a.ok);
    REQUIRE(b.ok);
    REQUIRE(c.ok);
    CHECK(a.cells == b.cells);
    CHECK(a.cells != c.cells);
    CHECK(fingerprint(a.cells) == FINGERPRINT_ROOMS);

    auto tiled = wfc::build_terrain_model(grass_water(), {});
    REQUIRE(tiled.ok());
    Run t = generate(tiled->model, 24, 18, 99, false);
    REQUIRE(t.ok);
    CHECK(fingerprint(t.cells) == FINGERPRINT_TILED);

    // The entropy helper behind the choice is integer-only: the derived seeds are fixed numbers.
    CHECK(wfc::derive_attempt_seed(1, 0) == wfc::derive_attempt_seed(1, 0));
    CHECK(wfc::derive_attempt_seed(1, 0) != wfc::derive_attempt_seed(1, 1));
    CHECK(wfc::derive_attempt_seed(1, 3) != wfc::derive_attempt_seed(2, 3));
}

TEST_CASE("wfc: step(budget) in small pieces ends in the same grid as run()") {
    auto model = overlapping(kRooms, 3, 2, false);
    Run whole = generate(model, 30, 20, 5);
    REQUIRE(whole.ok);
    wfc::GenerateOptions go;
    go.width = 30;
    go.height = 20;
    go.seed = 5;
    auto g = wfc::Generator::create(model, go);
    REQUIRE(g.ok());
    int steps = 0;
    double last = -1.0;
    while ((*g)->status() == wfc::GenStatus::Running && steps < 1000000) {
        (*g)->step(40);
        ++steps;
        CHECK((*g)->progress() >= 0.0);
        CHECK((*g)->progress() <= 1.0);
        last = (*g)->progress();
    }
    CHECK(steps > 5);
    REQUIRE((*g)->status() == wfc::GenStatus::Done);
    CHECK(last == doctest::Approx(1.0));
    CHECK((*g)->output() == whole.cells);
}

TEST_CASE("wfc: a dead end restarts with the next seed and the final error says where, how often and what to try") {
    // The ring sample teaches only windows around a pillar: a large level cannot be built from it.
    auto model = overlapping(kRing, 3, 1, false);
    Run r = generate(model, 24, 10, 7, false, 4);
    REQUIRE_FALSE(r.ok);
    CHECK(r.stats.attempts == 4);
    CHECK(r.stats.contradictions == 4);
    CHECK(r.message.find("4 attempts") != std::string::npos);
    CHECK(r.message.find("cell (") != std::string::npos);
    CHECK(r.hint.find("bigger") != std::string::npos);
    CHECK(r.hint.find("n") != std::string::npos);
    CHECK(r.hint.find("periodic") != std::string::npos);
    CHECK(r.hint.find("symmetry") != std::string::npos);

    // The same sample in its own size has an answer: the sample itself.
    Run exact = generate(model, 5, 5, 1, false, 4);
    REQUIRE_MESSAGE(exact.ok, exact.message);
    CHECK(exact.cells == sample_of(kRing).cells);
}

TEST_CASE("wfc: retries recover from a contradiction on a later attempt") {
    // n = 4 from a wrapping sample sometimes dead-ends, but a few seeds later it works: no seed fails with 200 attempts.
    auto model = overlapping(kMap16, 4, 1, true);
    int retried = 0;
    for (std::uint64_t seed = 0; seed < 12; ++seed) {
        Run r = generate(model, 40, 40, seed, true, 200);
        REQUIRE_MESSAGE(r.ok, r.message);
        CHECK(r.stats.contradictions == r.stats.attempts - 1);
        if (r.stats.attempts > 1) ++retried;
    }
    CHECK(retried > 0);
}

TEST_CASE("wfc: cell rules fix cells and the accept hook can refuse a finished grid") {
    auto model = overlapping(kRooms, 3, 1, false);
    wfc::GenerateOptions go;
    go.width = 20;
    go.height = 14;
    go.seed = 2;
    go.cellRules.push_back({4, 4, {1}});
    go.cellRules.push_back({10, 7, {0}});
    auto g = wfc::Generator::create(model, go);
    REQUIRE(g.ok());
    REQUIRE((*g)->run() == wfc::GenStatus::Done);
    CHECK((*g)->output()[4 * 20 + 4] == 1);
    CHECK((*g)->output()[7 * 20 + 10] == 0);

    // `accept` wants at least 30 wall cells: the generator retries until a grid has them.
    wfc::GenerateOptions need;
    need.width = 20;
    need.height = 14;
    need.seed = 2;
    need.maxAttempts = 400;
    need.accept = [](const std::vector<int>& cells, std::string& why, std::int64_t&) {
        int walls = 0;
        for (int c : cells) walls += c == 1;
        if (walls >= 30) return true;
        why = "only " + std::to_string(walls) + " wall cells";
        return false;
    };
    auto g2 = wfc::Generator::create(model, need);
    REQUIRE(g2.ok());
    REQUIRE_MESSAGE((*g2)->run() == wfc::GenStatus::Done, (*g2)->failure_message());
    int walls = 0;
    for (int c : (*g2)->output()) walls += c == 1;
    CHECK(walls >= 30);
    CHECK((*g2)->stats().attempts == (*g2)->stats().contradictions + (*g2)->stats().rejected + 1);
    CHECK((*g2)->stats().symbolCounts.size() == 2u);
    CHECK((*g2)->stats().symbolCounts[1] == walls);

    // Always refusing ends in a Failed generator whose message carries the reason.
    wfc::GenerateOptions never;
    never.width = 10;
    never.height = 10;
    never.maxAttempts = 3;
    never.accept = [](const std::vector<int>&, std::string& why, std::int64_t&) {
        why = "not enough treasure";
        return false;
    };
    auto g3 = wfc::Generator::create(model, never);
    REQUIRE(g3.ok());
    CHECK((*g3)->run() == wfc::GenStatus::Failed);
    CHECK((*g3)->failure_message().find("not enough treasure") != std::string::npos);
    CHECK((*g3)->stats().rejected == 3);
    CHECK((*g3)->stats().cutOff == 0);
    CHECK((*g3)->failure_message().find("sample's shape") == std::string::npos);

    // Cut-off areas behind most refusals name the sample's shape and how to fix it.
    wfc::GenerateOptions cut = never;
    cut.accept = [](const std::vector<int>&, std::string& why, std::int64_t&) {
        why = "2 walkable area(s) are cut off from the main one (8 cells)";
        return false;
    };
    auto g4 = wfc::Generator::create(model, cut);
    REQUIRE(g4.ok());
    CHECK((*g4)->run() == wfc::GenStatus::Failed);
    CHECK((*g4)->stats().cutOff == 3);
    CHECK((*g4)->failure_message().find("sample's shape") != std::string::npos);
    CHECK((*g4)->failure_hint().find("passages 2-3 cells wide") != std::string::npos);
}

TEST_CASE("wfc: errors teach") {
    auto message = [](const Error& e) { return e.message + " | " + e.hint; };
    auto has = [](const std::string& s, const char* part) { return s.find(part) != std::string::npos; };

    wfc::OverlapOptions o;
    o.n = 1;
    auto low = wfc::build_overlapping_model(sample_of(kRooms), o);
    REQUIRE_FALSE(low.ok());
    CHECK(has(message(low.error()), "between 2 and 5"));
    o.n = 6;
    CHECK_FALSE(wfc::build_overlapping_model(sample_of(kRooms), o).ok());

    o.n = 3;
    wfc::Sample empty;
    auto none = wfc::build_overlapping_model(empty, o);
    REQUIRE_FALSE(none.ok());
    CHECK(has(message(none.error()), "empty"));

    auto tiny = wfc::build_overlapping_model(sample_of({"#.", ".#"}), o);
    REQUIRE_FALSE(tiny.ok());
    CHECK(has(message(tiny.error()), "smaller than n"));

    o.symmetry = 3;
    CHECK_FALSE(wfc::build_overlapping_model(sample_of(kRooms), o).ok());

    auto noRules = wfc::build_terrain_model({}, {});
    REQUIRE_FALSE(noRules.ok());

    auto model = overlapping(kRooms, 3, 1, false);
    wfc::GenerateOptions go;
    go.width = 2;
    go.height = 9;
    auto small = wfc::Generator::create(model, go);
    REQUIRE_FALSE(small.ok());
    CHECK(has(message(small.error()), "smaller than the pattern size"));

    go.width = 5000;
    go.height = 9;
    CHECK_FALSE(wfc::Generator::create(model, go).ok());

    go.width = 10;
    go.height = 10;
    go.maxAttempts = 0;
    CHECK_FALSE(wfc::Generator::create(model, go).ok());
    go.maxAttempts = 3;
    go.cellRules.push_back({99, 0, {0}});
    auto outside = wfc::Generator::create(model, go);
    REQUIRE_FALSE(outside.ok());
    CHECK(has(message(outside.error()), "outside"));

    // A request above the memory budget says what to shrink.
    wfc::GenerateOptions big;
    big.width = 2048;
    big.height = 2048;
    auto huge = wfc::Generator::create(model, big);
    REQUIRE_FALSE(huge.ok());
    CHECK(has(message(huge.error()), "MB"));
    CHECK(wfc::estimate_generator_memory(*model, 64, 64, false) < wfc::estimate_generator_memory(*model, 128, 128, false));
}

TEST_CASE("wfc: 64 x 64 from a 16 x 16 sample with n = 3 is quick") {
    auto model = overlapping(kMap16, 3, 1, true);
    const auto t0 = std::chrono::steady_clock::now();
    Run r = generate(model, 64, 64, 1, true, 10);
    const double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
    REQUIRE_MESSAGE(r.ok, r.message);
    CHECK(r.cells.size() == 64u * 64u);
#ifdef NDEBUG
    CHECK_MESSAGE(ms < 3000.0, "took " << ms << " ms");
#else
    CHECK_MESSAGE(ms < 60000.0, "took " << ms << " ms");
#endif
}

// ------------------------------------------------------------------------------------------------ constraints (M63.2)

namespace {

wfc::GenerateOptions options_for(int w, int h, std::uint64_t seed, int maxAttempts = 10) {
    wfc::GenerateOptions go;
    go.width = w;
    go.height = h;
    go.seed = seed;
    go.maxAttempts = maxAttempts;
    return go;
}

std::unique_ptr<wfc::Generator> make_generator(std::shared_ptr<const wfc::PatternModel> model, wfc::GenerateOptions go) {
    auto g = wfc::Generator::create(std::move(model), std::move(go));
    REQUIRE_MESSAGE(g.ok(), (g.ok() ? std::string() : g.error().to_string()));
    return std::move(*g);
}

int count_of(const std::vector<int>& cells, int symbol) {
    int n = 0;
    for (int c : cells) n += c == symbol;
    return n;
}

}  // namespace

TEST_CASE("wfc: the entropy heap stays within 4 entries per cell and the memory estimate covers what was held") {
    // A sample with many different patterns, so every observation changes many cells and leaves stale heap entries behind.
    Rows noisy;
    std::uint32_t state = 12345;
    for (int y = 0; y < 40; ++y) {
        std::string row;
        for (int x = 0; x < 40; ++x) {
            state = state * 1664525u + 1013904223u;
            row += char('a' + int((state >> 24) % 5u));
        }
        noisy.push_back(row);
    }
    auto model = overlapping(noisy, 3, 1, true);
    REQUIRE(model->pattern_count() > 300u);
    auto go = options_for(40, 40, 3, 100);
    go.periodic = true;
    auto g = make_generator(model, go);
    g->run();
    const wfc::GenStats& st = g->stats();
    CHECK(st.heapPeak > 0u);
    CHECK(st.heapPeak <= 4u * std::size_t(st.cells));
    CHECK(st.peakBytes > 0u);
    CHECK(st.peakBytes <= st.memoryBytes);
    CHECK(st.work > 0);

    // A regular sample on a bigger grid leaves many stale entries: the heap is rebuilt instead of growing, and the estimate holds.
    auto m16 = overlapping(kMap16, 3, 1, true);
    auto big = options_for(96, 96, 4, 20);
    big.periodic = true;
    auto g16 = make_generator(m16, big);
    REQUIRE_MESSAGE(g16->run() == wfc::GenStatus::Done, g16->failure_message());
    CHECK(g16->stats().heapRebuilds > 0);
    CHECK(g16->stats().heapPeak <= 4u * std::size_t(g16->stats().cells));
    CHECK(g16->stats().peakBytes <= g16->stats().memoryBytes);

    // The sample's model is part of the estimate: a bigger model costs more for the same output size.
    auto small = overlapping(kRooms, 3, 1, false);
    CHECK(wfc::estimate_generator_memory(*model, 40, 40, true) > wfc::estimate_generator_memory(*small, 40, 40, true));
}

TEST_CASE("wfc: weights above 2^32 and an oversized tiled adjacency table are refused with a teaching error") {
    auto message = [](const Error& e) { return e.message + " | " + e.hint; };
    auto terrains = grass_water();
    auto heavy = wfc::build_terrain_model(terrains, {{0, 4000000000u}, {1, 4000000000u}});
    REQUIRE_FALSE(heavy.ok());
    CHECK(message(heavy.error()).find("weights add up") != std::string::npos);

    // A hand-made model whose weights overflow is refused when the generator is created.
    auto model = std::make_shared<wfc::PatternModel>(*overlapping(kRooms, 3, 1, false));
    model->weights[0] = 0xFFFFFFFFu;
    auto g = wfc::Generator::create(model, options_for(10, 10, 1));
    REQUIRE_FALSE(g.ok());
    CHECK(message(g.error()).find("weights add up") != std::string::npos);
    model->weights[0] = 0;
    auto zero = wfc::Generator::create(model, options_for(10, 10, 1));
    REQUIRE_FALSE(zero.ok());
    CHECK(message(zero.error()).find("weight 0") != std::string::npos);

    // The tiled model has the same adjacency limit as the overlapping one: 12000 tiles of a terrain are over it (the table is filled
    // until it passes 48 million entries, about 3 s of Debug CPU, which is the price of testing that limit; nothing here has a time cap).
    Terrain wide;
    wide.name = "wide";
    wide.mode = AutotileMode::Basic16;
    wide.slots.assign(autotile_masks(wide.mode).size(), {});
    for (int i = 0; i < 12000; ++i) wide.slots[std::size_t(i) % wide.slots.size()].push_back(i);
    auto big = wfc::build_terrain_model({wide}, {});
    REQUIRE_FALSE(big.ok());
    CHECK(message(big.error()).find("adjacency table") != std::string::npos);
}

TEST_CASE("wfc constraints: forbidden symbols never appear") {
    auto model = overlapping(kRooms, 3, 1, false);  // symbols: 0 floor, 1 wall
    auto go = options_for(20, 14, 5, 400);
    go.forbidden = {1};
    // Forbidding the wall leaves only the all-floor patterns: a level of floor.
    auto g = make_generator(model, go);
    REQUIRE_MESSAGE(g->run() == wfc::GenStatus::Done, g->failure_message());
    CHECK(count_of(g->output(), 1) == 0);

    // Forbidding everything is refused before anything runs.
    go.forbidden = {0, 1};
    auto none = wfc::Generator::create(model, go);
    REQUIRE_FALSE(none.ok());
    CHECK(none.error().message.find("forbidden") != std::string::npos);
    go.forbidden = {7};
    CHECK_FALSE(wfc::Generator::create(model, go).ok());
}

TEST_CASE("wfc constraints: counts, a missed minimum pins the missing cells and the maximum refuses a grid") {
    auto model = overlapping(kRooms, 3, 1, false);
    for (std::uint64_t seed = 1; seed <= 6; ++seed) {
        auto go = options_for(24, 16, seed, 200);
        go.counts.push_back({{1}, 60, 90, "wall"});
        auto g = make_generator(model, go);
        REQUIRE_MESSAGE(g->run() == wfc::GenStatus::Done, g->failure_message());
        const int walls = count_of(g->output(), 1);
        CHECK(walls >= 60);
        CHECK(walls <= 90);
        CHECK(g->stats().symbolCounts[1] == walls);
    }

    // The rare tile of the sample (the lone 'o') still turns up: a minimum of three of them.
    Rows rare = kRooms;
    rare[3][4] = 'o';
    auto rareModel = overlapping(rare, 3, 1, false);
    int pinnedAny = 0;
    for (std::uint64_t seed = 1; seed <= 5; ++seed) {
        auto go = options_for(24, 16, seed, 300);
        go.counts.push_back({{2}, 3, -1, "pillar"});
        auto g = make_generator(rareModel, go);
        REQUIRE_MESSAGE(g->run() == wfc::GenStatus::Done, g->failure_message());
        CHECK(count_of(g->output(), 2) >= 3);
        pinnedAny += g->stats().pinned;
    }
    CHECK(pinnedAny > 0);

    // An exact count of zero is a ban that is checked at the end.
    auto go = options_for(20, 14, 2, 400);
    go.counts.push_back({{1}, 0, 0, "wall"});
    auto none = make_generator(model, go);
    if (none->run() == wfc::GenStatus::Done) CHECK(count_of(none->output(), 1) == 0);
    else CHECK(none->failure_message().find("at most 0") != std::string::npos);
}

TEST_CASE("wfc constraints: the same constraints and seed give the same grid; pins are derived from the seed") {
    Rows rare = kRooms;
    rare[3][4] = 'o';
    auto model = overlapping(rare, 3, 1, false);
    auto build = [&] {
        auto go = options_for(30, 18, 9, 300);
        go.cellRules.push_back({1, 1, {0}});
        go.cellRules.push_back({28, 16, {0}});
        go.counts.push_back({{2}, 2, 4, "pillar"});
        auto g = make_generator(model, go);
        REQUIRE_MESSAGE(g->run() == wfc::GenStatus::Done, g->failure_message());
        return std::make_pair(g->output(), g->stats().attempts);
    };
    const auto a = build(), b = build();
    CHECK(a.first == b.first);
    CHECK(a.second == b.second);
    CHECK(fingerprint(a.first) == fingerprint(b.first));
}

TEST_CASE("wfc constraints: contradictions are reported before generating") {
    auto model = overlapping(kRooms, 3, 1, false);
    auto refused = [&](wfc::GenerateOptions go, const char* part) {
        auto g = wfc::Generator::create(model, go);
        INFO("expected: " << std::string(part));
        REQUIRE_FALSE(g.ok());
        const std::string text = g.error().message + " | " + g.error().hint;
        CHECK_MESSAGE(text.find(part) != std::string::npos, text);
    };
    {
        auto go = options_for(20, 14, 1);
        go.counts.push_back({{1}, 5, 2, "wall"});
        refused(go, "greater than max");
    }
    {
        auto go = options_for(20, 14, 1);
        go.counts.push_back({{1}, 281, -1, "wall"});
        refused(go, "output has only 280");
    }
    {
        auto go = options_for(20, 14, 1);
        go.cellRules.push_back({0, 0, {1}});
        go.forbidden = {1};
        refused(go, "only barred tiles");
    }
    {
        auto go = options_for(20, 14, 1);
        go.cellRules.push_back({0, 0, {1}});
        go.cellRules.push_back({0, 0, {0}});
        refused(go, "shares no tile");
    }
    {
        auto go = options_for(20, 14, 1);
        for (int x = 0; x < 3; ++x) go.cellRules.push_back({x, 0, {1}});
        go.counts.push_back({{1}, 0, 2, "wall"});
        refused(go, "fixed cells already hold it");
    }
    {
        auto go = options_for(4, 4, 1);  // 16 cells, 14 fixed to floor: only two can hold walls
        for (int i = 0; i < 14; ++i) go.cellRules.push_back({i % 4, i / 4, {0}});
        go.counts.push_back({{1}, 3, -1, "wall"});
        refused(go, "only 2 cells can hold it");
    }
    {
        auto go = options_for(20, 14, 1);  // `required` against a `max: 0` of the same tile
        go.counts.push_back({{1}, 1, -1, "/constraints/required/0"});
        go.counts.push_back({{1}, 0, 0, "/constraints/counts/0"});
        refused(go, "capped at 0 by Count rule 1 (/constraints/counts/0)");
    }
    {
        auto go = options_for(20, 14, 1);  // a minimum above another rule's maximum over the same tiles
        go.counts.push_back({{1}, 6, -1, "/constraints/counts/0"});
        go.counts.push_back({{0, 1}, 0, 4, "/constraints/counts/1"});
        refused(go, "allows at most 4");
    }
    {
        // 'o' is shown only in the bottom-right corner of a window: in a level that does not wrap it can only be the last cell.
        auto corner = overlapping({"...", "...", "..o"}, 2, 1, false);
        auto go = options_for(10, 6, 1);
        go.cellRules.push_back({0, 0, {1}, "/constraints/fixed/0"});
        auto g = wfc::Generator::create(corner, go);
        REQUIRE_FALSE(g.ok());
        CHECK(g.error().message.find("no pattern of the model can put it there") != std::string::npos);
        CHECK(g.error().message.find("/constraints/fixed/0") != std::string::npos);
        go.cellRules[0].x = 9;
        go.cellRules[0].y = 5;
        CHECK(wfc::Generator::create(corner, go).ok());
    }
    {
        // 'o' is only ever shown between two '#': forbidding '#' leaves no pattern that can hold it.
        auto flanked = overlapping({"........", "..#o#...", "........"}, 2, 1, false);
        auto go = options_for(10, 6, 1);
        go.cellRules.push_back({4, 3, {2}, "/constraints/fixed/0"});
        go.forbidden = {1};
        auto g = wfc::Generator::create(flanked, go);
        REQUIRE_FALSE(g.ok());
        CHECK(g.error().message.find("also holds a forbidden tile") != std::string::npos);
        CHECK(g.error().message.find("/constraints/fixed/0") != std::string::npos);
    }
    {
        auto go = options_for(20, 14, 1);  // the symbol exists in the grammar of the model but no pattern holds it
        auto m2 = std::make_shared<wfc::PatternModel>(*model);
        m2->symbolCount = 3;
        go.counts.push_back({{2}, 1, -1, "ghost"});
        auto g = wfc::Generator::create(m2, go);
        REQUIRE_FALSE(g.ok());
        CHECK(g.error().message.find("no pattern of the model holds it") != std::string::npos);
    }
}

// ------------------------------------------------------------------------------------------------ work cap and memory (M63.2 fixes)

TEST_CASE("wfc work: maxWork ends a run at the same point however the steps are sized") {
    auto model = overlapping(kMap16, 3, 1, true);
    auto make = [&](std::int64_t maxWork) {
        auto go = options_for(64, 64, 5, 10);
        go.periodic = true;
        go.maxWork = maxWork;
        return make_generator(model, go);
    };
    // Completed runs: the same output and work with small and big steps.
    auto whole = make(0);
    REQUIRE(whole->run() == wfc::GenStatus::Done);
    auto small = make(0);
    while (small->step(7) == wfc::GenStatus::Running) {
    }
    CHECK(small->status() == wfc::GenStatus::Done);
    CHECK(small->output() == whole->output());
    CHECK(small->stats().work == whole->stats().work);
    CHECK(whole->stats().work > 4096);

    // A cap below what the level needs: the same failure whichever way it is stepped.
    const std::int64_t cap = whole->stats().work / 2;
    auto a = make(cap);
    CHECK(a->run() == wfc::GenStatus::Failed);
    auto b = make(cap);
    while (b->step(1) == wfc::GenStatus::Running) {
    }
    CHECK(b->status() == wfc::GenStatus::Failed);
    CHECK(a->failure().workLimit);
    CHECK(b->failure().workLimit);
    CHECK(a->stats().work == b->stats().work);
    CHECK(a->stats().work > cap);
    CHECK(a->failure_message().find("work limit") != std::string::npos);
    CHECK(a->failure_hint().find("work limit") != std::string::npos);

    // A cap that is enough does not change the result.
    auto enough = make(whole->stats().work);
    REQUIRE(enough->run() == wfc::GenStatus::Done);
    CHECK(enough->output() == whole->output());
}

TEST_CASE("wfc work: accept's own cost counts toward maxWork") {
    auto model = overlapping(kRooms, 3, 1, false);
    auto go = options_for(20, 14, 1, 1000);
    go.maxWork = 100000;
    int calls = 0;
    go.accept = [&](const std::vector<int>&, std::string& why, std::int64_t& work) {
        ++calls;
        work += 50000;   // an expensive check
        why = "never good enough";
        return false;
    };
    auto g = make_generator(model, go);
    CHECK(g->run() == wfc::GenStatus::Failed);
    CHECK(g->failure().workLimit);
    CHECK(calls >= 1);
    CHECK(calls < 10);   // the cap stopped the retries long before maxAttempts
}

TEST_CASE("wfc memory: the estimate saturates and is checked before anything is allocated") {
    auto model = overlapping(kMap16, 3, 1, true);
    const std::uint64_t huge = wfc::estimate_generator_memory(*model, 2000000000, 2000000000, true);
    CHECK(huge > wfc::kWfcMemoryBudget);
    CHECK(huge >= wfc::estimate_generator_memory(*model, 2048, 2048, true));
    auto checked = wfc::check_generator_memory(*model, 2048, 2048, false);
    REQUIRE_FALSE(checked.ok());
    CHECK(checked.error().message.find("MB") != std::string::npos);
    CHECK(checked.error().hint.find(" x ") != std::string::npos);
    CHECK(wfc::check_generator_memory(*model, 64, 64, true).ok());
    // The extra the caller holds counts.
    CHECK_FALSE(wfc::check_generator_memory(*model, 64, 64, true, wfc::kWfcMemoryBudget).ok());

    // A huge number of fixed cells is refused by create() fast, without a per-cell map.
    auto go = options_for(256, 256, 1);
    for (int i = 0; i < 70000; ++i) go.cellRules.push_back({i % 256, (i / 256) % 256, {0}});
    auto g = wfc::Generator::create(model, go);
    REQUIRE_FALSE(g.ok());
    CHECK(g.error().message.find("cells are fixed") != std::string::npos);
}

TEST_CASE("wfc phases: a step ends within one chunk of its budget, even while an attempt starts or finishes") {
    auto model = overlapping(kMap16, 3, 1, true);
    auto go = options_for(160, 160, 3, 10);
    go.periodic = true;
    // A big grid: resetting its 25600 cells, building the output and counting it each used to be one piece of work.
    go.counts.push_back({{0}, 1, -1, "ground"});
    auto g = make_generator(model, go);
    std::int64_t before = 0, widest = 0;
    int steps = 0;
    while (g->step(1) == wfc::GenStatus::Running) {
        widest = std::max(widest, g->stats().work - before);
        before = g->stats().work;
        ++steps;
    }
    REQUIRE(g->status() == wfc::GenStatus::Done);
    CHECK(steps > 100);
    // One chunk is about 16384 units; a propagated cell or an observed cell is small beside it.
    CHECK(widest <= 2 * 16384 + 4096);
    // and the cut does not change the level
    auto whole = make_generator(model, go);
    REQUIRE(whole->run() == wfc::GenStatus::Done);
    CHECK(whole->output() == g->output());
    CHECK(whole->stats().work == g->stats().work);
}

TEST_CASE("wfc phases: the first flush of a fresh attempt (every cell dirty) is cut into chunks on a big grid") {
    auto model = overlapping(kMap16, 3, 1, true);
    auto go = options_for(256, 256, 3, 1);   // 65536 cells: far more than one chunk of 16384
    go.periodic = true;
    auto g = make_generator(model, go);
    std::int64_t before = 0, widest = 0;
    int steps = 0;
    // up to the first observed cell: the reset, the rules and the flush that gives every cell its heap entry
    while (g->status() == wfc::GenStatus::Running && g->stats().observations == 0 && steps < 100000) {
        g->step(1);
        widest = std::max(widest, g->stats().work - before);
        before = g->stats().work;
        ++steps;
    }
    REQUIRE(g->stats().observations > 0);
    CHECK(g->stats().heapPeak >= 65536u);   // every cell did get its entry
    // 65536 cells in one piece would be 65536 units (stamps) and again as many (entries); a chunk is about 16384
    CHECK(widest <= 2 * 16384 + 4096);
    CHECK(steps > 4 * 4);
}

TEST_CASE("wfc check: a GridCheck runs in pieces, counts its work and can refuse") {
    struct Walls : wfc::GridCheck {
        int begun = 0, steps = 0;
        std::size_t seen = 0;
        const std::vector<int>* grid = nullptr;
        void begin(const std::vector<int>& cells) override {
            ++begun;
            grid = &cells;
            seen = 0;
        }
        Verdict step(std::int64_t chunk, std::string& why, std::int64_t& work) override {
            ++steps;
            const std::size_t to = std::min(grid->size(), seen + std::size_t(std::min<std::int64_t>(chunk, 100)));   // 100 cells at a time
            work += std::int64_t(to - seen);
            seen = to;
            if (seen < grid->size()) return Verdict::More;
            int walls = 0;
            for (int c : *grid) walls += c == 1;
            if (walls >= 40) return Verdict::Accepted;
            why = "only " + std::to_string(walls) + " wall cells";
            return Verdict::Refused;
        }
    };
    auto model = overlapping(kRooms, 3, 1, false);
    auto check = std::make_shared<Walls>();
    auto go = options_for(30, 20, 2, 400);
    go.check = check;
    auto g = make_generator(model, go);
    while (g->step(5) == wfc::GenStatus::Running) {
    }
    REQUIRE_MESSAGE(g->status() == wfc::GenStatus::Done, g->failure_message());
    CHECK(count_of(g->output(), 1) >= 40);
    CHECK(check->begun == g->stats().attempts - g->stats().contradictions);   // asked once per finished grid
    CHECK(check->steps >= check->begun * 6);                                  // 600 cells, 100 per call: it said More five times each
    CHECK(g->stats().attempts == g->stats().contradictions + g->stats().rejected + 1);

    // the same level whether stepped finely or run
    auto again = std::make_shared<Walls>();
    auto go2 = options_for(30, 20, 2, 400);
    go2.check = again;
    auto h = make_generator(model, go2);
    REQUIRE(h->run() == wfc::GenStatus::Done);
    CHECK(h->output() == g->output());
    CHECK(h->stats().work == g->stats().work);

    // always refusing: Failed with the check's reason
    struct Never : wfc::GridCheck {
        void begin(const std::vector<int>&) override {}
        Verdict step(std::int64_t, std::string& why, std::int64_t&) override {
            why = "not enough treasure";
            return Verdict::Refused;
        }
    };
    auto go3 = options_for(12, 12, 1, 3);
    go3.check = std::make_shared<Never>();
    auto n = make_generator(model, go3);
    CHECK(n->run() == wfc::GenStatus::Failed);
    CHECK(n->failure_message().find("not enough treasure") != std::string::npos);
}

TEST_CASE("wfc constraints: pinMissing false leaves a missed minimum to the retries") {
    Rows rare = kRooms;
    rare[3][4] = 'o';
    auto rareModel = overlapping(rare, 3, 1, false);
    int pinned = 0, pinnedOff = 0;
    for (std::uint64_t seed = 1; seed <= 5; ++seed) {
        auto go = options_for(24, 16, seed, 300);
        go.counts.push_back({{2}, 3, -1, "pillar"});
        auto on = make_generator(rareModel, go);
        on->run();
        pinned += on->stats().pinned;
        go.pinMissing = false;
        auto off = make_generator(rareModel, go);
        off->run();
        pinnedOff += off->stats().pinned;
        if (off->status() == wfc::GenStatus::Done) CHECK(count_of(off->output(), 2) >= 3);   // a grid with 3 turned up by chance
    }
    CHECK(pinned > 0);
    CHECK(pinnedOff == 0);
}

TEST_CASE("wfc constraints: a maximum steers the solver instead of waiting for the finished grid") {
    // The lone 'o' of the sample is a rare tile; with a maximum of 2 the solver stops handing it out once two are decided.
    Rows rare = kRooms;
    rare[3][4] = 'o';
    rare[6][8] = 'o';  // kRooms is 10 x 8: row and column stay inside it
    auto rareModel = overlapping(rare, 3, 1, false);
    int rejected = 0, runs = 0;
    for (std::uint64_t seed = 1; seed <= 12; ++seed) {
        auto go = options_for(40, 30, seed, 40);
        go.counts.push_back({{2}, 0, 2, "pillar"});
        auto g = make_generator(rareModel, go);
        REQUIRE_MESSAGE(g->run() == wfc::GenStatus::Done, g->failure_message());
        CHECK(count_of(g->output(), 2) <= 2);
        CHECK(g->stats().symbolCounts[2] == count_of(g->output(), 2));
        rejected += g->stats().rejected;
        ++runs;
        // the same seed, the same level, stepped finely
        auto h = make_generator(rareModel, go);
        while (h->step(7) == wfc::GenStatus::Running) {
        }
        CHECK(h->output() == g->output());
        CHECK(h->stats().work == g->stats().work);
    }
    // the steering keeps nearly every attempt from being refused for its count
    CHECK(rejected <= runs);

    // Wall cells of the rooms sample: a tight maximum on a common symbol still comes out right, and on a periodic grid too.
    auto model = overlapping(kRooms, 3, 1, false);
    for (bool periodic : {false, true}) {
        auto go = options_for(24, 16, 3, 300);
        go.periodic = periodic;
        go.counts.push_back({{1}, 0, 70, "wall"});
        auto g = make_generator(model, go);
        REQUIRE_MESSAGE(g->run() == wfc::GenStatus::Done, g->failure_message());
        CHECK(count_of(g->output(), 1) <= 70);
    }

    // A maximum that is impossible says so after the cells already decided hold more than it allows, not only on the finished grid.
    auto go = options_for(20, 14, 2, 3);
    go.counts.push_back({{0}, 0, 1, "floor"});
    auto none = make_generator(model, go);
    CHECK(none->run() == wfc::GenStatus::Failed);
    CHECK(none->failure_hint().find("higher maximums") != std::string::npos);
}

TEST_CASE("wfc progress: follows the solver inside an attempt and never goes down across attempts") {
    auto model = overlapping(kRooms, 3, 1, false);
    // Many refused attempts: a check that refuses the first four finished grids.
    struct Late : wfc::GridCheck {
        int seen = 0;
        void begin(const std::vector<int>&) override { ++seen; }
        Verdict step(std::int64_t, std::string& why, std::int64_t&) override {
            if (seen > 4) return Verdict::Accepted;
            why = "not yet";
            return Verdict::Refused;
        }
    };
    auto go = options_for(30, 20, 2, 20);
    go.check = std::make_shared<Late>();
    auto g = make_generator(model, go);
    double last = 0;
    bool inside = false;
    int attemptsSeen = 0;
    while (g->step(50) == wfc::GenStatus::Running) {
        const double p = g->progress();
        CHECK(p >= last);
        CHECK(p < 1.0);
        if (p > last && p < 0.8 && last > 0) inside = true;   // moved within the first attempt
        last = p;
        attemptsSeen = g->stats().attempts;
    }
    CHECK(inside);
    CHECK(attemptsSeen >= 5);
    CHECK(last > 0.85);   // the later attempts moved it too
    CHECK(g->progress() == 1.0);
}

TEST_CASE("wfc finish: a GridFinish changes the finished grid in pieces and can refuse it") {
    struct Mark : wfc::GridFinish {
        std::vector<int>* grid = nullptr;
        std::size_t at = 0;
        std::uint64_t seed = 0;
        int begun = 0;
        void begin(std::vector<int>& cells, std::uint64_t s) override {
            grid = &cells;
            at = 0;
            seed = s;
            ++begun;
        }
        wfc::GridCheck::Verdict step(std::int64_t, std::string&, std::int64_t& work) override {
            const std::size_t to = std::min(grid->size(), at + 50);
            for (; at < to; ++at)
                if (at % 97 == 0) (*grid)[at] = 1;
            work += 50;
            return at < grid->size() ? wfc::GridCheck::Verdict::More : wfc::GridCheck::Verdict::Accepted;
        }
    };
    auto model = overlapping(kRooms, 3, 1, false);
    auto mark = std::make_shared<Mark>();
    auto go = options_for(30, 20, 5, 20);
    go.finish = mark;
    auto g = make_generator(model, go);
    REQUIRE_MESSAGE(g->run() == wfc::GenStatus::Done, g->failure_message());
    CHECK(mark->begun == 1);
    CHECK(mark->seed == g->stats().seedUsed);
    CHECK(g->output()[0] == 1);
    CHECK(g->output()[97] == 1);
    CHECK(g->stats().symbolCounts[1] == count_of(g->output(), 1));   // counted after the finish

    struct Never : wfc::GridFinish {
        void begin(std::vector<int>&, std::uint64_t) override {}
        wfc::GridCheck::Verdict step(std::int64_t, std::string& why, std::int64_t&) override {
            why = "no room for the exit";
            return wfc::GridCheck::Verdict::Refused;
        }
    };
    auto go2 = options_for(12, 12, 1, 3);
    go2.finish = std::make_shared<Never>();
    auto n = make_generator(model, go2);
    CHECK(n->run() == wfc::GenStatus::Failed);
    CHECK(n->failure_message().find("no room for the exit") != std::string::npos);
}
