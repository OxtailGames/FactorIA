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
    // Transmission and volume (M73.6b; glass, liquids): what the engine's own lighting reads; a "custom" lighting does not draw them.
    float transmission;         // 0..1: the share of the diffuse light that passes through the surface (and shows what is behind it); 0 = opaque
    float thickness;            // metres of the volume behind the surface: how far the light travels inside, bending it and tinting it
    vec3 attenuation_color;     // the colour the light has after travelling attenuation_distance inside the volume
    float attenuation_distance; // metres; 0 = the volume does not tint the light
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
#define FA_NCOL1 1
#else
#define FA_NCOL1 0
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
#ifdef FA_PREPASS_VS
// The motion vectors (M76-P1b): the prepass runs vertex() a second time for the previous frame, so what vertex() reads as fa_time
// is a copy that the prepass sets to the game time of that frame. fa_time_now() is the real uniform for the engine's own code.
vec4 fa_time_now() { return fa_time; }
vec4 fa_vtime = vec4(0.0);
#define fa_time fa_vtime
#endif
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

// The palette of the frame before for the motion vectors (M76-P1c), read by prepass_vs_skin only (vertex stage, view 29, sampler 11,
// read with texelFetch through a nearest sampler). One RGBA32F image of 1024-texel rows that holds a stream of texels: a joint is three
// texels (the three rows of its 3x4 matrix, as fa_skin), a palette is 64 joints (192 texels) and starts at texel `base` of the stream
// (fa_vel_on.w), so a skin of any joint count up to 64 fits and no uniform is used. `base` -> texel t is at (t & 1023, t >> 10).
@block fa_prev_palette
layout(binding=29) uniform texture2D fa_prev_pal_tex;
layout(binding=11) uniform sampler fa_prev_pal_smp;
@image_sample_type fa_prev_pal_tex unfilterable_float
@sampler_type fa_prev_pal_smp nonfiltering
vec4 fa_prev_pal_texel(int t) {
    return texelFetch(sampler2D(fa_prev_pal_tex, fa_prev_pal_smp), ivec2(t & 1023, t >> 10), 0);
}
mat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base) {
    vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0);
    for (int i = 0; i < 4; ++i) {
        int t = base + int(joints[i] * 255.0 + 0.5) * 3;
        float w = weights[i];
        r0 += fa_prev_pal_texel(t) * w;
        r1 += fa_prev_pal_texel(t + 1) * w;
        r2 += fa_prev_pal_texel(t + 2) * w;
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
// The probe atlas (M73-P3c; renderer_probes.h, docs/design/ARCHITECTURE_PROBES.md): one 2D image, view 14, sampler 10 (after the material's
// textures and their vertex-stage copies), that holds the sky (the tile at fa_atlas.zw, the sky material's prefiltered radiance and its nine
// spherical-harmonics coefficients, written by the renderer from the baked sky) and the tile of every ReflectionProbe, each an octahedral map
// with its levels of roughness and its SH row (probe.h). Bound whenever the sky or a probe exists (a white image otherwise, never read).
layout(binding=14) uniform texture2D fa_probe_atlas;
// This template knows the fragment's world position, so a probe's box corrects the reflection (the full-shader template does not).
#define FA_ENV_PARALLAX 1
layout(binding=10) uniform sampler fa_env_smp;
// The screen slot (view 28, read with texelFetch through the nearest sampler 1; M73.2c): in the opaque phase the prepass image (r = linear
// view depth, a = 1 on an opaque mesh), the source of the contact shadows. Bound by every draw (a white image when none takes contact
// shadows, which no fragment then reads). In the blended phase of a frame that has a transmissive draw it holds the refraction atlas instead
// (M73.6b, block fa_transmission of brdf_layers.glsl): the opaque picture of the camera's rectangle and its reduced copies, read by the
// transmissive draws, which have no contact shadows.
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
    // Contact shadows (M73.2c; light_loop.glsl, block fa_contact). A draw that takes none has fa_ct_a.x = 0 and the rest is not read.
    vec4 fa_ct_a;               // x = 1 when this draw takes contact shadows (an opaque mesh that receives shadows, view 28 holds the prepass),
                                // y = 1 when images are bottom-up (OpenGL), zw = the prepass's size in pixels
    vec4 fa_ct_b;               // x = the camera distance where the contact shadows are gone (they fade over its last half); y = 1 when view 28 holds
                                // the image of the ray traced shadows kernel and the sun's shadow of this draw is read from it (fa_shadow_factor);
                                // z = 1 when the scene has casters the rays do not see: the sun's shadow is then the darker of the mask and the cascades
                                // (and the traced lights' shadow the darker of the mask and their map), w = 1 when view 28 holds the ray traced
                                // visibility of up to three point, spot and area lights (fa_shadow_local_rt; M79-P2a-3)
    vec4 fa_ct_vpx;             // row 0 of the view-projection matrix: clip x of a world position
    vec4 fa_ct_vpy;             // row 1: clip y
    vec4 fa_ct_vpw;             // row 3: clip w
    vec4 fa_ct_fwd;             // xyz = the camera's forward axis, w = -dot(forward, position): depth = dot(xyz, world) + w
    // Transmission and volume (M73.6b; brdf_layers.glsl, block fa_transmission). fa_ct_vp*, fa_ct_a.yzw hold the camera's view of the frame
    // for a transmissive draw too (the atlas has the prepass's size, the camera's rectangle).
    vec4 fa_tr_a;               // x transmission, y thickness (metres), z attenuation distance (metres, 0 = no tint), w = how the draw is
                                // made: 0 not transmissive, 1 refracts the atlas bound at view 28, 2 a plain blend (no atlas),
                                // 3 as 1 and level 0 of the atlas also holds what the ray traced translucency saw (alpha 1 where it traced)
    vec4 fa_tr_b;               // rgb attenuation colour, w = the levels of the atlas (1 = the picture only)
    vec4 fa_probe_sh[9];        // baked light probes (M73.4d) of a mesh without a lightmap: coefficient k of the SH in [k].xyz (the order of
                                // ShL2), [0].w = the coverage (0 = no probe reaches the mesh: the sky's ambient, nothing else changes)
    // The reflection probes (M73-P3c; fa_env_funcs): the atlas and the up to two probes this draw reflects, chosen on the CPU from the
    // mesh's position (render_scene.cpp). The shares add up to at most 1, the rest is the sky; all zero = the sky alone.
    vec4 fa_atlas;              // x = the atlas' width in texels (the shader reads the size from the image), y = 1 when it is RGBA8 (its SH row is coded), zw = the sky's tile origin (texels)
    vec4 fa_rpa_tile;           // probe A: xy = its tile's origin in the atlas (texels), z = its resolution, w = its share of the light
    vec4 fa_rpa_pos;            // xyz = where it captured (world), w = 1 when its box corrects the reflection (box projection)
    vec4 fa_rpa_bx;             // its box: row i = how the unit box coordinate i grows with the world position (xyz) plus its offset (w);
    vec4 fa_rpa_by;             // the box is where all three are in [-1, 1]
    vec4 fa_rpa_bz;
    vec4 fa_rpb_tile;           // probe B, likewise
    vec4 fa_rpb_pos;
    vec4 fa_rpb_bx;
    vec4 fa_rpb_by;
    vec4 fa_rpb_bz;
    // The realtime GI grids (RealtimeGI; fa_gi_light below): their records are in the light data texture.
    vec4 fa_gi;                 // x = the first texel of the grid records (4 texels each), y = how many grids are ready (0 = none: nothing
                                // below runs), z = 1 when the draw belongs to a capture of the grid's own probes (the grid's light is times its bounce),
                                // w = the LOD cross-fade of the draw (fa_lod_dither): 0 = none, +a = the level fading in, -a = the level fading out
    vec4 fa_gi_px;              // x = 1 when view 26 (fa_lightmap) holds the per-pixel ray traced GI of the camera (M79-P4b-1; fa_indirect_diffuse reads it
                                // at the pixel the fragment's world position projects to, with the fa_ct_vp* rows and size), 0 = not; yzw = 0
};

