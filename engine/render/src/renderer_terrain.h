// The GPU side of the Terrain component (M75-P5a, docs/BIG_WORLDS.md "Terrain"): one RG8 height texture per terrain, the shared 33 x 33
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
    TextureAsset*
        textures[4]{};     // the heights, the albedo array, the normal array, the control array (splat maps and holes)
    std::size_t hash = 0;  // of everything above: items of two draws never share a batch
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
        Gpu* gpu = nullptr;        // for the sub-rectangle copies of a sculpt (null: the whole texture is made again)
        sg_pixel_format albedoFormat = SG_PIXELFORMAT_RGBA8;  // Gpu::texture_format(RGBA8): SRGB8A8 in a linear scene
    };
    // Appends the nodes of every Terrain the camera draws to `out` (one MeshItem per node, opaque) and keeps their TerrainDraw in
    // `draws`. Brings the GPU copy of each terrain's heights up to date first (the whole texture when its version changed). Returns the
    // number of terrains drawn.
    int gather(const View& view, std::deque<TerrainDraw>& draws, std::vector<MeshItem>& out);

    // Frees every GPU resource (the context is going away or the world was replaced).
    void destroy();
    // GPU memory of the height textures, the layer arrays and the control arrays.
    std::size_t bytes() const;
    std::size_t size() const { return entries_.size(); }
    // The renderer could build the terrain program on this GPU (false before the first terrain is drawn).
    bool program_ok() const { return matState_ > 0; }
    // Height texture uploads made since the renderer was made: the whole texture, and (rectUploads) a sub-rectangle of it, as a sculpt
    // changes it. A test looks at them.
    std::uint64_t uploads() const { return uploads_; }
    std::uint64_t rect_uploads() const { return rectUploads_; }
    // The layer arrays and control arrays made (a test looks at it: an unchanged terrain makes none).
    std::uint64_t layer_builds() const { return layerBuilds_; }

private:
    struct Entry {
        std::shared_ptr<fa::TerrainHeights> heights;
        std::uint64_t seenVersion = 0;
        TextureAsset tex;       // RG8 heights (r = high byte, g = low byte)
        bool copyable = false;  // `tex` was made to take copies (the first sculpt makes it so)
        sg_buffer stage{};      // the staging buffer of the sub-rectangle copies, and its size
        std::size_t stageCap = 0;
        std::uint64_t stagedFrame = 0;  // Gpu::frame() + 1 of the frame whose copy wrote it (one write a frame)
        TerrainTileBounds bounds;
        std::uint64_t seen = 0;
        // The layers (shaders/terrain.glsl): the arrays are made here from the files, never from Assets textures (a cached pointer to
        // one would dangle when Assets::clear() or a reload replaced it); what each was made from tells when to make it again.
        TextureAsset albedoArr, normalArr, controlArr;  // empty = the renderer's one-pixel arrays are bound instead
        std::uint64_t albedoKey = 0, normalKey = 0, controlKey = 0;
        std::uint64_t reloadSeen = 0;             // Assets::reload_generation() the arrays were checked against
        unsigned albedoMask = 0, normalMask = 0;  // the layers that have a picture in the arrays
        int splatMaps = 0, controlSide = 1;
        bool holesOn = false;
        sg_pixel_format albedoFormat = SG_PIXELFORMAT_RGBA8;
        std::string note;     // the last problem said about the layers (said once)
        bool failed = false;  // the texture could not be made: said once, nothing is drawn
        ~Entry();
    };
    Entry* prepare(const View& view, Entity e);
    bool upload(Entry& en, const View& view, const TerrainRect* rect);
    bool copy_rect(Entry& en, const View& view, const TerrainRect& rect);
    void update_layers(Entry& en, const View& view, Entity e, const Terrain3D& t,
                       const std::vector<TerrainLayerInfo>& layers);
    TextureAsset* dummy_array();
    MeshAsset* patch(bool split);
    MaterialAsset* material();

    std::unordered_map<std::uint64_t, std::unique_ptr<Entry>> entries_;  // by Entity::bits()
    std::unique_ptr<MeshAsset> patch_, splitPatch_;  // the shared patch and the split one (terrains with holes)
    std::unique_ptr<MaterialAsset> material_;
    TextureAsset dummy_;  // a 1 x 1 one-slice array of white: bound where a terrain has no layer pictures or no control
    sg_shader shaders_[3]{};  // terrain, shadow, prepass
    int matState_ = 0;        // 0 = not tried, 1 = built, -1 = failed (said once)
    std::uint64_t pruned_ = ~std::uint64_t(0);
    std::uint64_t uploads_ = 0, rectUploads_ = 0, layerBuilds_ = 0;
};

}  // namespace fa::render
