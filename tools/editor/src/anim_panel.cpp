// The Animation panel (View > Animation): the clips of the selected entity's Animator as a dopesheet (one row per part and
// field) or as curves, a time ruler to scrub, event markers, record mode and the onion skin switch. Everything it changes goes
// through anim.* commands (anim_edit in anim_edit.cpp), so an AI can make the same edit, and a drag of keys is ONE command.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>

#include "editor_internal.h"
#include "fa/scene/animation.h"
#include "imgui_internal.h"

namespace fa::editor {

namespace {

constexpr float kLeft = 230.0f;   // width of the track names
constexpr float kRow = 20.0f;
constexpr float kRuler = 22.0f;
constexpr float kLane = 18.0f;    // the event markers' strip under the ruler
constexpr float kPick = 6.0f;     // pixels around a key that still hit it
constexpr float kHandle = 40.0f;  // length of a bezier tangent handle, in pixels

const ImU32 kPlayhead = IM_COL32(255, 80, 70, 255);
const ImU32 kKeyColor = IM_COL32(215, 215, 220, 255);
const ImU32 kKeySelected = IM_COL32(255, 190, 60, 255);

ImU32 channel_color(const ClipTrack& tr, int c) {
    static const ImU32 xyz[4] = {IM_COL32(235, 90, 80, 255), IM_COL32(110, 210, 110, 255), IM_COL32(100, 150, 240, 255),
                                 IM_COL32(200, 200, 200, 255)};
    if (tr.channel < 0 && tr.channels == 1) return IM_COL32(230, 200, 90, 255);
    return xyz[std::clamp(tr.channel >= 0 ? tr.channel : c, 0, 3)];
}

// A key's shape tells how it reaches the next one: diamond = linear, square = step, circle = bezier, hexagon = easing.
void draw_key(ImDrawList* dl, ImVec2 p, const ClipKey& k, bool stepped, bool selected, bool ghost) {
    const ImU32 fill = ghost ? IM_COL32(255, 190, 60, 90) : (selected ? kKeySelected : kKeyColor);
    const ImU32 edge = IM_COL32(20, 20, 24, 255);
    const float r = 5.0f;
    if (stepped || k.interp == ClipInterp::Step) {
        dl->AddRectFilled(ImVec2(p.x - r + 1, p.y - r + 1), ImVec2(p.x + r - 1, p.y + r - 1), fill);
        dl->AddRect(ImVec2(p.x - r + 1, p.y - r + 1), ImVec2(p.x + r - 1, p.y + r - 1), edge);
    } else if (k.interp == ClipInterp::Bezier) {
        dl->AddCircleFilled(p, r, fill);
        dl->AddCircle(p, r, edge);
    } else if (k.interp == ClipInterp::Ease) {
        dl->AddNgonFilled(p, r + 1, fill, 6);
        dl->AddNgon(p, r + 1, edge, 6);
    } else {
        dl->AddQuadFilled(ImVec2(p.x, p.y - r), ImVec2(p.x + r, p.y), ImVec2(p.x, p.y + r), ImVec2(p.x - r, p.y), fill);
        dl->AddQuad(ImVec2(p.x, p.y - r), ImVec2(p.x + r, p.y), ImVec2(p.x, p.y + r), ImVec2(p.x - r, p.y), edge);
    }
}

long long ms_of(double t) { return std::llround(t * 1000.0); }

struct RowInfo {
    int group = 0;
    int track = -1;  // -1 = the header of the part
};

// One thing a click can pick: the keys it stands for (a header row stands for every track's key at that time).
struct Hit {
    std::vector<KeyId> ids;
    ImVec2 pos;
    int channel = 0;
};

}  // namespace

// ---------------------------------------------------------------------------------------------------------- the panel --
void Editor::draw_animation_panel() {
    if (ImGuiWindow* console = ImGui::FindWindowByName("Console"); console && console->DockId != 0)
        ImGui::SetNextWindowDockID(console->DockId, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(980, 340), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Animation", &showAnimation_)) {
        ImGui::End();
        return;
    }
    AnimUi& u = anim_;
    if (play_ != PlayState::Edit) {
        ImGui::TextDisabled("The game is running. Stop it to edit clips (a clip file is not part of the running scene).");
        ImGui::End();
        return;
    }
    anim_refresh_owner();
    const Entity owner = anim_owner();
    if (owner.is_null()) {
        const Entity sel = selected();
        if (sel.is_null()) {
            ImGui::TextDisabled("Select an entity that has an Animator, or one of its parts, to edit its clips.");
        } else {
            ImGui::TextWrapped("'%s' and its parents have no Animator. An Animator plays the clips in anim/*.anim.json.",
                               world().info(sel).name.c_str());
            if (ImGui::Button("Add an Animator to it")) {
                std::string err;
                const CommandResult r = edit_command("anim:addanimator:" + std::to_string(uiFrame_), "scene.set_component",
                                                     Json::object({{"id", world().id_of(sel)}, {"component", "Animator"}, {"fields", Json::object()}}), &err);
                if (!r.ok) notify("Could not add an Animator: " + err, 2);
            }
            at_track("anim:addanimator");
        }
        ImGui::End();
        return;
    }

    const std::string path = anim_clip_path();
    std::shared_ptr<const ClipAsset> clip;
    if (!path.empty()) {
        auto loaded = load_anim_clip(path);
        if (loaded.ok()) clip = *loaded;
        else u.error = loaded.error().to_string();
    }
    // The preview plays by moving the playhead; nothing runs in the engine.
    if (u.playing && clip) {
        double t = u.playhead + double(ImGui::GetIO().DeltaTime) * double(u.speed);
        if (t >= double(clip->duration)) {
            if (u.loopPreview && clip->duration > 0) t = std::fmod(t, double(clip->duration));
            else {
                t = double(clip->duration);
                u.playing = false;
            }
        }
        u.playhead = clip_round_time(t);
        u.dirtyPose = true;
    }
    draw_anim_toolbar(clip, path);
    if (clip) draw_anim_time_area(clip, path);
    else ImGui::TextDisabled("This Animator has no clip yet. New clip makes anim/<name>.anim.json and lists it in Animator.clips.");
    anim_event_popups(path);
    if (!u.error.empty()) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", u.error.c_str());

    if (clip && (u.dirtyPose || !u.posed || u.posedGeneration != world().scene_generation())) {
        if (u.posed || u.error.empty()) anim_pose();
    }
    ImGui::End();
}

// Puts the next item of about `width` pixels on the line of the last one when it fits in the window, on a new line otherwise (the
// panel is often narrow: a toolbar that runs off its right edge hides Record and Onion).
static void anim_flow(float width) {
    const float right = ImGui::GetWindowPos().x + ImGui::GetWindowWidth() - ImGui::GetStyle().WindowPadding.x;
    if (ImGui::GetItemRectMax().x + ImGui::GetStyle().ItemSpacing.x + width <= right) ImGui::SameLine();
}
static float anim_button_width(const char* label) { return ImGui::CalcTextSize(label).x + ImGui::GetStyle().FramePadding.x * 2.0f; }
static float anim_check_width(const char* label) {
    return ImGui::CalcTextSize(label).x + ImGui::GetFrameHeight() + ImGui::GetStyle().ItemInnerSpacing.x;
}

void Editor::draw_anim_toolbar(const std::shared_ptr<const ClipAsset>& clip, const std::string& path) {
    AnimUi& u = anim_;
    const Entity owner = anim_owner();
    const Animator* animator = world().get<Animator>(owner);
    ImGui::AlignTextToFramePadding();
    ImGui::TextDisabled("%s", world().info(owner).name.c_str());
    ImGui::SameLine();
    ImGui::SetNextItemWidth(130);
    if (ImGui::BeginCombo("##animclip", u.clipName.empty() ? "(no clip)" : u.clipName.c_str())) {
        if (animator && animator->clips.is_object())
            for (auto it = animator->clips.begin(); it != animator->clips.end(); ++it) {
                if (ImGui::Selectable(it.key().c_str(), it.key() == u.clipName)) anim_select_clip(it.key());
                at_track("anim:clip:" + it.key());
            }
        ImGui::EndCombo();
    }
    at_track("anim:clips");
    ImGui::SetItemTooltip("The clips of this Animator (Animator.clips)");
    ImGui::SameLine();
    if (ImGui::Button("New clip")) {
        std::vector<std::string> names;
        if (animator && animator->clips.is_object())
            for (auto it = animator->clips.begin(); it != animator->clips.end(); ++it) names.push_back(it.key());
        u.newClipName = unique_name(names, "clip");
        ImGui::OpenPopup("##animnewclip");
    }
    at_track("anim:newclip");
    ImGui::SetItemTooltip("Make an empty clip: anim/<name>.anim.json, listed in Animator.clips");
    if (ImGui::BeginPopup("##animnewclip")) {
        ImGui::TextDisabled("New clip");
        if (ImGui::IsWindowAppearing()) ImGui::SetKeyboardFocusHere();
        ImGui::SetNextItemWidth(180);
        ImGui::InputText("name", &u.newClipName);
        at_track("anim:newclip:name");
        ImGui::SetNextItemWidth(180);
        ImGui::DragFloat("seconds", &u.newClipDuration, 0.05f, 0.1f, 600.0f, "%.2f");
        ImGui::Checkbox("loops", &u.newClipLoop);
        if (ImGui::Button("Create")) {
            std::string err;
            if (anim_new_clip(u.newClipName, double(std::max(0.1f, u.newClipDuration)), u.newClipLoop, &err)) ImGui::CloseCurrentPopup();
        }
        at_track("anim:newclip:create");
        if (!u.error.empty()) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", u.error.c_str());
        ImGui::EndPopup();
    }
    if (!clip) return;

    anim_flow(anim_button_width("Pause"));
    if (ImGui::Button(u.playing ? "Pause" : "Play")) {
        if (!u.playing && u.playhead >= double(clip->duration) - 1e-6) anim_set_playhead(0);
        u.playing = !u.playing;
    }
    at_track("anim:play");
    ImGui::SetItemTooltip("Preview the clip in the viewport (Space). Nothing is saved: the entity goes back to its rest pose");
    anim_flow(anim_button_width("|<"));
    if (ImGui::Button("|<")) {
        u.playing = false;
        anim_set_playhead(0);
    }
    at_track("anim:rewind");
    ImGui::SetItemTooltip("Back to the start (Home)");
    anim_flow(anim_check_width("Loop"));
    ImGui::Checkbox("Loop", &u.loopPreview);
    at_track("anim:loop");
    ImGui::SetItemTooltip("Preview again from the start at the end of the clip");
    anim_flow(64.0f);
    ImGui::SetNextItemWidth(64);
    ImGui::DragFloat("##animspeed", &u.speed, 0.01f, 0.1f, 4.0f, "x%.2f");
    ImGui::SetItemTooltip("Preview speed");
    anim_flow(110.0f);
    ImGui::AlignTextToFramePadding();
    ImGui::Text("%.3fs  f%lld", u.playhead, std::llround(u.playhead * u.fps));

    // next line: the time grid, record mode, onion skin, the curve view
    anim_flow(74.0f);
    ImGui::SetNextItemWidth(74);
    if (ImGui::BeginCombo("##animfps", std::format("{} fps", u.fps).c_str())) {
        for (int f : {12, 24, 30, 60})
            if (ImGui::Selectable(std::format("{} fps", f).c_str(), f == u.fps)) u.fps = f;
        ImGui::EndCombo();
    }
    at_track("anim:fps");
    ImGui::SetItemTooltip("The frame rate of the time grid. Clips are in seconds: this only sets where snapping puts keys");
    anim_flow(anim_check_width("Snap"));
    ImGui::Checkbox("Snap", &u.snap);
    at_track("anim:snap");
    ImGui::SetItemTooltip("Scrubbing, dragging keys and events land on whole frames");

    anim_flow(anim_button_width("REC (on)"));
    const bool rec = u.recording;
    if (rec) {
        ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.75f, 0.12f, 0.1f, 1));
        ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.85f, 0.2f, 0.18f, 1));
    }
    if (ImGui::Button(rec ? "REC (on)" : "REC")) u.recording = !u.recording;
    if (rec) ImGui::PopStyleColor(2);
    at_track("anim:record");
    ImGui::SetItemTooltip("Record mode: moving, rotating or scaling a part with the gizmo, or changing an animatable field in the "
                          "Inspector, writes a key at the playhead instead of changing the rest value");
    anim_flow(anim_check_width("Onion"));
    ImGui::Checkbox("Onion", &u.onion);
    at_track("anim:onion");
    ImGui::SetItemTooltip("Show faded poses before (red) and after (green) the playhead in the viewport");
    if (u.onion) {
        anim_flow(46.0f);
        ImGui::SetNextItemWidth(46);
        ImGui::DragInt("##onb", &u.onionBefore, 0.1f, 0, 6, "-%d");
        ImGui::SetItemTooltip("Poses before the playhead");
        anim_flow(46.0f);
        ImGui::SetNextItemWidth(46);
        ImGui::DragInt("##ona", &u.onionAfter, 0.1f, 0, 6, "+%d");
        ImGui::SetItemTooltip("Poses after the playhead");
        anim_flow(56.0f);
        ImGui::SetNextItemWidth(56);
        ImGui::DragInt("##onf", &u.onionFrames, 0.1f, 1, 30, "%df");
        ImGui::SetItemTooltip("Frames between two ghost poses");
    }
    anim_flow(anim_check_width("Curves"));
    ImGui::Checkbox("Curves", &u.curves);
    at_track("anim:curves");
    ImGui::SetItemTooltip("Edit the selected tracks as curves (bezier keys show tangent handles) instead of the dopesheet");

    // third line: the clip itself
    float dur = clip->duration;
    ImGui::AlignTextToFramePadding();
    ImGui::TextDisabled("%s", path.c_str());
    anim_flow(80.0f);
    ImGui::SetNextItemWidth(80);
    ImGui::DragFloat("##animdur", &dur, 0.05f, 0.1f, 600.0f, "%.2fs");
    at_track("anim:duration");
    if (ImGui::IsItemDeactivatedAfterEdit())
        (void)anim_edit("anim:duration", {{"anim.set_clip", Json::object({{"path", path}, {"duration", double(dur)}})}});
    ImGui::SetItemTooltip("Length of the clip. Shorter than its last key or event is refused");
    anim_flow(anim_check_width("clip loops"));
    bool loops = clip->loop;
    if (ImGui::Checkbox("clip loops", &loops))
        (void)anim_edit("anim:cliploop:" + std::to_string(uiFrame_), {{"anim.set_clip", Json::object({{"path", path}, {"loop", loops}})}});
    at_track("anim:cliploop");
    ImGui::SetItemTooltip("The clip's own loop flag, the default of the Animator (a state's loop overrides it)");
    anim_flow(anim_button_width("Add event"));
    if (ImGui::Button("Add event")) {
        u.eventEditing = -1;
        u.eventAt = u.playhead;
        u.eventName = "event";
        ImGui::OpenPopup("##animevent");
    }
    at_track("anim:addevent");
    ImGui::SetItemTooltip("Add a named marker at the playhead: the Animator sends it as an event when the clip passes it");
    anim_flow(anim_button_width("Fit"));
    if (ImGui::Button("Fit")) u.fitNext = true;
    at_track("anim:fit");
    ImGui::SetItemTooltip("Zoom the time axis to the whole clip (Ctrl+wheel zooms, Shift+wheel or middle-drag pans)");
    if (u.recording) {
        anim_flow(200.0f);
        ImGui::AlignTextToFramePadding();
        ImGui::TextColored(ImVec4(1, 0.4f, 0.35f, 1), "Recording: %d key%s written", u.recordedKeys, u.recordedKeys == 1 ? "" : "s");
    }
}

