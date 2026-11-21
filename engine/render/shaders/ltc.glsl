// Linearly Transformed Cosines for area lights: the integral of a polygonal light over the specular lobe of the engine's BRDF
// (docs/design/ARCHITECTURE_AREA_LIGHTS.md). Not compiled on its own: mesh_common.glsl `@include`s this file and includes the block
// fa_ltc in fa_fs_light (the main fragment shader of the engine's own meshes; light_loop.glsl's fa_area_shade calls it). The CPU reference of every function here is
// tools/ltc/src/ltc_polygon.cpp (same algorithm, same polynomial; the tests compare it with brute force), and the table the lookup
// reads is engine/render/src/ltc_tables.h, our own fit (tools/ltc).
//
// How a light is shaded, in the order of the calls:
//   1. uv   = fa_ltc_uv(roughness, N.V)             where to read the two tables, which the renderer bakes (light_atlas.h) from the
//                                                  generated header into the light atlas (view 25, RGBA16F; no texture unit of their own):
//                                                    matrix  = kMatrix, the 64 x 64 tile at texel (0, 0): (a, b, c, d) of M^-1
//                                                    albedo  = kBrdf,   the 64 x 64 tile at texel (64, 0): (magnitude, fresnel)
//                                                  both with bilinear filtering and clamp to edge; u = roughness axis, v = view axis
//   2. t1   = fa_ltc_tangent(N, V)                  the frame of the table: x = V's side of N, z = N, y = z cross x
//      p_i  = fa_ltc_local(t1, N, corner_i - P)     the light's corners relative to the shaded point P, in that frame
//   3. form = fa_ltc_quad(abcd, p0, p1, p2, p3)     the integral of the lobe D over the polygon, signed
//   4. radiance = lightColor * (f0 * magnitude + (1 - f0) * fresnel) * abs(form) * pi          (abs: the light is lit on both sides;
//                                                    the pi is the one point lights carry, the light colors are not divided by it)
//
// Winding: fa_ltc_quad returns a positive number when the corners p0..p3 run counter-clockwise seen from +z (from the side the
// normal points to) in the local frame, a negative one for the other winding. The corners must be those of a convex polygon, in
// order. A triangle is a quad with the last corner repeated (fa_ltc_triangle).
//
// Precision: this block must run in highp. Under fp16 (mediump) the guards below (1e-24, 1e-10, 1e-7) flush to zero and dot(a, a)
// overflows past about 255 m. sokol-shdc emits `precision mediump float;` in its GLSL ES 3.00 output but qualifies every declaration
// highp; a scan test of the generated header (engine/render/tests/light_atlas_tests.cpp) fails if a declaration of this block loses
// the qualifier. Do not add `mediump` or `lowp` here.
//
// Horizon: M^-1 turns the polygon into the space where the lobe is a clamped cosine; the part under z = 0 there is cut away (an
// edge that crosses it is clipped, the cut is closed by the arc along the horizon), so a light that dips below the surface's
// horizon is shaded with its visible part. At most one run of the polygon is under the horizon (it is convex), which is what the
// streaming clip below relies on: no arrays are needed.
@block fa_ltc
const float FA_LTC_SIZE = 64.0;           // texels per axis of the two textures
const float FA_LTC_MIN_ROUGHNESS = 0.05;  // roughness of texel 0 on the u axis (the shader clamps roughness to 0.05..1)
const float FA_LTC_PI = 3.14159265358979;

// Texture coordinates (centers of texels, so that the bilinear filter blends the cells the fit made) of roughness (perceptual,
// alpha = roughness^2) and N.V: u = (roughness - 0.05) / 0.95, v = sqrt(1 - N.V).
vec2 fa_ltc_uv(float roughness, float ndv) {
    float u = clamp((roughness - FA_LTC_MIN_ROUGHNESS) / (1.0 - FA_LTC_MIN_ROUGHNESS), 0.0, 1.0);
    float v = sqrt(clamp(1.0 - ndv, 0.0, 1.0));
    return (vec2(u, v) * (FA_LTC_SIZE - 1.0) + 0.5) / FA_LTC_SIZE;
}

// The x axis of the table's frame: the part of V that is not along N, normalized (any axis perpendicular to N when V = N, where the
// lobe is the same all around).
vec3 fa_ltc_tangent(vec3 n, vec3 v) {
    vec3 t = v - n * dot(v, n);
    float l2 = dot(t, t);
    if (l2 < 1e-10) {
        t = (abs(n.z) < 0.999) ? cross(n, vec3(0.0, 0.0, 1.0)) : cross(n, vec3(1.0, 0.0, 0.0));
        l2 = dot(t, t);
    }
    return t * inversesqrt(l2);
}

