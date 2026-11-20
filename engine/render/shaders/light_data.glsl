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
//                                    y = how many local lights it has, z = slot of its first decal index, w = how many decals it has
//   after the clusters               the light indices, four to a texel (x, y, z, w); slot s is component s & 3 of the s >> 2 th
//                                    texel of this region
//   from fa_counts.y (0 = none)      the decals of the view (M73.5b, block fa_decals below): two header texels, 7 texels per decal, the
//                                    decal indices four to a texel
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

// The cluster of a world position: (slot of its first local light, how many local lights, slot of its first decal, how many decals): the
// tile of the view it projects to (by the rows of the view-projection matrix the CPU used, so the answer does not depend on the backend's
// window conventions) and the depth slice of its distance along the camera's forward axis. All zero when the frame has no clusters.
vec4 fa_cluster_texel(vec3 world_pos) {
    // No clusters (info.x < 0), an empty grid, or a position that is not in front of the camera (no NaN path): no lights, no decals.
    if (fa_cl_info.x < 0.0 || fa_cl_info.w < 1.0 || fa_cl_grid.x < 1.0 || fa_cl_grid.y < 1.0 || fa_cl_info.y < 1.0) {
        return vec4(0.0);
    }
    vec4 p = vec4(world_pos, 1.0);
    float w = dot(fa_cl_vpw, p);
    if (!(w > 1e-6)) { return vec4(0.0); }
    vec2 ndc = vec2(dot(fa_cl_vpx, p), dot(fa_cl_vpy, p)) / w;
    int tiles_x = int(fa_cl_grid.x);
    int tiles_y = int(fa_cl_grid.y);
    int tx = clamp(int(floor((ndc.x * 0.5 + 0.5) * fa_cl_grid.x)), 0, tiles_x - 1);
    int ty = clamp(int(floor((ndc.y * 0.5 + 0.5) * fa_cl_grid.y)), 0, tiles_y - 1);
    float depth = dot(fa_cl_fwd.xyz, world_pos) + fa_cl_fwd.w;
    int sl = clamp(int(floor(log2(max(depth, fa_cl_grid.w) / fa_cl_grid.w) * fa_cl_grid.z)), 0, int(fa_cl_info.y) - 1);
    return fa_light_texel(int(fa_cl_info.x) + (sl * tiles_y + ty) * tiles_x + tx);
}

// The same as (slot of its first local light, how many local lights); (0, 0) when the frame has no local lights.
ivec2 fa_cluster_lookup(vec3 world_pos) {
    vec4 e = fa_cluster_texel(world_pos);
    return ivec2(int(e.x), int(e.y));
}

// The table index of local light n of the cluster whose first slot is `slot`.
int fa_cluster_index(int slot, int n) {
    vec4 t = fa_light_texel(int(fa_cl_info.x) + int(fa_cl_info.w) + ((slot + n) >> 2));
    return int(t[(slot + n) & 3]);
}
@end

// ---- Projected decals (M73.5b; docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Decals") ----
// The decal region of the data texture starts at texel fa_counts.y (0 = the view has no decals):
//   +0  (decal count, atlas width, atlas height, first texel of the decal indices)
//   +1  x = colour mode: 0 the atlas holds raw bytes of a gamma scene, 1 raw bytes in a linear scene (the albedo is sRGB-coded: decode
//       it), 2 the atlas is SRGB8A8 (the GPU decoded every tile as sRGB: the normal tiles are encoded back)
//   +2 + 7d .. +8 + 7d   decal d: rows 0..2 of the world -> box matrix (xyz, translation w; the box is the cube -0.5 .. 0.5), the
//       albedo tile (u0, v0, u1, v1 in the atlas; all 0 = none), the normal tile, the tint (rgba, in the scene's colour space), and
//       (opacity, normal strength, 1 / cos(angle fade), the layer mask)
// fa_counts.w is the receiver: 0 = this mesh takes no decals, else 1 + its MeshRenderer.decalLayer. The decals of a cluster are in the
// order they are drawn (Decal.sortOrder), each blends over what the ones before it left.
@block fa_decals
vec3 fa_dc_to_linear(vec3 c) {
    c = max(c, vec3(0.0));
    return mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045)));
}
vec3 fa_dc_to_srgb(vec3 c) {
    c = max(c, vec3(0.0));
    return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, c * 12.92, step(c, vec3(0.0031308)));
}

