// The GPU side of the Terrain component (M75-P5a, docs/BIG_WORLDS_TERRAIN.md "Terrain"): one RG8 height texture per terrain, the shared 33 x 33
// patch every node is drawn with, the program (shaders/terrain.glsl) and, per camera, the CDLOD selection (terrain_lod.h) turned into
// MeshItems. A node is an instance of the patch in the ordinary mesh pipeline (an in-memory material with two vec4 of instance data), so
// the shadows, the prepass, the SSAO, the fog and the clustered lights draw the terrain as they draw any MeshRenderer.
#pragma once

#include <cstdint>
#include <deque>
#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "fa/core/jobs.h"
#include "fa/scene/terrain.h"
#include "mesh_batch.h"
#include "render_internal.h"
#include "terrain_lod.h"

namespace fa {
class World;
}

namespace fa::render {

// What every node of one terrain, seen by one camera, shares: the block of the material (the sixteen vec4 of shaders/terrain.glsl), its
// textures and the MeshRenderer the items point at (the grey a layer without an albedo texture keeps, and the shading values of a
// terrain without layers). Kept by the DrawContext of the job (a deque: the items hold its address).
struct TerrainDraw {
    MeshRenderer mr;
    float params[16][4]{};
    TextureAsset* textures[4]{};  // the heights, the albedo array, the normal array, the control array (the splat maps)
    TextureAsset* holes =
        nullptr;  // the R8 holes texture (a 1 x 1 one when there are none): the VERTEX stage's copy of the control slot
    std::size_t hash = 0;  // of everything above: items of two draws never share a batch
};

// What the job that decodes the pictures of one kind of layer texture (albedo or normal) leaves for the render thread: the mip chain of
// the whole array, packed, so the thread that owns the GPU only makes the image (renderer_terrain.cpp, update_layers).
struct TerrainLayerBuild {
    bool ran = false;                   // the job ran to its end (false: it was skipped, e.g. at shutdown)
    std::string error, hint;            // load_terrain_layer_images refused: no array is made
    std::vector<std::string> problems;  // files that could not be read (those layers stay neutral)
    int present = 0, width = 0, height = 0, slices = 0;
    unsigned mask = 0;                              // the layers that have a picture
    std::vector<std::vector<std::uint8_t>> levels;  // per mip level, every slice one after the other
};

// The values of one entry of `Terrain.layers` the renderer reads (defaults where a key is missing or not a number; clamped).
struct TerrainLayerInfo {
    std::string albedo, normal;
    float tileSize = 4.0f, roughness = 0.9f, metallic = 0.0f, normalScale = 1.0f;
};
// The first kMaxTerrainLayers entries of `Terrain.layers`.
std::vector<TerrainLayerInfo> terrain_layers(const Terrain3D& t);

class TerrainRenderer {
public:
    TerrainRenderer() = default;
    TerrainRenderer(const TerrainRenderer&) = delete;
    TerrainRenderer& operator=(const TerrainRenderer&) = delete;
    ~TerrainRenderer() { destroy(); }

    // What gather() needs of one camera of one frame.
    struct View {
        World* world = nullptr;
        Entity scopeRoot;
        std::function<bool(Entity)> drawn;  // Camera.showTags / hideTags (null = every entity)
        Assets* assets = nullptr;
        Mat4 viewProj;
        bool z01 = false;
        Vec3 camera;
        bool linear = false;       // the scene is linear (the colour space of the textures)
        std::uint64_t serial = 0;  // Renderer::Impl::frameSerial
        Gpu* gpu =
            nullptr;  // the renderer's Gpu: its device makes the textures, its list takes the sub-rectangle copies of a sculpt (required)
        gpu::PixelFormat albedoFormat =
            gpu::PixelFormat::Rgba8;  // Gpu::texture_format(RGBA8): SRGB8A8 in a linear scene
        float lodQuality =
            1.0f;  // the graphics preset's factor on Terrain.lodQuality (QualityLimits.terrainLodQuality)
    };
    // Appends the nodes of every Terrain the camera draws to `out` (one MeshItem per node, opaque) and keeps their TerrainDraw in
    // `draws`. Brings the GPU copy of each terrain's heights up to date first (the whole texture when its version changed). Returns the
    // number of terrains drawn.
    int gather(const View& view, std::deque<TerrainDraw>& draws, std::vector<MeshItem>& out);

