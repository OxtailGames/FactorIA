// The Animation panel's 3D mode (View > Animation, "3D bone clips"): a factoria.anim3d/1 clip of a rigged model as a dopesheet, a viewport that shows
// the skinned model posed by the playhead (tools/common's software renderer, the one anim3d.preview draws with, so it needs no scene and runs headless),
// a bone list, and the bone tools: pick a bone in the view or the list, turn it with a rotation gizmo (the root also slides along an axis), drag an IK
// handle (hand or foot: target and pole; head: a look-at point) or mirror the pose left to right. Everything the panel writes is the anim3d.* /
// ik3d.key command an AI would call (Anim3DModel, anim3d_model.h), and each edit is ONE entry of the editor's undo stack (`{"$clip3d": ...}`); a
// gizmo or a handle being dragged only changes the pose the view shows, and letting go makes the command. The filmstrip (anim3d.preview with several
// angles) and the weight picture (skin3d.preview) are those commands too, shown in their own window.
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <format>
#include <fstream>
#include <sstream>

#include "editor_internal.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/scene/anim3d_gen.h"
#include "fa/scene/anim_clip.h"
#include "fa/scene/ik3d.h"
#include "fa/tooling/model_view.h"
#include "imgui_internal.h"
#include "imgui_stdlib.h"
#include "inspector_model.h"
#include "ui_backend.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

namespace {

const ImVec4 kBad(1.0f, 0.55f, 0.45f, 1);
const ImVec4 kWarn(1.0f, 0.8f, 0.4f, 1);

constexpr double kPi = 3.14159265358979323846;

std::string stem_of(const std::string& path) {   // "assets/models/hero.rig.glb" -> "hero"
    std::string name = stdfs::path(path).filename().generic_string();
    for (const char* ext : {".rig.glb", ".rig.json", ".anim.json", ".glb"})
        if (ends_with(name, ext)) return name.substr(0, name.size() - std::string(ext).size());
    const std::size_t dot = name.find('.');
    return dot == std::string::npos ? name : name.substr(0, dot);
}

// The rig document that bakes `rig` (hero.rig.glb <- hero.rig.json), "" when none is there.
std::string rig_document_of(const std::string& projectDir, const std::string& rig) {
    if (rig.empty()) return {};
    std::string doc;
    if (ends_with(rig, ".rig.json")) doc = rig;
    else if (ends_with(rig, ".rig.glb")) doc = rig.substr(0, rig.size() - 8) + ".rig.json";
    std::error_code ec;
    return !doc.empty() && stdfs::exists(stdfs::path(projectDir) / doc, ec) ? doc : std::string();
}

Anim3DEdit edit_of(const std::string& command, const CommandResult& r) {
    Anim3DEdit e;
    if (!r.ok) {
        e.ok = false;
        e.error = command + ": " + command_error_text(r.error);
        return e;
    }
    e.result = r.result;
    if (r.result.is_object() && r.result.contains("undo")) e.undo = r.result["undo"];
    return e;
}

bool put_texture(Anim3DUi::Texture& slot, std::vector<Anim3DUi::Dead>& graveyard, const Image& img, std::uint64_t frame) {
    Anim3DUi::Texture t;
    if (img.empty() || !ui::make_texture(img.width, img.height, img.rgba.data(), t.image, t.view)) return false;
    if (slot.image || slot.view) graveyard.push_back({slot.image, slot.view, frame});
    t.w = img.width;
    t.h = img.height;
    t.key = slot.key;
    slot = t;
    return true;
}

ImU32 axis_color(int axis, bool hot) {
    const int a = hot ? 255 : 190;
    return axis == 0 ? IM_COL32(235, 80, 80, a) : axis == 1 ? IM_COL32(90, 205, 100, a) : IM_COL32(90, 140, 245, a);
}

}  // namespace

// ----------------------------------------------------------------------------------------------------------- document --
Anim3DModel& Editor::anim3d_ensure_model() {
    Anim3DUi& u = anim3d_;
    if (u.model && u.model->projectDir() != projectDir_) {   // another project was opened
        anim3d_release_textures();
        const bool mode = u.mode3d;
        u = Anim3DUi{};
        u.mode3d = mode;
    }
    if (!u.model) {
        u.model = std::make_unique<Anim3DModel>(projectDir_, [this](const std::string& name, const Json& args) {
            CommandResult r = engine_->commands().call(name, args);
            if (!args.is_object() || !args.value("dryRun", false)) after_command(name, args, r);
            return r;
        });
    }
    return *u.model;
}

void Editor::anim3d_release_textures() {
    Anim3DUi& u = anim3d_;
    for (Anim3DUi::Texture* t : {&u.picture, &u.film.tex, &u.weights.tex})
        if (t->image || t->view) ui::destroy_texture(t->image, t->view);
    for (const Anim3DUi::Dead& d : u.graveyard) ui::destroy_texture(d.image, d.view);
    u.picture = Anim3DUi::Texture{};
    u.film.tex = Anim3DUi::Texture{};
    u.weights.tex = Anim3DUi::Texture{};
    u.graveyard.clear();
}

bool Editor::open_anim3d_clip(const std::string& rel, const std::string& rig) {
    if (!engine_) return false;
    Anim3DModel& m = anim3d_ensure_model();
    Anim3DUi& u = anim3d_;
    const bool same = m.is_open() && m.path() == rel;
    if (!same) {
        u.selection.clear();
        u.selectedEvent = -1;
        u.bone.clear();
        u.playhead = 0;
    }
    u.playing = false;
    u.live = false;
    u.drag = Anim3DUi::Drag::None;
    u.sheetDrag = Anim3DUi::SheetDrag::None;
    u.fitNext = true;
    u.picture.key = ~0ULL;
    u.status.clear();
    const bool ok = m.open(rel, rig);
    if (ok && !m.has_rig() && !u.lastRig.empty()) m.set_rig(u.lastRig);   // a clip that names no rig is posed with the last one
    if (ok && m.has_rig()) u.lastRig = m.rig_path();
    u.openError = ok ? std::string() : m.error();
    u.mode3d = true;
    showAnimation_ = true;
    u.floatNext = true;
    focus_window("Animation");
    if (!ok) notify("Cannot open " + rel + " in the Animation panel: " + m.error(), 2);
    return ok;
}

void Editor::anim3d_commit(const Anim3DEdit& e) {
    Anim3DUi& u = anim3d_;
    if (!e.ok) {
        u.status = e.error;
        notify(e.error, 2);
        return;
    }
    ++u.commits;
    u.status.clear();
    if (e.undo.is_object() && e.undo.contains("args")) {
        undo_.push_back(Json::object({{"$clip3d", e.undo["args"]}}));
        if (undo_.size() > 100) undo_.erase(undo_.begin());
        redo_.clear();
        lastEditKey_.clear();
    }
    project_files_changed();
}

void Editor::anim3d_apply_undo(const Json& entry, bool forward) {
    Anim3DUi& u = anim3d_;
    const Json& args = entry["$clip3d"];
    const CommandResult r = engine_->commands().call("anim3d.restore", args);
    if (!r.ok) {
        notify("Could not " + std::string(forward ? "redo" : "undo") + " the clip edit: " + command_error_text(r.error), 2);
        return;
    }
    after_command("anim3d.restore", args, r);
    if (r.result.is_object() && r.result.contains("undo") && r.result["undo"].contains("args"))
        (forward ? undo_ : redo_).push_back(Json::object({{"$clip3d", r.result["undo"]["args"]}}));
    project_files_changed();
    const std::string path = args.value("path", std::string());
    Anim3DModel& m = anim3d_ensure_model();
    u.live = false;
    u.drag = Anim3DUi::Drag::None;
    if (m.is_open() && m.path() == path) {
        if (!m.reload()) {   // the undo removed the clip (a generated one): nothing left to show
            m.close();
            u.selection.clear();
            u.status = "The clip file is gone (undone). Redo brings it back.";
        }
    } else if (!path.empty() && args.contains("clip") && !args["clip"].is_null()) {
        open_anim3d_clip(path);
    }
}

double Editor::anim3d_snap(double t) const {
    const Anim3DUi& u = anim3d_;
    double dur = u.model && u.model->clip() ? double(u.model->clip()->duration) : 0.0;
    t = u.snap && u.fps > 0 ? std::round(t * u.fps) / u.fps : std::round(t * 1000.0) / 1000.0;
    return std::clamp(t, 0.0, std::max(dur, 0.0));
}

Vec2 Editor::anim3d_time_point(double t) const {
    const Anim3DUi& u = anim3d_;
    return Vec2{u.timeX0 + 12.0f + float((t - u.viewStart) * double(u.pps)), u.rulerY + 11.0f};
}

