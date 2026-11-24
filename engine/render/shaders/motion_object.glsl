// FactorIA per-object motion blur (PostProcess.motionBlurMode "object", M76-P1e): every pixel is smeared along its OWN motion, read from the
// velocity image of the depth prepass (RG16F, uvPrev - uvCurr, the sentinel 1024 where no object wrote one), so a moving object blurs along
// the way it moved and a still one next to it stays sharp. A reconstruction filter in the manner of McGuire et al., "A Fast and Stable
// Feature-Aware Motion Blur Filter" (2012), in four passes over ONE camera's rectangle of the picture:
//
//   vel      velocity image + prepass -> V (RGBA16F, the size of the rectangle): rg = the blur vector in pixels (the velocity times the shutter,
//            cut to the longest streak; where the velocity is the sentinel, the camera's own movement reconstructed from the depth exactly as
//            motion_blur.glsl does), b = the linear view depth (60000 for the sky), a = 0
//   tile     V -> the longest vector of every K x K block of pixels (K = the largest blur radius), in two passes (a row of blocks, then the
//            blocks): axis 0 reads V and writes (tiles across, rows), axis 1 reads that and writes (tiles across, tiles down)
//   gather   picture + V + tiles -> the picture (or the scratch): the longest vector of the 3 x 3 tiles around the pixel gives the direction
//            of the streak, and taps along it (and along the pixel's own vector) are weighted by the depth order of the tap and the pixel and
//            by how far each one's own blur reaches (a cone), with a cylinder for two things that move alike. A tap on a fast object over a
//            slower pixel is added (the object's blur covers it); a tap on something behind a fast pixel is added only as far as that pixel's
//            own blur reaches; so a fast object has a soft edge over a sharp background and the background never smears INTO the object.
//
// Coordinates, as dof.glsl: `uv` is the texture coordinate of the image being drawn, `s` the camera-local top-left coordinate; every image of
// the pass is read at fl(s) (texture space, so the texel numbers of V and of the tiles agree on every backend); the picture at
// fl(s * rc.zw + rc.xy). The taps are jittered by a fixed pattern (interleaved gradient noise): the same frame is drawn on every run.
@module motion_object

@vs vs
layout(binding=0) uniform mobj_vs_params {
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

@block common
layout(binding=1) uniform mobj_params {
    vec4 a;         // x = 1 when render targets are bottom-up (OpenGL), yz = the camera's rectangle in pixels, w = the tile size K in pixels
    vec4 rc;        // the rectangle of the source picture the pass covers (top-left, fractions of the picture): xy corner, zw size; 0 0 1 1 for a scratch image
    vec4 b;         // x = shutter (0 .. 1), y = the longest streak in pixels (twice the largest blur radius), z = most taps, w = 0
    vec4 e;         // x = the axis of the tile pass (0 across, 1 down), yz = the size of the tile image in tiles, w = 0
    vec4 pa;        // the projection of the camera: P00, P11, P02, P12 (what the view-space position of a pixel needs)
    vec4 pb;        // P03, P13, P32, P33
    mat4 m;         // previous view-projection * inverse view: a view-space position of this frame -> the clip position it had in the frame before
};

vec2 fl(vec2 s) { return vec2(s.x, mix(s.y, 1.0 - s.y, a.x)); }
vec2 game_uv(vec2 s) { return fl(s * rc.zw + rc.xy); }
float ign(vec2 p) { return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715)))); }
@end

// ---- vel: the blur vector and the depth of every pixel ---------------------------------------------------------
@fs fs_vel
layout(binding=1) uniform texture2D tex_v;
layout(binding=2) uniform texture2D tex_p;
layout(binding=1) uniform sampler smp_pt;
@image_sample_type tex_v unfilterable_float
@image_sample_type tex_p unfilterable_float
@sampler_type smp_pt nonfiltering
@include_block common
in vec2 uv;
out vec4 frag_color;
void main() {
    vec2 size = a.yz;
    vec2 s = fl(uv);
    vec4 pre = textureLod(sampler2D(tex_p, smp_pt), fl(s), 0.0);
    float d = pre.a > 0.5 ? pre.r : 60000.0;
    vec2 vel = textureLod(sampler2D(tex_v, smp_pt), fl(s), 0.0).rg;
    vec2 v_px = vec2(0.0);
    if (abs(vel.x) < 512.0 && abs(vel.y) < 512.0) {
        // An object wrote it: uvPrev - uvCurr (y down) over the rectangle.
        v_px = vel * size * b.x;
    } else {
        // Nobody wrote it: the camera's own movement from the depth (motion_blur.glsl), as the same uvPrev - uvCurr in pixels.
        vec2 ndc = vec2(s.x * 2.0 - 1.0, 1.0 - s.y * 2.0);
        float z = -d;
        float w = pb.z * z + pb.w;
        vec3 vp = vec3((ndc.x * w - pa.z * z - pb.x) / pa.x, (ndc.y * w - pa.w * z - pb.y) / pa.y, z);
        vec4 pc = m * vec4(vp, 1.0);
        if (pc.w > 1e-4) {
            vec2 pndc = pc.xy / pc.w;
            vec2 dn = ndc - pndc;
            v_px = vec2(-dn.x, dn.y) * 0.5 * size * b.x;
        }
    }
    float len = length(v_px);
    if (len > b.y) v_px *= b.y / len;
    frag_color = vec4(v_px, d, 0.0);
}
@end

