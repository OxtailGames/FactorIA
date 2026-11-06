// The Particle panel (View > Particles): an effect document (*.vfx.json, docs/PARTICLES.md "Effect documents") played by the engine's own
// timeline with a time scrubber, a parts list, an inspector built from the reflected fields of ParticleEmitter (their descriptions are the
// tooltips) and editors for gradients and curves. Everything it keeps is a vfx.edit call made by ParticleModel, so the Console and an AI make
// the same edit, and each edit is ONE entry of the editor's undo stack. The rules are in particle_model.h; the playback in particle_preview.h.
#include <algorithm>
#include <cfloat>
#include <cmath>
#include <filesystem>
#include <format>
#include <map>
#include <set>
#include <string>

#include "editor_internal.h"
#include "fa/core/reflect.h"
#include "fa/core/strings.h"
#include "fa/scene/components.h"
#include "fa/scene/curve.h"
#include "imgui_internal.h"
#include "inspector_model.h"
#include "particle_curve.h"

namespace fa::editor {

namespace {

const ImVec4 kBad(1.0f, 0.55f, 0.45f, 1);
const ImVec4 kWarn(1.0f, 0.8f, 0.4f, 1);

ImU32 col32(Color c, float alphaMul = 1.0f) {
    auto b = [](float v) { return int(std::clamp(v, 0.0f, 1.0f) * 255.0f + 0.5f); };
    return IM_COL32(b(c.r), b(c.g), b(c.b), b(c.a * alphaMul));
}

void hint(const std::string& text) {
    if (text.empty() || !ImGui::BeginItemTooltip()) return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text.c_str());
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

// Buttons that wrap: a row starts with a plain item, `next(label)` puts the next button on the same line when it fits and on the next one when
// it does not (a narrow window, the macOS CI display, must not push a button out of reach).
struct FitRow {
    float right;
    FitRow() { right = ImGui::GetCursorScreenPos().x + ImGui::GetContentRegionAvail().x; }
    void next(const char* label) {
        const float w = ImGui::CalcTextSize(label, nullptr, true).x + ImGui::GetStyle().FramePadding.x * 2.0f;
        if (ImGui::GetItemRectMax().x + ImGui::GetStyle().ItemSpacing.x + w <= right) ImGui::SameLine();
    }
};

std::string last_segment(const std::string& pointer) {
    const auto slash = pointer.find_last_of('/');
    return slash == std::string::npos ? pointer : pointer.substr(slash + 1);
}

std::string range_tip(const FieldInfo& f) {
    std::string tip = f.doc;
    if (f.minValue != f.maxValue) tip += std::format("\nRange {:g} to {:g}.", f.minValue, f.maxValue);
    return tip;
}

FieldInfo field_of(const char* name, FieldKind kind, const char* doc, float lo = 0, float hi = 0) {
    FieldInfo f;
    f.name = name;
    f.kind = kind;
    f.doc = doc;
    f.minValue = lo;
    f.maxValue = hi;
    return f;
}

// The default value of each field of a reflected type, as the panel shows a field the document does not set.
Json defaults_of(const TypeInfo& t) {
    DefaultObject d(t);
    return object_to_json(t, d.get(), true, false);
}

const char* kEssentials[] = {"burst", "rate", "lifetime", "lifetimeVariance", "speed", "speedVariance", "direction", "spread", "gravity",
                             "startSize", "endSize", "sizeVariance", "startColor", "endColor", "blend", "texture", "maxParticles", "worldSpace", "drag"};

bool is_essential(const std::string& name) {
    for (const char* e : kEssentials)
        if (name == e) return true;
    return false;
}

struct CurveField {
    const char* name;
    bool gradient;
    float lo, hi;
};
// The emitter fields that are a curve or a gradient: drawn by their editors, not as JSON text.
const CurveField kCurveFields[] = {{"colorGradient", true, 0, 1}, {"sizeCurve", false, 0, 1},      {"speedCurve", false, 0, 1},
                                   {"alphaCurve", false, 0, 1},   {"trailWidthCurve", false, 0, 1}, {"trailGradient", true, 0, 1}};

const CurveField* curve_field(const std::string& name) {
    for (const CurveField& c : kCurveFields)
        if (name == c.name) return &c;
    return nullptr;
}

const TypeInfo* component_type(const char* name) {
    ensure_builtin_components();
    return TypeRegistry::global().find(name);
}

}  // namespace

// ----------------------------------------------------------------------------------------------------------- document --
ParticleModel& Editor::particle_ensure_model() {
    if (!particle_.model) {
        particle_.model = std::make_unique<ParticleModel>(projectDir_, [this](const std::string& name, const Json& args) {
            CommandResult r = engine_->commands().call(name, args);
            if (!args.is_object() || !args.value("dryRun", false)) after_command(name, args, r);
            return r;
        });
    }
    if (!particle_.preview) particle_.preview = std::make_unique<ParticlePreview>();
    return *particle_.model;
}

bool Editor::open_particle_document(const std::string& rel) {
    if (!engine_) return false;
    ParticleModel& m = particle_ensure_model();
    ParticleUi& u = particle_;
    const bool ok = m.open(rel);
    u.openError = ok ? std::string() : m.error();
    u.selectedPart = ok && !m.parts().empty() ? 0 : -1;
    u.editorKey.clear();
    u.selectedKey = u.dragKey = -1;
    u.playing = true;
    u.loopWait = 0.0;
    if (ok) {
        u.preview->set_document(m.doc());
        u.preview->seek(0.0);
    }
    showParticle_ = true;
    focus_window("Particles");
    if (!ok) notify("Cannot open " + rel + " in the Particles panel: " + m.error(), 2);
    return ok;
}

void Editor::particle_close_document() {
    if (particle_.model) particle_.model->close();
    if (particle_.preview) {
        particle_.preview->set_document(nullptr);
        particle_.preview->seek(0.0);
    }
}

void Editor::particle_edited(const ParticleEditOutcome& out) {
    if (!out.ok) {
        notify(out.error, 1);
        return;
    }
    if (out.step <= 0 || !particle_.model) return;
    particle_drop_stale_step();   // an edit made on top of the outside change: the refused step cannot be applied any more
    undo_.push_back(Json::object({{"$particle", Json::object({{"step", out.step}})}}));
    if (undo_.size() > 100) undo_.erase(undo_.begin());
    redo_.clear();
    lastEditKey_.clear();
    particle_collect_steps();
}

void Editor::particle_drop_stale_step() {
    if (!particle_.model) return;
    const int id = particle_.model->take_stale_step();
    if (id <= 0) return;
    for (auto* stack : {&undo_, &redo_})
        stack->erase(std::remove_if(stack->begin(), stack->end(), [id](const Json& e) {
                         return e.is_object() && e.contains("$particle") && e["$particle"].is_object() && e["$particle"].value("step", 0) == id;
                     }), stack->end());
    lastEditKey_.clear();
    particle_collect_steps();
}

void Editor::particle_reload() {
    if (!particle_.model) return;
    particle_.model->reload();
    particle_drop_stale_step();
}

void Editor::particle_collect_steps() {
    if (!particle_.model) return;
    std::set<int> keep;
    for (const auto* stack : {&undo_, &redo_})
        for (const Json& e : *stack)
            if (e.is_object() && e.contains("$particle") && e["$particle"].is_object() && e["$particle"].value("step", 0) > 0)
                keep.insert(e["$particle"]["step"].get<int>());
    particle_.model->retain_steps(keep);
}

void Editor::particle_apply_undo(const Json& entry, bool forward) {
    ParticleUi& u = particle_;
    const int id = entry["$particle"].value("step", 0);
    if (!u.model || !u.model->step(id)) {
        notify("That effect edit is no longer remembered.", 1);
        return;
    }
    const std::string doc = u.model->step_document(id);
    if (!doc.empty() && doc != u.model->path()) open_particle_document(doc);
    if (!u.model->apply_step(id, forward)) {
        // A refusal because the file changed outside the editor leaves the step where it was (the Reload button of the panel decides).
        if (u.model->conflict()) (forward ? redo_ : undo_).push_back(entry);
        notify("Could not " + std::string(forward ? "redo" : "undo") + " the effect edit: " + u.model->status(), 2);
        return;
    }
    (forward ? undo_ : redo_).push_back(entry);
    const int parts = int(u.model->parts().size());
    if (u.selectedPart >= parts) u.selectedPart = parts - 1;
    project_files_changed();
}

Vec2 Editor::particle_time_pos(double seconds, double yFraction) const {
    const ParticleUi& u = particle_;
    const double len = std::max(1e-6, u.tlLength);
    return Vec2{float(u.tlX + seconds / len * u.tlW), float(u.tlY + yFraction * u.tlH)};
}

Vec2 Editor::particle_canvas_pos(float worldX, float worldY) const {
    const ParticleUi& u = particle_;
    return Vec2{u.canvasX + u.canvasW * 0.5f + worldX * u.zoom, u.canvasY + u.canvasH * 0.5f - worldY * u.zoom};
}

// ----------------------------------------------------------------------------------------------------------- panel --
void Editor::draw_particle_panel() {
    ParticleUi& u = particle_;
    ParticleModel& m = particle_ensure_model();

    first_floating_window(ImVec2(160, 70), ImVec2(1040, 720));
    if (!ImGui::Begin("Particles", &showParticle_)) {
        u.focused = false;
        ImGui::End();
        return;
    }
    u.focused = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows);

