// FactorIA sprite template (material kind "sprite", docs/design/CUSTOM_SHADERS.md, "Kinds (M72)"): the source of every 2D quad
// program, the engine's own (quad.glsl: Sprite, Shape2D, Tilemap, Text glyphs, particles, trails, debug lines, UI images)
// and every sprite material's. Not compiled on its own: a top file defines the @block fa_user (the material's uniforms,
// textures and snippet: void fragment(in QuadInput i, inout QuadSurface s) and, with FA_HAS_VERTEX defined, void
// vertex(inout QuadVertex v)), then `@include quad_common.glsl` and declares the programs:
//   @program quad vs fs                (quad.glsl does exactly this with an empty fragment())
//   @program quad_plain vs fs_plain
// A material's top file defines FA_MATERIAL (and FA_HAS_VERTEX when its snippet has a vertex()); the engine's own programs define
// neither. A custom material's generated top file has this very shape with its own fa_user block, so a sprite material whose fragment()
// is empty draws exactly the pixels the engine's own quad program does.
//
// The engine names of this file (the vertex attributes, the varyings, the uniform block members, the textures and samplers,
// tex_color, shape_color...) are not prefixed: they are the ones the renderer's C++ code binds by (the generated header's
// ATTR_/UB_/VIEW_/SMP_ constants and quad_vs_params_t / quad_quad_fs_params_t members), so a param or texture of a material must
// not take any of them (parse_material refuses them: tools/common/src/shaders_generate.cpp, template_globals reads this file and
// its @includes, so a new global here is covered without a list to update). What a snippet may use is the contract below
// and the fa_ names: fa_time, fa_sample_main(), fa_scene_rgb(), and (fragment stage only) fa_scene_color(uv) with fa_world_to_uv(p):
// the picture drawn so far in the camera job (view 12, `fa_scene_tex`, declared by the program only when the snippet calls it; the
// renderer then copies the target before the item, docs/rendering/RENDERING_2D_WATER.md).
//
// Bindings. Uniform blocks: vertex 0 vs_params (+ 4 for the material's vertex-stage block), fragment 1 quad_fs_params (+ 5 for
// the material). Views 0-3 (tex, normal_tex, light_tex, shadow_tex) and samplers 0-2 (smp, light_smp, shadow_smp) are the
// engine's: a material's textures are views 4.. and its samplers 3.. (engine/render/src/render_internal.h, kMaterialSprite*).
//
// What fragment() receives. s.color holds what the engine would draw for the mode (below), before the flash, the multiply
// conversion and the fog, which the engine applies to the result: an empty fragment() is the built-in look. For the modes 1, 2,
// 3, 4 and 7 the alpha holds the coverage (circle, ring, soft falloff, glyph, SDF shape) times the tint's alpha; the lit modes
// (5, 6 and the +16 ones) arrive already lit by the 2D lights.
//
// The modes, as the vertex format carries them:
// One vertex format for everything:  pos.xyz | uv | color (ubyte4n) | params (mode, aux)
// mode 0 = textured quad (texture * color)
// mode 1 = anti-aliased filled circle   (uv in [-1,1], coverage from the distance to the center)
// mode 2 = anti-aliased ring            (aux = inner radius as a fraction of the outer radius)
// mode 3 = soft round particle          (smooth radial falloff)
// mode 4 = glyph                        (single-channel coverage texture * color)
// mode 5 = lit textured quad            (texture * color * (ambient + 2D lights); aux = angle in radians of the picture's
//                                        right axis in the world, for the normal map)
// mode 6 = like 5, but the picture is mirrored: its up axis lies to the right of its right axis
// mode 7 = SDF shape: a rectangle with rounded corners or a circle (Shape2D.cornerRadius / softness / gradient). uv = the
//          position in the shape's box in units of its half size (so [-1,1] covers the box), shape_half = that half size in
//          local units, shape_rs = (corner radius, softness) in local units, color2 = the gradient's end colour.
//          aux: -1 flat fill; 0..2pi linear gradient, the angle in radians; 10 radial gradient; <= -2 outline of thickness
//          -aux - 2 (growing inward). Gradients and soft edges are dithered.
//          aux + 20 (aux >= 0 only): the gradient is read from a ramp texture (the item's texture, one row per gradient; see
//          engine/render/src/gradient_ramp.h) instead of blended from color to color2: color2.r * 255 is the row, the position
//          along the gradient is the u coordinate. This is how Shape2D gradientStops / gradientEase are drawn.
// mode + 16 = (modes 0, 1, 2, 7 only) the same output, shaded by the 2D lights like mode 5 with a flat surface (lit Shape2D)
// mode + 32 = (modes 0, 1, 2, 5, 6) the flash of docs/GAME_FEEL.md: after shading, the output colour is mixed towards color2.rgb
//            by color2.a (full-bright, whatever the lights say); the alpha of the picture is kept. Not for modes 4 and 7, which
//            use color2 or none.
// mode + 8 = same shading, but the output is converted for MULTIPLY blending (dst * out.rgb):
//            rgb = mix(1, rgb, alpha) so alpha fades the darkening in (blend: src=DST_COLOR, dst=ZERO).

