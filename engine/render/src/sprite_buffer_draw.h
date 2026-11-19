// Drawing a Sprite from compute buffers (M72.4, docs/shaders/SHADERS_COMPUTE.md "Sprites from a compute buffer"): a sprite
// material that declares "buffers" reads them in its vertex() and fragment() as read-only storage buffers, and the Sprite draws its
// one quad Sprite.instances times in one draw (fa_instance_index = 0 .. instances - 1); the vertex stage moves each copy.
//
// Two steps, like a mesh (mesh_buffer_draw.h): the gather (scene2d.cpp, on the main thread) checks the Sprite against its material
// and the compute buffers, reports what is wrong once with the entity and a JSON pointer, and draws nothing for a Sprite that does not
// fit; the draw (renderer_draw.cpp draw_group) looks the buffers up again by the ids the batch's MaterialUse holds and binds them.
#pragma once

#include "mesh_buffer_draw.h"

namespace fa {
struct Sprite;
}

namespace fa::render {

// The buffers `s` (the Sprite of `e`) is drawn with, checked against `material` (what Assets::sprite_material answered for it) and
// Sprite.instances against their sizes. `instances` of the answer is the count of the one draw (1 for Sprite.instances 0). A failure
// sets `skip` and is reported once through Assets::note_failure. A Sprite without buffers answers `active` false (and `skip` when it
// asks for instances a material without buffers cannot give).
MeshBufferUse resolve_sprite_buffers(Assets& assets, Compute* compute, Entity e, const Sprite& s,
                                     const MaterialUse* material);

// At draw time: the views of the buffers `use` holds the ids of, for a batch of `instances`. False (and the batch is not drawn, with
// one report per material) when a buffer is gone or too small by then.
bool bind_sprite_buffer_views(Assets& assets, Compute* compute, const MaterialUse& use, int instances,
                              MeshBufferUse& out);

}  // namespace fa::render
