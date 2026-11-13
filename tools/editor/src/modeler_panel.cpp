// The Model panel (View > Model): a model document (*.model.json, docs/MODELING.md) as its operation tree, the parameters of the picked node as
// sliders, and a live view of the mesh it evaluates to, with the part picked in the tree or the part list drawn in an accent colour. Everything it
// keeps is a model.edit call made by ModelerModel, so the Console and an AI make the same edit, and each edit is ONE entry of the editor's undo
// stack. A slider being dragged only shows its value in the viewport (the document is evaluated again from a copy); letting go writes it. The view
// is tools/common's software renderer (model_view.h), the one model.preview draws its sheets with. The rules are in modeler_model.h.
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <format>

#include "editor_internal.h"
#include "fa/core/strings.h"
#include "fa/tooling/model_view.h"
#include "imgui_internal.h"
#include "imgui_stdlib.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

const ImVec4 kBad(1.0f, 0.55f, 0.45f, 1);
const ImVec4 kWarn(1.0f, 0.8f, 0.4f, 1);
const ImVec4 kGood(0.55f, 0.85f, 0.55f, 1);
const ImVec4 kInfo(0.6f, 0.75f, 0.95f, 1);

bool is_number_list(const Json& v, std::size_t n) {
    if (!v.is_array() || v.size() != n) return false;
    for (const Json& x : v)
        if (!x.is_number()) return false;
    return true;
}

std::string node_label(const ModelerRow& r) {
    std::string s = r.op;
    if (!r.id.empty()) s += "  " + r.id;
    return s;
}

}  // namespace

// ----------------------------------------------------------------------------------------------------------- document --
ModelerModel& Editor::modeler_ensure_model() {
    if (!modeler_.model) {
        modeler_.model = std::make_unique<ModelerModel>(projectDir_, [this](const std::string& name, const Json& args) {
            CommandResult r = engine_->commands().call(name, args);
            if (!args.is_object() || !args.value("dryRun", false)) after_command(name, args, r);
            return r;
        });
        if (autotest_) {
            modeler_.model->set_async(
                false);  // the autotest evaluates inline: what it waits for is state, not a worker thread
            modeler_.model->set_debounce_ticks(1);
        }
    }
    return *modeler_.model;
}

bool Editor::open_model_document(const std::string& rel) {
    if (!engine_) return false;
    ModelerModel& m = modeler_ensure_model();
    ModelerUi& u = modeler_;
    u.selected.clear();
    u.highlight.clear();
    u.textKey.clear();
    u.check = Json();
    u.checkError.clear();
    u.checkRev = ~0ULL;
    u.picture.key = ~0ULL;
    const bool ok = m.open(rel);
    u.openError = ok ? std::string() : m.error();
    showModeler_ = true;
    focus_window("Model");
    if (!ok) notify("Cannot open " + rel + " in the Model panel: " + m.error(), 2);
    return ok;
}

void Editor::modeler_close_document() {
    if (modeler_.model) modeler_.model->close();
    modeler_.selected.clear();
    modeler_.highlight.clear();
}

void Editor::modeler_save() {
    ModelerUi& u = modeler_;
    if (!u.model || !u.model->is_open() || !u.model->valid()) return;
    if (play_ != PlayState::Edit) {
        notify("Stop the game before baking the model.", 1);
        return;
    }
    u.model->set_overwrite_on_save(u.overwriteBaked);
    const ModelerEditOutcome out = u.model->save();
    if (!out.ok)
        notify(out.error, 2);
    else
        project_files_changed();
}

void Editor::modeler_release_textures() {
    ModelerUi& u = modeler_;
    if (u.picture.image || u.picture.view) ui::destroy_texture(u.picture.image, u.picture.view);
    for (const ModelerUi::Dead& d : u.graveyard) ui::destroy_texture(d.image, d.view);
    u.picture = ModelerUi::Texture{};
    u.graveyard.clear();
}

