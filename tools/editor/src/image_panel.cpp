// The Image panel (View > Image): a layered image document (*.image.json) as a canvas with brushes, selections and a transform (the
// canvas is in image_canvas.cpp), a layer list with an inspector, adjustments and effects with live previews, a palette bar for indexed
// layers and a frame strip. Everything it changes goes through image.* commands (image_model.cpp), so an AI can make the same edit,
// and each edit is ONE entry of the editor's undo stack.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <format>

#include "editor_internal.h"
#include "fa/core/strings.h"
#include "imgui_internal.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

constexpr float kToolsW = 106.0f;
constexpr float kSideW = 310.0f;
constexpr float kPaletteH = 46.0f;
constexpr float kFramesH = 76.0f;
const char* kLayerPayload = "FA_IMAGE_LAYER";

std::string lower_slug(const std::string& s) {
    std::string out;
    for (char c : s) out += c == ' ' ? '-' : char(std::tolower(static_cast<unsigned char>(c)));
    return out;
}

std::string hex_of(float r, float g, float b, float a) {
    auto q = [](float v) { return int(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
    char buf[16];
    if (q(a) == 255) std::snprintf(buf, sizeof buf, "#%02x%02x%02x", q(r), q(g), q(b));
    else std::snprintf(buf, sizeof buf, "#%02x%02x%02x%02x", q(r), q(g), q(b), q(a));
    return buf;
}

bool colour_from_json(const Json& j, const std::string& fallback, float out[4]) {
    Color c;
    const std::string text = j.is_string() ? j.get<std::string>() : fallback;
    if (!parse_color(text, c) && !parse_color(fallback, c)) c = Color{0, 0, 0, 1};
    out[0] = c.r;
    out[1] = c.g;
    out[2] = c.b;
    out[3] = c.a;
    return true;
}

std::vector<int> split_index_path(const std::string& p) {
    std::vector<int> v;
    std::size_t pos = 0;
    while (pos <= p.size() && !p.empty()) {
        std::size_t next = p.find('/', pos);
        if (next == std::string::npos) next = p.size();
        v.push_back(std::atoi(p.substr(pos, next - pos).c_str()));
        pos = next + 1;
    }
    return v;
}
std::string join_index_path(const std::vector<int>& v) {
    std::string s;
    for (std::size_t i = 0; i < v.size(); ++i) s += (i ? "/" : "") + std::to_string(v[i]);
    return s;
}

struct Badge {
    const char* text;
    ImU32 colour;
};
Badge badge_of(ImageLayerKind k) {
    switch (k) {
        case ImageLayerKind::Pixels: return {"PX", IM_COL32(70, 130, 200, 255)};
        case ImageLayerKind::Indexed: return {"IX", IM_COL32(120, 110, 200, 255)};
        case ImageLayerKind::Fill: return {"FL", IM_COL32(150, 150, 150, 255)};
        case ImageLayerKind::Gradient: return {"GR", IM_COL32(200, 130, 70, 255)};
        case ImageLayerKind::Procedural: return {"PR", IM_COL32(90, 170, 120, 255)};
        case ImageLayerKind::Svg: return {"SV", IM_COL32(200, 160, 60, 255)};
        case ImageLayerKind::Text: return {"T", IM_COL32(190, 190, 90, 255)};
        case ImageLayerKind::Provider: return {"AI", IM_COL32(190, 90, 160, 255)};
        case ImageLayerKind::Group: return {"GP", IM_COL32(110, 160, 160, 255)};
        case ImageLayerKind::Adjustment: return {"AD", IM_COL32(190, 100, 100, 255)};
    }
    return {"?", IM_COL32(120, 120, 120, 255)};
}

// A button that stays lit while `on`.
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

}  // namespace

// ----------------------------------------------------------------------------------------------------------- document --
ImageModel& Editor::image_ensure_model() {
    if (!image_.model) {
        image_.model = std::make_unique<ImageModel>(projectDir_, [this](const std::string& name, const Json& args) {
            CommandResult r = engine_->commands().call(name, args);
            after_command(name, args, r);   // the Project panel looks at the folder again when a file was written
            return r;
        });
    }
    return *image_.model;
}

bool Editor::open_image_document(const std::string& rel) {
    if (!engine_) return false;
    image_ensure_model();
    ImageUi& u = image_;
    u.drag = ImageUi::Drag::None;
    u.points.clear();
    u.polygonOpen = false;
    u.selectedOp = -1;
    u.renaming.clear();
    const bool ok = u.model->open(rel);
    u.openError = ok ? std::string() : u.model->error();
    u.playing = false;
    u.tiled = ok && u.model->tile_mode();   // a tile document opens with its repeat preview on
    u.fitNext = true;
    showImage_ = true;
    focus_window("Image");
    if (!ok) notify("Cannot open " + rel + " in the Image panel: " + u.model->error(), 2);
    else if (u.model->paintable(u.model->selected_layer()) == false) {
        // start on the top paintable layer: the first thing a person does is draw
        for (const ImageLayerRow& r : u.model->layer_rows())
            if (u.model->paintable(r.path)) {
                u.model->select_layer(r.path);
                break;
            }
    }
    return ok;
}

void Editor::image_close_document() {
    if (image_.model) image_.model->close();
    image_.drag = ImageUi::Drag::None;
    image_.points.clear();
    image_.polygonOpen = false;
}

void Editor::image_release_textures() {
    ImageUi& u = image_;
    for (ImageTexture* t : {&u.picture, &u.selectionTint, &u.terrain})
        if (t->image || t->view) ui::destroy_texture(t->image, t->view);
    for (const ImageUi::Dead& d : u.graveyard) ui::destroy_texture(d.image, d.view);
    u.picture = ImageTexture{};
    u.selectionTint = ImageTexture{};
    u.terrain = ImageTexture{};
    u.graveyard.clear();
}

void Editor::image_save() {
    ImageUi& u = image_;
    if (!u.model || !u.model->is_open()) return;
    if (play_ != PlayState::Edit) {
        notify("Stop the game before saving the image.", 1);
        return;
    }
    const ImageEditOutcome out = u.model->save();
    if (!out.ok) notify(out.error, 2);
    else project_files_changed();
}

// The undo entry of an edit, and what the rest of the editor must know about it.
void Editor::image_edited(const ImageEditOutcome& out) {
    ImageUi& u = image_;
    if (!out.ok) {
        notify(out.error, 1);
        return;
    }
    if (out.step <= 0 || !u.model) return;
    undo_.push_back(Json::object({{"$image", Json::object({{"step", out.step}})}}));
    if (undo_.size() > 100) undo_.erase(undo_.begin());
    redo_.clear();
    lastEditKey_.clear();
    image_collect_steps();
}

void Editor::image_collect_steps() {
    if (!image_.model) return;
    std::set<int> keep;
    for (const auto* stack : {&undo_, &redo_})
        for (const Json& e : *stack)
            if (e.is_object() && e.contains("$image") && e["$image"].is_object() && e["$image"].value("step", 0) > 0)
                keep.insert(e["$image"]["step"].get<int>());
    image_.model->retain_steps(keep);
}

void Editor::image_apply_undo(const Json& entry, bool forward) {
    ImageUi& u = image_;
    const int id = entry["$image"].value("step", 0);
    if (!u.model || !u.model->step(id)) {
        notify("That image edit is no longer remembered.", 1);
        return;
    }
    const std::string doc = u.model->step_document(id);
    if (!doc.empty() && doc != u.model->path()) open_image_document(doc);
    if (!u.model->apply_step(id, forward)) {
        notify("Could not " + std::string(forward ? "redo" : "undo") + " the image edit: " + u.model->error(), 2);
        return;
    }
    (forward ? undo_ : redo_).push_back(entry);
    project_files_changed();
}

// ---------------------------------------------------------------------------------------------------------- the panel --
void Editor::draw_image_panel() {
    ImageUi& u = image_;
    // A floating window the first time (a canvas needs room; the panel docks like any other when the user drags it in).
    first_floating_window(ImVec2(160, 70), ImVec2(1100, 720));
    if (!ImGui::Begin("Image", &showImage_)) {
        u.focused = false;
        ImGui::End();
        return;
    }
    u.focused = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows);
    // graveyard: textures replaced a few frames ago can go now
    for (std::size_t i = 0; i < u.graveyard.size();) {
        if (u.graveyard[i].frame + 4 < uiFrame_) {
            ui::destroy_texture(u.graveyard[i].image, u.graveyard[i].view);
            u.graveyard.erase(u.graveyard.begin() + long(i));
        } else {
            ++i;
        }
    }
    ImageModel& m = image_ensure_model();
    if (!m.is_open()) {
        draw_image_toolbar(m);
        ImGui::Spacing();
        ImGui::TextDisabled("Open an image document (*.image.json) from the list above, or double click one in the Project panel.");
        if (!u.openError.empty()) ImGui::TextColored(ImVec4(1.0f, 0.55f, 0.45f, 1), "%s", u.openError.c_str());
        ImGui::End();
        return;
    }
    // The files may have changed behind our back (the Console, an AI, another editor): look a few times a second.
    if (uiFrame_ - u.lastPoll >= 20 && u.drag == ImageUi::Drag::None) {
        u.lastPoll = uiFrame_;
        if (m.poll_external()) {
            u.selectedOp = -1;
            m.set_status("The document changed on disk and was read again.");
        }
    }
    draw_image_toolbar(m);
    if (!m.valid()) {
        ImGui::Spacing();
        ImGui::TextColored(ImVec4(1.0f, 0.55f, 0.45f, 1), "This document does not load:");
        ImGui::TextWrapped("%s", m.error().c_str());
        ImGui::TextDisabled("Fix it with the Console (image.layer.set, image.save) or an editor, then Reload.");
        ImGui::End();
        return;
    }
    if (play_ != PlayState::Edit) ImGui::TextColored(ImVec4(1.0f, 0.8f, 0.4f, 1), "The game is running: stop it to edit the image.");

    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const float sideW = std::min(kSideW, std::max(220.0f, avail.x * 0.34f));
    const float centerW = std::max(100.0f, avail.x - kToolsW - sideW - ImGui::GetStyle().ItemSpacing.x * 2);
    ImGui::BeginChild("##imgtools", ImVec2(kToolsW, avail.y), false);
    draw_image_tools(m);
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##imgcenter", ImVec2(centerW, avail.y), false, ImGuiWindowFlags_NoScrollbar);
    draw_image_options(m);
    {
        const bool indexed = !m.palette().empty();
        const bool frames = m.animated() || m.frame_count() > 1 || indexed;   // a pixel-art document can start an animation from here
        const float statusH = ImGui::GetTextLineHeightWithSpacing() + 6;
        const float paletteH = indexed ? kPaletteH : 0.0f;
        const float framesH = frames ? kFramesH : 0.0f;
        ImVec2 canvas = ImGui::GetContentRegionAvail();
        canvas.y = std::max(60.0f, canvas.y - statusH - paletteH - framesH - ImGui::GetStyle().ItemSpacing.y * (1 + (indexed ? 1 : 0) + (frames ? 1 : 0)));
        draw_image_canvas(m, canvas);
        if (indexed) draw_image_palette(m);
        if (frames) draw_image_frames(m);
        // status line
        std::string line = m.status();
        if (u.mouseImageX >= 0) line += (line.empty() ? "" : "   |   ") + std::format("x {} y {}", int(u.mouseImageX), int(u.mouseImageY));
        int sx, sy, sw, sh;
        if (m.selection_bounds(sx, sy, sw, sh)) line += std::format("   |   selection {}x{} at {},{}", sw, sh, sx, sy);
        line += std::format("   |   {}%   |   {:.1f} ms", int(std::lround(u.zoom * 100)), m.last_composite_ms());
        ImGui::TextDisabled("%s", line.c_str());
    }
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##imgside", ImVec2(sideW, avail.y), false);
    draw_image_side(m);
    ImGui::EndChild();
    ImGui::End();
}

