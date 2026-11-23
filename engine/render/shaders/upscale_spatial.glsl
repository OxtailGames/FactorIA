// FactorIA spatial upscaler (M76, render.upscaler mode "spatial"): two fragment passes, on every backend (never compute).
//
//   fs_edge     brings the picture drawn at the render resolution to the output resolution. Each output pixel reads 12 texels (the
//               4x4 block around it without its corners), estimates the direction of the edge there from the luma gradient of the
//               four texels it lies between, and weights the 12 texels with a Catmull-Rom kernel measured in a stretched metric:
//               narrower across the edge (the edge stays hard) and longer along it (the stairs of a diagonal are smoothed). The
//               result is clamped to the lowest and highest value of those four texels, so the kernel's negative lobes never
//               ring past the picture's own range.
//   fs_sharpen  a contrast-adaptive sharpen at the output resolution: the pixel is pushed away from the mean of its four
//               neighbours by an amount that shrinks where the local contrast is already high (no halos on strong edges, no gain
//               on noise-free flat areas), and clamped to the range of those five values.
//
// Colour space. A linear scene without a final pass holds linear light, which may go far above 1 (an HDR float image): filtering
// that directly rings and clips. `lin` says so, and the filters then work on sqrt(c / (1 + c)), a reversible tonemap that is also
// close to a gamma 2 curve (0..inf -> 0..1), and go back with c = p^2 / (1 - p^2) before writing, so the image keeps its space. After
// a final pass (or in an sRGB-encoded 8-bit scene) the picture already holds display values, which are filtered as they are.
// Alpha is the bilinear mix of the four nearest texels (fs_edge) or untouched (fs_sharpen).
// No copy of any other implementation: the structure is common to the family of edge-adaptive upscalers, the maths is ours.
@module upscale_spatial

@vs vs
layout(location=0) in vec2 pos;
out vec2 uv;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    // The picture is stored like the game image on every backend (no flip): the same uv as blit.glsl with flip 0.
    uv = vec2(pos.x * 0.5 + 0.5, 0.5 - pos.y * 0.5);
}
@end

@block spatial_common
// The perceptual space of the filters (see the header): `lin` = 1 for a source that holds linear light.
vec3 to_percept(vec3 c, float lin) {
    if (lin > 0.5) {
        c = clamp(c, vec3(0.0), vec3(16384.0));
        return sqrt(c / (1.0 + c));
    }
    return c;
}
vec3 from_percept(vec3 p, float lin) {
    if (lin > 0.5) {
        vec3 q = clamp(p, vec3(0.0), vec3(0.99995));
        vec3 t = q * q;
        return t / (1.0 - t);
    }
    return p;
}
float luma_of(vec3 p) {
    return dot(p, vec3(0.30, 0.55, 0.15));
}
@end

@fs fs_edge
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=0) uniform upscale_edge_params {
    vec4 src;       // xy = the size of the source in texels, z = 1 when it holds linear light, w = unused
};
in vec2 uv;
out vec4 frag_color;
@include_block spatial_common

vec4 fetch(ivec2 base, int dx, int dy, ivec2 hi) {
    return texelFetch(sampler2D(tex, smp), clamp(base + ivec2(dx, dy), ivec2(0), hi), 0);
}

// The kernel: Catmull-Rom of the (stretched) distance in texels, 0 from 2 on.
float kernel_of(float q) {
    float x = sqrt(q);
    if (x < 1.0) return ((1.5 * x - 2.5) * x) * x + 1.0;
    if (x < 2.0) return ((-0.5 * x + 2.5) * x - 4.0) * x + 2.0;
    return 0.0;
}

