// The light data of the mesh fragment shaders: the uniform block of lights and the read of one light as a LightSample. The ONE
// declaration both the mesh template (mesh_common.glsl, the engine's own meshes and the custom materials of mode "snippet") and the
// full-shader template (mesh_full_common.glsl) include with `@include_block fa_light_data`, after the block fa_types (LightSample is
// declared there); mesh_common.glsl @includes this file, so the blocks are defined for both. Nothing here is compiled on its own.
//
// Today the lights are an array of at most 32 in a uniform block, filled by Renderer collect_lights / scene_uniforms (renderer_draw.cpp)
// and bound at fragment uniform block 2. M73.1 (clustered lights, docs/design/ARCHITECTURE_RENDERING_LIGHTING.md) reads the light list
// of a fragment's cluster from a data texture instead (the slot table in render_internal.h); the functions below are the place where
// "light n of this fragment" is turned into a LightSample, so the loop (light_loop.glsl) and the snippet's fa_light(n, i) stay as they
// are when the storage changes.
@block fa_light_data
layout(binding=2) uniform fa_lights {
    vec4 fa_light_pos[32];      // xyz position (point/spot) or direction TO the light (directional); w range
    vec4 fa_light_color[32];    // rgb color * intensity; w type (0 directional, 1 point, 2 spot)
    vec4 fa_light_dir[32];      // xyz spot axis (direction light points); w cos(spot half angle)
};

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
@end
