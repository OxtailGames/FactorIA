// FactorIA volumetric fog and light shafts (SceneSettings.volumetricFog, Light.volumetric; M73.5): a raymarch of the medium between the camera and
// the surface of each pixel, at a fraction of the picture's resolution, and a depth-aware upsample that joins it to the picture.
// docs/design/ARCHITECTURE_VOLUMETRIC.md.
//
//   march   prepass (+ shadow atlas, light data texture) -> RGBA16F at 1/2 or 1/4 of the camera's rectangle: rgb = the light the medium scatters
//           toward the camera along the pixel's ray, a = the fraction of the picture behind it that gets through (transmittance). The ray
//           ends at the surface (the prepass) or at the medium's distance, whichever is nearer; a pixel with no mesh (the sky) marches to
//           the distance.
//             - ambient light and the directional lights: `steps` jittered samples along the ray, the sun's shadow read from the cascaded
//               atlas (hard, one tap: the jitter and the upsample soften it);
//             - every point and spot light: `samples` jittered samples inside the part of the ray that is within the light's range, its
//               attenuation, its cone and its shadow tile (one tap) read at each.
//           The density is  sigma(y) = density * exp(-falloff * max(y - base, 0))  and the transmittance along the ray comes from its
//           closed-form integral, so the number of samples sets the noise, never the amount of fog.
//   apply   the march image + the prepass -> the camera's rectangle of the picture, blended  picture * a + rgb  (alpha factors ZERO / ONE).
//           Each full-resolution pixel takes its four nearest march pixels, weighted by how near their depth is to its own (the prepass is read
//           at the same texel the march read), so a fog edge does not bleed over a silhouette.
//
// Nothing here is random and nothing reads the clock: the jitter is a function of the pixel (interleaved gradient noise), so the same picture
// comes out on every run and every frame. `uv` is the texture coordinate of the image being drawn; `s` is the same point in the camera-local
// top-left uv (the one the projection terms work in).
@module volumetric

// The helpers the shadow include needs. shadow_common.glsl's fa_shadow_local (not called here: vol_shadow_local below is the march's own one-tap copy)
// reads the light data texture through fa_light_texel, defined further down. When the light loop of the area lights, cookies and IES profiles
// lands, that fa_shadow_local also calls fa_light_base(int) and fa_cube_face(vec3), which its light_data.glsl defines; this shader does not
// include light_data.glsl, so whoever integrates second must define both here too (before this include's functions are used) or the module
// stops compiling. vol_shadow_local itself never assumes the stride of a light's records in the texture: it takes the light's position from the
// caller (`lp`, from the uniform array) and only the index of its shadow region (lcfg + li).
@include shadow_common.glsl

@vs vs
layout(binding=0) uniform vol_vs_params {
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

@fs fs_march
layout(binding=0) uniform texture2D tex_p;      // the prepass
layout(binding=1) uniform texture2D fa_shadow_tex;
layout(binding=2) uniform texture2D fa_light_tex;
layout(binding=0) uniform sampler smp_pt;
@image_sample_type tex_p unfilterable_float
@image_sample_type fa_shadow_tex unfilterable_float
@image_sample_type fa_light_tex unfilterable_float
@sampler_type smp_pt nonfiltering
#define FA_SHADOW_TEX fa_shadow_tex
#define FA_SHADOW_SMP smp_pt
#define FA_LIGHT_TEX fa_light_tex
#define FA_LIGHT_SMP smp_pt

layout(binding=1) uniform vol_params {
    vec4 a;         // x = 1 when render targets are bottom-up (OpenGL), y = steps along the ray, z = how many point and spot lights, w = samples per light
    vec4 b;         // xy = the size of the march image in pixels, z = how many directional lights, w = how far the medium reaches (metres)
    vec4 pa;        // the projection of the camera: P00, P11, P02, P12
    vec4 pb;        // P03, P13, P32, P33
    vec4 eye;       // xyz = the camera's position
    vec4 right;     // the camera's axes in the world
    vec4 up;
    vec4 fwd;
    vec4 m;         // x = density at and below the base (per metre), y = height base (world y), z = height falloff (per metre), w = anisotropy g
    vec4 albedo;    // rgb = the colour of the medium (SceneSettings.fogColor in the scene's colour space)
    vec4 amb;       // rgb = SceneSettings.ambientLight * volumetricAmbient (before the albedo)
};
layout(binding=2) uniform vol_lights {
    vec4 dirs[8];   // directional light k: [2k] xyz = the direction TO the light, w = 1 when the sun's shadow applies (cascaded atlas); [2k+1] rgb = colour * intensity * strength
    vec4 loc[64];   // point or spot light k: [4k] xyz = position, w = range; [4k+1] rgb = colour * intensity * strength, w = cos of the inner cone;
                    // [4k+2] xyz = the spot axis, w = cos of the outer cone (-2 for a point light); [4k+3] x = index in the light table, y = 1 when it has a shadow
};
in vec2 uv;
out vec4 frag_color;

// The light data texture is read the same way the mesh shaders read it (light_data.glsl): texel t is at (t & 1023, t >> 10). A small copy: this
// file does not include the mesh template.
vec4 fa_light_texel(int t) {
    return texelFetch(sampler2D(FA_LIGHT_TEX, FA_LIGHT_SMP), ivec2(t & 1023, t >> 10), 0);
}
// The shadow functions of shadow_common.glsl read this: every position here receives shadows.
const vec4 fa_pbr = vec4(0.0, 0.0, 1.0, 0.0);
@include_block fa_shadow_common

vec2 fl(vec2 s) { return vec2(s.x, mix(s.y, 1.0 - s.y, a.x)); }
float sane(float x) {
    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u) { return 0.0; }
    return clamp(x, 0.0, 60000.0);
}
float ign(vec2 p) { return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715)))); }

