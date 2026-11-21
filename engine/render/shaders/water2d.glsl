// FactorIA 2D scene-colour effects (M74.4): the built-in Water2D and DistortionZone2D, and the copy of the picture they (and the sprite
// materials that call fa_scene_color) read. Two programs:
//
//   copy  one full-screen triangle into a transient image the size of the camera's rectangle: every pixel is the pixel of the game
//         image at (the rectangle's corner + the pixel), by texelFetch, so the copy is exact and keeps the image rows of the target (bottom
//         first in OpenGL, top first elsewhere, the same as the source).
//   fx    one quad (the area, from the vertex stream of the 2D renderer: position only) that reads the copy: the water (refraction of what
//         is under the surface, the reflection of what is above it mirrored about the surface line, a thin highlight at the surface) or
//         the ripple of a zone (kind 1). Both read the picture through scene_at(), the same mapping as fa_scene_color() in quad_common.glsl.
//
// Coordinates. "screen uv" is 0..1 over the render target with y running DOWN on every backend. The copy covers the camera's rectangle of
// the target, so `scene` (xy scale, zw offset) maps a screen uv to a position in the copy and `target.z` flips its v where render targets
// are bottom-up (OpenGL), like fa_scene / fa_target in the quad uniforms. `world_uv` is the camera's view-projection already turned into
// screen uv (quad_common.glsl, fa_world_uv): the screen uv of a world point is (row0 . p, row1 . p) / (row2 . p), p = (x, y, z, 1).
@module water2d

@vs copy_vs
layout(location=0) in vec2 pos;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
}
@end

@fs copy_fs
layout(binding=0) uniform texture2D src;
layout(binding=0) uniform sampler src_smp;
layout(binding=0) uniform water2d_copy_params {
    vec4 origin;    // xy = the corner of the camera's rectangle in the source image, in its own rows
};
out vec4 frag_color;
void main() {
    frag_color = texelFetch(sampler2D(src, src_smp), ivec2(gl_FragCoord.xy) + ivec2(origin.xy), 0);
}
@end

@program copy copy_vs copy_fs

@vs fx_vs
layout(binding=0) uniform water2d_vs_params {
    mat4 view_proj;
};
layout(location=0) in vec3 position;
out vec2 world_xy;
void main() {
    world_xy = position.xy;
    gl_Position = view_proj * vec4(position, 1.0);
}
@end

@fs fx_fs
layout(binding=0) uniform texture2D scene_tex;
layout(binding=0) uniform sampler scene_smp;
layout(binding=1) uniform water2d_fs_params {
    vec4 area;      // xy = the middle of the surface (water) or the centre (zone), zw = the unit up axis of the area, in the world
    vec4 shape;     // xy = width (across the axis) and height (along it) in world units, z = kind (0 water, 1 zone), w = seconds
    vec4 tint;      // water: rgb colour in the scene's space, a = opacity of the body
    vec4 wave;      // x = reflection, y = refraction in pixels (a zone: strength in pixels), z = amplitude, w = wave length (world units)
    vec4 misc;      // x = waves per second
    vec4 target;    // xy = 1 / the size of the render target in pixels, z = 1 where render targets are bottom-up (OpenGL)
    vec4 scene;     // screen uv * xy + zw = the position in the copy of the picture (0..1, y down)
    vec4 world_uv[3];
};
in vec2 world_xy;
out vec4 frag_color;

const float TAU = 6.2831853;

vec2 screen_uv() {
    vec2 p = gl_FragCoord.xy * target.xy;
    return vec2(p.x, mix(p.y, 1.0 - p.y, target.z));
}

// The position in the copy (0..1, y down) of a screen uv, and the picture there (clamped at the edge of the picture).
vec2 scene_pos(vec2 uv) {
    return uv * scene.xy + scene.zw;
}
vec4 scene_at(vec2 uv) {
    vec2 p = clamp(scene_pos(uv), vec2(0.0), vec2(1.0));
    p.y = mix(p.y, 1.0 - p.y, target.z);
    return textureLod(sampler2D(scene_tex, scene_smp), p, 0.0);
}

vec2 world_to_uv(vec2 xy) {
    vec4 q = vec4(xy, 0.0, 1.0);
    float w = dot(world_uv[2], q);
    return vec2(dot(world_uv[0], q), dot(world_uv[1], q)) / (abs(w) > 1e-6 ? w : 1.0);
}

void water() {
    vec2 up = area.zw;
    vec2 side = vec2(up.y, -up.x);
    vec2 rel = world_xy - area.xy;
    float h = dot(rel, up);          // height above the surface at rest; negative under it
    float t = dot(rel, side);        // position along the surface
    float len = max(wave.w, 0.1);
    float phase = TAU * (t / len + shape.w * misc.x);
    // The surface: two sines, so the crests are not all alike.
    float s = (sin(phase) * 0.7 + sin(phase * 2.17 + 1.3) * 0.3) * wave.z;
    float depth = s - h;             // how far under the moving surface (negative = above it: not water)
    float px = max(fwidth(h), 1e-4); // world units of one pixel
    float cover = clamp(depth / px + 0.5, 0.0, 1.0);
    float deep = clamp(depth / max(shape.y, 1e-3), 0.0, 1.0);

    // What is under the surface, pushed about by the waves (pixels), tinted.
    vec2 off = vec2(sin(TAU * (world_xy.y / (len * 0.5) - shape.w * misc.x * 1.3)),
                    0.5 * sin(TAU * (world_xy.x / len + shape.w * misc.x))) * wave.y;
    vec2 uv = screen_uv();
    vec3 seen = scene_at(uv + off * target.xy).rgb;
    vec3 body = mix(seen, tint.rgb, tint.a) * (1.0 - 0.35 * deep);

    // What is above it: the picture at the mirror image of this point about the moving surface, with the same waves.
    vec2 mirror = world_xy - 2.0 * (h - s) * up;
    vec2 ruv = world_to_uv(mirror) + off * target.xy * 1.5;
    vec2 rp = scene_pos(ruv);
    float edge = min(min(rp.x, 1.0 - rp.x), min(rp.y, 1.0 - rp.y));
    float visible = smoothstep(0.0, 0.1, edge);   // fades where the mirrored point leaves the screen
    vec3 mirrored = scene_at(ruv).rgb;
    float refl = wave.x * visible * (1.0 - 0.6 * deep);
    vec3 col = mix(body, mirrored, refl);

    // The thin highlight along the surface.
    float hl = 1.0 - smoothstep(px * 0.5, px * 2.5, depth);
    col = mix(col, mix(tint.rgb, vec3(1.0), 0.75), hl * 0.9);
    frag_color = vec4(col, cover);
}

void zone() {
    vec2 up = area.zw;
    vec2 side = vec2(up.y, -up.x);
    vec2 rel = world_xy - area.xy;
    vec2 q = abs(vec2(dot(rel, side), dot(rel, up))) / max(shape.xy * 0.5, vec2(1e-3));
    float weight = 1.0 - smoothstep(0.7, 1.0, max(q.x, q.y));   // nothing at the edge: the zone has no border
    vec2 off = vec2(sin(TAU * (world_xy.y / 20.0 - shape.w * 1.5)), 0.4 * sin(TAU * (world_xy.x / 28.0 + shape.w * 1.1))) * wave.y;
    frag_color = vec4(scene_at(screen_uv() + off * weight * target.xy).rgb, 1.0);
}

void main() {
    if (shape.z < 0.5) water(); else zone();
}
@end

@program fx fx_vs fx_fs
