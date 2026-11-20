// The shadow sampling of the mesh fragment shaders: the cascaded shadow of the directional light, shared by the engine's own light loop
// (mesh_common.glsl: fa_shadow_factor) and by the full-shader template (mesh_full_common.glsl: fa_shadow). Included with
// `@include_block fa_shadow_common` after the fragment head has declared the shadow atlas and its sampler (the macros FA_SHADOW_TEX and
// FA_SHADOW_SMP name them: the engine's meshes and the full-shader template use different names) and fa_pbr. Not compiled on its own.
//
// M73.2a: the shadow map is one 2D atlas (R32F, the fragment's depth 0..1 over the cascade's depth range) that holds one tile per cascade
// of the sun, the faces of the point lights and the maps of the spot lights (M73.2b). The CPU side (shadow_cascades.h,
// Renderer::Impl::shadow_bounds / scene_uniforms in renderer_draw.cpp) cuts the camera's view into cascades, fits a stable map to each
// and fills the block below; this block picks the cascade of a fragment, blends two at the seam and filters (hard, PCF or PCSS).
// fa_shadow_local does the same for a point or spot light: its record in the light data texture (light_data.glsl, "the shadow region")
// names its tiles, the face of a cube is chosen by the major axis, and the one filter below (fa_shadow_filter) reads the tile.
// docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The shadow atlas".
@block fa_shadow_common
layout(binding=7) uniform fa_shadows {
    mat4 fa_shadow_mat[4];      // cascade i: world position -> (u, v) in the atlas texture and depth 0..1 over the cascade's depth range
    vec4 fa_shadow_rect[4];     // cascade i: its tile in the atlas texture, (umin, vmin, umax, vmax), a texel smaller on every side
    vec4 fa_shadow_info[4];     // cascade i: x = metres per texel, y = metres between its near and far plane
    vec4 fa_shadow_split;       // where each cascade ends: the distance along the camera's forward axis (0 for the cascades not used)
    vec4 fa_shadow_cfg;         // x = cascades (0 = no shadow this frame), y = blend fraction of a cascade, z = filter (0 pcf, 1 hard, 2 pcss),
                                // w = tan of the light's angular radius (pcss)
    vec4 fa_shadow_bias;        // x = depth bias in metres (0 = automatic), y = normal bias in metres (0 = automatic), zw = one texel of the atlas in u, v
    vec4 fa_shadow_eye;         // xyz = the camera's position, w = 1 when the cascade debug view is on
    vec4 fa_shadow_fwd;         // xyz = the camera's forward axis, w = where the first cascade starts (distance along it)
    vec4 fa_shadow_lcfg;        // x = 1 + the first texel of the local lights' shadow region of the light data texture (0 = none)
};

// A rotation per pixel that no neighbour shares (interleaved gradient noise): the same on every backend and in every frame, so a still
// picture never shimmers. The kernels are fixed tables of the Vogel disk, never random.
float fa_shadow_noise() {
    return fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715))));
}
// Point k of n of the unit disk, turned by phi.
vec2 fa_shadow_vogel(int k, int n, float phi) {
    float r = sqrt((float(k) + 0.5) / float(n));
    float a = float(k) * 2.39996323 + phi;
    return vec2(cos(a), sin(a)) * r;
}
// The end of cascade i (a vector is not indexed by a variable: legacy targets cannot flatten it).
float fa_shadow_split_at(int i) {
    return i == 0 ? fa_shadow_split.x : (i == 1 ? fa_shadow_split.y : (i == 2 ? fa_shadow_split.z : fa_shadow_split.w));
}
// The depth stored in the tile at uv (clamped into the tile: a filter never reads the neighbour's map).
float fa_shadow_depth(vec2 uv, vec4 rect) {
    uv = clamp(uv, rect.xy, rect.zw);
    return textureLod(sampler2D(FA_SHADOW_TEX, FA_SHADOW_SMP), uv, 0.0).r;  // explicit LOD: no gradients inside loops (HLSL X3570)
}

// What a tile stores is turned into the unit the receiver is compared in. The cascades store their depth over the cascade's range as it is
// (conv.x = 0); a perspective tile of a point or spot light stores the window depth z of a projection with near plane conv.y and far plane
// conv.z, which is metres along the tile's axis after c = n * f / (f - z * (f - n)).
float fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv) {
    float z = fa_shadow_depth(uv, rect);
    return conv.x < 0.5 ? z : conv.y * conv.z / (conv.z - z * (conv.z - conv.y));
}

