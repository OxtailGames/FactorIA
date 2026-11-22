// The Terrain component's programs (M75-P5a, docs/BIG_WORLDS.md "Terrain"): the mesh template (mesh_common.glsl) with a vertex() that
// places each vertex of one shared 33 x 33 patch on the heightmap and morphs it toward the coarser level of detail (CDLOD), and a
// surface() that lights it. It is the shape of a custom material's generated top file (tools/common/src/shaders_generate.cpp), so the lighting,
// the shadows, the prepass, fog and the clustered lights are the ones of every MeshRenderer. engine/render/src/terrain_lod.cpp has the CPU twin
// of vertex() (terrain_vertex_raw), which the tests compare with the drawn geometry.
//
// Compiled with FA_HAS_VERTEX and FA_INST_2 (the `// shdc-defines:` line below; tools/shaders/compile_shaders.sh passes it to sokol-shdc).
// shdc-defines: FA_HAS_VERTEX:FA_INST_2
//
// Per node (instance data, two vec4): fa_nd0 = (first column, first row, step, level), fa_nd1 = (morph start, morph end) in metres from
// the camera. Per draw (the material block, binding 4 in the vertex stage and 5 in the fragment stage; the same eight vec4):
//   fa_t_m0..m3  the entity's model matrix (the patch has no place of its own: vertex() puts the vertex in the world itself)
//   fa_t_cam     xyz the camera in the terrain's local space, w = cells (samples - 1)
//   fa_t_grid    x, y = the metres of one cell along x and z, z = metres per raw height step (heightScale / 65535), w = heightOffset
//   fa_t_tex     x = the splat maps (0..2), y = 1 when there are holes (the patch is then the split one: see vertex()), z = 0 without albedo textures, else 1 + their fix (fa_tex_fix of
//                mesh_common.glsl: 0 as sampled, 1 sRGB to linear, 2 linear to sRGB), w the same for the normal textures
//   fa_t_nrm     x = bit mask of the layers that have an albedo texture, y the same for the normal textures, z = the side of the control
//                array in pixels, w = the number of layers (0 = none: the shading values of the MeshRenderer)
//   fa_t_layer   (fragment stage only) per layer: x = 1 / tileSize, y = roughness, z = metallic, w = normalScale
// The heights are in an RG8 texture (r = high byte, g = low byte), read with texelFetch: views 6 (fragment) and 10 (vertex), through a nearest sampler (samplers 2 and 6).
// The layers: view 7 is the albedo array and view 8 the normal array (one slice per layer, with mips, sampler 3 and 4), view 9 the CONTROL array
// (sampler 5, linear, clamped): slice 0 and 1 are the RGBA splat maps (channel c of map m weights layer 4m + c), the slice after them (when fa_t_tex.y)
// holds the holes in its red channel (255 = hole): the VERTEX stage reads it (view 13, sampler 9) and collapses the quads of the hole cells, so the
// hole is in the geometry and the main, shadow and prepass programs need no discard (the Metal GPU compiler cannot build this fragment shader with
// one). All of it fits the 16 texture units of the fragment stage that WebGL2 and
// GLES3 guarantee; a terrain with no layers binds one-pixel arrays.
@module terrain

@block fa_user
#ifdef GL_VERTEX_SHADER
layout(binding=4) uniform fa_material_vs {
    vec4 fa_t_m0; vec4 fa_t_m1; vec4 fa_t_m2; vec4 fa_t_m3;
    vec4 fa_t_cam; vec4 fa_t_grid; vec4 fa_t_tex; vec4 fa_t_nrm;
};
layout(binding=10) uniform texture2D fa_vs_height;
layout(binding=6) uniform sampler fa_vs_height_smp;
layout(binding=13) uniform texture2DArray fa_vs_control;
layout(binding=9) uniform sampler fa_vs_control_smp;
#else
layout(binding=5) uniform fa_material {
    vec4 fa_t_m0; vec4 fa_t_m1; vec4 fa_t_m2; vec4 fa_t_m3;
    vec4 fa_t_cam; vec4 fa_t_grid; vec4 fa_t_tex; vec4 fa_t_nrm;
    vec4 fa_t_layer[8];
};
layout(binding=6) uniform texture2D fa_t_height;
layout(binding=2) uniform sampler fa_t_height_smp;
layout(binding=7) uniform texture2DArray fa_t_albedo;
layout(binding=8) uniform texture2DArray fa_t_normal;
layout(binding=9) uniform texture2DArray fa_t_control;
layout(binding=3) uniform sampler fa_t_albedo_smp;
layout(binding=4) uniform sampler fa_t_normal_smp;
layout(binding=5) uniform sampler fa_t_control_smp;
#endif

