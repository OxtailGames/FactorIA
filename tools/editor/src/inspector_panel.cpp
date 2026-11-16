// Inspector panel: the selected entity's components, built from reflection. One collapsing header per component, one widget per
// reflected field by kind (inspector_model.h: widget_for), the field's doc string as the tooltip. A change is a
// `scene.set_component` call through Editor::edit_command, the path the Console and the AI use: one undo step per drag, a value
// the command refuses (out of range...) changes nothing and its message shows under the field. MeshRenderer.material is a file
// picker over *.material.json with the material's build error under it, and materialParams is typed by `material.info`.
#include <algorithm>
#include <cfloat>
#include <cmath>

#include "editor_internal.h"
#include "imgui_internal.h"  // ImGuiItemFlags_MixedValue: a checkbox that shows "several values"

namespace fa::editor {

namespace {

float round4(float v) { return std::round(v * 10000.0f) / 10000.0f; }

Json numbers(const float* v, int n) {
    Json a = Json::array();
    for (int i = 0; i < n; ++i) a.push_back(round4(v[i]));
    return a;
}

void read_floats(const Json& cur, float* v, int n, float fallback = 0.0f) {
    for (int i = 0; i < n; ++i)
        v[i] = cur.is_array() && std::size_t(i) < cur.size() && cur[std::size_t(i)].is_number()
                   ? cur[std::size_t(i)].get<float>()
                   : fallback;
}

void tooltip(const std::string& text) {
    if (text.empty() || !ImGui::BeginItemTooltip()) return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text.c_str());
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

// For a widget that is greyed out: the reason, shown on hover (BeginItemTooltip stays silent on a disabled item).
void tooltip_disabled(const std::string& text) {
    if (!ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled | ImGuiHoveredFlags_ForTooltip) ||
        !ImGui::BeginTooltip())
        return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text.c_str());
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

// prefab.apply writes a file for good, and while the game runs the scene holds what scripts did to it: not offered then.
constexpr const char* kApplyWhilePlaying = "The game is running: its values are not the scene's, and applying writes "
                                           "the prefab file for good. Stop the game first.";

std::string field_tip(const FieldInfo& f, bool disabled) {
    std::string tip = f.doc;
    if (field_has_range(f)) {
        char buf[96];
        std::snprintf(buf, sizeof buf, "\nRange: %g to %g", double(f.minValue), double(f.maxValue));
        tip += buf;
    }
    if (f.readOnly)
        tip += "\nRead-only.";
    else if (disabled)
        tip += "\nNot editable here.";
    return tip;
}

void error_text(const std::string& message) {
    ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
    ImGui::TextWrapped("%s", message.c_str());
    ImGui::PopStyleColor();
}

}  // namespace

void Editor::draw_inspector_panel() {
    ImGui::SetNextWindowSize(ImVec2(340, 520), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Inspector", &showInspector_)) {
        ImGui::End();
        return;
    }
    draw_play_banner(*this);
    Entity e = selected();
    if (e.is_null()) {
        ImGui::TextDisabled("Select an entity in the Hierarchy, or click it in the viewport.");
        inspEntity_.clear();
        ImGui::End();
        return;
    }
    World& w = world();
    {  // several entities selected: the shared components of all of them (the primary first)
        std::vector<Entity> group{e};
        const Selection& shown = selection_peek();
        for (const std::string& sid : shown.ids()) {
            const Entity o = sid == shown.primary() ? kNullEntity : w.find_by_id(sid);
            if (!o.is_null()) group.push_back(o);
        }
        if (group.size() > 1) {
            draw_inspector_multi(group);
            ImGui::End();
            return;
        }
    }
    const std::string id = w.id_of(e);
    if (id != inspEntity_) {  // a new entity: text being edited and messages of the last one do not carry over
        inspEntity_ = id;
        inspErrors_.clear();
        inspJson_.clear();
    }
    ImGui::Text("%s", tree_label(w.info(e).name, id).c_str());
    if (Entity p = w.parent(e)) ImGui::TextDisabled("child of %s", w.id_of(p).c_str());
    inspector_prefab_header(e);
    ImGui::Separator();

    if (!e.is_null()) {
        ImGui::SetNextItemWidth(-FLT_MIN);
        if (ImGui::BeginCombo("##addcomp", "Add Component...")) {
            std::vector<const TypeInfo*> types = TypeRegistry::global().all();
            std::stable_sort(types.begin(), types.end(),
                             [](const TypeInfo* a, const TypeInfo* b) { return a->category < b->category; });
            std::string category;
            for (const TypeInfo* t : types) {
                if (t->name == "EntityInfo" || t->name == "Transform" || w.get(e, *t) != nullptr) continue;
                if (t->category != category) {
                    category = t->category;
                    ImGui::SeparatorText(category.c_str());
                }
                if (ImGui::Selectable(t->name.c_str())) {
                    std::string err;
                    CommandResult r = edit_command(
                        "insp:add:" + std::to_string(uiFrame_), "scene.set_component",
                        Json::object({{"id", id}, {"component", t->name}, {"fields", Json::object()}}), &err);
                    if (!r.ok) notify("Could not add " + t->name + ": " + err, 2);
                }
                at_track("insp:add:" + t->name);
                tooltip(t->doc);
            }
            ImGui::EndCombo();
        }
        at_track("insp:add");
        tooltip("Add a component with its default values (scene.set_component). The x on a header removes it.");
    }
    ImGui::Spacing();
    ImGui::BeginChild("##inspector_body", ImVec2(0, 0), ImGuiChildFlags_None);
    for (const TypeInfo* t : w.components_of(e)) {
        draw_inspector_component(e, *t);
        e = selected();  // a removed component or a refused edit may not change the entity, but a command can
        if (e.is_null()) break;
    }
    ImGui::EndChild();
    ImGui::End();
}

// ---- prefab instances: what the selected entity overrides, and the commands that revert or apply it.

