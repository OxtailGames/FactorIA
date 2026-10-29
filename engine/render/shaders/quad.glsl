// FactorIA 2D quad shader: sprites, tiles, text glyphs, shapes, particles, debug lines.
// One vertex format for everything:  pos.xyz | uv | color (ubyte4n) | params (mode, aux)
// mode 0 = textured quad (texture * color)
// mode 1 = anti-aliased filled circle   (uv in [-1,1], coverage from the distance to the center)
// mode 2 = anti-aliased ring            (aux = inner radius as a fraction of the outer radius)
// mode 3 = soft round particle          (smooth radial falloff)
// mode 4 = glyph                        (single-channel coverage texture * color)
// mode 5 = lit textured quad            (texture * color * (ambient + 2D lights); aux = angle in radians of the picture's
//                                        right axis in the world, for the normal map)
// mode 6 = like 5, but the picture is mirrored: its up axis lies to the right of its right axis
// mode 7 = SDF shape: a rectangle with rounded corners or a circle (Shape2D.cornerRadius / softness / gradient). uv = the
//          position in the shape's box in units of its half size (so [-1,1] covers the box), shape_half = that half size in
//          local units, shape_rs = (corner radius, softness) in local units, color2 = the gradient's end colour.
//          aux: -1 flat fill; 0..2pi linear gradient, the angle in radians; 10 radial gradient; <= -2 outline of thickness
//          -aux - 2 (growing inward). Gradients and soft edges are dithered.
//          aux + 20 (aux >= 0 only): the gradient is read from a ramp texture (the item's texture, one row per gradient; see
//          engine/render/src/gradient_ramp.h) instead of blended from color to color2: color2.r * 255 is the row, the position
//          along the gradient is the u coordinate. This is how Shape2D gradientStops / gradientEase are drawn.
// mode + 16 = (modes 0, 1, 2, 7 only) the same output, shaded by the 2D lights like mode 5 with a flat surface (lit Shape2D)
// mode + 8 = same shading, but the output is converted for MULTIPLY blending (dst * out.rgb):
//            rgb = mix(1, rgb, alpha) so alpha fades the darkening in (blend: src=DST_COLOR, dst=ZERO).
@module quad

@include light_shadow.glsl

@vs vs
layout(binding=0) uniform vs_params {
    mat4 view_proj;
};

layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord0;
layout(location=2) in vec4 color0;
layout(location=3) in vec2 params0;
layout(location=4) in vec4 color2_0;
layout(location=5) in vec2 shape_half0;
layout(location=6) in vec2 shape_rs0;

out vec2 uv;
out vec4 color;
out vec2 params;
out vec2 world_xy;
out vec4 color2;
out vec2 shape_half;
out vec2 shape_rs;

void main() {
    gl_Position = view_proj * vec4(position, 1.0);
    uv = texcoord0;
    color = color0;
    params = params0;
    world_xy = position.xy;
    color2 = color2_0;
    shape_half = shape_half0;
    shape_rs = shape_rs0;
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=1) uniform texture2D normal_tex;   // lit quads: the normal map (a 1x1 image when unused)
layout(binding=2) uniform texture2D light_tex;    // lit quads, light buffer path: the point lights added up (light.glsl)
layout(binding=3) uniform texture2D shadow_tex;   // lit quads with a shadow caster in reach: one row per light (light_shadow.glsl)
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform sampler light_smp;      // bilinear: the light buffer may be smaller than the target
layout(binding=2) uniform sampler shadow_smp;     // nearest

// Only read by lit quads (mode 5, 6 and the lit shapes). Up to 16 lights: 53 vec4s, far below the WebGL2 / GLES3 minimum
// of 224.
layout(binding=1) uniform quad_fs_params {
    vec4 lit;                  // x = number of lights in the arrays, y = 1 when normal_tex is a real normal map,
                               // z = how a flat surface (no normal map) is lit: 0 = the loop below over the arrays,
                               //     1 = ambient + directional lights (flat_ambient) + the light buffer, 2 = flat_ambient only
    vec4 ambient;              // rgb
    vec4 normal_uv;            // normal map uv = uv * xy + zw
    vec4 flat_ambient;         // rgb: ambient + every directional light, what a flat surface gets from them (lit.z > 0)
    vec4 light_map;            // xy = 1 / the size of the target in pixels, z = the range the light buffer holds
    vec4 light_pos[16];        // point: xyz position (z = height), w radius; directional: xyz unit vector TO the light, w = -1
    vec4 light_color[16];      // rgb color * intensity; w falloff exponent
    vec4 light_shadow_v[16];   // x = v coordinate of the light's row in shadow_tex, -1 = it casts no shadow
};

in vec2 uv;
in vec4 color;
in vec2 params;
in vec2 world_xy;
in vec4 color2;
in vec2 shape_half;
in vec2 shape_rs;
out vec4 frag_color;

@include_block light_shadow

