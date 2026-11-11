// skin3d.*: the skin weights of a rig document (docs/RIGGING.md, "Skin weights"). The weights are never stored: the document's `skin` section holds the
// method per part and the list of edits, and every command here either changes that section (and bakes the .glb again) or looks at the weights the
// section gives. The weights themselves, their report and the posed bend are fa_scene's (fa/scene/rig_skin.h); the picture of skin3d.preview is the
// software view of model.preview (fa/tooling/model_view.h).
#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "assets_internal.h"
#include "assets_shots.h"
#include "fa/core/strings.h"
#include "fa/tooling/model_view.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/rig_bake.h"
#include "picture_canvas.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

namespace stdfs = std::filesystem;
using picture::Canvas;
using picture::Rgb;

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}
Json str(const char* what) { return Json::object({{"type", "string"}, {"description", what}}); }
Json boolean(const char* what, bool def) { return Json::object({{"type", "boolean"}, {"default", def}, {"description", what}}); }
// no "default" key: the registry fills schema defaults in and these must tell an argument that was not given
Json num(const char* what, double lo, double hi) { return Json::object({{"type", "number"}, {"minimum", lo}, {"maximum", hi}, {"description", what}}); }
Json integer(const char* what, double lo, double hi) { return Json::object({{"type", "integer"}, {"minimum", lo}, {"maximum", hi}, {"description", what}}); }
Json pathArg() { return str("The rig document, project-relative, under assets/, ending in .rig.json."); }

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}

double number_arg(const char* command, const Json& a, const char* key, double def, double lo, double hi, const char* hint) {
    if (!a.contains(key) || a[key].is_null()) return def;
    if (!a[key].is_number()) fail("invalid_argument", std::string(command) + ": `" + key + "` must be a number, got " + describe_json_value(a[key]) + ".", hint);
    const double v = a[key].get<double>();
    if (!(v >= lo && v <= hi)) fail("invalid_argument", std::format("{}: `{}` must be from {} to {}, got {}.", command, key, lo, hi, v), hint);
    return v;
}

std::string rig_path(const std::string& arg) {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", "`path` '" + arg + "' is not a rig document under assets/.", "Rig documents live in assets/, e.g. \"assets/models/hero.rig.json\" (rig.create writes one).");
    if (!ends_with(to_lower(*norm), kRigDocSuffix))
        fail("invalid_argument", "'" + *norm + "' does not end in .rig.json.", "Name rig documents <name>.rig.json, e.g. \"assets/models/hero.rig.json\".");
    return *norm;
}

Json issues_json(const std::vector<RigIssue>& issues) {
    Json list = Json::array();
    for (const RigIssue& i : issues) list.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return list;
}

[[noreturn]] void invalid_document(const std::string& rel, const Error& error, const std::vector<RigIssue>& issues) {
    throw CommandError("invalid_document", error.message, error.hint.empty() ? "schemas/rig.schema.json describes the format; rig.info {\"path\":...} lists every issue." : error.hint,
                       Json::object({{"path", rel}, {"issues", issues_json(issues)}}));
}

Json read_json_file(const std::string& projectDir, const std::string& rel) {
    auto text = tooling_detail::read_file(project_file(projectDir, rel));
    if (!text) {
        const std::vector<std::string> all = list_rig_documents(projectDir);
        fail("not_found", "'" + rel + "' does not exist.", all.empty() ? "Make one with rig.create {\"path\":\"" + rel + "\",\"model\":...,\"template\":...}." : did_you_mean(rel, all));
    }
    auto json = parse_json(*text, rel);
    if (!json.ok()) fail("invalid_document", json.error().message, json.error().hint.empty() ? "Fix the JSON syntax; schemas/rig.schema.json describes the format." : json.error().hint);
    return std::move(*json);
}

RigDoc checked(const Json& json, const std::string& rel) {
    std::vector<RigIssue> issues;
    auto doc = parse_rig_doc(json, rel, &issues);
    if (!doc.ok()) invalid_document(rel, doc.error(), issues);
    const std::vector<RigIssue> more = rig_check_doc(*doc);
    if (!more.empty()) invalid_document(rel, Error{rel + " " + more[0].pointer + ": " + more[0].message, more[0].hint}, more);
    return std::move(*doc);
}

void write_document(const std::string& projectDir, const std::string& rel, const Json& json) {
    std::string err;
    if (!tooling_detail::write_file(project_file(projectDir, rel), dump_json(json), &err)) fail("failed", "Cannot write '" + rel + "': " + err, "Check that the folder is writable.");
}

Json bake_json(const RigBakeStatus& s) { return Json::object({{"state", rig_bake_state_name(s.state)}, {"output", s.output}, {"reason", s.reason}}); }

struct Loaded {
    std::string rel;
    Json json;  // the document as the file has it, normalised through RigDoc
    RigDoc doc;
};
Loaded load(const std::string& projectDir, const Json& a) {
    Loaded l;
    l.rel = rig_path(tooling_detail::arg_string(a, "path", true));
    l.doc = checked(read_json_file(projectDir, l.rel), l.rel);
    l.json = rig_doc_to_json(l.doc);
    return l;
}

// The weights the document gives, or the reason they cannot be computed (nothing is written before this succeeds).
RigEvaluation evaluate_or_throw(const std::string& projectDir, const RigDoc& doc, const std::string& rel, const char* command) {
    auto eval = rig_evaluate(projectDir, doc, true);
    if (!eval.ok())
        throw CommandError("skin_failed", std::string(command) + ": " + eval.error().message,
                           eval.error().hint.empty() ? "rig.info {\"path\":\"" + rel + "\"} shows the fit and every issue of the document." : eval.error().hint, Json::object({{"path", rel}, {"written", false}}));
    return std::move(*eval);
}

Json edits_json(const RigSkinSettings& skin) {
    Json list = Json::array();
    for (std::size_t i = 0; i < skin.edits.size(); ++i) {
        Json e = rig_skin_edit_to_json(skin.edits[i]);
        e["index"] = i;
        list.push_back(e);
    }
    return list;
}

// The quality of the weights as the commands report it: the report of the skin plus how to read it.
Json quality_json(const RigSkinReport& r) {
    Json q = rig_skin_report_to_json(r);
    q["ok"] = r.unweighted == 0 && r.farBlends == 0 && r.warnings.empty();
    return q;
}