// `prefab.overrides` of the selected entity: asked again when the entity changed, after every edit the Inspector makes, when
// the undo stack moved, and every second (an AI or a script may edit too). Not part of an instance: nothing is asked.
void Editor::inspector_prefab_refresh(Entity e) {
    World& w = world();
    const std::string id = w.id_of(e);
    const Entity root = prefab_instance_root(w, e);
    if (root.is_null() || !engine_) {
        inspOv_ = Json();
        inspOvRoot_.clear();
        inspOvPrefab_.clear();
        inspOvWhy_.clear();
        inspOvId_ = id;
        inspOvStale_ = true;
        return;
    }
    const std::uint64_t stamp = std::uint64_t(undo_depth()) * 1000003u + std::uint64_t(redo_depth());
    if (!inspOvStale_ && inspOvId_ == id && inspOvStamp_ == stamp && time_ - inspOvAt_ < 1.0) return;
    inspOvStale_ = false;
    inspOvId_ = id;
    inspOvStamp_ = stamp;
    inspOvAt_ = time_;
    const CommandResult r = engine_->commands().call("prefab.overrides", Json::object({{"id", id}}));
    inspOv_ = Json::array();
    inspOvWhy_.clear();
    inspOvRoot_ = w.id_of(root);
    inspOvPrefab_ = w.info(root).prefab;
    if (!r.ok) {
        inspOvWhy_ = r.error.value("message", std::string("prefab.overrides failed"));
        return;
    }
    if (r.result.value("expressible", true)) {
        if (r.result.contains("overrides")) inspOv_ = r.result["overrides"];
    } else {
        inspOvWhy_ = r.result.value("reason", std::string("the differences cannot be listed"));
    }
}

void Editor::inspector_prefab_edit(const std::string& command, const std::string& id, const std::string& component,
                                   const std::string& field) {
    std::string err;
    const CommandResult r = edit_command("insp:" + command + ":" + std::to_string(uiFrame_), command,
                                         prefab_edit_args(id, component, field), &err);
    inspOvStale_ = true;
    if (!r.ok) {
        notify("Could not " + command.substr(7) + ": " + err, 2);
        return;
    }
    if (command == "prefab.apply") {
        const Json& files = r.result.contains("files") ? r.result["files"] : Json::array();
        const std::size_t others =
            r.result.contains("updated") && r.result["updated"].is_array() ? r.result["updated"].size() : 0;
        std::string msg =
            "Applied to " +
            (files.is_array() && !files.empty() && files[0].is_string() ? files[0].get<std::string>() : inspOvPrefab_);
        if (others) msg += "; " + std::to_string(others) + " other instance" + (others == 1 ? "" : "s") + " updated";
        notify(msg, 0);
    }
}

void Editor::inspector_prefab_header(Entity e) {
    inspector_prefab_refresh(e);
    if (inspOvRoot_.empty()) return;
    const std::string id = world().id_of(e);
    const bool isRoot = inspOvRoot_ == id;
    const int count = prefab_override_count(inspOv_);
    const bool usable = inspOvWhy_.empty();
    ImGui::PushStyleColor(ImGuiCol_Text, kProjectBlue);
    if (isRoot)
        ImGui::TextWrapped("Prefab %s", inspOvPrefab_.c_str());
    else
        ImGui::TextWrapped("Part of prefab %s (%s)", inspOvPrefab_.c_str(), inspOvRoot_.c_str());
    ImGui::PopStyleColor();
    at_track("insp:prefab");
    tooltip(
        "This entity was made by that prefab file. Fields that differ from the prefab are drawn in blue; right-click a "
        "field or a component header to revert it to the prefab or apply it to the prefab file.");
    if (!usable) {
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusWarn);
        ImGui::TextWrapped("Cannot list the overrides: %s", inspOvWhy_.c_str());
        ImGui::PopStyleColor();
        at_track("insp:prefab:why");
        return;
    }
    if (count == 0)
        ImGui::TextDisabled("No overrides");
    else
        ImGui::Text("%d override%s", count, count == 1 ? "" : "s");
    at_track("insp:prefab:count");
    if (const auto removed = prefab_removed_components(inspOv_, id); !removed.empty()) {
        std::string names;
        for (const std::string& n : removed) names += (names.empty() ? "" : ", ") + n;
        ImGui::PushStyleColor(ImGuiCol_Text, kProjectBlue);
        ImGui::TextWrapped("Removed from the prefab: %s", names.c_str());
        ImGui::PopStyleColor();
        at_track("insp:prefab:removed");
        tooltip("This instance lost these components. Revert all (or Revert) gives them back; Apply all deletes them "
                "from the prefab file, and so from its other instances.");
    }
    ImGui::BeginDisabled(count == 0);
    if (ImGui::SmallButton("Revert all")) inspector_prefab_edit("prefab.revert", id, "", "");
    ImGui::EndDisabled();
    at_track("insp:prefab:revert", count != 0);
    tooltip(isRoot ? "Put every value of this instance back to the prefab's: overridden fields, added components and "
                     "added children (prefab.revert). Ctrl+Z undoes it."
                   : "Put every overridden value of this part back to the prefab's (prefab.revert). Ctrl+Z undoes it.");
    ImGui::SameLine();
    const bool playing = play_ != PlayState::Edit;
    ImGui::BeginDisabled(count == 0 || playing);
    if (ImGui::SmallButton("Apply all")) {
        inspApplyAsk_ = true;
        inspApplyId_ = id;
    }
    ImGui::EndDisabled();
    at_track("insp:prefab:apply", count != 0 && !playing);
    if (playing)
        tooltip_disabled(kApplyWhilePlaying);
    else
        tooltip(
            "Write these values into the prefab file (prefab.apply). The other instances of the prefab in this scene "
            "get them too, except where they override the same thing.");
    if (inspApplyAsk_) {
        if (!playing) ImGui::OpenPopup("Apply to prefab?##insp");
        inspApplyAsk_ = false;  // a question asked while the game ran is not asked after Stop
    }
    ImGui::SetNextWindowPos(ImGui::GetMainViewport()->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    if (ImGui::BeginPopupModal("Apply to prefab?##insp", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
        ImGui::Text("Write %d override%s of '%s' into %s?", count, count == 1 ? "" : "s", inspApplyId_.c_str(),
                    inspOvPrefab_.c_str());
        ImGui::TextWrapped("Every other instance of the prefab in this scene gets the same change, except where it "
                           "overrides that value itself. This writes the prefab file: Ctrl+Z puts the scene back, not "
                           "the file.");
        ImGui::PopTextWrapPos();
        if (ImGui::Button("Apply")) {
            inspector_prefab_edit("prefab.apply", inspApplyId_, "", "");
            ImGui::CloseCurrentPopup();
        }
        at_track("insp:prefab:apply-yes");
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) ImGui::CloseCurrentPopup();
        at_track("insp:prefab:apply-no");
        ImGui::EndPopup();
    }
}