// The snippet contract (docs/SHADERS.md, "Materials on sprites, shapes, tiles, text and particles").
@block fa_quad_types
struct QuadInput {              // read-only, per fragment
    vec2 uv;                    // texture coordinates; modes 1, 2, 3 and 7: the position in the shape's box, [-1,1] covers it
    vec4 color;                 // the tint of the sprite, shape or glyph (vertex color; linear in a linear scene)
    vec2 world_pos;             // world position (x, y) of the fragment
    vec2 screen_uv;             // position in the render target, 0..1, y running DOWN on every backend
    float time;                 // seconds of game time since the scene started (the same as fa_time.x)
    float mode;                 // what is drawn: 0 texture, 1 circle, 2 ring, 3 soft particle, 4 glyph, 5/6 lit, 7 SDF shape
    vec4 custom;                // reserved: zero (per-sprite values are the material's instanced params, read by name)
    float life;                 // particles: how far the particle is through its life, 0 at birth to 1 at its end; 0 for everything else
};
struct QuadSurface {            // what the quad pipeline draws
    vec4 color;                 // straight (non-premultiplied) RGBA; arrives holding the engine's result for the mode
};
struct QuadVertex {             // vertex(): world space
    vec3 world_pos;             // the position of the corner; moving it moves the picture (and its fog and lights)
    vec2 uv;                    // texture coordinates (see QuadInput.uv)
    vec4 color;                 // the tint of the corner (linear in a linear scene)
};
@end

// Per-instance params of a sprite material (docs/SHADERS.md, "Per-instance params and vertex channels"). The generator defines FA_INST_1..3, the vec4
// of per-instance data the material's instanced params need; the engine's own programs have none and keep their attributes. The
// data is vertex buffer 1, attributes 7.. of the vertex shader: one value per quad, written to its four corners, so quads with
// different values still share one draw. The varyings are `flat`: the value of the first corner reaches fragment() unchanged.
@block fa_inst_flags
#if defined(FA_INST_3)
#define FA_NINST 3
#elif defined(FA_INST_2)
#define FA_NINST 2
#elif defined(FA_INST_1)
#define FA_NINST 1
#else
#define FA_NINST 0
#endif
@end

// A material with "buffers" (M72.4, docs/shaders/SHADERS_COMPUTE.md, "Sprites from a compute buffer") defines FA_BUFFER_INST: its Sprite draws
// Sprite.instances quads in ONE draw (the sprite's own quad, instanced), vertex() finds its instance in fa_instance_index
// (gl_InstanceIndex, 0 .. instances - 1) and moves the quad; fragment() reads the same number through a flat varying. A material
// without buffers draws every quad once: fa_instance_index is 0 there.
@block fa_inst_out
#ifdef FA_BUFFER_INST
flat out int fa_inst_index_v;
#endif
#if FA_NINST > 0
flat out vec4 fa_inst_v0;
#if FA_NINST > 1
flat out vec4 fa_inst_v1;
#endif
#if FA_NINST > 2
flat out vec4 fa_inst_v2;
#endif
#endif
@end

@block fa_inst_in
#ifdef FA_BUFFER_INST
flat in int fa_inst_index_v;
#define fa_instance_index fa_inst_index_v
#else
#define fa_instance_index 0
#endif
#if FA_NINST > 0
flat in vec4 fa_inst_v0;
#if FA_NINST > 1
flat in vec4 fa_inst_v1;
#endif
#if FA_NINST > 2
flat in vec4 fa_inst_v2;
#endif
#endif
@end

@include light_shadow.glsl
@include color_space.glsl

