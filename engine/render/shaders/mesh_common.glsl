// FactorIA mesh template: the source of every mesh program, the engine's own and every custom material's
// (docs/design/CUSTOM_SHADERS.md). Not compiled on its own: a top file defines the @block fa_user (the material's
// uniforms, textures and snippet: void surface(in SurfaceInput i, inout Surface s) and, with FA_HAS_VERTEX defined,
// void vertex(inout VertexData v)), then `@include mesh_common.glsl` and declares the programs:
//   @program mesh vs fs                          (mesh.glsl does exactly this with an empty surface())
//   @program mesh_skin vs_skin fs
//   @program shadow shadow_vs shadow_fs
//   @program shadow_skin shadow_vs_skin shadow_fs
//
// Metallic-roughness PBR (Cook-Torrance GGX) with normal, metallic-roughness, occlusion and emissive maps, up to 32
// directional/point/spot lights, sky image-based lighting (a procedural environment built from the scene's sky and
// horizon colors), fog and an optional directional shadow map.
// Instanced: the model matrix of every instance comes from vertex buffer 1 (four vec4 columns, locations 4..7; 1..4 in
// the shadow pass, whose attributes must be contiguous). Skinned meshes use the _skin programs: joints and weights come
// from vertex buffer 2 (locations 8, 9; 5, 6 in the shadow pass).
//
// Every engine identifier starts with fa_ (FA_ for constants), so "names starting with fa_ are the engine's" is the one
// rule a snippet follows. Uniform block bindings: vertex 0 fa_mesh_vs_params, 3 fa_skin (4 is left for the material's
// vertex-stage block); fragment 1 fa_mesh_fs_params, 2 fa_lights (5 for the material). Views 0-5 and samplers 0-1 are
// the engine's.

