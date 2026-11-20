// The CPU side of the shadows of point and spot lights (M73.2b): which lights get a shadow this frame and how big each map is (the
// budget), the perspective matrix of every tile, the faces of a point light, and the records the fragment shader reads from the light
// data texture. No GPU here: pure functions, tested by tests/local_shadows_tests.cpp, used by Renderer::Impl::shadow_bounds and
// upload_lights (renderer_draw.cpp). docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Shadows of point and spot lights".
//
// The maps live in the same 2D atlas as the cascades of the sun (shadow_cascades.h). A spot light has one tile, a perspective view
// along its axis; a point light has six, one per face of a cube, laid out as six ordinary tiles (there are no cube arrays on every
// backend). Depth convention of a perspective tile: the shadow pass stores the window depth z (0..1, the same on every backend) of the
// tile's perspective projection with near plane n and far plane f, and the shader turns it into metres along the tile's axis,
// c = n * f / (f - z * (f - n)) (the clip w of the projection IS that distance), and compares metres: the bias and the PCF slope
// are metres, and a texel is `texelCoef * distance` metres wide.
#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/core/math.h"
#include "shadow_cascades.h"

namespace fa::render {

// A spot wider than this half angle (degrees) takes the six-face path of the point light: one perspective tile cannot hold it.
inline constexpr float kMaxSpotTileAngle = 70.0f;
// The edge of a tile is a guard band of this many texels outside the region the tile is selected for, so the filter of a fragment at
// the edge of a cube face (or of the cone) reads its own tile's texels and not the clamped last row.
inline constexpr int kLocalShadowGuard = 8;
inline constexpr int kLocalShadowMinTile = 64;
inline constexpr int kLocalShadowMaxTile = 2048;
// Tiles per light: 1 (a spot) or 6 (a point light, a wide spot).
inline constexpr int kCubeFaces = 6;
// Priority of the first local light in the atlas layout (the sun's cascades are 0..3: they are shrunk and dropped last).
inline constexpr int kLocalShadowPriority = 16;

// ---------------------------------------------------------------------------
// The six faces of a cube
// ---------------------------------------------------------------------------
// Face 0..5 = +X, -X, +Y, -Y, +Z, -Z. The shader chooses the face by the major axis of the direction from the light (shaders/
// shadow_common.glsl, fa_shadow_local) with this same table.
struct CubeFace {
    Vec3 forward, up;
};
CubeFace cube_face_basis(int face);
// The face a direction (from the light to a point) falls in: the axis of its largest component, ties to the lower face.
int cube_face_of(Vec3 d);

// ---------------------------------------------------------------------------
// The budget
// ---------------------------------------------------------------------------
// A point or spot light that wants a shadow this frame.
struct LocalShadowInput {
    int light = 0;  // its index in the frame's light table
    Vec3 position{0, 0, 0};
    float range = 1.0f;
    float spotAngle = 0.0f;  // a spot's cone half angle in degrees; 0 = a point light
    float brightness = 1.0f;
    int resolution = 0;        // Light.shadowResolution: texels per tile side (0 = from the distance to the camera)
    float shadowDistance = 0;  // how far from the camera the shadow reaches; 0 = no limit (the light's range)
};

// Does this light take the six-face path?
bool local_light_is_cube(const LocalShadowInput& in);

// How relevant a light is to the camera (larger = first): its brightness times the share of its range the camera is inside of. Equal
// scores are ordered by the light's index in the table, so the order never depends on anything but the scene.
float local_shadow_importance(float brightness, float range, float distanceToCamera);

// The texels per tile side a light asks for: its resolution (rounded down to a power of two, 64..2048) or, with 0, a size that follows
// its apparent size: 1024 (512 per face of a cube) while the camera is within the light's range, halving each time the camera is twice
// as far, never under 64.
int local_shadow_wanted_tile(const LocalShadowInput& in, float distanceToCamera);

struct LocalShadowLight {
    int light = 0;      // the index in the light table
    bool cube = false;  // six faces
    int firstTile = 0;  // the index in ShadowAtlasLayout::tiles of its first tile; the faces follow
    int tiles = 1;      // 1 or 6
    int wanted = 0;     // texels per tile side asked for
    bool shrunk = false;
};

struct LocalShadowPlan {
    ShadowAtlasLayout atlas;               // the sun's tiles first (in the order given), then the tiles of `lights`
    std::vector<LocalShadowLight> lights;  // the lights that got shadow maps, most important first
    std::vector<int> lost;                 // the table index of every light that asked for one and lost it to the budget
    int shrunkLights = 0;                  // lights whose tiles are smaller than they asked for
};

// The deterministic budget of a frame. `inputs` are the lights that want a shadow; they are ranked by importance for the camera at
// `camera` (ties by table index), and each takes one or six tiles of the atlas next to `sunTiles` (the cascades). Past `maxViews`
// tiles in all (the sun's included) a light is lost. When the atlas (`atlasMax` texels per side) is full the largest maps are halved
// (layout_shadow_atlas: the least important of equally large ones first, down to 64), and when that is not enough the least important
// light loses its shadow whole: a point light never has only some of its faces. With no inputs the layout is exactly the sun's.
LocalShadowPlan plan_local_shadows(int atlasMax, const std::vector<ShadowTileRequest>& sunTiles,
                                   const std::vector<LocalShadowInput>& inputs, Vec3 camera,
                                   int maxViews = 64);

// ---------------------------------------------------------------------------
// The projection of a tile
// ---------------------------------------------------------------------------
struct LocalTileFit {
    Mat4 viewProj;               // world -> clip space of the shadow pass (the depth range of the backend)
    float nearPlane = 0.05f, farPlane = 1.0f;  // metres
    float texelCoef = 0;         // metres per texel at distance 1 along the axis
};

// A perspective tile of `tile` texels per side at `position` looking along `forward` (`up` picks the roll). `tanHalf` is the tangent
// of the half angle of the region the tile is chosen for (1 for the face of a cube; tan(spotAngle) for a spot); the tile is a little
// wider (the guard band). The far plane is `range`; the near plane follows it (range / 200, at least 5 cm).
LocalTileFit fit_local_tile(Vec3 position, Vec3 forward, Vec3 up, float tanHalf, int tile, float range, bool zeroToOne);

// The axis and roll of a spot light's tile (the same basis as the cascades use).
void spot_tile_basis(Vec3 axis, Vec3& forward, Vec3& up);

// The matrix that takes a world position (w = 1) to (u * w, v * w, -, w) of the atlas texture, w = the distance along the tile's axis in
// metres: the shader divides x and y by w for the texture coordinates and compares w (the receiver's depth) with the stored one. The
// u and v conventions are those of shadow_sample_matrix (`isGl`: the texture's v runs bottom up in a render target).
Mat4 local_sample_matrix(const LocalTileFit& fit, const ShadowTile& tile, int atlasW, int atlasH, bool isGl);

// ---------------------------------------------------------------------------
// The records in the light data texture
// ---------------------------------------------------------------------------
// The shadow region of the light data texture (shaders/light_data.glsl has the layout): one texel per light of the table that says where
// its record is, then the records. A record is 2 header texels and 6 texels per tile.
inline constexpr int kLocalShadowHeaderTexels = 2;
inline constexpr int kLocalShadowTileTexels = 6;

struct LocalShadowTileRecord {
    Mat4 sample;                         // local_sample_matrix
    Vec4 rect{0, 0, 1, 1};               // the tile's rectangle in the atlas texture, a texel smaller on every side
    float nearPlane = 0.05f, farPlane = 1.0f, texelCoef = 0;
};

struct LocalShadowRecord {
    int light = 0;       // the index in the light table
    int kind = 1;        // 1 = one tile (a spot), 2 = six faces (a point light)
    float fade = 0;      // metres from the camera past which the shadow fades out (0 = never)
    int filter = 0;      // 0 pcf, 1 hard, 2 pcss
    float softness = 0;  // tangent of the light's angular size (pcss)
    float bias = 0, normalBias = 0;  // metres, 0 = automatic
    std::vector<LocalShadowTileRecord> tiles;  // 1 or 6
};

// The texels the region takes for a table of `lights` lights and these records (0 without records).
std::size_t local_shadow_region_texels(int lights, const std::vector<LocalShadowRecord>& records);
// Writes the region at texel `base` of `texels` (RGBA32F, 4 floats a texel, zeroed, with room for the region).
void pack_local_shadow_region(int lights, const std::vector<LocalShadowRecord>& records, std::size_t base,
                              float* texels);

}  // namespace fa::render
