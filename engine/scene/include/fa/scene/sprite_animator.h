// SpriteAnimator logic without a GPU: which clip of the texture's sheet entry plays, how time walks its frames, which
// rectangle of the texture a frame is, and the pivot the sheet gives the sprite. The renderer (update_animators) steps the
// animators with the frame time and applies the region; scripts call sprite_animator_play (entity.spriteAnimator).
//
// Resolution order: the numeric fields of the component override the clip's values when they differ from their defaults
// (columns 1, rows 1, firstFrame 0, lastFrame 0, fps 10, loop true; `loop: false` is the only value of loop that overrides);
// the clip overrides the sheet's grid; a component without `clip` and without a sheet entry is the plain grid of its fields.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/asset_manifest.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

namespace fa {

// What a SpriteAnimator plays now, all fields settled.
struct SpriteAnimPlan {
    int columns = 1, rows = 1;
    int firstFrame = 0, lastFrame = 0;
    float fps = 10.0f;
    bool loop = true;
    SpriteAnimMode mode = SpriteAnimMode::Forward;
    int padding = 0;
    std::optional<Vec2> pivot;            // the sheet's / clip's pivot as Sprite.pivot (y already flipped to count from the bottom)
    bool fromSheet = false;               // a clip of the sheet entry was resolved
    std::string error;                    // a `clip` the sheet does not have, or a texture with no sheet: teaches, "" = fine
};

// The plan of `a` for a sprite that draws `texture`. `sheet` is assets::sheet(texture) (null when the texture has none).
SpriteAnimPlan resolve_sprite_animator(const SpriteAnimator& a, std::string_view texture, const std::shared_ptr<const assets::Sheet>& sheet);

// The error text for an unknown `clip` of `texture`: lists the clips and suggests the closest name.
std::string sprite_clip_error(std::string_view texture, std::string_view clip, const std::shared_ptr<const assets::Sheet>& sheet);

// Number of frames a pass over the clip shows, and the frame (an index of the sheet's grid, row-major) shown `n` frame-steps
// after the start. n is clamped for a clip that does not loop.
int sprite_anim_steps(const SpriteAnimPlan& plan);      // frames in one pass, pingpong included (first..last..first without repeating the ends)
int sprite_anim_frame(const SpriteAnimPlan& plan, int step);  // the grid index at a step of the pass

// Moves `a` on by `dt` seconds against `plan`: a change of clip restarts, time advances, `frame` is set. Returns true when a
// clip that does not loop reached its end during this step (once: `ended` is set, `playing` becomes false and the animation
// stays on its last frame; for pingpong back on the first frame).
bool sprite_animator_step(SpriteAnimator& a, const SpriteAnimPlan& plan, float dt);

// The pixel rectangle of grid index `frame` in a texture of texW x texH pixels (top-left origin, like Sprite.region).
Rect sprite_frame_rect(const SpriteAnimPlan& plan, int frame, int texW, int texH);

// The pivot a Sprite is drawn with: its own, or the plan's when the animator allows it and the sprite's is the default centre.
Vec2 sprite_effective_pivot(const Sprite& s, const SpriteAnimator& a, const SpriteAnimPlan& plan);

// Script calls (entity.spriteAnimator): start the clip `name` and play. Asking for the clip that already plays (and has not
// ended) does nothing unless `restart`, so a script may call it every frame. An unknown name is an error that lists the clips.
Result<void> sprite_animator_play(World& world, Entity e, std::string_view name, bool restart = false);
// Clips of the sprite's texture: [{name, firstFrame, lastFrame, frames, fps, loop, pivot?}]; an error when the texture has no sheet.
Result<Json> sprite_animator_clips(World& world, Entity e);
// The plan of an animator over `texture` (looks the sheet up itself); for tools and bounds.
SpriteAnimPlan sprite_animator_plan(const SpriteAnimator& a, std::string_view texture);

}  // namespace fa
