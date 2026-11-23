// FactorIA temporal antialiasing: the resolve function shared by the TAA pass of the post stack (taa.glsl) and the temporal upscaler (M76-P4),
// which resolves the same way from a picture at the render resolution into a history at the output resolution.
//
// Not compiled on its own: a top file declares the textures, the samplers and the uniform block below, then `@include taa_shared.glsl`
// and `@include_block taa_resolve_fn` inside the fragment shader. What the function reads (names fixed by this file):
//   tex_c  the picture of this frame, jittered, at inSize pixels, read at taa_game_uv(top-left uv of a pixel centre of that image)
//   tex_p  the prepass (r = linear view depth, a = 1 where a mesh was drawn), at inSize; read when `f.x` is 1
//   tex_v  the velocity (rg = uvPrev - uvCurr, unjittered; 1024 = no object wrote here), at inSize; read when `f.y` is 1
//   tex_h  the history: the resolved colour of the frame before in rgb, the linear depth of its pixel in a (when `f.w` is 1), at outSize
//   tex_r  the reactive mask (r, 0..1), at inSize; read when `f.z` is 1
//   smp_lin, smp_pt   the linear and the nearest sampler (clamp to edge)
// and the members of the block `taa_uniforms` (see taa_params below).
//
// Where things are: every uv here is a camera-local top-left uv (0,0 = the top-left of the camera's rectangle); taa_fl turns it into the
// texture coordinate of an image of that rectangle's size (the bottom-up targets of OpenGL are flipped), taa_game_uv does it for the
// picture of the whole frame (the camera's rectangle of it is `rc`).
//
// The history lives on the UNJITTERED grid of the output: its pixel q holds the colour of the point of the scene at the centre of pixel q of the
// camera's image drawn with the unjittered matrices. The picture of this frame was drawn with the jitter `jit` (in input pixels, +x right, +y
// down): its pixel i shows the scene at the unjittered position i + 0.5 - jit. The function resolves the output pixel at `u` from the 3x3 pixels
// of the picture around that position (a Gaussian filter, the neighbourhood variance clips the history) and the history reprojected to where
// the surface was on the frame before: from the velocity where an object wrote one, else from the camera's own movement and the depth of
// the prepass (the matrix `m`). With no prepass the depth is taken as very far (only the camera's turning moves the history).
@block taa_uniforms
layout(binding=1) uniform taa_params {
    vec4 a;     // x = 1 when render targets are bottom-up (OpenGL), yz = the picture's size in pixels (the camera's rectangle), w = 0
    vec4 hs;    // xy = the size of the history and of the output in pixels, z = 1 when the history holds the frame before, w = 0
    vec4 rc;    // the rectangle of the source picture the pass covers (top-left, fractions of the picture): xy corner, zw size
    vec4 j;     // xy = the jitter of this frame in picture pixels, zw = 0
    vec4 g;     // x = variance gamma (how far the history may stray from its neighbours), y = feedback (the share taken from the history), z = sharpen, w = reactive scale
    vec4 f;     // x = 1 when the prepass is bound, y = 1 when the velocity is bound, z = 1 when the reactive mask is bound, w = 1 when the history alpha holds the depth
    vec4 pa;    // the projection of the camera: P00, P11, P02, P12 (what the view-space position of a pixel needs)
    vec4 pb;    // P03, P13, P32, P33
    mat4 m;     // previous (unjittered) view-projection * inverse view: a view-space position of this frame -> the clip position it had on the frame before
};
@end

@block taa_resolve_fn
const float TAA_FAR = 60000.0;

vec2 taa_fl(vec2 s) { return vec2(s.x, mix(s.y, 1.0 - s.y, a.x)); }
vec2 taa_game_uv(vec2 s) { return taa_fl(s * rc.zw + rc.xy); }
float taa_max3(vec3 c) { return max(max(c.r, c.g), c.b); }
// The colour with its largest channel squeezed into 0..2: unchanged up to 1 (a mean of the samples of a pixel at the edge of a shape is the mean of
// their values, so the picture converges to the supersampled one), above 1 the channel m goes to 2 - 1/m, so a bright pixel cannot outweigh its
// neighbours in the mean and the variance.
vec3 taa_compress(vec3 c) {
    float m = taa_max3(c);
    return m <= 1.0 ? c : c * ((2.0 - 1.0 / m) / m);
}
vec3 taa_expand(vec3 c) {
    float m = taa_max3(c);
    return m <= 1.0 ? c : c * ((1.0 / (2.0 - min(m, 1.99998))) / m);
}
vec3 taa_ycocg(vec3 c) { return vec3(0.25 * c.r + 0.5 * c.g + 0.25 * c.b, 0.5 * c.r - 0.5 * c.b, -0.25 * c.r + 0.5 * c.g - 0.25 * c.b); }
vec3 taa_rgb(vec3 c) { return vec3(c.x + c.y - c.z, c.x + c.z, c.x - c.y - c.z); }

