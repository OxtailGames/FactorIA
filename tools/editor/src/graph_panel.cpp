// The Graph panel (View > Graph): the node-graph editor of a material (*.material.json with a "graph", docs/SHADERS.md "Node graphs"). A canvas with
// pan and zoom, typed coloured ports and links dragged between them, a searchable palette of the node library, an inspector for the constants of
// the selected node, the checker's problems pinned on the node or link their JSON pointer names, and a live preview on a sphere, a cube or a quad.
// The rules are in graph_model.h (every edit is one undo step, the file is saved by material.graph.generate), the preview in graph_preview.h.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <format>
#include <set>
#include <string>

#include "editor_internal.h"
#include "fa/core/strings.h"
#include "imgui_internal.h"
#include "imgui_stdlib.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

const ImVec4 kBad(1.0f, 0.55f, 0.45f, 1);
const ImVec4 kWarn(1.0f, 0.8f, 0.4f, 1);
const ImVec4 kGood(0.55f, 0.85f, 0.55f, 1);

// The geometry of a node in graph units: its box and where its ports are.
constexpr float kNodeW = 176.0f, kHeaderH = 24.0f, kRowH = 22.0f, kPadH = 6.0f, kPortR = 5.0f;

void hint(const std::string& text) {
    if (text.empty() || !ImGui::BeginItemTooltip()) return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text.c_str());
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

// Buttons that wrap: the next one goes on the same line when it fits (a narrow window must not push a button out of reach).
struct FitRow {
    float right;
    FitRow() { right = ImGui::GetCursorScreenPos().x + ImGui::GetContentRegionAvail().x; }
    void next(const char* label) {
        const float w = ImGui::CalcTextSize(label, nullptr, true).x + ImGui::GetStyle().FramePadding.x * 2.0f;
        if (ImGui::GetItemRectMax().x + ImGui::GetStyle().ItemSpacing.x + w <= right) ImGui::SameLine();
    }
};

ImU32 port_color(const std::string& type, float alpha = 1.0f) {
    static const ImU32 c[] = {IM_COL32(190, 190, 190, 255), IM_COL32(110, 200, 120, 255), IM_COL32(235, 205, 80, 255),
                              IM_COL32(240, 135, 185, 255), IM_COL32(150, 155, 240, 255), IM_COL32(235, 125, 60, 255)};
    ImU32 col = c[std::clamp(graph_port_class(type), 0, 5)];
    if (alpha < 1.0f) col = (col & 0x00FFFFFF) | (ImU32(255.0f * alpha) << 24);
    return col;
}

ImU32 header_color(const std::string& category) {
    unsigned h = 2166136261u;
    for (char ch : category) h = (h ^ unsigned(static_cast<unsigned char>(ch))) * 16777619u;
    const float hue = float(h % 360u) / 360.0f;
    float r, g, b;
    ImGui::ColorConvertHSVtoRGB(hue, 0.45f, 0.42f, r, g, b);
    return IM_COL32(int(r * 255), int(g * 255), int(b * 255), 255);
}

std::string number_text(double v) {
    char buf[32];
    std::snprintf(buf, sizeof buf, "%.3g", v);
    return buf;
}

// A constant as the node shows it: 0.5, (1, 0, 0), uv.
std::string value_text(const Json& v) {
    if (v.is_number()) return number_text(v.get<double>());
    if (v.is_string()) {
        std::string s = v.get<std::string>();
        if (!s.empty() && s[0] == '$') s.erase(0, 1);
        return s;
    }
    if (v.is_array()) {
        std::string out = "(";
        for (std::size_t i = 0; i < v.size(); ++i) {
            if (i) out += ", ";
            out += v[i].is_number() ? number_text(v[i].get<double>()) : std::string("?");
        }
        return out + ")";
    }
    return {};
}

int port_components(const std::string& type, const Json& current) {
    if (current.is_array()) return std::clamp(int(current.size()), 1, 4);
    switch (graph_port_class(type)) {
        case 1: return 2;
        case 2: return 3;
        case 3: return 4;
        default: return 1;
    }
}

struct Box {
    std::string id;
    const GraphNodeType* type = nullptr;
    float x = 0, y = 0, w = kNodeW, h = 0;
    int rows = 0;
};

Box node_box(const GraphModel& m, int index) {
    Box b;
    b.id = m.node_id(index);
    b.type = m.node_type(b.id);
    const Vec2 p = m.node_pos(b.id);
    b.x = p.x;
    b.y = p.y;
    if (b.type) {
        b.rows = int(std::max(b.type->inputs.size(), b.type->outputs.size()));
        if (!b.type->ref.empty()) ++b.rows;
    } else {
        b.rows = 1;
    }
    b.h = kHeaderH + float(b.rows) * kRowH + kPadH;
    return b;
}

// The ports are in graph units too; the panel scales them.
Vec2 input_pos(const Box& b, int i) { return Vec2{b.x, b.y + kHeaderH + float(i) * kRowH + kRowH * 0.5f}; }
Vec2 output_pos(const Box& b, int i) { return Vec2{b.x + b.w, b.y + kHeaderH + float(i) * kRowH + kRowH * 0.5f}; }

std::pair<std::string, std::string> split_end(const std::string& s) {
    const auto dot = s.find('.');
    return dot == std::string::npos ? std::pair<std::string, std::string>{s, ""}
                                    : std::pair<std::string, std::string>{s.substr(0, dot), s.substr(dot + 1)};
}

const GraphPort* find_port(const std::vector<GraphPort>& ports, const std::string& name) {
    for (const GraphPort& p : ports)
        if (p.name == name) return &p;
    return nullptr;
}

// "/graph/nodes/3/inputs" -> 3 (nodes) or the index of a link; -1 when the pointer names neither.
int pointer_index(const std::string& pointer, const char* prefix) {
    const std::string pre = prefix;
    if (pointer.compare(0, pre.size(), pre) != 0) return -1;
    std::size_t i = pre.size();
    int v = 0;
    bool any = false;
    while (i < pointer.size() && pointer[i] >= '0' && pointer[i] <= '9' && v < 1000000) {
        v = v * 10 + (pointer[i] - '0');
        ++i;
        any = true;
    }
    return any ? v : -1;
}

float distance_to_bezier(ImVec2 p, ImVec2 a, ImVec2 b, ImVec2 c, ImVec2 d) {
    float best = 1e9f;
    ImVec2 prev = a;
    for (int i = 1; i <= 16; ++i) {
        const float t = float(i) / 16.0f;
        const ImVec2 q = ImBezierCubicCalc(a, b, c, d, t);
        const ImVec2 e = ImVec2(q.x - prev.x, q.y - prev.y);
        const float len2 = e.x * e.x + e.y * e.y;
        float s = len2 > 0 ? ((p.x - prev.x) * e.x + (p.y - prev.y) * e.y) / len2 : 0.0f;
        s = std::clamp(s, 0.0f, 1.0f);
        const float dx = p.x - (prev.x + e.x * s), dy = p.y - (prev.y + e.y * s);
        best = std::min(best, std::sqrt(dx * dx + dy * dy));
        prev = q;
    }
    return best;
}

bool put_texture(GraphUi::Texture& slot, std::vector<GraphUi::Dead>& graveyard, const Image& img, std::uint64_t frame) {
    GraphUi::Texture t;
    if (img.empty() || !ui::make_texture(img.width, img.height, img.rgba.data(), t.image, t.view)) return false;
    if (slot.image || slot.view) graveyard.push_back({slot.image, slot.view, frame});
    t.w = img.width;
    t.h = img.height;
    slot = t;
    return true;
}

}  // namespace