@vs vs
layout(binding=0) uniform vs_params {
    mat4 view_proj;
    vec4 cspace;            // x = 1 in a linear scene (SceneSettings.colorSpace): the vertex colours are sRGB values and are
                            //     decoded to linear here, with all the precision of a float (a ubyte4n cannot hold linear darks);
                            // y = the fix of `tex` (fa_tex_fix: 0 as sampled, 1 sRGB -> linear, 2 linear -> sRGB), z = the same
                            //     for normal_tex; x = y = z = 0 in a gamma scene with 8-bit textures: every output is as before M71
    vec4 fa_time;           // x = seconds of game time since the scene started (a snippet reads it; 0 for the engine's own programs)
};
@include_block color_space
@include_block fa_inst_flags
@include_block fa_quad_types

// What the snippet may call from vertex() (and from a helper of its own, which is compiled into both stages): an sRGB colour of the
// author in the scene's colour space. fa_sample_main() exists in the fragment stage only: the main texture is not bound here.
vec3 fa_scene_rgb(vec3 c) { return cspace.x > 0.5 ? fa_srgb_to_linear(c) : c; }

// The instance of a material with buffers (see fa_inst_out); 0 when the quad is drawn once.
#define fa_instance_index gl_InstanceIndex

@include_block fa_user

layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord0;
layout(location=2) in vec4 color0;
layout(location=3) in vec2 params0;
layout(location=4) in vec4 color2_0;
layout(location=5) in vec2 shape_half0;
layout(location=6) in vec2 shape_rs0;
#if FA_NINST > 0
layout(location=7) in vec4 fa_inst_d0;
#endif
#if FA_NINST > 1
layout(location=8) in vec4 fa_inst_d1;
#endif
#if FA_NINST > 2
layout(location=9) in vec4 fa_inst_d2;
#endif

out vec2 uv;
out vec4 color;
out vec2 params;
out vec2 world_xy;
out vec4 color2;
out vec2 shape_half;
out vec2 shape_rs;
out vec3 xform;
out float world_z;
@include_block fa_inst_out

void main() {
#ifdef FA_BUFFER_INST
    fa_inst_index_v = gl_InstanceIndex;
#endif
#if FA_NINST == 1
    fa_instance_unpack(fa_inst_d0, vec4(0.0), vec4(0.0));
#elif FA_NINST == 2
    fa_instance_unpack(fa_inst_d0, fa_inst_d1, vec4(0.0));
#elif FA_NINST == 3
    fa_instance_unpack(fa_inst_d0, fa_inst_d1, fa_inst_d2);
#endif
#if FA_NINST > 0
    fa_inst_v0 = fa_inst_d0;
#endif
#if FA_NINST > 1
    fa_inst_v1 = fa_inst_d1;
#endif
#if FA_NINST > 2
    fa_inst_v2 = fa_inst_d2;
#endif
    QuadVertex v;
    v.world_pos = position;
    v.uv = texcoord0;
    v.color = color0;
    if (cspace.x > 0.5) v.color.rgb = fa_srgb_to_linear(color0.rgb);
#ifdef FA_HAS_VERTEX
    vertex(v);
#endif
    gl_Position = view_proj * vec4(v.world_pos, 1.0);
    uv = v.uv;
    color = v.color;
    xform = cspace.xyz;
    params = params0;
    world_xy = v.world_pos.xy;
    world_z = v.world_pos.z;
    color2 = color2_0;
    shape_half = shape_half0;
    shape_rs = shape_rs0;
}
@end

