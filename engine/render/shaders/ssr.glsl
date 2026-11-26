// FactorIA screen-space reflections (PostProcess.ssrEnabled, M71-D3a): every pixel of an opaque 3D mesh sends the mirror image of its view
// ray into the scene, follows it across the screen in the depth of the prepass and, where it passes behind a surface, takes the colour of
// the picture there. Two programs, both drawing one full-screen triangle over ONE camera's rectangle of the picture; the prepass and the
// scratch image have the size of that rectangle, so uv runs 0..1 across the rectangle and a pixel reads the same pixel of each (as dof.glsl).
//
//   trace   picture + prepass -> the scratch: the picture with the reflection mixed in (a pixel without a hit is the picture itself)
//   copy    the scratch -> the camera's rectangle of the picture
//
// The ray: from the pixel's view-space position, pushed off the surface by a small bias, along reflect(view ray, normal), for at most
// ssrMaxDistance world units, cut where it would pass the near plane and where it leaves the screen. It is walked in `steps` equal
// steps of SCREEN distance (a jitter of interleaved gradient noise moves the first one by a fixed pattern, so the same picture is drawn
// on every run); the depth of the ray is interpolated as 1/z, which is linear on the screen for a perspective camera. A step is a hit when
// the ray went behind the prepass surface and was in front of it, or less than ssrThickness behind it, one step before. Six bisections
// then find where it crossed between the two steps. The hit counts when the ray there is less than the thickness behind the surface.
//
// How much of the reflection is mixed in = ssrIntensity * fresnel * four fades (a reflected ray that goes back toward the camera, a hit
// on the back of a surface (its normal faces away from the ray), a hit near the border of the screen, a hit near the end of the ray), at
// most 0.75.
// The fresnel term is the only "material": there is no roughness or metalness image, so F = 0.2 + 0.8 (1 - N.V)^5, whatever the surface.
//
// With render.rayTracing.reflections (M79-P3a-1) the pass has a third image, the ray traced reflections of the camera (rt_reflect.hlsl, Rgba32F, the size of
// the prepass; b.w = 1 when it is bound). A pixel the kernel traced (its alpha is not 0) takes no screen-space ray: where the ray hit a surface
// (alpha > 0) the mix is the same fresnel term (no intensity, at most SSR_MAX_MIX) of the hit's colour; where it left the scene (alpha < 0) the
// picture is left as it is, it already holds the environment's reflection. The other pixels (the sky, a surface rougher than the kernel's cutoff)
// follow the rules above, with ssrIntensity 0 (the stack has no reflections) they are left alone.
//
// Coordinates: `uv` is the texture coordinate of an image of the pass's own size (the same orientation on every backend, as bloom.glsl).
// `s` is the same point in camera-local top-left uv; the picture is read at fl(s * rc.zw + rc.xy), where rc is the camera's rectangle.
// View space: the camera looks down -z; the prepass depth is -z. The projection terms come from the camera's matrix (as motion_blur.glsl).
@module ssr

@vs vs
layout(binding=0) uniform ssr_vs_params {
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

// ---- trace: the picture with the reflection ----------------------------------------------------------------
@fs fs_trace
layout(binding=0) uniform texture2D tex_c;
layout(binding=1) uniform texture2D tex_p;
layout(binding=2) uniform texture2D tex_r;
layout(binding=0) uniform sampler smp_lin;
layout(binding=1) uniform sampler smp_pt;
@image_sample_type tex_p unfilterable_float
@image_sample_type tex_r unfilterable_float
@sampler_type smp_pt nonfiltering
layout(binding=1) uniform ssr_params {
    vec4 a;         // x = 1 when render targets are bottom-up (OpenGL), yz = the camera's rectangle in pixels, w = steps (8 .. 128)
    vec4 rc;        // the rectangle of the source picture the pass covers (top-left, fractions of the picture): xy corner, zw size
    vec4 b;         // x = intensity (0 .. 1), y = longest ray in world units, z = thickness in world units, w = 1 when tex_r is the ray traced image
    vec4 pa;        // the projection of the camera: P00, P11, P02, P12 (what the view-space position of a pixel needs)
    vec4 pb;        // P03, P13, P32, P33
};
in vec2 uv;
out vec4 frag_color;

vec2 fl(vec2 s) { return vec2(s.x, mix(s.y, 1.0 - s.y, a.x)); }
vec2 game_uv(vec2 s) { return fl(s * rc.zw + rc.xy); }
float ign(vec2 p) { return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715)))); }
// One channel made safe: NaN, Inf (found by their bits, as bloom.glsl does) become 0, a negative becomes 0 and a finite value is kept up to 65504 (as post.glsl).
float sane(float x) {
    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u) return 0.0;
    return clamp(x, 0.0, 65504.0);
}
vec4 pre_at(vec2 s) { return textureLod(sampler2D(tex_p, smp_pt), fl(s), 0.0); }