// The per-node values, set from the instance buffer before vertex() runs.
vec4 fa_nd0;
vec4 fa_nd1;
void fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2) {
    fa_nd0 = fa_d0;
    fa_nd1 = fa_d1;
}

#ifdef GL_VERTEX_SHADER
// The raw 16-bit height of sample (column, row), the grid's edge repeated outside it (as terrain_vertex_raw).
float fa_t_raw(ivec2 cr) {
    cr = clamp(cr, ivec2(0), ivec2(int(fa_t_cam.w + 0.5)));
    vec2 t = texelFetch(sampler2D(fa_vs_height, fa_vs_height_smp), cr, 0).rg;
    return floor(t.x * 255.0 + 0.5) * 256.0 + floor(t.y * 255.0 + 0.5);
}

void vertex(inout VertexData v) {
    ivec2 g = ivec2(floor(v.object_pos.xz + 0.5));  // 0..32: the vertex of the patch
    int st = int(fa_nd0.z + 0.5);
    ivec2 first = ivec2(floor(fa_nd0.xy + 0.5));
    if (fa_t_tex.y > 0.5) {
        // A terrain with holes is drawn with the split patch (every quad has its own four vertices, whose uv is the quad's lower-left
        // corner 0..31). A quad whose middle cell is a hole collapses to a point: its four vertices all take the corner's place.
        ivec2 q = ivec2(floor(v.uv + 0.5));
        ivec2 cell = clamp(first + q * st + ivec2(st / 2), ivec2(0), ivec2(int(fa_t_cam.w + 0.5) - 1));
        float side = fa_t_nrm.z;
        ivec2 tp = ivec2(min(vec2(side - 1.0), floor((vec2(cell) + 0.5) * (side / fa_t_cam.w))));
        if (texelFetch(sampler2DArray(fa_vs_control, fa_vs_control_smp), ivec3(tp, int(fa_t_tex.x + 0.5)), 0).r > 0.5) g = q;
    }
    ivec2 cr = first + g * st;
    float h = fa_t_raw(cr);
    bool ox = (g.x & 1) != 0, oz = (g.y & 1) != 0;
    if (ox || oz) {
        // The height the coarser level has here: the mean of its two neighbours on the line of the cell's edge, or of the corners of
        // the diagonal (r, c) - (r + 1, c + 1) in the middle of a coarse cell.
        float coarse;
        if (ox && oz)
            coarse = 0.5 * (fa_t_raw(cr - ivec2(st)) + fa_t_raw(cr + ivec2(st)));
        else if (ox)
            coarse = 0.5 * (fa_t_raw(cr - ivec2(st, 0)) + fa_t_raw(cr + ivec2(st, 0)));
        else
            coarse = 0.5 * (fa_t_raw(cr - ivec2(0, st)) + fa_t_raw(cr + ivec2(0, st)));
        vec2 xz0 = (vec2(cr) - 0.5 * fa_t_cam.w) * fa_t_grid.xy;
        float d = length(xz0 - fa_t_cam.xz);
        float m = fa_nd1.y > fa_nd1.x ? clamp((d - fa_nd1.x) / (fa_nd1.y - fa_nd1.x), 0.0, 1.0) : (d >= fa_nd1.y ? 1.0 : 0.0);
        h = mix(h, coarse, m);
    }
    vec2 xz = (vec2(cr) - 0.5 * fa_t_cam.w) * fa_t_grid.xy;
    vec3 local = vec3(xz.x, fa_t_grid.w + fa_t_grid.z * h, xz.y);
    mat4 model = mat4(fa_t_m0, fa_t_m1, fa_t_m2, fa_t_m3);
    v.world_pos = (model * vec4(local, 1.0)).xyz;
    v.uv = xz;  // the terrain's local x and z: the fragment stage tiles the textures and finds its heights by it
}
#else
float fa_t_raw(ivec2 cr) {
    cr = clamp(cr, ivec2(0), ivec2(int(fa_t_cam.w + 0.5)));
    vec2 t = texelFetch(sampler2D(fa_t_height, fa_t_height_smp), cr, 0).rg;
    return floor(t.x * 255.0 + 0.5) * 256.0 + floor(t.y * 255.0 + 0.5);
}
// The fix of one texture sample (as fa_tex_fix of mesh_common.glsl, which is declared after this block): 0 as sampled, 1 sRGB-encoded
// values to linear, 2 linear to sRGB-encoded.
vec3 fa_t_fix(vec3 c, float mode) {
    c = max(c, vec3(0.0));
    if (mode > 1.5) return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, c * 12.92, step(c, vec3(0.0031308)));
    if (mode > 0.5) return mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045)));
    return c;
}
// The raw heights of the 4 x 4 samples around the cell (c, r) minus its four corners (twelve fetches), as the central-difference slope at each of
// the cell's four corners: what fa_t_slope of the four corners gives (sixteen fetches), the shared samples read once.
void fa_t_slopes(ivec2 c, out vec2 s00, out vec2 s10, out vec2 s01, out vec2 s11) {
    float a0 = fa_t_raw(c + ivec2(-1, 0)), a1 = fa_t_raw(c), a2 = fa_t_raw(c + ivec2(1, 0)), a3 = fa_t_raw(c + ivec2(2, 0));
    float b0 = fa_t_raw(c + ivec2(-1, 1)), b1 = fa_t_raw(c + ivec2(0, 1)), b2 = fa_t_raw(c + ivec2(1, 1)), b3 = fa_t_raw(c + ivec2(2, 1));
    float u0 = fa_t_raw(c + ivec2(0, -1)), u1 = fa_t_raw(c + ivec2(1, -1));
    float d0 = fa_t_raw(c + ivec2(0, 2)), d1 = fa_t_raw(c + ivec2(1, 2));
    vec2 k = vec2(fa_t_grid.z) / (2.0 * fa_t_grid.xy);
    s00 = vec2(a2 - a0, b1 - u0) * k;
    s10 = vec2(a3 - a1, b2 - u1) * k;
    s01 = vec2(b2 - b0, d0 - a1) * k;
    s11 = vec2(b3 - b1, d1 - a2) * k;
}

