// FactorIA's own spatio-temporal denoiser for the ray traced signals (M79-P1n; docs/design/ARCHITECTURE_DENOISE.md): temporal accumulation
// with reprojection, then a variance-guided a-trous wavelet filter (the family of SVGF and A-SVGF; the code is our own). Every program is a
// full-screen fragment pass at the size of the camera's rectangle, so it runs on every backend that draws the post effects (never a compute
// shader). renderer: engine/render/src/rt_denoise.cpp declares the passes of the frame graph.
//
//   guide     the prepass of this frame -> the guide history: r = linear view depth (0 where nothing was drawn), gba = the WORLD-space normal
//             (the next frame compares normals across a turn of the camera)
//   temporal  the noisy signal + the prepass + the velocity + the history of the frame before -> location 0: the accumulated colour in rgb and
//             the variance OF THE ESTIMATE in a; location 1: the moments (r, g = first and second moment of the luminance, b = the history
//             length in frames, a = the accumulated hit distance of a specular signal)
//   atrous    one wavelet iteration (step 1, 2, 4, 8, 16 pixels): the 5x5 B3 spline kernel, every tap weighted by the plane distance, the normal
//             and the luminance difference measured in standard deviations of the variance (the variance is filtered with the squared weights)
//   debug     the history length or the variance as a grey picture (the "views" of the module)
//
// The signal kinds (uniform `s.y`): 0 visibility (a shadow: one channel), 1 occlusion (one channel), 2 diffuse radiance (rgb), 3 specular radiance
// (rgb + the hit distance in a, in world units, < 0 = the ray missed). A one-channel signal is read from r and written to r, g and b alike.
//
// Nothing is random and nothing depends on the frame number: the same inputs give the same picture. A pixel without a mesh (the prepass a = 0)
// passes the signal through and keeps no history.
//
// Where things are: every image is the size of the camera's rectangle, so a pixel of one is the pixel of every other and the passes fetch with
// the texture-space uv of the pixel being drawn (the vertex shader flips it on OpenGL). Where the picture's top-down uv matters (the motion
// vector, the reprojection) rtd_top turns it back.
@module rt_denoise

@image_sample_type tex_n unfilterable_float
@image_sample_type tex_p unfilterable_float
@image_sample_type tex_v unfilterable_float
@image_sample_type tex_hc unfilterable_float
@image_sample_type tex_hm unfilterable_float
@image_sample_type tex_hg unfilterable_float
@image_sample_type tex_c unfilterable_float
@image_sample_type tex_r unfilterable_float
@sampler_type smp_pt nonfiltering

@vs vs
layout(binding=0) uniform rtd_vs_params {
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

@block rtd_common
const float RTD_FAR = 60000.0;

// A NaN test by the bits of the float: a GPU compiler that assumes "no NaN" may drop isnan(), but not this.
bool rtd_nanf(float x) { return (floatBitsToUint(x) & 0x7fffffffu) > 0x7f800000u; }
bool rtd_nan3(vec3 c) { return rtd_nanf(c.x) || rtd_nanf(c.y) || rtd_nanf(c.z); }

// The prepass's octahedral decode (prepass_view.glsl).
vec3 rtd_oct_decode(vec2 e) {
    vec3 n = vec3(e.x, e.y, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) {
        n.xy = (1.0 - abs(n.yx)) * vec2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0);
    }
    return normalize(n);
}