// Several entities selected. The header says how many; Add Component adds the chosen component to every selected entity that does
// not have it (one undo step); the components every entity has are drawn once, a field where the entities differ shows "—" and an
// edit writes to all of them (one undo step per drag); the components only some have are listed below, not editable.
void Editor::draw_inspector_multi(const std::vector<Entity>& ents) {
    World& w = world();
    const std::string primaryId = w.id_of(ents[0]);
    const std::string group = "multi:" + primaryId + ":" + std::to_string(ents.size());
    if (group != inspEntity_) {
        inspEntity_ = group;
        inspErrors_.clear();
        inspJson_.clear();
    }
    ImGui::Text("%s", multi_selection_title(ents.size()).c_str());
    tooltip("The selected entities. The Inspector shows what all of them have; the primary one (the one selected last) "
            "is " +
            tree_label(w.info(ents[0]).name, primaryId) + ".");
    ImGui::TextDisabled("primary: %s", tree_label(w.info(ents[0]).name, primaryId).c_str());
    ImGui::Separator();

    std::vector<std::vector<std::string>> names;
    std::vector<const TypeInfo*> typeOf;  // every type any of them has
    for (Entity e : ents) {
        std::vector<std::string> list;
        for (const TypeInfo* t : w.components_of(e)) {
            list.push_back(t->name);
            if (std::find(typeOf.begin(), typeOf.end(), t) == typeOf.end()) typeOf.push_back(t);
        }
        names.push_back(std::move(list));
    }
    const SharedComponents sc = shared_components(names);
    auto type_named = [&](const std::string& n) -> const TypeInfo* {
        for (const TypeInfo* t : typeOf)
            if (t->name == n) return t;
        return nullptr;
    };

    ImGui::SetNextItemWidth(-FLT_MIN);
    if (ImGui::BeginCombo("##addcomp", "Add Component...")) {
        std::vector<const TypeInfo*> types = TypeRegistry::global().all();
        std::stable_sort(types.begin(), types.end(),
                         [](const TypeInfo* a, const TypeInfo* b) { return a->category < b->category; });
        std::string category;
        for (const TypeInfo* t : types) {
            if (t->name == "EntityInfo" || t->name == "Transform") continue;
            std::vector<std::string> lacking;  // the selected entities that do not have it
            for (Entity e : ents)
                if (w.get(e, *t) == nullptr) lacking.push_back(w.id_of(e));
            if (lacking.empty()) continue;
            if (t->category != category) {
                category = t->category;
                ImGui::SeparatorText(category.c_str());
            }
            const std::string label = lacking.size() == ents.size() ? t->name
                                                                    : t->name + " (" + std::to_string(lacking.size()) +
                                                                          " of " + std::to_string(ents.size()) + ")";
            if (ImGui::Selectable((label + "###" + t->name).c_str())) {
                const std::string key =
                    "insp:add:" + std::to_string(uiFrame_);  // one key: one undo step for all of them
                std::string err;
                for (const std::string& lid : lacking) {
                    CommandResult r = edit_command(
                        key, "scene.set_component",
                        Json::object({{"id", lid}, {"component", t->name}, {"fields", Json::object()}}), &err);
                    if (!r.ok) {
                        notify("Could not add " + t->name + " to " + lid + ": " + err, 2);
                        break;
                    }
                }
            }
            at_track("insp:add:" + t->name);
            tooltip(t->doc + "\nAdded to the selected entities that do not have it yet.");
        }
        ImGui::EndCombo();
    }
    at_track("insp:add");
    tooltip(
        "Add a component with its default values to every selected entity that lacks it (scene.set_component, one undo "
        "step). The x on a header removes it from all of them.");
    ImGui::Spacing();
    ImGui::BeginChild("##inspector_body", ImVec2(0, 0), ImGuiChildFlags_None);
    for (const std::string& n : sc.shared) {
        if (const TypeInfo* t = type_named(n)) draw_inspector_component_multi(ents, *t);
        if (w.find_by_id(primaryId) != ents[0])
            break;  // an edit rebuilt the scene: the handles are stale, draw again next frame
    }
    if (!sc.partial.empty()) {
        ImGui::SeparatorText("Not on every selected entity");
        for (const auto& [n, have] : sc.partial) {
            ImGui::TextDisabled("%s  (%d of %zu)", n.c_str(), have, ents.size());
            if (const TypeInfo* t = type_named(n))
                tooltip(t->doc + "\nOnly some of the selected entities have it: select one to edit it.");
        }
    }
    ImGui::EndChild();
}

void Editor::draw_inspector_component_multi(const std::vector<Entity>& ents, const TypeInfo& type) {
    World& w = world();
    const bool removable = type.name != "Transform" && type.name != "EntityInfo";
    bool keep = true;
    ImGui::PushID(type.name.c_str());
    ImGui::SetNextItemOpen(true, ImGuiCond_Once);
    const bool open =
        ImGui::CollapsingHeader(type.name.c_str(), removable ? &keep : nullptr, ImGuiTreeNodeFlags_AllowOverlap);
    at_track("insp:hdr:" + type.name);
    if (removable)
        at_track_at("insp:hdr:" + type.name + ":x",
                    Vec2{ImGui::GetItemRectMax().x - ImGui::GetStyle().FramePadding.x - ImGui::GetFontSize() * 0.5f,
                         (ImGui::GetItemRectMin().y + ImGui::GetItemRectMax().y) * 0.5f});
    tooltip(type.doc);
    if (!keep) {  // the x of the header: off every selected entity, one undo step
        const std::string key = "insp:remove:" + std::to_string(uiFrame_);
        std::string err;
        for (Entity e : ents) {
            CommandResult r = edit_command(key, "scene.remove_component",
                                           Json::object({{"id", w.id_of(e)}, {"component", type.name}}), &err);
            if (!r.ok) {
                notify("Could not remove " + type.name + ": " + err, 2);
                break;
            }
        }
        ImGui::PopID();
        return;
    }
    if (open) {
        std::vector<Json> cur;
        for (Entity e : ents) cur.push_back(component_to_json(w, e, type, true, false, kInspectorArrayEditMax));
        if (ImGui::BeginTable("##fields", 2, ImGuiTableFlags_SizingStretchProp)) {
            ImGui::TableSetupColumn("name", ImGuiTableColumnFlags_WidthStretch, 0.38f);
            ImGui::TableSetupColumn("value", ImGuiTableColumnFlags_WidthStretch, 0.62f);
            for (const FieldInfo& f : type.fields) {
                if (!inspector_shows(f)) continue;
                const std::string key = type.name + "." + f.name;
                const bool disabled = f.readOnly || (type.name == "EntityInfo" && f.name == "id");
                std::vector<Json> values;
                for (const Json& c : cur) values.push_back(c.contains(f.name) ? c[f.name] : Json(nullptr));
                const FieldMix mix = field_mix(values);
                ImGui::TableNextRow();
                ImGui::TableSetColumnIndex(0);
                ImGui::AlignTextToFramePadding();
                ImGui::TextUnformatted(f.name.c_str());
                if (inspScrollTo_ == key) {  // the autotest asks for a field low in a long component
                    ImGui::SetScrollHereY(0.0f);
                    inspScrollTo_.clear();
                }
                tooltip(field_tip(f, disabled));
                ImGui::TableSetColumnIndex(1);
                if (type.name == "MeshRenderer" && f.name == "materialParams") {
                    ImGui::TextDisabled("Material params: select one entity to edit them.");
                } else {
                    Json out;
                    if (draw_field_widget(key, f, values[0], disabled, out, &mix)) {
                        // What the user saw is the primary's value rounded to 4 decimals: compare against that, so a number
                        // they did not touch does not count as edited and leaves the other entities' own value alone.
                        Json shown = values[0];
                        if (shown.is_array())
                            for (std::size_t i = 0; i < shown.size(); ++i)
                                if (shown[i].is_number()) shown[i] = round4(shown[i].get<float>());
                        std::string err;
                        bool ok = true;
                        for (std::size_t i = 0; i < ents.size() && ok; ++i) {
                            CommandResult r = edit_command("insp:" + inspEntity_ + ":" + key, "scene.set_component",
                                                           field_edit_args(w.id_of(ents[i]), type.name, f.name,
                                                                           multi_edit_value(values[i], shown, out)),
                                                           &err);
                            ok = r.ok;
                        }
                        if (ok)
                            inspErrors_.erase(key);
                        else
                            inspErrors_[key] = err;
                    }
                }
                if (auto it = inspErrors_.find(key); it != inspErrors_.end()) error_text(it->second);
            }
            ImGui::EndTable();
        }
    }
    ImGui::PopID();
}