void Editor::modeler_edited(const ModelerEditOutcome& out) {
    ModelerUi& u = modeler_;
    if (!out.ok) {
        notify(out.error, 1);
        return;
    }
    if (out.step <= 0 || !u.model) return;
    undo_.push_back(Json::object({{"$modeler", Json::object({{"step", out.step}})}}));
    if (undo_.size() > 100) undo_.erase(undo_.begin());
    redo_.clear();
    lastEditKey_.clear();
    modeler_collect_steps();
}

void Editor::modeler_collect_steps() {
    if (!modeler_.model) return;
    std::set<int> keep;
    for (const auto* stack : {&undo_, &redo_})
        for (const Json& e : *stack)
            if (e.is_object() && e.contains("$modeler") && e["$modeler"].is_object() &&
                e["$modeler"].value("step", 0) > 0)
                keep.insert(e["$modeler"]["step"].get<int>());
    modeler_.model->retain_steps(keep);
}

void Editor::modeler_apply_undo(const Json& entry, bool forward) {
    ModelerUi& u = modeler_;
    const int id = entry["$modeler"].value("step", 0);
    if (!u.model || !u.model->step(id)) {
        notify("That model edit is no longer remembered.", 1);
        return;
    }
    const std::string doc = u.model->step_document(id);
    if (!doc.empty() && doc != u.model->path()) open_model_document(doc);
    if (!u.model->apply_step(id, forward)) {
        notify("Could not " + std::string(forward ? "redo" : "undo") + " the model edit: " + u.model->status(), 2);
        return;
    }
    // The node picked may not exist any more.
    if (!u.selected.empty() && !u.model->node(u.selected)) u.selected.clear();
    (forward ? undo_ : redo_).push_back(entry);
    project_files_changed();
}

Vec2 Editor::modeler_screen_pos(float fx, float fy) const {
    const ModelerUi& u = modeler_;
    return Vec2{u.viewX0 + fx * u.viewW, u.viewY0 + fy * u.viewH};
}

// -------------------------------------------------------------------------------------------------------------- panel --
void Editor::draw_modeler_panel() {
    ModelerUi& u = modeler_;
    ModelerModel& m = modeler_ensure_model();
    // One tick per frame: collects a finished evaluation and starts the next one.
    if (m.is_open()) m.tick();
    for (std::size_t i = 0; i < u.graveyard.size();) {  // textures replaced a few frames ago can go now
        if (u.graveyard[i].frame + 4 < uiFrame_) {
            ui::destroy_texture(u.graveyard[i].image, u.graveyard[i].view);
            u.graveyard.erase(u.graveyard.begin() + long(i));
        } else {
            ++i;
        }
    }

    first_floating_window(ImVec2(240, 110), ImVec2(1100, 700));
    if (!ImGui::Begin("Model", &showModeler_)) {
        u.focused = false;
        ImGui::End();
        return;
    }
    u.focused = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows);
    draw_modeler_toolbar(m);
    if (!m.is_open()) {
        ImGui::Spacing();
        ImGui::TextDisabled(
            "Open a model document (*.model.json) from the list above, or double click one in the Project panel.");
        ImGui::TextDisabled(
            "model.create makes one; model.preview and model.check look at it from outside the editor.");
        if (!u.openError.empty()) ImGui::TextColored(kBad, "%s", u.openError.c_str());
        ImGui::End();
        return;
    }
    if (uiFrame_ - u.lastPoll >= 20 && !m.has_live() && !u.dragging) {
        u.lastPoll = uiFrame_;
        if (m.poll_external()) m.set_status("The file changed on disk and was read again.");
    }
    if (!m.valid()) {
        ImGui::Spacing();
        ImGui::TextColored(kBad, "This model document does not load:");
        ImGui::TextWrapped("%s", m.error().c_str());
        ImGui::TextDisabled("Fix it with the Console (model.edit, fs.edit) or an editor, then Reload. model.info lists "
                            "every problem with its JSON pointer.");
        ImGui::End();
        return;
    }
    if (play_ != PlayState::Edit) ImGui::TextColored(kWarn, "The game is running: stop it to edit the model.");
    if (!u.selected.empty() && !m.node(u.selected)) u.selected.clear();

    const float full = ImGui::GetContentRegionAvail().x;
    const float leftW = std::clamp(full * 0.24f, 200.0f, 320.0f), rightW = std::clamp(full * 0.27f, 240.0f, 380.0f);
    const float h = std::max(160.0f, ImGui::GetContentRegionAvail().y);
    ImGui::BeginChild("##mod_left", ImVec2(leftW, h), ImGuiChildFlags_Borders);
    draw_modeler_tree(m);
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##mod_view",
                      ImVec2(std::max(120.0f, full - leftW - rightW - 2 * ImGui::GetStyle().ItemSpacing.x), h),
                      ImGuiChildFlags_Borders);
    draw_modeler_viewport(m);
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##mod_params", ImVec2(0, h), ImGuiChildFlags_Borders);
    draw_modeler_params(m);
    ImGui::EndChild();
    ImGui::End();
}

