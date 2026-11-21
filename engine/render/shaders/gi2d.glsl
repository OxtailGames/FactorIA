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

@program draw vs_draw fs_draw
@program seed vs_full fs_seed
@program jfa vs_full fs_jfa