void Editor::draw_inspector_component(Entity e, const TypeInfo& type) {
    World& w = world();
    const std::string id = w.id_of(e);
    const bool removable = type.name != "Transform" && type.name != "EntityInfo";
    bool keep = true;
    ImGui::PushID(type.name.c_str());
    ImGui::SetNextItemOpen(true, ImGuiCond_Once);
    // A component of a prefab instance says what it overrides; the ### part keeps the header's identity.
    const bool inInstance = !inspOvRoot_.empty() && inspOvId_ == id && inspOvWhy_.empty();
    const bool added = inInstance && prefab_component_added(inspOv_, id, type.name);
    const int overridden = inInstance ? prefab_component_override_count(inspOv_, id, type.name) : 0;
    std::string headerLabel = type.name;
    if (added)
        headerLabel += "  (added to the instance)";
    else if (overridden > 0)
        headerLabel += "  (" + std::to_string(overridden) + " overridden)";
    headerLabel += "###" + type.name;
    if (inInstance && (added || overridden > 0)) ImGui::PushStyleColor(ImGuiCol_Text, kProjectBlue);
    const bool open =
        ImGui::CollapsingHeader(headerLabel.c_str(), removable ? &keep : nullptr, ImGuiTreeNodeFlags_AllowOverlap);
    if (inInstance && (added || overridden > 0)) ImGui::PopStyleColor();
    at_track("insp:hdr:" + type.name);
    if (inspScrollTo_ == type.name) {  // the autotest asks for a header low in a long list
        ImGui::SetScrollHereY(0.0f);
        inspScrollTo_.clear();
    }
    if (removable)  // the x of the header, for the autotest
        at_track_at("insp:hdr:" + type.name + ":x",
                    Vec2{ImGui::GetItemRectMax().x - ImGui::GetStyle().FramePadding.x - ImGui::GetFontSize() * 0.5f,
                         (ImGui::GetItemRectMin().y + ImGui::GetItemRectMax().y) * 0.5f});
    tooltip(type.doc);
    bool left = false;  // a revert may remove the component: do not draw its fields
    if (inInstance && ImGui::BeginPopupContextItem("##hdrctx")) {
        const bool any = added || overridden > 0;
        if (ImGui::MenuItem(added ? "Remove (the prefab does not have it)" : "Revert component to prefab", nullptr,
                            false, any)) {
            inspector_prefab_edit("prefab.revert", id, type.name, "");
            left = true;
        }
        at_track("insp:hdrctx:revert", any);
        const bool playing = play_ != PlayState::Edit;
        if (ImGui::MenuItem(added ? "Add to prefab" : "Apply component to prefab", nullptr, false, any && !playing)) {
            inspector_prefab_edit("prefab.apply", id, type.name, "");
            left = true;
        }
        at_track("insp:hdrctx:apply", any && !playing);
        if (playing) tooltip_disabled(kApplyWhilePlaying);
        ImGui::EndPopup();
    }
    if (left) {
        ImGui::PopID();
        return;
    }
    if (!keep) {  // the x of the header
        std::string err;
        CommandResult r = edit_command("insp:remove:" + std::to_string(uiFrame_), "scene.remove_component",
                                       Json::object({{"id", id}, {"component", type.name}}), &err);
        if (!r.ok) notify("Could not remove " + type.name + ": " + err, 2);
        ImGui::PopID();
        return;
    }
    if (open) {
        if (type.name == "Transform") {
            const Vec2 slot = w.ui_layout_offset(e);
            if (slot.x != 0.0f || slot.y != 0.0f) {  // a Panel or ScrollList places this entity (ui_rect.h)
                ImGui::TextDisabled("Placed by its parent's layout");
                tooltip("The layout puts this widget in its slot every frame. position is your offset from that slot "
                        "(0 = exactly in it); the viewport shows the placed result and dragging it edits the offset.");
            }
        }
        // A long array (a 512 x 512 tile map) is only counted: its JSON would be rebuilt every frame.
        const Json cur = component_to_json(w, e, type, true, false, kInspectorArrayEditMax);
        if (ImGui::BeginTable("##fields", 2, ImGuiTableFlags_SizingStretchProp)) {
            ImGui::TableSetupColumn("name", ImGuiTableColumnFlags_WidthStretch, 0.38f);
            ImGui::TableSetupColumn("value", ImGuiTableColumnFlags_WidthStretch, 0.62f);
            for (const FieldInfo& f : type.fields) {
                if (!inspector_shows(f)) continue;
                const std::string key = type.name + "." + f.name;
                const bool disabled = f.readOnly || (type.name == "EntityInfo" && f.name == "id");
                const Json value = cur.contains(f.name) ? cur[f.name] : Json(nullptr);
                ImGui::TableNextRow();
                ImGui::TableSetColumnIndex(0);
                ImGui::AlignTextToFramePadding();
                ImGui::PushID(f.name.c_str());  // each row has its own right-click menu
                const Json* overriddenField =
                    inInstance ? prefab_field_override(inspOv_, id, type.name, f.name) : nullptr;
                if (overriddenField) ImGui::PushStyleColor(ImGuiCol_Text, kProjectBlue);
                ImGui::TextUnformatted(f.name.c_str());
                if (overriddenField) ImGui::PopStyleColor();
                at_track("insp:label:" + key);
                {  // the tooltip right after its label, before the menu opens windows of its own
                    std::string tip = field_tip(f, disabled);
                    if (overriddenField)
                        tip += "\nOverridden: the prefab has " + (*overriddenField)["prefabValue"].dump() +
                               ". Right-click to revert it or apply it to the prefab.";
                    tooltip(tip);
                }
                if (inInstance && ImGui::BeginPopupContextItem("##fieldctx")) {
                    if (ImGui::MenuItem("Revert to prefab", nullptr, false, overriddenField != nullptr))
                        inspector_prefab_edit("prefab.revert", id, type.name, f.name);
                    at_track("insp:ctx:revert", overriddenField != nullptr);
                    const bool playing = play_ != PlayState::Edit;
                    if (ImGui::MenuItem("Apply to prefab", nullptr, false, overriddenField != nullptr && !playing))
                        inspector_prefab_edit("prefab.apply", id, type.name, f.name);
                    at_track("insp:ctx:apply", overriddenField != nullptr && !playing);
                    if (playing) tooltip_disabled(kApplyWhilePlaying);
                    ImGui::EndPopup();
                }
                ImGui::PopID();
                if (inspScrollTo_ == key) {  // the autotest asks for a field low in a long component
                    ImGui::SetScrollHereY(0.0f);
                    inspScrollTo_.clear();
                }
                ImGui::TableSetColumnIndex(1);
                if (type.name == "MeshRenderer" && f.name == "materialParams") {
                    draw_material_params(e, cur);
                } else {
                    Json out;
                    if (draw_field_widget(key, f, value, disabled, out)) {
                        std::string err;
                        CommandResult r = edit_command("insp:" + id + ":" + key, "scene.set_component",
                                                       field_edit_args(id, type.name, f.name, out), &err);
                        inspOvStale_ = true;
                        if (r.ok)
                            inspErrors_.erase(key);
                        else
                            inspErrors_[key] = err;
                    }
                }
                if (auto it = inspErrors_.find(key); it != inspErrors_.end()) error_text(it->second);
                if (type.name == "SpriteAnimator" && f.name == "clip") draw_animator_clips(e, id, value);
                if (type.name == "MeshRenderer" && f.name == "material" && value.is_string()) {
                    if (assetReportAt_ + 0.5 < time_ || assetReport_.is_null()) {
                        assetReportAt_ = time_;
                        assetReport_ =
                            engine_ && engine_->renderer() ? engine_->renderer()->asset_report() : Json::object();
                    }
                    const std::string buildError = material_build_error(assetReport_, value.get<std::string>());
                    if (!buildError.empty()) {
                        error_text("Build error: " + buildError);
                        at_track("insp:material:error");
                    }
                }
            }
            ImGui::EndTable();
        }
    }
    ImGui::PopID();
}

