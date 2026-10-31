// Hierarchy panel: the entity tree (roots and children), selection shared with the viewport, drag and drop to reparent
// (scene.set_parent), a context menu (create child, duplicate, rename, active, delete) and a search box. Nothing here edits the
// world directly: every change is a command call through Editor::edit_command, the path the Console and the AI use, so undo and
// the scene file come with it. The logic that can be tested without a window is in inspector_model.h.
#include <algorithm>
#include <cfloat>
#include <set>

#include "editor_internal.h"

namespace fa::editor {

CommandResult Editor::edit_command(const std::string& key, const std::string& name, const Json& args, std::string* error) {
    CommandResult r;
    if (!engine_) {
        r.error = Json::object({{"message", "No project is open."}});
        if (error) *error = "No project is open.";
        return r;
    }
    lastEditRecorded_ = false;
    // Record mode (Animation panel): a change of an animatable field of a part of the animated entity becomes a key at the
    // playhead; the scene keeps its rest value.
    if (play_ == PlayState::Edit && name == "scene.set_component" && anim_recording() && anim_record_edit(key, args, r, error)) {
        lastEditRecorded_ = r.ok;
        return r;
    }
    const CommandInfo* ci = engine_->commands().info(name);
    const bool snapshot = play_ == PlayState::Edit && ci && !ci->readOnly && command_edits_scene(name, args);
    if (snapshot && anim_.posed) {  // the undo step and the file must hold rest values, not the pose; the panel poses again
        anim_unpose();
        anim_.dirtyPose = true;
    }
    // begin_edit pushes the undo step before the call. A refused call must not leave an empty step (or lose the redo list), so
    // what begin_edit changes is put back when the command fails.
    std::vector<Json> savedRedo;
    std::string savedKey;
    double savedTime = 0;
    bool savedDirty = false, pushed = false;
    if (snapshot) {
        savedRedo = std::move(redo_);
        redo_.clear();
        savedKey = lastEditKey_;
        savedTime = lastEditTime_;
        savedDirty = dirty_;
        pushed = !(key == lastEditKey_ && (time_ - lastEditTime_) < 0.8);
        begin_edit(key);
    }
    r = engine_->commands().call(name, args);
    after_command(name, args, r);
    if (!r.ok && snapshot) {
        if (pushed && !undo_.empty()) undo_.pop_back();
        redo_ = std::move(savedRedo);
        lastEditKey_ = savedKey;
        lastEditTime_ = savedTime;
        dirty_ = savedDirty;
    }
    if (!r.ok && error) *error = command_error_text(r.error);
    return r;
}

void draw_play_banner(const Editor& ed) {
    if (ed.play_state() == PlayState::Edit) return;
    ImGui::PushStyleColor(ImGuiCol_Text, kStatusWarn);
    ImGui::TextWrapped("Game running: edits change the running game and are lost on Stop.");
    ImGui::PopStyleColor();
}

void Editor::hierarchy_spawn(const std::string& parentId, const std::string& name) {
    Json args = Json::object({{"name", name}});
    if (!parentId.empty()) args["parent"] = parentId;
    std::string err;
    CommandResult r = edit_command("hier:spawn:" + std::to_string(uiFrame_), "scene.spawn", args, &err);
    if (!r.ok) { notify("Could not create the entity: " + err, 2); return; }
    select_id(r.result.value("id", std::string()));
}

void Editor::hierarchy_duplicate(Entity e) {
    World& w = world();
    EntityJsonOptions o;  // children included, defaults and runtime state left out
    Json args = Json::object({{"entity", duplicate_spec(entity_to_json(w, e, o))}});
    if (Entity p = w.parent(e)) args["parent"] = w.id_of(p);
    std::string err;
    CommandResult r = edit_command("hier:duplicate:" + std::to_string(uiFrame_), "scene.spawn", args, &err);
    if (!r.ok) { notify("Could not duplicate the entity: " + err, 2); return; }
    select_id(r.result.value("id", std::string()));
}

void Editor::hierarchy_destroy(Entity e) {
    std::string err;
    CommandResult r = edit_command("hier:destroy:" + std::to_string(uiFrame_), "scene.destroy", Json::object({{"id", world().id_of(e)}}), &err);
    if (!r.ok) { notify("Could not delete the entity: " + err, 2); return; }
    if (selected().is_null()) select_id("");  // the selection was inside what was destroyed
}

void Editor::draw_hierarchy_node(Entity e, const std::string& filter) {
    World& w = world();
    const std::string id = w.id_of(e);
    const EntityInfo& info = w.info(e);
    const std::vector<Entity> kids = w.children(e);  // a copy: a command below may change the tree
    const bool filtered = !filter.empty();
    const bool leaf = filtered || kids.empty();
    const bool isSelected = id == selectedId_;

    ImGuiTreeNodeFlags fl = ImGuiTreeNodeFlags_OpenOnArrow | ImGuiTreeNodeFlags_SpanAvailWidth;
    if (leaf) fl |= ImGuiTreeNodeFlags_Leaf;
    if (isSelected) fl |= ImGuiTreeNodeFlags_Selected;
    if (!filtered && !w.parent(e)) fl |= ImGuiTreeNodeFlags_DefaultOpen;
    if (!filtered && !hierRevealId_.empty() && id != hierRevealId_) {
        // The selected entity may be deep: open the chain of its parents so it is on screen.
        for (Entity p = w.parent(w.find_by_id(hierRevealId_)); !p.is_null(); p = w.parent(p))
            if (p == e) { ImGui::SetNextItemOpen(true, ImGuiCond_Always); break; }
    }

    ImGui::PushID(id.c_str());
    const bool dim = !info.active;
    if (dim) ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    const std::string label = tree_label(info.name, id) + "###node";
    const bool open = ImGui::TreeNodeEx(label.c_str(), fl);
    if (dim) ImGui::PopStyleColor();
    at_track("tree:" + id);
    if (id == hierRevealId_) {
        if (!ImGui::IsItemVisible()) ImGui::SetScrollHereY(0.3f);
        hierRevealId_.clear();
    }
    if (ImGui::IsItemClicked(ImGuiMouseButton_Left) && !ImGui::IsItemToggledOpen()) select_id(id);
    if (ImGui::IsItemClicked(ImGuiMouseButton_Right)) select_id(id);
    if (ImGui::IsItemHovered() && !info.name.empty()) ImGui::SetItemTooltip("id: %s", id.c_str());

    // Drag this entity onto another one to make it a child, onto the empty space under the tree to make it a root.
    if (ImGui::BeginDragDropSource(ImGuiDragDropFlags_None)) {
        ImGui::SetDragDropPayload("FA_ENTITY", id.c_str(), id.size() + 1);
        ImGui::Text("%s", tree_label(info.name, id).c_str());
        ImGui::EndDragDropSource();
    }
    if (ImGui::BeginDragDropTarget()) {
        if (const ImGuiPayload* p = ImGui::AcceptDragDropPayload("FA_ENTITY")) {
            const std::string dragged(static_cast<const char*>(p->Data));
            std::string err;
            CommandResult r = edit_command("hier:parent:" + std::to_string(uiFrame_), "scene.set_parent",
                                           Json::object({{"id", dragged}, {"parent", id}}), &err);
            if (!r.ok) notify("Could not move '" + dragged + "' under '" + id + "': " + err, 2);
            else hierRevealId_ = dragged;
        }
        ImGui::EndDragDropTarget();
    }

    if (ImGui::BeginPopupContextItem("##ctx")) {
        if (ImGui::MenuItem("Create empty child")) hierarchy_spawn(id, "New Entity");
        at_track("tree:ctx:child");
        if (ImGui::MenuItem("Duplicate")) hierarchy_duplicate(e);
        at_track("tree:ctx:duplicate");
        if (ImGui::MenuItem("Rename...")) {
            hierRenameId_ = id;
            hierRenameText_ = info.name;
            hierRenameOpen_ = true;
        }
        at_track("tree:ctx:rename");
        if (ImGui::MenuItem("Active", nullptr, info.active)) {
            std::string err;
            CommandResult r = edit_command("hier:active:" + id, "scene.set_component",
                                           field_edit_args(id, "EntityInfo", "active", !info.active), &err);
            if (!r.ok) notify("Could not change Active: " + err, 2);
        }
        at_track("tree:ctx:active");
        if (!w.parent(e).is_null() && ImGui::MenuItem("Move to the top level")) {
            std::string err;
            CommandResult r = edit_command("hier:parent:" + std::to_string(uiFrame_), "scene.set_parent",
                                           Json::object({{"id", id}, {"parent", nullptr}}), &err);
            if (!r.ok) notify("Could not move the entity: " + err, 2);
        }
        ImGui::Separator();
        if (ImGui::MenuItem("Delete", "Del")) hierarchy_destroy(e);
        at_track("tree:ctx:delete");
        ImGui::EndPopup();
    }

    if (open) {
        if (!leaf) {
            for (Entity c : kids)
                if (w.alive(c)) draw_hierarchy_node(c, filter);
        }
        ImGui::TreePop();
    }
    ImGui::PopID();
}

void Editor::draw_hierarchy_panel() {
    ImGui::SetNextWindowSize(ImVec2(300, 360), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Hierarchy", &showHierarchy_)) {
        ImGui::End();
        return;
    }
    World& w = world();
    draw_play_banner(*this);
    if (selectedId_ != hierLastSelected_) {  // the viewport (or a command) moved the selection: show it in the tree
        hierLastSelected_ = selectedId_;
        hierRevealId_ = selectedId_;
    }

    ImGui::SetNextItemWidth(-ImGui::GetFrameHeight() - ImGui::GetStyle().ItemSpacing.x);
    ImGui::InputTextWithHint("##hierfilter", "Search name or id...", &hierFilter_);
    at_track("tree:filter");
    ImGui::SetItemTooltip("Show only entities whose name or id contains every word typed here");
    ImGui::SameLine();
    if (ImGui::Button("+", ImVec2(ImGui::GetFrameHeight(), 0))) hierarchy_spawn("", "New Entity");
    at_track("tree:add");
    ImGui::SetItemTooltip("Create an empty entity at the top level (scene.spawn)");

    ImGui::BeginChild("##tree", ImVec2(0, 0), ImGuiChildFlags_None);
    if (hierFilter_.empty()) {
        for (Entity r : w.roots())
            if (w.alive(r)) draw_hierarchy_node(r, hierFilter_);
    } else {
        for (Entity e : w.entities())
            if (w.alive(e) && tree_matches(hierFilter_, w.info(e).name, w.id_of(e))) draw_hierarchy_node(e, hierFilter_);
    }

    // The space under the tree: drop an entity here to move it to the top level; right-click to create one; click to deselect.
    ImGui::InvisibleButton("##tree_empty", ImVec2(-FLT_MIN, std::max(24.0f, ImGui::GetContentRegionAvail().y)));
    at_track("tree:empty");
    if (ImGui::IsItemClicked(ImGuiMouseButton_Left)) select_id("");
    if (ImGui::BeginDragDropTarget()) {
        if (const ImGuiPayload* p = ImGui::AcceptDragDropPayload("FA_ENTITY")) {
            const std::string dragged(static_cast<const char*>(p->Data));
            std::string err;
            CommandResult r = edit_command("hier:parent:" + std::to_string(uiFrame_), "scene.set_parent",
                                           Json::object({{"id", dragged}, {"parent", nullptr}}), &err);
            if (!r.ok) notify("Could not move '" + dragged + "' to the top level: " + err, 2);
            else hierRevealId_ = dragged;
        }
        ImGui::EndDragDropTarget();
    }
    if (ImGui::BeginPopupContextItem("##ctx_empty")) {
        if (ImGui::MenuItem("Create empty entity")) hierarchy_spawn("", "New Entity");
        at_track("tree:ctx:new");
        ImGui::EndPopup();
    }
    ImGui::EndChild();

    // Delete removes the selected entity while the tree has the focus (not while typing in a box).
    if (ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows) && !ImGui::GetIO().WantTextInput &&
        ImGui::IsKeyPressed(ImGuiKey_Delete, false)) {
        Entity s = selected();
        if (!s.is_null()) hierarchy_destroy(s);
    }

    if (hierRenameOpen_) {
        ImGui::OpenPopup("Rename entity");
        hierRenameOpen_ = false;
    }
    if (ImGui::BeginPopup("Rename entity")) {
        ImGui::TextDisabled("Name of '%s'", hierRenameId_.c_str());
        if (ImGui::IsWindowAppearing()) ImGui::SetKeyboardFocusHere();
        const bool enter = ImGui::InputText("##rename", &hierRenameText_, ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_AutoSelectAll);
        at_track("tree:rename:text");
        if (enter) {
            std::string err;
            CommandResult r = edit_command("hier:rename:" + hierRenameId_, "scene.set_component",
                                           field_edit_args(hierRenameId_, "EntityInfo", "name", hierRenameText_), &err);
            if (!r.ok) notify("Could not rename: " + err, 2);
            ImGui::CloseCurrentPopup();
        }
        ImGui::EndPopup();
    }
    ImGui::End();
}

}  // namespace fa::editor