// A tile of the decal atlas at the tile-local uv (0..1), at the mip level the surface's footprint asks for. `ddx` and `ddy` are the
// derivatives of the box position (x, y; the image's v runs the other way, which does not change the length).
vec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy) {
    vec2 size = rect.zw - rect.xy;
    vec2 px = size * atlas;
    vec2 gx = ddx * px;
    vec2 gy = ddy * px;
    float lod = clamp(0.5 * log2(max(max(dot(gx, gx), dot(gy, gy)), 1e-8)), 0.0, 4.0);
    return textureLod(sampler2D(FA_DECAL_TEX, FA_DECAL_SMP), rect.xy + clamp(uv, 0.0, 1.0) * size, lod);
}

// Paints the decals of the fragment's cluster over the surface: `world_pos` the position, `geo_normal` the geometric normal (the way the
// face looks, for the angle fade), `albedo` and `normal` (the shading normal, in the world) are changed. Call it once, in uniform control flow
// (it takes derivatives), before the lights. Nothing happens while the view has no decals or the mesh does not receive them.
void fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal) {
    vec3 dpx = dFdx(world_pos);
    vec3 dpy = dFdy(world_pos);
    if (fa_counts.y < 0.5 || fa_counts.w < 0.5) { return; }
    vec4 cl = fa_cluster_texel(world_pos);
    int dcount = int(cl.w);
    if (dcount < 1) { return; }
    int base = int(fa_counts.y + 0.5);
    vec4 head = fa_light_texel(base);
    vec2 atlas = head.yz;
    int idx_base = int(head.w);
    float mode = fa_light_texel(base + 1).x;
    int bit = int(fa_counts.w + 0.5) - 1;
    int first = int(cl.z);
    for (int k = 0; k < dcount; ++k) {
        int slot = first + k;
        int di = int(fa_light_texel(idx_base + (slot >> 2))[slot & 3]);
        int t = base + 2 + di * 7;
        vec4 prm = fa_light_texel(t + 6);
        if (((int(prm.w + 0.5) >> bit) & 1) == 0) { continue; }
        vec4 r0 = fa_light_texel(t);
        vec4 r1 = fa_light_texel(t + 1);
        vec4 r2 = fa_light_texel(t + 2);
        vec3 b = vec3(dot(r0.xyz, world_pos) + r0.w, dot(r1.xyz, world_pos) + r1.w, dot(r2.xyz, world_pos) + r2.w);
        if (abs(b.x) > 0.5 || abs(b.y) > 0.5 || abs(b.z) > 0.5) { continue; }
        vec3 axis = normalize(r2.xyz);
        float facing = clamp(dot(geo_normal, axis) * prm.z, 0.0, 1.0);
        if (facing <= 0.0) { continue; }
        // Fades over the last tenth of the box along the projection; the sides of the box cut sharply (a decal ends at the picture's edge).
        float edge = clamp((0.5 - abs(b.z)) * 10.0, 0.0, 1.0);
        float cover = edge * facing * prm.x;
        vec2 uv = vec2(b.x + 0.5, 0.5 - b.y);
        vec2 ddx = vec2(dot(r0.xyz, dpx), dot(r1.xyz, dpx));
        vec2 ddy = vec2(dot(r0.xyz, dpy), dot(r1.xyz, dpy));
        vec4 tint = fa_light_texel(t + 5);
        vec4 ar = fa_light_texel(t + 3);
        vec4 nr = fa_light_texel(t + 4);
        float tex_a = 1.0;
        vec3 col = tint.rgb;
        bool has_albedo = ar.z > ar.x;
        if (has_albedo) {
            vec4 tx = fa_decal_tile(ar, uv, atlas, ddx, ddy);
            if (mode > 0.5 && mode < 1.5) { tx.rgb = fa_dc_to_linear(tx.rgb); }
            col *= tx.rgb;
            tex_a = tx.a;
        }
        float a = cover * tex_a * tint.a;
        albedo = mix(albedo, col, clamp(a, 0.0, 1.0));
        if (nr.z > nr.x) {
            vec4 nt = fa_decal_tile(nr, uv, atlas, ddx, ddy);
            vec3 enc = mode > 1.5 ? fa_dc_to_srgb(nt.rgb) : nt.rgb;
            vec3 m = enc * 2.0 - 1.0;
            m.xy *= prm.y;
            vec3 tx_axis = normalize(r0.xyz);
            vec3 ty_axis = normalize(r1.xyz);
            vec3 d = tx_axis * m.x + ty_axis * m.y;
            vec3 n = normalize(normal);
            vec3 bent = normalize(n * max(m.z, 0.05) + (d - n * dot(n, d)));
            float w = clamp(cover * (has_albedo ? tex_a : 1.0), 0.0, 1.0);
            normal = normalize(mix(n, bent, w));
        }
    }
}
@end
