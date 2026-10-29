#include "gradient_ramp.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>

#include "fa/core/log.h"

namespace fa::render {

namespace {

std::uint64_t mix(std::uint64_t h, std::uint64_t v) {
    h ^= v + 0x9e3779b97f4a7c15ull + (h << 6) + (h >> 2);
    return h;
}

std::uint64_t bits(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof u);
    return u;
}

}  // namespace

std::uint64_t GradientSpec::hash() const {
    std::uint64_t h = mix(1469598103934665603ull, std::uint64_t(ease));
    h = mix(h, std::uint64_t(count));
    for (int i = 0; i < count; ++i) {
        h = mix(h, bits(t[std::size_t(i)]));
        const Color& c = color[std::size_t(i)];
        h = mix(h, bits(c.r)); h = mix(h, bits(c.g)); h = mix(h, bits(c.b)); h = mix(h, bits(c.a));
    }
    return h;
}

bool GradientSpec::operator==(const GradientSpec& o) const {
    if (ease != o.ease || count != o.count) return false;
    for (int i = 0; i < count; ++i)
        if (t[std::size_t(i)] != o.t[std::size_t(i)] || !(color[std::size_t(i)] == o.color[std::size_t(i)])) return false;
    return true;
}

bool gradient_spec(const Shape2D& s, const Color& tint, GradientSpec& out, std::string* warning) {
    out = GradientSpec{};
    out.ease = s.gradientEase;
    if (s.gradientStops.is_array() && !s.gradientStops.empty()) {
        int skipped = 0;
        std::string firstProblem;
        for (const Json& entry : s.gradientStops) {
            std::string err;
            float pos = 0.0f;
            Color c;
            if (!entry.is_array() || entry.size() != 2 || !entry[0].is_number() || !json_to(entry[1], c, &err) ||
                !std::isfinite(float(entry[0].get<double>()))) {
                if (skipped++ == 0) firstProblem = entry.dump();
                continue;
            }
            if (out.count >= kMaxGradientStops) continue;  // the others are ignored
            pos = std::clamp(float(entry[0].get<double>()), 0.0f, 1.0f);
            out.t[std::size_t(out.count)] = pos;
            out.color[std::size_t(out.count)] = c * tint;
            ++out.count;
        }
        if (skipped > 0 && warning)
            *warning = std::format("Shape2D.gradientStops: {} entr{} skipped, the first was {}. Each stop is [position 0..1, colour], "
                                   "e.g. [0.5, [0, 0, 0, 0.3]] or [1, \"#00000000\"]",
                                   skipped, skipped == 1 ? "y was" : "ies were", firstProblem);
    }
    if (out.count == 0) {
        if (out.ease == GradientEase::Linear) return false;  // color -> color2, blended by the shader
        out.count = 2;
        out.t[0] = 0.0f; out.t[1] = 1.0f;
        out.color[0] = s.color * tint;
        out.color[1] = s.color2 * tint;
        return true;
    }
    // Sorted by position (stable: equal positions keep their order, which makes a hard edge).
    std::array<int, kMaxGradientStops> order{};
    for (int i = 0; i < out.count; ++i) order[std::size_t(i)] = i;
    std::stable_sort(order.begin(), order.begin() + out.count, [&](int a, int b) { return out.t[std::size_t(a)] < out.t[std::size_t(b)]; });
    GradientSpec sorted = out;
    for (int i = 0; i < out.count; ++i) {
        sorted.t[std::size_t(i)] = out.t[std::size_t(order[std::size_t(i)])];
        sorted.color[std::size_t(i)] = out.color[std::size_t(order[std::size_t(i)])];
    }
    out = sorted;
    return true;
}

