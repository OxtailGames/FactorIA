// The light data of the mesh fragment shaders: where the lights are read from, and the read of one light as a LightSample. The ONE
// declaration both the mesh template (mesh_common.glsl, the engine's own meshes and the custom materials of mode "snippet") and the
// full-shader template (mesh_full_common.glsl) include with `@include_block fa_light_data`, after the block fa_types (LightSample is
// declared there) and after the fragment head, which declares the light data texture and defines FA_LIGHT_TEX and FA_LIGHT_SMP.
// Nothing here is compiled on its own.
//
// M73.1, clustered forward lighting (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md): the lights of the frame and the list of lights of
// every cluster of the view are packed by the renderer (src/light_clusters.cpp) into ONE data texture of 1024 RGBA32F texels per row,
// read with texelFetch (view 24, sampler 1). Texel t is at (t & 1023, t >> 10). The layout, in texels:
//   [0, S * L)                       light n at S n .. S n + S - 1, S = 4 normally and 8 (fa_ambient.w) in a view where a light has
//                                    an area, a cookie or an IES profile (M73.1b); the first four texels:
//                                      +0 xyz position (point/spot/area) or direction TO the light (directional), w range
//                                      +1 rgb colour * intensity, w type (0 directional, 1 point, 2 spot, 3 area)
//                                      +2 xyz the axis the light points along (spot, area, the axis of an IES profile), w cos(spot half angle)
//                                      +3 x cos of the inner cone of a spot (2 = the default fade), y z reserved,
//                                         w flags: 1 = Light.mode Baked (its direct light is in the lightmaps, M73.4a), else 0
//                                    and, when S = 8, the extension texels (zero for a light that has none of the three):
//                                      +4 xyz the light's right axis, w area: half width (rectangle, tube: half length) or radius (disc);
//                                         directional cookie: 1 / its width in metres
//                                      +5 xyz the light's up axis, w area: half height (rectangle), radius (disc) or half thickness (tube);
//                                         directional cookie: 1 / its height in metres
//                                      +6 xy the origin in texels of the cookie's tile in the light atlas (a point light's: of its cube of
//                                         3 x 2 face tiles of 256 texels), z = 1 when there is a cookie,
//                                         w area shape (0 rectangle, 1 disc, 2 tube)
//                                      +7 xy the origin of the IES tile, z = 1 when there is a profile, w area: radius of the sphere around
//                                         the emitter (the range is measured from its surface)
//   [fa_cl_info.x, + fa_cl_info.w)   one texel per cluster (slice-major, then row, then column): x = slot of its first light index,
//                                    y = how many local lights it has, z = slot of its first decal index, w = how many decals it has
//   after the clusters               the light indices, four to a texel (x, y, z, w); slot s is component s & 3 of the s >> 2 th
//                                    texel of this region
//   after the light indices          the shadow region of the point and spot lights (M73.2b), only in a frame where one has a shadow
//                                    map or a contact shadow; its first texel is fa_shadow_lcfg.x - 1 (the fa_shadows block, shadow_common.glsl):
//                                      [base, base + L)  light n: x = the texel of its record, or -1 (no shadow map this frame);
//                                      y = Light.contactShadowLength in metres, 0 = no contact shadow (M73.2c), z = 1 + the slot (0, 1 or 2)
//                                      of the light in the ray traced local shadows' image (M79-P2a-3, fa_shadow_local_rt; 0 = not traced),
//                                      w free. The region is also there, with every x = -1, in a frame where a light has a contact shadow or a
//                                      traced shadow and none a map.
//                                      then the records: 2 header texels (+0 kind 1 = one tile / 2 = six cube faces, fade distance,
//                                      filter, softness k; +1 depth bias, normal bias) and 6 texels per tile: the four rows of the
//                                      matrix world -> (u * w, v * w, -, w) of the atlas texture (w = metres along the tile's axis), the
//                                      tile's rectangle (umin, vmin, umax, vmax), and (metres per texel at distance 1, near plane,
//                                      far plane). Written by local_shadows.cpp, read by fa_shadow_local.
//   from fa_counts.y (0 = none)      (after the shadow region when there is one) the decals of the view (M73.5b, block fa_decals below): two header texels, 7 texels per decal, the
//                                    decal indices four to a texel
// The directional lights come first in the light table (at most 32) and belong to every cluster; the local lights of a cluster are
// in ascending index order, so a loop over "directional, then the cluster's list" adds the lights up in the order of the table.
@block fa_light_data
// The first texel of light li: 8 texels apart when a light of the view has extension texels (fa_ambient.w = 8; fa_counts.y is the
// first texel of the decal region), else 4 (fa_ambient.w = 0 or 4).
int fa_light_base(int li) { return li * (fa_ambient.w > 4.5 ? 8 : 4); }

