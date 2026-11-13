// Rig documents: the catalog of templates, reading and writing the format, the schema. The fit is rig_fit.cpp.
#include "fa/scene/rig_doc.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

const char* kAxisChoices[] = {"+x", "-x", "+y", "-y", "+z", "-z"};

RigOptionInfo int_option(const char* key, const char* doc, int def, int lo, int hi) {
    RigOptionInfo o;
    o.key = key;
    o.type = "integer";
    o.doc = doc;
    o.def = def;
    o.min = lo;
    o.max = hi;
    return o;
}
RigOptionInfo choice_option(const char* key, const char* doc, const char* def, std::vector<std::string> choices) {
    RigOptionInfo o;
    o.key = key;
    o.type = "choice";
    o.doc = doc;
    o.def = def;
    o.choices = std::move(choices);
    return o;
}
RigOptionInfo bool_option(const char* key, const char* doc, bool def) {
    RigOptionInfo o;
    o.key = key;
    o.type = "boolean";
    o.doc = doc;
    o.def = def;
    return o;
}

std::vector<RigTemplateInfo> make_templates() {
    std::vector<RigTemplateInfo> t;
    {
        RigTemplateInfo h;
        h.name = "humanoid";
        h.doc = "A standing two-legged character that looks towards +Z (character-left is +X): root (the hips), a "
                "spine chain, neck, head, a clavicle, upper arm, "
                "forearm and hand on each side, and a thigh, shin, foot and toe on each side. Arms hang at the sides "
                "(an A or relaxed pose) or are held out (a T "
                "pose): `pose` auto reads which from the model's proportions. Tail bones are optional.";
        h.options = {
            int_option("spine", "Bones between the hips and the neck: spine_1..spine_N.", 3, 1, 5),
            int_option("neck", "Bones between the shoulders and the head: neck (one) or neck_1..neck_N.", 1, 1, 3),
            int_option("tail", "Tail bones tail_1..tail_N from the hips backwards; 0 = none.", 0, 0, 12),
            bool_option("toes",
                        "A toe bone on each foot (the ball of the foot bends). false: the foot ends at the ball.",
                        true),
            choice_option("pose",
                          "The arms' rest pose: \"down\" (hanging), \"out\" (held out sideways, T pose) or \"auto\" "
                          "(out when the model is wider than 0.75 of its height).",
                          "auto", {"auto", "down", "out"})};
        h.partWords = {"head: head, skull, face, helmet, hat",
                       "neck: neck",
                       "torso: torso, body, chest, trunk, spine, pelvis, hips, waist",
                       "arms: arm, upper_arm, forearm, lower_arm, hand, fist, palm, shoulder, with l/left/r/right",
                       "legs: leg, thigh, upper_leg, shin, calf, lower_leg, foot, feet, toe, with l/left/r/right",
                       "tail: tail"};
        t.push_back(h);
    }
    {
        RigTemplateInfo q;
        q.name = "quadruped";
        q.doc = "A four-legged animal that looks towards +Z (a dog, a horse, a cat): root (the pelvis), a spine chain "
                "along the back, a neck chain, the head, "
                "front legs as clavicle, arm_upper, arm_lower and hand (the front leg is the arm of the canonical "
                "names) and hind legs as thigh, shin, foot and toe, "
                "and a tail chain. The same canonical names as the humanoid, so a clip can be retargeted between them.";
        q.options = {int_option("spine", "Bones between the pelvis and the neck: spine_1..spine_N.", 3, 1, 5),
                     int_option("neck", "Neck bones neck_1..neck_N.", 2, 1, 4),
                     int_option("tail", "Tail bones tail_1..tail_N; 0 = none.", 4, 0, 12)};
        q.partWords = {"head: head, skull, snout, muzzle, face",
                       "neck: neck",
                       "body: body, torso, trunk, barrel, chest, pelvis, hips",
                       "front legs: foreleg, front_leg, arm, upper_arm, forearm, hand, paw, with l/left/r/right",
                       "hind legs: hindleg, hind_leg, leg, thigh, shin, foot, toe, hoof, with l/left/r/right",
                       "tail: tail"};
        t.push_back(q);
    }
    {
        RigTemplateInfo b;
        b.name = "bird";
        b.doc = "A bird that looks towards +Z: root (the pelvis), a short spine, a neck chain, the head (its tail is "
                "the beak tip), two legs "
                "(thigh, shin, foot, toe) and two wings (clavicle, arm_upper, arm_lower, hand), and tail feathers as a "
                "tail chain. Wings are folded against the body "
                "or spread: `pose` auto reads which from the model's proportions.";
        b.options = {int_option("spine", "Bones between the pelvis and the neck: spine_1..spine_N.", 2, 1, 3),
                     int_option("neck", "Neck bones neck_1..neck_N.", 3, 1, 6),
                     int_option("tail", "Tail bones tail_1..tail_N; 0 = none.", 2, 0, 6),
                     choice_option("pose",
                                   "The wings' rest pose: \"folded\", \"spread\" or \"auto\" (spread when the model is "
                                   "wider than it is long).",
                                   "auto", {"auto", "folded", "spread"})};
        b.partWords = {"head: head, skull, beak, bill",
                       "neck: neck",
                       "body: body, torso, trunk, breast, chest",
                       "wings: wing, upper_wing, forewing, hand, primaries, with l/left/r/right",
                       "legs: leg, thigh, shin, foot, toe, claw, with l/left/r/right",
                       "tail: tail"};
        t.push_back(b);
    }
    {
        RigTemplateInfo tail;
        tail.name = "tail";
        tail.doc = "A chain for a tail, tentacle, antenna or rope-like model: root at one end and tail_1..tail_N "
                   "spaced evenly along `axis` over the model (or over its "
                   "\"tail\" part when it has one). `axis` is the direction the chain grows from its base.";
        tail.options = {int_option("segments", "Bones tail_1..tail_N.", 5, 2, 32),
                        choice_option("axis",
                                      "The direction the chain grows from its base: +x, -x, +y, -y, +z or -z. The base "
                                      "is at the opposite end of the model.",
                                      "-z", {kAxisChoices, kAxisChoices + 6})};
        tail.partWords = {"tail: tail, tentacle, antenna, whip"};
        t.push_back(tail);
    }
    {
        RigTemplateInfo c;
        c.name = "chain";
        c.doc = "A chain of equal links for a rope, chain, bridge cable or hanging lamp: root at one end and "
                "chain_1..chain_N spaced evenly along `axis` over the "
                "model (or over its \"chain\" part). The same as the tail template with chain bones.";
        c.options = {int_option("segments", "Bones chain_1..chain_N.", 6, 2, 32),
                     choice_option("axis",
                                   "The direction the chain grows from its base: +x, -x, +y, -y, +z or -z. The base is "
                                   "at the opposite end of the model.",
                                   "-y", {kAxisChoices, kAxisChoices + 6})};
        c.partWords = {"chain: chain, rope, cable, link"};
        t.push_back(c);
    }
    {
        RigTemplateInfo g;
        g.name = "generic";
        g.doc = "Bones you list yourself in `bones` for anything else (a robot arm, a door, a vehicle with wheels): "
                "`root` plus a bone per entry, each with its parent "
                "and the model part it moves; the joint sits at `anchor` of that part's bounds (the centre by "
                "default). rig.create with no bones makes one bone per "
                "part of the model, all under root.";
        g.partWords = {"every bone names its own part exactly"};
        t.push_back(g);
    }
    return t;
}

