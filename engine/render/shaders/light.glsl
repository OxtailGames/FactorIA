// FactorIA 2D light buffer: every point Light2D of the frame is one quad (its bounding square), drawn additively into an
// RGBA16F target (RGBA8 at half range where a half-float target cannot be blended) that lit sprites, tiles and shapes read
// back with their pixel position (quad.glsl). A light costs the pixels of its quad, however many visuals it shines on.
//   light = color * intensity * (1 - distance / radius)^falloff * shadow
// the same falloff the per-pixel path of quad.glsl computes. A light with a shadow row (castShadows, light2d.cpp) is also
// multiplied by how much of it gets past the solid tiles in its direction, and a light with a cookie (Light2D.cookie) by the cookie's
// brightness where the point falls on it (light_cookie.glsl).
@module light

@include light_shadow.glsl
@include light_cookie.glsl

@vs vs
layout(binding=0) uniform light_vs_params {
    mat4 view_proj;
};

layout(location=0) in vec2 corner;   // -1 or 1: the corner of the square, in radii from the light
layout(location=1) in vec4 pos;      // xy position, z height, w radius
layout(location=2) in vec4 color;    // rgb * intensity, w falloff exponent
layout(location=3) in vec4 shadow;   // x = v coordinate of the light's shadow row, -1 = no shadow; y = Light2D.size (penumbra)
layout(location=4) in vec4 cookie;   // the light's cookie cell in the atlas (light_cookie.glsl); w = 0: no cookie
layout(location=5) in vec4 cookie_xf_in;  // the cookie's projection (light_cookie.glsl)

out vec2 offset;    // from the light, in world units
out vec4 light_color;
out vec2 info;      // x = radius, y = shadow row v (or -1)
out float light_size;   // Light2D.size: 0 = hard shadow edges
out vec4 cookie_cell;
out vec4 cookie_xf;

void main() {
    vec2 world = pos.xy + corner * pos.w;
    gl_Position = view_proj * vec4(world, 0.0, 1.0);
    offset = corner * pos.w;
    light_color = color;
    info = vec2(pos.w, shadow.x);
    light_size = shadow.y;
    cookie_cell = cookie;
    cookie_xf = cookie_xf_in;
}
@end

@fs fs
layout(binding=0) uniform texture2D shadow_tex;   // a 1x1 white image when no light casts a shadow
layout(binding=1) uniform texture2D cookie_tex;   // the cookie atlas (a 1x1 white image when no light has a cookie)
layout(binding=0) uniform sampler shadow_smp;     // nearest
layout(binding=1) uniform sampler cookie_smp;     // bilinear
layout(binding=1) uniform light_fs_params {
    vec4 range;     // x = 1 / (the range the target holds: 1 for RGBA16F, 2 for RGBA8)
};

in vec2 offset;
in vec4 light_color;
in vec2 info;
in float light_size;
in vec4 cookie_cell;
in vec4 cookie_xf;
out vec4 frag_color;

@include_block light_shadow
@include_block light_cookie

void main() {
    float radius = max(info.x, 0.001);
    float att = pow(clamp(1.0 - length(offset) / radius, 0.0, 1.0), light_color.w);
    if (info.y >= 0.0) {
        att *= light_shadow_sized(info.y, light_size, offset, radius);
    }
    if (cookie_cell.w != 0.0) {
        vec3 cc = cookie_coord(cookie_cell, cookie_xf, offset);
        att *= cookie_value(textureLod(sampler2D(cookie_tex, cookie_smp), cc.xy, 0.0)) * cc.z;
    }
    frag_color = vec4(light_color.rgb * (att * range.x), 1.0);
}
@end

@program light vs fs