// ----------------------------------------------------------------------------------------------------------- document --
GraphModel& Editor::graph_ensure_model() {
    GraphUi& u = graph_;
    if (u.model && u.projectDir != projectDir_) {  // another project was opened
        graph_release_textures();
        u = GraphUi{};
    }
    if (!u.model) {
        u.projectDir = projectDir_;
        u.model = std::make_unique<GraphModel>(projectDir_, [this](const std::string& name, const Json& args) {
            CommandResult r = engine_->commands().call(name, args);
            if (!args.is_object() || !args.value("dryRun", false)) after_command(name, args, r);
            return r;
        });
    }
    if (!u.preview) u.preview = std::make_unique<GraphPreview>(projectDir_);
    return *u.model;
}

void Editor::graph_release_textures() {
    GraphUi& u = graph_;
    if (u.picture.image || u.picture.view) ui::destroy_texture(u.picture.image, u.picture.view);
    for (const GraphUi::Dead& d : u.graveyard) ui::destroy_texture(d.image, d.view);
    u.picture = GraphUi::Texture{};
    u.graveyard.clear();
}

bool Editor::open_graph_document(const std::string& rel, bool startGraph, bool discard) {
    if (!engine_) return false;
    GraphModel& m = graph_ensure_model();
    GraphUi& u = graph_;
    showGraph_ = true;
    focus_window("Graph");
    if (m.is_open() && m.path() == rel) return true;  // already open: its unsaved edits and undo steps stay
    if (!discard && m.is_open() && m.dirty()) {       // unsaved edits of another material: ask first
        u.askDiscard = true;
        u.pendingOpen = rel;
        u.pendingStart = startGraph;
        u.openError.clear();
        return false;
    }
    const bool ok = m.open(rel, startGraph);
    u.openError = ok ? std::string() : m.error();
    u.pendingOpen = ok ? std::string() : rel;  // the "Start a graph" button of a material that has none
    if (ok) {
        u.selectedLink = -1;
        u.drag = GraphUi::Drag::None;
        u.viewApplied = false;
        if (u.preview) u.preview->set_document(m.material_json(), m.revision());
    } else {
        // a failed open changes nothing: the document that was open stays, with its edits
        if (!m.is_open() && u.preview) u.preview->clear();
        notify("Cannot open " + rel + " in the Graph panel: " + m.error(), 1);
    }
    return ok;
}

void Editor::graph_close_document() {
    if (graph_.model) graph_.model->close();
    if (graph_.preview) graph_.preview->clear();
    graph_.openError.clear();
    graph_.pendingOpen.clear();
    graph_.selectedLink = -1;
    graph_.drag = GraphUi::Drag::None;
}

void Editor::graph_edited(const GraphEditOutcome& out) {
    if (!out.ok) {
        notify(out.error, 1);
        return;
    }
    if (out.step <= 0 || !graph_.model) return;
    undo_.push_back(Json::object({{"$graph", Json::object({{"step", out.step}})}}));
    redo_.clear();
    lastEditKey_.clear();
    graph_collect_steps();
}

void Editor::graph_collect_steps() {
    if (!graph_.model) return;
    std::set<int> keep;
    for (const auto* stack : {&undo_, &redo_})
        for (const Json& e : *stack)
            if (e.is_object() && e.contains("$graph") && e["$graph"].is_object() && e["$graph"].value("step", 0) > 0)
                keep.insert(e["$graph"]["step"].get<int>());
    graph_.model->retain_steps(keep);
}

void Editor::graph_apply_undo(const Json& entry, bool forward) {
    GraphUi& u = graph_;
    const int id = entry["$graph"].value("step", 0);
    if (!u.model || !u.model->step(id)) {
        notify("That graph edit is no longer remembered.", 1);
        return;
    }
    const std::string doc = u.model->step_document(id);
    if (!doc.empty() && doc != u.model->path()) open_graph_document(doc, false, true);
    if (!u.model->apply_step(id, forward)) {
        notify("Could not " + std::string(forward ? "redo" : "undo") + " the graph edit: " + u.model->status(), 2);
        return;
    }
    (forward ? undo_ : redo_).push_back(entry);
    u.selectedLink = -1;
    showGraph_ = true;
}

void Editor::graph_pre_frame() {
    GraphUi& u = graph_;
    if (!u.preview || !showGraph_ || !u.model || !u.model->is_open()) return;
    u.preview->tick(engine_ ? engine_->renderer() : nullptr);
}

Vec2 Editor::graph_screen_pos(float graphX, float graphY) const {
    const GraphUi& u = graph_;
    return Vec2{u.canvasX + u.panX + graphX * u.zoom, u.canvasY + u.panY + graphY * u.zoom};
}

Vec2 Editor::graph_node_screen(const std::string& id, const std::string& port, bool output) const {
    const GraphUi& u = graph_;
    if (!u.model) return Vec2{};
    const int index = u.model->node_index(id);
    if (index < 0) return Vec2{};
    const Box b = node_box(*u.model, index);
    if (port.empty()) return graph_screen_pos(b.x + b.w * 0.5f, b.y + kHeaderH * 0.5f);
    if (!b.type) return Vec2{};
    const auto& ports = output ? b.type->outputs : b.type->inputs;
    for (std::size_t i = 0; i < ports.size(); ++i)
        if (ports[i].name == port) {
            const Vec2 p = output ? output_pos(b, int(i)) : input_pos(b, int(i));
            return graph_screen_pos(p.x, p.y);
        }
    return Vec2{};
}

// ----------------------------------------------------------------------------------------------------------- panel --
void Editor::draw_graph_panel() {
    GraphUi& u = graph_;
    GraphModel& m = graph_ensure_model();
    for (std::size_t i = 0; i < u.graveyard.size();) {  // textures replaced a few frames ago can go now
        if (u.graveyard[i].frame + 4 < uiFrame_) {
            ui::destroy_texture(u.graveyard[i].image, u.graveyard[i].view);
            u.graveyard.erase(u.graveyard.begin() + long(i));
        } else {
            ++i;
        }
    }

    first_floating_window(ImVec2(140, 60), ImVec2(1060, 720));
    if (!ImGui::Begin("Graph", &showGraph_)) {
        u.focused = false;
        ImGui::End();
        return;
    }
    u.focused = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows);

    if (m.is_open() && !m.gesture_open() && uiFrame_ - u.lastPoll >= 20) {
        u.lastPoll = uiFrame_;
        if (m.poll_external() && !m.external_conflict()) m.set_status("The file changed on disk and was read again.");
    }
    draw_graph_toolbar(m);
    if (m.is_open() && m.external_conflict()) {
        ImGui::TextColored(kWarn, "The file changed outside the editor: Save would overwrite that change.");
        ImGui::SameLine();
        if (ImGui::Button("Reload##gconflict")) m.reload();
        at_track("gr:reload");
        hint("Takes the file as it is on disk; the edits not saved yet are lost.");
    }
    if (!u.openError.empty()) {  // the last open that failed, with or without a document open under it
        ImGui::TextColored(kBad, "%s", u.openError.c_str());
        if (!u.pendingOpen.empty() && ImGui::Button("Start a graph in this material")) {
            const std::string rel = u.pendingOpen;
            open_graph_document(rel, true, false);  // asks first when the open graph has unsaved edits
        }
        at_track("gr:start");
        hint("Starts an empty graph (the output node). The first Save writes the shader snippet from it: the "
             "material's own "
             "\"shader\" is replaced, after you confirm.");
        ImGui::SameLine();
        if (ImGui::SmallButton("Dismiss##gopenerr")) {
            u.openError.clear();
            u.pendingOpen.clear();
        }
    }
    if (!m.is_open()) {
        ImGui::Spacing();
        ImGui::TextDisabled(
            "Open a material with a graph from the list above, make one with New graph material, or double click a");
        ImGui::TextDisabled("*.material.json with a graph in the Project panel (docs/SHADERS.md, \"Node graphs\").");
        draw_graph_questions(m);
        ImGui::End();
        return;
    }

    u.preview->set_document(m.material_json(), m.revision());
    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const float rightW = std::clamp(avail.x * 0.36f, 210.0f, 320.0f);
    const float leftW = std::max(160.0f, avail.x - rightW - ImGui::GetStyle().ItemSpacing.x);
    ImGui::BeginChild("##gcanvasbox", ImVec2(leftW, avail.y), false,
                      ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);
    draw_graph_canvas(m);
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##gside", ImVec2(0, avail.y), false);
    draw_graph_side(m);
    ImGui::EndChild();
    draw_graph_questions(m);
    ImGui::End();
}

