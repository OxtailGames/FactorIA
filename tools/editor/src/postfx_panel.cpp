// Post-processing panel (View > Post-processing): the stack a camera draws, in the order its effects run. Every effect shows whether it
// runs, what this renderer draws of it (the render.supports table: unsupported, with the reason), and its fields with the source of
// each value (the camera's own PostProcess, a volume, the deprecated Camera.bloom* fields). Nothing here edits the world directly: an
// edit is a postprocess.set call and a preset button a postprocess.apply_preset call, both through Editor::edit_command (the path of
// the Console and the AI, one undo step each), on the camera's own PostProcess or on the volume chosen as the edit target. The A/B
// checkbox turns the stack off in the renderer (Renderer::set_post_bypass) and changes no data. The stack shown is
// `postprocess.get {resolved: true}`: the same one the renderer draws, computed on the CPU (render::post_stack_report called directly: a
// command call every frame would reach the console and the MCP history through the command interceptor).
#include <algorithm>
#include <utility>

#include "editor_internal.h"
#include "fa/core/reflect.h"
#include "fa/render/post_report.h"
#include "fa/render/renderer.h"
#include "fa/runtime/postprocess_presets.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/postprocess.h"
#include "imgui_internal.h"

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

bool Editor::postfx_edit(const Json& fields) {
    const std::string id = postfx_target_id();
    postFx_.error.clear();
    if (id.empty()) {
        postFx_.error = "There is no camera to edit: add a Camera to the scene, or choose a volume as the edit target.";
        return false;
    }
    std::string key = "postfx:" + id + ":";
    for (auto it = fields.begin(); it != fields.end(); ++it) key += it.key() + ",";
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
            const Renderer* r =engine_->renderer();
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
        tip("Draws the game without any post-processing (no PostProcess component and no Camera.bloom or colorFilter) "
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
            ImGui::TextColored(from == "own" || from == "legacy" ? kGreen : kProjectBlue, "%s", from.c_str());
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
                    const bool mine = from == "own" || from == "legacy";
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
    ImGui::EndChild();
    ImGui::End();
}

}  // namespace fa::editor
