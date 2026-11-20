// FactorIA mesh template: the source of every mesh program, the engine's own and every custom material's
// (docs/design/CUSTOM_SHADERS.md). Not compiled on its own: a top file defines the @block fa_user (the material's
// uniforms, textures and snippet: void surface(in SurfaceInput i, inout Surface s) and, with FA_HAS_VERTEX defined,
// void vertex(inout VertexData v)), then `@include mesh_common.glsl` and declares the programs:
//   @program mesh vs fs                          (mesh.glsl does exactly this with an empty surface())
//   @program mesh_skin vs_skin fs
//   @program shadow shadow_vs shadow_fs
//   @program shadow_skin shadow_vs_skin shadow_fs
//   @program prepass prepass_vs prepass_fs
//   @program prepass_skin prepass_vs_skin prepass_fs
//
// Metallic-roughness PBR (Cook-Torrance GGX) with normal, metallic-roughness, occlusion and emissive maps, up to 32
// directional/point/spot lights, sky image-based lighting (a procedural environment built from the scene's sky and
// horizon colors, or the sky a sky material draws: its ambient light and reflection come from a baked cube), fog and an optional
// directional shadow map.
// Instanced: the model matrix of every instance comes from vertex buffer 1 (four vec4 columns, locations 5..8; 1..4 in
// the shadow pass, whose attributes must be contiguous). Skinned meshes use the _skin programs: joints and weights come
// from vertex buffer 2 (locations 9, 10; 5, 6 in the shadow pass).
// Vertex colors (glTF COLOR_0, MeshData.colors) are the fourth attribute of vertex buffer 0, four normalized bytes; a mesh
// without colors has white there. They multiply the base color in fa_standard_surface (rgb and alpha).
//
// alphaMode "clip" defines FA_ALPHA_CLIP: fs discards below alphaCutoff after surface(), and the shadow programs run
// surface() too (shadow_vs outputs the varyings, shadow_fs includes the fragment resources) to cut the same holes.
//
// The prepass programs draw the view-space linear depth and normal of the opaque meshes for the depth-based post effects (ambient
// occlusion, depth of field, fog, ...): vertex() and surface() run as in the main pass (a displaced vertex, a cutout, a normal map
// give the depth and normal the camera sees). The pass writes one RGBA float texel per pixel, see prepass_fs. There fa_light_vp
// holds the VIEW matrix (the shadow matrix is not used), fa_view_proj the camera's.
//
// Every engine identifier starts with fa_ (FA_ for constants), so "names starting with fa_ are the engine's" is the one
// rule a snippet follows. Uniform block bindings: vertex 0 fa_mesh_vs_params, 3 fa_skin (4 is left for the material's
// vertex-stage block); fragment 1 fa_mesh_fs_params (5 for the material). Views 0-5 and samplers 0-1 are
// the engine's, and so are views 14-15 and sampler 10 (the baked sky, fa_fs_head). A material texture is bound twice, so both stages can sample it (a sokol view slot belongs to one stage and
// sokol-shdc refuses one name in both): the fragment stage reads it at view 6.. and sampler 2.., the vertex stage at view 10..
// and sampler 6.. under the name fa_vs_<name> (the generator's #define makes the snippet write the plain name in both).
//
// Lighting "custom" defines FA_CUSTOM_LIGHT: the light loop below keeps choosing the lights, their attenuation and the shadow
// and calls the snippet's `vec3 light(in SurfaceInput i, in Surface s, in LightSample l)` once per light instead of
// Cook-Torrance; the ambient term is the snippet's `vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor)` when
// FA_HAS_AMBIENT is defined, else ambientColor * albedo * occlusion; the sky reflection is off unless the snippet adds it with
// fa_sky_light(). With FA_HAS_LIGHTING (the snippet defines `vec3 lighting(in SurfaceInput i, in Surface s)`) the loop and the
// ambient term are the snippet's too: it picks the lights with fa_light_count() and fa_light(n, i) and may add the sky.
// Emission and fog stay. The functions of the contract are declared before the snippet (the block fa_fs_light of the main
// fragment shader; the shadow and prepass fragment shaders get stubs, fa_fs_nolight).
//
// The lighting is split over three files this one @includes (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md): light_data.glsl (the
// light uniform block and the read of one light; the full-shader template includes the same block), shadow_common.glsl (the shadow
// lookup, shared with the full-shader template) and light_loop.glsl (the standard loop and the custom-light hooks). All three are in
// the template hash of the mesh kind.
@include light_data.glsl
@include ltc.glsl
@include shadow_common.glsl
@include light_loop.glsl
@include brdf_layers.glsl

// The snippet contract (docs/SHADERS.md).
@block fa_types
struct SurfaceInput {           // read-only, per fragment
    vec3 world_pos;
    vec3 world_normal;          // interpolated geometric normal, normalized, flipped on back faces
    vec4 world_tangent;         // xyz tangent, w handedness
    vec2 uv;                    // after MeshRenderer.uvScale
    vec4 vertex_color;          // the interpolated vertex color (glTF COLOR_0), white for a mesh without; already in the base color
    vec3 view_dir;              // surface -> camera, normalized
    bool front_facing;
};
struct Surface {                // what the lighting reads
    vec3 albedo;
    float alpha;
    vec3 normal;                // world space, normalized by the engine after surface()
    float metallic;
    float roughness;
    float occlusion;
    vec3 emission;
    // The material layers of M73.6 (docs/shaders/SHADERS_LIGHTING.md, "Material layers"): what the standard lighting reads, filled from
    // the MeshRenderer and the glTF material before surface(). The defaults draw as before.
    float clearcoat;            // 0..1 strength of the clear coat; 0 = none
    float clearcoat_roughness;  // 0..1 (the engine clamps it to 0.05..1)
    vec3 sheen_color;           // the cloth sheen's colour; black = none
    float sheen_roughness;      // 0..1 (clamped to 0.1..1)
    float anisotropy;           // -1..1: stretch of the highlight along the tangent (negative: across it); 0 = round
    float anisotropy_rotation;  // radians, turns the stretch direction around the normal
    float specular;             // 0..1 strength of the dielectric specular (1 = the usual 4% reflectance at ior 1.5)
    float ior;                  // 1..3 index of refraction: sets the dielectric reflectance at normal incidence
    vec3 specular_color;        // tint of the dielectric reflectance (KHR_materials_specular), white = none
};
struct LightSample {            // light(): one light as the engine's light loop selected it (lighting "custom")
    vec3 direction;             // surface -> light, normalized (a directional light: the direction its light comes from)
    vec3 color;                 // the light's color times intensity times attenuation times shadow: what reaches the surface
    float attenuation;          // 1 for a directional light; for a point or spot light the range falloff (times the spot cone)
    float shadow;               // 1 = lit, 0 = in shadow (the shadow map of the first directional light; 1 for every other light)
    float distance;             // surface -> light distance in world units; 0 for a directional light
    int type;                   // 0 directional, 1 point, 2 spot
};
struct VertexData {             // vertex(): world space, after instancing and skinning
    vec3 world_pos;
    vec3 world_normal;
    vec4 world_tangent;
    vec2 uv;
    vec4 color;                 // the vertex color (white for a mesh without)
    vec3 object_pos;            // the model-space position (read-only by convention)
};

