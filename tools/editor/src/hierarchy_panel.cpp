// Hierarchy panel: the entity tree (roots and children), selection shared with the viewport (Ctrl/Cmd+click toggles, Shift+click
// selects the rows between, selection.h), drag and drop to reparent (scene.set_parent; the whole selection moves when the dragged
// row is selected), a context menu (create child, duplicate, rename, active, delete) and a search box. Nothing here edits the
// world directly: every change is a command call through Editor::edit_command, the path the Console and the AI use, so undo and
// the scene file come with it; a command on several entities shares one edit key, so it is one undo step. The logic that can be
// tested without a window is in inspector_model.h and selection.h.
#include <algorithm>
#include <cfloat>
#include <set>

#include "editor_internal.h"
#include "undo_inverse.h"

namespace fa::editor {

CommandResult Editor::edit_command(const std::string& key, const std::string& name, const Json& args,
                                   std::string* error, bool forceSnapshot, bool record) {
    CommandResult r;
    if (!engine_) {
        r.error = Json::object({{"message", "No project is open."}});
        if (error) *error = "No project is open.";
        return r;
    }
    lastEditRecorded_ = false;
    // Record mode (Animation panel): a change of an animatable field of a part of the animated entity becomes a key at the
    // playhead; the scene keeps its rest value.
    if (record && play_ == PlayState::Edit && name == "scene.set_component" && anim_recording() &&
        anim_record_edit(key, args, r, error)) {
        lastEditRecorded_ = r.ok;
        return r;
    }
    const CommandInfo* ci = engine_->commands().info(name);
    const bool edits = play_ == PlayState::Edit && ci && !ci->readOnly && command_edits_scene(name, args);
    if (edits &&
        anim_.posed) {  // the undo step and the file must hold rest values, not the pose; the panel poses again
        anim_unpose();
        anim_.dirtyPose = true;
    }
    // A command with an inverse builder (undo_inverse.h) is one Command entry: the inverse is built from the scene as it
    // is now (rest values: the pose is off), and the entry is pushed once the call succeeded, so a refused call leaves
    // nothing behind and keeps the redo list.
    // An edit that comes right after a snapshot step with the same key (several commands of one Console line or one AI call)
    // joins that step, which already restores the scene from before them all: a Command entry would make it two steps. (The
    // other order, a snapshot after a Command entry, is two steps: docs/EDITOR.md, "Undo entries".)
    const bool joinsSnapshot = lastEditKind_ == UndoEntry::Kind::Snapshot && !undo_.empty() &&
                               undo_.back().kind == UndoEntry::Kind::Snapshot &&
                               edit_coalesces(key, lastEditKey_, time_, lastEditTime_);
    if (edits && !forceSnapshot && !joinsSnapshot) {
        if (std::optional<UndoPlan> plan = plan_undo(world(), name, args)) {
            r = engine_->commands().call(name, args);
            after_command(name, args, r);
            if (r.ok) {
                if (plan->noop) {  // the call left the scene as it was: no step, nothing to save
                } else if (finish_undo_plan(world(), name, *plan, r.result)) {
                    push_command_entry(key, std::move(plan->forward), std::move(plan->inverse), CoalesceMode::Merge);
                } else {  // the result is not what the builder expects: the edit is done and nothing can undo it
                    dirty_ = true;
                    redo_.clear();  // the edit happened: a redo list from before it no longer applies
                    lastEditKey_.clear();
                    notify("This edit cannot be undone: " + name + " gave an unexpected result.", 1);
                }
            } else if (error) {
                *error = command_error_text(r.error);
            }
            return r;
        }
    }
    // Every other command takes a whole-scene snapshot. begin_edit pushes it before the call. A refused call must not leave an
    // empty step (or lose the redo list), so what begin_edit changes is put back when the command fails.
    const bool snapshot = edits;
    UndoStack savedRedo;
    std::string savedKey;
    double savedTime = 0;
    UndoEntry::Kind savedKind = lastEditKind_;
    bool savedDirty = false, pushed = false;
    if (snapshot) {
        savedRedo = std::move(redo_);
        redo_.clear();
        savedKey = lastEditKey_;
        savedTime = lastEditTime_;
        savedDirty = dirty_;
        pushed = begin_edit(key);
    }
    r = engine_->commands().call(name, args);
    after_command(name, args, r);
    if (!r.ok && snapshot) {
        if (pushed && !undo_.empty()) undo_.pop_back();
        redo_ = std::move(savedRedo);
        lastEditKey_ = savedKey;
        lastEditTime_ = savedTime;
        lastEditKind_ = savedKind;
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
    if (!r.ok) {
        notify("Could not create the entity: " + err, 2);
        return;
    }
    select_id(r.result.value("id", std::string()));
}

void Editor::hierarchy_destroy_selection() {
    const std::vector<std::string> ids = selection_roots();  // a destroyed entity takes its children with it
    if (ids.empty()) return;
    const std::string key = "hier:destroy:" + std::to_string(uiFrame_);
    std::string failure;
    // One step for the whole selection: when any of them has no inverse (a top-level entity before other top-level ones),
    // all of them take the snapshot, which coalesces under the key.
    bool snapshot = false;
    for (const std::string& id : ids)
        if (!has_undo_plan(world(), "scene.destroy", Json::object({{"id", id}}))) snapshot = true;
    for (const std::string& id : ids) {
        std::string err;
        CommandResult r = edit_command(key, "scene.destroy", Json::object({{"id", id}}), &err, snapshot);
        if (!r.ok && failure.empty()) failure = err;
    }
    if (!failure.empty()) notify("Could not delete the entity: " + failure, 2);
    selection();  // the selected entities that were destroyed leave the set
}

void Editor::hierarchy_reparent(const std::string& dragged, const std::string& parentId) {
    std::vector<std::string> ids;
    if (selection_.contains(dragged) && selection_.size() > 1)
        ids = selection_roots();
    else
        ids.push_back(dragged);
    ids.erase(std::remove(ids.begin(), ids.end(), parentId), ids.end());  // an entity cannot become its own child
    const std::string key = "hier:parent:" + std::to_string(uiFrame_);
    const Json parent = parentId.empty() ? Json(nullptr) : Json(parentId);
    std::string failure, failedId;
    bool moved = false;
    for (const std::string& id : ids) {
        std::string err;
        CommandResult r = edit_command(key, "scene.set_parent", Json::object({{"id", id}, {"parent", parent}}), &err);
        if (r.ok) {
            moved = true;
        } else if (failure.empty()) {
            failure = err;
            failedId = id;
        }
    }
    if (!failure.empty())
        notify("Could not move '" + failedId +
                   (parentId.empty() ? "' to the top level: " : "' under '" + parentId + "': ") + failure,
               2);
    if (moved) hierRevealId_ = dragged;
}

void Editor::hier_click(const std::string& id) {
    const ImGuiIO& io = ImGui::GetIO();
    click_in_list(selection_, id, SelectMods{io.KeyCtrl, io.KeyShift}, hierAnchor_, hierRowsPrev_);
    // The tree made this change itself: the panel must not take it for the viewport's and reset the anchor to the primary
    // (a Shift click moves the primary to the clicked row, and the next Shift click still starts from the anchor).
    hierLastSelected_ = selection_.primary();
}

void Editor::draw_hierarchy_node(Entity e, const std::string& filter) {
    World& w = world();
    const std::string id = w.id_of(e);
    const EntityInfo& info = w.info(e);
    const std::vector<Entity> kids = w.children(e);  // a copy: a command below may change the tree
    const bool filtered = !filter.empty();
    const bool leaf = filtered || kids.empty();
    const bool isSelected = selection_.contains(id);  // selection_peek(): no pruning while drawing
    const bool isPrimary = selection_.size() > 1 && id == selection_.primary();
    hierRows_.push_back(id);

    ImGuiTreeNodeFlags fl = ImGuiTreeNodeFlags_OpenOnArrow | ImGuiTreeNodeFlags_SpanAvailWidth;
    if (leaf) fl |= ImGuiTreeNodeFlags_Leaf;
    if (isSelected) fl |= ImGuiTreeNodeFlags_Selected;
    if (!filtered && !w.parent(e)) fl |= ImGuiTreeNodeFlags_DefaultOpen;
    if (!filtered && !hierRevealId_.empty() && id != hierRevealId_) {
        // The selected entity may be deep: open the chain of its parents so it is on screen.
        for (Entity p = w.parent(w.find_by_id(hierRevealId_)); !p.is_null(); p = w.parent(p))
            if (p == e) {
                ImGui::SetNextItemOpen(true, ImGuiCond_Always);
                break;
            }
    }

    ImGui::PushID(id.c_str());
    const bool dim = !info.active;
    if (dim) ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    // Of several selected rows the primary (the one the Inspector and the gizmo follow) is brighter and has a bar at its left.
    if (isPrimary) ImGui::PushStyleColor(ImGuiCol_Header, ImVec4(0.30f, 0.52f, 0.85f, 0.70f));
    const std::string label = tree_label(info.name, id) + "###node";
    const bool open = ImGui::TreeNodeEx(label.c_str(), fl);
    if (isPrimary) {
        ImGui::PopStyleColor();
        ImGui::GetWindowDrawList()->AddRectFilled(ImGui::GetItemRectMin(),
                                                  ImVec2(ImGui::GetItemRectMin().x + 3.0f, ImGui::GetItemRectMax().y),
                                                  IM_COL32(255, 205, 60, 255));
    }
    if (dim) ImGui::PopStyleColor();
    at_track("tree:" + id);
    if (id == hierRevealId_) {
        if (!ImGui::IsItemVisible()) ImGui::SetScrollHereY(0.3f);
        hierRevealId_.clear();
    }
    if (ImGui::IsItemClicked(ImGuiMouseButton_Left) && !ImGui::IsItemToggledOpen()) {
        const ImGuiIO& io = ImGui::GetIO();
        if (!io.KeyCtrl && !io.KeyShift && isSelected && selection_.size() > 1)
            hierClickPending_ =
                id;  // a drag from here moves all of them; a plain click selects this row on the release
        else
            hier_click(id);
    }
    if (hierClickPending_ == id && ImGui::IsMouseReleased(ImGuiMouseButton_Left)) {
        const ImVec2 dragged = ImGui::GetMouseDragDelta(ImGuiMouseButton_Left);
        if (ImGui::IsItemHovered() && dragged.x == 0.0f && dragged.y == 0.0f) {
            select_id(id);
            hierAnchor_ = id;
            hierLastSelected_ = selection_.primary();
        }
        hierClickPending_.clear();
    }
    if (ImGui::IsItemClicked(ImGuiMouseButton_Right) &&
        !isSelected) {  // on a selected row the menu acts on the whole selection
        select_id(id);
        hierAnchor_ = id;
        hierLastSelected_ = selection_.primary();
    }
    if (ImGui::IsItemHovered() && !info.name.empty()) ImGui::SetItemTooltip("id: %s", id.c_str());

    // Drag this entity onto another one to make it a child, onto the empty space under the tree to make it a root.
    if (ImGui::BeginDragDropSource(ImGuiDragDropFlags_None)) {
        ImGui::SetDragDropPayload("FA_ENTITY", id.c_str(), id.size() + 1);
        if (isSelected && selection_.size() > 1)
            ImGui::Text("%zu entities", selection_.size());
        else
            ImGui::Text("%s", tree_label(info.name, id).c_str());
        ImGui::EndDragDropSource();
    }
    if (ImGui::BeginDragDropTarget()) {
        if (const ImGuiPayload* p = ImGui::AcceptDragDropPayload("FA_ENTITY")) {
            hierarchy_reparent(std::string(static_cast<const char*>(p->Data)), id);
        }
        ImGui::EndDragDropTarget();
    }

    if (ImGui::BeginPopupContextItem("##ctx")) {
        if (ImGui::MenuItem("Create empty child")) hierarchy_spawn(id, "New Entity");
        at_track("tree:ctx:child");
        const std::string many = selection_.size() > 1 ? " (" + std::to_string(selection_.size()) + ")" : std::string();
        if (ImGui::MenuItem(("Duplicate" + many).c_str())) hierarchy_duplicate_selection();
        at_track("tree:ctx:duplicate");
        if (ImGui::MenuItem(("Copy" + many).c_str(), menu::shortcut_label("Ctrl+C", menu::kApple).c_str()))
            entity_copy();
        at_track("tree:ctx:copy");
        if (ImGui::MenuItem(("Cut" + many).c_str(), menu::shortcut_label("Ctrl+X", menu::kApple).c_str())) entity_cut();
        at_track("tree:ctx:cut");
        if (ImGui::MenuItem("Paste", menu::shortcut_label("Ctrl+V", menu::kApple).c_str(), false, clipboard_has_text()))
            entity_paste();
        at_track("tree:ctx:paste");
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
        if (ImGui::MenuItem(("Delete" + many).c_str(), "Del")) hierarchy_destroy_selection();
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
    if (selected_id() != hierLastSelected_) {  // the viewport (or a command) moved the selection: show it in the tree
        hierLastSelected_ = selected_id();
        hierRevealId_ = selected_id();
        hierAnchor_ = selected_id();
    }
    hierRows_.clear();

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
            if (w.alive(e) && tree_matches(hierFilter_, w.info(e).name, w.id_of(e)))
                draw_hierarchy_node(e, hierFilter_);
    }

    // The space under the tree: drop an entity here to move it to the top level; right-click to create one; click to deselect.
    ImGui::InvisibleButton("##tree_empty", ImVec2(-FLT_MIN, std::max(24.0f, ImGui::GetContentRegionAvail().y)));
    at_track("tree:empty");
    if (ImGui::IsItemClicked(ImGuiMouseButton_Left) && !ImGui::GetIO().KeyCtrl && !ImGui::GetIO().KeyShift)
        select_id("");
    if (ImGui::BeginDragDropTarget()) {
        if (const ImGuiPayload* p = ImGui::AcceptDragDropPayload("FA_ENTITY"))
            hierarchy_reparent(std::string(static_cast<const char*>(p->Data)), std::string());
        ImGui::EndDragDropTarget();
    }
    if (ImGui::BeginPopupContextItem("##ctx_empty")) {
        if (ImGui::MenuItem("Create empty entity")) hierarchy_spawn("", "New Entity");
        at_track("tree:ctx:new");
        ImGui::EndPopup();
    }
    ImGui::EndChild();

    hierRowsPrev_.swap(hierRows_);  // the order a Shift click of the next frame selects over
    if (ImGui::IsMouseReleased(ImGuiMouseButton_Left)) hierClickPending_.clear();

    if (ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows)) hierFocusFrame_ = uiFrame_;
    // Delete removes the selected entities while the tree has the focus (not while typing in a box).
    if (ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows) && !ImGui::GetIO().WantTextInput &&
        ImGui::IsKeyPressed(ImGuiKey_Delete, false) && !selection_.empty())
        hierarchy_destroy_selection();

    if (hierRenameOpen_) {
        ImGui::OpenPopup("Rename entity");
        hierRenameOpen_ = false;
    }
    if (ImGui::BeginPopup("Rename entity")) {
        ImGui::TextDisabled("Name of '%s'", hierRenameId_.c_str());
        if (ImGui::IsWindowAppearing()) ImGui::SetKeyboardFocusHere();
        const bool enter = ImGui::InputText("##rename", &hierRenameText_,
                                            ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_AutoSelectAll);
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
