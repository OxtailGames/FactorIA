#include "fa/scene/sprite_animator.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <format>
#include <mutex>
#include <string>
#include <unordered_map>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/scene/feel.h"

namespace fa {

namespace {

struct TexDims {
    bool known = false;
    int w = 1, h = 1;
};

// Sizes read from files stay until the file (or its .ktx2 twin) changes: stepping an animator must not read a picture
// every step. The file's stat (time, size) is looked at once per "epoch" (one per frame: the end of
// update_sprite_animators with dt 0 ends it), not per fixed step and not again in the settle pass. On a platform
// whose files have no time (an Android APK asset answers -1) the entry is cached all the same, keyed by the file name
// and re-read only when the name starts or stops being a file.
struct SizeEntry {
    std::int64_t mtime = -2, size = -2, twinMtime = -2;
    bool exists = false;
    std::uint64_t epoch = 0;  // the epoch the stat above was taken in; 0 = never
    TexDims dims;
};
struct SizeCache {
    std::mutex mutex;
    std::filesystem::path root;  // the project the entries belong to
    std::uint64_t epoch = 1;
    std::unordered_map<std::string, SizeEntry> entries;
};
SizeCache& size_cache() {
    static SizeCache c;
    return c;
}

// The size the renderer gives the texture of a Sprite, from files only. Unknown for the ids only the GPU knows.
TexDims cpu_texture_dims(const std::string& texture) {
    if (texture.empty()) return {true, 1, 1};  // the renderer's white pixel
    if (texture.rfind("runtime:", 0) == 0 || texture.rfind("target:", 0) == 0) return {};
    const std::string key = fs::normalize(texture);
    auto read = [&]() -> TexDims {
        auto r = texture_size(key);
        return r ? TexDims{true, r->width, r->height}
                 : TexDims{true, 32, 32};  // the renderer's missing-texture checker
    };
    SizeCache& c = size_cache();
    std::lock_guard<std::mutex> lock(c.mutex);
    if (c.root != fs::project_root()) {
        c.entries.clear();
        c.root = fs::project_root();
    }
    SizeEntry& e = c.entries[key];
    if (e.epoch == c.epoch) return e.dims;  // already looked at in this frame
    const std::int64_t mtime = fs::modified_time(key);
    const std::int64_t size = mtime >= 0 ? fs::file_size(key) : -1;
    const std::int64_t twin = fs::modified_time(key + kTextureTwinExtension);
    const bool exists = mtime >= 0 || fs::exists(key);
    // A rectangle of an atlas (or a name that is no file): answered from memory, so ask again whenever the epoch changes.
    const bool fromMemory = mtime < 0 && twin < 0 && !exists;
    if (e.epoch == 0 || fromMemory || e.mtime != mtime || e.size != size || e.twinMtime != twin || e.exists != exists) {
        e.dims = read();
        e.mtime = mtime;
        e.size = size;
        e.twinMtime = twin;
        e.exists = exists;
    }
    e.epoch = c.epoch;
    return e.dims;
}

// A frame ended (a dt 0 pass): the next lookup of each texture looks at its file again.
void next_size_epoch() {
    SizeCache& c = size_cache();
    std::lock_guard<std::mutex> lock(c.mutex);
    ++c.epoch;
}

}  // namespace

std::string sprite_clip_error(std::string_view texture, std::string_view clip,
                              const std::shared_ptr<const assets::Sheet>& sheet) {
    if (!sheet)
        return std::format("SpriteAnimator.clip \"{}\": '{}' has no `sheet` entry in assets.json, so it has no clips.",
                           clip, texture);
    const std::vector<std::string> names = sheet->clip_names();
    if (names.empty())
        return std::format("SpriteAnimator.clip \"{}\": the sheet entry of '{}' has no clips.", clip, texture);
    std::string list;
    for (const std::string& n : names) list += (list.empty() ? "" : ", ") + n;
    return std::format("SpriteAnimator.clip \"{}\": '{}' has no clip of that name. Its clips: {}. {}", clip, texture,
                       list, did_you_mean(clip, names));
}

SpriteAnimPlan resolve_sprite_animator(const SpriteAnimator& a, std::string_view texture,
                                       const std::shared_ptr<const assets::Sheet>& sheet) {
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
    // loopMode wins over both the clip and the `loop` alias.
    if (a.loopMode == SpriteLoopMode::Loop)
        p.loop = true;
    else if (a.loopMode == SpriteLoopMode::Once)
        p.loop = false;
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
    s = plan.loop
            ? s % period
            : std::min(s,
                       period);  // a pass that does not loop ends one step after the last (pingpong: back at the start)
    int index;                   // 0..count-1 along the clip
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
        a.eventStep = -1;
        if (a.ended) a.playing = true;
        a.ended = false;
        a.frame = sprite_anim_frame(plan, 0);
    }
    if (a.ended && a.playing) {  // somebody resumed a finished animation: it runs again only if its time was rewound
        if (plan.loop || int(std::floor(a.time * std::max(0.0f, plan.fps))) < sprite_anim_steps(plan))
            a.ended = false;
        else
            a.playing = false;
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

void sprite_animator_fire_events(World& world, Entity e, SpriteAnimator& a, const SpriteAnimPlan& plan) {
    const double stepsD = std::floor(static_cast<double>(a.time) * std::max(0.0f, plan.fps));
    const int period = sprite_anim_steps(plan);
    // The frames a pass shows are steps 0..period-1; a clip that does not loop shows nothing after them (it has ended).
    int last = static_cast<int>(std::clamp(stepsD, 0.0, 1.0e9));
    if (!plan.loop) last = std::min(last, period - 1);
    if (a.eventStep > last) a.eventStep = last;  // time went back: a seek, no events for the jump
    if (!a.events.is_array() || a.events.empty()) {
        a.eventStep = last;
        return;
    }
    const int first = std::max(a.eventStep + 1, last - kMaxSpriteEventSteps + 1);
    for (int step = first; step <= last; ++step) {
        const int frame = sprite_anim_frame(plan, step);
        for (std::size_t index = 0; index < a.events.size(); ++index) {
            const Json& ev = a.events[index];
            if (!inline_event_usable(world, e, true, index, ev)) continue;  // a wrong JSON type: said once, skipped
            const auto fit = ev.find("frame");
            if (fit == ev.end() || fit->get<double>() != frame) continue;
            const auto cit = ev.find("clip");
            if (cit != ev.end() && cit->get<std::string>() != a.clip) continue;
            const auto nit = ev.find("name");
            const std::string name = nit != ev.end() ? nit->get<std::string>() : std::string();
            if (!name.empty()) {
                Json data = Json::object();
                if (const auto dit = ev.find("data"); dit != ev.end() && dit->is_object()) data = *dit;
                data["id"] = world.id_of(e);
                data["clip"] = a.clip;
                data["frame"] = frame;
                world.events().game.push_back(GameEvent{name, std::move(data), e});
            }
            if (ev.contains("feel"))
                feel_run_clip_actions(
                    world, e, feel_event_actions(ev),
                    std::format("SpriteAnimator '{}' clip '{}' frame {}", world.id_of(e), a.clip, frame));
        }
    }
    a.eventStep = last;
}

std::vector<ClipIssue> check_sprite_event(const Json& ev, const std::string& ep,
                                          const std::shared_ptr<const assets::Sheet>& sheet) {
    std::vector<ClipIssue> issues;
    if (!ev.is_object()) {
        issues.push_back(
            {ep, "a frame event is an object, got " + describe_json_value(ev),
             "Write {\"frame\": 9, \"name\": \"hit\"} or {\"frame\": 9, \"feel\": {\"action\": \"shake\"}}."});
        return issues;
    }
    const std::vector<std::string> allowed = {"frame", "clip", "name", "data", "feel"};
    for (auto it = ev.begin(); it != ev.end(); ++it)
        if (std::find(allowed.begin(), allowed.end(), it.key()) == allowed.end())
            issues.push_back({ep + "/" + it.key(), "unknown key '" + it.key() + "'", did_you_mean(it.key(), allowed)});
    const auto fit = ev.find("frame");
    if (fit == ev.end() || !fit->is_number_integer() || fit->get<std::int64_t>() < 0)
        issues.push_back(
            {ep + "/frame",
             fit == ev.end() ? "a frame event needs `frame`"
                             : "frame must be a whole number from 0, got " + describe_json_value(*fit),
             "The grid frame that triggers it, numbered row-major from the top-left like firstFrame and lastFrame."});
    if (const auto cit = ev.find("clip"); cit != ev.end()) {
        if (!cit->is_string() || cit->get<std::string>().empty()) {
            issues.push_back({ep + "/clip",
                              "clip must be the name of a clip of the sheet, got " + describe_json_value(*cit),
                              "Leave `clip` out to fire in every clip."});
        } else if (sheet && !sheet->find(cit->get<std::string>())) {
            issues.push_back({ep + "/clip", "the sheet has no clip '" + cit->get<std::string>() + "'",
                              did_you_mean(cit->get<std::string>(), sheet->clip_names())});
        }
    }
    if (const auto nit = ev.find("name"); nit != ev.end() && (!nit->is_string() || nit->get<std::string>().empty()))
        issues.push_back({ep + "/name", "name must be a non-empty string, got " + describe_json_value(*nit),
                          "The game event world.on(name, fn) listens to."});
    if (const auto dit = ev.find("data"); dit != ev.end() && !dit->is_object())
        issues.push_back(
            {ep + "/data", "data must be an object, got " + describe_json_value(*dit), "Write {\"hand\": \"left\"}."});
    std::vector<Json> feel;
    read_event_feel(ev, ep, feel, issues);
    if (!ev.contains("name") && !ev.contains("feel"))
        issues.push_back({ep, "a frame event needs `name` or `feel`",
                          "`name` sends a game event; `feel` runs game feel actions (docs/GAME_FEEL.md)."});
    return issues;
}

std::vector<ClipIssue> check_sprite_events(const Json& events, const std::string& pointer,
                                           const std::shared_ptr<const assets::Sheet>& sheet) {
    std::vector<ClipIssue> issues;
    if (!events.is_array()) {
        issues.push_back({pointer, "events must be an array, got " + describe_json_value(events),
                          "Write [{\"frame\": 9, \"feel\": {\"action\": \"hitStop\", \"duration\": 0.06}}]."});
        return issues;
    }
    for (std::size_t i = 0; i < events.size(); ++i) {
        std::vector<ClipIssue> one = check_sprite_event(events[i], pointer + "/" + std::to_string(i), sheet);
        issues.insert(issues.end(), one.begin(), one.end());
    }
    return issues;
}

Rect sprite_frame_rect(const SpriteAnimPlan& plan, int frame, int texW, int texH) {
    const int cols = std::max(1, plan.columns), rows = std::max(1, plan.rows);
    const int fr = std::max(0, frame);
    const float cw = float(texW) / float(cols), ch = float(texH) / float(rows);
    const float pad = float(plan.padding);
    return Rect{float(fr % cols) * cw + pad, float((fr / cols) % rows) * ch + pad, std::max(1.0f, cw - 2 * pad),
                std::max(1.0f, ch - 2 * pad)};
}

Vec2 sprite_effective_pivot(const Sprite& s, const SpriteAnimator& a, const SpriteAnimPlan& plan) {
    if (a.sheetPivot && plan.pivot && s.pivot.x == 0.5f && s.pivot.y == 0.5f) return *plan.pivot;
    return s.pivot;
}

void update_sprite_animators(World& world, float dt) {
    // The settle pass (dt 0) ends a frame: it answers from what the frame's steps looked at, and file sizes are looked at again from
    // the next frame on. So a texture's file is looked at once per frame, however many fixed steps the frame has. The
    // settle pass reuses the size this frame's fixed steps cached: a texture a script rewrites in onUpdate shows its new
    // size next frame.
    struct EndOfFrame {
        bool on;
        ~EndOfFrame() {
            if (on) next_size_epoch();
        }
    } endOfFrame{dt <= 0.0f};
    // The sheet and the size of each texture are looked up once per texture per step.
    std::unordered_map<std::string, std::shared_ptr<const assets::Sheet>> sheets;
    std::unordered_map<std::string, TexDims> dims;
    // Driven by SpriteAnimator on purpose: each<A, B> walks the smaller pool, and the order of the clipEnded events (and of
    // the frame events) must be the animators' insertion order whatever the number of sprites.
    world.each<SpriteAnimator>([&](Entity e, SpriteAnimator& a) {
        Sprite* sprite = world.get<Sprite>(e);
        if (!sprite || !world.active_in_hierarchy(e) || world.pending_destroy(e)) return;
        Sprite& s = *sprite;
        std::shared_ptr<const assets::Sheet> sheet;
        if (!s.texture.empty()) {
            auto it = sheets.find(s.texture);
            if (it == sheets.end()) it = sheets.emplace(s.texture, assets::sheet(s.texture)).first;
            sheet = it->second;
        }
        const SpriteAnimPlan plan = resolve_sprite_animator(a, s.texture, sheet);
        if (!plan.error.empty() && world.warned_sprite_clips().insert(world.id_of(e) + "|" + a.clip).second)
            FA_WARN("scene", "entity '{}': {}", world.id_of(e), plan.error);
        const bool ended = sprite_animator_step(a, plan, dt);
        // Frame events run before clipEnded; they only queue effects and game events, so nothing below changes the world while
        // this loop walks it (a `spawn` instantiates its prefab in feel_update). Time that does not move (a paused game, the
        // editor's edit mode) fires none: nothing would drain what they queue.
        if (dt > 0.0f) sprite_animator_fire_events(world, e, a, plan);
        if (ended)
            world.events().game.push_back(
                GameEvent{"clipEnded", Json::object({{"id", world.id_of(e)}, {"clip", a.clip}}), e});
        auto dit = dims.find(s.texture);
        if (dit == dims.end()) dit = dims.emplace(s.texture, cpu_texture_dims(s.texture)).first;
        if (dit->second.known) s.region = sprite_frame_rect(plan, a.frame, dit->second.w, dit->second.h);
    });
}

Result<void> sprite_animator_play(World& world, Entity e, std::string_view name, bool restart) {
    SpriteAnimator* a = world.get<SpriteAnimator>(e);
    Sprite* s = world.get<Sprite>(e);
    if (!a || !s)
        return make_error(std::format("entity '{}' has no {}", world.id_of(e), a ? "Sprite" : "SpriteAnimator"),
                          "Add both: entity.add(\"Sprite\", {texture}) and entity.add(\"SpriteAnimator\", {clip}).");
    const auto sheet = s->texture.empty() ? nullptr : assets::sheet(s->texture);
    if (!sheet || !sheet->find(name))
        return make_error(sprite_clip_error(s->texture, name, sheet),
                          "Clip names are in the `sheet.clips` of assets.json (assets.preview_sheet lists them).");
    if (!restart && a->clip == name && a->playing && !a->ended)
        return {};  // already playing it: calling play every frame does not restart
    a->clip = std::string(name);
    a->playedClip.clear();  // the next step starts the clip over
    a->time = 0.0f;
    a->ended = false;
    a->playing = true;
    return {};
}

Result<Json> sprite_animator_clips(World& world, Entity e) {
    const Sprite* s = world.get<Sprite>(e);
    if (!s)
        return make_error(std::format("entity '{}' has no Sprite", world.id_of(e)),
                          "Add a Sprite with the sheet as its texture.");
    const auto sheet = s->texture.empty() ? nullptr : assets::sheet(s->texture);
    if (!sheet)
        return make_error(
            std::format("'{}' has no `sheet` entry in assets.json, so it has no clips.", s->texture),
            "assets.animate_svg, assets.bake_sheet, assets.slice_sheet and the Aseprite import write one.");
    Json out = Json::array();
    for (const assets::SheetClip& c : sheet->clips) {
        Json j = Json::object({{"name", c.name},
                               {"firstFrame", c.firstFrame},
                               {"lastFrame", c.lastFrame},
                               {"frames", c.lastFrame - c.firstFrame + 1},
                               {"fps", c.fps},
                               {"loop", c.loop}});
        const auto piv = c.pivot ? c.pivot : sheet->pivot;
        if (piv) j["pivot"] = Json::array({(*piv)[0], (*piv)[1]});
        out.push_back(std::move(j));
    }
    return out;
}

}  // namespace fa