bool Editor::draw_field_widget(const std::string& key, const FieldInfo& f, const Json& cur, bool disabled, Json& out,
                               const FieldMix* mix) {
    const FieldWidget kind = widget_for(f);
    // With several entities selected `cur` is the primary's value and `mix` says where the others differ: the widget shows "—"
    // (U+2014) there. A drag or a pick still starts from the primary's value.
    const bool mixed = mix && mix->mixed;
    const char* const dash = "\xE2\x80\x94";
    const std::string tip = field_tip(f, disabled);
    const std::string track = "insp:" + key;
    const std::string editKey = "insp:" + inspEntity_ + ":" + key;
    bool changed = false;
    ImGui::PushID(key.c_str());
    ImGui::BeginDisabled(disabled);
    ImGui::SetNextItemWidth(-FLT_MIN);

    // The vector widgets are one item: the autotest also needs the centre of each number.
    auto track_parts = [&](int n) {
        const ImVec2 a = ImGui::GetItemRectMin(), b = ImGui::GetItemRectMax();
        for (int i = 0; i < n; ++i)
            at_track_at(track + "." + std::to_string(i),
                        Vec2{a.x + (b.x - a.x) * (float(i) + 0.5f) / float(n), (a.y + b.y) * 0.5f}, !disabled);
    };
    // One drag is ONE undo step: while the item is held, the edit key stays alive however still the mouse is.
    auto keep_step_alive = [&] {
        if (ImGui::IsItemActive() && lastEditKey_ == editKey) lastEditTime_ = time_;
    };

    switch (kind) {
        case FieldWidget::Checkbox: {
            bool v = cur.is_boolean() && cur.get<bool>();
            if (mixed) ImGui::PushItemFlag(ImGuiItemFlags_MixedValue, true);
            if (ImGui::Checkbox("##v", &v)) {
                out = v;
                changed = true;
            }
            if (mixed) ImGui::PopItemFlag();
            at_track(track, !disabled);
            tooltip(tip);
            break;
        }
        case FieldWidget::DragInt: {
            int v = cur.is_number() ? int(std::lround(cur.get<double>())) : 0;
            const bool ranged = field_has_range(f);
            if (ImGui::DragInt("##v", &v, drag_speed_for(f, v), ranged ? int(f.minValue) : 0,
                               ranged ? int(f.maxValue) : 0, mixed ? dash : "%d")) {
                out = v;
                changed = true;
            }
            at_track(track, !disabled);
            tooltip(tip);
            keep_step_alive();
            break;
        }
        case FieldWidget::DragFloat: {
            float v = cur.is_number() ? cur.get<float>() : 0.0f;
            const bool ranged = field_has_range(f);
            if (ImGui::DragFloat("##v", &v, drag_speed_for(f, v), ranged ? f.minValue : 0.0f,
                                 ranged ? f.maxValue : 0.0f, mixed ? dash : "%.3f")) {
                out = round4(v);
                changed = true;
            }
            at_track(track, !disabled);
            tooltip(tip);
            keep_step_alive();
            break;
        }
        case FieldWidget::Vec2:
        case FieldWidget::Vec3:
        case FieldWidget::Vec4:
        case FieldWidget::Rect: {
            const int n = widget_arity(kind);
            float v[4];
            read_floats(cur, v, n, 0.0f);
            const bool ranged = field_has_range(f);
            const float lo = ranged ? f.minValue : 0.0f, hi = ranged ? f.maxValue : 0.0f;
            const float speed =
                drag_speed_for(f, std::max({std::fabs(v[0]), std::fabs(v[1]), n > 2 ? std::fabs(v[2]) : 0.0f}));
            bool edited = false;
            if (mixed) {
                // One drag box per number, so that only the numbers that differ show "—" (DragFloat3 has one format).
                const float total = ImGui::CalcItemWidth(), gap = ImGui::GetStyle().ItemInnerSpacing.x;
                ImGui::BeginGroup();
                for (int i = 0; i < n; ++i) {
                    ImGui::PushID(i);
                    if (i > 0) ImGui::SameLine(0.0f, gap);
                    ImGui::SetNextItemWidth(std::max(1.0f, (total - gap * float(n - 1)) / float(n)));
                    const bool partMixed = i < int(mix->parts.size()) ? bool(mix->parts[size_t(i)]) : true;
                    edited |= ImGui::DragFloat("##c", &v[i], speed, lo, hi, partMixed ? dash : "%.3f");
                    keep_step_alive();
                    ImGui::PopID();
                }
                ImGui::EndGroup();
            } else if (n == 2)
                edited = ImGui::DragFloat2("##v", v, speed, lo, hi, "%.3f");
            else if (n == 3)
                edited = ImGui::DragFloat3("##v", v, speed, lo, hi, "%.3f");
            else
                edited = ImGui::DragFloat4("##v", v, speed, lo, hi, "%.3f");
            if (edited) {
                out = numbers(v, n);
                changed = true;
            }
            at_track(track, !disabled);
            track_parts(n);
            tooltip(tip);
            if (!mixed) keep_step_alive();
            break;
        }
        case FieldWidget::Color: {
            float v[4];
            read_floats(cur, v, 4, 1.0f);
            if (mixed) {  // the swatch shows the primary's colour; the dash says the others differ
                ImGui::AlignTextToFramePadding();
                ImGui::TextDisabled("%s", dash);
                ImGui::SameLine();
                ImGui::SetNextItemWidth(-FLT_MIN);
            }
            if (ImGui::ColorEdit4("##v", v, ImGuiColorEditFlags_AlphaBar | ImGuiColorEditFlags_Float)) {
                out = numbers(v, 4);
                changed = true;
            }
            at_track(track, !disabled);
            tooltip(tip);
            keep_step_alive();
            break;
        }
        case FieldWidget::EnumCombo: {
            const std::string name = cur.is_string() ? cur.get<std::string>() : std::string();
            if (ImGui::BeginCombo("##v", mixed ? dash : name.c_str())) {
                for (const std::string& n : f.enumNames)
                    if (ImGui::Selectable(n.c_str(), n == name)) {
                        out = n;
                        changed = true;
                    }
                ImGui::EndCombo();
            }
            at_track(track, !disabled);
            tooltip(tip);
            break;
        }
        case FieldWidget::EntityCombo: {
            World& w = world();
            const std::string name = cur.is_string() ? cur.get<std::string>() : std::string();
            if (ImGui::BeginCombo("##v", mixed ? dash : name.empty() ? "(none)" : name.c_str())) {
                if (ImGui::Selectable("(none)", name.empty())) {
                    out = nullptr;
                    changed = true;
                }
                for (Entity o : w.entities()) {
                    const std::string oid = w.id_of(o);
                    if (ImGui::Selectable((tree_label(w.info(o).name, oid) + "###" + oid).c_str(), oid == name)) {
                        out = oid;
                        changed = true;
                    }
                }
                ImGui::EndCombo();
            }
            at_track(track, !disabled);
            tooltip(tip);
            break;
        }
        case FieldWidget::Text:
        case FieldWidget::AssetPicker: {
            JsonBox& b = inspJson_[key];
            if (!b.dirty) b.text = !mixed && cur.is_string() ? cur.get<std::string>() : std::string();
            const bool asset = kind == FieldWidget::AssetPicker;
            if (asset) ImGui::SetNextItemWidth(-(ImGui::GetFrameHeight() + ImGui::GetStyle().ItemInnerSpacing.x));
            ImGui::InputTextWithHint("##v", mixed ? dash : "", &b.text);
            if (ImGui::IsItemEdited()) b.dirty = true;
            const bool commit = ImGui::IsItemDeactivatedAfterEdit();
            if (ImGui::IsItemDeactivated() && !commit) b.dirty = false;  // Escape: the old value comes back
            at_track(track, !disabled);
            tooltip(tip);
            if (commit) {
                out = b.text;
                b.dirty = false;
                changed = true;
            }
            if (asset && ImGui::BeginDragDropTarget()) {
                // A file from the Project panel: only one of this field's asset type is taken; it is written as picking it does.
                const ImGuiPayload* live = ImGui::GetDragDropPayload();
                if (live && live->IsDataType(kAssetPayload) && live->Data) {
                    const std::string dropped(static_cast<const char*>(live->Data));
                    if (!asset_file_matches(f.assetType, dropped)) {
                        ImGui::SetTooltip("This field takes %s files", f.assetType.c_str());
                    } else if (ImGui::AcceptDragDropPayload(kAssetPayload)) {
                        out = dropped;
                        changed = true;
                        b.dirty = false;
                    }
                }
                ImGui::EndDragDropTarget();
            }
            if (asset) {
                ImGui::SameLine(0, ImGui::GetStyle().ItemInnerSpacing.x);
                if (ImGui::BeginCombo("##pick", "", ImGuiComboFlags_NoPreview)) {
                    auto& cache = assetFiles_[f.assetType];
                    if (cache.first + 2.0 < time_ || cache.second.empty()) {
                        cache.first = time_;
                        cache.second = list_asset_files(projectDir_, f.assetType);
                    }
                    if (ImGui::Selectable("(none)", b.text.empty())) {
                        out = std::string();
                        changed = true;
                        b.dirty = false;
                    }
                    const std::string now = cur.is_string() ? cur.get<std::string>() : std::string();
                    for (const std::string& file : cache.second)
                        if (ImGui::Selectable(file.c_str(), file == now)) {
                            out = file;
                            changed = true;
                            b.dirty = false;
                        }
                    if (cache.second.empty()) ImGui::TextDisabled("No %s files in the project.", f.assetType.c_str());
                    ImGui::EndCombo();
                }
                at_track(track + ":pick", !disabled);
                tooltip("Pick one of the project's " + f.assetType + " files");
            }
            if (asset && f.assetType == "mesh" && cur.is_string() && MeshStore::is_id(cur.get<std::string>())) {
                // A procedural mesh (mesh.create): what it is, or why the entity shows the placeholder box.
                if (const MeshStore::Entry* m = world().meshes().find(cur.get<std::string>()))
                    ImGui::TextDisabled(
                        "Procedural mesh: %zu vertices, %zu triangles, %zu submeshes (mesh.save writes it as a .glb)",
                        m->data.vertex_count(), m->data.triangle_count(), m->data.submeshes.size());
                else
                    ImGui::TextColored(ImVec4(1.0f, 0.55f, 0.35f, 1.0f),
                                       "This procedural mesh no longer exists (destroyed, or its scene was unloaded): "
                                       "a placeholder box is drawn.");
            }
            break;
        }
        case FieldWidget::JsonText: {
            const bool numbers = is_array_kind(f.kind);
            if (mixed) {  // a JSON box has no way to show several values: edit these one entity at a time
                ImGui::TextDisabled("%s  (differs: select one entity to edit)", dash);
                at_track(track, false);
                tooltip(tip);
                break;
            }
            const std::optional<std::size_t> longArray = inspector_array_length(cur);
            if (numbers && longArray) {
                // Too long for a text box that is rebuilt every frame: say what it is; scripts and commands edit it.
                ImGui::TextDisabled("%s, %zu elements: too many to edit here (scene.set_component or a script)",
                                    field_kind_name(f.kind), *longArray);
                at_track(track, false);
                tooltip(tip);
                break;
            }
            JsonBox& b = inspJson_[key];
            if (!b.dirty) b.text = numbers ? cur.dump() : cur.dump(2);  // a number array on one line, like a vector
            int lines = 1;
            for (char c : b.text) lines += c == '\n';
            lines = std::clamp(lines, 3, 12);
            const float h = ImGui::GetTextLineHeight() * float(lines) + ImGui::GetStyle().FramePadding.y * 2.0f;
            ImGui::InputTextMultiline("##v", &b.text, ImVec2(-FLT_MIN, h));
            if (ImGui::IsItemEdited()) {
                b.dirty = true;
                auto parsed = parse_json_box(b.text);
                b.error = parsed.ok() ? std::string() : parsed.error().message;
            }
            at_track(track, !disabled);
            tooltip(tip + "\nJSON: applied when you click away; invalid JSON is refused.");
            if (ImGui::IsItemDeactivated() && b.dirty) {
                auto parsed = parse_json_box(b.text);
                if (parsed.ok()) {
                    out = *parsed;
                    b.dirty = false;
                    b.error.clear();
                    changed = true;
                } else
                    b.error = parsed.error().message;
            }
            if (b.dirty && !b.error.empty()) {
                error_text("Not applied: " + b.error);
                if (ImGui::SmallButton("Revert")) {
                    b.dirty = false;
                    b.error.clear();
                }
            }
            break;
        }
    }
    ImGui::EndDisabled();
    ImGui::PopID();
    return changed;
}

