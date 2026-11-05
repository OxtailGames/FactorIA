// The Vector panel (View > Vector): an SVG as a canvas with a pen, node editing, shape tools and boolean buttons (the canvas is in
// vector_canvas.cpp), a layer list of the groups and elements of the drawing, and an inspector. Everything it changes goes through
// vector.* commands (vector_model.cpp), so the Console and an AI make the same edit, and each edit is ONE entry of the editor's undo stack.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <format>
#include <functional>
#include <set>

#include "editor_internal.h"
#include "inspector_model.h"
#include "fa/core/strings.h"
#include "imgui_internal.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

constexpr float kToolsW = 112.0f;
constexpr float kSideW = 320.0f;
const char* kItemPayload = "FA_VECTOR_ITEM";

bool toggle_button(const char* label, bool on, ImVec2 size = ImVec2(0, 0)) {
    if (on) ImGui::PushStyleColor(ImGuiCol_Button, ImGui::GetStyleColorVec4(ImGuiCol_ButtonActive));
    const bool clicked = ImGui::Button(label, size);
    if (on) ImGui::PopStyleColor();
    return clicked;
}

void eye_icon(ImDrawList* dl, ImVec2 c, bool on, bool hot) {
    const ImU32 col = on ? (hot ? IM_COL32(255, 255, 255, 255) : IM_COL32(210, 210, 215, 255)) : IM_COL32(110, 110, 118, 255);
    dl->AddEllipse(c, ImVec2(6.5f, 4.0f), col, 0.0f, 16, 1.4f);
    if (on) dl->AddCircleFilled(c, 2.2f, col);
    else dl->AddLine(ImVec2(c.x - 6, c.y + 5), ImVec2(c.x + 6, c.y - 5), col, 1.4f);
}

void lock_icon(ImDrawList* dl, ImVec2 c, bool on, bool hot) {
    const ImU32 col = on ? IM_COL32(240, 190, 90, 255) : (hot ? IM_COL32(190, 190, 195, 255) : IM_COL32(95, 95, 103, 255));
    dl->AddRectFilled(ImVec2(c.x - 4.5f, c.y - 1), ImVec2(c.x + 4.5f, c.y + 5), col, 1.0f);
    if (on) dl->AddRect(ImVec2(c.x - 3, c.y - 6), ImVec2(c.x + 3, c.y + 0.5f), col, 3.0f, 0, 1.4f);
    else dl->AddLine(ImVec2(c.x + 3, c.y - 1), ImVec2(c.x + 3, c.y - 4), col, 1.4f);
}

