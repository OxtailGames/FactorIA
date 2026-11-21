// M74 light layers and cookies of the 2D lights, the parts that need no GPU (docs/rendering/RENDERING_2D_EMISSION.md).
#pragma once

#include <cstdint>
#include <vector>

#include "render_internal.h"

namespace fa::render {

// A receiver (Sprite, Shape2D, Tilemap) is lit by a light when their masks share a bit: this is the whole rule, in the light buffer
// path and in the per-pixel path.
inline bool light_reaches(std::int32_t lightLayers, std::int32_t receiverLayers) {
    return (lightLayers & receiverLayers) != 0;
}

// How a frame's lit visuals without a normal map read the point lights.
//   The default scene (every light on every layer, every receiver on layer 0) has ONE buffer holding every point light: the cost of a
//   frame with no light layers is the cost it had before them.
//   A scene with layers gets one buffer per DISTINCT set of point lights the receiver masks in view reach (two masks that reach the same
//   lights share a buffer), at most kMaxLightBuffers2D. A mask that reaches no point light needs no buffer (only ambient and the
//   directional lights, litMode 2); a mask past the cap falls back to the per-pixel loop over the first kDirectLights2D lights, which
//   applies the same rule per light.
struct LightLayerPlan {
    static constexpr int kLoop = -1;     // the per-pixel loop (no buffer left, or the buffer path is off)
    static constexpr int kNoPoint = -2;  // no point light reaches the mask: ambient and directional lights only
    struct Mask {
        std::int32_t layers = 1;  // the receiver mask
        int buffer = 0;           // an index into `buffers`, or kLoop, or kNoPoint
    };
    std::vector<Mask> masks;  // every distinct receiver mask asked for, in the order first asked
    std::vector<std::vector<int>>
        buffers;              // per buffer, the indices (into the frame's lights) of the point lights it holds
    bool overflowed = false;  // a mask did not get a buffer (the cap)
    int buffer_of(std::int32_t layers) const;  // the Mask::buffer of `layers`; kLoop when the mask was never planned
};

// `lights`: the frame's Light2D, `receivers`: the layer masks of the lit visuals without a normal map (repeats welcome).
// `bufferPath`: false when the light buffer is not in use (a perspective camera, a failed target): every mask is kLoop.
LightLayerPlan plan_light_layers(const std::vector<Light2DData>& lights, const std::vector<std::int32_t>& receivers,
                                 bool bufferPath, int maxBuffers = kMaxLightBuffers2D);

// Gives the lights that have a cookie a cell of the cookie atlas: one cell per distinct texture, in the order the lights come in, at
// most kMaxCookies2D. Light2DData::cookieCell is set (-1: no cookie, or the atlas is full). Returns the textures by cell; `dropped` gets
// how many distinct cookies did not fit.
std::vector<TextureAsset*> assign_cookie_cells(std::vector<Light2DData>& lights, int* dropped);

// The numbers a light with a cookie hands to the shaders (light_cookie.glsl): the cell as (u origin, v origin, v step, u step) in the
// atlas's sampling coordinates and the projection as (cos, sin, 1 / the cookie's width in world units, 0). `flipV`: the render target
// is stored upside down (OpenGL). All zero for a light without a cookie.
struct CookieShaderData {
    float cell[4] = {0, 0, 0, 0};
    float xf[4] = {0, 0, 0, 0};
};
CookieShaderData cookie_shader_data(const Light2DData& light, bool flipV);

}  // namespace fa::render
