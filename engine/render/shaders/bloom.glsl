// FactorIA camera bloom (Camera.bloom): bright-pass + downsample, separable gaussian blur, additive composite.
// Every program draws one full-screen triangle; all intermediate targets are RGBA8 so the chain runs on every
// sokol_gfx backend (GL 4.3 core, GLES3, D3D11, Metal) without float-render-target extensions.
//
//   bright     game target (full res)  -> 1/2 or 1/4 res: per-source-pixel threshold, then a 2x2 or 4x4 average
//   down       1/2^n res               -> 1/2^(n+1) res: 2x2 box average (one bilinear tap at the texel corner)
//   blur       one axis of a gaussian whose half-width is at most 16 texels (the engine uses <= 5); pairs of taps are merged into one
//              bilinear fetch, so a kernel costs about half as many fetches as it has taps
//   composite  blurred glow (low res)  -> game target: dst.rgb += glow.rgb * intensity (alpha untouched)
@module bloom

// Source texture + an explicit-LOD fetch (no screen-space derivatives, so it is legal in the blur loop on D3D11).
@block source
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
vec3 fetch(vec2 c) { return textureLod(sampler2D(tex, smp), c, 0.0).rgb; }
@end

@vs vs
layout(binding=0) uniform bloom_vs_params {
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

// ---- bright pass -----------------------------------------------------------------------------------------
@fs fs_bright
@include_block source
layout(binding=1) uniform bloom_bright_params {
    vec4 p;         // xy = one SOURCE texel in uv units, z = threshold, w = 1 / max(1 - threshold, 1/255)
    vec4 q;         // x = taps per axis: 2 (writes 1/2 res) or 4 (writes 1/4 res); the n x n source pixels are covered exactly
};
in vec2 uv;
out vec4 frag_color;

// Keeps the hue; scales the color from 0 (at the threshold) to 1 (at full brightness). "Brightness" is the largest
// channel so saturated neon colors (pure magenta, cyan...) glow as much as white does.
vec3 bright(vec3 c) {
    float v = max(c.r, max(c.g, c.b));
    float f = clamp((v - p.z) * p.w, 0.0, 1.0);
    return c * f;
}

void main() {
    // Thresholding every source pixel BEFORE averaging keeps thin bright lines and small particles glowing.
    float n = q.x;
    float start = -(n - 1.0) * 0.5;
    vec3 acc = vec3(0.0);
    for (int j = 0; j < 4; j++) {
        if (float(j) >= n) break;
        for (int i = 0; i < 4; i++) {
            if (float(i) >= n) break;
            acc += bright(fetch(uv + vec2(start + float(i), start + float(j)) * p.xy));
        }
    }
    frag_color = vec4(acc / (n * n), 1.0);
}
@end

// ---- 2x downsample (box) ---------------------------------------------------------------------------------
@fs fs_down
@include_block source
in vec2 uv;
out vec4 frag_color;
void main() {
    // The destination texel center is the shared corner of a 2x2 block of source texels: a bilinear fetch there
    // is exactly their average.
    frag_color = vec4(fetch(uv), 1.0);
}
@end

// ---- separable gaussian ----------------------------------------------------------------------------------
@fs fs_blur
@include_block source
layout(binding=1) uniform bloom_blur_params {
    vec4 p;         // xy = uv step of one texel along the blur axis, z = 1 / (2 sigma^2) in texels, w = half-width in texels (<= 16)
};
in vec2 uv;
out vec4 frag_color;
void main() {
    vec2 step_uv = p.xy;
    float inv2s2 = p.z;
    float taps = p.w;
    vec3 acc = fetch(uv);
    float wsum = 1.0;
    // Tap pairs (a, a+1) are merged into one bilinear fetch at the weighted offset between them.
    for (int k = 0; k < 8; k++) {
        float a = float(2 * k + 1);
        if (a > taps) break;
        float b = a + 1.0;
        float wa = exp(-a * a * inv2s2);
        float wb = b <= taps ? exp(-b * b * inv2s2) : 0.0;
        float w = wa + wb;
        vec2 o = step_uv * ((a * wa + b * wb) / w);
        acc += (fetch(uv + o) + fetch(uv - o)) * w;
        wsum += 2.0 * w;
    }
    frag_color = vec4(acc / wsum, 1.0);
}
@end

// ---- composite (additive, see Gpu::bloom_pipeline) --------------------------------------------------------
@fs fs_composite
@include_block source
layout(binding=1) uniform bloom_composite_params {
    vec4 p;         // x = intensity
};
in vec2 uv;
out vec4 frag_color;
void main() {
    frag_color = vec4(fetch(uv) * p.x, 0.0);
}
@end

@program bright vs fs_bright
@program down vs fs_down
@program blur vs fs_blur
@program composite vs fs_composite