// The texture LOD bias of the frame (M76-P4b, docs/UPSCALING.md "Texture mip bias"): negative while the temporal upscaler or the temporal
// antialiasing accumulates jittered frames, so the textures keep the detail of the accumulated picture; 0 everywhere else (an image drawn
// without them is the same bit for bit). The scene's texture reads add it: texture(sampler2D(t, t_smp), uv, fa_mip_bias). Fragment stage only.
#define fa_mip_bias (fa_env_horizon.w)

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

// The dithered cross-fade between two levels of detail (MeshRenderer.lodCrossFade, LodGroup.crossFade): the renderer draws both levels
// for a few frames, the one fading in with fa_gi.w = +a and the one fading out with -a (0 < a < 1). A screen-space pattern (interleaved
// gradient noise, no texture) picks the pixels: the level fading in keeps those where it is below a, the other those where it is not, so
// the two levels cover every pixel exactly once. A draw with fa_gi.w = 0 returns at once.
// Only the programs that already may discard have it: a program with FA_LOD_DITHER (the engine's own mesh and prepass programs a
// fading draw uses: mesh_lod, mesh_skin_lod, prepass_lod, prepass_skin_lod) and a material with alphaMode "clip" (FA_ALPHA_CLIP). The
// others (every draw that does not fade) have no discard at all, so a tile-based GPU keeps its early depth test and hidden surface
// removal for them.
#if defined(FA_LOD_DITHER) || defined(FA_ALPHA_CLIP)
void fa_lod_dither() {
    float a = fa_gi.w;
    if (a != 0.0) {
        highp float n = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715))));
        if (a > 0.0 ? n >= a : n < -a) { discard; }
    }
}
#endif
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
    vec4 base_t = texture(sampler2D(fa_tex, fa_smp), i.uv, fa_mip_bias);
    base_t.rgb = fa_tex_fix(base_t.rgb, fa_fix_of(fa_maps.w, 1.0));
    vec4 albedo4 = base_t * fa_base_color * i.vertex_color;
    s.albedo = albedo4.rgb;
    s.alpha = albedo4.a;
    s.normal = i.world_normal;
    if (fa_maps.z > 0.5) {
        vec3 m = fa_tex_fix(texture(sampler2D(fa_normal_tex, fa_smp), i.uv, fa_mip_bias).xyz, fa_fix_of(fa_maps.w, 16.0)) * 2.0 - 1.0;
        m.xy *= fa_maps.x;
        s.normal = fa_tangent_normal(i, m);
    }
    vec4 mrt = texture(sampler2D(fa_mr_tex, fa_smp), i.uv, fa_mip_bias);
    mrt.rgb = fa_tex_fix(mrt.rgb, fa_fix_of(fa_maps.w, 64.0));
    s.metallic = clamp(fa_pbr.x * mrt.b, 0.0, 1.0);
    s.roughness = clamp(fa_pbr.y * mrt.g, 0.05, 1.0);
    vec4 occ_t = texture(sampler2D(fa_occlusion_tex, fa_smp), i.uv, fa_mip_bias);
    vec3 occ_f = fa_tex_fix(occ_t.rgb, fa_fix_of(fa_maps.w, 256.0));
    s.occlusion = 1.0 + fa_maps.y * (occ_f.r - 1.0);
    s.emission = fa_emissive.rgb + fa_model_emissive.rgb * fa_tex_fix(texture(sampler2D(fa_emissive_tex, fa_smp), i.uv, fa_mip_bias).rgb, fa_fix_of(fa_maps.w, 4.0));
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
    s.transmission = fa_tr_a.x;
    s.thickness = fa_tr_a.y;
    s.attenuation_distance = fa_tr_a.z;
    s.attenuation_color = fa_tr_b.rgb;
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
// declared fa_env_sky, fa_env_horizon, fa_atlas and the probe parameters).
@block fa_env_funcs
@include_block fa_sh
// ---- the probe atlas (M73-P3c) ----
// Each map is octahedral (probe.cpp oct_encode, whose operations these are): the half of the sphere around +Y is the inner diamond, the
// other half the four corners, y down the image. A tile is laid out as probe_layout (probe.h) says: level 0 (resolution texels and a
// one-texel border all round) at the origin, level k >= 1 in a column to its right, the SH row last. Level k holds the scene convolved with
// the GGX lobe of roughness k / (levels - 1). The border holds the texel across the edge, so a bilinear tap at the edge of a level never
// reads a neighbour's texels.
vec2 fa_oct_encode(vec3 d) {
    float s = abs(d.x) + abs(d.y) + abs(d.z);
    vec3 p = d / max(s, 1.0e-12);
    vec2 e = vec2(p.x, p.z);
    if (p.y < 0.0) {
        e = vec2((1.0 - abs(p.z)) * (p.x < 0.0 ? -1.0 : 1.0), (1.0 - abs(p.x)) * (p.z < 0.0 ? -1.0 : 1.0));
    }
    return e;
}

// The atlas' size in texels, read from the image: it is square, or taller than wide while a RealtimeGI's band of blocks is in it (every lookup divides
// by this, never by a single number).
vec2 fa_atlas_size() {
    return vec2(textureSize(sampler2D(fa_probe_atlas, fa_env_smp), 0));
}

