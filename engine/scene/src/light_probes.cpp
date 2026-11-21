#include "fa/scene/light_probes.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <utility>

#include "fa/core/fs.h"
#include "fa/scene/components.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/scene/world.h"

namespace fa {

namespace {

float saturate01(float v) { return std::clamp(v, 0.0f, 1.0f); }

// ---- the file (explicit little endian) --------------------------------------------------------------------------------------------------

void put32(std::vector<std::uint8_t>& out, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t((v >> (8 * i)) & 0xff));
}
void putf(std::vector<std::uint8_t>& out, float f) {
    std::uint32_t v;
    std::memcpy(&v, &f, 4);
    put32(out, v);
}

struct Reader {
    const std::uint8_t* p;
    std::size_t size, at = 0;
    bool ok = true;
    std::uint32_t u32() {
        if (at + 4 > size) {
            ok = false;
            return 0;
        }
        const std::uint32_t v = std::uint32_t(p[at]) | (std::uint32_t(p[at + 1]) << 8) |
                                (std::uint32_t(p[at + 2]) << 16) | (std::uint32_t(p[at + 3]) << 24);
        at += 4;
        return v;
    }
    float f32() {
        const std::uint32_t v = u32();
        float f;
        std::memcpy(&f, &v, 4);
        return f;
    }
    std::size_t left() const { return size - at; }
};

bool finite3v(Vec3 v) { return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z); }

// The number of probes along an axis of `extent` metres at `spacing`.
std::int64_t axis_count(double extent, double spacing) {
    if (!(extent > 0)) return 1;
    const double n = std::floor(extent / spacing + 1e-4) + 1.0;
    return n > 1e9 ? std::int64_t(1000000000) : std::int64_t(n);
}

}  // namespace

void ProbeSet::build_bounds() {
    bounds.clear();
    bounds.reserve(groups.size());
    constexpr float kMargin = 1e-3f;  // a little generous: the box never decides what the maths would not
    for (const ProbeGroup& g : groups) {
        ProbeBounds b;
        if (g.kind == ProbeGroupKind::Grid) {
            // grid_contribution gives coverage only below one spacing outside the (single-probe axes: half-spacing padded) lattice.
            const int n[3] = {g.nx, g.ny, g.nz};
            const float org[3] = {g.origin.x, g.origin.y, g.origin.z};
            float lo[3], hi[3];
            for (int a = 0; a < 3; ++a) {
                const float pad = n[a] == 1 ? 0.5f * g.spacing : 0.0f;
                lo[a] = org[a] - pad - g.spacing - kMargin;
                hi[a] = org[a] + float(n[a] - 1) * g.spacing + pad + g.spacing + kMargin;
            }
            b.lo = {lo[0], lo[1], lo[2]};
            b.hi = {hi[0], hi[1], hi[2]};
        } else {
            Vec3 lo{1e30f, 1e30f, 1e30f}, hi{-1e30f, -1e30f, -1e30f};
            for (std::int32_t i = 0; i < g.count; ++i) {
                const std::size_t idx = std::size_t(g.first) + std::size_t(i);
                if (idx >= positions.size()) break;
                lo = min(lo, positions[idx]);
                hi = max(hi, positions[idx]);
            }
            const float r = kProbePointRadius + kMargin;
            b.lo = lo - Vec3{r, r, r};
            b.hi = hi + Vec3{r, r, r};
        }
        bounds.push_back(b);
    }
}

std::size_t ProbeSet::invalid_count() const {
    std::size_t n = 0;
    for (std::uint8_t v : valid) n += v == 0 ? 1 : 0;
    return n;
}