// -------------------------------------------------------------------------------------------------------------- toolbar --
void Editor::draw_image_toolbar(ImageModel& m) {
    ImageUi& u = image_;
    const bool editable = play_ == PlayState::Edit;
    // The right edge of the last item of the one-line toolbar against the panel's right edge: the autotest checks that it fits.
    u.toolbarRight = 0;
    u.toolbarLimit = ImGui::GetWindowPos().x + ImGui::GetWindowWidth();
    const auto edge = [&u] { u.toolbarRight = std::max(u.toolbarRight, ImGui::GetItemRectMax().x); };
    // Open: the documents of the project
    std::vector<std::string> docs;
    for (const BrowserFile& f : projBrowser_.listing.files)
        if (ends_with(f.path, ".image.json")) docs.push_back(f.path);
    std::sort(docs.begin(), docs.end());
    const std::string current = m.is_open() ? m.path() : std::string();
    ImGui::SetNextItemWidth(260);
    if (ImGui::BeginCombo("##imgdoc", current.empty() ? "Open an image document..." : current.c_str())) {
        for (const std::string& d : docs) {
            if (ImGui::Selectable(d.c_str(), d == current)) open_image_document(d);
            at_track("img:doc:" + d);
        }
        if (docs.empty()) ImGui::TextDisabled("No *.image.json in the project yet. Use New.");
        ImGui::EndCombo();
    }
    at_track("img:open");
    edge();
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("The image documents (*.image.json) of the project. A double click in the Project panel opens one too.");
    ImGui::SameLine();
    if (ImGui::Button("New...")) ImGui::OpenPopup("##imgnew");
    at_track("img:new");
    edge();
    if (ImGui::BeginPopup("##imgnew")) {
        ImGui::TextUnformatted("New image document (image.create)");
        ImGui::SetNextItemWidth(220);
        ImGui::InputText("Name", &u.newDocName);
        ImGui::SetNextItemWidth(120);
        ImGui::InputInt("Size", &u.newDocSize);
        u.newDocSize = std::clamp(u.newDocSize, 1, 4096);
        ImGui::TextDisabled("assets/%s.image.json, %dx%d, a white background layer", u.newDocName.c_str(), u.newDocSize, u.newDocSize);
        if (ImGui::Button("Create") && editable && !u.newDocName.empty()) {
            const std::string path = "assets/" + u.newDocName + ".image.json";
            const CommandResult r = engine_->commands().call(
                "image.create", Json::object({{"path", path}, {"width", u.newDocSize}, {"height", u.newDocSize},
                                              {"layers", Json::array({Json::object({{"kind", "fill"}, {"name", "background"}, {"color", "#ffffff"}})})}}));
            after_command("image.create", Json::object(), r);
            if (r.ok) {
                open_image_document(path);
                ImGui::CloseCurrentPopup();
            } else {
                notify("image.create: " + command_error_text(r.error), 2);
            }
        }
        at_track("img:new:create");
        ImGui::EndPopup();
    }
    if (!m.is_open()) return;
    ImGui::SameLine();
    ImGui::BeginDisabled(!editable || !m.valid());
    if (ImGui::Button("Save")) image_save();
    at_track("img:save");
    edge();
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("Writes the document and bakes its PNG (image.save), like the command. Ctrl+S while this panel has the keyboard.");
    ImGui::SameLine();
    if (ImGui::Button("Reload")) {
        m.reload();
        u.selectedOp = -1;
    }
    at_track("img:reload");
    edge();
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Reads the document and its layer files again; the undo steps stay.");
    ImGui::SameLine();
    if (m.valid()) {
        const ImageBakeStatus b = m.bake_status();
        const bool fresh = b.state == ImageBakeState::Fresh;
        ImGui::TextColored(fresh ? ImVec4(0.55f, 0.85f, 0.55f, 1) : ImVec4(1.0f, 0.8f, 0.4f, 1), "%s",
                           fresh ? "baked" : "not baked");
        edge();
        // The badge stays short so the one-line toolbar fits a 1024 px window; the state and the reason are in its tooltip.
        if (ImGui::IsItemHovered() && !fresh)
            ImGui::SetTooltip("%s%s%s", image_bake_state_name(b.state), b.reason.empty() ? "" : ": ", b.reason.c_str());
        else if (ImGui::IsItemHovered() && !b.reason.empty())
            ImGui::SetTooltip("%s", b.reason.c_str());
        ImGui::SameLine();
        // The canvas size doubles as the Resize button (no room for a second button in the one-line toolbar at 1024 px).
        ImGui::BeginDisabled(!editable);
        if (ImGui::Button(std::format("{}x{}###imgsize", m.width(), m.height()).c_str())) {
            u.resizeWidth = m.width();
            u.resizeHeight = m.height();
            ImGui::OpenPopup("##imgresize");
        }
        at_track("img:resize", editable);
        edge();
        ImGui::EndDisabled();
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
            ImGui::SetTooltip("The canvas size. Click to change it (image.resize): every layer, frame and cel moves or is cropped by the anchor. Ctrl+Z undoes it.");
        if (ImGui::BeginPopup("##imgresize")) {
            static const char* const kAnchors[9] = {"top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"};
            ImGui::TextUnformatted("Resize canvas (image.resize)");
            ImGui::SetNextItemWidth(120);
            ImGui::InputInt("Width", &u.resizeWidth);
            ImGui::SetNextItemWidth(120);
            ImGui::InputInt("Height", &u.resizeHeight);
            u.resizeWidth = std::clamp(u.resizeWidth, 1, 4096);
            u.resizeHeight = std::clamp(u.resizeHeight, 1, 4096);
            ImGui::SetNextItemWidth(160);
            if (ImGui::BeginCombo("Anchor", kAnchors[u.resizeAnchor])) {
                for (int i = 0; i < 9; ++i)
                    if (ImGui::Selectable(kAnchors[i], i == u.resizeAnchor)) u.resizeAnchor = i;
                ImGui::EndCombo();
            }
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("The part of the old canvas that stays where it is.");
            const bool unchanged = u.resizeWidth == m.width() && u.resizeHeight == m.height();
            ImGui::BeginDisabled(unchanged);
            if (ImGui::Button("Resize")) {
                image_edited(m.resize_canvas(u.resizeWidth, u.resizeHeight, kAnchors[u.resizeAnchor], ""));
                ImGui::CloseCurrentPopup();
            }
            at_track("img:resize:apply", !unchanged);
            ImGui::EndDisabled();
            if (unchanged && ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Change the width or the height first: the canvas is already this size.");
            ImGui::EndPopup();
        }
    }
    // view
    ImGui::SameLine(0, 24);
    if (ImGui::Button("Fit")) u.fitNext = true;
    at_track("img:fit");
    edge();
    ImGui::SameLine();
    if (ImGui::Button("1:1")) {
        // 100% around the middle of the canvas
        const ImVec2 mid(u.canvasX + u.canvasW * 0.5f, u.canvasY + u.canvasH * 0.5f);
        const ImVec2 at = image_from_screen(mid);
        u.zoom = 1.0f;
        u.panX = (mid.x - u.canvasX) - at.x * u.zoom;
        u.panY = (mid.y - u.canvasY) - at.y * u.zoom;
        u.fitNext = false;
    }
    at_track("img:zoom100");
    edge();
    ImGui::SameLine();
    ImGui::SetNextItemWidth(60);
    int pct = int(std::lround(u.zoom * 100));
    if (ImGui::InputInt("##imgzoom", &pct, 0, 0, ImGuiInputTextFlags_EnterReturnsTrue)) {
        const ImVec2 mid(u.canvasX + u.canvasW * 0.5f, u.canvasY + u.canvasH * 0.5f);
        const ImVec2 at = image_from_screen(mid);
        u.zoom = std::clamp(float(pct) / 100.0f, 0.05f, 64.0f);
        u.panX = (mid.x - u.canvasX) - at.x * u.zoom;
        u.panY = (mid.y - u.canvasY) - at.y * u.zoom;
        u.fitNext = false;
    }
    edge();
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("Zoom in percent. The mouse wheel zooms around the pointer; the middle button, Space + drag, or Shift + wheel pans.\n"
                          "Above 100%% the pixels are drawn square (nearest neighbour); from 800%% a pixel grid shows.");
    ImGui::SameLine(0, 2);
    ImGui::TextDisabled("%%");
    edge();
    ImGui::SameLine();
    ImGui::Checkbox("Grid", &u.showGrid);
    at_track("img:grid");
    edge();
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("The pixel grid, drawn from 800%% zoom up. Every %d pixels a stronger line (the tile size in a tile document).", u.gridMajor);
    ImGui::SameLine();
    if (ImGui::Checkbox("Tiled", &u.tiled)) u.fitNext = true;
    at_track("img:tiled");
    edge();
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("Shows the picture repeated 3 x 3 so the seams show (a tile document opens with it on). Tools work on the middle copy.");
    ImGui::SameLine();
    ImGui::Checkbox("Checker", &u.checker);
    at_track("img:checker");
    edge();
}

// ------------------------------------------------------------------------------------------------------------------ tools --
void Editor::draw_image_tools(ImageModel& m) {
    ImageUi& u = image_;
    const bool editable = play_ == PlayState::Edit;
    ImGui::BeginDisabled(!editable);
    for (ImageTool t : image_tools()) {
        const char* name = image_tool_name(t);
        if (t == ImageTool::SelectRect) ImGui::Separator();
        if (toggle_button(name, u.tool == t, ImVec2(kToolsW - 8, 0))) {
            if (u.tool == ImageTool::Transform && t != ImageTool::Transform) m.cancel_transform();
            if (u.polygonOpen) u.points.clear(), u.polygonOpen = false;
            u.tool = t;
            if (t == ImageTool::Transform && !m.transforming()) m.begin_transform();
        }
        at_track("img:tool:" + lower_slug(name));
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) {
            const char* tip = "";
            switch (t) {
                case ImageTool::Move: tip = "Drag the selected pixels (a pixels layer), or the whole layer when nothing is selected. (V)"; break;
                case ImageTool::Brush: tip = "Paint with the colour. Alt+click picks a colour. Size [ and ], hardness and opacity in the bar above. On an indexed layer it paints palette colours exactly. (B)"; break;
                case ImageTool::Eraser: tip = "Erase to transparent. (E)"; break;
                case ImageTool::Fill: tip = "Fill the connected area of similar colour (tolerance in the bar above), inside the selection when there is one. (G)"; break;
                case ImageTool::Picker: tip = "Take the colour under the pointer. (I)"; break;
                case ImageTool::SelectRect: tip = "Drag a rectangle. Shift adds, Alt subtracts, Shift+Alt intersects. (M)"; break;
                case ImageTool::SelectEllipse: tip = "Drag an ellipse. Same modifiers as the rectangle. (Shift+M)"; break;
                case ImageTool::SelectLasso: tip = "Draw the outline freehand. (L)"; break;
                case ImageTool::SelectPolygon: tip = "Click the corners; double click, Enter or a click on the first point closes it. Esc cancels. (Shift+L)"; break;
                case ImageTool::Wand: tip = "Select the pixels of the picture under the pointer by colour, with a tolerance, connected or everywhere. (W)"; break;
                case ImageTool::Transform: tip = "Scale, rotate and flip the selected pixels (the whole layer without a selection). Drag the handles or type the numbers, then Apply. (T)"; break;
            }
            ImGui::SetTooltip("%s", tip);
        }
    }
    ImGui::EndDisabled();
}

