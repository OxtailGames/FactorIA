// The light data of the mesh fragment shaders: where the lights are read from, and the read of one light as a LightSample. The ONE
// declaration both the mesh template (mesh_common.glsl, the engine's own meshes and the custom materials of mode "snippet") and the
// full-shader template (mesh_full_common.glsl) include with `@include_block fa_light_data`, after the block fa_types (LightSample is
// declared there) and after the fragment head, which declares the light data texture and defines FA_LIGHT_TEX and FA_LIGHT_SMP.
// Nothing here is compiled on its own.
//
// M73.1, clustered forward lighting (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md): the lights of the frame and the list of lights of
// every cluster of the view are packed by the renderer (src/light_clusters.cpp) into ONE data texture of 1024 RGBA32F texels per row,
// read with texelFetch (view 24, sampler 1). Texel t is at (t & 1023, t >> 10). The layout, in texels:
//   [0, 4 * L)                       light n at 4n .. 4n + 3:
//                                      +0 xyz position (point/spot) or direction TO the light (directional), w range
//                                      +1 rgb colour * intensity, w type (0 directional, 1 point, 2 spot)
//                                      +2 xyz spot axis (the direction the light points), w cos(spot half angle)
//                                      +3 x cos of the inner cone of a spot (2 = the default fade), yzw reserved (cookie, IES)
//   [fa_cl_info.x, + fa_cl_info.w)   one texel per cluster (slice-major, then row, then column): x = slot of its first light index,
//                                    y = how many local lights it has
//   after the clusters               the light indices, four to a texel (x, y, z, w); slot s is component s & 3 of the s >> 2 th
//                                    texel of this region
//   after the light indices          the shadow region of the point and spot lights (M73.2b), only in a frame where one has a shadow
//                                    map; its first texel is fa_shadow_lcfg.x - 1 (the fa_shadows block, shadow_common.glsl):
//                                      [base, base + L)  light n: x = the texel of its record, or -1 (no shadow map this frame)
//                                      then the records: 2 header texels (+0 kind 1 = one tile / 2 = six cube faces, fade distance,
//                                      filter, softness k; +1 depth bias, normal bias) and 6 texels per tile: the four rows of the
//                                      matrix world -> (u * w, v * w, -, w) of the atlas texture (w = metres along the tile's axis), the
//                                      tile's rectangle (umin, vmin, umax, vmax), and (metres per texel at distance 1, near plane,
//                                      far plane). Written by local_shadows.cpp, read by fa_shadow_local.
// The directional lights come first in the light table (at most 32) and belong to every cluster; the local lights of a cluster are
// in ascending index order, so a loop over "directional, then the cluster's list" adds the lights up in the order of the table.
@block fa_light_data
vec4 fa_light_texel(int t) {
    return texelFetch(sampler2D(FA_LIGHT_TEX, FA_LIGHT_SMP), ivec2(t & 1023, t >> 10), 0);
}

// The colour times intensity of light li of the table (no attenuation).
vec3 fa_light_rgb(int li) { return fa_light_texel(li * 4 + 1).rgb; }
// The type of light li: 0 directional, 1 point, 2 spot.
float fa_light_type(int li) { return fa_light_texel(li * 4 + 1).w; }

// Light li of the table as seen from a world position, without its shadow: the direction to it, its color times intensity times
// attenuation, the attenuation, the distance and the type. shadow is 1.
LightSample fa_light_sample(int li, vec3 world_pos) {
    vec4 pos = fa_light_texel(li * 4);
    vec4 col = fa_light_texel(li * 4 + 1);
    float type = col.w;
    vec3 l;
    float atten = 1.0;
    float dist = 0.0;
    if (type < 0.5) {
        l = normalize(pos.xyz);
    } else {
        vec3 to_light = pos.xyz - world_pos;
        dist = length(to_light);
        l = to_light / max(dist, 1e-4);
        float range = max(pos.w, 1e-3);
        float x = clamp(1.0 - (dist / range) * (dist / range), 0.0, 1.0);
        atten = x * x;
        if (type > 1.5) {
            vec4 dir = fa_light_texel(li * 4 + 2);
            float cos_angle = dot(-l, normalize(dir.xyz));
            float cos_outer = dir.w;
            float cos_inner = fa_light_texel(li * 4 + 3).x;
            if (cos_inner > 1.5) { cos_inner = mix(cos_outer, 1.0, 0.25); }
            atten *= smoothstep(cos_outer, cos_inner, cos_angle);
        }
    }
    LightSample ls;
    ls.direction = l;
    ls.color = col.rgb * atten;
    ls.attenuation = atten;
    ls.shadow = 1.0;
    ls.distance = dist;
    ls.type = type < 0.5 ? 0 : (type > 1.5 ? 2 : 1);
    return ls;
}

// The cluster of a world position, as (slot of its first local light, how many local lights): the tile of the view it projects to
// (by the rows of the view-projection matrix the CPU used, so the answer does not depend on the backend's window conventions) and the
// depth slice of its distance along the camera's forward axis. (0, 0) when the frame has no local lights.
ivec2 fa_cluster_lookup(vec3 world_pos) {
    // No clusters (info.x < 0), an empty grid, or a position that is not in front of the camera (no NaN path): no local lights.
    if (fa_cl_info.x < 0.0 || fa_cl_info.w < 1.0 || fa_cl_grid.x < 1.0 || fa_cl_grid.y < 1.0 || fa_cl_info.y < 1.0) {
        return ivec2(0, 0);
    }
    vec4 p = vec4(world_pos, 1.0);
    float w = dot(fa_cl_vpw, p);
    if (!(w > 1e-6)) { return ivec2(0, 0); }
    vec2 ndc = vec2(dot(fa_cl_vpx, p), dot(fa_cl_vpy, p)) / w;
    int tiles_x = int(fa_cl_grid.x);
    int tiles_y = int(fa_cl_grid.y);
    int tx = clamp(int(floor((ndc.x * 0.5 + 0.5) * fa_cl_grid.x)), 0, tiles_x - 1);
    int ty = clamp(int(floor((ndc.y * 0.5 + 0.5) * fa_cl_grid.y)), 0, tiles_y - 1);
    float depth = dot(fa_cl_fwd.xyz, world_pos) + fa_cl_fwd.w;
    int sl = clamp(int(floor(log2(max(depth, fa_cl_grid.w) / fa_cl_grid.w) * fa_cl_grid.z)), 0, int(fa_cl_info.y) - 1);
    vec4 e = fa_light_texel(int(fa_cl_info.x) + (sl * tiles_y + ty) * tiles_x + tx);
    return ivec2(int(e.x), int(e.y));
}

// The table index of local light n of the cluster whose first slot is `slot`.
int fa_cluster_index(int slot, int n) {
    vec4 t = fa_light_texel(int(fa_cl_info.x) + int(fa_cl_info.w) + ((slot + n) >> 2));
    return int(t[(slot + n) & 3]);
}
@end
