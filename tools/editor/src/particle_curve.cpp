#include "particle_curve.h"

#include <algorithm>
#include <cmath>

namespace fa::editor {

namespace {

template <typename Keys>
std::size_t insert_position(const Keys& keys, float t) {
    std::size_t at = 0;
    while (at < keys.size() && keys[at].t <= t) ++at;
    return at;
}

template <typename Keys>
float clamp_between(const Keys& keys, int i, float t) {
    const float lo = i > 0 ? keys[std::size_t(i - 1)].t : 0.0f;
    const float hi = i + 1 < int(keys.size()) ? keys[std::size_t(i + 1)].t : 1.0f;
    return std::clamp(t, lo, std::max(lo, hi));
}

}  // namespace

int curve_add_key(Curve& c, float t, float value) {
    if (int(c.keys.size()) >= kMaxCurveKeys) return -1;
    t = std::clamp(t, 0.0f, 1.0f);
    const std::size_t at = insert_position(c.keys, t);
    c.keys.insert(c.keys.begin() + std::ptrdiff_t(at), CurveKey{t, value});
    return int(at);
}

bool curve_move_key(Curve& c, int i, float t, float value) {
    if (i < 0 || i >= int(c.keys.size()) || !std::isfinite(t) || !std::isfinite(value)) return false;
    c.keys[std::size_t(i)].t = clamp_between(c.keys, i, std::clamp(t, 0.0f, 1.0f));
    c.keys[std::size_t(i)].value = value;
    return true;
}

bool curve_remove_key(Curve& c, int i) {
    if (i < 0 || i >= int(c.keys.size())) return false;
    c.keys.erase(c.keys.begin() + i);
    return true;
}

int gradient_add_key(Gradient& g, float t) {
    if (int(g.keys.size()) >= kMaxCurveKeys) return -1;
    t = std::clamp(t, 0.0f, 1.0f);
    const Color here = g.empty() ? Color{1, 1, 1, 1} : g.eval(t);
    const std::size_t at = insert_position(g.keys, t);
    g.keys.insert(g.keys.begin() + std::ptrdiff_t(at), GradientKey{t, here});
    return int(at);
}

bool gradient_move_key(Gradient& g, int i, float t) {
    if (i < 0 || i >= int(g.keys.size()) || !std::isfinite(t)) return false;
    g.keys[std::size_t(i)].t = clamp_between(g.keys, i, std::clamp(t, 0.0f, 1.0f));
    return true;
}

bool gradient_set_key_color(Gradient& g, int i, Color color) {
    if (i < 0 || i >= int(g.keys.size())) return false;
    g.keys[std::size_t(i)].color = color;
    return true;
}

bool gradient_remove_key(Gradient& g, int i) {
    if (i < 0 || i >= int(g.keys.size())) return false;
    g.keys.erase(g.keys.begin() + i);
    return true;
}

void curve_value_range(const Curve& c, float& lo, float& hi) {
    lo = 0.0f;
    hi = 1.0f;
    for (const CurveKey& k : c.keys) {
        lo = std::min(lo, k.value);
        hi = std::max(hi, k.value);
    }
    if (hi - lo < 0.001f) hi = lo + 1.0f;
}

}  // namespace fa::editor