vec4 fa_light_texel(int t) {
    return texelFetch(sampler2D(FA_LIGHT_TEX, FA_LIGHT_SMP), ivec2(t & 1023, t >> 10), 0);
}

// The colour times intensity of light li of the table (no attenuation).
vec3 fa_light_rgb(int li) { return fa_light_texel(fa_light_base(li) + 1).rgb; }
// The type of light li: 0 directional, 1 point, 2 spot, 3 area.
float fa_light_type(int li) { return fa_light_texel(fa_light_base(li) + 1).w; }
// Whether light li is baked (Light.mode Baked): a lightmapped fragment skips it, its direct light is in the lightmap.
bool fa_light_baked(int li) { return fa_light_texel(fa_light_base(li) + 3).w > 0.5; }

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

// fa_cube_face(d), the face of a cube a direction falls in, is the block fa_cube_face of shadow_common.glsl, included before this block.
// The forward and up axes of cube face f: the table of cube_face_basis (local_shadows.cpp); the face's right is forward x up.
void fa_cube_face_basis(int f, out vec3 fwd, out vec3 up) {
    if (f == 0) { fwd = vec3(1.0, 0.0, 0.0); up = vec3(0.0, 1.0, 0.0); }
    else if (f == 1) { fwd = vec3(-1.0, 0.0, 0.0); up = vec3(0.0, 1.0, 0.0); }
    else if (f == 2) { fwd = vec3(0.0, 1.0, 0.0); up = vec3(0.0, 0.0, 1.0); }
    else if (f == 3) { fwd = vec3(0.0, -1.0, 0.0); up = vec3(0.0, 0.0, -1.0); }
    else if (f == 4) { fwd = vec3(0.0, 0.0, 1.0); up = vec3(0.0, 1.0, 0.0); }
    else { fwd = vec3(0.0, 0.0, -1.0); up = vec3(0.0, 1.0, 0.0); }
}

// The cookie and profile factors multiply the colour of the light a fragment gets (fa_light_sample sets it, 1 for a light without a
// cookie): the standard light loop reads it after the sample it asked for.
vec3 fa_light_tint;
// 1 while the last fa_light_sample was a light of type 3 (an area light) in a view with extension texels: the standard loop then shades
// it with the LTC tables (light_loop.glsl) instead of the point-light terms.
bool fa_light_is_area;