void Editor::anim3d_scan_lists() {
    Anim3DUi& u = anim3d_;
    u.clipList.clear();
    u.rigList.clear();
    if (engine_) {
        const CommandResult r = engine_->commands().call("anim3d.info", Json::object());
        if (r.ok && r.result.contains("clips") && r.result["clips"].is_array())
            for (const Json& c : r.result["clips"])
                if (c.is_string()) u.clipList.push_back(c.get<std::string>());
    }
    std::error_code ec;
    int seen = 0;
    for (stdfs::recursive_directory_iterator it(projectDir_, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().generic_string();
        if (it->is_directory(ec)) {
            if (!name.empty() && (name[0] == '.' || name == "build" || name == "node_modules" || name == "dist")) it.disable_recursion_pending();
            continue;
        }
        if (++seen > 40000) break;
        if (ends_with(name, ".rig.glb") || ends_with(name, ".rig.json")) {
            const std::string rel = stdfs::relative(it->path(), projectDir_, ec).generic_string();
            // A .rig.json whose .rig.glb is next to it is listed once, by the baked one.
            if (ends_with(rel, ".rig.json") && stdfs::exists(stdfs::path(projectDir_) / (rel.substr(0, rel.size() - 9) + ".rig.glb"), ec)) continue;
            u.rigList.push_back(rel);
        }
    }
    std::sort(u.clipList.begin(), u.clipList.end());
    std::sort(u.rigList.begin(), u.rigList.end());
}

// ------------------------------------------------------------------------------------------------------------ the panel --
bool Editor::draw_animation_mode_row() {
    Anim3DUi& u = anim3d_;
    const bool was = u.mode3d;
    if (ImGui::RadioButton("2D clips##a3m2", !u.mode3d)) u.mode3d = false;
    at_track("a3:mode2d");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("The clips of the selected entity's Animator (sprites, transforms, any field).");
    ImGui::SameLine();
    if (ImGui::RadioButton("3D bone clips##a3m3", u.mode3d)) u.mode3d = true;
    at_track("a3:mode3d");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("The bone clips (*.anim.json, factoria.anim3d/1) of a rigged model: posed in a 3D view, with bone tools and IK handles.");
    if (u.mode3d && !was) u.floatNext = true;
    return u.mode3d;
}

void Editor::anim3d_prepare_window() {
    Anim3DUi& u = anim3d_;
    if (!u.floatNext || !u.mode3d) return;
    u.floatNext = false;
    ImGuiWindow* w = ImGui::FindWindowByName("Animation");
    if (w && w->DockId == 0 && w->Size.y >= 520.0f) return;   // already floating and large
    const ImVec2 size = fit_work_area(ImVec2(1180, 760));
    ImGui::SetNextWindowDockID(0, ImGuiCond_Always);
    ImGui::SetNextWindowPos(ImVec2(ImGui::GetMainViewport()->WorkPos.x + 40, ImGui::GetMainViewport()->WorkPos.y + 20), ImGuiCond_Always);
    ImGui::SetNextWindowSize(size, ImGuiCond_Always);
}

void Editor::draw_animation_panel_3d() {
    Anim3DUi& u = anim3d_;
    Anim3DModel& m = anim3d_ensure_model();
    for (std::size_t i = 0; i < u.graveyard.size();) {   // textures replaced a few frames ago can go now
        if (u.graveyard[i].frame + 4 < uiFrame_) {
            ui::destroy_texture(u.graveyard[i].image, u.graveyard[i].view);
            u.graveyard.erase(u.graveyard.begin() + long(i));
        } else {
            ++i;
        }
    }
    if (play_ != PlayState::Edit) {
        u.playing = false;
        ImGui::TextDisabled("The game is running. Stop it to edit clips (a clip file is not part of the running scene).");
        return;
    }
    if (m.is_open() && uiFrame_ - u.lastPoll >= 20 && u.drag == Anim3DUi::Drag::None && u.sheetDrag == Anim3DUi::SheetDrag::None) {
        u.lastPoll = uiFrame_;
        if (m.poll()) u.status = "The file changed on disk and was read again.";
    }
    if (m.is_open() && m.revision() != u.selRevision) {   // keys that are no longer in the clip leave the selection
        u.selRevision = m.revision();
        for (auto it = u.selection.begin(); it != u.selection.end();) it = m.key_at(*it) ? std::next(it) : u.selection.erase(it);
        if (m.clip() && u.selectedEvent >= int(m.clip()->events.size())) u.selectedEvent = -1;
        if (!u.bone.empty() && m.rig() && m.node_of(u.bone) < 0) u.bone.clear();
    }

    anim3d_toolbar();
    if (!m.is_open() || !m.clip()) {
        ImGui::Spacing();
        ImGui::TextDisabled("Choose a 3D clip (anim/*.anim.json) in the list above, or double click one in the Project panel.");
        ImGui::TextDisabled("anim3d.generate writes a walk, run or idle clip for a baked rig (rig.bake); New clip starts an empty one.");
        if (!u.openError.empty()) ImGui::TextColored(kBad, "%s", u.openError.c_str());
        if (m.is_open() && !m.error().empty()) ImGui::TextColored(kBad, "%s", m.error().c_str());
        return;
    }

    // Playback: the playhead moves with the UI clock (nothing runs in the engine).
    const double dur = double(m.clip()->duration);
    if (u.playing) {
        u.playhead += double(ImGui::GetIO().DeltaTime) * double(u.speed);
        if (dur <= 0) {
            u.playing = false;
        } else if (u.playhead >= dur) {
            if (u.loopPreview) u.playhead = std::fmod(u.playhead, dur);
            else u.playhead = dur, u.playing = false;
        }
    }
    u.playhead = std::clamp(u.playhead, 0.0, std::max(dur, 0.0));

    if (ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows) && !ImGui::GetIO().WantTextInput && u.drag == Anim3DUi::Drag::None) {
        if (ImGui::IsKeyPressed(ImGuiKey_Space, false)) u.playing = !u.playing;
        if ((ImGui::IsKeyPressed(ImGuiKey_Delete, false) || ImGui::IsKeyPressed(ImGuiKey_Backspace, false)) && !u.selection.empty())
            anim3d_commit(m.remove_keys(u.selection)), u.selection.clear();
    }

    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const float spacing = ImGui::GetStyle().ItemSpacing.y;
    const float sheetH = std::clamp(avail.y * 0.36f, 130.0f, 280.0f);
    const float topH = std::max(160.0f, avail.y - sheetH - spacing);
    const float full = avail.x, itemX = ImGui::GetStyle().ItemSpacing.x;
    const float leftW = std::clamp(full * 0.17f, 150.0f, 230.0f), rightW = std::clamp(full * 0.26f, 250.0f, 340.0f);
    ImGui::BeginChild("##a3_bones", ImVec2(leftW, topH), ImGuiChildFlags_Borders);
    anim3d_bone_list();
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##a3_view", ImVec2(std::max(160.0f, full - leftW - rightW - 2 * itemX), topH), ImGuiChildFlags_Borders);
    anim3d_viewport();
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##a3_inspector", ImVec2(0, topH), ImGuiChildFlags_Borders);
    anim3d_inspector();
    ImGui::EndChild();
    ImGui::BeginChild("##a3_sheet", ImVec2(0, 0), ImGuiChildFlags_Borders);
    anim3d_dopesheet();
    ImGui::EndChild();
}

// ----------------------------------------------------------------------------------------------------------------- toolbar --
void Editor::anim3d_toolbar() {
    Anim3DUi& u = anim3d_;
    Anim3DModel& m = *u.model;
    ImGui::SameLine(0, 18);
    ImGui::TextUnformatted("Clip");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(230);
    if (ImGui::BeginCombo("##a3_clip", m.is_open() ? m.path().c_str() : "(none open)")) {
        if (ImGui::IsWindowAppearing()) anim3d_scan_lists();
        for (const std::string& c : u.clipList) {
            if (ImGui::Selectable(c.c_str(), m.is_open() && c == m.path())) open_anim3d_clip(c);
            at_track("a3:clip:" + c);
        }
        if (u.clipList.empty()) ImGui::TextDisabled("No 3D clips yet: New clip, or anim3d.generate.");
        ImGui::EndCombo();
    }
    at_track("a3:clip");
    ImGui::SameLine();
    ImGui::TextUnformatted("Rig");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(230);
    if (ImGui::BeginCombo("##a3_rig", m.has_rig() ? m.rig_path().c_str() : "(no rig)")) {
        if (ImGui::IsWindowAppearing()) anim3d_scan_lists();
        for (const std::string& r : u.rigList) {
            if (ImGui::Selectable(r.c_str(), r == m.rig_path()) && m.is_open()) {
                m.set_rig(r);
                if (m.has_rig()) u.lastRig = r;
                u.picture.key = ~0ULL;
                u.frameRig.clear();
            }
            at_track("a3:rig:" + r);
        }
        if (u.rigList.empty()) ImGui::TextDisabled("No baked rig (*.rig.glb): rig.create then rig.bake make one.");
        ImGui::EndCombo();
    }
    at_track("a3:rig");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("The baked rig that poses the clip. A clip made for another rig keeps its bone names; anim3d.retarget carries it over.");
    ImGui::SameLine();
    if (ImGui::Button("New clip")) ImGui::OpenPopup("##a3_new");
    at_track("a3:newclip");
    if (ImGui::BeginPopup("##a3_new")) {
        ImGui::SetNextItemWidth(160);
        ImGui::InputText("name", &u.newClipName);
        at_track("a3:newclip:name");
        ImGui::SetNextItemWidth(100);
        ImGui::DragFloat("seconds", &u.newClipDuration, 0.05f, 0.1f, 60.0f, "%.2f");
        const bool valid = !u.newClipName.empty() && u.newClipName.find('/') == std::string::npos && u.newClipName.find('\\') == std::string::npos;
        ImGui::BeginDisabled(!valid);
        if (ImGui::Button("Create")) {
            const std::string path = "anim/" + u.newClipName + ".anim.json";
            Json a = Json::object({{"path", path}, {"duration", double(u.newClipDuration)}, {"loop", true}});
            const std::string rig = m.rig_path().empty() ? u.lastRig : m.rig_path();
            if (!rig.empty()) a["rig"] = rig;
            const CommandResult r = engine_->commands().call("anim3d.create", a);
            after_command("anim3d.create", a, r);
            const Anim3DEdit e = edit_of("anim3d.create", r);
            anim3d_commit(e);
            if (e.ok) open_anim3d_clip(path, rig);
            ImGui::CloseCurrentPopup();
        }
        at_track("a3:newclip:create", valid);
        ImGui::EndDisabled();
        if (!valid) ImGui::TextDisabled("A clip name is a plain word without '/': it is the file name.");
        ImGui::EndPopup();
    }
    if (!m.is_open() || !m.clip()) return;

    // The transport (on a line of its own when the window is not wide enough for it after the chooser).
    if (ImGui::GetContentRegionAvail().x > 560) ImGui::SameLine(0, 18);
    if (ImGui::Button(u.playing ? "Pause" : "Play")) {
        u.playing = !u.playing;
        if (u.playing && !u.loopPreview && u.playhead >= double(m.clip()->duration) - 1e-6) u.playhead = 0;
    }
    at_track("a3:play");
    ImGui::SameLine();
    ImGui::Checkbox("Loop", &u.loopPreview);
    at_track("a3:loop");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(70);
    ImGui::SliderFloat("##a3_speed", &u.speed, 0.1f, 2.0f, "%.1fx");
    ImGui::SameLine();
    ImGui::Text("%.2f / %.2f s", u.playhead, double(m.clip()->duration));
    ImGui::SameLine();
    ImGui::Checkbox("Snap", &u.snap);
    at_track("a3:snap");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Keys and the playhead land on whole frames of the grid (%d per second).", u.fps);
    if (u.snap) {
        ImGui::SameLine();
        ImGui::SetNextItemWidth(60);
        ImGui::InputInt("fps", &u.fps, 0, 0);
        u.fps = std::clamp(u.fps, 1, 240);
    }

    // The pose tools.
    const bool hasBone = !u.bone.empty() && m.node_of(u.bone) >= 0;
    ImGui::BeginDisabled(!hasBone || !m.has_rig());
    if (ImGui::Button("Key rotation")) {
        const Anim3DEdit e = m.key_sampled(u.bone, 0, anim3d_snap(u.playhead));
        anim3d_commit(e);
        if (e.ok) u.selection = {Key3D{u.bone, 0, key3d_ms(anim3d_snap(u.playhead))}};
    }
    at_track("a3:key", hasBone && m.has_rig());
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Keys the picked bone's rotation at the playhead as the clip gives it now (a key that pins the value).");
    ImGui::SameLine();
    if (ImGui::Button("Key position")) {
        const Anim3DEdit e = m.key_sampled(u.bone, 1, anim3d_snap(u.playhead));
        anim3d_commit(e);
        if (e.ok) u.selection = {Key3D{u.bone, 1, key3d_ms(anim3d_snap(u.playhead))}};
    }
    at_track("a3:keypos", hasBone && m.has_rig());
    ImGui::EndDisabled();
    ImGui::SameLine(0, 18);
    ImGui::BeginDisabled(!m.has_rig());
    ImGui::SetNextItemWidth(80);
    static const char* kFrom[] = {"swap", "left", "right"};
    ImGui::Combo("##a3_mirrorfrom", &u.mirrorFrom, "swap\0left to right\0right to left\0");
    at_track("a3:mirrorfrom");
    ImGui::SameLine();
    if (ImGui::Button("Mirror pose")) {
        const double t = anim3d_snap(u.playhead);
        const double to = u.mirrorOther ? anim3d_snap(double(u.mirrorTo)) : t;
        const Anim3DEdit e = m.mirror(t, to, kFrom[std::clamp(u.mirrorFrom, 0, 2)]);
        anim3d_commit(e);
    }
    at_track("a3:mirror", m.has_rig());
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("Mirrors the pose at the playhead left to right (the bones the clip animates, by their canonical names: thigh_l <-> thigh_r) and keys it.\nswap exchanges both sides; left to right copies the left side onto the right.");
    ImGui::SameLine();
    ImGui::Checkbox("to", &u.mirrorOther);
    at_track("a3:mirrorother");
    if (u.mirrorOther) {
        ImGui::SameLine();
        ImGui::SetNextItemWidth(60);
        ImGui::DragFloat("##a3_mirrorto", &u.mirrorTo, 0.01f, 0.0f, std::max(0.0f, m.clip()->duration), "%.2f s");
    } else if (ImGui::IsItemHovered()) {
        ImGui::SetTooltip("Off: the mirrored pose is keyed at the playhead. On: at another time (a stride's second half).");
    }
    ImGui::SameLine(0, 18);
    if (ImGui::Button("Filmstrip")) anim3d_show_filmstrip();
    at_track("a3:filmstrip", m.has_rig());
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("anim3d.preview with several angles: the clip posed at six times, seen from the right, the front and the left.");
    ImGui::SameLine();
    const bool hasDoc = !rig_document_of(projectDir_, m.rig_path()).empty();
    ImGui::BeginDisabled(!hasDoc);
    if (ImGui::Button("Weights")) anim3d_show_weights();
    at_track("a3:weights", hasDoc && m.has_rig());
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip(hasDoc ? "skin3d.preview: the weights of the picked bone as a heat map (all bones when none is picked), from three sides."
                                 : "The weights come from the rig document (name.rig.json) that bakes the rig; there is none next to it.");
    ImGui::EndDisabled();
    if (!u.status.empty()) {
        ImGui::SameLine(0, 18);
        ImGui::TextColored(kWarn, "%s", u.status.c_str());
    }
}

