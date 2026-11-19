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
// horizon colors), fog and an optional directional shadow map.
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
// vertex-stage block); fragment 1 fa_mesh_fs_params, 2 fa_lights (5 for the material). Views 0-5 and samplers 0-1 are
// the engine's. A material texture is bound twice, so both stages can sample it (a sokol view slot belongs to one stage and
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
#ifdef FA_CH_UV1
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
    mat4 fa_light_vp;           // directional shadow matrix (world -> light clip)
    vec4 fa_uv_scale;           // xy
    vec4 fa_time;               // x = seconds of game time since the scene started
};

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
out vec4 fa_shadow_pos;

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
    fa_shadow_pos = fa_light_vp * wp;
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
@include_block fa_extra_attrs

void main() {
    fa_inst_begin();
    fa_shade_vertex(mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3), fa_position, fa_normal, fa_tangent, fa_texcoord0, fa_color);
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
    fa_shade_vertex(mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(fa_joints, fa_weights),
                    fa_position, fa_normal, fa_tangent, fa_texcoord0, fa_color);
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

layout(binding=1) uniform fa_mesh_fs_params {
    vec4 fa_camera_pos;         // xyz
    vec4 fa_ambient;            // rgb
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
    vec4 fa_counts;             // x = light count, y = shadow texel size, z = 1 on OpenGL backends
    vec4 fa_env_sky;            // rgb sky color (top of the environment)
    vec4 fa_env_horizon;        // rgb horizon color
    vec4 fa_time;               // x = seconds of game time since the scene started
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
    s.occlusion = 1.0 + fa_maps.y * (fa_tex_fix(texture(sampler2D(fa_occlusion_tex, fa_smp), i.uv).rrr, fa_fix_of(fa_maps.w, 256.0)).r - 1.0);
    s.emission = fa_emissive.rgb + fa_model_emissive.rgb * fa_tex_fix(texture(sampler2D(fa_emissive_tex, fa_smp), i.uv).rgb, fa_fix_of(fa_maps.w, 4.0));
    return s;
}
@end

// The sky the surface reflects, shared with the full-shader template (mesh_full_common.glsl includes this block after it has
// declared fa_env_sky and fa_env_horizon).
@block fa_env_funcs
// The environment the surface reflects: the same gradient as the sky, the horizon color (darker) below the horizon,
// and rougher surfaces see a blurrier, flatter version of it (a cheap stand-in for a prefiltered cubemap).
vec3 fa_environment(vec3 d, float rough) {
    float blur = rough * rough;
    float h = clamp(d.y * (1.0 - 0.7 * blur), 0.0, 1.0);
    vec3 up = mix(fa_env_horizon.rgb, fa_env_sky.rgb, pow(h, 0.55));
    vec3 down = fa_env_horizon.rgb * 0.55;
    float k = smoothstep(-0.05 - 0.6 * blur, 0.05 + 0.6 * blur, d.y);
    vec3 e = mix(down, up, k);
    return mix(e, 0.5 * (fa_env_sky.rgb + fa_env_horizon.rgb) * 0.8, blur * 0.6);
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
// s.roughness, s.albedo, s.normal) times s.occlusion.
vec3 fa_sky_light(in SurfaceInput i, in Surface s) {
    float metallic = clamp(s.metallic, 0.0, 1.0);
    float roughness = clamp(s.roughness, 0.05, 1.0);
    vec3 f0 = mix(vec3(0.04), s.albedo, metallic);
    return fa_sky_reflection(normalize(s.normal), i.view_dir, f0, roughness) * s.occlusion;
}
#endif
@end

// What only the main fragment shader has (the snippet's light(), ambient() and lighting() call these, so the block comes before
// the snippet): the light array, the shadow coordinate and map, the sky, and the light samples.
@block fa_fs_light
layout(binding=2) uniform fa_lights {
    vec4 fa_light_pos[32];      // xyz position (point/spot) or direction TO the light (directional); w range
    vec4 fa_light_color[32];    // rgb color * intensity; w type (0 directional, 1 point, 2 spot)
    vec4 fa_light_dir[32];      // xyz spot axis (direction light points); w cos(spot half angle)
};

in vec4 fa_shadow_pos;

const float FA_PI = 3.14159265;

float fa_shadow_factor(vec3 n, vec3 l) {
    if (fa_pbr.z < 0.5) { return 1.0; }
    vec3 p = fa_shadow_pos.xyz / fa_shadow_pos.w;
    vec2 suv = p.xy * 0.5 + 0.5;
    bool is_gl = fa_counts.z > 0.5;
    if (is_gl) { p.z = p.z * 0.5 + 0.5; } else { suv.y = 1.0 - suv.y; }
    if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0 || p.z > 1.0) { return 1.0; }
    float bias = fa_pbr.w * (1.0 + 2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0)));
    float lit = 0.0;
    float texel = fa_counts.y;
    for (int ix = -1; ix <= 1; ix++) {
        for (int iy = -1; iy <= 1; iy++) {
            float depth = textureLod(sampler2D(fa_shadow_tex, fa_shadow_smp), suv + vec2(float(ix), float(iy)) * texel, 0.0).r;  // explicit LOD: no gradients inside loops (HLSL X3570)
            lit += (p.z - bias <= depth) ? 1.0 : 0.0;
        }
    }
    return lit / 9.0;
}

