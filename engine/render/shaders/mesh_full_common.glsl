// FactorIA full-shader template (docs/shaders/SHADERS_FULL.md, docs/design/CUSTOM_SHADERS_FULL.md): the engine side of a mesh material
// whose "mode" is "full", i.e. whose author writes the vertex and the fragment stage (and their `main`) instead of a surface()
// snippet. Not compiled on its own: the generated top file defines the @block fa_user (the material's params, textures and
// instanced-param globals; no snippet), `@include mesh_common.glsl` (the blocks below build on its fa_vs_common, fa_skin_common,
// fa_inst_*, fa_extra_attrs and fa_types) and `@include mesh_full_common.glsl`, then declares, per pass, the programs
//     @vs  <name>      #define FA_PASS n / FA_PASS_<NAME> [/ FA_SKIN] [/ FA_SHADOW_PASS], @include_block fa_full_vs_head,
//                      `#define main fa_user_main`, the author's code, `#undef main`, @include_block fa_full_vs_tail
//     @fs  <name>      the same with fa_full_fs_head and fa_full_fs_tail
// so the author's `void main()` is the entry the engine's own main calls, after it has set up the model matrix (instancing and
// skinning), the instanced params and the declared mesh channels. Every engine identifier starts with fa_ (FA_ for macros).
//
// The declarations of the fragment resources (views 0 and 1, samplers 0 and 1, fa_mesh_fs_params) and the helpers copied from
// mesh_common.glsl (the fog, the colour space fixes) are copies, not includes: mesh_common.glsl's fa_fs_surface also declares the
// engine's own varyings, which a full shader does not have. A test (shader_template_test.cpp) compares the uniform block
// fa_mesh_fs_params with mesh_common.glsl's, so they cannot drift apart. The light uniform block and the light sample
// (light_data.glsl: fa_light_data), the shadow lookup (shadow_common.glsl: fa_shadow_common) and the sky functions (fa_environment,
// fa_env_brdf, fa_sky_reflection, fa_ambient_light: fa_env_funcs) are the exception: they are blocks of mesh_common.glsl's files,
// included here, so the engine's own meshes and a full shader read the lights and the shadow through the same code.

// ---- vertex stage ----

@block fa_full_vs_head
@include_block fa_vs_common
#ifdef FA_SKIN
@include_block fa_skin_common
#endif
@include_block fa_inst_out
// The attribute locations are those of the engine's pipeline layouts: the mesh pass (position, normal, uv, tangent, colour, the
// model matrix, the joints) or the shadow pass (position, the model matrix, the joints, normal, uv, tangent, colour).
#ifdef FA_SHADOW_PASS
layout(location=0) in vec3 fa_position;
layout(location=1) in vec4 fa_inst_m0;
layout(location=2) in vec4 fa_inst_m1;
layout(location=3) in vec4 fa_inst_m2;
layout(location=4) in vec4 fa_inst_m3;
#ifdef FA_SKIN
layout(location=5) in vec4 fa_joints;
layout(location=6) in vec4 fa_weights;
layout(location=7) in vec3 fa_normal;
layout(location=8) in vec2 fa_texcoord0;
layout(location=9) in vec4 fa_tangent;
layout(location=10) in vec4 fa_color;
#define FA_X_BASE 11
#else
layout(location=5) in vec3 fa_normal;
layout(location=6) in vec2 fa_texcoord0;
layout(location=7) in vec4 fa_tangent;
layout(location=8) in vec4 fa_color;
#define FA_X_BASE 9
#endif
#else
layout(location=0) in vec3 fa_position;
layout(location=1) in vec3 fa_normal;
layout(location=2) in vec2 fa_texcoord0;
layout(location=3) in vec4 fa_tangent;
layout(location=4) in vec4 fa_color;
layout(location=5) in vec4 fa_inst_m0;
layout(location=6) in vec4 fa_inst_m1;
layout(location=7) in vec4 fa_inst_m2;
layout(location=8) in vec4 fa_inst_m3;
#ifdef FA_SKIN
layout(location=9) in vec4 fa_joints;
layout(location=10) in vec4 fa_weights;
#define FA_X_BASE 11
#else
#define FA_X_BASE 9
#endif
#endif
@include_block fa_extra_attrs