// The snippet contract (docs/SHADERS.md).
@block fa_types
struct SurfaceInput {           // read-only, per fragment
    vec3 world_pos;
    vec3 world_normal;          // interpolated geometric normal, normalized, flipped on back faces
    vec4 world_tangent;         // xyz tangent, w handedness
    vec2 uv;                    // after MeshRenderer.uvScale
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
struct VertexData {             // vertex(): world space, after instancing and skinning
    vec3 world_pos;
    vec3 world_normal;
    vec4 world_tangent;
    vec2 uv;
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

@block fa_vs_common
layout(binding=0) uniform fa_mesh_vs_params {
    mat4 fa_view_proj;
    mat4 fa_light_vp;           // directional shadow matrix (world -> light clip)
    vec4 fa_uv_scale;           // xy
    vec4 fa_time;               // x = seconds of game time since the scene started
};

@include_block fa_types
@include_block fa_user

// World space from the model matrix: the VertexData vertex() receives.
VertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0) {
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
out vec3 fa_world_pos;
out vec3 fa_world_normal;
out vec4 fa_world_tangent;
out vec2 fa_uv;
out vec4 fa_shadow_pos;

// Everything after the model matrix is known: shared by the instanced and the skinned vertex shader.
void fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0) {
    VertexData v = fa_vertex_data(model, position, normal, tangent, texcoord0);
#ifdef FA_HAS_VERTEX
    vertex(v);
#endif
    vec4 wp = vec4(v.world_pos, 1.0);
    fa_world_pos = v.world_pos;
    fa_world_normal = v.world_normal;
    fa_world_tangent = v.world_tangent;
    fa_uv = v.uv;
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
layout(location=4) in vec4 fa_inst_m0;     // per-instance model matrix, one column each
layout(location=5) in vec4 fa_inst_m1;
layout(location=6) in vec4 fa_inst_m2;
layout(location=7) in vec4 fa_inst_m3;

void main() {
    fa_shade_vertex(mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3), fa_position, fa_normal, fa_tangent, fa_texcoord0);
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
layout(location=4) in vec4 fa_inst_m0;
layout(location=5) in vec4 fa_inst_m1;
layout(location=6) in vec4 fa_inst_m2;
layout(location=7) in vec4 fa_inst_m3;
layout(location=8) in vec4 fa_joints;
layout(location=9) in vec4 fa_weights;

void main() {
    fa_shade_vertex(mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(fa_joints, fa_weights),
                    fa_position, fa_normal, fa_tangent, fa_texcoord0);
}
@end

@fs fs
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
    vec4 fa_maps;               // x normal scale, y occlusion strength, z = 1 when a normal map is bound
    vec4 fa_fog;                // rgb color, w density
    vec4 fa_counts;             // x = light count, y = shadow texel size, z = 1 on OpenGL backends
    vec4 fa_env_sky;            // rgb sky color (top of the environment)
    vec4 fa_env_horizon;        // rgb horizon color
    vec4 fa_time;               // x = seconds of game time since the scene started
};

layout(binding=2) uniform fa_lights {
    vec4 fa_light_pos[32];      // xyz position (point/spot) or direction TO the light (directional); w range
    vec4 fa_light_color[32];    // rgb color * intensity; w type (0 directional, 1 point, 2 spot)
    vec4 fa_light_dir[32];      // xyz spot axis (direction light points); w cos(spot half angle)
};

in vec3 fa_world_pos;
in vec3 fa_world_normal;
in vec4 fa_world_tangent;
in vec2 fa_uv;
in vec4 fa_shadow_pos;
out vec4 fa_frag_color;

const float FA_PI = 3.14159265;

@include_block fa_types
@include_block fa_user

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

// What a MeshRenderer without a material draws: texture * color, normal map, metallic/roughness maps, occlusion,
// emissive. surface() starts from it.
Surface fa_standard_surface(in SurfaceInput i) {
    Surface s;
    vec4 albedo4 = texture(sampler2D(fa_tex, fa_smp), i.uv) * fa_base_color;
    s.albedo = albedo4.rgb;
    s.alpha = albedo4.a;
    s.normal = i.world_normal;
    if (fa_maps.z > 0.5) {
        vec3 m = texture(sampler2D(fa_normal_tex, fa_smp), i.uv).xyz * 2.0 - 1.0;
        m.xy *= fa_maps.x;
        s.normal = fa_tangent_normal(i, m);
    }
    vec4 mrt = texture(sampler2D(fa_mr_tex, fa_smp), i.uv);
    s.metallic = clamp(fa_pbr.x * mrt.b, 0.0, 1.0);
    s.roughness = clamp(fa_pbr.y * mrt.g, 0.05, 1.0);
    s.occlusion = 1.0 + fa_maps.y * (texture(sampler2D(fa_occlusion_tex, fa_smp), i.uv).r - 1.0);
    s.emission = fa_emissive.rgb + fa_model_emissive.rgb * texture(sampler2D(fa_emissive_tex, fa_smp), i.uv).rgb;
    return s;
}

void main() {
    SurfaceInput i;
    i.world_pos = fa_world_pos;
    i.front_facing = gl_FrontFacing;
    i.world_normal = normalize(fa_world_normal);
    if (!i.front_facing) { i.world_normal = -i.world_normal; }
    i.world_tangent = fa_world_tangent;
    i.uv = fa_uv;
    i.view_dir = normalize(fa_camera_pos.xyz - fa_world_pos);
    Surface s = fa_standard_surface(i);
    surface(i, s);

    vec3 result;
    if (fa_emissive.w > 0.5) {
        result = s.albedo;
    } else {
        vec3 gn = i.world_normal;
        vec3 n = normalize(s.normal);
        vec3 v = i.view_dir;
        float metallic = clamp(s.metallic, 0.0, 1.0);
        float roughness = clamp(s.roughness, 0.05, 1.0);
        float alpha = roughness * roughness;
        float a2 = alpha * alpha;
        float ndv = max(dot(n, v), 1e-4);
        vec3 diffuse_color = s.albedo * (1.0 - metallic);
        vec3 f0 = mix(vec3(0.04), s.albedo, metallic);
        vec3 lit = fa_ambient.rgb * diffuse_color * s.occlusion;
        int count = int(fa_counts.x);
        for (int li = 0; li < 32; li++) {
            if (li >= count) { break; }
            float type = fa_light_color[li].w;
            vec3 l;
            float atten = 1.0;
            if (type < 0.5) {
                l = normalize(fa_light_pos[li].xyz);
            } else {
                vec3 to_light = fa_light_pos[li].xyz - i.world_pos;
                float dist = length(to_light);
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
            float ndl = max(dot(n, l), 0.0);
            if (type < 0.5 && li == 0) { atten *= fa_shadow_factor(gn, l); }
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
        }
        // Image-based lighting: the sky reflected, weighted by the environment BRDF.
        vec3 r = reflect(-v, n);
        vec2 ab = fa_env_brdf(roughness, ndv);
        lit += fa_environment(r, roughness) * (f0 * ab.x + ab.y) * s.occlusion;
        result = lit;
    }
    result += s.emission;
    if (fa_fog.w > 0.0) {
        float dist = length(fa_camera_pos.xyz - i.world_pos);
        float f = 1.0 - exp(-(fa_fog.w * dist) * (fa_fog.w * dist));
        result = mix(result, fa_fog.rgb, clamp(f, 0.0, 1.0));
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
#ifdef FA_HAS_VERTEX
layout(location=5) in vec3 fa_normal;
layout(location=6) in vec2 fa_texcoord0;
layout(location=7) in vec4 fa_tangent;
#endif
void main() {
    mat4 model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);
#ifdef FA_HAS_VERTEX
    VertexData v = fa_vertex_data(model, fa_position, fa_normal, fa_tangent, fa_texcoord0);
    vertex(v);
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
#ifdef FA_HAS_VERTEX
layout(location=7) in vec3 fa_normal;
layout(location=8) in vec2 fa_texcoord0;
layout(location=9) in vec4 fa_tangent;
#endif
void main() {
    mat4 model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(fa_joints, fa_weights);
#ifdef FA_HAS_VERTEX
    VertexData v = fa_vertex_data(model, fa_position, fa_normal, fa_tangent, fa_texcoord0);
    vertex(v);
    gl_Position = fa_light_vp * vec4(v.world_pos, 1.0);
#else
    gl_Position = fa_light_vp * (model * vec4(fa_position, 1.0));
#endif
}
@end

// alphaMode "clip" (running surface() here to discard below the cutoff) comes with the materials (package 3).
@fs shadow_fs
out vec4 fa_frag_color;
void main() {
    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
}
@end