bool valid_bone_name(const std::string& n) {
    if (n.empty() || n.size() > 48) return false;
    if (!(n[0] >= 'a' && n[0] <= 'z')) return false;
    for (char c : n)
        if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_')) return false;
    return true;
}

std::vector<std::string> template_names() {
    std::vector<std::string> v;
    for (const RigTemplateInfo& t : rig_templates()) v.push_back(t.name);
    return v;
}

struct Reader {
    std::vector<RigIssue>& issues;
    void err(const std::string& pointer, const std::string& message, const std::string& hint) {
        issues.push_back({pointer, message, hint});
    }
};

}  // namespace

const std::vector<RigTemplateInfo>& rig_templates() {
    static const std::vector<RigTemplateInfo> v = make_templates();
    return v;
}

const RigTemplateInfo* find_rig_template(std::string_view name) {
    for (const RigTemplateInfo& t : rig_templates())
        if (t.name == name) return &t;
    return nullptr;
}

int RigDoc::optionInt(std::string_view key, int fallback) const {
    auto it = options.find(std::string(key));
    return it != options.end() && it->is_number_integer() ? it->get<int>() : fallback;
}
std::string RigDoc::optionString(std::string_view key, std::string_view fallback) const {
    auto it = options.find(std::string(key));
    return it != options.end() && it->is_string() ? it->get<std::string>() : std::string(fallback);
}
bool RigDoc::optionBool(std::string_view key, bool fallback) const {
    auto it = options.find(std::string(key));
    return it != options.end() && it->is_boolean() ? it->get<bool>() : fallback;
}

