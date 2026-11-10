// SpriteAnimator logic without a GPU: which clip of the texture's sheet entry plays, how time walks its frames, which
// rectangle of the texture a frame is, and the pivot the sheet gives the sprite. The runtime steps the animators in the fixed
// simulation step (update_sprite_animators, no GPU needed) and the renderer only draws the frame they chose; scripts call
// sprite_animator_play (entity.spriteAnimator).
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
#include "fa/scene/anim_clip.h"
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

// One step of `dt` seconds of every active SpriteAnimator of `world`: clip changes, time, `frame`, the frame events
// (SpriteAnimator::events, only when dt > 0), the game event `clipEnded` of a clip that reached its end, and the Sprite.region of
// the frame (the pixel rectangle of the frame in the texture). The sheet comes from assets::sheet and the texture's size from
// its file (texture_size, cached by file name; the file's time and size are looked at again once per frame, after each dt = 0
// pass, so a picture that changed is seen the next frame), never from a GPU texture, so a game with no renderer animates the same
// as one with it. A texture with no readable file counts 32x32 (the renderer's missing-texture checker), no texture 1x1; a
// `runtime:` or `target:` texture has no size on the CPU: its region is left to the renderer. dt = 0 only settles (a script
// changed the clip). An unknown `clip` is warned once per entity and clip (World::warned_sprite_clips).
void update_sprite_animators(World& world, float dt);

// Moves `a` on by `dt` seconds against `plan`: a change of clip restarts, time advances, `frame` is set. Returns true when a
// clip that does not loop reached its end during this step (once: `ended` is set, `playing` becomes false and the animation
// stays on its last frame; for pingpong back on the first frame).
bool sprite_animator_step(SpriteAnimator& a, const SpriteAnimPlan& plan, float dt);

// Runs the frame events of `a` (SpriteAnimator::events) for the frames the animation showed since the last call: every step of
// the pass from the one after the last handled up to the current one, in order, so a long frame time skips no event and a loop
// fires its frame once per pass. A frame event sends the game event `name` {id, clip, frame, ...data} and runs its `feel`
// actions for the entity (feel.h). Call it once per animation step after sprite_animator_step. A rewind of `time` (a script
// seeked) fires nothing; at most kMaxSpriteEventSteps steps are visited per call (a work count, not a clock).
inline constexpr int kMaxSpriteEventSteps = 1000;
void sprite_animator_fire_events(World& world, Entity e, SpriteAnimator& a, const SpriteAnimPlan& plan);

// Problems of a SpriteAnimator `events` value, as issues pointing below `pointer` ("/entities/0/components/SpriteAnimator/events"):
// not an array, an entry that is not an object, a missing or negative `frame`, an unknown key, an entry with neither `name` nor
// `feel`, a `clip` the sheet of `texture` does not have (checked only when `sheet` is not null), a wrong action.
std::vector<ClipIssue> check_sprite_events(const Json& events, const std::string& pointer,
                                           const std::shared_ptr<const assets::Sheet>& sheet);
// The same for one entry of the list, `pointer` being the entry's own.
std::vector<ClipIssue> check_sprite_event(const Json& event, const std::string& pointer, const std::shared_ptr<const assets::Sheet>& sheet);

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