    // Frees every GPU resource (the context is going away or the world was replaced).
    void destroy();
    // A layer texture file is being read, decoded or packed off the render thread (a terrain draws its layers neutral, or with the
    // pictures it had, until the next gather after it finishes adopts them). A test or a capture that needs the pictures waits, then
    // renders once more.
    bool loading() const;
    void wait_loaded();
    // Layer decoding jobs started since the renderer was made (a test looks at it: an unchanged terrain starts none).
    std::uint64_t layer_loads() const { return layerLoads_; }
    // The sub-rectangles of the splat maps the GPU took as copies (a repaint sends only what it painted).
    std::uint64_t splat_rect_uploads() const { return splatRects_; }
    // GPU memory of the height textures, the layer arrays and the control arrays.
    std::size_t bytes() const;
    std::size_t size() const { return entries_.size(); }
    // The renderer could build the terrain program on this GPU (false before the first terrain is drawn).
    bool program_ok() const { return matState_ > 0; }
    // The program of the thin G-buffer (M79-P0c, MaterialProgramId kProgGbuffer): made the first time a frame draws the G-buffer, never before, so
    // a game that asks for none pays for no shader. False (said once) when the material is not built or the GPU rejects the program: the
    // G-buffer then leaves the terrains out and their pixels keep the constants.
    bool ensure_gbuffer(gpu::Device& device);
    // Why the G-buffer program is missing (the shader that did not compile, said for the status): empty while it is built or never needed.
    const std::string& gbuffer_failure() const { return gbufferWhy_; }
    // Height texture uploads made since the renderer was made: the whole texture, and (rectUploads) a sub-rectangle of it, as a sculpt
    // changes it. A test looks at them.
    std::uint64_t uploads() const { return uploads_; }
    std::uint64_t rect_uploads() const { return rectUploads_; }
    // The same for the holes texture: made whole (the first stroke of a mask counts, it makes the texture take copies) and cells sent as a
    // rectangle.
    std::uint64_t holes_uploads() const { return holesUploads_; }
    std::uint64_t holes_rect_uploads() const { return holesRects_; }
    // The layer arrays and control arrays made (a test looks at it: an unchanged terrain makes none).
    std::uint64_t layer_builds() const { return layerBuilds_; }

private:
    struct Entry {
        std::shared_ptr<fa::TerrainHeights> heights;
        std::uint64_t seenVersion = 0;
        TextureAsset tex;       // RG8 heights (r = high byte, g = low byte)
        bool copyable = false;  // `tex` was made to take copies (the first sculpt makes it so)
        gpu::Buffer stage{};    // the staging buffer of the sub-rectangle copies, and its size
        std::size_t stageCap = 0;
        std::uint64_t stagedFrame = 0;  // Gpu::frame() + 1 of the frame whose copy wrote it (one write a frame)
        TerrainTileBounds bounds;
        std::uint64_t seen = 0;
        // The layers (shaders/terrain.glsl): the arrays are made here from the files, never from Assets textures (a cached pointer to
        // one would dangle when Assets::clear() or a reload replaced it); what each was made from tells when to make it again.
        // The albedo and normal arrays are decoded by a job (a LayerJob each) and adopted here when it is done; the old array stays bound
        // meanwhile when the same layers were reloaded, and the neutral one when they changed.
        TextureAsset albedoArr, normalArr;           // empty = the renderer's one-pixel arrays are bound instead
        std::uint64_t albedoKey = 0, normalKey = 0;  // what the arrays were made from (0 = nothing yet)
        std::uint64_t reloadSeen = 0;                // Assets::reload_generation() the arrays were checked against
        std::uint64_t heightsReloadSeen = 0;         // the same, for the heightmap file
        unsigned albedoMask = 0, normalMask = 0;     // the layers that have a picture in the arrays
        struct LayerJob {
            std::shared_ptr<TerrainLayerBuild> build;
            jobs::Handle handle;
            std::uint64_t key = 0;  // the key the job decodes for
            bool stale = false;     // a file was reloaded while it ran: its result is dropped and another job starts
        };
        LayerJob layerJob[2];                   // albedo, normal
        bool layerPending[2] = {false, false};  // a reload was seen: decode again even if the key is the same
        // The control array: the splat maps only, one slice each (RGBA8, `controlSide` pixels a side). The first repaint makes it one that
        // takes copies; the later ones send only the rectangle that changed.
        TextureAsset controlArr;
        std::uint64_t controlKey =
            0;  // what its shape was made from: the maps, their sizes and serials, the heights object
        std::uint64_t splatSeen[kTerrainSplatMaps] = {0, 0};  // the version of each splat map the array holds
        bool controlCopyable = false;
        gpu::Buffer controlStage{};
        std::size_t controlStageCap = 0;
        std::uint64_t controlStagedFrame = 0;
        int splatMaps = 0, controlSide = 1;
        // The holes: an R8 texture of one pixel per cell (255 = hole), read by the vertex stage only.
        TextureAsset holesTex;
        std::uint64_t holesKey =
            ~std::uint64_t(0);        // what the texture's shape was made from: the heights object, holes or none
        std::uint64_t holesSeen = 0;  // the holesVersion the texture holds
        bool holesOn = false;
        bool holesCopyable = false;  // holesTex was made to take copies (the first holes stroke makes it so)
        gpu::Buffer holesStage{};
        std::size_t holesStageCap = 0;
        std::uint64_t holesStagedFrame = 0;
        gpu::PixelFormat albedoFormat = gpu::PixelFormat::Rgba8;
        std::string layerNote[2], controlNote, holesNote;  // the last problem of each part (said once, with the others)
        std::string note;                                  // the last problem said about the layers (said once)
        bool failed = false;                               // the texture could not be made: said once, nothing is drawn
        gpu::Device* device =
            nullptr;  // the device its textures and buffers were made on (the destructor frees them there)
        ~Entry();
    };
    Entry* prepare(const View& view, Entity e);
    bool upload(Entry& en, const View& view, const TerrainRect* rect);
    bool copy_rect(Entry& en, const View& view, const TerrainRect& rect);
    bool copy_holes(Entry& en, const View& view, const TerrainRect& cells);
    void update_layers(Entry& en, const View& view, Entity e, const Terrain3D& t,
                       const std::vector<TerrainLayerInfo>& layers);
    void update_pictures(Entry& en, const View& view, const Terrain3D& t, const std::vector<TerrainLayerInfo>& layers,
                         bool reloaded, Entity e);
    void update_control(Entry& en, const View& view, const std::vector<TerrainLayerInfo>& layers, Entity e);
    bool copy_splat(Entry& en, const View& view, int maps, int side);
    TextureAsset* dummy_array(gpu::Device& device);
    TextureAsset* dummy_holes(gpu::Device& device, TextureAsset* fallback);
    MeshAsset* patch(gpu::Device& device, bool split);
    MaterialAsset* material(gpu::Device& device);

