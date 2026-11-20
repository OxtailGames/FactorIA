// FactorIA sky environment (SceneSettings.skyMaterial, M72 P15): the sky that is SEEN is baked into cubemaps the meshes sample for
// their reflection (image based lighting) and their ambient light. The sky itself is drawn by the sky material's own program (sky.glsl /
// sky_common.glsl) into the faces of a cube; the three programs here only filter that cube. All three draw one full-screen triangle into
// ONE face of ONE mip of a cube image; the vertex stage turns the pixel into the world direction it looks at from the face's basis:
//
//   dir = fwd + pos.x * right + pos.y * up        (pos = the clip position, -1 .. 1)
//
// fwd is the face's axis and right / up the directions of increasing u / decreasing row of the face as the cube map spec defines them
// (renderer_env.cpp has the table); `up` arrives already negated on OpenGL, whose render targets are stored bottom-up, so that row 0
// of the image is the top of the face on every backend (the same as the shadow map's `fa_counts.z`, mesh_common.glsl).
//
//   copy        one tap of the source cube: a straight copy (the first level of the prefiltered chain) and the down-sampling of the pyramid
//               (a bilinear tap at the centre of a 2x2 block is the block's average)
//   prefilter   the source cube convolved with the GGX lobe of a roughness, by importance sampling: the mip of the prefiltered cube a
//               surface of that roughness reflects. The source of a level is the pyramid image of about the same size (a level reads
//               an image no bigger than its own and no mipmaps: nothing is read from the image being drawn).
//   sh          the source cube projected onto nine spherical-harmonics coefficients, the ambient light of the meshes (below)
//
// The sample points come from the R2 sequence (a fixed low-discrepancy pattern) so the same image is drawn on every run and every GPU.
@module env

