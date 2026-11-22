// The GPU side of the impostors (M75-P1c, docs/BIG_WORLDS_LOD.md "Impostors"): the atlas files a MeshRenderer.impostor names, the one card every
// impostor is drawn as, the program (shaders/impostor.glsl) and the MeshItem a card becomes. A card is an instance of the quad in the ordinary
// mesh pipeline (an in-memory material with two vec4 of instance data), so the shadows, the prepass, the fog, the clustered lights and the dithered
// LOD cross-fade draw it as they draw any MeshRenderer.
#pragma once

#include <cstddef>
#include <cstdint>
#include <deque>
#include <memory>
#include <string>
#include <unordered_map>

#include "fa/scene/impostor.h"
#include "mesh_batch.h"
#include "render_internal.h"

namespace fa::render {

// The level the LodFades of an entity give its impostor (an integer beyond every level a MeshRenderer.lods list can have), so the dithered
// cross-fade between its last level and its impostor is the one between two levels.
inline constexpr int kImpostorLevel = 1000;

// The sort key of the cards (renderer_impostor.cpp): above any key the scene's items get, below a terrain node's (kTerrainSortKey), and one key per
// atlas (+ its number in the camera), so the cards of one atlas are neighbours and share a draw. Keyed like that they keep the fast sort path.
inline constexpr std::uint64_t kImpostorSortKey = ~std::uint64_t(0) - (std::uint64_t(1) << 32);

// What the cards of one atlas, seen by one camera, share: the block of the material (four vec4, shaders/impostor.glsl) and its two textures. Kept by
// the DrawContext of the job (a deque: the items hold its address).
struct ImpostorDraw {
    float params[4][4]{};
    TextureAsset* textures[2]{};  // the albedo atlas and the normal atlas
    std::size_t hash = 0;         // of everything above: items of two draws never share a batch
    std::uint32_t ordinal = 0;    // the number of the draw in its camera (the low bits of the sort key)
};

// A usable atlas (ImpostorRenderer::resolve): valid for the frame that asked.
struct ImpostorUse {
    const ImpostorAtlas* atlas = nullptr;
    TextureAsset* albedo = nullptr;
    TextureAsset* normal = nullptr;
    const void* id = nullptr;  // one value per atlas file
};

// The camera a card faces: the card is the square of the camera's right and up axes.
struct ImpostorCamera {
    Vec3 position, right, up;
    bool linear = false;  // the scene is linear (the colour space of the textures)
};

class ImpostorDraws {
public:
    // The draw of `use` for this camera (made on the first ask of the frame).
    const ImpostorDraw* draw(const ImpostorUse& use, const ImpostorCamera& cam);
    std::size_t size() const { return draws_.size(); }

private:
    std::deque<ImpostorDraw> draws_;
    std::unordered_map<const void*, std::size_t> index_;
};

class ImpostorRenderer {
public:
    ImpostorRenderer() = default;
    ImpostorRenderer(const ImpostorRenderer&) = delete;
    ImpostorRenderer& operator=(const ImpostorRenderer&) = delete;
    ~ImpostorRenderer() { destroy(); }

    // The atlas `mr.impostor` names, ready to draw this frame (`serial` = Renderer::Impl::frameSerial). False, with ONE warning per file
    // that names the entity and says how to fix it, when the file is missing or invalid, a picture is missing or is not the size the file says, or
    // this GPU cannot build the program: the caller keeps drawing the last level. A file that failed is read again after 64 frames and
    // whenever it is reloaded.
    bool resolve(Assets& assets, std::uint64_t serial, const MeshRenderer& mr, Entity entity, ImpostorUse& out);

    // Turns `item` (the entity's MeshItem as the scene gathered it) into its card: the quad, the impostor material, the world box of the card
    // and its instance data (the centre and radius in the world, the rotation world -> model). `use` came from resolve() this frame.
    void make_item(MeshItem& item, ImpostorDraws& draws, const ImpostorUse& use, const ImpostorCamera& cam);

    // Frees every GPU resource (the context is going away or the world was replaced).
    void destroy();
    std::size_t size() const { return entries_.size(); }
    // The program was built on this GPU (false before the first impostor is drawn).
    bool program_ok() const { return matState_ > 0; }

private:
    struct Entry {
        ImpostorAtlas atlas;
        bool ok = false;                              // the file parsed and both pictures are usable
        bool loaded = false;                          // the file was read (ok or not)
        std::uint64_t reloadSeen = 0;                 // Assets::reload_generation() the file was read at
        std::uint64_t triedAt = 0;                    // the frame serial of the last read
        std::uint64_t texSerial = ~std::uint64_t(0);  // the frame the textures were fetched in
        TextureAsset* albedo = nullptr;
        TextureAsset* normal = nullptr;
        std::string note;  // the last problem said (said once)
    };
    MeshAsset* quad();
    MaterialAsset* material();

    std::unordered_map<std::string, std::unique_ptr<Entry>> entries_;  // by normalised path
    std::unique_ptr<MeshAsset> quad_;
    std::unique_ptr<MaterialAsset> material_;
    sg_shader shaders_[3]{};  // impostor, shadow, prepass
    int matState_ = 0;        // 0 = not tried, 1 = built, -1 = failed (said once)
};

}  // namespace fa::render
