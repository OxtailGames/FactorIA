// The commands over the PostProcess component (M71): postprocess.get reads its fields, or the stack a camera really draws with where
// each value comes from (resolved); postprocess.set and postprocess.apply_preset write it (thin wrappers of scene.set_component that
// know the component, so a script or an AI does not have to spell it, and the editor undoes them); postprocess.presets lists the named
// looks (data: engine/runtime/data/postprocess_presets.json, fa/runtime/postprocess_presets.h).
#include <algorithm>
#include <format>

#include "engine_impl.h"
#include "fa/core/strings.h"
#include "fa/render/post_custom.h"
#include "fa/render/post_report.h"
#include "fa/runtime/postprocess_presets.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/postprocess.h"
#include "fa/scene/serialize.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

void check_args_known(const Json& a, std::initializer_list<const char*> known, const char* command) {
    if (!a.is_object()) return;
    std::vector<std::string> names;
    for (const char* k : known) names.push_back(k);
    for (auto it = a.begin(); it != a.end(); ++it)
        if (std::find(names.begin(), names.end(), it.key()) == names.end())
            throw CommandError("invalid_argument",
                               std::string(command) + ": unknown argument '" + it.key() + "'. " +
                                   did_you_mean(it.key(), names),
                               "The arguments are: " + join(names, ", ") + ".");
}

const TypeInfo& post_type() {
    ensure_builtin_components();
    const TypeInfo* t = TypeRegistry::global().of<PostProcess>();
    FA_ASSERT(t, "PostProcess is not registered");
    return *t;
}

// The names of the effects `p` switches on, in the order they run.
Json running_effects(const PostProcess& p) {
    Json out = Json::array();
    for (int e = 0; e < kPostEffectCount; ++e) {
        const FieldInfo* f = post_type().field(std::string(kPostEffectOrder[std::size_t(e)]) + "Enabled");
        if (f && *static_cast<const bool*>(f->ptr(&p))) out.push_back(std::string(kPostEffectOrder[std::size_t(e)]));
    }
    return out;
}

// The names of the effects a preset's `fields` switch on, in canonical order.
std::vector<std::string> preset_effects(const Json& fields) {
    std::vector<std::string> out;
    for (const std::string_view name : kPostEffectOrder) {
        const std::string key = std::string(name) + "Enabled";
        if (fields.contains(key) && fields[key].is_boolean() && fields[key].get<bool>()) out.emplace_back(name);
    }
    return out;
}

// The camera whose stack is asked for: the Camera entity `id` names, or without `id` the project's main camera (the active primary
// one that draws to the screen with the lowest depth, as the renderer chooses); kNullEntity when the world has no camera (the default camera, which only global volumes reach).
Entity camera_for_stack(Engine::Impl& I, const Json& a) {
    if (a.contains("id")) {
        const Entity e = need_entity(I.world, a);
        if (!I.world.get<Camera>(e))
            throw CommandError(
                "invalid_argument",
                std::format("postprocess.get: resolved needs a camera and '{}' has no Camera.", I.world.id_of(e)),
                "A camera draws a stack; a volume only feeds it. Name a Camera entity, leave `id` out for the main "
                "camera, or read the volume's own fields with resolved false.");
        return e;
    }
    // The renderer's own choice (rendering_cameras: primary, no renderTarget, active, not being destroyed, by depth), so a minimap
    // camera that draws into a texture is never taken for the main one.
    const std::vector<Entity> cams = rendering_cameras(I.world);
    return cams.empty() ? kNullEntity : cams.front();
}

}  // namespace

