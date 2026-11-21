// Post-processing panel (View > Post-processing): the stack a camera draws, in the order its effects run. Every effect shows whether it
// runs, what this renderer draws of it (the render.supports table: unsupported, with the reason), and its fields with the source of
// each value (the camera's own PostProcess, or a volume). Nothing here edits the world directly: an
// edit is a postprocess.set call and a preset button a postprocess.apply_preset call, both through Editor::edit_command (the path of
// the Console and the AI, one undo step each), on the camera's own PostProcess or on the volume chosen as the edit target. The A/B
// checkbox turns the stack off in the renderer (Renderer::set_post_bypass) and changes no data. The stack shown is
// `postprocess.get {resolved: true}`: the same one the renderer draws, computed on the CPU (render::post_stack_report called directly: a
// command call every frame would reach the console and the MCP history through the command interceptor).
#include <algorithm>
#include <cmath>
#include <utility>

#include "editor_internal.h"
#include "fa/core/fs.h"
#include "fa/core/reflect.h"
#include "fa/render/post_custom.h"
#include "fa/render/post_report.h"
#include "fa/render/renderer.h"
#include "fa/runtime/postprocess_presets.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/postprocess.h"
#include "imgui_internal.h"
#include "postfx_custom.h"

namespace fa::editor {

namespace {

const ImVec4 kGreen(0.4f, 0.9f, 0.5f, 1.0f);
const ImVec4 kOrange(1.0f, 0.75f, 0.3f, 1.0f);
const ImVec4 kRed(1.0f, 0.45f, 0.4f, 1.0f);

void tip(const std::string& text) {
    if (text.empty() || !ImGui::BeginItemTooltip()) return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text.c_str());
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

// The tooltip of a widget that may be disabled (BeginItemTooltip stays silent on a disabled item).
void tip_always(const std::string& text) {
    if (text.empty() || !ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled | ImGuiHoveredFlags_ForTooltip) ||
        !ImGui::BeginTooltip())
        return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text.c_str());
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

// What the renderer says about one effect: supported, or why not (one sentence naming the backend or the GPU).
struct EffectSupport {
    bool known = false;
    bool supported = true;
    std::string status;
};

EffectSupport support_of(const Json& table, const std::string& effect) {
    EffectSupport s;
    if (!table.is_object() || !table.contains("features")) return s;
    for (const Json& f : table["features"]) {
        if (!f.is_object() || f.value("name", std::string()) != effect) continue;
        s.known = true;
        s.supported = f.value("supported", false);
        s.status = f.value("status", std::string());
        break;
    }
    return s;
}

const Json* effect_entry(const Json& report, const std::string& effect) {
    if (!report.is_object() || !report.contains("resolved")) return nullptr;
    const Json& r = report["resolved"];
    if (!r.is_object() || !r.contains("effects")) return nullptr;
    for (const Json& e : r["effects"])
        if (e.value("name", std::string()) == effect) return &e;
    return nullptr;
}

}  // namespace

std::string Editor::postfx_target_id() {
    if (!postFx_.target.empty()) return postFx_.target;
    return postFx_.report.is_object() ? postFx_.report.value("id", std::string()) : std::string();
}

bool Editor::postfx_edit(const Json& fields, bool ownStep, int entry) {
    const std::string id = postfx_target_id();
    postFx_.error.clear();
    if (id.empty()) {
        postFx_.error = "There is no camera to edit: add a Camera to the scene, or choose a volume as the edit target.";
        return false;
    }
    std::string key = "postfx:" + id + ":";
    for (auto it = fields.begin(); it != fields.end(); ++it) key += it.key() + ",";
    if (entry >= 0) key += "#" + std::to_string(entry) + ",";  // a drag on one custom pass never merges into another's
    if (ownStep) key += std::to_string(uiFrame_);
    std::string err;
    const CommandResult r = edit_command(key, "postprocess.set", Json::object({{"id", id}, {"fields", fields}}), &err);
    if (!r.ok) postFx_.error = err;
    return r.ok;
}

