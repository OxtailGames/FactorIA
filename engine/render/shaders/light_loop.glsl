// The light loop of the mesh fragment shader and the glue to the custom-light hooks. Not compiled on its own: mesh_common.glsl
// @includes this file and includes its blocks where they are used.
//   fa_contact           the screen-space contact shadow of a light (M73.2c), included before fa_light_hooks.
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

// ---- Contact shadows (M73.2c; docs/design/ARCHITECTURE_SCREEN_EFFECTS.md) ----
// A short ray march in screen space from the fragment toward the light: the shadow map cannot show the dark line where a small object
// touches the surface under it, a depth ray of a few steps can. Each step projects a point of the ray to the screen (the rows
// fa_ct_vpx / vpy / vpw of the view-projection matrix, no inverse matrix) and compares its depth along the camera's forward axis with the
// prepass's at that pixel (view 28: r = linear view depth, a = 1 on an opaque mesh). A point that is behind the surface by more than the
// bias and less than the thickness is occluded. Per light: Light.contactShadowLength (metres, 0 = none), the y of the light's texel of
// the shadow region of the light data texture (light_data.glsl), whatever the light's index and the stride of the light table. A draw
// that takes none (fa_ct_a.x = 0: a blended mesh, a mesh that does not receive shadows, a frame with no prepass) skips all of it at
// the first branch.
@block fa_contact
const int FA_CONTACT_STEPS = 12;
// 1 = the light reaches the fragment, 0 = a contact shadow. `l` the unit direction to the light, `dist` the distance to it (any large
// number for a directional light), `gn` the geometric normal.
float fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist) {
    if (fa_ct_a.x < 0.5 || fa_shadow_lcfg.x < 0.5) { return 1.0; }
    float len = fa_light_texel(int(fa_shadow_lcfg.x + 0.5) - 1 + li).y;
    if (len <= 0.0) { return 1.0; }
    float cam_d = length(world - fa_camera_pos.xyz);
    float far_fade = 1.0 - smoothstep(0.5 * fa_ct_b.x, fa_ct_b.x, cam_d);
    if (far_fade <= 0.0) { return 1.0; }
    len = min(len, 0.9 * dist);  // never march past a point light
    // A few millimetres plus what a pixel of the prepass covers at this distance (a depth within that is the surface itself).
    float bias = 0.005 + 0.003 * cam_d;
    float thick = bias + 0.5 * len;
    vec3 origin = world + gn * bias;
    float jitter = fa_shadow_noise();  // interleaved gradient noise of the pixel: the same in every frame, so a still picture never shimmers
    float occ = 0.0;
    for (int k = 0; k < FA_CONTACT_STEPS; k++) {
        float f = (float(k) + jitter) / float(FA_CONTACT_STEPS);  // 0 .. 1 along the ray
        vec3 p = origin + l * (f * len);
        vec4 pv = vec4(p, 1.0);
        float w = dot(fa_ct_vpw, pv);
        if (w < 1e-4) { break; }  // behind the camera
        vec2 ndc = vec2(dot(fa_ct_vpx, pv), dot(fa_ct_vpy, pv)) / w;
        vec2 uv = vec2(ndc.x * 0.5 + 0.5, fa_ct_a.y > 0.5 ? ndc.y * 0.5 + 0.5 : 0.5 - ndc.y * 0.5);
        if (uv.x < 0.0 || uv.x >= 1.0 || uv.y < 0.0 || uv.y >= 1.0) { break; }  // off screen: nothing is known there
        ivec2 px = ivec2(uv * fa_ct_a.zw);
        vec4 scene = texelFetch(sampler2D(fa_screen_tex, fa_shadow_smp), px, 0);
        if (scene.a < 0.5) { continue; }  // no mesh at this pixel (the sky)
        float delta = (dot(fa_ct_fwd.xyz, p) + fa_ct_fwd.w) - scene.r;  // > 0: the point is behind the visible surface
        if (delta > bias && delta < thick) {
            // The shadow fades toward the end of the ray and toward the edge of the screen (the surface that hides it may be off screen).
            float edge = smoothstep(0.0, 0.05, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
            occ = max(occ, (1.0 - f * f) * edge);
        }
    }
    return 1.0 - occ * far_fade;
}
@end

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

// The same with the shadow applied: the first light when it is directional has the sun's cascaded shadow map, a point or spot light
// that has a shadow map this frame (Light.castShadows, within the budget) its own one: what the engine's light loop hands to light().
// li is an index of the light table, gn the geometric normal.
LightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn) {
    if (fa_lm.z > 0.5 && fa_light_baked(li)) {  // its direct light is in the lightmap this fragment reads: no light, no shadow lookup
        LightSample none;
        none.direction = vec3(0.0, 1.0, 0.0);
        none.color = vec3(0.0);
        none.attenuation = 0.0;
        none.shadow = 1.0;
        none.distance = 0.0;
        none.type = int(fa_light_type(li) + 0.5);
        return none;
    }
    LightSample ls = fa_light_sample(li, world_pos);
    if (ls.type == 0 && li == 0) {
        ls.shadow = fa_shadow_factor(gn, ls.direction);
        ls.color = ls.color * ls.shadow;
    } else if (ls.type != 0 && ls.attenuation > 0.0) {
        ls.shadow = fa_shadow_local(li, world_pos, gn, ls.direction);
        ls.color = ls.color * ls.shadow;
    }
    if (fa_ct_a.x > 0.5 && ls.attenuation > 0.0) {  // the contact shadow multiplies into the light's own shadow term
        float c = fa_contact_shadow(li, world_pos, gn, ls.direction, ls.type == 0 ? 1.0e9 : ls.distance);
        ls.shadow *= c;
        ls.color = ls.color * c;
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
    int li = fa_cl_light(n);
    if (fa_lm.z > 0.5 && fa_light_baked(li)) { return fa_no_light(); }  // a baked light on a lightmapped fragment
    return fa_light_sample(li, i.world_pos);
}
// The shadow of light n at this fragment: 1 lit, 0 in shadow (a value between at the edge of the shadow). The first light (n = 0) when
// it is directional has the sun's shadow, a point or spot light with a shadow map this frame its own; every other light gives 1. Every
// light with a contact shadow (Light.contactShadowLength) multiplies it in, whether it has a shadow map or not.
float fa_light_shadow(int n, in SurfaceInput i) {
    if (n < 0 || n >= fa_light_count()) { return 1.0; }
    int li = fa_cl_light(n);
    vec3 l;
    float dist = 1.0e9;
    float sh = 1.0;
    if (n == 0 && fa_cl_ndir >= 1) {
        l = normalize(fa_light_texel(0).xyz);
        sh = fa_shadow_factor(i.world_normal, l);
    } else if (li < fa_cl_ndir) {
        l = normalize(fa_light_texel(li * 4).xyz);
    } else {
        vec3 d = fa_light_texel(li * 4).xyz - i.world_pos;
        dist = length(d);
        l = d / max(dist, 1e-4);
        sh = fa_shadow_local(li, i.world_pos, i.world_normal, l);
    }
    if (fa_ct_a.x > 0.5) { sh *= fa_contact_shadow(li, i.world_pos, i.world_normal, l, dist); }
    return sh;
}
#endif
@end

@block fa_light_hooks_none
int fa_light_count() { return 0; }
LightSample fa_light(int n, in SurfaceInput i) { return fa_no_light(); }
LightSample fa_light_unshadowed(int n, in SurfaceInput i) { return fa_no_light(); }
float fa_light_shadow(int n, in SurfaceInput i) { return 1.0; }
@end

@block fa_light_loop
        int count = fa_cl_ndir + fa_cl_local;
        for (int ln = 0; ln < count; ln++) {
            int li = fa_cl_light(ln);
            if (fa_lm.z > 0.5 && fa_light_baked(li)) { continue; }  // Light.mode Baked on a lightmapped fragment (before any shadow lookup)
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
            if (lay.on) {
                // A material layer is set (clear coat, sheen, anisotropy, specular, ior): brdf_layers.glsl.
                lit += fa_layers_light(lay, diffuse_color, f0, n, v, l, h, ndl, ndv, ndh, vdh, alpha, a2) *
                       (fa_light_rgb(li) * atten);
            } else {
                // Cook-Torrance: GGX distribution, height-correlated Smith visibility (Karis' approximation), Schlick Fresnel.
                float dd = ndh * ndh * (a2 - 1.0) + 1.0;
                float d_ggx = a2 / (FA_PI * dd * dd);
                float vis = 0.5 / max(mix(2.0 * ndl * ndv, ndl + ndv, alpha), 1e-4);
                vec3 fres = f0 + (1.0 - f0) * pow(1.0 - vdh, 5.0);
                // Light colors are not divided by pi (a white light of intensity 1 lights a white diffuse surface to 1),
                // so the specular term carries the matching factor pi.
                vec3 spec = fres * (d_ggx * vis * FA_PI) * step(0.0001, ndl);
                lit += (diffuse_color + spec) * fa_light_rgb(li) * (ndl * atten);
            }
#endif
        }
@end