// Writes the new document, then bakes the .glb unless asked not to; the document stays written when the bake fails (the bake's own message says why).
void write_and_bake(const std::string& projectDir, const Loaded& l, const RigDoc& doc, const Json& args, Json& result, Json& steps) {
    require_usable_manifest(projectDir);
    write_document(projectDir, l.rel, rig_doc_to_json(doc));
    result["written"] = true;
    if (!tooling_detail::arg_bool(args, "bake", true)) {
        result["bake"] = bake_json(rig_bake_status(projectDir, l.rel));
        steps.push_back("rig.bake {\"path\":\"" + l.rel + "\"} writes the .glb with the new weights.");
        return;
    }
    auto b = bake_rig_document(projectDir, l.rel, {false, tooling_detail::arg_bool(args, "overwrite", false)});
    if (!b.ok()) {
        result["bake"] = Json::object({{"state", "failed"}, {"message", b.error().message}, {"hint", b.error().hint}});
        steps.push_back("The document was written but could not be baked: " + b.error().message + " " + b.error().hint);
        return;
    }
    result["bake"] = Json::object({{"state", "baked"}, {"output", b->output}, {"bytes", b->bytes}, {"sha256", b->sha256}});
}

void add_common_steps(const Loaded& l, const Json& result, Json& steps) {
    steps.push_back("skin3d.preview {\"path\":\"" + l.rel + "\",\"bone\":\"<bone>\"} draws the weights of one bone as a heat map; with \"pose\":{\"<bone>\":60} it bends the bone to show how the skin deforms.");
    if (result.contains("quality") && !result["quality"].value("ok", true))
        steps.push_back("`quality` has findings (unweighted vertices, far blends or warnings): read `warnings`; skin3d.smooth, skin3d.limit and rig.fit parts usually fix them.");
}

// ---- skin3d.info ----

Json skin3d_info_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("skin3d.info", a, "", {"path"});
    Loaded l = load(projectDir, a);
    RigEvaluation eval = evaluate_or_throw(projectDir, l.doc, l.rel, "skin3d.info");
    Json result = Json::object({{"path", l.rel}});
    const RigSkinSettings& s = l.doc.skin;
    result["skin"] = obj({{"method", s.method}, {"maxInfluences", s.maxInfluences}, {"smooth", s.smooth}, {"maxHops", s.maxHops}, {"locality", round_to(s.locality, 4)}});
    Json overrides = Json::object();
    for (const auto& [part, p] : s.parts) {
        Json o = Json::object();
        if (!p.method.empty()) o["method"] = p.method;
        if (!p.bone.empty()) o["bone"] = p.bone;
        overrides[part] = o;
    }
    result["skin"]["parts"] = overrides;
    result["edits"] = edits_json(s);
    Json bones = Json::array();
    for (const RigBoneFit& b : eval.fit.bones) {
        Json item = obj({{"name", b.name}, {"parent", b.parentIndex >= 0 ? Json(eval.fit.bones[std::size_t(b.parentIndex)].name) : Json()}});
        if (!b.parts.empty()) item["parts"] = b.parts;
        bones.push_back(item);
    }
    result["bones"] = bones;
    result["quality"] = quality_json(eval.skin.report);
    result["bake"] = bake_json(rig_bake_status(projectDir, l.rel));
    Json steps = Json::array();
    steps.push_back("skin3d.auto changes the method (auto, heat, voxel, rigid), globally or for one part; skin3d.set, add, smooth, normalize, limit and mirror append edits to the document.");
    add_common_steps(l, result, steps);
    result["nextSteps"] = steps;
    return result;
}

// ---- skin3d.auto ----

Json skin3d_auto_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("skin3d.auto", a, "", {"path", "method", "part", "bone", "maxInfluences", "smooth", "maxHops", "locality", "clearEdits", "dryRun", "bake", "overwrite"});
    Loaded l = load(projectDir, a);
    Json& skin = l.json["skin"];
    if (!skin.is_object()) skin = Json::object();
    Json changes = Json::array();
    std::string part;
    if (a.contains("part") && !a["part"].is_null()) {
        if (!a["part"].is_string()) fail("invalid_argument", "skin3d.auto: `part` must be text, got " + describe_json_value(a["part"]) + ".", "A part name of the model, e.g. \"torso\".");
        part = a["part"].get<std::string>();
    }
    if (part.empty() && a.contains("bone")) fail("invalid_argument", "skin3d.auto: `bone` needs `part`: it is the bone that part follows.", "Example: {\"part\":\"sleeve\",\"method\":\"rigid\",\"bone\":\"arm_upper_l\"}.");
    if (a.contains("method") && !a["method"].is_null()) {
        if (!a["method"].is_string()) fail("invalid_argument", "skin3d.auto: `method` must be text, got " + describe_json_value(a["method"]) + ".", "One of auto, heat, voxel, rigid.");
        const std::string method = a["method"].get<std::string>();
        if (part.empty()) {
            skin["method"] = method;
            changes.push_back("method");
        } else {
            Json& parts = skin["parts"];
            if (!parts.is_object()) parts = Json::object();
            Json entry = parts.contains(part) && parts[part].is_object() ? parts[part] : Json::object();
            entry["method"] = method;
            if (a.contains("bone") && a["bone"].is_string()) entry["bone"] = a["bone"];
            parts[part] = entry;
            changes.push_back("parts." + part);
        }
    } else if (!part.empty()) {
        // no method: `bone` alone moves the part's bone; neither removes the part's override
        Json& parts = skin["parts"];
        if (!parts.is_object()) parts = Json::object();
        if (a.contains("bone") && a["bone"].is_string()) {
            Json entry = parts.contains(part) && parts[part].is_object() ? parts[part] : Json::object();
            entry["bone"] = a["bone"];
            parts[part] = entry;
        } else {
            parts.erase(part);
        }
        if (parts.empty()) skin.erase("parts");
        changes.push_back("parts." + part);
    }
    for (const char* key : {"maxInfluences", "smooth", "maxHops", "locality"}) {
        if (!a.contains(key) || a[key].is_null()) continue;
        if (!a[key].is_number()) fail("invalid_argument", std::string("skin3d.auto: `") + key + "` must be a number, got " + describe_json_value(a[key]) + ".", "See the input schema for the range.");
        skin[key] = a[key];
        changes.push_back(key);
    }
    if (tooling_detail::arg_bool(a, "clearEdits", false)) {
        skin.erase("edits");
        changes.push_back("edits");
    }
    const RigDoc doc = checked(l.json, l.rel);
    RigEvaluation eval = evaluate_or_throw(projectDir, doc, l.rel, "skin3d.auto");
    Json result = Json::object({{"path", l.rel}, {"changed", changes}, {"written", false}});
    Json steps = Json::array();
    if (!changes.empty() && !tooling_detail::arg_bool(a, "dryRun", false)) {
        l.doc = doc;
        write_and_bake(projectDir, l, doc, a, result, steps);
    } else {
        result["bake"] = bake_json(rig_bake_status(projectDir, l.rel));
        if (changes.empty()) steps.push_back("Nothing was changed: pass `method` (auto, heat, voxel, rigid), `part` and `bone`, `smooth`, `maxInfluences`, `maxHops` or `locality`.");
    }
    result["quality"] = quality_json(eval.skin.report);
    result["skin"] = rig_skin_to_json(doc.skin).is_null() ? Json::object() : rig_skin_to_json(doc.skin);
    add_common_steps(l, result, steps);
    result["nextSteps"] = steps;
    return result;
}

