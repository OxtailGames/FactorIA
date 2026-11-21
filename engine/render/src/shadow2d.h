// ShadowCaster2D: the segments of the 2D shadows that do not come from tiles (docs/rendering/RENDERING_2D_SHADOWS.md).
//
// A caster is a closed outline in world space: a box, a polygon, or the contour of a sprite's alpha (marching squares on
// the texture, simplified, cached per texture + frame region + threshold). light2d.cpp turns the outlines near a light
// into the same row of kShadowAngles distances the tile ray cast fills: every segment is rasterised into the angles it
// covers, so the cost of a row is the number of (segment, angle) pairs it covers, not rays x all the segments of the scene.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "fa/core/math.h"

namespace fa {
class World;
}

namespace fa::render {

struct Frame;

// Caps (deterministic work counts: a result never depends on how fast the machine is). Normal use is 10x below each.
constexpr int kMaxShadowCasters2D = 2048;  // casters a frame reads; the others (in entity order) cast no shadow
constexpr int kMaxCasterSegments2D = 256;  // segments of one caster (a contour is simplified to fit; a polygon is cut)
constexpr int kMaxCasterBodiesPerLight = 512;  // casters one light's row reads (in entity order)
constexpr std::uint64_t kMaxRowWork2D =
    1u << 20;  // segment x angle tests of one light's row; the casters after it (in entity order) are skipped
constexpr std::size_t kMaxEntityWarnings2D = 64;  // distinct per-entity warnings a scene logs
constexpr int kMaxContourLoops2D = 16;            // closed outlines kept from one sprite
constexpr int kMaxContourPixels2D = 512 * 512;  // alpha pixels one contour reads; a larger region is reduced by blocks

// The outline(s) of an alpha image in pixel units of the region ([0, w] x [0, h], y down): marching squares on `alpha`
// (w x h bytes, row 0 first) at `threshold` (0..1, a pixel is inside when its alpha is above it), padded with an empty
// border so every outline closes, then simplified (Douglas-Peucker) to at most `maxPoints` points in all. Loops with a
// near-zero area are dropped, the biggest kMaxContourLoops2D are kept, biggest first.
using ContourLoops = std::vector<std::vector<Vec2>>;
ContourLoops contour_from_alpha(const std::uint8_t* alpha, int w, int h, float threshold, int maxPoints);

struct ShadowSegment {
    float ax, ay, bx, by;
};

// One caster of the frame, in world space.
struct ShadowBody {
    std::uint32_t first = 0, count = 0;  // its segments in CasterSet::segs, in loop order
    std::int32_t layers = -1;            // ShadowCaster2D.lightLayers
    bool selfShadow = false;
    float x0 = 0, y0 = 0, x1 = 0, y1 = 0;  // bounding box
    std::uint64_t hash = 0;                // of the segments and selfShadow: a light's cached row is keyed on it
};

struct CasterSet {
    std::vector<ShadowSegment> segs;
    std::vector<ShadowBody> bodies;
    bool empty() const { return bodies.empty(); }
};

// What a sprite's alpha gave, kept across frames by the renderer (a member of ShadowCache).
struct ContourCache {
    struct Alpha {
        int w = 0, h = 0;
        bool ok = false;
        std::string problem;  // why the pixels cannot be read (empty when ok)
        std::vector<std::uint8_t> a;
        std::uint64_t used = 0;
    };
    struct Entry {
        ContourLoops loops;
        std::uint64_t used = 0;
        bool fallbackBox = false;  // the alpha could not be read: the sprite's rectangle stands in
    };
    std::unordered_map<std::string, Alpha> planes;    // alpha channel per texture file (key: path + image id)
    std::unordered_map<std::string, Entry> contours;  // key: path + image id + region + threshold
    std::uint64_t tick = 0;  // one per gather_shadow_casters call: an entry is old when no pass of the last two used it
    std::uint64_t contoursMade = 0;  // for tests: how many contours were really extracted
    std::size_t planeBytes = 0;
    std::unordered_set<std::string>
        warned;  // per-entity warnings already logged this scene (at most kMaxEntityWarnings2D)
    std::unordered_set<std::string> warnedFixed;  // fixed-key warnings already logged this scene (a handful of keys)
};

// The casters of the frame: every enabled ShadowCaster2D of an active entity this camera draws, as world segments.
void gather_shadow_casters(World& world, Frame& f, ContourCache& cache, CasterSet& out);

// The casters whose box reaches the disc (px, py, radius) and that block a light with `layers` (a bit in common), in
// entity order, at most kMaxCasterBodiesPerLight. `over` is set when the cap cut the list.
void casters_in_reach(const CasterSet& set, float px, float py, float radius, std::int32_t layers,
                      std::vector<std::uint32_t>& out, bool& over);

// Lowers dist[i] (kShadowAngles entries, direction i * 2 pi / kShadowAngles, counter-clockwise from +x) to the distance at
// which the casters in `bodies` start to shadow the ray: the near side of an outline when it has selfShadow, otherwise the
// far side of the first outline the ray enters (its own face stays lit, like the face of a tile). A caster that holds the
// light inside its outline does not block that light. Returns the work done (segment/angle pairs tested), for tests.
// Stops at kMaxRowWork2D tests (a count, never time) and sets `*cut` when it did: the result is the same on every machine.
std::uint64_t cast_casters(const CasterSet& set, const std::vector<std::uint32_t>& bodies, float px, float py,
                           float radius, float* dist, bool* cut = nullptr);

// Logs `message` once per `key` until reset_warnings (the renderer calls it when the scene changes). A fixed key (the default)
// is never refused; a per-entity key (`perEntity`, one per caster or texture) shares kMaxEntityWarnings2D places, so a scene
// with thousands of bad casters cannot fill the log, and cannot push a fixed warning out either.
void warn_once(ContourCache& c, const std::string& key, const std::string& message, bool perEntity = false);
void reset_warnings(ContourCache& c);

}  // namespace fa::render