// Level `lv` (0, 1, ...) of the tile at `origin` with `res` texels per side, read in direction coordinate e.
vec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e) {
    float size = res / float(1 << lv);
    float lx = lv == 0 ? 0.0 : res + 2.0;
    float ly = lv == 0 ? 0.0 : res - res / float(1 << max(lv - 1, 0)) + 2.0 * float(lv - 1);  // (max: no negative shift in the branch not taken)
    vec2 px = origin + vec2(lx, ly) + vec2(1.0) + (e * 0.5 + vec2(0.5)) * size;
    return textureLod(sampler2D(fa_probe_atlas, fa_env_smp), px / fa_atlas_size(), 0.0).rgb;
}

// The light the tile sends toward direction d to a surface of the given roughness: the two nearest levels, blended.
vec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough) {
    float levels = res > 64.5 ? 5.0 : (res > 32.5 ? 4.0 : 3.0);
    float f = clamp(rough, 0.0, 1.0) * (levels - 1.0);
    int k = int(min(floor(f), levels - 2.0));
    float t = f - float(k);
    vec2 e = fa_oct_encode(d);
    vec3 a = fa_probe_level(origin, res, k, e);
    if (t < 0.002) { return a; }
    return mix(a, fa_probe_level(origin, res, k + 1, e), t);
}

// Coefficient k (0..8, the order of ShL2) of the tile's spherical harmonics: the texel k of its last row, read at its centre (no filtering).
vec3 fa_probe_sh_coef(vec2 origin, float res, int k) {
    vec2 px = origin + vec2(float(k) + 0.5, res + 2.5);
    vec3 v = textureLod(sampler2D(fa_probe_atlas, fa_env_smp), px / fa_atlas_size(), 0.0).rgb;
    if (fa_atlas.y > 0.5) { v = (v * 255.0 - 128.0) * (4.0 / 127.0); }  // RGBA8: clamp(c / 4, -1, 1) * 127 / 255 + 128 / 255 (0 is the byte 128)
    return v;
}

#ifdef FA_ENV_PARALLAX
// Box projection (parallax): the reflection ray from the surface point, followed to the probe's box and read from the probe's own position.
vec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz) {
    if (posw.w < 0.5) { return d; }
    vec3 pu = vec3(dot(bx.xyz, fa_world_pos) + bx.w, dot(by.xyz, fa_world_pos) + by.w, dot(bz.xyz, fa_world_pos) + bz.w);
    vec3 du = vec3(dot(bx.xyz, d), dot(by.xyz, d), dot(bz.xyz, d));
    float tx = du.x > 1.0e-6 ? (1.0 - pu.x) / du.x : (du.x < -1.0e-6 ? (-1.0 - pu.x) / du.x : 1.0e30);
    float ty = du.y > 1.0e-6 ? (1.0 - pu.y) / du.y : (du.y < -1.0e-6 ? (-1.0 - pu.y) / du.y : 1.0e30);
    float tz = du.z > 1.0e-6 ? (1.0 - pu.z) / du.z : (du.z < -1.0e-6 ? (-1.0 - pu.z) / du.z : 1.0e30);
    tx = tx > 0.0 ? tx : 1.0e30;
    ty = ty > 0.0 ? ty : 1.0e30;
    tz = tz > 0.0 ? tz : 1.0e30;
    float t = min(tx, min(ty, tz));
    if (t > 1.0e29) { return d; }
    vec3 r = fa_world_pos + d * t - posw.xyz;
    return dot(r, r) > 1.0e-10 ? normalize(r) : d;
}
#endif

// The light of the probe with tile `tile` toward d.
vec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, vec3 d, float rough) {
#ifdef FA_ENV_PARALLAX
    d = fa_probe_box_dir(d, posw, bx, by, bz);
#endif
    return fa_probe_radiance(tile.xy, tile.z, d, rough);
}

// The environment the surface reflects. The base is the sky: with a sky material (fa_env_sky.w = 1) its tile of the probe atlas, written
// from the sky the material draws and prefiltered by roughness (roughness 0 reads the first level, 1 the last); without one the gradient
// of skyColor and horizonColor (the horizon color, darker, below the horizon), rougher surfaces seeing a blurrier, flatter version of it
// (a cheap stand-in for a prefiltered cubemap). The reflection probes that reach the draw (at most two, with their shares, fa_rpa_tile.w
// and fa_rpb_tile.w; the sky keeps the rest) replace their share of it.
vec3 fa_environment(vec3 d, float rough) {
    float sa = fa_rpa_tile.w, sb = fa_rpb_tile.w;
    float sky = 1.0 - sa - sb;
    vec3 outc = vec3(0.0);
    if (sky > 0.0005) {
        vec3 base;
        if (fa_env_sky.w > 0.5) {
            base = fa_probe_radiance(fa_atlas.zw, 128.0, d, rough);
        } else {
            float blur = rough * rough;
            float h = clamp(d.y * (1.0 - 0.7 * blur), 0.0, 1.0);
            vec3 up = mix(fa_env_horizon.rgb, fa_env_sky.rgb, pow(h, 0.55));
            vec3 down = fa_env_horizon.rgb * 0.55;
            float k = smoothstep(-0.05 - 0.6 * blur, 0.05 + 0.6 * blur, d.y);
            vec3 e = mix(down, up, k);
            base = mix(e, 0.5 * (fa_env_sky.rgb + fa_env_horizon.rgb) * 0.8, blur * 0.6);
        }
        outc = base * sky;
    }
    if (sa > 0.0) { outc += fa_probe_environment(fa_rpa_tile, fa_rpa_pos, fa_rpa_bx, fa_rpa_by, fa_rpa_bz, d, rough) * sa; }
    if (sb > 0.0) { outc += fa_probe_environment(fa_rpb_tile, fa_rpb_pos, fa_rpb_bx, fa_rpb_by, fa_rpb_bz, d, rough) * sb; }
    return outc;
}