// ---- skin3d.set / add / smooth / normalize / limit / mirror ----

// Adds an edit to the document, checks that the weights can be computed with it (nothing is written otherwise) and bakes.
Json edit_command(const std::string& projectDir, const char* command, const char* op, const Json& a) {
    Loaded l = load(projectDir, a);
    Json edit = Json::object({{"op", op}});
    for (const char* key : {"bone", "weight", "amount", "iterations", "strength", "threshold", "max", "from"})
        if (a.contains(key) && !a[key].is_null()) edit[key] = a[key];
    if (a.contains("part") && !a["part"].is_null()) edit["part"] = a["part"];
    if (a.contains("select") && !a["select"].is_null()) {
        if (!a["select"].is_object()) fail("invalid_argument", std::string(command) + ": `select` must be a face query object, got " + describe_json_value(a["select"]) + ".", "Example: {\"by\":\"box\",\"min\":[0,1,-1],\"max\":[1,2,1]} (model.select_info lists the queries).");
        edit["select"] = a["select"];
    }
    Json& skin = l.json["skin"];
    if (!skin.is_object()) skin = Json::object();
    if (!skin.contains("edits") || !skin["edits"].is_array()) skin["edits"] = Json::array();
    skin["edits"].push_back(edit);
    const std::size_t index = skin["edits"].size() - 1;
    const RigDoc doc = checked(l.json, l.rel);
    // the weights before the edit, to say what it changed
    RigEvaluation before;
    {
        RigDoc without = doc;
        without.skin.edits.pop_back();
        before = evaluate_or_throw(projectDir, without, l.rel, command);
    }
    RigEvaluation eval = evaluate_or_throw(projectDir, doc, l.rel, command);
    std::size_t changed = 0;
    const RigWeights& wa = before.skin.weights;
    const RigWeights& wb = eval.skin.weights;
    if (wa.joints.size() == wb.joints.size())
        for (std::size_t v = 0; v < wa.vertex_count(); ++v) {
            bool differs = false;
            for (int k = 0; k < 4 && !differs; ++k) differs = wa.joints[v * 4 + k] != wb.joints[v * 4 + k] || wa.weights[v * 4 + k] != wb.weights[v * 4 + k];
            if (differs) ++changed;
        }
    Json result = Json::object({{"path", l.rel}, {"edit", rig_skin_edit_to_json(doc.skin.edits.back())}, {"index", index}, {"verticesChanged", changed}, {"written", false}});
    Json steps = Json::array();
    if (!tooling_detail::arg_bool(a, "dryRun", false)) {
        write_and_bake(projectDir, l, doc, a, result, steps);
    } else {
        result["bake"] = bake_json(rig_bake_status(projectDir, l.rel));
    }
    if (changed == 0) steps.push_back("The edit changed no vertex: check `part` and `select` (model.select_info shows what a query matches) and that the bone is one the vertices already follow.");
    result["quality"] = quality_json(eval.skin.report);
    steps.push_back("skin3d.clear {\"path\":\"" + l.rel + "\",\"index\":" + std::to_string(index) + "} removes this edit.");
    add_common_steps(l, result, steps);
    result["nextSteps"] = steps;
    return result;
}

// ---- skin3d.clear ----

Json skin3d_clear_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("skin3d.clear", a, "", {"path", "index", "dryRun", "bake", "overwrite"});
    Loaded l = load(projectDir, a);
    Json& skin = l.json["skin"];
    Json removed = Json::array();
    if (skin.is_object() && skin.contains("edits") && skin["edits"].is_array()) {
        Json& edits = skin["edits"];
        if (a.contains("index") && !a["index"].is_null()) {
            const double v = number_arg("skin3d.clear", a, "index", 0, 0, 1e6, "The index of an edit, as skin3d.info lists them.");
            if (v != std::floor(v) || std::size_t(v) >= edits.size())
                fail("invalid_argument", std::format("skin3d.clear: `index` {} is not an edit of {} (the document has {} edit(s)).", v, l.rel, edits.size()),
                     edits.empty() ? "The document has no edits." : "Use 0 to " + std::to_string(edits.size() - 1) + "; skin3d.info lists them.");
            removed.push_back(edits[std::size_t(v)]);
            edits.erase(edits.begin() + std::ptrdiff_t(v));
        } else {
            for (const Json& e : edits) removed.push_back(e);
            edits = Json::array();
        }
        if (edits.empty()) skin.erase("edits");
    }
    const RigDoc doc = checked(l.json, l.rel);
    RigEvaluation eval = evaluate_or_throw(projectDir, doc, l.rel, "skin3d.clear");
    Json result = Json::object({{"path", l.rel}, {"removed", removed}, {"written", false}});
    Json steps = Json::array();
    if (!removed.empty() && !tooling_detail::arg_bool(a, "dryRun", false)) {
        write_and_bake(projectDir, l, doc, a, result, steps);
    } else {
        result["bake"] = bake_json(rig_bake_status(projectDir, l.rel));
        if (removed.empty()) steps.push_back("The document has no edits to remove.");
    }
    result["remaining"] = edits_json(doc.skin);
    result["quality"] = quality_json(eval.skin.report);
    result["nextSteps"] = steps;
    return result;
}

// ---- skin3d.preview ----