// The model matrix of this vertex: the instance's, times the joint blend of a skinned mesh. Set before main().
mat4 fa_model;
// Seconds of game time, and the camera's world position (fa_time.yzw of the vertex stage, fa_camera_pos.xyz of the fragment one).
#define FA_TIME fa_time.x
#define FA_CAMERA fa_time.yzw
// In a pass that casts the shadow of the material ("shadow": "custom"), fa_view_proj is the light's matrix, so the author's
// `gl_Position = fa_view_proj * ...` is the shadow map's position there.
#ifdef FA_SHADOW_PASS
#define fa_view_proj fa_light_vp
#endif

vec3 fa_world_position(vec3 p) { return (fa_model * vec4(p, 1.0)).xyz; }
// A model-space direction to the world: the cofactor matrix of the upper 3x3 (inverse transpose up to a positive scale, right for
// a non-uniform scale and a mirrored instance), normalized.
vec3 fa_world_direction(vec3 n) {
    vec3 c0 = fa_model[0].xyz;
    vec3 c1 = fa_model[1].xyz;
    vec3 c2 = fa_model[2].xyz;
    float s = dot(c0, cross(c1, c2)) < 0.0 ? -1.0 : 1.0;
    return normalize((cross(c1, c2) * n.x + cross(c2, c0) * n.y + cross(c0, c1) * n.z) * s);
}
// The shadow coordinate of a world position: pass it in a varying to fa_shadow() of the fragment stage. Since M73.2 it is the world
// position itself (the fragment stage picks the cascade of the sun's shadow and projects it); `fa_light_vp` is still the light's matrix of
// a pass that casts the shadow of the material.
vec4 fa_shadow_coord(vec3 world) { return vec4(world, 1.0); }
@end

@block fa_full_vs_tail
void main() {
    fa_inst_begin();
#ifdef FA_SKIN
    fa_model = FA_INST_MODEL * fa_skin_matrix(fa_joints, fa_weights);
#else
    fa_model = FA_INST_MODEL;
#endif
    fa_user_main();
}
@end

// ---- fragment stage ----

@block fa_full_fs_head
layout(binding=0) uniform texture2D fa_tex;             // the MeshRenderer's base colour texture
layout(binding=1) uniform texture2D fa_full_shadow_tex;
layout(binding=0) uniform sampler fa_smp;
layout(binding=1) uniform sampler fa_full_shadow_smp;
@image_sample_type fa_full_shadow_tex unfilterable_float
@sampler_type fa_full_shadow_smp nonfiltering
// What fa_shadow_sun (shadow_common.glsl) samples. The names differ from mesh_common.glsl's (sokol-shdc wants a texture name to be
// unique in the whole top file, and the top of a full material also holds the engine's own programs).
#define FA_SHADOW_TEX fa_full_shadow_tex
#define FA_SHADOW_SMP fa_full_shadow_smp
// The light data texture (light_data.glsl; view 24), read with texelFetch through the shadow map's nearest sampler.
layout(binding=24) uniform texture2D fa_full_light_tex;
@image_sample_type fa_full_light_tex unfilterable_float
#define FA_LIGHT_TEX fa_full_light_tex
#define FA_LIGHT_SMP fa_full_shadow_smp
// The light atlas (as mesh_common.glsl's fa_fs_head: view 25, sampler 10): the cookies and IES profiles of the lights a full shader
// reads through fa_light(). The area lights' LTC shading is the engine's own meshes' (a full shader sees an area light as a point light).
layout(binding=25) uniform texture2D fa_full_light_atlas;
#define FA_ATLAS_TEX fa_full_light_atlas
#define FA_ATLAS_SMP fa_env_smp
// The decal atlas (light_data.glsl, block fa_decals; view 27, sampler 10): read by fa_apply_decals.
layout(binding=27) uniform texture2D fa_full_decal_tex;
#define FA_DECAL_TEX fa_full_decal_tex
#define FA_DECAL_SMP fa_env_smp
// The probe atlas (as mesh_common.glsl's fa_fs_head: view 14, sampler 10): the sky's tile and the reflection probes' (fa_env_funcs). A full
// shader has no fragment world position, so a probe's box does not correct its reflection here (FA_ENV_PARALLAX is not defined).
layout(binding=14) uniform texture2D fa_probe_atlas;
layout(binding=10) uniform sampler fa_env_smp;

