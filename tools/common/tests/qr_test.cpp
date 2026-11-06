// The QR encoder: the standard's worked Reed-Solomon example, the format information bits, the matrix of two inputs
// checked against an independent encoder (macOS CoreImage), the structure of the symbol at every version, and the limits.
#include <doctest.h>

#include <string>
#include <vector>

#include "fa/tooling/qr.h"

using namespace fa;

namespace {

// Format information read back from the first copy around the top left finder, bit 0 first (ISO 18004, 7.9).
std::uint32_t read_format_copy1(const QrCode& q) {
    std::uint32_t bits = 0;
    auto put = [&](int i, int x, int y) { bits |= static_cast<std::uint32_t>(q.dark(x, y) ? 1 : 0) << i; };
    for (int i = 0; i <= 5; ++i) put(i, 8, i);
    put(6, 8, 7);
    put(7, 8, 8);
    put(8, 7, 8);
    for (int i = 9; i < 15; ++i) put(i, 14 - i, 8);
    return bits;
}

std::uint32_t read_format_copy2(const QrCode& q) {
    std::uint32_t bits = 0;
    auto put = [&](int i, int x, int y) { bits |= static_cast<std::uint32_t>(q.dark(x, y) ? 1 : 0) << i; };
    for (int i = 0; i < 8; ++i) put(i, q.size - 1 - i, 8);
    for (int i = 8; i < 15; ++i) put(i, 8, q.size - 15 + i);
    return bits;
}

}  // namespace

TEST_CASE("qr: Reed-Solomon of the standard's HELLO WORLD example (1-M)") {
    const std::vector<std::uint8_t> data = {32, 91, 11, 120, 209, 114, 220, 77, 67, 64, 236, 17, 236, 17, 236, 17};
    const std::vector<std::uint8_t> expected = {196, 35, 39, 119, 235, 215, 231, 226, 93, 23};
    CHECK(qr_reed_solomon(data, 10) == expected);
    CHECK(qr_reed_solomon({}, 4) == std::vector<std::uint8_t>(4, 0));
}

TEST_CASE("qr: format information bits") {
    CHECK(qr_format_bits(QrEcc::Medium, 0) == 0x5412);
    CHECK(qr_format_bits(QrEcc::Low, 0) == 0x77C4);
    CHECK(qr_format_bits(QrEcc::High, 7) == 0x083B);
    CHECK(qr_format_bits(QrEcc::Quartile, 5) == 0x2183);
}

TEST_CASE("qr: capacities in byte mode") {
    CHECK(qr_capacity_bytes(1, QrEcc::Low) == 17);
    CHECK(qr_capacity_bytes(1, QrEcc::Medium) == 14);
    CHECK(qr_capacity_bytes(1, QrEcc::Quartile) == 11);
    CHECK(qr_capacity_bytes(1, QrEcc::High) == 7);
    CHECK(qr_capacity_bytes(10, QrEcc::Medium) == 213);
    CHECK(qr_capacity_bytes(40, QrEcc::Low) == 2953);
    CHECK(qr_capacity_bytes(40, QrEcc::Medium) == 2331);
    CHECK(qr_capacity_bytes(40, QrEcc::Quartile) == 1663);
    CHECK(qr_capacity_bytes(40, QrEcc::High) == 1273);
    CHECK(qr_capacity_bytes(0, QrEcc::Low) == 0);
    CHECK(qr_capacity_bytes(41, QrEcc::Low) == 0);
}

TEST_CASE("qr: the matrix of \"hello world\" at M equals an independent encoder's") {
    auto r = qr_encode("hello world", QrEcc::Medium);
    REQUIRE(r.ok());
    CHECK(r->version == 1);
    CHECK(r->size == 21);
    CHECK(r->mask == 2);
    const std::vector<std::string> expected = {
        "#######..#.##.#######", "#.....#...#...#.....#", "#.###.#.####..#.###.#", "#.###.#.###.#.#.###.#",
        "#.###.#.#.#.#.#.###.#", "#.....#.#..#..#.....#", "#######.#.#.#.#######", "........#.#..........",
        "#.#####..#.#..#####..", ".##.##.#.#.########.#", "#.#.####.##.###..###.", "#.#..#...#.###..###..",
        "...#.#####..###.....#", "........#.#.#...##..#", "#######....#..#...##.", "#.....#.#....#.#.####",
        "#.###.#.#..#..##....#", "#.###.#.##..######...", "#.###.#.##..#..#..#..", "#.....#..##.##..###..",
        "#######.##.##.#.#..#.",
    };
    CHECK(r->rows() == expected);
}