// The thickness at a surface of view depth `d`: the thickness field, at least what the prepass can tell apart at that distance (a
// float16 prepass, the fallback of a GPU without a float32 one, steps by about 0.001 * d: 0.06 at 100 units, 0.25 at 500).
// The most of a pixel that can be the reflection (ssrIntensity 1 reaches it). There is no roughness image, so a matte surface must never
// become a mirror: that would show as patches wherever the ray finds a hit and its neighbour finds none.
const float SSR_MAX_MIX = 0.75;
float thickness_at(float d) { return max(b.z, 0.002 * d); }

// The view-space position of the point at camera-local top-left uv `s` whose view depth (-z) is `d`.
vec3 view_pos(vec2 s, float d) {
    vec2 ndc = vec2(s.x * 2.0 - 1.0, 1.0 - s.y * 2.0);
    float z = -d;
    float w = pb.z * z + pb.w;  // clip w: -z for a perspective camera, 1 for an orthographic one
    return vec3((ndc.x * w - pa.z * z - pb.x) / pa.x, (ndc.y * w - pa.w * z - pb.y) / pa.y, z);
}
// The camera-local top-left uv of a view-space position in front of the camera.
vec2 project(vec3 v) {
    float w = pb.z * v.z + pb.w;
    vec2 c = vec2(pa.x * v.x + pa.z * v.z + pb.x, pa.y * v.y + pa.w * v.z + pb.y) / w;
    return vec2(c.x * 0.5 + 0.5, 0.5 - c.y * 0.5);
}
// The view-space normal of a prepass texel (octahedral, see mesh_common.glsl prepass_fs).
vec3 decode_normal(vec2 e) {
    vec3 n = vec3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) { n.xy = (1.0 - abs(n.yx)) * vec2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0); }
    return normalize(n);
}
// The view depth of the ray at the fraction q of its screen path (depth dA at q = 0, dB at q = 1): 1/depth is what is linear on the
// screen for a perspective camera, the depth itself for an orthographic one.
float ray_depth(float q, float dA, float dB, bool persp) {
    return persp ? 1.0 / mix(1.0 / dA, 1.0 / dB, q) : mix(dA, dB, q);
}

