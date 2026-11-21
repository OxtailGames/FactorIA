// The convolutions of an environment, shared by the sky's cube (env.glsl) and the reflection probes' octahedral tiles (probe.glsl, M73-P3b):
// the GGX importance prefilter and the projection onto spherical harmonics are written ONCE, here, and each program supplies only where
// its samples come from. Nothing in this file is compiled on its own: env.glsl and probe.glsl `@include` it and include its blocks.
//
// A program that includes `env_ggx` or `env_sh_project` first defines
//     vec3 env_tap_limited(vec3 d)     the source in direction d (unit), its brightest channel limited as the program wants
// and includes `env_math` before it. Everything here is a function, never a constant array: sokol-shdc leaves the precision of a global
// constant array at the default, which is mediump on GLSL ES (the octahedral map and the GGX lobe need highp).

@block env_math
const float ENV_PI = 3.14159265;

// Sample i of the R2 sequence, in the unit square.
vec2 env_r2(int i) {
    return fract(vec2(0.5) + float(i) * vec2(0.7548776662, 0.5698402910));
}

// An orthonormal basis around n: t and b.
void env_basis(vec3 n, out vec3 t, out vec3 b) {
    vec3 up = abs(n.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    t = normalize(cross(up, n));
    b = cross(n, t);
}
@end

// ---- the GGX lobe of a roughness, by importance sampling ----------------------------------------------------------------
// The source convolved with the GGX lobe: what a surface of that roughness reflects. The view is the normal (the split-sum assumption), the
// sample points come from the R2 sequence so the same image is drawn on every run and every GPU, and a sample is weighted by n . l.
@block env_ggx
vec3 env_ggx_filter(vec3 n, float roughness, int count) {
    vec3 t, b;
    env_basis(n, t, b);
    float alpha = roughness * roughness;
    float a2 = alpha * alpha;
    vec3 sum = vec3(0.0);
    float weight = 0.0;
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
    return weight > 0.0 ? sum / weight : env_tap_limited(n);
}
@end

// ---- the nine spherical-harmonics coefficients of a cube -----------------------------------------------------------------
// The source is a cube map whose faces are 16 x 16 texels (every texel at its centre, an exact fetch). Each coefficient is the sum over its 1536
// texels of radiance times the basis function times the texel's solid angle, normalised so that the weights add up to 4 pi (a source of one
// colour gives exactly c0 = L * sqrt(4 pi)). The basis and its order are ShL2 / sh_basis() of fa/scene/lightmap_bake.h (the sky's ambient, the light
// probes and the reflection probes share one definition).
@block env_sh_project
// The basis of face f as the cube map specification lays it out (renderer_env.cpp, kFaces; `up` is the direction of row 0).
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

// Coefficient k (0..8) of the source, RGB.
vec3 env_sh_coefficient(int k) {
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
    return sum * (4.0 * ENV_PI / wsum);
}
@end