TEST_CASE("qr: the matrix of a version 2 URL at M equals an independent encoder's") {
    auto r = qr_encode("http://host.local/play-it/", QrEcc::Medium);
    REQUIRE(r.ok());
    CHECK(r->version == 2);
    CHECK(r->size == 25);
    CHECK(r->mask == 2);
    const std::vector<std::string> expected = {
        "#######...#..#....#######", "#.....#....#.###..#.....#", "#.###.#.#####.###.#.###.#",
        "#.###.#.####.##...#.###.#", "#.###.#.##....#.#.#.###.#", "#.....#.#......##.#.....#",
        "#######.#.#.#.#.#.#######", "........#.#.#..#.........", "#.#####..#.#####..#####..",
        ".##.....#....#..##.#...#.", "#######...#.#.###.####.##", ".#.##......##....#.##...#",
        "#...#.##.##.####.##.#.###", "##.#.#..#...#...##.#.#.#.", "#..##.#........####..#.##",
        "#.#..#.#.#.#..#.#.#.##..#", "#.#####...#####.#####.#..", "........#.#######...###..",
        "#######..##.#...#.#.#####", "#.....#.#.....#.#...##...", "#.###.#.#.#..#.########..",
        "#.###.#.####.#.#..#.#.###", "#.###.#.#.#...#.#..#..#.#", "#.....#...#.#.####.###..#",
        "#######.#..####....######",
    };
    CHECK(r->rows() == expected);
}

TEST_CASE("qr: the symbol's fixed structure at every version and level") {
    const QrEcc levels[] = {QrEcc::Low, QrEcc::Medium, QrEcc::Quartile, QrEcc::High};
    for (QrEcc ecc : levels) {
        for (int v : {1, 2, 6, 7, 14, 21, 27, 33, 40}) {
            const std::string text = "a.co/p";
            auto r = qr_encode(text, ecc, v);
            REQUIRE(r.ok());
            CAPTURE(v);
            CHECK(r->version == v);
            CHECK(r->size == 17 + 4 * v);
            CHECK(r->modules.size() == static_cast<std::size_t>(r->size) * static_cast<std::size_t>(r->size));
            // Finder patterns: a 7x7 ring with a 3x3 core, in three corners, with a light separator.
            const int corners[3][2] = {{0, 0}, {r->size - 7, 0}, {0, r->size - 7}};
            for (auto& c : corners) {
                for (int dy = 0; dy < 7; ++dy)
                    for (int dx = 0; dx < 7; ++dx) {
                        const bool ring = dx == 0 || dx == 6 || dy == 0 || dy == 6;
                        const bool core = dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4;
                        CHECK(r->dark(c[0] + dx, c[1] + dy) == (ring || core));
                    }
            }
            // Timing patterns alternate between the finders.
            for (int i = 8; i < r->size - 8; ++i) {
                CHECK(r->dark(i, 6) == (i % 2 == 0));
                CHECK(r->dark(6, i) == (i % 2 == 0));
            }
            // The always-dark module, and both copies of the format information.
            CHECK(r->dark(8, r->size - 8));
            const std::uint32_t fmt = qr_format_bits(ecc, r->mask);
            CHECK(read_format_copy1(*r) == fmt);
            CHECK(read_format_copy2(*r) == fmt);
        }
    }
}

TEST_CASE("qr: the smallest version that fits is chosen and the result is deterministic") {
    auto a = qr_encode(std::string(14, 'a'), QrEcc::Medium);
    auto b = qr_encode(std::string(15, 'a'), QrEcc::Medium);
    REQUIRE(a.ok());
    REQUIRE(b.ok());
    CHECK(a->version == 1);
    CHECK(b->version == 2);
    auto a2 = qr_encode(std::string(14, 'a'), QrEcc::Medium);
    CHECK(a2->modules == a->modules);
    // Every capacity boundary fits exactly in its version and not in the one below.
    for (int v = 1; v <= 40; v += 3) {
        const int cap = qr_capacity_bytes(v, QrEcc::Quartile);
        auto fit = qr_encode(std::string(static_cast<std::size_t>(cap), 'x'), QrEcc::Quartile);
        REQUIRE(fit.ok());
        CHECK(fit->version == v);
    }
    // Any bytes, including zero bytes and the high half.
    std::string bin;
    for (int i = 0; i < 100; ++i) bin.push_back(static_cast<char>(i * 7));
    CHECK(qr_encode(bin, QrEcc::Low).ok());
}

TEST_CASE("qr: too much data is an error that says the limit") {
    auto r = qr_encode(std::string(2332, 'x'), QrEcc::Medium);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("2331") != std::string::npos);
    CHECK_FALSE(r.error().hint.empty());
    CHECK(qr_encode(std::string(2331, 'x'), QrEcc::Medium).ok());
    // A minimum version out of range is clamped, not an error.
    CHECK(qr_encode("x", QrEcc::Medium, 99)->version == 40);
    CHECK(qr_encode("x", QrEcc::Medium, 0)->version == 1);
}