bool Editor::postfx_preset(const std::string& name) {
    const std::string id = postfx_target_id();
    postFx_.error.clear();
    postFx_.note.clear();
    if (id.empty()) {
        postFx_.error = "There is no camera to edit: add a Camera to the scene, or choose a volume as the edit target.";
        return false;
    }
    std::string err;
    const CommandResult r =
        edit_command("postfx:preset:" + std::to_string(uiFrame_), "postprocess.apply_preset",
                     Json::object({{"id", id}, {"preset", name}, {"keep", postFx_.keepOthers}}), &err);
    if (!r.ok) {
        postFx_.error = err;
        return false;
    }
    if (r.result.is_object() && r.result.contains("note") && r.result["note"].is_string())
        postFx_.note = r.result["note"].get<std::string>();
    if (r.result.is_object() && r.result.contains("notDrawn") && r.result["notDrawn"].is_array() &&
        !r.result["notDrawn"].empty()) {
        postFx_.note += " Not drawn:";
        for (const Json& n : r.result["notDrawn"]) postFx_.note += " " + n.value("effect", std::string());
        postFx_.note += ".";
    }
    return true;
}

void Editor::postfx_release() {
    if (postFx_.bypassSet && engine_ && engine_->renderer()) engine_->renderer()->set_post_bypass(false);
    postFx_.bypassSet = false;
    postFx_.compare = false;
}

