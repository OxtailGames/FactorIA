// FactorIA post-processing stack (M71, PostProcess): the FINAL pass, one full-screen triangle that fuses exposure, tonemap, the output
// encode (with dithering) and the accessibility colour filter. It reads the finished game target and writes the picture present() and
// the captures show. The bloom has its own chain (bloom.glsl) and runs before this pass, on the scene-referred colour.
//
//   1. the input to scene-linear light: a gamma scene (SceneSettings.colorSpace gamma) holds sRGB-encoded values, which are decoded;
//      a linear scene is used as it is
//   2. exposure: x 2^EV (manual: PostProcess.exposureEv; auto: the adapted EV of exposure.glsl plus the compensation)
//   3. tonemap: none (a clip), neutral, ACES, AgX, Reinhard
//   4. the encode: the sRGB transfer function with a dither of one 8-bit step. For an HDR window (p.z = 1) the tonemap goes above
//      paper white up to the output's headroom (h.x; tonemap_hdr) and the sRGB curve is extended past 1: the target then holds
//      display light ENCODED, 1.0 = paper white, and present() (blit.glsl) encodes it for the swapchain (scRGB, HDR10 PQ, EDR)
//   5. the colour filter (Camera.colorFilter), on the encoded picture, the same filters as colorfilter.glsl
//
// A frame that needs no conversion (a gamma scene with only a colour filter) skips 1 to 4: the pass is then exactly the old colour filter.
@module post

@vs vs
layout(binding=0) uniform post_vs_params {
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

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=1) uniform texture2D expo_tex;    // the adapted exposure (1x1, EV in x); a 1x1 white image when the exposure is not automatic
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform post_params {
    vec4 p;         // x = 1 when the scene is linear (0: gamma), y = 1 when the frame is converted (steps 1 to 4), z = 1 for an HDR output (above paper white), w = colour filter (0 none, 1 greyscale, 2 highContrast, 3 protanopia, 4 deuteranopia, 5 tritanopia)
    vec4 q;         // x = tonemap (0 none, 1 neutral, 2 aces, 3 agx, 4 reinhard), y = exposure multiplier 2^EV (manual) or 2^compensation (auto), z = 1 for the automatic exposure, w = dither amplitude (one 8-bit step, 0 = off)
    vec4 r;         // xy = size of the picture in pixels (for the dither pattern)
    vec4 h;         // the HDR tonemap (p.z = 1): x = headroom (how many times paper white), y = the scene value where the HDR curve leaves the SDR one, z = the SDR curve's slope there, w = its display value there
};
in vec2 uv;
out vec4 frag_color;

// One channel made safe before the exposure and the tonemap: NaN, Inf (found by their bits, as bloom.glsl and exposure.glsl do) and
// anything from 65000 up become 0, so a bad pixel is black on every GPU and never NaN (Reinhard turns an Inf into NaN, and clamp(NaN)
// differs between backends).
float sane(float x) {
    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u || x >= 65000.0) return 0.0;
    return x;
}
vec3 to_linear(vec3 c) {
    return mix(pow(max((c + 0.055) / 1.055, vec3(0.0)), vec3(2.4)), c / 12.92, vec3(lessThanEqual(c, vec3(0.04045))));
}
vec3 to_srgb(vec3 c) {
    c = clamp(c, 0.0, 1.0);
    return mix(1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, c * 12.92, vec3(lessThanEqual(c, vec3(0.0031308))));
}
// A gamma scene can hold colours above white (a float target): decode them with the same curve extended past 1, and keep a negative's sign.
vec3 to_linear_ext(vec3 c) {
    vec3 a = abs(c);
    vec3 l = mix(pow(max((a + 0.055) / 1.055, vec3(0.0)), vec3(2.4)), a / 12.92, vec3(lessThanEqual(a, vec3(0.04045))));
    return sign(c) * l;
}

// ---- tonemaps: scene-linear in, display-linear 0..1 out ------------------------------------------------------------------------
vec3 tonemap_reinhard(vec3 c) {
    return c / (1.0 + c);
}

