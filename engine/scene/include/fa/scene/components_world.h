// The components of the big worlds of M75 (docs/BIG_WORLDS.md): LOD groups, occlusion, streaming anchors, terrain and foliage.
// P0 of M75 lands the data: every field is reflected (components_world.cpp), saved, loaded and validated today, and does nothing
// until the package named in its doc string draws or simulates it. Every default leaves an existing scene as it was (none of
// these components exists in one). Included by components.h.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/typed_array.h"
#include "fa/core/types.h"

namespace fa {

class TypeRegistry;

// What the LOD thresholds of a MeshRenderer or a LodGroup measure (MeshRenderer.lodMode, LodGroup.mode).
//   distance: metres between the camera and the entity's origin (the behaviour of every scene made before M75).
//   screenSize: the fraction of the screen's height that the bounding sphere of the mesh covers, 0..1 (1 = it fills the
//   screen, 0.1 = a tenth of it): independent of the field of view and of the object's size.
enum class LodMode : std::int32_t { Distance, ScreenSize };

inline constexpr std::int32_t kMaxLodThresholds = 8;      // LodGroup.thresholds: at most this many (so 9 levels)
inline constexpr std::int32_t kMaxTerrainLayers = 8;      // Terrain.layers: at most this many (two RGBA splat maps)
inline constexpr std::int32_t kMaxTerrainSplatMaps = 2;   // Terrain.splatMaps: 4 layers each
inline constexpr std::int32_t kMaxScatterMeshes = 16;     // ScatterRule.meshes: at most this many entries
inline constexpr float kMaxTerrainSize = 100000.0f;       // metres of Terrain.size along one axis (100 km)

// One thing wrong (or useless) in the data of one of these components: `pointer` is relative to the component ("/thresholds/1"), the
// convention of ParticleProblem. The scene loader reports errors and warnings with file and pointer.
struct WorldProblem {
    bool error = true;  // false = a warning: the component still loads, a setting just does nothing
    std::string pointer;
    std::string message;
    std::string hint;
};

// The levels of detail of an entity whose CHILDREN are the levels (child 0 the most detailed, child i drawn from threshold i - 1
// on), or an HLOD proxy that stands for the whole subtree (a cell of a streamed world) from far away. M75.1.
struct LodGroup {
    LodMode mode = LodMode::Distance;
    ArrayF32 thresholds;  // one number per child but the first: where child i + 1 replaces child i (unit: see `mode`)
    float crossFade = 0.0f;       // seconds a switch fades over; 0 = hard switch
    std::string hlodProxy;        // mesh path: the one mesh that replaces every child beyond hlodThreshold ("" = none)
    float hlodThreshold = 0.0f;   // where the proxy takes over (unit: see `mode`); needed when hlodProxy is set
};

// How the visibility of the entity's own mesh is used as an occluder: a box or the mesh itself. M75.2.
enum class OccluderShape : std::int32_t { Box, Mesh };
struct Occluder {
    OccluderShape shape = OccluderShape::Box;
    Vec3 size{1.0f, 1.0f, 1.0f};     // box: metres along the entity's local axes, before Transform.scale
    Vec3 center{0.0f, 0.0f, 0.0f};   // box: where the box's centre is, from the entity's origin
    std::string mesh;                // mesh: the mesh that is rasterised ("" = the entity's MeshRenderer.mesh)
    bool enabled = true;
};

// A region of an interior (a room) that portals connect: meshes inside it are drawn only when a chain of open portals leads from
// the camera's area to it. M75.2.
struct OcclusionArea {
    Vec3 size{10.0f, 4.0f, 10.0f};   // metres along the entity's local axes, before Transform.scale
    std::int32_t areaId = 1;         // 1..65535: the id OcclusionPortal.areaA and areaB name; 0 is "outside every area"
};

// An opening between two areas: a door, a window. M75.2.
struct OcclusionPortal {
    Vec3 size{2.0f, 2.0f, 0.2f};     // metres: width, height and depth of the opening's box, before Transform.scale
    std::int32_t areaA = 0;          // the OcclusionArea.areaId on the entity's -Z side (0 = outside)
    std::int32_t areaB = 0;          // the OcclusionArea.areaId on its +Z side (0 = outside)
    bool open = true;                // false: the portal is closed (a shut door) and light-of-sight through it is blocked
};

// Loads and unloads the cells of a streamed world around this entity. M75.3.
struct StreamingAnchor {
    float loadRadius = 256.0f;       // metres: cells whose bounds are nearer than this are loaded
    float unloadRadius = 320.0f;     // metres: loaded cells whose bounds are farther than this are unloaded; above loadRadius
    std::int32_t priority = 0;       // anchors with a higher priority get their cells loaded first
    bool enabled = true;
};

// A world cut into cells that load and unload around the StreamingAnchor entities (the index file lists the cells). Put it on ONE
// entity of the scene (the streamer uses the first enabled one). M75.3.
struct StreamedWorld {
    std::string world;                      // the index: a project-relative *.world.json
    bool enabled = true;                    // false: no cell is loaded and the loaded ones are unloaded
    std::int32_t maxLoadsInFlight = 2;      // cells being read at once (each is a BackgroundLoader job)
    std::int32_t maxAppliesPerFrame = 1;    // cells added to (or removed from) the world per frame, on the main thread
    bool keepLoaded = false;                // debug: every cell stays loaded, whatever the anchors say
    float cameraLoadRadius = 0.0f;          // metres; above 0 the active camera is an anchor with this load radius (0 = it is not)
    float cameraUnloadRadius = 0.0f;        // metres; 0 = 1.25 times cameraLoadRadius
};

// The visual and collision terrain: a heightmap drawn with GPU LOD and splat-mapped material layers. M75.5. The component is
// called "Terrain" in scenes and scripts; the C++ type is Terrain3D because fa::Terrain is the autotile terrain of fa/scene/autotile.h.
struct Terrain3D {
    std::string heightmap;       // 16-bit greyscale PNG or .r16 file; "" = flat at heightOffset
    Vec2 size{512.0f, 512.0f};   // metres [x, z] the heightmap covers, centred on the entity (as Heightfield3D)
    float heightScale = 100.0f;  // metres of height of a white (65535) sample
    float heightOffset = 0.0f;   // metres added after the scale
    Json splatMaps = Json::array();  // RGBA PNG paths, 4 layers each: channel c of map m weights layers[4 * m + c]
    Json layers = Json::array();     // [{"albedo", "normal", "tileSize", "roughness", "metallic", "normalScale"}], at most 8
    std::string holes;           // greyscale PNG that cuts holes where its pixel is 128 or more ("" = none)
    float lodQuality = 1.0f;     // multiplier of the mesh density and of the distances at which the terrain coarsens
    bool castShadows = true;
    bool collision = true;       // an automatic Heightfield3D collider on this entity (static, holes included)
};

// GPU-instanced vegetation or rocks: many copies of one mesh read from a data file. M75.6.
struct Foliage {
    std::string mesh = "cube";  // the mesh drawn at every instance: a primitive name or an asset path (as MeshRenderer.mesh)
    std::string instances;      // data file with the instances (written by foliage.paint and foliage.scatter); "" = none
    float density = 1.0f;       // 0..1: the share of the instances that are drawn (the rest are thinned out evenly)
    float windStrength = 0.0f;  // metres the top of an instance sways; 0 = no wind
    float windFrequency = 0.5f; // swings per second
    float lodDistance = 40.0f;  // metres beyond which an instance uses the next LOD of its mesh
    float fadeStart = 80.0f;    // metres where instances start to fade out
    float fadeEnd = 100.0f;     // metres beyond which instances are not drawn; above fadeStart
    bool castShadows = false;
};

// The rule that foliage.scatter fills a Foliage's instances file from: where, how dense and which meshes. M75.6.
struct ScatterRule {
    Json meshes = Json::array();     // [{"mesh": path, "weight": number}], at most 16: the chances of each mesh
    float density = 0.1f;            // instances per square metre of ground
    float minSpacing = 0.0f;         // metres kept between two instances; 0 = none
    Vec2 slopeRange{0.0f, 45.0f};    // degrees [min, max] of the ground's slope where instances grow
    Vec2 heightRange{-100000.0f, 100000.0f};  // metres [min, max] of the ground's height where instances grow
    Vec2 scaleRange{0.8f, 1.2f};     // the random scale [min, max] of an instance
    float alignToNormal = 0.0f;      // 0..1: how far an instance leans to the ground's normal (0 = upright, 1 = along it)
    std::int32_t layerMask = -1;     // bit mask of the Terrain.layers the ground must be painted with (-1 = any)
    std::int32_t seed = 1;           // the same rule and seed always scatter the same instances
    Entity terrain = kNullEntity;    // the entity with the Terrain to scatter on; empty = this entity's or its parent's
};

// The problems of each component's data (contradictions between fields, wrong shapes inside the Json arrays); a number out of its
// range is already refused by reflection. Used by the scene loader.
std::vector<WorldProblem> lod_group_problems(const LodGroup& g);
// The `lods` and impostor fields of a MeshRenderer that depend on lodMode (the lodMode default keeps the old behaviour: nothing is
// checked for distance).
std::vector<WorldProblem> mesh_lod_problems(const std::string& mesh, const Json& lods, LodMode mode, float impostorAt,
                                            const std::string& impostor);
std::vector<WorldProblem> occluder_problems(const Occluder& o, bool hasMeshRenderer);
std::vector<WorldProblem> occlusion_area_problems(const OcclusionArea& a);
std::vector<WorldProblem> occlusion_portal_problems(const OcclusionPortal& p);
std::vector<WorldProblem> streaming_anchor_problems(const StreamingAnchor& a);
std::vector<WorldProblem> streamed_world_problems(const StreamedWorld& w);
std::vector<WorldProblem> terrain_problems(const Terrain3D& t);
std::vector<WorldProblem> foliage_problems(const Foliage& f);
std::vector<WorldProblem> scatter_rule_problems(const ScatterRule& r);

// Registers the components above (components.cpp calls it).
void register_world_components(TypeRegistry& registry);

}  // namespace fa