// The filter of every shadow map: the fraction of light (1 lit) at uv of the tile `rect`, for a receiver at depth zr (bias taken off),
// in the unit of the tile's depth: `unit` metres each (the cascade's range; 1 for a perspective tile, whose unit is the metre). texel_m is
// the width of a texel at the receiver in metres, `plane` how much deeper the surface gets per texel to the side, `reach` how far in
// metres PCSS looks for casters, `k` the tangent of the light's angular size (pcss). mode: 0 pcf, 1 hard, 2 pcss.
float fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode,
                       float k) {
    vec2 texel_uv = fa_shadow_bias.zw;
    if (mode == 1) {  // hard: one tap
        return (zr <= fa_shadow_fetch(uv, rect, conv)) ? 1.0 : 0.0;
    }
    float phi = fa_shadow_noise() * 6.2831853;
    float radius = 1.5;  // pcf: a small fixed blur, in texels
    if (mode == 2) {
        // PCSS: find the casters in front of the receiver, take their mean depth, and size the blur by the distance to them.
        // A negative k is an area light's emitter size in metres (fa_shadow_local): the penumbra is that size times the distance
        // between the blocker and the receiver over the distance from the light to the blocker, a ratio of the tangent form below.
        float ks = k < 0.0 ? -k / max(zr, 0.1) : k;
        float search = clamp(ks * reach / texel_m, 3.0, 12.0);
        float sum = 0.0;
        float cnt = 0.0;
        for (int i = 0; i < 16; i++) {
            vec2 o = fa_shadow_vogel(i, 16, phi) * search;
            float d = fa_shadow_fetch(uv + o * texel_uv, rect, conv);
            if (d < zr - length(o) * plane) { sum += d; cnt += 1.0; }
        }
        if (cnt < 0.5) { return 1.0; }
        float mean_d = sum / cnt;
        float penumbra_m = max(zr - mean_d, 0.0) * unit * (k < 0.0 ? -k / max(mean_d, 0.05) : k);
        radius = clamp(penumbra_m / texel_m, 1.5, 16.0);
    }
    float lit = 0.0;
    int taps = mode == 2 ? 24 : 16;
    for (int i = 0; i < taps; i++) {
        vec2 o = fa_shadow_vogel(i, taps, phi) * radius;
        float d = fa_shadow_fetch(uv + o * texel_uv, rect, conv);
        lit += (zr - length(o) * plane <= d) ? 1.0 : 0.0;
    }
    return lit / float(taps);
}

// The light that reaches a position from cascade ci: 1 lit, 0 in shadow; -1 when the position is outside the cascade's map.
float fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l) {
    vec4 info = fa_shadow_info[ci];
    float texel_m = info.x;
    float range = max(info.y, 1e-3);
    float nl = clamp(dot(n, l), 0.0, 1.0);
    float sin_t = sqrt(1.0 - nl * nl);
    float slope = min(sin_t / max(nl, 0.2), 4.0);  // tan of the angle between the normal and the light, capped
    // The normal offset moves the position off the surface by what a texel of the map can be wrong by; the depth bias covers the rest.
    float nbias = fa_shadow_bias.y > 0.0 ? fa_shadow_bias.y : 1.5 * texel_m;
    vec3 p = (fa_shadow_mat[ci] * vec4(world + n * (nbias * sin_t), 1.0)).xyz;
    vec4 rect = fa_shadow_rect[ci];
    if (p.x < rect.x || p.x > rect.z || p.y < rect.y || p.y > rect.w || p.z > 1.0) { return -1.0; }
    float bias_m = (fa_shadow_bias.x > 0.0 ? fa_shadow_bias.x : 1.5 * texel_m) * (1.0 + 0.5 * slope);
    float zr = p.z - bias_m / range;
    float plane = texel_m * min(slope, 3.0) * 0.5 / range;  // how much deeper the surface gets per texel to the side of the centre
    return fa_shadow_filter(p.xy, rect, zr, texel_m, range, range * 0.25, plane, vec3(0.0), int(fa_shadow_cfg.z + 0.5),
                            fa_shadow_cfg.w);
}

