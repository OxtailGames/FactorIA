// FactorIA 2D global illumination: the field P3b reads (docs/design/ARCHITECTURE_RENDERING_GI2D.md, "2D GI field: what P3b reads").
// A camera's field is three RGBA16F images of the same size (the "field texels"), all drawn by the programs of this file:
//
//   draw   quads/triangles of the CPU gather (gi2d_gather.cpp) -> the emission image or the occluder image. The vertices are
//          already in field texel coordinates (0..W, 0..H, y up in WORLD space); the vertex shader only maps them to clip space,
//          turning y over on the backends whose render targets have their origin at the top, so that texture row 0 is the row
//          with the smallest world y on EVERY backend.
//   seed   occluder image -> an image that holds, per texel, the coordinates of its own texel when it is occupied (a > 0.5), else
//          (-1, -1) with a = 0.
//   jfa    one jump-flooding step (the nearest seed among the 9 texels at +-step), the last one also writes the distance.
//   seed_emit  emission image -> the seeds of a second jump-flooding chain (jfa, the same program): the nearest EMITTER (M74-P3b).
//   cascade    one radiance cascade (M74-P3b): every texel of its image is one ray of one probe; it marches the two distance fields, reads
//              what it hits and merges the cascade above it. See the comment above fs_cascade.
//   irradiance the last pass: the rays of every cascade-0 probe averaged into the irradiance image the lit 2D visuals sample.
//
// Coordinates: a full-screen pass gets `uv` = the texture coordinate of its own texel in every backend (as bloom.glsl), so texel
// (i, j) is read with texelFetch at ivec2(i, j) and j counts as the texture does.
@module gi2d

@include color_space.glsl

@vs vs_draw
layout(binding=0) uniform gi2d_vs_params {
    vec4 xf;    // xy = 2 / (field width, height), z = 1 where render targets have their origin at the bottom (OpenGL), else -1
};
layout(location=0) in vec2 pos;    // field texel coordinates
layout(location=1) in vec2 uv0;    // the texture coordinate (a disc: the offset from its centre in radii)
layout(location=2) in vec4 color;
out vec2 uv;
out vec4 col;
void main() {
    vec2 n = pos * xf.xy - 1.0;
    n.y *= xf.z;
    gl_Position = vec4(n, 0.0, 1.0);
    uv = uv0;
    col = color;
}
@end

@fs fs_draw
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform gi2d_fs_params {
    vec4 p;     // x = mode (see below), y = the alpha threshold of mode 5, z = the colour fix of `tex` (fa_tex_fix), w = 0
};
in vec2 uv;
in vec4 col;
out vec4 frag_color;
@include_block color_space
// Modes. Emission image (added):
//   0  a texture that says where it glows: rgb = texture rgb * colour rgb * colour a
//   2  a disc (a Light2D): rgb = colour rgb inside the unit circle of uv
//   3  the texture's own alpha shapes the glow: rgb = colour rgb * texture a * colour a
// Occluder image (replaced; rgb = albedo, a = occupancy):
//   1  solid: albedo = colour rgb, occupancy 1
//   4  a whole opaque cell textured: albedo = texture rgb * colour rgb, occupancy 1 (a solid tile)
//   5  a sprite's own alpha: texture a * colour a >= threshold is occupied, albedo = texture rgb * colour rgb
void main() {
    int mode = int(p.x + 0.5);
    if (mode == 1) {
        frag_color = vec4(col.rgb, 1.0);
        return;
    }
    if (mode == 2) {
        if (dot(uv, uv) > 1.0) discard;
        frag_color = vec4(col.rgb, 1.0);
        return;
    }
    vec4 t = texture(sampler2D(tex, smp), uv);
    t.rgb = fa_tex_fix(t.rgb, p.z);
    if (mode == 0) {
        frag_color = vec4(t.rgb * col.rgb * col.a, 1.0);
    } else if (mode == 3) {
        frag_color = vec4(col.rgb * (t.a * col.a), 1.0);
    } else if (mode == 4) {
        frag_color = vec4(t.rgb * col.rgb, 1.0);
    } else {
        if (t.a * col.a < p.y) discard;
        frag_color = vec4(t.rgb * col.rgb, 1.0);
    }
}
@end

