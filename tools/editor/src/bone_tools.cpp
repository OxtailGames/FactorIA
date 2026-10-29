// Bone tools (View > Bone tools): draw a chain of bones by clicking points in the viewport (bones.create), bind a sprite to bones
// (skin.bind), see the weights of one bone as coloured dots on the sprite's mesh and paint them with a brush (skin.set_weights),
// and drag the targets of IK2D chains. Each edit is one command through edit_command, so it is on the undo stack, in the scene
// file and visible to an AI; a brush stroke or a handle drag shares one undo step.
#include <algorithm>
#include <cmath>
#include <format>

#include "editor_internal.h"
#include "gizmo_model.h"
#include "imgui_internal.h"

namespace fa::editor {

namespace {

constexpr float kHandlePx = 9.0f;

// The viewport image <-> world mapping of this frame.
struct VpMap {
    Renderer* r = nullptr;
    ImVec2 imgMin{}, size{};
    Vec2 design(ImVec2 m) const {
        return Vec2{(m.x - imgMin.x) / size.x * float(r->target_width()), (m.y - imgMin.y) / size.y * float(r->target_height())};
    }
    Vec3 to_world(ImVec2 m, float z) const { return r->screen_to_world(design(m), z); }
    ImVec2 to_screen(Vec3 w) const {
        const Vec2 d = r->world_to_screen(w);
        return ImVec2(imgMin.x + d.x / float(r->target_width()) * size.x, imgMin.y + d.y / float(r->target_height()) * size.y);
    }
};

Vec2 local_point(const World& w, Entity e, Vec3 world) {
    const Vec3 v = w.world_matrix(e).inverse().transform_point(world);
    return Vec2{v.x, v.y};
}

bool grid_of(const World& w, Entity e, const SkinBox& box, int& cols, int& rows) {
    const Sprite* s = w.get<Sprite>(e);
    const SpriteSkin* k = w.get<SpriteSkin>(e);
    if (!s || !k) return false;
    if (k->outline) {
        skin_outline_dimensions(box, k->outlineDetail, cols, rows);
        return cols > 0 && rows > 0;
    }
    return sprite_mesh_grid(*s, cols, rows);
}

Vec2 vertex_local(const SkinBox& box, int cols, int rows, int r, int c) {
    return Vec2{box.x0 + (box.x1 - box.x0) * float(c) / float(cols), box.y1 + (box.y0 - box.y1) * float(r) / float(rows)};
}

// The weight of `bone` at each vertex (row-major from the top row); the automatic ones when the skin has not been painted yet.
std::vector<float> bone_weights(const World& w, Entity e, const SkinBox& box, int bone, std::size_t total) {
    std::vector<float> out(total, 0.0f);
    const SpriteSkin* skin = w.get<SpriteSkin>(e);
    if (!skin) return out;
    Json explicitWeights;
    if (skin->weights.is_array() && skin->weights.size() >= total) {
        explicitWeights = skin->weights;
    } else {
        auto automatic = skin_auto_weights(w, e, box);
        if (!automatic.ok()) return out;
        explicitWeights = *automatic;
    }
    for (std::size_t i = 0; i < total && i < explicitWeights.size(); ++i) {
        const Json& entry = explicitWeights[i];
        if (!entry.is_array()) continue;
        for (std::size_t k = 0; k + 1 < entry.size(); k += 2)
            if (entry[k].is_number() && entry[k + 1].is_number() && entry[k].get<int>() == bone) out[i] += entry[k + 1].get<float>();
    }
    return out;
}

ImU32 heat(float weight, int alpha) {
    const float t = std::clamp(weight, 0.0f, 1.0f);
    // blue (none) -> green -> red (full)
    const float r = t < 0.5f ? 0.0f : (t - 0.5f) * 2.0f, g = t < 0.5f ? t * 2.0f : 1.0f - (t - 0.5f) * 2.0f, b = t < 0.5f ? 1.0f - t * 2.0f : 0.0f;
    return IM_COL32(int(40 + 215 * r), int(60 + 195 * g), int(60 + 195 * b), alpha);
}

std::vector<Entity> all_bones(const World& w) {
    std::vector<Entity> out;
    for (Entity e : w.entities_with(TypeRegistry::global().of<Bone2D>())) out.push_back(e);
    return out;
}

// "hero/leg/thigh": the names from the top down, so two bones called alike can be told apart in a list.
std::string path_name(const World& w, Entity e) {
    std::string out = w.info(e).name;
    for (Entity p = w.parent(e); !p.is_null(); p = w.parent(p)) out = w.info(p).name + "/" + out;
    return out;
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------ the skin --
Entity Editor::bone_skin_entity() {
    if (!engine_) return kNullEntity;
    World& w = world();
    const Entity sel = selected();
    if (!sel.is_null() && w.has<Sprite>(sel) && w.has<SpriteSkin>(sel)) bone_.skinId = w.id_of(sel);
    if (bone_.skinId.empty()) return kNullEntity;
    const Entity e = w.find_by_id(bone_.skinId);
    if (e.is_null() || !w.alive(e) || !w.has<Sprite>(e) || !w.has<SpriteSkin>(e)) return kNullEntity;
    return e;
}

// ----------------------------------------------------------------------------------------------------------- the chain --
void Editor::bone_cancel_chain() {
    bone_.chain.clear();
    bone_.chainParent.clear();
}

void Editor::bone_finish_chain() {
    if (!engine_) return;
    World& w = world();
    if (bone_.chain.size() < 2) {
        bone_.error = "A chain needs at least two points: click where the first bone starts and where it ends.";
        return;
    }
    const Entity parent = w.find_by_id(bone_.chainParent);
    if (parent.is_null() || !w.alive(parent)) {
        bone_.error = "The entity the chain hangs from is gone. Select it and draw again.";
        bone_cancel_chain();
        return;
    }
    // Two bones with one name under one parent are refused (a clip finds a bone by name): pick the next free prefix.
    std::string prefix = bone_.chainPrefix.empty() ? "bone" : bone_.chainPrefix;
    const std::string base = prefix;
    for (int n = 2;; ++n) {
        bool taken = false;
        for (Entity c : w.children(parent)) taken = taken || w.info(c).name == prefix + "_1";
        if (!taken) break;
        prefix = base + std::to_string(n);
    }
    Json points = Json::array();
    for (const Vec2& p : bone_.chain) points.push_back(Json::array({std::round(p.x * 100.0f) / 100.0f, std::round(p.y * 100.0f) / 100.0f}));
    std::string err;
    const CommandResult r = edit_command("bone:chain:" + std::to_string(uiFrame_), "bones.create",
                                         Json::object({{"parent", w.id_of(parent)}, {"points", points}, {"prefix", prefix}}), &err);
    if (!r.ok) {
        bone_.error = "bones.create: " + err;
        notify("Could not make the bones: " + err, 2);
        return;
    }
    bone_.error.clear();
    if (r.result.contains("bones") && !r.result["bones"].empty()) {
        const Entity first = w.find_by_id(r.result["bones"][0].value("id", std::string()));
        if (!first.is_null()) select(first);
        if (bone_.bindRoot.empty()) bone_.bindRoot = r.result["bones"][0].value("id", std::string());
    }
    notify(std::format("Made {} bone{} under '{}'.", bone_.chain.size() - 1, bone_.chain.size() == 2 ? "" : "s", w.info(parent).name), 0);
    bone_cancel_chain();
}

// -------------------------------------------------------------------------------------------------------------- bind --
bool Editor::bone_bind(std::string* error) {
    auto fail = [&](const std::string& m) {
        bone_.error = m;
        if (error) *error = m;
        return false;
    };
    if (!engine_) return fail("No project is open.");
    World& w = world();
    Entity sprite = selected();
    if (sprite.is_null() || !w.has<Sprite>(sprite)) {
        sprite = bone_.skinId.empty() ? kNullEntity : w.find_by_id(bone_.skinId);
        if (sprite.is_null() || !w.alive(sprite) || !w.has<Sprite>(sprite)) return fail("Select the sprite to bind first (the entity with the Sprite).");
    }
    const Entity root = bone_.bindRoot.empty() ? kNullEntity : w.find_by_id(bone_.bindRoot);
    if (root.is_null() || !w.alive(root) || !w.has<Bone2D>(root)) return fail("Pick the root bone: the bound bones are it and every bone below it.");
    std::string err;
    const CommandResult r = edit_command("bone:bind:" + std::to_string(uiFrame_), "skin.bind",
                                         Json::object({{"entity", w.id_of(sprite)}, {"root", w.id_of(root)},
                                                       {"mesh", Json::array({std::max(1, bone_.meshColumns), std::max(1, bone_.meshRows)})}}), &err);
    if (!r.ok) return fail("skin.bind: " + err);
    bone_.error.clear();
    bone_.skinId = w.id_of(sprite);
    bone_.boneIndex = 0;
    if (r.result.contains("note") && r.result["note"].is_string()) notify(r.result["note"].get<std::string>(), 1);
    return true;
}

// ------------------------------------------------------------------------------------------------------------ painting --
bool Editor::bone_paint_at(Vec2 localPoint, bool firstOfStroke) {
    World& w = world();
    const Entity e = bone_skin_entity();
    if (e.is_null()) return false;
    const SkinBox box = sprite_local_box(e);
    int cols = 0, rows = 0;
    if (!grid_of(w, e, box, cols, rows)) {
        bone_.error = "The sprite has no mesh grid to paint: bind it with a mesh (columns x rows) first.";
        return false;
    }
    if (!firstOfStroke && bone_.hasDab) {  // a still mouse paints nothing more
        const float dx = localPoint.x - bone_.lastDab.x, dy = localPoint.y - bone_.lastDab.y;
        if (std::sqrt(dx * dx + dy * dy) < std::max(1.0f, bone_.radius * 0.25f)) return false;
    }
    Json vertices = Json::array();
    const float r2 = bone_.radius * bone_.radius;
    for (int r = 0; r <= rows; ++r)
        for (int c = 0; c <= cols; ++c) {
            const Vec2 v = vertex_local(box, cols, rows, r, c);
            const float dx = v.x - localPoint.x, dy = v.y - localPoint.y;
            if (dx * dx + dy * dy <= r2) vertices.push_back(r * (cols + 1) + c);
        }
    if (vertices.empty()) return false;
    static const char* modes[] = {"add", "set", "smooth"};
    const int mode = std::clamp(bone_.mode, 0, 2);
    Json args = Json::object({{"entity", w.id_of(e)}, {"vertices", vertices}, {"mode", modes[mode]}, {"weight", std::round(bone_.strength * 1000.0f) / 1000.0f}});
    if (mode != 2) args["bone"] = bone_.boneIndex;
    if (firstOfStroke || bone_.paintKey.empty()) bone_.paintKey = "bone:paint:" + std::to_string(uiFrame_);
    if (lastEditKey_ == bone_.paintKey) lastEditTime_ = time_;  // one stroke, one undo step, however slowly it goes
    std::string err;
    const CommandResult res = edit_command(bone_.paintKey, "skin.set_weights", args, &err);
    if (!res.ok) {
        bone_.error = "skin.set_weights: " + err;
        return false;
    }
    bone_.error.clear();
    bone_.lastDab = localPoint;
    bone_.hasDab = true;
    ++bone_.strokes;
    return true;
}

// ------------------------------------------------------------------------------------------------------------ viewport --
bool Editor::bone_tools_frame(Renderer& r, ImVec2 imgMin, ImVec2 size, bool hovered) {
    if (!bone_tools_active() || !engine_ || r.target_width() <= 0) return false;
    World& w = world();
    ImGuiIO& io = ImGui::GetIO();
    const VpMap map{&r, imgMin, size};
    bone_.ikHandles = 0;

    if (bone_.tool == BoneTool::Chain) {
        const bool keys = (vpHovered_ || vpFocused_) && !io.WantTextInput;
        if (keys && ImGui::IsKeyPressed(ImGuiKey_Escape, false)) bone_cancel_chain();
        if (keys && (ImGui::IsKeyPressed(ImGuiKey_Enter, false) || ImGui::IsKeyPressed(ImGuiKey_KeypadEnter, false))) bone_finish_chain();
        if (hovered && ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
            Entity parent = bone_.chainParent.empty() ? selected() : w.find_by_id(bone_.chainParent);
            if (parent.is_null() || !w.alive(parent)) {
                bone_.error = "Select the entity the bones hang from first (a character's root, or another bone to extend it).";
                notify(bone_.error, 1);
                return true;
            }
            bone_.chainParent = w.id_of(parent);
            const Vec2 p = local_point(w, parent, map.to_world(io.MousePos, w.world_position(parent).z));
            if (bone_.chain.empty() || std::hypot(p.x - bone_.chain.back().x, p.y - bone_.chain.back().y) > 0.5f) bone_.chain.push_back(p);
            bone_.error.clear();
            return true;
        }
        return false;
    }

    if (bone_.tool == BoneTool::Weights) {
        const Entity e = bone_skin_entity();
        if (e.is_null()) return false;
        if (bone_.painting && !io.MouseDown[0]) {
            bone_.painting = false;
            bone_.hasDab = false;
            bone_.paintKey.clear();
        }
        if (hovered && ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
            bone_.painting = true;
            bone_.hasDab = false;
            const Vec2 p = local_point(w, e, map.to_world(io.MousePos, w.world_position(e).z));
            (void)bone_paint_at(p, true);
            return true;
        }
        if (bone_.painting && io.MouseDown[0]) {
            const Vec2 p = local_point(w, e, map.to_world(io.MousePos, w.world_position(e).z));
            (void)bone_paint_at(p, false);
            return true;
        }
        return false;
    }

    if (bone_.tool == BoneTool::Ik) {
        // Handles at the targets of the IK2D chains; dragging one moves the target entity and solves the chain.
        struct H { Entity ik, target; ImVec2 pos; };
        std::vector<H> handles;
        for (Entity ik : w.entities_with(TypeRegistry::global().of<IK2D>())) {
            const IK2D* c = w.get<IK2D>(ik);
            if (!c || c->target.is_null() || !w.alive(c->target)) continue;
            handles.push_back({ik, c->target, map.to_screen(w.world_position(c->target))});
        }
        bone_.ikHandles = int(handles.size());
        if (!bone_.ikTarget.empty() && !io.MouseDown[0]) {
            bone_.ikTarget.clear();
            bone_.ikKey.clear();
        }
        if (!bone_.ikTarget.empty()) {
            const Entity target = w.find_by_id(bone_.ikTarget);
            if (target.is_null() || !w.alive(target)) {
                bone_.ikTarget.clear();
                return false;
            }
            if (lastEditKey_ == bone_.ikKey) lastEditTime_ = time_;
            if (ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
                bone_.ikTarget.clear();
                return true;
            }
            const Vec3 world = map.to_world(io.MousePos, w.world_position(target).z);
            const Entity parent = w.parent(target);
            Vec3 local = world;
            if (!parent.is_null()) local = w.world_matrix(parent).inverse().transform_point(world);
            const Transform* t = w.get<Transform>(target);
            if (t) {
                const Vec3 v{std::round(local.x * 100.0f) / 100.0f, std::round(local.y * 100.0f) / 100.0f, t->position.z};
                if (v.x != t->position.x || v.y != t->position.y) {
                    std::string err;
                    const CommandResult res = edit_command(bone_.ikKey, "scene.set_component",
                                                           field_edit_args(bone_.ikTarget, "Transform", "position", Json::array({v.x, v.y, v.z})), &err);
                    if (!res.ok) bone_.error = "Could not move the target: " + err;
                    else update_ik2d(w);  // the editor does not tick the engine: solve the chains now so the bones follow
                }
            }
            return true;
        }
        for (const H& h : handles) {
            at_track_at("bone:ik:" + w.info(h.target).name, Vec2{h.pos.x, h.pos.y});
        }
        if (hovered && ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
            const H* best = nullptr;
            float bd = kHandlePx * 1.6f;
            for (const H& h : handles) {
                const float d = std::hypot(h.pos.x - io.MousePos.x, h.pos.y - io.MousePos.y);
                if (d < bd) {
                    bd = d;
                    best = &h;
                }
            }
            if (best) {
                bone_.ikTarget = w.id_of(best->target);
                bone_.ikKey = "bone:ik:" + bone_.ikTarget + ":" + std::to_string(uiFrame_);
                select(best->ik);
                return true;
            }
        }
        return false;
    }
    return false;
}

void Editor::bone_tools_draw(ImDrawList* dl, Renderer& r, ImVec2 imgMin, ImVec2 size) {
    bone_.weightDots = 0;
    if (!bone_tools_active() || !engine_ || r.target_width() <= 0) return;
    World& w = world();
    const VpMap map{&r, imgMin, size};
    const ImVec2 mouse = ImGui::GetIO().MousePos;

    if (bone_.tool == BoneTool::Chain) {
        const Entity parent = bone_.chainParent.empty() ? kNullEntity : w.find_by_id(bone_.chainParent);
        std::vector<ImVec2> pts;
        if (!parent.is_null() && w.alive(parent)) {
            const Mat4 m = w.world_matrix(parent);
            for (const Vec2& p : bone_.chain) pts.push_back(map.to_screen(m.transform_point(Vec3{p.x, p.y, 0})));
        }
        for (std::size_t i = 0; i + 1 < pts.size(); ++i) dl->AddLine(pts[i], pts[i + 1], IM_COL32(255, 205, 60, 255), 2.5f);
        if (!pts.empty() && vpHovered_) dl->AddLine(pts.back(), mouse, IM_COL32(255, 205, 60, 120), 1.5f);
        for (const ImVec2& p : pts) {
            dl->AddCircleFilled(p, 5.0f, IM_COL32(255, 205, 60, 255));
            dl->AddCircle(p, 5.5f, IM_COL32(0, 0, 0, 200));
        }
        return;
    }

    if (bone_.tool == BoneTool::Weights) {
        const Entity e = bone_skin_entity();
        if (e.is_null()) return;
        const SkinBox box = sprite_local_box(e);
        int cols = 0, rows = 0;
        if (!grid_of(w, e, box, cols, rows)) return;
        const std::size_t total = std::size_t(cols + 1) * std::size_t(rows + 1);
        const std::vector<float> weights = bone_weights(w, e, box, bone_.boneIndex, total);
        const Mat4 m = w.world_matrix(e);
        for (int rr = 0; rr <= rows; ++rr)
            for (int c = 0; c <= cols; ++c) {
                const Vec2 v = vertex_local(box, cols, rows, rr, c);
                const ImVec2 p = map.to_screen(m.transform_point(Vec3{v.x, v.y, 0}));
                const float wt = weights[std::size_t(rr) * std::size_t(cols + 1) + std::size_t(c)];
                dl->AddCircleFilled(p, 3.0f + 3.5f * wt, heat(wt, 215));
                dl->AddCircle(p, 3.0f + 3.5f * wt, IM_COL32(0, 0, 0, 160));
                ++bone_.weightDots;
            }
        if (vpHovered_) {  // the brush
            const Vec3 c0 = m.transform_point(Vec3{0, 0, 0}), c1 = m.transform_point(Vec3{bone_.radius, 0, 0});
            const ImVec2 a = map.to_screen(c0), b = map.to_screen(c1);
            dl->AddCircle(mouse, std::max(3.0f, std::hypot(b.x - a.x, b.y - a.y)), IM_COL32(255, 255, 255, 220), 32, 1.5f);
        }
        return;
    }

    if (bone_.tool == BoneTool::Ik) {
        for (Entity ik : w.entities_with(TypeRegistry::global().of<IK2D>())) {
            const IK2D* c = w.get<IK2D>(ik);
            if (!c || c->target.is_null() || !w.alive(c->target)) continue;
            const ImVec2 p = map.to_screen(w.world_position(c->target));
            const ImVec2 tip = map.to_screen(Vec3{bone_world_segment(w, ik).tip.x, bone_world_segment(w, ik).tip.y, w.world_position(ik).z});
            const bool live = bone_.ikTarget == w.id_of(c->target);
            const bool hot = live || std::hypot(p.x - mouse.x, p.y - mouse.y) < kHandlePx * 1.6f;
            const ImU32 col = hot ? IM_COL32(255, 235, 120, 255) : IM_COL32(255, 140, 60, 255);
            if (w.has<Bone2D>(ik)) dl->AddLine(tip, p, IM_COL32(255, 140, 60, 120), 1.5f);
            dl->AddQuadFilled(ImVec2(p.x, p.y - kHandlePx), ImVec2(p.x + kHandlePx, p.y), ImVec2(p.x, p.y + kHandlePx), ImVec2(p.x - kHandlePx, p.y), col);
            dl->AddQuad(ImVec2(p.x, p.y - kHandlePx), ImVec2(p.x + kHandlePx, p.y), ImVec2(p.x, p.y + kHandlePx), ImVec2(p.x - kHandlePx, p.y), IM_COL32(0, 0, 0, 220), 1.5f);
            dl->AddText(ImVec2(p.x + kHandlePx + 3, p.y - 7), col, w.info(c->target).name.c_str());
        }
    }
}

// ----------------------------------------------------------------------------------------------------------- the panel --
void Editor::draw_bone_tools_panel() {
    if (ImGuiWindow* insp = ImGui::FindWindowByName("Inspector"); insp && insp->DockId != 0)
        ImGui::SetNextWindowDockID(insp->DockId, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(360, 520), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Bone tools", &showBoneTools_)) {
        ImGui::End();
        return;
    }
    if (play_ != PlayState::Edit) {
        ImGui::TextDisabled("Stop the game to edit bones: the tools change the scene.");
        ImGui::End();
        return;
    }
    if (!primary_is_ortho()) {
        ImGui::TextWrapped("The bone tools draw in the 2D view. This scene's main camera is not orthographic.");
        ImGui::End();
        return;
    }
    World& w = world();
    BoneUi& b = bone_;
    auto mode_button = [&](const char* label, BoneTool tool, const char* id, const char* tip) {
        const bool on = b.tool == tool;
        if (on) ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.24f, 0.42f, 0.70f, 1));
        if (ImGui::Button(label)) {
            if (b.tool == BoneTool::Chain && tool != BoneTool::Chain) bone_cancel_chain();
            b.tool = on ? BoneTool::Off : tool;
            b.painting = false;
            b.ikTarget.clear();
        }
        if (on) ImGui::PopStyleColor();
        at_track(id);
        ImGui::SetItemTooltip("%s", tip);
        ImGui::SameLine();
    };
    mode_button(" Draw chain ", BoneTool::Chain, "bone:tool:chain", "Click points in the viewport to lay a chain of bones; Enter finishes, Esc cancels");
    mode_button(" Weights ", BoneTool::Weights, "bone:tool:weights", "Show and paint how much one bone moves each vertex of the selected skinned sprite");
    mode_button(" IK targets ", BoneTool::Ik, "bone:tool:ik", "Drag the targets of the IK2D chains in the viewport");
    ImGui::NewLine();
    if (b.tool == BoneTool::Off) {
        ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
        ImGui::TextWrapped("Pick a tool. While one is on the viewport gizmo is off (click the tool again to leave it).");
        ImGui::PopStyleColor();
    }