// The ambient light a surface facing n receives: SceneSettings.ambientLight, or with a sky material (and with a physical sky or an HDRI
// environment) the light of that sky toward n: its radiance as nine spherical-harmonics coefficients (L2, the SH row of the sky's tile),
// convolved with the clamped cosine and divided by pi (fa_sh_eval), which replaces ambientLight. A sky of one color gives that color
// from every side; a sky with a bright sun or a bright horizon is smooth (three bands) and never negative. A reflection probe that
// reaches the draw gives the SH row of its own tile for its share (the coefficients are blended, the light is one evaluation). The
// same value the `ambient()` hook of a custom material receives as `ambientColor` (fa_indirect_diffuse: a baked lightmap texel or the
// light probes of a covered fragment take its place).
vec3 fa_ambient_light(vec3 n) {
    float sa = fa_rpa_tile.w, sb = fa_rpb_tile.w;
    float sky = 1.0 - sa - sb;
    vec3 amb = vec3(0.0);
    bool tile = fa_env_sky.w > 0.5;
    vec3 c[9];
    for (int k = 0; k < 9; ++k) { c[k] = vec3(0.0); }
    if (sky > 0.0005) {
        if (tile) {
            for (int k = 0; k < 9; ++k) { c[k] = fa_probe_sh_coef(fa_atlas.zw, 128.0, k) * sky; }
        } else {
            amb = fa_ambient.rgb * sky;
        }
    }
    if (sa > 0.0) {
        for (int k = 0; k < 9; ++k) { c[k] += fa_probe_sh_coef(fa_rpa_tile.xy, fa_rpa_tile.z, k) * sa; }
    }
    if (sb > 0.0) {
        for (int k = 0; k < 9; ++k) { c[k] += fa_probe_sh_coef(fa_rpb_tile.xy, fa_rpb_tile.z, k) * sb; }
    }
    if (tile || sa > 0.0 || sb > 0.0) { amb += fa_sh_eval(c, n); }
    return amb;
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
    if (lay.on) { return fa_layers_ibl(lay, n, i.view_dir, f0, roughness, s.occlusion); }
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
//
// M79-P2a-1: with ray traced shadows (fa_ct_b.y = 1: an opaque mesh that receives shadows, view 28 holds the image of the shadow kernel) the sun's
// shadow is the kernel's visibility of this pixel (docs/design/ARCHITECTURE_RT_EFFECTS.md): the texel the fragment's world position projects to, read
// when it holds the same surface (its depth, in g, is the fragment's within what a pixel covers). Where it does not (the edge of a silhouette, a
// pixel the camera's jitter moved) the cascades answer, as they do for every draw that takes no mask.
// M79-P2a-2: casters the rays do not see (terrain, impostors, GPU-driven meshes, cutouts, instances over the cap...) are only in the cascades, so
// when the scene has any (fa_ct_b.z = 1) the shadow is the darker of the two: nothing loses its shadow, and a traced caster is shadowed by both
// with the cascades' resolution at its edge (the trade-off of "No caster loses its shadow").
float fa_shadow_factor(vec3 n, vec3 l) {
    if (fa_ct_b.y > 0.5 && fa_pbr.z > 0.5) {
        // fwidth needs the pixels of a 2x2 quad to run this together. It is called from the light loop, after a `continue` for a baked light
        // (fa_baked_keep) that a lightmapped or probe-lit fragment takes and its neighbour may not, so at the edge between two such objects the
        // derivative can be taken from a lane that left: a wrong slope there only widens or narrows this tolerance for one pixel, and the
        // fragment falls back to the cascades or takes the mask, both a valid shadow. Accepted rather than moving the call out of the light loop.
        // What a pixel covers of depth along this surface: a surface seen at a grazing angle changes depth fast from one pixel to the next, and
        // the sample of a multisampled fragment or of the jittered camera sits up to a pixel from the texel read, so the tolerance grows with it.
        float d = dot(fa_ct_fwd.xyz, fa_world_pos) + fa_ct_fwd.w;
        float slope = min(1.5 * fwidth(d), 0.1 * d);
        vec4 pv = vec4(fa_world_pos, 1.0);
        float w = dot(fa_ct_vpw, pv);
        if (w > 1e-4) {
            vec2 ndc = vec2(dot(fa_ct_vpx, pv), dot(fa_ct_vpy, pv)) / w;
            vec2 uv = vec2(ndc.x * 0.5 + 0.5, fa_ct_a.y > 0.5 ? ndc.y * 0.5 + 0.5 : 0.5 - ndc.y * 0.5);
            if (uv.x >= 0.0 && uv.x < 1.0 && uv.y >= 0.0 && uv.y < 1.0) {
                ivec2 px = clamp(ivec2(uv * fa_ct_a.zw), ivec2(0), ivec2(fa_ct_a.zw) - 1);
                vec4 rt = texelFetch(sampler2D(fa_screen_tex, fa_shadow_smp), px, 0);
                if (rt.a > 0.5 && abs(d - rt.r) <= 0.002 * d + 0.01 + slope) {
                    return fa_ct_b.z > 0.5 ? min(rt.g, fa_shadow_sun(fa_world_pos, n, l)) : rt.g;
                }
            }
        }
    }
    return fa_shadow_sun(fa_world_pos, n, l);
}

// M79-P2a-3: the shadow of a point, spot or area light. A light the renderer traced this frame (its texel of the shadow region has z = 1 + its slot,
// light_data.glsl) takes its visibility from the same image view 28 holds for the sun's: b packs the three traced lights as three bytes of one
// integer below 2^24 (light s: 255 v * 256^s), exact in a float, read here with floor and mod (no bit operations: legacy targets have none).
// The texel read is the fragment's own when it shows the same surface (its depth in r, the same test as the sun's); where it does not (the edge of a
// silhouette, a pixel the camera's jitter moved) the four texels around it are tried, and when none does the cascades' counterpart is the map when
// the scene has casters the rays do not see (fa_ct_b.z = 1: the maps were drawn, the answer is the darker of the two as for the sun) and "lit"
// otherwise (the maps of the traced lights were not drawn: nothing to fall back to, a texel at a silhouette's edge).
float fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l) {
    if (fa_ct_b.w > 0.5 && fa_pbr.z > 0.5 && fa_shadow_lcfg.x > 0.5) {
        float slot = fa_light_texel(int(fa_shadow_lcfg.x + 0.5) - 1 + li).z;
        if (slot > 0.5) {
            float d = dot(fa_ct_fwd.xyz, world) + fa_ct_fwd.w;
            float slope = min(1.5 * fwidth(d), 0.1 * d);
            vec4 pv = vec4(world, 1.0);
            float w = dot(fa_ct_vpw, pv);
            if (w > 1e-4) {
                vec2 ndc = vec2(dot(fa_ct_vpx, pv), dot(fa_ct_vpy, pv)) / w;
                vec2 uv = vec2(ndc.x * 0.5 + 0.5, fa_ct_a.y > 0.5 ? ndc.y * 0.5 + 0.5 : 0.5 - ndc.y * 0.5);
                if (uv.x >= 0.0 && uv.x < 1.0 && uv.y >= 0.0 && uv.y < 1.0) {
                    ivec2 size = ivec2(fa_ct_a.zw);
                    ivec2 px0 = clamp(ivec2(uv * fa_ct_a.zw), ivec2(0), size - 1);
                    for (int k = 0; k < 5; k++) {
                        ivec2 o = k == 0 ? ivec2(0, 0) : (k == 1 ? ivec2(1, 0) : (k == 2 ? ivec2(-1, 0) : (k == 3 ? ivec2(0, 1) : ivec2(0, -1))));
                        vec4 rt = texelFetch(sampler2D(fa_screen_tex, fa_shadow_smp), clamp(px0 + o, ivec2(0), size - 1), 0);
                        if (rt.a > 0.5 && abs(d - rt.r) <= 0.002 * d + 0.01 + slope) {
                            float div = slot < 1.5 ? 1.0 : (slot < 2.5 ? 256.0 : 65536.0);
                            float v = mod(floor(rt.b / div), 256.0) / 255.0;
                            return fa_ct_b.z > 0.5 ? min(v, fa_shadow_local(li, lpos, world, n, l)) : v;
                        }
                    }
                }
            }
            return fa_ct_b.z > 0.5 ? fa_shadow_local(li, lpos, world, n, l) : 1.0;
        }
    }
    return fa_shadow_local(li, lpos, world, n, l);
}