void Editor::draw_postfx_panel() {
    // A window of its own (like the Level generator), not a tab of the narrow right column: the effects and their fields need width.
    ImGui::SetNextWindowSize(ImVec2(460, 540), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowPos(ImVec2(220, 90), ImGuiCond_FirstUseEver);
    Renderer* renderer = engine_ ? engine_->renderer() : nullptr;
    if (!ImGui::Begin("Post-processing", &showPostFx_)) {
        // A panel that is not on screen must not leave the picture without its stack: the A/B switch only holds while it is seen.
        // The check is not seen either: it goes back to off, or it would stay on while the picture has its stack again.
        if (postFx_.bypassSet && renderer) renderer->set_post_bypass(false);
        postFx_.bypassSet = false;
        postFx_.compare = false;
        ImGui::End();
        return;
    }
    if (!engine_) {
        ImGui::TextDisabled("No project is open.");
        ImGui::End();
        return;
    }
    World& w = world();
    const TypeInfo* type = TypeRegistry::global().of<PostProcess>();
    if (!type) {
        ImGui::TextDisabled("PostProcess is not registered.");
        ImGui::End();
        return;
    }

    // The answers of the engine, once per frame: the stack of the chosen camera and (every few seconds) what the renderer draws.
    {
        std::vector<std::string> cameras;
        w.each<Camera>([&](Entity e, Camera&) { cameras.push_back(w.id_of(e)); });
        if (!postFx_.camera.empty() && std::find(cameras.begin(), cameras.end(), postFx_.camera) == cameras.end())
            postFx_.camera.clear();  // the camera was deleted
        // The chosen camera, or the main one (the renderer's own choice). No command call: nothing is logged per frame.
        Entity cam = kNullEntity;
        if (!postFx_.camera.empty())
            cam = w.find_by_id(postFx_.camera);
        else if (const std::vector<Entity> cams = rendering_cameras(w); !cams.empty())
            cam = cams.front();
        postFx_.report = Json::object(
            {{"id", cam.is_null() ? std::string() : w.id_of(cam)}, {"resolved", render::post_stack_report(w, cam)}});
        if (postFx_.support.is_null() || time_ - postFx_.supportAt > 3.0) {
            // The renderer's own table (what render.supports answers), not a command call: nothing is logged every few seconds.
            const Renderer* r = engine_->renderer();
            postFx_.support = r ? r->supports_report() : Json::object();
            postFx_.supportAt = time_;
        }
    }
    const bool haveReport = postFx_.report.is_object() && postFx_.report.contains("resolved");
    const std::string cameraId = haveReport ? postFx_.report.value("id", std::string()) : std::string();

    // ------------------------------------------------------------------------------------------------ controls
    {
        std::vector<std::string> cameras;
        w.each<Camera>([&](Entity e, Camera&) { cameras.push_back(w.id_of(e)); });
        ImGui::SetNextItemWidth(170);
        const std::string label = postFx_.camera.empty()
                                      ? "Main camera" + (cameraId.empty() ? std::string() : " (" + cameraId + ")")
                                      : postFx_.camera;
        if (ImGui::BeginCombo("Camera", label.c_str())) {
            if (ImGui::Selectable("Main camera", postFx_.camera.empty())) postFx_.camera.clear();
            for (const std::string& c : cameras)
                if (ImGui::Selectable(c.c_str(), postFx_.camera == c)) postFx_.camera = c;
            ImGui::EndCombo();
        }
        at_track("postfx:camera");
        tip("The camera whose stack is shown: the one the game draws first (the active primary camera with the lowest "
            "depth), or "
            "any other Camera of the scene.");
        ImGui::SameLine();
        ImGui::Checkbox("Stack off (A/B)", &postFx_.compare);
        at_track("postfx:ab");
        tip("Draws the game without any post-processing (no PostProcess component) "
            "to compare "
            "it with the stack on. It changes no data and is not saved; it ends when this panel is closed, collapsed "
            "or hidden behind another tab. "
            "While it is on, every capture of the game (game.screenshot, render.inspect, the captures an AI asks for) "
            "shows the picture without the stack too.");
        if (renderer) {
            renderer->set_post_bypass(postFx_.compare);
            postFx_.bypassSet = postFx_.compare;
        }

        // The edit target: the camera's own PostProcess, or a volume (an entity with a PostProcess and no Camera).
        std::vector<std::string> volumes;
        w.each<PostProcess>([&](Entity e, PostProcess&) {
            if (!std::as_const(w).get<Camera>(e)) volumes.push_back(w.id_of(e));
        });
        if (!postFx_.target.empty() && std::find(volumes.begin(), volumes.end(), postFx_.target) == volumes.end())
            postFx_.target.clear();  // the volume was deleted or lost its PostProcess
        ImGui::SetNextItemWidth(170);
        const std::string tlabel = postFx_.target.empty() ? "The camera's own" : "Volume " + postFx_.target;
        if (ImGui::BeginCombo("Edit", tlabel.c_str())) {
            if (ImGui::Selectable("The camera's own", postFx_.target.empty())) postFx_.target.clear();
            for (const std::string& v : volumes)
                if (ImGui::Selectable(("Volume " + v).c_str(), postFx_.target == v)) postFx_.target = v;
            ImGui::EndCombo();
        }
        at_track("postfx:target");
        tip("Where the switches, fields and presets below write: the PostProcess of the camera (added when it has "
            "none), or one "
            "of the volumes of the scene (an entity with a PostProcess and no Camera: create one with "
            "postprocess.set).");
    }

    // ------------------------------------------------------------------------------------------------ presets
    ImGui::TextDisabled("Looks");
    ImGui::SameLine();
    ImGui::Checkbox("Keep other effects", &postFx_.keepOthers);
    at_track("postfx:keep");
    tip("Off: a look replaces every effect of the edit target with exactly its own. On: it only sets the effects it "
        "names.");
    for (const PostPreset& p : postprocess_presets()) {
        if (ImGui::SmallButton(p.name.c_str())) postfx_preset(p.name);
        at_track("postfx:preset:" + p.name);
        tip(p.doc);
        ImGui::SameLine();
    }
    ImGui::NewLine();
    if (!postFx_.error.empty()) ImGui::TextColored(kRed, "%s", postFx_.error.c_str());
    if (!postFx_.note.empty()) {
        ImGui::PushTextWrapPos(0.0f);
        ImGui::TextColored(kOrange, "%s", postFx_.note.c_str());
        ImGui::PopTextWrapPos();
    }
    ImGui::Separator();
    if (!haveReport) {
        ImGui::TextDisabled("The stack could not be read.");
        ImGui::End();
        return;
    }

    // ------------------------------------------------------------------------------------------------ layers
    const Json& resolved = postFx_.report["resolved"];
    const std::string backend =
        postFx_.support.is_object() ? postFx_.support.value("backendLabel", std::string()) : std::string();
    ImGui::Text("%d effect%s run%s", resolved.value("count", 0), resolved.value("count", 0) == 1 ? "" : "s",
                resolved.value("count", 0) == 1 ? "s" : "");
    if (!backend.empty()) {
        ImGui::SameLine();
        ImGui::TextDisabled("on %s", backend.c_str());
    }
    if (resolved.contains("layers") && resolved["layers"].is_array()) {
        for (const Json& l : resolved["layers"]) {
            const std::string from = l.value("from", std::string());
            ImGui::TextColored(from == "own" ? kGreen : kProjectBlue, "%s", from.c_str());
            ImGui::SameLine();
            ImGui::TextDisabled("strength %.2f (weight %.2f)", l.value("strength", 0.0), l.value("weight", 0.0));
            if (l.contains("priority")) {
                ImGui::SameLine();
                ImGui::TextDisabled("priority %d", l.value("priority", 0));
            }
        }
    }
    if (resolved.value("count", 0) == 0 && (!resolved.contains("layers") || resolved["layers"].empty()))
        ImGui::TextDisabled("No PostProcess reaches this camera: pick a look or switch an effect on.");

    // ------------------------------------------------------------------------------------------------ effects
    const std::string targetId = postfx_target_id();
    const Entity targetEntity = targetId.empty() ? kNullEntity : w.find(targetId);
    const bool targetHas = !targetEntity.is_null() && std::as_const(w).get<PostProcess>(targetEntity) != nullptr;
    const Json ownJson = targetHas ? component_to_json(w, targetEntity, *type, true, false) : Json::object();
    DefaultObject defaults(*type);
    auto own_value = [&](const FieldInfo& f) {
        if (ownJson.contains(f.name)) return ownJson[f.name];
        return field_to_json(f, defaults.get());
    };

    ImGui::BeginChild("##postfxeffects", ImVec2(0, 0), ImGuiChildFlags_None);
    for (int e = 0; e < kPostEffectCount; ++e) {
        const std::string effect(kPostEffectOrder[std::size_t(e)]);
        const std::string enabledName = effect + "Enabled";
        const FieldInfo* enabledField = type->field(enabledName);
        if (!enabledField) continue;
        const Json* entry = effect_entry(postFx_.report, effect);
        const bool running = entry && entry->value("enabled", false);
        const bool ownOn = own_value(*enabledField).is_boolean() && own_value(*enabledField).get<bool>();
        const EffectSupport support = support_of(postFx_.support, effect);
        const bool blocked = support.known && !support.supported;  // unsupported on this GPU or backend
        ImGui::PushID(effect.c_str());

        // The switch writes <effect>Enabled of the edit target. An effect this renderer does not draw (unsupported on this
        // GPU or backend) cannot be switched on, but one that a look switched on can be switched off.
        ImGui::BeginDisabled(blocked && !ownOn);
        bool on = ownOn;
        if (ImGui::Checkbox("##on", &on)) postfx_edit(Json::object({{enabledName, on}}));
        ImGui::EndDisabled();
        at_track("postfx:on:" + effect, !(blocked && !ownOn));
        if (blocked && !ownOn)
            tip_always(effect + " is not drawn here: " + support.status +
                       "\nIts fields are stored and saved with the scene.");
        else
            tip_always("Switch " + effect + " on or off in the edit target (" +
                       (postFx_.target.empty() ? "the camera's own PostProcess" : "volume " + postFx_.target) + ").");
        ImGui::SameLine();
        ImGui::SetNextItemOpen(postFx_.open.count(effect) > 0, ImGuiCond_Always);
        if (blocked && !ownOn) ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
        const bool open = ImGui::TreeNodeEx(
            "##node", ImGuiTreeNodeFlags_SpanAvailWidth | ImGuiTreeNodeFlags_AllowOverlap, "%s", effect.c_str());
        if (blocked && !ownOn) ImGui::PopStyleColor();
        at_track("postfx:open:" + effect);
        if (open)
            postFx_.open.insert(effect);
        else
            postFx_.open.erase(effect);
        ImGui::SameLine();
        if (running)
            ImGui::TextColored(kGreen, "running");
        else if (ownOn)
            ImGui::TextColored(kOrange, "on here, not running");
        else
            ImGui::TextDisabled("off");
        if (running)
            tip_always("The stack the camera draws runs this effect.");
        else if (ownOn)
            tip_always("The edit target switches it on, but the camera's stack does not run it: the target is a volume "
                       "the camera is not inside, or a layer too weak to switch it.");
        if (support.known && !support.supported) {
            ImGui::SameLine();
            ImGui::TextColored(kRed, "unsupported");
            tip_always(support.status);
        }

        if (open) {
            ImGui::BeginDisabled(blocked && !ownOn);
            if (ImGui::BeginTable("##fields", 2, ImGuiTableFlags_SizingStretchProp | ImGuiTableFlags_NoSavedSettings)) {
                ImGui::TableSetupColumn("name", ImGuiTableColumnFlags_WidthStretch, 0.45f);
                ImGui::TableSetupColumn("value", ImGuiTableColumnFlags_WidthStretch, 0.55f);
                const Json* fields = entry && entry->contains("fields") ? &(*entry)["fields"] : nullptr;
                for (const FieldInfo& f : type->fields) {
                    if (post_field_effect(f.name) != e || f.name == enabledName) continue;
                    // What the camera draws when the effect runs, else what the edit target holds (it is edited either way).
                    Json shown = own_value(f);
                    std::string from = running ? "default" : "not running";
                    if (fields && fields->contains(f.name)) {
                        const Json& cell = (*fields)[f.name];
                        if (cell.contains("value")) shown = cell["value"];
                        from = cell.value("from", std::string("default"));
                    }
                    ImGui::TableNextRow();
                    ImGui::TableSetColumnIndex(0);
                    ImGui::AlignTextToFramePadding();
                    ImGui::TextUnformatted(f.name.c_str());
                    at_track("postfx:label:" + f.name);
                    tip(f.doc);
                    ImGui::SameLine();
                    const bool mine = from == "own";
                    ImGui::TextColored(mine ? kGreen
                                       : from.rfind("volume:", 0) == 0
                                           ? kProjectBlue
                                           : ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled),
                                       "%s", from.c_str());
                    ImGui::TableSetColumnIndex(1);
                    Json out;
                    const bool changed = draw_field_widget("postfx." + f.name, f, shown, false, out);
                    if (changed) postfx_edit(Json::object({{f.name, out}}));
                }
                ImGui::EndTable();
            }
            ImGui::EndDisabled();
            ImGui::TreePop();
        }
        ImGui::PopID();
    }
    ImGui::Separator();
    draw_postfx_custom(targetHas && ownJson.contains("customPasses") ? ownJson["customPasses"] : Json::array(),
                       resolved);
    ImGui::EndChild();
    ImGui::End();
}