    // ---- chain
    if (b.tool == BoneTool::Chain) {
        ImGui::SeparatorText("Draw a chain");
        const Entity parent = b.chainParent.empty() ? selected() : w.find_by_id(b.chainParent);
        ImGui::TextWrapped("Click in the viewport to place the joints, from the root to the tip. The bones hang from: %s",
                           parent.is_null() ? "(select an entity first)" : w.info(parent).name.c_str());
        ImGui::SetNextItemWidth(140);
        ImGui::InputText("name prefix", &b.chainPrefix);
        ImGui::SetItemTooltip("Bones are called <prefix>_1, <prefix>_2 ... (a free prefix is picked when the name is taken)");
        at_track("bone:chain:prefix");
        ImGui::Text("%zu point%s, %zu bone%s", b.chain.size(), b.chain.size() == 1 ? "" : "s", b.chain.size() > 1 ? b.chain.size() - 1 : 0,
                    b.chain.size() == 2 ? "" : "s");
        ImGui::BeginDisabled(b.chain.size() < 2);
        if (ImGui::Button("Finish chain (Enter)")) bone_finish_chain();
        at_track("bone:chain:finish", b.chain.size() >= 2);
        ImGui::EndDisabled();
        ImGui::SameLine();
        ImGui::BeginDisabled(b.chain.empty());
        if (ImGui::Button("Cancel (Esc)")) bone_cancel_chain();
        at_track("bone:chain:cancel", !b.chain.empty());
        ImGui::EndDisabled();
    }