@block quad_fs_uniforms
// Only read by lit quads (mode 5, 6 and the lit shapes). Up to 16 lights: 53 vec4s, far below the WebGL2 / GLES3 minimum
// of 224.
layout(binding=1) uniform quad_fs_params {
    vec4 lit;                  // x = number of lights in the arrays, y = 1 when normal_tex is a real normal map,
                               // z = how a flat surface (no normal map) is lit: 0 = the loop below over the arrays,
                               //     1 = ambient + directional lights (flat_ambient) + the light buffer, 2 = flat_ambient only
    vec4 ambient;              // rgb
    vec4 normal_uv;            // normal map uv = uv * xy + zw
    vec4 flat_ambient;         // rgb: ambient + every directional light, what a flat surface gets from them (lit.z > 0)
    vec4 light_map;            // xy = 1 / the size of the target in pixels, z = the range the light buffer holds
    vec4 light_pos[16];        // point: xyz position (z = height), w radius; directional: xyz unit vector TO the light, w = -1
    vec4 light_color[16];      // rgb color * intensity; w falloff exponent
    vec4 light_shadow_v[16];   // x = v coordinate of the light's row in shadow_tex, -1 = it casts no shadow
    // The fog of the camera's post stack (PostProcess.fog*) on the quads of the world: the same formula as fog.glsl. Only the full
    // program reads it (a batch under stack fog never uses quad_plain). All 0 without that fog: nothing changes.
    vec4 fog_col;              // rgb = what the quad fades to (the fog colour; 0 for an additive quad, 1 for a multiplying one), w = density
    vec4 fog_b;                // x = fogStart, y = height density, z = height base (world y), w = height falloff
    vec4 fog_c;                // xyz = the camera's forward axis, w = 1 for an orthographic camera
    vec4 fog_eye;              // xyz = the camera's world position
    // For the snippets of sprite materials (the engine's own programs never read them): zero in a program without a material.
    vec4 fa_time;              // x = seconds of game time since the scene started
    vec4 fa_target;            // xy = 1 / the size of the render target in pixels, z = 1 when render targets have their origin at the
                               // bottom (OpenGL), which flips screen_uv.y so that it runs down on every backend
    // For a material that calls fa_scene_color() / fa_world_to_uv() (the renderer fills them only for those; zero otherwise).
    vec4 fa_scene;             // screen_uv * xy + zw = the position in the copy of the picture drawn so far (0..1 over the camera's
                               // rectangle, y down); the copy is the camera's rectangle of the target
    vec4 fa_world_uv[3];       // rows of the camera's view-projection already turned into screen_uv: u = row0 . p / row2 . p,
                               // v = row1 . p / row2 . p for p = (world x, y, z, 1)
};
@end

@block fa_quad_fs_common
@include_block fa_inst_flags
@include_block fa_inst_in
@include_block fa_quad_types

// The sample of `tex` as a colour: decoded to linear (or encoded back) as xform.y says.
vec4 tex_color(vec2 p) {
    vec4 t = texture(sampler2D(tex, smp), p);
    return vec4(fa_tex_fix(t.rgb, xform.y), t.a);
}
// A colour that is not in the vertex (color2: the end of a gradient, the colour of a flash): sRGB values -> linear in a linear scene.
vec3 scene_rgb(vec3 c) {
    if (xform.x > 0.5) c = fa_srgb_to_linear(c);
    return c;
}

// What the snippet may call from fragment().
vec4 fa_sample_main(vec2 p) { return tex_color(p); }   // the main texture of the sprite, in the colour space of the scene
vec3 fa_scene_rgb(vec3 c) { return scene_rgb(c); }     // an sRGB colour of the author (a param of type color) in the scene's space

// The picture drawn so far in the camera (everything under this item: sorted before it), at `uv` (0..1 over the render target, y down: the
// space of i.screen_uv), bilinear and clamped to the picture's edge. Calling it is what asks the renderer to keep a copy of the picture
// before the item is drawn (docs/shaders/SHADERS_SPRITES.md, "The scene colour"); in the HUD (space "screen") there is none and it returns
// transparent black. The alpha is the picture's.
vec4 fa_scene_color(vec2 uv) {
    if (fa_scene.x <= 0.0) return vec4(0.0);   // no copy of the picture here (the HUD, a debug draw)
    vec2 p = uv * fa_scene.xy + fa_scene.zw;
    p.y = mix(p.y, 1.0 - p.y, fa_target.z);   // the copy keeps the image rows of the target: bottom first in OpenGL
    return textureLod(sampler2D(fa_scene_tex, light_smp), clamp(p, vec2(0.0), vec2(1.0)), 0.0);
}
// Where a world position lands on the screen, as screen_uv (0..1 over the render target, y down; outside 0..1 = off screen): to read
// fa_scene_color at another place of the world, such as the mirror image of this pixel in water.
vec2 fa_world_to_uv(vec3 world) {
    vec4 q = vec4(world, 1.0);
    float w = dot(fa_world_uv[2], q);
    return vec2(dot(fa_world_uv[0], q), dot(fa_world_uv[1], q)) / (abs(w) > 1e-6 ? w : 1.0);
}

