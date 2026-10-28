#include <algorithm>
#include <cstring>

#include "frame.h"

namespace fa::render {

void QuadList::begin_item(int layer, float secondary, TextureAsset* tex, SamplerKind smp, BlendMode blend, const Rect& clip) {
    cur_ = QuadItem{};
    cur_.layer = layer;
    cur_.secondary = secondary;
    cur_.seq = seq_++;
    cur_.firstVert = std::uint32_t(raw.size());
    cur_.tex = tex;
    cur_.smp = smp;
    cur_.blend = blend;
    cur_.clip = clip;
    cur_.lit = false;
    cur_.normal = nullptr;
    cur_.plain = true;
    cur_.opaque = false;
    open_ = true;
}

void QuadList::quad(const Vertex2D& a, const Vertex2D& b, const Vertex2D& c, const Vertex2D& d) {
    if (a.mode != float(kModeTextured)) cur_.plain = false;  // the four corners of a quad share its mode
    raw.push_back(a);
    raw.push_back(b);
    raw.push_back(c);
    raw.push_back(d);
}

void QuadList::end_item() {
    if (!open_) return;
    open_ = false;
    cur_.quadCount = std::uint32_t(raw.size() - cur_.firstVert) / 4;
    if (cur_.quadCount > 0) items.push_back(cur_);
}

void QuadList::flatten(std::vector<Vertex2D>& out, std::vector<QuadBatch>& batches) {
    std::stable_sort(items.begin(), items.end(), [](const QuadItem& a, const QuadItem& b) {
        if (a.layer != b.layer) return a.layer < b.layer;
        if (a.secondary != b.secondary) return a.secondary > b.secondary;
        return a.seq < b.seq;
    });
    for (const QuadItem& it : items) {
        std::uint32_t firstQuad = std::uint32_t(out.size() / 4);
        out.insert(out.end(), raw.begin() + it.firstVert, raw.begin() + it.firstVert + std::size_t(it.quadCount) * 4);
        if (it.lit)  // shapes: textured / circle / ring quads of a lit item are shaded too (shader mode + 16)
            for (std::size_t i = std::size_t(firstQuad) * 4; i < out.size(); ++i)
                if (out[i].mode < float(kModeLit) || out[i].mode == float(kModeShape)) out[i].mode += 16.0f;
        if (it.blend == BlendMode::Multiply)  // shader variant: output mix(1, rgb, a) for the multiply blend
            for (std::size_t i = std::size_t(firstQuad) * 4; i < out.size(); ++i) out[i].mode += 8.0f;
        const bool plain = it.plain && !it.lit && it.blend != BlendMode::Multiply;
        const bool opaque = it.opaque && it.blend == BlendMode::Alpha;
        // Textures packed into one atlas share its GPU image, so their quads batch together.
        // Lit quads also need the same normal map, and (their uv transform depends on it) the same texture object.
        if (!batches.empty() && batches.back().tex->gpu_view().id == it.tex->gpu_view().id && batches.back().smp == it.smp &&
            batches.back().blend == it.blend && batches.back().clip == it.clip && batches.back().lit == it.lit &&
            (!it.lit || (batches.back().tex == it.tex && batches.back().normal == it.normal)) &&
            batches.back().opaque == opaque && batches.back().firstQuad + batches.back().quadCount == firstQuad) {
            batches.back().quadCount += it.quadCount;
            batches.back().plain = batches.back().plain && plain;
        } else {
            batches.push_back({firstQuad, it.quadCount, it.tex, it.smp, it.blend, it.clip, it.lit, it.normal, plain, opaque});
        }
    }
}

void QuadEmitter::rect(float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1) const {
    rect_uv(x0, y0, x1, y1, {{u0, v0}, {u0, v1}, {u1, v1}, {u1, v0}});
}

void QuadEmitter::rect_uv(float x0, float y0, float x1, float y1, const Vec2 (&uv)[4]) const {
    auto v = [&](float x, float y, Vec2 t) {
        Vec3 p = xf(x, y);
        return Vertex2D{p.x, p.y, p.z, t.x, t.y, color, mode, aux};
    };
    list.quad(v(x0, y1, uv[0]), v(x0, y0, uv[1]), v(x1, y0, uv[2]), v(x1, y1, uv[3]));
}

}  // namespace fa::render