// Heat-map colour of a weight: blue (0) through cyan, green and yellow to red (1).
void heat_color(float w, float out[3]) {
    w = std::clamp(w, 0.0f, 1.0f);
    const float stops[5][3] = {{0.05f, 0.08f, 0.55f}, {0.0f, 0.75f, 0.85f}, {0.1f, 0.8f, 0.2f}, {0.95f, 0.9f, 0.1f}, {0.95f, 0.15f, 0.1f}};
    const float t = w * 4.0f;
    const int i = std::min(int(t), 3);
    const float f = t - float(i);
    for (int c = 0; c < 3; ++c) out[c] = stops[i][c] + (stops[i + 1][c] - stops[i][c]) * f;
}

// A colour per bone: hues spread by the golden ratio so neighbours in the list differ.
void bone_color(std::size_t bone, float out[3]) {
    const float h = std::fmod(float(bone) * 0.61803398875f + 0.08f, 1.0f) * 6.0f;
    const float s = (bone % 2 == 0) ? 0.75f : 0.55f, v = (bone % 3 == 0) ? 0.95f : 0.8f;
    const int i = int(h);
    const float f = h - float(i), p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f));
    const float table[6][3] = {{v, t, p}, {q, v, p}, {p, v, t}, {p, q, v}, {t, p, v}, {v, p, q}};
    for (int c = 0; c < 3; ++c) out[c] = table[i % 6][c];
}

constexpr int kHeader = 52, kPad = 8;

std::vector<RigBonePose> poses_arg(const Json& a, const RigFit& fit) {
    std::vector<RigBonePose> out;
    if (!a.contains("pose") || a["pose"].is_null()) return out;
    std::vector<std::string> names;
    for (const RigBoneFit& b : fit.bones) names.push_back(b.name);
    auto bone_index = [&](const std::string& name, const std::string& where) {
        for (std::size_t i = 0; i < names.size(); ++i)
            if (names[i] == name) return int(i);
        fail("invalid_argument", "skin3d.preview: " + where + " names the bone \"" + name + "\", which the rig does not have.", did_you_mean(name, names));
    };
    auto angle = [&](const Json& v, const std::string& where) {
        if (!v.is_number() || !(v.get<double>() >= -180 && v.get<double>() <= 180))
            fail("invalid_argument", "skin3d.preview: " + where + " must be an angle in degrees from -180 to 180, got " + describe_json_value(v) + ".", "Example: {\"arm_lower_l\":60}.");
        return float(v.get<double>());
    };
    const Json& p = a["pose"];
    if (p.is_object()) {
        for (auto it = p.begin(); it != p.end(); ++it) {
            RigBonePose bp;
            bp.bone = bone_index(it.key(), "`pose`");
            bp.degrees = angle(it.value(), "`pose`." + it.key());
            out.push_back(bp);
        }
    } else if (p.is_array()) {
        for (std::size_t i = 0; i < p.size(); ++i) {
            const std::string where = "`pose`[" + std::to_string(i) + "]";
            const Json& e = p[i];
            if (!e.is_object() || !e.contains("bone") || !e["bone"].is_string() || !e.contains("degrees"))
                fail("invalid_argument", "skin3d.preview: " + where + " must be {\"bone\":name,\"degrees\":angle,\"axis\":[x,y,z]}.", "Example: [{\"bone\":\"arm_lower_l\",\"degrees\":60}].");
            RigBonePose bp;
            bp.bone = bone_index(e["bone"].get<std::string>(), where);
            bp.degrees = angle(e["degrees"], where + ".degrees");
            if (e.contains("axis")) {
                if (!e["axis"].is_array() || e["axis"].size() != 3 || !e["axis"][0].is_number() || !e["axis"][1].is_number() || !e["axis"][2].is_number())
                    fail("invalid_argument", "skin3d.preview: " + where + ".axis must be [x,y,z].", "Leave `axis` out to bend perpendicular to the bone (knee and elbow).");
                bp.axis = {float(e["axis"][0].get<double>()), float(e["axis"][1].get<double>()), float(e["axis"][2].get<double>())};
            }
            out.push_back(bp);
        }
    } else {
        fail("invalid_argument", "skin3d.preview: `pose` must be an object {bone: degrees} or a list of {bone, degrees, axis}, got " + describe_json_value(p) + ".", "Example: {\"arm_lower_l\":60}.");
    }
    return out;
}