// The screen position of the fragment as the snippet sees it: 0..1 over the render target, y running down on every backend.
vec2 fa_screen_uv() {
    vec2 p = gl_FragCoord.xy * fa_target.xy;
    return vec2(p.x, mix(p.y, 1.0 - p.y, fa_target.z));
}

QuadInput fa_quad_input(float base_mode) {
    QuadInput i;
    i.uv = uv;
    i.color = color;
    i.world_pos = world_xy;
#ifdef FA_MATERIAL
    i.screen_uv = fa_screen_uv();
    i.time = fa_time.x;
#else
    // The engine's own programs do not read fa_time and fa_target: the lean quad_plain program has no uniform block at all.
    i.screen_uv = vec2(0.0);
    i.time = 0.0;
#endif
    i.mode = base_mode;
    i.custom = vec4(0.0);
    // A particle quad of a material carries its life in the shape half-size slot (modes 0 and 3 never read it otherwise).
    i.life = (base_mode < 0.5 || (base_mode > 2.5 && base_mode < 3.5)) ? shape_half.x : 0.0;
    return i;
}

@include_block fa_user

// Loads the flat varyings into the globals the generator declared for the instanced params (before fragment() reads them).
void fa_inst_load() {
#if FA_NINST == 1
    fa_instance_unpack(fa_inst_v0, vec4(0.0), vec4(0.0));
#elif FA_NINST == 2
    fa_instance_unpack(fa_inst_v0, fa_inst_v1, vec4(0.0));
#elif FA_NINST == 3
    fa_instance_unpack(fa_inst_v0, fa_inst_v1, fa_inst_v2);
#endif
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=1) uniform texture2D normal_tex;   // lit quads: the normal map (a 1x1 image when unused)
layout(binding=2) uniform texture2D light_tex;    // lit quads, light buffer path: the point lights added up (light.glsl)
layout(binding=3) uniform texture2D shadow_tex;   // lit quads with a shadow caster in reach: one row per light (light_shadow.glsl)
layout(binding=12) uniform texture2D fa_scene_tex; // fa_scene_color(): the picture drawn so far (declared by the program only when the snippet calls it)
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform sampler light_smp;      // bilinear: the light buffer may be smaller than the target
layout(binding=2) uniform sampler shadow_smp;     // nearest

@include_block quad_fs_uniforms

in vec2 uv;
in vec4 color;
in vec2 params;
in vec2 world_xy;
in vec4 color2;
in vec2 shape_half;
in vec2 shape_rs;
in vec3 xform;
in float world_z;
out vec4 frag_color;

@include_block light_shadow
@include_block color_space

@include_block fa_quad_fs_common

vec3 lit_color(vec4 base, float mode) {
    vec3 n = vec3(0.0, 0.0, 1.0);
    bool use_normal = lit.y > 0.5;
    if (use_normal) {
        vec3 s = fa_tex_fix(texture(sampler2D(normal_tex, smp), uv * normal_uv.xy + normal_uv.zw).xyz, xform.z) * 2.0 - 1.0;
        float a = params.y;
        vec2 t = vec2(cos(a), sin(a));
        vec2 b = vec2(-t.y, t.x) * (mode > 5.5 ? -1.0 : 1.0);
        n = normalize(vec3(s.x * t + s.y * b, max(s.z, 0.05)));
    }
    // One return at the end: fxc warns (X4000, logged at run time on D3D11) about an early return before the loop.
    bool flat_lit = !use_normal && lit.z > 0.5;
    vec3 total = flat_lit ? flat_ambient.rgb : ambient.rgb;
    if (flat_lit && lit.z < 1.5) {
        // A flat surface faces every light head on, so each light adds color * falloff and they add up: the light buffer
        // already holds that sum (gl_FragCoord is the pixel of the same target, in the same orientation).
        total += textureLod(sampler2D(light_tex, light_smp), gl_FragCoord.xy * light_map.xy, 0.0).rgb * light_map.z;
    }
    for (int i = 0; i < 16; i++) {
        if (flat_lit || float(i) >= lit.x) { break; }
        vec4 lp = light_pos[i];
        vec4 lc = light_color[i];
        vec3 l;
        float att = 1.0;
        if (lp.w < 0.0) {
            l = lp.xyz;
        } else {
            vec2 d = lp.xy - world_xy;
            float dist = length(d);
            att = pow(clamp(1.0 - dist / max(lp.w, 0.001), 0.0, 1.0), lc.w);
            l = vec3(d, lp.z) / max(length(vec3(d, lp.z)), 0.0001);
            if (light_shadow_v[i].x >= 0.0) { att *= light_shadow(light_shadow_v[i].x, -d, lp.w); }
        }
        float ndl = use_normal ? max(dot(n, l), 0.0) : 1.0;
        total += lc.rgb * (att * ndl);
    }
    return base.rgb * total;
}

