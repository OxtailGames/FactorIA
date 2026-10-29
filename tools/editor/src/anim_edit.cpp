// The Animation panel's side that changes things: which entity and clip the panel works on, the pose it leaves the world in,
// every edit of a clip (anim.* commands, with their undo steps in the editor's stack), record mode and the onion skin. The
// drawing of the panel is in anim_panel.cpp, the rules that need no window in anim_model.h.
//
// A clip file is not part of the scene. Its undo steps are entries of the editor's own undo stack: {"$clip": {path, clip}}, the
// arguments of anim.restore with the whole previous document, so Ctrl+Z / Ctrl+Y undo scene edits and clip edits in the order
// they were made.
//
// Posing: scrubbing and playing the preview pose the entity with anim.pose and put the Animator's clip / time / playing back at
// once, so the scene that is saved never says "paused on this clip". The rest values of the fields a clip drives are kept by the
// Animator itself (the scene writers use them instead of the posed values); anim_unpose() gives them back to the world.
#include <algorithm>
#include <cmath>
#include <format>
#include <functional>

#include "editor_internal.h"
#include "fa/scene/animation.h"
#include "fa/scene/bones2d.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

bool is_clip_entry(const Json& j) { return j.is_object() && j.contains("$clip"); }

void collect_bones(const World& w, Entity e, std::vector<Entity>& out) {
    if (w.has<Bone2D>(e)) out.push_back(e);
    for (Entity c : w.children(e)) collect_bones(w, c, out);
}

}  // namespace

// ----------------------------------------------------------------------------------------------------- which clip --
Entity Editor::anim_owner() {
    if (!engine_ || anim_.ownerId.empty()) return kNullEntity;
    Entity e = world().find_by_id(anim_.ownerId);
    if (e.is_null() || !world().alive(e) || !world().has<Animator>(e)) return kNullEntity;
    return e;
}

void Editor::anim_refresh_owner() {
    if (!engine_) return;
    World& w = world();
    const Entity sel = selected();
    Entity current = anim_owner();
    auto within = [&](Entity e, Entity root) {
        for (; !e.is_null(); e = w.parent(e))
            if (e == root) return true;
        return false;
    };
    Entity next = current;
    if (!sel.is_null()) {
        if (current.is_null() || !within(sel, current)) {
            next = sel;
            while (!next.is_null() && !w.has<Animator>(next)) next = w.parent(next);
        }
    } else if (anim_.ownerId.empty() || current.is_null()) {
        next = kNullEntity;
    }
    const std::string nextId = next.is_null() ? std::string() : w.id_of(next);
    if (nextId == anim_.ownerId) {
        // The same entity: its clip may have been renamed or removed.
        if (!next.is_null()) {
            const Animator* a = w.get<Animator>(next);
            if (a && (!a->clips.is_object() || !a->clips.contains(anim_.clipName))) anim_select_clip(std::string());
        }
        return;
    }
    anim_unpose();
    anim_.ownerId = nextId;
    anim_.recording = false;
    anim_.playing = false;
    anim_.selection.clear();
    anim_.selectedEvent = -1;
    anim_.clipName.clear();
    anim_select_clip(std::string());
}

void Editor::anim_select_clip(const std::string& wanted) {
    anim_unpose();
    anim_.selection.clear();
    anim_.curveTracks.clear();
    anim_.selectedEvent = -1;
    anim_.playhead = 0;
    anim_.playing = false;
    anim_.fitNext = true;
    anim_.dirtyPose = true;
    anim_.ghostKey.clear();
    anim_.clipName.clear();
    const Entity owner = anim_owner();
    if (owner.is_null()) return;
    const Animator* a = world().get<Animator>(owner);
    if (!a || !a->clips.is_object() || a->clips.empty()) return;
    if (!wanted.empty() && a->clips.contains(wanted)) anim_.clipName = wanted;
    else if (!a->clip.empty() && a->clips.contains(a->clip)) anim_.clipName = a->clip;
    else anim_.clipName = a->clips.begin().key();
}