@include_block fa_env_funcs
@include_block fa_light_shared

// Light li of the array as seen from a world position, without its shadow: the direction to it, its color times intensity times
// attenuation, the attenuation, the distance and the type. shadow is 1.
LightSample fa_light_sample(int li, vec3 world_pos) {
    float type = fa_light_color[li].w;
    vec3 l;
    float atten = 1.0;
    float dist = 0.0;
    if (type < 0.5) {
        l = normalize(fa_light_pos[li].xyz);
    } else {
        vec3 to_light = fa_light_pos[li].xyz - world_pos;
        dist = length(to_light);
        l = to_light / max(dist, 1e-4);
        float range = max(fa_light_pos[li].w, 1e-3);
        float x = clamp(1.0 - (dist / range) * (dist / range), 0.0, 1.0);
        atten = x * x;
        if (type > 1.5) {
            float cos_angle = dot(-l, normalize(fa_light_dir[li].xyz));
            float cos_outer = fa_light_dir[li].w;
            atten *= smoothstep(cos_outer, mix(cos_outer, 1.0, 0.25), cos_angle);
        }
    }
    LightSample ls;
    ls.direction = l;
    ls.color = fa_light_color[li].rgb * atten;
    ls.attenuation = atten;
    ls.shadow = 1.0;
    ls.distance = dist;
    ls.type = type < 0.5 ? 0 : (type > 1.5 ? 2 : 1);
    return ls;
}

// The same with the shadow of the directional shadow map applied (only the first light, and only when it is directional, is
// shadowed): what the engine's light loop hands to light(). gn is the geometric normal.
LightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn) {
    LightSample ls = fa_light_sample(li, world_pos);
    if (ls.type == 0 && li == 0) {
        ls.shadow = fa_shadow_factor(gn, ls.direction);
        ls.color = fa_light_color[li].rgb * (ls.attenuation * ls.shadow);
    }
    return ls;
}

#ifdef FA_CUSTOM_LIGHT
// The lighting API of a "custom" material (docs/shaders/SHADERS_LIGHTING.md): usable from light(), ambient() and lighting().
// How many lights the engine hands over (at most 32): the ones that matter most for this frame, directional first.
int fa_light_count() { return min(int(fa_counts.x), 32); }
// Light n (0 .. fa_light_count() - 1) with the shadow applied, as light() receives it. A number outside the range gives a sample
// that lights nothing (color and attenuation 0, shadow 1).
LightSample fa_light(int n, in SurfaceInput i) {
    if (n < 0 || n >= fa_light_count()) { return fa_no_light(); }
    return fa_light_shadowed(n, i.world_pos, i.world_normal);
}
// Light n without the shadow map read: color has no shadow in it and shadow is 1; the way to treat the shadow apart.
LightSample fa_light_unshadowed(int n, in SurfaceInput i) {
    if (n < 0 || n >= fa_light_count()) { return fa_no_light(); }
    return fa_light_sample(n, i.world_pos);
}
// The shadow of light n at this fragment: 1 lit, 0 in shadow (a value between at the edge of the shadow). Only the first light
// (n = 0) when it is directional has a shadow; every other light gives 1.
float fa_light_shadow(int n, in SurfaceInput i) {
    if (n != 0 || fa_light_count() < 1 || fa_light_color[0].w > 0.5) { return 1.0; }
    return fa_shadow_factor(i.world_normal, normalize(fa_light_pos[0].xyz));
}
#endif
@end