Json skin3d_preview_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("skin3d.preview", a, "", {"path", "bone", "mode", "pose", "views", "yaw", "pitch", "cell", "out", "overwrite"});
    const std::string rel = rig_path(tooling_detail::arg_string(a, "path", true));
    const int views = int(number_arg("skin3d.preview", a, "views", 3, 1, 6, "How many sides to draw, 1 to 6, evenly spaced around the model."));
    if (a.contains("views") && a["views"].is_number() && a["views"].get<double>() != std::floor(a["views"].get<double>()))
        fail("invalid_argument", "skin3d.preview: `views` must be a whole number from 1 to 6.", "Example: 3.");
    const double yaw = number_arg("skin3d.preview", a, "yaw", 20, -360, 360, "The angle of the first view in degrees: 0 looks at the model's +Z side.");
    const double pitch = number_arg("skin3d.preview", a, "pitch", 12, -80, 80, "Degrees above the horizon.");
    const int cell = int(number_arg("skin3d.preview", a, "cell", 280, 96, 640, "Pixels per side of each view."));
    std::string outRel;
    if (a.contains("out") && !a["out"].is_null()) {
        auto norm = a["out"].is_string() ? fs::normalize_checked(a["out"].get<std::string>()) : Result<std::string>(Error{"not a string", ""});
        if (!norm.ok() || norm->empty() || to_lower(fs::extension(*norm)) != ".png")
            fail("invalid_argument", "skin3d.preview: `out` must be a project-relative path ending in .png.", "Example: \"docs/review/hero-weights.png\". Leave it out to only look at the picture.");
        outRel = *norm;
        std::error_code ec;
        if (!tooling_detail::arg_bool(a, "overwrite", false) && stdfs::exists(project_file(projectDir, outRel), ec))
            fail("exists", "'" + outRel + "' already exists.", "Pass overwrite: true to replace it, or choose another `out`.");
    }

    // the document's weights with the document's own edits
    const RigDoc doc = checked(read_json_file(projectDir, rel), rel);
    RigEvaluation eval = evaluate_or_throw(projectDir, doc, rel, "skin3d.preview");
    const RigFit& fit = eval.fit;
    const RigWeights& weights = eval.skin.weights;
    std::vector<std::string> boneNames;
    for (const RigBoneFit& b : fit.bones) boneNames.push_back(b.name);

    int boneIndex = -1;
    if (a.contains("bone") && !a["bone"].is_null()) {
        if (!a["bone"].is_string()) fail("invalid_argument", "skin3d.preview: `bone` must be text, got " + describe_json_value(a["bone"]) + ".", "A bone name of the rig, e.g. \"arm_lower_l\".");
        const std::string name = a["bone"].get<std::string>();
        for (std::size_t i = 0; i < boneNames.size(); ++i)
            if (boneNames[i] == name) boneIndex = int(i);
        if (boneIndex < 0) fail("invalid_argument", "skin3d.preview: the rig has no bone \"" + name + "\".", did_you_mean(name, boneNames) + " Bones: " + join(boneNames, ", ") + ".");
    }
    std::string mode = boneIndex >= 0 ? "heat" : "bones";
    if (a.contains("mode") && !a["mode"].is_null()) {
        const std::vector<std::string> modes = {"heat", "bones"};
        if (!a["mode"].is_string() || std::find(modes.begin(), modes.end(), a["mode"].get<std::string>()) == modes.end())
            fail("invalid_argument", "skin3d.preview: `mode` is " + describe_json_value(a["mode"]) + ", not one of heat, bones.",
                 a["mode"].is_string() ? did_you_mean(a["mode"].get<std::string>(), modes) : "heat: the weights of `bone` as a heat map; bones: one colour per bone.");
        mode = a["mode"].get<std::string>();
    }
    if (mode == "heat" && boneIndex < 0) fail("invalid_argument", "skin3d.preview: mode \"heat\" draws the weights of one bone: give `bone`.", "Bones: " + join(boneNames, ", ") + ". Leave `mode` out for one colour per bone.");
    const std::vector<RigBonePose> poses = poses_arg(a, fit);

    // the model with its materials set aside and a colour per vertex from its weights
    MeshData colored = eval.mesh;
    for (MeshSubmesh& sm : colored.submeshes) {
        sm.material.color = Color{1, 1, 1, 1};
        sm.material.emissive = Color{0, 0, 0, 1};
        sm.material.texture.clear();
    }
    const std::size_t vc = colored.vertex_count();
    colored.colors.assign(vc * 4, 1.0f);
    float boneRgb[64][3];
    for (std::size_t b = 0; b < fit.bones.size() && b < 64; ++b) bone_color(b, boneRgb[b]);
    std::size_t covered = 0, strong = 0;
    double sum = 0;
    float peak = 0;
    for (std::size_t v = 0; v < vc && v < weights.vertex_count(); ++v) {
        float rgb[3] = {0, 0, 0};
        float onBone = 0;
        for (int k = 0; k < 4; ++k) {
            const float w = weights.weights[v * 4 + k];
            const std::size_t j = weights.joints[v * 4 + k];
            if (w <= 0 || j >= fit.bones.size()) continue;
            if (int(j) == boneIndex) onBone += w;
            for (int c = 0; c < 3; ++c) rgb[c] += boneRgb[j][c] * w;
        }
        if (mode == "heat") heat_color(onBone, rgb);
        if (onBone > 0) {
            ++covered;
            sum += onBone;
            peak = std::max(peak, onBone);
        }
        if (onBone >= 0.5f) ++strong;
        for (int c = 0; c < 3; ++c) colored.colors[v * 4 + c] = rgb[c];
    }
    std::vector<float> posedPositions;
    MeshData posed;
    if (!poses.empty()) {
        posedPositions = rig_skin_pose(fit, weights, eval.mesh.positions, poses);
        posed = colored;
        posed.positions = posedPositions;
    }

    ModelViewItem restItem;
    restItem.mesh = &colored;
    ModelViewItem posedItem;
    posedItem.mesh = &posed;
    std::vector<ModelViewItem> framing = {restItem};
    if (!poses.empty()) framing.push_back(posedItem);
    const ModelViewFrame frame = frame_model_items(framing);

    // the legend: the bones that lead some vertex (one colour per bone) or the ramp (one bone)
    std::vector<std::size_t> legend;
    if (mode == "bones")
        for (std::size_t b = 0; b < eval.skin.report.boneVertices.size(); ++b)
            if (eval.skin.report.boneVertices[b].second > 0) legend.push_back(b);
    const int columns = views;
    const int rows = poses.empty() ? 1 : 2;
    const int width = std::max(columns * cell + (columns + 1) * kPad, 560);
    const int perRow = std::max(1, (width - 2 * kPad) / 150);
    const int legendRows = mode == "bones" ? int((legend.size() + std::size_t(perRow) - 1) / std::size_t(perRow)) : 0;
    const int legendHeight = legendRows * 16 + (legendRows ? 6 : 0);
    const int height = kHeader + legendHeight + rows * (cell + 20) + (rows + 1) * kPad;
    Canvas canvas(width, height, {22, 24, 28});

    canvas.text(rel, kPad + 2, 6, 17, {235, 238, 245});
    std::string what = mode == "heat" ? "weights of " + boneNames[std::size_t(boneIndex)] + ": blue 0, green .5, red 1" : "one colour per bone, mixed where bones share a vertex";
    canvas.text(std::format("{} vertices   {} bones   {}   {} edit(s)", eval.skin.report.vertices, fit.bones.size(), what, doc.skin.edits.size()), kPad + 2, 28, 13, {185, 192, 204});
    if (mode == "heat")
        for (int i = 0; i < 120; ++i) {
            float rgb[3];
            heat_color(float(i) / 119.0f, rgb);
            canvas.rect(width - kPad - 120 + i, 8, width - kPad - 120 + i, 20, {std::uint8_t(rgb[0] * 255), std::uint8_t(rgb[1] * 255), std::uint8_t(rgb[2] * 255)});
        }
    for (std::size_t i = 0; i < legend.size(); ++i) {
        const int x = kPad + int(i % std::size_t(perRow)) * 150, y = kHeader + int(i / std::size_t(perRow)) * 16;
        const float* c = boneRgb[std::min<std::size_t>(legend[i], 63)];
        canvas.rect(x, y, x + 11, y + 11, {std::uint8_t(c[0] * 255), std::uint8_t(c[1] * 255), std::uint8_t(c[2] * 255)});
        canvas.text(boneNames[legend[i]], x + 16, y + 6, 11, {200, 206, 216}, 0, true);
    }

    ModelViewOptions vo;
    vo.width = vo.height = cell;
    vo.pitchDeg = pitch;
    vo.ground = true;
    vo.center = frame.center;
    vo.radius = frame.radius;
    vo.supersample = cell > 480 ? 1 : 2;
    std::string poseLabel;
    for (const RigBonePose& p : poses) poseLabel += (poseLabel.empty() ? "" : ", ") + boneNames[std::size_t(p.bone)] + std::format(" {:.0f} deg", p.degrees);
    Json viewList = Json::array();
    for (int r = 0; r < rows; ++r)
        for (int i = 0; i < views; ++i) {
            vo.yawDeg = yaw + 360.0 * i / views;
            std::vector<ModelViewItem> items = {r == 0 ? restItem : posedItem};
            const Image cellImage = render_model_view(items, vo);
            const int x = kPad + i * (cell + kPad), y = kHeader + legendHeight + kPad + r * (cell + 20 + kPad);
            draw_over(canvas.img, cellImage, x, y);
            canvas.rect(x, y + cell, x + cell - 1, y + cell + 19, {30, 33, 39});
            const double shown = std::fmod(std::fmod(vo.yawDeg, 360.0) + 360.0, 360.0);
            canvas.text(std::format("{}  yaw {:.0f}", r == 0 ? "rest" : "posed: " + poseLabel, shown), x + 6, y + cell + 10, 11, {170, 178, 190}, 0, true);
            if (r == 0) viewList.push_back(obj({{"yaw", round_to(shown, 2)}, {"pitch", pitch}}));
        }

    Json result = Json::object({{"path", rel}, {"mode", mode}});
    if (boneIndex >= 0) {
        result["bone"] = boneNames[std::size_t(boneIndex)];
        result["boneWeights"] = obj({{"verticesWithWeight", covered}, {"verticesAboveHalf", strong}, {"max", round_to(peak, 4)}, {"mean", covered ? round_to(sum / double(covered), 4) : 0.0}});
    }
    if (!poses.empty()) {
        Json pj = Json::array();
        for (const RigBonePose& p : poses) pj.push_back(obj({{"bone", boneNames[std::size_t(p.bone)]}, {"degrees", p.degrees}}));
        result["pose"] = pj;
    }
    result["quality"] = quality_json(eval.skin.report);
    result["views"] = viewList;
    result["picture"] = obj({{"width", canvas.img.width}, {"height", canvas.img.height}, {"cell", cell}, {"columns", columns}, {"rows", rows}});
    if (!outRel.empty()) {
        const std::vector<std::uint8_t> png = encode_png(canvas.img);
        std::string err;
        const stdfs::path out = project_file(projectDir, outRel);
        if (!tooling_detail::write_file(out, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err)) fail("failed", err);
        result["written"] = outRel;
        result["$image"] = image_member(out, false);
    } else {
        result["$image"] = image_member(write_temporary_picture(projectDir, canvas.img, "skin3d"), true);
    }
    Json steps = Json::array();
    steps.push_back(mode == "heat" ? "Read the heat map: red where the bone is the only influence, blue where it has none. A bone's weights should fall off smoothly into its neighbours; red on the wrong limb means the parts are not matched (rig.fit `parts`)."
                                   : "Read the colours: each bone has one; a blend of two colours is a vertex shared by two bones. A limb in the wrong colour follows the wrong bone: skin3d.set fixes a part or a selection.");
    if (poses.empty()) steps.push_back("Pass \"pose\":{\"<bone>\":60} to bend a bone and see the skin deform under the rest pose.");
    else steps.push_back("The lower row is the model bent as the .glb would bend it (linear blend skinning); creases or stretched triangles at a joint call for skin3d.smooth or a different method for that part.");
    result["nextSteps"] = steps;
    return result;
}

