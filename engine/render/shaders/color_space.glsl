// The sRGB transfer functions, shared by quad.glsl, mesh_common.glsl and blit.glsl (SceneSettings.colorSpace "linear", M71).
// Not compiled on its own: a top file `@include color_space.glsl` and then `@include_block color_space` in each stage that
// converts. The CPU side is engine/render/src/color_space.h (same formula).
@block color_space
vec3 fa_srgb_to_linear(vec3 c) {
    c = max(c, vec3(0.0));
    vec3 lo = c / 12.92;
    vec3 hi = pow((c + 0.055) / 1.055, vec3(2.4));
    return mix(hi, lo, step(c, vec3(0.04045)));
}
vec3 fa_linear_to_srgb(vec3 c) {
    c = max(c, vec3(0.0));
    vec3 lo = c * 12.92;
    vec3 hi = 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055;
    return mix(hi, lo, step(c, vec3(0.0031308)));
}
// The colour space fix of a texture sample: 0 = as sampled, 1 = sRGB-encoded values -> linear (a colour texture the GPU did not
// decode), 2 = linear -> sRGB-encoded (a data texture, or any texture in a gamma scene, that the GPU decoded as sRGB).
vec3 fa_tex_fix(vec3 c, float mode) {
    // Explicit branches on a uniform: a gamma scene (mode 0) skips both pow() blocks instead of computing and discarding them.
    if (mode > 1.5) {
        c = fa_linear_to_srgb(c);
    } else if (mode > 0.5) {
        c = fa_srgb_to_linear(c);
    }
    return c;
}
@end