// A copy of mesh_common.glsl's fa_mesh_fs_params (a test compares them): the same CPU struct fills both.
layout(binding=1) uniform fa_mesh_fs_params {
    vec4 fa_camera_pos;         // xyz
    vec4 fa_ambient;            // rgb; w = texels per light of the light table (4, or 8 while a light of the view has an area, a cookie
                                // or an IES profile; 0 = 4: M73.1b, light_data.glsl)
    vec4 fa_base_color;
    vec4 fa_emissive;           // rgb MeshRenderer.emissive, w = 1 when unlit
    vec4 fa_model_emissive;     // rgb glTF emissiveFactor (multiplies fa_emissive_tex)
    vec4 fa_pbr;                // x metallic, y roughness, z receive shadow (0/1), w shadow depth bias
    vec4 fa_maps;               // x normal scale, y occlusion strength, z = 1 when a normal map is bound, w = the colour space
                                // fixes of the textures (SceneSettings.colorSpace, see fa_tex_fix): base + 4 * emissive +
                                // 16 * normal + 64 * metallic-roughness + 256 * occlusion, each 0, 1 or 2; 0 in a gamma scene with 8-bit images
    vec4 fa_fog;                // rgb color, w density (exponential squared, SceneSettings.fogDensity or the stack's fogDensity)
    vec4 fa_fog_b;              // the stack's fog (PostProcess.fog*) on a blended mesh: x = fogStart, y = height density,
                                // z = height base (world y), w = height falloff; all 0 for the scene's own fog
    vec4 fa_fog_c;              // xyz = the camera's forward axis in the world, w = 1 for an orthographic camera (0 otherwise)
    vec4 fa_counts;             // x = light count, y = first texel of the decal region (0 = no decals), z = 1 on OpenGL backends,
                                // w = what this mesh takes of the decals: 0 = none, else 1 + MeshRenderer.decalLayer
    vec4 fa_env_sky;            // rgb sky color (top of the environment); w = 1 when the sky's tile of the probe atlas holds the baked sky
    vec4 fa_env_horizon;        // rgb horizon color; w = the texture LOD bias of the frame (fa_mip_bias below; 0 = none)
    vec4 fa_time;               // x = seconds of game time since the scene started
    // Clustered lighting (M73.1; src/light_clusters.h): the rows of the view-projection matrix that give a fragment's tile, the
    // camera's forward depth and the grid; all zero (fa_cl_info.x = -1) while the frame has no local lights.
    vec4 fa_cl_vpx;             // row 0 of the view-projection matrix: clip x of a world position
    vec4 fa_cl_vpy;             // row 1: clip y
    vec4 fa_cl_vpw;             // row 3: clip w
    vec4 fa_cl_fwd;             // xyz = the camera's forward axis, w = -dot(forward, position): depth = dot(xyz, world) + w
    vec4 fa_cl_grid;            // x = tiles across, y = tiles down, z = depth slices per octave (slices / log2(far / near)), w = near
    vec4 fa_cl_info;            // x = first texel of the cluster table (-1 = no clusters), y = depth slices, z = directional lights,
                                // w = clusters (tiles x * tiles y * slices)
    vec4 fa_layers_a;           // x clearcoat, y clearcoat roughness, z anisotropy, w anisotropy rotation (radians)
    vec4 fa_layers_b;           // rgb sheen colour, w sheen roughness
    vec4 fa_layers_c;           // x specular, y ior, z = the layer data packed in the maps: 1 = the occlusion map holds the clear coat
                                // in g, its roughness in b and the sheen roughness in a; 2 = the metallic-roughness map holds the
                                // anisotropy strength in r and the specular in a (the importer packs them, see brdf_layers.glsl)
    vec4 fa_layers_d;           // rgb specular colour (KHR_materials_specular)
    // Contact shadows (M73.2c): a full shader has none, it only has to keep the block the CPU fills the same size.
    vec4 fa_ct_a;
    vec4 fa_ct_b;
    vec4 fa_ct_vpx;
    vec4 fa_ct_vpy;
    vec4 fa_ct_vpw;
    vec4 fa_ct_fwd;
    // Transmission and volume (M73.6b): a full shader has none either.
    vec4 fa_tr_a;
    vec4 fa_tr_b;
    // Light probes (M73.4d): a full shader has no lighting either; the 9 vec4 keep the block the same size.
    vec4 fa_probe_sh[9];
    // The reflection probes (M73-P3c): see mesh_common.glsl.
    vec4 fa_atlas;
    vec4 fa_rpa_tile;
    vec4 fa_rpa_pos;
    vec4 fa_rpa_bx;
    vec4 fa_rpa_by;
    vec4 fa_rpa_bz;
    vec4 fa_rpb_tile;
    vec4 fa_rpb_pos;
    vec4 fa_rpb_bx;
    vec4 fa_rpb_by;
    vec4 fa_rpb_bz;
    // The realtime GI grids and the LOD cross-fade (w): see mesh_common.glsl. A full shader never fades (the renderer switches its levels at once).
    vec4 fa_gi;
};