// The history at the camera-local uv `p`: 5 taps of a Catmull-Rom filter (sharper than a bilinear tap, which would blur the picture a little more
// at every frame it is carried).
vec3 taa_history_rgb(vec2 p, vec2 size) {
    vec2 pos = p * size;
    vec2 c1 = floor(pos - 0.5) + 0.5;
    vec2 fr = pos - c1;
    vec2 w0 = fr * (-0.5 + fr * (1.0 - 0.5 * fr));
    vec2 w1 = 1.0 + fr * fr * (-2.5 + 1.5 * fr);
    vec2 w2 = fr * (0.5 + fr * (2.0 - 1.5 * fr));
    vec2 w3 = fr * fr * (-0.5 + 0.5 * fr);
    vec2 w12 = w1 + w2;
    vec2 lo = vec2(0.5);
    vec2 hi = size - 0.5;
    vec2 p0 = clamp(c1 - 1.0, lo, hi) / size;
    vec2 p3 = clamp(c1 + 2.0, lo, hi) / size;
    vec2 p12 = clamp(c1 + w2 / w12, lo, hi) / size;
    vec3 r = textureLod(sampler2D(tex_h, smp_lin), taa_fl(vec2(p12.x, p0.y)), 0.0).rgb * (w12.x * w0.y);
    r += textureLod(sampler2D(tex_h, smp_lin), taa_fl(vec2(p0.x, p12.y)), 0.0).rgb * (w0.x * w12.y);
    r += textureLod(sampler2D(tex_h, smp_lin), taa_fl(vec2(p12.x, p12.y)), 0.0).rgb * (w12.x * w12.y);
    r += textureLod(sampler2D(tex_h, smp_lin), taa_fl(vec2(p3.x, p12.y)), 0.0).rgb * (w3.x * w12.y);
    r += textureLod(sampler2D(tex_h, smp_lin), taa_fl(vec2(p12.x, p3.y)), 0.0).rgb * (w12.x * w3.y);
    float wsum = w12.x * w0.y + w0.x * w12.y + w12.x * w12.y + w3.x * w12.y + w12.x * w3.y;
    return max(r / max(wsum, 1e-4), vec3(0.0));
}

// What taa_resolve returns: the resolved colour (display-linear like the picture) and the linear depth the history keeps for its pixel.
struct TaaResult {
    vec3 color;
    float depth;
};