// ----------------------------------------------------------------------------------------------------- event popups --
void Editor::anim_event_popups(const std::string& path) {
    AnimUi& u = anim_;
    if (!ImGui::BeginPopup("##animevent")) return;
    ImGui::TextDisabled(u.eventEditing < 0 ? "Add an event" : "Event");
    if (ImGui::IsWindowAppearing()) ImGui::SetKeyboardFocusHere();
    ImGui::SetNextItemWidth(200);
    const bool enter = ImGui::InputText("name", &u.eventName, ImGuiInputTextFlags_EnterReturnsTrue);
    at_track("anim:event:name");
    if (u.eventEditing < 0) {
        float at = float(u.eventAt);
        ImGui::SetNextItemWidth(200);
        if (ImGui::DragFloat("at (s)", &at, 0.01f, 0.0f, 600.0f, "%.3f")) u.eventAt = at;
        at_track("anim:event:at");
    }
    const bool ok = ImGui::Button(u.eventEditing < 0 ? "Add" : "Rename") || enter;
    at_track("anim:event:ok");
    if (ok && !u.eventName.empty() && !path.empty()) {
        if (u.eventEditing < 0) {
            if (anim_edit("anim:event:add:" + std::to_string(uiFrame_),
                          {{"anim.add_event", Json::object({{"path", path}, {"t", clip_round_time(u.eventAt)}, {"name", u.eventName}, {"extendDuration", true}})}}))
                ImGui::CloseCurrentPopup();
        } else if (anim_edit("anim:event:rename:" + std::to_string(uiFrame_),
                             {{"anim.set_event", Json::object({{"path", path}, {"event", u.eventEditing}, {"name", u.eventName}})}})) {
            ImGui::CloseCurrentPopup();
        }
    }
    if (u.eventEditing >= 0) {
        ImGui::SameLine();
        if (ImGui::Button("Delete")) {
            if (anim_edit("anim:event:delete:" + std::to_string(uiFrame_),
                          {{"anim.remove_event", Json::object({{"path", path}, {"event", u.eventEditing}})}})) {
                u.selectedEvent = -1;
                ImGui::CloseCurrentPopup();
            }
        }
        at_track("anim:event:delete");
    }
    ImGui::EndPopup();
}

