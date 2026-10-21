// Project panel (View > Project): the project's files. A folder tree on the left, the files of the chosen folder on the right
// (thumbnails for pictures, a badge for the rest), a type filter and a search box. The listing is cached (project_browser_model.h)
// and rescanned on Refresh, when the window gains focus and after the editor writes or deletes a file; never per frame.
//
// Actions, all through the commands the AI uses: dragging a file (payload "FA_ASSET", the project-relative path) onto an
// Inspector asset field of the same type sets that field (inspector_panel.cpp) and a prefab onto the Viewport spawns it with
// scene.spawn (viewport.cpp, Editor::viewport_accept_drop); a double click opens a scene; the right-click menu reveals a file in
// the file manager, copies its path or deletes it (fs.delete, after a confirmation).
#include <algorithm>
#include <cfloat>
#include <cmath>

#include "editor_internal.h"
#include "imgui_internal.h"
#include "fa/runtime/project.h"
#include "project_browser_model.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

ImU32 badge_color(std::string_view type) {
    if (type == "audio") return IM_COL32(70, 120, 170, 255);
    if (type == "font") return IM_COL32(120, 100, 160, 255);
    if (type == "mesh") return IM_COL32(60, 140, 110, 255);
    if (type == "script") return IM_COL32(170, 140, 50, 255);
    if (type == "scene") return IM_COL32(170, 90, 70, 255);
    if (type == "prefab") return IM_COL32(70, 150, 190, 255);
    if (type == "material") return IM_COL32(160, 80, 140, 255);
    return IM_COL32(100, 100, 108, 255);
}

constexpr float kTileW = 84.0f, kThumb = 56.0f;

}  // namespace

void Editor::project_files_changed() { projBrowser_.stale = true; }