// The Henyey-Greenstein phase function times 4 pi: 1 for g = 0 (the same in every direction), so the light colours keep their meaning.
// `c` is the cosine of the angle between the direction to the light and the direction the camera looks along the ray.
float vol_phase(float c) {
    float g = m.w;
    float d = 1.0 + g * g - 2.0 * g * c;
    return (1.0 - g * g) / (d * sqrt(d));
}

// The density at height y, and the integral of it from the base up to y (0 at the base, negative below it, the density being constant there).
float dens_at(float y) {
    float u = y - m.y;
    if (u <= 0.0 || m.z < 1e-5) return m.x;
    return m.x * exp(-min(m.z * u, 80.0));
}
float dens_int(float y) {
    float u = y - m.y;
    if (u <= 0.0 || m.z < 1e-5) return m.x * u;
    return m.x * (1.0 - exp(-min(m.z * u, 80.0))) / m.z;
}
// The optical depth from the camera to the point t metres along the ray (whose height changes by ry per metre): the closed form of the
// integral of the density. A nearly level stretch (or one where the density hardly changes) uses the density at its middle, where the
// difference of integrals loses its digits.
float tau_at(float t, float ry) {
    if (m.z < 1e-5) return m.x * t;                  // the same density at every height
    float dy = ry * t;
    if (abs(dy) < 1e-3 || abs(dy) * m.z < 2e-3) return dens_at(eye.y + 0.5 * dy) * t;
    return (dens_int(eye.y + dy) - dens_int(eye.y)) / ry;
}

// The part of a point or spot light that reaches p: its attenuation in range and its cone (the formulas of fa_light_sample in
// light_data.glsl), x = 0 outside. `l` is the unit direction from p to the light.
float local_atten(int k, vec3 p, out vec3 l) {
    vec4 pr = loc[4 * k];
    vec3 to = pr.xyz - p;
    float d = length(to);
    l = to / max(d, 1e-4);
    float x = clamp(1.0 - (d / max(pr.w, 1e-3)) * (d / max(pr.w, 1e-3)), 0.0, 1.0);
    float att = x * x;
    vec4 ax = loc[4 * k + 2];
    if (ax.w > -1.5) {
        float cosOuter = ax.w;
        float cosInner = loc[4 * k + 1].w;
        att *= smoothstep(cosOuter, cosInner, dot(-l, ax.xyz));
    }
    return att;
}