// -------------------------------------------------------------------------------------------------------- key menu --
void Editor::anim_key_menu(const std::shared_ptr<const ClipAsset>& clip, const std::string& path) {
    AnimUi& u = anim_;
    if (!ImGui::BeginPopup("##animkeymenu")) return;
    const bool any = !u.selection.empty();
    ImGui::TextDisabled("%zu key%s", u.selection.size(), u.selection.size() == 1 ? "" : "s");
    ImGui::Separator();
    auto interp = [&](const char* label, const std::string& name) {
        if (ImGui::MenuItem(label, nullptr, false, any)) {
            if (anim_edit("anim:interp:" + std::to_string(uiFrame_), {set_interp_call(path, u.selection, name)}))
                ImGui::CloseCurrentPopup();
        }
        at_track("anim:menu:" + name);
    };
    interp("Linear", "linear");
    interp("Step (hold)", "step");
    interp("Bezier (curve)", "bezier");
    if (ImGui::BeginMenu("Easing", any)) {
        for (const std::string& n : clip_ease_names()) {
            if (n == "linear") continue;
            if (ImGui::MenuItem(n.c_str())) {
                if (anim_edit("anim:interp:" + std::to_string(uiFrame_), {set_interp_call(path, u.selection, n)})) ImGui::CloseCurrentPopup();
            }
            at_track("anim:menu:ease:" + n);
        }
        ImGui::EndMenu();
    }
    at_track("anim:menu:easing");
    ImGui::Separator();
    if (ImGui::MenuItem("Copy", "Ctrl+C", false, any)) u.clipboard = copy_keys(*clip, u.selection);
    at_track("anim:menu:copy");
    if (ImGui::MenuItem("Paste at playhead", "Ctrl+V", false, !u.clipboard.empty())) {
        const double at = u.snap ? snap_to_frames(u.playhead, u.fps) : u.playhead;
        const KeySet pasted = pasted_selection(*clip, u.clipboard, at);
        if (anim_edit("anim:paste:" + std::to_string(uiFrame_), paste_keys_calls(path, u.clipboard, at))) u.selection = pasted;
    }
    at_track("anim:menu:paste");
    if (ImGui::MenuItem("Delete", "Del", false, any)) {
        if (anim_edit("anim:delete:" + std::to_string(uiFrame_), delete_keys_calls(path, *clip, u.selection))) u.selection.clear();
    }
    at_track("anim:menu:delete");
    ImGui::EndPopup();
}