// Mode 7: the colour and alpha of one pixel of a rounded rectangle / circle, with its gradient and soft edge.
vec4 shape_color() {
    vec2 hs = max(shape_half, vec2(1e-4));
    vec2 p = uv * hs;
    float r = clamp(shape_rs.x, 0.0, min(hs.x, hs.y));
    float soft = shape_rs.y;
    vec2 q = abs(p) - hs + r;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;   // signed distance to the outline, < 0 inside
    float ax = params.y;
    bool ramp = ax > 15.0;
    if (ramp) ax -= 20.0;
    float ring = ax <= -1.5 ? (-ax - 2.0) : 0.0;
    if (ring > 0.0) d = abs(d + ring * 0.5) - ring * 0.5;          // an outline growing inward
    float aa = max(fwidth(d), 1e-4);
    float w = max(soft, aa);
    float t = clamp(0.5 - d / w, 0.0, 1.0);
    float cov = soft > aa ? t * t * (3.0 - 2.0 * t) : t;
    vec4 c = color;
    bool graded = ring <= 0.0 && ax > -0.5;
    if (graded) {
        float g;
        if (ax > 7.0) {
            g = length(uv);
        } else {
            vec2 dir = vec2(cos(ax), sin(ax));
            g = dot(p, dir) / max(abs(dir.x) * hs.x + abs(dir.y) * hs.y, 1e-4) * 0.5 + 0.5;
        }
        g = clamp(g, 0.0, 1.0);
        // Blend premultiplied, so fading to a transparent colour does not darken the middle of the gradient.
        if (ramp) {
            // Straight-alpha texels (the filtering blends them; the stops are baked premultiplied), level 0 only.
            c = textureLod(sampler2D(tex, smp), vec2((0.5 + g * 255.0) / 256.0, (floor(color2.r * 255.0 + 0.5) + 0.5) / 256.0), 0.0);
            c.rgb = fa_tex_fix(c.rgb, xform.y);
        } else {
            vec3 end_rgb = scene_rgb(color2.rgb);
            vec4 pm = mix(vec4(color.rgb * color.a, color.a), vec4(end_rgb * color2.a, color2.a), g);
            c = vec4(pm.a > 1e-5 ? pm.rgb / pm.a : color.rgb, pm.a);
        }
    }
    c.a *= cov;
    if (graded || soft > 0.0) {
        // Interleaved gradient noise, +-0.5/255: breaks the 8-bit steps of a slow gradient or a wide soft edge into fine grain.
        float n = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715)))) - 0.5;
        // The grain is added in the display's encoding: that is where its 8-bit steps are.
        if (xform.x > 0.5) {
            c.rgb = fa_srgb_to_linear(fa_linear_to_srgb(c.rgb) + n / 255.0);
        } else {
            c.rgb += n / 255.0;
        }
        c.a = clamp(c.a + n / 255.0 * step(0.001, c.a), 0.0, 1.0);
    }
    return c;
}