// The light of a point or spot light that its shadow lets through at p (1 lit): the record of fa_shadow_local (shadow_common.glsl) read with
// one tap, whatever filter the light has: a fog sample does not need the soft edge and takes a few of them per pixel. `l` points to the light.
float vol_shadow_local(int li, vec3 lp, vec3 world, vec3 l) {
    if (fa_shadow_lcfg.x < 0.5) { return 1.0; }
    float at = fa_light_texel(int(fa_shadow_lcfg.x + 0.5) - 1 + li).x;
    if (at < 0.0) { return 1.0; }
    int rec = int(at + 0.5);
    vec4 h0 = fa_light_texel(rec);
    vec4 h1 = fa_light_texel(rec + 1);
    float fade = 1.0;
    if (h0.y > 0.0) {
        fade = 1.0 - smoothstep(0.75 * h0.y, h0.y, length(world - fa_shadow_eye.xyz));
        if (fade <= 0.0) { return 1.0; }
    }
    int face = 0;
    if (h0.x > 1.5) {  // a cube: the face of the major axis of the direction from the light
        vec3 d = world - lp;
        vec3 ad = abs(d);
        face = (ad.x >= ad.y && ad.x >= ad.z) ? (d.x > 0.0 ? 0 : 1) : (ad.y >= ad.z ? (d.y > 0.0 ? 2 : 3) : (d.z > 0.0 ? 4 : 5));
    }
    int t = rec + 2 + face * 6;
    vec4 r0 = fa_light_texel(t);
    vec4 r1 = fa_light_texel(t + 1);
    vec4 r3 = fa_light_texel(t + 3);
    vec4 rect = fa_light_texel(t + 4);
    vec4 tinfo = fa_light_texel(t + 5);  // x = metres per texel at distance 1, y = near plane, z = far plane
    vec4 wp = vec4(world, 1.0);
    float pw = dot(r3, wp);  // the distance along the tile's axis, in metres
    if (pw < tinfo.y) { return 1.0; }
    float texel_m = tinfo.x * max(pw, 1e-3);
    vec2 suv = vec2(dot(r0, wp), dot(r1, wp)) / pw;
    if (suv.x < rect.x || suv.x > rect.z || suv.y < rect.y || suv.y > rect.w) { return 1.0; }
    float bias_m = (h1.x > 0.0 ? h1.x : 1.5 * texel_m) * 1.5;
    float s = fa_shadow_filter(suv, rect, pw - bias_m, texel_m, 1.0, 0.0, 0.0, vec3(1.0, tinfo.y, tinfo.z), 1, 0.0);
    return mix(1.0, s, fade);
}