@block fa_fs_nolight
#ifdef FA_CUSTOM_LIGHT
@include_block fa_env_funcs
@include_block fa_light_shared
int fa_light_count() { return 0; }
LightSample fa_light(int n, in SurfaceInput i) { return fa_no_light(); }
LightSample fa_light_unshadowed(int n, in SurfaceInput i) { return fa_no_light(); }
float fa_light_shadow(int n, in SurfaceInput i) { return 1.0; }
#endif
@end

@block fa_fs_surface
@include_block fa_fs_head
@include_block fa_fs_nolight
@include_block fa_user
@include_block fa_fs_rest
@end

@fs fs
@include_block fa_fs_head
@include_block fa_fs_light
@include_block fa_user
@include_block fa_fs_rest

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

    vec3 result;
    if (fa_emissive.w > 0.5) {
        result = s.albedo;
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
        vec3 lit = ambient(i, s, fa_ambient.rgb);
#else
        vec3 lit = fa_ambient.rgb * s.albedo * s.occlusion;
#endif
#else
        float metallic = clamp(s.metallic, 0.0, 1.0);
        float roughness = clamp(s.roughness, 0.05, 1.0);
        float alpha = roughness * roughness;
        float a2 = alpha * alpha;
        float ndv = max(dot(n, v), 1e-4);
        vec3 diffuse_color = s.albedo * (1.0 - metallic);
        vec3 f0 = mix(vec3(0.04), s.albedo, metallic);
        vec3 lit = fa_ambient.rgb * diffuse_color * s.occlusion;
#endif
        int count = int(fa_counts.x);
        for (int li = 0; li < 32; li++) {
            if (li >= count) { break; }
            LightSample ls = fa_light_shadowed(li, i.world_pos, gn);
#ifdef FA_CUSTOM_LIGHT
            // lighting "custom": the snippet's light() takes the place of the Cook-Torrance term below.
            lit += light(i, s, ls);
#else
            vec3 l = ls.direction;
            float ndl = max(dot(n, l), 0.0);
            float atten = ls.attenuation * ls.shadow;
            vec3 h = normalize(l + v);
            float ndh = max(dot(n, h), 0.0);
            float vdh = max(dot(v, h), 0.0);
            // Cook-Torrance: GGX distribution, height-correlated Smith visibility (Karis' approximation), Schlick Fresnel.
            float dd = ndh * ndh * (a2 - 1.0) + 1.0;
            float d_ggx = a2 / (FA_PI * dd * dd);
            float vis = 0.5 / max(mix(2.0 * ndl * ndv, ndl + ndv, alpha), 1e-4);
            vec3 fres = f0 + (1.0 - f0) * pow(1.0 - vdh, 5.0);
            // Light colors are not divided by pi (a white light of intensity 1 lights a white diffuse surface to 1),
            // so the specular term carries the matching factor pi.
            vec3 spec = fres * (d_ggx * vis * FA_PI) * step(0.0001, ndl);
            lit += (diffuse_color + spec) * fa_light_color[li].rgb * (ndl * atten);
#endif
        }
#ifndef FA_CUSTOM_LIGHT
        // Image-based lighting: the sky reflected, weighted by the environment BRDF.
        lit += fa_sky_reflection(n, v, f0, roughness) * s.occlusion;
#endif
#endif
        result = lit;
    }
    result += s.emission;
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
            result = mix(result, fa_fog.rgb, clamp(f, 0.0, 1.0));
        }
    }
    fa_frag_color = vec4(result, s.alpha);
}
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
    mat4 model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);
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
    mat4 model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(fa_joints, fa_weights);
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
    fa_prepass_vertex(mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3), fa_position, fa_normal, fa_tangent, fa_texcoord0, fa_color);
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
    fa_prepass_vertex(mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(fa_joints, fa_weights), fa_position,
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