// ------------------------------------------------------------------------------------------------------------- bone list --
void Editor::anim3d_bone_list() {
    Anim3DUi& u = anim3d_;
    Anim3DModel& m = *u.model;
    ImGui::TextDisabled("Bones");
    if (!m.has_rig()) {
        ImGui::TextWrapped("%s", m.error().empty() ? "Choose a rig." : m.error().c_str());
        return;
    }
    ImGui::BeginChild("##a3_boneRows", ImVec2(0, 0));
    for (const Anim3DBoneRow& r : m.rows()) {
        ImGui::PushID(r.node);
        ImGui::Dummy(ImVec2(float(r.depth) * 10.0f, 0));
        ImGui::SameLine(0, 0);
        const std::string label = r.keys > 0 ? std::format("{}  ({})", r.name, r.keys) : r.name;
        if (ImGui::Selectable(label.c_str(), u.bone == r.name)) {
            u.bone = r.name;
            if (u.onlyBone) u.selection.clear();
        }
        at_track("a3:bone:" + r.name);
        ImGui::PopID();
    }
    ImGui::EndChild();
}

// ----------------------------------------------------------------------------------------------------------------- viewport --
namespace {

struct Scr {
    double x = 0, y = 0;
    bool ok = false;
};

struct HandleHit {
    enum Kind { None, Ring, Arrow, Target, Pole, Look } kind = None;
    int axis = 0;
};

// The centre and the radius of the sphere that holds the bind mesh (or, with no mesh, the bones).
void frame_of(const Anim3DRigModel& rig, Vec3& center, double& radius) {
    const MeshData& b = rig.bind;
    Vec3 lo = b.bmin, hi = b.bmax;
    if (b.positions.size() < 3) {
        bool first = true;
        for (int n : rig.rig.bones) {
            const Vec3 h = rig.rig.rest_head(n);
            lo = first ? h : min(lo, h);
            hi = first ? h : max(hi, h);
            first = false;
        }
    }
    center = (lo + hi) * 0.5f;
    radius = 0.05;
    if (b.positions.size() >= 3) {
        for (std::size_t v = 0; v + 2 < b.positions.size(); v += 3) {
            const double dx = b.positions[v] - center.x, dy = b.positions[v + 1] - center.y, dz = b.positions[v + 2] - center.z;
            radius = std::max(radius, std::sqrt(dx * dx + dy * dy + dz * dz));
        }
    } else {
        radius = std::max(0.5, double(length(hi - lo)) * 0.6);
    }
}

}  // namespace

