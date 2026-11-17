// The commands over the PostProcess component (M71): postprocess.get and postprocess.set read and write its fields (thin wrappers of
// scene.set_component that know the component, so a script or an AI does not have to spell it), postprocess.presets lists the named
// looks (none yet: the presets arrive with the effects that make them worth having).
#include <algorithm>
#include <format>

#include "engine_impl.h"
#include "fa/core/strings.h"
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

}  // namespace

void register_postprocess_commands(Engine&, Engine::Impl& I) {
    I.commands.add(
        {"postprocess.get", "Read the PostProcess component of an entity: its fields and the effects it switches on.",
         "The PostProcess component (a camera's own stack, or a volume: an entity with a shape and a size) holds one block of "
         "fields per post effect, named `<effect>Enabled` and `<effect>Parameter`: bloomEnabled, bloomIntensity, tonemapMode, "
         "vignetteIntensity... and the meta fields enabled, shape (global, box, circle, sphere), size, blendDistance, priority "
         "and weight. Result: {id, effects, order, value}; `effects` lists the effects this component switches on, in the order "
         "they run; `order` is the order of every effect (the same as render.supports lists them); `value` has every field "
         "(or only the names in `fields`). Example: postprocess.get {\"id\":\"camera\",\"fields\":[\"bloomEnabled\","
         "\"bloomIntensity\"]}" FA_COMMAND_DETAILS
         "While M71 is in progress the fields are stored and saved with the scene, and an effect is drawn once the renderer "
         "supports it (render.supports names which). Errors: `not_found` for an unknown entity, `invalid_argument` for an entity "
         "without a PostProcess (add one with postprocess.set) or a field name that does not exist (with a did-you-mean).",
         parse_schema(R"({"type":"object","required":["id"],"properties":{
               "id":{"type":"string","description":"Entity id (or name) that has the PostProcess component."},
               "fields":{"type":"array","items":{"type":"string"},"description":"Only these fields (names as in api.components, e.g. bloomIntensity). Default: every field."}}})"),
         true, "scene"},
        [&I](const Json& a) {
            check_args_known(a, {"id", "fields"}, "postprocess.get");
            const Entity e = need_entity(I.world, a);
            const PostProcess* p = I.world.get<PostProcess>(e);
            if (!p)
                throw CommandError("invalid_argument",
                                   std::format("postprocess.get: '{}' has no PostProcess.", I.world.id_of(e)),
                                   "Add one: postprocess.set {id, fields: {bloomEnabled: true}}.");
            Json value = component_to_json(I.world, e, post_type(), true, true);
            if (a.contains("fields")) {
                if (!a["fields"].is_array())
                    throw CommandError("invalid_argument", "fields: " + describe_json_value(a["fields"]) + " is not an array.",
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
            return Json::object({{"id", I.world.id_of(e)}, {"effects", running_effects(*p)}, {"order", order}, {"value", value}});
        });

    I.commands.add(
        {"postprocess.set", "Set fields of the PostProcess component of an entity (added when missing).",
         "Like scene.set_component with component \"PostProcess\": `fields` is a partial object, the fields you do not name keep "
         "their value, a bad field or value changes nothing and the error names the field, the allowed values and the range. "
         "Turn an effect on with `<effect>Enabled` and tune it with its parameters in one call. Example: postprocess.set "
         "{\"id\":\"camera\",\"fields\":{\"tonemapEnabled\":true,\"tonemapMode\":\"aces\",\"bloomEnabled\":true,"
         "\"bloomIntensity\":0.8}}. A volume: an entity without a Camera whose PostProcess has shape box, circle or sphere "
         "(size, blendDistance, priority, weight): postprocess.set {\"id\":\"cave\",\"fields\":{\"shape\":\"box\","
         "\"size\":[10,6,10],\"blendDistance\":3,\"vignetteEnabled\":true}}" FA_COMMAND_DETAILS
         "Result: {id, effects, value} as postprocess.get. `merge` reads `fields` as an RFC 7386 merge-patch like "
         "scene.set_component (a null resets a field to its default). The picture changes when the renderer draws the effect "
         "(render.supports says which it does); the fields are stored either way.",
         parse_schema(R"({"type":"object","required":["id","fields"],"properties":{
               "id":{"type":"string","description":"Entity id (or name). The PostProcess is added when it has none."},
               "fields":{"type":"object","description":"Field name -> value, e.g. {\"bloomEnabled\": true, \"bloomIntensity\": 0.8}."},
               "merge":{"type":"boolean","default":false,"description":"true = read `fields` as an RFC 7386 merge-patch: a null resets the field to its default."}}})"),
         false, "scene"},
        [&I](const Json& a) {
            check_args_known(a, {"id", "fields", "merge"}, "postprocess.set");
            if (!a.contains("fields") || !a["fields"].is_object())
                throw CommandError("invalid_argument", "postprocess.set: missing the object 'fields'.",
                                   "Pass {id, fields: {bloomEnabled: true}}; api.components lists the fields of PostProcess.");
            Json args = a;
            args["component"] = "PostProcess";
            Json r = set_component(I.world, args);
            const Entity e = need_entity(I.world, a);
            const PostProcess* p = I.world.get<PostProcess>(e);
            r.erase("component");
            r["effects"] = p ? running_effects(*p) : Json::array();
            return r;
        });

    I.commands.add(
        {"postprocess.presets", "List the named post-processing looks that postprocess.set can apply.",
         "A preset is a named set of PostProcess fields (a look: cinematic, retro...). There are none yet: the list is empty "
         "until the effects that make them worth having are drawn. Result: {presets: [{name, doc, fields}]}. Example: "
         "postprocess.presets {}",
         parse_schema(R"({"type":"object","properties":{}})"), true, "scene"},
        [](const Json& a) {
            check_args_known(a, {}, "postprocess.presets");
            return Json::object({{"presets", Json::array()}});
        });

    declare_command_capabilities(I.commands, {
                                                 {"postprocess.get", capability_sets::reads()},
                                                 {"postprocess.set", capability_sets::changes_state()},
                                                 {"postprocess.presets", capability_sets::reads()},
                                             });
}

}  // namespace fa
