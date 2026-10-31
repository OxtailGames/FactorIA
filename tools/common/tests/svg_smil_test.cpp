// SMIL sampling (tools/common/src/svg_smil.cpp): an animated SVG at one instant, as a still SVG.
#include <doctest.h>

#include <string>

#include "fa/tooling/svg_smil.h"

using namespace fa;

namespace {

std::string wrap(const std::string& body) { return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>" + body + "</svg>"; }

SmilSvg parse_ok(const std::string& svg) {
    auto r = SmilSvg::parse(svg);
    if (!r.ok()) FAIL(r.error().message);
    return *r;
}

bool has(const std::string& text, const std::string& needle) { return text.find(needle) != std::string::npos; }

bool warned(const SmilSvg& s, const std::string& needle) {
    for (const std::string& w : s.warnings())
        if (has(w, needle)) return true;
    return false;
}

}  // namespace

TEST_CASE("smil: <animate> interpolates a number linearly, repeats, and the animation element is gone") {
    const SmilSvg s = parse_ok(wrap("<circle cx='10' cy='20' r='5'><animate attributeName='cx' from='10' to='90' dur='2s' repeatCount='indefinite'/></circle>"));
    CHECK(s.animation_count() == 1);
    CHECK(s.cycle_seconds() == doctest::Approx(2.0));
    CHECK(has(s.sample(0.0), "cx=\"10\""));
    CHECK(has(s.sample(1.0), "cx=\"50\""));
    CHECK(has(s.sample(0.5), "cx=\"30\""));
    CHECK(has(s.sample(2.0), "cx=\"10\""));  // repeats
    CHECK(has(s.sample(3.0), "cx=\"50\""));
    CHECK_FALSE(has(s.sample(1.0), "<animate"));
    CHECK(has(s.sample(1.0), "cy=\"20\""));  // the other attributes stay
    CHECK(s.sample(0.7) == s.sample(0.7));   // deterministic
}

TEST_CASE("smil: without repeatCount the value holds at the start after the end, with fill=freeze at the end") {
    const std::string plain = wrap("<rect width='10' height='10' x='0'><animate attributeName='x' from='0' to='40' dur='1s'/></rect>");
    const std::string frozen = wrap("<rect width='10' height='10' x='0'><animate attributeName='x' from='0' to='40' dur='1s' fill='freeze'/></rect>");
    CHECK(has(parse_ok(plain).sample(5.0), "x=\"0\""));
    CHECK(has(parse_ok(frozen).sample(5.0), "x=\"40\""));
    CHECK(has(parse_ok(frozen).sample(0.25), "x=\"10\""));
}

TEST_CASE("smil: begin offsets, <set>, repeatCount and repeatDur bound the active time") {
    const SmilSvg late = parse_ok(wrap("<rect width='10' height='10' x='0'><animate attributeName='x' from='0' to='10' dur='1s' begin='2s' fill='freeze'/></rect>"));
    CHECK(has(late.sample(1.0), "x=\"0\""));
    CHECK(has(late.sample(2.5), "x=\"5\""));
    CHECK(has(late.sample(9.0), "x=\"10\""));
    const SmilSvg set = parse_ok(wrap("<rect width='10' height='10' fill='red'><set attributeName='fill' to='blue' begin='1s' dur='1s'/></rect>"));
    CHECK(has(set.sample(0.5), "fill=\"red\""));
    CHECK(has(set.sample(1.5), "fill=\"blue\""));
    CHECK(has(set.sample(2.5), "fill=\"red\""));  // after dur, without freeze: back to the base value
    const SmilSvg twice = parse_ok(wrap("<rect width='10' height='10' x='0'><animate attributeName='x' from='0' to='10' dur='1s' repeatCount='2'/></rect>"));
    CHECK(twice.cycle_seconds() == doctest::Approx(2.0));
    CHECK(has(twice.sample(1.5), "x=\"5\""));
    CHECK(has(twice.sample(2.5), "x=\"0\""));
}

TEST_CASE("smil: values, keyTimes and calcMode (discrete, spline)") {
    const SmilSvg s = parse_ok(wrap("<rect width='10' height='10' x='0'><animate attributeName='x' values='0;100;0' keyTimes='0;0.25;1' dur='4s'/></rect>"));
    CHECK(has(s.sample(0.5), "x=\"50\""));
    CHECK(has(s.sample(1.0), "x=\"100\""));
    CHECK(has(s.sample(2.5), "x=\"50\""));
    const SmilSvg d = parse_ok(wrap("<rect width='10' height='10' x='0'><animate attributeName='x' values='0;10;20' calcMode='discrete' dur='3s'/></rect>"));
    CHECK(has(d.sample(0.5), "x=\"0\""));
    CHECK(has(d.sample(1.5), "x=\"10\""));
    CHECK(has(d.sample(2.5), "x=\"20\""));
    const SmilSvg sp = parse_ok(wrap("<rect width='10' height='10' x='0'><animate attributeName='x' from='0' to='100' calcMode='spline' keyTimes='0;1' keySplines='0.5 0 0.5 1' dur='2s'/></rect>"));
    CHECK(has(sp.sample(1.0), "x=\"50\""));  // an ease-in-out passes the middle at the middle
    const std::string early = sp.sample(0.5);
    CHECK_FALSE(has(early, "x=\"25\""));     // but it is slower than linear at the start
}

TEST_CASE("smil: colours interpolate in RGB, path data of equal structure interpolates number by number") {
    const SmilSvg c = parse_ok(wrap("<circle r='5' fill='red'><animate attributeName='fill' values='red;blue' dur='2s' repeatCount='indefinite'/></circle>"));
    CHECK(has(c.sample(1.0), "#800080"));
    const SmilSvg p = parse_ok(wrap("<path d='M0 0 L10 10'><animate attributeName='d' values='M0 0 L10 10;M0 0 L50 50' dur='2s'/></path>"));
    CHECK(has(p.sample(1.0), "d=\"M0 0 L30 30\""));
}

TEST_CASE("smil: animateTransform composes with the element's own transform") {
    const SmilSvg rot = parse_ok(wrap("<rect width='10' height='10'><animateTransform attributeName='transform' type='rotate' from='0 50 50' to='180 50 50' dur='2s' fill='freeze'/></rect>"));
    CHECK(has(rot.sample(1.0), "transform=\"rotate(90 50 50)\""));
    CHECK(has(rot.sample(4.0), "transform=\"rotate(180 50 50)\""));
    const SmilSvg sum = parse_ok(wrap("<rect width='10' height='10' transform='translate(5 5)'><animateTransform attributeName='transform' type='scale' from='1' to='3' dur='2s' additive='sum'/></rect>"));
    const std::string at1 = sum.sample(1.0);
    CHECK(has(at1, "translate(5 5)"));
    CHECK(has(at1, "scale(2"));
}

TEST_CASE("smil: animateMotion follows a path and turns with rotate=auto") {
    const SmilSvg m = parse_ok(wrap("<g><animateMotion path='M0 0 L100 0' dur='4s' rotate='auto'/><rect width='5' height='5'/></g>"));
    CHECK(has(m.sample(1.0), "translate(25 0)"));
    CHECK(has(m.sample(2.0), "translate(50 0)"));
    const SmilSvg down = parse_ok(wrap("<g><animateMotion path='M0 0 L0 100' dur='4s' rotate='auto'/><rect width='5' height='5'/></g>"));
    CHECK(has(down.sample(2.0), "rotate(90)"));
}

TEST_CASE("smil: id.begin and id.end sync-bases start an animation relative to another") {
    const SmilSvg s = parse_ok(wrap(
        "<rect width='10' height='10' x='0'>"
        "<animate id='a' attributeName='x' from='0' to='10' dur='1s' fill='freeze'/>"
        "<animate id='b' attributeName='y' from='0' to='20' dur='2s' begin='a.end+1s' fill='freeze'/></rect>"));
    CHECK_FALSE(has(s.sample(1.5), "y=\""));  // b has not begun (a ended at 1 s, b begins 1 s later)
    CHECK(has(s.sample(2.0), "y=\"0\""));
    CHECK(has(s.sample(3.0), "y=\"10\""));
    CHECK(s.cycle_seconds() == doctest::Approx(4.0));
}

TEST_CASE("smil: what cannot be sampled is a warning that names the element") {
    const SmilSvg s = parse_ok(wrap("<rect width='3' height='3' x='1'><animate attributeName='x' from='0' to='4' dur='1s' begin='click'/></rect>"));
    s.sample(0.0);
    REQUIRE_FALSE(s.warnings().empty());
    CHECK(warned(s, "<animate attributeName=\"x\"> on <rect>"));
    CHECK(warned(s, "click"));
    CHECK(has(s.sample(2.0), "x=\"1\""));  // it has no effect
    const SmilSvg none = parse_ok(wrap("<rect width='3' height='3'/>"));
    CHECK(none.animation_count() == 0);
    CHECK(none.cycle_seconds() == 0);
}

TEST_CASE("smil: an SVG that is not well-formed XML is an error with its line") {
    auto r = SmilSvg::parse("<svg xmlns='http://www.w3.org/2000/svg'>\n<rect width='3'\n</svg>");
    REQUIRE_FALSE(r.ok());
    CHECK(has(r.error().message, "line"));
    CHECK_FALSE(r.error().hint.empty());
}