@include_block fa_env_funcs
@include_block fa_layers_env
@include_block fa_layers_light
@include_block fa_light_shared
@include_block fa_contact
@include_block fa_transmission
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

// ---- the realtime GI grids (RealtimeGI; docs/design/ARCHITECTURE_PROBES.md, "Realtime GI: the shading") ----
// The records of the ready grids are in the light data texture from texel fa_gi.x, four texels each (gi.h, gi_pack_record): [0] origin.xyz and
// spacing, [1] the probe counts per axis and their product, [2] the first block, blocks per band row, maxDistance and intensity, [3] bounce,
// backface tolerance and ready. A probe's block is in the band of the probe atlas under its 1024 square (10 x 11 texels): the depth map (the
// mean and the mean square of d / maxDistance, an octahedral map with a border), the nine coefficients of the SH of the light that reaches
// it, and the meta texel (the share of back faces hit, 1 once captured).
vec4 fa_gi_fetch(vec2 texel) {
    return textureLod(sampler2D(fa_probe_atlas, fa_env_smp), texel / fa_atlas_size(), 0.0);
}

// The light of the grid whose record starts at texel `rec`, for a surface facing n at the fragment (v: toward the camera), as the light a sky
// gives (irradiance / pi). `cover` is how much of the fragment the grid answers for: 1 inside its probes, fading to 0 over the half spacing
// around them (the grid's box), and 0 where the eight probes around the point cannot see it.
vec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover) {
    cover = 0.0;
    vec4 r0 = fa_light_texel(rec);
    vec4 r1 = fa_light_texel(rec + 1);
    vec4 r2 = fa_light_texel(rec + 2);
    vec4 r3 = fa_light_texel(rec + 3);
    if (r3.z < 0.5 || fa_atlas_size().y < 1155.0) { return vec3(0.0); }  // not ready, or an atlas without the band
    float spacing = max(r0.w, 1.0e-4);
    vec3 cnt = r1.xyz;
    vec3 rel = (fa_world_pos - r0.xyz) / spacing;                         // in probe units
    vec3 inner = min(rel + vec3(0.5), cnt - vec3(0.5) - rel);             // the distance to the box's faces, in spacings
    float edge = min(inner.x, min(inner.y, inner.z));
    if (!(edge > 0.0)) { return vec3(0.0); }
    float box = smoothstep(0.0, 1.0, clamp(edge * 2.0, 0.0, 1.0));
    // The eight probes around the point and their trilinear weights (gi_neighbours).
    vec3 g = clamp(rel, vec3(0.0), cnt - vec3(1.0));
    vec3 i0 = min(floor(g), max(cnt - vec3(2.0), vec3(0.0)));
    vec3 f = g - i0;
    // The point seen from the probes: pushed along the normal (and a little toward the camera) so a surface does not see itself through
    // the probe's own depth map.
    vec3 pb = fa_world_pos + (n * 0.8 + v * 0.2) * (0.2 * spacing);
    int bpr = int(r2.y + 0.5);
    // The cosine-convolved SH basis toward n (fa_sh_eval's constants): the irradiance of a probe is the sum of its nine coefficients times
    // these, so the probes are blended after the product and no array of coefficients is kept.
    float b0 = 0.282094792;
    float b1 = 0.325735008 * n.y;
    float b2 = 0.325735008 * n.z;
    float b3 = 0.325735008 * n.x;
    float b4 = 0.273137108 * n.x * n.y;
    float b5 = 0.273137108 * n.y * n.z;
    float b6 = 0.078847891 * (3.0 * n.z * n.z - 1.0);
    float b7 = 0.273137108 * n.x * n.z;
    float b8 = 0.136568554 * (n.x * n.x - n.y * n.y);
    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    // The bound comes from the record (its last texel is 0), not from a constant: a driver that unrolled the eight probes made a shader
    // with a discard (a clip material) too big for the Metal compiler.
    int nProbes = 8 + int(r3.w);
    for (int k = 0; k < nProbes; ++k) {
        vec3 d = vec3(float(k & 1), float((k >> 1) & 1), float((k >> 2) & 1));
        float tri = (d.x > 0.5 ? f.x : 1.0 - f.x) * (d.y > 0.5 ? f.y : 1.0 - f.y) * (d.z > 0.5 ? f.z : 1.0 - f.z);
        if (!(tri > 0.0)) { continue; }
        vec3 pr = min(i0 + d, cnt - vec3(1.0));
        int blk = int(r2.x + pr.x + cnt.x * (pr.y + cnt.y * pr.z) + 0.5);
        vec2 org = vec2(float(blk % bpr) * 10.0, 1024.0 + float(blk / bpr) * 11.0);
        vec4 meta = fa_gi_fetch(org + vec2(9.5, 10.5));
        if (meta.g < 0.5 || meta.r > r3.y) { continue; }  // not captured yet, or inside geometry
        vec3 toPoint = pb - (r0.xyz + pr * spacing);
        float dist = length(toPoint);
        vec3 dir = toPoint / max(dist, 1.0e-4);
        float w = tri;
        // A probe behind the surface (it is on the other side of the normal) counts less.
        float back = max(0.0001, (dot(-dir, n) + 1.0) * 0.5);
        w *= back * back;
        // Chebyshev's visibility test on the depth map: the moments are of d / maxDistance, so is the point's distance.
        vec2 e = fa_oct_encode(dir);
        vec2 mom = fa_gi_fetch(org + vec2(1.0) + (e * 0.5 + vec2(0.5)) * 8.0).rg;
        float dn = dist / max(r2.z, 1.0e-4);
        if (dn > mom.x) {
            float variance = max(mom.y - mom.x * mom.x, 0.0);
            float dd = dn - mom.x;
            float cheb = variance / max(variance + dd * dd, 1.0e-12);
            w *= cheb * cheb * cheb;
        }
        if (!(w > 0.0)) { continue; }
        vec2 shRow = org + vec2(0.5, 10.5);
        vec3 irr = fa_gi_fetch(shRow).rgb * b0 + fa_gi_fetch(shRow + vec2(1.0, 0.0)).rgb * b1 + fa_gi_fetch(shRow + vec2(2.0, 0.0)).rgb * b2 +
                   fa_gi_fetch(shRow + vec2(3.0, 0.0)).rgb * b3 + fa_gi_fetch(shRow + vec2(4.0, 0.0)).rgb * b4 +
                   fa_gi_fetch(shRow + vec2(5.0, 0.0)).rgb * b5 + fa_gi_fetch(shRow + vec2(6.0, 0.0)).rgb * b6 +
                   fa_gi_fetch(shRow + vec2(7.0, 0.0)).rgb * b7 + fa_gi_fetch(shRow + vec2(8.0, 0.0)).rgb * b8;
        acc += irr * w;
        wsum += w;
    }
    if (!(wsum > 1.0e-5)) { return vec3(0.0); }
    // Every probe that sees the point little leaves the sky to the rest: the grid's say fades with the weight it found.
    cover = box * smoothstep(0.0, 0.02, wsum);
    float gain = r2.w * (fa_gi.z > 0.5 ? r3.x : 1.0);  // intensity, times bounce in a capture of the grid's probes
    return max(acc / wsum, vec3(0.0)) * gain;
}