    // A drag whose release the widget did not report (the value stayed in memory): it becomes one edit now.
    if (m.field_previewing() && !ImGui::IsMouseDown(ImGuiMouseButton_Left) && !ImGui::IsAnyItemActive()) {
        const std::string name = last_segment(m.preview_pointer());
        particle_edited(m.commit_field("Edit " + name));
    }
    if (m.is_open() && !m.field_previewing() && uiFrame_ - u.lastPoll >= 20) {
        u.lastPoll = uiFrame_;
        if (m.poll_external()) m.set_status("The file changed on disk and was read again.");
    }

    draw_particle_toolbar(m);
    if (m.is_open() && m.conflict()) {
        ImGui::TextColored(kWarn, "The file changed outside the editor: undo and redo would overwrite that change.");
        ImGui::SameLine();
        if (ImGui::Button("Reload##conflict")) particle_reload();
        ImGui::SameLine();
        ImGui::TextDisabled("(Reload takes the file as it is on disk)");
    }
    if (!m.is_open()) {
        ImGui::Spacing();
        ImGui::TextDisabled("Open an effect document (*.vfx.json) from the list above, make a new one with New, or double click one in the Project panel.");
        ImGui::TextDisabled("An effect is emitters, a light flash, sounds and commands on one timeline (docs/PARTICLES.md, \"Effect documents\").");
        if (!u.openError.empty()) ImGui::TextColored(kBad, "%s", u.openError.c_str());
        ImGui::End();
        return;
    }
    if (!m.valid()) {
        ImGui::Spacing();
        ImGui::TextColored(kBad, "This file does not load:");
        ImGui::TextWrapped("%s", m.error().c_str());
        ImGui::TextDisabled("Fix it with the Console (fs.edit) or an editor, then Reload.");
        ImGui::End();
        return;
    }
    if (play_ != PlayState::Edit) ImGui::TextColored(kWarn, "The game is running: stop it to edit the effect.");

    // The preview plays the document as it is now (a drag in progress included).
    u.preview->begin_frame();
    u.preview->set_document(m.doc());
    u.preview->catch_up();   // a seek or an edit that is still being rebuilt does ONE bounded share of its steps per frame (begin_frame)
    if (u.playing && !u.scrubbing && m.doc()) {
        const double dt = std::min(0.1, double(ImGui::GetIO().DeltaTime)) * double(u.speed);
        if (u.preview->time() >= u.preview->timeline_length()) {
            if (u.loop) {
                u.loopWait += dt;
                if (u.loopWait >= 0.4) {
                    u.loopWait = 0.0;
                    u.preview->seek(0.0);
                }
            } else {
                u.playing = false;
            }
        } else {
            u.preview->advance(dt);
        }
    }

    draw_particle_timeline(m);
    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const float leftW = std::clamp(avail.x * 0.42f, 220.0f, std::max(220.0f, avail.x - 300.0f));
    ImGui::BeginChild("##ptcanvas", ImVec2(leftW, avail.y), false);
    draw_particle_canvas(m);
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##ptedit", ImVec2(0, avail.y), false);
    draw_particle_parts(m);
    draw_particle_inspector(m);
    ImGui::EndChild();
    ImGui::End();
}

void Editor::draw_particle_toolbar(ParticleModel& m) {
    ParticleUi& u = particle_;
    const bool editable = play_ == PlayState::Edit;
    ImGui::SetNextItemWidth(260);
    if (ImGui::BeginCombo("##ptfile", m.is_open() ? m.title().c_str() : "Open an effect...")) {
        // The list is made only while the combo is open (it lowercases every file name of the project).
        std::vector<std::string> files;
        for (const BrowserFile& f : projBrowser_.listing.files)
            if (ends_with(to_lower(f.path), ".vfx.json")) files.push_back(f.path);
        std::sort(files.begin(), files.end());
        for (const std::string& f : files) {
            if (ImGui::Selectable(f.c_str(), f == m.path())) open_particle_document(f);
            at_track("pt:file:" + f);
        }
        if (files.empty()) ImGui::TextDisabled("No effect documents in the project yet. New makes one.");
        ImGui::EndCombo();
    }
    at_track("pt:open");
    hint("The effect documents (*.vfx.json) of the project. A double click in the Project panel opens one too.");
    FitRow row;
    row.next("New");
    ImGui::BeginDisabled(!editable);
    if (ImGui::Button("New")) {
        std::string rel;
        for (int i = 1; i < 1000; ++i) {
            rel = i == 1 ? "assets/vfx/effect.vfx.json" : std::format("assets/vfx/effect{}.vfx.json", i);
            std::error_code ec;
            if (!std::filesystem::exists(std::filesystem::path(projectDir_) / rel, ec)) break;
        }
        const ParticleEditOutcome out = m.create(rel);
        if (!out.ok) {
            notify(out.error, 1);
        } else {
            project_files_changed();
            open_particle_document(rel);
        }
    }
    at_track("pt:new");
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("vfx.create: writes assets/vfx/effect.vfx.json with one burst emitter to edit from.");
    if (!m.is_open()) return;

    row.next(u.playing ? "Pause" : "Play");
    if (ImGui::Button(u.playing ? "Pause" : "Play")) {
        u.playing = !u.playing;
        u.loopWait = 0.0;
        if (u.playing && u.preview->time() >= u.preview->timeline_length()) u.preview->seek(0.0);
    }
    at_track("pt:play");
    hint("Plays and pauses the preview. Space while this panel has the keyboard.");
    row.next("Restart");
    if (ImGui::Button("Restart")) {
        u.preview->seek(0.0);
        u.playing = true;
        u.loopWait = 0.0;
    }
    at_track("pt:restart");
    hint("Plays the effect again from the start. The same seed gives the same particles every time.");
    row.next("Loop");
    ImGui::Checkbox("Loop", &u.loop);
    at_track("pt:loop");
    hint("Start again a moment after the last particle is gone.");
    row.next("Reload");
    if (ImGui::Button("Reload")) particle_reload();
    at_track("pt:reload");
    hint("Reads the file again; the undo steps stay.");

    ImGui::SetNextItemWidth(110);
    ImGui::SliderFloat("Speed", &u.speed, 0.1f, 2.0f, "%.2fx");
    at_track("pt:speed");
    hint("How fast the preview plays. The simulation steps stay the same size, so slow motion shows the same particles.");
    ImGui::SameLine();
    int seed = int(u.preview->seed());
    ImGui::SetNextItemWidth(80);
    if (ImGui::DragInt("Seed", &seed, 0.2f, 0, 99999)) u.preview->set_seed(std::uint32_t(std::max(0, seed)));
    at_track("pt:seed");
    hint("The random seed of the preview. The same seed and the same time always show the same particles; a game gives each play its own.");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(90);
    ImGui::SliderFloat("Zoom", &u.zoom, 0.25f, 6.0f, "%.2f");
    at_track("pt:zoom");
    hint("Pixels per world unit of the preview. The mouse wheel over the preview zooms too.");
    ImGui::SameLine();
    ImGui::Checkbox("Grid", &u.showGrid);
    at_track("pt:grid");
    if (!m.status().empty()) {
        ImGui::SameLine();
        ImGui::TextDisabled("%s", m.status().c_str());
    }
    if (u.focused && !ImGui::GetIO().WantTextInput && ImGui::IsKeyPressed(ImGuiKey_Space, false)) {
        u.playing = !u.playing;
        if (u.playing && u.preview->time() >= u.preview->timeline_length()) u.preview->seek(0.0);
    }
}