// Under SpriteAnimator.clip: the clips the texture of the entity's Sprite has in its `sheet` entry (assets.json), one click each,
// or why there are none. The clip name is set through scene.set_component like any field.
void Editor::draw_animator_clips(Entity e, const std::string& id, const Json& current) {
    const Sprite* sprite = world().get<Sprite>(e);
    if (!sprite || sprite->texture.empty()) {
        ImGui::TextDisabled("Give the entity a Sprite with a texture to pick one of its clips.");
        return;
    }
    const auto sheet = assets::sheet(sprite->texture);
    if (!sheet || sheet->clips.empty()) {
        ImGui::TextDisabled("'%s' has no clips in assets.json (assets.animate_svg, assets.bake_sheet and "
                            "assets.slice_sheet record them).",
                            sprite->texture.c_str());
        return;
    }
    const std::string now = current.is_string() ? current.get<std::string>() : std::string();
    ImGui::TextDisabled("Clips (click to play):");
    tooltip("The clips of " + sprite->texture + " (its `sheet` entry in assets.json)");
    for (const assets::SheetClip& c : sheet->clips) {
        const float w = ImGui::CalcTextSize(c.name.c_str()).x + ImGui::GetStyle().FramePadding.x * 2 +
                        ImGui::GetStyle().ItemSpacing.x;
        if (&c != &sheet->clips.front() && ImGui::GetContentRegionAvail().x > w) ImGui::SameLine();
        if (ImGui::SmallButton((c.name + "###clip:" + c.name).c_str()) && c.name != now) {
            std::string err;
            CommandResult r = edit_command("insp:" + id + ":SpriteAnimator.clip", "scene.set_component",
                                           field_edit_args(id, "SpriteAnimator", "clip", c.name), &err);
            if (r.ok)
                inspErrors_.erase("SpriteAnimator.clip");
            else
                inspErrors_["SpriteAnimator.clip"] = err;
        }
        at_track("insp:SpriteAnimator.clip:" + c.name);
        tooltip(std::format("Frames {} to {} at {} fps{}", c.firstFrame, c.lastFrame, c.fps,
                            c.loop ? ", loops" : ", plays once"));
    }
}