// A narrow fit of the ACES reference rendering (Narkowicz): a filmic toe and shoulder, saturating highlights.
vec3 tonemap_aces(vec3 c) {
    c = c * 0.6;
    return clamp((c * (2.51 * c + 0.03)) / (c * (2.43 * c + 0.59) + 0.14), 0.0, 1.0);
}

// Keeps everything below 0.76 as it is and rolls the peak channel off toward 1 above it, with a little desaturation of the part that was
// compressed, so a bright saturated colour goes toward white instead of clipping to a hue.
vec3 tonemap_neutral(vec3 c) {
    c = max(c, vec3(0.0));
    float peak = max(c.r, max(c.g, c.b));
    const float start = 0.76;
    if (peak <= start) return c;
    float d = 1.0 - start;
    float new_peak = 1.0 - d * d / (peak + d - start);
    c *= new_peak / peak;
    float g = 1.0 - 1.0 / (0.15 * (peak - new_peak) + 1.0);
    return mix(c, vec3(new_peak), g);
}

// AgX (Troy Sobotka's look: an inset to a smaller gamut, a log2 encode over 16.5 stops, a sigmoid, the matching outset), with the
// polynomial fit of its default contrast curve. The result is display-linear.
vec3 agx_contrast(vec3 x) {
    vec3 x2 = x * x;
    vec3 x4 = x2 * x2;
    return 15.5 * x4 * x2 - 40.14 * x4 * x + 31.96 * x4 - 6.868 * x2 * x + 0.4298 * x2 + 0.1191 * x - 0.00232;
}
vec3 tonemap_agx(vec3 c) {
    const mat3 srgb_to_rec2020 = mat3(vec3(0.6274, 0.0691, 0.0164), vec3(0.3293, 0.9195, 0.0880), vec3(0.0433, 0.0113, 0.8956));
    const mat3 rec2020_to_srgb = mat3(vec3(1.6605, -0.1246, -0.0182), vec3(-0.5876, 1.1329, -0.1006), vec3(-0.0728, -0.0083, 1.1187));
    const mat3 inset = mat3(vec3(0.856627153315983, 0.137318972929847, 0.11189821299995),
                            vec3(0.0951212405381588, 0.761241990602591, 0.0767994186031903),
                            vec3(0.0482516061458583, 0.101439036467562, 0.811302368396859));
    const mat3 outset = mat3(vec3(1.1271005818144368, -0.1413297634984383, -0.14132976349843826),
                             vec3(-0.11060664309660323, 1.157823702216272, -0.11060664309660294),
                             vec3(-0.016493938717834573, -0.016493938717834257, 1.2519364065950405));
    const float min_ev = -12.47393;
    const float max_ev = 4.026069;
    c = inset * (srgb_to_rec2020 * max(c, vec3(0.0)));
    c = log2(max(c, vec3(1e-10)));
    c = clamp((c - min_ev) / (max_ev - min_ev), 0.0, 1.0);
    c = agx_contrast(c);
    c = outset * c;
    c = pow(max(c, vec3(0.0)), vec3(2.2));
    return clamp(rec2020_to_srgb * c, 0.0, 1.0);
}

vec3 tonemap(vec3 c, int mode) {
    if (mode == 1) return tonemap_neutral(c);
    if (mode == 2) return tonemap_aces(c);
    if (mode == 3) return tonemap_agx(c);
    if (mode == 4) return tonemap_reinhard(c);
    return clamp(c, 0.0, 1.0);
}