// --------------------------------------------------------------------------------------------------------- timeline --
void Editor::draw_particle_timeline(ParticleModel& m) {
    ParticleUi& u = particle_;
    ParticlePreview& pv = *u.preview;
    const std::vector<ParticlePartInfo> parts = m.parts();
    const double length = pv.timeline_length();
    const float rulerH = 16.0f, rowH = 7.0f;
    const float trackH = std::clamp(float(parts.size()) * rowH + 6.0f, 22.0f, 124.0f);
    const float w = std::max(120.0f, ImGui::GetContentRegionAvail().x);
    const ImVec2 p0 = ImGui::GetCursorScreenPos();
    ImGui::InvisibleButton("##pttimeline", ImVec2(w, rulerH + trackH));
    at_track("pt:timeline");
    const bool hovered = ImGui::IsItemHovered();
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const float x0 = p0.x + 6.0f, x1 = p0.x + w - 6.0f;
    u.tlX = x0;
    u.tlW = x1 - x0;
    u.tlY = p0.y;
    u.tlH = rulerH + trackH;
    u.tlLength = length;
    auto xat = [&](double t) { return x0 + float(std::clamp(t / length, 0.0, 1.0)) * (x1 - x0); };

    dl->AddRectFilled(p0, ImVec2(p0.x + w, p0.y + rulerH + trackH), IM_COL32(28, 30, 36, 255), 3.0f);
    // ruler: a tick about every 60 pixels at a round number of seconds
    const double steps[] = {0.05, 0.1, 0.25, 0.5, 1.0, 2.0, 5.0};
    double tick = steps[6];
    for (double s : steps)
        if (s / length * double(x1 - x0) >= 56.0) {
            tick = s;
            break;
        }
    for (double t = 0.0; t <= length + 1e-9; t += tick) {
        const float x = xat(t);
        dl->AddLine(ImVec2(x, p0.y + rulerH - 5), ImVec2(x, p0.y + rulerH), IM_COL32(150, 155, 170, 255));
        dl->AddText(ImVec2(x + 3, p0.y + 1), IM_COL32(150, 155, 170, 255), std::format("{:g}s", t).c_str());
    }
    if (m.doc()) {
        const float xe = xat(m.doc()->duration);
        dl->AddLine(ImVec2(xe, p0.y + rulerH), ImVec2(xe, p0.y + rulerH + trackH), IM_COL32(110, 120, 150, 255), 1.0f);
    }
    // the parts: a bar from `at` for `duration` (emitters and lights), a diamond at `at` (sounds and commands)
    for (const ParticlePartInfo& p : parts) {
        const float y = p0.y + rulerH + 3.0f + float(p.index) * rowH;
        if (y + rowH > p0.y + rulerH + trackH) break;
        const bool sel = p.index == u.selectedPart;
        const float xa = xat(p.at);
        if (p.type == "sound" || p.type == "command") {
            const ImU32 c = p.type == "sound" ? IM_COL32(110, 200, 255, 255) : IM_COL32(200, 150, 255, 255);
            const float cy = y + rowH * 0.5f;
            dl->AddQuadFilled(ImVec2(xa, cy - 3), ImVec2(xa + 3, cy), ImVec2(xa, cy + 3), ImVec2(xa - 3, cy), c);
            if (sel) dl->AddCircle(ImVec2(xa, cy), 5.0f, IM_COL32(255, 255, 255, 255), 12);
        } else {
            const float xb = std::max(xa + 3.0f, xat(p.at + p.duration));
            const ImU32 c = p.type == "light" ? IM_COL32(255, 215, 90, 255) : IM_COL32(255, 140, 70, 255);
            dl->AddRectFilled(ImVec2(xa, y + 1), ImVec2(xb, y + rowH - 1), c, 2.0f);
            if (sel) dl->AddRect(ImVec2(xa - 1, y), ImVec2(xb + 1, y + rowH), IM_COL32(255, 255, 255, 255), 2.0f);
        }
    }
    // the playhead
    const float xp = xat(pv.target_time());   // under the mouse even while the particles are catching up
    dl->AddLine(ImVec2(xp, p0.y), ImVec2(xp, p0.y + rulerH + trackH), IM_COL32(255, 80, 80, 255), 2.0f);
    dl->AddTriangleFilled(ImVec2(xp - 5, p0.y), ImVec2(xp + 5, p0.y), ImVec2(xp, p0.y + 7), IM_COL32(255, 80, 80, 255));

    // Pressing on the timeline puts the playhead there and keeps it under the mouse until the button is released; a press on a part's row
    // selects that part. Scrubbing pauses the preview (Play goes on from there).
    auto time_at_mouse = [&] { return std::clamp(double((ImGui::GetIO().MousePos.x - x0) / std::max(1.0f, x1 - x0)) * length, 0.0, length); };
    if (ImGui::IsItemActivated() && hovered) {
        const float my = ImGui::GetIO().MousePos.y - (p0.y + rulerH + 3.0f);
        if (my >= 0.0f) {
            const int row = int(my / rowH);
            if (row >= 0 && row < int(parts.size())) u.selectedPart = row;
        }
    }
    if (ImGui::IsItemActive()) {
        u.scrubbing = true;
        u.playing = false;
        const double t = time_at_mouse();
        if (std::abs(t - pv.target_time()) > 1e-6) pv.seek(t);
    } else if (u.scrubbing) {
        u.scrubbing = false;
    }
    hint("Click or drag to move the playhead: the effect is rebuilt up to that moment with the same seed, so a time always shows the same particles. "
         "A click on a part's bar selects it. Orange bars are emitters (the bar is their burst and `duration`), yellow lights, blue diamonds sounds and purple ones commands; "
         "the grey line is where the effect ends.");
}