void bake_ramp_row(const GradientSpec& spec, std::uint8_t* rgba) {
    for (int i = 0; i < kRampWidth; ++i) {
        const float x = gradient_ease_apply(spec.ease, float(i) / float(kRampWidth - 1));
        float pr = 0, pg = 0, pb = 0, pa = 0;  // premultiplied
        auto premul = [](const Color& c, float& r, float& g, float& b, float& a) { r = c.r * c.a; g = c.g * c.a; b = c.b * c.a; a = c.a; };
        if (spec.count <= 0) {
            // nothing to draw
        } else if (x <= spec.t[0]) {
            premul(spec.color[0], pr, pg, pb, pa);
        } else if (x >= spec.t[std::size_t(spec.count - 1)]) {
            premul(spec.color[std::size_t(spec.count - 1)], pr, pg, pb, pa);
        } else {
            int k = 1;
            while (k < spec.count - 1 && x > spec.t[std::size_t(k)]) ++k;
            const float t0 = spec.t[std::size_t(k - 1)], t1 = spec.t[std::size_t(k)];
            const float f = t1 > t0 ? (x - t0) / (t1 - t0) : 1.0f;
            float r0, g0, b0, a0, r1, g1, b1, a1;
            premul(spec.color[std::size_t(k - 1)], r0, g0, b0, a0);
            premul(spec.color[std::size_t(k)], r1, g1, b1, a1);
            pr = r0 + (r1 - r0) * f; pg = g0 + (g1 - g0) * f; pb = b0 + (b1 - b0) * f; pa = a0 + (a1 - a0) * f;
        }
        const float inv = pa > 1e-5f ? 1.0f / pa : 0.0f;
        const Color straight = pa > 1e-5f ? Color{pr * inv, pg * inv, pb * inv, pa}
                                          : (spec.count > 0 ? Color{spec.color[0].r, spec.color[0].g, spec.color[0].b, 0.0f} : Color{0, 0, 0, 0});
        const std::uint32_t p = straight.to_rgba8();
        std::memcpy(rgba + std::size_t(i) * 4, &p, 4);
    }
}

GradientRamps::~GradientRamps() { destroy(); }

void GradientRamps::destroy() {
    if (tex_.view.id) sg_destroy_view(tex_.view);
    if (tex_.image.id) sg_destroy_image(tex_.image);
    tex_.view = {};
    tex_.image = {};
}

int GradientRamps::acquire(const GradientSpec& spec) {
    const std::uint64_t h = spec.hash();
    auto it = byHash_.find(h);
    if (it != byHash_.end())
        for (int r : it->second)
            if (rows_[std::size_t(r)].spec == spec) {
                rows_[std::size_t(r)].used = tick_;
                return r;
            }
    // A free row, else the least recently used one that no shape of this frame reads.
    int row = -1;
    for (int r = 0; r < kRampRows && row < 0; ++r)
        if (!rows_[std::size_t(r)].live) row = r;
    if (row < 0) {
        std::uint64_t oldest = tick_;
        for (int r = 0; r < kRampRows; ++r)
            if (rows_[std::size_t(r)].used < oldest) { oldest = rows_[std::size_t(r)].used; row = r; }
        if (row < 0) return -1;
        auto& list = byHash_[rows_[std::size_t(row)].spec.hash()];
        list.erase(std::remove(list.begin(), list.end(), row), list.end());
        if (list.empty()) byHash_.erase(rows_[std::size_t(row)].spec.hash());
    }
    if (pixels_.empty()) pixels_.assign(std::size_t(kRampWidth) * kRampRows * 4, 0);
    Row& rw = rows_[std::size_t(row)];
    rw.spec = spec;
    rw.used = tick_;
    rw.live = true;
    byHash_[h].push_back(row);
    bake_ramp_row(spec, pixels_.data() + std::size_t(row) * kRampWidth * 4);
    dirty_ = true;
    return row;
}

void GradientRamps::sync() {
    if (pixels_.empty() || (!dirty_ && tex_.image.id)) return;
    if (tex_.view.id) sg_destroy_view(tex_.view);
    if (tex_.image.id) sg_destroy_image(tex_.image);
    sg_image_desc d{};
    d.width = kRampWidth;
    d.height = kRampRows;
    d.pixel_format = SG_PIXELFORMAT_RGBA8;
    d.data.mip_levels[0] = {pixels_.data(), pixels_.size()};
    d.label = "gradient-ramps";
    tex_.path = "<gradient-ramps>";
    tex_.image = make_image(d);
    sg_view_desc vd{};
    vd.texture.image = tex_.image;
    vd.label = "gradient-ramps";
    tex_.view = sg_make_view(&vd);
    tex_.width = kRampWidth;
    tex_.height = kRampRows;
    tex_.bytes = pixels_.size();
    dirty_ = false;
}

}  // namespace fa::render
