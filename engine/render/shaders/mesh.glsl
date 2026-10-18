// FactorIA 3D mesh shader: metallic-roughness PBR (Cook-Torrance GGX) with normal, metallic-roughness, occlusion
// and emissive maps, up to 32 directional/point/spot lights, sky image-based lighting (a procedural environment built
// from the scene's sky and horizon colors), fog and an optional directional shadow map.
// Instanced: the model matrix of every instance comes from vertex buffer 1 (four vec4 columns, locations 4..7).
// Skinned meshes use the second program (mesh_skin): joints and weights come from vertex buffer 2 (locations 8, 9).
@module mesh

@block vs_common
layout(binding=0) uniform mesh_vs_params {
    mat4 view_proj;
    mat4 light_vp;      // directional shadow matrix (world -> light clip)
    vec4 uv_scale;      // xy
};

out vec3 world_pos;
out vec3 world_normal;
out vec4 world_tangent;
out vec2 uv;
out vec4 shadow_pos;

// Everything after the model matrix is known: shared by the instanced and the skinned vertex shader.
void shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0) {
    vec4 wp = model * vec4(position, 1.0);
    world_pos = wp.xyz;
    // Normal matrix = cofactor matrix of the upper 3x3 (inverse transpose up to a positive scale), so one
    // 64-byte matrix per instance is enough. s flips the handedness of mirrored instances.
    vec3 c0 = model[0].xyz;
    vec3 c1 = model[1].xyz;
    vec3 c2 = model[2].xyz;
    float s = dot(c0, cross(c1, c2)) < 0.0 ? -1.0 : 1.0;
    world_normal = (cross(c1, c2) * normal.x + cross(c2, c0) * normal.y + cross(c0, c1) * normal.z) * s;
    world_tangent = vec4(c0 * tangent.x + c1 * tangent.y + c2 * tangent.z, tangent.w * s);
    uv = texcoord0 * uv_scale.xy;
    shadow_pos = light_vp * wp;
    gl_Position = view_proj * wp;
}
@end

@vs vs
@include_block vs_common
layout(location=0) in vec3 position;
layout(location=1) in vec3 normal;
layout(location=2) in vec2 texcoord0;
layout(location=3) in vec4 tangent;     // xyz tangent, w = handedness (+1 / -1)
layout(location=4) in vec4 inst_m0;     // per-instance model matrix, one column each
layout(location=5) in vec4 inst_m1;
layout(location=6) in vec4 inst_m2;
layout(location=7) in vec4 inst_m3;

void main() {
    shade_vertex(mat4(inst_m0, inst_m1, inst_m2, inst_m3), position, normal, tangent, texcoord0);
}
@end

// Skinned variant: the same outputs (so the same fragment shader), with the model matrix of the (single) instance
// times the blend of up to four joint matrices. The palette is 64 joints of 3 rows (a 3x4 matrix as three vec4 rows).
@vs vs_skin
@include_block vs_common
layout(location=0) in vec3 position;
layout(location=1) in vec3 normal;
layout(location=2) in vec2 texcoord0;
layout(location=3) in vec4 tangent;
layout(location=4) in vec4 inst_m0;
layout(location=5) in vec4 inst_m1;
layout(location=6) in vec4 inst_m2;
layout(location=7) in vec4 inst_m3;
layout(location=8) in vec4 joints;      // joint indices (bytes, normalized: x255)
layout(location=9) in vec4 weights;

layout(binding=3) uniform mesh_skin {
    vec4 joint_rows[192];               // joint j: rows 3j .. 3j+2 of its skinning matrix
};

void main() {
    vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0);
    for (int i = 0; i < 4; ++i) {
        int j = int(joints[i] * 255.0 + 0.5) * 3;
        float w = weights[i];
        r0 += joint_rows[j] * w;
        r1 += joint_rows[j + 1] * w;
        r2 += joint_rows[j + 2] * w;
    }
    mat4 skin = mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0),
                     vec4(r0.w, r1.w, r2.w, 1.0));
    shade_vertex(mat4(inst_m0, inst_m1, inst_m2, inst_m3) * skin, position, normal, tangent, texcoord0);
}
@end


