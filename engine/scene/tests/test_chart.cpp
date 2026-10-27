// The geometry of a Chart (fa/scene/chart.h): the axis, where bars and points are, and which sample a point is over.
#include <doctest.h>

#include <cmath>

#include "fa/scene/chart.h"
#include "fa/scene/components.h"

using namespace fa;

namespace {
constexpr Rect kBox{0, 0, 112, 106};  // padding 6: the plot is 100 x 94 at (6, 6)
}

TEST_CASE("chart: one series or several, anything that is not a number is 0") {
    Chart c;
    c.values = Json::array({1, 2.5, "x", 4});
    auto s = chart_series(c);
    REQUIRE(s.size() == 1);
    CHECK(s[0] == std::vector<double>{1, 2.5, 0, 4});
    c.values = Json::array({Json::array({1, 2}), Json::array({3})});
    s = chart_series(c);
    REQUIRE(s.size() == 2);
    CHECK(s[1] == std::vector<double>{3});
    c.values = Json::array();
    CHECK(chart_series(c).empty());
    c.values = Json("nope");
    CHECK(chart_series(c).empty());
}

TEST_CASE("chart: the automatic axis includes the baseline, min and max override it, a flat axis is widened") {
    Chart c;
    c.values = Json::array({50, 80, 100});
    auto s = chart_series(c);
    ChartLayout L = chart_layout(c, s, kBox);
    CHECK(L.lo == 0.0);
    CHECK(L.hi == 100.0);
    c.includeBaseline = false;
    L = chart_layout(c, s, kBox);
    CHECK(L.lo == 50.0);
    c.values = Json::array({-5, 20});
    c.includeBaseline = true;
    s = chart_series(c);
    L = chart_layout(c, s, kBox);
    CHECK(L.lo == -5.0);
    CHECK(L.hi == 20.0);
    c.min = Json(-50);
    c.max = Json(200);
    L = chart_layout(c, s, kBox);
    CHECK(L.lo == -50.0);
    CHECK(L.hi == 200.0);
    c.min = c.max = Json();
    c.values = Json::array({7, 7});
    c.baseline = 7;
    L = chart_layout(c, chart_series(c), kBox);
    CHECK(L.hi > L.lo);
    c.values = Json::array();
    L = chart_layout(c, chart_series(c), kBox);
    CHECK(L.hi > L.lo);
}

TEST_CASE("chart: bars scale to the maximum and sit on the baseline") {
    Chart c;
    c.values = Json::array({25, 50, 100});
    c.barGap = 0.0f;
    const auto s = chart_series(c);
    const ChartLayout L = chart_layout(c, s, kBox);
    const Rect tall = L.bar(0, 2, 100, 0), half = L.bar(0, 1, 50, 0);
    CHECK(tall.h == doctest::Approx(L.plot.h));
    CHECK(half.h == doctest::Approx(L.plot.h * 0.5f));
    CHECK(tall.y + tall.h == doctest::Approx(L.plot.y + L.plot.h));  // all bars stand on the bottom (zero)
    CHECK(tall.w == doctest::Approx(L.plot.w / 3));
    CHECK(L.bar(0, 0, 25, 0).x == doctest::Approx(L.plot.x));
}

TEST_CASE("chart: a line passes through its points, from edge to edge; values are right-aligned in more slots") {
    Chart c;
    c.kind = ChartKind::Line;
    c.values = Json::array({0, 50, 100});
    const auto s = chart_series(c);
    ChartLayout L = chart_layout(c, s, kBox);
    CHECK(L.x_of(0) == doctest::Approx(L.plot.x));
    CHECK(L.x_of(2) == doctest::Approx(L.plot.x + L.plot.w));
    CHECK(L.y_of(100) == doctest::Approx(L.plot.y));
    CHECK(L.y_of(50) == doctest::Approx(L.plot.y + L.plot.h / 2));
    c.slots = 5;
    L = chart_layout(c, s, kBox);
    CHECK(L.first == 2);
    CHECK(L.x_of(L.first + 2) == doctest::Approx(L.plot.x + L.plot.w));
}

TEST_CASE("chart: the sample under a point, for bars, lines and several series") {
    Chart c;
    c.values = Json::array({25, 50, 100, 10});
    auto s = chart_series(c);
    const ChartLayout L = chart_layout(c, s, kBox);
    auto hit = chart_sample_at(c, s, kBox, {L.plot.x + 1, 50});
    REQUIRE(hit);
    CHECK(hit->index == 0);
    CHECK(hit->value == 25.0);
    hit = chart_sample_at(c, s, kBox, {L.plot.x + L.plot.w - 1, 50});
    REQUIRE(hit);
    CHECK(hit->index == 3);
    CHECK_FALSE(chart_sample_at(c, s, kBox, {-1, 50}));
    CHECK_FALSE(chart_sample_at(c, s, kBox, {500, 50}));

    c.slots = 8;  // four empty slots at the left: no sample there
    CHECK_FALSE(chart_sample_at(c, s, kBox, {L.plot.x + 2, 50}));
    hit = chart_sample_at(c, s, kBox, {L.plot.x + L.plot.w - 2, 50});
    REQUIRE(hit);
    CHECK(hit->index == 3);

    c.slots = 0;
    c.values = Json::array({Json::array({1, 2}), Json::array({3, 4})});
    s = chart_series(c);
    const ChartLayout L2 = chart_layout(c, s, kBox);
    const Rect b1 = L2.bar(1, 0, 3, 0);
    hit = chart_sample_at(c, s, kBox, {b1.x + b1.w * 0.5f, 50});
    REQUIRE(hit);
    CHECK(hit->index == 0);
    CHECK(hit->series == 1);

    c.kind = ChartKind::Line;  // the closest point: series 1 is at 3, series 0 at 1 on the first sample
    hit = chart_sample_at(c, s, kBox, {L2.plot.x + 1, L2.y_of(1)});
    REQUIRE(hit);
    CHECK(hit->index == 0);
    CHECK(hit->series == 0);
}

TEST_CASE("chart: labels use the language's number format") {
    Chart c;
    CHECK(chart_label(c, 1234.5, "en") == "1,234.5");
    CHECK(chart_label(c, 12345.5, "es") == "12.345,5");
    CHECK(chart_label(c, 0.1 + 0.2, "en") == "0.3");
    c.decimals = 1;
    CHECK(chart_label(c, 2, "en") == "2.0");
}