void Editor::anim3d_viewport() {
    Anim3DUi& u = anim3d_;
    Anim3DModel& m = *u.model;
    const std::shared_ptr<const Anim3DClip> clip = m.clip();
    const Anim3DRigModel* rig = m.rig();
    const bool canEdit = play_ == PlayState::Edit && clip != nullptr;

    if (ImGui::RadioButton("Rotate", u.tool == Bone3DTool::Rotate)) u.tool = Bone3DTool::Rotate;
    at_track("a3:tool:rotate");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Three rings turn the picked bone about the axes of its parent's frame; the root also has arrows that slide it.\nLetting go keys the bone at the playhead (one undo step).");
    ImGui::SameLine();
    if (ImGui::RadioButton("IK", u.tool == Bone3DTool::Ik)) u.tool = Bone3DTool::Ik;
    at_track("a3:tool:ik");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("On a hand or a foot (a bone with two bones above it): drag its target, and the pole that says where the elbow or knee points.\nOn the head or neck: drag the point it looks at. Letting go keys the whole chain (ik3d.key).");
    ImGui::SameLine();
    ImGui::Checkbox("Bones", &u.showBones);
    at_track("a3:showbones");
    ImGui::SameLine();
    ImGui::Checkbox("Mesh", &u.showMesh);
    at_track("a3:showmesh");
    ImGui::SameLine();
    ImGui::Checkbox("Ortho", &u.orthographic);
    ImGui::SameLine();
    if (ImGui::Button("Reset view")) {
        u.yaw = -25;
        u.pitch = 12;
        u.zoom = 1;
        u.frameRig.clear();
    }
    at_track("a3:resetview");
    if (!rig || !clip) {
        ImGui::TextColored(kWarn, "%s", m.error().empty() ? "Choose a rig to see the model." : m.error().c_str());
        ImGui::TextDisabled("The dopesheet works without one; the view and the bone tools need the baked rig (*.rig.glb) the clip is for.");
        return;
    }
    if (u.frameRig != m.rig_path()) {
        frame_of(*rig, u.frameCenter, u.frameRadius);
        u.frameRig = m.rig_path();
    }

    // ---- the picture
    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const int w = std::clamp(int(avail.x), 64, 1400), h = std::clamp(int(avail.y), 64, 1000);
    const ImVec2 p0 = ImGui::GetCursorScreenPos();
    const Pose pose = u.live ? u.livePose : m.pose_at(u.playhead);
    ModelViewOptions o;
    o.width = w;
    o.height = h;
    o.yawDeg = double(u.yaw);
    o.pitchDeg = double(u.pitch);
    o.orthographic = u.orthographic;
    o.shaded = true;
    o.ground = true;
    o.zoom = double(u.zoom);
    o.center = u.frameCenter;
    o.radius = u.frameRadius;
    o.supersample = (u.playing || u.drag != Anim3DUi::Drag::None) ? 1 : 2;
    std::uint64_t key = 1469598103934665603ULL;
    auto mix = [&](std::uint64_t v) { key = (key ^ (v + 0x9e3779b97f4a7c15ULL + (key << 6) + (key >> 2))) * 0x100000001b3ULL; };
    mix(m.revision());
    mix(std::uint64_t(key3d_ms(u.playhead)));
    mix(u.live ? u.liveSerial + 1 : 0);
    mix(std::uint64_t(std::llround(double(u.yaw) * 10)));
    mix(std::uint64_t(std::llround(double(u.pitch) * 10)));
    mix(std::uint64_t(std::llround(double(u.zoom) * 100)));
    mix(std::uint64_t(w) * 4096 + std::uint64_t(h));
    mix(std::uint64_t(u.showMesh) | std::uint64_t(u.orthographic) << 1 | std::uint64_t(o.supersample) << 2);
    if (key != u.picture.key) {
        MeshData mesh;
        std::vector<ModelViewItem> items;
        if (u.showMesh) {
            mesh = m.skin(pose);
            ModelViewItem item;
            item.mesh = &mesh;
            items.push_back(item);
        }
        const Image pic = render_model_view(items, o);
        if (put_texture(u.picture, u.graveyard, pic, uiFrame_)) {
            u.picture.key = key;
            ++u.renderCount;
        }
    }
    u.cam = model_view_camera(o, u.frameCenter, u.frameRadius);
    u.camValid = true;
    u.viewX0 = p0.x;
    u.viewY0 = p0.y;
    u.viewW = float(w);
    u.viewH = float(h);
    ImGui::InvisibleButton("##a3_canvas", ImVec2(float(w), float(h)), ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight);
    at_track("a3:view");
    const bool hovered = ImGui::IsItemHovered();
    ImDrawList* dl = ImGui::GetWindowDrawList();
    dl->PushClipRect(p0, ImVec2(p0.x + float(w), p0.y + float(h)), true);
    if (u.picture.view) dl->AddImage(ImTextureRef(ImTextureID(ui::texture_from_view(u.picture.view, true))), p0, ImVec2(p0.x + float(w), p0.y + float(h)));

    // ---- where the bones and the handles are on the picture
    auto P = [&](Vec3 p) {
        Scr s;
        double depth = 0;
        s.ok = u.cam.project(p, s.x, s.y, depth);
        return s;
    };
    auto S = [&](const Scr& s) { return ImVec2(p0.x + float(s.x), p0.y + float(s.y)); };
    const std::vector<Anim3DBoneRow> rows = m.rows();
    const PoseFrame frame = pose_frame(*rig->skeleton, pose);
    const Rig3D& r3 = rig->rig;
    std::vector<Scr> heads(rows.size()), tails(rows.size());
    for (std::size_t i = 0; i < rows.size(); ++i) {
        const int n = rows[i].node;
        heads[i] = P(frame.pos[std::size_t(n)]);
        Vec3 tail;
        bool found = false;
        for (int c : r3.bones)
            if (r3.node(c).parent == n) {
                tail = frame.pos[std::size_t(c)];
                found = true;
                break;
            }
        if (!found) {
            const float len = r3.length[std::size_t(n)] > 0 ? r3.length[std::size_t(n)] : 0.1f;
            Vec3 axis = r3.axis[std::size_t(n)];
            if (length_sq(axis) < 1e-8f) axis = {0, 1, 0};
            tail = frame.pos[std::size_t(n)] + frame.rot[std::size_t(n)].rotate(axis) * len;
        }
        tails[i] = P(tail);
    }
    auto pick_bone = [&](double mx, double my) -> int {
        int best = -1;
        double bestD = 10.0;
        for (std::size_t i = 0; i < rows.size(); ++i) {
            if (!heads[i].ok) continue;
            const double d = std::hypot(heads[i].x - mx, heads[i].y - my);
            if (d <= bestD) best = int(i), bestD = d;   // parents come first, so a child wins a tie
        }
        if (best >= 0) return best;
        bestD = 7.0;
        for (std::size_t i = 0; i < rows.size(); ++i) {
            if (!heads[i].ok || !tails[i].ok) continue;
            const double d = segment_distance(mx, my, heads[i].x, heads[i].y, tails[i].x, tails[i].y);
            if (d <= bestD) best = int(i), bestD = d;
        }
        return best;
    };

    const bool rotateTool = u.tool == Bone3DTool::Rotate;
    const int node = canEdit && m.rig() ? m.node_of(u.bone) : -1;
    const double ringR = std::max(0.08, 0.16 * u.frameRadius), arrowLen = 0.32 * u.frameRadius;
    std::array<std::vector<Scr>, 3> ring;
    std::array<Scr, 3> arrowTip;
    std::array<Vec3, 3> axisW{};
    bool showArrows = false;
    Scr headS, targetS, poleS, midS, lookS;
    Vec3 headW{};
    Anim3DLimb limb;
    bool ikOk = false, lookOk = false;
    if (node >= 0) {
        headW = frame.pos[std::size_t(node)];
        headS = P(headW);
        if (rotateTool) {
            for (int a = 0; a < 3; ++a) {
                axisW[std::size_t(a)] = gizmo_axis_world(*rig, pose, node, a);
                const int N = 48;
                for (int k = 0; k <= N; ++k) ring[std::size_t(a)].push_back(P(ring_point(headW, axisW[std::size_t(a)], ringR, 2.0 * kPi * double(k) / double(N))));
                arrowTip[std::size_t(a)] = P(headW + axisW[std::size_t(a)] * float(arrowLen));
            }
            showArrows = !r3.is_bone(r3.node(node).parent) || m.track_index(u.bone, 1) >= 0;
        } else {
            const long long ms = key3d_ms(u.playhead);
            limb = limb_of(*rig, node);
            if (limb.valid()) {
                if (u.ikPoleBone != u.bone || key3d_ms(u.ikPoleTime) != ms) {
                    u.ikPole = default_pole(*rig, pose, limb);
                    u.ikPoleBone = u.bone;
                    u.ikPoleTime = u.playhead;
                }
                ikOk = true;
                targetS = P(u.drag == Anim3DUi::Drag::IkTarget ? u.dragPoint : headW);
                poleS = P(u.drag == Anim3DUi::Drag::IkPole ? u.dragPoint : u.ikPole);
                midS = P(frame.pos[std::size_t(limb.mid)]);
            } else if (aims_like_a_head(*rig, node)) {
                if (u.lookBone != u.bone || key3d_ms(u.lookTime) != ms) {
                    u.lookPoint = headW + Vec3{0, 0, 1} * float(0.5 * u.frameRadius);
                    u.lookBone = u.bone;
                    u.lookTime = u.playhead;
                }
                lookOk = true;
                lookS = P(u.drag == Anim3DUi::Drag::LookTarget ? u.dragPoint : u.lookPoint);
            }
        }
    }
    auto hit_handle = [&](double mx, double my) -> HandleHit {
        HandleHit hit;
        if (node < 0) return hit;
        if (rotateTool) {
            if (showArrows) {
                double best = 9.0;
                for (int a = 0; a < 3; ++a) {
                    if (!arrowTip[std::size_t(a)].ok || !headS.ok) continue;
                    const double d = std::min(std::hypot(arrowTip[std::size_t(a)].x - mx, arrowTip[std::size_t(a)].y - my),
                                              segment_distance(mx, my, headS.x, headS.y, arrowTip[std::size_t(a)].x, arrowTip[std::size_t(a)].y));
                    if (d < best) best = d, hit = {HandleHit::Arrow, a};
                }
                if (hit.kind != HandleHit::None) return hit;
            }
            double best = 7.0;
            for (int a = 0; a < 3; ++a) {
                const auto& pts = ring[std::size_t(a)];
                for (std::size_t k = 0; k + 1 < pts.size(); ++k) {
                    if (!pts[k].ok || !pts[k + 1].ok) continue;
                    const double d = segment_distance(mx, my, pts[k].x, pts[k].y, pts[k + 1].x, pts[k + 1].y);
                    if (d < best) best = d, hit = {HandleHit::Ring, a};
                }
            }
            return hit;
        }
        auto near = [&](const Scr& s) { return s.ok && std::hypot(s.x - mx, s.y - my) < 13.0; };
        if (ikOk && near(poleS)) return {HandleHit::Pole, 0};
        if (ikOk && near(targetS)) return {HandleHit::Target, 0};
        if (lookOk && near(lookS)) return {HandleHit::Look, 0};
        return hit;
    };

    // ---- the mouse
    const ImGuiIO& io = ImGui::GetIO();
    const double mx = double(io.MousePos.x - p0.x), my = double(io.MousePos.y - p0.y);
    int hoverBone = -1;
    if (hovered && u.drag == Anim3DUi::Drag::None) hoverBone = pick_bone(mx, my);
    if (hovered && io.MouseWheel != 0.0f) u.zoom = std::clamp(u.zoom * std::pow(1.1f, io.MouseWheel), 0.2f, 8.0f);
    using D = Anim3DUi::Drag;
    auto begin_orbit = [&](int button) {
        u.drag = D::Orbit;
        u.dragButton = button;
        u.dragMoved = false;
        u.pressX = io.MousePos.x;
        u.pressY = io.MousePos.y;
    };
    auto begin_handle = [&](const HandleHit& hit) {
        u.dragButton = 0;
        u.dragMoved = false;
        u.pressX = io.MousePos.x;
        u.pressY = io.MousePos.y;
        u.playhead = anim3d_snap(u.playhead);   // the result is keyed on the grid: show the pose there
        u.dragTime = u.playhead;
        u.dragBase = m.pose_at(u.playhead);
        const Pose& base = u.dragBase;
        const Vec3 head = bone_head(*rig, base, node);
        u.dragAxis = hit.axis;
        if (hit.kind == HandleHit::Ring) {
            u.drag = D::Ring;
            double a = 0;
            if (!ring_angle(u.cam, mx, my, head, gizmo_axis_world(*rig, base, node, hit.axis), a)) a = 0;
            u.dragAngle = a;
            u.dragTotal = 0;
        } else if (hit.kind == HandleHit::Arrow) {
            u.drag = D::Arrow;
            double s = 0;
            if (!line_param(u.cam, mx, my, head, gizmo_axis_world(*rig, base, node, hit.axis), s)) s = 0;
            u.dragStartS = s;
            u.dragTotal = 0;
        } else {
            const long long ms = key3d_ms(u.playhead);
            if (limb.valid() && (u.ikPoleBone != u.bone || key3d_ms(u.ikPoleTime) != ms)) {
                u.ikPole = default_pole(*rig, base, limb);
                u.ikPoleBone = u.bone;
                u.ikPoleTime = u.playhead;
            }
            u.dragEnd = head;
            Vec3 pt = hit.kind == HandleHit::Target ? head : hit.kind == HandleHit::Pole ? u.ikPole : u.lookPoint;
            u.drag = hit.kind == HandleHit::Target ? D::IkTarget : hit.kind == HandleHit::Pole ? D::IkPole : D::LookTarget;
            Vec3 hp;
            u.dragOffset = plane_hit(u.cam, mx, my, pt, u.cam.forward, hp) ? pt - hp : Vec3{};
            u.dragPoint = pt;
            u.liveSolver = Json();
        }
    };
    if (canEdit && u.drag == D::None) {
        if (ImGui::IsItemClicked(ImGuiMouseButton_Right)) {
            begin_orbit(1);
        } else if (ImGui::IsItemClicked(ImGuiMouseButton_Left)) {
            const HandleHit hit = hit_handle(mx, my);
            if (hit.kind == HandleHit::None) begin_orbit(0);
            else begin_handle(hit);
            u.playing = false;
        }
    }
    if (u.drag != D::None) {
        const int b = u.dragButton;
        const bool cancel = u.drag != D::Orbit && ImGui::IsKeyPressed(ImGuiKey_Escape, false);
        if (!canEdit || cancel) {
            u.drag = D::None;
            u.live = false;
            ++u.liveSerial;
        } else if (io.MouseDown[b]) {
            if (!u.dragMoved && std::hypot(io.MousePos.x - u.pressX, io.MousePos.y - u.pressY) > 4.0f) u.dragMoved = u.drag == D::Orbit;
            if (u.drag == D::Orbit) {
                u.yaw -= io.MouseDelta.x * 0.5f;
                u.pitch = std::clamp(u.pitch + io.MouseDelta.y * 0.5f, -89.0f, 89.0f);
            } else if (u.drag == D::Ring) {
                const Vec3 head = bone_head(*rig, u.dragBase, node);
                double a = 0;
                if (ring_angle(u.cam, mx, my, head, gizmo_axis_world(*rig, u.dragBase, node, u.dragAxis), a)) {
                    u.dragTotal += angle_delta(u.dragAngle, a);
                    u.dragAngle = a;
                }
                u.livePose = u.dragBase;
                u.livePose.rotation[std::size_t(node)] = rotated_local(*rig, u.dragBase, node, u.dragAxis, u.dragTotal);
                u.live = true;
                u.dragMoved = std::fabs(u.dragTotal) > 1e-3;
                ++u.liveSerial;
            } else if (u.drag == D::Arrow) {
                const Vec3 head = bone_head(*rig, u.dragBase, node);
                double s = 0;
                if (line_param(u.cam, mx, my, head, gizmo_axis_world(*rig, u.dragBase, node, u.dragAxis), s)) u.dragTotal = s - u.dragStartS;
                const Vec3 delta = gizmo_axis_world(*rig, u.dragBase, node, u.dragAxis) * float(u.dragTotal);
                Vec3 local{};
                for (int a = 0; a < 3; ++a) {
                    const float c = dot(delta, gizmo_axis_world(*rig, u.dragBase, node, a));
                    (a == 0 ? local.x : a == 1 ? local.y : local.z) = c;
                }
                u.livePose = u.dragBase;
                u.livePose.translation[std::size_t(node)] = u.dragBase.translation[std::size_t(node)] + local;
                u.live = true;
                u.dragMoved = std::fabs(u.dragTotal) > 1e-4;
                ++u.liveSerial;
            } else {
                Vec3 hp;
                if (plane_hit(u.cam, mx, my, u.dragPoint, u.cam.forward, hp)) u.dragPoint = hp + u.dragOffset;
                Json solver;
                if (u.drag == D::IkTarget) solver = two_bone_solver(*rig, limb, u.dragPoint, u.ikPole);
                else if (u.drag == D::IkPole) solver = two_bone_solver(*rig, limb, u.dragEnd, u.dragPoint);
                else solver = look_at_solver(*rig, node, u.dragPoint);
                Pose solved = u.dragBase;
                const auto res = ik3d_solve_once(r3, solved, solver, 0.0f);
                if (res.ok()) {
                    u.livePose = solved;
                    u.live = true;
                    u.liveSolver = solver;
                    u.dragMoved = true;
                    ++u.liveSerial;
                }
            }
            if (u.yaw > 180.0f) u.yaw -= 360.0f;
            if (u.yaw < -180.0f) u.yaw += 360.0f;
        } else {   // let go
            const D kind = u.drag;
            u.drag = D::None;
            if (kind == D::Orbit) {
                if (!u.dragMoved && b == 0) {
                    const int idx = pick_bone(mx, my);
                    u.bone = idx >= 0 ? rows[std::size_t(idx)].name : std::string();
                    if (idx >= 0) u.status.clear();
                }
            } else if (u.dragMoved) {
                if (kind == D::Ring) {
                    const Quat delta = pose_delta_rotation(r3, u.livePose, node);
                    const Anim3DEdit e = m.set_key(u.bone, 0, u.dragTime, rotation_key_value(*clip, delta));
                    anim3d_commit(e);
                    if (e.ok) u.selection = {Key3D{u.bone, 0, key3d_ms(u.dragTime)}};
                } else if (kind == D::Arrow) {
                    const Vec3 t = u.livePose.translation[std::size_t(node)] - r3.rest.translation[std::size_t(node)];
                    const Anim3DEdit e = m.set_key(u.bone, 1, u.dragTime, {t.x, t.y, t.z, 0});
                    anim3d_commit(e);
                    if (e.ok) u.selection = {Key3D{u.bone, 1, key3d_ms(u.dragTime)}};
                } else if (u.liveSolver.is_object()) {
                    if (kind == D::IkPole) u.ikPole = u.dragPoint;
                    if (kind == D::LookTarget) u.lookPoint = u.dragPoint;
                    anim3d_commit(m.ik_key(u.dragTime, u.liveSolver));
                }
            }
            if (kind != D::Orbit) {
                u.live = false;
                ++u.liveSerial;
            }
        }
    }
    if (u.yaw > 180.0f) u.yaw -= 360.0f;
    if (u.yaw < -180.0f) u.yaw += 360.0f;

    // ---- the overlay
    u.bonesDrawn = 0;
    u.handlesDrawn = 0;
    const ImU32 boneCol = IM_COL32(120, 190, 255, 215), pickCol = IM_COL32(255, 170, 60, 255), hoverCol = IM_COL32(255, 255, 255, 255);
    if (u.showBones) {
        for (std::size_t i = 0; i < rows.size(); ++i) {
            if (!heads[i].ok) continue;
            const bool picked = rows[i].name == u.bone, hot = int(i) == hoverBone;
            const ImU32 col = picked ? pickCol : hot ? hoverCol : boneCol;
            if (tails[i].ok) dl->AddLine(S(heads[i]), S(tails[i]), col, picked ? 3.0f : 1.8f);
            dl->AddCircleFilled(S(heads[i]), picked ? 5.0f : 3.2f, col);
            ++u.bonesDrawn;
            if (autotest_) at_track_at("a3:joint:" + rows[i].name, Vec2{p0.x + float(heads[i].x), p0.y + float(heads[i].y)});
        }
    }
    if (hoverBone >= 0 && hovered) ImGui::SetTooltip("%s", rows[std::size_t(hoverBone)].name.c_str());
    if (node >= 0 && canEdit) {
        const bool dragging = u.drag != D::None && u.drag != D::Orbit;
        if (rotateTool) {
            HandleHit over;
            if (hovered && u.drag == D::None) over = hit_handle(mx, my);
            for (int a = 0; a < 3; ++a) {
                const auto& pts = ring[std::size_t(a)];
                const bool hot = (u.drag == D::Ring && u.dragAxis == a) || (over.kind == HandleHit::Ring && over.axis == a);
                std::vector<ImVec2> line;
                for (const Scr& s : pts)
                    if (s.ok) line.push_back(S(s));
                if (line.size() > 1) dl->AddPolyline(line.data(), int(line.size()), axis_color(a, hot), ImDrawFlags_None, hot ? 3.4f : 2.0f);
                ++u.handlesDrawn;
                if (autotest_ && !pts.empty()) {   // the point of the ring farthest from the other two: a click there picks this ring
                    std::size_t bestK = 0;
                    double bestD = -1;
                    for (std::size_t k = 0; k < pts.size(); ++k) {
                        if (!pts[k].ok) continue;
                        double d = 1e9;
                        for (int b = 0; b < 3; ++b) {
                            if (b == a) continue;
                            const auto& other = ring[std::size_t(b)];
                            for (std::size_t j = 0; j + 1 < other.size(); ++j)
                                if (other[j].ok && other[j + 1].ok) d = std::min(d, segment_distance(pts[k].x, pts[k].y, other[j].x, other[j].y, other[j + 1].x, other[j + 1].y));
                        }
                        if (d > bestD) bestD = d, bestK = k;
                    }
                    at_track_at(std::string("a3:ring:") + "xyz"[a], Vec2{p0.x + float(pts[bestK].x), p0.y + float(pts[bestK].y)});
                }
            }
            if (showArrows && headS.ok) {
                for (int a = 0; a < 3; ++a) {
                    if (!arrowTip[std::size_t(a)].ok) continue;
                    const bool hot = (u.drag == D::Arrow && u.dragAxis == a) || (over.kind == HandleHit::Arrow && over.axis == a);
                    dl->AddLine(S(headS), S(arrowTip[std::size_t(a)]), axis_color(a, hot), hot ? 3.4f : 2.0f);
                    dl->AddCircleFilled(S(arrowTip[std::size_t(a)]), hot ? 6.0f : 4.5f, axis_color(a, hot));
                    ++u.handlesDrawn;
                    if (autotest_) at_track_at(std::string("a3:arrow:") + "xyz"[a], Vec2{p0.x + float(arrowTip[std::size_t(a)].x), p0.y + float(arrowTip[std::size_t(a)].y)});
                }
            }
            if (dragging && (u.drag == D::Ring || u.drag == D::Arrow)) {
                const std::string note = u.drag == D::Ring ? std::format("{} {:+.1f} deg about {}", u.bone, u.dragTotal * 180.0 / kPi, "xyz"[u.dragAxis])
                                                           : std::format("{} {:+.3f} along {}", u.bone, u.dragTotal, "xyz"[u.dragAxis]);
                dl->AddText(ImVec2(p0.x + 8, p0.y + float(h) - 20), IM_COL32(255, 230, 160, 255), note.c_str());
            }
        } else {
            HandleHit over;
            if (hovered && u.drag == D::None) over = hit_handle(mx, my);
            if (ikOk) {
                if (midS.ok && poleS.ok) dl->AddLine(S(midS), S(poleS), IM_COL32(200, 160, 255, 160), 1.4f);
                if (targetS.ok) {
                    const bool hot = u.drag == D::IkTarget || over.kind == HandleHit::Target;
                    dl->AddCircle(S(targetS), hot ? 11.0f : 9.0f, IM_COL32(255, 200, 70, 255), 20, 2.6f);
                    dl->AddCircleFilled(S(targetS), 3.0f, IM_COL32(255, 200, 70, 255));
                    ++u.handlesDrawn;
                    if (autotest_) at_track_at("a3:ik:target", Vec2{p0.x + float(targetS.x), p0.y + float(targetS.y)});
                }
                if (poleS.ok) {
                    const bool hot = u.drag == D::IkPole || over.kind == HandleHit::Pole;
                    const ImVec2 c = S(poleS);
                    const float rr = hot ? 9.0f : 7.0f;
                    dl->AddQuadFilled(ImVec2(c.x, c.y - rr), ImVec2(c.x + rr, c.y), ImVec2(c.x, c.y + rr), ImVec2(c.x - rr, c.y), IM_COL32(190, 140, 255, 230));
                    ++u.handlesDrawn;
                    if (autotest_) at_track_at("a3:ik:pole", Vec2{c.x, c.y});
                }
            } else if (lookOk && lookS.ok) {
                const bool hot = u.drag == D::LookTarget || over.kind == HandleHit::Look;
                const ImVec2 c = S(lookS);
                const float rr = hot ? 12.0f : 10.0f;
                dl->AddCircle(c, rr, IM_COL32(255, 200, 70, 255), 20, 2.4f);
                dl->AddLine(ImVec2(c.x - rr - 3, c.y), ImVec2(c.x + rr + 3, c.y), IM_COL32(255, 200, 70, 255), 1.6f);
                dl->AddLine(ImVec2(c.x, c.y - rr - 3), ImVec2(c.x, c.y + rr + 3), IM_COL32(255, 200, 70, 255), 1.6f);
                if (headS.ok) dl->AddLine(S(headS), c, IM_COL32(255, 200, 70, 120), 1.2f);
                ++u.handlesDrawn;
                if (autotest_) at_track_at("a3:ik:look", Vec2{c.x, c.y});
            }
            if (dragging) {
                dl->AddText(ImVec2(p0.x + 8, p0.y + float(h) - 20), IM_COL32(255, 230, 160, 255),
                            u.drag == D::LookTarget ? (u.bone + " looks at the point").c_str() : ("IK " + u.bone + (u.drag == D::IkPole ? ": pole" : ": target")).c_str());
            }
        }
    }
    const char* hint = !canEdit ? ""
                       : node < 0 ? "Click a bone to pick it. Drag to orbit, wheel to zoom."
                       : (!rotateTool && !ikOk && !lookOk) ? "IK handles: pick a hand or a foot (two bones above it), or the head."
                                                           : "";
    if (*hint) dl->AddText(ImVec2(p0.x + 8, p0.y + 6), IM_COL32(200, 205, 215, 220), hint);
    dl->PopClipRect();
}

