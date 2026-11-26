// FactorIA transmission copy (M73.6b): the opaque picture a transmissive mesh looks through. One program, one full-screen triangle drawn into a
// rectangle of the destination: the camera's rectangle of the game image, copied (mode 0) or reduced to half its size (mode 1), becomes one level
// of the "refraction atlas" the mesh shader reads at view 28 (renderer_xmit.h; the mesh side is block fa_transmission of brdf_layers.glsl).
//
// Coordinates are IMAGE ROWS: `uv` runs 0..1 across the destination rectangle with row 0 at the image's row 0 on every backend (the flip uniform
// is 1 where render targets are bottom-up, OpenGL), and the source rectangle `src` (corner and size in pixels) is given in the source image's
// own rows too, so nothing here depends on which way the picture is up.
//
//   mode 0  copy: one bilinear tap at the pixel centre (exactly the source pixel when the sizes match)
//   mode 1  reduce: four bilinear taps one source pixel off the centre (each averages 2x2), a smooth 4x4 weighting (no flicker when the picture moves)
//   mode 2  level 0 with the ray traced translucency (M79-P3b, rt_refract.hlsl): the copy, where the image of that kernel (tex_rt, the size of the
//           camera's rectangle) holds a traced pixel, replaced by what the glass shows there, with alpha 1; alpha 0 elsewhere. The kernel's alpha
//           says what to do (its header lists the three cases): 1 the colour rgb as it is; below 0 the picture read at the texel it encodes
//           (-(1 + u + 4096 v), the texel's position in 4096ths) times rgb, the light the glass volume let through
// Every tap is clamped inside the source rectangle, so a split-screen neighbour never bleeds in.
@module xmit

@vs vs
layout(binding=0) uniform xmit_vs_params {
    vec4 flip;      // x = 1 when render targets have their origin at the bottom (OpenGL), 0 otherwise
};
layout(location=0) in vec2 pos;
out vec2 uv;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    float v_top_down = 0.5 - pos.y * 0.5;
    float v_bottom_up = 0.5 + pos.y * 0.5;
    uv = vec2(pos.x * 0.5 + 0.5, mix(v_top_down, v_bottom_up, flip.x));
}
@end

@fs fs
layout(binding=0) uniform texture2D tex_src;
layout(binding=0) uniform sampler smp_lin;
layout(binding=1) uniform texture2D tex_rt;  // mode 2 only (the copy binds the picture there too when there is no traced image)
layout(binding=1) uniform sampler smp_pt;
@image_sample_type tex_rt unfilterable_float
@sampler_type smp_pt nonfiltering
layout(binding=1) uniform xmit_params {
    vec4 src;       // the source rectangle in pixels (image rows): xy corner, zw size
    vec4 info;      // xy = the source image's size in pixels, z = mode (0 copy, 1 reduce, 2 copy with the traced translucency)
};
in vec2 uv;
out vec4 frag_color;

vec4 tap(vec2 p) {
    // p in pixels of the source image, clamped half a pixel inside the rectangle
    vec2 q = clamp(p, src.xy + 0.5, src.xy + src.zw - 0.5);
    return texture(sampler2D(tex_src, smp_lin), q / info.xy);
}

void main() {
    vec2 p = src.xy + uv * src.zw;
    if (info.z > 1.5) {
        ivec2 px = ivec2(min(floor(uv * src.zw), src.zw - 1.0));
        vec4 rt = texelFetch(sampler2D(tex_rt, smp_pt), px, 0);
        if (rt.a > 0.5) {
            frag_color = vec4(rt.rgb, 1.0);
        } else if (rt.a < -0.5) {
            float code = -rt.a - 1.0;
            float v12 = floor(code / 4096.0);
            float u12 = code - v12 * 4096.0;
            vec2 quv = (vec2(u12, v12) + 0.5) / 4096.0;
            frag_color = vec4(tap(src.xy + quv * src.zw).rgb * rt.rgb, 1.0);
        } else {
            frag_color = vec4(tap(p).rgb, 0.0);
        }
    } else if (info.z < 0.5) {
        frag_color = tap(p);
    } else {
        vec2 o = vec2(1.0);
        frag_color = 0.25 * (tap(p + vec2(-o.x, -o.y)) + tap(p + vec2(o.x, -o.y)) + tap(p + vec2(-o.x, o.y)) + tap(p + vec2(o.x, o.y)));
    }
}
@end

@program copy vs fs
