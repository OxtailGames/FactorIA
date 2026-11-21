// The cookie lookup shared by the light buffer pass (light.glsl) and the per-pixel lit path of quad.glsl (M74, Light2D.cookie). Not
// compiled on its own: both top files `@include light_cookie.glsl` and, in their fragment shader, `@include_block light_cookie`.
//
// The cookies of a frame are copied into one atlas (engine/render/src/renderer_lights2d.cpp): kCookieGrid x kCookieGrid cells, one per
// distinct cookie texture. A light carries its cell as `cell` = (u origin, v origin, v step, u step) in the atlas's own sampling
// coordinates (the v step is negative on OpenGL, whose render targets are stored upside down), and its projection as `xf` = (cos, sin of
// the cookie's turn, 1 / the cookie's width in world units).
@block light_cookie
// The atlas coordinate of the point `off` (world units from the light) in the light's cookie, and in z whether the point lies on the cookie
// at all (1) or beyond its edge (0, the light is cut off there). The cookie's up is the world's up.
vec3 cookie_coord(vec4 cell, vec4 xf, vec2 off) {
    vec2 q = vec2(xf.x * off.x + xf.y * off.y, xf.x * off.y - xf.y * off.x) * xf.z;
    vec2 c = vec2(q.x + 0.5, 0.5 - q.y);
    float inside = (c.x >= 0.0 && c.x <= 1.0 && c.y >= 0.0 && c.y <= 1.0) ? 1.0 : 0.0;
    c = clamp(c, vec2(0.001953125), vec2(0.998046875));   // half a texel of a 256 px cell: never read the next cell
    return vec3(cell.x + c.x * cell.w, cell.y + c.y * cell.z, inside);
}
// How much light the cookie lets through at a texel: its brightness times its alpha (a white shape on a transparent picture, or a grey
// picture, both work).
float cookie_value(vec4 t) {
    return dot(t.rgb, vec3(0.2126, 0.7152, 0.0722)) * t.a;
}
@end