// The texture LOD bias of the frame (M76-P4b): negative while the temporal upscaler or the temporal antialiasing accumulates jittered
// frames, 0 otherwise. fa_base_sample() adds it; add it to the other texture reads: texture(sampler2D(t, t_smp), uv, fa_mip_bias).
// Fragment stage only.
#define fa_mip_bias (fa_env_horizon.w)

@include_block fa_inst_flags
@include_block fa_inst_in
@include_block fa_types
// The light uniform block and fa_light_sample (light_data.glsl), the same declaration as the engine's own meshes; the shadow lookup
// fa_shadow_sun (shadow_common.glsl).
@include_block fa_cube_face
@include_block fa_light_data
@include_block fa_decals
@include_block fa_shadow_common
@include_block fa_user

// The sky the surface reflects and the ambient light (fa_environment, fa_env_brdf, fa_sky_reflection, fa_ambient_light): the same code as
// the engine's own meshes.
@include_block fa_env_funcs

layout(location=0) out vec4 fa_frag_color;

#define FA_TIME fa_time.x
#define FA_CAMERA fa_camera_pos.xyz

// Loads the instanced params the vertex stage passed on into the globals the generator declared.
void fa_inst_load() {
#if FA_NINST == 1
    fa_instance_unpack(fa_inst_v0, vec4(0.0), vec4(0.0));
#elif FA_NINST == 2
    fa_instance_unpack(fa_inst_v0, fa_inst_v1, vec4(0.0));
#elif FA_NINST == 3
    fa_instance_unpack(fa_inst_v0, fa_inst_v1, fa_inst_v2);
#endif
}

vec3 fa_srgb_to_linear(vec3 c) {
    c = max(c, vec3(0.0));
    return mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045)));
}
vec3 fa_linear_to_srgb(vec3 c) {
    c = max(c, vec3(0.0));
    return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, c * 12.92, step(c, vec3(0.0031308)));
}
// The MeshRenderer's base colour texture sampled at uv, in the scene's colour space, times MeshRenderer.color.
vec4 fa_base_sample(vec2 uv) {
    vec4 t = texture(sampler2D(fa_tex, fa_smp), uv, fa_mip_bias);
    float mode = mod(floor(fa_maps.w + 0.01), 4.0);
    if (mode > 1.5) {
        t.rgb = fa_linear_to_srgb(t.rgb);
    } else if (mode > 0.5) {
        t.rgb = fa_srgb_to_linear(t.rgb);
    }
    return t * fa_base_color;
}

// The fraction of light that reaches a surface (1 = lit) from the directional light's cascaded shadow: `coord` is fa_shadow_coord() of the
// vertex stage, n the geometric normal, l the direction to the light. 1 when the MeshRenderer does not receive shadows.
float fa_shadow(vec4 coord, vec3 n, vec3 l) {
    return fa_shadow_sun(coord.xyz / coord.w, n, l);
}

