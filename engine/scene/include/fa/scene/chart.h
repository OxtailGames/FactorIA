// Where a Chart's bars, line points and rules are: the ONE definition behind drawing (fa_render) and the hover (fa_ui), so the
// bar the pointer is on is the bar that is drawn. Everything is in UI units (ui_rect.h), relative to the rectangle given.
#pragma once

#include <optional>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/components.h"

namespace fa {

// The series of Chart.values: a flat list of numbers is one series, a list of lists several. Anything that is not a number is
// read as 0 (the baseline of an automatic axis).
std::vector<std::vector<double>> chart_series(const Chart& c);

// The colour of series `i`: Chart.colors[i % size], a default palette when the list is empty or the entry is not a colour.
Color chart_series_color(const Chart& c, int i);

struct ChartLayout {
    Rect plot;               // where the samples are drawn
    double lo = 0, hi = 1;   // the value axis (hi > lo)
    int slots = 0;           // samples the plot has room for
    int first = 0;           // slot of the first value: slots - longest series (the values are right-aligned)
    int count = 0;           // length of the longest series
    int series = 0;
    bool line = false;
    float barGap = 0.2f;

    // Vertical position of value `v` (clamped to the axis).
    float y_of(double v) const;
    // Horizontal centre of slot `slot` (bars: the middle of its column; lines: the points span the plot from edge to edge).
    float x_of(int slot) const;
    // Width of one slot's column.
    float slot_width() const;
    // The bar of series `s` in slot `slot` for value `v`; the part between the baseline and the value, at least 1 unit high.
    Rect bar(int s, int slot, double v, double baseline) const;
};

// The axis and the plot of `c` inside the box `r`. Automatic min / max cover every value, and the baseline when
// includeBaseline is on; a flat axis (hi <= lo) is widened by one so a constant series still has a height.
ChartLayout chart_layout(const Chart& c, const std::vector<std::vector<double>>& series, const Rect& r);

struct ChartSample {
    int series = 0;
    int index = 0;    // position in the series (0 = its oldest value)
    double value = 0;
};
// The sample under the point `p` (UI units, same space as `r`): nullopt outside the box or when there are no values. A bar chart
// answers with the column p is in (series: the bar of that column p is over, or the nearest); a line chart with the point closest
// to p horizontally (series: the closest vertically). A slot with no value (the empty room of right-aligned values) has no sample.
std::optional<ChartSample> chart_sample_at(const Chart& c, const std::vector<std::vector<double>>& series, const Rect& r, Vec2 p);

// The text of an axis label in `language` (a BCP 47 tag, "" = English): the number with Chart.decimals digits.
std::string chart_label(const Chart& c, double value, const std::string& language);

}  // namespace fa
