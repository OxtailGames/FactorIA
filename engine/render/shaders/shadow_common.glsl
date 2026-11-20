// The shadow sampling of the mesh fragment shaders: the lookup in the directional shadow map, shared by the engine's own light loop
// (mesh_common.glsl: fa_shadow_factor) and by the full-shader template (mesh_full_common.glsl: fa_shadow). Included with
// `@include_block fa_shadow_common` after the fragment head has declared the shadow map and its sampler (the macros FA_SHADOW_TEX and FA_SHADOW_SMP name them: the
// engine's meshes and the full-shader template use different names), fa_pbr and fa_counts. Not
// compiled on its own.
//
// Today: one 2D depth map, a 3x3 PCF with a slope-scaled bias. M73.2 (cascades, the shadow atlas, PCSS) replaces the body of
// fa_shadow_pcf and adds lookups next to it (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md).
@block fa_shadow_common
// The fraction of light that reaches a surface (1 = lit) from the directional shadow map: `coord` is the position in light clip space
// (fa_shadow_pos, or fa_shadow_coord() of the vertex stage of a full shader), n the geometric normal, l the direction to the light.
// 1 when the MeshRenderer does not receive shadows.
float fa_shadow_pcf(vec4 coord, vec3 n, vec3 l) {
    if (fa_pbr.z < 0.5) { return 1.0; }
    vec3 p = coord.xyz / coord.w;
    vec2 suv = p.xy * 0.5 + 0.5;
    bool is_gl = fa_counts.z > 0.5;
    if (is_gl) { p.z = p.z * 0.5 + 0.5; } else { suv.y = 1.0 - suv.y; }
    if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0 || p.z > 1.0) { return 1.0; }
    float bias = fa_pbr.w * (1.0 + 2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0)));
    float lit = 0.0;
    float texel = fa_counts.y;
    for (int ix = -1; ix <= 1; ix++) {
        for (int iy = -1; iy <= 1; iy++) {
            float depth = textureLod(sampler2D(FA_SHADOW_TEX, FA_SHADOW_SMP), suv + vec2(float(ix), float(iy)) * texel, 0.0).r;  // explicit LOD: no gradients inside loops (HLSL X3570)
            lit += (p.z - bias <= depth) ? 1.0 : 0.0;
        }
    }
    return lit / 9.0;
}
@end