std::string hex_of(const float c[4]) {
    auto q = [](float v) { return int(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
    char buf[16];
    std::snprintf(buf, sizeof buf, "#%02x%02x%02x", q(c[0]), q(c[1]), q(c[2]));
    return buf;
}

// "#rgb" or "#rrggbb" (any case) into 0..1 floats; false for a name, a url(#...) or "none".
bool colour_of(const std::string& s, float out[4]) {
    if (s.size() < 4 || s[0] != '#') return false;
    auto hv = [](char c) { return c >= '0' && c <= '9' ? c - '0' : (c >= 'a' && c <= 'f' ? c - 'a' + 10 : (c >= 'A' && c <= 'F' ? c - 'A' + 10 : -1)); };
    int v[3] = {0, 0, 0};
    if (s.size() == 4) {
        for (int i = 0; i < 3; ++i) {
            const int h = hv(s[std::size_t(i) + 1]);
            if (h < 0) return false;
            v[i] = h * 17;
        }
    } else if (s.size() == 7) {
        for (int i = 0; i < 3; ++i) {
            const int a = hv(s[std::size_t(i) * 2 + 1]), b = hv(s[std::size_t(i) * 2 + 2]);
            if (a < 0 || b < 0) return false;
            v[i] = a * 16 + b;
        }
    } else {
        return false;
    }
    out[0] = float(v[0]) / 255.0f;
    out[1] = float(v[1]) / 255.0f;
    out[2] = float(v[2]) / 255.0f;
    out[3] = 1.0f;
    return true;
}

ImU32 colour_u32(const std::string& s, ImU32 fallback) {
    float c[4];
    if (!colour_of(s, c)) return fallback;
    return IM_COL32(int(c[0] * 255 + 0.5f), int(c[1] * 255 + 0.5f), int(c[2] * 255 + 0.5f), 255);
}

Json refs_to_json(const std::vector<std::string>& refs) {
    Json out = Json::array();
    for (const std::string& r : refs) out.push_back(r);
    return out;
}

std::string label_of(const VecItem& it) {
    if (!it.id.empty()) return it.id;
    return "<" + it.tag + ">";
}

struct ShapeParam {
    const char* key;
    const char* label;
    double lo, hi, def;
    bool integer;
    const char* tip;
};

const std::vector<ShapeParam>& shape_params(const std::string& kind) {
    static const std::vector<ShapeParam> star = {
        {"radius", "Radius", 0.1, 5000, 30, false, "Distance from the centre to the tips."},
        {"points", "Points", 3, 128, 5, true, "How many tips."},
        {"innerRatio", "Inner ratio", 0.02, 0.98, 0.5, false, "The valleys' radius over the tips' radius."},
        {"roundness", "Roundness", 0, 1, 0, false, "0 sharp corners, 1 fully rounded."},
        {"rotation", "Rotation", -360, 360, -90, false, "Degrees; -90 points a tip up."}};
    static const std::vector<ShapeParam> gear = {
        {"radius", "Radius", 0.1, 5000, 30, false, "Distance from the centre to the tooth tips."},
        {"teeth", "Teeth", 3, 128, 8, true, "How many teeth."},
        {"depth", "Depth", 0, 2000, 6, false, "How tall a tooth is, in drawing units (default 0.2 of the radius)."},
        {"toothWidth", "Tooth width", 0, 2000, 4, false, "The width of a tooth at its tip, in drawing units (default 0.5 of the pitch)."},
        {"hole", "Hole", 0, 5000, 9, false, "Radius of the centre hole; 0 for none (default 0.3 of the radius)."},
        {"rotation", "Rotation", -360, 360, 0, false, "Degrees."}};
    static const std::vector<ShapeParam> polygon = {
        {"radius", "Radius", 0.1, 5000, 30, false, "Distance from the centre to the corners."},
        {"sides", "Sides", 3, 128, 6, true, "How many sides."},
        {"cornerRadius", "Corner radius", 0, 2000, 0, false, "A true circular fillet at the corners."},
        {"rotation", "Rotation", -360, 360, 0, false, "Degrees."}};
    static const std::vector<ShapeParam> arrow = {
        {"shaftWidth", "Shaft width", 0.1, 2000, 6, false, "Width of the shaft."},
        {"headLength", "Head length", 0.1, 2000, 14, false, "Length of the head."},
        {"headWidth", "Head width", 0.1, 2000, 16, false, "Width of the head."},
        {"curve", "Curve", -0.5, 0.5, 0, false, "Bend as a fraction of the length; positive to the right of from -> to."}};
    static const std::vector<ShapeParam> bubble = {
        {"width", "Width", 1, 5000, 50, false, "Width of the box."},
        {"height", "Height", 1, 5000, 30, false, "Height of the box."},
        {"cornerRadius", "Corner radius", 0, 2000, 8, false, "Rounding of the box."},
        {"tailWidth", "Tail width", 0.1, 2000, 10, false, "Width of the tail where it leaves the box."},
        {"tailRoundness", "Tail roundness", 0, 1, 0.5, false, "0 a sharp tail, 1 a round tip."}};
    static const std::vector<ShapeParam> none;
    if (kind == "star") return star;
    if (kind == "gear") return gear;
    if (kind == "polygon") return polygon;
    if (kind == "arrow") return arrow;
    if (kind == "bubble") return bubble;
    return none;
}

}  // namespace

// ----------------------------------------------------------------------------------------------------------- document --
VectorModel& Editor::vector_ensure_model() {
    if (!vector_.model) {
        vector_.model = std::make_unique<VectorModel>(projectDir_, [this](const std::string& name, const Json& args) {
            CommandResult r = engine_->commands().call(name, args);
            // a preview on text in memory (dryRun) writes nothing; the others change files the Project panel lists
            if (!args.is_object() || !args.value("dryRun", false)) after_command(name, args, r);
            return r;
        });
    }
    return *vector_.model;
}

bool Editor::open_vector_document(const std::string& rel) {
    if (!engine_) return false;
    vector_ensure_model();
    VectorUi& u = vector_;
    u.drag = VectorUi::Drag::None;
    u.renaming.clear();
    u.collapsed.clear();
    const bool ok = u.model->open(rel);
    u.openError = ok ? std::string() : u.model->error();
    u.fitNext = true;
    showVector_ = true;
    focus_window("Vector");
    if (!ok) notify("Cannot open " + rel + " in the Vector panel: " + u.model->error(), 2);
    return ok;
}

bool Editor::open_vector_layer(const std::string& documentRel, const std::string& layer) {
    if (!engine_) return false;
    vector_ensure_model();
    VectorUi& u = vector_;
    u.drag = VectorUi::Drag::None;
    u.renaming.clear();
    u.collapsed.clear();
    const bool ok = u.model->open_layer(documentRel, layer);
    u.openError = ok ? std::string() : u.model->error();
    u.fitNext = true;
    showVector_ = true;
    focus_window("Vector");
    if (!ok) notify("Cannot open the svg layer in the Vector panel: " + u.model->error(), 2);
    return ok;
}

void Editor::vector_close_document() {
    if (vector_.model) vector_.model->close();
    vector_.drag = VectorUi::Drag::None;
}

void Editor::vector_release_textures() {
    VectorUi& u = vector_;
    if (u.picture.image || u.picture.view) ui::destroy_texture(u.picture.image, u.picture.view);
    for (const VectorUi::Dead& d : u.graveyard) ui::destroy_texture(d.image, d.view);
    u.picture = VectorTexture{};
    u.graveyard.clear();
}

void Editor::vector_save() {
    VectorUi& u = vector_;
    if (!u.model || !u.model->is_open()) return;
    if (play_ != PlayState::Edit) {
        notify("Stop the game before saving the drawing.", 1);
        return;
    }
    const VectorEditOutcome out = u.model->save();
    if (!out.ok) notify(out.error, 2);
    else project_files_changed();
}

void Editor::vector_edited(const VectorEditOutcome& out) {
    VectorUi& u = vector_;
    if (!out.ok) {
        notify(out.error, 1);
        return;
    }
    if (out.step <= 0 || !u.model) return;
    undo_.push_back(Json::object({{"$vector", Json::object({{"step", out.step}})}}));
    if (undo_.size() > 100) undo_.erase(undo_.begin());
    redo_.clear();
    lastEditKey_.clear();
    vector_collect_steps();
}

void Editor::vector_collect_steps() {
    if (!vector_.model) return;
    std::set<int> keep;
    for (const auto* stack : {&undo_, &redo_})
        for (const Json& e : *stack)
            if (e.is_object() && e.contains("$vector") && e["$vector"].is_object() && e["$vector"].value("step", 0) > 0)
                keep.insert(e["$vector"]["step"].get<int>());
    vector_.model->retain_steps(keep);
}

void Editor::vector_apply_undo(const Json& entry, bool forward) {
    VectorUi& u = vector_;
    const int id = entry["$vector"].value("step", 0);
    if (!u.model || !u.model->step(id)) {
        notify("That vector edit is no longer remembered.", 1);
        return;
    }
    const std::string doc = u.model->step_document(id);
    const std::string layer = u.model->step_layer(id);
    if (!doc.empty() && (doc != u.model->path() || layer != u.model->layer())) {
        if (layer.empty()) open_vector_document(doc);
        else open_vector_layer(doc, layer);
    }
    if (!u.model->apply_step(id, forward)) {
        notify("Could not " + std::string(forward ? "redo" : "undo") + " the vector edit: " + u.model->status(), 2);
        return;
    }
    (forward ? undo_ : redo_).push_back(entry);
    project_files_changed();
}

// ---------------------------------------------------------------------------------------------------------- the panel --
void Editor::draw_vector_panel() {
    VectorUi& u = vector_;
    ImGui::SetNextWindowPos(ImVec2(180, 80), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(1120, 740), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Vector", &showVector_)) {
        u.focused = false;
        ImGui::End();
        return;
    }
    u.focused = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows);
    for (std::size_t i = 0; i < u.graveyard.size();) {
        if (u.graveyard[i].frame + 4 < uiFrame_) {
            ui::destroy_texture(u.graveyard[i].image, u.graveyard[i].view);
            u.graveyard.erase(u.graveyard.begin() + long(i));
        } else {
            ++i;
        }
    }
    VectorModel& m = vector_ensure_model();
    if (!m.is_open()) {
        draw_vector_toolbar(m);
        ImGui::Spacing();
        ImGui::TextDisabled("Open a drawing (*.svg) from the list above, or double click one in the Project panel.");
        ImGui::TextDisabled("An svg layer of an image document opens here from the Image panel (Edit in Vector panel).");
        if (!u.openError.empty()) ImGui::TextColored(ImVec4(1.0f, 0.55f, 0.45f, 1), "%s", u.openError.c_str());
        ImGui::End();
        return;
    }
    // The files may have changed behind our back (the Console, an AI, the Image panel): look a few times a second.
    if (uiFrame_ - u.lastPoll >= 20 && u.drag == VectorUi::Drag::None && !m.previewing() && !m.pen().active) {
        u.lastPoll = uiFrame_;
        if (m.poll_external()) m.set_status("The file changed on disk and was read again.");
    }
    draw_vector_toolbar(m);
    if (!m.valid()) {
        ImGui::Spacing();
        ImGui::TextColored(ImVec4(1.0f, 0.55f, 0.45f, 1), "This drawing does not load:");
        ImGui::TextWrapped("%s", m.error().c_str());
        ImGui::TextDisabled("Fix it with the Console (fs.edit, vector.set_path) or an editor, then Reload.");
        ImGui::End();
        return;
    }
    if (play_ != PlayState::Edit) ImGui::TextColored(ImVec4(1.0f, 0.8f, 0.4f, 1), "The game is running: stop it to edit the drawing.");

    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const float sideW = std::min(kSideW, std::max(230.0f, avail.x * 0.32f));
    const float centerW = std::max(100.0f, avail.x - kToolsW - sideW - ImGui::GetStyle().ItemSpacing.x * 2);
    ImGui::BeginChild("##vectools", ImVec2(kToolsW, avail.y), false);
    draw_vector_tools(m);
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##vecc", ImVec2(centerW, avail.y), false, ImGuiWindowFlags_NoScrollbar);
    draw_vector_actions(m);
    {
        const float statusH = ImGui::GetTextLineHeightWithSpacing() + 6;
        ImVec2 canvas = ImGui::GetContentRegionAvail();
        canvas.y = std::max(60.0f, canvas.y - statusH - ImGui::GetStyle().ItemSpacing.y);
        draw_vector_canvas(m, canvas);
        std::string line = m.status();
        if (u.mouseInside) line += (line.empty() ? "" : "   |   ") + std::format("x {:.1f} y {:.1f}", u.mouse.x, u.mouse.y);
        VecRect b;
        if (m.selection_bounds(b, false)) line += std::format("   |   {} selected, {:.1f} x {:.1f}", m.selection().size(), b.width(), b.height());
        line += std::format("   |   {}%   |   read {:.1f} ms, draw {:.1f} ms", int(std::lround(u.zoom * 100)), m.last_scene_ms(), m.last_raster_ms());
        ImGui::TextDisabled("%s", line.c_str());
    }
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##vecside", ImVec2(sideW, avail.y), false);
    draw_vector_side(m);
    ImGui::EndChild();
    ImGui::End();
}