std::string Editor::anim_clip_path() {
    const Entity owner = anim_owner();
    if (owner.is_null() || anim_.clipName.empty()) return {};
    const Animator* a = world().get<Animator>(owner);
    if (!a || !a->clips.is_object() || !a->clips.contains(anim_.clipName) || !a->clips[anim_.clipName].is_string()) return {};
    return a->clips[anim_.clipName].get<std::string>();
}

// --------------------------------------------------------------------------------------------------------- posing --
void Editor::anim_set_playhead(double t, bool pose) {
    double hi = 1e9;
    if (const std::string path = anim_clip_path(); !path.empty())
        if (auto clip = load_anim_clip(path); clip.ok()) hi = (*clip)->duration;
    t = std::clamp(clip_round_time(t), 0.0, hi);
    if (t == anim_.playhead && !anim_.dirtyPose) return;
    anim_.playhead = t;
    if (pose) anim_.dirtyPose = true;
}

void Editor::anim_pose() {
    anim_.dirtyPose = false;
    if (!engine_ || play_ != PlayState::Edit) return;
    const Entity owner = anim_owner();
    const std::string path = anim_clip_path();
    if (owner.is_null() || path.empty()) return;
    auto clip = load_anim_clip(path);
    if (!clip.ok()) {
        anim_.error = clip.error().to_string();
        return;
    }
    World& w = world();
    Animator* a = w.get<Animator>(owner);
    if (!a) return;
    if (!anim_.posed || anim_.posedGeneration != w.scene_generation() || anim_.posedOwner != anim_.ownerId) {
        // First pose of this world: remember what the Animator says and where the bones are (an IK solve moves them too).
        anim_.savedClip = a->clip;
        anim_.savedTime = a->time;
        anim_.savedPlaying = a->playing;
        anim_.boneRest.clear();
        std::vector<Entity> bones;
        collect_bones(w, owner, bones);
        const TypeInfo* tt = TypeRegistry::global().find("Transform");
        for (Entity b : bones)
            if (const Transform* t = w.get<Transform>(b); t && tt) anim_.boneRest.push_back({w.id_of(b), field_to_json(*tt->field("position"), t), field_to_json(*tt->field("rotation"), t),
                                          field_to_json(*tt->field("scale"), t)});
    }
    const double t = std::clamp(anim_.playhead, 0.0, double((*clip)->duration));
    const CommandResult r = engine_->commands().call(
        "anim.pose", Json::object({{"entity", anim_.ownerId}, {"clip", anim_.clipName}, {"t", t}}));
    if (Animator* again = w.get<Animator>(owner)) {  // anim.pose pauses the Animator on the clip: the scene must not say so
        again->clip = anim_.savedClip;
        again->time = anim_.savedTime;
        again->playing = anim_.savedPlaying;
    }
    if (!r.ok) {
        anim_.error = command_error_text(r.error);
        return;
    }
    anim_.error.clear();
    anim_.posed = true;
    anim_.posedGeneration = w.scene_generation();
    anim_.posedOwner = anim_.ownerId;
}

void Editor::anim_unpose() {
    if (!anim_.posed) return;
    anim_.posed = false;
    anim_.ghosts.clear();
    anim_.ghostKey.clear();
    if (!engine_ || anim_.posedGeneration != world().scene_generation()) return;  // the world was replaced: nothing to undo
    World& w = world();
    const Entity owner = w.find_by_id(anim_.posedOwner);
    if (owner.is_null() || !w.alive(owner) || !w.has<Animator>(owner)) return;
    (void)animator_stop(w, owner);  // every driven field gets its rest value back
    if (Animator* a = w.get<Animator>(owner)) {
        a->clip = anim_.savedClip;
        a->time = anim_.savedTime;
        a->playing = anim_.savedPlaying;
    }
    const TypeInfo* tt = TypeRegistry::global().find("Transform");
    for (const AnimUi::BoneRest& b : anim_.boneRest) {
        const Entity e = w.find_by_id(b.id);
        Transform* t = e.is_null() ? nullptr : w.get<Transform>(e);
        if (!t || !tt) continue;
        (void)field_from_json(*tt->field("position"), t, b.position);
        (void)field_from_json(*tt->field("rotation"), t, b.rotation);
        (void)field_from_json(*tt->field("scale"), t, b.scale);
    }
    anim_.boneRest.clear();
}