// A tangent-space normal (-1..1, e.g. a normal map texel * 2 - 1) to world space. On back faces the frame is built from
// the front-face normal and the result flipped, as the engine's own normal map does.
vec3 fa_tangent_normal(in SurfaceInput i, vec3 m) {
    vec3 gn = i.front_facing ? i.world_normal : -i.world_normal;
    vec3 t = normalize(i.world_tangent.xyz - gn * dot(gn, i.world_tangent.xyz));
    vec3 b = cross(gn, t) * i.world_tangent.w;
    vec3 n = normalize(t * m.x + b * m.y + gn * m.z);
    return i.front_facing ? n : -n;
}
@end

// Per-instance params and declared mesh channels. The generator defines FA_INST_1..3 (the vec4 of per-instance data the
// material's instanced params need) and FA_CH_UV1 / FA_CH_COLOR1 (the "vertexAttributes" it declares); a material with none
// of them gets exactly the attributes it always had. The extra vertex attributes follow the matrix (and the joints) of every
// program that runs vertex() or surface(): FA_X_BASE (9, 11 in the skinned programs) is the first, then the instance data
// (vertex buffer 3, one per instance), then uv1 and color1 (vertex buffers 4 and 5, per vertex). The varyings are `flat`: one
// value per instance reaches surface() unchanged, which loads it into the globals the generator declared (fa_instance_unpack).
@block fa_inst_flags
#if defined(FA_INST_3)
#define FA_NINST 3
#elif defined(FA_INST_2)
#define FA_NINST 2
#elif defined(FA_INST_1)
#define FA_NINST 1
#else
#define FA_NINST 0
#endif
@end

@block fa_inst_out
#if FA_NINST > 0
#define FA_INST_OUT
flat out vec4 fa_inst_v0;
#if FA_NINST > 1
flat out vec4 fa_inst_v1;
#endif
#if FA_NINST > 2
flat out vec4 fa_inst_v2;
#endif
#endif
@end

@block fa_inst_in
#if FA_NINST > 0
flat in vec4 fa_inst_v0;
#if FA_NINST > 1
flat in vec4 fa_inst_v1;
#endif
#if FA_NINST > 2
flat in vec4 fa_inst_v2;
#endif
#endif
@end

// The vertex attributes of the instance data and the declared channels; the vertex shader defines FA_X_BASE first and calls
// fa_inst_begin() before anything reads the params, vertex_uv1 or vertex_color1.
@block fa_extra_attrs
#if FA_NINST > 0
layout(location=FA_X_BASE) in vec4 fa_inst_d0;
#endif
#if FA_NINST > 1
layout(location=FA_X_BASE+1) in vec4 fa_inst_d1;
#endif
#if FA_NINST > 2
layout(location=FA_X_BASE+2) in vec4 fa_inst_d2;
#endif
// The engine's own mesh program (mesh.glsl's fa_user defines FA_LM_BUILTIN, and only the `vs` program defines FA_LM_PASS) always reads
// the uv1 buffer: the lightmap UV of a lightmapped entity, zeros otherwise. A custom material that declares "uv1" reads the same buffer
// (its uv1 is the lightmap UV on a lightmapped entity).
#if defined(FA_CH_UV1) || (defined(FA_LM_BUILTIN) && defined(FA_LM_PASS))
#define FA_LM_ATTR
layout(location=FA_X_BASE+FA_NINST) in vec2 fa_attr_uv1;
#define FA_NUV1 1
#else
#define FA_NUV1 0
#endif
#ifdef FA_CH_COLOR1
layout(location=FA_X_BASE+FA_NINST+FA_NUV1) in vec4 fa_attr_color1;
#endif

void fa_inst_begin() {
#if FA_NINST == 1
    fa_instance_unpack(fa_inst_d0, vec4(0.0), vec4(0.0));
#elif FA_NINST == 2
    fa_instance_unpack(fa_inst_d0, fa_inst_d1, vec4(0.0));
#elif FA_NINST == 3
    fa_instance_unpack(fa_inst_d0, fa_inst_d1, fa_inst_d2);
#endif
#ifdef FA_INST_OUT
    fa_inst_v0 = fa_inst_d0;
#if FA_NINST > 1
    fa_inst_v1 = fa_inst_d1;
#endif
#if FA_NINST > 2
    fa_inst_v2 = fa_inst_d2;
#endif
#endif
#ifdef FA_CH_UV1
    vertex_uv1 = fa_attr_uv1;
#endif
#ifdef FA_CH_COLOR1
    vertex_color1 = fa_attr_color1;
#endif
}
@end

@block fa_vs_common
layout(binding=0) uniform fa_mesh_vs_params {
    mat4 fa_view_proj;
    mat4 fa_light_vp;           // the matrix of the shadow pass being drawn (a cascade of the sun; the view matrix in the prepass)
    vec4 fa_uv_scale;           // xy
    vec4 fa_time;               // x = seconds of game time since the scene started
    vec4 fa_lm_so;              // the lightmap rectangle of the entity drawn: page uv = lightmap uv * xy + zw; x = 0 = not lightmapped
};

// Drawing from a storage buffer (M72.4): a material with "buffers" defines FA_BUFFER_INST. Its entity is drawn as
// MeshRenderer.instances GPU instances, so the model matrix is one value per draw, a uniform block (binding 6,
// kMeshInstanceBaseUniform in fa/tooling/shaders.h), not the per-instance vertex buffer (which holds one matrix and would be
// read past its end); vertex() finds its instance in fa_instance_index (0 .. instances - 1).
#define fa_instance_index gl_InstanceIndex
#ifdef FA_BUFFER_INST
layout(binding=6) uniform fa_inst_base {
    mat4 fa_base_model;
};
#define FA_INST_MODEL fa_base_model
#else
#define FA_INST_MODEL mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3)
#endif
@include_block fa_inst_flags
@include_block fa_types
@include_block fa_user

// World space from the model matrix: the VertexData vertex() receives.
VertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color) {
    VertexData v;
    v.world_pos = (model * vec4(position, 1.0)).xyz;
    // Normal matrix = cofactor matrix of the upper 3x3 (inverse transpose up to a positive scale), so one
    // 64-byte matrix per instance is enough. s flips the handedness of mirrored instances.
    vec3 c0 = model[0].xyz;
    vec3 c1 = model[1].xyz;
    vec3 c2 = model[2].xyz;
    float s = dot(c0, cross(c1, c2)) < 0.0 ? -1.0 : 1.0;
    v.world_normal = (cross(c1, c2) * normal.x + cross(c2, c0) * normal.y + cross(c0, c1) * normal.z) * s;
    v.world_tangent = vec4(c0 * tangent.x + c1 * tangent.y + c2 * tangent.z, tangent.w * s);
    v.uv = texcoord0 * fa_uv_scale.xy;
    v.color = color;
    v.object_pos = position;
    return v;
}
@end