// -------------------------------------------------------------------------------------------------------------- toolbar --
void Editor::draw_vector_toolbar(VectorModel& m) {
    VectorUi& u = vector_;
    const bool editable = play_ == PlayState::Edit;
    std::vector<std::string> files;
    for (const BrowserFile& f : projBrowser_.listing.files)
        if (ends_with(f.path, ".svg")) files.push_back(f.path);
    std::sort(files.begin(), files.end());
    const std::string current = m.is_open() ? m.title() : std::string();
    ImGui::SetNextItemWidth(280);
    if (ImGui::BeginCombo("##vecdoc", current.empty() ? "Open a drawing..." : current.c_str())) {
        for (const std::string& f : files) {
            if (ImGui::Selectable(f.c_str(), !m.is_layer() && f == m.path())) open_vector_document(f);
            at_track("vec:doc:" + f);
        }
        if (files.empty()) ImGui::TextDisabled("No *.svg in the project yet. Use New.");
        ImGui::EndCombo();
    }
    at_track("vec:open");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("The drawings (*.svg) of the project. A double click in the Project panel opens one too.");
    ImGui::SameLine();
    if (ImGui::Button("New...")) ImGui::OpenPopup("##vecnew");
    at_track("vec:new");
    if (ImGui::BeginPopup("##vecnew")) {
        ImGui::TextUnformatted("New drawing (an empty SVG)");
        ImGui::SetNextItemWidth(220);
        ImGui::InputText("Name", &u.newDocName);
        ImGui::SetNextItemWidth(120);
        ImGui::InputInt("Size", &u.newDocSize);
        u.newDocSize = std::clamp(u.newDocSize, 1, 8192);
        ImGui::TextDisabled("assets/%s.svg, viewBox 0 0 %d %d", u.newDocName.c_str(), u.newDocSize, u.newDocSize);
        if (ImGui::Button("Create") && editable && !u.newDocName.empty()) {
            const std::string path = "assets/" + u.newDocName + ".svg";
            const std::string size = std::to_string(u.newDocSize);
            const std::string text = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " + size + " " + size + "\" width=\"" + size +
                                     "\" height=\"" + size + "\">\n</svg>\n";
            const Json args = Json::object({{"path", path}, {"content", text}});
            const CommandResult r = engine_->commands().call("fs.write", args);
            after_command("fs.write", args, r);
            if (r.ok) {
                open_vector_document(path);
                ImGui::CloseCurrentPopup();
            } else {
                notify("fs.write: " + command_error_text(r.error), 2);
            }
        }
        at_track("vec:new:create");
        ImGui::EndPopup();
    }
    if (!m.is_open()) return;
    ImGui::SameLine();
    ImGui::BeginDisabled(!editable || !m.valid());
    if (ImGui::Button(m.is_layer() ? "Save + bake" : "Save")) vector_save();
    at_track("vec:save");
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip(m.is_layer() ? "Bakes the image document's PNG from this layer (image.save), like the command. Ctrl+S while this panel has the keyboard.\n"
                                         "Every edit is already written to the layer."
                                       : "Every edit is written to the file as you make it, like the vector.* commands do; there is nothing left to save.");
    ImGui::SameLine();
    if (ImGui::Button("Reload")) {
        m.reload();
        u.drag = VectorUi::Drag::None;
    }
    at_track("vec:reload");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Reads the file again; the undo steps stay.");
    if (m.is_layer()) {
        ImGui::SameLine();
        if (ImGui::Button("Image panel")) open_image_document(m.path());
        at_track("vec:to_image");
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("Show the image document this layer belongs to.");
    }
    ImGui::SameLine(0, 24);
    if (ImGui::Button("Fit")) u.fitNext = true;
    at_track("vec:fit");
    ImGui::SameLine();
    if (ImGui::Button("1:1")) {
        const ImVec2 mid(u.canvasX + u.canvasW * 0.5f, u.canvasY + u.canvasH * 0.5f);
        const VecPoint at = vector_from_screen(mid);
        const VecRect cv = m.scene().canvas;
        u.zoom = 1.0f;
        u.panX = (mid.x - u.canvasX) - float(at.x - cv.x0) * u.zoom;
        u.panY = (mid.y - u.canvasY) - float(at.y - cv.y0) * u.zoom;
        u.fitNext = false;
    }
    at_track("vec:zoom100");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(60);
    int pct = int(std::lround(u.zoom * 100));
    if (ImGui::InputInt("##veczoom", &pct, 0, 0, ImGuiInputTextFlags_EnterReturnsTrue)) {
        const ImVec2 mid(u.canvasX + u.canvasW * 0.5f, u.canvasY + u.canvasH * 0.5f);
        const VecPoint at = vector_from_screen(mid);
        const VecRect cv = m.scene().canvas;
        u.zoom = std::clamp(float(pct) / 100.0f, 0.02f, 256.0f);
        u.panX = (mid.x - u.canvasX) - float(at.x - cv.x0) * u.zoom;
        u.panY = (mid.y - u.canvasY) - float(at.y - cv.y0) * u.zoom;
        u.fitNext = false;
    }
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("Zoom in percent (1 drawing unit = 1 pixel at 100%%). The wheel zooms around the pointer; the middle button, Space + drag or Shift + wheel pans.");
    ImGui::SameLine(0, 2);
    ImGui::TextDisabled("%%");
    ImGui::SameLine(0, 16);
    ImGui::Checkbox("Grid", &m.snapping.grid);
    at_track("vec:snap:grid");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Snap to a grid of the size set in Snap...; the grid lines show while this is on.");
    ImGui::SameLine();
    ImGui::Checkbox("Points", &m.snapping.points);
    at_track("vec:snap:points");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Snap to the nodes, bounding-box corners and centres of the other shapes and to the canvas corners and centre. A point wins over the grid and the guides.");
    ImGui::SameLine();
    ImGui::Checkbox("Guides", &m.snapping.guides);
    at_track("vec:snap:guides");
    ImGui::SameLine();
    if (ImGui::Button("Snap...")) ImGui::OpenPopup("##vecsnap");
    at_track("vec:snap");
    if (ImGui::BeginPopup("##vecsnap")) {
        float gs = float(m.snapping.gridSize);
        ImGui::SetNextItemWidth(120);
        if (ImGui::InputFloat("Grid size", &gs, 1.0f, 10.0f, "%.2f")) m.snapping.gridSize = std::max(0.01, double(gs));
        at_track("vec:snap:size");
        ImGui::TextDisabled("in drawing units");
        ImGui::Separator();
        ImGui::TextUnformatted("Guides");
        double g = u.newGuide;
        ImGui::SetNextItemWidth(100);
        if (ImGui::InputDouble("##guidepos", &g, 0, 0, "%.2f")) u.newGuide = g;
        at_track("vec:guide:pos");
        ImGui::SameLine();
        if (ImGui::Button("Vertical")) m.guidesX.push_back(u.newGuide);
        at_track("vec:guide:x");
        ImGui::SameLine();
        if (ImGui::Button("Horizontal")) m.guidesY.push_back(u.newGuide);
        at_track("vec:guide:y");
        for (std::size_t i = 0; i < m.guidesX.size(); ++i) {
            ImGui::PushID(int(i));
            ImGui::Text("x = %.2f", m.guidesX[i]);
            ImGui::SameLine();
            if (ImGui::SmallButton("Remove")) {
                m.guidesX.erase(m.guidesX.begin() + long(i));
                ImGui::PopID();
                break;
            }
            ImGui::PopID();
        }
        for (std::size_t i = 0; i < m.guidesY.size(); ++i) {
            ImGui::PushID(int(i) + 10000);
            ImGui::Text("y = %.2f", m.guidesY[i]);
            ImGui::SameLine();
            if (ImGui::SmallButton("Remove")) {
                m.guidesY.erase(m.guidesY.begin() + long(i));
                ImGui::PopID();
                break;
            }
            ImGui::PopID();
        }
        ImGui::EndPopup();
    }
}