// u: the camera-local top-left uv of the output pixel's centre (unjittered grid). inSize: the size of the picture of this frame, outSize: the
// size of the history and the output, jit: the jitter of this frame in picture pixels.
TaaResult taa_resolve(vec2 u, vec2 inSize, vec2 outSize, vec2 jit) {
    vec2 up = u * inSize;                         // the position to resolve, in picture pixels
    vec2 base = floor(up + jit);                  // the picture pixel that shows it
    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    vec3 m1 = vec3(0.0);
    vec3 m2 = vec3(0.0);
    float bestD = 1e30;
    float bestDepth = TAA_FAR;
    vec2 bestCtr = base + 0.5;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 ip = clamp(base + vec2(float(x), float(y)), vec2(0.0), inSize - 1.0);
            vec2 ctr = ip + 0.5;
            vec2 suv = ctr / inSize;
            vec3 c = textureLod(sampler2D(tex_c, smp_lin), taa_game_uv(suv), 0.0).rgb;
            c = taa_ycocg(taa_compress(clamp(c, vec3(0.0), vec3(65000.0))));
            vec2 d = (ctr - jit) - up;            // where this pixel's sample is, from the pixel being resolved
            float w = exp(-2.29 * dot(d, d));
            acc += c * w;
            wsum += w;
            m1 += c;
            m2 += c * c;
            // The closest surface around decides how the pixel moved (an edge keeps the motion of the thing in front).
            float depth = TAA_FAR;
            if (f.x > 0.5) {
                vec4 pre = textureLod(sampler2D(tex_p, smp_pt), taa_fl(suv), 0.0);
                depth = pre.a > 0.5 ? pre.r : TAA_FAR;
            }
            float key = depth * (1.0 + 1e-4 * float(abs(x) + abs(y)));   // the centre wins a tie
            if (key < bestD) {
                bestD = key;
                bestDepth = depth;
                bestCtr = ctr;
            }
        }
    }
    vec3 cur = acc / max(wsum, 1e-6);
    vec3 mu = m1 / 9.0;
    vec3 sigma = sqrt(max(m2 / 9.0 - mu * mu, vec3(0.0)));

    // How the surface at the closest sample moved: the velocity an object wrote, else the camera's movement from the depth.
    vec2 suvB = bestCtr / inSize;                 // the sample's own uv, in the jittered image
    vec2 sU = (bestCtr - jit) / inSize;           // where the surface of that sample is on the unjittered image
    bool velocityKnown = false;
    vec2 mv = vec2(0.0);
    if (f.y > 0.5) {
        vec2 v = textureLod(sampler2D(tex_v, smp_pt), taa_fl(suvB), 0.0).rg;
        // The same test as VelocityRef::is_none: a NaN or a value from 512 up is "no object wrote here".
        velocityKnown = abs(v.x) < 512.0 && abs(v.y) < 512.0;
        if (velocityKnown) mv = v;
    }
    vec2 ndc = vec2(sU.x * 2.0 - 1.0, 1.0 - sU.y * 2.0);
    float z = -bestDepth;
    float w = pb.z * z + pb.w;                    // clip w: -z for a perspective camera, 1 for an orthographic one
    vec3 vp = vec3((ndc.x * w - pa.z * z - pb.x) / pa.x, (ndc.y * w - pa.w * z - pb.y) / pa.y, z);
    vec4 pc = m * vec4(vp, 1.0);
    bool ok = pc.w > 1e-4;
    float prevDepth = -1.0;                       // the view depth the surface had on the frame before (-1: not known)
    if (ok) {
        if (!velocityKnown) mv = ((pc.xy / pc.w) - ndc) * vec2(0.5, -0.5);
        if (abs(pb.z) > 1e-6) prevDepth = pc.w;
    }
    vec2 pu = u + mv;                             // where the history keeps this surface
    float hv = (hs.z > 0.5 && ok && pu.x >= 0.0 && pu.x <= 1.0 && pu.y >= 0.0 && pu.y <= 1.0) ? 1.0 : 0.0;

    float keep = 0.0;
    vec3 hist = cur;
    if (hv > 0.5) {
        hist = taa_ycocg(taa_compress(taa_history_rgb(pu, outSize)));
        // The variance clip: the history is pulled toward the mean of the neighbours until it is inside the box of mean +- gamma * sigma.
        vec3 e = max(g.x * sigma, vec3(1e-3));
        vec3 dir = hist - mu;
        float t = max(max(abs(dir.x) / e.x, abs(dir.y) / e.y), abs(dir.z) / e.z);
        if (t > 1.0) hist = mu + dir / t;
        keep = clamp(g.y, 0.0, 0.995);
        // A surface that was not where the history says (an occluded thing came out): the depth it had is far from the depth it has now. Not
        // known for a pixel an object moved (its velocity says where it was, not how deep).
        if (f.w > 0.5 && prevDepth > 0.0 && !velocityKnown) {
            float hd = textureLod(sampler2D(tex_h, smp_pt), taa_fl(pu), 0.0).a;
            float rel = abs(hd - prevDepth) / max(prevDepth, 0.25);
            keep *= 1.0 - smoothstep(0.08, 0.2, rel);
        }
        if (f.z > 0.5) {
            float r = textureLod(sampler2D(tex_r, smp_pt), taa_fl(suvB), 0.0).r;
            keep *= 1.0 - clamp(r * g.w, 0.0, 1.0);
        }
    }
    TaaResult res;
    res.color = taa_expand(taa_rgb(mix(cur, hist, keep)));
    res.depth = bestDepth;
    return res;
}
@end