void Editor::graph_save(bool force) {
    GraphUi& u = graph_;
    if (!u.model || !u.model->is_open()) return;
    const GraphSaveOutcome out = u.model->save(force);
    if (out.needsForce) {
        u.askForce = true;
        return;
    }
    if (!out.ok) {
        notify("Cannot save the graph: " + out.error, 1);
        return;
    }
    project_files_changed();
    notify("Saved " + u.model->path() + (out.written ? "" : " (nothing changed)"), 0);
}

void Editor::draw_graph_toolbar(GraphModel& m) {
    GraphUi& u = graph_;
    ImGui::SetNextItemWidth(250);
    if (ImGui::BeginCombo("##gfile", m.is_open() ? m.title().c_str() : "Open a material...")) {
        // The list is made only while the combo is open (it lowercases every file name of the project).
        std::vector<std::string> files;
        for (const BrowserFile& f : projBrowser_.listing.files)
            if (ends_with(to_lower(f.path), ".material.json")) files.push_back(f.path);
        std::sort(files.begin(), files.end());
        for (const std::string& f : files) {
            if (ImGui::Selectable(f.c_str(), f == m.path())) open_graph_document(f);
            at_track("gr:file:" + f);
        }
        if (files.empty()) ImGui::TextDisabled("No materials in the project yet. New graph material makes one.");
        ImGui::EndCombo();
    }
    at_track("gr:open");
    hint("The materials (*.material.json) of the project. One without a graph offers to start one.");
    FitRow row;
    row.next("New graph material");
    if (ImGui::Button("New graph material")) {
        std::string rel;
        for (int i = 1; i < 1000; ++i) {
            rel = i == 1 ? "assets/materials/graph.material.json"
                         : std::format("assets/materials/graph{}.material.json", i);
            std::error_code ec;
            if (!std::filesystem::exists(std::filesystem::path(projectDir_) / rel, ec)) break;
        }
        if (m.is_open() && m.dirty()) {
            u.askDiscard = true;
            u.pendingOpen = rel;
            u.pendingStart = true;
            u.pendingCreate = true;
        } else {
            const GraphEditOutcome out = m.create(rel);
            if (!out.ok) {
                notify(out.error, 1);
            } else {
                project_files_changed();
                open_graph_document(rel, false, true);
            }
        }
    }
    at_track("gr:new");
    hint("material.graph.generate: writes assets/materials/graph.material.json with a graph of one output node, and "
         "opens it.");
    if (!m.is_open()) return;

    row.next("Add node");
    if (ImGui::Button("Add node")) {
        u.openPalette = true;
        u.menuAt = Vec2{(u.canvasW * 0.5f - u.panX) / u.zoom, (u.canvasH * 0.5f - u.panY) / u.zoom};
    }
    at_track("gr:add");
    hint("Search the node library. A right click on the canvas opens the same list at the mouse.");
    row.next("Save");
    ImGui::BeginDisabled(!m.dirty() && m.snippet_state() == "in_sync");
    if (ImGui::Button("Save")) graph_save(false);
    at_track("gr:save");
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("material.graph.generate: writes the graph into the material and the shader snippet from it. "
                          "Ctrl+S in the canvas.");
    row.next("Fit");
    if (ImGui::Button("Fit")) u.wantFit = true;
    at_track("gr:fit");
    hint("Shows the whole graph. F in the canvas.");

    ImGui::TextDisabled("%d nodes, %d links", m.node_count(), m.link_count());
    ImGui::SameLine();
    if (m.dirty()) {
        ImGui::TextColored(kWarn, "unsaved");
        ImGui::SameLine();
    }
    const std::string& st = m.snippet_state();
    if (st == "hand_edited" || st == "unmanaged") {
        ImGui::TextColored(kWarn, "snippet edited by hand");
        hint("The shader snippet was changed outside the graph (or was never written by it). Save asks before it "
             "overwrites it.");
    } else if (st == "in_sync") {
        ImGui::TextColored(kGood, "snippet in sync");
        hint("The shader snippet on disk is the one this graph generates.");
    } else if (st == "draft") {
        ImGui::TextDisabled("not saved yet");
    } else {
        ImGui::TextDisabled("snippet: %s", st.c_str());
    }
    if (!m.status().empty()) {
        ImGui::SameLine();
        ImGui::TextDisabled("%s", m.status().c_str());
    }
}