// A point p relative to the shaded point, in the table's frame: x along t1, y along cross(n, t1), z along n.
vec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p) {
    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));
}

// The integral over the great-circle arc from a to b (any lengths, not parallel) of what the form factor adds up: the vector
// cross(a, b) / |cross(a, b)| * acos(a.b), whose z is the edge's share. acos(y) / sqrt(1 - y^2) is a degree-6 polynomial of
// y = |a.b| (5e-6 from the function) and acos(-y) = pi - acos(y).
vec3 fa_ltc_edge_vector(vec3 a, vec3 b) {
    float la2 = dot(a, a);
    float lb2 = dot(b, b);
    if (la2 < 1e-24 || lb2 < 1e-24) return vec3(0.0);
    vec3 na = a * inversesqrt(la2);
    vec3 nb = b * inversesqrt(lb2);
    float x = dot(na, nb);
    float y = abs(x);
    float g = 0.04164716762962988;
    g = g * y - 0.1924748645577205;
    g = g * y + 0.4179156120778016;
    g = g * y - 0.6160572217483093;
    g = g * y + 0.7777224167319281;
    g = g * y - 0.9995423990187176;
    g = g * y + 1.5707917009694146;
    if (x < 0.0) g = FA_LTC_PI * inversesqrt(max(1.0 - x * x, 1e-7)) - g;
    return cross(na, nb) * g;
}

// One edge a -> b of the transformed polygon: adds the part above the horizon to `sum`, and remembers where the polygon left it
// (`leave`) and came back (`enter`); seen.x / seen.y are set once each happened.
void fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen) {
    bool in_a = a.z > 0.0;
    bool in_b = b.z > 0.0;
    if (in_a && in_b) {
        sum += fa_ltc_edge_vector(a, b);
    } else if (in_a != in_b) {
        float t = a.z / (a.z - b.z);
        vec3 c = a + (b - a) * t;
        c.z = 0.0;
        if (in_a) {
            sum += fa_ltc_edge_vector(a, c);
            leave = c;
            seen.x = 1.0;
        } else {
            sum += fa_ltc_edge_vector(c, b);
            enter = c;
            seen.y = 1.0;
        }
    }
}

// The integral of the lobe over the polygon p0 p1 p2 p3 (points in the table's frame), signed by the winding (see the top).
// abcd = the matrix of the cell, M^-1 = [[a 0 b] [0 1 0] [c 0 d]].
float fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3) {
    vec3 q0 = vec3(abcd.x * p0.x + abcd.y * p0.z, p0.y, abcd.z * p0.x + abcd.w * p0.z);
    vec3 q1 = vec3(abcd.x * p1.x + abcd.y * p1.z, p1.y, abcd.z * p1.x + abcd.w * p1.z);
    vec3 q2 = vec3(abcd.x * p2.x + abcd.y * p2.z, p2.y, abcd.z * p2.x + abcd.w * p2.z);
    vec3 q3 = vec3(abcd.x * p3.x + abcd.y * p3.z, p3.y, abcd.z * p3.x + abcd.w * p3.z);
    vec3 sum = vec3(0.0);
    vec3 leave = vec3(0.0);
    vec3 enter = vec3(0.0);
    vec2 seen = vec2(0.0);
    fa_ltc_clip_edge(q0, q1, sum, leave, enter, seen);
    fa_ltc_clip_edge(q1, q2, sum, leave, enter, seen);
    fa_ltc_clip_edge(q2, q3, sum, leave, enter, seen);
    fa_ltc_clip_edge(q3, q0, sum, leave, enter, seen);
    if (seen.x * seen.y > 0.5) sum += fa_ltc_edge_vector(leave, enter);
    return sum.z / (2.0 * FA_LTC_PI);
}

// A triangle: the quad with its last corner repeated (the edge from a corner to itself adds nothing).
float fa_ltc_triangle(vec4 abcd, vec3 p0, vec3 p1, vec3 p2) {
    return fa_ltc_quad(abcd, p0, p1, p2, p2);
}

// A rectangle light: center +- ex +- ey, all in the table's frame (corners: -ex-ey, +ex-ey, +ex+ey, -ex+ey, so the sign is
// that of cross(ex, ey).z seen from the shaded point). The unsigned integral of a light that is lit on both sides.
float fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey) {
    return abs(fa_ltc_quad(abcd, center - ex - ey, center + ex - ey, center + ex + ey, center - ex + ey));
}
@end
