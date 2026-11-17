// FactorIA automatic exposure (PostProcess.exposureMode auto): measures how bright the frame is and adapts the exposure to it.
//
//   luma   game target (full size) -> 32x32: every texel is the mean of log2(luminance) over its 8x8 sample grid, so a small bright
//          light still counts and nothing is random (fixed taps)
//   adapt  32x32 + the previous exposure (1x1) -> the next exposure (1x1): the mean over the 32x32 gives the average luminance, the
//          exposure that brings it to 18% grey is clamped to [minEv, maxEv] and the stored EV moves toward it by 1 - exp(-speed * dt)
//
// The EV lives in the red channel of a 1x1 float target; the final pass (post.glsl) reads it. dt is the engine's frame time, so the
// adaptation is the same on every run and every machine; a frame with dt 0 does not move it.
@module exposure

@vs vs
layout(binding=0) uniform exposure_vs_params {
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

@fs fs_luma
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform exposure_luma_params {
    vec4 p;         // x = 1 when the scene is linear (0: gamma, sRGB-encoded values), yz = size of one texel of the 32x32 target in uv units
};
in vec2 uv;
out vec4 frag_color;

// One channel made safe: NaN, Inf (found by their bits, as bloom.glsl does) and anything from 65000 up become 0, a negative becomes 0.
float sane(float x) {
    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u || x >= 65000.0) return 0.0;
    return max(x, 0.0);
}
vec3 to_linear(vec3 c) {
    return mix(pow(max((c + 0.055) / 1.055, vec3(0.0)), vec3(2.4)), c / 12.92, vec3(lessThanEqual(c, vec3(0.04045))));
}

void main() {
    float acc = 0.0;
    for (int j = 0; j < 8; j++) {
        for (int i = 0; i < 8; i++) {
            vec2 o = (vec2(float(i), float(j)) + 0.5) / 8.0 - 0.5;
            vec3 c = textureLod(sampler2D(tex, smp), uv + o * p.yz, 0.0).rgb;
            c = vec3(sane(c.r), sane(c.g), sane(c.b));
            if (p.x < 0.5) c = to_linear(min(c, vec3(64.0)));
            float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
            acc += log2(max(lum, 1e-4));
        }
    }
    frag_color = vec4(acc / 64.0, 0.0, 0.0, 1.0);
}
@end

@fs fs_adapt
layout(binding=0) uniform texture2D luma_tex;
layout(binding=1) uniform texture2D prev_tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform exposure_adapt_params {
    vec4 p;         // x = dt in seconds, y = adaptation speed per second, z = the darkest EV, w = the brightest EV
    vec4 q;         // x = 1 to take the measured exposure at once (the first frame, or after a pause), not to move toward it
};
in vec2 uv;
out vec4 frag_color;

void main() {
    // The mean of the 32x32 log-luminances: 16x16 bilinear taps, each at the corner shared by 2x2 texels.
    float acc = 0.0;
    for (int j = 0; j < 16; j++) {
        for (int i = 0; i < 16; i++) {
            vec2 c = (vec2(float(i), float(j)) * 2.0 + 1.0) / 32.0;
            acc += textureLod(sampler2D(luma_tex, smp), c, 0.0).r;
        }
    }
    float mean_log2 = acc / 256.0;
    // The exposure that brings the average luminance to 18% grey.
    float target_ev = clamp(log2(0.18) - mean_log2, p.z, p.w);
    float prev_ev = textureLod(sampler2D(prev_tex, smp), vec2(0.5, 0.5), 0.0).r;
    float k = 1.0 - exp(-p.y * p.x);
    float ev = q.x > 0.5 ? target_ev : prev_ev + (target_ev - prev_ev) * k;
    frag_color = vec4(ev, 0.0, 0.0, 1.0);
}
@end

@program luma vs fs_luma
@program adapt vs fs_adapt