// ---------------------------------------------------------------------------------------------------------- edits --
bool Editor::anim_edit(const std::string& key, const std::vector<ModelCall>& calls, std::string* error) {
    auto fail = [&](const std::string& message) {
        anim_.error = message;
        if (error) *error = message;
        return false;
    };
    if (!engine_) return fail("No project is open.");
    if (play_ != PlayState::Edit) return fail("Stop the game to edit clips.");
    Json undoArgs;
    std::string problem;
    for (const ModelCall& call : calls) {
        const CommandResult r = engine_->commands().call(call.first, call.second);
        if (!r.ok) {
            problem = call.first + ": " + command_error_text(r.error);
            break;
        }
        if (undoArgs.is_null() && r.result.is_object() && r.result.contains("undo") && r.result["undo"].contains("args"))
            undoArgs = r.result["undo"]["args"];  // the first call's undo holds the clip as it was before the whole edit
    }
    if (!undoArgs.is_null()) {
        const bool coalesce = key == lastEditKey_ && (time_ - lastEditTime_) < 0.8 && !undo_.empty() && is_clip_entry(undo_.back());
        if (!coalesce) {
            undo_.push_back(Json::object({{"$clip", undoArgs}}));
            if (undo_.size() > 100) undo_.erase(undo_.begin());
            redo_.clear();
        }
        lastEditKey_ = key;
        lastEditTime_ = time_;
        anim_.dirtyPose = true;
        anim_.ghostKey.clear();
    }
    if (!problem.empty()) return fail(problem);
    anim_.error.clear();
    return true;
}

void Editor::anim_apply_clip_undo(const Json& entry, bool forward) {
    const Json& args = entry["$clip"];
    const CommandResult r = engine_->commands().call("anim.restore", args);
    if (!r.ok) {
        notify("Could not " + std::string(forward ? "redo" : "undo") + " the clip edit: " + command_error_text(r.error), 2);
        return;
    }
    if (r.result.is_object() && r.result.contains("undo") && r.result["undo"].contains("args")) {
        auto& other = forward ? undo_ : redo_;
        other.push_back(Json::object({{"$clip", r.result["undo"]["args"]}}));
    }
    anim_.dirtyPose = true;
    anim_.ghostKey.clear();
}

void Editor::anim_cancel_step() {
    if (undo_.empty() || !is_clip_entry(undo_.back())) return;
    const Json entry = std::move(undo_.back());
    undo_.pop_back();
    if (engine_) (void)engine_->commands().call("anim.restore", entry["$clip"]);
    lastEditKey_.clear();
    anim_.dirtyPose = true;
    anim_.ghostKey.clear();
}

bool Editor::anim_new_clip(const std::string& name, double duration, bool loop, std::string* error) {
    auto fail = [&](const std::string& m) {
        anim_.error = m;
        if (error) *error = m;
        return false;
    };
    const Entity owner = anim_owner();
    if (owner.is_null()) return fail("Select an entity with an Animator first.");
    if (name.empty() || name.find('/') != std::string::npos || name.find('\\') != std::string::npos)
        return fail("A clip name is a plain word without '/': it becomes the file name and the key in Animator.clips.");
    const Animator* a = world().get<Animator>(owner);
    if (a && a->clips.is_object() && a->clips.contains(name)) return fail("The Animator already has a clip called '" + name + "'.");
    const std::string path = "anim/" + name + ".anim.json";
    const std::string stamp = std::to_string(uiFrame_);
    if (!anim_edit("anim:new:" + stamp, {{"anim.create_clip", Json::object({{"path", path}, {"duration", duration}, {"loop", loop}})}}, error))
        return false;
    std::string err;
    const CommandResult r = edit_command("anim:new-ref:" + stamp, "scene.set_component",
                                         field_edit_args(anim_.ownerId, "Animator", "clips", Json::object({{name, path}}), true), &err);
    if (!r.ok) return fail("The clip file was written but the Animator could not take it: " + err);
    project_files_changed();
    anim_select_clip(name);
    return true;
}