@vs vs
layout(binding=0) uniform env_vs_params {
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

@block env_common
layout(binding=0) uniform textureCube env_src;
layout(binding=0) uniform sampler env_smp;
layout(binding=1) uniform env_params {
    vec4 p;     // x = roughness (0 .. 1: the prefilter), y = sample count, z = the most a tap of the source may be (0 = no limit), w = brightness
};
in vec3 dir;
out vec4 frag_color;

const float ENV_PI = 3.14159265;

// Sample i of the R2 sequence, in the unit square.
vec2 env_r2(int i) {
    return fract(vec2(0.5) + float(i) * vec2(0.7548776662, 0.5698402910));
}

vec3 env_tap(vec3 d) {
    return textureLod(samplerCube(env_src, env_smp), d, 0.0).rgb;
}

// A tap with its brightest channel limited to p.z (its colour kept): one very bright texel (the sun of an HDRI) would otherwise be hit by
// a few of the 32..128 samples of a pixel and not by the pixel next to it, a firefly. 0 = no limit (every sky but an HDRI).
vec3 env_tap_limited(vec3 d) {
    vec3 t = env_tap(d);
    float m = max(max(t.r, t.g), t.b);
    if (p.z > 0.0 && m > p.z) {
        t *= p.z / m;
    }
    return t;
}

// The cubes are RGBA16F, whose largest value is 65504: a texel of 60000 times a brightness of 4 would be infinity, and infinity is NaN
// after the tone mapping. The brightest channel is limited to 65000 with the colour kept (the same rule the CPU applies to the file).
// Anything under that is returned unchanged, so a scene that has no gain is bit-identical.
vec3 env_out(vec3 c) {
    float m = max(max(c.r, c.g), c.b);
    if (m > 65000.0) {
        c *= 65000.0 / m;
    }
    return c;
}

// An orthonormal basis around n: t and b.
void env_basis(vec3 n, out vec3 t, out vec3 b) {
    vec3 up = abs(n.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    t = normalize(cross(up, n));
    b = cross(n, t);
}
@end

// ---- copy ---------------------------------------------------------------------------------------------------
@fs fs_copy
@include_block env_common
void main() {
    frag_color = vec4(env_out(env_tap(normalize(dir)) * p.w), 1.0);
}
@end

// ---- prefilter: the GGX lobe of a roughness --------------------------------------------------------------------
@fs fs_prefilter
@include_block env_common
void main() {
    vec3 n = normalize(dir);
    vec3 t, b;
    env_basis(n, t, b);
    float alpha = p.x * p.x;
    float a2 = alpha * alpha;
    vec3 sum = vec3(0.0);
    float weight = 0.0;
    int count = int(p.y);
    for (int k = 0; k < 128; k++) {
        if (k >= count) { break; }
        vec2 u = env_r2(k);
        float phi = 2.0 * ENV_PI * u.x;
        float cos_t = sqrt((1.0 - u.y) / (1.0 + (a2 - 1.0) * u.y));
        float sin_t = sqrt(max(1.0 - cos_t * cos_t, 0.0));
        vec3 h = t * (sin_t * cos(phi)) + b * (sin_t * sin(phi)) + n * cos_t;
        vec3 l = 2.0 * dot(n, h) * h - n;   // the view is the normal (the split-sum assumption)
        float ndl = dot(n, l);
        if (ndl > 0.0) {
            sum += env_tap_limited(l) * ndl;
            weight += ndl;
        }
    }
    frag_color = vec4(env_out((weight > 0.0 ? sum / weight : env_tap_limited(n)) * p.w), 1.0);
}
@end

// ---- sh: the nine spherical-harmonics coefficients of the sky ---------------------------------------------------------
// The diffuse ambient light of the meshes (mesh_common.glsl fa_ambient_light) is the sky's radiance as real spherical harmonics, bands 0..2
// (nine RGB coefficients, the same basis and order as ShL2 / sh_basis() of fa/scene/lightmap_bake.h, so the light probes of M73.4d use the
// same evaluation). This program computes them, one coefficient per texel: the six passes of a bake draw the faces of MIP 5 of the
// prefiltered cube (4 x 4 texels per face; the meshes read mips 0..4, so the texels are free; the cube already is a texture every mesh
// program binds, which is the point: no texture unit for it). On the face +X texel (x, y) holds coefficient x + 4 * y (the first nine; the
// others, and the five other faces, are written as zero so no texel is ever garbage or a NaN). Each fragment sums the SMALLEST pyramid image
// (16 x 16 per face, 1536 texels), every texel at its centre (an exact fetch: no sampling noise, the same image every run and on every GPU)
// times the basis function times the texel's solid angle, normalised so that the weights add up to 4 pi (a sky of one colour gives
// exactly c0 = L * sqrt(4 pi), and fa_sh_eval gives L for every normal). The sun of an HDRI is limited like every other convolution
// (p.z), so the ambient does not change with the brightest texel of a picture; there is no further windowing: the clamped cosine
// the shader convolves the coefficients with (1, 2/3, 1/4 per band) is itself the smoothest window an irradiance can have, and the shader
// clamps the result at 0 (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The sky's spherical harmonics").
// When the cubes are RGBA8 (p.y = 1, a GPU that cannot render to half floats) a coefficient is stored as clamp(c / 4, -1, 1) * 0.5 + 0.5.
@fs fs_sh
@include_block env_common
// The basis of face f as the cube map specification lays it out (renderer_env.cpp, kFaces; `up` is the direction of row 0). Written as
// a function, not as constant arrays: sokol-shdc leaves the precision of a global constant array at the default, which is mediump on GLSL ES.
void sh_face(int f, out vec3 fwd, out vec3 right, out vec3 up) {
    fwd = vec3(0.0, 0.0, -1.0);
    right = vec3(-1.0, 0.0, 0.0);
    up = vec3(0.0, 1.0, 0.0);
    if (f == 0) { fwd = vec3(1.0, 0.0, 0.0); right = vec3(0.0, 0.0, -1.0); }
    if (f == 1) { fwd = vec3(-1.0, 0.0, 0.0); right = vec3(0.0, 0.0, 1.0); }
    if (f == 2) { fwd = vec3(0.0, 1.0, 0.0); right = vec3(1.0, 0.0, 0.0); up = vec3(0.0, 0.0, -1.0); }
    if (f == 3) { fwd = vec3(0.0, -1.0, 0.0); right = vec3(1.0, 0.0, 0.0); up = vec3(0.0, 0.0, 1.0); }
    if (f == 4) { fwd = vec3(0.0, 0.0, 1.0); right = vec3(1.0, 0.0, 0.0); }
}

float sh_basis_k(int k, vec3 d) {
    if (k == 0) { return 0.282094792; }
    if (k == 1) { return 0.488602512 * d.y; }
    if (k == 2) { return 0.488602512 * d.z; }
    if (k == 3) { return 0.488602512 * d.x; }
    if (k == 4) { return 1.092548431 * d.x * d.y; }
    if (k == 5) { return 1.092548431 * d.y * d.z; }
    if (k == 6) { return 0.315391565 * (3.0 * d.z * d.z - 1.0); }
    if (k == 7) { return 1.092548431 * d.x * d.z; }
    return 0.546274215 * (d.x * d.x - d.y * d.y);
}

void main() {
    vec3 result = vec3(0.0);
    // The texel this fragment is, from the direction it looks along (the face +X: dir.x is 1; the same on every backend, whatever the
    // orientation of the render target).
    int col = int(floor((1.0 - dir.z) * 2.0));
    int row = int(floor((1.0 - dir.y) * 2.0));
    int k = col + 4 * row;
    if (p.x > 0.5 && k >= 0 && k < 9) {
        vec3 sum = vec3(0.0);
        float wsum = 0.0;
        for (int f = 0; f < 6; f++) {
            vec3 fwd, right, up;
            sh_face(f, fwd, right, up);
            for (int y = 0; y < 16; y++) {
                for (int x = 0; x < 16; x++) {
                    float u = (float(x) * 2.0 + 1.0) / 16.0 - 1.0;
                    float v = 1.0 - (float(y) * 2.0 + 1.0) / 16.0;
                    vec3 d = fwd + u * right + v * up;
                    float inv = inversesqrt(dot(d, d));
                    float w = inv * inv * inv;      // proportional to the solid angle of the texel
                    vec3 dn = d * inv;
                    sum += env_tap_limited(dn) * (sh_basis_k(k, dn) * w);
                    wsum += w;
                }
            }
        }
        result = sum * (4.0 * ENV_PI / wsum) * p.w;
    }
    // The cubes are RGBA16F (largest value 65504): a coefficient is at most about 3.6 times the brightest texel, so the largest
    // component is limited to 65000 with the colour kept (a coefficient can be negative).
    float m = max(max(abs(result.r), abs(result.g)), abs(result.b));
    if (m > 65000.0) {
        result *= 65000.0 / m;
    }
    if (p.y > 0.5) {
        result = clamp(result * 0.25, vec3(-1.0), vec3(1.0)) * 0.5 + 0.5;
    }
    frag_color = vec4(result, 1.0);
}
@end

@program copy vs fs_copy
@program prefilter vs fs_prefilter
@program sh vs fs_sh