// The luminance the edge-stopping and the variance work on: the one channel of a one-channel signal, else Rec. 709.
float rtd_luma(vec3 c, float channels) {
    return channels < 1.5 ? c.r : dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// The 1D B3 spline kernel of the a-trous filter at tap i = -2..2.
float rtd_kernel(int i) {
    int k = abs(i);
    return k == 0 ? 0.375 : (k == 1 ? 0.25 : 0.0625);
}

// The view-space position of the surface at the picture's top-down uv with linear depth d (cam: xy = what a unit of normalised device
// coordinates is in view space at depth 1, or at any depth for an orthographic camera, z = 1 for an orthographic one).
vec3 rtd_view_pos(vec2 suv, float d, vec4 cam) {
    vec2 ndc = vec2(suv.x * 2.0 - 1.0, 1.0 - 2.0 * suv.y);
    float k = cam.z > 0.5 ? 1.0 : d;
    return vec3(ndc.x * cam.x * k, ndc.y * cam.y * k, -d);
}
@end

// ---------------------------------------------------------------------------------------------------------------------------------------
@fs fs_guide
layout(binding=1) uniform texture2D tex_p;
layout(binding=0) uniform sampler smp_pt;
layout(binding=1) uniform rtd_guide_params {
    vec4 wx;   // xyz = what a view-space normal's x becomes in the world: the first column of the view matrix's rotation
    vec4 wy;
    vec4 wz;
};
in vec2 uv;
out vec4 frag_color;
@include_block rtd_common

void main() {
    vec4 pre = textureLod(sampler2D(tex_p, smp_pt), uv, 0.0);
    if (pre.a < 0.5) {
        frag_color = vec4(0.0);
        return;
    }
    vec3 n = rtd_oct_decode(pre.gb);
    vec3 nw = normalize(vec3(dot(wx.xyz, n), dot(wy.xyz, n), dot(wz.xyz, n)));
    frag_color = vec4(max(pre.r, 1e-4), nw);
}
@end

// ---------------------------------------------------------------------------------------------------------------------------------------
@fs fs_temporal
layout(binding=0) uniform texture2D tex_n;
layout(binding=1) uniform texture2D tex_p;
layout(binding=2) uniform texture2D tex_v;
layout(binding=3) uniform texture2D tex_hc;
layout(binding=4) uniform texture2D tex_hm;
layout(binding=5) uniform texture2D tex_hg;
layout(binding=0) uniform sampler smp_pt;
layout(binding=1) uniform rtd_temporal_params {
    vec4 a;     // x = 1 when render targets are bottom-up (OpenGL), yz = the size of every image in pixels, w = 1 when the history holds the frame before
    vec4 s;     // x = channels (1 or 3), y = signal kind, z = the longest history in frames, w = the firefly clamp (0 = off)
    vec4 f;     // x = 1 when the velocity is bound, y = the depth tolerance (a share of the depth), z = the least cosine between the normals, w = 1 when the input's alpha is the hit distance
    vec4 pa;    // the projection of the camera: P00, P11, P02, P12
    vec4 pb;    // P03, P13, P32, P33
    mat4 m;     // previous (unjittered) view-projection * inverse view: a view-space position of this frame -> the clip position it had on the frame before
    vec4 wx;    // the rotation of the view matrix, as in rtd_guide_params
    vec4 wy;
    vec4 wz;
    vec4 sv;    // x = the depth share the spatial variance estimate takes as one plane, y = the least cosine of the normals there
};
in vec2 uv;
layout(location=0) out vec4 out_color;
layout(location=1) out vec4 out_moments;
@include_block rtd_common

// The texture-space uv of the pixel centre (x, y) counted from the top of the picture.
vec2 rtd_uv(vec2 ip) {
    vec2 t = (ip + 0.5) / a.yz;
    return vec2(t.x, mix(t.y, 1.0 - t.y, a.x));
}

vec3 rtd_read(vec4 t) {
    vec3 c = s.x < 1.5 ? vec3(t.r) : t.rgb;
    return rtd_nan3(c) ? vec3(0.0) : clamp(c, vec3(0.0), vec3(65000.0));
}

void main() {
    vec4 pre = textureLod(sampler2D(tex_p, smp_pt), uv, 0.0);
    vec4 nz = textureLod(sampler2D(tex_n, smp_pt), uv, 0.0);
    vec3 cur = rtd_read(nz);
    float hit = 0.0;
    if (f.w > 0.5) {
        hit = rtd_nanf(nz.a) ? 0.0 : (nz.a < 0.0 ? RTD_FAR : min(nz.a, RTD_FAR));
    }
    if (pre.a < 0.5) {   // nothing was drawn here: the signal as it is, no variance, no history
        out_color = vec4(cur, 0.0);
        out_moments = vec4(0.0, 0.0, 0.0, hit);
        return;
    }
    float d = pre.r;
    vec3 nv = rtd_oct_decode(pre.gb);
    vec3 nw = normalize(vec3(dot(wx.xyz, nv), dot(wy.xyz, nv), dot(wz.xyz, nv)));
    vec2 ip = floor(vec2(uv.x, mix(uv.y, 1.0 - uv.y, a.x)) * a.yz);

    // The 3x3 around: the depth change per pixel on the flat side of the pixel (what a sub-pixel error of the reprojection moves a surface by)
    // and, for a radiance, the mean luminance of the neighbours the firefly clamp measures against.
    float slopeX = 1e30;
    float slopeY = 1e30;
    float sumL = 0.0;
    float cnt = 0.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            if (x == 0 && y == 0) continue;
            vec2 q = ip + vec2(float(x), float(y));
            if (q.x < 0.0 || q.y < 0.0 || q.x >= a.y || q.y >= a.z) continue;
            vec2 tq = rtd_uv(q);
            vec4 pq = textureLod(sampler2D(tex_p, smp_pt), tq, 0.0);
            if (pq.a < 0.5) continue;
            float dd = abs(pq.r - d);
            if (y == 0) slopeX = min(slopeX, dd);
            if (x == 0) slopeY = min(slopeY, dd);
            if (s.w > 0.0) {
                sumL += rtd_luma(rtd_read(textureLod(sampler2D(tex_n, smp_pt), tq, 0.0)), s.x);
                cnt += 1.0;
            }
        }
    }
    float slope = max(slopeX < 1e29 ? slopeX : 0.0, slopeY < 1e29 ? slopeY : 0.0);
    // The firefly clamp: a radiance sample brighter than `s.w` times the mean of its neighbours is brought down to that. (A one-channel
    // signal is bounded and never clamped: the caller sets s.w = 0.)
    if (s.w > 0.0 && cnt > 0.0) {
        float cap = s.w * (sumL / cnt + 0.01);
        float l0 = rtd_luma(cur, s.x);
        if (l0 > cap) cur *= cap / l0;
    }

    // Where the surface was on the frame before: the velocity an object wrote, else the camera's own movement from the depth.
    vec2 sU = (ip + 0.5) / a.yz;
    vec2 ndc = vec2(sU.x * 2.0 - 1.0, 1.0 - sU.y * 2.0);
    float z = -d;
    float wclip = pb.z * z + pb.w;
    vec3 vp = vec3((ndc.x * wclip - pa.z * z - pb.x) / pa.x, (ndc.y * wclip - pa.w * z - pb.y) / pa.y, z);
    vec4 pc = m * vec4(vp, 1.0);
    bool ok = pc.w > 1e-4;
    bool velKnown = false;
    vec2 mv = vec2(0.0);
    if (f.x > 0.5) {
        vec2 v = textureLod(sampler2D(tex_v, smp_pt), uv, 0.0).rg;
        velKnown = abs(v.x) < 512.0 && abs(v.y) < 512.0;   // the same test as VelocityRef::is_none
        if (velKnown) mv = v;
    }
    float prevDepth = -1.0;   // the view depth the surface had on the frame before (-1: not known)
    if (ok) {
        if (!velKnown) mv = ((pc.xy / pc.w) - ndc) * vec2(0.5, -0.5);
        if (abs(pb.z) > 1e-6) prevDepth = pc.w;
    }
    bool canReproject = a.w > 0.5 && (ok || velKnown);

    // The four history pixels around that position, each taken only when it shows the same surface: drawn, at the depth it should have
    // (the camera's movement says it; a pixel an object moved may also have kept its distance) and facing the same way.
    vec2 pu = sU + mv;
    vec2 fpos = pu * a.yz - 0.5;
    vec2 i0 = floor(fpos);
    vec2 fr = fpos - i0;
    float tol = f.y * d + 1.5 * slope;
    float wsum = 0.0;
    float hlen = 0.0;
    float hhit = 0.0;
    vec3 hcol = vec3(0.0);
    vec2 hmom = vec2(0.0);
    for (int k = 0; k < 4; k++) {
        vec2 o = vec2(float(k & 1), float(k >> 1));
        vec2 q = i0 + o;
        float w = (o.x > 0.5 ? fr.x : 1.0 - fr.x) * (o.y > 0.5 ? fr.y : 1.0 - fr.y);
        if (!canReproject || w <= 0.0 || q.x < 0.0 || q.y < 0.0 || q.x >= a.y || q.y >= a.z) continue;
        vec2 tq = rtd_uv(q);
        vec4 hg = textureLod(sampler2D(tex_hg, smp_pt), tq, 0.0);
        if (!(hg.r > 0.0)) continue;   // nothing was drawn there (also a NaN)
        float e1 = prevDepth > 0.0 ? abs(hg.r - prevDepth) : 1e30;
        float e2 = abs(hg.r - d);
        float dz = (velKnown || prevDepth <= 0.0) ? min(e1, e2) : e1;
        if (dz > tol) continue;
        if (dot(hg.gba, nw) < f.z) continue;
        vec4 hc = textureLod(sampler2D(tex_hc, smp_pt), tq, 0.0);
        vec4 hm = textureLod(sampler2D(tex_hm, smp_pt), tq, 0.0);
        if (rtd_nan3(hc.rgb) || rtd_nanf(hm.x) || rtd_nanf(hm.y) || rtd_nanf(hm.z) || rtd_nanf(hm.w)) continue;
        wsum += w;
        hcol += hc.rgb * w;
        hmom += hm.xy * w;
        hlen += hm.z * w;
        hhit += hm.w * w;
    }
    bool hv = wsum > 0.01;

    // The accumulation: a running mean over the history length, which stops growing at the longest history (an exponential mean from there).
    float len = hv ? min(hlen / wsum + 1.0, s.z) : 1.0;
    float alpha = 1.0 / len;
    float l = rtd_luma(cur, s.x);
    float m1 = hv ? mix(hmom.x / wsum, l, alpha) : l;
    float m2 = hv ? mix(hmom.y / wsum, l * l, alpha) : l * l;
    vec3 col = hv ? mix(hcol / wsum, cur, alpha) : cur;
    float outHit = hv ? mix(hhit / wsum, hit, alpha) : hit;
    float varT = max(m2 - m1 * m1, 0.0);
    float varSample = varT;
    if (len < 4.0) {
        // A short history has too few samples for a variance: the spread of the pixels around that show the same surface stands in for it, and
        // hands over to the temporal one as the history grows.
        float sm1 = 0.0;
        float sm2 = 0.0;
        float sw = 0.0;
        for (int y = -2; y <= 2; y++) {
            for (int x = -2; x <= 2; x++) {
                vec2 q = ip + vec2(float(x), float(y));
                if (q.x < 0.0 || q.y < 0.0 || q.x >= a.y || q.y >= a.z) continue;
                vec2 tq = rtd_uv(q);
                vec4 pq = textureLod(sampler2D(tex_p, smp_pt), tq, 0.0);
                if (pq.a < 0.5) continue;
                if (abs(pq.r - d) > sv.x * d + slope * max(abs(float(x)), abs(float(y)))) continue;
                if (dot(rtd_oct_decode(pq.gb), nv) < sv.y) continue;
                float lq = rtd_luma(rtd_read(textureLod(sampler2D(tex_n, smp_pt), tq, 0.0)), s.x);
                sm1 += lq;
                sm2 += lq * lq;
                sw += 1.0;
            }
        }
        float varS = sw > 1.0 ? max(sm2 / sw - (sm1 / sw) * (sm1 / sw), 0.0) : 0.0;
        varSample = mix(varS, varT, clamp((len - 1.0) / 3.0, 0.0, 1.0));
    }
    out_color = vec4(col, varSample / len);
    out_moments = vec4(m1, m2, len, outHit);
}
@end