void Editor::draw_image_options(ImageModel& m) {
    ImageUi& u = image_;
    const bool editable = play_ == PlayState::Edit;
    const bool indexed = !m.palette().empty() && m.layer(m.selected_layer()) && m.layer(m.selected_layer())->kind == ImageLayerKind::Indexed;
    const float h = ImGui::GetFrameHeightWithSpacing() * 3 + 6;
    ImGui::BeginChild("##imgopts", ImVec2(0, h), false, ImGuiWindowFlags_NoScrollbar);
    ImGui::BeginDisabled(!editable);
    ImGui::AlignTextToFramePadding();
    ImGui::TextUnformatted(image_tool_name(u.tool));
    ImGui::SameLine();
    auto brush_colour = [&] {
        float c[4] = {u.brush.color.r, u.brush.color.g, u.brush.color.b, u.brush.color.a};
        if (indexed) {
            ImGui::TextDisabled("palette colour %d", u.brush.paletteIndex);
            return;
        }
        if (ImGui::ColorEdit4("##imgcolor", c, ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_AlphaPreviewHalf))
            u.brush.color = Color{c[0], c[1], c[2], c[3]};
        at_track("img:color");
    };
    switch (u.tool) {
        case ImageTool::Brush:
        case ImageTool::Eraser: {
            brush_colour();
            ImGui::SameLine();
            float size = float(u.brush.size);
            ImGui::SetNextItemWidth(120);
            if (ImGui::SliderFloat("Size", &size, 1, 256, "%.0f", ImGuiSliderFlags_Logarithmic)) u.brush.size = size;
            at_track("img:brush:size");
            ImGui::BeginDisabled(indexed);
            ImGui::SameLine();
            float hardness = float(u.brush.hardness);
            ImGui::SetNextItemWidth(100);
            if (ImGui::SliderFloat("Hardness", &hardness, 0, 1, "%.2f")) u.brush.hardness = hardness;
            ImGui::SameLine();
            float opacity = float(u.brush.opacity);
            ImGui::SetNextItemWidth(100);
            if (ImGui::SliderFloat("Opacity", &opacity, 0, 1, "%.2f")) u.brush.opacity = opacity;
            ImGui::EndDisabled();
            if (indexed && ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                ImGui::SetTooltip("An indexed layer is painted with whole palette pixels: hardness and opacity do not apply.");
            break;
        }
        case ImageTool::Fill: {
            brush_colour();
            ImGui::SameLine();
            ImGui::SetNextItemWidth(140);
            ImGui::SliderInt("Tolerance", &u.wand.tolerance, 0, 255);
            break;
        }
        case ImageTool::Wand: {
            ImGui::SetNextItemWidth(140);
            ImGui::SliderInt("Tolerance", &u.wand.tolerance, 0, 255);
            ImGui::SameLine();
            ImGui::Checkbox("Contiguous", &u.wand.contiguous);
            break;
        }
        case ImageTool::Transform: {
            if (!m.transforming()) {
                if (ImGui::Button("Start transform")) m.begin_transform();
                at_track("img:tf:start");
                ImGui::SameLine();
                ImGui::TextDisabled("%s", m.has_selection() ? "of the selected pixels" : "of the whole layer");
                break;
            }
            ImageModel::TransformState t = m.transform();
            bool changed = false;
            float sx = float(t.scaleX), sy = float(t.scaleY), rot = float(t.rotate);
            ImGui::SetNextItemWidth(80);
            changed |= ImGui::DragFloat("##tfsx", &sx, 0.01f, 0.01f, 32.0f, "x %.2f");
            ImGui::SameLine();
            ImGui::SetNextItemWidth(80);
            changed |= ImGui::DragFloat("##tfsy", &sy, 0.01f, 0.01f, 32.0f, "y %.2f");
            ImGui::SameLine();
            ImGui::SetNextItemWidth(90);
            changed |= ImGui::DragFloat("##tfrot", &rot, 0.5f, -3600.0f, 3600.0f, "%.1f deg");
            ImGui::AlignTextToFramePadding();
            changed |= ImGui::Checkbox("Flip H", &t.flipH);
            ImGui::SameLine();
            changed |= ImGui::Checkbox("Flip V", &t.flipV);
            ImGui::SameLine();
            bool nearest = t.nearest;
            if (ImGui::Checkbox("Nearest", &nearest)) m.set_transform_nearest(nearest);
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("Nearest neighbour keeps hard pixel edges (pixel art); off blends smoothly. Indexed documents start with it on.");
            if (changed) m.set_transform(sx, sy, rot, t.flipH, t.flipV, t.dx, t.dy);
            ImGui::SameLine();
            if (ImGui::Button("Apply")) image_edited(m.apply_transform());
            at_track("img:tf:apply");
            ImGui::SameLine();
            if (ImGui::Button("Cancel")) m.cancel_transform();
            at_track("img:tf:cancel");
            break;
        }
        case ImageTool::Move:
            ImGui::TextDisabled("%s", m.has_selection() ? "Drag to move the selected pixels." : "Drag to move the whole layer (its x, y).");
            break;
        case ImageTool::Picker: ImGui::TextDisabled("Click or drag over the picture to take a colour."); break;
        default: break;
    }
    if (image_tool_selects(u.tool)) {
        static const char* kOps[] = {"Replace", "Add", "Subtract", "Intersect"};
        int op = int(u.selectOp);
        ImGui::SetNextItemWidth(100);
        if (ImGui::Combo("##imgselop", &op, kOps, 4)) u.selectOp = SelectOp(op);
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("How a new selection combines with the one there is. Hold Shift to add, Alt to subtract, Shift+Alt to intersect.");
        if (u.tool == ImageTool::Wand) {
            // the wand's own settings were drawn above
        }
    }
    // second row: the selection
    if (image_tool_selects(u.tool) || m.has_selection()) {
        if (ImGui::Button("All")) image_edited(m.select_all());
        at_track("img:sel:all");
        ImGui::SameLine();
        if (ImGui::Button("None")) image_edited(m.deselect());
        at_track("img:sel:none");
        ImGui::SameLine();
        if (ImGui::Button("Invert")) image_edited(m.selection_invert());
        at_track("img:sel:invert");
        ImGui::SameLine();
        ImGui::SetNextItemWidth(70);
        ImGui::DragFloat("##selpx", &u.selectionPx, 0.1f, 0.5f, 64.0f, "%.1f px");
        ImGui::SameLine();
        if (ImGui::Button("Grow")) image_edited(m.selection_grow(u.selectionPx));
        at_track("img:sel:grow");
        ImGui::SameLine();
        if (ImGui::Button("Shrink")) image_edited(m.selection_shrink(u.selectionPx));
        ImGui::SameLine();
        if (ImGui::Button("Feather")) image_edited(m.selection_feather(u.selectionPx));
        ImGui::SameLine();
        ImGui::Checkbox("Tint", &u.tint);
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("Show the selection as a blue tint (it shows when the outline would be too long to draw).");
    }
    ImGui::EndDisabled();
    ImGui::EndChild();
}

// ---------------------------------------------------------------------------------------------------- palette and frames --
namespace {
// Where palette colour `i` ends up when the colour at `from` moves to `to` (image.palette.move).
int moved_index(int i, int from, int to) {
    if (i == from) return to;
    if (from < to && i > from && i <= to) return i - 1;
    if (from > to && i >= to && i < from) return i + 1;
    return i;
}
}  // namespace

void Editor::draw_image_palette(ImageModel& m) {
    ImageUi& u = image_;
    const PixelPalette& pal = m.palette();
    const bool editable = play_ == PlayState::Edit && m.valid();
    auto colour_of = [&](int i) {
        const auto& rgb = pal.entries[std::size_t(i)].rgb;
        return Color{rgb[0] / 255.0f, rgb[1] / 255.0f, rgb[2] / 255.0f, 1.0f};
    };
    u.brush.paletteIndex = std::clamp(u.brush.paletteIndex, 0, std::max(0, pal.size() - 1));
    u.secondaryIndex = std::clamp(u.secondaryIndex, 0, std::max(0, pal.size() - 1));
    ImGui::BeginChild("##imgpalette", ImVec2(0, kPaletteH), false, ImGuiWindowFlags_HorizontalScrollbar);
    ImGui::AlignTextToFramePadding();
    ImGui::TextDisabled("Palette");
    for (int i = 0; i < pal.size(); ++i) {
        ImGui::SameLine();
        ImGui::PushID(i);
        const Color c = colour_of(i);
        const ImVec4 col(c.r, c.g, c.b, 1.0f);
        if (ImGui::ColorButton("##sw", col, ImGuiColorEditFlags_NoTooltip | ImGuiColorEditFlags_NoAlpha, ImVec2(22, 22))) {
            u.brush.paletteIndex = i;
            u.brush.color = c;
        }
        const bool right = ImGui::IsItemClicked(ImGuiMouseButton_Right);
        if (right) {
            u.secondaryIndex = i;
            u.secondaryColor = c;
        }
        ImDrawList* dl = ImGui::GetWindowDrawList();
        const ImVec2 a = ImGui::GetItemRectMin(), b = ImGui::GetItemRectMax();
        if (u.brush.paletteIndex == i) {
            dl->AddRect(a, b, IM_COL32(0, 0, 0, 255), 0, 0, 4.0f);
            dl->AddRect(a, b, IM_COL32(255, 255, 255, 255), 0, 0, 2.0f);
        }
        if (u.secondaryIndex == i) {
            dl->AddRect(ImVec2(a.x - 2, a.y - 2), ImVec2(b.x + 2, b.y + 2), IM_COL32(255, 170, 40, 255), 0, 0, 2.0f);
        }
        at_track("img:palette:" + std::to_string(i));
        if (ImGui::IsItemHovered())
            ImGui::SetTooltip("%d: %s\nClick: primary colour (left button, white frame). Right-click: secondary colour (right button, orange frame). X swaps them.",
                              i, pal.label(i).c_str());
        ImGui::PopID();
    }
    ImGui::SameLine(0, 16);
    ImGui::BeginDisabled(!editable);
    if (ImGui::SmallButton("+")) {
        ImGui::OpenPopup("##paladd");
        u.paletteName.clear();
    }
    at_track("img:palette:add");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Add a colour to the end of the palette (image.palette).");
    if (ImGui::BeginPopup("##paladd")) {
        ImGui::TextUnformatted("New palette colour");
        ImGui::SetNextItemWidth(110);
        ImGui::InputText("Colour", &u.paletteHex);
        ImGui::SetNextItemWidth(110);
        ImGui::InputText("Name", &u.paletteName);
        if (ImGui::Button("Add")) {
            const ImageEditOutcome out = m.add_palette_color(u.paletteHex, u.paletteName);
            image_edited(out);
            if (out.ok) {
                u.brush.paletteIndex = m.palette().size() - 1;
                u.brush.color = colour_of(u.brush.paletteIndex);
            }
            ImGui::CloseCurrentPopup();
        }
        at_track("img:palette:add:apply");
        ImGui::EndPopup();
    }
    ImGui::SameLine();
    const bool have = pal.size() > 0 && u.brush.paletteIndex < pal.size();
    ImGui::BeginDisabled(!have);
    if (ImGui::SmallButton("Edit")) ImGui::OpenPopup("##paledit");
    at_track("img:palette:edit");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("Change the primary colour of the palette (image.palette). Every pixel that uses it changes with it.");
    if (ImGui::BeginPopup("##paledit")) {
        static std::string hexBuf;
        if (ImGui::IsWindowAppearing() && have) hexBuf = pal.hex(u.brush.paletteIndex);
        ImGui::Text("Colour %d of the palette", u.brush.paletteIndex);
        ImGui::SetNextItemWidth(110);
        const bool enter = ImGui::InputText("##swhex", &hexBuf, ImGuiInputTextFlags_EnterReturnsTrue);
        ImGui::SameLine();
        if ((ImGui::Button("Apply") || enter) && have) {
            const int idx = u.brush.paletteIndex;
            image_edited(m.set_palette_color(idx, hexBuf));
            if (idx < m.palette().size()) u.brush.color = colour_of(idx);
            ImGui::CloseCurrentPopup();
        }
        at_track("img:palette:apply");
        ImGui::EndPopup();
    }
    ImGui::SameLine();
    if (ImGui::SmallButton("<") && u.brush.paletteIndex > 0) {
        const int from = u.brush.paletteIndex, to = from - 1;
        if (m.move_palette_color(from, to).ok) {
            u.brush.paletteIndex = to;
            u.secondaryIndex = moved_index(u.secondaryIndex, from, to);
        }
    }
    at_track("img:palette:left");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Move the primary colour one place left; its pixels follow it (image.palette.move).");
    ImGui::SameLine();
    if (ImGui::SmallButton(">") && u.brush.paletteIndex + 1 < pal.size()) {
        const int from = u.brush.paletteIndex, to = from + 1;
        if (m.move_palette_color(from, to).ok) {
            u.brush.paletteIndex = to;
            u.secondaryIndex = moved_index(u.secondaryIndex, from, to);
        }
    }
    at_track("img:palette:right");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Move the primary colour one place right; its pixels follow it (image.palette.move).");
    ImGui::SameLine();
    if (ImGui::SmallButton("Remove") && pal.size() > 1) {
        const int idx = u.brush.paletteIndex;
        const int repl = u.secondaryIndex != idx ? u.secondaryIndex : -1;
        ImageEditOutcome out = m.remove_palette_color(idx, repl);
        image_edited(out);
        if (out.ok) {
            u.secondaryIndex = u.secondaryIndex == idx ? 0 : (u.secondaryIndex > idx ? u.secondaryIndex - 1 : u.secondaryIndex);
            u.brush.paletteIndex = std::clamp(idx, 0, std::max(0, m.palette().size() - 1));
            u.brush.color = colour_of(u.brush.paletteIndex);
        }
    }
    at_track("img:palette:remove");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("Remove the primary colour from the palette (image.palette.remove). Pixels that use it take the secondary colour, or become transparent when both are the same.");
    ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::SmallButton("Swap")) {
        std::swap(u.brush.paletteIndex, u.secondaryIndex);
        std::swap(u.brush.color, u.secondaryColor);
    }
    at_track("img:palette:swap");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Swap the primary and secondary colours (X).");
    ImGui::EndDisabled();
    ImGui::EndChild();
}