Result<RigDoc> parse_rig_doc(const Json& json, std::string_view file, std::vector<RigIssue>* issuesOut) {
    RigDoc doc;
    std::vector<RigIssue> issues;
    Reader r{issues};
    auto finish = [&]() -> Result<RigDoc> {
        if (issuesOut) *issuesOut = issues;
        if (issues.empty()) return doc;
        const RigIssue& first = issues.front();
        std::string where = std::string(file);
        if (!first.pointer.empty()) where += (where.empty() ? "" : " ") + first.pointer;
        std::string message = (where.empty() ? "" : where + ": ") + first.message;
        if (issues.size() > 1)
            message += std::format(" (and {} more problem{})", issues.size() - 1, issues.size() == 2 ? "" : "s");
        return make_error(message,
                          first.hint.empty()
                              ? "docs/RIGGING.md describes the format and schemas/rig.schema.json lists every field."
                              : first.hint);
    };
    if (!json.is_object()) {
        r.err("", "a rig document must be a JSON object, got " + describe_json_value(json),
              "Start from `rig.create`, or write {\"format\": \"factoria.rig/1\", \"model\": "
              "\"assets/models/hero.model.json\", \"template\": \"humanoid\"}.");
        return finish();
    }
    static const std::vector<std::string> topKeys = {"$schema", "format",  "doc",       "model",     "template",
                                                     "options", "parts",   "landmarks", "symmetryX", "strict",
                                                     "skin",    "binding", "output",    "bones"};
    for (auto it = json.begin(); it != json.end(); ++it)
        if (std::find(topKeys.begin(), topKeys.end(), it.key()) == topKeys.end())
            r.err("/" + it.key(), "\"" + it.key() + "\" is not a field of a rig document",
                  did_you_mean(it.key(), topKeys));
    if (auto it = json.find("format"); it == json.end())
        r.err("/format", "the document has no \"format\"", std::string("Add \"format\": \"") + kRigDocFormat + "\".");
    else if (!it->is_string() || it->get<std::string>() != kRigDocFormat)
        r.err("/format", "format must be \"" + std::string(kRigDocFormat) + "\", got " + describe_json_value(*it),
              "This reader only knows format 1.");
    if (auto it = json.find("doc"); it != json.end()) {
        if (!it->is_string())
            r.err("/doc", "doc must be text, got " + describe_json_value(*it),
                  "Say in a sentence what the rig is for.");
        else
            doc.doc = it->get<std::string>();
    }
    if (auto it = json.find("model"); it == json.end())
        r.err("/model", "the document has no \"model\"",
              "Name the model document the rig fits, e.g. \"model\": \"assets/models/hero.model.json\".");
    else if (!it->is_string() || !ends_with(to_lower(it->get<std::string>()), ".model.json"))
        r.err("/model",
              "model must be the project path of a model document ending in .model.json, got " +
                  describe_json_value(*it),
              "Example: \"assets/models/hero.model.json\". Create it with model.create.");
    else
        doc.model = it->get<std::string>();
    const RigTemplateInfo* tpl = nullptr;
    if (auto it = json.find("template"); it == json.end())
        r.err("/template", "the document has no \"template\"",
              "Choose one of: " + join(template_names(), ", ") + ". `rig.templates {}` describes them.");
    else if (!it->is_string() || !(tpl = find_rig_template(it->get<std::string>())))
        r.err("/template", "unknown template " + describe_json_value(*it),
              it->is_string() ? did_you_mean(it->get<std::string>(), template_names())
                              : "Choose one of: " + join(template_names(), ", ") + ".");
    else
        doc.templateName = tpl->name;

    // options: only the template's, in range, defaults filled in
    doc.options = Json::object();
    if (tpl)
        for (const RigOptionInfo& o : tpl->options) doc.options[o.key] = o.def;
    if (auto it = json.find("options"); it != json.end()) {
        if (!it->is_object())
            r.err("/options", "options must be an object, got " + describe_json_value(*it),
                  "Example: {\"spine\": 4}. `rig.templates {}` lists the options of each template.");
        else
            for (auto o = it->begin(); o != it->end(); ++o) {
                const std::string at = "/options/" + o.key();
                if (!tpl) continue;
                const RigOptionInfo* info = nullptr;
                for (const RigOptionInfo& oi : tpl->options)
                    if (oi.key == o.key()) info = &oi;
                if (!info) {
                    std::vector<std::string> keys;
                    for (const RigOptionInfo& oi : tpl->options) keys.push_back(oi.key);
                    r.err(at, "the " + tpl->name + " template has no option \"" + o.key() + "\"",
                          keys.empty() ? "This template takes no options." : did_you_mean(o.key(), keys));
                    continue;
                }
                if (info->type == "integer") {
                    if (!o->is_number_integer() || o->get<int>() < *info->min || o->get<int>() > *info->max)
                        r.err(at,
                              std::format("{} must be a whole number from {} to {}, got {}", o.key(), *info->min,
                                          *info->max, describe_json_value(*o)),
                              info->doc);
                    else
                        doc.options[o.key()] = *o;
                } else if (info->type == "boolean") {
                    if (!o->is_boolean())
                        r.err(at, o.key() + " must be true or false, got " + describe_json_value(*o), info->doc);
                    else
                        doc.options[o.key()] = *o;
                } else {
                    if (!o->is_string() || std::find(info->choices.begin(), info->choices.end(),
                                                     o->get<std::string>()) == info->choices.end())
                        r.err(at,
                              o.key() + " must be one of " + join(info->choices, ", ") + ", got " +
                                  describe_json_value(*o),
                              o->is_string() ? did_you_mean(o->get<std::string>(), info->choices) : info->doc);
                    else
                        doc.options[o.key()] = *o;
                }
            }
    }

    if (auto it = json.find("parts"); it != json.end()) {
        if (!it->is_object())
            r.err("/parts", "parts must be an object of bone name to part names, got " + describe_json_value(*it),
                  "Example: {\"head\": [\"skull\"], \"arm_upper_l\": \"sleeve_l\"}.");
        else
            for (auto p = it->begin(); p != it->end(); ++p) {
                const std::string at = "/parts/" + p.key();
                std::vector<std::string> names;
                if (p->is_string())
                    names.push_back(p->get<std::string>());
                else if (p->is_array()) {
                    bool ok = true;
                    for (const Json& n : *p) {
                        if (!n.is_string())
                            ok = false;
                        else
                            names.push_back(n.get<std::string>());
                    }
                    if (!ok || names.empty()) {
                        r.err(at,
                              "parts of a bone must be a part name or a non-empty list of part names, got " +
                                  describe_json_value(*p),
                              "Part names are the `part` of the model document's nodes (model.info lists them).");
                        continue;
                    }
                } else {
                    r.err(at,
                          "parts of a bone must be a part name or a list of part names, got " + describe_json_value(*p),
                          "Example: \"skull\" or [\"skull\", \"jaw\"].");
                    continue;
                }
                doc.parts.emplace_back(p.key(), std::move(names));
            }
    }
    if (auto it = json.find("landmarks"); it != json.end()) {
        if (!it->is_object())
            r.err("/landmarks",
                  "landmarks must be an object of landmark name to [x, y, z], got " + describe_json_value(*it),
                  "Example: {\"head\": [0, 1.5, 0], \"hand_l.tail\": [0.9, 1.1, 0]}.");
        else
            for (auto l = it->begin(); l != it->end(); ++l) {
                Vec3 v{};
                std::string why;
                if (!json_to(*l, v, &why) || !l->is_array() || l->size() != 3) {
                    r.err("/landmarks/" + l.key(),
                          "a landmark must be a position [x, y, z] in the model's space, got " +
                              describe_json_value(*l),
                          "Example: [0.2, 1.4, 0].");
                    continue;
                }
                doc.landmarks.emplace_back(l.key(), v);
            }
    }
    if (auto it = json.find("symmetryX"); it != json.end()) {
        if (!it->is_number())
            r.err("/symmetryX",
                  "symmetryX must be a number (the x of the symmetry plane), got " + describe_json_value(*it),
                  "Leave it out to use the centre of the model's bounds.");
        else
            doc.symmetryX = it->get<float>();
    }
    if (auto it = json.find("strict"); it != json.end()) {
        if (!it->is_boolean())
            r.err("/strict", "strict must be true or false, got " + describe_json_value(*it),
                  "true makes a landmark that was only estimated from proportions an error.");
        else
            doc.strict = it->get<bool>();
    }
    if (auto it = json.find("binding"); it != json.end())
        r.err("/binding", "\"binding\" was replaced by the `skin` section",
              "Write {\"skin\": {\"method\": \"rigid\"}} for the rigid binding; `skin.method` also takes auto, heat "
              "and voxel (docs/RIGGING.md, \"Skin weights\").");
    if (auto it = json.find("skin"); it != json.end()) parse_rig_skin(*it, doc.skin, issues);
    if (auto it = json.find("output"); it != json.end()) {
        if (!it->is_object())
            r.err("/output",
                  "output must be an object like {\"path\": \"assets/models/hero.rig.glb\"}, got " +
                      describe_json_value(*it),
                  "Leave it out to bake next to the document.");
        else {
            for (auto o = it->begin(); o != it->end(); ++o)
                if (o.key() != "path")
                    r.err("/output/" + o.key(), "\"" + o.key() + "\" is not a field of output",
                          did_you_mean(o.key(), std::vector<std::string>{"path"}));
            if (auto p = it->find("path"); p != it->end()) {
                if (!p->is_string() || !ends_with(to_lower(p->get<std::string>()), ".glb"))
                    r.err("/output/path",
                          "output.path must be a project path ending in .glb, got " + describe_json_value(*p),
                          "Example: \"assets/models/hero.rig.glb\".");
                else
                    doc.outputPath = p->get<std::string>();
            }
        }
    }
    if (auto it = json.find("bones"); it != json.end()) {
        if (tpl && tpl->name != "generic")
            r.err("/bones", "only the generic template takes a list of bones",
                  "Remove \"bones\", or set \"template\": \"generic\". The other templates have their own bones "
                  "(`rig.templates {name: \"" +
                      tpl->name + "\"}`).");
        else if (!it->is_array())
            r.err("/bones", "bones must be a list, got " + describe_json_value(*it),
                  "Example: [{\"name\": \"arm\", \"part\": \"arm\"}, {\"name\": \"hand\", \"parent\": \"arm\", "
                  "\"part\": \"hand\"}].");
        else
            for (std::size_t i = 0; i < it->size(); ++i) {
                const Json& b = (*it)[i];
                const std::string at = "/bones/" + std::to_string(i);
                if (!b.is_object()) {
                    r.err(at,
                          "a bone must be an object like {\"name\": \"arm\", \"part\": \"arm\"}, got " +
                              describe_json_value(b),
                          "Fields: name, parent, role, part, anchor, tailAnchor.");
                    continue;
                }
                static const std::vector<std::string> boneKeys = {"name", "parent", "role",
                                                                  "part", "anchor", "tailAnchor"};
                for (auto k = b.begin(); k != b.end(); ++k)
                    if (std::find(boneKeys.begin(), boneKeys.end(), k.key()) == boneKeys.end())
                        r.err(at + "/" + k.key(), "\"" + k.key() + "\" is not a field of a bone",
                              did_you_mean(k.key(), boneKeys));
                RigGenericBone g;
                g.pointer = at;
                auto text = [&](const char* key, std::string& out, bool required) {
                    auto f = b.find(key);
                    if (f == b.end()) {
                        if (required)
                            r.err(at + "/" + key, std::string("the bone has no \"") + key + "\"",
                                  "Name the bone with lowercase letters, digits and underscores, e.g. \"arm\".");
                        return;
                    }
                    if (!f->is_string())
                        r.err(at + "/" + key, std::string(key) + " must be text, got " + describe_json_value(*f), "");
                    else
                        out = f->get<std::string>();
                };
                text("name", g.name, true);
                text("parent", g.parent, false);
                text("role", g.role, false);
                text("part", g.part, false);
                if (!g.name.empty() && !valid_bone_name(g.name))
                    r.err(at + "/name", "'" + g.name + "' is not a valid bone name",
                          "Use 1 to 48 characters: lowercase letters, digits and underscores, starting with a letter.");
                if (!g.role.empty() && !valid_bone_name(g.role))
                    r.err(at + "/role", "'" + g.role + "' is not a valid role",
                          "Use lowercase letters, digits and underscores, e.g. \"arm_upper\".");
                for (const char* key : {"anchor", "tailAnchor"}) {
                    auto f = b.find(key);
                    if (f == b.end()) continue;
                    Vec3 v{};
                    std::string why;
                    if (!f->is_array() || f->size() != 3 || !json_to(*f, v, &why) || std::fabs(v.x) > 1 ||
                        std::fabs(v.y) > 1 || std::fabs(v.z) > 1) {
                        r.err(at + "/" + key,
                              std::string(key) + " must be [x, y, z] with each number from -1 to 1, got " +
                                  describe_json_value(*f),
                              "-1..1 around the centre of the part's bounds: [0, 0, 0] the centre, [0, -1, 0] the "
                              "bottom, [0, 1, 0] the top, [1, 0, 0] the +X side.");
                        continue;
                    }
                    if (std::string(key) == "anchor")
                        g.anchor = v;
                    else
                        g.tailAnchor = v;
                }
                doc.bones.push_back(std::move(g));
            }
    }
    return finish();
}

