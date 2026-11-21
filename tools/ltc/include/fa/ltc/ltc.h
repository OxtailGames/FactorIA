// Linearly Transformed Cosines for area lights: our own deterministic fit of the tables, and the CPU reference of the
// integral the shader will do (docs/design/ARCHITECTURE_AREA_LIGHTS.md).
//
// The method is the one of Heitz, Dupuy, Hill and Neubelt, "Real-Time Polygonal-Light Shading with Linearly Transformed
// Cosines" (SIGGRAPH 2016): the lobe of a BRDF times the cosine is approximated by a clamped cosine D_o(w) = max(0, w.z) / pi
// that a 3x3 matrix M bends, D(w) = D_o(M^-1 w / |M^-1 w|) |det M^-1| / |M^-1 w|^3. The integral of D over a polygon is then
// the form factor of the polygon M^-1 turned into, which has a closed form. The code and the numbers here are ours: the
// parameters are fitted by this library (Nelder-Mead on a cubic error between D and the engine's BRDF, importance sampled
// both ways) for the BRDF of engine/render/shaders/mesh_common.glsl, never copied from another table.
//
// Everything here is in double precision and uses only + - * / and sqrt of the C library, plus the library's own sin, cos,
// exp and log, so a table has the same bits on every platform the engine builds for (the repo compiles with -ffp-contract=off
// and /fp:precise) and with any number of job threads.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa::ltc {

// ---------------------------------------------------------------------------------------------------------- the table
inline constexpr int kTableSize = 64;  // cells per axis of the shipped table
// The roughness axis is the perceptual roughness the shader uses (alpha = roughness^2), from the smallest one the shader
// allows (clamp(s.roughness, 0.05, 1.0)) to 1. The view axis is t = sqrt(1 - cos(theta)), cos(theta) = N.V, from 0 to 1.
inline constexpr double kMinRoughness = 0.05;
inline constexpr double kMinCosTheta = 0.01;  // the grazing cell is fitted at this cosine, not at exactly 0

// Cell i of `size` along the roughness axis and cell j along the view axis.
double roughness_at(int i, int size);
double cos_theta_at(int j, int size);