// The light of the ready grids at the fragment: `left` is the part the grids do not answer for (1 = none reaches it). The first grid that
// reaches the fragment takes its cover, the next ones what is left.
vec3 fa_gi_light(vec3 n, out float left) {
    left = 1.0;
    vec3 acc = vec3(0.0);
    vec3 v = normalize(fa_camera_pos.xyz - fa_world_pos);
    int first = int(fa_gi.x + 0.5);
    int count = int(fa_gi.y + 0.5);
    for (int k = 0; k < count && k < 8; ++k) {
        float c;
        vec3 l = fa_gi_grid(first + 4 * k, n, v, c);
        float share = c * left;
        acc += l * share;
        left -= share;
        if (left < 0.001) { left = 0.0; break; }
    }
    return acc;
}

// The diffuse light of a fragment no baked data reaches: the realtime GI where a ready grid covers it, the ambient light (the reflection
// probes' SH and the sky's) for the rest.
vec3 fa_realtime_or_ambient(vec3 n) {
    vec3 gi = vec3(0.0);
    float left = 1.0;
    if (fa_gi.y > 0.5) { gi = fa_gi_light(n, left); }
    if (left <= 0.0) { return gi; }
    return gi + fa_ambient_light(n) * left;
}

// The diffuse indirect light toward n, by order: the baked texel of a lightmapped surface; else the baked light probes where they cover
// the point (blended with the ambient light by their coverage: the part they do not cover gets the ambient light, not the realtime GI
// grid, a known deviation, docs/design/ARCHITECTURE_PROBES.md); else the realtime GI grid where a ready one covers it (blended with the
// ambient over the half spacing outside its probes); else the ambient light or the sky's irradiance (with the SH of a reflection probe
// that reaches the draw). It replaces fa_ambient_light in every diffuse ambient term, with or without material layers (the layers'
// base_scale darkens it as it does the ambient light). The specular IBL (fa_sky_reflection, fa_layers_ibl) is not part of it and stays
// the reflection probes' and the sky's: a lightmap holds no direction, so the ambient is never counted twice (the texel replaces the
// diffuse ambient only) and never missing.
// The grid's code is inlined at ONE call site: Apple's Metal compiler crashes on a clip material (graph with a discard) that has it at
// two, or that blends its result with the baked SH after the fact (also when the blend is made inside the one function: tried).
vec3 fa_indirect_diffuse(vec3 n) {
    if (fa_lm.z > 0.5) {
        return textureLod(sampler2D(fa_lightmap, fa_env_smp), fa_lm.xy, 0.0).rgb;
    }
    if (fa_gi_px.x > 0.5) {
        // The ray traced per-pixel GI (M79-P4b-1): the denoised irradiance / pi of the camera's image (view 26 holds it on a draw with no lightmap)
        // at this fragment's pixel, in place of the probes and the ambient light below. It is bound only on opaque draws of the main camera's pass.
        vec4 pv = vec4(fa_world_pos, 1.0);
        float w = max(dot(fa_ct_vpw, pv), 1e-4);
        vec2 ndc = vec2(dot(fa_ct_vpx, pv), dot(fa_ct_vpy, pv)) / w;
        vec2 uv = vec2(ndc.x * 0.5 + 0.5, fa_ct_a.y > 0.5 ? ndc.y * 0.5 + 0.5 : 0.5 - ndc.y * 0.5);
        ivec2 px = clamp(ivec2(uv * fa_ct_a.zw), ivec2(0), ivec2(fa_ct_a.zw) - 1);
        return texelFetch(sampler2D(fa_lightmap, fa_env_smp), px, 0).rgb;
    }
    if (fa_probe_sh[0].w > 0.0) {
        // Baked light probes (M73.4d): a mesh without a lightmap reads the SH its position got on the CPU, blended into the ambient
        // light where the probes only partly reach it.
        vec3 c[9];
        for (int k = 0; k < 9; k++) { c[k] = fa_probe_sh[k].xyz; }
        return mix(fa_ambient_light(n), fa_sh_eval(c, n), clamp(fa_probe_sh[0].w, 0.0, 1.0));
    }
    return fa_realtime_or_ambient(n);
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
#if defined(FA_LOD_DITHER) || defined(FA_ALPHA_CLIP)
    fa_lod_dither();
#endif

    vec3 result;
    float fa_tr_blend = 0.0;  // fallback draw of a transmissive surface (no atlas): how much of the picture behind the plain blend lets through
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
        // A transmissive surface lets this share of its diffuse light through (a metal lets none): what shows behind it is added below.
        float tr = clamp(s.transmission, 0.0, 1.0) * (1.0 - metallic);
        vec3 diffuse_color = s.albedo * (1.0 - metallic) * (1.0 - tr);
        vec3 f0 = mix(vec3(0.04), s.albedo, metallic);
        FaLayers lay = fa_layers_setup(i, s, n, v, metallic, roughness, f0);
        vec3 lit = fa_indirect_diffuse(n) * diffuse_color * s.occlusion;
        if (lay.on) { lit *= lay.base_scale; }
#endif
@include_block fa_light_loop
#if !defined(FA_CUSTOM_LIGHT) && !defined(FA_SSS)
        // Image-based lighting: the sky reflected, weighted by the environment BRDF (with the layers, fa_layers_ibl).
        if (lay.on) {
            lit += fa_layers_ibl(lay, n, v, f0, roughness, s.occlusion);
        } else {
            lit += fa_sky_reflection(n, v, f0, roughness) * s.occlusion;
        }
        if (tr > 0.0) {
            lit += fa_transmitted(s, n, v, roughness, f0, lay.on ? lay.f90 : 1.0, lay.on ? lay.base_scale : 1.0, tr, fa_tr_blend);
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
    if (fa_tr_blend > 0.0) {
        // A plain blend where the picture behind is not available: the surface covers it by 1 - the share that passes through.
        result /= 1.0 - fa_tr_blend;
        s.alpha *= 1.0 - fa_tr_blend;
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

// The variant of `fs` a draw that cross-fades between two levels of detail uses (programs mesh_lod and mesh_skin_lod): the only one
// with the dither's discard (fa_lod_dither), so the programs of every other draw keep their early depth test.
@fs fs_lod
#define FA_LOD_DITHER
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

// The motion vectors (M76): the camera's UNJITTERED view-projection of this frame and of the frame before, and in fa_vel_on: x = 1 when
// the prepass draws the velocity image (the renderer binds the block always; without the image the vertex stage skips the work),
// y = the game time of the frame before in seconds (what vertex() reads as fa_time.x in its second run), z = 1 when the draw has the
// previous palette in the image of fa_prev_palette (prepass_vs_skin only), w = the first texel of that palette in the image.
layout(binding=2) uniform fa_vel_params {
    mat4 fa_vel_vp;
    mat4 fa_vel_prev_vp;
    vec4 fa_vel_on;
};
// The clip position (x, y, w) of the surface point now and in the previous frame, interpolated; the fragment stage turns them into
// uv. w <= 0 in fa_vel_prev: "this program cannot say where the point was" (a skinned draw without a previous palette, a draw without the previous model):
// the fragment writes the sentinel and the temporal passes reproject with the camera alone.
out vec3 fa_vel_cur;
out vec3 fa_vel_prev;

// The three rows of an affine matrix (a vec4 each) as a matrix.
mat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2) {
    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0),
                vec4(r0.w, r1.w, r2.w, 1.0));
}