Result<void> add_probe_group(ProbeSet& set, const std::string& entityId, const LightProbeGroup& c, Vec3 worldPosition) {
    const std::string who = "LightProbeGroup of entity '" + entityId + "'";
    if (c.grid) {
        if (!finite3v(c.size) || c.size.x < 0 || c.size.y < 0 || c.size.z < 0 || !finite3v(c.offset))
            return make_error(who + ": /size and /offset must be finite and /size not negative",
                              "Set size to the box in metres, e.g. [10, 4, 10].");
        if (!std::isfinite(c.spacing) || c.spacing < 0.25f || c.spacing > 100.0f)
            return make_error(who + ": /spacing " + std::to_string(c.spacing) + " is outside 0.25..100",
                              "Use 1 to 2 metres for a room; a smaller spacing makes eight times the probes.");
        const std::int64_t nx = axis_count(c.size.x, c.spacing), ny = axis_count(c.size.y, c.spacing),
                           nz = axis_count(c.size.z, c.spacing);
        const double total = double(nx) * double(ny) * double(nz);
        if (total > double(kMaxProbesPerGroup))
            return make_error(who + ": the grid would have " + std::to_string(nx) + " x " + std::to_string(ny) + " x " +
                                  std::to_string(nz) + " probes (/size " + std::to_string(c.size.x) + ", " +
                                  std::to_string(c.size.y) + ", " + std::to_string(c.size.z) + " at /spacing " +
                                  std::to_string(c.spacing) + "), over the limit of " +
                                  std::to_string(kMaxProbesPerGroup) + " per group",
                              "Raise /spacing, shrink /size, or split the area over several entities with a "
                              "LightProbeGroup each (a scene may have up to " +
                                  std::to_string(kMaxProbes) + " probes).");
        if (double(set.size()) + total > double(kMaxProbes))
            return make_error(who + ": the scene would have more than " + std::to_string(kMaxProbes) + " probes",
                              "Raise /spacing or shrink /size of some LightProbeGroups.");
        if (int(set.groups.size()) >= kMaxProbeGroups)
            return make_error("a scene may have at most " + std::to_string(kMaxProbeGroups) + " probe groups",
                              "Merge LightProbeGroups.");
        ProbeGroup g;
        g.id = entityId;
        g.kind = ProbeGroupKind::Grid;
        g.first = std::int32_t(set.size());
        g.nx = std::int32_t(nx);
        g.ny = std::int32_t(ny);
        g.nz = std::int32_t(nz);
        g.count = std::int32_t(total);
        g.spacing = c.spacing;
        const Vec3 centre = worldPosition + c.offset;
        g.origin = {centre.x - 0.5f * float(nx - 1) * c.spacing, centre.y - 0.5f * float(ny - 1) * c.spacing,
                    centre.z - 0.5f * float(nz - 1) * c.spacing};
        for (std::int32_t z = 0; z < g.nz; ++z)
            for (std::int32_t y = 0; y < g.ny; ++y)
                for (std::int32_t x = 0; x < g.nx; ++x)
                    set.positions.push_back({g.origin.x + float(x) * c.spacing, g.origin.y + float(y) * c.spacing,
                                             g.origin.z + float(z) * c.spacing});
        set.groups.push_back(std::move(g));
    }
    if (c.points.is_array() && !c.points.empty()) {
        if (c.points.size() > std::size_t(kMaxProbePoints))
            return make_error(who + ": /points has " + std::to_string(c.points.size()) + " entries, at most " +
                                  std::to_string(kMaxProbePoints) + " are read",
                              "Use the grid for many probes.");
        if (double(set.size()) + double(c.points.size()) > double(kMaxProbes))
            return make_error(who + ": the scene would have more than " + std::to_string(kMaxProbes) + " probes",
                              "Raise /spacing or shrink /size of some LightProbeGroups.");
        if (int(set.groups.size()) >= kMaxProbeGroups)
            return make_error("a scene may have at most " + std::to_string(kMaxProbeGroups) + " probe groups",
                              "Merge LightProbeGroups.");
        ProbeGroup g;
        g.id = entityId;
        g.kind = ProbeGroupKind::Points;
        g.first = std::int32_t(set.size());
        g.count = std::int32_t(c.points.size());
        std::vector<Vec3> pts;
        for (std::size_t i = 0; i < c.points.size(); ++i) {
            const Json& e = c.points[i];
            const std::string at = who + ": /points/" + std::to_string(i);
            if (!e.is_array() || e.size() != 3 || !e[0].is_number() || !e[1].is_number() || !e[2].is_number())
                return make_error(at + " must be [x, y, z] (three numbers)", "Example: \"points\": [[1, 1.5, -2]].");
            const Vec3 p{float(e[0].get<double>()), float(e[1].get<double>()), float(e[2].get<double>())};
            if (!finite3v(p)) return make_error(at + " is not a finite position", "Remove the NaN or infinite value.");
            pts.push_back(p);
        }
        for (const Vec3& p : pts) set.positions.push_back(p);
        set.groups.push_back(std::move(g));
    }
    set.build_bounds();
    return {};
}

