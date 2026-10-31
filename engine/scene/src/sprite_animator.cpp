#include "fa/scene/sprite_animator.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"

namespace fa {

std::string sprite_clip_error(std::string_view texture, std::string_view clip, const std::shared_ptr<const assets::Sheet>& sheet) {
    if (!sheet)
        return std::format("SpriteAnimator.clip \"{}\": '{}' has no `sheet` entry in assets.json, so it has no clips.", clip, texture);
    const std::vector<std::string> names = sheet->clip_names();
    if (names.empty())
        return std::format("SpriteAnimator.clip \"{}\": the sheet entry of '{}' has no clips.", clip, texture);
    std::string list;
    for (const std::string& n : names) list += (list.empty() ? "" : ", ") + n;
    return std::format("SpriteAnimator.clip \"{}\": '{}' has no clip of that name. Its clips: {}. {}", clip, texture, list,
                       did_you_mean(clip, names));
}

SpriteAnimPlan resolve_sprite_animator(const SpriteAnimator& a, std::string_view texture, const std::shared_ptr<const assets::Sheet>& sheet) {
    SpriteAnimPlan p;
    p.columns = std::max(1, a.columns);
    p.rows = std::max(1, a.rows);
    p.firstFrame = std::max(0, a.firstFrame);
    p.lastFrame = std::max(p.firstFrame, a.lastFrame);
    p.fps = a.fps;
    p.loop = a.loop;
    p.mode = a.mode;
    const assets::SheetClip* clip = nullptr;
    if (!a.clip.empty()) {
        clip = sheet ? sheet->find(a.clip) : nullptr;
        if (!clip) {
            p.error = sprite_clip_error(texture, a.clip, sheet);
            return p;  // the numeric fields alone
        }
        p.fromSheet = true;
        p.columns = a.columns != 1 ? std::max(1, a.columns) : sheet->columns;
        p.rows = a.rows != 1 ? std::max(1, a.rows) : sheet->rows;
        p.firstFrame = a.firstFrame != 0 ? std::max(0, a.firstFrame) : clip->firstFrame;
        p.lastFrame = std::max(p.firstFrame, a.lastFrame != 0 ? a.lastFrame : clip->lastFrame);
        p.fps = a.fps != 10.0f ? a.fps : clip->fps;
        p.loop = !a.loop ? false : clip->loop;
    }
    // The picture of a sheet: its gutter and pivot apply when the animator's grid is the sheet's.
    if (sheet && p.columns == sheet->columns && p.rows == sheet->rows) {
        p.padding = sheet->padding;
        const auto piv = clip && clip->pivot ? clip->pivot : sheet->pivot;
        if (piv) p.pivot = Vec2{(*piv)[0], 1.0f - (*piv)[1]};
    }
    return p;
}

SpriteAnimPlan sprite_animator_plan(const SpriteAnimator& a, std::string_view texture) {
    if (texture.empty()) return resolve_sprite_animator(a, texture, nullptr);
    return resolve_sprite_animator(a, texture, assets::sheet(texture));
}

int sprite_anim_steps(const SpriteAnimPlan& plan) {
    const int count = std::max(1, plan.lastFrame - plan.firstFrame + 1);
    if (plan.mode == SpriteAnimMode::PingPong && count > 1) return 2 * count - 2;
    return count;
}

int sprite_anim_frame(const SpriteAnimPlan& plan, int step) {
    const int count = std::max(1, plan.lastFrame - plan.firstFrame + 1);
    const int period = sprite_anim_steps(plan);
    int s = std::max(0, step);
    s = plan.loop ? s % period : std::min(s, period);  // a pass that does not loop ends one step after the last (pingpong: back at the start)
    int index;  // 0..count-1 along the clip
    switch (plan.mode) {
        case SpriteAnimMode::Reverse: index = count - 1 - std::min(s, count - 1); break;
        case SpriteAnimMode::PingPong: index = s < count ? s : 2 * count - 2 - s; break;
        default: index = std::min(s, count - 1); break;
    }
    return plan.firstFrame + std::clamp(index, 0, count - 1);
}

bool sprite_animator_step(SpriteAnimator& a, const SpriteAnimPlan& plan, float dt) {
    if (a.playedClip != a.clip) {  // another clip: start over
        a.playedClip = a.clip;
        a.time = 0.0f;
        if (a.ended) a.playing = true;
        a.ended = false;
        a.frame = sprite_anim_frame(plan, 0);
    }
    if (a.ended && a.playing) {  // somebody resumed a finished animation: it runs again only if its time was rewound
        if (plan.loop || int(std::floor(a.time * std::max(0.0f, plan.fps))) < sprite_anim_steps(plan)) a.ended = false;
        else a.playing = false;
    }
    if (a.playing && dt > 0.0f && !a.ended) {
        a.time += dt;
        const int n = int(std::floor(a.time * std::max(0.0f, plan.fps)));
        const int period = sprite_anim_steps(plan);
        a.frame = sprite_anim_frame(plan, n);
        if (!plan.loop && n >= period) {
            a.playing = false;
            a.ended = true;
            return true;
        }
    } else if (a.frame < plan.firstFrame || a.frame > plan.lastFrame) {
        a.frame = sprite_anim_frame(plan, 0);
    }
    return false;
}

Rect sprite_frame_rect(const SpriteAnimPlan& plan, int frame, int texW, int texH) {
    const int cols = std::max(1, plan.columns), rows = std::max(1, plan.rows);
    const int fr = std::max(0, frame);
    const float cw = float(texW) / float(cols), ch = float(texH) / float(rows);
    const float pad = float(plan.padding);
    return Rect{float(fr % cols) * cw + pad, float((fr / cols) % rows) * ch + pad, std::max(1.0f, cw - 2 * pad), std::max(1.0f, ch - 2 * pad)};
}

Vec2 sprite_effective_pivot(const Sprite& s, const SpriteAnimator& a, const SpriteAnimPlan& plan) {
    if (a.sheetPivot && plan.pivot && s.pivot.x == 0.5f && s.pivot.y == 0.5f) return *plan.pivot;
    return s.pivot;
}

Result<void> sprite_animator_play(World& world, Entity e, std::string_view name, bool restart) {
    SpriteAnimator* a = world.get<SpriteAnimator>(e);
    Sprite* s = world.get<Sprite>(e);
    if (!a || !s)
        return make_error(std::format("entity '{}' has no {}", world.id_of(e), a ? "Sprite" : "SpriteAnimator"),
                          "Add both: entity.add(\"Sprite\", {texture}) and entity.add(\"SpriteAnimator\", {clip}).");
    const auto sheet = s->texture.empty() ? nullptr : assets::sheet(s->texture);
    if (!sheet || !sheet->find(name)) return make_error(sprite_clip_error(s->texture, name, sheet), "Clip names are in the `sheet.clips` of assets.json (assets.preview_sheet lists them).");
    if (!restart && a->clip == name && a->playing && !a->ended) return {};  // already playing it: calling play every frame does not restart
    a->clip = std::string(name);
    a->playedClip.clear();  // the next step starts the clip over
    a->time = 0.0f;
    a->ended = false;
    a->playing = true;
    return {};
}

Result<Json> sprite_animator_clips(World& world, Entity e) {
    const Sprite* s = world.get<Sprite>(e);
    if (!s) return make_error(std::format("entity '{}' has no Sprite", world.id_of(e)), "Add a Sprite with the sheet as its texture.");
    const auto sheet = s->texture.empty() ? nullptr : assets::sheet(s->texture);
    if (!sheet)
        return make_error(std::format("'{}' has no `sheet` entry in assets.json, so it has no clips.", s->texture),
                          "assets.animate_svg, assets.bake_sheet, assets.slice_sheet and the Aseprite import write one.");
    Json out = Json::array();
    for (const assets::SheetClip& c : sheet->clips) {
        Json j = Json::object({{"name", c.name}, {"firstFrame", c.firstFrame}, {"lastFrame", c.lastFrame},
                               {"frames", c.lastFrame - c.firstFrame + 1}, {"fps", c.fps}, {"loop", c.loop}});
        const auto piv = c.pivot ? c.pivot : sheet->pivot;
        if (piv) j["pivot"] = Json::array({(*piv)[0], (*piv)[1]});
        out.push_back(std::move(j));
    }
    return out;
}

}  // namespace fa