void Editor::draw_material_params(Entity e, const Json& cur) {
    const std::string id = world().id_of(e);
    const std::string path =
        cur.contains("material") && cur["material"].is_string() ? cur["material"].get<std::string>() : std::string();
    const Json overrides = cur.contains("materialParams") ? cur["materialParams"] : Json::object();
    FieldInfo rawField;  // the plain JSON box, when there is no material to type the params by
    rawField.name = "materialParams";
    rawField.kind = FieldKind::Json;
    rawField.doc = "Per-entity overrides of the material's params, keyed by the name the material file declares.";
    auto raw = [&] {
        Json out;
        if (draw_field_widget("MeshRenderer.materialParams", rawField, overrides, false, out)) {
            std::string err;
            CommandResult r = edit_command("insp:" + id + ":MeshRenderer.materialParams", "scene.set_component",
                                           field_edit_args(id, "MeshRenderer", "materialParams", out), &err);
            if (!r.ok)
                inspErrors_["MeshRenderer.materialParams"] = err;
            else
                inspErrors_.erase("MeshRenderer.materialParams");
        }
    };
    if (path.empty()) {
        ImGui::TextDisabled("Choose a material above to edit its params.");
        if (overrides.is_object() && !overrides.empty()) raw();
        return;
    }

    // material.info, again when the file changed (checked twice a second) or failed before.
    MaterialInfoEntry& entry = materialInfo_[path];
    if (entry.checkedAt + 0.5 < time_) {
        entry.checkedAt = time_;
        const std::int64_t mtime = fs::modified_time(path);
        if (mtime != entry.mtime || !entry.error.empty()) {
            entry.mtime = mtime;
            entry.error.clear();
            entry.info = Json();
            if (!engine_ || !engine_->commands().info("material.info")) {
                entry.error = "This build has no material.info command.";
            } else {
                CommandResult r = engine_->commands().call("material.info", Json::object({{"material", path}}));
                if (r.ok)
                    entry.info = r.result;
                else
                    entry.error = command_error_text(r.error);
            }
        }
    }
    if (!entry.error.empty()) {
        error_text("Cannot read the material's params: " + entry.error);
        raw();
        return;
    }
    auto specs = material_params_from_info(entry.info);
    if (!specs.ok()) {
        error_text(specs.error().message);
        raw();
        return;
    }
    if (specs->empty()) ImGui::TextDisabled("This material declares no params.");

    ImGui::PushID("matparams");
    for (const MaterialParamSpec& p : *specs) {
        const int n = material_param_arity(p.type);
        const bool overridden = material_param_overridden(p, overrides);
        const Json value = material_param_value(p, overrides);
        ImGui::PushID(p.name.c_str());
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted((p.name + (overridden ? " *" : "")).c_str());
        {
            std::string tipText = p.doc + "\n" + p.type;
            if (p.min && p.max) {
                char b[64];
                std::snprintf(b, sizeof b, " (%g to %g)", *p.min, *p.max);
                tipText += b;
            }
            tipText += overridden ? "\nSet on this entity (the material's default is overridden)."
                                  : "\nUsing the material's default.";
            tooltip(tipText);
        }
        ImGui::SameLine();
        const float reset = ImGui::CalcTextSize("Reset").x + ImGui::GetStyle().FramePadding.x * 2.0f;
        ImGui::SetNextItemWidth(-(reset + ImGui::GetStyle().ItemSpacing.x));
        Json out;
        bool changed = false;
        const std::string track = "insp:matparam:" + p.name;
        float v[4];
        read_floats(value.is_number() ? Json::array({value}) : value, v, std::max(n, 1), 0.0f);
        const float lo = p.min ? float(*p.min) : 0.0f, hi = p.max ? float(*p.max) : 0.0f;
        const float speed =
            p.min && p.max ? std::max(1e-4f, (hi - lo) / 200.0f) : std::max(0.01f, std::fabs(v[0]) * 0.01f);
        if (p.type == "float") {
            changed = ImGui::DragFloat("##v", v, speed, lo, hi, "%.3f", ImGuiSliderFlags_ClampOnInput);
            if (changed) out = round4(v[0]);
        } else if (p.type == "vec2") {
            changed = ImGui::DragFloat2("##v", v, speed, lo, hi, "%.3f", ImGuiSliderFlags_ClampOnInput);
            if (changed) out = numbers(v, 2);
        } else if (p.type == "vec3") {
            changed = ImGui::DragFloat3("##v", v, speed, lo, hi, "%.3f", ImGuiSliderFlags_ClampOnInput);
            if (changed) out = numbers(v, 3);
        } else if (p.type == "vec4") {
            changed = ImGui::DragFloat4("##v", v, speed, lo, hi, "%.3f", ImGuiSliderFlags_ClampOnInput);
            if (changed) out = numbers(v, 4);
        } else if (p.type == "color") {
            changed = ImGui::ColorEdit4("##v", v, ImGuiColorEditFlags_AlphaBar | ImGuiColorEditFlags_Float);
            if (changed) out = numbers(v, 4);
        } else {
            ImGui::TextDisabled("%s (not editable here)", p.type.c_str());
        }
        at_track(track);
        const std::string editKey = "insp:" + id + ":matparam:" + p.name;
        if (ImGui::IsItemActive() && lastEditKey_ == editKey) lastEditTime_ = time_;
        if (changed) {
            std::string err;
            CommandResult r = edit_command(editKey, "scene.set_component", material_param_edit_args(id, p, out), &err);
            if (r.ok)
                inspErrors_.erase("matparam:" + p.name);
            else
                inspErrors_["matparam:" + p.name] = err;
        }
        ImGui::SameLine();
        ImGui::BeginDisabled(!overridden);
        if (ImGui::SmallButton("Reset")) {
            std::string err;
            CommandResult r = edit_command("insp:" + id + ":matreset:" + std::to_string(uiFrame_),
                                           "scene.set_component", material_param_reset_args(id, p), &err);
            if (!r.ok)
                inspErrors_["matparam:" + p.name] = err;
            else
                inspErrors_.erase("matparam:" + p.name);
        }
        ImGui::EndDisabled();
        at_track("insp:matreset:" + p.name, overridden);
        tooltip("Back to the material's default (removes the override from this entity)");
        if (auto it = inspErrors_.find("matparam:" + p.name); it != inspErrors_.end()) error_text(it->second);
        ImGui::PopID();
    }
    ImGui::PopID();
    // Overrides for names the material does not declare stay in the file; say so rather than hide them.
    if (overrides.is_object()) {
        std::string stray;
        for (auto it = overrides.begin(); it != overrides.end(); ++it) {
            bool known = false;
            for (const MaterialParamSpec& p : *specs) known = known || p.name == it.key();
            if (!known) {
                bool isTexture = false;
                for (const Json& t : entry.info.value("textures", Json::array()))
                    isTexture = isTexture || t.value("name", std::string()) == it.key();
                if (!isTexture) stray += (stray.empty() ? "" : ", ") + it.key();
            }
        }
        if (!stray.empty()) {
            ImGui::PushStyleColor(ImGuiCol_Text, kStatusWarn);
            ImGui::TextWrapped("Overrides this material does not declare: %s", stray.c_str());
            ImGui::PopStyleColor();
        }
    }
}

}  // namespace fa::editor