// The palette is 64 joints of 3 rows (a 3x4 matrix as three vec4 rows).
@block fa_skin_common
layout(binding=3) uniform fa_skin {
    vec4 fa_joint_rows[192];    // joint j: rows 3j .. 3j+2 of its skinning matrix
};

// The blend of up to four joint matrices (joint indices are bytes, normalized: x255).
mat4 fa_skin_matrix(vec4 joints, vec4 weights) {
    vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0);
    for (int i = 0; i < 4; ++i) {
        int j = int(joints[i] * 255.0 + 0.5) * 3;
        float w = weights[i];
        r0 += fa_joint_rows[j] * w;
        r1 += fa_joint_rows[j + 1] * w;
        r2 += fa_joint_rows[j + 2] * w;
    }
    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0),
                vec4(r0.w, r1.w, r2.w, 1.0));
}
@end

@block fa_mesh_vs
@include_block fa_inst_out
out vec3 fa_world_pos;
out vec3 fa_world_normal;
out vec4 fa_world_tangent;
out vec2 fa_uv;
out vec4 fa_vertex_color;
out vec3 fa_lm;                 // xy = the page uv of the lightmap, z = 1 when the entity is lightmapped (fa_lm_so.x > 0); last, as fa_lm of the fragment stage

// Everything after the model matrix is known: shared by the instanced and the skinned vertex shader.
void fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color) {
    VertexData v = fa_vertex_data(model, position, normal, tangent, texcoord0, color);
#ifdef FA_HAS_VERTEX
    vertex(v);
#endif
    vec4 wp = vec4(v.world_pos, 1.0);
    fa_world_pos = v.world_pos;
    fa_world_normal = v.world_normal;
    fa_world_tangent = v.world_tangent;
    fa_uv = v.uv;
    fa_vertex_color = v.color;
    gl_Position = fa_view_proj * wp;
}
@end

@vs vs
@include_block fa_vs_common
@include_block fa_mesh_vs
layout(location=0) in vec3 fa_position;
layout(location=1) in vec3 fa_normal;
layout(location=2) in vec2 fa_texcoord0;
layout(location=3) in vec4 fa_tangent;     // xyz tangent, w = handedness (+1 / -1)
layout(location=4) in vec4 fa_color;       // vertex color, normalized bytes (white without)
layout(location=5) in vec4 fa_inst_m0;     // per-instance model matrix, one column each
layout(location=6) in vec4 fa_inst_m1;
layout(location=7) in vec4 fa_inst_m2;
layout(location=8) in vec4 fa_inst_m3;
#define FA_X_BASE 9
#define FA_LM_PASS
@include_block fa_extra_attrs

void main() {
    fa_inst_begin();
    fa_shade_vertex(FA_INST_MODEL, fa_position, fa_normal, fa_tangent, fa_texcoord0, fa_color);
#ifdef FA_LM_ATTR
    fa_lm = vec3(fa_attr_uv1 * fa_lm_so.xy + fa_lm_so.zw, fa_lm_so.x > 0.0 ? 1.0 : 0.0);
#else
    fa_lm = vec3(0.0);
#endif
}
@end

// Skinned variant: the same outputs (so the same fragment shader), with the model matrix of the (single) instance
// times the joint blend.
@vs vs_skin
@include_block fa_vs_common
@include_block fa_skin_common
@include_block fa_mesh_vs
layout(location=0) in vec3 fa_position;
layout(location=1) in vec3 fa_normal;
layout(location=2) in vec2 fa_texcoord0;
layout(location=3) in vec4 fa_tangent;
layout(location=4) in vec4 fa_color;
layout(location=5) in vec4 fa_inst_m0;
layout(location=6) in vec4 fa_inst_m1;
layout(location=7) in vec4 fa_inst_m2;
layout(location=8) in vec4 fa_inst_m3;
layout(location=9) in vec4 fa_joints;
layout(location=10) in vec4 fa_weights;
#define FA_X_BASE 11
@include_block fa_extra_attrs

void main() {
    fa_inst_begin();
    fa_shade_vertex(FA_INST_MODEL * fa_skin_matrix(fa_joints, fa_weights),
                    fa_position, fa_normal, fa_tangent, fa_texcoord0, fa_color);
    fa_lm = vec3(0.0);  // a skinned mesh is never lightmapped
}
@end