void Editor::draw_image_frames(ImageModel& m) {
    ImageUi& u = image_;
    const bool editable = play_ == PlayState::Edit && m.valid();
    ImGui::BeginChild("##imgframes", ImVec2(0, kFramesH), false, ImGuiWindowFlags_HorizontalScrollbar);
    const int count = m.frame_count();
    // the preview plays the frames for their durations: it changes only the frame shown
    if (u.playing) {
        if (count < 2 || m.stroking() || m.moving() || m.transforming()) {
            u.playing = false;
        } else {
            u.playClock += double(ImGui::GetIO().DeltaTime) * 1000.0;
            for (int guard = 0; guard < count && u.playClock >= double(std::max(1, m.frame_duration(m.frame()))); ++guard) {
                u.playClock -= double(std::max(1, m.frame_duration(m.frame())));
                m.set_frame((m.frame() + 1) % count);
            }
        }
    }
    ImGui::AlignTextToFramePadding();
    ImGui::TextDisabled("Frames");
    ImGui::SameLine();
    ImGui::BeginDisabled(count < 2);
    if (ImGui::Button(u.playing ? "Stop" : "Play", ImVec2(44, 0))) {
        u.playing = !u.playing;
        u.playClock = 0;
    }
    at_track("img:frame:play");
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Plays the frames for their durations. A preview: it changes only the frame shown. A click on the canvas stops it.");
    for (int f = 0; f < count && (m.animated() || count > 1); ++f) {
        ImGui::SameLine();
        ImGui::PushID(f);
        char label[16];
        std::snprintf(label, sizeof label, "%d", f + 1);
        if (toggle_button(label, m.frame() == f, ImVec2(28, 0))) {
            m.set_frame(f);
            u.playing = false;
        }
        at_track("img:frame:" + std::to_string(f));
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("Frame %d, %d ms. The tools paint into this frame.", f + 1, m.frame_duration(f));
        ImGui::PopID();
    }
    ImGui::SameLine(0, 16);
    ImGui::BeginDisabled(!editable);
    if (ImGui::SmallButton("+ Add")) image_edited(m.add_frame(false));
    at_track("img:frame:add");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Insert an empty frame after this one (image.frame.add with blank). The first one makes the picture an animation.");
    ImGui::SameLine();
    if (ImGui::SmallButton("Duplicate")) image_edited(m.add_frame(true));
    at_track("img:frame:duplicate");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Insert a copy of this frame after it (image.frame.add with from).");
    ImGui::SameLine();
    ImGui::BeginDisabled(count < 2 || !m.animated());
    if (ImGui::SmallButton("Delete")) image_edited(m.remove_frame(m.frame()));
    at_track("img:frame:delete");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Delete this frame on every layer (image.frame.remove).");
    ImGui::SameLine();
    if (ImGui::SmallButton("<##fmove") && m.frame() > 0) image_edited(m.move_frame(m.frame(), m.frame() - 1));
    at_track("img:frame:left");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Move this frame one place earlier (image.frame.move).");
    ImGui::SameLine();
    if (ImGui::SmallButton(">##fmove") && m.frame() + 1 < count) image_edited(m.move_frame(m.frame(), m.frame() + 1));
    at_track("img:frame:right");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Move this frame one place later (image.frame.move).");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(84);
    int ms = m.frame_duration(m.frame());
    if (ImGui::InputInt("ms##fdur", &ms, 0, 0, ImGuiInputTextFlags_EnterReturnsTrue) && ms != m.frame_duration(m.frame()))
        image_edited(m.set_frame_duration(m.frame(), ms));
    at_track("img:frame:duration");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("How long this frame shows, in milliseconds (image.frame.set). Press Enter to apply.");
    ImGui::EndDisabled();
    ImGui::EndDisabled();

    // the onion skin
    bool onion = m.onion();
    if (ImGui::Checkbox("Onion skin", &onion)) m.set_onion(onion);
    at_track("img:onion");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Shows the frames before (red) and after (blue) faintly under the current one. A preview: the bake never has it.");
    ImageModel::OnionSettings o = m.onion_settings();
    bool changed = false;
    ImGui::BeginDisabled(!onion);
    ImGui::SameLine();
    ImGui::SetNextItemWidth(56);
    changed |= ImGui::DragInt("before##onion", &o.before, 0.1f, 0, 8);
    at_track("img:onion:before");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(56);
    changed |= ImGui::DragInt("after##onion", &o.after, 0.1f, 0, 8);
    at_track("img:onion:after");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(90);
    changed |= ImGui::SliderFloat("opacity##onion", &o.opacity, 0.05f, 1.0f, "%.2f");
    at_track("img:onion:opacity");
    ImGui::SameLine();
    changed |= ImGui::Checkbox("wrap##onion", &o.loop);
    at_track("img:onion:wrap");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("The frame before the first is the last one, and the other way round.");
    ImGui::EndDisabled();
    if (changed) m.set_onion_settings(o);
    ImGui::EndChild();
}