// The first lights of the scene's light table: the directional lights, then the most relevant local ones, at most 32 (fa_counts.x of
// them). What a full shader that has no position to ask for a cluster loops over; fa_cluster_light_count() is the list of a position.
int fa_light_count() { return min(int(fa_counts.x), 32); }
// Light li (0 .. fa_light_count() - 1, or an index of fa_cluster_light_index()) as seen from a surface point: the direction to the
// light, its colour times intensity times attenuation times shadow, the attenuation and the shadow separately, the distance and the
// type (0 directional, 1 point, 2 spot). `coord` is fa_shadow_coord() of the vertex stage (the first directional light has the sun's
// shadow, a point or spot light with a shadow map this frame its own); `gn` the geometric normal.
LightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord) {
    LightSample ls = fa_light_sample_n(li, world_pos, gn);
    if (ls.type == 0 && li == 0) {
        ls.shadow = fa_shadow(coord, gn, ls.direction);
        ls.color = ls.color * ls.shadow;
    } else if (ls.type != 0 && ls.attenuation > 0.0) {
        ls.shadow = fa_shadow_local(li, fa_light_texel(fa_light_base(li)).xyz, world_pos, gn, ls.direction);
        ls.color = ls.color * ls.shadow;
    }
    return ls;
}
// The lights that reach a world position (M73.1, clustered lighting): the directional lights and the local lights of the position's
// cluster, hundreds in the scene but a few here. fa_cluster_light_index(n, p) for n in 0 .. fa_cluster_light_count(p) - 1 is the
// index to give to fa_light(). Both look the cluster up again: call fa_cluster_light_count once and keep the position.
int fa_cluster_light_count(vec3 world_pos) {
    return int(fa_cl_info.z) + fa_cluster_lookup(world_pos).y;
}
int fa_cluster_light_index(int n, vec3 world_pos) {
    int ndir = int(fa_cl_info.z);
    if (n < ndir) { return n; }
    return fa_cluster_index(fa_cluster_lookup(world_pos).x, n - ndir);
}

// The scene's fog (SceneSettings fog, or the stack's fog on a blended mesh) applied to a colour drawn at a world position: the
// engine's own meshes call the same formula. A full shader is not fogged unless it calls this.
vec3 fa_apply_fog(vec3 result, vec3 world_pos) {
    if (fa_fog.w > 0.0 || fa_fog_b.y > 0.0) {
        vec3 rel = world_pos - fa_camera_pos.xyz;
        float dep = dot(rel, fa_fog_c.xyz);
        float dist = fa_fog_c.w > 0.5 ? dep : length(rel);
        float len = dist - fa_fog_b.x;
        if (len > 0.0) {
            float tau = fa_fog.w * len;
            tau *= tau;
            if (fa_fog_b.y > 0.0) {
                float py = world_pos.y;
                float ey = fa_fog_c.w > 0.5 ? py - fa_fog_c.y * dep : fa_camera_pos.y;
                float ya = mix(ey, py, clamp(fa_fog_b.x / dist, 0.0, 1.0));
                float dy = py - ya;
                float ka = ya - fa_fog_b.z;
                float kb = py - fa_fog_b.z;
                float ha = (ka <= 0.0 || fa_fog_b.w < 1e-4) ? fa_fog_b.y : fa_fog_b.y * exp(-min(fa_fog_b.w * ka, 80.0));
                float ia = (ka <= 0.0 || fa_fog_b.w < 1e-4) ? fa_fog_b.y * ka : fa_fog_b.y * (1.0 - exp(-min(fa_fog_b.w * ka, 80.0))) / fa_fog_b.w;
                float ib = (kb <= 0.0 || fa_fog_b.w < 1e-4) ? fa_fog_b.y * kb : fa_fog_b.y * (1.0 - exp(-min(fa_fog_b.w * kb, 80.0))) / fa_fog_b.w;
                float avg = abs(dy) < 1e-3 ? ha : (ib - ia) / dy;
                tau += len * max(avg, 0.0);
            }
            float f = 1.0 - exp(-clamp(tau, 0.0, 80.0));
            result = mix(result, fa_fog.rgb, clamp(f, 0.0, 1.0));
        }
    }
    return result;
}
@end

@block fa_full_fs_tail
void main() {
    fa_inst_load();
    fa_user_main();
#ifdef FA_SHADOW_PASS
    // The shadow map holds depth only: whatever the author wrote, the pass outputs the fragment's depth (a discard still cuts holes).
    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
#endif
}
@end