// The fragment resources, up to the types of the contract (fa_fs_head), then the snippet and the standard surface
// (fa_fs_rest). Blocks must be defined before they are included, so the order below is the order of use: the shadow and prepass
// fragment shaders of an alphaMode "clip" material include fa_fs_surface = head + fa_fs_nolight + snippet + rest (they must run
// surface() to know what to discard); the main fragment shader includes fa_fs_head, fa_fs_light (the lights, the shadow and
// the sky), the snippet and fa_fs_rest, so the snippet's light(), ambient() and lighting() see the lights.
@block fa_fs_head
layout(binding=0) uniform texture2D fa_tex;             // base color
layout(binding=1) uniform texture2D fa_shadow_tex;
layout(binding=2) uniform texture2D fa_normal_tex;      // tangent-space normal map
layout(binding=3) uniform texture2D fa_mr_tex;          // glTF metallicRoughnessTexture: g = roughness, b = metallic
layout(binding=4) uniform texture2D fa_occlusion_tex;   // r = ambient occlusion
layout(binding=5) uniform texture2D fa_emissive_tex;
layout(binding=0) uniform sampler fa_smp;
layout(binding=1) uniform sampler fa_shadow_smp;
@image_sample_type fa_shadow_tex unfilterable_float
@sampler_type fa_shadow_smp nonfiltering
// What fa_shadow_sun (shadow_common.glsl) samples; the full-shader template names its own shadow map differently.
#define FA_SHADOW_TEX fa_shadow_tex
#define FA_SHADOW_SMP fa_shadow_smp
// The light data texture (light_data.glsl; view 24), read with texelFetch through the shadow map's nearest sampler.
layout(binding=24) uniform texture2D fa_light_tex;
@image_sample_type fa_light_tex unfilterable_float
#define FA_LIGHT_TEX fa_light_tex
#define FA_LIGHT_SMP fa_shadow_smp
// The light atlas (light_data.glsl, src/light_atlas.h; view 25): the LTC tables of the area lights, the light cookies and the IES
// profiles in one RGBA16F image, read bilinearly through the sky's linear clamp sampler (10, declared below). While no light needs it
// the renderer binds the 1 x 1 white texture and the shader never reads it.
layout(binding=25) uniform texture2D fa_light_atlas;
#define FA_ATLAS_TEX fa_light_atlas
#define FA_ATLAS_SMP fa_env_smp
// The decal atlas (light_data.glsl, block fa_decals; view 27): the albedo and normal textures of the Decal components, RGBA8 with mips,
// read with textureLod through the linear clamped sampler 10. Bound with the main pass's other views (a white image while the view has no
// decals, which no fragment then reads).
layout(binding=27) uniform texture2D fa_decal_tex;
#define FA_DECAL_TEX fa_decal_tex
#define FA_DECAL_SMP fa_env_smp
// The sky of a sky material (SceneSettings.skyMaterial), baked by the renderer (renderer_env.h): a cube, view 14, sampler 10 (after the
// material's textures and their vertex-stage copies), whose mips 0..4 are the sky prefiltered by roughness and whose mip 5 holds the sky's
// nine spherical-harmonics coefficients, the source of the diffuse ambient (fa_ambient_light); bound and used only while fa_env_sky.w is
// 1 (2: the cube is RGBA8 and the coefficients are stored as c / 8 + 0.5).
layout(binding=14) uniform textureCube fa_env_tex;
layout(binding=10) uniform sampler fa_env_smp;
// The screen slot (view 28, read with texelFetch through the nearest sampler 1; M73.2c): in the opaque phase the prepass image (r = linear
// view depth, a = 1 on an opaque mesh), the source of the contact shadows. Bound by every draw (a white image when none takes contact
// shadows, which no fragment then reads); M73.6b binds the opaque colour here for the transmissive draws, which have no contact shadows.
layout(binding=28) uniform texture2D fa_screen_tex;
@image_sample_type fa_screen_tex unfilterable_float

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
    vec4 fa_env_sky;            // rgb sky color (top of the environment); w = 1 when the baked environment of a sky material is bound
    vec4 fa_env_horizon;        // rgb horizon color; w = the highest mip of fa_env_tex (what roughness 1 reads)
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
    // Contact shadows (M73.2c; light_loop.glsl, block fa_contact). A draw that takes none has fa_ct_a.x = 0 and the rest is not read.
    vec4 fa_ct_a;               // x = 1 when this draw takes contact shadows (an opaque mesh that receives shadows, view 28 holds the prepass),
                                // y = 1 when images are bottom-up (OpenGL), zw = the prepass's size in pixels
    vec4 fa_ct_b;               // x = the camera distance where the contact shadows are gone (they fade over its last half)
    vec4 fa_ct_vpx;             // row 0 of the view-projection matrix: clip x of a world position
    vec4 fa_ct_vpy;             // row 1: clip y
    vec4 fa_ct_vpw;             // row 3: clip w
    vec4 fa_ct_fwd;             // xyz = the camera's forward axis, w = -dot(forward, position): depth = dot(xyz, world) + w
    vec4 fa_probe_sh[9];        // baked light probes (M73.4d) of a mesh without a lightmap: coefficient k of the SH in [k].xyz (the order of
                                // ShL2), [0].w = the coverage (0 = no probe reaches the mesh: the sky's ambient, nothing else changes)
};

// The varyings are declared in the order of the vertex stage's outputs (the instance values first): sokol-shdc matches them
// by that order.
@include_block fa_inst_flags
@include_block fa_inst_in
in vec3 fa_world_pos;
in vec3 fa_world_normal;
in vec4 fa_world_tangent;
in vec2 fa_uv;
in vec4 fa_vertex_color;

@include_block fa_types
@end

@block fa_fs_rest
// Loads the instanced params the vertex stage passed on into the globals the generator declared (surface() reads them).
void fa_inst_load() {
#if FA_NINST == 1
    fa_instance_unpack(fa_inst_v0, vec4(0.0), vec4(0.0));
#elif FA_NINST == 2
    fa_instance_unpack(fa_inst_v0, fa_inst_v1, vec4(0.0));
#elif FA_NINST == 3
    fa_instance_unpack(fa_inst_v0, fa_inst_v1, fa_inst_v2);
#endif
}

// The sRGB transfer functions (the CPU side is engine/render/src/color_space.h) and the fix of one texture sample: 0 = as
// sampled, 1 = sRGB-encoded values -> linear (a colour texture the GPU did not decode), 2 = linear -> sRGB-encoded (a data
// texture the GPU decoded as sRGB, or any texture in a gamma scene).
vec3 fa_srgb_to_linear(vec3 c) {
    c = max(c, vec3(0.0));
    return mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045)));
}
vec3 fa_linear_to_srgb(vec3 c) {
    c = max(c, vec3(0.0));
    return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, c * 12.92, step(c, vec3(0.0031308)));
}
vec3 fa_tex_fix(vec3 c, float mode) {
    // Explicit branches on a uniform: a gamma scene (mode 0) skips both pow() blocks instead of computing and discarding them.
    if (mode > 1.5) {
        c = fa_linear_to_srgb(c);
    } else if (mode > 0.5) {
        c = fa_srgb_to_linear(c);
    }
    return c;
}
float fa_fix_of(float packed, float scale) { return mod(floor(packed / scale + 0.01), 4.0); }

// What a MeshRenderer without a material draws: texture * color, normal map, metallic/roughness maps, occlusion,
// emissive. surface() starts from it.
Surface fa_standard_surface(in SurfaceInput i) {
    Surface s;
    vec4 base_t = texture(sampler2D(fa_tex, fa_smp), i.uv);
    base_t.rgb = fa_tex_fix(base_t.rgb, fa_fix_of(fa_maps.w, 1.0));
    vec4 albedo4 = base_t * fa_base_color * i.vertex_color;
    s.albedo = albedo4.rgb;
    s.alpha = albedo4.a;
    s.normal = i.world_normal;
    if (fa_maps.z > 0.5) {
        vec3 m = fa_tex_fix(texture(sampler2D(fa_normal_tex, fa_smp), i.uv).xyz, fa_fix_of(fa_maps.w, 16.0)) * 2.0 - 1.0;
        m.xy *= fa_maps.x;
        s.normal = fa_tangent_normal(i, m);
    }
    vec4 mrt = texture(sampler2D(fa_mr_tex, fa_smp), i.uv);
    mrt.rgb = fa_tex_fix(mrt.rgb, fa_fix_of(fa_maps.w, 64.0));
    s.metallic = clamp(fa_pbr.x * mrt.b, 0.0, 1.0);
    s.roughness = clamp(fa_pbr.y * mrt.g, 0.05, 1.0);
    vec4 occ_t = texture(sampler2D(fa_occlusion_tex, fa_smp), i.uv);
    vec3 occ_f = fa_tex_fix(occ_t.rgb, fa_fix_of(fa_maps.w, 256.0));
    s.occlusion = 1.0 + fa_maps.y * (occ_f.r - 1.0);
    s.emission = fa_emissive.rgb + fa_model_emissive.rgb * fa_tex_fix(texture(sampler2D(fa_emissive_tex, fa_smp), i.uv).rgb, fa_fix_of(fa_maps.w, 4.0));
    // The material layers: the factors of the MeshRenderer / glTF material, times the textures the importer packed into the maps.
    s.clearcoat = fa_layers_a.x;
    s.clearcoat_roughness = fa_layers_a.y;
    s.anisotropy = fa_layers_a.z;
    s.anisotropy_rotation = fa_layers_a.w;
    s.sheen_color = fa_layers_b.rgb;
    s.sheen_roughness = fa_layers_b.w;
    s.specular = fa_layers_c.x;
    s.ior = fa_layers_c.y;
    s.specular_color = fa_layers_d.rgb;
    float packed_maps = fa_layers_c.z;
    if (packed_maps > 0.5) {
        if (mod(packed_maps, 2.0) > 0.5) {
            s.clearcoat *= occ_f.g;
            s.clearcoat_roughness *= occ_f.b;
            s.sheen_roughness *= occ_t.a;
        }
        if (packed_maps > 1.5) {
            s.anisotropy *= mrt.r;
            s.specular *= mrt.a;
        }
    }
    return s;
}
@end