// ------------------------------------------------------------------------------------------------------------------ tools --
void Editor::draw_vector_tools(VectorModel& m) {
    VectorUi& u = vector_;
    const bool editable = play_ == PlayState::Edit;
    ImGui::BeginDisabled(!editable);
    static const char* kHotkeys[] = {"V", "A", "P", "R", "O", "L", "S"};
    int k = 0;
    for (VectorTool t : vector_tools()) {
        const std::string label = std::string(vector_tool_name(t)) + "  " + kHotkeys[k++];
        if (t == VectorTool::Pen) ImGui::Separator();
        if (toggle_button(label.c_str(), u.tool == t, ImVec2(kToolsW - 8, 0))) {
            if (m.pen().active) {
                if (m.pen_can_finish()) vector_edited(m.pen_finish(false));
                else m.pen_cancel();
            }
            u.tool = t;
        }
        at_track(std::string("vec:tool:") + vector_tool_name(t));
        if (ImGui::IsItemHovered()) {
            switch (t) {
                case VectorTool::Select: ImGui::SetTooltip("Click a shape, drag a box to select several (Shift adds), drag to move, drag a handle of the box to scale, outside a corner to rotate. Double click a group to go into it."); break;
                case VectorTool::Node: ImGui::SetTooltip("Edit the nodes of the selected shape: drag anchors and handles, double click a segment to add a node, double click a node to switch corner and smooth. Alt while dragging a handle breaks the link between the two."); break;
                case VectorTool::Pen: ImGui::SetTooltip("Click for a corner, drag for a curve, click the first node to close. Enter or a double click ends an open path, Esc drops it. A click on the end of the selected open path continues it."); break;
                case VectorTool::Rectangle: ImGui::SetTooltip("Drag a box. Shift makes a square, Alt draws from the centre."); break;
                case VectorTool::Ellipse: ImGui::SetTooltip("Drag a box. Shift makes a circle, Alt draws from the centre."); break;
                case VectorTool::Line: ImGui::SetTooltip("Drag from one end to the other. Shift snaps the angle to 45 degrees."); break;
                case VectorTool::Shape: ImGui::SetTooltip("Drag out a parametric shape (vector.shape): its parameters stay editable in the inspector."); break;
            }
        }
    }
    ImGui::EndDisabled();
    ImGui::Spacing();
    ImGui::Separator();
    ImGui::TextDisabled("New shapes");
    float fill[4];
    if (!colour_of(m.style.fill, fill)) {
        fill[0] = fill[1] = fill[2] = 0.5f;
        fill[3] = 1;
    }
    ImGui::SetNextItemWidth(kToolsW - 8);
    if (ImGui::ColorEdit3("##newfill", fill, ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoLabel)) m.style.fill = hex_of(fill);
    at_track("vec:newfill");
    ImGui::SameLine();
    ImGui::TextDisabled("Fill");
    float stroke[4];
    if (!colour_of(m.style.stroke, stroke)) {
        stroke[0] = stroke[1] = stroke[2] = 0.1f;
        stroke[3] = 1;
    }
    if (ImGui::ColorEdit3("##newstroke", stroke, ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoLabel)) {
        m.style.stroke = hex_of(stroke);
        m.style.useStroke = true;
    }
    at_track("vec:newstroke");
    ImGui::SameLine();
    ImGui::Checkbox("Line", &m.style.useStroke);
    at_track("vec:newstroke:use");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Give new closed shapes an outline. Open paths and lines always have a stroke.");
    float sw = float(m.style.strokeWidth);
    ImGui::SetNextItemWidth(kToolsW - 8);
    if (ImGui::DragFloat("##newsw", &sw, 0.1f, 0.1f, 200.0f, "%.1f")) m.style.strokeWidth = std::max(0.1f, sw);
    at_track("vec:newstroke:width");
    if (!m.palette().empty()) {
        ImGui::TextDisabled("Palette");
        int col = 0;
        for (const std::string& hex : m.palette()) {
            ImGui::PushID(hex.c_str());
            float c[4];
            colour_of(hex, c);
            if (ImGui::ColorButton("##sw", ImVec4(c[0], c[1], c[2], 1), ImGuiColorEditFlags_NoTooltip, ImVec2(16, 16))) m.style.fill = hex;
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s (new shapes' fill)", hex.c_str());
            ImGui::PopID();
            if (++col % 5 != 0) ImGui::SameLine(0, 2);
        }
        if (col % 5 != 0) ImGui::NewLine();
    }
    if (u.tool == VectorTool::Shape) {
        ImGui::Spacing();
        ImGui::TextDisabled("Shape");
        ImGui::SetNextItemWidth(kToolsW - 8);
        if (ImGui::BeginCombo("##shapekind", u.shapeKind.c_str())) {
            for (const char* kind : {"star", "gear", "polygon", "arrow", "bubble", "ribbon"})
                if (ImGui::Selectable(kind, u.shapeKind == kind)) u.shapeKind = kind;
            ImGui::EndCombo();
        }
        at_track("vec:shapekind");
    }
}

// ----------------------------------------------------------------------------------------------------------------- actions --
void Editor::draw_vector_actions(VectorModel& m) {
    VectorUi& u = vector_;
    const bool editable = play_ == PlayState::Edit && m.valid();
    const std::size_t count = m.selection().size();
    ImGui::BeginDisabled(!editable);
    auto act = [&](const char* label, const char* track, const char* tip, std::size_t minCount, auto&& fn) {
        ImGui::BeginDisabled(count < minCount);
        if (ImGui::Button(label)) fn();
        at_track(std::string("vec:act:") + track);
        ImGui::EndDisabled();
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("%s", tip);
        ImGui::SameLine();
    };
    ImGui::TextDisabled("Shapes");
    ImGui::SameLine();
    act("Union", "union", "vector.boolean union: merge the selected shapes into one path (it keeps the first one's id and style).", 2, [&] { vector_edited(m.boolean_op("union")); });
    act("Subtract", "subtract", "vector.boolean subtract: remove the later shapes from the first.", 2, [&] { vector_edited(m.boolean_op("subtract")); });
    act("Intersect", "intersect", "vector.boolean intersect: keep what all the shapes cover.", 2, [&] { vector_edited(m.boolean_op("intersect")); });
    act("Exclude", "exclude", "vector.boolean exclude: keep what an odd number of shapes cover.", 2, [&] { vector_edited(m.boolean_op("exclude")); });
    ImGui::TextUnformatted("|");
    ImGui::SameLine();
    act("Group", "group", "vector.group (Ctrl+G).", 1, [&] { vector_edited(m.group_selection()); });
    act("Ungroup", "ungroup", "vector.ungroup (Ctrl+Shift+G): the children stay where they are.", 1, [&] { vector_edited(m.ungroup_selection()); });
    act("Front", "front", "vector.reorder front: draw the selection on top.", 1, [&] { vector_edited(m.reorder(m.selection(), "front")); });
    act("Back", "back", "vector.reorder back: draw the selection behind the rest.", 1, [&] { vector_edited(m.reorder(m.selection(), "back")); });
    ImGui::NewLine();

    ImGui::TextDisabled("Path  ");
    ImGui::SameLine();
    // buttons that ask for numbers open a popup
    if (count < 1) ImGui::BeginDisabled();
    if (ImGui::Button("Offset...")) ImGui::OpenPopup("##vecoffset");
    at_track("vec:act:offset");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("vector.offset: grow or shrink the outline.");
    if (count < 1) ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::BeginPopup("##vecoffset")) {
        double d = u.offsetDistance;
        ImGui::SetNextItemWidth(120);
        if (ImGui::InputDouble("Distance", &d, 0.5, 5, "%.2f")) u.offsetDistance = d;
        at_track("vec:offset:distance");
        static const char* kJoins[] = {"round", "miter", "bevel", "square"};
        ImGui::SetNextItemWidth(120);
        ImGui::Combo("Join", &u.offsetJoin, kJoins, 4);
        ImGui::Checkbox("Keep the original (copy)", &u.offsetCopy);
        ImGui::TextDisabled("Positive grows, negative insets.");
        if (ImGui::Button("Apply") && std::abs(u.offsetDistance) > 1e-9) {
            vector_edited(m.edit_selection("Offset", "vector.offset",
                                           Json::object({{"distance", u.offsetDistance}, {"join", kJoins[u.offsetJoin]}, {"copy", u.offsetCopy}})));
            ImGui::CloseCurrentPopup();
        }
        at_track("vec:offset:apply");
        ImGui::EndPopup();
    }
    if (count < 1) ImGui::BeginDisabled();
    if (ImGui::Button("Simplify...")) ImGui::OpenPopup("##vecsimplify");
    at_track("vec:act:simplify");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("vector.simplify: fewer nodes within a tolerance.");
    if (count < 1) ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::BeginPopup("##vecsimplify")) {
        double t = u.simplifyTolerance;
        ImGui::SetNextItemWidth(120);
        if (ImGui::InputDouble("Tolerance", &t, 0.1, 1, "%.2f")) u.simplifyTolerance = std::max(0.001, t);
        ImGui::TextDisabled("The largest distance the result may be from the outline.");
        if (ImGui::Button("Apply")) {
            vector_edited(m.edit_selection("Simplify", "vector.simplify", Json::object({{"tolerance", u.simplifyTolerance}})));
            ImGui::CloseCurrentPopup();
        }
        at_track("vec:simplify:apply");
        ImGui::EndPopup();
    }
    if (count < 1) ImGui::BeginDisabled();
    if (ImGui::Button("Smooth...")) ImGui::OpenPopup("##vecsmooth");
    at_track("vec:act:smooth");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("vector.smooth: give the nodes that are not sharp corners smooth handles.");
    if (count < 1) ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::BeginPopup("##vecsmooth")) {
        float s = float(u.smoothness);
        ImGui::SetNextItemWidth(140);
        if (ImGui::SliderFloat("Smoothness", &s, 0.0f, 1.0f, "%.2f")) u.smoothness = s;
        if (ImGui::Button("Apply")) {
            vector_edited(m.edit_selection("Smooth", "vector.smooth", Json::object({{"smoothness", u.smoothness}})));
            ImGui::CloseCurrentPopup();
        }
        at_track("vec:smooth:apply");
        ImGui::EndPopup();
    }
    if (count < 1) ImGui::BeginDisabled();
    if (ImGui::Button("Mirror...")) ImGui::OpenPopup("##vecmirror");
    at_track("vec:act:mirror");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("vector.mirror: reflect across the middle of the drawing; welded into one path or kept as a copy.");
    if (count < 1) ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::BeginPopup("##vecmirror")) {
        static const char* kAxes[] = {"vertical", "horizontal"};
        ImGui::SetNextItemWidth(120);
        ImGui::Combo("Axis", &u.mirrorAxis, kAxes, 2);
        ImGui::Checkbox("Weld into one path", &u.mirrorWeld);
        ImGui::TextDisabled("The line is the middle of the drawing.\nWith an exact line, use vector.mirror `at` in the Console.");
        if (ImGui::Button("Apply")) {
            vector_edited(m.edit_selection("Mirror", "vector.mirror", Json::object({{"axis", kAxes[u.mirrorAxis]}, {"weld", u.mirrorWeld}})));
            ImGui::CloseCurrentPopup();
        }
        at_track("vec:mirror:apply");
        ImGui::EndPopup();
    }
    act("Outline", "outline", "vector.stroke_to_path: turn the stroke into a filled outline.", 1, [&] { vector_edited(m.edit_selection("Stroke to path", "vector.stroke_to_path")); });
    ImGui::NewLine();

    ImGui::TextDisabled("Arrange");
    ImGui::SameLine();
    if (count < 1) ImGui::BeginDisabled();
    if (ImGui::Button("Align...")) ImGui::OpenPopup("##vecalign");
    at_track("vec:act:align");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("vector.align: to each other (two or more selected) or to the canvas (one).");
    if (count < 1) ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::BeginPopup("##vecalign")) {
        struct A {
            const char* label;
            const char* axis;
            const char* value;
        };
        static const A kAlign[] = {{"Left", "horizontal", "left"}, {"Centre", "horizontal", "center"}, {"Right", "horizontal", "right"},
                                   {"Top", "vertical", "top"},     {"Middle", "vertical", "middle"},    {"Bottom", "vertical", "bottom"}};
        for (int i = 0; i < 6; ++i) {
            if (i % 3 != 0) ImGui::SameLine();
            if (ImGui::Button(kAlign[i].label)) {
                vector_edited(m.edit_selection(std::string("Align ") + kAlign[i].label, "vector.align", Json::object({{kAlign[i].axis, kAlign[i].value}})));
                ImGui::CloseCurrentPopup();
            }
            at_track(std::string("vec:align:") + kAlign[i].value);
        }
        ImGui::EndPopup();
    }
    if (count < 3) ImGui::BeginDisabled();
    if (ImGui::Button("Distribute...")) ImGui::OpenPopup("##vecdistribute");
    at_track("vec:act:distribute");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("vector.distribute: equal gaps between three or more shapes.");
    if (count < 3) ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::BeginPopup("##vecdistribute")) {
        if (ImGui::Button("Horizontally")) {
            vector_edited(m.edit_selection("Distribute horizontally", "vector.distribute", Json::object({{"axis", "horizontal"}})));
            ImGui::CloseCurrentPopup();
        }
        at_track("vec:distribute:horizontal");
        ImGui::SameLine();
        if (ImGui::Button("Vertically")) {
            vector_edited(m.edit_selection("Distribute vertically", "vector.distribute", Json::object({{"axis", "vertical"}})));
            ImGui::CloseCurrentPopup();
        }
        at_track("vec:distribute:vertical");
        ImGui::EndPopup();
    }
    ImGui::TextUnformatted("|");
    ImGui::SameLine();
    ImGui::TextDisabled("Style");
    ImGui::SameLine();
    act("House style", "style", "vector.style: the outline and palette of the project's style (assets.json).", 1, [&] { vector_edited(m.edit_selection("House style", "vector.style")); });
    act("To palette", "palette", "vector.style palette: snap fills and strokes to the nearest colour of the project's palette.", 1, [&] {
        vector_edited(m.edit_selection("Snap to palette", "vector.style", Json::object({{"palette", true}, {"outline", false}})));
    });
    if (count < 1) ImGui::BeginDisabled();
    if (ImGui::Button("Shade...")) ImGui::OpenPopup("##vecshade");
    at_track("vec:act:shade");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("vector.shade: shadow and highlight bands from a light direction.");
    if (count < 1) ImGui::EndDisabled();
    if (ImGui::BeginPopup("##vecshade")) {
        static const char* kLights[] = {"(project default)", "upper-left", "top", "upper-right", "left", "right", "lower-left", "bottom", "lower-right"};
        ImGui::SetNextItemWidth(160);
        ImGui::Combo("Light", &u.shadeLight, kLights, 9);
        double d = u.shadeDepth;
        ImGui::SetNextItemWidth(120);
        if (ImGui::InputDouble("Depth", &d, 0.5, 5, "%.2f")) u.shadeDepth = std::max(0.0, d);
        ImGui::TextDisabled("0 = 10%% of the shape's smaller side.");
        if (ImGui::Button("Apply")) {
            Json args = Json::object();
            if (u.shadeLight > 0) args["light"] = kLights[u.shadeLight];
            if (u.shadeDepth > 0) args["depth"] = u.shadeDepth;
            vector_edited(m.edit_selection("Shade", "vector.shade", args));
            ImGui::CloseCurrentPopup();
        }
        at_track("vec:shade:apply");
        ImGui::EndPopup();
    }
    ImGui::NewLine();

    if (u.tool == VectorTool::Node) {
        ImGui::TextDisabled("Nodes  ");
        ImGui::SameLine();
        const std::vector<VectorNodeRef>& sel = m.selected_nodes();
        const bool any = !sel.empty() && editable;
        auto nodes_of_one_shape = [&]() { return !sel.empty() && std::all_of(sel.begin(), sel.end(), [&](const VectorNodeRef& n) { return n.shape == sel[0].shape; }); };
        auto convert = [&](const char* kind) {
            Json ops = Json::array();
            for (const VectorNodeRef& n : sel) ops.push_back(Json::object({{"op", "convert"}, {"subpath", n.subpath}, {"node", n.node}, {"to", kind}}));
            vector_edited(m.node_ops(sel[0].shape, ops, std::string("Make ") + kind));
        };
        ImGui::BeginDisabled(!any || !nodes_of_one_shape());
        if (ImGui::Button("Add node")) {
            // a node in the middle of each segment between selected neighbours; with one node selected, after it
            Json ops = Json::array();
            std::vector<VectorNodeRef> s = sel;
            std::sort(s.begin(), s.end(), [](const VectorNodeRef& a, const VectorNodeRef& b) { return a.subpath != b.subpath ? a.subpath > b.subpath : a.node > b.node; });
            for (const VectorNodeRef& n : s) ops.push_back(Json::object({{"op", "insert"}, {"subpath", n.subpath}, {"segment", n.node}, {"t", 0.5}}));
            vector_edited(m.node_ops(sel[0].shape, ops, "Add node"));
            m.select_nodes({});
        }
        at_track("vec:node:add");
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Insert a node in the middle of the segment after each selected node.");
        ImGui::SameLine();
        if (ImGui::Button("Delete")) {
            Json ops = Json::array();
            std::vector<VectorNodeRef> s = sel;
            std::sort(s.begin(), s.end(), [](const VectorNodeRef& a, const VectorNodeRef& b) { return a.subpath != b.subpath ? a.subpath > b.subpath : a.node > b.node; });
            for (const VectorNodeRef& n : s) ops.push_back(Json::object({{"op", "delete"}, {"subpath", n.subpath}, {"node", n.node}}));
            vector_edited(m.node_ops(sel[0].shape, ops, "Delete nodes"));
            m.select_nodes({});
        }
        at_track("vec:node:delete");
        ImGui::SameLine();
        if (ImGui::Button("Corner")) convert("corner");
        at_track("vec:node:corner");
        ImGui::SameLine();
        if (ImGui::Button("Smooth")) convert("smooth");
        at_track("vec:node:smooth");
        ImGui::SameLine();
        if (ImGui::Button("Symmetric")) convert("symmetric");
        at_track("vec:node:symmetric");
        ImGui::SameLine();
        if (ImGui::Button("Break")) {
            vector_edited(m.node_ops(sel[0].shape, Json::array({Json::object({{"op", "break"}, {"subpath", sel[0].subpath}, {"node", sel[0].node}})}), "Break path"));
            m.select_nodes({});
        }
        at_track("vec:node:break");
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Cut the path at the first selected node.");
        ImGui::SameLine();
        ImGui::EndDisabled();
        ImGui::BeginDisabled(!(editable && sel.size() == 2 && nodes_of_one_shape()));
        if (ImGui::Button("Join")) {
            vector_edited(m.node_ops(sel[0].shape,
                                     Json::array({Json::object({{"op", "join"}, {"subpath", sel[0].subpath}, {"node", sel[0].node},
                                                                {"other", sel[1].subpath}, {"otherNode", sel[1].node}})}),
                                     "Join nodes"));
            m.select_nodes({});
        }
        at_track("vec:node:join");
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Join two selected ends of open paths (the two ends of one path close it).");
        ImGui::EndDisabled();
        ImGui::SameLine();
        ImGui::BeginDisabled(!any || !nodes_of_one_shape());
        if (ImGui::Button("Close")) vector_edited(m.node_ops(sel[0].shape, Json::array({Json::object({{"op", "close"}, {"subpath", sel[0].subpath}})}), "Close path"));
        at_track("vec:node:close");
        ImGui::SameLine();
        if (ImGui::Button("Reverse")) vector_edited(m.node_ops(sel[0].shape, Json::array({Json::object({{"op", "reverse"}, {"subpath", sel[0].subpath}})}), "Reverse path"));
        at_track("vec:node:reverse");
        ImGui::EndDisabled();
    }
    ImGui::EndDisabled();
}