// -------------------------------------------------------------------------------------------------------------- dopesheet --
namespace {

constexpr float kRowH = 20.0f, kLabelW = 200.0f, kRulerH = 22.0f, kLaneH = 18.0f;

struct SheetRow {
    std::string bone;
    int channel = 0;
    std::size_t track = 0;
    int depth = 0;
};

ImU32 channel_color(int channel, bool selected) {
    if (selected) return IM_COL32(255, 235, 140, 255);
    return channel == 0 ? IM_COL32(240, 150, 80, 255) : channel == 1 ? IM_COL32(110, 205, 120, 255) : IM_COL32(120, 160, 240, 255);
}

}  // namespace

void Editor::anim3d_dopesheet() {
    Anim3DUi& u = anim3d_;
    Anim3DModel& m = *u.model;
    const std::shared_ptr<const Anim3DClip> clip = m.clip();   // a copy: an edit below reloads the model, and the clip it replaced stays valid here
    if (!clip) return;
    const double dur = double(clip->duration);
    using SD = Anim3DUi::SheetDrag;
    ImGuiIO& io = ImGui::GetIO();

    // ---- the tracks, in the rig's bone order
    std::vector<SheetRow> rows;
    {
        const std::vector<Anim3DBoneRow> bones = m.rows();
        std::map<std::string, std::pair<int, int>> order;   // bone -> (index in the rig, depth)
        for (std::size_t i = 0; i < bones.size(); ++i) order[bones[i].name] = {int(i), bones[i].depth};
        for (std::size_t i = 0; i < clip->tracks.size(); ++i) {
            const Anim3DTrack& t = clip->tracks[i];
            if (u.onlyBone && t.bone != u.bone) continue;
            const auto it = order.find(t.bone);
            rows.push_back({t.bone, int(t.channel), i, it == order.end() ? 0 : it->second.second});
        }
        std::stable_sort(rows.begin(), rows.end(), [&](const SheetRow& a, const SheetRow& b) {
            const auto ia = order.find(a.bone), ib = order.find(b.bone);
            const int oa = ia == order.end() ? 1 << 20 : ia->second.first, ob = ib == order.end() ? 1 << 20 : ib->second.first;
            if (oa != ob) return oa < ob;
            if (a.bone != b.bone) return a.bone < b.bone;
            return a.channel < b.channel;
        });
    }

    // ---- header
    if (ImGui::Button("Fit")) u.fitNext = true;
    at_track("a3:fit");
    ImGui::SameLine();
    ImGui::Checkbox("Only the picked bone", &u.onlyBone);
    at_track("a3:onlybone");
    ImGui::SameLine();
    ImGui::BeginDisabled(u.selection.empty());
    {
        std::string cur = "(keys)";
        if (!u.selection.empty()) {
            std::set<std::string> kinds;
            for (const Key3D& k : u.selection)
                if (const ClipKey* ck = m.key_at(k)) kinds.insert(key3d_interp(*ck));
            cur = kinds.size() == 1 ? *kinds.begin() : "mixed";
        }
        ImGui::SetNextItemWidth(110);
        if (ImGui::BeginCombo("##a3_interp", cur.c_str())) {
            std::vector<std::string> names = {"linear", "step", "bezier"};
            for (const std::string& n : clip_ease_names()) names.push_back(n);
            for (const std::string& n : names) {
                if (ImGui::Selectable(n.c_str(), n == cur)) anim3d_commit(m.set_interp(u.selection, n));
                at_track("a3:interp:" + n);
            }
            ImGui::EndCombo();
        }
        at_track("a3:interp", !u.selection.empty());
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
            ImGui::SetTooltip("How the picked keys ease into the next one: linear, step (holds), bezier or one of the M42 easings.");
    }
    ImGui::SameLine();
    if (ImGui::Button("Delete keys")) {
        anim3d_commit(m.remove_keys(u.selection));
        u.selection.clear();
    }
    at_track("a3:delete", !u.selection.empty());
    ImGui::EndDisabled();
    ImGui::SameLine();
    ImGui::TextDisabled("%d key%s picked   click: pick (shift adds)   drag: move   double click a row: key the current pose   Ctrl+wheel: zoom",
                        int(u.selection.size()), u.selection.size() == 1 ? "" : "s");

    // ---- layout
    const ImVec2 o = ImGui::GetCursorScreenPos();
    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const float timeW = std::max(80.0f, avail.x - kLabelW);
    u.timeX0 = o.x + kLabelW;
    u.timeX1 = u.timeX0 + timeW;
    u.rulerY = o.y;
    u.rowsY0 = o.y + kRulerH + kLaneH;
    if (u.fitNext && dur > 0) {
        u.pps = std::clamp(float((double(timeW) - 24.0) / dur), 20.0f, 4000.0f);
        u.viewStart = 0;
        u.fitNext = false;
    }
    auto x_of = [&](double t) { return u.timeX0 + 12.0f + float((t - u.viewStart) * double(u.pps)); };
    auto t_of = [&](double x) { return u.viewStart + (x - double(u.timeX0) - 12.0) / double(u.pps); };
    auto snap_free = [&](double t) { return u.snap && u.fps > 0 ? std::round(t * u.fps) / u.fps : std::round(t * 1000.0) / 1000.0; };

    ImDrawList* dl = ImGui::GetWindowDrawList();
    // zoom with Ctrl+wheel, pan with Shift+wheel, over the whole sheet
    if (ImGui::IsWindowHovered(ImGuiHoveredFlags_ChildWindows) && io.MouseWheel != 0.0f && io.MousePos.x >= u.timeX0) {
        if (io.KeyCtrl) {
            const double under = t_of(io.MousePos.x);
            u.pps = std::clamp(u.pps * std::pow(1.15f, io.MouseWheel), 20.0f, 4000.0f);
            u.viewStart = under - (double(io.MousePos.x) - double(u.timeX0) - 12.0) / double(u.pps);
        } else if (io.KeyShift) {
            u.viewStart -= double(io.MouseWheel) * 60.0 / double(u.pps);
        }
    }
    u.viewStart = std::clamp(u.viewStart, -12.0 / double(u.pps), std::max(dur, 1.0));

    // ---- ruler: scrub
    ImGui::SetCursorScreenPos(ImVec2(u.timeX0, o.y));
    ImGui::InvisibleButton("##a3_ruler", ImVec2(timeW, kRulerH));
    at_track("a3:ruler");
    if (ImGui::IsItemActive() && io.MouseDown[0]) {
        u.playhead = anim3d_snap(t_of(io.MousePos.x));
        u.playing = false;
        u.sheetDrag = SD::Scrub;
    } else if (u.sheetDrag == SD::Scrub) {
        u.sheetDrag = SD::None;
    }
    // ---- event lane
    ImGui::SetCursorScreenPos(ImVec2(u.timeX0, o.y + kRulerH));
    ImGui::InvisibleButton("##a3_lane", ImVec2(timeW, kLaneH));
    at_track("a3:lane");
    const bool laneHover = ImGui::IsItemHovered();
    auto event_at = [&](double x) {
        int best = -1;
        float bestD = 7.0f;
        for (std::size_t i = 0; i < clip->events.size(); ++i) {
            const float d = std::fabs(x_of(double(clip->events[i].t)) - float(x));
            if (d <= bestD) best = int(i), bestD = d;
        }
        return best;
    };
    if (ImGui::IsItemClicked(ImGuiMouseButton_Left)) {
        const int hit = event_at(io.MousePos.x);
        if (ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left) && hit < 0) {
            const Anim3DEdit e = m.add_event(anim3d_snap(t_of(io.MousePos.x)), u.eventName.empty() ? "event" : u.eventName);
            anim3d_commit(e);
            if (e.ok) {
                u.selectedEvent = -1;
                for (std::size_t i = 0; m.clip() && i < m.clip()->events.size(); ++i)
                    if (std::fabs(double(m.clip()->events[i].t) - anim3d_snap(t_of(io.MousePos.x))) < 0.0006) u.selectedEvent = int(i);
            }
        } else {
            u.selectedEvent = hit;
            if (hit >= 0) {
                u.sheetDrag = SD::Event;
                u.sheetEvent = hit;
                u.sheetPressT = double(clip->events[std::size_t(hit)].t);
                u.sheetDt = 0;
                u.sheetMoved = false;
            }
        }
    }
    if (u.sheetDrag == SD::Event) {
        if (io.MouseDown[0]) {
            const double target = std::clamp(snap_free(t_of(io.MousePos.x)), 0.0, std::max(dur, 0.0));
            u.sheetDt = target - u.sheetPressT;
            u.sheetMoved = std::fabs(u.sheetDt) > 1e-6;
        } else {
            u.sheetDrag = SD::None;
            if (u.sheetMoved && u.sheetEvent >= 0 && u.sheetEvent < int(clip->events.size())) {
                anim3d_commit(m.set_event(u.sheetEvent, Json::object({{"t", u.sheetPressT + u.sheetDt}})));
                if (m.clip())   // the events stay in time order: follow the one that moved
                    for (std::size_t i = 0; i < m.clip()->events.size(); ++i)
                        if (std::fabs(double(m.clip()->events[i].t) - (u.sheetPressT + u.sheetDt)) < 0.0006 &&
                            m.clip()->events[i].name == clip->events[std::size_t(u.sheetEvent)].name)
                            u.selectedEvent = int(i);
            }
            u.sheetEvent = -1;
            u.sheetMoved = false;
        }
    }
    // the ruler and the lane themselves
    {
        const ImU32 bg = IM_COL32(34, 36, 42, 255), tick = IM_COL32(150, 155, 165, 255), text = IM_COL32(200, 205, 215, 255);
        dl->AddRectFilled(ImVec2(u.timeX0, o.y), ImVec2(u.timeX1, o.y + kRulerH + kLaneH), bg);
        dl->PushClipRect(ImVec2(u.timeX0, o.y), ImVec2(u.timeX1, o.y + kRulerH + kLaneH), true);
        const double firstT = std::floor(t_of(u.timeX0) * 20.0) / 20.0, lastT = t_of(u.timeX1);
        double step = 0.05;   // a label every >= 60 px
        for (double s : {0.05, 0.1, 0.25, 0.5, 1.0, 2.0, 5.0}) {
            step = s;
            if (s * double(u.pps) >= 60.0) break;
        }
        for (double t = std::floor(firstT / step) * step; t <= lastT + 1e-9; t += step) {
            if (t < -1e-9) continue;
            const float x = x_of(t);
            dl->AddLine(ImVec2(x, o.y + kRulerH - 8), ImVec2(x, o.y + kRulerH), tick);
            dl->AddText(ImVec2(x + 3, o.y + 2), text, std::format("{:.2f}", t).c_str());
        }
        // frames, when there is room
        if (u.snap && u.fps > 0 && double(u.pps) / double(u.fps) >= 6.0) {
            for (int f = int(std::max(0.0, std::floor(t_of(u.timeX0) * u.fps))); double(f) / u.fps <= std::min(lastT, dur) + 1e-9; ++f)
                dl->AddLine(ImVec2(x_of(double(f) / u.fps), o.y + kRulerH - 4), ImVec2(x_of(double(f) / u.fps), o.y + kRulerH), IM_COL32(100, 105, 115, 255));
        }
        // the end of the clip
        dl->AddRectFilled(ImVec2(x_of(dur), o.y), ImVec2(u.timeX1 + 1, o.y + kRulerH + kLaneH), IM_COL32(0, 0, 0, 90));
        dl->AddLine(ImVec2(x_of(dur), o.y), ImVec2(x_of(dur), o.y + kRulerH + kLaneH), IM_COL32(220, 90, 90, 255));
        // events
        for (std::size_t i = 0; i < clip->events.size(); ++i) {
            double t = double(clip->events[i].t);
            if (u.sheetDrag == SD::Event && int(i) == u.sheetEvent) t = u.sheetPressT + u.sheetDt;
            const float x = x_of(t), cy = o.y + kRulerH + kLaneH * 0.5f;
            const bool sel = int(i) == u.selectedEvent;
            const ImU32 col = sel ? IM_COL32(255, 235, 140, 255) : IM_COL32(120, 200, 255, 255);
            dl->AddTriangleFilled(ImVec2(x, cy + 6), ImVec2(x - 5, cy - 5), ImVec2(x + 5, cy - 5), col);
            dl->AddText(ImVec2(x + 7, cy - 7), sel ? col : IM_COL32(170, 190, 215, 255), clip->events[i].name.c_str());
            at_track_at("a3:event:" + std::to_string(i) + ":mark", Vec2{x, cy});
        }
        dl->PopClipRect();
        if (laneHover && event_at(io.MousePos.x) < 0) ImGui::SetTooltip("Double click: add an event \"%s\" here", u.eventName.c_str());
    }

    // ---- the rows
    ImGui::SetCursorScreenPos(ImVec2(o.x, o.y + kRulerH + kLaneH + 2));
    ImGui::BeginChild("##a3_rows", ImVec2(0, 0), ImGuiChildFlags_None);
    {
        ImDrawList* rl = ImGui::GetWindowDrawList();
        const ImVec2 start = ImGui::GetCursorScreenPos();
        const float width = std::max(ImGui::GetContentRegionAvail().x, 40.0f);
        const float total = std::max(float(rows.size()) * kRowH, 1.0f);
        ImGui::InvisibleButton("##a3_rowhit", ImVec2(width, total), ImGuiButtonFlags_MouseButtonLeft);
        at_track("a3:rows");
        const bool rowsHover = ImGui::IsItemHovered();
        const float winTop = ImGui::GetWindowPos().y, winBottom = winTop + ImGui::GetWindowHeight();

        auto key_pos = [&](const SheetRow& r, const ClipKey& k, std::size_t row, bool shifted, double dt) {
            return ImVec2(x_of(double(k.t) + (shifted ? dt : 0.0)), start.y + float(row) * kRowH + kRowH * 0.5f);
        };
        auto key_hit = [&](double mx, double my, Key3D& out) {
            const int row = int(std::floor((my - double(start.y)) / double(kRowH)));
            if (row < 0 || row >= int(rows.size())) return false;
            const SheetRow& r = rows[std::size_t(row)];
            double best = 7.0;
            bool found = false;
            for (const ClipKey& k : clip->tracks[r.track].keys) {
                const double d = std::fabs(double(x_of(double(k.t))) - mx);
                if (d <= best) best = d, out = Key3D{r.bone, r.channel, key3d_ms(double(k.t))}, found = true;
            }
            return found;
        };
        auto row_at = [&](double my) {
            const int row = int(std::floor((my - double(start.y)) / double(kRowH)));
            return row >= 0 && row < int(rows.size()) ? row : -1;
        };

        const bool hovered = ImGui::IsItemHovered();
        if (ImGui::IsItemClicked(ImGuiMouseButton_Left)) {
            Key3D hit;
            const int row = row_at(io.MousePos.y);
            if (io.MousePos.x < u.timeX0) {                 // the label column: pick the bone
                if (row >= 0) u.bone = rows[std::size_t(row)].bone;
            } else if (key_hit(io.MousePos.x, io.MousePos.y, hit)) {
                if (io.KeyShift) {
                    if (!u.selection.erase(hit)) u.selection.insert(hit);
                } else if (!u.selection.count(hit)) {
                    u.selection = {hit};
                }
                u.bone = hit.bone;
                if (u.selection.count(hit)) {
                    u.sheetDrag = SD::Keys;
                    u.sheetPressT = snap_free(t_of(io.MousePos.x));
                    u.sheetDt = 0;
                    u.sheetMoved = false;
                }
            } else if (row >= 0 && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left)) {
                const SheetRow& r = rows[std::size_t(row)];
                const double t = anim3d_snap(t_of(io.MousePos.x));
                const Anim3DEdit e = m.key_sampled(r.bone, r.channel, t);
                anim3d_commit(e);
                if (e.ok) u.selection = {Key3D{r.bone, r.channel, key3d_ms(t)}};
                u.bone = r.bone;
            } else {
                if (!io.KeyShift) u.selection.clear();
                if (row >= 0) u.bone = rows[std::size_t(row)].bone;
                if (io.MousePos.x >= u.timeX0 && !io.KeyShift && row < 0) {   // below the last row: move the playhead
                    u.playhead = anim3d_snap(t_of(io.MousePos.x));
                }
            }
        }
        if (u.sheetDrag == SD::Keys) {
            if (io.MouseDown[0]) {
                double dt = snap_free(t_of(io.MousePos.x)) - u.sheetPressT;
                if (!u.selection.empty()) dt = std::max(dt, -earliest_time3d(u.selection));
                u.sheetDt = dt;
                u.sheetMoved = std::fabs(dt) > 1e-6;
            } else {
                u.sheetDrag = SD::None;
                if (u.sheetMoved && !u.selection.empty()) {
                    const double dt = u.sheetDt;
                    const bool extend = latest_time3d(u.selection) + dt > dur + 1e-6;
                    const Anim3DEdit e = m.move_keys(u.selection, dt, extend);
                    anim3d_commit(e);
                    if (e.ok) {
                        Key3DSet moved;
                        for (const Key3D& k : u.selection) moved.insert(Key3D{k.bone, k.channel, k.ms + std::llround(dt * 1000.0)});
                        u.selection = moved;
                    }
                }
                u.sheetMoved = false;
                u.sheetDt = 0;
            }
        }
        (void)rowsHover;
        (void)hovered;

        // rows
        u.keysDrawn = 0;
        const std::string pickedBone = u.bone;
        std::string lastBone;
        for (std::size_t row = 0; row < rows.size(); ++row) {
            const SheetRow& r = rows[row];
            const float y = start.y + float(row) * kRowH;
            if (y + kRowH < winTop || y > winBottom) continue;
            const bool picked = r.bone == pickedBone;
            rl->AddRectFilled(ImVec2(start.x, y), ImVec2(start.x + width, y + kRowH),
                              picked ? IM_COL32(60, 70, 95, 255) : (row % 2 ? IM_COL32(40, 42, 48, 255) : IM_COL32(35, 37, 42, 255)));
            const std::string label = std::string(std::size_t(std::min(r.depth, 6)) * 2, ' ') + (r.bone == lastBone ? std::string("   ") : r.bone + " ") + channel3d_short(r.channel);
            lastBone = r.bone;
            rl->PushClipRect(ImVec2(start.x, y), ImVec2(u.timeX0, y + kRowH), true);
            rl->AddText(ImVec2(start.x + 6, y + 2), picked ? IM_COL32(255, 220, 150, 255) : IM_COL32(200, 205, 215, 255), label.c_str());
            rl->PopClipRect();
            at_track_at("a3:row:" + r.bone + ":" + std::to_string(r.channel), Vec2{start.x + 40, y + kRowH * 0.5f});
            rl->PushClipRect(ImVec2(u.timeX0, y), ImVec2(u.timeX1, y + kRowH), true);
            // stance bars
            for (const Anim3DContact& c : clip->contacts) {
                if (c.bone != r.bone) continue;
                const float a = x_of(double(c.from)), b = x_of(double(c.to));
                if (c.from <= c.to) {
                    rl->AddRectFilled(ImVec2(a, y + kRowH - 4), ImVec2(b, y + kRowH - 1), IM_COL32(90, 170, 100, 150));
                } else {
                    rl->AddRectFilled(ImVec2(a, y + kRowH - 4), ImVec2(x_of(dur), y + kRowH - 1), IM_COL32(90, 170, 100, 150));
                    rl->AddRectFilled(ImVec2(x_of(0), y + kRowH - 4), ImVec2(b, y + kRowH - 1), IM_COL32(90, 170, 100, 150));
                }
            }
            for (const ClipKey& k : clip->tracks[r.track].keys) {
                const Key3D id{r.bone, r.channel, key3d_ms(double(k.t))};
                const bool sel = u.selection.count(id) > 0;
                const bool ghost = sel && u.sheetDrag == SD::Keys && u.sheetMoved;
                const ImVec2 c = key_pos(r, k, row, ghost, u.sheetDt);
                if (c.x < u.timeX0 - 8 || c.x > u.timeX1 + 8) continue;
                const float rr = sel ? 5.5f : 4.5f;
                const ImU32 col = channel_color(r.channel, sel);
                if (ghost) rl->AddCircle(ImVec2(x_of(double(k.t)), c.y), 3.0f, IM_COL32(150, 150, 150, 160));
                if (k.interp == ClipInterp::Step)
                    rl->AddRectFilled(ImVec2(c.x - rr + 1, c.y - rr + 1), ImVec2(c.x + rr - 1, c.y + rr - 1), col);
                else
                    rl->AddQuadFilled(ImVec2(c.x, c.y - rr), ImVec2(c.x + rr, c.y), ImVec2(c.x, c.y + rr), ImVec2(c.x - rr, c.y), col);
                rl->AddQuad(ImVec2(c.x, c.y - rr), ImVec2(c.x + rr, c.y), ImVec2(c.x, c.y + rr), ImVec2(c.x - rr, c.y), IM_COL32(20, 20, 24, 255));
                ++u.keysDrawn;
                at_track_at("a3:key:" + r.bone + ":" + std::to_string(r.channel) + ":" + std::to_string(id.ms), Vec2{c.x, c.y});
            }
            rl->PopClipRect();
        }
        // the playhead over the rows
        rl->PushClipRect(ImVec2(u.timeX0, winTop), ImVec2(u.timeX1, winBottom), true);
        rl->AddLine(ImVec2(x_of(u.playhead), winTop), ImVec2(x_of(u.playhead), winBottom), IM_COL32(255, 90, 90, 220), 1.5f);
        rl->PopClipRect();
        if (rows.empty()) rl->AddText(ImVec2(start.x + 8, start.y + 4), IM_COL32(150, 155, 165, 255), "This clip has no tracks yet: pick a bone and use Key rotation, or turn it with a gizmo.");
    }
    ImGui::EndChild();
    // the playhead over the ruler and the lane
    dl->PushClipRect(ImVec2(u.timeX0, o.y), ImVec2(u.timeX1, o.y + kRulerH + kLaneH), true);
    {
        const float x = x_of(u.playhead);
        dl->AddLine(ImVec2(x, o.y), ImVec2(x, o.y + kRulerH + kLaneH), IM_COL32(255, 90, 90, 255), 1.5f);
        dl->AddTriangleFilled(ImVec2(x - 5, o.y), ImVec2(x + 5, o.y), ImVec2(x, o.y + 8), IM_COL32(255, 90, 90, 255));
    }
    dl->PopClipRect();
}