// ------------------------------------------------------------------------------------------------------------ canvas --
void Editor::draw_particle_canvas(ParticleModel& m) {
    ParticleUi& u = particle_;
    ParticlePreview& pv = *u.preview;
    const ImVec2 size = ImGui::GetContentRegionAvail();
    const ImVec2 p0 = ImGui::GetCursorScreenPos();
    if (size.x < 40 || size.y < 40) return;
    ImGui::InvisibleButton("##ptpreview", size);
    at_track("pt:canvas");
    if (ImGui::IsItemHovered() && ImGui::GetIO().MouseWheel != 0.0f)
        u.zoom = std::clamp(u.zoom * std::pow(1.1f, ImGui::GetIO().MouseWheel), 0.25f, 6.0f);
    u.canvasX = p0.x;
    u.canvasY = p0.y;
    u.canvasW = size.x;
    u.canvasH = size.y;
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImVec2 p1(p0.x + size.x, p0.y + size.y);
    dl->AddRectFilled(p0, p1, IM_COL32(18, 19, 24, 255), 3.0f);
    dl->PushClipRect(p0, p1, true);
    const ImVec2 origin(p0.x + size.x * 0.5f, p0.y + size.y * 0.5f);
    if (u.showGrid) {
        float step = 50.0f * u.zoom;
        while (step < 24.0f) step *= 2.0f;
        for (float x = std::fmod(origin.x - p0.x, step); x < size.x; x += step) dl->AddLine(ImVec2(p0.x + x, p0.y), ImVec2(p0.x + x, p1.y), IM_COL32(40, 42, 52, 255));
        for (float y = std::fmod(origin.y - p0.y, step); y < size.y; y += step) dl->AddLine(ImVec2(p0.x, p0.y + y), ImVec2(p1.x, p0.y + y), IM_COL32(40, 42, 52, 255));
    }
    dl->AddLine(ImVec2(origin.x - 8, origin.y), ImVec2(origin.x + 8, origin.y), IM_COL32(90, 100, 130, 255));
    dl->AddLine(ImVec2(origin.x, origin.y - 8), ImVec2(origin.x, origin.y + 8), IM_COL32(90, 100, 130, 255));
    if (!m.doc()) {
        dl->AddText(ImVec2(p0.x + 8, p0.y + 8), IM_COL32(255, 140, 120, 255), "The file is not a valid effect: see Problems.");
        dl->PopClipRect();
        return;
    }
    // lights first: a glow of rings that gets fainter outwards
    for (const PreviewLight& l : pv.lights()) {
        const ImVec2 c(origin.x + l.x * u.zoom, origin.y + l.y * u.zoom);
        const float r = std::min(l.radius * u.zoom, 2000.0f);
        for (int k = 0; k < 6; ++k) {
            const float f = 1.0f - float(k) / 6.0f;
            dl->AddCircleFilled(c, r * f, col32(l.color, std::clamp(0.05f * l.intensity, 0.0f, 0.5f)), 32);
        }
    }
    int drawn = 0;
    for (const PreviewDot& d : pv.dots()) {
        if (++drawn > 4000) break;
        const ImVec2 c(origin.x + d.x * u.zoom, origin.y + d.y * u.zoom);
        const float r = std::max(0.75f, d.size * 0.5f * u.zoom);
        if (c.x + r < p0.x || c.x - r > p1.x || c.y + r < p0.y || c.y - r > p1.y) continue;
        // a soft particle: a faint halo and a firmer core (the renderer's texture is a soft disc)
        const float a = d.additive ? 0.8f : 1.0f;
        dl->AddCircleFilled(c, r, col32(d.color, 0.45f * a), r > 12.0f ? 24 : 12);
        dl->AddCircleFilled(c, r * 0.6f, col32(d.color, a), r > 12.0f ? 20 : 10);
    }
    dl->AddText(ImVec2(p0.x + 6, p0.y + 4), IM_COL32(150, 155, 170, 255),
                (std::format("{:.2f} s   {} particles   {} emitters   {} lights", pv.time(), pv.live_particles(), pv.live_emitters(), pv.lights().size()) +
                 (pv.catching_up() ? std::format("   (catching up to {:.2f} s)", pv.target_time()) : std::string())).c_str());
    dl->PopClipRect();
    hint("The preview: the effect played by the same timeline and particle simulation a game runs (additive blending shows as normal; ribbon trails are not drawn). "
         "The cross is the effect's position; +y is up. The mouse wheel zooms.");
}

// ------------------------------------------------------------------------------------------------------------- parts --
void Editor::draw_particle_parts(ParticleModel& m) {
    ParticleUi& u = particle_;
    const bool editable = play_ == PlayState::Edit && m.valid();
    const std::vector<ParticlePartInfo> parts = m.parts();
    if (u.selectedPart >= int(parts.size())) u.selectedPart = int(parts.size()) - 1;
    ImGui::SeparatorText("Parts");
    for (const ParticlePartInfo& p : parts) {
        ImGui::PushID(p.index);
        const std::string label = std::format("{}  {}  {}  at {:.2f} s###part", p.index, p.type, p.name.empty() ? "-" : p.name, p.at);
        if (ImGui::Selectable(label.c_str(), p.index == u.selectedPart)) u.selectedPart = p.index;
        at_track("pt:part:" + std::to_string(p.index));
        ImGui::PopID();
    }
    if (parts.empty()) ImGui::TextDisabled("No parts.");

    ImGui::BeginDisabled(!editable);
    const bool full = parts.size() >= 16;
    bool first = true;
    FitRow row;
    auto add = [&](const char* label, const char* track, const char* type, const char* tip) {
        if (!first) row.next(label);
        first = false;
        ImGui::BeginDisabled(full);
        if (ImGui::Button(label)) {
            std::string what;
            bool go = true;
            if (std::string(type) == "sound") {
                const std::vector<std::string> clips = list_asset_files(projectDir_, "audio", 1);
                if (clips.empty()) {
                    notify("No audio file in the project to play: add one first (assets.import or sfx.render).", 1);
                    go = false;
                } else {
                    what = clips.front();
                }
            }
            if (go) {
                const ParticleEditOutcome out = m.add_item("/parts", ParticleModel::starter_part(type, what), -1, std::string("Add ") + type);
                particle_edited(out);
                if (out.ok) u.selectedPart = int(m.parts().size()) - 1;
            }
        }
        at_track(track);
        ImGui::EndDisabled();
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("%s", full ? "An effect has at most 16 parts." : tip);
    };
    add("+ Emitter", "pt:add_emitter", "emitter", "vfx.edit add: a burst of particles at its time. Edit its look in the inspector below.");
    add("+ Light", "pt:add_light", "light", "vfx.edit add: a flash of light that fades out over its duration.");
    add("+ Sound", "pt:add_sound", "sound", "vfx.edit add: plays the first audio file of the project once; pick the clip in the inspector.");
    add("+ Command", "pt:add_command", "command", "vfx.edit add: calls a game feel command (feel.shake, feel.hitStop, ...) at its time.");
    const int sel = u.selectedPart;
    row.next("Up");
    ImGui::BeginDisabled(sel <= 0);
    if (ImGui::Button("Up")) {
        particle_edited(m.move_item("/parts", sel, sel - 1, "Move part up"));
        u.selectedPart = sel - 1;
    }
    at_track("pt:part_up");
    ImGui::EndDisabled();
    hint("Moves the selected part earlier in the list (the order only decides the default names and the order in this list).");
    row.next("Down");
    ImGui::BeginDisabled(sel < 0 || sel + 1 >= int(parts.size()));
    if (ImGui::Button("Down")) {
        particle_edited(m.move_item("/parts", sel, sel + 1, "Move part down"));
        u.selectedPart = sel + 1;
    }
    at_track("pt:part_down");
    ImGui::EndDisabled();
    hint("Moves the selected part later in the list.");
    row.next("Remove");
    ImGui::BeginDisabled(sel < 0);
    if (ImGui::Button("Remove")) particle_edited(m.remove_field("/parts/" + std::to_string(sel), "Remove part"));
    at_track("pt:part_remove");
    ImGui::EndDisabled();
    hint("Removes the selected part. An effect needs at least one.");
    ImGui::EndDisabled();
}

