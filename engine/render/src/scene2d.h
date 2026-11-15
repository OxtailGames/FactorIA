// Scene2D: the camera-independent part of the 2D gather, done once per rendered frame and shared by every camera, render target
// and CameraView of that frame (docs/design/ARCHITECTURE.md, the render core; M95.2).
#pragma once

#include <cstdint>
#include <vector>

#include "frame.h"

namespace fa::render {

// What the 2D gather (gather_2d, gather_particles, apply_sprite_frames) does for one entity, and what of it depends on the camera:
//
//   Per entity, the same for every camera of the frame (done once, then kept in Scene2D):
//     - the component reads and the visibility tests that look only at the world: active in the hierarchy, colour alpha, the
//       inherited Tint (a walk up the parents), the inherited flash;
//     - the drawn matrix (game feel pose included), the sprite frame (apply_sprite_frames: Sprite.region of every
//       SpriteAnimator, idempotent: it writes what the animator's `frame` says and never moves time, so once per frame is
//       the same as once per camera), the animator's pivot, the nine-slice borders, the mesh / skin cells, flips and skew;
//     - the vertices: every Sprite and Shape2D in world space, and the Particle emitters that do not face the camera, in
//       world coordinates, with their uv, colour, mode and light frame; the item's layer, texture, sampler, blend and flags;
//     - the sort key: `layer` and, for an orthographic camera, the y of a Sprite (y sorting). Only a perspective camera's
//       key, the distance of the item to the camera, depends on the camera, and it is a function of the item's position
//       (Slot::pos): it is written into each camera's copy.
//
//   Per camera (done for every camera, target and view):
//     - which entities the camera draws: Camera.showTags / hideTags (CameraMask), world or screen space;
//     - the Parallax shift (update_parallax moves every Parallax layer for THIS camera, and the world keeps the first camera's
//       at the end of the frame), so an entity with a Parallax component is built again for each camera, and so is its
//       repeat (the copies the camera's rectangle shows);
//     - the 2D lights in view and their shadow rows (gather_lights), the frame's own ambient light;
//     - a Tilemap: only the cells inside the camera's rectangle are emitted (a map of a million cells shows a few
//       thousand), so its quads are the camera's; Text: the glyph raster size follows the camera's pixelsPerUnit and the
//       render scale, the anchor is snapped to the camera's pixel grid and a lit Text is facing the camera (the shaped
//       layouts themselves are cached by Fonts, keyed by raster size, so cameras with the same zoom share them);
//     - an item that shows a render target's texture ("target:<name>"): the target's own camera sees the checker instead;
//     - screen space (anchor, safe area, scroll clip, UI scale): gathered once per frame, by the frame that wants the screen;
//     - Particle emitters that billboard (is3D: the camera's right and up vectors) and the debug draw (pixel size).
//
// Scene2D holds, for each Sprite and Shape2D, the items it built the first time a camera drew it: where they are (the quad list
// of that camera's Frame, a `donor`, and the range of items) and where the entity is. The next camera that draws the entity
// appends a copy of those items to its own list (QuadList::append_items) instead of building them again, with its own sort key.
// A camera that has nothing to copy builds as before, straight into its Frame. A Scene2D lives for one gather round of one
// frame: its donors are Frame lists and must stay in place until the last gather of the round (renderer.cpp reserves the
// vectors of Frames that it fills).
// apply_sprite_frames runs once per frame before the first gather, so a SpriteAnimator whose texture is its own camera's render
// target now uses the target's real size (before: the checker's), and its region at the end of the frame is the real one.
class Scene2D {
public:
    // What was built and what was copied, summed over every gather of this Scene2D (the tests check that building happens once
    // per frame, whatever the number of cameras).
    struct Work {
        int spritesBuilt = 0, spritesCopied = 0;
        int shapesBuilt = 0, shapesCopied = 0;
        int emittersBuilt = 0, emittersCopied = 0;
    };

    // gather_2d for the camera of `f`: the lists f.world and f.screen. apply_sprite_frames is not part of it: it is idempotent and
    // the caller runs it once per frame, before the first gather.
    void gather(World& world, Frame& f);
    // gather_particles for the camera of `f`.
    void gather_particles(World& world, Frame& f);

    // The caller knows that this Scene2D gathers for one destination only (one frame, no target, no view): nothing is shared, so
    // no slot is kept (the tables cost ~40 B per entity index, and every frame). The lists are the same. Call before the first gather.
    void set_single_destination(bool single) { single_ = single; }

    const Work& work() const { return work_; }

private:
    // What is known about one entity (indexed by Entity::index; an entity is drawn by one kind of visual, so a Sprite and a Shape2D
    // never share an entity of a table, and the tables are separate anyway).
    struct Slot {
        enum class State : std::uint8_t {
            Todo,    // not looked at yet
            Skip,    // draws nothing for any camera (inactive, transparent, empty)
            Direct,  // draws, but what it makes depends on the camera: built for every camera
            Share,   // built once: `donor` holds the items
        };
        State state = State::Todo;
        bool counted = false;                // it counts in the frame's stats (sprites, shapes, particles) when drawn
        bool ySort = false;                  // the orthographic sort key is pos.y (a Sprite) instead of 0
        std::uint32_t first = 0, count = 0;  // items [first, first + count) of `donor`
        const QuadList* donor = nullptr;
        Vec3 pos{};         // where the entity is drawn: the perspective sort key is the distance from the camera
        int particles = 0;  // an emitter's live particles, for the stats
    };
    // The slot of `e` in `table`. A round with one destination keeps no slots (nothing is shared): a scratch slot, reset.
    Slot& slot_of(std::vector<Slot>& table, const World& world, Entity e);
    float sort_key(const Slot& s, const Frame& f) const;

    void gather_sprites(World& world, Frame& f);
    void gather_shapes(World& world, Frame& f);

    std::vector<Slot> sprites_, shapes_, emitters_;
    Work work_;
    Slot scratch_;
    bool single_ = false;
    bool begun_ = false;
};

}  // namespace fa::render
