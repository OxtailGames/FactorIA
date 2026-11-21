// FactorIA screen-space subsurface scattering (MeshRenderer.subsurface, M73.5): the diffuse light of the meshes that scatter, blurred in two separable passes
// with a profile of four Gaussians (subsurface.h: the table, the cell edges and the CPU twin of the weights below), and added to the picture.
// docs/design/ARCHITECTURE_SUBSURFACE.md.
//
//   images  A = rgb: the DIFFUSE light of the surface (mesh_common.glsl, fs_sss), a: its linear view depth (0 = no scattering here);
//           B = rgb: the scatter radius of each colour channel in metres, a: the strength (MeshRenderer.subsurface).
//   blur_h  A + B -> H: the same image blurred along x, a = the depth.
//   blur_v  H + A + B -> V: the change the scattering makes, strength * (blurred along y - A.rgb), rgb signed (the picture already holds the unblurred
//           diffuse light, the main pass drew it). Specular, emission and reflections are not in A: they stay sharp.
//   add     V -> the picture of the camera's rectangle: the positive part added, the negative part subtracted (two draws of one pass).
//
// A tap counts for a pixel only where it holds scattering light of a surface at about the same depth, so the light never crosses a silhouette and never
// reaches another object; the weights of the taps that count are renormalised, per colour channel (each has its own radius). The taps are the cells of
// kSssCell: the weight of a tap is the mass of the profile inside its cell (the Gaussians' cumulative function, an erf), so a radius smaller than the
// taps (a few pixels) loses nothing: the taps that land on the same pixel add up.
@module subsurface

