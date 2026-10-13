// Hierarchy panel: entity tree with parenting, rename, create, duplicate, delete, filter.
#include <algorithm>

#include "editor_internal.h"

namespace fa::editor {

namespace {
const char* kind_tag(World& w, Entity e) {
    if (w.has<Camera>(e)) return "Camera";
    if (w.has<Light>(e)) return "Light";
    if (w.has<MeshRenderer>(e)) return "Mesh";
    if (w.has<Sprite>(e)) return "Sprite";
    if (w.has<Shape2D>(e)) return "Shape";
    if (w.has<Text>(e)) return "Text";
    if (w.has<Tilemap>(e)) return "Tilemap";
    if (w.has<ParticleEmitter>(e)) return "Particles";
    if (w.has<AudioSource>(e)) return "Audio";
    if (w.has<Collider2D>(e) || w.has<Collider3D>(e)) return "Collider";
    return "";
}

void create_menu(Editor& ed, Entity parent) {
    if (ImGui::MenuItem("Empty")) ed.create_entity("empty", parent);
    if (ImGui::MenuItem("Sprite")) ed.create_entity("sprite", parent);
    if (ImGui::MenuItem("Shape")) ed.create_entity("shape", parent);
    if (ImGui::MenuItem("Camera")) ed.create_entity("camera", parent);
    if (ImGui::MenuItem("Light")) ed.create_entity("light", parent);
    if (ImGui::MenuItem("Mesh (cube)")) ed.create_entity("mesh", parent);
}
}  // namespace

static void hierarchy_node(Editor& ed, Entity e, const std::string& filter, bool flat) {
    World& w = ed.world();
    const std::string id = w.id_of(e);
    const EntityInfo& info = w.info(e);
    const auto& kids = w.children(e);
    const bool editing = ed.play_state() == PlayState::Edit;

    ImGui::PushID(int(e.index));
    ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags_OpenOnArrow | ImGuiTreeNodeFlags_SpanFullWidth | ImGuiTreeNodeFlags_DefaultOpen | ImGuiTreeNodeFlags_FramePadding;
    if (kids.empty() || flat) flags |= ImGuiTreeNodeFlags_Leaf;
    if (id == ed.selected_id()) flags |= ImGuiTreeNodeFlags_Selected;

    bool open;
    if (ed.renamingId_ == id) {
        open = false;
        ImGui::SetNextItemWidth(-1);
        if (ed.renameFocus_) { ImGui::SetKeyboardFocusHere(); ed.renameFocus_ = false; }
        std::string name = info.name;
        if (ImGui::InputText("##rename", &name, ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_AutoSelectAll)) {
            ed.begin_edit("rename:" + id);
            w.info(e).name = name;
            ed.renamingId_.clear();
        } else if (ImGui::IsItemDeactivated()) {
            ed.renamingId_.clear();
        }
    } else {
        const char* nm = info.name.empty() ? id.c_str() : info.name.c_str();
        ImGui::PushStyleColor(ImGuiCol_Text, info.active ? ImGui::GetStyleColorVec4(ImGuiCol_Text) : ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
        open = ImGui::TreeNodeEx("##node", flags, "%s", nm);
        ImGui::PopStyleColor();
        if (ImGui::IsItemClicked(ImGuiMouseButton_Left) && !ImGui::IsItemToggledOpen()) ed.select(e);
        if (ImGui::IsItemHovered() && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left)) {
            ed.renamingId_ = id;
            ed.renameFocus_ = true;
        }
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("id: %s", id.c_str());
        // Right-aligned kind tag.
        const char* tag = kind_tag(w, e);
        if (*tag) {
            ImVec2 ts = ImGui::CalcTextSize(tag);
            float x = ImGui::GetWindowPos().x + ImGui::GetWindowContentRegionMax().x - ts.x - 6;
            ImGui::GetWindowDrawList()->AddText(ImVec2(x, ImGui::GetItemRectMin().y + 3), IM_COL32(130, 140, 160, 255), tag);
        }
        // Drag & drop reparenting.
        if (editing && ImGui::BeginDragDropSource(ImGuiDragDropFlags_None)) {
            std::uint64_t bits = e.bits();
            ImGui::SetDragDropPayload("FA_ENTITY", &bits, sizeof bits);
            ImGui::Text("%s", nm);
            ImGui::EndDragDropSource();
        }
        if (editing && ImGui::BeginDragDropTarget()) {
            if (const ImGuiPayload* p = ImGui::AcceptDragDropPayload("FA_ENTITY")) {
                Entity child = Entity::from_bits(*static_cast<const std::uint64_t*>(p->Data));
                if (w.alive(child) && child != e && !w.is_ancestor(child, e)) {
                    ed.pendingReparent_ = true;
                    ed.pendingReparentChild_ = w.id_of(child);
                    ed.pendingReparentParent_ = id;
                }
            }
            ImGui::EndDragDropTarget();
        }
        if (ImGui::BeginPopupContextItem("##ctx")) {
            ed.select(e);
            ImGui::BeginDisabled(!editing);
            if (ImGui::BeginMenu("Create child")) { create_menu(ed, e); ImGui::EndMenu(); }
            if (ImGui::MenuItem("Rename", "double-click")) { ed.renamingId_ = id; ed.renameFocus_ = true; }
            if (ImGui::MenuItem("Duplicate", "Ctrl+D")) ed.duplicate_entity(e);
            if (ImGui::MenuItem("Unparent", nullptr, false, !w.parent(e).is_null())) {
                ed.begin_edit("unparent:" + id);
                w.set_parent(e, kNullEntity, true);
            }
            bool active = info.active;
            if (ImGui::MenuItem("Active", nullptr, &active)) {
                ed.begin_edit("active:" + id);
                w.set_active(e, active);
            }
            ImGui::Separator();
            if (ImGui::MenuItem("Delete", "Del")) {
                ImGui::EndDisabled();
                ImGui::EndPopup();
                if (open) ImGui::TreePop();
                ImGui::PopID();
                ed.delete_entity(e);
                return;
            }
            ImGui::EndDisabled();
            ImGui::EndPopup();
        }
    }
    if (open) {
        if (!flat) {
            std::vector<Entity> copy(kids.begin(), kids.end());
            for (Entity c : copy) hierarchy_node(ed, c, filter, flat);
        }
        ImGui::TreePop();
    }
    ImGui::PopID();
}

void Editor::draw_hierarchy() {
    if (!ImGui::Begin("Hierarchy", &showHierarchy_)) { ImGui::End(); return; }
    World& w = world();
    const bool editing = play_ == PlayState::Edit;
    ImGui::SetNextItemWidth(-62);
    ImGui::InputTextWithHint("##filter", "Filter...", &hierFilter_);
    ImGui::SameLine();
    if (ImGui::Button("+ New")) ImGui::OpenPopup("##create_root");
    if (ImGui::BeginPopup("##create_root")) {
        ImGui::BeginDisabled(!editing);
        create_menu(*this, kNullEntity);
        ImGui::EndDisabled();
        ImGui::EndPopup();
    }
    ImGui::Separator();

    ImGui::BeginChild("##tree", ImVec2(0, 0), ImGuiChildFlags_None);
    const bool flat = !hierFilter_.empty();
    if (flat) {
        for (Entity e : w.entities()) {
            const EntityInfo& info = w.info(e);
            if (contains_ci(info.name, hierFilter_) || contains_ci(info.id, hierFilter_)) hierarchy_node(*this, e, hierFilter_, true);
        }
    } else {
        for (Entity e : w.roots()) hierarchy_node(*this, e, hierFilter_, false);
    }
    // Drop on empty space = unparent.
    ImVec2 rest = ImGui::GetContentRegionAvail();
    if (rest.y > 4) {
        ImGui::InvisibleButton("##empty", ImVec2(std::max(1.0f, rest.x), std::max(1.0f, rest.y)));
        if (ImGui::IsItemClicked()) select(kNullEntity);
        if (editing && ImGui::BeginDragDropTarget()) {
            if (const ImGuiPayload* p = ImGui::AcceptDragDropPayload("FA_ENTITY")) {
                Entity child = Entity::from_bits(*static_cast<const std::uint64_t*>(p->Data));
                if (w.alive(child) && !w.parent(child).is_null()) {
                    begin_edit("unparent:" + w.id_of(child));
                    w.set_parent(child, kNullEntity, true);
                }
            }
            ImGui::EndDragDropTarget();
        }
        if (ImGui::BeginPopupContextItem("##ctx_empty")) {
            ImGui::BeginDisabled(!editing);
            create_menu(*this, kNullEntity);
            ImGui::EndDisabled();
            ImGui::EndPopup();
        }
    }
    ImGui::EndChild();

    if (pendingReparent_) {
        pendingReparent_ = false;
        Entity c = w.find_by_id(pendingReparentChild_), p = w.find_by_id(pendingReparentParent_);
        if (!c.is_null() && !p.is_null()) {
            begin_edit("reparent:" + pendingReparentChild_);
            w.set_parent(c, p, true);
        }
    }
    if (ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows) && editing && !ImGui::GetIO().WantTextInput &&
        ImGui::IsKeyPressed(ImGuiKey_Delete, false))
        delete_entity(selected());
    ImGui::End();
}

}  // namespace fa::editor