Json args_of(const Json& args) { return args.is_null() ? Json::object() : args; }

Json part_prop() {
    return Json::object({{"oneOf", Json::array({Json{{"type", "string"}}, Json{{"type", "array"}, {"items", Json{{"type", "string"}}}, {"minItems", 1}}})},
                         {"description", "The model part (or list of parts) the edit works on. Combined with `select`: the vertices in both. Left out with no `select`: every vertex."}});
}
Json select_prop() {
    return Json::object({{"type", "object"}, {"description", "A face query of the model document ({\"by\":\"box\",\"min\":[x,y,z],\"max\":[x,y,z]}; model.select_info lists them: box, sphere, halfspace, part, normal, and, or, not...): the edit works on the vertices of the faces it matches."}});
}

void add_edit_command(CommandRegistry& registry, const std::string& projectDir, const char* name, const char* op, const char* summary, const char* description, Json extra, std::vector<const char*> required) {
    CommandInfo info;
    info.name = name;
    info.category = "assets";
    info.readOnly = false;
    info.summary = summary;
    info.description = description;
    Json props = obj({{"path", pathArg()},
                      {"part", part_prop()},
                      {"select", select_prop()},
                      {"dryRun", boolean("Compute the weights with the edit and report, but write nothing.", false)},
                      {"bake", boolean("Bake the skinned .glb after writing.", true)},
                      {"overwrite", boolean("Replace a .glb that no rig document baked.", false)}});
    for (auto it = extra.begin(); it != extra.end(); ++it) props[it.key()] = it.value();
    Json req = Json::array({"path"});
    for (const char* r : required) req.push_back(r);
    info.inputSchema = Json::object({{"type", "object"}, {"required", req}, {"additionalProperties", false}, {"properties", props}});
    std::vector<std::string> keys = {"path", "part", "select", "dryRun", "bake", "overwrite"};
    for (auto it = extra.begin(); it != extra.end(); ++it) keys.push_back(it.key());
    const std::string command = name;
    const std::string opName = op;
    registry.add(info, [projectDir, command, opName, keys](const Json& args) {
        Json a = args_of(args);
        check_arg_keys(command.c_str(), a, "", std::vector<std::string>(keys));
        return edit_command(projectDir, command.c_str(), opName.c_str(), a);
    });
}

}  // namespace

