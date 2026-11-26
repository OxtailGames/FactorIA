#include "fa/render/gi.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>

#include "fa/scene/components.h"

namespace fa::render {

namespace {

bool finite3(Vec3 v) { return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z); }

void mix_bits(std::uint64_t& h, float f) {
    f += 0.0f;  // -0.0f and 0.0f are the same number: they must give the same key
    std::uint32_t bits;
    std::memcpy(&bits, &f, 4);
    for (int i = 0; i < 4; ++i) {
        h ^= (bits >> (8 * i)) & 0xffu;
        h *= 1099511628211ull;
    }
}

std::string num(double v) {
    char b[64];
    std::snprintf(b, sizeof(b), "%g", v);
    return b;
}

}  // namespace

int gi_axis_count(double extent, double spacing) {
    if (!(extent > 0.0) || !(spacing > 0.0)) return 1;
    const double n = std::floor(extent / spacing + 1e-4) + 1.0;
    return n > 1e6 ? 1000000 : int(n);
}

Result<GiLayout> gi_layout(const RealtimeGI& c, Vec3 worldPosition, const std::string& entityId) {
    const std::string who = "RealtimeGI of entity '" + entityId + "'";
    const auto in_range = [](double v, double lo, double hi) { return std::isfinite(v) && v >= lo && v <= hi; };
    if (!finite3(c.size) || c.size.x < 0.0f || c.size.y < 0.0f || c.size.z < 0.0f)
        return make_error(who + ": /size must be three finite numbers, none negative",
                          "Set size to the box in metres, e.g. [20, 6, 20]; 0 on an axis makes one layer of probes.");
    if (!finite3(c.offset) || !finite3(worldPosition))
        return make_error(who + ": /offset must be three finite numbers", "Set offset to e.g. [0, 0, 0].");
    if (!in_range(c.spacing, 0.25, 100.0))
        return make_error(who + ": /spacing " + num(c.spacing) + " is outside 0.25..100",
                          "Use 1 to 3 metres for a room; a smaller spacing makes eight times the probes.");
    if (c.resolution != 16 && c.resolution != 32)
        return make_error(who + ": /resolution " + std::to_string(c.resolution) + " is not 16 or 32",
                          "Use 16 (default) or 32 texels per face of a capture.");
    if (c.probesPerFrame < 1 || c.probesPerFrame > kGiMaxFrameProbes)
        return make_error(who + ": /probesPerFrame " + std::to_string(c.probesPerFrame) + " is outside 1.." +
                              std::to_string(kGiMaxFrameProbes),
                          "Each probe draws the scene six times: 1 to 4 a frame is usual.");
    if (!in_range(c.intensity, 0.0, 16.0))
        return make_error(who + ": /intensity " + num(c.intensity) + " is outside 0..16",
                          "Use 1 for the light as it is.");
    if (!in_range(c.bounce, 0.0, 1.0))
        return make_error(who + ": /bounce " + num(c.bounce) + " is outside 0..1",
                          "Use 1 for as many bounces as the frames give.");
    if (!in_range(c.hysteresis, 0.0, 0.99))
        return make_error(who + ": /hysteresis " + num(c.hysteresis) + " is outside 0..0.99",
                          "Use 0.9 to keep nine tenths of the old value; 0 replaces it at once.");
    if (!in_range(c.nearExclusion, 0.01, 10.0))
        return make_error(who + ": /nearExclusion " + num(c.nearExclusion) + " is outside 0.01..10",
                          "Use 0.1: surfaces closer than 10 cm to the probe are not captured.");
    if (!in_range(c.maxDistance, 1.0, 1000.0))
        return make_error(who + ": /maxDistance " + num(c.maxDistance) + " is outside 1..1000",
                          "Use the distance of the farthest wall that should light the grid, e.g. 30.");
    if (!(c.maxDistance > c.nearExclusion))
        return make_error(who + ": /maxDistance " + num(c.maxDistance) + " is not larger than /nearExclusion " +
                              num(c.nearExclusion),
                          "Raise /maxDistance or lower /nearExclusion.");
    if (!in_range(c.backfaceTolerance, 0.02, 0.9))
        return make_error(who + ": /backfaceTolerance " + num(c.backfaceTolerance) + " is outside 0.02..0.9",
                          "Use 0.25: a probe with a quarter of its rays on back faces is inside geometry.");
    const int nx = gi_axis_count(c.size.x, c.spacing), ny = gi_axis_count(c.size.y, c.spacing),
              nz = gi_axis_count(c.size.z, c.spacing);
    const double total = double(nx) * double(ny) * double(nz);
    if (total > double(kGiMaxProbes))
        return make_error(who + ": the grid would have " + std::to_string(nx) + " x " + std::to_string(ny) + " x " +
                              std::to_string(nz) + " probes (/size [" + num(c.size.x) + ", " + num(c.size.y) + ", " +
                              num(c.size.z) + "] at /spacing " + num(c.spacing) + "), over the limit of " +
                              std::to_string(kGiMaxProbes) + " probes for all the grids of a scene",
                          "Raise /spacing, shrink /size, or use size 0 on the height for one layer of probes.");
    GiLayout g;
    g.spacing = c.spacing;
    g.nx = nx;
    g.ny = ny;
    g.nz = nz;
    g.count = int(total);
    g.resolution = c.resolution;
    g.maxDistance = c.maxDistance;
    g.nearPlane = c.nearExclusion;
    g.intensity = c.intensity;
    g.bounce = c.bounce;
    g.hysteresis = c.hysteresis;
    g.backfaceTolerance = c.backfaceTolerance;
    // Only the ray traced mode reads these two, so a value outside the range is clamped (never an error: it would invalidate a grid the
    // raster captures draw fine).
    g.raysPerProbe = std::clamp(c.raysPerProbe, 16, 256);
    g.rtProbesPerFrame = std::clamp(c.rtProbesPerFrame, 1, 64);
    const Vec3 centre = worldPosition + c.offset;
    g.origin = {centre.x - 0.5f * float(nx - 1) * c.spacing, centre.y - 0.5f * float(ny - 1) * c.spacing,
                centre.z - 0.5f * float(nz - 1) * c.spacing};
    std::uint64_t h = 1469598103934665603ull;
    // The origin is not in the key (an entity that moves a little must not restart the grid: gi_layout_moved decides when it has moved
    // enough); the tags are, because they decide what a capture draws.
    for (float f : {g.spacing, float(nx), float(ny), float(nz), float(g.resolution), g.maxDistance, g.nearPlane})
        mix_bits(h, f);
    for (const Json* tags : {&c.showTags, &c.hideTags}) {
        const std::string text = tags->dump();
        for (unsigned char ch : text) {
            h ^= ch;
            h *= 1099511628211ull;
        }
        h ^= 0xffu;  // the end of a list, so [a] [] and [] [a] differ
        h *= 1099511628211ull;
    }
    g.key = h;
    return g;
}