Result<void> collect_probe_groups(World& world, ProbeSet& set) {
    std::vector<std::pair<std::string, Entity>> groupEntities;
    world.each<LightProbeGroup>([&](Entity e, LightProbeGroup&) {
        if (world.active_in_hierarchy(e)) groupEntities.emplace_back(world.id_of(e), e);
    });
    std::sort(groupEntities.begin(), groupEntities.end(),
              [](const auto& a, const auto& b) { return a.first < b.first; });
    for (const auto& [id, e] : groupEntities) {
        const Vec3 at = world.world_matrix(e).translation();
        if (auto r = add_probe_group(set, id, *world.get<LightProbeGroup>(e), at); !r) return r;
    }
    return {};
}

std::vector<std::uint8_t> encode_probe_set(const ProbeSet& set) {
    std::vector<std::uint8_t> out;
    out.reserve(16 + set.size() * (12 + 108 + 1) + set.groups.size() * 64);
    put32(out, kProbeFileMagic);
    put32(out, kProbeFileVersion);
    put32(out, std::uint32_t(set.groups.size()));
    put32(out, std::uint32_t(set.size()));
    for (const ProbeGroup& g : set.groups) {
        put32(out, std::uint32_t(g.kind));
        put32(out, std::uint32_t(g.first));
        put32(out, std::uint32_t(g.count));
        put32(out, std::uint32_t(g.nx));
        put32(out, std::uint32_t(g.ny));
        put32(out, std::uint32_t(g.nz));
        putf(out, g.spacing);
        putf(out, g.origin.x);
        putf(out, g.origin.y);
        putf(out, g.origin.z);
        put32(out, std::uint32_t(g.id.size()));
        out.insert(out.end(), g.id.begin(), g.id.end());
    }
    for (const Vec3& p : set.positions) {
        putf(out, p.x);
        putf(out, p.y);
        putf(out, p.z);
    }
    for (std::size_t i = 0; i < set.size(); ++i)
        for (int k = 0; k < 9; ++k) {
            const Vec3 c = i < set.sh.size() ? set.sh[i].c[k] : Vec3{};
            putf(out, c.x);
            putf(out, c.y);
            putf(out, c.z);
        }
    for (std::size_t i = 0; i < set.size(); ++i) out.push_back(i < set.valid.size() ? set.valid[i] : 0);
    return out;
}

Result<ProbeSet> decode_probe_set(const std::uint8_t* data, std::size_t size, const std::string& file) {
    Reader r{data, size};
    auto bad = [&](const std::string& what) {
        return make_error("light probe file " + file + ": " + what, "Bake the lightmaps again (lightmap.bake).");
    };
    if (r.u32() != kProbeFileMagic) return bad("it is not a light probe file (wrong magic)");
    const std::uint32_t version = r.u32();
    if (version != kProbeFileVersion)
        return bad("it is version " + std::to_string(version) + ", this engine reads version " +
                   std::to_string(kProbeFileVersion));
    const std::uint32_t groups = r.u32(), probes = r.u32();
    if (!r.ok || groups > std::uint32_t(kMaxProbeGroups) || probes > std::uint32_t(kMaxProbes))
        return bad("it lists " + std::to_string(groups) + " groups and " + std::to_string(probes) +
                   " probes, over the limits (" + std::to_string(kMaxProbeGroups) + ", " + std::to_string(kMaxProbes) +
                   ")");
    ProbeSet set;
    set.groups.reserve(groups);
    std::uint64_t covered = 0;
    for (std::uint32_t i = 0; i < groups; ++i) {
        ProbeGroup g;
        const std::uint32_t kind = r.u32(), first = r.u32(), count = r.u32();
        const std::uint32_t nx = r.u32(), ny = r.u32(), nz = r.u32();
        g.spacing = r.f32();
        g.origin = {r.f32(), r.f32(), r.f32()};
        const std::uint32_t idLen = r.u32();
        if (!r.ok || idLen > 4096 || idLen > r.left()) return bad("group " + std::to_string(i) + " is cut short");
        g.id.assign(reinterpret_cast<const char*>(data + r.at), idLen);
        r.at += idLen;
        if (kind > 1 || first != covered || count > probes || first + std::uint64_t(count) > probes)
            return bad("group " + std::to_string(i) + " does not fit the probe list");
        g.kind = ProbeGroupKind(kind);
        g.first = std::int32_t(first);
        g.count = std::int32_t(count);
        if (kind == 0) {
            if (nx < 1 || ny < 1 || nz < 1 || std::uint64_t(nx) * ny * nz != count ||
                !(g.spacing >= 0.25f && g.spacing <= 100.0f) || !finite3v(g.origin))
                return bad("grid group " + std::to_string(i) + " has an inconsistent size or spacing");
            g.nx = std::int32_t(nx);
            g.ny = std::int32_t(ny);
            g.nz = std::int32_t(nz);
        }
        covered += count;
        set.groups.push_back(std::move(g));
    }
    if (covered != probes)
        return bad("its groups cover " + std::to_string(covered) + " of " + std::to_string(probes) + " probes");
    const std::uint64_t need = std::uint64_t(probes) * (12 + 108 + 1);
    if (!r.ok || need > r.left())
        return bad("it is cut short (" + std::to_string(r.left()) + " bytes left, " + std::to_string(need) +
                   " needed)");
    set.positions.resize(probes);
    for (Vec3& p : set.positions) {
        p = {r.f32(), r.f32(), r.f32()};
        if (!finite3v(p)) return bad("a probe position is not finite");
    }
    set.sh.resize(probes);
    for (ShL2& s : set.sh)
        for (int k = 0; k < 9; ++k) {
            s.c[k] = {r.f32(), r.f32(), r.f32()};
            if (!finite3v(s.c[k])) return bad("a probe holds a coefficient that is not finite");
        }
    set.valid.resize(probes);
    for (std::uint8_t& v : set.valid) v = data[r.at++] != 0 ? 1 : 0;
    set.build_bounds();
    return set;
}