// The sky the surface reflects, shared with the full-shader template (mesh_full_common.glsl includes this block after it has
// declared fa_env_sky and fa_env_horizon).
@block fa_env_funcs
@include_block fa_sh
// The environment the surface reflects. With a sky material (fa_env_sky.w = 1) it is the sky the material draws, baked into a cube whose
// mips are prefiltered by roughness: roughness 0 reads mip 0, roughness 1 the last. Without one it is the gradient of skyColor and
// horizonColor (the horizon color, darker, below the horizon), rougher surfaces seeing a blurrier, flatter version of it (a cheap
// stand-in for a prefiltered cubemap).
vec3 fa_environment(vec3 d, float rough) {
    if (fa_env_sky.w > 0.5) {
        return textureLod(samplerCube(fa_env_tex, fa_env_smp), d, clamp(rough, 0.0, 1.0) * fa_env_horizon.w).rgb;
    }
    float blur = rough * rough;
    float h = clamp(d.y * (1.0 - 0.7 * blur), 0.0, 1.0);
    vec3 up = mix(fa_env_horizon.rgb, fa_env_sky.rgb, pow(h, 0.55));
    vec3 down = fa_env_horizon.rgb * 0.55;
    float k = smoothstep(-0.05 - 0.6 * blur, 0.05 + 0.6 * blur, d.y);
    vec3 e = mix(down, up, k);
    return mix(e, 0.5 * (fa_env_sky.rgb + fa_env_horizon.rgb) * 0.8, blur * 0.6);
}

// Coefficient k (0..8, the order of ShL2) of the sky's spherical harmonics: the texel (k & 3, k >> 2) of the face +X of mip 5 of the baked
// cube (renderer_env.h, env.glsl fs_sh), read at the exact centre of the texel (the direction (1, y, z) of a texel centre is on the +X face
// at (s, t) = ((c + 0.5) / 4, (r + 0.5) / 4)), so no filtering touches it.
vec3 fa_sky_sh_coef(int k) {
    vec3 d = vec3(1.0, 1.0 - float(2 * (k >> 2) + 1) * 0.25, 1.0 - float(2 * (k & 3) + 1) * 0.25);
    vec3 v = textureLod(samplerCube(fa_env_tex, fa_env_smp), d, 5.0).rgb;
    if (fa_env_sky.w > 1.5) { v = (v - 0.5) * 8.0; }
    return v;
}

// The ambient light a surface facing n receives: SceneSettings.ambientLight, or with a sky material (and with a physical sky or an HDRI
// environment) the light of that sky toward n: its radiance as nine spherical-harmonics coefficients (L2), convolved with the clamped
// cosine and divided by pi (fa_sh_eval), which replaces ambientLight. A sky of one color gives that color from every side; a sky with a
// bright sun or a bright horizon is smooth (three bands) and never negative. The same value the `ambient()` hook of a custom material
// receives as `ambientColor` (fa_indirect_diffuse: on a lightmapped surface the baked texel takes its place).
vec3 fa_ambient_light(vec3 n) {
    if (fa_env_sky.w > 0.5) {
        vec3 c[9];
        for (int k = 0; k < 9; ++k) { c[k] = fa_sky_sh_coef(k); }
        return fa_sh_eval(c, n);
    }
    return fa_ambient.rgb;
}

// Analytic split-sum environment BRDF (Karis, "Physically Based Shading on Mobile"): scale and bias of F0.
vec2 fa_env_brdf(float rough, float ndv) {
    vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
    vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
    vec4 r = rough * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * ndv)) * r.x + r.y;
    return vec2(-1.04, 1.04) * a004 + r.zw;
}

// Image-based lighting: the sky reflected in a surface with normal n seen from direction v (surface -> eye), weighted by the
// environment BRDF. f0 is the reflectance at normal incidence (0.04 for a dielectric, the albedo for a metal).
vec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness) {
    float ndv = max(dot(n, v), 1e-4);
    vec3 r = reflect(-v, n);
    vec2 ab = fa_env_brdf(roughness, ndv);
    return fa_environment(r, roughness) * (f0 * ab.x + ab.y);
}
@end

// What a "custom" material's helpers may call in every fragment program, not only the main one: the shadow and prepass fragment
// shaders (fa_fs_surface) also compile the snippet, whose light(), ambient(), lighting() and helpers are never run there. The sky
// functions are real, the light functions answer "no lights" so the snippet compiles.
@block fa_light_shared
#ifdef FA_CUSTOM_LIGHT
// A sample that lights nothing (what a light number outside the range gives).
LightSample fa_no_light() {
    LightSample none;
    none.direction = vec3(0.0, 1.0, 0.0);
    none.color = vec3(0.0);
    none.attenuation = 0.0;
    none.shadow = 1.0;
    none.distance = 0.0;
    none.type = 0;
    return none;
}
// What the engine's own lighting adds for the sky: its reflection weighted by the environment BRDF of this surface (s.metallic,
// s.roughness, s.albedo, s.normal) times s.occlusion, with the material layers (clear coat, sheen, anisotropy, specular and ior of
// the Surface) when they are set.
vec3 fa_sky_light(in SurfaceInput i, in Surface s) {
    float metallic = clamp(s.metallic, 0.0, 1.0);
    float roughness = clamp(s.roughness, 0.05, 1.0);
    vec3 f0 = mix(vec3(0.04), s.albedo, metallic);
    vec3 n = normalize(s.normal);
    FaLayers lay = fa_layers_setup(i, s, n, i.view_dir, metallic, roughness, f0);
    if (lay.on) { return fa_layers_ibl(lay, n, i.view_dir, f0, roughness) * s.occlusion; }
    return fa_sky_reflection(n, i.view_dir, f0, roughness) * s.occlusion;
}
#endif
@end

// What only the main fragment shader has (the snippet's light(), ambient() and lighting() call these, so the block comes before
// the snippet): the light array (light_data.glsl), the shadow coordinate and lookup (shadow_common.glsl), the sky, and the light
// samples and the custom-light hooks (light_loop.glsl).
@block fa_fs_light
// The lightmap varying of the vertex stage (M73.4a, declared last there too: the varyings of the two stages match by order). Declared
// here, before the light functions, because a baked light is skipped on a lightmapped fragment (fa_light_baked, light_data.glsl).
in vec3 fa_lm;
@include_block fa_cube_face
@include_block fa_light_data
@include_block fa_decals