vec3 lit_color(vec4 base, float mode) {
    vec3 n = vec3(0.0, 0.0, 1.0);
    bool use_normal = lit.y > 0.5;
    if (use_normal) {
        vec3 s = texture(sampler2D(normal_tex, smp), uv * normal_uv.xy + normal_uv.zw).xyz * 2.0 - 1.0;
        float a = params.y;
        vec2 t = vec2(cos(a), sin(a));
        vec2 b = vec2(-t.y, t.x) * (mode > 5.5 ? -1.0 : 1.0);
        n = normalize(vec3(s.x * t + s.y * b, max(s.z, 0.05)));
    }
    if (!use_normal && lit.z > 0.5) {
        // A flat surface faces every light head on, so each light adds color * falloff and they add up: the light buffer
        // already holds that sum (gl_FragCoord is the pixel of the same target, in the same orientation).
        vec3 total = flat_ambient.rgb;
        if (lit.z < 1.5) {
            total += textureLod(sampler2D(light_tex, light_smp), gl_FragCoord.xy * light_map.xy, 0.0).rgb * light_map.z;
        }
        return base.rgb * total;
    }
    vec3 total = ambient.rgb;
    for (int i = 0; i < 16; i++) {
        if (float(i) >= lit.x) { break; }
        vec4 lp = light_pos[i];
        vec4 lc = light_color[i];
        vec3 l;
        float att = 1.0;
        if (lp.w < 0.0) {
            l = lp.xyz;
        } else {
            vec2 d = lp.xy - world_xy;
            float dist = length(d);
            att = pow(clamp(1.0 - dist / max(lp.w, 0.001), 0.0, 1.0), lc.w);
            l = vec3(d, lp.z) / max(length(vec3(d, lp.z)), 0.0001);
            if (light_shadow_v[i].x >= 0.0) { att *= light_shadow(light_shadow_v[i].x, -d, lp.w); }
        }
        float ndl = use_normal ? max(dot(n, l), 0.0) : 1.0;
        total += lc.rgb * (att * ndl);
    }
    return base.rgb * total;
}

// Mode 7: the colour and alpha of one pixel of a rounded rectangle / circle, with its gradient and soft edge.
vec4 shape_color() {
    vec2 hs = max(shape_half, vec2(1e-4));
    vec2 p = uv * hs;
    float r = clamp(shape_rs.x, 0.0, min(hs.x, hs.y));
    float soft = shape_rs.y;
    vec2 q = abs(p) - hs + r;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;   // signed distance to the outline, < 0 inside
    float ax = params.y;
    bool ramp = ax > 15.0;
    if (ramp) ax -= 20.0;
    float ring = ax <= -1.5 ? (-ax - 2.0) : 0.0;
    if (ring > 0.0) d = abs(d + ring * 0.5) - ring * 0.5;          // an outline growing inward
    float aa = max(fwidth(d), 1e-4);
    float w = max(soft, aa);
    float t = clamp(0.5 - d / w, 0.0, 1.0);
    float cov = soft > aa ? t * t * (3.0 - 2.0 * t) : t;
    vec4 c = color;
    bool graded = ring <= 0.0 && ax > -0.5;
    if (graded) {
        float g;
        if (ax > 7.0) {
            g = length(uv);
        } else {
            vec2 dir = vec2(cos(ax), sin(ax));
            g = dot(p, dir) / max(abs(dir.x) * hs.x + abs(dir.y) * hs.y, 1e-4) * 0.5 + 0.5;
        }
        g = clamp(g, 0.0, 1.0);
        // Blend premultiplied, so fading to a transparent colour does not darken the middle of the gradient.
        if (ramp) {
            // Straight-alpha texels (the filtering blends them; the stops are baked premultiplied), level 0 only.
            c = textureLod(sampler2D(tex, smp), vec2((0.5 + g * 255.0) / 256.0, (floor(color2.r * 255.0 + 0.5) + 0.5) / 256.0), 0.0);
        } else {
            vec4 pm = mix(vec4(color.rgb * color.a, color.a), vec4(color2.rgb * color2.a, color2.a), g);
            c = vec4(pm.a > 1e-5 ? pm.rgb / pm.a : color.rgb, pm.a);
        }
    }
    c.a *= cov;
    if (graded || soft > 0.0) {
        // Interleaved gradient noise, +-0.5/255: breaks the 8-bit steps of a slow gradient or a wide soft edge into fine grain.
        float n = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715)))) - 0.5;
        c.rgb += n / 255.0;
        c.a = clamp(c.a + n / 255.0 * step(0.001, c.a), 0.0, 1.0);
    }
    return c;
}

void main() {
    float mode = params.x;
    bool shade = mode > 15.5;
    if (shade) mode -= 16.0;
    bool mul = mode > 7.5;
    if (mul) mode -= 8.0;
    if (mode < 0.5) {
        frag_color = texture(sampler2D(tex, smp), uv) * color;
        if (shade) frag_color = vec4(lit_color(frag_color, 5.0), frag_color.a);
    } else if (mode > 6.5) {
        frag_color = shape_color();
        if (shade) frag_color = vec4(lit_color(frag_color, 5.0), frag_color.a);
    } else if (mode > 4.5) {
        vec4 base = texture(sampler2D(tex, smp), uv) * color;
        frag_color = vec4(lit_color(base, mode), base.a);
    } else if (mode > 3.5) {
        frag_color = vec4(color.rgb, color.a * texture(sampler2D(tex, smp), uv).r);
    } else {
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
        frag_color = vec4(shade ? lit_color(color, 5.0) : color.rgb, color.a * cov);
    }
    if (mul) frag_color = vec4(mix(vec3(1.0), frag_color.rgb, frag_color.a), 1.0);
}
@end

// The plain variant, for batches whose quads are all mode 0 (not lit, not multiply): the output of mode 0 above, without
// the branches. Software rasterizers (llvmpipe, WARP) run every branch of `fs` for every pixel, all its texture fetches
// and light loops included, so a screen-sized sprite, panel or video costs several times more there with `fs`.
@fs fs_plain
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
in vec4 color;
in vec2 params;
in vec2 world_xy;
in vec4 color2;
in vec2 shape_half;
in vec2 shape_rs;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(tex, smp), uv) * color;
}
@end

@program quad vs fs
@program quad_plain vs fs_plain