// The tonemap of an HDR output (hdr_encode.h, tonemap_hdr, is the same maths on the CPU): the SDR curve below its shoulder, then the
// brightest channel rolls off toward the headroom H instead of toward 1, with the same value and slope where the two meet; the colour
// keeps the SDR curve's ratios between its channels. Between H = 1 and 2 it is mixed with the SDR curve, so a headroom that follows the
// screen never jumps. `none` clips at the headroom.
vec3 tonemap_hdr(vec3 c, int mode) {
    float hr = max(h.x, 1.0);
    if (mode < 1 || mode > 4) return clamp(c, 0.0, hr);
    vec3 s = tonemap(c, mode);
    float cm = max(c.r, max(c.g, c.b));
    if (hr <= 1.0 || !(cm > h.y)) return s;
    float x = h.z * (cm - h.y) / (hr - h.w);
    float e = h.w + (hr - h.w) * x / (1.0 + x);
    float t = tonemap(vec3(cm), mode).r;
    float peak = mix(t, e, clamp(hr - 1.0, 0.0, 1.0));
    return s * (peak / max(t, 1e-6));
}
// The sRGB transfer function extended past 1 (an HDR output): negatives are 0, the curve goes on above white.
vec3 to_srgb_ext(vec3 c) {
    c = max(c, vec3(0.0));
    return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, c * 12.92, vec3(lessThanEqual(c, vec3(0.0031308))));
}

// Interleaved gradient noise (Jimenez): a fixed pattern from the pixel position, so a run is reproducible.
float dither_noise(vec2 pixel) {
    return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

// ---- the colour filter (the code of colorfilter.glsl): works on the encoded picture, in linear light inside ----------------------
vec3 color_filter(vec3 c, int mode) {
    vec3 o = c;
    if (mode == 1) {
        float y = dot(to_linear(c), vec3(0.2126, 0.7152, 0.0722));
        o = to_srgb(vec3(y));
    } else if (mode == 2) {
        o = clamp((c - 0.5) * 1.8 + 0.5, 0.0, 1.0);
    } else if (mode >= 3) {
        vec3 l = to_linear(c);
        // Machado 2009, severity 1.0, linear RGB. GLSL matrices are column-major: each vec3 is a COLUMN, so the
        // columns below are the table's columns (what pure red, green and blue become).
        mat3 m;
        if (mode == 3) {
            m = mat3(vec3(0.152286, 0.114503, -0.003882), vec3(1.052583, 0.786281, -0.048116), vec3(-0.204868, 0.099216, 1.051998));
        } else if (mode == 4) {
            m = mat3(vec3(0.367322, 0.280085, -0.011820), vec3(0.860646, 0.672501, 0.042940), vec3(-0.227968, 0.047413, 0.968881));
        } else {
            m = mat3(vec3(1.255528, -0.078411, 0.004733), vec3(-0.076749, 0.930809, 0.691367), vec3(-0.178779, 0.147602, 0.303900));
        }
        vec3 err = l - m * l;
        vec3 add = mode == 5 ? vec3(err.r + 0.7 * err.b, err.g + 0.7 * err.b, 0.0)
                             : vec3(0.0, 0.7 * err.r + err.g, 0.7 * err.r + err.b);
        o = to_srgb(l + add);
    }
    return o;
}

void main() {
    vec4 texel = textureLod(sampler2D(tex, smp), uv, 0.0);
    int filter_mode = int(p.w + 0.5);
    vec3 c = texel.rgb;
    if (p.y > 0.5) {
        c = vec3(sane(c.r), sane(c.g), sane(c.b));
        // 1. scene-linear light
        if (p.x < 0.5) c = to_linear_ext(c);
        // 2. exposure
        float mul = q.y;
        if (q.z > 0.5) mul *= exp2(textureLod(sampler2D(expo_tex, smp), vec2(0.5, 0.5), 0.0).r);
        c *= mul;
        // 3. tonemap, then 4. the sRGB encode with a dither of one 8-bit step (an HDR output: above paper white, extended)
        if (p.z > 0.5) {
            c = to_srgb_ext(tonemap_hdr(c, int(q.x + 0.5)));
        } else {
            c = to_srgb(tonemap(c, int(q.x + 0.5)));
        }
        if (q.w > 0.0) c += (dither_noise(uv * r.xy) - 0.5) * q.w;
    }
    // 5. the colour filter works on what the screen shows, so it clamps (an HDR picture too: a filtered frame stays within paper
    //    white); without a filter the picture is kept as it is
    if (filter_mode != 0) c = color_filter(clamp(c, 0.0, 1.0), filter_mode);
    frag_color = vec4(c, filter_mode != 0 ? 1.0 : texel.a);
}
@end

@program post vs fs