// ---- tile: the longest vector of a block ------------------------------------------------------------------------
@fs fs_tile
layout(binding=1) uniform texture2D tex_v;
layout(binding=1) uniform sampler smp_pt;
@include_block common
in vec2 uv;
out vec4 frag_color;
void main() {
    bool down = e.x > 0.5;
    ivec2 out_size = down ? ivec2(e.yz) : ivec2(int(e.y), int(a.z));
    ivec2 o = clamp(ivec2(floor(uv * vec2(out_size))), ivec2(0), out_size - ivec2(1));
    int k = int(a.w + 0.5);
    int src_len = down ? int(a.z) : int(a.y);
    vec2 best = vec2(0.0);
    float best_len = -1.0;
    for (int i = 0; i < 128; i++) {
        if (i >= k) break;
        int c = (down ? o.y : o.x) * k + i;
        if (c >= src_len) break;
        vec2 v = texelFetch(sampler2D(tex_v, smp_pt), down ? ivec2(o.x, c) : ivec2(c, o.y), 0).rg;
        float l = dot(v, v);
        if (l > best_len) {
            best_len = l;
            best = v;
        }
    }
    frag_color = vec4(best, 0.0, 0.0);
}
@end

// ---- gather: the blurred picture --------------------------------------------------------------------------------
@fs fs_gather
layout(binding=0) uniform texture2D tex_c;
layout(binding=1) uniform texture2D tex_v;
layout(binding=3) uniform texture2D tex_t;
layout(binding=0) uniform sampler smp_lin;
layout(binding=1) uniform sampler smp_pt;
@image_sample_type tex_t unfilterable_float
@include_block common
in vec2 uv;
out vec4 frag_color;

// 1 when `za` is not behind `zb` (a pixel in front of, or level with, another), falling to 0 over a depth that grows with the distance.
float soft_front(float za, float zb) {
    float ext = 0.1 + 0.03 * min(za, zb);
    return clamp(1.0 - (za - zb) / ext, 0.0, 1.0);
}
// The share of a pixel's own streak (its blur vector of length v) that covers a point `dist` pixels from it, per pixel of streak: a cone
// that is 1/v at the pixel and 0 at v.
float cone(float dist, float v) { return v < 0.5 ? 0.0 : clamp(1.0 - dist / v, 0.0, 1.0) / v; }
// 1 inside the streak of a pixel and 0 beyond it, softly.
float cyl(float dist, float v) { return v < 0.5 ? 0.0 : 1.0 - smoothstep(0.95 * v, 1.05 * v, dist); }

void main() {
    vec2 size = a.yz;
    vec2 s = fl(uv);
    vec4 here = textureLod(sampler2D(tex_c, smp_lin), game_uv(s), 0.0);
    ivec2 isize = ivec2(size);
    ivec2 ip = clamp(ivec2(floor(uv * size)), ivec2(0), isize - ivec2(1));
    int k = int(a.w + 0.5);
    ivec2 tc = ip / ivec2(k);
    ivec2 nt = ivec2(e.yz);
    // The longest vector of the 3 x 3 tiles around this pixel's: the direction and the length of the streak that can reach it.
    vec2 vn = vec2(0.0);
    float vn_len = -1.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            ivec2 t = clamp(tc + ivec2(i, j), ivec2(0), nt - ivec2(1));
            vec2 v = texelFetch(sampler2D(tex_t, smp_pt), t, 0).rg;
            float l = dot(v, v);
            if (l > vn_len) {
                vn_len = l;
                vn = v;
            }
        }
    }
    float ln = length(vn);
    if (ln < 0.5) {
        frag_color = here;
        return;
    }
    vec4 vx4 = texelFetch(sampler2D(tex_v, smp_pt), ip, 0);
    vec2 vx = vx4.rg;
    float zx = vx4.b;
    float lx = length(vx);
    bool own_line = lx >= 0.5;
    int n = int(clamp(ceil(ln * 0.5), 3.0, b.z));
    float per_line = own_line ? float(n) * 0.5 : float(n);  // taps along each of the two lines
    float jitter = ign(floor(s * size));
    // The pixel itself: the share of its own streak that falls on one pixel (a pixel that does not move keeps all of it).
    float w0 = 1.0 / max(lx, 1.0);
    vec3 acc = here.rgb * w0;
    float wsum = w0;
    vec2 lo = vec2(0.5) / size;
    for (int i = 0; i < 32; i++) {
        if (i >= n) break;
        bool own = own_line && (i & 1) == 1;
        vec2 line = own ? vx : vn;
        float t = (float(i) + jitter) / float(n) - 0.5;   // the streak is centred on the pixel
        vec2 off = line * t;
        vec2 ts = clamp(s + off / size, lo, vec2(1.0) - lo);   // stays inside the camera's rectangle
        float dist = length(off);
        vec4 vy4 = textureLod(sampler2D(tex_v, smp_pt), fl(ts), 0.0);
        float ly = length(vy4.rg);
        float zy = vy4.b;
        float front = soft_front(zy, zx);    // the tap is in front of the pixel
        float back = soft_front(zx, zy);     // the pixel is in front of the tap
        float wt = front * cone(dist, ly) + back * cone(dist, lx) + 2.0 * cyl(dist, ly) * cyl(dist, lx) / max(max(lx, ly), 1.0);
        wt *= length(line) / per_line;       // the pixels of the streak this tap stands for
        acc += textureLod(sampler2D(tex_c, smp_lin), game_uv(ts), 0.0).rgb * wt;
        wsum += wt;
    }
    frag_color = vec4(acc / wsum, here.a);
}
@end

@program vel vs fs_vel
@program tile vs fs_tile
@program gather vs fs_gather