void Editor::draw_modeler_toolbar(ModelerModel& m) {
    ModelerUi& u = modeler_;
    ImGui::TextUnformatted("Document");
    ImGui::SameLine();
    // The documents of the project, by their file name.
    ImGui::SetNextItemWidth(260);
    if (ImGui::BeginCombo("##mod_doc", m.is_open() ? m.path().c_str() : "(none open)")) {
        std::vector<std::string> docs;
        for (const auto& e : std::filesystem::recursive_directory_iterator(
                 projectDir_ + "/assets", std::filesystem::directory_options::skip_permission_denied)) {
            std::error_code ec;
            if (!e.is_regular_file(ec)) continue;
            const std::string rel = std::filesystem::relative(e.path(), projectDir_, ec).generic_string();
            if (ends_with(rel, ".model.json")) docs.push_back(rel);
        }
        std::sort(docs.begin(), docs.end());
        for (const std::string& d : docs)
            if (ImGui::Selectable(d.c_str(), m.is_open() && d == m.path())) open_model_document(d);
        if (docs.empty()) ImGui::TextDisabled("No *.model.json under assets/ (model.create makes one).");
        ImGui::EndCombo();
    }
    at_track("mod:doc");
    if (!m.is_open()) return;
    ImGui::SameLine();
    const bool canSave = m.valid() && play_ == PlayState::Edit;
    ImGui::BeginDisabled(!canSave);
    if (ImGui::Button("Save")) modeler_save();
    at_track("mod:save", canSave);
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip(
            "Bakes the .glb next to the document (model.bake). Ctrl+S while this panel has the keyboard.\n"
            "Every edit is already written to the document; baking is what changes the model the game loads.");
    ImGui::SameLine();
    ImGui::Checkbox("Replace foreign file", &u.overwriteBaked);
    at_track("mod:overwrite");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("Bake over a .glb that nothing of ours made (no recipe in assets.json). Off: the bake stops "
                          "with a message instead.");
    ImGui::SameLine();
    if (ImGui::Button("Reload")) m.reload();
    at_track("mod:reload");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Reads the file again; the undo steps stay.");
    if (m.busy()) {
        ImGui::SameLine();
        ImGui::TextDisabled("evaluating...");
    }
    if (!m.status().empty()) {
        ImGui::SameLine();
        ImGui::TextDisabled("%s", m.status().c_str());
    }
}

