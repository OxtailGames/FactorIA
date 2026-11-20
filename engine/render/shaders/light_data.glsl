// The light data of the mesh fragment shaders: where the lights are read from, and the read of one light as a LightSample. The ONE
// declaration both the mesh template (mesh_common.glsl, the engine's own meshes and the custom materials of mode "snippet") and the
// full-shader template (mesh_full_common.glsl) include with `@include_block fa_light_data`, after the block fa_types (LightSample is
// declared there) and after the fragment head, which declares the light data texture and defines FA_LIGHT_TEX and FA_LIGHT_SMP.
// Nothing here is compiled on its own.
//
// M73.1, clustered forward lighting (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md): the lights of the frame and the list of lights of
// every cluster of the view are packed by the renderer (src/light_clusters.cpp) into ONE data texture of 1024 RGBA32F texels per row,
// read with texelFetch (view 24, sampler 1). Texel t is at (t & 1023, t >> 10). The layout, in texels:
//   [0, S * L)                       light n at S n .. S n + S - 1, S = 4 normally and 8 (fa_counts.y) in a view where a light has
//                                    an area, a cookie or an IES profile (M73.1b); the first four texels:
//                                      +0 xyz position (point/spot/area) or direction TO the light (directional), w range
//                                      +1 rgb colour * intensity, w type (0 directional, 1 point, 2 spot, 3 area)
//                                      +2 xyz the axis the light points along (spot, area, the axis of an IES profile), w cos(spot half angle)
//                                      +3 x cos of the inner cone of a spot (2 = the default fade), yzw reserved
//                                    and, when S = 8, the extension texels (zero for a light that has none of the three):
//                                      +4 xyz the light's right axis, w area: half width (rectangle, tube: half length) or radius (disc);
//                                         directional cookie: 1 / its width in metres
//                                      +5 xyz the light's up axis, w area: half height (rectangle), radius (disc) or half thickness (tube);
//                                         directional cookie: 1 / its height in metres
//                                      +6 xy the origin in texels of the cookie's tile in the light atlas, z = 1 when there is a cookie,
//                                         w area shape (0 rectangle, 1 disc, 2 tube)
//                                      +7 xy the origin of the IES tile, z = 1 when there is a profile, w area: radius of the sphere around
//                                         the emitter (the range is measured from its surface)
//   [fa_cl_info.x, + fa_cl_info.w)   one texel per cluster (slice-major, then row, then column): x = slot of its first light index,
//                                    y = how many local lights it has
//   after the clusters               the light indices, four to a texel (x, y, z, w); slot s is component s & 3 of the s >> 2 th
//                                    texel of this region
// The directional lights come first in the light table (at most 32) and belong to every cluster; the local lights of a cluster are
// in ascending index order, so a loop over "directional, then the cluster's list" adds the lights up in the order of the table.
@block fa_light_data
// The first texel of light li: 8 texels apart when a light of the view has extension texels (fa_counts.y = 8), else 4.
int fa_light_base(int li) { return li * (fa_counts.y > 4.5 ? 8 : 4); }

vec4 fa_light_texel(int t) {
    return texelFetch(sampler2D(FA_LIGHT_TEX, FA_LIGHT_SMP), ivec2(t & 1023, t >> 10), 0);
}

// The colour times intensity of light li of the table (no attenuation).
vec3 fa_light_rgb(int li) { return fa_light_texel(fa_light_base(li) + 1).rgb; }
// The type of light li: 0 directional, 1 point, 2 spot, 3 area.
float fa_light_type(int li) { return fa_light_texel(fa_light_base(li) + 1).w; }

// The light atlas (light_atlas.h; view 25): the LTC tables, the cookies and the IES profiles in one RGBA16F image. `texel` is a
// position in texels (the centre of the first texel is (0.5, 0.5)); the lookup is bilinear and never reads a mip.
vec4 fa_atlas_fetch(vec2 texel) {
    vec2 size = vec2(textureSize(sampler2D(FA_ATLAS_TEX, FA_ATLAS_SMP), 0));
    return textureLod(sampler2D(FA_ATLAS_TEX, FA_ATLAS_SMP), texel / size, 0.0);
}

// A cookie tile (256 x 256 texels with a border that wraps; the picture is the inner 254): `uv` is 0..1 across the picture, v down.
vec3 fa_cookie_sample(vec2 tile_origin, vec2 uv) {
    return fa_atlas_fetch(tile_origin + vec2(1.0) + clamp(uv, 0.0, 1.0) * 254.0).rgb;
}

