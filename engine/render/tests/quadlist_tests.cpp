// QuadList::flatten marks the batches it can draw with the lean quad_plain shader: only plain textured quads (mode 0, not
// lit, not multiply). Merging ignores it, so the number of draw calls never depends on it. It also marks the opaque
// batches (QuadList::set_opaque), drawn without blending; those only merge with each other.
#include <doctest.h>

#include "render_internal.h"

using namespace fa;
using namespace fa::render;

namespace {

void add_item(QuadList& l, TextureAsset* tex, int layer, QuadMode mode, BlendMode blend = BlendMode::Alpha, bool lit = false,
              bool opaque = false) {
    l.begin_item(layer, 0, tex, SamplerKind::Nearest, blend);
    if (lit) l.set_lit(nullptr);
    if (opaque) l.set_opaque();
    const Vertex2D v{0, 0, 0, 0, 0, 0xffffffffu, float(mode), 0};
    l.quad(v, v, v, v);
    l.end_item();
}

std::vector<QuadBatch> flatten(QuadList& l) {
    std::vector<Vertex2D> out;
    std::vector<QuadBatch> batches;
    l.flatten(out, batches);
    return batches;
}

}  // namespace

TEST_CASE("quadlist: batches of plain textured quads are marked plain, any other quad clears it") {
    TextureAsset tex;
    SUBCASE("textured quads only") {
        QuadList l;
        add_item(l, &tex, 0, kModeTextured);
        add_item(l, &tex, 1, kModeTextured);
        const auto b = flatten(l);
        REQUIRE(b.size() == 1);
        CHECK(b[0].quadCount == 2);
        CHECK(b[0].plain);
    }
    SUBCASE("a glyph or a circle merged in: one batch, drawn with the full shader") {
        for (QuadMode other : {kModeGlyph, kModeCircle}) {
            QuadList l;
            add_item(l, &tex, 0, kModeTextured);
            add_item(l, &tex, 1, other);
            const auto b = flatten(l);
            REQUIRE(b.size() == 1);
            CHECK(b[0].quadCount == 2);
            CHECK_FALSE(b[0].plain);
        }
    }
    SUBCASE("lit and multiply items are not plain") {
        QuadList l;
        add_item(l, &tex, 0, kModeTextured, BlendMode::Alpha, true);
        add_item(l, &tex, 1, kModeTextured, BlendMode::Multiply);
        add_item(l, &tex, 2, kModeTextured);
        const auto b = flatten(l);
        REQUIRE(b.size() == 3);
        CHECK_FALSE(b[0].plain);
        CHECK_FALSE(b[1].plain);
        CHECK(b[2].plain);
    }
}

TEST_CASE("quadlist: opaque items are drawn without blending, in batches of their own") {
    TextureAsset tex;
    SUBCASE("opaque items merge with each other") {
        QuadList l;
        add_item(l, &tex, 0, kModeTextured, BlendMode::Alpha, false, true);
        add_item(l, &tex, 1, kModeTextured, BlendMode::Alpha, false, true);
        const auto b = flatten(l);
        REQUIRE(b.size() == 1);
        CHECK(b[0].quadCount == 2);
        CHECK(b[0].opaque);
    }
    SUBCASE("an opaque item next to a blended one: two batches") {
        QuadList l;
        add_item(l, &tex, 0, kModeTextured);
        add_item(l, &tex, 1, kModeTextured, BlendMode::Alpha, false, true);
        add_item(l, &tex, 2, kModeTextured);
        const auto b = flatten(l);
        REQUIRE(b.size() == 3);
        CHECK_FALSE(b[0].opaque);
        CHECK(b[1].opaque);
        CHECK_FALSE(b[2].opaque);
    }
    SUBCASE("only the Alpha blend mode can drop blending") {
        QuadList l;
        add_item(l, &tex, 0, kModeTextured, BlendMode::Additive, false, true);
        add_item(l, &tex, 1, kModeTextured, BlendMode::Multiply, false, true);
        const auto b = flatten(l);
        REQUIRE(b.size() == 2);
        CHECK_FALSE(b[0].opaque);
        CHECK_FALSE(b[1].opaque);
    }
    SUBCASE("the next item starts blended again") {
        QuadList l;
        add_item(l, &tex, 0, kModeTextured, BlendMode::Alpha, false, true);
        add_item(l, &tex, 0, kModeGlyph);
        const auto b = flatten(l);
        REQUIRE(b.size() == 2);
        CHECK(b[0].opaque);
        CHECK_FALSE(b[1].opaque);
    }
}

TEST_CASE("float_to_half_bits: IEEE binary16 for the sizes a shape can have") {
    CHECK(float_to_half_bits(0.0f) == 0);
    CHECK(float_to_half_bits(-3.0f) == 0);
    CHECK(float_to_half_bits(1.0f) == 0x3C00);
    CHECK(float_to_half_bits(2.0f) == 0x4000);
    CHECK(float_to_half_bits(0.5f) == 0x3800);
    CHECK(float_to_half_bits(20.0f) == 0x4D00);
    CHECK(float_to_half_bits(1000.0f) == 0x63D0);
    CHECK(float_to_half_bits(1e9f) == 0x7BFF);  // saturates instead of becoming infinity
    CHECK(float_to_half_bits(1.9999f) == 0x4000);  // the mantissa carries into the exponent
}

TEST_CASE("A shape with rounded corners (mode 7) is not a plain quad and keeps its extra vertex data through flatten") {
    QuadList l;
    l.begin_item(0, 0, nullptr, SamplerKind::Nearest, BlendMode::Alpha);
    Vertex2D v{0, 0, 0, 0, 0, 0xffffffffu, float(kModeShape), -1.0f};
    v.halfW = 7.0f;
    l.quad(v, v, v, v);
    l.end_item();
    std::vector<Vertex2D> out;
    std::vector<QuadBatch> batches;
    l.flatten(out, batches);
    REQUIRE(batches.size() == 1);
    CHECK_FALSE(batches[0].plain);
    CHECK(out[0].halfW == 7.0f);
}
