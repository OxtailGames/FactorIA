// FactorIA reflection probes (M73-P3b, docs/design/ARCHITECTURE_PROBES.md): the programs that fill the probe atlas.
//
// A probe's map is OCTAHEDRAL (the sphere folded onto a square around +Y, include/fa/render/probe.h has the CPU twin of every function here
// and the layout of a tile). Two kinds of target:
//   cube      the six faces of a scratch cube (the capture's faces, then its pyramid): vs_cube turns the pixel into the world direction it looks
//             at from the face's basis, exactly as env.glsl does (the basis is the cube map specification's; `up` arrives negated on OpenGL)
//   atlas     a rectangle of the atlas (one level of a tile with its one-texel border, or the nine texels of the SH row): vs_rect draws a
//             full-screen triangle into a viewport of the rectangle's size, and the fragment finds its texel from gl_FragCoord, which is the
//             memory row and column of the target on every backend (OpenGL stores a render target bottom-up, and its window row IS its
//             memory row). The octahedral coordinate of a texel of the border is beyond [-1, 1]: oct_decode folds it, so the border holds
//             what the texel across the edge holds and a clamped bilinear tap at the edge is exact.
//
//   face       the capture of one face (a 2D picture of the scene, upright on every backend) into the cube face of the scratch pyramid
//   down       one pyramid image from the one before (a bilinear tap at the centre of a 2x2 block is the block's average)
//   oct_cube   a level of a tile from a cube at a lod: the pyramid's first image (level 0) and the sky's prefiltered cube (the sky's tile)
//   oct_ggx    a level of a tile: the pyramid image of about its size convolved with the GGX lobe of the level's roughness (env_ggx.glsl, the
//              code the sky's cube uses)
//   sh         the nine coefficients of the 16 x 16 pyramid image, one texel each (env_ggx.glsl, env_sh_project: the code of the sky)
//   sh_cube    the sky's nine coefficients, copied from mip 5 of its prefiltered cube
//   blit       a rectangle of a 2D image copied to the atlas or to a scratch image (a baked page in, a tile out for the read-back)
//
// Every program writes RGBA16F, or RGBA8 on a GPU that cannot render to half floats (the radiance is then clamped to 0..1, and the SH texels hold
// clamp(c / 4, -1, 1) * 0.5 + 0.5, as the sky's: q.y = 1).
@module probe

@include env_ggx.glsl

@vs vs_rect
layout(location=0) in vec2 pos;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
}
@end

@vs vs_cube
layout(binding=0) uniform probe_vs_params {
    vec4 fwd;
    vec4 right;
    vec4 up;
};
layout(location=0) in vec2 pos;
out vec3 dir;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    dir = fwd.xyz + pos.x * right.xyz + pos.y * up.xyz;
}
@end

// The octahedral map (probe.cpp oct_fold / oct_decode, with the same operations in the same order).
@block probe_oct
float oct_sign(float v) {
    return v < 0.0 ? -1.0 : 1.0;
}

vec2 oct_fold(vec2 e) {
    if (e.x > 1.0) {
        e.x = 2.0 - e.x;
        e.y = -e.y;
    } else if (e.x < -1.0) {
        e.x = -2.0 - e.x;
        e.y = -e.y;
    }
    if (e.y > 1.0) {
        e.y = 2.0 - e.y;
        e.x = -e.x;
    } else if (e.y < -1.0) {
        e.y = -2.0 - e.y;
        e.x = -e.x;
    }
    return e;
}

vec3 oct_decode(vec2 e0) {
    vec2 e = oct_fold(e0);
    float x = e.x;
    float z = e.y;
    float y = 1.0 - abs(x) - abs(z);
    if (y < 0.0) {
        float nx = (1.0 - abs(z)) * oct_sign(x);
        float nz = (1.0 - abs(x)) * oct_sign(z);
        x = nx;
        z = nz;
    }
    return normalize(vec3(x, y, z));
}