// ------------------------------------------------------------------------------------------------------ record mode --
// A scene.set_component that touches a part of the animated entity while record mode is on: the animatable fields become keys
// at the playhead (the part keeps its rest value), the others go through as the edit they are. Returns false when the call is
// none of the record mode's business (the caller then runs it as usual).
bool Editor::anim_record_edit(const std::string& key, const Json& args, CommandResult& out, std::string* error) {
    if (!anim_recording() || play_ != PlayState::Edit || !args.is_object() || args.value("merge", false)) return false;
    if (!args.contains("id") || !args["id"].is_string() || !args.contains("component") || !args["component"].is_string()) return false;
    if (!args.contains("fields") || !args["fields"].is_object()) return false;
    anim_refresh_owner();
    const Entity owner = anim_owner();
    const std::string path = anim_clip_path();
    if (owner.is_null() || path.empty()) return false;
    World& w = world();
    const Entity target = w.find(args["id"].get<std::string>());
    if (target.is_null()) return false;
    const std::string component = args["component"].get<std::string>();
    if (component == "Animator") return false;  // the Animator is not animated by its own clips
    const auto part = part_path_of(w, owner, target);
    if (!part) return false;
    const TypeInfo* type = TypeRegistry::global().find(component);
    void* live = type ? w.get(target, *type) : nullptr;
    if (!live) return false;
    auto clip = load_anim_clip(path);
    if (!clip.ok()) return false;

    std::vector<RecordKey> changes;
    Json rest = Json::object();
    for (auto it = args["fields"].begin(); it != args["fields"].end(); ++it) {
        const FieldInfo* f = type->field(it.key());
        if (!f || !clip_field_animatable(*f)) {
            rest[it.key()] = *it;
            continue;
        }
        const auto got = record_changes(*type, *f, live, *it);
        changes.insert(changes.end(), got.begin(), got.end());
    }
    out = CommandResult{};
    out.ok = true;
    out.result = Json::object({{"recorded", changes.size()}, {"clip", anim_.clipName}, {"t", anim_.playhead}});
    if (!changes.empty()) {
        const double t = anim_.snap ? snap_to_frames(anim_.playhead, anim_.fps) : anim_.playhead;
        const double at = std::clamp(t, 0.0, 1e9);
        std::string err;
        if (!anim_edit(key, record_calls(path, **clip, *part, changes, at), &err)) {
            out.ok = false;
            out.error = Json::object({{"message", err}, {"hint", "Record mode writes keys with anim.set_keys; the clip file could not take this one."}});
            if (error) *error = err;
            return true;
        }
        anim_.recordedKeys += int(changes.size());
        project_files_changed();
    }
    if (!rest.empty()) {
        Json args2 = args;
        args2["fields"] = rest;
        const bool was = anim_.recording;
        anim_.recording = false;  // the plain edit below must not come back here
        out = edit_command(key + ":rest", "scene.set_component", args2, error);
        anim_.recording = was;
    }
    return true;
}

// ------------------------------------------------------------------------------------------------------ onion skin --
SkinBox Editor::sprite_local_box(Entity e) {
    const Sprite* s = world().get<Sprite>(e);
    if (!s) return {};
    Vec2 size = s->size;
    if (size.x <= 0 || size.y <= 0) {
        Vec2 base{32.0f, 32.0f};
        if (!s->texture.empty()) {
            if (s->region.w > 0 && s->region.h > 0) base = {s->region.w, s->region.h};
            else if (const VisualMeasure m = visual_measure(); m.textureSize) base = m.textureSize(s->texture);
        }
        size = {size.x > 0 ? size.x : base.x, size.y > 0 ? size.y : base.y};
    }
    return SkinBox{-s->pivot.x * size.x, -s->pivot.y * size.y, (1.0f - s->pivot.x) * size.x, (1.0f - s->pivot.y) * size.y};
}

