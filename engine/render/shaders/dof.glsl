// FactorIA depth of field (PostProcess.depthOfFieldEnabled, M71-D2): a circle of confusion (CoC) from the linear view depth of the
// prepass, a gather blur at half resolution and a full-resolution composite. Every program draws one full-screen triangle over ONE
// camera's rectangle of the picture; all the images except the picture itself have the size of that rectangle (the prepass, the
// scratch) or half of it, so uv runs 0..1 across the rectangle and a pixel reads the same pixel of every image.
//
//   down       picture + prepass -> 1/2 res: the 2x2 block averaged (bright pixels weigh less, so a lamp does not flicker), the
//              signed CoC in alpha (positive = behind the focus, negative = in front, in physical pixels of the full image)
//   gather     1/2 res -> 1/2 res: a disc of golden-angle taps (a deterministic rotation per texel). A tap reaches the texel when its
//              own blur disc does (scatter as gather); a far tap never blurs a sharper texel, a near one blurs whatever is behind it
//              (so a blurred foreground object has a soft edge over a sharp background). alpha = how much of the texel the near
//              field covers
//   composite  picture + prepass + gather -> the scratch (full res): the sharp picture mixed with the gather by the pixel's own far
//              CoC and the near coverage
//   copy       the scratch -> the camera's rectangle of the picture
//
// Coordinates: `uv` is the texture coordinate of an image of the pass's own size (the same orientation on every backend, as bloom.glsl).
// `s` is the same point in camera-local top-left uv; the picture is read at fl(s * rc.zw + rc.xy), where rc is the camera's rectangle.
@module dof

@vs vs
layout(binding=0) uniform dof_vs_params {
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

@block common
layout(binding=1) uniform dof_params {
    vec4 a;         // x = 1 when render targets are bottom-up (OpenGL), yz = the camera's rectangle in pixels, w = 0
    vec4 rc;        // the rectangle of the source picture the pass covers (top-left, fractions of the picture): xy corner, zw size; 0 0 1 1 for a scratch image
    vec4 c;         // x = focus distance, y = half of the sharp range (world units), z = largest near blur, w = largest far blur (physical pixels)
    vec4 r;         // x = length of the near ramp, y = of the far ramp (world units), z = 1 bokeh (bright points become discs) / 0 smooth, w = taps of the gather (4 .. 64)
    vec4 g;         // x = gather radius in pixels of the half-resolution image, yz = its size in pixels, w = 0
};

// top-left uv <-> the uv of a render target of this backend (the same function both ways)
vec2 fl(vec2 s) { return vec2(s.x, mix(s.y, 1.0 - s.y, a.x)); }
vec2 game_uv(vec2 s) { return fl(s * rc.zw + rc.xy); }
float luma(vec3 col) { return dot(col, vec3(0.2126, 0.7152, 0.0722)); }
// One channel made safe: NaN, Inf (found by their bits, as bloom.glsl does) and anything from 65000 up become 0.
float sane(float x) {
    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u || x >= 65000.0) return 0.0;
    return max(x, 0.0);
}
// Interleaved gradient noise of a pixel: a fixed pattern, so the same picture is drawn on every run.
float ign(vec2 p) { return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715)))); }
// The signed circle of confusion of a prepass texel: where nothing was drawn (the sky) the depth is infinite, so it is as blurred as
// the far limit.
float coc_at(vec4 pre) {
    float d = pre.a > 0.5 ? pre.r : 60000.0;
    float lo = c.x - c.y;
    float hi = c.x + c.y;
    if (d > hi) {
        float t = clamp((d - hi) / r.y, 0.0, 1.0);
        return c.w * t * t * (3.0 - 2.0 * t);
    }
    if (d < lo) {
        float t = clamp((lo - d) / r.x, 0.0, 1.0);
        return -c.z * t * t * (3.0 - 2.0 * t);
    }
    return 0.0;
}
@end

// ---- down: the picture at 1/2 resolution with the CoC in alpha --------------------------------------------
@fs fs_down
layout(binding=0) uniform texture2D tex_c;
layout(binding=1) uniform texture2D tex_p;
layout(binding=0) uniform sampler smp_lin;
layout(binding=1) uniform sampler smp_pt;
@image_sample_type tex_p unfilterable_float
@sampler_type smp_pt nonfiltering
@include_block common
in vec2 uv;
out vec4 frag_color;
void main() {
    vec2 size = a.yz;
    vec2 s = fl(uv);
    vec2 base = floor(s * g.yz) * 2.0;  // the top-left pixel of the 2x2 block this texel covers
    vec3 acc = vec3(0.0);
    float coc = 0.0;
    float wsum = 0.0;
    for (int j = 0; j < 2; j++) {
        for (int i = 0; i < 2; i++) {
            vec2 p = min(base + vec2(float(i), float(j)), size - 1.0) + 0.5;
            vec2 sp = p / size;
            vec3 col = textureLod(sampler2D(tex_c, smp_lin), game_uv(sp), 0.0).rgb;
            col = vec3(sane(col.r), sane(col.g), sane(col.b));
            float cc = coc_at(textureLod(sampler2D(tex_p, smp_pt), fl(sp), 0.0));
            float w = 1.0 / (1.0 + luma(col));
            acc += col * w;
            coc += cc * w;
            wsum += w;
        }
    }
    frag_color = vec4(acc / wsum, coc / wsum);
}
@end

