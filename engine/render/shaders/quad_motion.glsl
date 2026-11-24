// The motion vectors and the reactive mask of the 2D quads of the world (M76-P1d): sprites, shapes, tiles, text, particles and trails,
// drawn into the camera's velocity image (RG16F) and its reactive mask (R8) after the prepass, for the temporal antialiasing and the
// temporal upscaler. Two programs of one vertex shader, each drawn in a pass of its own over the batches of the quad stream:
//   quad_vel    the velocity of the quad's pixels, only where its coverage is at least one half (an alpha-tested cutout) and the quad is in
//               front of what the prepass drew; a quad the mask marks as reactive (a blended particle) writes none: it keeps the velocity of
//               the opaque surface behind it.
//   quad_react  the reactive mask: the vertex's reactive value (0..1) times the quad's coverage, written with the MAX blend, so
//               overlapping particles do not add up past 1. The same depth test.
// The vertices are the engine's Vertex2D (position is in the world, pre-transformed; quad_common.glsl documents the modes); vertex buffer 1
// carries, per vertex, motion.xyz = how far the quad's item moved in the world since the frame before (the item's origin now minus its
// origin on the frame before; 0 for what has no history) and motion.w = the reactive value. The previous position of a vertex is then
// `position - motion.xyz` through the previous frame's view-projection: a translation only (a rotation or a scale change of the item between
// two frames is not part of it). The quad is rasterised with the matrix the colour is drawn with (the jitter of the temporal antialiasing
// included), so its coverage and depth test hit the colour's pixels, and the vectors come from the matrices without the jitter.
// Coverage per mode, as quad_common.glsl draws it: 0, 5, 6 = the texture's alpha times the tint's; 1, 2, 3 = circle, ring, soft dot;
// 4 = the glyph; 7 = a Shape2D, whose whole box counts (its rounded corners and soft edge are not followed). The +8, +16 and +32 flags
// of the mode do not change the coverage and are dropped.
@module quad_motion

@block qm_fs_common
layout(binding=0) uniform texture2D tex;
layout(binding=1) uniform texture2D pre_tex;       // the prepass (r = the view depth, a = 1 where a mesh was drawn); a 1x1 white image when not used
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform sampler pre_smp;
@image_sample_type pre_tex unfilterable_float
@sampler_type pre_smp nonfiltering
layout(binding=1) uniform quad_motion_fs_params {
    vec4 fcfg;      // x = 1 when the quad is tested against the prepass's depth (a perspective camera that drew a prepass)
};
in vec2 uv;
in vec4 color;
in vec2 params;
in vec3 vel_cur;    // the clip position x, y, w of the pixel now and on the frame before, through the unjittered matrices
in vec3 vel_prev;
in float view_depth;
in float react;
out vec4 frag_color;

// The coverage of the pixel, 0..1 (the alpha the quad pipeline would blend with).
float qm_coverage() {
    float mode = params.x;
    if (mode > 31.5) mode -= 32.0;
    if (mode > 15.5) mode -= 16.0;
    if (mode > 7.5) mode -= 8.0;
    if (mode < 0.5 || (mode > 4.5 && mode < 6.5)) return texture(sampler2D(tex, smp), uv).a * color.a;
    if (mode > 6.5) return color.a;
    if (mode > 3.5) return color.a * texture(sampler2D(tex, smp), uv).r;
    float d = length(uv);
    float aa = max(fwidth(d), 1e-4);
    float cov;
    if (mode < 1.5) {
        cov = clamp((1.0 - d) / aa + 0.5, 0.0, 1.0);
    } else if (mode < 2.5) {
        float outer = clamp((1.0 - d) / aa + 0.5, 0.0, 1.0);
        float inner = clamp((d - params.y) / aa + 0.5, 0.0, 1.0);
        cov = outer * inner;
    } else {
        float t = clamp(1.0 - d, 0.0, 1.0);
        cov = t * t * (3.0 - 2.0 * t);
    }
    return color.a * cov;
}

// True where something the prepass drew is in front of the quad (the quad's pipeline would fail its depth test).
bool qm_hidden() {
    if (fcfg.x < 0.5) return false;
    vec4 p = texelFetch(sampler2D(pre_tex, pre_smp), ivec2(gl_FragCoord.xy), 0);
    return p.a > 0.5 && view_depth > p.r * 1.0005 + 0.001;
}
@end

@vs vs
layout(binding=0) uniform quad_motion_vs_params {
    mat4 draw_vp;       // the matrix the picture is drawn with (the jitter included): where the pixels are
    mat4 cur_vp;        // this frame's view-projection, without the jitter: the motion
    mat4 prev_vp;       // the frame before's (the same one when the camera has no history)
    vec4 depth_row;     // view depth of a world point p = dot(depth_row, vec4(p, 1)) (what the prepass stores in r)
};
layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord0;
layout(location=2) in vec4 color0;
layout(location=3) in vec2 params0;
layout(location=4) in vec4 motion;

out vec2 uv;
out vec4 color;
out vec2 params;
out vec3 vel_cur;
out vec3 vel_prev;
out float view_depth;
out float react;

void main() {
    vec4 cur = cur_vp * vec4(position, 1.0);
    vec4 prev = prev_vp * vec4(position - motion.xyz, 1.0);
    gl_Position = draw_vp * vec4(position, 1.0);  // as the colour and the prepass: the same pixels, and the jitter is not part of the motion
    uv = texcoord0;
    color = color0;
    params = params0;
    vel_cur = cur.xyw;
    vel_prev = prev.xyw;
    view_depth = dot(depth_row, vec4(position, 1.0));
    react = motion.w;
}
@end

@fs fs_vel
@include_block qm_fs_common
void main() {
    if (react > 0.0 || qm_coverage() < 0.5 || qm_hidden()) discard;
    vec2 m = vec2(1024.0);
    if (vel_cur.z > 1.0e-5 && vel_prev.z > 1.0e-5) {
        vec2 uv_cur = vec2(vel_cur.x, -vel_cur.y) / vel_cur.z * 0.5;
        vec2 uv_prev = vec2(vel_prev.x, -vel_prev.y) / vel_prev.z * 0.5;
        m = clamp(uv_prev - uv_cur, vec2(-4.0), vec2(4.0));
    }
    frag_color = vec4(m, 0.0, 0.0);
}
@end

@fs fs_react
@include_block qm_fs_common
void main() {
    if (react <= 0.0 || qm_hidden()) discard;
    float r = clamp(react * qm_coverage(), 0.0, 1.0);
    if (r <= 0.0) discard;
    frag_color = vec4(r, 0.0, 0.0, 0.0);
}
@end

@program quad_vel vs fs_vel
@program quad_react vs fs_react