// ---------------------------------------------------------------------------------------------------------- inspector --
bool Editor::draw_particle_row(ParticleModel& m, const std::string& key, const FieldInfo& f, const std::string& pointer, const Json& cur, bool present) {
    const bool editable = play_ == PlayState::Edit && m.valid();
    ImGui::TableNextRow();
    ImGui::TableSetColumnIndex(0);
    ImGui::AlignTextToFramePadding();
    if (present) ImGui::TextUnformatted(f.name.c_str());
    else ImGui::TextDisabled("%s", f.name.c_str());
    hint(range_tip(f) + (present ? "" : "\n(Default: the effect does not set it.)"));
    ImGui::TableSetColumnIndex(1);
    Json out;
    bool edited = false;
    if (draw_field_widget(key, f, cur, !editable, out)) {
        edited = true;
        m.preview_field(pointer, out);
        // A text box, a checkbox or a pick is one edit at once; a drag stays in memory until the mouse is released.
        if (!ImGui::IsItemActive()) particle_edited(m.commit_field("Edit " + f.name));
    }
    ImGui::TableSetColumnIndex(2);
    if (present) {
        ImGui::PushID(key.c_str());
        ImGui::BeginDisabled(!editable);
        if (ImGui::SmallButton("x")) particle_edited(m.remove_field(pointer, "Reset " + f.name));
        at_track("pt:reset:" + key);
        ImGui::EndDisabled();
        hint("Back to the default: removes the field from the document.");
        ImGui::PopID();
    }
    return edited;
}

void Editor::draw_particle_object_fields(ParticleModel& m, const std::string& base, const TypeInfo& type, const Json& patch, bool essentialsOnly) {
    ParticleUi& u = particle_;
    static std::map<std::string, Json> defaults;
    auto it = defaults.find(type.name);
    if (it == defaults.end()) it = defaults.emplace(type.name, defaults_of(type)).first;
    const Json& def = it->second;
    const std::string filter = to_lower(u.fieldFilter);
    if (!ImGui::BeginTable(("##ptf" + type.name + (essentialsOnly ? "e" : "a")).c_str(), 3, ImGuiTableFlags_SizingStretchProp)) return;
    ImGui::TableSetupColumn("name", ImGuiTableColumnFlags_WidthStretch, 0.36f);
    ImGui::TableSetupColumn("value", ImGuiTableColumnFlags_WidthStretch, 0.60f);
    ImGui::TableSetupColumn("reset", ImGuiTableColumnFlags_WidthFixed, 18.0f);
    for (const FieldInfo& f : type.fields) {
        if (!inspector_shows(f) || f.readOnly) continue;
        if (type.name == "ParticleEmitter" && (f.name == "emitting" || f.name == "autoDestroy")) continue;   // the effect sets them
        if (curve_field(f.name)) continue;
        if (essentialsOnly && type.name == "ParticleEmitter" && !is_essential(f.name)) continue;
        if (!essentialsOnly && type.name == "ParticleEmitter" && is_essential(f.name)) continue;
        if (!filter.empty() && to_lower(f.name).find(filter) == std::string::npos) continue;
        const bool present = patch.is_object() && patch.contains(f.name);
        const Json cur = present ? patch[f.name] : (def.contains(f.name) ? def[f.name] : Json(nullptr));
        draw_particle_row(m, "pt:" + base + "/" + f.name, f, base + "/" + f.name, cur, present);
    }
    ImGui::EndTable();
}

