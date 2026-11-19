// QuadList::flatten marks the batches it can draw with the lean quad_plain shader: only plain textured quads (mode 0, not
// lit, not multiply). Merging ignores it, so the number of draw calls never depends on it. It also marks the opaque
// batches (QuadList::set_opaque), drawn without blending; those only merge with each other.
#include <doctest.h>

#include "render_internal.h"

using namespace fa;
using namespace fa::render;

namespace {

void add_item(QuadList& l, TextureAsset* tex, int layer, QuadMode mode, BlendMode blend = BlendMode::Alpha,
              bool lit = false, bool opaque = false) {
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
    CHECK(float_to_half_bits(1e9f) == 0x7BFF);     // saturates instead of becoming infinity
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

// ---------------------------------------------------------------------------------------------------------------------------------
// Per-quad instanced values of a sprite material (M72.1): QuadList::inst, remapped by append and append_items, and
// copied four times per quad into the stream flatten() is given.
// ---------------------------------------------------------------------------------------------------------------------------------
namespace {

// An item of `quads` quads with `use`, whose instanced values are base, base + 1, ... (use->instVec4 * 4 of them).
void inst_item(QuadList& l, TextureAsset* tex, const MaterialUse* use, float base, int layer = 0, int quads = 1) {
    l.begin_item(layer, 0, tex, SamplerKind::Nearest, BlendMode::Alpha);
    MaterialRef ref;
    ref.use = use;
    for (int k = 0; k < use->instVec4 * 4; ++k) ref.inst[k] = base + float(k);
    l.set_material(ref);
    const Vertex2D v{0, 0, 0, 0, 0, 0xffffffffu, float(kModeTextured), 0};
    for (int q = 0; q < quads; ++q) l.quad(v, v, v, v);
    l.end_item();
}

MaterialUse make_use(int instVec4) {
    MaterialUse u;
    u.instVec4 = instVec4;
    return u;
}

// True when `stream` holds, from `at`, `vertices` copies of base, base + 1, ... (`floats` of them).
bool copies_of(const std::vector<float>& stream, std::size_t at, std::size_t vertices, std::size_t floats, float base) {
    if (stream.size() < at + vertices * floats) return false;
    for (std::size_t v = 0; v < vertices; ++v)
        for (std::size_t k = 0; k < floats; ++k)
            if (stream[at + v * floats + k] != base + float(k)) return false;
    return true;
}

}  // namespace

TEST_CASE("quadlist: 20000 one-quad items with instanced values are one batch, contiguous and in order") {
    TextureAsset tex;
    const MaterialUse use = make_use(3);
    QuadList l;
    constexpr int kItems = 20000;
    for (int i = 0; i < kItems; ++i) inst_item(l, &tex, &use, float(i * 100));
    std::vector<Vertex2D> out;
    std::vector<QuadBatch> batches;
    std::vector<float> inst;
    l.flatten(out, batches, &inst);
    REQUIRE(batches.size() == 1);
    CHECK(batches[0].quadCount == kItems);
    CHECK(batches[0].instFirst == 0);
    REQUIRE(inst.size() == std::size_t(kItems) * 4 * 12);
    bool ok = true;
    for (int i = 0; i < kItems && ok; ++i) ok = copies_of(inst, std::size_t(i) * 4 * 12, 4, 12, float(i * 100));
    CHECK(ok);
}

TEST_CASE("quadlist: batches of different materials start where their own instanced values start") {
    TextureAsset tex;
    const MaterialUse a = make_use(1), b = make_use(2);
    QuadList l;
    inst_item(l, &tex, &a, 10, 0, 2);  // 2 quads of A
    inst_item(l, &tex, &a, 20, 0, 1);  // the same batch
    inst_item(l, &tex, &b, 30, 1, 1);  // B
    inst_item(l, &tex, &a, 40, 2, 1);  // A again, a batch of its own
    std::vector<Vertex2D> out;
    std::vector<QuadBatch> batches;
    std::vector<float> inst;
    l.flatten(out, batches, &inst);
    REQUIRE(batches.size() == 3);
    CHECK(batches[0].quadCount == 3);
    CHECK(batches[0].instFirst == 0);
    CHECK(batches[1].use == &b);
    CHECK(batches[1].instFirst == 3 * 4 * 4);
    CHECK(batches[2].use == &a);
    CHECK(batches[2].instFirst == 3 * 4 * 4 + 4 * 8);
    CHECK(copies_of(inst, 0, 8, 4, 10));
    CHECK(copies_of(inst, 8 * 4, 4, 4, 20));
    CHECK(copies_of(inst, 12 * 4, 4, 8, 30));
    CHECK(copies_of(inst, 12 * 4 + 4 * 8, 4, 4, 40));
    CHECK(inst.size() == 12 * 4 + 4 * 8 + 4 * 4);
    // an item with no instanced values adds nothing, and the stream is optional
    QuadList plain;
    add_item(plain, &tex, 0, kModeTextured);
    std::vector<float> none;
    std::vector<QuadBatch> pb;
    plain.flatten(out, pb, &none);
    CHECK(none.empty());
    QuadList again;
    inst_item(again, &tex, &a, 1);
    std::vector<QuadBatch> ab;
    again.flatten(out, ab);
    CHECK(ab.size() == 1);
}

TEST_CASE("quadlist: append and append_items keep the instanced values of the items they bring") {
    TextureAsset tex;
    const MaterialUse a = make_use(1), b = make_use(3);
    SUBCASE("append of a part") {
        QuadList l;
        inst_item(l, &tex, &a, 1, 0);
        QuadList part;
        inst_item(part, &tex, &b, 100, 1);
        inst_item(part, &tex, &a, 200, 2);
        l.append(part);
        std::vector<Vertex2D> out;
        std::vector<QuadBatch> batches;
        std::vector<float> inst;
        l.flatten(out, batches, &inst);
        REQUIRE(batches.size() == 3);
        CHECK(copies_of(inst, 0, 4, 4, 1));
        CHECK(copies_of(inst, 16, 4, 12, 100));
        CHECK(copies_of(inst, 16 + 48, 4, 4, 200));
        CHECK(batches[1].instFirst == 16);
        CHECK(batches[2].instFirst == 16 + 48);
    }
    SUBCASE("append_items of a range of another list, twice") {
        QuadList src;
        inst_item(src, &tex, &a, 1, 0);
        inst_item(src, &tex, &b, 100, 1);
        inst_item(src, &tex, &a, 200, 2);
        QuadList l;
        inst_item(l, &tex, &a, 7, 0);
        const std::size_t first = l.append_items(src, 1, 2);
        CHECK(first == 1);
        l.append_items(src, 2, 1);
        std::vector<Vertex2D> out;
        std::vector<QuadBatch> batches;
        std::vector<float> inst;
        l.flatten(out, batches, &inst);
        // layer 0 the own item of A, layer 1 B, layer 2 two copies of the item of A with 200
        REQUIRE(batches.size() == 3);
        CHECK(copies_of(inst, 0, 4, 4, 7));
        CHECK(copies_of(inst, 16, 4, 12, 100));
        CHECK(copies_of(inst, 16 + 48, 8, 4, 200));
        CHECK(batches[2].quadCount == 2);
        // the source is untouched
        std::vector<QuadBatch> sb;
        std::vector<float> sinst;
        src.flatten(out, sb, &sinst);
        CHECK(copies_of(sinst, 0, 4, 4, 1));
        CHECK(copies_of(sinst, 16, 4, 12, 100));
    }
}
