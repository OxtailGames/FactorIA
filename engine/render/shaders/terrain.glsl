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
//   fa_t_tex     x, y = 1 / tileSize along x and z, z = 1 when layer 0 has an albedo texture, w = 1 when it has a normal texture
//   fa_t_nrm     x = the normal map's scale
// The heights are in an RG8 texture (r = high byte, g = low byte), read with texelFetch: views 6 (fragment) and 10 (vertex), through a nearest sampler (samplers 2 and 6).
@module terrain

@block fa_user
#ifdef GL_VERTEX_SHADER
layout(binding=4) uniform fa_material_vs {
    vec4 fa_t_m0; vec4 fa_t_m1; vec4 fa_t_m2; vec4 fa_t_m3;
    vec4 fa_t_cam; vec4 fa_t_grid; vec4 fa_t_tex; vec4 fa_t_nrm;
};
layout(binding=10) uniform texture2D fa_vs_height;
layout(binding=6) uniform sampler fa_vs_height_smp;
#else
layout(binding=5) uniform fa_material {
    vec4 fa_t_m0; vec4 fa_t_m1; vec4 fa_t_m2; vec4 fa_t_m3;
    vec4 fa_t_cam; vec4 fa_t_grid; vec4 fa_t_tex; vec4 fa_t_nrm;
};
layout(binding=6) uniform texture2D fa_t_height;
layout(binding=2) uniform sampler fa_t_height_smp;
layout(binding=7) uniform texture2D fa_t_albedo;
layout(binding=8) uniform texture2D fa_t_normal;
layout(binding=3) uniform sampler fa_t_albedo_smp;
layout(binding=4) uniform sampler fa_t_normal_smp;
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
    ivec2 g = ivec2(floor(v.object_pos.xz + 0.5));  // 0..32: the vertex of the shared patch
    int st = int(fa_nd0.z + 0.5);
    ivec2 cr = ivec2(floor(fa_nd0.xy + 0.5)) + g * st;
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
// The slope (metres per metre along x, z) at sample `cr`: central differences.
vec2 fa_t_slope(ivec2 cr) {
    float dx = fa_t_raw(cr + ivec2(1, 0)) - fa_t_raw(cr - ivec2(1, 0));
    float dz = fa_t_raw(cr + ivec2(0, 1)) - fa_t_raw(cr - ivec2(0, 1));
    return vec2(dx, dz) * fa_t_grid.z / (2.0 * fa_t_grid.xy);
}

void surface(in SurfaceInput i, inout Surface s) {
    // The normal comes from the heights, not from the (coarser) geometry: the shading does not change when a tile changes level. The
    // slope at the four samples around the point, blended.
    vec2 p = i.uv / fa_t_grid.xy + 0.5 * fa_t_cam.w;
    vec2 fl = floor(p);
    vec2 f = p - fl;
    ivec2 c = ivec2(fl);
    vec2 slope = mix(mix(fa_t_slope(c), fa_t_slope(c + ivec2(1, 0)), f.x),
                     mix(fa_t_slope(c + ivec2(0, 1)), fa_t_slope(c + ivec2(1, 1)), f.x), f.y);
    vec3 nl = normalize(vec3(-slope.x, 1.0, -slope.y));  // the terrain's local space (y up)
    // To the tangent frame of the patch (tangent = local +x, normal = +y, bitangent = -z): fa_tangent_normal makes it world space.
    vec3 n = fa_tangent_normal(i, vec3(nl.x, -nl.z, nl.y));
    vec2 uv = i.uv * fa_t_tex.xy;
    if (fa_t_tex.z > 0.5) s.albedo = texture(sampler2D(fa_t_albedo, fa_t_albedo_smp), uv).rgb;
    if (fa_t_tex.w > 0.5) {
        vec3 d = texture(sampler2D(fa_t_normal, fa_t_normal_smp), uv).xyz * 2.0 - 1.0;
        d.xy *= fa_t_nrm.x;
        vec3 t0 = normalize(i.world_tangent.xyz - n * dot(n, i.world_tangent.xyz));
        vec3 b0 = cross(n, t0);
        n = normalize(t0 * d.x + b0 * d.y + n * max(d.z, 0.05));
    }
    s.normal = n;
}
#endif
@end

@include mesh_common.glsl

@program terrain vs fs
@program shadow shadow_vs shadow_fs
@program prepass prepass_vs prepass_fs
