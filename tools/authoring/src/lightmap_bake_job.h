// The lightmap bake of the editor, the CLI and MCP (M73.4c): what the `lightmap.bake*` commands do, without the command plumbing.
//
//   make_plan   (main thread)  reads the World: the MeshRenderers that are lit or that shadow, the lights, the sky, the settings. It makes
//                              plain data, so the bake never touches the World again and a scene change cannot reach it.
//   execute     (any thread)   loads the geometry (and the unwrap) of each mesh, gives each lit entity a square of a page, builds the BakeScene,
//                              runs bake_lightmap (fa/scene/lightmap_bake.h) and writes the .hdr pages and the manifest. It checks the cancel
//                              flag of its thread (CommandCancelScope) in every phase and reports its progress through `report`.
//
// docs/design/ARCHITECTURE_BAKING.md, "The lightmap.bake commands", has the rules (what is mapped, the page layout, the file names).
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/light_probes.h"
#include "fa/scene/lightmap_bake.h"

namespace fa {
class World;

namespace lightmap_job {

// Which light the bake gives the surfaces from outside the scene.
enum class SkyChoice { Auto, Environment, Gradient, Ambient, None };

// What traces the texels: the CPU baker (bit-exact, the reference), the GPU (a fast preview: rays on the graphics card, fa/render/lightmap_gpu_bake.h),
// or Auto (the GPU when this machine has one that traces rays, else the CPU, with a note saying why).
enum class DeviceChoice { Cpu, Gpu, Auto };

// What the caller asks for (the arguments of the commands, checked).
struct Options {
    double texelsPerMeter = 16;  // the scene's density; MeshRenderer.lightmapScale multiplies it
    int maxPageSize = 2048;      // the largest side of a page, 16..8192
    SkyChoice sky = SkyChoice::Auto;
    DeviceChoice device = DeviceChoice::Cpu;
    BakeSettings settings;  // maxAtlasSize follows maxPageSize
};

// A mesh of the scene as the bake sees it.
struct PlanMesh {
    std::string id;    // EntityInfo.id
    std::string mesh;  // MeshRenderer.mesh
    Mat4 world;
    Vec3 albedo{0.8f, 0.8f, 0.8f};
    Vec3 emissive{};
    bool castsShadow = true;
    bool receiver = false;  // gets a square of a page
    double texelsPerMeter = 0;
};

struct Plan {
    Options options;
    std::string scene;        // Engine::Impl::currentScene when the plan was made: a result applies to this scene only
    std::string manifestAbs;  // where the manifest is written (absolute, UTF-8)
    std::string
        manifestProject;  // the same as the project spells it ("scenes/main.lightmap.json"): what SceneSettings.lightmaps holds
    std::vector<PlanMesh> meshes;  // sorted by id
    std::vector<BakeLight> lights;
    ProbeSet
        probes;  // the LightProbeGroups of the scene as positions (no light yet): baked as the phase "probes" of the same job
    BakeSky sky;                    // gradient / constant sky; also the fallback
    std::string environmentMap;     // SkyChoice::Environment: the .hdr to load (the job does)
    float environmentScale = 1;     // its multiplier (SceneSettings.environmentIntensity)
    float environmentRotation = 0;  // the baker's rotationDeg (already offset, see lightmap_bake_job.cpp)
    std::string settingsHash;       // of everything that changes the result: settings, lights, sky, meshes
    std::vector<std::string> warnings;
    int lightCount() const { return int(lights.size()); }
};

// Reads the world. Errors say what to change: no lit mesh, a bad number, a scene that has nothing to bake. `scene` is the current scene's path.
Result<Plan> make_plan(World& world, const std::string& scene, const Options& options, const std::string& manifestAbs,
                       const std::string& manifestProject);

// Called on the baking thread: the phase ("geometry", "layout", "rasterize", "trace", "denoise", "dilate", "probes", "writing"), the progress of the whole
// bake 0..1, and the rays traced so far.
using ReportFn = std::function<void(const std::string& phase, double progress, std::uint64_t rays)>;

// Runs the bake and writes the files. The result: {manifest, pages: [{file, width, height, bakedTexels}], entities, texels, rays, triangles,
// settingsHash, device: {requested, used, name, note}, skipped: [{id, reason}], warnings}. A cancelled bake returns the error "cancelled" and has written nothing (the cancel is
// not looked at once the files are being written: a half-written set is worse than a finished bake).
Result<Json> execute(const Plan& plan, const ReportFn& report);

// The sky of a Plan as it would be baked, for the tests: the equirect rotation the baker needs for SceneSettings.environmentRotation.
float baker_rotation_for_environment(float environmentRotationDegrees);

}  // namespace lightmap_job
}  // namespace fa
