// QuadList::flatten marks the batches it can draw with the lean quad_plain shader: only plain textured quads (mode 0, not
// lit, not multiply). Merging ignores it, so the number of draw calls never depends on it.
#include <doctest.h>

#include "render_internal.h"

using namespace fa;
using namespace fa::render;

namespace {

void add_item(QuadList& l, TextureAsset* tex, int layer, QuadMode mode, BlendMode blend = BlendMode::Alpha, bool lit = false) {
    l.begin_item(layer, 0, tex, SamplerKind::Nearest, blend);
    if (lit) l.set_lit(nullptr);
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