void register_skin3d_commands(CommandRegistry& registry, const std::string& projectDir) {
    static const char* const kScope =
        " The vertices it works on are those of `part` and of the faces `select` matches (both given: the vertices in both; neither: every vertex); `select` is a face query of the model document "
        "(model.select_info). The edit is appended to the rig document's `skin.edits` (applied in order after the automatic weights, so it survives a re-bake), the weights are computed with it before anything is written "
        "(a bone or part that does not exist fails with a \"did you mean\" and writes nothing), and unless bake is false the skinned .glb is baked again. The answer has the edit, its `index`, how many vertices it changed "
        "(`verticesChanged`) and the `quality` of the weights (vertices without weight, most influences, blends across far bones, bones that lead no vertex, warnings). dryRun reports without writing.";
    {
        CommandInfo info;
        info.name = "skin3d.info";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Show a rig document's skin: the method, its settings and edits, the bones with the parts they follow, and the quality of the weights it gives.";
        info.description =
            "Reads `path` (*.rig.json), fits the rig and computes the weights of its `skin` section. Returns the effective settings (`skin`: method, maxInfluences, smooth, maxHops, locality and the per-part overrides), the `edits` with their index (skin3d.clear removes one), "
            "the `bones` with their parent and the model parts each follows, the `quality` of the weights and the state of the baked .glb. `quality` counts vertices without weight (`unweighted`: they follow the nearest bone), the most influences any vertex has, "
            "`farBlends` (vertices blending bones more than `maxHops` apart in the hierarchy), the vertices led by each bone (`boneVertices`; `idleBones` lead none), the method used per part, the heat solver's pieces and the `warnings` (each says what to change). Nothing is written. "
            "Example: {\"path\":\"assets/models/hero.rig.json\"}";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false}, {"properties", obj({{"path", pathArg()}})}});
        registry.add(info, [projectDir](const Json& args) { return skin3d_info_command(projectDir, args_of(args)); });
    }
    {
        CommandInfo info;
        info.name = "skin3d.auto";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Choose how the weights are computed (auto, heat, voxel, rigid), for the whole rig or one part, and their settings; recompute and bake.";
        info.description =
            "Changes the `skin` section of a rig document. `method`: auto (heat diffusion; a generic rig, whose bones were placed on parts, is rigid per part), heat (bone heat diffusion on the surface: smooth weights that follow the shape; works on the meshes the engine makes, "
            "SDF creatures included), voxel (distance along a voxelised copy of the surface: needs no manifold mesh; what a part falls back to when the heat solve cannot converge) or rigid (the whole part follows ONE bone: robot style). "
            "With `part` the method is that part's only (`bone` is the bone it follows: rigid = the one bone, heat and voxel = the bone the part is centred on; without `method` and `bone` the part's override is removed). Settings: `maxInfluences` (1 to 4 bones per vertex), "
            "`smooth` (passes over the automatic weights, 0 to 8), `maxHops` (a vertex never follows bones further than this many bones from its strongest, 1 to 8) and `locality` (heat: higher hugs each bone, 0.05 to 20). `clearEdits` also removes every edit. "
            "The weights are computed before anything is written (a bad part or bone fails and writes nothing), the .glb is baked again unless bake is false, and the answer has the `quality` of the weights. "
            "Examples: {\"path\":\"assets/models/robot.rig.json\",\"part\":\"claw\",\"method\":\"rigid\",\"bone\":\"arm_lower_l\"}, {\"path\":\"assets/models/hero.rig.json\",\"smooth\":3,\"locality\":1.5}";
        info.inputSchema = Json::object(
            {{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
             {"properties", obj({{"path", pathArg()},
                                 {"method", Json::object({{"type", "string"}, {"enum", Json::array({"auto", "heat", "voxel", "rigid"})}, {"description", "The method: for every part, or for `part` when given."}})},
                                 {"part", str("A model part to give its own method (and bone). Without `method` and `bone` its override is removed.")},
                                 {"bone", str("With `part`: the bone the part follows (rigid) or is centred on (heat, voxel).")},
                                 {"maxInfluences", integer("Bones per vertex, 1 to 4.", 1, 4)},
                                 {"smooth", integer("Smoothing passes over the automatic weights, 0 to 8.", 0, 8)},
                                 {"maxHops", integer("A vertex does not follow bones further than this many bones from its strongest one, 1 to 8.", 1, 8)},
                                 {"locality", num("Heat diffusion: higher = weights hug each bone (shorter blends), lower = longer blends. 0.05 to 20 (default 1).", 0.05, 20)},
                                 {"clearEdits", boolean("Also remove every edit (skin.edits).", false)},
                                 {"dryRun", boolean("Compute the weights with the change and report, but write nothing.", false)},
                                 {"bake", boolean("Bake the skinned .glb after writing.", true)},
                                 {"overwrite", boolean("Replace a .glb that no rig document baked.", false)}})}});
        registry.add(info, [projectDir](const Json& args) { return skin3d_auto_command(projectDir, args_of(args)); });
    }
    add_edit_command(registry, projectDir, "skin3d.set", "set", "Give a bone an exact weight on the vertices of a part or a selection; the other bones share the rest.",
                     (std::string("Sets the weight of `bone` to `weight` (0 to 1; default 1: the vertices follow only that bone) and scales the other influences of each vertex to share what is left in their proportions. A vertex whose only influence was "
                                  "the bone keeps it at 1. Use it to pin a hand to its bone, a sleeve to an arm or free a vertex from a bone (weight 0).") + kScope + " Example: {\"path\":\"assets/models/hero.rig.json\",\"bone\":\"hand_l\",\"weight\":1,\"part\":\"glove_l\"}").c_str(),
                     obj({{"bone", str("The bone whose weight is set.")}, {"weight", num("The weight it gets, 0 to 1 (default 1).", 0, 1)}}), {"bone"});
    add_edit_command(registry, projectDir, "skin3d.add", "add", "Add weight to a bone (or take it away with a negative amount) on the vertices of a part or a selection.",
                     (std::string("Adds `amount` (-1 to 1) to the weight of `bone` on each vertex, then normalises (a vertex keeps at most the document's `maxInfluences` strongest bones, the others are dropped). A positive amount makes the bone pull the vertices harder, "
                                  "a negative one releases them from it. Example: {\"path\":\"assets/models/hero.rig.json\",\"bone\":\"spine_2\",\"amount\":0.3,\"select\":{\"by\":\"box\",\"min\":[-0.3,1.2,-0.2],\"max\":[0.3,1.4,0.2]}}.") + kScope).c_str(),
                     obj({{"bone", str("The bone whose weight changes.")}, {"amount", num("Added to the bone's weight, -1 to 1.", -1, 1)}}), {"bone", "amount"});
    add_edit_command(registry, projectDir, "skin3d.smooth", "smooth", "Smooth the weights over the surface on the vertices of a part or a selection, to soften a crease at a joint.",
                     (std::string("Moves the weights of each vertex towards the average of the vertices that share an edge with it (welded by position, so seams do not break it): `iterations` passes of `strength` (0 to 1). The neighbours outside the selection "
                                  "take part, so the border blends in. Example: {\"path\":\"assets/models/hero.rig.json\",\"part\":\"arm_lower_l\",\"iterations\":3}.") + kScope).c_str(),
                     obj({{"iterations", integer("Passes, 1 to 50 (default 1).", 1, 50)}, {"strength", num("How far each pass moves a vertex to its neighbours' average, 0 to 1 (default 0.5).", 0, 1)}}), {});
    add_edit_command(registry, projectDir, "skin3d.normalize", "normalize", "Drop negligible influences and make each vertex's weights sum to 1, on a part or a selection.",
                     (std::string("Removes the influences under `threshold` (0 to 0.5, default 0.01) and rescales what is left to sum to 1. A vertex whose weights are all under the threshold keeps its strongest bone. "
                                  "Example: {\"path\":\"assets/models/hero.rig.json\",\"threshold\":0.05}.") + kScope).c_str(),
                     obj({{"threshold", num("Influences under this weight are dropped, 0 to 0.5 (default 0.01).", 0, 0.5)}}), {});
    add_edit_command(registry, projectDir, "skin3d.limit", "limit", "Keep at most N influences per vertex (1 to 4) on a part or a selection, strongest first, and normalise.",
                     (std::string("Keeps the `max` strongest bones of each vertex (1 to 4, default 4) and renormalises. max 1 makes the selection rigid per vertex. Example: {\"path\":\"assets/models/hero.rig.json\",\"max\":2,\"part\":\"hand_l\"}.") + kScope).c_str(),
                     obj({{"max", integer("Influences kept per vertex, 1 to 4 (default 4).", 1, 4)}}), {});
    add_edit_command(registry, projectDir, "skin3d.mirror", "mirror", "Copy the weights of one side of the character to the other (_l to _r or the other way), pairing each vertex with its mirror image.",
                     (std::string("Copies the weights from the side `from` (\"l\" = the character's left, +X; \"r\" = "
                         "right) to the opposite side: each vertex is paired with the vertex nearest to its "
                         "mirror image across the symmetry plane (`symmetryX` of the rig document, else the "
                         "centre of the model's bounds), preferring one of the mirrored part, and takes its "
                         "weights with every bone swapped for its opposite (arm_upper_l <-> arm_upper_r; "
                         "bones on the centre line keep themselves). Vertices with no partner within a "
                         "tolerance are left as they were and counted in `quality.mirrorUnmatched`. Use it "
                         "after hand-editing one arm. Example: "
                         "{\"path\":\"assets/models/hero.rig.json\",\"from\":\"l\"}. "
                         FA_COMMAND_DETAILS) + kScope).c_str(),
                     obj({{"from", Json::object({{"type", "string"}, {"enum", Json::array({"l", "r"})}, {"description", "The side whose weights are copied to the other: l (+X) or r (-X)."}})}}), {"from"});
    {
        CommandInfo info;
        info.name = "skin3d.clear";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Remove one edit (by index) or all the edits from a rig document's skin, recompute and bake.";
        info.description =
            "Removes `index` (as skin3d.info and the answer of an edit command number them) or, without it, every entry of `skin.edits`; the automatic weights and the per-part methods stay. The weights are recomputed and the .glb is baked again unless bake is false. "
            "Example: {\"path\":\"assets/models/hero.rig.json\",\"index\":2}";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()},
                                                             {"index", integer("The edit to remove (0 is the first); left out: every edit.", 0, 100000)},
                                                             {"dryRun", boolean("Report without writing.", false)},
                                                             {"bake", boolean("Bake the skinned .glb after writing.", true)},
                                                             {"overwrite", boolean("Replace a .glb that no rig document baked.", false)}})}});
        registry.add(info, [projectDir](const Json& args) { return skin3d_clear_command(projectDir, args_of(args)); });
    }
    {
        CommandInfo info;
        info.name = "skin3d.preview";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Draw the skin weights of a rig: a heat map of one bone or one colour per bone, and optionally the model bent at a bone to see how the skin deforms; returns the PNG.";
        info.description =
            "The way to SEE the weights. It fits the rig, computes the weights of the document's `skin` section (edits included) and draws the model with the software renderer of model.preview (no graphics device, the same pixels everywhere), from `views` sides. "
            "With `bone` (mode \"heat\"): the weights of that bone as a heat map, blue 0 to red 1, so a blend that is too long, too short or on the wrong limb is visible. Without it (mode \"bones\"): each vertex has the weighted mix of its bones' colours, with a legend of the bones. "
            "`pose` ({\"arm_lower_l\":60} or [{bone, degrees, axis:[x,y,z]}]) bends bones about the axis perpendicular to the bone (a knee or an elbow; `axis` overrides it), taking their children along, and adds a second row with the model deformed by linear blend skinning "
            "the way the .glb would deform it: creases, stretched triangles and parts left behind are what a bad skin looks like. The answer has the weights' `quality` and, for one bone, how many vertices it has weight on. "
            "The picture is returned as $image in a temporary file; pass `out` (a project-relative .png) to keep it. Nothing in the project changes otherwise. Example: {\"path\":\"assets/models/hero.rig.json\",\"bone\":\"arm_lower_l\",\"pose\":{\"arm_lower_l\":70}}";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()},
                                                             {"bone", str("Draw the weights of this bone as a heat map.")},
                                                             {"mode", Json::object({{"type", "string"}, {"enum", Json::array({"heat", "bones"})}, {"description", "heat (needs `bone`; the default with it) or bones (one colour per bone; the default without)."}})},
                                                             {"pose", Json::object({{"type", Json::array({"object", "array"})}, {"description", "Bones to bend: {bone: degrees} or a list of {bone, degrees, axis}. Adds a row with the deformed model."}})},
                                                             {"views", integer("How many sides to draw, 1 to 6 (default 3).", 1, 6)},
                                                             {"yaw", num("The angle of the first view in degrees: 0 looks at the model's +Z side (default 20).", -360, 360)},
                                                             {"pitch", num("Degrees above the horizon (default 12).", -80, 80)},
                                                             {"cell", num("Pixels per side of each view (default 280).", 96, 640)},
                                                             {"out", str("Keep the picture as a PNG at this project-relative path (ending in .png). Left out, it is a temporary file.")},
                                                             {"overwrite", boolean("Replace the file at `out` if it exists.", false)}})}});
        registry.add(info, [projectDir](const Json& args) { return skin3d_preview_command(projectDir, args_of(args)); });
    }
}

}  // namespace fa::assets_detail
