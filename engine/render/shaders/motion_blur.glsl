// FactorIA camera motion blur (PostProcess.motionBlurEnabled, M71-D2): each pixel is smeared along the way it moved on the screen since the
// frame before, which only the camera's own movement made it do (a moving object has no velocity of its own here).
//
// The pixel's view-space position comes from the linear depth of the prepass and the camera's projection; `m` (the matrix of the camera
// of the frame before times the inverse view matrix of this one, made on the CPU) takes that position to the previous frame's clip space.
// The velocity is the difference of the two screen positions, clamped to a length, and the picture is sampled along it with a few taps whose
// offset is jittered by a fixed pattern (interleaved gradient noise), so the same frame is drawn on every run.
//
// One full-screen triangle over ONE camera's rectangle of the picture, as dof.glsl: `uv` is the texture coordinate of the image being
// drawn, `s` the camera-local top-left coordinate. The source picture is read at fl(s * rc.zw + rc.xy); the prepass has the size of the
// rectangle and is read at fl(s).
@module motion_blur

@vs vs
layout(binding=0) uniform motion_vs_params {
    vec4 flip;      // x = 1 when render targets have their origin at the bottom (OpenGL), 0 otherwise
};
layout(location=0) in vec2 pos;
out vec2 uv;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    float v_top_down = 0.5 - pos.y * 0.5;
    float v_bottom_up = 0.5 + pos.y * 0.5;
    uv = vec2(pos.x * 0.5 + 0.5, mix(v_top_down, v_bottom_up, flip.x));
}
@end

@fs fs_motion
layout(binding=0) uniform texture2D tex_c;
layout(binding=1) uniform texture2D tex_p;
layout(binding=0) uniform sampler smp_lin;
layout(binding=1) uniform sampler smp_pt;
@image_sample_type tex_p unfilterable_float
@sampler_type smp_pt nonfiltering
layout(binding=1) uniform motion_params {
    vec4 a;         // x = 1 when render targets are bottom-up (OpenGL), yz = the camera's rectangle in pixels, w = 0
    vec4 rc;        // the rectangle of the source picture the pass covers (top-left, fractions of the picture): xy corner, zw size; 0 0 1 1 for a scratch image
    vec4 b;         // x = shutter (the part of the movement that is blurred, 0 .. 1), y = longest streak in pixels, z = most taps, w = 0
    vec4 pa;        // the projection of the camera: P00, P11, P02, P12 (what the view-space position of a pixel needs)
    vec4 pb;        // P03, P13, P32, P33
    mat4 m;         // previous view-projection * inverse view: a view-space position of this frame -> the clip position it had in the frame before
};
in vec2 uv;
out vec4 frag_color;

vec2 fl(vec2 s) { return vec2(s.x, mix(s.y, 1.0 - s.y, a.x)); }
vec2 game_uv(vec2 s) { return fl(s * rc.zw + rc.xy); }
float ign(vec2 p) { return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715)))); }

void main() {
    vec2 size = a.yz;
    vec2 s = fl(uv);
    vec4 here = textureLod(sampler2D(tex_c, smp_lin), game_uv(s), 0.0);
    vec4 pre = textureLod(sampler2D(tex_p, smp_pt), fl(s), 0.0);
    // Where nothing was drawn (the sky) the position is far away: only the camera's turning moves it.
    float d = pre.a > 0.5 ? pre.r : 60000.0;
    vec2 ndc = vec2(s.x * 2.0 - 1.0, 1.0 - s.y * 2.0);
    float z = -d;
    float w = pb.z * z + pb.w;                       // clip w: -z for a perspective camera, 1 for an orthographic one
    vec3 vp = vec3((ndc.x * w - pa.z * z - pb.x) / pa.x, (ndc.y * w - pa.w * z - pb.y) / pa.y, z);
    vec4 pc = m * vec4(vp, 1.0);
    vec2 v_px = vec2(0.0);
    if (pc.w > 1e-4) {
        vec2 pndc = pc.xy / pc.w;
        vec2 dn = ndc - pndc;                        // how far the pixel moved, in ndc
        v_px = vec2(dn.x, -dn.y) * 0.5 * size * b.x; // in pixels, top-left
        float len = length(v_px);
        if (len > b.y) v_px *= b.y / len;
    }
    float len_px = length(v_px);
    if (len_px < 0.5) {
        frag_color = here;
        return;
    }
    int n = int(clamp(ceil(len_px * 0.5), 3.0, b.z));
    float jitter = ign(floor(s * size));
    vec3 acc = here.rgb;
    float wsum = 1.0;
    vec2 lo = 0.5 / size;
    for (int i = 0; i < 64; i++) {
        if (i >= n) break;
        float t = (float(i) + jitter) / float(n) - 0.5;   // -0.5 .. 0.5: the streak is centred on the pixel
        vec2 ts = clamp(s + v_px / size * t, lo, 1.0 - lo);  // stays inside the camera's rectangle
        acc += textureLod(sampler2D(tex_c, smp_lin), game_uv(ts), 0.0).rgb;
        wsum += 1.0;
    }
    frag_color = vec4(acc / wsum, here.a);
}
@end

@program motion vs fs_motion