// ---- gather: the blur --------------------------------------------------------------------------------------
@fs fs_gather
layout(binding=2) uniform texture2D tex_g;
layout(binding=0) uniform sampler smp_lin;
@include_block common
in vec2 uv;
out vec4 frag_color;

vec3 accF;      // the texel's own blur: what is at the focus or behind it
float wF;
vec3 accN;      // the near field: what is in front of the focus and reaches the texel
float wN;
float nearCov;  // how much of the texel the near field covers (a sum of areas over the number of taps)
float cenR;     // the far radius of the texel itself (half-res pixels): a far tap cannot blur beyond it

void tap(vec4 t, float rad) {
    float rs = abs(t.a) * 0.5;  // the radius of the tap's own blur disc, half-res pixels
    float boost = 1.0 + r.z * min(dot(t.rgb, vec3(0.2126, 0.7152, 0.0722)) * dot(t.rgb, vec3(0.2126, 0.7152, 0.0722)), 64.0) * 0.25;
    if (t.a < 0.0) {
        float cov = clamp(rs - rad + 1.0, 0.0, 1.0);
        // flat disc for bokeh, a soft one (centre-heavy) otherwise
        cov *= mix(1.0 - 0.8 * (rad * rad) / ((rs + 1.0) * (rs + 1.0)), 1.0, r.z);
        float w = cov * boost;
        accN += t.rgb * w;
        wN += w;
        nearCov += cov * (g.x * g.x) / max(rs * rs, 1.0);
    } else {
        float reach = min(rs, cenR);
        float cov = clamp(reach - rad + 1.0, 0.0, 1.0);
        cov *= mix(1.0 - 0.8 * (rad * rad) / ((reach + 1.0) * (reach + 1.0)), 1.0, r.z);
        float w = cov * boost;
        accF += t.rgb * w;
        wF += w;
    }
}

void main() {
    vec2 s = fl(uv);
    vec2 hs = g.yz;
    vec4 cen = textureLod(sampler2D(tex_g, smp_lin), uv, 0.0);
    cenR = max(cen.a, 0.0) * 0.5;
    accF = vec3(0.0);
    wF = 0.0;
    accN = vec3(0.0);
    wN = 0.0;
    nearCov = 0.0;
    tap(cen, 0.0);
    int n = int(r.w + 0.5);
    float rot = ign(floor(s * hs)) * 6.2831853;
    for (int i = 0; i < 64; i++) {
        if (i >= n) break;
        float rad = g.x * sqrt((float(i) + 0.5) / float(n));
        float th = float(i) * 2.39996323 + rot;
        vec2 off = vec2(cos(th), sin(th)) * rad;
        vec2 ts = clamp(s + off / hs, 0.5 / hs, 1.0 - 0.5 / hs);  // stays inside the camera's rectangle
        tap(textureLod(sampler2D(tex_g, smp_lin), fl(ts), 0.0), rad);
    }
    vec3 far_col = wF > 1e-4 ? accF / wF : cen.rgb;
    float an = clamp(nearCov / float(n), 0.0, 1.0);
    vec3 near_col = wN > 1e-4 ? accN / wN : far_col;
    frag_color = vec4(mix(far_col, near_col, an), an);
}
@end

// ---- composite: sharp picture + blur -----------------------------------------------------------------------
@fs fs_composite
layout(binding=0) uniform texture2D tex_c;
layout(binding=1) uniform texture2D tex_p;
layout(binding=2) uniform texture2D tex_g;
layout(binding=0) uniform sampler smp_lin;
layout(binding=1) uniform sampler smp_pt;
@include_block common
in vec2 uv;
out vec4 frag_color;
void main() {
    vec4 sharp = textureLod(sampler2D(tex_c, smp_lin), game_uv(fl(uv)), 0.0);
    float cc = coc_at(textureLod(sampler2D(tex_p, smp_pt), uv, 0.0));
    vec4 blur = textureLod(sampler2D(tex_g, smp_lin), uv, 0.0);
    float far_a = clamp(max(cc, 0.0) * 0.5, 0.0, 1.0);  // a blur under 2 pixels is mostly the sharp picture
    float k = max(far_a, blur.a);
    frag_color = vec4(mix(sharp.rgb, blur.rgb, k), sharp.a);
}
@end

// ---- copy: the scratch back into the camera's rectangle ---------------------------------------------------
@fs fs_copy
layout(binding=0) uniform texture2D tex_c;
layout(binding=0) uniform sampler smp_lin;
in vec2 uv;
out vec4 frag_color;
void main() {
    frag_color = textureLod(sampler2D(tex_c, smp_lin), uv, 0.0);
}
@end

@program down vs fs_down
@program gather vs fs_gather
@program composite vs fs_composite
@program copy vs fs_copy