// ------------------------------------------------------------------------------------------------------------------ tree --
void Editor::draw_modeler_tree(ModelerModel& m) {
    ModelerUi& u = modeler_;
    ImGui::TextDisabled("Operations");
    const std::vector<ModelerRow> rows = m.rows();
    (void)m.catalog();  // the kinds are looked up once the catalog is loaded
    const bool canEdit = play_ == PlayState::Edit;
    ImGui::BeginChild("##mod_rows", ImVec2(0, std::max(100.0f, ImGui::GetContentRegionAvail().y * 0.5f)));
    for (std::size_t i = 0; i < rows.size(); ++i) {
        const ModelerRow& r = rows[i];
        ImGui::PushID(int(i));
        ImGui::Dummy(ImVec2(float(r.depth) * 14.0f, 0));
        ImGui::SameLine(0, 0);
        bool on = r.enabled;
        ImGui::BeginDisabled(!canEdit);
        if (ImGui::Checkbox("##on", &on)) modeler_edited(m.set_enabled(r.pointer, on));
        ImGui::EndDisabled();
        at_track("mod:enabled:" + std::to_string(i), canEdit);
        if (ImGui::IsItemHovered())
            ImGui::SetTooltip(
                "Off leaves the node, and everything below it, out of the model (enabled: false in the document).");
        ImGui::SameLine();
        if (!r.enabled) ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
        if (ImGui::Selectable(node_label(r).c_str(), u.selected == r.pointer)) {
            u.selected = r.pointer;
            const std::string part = m.part_of(r.pointer);
            if (!part.empty()) u.highlight = part;
        }
        if (!r.enabled) ImGui::PopStyleColor();
        at_track("mod:node:" + std::to_string(i));
        if (ImGui::IsItemHovered())
            ImGui::SetTooltip("%s%s\n%s%s", r.pointer.c_str(), r.part.empty() ? "" : ("\npart: " + r.part).c_str(),
                              r.kind.c_str(),
                              r.container ? (", " + std::to_string(r.childCount) + " children").c_str() : "");
        ImGui::PopID();
    }
    if (rows.empty()) ImGui::TextDisabled("The document has no nodes yet.");
    ImGui::EndChild();

    // Add / remove
    const Json& cat = m.catalog();
    ImGui::SetNextItemWidth(120);
    if (ImGui::BeginCombo("##mod_newop", u.newOp.c_str())) {
        for (const Json& o : cat["operations"]) {
            const std::string op = o.value("op", std::string());
            const std::string kind = o.value("kind", std::string());
            if (kind == "modifier" && (op == "extrude_faces" || op == "inset_faces" || op == "loop_cut" ||
                                       op == "bevel_edges" || op == "delete_faces" || op == "assign_faces"))
                continue;  // they need a query
            if (kind != "primitive" && kind != "modifier" && kind != "group") continue;
            if (ImGui::Selectable(op.c_str(), op == u.newOp)) u.newOp = op;
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", o.value("doc", std::string()).c_str());
        }
        ImGui::EndCombo();
    }
    at_track("mod:newop");
    ImGui::SameLine();
    ImGui::BeginDisabled(!canEdit);
    if (ImGui::Button("Add")) {
        // Into the picked group or modifier, else at the top level.
        std::string parent;
        for (const ModelerRow& r : rows)
            if (r.pointer == u.selected && r.container) parent = r.id.empty() ? r.pointer : r.id;
        const Json node = Json::object({{"op", u.newOp}});
        const ModelerEditOutcome out = m.add_node(parent, node);
        modeler_edited(out);
        if (out.ok && out.result.contains("edit") && out.result["edit"].contains("pointer"))
            u.selected = out.result["edit"]["pointer"].get<std::string>();
    }
    at_track("mod:add", canEdit);
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("Adds a node of that operation (model.edit add): into the picked group or modifier, else at "
                          "the end of the top level.");
    ImGui::EndDisabled();
    ImGui::SameLine();
    ImGui::BeginDisabled(!canEdit || u.selected.empty());
    if (ImGui::Button("Remove")) {
        modeler_edited(m.remove_node(u.selected));
        u.selected.clear();
    }
    at_track("mod:remove", canEdit && !u.selected.empty());
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("Removes the picked node and everything below it (model.edit remove). Undo brings it back.");

    // Parts
    ImGui::Separator();
    ImGui::TextDisabled("Parts");
    const std::vector<std::string> parts = m.part_names();
    if (parts.empty()) ImGui::TextDisabled("No node names a part (give one a `part`).");
    if (ImGui::Selectable("(none)", u.highlight.empty())) u.highlight.clear();
    at_track("mod:part:none");
    for (const std::string& p : parts) {
        if (ImGui::Selectable(p.c_str(), u.highlight == p)) u.highlight = p;
        at_track("mod:part:" + p);
        if (ImGui::IsItemHovered()) {
            std::size_t tris = 0;
            for (const ModelPartInfo& info : m.build()->parts)
                if (info.part == p) tris += info.triangles;
            ImGui::SetTooltip("%zu triangles. Drawn in orange in the view.", tris);
        }
    }

    // Check
    ImGui::Separator();
    if (ImGui::Button("Check")) {
        u.check = m.check();
        u.checkError = m.check_error();
        u.checkRev = m.doc_revision();
    }
    at_track("mod:check");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("model.check: scale against a 1.8 m figure, flipped normals, open and non-manifold edges, "
                          "degenerate triangles, triangles over the platform budgets.");
    if (!u.checkError.empty()) ImGui::TextColored(kBad, "%s", u.checkError.c_str());
    if (u.check.is_object()) {
        if (u.checkRev != m.doc_revision()) ImGui::TextDisabled("(from before the last edit)");
        const Json& findings = u.check["findings"];
        if (findings.empty()) ImGui::TextColored(kGood, "Nothing found.");
        for (std::size_t i = 0; i < findings.size(); ++i) {
            const Json& f = findings[i];
            const std::string sev = f.value("severity", std::string());
            ImGui::PushID(int(i));
            const ImVec4 col = sev == "error" ? kBad : sev == "warning" ? kWarn : kInfo;
            ImGui::TextColored(col, "%s", sev.c_str());
            ImGui::SameLine();
            ImGui::TextWrapped("%s", f.value("message", std::string()).c_str());
            at_track("mod:finding:" + std::to_string(i));
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", f.value("hint", std::string()).c_str());
            if (ImGui::IsItemClicked() && f.contains("parts") && f["parts"].is_array() && !f["parts"].empty() &&
                f["parts"][0].is_string())
                u.highlight = f["parts"][0].get<std::string>();
            ImGui::PopID();
        }
    }
}