// ------------------------------------------------------------------------------------------------------------- inspector --
void Editor::anim3d_inspector() {
    Anim3DUi& u = anim3d_;
    Anim3DModel& m = *u.model;
    const std::shared_ptr<const Anim3DClip> clip = m.clip();
    if (!clip) return;
    const Anim3DRigModel* rig = m.rig();

    // ---- the picked bone
    if (ImGui::CollapsingHeader("Bone", ImGuiTreeNodeFlags_DefaultOpen)) {
        const int node = rig ? m.node_of(u.bone) : -1;
        if (u.bone.empty() || (node < 0 && rig)) {
            ImGui::TextDisabled("No bone picked. Click a bone in the view or the list.");
        } else {
            ImGui::TextUnformatted(u.bone.c_str());
            ImGui::TextDisabled("%d key%s in this clip", m.key_count(u.bone), m.key_count(u.bone) == 1 ? "" : "s");
            if (rig && node >= 0) {
                const Pose pose = u.live ? u.livePose : m.pose_at(u.playhead);
                const auto v = rotation_key_value(*clip, pose_delta_rotation(rig->rig, pose, node));
                const Vec3 t = pose.translation[std::size_t(node)] - rig->rig.rest.translation[std::size_t(node)];
                if (clip->quat) ImGui::Text("rotation  %.3f %.3f %.3f %.3f", v[0], v[1], v[2], v[3]);
                else ImGui::Text("rotation  %.1f %.1f %.1f deg", v[0], v[1], v[2]);
                ImGui::Text("position  %+.3f %+.3f %+.3f", t.x, t.y, t.z);
            }
        }
    }

    // ---- the picked key
    if (ImGui::CollapsingHeader("Key", ImGuiTreeNodeFlags_DefaultOpen)) {
        if (u.selection.size() == 1) {
            const Key3D k = *u.selection.begin();
            const ClipKey* ck = m.key_at(k);
            if (ck) {
                if (!(u.keyShown == k) || u.keyShownRev != m.revision()) {
                    if (!ImGui::IsAnyItemActive()) {
                        u.keyVals = ck->value;
                        u.keyShown = k;
                        u.keyShownRev = m.revision();
                    }
                }
                ImGui::Text("%s %s at %.3f s (%s)", k.bone.c_str(), channel3d_name(k.channel), double(ck->t), key3d_interp(*ck).c_str());
                const bool quat = k.channel == 0 && clip->quat;
                ImGui::SetNextItemWidth(-1);
                if (quat) ImGui::DragFloat4("##a3_keyval", u.keyVals.data(), 0.01f);
                else ImGui::DragFloat3("##a3_keyval", u.keyVals.data(), k.channel == 0 ? 0.5f : 0.005f);
                at_track("a3:keyvalue");
                if (ImGui::IsItemDeactivatedAfterEdit()) {
                    const Anim3DEdit e = m.set_key(k.bone, k.channel, double(ck->t), u.keyVals);
                    anim3d_commit(e);
                    u.keyShownRev = ~0ULL;
                }
                if (ImGui::IsItemHovered()) ImGui::SetTooltip(k.channel == 0 && !quat ? "Euler degrees, the way the file stores them." : "Local units (the offset from the bone's rest pose).");
            }
        } else if (u.selection.empty()) {
            ImGui::TextDisabled("No key picked.");
        } else {
            ImGui::Text("%d keys picked (%.2f s to %.2f s)", int(u.selection.size()), earliest_time3d(u.selection), latest_time3d(u.selection));
        }
    }

    // ---- the clip
    if (ImGui::CollapsingHeader("Clip")) {
        float duration = clip->duration, ground = clip->groundSpeed;
        bool loop = clip->loop;
        ImGui::SetNextItemWidth(110);
        ImGui::InputFloat("duration (s)", &duration, 0, 0, "%.3f");
        at_track("a3:duration");
        if (ImGui::IsItemDeactivatedAfterEdit() && duration > 0) anim3d_commit(m.set_clip(Json::object({{"duration", double(duration)}})));
        if (ImGui::Checkbox("loop", &loop)) anim3d_commit(m.set_clip(Json::object({{"loop", loop}})));
        at_track("a3:cliploop");
        ImGui::SetNextItemWidth(110);
        ImGui::InputFloat("ground speed", &ground, 0, 0, "%.3f");
        at_track("a3:groundspeed");
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("Model units per second the ground moves under the feet in stance (0 = in place).");
        if (ImGui::IsItemDeactivatedAfterEdit() && ground >= 0) anim3d_commit(m.set_clip(Json::object({{"groundSpeed", double(ground)}})));
        ImGui::TextDisabled("rig  %s", clip->rig.empty() ? "(any)" : clip->rig.c_str());
        if (!clip->generated.is_null()) ImGui::TextDisabled("generated  %s", clip->generated.dump().c_str());
    }

    // ---- events
    if (ImGui::CollapsingHeader("Events", ImGuiTreeNodeFlags_DefaultOpen)) {
        for (std::size_t i = 0; i < clip->events.size(); ++i) {
            const bool sel = int(i) == u.selectedEvent;
            if (ImGui::Selectable((std::format("{:.3f}  {}", double(clip->events[i].t), clip->events[i].name) + "##a3_ev" + std::to_string(i)).c_str(), sel)) u.selectedEvent = int(i);
            at_track("a3:event:" + std::to_string(i));
        }
        if (clip->events.empty()) ImGui::TextDisabled("None. Double click the lane under the ruler, or Add.");
        if (u.selectedEvent >= 0 && u.selectedEvent < int(clip->events.size())) {
            const ClipEvent& ev = clip->events[std::size_t(u.selectedEvent)];
            const std::string key = clip->path + "#" + std::to_string(u.selectedEvent) + "@" + std::to_string(m.revision());
            if (u.eventTextKey != key && !ImGui::IsAnyItemActive()) {
                u.eventTextKey = key;
                u.eventText = ev.name;
                u.eventData = ev.data.is_object() && !ev.data.empty() ? ev.data.dump() : std::string();
                u.eventTime = ev.t;
                u.eventDataError.clear();
            }
            ImGui::SetNextItemWidth(-60);
            ImGui::InputText("name##a3_evname", &u.eventText);
            at_track("a3:event:name");
            if (ImGui::IsItemDeactivatedAfterEdit() && !u.eventText.empty()) anim3d_commit(m.set_event(u.selectedEvent, Json::object({{"name", u.eventText}})));
            ImGui::SetNextItemWidth(110);
            ImGui::InputFloat("time (s)##a3_evtime", &u.eventTime, 0, 0, "%.3f");
            at_track("a3:event:time");
            if (ImGui::IsItemDeactivatedAfterEdit()) anim3d_commit(m.set_event(u.selectedEvent, Json::object({{"t", double(std::clamp(u.eventTime, 0.0f, clip->duration))}})));
            ImGui::SetNextItemWidth(-60);
            ImGui::InputText("data##a3_evdata", &u.eventData);
            at_track("a3:event:data");
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("A JSON object sent with the event, e.g. {\"foot\":\"left\"}.");
            if (ImGui::IsItemDeactivatedAfterEdit()) {
                Json data = Json::object();
                bool good = true;
                if (!trim(u.eventData).empty()) {
                    auto parsed = Json::parse(u.eventData, nullptr, false);
                    if (parsed.is_discarded() || !parsed.is_object()) good = false;
                    else data = parsed;
                }
                if (good) {
                    u.eventDataError.clear();
                    anim3d_commit(m.set_event(u.selectedEvent, Json::object({{"data", data}})));
                } else {
                    u.eventDataError = "The data must be a JSON object, e.g. {\"foot\":\"left\"}.";
                }
            }
            if (!u.eventDataError.empty()) ImGui::TextColored(kBad, "%s", u.eventDataError.c_str());
            if (ImGui::Button("Remove event")) {
                anim3d_commit(m.remove_event(u.selectedEvent));
                u.selectedEvent = -1;
            }
            at_track("a3:event:remove");
        }
        ImGui::SetNextItemWidth(110);
        ImGui::InputText("##a3_evnew", &u.eventName);
        at_track("a3:event:newname");
        ImGui::SameLine();
        if (ImGui::Button("Add at playhead") && !u.eventName.empty()) {
            const double t = anim3d_snap(u.playhead);
            const Anim3DEdit e = m.add_event(t, u.eventName);
            anim3d_commit(e);
            if (e.ok && m.clip()) {
                u.selectedEvent = -1;
                for (std::size_t i = 0; i < m.clip()->events.size(); ++i)
                    if (std::fabs(double(m.clip()->events[i].t) - t) < 0.0006 && m.clip()->events[i].name == u.eventName) u.selectedEvent = int(i);
            }
        }
        at_track("a3:event:add");
    }

    // ---- generate / retarget
    const std::string rigPath = m.rig_path();
    const std::string rigStem = stem_of(rigPath.empty() ? clip->rig : rigPath);
    const bool generateOpen = ImGui::CollapsingHeader("Generate a clip");
    at_track("a3:section:generate");
    if (ImGui::IsItemToggledOpen()) ImGui::SetScrollHereY(0.0f);   // a form that just opened is brought into view
    if (generateOpen) {
        if (rigPath.empty()) {
            ImGui::TextDisabled("Needs the baked rig: choose one in the toolbar.");
        } else {
            const auto& kinds = anim3d_generator_kinds();
            ImGui::SetNextItemWidth(-1);
            if (ImGui::BeginCombo("##a3_kind", u.kind.c_str())) {
                for (const std::string& k : kinds) {
                    if (ImGui::Selectable(k.c_str(), k == u.kind)) {
                        u.kind = k;
                        u.generateOutEdited = false;
                    }
                    at_track("a3:kind:" + k);
                }
                ImGui::EndCombo();
            }
            at_track("a3:kind");
            if (!u.generateOutEdited) u.generateOut = "anim/" + rigStem + "_" + u.kind + ".anim.json";
            ImGui::SetNextItemWidth(-1);
            if (ImGui::InputText("##a3_genout", &u.generateOut)) u.generateOutEdited = true;
            at_track("a3:genout");
            ImGui::SetNextItemWidth(-1);
            ImGui::InputTextWithHint("##a3_genparams", "parameters as JSON, e.g. {\"duration\":1}", &u.generateParams);
            at_track("a3:genparams");
            ImGui::Checkbox("replace the file if it exists##a3_genreplace", &u.replaceOutput);
            at_track("a3:genreplace");
            std::string problem;
            Json params = Json::object();
            if (!trim(u.generateParams).empty()) {
                auto parsed = Json::parse(u.generateParams, nullptr, false);
                if (parsed.is_discarded() || !parsed.is_object()) problem = "The parameters must be a JSON object.";
                else params = parsed;
            }
            if (!problem.empty()) ImGui::TextColored(kBad, "%s", problem.c_str());
            ImGui::BeginDisabled(!problem.empty() || u.generateOut.empty());
            if (ImGui::Button("Generate")) {
                const std::string out = u.generateOut;
                const Anim3DEdit e = m.generate(u.kind, params, out, u.replaceOutput);
                anim3d_commit(e);
                if (e.ok) {
                    open_anim3d_clip(out, rigPath);
                    ImGui::EndDisabled();
                    return;   // the clip on show is another one now
                }
            }
            at_track("a3:generate", problem.empty() && !u.generateOut.empty());
            ImGui::EndDisabled();
            if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("anim3d.generate: writes the clip with the rig's bones and opens it. Undo deletes the file again.");
        }
    }
    const bool retargetOpen = ImGui::CollapsingHeader("Retarget to another rig");
    at_track("a3:section:retarget");
    if (ImGui::IsItemToggledOpen()) ImGui::SetScrollHereY(0.0f);   // a form that just opened is brought into view
    if (retargetOpen) {
        if (rigPath.empty()) {
            ImGui::TextDisabled("Needs the baked rig the clip is for.");
        } else {
            if (u.rigList.empty() && ImGui::IsWindowAppearing()) anim3d_scan_lists();
            ImGui::SetNextItemWidth(-1);
            if (ImGui::BeginCombo("##a3_retargetto", u.retargetTo.empty() ? "(target rig)" : u.retargetTo.c_str())) {
                anim3d_scan_lists();
                for (const std::string& r : u.rigList) {
                    if (r == rigPath) continue;
                    if (ImGui::Selectable(r.c_str(), r == u.retargetTo)) {
                        u.retargetTo = r;
                        u.retargetOutEdited = false;
                    }
                    at_track("a3:retargetrig:" + r);
                }
                ImGui::EndCombo();
            }
            at_track("a3:retargetto");
            const std::string stem = stem_of(clip->path);
            if (!u.retargetOutEdited) u.retargetOut = "anim/" + stem + "_" + stem_of(u.retargetTo) + ".anim.json";
            ImGui::SetNextItemWidth(-1);
            if (ImGui::InputText("##a3_retout", &u.retargetOut)) u.retargetOutEdited = true;
            at_track("a3:retout");
            ImGui::BeginDisabled(u.retargetTo.empty() || u.retargetOut.empty());
            if (ImGui::Button("Retarget")) {
                const std::string out = u.retargetOut, to = u.retargetTo;
                const Anim3DEdit e = m.retarget(to, out, u.replaceOutput);
                anim3d_commit(e);
                if (e.ok) {
                    open_anim3d_clip(out, to);
                    ImGui::EndDisabled();
                    return;
                }
            }
            at_track("a3:retarget", !u.retargetTo.empty() && !u.retargetOut.empty());
            ImGui::EndDisabled();
            if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("anim3d.retarget: carries the clip over to the rig by bone role, keeping the feet planted through the stance bars.");
        }
    }
}

