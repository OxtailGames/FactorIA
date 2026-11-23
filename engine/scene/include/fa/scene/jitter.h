// The sub-pixel camera jitter of the temporal antialiasing and the temporal upscaler (M76, docs/design/ARCHITECTURE_RENDERING_POST.md,
// "Motion vectors and jitter (M76)"). One Halton(2,3) sequence, a pure function of the frame index (no clock, no random numbers), so a
// run draws the same pictures every time and a recorded replay matches.
//
// The jitter moves where the scene lands on the render image by a fraction of a pixel. It applies to the DRAWN projection only
// (CameraGeometry::drawProj / drawViewProj): the matrices that answer questions (queryViewProj, the culling, the Hi-Z pyramid, picking,
// world_to_screen, the previous-frame matrices and the motion vectors) are never jittered.
#pragma once

#include <cstdint>

#include "fa/core/math.h"

namespace fa {

inline constexpr int kJitterPhasesDefault = 8;  // the sequence repeats after this many frames
// The longest sequence a camera may ask for: the temporal upscaler (M76-P4) wants ceil(8 * (output / render)^2) phases, 72 at a render size
// of a third of the output's width and height (UltraPerformance), 128 at the smallest render scale (0.25) of the renderer.
inline constexpr int kJitterPhasesMax = 128;

// Element `index` (1, 2, 3 ...) of the Halton sequence in `base` (2 or 3 for the jitter): a number in [0, 1). Index 0 gives 0.
float halton(std::uint32_t index, std::uint32_t base);

// The jitter of frame `frameIndex`, in RENDER pixels of the camera's image: x to the right, y DOWN (the direction of
// CameraGeometry::world_to_screen), each in -0.5 .. 0.5. Frame f uses Halton(2,3) element (f mod phases) + 1; `phases` is clamped to
// 1..kJitterPhasesMax (1 = no jitter: element 1 is (0, -1/6), so use a zero offset when the camera does not jitter).
Vec2 jitter_offset_pixels(std::uint64_t frameIndex, int phases = kJitterPhasesDefault);

// The same shift as an offset of normalised device coordinates for an image of `widthPx` x `heightPx` render pixels: a scene point
// moves by `pixels` on that image when its clip x and y get +ndc.x * w and +ndc.y * w. (2 * x / w, -2 * y / h: y flips because the
// image's y goes down and NDC's up.) A size below 1 is read as 1.
Vec2 jitter_pixels_to_ndc(Vec2 pixels, float widthPx, float heightPx);

}  // namespace fa
