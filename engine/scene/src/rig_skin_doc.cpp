// The `skin` section of a rig document: reading, writing, checking and the schema (rig_skin_doc.h). The weights are rig_skin.cpp.
#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "fa/core/strings.h"
#include "fa/scene/model_doc.h"
#include "fa/scene/model_select.h"
#include "fa/scene/rig_doc.h"

namespace fa {

namespace {

const std::vector<std::string>& method_names() {
    static const std::vector<std::string> v = {"auto", "heat", "voxel", "rigid"};
    return v;
}
const std::vector<std::string>& op_names() {
    static const std::vector<std::string> v = {"set", "add", "smooth", "normalize", "limit", "mirror"};
    return v;
}

bool number_in(const Json& j, double lo, double hi) { return j.is_number() && j.get<double>() >= lo && j.get<double>() <= hi; }

}  // namespace

bool RigSkinSettings::is_default() const {
    const RigSkinSettings d;
    return method == d.method && maxInfluences == d.maxInfluences && smooth == d.smooth && maxHops == d.maxHops && locality == d.locality && parts.empty() && edits.empty();
}

const std::vector<RigSkinOpInfo>& rig_skin_ops() {
    static const std::vector<RigSkinOpInfo> v = {
        {"set", "Gives `bone` the weight `weight` (0..1) on the selected vertices; the other bones share what is left in their proportions (a vertex that had no other bone gives it to the parent of `bone`). weight 1 binds the vertices rigidly to the bone."},
        {"add", "Adds `amount` (-1..1) to the weight of `bone` on the selected vertices (a negative amount takes weight away) and renormalises the others."},
        {"smooth", "Averages the weights of each selected vertex with those of its neighbours on the mesh, `iterations` passes of `strength`. Softens a joint; seams between parts are welded for it."},
        {"normalize", "Makes the weights of the selected vertices sum to 1 after dropping the influences under `threshold`."},
        {"limit", "Keeps the `max` strongest influences of the selected vertices (1..4) and renormalises."},
        {"mirror", "Copies the weights of the `from` side (\"l\" is +X) to the matching vertices of the other side, swapping each bone for its `_l` / `_r` partner; bones without a side map to themselves, vertices on the symmetry plane are made symmetric."},
    };
    return v;
}

const std::vector<RigSkinOpInfo>& rig_skin_methods() {
    static const std::vector<RigSkinOpInfo> v = {
        {"auto", "heat diffusion for every part, except in a generic rig, where each part follows its bone rigidly (the robot style)."},
        {"heat", "Bone heat: each bone's weight diffuses over the mesh surface from the vertices nearest to it (a Laplace solve on the welded mesh), so weights are smooth, local and stay inside the part."},
        {"voxel", "Voxel binding: the surface is voxelised and each bone's distance travels along the voxels, so a vertex weights the bones that are near it AROUND the shape, not through the air. For meshes heat cannot solve (open, non-manifold or in pieces)."},
        {"rigid", "The whole part follows ONE bone with weight 1: the part's bone from the fit (`bone` overrides it). For robots, doors and characters made of parts."},
    };
    return v;
}

void parse_rig_skin(const Json& json, RigSkinSettings& out, std::vector<RigIssue>& issues) {
    auto err = [&](const std::string& pointer, const std::string& message, const std::string& hint) { issues.push_back({pointer, message, hint}); };
    if (!json.is_object()) {
        err("/skin", "skin must be an object, got " + describe_json_value(json), "Example: {\"method\": \"heat\", \"edits\": []}. docs/RIGGING.md, \"Skin weights\", lists the fields.");
        return;
    }
    static const std::vector<std::string> keys = {"method", "maxInfluences", "smooth", "maxHops", "locality", "parts", "edits"};
    for (auto it = json.begin(); it != json.end(); ++it)
        if (std::find(keys.begin(), keys.end(), it.key()) == keys.end()) err("/skin/" + it.key(), "\"" + it.key() + "\" is not a field of skin", did_you_mean(it.key(), keys));
    auto method_of = [&](const Json& j, const std::string& at, std::string& dst) {
        if (!j.is_string() || std::find(method_names().begin(), method_names().end(), j.get<std::string>()) == method_names().end())
            err(at, "method must be one of " + join(method_names(), ", ") + ", got " + describe_json_value(j), j.is_string() ? did_you_mean(j.get<std::string>(), method_names()) : "auto, heat, voxel or rigid.");
        else dst = j.get<std::string>();
    };
    if (auto it = json.find("method"); it != json.end()) method_of(*it, "/skin/method", out.method);
    if (auto it = json.find("maxInfluences"); it != json.end()) {
        if (!number_in(*it, 1, 4) || !it->is_number_integer()) err("/skin/maxInfluences", "maxInfluences must be a whole number from 1 to 4, got " + describe_json_value(*it), "A vertex follows at most 4 bones (the renderer's JOINTS_0 / WEIGHTS_0).");
        else out.maxInfluences = it->get<int>();
    }
    if (auto it = json.find("smooth"); it != json.end()) {
        if (!number_in(*it, 0, 8) || !it->is_number_integer()) err("/skin/smooth", "smooth must be a whole number from 0 to 8, got " + describe_json_value(*it), "Passes of smoothing over the automatic weights; 0 leaves them as the solver made them.");
        else out.smooth = it->get<int>();
    }
    if (auto it = json.find("maxHops"); it != json.end()) {
        if (!number_in(*it, 1, 8) || !it->is_number_integer()) err("/skin/maxHops", "maxHops must be a whole number from 1 to 8, got " + describe_json_value(*it), "The farthest a bone may be, counting bones along the skeleton, from the strongest bone of a vertex and still weigh on it.");
        else out.maxHops = it->get<int>();
    }
    if (auto it = json.find("locality"); it != json.end()) {
        if (!number_in(*it, 0.05, 20)) err("/skin/locality", "locality must be a number from 0.05 to 20, got " + describe_json_value(*it), "Higher keeps each bone's weights close to it (short blends at the joints), lower spreads them. Default 1.");
        else out.locality = it->get<float>();
    }
    if (auto it = json.find("parts"); it != json.end()) {
        if (!it->is_object()) err("/skin/parts", "parts must be an object of model part to {method, bone}, got " + describe_json_value(*it), "Example: {\"sleeve\": {\"method\": \"rigid\", \"bone\": \"arm_upper_l\"}}.");
        else
            for (auto p = it->begin(); p != it->end(); ++p) {
                const std::string at = "/skin/parts/" + p.key();
                if (!p->is_object()) {
                    err(at, "a part's binding must be an object like {\"method\": \"rigid\", \"bone\": \"hand_l\"}, got " + describe_json_value(*p), "Fields: method, bone.");
                    continue;
                }
                RigSkinPart sp;
                static const std::vector<std::string> partKeys = {"method", "bone"};
                for (auto k = p->begin(); k != p->end(); ++k)
                    if (std::find(partKeys.begin(), partKeys.end(), k.key()) == partKeys.end()) err(at + "/" + k.key(), "\"" + k.key() + "\" is not a field of a part's binding", did_you_mean(k.key(), partKeys));
                if (auto m = p->find("method"); m != p->end()) method_of(*m, at + "/method", sp.method);
                if (auto b = p->find("bone"); b != p->end()) {
                    if (!b->is_string() || b->get<std::string>().empty()) err(at + "/bone", "bone must be the name of a bone, got " + describe_json_value(*b), "rig.templates {\"name\": ...} lists the bones.");
                    else sp.bone = b->get<std::string>();
                }
                out.parts.emplace_back(p.key(), std::move(sp));
            }
    }
    if (auto it = json.find("edits"); it != json.end()) {
        if (!it->is_array()) {
            err("/skin/edits", "edits must be a list, got " + describe_json_value(*it), "Each edit is {\"op\": \"set\", \"bone\": \"hand_l\", \"weight\": 1, \"part\": \"glove\"}; the skin3d.* commands write them.");
            return;
        }
        for (std::size_t i = 0; i < it->size(); ++i) {
            const Json& e = (*it)[i];
            const std::string at = "/skin/edits/" + std::to_string(i);
            if (!e.is_object()) {
                err(at, "an edit must be an object with an `op`, got " + describe_json_value(e), "Ops: " + join(op_names(), ", ") + ".");
                continue;
            }
            RigSkinEdit ed;
            ed.pointer = at;
            static const std::vector<std::string> editKeys = {"op", "bone", "from", "weight", "amount", "strength", "threshold", "iterations", "max", "part", "parts", "select"};
            for (auto k = e.begin(); k != e.end(); ++k)
                if (std::find(editKeys.begin(), editKeys.end(), k.key()) == editKeys.end()) err(at + "/" + k.key(), "\"" + k.key() + "\" is not a field of an edit", did_you_mean(k.key(), editKeys));
            auto op = e.find("op");
            if (op == e.end() || !op->is_string() || std::find(op_names().begin(), op_names().end(), op->get<std::string>()) == op_names().end()) {
                err(at + "/op", "op must be one of " + join(op_names(), ", ") + ", got " + (op == e.end() ? std::string("nothing") : describe_json_value(*op)),
                    op != e.end() && op->is_string() ? did_you_mean(op->get<std::string>(), op_names()) : "Example: \"set\".");
                continue;
            }
            ed.op = op->get<std::string>();
            auto number = [&](const char* key, float& dst, double lo, double hi, const char* hint) {
                auto f = e.find(key);
                if (f == e.end()) return;
                if (!number_in(*f, lo, hi)) err(at + "/" + key, std::format("{} must be a number from {} to {}, got {}", key, lo, hi, describe_json_value(*f)), hint);
                else dst = f->get<float>();
            };
            auto whole = [&](const char* key, int& dst, int lo, int hi, const char* hint) {
                auto f = e.find(key);
                if (f == e.end()) return;
                if (!number_in(*f, lo, hi) || !f->is_number_integer()) err(at + "/" + key, std::format("{} must be a whole number from {} to {}, got {}", key, lo, hi, describe_json_value(*f)), hint);
                else dst = f->get<int>();
            };
            if (ed.op == "set" || ed.op == "add") {
                if (auto b = e.find("bone"); b == e.end() || !b->is_string() || b->get<std::string>().empty())
                    err(at + "/bone", "a " + ed.op + " edit needs `bone`, the bone whose weight changes", "Example: \"bone\": \"arm_upper_l\". rig.templates {\"name\": ...} lists the bones.");
                else ed.bone = b->get<std::string>();
            }
            if (ed.op == "set") number("weight", ed.weight, 0, 1, "0 takes the bone off the vertices, 1 binds them wholly to it.");
            if (ed.op == "add") number("amount", ed.amount, -1, 1, "Positive gives the bone more weight, negative takes weight away.");
            if (ed.op == "smooth") {
                whole("iterations", ed.iterations, 1, 50, "Passes of smoothing.");
                number("strength", ed.strength, 0, 1, "0 changes nothing, 1 replaces each vertex's weights with its neighbours' average.");
            }
            if (ed.op == "normalize") number("threshold", ed.threshold, 0, 0.5, "Influences under this weight are dropped.");
            if (ed.op == "limit") whole("max", ed.max, 1, 4, "Bones kept per vertex, 1 to 4.");
            if (ed.op == "mirror") {
                auto f = e.find("from");
                if (f == e.end() || !f->is_string() || (f->get<std::string>() != "l" && f->get<std::string>() != "r"))
                    err(at + "/from", "a mirror edit needs `from`: \"l\" or \"r\", the side whose weights are copied to the other", "\"l\" is the +X side, \"r\" the -X side.");
                else ed.from = f->get<std::string>();
            }
            // the fields that do not belong to the op are mistakes, not noise
            auto expects = [&](const char* key, bool ok) {
                if (e.contains(key) && !ok) err(at + "/" + key, std::string("a ") + ed.op + " edit has no `" + key + "`", "Fields of " + ed.op + ": see skin3d." + ed.op + " in `factoria docs commands`.");
            };
            expects("bone", ed.op == "set" || ed.op == "add");
            expects("weight", ed.op == "set");
            expects("amount", ed.op == "add");
            expects("iterations", ed.op == "smooth");
            expects("strength", ed.op == "smooth");
            expects("threshold", ed.op == "normalize");
            expects("max", ed.op == "limit");
            expects("from", ed.op == "mirror");
            for (const char* key : {"part", "parts"}) {
                auto f = e.find(key);
                if (f == e.end()) continue;
                if (f->is_string()) ed.parts.push_back(f->get<std::string>());
                else if (f->is_array() && !f->empty() && std::all_of(f->begin(), f->end(), [](const Json& n) { return n.is_string(); }))
                    for (const Json& n : *f) ed.parts.push_back(n.get<std::string>());
                else err(at + "/" + key, "part must be a part name or a non-empty list of part names, got " + describe_json_value(*f), "Part names are the `part` of the model document's nodes (model.info lists them).");
            }
            if (auto s = e.find("select"); s != e.end() && !s->is_null()) {
                std::vector<ModelIssue> sel;
                check_model_selection(*s, ModelSelectKind::Faces, at + "/select", sel);
                for (const ModelIssue& m : sel) err(m.pointer, m.message, m.hint);
                ed.select = *s;
            }
            out.edits.push_back(std::move(ed));
        }
    }
}

std::vector<RigIssue> rig_check_skin(const RigDoc& doc, const std::vector<std::string>& boneNames) {
    std::vector<RigIssue> issues;
    auto bone_ok = [&](const std::string& b) { return std::find(boneNames.begin(), boneNames.end(), b) != boneNames.end(); };
    for (const auto& [part, sp] : doc.skin.parts)
        if (!sp.bone.empty() && !bone_ok(sp.bone))
            issues.push_back({"/skin/parts/" + part + "/bone", "'" + sp.bone + "' is not a bone of the " + doc.templateName + " rig", did_you_mean(sp.bone, boneNames)});
    for (const RigSkinEdit& e : doc.skin.edits)
        if (!e.bone.empty() && !bone_ok(e.bone))
            issues.push_back({e.pointer + "/bone", "'" + e.bone + "' is not a bone of the " + doc.templateName + " rig", did_you_mean(e.bone, boneNames)});
    return issues;
}

Json rig_skin_edit_to_json(const RigSkinEdit& e) {
    Json j = Json::object();
    j["op"] = e.op;
    if (e.op == "set" || e.op == "add") j["bone"] = e.bone;
    if (e.op == "set") j["weight"] = e.weight;
    if (e.op == "add") j["amount"] = e.amount;
    if (e.op == "smooth") {
        j["iterations"] = e.iterations;
        j["strength"] = e.strength;
    }
    if (e.op == "normalize") j["threshold"] = e.threshold;
    if (e.op == "limit") j["max"] = e.max;
    if (e.op == "mirror") j["from"] = e.from;
    if (e.parts.size() == 1) j["part"] = e.parts[0];
    else if (!e.parts.empty()) j["part"] = e.parts;
    if (!e.select.is_null()) j["select"] = e.select;
    return j;
}

Json rig_skin_to_json(const RigSkinSettings& s) {
    if (s.is_default()) return Json();
    const RigSkinSettings d;
    Json j = Json::object();
    if (s.method != d.method) j["method"] = s.method;
    if (s.maxInfluences != d.maxInfluences) j["maxInfluences"] = s.maxInfluences;
    if (s.smooth != d.smooth) j["smooth"] = s.smooth;
    if (s.maxHops != d.maxHops) j["maxHops"] = s.maxHops;
    if (s.locality != d.locality) j["locality"] = s.locality;
    if (!s.parts.empty()) {
        Json p = Json::object();
        for (const auto& [part, sp] : s.parts) {
            Json o = Json::object();
            if (!sp.method.empty()) o["method"] = sp.method;
            if (!sp.bone.empty()) o["bone"] = sp.bone;
            p[part] = o;
        }
        j["parts"] = p;
    }
    if (!s.edits.empty()) {
        Json arr = Json::array();
        for (const RigSkinEdit& e : s.edits) arr.push_back(rig_skin_edit_to_json(e));
        j["edits"] = arr;
    }
    return j;
}

Json rig_skin_schema() {
    Json methodEnum = Json::object({{"enum", method_names()}});
    std::string methodDoc;
    for (const RigSkinOpInfo& m : rig_skin_methods()) methodDoc += " " + m.op + ": " + m.doc;
    std::string opDoc;
    for (const RigSkinOpInfo& o : rig_skin_ops()) opDoc += " " + o.op + ": " + o.doc;
    Json selection = model_selection_schema(ModelSelectKind::Faces);
    Json partSchema = Json::object();
    partSchema["oneOf"] = Json::array({Json{{"type", "string"}}, Json{{"type", "array"}, {"items", Json{{"type", "string"}}}, {"minItems", 1}}});
    partSchema["description"] = "Model part(s) the edit works on.";
    Json edit = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"required", Json::array({"op"})},
         {"description", "One edit of the weights, applied in order after the automatic ones." + opDoc},
         {"properties",
          Json::object({{"op", Json::object({{"enum", op_names()}, {"description", "What the edit does."}})},
                        {"bone", Json::object({{"type", "string"}, {"description", "set, add: the bone whose weight changes."}})},
                        {"weight", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "set: the weight the bone gets."}})},
                        {"amount", Json::object({{"type", "number"}, {"minimum", -1}, {"maximum", 1}, {"description", "add: added to the bone's weight."}})},
                        {"iterations", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", 50}, {"description", "smooth: passes."}})},
                        {"strength", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "smooth: how far a pass moves a vertex to its neighbours' average."}})},
                        {"threshold", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 0.5}, {"description", "normalize: influences under this weight are dropped."}})},
                        {"max", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", 4}, {"description", "limit: influences kept per vertex."}})},
                        {"from", Json::object({{"enum", Json::array({"l", "r"})}, {"description", "mirror: the side whose weights are copied (l = +X)."}})},
                        {"part", partSchema},
                        {"select", selection}})}});
    return Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "How the vertices are bound to the bones (docs/RIGGING.md, \"Skin weights\"). Left out: the automatic weights with their defaults."},
         {"properties",
          Json::object({{"method", Json::object({{"enum", method_names()}, {"description", "The default method for every part." + methodDoc + " Default auto."}})},
                        {"maxInfluences", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", 4}, {"description", "Bones per vertex. Default 4."}})},
                        {"smooth", Json::object({{"type", "integer"}, {"minimum", 0}, {"maximum", 8}, {"description", "Smoothing passes over the automatic weights. Default 1."}})},
                        {"maxHops", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", 8}, {"description", "A vertex is not weighted to a bone further than this many bones from its strongest bone along the skeleton. Default 2."}})},
                        {"locality", Json::object({{"type", "number"}, {"minimum", 0.05}, {"maximum", 20}, {"description", "Heat diffusion: higher keeps each bone's weights close to it (short blends), lower spreads them. Default 1."}})},
                        {"parts", Json::object({{"type", "object"},
                                                {"description", "Model part -> how it is bound. A part that is not in the model is an error."},
                                                {"additionalProperties", Json::object({{"type", "object"},
                                                                                       {"additionalProperties", false},
                                                                                       {"properties", Json::object({{"method", methodEnum},
                                                                                                                    {"bone", Json::object({{"type", "string"}, {"description", "The bone the part follows (rigid) or is centred on (heat, voxel); default: the bones the fit gave the part."}})}})}})}})},
                        {"edits", Json::object({{"type", "array"}, {"description", "Edits of the weights, applied in order (skin3d.* commands append them)."}, {"items", edit}})}})}});
}

}  // namespace fa