// -------------------------------------------------------------------------------------------------------------- the sheets --
void Editor::anim3d_load_sheet(Anim3DUi::Sheet& sheet, const std::string& what, const Json& result) {
    Anim3DUi& u = anim3d_;
    sheet.what = what;
    sheet.error.clear();
    sheet.note.clear();
    sheet.clip = u.model ? u.model->path() : std::string();
    sheet.revision = u.model ? u.model->revision() : 0;
    if (!result.is_object() || !result.contains("$image") || !result["$image"].is_object() || !result["$image"].contains("path")) {
        sheet.error = "The command returned no picture.";
        return;
    }
    const stdfs::path file = result["$image"]["path"].get<std::string>();
    const bool temporary = result["$image"].value("temporary", false);
    std::ifstream in(file, std::ios::binary);
    std::vector<std::uint8_t> bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    in.close();
    if (temporary) {
        std::error_code ec;
        stdfs::remove(file, ec);
    }
    auto img = decode_image(bytes.data(), bytes.size());
    if (!img.ok()) {
        sheet.error = "Cannot read the picture: " + img.error().message;
        return;
    }
    if (!put_texture(sheet.tex, u.graveyard, *img, uiFrame_)) {
        sheet.error = "Cannot show the picture (no graphics device).";
        return;
    }
    if (result.contains("quality")) sheet.note = result["quality"].dump();
    u.showSheets = true;
    u.sheetTab = what == "weights" ? 1 : 0;
}