@vs vs_full
layout(binding=0) uniform gi2d_full_vs_params {
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

@fs fs_seed
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform gi2d_seed_params {
    vec4 size;      // xy = the field's size in texels
};
in vec2 uv;
out vec4 frag_color;
void main() {
    ivec2 ip = ivec2(floor(uv * size.xy));
    float occ = texelFetch(sampler2D(tex, smp), ip, 0).a;
    frag_color = occ > 0.5 ? vec4(vec2(ip), 0.0, 1.0) : vec4(-1.0, -1.0, 0.0, 0.0);
}
@end

@fs fs_jfa
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform gi2d_jfa_params {
    vec4 q;         // xy = the field's size in texels, z = the step in texels, w = 1: the last step (writes the distance too)
};
in vec2 uv;
out vec4 frag_color;
void main() {
    ivec2 ip = ivec2(floor(uv * q.xy));
    ivec2 sz = ivec2(q.xy);
    int step_ = int(q.z + 0.5);
    float best = 1.0e30;
    vec2 seed = vec2(-1.0);
    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            ivec2 sp = ip + ivec2(dx, dy) * step_;
            if (sp.x < 0 || sp.y < 0 || sp.x >= sz.x || sp.y >= sz.y) continue;
            vec4 s = texelFetch(sampler2D(tex, smp), sp, 0);
            if (s.a < 0.5) continue;
            vec2 d = s.xy - vec2(ip);
            float dd = dot(d, d);
            if (dd < best) {
                best = dd;
                seed = s.xy;
            }
        }
    }
    bool found = best < 1.0e29;
    if (q.w > 0.5) {
        frag_color = found ? vec4(seed, sqrt(best), 1.0) : vec4(-1.0, -1.0, 65504.0, 0.0);
    } else {
        frag_color = found ? vec4(seed, 0.0, 1.0) : vec4(-1.0, -1.0, 0.0, 0.0);
    }
}
@end

// The seeds of the emitter distance chain (M74-P3b): a texel that glows (any emission above a hair) names itself, the others hold (-1, -1) with
// a = 0, as fs_seed does for the occluders.
@fs fs_seed_emit
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform gi2d_seed_emit_params {
    vec4 size;      // xy = the field's size in texels
};
in vec2 uv;
out vec4 frag_color;
void main() {
    ivec2 ip = ivec2(floor(uv * size.xy));
    vec3 e = texelFetch(sampler2D(tex, smp), ip, 0).rgb;
    frag_color = (e.r + e.g + e.b) > 0.0001 ? vec4(vec2(ip), 0.0, 1.0) : vec4(-1.0, -1.0, 0.0, 0.0);
}
@end

// One radiance cascade (docs/design/ARCHITECTURE_RENDERING_GI2D.md, "The cascades (P3b)"). The image of cascade i has the size of the field rounded
// up to a multiple of the largest probe spacing, and is cut into S x S tiles (S = the cascade's probe spacing in texels, 2, 4, 8, ... or 4, 8,
// ...): tile (dx, dy) holds ray number j = dy * S + dx of EVERY probe, laid out like the probes themselves (one texel per probe), so two
// neighbouring probes of one direction are two neighbouring texels and the hardware's bilinear filter interpolates between probes. The
// probe (px, py) of cascade i sits at the field texel ((px, py) + 0.5) * S; its ray j has the angle 2 pi (j + 0.5) / (S * S) and covers the
// distance interval [start, end) in texels from the probe. The cascade above has probes twice as far apart and four times as many rays,
// the children 4j .. 4j + 3 of ray j, so a ray that reaches the end of its interval without a hit adds the average of its four children,
// read at the probe's own position with the bilinear filter.
//
// The march is sphere tracing on two distance fields at once: the nearest occluder (P3a's distance image) and the nearest emitter. A ray ends
// at the first texel centre it comes within one texel of: an emitter gives its emission, an occluder gives its own emission plus
// bounce * albedo * the irradiance of the previous frame at the point where the ray stopped (the colour of what it bounces). A ray that
// leaves the field ends too (no light comes from outside). rgb = the radiance the ray brings (merged with the cascades above), a = 1 when it
// ended on something.
@fs fs_cascade
layout(binding=0) uniform texture2D c_occ_dist;     // P3a's distance image: nearest occluder
layout(binding=1) uniform texture2D c_emit_dist;    // the jump-flooding chain of the emission: nearest emitter
layout(binding=2) uniform texture2D c_emission;
layout(binding=3) uniform texture2D c_albedo;       // the occluder image (rgb = albedo)
layout(binding=4) uniform texture2D c_upper;        // the merged cascade above (any image for the top cascade)
layout(binding=5) uniform texture2D c_hist;         // the irradiance of the previous frame (any image when none)
layout(binding=0) uniform sampler c_near;
layout(binding=1) uniform sampler c_lin;
layout(binding=1) uniform gi2d_cascade_params {
    vec4 a;     // xy = size of the cascade image in texels, zw = size of the field in texels
    vec4 b;     // x = probe spacing S of this cascade, y = start of its interval in texels, z = end, w = 1 for the top cascade
    vec4 c;     // x = bounce, y = 1 when c_hist holds the previous irradiance, zw = this field's origin minus the one c_hist was made for, in texels
    vec4 d;     // x = the most steps a ray takes
};
in vec2 uv;
out vec4 frag_color;

// The irradiance image covers the field texels [0, a.xy) and holds rgb premultiplied by a = 1 where its probe is free: the weighted
// filter divides by what the footprint holds, so a probe inside a wall never darkens its neighbours.
vec3 history_at(vec2 pos) {
    if (c.y < 0.5) return vec3(0.0);
    vec2 hp = pos + c.zw;
    if (hp.x < 0.0 || hp.y < 0.0 || hp.x >= a.z || hp.y >= a.w) return vec3(0.0);
    vec4 e = textureLod(sampler2D(c_hist, c_lin), hp / a.xy, 0.0);
    return e.a > 0.02 ? e.rgb / e.a : vec3(0.0);
}