Result<RigDoc> load_rig_doc(std::string_view path, std::vector<RigIssue>* issues) {
    auto text = fs::read_text(path);
    if (!text)
        return make_error(std::string(path) + ": cannot read the rig document: " + text.error().message,
                          text.error().hint.empty()
                              ? "Rig documents are *.rig.json files; rig.create writes a starting point."
                              : text.error().hint);
    auto json = parse_json(*text, path);
    if (!json) return json.error();
    return parse_rig_doc(*json, path, issues);
}

Json rig_doc_to_json(const RigDoc& doc) {
    Json j = Json::object();
    j["format"] = kRigDocFormat;
    if (!doc.doc.empty()) j["doc"] = doc.doc;
    j["model"] = doc.model;
    j["template"] = doc.templateName;
    if (!doc.options.empty()) j["options"] = doc.options;
    if (!doc.parts.empty()) {
        Json p = Json::object();
        for (const auto& [bone, names] : doc.parts) {
            if (names.size() == 1)
                p[bone] = names[0];
            else
                p[bone] = names;
        }
        j["parts"] = p;
    }
    if (!doc.landmarks.empty()) {
        Json l = Json::object();
        for (const auto& [name, v] : doc.landmarks) l[name] = to_json(v);
        j["landmarks"] = l;
    }
    if (doc.symmetryX) j["symmetryX"] = to_json(*doc.symmetryX);
    if (doc.strict) j["strict"] = true;
    if (Json skin = rig_skin_to_json(doc.skin); !skin.is_null()) j["skin"] = skin;
    if (!doc.outputPath.empty()) j["output"] = Json::object({{"path", doc.outputPath}});
    if (!doc.bones.empty()) {
        Json arr = Json::array();
        for (const RigGenericBone& b : doc.bones) {
            Json o = Json::object();
            o["name"] = b.name;
            if (!b.parent.empty()) o["parent"] = b.parent;
            if (!b.role.empty()) o["role"] = b.role;
            if (!b.part.empty()) o["part"] = b.part;
            if (b.anchor.x != 0 || b.anchor.y != 0 || b.anchor.z != 0) o["anchor"] = to_json(b.anchor);
            if (b.tailAnchor) o["tailAnchor"] = to_json(*b.tailAnchor);
            arr.push_back(o);
        }
        j["bones"] = arr;
    }
    return j;
}