void main() {
    vec2 size = a.yz;
    vec2 s = fl(uv);
    vec4 here = textureLod(sampler2D(tex_c, smp_lin), game_uv(s), 0.0);
    frag_color = here;
    vec4 pre = pre_at(s);
    if (pre.a < 0.5 || (b.x <= 0.0 && b.w < 0.5)) return;  // the sky, a sprite: nothing to reflect off

    float d0 = pre.r;
    vec3 P = view_pos(s, d0);
    vec3 N = decode_normal(pre.gb);
    bool persp = abs(pb.z) > 0.5;
    vec3 V = persp ? normalize(P) : vec3(0.0, 0.0, -1.0);  // from the camera into the scene
    vec3 R = reflect(V, N);
    float fres = 0.2 + 0.8 * pow(1.0 - clamp(dot(N, -V), 0.0, 1.0), 5.0);
    if (b.w > 0.5) {
        vec4 rt = textureLod(sampler2D(tex_r, smp_pt), fl(s), 0.0);
        if (rt.a != 0.0) {  // the kernel traced this pixel: no screen-space ray
            if (rt.a > 0.0) {
                vec3 rc3 = vec3(sane(rt.r), sane(rt.g), sane(rt.b));
                frag_color = vec4(mix(here.rgb, rc3, min(fres, SSR_MAX_MIX)), here.a);
            }
            return;
        }
    }
    if (b.x <= 0.0) return;
    float toward = smoothstep(-0.1, 0.15, dot(R, V));      // a ray back to the camera finds nothing the screen shows
    float k0 = b.x * fres * toward;
    if (k0 < 0.002) return;

    // The ray, off the surface by a small bias, cut at the near plane.
    vec3 A = P + N * max(0.01, 0.002 * d0);
    float T = b.y;
    if (persp && R.z > 0.0) { T = min(T, (-A.z - 0.05) / R.z); }
    if (T < 0.01) return;
    vec3 B = A + R * T;
    float dA = -A.z;
    float dB = -B.z;
    vec2 pA = project(A) * size;
    vec2 dp = project(B) * size - pA;
    // The part of the path that is on the screen.
    float qmax = 1.0;
    if (dp.x > 1e-4) { qmax = min(qmax, (size.x - pA.x) / dp.x); } else if (dp.x < -1e-4) { qmax = min(qmax, -pA.x / dp.x); }
    if (dp.y > 1e-4) { qmax = min(qmax, (size.y - pA.y) / dp.y); } else if (dp.y < -1e-4) { qmax = min(qmax, -pA.y / dp.y); }
    qmax = clamp(qmax, 0.0, 1.0);
    float len = length(dp) * qmax;
    if (len < 1.0) return;
    int n = int(min(a.w, ceil(len)));

    // Walk the path.
    float jit = 0.2 + 0.8 * ign(floor(s * size));
    float qPrev = 0.0;
    float dPrev = dA;
    float qHit = -1.0;
    float qLo = 0.0;
    for (int i = 0; i < 128; i++) {
        if (i >= n) break;
        float q = (float(i) + jit) / float(n) * qmax;
        float rd = ray_depth(q, dA, dB, persp);
        vec4 sp = pre_at((pA + dp * q) / size);
        if (sp.a > 0.5 && rd >= sp.r && dPrev <= sp.r + thickness_at(sp.r)) {
            qHit = q;
            qLo = qPrev;
            break;
        }
        qPrev = q;
        dPrev = rd;
    }
    if (qHit < 0.0) return;

    // Where between the two steps the ray went behind the surface.
    float lo = qLo;
    float hi = qHit;
    for (int j = 0; j < 6; j++) {
        float m = 0.5 * (lo + hi);
        vec4 sp = pre_at((pA + dp * m) / size);
        if (sp.a > 0.5 && ray_depth(m, dA, dB, persp) >= sp.r) { hi = m; } else { lo = m; }
    }
    vec2 sh = (pA + dp * hi) / size;
    vec4 hp = pre_at(sh);
    float rdh = ray_depth(hi, dA, dB, persp);
    if (hp.a < 0.5 || rdh - hp.r > thickness_at(hp.r)) return;  // the ray is behind the surface by more than its thickness: it went behind an edge

    float backFace = smoothstep(0.0, 0.25, -dot(decode_normal(hp.gb), R));
    float reach = 1.0 - smoothstep(0.7, 1.0, length(view_pos(sh, rdh) - A) / b.y);
    vec2 edge = min(sh, 1.0 - sh);
    float onScreen = smoothstep(0.0, 0.1, min(edge.x, edge.y));
    // No roughness image yet, so no pixel is a pure mirror: the mix is capped, which also keeps a hit next to a miss from showing as a hard patch.
    float k = clamp(k0 * backFace * reach * onScreen, 0.0, SSR_MAX_MIX);
    vec3 hc = textureLod(sampler2D(tex_c, smp_lin), game_uv(sh), 0.0).rgb;
    hc = vec3(sane(hc.r), sane(hc.g), sane(hc.b));
    frag_color = vec4(mix(here.rgb, hc, k), here.a);
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

@program trace vs fs_trace
@program copy vs fs_copy