// The coordinate of this fragment's texel in the map of the level: region.xy is the memory origin of the rectangle that is drawn (the level's
// border included), region.z the interior texels per side, region.w the border.
vec2 oct_coordinate(vec4 region) {
    return (gl_FragCoord.xy - region.xy - vec2(region.w)) / region.z * 2.0 - vec2(1.0);
}
@end

@block probe_atlas_params
layout(binding=0) uniform sampler probe_smp;
layout(binding=1) uniform probe_params {
    vec4 region;  // the rectangle drawn: x, y = its memory origin in the atlas, z = interior texels per side, w = border
    vec4 p;       // x = roughness, y = samples, z = the most a tap may be (0 = no limit), w = gain
    vec4 q;       // x = lod (oct_cube), y = 1: the atlas is RGBA8 (coded SH), z = unused, w = 1: the source's SH is coded (sh_cube)
};
out vec4 frag_color;

// The cubes and the atlas are RGBA16F, whose largest value is 65504 (env.glsl env_out).
vec3 probe_out(vec3 c) {
    float m = max(max(c.r, c.g), c.b);
    if (m > 65000.0) {
        c *= 65000.0 / m;
    }
    return c;
}
@end

// ---- face: the picture of one face into the cube face of the scratch pyramid ---------------------------------------------
@fs fs_face
layout(binding=0) uniform texture2D probe_tex;
layout(binding=0) uniform sampler probe_smp;
layout(binding=1) uniform probe_face_params {
    vec4 cam_right;  // the capture camera's axes in the world (a right-handed camera, 90 degrees across and down)
    vec4 cam_up;
    vec4 cam_fwd;
};
in vec3 dir;
out vec4 frag_color;
void main() {
    vec3 d = normalize(dir);
    float z = dot(d, cam_fwd.xyz);
    vec2 n = vec2(dot(d, cam_right.xyz), dot(d, cam_up.xyz)) / z;
    vec2 uv = vec2(0.5 + 0.5 * n.x, 0.5 - 0.5 * n.y);   // the picture is upright: row 0 is the top
    vec3 c = textureLod(sampler2D(probe_tex, probe_smp), uv, 0.0).rgb;
    float m = max(max(c.r, c.g), c.b);
    if (m > 65000.0) {
        c *= 65000.0 / m;
    }
    frag_color = vec4(c, 1.0);
}
@end

// ---- down: the next image of the pyramid ----------------------------------------------------------------------------------
@fs fs_down
layout(binding=0) uniform textureCube probe_cube;
layout(binding=0) uniform sampler probe_smp;
in vec3 dir;
out vec4 frag_color;
void main() {
    frag_color = vec4(textureLod(samplerCube(probe_cube, probe_smp), normalize(dir), 0.0).rgb, 1.0);
}
@end

// ---- oct_cube: a level of a tile from a cube at a lod ---------------------------------------------------------------------
@fs fs_oct_cube
layout(binding=0) uniform textureCube probe_cube;
@include_block probe_atlas_params
@include_block probe_oct
void main() {
    vec3 d = oct_decode(oct_coordinate(region));
    frag_color = vec4(probe_out(textureLod(samplerCube(probe_cube, probe_smp), d, q.x).rgb * p.w), 1.0);
}
@end

// ---- oct_ggx: a level of a tile, the GGX lobe of its roughness --------------------------------------------------------------
@fs fs_oct_ggx
layout(binding=0) uniform textureCube probe_cube;
@include_block probe_atlas_params
@include_block probe_oct
@include_block env_math
vec3 env_tap_limited(vec3 d) {
    vec3 t = textureLod(samplerCube(probe_cube, probe_smp), d, 0.0).rgb;
    float m = max(max(t.r, t.g), t.b);
    if (p.z > 0.0 && m > p.z) {
        t *= p.z / m;
    }
    return t;
}
@include_block env_ggx
void main() {
    vec3 n = oct_decode(oct_coordinate(region));
    frag_color = vec4(probe_out(env_ggx_filter(n, p.x, int(p.y)) * p.w), 1.0);
}
@end

