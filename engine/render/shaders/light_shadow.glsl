// The shadow lookup shared by the light buffer pass (light.glsl) and the per-pixel lit path of quad.glsl. Not compiled on
// its own: both top files `@include light_shadow.glsl`, declare
//     layout(binding=N) uniform texture2D shadow_tex;
//     layout(binding=M) uniform sampler shadow_smp;       (a nearest sampler)
// in their fragment shader, and then `@include_block light_shadow`.
//
// shadow_tex holds one row per light that casts shadows (engine/render/src/light2d.cpp): 1024 texels, texel i is the
// direction i * 2 pi / 1024 (counter-clockwise from +x, world axes), RGBA8 with the distance light travels before the far
// side of the first solid tile (or the start of the shadow of a ShadowCaster2D) in that direction as a 16-bit fraction of
// the light's radius: r = high byte, g = low byte. 65535 = nothing in the way.
//
// light_shadow_sized adds the penumbra of a light with a size (Light2D.size > 0): see docs/rendering/RENDERING_2D_SHADOWS.md.
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

// One tap of the soft shadow: the same lookup as light_shadow at the (fractional) texel position tt, which may lie outside
// 0..1024 (the ring wraps).
float light_shadow_tap(float v, float tt, float dist, float radius) {
    float i0 = floor(tt);
    float f = tt - i0;
    i0 = i0 - 1024.0 * floor(i0 / 1024.0);
    float i1 = i0 + 1.0;
    if (i1 > 1023.5) { i1 = 0.0; }
    float l0 = clamp((shadow_texel(v, i0) * radius - dist) + 0.5, 0.0, 1.0);
    float l1 = clamp((shadow_texel(v, i1) * radius - dist) + 0.5, 0.0, 1.0);
    return mix(l0, l1, f);
}

// Soft shadow of a light of radius `size` (world units), PCSS in the angle domain: 1) look for the blockers around the
// pixel's direction (the stored distances that are nearer than the pixel), 2) their mean distance b gives the half width of
// the penumbra as an angle, size * (1 / b - 1 / dist), which grows with the distance past the occluder, 3) average the hard
// lookups over that angle with a tent weight.
float light_shadow_soft(float v, float size, vec2 d, float radius) {
    float dist = length(d);
    float result = 1.0;
    if (dist >= 0.0001) {
        float a = atan(d.y, d.x);
        a = a < 0.0 ? a + 6.28318530718 : a;
        float t = a * (1024.0 / 6.28318530718);
        float search = min(size * 10.0 / dist, 0.7) * (1024.0 / 6.28318530718);   // half width in texels
        float sum = 0.0;
        float n = 0.0;
        for (int k = 0; k < 12; k++) {
            float o = (float(k) + 0.5) * (2.0 / 12.0) - 1.0;
            float tt = floor(t + o * search);
            tt = tt - 1024.0 * floor(tt / 1024.0);
            float b = shadow_texel(v, tt) * radius;
            if (b < dist) { sum += b; n += 1.0; }
        }
        if (n > 0.5) {
            float b = max(sum / n, 1.0);
            float half_angle = min(size * (1.0 / b - 1.0 / dist), 0.7) * (1024.0 / 6.28318530718);   // texels
            float acc = 0.0;
            float wsum = 0.0;
            for (int k = 0; k < 16; k++) {
                float o = (float(k) + 0.5) * (2.0 / 16.0) - 1.0;
                float w = 1.0 - 0.8 * abs(o);
                acc += w * light_shadow_tap(v, t + o * half_angle, dist, radius);
                wsum += w;
            }
            result = acc / wsum;
        }
    }
    return result;
}

// The shadow factor of a light: the hard edge for size 0 (exactly light_shadow), the penumbra otherwise.
float light_shadow_sized(float v, float size, vec2 d, float radius) {
    float r = 1.0;
    if (size > 0.0) {
        r = light_shadow_soft(v, size, d, radius);
    } else {
        r = light_shadow(v, d, radius);
    }
    return r;
}
@end