// ------------------------------------------------------------------------------------------------------------------ side --
void Editor::draw_vector_side(VectorModel& m) {
    draw_vector_layers(m);
    ImGui::Spacing();
    ImGui::Separator();
    ImGui::BeginChild("##vecinsp", ImVec2(0, 0), false);
    draw_vector_inspector(m);
    ImGui::EndChild();
}

// The rows of the layer list: the elements of the drawing, the topmost first, groups with their children indented.
void Editor::draw_vector_layers(VectorModel& m) {
    VectorUi& u = vector_;
    const bool editable = play_ == PlayState::Edit;
    const VecScene& sc = m.scene();
    ImGui::AlignTextToFramePadding();
    ImGui::TextUnformatted("Layers");
    ImGui::SameLine();
    ImGui::TextDisabled("%d elements", int(sc.items.size()));
    ImGui::BeginChild("##veclist", ImVec2(0, std::max(140.0f, ImGui::GetContentRegionAvail().y * 0.45f)), true);
    constexpr float rowH = 24.0f;
    std::string dropSrc;
    int dropTarget = -1, dropZone = 0;   // -1 above the target in the list, 0 into it, 1 below
    std::function<void(int, int)> rows = [&](int parent, int depth) {
        const std::vector<int> kids = parent < 0 ? sc.roots() : sc.items[std::size_t(parent)].children;
        for (auto it = kids.rbegin(); it != kids.rend(); ++it) {
            const VecItem& r = sc.items[std::size_t(*it)];
            ImGui::PushID(r.ref.c_str());
            const ImVec2 p0 = ImGui::GetCursorScreenPos();
            const float w = ImGui::GetContentRegionAvail().x;
            const bool sel = m.is_selected(r.ref);
            const bool dim = r.hidden || r.hiddenByAncestor;
            if (ImGui::Selectable("##row", sel, ImGuiSelectableFlags_AllowDoubleClick | ImGuiSelectableFlags_AllowOverlap, ImVec2(w, rowH))) {
                const ImGuiIO& io = ImGui::GetIO();
                const std::string ctx = r.parent >= 0 ? sc.items[std::size_t(r.parent)].ref : std::string();
                if (io.KeyCtrl || io.KeySuper || io.KeyShift) {
                    if (ctx == m.context()) m.toggle_selected(r.ref);
                } else {
                    m.set_context(ctx);
                    m.select({r.ref});
                }
            }
            at_track("vec:layer:" + label_of(r));
            if (ImGui::IsItemHovered() && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left) && editable) {
                u.renaming = r.ref;
                u.renameBuf = r.id;
                u.renameFocus = true;
            }
            if (ImGui::IsItemHovered()) u.hover = r.ref;
            if (editable && !r.locked && ImGui::BeginDragDropSource(ImGuiDragDropFlags_None)) {
                ImGui::SetDragDropPayload(kItemPayload, r.ref.c_str(), r.ref.size() + 1);
                ImGui::TextUnformatted(label_of(r).c_str());
                ImGui::EndDragDropSource();
            }
            if (editable && ImGui::BeginDragDropTarget()) {
                const ImGuiPayload* pl = ImGui::AcceptDragDropPayload(kItemPayload, ImGuiDragDropFlags_AcceptBeforeDelivery | ImGuiDragDropFlags_AcceptNoDrawDefaultRect);
                if (pl) {
                    const std::string src(static_cast<const char*>(pl->Data));
                    const float t = (ImGui::GetMousePos().y - p0.y) / rowH;
                    const int zone = t < 0.28f ? -1 : (t > 0.72f ? 1 : (r.isGroup ? 0 : (t < 0.5f ? -1 : 1)));
                    const int si = sc.find(src);
                    const bool inside = si < 0 || r.ref == src || sc.is_descendant(r.index, si);
                    ImDrawList* dl = ImGui::GetWindowDrawList();
                    if (!inside) {
                        if (zone == 0) dl->AddRect(p0, ImVec2(p0.x + w, p0.y + rowH), IM_COL32(110, 170, 255, 255), 2.0f, 0, 2.0f);
                        else dl->AddLine(ImVec2(p0.x, zone < 0 ? p0.y : p0.y + rowH), ImVec2(p0.x + w, zone < 0 ? p0.y : p0.y + rowH), IM_COL32(110, 170, 255, 255), 2.0f);
                    }
                    if (pl->IsDelivery() && !inside) {
                        dropSrc = src;
                        dropTarget = r.index;
                        dropZone = zone;
                    }
                }
                ImGui::EndDragDropTarget();
            }
            ImDrawList* dl = ImGui::GetWindowDrawList();
            float x = p0.x + 4 + float(depth) * 14.0f;
            const float cy = p0.y + rowH * 0.5f;
            if (r.isGroup) {
                const bool closed = u.collapsed.count(r.ref) > 0;
                ImGui::SetCursorScreenPos(ImVec2(x, p0.y));
                if (ImGui::InvisibleButton("##open", ImVec2(14, rowH))) {
                    if (closed) u.collapsed.erase(r.ref);
                    else u.collapsed.insert(r.ref);
                }
                at_track("vec:layer:" + label_of(r) + ":open");
                const ImU32 col = IM_COL32(200, 200, 205, 255);
                if (!closed) dl->AddTriangleFilled(ImVec2(x + 2, cy - 3), ImVec2(x + 11, cy - 3), ImVec2(x + 6.5f, cy + 3), col);
                else dl->AddTriangleFilled(ImVec2(x + 3, cy - 5), ImVec2(x + 3, cy + 5), ImVec2(x + 9, cy), col);
            }
            x += 16;
            ImGui::SetCursorScreenPos(ImVec2(x, p0.y));
            const bool eyeClicked = ImGui::InvisibleButton("##vis", ImVec2(18, rowH));
            at_track("vec:layer:" + label_of(r) + ":visible");
            eye_icon(dl, ImVec2(x + 9, cy), !r.hidden, ImGui::IsItemHovered());
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("Show or hide (display=\"none\" in the SVG, so every renderer honours it).");
            if (eyeClicked && editable) vector_edited(m.set_hidden(r.ref, !r.hidden));
            x += 22;
            // a swatch of the fill (groups: a folder tab)
            if (r.isGroup) {
                dl->AddRectFilled(ImVec2(x, cy - 6), ImVec2(x + 18, cy + 6), IM_COL32(110, 160, 160, 255), 2.0f);
            } else {
                const ImU32 fillCol = colour_u32(r.fill, r.fill == "none" ? IM_COL32(60, 60, 66, 255) : IM_COL32(0, 0, 0, 255));
                dl->AddRectFilled(ImVec2(x, cy - 6), ImVec2(x + 18, cy + 6), fillCol, 2.0f);
                if (!r.stroke.empty() && r.stroke != "none") dl->AddRect(ImVec2(x, cy - 6), ImVec2(x + 18, cy + 6), colour_u32(r.stroke, IM_COL32(200, 200, 200, 255)), 2.0f, 0, 1.5f);
                else dl->AddRect(ImVec2(x, cy - 6), ImVec2(x + 18, cy + 6), IM_COL32(0, 0, 0, 120), 2.0f);
            }
            x += 24;
            const float lockX = p0.x + w - 24;
            if (u.renaming == r.ref) {
                ImGui::SetCursorScreenPos(ImVec2(x, p0.y + 2));
                ImGui::SetNextItemWidth(std::max(40.0f, lockX - x - 8));
                if (u.renameFocus) {
                    ImGui::SetKeyboardFocusHere();
                    u.renameFocus = false;
                }
                if (ImGui::InputText("##rename", &u.renameBuf, ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_AutoSelectAll)) {
                    if (!u.renameBuf.empty() && u.renameBuf != r.id) vector_edited(m.rename(r.ref, u.renameBuf));
                    u.renaming.clear();
                } else if (ImGui::IsItemDeactivated()) {
                    u.renaming.clear();
                }
                at_track("vec:layer:rename");
            } else {
                std::string label = label_of(r);
                if (r.isGroup) label += std::format("  ({})", r.children.size());
                if (!r.shapeKind.empty()) label += "  " + r.shapeKind;
                const ImU32 textCol = dim ? IM_COL32(130, 130, 138, 255) : (r.id.empty() ? IM_COL32(170, 170, 178, 255) : IM_COL32(230, 230, 235, 255));
                dl->PushClipRect(ImVec2(x, p0.y), ImVec2(lockX - 4, p0.y + rowH), true);
                dl->AddText(ImVec2(x, cy - ImGui::GetTextLineHeight() * 0.5f), textCol, label.c_str());
                dl->PopClipRect();
            }
            ImGui::SetCursorScreenPos(ImVec2(lockX, p0.y));
            const bool lockClicked = ImGui::InvisibleButton("##lock", ImVec2(20, rowH));
            at_track("vec:layer:" + label_of(r) + ":lock");
            lock_icon(dl, ImVec2(lockX + 10, cy), r.locked, ImGui::IsItemHovered());
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("Lock: the canvas does not pick or move it (data-locked in the SVG).");
            if (lockClicked && editable) vector_edited(m.set_locked(r.ref, !r.locked));
            ImGui::SetCursorScreenPos(ImVec2(p0.x, p0.y + rowH));
            ImGui::Dummy(ImVec2(0, 0));
            ImGui::PopID();
            if (r.isGroup && u.collapsed.count(r.ref) == 0) rows(r.index, depth + 1);
        }
    };
    rows(-1, 0);
    if (sc.items.empty()) ImGui::TextDisabled("The drawing is empty. Pick a tool and draw on the canvas.");
    ImGui::EndChild();
    if (!dropSrc.empty() && dropTarget >= 0) {
        const VecItem& t = sc.items[std::size_t(dropTarget)];
        std::vector<std::string> refs = m.is_selected(dropSrc) ? m.selection() : std::vector<std::string>{dropSrc};
        bool bad = false;
        for (const std::string& r : refs) {
            const int ri = sc.find(r);
            if (ri < 0 || t.index == ri || sc.is_descendant(t.index, ri)) bad = true;
        }
        if (!bad) {
            std::string parent, before;
            if (dropZone == 0) {
                parent = t.ref;
            } else {
                parent = t.parent >= 0 ? sc.items[std::size_t(t.parent)].ref : std::string();
                if (dropZone > 0) {
                    before = t.ref;   // below it in the list is behind it in the picture
                } else {
                    // above it in the list is in front of it: before the next sibling that does not move too
                    const std::vector<int> sibs = t.parent >= 0 ? sc.items[std::size_t(t.parent)].children : sc.roots();
                    bool after = false;
                    for (int s : sibs) {
                        if (after && std::find(refs.begin(), refs.end(), sc.items[std::size_t(s)].ref) == refs.end()) {
                            before = sc.items[std::size_t(s)].ref;
                            break;
                        }
                        if (s == t.index) after = true;
                    }
                }
            }
            vector_edited(m.regroup(refs, parent, before));
        }
    }
}