// ---------------------------------------------------------------------------------------------------------------------------------------
@fs fs_atrous
layout(binding=6) uniform texture2D tex_c;
layout(binding=1) uniform texture2D tex_p;
layout(binding=4) uniform texture2D tex_hm;
layout(binding=7) uniform texture2D tex_r;
layout(binding=0) uniform sampler smp_pt;
layout(binding=1) uniform rtd_atrous_params {
    vec4 a;     // x = 1 when render targets are bottom-up (OpenGL), yz = the size of every image in pixels, w = the step of this iteration in pixels
    vec4 s;     // x = channels (1 or 3), y = signal kind, z = the share of the depth a neighbour may be off the plane, w = the exponent of the normal weight
    vec4 f;     // x = the width of the luminance weight in standard deviations, y = 1 when the roughness is bound, z = the roughness of a pixel without one, w = 0
    vec4 cam;   // xy = what a unit of normalised device coordinates is in view space at depth 1, z = 1 for an orthographic camera
};
in vec2 uv;
out vec4 out_color;
@include_block rtd_common

vec2 rtd_uv(vec2 ip) {
    vec2 t = (ip + 0.5) / a.yz;
    return vec2(t.x, mix(t.y, 1.0 - t.y, a.x));
}

void main() {
    vec4 pre = textureLod(sampler2D(tex_p, smp_pt), uv, 0.0);
    vec4 cc = textureLod(sampler2D(tex_c, smp_pt), uv, 0.0);
    if (pre.a < 0.5) {
        out_color = cc;
        return;
    }
    float dp = pre.r;
    vec3 np = rtd_oct_decode(pre.gb);
    vec2 ip = floor(vec2(uv.x, mix(uv.y, 1.0 - uv.y, a.x)) * a.yz);
    vec3 pp = rtd_view_pos((ip + 0.5) / a.yz, dp, cam);

    // How far this iteration reaches. A specular signal is filtered only as wide as its lobe: the footprint of the reflection cone at the hit
    // (roughness^2 * the hit distance) in pixels, so a mirror keeps its image and a rough surface is blurred like a diffuse one.
    float st = a.w;
    if (s.y > 2.5) {
        float hitD = textureLod(sampler2D(tex_hm, smp_pt), uv, 0.0).a;
        float rough = f.y > 0.5 ? textureLod(sampler2D(tex_r, smp_pt), uv, 0.0).r : f.z;
        rough = clamp(rough, 0.0, 1.0);
        float pixW = 2.0 * (cam.z > 0.5 ? 1.0 : dp) * cam.y / a.z;   // the size of a pixel in world units at this depth
        float radiusPx = rough * rough * min(hitD, 64.0 * dp) / max(pixW, 1e-6);
        st = min(st, 0.5 * radiusPx);
    }
    if (st < 0.5) {   // too small to reach another pixel: the signal stays as it is
        out_color = cc;
        return;
    }

    // The variance around the pixel (a 3x3 Gaussian) sets how different two luminances may be and still count as one surface.
    float varSum = 0.0;
    float varW = 0.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 q = ip + vec2(float(x), float(y));
            if (q.x < 0.0 || q.y < 0.0 || q.x >= a.y || q.y >= a.z) continue;
            float w = (x == 0 ? 0.5 : 0.25) * (y == 0 ? 0.5 : 0.25);
            varSum += w * max(textureLod(sampler2D(tex_c, smp_pt), rtd_uv(q), 0.0).a, 0.0);
            varW += w;
        }
    }
    float sigmaL = f.x * sqrt(varSum / max(varW, 1e-6)) + 1e-4;
    float lp = rtd_luma(cc.rgb, s.x);
    float ptol = max(s.z * dp * (1.0 + 0.1 * st), 1e-5);

    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    float vacc = 0.0;
    for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
            vec2 off = vec2(float(x), float(y)) * st;
            off = sign(off) * floor(abs(off) + 0.5);
            vec2 q = ip + off;
            if (q.x < 0.0 || q.y < 0.0 || q.x >= a.y || q.y >= a.z) continue;
            float hk = rtd_kernel(x) * rtd_kernel(y);
            float w = hk;
            vec4 cq = cc;
            if (x != 0 || y != 0) {
                vec2 tq = rtd_uv(q);
                vec4 pq = textureLod(sampler2D(tex_p, smp_pt), tq, 0.0);
                if (pq.a < 0.5) continue;
                cq = textureLod(sampler2D(tex_c, smp_pt), tq, 0.0);
                vec3 pn = rtd_view_pos((q + 0.5) / a.yz, pq.r, cam);
                float dist = dot(pn - pp, np) / ptol;
                float wz = exp(-dist * dist);
                float wn = pow(max(dot(np, rtd_oct_decode(pq.gb)), 0.0), s.w);
                float wl = exp(-abs(lp - rtd_luma(cq.rgb, s.x)) / sigmaL);
                w = hk * wz * wn * wl;
            }
            acc += w * cq.rgb;
            wsum += w;
            vacc += w * w * max(cq.a, 0.0);
        }
    }
    float inv = 1.0 / max(wsum, 1e-8);
    out_color = vec4(acc * inv, vacc * inv * inv);
}
@end

// ---------------------------------------------------------------------------------------------------------------------------------------
@fs fs_debug
layout(binding=6) uniform texture2D tex_c;
layout(binding=4) uniform texture2D tex_hm;
layout(binding=0) uniform sampler smp_pt;
layout(binding=1) uniform rtd_debug_params {
    vec4 a;     // x = the view: 1 the history length (white = the longest history), 2 the standard deviation of the estimate, sd / (sd + 0.01)
    vec4 s;     // x = the longest history in frames
};
in vec2 uv;
out vec4 frag_color;

void main() {
    if (a.x < 1.5) {
        float len = textureLod(sampler2D(tex_hm, smp_pt), uv, 0.0).b;
        frag_color = vec4(vec3(clamp(len / max(s.x, 1.0), 0.0, 1.0)), 1.0);
    } else {
        float sd = sqrt(max(textureLod(sampler2D(tex_c, smp_pt), uv, 0.0).a, 0.0));
        frag_color = vec4(vec3(sd / (sd + 0.01)), 1.0);
    }
}
@end

@program guide vs fs_guide
@program temporal vs fs_temporal
@program atrous vs fs_atrous
@program debug vs fs_debug