Result<ProbeSet> load_probe_set(const std::string& path) {
    auto bytes = fs::read_bytes(path);
    if (!bytes)
        return make_error("cannot read the light probe file '" + path + "': " + bytes.error().message,
                          bytes.error().hint);
    return decode_probe_set(bytes->data(), bytes->size(), path);
}

// ---- interpolation ------------------------------------------------------------------------------------------------------------------------

namespace {

struct Accum {
    ShL2 sum;
    float weight = 0;
    int used = 0;
    void add(const ShL2& sh, float w) {
        if (!(w > 0)) return;
        for (int k = 0; k < 9; ++k) sum.c[k] += sh.c[k] * w;
        weight += w;
        ++used;
    }
};

// One grid: its contribution as (SH mean, weight 0..1).
void grid_contribution(const ProbeSet& s, const ProbeGroup& g, Vec3 p, Accum& acc) {
    const int n[3] = {g.nx, g.ny, g.nz};
    const float pos[3] = {p.x, p.y, p.z};
    const float org[3] = {g.origin.x, g.origin.y, g.origin.z};
    float out2 = 0;
    int i0[3];
    float f[3];
    for (int a = 0; a < 3; ++a) {
        const float lo = org[a] - (n[a] == 1 ? 0.5f * g.spacing : 0.0f);
        const float hi = org[a] + float(n[a] - 1) * g.spacing + (n[a] == 1 ? 0.5f * g.spacing : 0.0f);
        const float excess = std::max(0.0f, std::max(lo - pos[a], pos[a] - hi));
        out2 += excess * excess;
        if (n[a] == 1) {
            i0[a] = 0;
            f[a] = 0;
        } else {
            const float t = std::clamp((pos[a] - org[a]) / g.spacing, 0.0f, float(n[a] - 1));
            i0[a] = std::min(int(std::floor(t)), n[a] - 2);
            f[a] = t - float(i0[a]);
        }
    }
    const float cov = 1.0f - saturate01(std::sqrt(out2) / g.spacing);
    if (!(cov > 0)) return;
    ShL2 mean;
    float w = 0;
    int used = 0;
    for (int c = 0; c < 8; ++c) {
        const int dx = c & 1, dy = (c >> 1) & 1, dz = (c >> 2) & 1;
        const float wc = (dx ? f[0] : 1.0f - f[0]) * (dy ? f[1] : 1.0f - f[1]) * (dz ? f[2] : 1.0f - f[2]);
        if (!(wc > 0)) continue;
        const int ix = std::min(i0[0] + dx, n[0] - 1), iy = std::min(i0[1] + dy, n[1] - 1),
                  iz = std::min(i0[2] + dz, n[2] - 1);
        const std::size_t idx = std::size_t(g.first) +
                                (std::size_t(iz) * std::size_t(n[1]) + std::size_t(iy)) * std::size_t(n[0]) +
                                std::size_t(ix);
        if (idx >= s.sh.size() || s.valid[idx] == 0) continue;
        for (int k = 0; k < 9; ++k) mean.c[k] += s.sh[idx].c[k] * wc;
        w += wc;
        ++used;
    }
    if (!(w > 1e-4f)) return;
    for (int k = 0; k < 9; ++k) mean.c[k] = mean.c[k] / w;
    acc.add(mean, cov * saturate01(w / 0.25f));
    acc.used += used - 1;  // add() counted the group once
}

}  // namespace