// -------------------------------------------------------------------------------------------------------------- inspector --
void Editor::draw_vector_inspector(VectorModel& m) {
    VectorUi& u = vector_;
    const bool editable = play_ == PlayState::Edit;
    const VecScene& sc = m.scene();
    const std::vector<int> sel = m.selected_items();
    if (sel.empty()) {
        ImGui::TextDisabled("Nothing selected");
        ImGui::Text("Canvas %.4g x %.4g", sc.canvas.width(), sc.canvas.height());
        if (sc.declaredWidth > 0 && (std::abs(sc.declaredWidth - sc.canvas.width()) > 1e-6 || std::abs(sc.declaredHeight - sc.canvas.height()) > 1e-6))
            ImGui::TextDisabled("declared size %.4g x %.4g", sc.declaredWidth, sc.declaredHeight);
        if (sc.unnamed > 0) {
            ImGui::TextDisabled("%d elements have no id.", sc.unnamed);
            ImGui::BeginDisabled(!editable);
            if (ImGui::Button("Give them ids")) vector_edited(m.edit("Name elements", "vector.assign_ids", Json::object()));
            at_track("vec:assign_ids");
            ImGui::EndDisabled();
            if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("vector.assign_ids: name every shape and group (path, path-2, g...) so scripts and commands can pick them by id.");
        }
        for (const std::string& w : sc.warnings) ImGui::TextWrapped("%s", w.c_str());
        return;
    }
    const VecItem& first = sc.items[std::size_t(sel[0])];
    ImGui::BeginDisabled(!editable);
    if (sel.size() == 1) ImGui::Text("%s  (%s)", label_of(first).c_str(), first.isGroup ? "group" : first.tag.c_str());
    else ImGui::Text("%zu elements", sel.size());
    if (!first.problem.empty()) ImGui::TextColored(ImVec4(1.0f, 0.55f, 0.45f, 1), "%s", first.problem.c_str());
    if (sel.size() == 1 && !first.isGroup) ImGui::TextDisabled("%d nodes%s%s", first.nodeCount, first.curves ? ", curves" : "", first.closed ? ", closed" : ", open");

    // position and size of the selection
    VecRect b;
    if (m.selection_bounds(b, false) && !m.previewing()) {
        double v[4] = {b.x0, b.y0, b.width(), b.height()};
        static const char* kNames[] = {"X", "Y", "W", "H"};
        for (int i = 0; i < 4; ++i) {
            if (i % 2 == 1) ImGui::SameLine();
            ImGui::SetNextItemWidth(ImGui::GetContentRegionAvail().x * (i % 2 == 0 ? 0.5f : 1.0f) - 28);
            double x = v[i];
            if (ImGui::InputDouble(kNames[i], &x, 0, 0, "%.2f", ImGuiInputTextFlags_EnterReturnsTrue)) {
                if (i == 0) vector_edited(m.move_selection(x - b.x0, 0));
                else if (i == 1) vector_edited(m.move_selection(0, x - b.y0));
                else if (x > 1e-6 && v[i] > 1e-9) {
                    const double f = x / v[i];
                    Json args = Json::object({{"scale", i == 2 ? Json::array({f, 1.0}) : Json::array({1.0, f})}, {"about", Json::array({b.x0, b.y0})}});
                    vector_edited(m.edit_selection("Resize", "vector.transform", args));
                }
            }
            at_track(std::string("vec:insp:") + kNames[i]);
        }
    }
    // rotate / flip
    if (ImGui::Button("Flip H")) vector_edited(m.edit_selection("Flip", "vector.transform", Json::object({{"flip", "horizontal"}})));
    at_track("vec:insp:flipH");
    ImGui::SameLine();
    if (ImGui::Button("Flip V")) vector_edited(m.edit_selection("Flip", "vector.transform", Json::object({{"flip", "vertical"}})));
    at_track("vec:insp:flipV");
    ImGui::SameLine();
    if (ImGui::Button("Rotate 90")) vector_edited(m.edit_selection("Rotate", "vector.transform", Json::object({{"rotate", 90}})));
    at_track("vec:insp:rot90");
    ImGui::Separator();

    const std::vector<std::string> refs = m.selection();
    // fill and stroke: a colour button with a popup picker (a live preview while it is open, ONE undo step when it closes), the palette
    // swatches that set an exact colour, and "none".
    auto paint_row = [&](const char* label, const char* prop, const std::string& value, float col[4], const char* popupId) {
        ImGui::PushID(prop);
        float shown[4] = {0.5f, 0.5f, 0.5f, 1};
        const bool isColour = colour_of(value, shown);
        const bool isNone = value == "none";
        if (!u.sliderDragging || u.shownFor != prop) {
            col[0] = shown[0];
            col[1] = shown[1];
            col[2] = shown[2];
            col[3] = 1;
        }
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted(label);
        ImGui::SameLine(64);
        if (ImGui::ColorButton("##c", isNone ? ImVec4(0, 0, 0, 0) : ImVec4(col[0], col[1], col[2], 1), ImGuiColorEditFlags_AlphaPreviewHalf, ImVec2(36, 20)))
            ImGui::OpenPopup(popupId);
        at_track(std::string("vec:insp:") + prop);
        ImGui::SameLine();
        bool none = isNone;
        if (ImGui::Checkbox("none", &none))
            vector_edited(m.set_style(Json::object({{prop, none ? "none" : (std::string(prop) == "fill" ? "#6d9eeb" : "#101018")}}), std::string("Change ") + prop));
        at_track(std::string("vec:insp:") + prop + ":none");
        ImGui::SameLine();
        ImGui::TextDisabled("%s", isColour ? value.c_str() : (value.empty() ? "(default)" : value.c_str()));
        if (ImGui::BeginPopup(popupId)) {
            if (ImGui::ColorPicker3("##picker", col, ImGuiColorEditFlags_NoSidePreview | ImGuiColorEditFlags_NoAlpha)) {
                u.sliderDragging = true;
                u.shownFor = prop;
                m.preview_edit("vector.set", Json::object({{"elements", refs_to_json(refs)}, {prop, hex_of(col)}}));
            }
            at_track(std::string("vec:insp:") + prop + ":picker");
            ImGui::EndPopup();
        } else if (u.sliderDragging && u.shownFor == prop) {
            u.sliderDragging = false;
            u.shownFor.clear();
            if (m.previewing()) vector_edited(m.commit_preview(std::string("Change ") + prop));
        }
        if (!m.palette().empty()) {
            int n = 0;
            for (const std::string& hex : m.palette()) {
                ImGui::PushID(hex.c_str());
                float c[4];
                colour_of(hex, c);
                if (ImGui::ColorButton("##p", ImVec4(c[0], c[1], c[2], 1), ImGuiColorEditFlags_NoTooltip, ImVec2(14, 14)))
                    vector_edited(m.set_style(Json::object({{prop, hex}}), std::string("Change ") + prop));
                at_track(std::string("vec:insp:") + prop + ":palette:" + hex);
                if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s: the exact colour of the project's palette", hex.c_str());
                ImGui::PopID();
                if (++n % 12 != 0) ImGui::SameLine(0, 2);
            }
            if (n % 12 != 0) ImGui::NewLine();
        }
        ImGui::PopID();
    };
    paint_row("Fill", "fill", first.fill, u.fillCol, "##vecfillpick");
    paint_row("Stroke", "stroke", first.stroke, u.strokeCol, "##vecstrokepick");

    auto slider = [&](const char* label, const char* prop, float value, float lo, float hi, const char* fmt, const char* tip) {
        float v = value;
        ImGui::SetNextItemWidth(-90);
        if (ImGui::SliderFloat(label, &v, lo, hi, fmt)) m.preview_edit("vector.set", Json::object({{"elements", refs_to_json(refs)}, {prop, v}}));
        at_track(std::string("vec:insp:") + prop);
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", tip);
        if (ImGui::IsItemDeactivatedAfterEdit()) vector_edited(m.commit_preview(std::string("Change ") + prop));
    };
    slider("Stroke width", "strokeWidth", float(first.strokeWidth), 0.0f, std::max(20.0f, float(first.strokeWidth) * 2), "%.2f", "In the element's own units.");
    slider("Opacity", "opacity", float(first.opacity), 0.0f, 1.0f, "%.2f", "The element's own opacity (a group's applies to everything in it).");
    {
        static const char* kRules[] = {"nonzero", "evenodd"};
        int rule = first.fillRule == "evenodd" ? 1 : 0;
        ImGui::SetNextItemWidth(-90);
        if (ImGui::Combo("Fill rule", &rule, kRules, 2)) vector_edited(m.set_style(Json::object({{"fillRule", kRules[rule]}}), "Change fill rule"));
        at_track("vec:insp:fillRule");
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("evenodd leaves holes where subpaths overlap; nonzero fills them.");
    }
    if (sel.size() == 1 && !first.shapeKind.empty()) {
        ImGui::Separator();
        draw_vector_shape_params(m, first);
    }
    ImGui::EndDisabled();
}