void main() {
    vec2 s = fl(uv);
    vec4 pre = textureLod(sampler2D(tex_p, smp_pt), uv, 0.0);
    bool sky = pre.a < 0.5;
    float dep = sky ? 1.0 : pre.r;
    vec2 ndc = vec2(s.x * 2.0 - 1.0, 1.0 - s.y * 2.0);
    float z = -dep;
    float w = pb.z * z + pb.w;                       // clip w: -z for a perspective camera
    vec3 vp = vec3((ndc.x * w - pa.z * z - pb.x) / pa.x, (ndc.y * w - pa.w * z - pb.y) / pa.y, z);
    vec3 off = right.xyz * vp.x + up.xyz * vp.y + fwd.xyz * dep;
    float dl = max(length(off), 1e-4);
    vec3 r = off / dl;                               // the unit ray from the camera through the pixel
    float reach = b.w;
    float len = sky ? reach : min(dl, reach);
    int steps = int(a.y + 0.5);
    int nd = int(b.z + 0.5);
    int nl = int(a.z + 0.5);
    int ns = int(a.w + 0.5);
    float j = ign(floor(s * b.xy));
    vec3 acc = vec3(0.0);

    // Ambient light and the directional lights: `steps` samples along the whole ray, each the part of the medium it stands for.
    float dt = len / float(max(steps, 1));
    for (int i = 0; i < 64; i++) {
        if (i >= steps) { break; }
        float t = (float(i) + j) * dt;
        vec3 p = eye.xyz + r * t;
        float sg = dens_at(p.y);
        float absorb = 1.0 - exp(-sg * dt);          // how much of the sample's stretch the medium takes
        if (absorb < 1e-5) { continue; }
        vec3 lit = amb.rgb;
        for (int k = 0; k < 4; k++) {
            if (k >= nd) { break; }
            vec4 d0 = dirs[2 * k];
            vec3 l = d0.xyz;
            float sh = d0.w > 0.5 ? fa_shadow_sun(p, l, l) : 1.0;
            lit += dirs[2 * k + 1].rgb * (vol_phase(dot(l, r)) * sh);
        }
        acc += lit * (absorb * exp(-tau_at(t, r.y)));
    }

    // The point and spot lights: samples inside the stretch of the ray that is within the light's range (a sphere), so a short range costs
    // as many samples as a long one and its shaft is as sharp.
    for (int k = 0; k < 16; k++) {
        if (k >= nl) { break; }
        vec4 pr = loc[4 * k];
        vec3 oc = pr.xyz - eye.xyz;
        float tb = dot(oc, r);
        float disc = tb * tb - (dot(oc, oc) - pr.w * pr.w);
        if (disc <= 0.0) { continue; }
        float sq = sqrt(disc);
        float t0 = max(tb - sq, 0.0);
        float t1 = min(tb + sq, len);
        if (t1 <= t0) { continue; }
        float dtl = (t1 - t0) / float(max(ns, 1));
        float jl = fract(j + float(k) * 0.61803399);
        vec4 meta = loc[4 * k + 3];
        vec3 col = loc[4 * k + 1].rgb;
        vec3 sum = vec3(0.0);
        for (int q = 0; q < 24; q++) {
            if (q >= ns) { break; }
            float t = t0 + (float(q) + jl) * dtl;
            vec3 p = eye.xyz + r * t;
            vec3 l;
            float att = local_atten(k, p, l);
            if (att <= 0.0) { continue; }
            float sh = meta.y > 0.5 ? vol_shadow_local(int(meta.x + 0.5), loc[4 * k].xyz, p, l) : 1.0;
            float sg = dens_at(p.y);
            sum += col * (att * sh * vol_phase(dot(l, r)) * min(sg * dtl, 1.0) * exp(-tau_at(t, r.y)));
        }
        acc += sum;
    }

    float trans = exp(-tau_at(len, r.y));
    vec3 rgb = acc * albedo.rgb;
    // NaN and Inf (by their bits) become 0 and the rest is kept inside what a half float holds: one bad sample never spreads through the upsample.
    frag_color = vec4(sane(rgb.x), sane(rgb.y), sane(rgb.z), clamp(trans, 0.0, 1.0));
}
@end

@fs fs_apply
layout(binding=0) uniform texture2D tex_av;      // the march image
layout(binding=1) uniform texture2D tex_ap;      // the prepass
layout(binding=0) uniform sampler smp_ap;
@image_sample_type tex_av unfilterable_float
@image_sample_type tex_ap unfilterable_float
@sampler_type smp_ap nonfiltering
layout(binding=1) uniform apply_params {
    vec4 a;         // xy = the size of the march image in pixels
};
in vec2 uv;
out vec4 frag_color;

// The depth the upsample compares: the prepass's linear depth, or a far value for a pixel with no mesh.
float eff_depth(vec2 q) {
    vec4 pre = textureLod(sampler2D(tex_ap, smp_ap), q, 0.0);
    return pre.a < 0.5 ? 1.0e4 : min(pre.r, 1.0e4);
}

void main() {
    vec2 size = a.xy;
    float dp = eff_depth(uv);
    vec2 p = uv * size - 0.5;
    vec2 i0 = floor(p);
    vec2 f = p - i0;
    vec4 sum = vec4(0.0);
    float wsum = 0.0;
    for (int k = 0; k < 4; k++) {
        vec2 d = vec2(float(k & 1), float(k >> 1));
        vec2 ix = clamp(i0 + d, vec2(0.0), size - 1.0);
        vec2 q = (ix + 0.5) / size;                  // the centre of that march pixel: where the march read the prepass
        float bil = (d.x > 0.5 ? f.x : 1.0 - f.x) * (d.y > 0.5 ? f.y : 1.0 - f.y);
        float dq = eff_depth(q);
        float rel = abs(dq - dp) / max(min(dq, dp), 0.1);
        float wt = bil / (0.02 + rel) + 1e-5;
        sum += textureLod(sampler2D(tex_av, smp_ap), q, 0.0) * wt;
        wsum += wt;
    }
    vec4 v = sum / wsum;
    frag_color = vec4(v.rgb, v.a);                   // rgb added, a = what the blend multiplies the picture by (its alpha is not written)
}
@end

@program march vs fs_march
@program apply vs fs_apply