void Editor::draw_graph_questions(GraphModel& m) {
    GraphUi& u = graph_;
    if (u.askForce) {
        ImGui::OpenPopup("Overwrite the shader snippet?");
        u.askForce = false;
    }
    if (u.askDiscard) {
        ImGui::OpenPopup("Discard the graph changes?");
        u.askDiscard = false;
    }
    if (ImGui::BeginPopupModal("Overwrite the shader snippet?", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::PushTextWrapPos(ImGui::GetFontSize() * 30.0f);
        ImGui::TextUnformatted(
            "The shader snippet of this material was edited by hand, or was not written by a graph. Saving writes the "
            "snippet again from the graph and the hand edits are lost.");
        ImGui::PopTextWrapPos();
        if (ImGui::Button("Overwrite")) {
            graph_save(true);
            ImGui::CloseCurrentPopup();
        }
        at_track("gr:force");
        ImGui::SameLine();
        if (ImGui::Button("Cancel##force")) ImGui::CloseCurrentPopup();
        at_track("gr:force:cancel");
        ImGui::EndPopup();
    }
    if (ImGui::BeginPopupModal("Discard the graph changes?", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::PushTextWrapPos(ImGui::GetFontSize() * 30.0f);
        ImGui::Text("%s has changes that are not saved. Opening %s drops them.", m.title().c_str(),
                    u.pendingOpen.c_str());
        ImGui::PopTextWrapPos();
        if (ImGui::Button("Discard and open")) {
            const std::string rel = u.pendingOpen;
            const bool start = u.pendingStart, create = u.pendingCreate;
            u.pendingCreate = false;
            ImGui::CloseCurrentPopup();
            if (create) {
                const GraphEditOutcome out = m.create(rel);
                if (!out.ok) {
                    notify(out.error, 1);
                } else {
                    project_files_changed();
                    open_graph_document(rel, false, true);
                }
            } else {
                open_graph_document(rel, start, true);
            }
        }
        at_track("gr:discard");
        ImGui::SameLine();
        if (ImGui::Button("Keep editing")) {
            u.pendingCreate = false;
            ImGui::CloseCurrentPopup();
        }
        ImGui::EndPopup();
    }
}

// ---------------------------------------------------------------------------------------------------------- canvas --
void Editor::draw_graph_canvas(GraphModel& m) {
    GraphUi& u = graph_;
    ImGuiIO& io = ImGui::GetIO();
    const ImVec2 p0 = ImGui::GetCursorScreenPos();
    ImVec2 size = ImGui::GetContentRegionAvail();
    size.x = std::max(size.x, 100.0f);
    size.y = std::max(size.y, 100.0f);
    ImGui::InvisibleButton("##gcanvas", size,
                           ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight |
                               ImGuiButtonFlags_MouseButtonMiddle);
    at_track("gr:canvas");
    const bool hovered = ImGui::IsItemHovered();
    u.canvasX = p0.x;
    u.canvasY = p0.y;
    u.canvasW = size.x;
    u.canvasH = size.y;

    const int nodeCount = m.node_count();
    std::vector<Box> boxes;
    boxes.reserve(std::size_t(nodeCount));
    for (int i = 0; i < nodeCount; ++i) boxes.push_back(node_box(m, i));

    // ---- the view: what the file remembers, or the whole graph
    if (!u.viewApplied) {
        u.viewApplied = true;
        const GraphModel::View& v = m.saved_view();
        if (v.known) {
            u.zoom = std::clamp(v.zoom, 0.3f, 2.5f);
            u.panX = v.panX;
            u.panY = v.panY;
        } else {
            u.wantFit = true;
        }
    }
    if (u.wantFit) {
        u.wantFit = false;
        if (!boxes.empty()) {
            float x0 = 1e9f, y0 = 1e9f, x1 = -1e9f, y1 = -1e9f;
            for (const Box& b : boxes) {
                x0 = std::min(x0, b.x);
                y0 = std::min(y0, b.y);
                x1 = std::max(x1, b.x + b.w);
                y1 = std::max(y1, b.y + b.h);
            }
            const float w = std::max(1.0f, x1 - x0) + 60.0f, h = std::max(1.0f, y1 - y0) + 60.0f;
            u.zoom = std::clamp(std::min(size.x / w, size.y / h), 0.3f, 1.2f);
            u.panX = (size.x - (x1 - x0) * u.zoom) * 0.5f - x0 * u.zoom;
            u.panY = (size.y - (y1 - y0) * u.zoom) * 0.5f - y0 * u.zoom;
        } else {
            u.zoom = 1.0f;
            u.panX = u.panY = 40.0f;
        }
    }
    const float zoom = u.zoom;
    auto S = [&](float gx, float gy) { return ImVec2(p0.x + u.panX + gx * zoom, p0.y + u.panY + gy * zoom); };
    auto G = [&](ImVec2 s) { return Vec2{(s.x - p0.x - u.panX) / zoom, (s.y - p0.y - u.panY) / zoom}; };
    const ImVec2 mouse = io.MousePos;

    // ---- wheel zoom around the mouse
    if (hovered && io.MouseWheel != 0.0f && u.drag == GraphUi::Drag::None) {
        const Vec2 under = G(mouse);
        u.zoom = std::clamp(u.zoom * std::pow(1.1f, io.MouseWheel), 0.3f, 2.5f);
        u.panX = mouse.x - p0.x - under.x * u.zoom;
        u.panY = mouse.y - p0.y - under.y * u.zoom;
    }

    // ---- what is under the mouse
    struct Hit {
        enum Kind { None, Node, Port, Link } kind = None;
        int node = -1, link = -1, port = -1;
        bool output = false;
    } hit;
    {
        const float portReach = 9.0f * std::max(zoom, 0.8f);
        for (int i = int(boxes.size()) - 1; i >= 0 && hit.kind == Hit::None; --i) {
            const Box& b = boxes[std::size_t(i)];
            if (!b.type) continue;
            for (int k = 0; k < int(b.type->inputs.size()) && hit.kind == Hit::None; ++k) {
                const Vec2 p = input_pos(b, k);
                const ImVec2 sp = S(p.x, p.y);
                if (std::hypot(mouse.x - sp.x, mouse.y - sp.y) <= portReach) hit = {Hit::Port, i, -1, k, false};
            }
            for (int k = 0; k < int(b.type->outputs.size()) && hit.kind == Hit::None; ++k) {
                const Vec2 p = output_pos(b, k);
                const ImVec2 sp = S(p.x, p.y);
                if (std::hypot(mouse.x - sp.x, mouse.y - sp.y) <= portReach) hit = {Hit::Port, i, -1, k, true};
            }
        }
        for (int i = int(boxes.size()) - 1; i >= 0 && hit.kind == Hit::None; --i) {
            const Box& b = boxes[std::size_t(i)];
            const ImVec2 a = S(b.x, b.y), c = S(b.x + b.w, b.y + b.h);
            if (mouse.x >= a.x && mouse.x <= c.x && mouse.y >= a.y && mouse.y <= c.y)
                hit = {Hit::Node, i, -1, -1, false};
        }
    }
    // The links: where each starts and ends on the screen, and the one the mouse is on.
    struct LinkGeo {
        ImVec2 a, b, c, d;
        std::string type;
        bool ok = false;
    };
    std::vector<LinkGeo> links(std::size_t(std::max(0, m.link_count())));
    for (int i = 0; i < m.link_count(); ++i) {
        const Json& l = m.graph()["links"][std::size_t(i)];
        const auto from = split_end(l.value("from", std::string())), to = split_end(l.value("to", std::string()));
        const int fi = m.node_index(from.first), ti = m.node_index(to.first);
        if (fi < 0 || ti < 0) continue;
        const Box& fb = boxes[std::size_t(fi)];
        const Box& tb = boxes[std::size_t(ti)];
        if (!fb.type || !tb.type) continue;
        int fo = -1, tk = -1;
        for (int k = 0; k < int(fb.type->outputs.size()); ++k)
            if (fb.type->outputs[std::size_t(k)].name == from.second) fo = k;
        for (int k = 0; k < int(tb.type->inputs.size()); ++k)
            if (tb.type->inputs[std::size_t(k)].name == to.second) tk = k;
        if (fo < 0 || tk < 0) continue;
        const Vec2 pa = output_pos(fb, fo), pb = input_pos(tb, tk);
        LinkGeo& g = links[std::size_t(i)];
        g.a = S(pa.x, pa.y);
        g.d = S(pb.x, pb.y);
        const float dx = std::max(40.0f * zoom, std::abs(g.d.x - g.a.x) * 0.5f);
        g.b = ImVec2(g.a.x + dx, g.a.y);
        g.c = ImVec2(g.d.x - dx, g.d.y);
        g.type = fb.type->outputs[std::size_t(fo)].type;
        g.ok = true;
    }
    if (hit.kind == Hit::None && hovered) {
        float best = 7.0f;
        for (int i = 0; i < int(links.size()); ++i) {
            if (!links[std::size_t(i)].ok) continue;
            const LinkGeo& g = links[std::size_t(i)];
            const float d = distance_to_bezier(mouse, g.a, g.b, g.c, g.d);
            if (d < best) {
                best = d;
                hit = {Hit::Link, -1, i, -1, false};
            }
        }
    }

    // ---- the tooltip of what is under the mouse, right after the canvas
    if (hovered && u.drag == GraphUi::Drag::None && hit.kind != Hit::None) {
        std::string tip;
        if (hit.kind == Hit::Port) {
            const Box& b = boxes[std::size_t(hit.node)];
            const GraphPort& p =
                hit.output ? b.type->outputs[std::size_t(hit.port)] : b.type->inputs[std::size_t(hit.port)];
            tip = std::format("{}.{} ({}, {})\n{}", b.id, p.name, p.type, hit.output ? "output" : "input", p.doc);
            if (!hit.output && m.link_index_into(b.id, p.name) >= 0)
                tip += "\nDrag from here to move the link; drop it on empty canvas to cut it.";
        } else if (hit.kind == Hit::Node) {
            const Box& b = boxes[std::size_t(hit.node)];
            tip = (b.type ? b.type->type + "\n" + b.type->doc : b.id);
            for (const GraphIssue& is : m.node_issues(b.id))
                tip += std::string("\n") + (is.warning ? "Warning: " : "Error: ") + is.issue.message +
                       (is.issue.hint.empty() ? std::string() : " " + is.issue.hint);
        } else if (hit.kind == Hit::Link) {
            tip = "A link. Click to select it, Delete cuts it.";
            for (const GraphIssue& is : m.link_issues(hit.link))
                tip += std::string("\n") + (is.warning ? "Warning: " : "Error: ") + is.issue.message +
                       (is.issue.hint.empty() ? std::string() : " " + is.issue.hint);
        }
        hint(tip);
    }

    // ---- mouse
    const bool popupOpen = ImGui::IsPopupOpen("", ImGuiPopupFlags_AnyPopupId | ImGuiPopupFlags_AnyPopupLevel);
    auto outcome = [&](const GraphEditOutcome& o) { graph_edited(o); };
    if (hovered && !popupOpen && u.drag == GraphUi::Drag::None) {
        if (ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
            u.dragStart = Vec2{mouse.x, mouse.y};
            u.linkMessage.clear();
            if (hit.kind == Hit::Port) {
                const Box& b = boxes[std::size_t(hit.node)];
                u.selectedLink = -1;
                if (hit.output) {
                    u.linkFrom = {b.id, b.type->outputs[std::size_t(hit.port)].name, true};
                    u.linkPicked = GraphPortId{};
                    u.drag = GraphUi::Drag::Link;
                } else {
                    const std::string name = b.type->inputs[std::size_t(hit.port)].name;
                    const GraphPortId src = m.link_source(b.id, name);
                    if (src.valid()) {  // pick the link up: the end that stays is its output
                        u.linkFrom = {src.node, src.port, true};
                        u.linkPicked = {b.id, name, false};
                    } else {
                        u.linkFrom = {b.id, name, false};
                        u.linkPicked = GraphPortId{};
                    }
                    u.drag = GraphUi::Drag::Link;
                }
                m.begin_gesture();
            } else if (hit.kind == Hit::Node) {
                const std::string& id = boxes[std::size_t(hit.node)].id;
                u.selectedLink = -1;
                if (io.KeyShift || io.KeyCtrl || io.KeySuper) {
                    if (m.is_selected(id))
                        m.deselect(id);
                    else
                        m.select(id, true);
                } else if (!m.is_selected(id)) {
                    m.select(id);
                }
                if (m.is_selected(id)) {
                    u.drag = GraphUi::Drag::Nodes;
                    u.dragApplied = Vec2{0, 0};
                    m.begin_gesture();
                }
            } else if (hit.kind == Hit::Link) {
                u.selectedLink = hit.link;
                m.clear_selection();
            } else {
                u.selectedLink = -1;
                if (!(io.KeyShift || io.KeyCtrl || io.KeySuper)) m.clear_selection();
                u.drag = GraphUi::Drag::Box;
            }
        } else if (ImGui::IsMouseClicked(ImGuiMouseButton_Middle)) {
            u.drag = GraphUi::Drag::Pan;
        } else if (ImGui::IsMouseClicked(ImGuiMouseButton_Right)) {
            u.rightPanCandidate = true;
            u.dragStart = Vec2{mouse.x, mouse.y};
        }
    }
    if (u.rightPanCandidate && u.drag == GraphUi::Drag::None) {
        if (!ImGui::IsMouseDown(ImGuiMouseButton_Right)) {  // a click without a drag: the palette, at the mouse
            u.rightPanCandidate = false;
            if (hovered && !popupOpen) {
                u.openPalette = true;
                u.menuAt = G(mouse);
                if (hit.kind == Hit::Node && !m.is_selected(boxes[std::size_t(hit.node)].id))
                    m.select(boxes[std::size_t(hit.node)].id);
            }
        } else if (std::hypot(mouse.x - u.dragStart.x, mouse.y - u.dragStart.y) > 4.0f) {
            u.rightPanCandidate = false;
            u.drag = GraphUi::Drag::Pan;
        }
    }

    // ---- the drag in progress
    switch (u.drag) {
        case GraphUi::Drag::Pan:
            u.panX += io.MouseDelta.x;
            u.panY += io.MouseDelta.y;
            if (!ImGui::IsMouseDown(ImGuiMouseButton_Right) && !ImGui::IsMouseDown(ImGuiMouseButton_Middle))
                u.drag = GraphUi::Drag::None;
            break;
        case GraphUi::Drag::Nodes: {
            const float tx = std::round((mouse.x - u.dragStart.x) / zoom),
                        ty = std::round((mouse.y - u.dragStart.y) / zoom);
            if (tx != u.dragApplied.x || ty != u.dragApplied.y) {
                m.move_nodes(m.selection(), tx - u.dragApplied.x, ty - u.dragApplied.y);
                u.dragApplied = Vec2{tx, ty};
            }
            if (!ImGui::IsMouseDown(ImGuiMouseButton_Left)) {
                u.drag = GraphUi::Drag::None;
                outcome(m.end_gesture(m.selection().size() > 1 ? "Move nodes" : "Move node"));
            }
            break;
        }
        case GraphUi::Drag::Box:
            if (!ImGui::IsMouseDown(ImGuiMouseButton_Left)) {
                u.drag = GraphUi::Drag::None;
                const float x0 = std::min(u.dragStart.x, mouse.x), x1 = std::max(u.dragStart.x, mouse.x);
                const float y0 = std::min(u.dragStart.y, mouse.y), y1 = std::max(u.dragStart.y, mouse.y);
                std::set<std::string> ids =
                    (io.KeyShift || io.KeyCtrl || io.KeySuper) ? m.selection() : std::set<std::string>();
                for (const Box& b : boxes) {
                    const ImVec2 a = S(b.x, b.y), c = S(b.x + b.w, b.y + b.h);
                    if (c.x >= x0 && a.x <= x1 && c.y >= y0 && a.y <= y1) ids.insert(b.id);
                }
                m.select_only(ids);
            }
            break;
        case GraphUi::Drag::Link:
            if (!ImGui::IsMouseDown(ImGuiMouseButton_Left)) {
                u.drag = GraphUi::Drag::None;
                const bool fromOutput = u.linkFrom.output;
                // the port the link was dropped on, of the kind that can take it
                std::string target;
                if (hit.kind == Hit::Port && hit.output != fromOutput) {
                    const Box& b = boxes[std::size_t(hit.node)];
                    target = b.id + "." +
                             (hit.output ? b.type->outputs[std::size_t(hit.port)].name
                                         : b.type->inputs[std::size_t(hit.port)].name);
                }
                const std::string fromEnd = u.linkFrom.node + "." + u.linkFrom.port;
                GraphEditOutcome o;
                if (!target.empty()) {
                    o = fromOutput ? m.connect(fromEnd, target) : m.connect(target, fromEnd);
                    if (!o.ok) u.linkMessage = o.error;
                    if (o.ok && u.linkPicked.valid() &&
                        (u.linkPicked.node + "." + u.linkPicked.port) != (fromOutput ? target : fromEnd))
                        m.disconnect(u.linkPicked.node + "." + u.linkPicked.port);
                } else if (u.linkPicked.valid()) {  // dropped on empty canvas: the link that was picked up is cut
                    o = m.disconnect(u.linkPicked.node + "." + u.linkPicked.port);
                }
                const GraphEditOutcome step = m.end_gesture(u.linkPicked.valid() ? "Move link" : "Connect");
                if (!o.ok) {
                    notify(o.error, 1);
                } else {
                    outcome(step);
                }
            }
            break;
        case GraphUi::Drag::None: break;
    }

    // ---- keys
    if (u.focused && hovered && !io.WantTextInput && u.drag == GraphUi::Drag::None && !popupOpen) {
        const bool cmd = io.KeyCtrl || io.KeySuper;
        if (ImGui::IsKeyPressed(ImGuiKey_Delete, false) || ImGui::IsKeyPressed(ImGuiKey_Backspace, false)) {
            if (u.selectedLink >= 0) {
                outcome(m.remove_link(u.selectedLink));
                u.selectedLink = -1;
            } else if (!m.selection().empty()) {
                outcome(m.remove_nodes(m.selection()));
            }
        }
        if (cmd && ImGui::IsKeyPressed(ImGuiKey_A, false)) m.select_all();
        if (cmd && ImGui::IsKeyPressed(ImGuiKey_C, false) && !m.selection().empty()) {
            u.clipboard = m.copy(m.selection());
            ImGui::SetClipboardText(u.clipboard.c_str());
        }
        if (cmd && ImGui::IsKeyPressed(ImGuiKey_X, false) && !m.selection().empty()) {
            std::string clip;
            outcome(m.cut(m.selection(), &clip));
            if (!clip.empty()) {
                u.clipboard = clip;
                ImGui::SetClipboardText(clip.c_str());
            }
        }
        if (cmd && ImGui::IsKeyPressed(ImGuiKey_V, false)) {
            const char* sys = ImGui::GetClipboardText();
            const std::string text = sys && *sys && std::string(sys).find("factoria.graph.clip") != std::string::npos
                                         ? std::string(sys)
                                         : u.clipboard;
            if (!text.empty()) outcome(m.paste(text, G(mouse)));
        }
        if (cmd && ImGui::IsKeyPressed(ImGuiKey_D, false) && !m.selection().empty())
            outcome(m.duplicate(m.selection()));
        if (cmd && ImGui::IsKeyPressed(ImGuiKey_S, false)) graph_save(false);
        if (!cmd && ImGui::IsKeyPressed(ImGuiKey_F, false)) u.wantFit = true;
    }

    // ---- draw
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImVec2 p1(p0.x + size.x, p0.y + size.y);
    dl->PushClipRect(p0, p1, true);
    dl->AddRectFilled(p0, p1, IM_COL32(28, 29, 33, 255));
    for (const auto& [step, col] : {std::pair<float, ImU32>{32.0f, IM_COL32(255, 255, 255, 14)},
                                    std::pair<float, ImU32>{160.0f, IM_COL32(255, 255, 255, 30)}}) {
        const float px = step * zoom;
        if (px < 9.0f) continue;
        float x = std::fmod(u.panX, px);
        if (x < 0) x += px;
        for (; x < size.x; x += px) dl->AddLine(ImVec2(p0.x + x, p0.y), ImVec2(p0.x + x, p1.y), col);
        float y = std::fmod(u.panY, px);
        if (y < 0) y += px;
        for (; y < size.y; y += px) dl->AddLine(ImVec2(p0.x, p0.y + y), ImVec2(p1.x, p0.y + y), col);
    }
    for (int i = 0; i < int(links.size()); ++i) {
        const LinkGeo& g = links[std::size_t(i)];
        if (!g.ok) continue;
        const std::vector<GraphIssue> issues = m.link_issues(i);
        const bool bad = std::any_of(issues.begin(), issues.end(), [](const GraphIssue& is) { return !is.warning; });
        ImU32 col = bad ? IM_COL32(235, 80, 70, 255) : port_color(g.type, 0.85f);
        float thick = (bad ? 3.0f : 2.0f) * std::max(zoom, 0.7f);
        if (i == u.selectedLink) {
            col = IM_COL32(255, 255, 255, 255);
            thick += 1.5f;
        } else if (hit.kind == Hit::Link && hit.link == i) {
            thick += 1.0f;
        }
        dl->AddBezierCubic(g.a, g.b, g.c, g.d, col, thick);
    }
    // the link being dragged
    if (u.drag == GraphUi::Drag::Link) {
        const int fi = m.node_index(u.linkFrom.node);
        if (fi >= 0 && boxes[std::size_t(fi)].type) {
            const Box& fb = boxes[std::size_t(fi)];
            const auto& ports = u.linkFrom.output ? fb.type->outputs : fb.type->inputs;
            for (int k = 0; k < int(ports.size()); ++k) {
                if (ports[std::size_t(k)].name != u.linkFrom.port) continue;
                const Vec2 pp = u.linkFrom.output ? output_pos(fb, k) : input_pos(fb, k);
                const ImVec2 a = S(pp.x, pp.y);
                const float dx = std::max(40.0f * zoom, std::abs(mouse.x - a.x) * 0.5f);
                const float sign = u.linkFrom.output ? 1.0f : -1.0f;
                dl->AddBezierCubic(a, ImVec2(a.x + dx * sign, a.y), ImVec2(mouse.x - dx * sign, mouse.y), mouse,
                                   port_color(ports[std::size_t(k)].type), 2.5f);
            }
        }
    }
    const float fs = ImGui::GetFontSize() * std::clamp(zoom, 0.55f, 1.4f);
    ImFont* font = ImGui::GetFont();
    const bool labels = zoom >= 0.5f;
    for (const Box& b : boxes) {
        const ImVec2 a = S(b.x, b.y), c = S(b.x + b.w, b.y + b.h);
        if (c.x < p0.x || a.x > p1.x || c.y < p0.y || a.y > p1.y) continue;
        const std::vector<GraphIssue> issues = m.node_issues(b.id);
        const bool bad = std::any_of(issues.begin(), issues.end(), [](const GraphIssue& is) { return !is.warning; });
        const bool warn = !bad && !issues.empty();
        const bool sel = m.is_selected(b.id);
        const float r = 5.0f * zoom;
        dl->AddRectFilled(a, c, IM_COL32(48, 50, 56, 245), r);
        dl->AddRectFilled(a, ImVec2(c.x, a.y + kHeaderH * zoom), header_color(b.type ? b.type->category : "?"), r,
                          ImDrawFlags_RoundCornersTop);
        dl->AddRect(a, c,
                    bad    ? IM_COL32(235, 80, 70, 255)
                    : warn ? IM_COL32(235, 190, 70, 255)
                    : sel  ? IM_COL32(255, 255, 255, 255)
                           : IM_COL32(90, 92, 100, 255),
                    r, 0, (bad || warn || sel ? 2.0f : 1.0f));
        if (bad && sel)
            dl->AddRect(ImVec2(a.x - 2, a.y - 2), ImVec2(c.x + 2, c.y + 2), IM_COL32(255, 255, 255, 200), r + 2.0f, 0,
                        1.0f);
        if (labels) {
            const std::string title = b.type ? b.type->type : b.id + " (unknown type)";
            dl->AddText(font, fs, ImVec2(a.x + 8.0f * zoom, a.y + (kHeaderH * zoom - fs) * 0.5f),
                        IM_COL32(240, 240, 240, 255), title.c_str());
        }
        if (!b.type) continue;
        for (int k = 0; k < int(b.type->inputs.size()); ++k) {
            const GraphPort& port = b.type->inputs[std::size_t(k)];
            const Vec2 pp = input_pos(b, k);
            const ImVec2 sp = S(pp.x, pp.y);
            const bool linked = m.link_index_into(b.id, port.name) >= 0;
            const bool over = hit.kind == Hit::Port && hit.node >= 0 && boxes[std::size_t(hit.node)].id == b.id &&
                              !hit.output && hit.port == k;
            bool compatible = true;
            if (u.drag == GraphUi::Drag::Link && u.linkFrom.output) {
                const int fi = m.node_index(u.linkFrom.node);
                const GraphNodeType* ft = fi >= 0 ? boxes[std::size_t(fi)].type : nullptr;
                const GraphPort* fp = ft ? find_port(ft->outputs, u.linkFrom.port) : nullptr;
                compatible = fp && u.linkFrom.node != b.id && graph_ports_may_link(fp->type, port.type);
            }
            dl->AddCircleFilled(sp, (over ? kPortR + 2.0f : kPortR) * std::max(zoom, 0.7f),
                                compatible ? port_color(port.type) : IM_COL32(80, 80, 80, 255));
            if (!linked) dl->AddCircleFilled(sp, 2.0f * std::max(zoom, 0.7f), IM_COL32(28, 29, 33, 255));
            if (labels) {
                dl->AddText(font, fs, ImVec2(sp.x + 9.0f * zoom, sp.y - fs * 0.5f), IM_COL32(215, 215, 220, 255),
                            port.name.c_str());
                if (!linked && std::size_t(k) >= b.type->outputs.size()) {
                    const Json v = m.input_value(b.id, port.name);
                    const std::string txt = value_text(v.is_null() ? port.defaultValue : v);
                    if (!txt.empty()) {
                        const float nameW = ImGui::CalcTextSize(port.name.c_str()).x * fs / ImGui::GetFontSize();
                        dl->AddText(font, fs, ImVec2(sp.x + 16.0f * zoom + nameW, sp.y - fs * 0.5f),
                                    v.is_null() ? IM_COL32(130, 132, 140, 255) : IM_COL32(250, 220, 120, 255),
                                    txt.c_str());
                    }
                }
            }
        }
        for (int k = 0; k < int(b.type->outputs.size()); ++k) {
            const GraphPort& port = b.type->outputs[std::size_t(k)];
            const Vec2 pp = output_pos(b, k);
            const ImVec2 sp = S(pp.x, pp.y);
            const bool over = hit.kind == Hit::Port && hit.node >= 0 && boxes[std::size_t(hit.node)].id == b.id &&
                              hit.output && hit.port == k;
            bool compatible = true;
            if (u.drag == GraphUi::Drag::Link && !u.linkFrom.output) {
                const int fi = m.node_index(u.linkFrom.node);
                const GraphNodeType* ft = fi >= 0 ? boxes[std::size_t(fi)].type : nullptr;
                const GraphPort* fp = ft ? find_port(ft->inputs, u.linkFrom.port) : nullptr;
                compatible = fp && u.linkFrom.node != b.id && graph_ports_may_link(port.type, fp->type);
            }
            dl->AddCircleFilled(sp, (over ? kPortR + 2.0f : kPortR) * std::max(zoom, 0.7f),
                                compatible ? port_color(port.type) : IM_COL32(80, 80, 80, 255));
            if (labels) {
                const float w = ImGui::CalcTextSize(port.name.c_str()).x * fs / ImGui::GetFontSize();
                dl->AddText(font, fs, ImVec2(sp.x - 9.0f * zoom - w, sp.y - fs * 0.5f), IM_COL32(215, 215, 220, 255),
                            port.name.c_str());
            }
        }
        if (labels && !b.type->ref.empty()) {
            const Json nodeJson = m.graph()["nodes"][std::size_t(m.node_index(b.id))];
            const std::string ref = nodeJson.value(b.type->ref, std::string());
            const float y = b.y + kHeaderH + float(b.rows - 1) * kRowH + kRowH * 0.5f;
            const ImVec2 sp = S(b.x + 10.0f, y);
            dl->AddText(font, fs, ImVec2(sp.x, sp.y - fs * 0.5f),
                        ref.empty() ? IM_COL32(235, 120, 100, 255) : IM_COL32(250, 220, 120, 255),
                        (b.type->ref + ": " + (ref.empty() ? std::string("(none)") : ref)).c_str());
        }
    }
    if (u.drag == GraphUi::Drag::Box) {
        const ImVec2 a(std::min(u.dragStart.x, mouse.x), std::min(u.dragStart.y, mouse.y)),
            c(std::max(u.dragStart.x, mouse.x), std::max(u.dragStart.y, mouse.y));
        dl->AddRectFilled(a, c, IM_COL32(120, 160, 255, 40));
        dl->AddRect(a, c, IM_COL32(120, 160, 255, 160));
    }
    if (!u.linkMessage.empty()) {
        dl->AddText(ImVec2(p0.x + 8, p1.y - ImGui::GetFontSize() - 6), IM_COL32(255, 140, 120, 255),
                    u.linkMessage.c_str());
    }
    if (boxes.size() <= 1 && u.drag == GraphUi::Drag::None)
        dl->AddText(ImVec2(p0.x + 12, p0.y + 8), IM_COL32(150, 152, 160, 255),
                    "Right click for the node list. Drag from a port to link.");
    dl->PopClipRect();

    // Remember where the user left the view (the file keeps it; the generator ignores it).
    if (u.drag == GraphUi::Drag::None &&
        (std::abs(m.saved_view().zoom - u.zoom) > 1e-4f || std::abs(m.saved_view().panX - u.panX) > 0.5f ||
         std::abs(m.saved_view().panY - u.panY) > 0.5f || !m.saved_view().known))
        m.set_view(u.zoom, std::round(u.panX), std::round(u.panY));

    draw_graph_palette(m);
}

void Editor::draw_graph_palette(GraphModel& m) {
    GraphUi& u = graph_;
    if (u.openPalette) {
        u.openPalette = false;
        u.filter.clear();
        u.focusFilter = true;
        ImGui::OpenPopup("##graphpalette");
    }
    ImGui::SetNextWindowSizeConstraints(ImVec2(260, 160), ImVec2(380, std::max(200.0f, u.canvasH - 10.0f)));
    if (!ImGui::BeginPopup("##graphpalette")) return;
    if (u.focusFilter) {
        ImGui::SetKeyboardFocusHere();
        u.focusFilter = false;
    }
    ImGui::SetNextItemWidth(-FLT_MIN);
    const bool enter = ImGui::InputTextWithHint("##gfilter", "Search nodes (noise, mix, time...)", &u.filter,
                                                ImGuiInputTextFlags_EnterReturnsTrue);
    at_track("gr:filter");
    hint("Matches the name, the category and the description of every node of the library.");
    const std::vector<const GraphNodeType*> list = m.palette(u.filter);
    std::string add;
    ImGui::BeginChild("##gpalettelist", ImVec2(0, std::min(320.0f, std::max(120.0f, u.canvasH - 80.0f))), false);
    std::string category;
    bool open = true;
    for (const GraphNodeType* t : list) {
        if (t->category != category) {
            category = t->category;
            if (u.filter.empty())
                open = ImGui::CollapsingHeader(category.c_str(), ImGuiTreeNodeFlags_DefaultOpen);
            else
                ImGui::TextDisabled("%s", category.c_str());
        }
        if (!open) continue;
        if (ImGui::Selectable((t->type + "##pal" + t->type).c_str())) add = t->type;
        at_track("gr:add:" + t->type);
        hint(t->doc);
    }
    if (list.empty()) ImGui::TextDisabled("No node matches \"%s\".", u.filter.c_str());
    ImGui::EndChild();
    if (enter && add.empty() && !list.empty()) add = list.front()->type;
    if (!add.empty()) {
        const GraphEditOutcome out = m.add_node(add, u.menuAt);
        graph_edited(out);
        if (out.ok && !out.id.empty()) m.select(out.id);
        u.selectedLink = -1;
        ImGui::CloseCurrentPopup();
    }
    ImGui::EndPopup();
}

// ------------------------------------------------------------------------------------------------------------- side --
void Editor::draw_graph_side(GraphModel& m) {
    GraphUi& u = graph_;
    GraphPreview& pv = *u.preview;

    // ---- the preview
    ImGui::TextUnformatted("Preview");
    const float w = std::clamp(ImGui::GetContentRegionAvail().x - 4.0f, 96.0f, 300.0f);
    if (pv.image_serial() != u.picture.serial && !pv.image().empty()) {
        if (put_texture(u.picture, u.graveyard, pv.image(), uiFrame_)) u.picture.serial = pv.image_serial();
    }
    const ImVec2 q0 = ImGui::GetCursorScreenPos();
    ImGui::InvisibleButton("##gpreview", ImVec2(w, w));
    at_track("gr:preview");
    ImDrawList* dl = ImGui::GetWindowDrawList();
    dl->AddRectFilled(q0, ImVec2(q0.x + w, q0.y + w), IM_COL32(40, 42, 48, 255));
    if (u.picture.view)
        dl->AddImage(ImTextureRef(ImTextureID(ui::texture_from_view(u.picture.view, true))), q0,
                     ImVec2(q0.x + w, q0.y + w));
    hint("The material as it is now, drawn by the engine's renderer (not as saved). It follows the edits a moment "
         "after they stop.");
    switch (pv.state()) {
        case PreviewState::Waiting: ImGui::TextDisabled("waiting for the edits to stop..."); break;
        case PreviewState::Compiling: ImGui::TextDisabled("compiling the shader..."); break;
        case PreviewState::Ready: ImGui::TextDisabled("up to date"); break;
        case PreviewState::NoRenderer: ImGui::TextWrapped("%s", pv.message().c_str()); break;
        case PreviewState::Error:
            ImGui::TextColored(kBad, "The preview is behind: the graph does not build.");
            at_track("gr:preview:error");
            ImGui::PushTextWrapPos(0.0f);
            ImGui::TextUnformatted(pv.message().c_str());
            ImGui::PopTextWrapPos();
            break;
        case PreviewState::Empty: break;
    }
    PreviewShape shape = pv.shape();
    FitRow row;
    for (const auto& [label, s] : {std::pair<const char*, PreviewShape>{"Sphere", PreviewShape::Sphere},
                                   {"Cube", PreviewShape::Cube},
                                   {"Quad", PreviewShape::Quad}}) {
        if (ImGui::RadioButton(label, shape == s)) pv.set_shape(s);
        at_track(std::string("gr:shape:") + label);
        row.next("Quad");
    }
    ImGui::NewLine();
    bool anim = pv.animated();
    if (ImGui::Checkbox("Animate", &anim)) pv.set_animated(anim);
    at_track("gr:animate");
    hint("Draws the preview again every few frames, for a graph that reads the time.");
    ImGui::Separator();

    // ---- the selected node
    const std::set<std::string>& sel = m.selection();
    if (sel.size() == 1) {
        draw_graph_node_inspector(m, *sel.begin());
    } else if (u.selectedLink >= 0 && u.selectedLink < m.link_count()) {
        const Json& l = m.graph()["links"][std::size_t(u.selectedLink)];
        ImGui::Text("Link %s -> %s", l.value("from", std::string()).c_str(), l.value("to", std::string()).c_str());
        if (ImGui::Button("Cut link")) {
            graph_edited(m.remove_link(u.selectedLink));
            u.selectedLink = -1;
        }
        at_track("gr:cutlink");
    } else if (sel.size() > 1) {
        ImGui::Text("%d nodes selected", int(sel.size()));
        if (ImGui::Button("Delete##many")) graph_edited(m.remove_nodes(sel));
        ImGui::SameLine();
        if (ImGui::Button("Duplicate##many")) graph_edited(m.duplicate(sel));
    } else {
        ImGui::TextDisabled("Select a node to edit its constants.");
    }
    ImGui::Separator();

    // ---- the problems
    const MaterialGraphReport& rep = m.report();
    ImGui::Text("Problems: %d errors, %d warnings", int(rep.errors.size()), int(rep.warnings.size()));
    at_track("gr:problems");
    auto list = [&](const std::vector<MaterialIssue>& issues, bool warning) {
        int n = 0;
        for (const MaterialIssue& is : issues) {
            if (++n > 40) {
                ImGui::TextDisabled("...and %d more", int(issues.size()) - 40);
                break;
            }
            ImGui::PushID(n + (warning ? 1000 : 0));
            ImGui::PushStyleColor(ImGuiCol_Text, warning ? kWarn : kBad);
            const bool clicked = ImGui::Selectable((is.pointer + ": " + is.message).c_str(), false);
            ImGui::PopStyleColor();
            if (!is.hint.empty()) hint(is.hint);
            ImGui::PopID();
            if (clicked) {
                const int node = pointer_index(is.pointer, "/graph/nodes/");
                const int link = pointer_index(is.pointer, "/graph/links/");
                if (node >= 0 && node < m.node_count()) {
                    m.select(m.node_id(node));
                    u.selectedLink = -1;
                } else if (link >= 0 && link < m.link_count()) {
                    u.selectedLink = link;
                    m.clear_selection();
                }
            }
            at_track(std::string("gr:problem:") + (warning ? "w" : "e") + std::to_string(n));
        }
    };
    list(rep.errors, false);
    list(rep.warnings, true);
}

void Editor::draw_graph_node_inspector(GraphModel& m, const std::string& id) {
    GraphUi& u = graph_;
    const GraphNodeType* t = m.node_type(id);
    ImGui::PushID(id.c_str());
    ImGui::Text("%s", id.c_str());
    ImGui::SameLine();
    ImGui::TextDisabled("%s", t ? t->type.c_str() : "unknown type");
    if (t) {
        ImGui::PushTextWrapPos(0.0f);
        ImGui::TextDisabled("%s", t->doc.c_str());
        ImGui::PopTextWrapPos();
    }
    if (t && !t->ref.empty()) {
        const Json& doc = m.material_json();
        const char* section = t->ref == "param" ? "params" : "textures";
        std::vector<std::string> names;
        if (doc.contains(section) && doc[section].is_object())
            for (const auto& [k, v] : doc[section].items()) names.push_back(k);
        std::sort(names.begin(), names.end());
        const Json node = m.graph()["nodes"][std::size_t(m.node_index(id))];
        const std::string cur = node.value(t->ref, std::string());
        ImGui::SetNextItemWidth(-FLT_MIN);
        if (ImGui::BeginCombo("##gref", cur.empty() ? "(choose)" : cur.c_str())) {
            for (const std::string& n : names)
                if (ImGui::Selectable(n.c_str(), n == cur)) graph_edited(m.set_ref(id, n));
            if (names.empty())
                ImGui::TextDisabled("The material declares no %s yet (edit the file or ask an AI).", section);
            ImGui::EndCombo();
        }
        at_track("gr:ref");
        hint(std::string("The ") + t->ref + " of the material this node reads.");
    }
    if (t) {
        for (const GraphPort& port : t->inputs) {
            ImGui::PushID(port.name.c_str());
            const GraphPortId src = m.link_source(id, port.name);
            if (src.valid()) {
                ImGui::Text("%s", port.name.c_str());
                ImGui::SameLine();
                ImGui::TextDisabled("<- %s.%s", src.node.c_str(), src.port.c_str());
                ImGui::SameLine();
                if (ImGui::SmallButton("Cut")) graph_edited(m.disconnect(id + "." + port.name));
                at_track("gr:cut:" + id + "." + port.name);
            } else if (graph_port_class(port.type) == 5 || port.type == "param") {
                ImGui::Text("%s", port.name.c_str());
                ImGui::SameLine();
                ImGui::TextDisabled("(link a node)");
            } else {
                const Json set = m.input_value(id, port.name);
                const Json& base = set.is_null() ? port.defaultValue : set;
                const int n = port_components(port.type, base);
                float v[4] = {0, 0, 0, 0};
                if (base.is_number()) {
                    for (int i = 0; i < n; ++i) v[i] = base.get<float>();
                } else if (base.is_array()) {
                    for (int i = 0; i < n && i < int(base.size()); ++i)
                        if (base[std::size_t(i)].is_number()) v[i] = base[std::size_t(i)].get<float>();
                }
                if (base.is_string()) ImGui::TextDisabled("%s", port.name.c_str());
                ImGui::SetNextItemWidth(-48.0f);
                const bool changed = ImGui::DragScalarN(port.name.c_str(), ImGuiDataType_Float, v, n, 0.01f);
                const std::string track = "gr:in:" + id + "." + port.name;
                at_track(track);
                hint(port.doc + (base.is_string() ? "\nUnlinked, it reads " + value_text(base) + "." : std::string()));
                if (ImGui::IsItemActivated()) m.begin_gesture();
                if (changed) {
                    for (float& f : v)
                        if (!std::isfinite(f)) f = 0.0f;
                    Json val = Json::array();
                    for (int i = 0; i < n; ++i) val.push_back(double(std::round(v[i] * 10000.0f) / 10000.0f));
                    const GraphEditOutcome o = m.set_input(id, port.name, n == 1 ? val[0] : val);
                    if (!o.ok) u.linkMessage = o.error;
                }
                if (ImGui::IsItemDeactivated()) graph_edited(m.end_gesture("Edit " + port.name));
                if (!set.is_null()) {
                    ImGui::SameLine();
                    if (ImGui::SmallButton("x")) graph_edited(m.set_input(id, port.name, Json()));
                    at_track("gr:reset:" + id + "." + port.name);
                    hint("Back to the default.");
                }
            }
            ImGui::PopID();
        }
    }
    if (ImGui::Button("Delete node")) graph_edited(m.remove_nodes({id}));
    at_track("gr:delete");
    ImGui::SameLine();
    if (ImGui::Button("Duplicate")) graph_edited(m.duplicate({id}));
    at_track("gr:duplicate");
    ImGui::PopID();
}

}  // namespace fa::editor