// Adds layer k, weighted w (nothing when w is 0), to the blend: its albedo, its normal-map vector, its roughness and its metallic.
void fa_t_layer_add(int k, float w, in SurfaceInput i, vec2 duvx, vec2 duvy, vec3 grey, int aMask, int nMask, inout vec3 albedo,
                    inout vec3 dsum, inout float rough, inout float metal) {
    if (w > 0.0) {
        vec4 L = fa_t_layer[k];  // 1 / tileSize, roughness, metallic, normalScale
        vec3 a = grey;
        if (((aMask >> k) & 1) != 0)
            a = fa_t_fix(textureGrad(sampler2DArray(fa_t_albedo, fa_t_albedo_smp), vec3(i.uv * L.x, float(k)), duvx * L.x, duvy * L.x).rgb,
                         fa_t_tex.z - 1.0);
        albedo += a * w;
        vec3 d = vec3(0.0, 0.0, 1.0);  // flat
        if (((nMask >> k) & 1) != 0) {
            d = fa_t_fix(textureGrad(sampler2DArray(fa_t_normal, fa_t_normal_smp), vec3(i.uv * L.x, float(k)), duvx * L.x, duvy * L.x).xyz,
                         fa_t_tex.w - 1.0) * 2.0 - 1.0;
            d.xy *= L.w;
        }
        dsum += d * w;
        rough += L.y * w;
        metal += L.z * w;
    }
}

