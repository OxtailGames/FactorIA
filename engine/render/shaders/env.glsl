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
//   irradiance  the source cube convolved with the cosine lobe: what a diffuse surface facing a direction receives, divided by pi
//               (a sky of one colour gives that colour), the ambient light of the meshes
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

// ---- irradiance: the cosine lobe --------------------------------------------------------------------------------
@fs fs_irradiance
@include_block env_common
void main() {
    vec3 n = normalize(dir);
    vec3 t, b;
    env_basis(n, t, b);
    vec3 sum = vec3(0.0);
    int count = int(p.y);
    for (int k = 0; k < 256; k++) {
        if (k >= count) { break; }
        vec2 u = env_r2(k);
        float phi = 2.0 * ENV_PI * u.x;
        float cos_t = sqrt(1.0 - u.y);      // cosine-weighted: the mean of the radiance IS the integral of L cos / pi
        float sin_t = sqrt(u.y);
        vec3 l = t * (sin_t * cos(phi)) + b * (sin_t * sin(phi)) + n * cos_t;
        sum += env_tap_limited(l);
    }
    frag_color = vec4(env_out(sum / float(max(count, 1)) * p.w), 1.0);
}
@end

@program copy vs fs_copy
@program prefilter vs fs_prefilter
@program irradiance vs fs_irradiance
