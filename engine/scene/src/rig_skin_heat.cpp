// Bone heat (Baran and Popovic, "Automatic rigging and animation of 3D characters") on the welded mesh: for every bone i solve
//     (L + M H) w_i = M H p_i
// where L is the cotangent stiffness matrix, M the lumped mass, H = locality / d^2 with d the distance from a node to its nearest bone, and p_i is 1
// at the nodes whose nearest bones include i. The weights of a node are then normalised over the bones. A node can only be weighted to the bones of its
// mask (the bones of its part and their neighbours), which also keeps each solve small. Conjugate gradients with a Jacobi preconditioner, in double,
// in a fixed order: the same input gives the same bits.
#include <algorithm>
#include <cmath>

#include "rig_skin_internal.h"

namespace fa::rig_skin_detail {

void solve_heat(const Weld& weld, const std::vector<std::uint64_t>& mask, const std::vector<Seg>& bones,
                double locality, std::vector<Infl>& out, HeatStats& stats) {
    const std::size_t nn = weld.nodes();
    out.assign(nn, {});
    if (nn == 0 || bones.empty()) return;
    Vec3 lo = weld.pos[0], hi = weld.pos[0];
    for (const Vec3& p : weld.pos) {
        lo = {std::min(lo.x, p.x), std::min(lo.y, p.y), std::min(lo.z, p.z)};
        hi = {std::max(hi.x, p.x), std::max(hi.y, p.y), std::max(hi.z, p.z)};
    }
    const double diag = double(length(hi - lo));
    const double dFloor = std::max(0.004 * diag, 1e-6);

    // the heat of every node: H, the bones it is nearest to, the bones it may follow
    std::vector<double> heat(nn, 0.0);
    std::vector<std::uint64_t> nearest(nn, 0);
    for (std::size_t j = 0; j < nn; ++j) {
        std::uint64_t m = mask[j];
        if (!m) m = ~std::uint64_t(0) >> (64 - std::min<std::size_t>(64, bones.size()));
        float best = 1e30f;
        for (std::size_t b = 0; b < bones.size(); ++b)
            if (m >> b & 1) best = std::min(best, seg_dist2(weld.pos[j], bones[b]));
        const float limit = best * 1.1025f + 1e-12f;
        for (std::size_t b = 0; b < bones.size(); ++b)
            if ((m >> b & 1) && seg_dist2(weld.pos[j], bones[b]) <= limit) nearest[j] |= std::uint64_t(1) << b;
        const double d = std::max(std::sqrt(double(best)), dFloor);
        heat[j] = locality * weld.mass[j] / (d * d);
    }
    // the diagonal of L + M H
    std::vector<double> dg(nn, 0.0);
    for (std::size_t j = 0; j < nn; ++j) {
        double s = heat[j];
        for (std::uint32_t e = weld.rowStart[j]; e < weld.rowStart[j + 1]; ++e) s += double(weld.cot[e]);
        dg[j] = s;
    }

    std::vector<std::vector<std::uint32_t>> members(weld.components);
    for (std::size_t j = 0; j < nn; ++j) members[weld.component[j]].push_back(std::uint32_t(j));

    std::vector<char> active(nn, 0);
    std::vector<double> x(nn), r(nn), z(nn), p(nn), q(nn), b(nn);
    for (std::uint32_t c = 0; c < weld.components; ++c) {
        const std::vector<std::uint32_t>& all = members[c];
        std::uint64_t bonesHere = 0;
        for (std::uint32_t j : all) bonesHere |= mask[j] ? mask[j] : ~std::uint64_t(0);
        bool failed = false;
        for (std::size_t bone = 0; bone < bones.size() && !failed; ++bone) {
            if (!(bonesHere >> bone & 1)) continue;
            std::vector<std::uint32_t> list;
            bool any = false;
            for (std::uint32_t j : all) {
                const std::uint64_t m = mask[j] ? mask[j] : ~std::uint64_t(0);
                if (m >> bone & 1) {
                    active[j] = 1;
                    list.push_back(j);
                    if (nearest[j] >> bone & 1) any = true;
                }
            }
            if (any) {
                double bnorm = 0;
                for (std::uint32_t j : list) {
                    b[j] = (nearest[j] >> bone & 1) ? heat[j] : 0.0;
                    bnorm += b[j] * b[j];
                    x[j] = b[j] / dg[j];
                }
                auto apply = [&](const std::vector<double>& in, std::vector<double>& res) {
                    for (std::uint32_t j : list) {
                        double s = dg[j] * in[j];
                        for (std::uint32_t e = weld.rowStart[j]; e < weld.rowStart[j + 1]; ++e)
                            if (active[weld.col[e]]) s -= double(weld.cot[e]) * in[weld.col[e]];
                        res[j] = s;
                    }
                };
                apply(x, q);
                double rz = 0, rnorm = 0;
                for (std::uint32_t j : list) {
                    r[j] = b[j] - q[j];
                    z[j] = r[j] / dg[j];
                    p[j] = z[j];
                    rz += r[j] * z[j];
                    rnorm += r[j] * r[j];
                }
                const double tol2 = 1e-12 * bnorm;
                std::uint32_t it = 0;
                while (rnorm > tol2 && it < 600) {
                    apply(p, q);
                    double pq = 0;
                    for (std::uint32_t j : list) pq += p[j] * q[j];
                    if (!(pq > 0)) break;
                    const double alpha = rz / pq;
                    double rz2 = 0;
                    rnorm = 0;
                    for (std::uint32_t j : list) {
                        x[j] += alpha * p[j];
                        r[j] -= alpha * q[j];
                        z[j] = r[j] / dg[j];
                        rz2 += r[j] * z[j];
                        rnorm += r[j] * r[j];
                    }
                    const double beta = rz2 / rz;
                    rz = rz2;
                    for (std::uint32_t j : list) p[j] = z[j] + beta * p[j];
                    ++it;
                }
                const double rel = bnorm > 0 ? std::sqrt(rnorm / bnorm) : 0.0;
                stats.maxIterations = std::max(stats.maxIterations, it);
                stats.worstResidual = std::max(stats.worstResidual, rel);
                if (rel > 1e-3) {
                    failed = true;
                } else {
                    for (std::uint32_t j : list)
                        if (x[j] > 1e-6) out[j].push_back({std::uint16_t(bone), float(x[j])});
                }
            }
            for (std::uint32_t j : list) active[j] = 0;
        }
        if (failed) {
            ++stats.componentsFailed;
            for (std::uint32_t j : all) out[j].clear();
            continue;
        }
        ++stats.componentsSolved;
        for (std::uint32_t j : all) {
            normalize_infl(out[j], 0.0f);
            normalize_infl(out[j], 1e-4f);
            if (out[j].empty()) {
                // nothing diffused here (a node every nearest bone of which had no heat): follow the nearest bone
                for (std::size_t bone = 0; bone < bones.size(); ++bone)
                    if (nearest[j] >> bone & 1) {
                        out[j].push_back({std::uint16_t(bone), 1.0f});
                        break;
                    }
            }
        }
    }
}

}  // namespace fa::rig_skin_detail
