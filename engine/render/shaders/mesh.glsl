// FactorIA 3D mesh shader: ambient + up to 8 directional/point/spot lights,
// Blinn-Phong shading driven by metallic/roughness, emissive, fog, optional
// directional shadow map.
@module mesh

@vs vs
layout(binding=0) uniform mesh_vs_params {
    mat4 mvp;
    mat4 model;
    mat4 normal_mat;
    mat4 light_vp;      // directional shadow matrix (world -> light clip)
    vec4 uv_scale;      // xy
};

layout(location=0) in vec3 position;
layout(location=1) in vec3 normal;
layout(location=2) in vec2 texcoord0;

out vec3 world_pos;
out vec3 world_normal;
out vec2 uv;
out vec4 shadow_pos;

void main() {
    vec4 wp = model * vec4(position, 1.0);
    world_pos = wp.xyz;
    world_normal = mat3(normal_mat) * normal;
    uv = texcoord0 * uv_scale.xy;
    shadow_pos = light_vp * wp;
    gl_Position = mvp * vec4(position, 1.0);
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=1) uniform texture2D shadow_tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform sampler shadow_smp;
@image_sample_type shadow_tex unfilterable_float
@sampler_type shadow_smp nonfiltering

layout(binding=1) uniform mesh_fs_params {
    vec4 camera_pos;            // xyz
    vec4 ambient;               // rgb
    vec4 base_color;
    vec4 emissive;              // rgb, w = 1 when unlit
    vec4 material;              // x metallic, y roughness, z receive shadow (0/1), w shadow depth bias
    vec4 fog;                   // rgb color, w density
    vec4 counts;                // x = light count, y = shadow texel size, z = 1 on OpenGL backends
    vec4 light_pos[8];          // xyz position (point/spot) or direction TO the light (directional); w range
    vec4 light_color[8];        // rgb color * intensity; w type (0 directional, 1 point, 2 spot)
    vec4 light_dir[8];          // xyz spot axis (direction light points); w cos(spot half angle)
};

in vec3 world_pos;
in vec3 world_normal;
in vec2 uv;
in vec4 shadow_pos;
out vec4 frag_color;

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

void main() {
    vec4 texel = texture(sampler2D(tex, smp), uv);
    vec4 albedo4 = texel * base_color;
    vec3 albedo = albedo4.rgb;
    vec3 result;
    if (emissive.w > 0.5) {
        result = albedo;
    } else {
        vec3 n = normalize(world_normal);
        if (!gl_FrontFacing) { n = -n; }
        vec3 v = normalize(camera_pos.xyz - world_pos);
        float metallic = material.x;
        float roughness = clamp(material.y, 0.04, 1.0);
        vec3 diffuse_color = albedo * (1.0 - metallic);
        vec3 spec_color = mix(vec3(0.04), albedo, metallic);
        float shininess = mix(96.0, 4.0, roughness);
        float spec_strength = (1.0 - roughness * 0.75) * (shininess + 8.0) / 25.0;
        vec3 lit = ambient.rgb * diffuse_color;
        int count = int(counts.x);
        for (int i = 0; i < 8; i++) {
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
            if (type < 0.5 && i == 0) { atten *= shadow_factor(n, l); }
            vec3 h = normalize(l + v);
            float spec = pow(max(dot(n, h), 0.0), shininess) * spec_strength * step(0.0001, ndl);
            lit += (diffuse_color + spec_color * spec) * light_color[i].rgb * (ndl * atten);
        }
        result = lit;
    }
    result += emissive.rgb;
    if (fog.w > 0.0) {
        float dist = length(camera_pos.xyz - world_pos);
        float f = 1.0 - exp(-(fog.w * dist) * (fog.w * dist));
        result = mix(result, fog.rgb, clamp(f, 0.0, 1.0));
    }
    frag_color = vec4(result, albedo4.a);
}
@end

@program mesh vs fs
