// Light probes (M73.4d, docs/design/ARCHITECTURE_BAKING.md, "Light probes and mixed lights"): the baked spherical harmonics of the light at points of the scene, that a
// moving object (one with no lightmap of its own) reads as its ambient light. GPU-free: the layout of the probes of a LightProbeGroup, the file
// lightmap.bake writes next to the lightmap pages, and the CPU interpolation the renderer uses per mesh.
//
// The file `<stem>.lightmap.<hash8>.probes` (little endian, whatever the machine): u32 magic "FAPR", u32 version, u32 groups, u32 probes; per
// group u32 kind (0 grid, 1 points), u32 first, u32 count, u32 nx, ny, nz, f32 spacing, f32 origin x, y, z, u32 id length, the id bytes;
// then per probe 3 f32 (position), per probe 27 f32 (nine RGB coefficients of ShL2, radiance), per probe one byte (1 = valid).
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/lightmap_bake.h"

namespace fa {

struct LightProbeGroup;

inline constexpr int kMaxProbesPerGroup = 16384;  // grid probes of one LightProbeGroup
inline constexpr int kMaxProbePoints = 256;       // single points of one LightProbeGroup
inline constexpr int kMaxProbes = 65536;          // probes of a scene
inline constexpr int kMaxProbeGroups = 4096;
inline constexpr float kProbePointRadius = 5.0f;               // metres a single probe reaches
inline constexpr std::uint32_t kProbeFileMagic = 0x52504146u;  // "FAPR"
inline constexpr std::uint32_t kProbeFileVersion = 1;

enum class ProbeGroupKind : std::int32_t { Grid = 0, Points = 1 };

// One group of probes of a baked set. The probes of a grid run x fastest: index = first + (iz * ny + iy) * nx + ix, at origin + (ix, iy, iz) * spacing
// (an axis with count 1 sits at origin). The grid is centred on the box of the component, so its span is (count - 1) * spacing on each axis.
struct ProbeGroup {
    std::string id;  // the entity's id
    ProbeGroupKind kind = ProbeGroupKind::Grid;
    std::int32_t first = 0, count = 0;
    std::int32_t nx = 1, ny = 1, nz = 1;
    float spacing = 1;
    Vec3 origin{};
};

struct ProbeSet {
    std::vector<ProbeGroup> groups;
    std::vector<Vec3> positions;
    std::vector<ShL2> sh;             // empty before the bake; else one per position (zeros for an invalid probe)
    std::vector<std::uint8_t> valid;  // empty before the bake; else 1 = usable, 0 = inside geometry
    std::size_t size() const { return positions.size(); }
    bool baked() const {
        return !positions.empty() && sh.size() == positions.size() && valid.size() == positions.size();
    }
    std::size_t invalid_count() const;
};

// Appends the groups of a LightProbeGroup component whose entity is at `worldPosition`: the grid (unless `grid` is false) and the points. Errors
// name the field (/size, /points/3) and what to change: a count over kMaxProbesPerGroup, a bad point, more than kMaxProbes in the set.
Result<void> add_probe_group(ProbeSet& set, const std::string& entityId, const LightProbeGroup& component,
                             Vec3 worldPosition);

// The files. `file` only names it in errors. decode checks every count against the size before it allocates anything.
std::vector<std::uint8_t> encode_probe_set(const ProbeSet& set);
Result<ProbeSet> decode_probe_set(const std::uint8_t* data, std::size_t size, const std::string& file);
Result<ProbeSet> load_probe_set(const std::string& path);  // a project path, through fa::fs

// What a point of the world receives: the interpolated radiance SH of the probes around it and how much of it the probes cover.
struct ProbeLight {
    ShL2 sh;  // weighted mean of the covering probes; zeros when coverage is 0
    float coverage =
        0;  // 0 = no probe reaches the point (use the sky's ambient), 1 = fully inside the probes; in between it blends
    int probesUsed = 0;  // probes that contributed (grid corners and points with a non-zero weight)
};
// Trilinear in each grid (corners that are invalid are skipped and the rest renormalised, the coverage falls where too little is left), a
// fade over one spacing outside a grid's box, single points with weight (1 - d / radius)^2. Deterministic and continuous in `p`.
ProbeLight probe_light_at(const ProbeSet& set, Vec3 p);

// 64-bit hash of the SH and coverage a point gets, quantised to 1/1024 (a non-finite value is clamped), so equal light gives an equal key (batching, caches). 0 for coverage 0.
std::uint64_t probe_light_key(const ProbeLight& light);

}  // namespace fa
