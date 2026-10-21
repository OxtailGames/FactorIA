// Inspector panel: the selected entity's components, built from reflection. One collapsing header per component, one widget per
// reflected field by kind (inspector_model.h: widget_for), the field's doc string as the tooltip. A change is a
// `scene.set_component` call through Editor::edit_command, the path the Console and the AI use: one undo step per drag, a value
// the command refuses (out of range...) changes nothing and its message shows under the field. MeshRenderer.material is a file
// picker over *.material.json with the material's build error under it, and materialParams is typed by `material.info`.
#include <algorithm>
#include <cfloat>
#include <cmath>

#include "editor_internal.h"

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
        v[i] = cur.is_array() && std::size_t(i) < cur.size() && cur[std::size_t(i)].is_number() ? cur[std::size_t(i)].get<float>() : fallback;
}

void tooltip(const std::string& text) {
    if (text.empty() || !ImGui::BeginItemTooltip()) return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text.c_str());
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

std::string field_tip(const FieldInfo& f, bool disabled) {
    std::string tip = f.doc;
    if (field_has_range(f)) {
        char buf[96];
        std::snprintf(buf, sizeof buf, "\nRange: %g to %g", double(f.minValue), double(f.maxValue));
        tip += buf;
    }
    if (f.readOnly) tip += "\nRead-only.";
    else if (disabled) tip += "\nNot editable here.";
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
    const std::string id = w.id_of(e);
    if (id != inspEntity_) {  // a new entity: text being edited and messages of the last one do not carry over
        inspEntity_ = id;
        inspErrors_.clear();
        inspJson_.clear();
    }
    ImGui::Text("%s", tree_label(w.info(e).name, id).c_str());
    if (Entity p = w.parent(e)) ImGui::TextDisabled("child of %s", w.id_of(p).c_str());
    ImGui::Separator();

    ImGui::BeginChild("##inspector_body", ImVec2(0, 0), ImGuiChildFlags_None);
    for (const TypeInfo* t : w.components_of(e)) {
        draw_inspector_component(e, *t);
        e = selected();  // a removed component or a refused edit may not change the entity, but a command can
        if (e.is_null()) break;
    }
    if (!e.is_null()) {
        ImGui::Spacing();
        ImGui::SetNextItemWidth(-FLT_MIN);
        if (ImGui::BeginCombo("##addcomp", "Add Component...")) {
            std::vector<const TypeInfo*> types = TypeRegistry::global().all();
            std::stable_sort(types.begin(), types.end(), [](const TypeInfo* a, const TypeInfo* b) { return a->category < b->category; });
            std::string category;
            for (const TypeInfo* t : types) {
                if (t->name == "EntityInfo" || t->name == "Transform" || w.get(e, *t) != nullptr) continue;
                if (t->category != category) {
                    category = t->category;
                    ImGui::SeparatorText(category.c_str());
                }
                if (ImGui::Selectable(t->name.c_str())) {
                    std::string err;
                    CommandResult r = edit_command("insp:add:" + std::to_string(uiFrame_), "scene.set_component",
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
    ImGui::EndChild();
    ImGui::End();
}

void Editor::draw_inspector_component(Entity e, const TypeInfo& type) {
    World& w = world();
    const std::string id = w.id_of(e);
    const bool removable = type.name != "Transform" && type.name != "EntityInfo";
    bool keep = true;
    ImGui::PushID(type.name.c_str());
    ImGui::SetNextItemOpen(true, ImGuiCond_Once);
    const bool open = ImGui::CollapsingHeader(type.name.c_str(), removable ? &keep : nullptr, ImGuiTreeNodeFlags_AllowOverlap);
    at_track("insp:hdr:" + type.name);
    if (removable)  // the x of the header, for the autotest
        at_track_at("insp:hdr:" + type.name + ":x", Vec2{ImGui::GetItemRectMax().x - ImGui::GetStyle().FramePadding.x - ImGui::GetFontSize() * 0.5f,
                                                           (ImGui::GetItemRectMin().y + ImGui::GetItemRectMax().y) * 0.5f});
    tooltip(type.doc);
    if (!keep) {  // the x of the header
        std::string err;
        CommandResult r = edit_command("insp:remove:" + std::to_string(uiFrame_), "scene.remove_component",
                                       Json::object({{"id", id}, {"component", type.name}}), &err);
        if (!r.ok) notify("Could not remove " + type.name + ": " + err, 2);
        ImGui::PopID();
        return;
    }
    if (open) {
        const Json cur = component_to_json(w, e, type, true, false);
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
                ImGui::TextUnformatted(f.name.c_str());
                tooltip(field_tip(f, disabled));
                ImGui::TableSetColumnIndex(1);
                if (type.name == "MeshRenderer" && f.name == "materialParams") {
                    draw_material_params(e, cur);
                } else {
                    Json out;
                    if (draw_field_widget(key, f, value, disabled, out)) {
                        std::string err;
                        CommandResult r = edit_command("insp:" + id + ":" + key, "scene.set_component",
                                                       field_edit_args(id, type.name, f.name, out), &err);
                        if (r.ok) inspErrors_.erase(key);
                        else inspErrors_[key] = err;
                    }
                }
                if (auto it = inspErrors_.find(key); it != inspErrors_.end()) error_text(it->second);
                if (type.name == "MeshRenderer" && f.name == "material" && value.is_string()) {
                    if (assetReportAt_ + 0.5 < time_ || assetReport_.is_null()) {
                        assetReportAt_ = time_;
                        assetReport_ = engine_ && engine_->renderer() ? engine_->renderer()->asset_report() : Json::object();
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

bool Editor::draw_field_widget(const std::string& key, const FieldInfo& f, const Json& cur, bool disabled, Json& out) {
    const FieldWidget kind = widget_for(f);
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
            at_track_at(track + "." + std::to_string(i), Vec2{a.x + (b.x - a.x) * (float(i) + 0.5f) / float(n), (a.y + b.y) * 0.5f}, !disabled);
    };
    // One drag is ONE undo step: while the item is held, the edit key stays alive however still the mouse is.
    auto keep_step_alive = [&] {
        if (ImGui::IsItemActive() && lastEditKey_ == editKey) lastEditTime_ = time_;
    };

    switch (kind) {
        case FieldWidget::Checkbox: {
            bool v = cur.is_boolean() && cur.get<bool>();
            if (ImGui::Checkbox("##v", &v)) { out = v; changed = true; }
            at_track(track, !disabled);
            tooltip(tip);
            break;
        }
        case FieldWidget::DragInt: {
            int v = cur.is_number() ? int(std::lround(cur.get<double>())) : 0;
            const bool ranged = field_has_range(f);
            if (ImGui::DragInt("##v", &v, drag_speed_for(f, v), ranged ? int(f.minValue) : 0, ranged ? int(f.maxValue) : 0)) {
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
            if (ImGui::DragFloat("##v", &v, drag_speed_for(f, v), ranged ? f.minValue : 0.0f, ranged ? f.maxValue : 0.0f, "%.3f")) {
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
            const float speed = drag_speed_for(f, std::max({std::fabs(v[0]), std::fabs(v[1]), n > 2 ? std::fabs(v[2]) : 0.0f}));
            bool edited = false;
            if (n == 2) edited = ImGui::DragFloat2("##v", v, speed, lo, hi, "%.3f");
            else if (n == 3) edited = ImGui::DragFloat3("##v", v, speed, lo, hi, "%.3f");
            else edited = ImGui::DragFloat4("##v", v, speed, lo, hi, "%.3f");
            if (edited) { out = numbers(v, n); changed = true; }
            at_track(track, !disabled);
            track_parts(n);
            tooltip(tip);
            keep_step_alive();
            break;
        }
        case FieldWidget::Color: {
            float v[4];
            read_floats(cur, v, 4, 1.0f);
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
            if (ImGui::BeginCombo("##v", name.c_str())) {
                for (const std::string& n : f.enumNames)
                    if (ImGui::Selectable(n.c_str(), n == name)) { out = n; changed = true; }
                ImGui::EndCombo();
            }
            at_track(track, !disabled);
            tooltip(tip);
            break;
        }
        case FieldWidget::EntityCombo: {
            World& w = world();
            const std::string name = cur.is_string() ? cur.get<std::string>() : std::string();
            if (ImGui::BeginCombo("##v", name.empty() ? "(none)" : name.c_str())) {
                if (ImGui::Selectable("(none)", name.empty())) { out = nullptr; changed = true; }
                for (Entity o : w.entities()) {
                    const std::string oid = w.id_of(o);
                    if (ImGui::Selectable((tree_label(w.info(o).name, oid) + "###" + oid).c_str(), oid == name)) { out = oid; changed = true; }
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
            if (!b.dirty) b.text = cur.is_string() ? cur.get<std::string>() : std::string();
            const bool asset = kind == FieldWidget::AssetPicker;
            if (asset) ImGui::SetNextItemWidth(-(ImGui::GetFrameHeight() + ImGui::GetStyle().ItemInnerSpacing.x));
            ImGui::InputText("##v", &b.text);
            if (ImGui::IsItemEdited()) b.dirty = true;
            const bool commit = ImGui::IsItemDeactivatedAfterEdit();
            if (ImGui::IsItemDeactivated() && !commit) b.dirty = false;  // Escape: the old value comes back
            at_track(track, !disabled);
            tooltip(tip);
            if (commit) { out = b.text; b.dirty = false; changed = true; }
            if (asset) {
                ImGui::SameLine(0, ImGui::GetStyle().ItemInnerSpacing.x);
                if (ImGui::BeginCombo("##pick", "", ImGuiComboFlags_NoPreview)) {
                    auto& cache = assetFiles_[f.assetType];
                    if (cache.first + 2.0 < time_ || cache.second.empty()) {
                        cache.first = time_;
                        cache.second = list_asset_files(projectDir_, f.assetType);
                    }
                    if (ImGui::Selectable("(none)", b.text.empty())) { out = std::string(); changed = true; b.dirty = false; }
                    const std::string now = cur.is_string() ? cur.get<std::string>() : std::string();
                    for (const std::string& file : cache.second)
                        if (ImGui::Selectable(file.c_str(), file == now)) { out = file; changed = true; b.dirty = false; }
                    if (cache.second.empty()) ImGui::TextDisabled("No %s files in the project.", f.assetType.c_str());
                    ImGui::EndCombo();
                }
                at_track(track + ":pick", !disabled);
                tooltip("Pick one of the project's " + f.assetType + " files");
            }
            break;
        }
        case FieldWidget::JsonText: {
            JsonBox& b = inspJson_[key];
            if (!b.dirty) b.text = cur.dump(2);
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
                if (parsed.ok()) { out = *parsed; b.dirty = false; b.error.clear(); changed = true; }
                else b.error = parsed.error().message;
            }
            if (b.dirty && !b.error.empty()) {
                error_text("Not applied: " + b.error);
                if (ImGui::SmallButton("Revert")) { b.dirty = false; b.error.clear(); }
            }
            break;
        }
    }
    ImGui::EndDisabled();
    ImGui::PopID();
    return changed;
}

void Editor::draw_material_params(Entity e, const Json& cur) {
    const std::string id = world().id_of(e);
    const std::string path = cur.contains("material") && cur["material"].is_string() ? cur["material"].get<std::string>() : std::string();
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
            if (!r.ok) inspErrors_["MeshRenderer.materialParams"] = err;
            else inspErrors_.erase("MeshRenderer.materialParams");
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
                if (r.ok) entry.info = r.result;
                else entry.error = command_error_text(r.error);
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
            if (p.min && p.max) { char b[64]; std::snprintf(b, sizeof b, " (%g to %g)", *p.min, *p.max); tipText += b; }
            tipText += overridden ? "\nSet on this entity (the material's default is overridden)." : "\nUsing the material's default.";
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
        const float speed = p.min && p.max ? std::max(1e-4f, (hi - lo) / 200.0f) : std::max(0.01f, std::fabs(v[0]) * 0.01f);
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
            if (r.ok) inspErrors_.erase("matparam:" + p.name);
            else inspErrors_["matparam:" + p.name] = err;
        }
        ImGui::SameLine();
        ImGui::BeginDisabled(!overridden);
        if (ImGui::SmallButton("Reset")) {
            std::string err;
            CommandResult r = edit_command("insp:" + id + ":matreset:" + std::to_string(uiFrame_), "scene.set_component",
                                           material_param_reset_args(id, p), &err);
            if (!r.ok) inspErrors_["matparam:" + p.name] = err;
            else inspErrors_.erase("matparam:" + p.name);
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
