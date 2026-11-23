// The Cells panel (View > Cells) and the cell grid in the viewport: editing a streamed world (docs/BIG_WORLDS_STREAMING.md, "Editing a streamed world").
// The model is cell_edit.h; this file is the UI. Edit mode only: Play streams by distance, and the cells the user loaded come back at Stop.
//
// The panel lists the cells nearest the camera (and every loaded one) with their state (not loaded, loaded, unsaved), loads the cells around
// the camera or one picked cell, unloads (a cell with unsaved changes asks first), selects a cell's root entity in the Hierarchy and saves.
// There is no free editor camera: the view is the scene's camera, so "around the view" is around that camera.
#include <algorithm>
#include <cfloat>
#include <cmath>
#include <cstdio>

#include "editor_internal.h"

namespace fa::editor {

namespace {

constexpr std::size_t kMaxRows = 200;  // cells listed (and drawn in the viewport) at most

void tip(const char* text) {
    if (!ImGui::BeginItemTooltip()) return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text);
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

std::string cell_widget(const char* what, const CellRow& r) {
    return std::string("cells:") + what + ":" + std::to_string(r.i) + "_" + std::to_string(r.j);
}

ImU32 state_color(const CellRow& r, int alpha) {
    if (r.dirty) return IM_COL32(255, 160, 40, alpha);
    if (r.loaded) return IM_COL32(80, 220, 120, alpha);
    return IM_COL32(150, 150, 150, alpha);
}

}  // namespace

// The camera's position on the world's plane, in absolute metres: what "around the view" means. The renderer's main camera when there is
// one (its eye is in the engine's local space, so the floating origin is added back), else the first Camera entity.
bool Editor::cells_view_point(double& a, double& b) {
    if (!engine_ || !cells_.has_index()) return false;
    DVec3 abs{0, 0, 0};
    bool have = false;
    if (Renderer* r = engine_->renderer(); r && r->initialized() && r->target_width() > 0) {
        Vec3 eye, forward;
        r->screen_ray(Vec2{float(r->target_width()) * 0.5f, float(r->target_height()) * 0.5f}, eye, forward);
        abs = world().origin() + DVec3{double(eye.x), double(eye.y), double(eye.z)};
        have = true;
    }
    if (!have) {
        world().each<Camera>([&](Entity e, Camera&) {
            if (!have) {
                abs = world().absolute_position(e);
                have = true;
            }
        });
    }
    if (!have) return false;
    cells_.plane_of(abs, a, b);
    return true;
}

void Editor::cells_refresh_rows() {
    double a = 0, b = 0;
    if (!cells_view_point(a, b)) {
        cellsUi_.rows.clear();
        cellsUi_.rowsKey = INT64_MIN;
        return;
    }
    std::int64_t vi = 0, vj = 0;
    cells_.index().cell_of(a, b, vi, vj);
    // The list is rebuilt only when it can differ: another cell under the camera, a cell loaded or unloaded, a mark changed, or an edit.
    std::int64_t key = vi * 1000003 + vj;
    key = key * 31 + cells_.loaded_count();
    key = key * 31 + cells_.dirty_count();
    key = key * 31 + std::int64_t(cells_.index().cells.size());
    key = key * 31 + std::int64_t(world().entity_count());
    key = key * 31 + (cells_.any_dirty() ? 1 : 0);
    if (key == cellsUi_.rowsKey && !cellsUi_.rows.empty()) return;
    cellsUi_.rowsKey = key;
    cellsUi_.rows = cells_.rows(world(), a, b, kMaxRows);
}

bool Editor::cells_load_around_view(std::string* message) {
    double a = 0, b = 0;
    if (!cells_view_point(a, b)) {
        if (message) *message = "There is no camera to take the view from: load a cell from the list.";
        return false;
    }
    const double radius = double(std::clamp(cellsUi_.radiusCells, 0, 8)) * cells_.index().cellSize;
    int loaded = 0, left = 0;
    std::string err;
    const bool ok = cells_.load_around(world(), a, b, radius, CellEdit::kMaxAround, &loaded, &left, &err);
    std::string text = "Loaded " + std::to_string(loaded) + " cell" + (loaded == 1 ? "" : "s") + " around the camera";
    if (left > 0)
        text += "; " + std::to_string(left) + " more in range (the editor loads at most " +
                std::to_string(CellEdit::kMaxAround) + " at a time)";
    if (!ok) text += ". " + err;
    if (message) *message = text;
    cells_.note_edit(world());
    cellsUi_.rowsKey = INT64_MIN;
    if (!cells_.warnings().empty()) notify(cells_.warnings(), 1);
    return ok;
}

bool Editor::cells_save(bool only, std::int32_t i, std::int32_t j) {
    if (play_ != PlayState::Edit) {
        notify("Stop the game before saving cells (play-mode changes are temporary).", 1);
        return false;
    }
    const CellSaveReport rep = cells_.save(world(), only, i, j);
    cellsUi_.rowsKey = INT64_MIN;
    if (!rep.ok) {
        cellsUi_.status = "Save failed: " + rep.error;
        notify(cellsUi_.status, 2);
        return false;
    }
    if (rep.moved > 0)
        notify(std::to_string(rep.moved) + " entit" + (rep.moved == 1 ? "y" : "ies") +
               " moved to the cell of their position (the cell files and the index say so now).");
    for (const std::string& note : rep.notes)
        notify(note, 1);  // e.g. the index on disk was unreadable and was overwritten
    if (!rep.written.empty()) {
        cellsUi_.status = "Saved " + std::to_string(rep.written.size()) + " cell file" +
                          (rep.written.size() == 1 ? "" : "s") + (rep.indexWritten ? " and the index" : "") + ".";
        notify(cellsUi_.status);
    }
    return true;
}

void Editor::cells_inspector_line(Entity e) {
    std::int32_t i = 0, j = 0;
    if (!cells_.cell_of_entity(world(), e, i, j)) return;
    const bool isRoot = world().info(e).streamedCell;
    ImGui::TextDisabled("%s %d,%d%s", isRoot ? "Cell root of" : "Cell", i, j,
                        cells_.is_dirty(i, j) ? " (unsaved changes)" : "");
    std::int32_t ti = 0, tj = 0;
    if (!isRoot && cells_.destination_of(world(), e, ti, tj) && (ti != i || tj != j)) {
        ImGui::TextColored(ImVec4(1.0f, 0.75f, 0.3f, 1.0f), "Its position is in cell %d,%d: Save moves it there.", ti,
                           tj);
        tip("The entity keeps its id and components. Save writes it into the file of the cell its position is in (the "
            "cell is loaded, "
            "or made and listed in the index when the index has none there).");
    }
}

void Editor::draw_cells_panel() {
    first_floating_window(ImVec2(220, 90), ImVec2(460, 520));
    if (!ImGui::Begin("Cells", &showCells_)) {
        ImGui::End();
        return;
    }
    if (!engine_) {
        ImGui::TextDisabled("Open a project to edit the cells of its streamed world.");
        ImGui::End();
        return;
    }
    if (play_ != PlayState::Edit) {
        ImGui::TextWrapped(
            "The game is running: it streams the cells by distance. Stop it to edit cells (the ones you had loaded "
            "come back).");
        ImGui::End();
        return;
    }
    if (!cells_.has_index()) {
        if (!cells_.error().empty()) {
            ImGui::TextColored(kStatusFailed, "The streamed world's index cannot be read:");
            ImGui::TextWrapped("%s", cells_.error().c_str());
        } else {
            ImGui::TextWrapped(
                "This scene has no StreamedWorld. Add one (its `world` names a *.world.json) or cut a scene into cells "
                "with world.split_cells (docs/BIG_WORLDS_STREAMING.md, \"Editing a streamed world\").");
        }
        if (ImGui::Button("Read the index again")) cells_.refresh(world(), true);
        at_track("cells:reread");
        tip("Look for the scene's StreamedWorld and read its index again.");
        ImGui::End();
        return;
    }
    const WorldIndex& idx = cells_.index();
    ImGui::TextWrapped("%s: %s, cells of %.4g m, %d in the index.", cells_.index_path().c_str(),
                       idx.dimension == WorldDimension::D3 ? "3D (cells on x and z)" : "2D (cells on x and y)",
                       idx.cellSize, int(idx.cells.size()));
    ImGui::TextWrapped(
        "Nothing streams here: only the cells you load are in the scene. %d loaded, %d with unsaved changes.",
        cells_.loaded_count(), cells_.dirty_count());
    tip("Edit mode never loads a cell by distance. Play streams them as the game does and Stop puts the ones you "
        "loaded back.");

    ImGui::SetNextItemWidth(90);
    ImGui::DragInt("##radius", &cellsUi_.radiusCells, 0.1f, 0, 8, "%d cells out");
    at_track("cells:radius");
    tip("How far around the camera 'Load around the view' goes, in cells (0 = the cell under the camera). The editor "
        "loads at most 64 "
        "cells at a time and 256 in all.");
    ImGui::SameLine();
    if (ImGui::Button("Load around the view")) {
        std::string msg;
        cells_load_around_view(&msg);
        cellsUi_.status = msg;
    }
    at_track("cells:around");
    tip("Load, as editable entities, the cells whose area is within that many cells of the camera, nearest first.");
    ImGui::SameLine();
    if (ImGui::Button("Unload clean")) {
        const int n = cells_.unload_clean(world());
        cellsUi_.status = "Unloaded " + std::to_string(n) + " cell" + (n == 1 ? "" : "s") + " without changes.";
        cellsUi_.rowsKey = INT64_MIN;
    }
    at_track("cells:unloadclean");
    tip("Unload every loaded cell that has no unsaved changes. The ones with changes stay.");

    ImGui::BeginDisabled(!cells_.any_dirty());
    if (ImGui::Button("Save cells")) cells_save(false, 0, 0);
    at_track("cells:save", cells_.any_dirty());
    ImGui::EndDisabled();
    tip("Write each cell with unsaved changes to its own file (and the index when a cell was added or its height "
        "bounds grew). An "
        "entity whose position is now in another cell moves to that cell's file. Save in the toolbar does this too.");
    ImGui::SameLine();
    ImGui::Checkbox("Show the grid", &cellsUi_.overlay);
    at_track("cells:grid");
    tip("Draw the cells in the viewport: green loaded, orange with unsaved changes, grey not loaded.");
    ImGui::SameLine();
    if (ImGui::Button("Read the index again")) {
        cells_.refresh(world(), true);
        cellsUi_.rowsKey = INT64_MIN;
    }
    at_track("cells:reread");
    tip("Read the index file again (a tool such as world.split_cells changed it). Loaded cells stay loaded.");
    if (!cellsUi_.status.empty()) ImGui::TextWrapped("%s", cellsUi_.status.c_str());
    if (cells_.index_changed()) ImGui::TextColored(kStatusWarn, "The index has changes that are not written yet.");

    cells_refresh_rows();
    ImGui::Separator();
    if (ImGui::BeginTable("##cells", 4,
                          ImGuiTableFlags_RowBg | ImGuiTableFlags_ScrollY | ImGuiTableFlags_SizingStretchProp)) {
        ImGui::TableSetupColumn("Cell", ImGuiTableColumnFlags_WidthStretch, 0.18f);
        ImGui::TableSetupColumn("State", ImGuiTableColumnFlags_WidthStretch, 0.34f);
        ImGui::TableSetupColumn("Distance", ImGuiTableColumnFlags_WidthStretch, 0.18f);
        ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthStretch, 0.30f);
        ImGui::TableSetupScrollFreeze(0, 1);
        ImGui::TableHeadersRow();
        std::vector<CellRow> rows = cellsUi_.rows;  // the buttons below change the list
        for (const CellRow& r : rows) {
            ImGui::TableNextRow();
            ImGui::PushID(r.i);  // two ids, never i * k + j: that overflows for large coordinates and can collide
            ImGui::PushID(r.j);
            ImGui::TableSetColumnIndex(0);
            ImGui::Text("%d,%d", r.i, r.j);
            ImGui::TableSetColumnIndex(1);
            if (r.dirty)
                ImGui::TextColored(ImVec4(1.0f, 0.65f, 0.2f, 1.0f), "unsaved%s%s", r.inIndex ? "" : " (new)",
                                   r.rootGone ? " (root deleted: Save writes it empty)" : "");
            else if (r.loaded)
                ImGui::TextColored(ImVec4(0.45f, 0.9f, 0.55f, 1.0f), "loaded, %lld entities", (long long)r.entities);
            else
                ImGui::TextDisabled("not loaded");
            ImGui::TableSetColumnIndex(2);
            ImGui::Text("%.0f m", r.distance);
            ImGui::TableSetColumnIndex(3);
            if (!r.loaded) {
                if (ImGui::SmallButton("Load")) {
                    std::string err;
                    if (!cells_.load(world(), r.i, r.j, &err)) {
                        cellsUi_.status = err;
                        notify(err, 2);
                    } else if (!cells_.warnings().empty()) {
                        notify(cells_.warnings(), 1);
                    }
                    cellsUi_.rowsKey = INT64_MIN;
                }
                at_track(cell_widget("load", r));
                tip("Load this cell as editable entities under its root entity.");
            } else {
                if (ImGui::SmallButton("Unload")) {
                    std::string err;
                    if (r.dirty) {
                        cellsUi_.askI = r.i;
                        cellsUi_.askJ = r.j;
                        cellsUi_.ask = true;
                    } else if (!cells_.unload(world(), r.i, r.j, false, &err)) {
                        cellsUi_.status = err;
                    }
                    cellsUi_.rowsKey = INT64_MIN;
                }
                at_track(cell_widget("unload", r));
                tip("Remove this cell's entities from the scene. A cell with unsaved changes asks first.");
                ImGui::SameLine();
                ImGui::BeginDisabled(r.rootGone);  // its root entity no longer exists: there is nothing to select
                if (ImGui::SmallButton("Select")) {
                    select_id("cell_" + std::to_string(r.i) + "_" + std::to_string(r.j));
                    cellsUi_.focusI = r.i;
                    cellsUi_.focusJ = r.j;
                    cellsUi_.hasFocus = true;
                }
                ImGui::EndDisabled();
                at_track(cell_widget("select", r), !r.rootGone);
                if (r.rootGone) {
                    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled | ImGuiHoveredFlags_ForTooltip))
                        ImGui::SetTooltip(
                            "%s",
                            "The root entity of this cell was deleted, so there is nothing to select. Undo brings "
                            "it back; Save writes the cell empty.");
                } else {
                    tip("Select this cell's root entity: the Hierarchy and the Inspector show it, and the grid marks "
                        "it.");
                }
            }
            ImGui::PopID();
            ImGui::PopID();
        }
        ImGui::EndTable();
    }
    if (cellsUi_.ask) ImGui::OpenPopup("Unsaved cell##cells");
    if (ImGui::BeginPopupModal("Unsaved cell##cells", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::Text("Cell %d,%d has unsaved changes.", cellsUi_.askI, cellsUi_.askJ);
        if (ImGui::Button("Save and unload")) {
            if (cells_save(true, cellsUi_.askI, cellsUi_.askJ)) {
                std::string err;
                if (!cells_.unload(world(), cellsUi_.askI, cellsUi_.askJ, false, &err)) cellsUi_.status = err;
            }
            cellsUi_.ask = false;
            cellsUi_.rowsKey = INT64_MIN;
            ImGui::CloseCurrentPopup();
        }
        at_track("cells:ask_save");
        ImGui::SameLine();
        if (ImGui::Button("Discard changes and unload")) {
            cells_.unload(world(), cellsUi_.askI, cellsUi_.askJ, true, nullptr);
            cellsUi_.ask = false;
            cellsUi_.rowsKey = INT64_MIN;
            ImGui::CloseCurrentPopup();
        }
        at_track("cells:ask_discard");
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) {
            cellsUi_.ask = false;
            ImGui::CloseCurrentPopup();
        }
        at_track("cells:ask_cancel");
        ImGui::EndPopup();
    }
    ImGui::End();
}