// ------------------------------------------------------------------------------------------------------------ vectors
struct Vec3d {
    double x = 0, y = 0, z = 0;
};
inline Vec3d operator+(Vec3d a, Vec3d b) { return {a.x + b.x, a.y + b.y, a.z + b.z}; }
inline Vec3d operator-(Vec3d a, Vec3d b) { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
inline Vec3d operator*(Vec3d a, double s) { return {a.x * s, a.y * s, a.z * s}; }
inline double dot(Vec3d a, Vec3d b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
inline Vec3d cross(Vec3d a, Vec3d b) { return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x}; }
double length(Vec3d a);
Vec3d normalize(Vec3d a);  // a must not be zero

// ----------------------------------------------------------------------------------- math without a C library's rounding
// sin, cos, exp and log written with + - * / only, so that every platform rounds them alike (the C library's differ in the last
// digit). About 1e-15 relative error for |x| < 1e4 (angles) and |x| < 700 (exp).
void det_sincos(double x, double& s, double& c);
double det_exp(double x);
double det_log(double x);              // x > 0
double det_atan2(double y, double x);  // (x, y) not both 0; the angle of (x, y) in (-pi, pi]

// ------------------------------------------------------------------------------------------------------------ the lobe
// M^-1 = [[a, 0, b], [0, 1, 0], [c, 0, d]] in the frame where N = +z and V lies in the xz plane (V = (sin theta, 0, cos
// theta)): the BRDF is symmetric about that plane, so the matrix is too; the scale of M is free and fixed by the 1 in the
// middle. This is what the table stores per cell, and what the shader multiplies the polygon's points with.
struct Lobe {
    double a = 1, b = 0, c = 0, d = 1;
};

// D(w) of the lobe for a unit direction w, per steradian (it integrates to 1 over the sphere).
double lobe_density(const Lobe& lobe, Vec3d w);
// The direction a cosine-distributed sample w_o of D_o is moved to (what sampling D does), normalized.
Vec3d lobe_sample(const Lobe& lobe, Vec3d wo);

// ---------------------------------------------------------------------------------------------------------------- BRDF
// The engine's specular term without the Fresnel factor and without the factor pi the shader multiplies it with (the
// shader's light colors are not divided by pi): f(l) = D_ggx(h) * V_smith(l, v), for N = +z, V = (sqrt(1 - c^2), 0, c) with
// c = cosTheta, alpha = roughness^2, V_smith = 0.5 / max(mix(2 nl nv, nl + nv, alpha), 1e-4). f * cos(l) is what the fit,
// the table's magnitude and the tests integrate.
double brdf_cos(double roughness, double cosTheta, Vec3d l);

// What the table keeps per cell besides the matrix: the integral of f * cos(l) over the hemisphere (`magnitude`, the
// directional albedo with F = 1) and of f * cos(l) * (1 - V.H)^5 (`fresnel`); the shader's specular color of an area light is
// (f0 * magnitude + (1 - f0) * fresnel) * (the integral of D over the light), with the light's radiance and pi as for
// point lights.
struct Albedo {
    double magnitude = 0;
    double fresnel = 0;
};
// Estimated with `samples` importance samples of the visible normals of GGX (a Hammersley sequence), within about 1e-4.
Albedo albedo_importance(double roughness, double cosTheta, int samples);
// The same integrals with a different method (a grid over the half-vector domain, nothing shared with the importance
// sampler): the reference the tests compare the table with. `grid` points per half-vector axis.
Albedo albedo_quadrature(double roughness, double cosTheta, int grid);

// The L1 distance, integral over the sphere of |D(w) - f cos(w) / magnitude| dw, between a lobe and the BRDF it stands for
// (0 = identical, 2 = disjoint), estimated with `samples` samples of each of the two densities.
double lobe_error(double roughness, double cosTheta, const Lobe& lobe, int samples);

// ----------------------------------------------------------------------------------------------------------- the fitting
struct TableConfig {
    int size = kTableSize;     // cells per axis, 2..256
    int fitSamples = 768;      // samples of each density in the error the fit minimizes
    int albedoSamples = 8192;  // importance samples of the magnitude and Fresnel integrals
    int iterations = 220;  // Nelder-Mead iterations of each of its two runs (a cap: it stops when the simplex is flat)
};

// The result: row j (view axis) of `size` cells, cell i (roughness axis) inside it, as a texture of size x size texels would
// be laid out (u = roughness, v = view).
struct Table {
    int size = 0;
    std::vector<float> matrix;  // size*size*4: a, b, c, d of Lobe
    std::vector<float> brdf;    // size*size*2: magnitude, fresnel
    std::vector<float> error;   // size*size: lobe_error at the fit's own samples (a diagnostic, not shipped)
};

// Fits every cell of the table. Rows (roughness) run in parallel with fa::jobs (the pool, or the calling thread when none runs):
// the result is the same bits whatever the thread count. A cell starts from its neighbour's parameters, so the first view
// cell of each roughness comes from a sequential pass first. Invalid sizes or sample counts are refused with a hint.
Result<Table> fit_table(const TableConfig& config);

// A hash (FNV-1a 64 of the bits) of matrix and brdf, to compare tables (the second form hashes arrays of `size` x `size` cells,
// such as the ones of the generated header).
std::uint64_t table_hash(const Table& table);
std::uint64_t table_hash(const float* matrix, const float* brdf, int size);

// The text of the generated C++ header (engine/render/src/ltc_tables.h) for a table fitted with `config`. Only '\n' line ends.
std::string write_header(const Table& table, const TableConfig& config);

// ------------------------------------------------------------------------------------------------- reading a table back
struct Lookup {
    Lobe lobe;
    double magnitude = 0;
    double fresnel = 0;
};
// Bilinear lookup the way the shader does it (matrix: size*size*4 floats, brdf: size*size*2), with `size` cells per axis.
Lookup lookup_table(const float* matrix, const float* brdf, int size, double roughness, double cosTheta);

// -------------------------------------------------------------------------------------------- polygon integral, CPU side
// The integral of D over a convex polygon (counter-clockwise as seen from +z in the frame of the lobe, see ltc.glsl) whose
// points are given relative to the shaded point in that frame: M^-1 turns them, the part above the horizon is kept and the
// closed form of the form factor is evaluated. Signed: positive for the winding above, negative for the other one. This is
// the same algorithm as fa_ltc_quad of engine/render/shaders/ltc.glsl, with the same polynomial for the edge integral.
double polygon_integral(const Lobe& lobe, const Vec3d* points, int count);
// The same with the exact arc cosine for the edge integral (what the polynomial approximates, to 5e-6).
double polygon_integral_exact(const Lobe& lobe, const Vec3d* points, int count);

// The integral of the BRDF times cosine (F = 1) over a rectangle seen from the origin, N = +z, V = (sin, 0, cos): the
// rectangle is center +- ex +- ey. Brute force: a grid of grid x grid cells over the rectangle, each weighted by its solid
// angle (the rectangle is lit on both sides).
double rect_brdf_integral(double roughness, double cosTheta, Vec3d center, Vec3d ex, Vec3d ey, int grid);
// The same with the LTC of the table cell: magnitude * integral of D over the rectangle.
double rect_ltc_integral(const Lookup& cell, Vec3d center, Vec3d ex, Vec3d ey);

}  // namespace fa::ltc
