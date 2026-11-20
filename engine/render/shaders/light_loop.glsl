// The light loop of the mesh fragment shader and the glue to the custom-light hooks. Not compiled on its own: mesh_common.glsl
// @includes this file and includes its blocks where they are used.
//   fa_light_hooks       the shadowed light as the loop hands it to light(), and the lighting API of a "custom" material
//                        (fa_light_count(), fa_light(n, i), fa_light_unshadowed(), fa_light_shadow()); in fa_fs_light, after
//                        fa_light_data (light_data.glsl), fa_shadow_sun (shadow_common.glsl) and fa_light_shared.
//   fa_light_hooks_none  the same functions in the shadow and prepass fragment shaders, which have no lights (they only have to
//                        compile the snippet): fa_fs_nolight.
//   fa_light_loop        the standard loop, text included in the middle of main() of the main fragment shader (it uses main()'s
//                        locals: the surface s, the normal n, the view v, the geometric normal gn, lit and the BRDF terms). With
//                        FA_CUSTOM_LIGHT the snippet's light() takes the place of Cook-Torrance.
// M73.1 (clustered lights): the loop runs over this fragment's cluster, the directional lights and then the local lights whose
// sphere reaches the cluster, instead of every light of the frame; fa_light_count() and fa_light(n, i) are the same list. The
// contract the snippets see does not change (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md).

@block fa_light_hooks
// The cluster of the fragment (fa_cluster_begin, called at the start of main()): how many directional lights there are (they are
// lights 0 .. fa_cl_ndir - 1 of the table and belong to every cluster) and where the list of the local ones starts.
int fa_cl_ndir;
int fa_cl_slot;
int fa_cl_local;

void fa_cluster_begin(vec3 world_pos) {
    fa_cl_ndir = int(fa_cl_info.z);
    ivec2 c = fa_cluster_lookup(world_pos);
    fa_cl_slot = c.x;
    fa_cl_local = c.y;
}

// Light n (0 .. directional + local - 1) of this fragment's cluster as an index of the light table.
int fa_cl_light(int n) {
    if (n < fa_cl_ndir) { return n; }
    return fa_cluster_index(fa_cl_slot, n - fa_cl_ndir);
}

// The same with the shadow of the directional shadow map applied (only the first light, and only when it is directional, is
// shadowed): what the engine's light loop hands to light(). li is an index of the light table, gn the geometric normal.
LightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn) {
    LightSample ls = fa_light_sample(li, world_pos);
    if (ls.type == 0 && li == 0) {
        ls.shadow = fa_shadow_factor(gn, ls.direction);
        ls.color = ls.color * ls.shadow;
    }
    return ls;
}

#ifdef FA_CUSTOM_LIGHT
// The lighting API of a "custom" material (docs/shaders/SHADERS_LIGHTING.md): usable from light(), ambient() and lighting().
// How many lights reach this fragment: the directional lights and the local lights of its cluster (the engine hands over at most
// 1024 lights per frame, the most relevant ones, directional first).
int fa_light_count() { return fa_cl_ndir + fa_cl_local; }
// Light n (0 .. fa_light_count() - 1) with the shadow applied, as light() receives it. A number outside the range gives a sample
// that lights nothing (color and attenuation 0, shadow 1).
LightSample fa_light(int n, in SurfaceInput i) {
    if (n < 0 || n >= fa_light_count()) { return fa_no_light(); }
    return fa_light_shadowed(fa_cl_light(n), i.world_pos, i.world_normal);
}
// Light n without the shadow map read: color has no shadow in it and shadow is 1; the way to treat the shadow apart.
LightSample fa_light_unshadowed(int n, in SurfaceInput i) {
    if (n < 0 || n >= fa_light_count()) { return fa_no_light(); }
    return fa_light_sample(fa_cl_light(n), i.world_pos);
}
// The shadow of light n at this fragment: 1 lit, 0 in shadow (a value between at the edge of the shadow). Only the first light
// (n = 0) when it is directional has a shadow; every other light gives 1.
float fa_light_shadow(int n, in SurfaceInput i) {
    if (n != 0 || fa_light_count() < 1 || fa_cl_ndir < 1) { return 1.0; }
    return fa_shadow_factor(i.world_normal, normalize(fa_light_texel(0).xyz));
}
#endif
@end

@block fa_light_hooks_none
int fa_light_count() { return 0; }
LightSample fa_light(int n, in SurfaceInput i) { return fa_no_light(); }
LightSample fa_light_unshadowed(int n, in SurfaceInput i) { return fa_no_light(); }
float fa_light_shadow(int n, in SurfaceInput i) { return 1.0; }
@end

// The area lights (type 3 in the light table, shape in +6.w) of the engine's own standard lighting: the clipped polygon of the light
// integrated over the clamped cosine (the diffuse) and over the specular lobe (the LTC tables of the light atlas), with the point
// light's energy: far away the result is that of the point light of the same colour (ls.color without the LTC), near it grows with the
// angle the light covers up to the colour times 1 (the whole hemisphere). The light's colour is multiplied by s = (pi d^2 + A) / A,
// pi over the solid angle A / (d^2 + A / pi) the shape covers seen from its centre at distance d; the diffuse integral is a form
// factor (0..1, the cosine integral over pi) and the specular one carries the table's magnitude and Fresnel. A rectangle and a
// disc (an octagon of three convex quads of the same area) shine from their front only (the side `axis` points to); a tube
// (a rectangle that turns around its axis toward the shaded point) shines all around.
@block fa_area_light
#ifndef FA_CUSTOM_LIGHT
const float FA_OCT_C = 0.92387953;
const float FA_OCT_S = 0.38268343;

float fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey) {
    if (shape < 0.5 || shape > 1.5) { return fa_ltc_rect(m, pc, ex, ey); }
    // The disc: an octagon of the circumscribed radius 1.0539 r (the area of the disc), as the fan v0 v1 v2 v3, v0 v3 v4 v5, v0 v5 v6 v7.
    vec3 v0 = pc + ex * FA_OCT_C + ey * FA_OCT_S;
    vec3 v1 = pc + ex * FA_OCT_S + ey * FA_OCT_C;
    vec3 v2 = pc - ex * FA_OCT_S + ey * FA_OCT_C;
    vec3 v3 = pc - ex * FA_OCT_C + ey * FA_OCT_S;
    vec3 v4 = pc - ex * FA_OCT_C - ey * FA_OCT_S;
    vec3 v5 = pc - ex * FA_OCT_S - ey * FA_OCT_C;
    vec3 v6 = pc + ex * FA_OCT_S - ey * FA_OCT_C;
    vec3 v7 = pc + ex * FA_OCT_C - ey * FA_OCT_S;
    return abs(fa_ltc_quad(m, v0, v1, v2, v3) + fa_ltc_quad(m, v0, v3, v4, v5) + fa_ltc_quad(m, v0, v5, v6, v7));
}

// The light of the table li (an area light) shading the surface point: the radiance this light adds, attenuation (window) applied,
// without the shadow.
vec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window) {
    int base = fa_light_base(li);
    vec4 pos = fa_light_texel(base);
    vec3 col = fa_light_texel(base + 1).rgb;
    vec3 axis = normalize(fa_light_texel(base + 2).xyz);
    vec4 e4 = fa_light_texel(base + 4);
    vec4 e5 = fa_light_texel(base + 5);
    float shape = fa_light_texel(base + 6).w;
    vec3 rel = pos.xyz - world_pos;
    if (shape < 1.5 && dot(axis, rel) >= 0.0) { return vec3(0.0); }
    bool disc = shape > 0.5 && shape < 1.5;
    float grow = disc ? 1.0539 : 1.0;
    vec3 right = e4.xyz * (e4.w * grow);
    vec3 up = e5.xyz * (e5.w * grow);
    float area = disc ? FA_PI * e4.w * e4.w : 4.0 * e4.w * e5.w;
    if (shape > 1.5) {
        // A tube: the thickness runs across the axis and the line of sight.
        vec3 perp = cross(e4.xyz, -rel);
        float pl = dot(perp, perp);
        perp = pl > 1e-10 ? perp * inversesqrt(pl) : e5.xyz;
        up = perp * e5.w;
    }
    float scale = (FA_PI * dot(rel, rel) + max(area, 1e-6)) / max(area, 1e-6);
    vec3 t1 = fa_ltc_tangent(n, v);
    vec3 pc = fa_ltc_local(t1, n, rel);
    vec3 ex = fa_ltc_local(t1, n, right);
    vec3 ey = fa_ltc_local(t1, n, up);
    float diff = fa_area_form(vec4(1.0, 0.0, 0.0, 1.0), shape, pc, ex, ey);
    vec2 uv = fa_ltc_uv(roughness, ndv) * FA_LTC_SIZE;
    vec4 m = fa_atlas_fetch(uv);
    vec4 br = fa_atlas_fetch(uv + vec2(FA_LTC_SIZE, 0.0));
    float spec_form = fa_area_form(m, shape, pc, ex, ey);
    vec3 spec_color = f0 * br.x + (vec3(1.0) - f0) * br.y;
    return (diffuse_color * diff + spec_color * spec_form) * col * (scale * window);
}
#endif
@end

@block fa_light_loop
        int count = fa_cl_ndir + fa_cl_local;
        for (int ln = 0; ln < count; ln++) {
            int li = fa_cl_light(ln);
            LightSample ls = fa_light_shadowed(li, i.world_pos, gn);
#ifdef FA_CUSTOM_LIGHT
            // lighting "custom": the snippet's light() takes the place of the Cook-Torrance term below.
            lit += light(i, s, ls);
#else
            vec3 l = ls.direction;
            float ndl = max(dot(n, l), 0.0);
            float atten = ls.attenuation * ls.shadow;
            vec3 h = normalize(l + v);
            float ndh = max(dot(n, h), 0.0);
            float vdh = max(dot(v, h), 0.0);
            if (fa_light_is_area && !lay.on) {
                // An area light (M73.1b): the LTC polygon of the light, diffuse and specular, in place of the point-light terms.
                lit += fa_area_shade(li, i.world_pos, n, v, diffuse_color, f0, roughness, ndv, atten);
            } else if (lay.on) {
                // A material layer is set (clear coat, sheen, anisotropy, specular, ior): brdf_layers.glsl.
                lit += fa_layers_light(lay, diffuse_color, f0, n, v, l, h, ndl, ndv, ndh, vdh, alpha, a2) *
                       (fa_light_rgb(li) * fa_light_tint * atten);
            } else {
                // Cook-Torrance: GGX distribution, height-correlated Smith visibility (Karis' approximation), Schlick Fresnel.
                float dd = ndh * ndh * (a2 - 1.0) + 1.0;
                float d_ggx = a2 / (FA_PI * dd * dd);
                float vis = 0.5 / max(mix(2.0 * ndl * ndv, ndl + ndv, alpha), 1e-4);
                vec3 fres = f0 + (1.0 - f0) * pow(1.0 - vdh, 5.0);
                // Light colors are not divided by pi (a white light of intensity 1 lights a white diffuse surface to 1),
                // so the specular term carries the matching factor pi.
                vec3 spec = fres * (d_ggx * vis * FA_PI) * step(0.0001, ndl);
                lit += (diffuse_color + spec) * (fa_light_rgb(li) * fa_light_tint) * (ndl * atten);
            }
#endif
        }
@end
