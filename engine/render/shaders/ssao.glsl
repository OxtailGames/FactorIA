// FactorIA ambient occlusion (PostProcess.ssaoEnabled): GTAO, ground truth ambient occlusion from the depth and normal prepass
// (mesh_common.glsl, prepass_fs: r = linear view depth in world units, gb = octahedral view-space normal, a = 1 where an opaque mesh was
// drawn). Three programs, in this order (renderer_ssao.cpp declares the passes):
//
//   ao     the horizon search: for a few directions in screen space, a few steps each way, the highest horizon the depth buffer shows
//          inside the radius; the cosine-weighted visible part of the hemisphere is integrated in closed form (Jimenez et al., "Practical
//          Realtime Strategies for Accurate Indirect Occlusion", 2016). The directions and the steps are shifted by a fixed 4x4
//          pattern of the pixel (no random numbers, no frame number: the same picture on every run). Half or full resolution.
//   blur   two passes (horizontal, vertical), 5 taps each, weighted by the difference of depth: the 4x4 pattern averages out and the
//          edges of a surface stay sharp (a tap on another surface weighs nothing).
//   apply  reads the occlusion at the pixels of the prepass (a half resolution one is upsampled with the same depth weights) and
//          writes the visibility raised to a power: the pipeline multiplies it into the scene (blend DST_COLOR, ZERO), or, for the
//          debug view, writes it as a grey.
//
// The view space is the prepass's: x right, y up, the camera looks down -z. `cam` of every program: xy = what a unit of normalised device
// coordinates is in view space at depth 1 (a perspective camera: 1 / proj[0][0] and 1 / proj[1][1]; an orthographic one: the half
// extents), z = 1 for an orthographic camera (the depth does not scale x and y), w = 1 when render targets have their origin at the bottom
// (OpenGL).
@module ssao

@image_sample_type pre_tex unfilterable_float
@image_sample_type ao_tex unfilterable_float
@sampler_type smp nonfiltering

@vs vs
layout(binding=0) uniform ssao_vs_params {
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

// What the programs share. The including program declares pre_tex (the prepass) and smp (nearest) first.
@block ssao_common
const float SSAO_PI = 3.14159265;
const float SSAO_FAR = 60000.0;

// The prepass's octahedral decode (prepass_view.glsl).
vec3 ssao_oct_decode(vec2 e) {
    vec3 n = vec3(e.x, e.y, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) {
        n.xy = (1.0 - abs(n.yx)) * vec2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0);
    }
    return normalize(n);
}

// The view-space position of the surface at the uv of an image of this backend (uv.y runs down, or up on OpenGL) with linear depth d.
vec3 ssao_view_pos(vec2 uv, float d, vec4 cam) {
    vec2 ndc = vec2(uv.x * 2.0 - 1.0, mix(1.0 - 2.0 * uv.y, 2.0 * uv.y - 1.0, cam.w));
    float s = cam.z > 0.5 ? 1.0 : d;
    return vec3(ndc.x * cam.x * s, ndc.y * cam.y * s, -d);
}

// The depth of a texel of the prepass image: the far value where no mesh was drawn.
float ssao_depth_of(vec4 t) {
    return t.a > 0.5 ? t.r : SSAO_FAR;
}

// Weight of a neighbour at view position Pn for a centre at Pc with unit normal nc: 1 on the plane of the centre (a floor seen at a
// grazing angle changes its depth a lot from pixel to pixel and is still one surface), 0 off it (an edge, a step).
float ssao_plane_weight(vec3 Pc, vec3 nc, vec3 Pn, float sigma) {
    float x = dot(Pn - Pc, nc) / max(sigma, 0.0001);
    return exp(-x * x);
}

// The bit-reversed 4x4 Bayer matrix, 0..15, of the pixel.
float ssao_bayer(vec2 pixel) {
    int x = int(mod(pixel.x, 4.0));
    int y = int(mod(pixel.y, 4.0));
    int a = x ^ y;
    return float(((a & 1) << 3) | ((y & 1) << 2) | (((a >> 1) & 1) << 1) | ((y >> 1) & 1));
}