@vs vs
layout(binding=0) uniform sss_vs_params {
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

@block sss_common
layout(binding=1) uniform sss_params {
    vec4 a;         // x = pixels per metre at depth 1 (perspective) or per world unit (orthographic), y = 1 when orthographic, zw = the image's size in pixels
    vec4 b;         // x = the widest radius the pass blurs, in pixels
    vec4 g[4];      // the four Gaussians: x = weight, y = sigma, in units of the radius that holds 90% of the light
    vec4 cell[2];   // the eight edges of the tap cells, in the same units: cell[k >> 2][k & 3]
};
in vec2 uv;
out vec4 frag_color;

const int SSS_TAPS = 7;     // taps on each side of the centre one

// Edge k (0..7) of the tap cells: the components of a vec4 are picked without a dynamic index (not every target can flatten one).
float sss_cell(int k) {
    vec4 v = cell[k >> 2];
    int c = k & 3;
    return c == 0 ? v.x : (c == 1 ? v.y : (c == 2 ? v.z : v.w));
}
// The error function (Abramowitz and Stegun 7.1.26, error below 1.5e-7).
// Four at a time (one per Gaussian), so no array is needed.
vec4 sss_erf4(vec4 x) {
    vec4 s = vec4(x.x < 0.0 ? -1.0 : 1.0, x.y < 0.0 ? -1.0 : 1.0, x.z < 0.0 ? -1.0 : 1.0, x.w < 0.0 ? -1.0 : 1.0);
    x = abs(x);
    vec4 t = vec4(1.0) / (vec4(1.0) + 0.3275911 * x);
    vec4 y = vec4(1.0) - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * exp(-x * x);
    return s * y;
}
// The weight of the centre tap (the cell [-edge 0, edge 0], both sides) and of each tap k = 1..7 (ONE side of the centre) of a colour channel whose radius is
// `ratio` times the widest one: the mass of the four Gaussians in the cell, edges divided by the ratio (the profile is narrower for a smaller radius).
void sss_weights(float ratio, out float w[8]) {
    vec4 weight = vec4(g[0].x, g[1].x, g[2].x, g[3].x);
    vec4 inv_sigma = vec4(1.0) / (vec4(g[0].y, g[1].y, g[2].y, g[3].y) * 1.41421356);
    vec4 prev = vec4(0.0);
    for (int k = 0; k < 8; k++) {
        float edge = sss_cell(k) / ratio;
        vec4 e = sss_erf4(vec4(edge) * inv_sigma);
        float m = dot(weight, e - prev);
        prev = e;
        w[k] = k == 0 ? m : 0.5 * m;
    }
}
// The offset of tap k (1..7) from the centre, in pixels: the middle of its cell, in the units of the widest radius.
float sss_offset(int k, float radius_px) {
    return 0.5 * (sss_cell(k - 1) + sss_cell(k)) * radius_px;
}
// One direction of the blur. `src` = rgb the light, a the depth (0 = nothing); `dir` = (1, 0) or (0, 1). The result is the blurred light of the centre
// pixel `p` (rgb) and 1 in a when the pixel scatters.
vec3 sss_blur(texture2D src, sampler smp, ivec2 p, vec2 dir, vec4 center, vec3 radius_m) {
    float depth = center.a;
    float px_per_m = a.y > 0.5 ? a.x : a.x / depth;
    float widest = max(radius_m.r, max(radius_m.g, radius_m.b));
    float radius_px = min(widest * px_per_m, b.x);
    if (radius_px < 0.3) { return center.rgb; }
    vec3 ratio = clamp(radius_m / max(widest, 1e-6), 0.02, 1.0);
    float wr[8];
    float wg[8];
    float wb[8];
    sss_weights(ratio.r, wr);
    sss_weights(ratio.g, wg);
    sss_weights(ratio.b, wb);
    vec3 acc = center.rgb * vec3(wr[0], wg[0], wb[0]);
    vec3 sum = vec3(wr[0], wg[0], wb[0]);
    ivec2 size = ivec2(a.zw);
    ivec2 step_dir = ivec2(dir);
    for (int k = 1; k <= SSS_TAPS; k++) {
        float off = sss_offset(k, radius_px);
        int o = int(floor(off + 0.5));
        // A tap on the same surface is no further in depth than the slope of a steep one allows over its distance (about 63 degrees).
        float tol = 0.01 + 2.0 * (off / px_per_m);
        vec3 w = vec3(wr[k], wg[k], wb[k]);
        for (int s = 0; s < 2; s++) {
            ivec2 q = p + step_dir * (s == 0 ? o : -o);
            if (q.x < 0 || q.y < 0 || q.x >= size.x || q.y >= size.y) { continue; }
            vec4 t = texelFetch(sampler2D(src, smp), q, 0);
            if (t.a <= 0.0 || abs(t.a - depth) > tol) { continue; }
            acc += t.rgb * w;
            sum += w;
        }
    }
    return acc / sum;
}
@end

@fs fs_blur_h
layout(binding=0) uniform texture2D tex_a;      // the diffuse light and its depth
layout(binding=1) uniform texture2D tex_b;      // the radius and the strength
layout(binding=0) uniform sampler smp_pt;
@image_sample_type tex_a unfilterable_float
@image_sample_type tex_b unfilterable_float
@sampler_type smp_pt nonfiltering
@include_block sss_common

void main() {
    ivec2 size = ivec2(a.zw);
    ivec2 p = clamp(ivec2(uv * a.zw), ivec2(0), size - 1);
    vec4 c = texelFetch(sampler2D(tex_a, smp_pt), p, 0);
    vec4 r = texelFetch(sampler2D(tex_b, smp_pt), p, 0);
    if (c.a <= 0.0 || r.a <= 0.0) { frag_color = vec4(0.0); return; }
    frag_color = vec4(sss_blur(tex_a, smp_pt, p, vec2(1.0, 0.0), c, r.rgb), c.a);
}
@end

@fs fs_blur_v
layout(binding=0) uniform texture2D tex_aa;     // the diffuse light and its depth
layout(binding=1) uniform texture2D tex_ab;     // the radius and the strength
layout(binding=2) uniform texture2D tex_ah;     // the light blurred along x
layout(binding=0) uniform sampler smp_ap;
@image_sample_type tex_aa unfilterable_float
@image_sample_type tex_ab unfilterable_float
@image_sample_type tex_ah unfilterable_float
@sampler_type smp_ap nonfiltering
@include_block sss_common

void main() {
    ivec2 size = ivec2(a.zw);
    ivec2 p = clamp(ivec2(uv * a.zw), ivec2(0), size - 1);
    vec4 d0 = texelFetch(sampler2D(tex_aa, smp_ap), p, 0);
    vec4 r = texelFetch(sampler2D(tex_ab, smp_ap), p, 0);
    vec4 h = texelFetch(sampler2D(tex_ah, smp_ap), p, 0);
    if (d0.a <= 0.0 || r.a <= 0.0 || h.a <= 0.0) { frag_color = vec4(0.0); return; }
    vec3 blurred = sss_blur(tex_ah, smp_ap, p, vec2(0.0, 1.0), h, r.rgb);
    frag_color = vec4(r.a * (blurred - d0.rgb), 0.0);
}
@end

// The change the blur makes, as two draws of the same pass: its positive part added to the picture, its negative part subtracted (a blend cannot take a
// negative source in a picture that is 8 bits or R11G11B10, and the result of each is clamped to what the picture can hold).
@fs fs_add
layout(binding=0) uniform texture2D tex_dv;     // the change: rgb = light to add (positive) or take away (negative)
layout(binding=0) uniform sampler smp_dv;
@image_sample_type tex_dv unfilterable_float
@sampler_type smp_dv nonfiltering
layout(binding=1) uniform sss_add_params {
    vec4 m;         // x = 0: draw the positive part, 1: draw the negative part; zw = the image's size in pixels
};
in vec2 uv;
out vec4 frag_color;

void main() {
    ivec2 p = clamp(ivec2(uv * m.zw), ivec2(0), ivec2(m.zw) - 1);
    vec3 d = texelFetch(sampler2D(tex_dv, smp_dv), p, 0).rgb;
    frag_color = vec4(m.x < 0.5 ? max(d, vec3(0.0)) : max(-d, vec3(0.0)), 0.0);
}
@end

@program blur_h vs fs_blur_h
@program blur_v vs fs_blur_v
@program add vs fs_add