// The light that reaches a world position from the shadow of the point or spot light li of the light table (1 lit, 0 in shadow); n the
// geometric normal, l the direction to the light. 1 when the light has no shadow map this frame, when the MeshRenderer does not receive
// shadows, and past the light's shadow distance (it fades out over its last quarter). The record of the light is in the shadow region of
// the light data texture: [base + li] = the texel of its record or -1; the record is 2 header texels (kind 1 = one tile, 2 = a cube; the
// fade distance; the filter; the softness k / the biases) and 6 texels per tile (4 rows of the sample matrix, the tile's rectangle, and
// metres per texel at distance 1, the near and far plane); a cube's faces are in the order +X -X +Y -Y +Z -Z.
float fa_shadow_local(int li, vec3 world, vec3 n, vec3 l) {
    if (fa_pbr.z < 0.5 || fa_shadow_lcfg.x < 0.5) { return 1.0; }
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
    if (h0.x > 1.5) {  // a cube: the face of the major axis of the direction from the light (the table of cube_face_basis)
        vec3 d = world - fa_light_texel(fa_light_base(li)).xyz;
        face = fa_cube_face(d);
    }
    int t = rec + 2 + face * 6;
    vec4 r0 = fa_light_texel(t);
    vec4 r1 = fa_light_texel(t + 1);
    vec4 r3 = fa_light_texel(t + 3);
    vec4 rect = fa_light_texel(t + 4);
    vec4 tinfo = fa_light_texel(t + 5);  // x = metres per texel at distance 1, y = near plane, z = far plane
    float texel_m = tinfo.x * max(dot(r3, vec4(world, 1.0)), 1e-3);
    float nl = clamp(dot(n, l), 0.0, 1.0);
    float sin_t = sqrt(1.0 - nl * nl);
    float pw0 = max(dot(r3, vec4(world, 1.0)), 1e-3);
    // The depth that is compared is the distance along the tile's AXIS, so how much it changes per texel across the surface is measured
    // against the axis, not against the light's ray: with a = the axis (the xyz of row 3) and r = the ray from the light divided by
    // pw0 (its component along the axis is 1), a plane of normal n has dw/dtexel = texel_m * sqrt(1 - (n.a)^2) / |n.r|. A surface that
    // faces the light at a cube face's diagonal has up to 0.5 where the angle between n and l says 0; one square to the axis has 0.
    vec3 axis = r3.xyz;
    float na = clamp(dot(n, axis), -1.0, 1.0);
    float nr = abs(dot(n, world - fa_light_texel(fa_light_base(li)).xyz)) / pw0;
    float slope = min(sqrt(1.0 - na * na) / max(nr, 0.2), 4.0);
    float nbias = h1.y > 0.0 ? h1.y : 1.5 * texel_m;
    vec4 wp = vec4(world + n * (nbias * sin_t), 1.0);
    float pw = dot(r3, wp);  // the receiver's distance along the tile's axis, in metres
    if (pw < tinfo.y) { return 1.0; }
    vec2 uv = vec2(dot(r0, wp), dot(r1, wp)) / pw;
    if (uv.x < rect.x || uv.x > rect.z || uv.y < rect.y || uv.y > rect.w) { return 1.0; }
    float bias_m = (h1.x > 0.0 ? h1.x : 1.5 * texel_m) * (1.0 + 0.5 * slope);
    float plane = texel_m * min(slope, 3.0) * 0.5;
    float s = fa_shadow_filter(uv, rect, pw - bias_m, texel_m, 1.0, tinfo.z * 0.25, plane, vec3(1.0, tinfo.y, tinfo.z),
                               int(h0.z + 0.5), h0.w);
    return mix(1.0, s, fade);
}

// The fraction of light that reaches a world position (1 = lit) from the directional light's cascaded shadow, n the geometric normal,
// l the direction to the light. 1 when the MeshRenderer does not receive shadows, past the last cascade, and while no shadow is drawn.
float fa_shadow_sun(vec3 world, vec3 n, vec3 l) {
    if (fa_pbr.z < 0.5) { return 1.0; }
    int count = int(fa_shadow_cfg.x + 0.5);
    if (count < 1) { return 1.0; }
    float d = dot(world - fa_shadow_eye.xyz, fa_shadow_fwd.xyz);
    if (d > fa_shadow_split_at(count - 1)) { return 1.0; }
    int ci = 0;
    if (count > 1 && d > fa_shadow_split.x) { ci = 1; }
    if (count > 2 && d > fa_shadow_split.y) { ci = 2; }
    if (count > 3 && d > fa_shadow_split.z) { ci = 3; }
    float s = -1.0;
    for (int k = 0; k < 4; k++) {
        if (ci >= count) { break; }
        s = fa_shadow_cascade(ci, world, n, l);
        if (s >= 0.0) { break; }
        ci++;
    }
    if (s < 0.0) { return 1.0; }
    // Near the end of a cascade it blends into the next one (the last fades out into light), so the seam does not show.
    float blend = fa_shadow_cfg.y;
    if (blend > 0.0) {
        float start = ci > 0 ? fa_shadow_split_at(ci - 1) : fa_shadow_fwd.w;
        float band = blend * max(fa_shadow_split_at(ci) - start, 1e-4);
        float t = clamp((d - (fa_shadow_split_at(ci) - band)) / band, 0.0, 1.0);
        if (t > 0.0) {
            float s2 = 1.0;
            if (ci + 1 < count) {
                s2 = fa_shadow_cascade(ci + 1, world, n, l);
                if (s2 < 0.0) { s2 = s; }
            }
            s = mix(s, s2, t);
        }
    }
    return s;
}

// The cascade debug view (render.debug_view cascades): the colour tinted by the cascade the position falls in (red, green, blue,
// yellow; grey past the last). Unchanged while the view is off.
vec3 fa_shadow_debug(vec3 color, vec3 world) {
    if (fa_shadow_eye.w < 0.5) { return color; }
    int count = int(fa_shadow_cfg.x + 0.5);
    float d = dot(world - fa_shadow_eye.xyz, fa_shadow_fwd.xyz);
    vec3 tint = vec3(0.35);
    if (count > 0 && d <= fa_shadow_split_at(count - 1)) {
        tint = vec3(1.0, 0.15, 0.1);
        if (count > 1 && d > fa_shadow_split.x) { tint = vec3(0.1, 0.9, 0.2); }
        if (count > 2 && d > fa_shadow_split.y) { tint = vec3(0.15, 0.3, 1.0); }
        if (count > 3 && d > fa_shadow_split.z) { tint = vec3(1.0, 0.9, 0.1); }
    }
    return mix(color, tint, 0.55);
}
@end