// The cosine of the horizon seen at uv `suv` from the point P (view vector V), pulled to `lowCos` (no occluder) the farther the sample is.
float ssao_horizon(vec2 suv, vec3 P, vec3 V, float lowCos, vec4 cam, vec2 fall, vec2 psz) {
    if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) {
        return lowCos;
    }
    // The depth under the sample: the four pixels around it, interpolated in 1 / depth (exact on a plane, so a floor seen at a grazing angle
    // does not read as a ridge of steps) when all four show the same surface, else the pixel it falls in (an edge keeps its step).
    vec2 fp = suv * psz - 0.5;
    vec2 i0 = floor(fp);
    vec2 f = fp - i0;
    vec2 lo = vec2(0.0);
    vec2 hi = psz - 1.0;
    vec4 t00 = textureLod(sampler2D(pre_tex, smp), (clamp(i0, lo, hi) + 0.5) / psz, 0.0);
    vec4 t10 = textureLod(sampler2D(pre_tex, smp), (clamp(i0 + vec2(1.0, 0.0), lo, hi) + 0.5) / psz, 0.0);
    vec4 t01 = textureLod(sampler2D(pre_tex, smp), (clamp(i0 + vec2(0.0, 1.0), lo, hi) + 0.5) / psz, 0.0);
    vec4 t11 = textureLod(sampler2D(pre_tex, smp), (clamp(i0 + vec2(1.0, 1.0), lo, hi) + 0.5) / psz, 0.0);
    vec4 tn = f.x < 0.5 ? (f.y < 0.5 ? t00 : t01) : (f.y < 0.5 ? t10 : t11);
    if (tn.a < 0.5) {
        return lowCos;
    }
    float depth = tn.r;
    if (t00.a + t10.a + t01.a + t11.a > 3.5) {
        float dmin = min(min(t00.r, t10.r), min(t01.r, t11.r));
        float dmax = max(max(t00.r, t10.r), max(t01.r, t11.r));
        if (dmax - dmin < 0.1 * dmin) {
            float inv = mix(mix(1.0 / t00.r, 1.0 / t10.r, f.x), mix(1.0 / t01.r, 1.0 / t11.r, f.x), f.y);
            depth = 1.0 / inv;
        }
    }
    vec3 delta = ssao_view_pos(suv, depth, cam) - P;
    float dist = length(delta);
    float w = clamp((fall.x - dist) / fall.y, 0.0, 1.0);
    // A small bias: a sample must rise above the tangent plane to count, so the rounding of the depth and of the normal does not darken a flat floor.
    float c = dot(delta / max(dist, 0.00001), V) - 0.03;
    return mix(lowCos, c, w);
}
@end

@fs fs_ao
layout(binding=0) uniform texture2D pre_tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform ssao_ao_params {
    vec4 cam;       // see the top of the file
    vec4 p;         // x = radius in world units, y = directions (slices), z = steps per direction and side
    vec4 sz;        // xy = size of the occlusion image, zw = size of the prepass image
    vec4 q;         // x = prepass pixels per texel of the occlusion image (1 or 2)
};
in vec2 uv;
out vec4 frag_color;
@include_block ssao_common

