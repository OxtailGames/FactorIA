// The CPU side of the Foliage component's drawing (M75.6, docs/BIG_WORLDS_TERRAIN.md "Foliage"), free of any GPU call so tests can look
// at it: the instances sorted into chunks (fixed squares of the entity's local ground plane, each with its box), the stable thinning of
// `density`, the steps of the distance fade and the wind's sway.
#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/foliage.h"

namespace fa::render {

// Side of a chunk in metres, in the local space of the Foliage entity. A chunk is culled with one box test, so it must be small enough
// that a view cuts through few of them and large enough that a forest is a few hundred tests, not tens of thousands.
inline constexpr float kFoliageChunkSize = 32.0f;
// The distance fade is dithered with the screen pattern of the LOD cross-fade, whose amount is one number per draw: an instance falls in
// one of this many steps between fadeStart and fadeEnd (instances of the same step share a draw), so a Foliage with a fade costs up to
// this many draws more per mesh and LOD.
inline constexpr int kFoliageFadeSteps = 8;
// Beyond the camera's view, a chunk that casts shadows is still kept when it is within this many metres of it, so the shadow of a tree
// just off the screen is in the picture.
inline constexpr float kFoliageShadowMargin = 24.0f;

// The most MeshItems one camera takes from all the Foliage entities of a frame (a MeshItem is a few hundred bytes): the nearest chunks come
// first, the rest is left out and counted as culled. A fixed count, so what is drawn never depends on the machine.
inline constexpr std::size_t kFoliageMaxItems = 262144;

// One instance as the renderer keeps it: the file's, in the order of the chunks, with its stable thinning rank.
struct FoliagePacked {
    Vec3 position{0, 0, 0};
    float yaw = 0.0f, scale = 1.0f;
    Vec3 up{0, 1, 0};
    std::uint16_t mesh = 0;
    std::uint16_t rank = 0;  // foliage_thin_rank of the instance's index in the file
};

struct FoliageChunk {
    std::uint32_t first = 0, count = 0;  // the instances items[first .. first + count)
    Vec3 lo{0, 0, 0}, hi{0, 0, 0};       // the box of their positions (local space)
    float maxScale = 1.0f;               // the largest scale among them
};

struct FoliageChunks {
    std::vector<FoliagePacked> items;
    std::vector<FoliageChunk> chunks;  // in the order of (cell x, cell z): the same file always gives the same chunks
};

// Sorts `instances` into chunks of `size` metres. A cell of the ground plane is (floor(x / size), floor(z / size)); the instances of a cell
// keep their order in the file.
FoliageChunks build_foliage_chunks(const std::vector<FoliageInstance>& instances, float size = kFoliageChunkSize);

// A number 0..65535 for the instance at `index` of the file, spread evenly (a golden-ratio sequence): the instances whose rank is below
// foliage_keep_below(density) are drawn. It depends on the index only, so the same instances are thinned out every frame, and 0.5 keeps
// about every other one of any run of neighbours in the file.
std::uint16_t foliage_thin_rank(std::uint32_t index);
// The ranks below this are kept at `density` (0..1): 0 keeps none, 1 (or more) keeps all (65536).
std::uint32_t foliage_keep_below(float density);
// How many instances of `chunk` are kept at `density`.
std::uint32_t foliage_kept_count(const FoliageChunks& c, const FoliageChunk& chunk, float density);

// The step of the distance fade at `distance` metres: 0 = solid (up to fadeStart), 1 .. kFoliageFadeSteps = fading out, -1 = not drawn
// (fadeEnd and beyond).
int foliage_fade_step(float distance, float fadeStart, float fadeEnd);
// The `lodFade` of a MeshItem for a fade step (1..kFoliageFadeSteps): the share of the screen pattern the instance still covers, falling
// from near 1 to near 0. 0 for step 0 (no fade).
float foliage_fade_amount(int step);

// The matrix of an instance in the local space of the Foliage entity: its position, a turn of `yaw` about its up axis, the lean of that axis to
// `up` and the uniform scale.
Mat4 foliage_local_matrix(const FoliagePacked& p);

// The sway of an instance in the wind: how far (metres) the top moves along the x and z of the world, at `time` seconds, for an instance
// whose local ground position is (x, z). `strength` metres at most (the sway swings between -strength and +strength), `frequency` swings
// per second. The phase follows the position, so neighbours swing as one wave and a field is not in step.
void foliage_sway(float strength, float frequency, float time, float x, float z, float& dx, float& dz);

}  // namespace fa::render
