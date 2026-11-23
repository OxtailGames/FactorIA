// FactorIA temporal antialiasing (PostEffect::TemporalAA, M76-P2): two full-screen passes over ONE camera's rectangle of the picture.
//
//   fs_taa   resolves the jittered picture of this frame with the history of the frames before into the next history image (rgb = the
//            colour, a = the linear depth of its pixel, or 1 where the history is 8-bit); the maths are in taa_shared.glsl, which the temporal
//            upscaler shares.
//   fs_out   copies the history into the camera's rectangle of the picture, sharpened (the history itself is not: a sharpened history would
//            sharpen again at every frame). It writes red, green and blue only: the alpha of the picture stays.
@module taa

@include taa_shared.glsl

@vs vs
layout(binding=0) uniform taa_vs_params {
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

@fs fs_taa
layout(binding=0) uniform texture2D tex_c;
layout(binding=1) uniform texture2D tex_p;
layout(binding=2) uniform texture2D tex_v;
layout(binding=3) uniform texture2D tex_h;
layout(binding=4) uniform texture2D tex_r;
layout(binding=0) uniform sampler smp_lin;
layout(binding=1) uniform sampler smp_pt;
@image_sample_type tex_p unfilterable_float
@image_sample_type tex_v unfilterable_float
@image_sample_type tex_r unfilterable_float
@sampler_type smp_pt nonfiltering
@include_block taa_uniforms
in vec2 uv;
out vec4 frag_color;

@include_block taa_resolve_fn

void main() {
    vec2 s = taa_fl(uv);
    TaaResult r = taa_resolve(s, a.yz, hs.xy, j.xy);
    // Where the history holds 8 bits there is no depth in it (and its colour is clamped to 0..1).
    frag_color = vec4(f.w > 0.5 ? r.color : clamp(r.color, 0.0, 1.0), f.w > 0.5 ? r.depth : 1.0);
}
@end

@fs fs_out
layout(binding=5) uniform texture2D tex_o;
layout(binding=2) uniform sampler smp_o;
@include_block taa_uniforms
in vec2 uv;
out vec4 frag_color;

// The colour with its largest channel squeezed into 0..2 and back (taa_compress and taa_expand of taa_shared.glsl, which need its textures).
vec3 taa_o_squeeze(vec3 c) {
    float m = max(max(c.r, c.g), c.b);
    return m <= 1.0 ? c : c * ((2.0 - 1.0 / m) / m);
}
vec3 taa_o_unsqueeze(vec3 c) {
    float m = max(max(c.r, c.g), c.b);
    return m <= 1.0 ? c : c * ((1.0 / (2.0 - min(m, 1.99998))) / m);
}
vec3 taa_o_tap(vec2 t) {
    return taa_o_squeeze(textureLod(sampler2D(tex_o, smp_o), clamp(t, 0.5 / hs.xy, 1.0 - 0.5 / hs.xy), 0.0).rgb);
}

void main() {
    vec2 px = 1.0 / hs.xy;
    vec3 c = taa_o_tap(uv);
    vec3 n = 0.25 * (taa_o_tap(uv + vec2(px.x, 0.0)) + taa_o_tap(uv - vec2(px.x, 0.0)) + taa_o_tap(uv + vec2(0.0, px.y)) +
                     taa_o_tap(uv - vec2(0.0, px.y)));
    vec3 o = max(c + g.z * (c - n), 0.0);  // sharpened where the colour is squeezed to 0..2: no halo on a bright pixel
    frag_color = vec4(taa_o_unsqueeze(o), 1.0);
}
@end

@program taa vs fs_taa
@program out vs fs_out