// -------------------------------------------------------------------------------------------------------- time area --
void Editor::draw_anim_time_area(const std::shared_ptr<const ClipAsset>& clipPtr, const std::string& path) {
    AnimUi& u = anim_;
    const ClipAsset& clip = *clipPtr;
    const ImGuiIO& io = ImGui::GetIO();
    const ImVec2 origin = ImGui::GetCursorScreenPos();
    ImVec2 avail = ImGui::GetContentRegionAvail();
    avail.y = std::max(avail.y, 120.0f);
    const float x0 = origin.x + kLeft, x1 = origin.x + avail.x - 4.0f;
    u.timeX0 = x0;
    u.timeX1 = x1;
    if (u.fitNext) {
        u.pps = std::clamp((x1 - x0 - 24.0f) / std::max(0.1f, clip.duration), 8.0f, 4000.0f);
        u.viewStart = -12.0 / double(u.pps);
        u.fitNext = false;
    }
    ImDrawList* wdl = ImGui::GetWindowDrawList();
    const float yRuler = origin.y, yLane = yRuler + kRuler, yRows = yLane + kLane;
    u.rulerY = yRuler + kRuler * 0.5f;
    u.rowsY0 = yRows;
    const float rowsH = std::max(40.0f, origin.y + avail.y - yRows - 2.0f);

    // ---- drag in progress: update (the release is handled at the end)
    const ImVec2 mouse = io.MousePos;
    const double mouseT = anim_x_to_time(mouse.x);
    if (u.drag != AnimUi::Drag::None && std::fabs(mouse.x - u.dragStartX) + std::fabs(mouse.y - u.dragStartY) > 3.0f) u.dragMoved = true;
    switch (u.drag) {
        case AnimUi::Drag::Scrub:
            if (io.MouseDown[0]) {
                u.playing = false;
                anim_set_playhead(u.snap ? snap_to_frames(mouseT, u.fps) : mouseT);
            }
            break;
        case AnimUi::Drag::Keys:
        case AnimUi::Drag::Value:
            u.dragOffset = u.dragMoved ? snapped_move_offset(u.selection, mouseT - u.dragPressT, u.snap ? u.fps : 0)
                                       : 0.0;
            break;
        case AnimUi::Drag::Scale: {
            const double e = earliest_time(u.selection);
            const double den = u.dragPressT - e;
            u.dragScale = (u.dragMoved && den > 0.02) ? snapped_scale(u.selection, (mouseT - e) / den, u.snap ? u.fps : 0) : 1.0;
            break;
        }
        case AnimUi::Drag::Event:
            u.dragEventTo = std::max(0.0, u.snap ? snap_to_frames(mouseT, u.fps) : mouseT);
            break;
        case AnimUi::Drag::Pan:
            u.viewStart -= double(io.MouseDelta.x) / double(u.pps);
            break;
        default:
            break;
    }
    if (u.drag == AnimUi::Drag::Pan && !io.MouseDown[2]) u.drag = AnimUi::Drag::None;

    // ---- zoom and pan with the mouse over the time area
    const bool overTime = mouse.x >= x0 && mouse.x <= x1 && mouse.y >= yRuler && mouse.y <= yRows + rowsH && ImGui::IsWindowHovered();
    if (overTime && io.MouseWheel != 0 && io.KeyCtrl) {
        const double at = anim_x_to_time(mouse.x);
        u.pps = std::clamp(u.pps * std::pow(1.15f, io.MouseWheel), 8.0f, 4000.0f);
        u.viewStart = at - double(mouse.x - x0) / double(u.pps);
    } else if (overTime && io.MouseWheel != 0 && io.KeyShift) {
        u.viewStart -= double(io.MouseWheel) * 40.0 / double(u.pps);
    }
    if (overTime && ImGui::IsMouseClicked(2) && u.drag == AnimUi::Drag::None) {
        u.drag = AnimUi::Drag::Pan;
        u.dragStartX = mouse.x;
        u.dragStartY = mouse.y;
    }

    // ---- ruler
    wdl->AddRectFilled(ImVec2(x0, yRuler), ImVec2(x1, yRows), IM_COL32(36, 38, 44, 255));
    wdl->AddRectFilled(ImVec2(origin.x, yRuler), ImVec2(x0, yRows), IM_COL32(30, 31, 36, 255));
    wdl->AddText(ImVec2(origin.x + 6, yRuler + 4), IM_COL32(150, 150, 160, 255), "Tracks");
    {
        wdl->PushClipRect(ImVec2(x0, yRuler), ImVec2(x1, yRows), true);
        static const double nice[] = {0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0};
        double major = 60.0;
        for (double n : nice)
            if (n * double(u.pps) >= 70.0) {
                major = n;
                break;
            }
        const double frame = 1.0 / double(std::max(1, u.fps));
        if (frame * double(u.pps) >= 5.0) {
            const long long f0 = std::max(0LL, (long long)std::floor(anim_x_to_time(x0) / frame));
            for (long long f = f0; f * frame <= anim_x_to_time(x1); ++f) {
                const float x = anim_time_to_x(double(f) * frame);
                wdl->AddLine(ImVec2(x, yLane - 5), ImVec2(x, yLane), IM_COL32(110, 110, 120, 255));
            }
        }
        const long long m0 = std::max(0LL, (long long)std::floor(anim_x_to_time(x0) / major));
        for (long long m = m0; double(m) * major <= anim_x_to_time(x1) + major; ++m) {
            const double t = double(m) * major;
            const float x = anim_time_to_x(t);
            wdl->AddLine(ImVec2(x, yRuler + 8), ImVec2(x, yLane), IM_COL32(170, 170, 180, 255));
            wdl->AddText(ImVec2(x + 3, yRuler + 1), IM_COL32(190, 190, 200, 255), std::format("{:g}s", t).c_str());
        }
        // the clip's length
        const float xe = anim_time_to_x(double(clip.duration));
        wdl->AddRectFilled(ImVec2(xe, yRuler), ImVec2(x1, yRows), IM_COL32(0, 0, 0, 70));
        wdl->AddLine(ImVec2(xe, yRuler), ImVec2(xe, yRows), IM_COL32(120, 160, 255, 200));
        wdl->PopClipRect();
    }
    ImGui::SetCursorScreenPos(ImVec2(x0, yRuler));
    ImGui::InvisibleButton("##animruler", ImVec2(std::max(1.0f, x1 - x0), kRuler));
    at_track_at("anim:ruler", Vec2{(x0 + x1) * 0.5f, yRuler + kRuler * 0.5f});
    if (ImGui::IsItemHovered() && ImGui::IsMouseClicked(0) && u.drag == AnimUi::Drag::None) {
        u.drag = AnimUi::Drag::Scrub;
        u.dragStartX = mouse.x;
        u.dragStartY = mouse.y;
        u.dragMoved = false;
        u.playing = false;
        anim_set_playhead(u.snap ? snap_to_frames(mouseT, u.fps) : mouseT);
    }
    ImGui::SetItemTooltip("Click or drag to scrub: the entity is posed in the viewport (the scene is not changed)");

    // ---- event lane
    wdl->AddRectFilled(ImVec2(x0, yLane), ImVec2(x1, yRows), IM_COL32(30, 32, 37, 255));
    wdl->AddText(ImVec2(origin.x + 6, yLane + 1), IM_COL32(150, 150, 160, 255), "Events");
    wdl->PushClipRect(ImVec2(x0, yLane), ImVec2(x1, yRows), true);
    for (std::size_t i = 0; i < clip.events.size(); ++i) {
        const double te = (u.drag == AnimUi::Drag::Event && u.dragEvent == int(i)) ? u.dragEventTo : double(clip.events[i].t);
        const float x = anim_time_to_x(te);
        const bool sel = u.selectedEvent == int(i);
        const ImU32 col = sel ? kKeySelected : IM_COL32(120, 200, 255, 255);
        wdl->AddTriangleFilled(ImVec2(x - 5, yLane + 2), ImVec2(x + 5, yLane + 2), ImVec2(x, yLane + 13), col);
        wdl->AddLine(ImVec2(x, yLane + 13), ImVec2(x, yRows), col);
        wdl->AddText(ImVec2(x + 7, yLane + 1), col, clip.events[i].name.c_str());
        at_track_at("anim:event:" + std::to_string(i), Vec2{x, yLane + 7});
    }
    wdl->PopClipRect();
    ImGui::SetCursorScreenPos(ImVec2(x0, yLane));
    ImGui::InvisibleButton("##animlane", ImVec2(std::max(1.0f, x1 - x0), kLane));
    const bool laneHover = ImGui::IsItemHovered();
    int laneHit = -1;
    if (laneHover) {
        float best = kPick + 2;
        for (std::size_t i = 0; i < clip.events.size(); ++i) {
            const float d = std::fabs(anim_time_to_x(double(clip.events[i].t)) - mouse.x);
            if (d < best) {
                best = d;
                laneHit = int(i);
            }
        }
    }
    if (laneHover && ImGui::IsMouseClicked(0) && u.drag == AnimUi::Drag::None) {
        u.selectedEvent = laneHit;
        if (laneHit >= 0) {
            u.selection.clear();
            u.drag = AnimUi::Drag::Event;
            u.dragEvent = laneHit;
            u.dragEventTo = double(clip.events[std::size_t(laneHit)].t);
            u.dragStartX = mouse.x;
            u.dragStartY = mouse.y;
            u.dragMoved = false;
        }
    }
    if (laneHover && ImGui::IsMouseDoubleClicked(0) && laneHit >= 0) {
        u.eventEditing = laneHit;
        u.eventName = clip.events[std::size_t(laneHit)].name;
        ImGui::OpenPopup("##animevent");
    }
    if (laneHover && ImGui::IsMouseClicked(1)) {
        u.selectedEvent = laneHit;
        if (laneHit >= 0) {
            u.eventEditing = laneHit;
            u.eventName = clip.events[std::size_t(laneHit)].name;
        } else {
            u.eventEditing = -1;
            u.eventName = "event";
            u.eventAt = u.snap ? snap_to_frames(mouseT, u.fps) : mouseT;
        }
        ImGui::OpenPopup("##animevent");
    }
    ImGui::SetItemTooltip("Event markers: drag to move, double-click to rename, right-click to add or delete");

    // ---- rows: the parts and their tracks
    const std::vector<TrackGroup> groups = group_tracks(clip);
    std::vector<RowInfo> rows;
    for (std::size_t g = 0; g < groups.size(); ++g) {
        rows.push_back({int(g), -1});
        if (!u.collapsed.count(groups[g].part))
            for (int tr : groups[g].tracks) rows.push_back({int(g), tr});
    }
    const float totalH = float(rows.size()) * kRow + 8.0f;
    const bool curves = u.curves;
    std::vector<Hit> hits;
    bool rightPressed = false;

    ImGui::SetCursorScreenPos(ImVec2(origin.x, yRows));
    if (curves) {
        // the tree on the left, the curves on the right
        ImGui::BeginChild("##animtree", ImVec2(kLeft, rowsH), ImGuiChildFlags_None);
    } else {
        ImGui::BeginChild("##animrows", ImVec2(x1 + 4.0f - origin.x, rowsH), ImGuiChildFlags_None);
    }
    {
        ImDrawList* dl = ImGui::GetWindowDrawList();
        const ImVec2 c0 = ImGui::GetCursorScreenPos();
        const float width = curves ? kLeft : (x1 + 4.0f - origin.x);
        ImGui::InvisibleButton("##animarea", ImVec2(width, std::max(totalH, rowsH - 2.0f)), ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight);
        const bool areaHover = ImGui::IsItemHovered();
        const bool leftClick = areaHover && ImGui::IsMouseClicked(0);
        const bool rightClick = areaHover && ImGui::IsMouseClicked(1);
        const ImVec2 clipMin = ImGui::GetWindowPos();
        const ImVec2 clipMax(clipMin.x + ImGui::GetWindowWidth(), clipMin.y + ImGui::GetWindowHeight());
        dl->PushClipRect(clipMin, clipMax, true);
        // track names (also in the curve view, where a click chooses which curves show)
        for (std::size_t i = 0; i < rows.size(); ++i) {
            const RowInfo& row = rows[i];
            const TrackGroup& g = groups[std::size_t(row.group)];
            const float y = c0.y + float(i) * kRow;
            if (y + kRow < clipMin.y || y > clipMax.y) continue;
            const bool header = row.track < 0;
            const ImU32 bg = header ? IM_COL32(44, 47, 56, 255) : ((i & 1) ? IM_COL32(33, 35, 40, 255) : IM_COL32(37, 39, 45, 255));
            dl->AddRectFilled(ImVec2(c0.x, y), ImVec2(curves ? c0.x + kLeft : x1, y + kRow), bg);
            const bool folded = u.collapsed.count(g.part) > 0;
            if (header) {
                const float ax = c0.x + 8, ay = y + kRow * 0.5f;
                if (folded) dl->AddTriangleFilled(ImVec2(ax - 3, ay - 5), ImVec2(ax - 3, ay + 5), ImVec2(ax + 4, ay), IM_COL32(200, 200, 210, 255));
                else dl->AddTriangleFilled(ImVec2(ax - 5, ay - 3), ImVec2(ax + 5, ay - 3), ImVec2(ax, ay + 4), IM_COL32(200, 200, 210, 255));
                dl->AddText(ImVec2(c0.x + 20, y + 3), IM_COL32(230, 230, 240, 255), g.title.c_str());
                at_track_at("anim:group:" + std::to_string(row.group), Vec2{c0.x + 60, y + kRow * 0.5f});
            } else {
                const ClipTrack& tr = clip.tracks[std::size_t(row.track)];
                const bool shown = u.curveTracks.count(row.track) > 0;
                const ImU32 txt = (curves && shown) ? kKeySelected : IM_COL32(190, 190, 200, 255);
                dl->AddText(ImVec2(c0.x + 26, y + 3), txt, track_title(tr).c_str());
                at_track_at("anim:track:" + std::to_string(row.track), Vec2{c0.x + 70, y + kRow * 0.5f});
            }
            if (leftClick && mouse.x < c0.x + kLeft && mouse.y >= y && mouse.y < y + kRow) {
                if (header) {
                    if (folded) u.collapsed.erase(g.part);
                    else u.collapsed.insert(g.part);
                } else if (curves) {
                    if (u.curveTracks.count(row.track)) u.curveTracks.erase(row.track);
                    else u.curveTracks.insert(row.track);
                } else {
                    KeySet pick;
                    for (const ClipKey& k : clip.tracks[std::size_t(row.track)].keys) pick.insert(make_key_id(row.track, k.t));
                    if (io.KeyShift) u.selection.insert(pick.begin(), pick.end());
                    else u.selection = pick;
                    u.selectedEvent = -1;
                }
            }
        }
        if (!curves) {
            // ---- dopesheet: time grid, keys
            dl->PushClipRect(ImVec2(x0, clipMin.y), ImVec2(x1, clipMax.y), true);
            {
                const double frame = 1.0 / double(std::max(1, u.fps));
                if (frame * double(u.pps) >= 8.0) {
                    const long long f0 = std::max(0LL, (long long)std::floor(anim_x_to_time(x0) / frame));
                    for (long long f = f0; f * frame <= anim_x_to_time(x1); ++f) {
                        const float x = anim_time_to_x(double(f) * frame);
                        dl->AddLine(ImVec2(x, clipMin.y), ImVec2(x, clipMax.y), (f % u.fps == 0) ? IM_COL32(255, 255, 255, 26) : IM_COL32(255, 255, 255, 8));
                    }
                }
            }
            const KeySet ghostSet = (u.drag == AnimUi::Drag::Keys || u.drag == AnimUi::Drag::Scale) && u.dragMoved
                                        ? moved_keys(u.selection, u.drag == AnimUi::Drag::Keys ? u.dragOffset : 0.0,
                                                     u.drag == AnimUi::Drag::Scale ? u.dragScale : 1.0)
                                        : KeySet();
            for (std::size_t i = 0; i < rows.size(); ++i) {
                const RowInfo& row = rows[i];
                const float y = c0.y + float(i) * kRow + kRow * 0.5f;
                if (y + kRow < clipMin.y || y - kRow > clipMax.y) continue;
                const TrackGroup& g = groups[std::size_t(row.group)];
                const std::vector<int> single = {row.track};
                const std::vector<int>& members = row.track < 0 ? g.tracks : single;
                std::map<long long, Hit> headerHits;
                for (int ti : members) {
                    const ClipTrack& tr = clip.tracks[std::size_t(ti)];
                    for (const ClipKey& k : tr.keys) {
                        const float x = anim_time_to_x(double(k.t));
                        if (x < x0 - 8 || x > x1 + 8) continue;
                        const KeyId id = make_key_id(ti, k.t);
                        if (row.track >= 0) {
                            const bool sel = u.selection.count(id) > 0;
                            draw_key(dl, ImVec2(x, y), k, tr.stepped, sel, false);
                            hits.push_back({{id}, ImVec2(x, y), 0});
                            at_track_at(std::format("anim:key:{}:{}", ti, ms_of(k.t)), Vec2{x, y});
                        } else {
                            Hit& h = headerHits[id.tick];
                            h.pos = ImVec2(x, y);
                            h.ids.push_back(id);
                        }
                    }
                }
                for (auto& [tick, h] : headerHits) {
                    bool all = true;
                    for (const KeyId& id : h.ids) all = all && u.selection.count(id) > 0;
                    ClipKey shape;
                    draw_key(dl, h.pos, shape, false, all, false);
                    hits.push_back(h);
                }
                if (row.track >= 0)
                    for (const KeyId& gid : ghostSet)
                        if (gid.track == row.track) {
                            const ClipKey shape;
                            draw_key(dl, ImVec2(anim_time_to_x(gid.t), y), shape, clip.tracks[std::size_t(row.track)].stepped, true, true);
                        }
            }
            dl->PopClipRect();
            // box
            if (u.drag == AnimUi::Drag::Box && u.dragMoved) {
                const ImVec2 a(std::min(u.dragStartX, mouse.x), std::min(u.dragStartY, mouse.y));
                const ImVec2 b(std::max(u.dragStartX, mouse.x), std::max(u.dragStartY, mouse.y));
                dl->AddRectFilled(a, b, IM_COL32(255, 190, 60, 30));
                dl->AddRect(a, b, IM_COL32(255, 190, 60, 200));
                KeySet inside;
                for (const Hit& h : hits)
                    if (h.pos.x >= a.x && h.pos.x <= b.x && h.pos.y >= a.y && h.pos.y <= b.y) inside.insert(h.ids.begin(), h.ids.end());
                u.selection = u.dragAdd ? u.dragBase : KeySet();
                u.selection.insert(inside.begin(), inside.end());
            }
            // the playhead through the rows
            const float px = anim_time_to_x(u.playhead);
            if (px >= x0 && px <= x1) dl->AddLine(ImVec2(px, clipMin.y), ImVec2(px, clipMax.y), kPlayhead, 1.5f);

            // press in the rows area
            if ((leftClick || rightClick) && mouse.x >= x0 && u.drag == AnimUi::Drag::None) {
                const Hit* best = nullptr;
                float bd = kPick + 1;
                for (const Hit& h : hits) {
                    const float d = std::fabs(h.pos.x - mouse.x);
                    if (std::fabs(h.pos.y - mouse.y) < kRow * 0.5f && d < bd) {
                        bd = d;
                        best = &h;
                    }
                }
                if (best) {
                    bool all = true;
                    for (const KeyId& id : best->ids) all = all && u.selection.count(id) > 0;
                    if (rightClick) {
                        if (!all) {
                            u.selection.clear();
                            u.selection.insert(best->ids.begin(), best->ids.end());
                        }
                        rightPressed = true;
                    } else {
                        u.selectedEvent = -1;
                        if (io.KeyShift) {
                            for (const KeyId& id : best->ids) {
                                if (all) u.selection.erase(id);
                                else u.selection.insert(id);
                            }
                        } else {
                            u.dragBase.clear();
                            if (all) u.dragBase.insert(best->ids.begin(), best->ids.end());  // a click without a drag narrows to this key
                            else {
                                u.selection.clear();
                                u.selection.insert(best->ids.begin(), best->ids.end());
                            }
                        }
                        if (!u.selection.empty() && !(io.KeyShift && all)) {
                            u.drag = io.KeyAlt ? AnimUi::Drag::Scale : AnimUi::Drag::Keys;
                            u.dragPressT = mouseT;
                            u.dragStartX = mouse.x;
                            u.dragStartY = mouse.y;
                            u.dragMoved = false;
                            u.dragOffset = 0;
                            u.dragScale = 1;
                        }
                    }
                } else if (leftClick) {
                    u.selectedEvent = -1;
                    u.drag = AnimUi::Drag::Box;
                    u.dragAdd = io.KeyShift;
                    u.dragBase = io.KeyShift ? u.selection : KeySet();
                    if (!io.KeyShift) u.selection.clear();
                    u.dragStartX = mouse.x;
                    u.dragStartY = mouse.y;
                    u.dragMoved = false;
                }
            }
            if (rightPressed) ImGui::OpenPopup("##animkeymenu");
            anim_key_menu(clipPtr, path);
        }
        dl->PopClipRect();
    }
    ImGui::EndChild();

    if (curves) {
        // the curve canvas right of the tree
        draw_anim_curves(clipPtr, path, ImVec2(x0, yRows), ImVec2(std::max(1.0f, x1 - x0), rowsH));
    }

    // the playhead over the ruler and the event lane
    {
        const float px = anim_time_to_x(u.playhead);
        if (px >= x0 && px <= x1) {
            wdl->PushClipRect(ImVec2(x0, yRuler), ImVec2(x1, yRows), true);
            wdl->AddLine(ImVec2(px, yRuler), ImVec2(px, yRows), kPlayhead, 1.5f);
            wdl->AddTriangleFilled(ImVec2(px - 6, yRuler), ImVec2(px + 6, yRuler), ImVec2(px, yRuler + 10), kPlayhead);
            wdl->PopClipRect();
        }
        at_track_at("anim:playhead", Vec2{px, yRuler + kRuler * 0.5f});
    }

    // ---- keyboard (the panel has the focus and nobody is typing)
    const bool focused = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows) && !io.WantTextInput;
    if (focused) {
        if (ImGui::IsKeyPressed(ImGuiKey_Space, false)) {
            if (!u.playing && u.playhead >= double(clip.duration) - 1e-6) anim_set_playhead(0);
            u.playing = !u.playing;
        }
        if (ImGui::IsKeyPressed(ImGuiKey_Home, false)) anim_set_playhead(0);
        if (ImGui::IsKeyPressed(ImGuiKey_LeftArrow)) {
            u.playing = false;
            anim_set_playhead(std::round(u.playhead * u.fps) / u.fps - 1.0 / u.fps);
        }
        if (ImGui::IsKeyPressed(ImGuiKey_RightArrow)) {
            u.playing = false;
            anim_set_playhead(std::round(u.playhead * u.fps) / u.fps + 1.0 / u.fps);
        }
        if (ImGui::IsKeyPressed(ImGuiKey_Delete, false) || ImGui::IsKeyPressed(ImGuiKey_Backspace, false)) {
            if (!u.selection.empty()) {
                if (anim_edit("anim:delete:" + std::to_string(uiFrame_), delete_keys_calls(path, clip, u.selection))) u.selection.clear();
            } else if (u.selectedEvent >= 0 && std::size_t(u.selectedEvent) < clip.events.size()) {
                if (anim_edit("anim:event:delete:" + std::to_string(uiFrame_),
                              {{"anim.remove_event", Json::object({{"path", path}, {"event", u.selectedEvent}})}}))
                    u.selectedEvent = -1;
            }
        }
        if (ImGui::IsKeyChordPressed(ImGuiMod_Ctrl | ImGuiKey_C) && !u.selection.empty()) u.clipboard = copy_keys(clip, u.selection);
        if (ImGui::IsKeyChordPressed(ImGuiMod_Ctrl | ImGuiKey_V) && !u.clipboard.empty()) {
            const double at = u.snap ? snap_to_frames(u.playhead, u.fps) : u.playhead;
            const KeySet pasted = pasted_selection(clip, u.clipboard, at);
            if (anim_edit("anim:paste:" + std::to_string(uiFrame_), paste_keys_calls(path, u.clipboard, at))) u.selection = pasted;
        }
        if (u.drag != AnimUi::Drag::None && ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
            // nothing was written yet: the drag only showed a preview
            if (u.drag == AnimUi::Drag::Box) u.selection = u.dragBase;
            u.drag = AnimUi::Drag::None;
        }
    }

    // ---- the end of a drag: ONE command for the whole gesture
    if (u.drag != AnimUi::Drag::None && u.drag != AnimUi::Drag::Pan && !io.MouseDown[0]) {
        const AnimUi::Drag d = u.drag;
        u.drag = AnimUi::Drag::None;
        const std::string key = "anim:drag:" + std::to_string(uiFrame_);
        if (d == AnimUi::Drag::Keys && u.dragMoved && std::fabs(u.dragOffset) > 1e-9) {
            const KeySet after = moved_keys(u.selection, u.dragOffset, 1.0);
            if (anim_edit(key, {move_keys_call(path, u.selection, u.dragOffset, 1.0)})) u.selection = after;
        } else if (d == AnimUi::Drag::Keys && !u.dragMoved && !u.dragBase.empty() && !io.KeyShift) {
            u.selection = u.dragBase;
        } else if (d == AnimUi::Drag::Scale && u.dragMoved && std::fabs(u.dragScale - 1.0) > 1e-9) {
            const KeySet after = moved_keys(u.selection, 0.0, u.dragScale);
            if (anim_edit(key, {move_keys_call(path, u.selection, 0.0, u.dragScale)})) u.selection = after;
        } else if (d == AnimUi::Drag::Event && u.dragEvent >= 0 && std::size_t(u.dragEvent) < clip.events.size() &&
                   std::fabs(u.dragEventTo - double(clip.events[std::size_t(u.dragEvent)].t)) > 1e-6) {
            const std::string name = clip.events[std::size_t(u.dragEvent)].name;
            if (anim_edit(key, {{"anim.move_event", Json::object({{"path", path}, {"event", u.dragEvent}, {"to", clip_round_time(u.dragEventTo)}})}})) {
                u.selectedEvent = -1;
                if (auto again = load_anim_clip(path); again.ok())
                    for (std::size_t i = 0; i < (*again)->events.size(); ++i)
                        if ((*again)->events[i].name == name && std::fabs((*again)->events[i].t - u.dragEventTo) < 1e-3) u.selectedEvent = int(i);
            }
        } else if (d == AnimUi::Drag::Tangent && u.dragTrack >= 0 && std::size_t(u.dragTrack) < clip.tracks.size()) {
            const ClipTrack& tr = clip.tracks[std::size_t(u.dragTrack)];
            if (const ClipKey* k = find_key_at(tr, u.dragKeyT))
                (void)anim_edit(key, {set_tangent_call(path, tr, *k, u.dragTrack, u.dragChannel, u.dragOutgoing, u.dragSlope)});
        } else if (d == AnimUi::Drag::Value && !u.dragMoved && !u.dragBase.empty() && !io.KeyShift) {
            u.selection = u.dragBase;
        } else if (d == AnimUi::Drag::Value && u.dragTrack >= 0 && std::size_t(u.dragTrack) < clip.tracks.size()) {
            const ClipTrack& tr = clip.tracks[std::size_t(u.dragTrack)];
            if (const ClipKey* k = find_key_at(tr, u.dragKeyT); k && u.dragMoved) {
                std::vector<ModelCall> calls;
                Json kj = key_json(tr, *k, double(k->t));
                if (tr.channels == 1) kj["value"] = double(u.dragValue);
                else if (kj["value"].is_array() && std::size_t(u.dragChannel) < kj["value"].size()) kj["value"][std::size_t(u.dragChannel)] = double(u.dragValue);
                calls.push_back({"anim.set_keys", Json::object({{"path", path}, {"track", track_ref_json(tr)}, {"keys", Json::array({kj})}})});
                const double off = u.dragOffset;
                const KeyId pressed = make_key_id(u.dragTrack, k->t);
                KeySet after = u.selection;
                if (std::fabs(off) > 1e-9) {
                    calls.push_back(move_keys_call(path, u.selection, off, 1.0));
                    after = moved_keys(u.selection, off, 1.0);
                }
                (void)pressed;
                if (anim_edit(key, calls)) u.selection = after;
            }
        }
        u.dragMoved = false;
        u.dragOffset = 0;
        u.dragScale = 1;
    }
    ImGui::SetCursorScreenPos(ImVec2(origin.x, origin.y + avail.y));
    ImGui::Dummy(ImVec2(0, 0));
}

