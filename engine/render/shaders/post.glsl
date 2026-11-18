// FactorIA post-processing stack (M71, PostProcess): the FINAL pass, one full-screen triangle that fuses the lens, exposure, tonemap, the
// output encode (with dithering), the display-space effects and the accessibility colour filter. It reads the finished game target and
// writes the picture present() and the captures show. The bloom has its own chain (bloom.glsl) and runs before this pass, on the
// scene-referred colour (so the glow is bent by the lens with the rest of the picture).
//
//   0. how the scene is read (only with lensDistortion / chromaticAberration, bit 1 / 2 of ex.x): the pixel samples the scene at a bent
//      position (bilinear; black where the lens looks beyond the picture), red and blue a little further out and in than green
//   1. the input to scene-linear light: a gamma scene (SceneSettings.colorSpace gamma) holds sRGB-encoded values, which are decoded;
//      a linear scene is used as it is
//   2. exposure: x 2^EV (manual: PostProcess.exposureEv; auto: the adapted EV of exposure.glsl plus the compensation)
//   3. tonemap: none (a clip), neutral, ACES, AgX, Reinhard
//   4. the encode: the sRGB transfer function. For an HDR window (p.z = 1) the tonemap goes above paper white up to the output's
//      headroom (h.x; tonemap_hdr) and the sRGB curve is extended past 1: the target then holds display light ENCODED, 1.0 = paper
//      white, and present() (blit.glsl) encodes it for the swapchain (scRGB, HDR10 PQ, EDR)
//   5. the display-space effects, on the encoded picture (what the screen shows), none of them clipping above 1: colour grading (white
//      balance, gain, lift, gamma, contrast, saturation, hue, then the LUT), the vignette, the sharpen (it shades the four neighbours of
//      the pixel through 0 to 5 too), the film grain; then the dither of one 8-bit step
//      then (M71-C2) the outline (depth mode: the edges of the prepass image; sprite mode: the border outside the alpha of the 2D
//      coverage image, both read by texel from aux_tex), the pixelate (the position every step above reads is moved to the centre of
//      its block, so the whole of 0 to 5 is evaluated once per block) and the posterize (levels per channel); the grain and the dither
//      keep the real pixel
//   6. the colour filter (Camera.colorFilter), on the encoded picture, the same filters as colorfilter.glsl
//
// A frame that needs no conversion (a gamma scene with only a colour filter) skips 1 to 4: the pass is then exactly the old colour filter.
// A frame without any effect of 0 and 5 (ex.x = 0) runs exactly the code it did before them: they are all behind uniform branches.
// The CPU form of the effects' maths is post_fx.cpp (the tests compare the two).
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
layout(binding=2) uniform texture2D lut_tex;     // the colour grading LUT as a strip of slices (RGBA8, cube_lut.h); a 1x1 white image when there is none
layout(binding=3) uniform texture2D aux_tex;     // the outline's image: the prepass (depth mode) or the sprite coverage (sprite mode); a 1x1 white image when there is none
layout(binding=0) uniform sampler smp;           // nearest: the source has the size of the destination
layout(binding=1) uniform sampler lin_smp;       // bilinear, clamp to edge: the lens and the LUT
layout(binding=2) uniform sampler aux_smp;       // nearest, and read by texelFetch: the prepass is a float image that cannot be filtered
@image_sample_type aux_tex unfilterable_float
@sampler_type aux_smp nonfiltering
layout(binding=1) uniform post_params {
    vec4 p;         // x = 1 when the scene is linear (0: gamma), y = 1 when the frame is converted (steps 1 to 4), z = 1 for an HDR output (above paper white), w = colour filter (0 none, 1 greyscale, 2 highContrast, 3 protanopia, 4 deuteranopia, 5 tritanopia)
    vec4 q;         // x = tonemap (0 none, 1 neutral, 2 aces, 3 agx, 4 reinhard), y = exposure multiplier 2^EV (manual) or 2^compensation (auto), z = 1 for the automatic exposure, w = dither amplitude (one 8-bit step, 0 = off)
    vec4 r;         // xy = size of the picture in pixels (for the dither pattern)
    vec4 h;         // the HDR tonemap (p.z = 1): x = headroom (how many times paper white), y = the scene value where the HDR curve leaves the SDR one, z = the SDR curve's slope there, w = its display value there
};
layout(binding=2) uniform post_fx_params {
    vec4 ex;        // x = the effect mask (1 lens, 2 chromatic aberration, 4 grade, 8 LUT, 16 vignette, 32 sharpen, 64 grain, 128 outline (depth), 256 outline (sprite), 512 pixelate, 1024 posterize; 0 = none), y = 1 when render targets are bottom-up (OpenGL), z = width / height, w = the grain's seed (a whole number below 2^24)
    vec4 ln;        // lens: x = k (the radius grows by 1 + k r^2), y = zoom, zw = the centre (screen uv, top-left origin)
    vec4 ab;        // x = the aberration (red and blue move by (uv - 0.5) * x), y = the sharpen weight of each neighbour (negative), z = the LUT contribution, w = contrast
    vec4 wb;        // rgb = white balance gains, w = saturation
    vec4 lf;        // rgb = lift, w = the hue matrix's a
    vec4 gn;        // rgb = gain, w = the hue matrix's b
    vec4 ig;        // rgb = 1 / gamma, w = the hue matrix's c
    vec4 vg;        // vignette: x = intensity, y = smoothness, z = roundness, w = the grain's intensity (already x its strength)
    vec4 vc;        // xy = the vignette's centre (screen uv), z = the grain's size in pixels, w = the grain's luminance response
    vec4 vk;        // rgb = the vignette's colour
    vec4 lt;        // the LUT strip: x = size (colours per side), y = tiles across, z = tiles down
    vec4 ol;        // outline: x = width in pixels, y = the depth threshold, z = the normal threshold, w = the alpha threshold
    vec4 oc;        // rgba = the outline's colour (alpha = its opacity)
    vec4 ap;        // x = the pixelate block in pixels, y = the posterize levels, zw = the size of aux_tex in texels
    vec4 ax;        // the screen uv to aux_tex uv map: xy = scale, zw = offset (the prepass has the size of the picture today: 1, 1, 0, 0)
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

// ---- the screen effects (post_fx.cpp is the same maths on the CPU) ------------------------------------------------------------------
// Screen space `s`: the picture's uv with the origin at the top left on every backend (the effects' centres and the grain's pixels are
// written in it); `uv` is where this backend's render target has its origin. Their conversion is its own inverse.
vec2 flip_v(vec2 s) {
    return vec2(s.x, mix(s.y, 1.0 - s.y, ex.y));
}

// Where the lens reads the scene for the pixel at s: the radius from the centre grows by (1 + k r^2) / zoom, r = 1 at a corner.
vec2 lens_source(vec2 s) {
    float aspect = ex.z;
    vec2 d = s - ln.zw;
    d.x *= aspect;
    float r2 = dot(d, d) / (0.25 * (aspect * aspect + 1.0));
    d *= (1.0 + ln.x * r2) / ln.y;
    d.x /= aspect;
    return ln.zw + d;
}

vec4 scene_tap(vec2 s) {
    return textureLod(sampler2D(tex, lin_smp), flip_v(s), 0.0);
}

// The scene at screen position s, as the lens and the aberration read it (fm = the effect mask). A pixel with neither reads its own
// texel; with the mask 0 that is `uv` itself, so a frame without effects reads exactly what it did before them.
vec4 read_scene(vec2 s, int fm) {
    if (fm == 0) return textureLod(sampler2D(tex, smp), uv, 0.0);
    if ((fm & 3) == 0) return textureLod(sampler2D(tex, smp), flip_v(s), 0.0);
    vec2 t = s;
    if ((fm & 1) != 0) {
        t = lens_source(s);
        if (t.x < 0.0 || t.y < 0.0 || t.x > 1.0 || t.y > 1.0) return vec4(0.0, 0.0, 0.0, 1.0);  // beyond the picture: black
    }
    if ((fm & 2) != 0) {
        vec2 d = (t - 0.5) * ab.x;
        vec4 g = scene_tap(t);
        return vec4(scene_tap(t + d).r, g.g, scene_tap(t - d).b, g.a);
    }
    return scene_tap(t);
}

// Steps 1 to 4: scene colour to the encoded display picture (no dither).
vec3 convert_scene(vec3 c, float mul) {
    c = vec3(sane(c.r), sane(c.g), sane(c.b));
    // 1. scene-linear light
    if (p.x < 0.5) c = to_linear_ext(c);
    // 2. exposure
    c *= mul;
    // 3. tonemap, then 4. the sRGB encode (an HDR output: above paper white, extended)
    if (p.z > 0.5) return to_srgb_ext(tonemap_hdr(c, int(q.x + 0.5)));
    return to_srgb(tonemap(c, int(q.x + 0.5)));
}

// Colour grading on the encoded picture: white balance and gain (multiplied in), lift (added to what is below white), gamma, contrast
// around 0.5, saturation, the hue's rotation about the grey axis. Nothing clips above 1; nothing goes below 0.
vec3 grade(vec3 c) {
    c = c * wb.rgb * gn.rgb;
    c += lf.rgb * (1.0 - clamp(c, 0.0, 1.0));
    c = pow(max(c, vec3(0.0)), ig.rgb);
    c = max((c - 0.5) * ab.w + 0.5, vec3(0.0));
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    c = vec3(l) + (c - vec3(l)) * wb.w;
    c = vec3(dot(c, vec3(lf.w, gn.w, ig.w)), dot(c, vec3(ig.w, lf.w, gn.w)), dot(c, vec3(gn.w, ig.w, lf.w)));
    return max(c, vec3(0.0));
}

// One slice of the LUT strip at (red, green): the slices are tiled lt.y across; the sample is at texel centres, so the bilinear
// footprint never leaves the slice.
vec3 lut_slice(vec2 rg, int slice) {
    int cols = int(lt.y + 0.5);
    vec2 tile = vec2(float(slice % cols), float(slice / cols));
    vec2 inside = rg * (lt.x - 1.0) + 0.5;
    vec2 at = (tile * lt.x + inside) / (vec2(lt.y, lt.z) * lt.x);
    return textureLod(sampler2D(lut_tex, lin_smp), at, 0.0).rgb;
}
// The LUT is looked up at the picture clamped to 0..1 (trilinear: the bilinear of the strip between two slices, mixed by hand); what it
// changes is added to the picture, so the part above white is kept.
vec3 apply_lut(vec3 c) {
    vec3 x = clamp(c, 0.0, 1.0);
    float n = lt.x;
    float bz = x.b * (n - 1.0);
    float b0 = min(floor(bz), n - 2.0);
    vec3 l = mix(lut_slice(x.rg, int(b0 + 0.5)), lut_slice(x.rg, int(b0 + 1.5)), bz - b0);
    return c + (l - x) * ab.z;
}

vec3 apply_vignette(vec3 c, vec2 s) {
    vec2 d = s - vc.xy;
    d.x *= mix(1.0, ex.z, vg.z);
    float rad = length(d) * 1.41421356;
    float w = mix(0.02, 1.0, vg.y);
    return mix(c, vk.rgb, vg.x * smoothstep(1.0 - w, 1.0, rad));
}

// Everything per pixel up to and including the vignette: what the sharpen compares a pixel with its neighbours in.
vec4 shade(vec2 s, int fm, float mul) {
    vec4 t = read_scene(s, fm);
    vec3 c = t.rgb;
    if (p.y > 0.5) c = convert_scene(c, mul);
    else if (fm != 0) c = vec3(sane(c.r), sane(c.g), sane(c.b));
    if ((fm & 4) != 0) c = grade(c);
    if ((fm & 8) != 0) c = apply_lut(c);
    if ((fm & 16) != 0) c = apply_vignette(c, s);
    return vec4(c, t.a);
}

// Contrast-adaptive sharpen (after AMD CAS): the four neighbours are subtracted, weighted by how far the neighbourhood is from the limits
// of the range, so flat areas and edges already at black or white are not pushed (no halos, no clipping).
vec3 apply_sharpen(vec3 c, vec3 n, vec3 e, vec3 sth, vec3 w) {
    vec3 mn = min(min(min(c, n), min(e, sth)), w);
    vec3 mx = max(max(max(c, n), max(e, sth)), w);
    vec3 amp = sqrt(clamp(min(mn, 1.0 - mx) / max(mx, vec3(1e-4)), 0.0, 1.0));
    vec3 k = amp * ab.y;
    return max((c + k * (n + e + sth + w)) / (1.0 + 4.0 * k), vec3(0.0));
}

// PCG hash on whole numbers: the same bits on every GPU, so a run is reproducible.
uint pcg(uint v) {
    uint st = v * 747796405u + 2891336453u;
    uint wd = ((st >> ((st >> 28u) + 4u)) ^ st) * 277803737u;
    return (wd >> 22u) ^ wd;
}
// Film grain: monochrome triangular noise per cell of vc.z pixels, from the pixel, the frame's seed and nothing else, scaled by how mid-toned
// the pixel is (vc.w) and by its intensity (vg.w).
vec3 apply_grain(vec3 c, vec2 s) {
    vec2 cell = floor((floor(s * r.xy) + 0.5) / vc.z);
    uint h1 = pcg(uint(int(cell.x)) + pcg(uint(int(cell.y)) + pcg(uint(ex.w + 0.5))));
    uint h2 = pcg(h1 ^ 0x68E31DA4u);
    float noise = float(h1 >> 8u) * (1.0 / 16777216.0) + float(h2 >> 8u) * (1.0 / 16777216.0) - 1.0;
    float l = clamp(dot(c, vec3(0.2126, 0.7152, 0.0722)), 0.0, 1.0);
    float weight = mix(1.0, 4.0 * l * (1.0 - l), vc.w);
    return max(c + vec3(noise * vg.w * weight), vec3(0.0));
}

// ---- outline, pixelate, posterize ------------------------------------------------------------------------------------------------
// aux_tex at screen position s, `off` texels away (the offset is in screen orientation: the texel row is flipped after it on a bottom-up
// backend, like the game image). Read by whole texels, clamped to the image, so the border never reads beyond it.
vec4 aux_at(vec2 s, ivec2 off) {
    ivec2 sz = ivec2(ap.zw + 0.5);
    vec2 a = s * ax.xy + ax.zw;
    ivec2 t = clamp(ivec2(floor(a * ap.zw)) + off, ivec2(0), sz - 1);
    if (ex.y > 0.5) t.y = sz.y - 1 - t.y;
    return texelFetch(sampler2D(aux_tex, aux_smp), t, 0);
}

// The view-space normal of the prepass (octahedral, see prepass_view.glsl).
vec3 oct_decode(vec2 e) {
    vec3 n = vec3(e.x, e.y, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * vec2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

// 1 when an edge runs between the two prepass texels: one is a mesh and the other is not (the silhouette), or both are and their depth
// jumps by more than ol.y of the nearer (the limit grows where the surface is seen at a grazing angle, where a flat floor changes depth
// from texel to texel), or their normals differ by more than ol.z.
float depth_edge(vec4 a, vec4 b) {
    bool ca = a.a > 0.5;
    bool cb = b.a > 0.5;
    if (!ca && !cb) return 0.0;
    if (ca != cb) return 1.0;
    vec3 na = oct_decode(a.gb);
    vec3 nb = oct_decode(b.gb);
    float facing = clamp(0.5 * (abs(na.z) + abs(nb.z)), 0.2, 1.0);
    if (abs(a.r - b.r) / max(min(a.r, b.r), 1e-3) > ol.y / facing) return 1.0;
    return length(na - nb) > ol.z ? 1.0 : 0.0;
}

// Depth outline: a Roberts cross over a window of ol.x pixels (lo texels before the pixel, hi after: the edge between two texels marks
// lo + hi pixels, the width of the line).
vec3 apply_outline_depth(vec3 c, vec2 s) {
    float w = ol.x;
    int lo = int(floor(w * 0.5));
    int hi = max(int(ceil(w * 0.5)), 1);
    vec4 ta = aux_at(s, ivec2(-lo, -lo));
    vec4 tb = aux_at(s, ivec2(hi, hi));
    vec4 tc = aux_at(s, ivec2(hi, -lo));
    vec4 td = aux_at(s, ivec2(-lo, hi));
    float e = max(depth_edge(ta, tb), depth_edge(tc, td));
    return mix(c, oc.rgb, oc.a * e * min(w, 1.0));
}

bool sprite_at(vec2 s, ivec2 off) {
    return aux_at(s, off).a >= ol.w;
}
// One ring of eight taps (four along the axes, four diagonal) at the distance k.
bool sprite_ring(vec2 s, int k) {
    int d = max(int(float(k) * 0.70710678 + 0.5), 1);
    return sprite_at(s, ivec2(k, 0)) || sprite_at(s, ivec2(-k, 0)) || sprite_at(s, ivec2(0, k)) || sprite_at(s, ivec2(0, -k)) ||
           sprite_at(s, ivec2(d, d)) || sprite_at(s, ivec2(-d, d)) || sprite_at(s, ivec2(d, -d)) || sprite_at(s, ivec2(-d, -d));
}

// Sprite outline: the line is drawn OUTSIDE the sprites. A pixel inside one (alpha at the threshold or above) is left as it is; any
// other pixel with a sprite within the width (the ring at the width, and one at half of it for thin sprites) takes the outline colour.
vec3 apply_outline_sprite(vec3 c, vec2 s) {
    if (sprite_at(s, ivec2(0, 0))) return c;
    int k = max(int(ol.x + 0.5), 1);
    bool hit = sprite_ring(s, k);
    int k2 = (k + 1) / 2;
    if (!hit && k2 < k) hit = sprite_ring(s, k2);
    return hit ? mix(c, oc.rgb, oc.a * min(ol.x, 1.0)) : c;
}

// The pixel whose colour the block of the pixel at s shows: its centre (the last pixel when the edge cuts the block).
vec2 pixelate_at(vec2 s) {
    ivec2 sz = ivec2(r.xy + 0.5);
    ivec2 b = ivec2(int(ap.x + 0.5));
    ivec2 pix = ivec2(floor(s * r.xy));
    ivec2 cp = min((pix / b) * b + b / 2, sz - 1);
    return (vec2(cp) + 0.5) / r.xy;
}

// The encoded colour cut to ap.y levels per channel; what is above white (an HDR output) is kept.
vec3 apply_posterize(vec3 c) {
    float n = ap.y - 1.0;
    vec3 b = clamp(c, 0.0, 1.0);
    return floor(b * n + 0.5) / n + (c - b);
}

void main() {
    int fm = int(ex.x + 0.5);
    int filter_mode = int(p.w + 0.5);
    float mul = q.y;
    if (p.y > 0.5 && q.z > 0.5) mul *= exp2(textureLod(sampler2D(expo_tex, smp), vec2(0.5, 0.5), 0.0).r);
    vec2 s = fm == 0 ? uv : flip_v(uv);
    vec2 s_pixel = s;  // the grain and the dither belong to the real pixel
    if ((fm & 512) != 0) s = pixelate_at(s);
    vec4 px = shade(s, fm, mul);
    vec3 c = px.rgb;
    // 5. (the sharpen needs the neighbours shaded the same way; the grain goes over it)
    if ((fm & 32) != 0) {
        vec2 dx = vec2(1.0 / r.x, 0.0);
        vec2 dy = vec2(0.0, 1.0 / r.y);
        c = apply_sharpen(c, shade(s - dy, fm, mul).rgb, shade(s + dx, fm, mul).rgb, shade(s + dy, fm, mul).rgb,
                          shade(s - dx, fm, mul).rgb);
    }
    if ((fm & 128) != 0) c = apply_outline_depth(c, s);
    if ((fm & 256) != 0) c = apply_outline_sprite(c, s);
    if ((fm & 1024) != 0) c = apply_posterize(c);
    if ((fm & 64) != 0) c = apply_grain(c, s_pixel);
    // the dither of one 8-bit step (q.w: after a conversion or an effect)
    if (q.w > 0.0) c += (dither_noise(uv * r.xy) - 0.5) * q.w;
    // 6. the colour filter works on what the screen shows, so it clamps (an HDR picture too: a filtered frame stays within paper
    //    white); without a filter the picture is kept as it is
    if (filter_mode != 0) c = color_filter(clamp(c, 0.0, 1.0), filter_mode);
    frag_color = vec4(c, filter_mode != 0 ? 1.0 : px.a);
}
@end

@program post vs fs
