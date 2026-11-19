// FactorIA post-process template (material kind "post", docs/design/CUSTOM_SHADERS.md, "Kinds (M72)"): the source of the full-screen
// program of a post-process material, one pass of the post stack (docs/design/ARCHITECTURE_RENDERING.md, "PostProcess (M71)").
// Not compiled on its own: a top file defines the @block fa_user (the material's uniforms, textures and snippet: void post(in
// PostInput i, inout PostSurface s)), then `@include post_common.glsl` and declares the program:
//   @program post vs fs
// The pass draws one full-screen triangle over ONE camera's rectangle of the picture (a split screen runs the pass once per
// camera). It reads the picture as the passes before it left it and writes the result of its pixel. Placed before the tonemap the
// picture is linear HDR colour (before the exposure and the tone mapping); placed after it (position "after:tonemap" and the places
// between the screen effects) it is the display-referred, sRGB-encoded picture the effects before it made (docs/shaders/SHADERS_POST.md).
//
// Every engine name of this file starts with fa_ (the snippet declares none), so a param or texture of a material is free to
// take any name that is not a GLSL keyword. A snippet may use the contract below and these helpers:
//   vec4  fa_scene_color(vec2 uv)   the picture at uv (0..1 over the camera's rectangle, origin top left, y down on every backend),
//                                   clamped to the rectangle, bilinear (linear light before the tonemap, display-referred after)
//   float fa_depth(vec2 uv)         the linear view depth in world units (the distance along the camera's forward axis); 60000
//                                   where no mesh was drawn (the sky, a sprite). Reading it makes the renderer draw the depth
//                                   and normal prepass for the camera
//   vec3  fa_normal(vec2 uv)        the view-space normal of the surface (x right, y up, z towards the camera); vec3(0) where no
//                                   mesh was drawn. Reads the same prepass as fa_depth
//   vec3  fa_scene_rgb(vec3 c)      an sRGB colour of the author (a param of type color) in the colour space of the picture (linear
//                                   light in a linear scene, as is in a gamma one)
//   fa_time                         vec4: x = seconds of game time since the scene started
//   vec4  fa_history(vec2 uv)       what THIS pass wrote last frame at uv (same uv rules as fa_scene_color; the output of the pass, after its
//                                   sanitising). Calling it makes the renderer keep that output in two images of the camera's size, one
//                                   pair per pass and camera. While there is no history (the first frame, a resize, a cut) it returns
//                                   fa_scene_color(uv) instead, so a trail or an echo starts from the picture, never from garbage
//   fa_history_valid                true when fa_history returns what the pass wrote last frame, false when it returns the picture
//
// Bindings. Uniform blocks: vertex 0 fa_post_vs_params, fragment 1 fa_post_params and 5 the material's (fa_material). Views 0
// (fa_scene) and 1 (fa_prepass) and samplers 0 (linear, clamped) and 1 (nearest) are the engine's: a material's textures are views
// 2.. and its samplers 2.. (engine/render/src/render_internal.h, kMaterialPost*). The prepass is declared always and bound only when
// the program uses it, which is when the snippet calls fa_depth or fa_normal (sokol-shdc drops an unused texture from the program).
//
// The pass output is sanitised like the final pass of post.glsl: a NaN or Inf becomes 0, a negative colour 0 and a finite one is kept up to 65504.

// The snippet contract (docs/shaders/SHADERS_POST.md).
@block fa_post_types
struct PostInput {              // read-only, per pixel
    vec2 uv;                    // 0..1 over the camera's rectangle, origin top left, y down on every backend
    vec2 texel;                 // size of one pixel in uv units (1 / size)
    vec2 size;                  // the camera's rectangle in pixels
    float time;                 // seconds of game time since the scene started (the same as fa_time.x)
};
struct PostSurface {            // what the pass writes
    vec4 color;                 // RGBA of the picture's colour space; arrives holding the picture at this pixel
};
@end

@vs vs
layout(binding=0) uniform fa_post_vs_params {
    vec4 fa_flip;               // x = 1 when render targets have their origin at the bottom (OpenGL), 0 otherwise
};
layout(location=0) in vec2 pos;
out vec2 fa_uv;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    float v_top_down = 0.5 - pos.y * 0.5;
    float v_bottom_up = 0.5 + pos.y * 0.5;
    fa_uv = vec2(pos.x * 0.5 + 0.5, mix(v_top_down, v_bottom_up, fa_flip.x));
}
@end