// ------------------------------------------------------------------------------------------------------------ curves --
void Editor::draw_anim_curves(const std::shared_ptr<const ClipAsset>& clipPtr, const std::string& path, ImVec2 origin, ImVec2 size) {
    (void)path;
    AnimUi& u = anim_;
    const ClipAsset& clip = *clipPtr;
    const ImGuiIO& io = ImGui::GetIO();
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const float cx0 = origin.x, cx1 = origin.x + size.x, cy0 = origin.y, cy1 = origin.y + size.y;
    dl->AddRectFilled(ImVec2(cx0, cy0), ImVec2(cx1, cy1), IM_COL32(26, 27, 32, 255));
    dl->PushClipRect(ImVec2(cx0, cy0), ImVec2(cx1, cy1), true);

    // which curves
    std::vector<int> drawn;
    for (int t : u.curveTracks)
        if (t >= 0 && std::size_t(t) < clip.tracks.size() && !clip.tracks[std::size_t(t)].stepped) drawn.push_back(t);
    if (drawn.empty()) {
        std::set<int> fromSelection;
        for (const KeyId& id : u.selection) fromSelection.insert(id.track);
        for (int t : fromSelection)
            if (t >= 0 && std::size_t(t) < clip.tracks.size() && !clip.tracks[std::size_t(t)].stepped) drawn.push_back(t);
    }
    if (drawn.empty())
        for (std::size_t t = 0; t < clip.tracks.size(); ++t)
            if (!clip.tracks[t].stepped) drawn.push_back(int(t));
    // value range
    float vmin = 1e30f, vmax = -1e30f;
    for (int ti : drawn) {
        const ClipTrack& tr = clip.tracks[std::size_t(ti)];
        for (const ClipKey& k : tr.keys)
            for (int c = 0; c < tr.channels; ++c) {
                vmin = std::min(vmin, k.value[std::size_t(c)]);
                vmax = std::max(vmax, k.value[std::size_t(c)]);
            }
    }
    if (vmin > vmax) {
        vmin = -1;
        vmax = 1;
    }
    if (vmax - vmin < 1e-4f) {
        vmin -= 1;
        vmax += 1;
    }
    const float pad = (vmax - vmin) * 0.1f;
    vmin -= pad;
    vmax += pad;
    const float pyv = (size.y - 16.0f) / (vmax - vmin);
    auto y_of = [&](float v) { return cy1 - 8.0f - (v - vmin) * pyv; };
    auto v_of = [&](float y) { return vmin + (cy1 - 8.0f - y) / pyv; };

    // grid
    {
        const float span = vmax - vmin;
        float step = std::pow(10.0f, std::floor(std::log10(span / 4.0f)));
        for (float m : {1.0f, 2.0f, 5.0f, 10.0f})
            if (span / (step * m) <= 8.0f) {
                step *= m;
                break;
            }
        for (float v = std::ceil(vmin / step) * step; v <= vmax; v += step) {
            const float y = y_of(v);
            dl->AddLine(ImVec2(cx0, y), ImVec2(cx1, y), std::fabs(v) < step * 0.01f ? IM_COL32(255, 255, 255, 50) : IM_COL32(255, 255, 255, 16));
            dl->AddText(ImVec2(cx0 + 3, y - 12), IM_COL32(150, 150, 160, 255), std::format("{:g}", std::round(v / step * 1000.0f) / 1000.0f * step).c_str());
        }
        const double frame = 1.0 / double(std::max(1, u.fps));
        if (frame * double(u.pps) >= 8.0) {
            const long long f0 = std::max(0LL, (long long)std::floor(anim_x_to_time(cx0) / frame));
            for (long long f = f0; f * frame <= anim_x_to_time(cx1); ++f) {
                const float x = anim_time_to_x(double(f) * frame);
                dl->AddLine(ImVec2(x, cy0), ImVec2(x, cy1), (f % u.fps == 0) ? IM_COL32(255, 255, 255, 26) : IM_COL32(255, 255, 255, 8));
            }
        }
    }

    // curves, keys, handles
    std::vector<Hit> hits;
    struct Handle {
        ImVec2 pos, key;
        int track, channel;
        double keyT;
        bool outgoing;
    };
    std::vector<Handle> handles;
    const ImVec2 mouse = io.MousePos;
    for (int ti : drawn) {
        const ClipTrack& tr = clip.tracks[std::size_t(ti)];
        for (int c = 0; c < tr.channels; ++c) {
            std::vector<ImVec2> pts;
            for (float x = cx0; x <= cx1 + 2.0f; x += 2.0f) {
                const double t = std::clamp(anim_x_to_time(x), 0.0, double(clip.duration));
                std::array<float, 4> v{};
                const Json* raw = nullptr;
                sample_clip_track(tr, float(t), v, &raw);
                pts.push_back(ImVec2(x, y_of(v[std::size_t(c)])));
            }
            dl->AddPolyline(pts.data(), int(pts.size()), channel_color(tr, c), ImDrawFlags_None, 1.5f);
        }
        for (std::size_t ki = 0; ki < tr.keys.size(); ++ki) {
            const ClipKey& k = tr.keys[ki];
            const float x = anim_time_to_x(double(k.t));
            const KeyId id = make_key_id(ti, k.t);
            const bool sel = u.selection.count(id) > 0;
            for (int c = 0; c < tr.channels; ++c) {
                float v = k.value[std::size_t(c)];
                float xx = x;
                if (u.drag == AnimUi::Drag::Value && sel) {
                    xx = anim_time_to_x(double(k.t) + u.dragOffset);
                    if (id.track == u.dragTrack && std::fabs(double(k.t) - u.dragKeyT) < 1e-4 && c == u.dragChannel) v = u.dragValue;
                }
                const ImVec2 p(xx, y_of(v));
                if (xx < cx0 - 8 || xx > cx1 + 8) continue;
                draw_key(dl, p, k, false, sel, false);
                hits.push_back({{id}, ImVec2(x, y_of(k.value[std::size_t(c)])), c});
                at_track_at(std::format("anim:curvekey:{}:{}:{}", ti, ms_of(k.t), c), Vec2{p.x, p.y});
                if (sel && k.interp == ClipInterp::Bezier) {
                    const float dt = kHandle / u.pps;
                    float slope = k.outTan[std::size_t(c)];
                    if (u.drag == AnimUi::Drag::Tangent && u.dragTrack == ti && u.dragChannel == c && u.dragOutgoing && std::fabs(u.dragKeyT - double(k.t)) < 1e-4) slope = u.dragSlope;
                    handles.push_back({ImVec2(p.x + kHandle, p.y - slope * dt * pyv), p, ti, c, double(k.t), true});
                }
                if (sel && ki > 0 && tr.keys[ki - 1].interp == ClipInterp::Bezier) {
                    const float dt = kHandle / u.pps;
                    float slope = k.inTan[std::size_t(c)];
                    if (u.drag == AnimUi::Drag::Tangent && u.dragTrack == ti && u.dragChannel == c && !u.dragOutgoing && std::fabs(u.dragKeyT - double(k.t)) < 1e-4) slope = u.dragSlope;
                    handles.push_back({ImVec2(p.x - kHandle, p.y + slope * dt * pyv), p, ti, c, double(k.t), false});
                }
            }
        }
    }
    for (const Handle& h : handles) {
        dl->AddLine(h.key, h.pos, IM_COL32(255, 190, 60, 160));
        dl->AddCircleFilled(h.pos, 4.0f, IM_COL32(255, 190, 60, 255));
        dl->AddCircle(h.pos, 4.0f, IM_COL32(20, 20, 24, 255));
        at_track_at(std::format("anim:handle:{}:{}:{}:{}", h.track, ms_of(h.keyT), h.channel, h.outgoing ? "out" : "in"), Vec2{h.pos.x, h.pos.y});
    }
    const float px = anim_time_to_x(u.playhead);
    if (px >= cx0 && px <= cx1) dl->AddLine(ImVec2(px, cy0), ImVec2(px, cy1), kPlayhead, 1.5f);

    if (u.drag == AnimUi::Drag::Box && u.dragMoved) {
        const ImVec2 a(std::min(u.dragStartX, mouse.x), std::min(u.dragStartY, mouse.y));
        const ImVec2 b(std::max(u.dragStartX, mouse.x), std::max(u.dragStartY, mouse.y));
        dl->AddRectFilled(a, b, IM_COL32(255, 190, 60, 30));
        dl->AddRect(a, b, IM_COL32(255, 190, 60, 200));
        KeySet inside;
        for (const Hit& h : hits)
            if (h.pos.x >= a.x && h.pos.x <= b.x && h.pos.y >= a.y && h.pos.y <= b.y) inside.insert(h.ids.begin(), h.ids.end());
        u.selection = u.dragAdd ? u.dragBase : KeySet();
        u.selection.insert(inside.begin(), inside.end());
    }

    // a drag of a tangent handle or a key updates the numbers from the mouse
    if (u.drag == AnimUi::Drag::Tangent) {
        const float dt = kHandle / u.pps;
        // the key is at y_of(value): keep the pressed handle's key position
        if (const ClipTrack* tr = (u.dragTrack >= 0 && std::size_t(u.dragTrack) < clip.tracks.size()) ? &clip.tracks[std::size_t(u.dragTrack)] : nullptr) {
            if (const ClipKey* k = find_key_at(*tr, u.dragKeyT)) {
                const float ky = y_of(k->value[std::size_t(u.dragChannel)]);
                const float dv = (u.dragOutgoing ? (ky - mouse.y) : (mouse.y - ky)) / pyv;
                u.dragSlope = dv / dt;
            }
        }
    } else if (u.drag == AnimUi::Drag::Value) {
        u.dragValue = v_of(mouse.y);
    }

    // press
    ImGui::SetCursorScreenPos(origin);
    ImGui::InvisibleButton("##animcurves", size, ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight);
    at_track_at("anim:curvearea", Vec2{origin.x + size.x * 0.5f, origin.y + size.y * 0.5f});
    const bool hover = ImGui::IsItemHovered();
    bool rightPressed = false;
    if (hover && (ImGui::IsMouseClicked(0) || ImGui::IsMouseClicked(1)) && u.drag == AnimUi::Drag::None) {
        const bool right = ImGui::IsMouseClicked(1);
        const double mouseT = anim_x_to_time(mouse.x);
        const Handle* bh = nullptr;
        float bd = kPick + 1;
        for (const Handle& h : handles) {
            const float d = std::hypot(h.pos.x - mouse.x, h.pos.y - mouse.y);
            if (d < bd) {
                bd = d;
                bh = &h;
            }
        }
        if (bh && !right) {
            u.drag = AnimUi::Drag::Tangent;
            u.dragTrack = bh->track;
            u.dragChannel = bh->channel;
            u.dragKeyT = bh->keyT;
            u.dragOutgoing = bh->outgoing;
            const ClipTrack& tr = clip.tracks[std::size_t(bh->track)];
            const ClipKey* k = find_key_at(tr, bh->keyT);
            u.dragSlope = k ? (bh->outgoing ? k->outTan : k->inTan)[std::size_t(bh->channel)] : 0.0f;
            u.dragStartX = mouse.x;
            u.dragStartY = mouse.y;
            u.dragMoved = false;
        } else {
            const Hit* best = nullptr;
            bd = kPick + 1;
            for (const Hit& h : hits) {
                const float d = std::hypot(h.pos.x - mouse.x, h.pos.y - mouse.y);
                if (d < bd) {
                    bd = d;
                    best = &h;
                }
            }
            if (best) {
                const bool all = u.selection.count(best->ids[0]) > 0;
                if (right) {
                    if (!all) {
                        u.selection.clear();
                        u.selection.insert(best->ids.begin(), best->ids.end());
                    }
                    rightPressed = true;
                } else {
                    u.selectedEvent = -1;
                    if (io.KeyShift) {
                        if (all) u.selection.erase(best->ids[0]);
                        else u.selection.insert(best->ids[0]);
                    } else if (!all) {
                        u.selection.clear();
                        u.selection.insert(best->ids.begin(), best->ids.end());
                    }
                    u.dragBase.clear();
                    if (!io.KeyShift && all) u.dragBase.insert(best->ids[0]);
                    if (u.selection.count(best->ids[0])) {
                        u.drag = AnimUi::Drag::Value;
                        u.dragTrack = best->ids[0].track;
                        u.dragKeyT = best->ids[0].t;
                        u.dragChannel = best->channel;
                        u.dragPressT = mouseT;
                        u.dragStartX = mouse.x;
                        u.dragStartY = mouse.y;
                        u.dragMoved = false;
                        u.dragOffset = 0;
                        if (const ClipKey* k = find_key_at(clip.tracks[std::size_t(u.dragTrack)], u.dragKeyT)) u.dragValue = k->value[std::size_t(u.dragChannel)];
                    }
                }
            } else if (!right) {
                u.selectedEvent = -1;
                u.drag = AnimUi::Drag::Box;
                u.dragAdd = io.KeyShift;
                u.dragBase = io.KeyShift ? u.selection : KeySet();
                if (!io.KeyShift) u.selection.clear();
                u.dragStartX = mouse.x;
                u.dragStartY = mouse.y;
                u.dragMoved = false;
            }
        }
    }
    if (rightPressed) ImGui::OpenPopup("##animkeymenu");
    anim_key_menu(clipPtr, path);
    dl->PopClipRect();
}

}  // namespace fa::editor