// ---------------------------------------------------------------------------------------------------------------- viewport --
void Editor::draw_modeler_viewport(ModelerModel& m) {
    ModelerUi& u = modeler_;
    // The options of the view.
    ImGui::Checkbox("Shaded", &u.shaded);
    at_track("mod:shaded");
    ImGui::SameLine();
    ImGui::Checkbox("Wire", &u.wireframe);
    at_track("mod:wire");
    ImGui::SameLine();
    ImGui::Checkbox("Ortho", &u.orthographic);
    ImGui::SameLine();
    ImGui::Checkbox("Ground", &u.ground);
    ImGui::SameLine();
    ImGui::Checkbox("1.8 m figure", &u.figure);
    at_track("mod:figure");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Stands a 1.8 m figure beside the model, to judge its scale.");
    ImGui::SameLine();
    if (ImGui::Button("Reset view")) {
        u.yaw = 30;
        u.pitch = 20;
        u.zoom = 1;
    }
    at_track("mod:reset_view");
    if (!m.eval_error().empty()) ImGui::TextColored(kBad, "The model cannot be evaluated: %s", m.eval_error().c_str());

    const ModelerBuildPtr build = m.build();
    if (!build) {
        ImGui::TextDisabled(m.eval_error().empty() ? "evaluating..." : "No mesh to show.");
        return;
    }
    const std::string note =
        std::format("{} triangles, {} vertices, {} parts, {:.2f} x {:.2f} x {:.2f} m{}", build->stats.triangles,
                    build->stats.vertices, m.part_names().size(), build->stats.bmax.x - build->stats.bmin.x,
                    build->stats.bmax.y - build->stats.bmin.y, build->stats.bmax.z - build->stats.bmin.z,
                    build->stats.closed() ? ", closed" : ", open surface");
    ImGui::TextDisabled("%s", note.c_str());
    for (const std::string& w : build->warnings) ImGui::TextColored(kWarn, "%s", w.c_str());

    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const int w = std::clamp(int(avail.x), 64, 900), h = std::clamp(int(avail.y), 64, 900);
    ImVec2 p0 = ImGui::GetCursorScreenPos();
    ImGui::InvisibleButton("##mod_canvas", ImVec2(float(w), float(h)),
                           ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight);
    at_track("mod:view");
    const bool hovered = ImGui::IsItemHovered();
    u.dragging = ImGui::IsItemActive() && ImGui::IsMouseDragging(ImGuiMouseButton_Left, 0.0f);
    if (u.dragging) {
        const ImVec2 d = ImGui::GetIO().MouseDelta;
        u.yaw -= d.x * 0.5f;
        u.pitch = std::clamp(u.pitch + d.y * 0.5f, -89.0f, 89.0f);
    }
    if (hovered && ImGui::GetIO().MouseWheel != 0.0f)
        u.zoom = std::clamp(u.zoom * std::pow(1.1f, ImGui::GetIO().MouseWheel), 0.2f, 8.0f);
    if (u.yaw > 180.0f) u.yaw -= 360.0f;
    if (u.yaw < -180.0f) u.yaw += 360.0f;

    // The picture is made again when anything it shows changed.
    std::uint64_t key = 1469598103934665603ULL;
    auto mix = [&](std::uint64_t v) {
        key = (key ^ (v + 0x9e3779b97f4a7c15ULL + (key << 6) + (key >> 2))) * 0x100000001b3ULL;
    };
    mix(m.build_revision());
    mix(std::uint64_t(std::llround(double(u.yaw) * 10)));
    mix(std::uint64_t(std::llround(double(u.pitch) * 10)));
    mix(std::uint64_t(std::llround(double(u.zoom) * 100)));
    mix(std::uint64_t(w) * 4096 + std::uint64_t(h));
    mix(std::uint64_t(u.shaded) | std::uint64_t(u.wireframe) << 1 | std::uint64_t(u.orthographic) << 2 |
        std::uint64_t(u.ground) << 3 | std::uint64_t(u.figure) << 4 | std::uint64_t(u.dragging) << 5);
    mix(std::hash<std::string>{}(u.highlight));
    if (key != u.picture.key) {
        const auto t0 = std::chrono::steady_clock::now();  // UI timing only
        const MeshData& fig = model_reference_figure();
        ModelViewItem item;
        item.mesh = &build->data;
        item.highlightPart = u.highlight;
        std::vector<ModelViewItem> items = {item};
        if (u.figure && !fig.positions.empty()) {
            ModelViewItem f;
            f.mesh = &fig;
            f.flat = true;
            f.wire = false;
            f.offset = reference_figure_offset(build->stats.bmin, build->stats.bmax);
            items.push_back(f);
        }
        ModelViewOptions o;
        o.width = w;
        o.height = h;
        o.yawDeg = double(u.yaw);
        o.pitchDeg = double(u.pitch);
        o.orthographic = u.orthographic;
        o.shaded = u.shaded;
        o.wireframe = u.wireframe;
        o.ground = u.ground;
        o.zoom = double(u.zoom);
        o.supersample = (u.dragging || build->stats.triangles > 60000) ? 1 : 2;
        const Image pic = render_model_view(items, o);
        ModelerUi::Texture t;
        if (!pic.empty() && ui::make_texture(pic.width, pic.height, pic.rgba.data(), t.image, t.view)) {
            if (u.picture.image || u.picture.view) u.graveyard.push_back({u.picture.image, u.picture.view, uiFrame_});
            t.w = pic.width;
            t.h = pic.height;
            t.key = key;
            u.picture = t;
            ++u.renderCount;
            u.renderMs = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
        }
    }
    u.viewX0 = p0.x;
    u.viewY0 = p0.y;
    u.viewW = float(w);
    u.viewH = float(h);
    if (u.picture.view)
        ImGui::GetWindowDrawList()->AddImage(ImTextureRef(ImTextureID(ui::texture_from_view(u.picture.view, true))), p0,
                                             ImVec2(p0.x + float(w), p0.y + float(h)));
    if (hovered)
        ImGui::SetTooltip("Drag to orbit, wheel to zoom. Back faces are dark red: a model that shows red from outside "
                          "has flipped triangles.");
}