// The parameters of a shape vector.shape drew (data-fa-shape / data-fa-args): a live preview while a field is dragged, one undo step when let go.
void Editor::draw_vector_shape_params(VectorModel& m, const VecItem& item) {
    ImGui::Text("Shape: %s", item.shapeKind.c_str());
    const std::vector<ShapeParam>& params = shape_params(item.shapeKind);
    if (params.empty()) {
        ImGui::TextDisabled("This kind has no editable parameters.");
        return;
    }
    Json args = Json::object();
    if (!item.shapeArgs.empty()) {
        auto parsed = parse_json(item.shapeArgs, "data-fa-args");
        if (parsed.ok() && parsed->is_object()) args = *parsed;
    }
    for (const ShapeParam& p : params) {
        double v = args.contains(p.key) && args[p.key].is_number() ? args[p.key].get<double>() : p.def;
        ImGui::SetNextItemWidth(-100);
        bool changed = false;
        if (p.integer) {
            int iv = int(std::lround(v));
            changed = ImGui::SliderInt(p.label, &iv, int(p.lo), int(p.hi));
            v = iv;
        } else {
            float fv = float(v);
            const float hi = float(std::min(p.hi, std::max(p.def * 4, v * 2)));
            changed = ImGui::SliderFloat(p.label, &fv, float(p.lo), std::max(float(p.lo) + 0.001f, hi), "%.2f");
            v = fv;
        }
        at_track(std::string("vec:shape:") + p.key);
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", p.tip);
        if (changed) {
            Json next = args;
            next[p.key] = v;
            m.preview_shape_args(item.ref, item.shapeKind, next);
        }
        if (ImGui::IsItemDeactivatedAfterEdit() && m.previewing()) vector_edited(m.commit_preview("Change " + item.shapeKind));
    }
}

}  // namespace fa::editor