const float FA_PI = 3.14159265;

@include_block fa_shadow_common

// The directional shadow of the fragment: 1 lit, 0 in shadow (the cascaded shadow of shadow_common.glsl at the fragment's world position).
float fa_shadow_factor(vec3 n, vec3 l) {
    return fa_shadow_sun(fa_world_pos, n, l);
}

@include_block fa_env_funcs
@include_block fa_layers_env
@include_block fa_layers_light
@include_block fa_light_shared
@include_block fa_contact
@include_block fa_light_hooks
@include_block fa_ltc
@include_block fa_area_light
@end

@block fa_fs_nolight
#ifdef FA_CUSTOM_LIGHT
@include_block fa_env_funcs
@include_block fa_layers_env
@include_block fa_light_shared
@include_block fa_light_hooks_none
#endif
@end

@block fa_fs_surface
@include_block fa_fs_head
@include_block fa_fs_nolight
@include_block fa_user
@include_block fa_fs_rest
@end

// The body of the main fragment shader, shared by `fs` and by `fs_sss` (the subsurface variant, which defines FA_SSS first, M73.5).
@block fa_fs_main
@include_block fa_fs_head
@include_block fa_fs_light
@include_block fa_user
@include_block fa_fs_rest

// The baked lightmap (M73.4a): the page of the entity drawn, an irradiance/pi texel like ambientLight is, read at the lightmap UV the
// vertex stage passed (fa_lm, declared in fa_fs_light). Bound (a white texel) on every draw of the engine's program, so a mesh without
// a lightmap costs one branch on a varying.
layout(binding=26) uniform texture2D fa_lightmap;

// The diffuse indirect light toward n: the baked texel of a lightmapped surface, else the ambient light or the sky's irradiance. It
// replaces fa_ambient_light in every diffuse ambient term, with or without material layers (the layers' base_scale darkens it as it does
// the ambient light). The specular IBL (fa_sky_reflection, fa_layers_ibl) is not part of it and stays the sky's: a lightmap holds no
// direction, so the ambient is never counted twice (the texel replaces the diffuse ambient only) and never missing.
vec3 fa_indirect_diffuse(vec3 n) {
    if (fa_lm.z > 0.5) {
        return textureLod(sampler2D(fa_lightmap, fa_env_smp), fa_lm.xy, 0.0).rgb;
    }
    float cover = fa_probe_sh[0].w;
    if (cover > 0.0) {
        // Baked light probes (M73.4d): a mesh without a lightmap reads the SH its position got on the CPU, blended into the sky's
        // ambient where the probes only partly reach it.
        vec3 c[9];
        for (int k = 0; k < 9; k++) { c[k] = fa_probe_sh[k].xyz; }
        return mix(fa_ambient_light(n), fa_sh_eval(c, n), clamp(cover, 0.0, 1.0));
    }
    return fa_ambient_light(n);
}

#ifdef FA_SSS
// The subsurface variant (M73.5, docs/design/ARCHITECTURE_SUBSURFACE.md): two outputs instead of the lit colour. Target 0: rgb = the DIFFUSE
// light the surface sends toward the camera (no specular, no sky reflection, no emission), a = the linear view depth of the fragment (what the
// prepass holds; 0 where the fragment does not scatter). Target 1: rgb = the scatter radius of each colour channel in metres, a = the strength,
// 0 where the fragment does not scatter (an unlit mesh, or a surface the camera does not see: the prepass is at view 28).
layout(binding=2) uniform fa_sss_params {
    vec4 fa_sss;                // rgb = radius in metres per colour channel (subsurfaceRadius * subsurfaceColor), a = subsurface (0..1)
};
layout(location=0) out vec4 fa_frag_color;
layout(location=1) out vec4 fa_sss_b;
#else
out vec4 fa_frag_color;
#endif