// The shading of a point of the terrain.
void fa_t_shade(in SurfaceInput i, inout Surface s, vec2 duvx, vec2 duvy, vec2 cuv, int nLayers, int nSplat) {
    // The normal comes from the heights, not from the (coarser) geometry: the shading does not change when a tile changes level. The
    // slope at the four samples around the point, blended.
    vec2 p = i.uv / fa_t_grid.xy + 0.5 * fa_t_cam.w;
    vec2 fl = floor(p);
    vec2 f = p - fl;
    ivec2 c = ivec2(fl);
    vec2 s00, s10, s01, s11;
    fa_t_slopes(c, s00, s10, s01, s11);
    vec2 slope = mix(mix(s00, s10, f.x), mix(s01, s11, f.x), f.y);
    vec3 nl = normalize(vec3(-slope.x, 1.0, -slope.y));  // the terrain's local space (y up)
    // To the tangent frame of the patch (tangent = local +x, normal = +y, bitangent = -z): fa_tangent_normal makes it world space.
    vec3 n = fa_tangent_normal(i, vec3(nl.x, -nl.z, nl.y));
    if (nLayers > 0) {
        // The weight of each layer: the splat maps (bilinear), normalised over the layers there are; layer 0 alone without maps.
        vec4 w0 = vec4(1.0, 0.0, 0.0, 0.0), w1 = vec4(0.0);
        if (nSplat > 0 && nLayers > 1) {
            vec4 c0 = texture(sampler2DArray(fa_t_control, fa_t_control_smp), vec3(cuv, 0.0));
            vec4 c1 = nSplat > 1 ? texture(sampler2DArray(fa_t_control, fa_t_control_smp), vec3(cuv, 1.0)) : vec4(0.0);
            vec4 lim = vec4(float(nLayers));
            c0 *= vec4(lessThan(vec4(0.0, 1.0, 2.0, 3.0), lim));
            c1 *= vec4(lessThan(vec4(4.0, 5.0, 6.0, 7.0), lim));
            float sum = dot(c0, vec4(1.0)) + dot(c1, vec4(1.0));
            if (sum > 1.0e-4) {
                w0 = c0 / sum;
                w1 = c1 / sum;
            }
        }
        int aMask = int(fa_t_nrm.x + 0.5), nMask = int(fa_t_nrm.y + 0.5);
        vec3 grey = s.albedo;  // a layer without an albedo texture keeps the grey of the MeshRenderer
        vec3 albedo = vec3(0.0), dsum = vec3(0.0);
        float rough = 0.0, metal = 0.0;
        // Unrolled: the Metal GPU compiler crashes on this blend as a loop over a local array.
        fa_t_layer_add(0, w0.x, i, duvx, duvy, grey, aMask, nMask, albedo, dsum, rough, metal);
        fa_t_layer_add(1, w0.y, i, duvx, duvy, grey, aMask, nMask, albedo, dsum, rough, metal);
        fa_t_layer_add(2, w0.z, i, duvx, duvy, grey, aMask, nMask, albedo, dsum, rough, metal);
        fa_t_layer_add(3, w0.w, i, duvx, duvy, grey, aMask, nMask, albedo, dsum, rough, metal);
        fa_t_layer_add(4, w1.x, i, duvx, duvy, grey, aMask, nMask, albedo, dsum, rough, metal);
        fa_t_layer_add(5, w1.y, i, duvx, duvy, grey, aMask, nMask, albedo, dsum, rough, metal);
        fa_t_layer_add(6, w1.z, i, duvx, duvy, grey, aMask, nMask, albedo, dsum, rough, metal);
        fa_t_layer_add(7, w1.w, i, duvx, duvy, grey, aMask, nMask, albedo, dsum, rough, metal);
        s.albedo = albedo;
        s.roughness = rough;
        s.metallic = metal;
        if (nMask != 0) {
            vec3 t0 = normalize(i.world_tangent.xyz - n * dot(n, i.world_tangent.xyz));
            vec3 b0 = cross(n, t0);
            n = normalize(t0 * dsum.x + b0 * dsum.y + n * max(dsum.z, 0.05));
        }
    }
    s.normal = n;
}
void surface(in SurfaceInput i, inout Surface s) {
    // The derivatives of the position first: the layers' textures are read inside branches (textureGrad).
    vec2 duvx = dFdx(i.uv), duvy = dFdy(i.uv);
    // 0..1 across the terrain, 0 at its -X and -Z edge.
    vec2 cuv = i.uv / (fa_t_grid.xy * fa_t_cam.w) + 0.5;
    int nLayers = int(fa_t_nrm.w + 0.5);
    int nSplat = int(fa_t_tex.x + 0.5);
    fa_t_shade(i, s, duvx, duvy, cuv, nLayers, nSplat);
}
#endif
@end

@include mesh_common.glsl

@program terrain vs fs
@program shadow shadow_vs shadow_fs
@program prepass prepass_vs prepass_fs
