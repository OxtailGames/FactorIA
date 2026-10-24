// The video system: plays the Video components (components.h) from the game clock. The runtime calls update_videos() once
// per FIXED step with the step's length times time.scale (0 while the game is paused), so videos pause with the game, and
// headless runs decode the same pictures at the same times as windowed ones. The renderer READS the picture of each
// Video (rt.decoder->picture()) and fa_audio feeds its sound to the mixer (rt.decoder->take_audio()); neither advances it.
#pragma once

#include "fa/scene/world.h"

namespace fa {

// For every active Video: opens its file (again when `path` changed), applies what a script wrote to `playing` and `time`,
// advances it by `dt` seconds while it plays, and keeps `time`, `duration`, `playing` and `ended` true. At the end of a
// video that does not loop it pushes the game event "video.ended" ({id, path}) once and clears `playing`. `dt` may be 0
// (a paused game): seeks and play / pause still apply. A file that cannot be opened is logged once and the Video draws
// only its background.
void update_videos(World& world, float dt);

}  // namespace fa