ProbeLight probe_light_at(const ProbeSet& set, Vec3 p) {
    ProbeLight out;
    if (!set.baked() || !finite3v(p)) return out;
    Accum acc;
    const bool boxed = set.bounds.size() == set.groups.size();
    for (std::size_t gi = 0; gi < set.groups.size(); ++gi) {
        const ProbeGroup& g = set.groups[gi];
        if (boxed) {
            const ProbeBounds& b = set.bounds[gi];
            if (p.x < b.lo.x || p.y < b.lo.y || p.z < b.lo.z || p.x > b.hi.x || p.y > b.hi.y || p.z > b.hi.z)
                continue;  // no probe of the group reaches the point
        }
        if (g.kind == ProbeGroupKind::Grid) {
            grid_contribution(set, g, p, acc);
        } else {
            for (int i = 0; i < g.count; ++i) {
                const std::size_t idx = std::size_t(g.first + i);
                if (set.valid[idx] == 0) continue;
                const float d = length(set.positions[idx] - p);
                const float t = 1.0f - d / kProbePointRadius;
                if (t > 0) acc.add(set.sh[idx], t * t);
            }
        }
    }
    if (!(acc.weight > 0)) return out;
    for (int k = 0; k < 9; ++k) out.sh.c[k] = acc.sum.c[k] / acc.weight;
    out.coverage = std::min(1.0f, acc.weight);
    out.probesUsed = acc.used;
    return out;
}

const ProbeGroup* find_same_probe_group(const ProbeSet& in, const ProbeSet& of, const ProbeGroup& g) {
    auto near = [](Vec3 a, Vec3 b, float tol) {
        return std::fabs(a.x - b.x) <= tol && std::fabs(a.y - b.y) <= tol && std::fabs(a.z - b.z) <= tol;
    };
    for (const ProbeGroup& cand : in.groups) {
        if (cand.id != g.id || cand.kind != g.kind || cand.count != g.count) continue;
        if (g.kind == ProbeGroupKind::Grid) {
            if (cand.nx == g.nx && cand.ny == g.ny && cand.nz == g.nz && std::fabs(cand.spacing - g.spacing) <= 1e-4f &&
                near(cand.origin, g.origin, 1e-3f))
                return &cand;
            continue;
        }
        bool same = true;
        for (std::int32_t i = 0; same && i < g.count; ++i) {
            const std::size_t a = std::size_t(cand.first) + std::size_t(i), b = std::size_t(g.first) + std::size_t(i);
            same = a < in.positions.size() && b < of.positions.size() && near(in.positions[a], of.positions[b], 1e-3f);
        }
        if (same) return &cand;
    }
    return nullptr;
}

std::uint64_t probe_light_key(const ProbeLight& light) {
    if (!(light.coverage > 0)) return 0;
    std::uint64_t h = kLightmapHashSeed;
    auto q = [&](float v) {
        // 1/1024 of a unit of radiance: far below what shows. Clamped first: a NaN or huge value must not reach llround.
        const double c = std::isnan(v) ? 0.0 : std::clamp(double(v), -1.0e6, 1.0e6);
        const std::int64_t i = std::int64_t(std::llround(c * 1024.0));
        h = lightmap_hash_bytes(h, &i, sizeof i);
    };
    q(light.coverage);
    for (const Vec3& c : light.sh.c) {
        q(c.x);
        q(c.y);
        q(c.z);
    }
    return h | 1u;  // never 0: 0 means "no probe light"
}

}  // namespace fa