void main() {
    ivec2 isz = ivec2(a.xy);
    ivec2 ip = ivec2(floor(uv * a.xy));
    int S = int(b.x + 0.5);
    ivec2 grid = isz / S;
    ivec2 tile = ip / grid;
    ivec2 probe = ip - tile * grid;
    int j = tile.y * S + tile.x;
    float ang = 6.28318530718 * (float(j) + 0.5) / float(S * S);
    vec2 dir = vec2(cos(ang), sin(ang));
    vec2 center = (vec2(probe) + 0.5) * float(S);
    float t = b.y;
    bool ended = false;
    vec3 rad = vec3(0.0);
    int steps = int(d.x + 0.5);
    for (int k = 0; k < steps; ++k) {
        vec2 pos = center + dir * t;
        if (pos.x < 0.0 || pos.y < 0.0 || pos.x >= a.z || pos.y >= a.w) {
            ended = true;
            break;
        }
        ivec2 ipos = ivec2(pos);
        vec4 so = texelFetch(sampler2D(c_occ_dist, c_near), ipos, 0);
        vec4 se = texelFetch(sampler2D(c_emit_dist, c_near), ipos, 0);
        float dO = so.a > 0.5 ? length(so.xy + 0.5 - pos) : 1.0e9;
        float dE = se.a > 0.5 ? length(se.xy + 0.5 - pos) : 1.0e9;
        float dn = min(dO, dE);
        if (dn < 1.0) {
            ended = true;
            if (dE <= dO) {
                rad = texelFetch(sampler2D(c_emission, c_near), ivec2(se.xy), 0).rgb;
            } else {
                ivec2 q = ivec2(so.xy);
                rad = texelFetch(sampler2D(c_emission, c_near), q, 0).rgb;
                rad += c.x * texelFetch(sampler2D(c_albedo, c_near), q, 0).rgb * history_at(pos);
            }
            break;
        }
        if (dn > 1.0e8) { t = b.z; break; }     // nothing to hit anywhere: the rest of the interval is empty
        t += max(dn - 0.75, 0.5);
        if (t >= b.z) break;
    }
    if (!ended && b.w < 0.5) {
        // Merge: the four children of this ray in the cascade above, at this probe's position (bilinear between that cascade's probes).
        int S2 = S * 2;
        ivec2 grid2 = isz / S2;
        vec2 pc = clamp(center / float(S2), vec2(0.5), vec2(grid2) - 0.5);
        vec3 sum = vec3(0.0);
        for (int m = 0; m < 4; ++m) {
            int jj = j * 4 + m;
            ivec2 t2 = ivec2(jj % S2, jj / S2);
            sum += textureLod(sampler2D(c_upper, c_lin), (vec2(t2 * grid2) + pc) / a.xy, 0.0).rgb;
        }
        rad += sum * 0.25;
    }
    frag_color = vec4(rad, ended ? 1.0 : 0.0);
}
@end

// The irradiance image: texel (px, py) is the probe of cascade 0 at the field texel ((px, py) + 0.5) * S. rgb = the mean of the radiance
// of all its S * S rays (what a flat surface facing every direction receives, in the units of the emission), multiplied by a = 1 when the probe
// is in free space and 0 when it lies inside an occluder or an emitter (nothing is known there; the visuals' filter skips it).
@fs fs_irradiance
layout(binding=0) uniform texture2D r_cascade;      // the merged cascade 0
layout(binding=1) uniform texture2D r_occ_dist;
layout(binding=2) uniform texture2D r_emit_dist;
layout(binding=0) uniform sampler r_near;
layout(binding=1) uniform gi2d_irradiance_params {
    vec4 a;     // x = probe spacing S of cascade 0, yz = size of the cascade image in texels, w = 0
};
in vec2 uv;
out vec4 frag_color;
void main() {
    int S = int(a.x + 0.5);
    ivec2 isz = ivec2(a.yz);
    ivec2 grid = isz / S;
    ivec2 probe = ivec2(floor(uv * vec2(grid)));
    vec3 sum = vec3(0.0);
    for (int dy = 0; dy < S; ++dy) {
        for (int dx = 0; dx < S; ++dx) {
            sum += texelFetch(sampler2D(r_cascade, r_near), ivec2(dx, dy) * grid + probe, 0).rgb;
        }
    }
    ivec2 at = ivec2((vec2(probe) + 0.5) * float(S));
    vec4 so = texelFetch(sampler2D(r_occ_dist, r_near), at, 0);
    vec4 se = texelFetch(sampler2D(r_emit_dist, r_near), at, 0);
    float inside = ((so.a > 0.5 && so.z < 0.5) || (se.a > 0.5 && se.z < 0.5)) ? 1.0 : 0.0;
    float free_ = 1.0 - inside;
    frag_color = vec4(sum / float(S * S) * free_, free_);
}
@end

@program draw vs_draw fs_draw
@program seed vs_full fs_seed
@program jfa vs_full fs_jfa
@program seed_emit vs_full fs_seed_emit
@program cascade vs_full fs_cascade
@program irradiance vs_full fs_irradiance