bool gi_layout_moved(const GiLayout& g, Vec3 anchor) {
    const float limit = 0.5f * g.spacing;
    return std::fabs(g.origin.x - anchor.x) >= limit || std::fabs(g.origin.y - anchor.y) >= limit ||
           std::fabs(g.origin.z - anchor.z) >= limit;
}

Vec3 gi_probe_position(const GiLayout& g, int index) {
    const int x = index % g.nx, y = (index / g.nx) % g.ny, z = index / (g.nx * g.ny);
    return {g.origin.x + float(x) * g.spacing, g.origin.y + float(y) * g.spacing, g.origin.z + float(z) * g.spacing};
}

GiNeighbours gi_neighbours(const GiLayout& g, Vec3 p) {
    const int n[3] = {g.nx, g.ny, g.nz};
    const float local[3] = {(p.x - g.origin.x) / g.spacing, (p.y - g.origin.y) / g.spacing,
                            (p.z - g.origin.z) / g.spacing};
    int base[3];
    float frac[3];
    for (int a = 0; a < 3; ++a) {
        if (n[a] == 1) {
            base[a] = 0;
            frac[a] = 0.0f;
            continue;
        }
        const float c = std::clamp(std::isfinite(local[a]) ? local[a] : 0.0f, 0.0f, float(n[a] - 1));
        base[a] = std::min(int(std::floor(c)), n[a] - 2);
        frac[a] = c - float(base[a]);
    }
    GiNeighbours out;
    for (int i = 0; i < 8; ++i) {
        const int dx = i & 1, dy = (i >> 1) & 1, dz = (i >> 2) & 1;
        const int x = std::min(base[0] + dx, n[0] - 1), y = std::min(base[1] + dy, n[1] - 1),
                  z = std::min(base[2] + dz, n[2] - 1);
        out.index[i] = x + n[0] * (y + n[1] * z);
        out.weight[i] =
            (dx ? frac[0] : 1.0f - frac[0]) * (dy ? frac[1] : 1.0f - frac[1]) * (dz ? frac[2] : 1.0f - frac[2]);
    }
    // One layer on an axis: the two probes of that axis are the same one and the weights of both add up (they already sum to 1).
    return out;
}