// -------------------------------------------------------------------------------------------------------- the side column --
void Editor::draw_image_side(ImageModel& m) {
    draw_image_layers(m);
    ImGui::Separator();
    draw_image_terrain(m);
    draw_image_layer_inspector(m);
}

void Editor::draw_image_layers(ImageModel& m) {
    ImageUi& u = image_;
    const bool editable = play_ == PlayState::Edit;
    ImGui::AlignTextToFramePadding();
    ImGui::TextUnformatted("Layers");
    ImGui::SameLine();
    ImGui::BeginDisabled(!editable);
    if (ImGui::SmallButton("+ Add")) ImGui::OpenPopup("##imgaddlayer");
    at_track("img:layer:add");
    if (ImGui::BeginPopup("##imgaddlayer")) {
        static const char* kKinds[] = {"pixels", "indexed", "fill", "gradient", "text", "group", "adjustment"};
        for (const char* k : kKinds) {
            if (ImGui::Selectable(k)) image_edited(m.add_layer(k));
            at_track(std::string("img:layer:add:") + k);
        }
        ImGui::Separator();
        ImGui::TextDisabled("procedural and svg layers:\nimage.layer.add in the Console");
        ImGui::EndPopup();
    }
    ImGui::SameLine();
    const bool have = m.layer(m.selected_layer()) != nullptr;
    ImGui::BeginDisabled(!have);
    if (ImGui::SmallButton("Duplicate")) image_edited(m.duplicate_layer(m.selected_layer()));
    at_track("img:layer:duplicate");
    ImGui::SameLine();
    if (ImGui::SmallButton("Remove")) image_edited(m.remove_layer(m.selected_layer()));
    at_track("img:layer:remove");
    ImGui::EndDisabled();
    ImGui::EndDisabled();
    draw_image_provider(m);

    ImGui::BeginChild("##imglist", ImVec2(0, std::max(120.0f, ImGui::GetContentRegionAvail().y * 0.4f)), true);
    const std::vector<ImageLayerRow> rows = m.layer_rows();
    constexpr float rowH = 24.0f;
    std::string dropSrc, dropDst;
    int dropZone = 0;   // -1 above the target, 0 into it, 1 below
    for (const ImageLayerRow& r : rows) {
        ImGui::PushID(r.path.c_str());
        const ImVec2 p0 = ImGui::GetCursorScreenPos();
        const float w = ImGui::GetContentRegionAvail().x;
        const bool sel = m.selected_layer() == r.path;
        if (ImGui::Selectable("##row", sel, ImGuiSelectableFlags_AllowDoubleClick | ImGuiSelectableFlags_AllowOverlap, ImVec2(w, rowH))) {
            m.select_layer(r.path);
            if (u.tool == ImageTool::Transform) m.cancel_transform();
        }
        at_track("img:layer:" + r.name);
        const bool rowHovered = ImGui::IsItemHovered();
        if (ImGui::IsItemHovered() && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left) && editable) {
            u.renaming = r.path;
            u.renameBuf = r.name;
            u.renameFocus = true;
        }
        // drag to reorder
        if (editable && ImGui::BeginDragDropSource(ImGuiDragDropFlags_None)) {
            ImGui::SetDragDropPayload(kLayerPayload, r.path.c_str(), r.path.size() + 1);
            ImGui::TextUnformatted(r.name.c_str());
            ImGui::EndDragDropSource();
        }
        if (editable && ImGui::BeginDragDropTarget()) {
            const ImGuiPayload* pl = ImGui::AcceptDragDropPayload(kLayerPayload, ImGuiDragDropFlags_AcceptBeforeDelivery | ImGuiDragDropFlags_AcceptNoDrawDefaultRect);
            if (pl) {
                const std::string src(static_cast<const char*>(pl->Data));
                const float t = (ImGui::GetMousePos().y - p0.y) / rowH;
                const int zone = t < 0.28f ? -1 : (t > 0.72f ? 1 : (r.isGroup ? 0 : (t < 0.5f ? -1 : 1)));
                const bool inside = r.path == src || r.path.rfind(src + "/", 0) == 0;
                ImDrawList* dl = ImGui::GetWindowDrawList();
                if (!inside) {
                    if (zone == 0) dl->AddRect(p0, ImVec2(p0.x + w, p0.y + rowH), IM_COL32(110, 170, 255, 255), 2.0f, 0, 2.0f);
                    else dl->AddLine(ImVec2(p0.x, zone < 0 ? p0.y : p0.y + rowH), ImVec2(p0.x + w, zone < 0 ? p0.y : p0.y + rowH), IM_COL32(110, 170, 255, 255), 2.0f);
                }
                if (pl->IsDelivery() && !inside) {
                    dropSrc = src;
                    dropDst = r.path;
                    dropZone = zone;
                }
            }
            ImGui::EndDragDropTarget();
        }
        // the row's parts, drawn over the selectable
        ImDrawList* dl = ImGui::GetWindowDrawList();
        float x = p0.x + 4 + float(r.depth) * 14.0f;
        const float cy = p0.y + rowH * 0.5f;
        if (r.isGroup) {
            ImGui::SetCursorScreenPos(ImVec2(x, p0.y));
            if (ImGui::InvisibleButton("##open", ImVec2(14, rowH))) m.set_open(r.path, !r.open);
            at_track("img:layer:" + r.name + ":open");
            const ImU32 col = IM_COL32(200, 200, 205, 255);
            if (r.open) dl->AddTriangleFilled(ImVec2(x + 2, cy - 3), ImVec2(x + 11, cy - 3), ImVec2(x + 6.5f, cy + 3), col);
            else dl->AddTriangleFilled(ImVec2(x + 3, cy - 5), ImVec2(x + 3, cy + 5), ImVec2(x + 9, cy), col);
        }
        x += 16;
        ImGui::SetCursorScreenPos(ImVec2(x, p0.y));
        const bool eyeClicked = ImGui::InvisibleButton("##vis", ImVec2(18, rowH));
        at_track("img:layer:" + r.name + ":visible");
        eye_icon(dl, ImVec2(x + 9, cy), r.visible, ImGui::IsItemHovered());
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("Show or hide the layer (a change of the document: it is undone with Ctrl+Z).");
        if (eyeClicked && editable) image_edited(m.set_layer(r.path, Json::object({{"visible", !r.visible}}), r.visible ? "Hide layer" : "Show layer"));
        x += 22;
        const Badge b = badge_of(r.kind);
        dl->AddRectFilled(ImVec2(x, cy - 8), ImVec2(x + 22, cy + 8), b.colour, 3.0f);
        const ImVec2 ts = ImGui::CalcTextSize(b.text);
        dl->AddText(ImVec2(x + 11 - ts.x * 0.5f, cy - ts.y * 0.5f), IM_COL32(255, 255, 255, 255), b.text);
        x += 28;
        const float lockX = p0.x + w - 24;
        if (u.renaming == r.path) {
            ImGui::SetCursorScreenPos(ImVec2(x, p0.y + 2));
            ImGui::SetNextItemWidth(std::max(40.0f, lockX - x - 8));
            if (u.renameFocus) {
                ImGui::SetKeyboardFocusHere();
                u.renameFocus = false;
            }
            if (ImGui::InputText("##rename", &u.renameBuf, ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_AutoSelectAll)) {
                if (!u.renameBuf.empty() && u.renameBuf != r.name) image_edited(m.rename_layer(r.path, u.renameBuf));
                u.renaming.clear();
            } else if (ImGui::IsItemDeactivated()) {
                u.renaming.clear();
            }
            at_track("img:layer:rename");
        } else {
            std::string label = r.name;
            if (r.opacity < 0.999f) label += std::format("  {}%", int(std::lround(r.opacity * 100)));
            if (r.blend != ImageBlend::Normal) label += std::string("  ") + image_blend_name(r.blend);
            if (r.clip) label += "  clip";
            const ImU32 textCol = r.visible ? IM_COL32(230, 230, 235, 255) : IM_COL32(130, 130, 138, 255);
            dl->PushClipRect(ImVec2(x, p0.y), ImVec2(lockX - 4, p0.y + rowH), true);
            dl->AddText(ImVec2(x, cy - ImGui::GetTextLineHeight() * 0.5f), textCol, label.c_str());
            dl->PopClipRect();
        }
        ImGui::SetCursorScreenPos(ImVec2(lockX, p0.y));
        const bool lockClicked = ImGui::InvisibleButton("##lock", ImVec2(20, rowH));
        at_track("img:layer:" + r.name + ":lock");
        lock_icon(dl, ImVec2(lockX + 10, cy), r.locked, ImGui::IsItemHovered());
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("Lock the layer: the tools do not paint on it or move it. (Kept for this session only; the document has no field for it.)");
        if (lockClicked) m.set_locked(r.path, !r.locked);
        (void)rowHovered;
        ImGui::SetCursorScreenPos(ImVec2(p0.x, p0.y + rowH));
        ImGui::Dummy(ImVec2(0, 0));
        ImGui::PopID();
    }
    ImGui::EndChild();
    if (!dropSrc.empty()) {
        std::vector<int> s = split_index_path(dropSrc), t = split_index_path(dropDst);
        std::vector<int> targetParent(t.begin(), t.end() - 1), srcParent(s.begin(), s.end() - 1);
        std::string parent;
        int index = 0;
        if (dropZone == 0) {   // into the group, on top
            parent = dropDst;
            const ImageLayerRow* row = nullptr;
            for (const ImageLayerRow& rr : rows)
                if (rr.path == dropDst) row = &rr;
            index = row ? row->childCount : 0;
            if (srcParent == t) index = std::max(0, index - 1);
        } else {
            parent = join_index_path(targetParent);
            int at = t.back();
            if (srcParent == targetParent && s.back() < at) --at;   // the layer leaves its place first
            index = dropZone < 0 ? at + 1 : at;
        }
        image_edited(m.move_layer(dropSrc, parent, index));
    }
}

