// Reflection probes, the CPU side (M73-P3b; docs/design/ARCHITECTURE_PROBES.md): the octahedral mapping, the layout of a probe's
// tile in the atlas, the allocator that places the tiles, the scheduler that spreads the captures of the realtime probes over the
// frames, and the files of a baked probe. No GPU here: the renderer (src/renderer_probes.cpp) draws into the tiles this file
// lays out, and the tests check every function on the CPU.
//
// A probe's map is an OCTAHEDRAL image: the sphere of directions is folded onto a square (the upper half-sphere, around +Y, is the
// inner diamond; the lower half is the four corner triangles). One 2D texture holds many probes, which sokol (no cube arrays) and
// the mesh fragment shader's sixteen texture units both need. The map is stored with a one-texel border that repeats the texel
// across the edge (the mirror of the fold, oct_fold), so a bilinear tap at the edge is exact with a clamped sampler.
//
//   tile of resolution R, L = probe_levels(R) levels (R = 32: 3, 64: 4, 128: 5, 256: 5):
//     level k   (R >> k) x (R >> k) texels + the border; level 0 at the tile's origin, level k >= 1 stacked in a column to the right
//     SH row    the last row: nine texels, the coefficients of the probe's diffuse light (RGB each; RGBA8: c / 4 * 0.5 + 0.5)
//   level k holds the scene convolved with the GGX lobe of roughness k / (L - 1): a surface of roughness r reads level r * (L - 1).
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/lightmap_bake.h"

namespace fa {
struct ImageF;  // fa/core/image_float.h: not included here, its sRGB functions would clash with the renderer's (color_space.h)
}

namespace fa::render {

inline constexpr int kProbeMaxLevels = 5;
inline constexpr int kProbeShCoefficients = 9;
inline constexpr int kProbeBorder = 1;            // texels around each level
inline constexpr int kProbeAtlasSize = 1024;      // texels per side of the atlas (RGBA16F: 8 MB)
inline constexpr int kProbeSkyResolution = 128;   // the sky's entry (atlas entry 0): the resolution of the environment cube
inline constexpr std::uint64_t kProbeSkyId = 0;   // the allocator id of the sky; entities have bits above 0
inline constexpr int kProbeFaces = 6;
inline constexpr int kProbeFaceBudget = 2;        // faces the realtime probes may draw per frame, in all
inline constexpr int kProbeSlots = 2;             // probes with a capture in progress at once
inline constexpr int kProbeManifestVersion = 1;
inline constexpr int kProbeMaxCount = 256;        // probes the renderer keeps (the rest are listed as "over the limit")

// ---- the octahedral map -----------------------------------------------------------------------------------------------------

// A coordinate beyond [-1, 1] mirrored back inside: the texel across the edge is the one on this side with the other coordinate
// negated, so the border of a tile can be computed from the direction like any other texel.
Vec2 oct_fold(Vec2 e);
// The unit direction of the map coordinate e (x and y in [-1, 1], y down the image; the border's coordinates are folded first).
Vec3 oct_decode(Vec2 e);
// The map coordinate of a direction (not necessarily unit; the zero vector gives the centre).
Vec2 oct_encode(Vec3 direction);
// The coordinate of the centre of interior texel (x, y) of a level of `size` texels.
Vec2 oct_texel_coordinate(int x, int y, int size);
// The solid angle (steradians, summing to 4 pi over the interior texels of a `size` map) the texel at e covers.
float oct_texel_weight(Vec2 e, int size);

// ---- the capture camera of a face ---------------------------------------------------------------------------------------------

// The camera that captures face `face` (0..5: +X -X +Y -Y +Z -Z, the cube map's order) from the probe's position: it looks along the axis
// (`fwd`), is 90 degrees across and down, and is RIGHT-handed (right = fwd x up; the cube map specification's own face basis is left-handed,
// so the copy into the cube projects by direction and the handedness does not matter). The up of the four side faces is +Y, the up of +Y is
// -Z and the up of -Y is +Z.
struct ProbeFace {
    Vec3 fwd, up, right;
};
ProbeFace probe_face(int face);

// ---- the tile ---------------------------------------------------------------------------------------------------------------

// The resolution a request is rounded to: 32, 64, 128 or 256 (the nearest, ties up; a value outside is clamped).
int probe_resolution(int requested);
int probe_levels(int resolution);
// The roughness the level holds.
float probe_level_roughness(int levels, int level);
// The pyramid image the SH is projected from: the one 16 texels wide (S_1 of a 32 map ... S_4 of a 256 map).
int probe_sh_source(int resolution);

struct ProbeLayout {
    int resolution = 0, levels = 0;
    int tileW = 0, tileH = 0;  // with the SH row
    int levelX[kProbeMaxLevels]{}, levelY[kProbeMaxLevels]{};
    int levelSize[kProbeMaxLevels]{};  // interior texels per side; the region is levelSize + 2 * kProbeBorder
    int shY = 0;                       // the row of the SH texels; coefficient i is the texel at x = i
};
ProbeLayout probe_layout(int resolution);
// The pixels of a baked page: the tile without its SH row (the SH is a list of numbers in the manifest).
int probe_page_width(int resolution);
int probe_page_height(int resolution);

// ---- the atlas allocator ----------------------------------------------------------------------------------------------------

struct ProbeTile {
    int x = 0, y = 0;  // the tile's origin in the atlas
    int resolution = 0;
    bool valid() const { return resolution > 0; }
};

// Places tiles in a square atlas. A tile of one resolution goes into a SHELF of its own height (a row of equal slots), shelves are
// stacked from the top, a shelf with no tile left at the bottom is given back. Deterministic: the same requests in the same order
// give the same places on every machine. When no slot is free a tile may take the place of one whose probe has a strictly smaller
// importance (the lowest importance first, then the one used longest ago, then the largest id); an equal importance never
// evicts, so two probes never push each other out frame after frame.
class ProbeAtlasAllocator {
public:
    explicit ProbeAtlasAllocator(int atlasSize = kProbeAtlasSize) : size_(atlasSize) {}
    int atlas_size() const { return size_; }

