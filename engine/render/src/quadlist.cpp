#include <algorithm>
#include <cstring>

#include "frame.h"
#include "render_jobs.h"

namespace fa::render {

void QuadList::begin_item(int layer, float secondary, TextureAsset* tex, SamplerKind smp, BlendMode blend,
                          const Rect& clip) {
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

void QuadList::append(QuadList& part) {
    const std::uint32_t base = std::uint32_t(raw.size());
    items.reserve(items.size() + part.items.size());
    for (QuadItem it : part.items) {
        it.firstVert += base;
        it.seq = seq_++;  // the part's items keep their order among themselves and come after this list's
        items.push_back(it);
    }
    raw.insert(raw.end(), part.raw.begin(), part.raw.end());
    part.clear();
}

void QuadList::add_quads_of(const QuadList& part) {
    if (!open_ || part.raw.size() <= part.cur_.firstVert) return;
    raw.insert(raw.end(), part.raw.begin() + part.cur_.firstVert, part.raw.end());
    cur_.plain = cur_.plain && part.cur_.plain;
}

namespace {

// A list with this many items is sorted as jobs, in chunks of kSortGrain (a sort of fewer takes a few microseconds).
constexpr std::size_t kParallelSortItems = 4096;
constexpr std::size_t kSortGrain = 1024;
// This many vertices (4096 quads, 192 KB) and more are copied into the stream as jobs, kCopyGrain vertices per chunk;
// fewer are copied faster than they are handed out.
constexpr std::size_t kParallelCopyVerts = 16384;
constexpr std::size_t kCopyGrain = 8192;

// A vertex of `it` as the stream holds it: lit items shade every textured / circle / ring / shape quad (shader mode
// + 16), Multiply items use the shader's multiply variant (+ 8), flashing items the flash variant (+ 32, colour in color2;
// shapes and glyphs keep theirs). The steps run in that order, as the flags are the higher bits of the mode.
inline Vertex2D stream_vertex(const QuadItem& it, Vertex2D v) {
    if (it.lit && (v.mode < float(kModeLit) || v.mode == float(kModeShape))) v.mode += 16.0f;
    if (it.blend == BlendMode::Multiply) v.mode += 8.0f;
    if (it.flash != 0) {
        const int base = int(v.mode) & 7;
        if (base != kModeShape && base != kModeGlyph) {
            v.mode += 32.0f;
            v.color2 = it.flash;
        }
    }
    return v;
}

}  // namespace

void QuadList::flatten(std::vector<Vertex2D>& out, std::vector<QuadBatch>& batches) {
    // seq is unique within a list and a NaN secondary key counts as +infinity (order_float), so the order is total:
    // any correct sort gives this one.
    rjobs::stable_sort(
        "render.sort_quads", items,
        [](const QuadItem& a, const QuadItem& b) {
            if (a.layer != b.layer) return a.layer < b.layer;
            const float sa = rjobs::order_float(a.secondary), sb = rjobs::order_float(b.secondary);
            if (sa != sb) return sa > sb;
            return a.seq < b.seq;
        },
        kParallelSortItems, kSortGrain);

    std::size_t total = 0;
    for (const QuadItem& it : items) total += std::size_t(it.quadCount) * 4;
    const std::size_t base = out.size();
    const rjobs::Split copySplit = rjobs::split(total, kCopyGrain, kParallelCopyVerts);
    if (copySplit.chunks <= 1) {
        // One chunk (a small list, or no worker): appended in order, nothing else allocated.
        for (const QuadItem& it : items) {
            const Vertex2D* src = raw.data() + it.firstVert;
            const std::size_t n = std::size_t(it.quadCount) * 4;
            if (it.lit || it.blend == BlendMode::Multiply || it.flash != 0) {
                for (std::size_t k = 0; k < n; ++k) out.push_back(stream_vertex(it, src[k]));
            } else {
                out.insert(out.end(), src, src + n);
            }
        }
    } else {
        // Where each item's vertices land in `out` (offsets from `base`), then the copy, by ranges of vertices so one
        // huge item (a big Tilemap) is shared out too. offsets_ is kept from frame to frame.
        offsets_.assign(items.size() + 1, 0);
        for (std::size_t i = 0; i < items.size(); ++i)
            offsets_[i + 1] = offsets_[i] + std::size_t(items[i].quadCount) * 4;
        out.resize(base + total);
        rjobs::run("render.flatten_quads", copySplit, [&](const jobs::Chunk& c) {
            // The item holding vertex c.begin: the last offset <= c.begin (items without quads are never in the list).
            const auto after = std::upper_bound(offsets_.begin(), offsets_.end(), c.begin);
            std::size_t i = std::size_t(after - offsets_.begin()) - 1;
            for (std::size_t v = c.begin; v < c.end; ++i) {
                const QuadItem& it = items[i];
                const std::size_t stop = std::min(c.end, offsets_[i + 1]);
                const Vertex2D* src = raw.data() + it.firstVert + (v - offsets_[i]);
                Vertex2D* dst = out.data() + base + v;
                if (it.lit || it.blend == BlendMode::Multiply || it.flash != 0) {
                    for (std::size_t k = 0, n = stop - v; k < n; ++k) dst[k] = stream_vertex(it, src[k]);
                } else {
                    std::copy(src, src + (stop - v), dst);
                }
                v = stop;
            }
        });
    }

    std::size_t at = base;  // the first vertex of the item in `out`
    for (const QuadItem& it : items) {
        const std::uint32_t firstQuad = std::uint32_t(at / 4);
        at += std::size_t(it.quadCount) * 4;
        const bool plain = it.plain && !it.lit && it.blend != BlendMode::Multiply;
        const bool opaque = it.opaque && it.blend == BlendMode::Alpha;
        // Textures packed into one atlas share its GPU image, so their quads batch together.
        // Lit quads also need the same normal map, and (their uv transform depends on it) the same texture object.
        if (!batches.empty() && batches.back().tex->gpu_view().id == it.tex->gpu_view().id &&
            batches.back().smp == it.smp && batches.back().blend == it.blend && batches.back().clip == it.clip &&
            batches.back().lit == it.lit &&
            (!it.lit || (batches.back().tex == it.tex && batches.back().normal == it.normal)) &&
            batches.back().opaque == opaque && batches.back().firstQuad + batches.back().quadCount == firstQuad) {
            batches.back().quadCount += it.quadCount;
            batches.back().plain = batches.back().plain && plain;
        } else {
            batches.push_back(
                {firstQuad, it.quadCount, it.tex, it.smp, it.blend, it.clip, it.lit, it.normal, plain, opaque});
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
