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
    open_ = true;
}

void QuadList::quad(const Vertex2D& a, const Vertex2D& b, const Vertex2D& c, const Vertex2D& d) {
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
        if (it.blend == BlendMode::Multiply)  // shader variant: output mix(1, rgb, a) for the multiply blend
            for (std::size_t i = std::size_t(firstQuad) * 4; i < out.size(); ++i) out[i].mode += 8.0f;
        if (!batches.empty() && batches.back().tex == it.tex && batches.back().smp == it.smp && batches.back().blend == it.blend &&
            batches.back().clip == it.clip && batches.back().firstQuad + batches.back().quadCount == firstQuad) {
            batches.back().quadCount += it.quadCount;
        } else {
            batches.push_back({firstQuad, it.quadCount, it.tex, it.smp, it.blend, it.clip});
        }
    }
}

void QuadEmitter::rect(float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1) const {
    auto v = [&](float x, float y, float u, float vv) {
        Vec3 p = xf(x, y);
        return Vertex2D{p.x, p.y, p.z, u, vv, color, mode, aux};
    };
    list.quad(v(x0, y1, u0, v0), v(x0, y0, u0, v1), v(x1, y0, u1, v1), v(x1, y1, u1, v0));
}

}  // namespace fa::render
