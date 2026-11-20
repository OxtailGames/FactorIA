// The Lightmap panel (View > Lightmap): bakes the open scene's baked lights, its sky and its lit meshes into lightmaps, with a progress bar
// and Cancel. Nothing here bakes: every action is a command (lightmap.bake_start, lightmap.bake_status, lightmap.bake_cancel) that the
// CLI and MCP run the same way. The job runs on a job thread of the engine, so the editor never waits for it: lightmap_poll asks for the
// state a few times a second, and the only work it does on the UI thread is the JSON of one small answer.
//
// The bake is started with apply false: when it is done the panel sets SceneSettings.lightmaps with scene_settings_edit, so the change is
// one undo step and the scene is dirty. It does that only when the scene it was started on is still the open one (the engine says so in the
// answer's handOver) and the game is not running; otherwise it says why and where the files are.
#include <algorithm>
#include <cfloat>
#include <cmath>
#include <cstdio>

#include "editor_internal.h"
#include "fa/core/strings.h"
#include "inspector_model.h"

namespace fa::editor {

namespace {

constexpr int kLightmapPageSizes[] = {512, 1024, 2048, 4096};
const char* const kLightmapSkies[] = {"auto", "environment", "gradient", "ambient", "none"};
constexpr const char* kLightmapSkyHints[] = {
    "The environment map when the scene has one, else the scene's ambient light.",
    "The scene's environment map (SceneSettings.environmentMap), rotated and scaled like the renderer does.",
    "The scene's sky gradient colours.",
    "A flat sky of the scene's ambient light colour.",
    "No light from the sky: only the lights and emitters."};

void tip(const char* text) {
    if (!ImGui::BeginItemTooltip()) return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text);
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

std::string seconds_text(double s) {
    char buf[48];
    if (s >= 90)
        std::snprintf(buf, sizeof buf, "%d min %02d s", int(s / 60), int(std::fmod(s, 60.0)));
    else
        std::snprintf(buf, sizeof buf, "%.1f s", s);
    return buf;
}

std::string count_text(double n) {
    char buf[48];
    if (n >= 1e9)
        std::snprintf(buf, sizeof buf, "%.2f G", n / 1e9);
    else if (n >= 1e6)
        std::snprintf(buf, sizeof buf, "%.1f M", n / 1e6);
    else if (n >= 1e3)
        std::snprintf(buf, sizeof buf, "%.1f k", n / 1e3);
    else
        std::snprintf(buf, sizeof buf, "%.0f", n);
    return buf;
}

}  // namespace

bool Editor::lightmap_start(std::string* error) {
    std::string err;
    auto fail = [&](const std::string& message, const std::string& hint) {
        lightmap_.error = message;
        lightmap_.hint = hint;
        lightmap_.note.clear();
        if (error) *error = message;
        return false;
    };
    if (!engine_) return fail("No project is open.", "Open or create a project, then open a 3D scene.");
    if (play_ != PlayState::Edit) return fail("The game is running.", "Stop the game, then bake: a bake reads the scene as it is saved.");
    if (lightmap_.state == "running") return fail("A bake is already running.", "Cancel it, or wait for it to finish.");
    Json args = Json::object();
    args["texelsPerMeter"] = double(std::clamp(lightmap_.texelsPerMeter, 0.01f, 4096.0f));
    args["samples"] = std::clamp(lightmap_.samples, 1, 65536);
    args["shadowSamples"] = std::clamp(lightmap_.shadowSamples, 1, 1024);
    args["maxPageSize"] = kLightmapPageSizes[std::clamp(lightmap_.pageSizeIndex, 0, 3)];
    args["sky"] = kLightmapSkies[std::clamp(lightmap_.skyIndex, 0, 4)];
    if (!lightmap_.path.empty()) args["path"] = lightmap_.path;
    args["apply"] = false;  // the panel sets SceneSettings.lightmaps itself: an undo step and a dirty scene
    const CommandResult r = engine_->commands().call("lightmap.bake_start", args);
    if (!r.ok) {
        const std::string text = command_error_text(r.error);
        return fail(r.error.value("message", text), r.error.value("hint", std::string()));
    }
    lightmap_ = LightmapUi{lightmap_.texelsPerMeter, lightmap_.samples, lightmap_.shadowSamples, lightmap_.pageSizeIndex,
                           lightmap_.skyIndex,       lightmap_.path};
    lightmap_.job = r.result.value("job", std::string());
    lightmap_.scene = scenePath_;
    lightmap_.engine = engine_.get();
    lightmap_.state = "running";
    lightmap_.phase = r.result.value("phase", std::string("starting"));
    lightmap_.lastPoll = -1;
    return true;
}

void Editor::lightmap_cancel() {
    if (!engine_ || lightmap_.job.empty() || lightmap_.state != "running" || lightmap_.engine != engine_.get()) return;
    (void)engine_->commands().call("lightmap.bake_cancel", Json::object({{"job", lightmap_.job}}));
    lightmap_.lastPoll = -1;  // look at the state on the next frame
}

void Editor::lightmap_poll() {
    if (lightmap_.state != "running") return;
    if (!engine_ || lightmap_.engine != engine_.get()) {  // the project was closed: its job is gone
        lightmap_.state = "failed";
        lightmap_.error = "The bake stopped with the project it was started on.";
        lightmap_.hint = "Open the project and bake again.";
        return;
    }
    if (lightmap_.lastPoll >= 0 && time_ - lightmap_.lastPoll < 0.1) return;
    lightmap_.lastPoll = time_;
    const CommandResult r = engine_->commands().call("lightmap.bake_status", Json::object({{"job", lightmap_.job}, {"apply", false}}));
    if (!r.ok) {
        lightmap_.state = "failed";
        lightmap_.error = r.error.value("message", command_error_text(r.error));
        lightmap_.hint = r.error.value("hint", std::string());
        return;
    }
    const Json& s = r.result;
    lightmap_.state = s.value("state", std::string("failed"));
    lightmap_.phase = s.value("phase", std::string());
    lightmap_.progress = s.value("progress", 0.0);
    lightmap_.elapsed = s.value("elapsedSeconds", 0.0);
    lightmap_.eta = s.contains("etaSeconds") ? s.value("etaSeconds", -1.0) : -1.0;
    lightmap_.rays = s.value("rays", std::uint64_t(0));
    if (lightmap_.state == "failed" || lightmap_.state == "cancelled") {
        lightmap_.error = lightmap_.state == "cancelled" ? "The bake was cancelled; no file was changed." : s.value("error", std::string());
        lightmap_.hint = s.value("hint", std::string());
        return;
    }
    if (lightmap_.state != "done") return;
    lightmap_.result = s.value("result", Json::object());
    // The scene it was started on is still the open one (the engine checked its own current scene; the editor's path is the second check)
    // and the game is not running: the manifest becomes SceneSettings.lightmaps, one undo step.
    const std::string manifest = s.value("manifest", std::string());
    const Json hand = s.value("handOver", Json::object());
    if (!hand.contains("settingsChanged")) {
        lightmap_.note = hand.value("note", std::string("The scene was changed during the bake: SceneSettings.lightmaps was not set."));
    } else if (lightmap_.scene != scenePath_) {
        lightmap_.note = "Another scene is open now: SceneSettings.lightmaps was not set. Open the baked scene and set it to '" + manifest + "'.";
    } else if (play_ != PlayState::Edit) {
        lightmap_.note = "The game is running: SceneSettings.lightmaps was not set. Stop, then set it to '" + manifest + "'.";
    } else if (world().settings().lightmaps == manifest) {
        lightmap_.note = "The scene already uses '" + manifest + "': the renderer loaded the new pages.";
    } else {
        std::string err;
        if (scene_settings_edit("lightmaps", manifest, false, &err))
            lightmap_.note = "SceneSettings.lightmaps = '" + manifest + "' (Undo takes it back). Save the scene to keep it.";
        else
            lightmap_.note = "Could not set SceneSettings.lightmaps: " + err;
    }
}

void Editor::draw_lightmap_panel() {
    first_floating_window(ImVec2(200, 80), ImVec2(440, 520));
    if (!ImGui::Begin("Lightmap", &showLightmap_)) {
        ImGui::End();
        return;
    }
    if (!engine_) {
        ImGui::TextDisabled("Open a project to bake the lightmaps of its scene.");
        ImGui::End();
        return;
    }
    lightmap_poll();
    const bool running = lightmap_.state == "running";
    ImGui::TextWrapped("Bakes the scene's baked lights, its sky and its lit meshes into lightmap pages next to the scene.");
    draw_play_banner(*this);

    ImGui::BeginDisabled(running);
    if (ImGui::BeginTable("##opts", 2, ImGuiTableFlags_SizingStretchProp)) {
        ImGui::TableSetupColumn("name", ImGuiTableColumnFlags_WidthStretch, 0.4f);
        ImGui::TableSetupColumn("value", ImGuiTableColumnFlags_WidthStretch, 0.6f);
        auto row = [](const char* label, const char* hint) {
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted(label);
            tip(hint);
            ImGui::TableSetColumnIndex(1);
            ImGui::SetNextItemWidth(-FLT_MIN);
        };
        row("Texels per meter", "Lightmap texels per meter of surface (times each MeshRenderer.lightmapScale). 16 is a good start; 64 gives sharp shadows with 16 times the texels and a longer bake.");
        ImGui::DragFloat("##tpm", &lightmap_.texelsPerMeter, 0.5f, 0.5f, 256.0f, "%.1f");
        tip("Lightmap texels per meter of surface. 16 is a good start; 64 is sharp and 16 times heavier.");
        at_track("lm:tpm", !running);
        row("Samples", "Gather rays per texel for the sky, emitters and bounced light: 16 is a draft, 64 is smooth.");
        ImGui::DragInt("##samples", &lightmap_.samples, 1.0f, 1, 4096);
        tip("Gather rays per texel: 16 is a draft, 64 is smooth.");
        row("Shadow samples", "Shadow rays per light per texel: more makes softer, smoother shadows.");
        ImGui::DragInt("##shadow", &lightmap_.shadowSamples, 1.0f, 1, 256);
        tip("Shadow rays per light per texel: more makes softer, smoother shadows.");
        row("Page size", "The longest side of a page in texels. More meshes than fit make more pages.");
        if (ImGui::BeginCombo("##page", std::to_string(kLightmapPageSizes[std::clamp(lightmap_.pageSizeIndex, 0, 3)]).c_str())) {
            for (int i = 0; i < 4; ++i)
                if (ImGui::Selectable(std::to_string(kLightmapPageSizes[i]).c_str(), i == lightmap_.pageSizeIndex)) lightmap_.pageSizeIndex = i;
            ImGui::EndCombo();
        }
        tip("The longest side of a page in texels. More meshes than fit make more pages.");
        row("Sky", kLightmapSkyHints[std::clamp(lightmap_.skyIndex, 0, 4)]);
        if (ImGui::BeginCombo("##sky", kLightmapSkies[std::clamp(lightmap_.skyIndex, 0, 4)])) {
            for (int i = 0; i < 5; ++i) {
                if (ImGui::Selectable(kLightmapSkies[i], i == lightmap_.skyIndex)) lightmap_.skyIndex = i;
                tip(kLightmapSkyHints[i]);
            }
            ImGui::EndCombo();
        }
        tip(kLightmapSkyHints[std::clamp(lightmap_.skyIndex, 0, 4)]);
        row("Manifest", "Where the manifest is written, inside the project (.lightmap.json); the pages go next to it. Empty: next to the open scene.");
        ImGui::InputTextWithHint("##path", "next to the scene", &lightmap_.path);
        tip("Where the manifest is written, inside the project (.lightmap.json); the pages go next to it. Empty: next to the open scene.");
        ImGui::EndTable();
    }
    ImGui::EndDisabled();

    ImGui::BeginDisabled(running || play_ != PlayState::Edit);
    if (ImGui::Button("Start")) {
        std::string err;
        if (!lightmap_start(&err)) notify("Lightmap bake: " + err, 2);
    }
    at_track("lm:start", !running && play_ == PlayState::Edit);
    tip("Bake on a job thread: the editor stays usable. A finished bake replaces the pages of the same manifest and sets SceneSettings.lightmaps (one undo step).");
    ImGui::EndDisabled();
    ImGui::SameLine();
    ImGui::BeginDisabled(!running);
    if (ImGui::Button("Cancel")) lightmap_cancel();
    at_track("lm:cancel", running);
    tip("Stop the bake. No file is changed unless it was already writing them.");
    ImGui::EndDisabled();

    if (running) {
        std::string overlay = lightmap_.phase.empty() ? "starting" : lightmap_.phase;
        char buf[64];
        std::snprintf(buf, sizeof buf, "  %d%%", int(lightmap_.progress * 100.0));
        overlay += buf;
        if (lightmap_.eta >= 0) overlay += "  about " + seconds_text(lightmap_.eta) + " left";
        ImGui::ProgressBar(float(std::clamp(lightmap_.progress, 0.0, 1.0)), ImVec2(-FLT_MIN, 0), overlay.c_str());
        at_track("lm:progress");
        if (lightmap_.rays > 0) ImGui::TextDisabled("%s rays traced, %s", count_text(double(lightmap_.rays)).c_str(), seconds_text(lightmap_.elapsed).c_str());
    }
    if (!lightmap_.error.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, lightmap_.state == "cancelled" ? kStatusWarn : kStatusFailed);
        ImGui::TextWrapped("%s", lightmap_.error.c_str());
        ImGui::PopStyleColor();
        if (!lightmap_.hint.empty()) ImGui::TextWrapped("%s", lightmap_.hint.c_str());
        at_track("lm:error");
    }
    if (lightmap_.state == "done" && lightmap_.result.is_object()) {
        const Json& res = lightmap_.result;
        ImGui::Separator();
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusReady);
        ImGui::TextUnformatted("Baked.");
        ImGui::PopStyleColor();
        const Json pages = res.value("pages", Json::array());
        ImGui::Text("%d page(s), %s texels, %d mesh(es), %s rays, %s", int(pages.size()), count_text(res.value("texels", 0.0)).c_str(),
                    res.value("entities", 0), count_text(double(res.value("rays", std::uint64_t(0)))).c_str(),
                    seconds_text(lightmap_.elapsed).c_str());
        at_track("lm:summary");
        for (const Json& p : pages)
            ImGui::BulletText("%s  %d x %d", p.value("file", std::string()).c_str(), p.value("width", 0), p.value("height", 0));
        for (const Json& sk : res.value("skipped", Json::array()))
            ImGui::TextDisabled("skipped %s: %s", sk.value("id", std::string()).c_str(), sk.value("reason", std::string()).c_str());
        for (const Json& w : res.value("warnings", Json::array())) {
            ImGui::PushStyleColor(ImGuiCol_Text, kStatusWarn);
            ImGui::TextWrapped("%s", w.is_string() ? w.get<std::string>().c_str() : "");
            ImGui::PopStyleColor();
        }
        if (!lightmap_.note.empty()) ImGui::TextWrapped("%s", lightmap_.note.c_str());
        at_track("lm:note");
    }
    ImGui::End();
}

}  // namespace fa::editor