@fs fs
layout(binding=0) uniform texture2D tex;            // base color
layout(binding=1) uniform texture2D shadow_tex;
layout(binding=2) uniform texture2D normal_tex;     // tangent-space normal map
layout(binding=3) uniform texture2D mr_tex;         // glTF metallicRoughnessTexture: g = roughness, b = metallic
layout(binding=4) uniform texture2D occlusion_tex;  // r = ambient occlusion
layout(binding=5) uniform texture2D emissive_tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform sampler shadow_smp;
@image_sample_type shadow_tex unfilterable_float
@sampler_type shadow_smp nonfiltering

layout(binding=1) uniform mesh_fs_params {
    vec4 camera_pos;            // xyz
    vec4 ambient;               // rgb
    vec4 base_color;
    vec4 emissive;              // rgb MeshRenderer.emissive, w = 1 when unlit
    vec4 model_emissive;        // rgb glTF emissiveFactor (multiplies emissive_tex)
    vec4 material;              // x metallic, y roughness, z receive shadow (0/1), w shadow depth bias
    vec4 maps;                  // x normal scale, y occlusion strength, z = 1 when a normal map is bound
    vec4 fog;                   // rgb color, w density
    vec4 counts;                // x = light count, y = shadow texel size, z = 1 on OpenGL backends
    vec4 env_sky;               // rgb sky color (top of the environment)
    vec4 env_horizon;           // rgb horizon color
};

layout(binding=2) uniform mesh_lights {
    vec4 light_pos[32];         // xyz position (point/spot) or direction TO the light (directional); w range
    vec4 light_color[32];       // rgb color * intensity; w type (0 directional, 1 point, 2 spot)
    vec4 light_dir[32];         // xyz spot axis (direction light points); w cos(spot half angle)
};

in vec3 world_pos;
in vec3 world_normal;
in vec4 world_tangent;
in vec2 uv;
in vec4 shadow_pos;
out vec4 frag_color;

const float PI = 3.14159265;

float shadow_factor(vec3 n, vec3 l) {
    if (material.z < 0.5) { return 1.0; }
    vec3 p = shadow_pos.xyz / shadow_pos.w;
    vec2 suv = p.xy * 0.5 + 0.5;
    bool is_gl = counts.z > 0.5;
    if (is_gl) { p.z = p.z * 0.5 + 0.5; } else { suv.y = 1.0 - suv.y; }
    if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0 || p.z > 1.0) { return 1.0; }
    float bias = material.w * (1.0 + 2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0)));
    float lit = 0.0;
    float texel = counts.y;
    for (int ix = -1; ix <= 1; ix++) {
        for (int iy = -1; iy <= 1; iy++) {
            float depth = textureLod(sampler2D(shadow_tex, shadow_smp), suv + vec2(float(ix), float(iy)) * texel, 0.0).r;  // explicit LOD: no gradients inside loops (HLSL X3570)
            lit += (p.z - bias <= depth) ? 1.0 : 0.0;
        }
    }
    return lit / 9.0;
}

// The environment the surface reflects: the same gradient as the sky, the horizon color (darker) below the horizon,
// and rougher surfaces see a blurrier, flatter version of it (a cheap stand-in for a prefiltered cubemap).
vec3 environment(vec3 d, float rough) {
    float blur = rough * rough;
    float h = clamp(d.y * (1.0 - 0.7 * blur), 0.0, 1.0);
    vec3 up = mix(env_horizon.rgb, env_sky.rgb, pow(h, 0.55));
    vec3 down = env_horizon.rgb * 0.55;
    float k = smoothstep(-0.05 - 0.6 * blur, 0.05 + 0.6 * blur, d.y);
    vec3 e = mix(down, up, k);
    return mix(e, 0.5 * (env_sky.rgb + env_horizon.rgb) * 0.8, blur * 0.6);
}

// Analytic split-sum environment BRDF (Karis, "Physically Based Shading on Mobile"): scale and bias of F0.
vec2 env_brdf(float rough, float ndv) {
    vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
    vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
    vec4 r = rough * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * ndv)) * r.x + r.y;
    return vec2(-1.04, 1.04) * a004 + r.zw;
}