void register_postprocess_commands(Engine&, Engine::Impl& I) {
    I.commands.add(
        {"postprocess.get",
         "Read the PostProcess component of an entity, or (resolved) the stack a camera really draws and where each "
         "value comes "
         "from.",
         "The PostProcess component (a camera's own stack, or a volume: an entity with a shape and a size) holds one "
         "block of "
         "fields per post effect, named `<effect>Enabled` and `<effect>Parameter`: bloomEnabled, bloomIntensity, "
         "tonemapMode, "
         "vignetteIntensity... and the meta fields enabled, shape (global, box, circle, sphere), size, blendDistance, "
         "priority "
         "and weight. Result: {id, effects, order, value}; `effects` lists the effects this component switches on, in "
         "the order "
         "they run; `order` is the order of every effect (the same as render.supports lists them); `value` has every "
         "field "
         "(or only the names in `fields`). With resolved true the answer is the stack a CAMERA draws: {id, resolved: "
         "{camera, "
         "position, perspective, layers, effects, count}}. Example: postprocess.get {\"id\":\"camera\",\"fields\":"
         "[\"bloomEnabled\",\"bloomIntensity\"]}; postprocess.get "
         "{\"id\":\"camera\",\"resolved\":true}" FA_COMMAND_DETAILS
         "The resolved stack is the one the renderer draws, computed on the CPU (it works with graphics=false): the "
         "camera's own "
         "PostProcess (or, without one, the deprecated Camera.bloom* and colorFilter fields that stand in for it), "
         "then every "
         "volume the camera is inside (or within blendDistance of) by ascending priority, each blended by its weight "
         "and how deep "
         "the camera is. `layers` lists them: {index, from, kind (own, legacy, volume), entity, priority (volumes), "
         "weight, "
         "influence, strength}; `strength` is weight times influence. `effects` has every effect in the canonical "
         "order: {name, "
         "enabled, layers (the indexes that write it), fields} where `fields` (only for an effect that runs) maps each "
         "parameter "
         "to {value, from, strength}: `from` is \"own\", \"legacy\", \"volume:<entity id>\" or \"default\" (no layer "
         "wrote it). "
         "`count` is how many effects run. Without `id` the main camera is used (the camera that draws first: active, "
         "primary, not "
         "drawing into a `renderTarget`, lowest "
         "depth); a scene with no camera answers for the default camera, which only global volumes reach. Errors: "
         "`not_found` "
         "for an unknown entity, `invalid_argument` for an entity without a PostProcess (add one with "
         "postprocess.set), a "
         "resolved id that is not a camera, `fields` together with resolved, or a field name that does not exist (with "
         "a "
         "did-you-mean). The fields are stored and saved with the scene; an effect is drawn only when the renderer "
         "supports it "
         "(render.supports names which).",
         parse_schema(R"({"type":"object","properties":{
               "id":{"type":"string","description":"Entity id (or name) that has the PostProcess component; with resolved true, the Camera entity (default: the main camera)."},
               "fields":{"type":"array","items":{"type":"string"},"description":"Only these fields (names as in api.components, e.g. bloomIntensity). Default: every field. Not with resolved."},
               "resolved":{"type":"boolean","default":false,"description":"true = the stack the camera draws (its own PostProcess or legacy fields, plus the volumes it is inside) with the source of every value."}}})"),
         true, "scene"},
        [&I](const Json& a) {
            check_args_known(a, {"id", "fields", "resolved"}, "postprocess.get");
            if (a.contains("resolved") && !a["resolved"].is_boolean())
                throw CommandError(
                    "invalid_argument", "resolved: " + describe_json_value(a["resolved"]) + " is not a boolean.",
                    "Pass true for the stack a camera draws, or leave it out for the component's own fields.");
            if (a.value("resolved", false)) {
                if (a.contains("fields"))
                    throw CommandError(
                        "invalid_argument", "postprocess.get: `fields` cannot be combined with resolved.",
                        "`fields` picks fields of one component; the resolved stack has its own layout. Use one or "
                        "the other.");
                const Entity cam = camera_for_stack(I, a);
                return Json::object({{"id", cam.is_null() ? std::string() : I.world.id_of(cam)},
                                     {"resolved", render::post_stack_report(I.world, cam)}});
            }
            const Entity e = need_entity(I.world, a);
            const PostProcess* p = I.world.get<PostProcess>(e);
            if (!p)
                throw CommandError("invalid_argument",
                                   std::format("postprocess.get: '{}' has no PostProcess.", I.world.id_of(e)),
                                   "Add one: postprocess.set {id, fields: {bloomEnabled: true}}.");
            Json value = component_to_json(I.world, e, post_type(), true, true);
            if (a.contains("fields")) {
                if (!a["fields"].is_array())
                    throw CommandError("invalid_argument",
                                       "fields: " + describe_json_value(a["fields"]) + " is not an array.",
                                       "Pass a list of field names, e.g. [\"bloomEnabled\", \"bloomIntensity\"].");
                std::vector<std::string> all;
                for (const FieldInfo& f : post_type().fields) all.push_back(f.name);
                Json picked = Json::object();
                for (const Json& n : a["fields"]) {
                    const std::string name = n.is_string() ? n.get<std::string>() : std::string();
                    if (std::find(all.begin(), all.end(), name) == all.end())
                        throw CommandError("invalid_argument",
                                           "fields: PostProcess has no field " + describe_json_value(n) + ". " +
                                               did_you_mean(name, all),
                                           "Use api.components to see the fields of PostProcess.");
                    if (value.contains(name)) picked[name] = value[name];
                }
                value = std::move(picked);
            }
            Json order = Json::array();
            for (const std::string_view n : kPostEffectOrder) order.push_back(std::string(n));
            return Json::object(
                {{"id", I.world.id_of(e)}, {"effects", running_effects(*p)}, {"order", order}, {"value", value}});
        });

    I.commands.add(
        {"postprocess.set", "Set fields of the PostProcess component of an entity (added when missing).",
         "Like scene.set_component with component \"PostProcess\": `fields` is a partial object, the fields you do not "
         "name keep "
         "their value, a bad field or value changes nothing and the error names the field, the allowed values and the "
         "range. "
         "Turn an effect on with `<effect>Enabled` and tune it with its parameters in one call. Example: "
         "postprocess.set "
         "{\"id\":\"camera\",\"fields\":{\"tonemapEnabled\":true,\"tonemapMode\":\"aces\",\"bloomEnabled\":true,"
         "\"bloomIntensity\":0.8}}. A volume: an entity without a Camera whose PostProcess has shape box, circle or "
         "sphere "
         "(size, blendDistance, priority, weight): postprocess.set {\"id\":\"cave\",\"fields\":{\"shape\":\"box\","
         "\"size\":[10,6,10],\"blendDistance\":3,\"vignetteEnabled\":true}}" FA_COMMAND_DETAILS
         "Result: {id, effects, value} as postprocess.get. `merge` reads `fields` as an RFC 7386 merge-patch like "
         "scene.set_component (a null resets a field to its default). The editor undoes the call in one step. The "
         "picture changes "
         "when the renderer draws the effect (render.supports says which it does); the fields are stored either way. "
         "`customPasses` is the list of your own post materials ({material, materialParams, enabled, position}, see "
         "docs/SHADERS.md \"Post-process materials\"): the whole array is replaced, so send the list in the order you "
         "want to add, reorder or remove a pass; every entry is checked first (a bad one changes nothing and the "
         "error carries its JSON pointer) and the result has `customPasses`, the number of entries.",
         parse_schema(R"({"type":"object","required":["id","fields"],"properties":{
               "id":{"type":"string","description":"Entity id (or name). The PostProcess is added when it has none."},
               "fields":{"type":"object","description":"Field name -> value, e.g. {\"bloomEnabled\": true, \"bloomIntensity\": 0.8}."},
               "merge":{"type":"boolean","default":false,"description":"true = read `fields` as an RFC 7386 merge-patch: a null resets the field to its default."}}})"),
         false, "scene"},
        [&I](const Json& a) {
            check_args_known(a, {"id", "fields", "merge"}, "postprocess.set");
            if (!a.contains("fields") || !a["fields"].is_object())
                throw CommandError(
                    "invalid_argument", "postprocess.set: missing the object 'fields'.",
                    "Pass {id, fields: {bloomEnabled: true}}; api.components lists the fields of PostProcess.");
            // The custom passes are checked before anything is written, so a bad entry changes nothing and the error points at it.
            if (a["fields"].contains("customPasses") && !a["fields"]["customPasses"].is_null()) {
                auto passes = render::parse_custom_post_passes(a["fields"]["customPasses"], "/fields/customPasses");
                if (!passes.ok())
                    throw CommandError("invalid_argument", passes.error().message,
                                       passes.error().hint.empty() ? "docs/SHADERS.md, \"Post-process materials\"."
                                                                   : passes.error().hint);
            }
            Json args = a;
            args["component"] = "PostProcess";
            Json r = set_component(I.world, args);
            const Entity e = need_entity(I.world, a);
            const PostProcess* p = I.world.get<PostProcess>(e);
            r.erase("component");
            r["effects"] = p ? running_effects(*p) : Json::array();
            r["customPasses"] = p && p->customPasses.is_array() ? int(p->customPasses.size()) : 0;
            return r;
        });

    I.commands.add(
        {"postprocess.presets", "List the named post-processing looks that postprocess.apply_preset can apply.",
         "A preset is a named set of PostProcess fields (a look). The list is data "
         "(engine/runtime/data/postprocess_presets.json): "
         "neutral (everything off), cinematic, retro, noir, dreamy, vivid and horror, each using only fields that "
         "exist. Result: "
         "{presets: [{name, doc, effects, fields}]}; `effects` are the effects the preset switches on, in the order "
         "they run. "
         "Example: postprocess.presets {}" FA_COMMAND_DETAILS
         "A preset may switch on an effect the renderer does not draw yet: apply_preset still stores its fields and "
         "says which "
         "effects are not drawn (render.supports lists the effects a renderer draws).",
         parse_schema(R"({"type":"object","properties":{}})"), true, "scene"},
        [](const Json& a) {
            check_args_known(a, {}, "postprocess.presets");
            Json list = Json::array();
            for (const PostPreset& p : postprocess_presets()) {
                Json effects = Json::array();
                for (const std::string& e : preset_effects(p.fields)) effects.push_back(e);
                list.push_back(Json::object(
                    {{"name", p.name}, {"doc", p.doc}, {"effects", std::move(effects)}, {"fields", p.fields}}));
            }
            return Json::object({{"presets", std::move(list)}});
        });

    I.commands.add(
        {"postprocess.apply_preset", "Apply a named look (cinematic, retro, noir...) to the PostProcess of an entity.",
         "Sets the fields of the preset on the PostProcess of `id` (added when missing). By default the look REPLACES "
         "the effects: "
         "every effect field the component has goes back to its default first, so the result is exactly the preset "
         "(the meta "
         "fields of a volume - enabled, shape, size, blendDistance, priority, weight - and the entity fields, such as "
         "a "
         "depth-of-field focus target, are never touched). With `keep` "
         "true only "
         "the preset's own fields are written and every other effect stays as it was. `neutral` switches every effect "
         "off. "
         "Result: {id, preset, effects, value, drawnChecked, notDrawn, note}. Example: postprocess.apply_preset "
         "{\"id\":\"camera\",\"preset\":\"cinematic\"}" FA_COMMAND_DETAILS
         "`effects` are the effects now on. A preset that names an effect the renderer does not draw yet "
         "(render.supports says "
         "\"planned\" or why it is unsupported here) is still applied: its fields are stored and `notDrawn` lists "
         "{effect, status} for each such effect, with a `note` saying it will show once drawn; `drawnChecked` is false "
         "(and "
         "`notDrawn` empty) when there is no renderer to ask (graphics=false). The call is one edit: the editor undoes "
         "it in one "
         "step. Errors: `not_found` for an unknown entity, `invalid_argument` for an unknown preset (with a "
         "did-you-mean).",
         parse_schema(R"({"type":"object","required":["id","preset"],"properties":{
               "id":{"type":"string","description":"Entity id (or name): a camera, or a volume. The PostProcess is added when it has none."},
               "preset":{"type":"string","description":"Preset name, as listed by postprocess.presets (neutral, cinematic, retro, noir, dreamy, vivid, horror)."},
               "keep":{"type":"boolean","default":false,"description":"true = write only the preset's fields and keep every other effect as it is; false = reset every effect to its default first."}}})"),
         false, "scene"},
        [&I](const Json& a) {
            check_args_known(a, {"id", "preset", "keep"}, "postprocess.apply_preset");
            if (!a.contains("preset") || !a["preset"].is_string())
                throw CommandError("invalid_argument", "postprocess.apply_preset: missing the string 'preset'.",
                                   "Pass {id, preset: \"cinematic\"}; postprocess.presets lists the names.");
            if (a.contains("keep") && !a["keep"].is_boolean())
                throw CommandError(
                    "invalid_argument", "keep: " + describe_json_value(a["keep"]) + " is not a boolean.",
                    "Pass true to keep the effects the preset does not name, or leave it out to replace them.");
            const std::string name = a["preset"].get<std::string>();
            const PostPreset* preset = find_postprocess_preset(name);
            if (!preset) {
                std::vector<std::string> names;
                for (const PostPreset& p : postprocess_presets()) names.push_back(p.name);
                throw CommandError("invalid_argument",
                                   "preset: unknown preset '" + name + "'. " + did_you_mean(name, names),
                                   "The presets are: " + join(names, ", ") + " (postprocess.presets describes them).");
            }
            const Entity e = need_entity(I.world, a);
            auto r =
                patch_component(I.world, e, post_type(), postprocess_preset_fields(*preset, a.value("keep", false)));
            if (!r.ok())
                throw CommandError("invalid_argument", r.error().message,
                                   r.error().hint.empty() ? "Use api.components to see the fields of PostProcess."
                                                          : r.error().hint);
            const PostProcess* p = I.world.get<PostProcess>(e);

            Json notDrawn = Json::array();
            const bool checked = I.renderer && I.renderer->initialized();
            if (checked) {
                const Json report = I.renderer->supports_report();
                for (const std::string& effect : preset_effects(preset->fields))
                    for (const Json& f : report["features"])
                        if (f["name"] == effect && !f["supported"].get<bool>())
                            notDrawn.push_back(Json::object({{"effect", effect}, {"status", f["status"]}}));
            }
            std::string note;
            if (!checked)
                note = "There is no renderer here (graphics=false), so which effects are drawn is not known; "
                       "render.supports "
                       "answers it on a run with graphics.";
            else if (!notDrawn.empty())
                note = std::format(
                    "{} of the preset's effects are not drawn by this renderer: their fields are stored and show "
                    "once the renderer draws them (see notDrawn).",
                    notDrawn.size());
            return Json::object({{"id", I.world.id_of(e)},
                                 {"preset", name},
                                 {"effects", p ? running_effects(*p) : Json::array()},
                                 {"value", component_to_json(I.world, e, post_type(), true, true)},
                                 {"drawnChecked", checked},
                                 {"notDrawn", std::move(notDrawn)},
                                 {"note", note}});
        });

    declare_command_capabilities(I.commands, {
                                                 {"postprocess.get", capability_sets::reads()},
                                                 {"postprocess.set", capability_sets::changes_state()},
                                                 {"postprocess.presets", capability_sets::reads()},
                                                 {"postprocess.apply_preset", capability_sets::changes_state()},
                                             });
}

}  // namespace fa
