// Normal maps as pictures you can edit (M74, docs/images/IMAGES_EFFECTS_COMMANDS.md, "Normal maps"): make a tangent-space normal map from a height field or from
// a sprite, keep it a valid normal map while it is flipped, smoothed, scaled or repainted, and light a picture with it.
//
// The maps are straight RGBA8 `Image`s laid out like Sprite.normalMap: red = +X to the right, green = +Y UP the picture (OpenGL / glTF), blue
// = +Z towards the viewer, each decoded as byte / 127.5 - 1 and encoded as floor(v * 255 + 0.5) with v = n * 0.5 + 0.5. A flat area is
// (128, 128, 255). Nothing here reads or writes a file, so the image panel, the image.* commands and the tests run the same code.
#pragma once

#include <string>

#include "fa/core/image.h"
#include "fa/core/types.h"

namespace fa {

// Where make_normal_map reads its height from.
//   "sprite": the picture is a sprite, as Sprite.normalFrom = sprite: a bevel from the distance to the transparent edge plus the luminance
//             times the alpha (brighter and more opaque reads as higher).
//   "height": the picture is a grey height map, as Sprite.normalFrom = height: white = high, the luminance of each pixel, alpha ignored.
// `strength` is the relief (0 = flat; Sprite.normalStrength). With `tile` the slope at an edge uses the pixel on the other side (a tiling
// texture has no seam); without it the border is clamped, which is what the runtime does. With tile false the result is byte-identical to
// the one the renderer makes for the same picture and strength (engine/core normal_map_from_sprite / normal_map_from_height_image).
// An empty image when `src` is empty or `from` is neither value. The result is opaque.
Image make_normal_map(const Image& src, const std::string& from, double strength, bool tile);

// The colour of a normal that tilts `tiltDegrees` (0 = flat, up to 89) away from the viewer towards `azimuthDegrees` (counter-clockwise
// from +x, so 0 = right, 90 = up the picture, 180 = left, 270 = down). Opaque. This is the colour to paint a slope with.
Color normal_direction_color(double azimuthDegrees, double tiltDegrees);

// Edits that keep a map a normal map. Pixels with alpha 0 are left alone. Every result is re-encoded from unit vectors.
// Mirrors the X (red) and / or the Y (green) component: flipping Y turns an OpenGL map into a DirectX one and back, flipping twice gives
// the same bytes.
void normal_map_flip(Image& map, bool flipX, bool flipY);
// Blurs the vectors with a Gaussian of `sigma` pixels (0..64; the border is clamped, wrapped when `tile`) and renormalizes them.
void normal_map_smooth(Image& map, double sigma, bool tile);
// Scales the slopes by `amount` (0 = flat, 1 = unchanged, 2 = twice as steep): the vector (x, y, z) becomes (x k, y k, z) normalized.
void normal_map_scale(Image& map, double amount);
// Makes every vector unit length with a non-negative z (a painted, blended or resized map drifts off it). With `flatten` a transparent or
// half-transparent pixel becomes the flat normal mixed in by its alpha and the result is opaque, as a normal map file should be.
void normal_map_normalize(Image& map, bool flatten);

// A light for light_with_normal_map. Positions are in pixels of the picture (y down), `height` is how far above the picture a point light is.
struct NormalLight {
    bool point = true;                    // a lamp at (x, y, height) when true, else a light from a direction
    double x = 0, y = 0, height = 32;     // point light
    double azimuth = 135, elevation = 45;  // directional light, as the `shade` operation: degrees, 0 = from the right, 90 = from above
    double intensity = 1;                  // 0..4
    bool flipGreen = false;                // the map is DirectX style (green down)
};
// `base` lit by `normal`: every pixel's colour is multiplied by max(0, 1 + 2 intensity (n.L - L.z)), the formula of the `shade` operation,
// so a flat surface keeps its colour. `normal` is read at the same pixel of `base` (outside it, or where it is transparent, the surface is
// flat). The result has at most `maxSide` pixels on its long side (the picture is sampled, not averaged: it is a preview, with the light
// given in the pixels of `base`); maxSide 0 keeps the size.
Image light_with_normal_map(const Image& base, const Image& normal, const NormalLight& light, int maxSide = 0);

}  // namespace fa