// An IES tile (66 x 34 texels: 64 x 32 profile, a border that wraps across and clamps down): the intensity, 0..1 of the peak, toward
// `d`, the direction from the light to the point, given the light's axis (the nadir of the profile), right and up (the horizontal
// angle 0 is the right axis, it grows toward up).
float fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up) {
    float v = acos(clamp(dot(d, axis), -1.0, 1.0)) * 0.3183098862;
    float px = dot(d, right);
    float py = dot(d, up);
    float h = (px * px + py * py > 1e-10) ? atan(py, px) * 0.1591549431 : 0.0;
    h -= floor(h);
    return fa_atlas_fetch(tile_origin + vec2(1.0 + h * 64.0, 1.0 + v * 32.0)).r;
}

// The cookie and profile factors multiply the colour of the light a fragment gets (fa_light_sample sets it, 1 for a light without a
// cookie): the standard light loop reads it after the sample it asked for.
vec3 fa_light_tint;
// 1 while the last fa_light_sample was a light of type 3 (an area light) in a view with extension texels: the standard loop then shades
// it with the LTC tables (light_loop.glsl) instead of the point-light terms.
bool fa_light_is_area;

// Light li of the table as seen from a world position, without its shadow: the direction to it, its color times intensity times
// attenuation, the attenuation, the distance and the type. shadow is 1. An area light (type 3) is a point light at its centre here
// (the engine's own lighting shades it with the LTC tables, light_loop.glsl); the cookie and the IES profile are in the colour and
// the attenuation.
LightSample fa_light_sample(int li, vec3 world_pos) {
    int base = fa_light_base(li);
    bool ext = fa_counts.y > 4.5;
    vec4 pos = fa_light_texel(base);
    vec4 col = fa_light_texel(base + 1);
    float type = col.w;
    vec3 l;
    float atten = 1.0;
    float dist = 0.0;
    fa_light_tint = vec3(1.0);
    fa_light_is_area = ext && type > 2.5;
    if (type < 0.5) {
        l = normalize(pos.xyz);
        if (ext) {
            vec4 e6 = fa_light_texel(base + 6);
            if (e6.z > 0.5) {
                // A directional cookie: an orthographic projection along the light, tiled over its world size, anchored at the origin.
                vec4 e4 = fa_light_texel(base + 4);
                vec4 e5 = fa_light_texel(base + 5);
                vec2 uv = vec2(dot(world_pos, e4.xyz) * e4.w, -dot(world_pos, e5.xyz) * e5.w) + vec2(0.5);
                fa_light_tint = fa_cookie_sample(e6.xy, fract(uv));
            }
        }
    } else {
        vec3 to_light = pos.xyz - world_pos;
        dist = length(to_light);
        l = to_light / max(dist, 1e-4);
        float range = max(pos.w, 1e-3);
        float reach = dist;
        if (ext && type > 2.5) { reach = max(dist - fa_light_texel(base + 7).w, 0.0); }
        float x = clamp(1.0 - (reach / range) * (reach / range), 0.0, 1.0);
        atten = x * x;
        if (type > 1.5 && type < 2.5) {
            vec4 dir = fa_light_texel(base + 2);
            float cos_angle = dot(-l, normalize(dir.xyz));
            float cos_outer = dir.w;
            float cos_inner = fa_light_texel(base + 3).x;
            if (cos_inner > 1.5) { cos_inner = mix(cos_outer, 1.0, 0.25); }
            atten *= smoothstep(cos_outer, cos_inner, cos_angle);
        }
        if (ext && type < 2.5) {
            vec4 e6 = fa_light_texel(base + 6);
            vec4 e7 = fa_light_texel(base + 7);
            if (e6.z > 0.5 || e7.z > 0.5) {
                vec4 dir = fa_light_texel(base + 2);
                vec3 axis = normalize(dir.xyz);
                vec4 e4 = fa_light_texel(base + 4);
                vec4 e5 = fa_light_texel(base + 5);
                if (e6.z > 0.5) {
                    // A spot cookie: a perspective projection through the cone, the cone's edge on the picture's edge.
                    vec3 rel = -to_light;
                    float z = dot(rel, axis);
                    float tan_outer = sqrt(max(1.0 - dir.w * dir.w, 0.0)) / max(dir.w, 1e-3);
                    float k = 0.5 / max(z * tan_outer, 1e-4);
                    vec2 uv = vec2(0.5 + dot(rel, e4.xyz) * k, 0.5 - dot(rel, e5.xyz) * k);
                    fa_light_tint = fa_cookie_sample(e6.xy, uv);
                }
                if (e7.z > 0.5) { atten *= fa_ies_sample(e7.xy, -l, axis, e4.xyz, e5.xyz); }
            }
        }
    }
    LightSample ls;
    ls.direction = l;
    ls.color = col.rgb * atten;
    if (ext) { ls.color *= fa_light_tint; }
    ls.attenuation = atten;
    ls.shadow = 1.0;
    ls.distance = dist;
    ls.type = type < 0.5 ? 0 : ((type > 1.5 && type < 2.5) ? 2 : 1);
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