    std::unordered_map<std::uint64_t, std::unique_ptr<Entry>> entries_;  // by Entity::bits()
    std::unique_ptr<MeshAsset> patch_, splitPatch_;  // the shared patch and the split one (terrains with holes)
    std::unique_ptr<MaterialAsset> material_;
    TextureAsset dummy_;  // a 1 x 1 one-slice array of white: bound where a terrain has no layer pictures or no control
    TextureAsset dummyHoles_;   // a 1 x 1 R8 texture of 0: the holes texture of a terrain without holes
    gpu::Shader shaders_[4]{};  // terrain, shadow, prepass, gbuffer (made by ensure_gbuffer)
    gpu::Device* device_ =
        nullptr;  // the device of the last gather(): what the textures, patches and programs were made on
    bool gbufferFailed_ = false;  // the G-buffer program was rejected (said once)
    std::string gbufferWhy_;      // what the status says when the G-buffer program was rejected (empty otherwise)
    int matState_ = 0;            // 0 = not tried, 1 = built, -1 = failed (said once)
    std::uint64_t pruned_ = ~std::uint64_t(0);
    std::unordered_map<std::uint64_t, std::uint64_t>
        failedSeen_;                                   // entity -> reload generation of a heightmap that did not read
    std::uint64_t holesUploads_ = 0, holesRects_ = 0;  // holes texture made whole / cells sent as a rectangle
    std::uint64_t uploads_ = 0, rectUploads_ = 0, layerBuilds_ = 0, layerLoads_ = 0, splatRects_ = 0;
};

}  // namespace fa::render
