// SMIL animation of an SVG, sampled at a point in time: the animated SVG an AI writes when asked for "an animated SVG"
// becomes the still SVG of that instant, which assets.animate_svg rasterizes frame by frame (docs/ASSETS.md, "Animations
// drawn with code").
//
// The subset that is sampled: <animate>, <set>, <animateTransform> (translate, scale, rotate, skewX, skewY) and
// <animateMotion> (a `path`, an <mpath>, or values/from/to/by; rotate auto), with begin (offsets, `id.begin` and
// `id.end` sync-bases with an offset, several begins), end, dur, repeatCount, repeatDur, fill="freeze", values, keyTimes,
// keySplines, calcMode (discrete, linear, paced, spline), from/to/by, additive and accumulate. Numbers, lengths, colours
// and any value that is the same text around numbers (path data of equal structure, points, viewBox) are interpolated;
// anything else changes at its keyTime. Event-based begins (click...), CSS animations, min, max, restart and the other
// parts of SMIL are not sampled: each is a warning that names the element.
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa {

class SmilSvg {
public:
    // Reads the SVG (well-formed XML). The error names the line and column of the XML problem.
    static Result<SmilSvg> parse(const std::string& svg);

    // Seconds one pass of the animation lasts: the latest end of every animation with a finite duration; an animation that
    // repeats forever counts one repetition. 0 when the SVG has no animation.
    double cycle_seconds() const;
    // Number of animation elements (<animate>, <set>, <animateTransform>, <animateMotion>) that will be sampled.
    int animation_count() const;
    // The SVG as it is at `t` seconds: the animation elements are gone and the animated attributes hold their value at `t`.
    // Deterministic: the same `t` always gives the same text.
    std::string sample(double t) const;
    // What is not sampled (and why), in the order found, each once. Complete after the first sample(): some are found
    // only while a value is computed.
    const std::vector<std::string>& warnings() const;

private:
    struct Impl;
    std::shared_ptr<Impl> impl_;
};

}  // namespace fa