void main() {
    float lin = src.z;
    ivec2 hi = ivec2(src.xy) - ivec2(1);
    vec2 s = uv * src.xy - vec2(0.5);
    ivec2 b = ivec2(floor(s));
    vec2 f = s - vec2(b);

    // The 12 texels, named by their offset from the one at or left-above the sample: n = -1, 0 = the texel, 1, 2.
    vec4 r_0m1 = fetch(b, 0, -1, hi); vec4 r_1m1 = fetch(b, 1, -1, hi);
    vec4 r_m10 = fetch(b, -1, 0, hi); vec4 r_00 = fetch(b, 0, 0, hi); vec4 r_10 = fetch(b, 1, 0, hi); vec4 r_20 = fetch(b, 2, 0, hi);
    vec4 r_m11 = fetch(b, -1, 1, hi); vec4 r_01 = fetch(b, 0, 1, hi); vec4 r_11 = fetch(b, 1, 1, hi); vec4 r_21 = fetch(b, 2, 1, hi);
    vec4 r_02 = fetch(b, 0, 2, hi); vec4 r_12 = fetch(b, 1, 2, hi);

    vec3 p_0m1 = to_percept(r_0m1.rgb, lin); vec3 p_1m1 = to_percept(r_1m1.rgb, lin);
    vec3 p_m10 = to_percept(r_m10.rgb, lin); vec3 p_00 = to_percept(r_00.rgb, lin);
    vec3 p_10 = to_percept(r_10.rgb, lin); vec3 p_20 = to_percept(r_20.rgb, lin);
    vec3 p_m11 = to_percept(r_m11.rgb, lin); vec3 p_01 = to_percept(r_01.rgb, lin);
    vec3 p_11 = to_percept(r_11.rgb, lin); vec3 p_21 = to_percept(r_21.rgb, lin);
    vec3 p_02 = to_percept(r_02.rgb, lin); vec3 p_12 = to_percept(r_12.rgb, lin);

    float l_0m1 = luma_of(p_0m1), l_1m1 = luma_of(p_1m1);
    float l_m10 = luma_of(p_m10), l_00 = luma_of(p_00), l_10 = luma_of(p_10), l_20 = luma_of(p_20);
    float l_m11 = luma_of(p_m11), l_01 = luma_of(p_01), l_11 = luma_of(p_11), l_21 = luma_of(p_21);
    float l_02 = luma_of(p_02), l_12 = luma_of(p_12);

    // The gradient at the four texels around the sample (central differences: each one has its four neighbours among the 12), then
    // interpolated to the sample like the colour is.
    vec2 g00 = vec2(l_10 - l_m10, l_01 - l_0m1);
    vec2 g10 = vec2(l_20 - l_00, l_11 - l_1m1);
    vec2 g01 = vec2(l_11 - l_m11, l_02 - l_00);
    vec2 g11 = vec2(l_21 - l_01, l_12 - l_10);
    vec2 g = mix(mix(g00, g10, f.x), mix(g01, g11, f.x), f.y);
    float mag = length(g);
    vec2 across = mag > 1e-4 ? g / mag : vec2(1.0, 0.0);
    vec2 along = vec2(-across.y, across.x);
    float edge = smoothstep(0.04, 0.45, mag);
    float sAcross = 1.0 + 0.45 * edge;  // a larger factor = a narrower kernel
    float sAlong = 1.0 - 0.30 * edge;   // a smaller one = a longer kernel

    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    // One tap: the offset from the sample, the weight, the colour.
    #define FA_TAP(DX, DY, P) { vec2 d = vec2(float(DX), float(DY)) - f; float da = dot(d, along) * sAlong; float dc = dot(d, across) * sAcross; float w = kernel_of(da * da + dc * dc); acc += w * P; wsum += w; }
    FA_TAP(0, -1, p_0m1) FA_TAP(1, -1, p_1m1)
    FA_TAP(-1, 0, p_m10) FA_TAP(0, 0, p_00) FA_TAP(1, 0, p_10) FA_TAP(2, 0, p_20)
    FA_TAP(-1, 1, p_m11) FA_TAP(0, 1, p_01) FA_TAP(1, 1, p_11) FA_TAP(2, 1, p_21)
    FA_TAP(0, 2, p_02) FA_TAP(1, 2, p_12)

    vec3 lo = min(min(p_00, p_10), min(p_01, p_11));
    vec3 hi3 = max(max(p_00, p_10), max(p_01, p_11));
    vec3 bil = mix(mix(p_00, p_10, f.x), mix(p_01, p_11, f.x), f.y);
    vec3 outp = wsum > 1e-3 ? acc / wsum : bil;
    outp = clamp(outp, lo, hi3);
    float a = mix(mix(r_00.a, r_10.a, f.x), mix(r_01.a, r_11.a, f.x), f.y);
    frag_color = vec4(from_percept(outp, lin), a);
}
@end

@fs fs_sharpen
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=0) uniform upscale_sharpen_params {
    vec4 src;       // xy = the size of the source in texels, z = 1 when it holds linear light, w = the strongest negative weight of
                    // the sharpen (0 = none; sharpness 1 is 0.18)
};
in vec2 uv;
out vec4 frag_color;
@include_block spatial_common

void main() {
    float lin = src.z;
    ivec2 hi = ivec2(src.xy) - ivec2(1);
    ivec2 b = clamp(ivec2(floor(uv * src.xy)), ivec2(0), hi);
    vec4 rc = texelFetch(sampler2D(tex, smp), b, 0);
    vec3 c = to_percept(rc.rgb, lin);
    vec3 n = to_percept(texelFetch(sampler2D(tex, smp), clamp(b + ivec2(0, -1), ivec2(0), hi), 0).rgb, lin);
    vec3 s = to_percept(texelFetch(sampler2D(tex, smp), clamp(b + ivec2(0, 1), ivec2(0), hi), 0).rgb, lin);
    vec3 w = to_percept(texelFetch(sampler2D(tex, smp), clamp(b + ivec2(-1, 0), ivec2(0), hi), 0).rgb, lin);
    vec3 e = to_percept(texelFetch(sampler2D(tex, smp), clamp(b + ivec2(1, 0), ivec2(0), hi), 0).rgb, lin);
    vec3 lo = min(c, min(min(n, s), min(w, e)));
    vec3 up = max(c, max(max(n, s), max(w, e)));
    // The headroom above the brightest value of the neighbourhood: where the contrast is already near the top of the range there
    // is nothing left to gain, so the weight goes to 0 (no halo on a strong edge).
    float top = lin > 0.5 ? 0.70710678 : 1.0;
    vec3 amp = sqrt(clamp(min(lo, vec3(top) - up) / max(up, vec3(1e-4)), vec3(0.0), vec3(1.0)));
    vec3 wt = -amp * src.w;
    vec3 sharp = (c + wt * (n + s + w + e)) / (vec3(1.0) + 4.0 * wt);
    sharp = clamp(sharp, lo, up);
    frag_color = vec4(from_percept(sharp, lin), rc.a);
}
@end

@program spatial_edge vs fs_edge
@program spatial_sharpen vs fs_sharpen
