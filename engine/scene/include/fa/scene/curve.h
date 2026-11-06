// Keyed curves and colour gradients: a few (position, value) keys, evaluated between them. They are plain data that live in JSON
// fields (ParticleEmitter.sizeCurve, colorGradient, ...), so a scene file, a script and a command can all write them, and they are
// reusable by anything else that needs a value that changes over 0..1 (effect documents, the particle editor).
//
// JSON forms (`Curve::parse` / `Gradient::parse`; an Error names what is wrong and shows the right form):
//   curve      [[0, 1], [0.3, 1.5], [1, 0]]                            keys [position, value], linear between them
//              {"keys": [[0, 0], [1, 1]], "interp": "smooth"}          interp: "linear" (default), "smooth" (ease in and out), "step"
//              2                                                       a number: the constant 2
//              []                                                      empty: no curve (`empty()`; the caller says what that means)
//   gradient   [[0, "#ffffff"], [0.5, [1, 0.8, 0, 1]], [1, "#ff000000"]]   keys [position, colour]; the colour is anything a colour
//                                                                       field accepts ("#rrggbb", "#rrggbbaa", a name, [r, g, b, a]),
//                                                                       alpha included, and the keys are blended linearly
// Positions are 0..1 (outside the keys the first/last value holds), at most kMaxCurveKeys keys; keys given out of order are sorted.
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr int kMaxCurveKeys = 16;

enum class CurveInterp { Linear, Smooth, Step };

struct CurveKey {
    float t = 0.0f;
    float value = 0.0f;
};

class Curve {
public:
    std::vector<CurveKey> keys;  // sorted by t
    CurveInterp interp = CurveInterp::Linear;

    bool empty() const { return keys.empty(); }
    // The value at `t` (any number: positions before the first key give the first value, after the last the last). 0 for an empty curve.
    float eval(float t) const;
    // Like eval, but `fallback` for an empty curve (a curve that is not set leaves the thing as it is).
    float eval_or(float t, float fallback) const { return keys.empty() ? fallback : eval(t); }

    // The curve a JSON value spells (see the header). `what` names the field in the Error ("ParticleEmitter.sizeCurve").
    static Result<Curve> parse(const Json& j, std::string_view what);
    Json to_json() const;  // the `[[t, v], ...]` form, or the object form when interp is not linear
    static Curve constant(float v);
    bool operator==(const Curve& o) const;
};

struct GradientKey {
    float t = 0.0f;
    Color color{1, 1, 1, 1};
};

class Gradient {
public:
    std::vector<GradientKey> keys;  // sorted by t

    bool empty() const { return keys.empty(); }
    // The colour at `t` (alpha blended like the colour); transparent white for an empty gradient.
    Color eval(float t) const;
    Color eval_or(float t, Color fallback) const { return keys.empty() ? fallback : eval(t); }

    static Result<Gradient> parse(const Json& j, std::string_view what);
    Json to_json() const;
    bool operator==(const Gradient& o) const;
};

}  // namespace fa