void main() {
    vec2 texel = floor(uv * sz.xy);
    vec2 puv = (texel * q.x + 0.5) / sz.zw;         // the prepass pixel this texel stands for
    vec4 c = textureLod(sampler2D(pre_tex, smp), puv, 0.0);
    if (c.a < 0.5) {
        frag_color = vec4(1.0, 0.0, 0.0, 1.0);
        return;
    }
    float d = c.r;
    vec3 P = ssao_view_pos(puv, d, cam);
    vec3 V = normalize(-P);
    vec3 n = ssao_oct_decode(c.gb);

    // The radius on the screen, in uv units of each axis (a circle in view space), kept under a quarter of the image.
    float scale = cam.z > 0.5 ? 1.0 : d;
    vec2 ruv = vec2(p.x / (2.0 * cam.x * scale), p.x / (2.0 * cam.y * scale));
    float shrink = min(1.0, 0.25 / max(ruv.x, 0.000001));
    ruv *= shrink;
    float radius = p.x * shrink;
    float pixels = ruv.x * sz.z;
    if (pixels < 1.5) {
        frag_color = vec4(1.0, 0.0, 0.0, 1.0);
        return;
    }
    float min_s = min(1.5 / pixels, 0.5);
    float range = 0.6 * radius;
    vec2 fall = vec2(radius, range);
    float y_up = mix(-1.0, 1.0, cam.w);            // uv.y grows downward unless the target's origin is at the bottom

    vec3 e1 = normalize(vec3(1.0, 0.0, 0.0) - V.x * V);
    vec3 e2 = cross(V, e1);
    float cell = ssao_bayer(texel);                 // 0..15, one per pixel of a 4x4 block
    float noise_slice = (cell + 0.5) / 16.0;
    float noise_step = fract(cell * 0.61803398875 + 0.25);
    int slices = int(p.y);
    int steps = int(p.z);

    float vis = 0.0;
    for (int i = 0; i < 8; i++) {
        if (i >= slices) {
            break;
        }
        float phi = (float(i) + noise_slice) / float(slices) * SSAO_PI;
        float cp = cos(phi);
        float sp = sin(phi);
        vec3 ortho = cp * e1 + sp * e2;                 // a direction of the plane the view vector is normal to: uniform in angle
        vec3 axis = normalize(cross(ortho, V));
        vec3 pn = n - axis * dot(n, axis);
        float pn_len = length(pn);
        float sgn = sign(dot(ortho, pn));
        float cos_n = clamp(dot(pn, V) / max(pn_len, 0.00001), 0.0, 1.0);
        float ang = sgn * acos(cos_n);
        float low0 = cos(ang + SSAO_PI * 0.5);
        float low1 = cos(ang - SSAO_PI * 0.5);
        float hc0 = low0;
        float hc1 = low1;
        // Where that direction goes on the screen (the derivative of the projection of P + t * ortho at t = 0), per unit of view space.
        vec2 g = cam.z > 0.5 ? ortho.xy / cam.xy : (ortho.xy / d + P.xy * ortho.z / (d * d)) / cam.xy;
        vec2 omega = 0.5 * radius * vec2(g.x, y_up * g.y);
        omega *= min(1.0, 0.3 / max(length(omega), 0.000001));
        for (int j = 0; j < 12; j++) {
            if (j >= steps) {
                break;
            }
            float s = (float(j) + noise_step) / float(steps);
            s = min(s * s + min_s, 1.0);
            vec2 off = omega * s;
            hc0 = max(hc0, ssao_horizon(puv + off, P, V, low0, cam, fall, sz.zw));
            hc1 = max(hc1, ssao_horizon(puv - off, P, V, low1, cam, fall, sz.zw));
        }
        float h0 = -acos(clamp(hc1, -1.0, 1.0));
        float h1 = acos(clamp(hc0, -1.0, 1.0));
        h0 = ang + clamp(h0 - ang, -SSAO_PI * 0.5, SSAO_PI * 0.5);
        h1 = ang + clamp(h1 - ang, -SSAO_PI * 0.5, SSAO_PI * 0.5);
        float arc0 = (cos_n + 2.0 * h0 * sin(ang) - cos(2.0 * h0 - ang)) * 0.25;
        float arc1 = (cos_n + 2.0 * h1 * sin(ang) - cos(2.0 * h1 - ang)) * 0.25;
        vis += pn_len * (arc0 + arc1);
    }
    // Not clamped to 1 here: a single pixel's few slices can add up to more than 1 and the blur must average that away (the clamp is in apply).
    vis = max(vis / float(max(slices, 1)), 0.0);
    frag_color = vec4(vis, 0.0, 0.0, 1.0);
}
@end

@fs fs_blur
layout(binding=0) uniform texture2D pre_tex;
layout(binding=1) uniform texture2D ao_tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform ssao_blur_params {
    vec4 dir;       // xy = the axis of the pass in texels (1, 0) or (0, 1)
    vec4 sz;        // xy = size of the occlusion image, zw = size of the prepass image
    vec4 q;         // x = prepass pixels per texel of the occlusion image (1 or 2), y = tolerance off the plane, a fraction of the depth
    vec4 cam;       // see the top of the file
};
in vec2 uv;
out vec4 frag_color;
@include_block ssao_common