void main() {
    float mode = params.x;
    bool flash = mode > 31.5;
    if (flash) mode -= 32.0;
    bool shade = mode > 15.5;
    if (shade) mode -= 16.0;
    bool mul = mode > 7.5;
    if (mul) mode -= 8.0;
    if (mode < 0.5) {
        frag_color = tex_color(uv) * color;
        if (shade) frag_color = vec4(lit_color(frag_color, 5.0), frag_color.a);
    } else if (mode > 6.5) {
        frag_color = shape_color();
        if (shade) frag_color = vec4(lit_color(frag_color, 5.0), frag_color.a);
    } else if (mode > 4.5) {
        vec4 base = tex_color(uv) * color;
        frag_color = vec4(lit_color(base, mode), base.a);
    } else if (mode > 3.5) {
        frag_color = vec4(color.rgb, color.a * texture(sampler2D(tex, smp), uv).r);
    } else {
        float d = length(uv);
        float aa = max(fwidth(d), 1e-4);
        float cov;
        if (mode < 1.5) {
            cov = clamp((1.0 - d) / aa + 0.5, 0.0, 1.0);
        } else if (mode < 2.5) {
            float outer = clamp((1.0 - d) / aa + 0.5, 0.0, 1.0);
            float inner = clamp((d - params.y) / aa + 0.5, 0.0, 1.0);
            cov = outer * inner;
        } else {
            float t = clamp(1.0 - d, 0.0, 1.0);
            cov = t * t * (3.0 - 2.0 * t);
        }
        frag_color = vec4(shade ? lit_color(color, 5.0) : color.rgb, color.a * cov);
    }
    // The material's fragment() (an empty one in the engine's own program) sees what the mode drew, before the flash, the multiply
    // conversion and the fog.
    QuadInput fa_in = fa_quad_input(mode);
    QuadSurface fa_surf;
    fa_surf.color = frag_color;
    fa_inst_load();
    fragment(fa_in, fa_surf);
    frag_color = fa_surf.color;
    if (flash) frag_color.rgb = mix(frag_color.rgb, scene_rgb(color2.rgb), color2.a);
    if (mul) frag_color = vec4(mix(vec3(1.0), frag_color.rgb, frag_color.a), 1.0);
    if (fog_col.w > 0.0 || fog_b.y > 0.0) {
        vec3 rel = vec3(world_xy, world_z) - fog_eye.xyz;
        float dep = dot(rel, fog_c.xyz);
        float dist = fog_c.w > 0.5 ? dep : length(rel);
        float len = dist - fog_b.x;
        if (len > 0.0) {
            float tau = fog_col.w * len;
            tau *= tau;
            if (fog_b.y > 0.0) {
                float py = world_xy.y;
                float ey = fog_c.w > 0.5 ? py - fog_c.y * dep : fog_eye.y;
                float ya = mix(ey, py, clamp(fog_b.x / dist, 0.0, 1.0));
                float dy = py - ya;
                float ka = ya - fog_b.z;
                float kb = py - fog_b.z;
                float ha = (ka <= 0.0 || fog_b.w < 1e-4) ? fog_b.y : fog_b.y * exp(-min(fog_b.w * ka, 80.0));
                float ia = (ka <= 0.0 || fog_b.w < 1e-4) ? fog_b.y * ka : fog_b.y * (1.0 - exp(-min(fog_b.w * ka, 80.0))) / fog_b.w;
                float ib = (kb <= 0.0 || fog_b.w < 1e-4) ? fog_b.y * kb : fog_b.y * (1.0 - exp(-min(fog_b.w * kb, 80.0))) / fog_b.w;
                float avg = abs(dy) < 1e-3 ? ha : (ib - ia) / dy;
                tau += len * max(avg, 0.0);
            }
            float f = 1.0 - exp(-clamp(tau, 0.0, 80.0));
            frag_color.rgb = mix(frag_color.rgb, fog_col.rgb, clamp(f, 0.0, 1.0));
        }
    }
}
@end

// The plain variant, for batches whose quads are all mode 0 (not lit, not multiply): the output of mode 0 above, without
// the branches. Software rasterizers (llvmpipe, WARP) run every branch of `fs` for every pixel, all its texture fetches
// and light loops included, so a screen-sized sprite, panel or video costs several times more there with `fs`.
// A material's fs_plain still reads uniform block 1 (quad_fs_params): fa_time and fa_target, and the fog, come from it. Only the
// engine's own plain program (no FA_MATERIAL) has no uniform block at all.
@fs fs_plain
layout(binding=0) uniform texture2D tex;
layout(binding=12) uniform texture2D fa_scene_tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform sampler light_smp;

in vec2 uv;
in vec4 color;
in vec2 params;
in vec2 world_xy;
in vec4 color2;
in vec2 shape_half;
in vec2 shape_rs;
in vec3 xform;
in float world_z;
out vec4 frag_color;

@include_block quad_fs_uniforms
@include_block color_space
@include_block fa_quad_fs_common

void main() {
    vec4 t = texture(sampler2D(tex, smp), uv);
    frag_color = vec4(fa_tex_fix(t.rgb, xform.y), t.a) * color;
    QuadInput fa_in = fa_quad_input(0.0);
    QuadSurface fa_surf;
    fa_surf.color = frag_color;
    fa_inst_load();
    fragment(fa_in, fa_surf);
    frag_color = fa_surf.color;
}
@end