void Editor::draw_postfx_custom(const Json& list, const Json& resolved) {
    const std::size_t count = list.is_array() ? list.size() : 0;
    ImGui::SetNextItemOpen(postFx_.open.count("custom") > 0, ImGuiCond_Always);
    const bool section =
        ImGui::TreeNodeEx("##customnode", ImGuiTreeNodeFlags_SpanAvailWidth, "Custom passes (%zu)", count);
    at_track("postfx:custom");
    tip("Your own full-screen passes: kind \"post\" materials drawn between the built-in effects "
        "(PostProcess.customPasses; docs/shaders/SHADERS_POST.md). Every change below is one "
        "postprocess.set call and one undo step.");
    if (section)
        postFx_.open.insert("custom");
    else
        postFx_.open.erase("custom");
    if (!section) return;

    // Passes the camera draws that this target does not hold (a volume's, or the camera's own while a volume is the
    // target).
    int others = 0;
    if (resolved.contains("customPasses") && resolved["customPasses"].is_array())
        for (const Json& c : resolved["customPasses"])
            if (c.value("from", std::string()) != "own") ++others;
    if (others > 0)
        ImGui::TextDisabled("%d more pass%s come from other layers (see the resolved stack).", others,
                            others == 1 ? "" : "es");
    if (resolved.contains("customPassProblems") && resolved["customPassProblems"].is_array())
        for (const Json& p : resolved["customPassProblems"]) {
            ImGui::PushTextWrapPos(0.0f);
            ImGui::TextColored(kRed, "%s", p.is_string() ? p.get<std::string>().c_str() : "");
            ImGui::PopTextWrapPos();
        }

    // The asset report and the skipped passes are asked at most twice a second, like the Inspector's material rows.
    if (assetReportAt_ + 0.5 < time_ || assetReport_.is_null()) {
        assetReportAt_ = time_;
        assetReport_ = engine_ && engine_->renderer() ? engine_->renderer()->asset_report() : Json::object();
    }
    const std::vector<std::string> skipped = count > 0 && engine_ && engine_->renderer()
                                                 ? engine_->renderer()->stats(false).materialFallbacks
                                                 : std::vector<std::string>();
    const std::vector<std::string> positions = render::custom_post_position_names();

    // Add: pick one of the project's materials.
    {
        ImGui::BeginDisabled(count >= std::size_t(render::kMaxCustomPostPasses));
        ImGui::SetNextItemWidth(260);
        if (ImGui::BeginCombo("##addpass", "Add a post material...")) {
            auto& cache = assetFiles_["material"];
            if (cache.first + 2.0 < time_ || cache.second.empty()) {
                cache.first = time_;
                cache.second = list_asset_files(projectDir_, "material");
            }
            for (const std::string& file : cache.second)
                if (ImGui::Selectable(file.c_str()))
                    postfx_edit(Json::object({{"customPasses", custom_pass_add(list, file)}}), true);
            if (cache.second.empty())
                ImGui::TextDisabled("No materials in the project (docs/shaders/SHADERS_POST.md).");
            ImGui::EndCombo();
        }
        ImGui::EndDisabled();
        at_track("postfx:custom:add", count < std::size_t(render::kMaxCustomPostPasses));
        tip_always(count >= std::size_t(render::kMaxCustomPostPasses)
                       ? "A stack holds at most 8 custom passes: remove one first."
                       : "Adds a pass at the end of the list, at the default position (before the tonemap). The "
                         "material must have \"kind\": \"post\" (docs/shaders/SHADERS_POST.md).");
    }
    if (count == 0) ImGui::TextDisabled("No custom passes on this edit target.");

    for (std::size_t i = 0; i < count; ++i) {
        const Json& entry = list[i];
        const std::string idx = std::to_string(i);
        const std::string material = entry.is_object() && entry.contains("material") && entry["material"].is_string()
                                         ? entry["material"].get<std::string>()
                                         : std::string();
        const bool enabled = !entry.is_object() || entry.value("enabled", true);
        const std::string position = entry.is_object() && entry.contains("position") && entry["position"].is_string()
                                         ? entry["position"].get<std::string>()
                                         : std::string(render::kCustomPostDefaultPosition);
        const std::string buildError = material.empty() ? std::string() : material_build_error(assetReport_, material);
        const bool isSkipped =
            enabled && !material.empty() && std::find(skipped.begin(), skipped.end(), material) != skipped.end();
        ImGui::PushID(int(i));

        bool on = enabled;
        if (ImGui::Checkbox("##on", &on))
            postfx_edit(Json::object({{"customPasses", custom_pass_set(list, i, "enabled", on)}}), true);
        at_track("postfx:custom:on:" + idx);
        tip_always("Draws this pass (off: it stays in the list and draws nothing).");
        ImGui::SameLine();
        const std::string key = "custom:" + idx;
        ImGui::SetNextItemOpen(postFx_.open.count(key) > 0, ImGuiCond_Always);
        const bool open =
            ImGui::TreeNodeEx("##node", ImGuiTreeNodeFlags_AllowOverlap, "%s", custom_pass_label(entry).c_str());
        at_track("postfx:custom:open:" + idx);
        if (open)
            postFx_.open.insert(key);
        else
            postFx_.open.erase(key);
        ImGui::SameLine();
        if (!enabled)
            ImGui::TextDisabled("off");
        else if (isSkipped || !buildError.empty())
            ImGui::TextColored(kRed, "skipped");
        else
            ImGui::TextColored(kGreen, "%s", position.c_str());
        if (isSkipped || !buildError.empty())
            tip_always(buildError.empty()
                           ? "The renderer skipped this pass: the material is missing, is not a \"post\" "
                             "material or cannot be drawn here. The log says why."
                           : "Build error: " + buildError);
        ImGui::SameLine();
        ImGui::BeginDisabled(i == 0);
        if (ImGui::SmallButton("Up"))
            postfx_edit(Json::object({{"customPasses", custom_pass_move(list, i, -1)}}), true);
        ImGui::EndDisabled();
        at_track("postfx:custom:up:" + idx, i > 0);
        tip_always(
            "Moves the pass earlier: passes at the same position run in list order, each reading the picture the one "
            "before wrote.");
        ImGui::SameLine();
        ImGui::BeginDisabled(i + 1 >= count);
        if (ImGui::SmallButton("Down"))
            postfx_edit(Json::object({{"customPasses", custom_pass_move(list, i, 1)}}), true);
        ImGui::EndDisabled();
        at_track("postfx:custom:down:" + idx, i + 1 < count);
        tip_always("Moves the pass later.");
        ImGui::SameLine();
        if (ImGui::SmallButton("Remove"))
            postfx_edit(Json::object({{"customPasses", custom_pass_remove(list, i)}}), true);
        at_track("postfx:custom:remove:" + idx);
        tip_always("Removes the pass from the list (Edit > Undo brings it back). The material file is not touched.");

        if (open) {
            ImGui::Indent();
            // Position.
            ImGui::SetNextItemWidth(200);
            if (ImGui::BeginCombo("Position", position.c_str())) {
                for (const std::string& p : positions)
                    if (ImGui::Selectable(p.c_str(), p == position))
                        postfx_edit(Json::object({{"customPasses", custom_pass_set(list, i, "position", p)}}), true);
                ImGui::EndCombo();
            }
            at_track("postfx:custom:position:" + idx);
            tip("Where in the frame the pass runs: before or after a built-in effect. Up to \"before:tonemap\" the "
                "pass reads scene-linear colour (the positions before the exposure, the lens effects and the tonemap "
                "are the same place, after the bloom); from \"after:tonemap\" on it reads the display-referred, "
                "sRGB-encoded picture between two screen effects (the colour grading, vignette, sharpen, outline, "
                "posterize, film grain), and the final pass is drawn in two pieces there.");
            // Material.
            ImGui::SetNextItemWidth(260);
            if (ImGui::BeginCombo("Material", material.empty() ? "(none)" : material.c_str())) {
                auto& cache = assetFiles_["material"];
                if (cache.first + 2.0 < time_ || cache.second.empty()) {
                    cache.first = time_;
                    cache.second = list_asset_files(projectDir_, "material");
                }
                for (const std::string& file : cache.second)
                    if (ImGui::Selectable(file.c_str(), file == material))
                        postfx_edit(Json::object({{"customPasses", custom_pass_set(list, i, "material", file)}}), true);
                ImGui::EndCombo();
            }
            at_track("postfx:custom:material:" + idx);
            tip("The kind \"post\" material this pass draws. Changing it drops the params set below.");
            if (!buildError.empty()) ImGui::TextColored(kRed, "Build error: %s", buildError.c_str());

            // Params of the material, typed by material.info; an edit overrides the value in this entry only.
            if (!material.empty()) {
                MaterialInfoEntry& info = materialInfo_[material];
                if (info.checkedAt + 0.5 < time_) {
                    info.checkedAt = time_;
                    const std::int64_t mtime = fs::modified_time(material);
                    if (mtime != info.mtime || !info.error.empty()) {
                        info.mtime = mtime;
                        info.error.clear();
                        info.info = Json();
                        if (!engine_ || !engine_->commands().info("material.info")) {
                            info.error = "This build has no material.info command.";
                        } else {
                            CommandResult r =
                                engine_->commands().call("material.info", Json::object({{"material", material}}));
                            if (r.ok)
                                info.info = r.result;
                            else
                                info.error = command_error_text(r.error);
                        }
                    }
                }
                const Json overrides =
                    entry.is_object() && entry.contains("materialParams") && entry["materialParams"].is_object()
                        ? entry["materialParams"]
                        : Json::object();
                const auto specs = material_params_from_info(info.error.empty() ? info.info : Json::object());
                if (!info.error.empty()) {
                    ImGui::TextColored(kRed, "Cannot read the material's params: %s", info.error.c_str());
                } else if (!specs.ok()) {
                    ImGui::TextColored(kRed, "%s", specs.error().message.c_str());
                } else {
                    if (specs->empty()) ImGui::TextDisabled("This material declares no params.");
                    for (const MaterialParamSpec& p : *specs) {
                        const int n = material_param_arity(p.type);
                        const bool overridden = material_param_overridden(p, overrides);
                        const Json value = material_param_value(p, overrides);
                        ImGui::PushID(p.name.c_str());
                        ImGui::AlignTextToFramePadding();
                        ImGui::TextUnformatted((p.name + (overridden ? " *" : "")).c_str());
                        tip(p.doc + "\n" + p.type +
                            (overridden ? "\nSet on this pass." : "\nUsing the material's default."));
                        ImGui::SameLine();
                        const float resetW = ImGui::CalcTextSize("Reset").x + ImGui::GetStyle().FramePadding.x * 2.0f;
                        ImGui::SetNextItemWidth(-(resetW + ImGui::GetStyle().ItemSpacing.x));
                        float v[4] = {0, 0, 0, 0};
                        for (int k = 0; k < std::max(n, 1); ++k) {
                            const Json& cell = value.is_array()
                                                   ? (std::size_t(k) < value.size() ? value[std::size_t(k)] : Json(0))
                                                   : value;
                            v[k] = cell.is_number() ? cell.get<float>() : 0.0f;
                        }
                        const float lo = p.min ? float(*p.min) : 0.0f, hi = p.max ? float(*p.max) : 0.0f;
                        const float speed = p.min && p.max ? std::max(1e-4f, (hi - lo) / 200.0f)
                                                           : std::max(0.01f, std::fabs(v[0]) * 0.01f);
                        Json out;
                        bool changed = false;
                        auto numbers = [&](int count_) {
                            Json a = Json::array();
                            for (int k = 0; k < count_; ++k) a.push_back(std::round(v[k] * 10000.0f) / 10000.0f);
                            return a;
                        };
                        if (p.type == "float") {
                            changed = ImGui::DragFloat("##v", v, speed, lo, hi, "%.3f", ImGuiSliderFlags_ClampOnInput);
                            if (changed) out = std::round(v[0] * 10000.0f) / 10000.0f;
                        } else if (p.type == "vec2") {
                            changed = ImGui::DragFloat2("##v", v, speed, lo, hi, "%.3f", ImGuiSliderFlags_ClampOnInput);
                            if (changed) out = numbers(2);
                        } else if (p.type == "vec3") {
                            changed = ImGui::DragFloat3("##v", v, speed, lo, hi, "%.3f", ImGuiSliderFlags_ClampOnInput);
                            if (changed) out = numbers(3);
                        } else if (p.type == "vec4") {
                            changed = ImGui::DragFloat4("##v", v, speed, lo, hi, "%.3f", ImGuiSliderFlags_ClampOnInput);
                            if (changed) out = numbers(4);
                        } else if (p.type == "color") {
                            changed =
                                ImGui::ColorEdit4("##v", v, ImGuiColorEditFlags_AlphaBar | ImGuiColorEditFlags_Float);
                            if (changed) out = numbers(4);
                        } else {
                            ImGui::TextDisabled("%s (not editable here)", p.type.c_str());
                        }
                        at_track("postfx:custom:param:" + idx + ":" + p.name);
                        if (changed)
                            postfx_edit(Json::object({{"customPasses", custom_pass_set_param(list, i, p.name, out)}}),
                                        false, int(i));
                        ImGui::SameLine();
                        ImGui::BeginDisabled(!overridden);
                        if (ImGui::SmallButton("Reset"))
                            postfx_edit(
                                Json::object({{"customPasses", custom_pass_set_param(list, i, p.name, Json())}}), true);
                        ImGui::EndDisabled();
                        at_track("postfx:custom:reset:" + idx + ":" + p.name, overridden);
                        tip_always("Back to the material's default (removes the override from this pass).");
                        ImGui::PopID();
                    }
                }
            }
            ImGui::Unindent();
            ImGui::TreePop();
        }
        ImGui::PopID();
    }
    ImGui::TreePop();
}

}  // namespace fa::editor