void Editor::draw_particle_inspector(ParticleModel& m) {
    ParticleUi& u = particle_;
    const bool editable = play_ == PlayState::Edit && m.valid();
    const Json& doc = m.shown_json();

    // ---- the effect itself
    if (ImGui::CollapsingHeader("Effect", ImGuiTreeNodeFlags_DefaultOpen)) {
        if (ImGui::BeginTable("##pteffect", 3, ImGuiTableFlags_SizingStretchProp)) {
            ImGui::TableSetupColumn("name", ImGuiTableColumnFlags_WidthStretch, 0.36f);
            ImGui::TableSetupColumn("value", ImGuiTableColumnFlags_WidthStretch, 0.60f);
            ImGui::TableSetupColumn("reset", ImGuiTableColumnFlags_WidthFixed, 18.0f);
            static const FieldInfo docF = field_of("doc", FieldKind::String, "What the effect is and where the game plays it.");
            static const FieldInfo durF = field_of("duration", FieldKind::Float,
                                                   "Length of the effect in seconds. Left out (the default): until the last part has started and ended. "
                                                   "A part that starts after it is an error.", 0.05f, 30.0f);
            draw_particle_row(m, "pt:/doc", docF, "/doc", doc.contains("doc") ? doc["doc"] : Json(""), doc.contains("doc"));
            const double auto_len = m.doc() ? m.doc()->duration : 0.0;
            draw_particle_row(m, "pt:/duration", durF, "/duration", doc.contains("duration") ? doc["duration"] : Json(auto_len), doc.contains("duration"));
            ImGui::EndTable();
        }
    }

    // ---- problems
    const auto& issues = m.issues();
    if (!issues.empty()) {
        int errors = 0;
        for (const VfxIssue& i : issues) errors += i.error ? 1 : 0;
        ImGui::SetNextItemOpen(errors > 0, ImGuiCond_Once);
        if (ImGui::CollapsingHeader(std::format("Problems ({})###ptproblems", issues.size()).c_str())) {
            for (const VfxIssue& i : issues) {
                ImGui::TextColored(i.error ? kBad : kWarn, "%s", (i.pointer + ": " + i.message).c_str());
                hint(i.hint);
            }
        }
        at_track("pt:problems");
    }

    // ---- the selected part
    const std::vector<ParticlePartInfo> parts = m.parts();
    if (u.selectedPart < 0 || u.selectedPart >= int(parts.size())) {
        ImGui::TextDisabled("Select a part to edit it.");
        return;
    }
    const int index = u.selectedPart;
    const std::string base = "/parts/" + std::to_string(index);
    // The file may not be an effect (no `parts`, or not a list): the Problems above say so and there is no part to edit.
    if (!doc.is_object() || !doc.contains("parts") || !doc["parts"].is_array() || std::size_t(index) >= doc["parts"].size()) {
        ImGui::TextDisabled("This file has no part to edit: see Problems.");
        return;
    }
    const Json& part = doc["parts"][std::size_t(index)];
    const std::string type = part.is_object() ? part.value("type", std::string()) : std::string();
    ImGui::SeparatorText(std::format("Part {}: {}", index, type).c_str());

    static const FieldInfo nameF = field_of("name", FieldKind::String,
                                            "Name of the child entity an emitter or a light becomes (letters, digits, '_' and '-'); unique in the effect.");
    static const FieldInfo atF = field_of("at", FieldKind::Float, "Seconds after the effect starts that the part starts.", 0.0f, 30.0f);
    static const FieldInfo durF = field_of("duration", FieldKind::Float,
                                           "emitter: seconds it keeps emitting its `rate` after the burst (0: only the burst). light: seconds it lasts (default 0.2); it fades out over it.",
                                           0.0f, 30.0f);
    static const FieldInfo offsetF = field_of("offset", FieldKind::Vec3, "[x, y, z] relative to the effect's position.");
    static const FieldInfo is3dF = field_of("is3D", FieldKind::Bool, "true makes a 3D point Light instead of a Light2D.");
    static const FieldInfo clipF = [] {
        FieldInfo f = field_of("clip", FieldKind::Asset, "The audio file (project path) played once.");
        f.assetType = "audio";
        return f;
    }();
    static const FieldInfo volumeF = field_of("volume", FieldKind::Float, "Volume 0..1.", 0.0f, 1.0f);
    static const FieldInfo pitchF = field_of("pitch", FieldKind::Float, "Playback speed, 1 = as recorded.", 0.1f, 4.0f);
    static const FieldInfo busF = field_of("bus", FieldKind::String, "The mixer bus: \"sfx\", \"music\", \"ui\" or a bus of the project.");
    static const FieldInfo argsF = field_of("args", FieldKind::Json, "The arguments of the command, e.g. {\"amount\": 0.5}.");
    static const FieldInfo commandF = [] {
        FieldInfo f = field_of("command", FieldKind::Enum, "The command to call: only the game feel and audio playback commands an effect may use.");
        f.enumNames = vfx_allowed_commands();
        return f;
    }();

    auto val = [&](const char* k, Json fallback) { return part.contains(k) ? part[k] : fallback; };
    if (ImGui::BeginTable("##ptpart", 3, ImGuiTableFlags_SizingStretchProp)) {
        ImGui::TableSetupColumn("name", ImGuiTableColumnFlags_WidthStretch, 0.36f);
        ImGui::TableSetupColumn("value", ImGuiTableColumnFlags_WidthStretch, 0.60f);
        ImGui::TableSetupColumn("reset", ImGuiTableColumnFlags_WidthFixed, 18.0f);
        auto row = [&](const FieldInfo& f, Json fallback) {
            draw_particle_row(m, "pt:" + base + "/" + f.name, f, base + "/" + f.name, val(f.name.c_str(), std::move(fallback)), part.contains(f.name));
        };
        row(nameF, Json(""));
        row(atF, Json(0.0));
        if (type == "emitter" || type == "light") {
            row(durF, Json(type == "light" ? 0.2 : 0.0));
            row(offsetF, Json::array({0, 0, 0}));
        }
        if (type == "light") row(is3dF, Json(false));
        if (type == "sound") {
            row(clipF, Json(""));
            row(volumeF, Json(1.0));
            row(pitchF, Json(1.0));
            row(busF, Json("sfx"));
        }
        if (type == "command") {
            row(commandF, Json("feel.shake"));
            row(argsF, Json::object());
        }
        ImGui::EndTable();
    }

    if (type == "light") {
        const bool is3d = part.value("is3D", false);
        if (!part.contains("light")) {
            ImGui::BeginDisabled(!editable);
            if (ImGui::Button("Add light settings")) particle_edited(m.set_field(base + "/light", Json::object(), "Add light settings"));
            at_track("pt:add_light_settings");
            ImGui::EndDisabled();
            hint("The part has no `light` object yet: the light uses the component's defaults. This adds an empty one to edit.");
        } else {
            ImGui::TextDisabled("%s", is3d ? "Light" : "Light2D");
            const TypeInfo* t = component_type(is3d ? "Light" : "Light2D");
            if (t) draw_particle_object_fields(m, base + "/light", *t, part["light"], false);
        }
        draw_particle_curve_field(m, base + "/fade", "fade", val("fade", Json::array()), 0.0f, 1.0f);
        ImGui::TextDisabled("fade multiplies the light's intensity over its life; empty = a straight fade from 1 to 0.");
    }

    if (type == "emitter") {
        const TypeInfo* t = component_type("ParticleEmitter");
        if (!t || !part.contains("emitter")) {
            ImGui::TextColored(kBad, "This emitter part has no `emitter` object.");
            return;
        }
        const Json& em = part["emitter"];
        const std::string eb = base + "/emitter";
        ImGui::SeparatorText("Emitter");
        draw_particle_object_fields(m, eb, *t, em, true);
        for (const CurveField& c : kCurveFields) {
            if (std::string(c.name) == "trailWidthCurve" || std::string(c.name) == "trailGradient") continue;
            const Json cur = em.contains(c.name) ? em[c.name] : Json::array();
            if (c.gradient) draw_particle_gradient_field(m, eb + "/" + c.name, c.name, cur);
            else draw_particle_curve_field(m, eb + "/" + c.name, c.name, cur, c.lo, c.hi);
        }
        if (ImGui::CollapsingHeader("All other fields")) {
            ImGui::SetNextItemWidth(-FLT_MIN);
            ImGui::InputTextWithHint("##ptfilter", "filter fields", &u.fieldFilter);
            at_track("pt:filter");
            draw_particle_object_fields(m, eb, *t, em, false);
            for (const char* name : {"trailWidthCurve", "trailGradient"}) {
                const std::string f = to_lower(u.fieldFilter);
                if (!f.empty() && to_lower(name).find(f) == std::string::npos) continue;
                const Json cur = em.contains(name) ? em[name] : Json::array();
                if (std::string(name) == "trailGradient") draw_particle_gradient_field(m, eb + "/" + name, name, cur);
                else draw_particle_curve_field(m, eb + "/" + name, name, cur, 0.0f, 1.0f);
            }
        }
    }
}