// The point of an area light's emitter a shading point takes its light from (the "representative point", Karis 2013): the closest point
// of the emitter to the ray `r` (the view reflected about the normal) from `p`, or, when r is zero, to p itself. A rectangle and a disc
// are the plane of the light (axis `axis`, right `ru`, up `uu`, half sizes hx and hy; the disc's radius is hx) cut by the ray (the
// ray's plane point when it reaches the plane in front of it, else p's projection) and clamped to the shape; a tube is the segment
// c +- ru * hx (its thickness does not move the point).
vec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r) {
    bool has_ray = dot(r, r) > 0.5;
    if (shape > 1.5) {
        vec3 a = c - ru * hx - p;
        vec3 ld = ru * (2.0 * hx);
        float len2 = max(dot(ld, ld), 1e-8);
        float t = clamp(-dot(a, ld) / len2, 0.0, 1.0);
        if (has_ray) {
            float rol0 = dot(r, a);
            float rold = dot(r, ld);
            float den = len2 - rold * rold;
            if (abs(den) > 1e-5 * len2) { t = clamp((rol0 * rold - dot(a, ld)) / den, 0.0, 1.0); }
        }
        return p + a + ld * t;
    }
    vec3 q = p;
    float denom = dot(r, axis);
    if (has_ray && abs(denom) > 1e-4) {
        float tr = dot(c - p, axis) / denom;
        if (tr > 0.0) { q = p + r * tr; }
    }
    vec3 d = q - c;
    vec2 xy = vec2(dot(d, ru), dot(d, uu));
    if (shape > 0.5) {
        float len = length(xy);
        if (len > hx) { xy *= hx / len; }
    } else {
        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));
    }
    return c + ru * xy.x + uu * xy.y;
}

