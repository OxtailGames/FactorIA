#include "probe_select.h"

#include <algorithm>
#include <cmath>

namespace fa::render {

void probe_volume_finish(ProbeVolume& v) {
    Vec3 ext{0, 0, 0};
    for (int i = 0; i < 3; ++i) {
        const float h = std::max(v.half[i], 1.0e-4f);
        v.half[i] = h;
        const Vec3 a = v.axis[i];
        v.rows[i][0] = a.x / h;
        v.rows[i][1] = a.y / h;
        v.rows[i][2] = a.z / h;
        v.rows[i][3] = -dot(a, v.center) / h;
        ext.x += std::fabs(a.x) * h;
        ext.y += std::fabs(a.y) * h;
        ext.z += std::fabs(a.z) * h;
    }
    v.lo = v.center - ext;
    v.hi = v.center + ext;
    v.volume = 8.0f * v.half.x * v.half.y * v.half.z;
}

namespace {

struct Cand {
    int index = -1;
    int steps = 0;
    float dist2 = 0.0f;
};

bool better(const std::vector<ProbeVolume>& vols, const Cand& a, const Cand& b) {
    const ProbeVolume& x = vols[std::size_t(a.index)];
    const ProbeVolume& y = vols[std::size_t(b.index)];
    if (x.importance != y.importance) return x.importance > y.importance;
    if (x.volume != y.volume) return x.volume < y.volume;
    if (a.dist2 != b.dist2) return a.dist2 < b.dist2;
    return x.id < y.id;
}

}  // namespace

ProbePick pick_probes(const std::vector<ProbeVolume>& vols, Vec3 p) {
    ProbePick out;
    if (vols.empty() || !std::isfinite(p.x) || !std::isfinite(p.y) || !std::isfinite(p.z)) return out;
    Cand best[2];
    const std::size_t n = std::min<std::size_t>(vols.size(), 511);
    for (std::size_t i = 0; i < n; ++i) {
        const ProbeVolume& v = vols[i];
        if (p.x < v.lo.x || p.x > v.hi.x || p.y < v.lo.y || p.y > v.hi.y || p.z < v.lo.z || p.z > v.hi.z) continue;
        // How far inside the box the point is: the smallest distance to a face along the box's own axes.
        const Vec3 d = p - v.center;
        float inside = v.half.x - std::fabs(dot(d, v.axis[0]));
        inside = std::min(inside, v.half.y - std::fabs(dot(d, v.axis[1])));
        inside = std::min(inside, v.half.z - std::fabs(dot(d, v.axis[2])));
        if (!(inside >= 0.0f)) continue;
        const float w = v.blend > 1.0e-4f ? std::clamp(inside / v.blend, 0.0f, 1.0f) : 1.0f;
        const int steps = int(w * float(kProbeShareSteps) + 0.5f);
        if (steps < 1) continue;
        const Vec3 to = p - v.position;
        Cand c{int(i), steps, dot(to, to)};
        if (best[0].index < 0 || better(vols, c, best[0])) {
            best[1] = best[0];
            best[0] = c;
        } else if (best[1].index < 0 || better(vols, c, best[1])) {
            best[1] = c;
        }
    }
    if (best[0].index < 0) return out;
    out.index[0] = std::uint16_t(best[0].index + 1);
    out.steps[0] = std::uint8_t(best[0].steps);
    if (best[1].index >= 0 && best[0].steps < kProbeShareSteps) {
        out.index[1] = std::uint16_t(best[1].index + 1);
        out.steps[1] = std::uint8_t(best[1].steps);
    }
    return out;
}

}  // namespace fa::render