    // ---- bind
    ImGui::SeparatorText("Bind a sprite to bones");
    {
        Entity sprite = selected();
        if (sprite.is_null() || !w.has<Sprite>(sprite)) sprite = b.skinId.empty() ? kNullEntity : w.find_by_id(b.skinId);
        ImGui::TextWrapped("Sprite: %s", (!sprite.is_null() && w.alive(sprite) && w.has<Sprite>(sprite)) ? w.info(sprite).name.c_str() : "(select the entity with the Sprite)");
        const std::vector<Entity> bones = all_bones(w);
        Entity root = b.bindRoot.empty() ? kNullEntity : w.find_by_id(b.bindRoot);
        if (!root.is_null() && !w.alive(root)) root = kNullEntity;
        ImGui::SetNextItemWidth(200);
        if (ImGui::BeginCombo("root bone", root.is_null() ? "(pick one)" : path_name(w, root).c_str())) {
            for (Entity e : bones) {
                if (ImGui::Selectable(path_name(w, e).c_str(), e == root)) b.bindRoot = w.id_of(e);
                at_track("bone:bindroot:" + w.info(e).name);
            }
            ImGui::EndCombo();
        }
        at_track("bone:bindroot");
        ImGui::SetItemTooltip("The skin follows this bone and every bone below it");
        if (ImGui::Button("Use the selected bone") && !selected().is_null() && w.has<Bone2D>(selected())) b.bindRoot = w.id_of(selected());
        at_track("bone:bindselected");
        ImGui::SetNextItemWidth(60);
        ImGui::DragInt("mesh columns", &b.meshColumns, 0.2f, 1, 64);
        ImGui::SetNextItemWidth(60);
        ImGui::DragInt("mesh rows", &b.meshRows, 0.2f, 1, 64);
        ImGui::SetItemTooltip("The grid the sprite is cut into; weights are painted per grid vertex. 4 x 8 is plenty for a limb");
        if (ImGui::Button("Bind sprite to bones")) {
            std::string err;
            if (!bone_bind(&err)) notify(err, 1);
        }
        at_track("bone:bind");
        ImGui::SetItemTooltip("skin.bind: adds the SpriteSkin, names its bones and records the bind pose (the picture does not change)");
    }