RigDoc make_rig_doc(const std::string& model, const std::string& templateName,
                    const std::vector<std::string>& partNames) {
    RigDoc d;
    d.model = model;
    d.templateName = templateName;
    if (const RigTemplateInfo* t = find_rig_template(templateName))
        for (const RigOptionInfo& o : t->options) d.options[o.key] = o.def;
    if (templateName == "generic") {
        std::set<std::string> used = {"root"};
        for (const std::string& p : partNames) {
            std::string n;
            for (char c : to_lower(p)) n += ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) ? c : '_';
            if (n.empty() || !(n[0] >= 'a' && n[0] <= 'z')) n = "part_" + n;
            if (n.size() > 40) n.resize(40);
            std::string unique = n;
            for (int k = 2; used.count(unique); ++k) unique = n + "_" + std::to_string(k);
            used.insert(unique);
            RigGenericBone b;
            b.name = unique;
            b.part = p;
            d.bones.push_back(std::move(b));
        }
    }
    return d;
}

Json rig_doc_schema() {
    // the union of every template's options, each described with the templates it belongs to
    Json optionProps = Json::object();
    for (const RigTemplateInfo& t : rig_templates())
        for (const RigOptionInfo& o : t.options) {
            if (optionProps.contains(o.key)) {
                optionProps[o.key]["description"] = optionProps[o.key]["description"].get<std::string>() + " (" +
                                                    t.name + ": default " + o.def.dump() + ")";
                continue;
            }
            Json p = Json::object();
            if (o.type == "integer") {
                p["type"] = "integer";
                p["minimum"] = *o.min;
                p["maximum"] = *o.max;
            } else if (o.type == "boolean")
                p["type"] = "boolean";
            else {
                p["type"] = "string";
                p["enum"] = o.choices;
            }
            p["description"] = o.doc + " [" + t.name + ": default " + o.def.dump() + "]";
            optionProps[o.key] = p;
        }
    Json vec3 = Json::object(
        {{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 3}, {"maxItems", 3}});
    Json partNames = Json::object(
        {{"oneOf",
          Json::array(
              {Json::object({{"type", "string"}}),
               Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})}, {"minItems", 1}})})}});
    Json bone = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"required", Json::array({"name"})},
         {"properties",
          Json::object(
              {{"name", Json::object({{"type", "string"},
                                      {"pattern", "^[a-z][a-z0-9_]{0,47}$"},
                                      {"description", "The bone's name: lowercase letters, digits and underscores."}})},
               {"parent", Json::object({{"type", "string"},
                                        {"description", "The bone it hangs from, listed earlier. Left out: root."}})},
               {"role", Json::object({{"type", "string"},
                                      {"description",
                                       "What the bone is for retargeting (arm_upper, hand...). Left out: the name."}})},
               {"part", Json::object({{"type", "string"},
                                      {"description",
                                       "The model part this bone moves; its joint is placed in that part's bounds."}})},
               {"anchor",
                Json::object(
                    {{"type", "array"},
                     {"items", Json::object({{"type", "number"}, {"minimum", -1}, {"maximum", 1}})},
                     {"minItems", 3},
                     {"maxItems", 3},
                     {"description",
                      "Where in the part's bounds the joint is, -1..1 around the centre. Default [0, 0, 0]."}})},
               {"tailAnchor",
                Json::object({{"type", "array"},
                              {"items", Json::object({{"type", "number"}, {"minimum", -1}, {"maximum", 1}})},
                              {"minItems", 3},
                              {"maxItems", 3},
                              {"description", "The same for the end of a bone with no children. Left out: the opposite "
                                              "side of the part from `anchor`."}})}})}});
    return Json::object(
        {{"$schema", "https://json-schema.org/draft/2020-12/schema"},
         {"$id", "https://factoria.dev/schemas/rig.schema.json"},
         {"title", "FactorIA rig document (*.rig.json)"},
         {"description",
          "A skeleton for a model document: a template (humanoid, quadruped, bird, tail, chain, generic) fitted to the "
          "model by its parts and landmarks. `rig.bake` writes the skinned .glb "
          "(joints, inverse bind matrices and the skin weights the `skin` section describes). Errors name the file and "
          "the JSON pointer; docs/RIGGING.md explains the format and `rig.templates {}` lists the templates."},
         {"type", "object"},
         {"required", Json::array({"format", "model", "template"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"$schema",
                Json::object({{"type", "string"}, {"description", "Optional schema reference for editors."}})},
               {"format", Json::object({{"const", kRigDocFormat},
                                        {"description",
                                         std::string("File format identifier. Always \"") + kRigDocFormat + "\"."}})},
               {"doc", Json::object({{"type", "string"}, {"description", "What the rig is for."}})},
               {"model",
                Json::object({{"type", "string"},
                              {"pattern", "\\.[mM][oO][dD][eE][lL]\\.[jJ][sS][oO][nN]$"},
                              {"description", "The model document it fits (project-relative, *.model.json)."}})},
               {"template",
                Json::object({{"enum", template_names()},
                              {"description", "Which skeleton: humanoid, quadruped, bird, tail, chain or generic."}})},
               {"options", Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"description", "Options of the template (rig.templates lists them); a key "
                                                         "the template does not have is an error."},
                                         {"properties", optionProps}})},
               {"parts", Json::object({{"type", "object"},
                                       {"description",
                                        "Bone name -> the model part(s) that decide where it is, when the names of the "
                                        "parts do not say so. A name that is not a part of the model is an error."},
                                       {"additionalProperties", partNames}})},
               {"landmarks",
                Json::object(
                    {{"type", "object"},
                     {"description",
                      "Explicit joint positions [x, y, z] in the model's space (after its gameReady origin), by bone "
                      "name; \"<bone>.tail\" is the end of a bone with no children. Wins over parts and proportions."},
                     {"additionalProperties", vec3}})},
               {"symmetryX",
                Json::object(
                    {{"type", "number"},
                     {"description",
                      "The x of the symmetry plane (left = +X of it). Default: the centre of the model's bounds."}})},
               {"strict", Json::object({{"type", "boolean"},
                                        {"description", "A landmark that could only be estimated from the template's "
                                                        "proportions is an error. Default false."}})},
               {"skin", rig_skin_schema()},
               {"output",
                Json::object(
                    {{"type", "object"},
                     {"additionalProperties", false},
                     {"description", "Where `rig.bake` writes the skinned .glb."},
                     {"properties",
                      Json::object(
                          {{"path", Json::object({{"type", "string"},
                                                  {"pattern", "\\.[gG][lL][bB]$"},
                                                  {"description",
                                                   "Project-relative file under assets/ ending in .glb. Left out: next "
                                                   "to the document, with .glb instead of .rig.json."}})}})}})},
               {"bones", Json::object({{"type", "array"},
                                       {"description", "generic template only: the bones, parents before children."},
                                       {"items", bone}})}})}});
}

}  // namespace fa