void main() {
    vec2 texel = floor(uv * sz.xy);
    vec2 cuv = (texel * q.x + 0.5) / sz.zw;
    vec4 pc = textureLod(sampler2D(pre_tex, smp), cuv, 0.0);
    if (pc.a < 0.5) {
        frag_color = vec4(1.0, 0.0, 0.0, 1.0);
        return;
    }
    vec3 Pc = ssao_view_pos(cuv, pc.r, cam);
    vec3 nc = ssao_oct_decode(pc.gb);
    float sigma = pc.r * q.y;
    float sum = 0.0;
    float wsum = 0.0;
    for (int k = -2; k <= 2; k++) {
        vec2 t = texel + dir.xy * float(k);
        if (t.x < 0.0 || t.y < 0.0 || t.x >= sz.x || t.y >= sz.y) {
            continue;
        }
        float ao = textureLod(sampler2D(ao_tex, smp), (t + 0.5) / sz.xy, 0.0).r;
        vec2 nuv = (t * q.x + 0.5) / sz.zw;
        vec4 pn = textureLod(sampler2D(pre_tex, smp), nuv, 0.0);
        // The ends of the five taps weigh half: together they are one tap of the 4-texel period of the noise.
        float w = k == 0 ? 1.0 : (pn.a < 0.5 ? 0.0 : ssao_plane_weight(Pc, nc, ssao_view_pos(nuv, pn.r, cam), sigma));
        w *= (k == 2 || k == -2 ? 0.5 : 1.0);
        sum += w * ao;
        wsum += w;
    }
    frag_color = vec4(sum / wsum, 0.0, 0.0, 1.0);
}
@end

@fs fs_apply
layout(binding=0) uniform texture2D pre_tex;
layout(binding=1) uniform texture2D ao_tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform ssao_apply_params {
    vec4 a;         // x = the power the visibility is raised to (intensity, and the encode of a gamma scene), y = prepass pixels per texel of the occlusion image (1 or 2), z = tolerance off the plane, a fraction of the depth
    vec4 sz;        // xy = size of the occlusion image, zw = size of the prepass image
    vec4 cam;       // see the top of the file
};
in vec2 uv;
out vec4 frag_color;
@include_block ssao_common

void main() {
    vec2 pixel = floor(uv * sz.zw);
    vec2 cuv = (pixel + 0.5) / sz.zw;
    vec4 c = textureLod(sampler2D(pre_tex, smp), cuv, 0.0);
    if (c.a < 0.5) {
        frag_color = vec4(1.0, 1.0, 1.0, 1.0);
        return;
    }
    float vis;
    if (a.y < 1.5) {
        vis = textureLod(sampler2D(ao_tex, smp), (pixel + 0.5) / sz.xy, 0.0).r;
    } else {
        // A bilateral upsample: the four texels around the pixel, bilinear weights times the weight of their depth.
        vec3 Pc = ssao_view_pos(cuv, c.r, cam);
        vec3 nc = ssao_oct_decode(c.gb);
        float sigma = c.r * a.z * a.y;
        vec2 qp = (pixel + 0.5) / a.y - 0.5;
        vec2 i0 = floor(qp);
        vec2 f = qp - i0;
        float sum = 0.0;
        float wsum = 0.0;
        for (int j = 0; j < 2; j++) {
            for (int i = 0; i < 2; i++) {
                vec2 t = clamp(i0 + vec2(float(i), float(j)), vec2(0.0), sz.xy - 1.0);
                float wb = (i == 0 ? 1.0 - f.x : f.x) * (j == 0 ? 1.0 - f.y : f.y);
                float ao = textureLod(sampler2D(ao_tex, smp), (t + 0.5) / sz.xy, 0.0).r;
                vec2 nuv = (t * a.y + 0.5) / sz.zw;
                vec4 pn = textureLod(sampler2D(pre_tex, smp), nuv, 0.0);
                float w = wb * (pn.a < 0.5 ? 0.0 : ssao_plane_weight(Pc, nc, ssao_view_pos(nuv, pn.r, cam), sigma)) + 0.0001;
                sum += w * ao;
                wsum += w;
            }
        }
        vis = sum / wsum;
    }
    float k = pow(clamp(vis, 0.001, 1.0), a.x);
    frag_color = vec4(k, k, k, 1.0);
}
@end

@program ao vs fs_ao
@program blur vs fs_blur
@program apply vs fs_apply