// The cells' areas on the world's plane (XZ for 3D, XY for 2D) in the viewport, in the colours of the list. The areas are absolute: each
// corner goes through World::to_local, so the grid sits on the entities whatever the floating origin is.
void Editor::draw_cells_overlay(ImDrawList* dl, Renderer& r, const std::function<ImVec2(Vec3)>& project) {
    if (!showCells_ || !cellsUi_.overlay || play_ != PlayState::Edit || !cells_.has_index()) return;
    cells_refresh_rows();
    if (cellsUi_.rows.empty()) return;
    const WorldIndex& idx = cells_.index();
    const bool d3 = idx.dimension == WorldDimension::D3;
    const float tw = float(r.target_width()), th = float(r.target_height());
    Vec3 eye, forward;
    r.screen_ray(Vec2{tw * 0.5f, th * 0.5f}, eye, forward);
    const bool ortho = primary_is_ortho();
    std::int32_t selI = 0, selJ = 0;
    const bool hasSel = !selected().is_null() && cells_.cell_of_entity(world(), selected(), selI, selJ);
    for (const CellRow& row : cellsUi_.rows) {
        const double a0 = idx.originA + double(row.i) * idx.cellSize, b0 = idx.originB + double(row.j) * idx.cellSize;
        const double a1 = a0 + idx.cellSize, b1 = b0 + idx.cellSize;
        double y = 0;
        if (d3)
            if (const WorldCell* c = idx.find(row.i, row.j)) y = c->boundsMin.y;
        const double ca[4] = {a0, a1, a1, a0}, cb[4] = {b0, b0, b1, b1};
        ImVec2 p[4];
        bool front[4];
        for (int k = 0; k < 4; ++k) {
            const Vec3 local = world().to_local(d3 ? DVec3{ca[k], y, cb[k]} : DVec3{ca[k], cb[k], 0.0});
            front[k] = ortho || dot(Vec3{local.x - eye.x, local.y - eye.y, local.z - eye.z}, forward) > 0.05f;
            p[k] = project(local);
        }
        const bool focus = (hasSel && row.i == selI && row.j == selJ) ||
                           (cellsUi_.hasFocus && row.i == cellsUi_.focusI && row.j == cellsUi_.focusJ);
        const float thick = focus ? 3.0f : (row.loaded ? 2.0f : 1.0f);
        if ((front[0] && front[1] && front[2] && front[3]) && (row.loaded || row.dirty))
            dl->AddConvexPolyFilled(p, 4, state_color(row, 28));
        for (int k = 0; k < 4; ++k)
            if (front[k] && front[(k + 1) % 4])
                dl->AddLine(p[k], p[(k + 1) % 4], state_color(row, row.loaded ? 230 : 110), thick);
        if (front[0] && front[1] && front[2] && front[3] && (row.loaded || focus)) {
            const ImVec2 c((p[0].x + p[2].x) * 0.5f, (p[0].y + p[2].y) * 0.5f);
            char label[48];
            std::snprintf(label, sizeof label, "%d,%d%s", row.i, row.j, row.dirty ? " *" : "");
            dl->AddText(c, state_color(row, 255), label);
        }
    }
}

}  // namespace fa::editor
