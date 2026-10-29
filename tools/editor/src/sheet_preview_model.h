// What the Project panel shows for a sprite sheet (project_browser_panel.cpp, "Sheet preview"): one clip of the sheet's `sheet`
// entry (or every frame) played the way a SpriteAnimator plays it, so the preview and the game agree. No ImGui: tested in
// tests/project_browser_tests.cpp.
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "fa/core/asset_manifest.h"
#include "fa/core/math.h"
#include "fa/scene/sprite_animator.h"

namespace fa::editor {

// The entries of the clip menu: "(all frames)" first, then the clip names of the sheet.
inline constexpr const char* kAllFrames = "(all frames)";
std::vector<std::string> sheet_preview_choices(const assets::Sheet& sheet);

// The plan for `choice` ("" or kAllFrames = every frame, 10 fps, looping; a clip name = that clip's fps, loop and pivot).
// A name the sheet does not have falls back to every frame.
SpriteAnimPlan sheet_preview_plan(const assets::Sheet& sheet, const std::string& choice);

struct SheetPreviewFrame {
    int frame = 0;        // grid index (row-major) shown
    int step = 0;         // 0-based position in the pass
    int steps = 1;        // frames in one pass
    Rect rect;            // pixel rectangle of the frame in the texture (top-left origin), the gutter skipped
    Vec2 pivot{0.5f, 0.5f};  // 0..1 from the TOP-left of the frame (the sheet's convention)
    bool ended = false;   // a clip that does not loop has reached its last frame
};
// The frame shown `seconds` after the preview started, for a texture of texW x texH pixels.
SheetPreviewFrame sheet_preview_frame(const assets::Sheet& sheet, const std::string& choice, double seconds, int texW, int texH);

}  // namespace fa::editor