// fa_prev_model() is the model matrix of the instance in the frame before (the previous palette included for a skinned mesh), defined by
// each prepass program after its attributes and called only when the draw has a previous model (a draw without velocity reads nothing for
// it); `has_prev` false when the program has none. The previous world position of the point is where the SAME vertex shader puts it with that matrix and
// with the game time of that frame: vertex() of a material runs a second time, so wind, a wave or any displacement that moves with
// the time moves the pixel's vector too, and a displacement that does not change gives none. (The instance data and the material's
// values are the ones of this frame in both runs.) The engine's terrain and impostor programs define FA_VEL_STATIC_VERTEX: their
// vertex() places the vertex from the instance data and ignores the model matrix, so the previous position is the position now plus
// what the model matrix alone moved the point by.
mat4 fa_prev_model();
void fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color,
                       bool has_prev) {
    bool want_prev = has_prev && fa_vel_on.x > 0.5;
#ifdef FA_PREPASS_VS
    fa_vtime = fa_time_now();
#endif
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
    fa_vel_cur = vec3(0.0, 0.0, 1.0);
    fa_vel_prev = vec3(0.0);
    if (want_prev) {
        mat4 prev_model = fa_prev_model();
        vec3 prev_world;
#if defined(FA_HAS_VERTEX) && !defined(FA_VEL_STATIC_VERTEX)
        fa_vtime.x = fa_vel_on.y;
        VertexData pv = fa_vertex_data(prev_model, position, normal, tangent, texcoord0, color);
        vertex(pv);
        prev_world = pv.world_pos;
#else
        vec4 lp = vec4(position, 1.0);
        prev_world = v.world_pos + (prev_model * lp).xyz - (model * lp).xyz;
#endif
        vec4 cur = fa_vel_vp * wp;
        vec4 prev = fa_vel_prev_vp * vec4(prev_world, 1.0);
        fa_vel_cur = vec3(cur.x, cur.y, cur.w);
        fa_vel_prev = vec3(prev.x, prev.y, prev.w);
    }
}
@end

@vs prepass_vs
#define FA_PREPASS_VS
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
// The previous model matrix of the instance (vertex buffer 6, an affine matrix as three rows), right after the extra attributes
// (Gpu::prepass_pipeline lays them out the same way, render_internal.h prepass_prev_attr). A program without room for them (a
// material that declares every extra attribute) or drawn from storage buffers has none: its fragments write the sentinel.
#if !defined(FA_BUFFER_INST) && (FA_X_BASE + FA_NINST + FA_NUV1 + FA_NCOL1 + 3) <= 16
#define FA_PREV_BASE (FA_X_BASE + FA_NINST + FA_NUV1 + FA_NCOL1)
layout(location=FA_PREV_BASE) in vec4 fa_prev_r0;
layout(location=FA_PREV_BASE+1) in vec4 fa_prev_r1;
layout(location=FA_PREV_BASE+2) in vec4 fa_prev_r2;
mat4 fa_prev_model() { return fa_rows_to_mat4(fa_prev_r0, fa_prev_r1, fa_prev_r2); }
#define FA_HAS_PREV true
#else
mat4 fa_prev_model() { return mat4(1.0); }
#define FA_HAS_PREV false
#endif
void main() {
    fa_inst_begin();
    fa_prepass_vertex(FA_INST_MODEL, fa_position, fa_normal, fa_tangent, fa_texcoord0, fa_color, FA_HAS_PREV);
}
@end

@vs prepass_vs_skin
#define FA_PREPASS_VS
@include_block fa_vs_common
@include_block fa_skin_common
@include_block fa_prev_palette
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
// The previous model matrix as in prepass_vs, after the extras at FA_X_BASE 11 (so room for 2 extra attributes), times the skinning of
// the frame before, read from the palette image at the texel fa_vel_on.w when the draw has one (fa_vel_on.z = 1), else the draw writes the
// sentinel. The previous matrix is evaluated only for a draw that wants it (fa_prepass_vertex), so a frame without velocity reads none of it.
#if !defined(FA_BUFFER_INST) && (FA_X_BASE + FA_NINST + FA_NUV1 + FA_NCOL1 + 3) <= 16
#define FA_PREV_BASE (FA_X_BASE + FA_NINST + FA_NUV1 + FA_NCOL1)
layout(location=FA_PREV_BASE) in vec4 fa_prev_r0;
layout(location=FA_PREV_BASE+1) in vec4 fa_prev_r1;
layout(location=FA_PREV_BASE+2) in vec4 fa_prev_r2;
mat4 fa_prev_model() {
    return fa_rows_to_mat4(fa_prev_r0, fa_prev_r1, fa_prev_r2) * fa_prev_skin_matrix(fa_joints, fa_weights, int(fa_vel_on.w + 0.5));
}
#define FA_HAS_PREV (fa_vel_on.z > 0.5)
#else
mat4 fa_prev_model() { return mat4(1.0); }
#define FA_HAS_PREV false
#endif
void main() {
    fa_inst_begin();
    fa_prepass_vertex(FA_INST_MODEL * fa_skin_matrix(fa_joints, fa_weights), fa_position,
                      fa_normal, fa_tangent, fa_texcoord0, fa_color, FA_HAS_PREV);
}
@end

