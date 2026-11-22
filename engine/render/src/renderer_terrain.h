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

// What every node of one terrain, seen by one camera, shares: the block of the material (the eight vec4 of shaders/terrain.glsl), its
// textures and the MeshRenderer the items point at (the shading values of layer 0). Kept by the DrawContext of the job (a deque: the
// items hold its address).
struct TerrainDraw {
    MeshRenderer mr;
    float params[8][4]{};
    TextureAsset*
        textures[3]{};     // the heights, the albedo of layer 0 (white without one), its normal map (white without one)
    std::size_t hash = 0;  // of everything above: items of two draws never share a batch
};

// The values of a Terrain the renderer reads from `Terrain.layers[0]` (the other layers are drawn by the layered material, P5d).
struct TerrainLayer0 {
    std::string albedo, normal;
    float tileSize = 4.0f, roughness = 0.9f, metallic = 0.0f, normalScale = 1.0f;
};
TerrainLayer0 terrain_layer0(const Terrain3D& t);

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
    };
    // Appends the nodes of every Terrain the camera draws to `out` (one MeshItem per node, opaque) and keeps their TerrainDraw in
    // `draws`. Brings the GPU copy of each terrain's heights up to date first (the whole texture when its version changed). Returns the
    // number of terrains drawn.
    int gather(const View& view, std::deque<TerrainDraw>& draws, std::vector<MeshItem>& out);

    // Frees every GPU resource (the context is going away or the world was replaced).
    void destroy();
    // GPU memory of the height textures.
    std::size_t bytes() const;
    std::size_t size() const { return entries_.size(); }
    // The renderer could build the terrain program on this GPU (false before the first terrain is drawn).
    bool program_ok() const { return matState_ > 0; }
    // Height texture uploads (whole textures) made since the renderer was made: a test looks at it.
    std::uint64_t uploads() const { return uploads_; }

private:
    struct Entry {
        std::shared_ptr<fa::TerrainHeights> heights;
        std::uint64_t seenVersion = 0;
        TextureAsset tex;  // RG8 heights (r = high byte, g = low byte)
        TerrainTileBounds bounds;
        std::uint64_t seen = 0;
        std::string albedoPath, normalPath;
        TextureAsset* albedo = nullptr;
        TextureAsset* normal = nullptr;
        bool failed = false;  // the texture could not be made: said once, nothing is drawn
        ~Entry();
    };
    Entry* prepare(const View& view, Entity e);
    bool upload(Entry& en, Entity e);
    MeshAsset* patch();
    MaterialAsset* material();

    std::unordered_map<std::uint64_t, std::unique_ptr<Entry>> entries_;  // by Entity::bits()
    std::unique_ptr<MeshAsset> patch_;
    std::unique_ptr<MaterialAsset> material_;
    sg_shader shaders_[3]{};  // terrain, shadow, prepass
    int matState_ = 0;        // 0 = not tried, 1 = built, -1 = failed (said once)
    std::uint64_t pruned_ = ~std::uint64_t(0);
    std::uint64_t uploads_ = 0;
};

}  // namespace fa::render
