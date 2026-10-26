// The shadow lookup shared by the light buffer pass (light.glsl) and the per-pixel lit path of quad.glsl. Not compiled on
// its own: both top files `@include light_shadow.glsl`, declare
//     layout(binding=N) uniform texture2D shadow_tex;
//     layout(binding=M) uniform sampler shadow_smp;       (a nearest sampler)
// in their fragment shader, and then `@include_block light_shadow`.
//
// shadow_tex holds one row per light that casts shadows (engine/render/src/light2d.cpp): 1024 texels, texel i is the
// direction i * 2 pi / 1024 (counter-clockwise from +x, world axes), RGBA8 with the distance light travels before the far
// side of the first solid tile in that direction as a 16-bit fraction of the light's radius: r = high byte, g = low byte.
// 65535 = nothing in the way.
@block light_shadow
float shadow_texel(float v, float i) {
    vec4 t = textureLod(sampler2D(shadow_tex, shadow_smp), vec2((i + 0.5) / 1024.0, v), 0.0);
    return (floor(t.r * 255.0 + 0.5) * 256.0 + floor(t.g * 255.0 + 0.5)) / 65535.0;
}

// How much of the light reaches the point `d` away from it (world units): 1 in the open, 0 behind a solid tile, with a
// soft edge one world unit wide and one ray's width across. `v` is the v coordinate of the light's row, `radius` its radius.
float light_shadow(float v, vec2 d, float radius) {
    float dist = length(d);
    if (dist < 0.0001) { return 1.0; }
    float a = atan(d.y, d.x);
    a = a < 0.0 ? a + 6.28318530718 : a;
    float t = a * (1024.0 / 6.28318530718);
    float i0 = min(floor(t), 1023.0);
    float f = t - i0;
    float i1 = i0 + 1.0;
    if (i1 > 1023.5) { i1 = 0.0; }
    float l0 = clamp((shadow_texel(v, i0) * radius - dist) + 0.5, 0.0, 1.0);
    float l1 = clamp((shadow_texel(v, i1) * radius - dist) + 0.5, 0.0, 1.0);
    return mix(l0, l1, f);
}
@end
