// The key edits of the Particle panel's curve and gradient editors, with no ImGui: add a key where the user clicked, move one (it stays between
// its neighbours, so the key list stays sorted and the key keeps its index while it is dragged), remove one. The data are fa::Curve and
// fa::Gradient (fa/scene/curve.h), the same objects the renderer reads, so what the editor shows is what the emitter does.
#pragma once

#include "fa/scene/curve.h"

namespace fa::editor {

// Adds a key at (t, value) in its place; returns its index, or -1 when the curve already holds kMaxCurveKeys keys.
int curve_add_key(Curve& c, float t, float value);
// Moves key `i` to (t, value); t is clamped to 0..1 and to the keys beside it. Returns false for a bad index.
bool curve_move_key(Curve& c, int i, float t, float value);
bool curve_remove_key(Curve& c, int i);

// Adds a key at t with the colour the gradient has there (so the picture does not change); returns its index or -1 when full.
int gradient_add_key(Gradient& g, float t);
bool gradient_move_key(Gradient& g, int i, float t);
bool gradient_set_key_color(Gradient& g, int i, Color color);
bool gradient_remove_key(Gradient& g, int i);

// The range a curve editor shows on the value axis: at least 0..1, wider when a key is outside it.
void curve_value_range(const Curve& c, float& lo, float& hi);

}  // namespace fa::editor