@fs fs
layout(binding=0) uniform texture2D fa_scene;       // the picture so far (the camera's rectangle of it)
layout(binding=1) uniform texture2D fa_prepass;     // r = linear view depth, gb = octahedral view normal, a = 1 where a mesh was drawn
layout(binding=6) uniform texture2D fa_history_tex;  // the output of this pass in the previous frame (the camera's rectangle size)
layout(binding=0) uniform sampler fa_scene_smp;
layout(binding=1) uniform sampler fa_prepass_smp;
@image_sample_type fa_prepass unfilterable_float
@sampler_type fa_prepass_smp nonfiltering

layout(binding=1) uniform fa_post_params {
    vec4 fa_a;                  // x = 1 when render targets are bottom-up (OpenGL), y = 1 in a linear scene (the picture is linear light),
                                // z = 1 when the history holds the pass's output of the frame before, w = 0
    vec4 fa_rc;                 // the camera's rectangle of the picture, fractions of it: xy corner, zw size (0 0 1 1 = all of it)
    vec4 fa_size;               // xy = the rectangle in pixels, zw = 1 / that
    vec4 fa_time;               // x = seconds of game time since the scene started
};

in vec2 fa_uv;
out vec4 fa_frag_color;

// top-left uv of the camera's rectangle <-> the uv of a render target of this backend (the same function both ways)
vec2 fa_flip_uv(vec2 s) { return vec2(s.x, mix(s.y, 1.0 - s.y, fa_a.x)); }

// The uv is kept within the pixel centres of the camera's rectangle: the first pass reads the whole picture, and a bilinear tap at the edge
// of the rectangle would otherwise blend in the pixels of the camera next to it (split screen), as the built-in effects do.
vec4 fa_scene_color(vec2 uv) {
    vec2 h = 0.5 * fa_size.zw;
    vec2 s = clamp(uv, h, 1.0 - h);
    return textureLod(sampler2D(fa_scene, fa_scene_smp), fa_flip_uv(s * fa_rc.zw + fa_rc.xy), 0.0);
}
vec4 fa_prepass_at(vec2 uv) {
    return textureLod(sampler2D(fa_prepass, fa_prepass_smp), fa_flip_uv(clamp(uv, vec2(0.0), vec2(1.0))), 0.0);
}
float fa_depth(vec2 uv) {
    vec4 p = fa_prepass_at(uv);
    return p.a > 0.5 ? p.r : 60000.0;
}
vec3 fa_normal(vec2 uv) {
    vec4 p = fa_prepass_at(uv);
    if (p.a < 0.5) return vec3(0.0);
    vec3 n = vec3(p.gb, 1.0 - abs(p.g) - abs(p.b));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * vec2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}
// The pass's own output of the frame before, read like the picture (uv over the camera's rectangle, y down, clamped to the pixel
// centres, bilinear). The history image has the rectangle's size, so a pixel is read back exactly. Without a history it is the picture.
#define fa_history_valid (fa_a.z > 0.5)
vec4 fa_history(vec2 uv) {
    if (!fa_history_valid) return fa_scene_color(uv);
    vec2 h = 0.5 * fa_size.zw;
    vec2 s = clamp(uv, h, 1.0 - h);
    return textureLod(sampler2D(fa_history_tex, fa_scene_smp), fa_flip_uv(s), 0.0);
}
// An sRGB colour of the author (a param of type color) in the colour space of the picture: decoded to linear light in a linear
// scene before the tonemap, as it is in a gamma scene and at the display-referred places (the picture is sRGB-encoded there).
vec3 fa_scene_rgb(vec3 c) {
    if (fa_a.y < 0.5) return c;
    vec3 lo = c / 12.92;
    vec3 hi = pow((c + 0.055) / 1.055, vec3(2.4));
    return mix(lo, hi, step(vec3(0.04045), c));
}
// One channel made safe: NaN and Inf (found by their bits, as post.glsl does) become 0, a negative becomes 0 and a finite value is
// kept up to 65504.
float fa_sane(float x) {
    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u) return 0.0;
    return clamp(x, 0.0, 65504.0);
}

@include_block fa_post_types
@include_block fa_user

void main() {
    vec2 s = fa_flip_uv(fa_uv);
    PostInput i;
    i.uv = s;
    i.texel = fa_size.zw;
    i.size = fa_size.xy;
    i.time = fa_time.x;
    PostSurface o;
    o.color = fa_scene_color(s);
    post(i, o);
    float a = ((floatBitsToUint(o.color.a) >> 23u) & 255u) == 255u ? 1.0 : clamp(o.color.a, 0.0, 1.0);
    fa_frag_color = vec4(fa_sane(o.color.r), fa_sane(o.color.g), fa_sane(o.color.b), a);
}
@end
