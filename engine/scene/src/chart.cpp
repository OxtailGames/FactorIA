#include "fa/scene/chart.h"

#include <algorithm>
#include <cmath>
#include <limits>

#include "fa/core/json.h"
#include "fa/core/number_format.h"

namespace fa {

namespace {

double number_or_zero(const Json& j) {
    if (!j.is_number()) return 0.0;
    const double v = j.get<double>();
    return std::isfinite(v) ? v : 0.0;
}

}  // namespace

std::vector<std::vector<double>> chart_series(const Chart& c) {
    std::vector<std::vector<double>> out;
    if (!c.values.is_array()) return out;
    bool nested = false;
    for (const Json& j : c.values) nested = nested || j.is_array();
    if (!nested) {
        std::vector<double> one;
        for (const Json& j : c.values) one.push_back(number_or_zero(j));
        if (!one.empty()) out.push_back(std::move(one));
        return out;
    }
    for (const Json& s : c.values) {
        std::vector<double> v;
        if (s.is_array())
            for (const Json& j : s) v.push_back(number_or_zero(j));
        out.push_back(std::move(v));
    }
    return out;
}

Color chart_series_color(const Chart& c, int i) {
    static const Color palette[] = {{0.55f, 0.78f, 1.0f, 1}, {1.0f, 0.82f, 0.38f, 1}, {0.55f, 0.9f, 0.55f, 1}, {1.0f, 0.5f, 0.5f, 1},
                                    {0.8f, 0.6f, 1.0f, 1}};
    const int n = int(sizeof(palette) / sizeof(palette[0]));
    if (c.colors.is_array() && !c.colors.empty()) {
        Color out;
        const Json& j = c.colors[std::size_t(i) % c.colors.size()];
        if (json_to(j, out, nullptr)) return out;
    }
    return palette[i % n];
}

float ChartLayout::y_of(double v) const {
    const double t = std::clamp((v - lo) / (hi - lo), 0.0, 1.0);
    return plot.y + plot.h * float(1.0 - t);
}

float ChartLayout::slot_width() const { return slots > 0 ? plot.w / float(slots) : plot.w; }

float ChartLayout::x_of(int slot) const {
    if (!line) return plot.x + (float(slot) + 0.5f) * slot_width();
    return slots > 1 ? plot.x + plot.w * float(slot) / float(slots - 1) : plot.x + plot.w * 0.5f;
}

Rect ChartLayout::bar(int s, int slot, double v, double baseline) const {
    const float w = slot_width() * std::clamp(1.0f - barGap, 0.05f, 1.0f);
    const float each = w / float(std::max(1, series));
    const float x = plot.x + float(slot) * slot_width() + (slot_width() - w) * 0.5f + each * float(s);
    const float yv = y_of(v), yb = y_of(baseline);
    const float top = std::min(yv, yb), h = std::max(1.0f, std::abs(yv - yb));
    return Rect{x, top, each, h};
}

ChartLayout chart_layout(const Chart& c, const std::vector<std::vector<double>>& series, const Rect& r) {
    ChartLayout L;
    const float pad = std::max(0.0f, c.padding);
    L.plot = Rect{r.x + pad, r.y + pad, std::max(0.0f, r.w - 2 * pad), std::max(0.0f, r.h - 2 * pad)};
    L.line = c.kind == ChartKind::Line;
    L.barGap = c.barGap;
    L.series = int(series.size());
    for (const auto& s : series) L.count = std::max(L.count, int(s.size()));
    L.slots = std::max(L.count, int(std::max(0, c.slots)));
    L.first = L.slots - L.count;
    double lo = std::numeric_limits<double>::infinity(), hi = -lo;
    for (const auto& s : series)
        for (double v : s) {
            lo = std::min(lo, v);
            hi = std::max(hi, v);
        }
    if (!std::isfinite(lo)) lo = hi = c.baseline;
    if (c.includeBaseline) {
        lo = std::min(lo, double(c.baseline));
        hi = std::max(hi, double(c.baseline));
    }
    if (c.min.is_number()) lo = c.min.get<double>();
    if (c.max.is_number()) hi = c.max.get<double>();
    if (!(hi > lo)) hi = lo + 1.0;
    L.lo = lo;
    L.hi = hi;
    return L;
}

std::optional<ChartSample> chart_sample_at(const Chart& c, const std::vector<std::vector<double>>& series, const Rect& r, Vec2 p) {
    if (!r.contains(p) || series.empty()) return std::nullopt;
    const ChartLayout L = chart_layout(c, series, r);
    if (L.count == 0 || L.slots == 0 || !(L.plot.w > 0)) return std::nullopt;
    const float rel = std::clamp(p.x - L.plot.x, 0.0f, L.plot.w);
    int slot;
    if (L.line) slot = L.slots > 1 ? int(std::lround(rel / L.plot.w * float(L.slots - 1))) : 0;
    else slot = std::min(L.slots - 1, int(rel / L.slot_width()));
    const int index = slot - L.first;
    if (index < 0 || index >= L.count) return std::nullopt;
    // The series: for bars the one whose bar the pointer is over (columns split evenly), for lines the closest point vertically.
    int best = -1;
    if (L.line) {
        float bestDist = std::numeric_limits<float>::infinity();
        for (int s = 0; s < L.series; ++s) {
            if (index >= int(series[s].size())) continue;
            const float d = std::abs(L.y_of(series[s][index]) - p.y);
            if (d < bestDist) {
                bestDist = d;
                best = s;
            }
        }
    } else {
        const Rect first = L.bar(0, slot, 0, c.baseline);
        const float w = first.w * float(L.series);
        best = std::clamp(int((p.x - first.x) / std::max(0.001f, w) * float(L.series)), 0, L.series - 1);
        if (index >= int(series[best].size())) {
            best = -1;
            for (int s = 0; s < L.series && best < 0; ++s)
                if (index < int(series[s].size())) best = s;
        }
    }
    if (best < 0) return std::nullopt;
    return ChartSample{best, index, series[best][index]};
}

std::string chart_label(const Chart& c, double value, const std::string& language) {
    if (c.decimals >= 0) return format_number(value, std::min<int>(c.decimals, 9), language);
    return format_number(std::round(value * 100.0) / 100.0, -1, language);  // the digits the value has, at most two
}

}  // namespace fa
