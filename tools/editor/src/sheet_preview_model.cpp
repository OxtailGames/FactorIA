#include "sheet_preview_model.h"

#include <algorithm>
#include <cmath>

namespace fa::editor {

std::vector<std::string> sheet_preview_choices(const assets::Sheet& sheet) {
    std::vector<std::string> out{kAllFrames};
    for (const std::string& n : sheet.clip_names()) out.push_back(n);
    return out;
}

SpriteAnimPlan sheet_preview_plan(const assets::Sheet& sheet, const std::string& choice) {
    SpriteAnimator a;
    if (!choice.empty() && choice != kAllFrames && sheet.find(choice)) {
        a.clip = choice;
    } else {  // every frame of the grid
        a.columns = sheet.columns;
        a.rows = sheet.rows;
        a.firstFrame = 0;
        a.lastFrame = std::max(0, (sheet.frames > 0 ? sheet.frames : sheet.columns * sheet.rows) - 1);
    }
    auto shared = std::make_shared<assets::Sheet>(sheet);
    SpriteAnimPlan plan = resolve_sprite_animator(a, "preview", shared);
    if (!plan.pivot && sheet.pivot) plan.pivot = Vec2{(*sheet.pivot)[0], 1.0f - (*sheet.pivot)[1]};
    return plan;
}

SheetPreviewFrame sheet_preview_frame(const assets::Sheet& sheet, const std::string& choice, double seconds, int texW, int texH) {
    const SpriteAnimPlan plan = sheet_preview_plan(sheet, choice);
    SheetPreviewFrame out;
    out.steps = sprite_anim_steps(plan);
    const long raw = long(std::floor(std::max(0.0, seconds) * std::max(0.0f, plan.fps)));
    out.step = plan.loop ? int(raw % out.steps) : int(std::min<long>(raw, out.steps - 1));
    out.ended = !plan.loop && raw >= out.steps - 1;
    out.frame = sprite_anim_frame(plan, out.step);
    out.rect = sprite_frame_rect(plan, out.frame, texW, texH);
    if (plan.pivot) out.pivot = Vec2{plan.pivot->x, 1.0f - plan.pivot->y};
    return out;
}

}  // namespace fa::editor