// One texel per pixel of the prepass target (an RGBA float image, cleared to r = far, a = 0 where nothing is drawn):
//   r  the linear view depth in world units (the distance along the camera's axis, so the same for a perspective and an
//      orthographic camera and in every graphics API); far (60000) where nothing was drawn, and never more than that where
//      something was (clamped, so an RGBA16F fallback never stores Inf)
//   gb the surface normal in view space (x right, y up, z toward the camera), octahedral encoded in -1..1 (decode below); 0 0 where
//      nothing was drawn
//   a  1 where an opaque mesh was drawn, 0 where not: the truth about coverage (a drawn surface at 60000 or more has r = 60000 too)
// A second output (location 1) is the motion vector of the pixel (M76): uvPrev - uvCurr, in uv units (y down), from the UNJITTERED
// matrices of this frame and the one before; 1024 in both channels (VelocityRef::kNone) where this program cannot say (a skinned
// mesh, a draw without a previous model, a point behind the previous camera). The renderer attaches a second image to the pass only
// when a temporal effect, the debug view "motionVectors" or a test asks; without the attachment the output is dropped.
// The normal is the one the main pass lights with (a normal map and surface() included); a cutout (alphaMode "clip") leaves holes.
//
// With FA_GBUFFER (the programs `gbuffer` of mesh.glsl, terrain.glsl and impostor.glsl, M79-P0c: the thin G-buffer the renderer draws only when
// something asks for it, see docs/design/ARCHITECTURE_RENDERING_GBUFFER.md) the same vertex stage and the same surface() write other outputs:
//   location 0 (RGBA8)  rgb = the albedo of the surface (the base colour times the texture and the vertex colour, linear, clamped to 0..1;
//                       a metal's base colour is its albedo here too), a = 1 where a mesh was drawn
//   location 1 (RGBA8)  r = the roughness (0.05..1), g = the metalness (0..1), b = 0 (spare), a = 1 where a mesh was drawn
// With FA_GBUFFER_VIS (the mesh programs) a fragment that is not the surface the prepass kept at its pixel is dropped (the prepass is at view 28):
// an alpha-tested cutout leaves its holes and a mesh behind another one writes nothing, so the engine's own program serves a material whose
// surface() it does not run.
@block fa_prepass_fs_main
@include_block fa_fs_surface
in float fa_pre_depth;
in vec3 fa_pre_r0;
in vec3 fa_pre_r1;
in vec3 fa_pre_r2;
in vec3 fa_vel_cur;
in vec3 fa_vel_prev;
#ifdef FA_GBUFFER
layout(location=0) out vec4 fa_frag_albedo;
layout(location=1) out vec4 fa_frag_material;
#else
layout(location=0) out vec4 fa_frag_color;
layout(location=1) out vec2 fa_frag_velocity;
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
    Surface s = fa_standard_surface(i);
    surface(i, s);
#ifdef FA_ALPHA_CLIP
    if (s.alpha < alphaCutoff) { discard; }
#endif
#if defined(FA_LOD_DITHER) || defined(FA_ALPHA_CLIP)
    fa_lod_dither();
#endif
#ifdef FA_GBUFFER
#ifdef FA_GBUFFER_VIS
    {
        // The pixel of this fragment in the image of the prepass (same size, same rows): the surface the camera sees there.
        vec4 seen = texelFetch(sampler2D(fa_screen_tex, fa_shadow_smp), ivec2(gl_FragCoord.xy), 0);
        if (seen.a < 0.5 || abs(fa_pre_depth - seen.r) > 0.02 + 0.01 * fa_pre_depth) { discard; }
    }
#endif
    fa_frag_albedo = vec4(clamp(s.albedo, vec3(0.0), vec3(1.0)), 1.0);
    // The spare channel is 0. It reads the varyings of the prepass's vertex stage (all finite) only so that this fragment stage declares the
    // same inputs as that stage writes: on the backends that number the stage interface by position (HLSL, Metal) both must list the same.
    fa_frag_material = vec4(clamp(s.roughness, 0.0, 1.0), clamp(s.metallic, 0.0, 1.0),
                            0.0 * (fa_pre_r0.x + fa_pre_r1.x + fa_pre_r2.x + fa_vel_cur.x + fa_vel_prev.x), 1.0);
#else
    vec3 n = normalize(s.normal);
    vec3 nv = normalize(vec3(dot(fa_pre_r0, n), dot(fa_pre_r1, n), dot(fa_pre_r2, n)));
    // Octahedral encoding: the sphere folded onto the square -1..1 (decode: n = (e.x, e.y, 1 - |e.x| - |e.y|); where n.z < 0,
    // e = (1 - |e.yx|) * sign(e) first; normalize).
    vec2 e = nv.xy / (abs(nv.x) + abs(nv.y) + abs(nv.z));
    if (nv.z < 0.0) { e = (1.0 - abs(e.yx)) * vec2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0); }
    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);
    vec2 motion = vec2(1024.0);
    if (fa_vel_cur.z > 1.0e-5 && fa_vel_prev.z > 1.0e-5) {
        vec2 uv_cur = vec2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z * 0.5;
        vec2 uv_prev = vec2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z * 0.5;
        motion = clamp(uv_prev - uv_cur, vec2(-4.0), vec2(4.0));
    }
    fa_frag_velocity = motion;
#endif
}
@end

@fs prepass_fs
@include_block fa_prepass_fs_main
@end

// The thin G-buffer's fragment stage (M79-P0c): `gbuffer_fs` for the meshes (programs gbuffer and gbuffer_skin of mesh.glsl: they test their
// fragment against the prepass, so an alpha-tested cutout leaves holes), `gbuffer_fs_plain` for the terrain and the impostors, which are opaque
// by construction (their own alpha clip, when they have one, is in surface()) and whose fragment stage has no room for another texture.
@fs gbuffer_fs
#define FA_GBUFFER
#define FA_GBUFFER_VIS
@include_block fa_prepass_fs_main
@end

@fs gbuffer_fs_plain
#define FA_GBUFFER
@include_block fa_prepass_fs_main
@end

// The prepass of a draw that cross-fades between two levels of detail (prepass_lod, prepass_skin_lod): `prepass_fs` with the dither.
@fs prepass_fs_lod
#define FA_LOD_DITHER
@include_block fa_prepass_fs_main
@end