// ------------------------------------------------------------------------------------------------------------ inspector --
void Editor::draw_image_layer_inspector(ImageModel& m) {
    ImageUi& u = image_;
    const bool editable = play_ == PlayState::Edit;
    const std::string path = m.selected_layer();
    const ImageLayer* lp = m.layer(path);
    if (!lp) {
        ImGui::TextDisabled("Select a layer to edit it.");
        return;
    }
    const ImageLayer& L = *lp;
    ImGui::BeginDisabled(!editable);
    ImGui::Text("%s  (%s)", L.name.empty() ? "(unnamed)" : L.name.c_str(), image_layer_kind_name(L.kind));
    bool visible = L.visible;
    if (ImGui::Checkbox("Visible", &visible)) image_edited(m.set_layer(path, Json::object({{"visible", visible}}), visible ? "Show layer" : "Hide layer"));
    ImGui::SameLine();
    bool clip = L.clip;
    if (ImGui::Checkbox("Clip to below", &clip)) image_edited(m.set_layer(path, Json::object({{"clip", clip}}), "Change clipping"));
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Draw this layer only where the layer below it is opaque.");

    // A slider that shows the change at once without touching the disk, and keeps it as ONE undo step when let go.
    auto layer_slider = [&](const char* id, const char* key, float value, float lo, float hi, const char* fmt) {
        float v = value;
        ImGui::SetNextItemWidth(-90);
        if (ImGui::SliderFloat(id, &v, lo, hi, fmt)) m.preview_layer(path, Json::object({{key, v}}));
        at_track(std::string("img:insp:") + key);
        if (ImGui::IsItemDeactivatedAfterEdit()) image_edited(m.commit_preview());
    };
    auto layer_int = [&](const char* id, const char* key, int value, int lo, int hi) {
        int v = value;
        ImGui::SetNextItemWidth(-90);
        if (ImGui::SliderInt(id, &v, lo, hi)) m.preview_layer(path, Json::object({{key, v}}));
        at_track(std::string("img:insp:") + key);
        if (ImGui::IsItemDeactivatedAfterEdit()) image_edited(m.commit_preview());
    };
    layer_slider("Opacity", "opacity", L.opacity, 0.0f, 1.0f, "%.2f");
    // blend
    {
        const std::vector<std::string> names = image_blend_names();
        const char* now = image_blend_name(L.blend);
        ImGui::SetNextItemWidth(-90);
        if (ImGui::BeginCombo("Blend", now)) {
            for (const std::string& n : names)
                if (ImGui::Selectable(n.c_str(), n == now)) image_edited(m.set_layer(path, Json::object({{"blend", n}}), "Change blend mode"));
            ImGui::EndCombo();
        }
        at_track("img:insp:blend");
    }
    layer_int("X", "x", L.x, -m.width(), m.width());
    layer_int("Y", "y", L.y, -m.height(), m.height());

    // kind-specific
    if (L.kind == ImageLayerKind::Fill || L.kind == ImageLayerKind::Text) {
        float c[4] = {L.color.r, L.color.g, L.color.b, L.color.a};
        ImGui::SetNextItemWidth(-90);
        if (ImGui::ColorEdit4("Colour", c, ImGuiColorEditFlags_AlphaPreviewHalf)) m.preview_layer(path, Json::object({{"color", hex_of(c[0], c[1], c[2], c[3])}}));
        at_track("img:insp:color");
        if (ImGui::IsItemDeactivatedAfterEdit()) image_edited(m.commit_preview());
    }
    if (L.kind == ImageLayerKind::Text) {
        std::string v = L.text;
        ImGui::SetNextItemWidth(-90);
        if (ImGui::InputText("Text", &v)) m.preview_layer(path, Json::object({{"text", v}}));
        at_track("img:insp:text");
        if (ImGui::IsItemDeactivatedAfterEdit()) image_edited(m.commit_preview("Change text"));
        layer_slider("Size", "size", L.size, 4.0f, 256.0f, "%.0f px");
    }
    if (L.kind == ImageLayerKind::Gradient) {
        float angle = L.gradient.angle;
        ImGui::SetNextItemWidth(-90);
        if (ImGui::SliderFloat("Angle", &angle, 0, 360, "%.0f deg")) m.preview_layer(path, Json::object({{"gradient", Json::object({{"angle", angle}})}}));
        if (ImGui::IsItemDeactivatedAfterEdit()) image_edited(m.commit_preview());
        ImGui::TextDisabled("%zu stops (edit them with image.layer.set)", L.gradient.stops.size());
    }
    if (L.kind == ImageLayerKind::Pixels || L.kind == ImageLayerKind::Indexed) {
        ImGui::TextDisabled("%s%s", L.source.empty() ? "" : L.source.c_str(), L.hasCels ? "  (has cels)" : "");
    }
    if (L.kind == ImageLayerKind::Svg) {
        ImGui::TextDisabled("%s", L.source.empty() ? "inline svg" : L.source.c_str());
        ImGui::BeginDisabled(!editable);
        if (ImGui::Button("Edit in Vector panel")) open_vector_layer(m.path(), path);
        at_track("img:insp:edit_vector");
        ImGui::EndDisabled();
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
            ImGui::SetTooltip("Open this layer's SVG in the Vector panel: pen, nodes, shapes, booleans and layers. Every edit is written to the layer; Save in either panel bakes the PNG.");
    }
    if (!L.masks.empty()) ImGui::TextDisabled("%zu mask(s) (edit them with image.layer.set)", L.masks.size());

    ImGui::Spacing();
    draw_image_operations(m, L, false);
    ImGui::Spacing();
    // An edit above reloaded the document and freed the layer `L` is a reference to: look the layer up again.
    if (const ImageLayer* again = m.layer(m.selected_layer())) draw_image_operations(m, *again, true);
    ImGui::EndDisabled();
    (void)u;
}