GiTexel gi_block_origin(int block) {
    return GiTexel{(block % kGiBlocksPerRow) * kGiBlockW, kProbeAtlasSize + (block / kGiBlocksPerRow) * kGiBlockH};
}

Vec2 gi_depth_uv(Vec3 d) {
    const Vec2 e = oct_encode(d);
    return Vec2{kProbeBorder + (e.x * 0.5f + 0.5f) * float(kGiDepthTexels),
                kProbeBorder + (e.y * 0.5f + 0.5f) * float(kGiDepthTexels)};
}

void gi_pack_record(const GiLayout& g, int baseBlock, bool ready, float out[kGiRecordFloats]) {
    const float r[kGiRecordFloats] = {
        g.origin.x,    g.origin.y,  g.origin.z,     g.spacing,           float(g.nx),
        float(g.ny),   float(g.nz), float(g.count), float(baseBlock),    float(kGiBlocksPerRow),
        g.maxDistance, g.intensity, g.bounce,       g.backfaceTolerance, ready ? 1.0f : 0.0f,
        0.0f};
    std::memcpy(out, r, sizeof(r));
}

// ---- the blocks ----------------------------------------------------------------------------------------------------------------

std::optional<int> GiBlockAllocator::find(std::uint64_t id) const {
    for (const Run& r : runs_)
        if (r.id == id) return r.first;
    return std::nullopt;
}

void GiBlockAllocator::release(std::uint64_t id) {
    runs_.erase(std::remove_if(runs_.begin(), runs_.end(), [id](const Run& r) { return r.id == id; }), runs_.end());
}

std::optional<int> GiBlockAllocator::acquire(std::uint64_t id, int count) {
    if (count < 1 || count > kGiMaxProbes) return std::nullopt;
    for (const Run& r : runs_)
        if (r.id == id && r.count == count) return r.first;
    release(id);
    int at = 0;
    for (std::size_t i = 0; i <= runs_.size(); ++i) {
        const int end = i < runs_.size() ? runs_[i].first : kGiMaxProbes;
        if (end - at >= count) {
            runs_.insert(runs_.begin() + std::ptrdiff_t(i), Run{id, at, count});
            return at;
        }
        if (i < runs_.size()) at = runs_[i].first + runs_[i].count;
    }
    return std::nullopt;
}

int GiBlockAllocator::used() const {
    int n = 0;
    for (const Run& r : runs_) n += r.count;
    return n;
}

void GiBlockAllocator::clear() { runs_.clear(); }

// ---- the order ----------------------------------------------------------------------------------------------------------------

std::vector<int> gi_pick(const std::vector<std::uint64_t>& lastCapture, const std::vector<std::uint64_t>& retryFrame,
                         std::uint64_t frame, int budget) {
    std::vector<int> order;
    for (std::size_t i = 0; i < lastCapture.size(); ++i)
        if (i >= retryFrame.size() || retryFrame[i] <= frame) order.push_back(int(i));
    std::stable_sort(order.begin(), order.end(),
                     [&](int a, int b) { return lastCapture[std::size_t(a)] < lastCapture[std::size_t(b)]; });
    if (budget < 0) budget = 0;
    if (order.size() > std::size_t(budget)) order.resize(std::size_t(budget));
    return order;
}

}  // namespace fa::render