void main() {
    vec4 texel = texture(sampler2D(tex, smp), uv);
    vec4 albedo4 = texel * base_color;
    vec3 albedo = albedo4.rgb;
    vec3 result;
    vec3 emission = emissive.rgb + model_emissive.rgb * texture(sampler2D(emissive_tex, smp), uv).rgb;
    if (emissive.w > 0.5) {
        result = albedo;
    } else {
        vec3 gn = normalize(world_normal);
        vec3 n = gn;
        if (maps.z > 0.5) {
            vec3 t = normalize(world_tangent.xyz - gn * dot(gn, world_tangent.xyz));
            vec3 b = cross(gn, t) * world_tangent.w;
            vec3 m = texture(sampler2D(normal_tex, smp), uv).xyz * 2.0 - 1.0;
            m.xy *= maps.x;
            n = normalize(t * m.x + b * m.y + gn * m.z);
        }
        if (!gl_FrontFacing) { n = -n; gn = -gn; }
        vec3 v = normalize(camera_pos.xyz - world_pos);
        vec4 mrt = texture(sampler2D(mr_tex, smp), uv);
        float metallic = clamp(material.x * mrt.b, 0.0, 1.0);
        float roughness = clamp(material.y * mrt.g, 0.05, 1.0);
        float occlusion = 1.0 + maps.y * (texture(sampler2D(occlusion_tex, smp), uv).r - 1.0);
        float alpha = roughness * roughness;
        float a2 = alpha * alpha;
        float ndv = max(dot(n, v), 1e-4);
        vec3 diffuse_color = albedo * (1.0 - metallic);
        vec3 f0 = mix(vec3(0.04), albedo, metallic);
        vec3 lit = ambient.rgb * diffuse_color * occlusion;
        int count = int(counts.x);
        for (int i = 0; i < 32; i++) {
            if (i >= count) { break; }
            float type = light_color[i].w;
            vec3 l;
            float atten = 1.0;
            if (type < 0.5) {
                l = normalize(light_pos[i].xyz);
            } else {
                vec3 to_light = light_pos[i].xyz - world_pos;
                float dist = length(to_light);
                l = to_light / max(dist, 1e-4);
                float range = max(light_pos[i].w, 1e-3);
                float x = clamp(1.0 - (dist / range) * (dist / range), 0.0, 1.0);
                atten = x * x;
                if (type > 1.5) {
                    float cos_angle = dot(-l, normalize(light_dir[i].xyz));
                    float cos_outer = light_dir[i].w;
                    atten *= smoothstep(cos_outer, mix(cos_outer, 1.0, 0.25), cos_angle);
                }
            }
            float ndl = max(dot(n, l), 0.0);
            if (type < 0.5 && i == 0) { atten *= shadow_factor(gn, l); }
            vec3 h = normalize(l + v);
            float ndh = max(dot(n, h), 0.0);
            float vdh = max(dot(v, h), 0.0);
            // Cook-Torrance: GGX distribution, height-correlated Smith visibility (Karis' approximation), Schlick Fresnel.
            float dd = ndh * ndh * (a2 - 1.0) + 1.0;
            float d_ggx = a2 / (PI * dd * dd);
            float vis = 0.5 / max(mix(2.0 * ndl * ndv, ndl + ndv, alpha), 1e-4);
            vec3 fres = f0 + (1.0 - f0) * pow(1.0 - vdh, 5.0);
            // Light colors are not divided by pi (a white light of intensity 1 lights a white diffuse surface to 1),
            // so the specular term carries the matching factor pi.
            vec3 spec = fres * (d_ggx * vis * PI) * step(0.0001, ndl);
            lit += (diffuse_color + spec) * light_color[i].rgb * (ndl * atten);
        }
        // Image-based lighting: the sky reflected, weighted by the environment BRDF.
        vec3 r = reflect(-v, n);
        vec2 ab = env_brdf(roughness, ndv);
        lit += environment(r, roughness) * (f0 * ab.x + ab.y) * occlusion;
        result = lit;
    }
    result += emission;
    if (fog.w > 0.0) {
        float dist = length(camera_pos.xyz - world_pos);
        float f = 1.0 - exp(-(fog.w * dist) * (fog.w * dist));
        result = mix(result, fog.rgb, clamp(f, 0.0, 1.0));
    }
    frag_color = vec4(result, albedo4.a);
}
@end

@program mesh vs fs
@program mesh_skin vs_skin fs