// ---- sh: the nine coefficients of a 16 x 16 cube ---------------------------------------------------------------------------
// The drawn rectangle is the nine texels of the SH row: texel x is coefficient x (probe.h, "SH row").
@fs fs_sh
layout(binding=0) uniform textureCube probe_cube;
@include_block probe_atlas_params
@include_block env_math
vec3 env_tap_limited(vec3 d) {
    vec3 t = textureLod(samplerCube(probe_cube, probe_smp), d, 0.0).rgb;
    float m = max(max(t.r, t.g), t.b);
    if (p.z > 0.0 && m > p.z) {
        t *= p.z / m;
    }
    return t;
}
@include_block env_sh_project
void main() {
    int k = int(floor(gl_FragCoord.x - region.x));
    vec3 result = vec3(0.0);
    if (k >= 0 && k < 9) {
        result = env_sh_coefficient(k) * p.w;
    }
    float m = max(max(abs(result.r), abs(result.g)), abs(result.b));
    if (m > 65000.0) {
        result *= 65000.0 / m;
    }
    if (q.y > 0.5) {
        result = clamp(result * 0.25, vec3(-1.0), vec3(1.0)) * 0.5 + 0.5;
    }
    frag_color = vec4(result, 1.0);
}
@end

// ---- sh_cube: the sky's coefficients, copied from mip 5 of its prefiltered cube ------------------------------------------------
// Coefficient k is the texel (k % 4, k / 4) of the face +X (renderer_env.h); it is read at the exact centre of its texel.
@fs fs_sh_cube
layout(binding=0) uniform textureCube probe_cube;
@include_block probe_atlas_params
void main() {
    int k = int(floor(gl_FragCoord.x - region.x));
    int col = k - (k / 4) * 4;
    int row = k / 4;
    float u = (float(col) * 2.0 + 1.0) / 4.0 - 1.0;
    float v = 1.0 - (float(row) * 2.0 + 1.0) / 4.0;
    vec3 c = vec3(0.0);
    if (k >= 0 && k < 9) {
        c = textureLod(samplerCube(probe_cube, probe_smp), vec3(1.0, v, -u), p.x).rgb;
        if (q.w > 0.5) {
            c = (c - 0.5) * 8.0;   // the source holds clamp(c / 4, -1, 1) * 0.5 + 0.5
        }
        if (q.y > 0.5) {
            c = clamp(c * 0.25, vec3(-1.0), vec3(1.0)) * 0.5 + 0.5;
        }
    }
    frag_color = vec4(c, 1.0);
}
@end

// ---- blit: a rectangle of a 2D image copied texel for texel -------------------------------------------------------------------
@fs fs_blit
layout(binding=0) uniform texture2D probe_tex;
layout(binding=0) uniform sampler probe_smp;
layout(binding=1) uniform probe_blit_params {
    vec4 dst;   // x, y = the memory origin of the rectangle drawn
    vec4 src;   // x, y = the source texel of the rectangle's first texel, z = rows of the rectangle, w = 1: read the rows bottom-up (OpenGL's read-back)
};
out vec4 frag_color;
void main() {
    int lx = int(floor(gl_FragCoord.x - dst.x));
    int ly = int(floor(gl_FragCoord.y - dst.y));
    if (src.w > 0.5) {
        ly = int(src.z) - 1 - ly;
    }
    frag_color = texelFetch(sampler2D(probe_tex, probe_smp), ivec2(int(src.x) + lx, int(src.y) + ly), 0);
}
@end

@program face vs_cube fs_face
@program down vs_cube fs_down
@program oct_cube vs_rect fs_oct_cube
@program oct_ggx vs_rect fs_oct_ggx
@program sh vs_rect fs_sh
@program sh_cube vs_rect fs_sh_cube
@program blit vs_rect fs_blit