void Editor::draw_project_panel() {
    // A newly shown panel joins the Console's tab bar instead of floating.
    if (ImGuiWindow* console = ImGui::FindWindowByName("Console"); console && console->DockId != 0)
        ImGui::SetNextWindowDockID(console->DockId, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(720, 240), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Project", &showProject_)) {
        projBrowser_.windowFocused = false;
        ImGui::End();
        return;
    }
    ProjectBrowser& pb = projBrowser_;
    const bool focused = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows);
    if (focused && !pb.windowFocused) pb.stale = true;  // coming back to the panel: the files may have changed meanwhile
    pb.windowFocused = focused;
    if (pb.project != projectDir_) {  // another project
        pb = ProjectBrowser{};
        pb.project = projectDir_;
    }
    if (pb.stale || !pb.scanned) {
        pb.listing = scan_project(projectDir_);
        pb.tree = build_folder_tree(pb.listing);
        pb.stale = false;
        pb.scanned = true;
        ++pb.scans;
        const bool known = pb.query.folder.empty() || std::find(pb.listing.folders.begin(), pb.listing.folders.end(), pb.query.folder) !=
                                                          pb.listing.folders.end();
        if (!known) pb.query.folder.clear();
    }
    BrowserQuery& q = pb.query;

    // ---- toolbar
    if (ImGui::Button("Refresh")) pb.stale = true;
    at_track("proj:refresh");
    ImGui::SetItemTooltip("Read the project's files again (this also happens when the window gains focus and after the editor writes or deletes a file)");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(100);
    if (ImGui::BeginCombo("##projtype", q.type.c_str())) {
        for (const std::string& t : browser_type_filters()) {
            if (ImGui::Selectable(t.c_str(), t == q.type)) q.type = t;
            at_track("proj:type:" + t);
        }
        ImGui::EndCombo();
    }
    at_track("proj:type");
    ImGui::SetItemTooltip("Show only files of this type (all, texture, audio, font, mesh, script, scene, prefab, material)");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(std::max(120.0f, std::min(260.0f, ImGui::GetContentRegionAvail().x - 190.0f)));
    ImGui::InputTextWithHint("##projsearch", "Search...", &q.search);
    at_track("proj:search");
    ImGui::SetItemTooltip("Case-insensitive part of a path; a search looks through the whole project, not only the chosen folder");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(84);
    static const char* sortNames[] = {"Name", "Type", "Size"};
    if (ImGui::BeginCombo("##projsort", sortNames[int(q.sort)])) {
        for (int i = 0; i < 3; ++i)
            if (ImGui::Selectable(sortNames[i], int(q.sort) == i)) q.sort = BrowserSort(i);
        ImGui::EndCombo();
    }
    ImGui::SetItemTooltip("Sort the files by name, type or size");
    ImGui::SameLine();
    ImGui::Checkbox("Desc", &q.descending);
    ImGui::SetItemTooltip("Reverse the order");

    const std::vector<std::size_t> shown = query_files(pb.listing, q);
    ImGui::SameLine();
    ImGui::TextDisabled("%zu file%s%s", shown.size(), shown.size() == 1 ? "" : "s", pb.listing.truncated ? " (list cut)" : "");

    // ---- folder tree | files
    const float treeW = std::clamp(ImGui::GetContentRegionAvail().x * 0.22f, 130.0f, 240.0f);
    ImGui::BeginChild("##projtree", ImVec2(treeW, 0), ImGuiChildFlags_Borders);
    auto draw_node = [&](auto&& self, const FolderNode& n, bool isRoot) -> void {
        ImGuiTreeNodeFlags fl = ImGuiTreeNodeFlags_OpenOnArrow | ImGuiTreeNodeFlags_SpanAvailWidth;
        if (n.children.empty()) fl |= ImGuiTreeNodeFlags_Leaf;
        if (isRoot) fl |= ImGuiTreeNodeFlags_DefaultOpen;
        if (n.path == q.folder) fl |= ImGuiTreeNodeFlags_Selected;
        const std::string label = (isRoot ? std::string("Project (all files)") : n.name) + "###dir:" + n.path;
        const bool open = ImGui::TreeNodeEx(label.c_str(), fl);
        at_track("proj:folder:" + n.path);
        if (ImGui::IsItemClicked() && !ImGui::IsItemToggledOpen()) q.folder = n.path;
        if (ImGui::IsItemHovered()) ImGui::SetItemTooltip("%d file%s in it and below", n.fileCount, n.fileCount == 1 ? "" : "s");
        if (open) {
            for (const FolderNode& c : n.children) self(self, c, false);
            ImGui::TreePop();
        }
    };
    draw_node(draw_node, pb.tree, true);
    ImGui::EndChild();
    ImGui::SameLine();

    ImGui::BeginChild("##projfiles", ImVec2(0, 0), ImGuiChildFlags_Borders);
    if (shown.empty()) {
        ImGui::TextDisabled(pb.listing.files.empty() ? "The project has no files yet." : "No file matches the filter.");
    } else {
        const float availW = ImGui::GetContentRegionAvail().x;
        const int cols = std::max(1, int(availW / kTileW));
        const int rows = int((shown.size() + std::size_t(cols) - 1) / std::size_t(cols));
        const float tileH = kThumb + ImGui::GetTextLineHeight() + 12.0f;
        ImGuiListClipper clip;
        clip.Begin(rows, tileH + ImGui::GetStyle().ItemSpacing.y);
        while (clip.Step()) {
            for (int row = clip.DisplayStart; row < clip.DisplayEnd; ++row) {
                for (int col = 0; col < cols; ++col) {
                    const std::size_t idx = std::size_t(row) * std::size_t(cols) + std::size_t(col);
                    if (idx >= shown.size()) break;
                    if (col > 0) ImGui::SameLine();
                    draw_project_tile(pb.listing.files[shown[idx]], ImVec2(kTileW - ImGui::GetStyle().ItemSpacing.x, tileH));
                }
            }
        }
    }
    ImGui::EndChild();

    // ---- delete confirmation (the right-click menu asks for it)
    if (!pb.deleteAsk.empty() && !ImGui::IsPopupOpen("Delete file?")) ImGui::OpenPopup("Delete file?");
    if (ImGui::BeginPopupModal("Delete file?", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::Text("Delete '%s'?", pb.deleteAsk.c_str());
        ImGui::TextColored(kStatusFailed, "The file is removed from disk (fs.delete). This cannot be undone with Ctrl+Z.");
        if (pb.deleteAsk == scenePath_) ImGui::TextColored(kStatusWarn, "This is the scene that is open now.");
        const bool cancel = ImGui::Button("Cancel", ImVec2(120, 0)) || ImGui::IsKeyPressed(ImGuiKey_Escape);
        at_track("proj:delete-cancel");
        ImGui::SetItemDefaultFocus();
        ImGui::SameLine();
        const bool confirmed = ImGui::Button("Delete", ImVec2(120, 0));
        at_track("proj:delete-confirm");
        if (confirmed) {
            std::string err;
            CommandResult r = edit_command("proj:delete", "fs.delete", Json::object({{"path", pb.deleteAsk}}), &err);
            if (!r.ok) notify("Could not delete " + pb.deleteAsk + ": " + err, 2);
            else notify("Deleted " + pb.deleteAsk);
            if (pb.selected == pb.deleteAsk) pb.selected.clear();
            pb.deleteAsk.clear();
            pb.stale = true;
            ImGui::CloseCurrentPopup();
        } else if (cancel) {
            pb.deleteAsk.clear();
            ImGui::CloseCurrentPopup();
        }
        ImGui::EndPopup();
    }
    ImGui::End();
}

