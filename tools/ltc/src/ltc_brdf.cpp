// The engine's BRDF (engine/render/shaders/mesh_common.glsl), its importance sampler, the cell problem the fit minimizes.
#include <algorithm>
#include <cmath>

#include "fa/ltc/ltc.h"
#include "ltc_internal.h"

namespace fa::ltc {
namespace detail {

BrdfCtx make_brdf(double roughness, double cosTheta) {
    BrdfCtx ctx;
    ctx.alpha = roughness * roughness;
    ctx.a2 = ctx.alpha * ctx.alpha;
    const double c = std::clamp(cosTheta, 0.0, 1.0);
    ctx.ndv = std::max(c, 1e-4);
    ctx.v = {std::sqrt(std::max(0.0, 1.0 - c * c)), 0.0, c};
    return ctx;
}

namespace {
double ggx_d(const BrdfCtx& ctx, double ndh) {
    const double dd = ndh * ndh * (ctx.a2 - 1.0) + 1.0;
    return ctx.a2 / (kPi * dd * dd);
}
}  // namespace

double brdf_fcos(const BrdfCtx& ctx, Vec3d l) {
    const double ndl = l.z;
    if (!(ndl > 0.0001)) return 0.0;
    const Vec3d h = normalize(ctx.v + l);
    const double d = ggx_d(ctx, h.z);
    // Height-correlated Smith visibility, Karis' approximation: 0.5 / max(mix(2 ndl ndv, ndl + ndv, alpha), 1e-4).
    const double mixed = 2.0 * ndl * ctx.ndv * (1.0 - ctx.alpha) + (ndl + ctx.ndv) * ctx.alpha;
    const double vis = 0.5 / std::max(mixed, 1e-4);
    return d * vis * ndl;
}

double vndf_pdf(const BrdfCtx& ctx, Vec3d l) {
    const Vec3d sum = ctx.v + l;
    const double len2 = dot(sum, sum);
    if (!(len2 > 1e-18)) return 0.0;
    const double inv = 1.0 / std::sqrt(len2);
    const double ndh = sum.z * inv;
    if (!(ndh > 0.0)) return 0.0;
    // D_visible(h) / (4 v.h) = G1(v) D(h) / (4 n.v), with the exact Smith G1 of GGX.
    const double root = std::sqrt(ctx.a2 + (1.0 - ctx.a2) * ctx.ndv * ctx.ndv);
    return ggx_d(ctx, ndh) / (2.0 * (ctx.ndv + root));
}

Vec3d vndf_sample(const BrdfCtx& ctx, double u1, double u2, double* vdh) {
    // The visible normals of the stretched hemisphere (the view direction scaled by alpha), sampled on a disk.
    const Vec3d vh = normalize({ctx.alpha * ctx.v.x, ctx.alpha * ctx.v.y, ctx.v.z});
    const Vec3d t1 = vh.z < 0.9999 ? normalize(cross({0.0, 0.0, 1.0}, vh)) : Vec3d{1.0, 0.0, 0.0};
    const Vec3d t2 = cross(vh, t1);
    const double r = std::sqrt(u1);
    double sn = 0, cs = 0;
    det_sincos(2.0 * kPi * u2, sn, cs);
    const double p1 = r * cs;
    double p2 = r * sn;
    const double s = 0.5 * (1.0 + vh.z);
    p2 = (1.0 - s) * std::sqrt(std::max(0.0, 1.0 - p1 * p1)) + s * p2;
    const double pz = std::sqrt(std::max(0.0, 1.0 - p1 * p1 - p2 * p2));
    const Vec3d nh = t1 * p1 + t2 * p2 + vh * pz;
    const Vec3d n = normalize({ctx.alpha * nh.x, ctx.alpha * nh.y, std::max(0.0, nh.z)});
    const double vn = dot(ctx.v, n);
    if (vdh) *vdh = vn;
    return n * (2.0 * vn) - ctx.v;
}

double radical_inverse(std::uint32_t i) {
    i = (i << 16) | (i >> 16);
    i = ((i & 0x55555555u) << 1) | ((i & 0xAAAAAAAAu) >> 1);
    i = ((i & 0x33333333u) << 2) | ((i & 0xCCCCCCCCu) >> 2);
    i = ((i & 0x0F0F0F0Fu) << 4) | ((i & 0xF0F0F0F0u) >> 4);
    i = ((i & 0x00FF00FFu) << 8) | ((i & 0xFF00FF00u) >> 8);
    return static_cast<double>(i) * 2.3283064365386963e-10;  // 2^-32
}

Vec3d cosine_sample(double u1, double u2) {
    const double r = std::sqrt(u1);
    double sn = 0, cs = 0;
    det_sincos(2.0 * kPi * u2, sn, cs);
    return {r * cs, r * sn, std::sqrt(std::max(0.0, 1.0 - u1))};
}

// -------------------------------------------------------------------------------------------------------- the cell problem
CellProblem::CellProblem(double roughness, double cosTheta, int fitSamples, int albedoSamples)
    : ctx_(make_brdf(roughness, cosTheta)) {
    albedo_ = albedo_importance(roughness, cosTheta, albedoSamples);
    invMagnitude_ = albedo_.magnitude > 0.0 ? 1.0 / albedo_.magnitude : 0.0;
    {
        // The mean direction of f cos, from the same importance samples as the albedo.
        Vec3d mean;
        for (int i = 0; i < albedoSamples; ++i) {
            double u1 = 0, u2 = 0;
            hammersley(i, albedoSamples, u1, u2);
            const Vec3d l = vndf_sample(ctx_, u1, u2);
            const double pdf = vndf_pdf(ctx_, l);
            if (pdf > 0.0) mean = mean + l * (brdf_fcos(ctx_, l) / pdf);
        }
        meanAngle_ = det_atan2(mean.x, mean.z);
    }
    brdfSamples_.reserve(static_cast<std::size_t>(fitSamples));
    cosineSamples_.reserve(static_cast<std::size_t>(fitSamples));
    for (int i = 0; i < fitSamples; ++i) {
        double u1 = 0, u2 = 0;
        hammersley(i, fitSamples, u1, u2);
        BrdfSample s;
        s.l = vndf_sample(ctx_, u1, u2);
        s.target = brdf_fcos(ctx_, s.l) * invMagnitude_;
        s.pdf = vndf_pdf(ctx_, s.l);
        brdfSamples_.push_back(s);
        // The lobe's own samples: the same sequence, a quarter of a stratum further in u1, so the two sets do not coincide.
        cosineSamples_.push_back(cosine_sample((static_cast<double>(i) + 0.25) / static_cast<double>(fitSamples), u2));
    }
}

template <bool Cubic>
double CellProblem::estimate(const Lobe& lobe) const {
    double sum = 0.0;
    for (const BrdfSample& s : brdfSamples_) {
        const double dl = lobe_density(lobe, s.l);
        const double delta = std::fabs(dl - s.target);
        sum += (Cubic ? delta * delta * delta : delta) / (s.pdf + dl);
    }
    for (const Vec3d& wo : cosineSamples_) {
        const Vec3d w = lobe_sample(lobe, wo);
        const double dl = lobe_density(lobe, w);
        const double target = brdf_fcos(ctx_, w) * invMagnitude_;
        const double delta = std::fabs(dl - target);
        sum += (Cubic ? delta * delta * delta : delta) / (vndf_pdf(ctx_, w) + dl);
    }
    return sum / static_cast<double>(brdfSamples_.size());
}

double CellProblem::cubic_error(const Lobe& lobe) const { return estimate<true>(lobe); }
double CellProblem::l1_error(const Lobe& lobe) const { return estimate<false>(lobe); }

}  // namespace detail

// ---------------------------------------------------------------------------------------------------------- public parts
double brdf_cos(double roughness, double cosTheta, Vec3d l) {
    return detail::brdf_fcos(detail::make_brdf(roughness, cosTheta), l);
}

Albedo albedo_importance(double roughness, double cosTheta, int samples) {
    const detail::BrdfCtx ctx = detail::make_brdf(roughness, cosTheta);
    double sumA = 0.0, sumB = 0.0;
    for (int i = 0; i < samples; ++i) {
        double u1 = 0, u2 = 0;
        detail::hammersley(i, samples, u1, u2);
        double vdh = 0;
        const Vec3d l = detail::vndf_sample(ctx, u1, u2, &vdh);
        const double pdf = detail::vndf_pdf(ctx, l);
        if (!(pdf > 0.0)) continue;
        const double w = detail::brdf_fcos(ctx, l) / pdf;
        const double f = 1.0 - std::clamp(vdh, 0.0, 1.0);
        const double f2 = f * f;
        sumA += w;
        sumB += w * f2 * f2 * f;
    }
    return {sumA / static_cast<double>(samples), sumB / static_cast<double>(samples)};
}

Albedo albedo_quadrature(double roughness, double cosTheta, int grid) {
    const detail::BrdfCtx ctx = detail::make_brdf(roughness, cosTheta);
    double sumA = 0.0, sumB = 0.0;
    for (int iu = 0; iu < grid; ++iu) {
        // Half vectors with the density D(h) cos(theta_h) (its cumulative distribution is uniform in u).
        const double u = (static_cast<double>(iu) + 0.5) / static_cast<double>(grid);
        const double cos2 = (1.0 - u) / (1.0 - u + ctx.a2 * u);
        const double cosH = std::sqrt(cos2);
        const double sinH = std::sqrt(std::max(0.0, 1.0 - cos2));
        const double dd = cosH * cosH * (ctx.a2 - 1.0) + 1.0;
        const double pdf = ctx.a2 / (detail::kPi * dd * dd) * cosH;
        for (int ip = 0; ip < grid; ++ip) {
            const double phi = 2.0 * detail::kPi * (static_cast<double>(ip) + 0.5) / static_cast<double>(grid);
            double sn = 0, cs = 0;
            det_sincos(phi, sn, cs);
            const Vec3d h{sinH * cs, sinH * sn, cosH};
            const double vdh = dot(ctx.v, h);
            if (!(vdh > 0.0)) continue;
            const Vec3d l = h * (2.0 * vdh) - ctx.v;
            const double w = detail::brdf_fcos(ctx, l) * 4.0 * vdh / pdf;  // dl = 4 (v.h) dh
            const double f = 1.0 - vdh;
            const double f2 = f * f;
            sumA += w;
            sumB += w * f2 * f2 * f;
        }
    }
    const double n = static_cast<double>(grid) * static_cast<double>(grid);
    return {sumA / n, sumB / n};
}

double lobe_error(double roughness, double cosTheta, const Lobe& lobe, int samples) {
    const detail::CellProblem problem(roughness, cosTheta, samples, std::max(samples, 4096));
    return problem.l1_error(lobe);
}

}  // namespace fa::ltc
