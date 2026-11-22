#include "brush.h"

#include <algorithm>
#include <cmath>
#include <limits>

namespace fa::editor {

void brush_clamp(BrushSettings& b, float maxRadius) {
    const float hi = std::max(kBrushMinRadius, maxRadius);
    b.radius = std::isfinite(b.radius) ? std::clamp(b.radius, kBrushMinRadius, hi) : kBrushMinRadius;
    b.strength = std::isfinite(b.strength) ? std::clamp(b.strength, 0.0f, 1.0f) : 0.5f;
    b.falloff = std::isfinite(b.falloff) ? std::clamp(b.falloff, 0.0f, 1.0f) : 1.0f;
}

float brush_spacing(float radius) { return std::max(radius, kBrushMinRadius) / kBrushStampsPerRadius; }

float brush_inner_radius(const BrushSettings& b) { return b.radius * (1.0f - std::clamp(b.falloff, 0.0f, 1.0f)); }

void brush_step_radius(BrushSettings& b, int steps, float maxRadius) {
    for (int i = 0; i < std::abs(steps); ++i) b.radius *= steps > 0 ? 1.25f : 0.8f;
    brush_clamp(b, maxRadius);
}

void brush_step_strength(BrushSettings& b, int steps) {
    b.strength = std::round((b.strength + 0.05f * float(steps)) * 100.0f) / 100.0f;
    brush_clamp(b);
}

// ------------------------------------------------------------------------------------------------------------------ stroke --
void BrushStroke::begin(Vec2 p, float radius) {
    points_.clear();
    taken_ = 0;
    spacing_ = brush_spacing(radius);
    last_ = p;
    points_.push_back(p);
    active_ = true;
}

int BrushStroke::add(Vec2 p) {
    if (!active_ || full() || !std::isfinite(p.x) || !std::isfinite(p.y)) return 0;
    int added = 0;
    for (;;) {
        const float dx = p.x - last_.x, dz = p.y - last_.y;
        const float d = std::sqrt(dx * dx + dz * dz);
        if (d < spacing_ || full()) break;
        const float k = spacing_ / d;
        last_ = Vec2{last_.x + dx * k, last_.y + dz * k};
        points_.push_back(last_);
        ++added;
    }
    return added;
}

std::size_t BrushStroke::take_pending(std::vector<Vec2>& out, std::size_t max) {
    const std::size_t n = std::min(max, points_.size() - taken_);
    out.insert(out.end(), points_.begin() + std::ptrdiff_t(taken_), points_.begin() + std::ptrdiff_t(taken_ + n));
    taken_ += n;
    return n;
}

void BrushStroke::end() {
    active_ = false;
    points_.clear();
    taken_ = 0;
}

// -------------------------------------------------------------------------------------------------------------------- ring --
std::vector<Vec2> brush_ring(Vec2 center, float radius, int segments) {
    const int n = std::clamp(segments, 8, 720);
    std::vector<Vec2> out;
    out.reserve(std::size_t(n));
    for (int i = 0; i < n; ++i) {
        const float a = 6.28318530718f * float(i) / float(n);
        out.push_back(Vec2{center.x + radius * std::cos(a), center.y + radius * std::sin(a)});
    }
    return out;
}

// -------------------------------------------------------------------------------------------------------------------- rays --
bool brush_ray_box(Vec3 origin, Vec3 dir, Vec3 lo, Vec3 hi, float& t0, float& t1) {
    float a = 0.0f, b = std::numeric_limits<float>::max();
    for (int i = 0; i < 3; ++i) {
        const float o = origin[i], d = dir[i], l = std::min(lo[i], hi[i]), h = std::max(lo[i], hi[i]);
        if (std::fabs(d) < 1e-12f) {
            if (o < l || o > h) return false;
            continue;
        }
        float ta = (l - o) / d, tb = (h - o) / d;
        if (ta > tb) std::swap(ta, tb);
        a = std::max(a, ta);
        b = std::min(b, tb);
        if (a > b) return false;
    }
    t0 = a;
    t1 = b;
    return true;
}

bool brush_ray_ground(Vec3 origin, Vec3 dir, float t0, float t1, int steps, const BrushSurface& surface, Vec3& hit) {
    if (!surface || !(t1 >= t0)) return false;
    const int n = std::clamp(steps, 1, 1 << 16);
    auto above = [&](float t,
                     bool& known) {  // true when the ray point at t is above the ground; `known` false: no ground there
        const Vec3 p = origin + dir * t;
        float y = 0.0f;
        known = surface(p.x, p.z, y);
        return p.y > y;
    };
    bool prevKnown = false;
    bool prevAbove = above(t0, prevKnown);
    float prevT = t0;
    for (int i = 1; i <= n; ++i) {
        const float t = t0 + (t1 - t0) * float(i) / float(n);
        bool known = false;
        const bool nowAbove = above(t, known);
        if (prevKnown && known && prevAbove && !nowAbove) {
            float lo = prevT, hi = t;  // above at lo, below at hi
            for (int k = 0; k < 24; ++k) {
                const float mid = 0.5f * (lo + hi);
                bool mk = false;
                if (above(mid, mk) || !mk)
                    lo = mid;
                else
                    hi = mid;
            }
            hit = origin + dir * (0.5f * (lo + hi));
            float y = 0.0f;
            if (surface(hit.x, hit.z, y)) hit.y = y;  // exactly on the ground
            return true;
        }
        prevKnown = known;
        prevAbove = known ? nowAbove : false;
        prevT = t;
    }
    return false;
}

}  // namespace fa::editor