void Editor::draw_project_tile(const BrowserFile& f, ImVec2 size) {
    ProjectBrowser& pb = projBrowser_;
    ImGui::PushID(f.path.c_str());
    const ImVec2 p0 = ImGui::GetCursorScreenPos();
    const bool isSel = pb.selected == f.path;
    ImGui::Selectable("##tile", isSel, ImGuiSelectableFlags_AllowDoubleClick, size);
    at_track("proj:file:" + f.path);
    const bool hovered = ImGui::IsItemHovered();
    if (ImGui::IsItemClicked(ImGuiMouseButton_Left) || ImGui::IsItemClicked(ImGuiMouseButton_Right)) pb.selected = f.path;

    // Drag: the payload is the project-relative path (Inspector asset fields and the Viewport accept it).
    if (ImGui::BeginDragDropSource(ImGuiDragDropFlags_None)) {
        ImGui::SetDragDropPayload(kAssetPayload, f.path.c_str(), f.path.size() + 1);
        ImGui::TextUnformatted(f.path.c_str());
        ImGui::TextDisabled("%s", f.type.c_str());
        ImGui::EndDragDropSource();
    }
    if (hovered && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left) && f.type == "scene") {
        if (dirty_) pendingScene_ = f.path;  // the "Unsaved changes" dialog asks first
        else open_scene(f.path);
    }
    if (hovered && !ImGui::IsMouseDragging(ImGuiMouseButton_Left)) {
        ImGui::SetTooltip("%s\n%s, %s%s", f.path.c_str(), f.type.c_str(), size_text(f.size).c_str(),
                          f.type == "scene" ? "\nDouble-click to open" : f.type == "prefab" ? "\nDrag onto the Viewport to spawn it" : "");
    }

    // The thumbnail (pictures), or a badge with the extension.
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImVec2 box0(p0.x + (size.x - kThumb) * 0.5f, p0.y + 3.0f);
    const ImVec2 box1(box0.x + kThumb, box0.y + kThumb);
    const TextureEntry* tex = f.type == "texture" && f.size < 16u * 1024u * 1024u ? texture_for(f.path) : nullptr;
    if (tex && tex->w > 0 && tex->h > 0) {
        const float s = std::min(kThumb / float(tex->w), kThumb / float(tex->h));
        const ImVec2 sz(float(tex->w) * s, float(tex->h) * s);
        const ImVec2 a(box0.x + (kThumb - sz.x) * 0.5f, box0.y + (kThumb - sz.y) * 0.5f);
        dl->AddRectFilled(box0, box1, IM_COL32(40, 40, 46, 255), 3.0f);
        dl->AddImage(ImTextureRef(ImTextureID(ui::texture_from_view(tex->view, true))), a, ImVec2(a.x + sz.x, a.y + sz.y));
    } else {
        dl->AddRectFilled(box0, box1, badge_color(f.type), 4.0f);
        const std::string badge = type_badge(f.path, f.type);
        const ImVec2 ts = ImGui::CalcTextSize(badge.c_str());
        dl->AddText(ImVec2(box0.x + (kThumb - ts.x) * 0.5f, box0.y + (kThumb - ts.y) * 0.5f), IM_COL32(255, 255, 255, 235), badge.c_str());
    }
    // The name under it, cut to the tile (the tooltip has the whole path).
    const std::string name = file_name_of(f.path);
    const ImVec2 lp(p0.x + 2.0f, box1.y + 3.0f);
    dl->PushClipRect(ImVec2(p0.x, lp.y), ImVec2(p0.x + size.x, p0.y + size.y), true);
    const ImVec2 ts = ImGui::CalcTextSize(name.c_str());
    dl->AddText(ImVec2(ts.x < size.x - 4.0f ? p0.x + (size.x - ts.x) * 0.5f : lp.x, lp.y), ImGui::GetColorU32(ImGuiCol_Text), name.c_str());
    dl->PopClipRect();

    if (ImGui::BeginPopupContextItem("##ctx")) {
        pb.selected = f.path;
        const std::string reveal = std::string("Show in ") + file_manager_name();
        if (ImGui::MenuItem(reveal.c_str())) {
            const std::string err = reveal_in_file_manager(projectDir_ + "/" + f.path);
            if (!err.empty()) notify(err, 1);
        }
        at_track("proj:ctx:reveal");
        if (ImGui::MenuItem("Copy path")) ImGui::SetClipboardText(f.path.c_str());
        at_track("proj:ctx:copy");
        ImGui::Separator();
        if (ImGui::MenuItem("Delete...")) pb.deleteAsk = f.path;
        at_track("proj:ctx:delete");
        ImGui::EndPopup();
    }
    ImGui::PopID();
}