void Editor::anim_update_onion(Renderer& r) {
    (void)r;
    AnimUi& u = anim_;
    const Entity owner = anim_owner();
    const std::string path = anim_clip_path();
    if (!u.onion || !showAnimation_ || owner.is_null() || path.empty() || play_ != PlayState::Edit) {
        u.ghosts.clear();
        u.ghostKey.clear();
        return;
    }
    auto clip = load_anim_clip(path);
    if (!clip.ok()) return;
    World& w = world();
    const std::string key = std::format("{}|{}|{}|{}|{}|{}|{}|{}|{}", u.ownerId, u.clipName, u.playhead, u.onionBefore, u.onionAfter,
                                        u.onionFrames, u.fps, (*clip)->mtime, w.scene_generation());
    if (key == u.ghostKey) return;
    u.ghostKey = key;
    u.ghosts.clear();
    if (!u.posed || u.dirtyPose) anim_pose();  // saves the Animator's fields before the ghosts change them
    if (!u.posed) return;
    const double step = std::max(1, u.onionFrames) / double(std::max(1, u.fps));
    std::vector<std::pair<double, int>> times;
    for (int i = u.onionBefore; i >= 1; --i) {
        const double t = u.playhead - i * step;
        if (t >= -1e-9) times.push_back({std::max(0.0, t), -i});
    }
    for (int i = 1; i <= u.onionAfter; ++i) {
        const double t = u.playhead + i * step;
        if (t <= double((*clip)->duration) + 1e-9) times.push_back({std::min(t, double((*clip)->duration)), i});
    }
    std::vector<Entity> sprites;
    std::function<void(Entity)> collect = [&](Entity e) {
        if (w.has<Sprite>(e) && w.active_in_hierarchy(e)) sprites.push_back(e);
        for (Entity c : w.children(e)) collect(c);
    };
    collect(owner);
    for (const auto& [t, side] : times) {
        (void)animator_sample(w, owner, u.clipName, float(t));
        bind_pending_skins(w);
        update_ik2d(w);
        OnionPose pose;
        pose.t = t;
        pose.side = side < 0 ? -1 : 1;
        for (Entity e : sprites) {
            const Sprite& s = *w.get<Sprite>(e);
            const SkinBox box = sprite_local_box(e);
            const Mat4 m = w.world_matrix(e);
            auto to_world = [&](Vec2 p) {
                const Vec3 v = m.transform_point(Vec3{p.x, p.y, 0});
                return Vec2{v.x, v.y};
            };
            float u0 = 0, v0 = 0, u1 = 1, v1 = 1;
            std::string texture;
            if (!s.texture.empty()) {
                if (const TextureEntry* tex = texture_for(s.texture); tex && tex->w > 0 && tex->h > 0) {
                    texture = s.texture;
                    if (s.region.w > 0 && s.region.h > 0) {
                        u0 = s.region.x / float(tex->w);
                        v0 = s.region.y / float(tex->h);
                        u1 = (s.region.x + s.region.w) / float(tex->w);
                        v1 = (s.region.y + s.region.h) / float(tex->h);
                    }
                }
            }
            if (s.flipX) std::swap(u0, u1);
            if (s.flipY) std::swap(v0, v1);
            SkinMesh mesh;
            if (w.has<SpriteSkin>(e) && build_skin_mesh(w, e, s, box, mesh, nullptr) && !mesh.quads.empty()) {
                for (const auto& cell : mesh.quads) {
                    OnionQuad q;
                    q.texture = texture;
                    for (int k = 0; k < 4; ++k) {
                        q.corner[k] = to_world(mesh.position[cell[std::size_t(k)]]);
                        q.uv[k] = Vec2{u0 + (u1 - u0) * mesh.uv[cell[std::size_t(k)]].x, v0 + (v1 - v0) * mesh.uv[cell[std::size_t(k)]].y};
                    }
                    pose.quads.push_back(q);
                }
                continue;
            }
            OnionQuad q;
            q.texture = texture;
            const Vec2 c[4] = {{box.x0, box.y1}, {box.x1, box.y1}, {box.x1, box.y0}, {box.x0, box.y0}};
            const Vec2 uv[4] = {{u0, v0}, {u1, v0}, {u1, v1}, {u0, v1}};
            for (int k = 0; k < 4; ++k) {
                q.corner[k] = to_world(c[k]);
                q.uv[k] = uv[k];
            }
            pose.quads.push_back(q);
        }
        u.ghosts.push_back(std::move(pose));
    }
    anim_pose();  // back to the playhead
}