// -------------------------------------------------------------------------------------------------------------- parameters --
void Editor::draw_modeler_params(ModelerModel& m) {
    ModelerUi& u = modeler_;
    if (u.selected.empty()) {
        ImGui::TextDisabled("Pick a node in the tree to edit its parameters.");
        ImGui::Spacing();
        ImGui::TextDisabled("Every change is a model.edit call and one undo step; a slider shows its value in the view "
                            "while you drag and writes it when you let go.");
        return;
    }
    const Json* shownPtr = m.shown_node(u.selected);
    if (!shownPtr) {
        ImGui::TextDisabled("That node is gone.");
        return;
    }
    // A copy: an edit in the loop below (set_values, set_live) replaces the document the pointer points into, and the
    // next field would read freed memory.
    const Json shown = *shownPtr;
    const std::string op = shown.value("op", std::string());
    ImGui::Text("%s", op.c_str());
    ImGui::SameLine();
    ImGui::TextDisabled("%s", u.selected.c_str());
    if (const Json* info = m.op_info(op)) ImGui::TextWrapped("%s", info->value("doc", std::string()).c_str());
    ImGui::Separator();

    const bool canEdit = play_ == PlayState::Edit;
    ImGui::BeginDisabled(!canEdit);
    const std::string ptr = u.selected;
    for (const Json& f : m.fields_of(op)) {
        const std::string key = f.value("key", std::string());
        const std::string type = f.value("type", std::string());
        if (key == "id" || key == "children" || key == "op" || key == "enabled") continue;
        const bool present = shown.contains(key);
        const Json fallback = f.contains("default") ? f["default"] : Json();
        const Json& value = present ? shown[key] : fallback;
        const double lo = f.value("min", -1000.0), hi = f.value("max", 1000.0);
        ImGui::PushID(key.c_str());
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted(key.c_str());
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", f.value("doc", std::string()).c_str());
        if (present) {
            ImGui::SameLine();
            if (ImGui::SmallButton("reset"))
                modeler_edited(m.set_values(ptr, Json::object({{key, Json()}}), "Reset " + key));
            at_track("mod:reset:" + key, canEdit);
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("Takes the field out of the document: back to its default.");
        }
        auto range = [&](double current, double def) {
            // A slider over [min, max]; a very wide range is cut around the value so the slider stays usable (ctrl+click types any number).
            double a = lo, b = hi;
            if (b - a > 100.0) b = std::min(hi, std::max({10.0, std::fabs(current) * 3.0, std::fabs(def) * 4.0}));
            if (a < -100.0) a = std::max(lo, -b);
            return std::pair<float, float>{float(a), float(b)};
        };
        auto commit_live = [&](const Json& v) { m.set_live(ptr, Json::object({{key, v}})); };
        auto commit = [&](const Json& v) { modeler_edited(m.set_values(ptr, Json::object({{key, v}}))); };
        ImGui::SetNextItemWidth(-1);
        if (type == "number") {
            float v = value.is_number() ? value.get<float>() : float(std::clamp(0.0, lo, hi));
            const auto [a, b] = range(double(v), fallback.is_number() ? fallback.get<double>() : 0.0);
            if (ImGui::SliderFloat("##v", &v, a, b, "%.3f")) commit_live(Json(double(v)));
            at_track("mod:param:" + key, canEdit);
            if (ImGui::IsItemDeactivatedAfterEdit()) commit(Json(double(v)));
        } else if (type == "integer") {
            int v = value.is_number() ? value.get<int>() : int(std::clamp(0.0, lo, hi));
            const auto [a, b] = range(double(v), fallback.is_number() ? fallback.get<double>() : 0.0);
            if (ImGui::SliderInt("##v", &v, int(a), int(b))) commit_live(Json(v));
            at_track("mod:param:" + key, canEdit);
            if (ImGui::IsItemDeactivatedAfterEdit()) commit(Json(v));
        } else if (type == "boolean") {
            bool v = value.is_boolean() ? value.get<bool>() : false;
            if (ImGui::Checkbox("##v", &v)) commit(Json(v));
            at_track("mod:param:" + key, canEdit);
        } else if (type == "vec3" || type == "size3") {
            float v[3] = {0, 0, 0};
            if (is_number_list(value, 3))
                for (int i = 0; i < 3; ++i) v[i] = value[std::size_t(i)].get<float>();
            else if (value.is_number())
                v[0] = v[1] = v[2] = value.get<float>();
            else if (type == "size3")
                v[0] = v[1] = v[2] = 1;
            const auto [a, b] = range(double(std::max({std::fabs(v[0]), std::fabs(v[1]), std::fabs(v[2])})), 1.0);
            auto as_json = [&] { return Json::array({double(v[0]), double(v[1]), double(v[2])}); };
            if (ImGui::SliderFloat3("##v", v, a, b, "%.3f")) commit_live(as_json());
            at_track("mod:param:" + key, canEdit);
            if (ImGui::IsItemDeactivatedAfterEdit()) commit(as_json());
        } else if (type == "count3" || type == "count2") {
            const int n = type == "count3" ? 3 : 2;
            int v[3] = {1, 1, 1};
            if (is_number_list(value, std::size_t(n)))
                for (int i = 0; i < n; ++i) v[i] = value[std::size_t(i)].get<int>();
            else if (value.is_number())
                v[0] = v[1] = v[2] = value.get<int>();
            auto as_json = [&] { return n == 3 ? Json::array({v[0], v[1], v[2]}) : Json::array({v[0], v[1]}); };
            const int a = int(lo), b = int(std::min(hi, 64.0));
            const bool changed = n == 3 ? ImGui::SliderInt3("##v", v, a, b) : ImGui::SliderInt2("##v", v, a, b);
            if (changed) commit_live(as_json());
            at_track("mod:param:" + key, canEdit);
            if (ImGui::IsItemDeactivatedAfterEdit()) commit(as_json());
        } else if (type == "choice" && f.contains("choices")) {
            const std::string current = value.is_string() ? value.get<std::string>() : std::string();
            if (ImGui::BeginCombo("##v", current.empty() ? "(default)" : current.c_str())) {
                for (const Json& c : f["choices"]) {
                    const std::string name = c.is_string() ? c.get<std::string>() : std::string();
                    if (ImGui::Selectable(name.c_str(), name == current) && name != current) commit(Json(name));
                }
                ImGui::EndCombo();
            }
            at_track("mod:param:" + key, canEdit);
        } else if (type == "string") {
            const std::string textKey = ptr + "|" + key;
            if (u.textKey != textKey) {
                u.textKey = textKey;
                u.text = value.is_string() ? value.get<std::string>() : std::string();
            }
            ImGui::InputText("##v", &u.text);
            at_track("mod:param:" + key, canEdit);
            if (ImGui::IsItemDeactivatedAfterEdit()) {
                if (u.text.empty() && present)
                    commit(Json());
                else
                    commit(Json(u.text));
                u.textKey.clear();
            } else if (!ImGui::IsItemActive() && u.textKey == textKey) {
                u.textKey.clear();  // read the field again from the document next frame
            }
        } else {
            // points, rings, faces queries, colours, children: edited with model.edit (Console), shown here as the JSON that is in the document.
            ImGui::TextDisabled("%s", present ? value.dump().substr(0, 120).c_str() : "(not set)");
            if (ImGui::IsItemHovered())
                ImGui::SetTooltip("This field is a %s: change it with model.edit "
                                  "{\"op\":\"set\",\"target\":\"%s\",\"values\":{\"%s\":...}} in the Console.",
                                  type.c_str(), ptr.c_str(), key.c_str());
        }
        ImGui::PopID();
    }
    ImGui::EndDisabled();
}

}  // namespace fa::editor