// A file dragged over the Viewport (viewport.cpp calls this right after the viewport's hit item; `design` is the mouse in design
// pixels). A prefab dropped here becomes an entity with scene.spawn {prefab, position}: in 2D at the world point under the mouse
// on the z = 0 plane, in 3D where the mouse ray meets the ground (y = 0), else 10 units in front of the camera. It is selected.
// Other file types are refused (the tooltip says so).
void Editor::viewport_accept_drop(Renderer& r, Vec2 design) {
    if (!ImGui::BeginDragDropTarget()) return;
    const ImGuiPayload* live = ImGui::GetDragDropPayload();
    if (live && live->IsDataType(kAssetPayload) && live->Data) {
        const std::string path(static_cast<const char*>(live->Data));
        if (asset_type_of(path) != "prefab") {
            ImGui::SetTooltip("Only prefabs (.prefab.json) can be dropped on the Viewport");
        } else if (const ImGuiPayload* got = ImGui::AcceptDragDropPayload(kAssetPayload)) {
            (void)got;
            Json pos;
            if (primary_is_ortho()) {
                const Vec3 wp = r.screen_to_world(design, 0.0f);
                pos = Json::array({wp.x, wp.y});
            } else {
                Vec3 o, d;
                r.screen_ray(design, o, d);
                const Vec3 wp = drop_point_3d(o, d);
                pos = Json::array({wp.x, wp.y, wp.z});
            }
            std::string err;
            CommandResult res = edit_command("proj:spawn:" + std::to_string(uiFrame_), "scene.spawn",
                                             Json::object({{"prefab", path}, {"position", pos}}), &err);
            if (!res.ok) notify("Could not spawn " + path + ": " + err, 2);
            else select_id(res.result.value("id", std::string()));
        }
    }
    ImGui::EndDragDropTarget();
}

}  // namespace fa::editor