    // ---- weights
    if (b.tool == BoneTool::Weights) {
        ImGui::SeparatorText("Paint weights");
        const Entity e = bone_skin_entity();
        if (e.is_null()) {
            ImGui::TextWrapped("Select a sprite that is bound to bones (Bind a sprite to bones above). Its mesh shows as dots coloured by the weight of the bone you pick.");
        } else {
            const SpriteSkin* skin = w.get<SpriteSkin>(e);
            const SkinBones resolved = skin_resolve_bones(w, e, *skin);
            ImGui::Text("Skin: %s, %zu bone%s", w.info(e).name.c_str(), resolved.entities.size(), resolved.entities.size() == 1 ? "" : "s");
            // The selected bone, when the skin has it, is the one shown.
            const Entity sel = selected();
            for (std::size_t i = 0; i < resolved.entities.size(); ++i)
                if (!sel.is_null() && resolved.entities[i] == sel && b.boneIndex != int(i) && !b.painting) b.boneIndex = int(i);
            b.boneIndex = std::clamp(b.boneIndex, 0, std::max(0, int(resolved.entities.size()) - 1));
            std::string current = "(none)";
            if (std::size_t(b.boneIndex) < resolved.entities.size() && !resolved.entities[std::size_t(b.boneIndex)].is_null())
                current = w.info(resolved.entities[std::size_t(b.boneIndex)]).name;
            ImGui::SetNextItemWidth(200);
            if (ImGui::BeginCombo("bone", current.c_str())) {
                for (std::size_t i = 0; i < resolved.entities.size(); ++i) {
                    if (resolved.entities[i].is_null()) continue;
                    if (ImGui::Selectable(w.info(resolved.entities[i]).name.c_str(), int(i) == b.boneIndex)) b.boneIndex = int(i);
                    at_track("bone:weights:bone:" + w.info(resolved.entities[i]).name);
                }
                ImGui::EndCombo();
            }
            at_track("bone:weights:bone");
            ImGui::SetItemTooltip("Selecting a bone of the skin in the Hierarchy picks it here");
            static const char* names[] = {"Add", "Set", "Smooth"};
            for (int i = 0; i < 3; ++i) {
                if (ImGui::RadioButton(names[i], b.mode == i)) b.mode = i;
                at_track(std::string("bone:mode:") + (i == 0 ? "add" : i == 1 ? "set" : "smooth"));
                ImGui::SameLine();
            }
            ImGui::NewLine();
            ImGui::SetItemTooltip("Add: raise the bone's weight by the strength. Set: give the bone exactly that weight. Smooth: blend toward the neighbours");
            ImGui::SetNextItemWidth(200);
            ImGui::SliderFloat("radius", &b.radius, 2.0f, 200.0f, "%.0f");
            at_track("bone:radius");
            ImGui::SetItemTooltip("Brush radius, in the sprite's own units");
            ImGui::SetNextItemWidth(200);
            ImGui::SliderFloat("strength", &b.strength, 0.0f, 1.0f, "%.2f");
            at_track("bone:strength");
            ImGui::SetItemTooltip("The weight added, set or blended per dab");
            if (ImGui::Button("Start from automatic weights")) {
                std::string err;
                const CommandResult r = edit_command("bone:autoweights:" + std::to_string(uiFrame_), "skin.auto_weights",
                                                     Json::object({{"entity", w.id_of(e)}}), &err);
                if (!r.ok) notify("skin.auto_weights: " + err, 1);
            }
            at_track("bone:autoweights");
            ImGui::SetItemTooltip("Write the automatic weights into the skin, to paint over");
            ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
            ImGui::TextWrapped("Drag over the sprite in the viewport to paint; one stroke is one undo step.");
            ImGui::PopStyleColor();
        }
    }

    if (b.tool == BoneTool::Ik) {
        ImGui::SeparatorText("IK targets");
        int n = 0;
        for (Entity ik : w.entities_with(TypeRegistry::global().of<IK2D>())) {
            const IK2D* c = w.get<IK2D>(ik);
            if (!c || c->target.is_null() || !w.alive(c->target)) continue;
            ++n;
            ImGui::BulletText("%s -> %s", w.info(ik).name.c_str(), w.info(c->target).name.c_str());
        }
        if (n == 0) ImGui::TextWrapped("No IK2D with a target in this scene. Add an IK2D to the last bone of a chain and set its target.");
        else ImGui::TextWrapped("Drag the diamonds in the viewport. The bones turn to follow; the pose stays in the bones' rotation until you change it.");
    }
    if (!b.error.empty()) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", b.error.c_str());
    ImGui::End();
}

}  // namespace fa::editor