// --------------------------------------------------------------------------------------------------- gradient editor --
bool Editor::draw_particle_gradient_field(ParticleModel& m, const std::string& pointer, const std::string& label, const Json& cur) {
    ParticleUi& u = particle_;
    const bool editable = play_ == PlayState::Edit && m.valid();
    ImGui::PushID(pointer.c_str());
    const std::string track = "pt:grad:" + label;
    bool changed = false;
    auto parsed = Gradient::parse(cur.is_null() ? Json::array() : cur, label);
    ImGui::AlignTextToFramePadding();
    ImGui::TextUnformatted(label.c_str());
    hint(std::format("{}\nKeys are [position 0..1, colour]; the colours blend linearly, alpha included. Click the bar to add a key, drag a key to move it. "
                     "Empty: the emitter fades from startColor to endColor.", label));
    if (!parsed.ok()) {
        ImGui::SameLine();
        ImGui::TextColored(kBad, "%s", parsed.error().message.c_str());
        ImGui::BeginDisabled(!editable);
        if (ImGui::SmallButton("Reset")) particle_edited(m.set_field(pointer, Json::array(), "Reset " + label));
        ImGui::EndDisabled();
        ImGui::PopID();
        return false;
    }
    Gradient g = *parsed;
    // The selected key belongs to ONE field (the one clicked last); the others draw with none selected.
    const bool mine = u.editorKey == pointer;
    const float w = std::max(120.0f, ImGui::GetContentRegionAvail().x - 8.0f);
    const float barH = 20.0f, markH = 12.0f;
    const ImVec2 p0 = ImGui::GetCursorScreenPos();
    ImGui::InvisibleButton("##bar", ImVec2(w, barH + markH));
    at_track(track);
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const float x0 = p0.x + 4.0f, x1 = p0.x + w - 4.0f;
    // a checkerboard under the bar shows the alpha
    for (int i = 0; i < 24; ++i) {
        const float xa = x0 + (x1 - x0) * float(i) / 24.0f, xb = x0 + (x1 - x0) * float(i + 1) / 24.0f;
        dl->AddRectFilled(ImVec2(xa, p0.y), ImVec2(xb, p0.y + barH * 0.5f), (i & 1) ? IM_COL32(70, 70, 70, 255) : IM_COL32(110, 110, 110, 255));
        dl->AddRectFilled(ImVec2(xa, p0.y + barH * 0.5f), ImVec2(xb, p0.y + barH), (i & 1) ? IM_COL32(110, 110, 110, 255) : IM_COL32(70, 70, 70, 255));
    }
    if (g.empty()) {
        dl->AddText(ImVec2(x0 + 4, p0.y + 3), IM_COL32(200, 200, 200, 255), "(default: startColor to endColor)");
    } else {
        constexpr int kSeg = 48;
        for (int i = 0; i < kSeg; ++i) {
            const float ta = float(i) / kSeg, tb = float(i + 1) / kSeg;
            dl->AddRectFilledMultiColor(ImVec2(x0 + (x1 - x0) * ta, p0.y), ImVec2(x0 + (x1 - x0) * tb, p0.y + barH), col32(g.eval(ta)), col32(g.eval(tb)),
                                        col32(g.eval(tb)), col32(g.eval(ta)));
        }
    }
    dl->AddRect(ImVec2(x0, p0.y), ImVec2(x1, p0.y + barH), IM_COL32(20, 20, 24, 255));
    for (std::size_t i = 0; i < g.keys.size(); ++i) {
        const float x = x0 + g.keys[i].t * (x1 - x0);
        const bool sel = mine && u.selectedKey == int(i);
        const ImU32 edge = sel ? IM_COL32(255, 255, 255, 255) : IM_COL32(20, 20, 24, 255);
        dl->AddTriangleFilled(ImVec2(x, p0.y + barH + 1), ImVec2(x - 5, p0.y + barH + markH), ImVec2(x + 5, p0.y + barH + markH), col32(g.keys[i].color, 1.0f) | IM_COL32_A_MASK);
        dl->AddTriangle(ImVec2(x, p0.y + barH + 1), ImVec2(x - 5, p0.y + barH + markH), ImVec2(x + 5, p0.y + barH + markH), edge, sel ? 2.0f : 1.0f);
    }
    // Press: pick the key under the mouse, or add one there. Drag: move it. Release: ONE edit.
    if (editable && ImGui::IsItemActivated()) {
        const ImVec2 mp = ImGui::GetIO().MousePos;
        int pick = -1;
        float best = 8.0f;
        for (std::size_t i = 0; i < g.keys.size(); ++i) {
            const float d = std::abs(x0 + g.keys[i].t * (x1 - x0) - mp.x);
            if (d < best) {
                best = d;
                pick = int(i);
            }
        }
        if (pick < 0) {
            pick = gradient_add_key(g, (mp.x - x0) / std::max(1.0f, x1 - x0));
            if (pick >= 0) {
                m.preview_field(pointer, g.to_json());
                changed = true;
            }
        }
        u.editorKey = pointer;
        u.selectedKey = pick;
        u.dragKey = pick;
        u.dragField = pointer;
    }
    if (editable && ImGui::IsItemActive() && u.dragKey >= 0 && u.dragField == pointer && ImGui::IsMouseDragging(ImGuiMouseButton_Left, 0.0f)) {
        if (gradient_move_key(g, u.dragKey, (ImGui::GetIO().MousePos.x - x0) / std::max(1.0f, x1 - x0))) {
            m.preview_field(pointer, g.to_json());
            changed = true;
        }
    }
    if (ImGui::IsItemDeactivated() && u.dragField == pointer) {
        u.dragKey = -1;
        u.dragField.clear();
        particle_edited(m.commit_field("Edit " + label));
    }
    if (mine && u.selectedKey >= int(g.keys.size())) u.selectedKey = -1;

    // The selected key: position and colour as numbers, and Remove.
    const int sk = u.editorKey == pointer ? u.selectedKey : -1;
    ImGui::BeginDisabled(!editable || sk < 0);
    float pos = sk >= 0 ? g.keys[std::size_t(sk)].t : 0.0f;
    float rgba[4] = {1, 1, 1, 1};
    if (sk >= 0) {
        const Color c = g.keys[std::size_t(sk)].color;
        rgba[0] = c.r;
        rgba[1] = c.g;
        rgba[2] = c.b;
        rgba[3] = c.a;
    }
    ImGui::SetNextItemWidth(64);
    if (ImGui::DragFloat("##keypos", &pos, 0.005f, 0.0f, 1.0f, "%.2f") && sk >= 0) {
        gradient_move_key(g, sk, pos);
        m.preview_field(pointer, g.to_json());
        changed = true;
    }
    at_track(track + ":pos");
    hint("Position of the selected key along the particle's life (0 = born, 1 = dies).");
    if (ImGui::IsItemDeactivatedAfterEdit()) particle_edited(m.commit_field("Edit " + label));
    ImGui::SameLine();
    if (ImGui::ColorEdit4("##keycolor", rgba, ImGuiColorEditFlags_AlphaBar | ImGuiColorEditFlags_Float | ImGuiColorEditFlags_NoInputs) && sk >= 0) {
        gradient_set_key_color(g, sk, Color{rgba[0], rgba[1], rgba[2], rgba[3]});
        m.preview_field(pointer, g.to_json());
        changed = true;
    }
    at_track(track + ":color");
    hint("Colour of the selected key, alpha included.");
    ImGui::SameLine();
    if (ImGui::SmallButton("Remove key") && sk >= 0) {
        gradient_remove_key(g, sk);
        u.selectedKey = -1;
        particle_edited(m.set_field(pointer, g.to_json(), "Remove " + label + " key"));
    }
    at_track(track + ":remove");
    ImGui::EndDisabled();
    hint("Removes the selected key. Removing them all brings back the startColor to endColor fade.");
    ImGui::PopID();
    return changed;
}