void main() {
    fa_inst_load();
    SurfaceInput i;
    i.world_pos = fa_world_pos;
    i.front_facing = gl_FrontFacing;
    i.world_normal = normalize(fa_world_normal);
    if (!i.front_facing) { i.world_normal = -i.world_normal; }
    i.world_tangent = fa_world_tangent;
    i.uv = fa_uv;
    i.vertex_color = fa_vertex_color;
    i.view_dir = normalize(fa_camera_pos.xyz - fa_world_pos);
    fa_cluster_begin(fa_world_pos);
    Surface s = fa_standard_surface(i);
    surface(i, s);
    // The projected decals of the cluster paint the surface before the lights see it (before the discard: it takes derivatives).
    fa_apply_decals(i.world_pos, i.world_normal, s.albedo, s.normal);
#ifdef FA_ALPHA_CLIP
    if (s.alpha < alphaCutoff) { discard; }
#endif

    vec3 result;
#ifdef FA_SSS
    float fa_sss_on = fa_sss.w;
    float fa_sss_depth = 0.0;
    {
        // Only the surface the camera sees scatters: the fragment's linear depth must be the prepass's at its pixel (view 28 holds it in this
        // pass), so a mesh behind another one, or behind a wall of the scene, leaves nothing in the image the blur reads.
        vec4 pv = vec4(i.world_pos, 1.0);
        float w = max(dot(fa_ct_vpw, pv), 1e-4);
        vec2 ndc = vec2(dot(fa_ct_vpx, pv), dot(fa_ct_vpy, pv)) / w;
        vec2 uv = vec2(ndc.x * 0.5 + 0.5, fa_ct_a.y > 0.5 ? ndc.y * 0.5 + 0.5 : 0.5 - ndc.y * 0.5);
        ivec2 px = clamp(ivec2(uv * fa_ct_a.zw), ivec2(0), ivec2(fa_ct_a.zw) - 1);
        vec4 scene = texelFetch(sampler2D(fa_screen_tex, fa_shadow_smp), px, 0);
        fa_sss_depth = dot(fa_ct_fwd.xyz, i.world_pos) + fa_ct_fwd.w;
        if (scene.a < 0.5 || abs(fa_sss_depth - scene.r) > 0.02 + 0.01 * fa_sss_depth) { fa_sss_on = 0.0; }
    }
#endif
    if (fa_emissive.w > 0.5) {
#ifdef FA_SSS
        result = vec3(0.0);  // an unlit surface has no diffuse light to scatter
        fa_sss_on = 0.0;
#else
        result = s.albedo;
#endif
    } else {
        vec3 gn = i.world_normal;
        vec3 n = normalize(s.normal);
        vec3 v = i.view_dir;
#ifdef FA_HAS_LIGHTING
        // lighting "custom" with the snippet's lighting(): it writes the light loop and the ambient and sky terms itself.
        s.normal = n;
        vec3 lit = lighting(i, s);
#else
#ifdef FA_CUSTOM_LIGHT
        s.normal = n;
#ifdef FA_HAS_AMBIENT
        vec3 lit = ambient(i, s, fa_indirect_diffuse(n));
#else
        vec3 lit = fa_indirect_diffuse(n) * s.albedo * s.occlusion;
#endif
#else
        float metallic = clamp(s.metallic, 0.0, 1.0);
        float roughness = clamp(s.roughness, 0.05, 1.0);
        float alpha = roughness * roughness;
        float a2 = alpha * alpha;
        float ndv = max(dot(n, v), 1e-4);
        vec3 diffuse_color = s.albedo * (1.0 - metallic);
        vec3 f0 = mix(vec3(0.04), s.albedo, metallic);
        FaLayers lay = fa_layers_setup(i, s, n, v, metallic, roughness, f0);
        vec3 lit = fa_indirect_diffuse(n) * diffuse_color * s.occlusion;
        if (lay.on) { lit *= lay.base_scale; }
#endif
@include_block fa_light_loop
#if !defined(FA_CUSTOM_LIGHT) && !defined(FA_SSS)
        // Image-based lighting: the sky reflected, weighted by the environment BRDF (with the layers, fa_layers_ibl).
        if (lay.on) {
            lit += fa_layers_ibl(lay, n, v, f0, roughness) * s.occlusion;
        } else {
            lit += fa_sky_reflection(n, v, f0, roughness) * s.occlusion;
        }
#endif
#endif
        result = lit;
    }
#ifndef FA_SSS
    result += s.emission;
    result = fa_shadow_debug(result, i.world_pos);
#endif
    if (fa_fog.w > 0.0 || fa_fog_b.y > 0.0) {
        // The same formula as the fog of the post stack (fog.glsl): from fogStart along the view ray, the distance fog
        // (density * length)^2 plus the integral of the height density; the scene's own fog is the case start = 0, no height.
        vec3 rel = i.world_pos - fa_camera_pos.xyz;
        float dep = dot(rel, fa_fog_c.xyz);
        float dist = fa_fog_c.w > 0.5 ? dep : length(rel);
        float len = dist - fa_fog_b.x;
        if (len > 0.0) {
            float tau = fa_fog.w * len;
            tau *= tau;
            if (fa_fog_b.y > 0.0) {
                float py = i.world_pos.y;
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
#ifdef FA_SSS
            result *= 1.0 - clamp(f, 0.0, 1.0);  // the fog colour is not diffuse light of the surface: only what the fog lets through
#else
            result = mix(result, fa_fog.rgb, clamp(f, 0.0, 1.0));
#endif
        }
    }
#ifdef FA_SSS
    if (fa_sss_on <= 0.0) { result = vec3(0.0); fa_sss_depth = 0.0; }
    fa_frag_color = vec4(result, fa_sss_depth);
    fa_sss_b = vec4(fa_sss.rgb, fa_sss_on);
#else
    fa_frag_color = vec4(result, s.alpha);
#endif
}
@end

@fs fs
@include_block fa_fs_main
@end

// The subsurface variant of `fs` (only the engine's own mesh program has it: mesh.glsl, programs mesh_sss and mesh_skin_sss).
@fs fs_sss
#define FA_SSS
@include_block fa_fs_main
@end

// Depth-only pass for the directional shadow map. With FA_HAS_VERTEX the material's vertex() runs here too (a wave
// casts the shadow of the wave): normal, uv and tangent then follow the instance (or skin) attributes.
@vs shadow_vs
@include_block fa_vs_common
layout(location=0) in vec3 fa_position;
layout(location=1) in vec4 fa_inst_m0;
layout(location=2) in vec4 fa_inst_m1;
layout(location=3) in vec4 fa_inst_m2;
layout(location=4) in vec4 fa_inst_m3;
#if defined(FA_HAS_VERTEX) || defined(FA_ALPHA_CLIP)
layout(location=5) in vec3 fa_normal;
layout(location=6) in vec2 fa_texcoord0;
layout(location=7) in vec4 fa_tangent;
layout(location=8) in vec4 fa_color;
#ifdef FA_ALPHA_CLIP
@include_block fa_inst_out
#endif
#define FA_X_BASE 9
@include_block fa_extra_attrs
#endif
#ifdef FA_ALPHA_CLIP
out vec3 fa_world_pos;
out vec3 fa_world_normal;
out vec4 fa_world_tangent;
out vec2 fa_uv;
out vec4 fa_vertex_color;
#endif
void main() {
    mat4 model = FA_INST_MODEL;
#if defined(FA_HAS_VERTEX) || defined(FA_ALPHA_CLIP)
    fa_inst_begin();
    VertexData v = fa_vertex_data(model, fa_position, fa_normal, fa_tangent, fa_texcoord0, fa_color);
#ifdef FA_HAS_VERTEX
    vertex(v);
#endif
#ifdef FA_ALPHA_CLIP
    fa_world_pos = v.world_pos;
    fa_world_normal = v.world_normal;
    fa_world_tangent = v.world_tangent;
    fa_uv = v.uv;
    fa_vertex_color = v.color;
#endif
    gl_Position = fa_light_vp * vec4(v.world_pos, 1.0);
#else
    gl_Position = fa_light_vp * (model * vec4(fa_position, 1.0));
#endif
}
@end

@vs shadow_vs_skin
@include_block fa_vs_common
@include_block fa_skin_common
layout(location=0) in vec3 fa_position;
layout(location=1) in vec4 fa_inst_m0;
layout(location=2) in vec4 fa_inst_m1;
layout(location=3) in vec4 fa_inst_m2;
layout(location=4) in vec4 fa_inst_m3;
layout(location=5) in vec4 fa_joints;
layout(location=6) in vec4 fa_weights;
#if defined(FA_HAS_VERTEX) || defined(FA_ALPHA_CLIP)
layout(location=7) in vec3 fa_normal;
layout(location=8) in vec2 fa_texcoord0;
layout(location=9) in vec4 fa_tangent;
layout(location=10) in vec4 fa_color;
#ifdef FA_ALPHA_CLIP
@include_block fa_inst_out
#endif
#define FA_X_BASE 11
@include_block fa_extra_attrs
#endif
#ifdef FA_ALPHA_CLIP
out vec3 fa_world_pos;
out vec3 fa_world_normal;
out vec4 fa_world_tangent;
out vec2 fa_uv;
out vec4 fa_vertex_color;
#endif
void main() {
    mat4 model = FA_INST_MODEL * fa_skin_matrix(fa_joints, fa_weights);
#if defined(FA_HAS_VERTEX) || defined(FA_ALPHA_CLIP)
    fa_inst_begin();
    VertexData v = fa_vertex_data(model, fa_position, fa_normal, fa_tangent, fa_texcoord0, fa_color);
#ifdef FA_HAS_VERTEX
    vertex(v);
#endif
#ifdef FA_ALPHA_CLIP
    fa_world_pos = v.world_pos;
    fa_world_normal = v.world_normal;
    fa_world_tangent = v.world_tangent;
    fa_uv = v.uv;
    fa_vertex_color = v.color;
#endif
    gl_Position = fa_light_vp * vec4(v.world_pos, 1.0);
#else
    gl_Position = fa_light_vp * (model * vec4(fa_position, 1.0));
#endif
}
@end

// With alphaMode "clip" this also runs the material's surface() and discards below alphaCutoff, so the shadow has the
// cutout's holes; without it the pass writes depth only and none of the material is part of the program.
@fs shadow_fs
#ifdef FA_ALPHA_CLIP
@include_block fa_fs_surface
#endif
out vec4 fa_frag_color;
void main() {
#ifdef FA_ALPHA_CLIP
    fa_inst_load();
    SurfaceInput i;
    i.world_pos = fa_world_pos;
    i.front_facing = gl_FrontFacing;
    i.world_normal = normalize(fa_world_normal);
    if (!i.front_facing) { i.world_normal = -i.world_normal; }
    i.world_tangent = fa_world_tangent;
    i.uv = fa_uv;
    i.vertex_color = fa_vertex_color;
    i.view_dir = normalize(fa_camera_pos.xyz - fa_world_pos);
    Surface s = fa_standard_surface(i);
    surface(i, s);
    if (s.alpha < alphaCutoff) { discard; }
#endif
    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
}
@end

// ---- the depth and normal prepass (M71) ----
// Both vertex shaders have the attributes of the main program (vs, vs_skin), so the engine's mesh pipeline layout serves them.
// The vertex outputs of the prepass: what surface() reads (as the shadow programs of an alphaMode "clip" material), the linear view
// depth, and the rotation of the view matrix as three rows (the fragment shader turns the surface normal, which surface() may have
// changed, into view space; a varying that is the same at every vertex is exact after interpolation).
@block fa_prepass_vs
@include_block fa_inst_out
out vec3 fa_world_pos;
out vec3 fa_world_normal;
out vec4 fa_world_tangent;
out vec2 fa_uv;
out vec4 fa_vertex_color;
out float fa_pre_depth;
out vec3 fa_pre_r0;
out vec3 fa_pre_r1;
out vec3 fa_pre_r2;

void fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color) {
    VertexData v = fa_vertex_data(model, position, normal, tangent, texcoord0, color);
#ifdef FA_HAS_VERTEX
    vertex(v);
#endif
    mat4 view = fa_light_vp;
    vec4 wp = vec4(v.world_pos, 1.0);
    fa_world_pos = v.world_pos;
    fa_world_normal = v.world_normal;
    fa_world_tangent = v.world_tangent;
    fa_uv = v.uv;
    fa_vertex_color = v.color;
    // The camera looks down -z in view space: the depth is the distance along the view axis, positive in front.
    fa_pre_depth = -(view * wp).z;
    fa_pre_r0 = vec3(view[0].x, view[1].x, view[2].x);
    fa_pre_r1 = vec3(view[0].y, view[1].y, view[2].y);
    fa_pre_r2 = vec3(view[0].z, view[1].z, view[2].z);
    gl_Position = fa_view_proj * wp;
}
@end