// Light li of the table as seen from a world position, without its shadow: the direction to it, its color times intensity times
// attenuation, the attenuation, the distance and the type. shadow is 1. The cookie and the IES profile are in the colour and the
// attenuation. An area light (type 3) is a point light at the representative point of its emitter (fa_area_point), seen from the
// camera: the point closest to the view reflected about `n` (the geometric normal; a zero `n` takes the point closest to the surface),
// with the colour and attenuation of a point light at its centre, and no light for a surface behind a rectangle or a disc (they shine
// from their front only). The engine's own lighting shades an area light with the LTC tables instead (light_loop.glsl).
LightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n) {
    int base = fa_light_base(li);
    bool ext = fa_ambient.w > 4.5;
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
        float centre_dist = length(to_light);
        float reach = centre_dist;
        bool front = true;
        if (ext && type > 2.5) {
            reach = max(centre_dist - fa_light_texel(base + 7).w, 0.0);
            vec4 e4 = fa_light_texel(base + 4);
            vec4 e5 = fa_light_texel(base + 5);
            float shape = fa_light_texel(base + 6).w;
            vec3 axis = normalize(fa_light_texel(base + 2).xyz);
            front = shape > 1.5 || dot(axis, to_light) < 0.0;
            vec3 r = vec3(0.0);
            vec3 to_cam = fa_camera_pos.xyz - world_pos;
            if (dot(n, n) > 0.5 && dot(to_cam, to_cam) > 1e-12) { r = reflect(-normalize(to_cam), normalize(n)); }
            to_light = fa_area_point(pos.xyz, axis, e4.xyz, e5.xyz, e4.w, e5.w, shape, world_pos, r) - world_pos;
        }
        dist = length(to_light);
        l = to_light / max(dist, 1e-4);
        float range = max(pos.w, 1e-3);
        float x = clamp(1.0 - (reach / range) * (reach / range), 0.0, 1.0);
        atten = front ? x * x : 0.0;
        if (type > 1.5 && type < 2.5) {
            vec4 dir = fa_light_texel(base + 2);
            float cos_angle = dot(-l, normalize(dir.xyz));
            float cos_outer = dir.w;
            float cos_inner = fa_light_texel(base + 3).x;
            if (cos_inner > 1.5) { cos_inner = mix(cos_outer, 1.0, 0.25); }
            atten *= smoothstep(cos_outer, cos_inner, cos_angle);
        }
        if (ext && type < 1.5) {
            vec4 e6 = fa_light_texel(base + 6);
            if (e6.z > 0.5) {
                // A point light's cookie: a cube of six face tiles (3 x 2 tiles of 256 texels at e6.xy) in the light's own frame
                // (right e4, up e5, back = right x up), the face chosen as the shadow's cube is (fa_cube_face).
                vec3 rel = -to_light;
                vec4 e4 = fa_light_texel(base + 4);
                vec4 e5 = fa_light_texel(base + 5);
                vec3 p = vec3(dot(rel, e4.xyz), dot(rel, e5.xyz), dot(rel, cross(e4.xyz, e5.xyz)));
                int f = fa_cube_face(p);
                vec3 fwd;
                vec3 up;
                fa_cube_face_basis(f, fwd, up);
                float w = max(dot(p, fwd), 1e-4);
                vec2 st = vec2(dot(p, cross(fwd, up)), dot(p, up)) / w;
                vec2 face_origin = vec2(float(f - (f / 3) * 3), float(f / 3)) * 256.0;
                fa_light_tint = fa_cookie_sample(e6.xy + face_origin, vec2(0.5 + 0.5 * st.x, 0.5 - 0.5 * st.y));
            }
            vec4 e7 = fa_light_texel(base + 7);
            if (e7.z > 0.5) {
                vec3 axis = normalize(fa_light_texel(base + 2).xyz);
                atten *= fa_ies_sample(e7.xy, -l, axis, fa_light_texel(base + 4).xyz, fa_light_texel(base + 5).xyz);
            }
        } else if (ext && type < 2.5) {
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
// The same without a normal (the representative point is the closest to the surface).
LightSample fa_light_sample(int li, vec3 world_pos) { return fa_light_sample_n(li, world_pos, vec3(0.0)); }

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

// ---- Spherical harmonics (M73.3a; docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The sky's spherical harmonics") ----
// The diffuse light (irradiance divided by pi) a surface facing n receives from a radiance given as nine RGB coefficients of the real
// spherical harmonics of bands 0..2 (the order and constants of ShL2 / sh_basis() in fa/scene/lightmap_bake.h: Y00, y, z, x, xy, yz,
// 3z^2 - 1, xz, x^2 - y^2): the radiance's coefficients times the clamped cosine's (1, 2/3, 1/4 per band; the 1/pi is in them). A radiance
// of one colour L gives L toward every n. L2 can undershoot below zero on the side opposite a strong light; the result is clamped at 0.
// The sky's coefficients come from fa_sky_sh_coef (mesh_common.glsl), the light probes of M73.4d read theirs from the light data texture.
@block fa_sh
vec3 fa_sh_eval(vec3 c[9], vec3 n) {
    vec3 r = c[0] * 0.282094792;
    r += c[1] * (0.325735008 * n.y) + c[2] * (0.325735008 * n.z) + c[3] * (0.325735008 * n.x);
    r += c[4] * (0.273137108 * n.x * n.y) + c[5] * (0.273137108 * n.y * n.z) + c[6] * (0.078847891 * (3.0 * n.z * n.z - 1.0));
    r += c[7] * (0.273137108 * n.x * n.z) + c[8] * (0.136568554 * (n.x * n.x - n.y * n.y));
    return max(r, vec3(0.0));
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
    float lod = clamp(0.5 * log2(max(max(dot(gx, gx), dot(gy, gy)), 1e-8)), 0.0, 3.0);  // 3 = kDecalMaxLod (decal_atlas.h): the gutter holds a bilinear tap of level 3
    return textureLod(sampler2D(FA_DECAL_TEX, FA_DECAL_SMP), rect.xy + clamp(uv, 0.0, 1.0) * size, lod);
}

// Paints the decals of the fragment's cluster over the surface: `world_pos` the position, `geo_normal` the geometric normal (the way the
// face looks, for the angle fade), `albedo` and `normal` (the shading normal, in the world) are changed. Call it once, in uniform control flow
// (it takes derivatives), before the lights. Nothing happens while the view has no decals or the mesh does not receive them.
void fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal) {
    // The two tests are on uniforms (the view and the draw), so every fragment of a quad takes the same branch and the derivatives below
    // stay in uniform control flow; the cluster's decal count (per fragment) is only tested after them.
    if (fa_counts.y < 0.5 || fa_counts.w < 0.5) { return; }
    vec3 dpx = dFdx(world_pos);
    vec3 dpy = dFdy(world_pos);
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