// Adjustments (colour operations) or effects (footprint operations) of the layer, each with the fields of its type. A slider drag shows
// the result live and is one undo step when let go.
void Editor::draw_image_operations(ImageModel& m, const ImageLayer& L, bool effect) {
    ImageUi& u = image_;
    const std::string path = m.selected_layer();
    // A COPY: add_operation, move_operation and the rest reload the document (ImageModel::load_from_disk), which frees the layers
    // `L` lives in, while this function goes on with the rest of the list in the same frame (found by the ASan run: heap-use-after-free).
    const std::vector<Json> list = effect ? L.effects : L.adjustments;
    const char* title = effect ? "Effects" : "Adjustments";
    ImGui::PushID(effect ? "effects" : "adjustments");
    ImGui::AlignTextToFramePadding();
    ImGui::TextUnformatted(title);
    ImGui::SameLine();
    if (ImGui::SmallButton("+ Add")) ImGui::OpenPopup("##addop");
    at_track(effect ? "img:effect:add" : "img:op:add");
    if (ImGui::BeginPopup("##addop")) {
        for (const ImageOpInfo& t : effect ? image_effect_types() : image_adjustment_types()) {
            if (ImGui::Selectable(t.name.c_str())) {
                image_edited(m.add_operation(path, effect, t.name));
                u.selectedOp = int(list.size());
                u.selectedOpEffect = effect;
            }
            at_track((effect ? "img:effect:add:" : "img:op:add:") + t.name);
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", t.description.c_str());
        }
        ImGui::EndPopup();
    }
    for (int i = 0; i < int(list.size()); ++i) {
        const Json& op = list[std::size_t(i)];
        const std::string type = op.is_object() && op.contains("type") && op["type"].is_string() ? op["type"].get<std::string>() : "?";
        ImGui::PushID(i);
        const bool open = u.selectedOp == i && u.selectedOpEffect == effect;
        const std::string pre = std::string("img:") + (effect ? "effect" : "op") + ":" + std::to_string(i);
        const float rowRight = ImGui::GetCursorScreenPos().x + ImGui::GetContentRegionAvail().x;
        ImGui::SetNextItemOpen(open, ImGuiCond_Always);
        const bool shown = ImGui::TreeNodeEx("##op", ImGuiTreeNodeFlags_SpanAvailWidth | ImGuiTreeNodeFlags_Framed | ImGuiTreeNodeFlags_AllowOverlap, "%s", type.c_str());
        at_track(pre);
        if (ImGui::IsItemToggledOpen()) {
            u.selectedOp = open ? -1 : i;
            u.selectedOpEffect = effect;
        }
        // reorder and remove, at the right end of the row
        const float rowY = ImGui::GetItemRectMin().y;
        ImGui::SameLine();
        ImGui::SetCursorScreenPos(ImVec2(rowRight - 74, rowY));
        const bool up = ImGui::SmallButton("^");
        at_track(pre + ":up");
        ImGui::SameLine();
        const bool down = ImGui::SmallButton("v");
        at_track(pre + ":down");
        ImGui::SameLine();
        const bool remove = ImGui::SmallButton("x");
        at_track(pre + ":remove");
        if (up && i > 0) image_edited(m.move_operation(path, effect, i, i - 1));
        if (down && i + 1 < int(list.size())) image_edited(m.move_operation(path, effect, i, i + 1));
        if (remove) {
            image_edited(m.remove_operation(path, effect, i));
            u.selectedOp = -1;
            if (shown) ImGui::TreePop();
            ImGui::PopID();
            break;
        }
        if (shown) {
            for (const ImageOpField& f : image_op_fields(type, effect)) {
                const Json* cur = op.is_object() && op.contains(f.key) ? &op[f.key] : nullptr;
                ImGui::PushID(f.key.c_str());
                const std::string trackName = std::string("img:field:") + f.key;
                auto preview = [&](const Json& value) { m.preview_operation(path, effect, i, Json::object({{f.key, value}})); };
                auto commit = [&] { image_edited(m.commit_operation_preview(std::string("Change ") + type)); };
                ImGui::SetNextItemWidth(-90);
                switch (f.kind) {
                    case ImageOpField::Kind::Number: {
                        float v = cur && cur->is_number() ? cur->get<float>() : float(f.def);
                        if (ImGui::SliderFloat(f.label.c_str(), &v, float(f.min), float(f.max), "%.3g")) preview(v);
                        at_track(trackName);
                        if (ImGui::IsItemDeactivatedAfterEdit()) commit();
                        break;
                    }
                    case ImageOpField::Kind::Int: {
                        int v = cur && cur->is_number() ? int(cur->get<double>()) : int(f.def);
                        if (ImGui::SliderInt(f.label.c_str(), &v, int(f.min), int(f.max))) preview(v);
                        at_track(trackName);
                        if (ImGui::IsItemDeactivatedAfterEdit()) commit();
                        break;
                    }
                    case ImageOpField::Kind::Bool: {
                        bool v = cur && cur->is_boolean() ? cur->get<bool>() : f.def != 0;
                        if (ImGui::Checkbox(f.label.c_str(), &v)) {
                            preview(v);
                            commit();
                        }
                        at_track(trackName);
                        break;
                    }
                    case ImageOpField::Kind::Choice: {
                        const std::string now = cur && cur->is_string() ? cur->get<std::string>() : f.defText;
                        if (ImGui::BeginCombo(f.label.c_str(), now.empty() ? "(default)" : now.c_str())) {
                            for (const std::string& o : f.options)
                                if (ImGui::Selectable(o.empty() ? "(default)" : o.c_str(), o == now)) {
                                    preview(o.empty() ? Json(nullptr) : Json(o));
                                    commit();
                                }
                            ImGui::EndCombo();
                        }
                        at_track(trackName);
                        break;
                    }
                    case ImageOpField::Kind::Color: {
                        float c[4];
                        colour_from_json(cur ? *cur : Json(), f.defText.empty() ? "#ffffff" : f.defText, c);
                        if (ImGui::ColorEdit4(f.label.c_str(), c, ImGuiColorEditFlags_AlphaPreviewHalf)) preview(hex_of(c[0], c[1], c[2], c[3]));
                        at_track(trackName);
                        if (ImGui::IsItemDeactivatedAfterEdit()) commit();
                        break;
                    }
                    case ImageOpField::Kind::Text: {
                        std::string v = cur && cur->is_string() ? cur->get<std::string>() : f.defText;
                        if (ImGui::InputText(f.label.c_str(), &v)) preview(v);
                        at_track(trackName);
                        if (ImGui::IsItemDeactivatedAfterEdit()) commit();
                        break;
                    }
                    case ImageOpField::Kind::Vec3: {
                        float v[3] = {float(f.def), float(f.def), float(f.def)};
                        if (cur && cur->is_array())
                            for (std::size_t k = 0; k < 3 && k < cur->size(); ++k)
                                if ((*cur)[k].is_number()) v[k] = (*cur)[k].get<float>();
                        if (ImGui::SliderFloat3(f.label.c_str(), v, float(f.min), float(f.max), "%.2f")) preview(Json::array({v[0], v[1], v[2]}));
                        at_track(trackName);
                        if (ImGui::IsItemDeactivatedAfterEdit()) commit();
                        break;
                    }
                    case ImageOpField::Kind::Curve:
                    case ImageOpField::Kind::Stops: {
                        // lists of points / colour stops: edited as JSON text, kept when the text is valid JSON of the same shape
                        std::string v = cur ? cur->dump() : std::string("[]");
                        if (ImGui::InputText(f.label.c_str(), &v)) {
                            Json parsed = Json::parse(v, nullptr, false);
                            if (!parsed.is_discarded() && parsed.is_array()) preview(parsed);
                        }
                        at_track(trackName);
                        if (ImGui::IsItemDeactivatedAfterEdit()) commit();
                        if (ImGui::IsItemHovered()) ImGui::SetTooltip("JSON list. Example: %s", f.kind == ImageOpField::Kind::Curve ? "[[0,0],[0.5,0.6],[1,1]]" : "[{\"at\":0,\"color\":\"#000000\"},{\"at\":1,\"color\":\"#ffffff\"}]");
                        break;
                    }
                }
                ImGui::PopID();
            }
            ImGui::TreePop();
        }
        ImGui::PopID();
    }
    if (list.empty()) ImGui::TextDisabled("None");
    ImGui::PopID();
}

}  // namespace fa::editor