// ------------------------------------------------------------------------------------------------------ curve editor --
bool Editor::draw_particle_curve_field(ParticleModel& m, const std::string& pointer, const std::string& label, const Json& cur, float lo, float hi) {
    ParticleUi& u = particle_;
    const bool editable = play_ == PlayState::Edit && m.valid();
    ImGui::PushID(pointer.c_str());
    const std::string track = "pt:curve:" + label;
    bool changed = false;
    auto parsed = Curve::parse(cur.is_null() ? Json::array() : cur, label);
    ImGui::AlignTextToFramePadding();
    ImGui::TextUnformatted(label.c_str());
    hint(std::format("{}\nKeys are [position 0..1, value]. Click the graph to add a key, drag a key to move it. Empty: the field does nothing.", label));
    if (!parsed.ok()) {
        ImGui::SameLine();
        ImGui::TextColored(kBad, "%s", parsed.error().message.c_str());
        ImGui::BeginDisabled(!editable);
        if (ImGui::SmallButton("Reset")) particle_edited(m.set_field(pointer, Json::array(), "Reset " + label));
        ImGui::EndDisabled();
        ImGui::PopID();
        return false;
    }
    Curve c = *parsed;
    const bool mine = u.editorKey == pointer;
    float vlo = lo, vhi = hi;
    {
        float klo, khi;
        curve_value_range(c, klo, khi);
        vlo = std::min(vlo, klo);
        vhi = std::max(vhi, khi);
    }
    // The graph's scale stays what it was when a drag began, so the key does not run away from the mouse.
    if (u.dragKey >= 0 && u.dragField == pointer) {
        vlo = u.dragLo;
        vhi = u.dragHi;
    }
    const float pad = (vhi - vlo) * 0.08f;
    const float vmin = vlo - pad, vmax = vhi + pad;
    const float w = std::max(120.0f, ImGui::GetContentRegionAvail().x - 8.0f);
    const float h = 96.0f;
    const ImVec2 p0 = ImGui::GetCursorScreenPos();
    ImGui::InvisibleButton("##curve", ImVec2(w, h));
    at_track(track);
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const float x0 = p0.x + 4.0f, x1 = p0.x + w - 4.0f, y0 = p0.y + 4.0f, y1 = p0.y + h - 4.0f;
    auto sx = [&](float t) { return x0 + t * (x1 - x0); };
    auto sy = [&](float v) { return y1 - (v - vmin) / (vmax - vmin) * (y1 - y0); };
    dl->AddRectFilled(p0, ImVec2(p0.x + w, p0.y + h), IM_COL32(24, 26, 32, 255), 3.0f);
    for (int i = 0; i <= 4; ++i) dl->AddLine(ImVec2(sx(float(i) / 4.0f), y0), ImVec2(sx(float(i) / 4.0f), y1), IM_COL32(44, 47, 58, 255));
    // Horizontal grid lines at whole values; a wide range steps by 1, 2 or 5 x 10^n (curve_grid_values), never more than
    // kCurveGridMaxLines lines: a key of 1e9 must not loop a billion times.
    for (const float v : curve_grid_values(vlo, vhi)) {
        dl->AddLine(ImVec2(x0, sy(v)), ImVec2(x1, sy(v)), v == 0.0f || v == 1.0f ? IM_COL32(70, 76, 94, 255) : IM_COL32(44, 47, 58, 255));
        dl->AddText(ImVec2(x0 + 2, sy(v) - 12), IM_COL32(110, 115, 135, 255), std::format("{:g}", v).c_str());
    }
    if (c.empty()) {
        dl->AddText(ImVec2(x0 + 24, (y0 + y1) * 0.5f - 6), IM_COL32(150, 155, 170, 255), "(empty: click to add a key)");
    } else {
        constexpr int kN = 64;
        ImVec2 prev;
        for (int i = 0; i <= kN; ++i) {
            const float t = float(i) / kN;
            const ImVec2 pt(sx(t), sy(c.eval(t)));
            if (i > 0) dl->AddLine(prev, pt, IM_COL32(120, 190, 255, 255), 1.8f);
            prev = pt;
        }
    }
    for (std::size_t i = 0; i < c.keys.size(); ++i) {
        const bool sel = mine && u.selectedKey == int(i);
        const ImVec2 kp(sx(c.keys[i].t), sy(c.keys[i].value));
        dl->AddCircleFilled(kp, sel ? 5.5f : 4.0f, sel ? IM_COL32(255, 255, 255, 255) : IM_COL32(120, 190, 255, 255), 14);
        dl->AddCircle(kp, sel ? 5.5f : 4.0f, IM_COL32(20, 20, 24, 255), 14);
    }
    if (editable && ImGui::IsItemActivated()) {
        const ImVec2 mp = ImGui::GetIO().MousePos;
        int pick = -1;
        float best = 10.0f;
        for (std::size_t i = 0; i < c.keys.size(); ++i) {
            const float dx = sx(c.keys[i].t) - mp.x, dy = sy(c.keys[i].value) - mp.y;
            const float d = std::sqrt(dx * dx + dy * dy);
            if (d < best) {
                best = d;
                pick = int(i);
            }
        }
        u.dragLo = vlo;
        u.dragHi = vhi;
        u.dragField = pointer;
        if (pick < 0) {
            const float t = (mp.x - x0) / std::max(1.0f, x1 - x0);
            const float v = vmin + (y1 - mp.y) / std::max(1.0f, y1 - y0) * (vmax - vmin);
            pick = curve_add_key(c, t, v);
            if (pick >= 0) {
                m.preview_field(pointer, c.to_json());
                changed = true;
            }
        }
        u.editorKey = pointer;
        u.selectedKey = pick;
        u.dragKey = pick;
    }
    if (editable && ImGui::IsItemActive() && u.dragKey >= 0 && u.dragField == pointer && ImGui::IsMouseDragging(ImGuiMouseButton_Left, 0.0f)) {
        const ImVec2 mp = ImGui::GetIO().MousePos;
        const float t = (mp.x - x0) / std::max(1.0f, x1 - x0);
        const float v = vmin + (y1 - mp.y) / std::max(1.0f, y1 - y0) * (vmax - vmin);
        if (curve_move_key(c, u.dragKey, t, std::clamp(v, u.dragLo - pad, u.dragHi + pad))) {
            m.preview_field(pointer, c.to_json());
            changed = true;
        }
    }
    if (ImGui::IsItemDeactivated() && u.dragField == pointer) {
        u.dragKey = -1;
        u.dragField.clear();
        particle_edited(m.commit_field("Edit " + label));
    }
    if (mine && u.selectedKey >= int(c.keys.size())) u.selectedKey = -1;

    // The selected key as numbers, the interpolation, Remove and Clear.
    const int sk = u.editorKey == pointer ? u.selectedKey : -1;
    ImGui::BeginDisabled(!editable);
    ImGui::BeginDisabled(sk < 0);
    float kt = sk >= 0 ? c.keys[std::size_t(sk)].t : 0.0f, kv = sk >= 0 ? c.keys[std::size_t(sk)].value : 0.0f;
    ImGui::SetNextItemWidth(60);
    bool keyEdited = ImGui::DragFloat("##keyt", &kt, 0.005f, 0.0f, 1.0f, "t %.2f");
    at_track(track + ":t");
    hint("Position of the selected key along the particle's life (0 = born, 1 = dies).");
    if (ImGui::IsItemDeactivatedAfterEdit()) particle_edited(m.commit_field("Edit " + label));
    ImGui::SameLine();
    ImGui::SetNextItemWidth(70);
    keyEdited |= ImGui::DragFloat("##keyv", &kv, 0.01f, 0.0f, 0.0f, "v %.2f");
    at_track(track + ":v");
    hint("Value of the selected key. The curve multiplies the field it belongs to.");
    if (ImGui::IsItemDeactivatedAfterEdit()) particle_edited(m.commit_field("Edit " + label));
    if (keyEdited && sk >= 0) {
        curve_move_key(c, sk, kt, kv);
        m.preview_field(pointer, c.to_json());
        changed = true;
    }
    ImGui::EndDisabled();
    ImGui::SameLine();
    int interp = int(c.interp);
    ImGui::SetNextItemWidth(84);
    if (ImGui::Combo("##interp", &interp, "linear\0smooth\0step\0")) {
        c.interp = CurveInterp(interp);
        particle_edited(m.set_field(pointer, c.to_json(), "Set " + label + " interpolation"));
    }
    at_track(track + ":interp");
    hint("How the curve goes from one key to the next: linear, smooth (ease in and out) or step (jumps at each key).");
    FitRow row;
    ImGui::SameLine();
    ImGui::BeginDisabled(sk < 0);
    if (ImGui::SmallButton("Remove key")) {
        curve_remove_key(c, sk);
        u.selectedKey = -1;
        particle_edited(m.set_field(pointer, c.to_json(), "Remove " + label + " key"));
    }
    at_track(track + ":remove");
    ImGui::EndDisabled();
    hint("Removes the selected key.");
    ImGui::SameLine();
    ImGui::BeginDisabled(c.empty());
    if (ImGui::SmallButton("Clear")) {
        u.selectedKey = -1;
        particle_edited(m.set_field(pointer, Json::array(), "Clear " + label));
    }
    at_track(track + ":clear");
    ImGui::EndDisabled();
    hint("Removes every key: the field does nothing again.");
    ImGui::EndDisabled();
    ImGui::PopID();
    (void)row;
    return changed;
}

}  // namespace fa::editor