void Editor::anim3d_show_filmstrip() {
    Anim3DUi& u = anim3d_;
    Anim3DModel& m = *u.model;
    if (!m.is_open() || m.rig_path().empty()) {
        u.status = "The filmstrip needs the baked rig the clip is for.";
        return;
    }
    const std::string clipPath = m.path();
    const std::uint64_t revision = m.revision();
    const Json args = Json::object({{"path", clipPath}, {"rig", m.rig_path()}, {"frames", 6}, {"cell", 150}, {"yaws", Json::array({-70, 0, 90})}});
    CommandResult r = engine_->commands().call("anim3d.preview", args);
    // The command is synchronous: the clip on show is the one it drew (checked all the same, as a result that outlives its clip would mislead).
    if (!m.is_open() || m.path() != clipPath || m.revision() != revision) return;
    if (!r.ok) {
        u.film.error = "anim3d.preview: " + command_error_text(r.error);
        u.film.what = "filmstrip";
        u.film.clip = clipPath;
        u.showSheets = true;
        u.sheetTab = 0;
        return;
    }
    anim3d_load_sheet(u.film, "filmstrip", r.result);
}

void Editor::anim3d_show_weights() {
    Anim3DUi& u = anim3d_;
    Anim3DModel& m = *u.model;
    const std::string doc = rig_document_of(projectDir_, m.rig_path());
    if (doc.empty()) {
        u.status = "The weights come from the rig document (name.rig.json) next to the baked rig.";
        return;
    }
    const std::string clipPath = m.path();
    const std::uint64_t revision = m.revision();
    Json args = Json::object({{"path", doc}, {"views", 3}, {"cell", 200}});
    const bool oneBone = !u.bone.empty() && m.node_of(u.bone) >= 0;
    if (oneBone) args["bone"] = u.bone;
    CommandResult r = engine_->commands().call("skin3d.preview", args);
    if (!m.is_open() || m.path() != clipPath || m.revision() != revision) return;
    if (!r.ok) {
        u.weights.error = "skin3d.preview: " + command_error_text(r.error);
        u.weights.what = "weights";
        u.weights.clip = clipPath;
        u.showSheets = true;
        u.sheetTab = 1;
        return;
    }
    anim3d_load_sheet(u.weights, "weights", r.result);
    u.weights.note = oneBone ? "weights of " + u.bone : "one colour per bone";
}

void Editor::draw_anim3d_sheets() {
    Anim3DUi& u = anim3d_;
    ImGui::SetNextWindowSize(ImVec2(760, 520), ImGuiCond_FirstUseEver);
    bool open = true;
    if (ImGui::Begin("Animation sheets", &open)) {
        const std::string current = u.model ? u.model->path() : std::string();
        const std::uint64_t revision = u.model ? u.model->revision() : 0;
        if (ImGui::BeginTabBar("##a3_sheets")) {
            struct Part {
                const char* title;
                Anim3DUi::Sheet* sheet;
                int index;
            };
            for (const Part& part : {Part{"Filmstrip", &u.film, 0}, Part{"Weights", &u.weights, 1}}) {
                Anim3DUi::Sheet& s = *part.sheet;
                const bool select = u.sheetTab == part.index;
                if (ImGui::BeginTabItem(part.title, nullptr, select ? ImGuiTabItemFlags_SetSelected : 0)) {
                    if (!select) u.sheetTab = part.index;
                    u.sheetTab = part.index;
                    ImGui::PushID(part.index);
                    if (s.what.empty()) {
                        ImGui::TextDisabled("Nothing drawn yet: use the %s button in the toolbar.", part.index == 0 ? "Filmstrip" : "Weights");
                    } else {
                        if (!s.clip.empty() && s.clip != current) ImGui::TextColored(kWarn, "This is the picture of %s, not the clip on show.", s.clip.c_str());
                        else if (s.revision != revision && part.index == 0) ImGui::TextColored(kWarn, "The clip changed since this picture was made: press Filmstrip again.");
                        if (!s.note.empty()) ImGui::TextDisabled("%s", s.note.c_str());
                        if (!s.error.empty()) ImGui::TextColored(kBad, "%s", s.error.c_str());
                        if (s.tex.view) {
                            const ImVec2 room = ImGui::GetContentRegionAvail();
                            const float scale = std::min(1.0f, std::min(room.x / float(s.tex.w), room.y / float(s.tex.h)));
                            ImGui::Image(ImTextureRef(ImTextureID(ui::texture_from_view(s.tex.view, true))), ImVec2(float(s.tex.w) * scale, float(s.tex.h) * scale));
                            at_track(part.index == 0 ? "a3:sheet:filmstrip" : "a3:sheet:weights");
                        }
                    }
                    ImGui::PopID();
                    ImGui::EndTabItem();
                }
            }
            ImGui::EndTabBar();
        }
    }
    ImGui::End();
    if (!open) u.showSheets = false;
}

}  // namespace fa::editor
