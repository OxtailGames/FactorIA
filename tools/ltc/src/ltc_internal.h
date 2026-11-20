// Private pieces shared by the files of fa_ltc: the BRDF of the engine's shader, its importance sampler, the sample sequence.
#pragma once

#include <cstdint>

#include "fa/ltc/ltc.h"

namespace fa::ltc::detail {

inline constexpr double kPi = 3.14159265358979323846;

// The view of one cell: N = +z, V = (sin theta, 0, cos theta).
struct BrdfCtx {
    double alpha = 0, a2 = 0;
    double ndv = 0;  // max(cos theta, 1e-4), as the shader
    Vec3d v;
};
BrdfCtx make_brdf(double roughness, double cosTheta);
// f(l) * cos(l) with F = 1 and no pi (see brdf_cos in ltc.h); 0 for a direction at or under the horizon.
double brdf_fcos(const BrdfCtx& ctx, Vec3d l);
// Density (per steradian of l) of vndf_sample producing l; 0 when its half vector is under the horizon.
double vndf_pdf(const BrdfCtx& ctx, Vec3d l);
// A reflected direction l (it may be under the horizon) from two numbers in [0, 1): GGX distribution of visible normals.
Vec3d vndf_sample(const BrdfCtx& ctx, double u1, double u2, double* vdh = nullptr);

// Van der Corput radical inverse in base 2, and the i-th of n Hammersley points (u1 stratified, u2 low discrepancy).
double radical_inverse(std::uint32_t i);
inline void hammersley(int i, int n, double& u1, double& u2) {
    u1 = (static_cast<double>(i) + 0.5) / static_cast<double>(n);
    u2 = radical_inverse(static_cast<std::uint32_t>(i));
}
// A cosine-distributed direction of the +z hemisphere.
Vec3d cosine_sample(double u1, double u2);

// The error of a lobe against one cell's BRDF, and the cell's integrals. Immutable after construction: the same object can be
// evaluated from many threads.
class CellProblem {
public:
    CellProblem(double roughness, double cosTheta, int fitSamples, int albedoSamples);
    // Integral of |D - f cos / magnitude|^3 over the sphere, estimated with both densities' samples (the fit minimizes it).
    double cubic_error(const Lobe& lobe) const;
    // The same with the exponent 1: the L1 distance.
    double l1_error(const Lobe& lobe) const;
    const Albedo& albedo() const { return albedo_; }
    // The angle (from +z towards +x) of the mean direction of f cos: where the lobe's center belongs.
    double mean_angle() const { return meanAngle_; }

private:
    struct BrdfSample {
        Vec3d l;
        double target = 0;  // f cos / magnitude at l
        double pdf = 0;     // vndf_pdf at l
    };
    template <bool Cubic>
    double estimate(const Lobe& lobe) const;
    BrdfCtx ctx_;
    Albedo albedo_;
    double invMagnitude_ = 0;
    double meanAngle_ = 0;
    std::vector<BrdfSample> brdfSamples_;
    std::vector<Vec3d> cosineSamples_;
};

}  // namespace fa::ltc::detail
