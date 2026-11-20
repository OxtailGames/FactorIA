// The light loop of the mesh fragment shader and the glue to the custom-light hooks. Not compiled on its own: mesh_common.glsl
// @includes this file and includes its blocks where they are used.
//   fa_light_hooks       the shadowed light as the loop hands it to light(), and the lighting API of a "custom" material
//                        (fa_light_count(), fa_light(n, i), fa_light_unshadowed(), fa_light_shadow()); in fa_fs_light, after
//                        fa_light_data (light_data.glsl), fa_shadow_pcf (shadow_common.glsl) and fa_light_shared.
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
            // Cook-Torrance: GGX distribution, height-correlated Smith visibility (Karis' approximation), Schlick Fresnel.
            float dd = ndh * ndh * (a2 - 1.0) + 1.0;
            float d_ggx = a2 / (FA_PI * dd * dd);
            float vis = 0.5 / max(mix(2.0 * ndl * ndv, ndl + ndv, alpha), 1e-4);
            vec3 fres = f0 + (1.0 - f0) * pow(1.0 - vdh, 5.0);
            // Light colors are not divided by pi (a white light of intensity 1 lights a white diffuse surface to 1),
            // so the specular term carries the matching factor pi.
            vec3 spec = fres * (d_ggx * vis * FA_PI) * step(0.0001, ndl);
            lit += (diffuse_color + spec) * fa_light_rgb(li) * (ndl * atten);
#endif
        }
@end