    // The tile of `id` (a request with the same resolution keeps it; another resolution moves it). Evicted ids are added to
    // *evicted. Null when there is no room.
    std::optional<ProbeTile> acquire(std::uint64_t id, int resolution, int importance, std::uint64_t frame,
                                     std::vector<std::uint64_t>* evicted);
    void release(std::uint64_t id);
    // Marks `id` used at `frame` (the least recently used tile goes first).
    void touch(std::uint64_t id, std::uint64_t frame);
    std::optional<ProbeTile> find(std::uint64_t id) const;
    int count() const;
    // Texels of the atlas the tiles cover now, and the texels of the shelves (what no other resolution can use).
    std::uint64_t used_texels() const;
    std::uint64_t reserved_texels() const;

private:
    struct Slot {
        std::uint64_t id = 0;
        bool used = false;
        int importance = 0;
        std::uint64_t lastUsed = 0;
    };
    struct Shelf {
        int y = 0, h = 0, w = 0, resolution = 0;
        std::vector<Slot> slots;
    };
    int size_;
    std::vector<Shelf> shelves_;
    Slot* slot_of(std::uint64_t id, Shelf** shelf = nullptr, int* index = nullptr);
    const Slot* slot_of(std::uint64_t id, const Shelf** shelf, int* index) const;
    ProbeTile tile_at(const Shelf& s, int index) const;
    void trim();
};

// ---- the scheduler of the realtime probes -----------------------------------------------------------------------------------

enum class ProbeUpdateKind : std::uint8_t { EveryFrame, TimeSliced, OnDemand };

struct ProbeSpec {
    std::uint64_t id = 0;
    ProbeUpdateKind update = ProbeUpdateKind::TimeSliced;
    int importance = 0;
    int resolution = 128;
};

// Spreads the faces of the captures over the frames: at most `budget` faces a frame in all, at most kProbeSlots probes under way.
class ProbeScheduler {
public:
    struct Work {
        std::uint64_t id = 0;
        int slot = 0;       // the set of six face images the capture draws into
        int face = 0;       // 0..5
        bool last = false;  // the sixth face of this capture: the filtering follows it in the same frame
    };
    struct Info {
        std::uint64_t captures = 0;    // completed captures
        std::uint64_t lastFrame = 0;   // the frame the last one completed (0 = never)
        int facesDone = 0;             // of the capture under way (0 = none)
        bool pending = false;          // wants a capture
    };
    void set_budget(int faces);
    int budget() const { return budget_; }
    // The realtime probes of this frame. A probe that is no longer listed is forgotten; one whose resolution changed starts over.
    void set_probes(const std::vector<ProbeSpec>& probes);
    // An on-demand probe: capture once more. Any probe: capture again as soon as the budget allows.
    void refresh(std::uint64_t id);
    // The work of this frame (it assumes the caller does it).
    std::vector<Work> plan(std::uint64_t frame);
    Info info(std::uint64_t id) const;

private:
    struct State {
        ProbeSpec spec;
        Info info;
        int slot = -1;
        bool refresh = false;
    };
    std::vector<State> probes_;  // sorted by id
    int budget_ = kProbeFaceBudget;
    bool slotBusy_[kProbeSlots]{};
};

// ---- baked probes -----------------------------------------------------------------------------------------------------------

// *.probe.json, written by probe.bake next to its page (<name>.probe.<hash>.hdr): the manifest is written after the page, so a
// reader sees the old pair or the new one.
struct ProbeManifest {
    int version = kProbeManifestVersion;
    int resolution = 128;
    int levels = 5;
    std::string page;        // project-relative .hdr, probe_page_width x probe_page_height of RGBE texels
    std::string entity;      // the id of the entity that was baked (for the reader; the component names the file)
    float sh[kProbeShCoefficients][3]{};
    std::string hash;        // 16 hex digits of the page's bytes: what a hot reload compares, and in the page's name
};
Json probe_manifest_to_json(const ProbeManifest& manifest);
// Errors name the file, the JSON pointer and the fix.
Result<ProbeManifest> probe_manifest_from_json(const Json& json, const std::string& name);

// The nine coefficients of the light a page holds: its level 0, every texel weighted by its solid angle (oct_texel_weight) and the
// weights normalised to 4 pi, the same projection as the GPU's (env.glsl's fs_sh, probe.glsl's fs_sh) on a finer image.
fa::ShL2 probe_sh_from_page(const ImageF& page, int resolution);
// The first 16 lowercase hex digits of the SHA-256 of the bytes (what a hot reload compares, and in the page's name).
std::string probe_hash_hex(const std::vector<std::uint8_t>& bytes);
// The ImageF of the page from the RGBE texels `rgbe` (probe_page_width x probe_page_height x 4 bytes, row 0 first: what the GPU's
// RGBE pass writes) and back: encode_hdr / decode_hdr of the repo's own codec, so a page is the same bytes on every machine.
Result<ImageF> probe_page_from_rgbe(const std::vector<std::uint8_t>& rgbe, int resolution);

}  // namespace fa::render