void Editor::anim_draw_onion(ImDrawList* dl, Renderer& r) {
    anim_.onionDrawn = 0;
    if (!anim_.onion || anim_.ghosts.empty()) return;
    const float tw = float(r.target_width()), th = float(r.target_height());
    auto to_vp = [&](Vec2 world) {
        const Vec2 d = r.world_to_screen(Vec3{world.x, world.y, 0});
        return ImVec2(vpImageMin_.x + d.x / tw * vpImageSize_.x, vpImageMin_.y + d.y / th * vpImageSize_.y);
    };
    const int maxSide = std::max(1, std::max(anim_.onionBefore, anim_.onionAfter));
    for (const OnionPose& pose : anim_.ghosts) {
        // Further from the playhead = fainter. Before the playhead red, after it green, like the usual onion skin.
        const int distance = 1 + int(std::lround(std::fabs(pose.t - anim_.playhead) * double(anim_.fps) / double(std::max(1, anim_.onionFrames)))) - 1;
        const float fade = 1.0f - 0.65f * float(std::min(distance, maxSide) - 1) / float(std::max(1, maxSide));
        const ImU32 tint = pose.side < 0 ? IM_COL32(255, 120, 110, int(110 * fade)) : IM_COL32(110, 255, 140, int(110 * fade));
        const ImU32 edge = pose.side < 0 ? IM_COL32(255, 120, 110, int(190 * fade)) : IM_COL32(110, 255, 140, int(190 * fade));
        for (const OnionQuad& q : pose.quads) {
            ImVec2 p[4];
            for (int k = 0; k < 4; ++k) p[k] = to_vp(q.corner[k]);
            if (!q.texture.empty()) {
                if (const TextureEntry* tex = texture_for(q.texture)) {
                    dl->AddImageQuad(ImTextureRef(ImTextureID(ui::texture_from_view(tex->view, true))), p[0], p[1], p[2], p[3],
                                     ImVec2(q.uv[0].x, q.uv[0].y), ImVec2(q.uv[1].x, q.uv[1].y), ImVec2(q.uv[2].x, q.uv[2].y),
                                     ImVec2(q.uv[3].x, q.uv[3].y), tint);
                    ++anim_.onionDrawn;
                    continue;
                }
            }
            dl->AddConvexPolyFilled(p, 4, tint);
            dl->AddPolyline(p, 4, edge, ImDrawFlags_Closed, 1.0f);
            ++anim_.onionDrawn;
        }
    }
}

void Editor::anim_draw_record_frame(ImDrawList* dl, ImVec2 imgMin, ImVec2 size) {
    if (!anim_recording()) return;
    const ImVec2 imgMax(imgMin.x + size.x, imgMin.y + size.y);
    dl->AddRectFilled(imgMin, imgMax, IM_COL32(255, 40, 40, 14));
    dl->AddRect(imgMin, imgMax, IM_COL32(255, 60, 50, 255), 0, 0, 4.0f);
    const std::string label = std::format("REC  {}  {:.2f}s", anim_.clipName, anim_.playhead);
    const ImVec2 ts = ImGui::CalcTextSize(label.c_str());
    const ImVec2 a(imgMin.x + 10, imgMin.y + 10);
    dl->AddRectFilled(a, ImVec2(a.x + ts.x + 26, a.y + ts.y + 8), IM_COL32(150, 20, 20, 230), 4.0f);
    dl->AddCircleFilled(ImVec2(a.x + 11, a.y + 4 + ts.y * 0.5f), 5.0f, IM_COL32(255, 90, 80, 255));
    dl->AddText(ImVec2(a.x + 21, a.y + 4), IM_COL32(255, 255, 255, 255), label.c_str());
}

}  // namespace fa::editor