@vs prepass_vs
@include_block fa_vs_common
@include_block fa_prepass_vs
layout(location=0) in vec3 fa_position;
layout(location=1) in vec3 fa_normal;
layout(location=2) in vec2 fa_texcoord0;
layout(location=3) in vec4 fa_tangent;
layout(location=4) in vec4 fa_color;
layout(location=5) in vec4 fa_inst_m0;
layout(location=6) in vec4 fa_inst_m1;
layout(location=7) in vec4 fa_inst_m2;
layout(location=8) in vec4 fa_inst_m3;
#define FA_X_BASE 9
@include_block fa_extra_attrs
void main() {
    fa_inst_begin();
    fa_prepass_vertex(FA_INST_MODEL, fa_position, fa_normal, fa_tangent, fa_texcoord0, fa_color);
}
@end

@vs prepass_vs_skin
@include_block fa_vs_common
@include_block fa_skin_common
@include_block fa_prepass_vs
layout(location=0) in vec3 fa_position;
layout(location=1) in vec3 fa_normal;
layout(location=2) in vec2 fa_texcoord0;
layout(location=3) in vec4 fa_tangent;
layout(location=4) in vec4 fa_color;
layout(location=5) in vec4 fa_inst_m0;
layout(location=6) in vec4 fa_inst_m1;
layout(location=7) in vec4 fa_inst_m2;
layout(location=8) in vec4 fa_inst_m3;
layout(location=9) in vec4 fa_joints;
layout(location=10) in vec4 fa_weights;
#define FA_X_BASE 11
@include_block fa_extra_attrs
void main() {
    fa_inst_begin();
    fa_prepass_vertex(FA_INST_MODEL * fa_skin_matrix(fa_joints, fa_weights), fa_position,
                      fa_normal, fa_tangent, fa_texcoord0, fa_color);
}
@end

// One texel per pixel of the prepass target (an RGBA float image, cleared to r = far, a = 0 where nothing is drawn):
//   r  the linear view depth in world units (the distance along the camera's axis, so the same for a perspective and an
//      orthographic camera and in every graphics API); far (60000) where nothing was drawn, and never more than that where
//      something was (clamped, so an RGBA16F fallback never stores Inf)
//   gb the surface normal in view space (x right, y up, z toward the camera), octahedral encoded in -1..1 (decode below); 0 0 where
//      nothing was drawn
//   a  1 where an opaque mesh was drawn, 0 where not: the truth about coverage (a drawn surface at 60000 or more has r = 60000 too)
// The normal is the one the main pass lights with (a normal map and surface() included); a cutout (alphaMode "clip") leaves holes.
@fs prepass_fs
@include_block fa_fs_surface
in float fa_pre_depth;
in vec3 fa_pre_r0;
in vec3 fa_pre_r1;
in vec3 fa_pre_r2;
out vec4 fa_frag_color;
void main() {
    fa_inst_load();
    SurfaceInput i;
    i.world_pos = fa_world_pos;
    i.front_facing = gl_FrontFacing;
    i.world_normal = normalize(fa_world_normal);
    if (!i.front_facing) { i.world_normal = -i.world_normal; }
    i.world_tangent = fa_world_tangent;
    i.uv = fa_uv;
    i.vertex_color = fa_vertex_color;
    i.view_dir = normalize(fa_camera_pos.xyz - fa_world_pos);
    Surface s = fa_standard_surface(i);
    surface(i, s);
#ifdef FA_ALPHA_CLIP
    if (s.alpha < alphaCutoff) { discard; }
#endif
    vec3 n = normalize(s.normal);
    vec3 nv = normalize(vec3(dot(fa_pre_r0, n), dot(fa_pre_r1, n), dot(fa_pre_r2, n)));
    // Octahedral encoding: the sphere folded onto the square -1..1 (decode: n = (e.x, e.y, 1 - |e.x| - |e.y|); where n.z < 0,
    // e = (1 - |e.yx|) * sign(e) first; normalize).
    vec2 e = nv.xy / (abs(nv.x) + abs(nv.y) + abs(nv.z));
    if (nv.z < 0.0) { e = (1.0 - abs(e.yx)) * vec2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0); }
    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);
}
@end
