// rig.templates, rig.info, rig.create, rig.fit and rig.bake: rig documents (`*.rig.json`, docs/RIGGING.md) as project files. The format, the
// templates and the fit are fa_scene's (fa/scene/rig_doc.h, rig_fit.h); baking and its recipe are rig_doc_bake.cpp.
#include <algorithm>
#include <cmath>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/scene/model_doc.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/rig_bake.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

namespace stdfs = std::filesystem;

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}
Json str(const char* what) { return Json::object({{"type", "string"}, {"description", what}}); }
Json boolean(const char* what, bool def) { return Json::object({{"type", "boolean"}, {"default", def}, {"description", what}}); }
// no "default" key: the registry fills schema defaults in, and rig.fit must tell an argument that was not given
Json flag(const char* what) { return Json::object({{"type", "boolean"}, {"description", what}}); }
Json object_arg(const char* what) { return Json::object({{"type", "object"}, {"description", what}}); }

std::string rig_path(const std::string& arg, const char* what = "path") {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", std::string("`") + what + "` '" + arg + "' is not a rig document under assets/.", "Rig documents live in assets/, e.g. \"assets/models/hero.rig.json\" (rig.create writes one).");
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
    throw CommandError("invalid_document", error.message, error.hint.empty() ? "schemas/rig.schema.json describes the format; rig.templates {} lists the templates." : error.hint,
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

// Parses a document's JSON and checks what needs the template; throws with every issue.
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

Json options_json(const RigTemplateInfo& t) {
    Json list = Json::array();
    for (const RigOptionInfo& o : t.options) {
        Json item = Json::object({{"key", o.key}, {"type", o.type}, {"default", o.def}, {"doc", o.doc}});
        if (o.min) item["min"] = *o.min;
        if (o.max) item["max"] = *o.max;
        if (!o.choices.empty()) item["choices"] = o.choices;
        list.push_back(item);
    }
    return list;
}

Json bones_json(const std::vector<RigBoneInfo>& bones) {
    Json list = Json::array();
    for (const RigBoneInfo& b : bones) {
        Json item = Json::object({{"name", b.name}, {"role", b.role}});
        if (b.index) item["index"] = b.index;
        if (!b.side.empty()) item["side"] = b.side;
        item["parent"] = b.parent;
        item["leaf"] = b.leaf;
        list.push_back(item);
    }
    return list;
}

// What the fit matched, for the commands: the report of rig_fit_to_json plus a short list of which bones follow which parts.
Json fit_report(const RigFit& fit, const std::vector<std::string>& extraWarnings = {}) {
    Json report = rig_fit_to_json(fit);
    Json matched = Json::object();
    Json unmatched = Json::array();
    for (const RigBoneFit& b : fit.bones) {
        if (!b.parts.empty()) matched[b.name] = b.parts;
        else unmatched.push_back(b.name);
    }
    report["matched"] = matched;
    report["boneHasNoPart"] = unmatched;
    if (!extraWarnings.empty()) {
        Json w = report["warnings"];
        for (const std::string& s : extraWarnings)
            if (std::find(fit.warnings.begin(), fit.warnings.end(), s) == fit.warnings.end()) w.push_back(s);
        report["warnings"] = w;
    }
    return report;
}

// The report of fitting the document now, or the reason it cannot be fitted.
Json try_fit(const std::string& projectDir, const RigDoc& doc) {
    auto eval = rig_evaluate(projectDir, doc);
    if (!eval.ok()) return Json::object({{"state", "failed"}, {"message", eval.error().message}, {"hint", eval.error().hint}});
    Json report = fit_report(eval->fit, eval->warnings);
    report["state"] = "fitted";
    return report;
}

// Fits the document now; a fit that cannot be made throws (nothing is written yet) with the reason and how to fix it.
Json fit_or_throw(const std::string& projectDir, const RigDoc& doc, const std::string& rel, const char* command) {
    Json report = try_fit(projectDir, doc);
    if (report.value("state", std::string()) == "failed")
        throw CommandError("fit_failed", std::string(command) + ": " + report.value("message", std::string()), report.value("hint", std::string()),
                           Json::object({{"path", rel}, {"written", false}}));
    return report;
}

std::vector<std::string> model_part_names(const std::string& projectDir, const std::string& modelPath) {
    ProjectRootGuard root(projectDir);
    std::vector<ModelIssue> issues;
    auto model = load_model_doc(modelPath, &issues);
    if (!model.ok()) fail("invalid_document", "The model '" + modelPath + "' does not load: " + model.error().message, model.error().hint);
    auto build = evaluate_model(*model, model_project_eval_options(projectDir));
    if (!build.ok()) fail("failed", "The model '" + modelPath + "' does not build: " + build.error().message, build.error().hint);
    std::vector<std::string> names;
    for (const ModelPartInfo& p : build->parts)
        if (!p.part.empty() && std::find(names.begin(), names.end(), p.part) == names.end()) names.push_back(p.part);
    return names;
}

void require_model(const std::string& projectDir, const std::string& model) {
    auto file = resolve_project_path(projectDir, model);
    std::error_code ec;
    if (!file.ok() || !stdfs::is_regular_file(*file, ec)) {
        const std::vector<std::string> all = list_model_documents(projectDir);
        fail("not_found", "The model '" + model + "' does not exist.", all.empty() ? "Make one with model.create, then pass its path as `model`." : did_you_mean(model, all));
    }
}

// ---- rig.templates ----

Json template_json(const RigTemplateInfo& t) {
    return Json::object({{"name", t.name}, {"doc", t.doc}, {"options", options_json(t)}, {"partWords", t.partWords}});
}

Json rig_templates_command(const Json& a) {
    check_arg_keys("rig.templates", a, "", {"name", "options"});
    if (!a.contains("name")) {
        if (a.contains("options")) fail("invalid_argument", "rig.templates: `options` needs a template `name`.", "Example: {\"name\":\"humanoid\",\"options\":{\"spine\":4}}.");
        Json list = Json::array();
        for (const RigTemplateInfo& t : rig_templates()) list.push_back(template_json(t));
        return Json::object({{"templates", list},
                             {"nextSteps", Json::array({"rig.templates {\"name\":\"humanoid\"} lists the bones of one template. rig.create {\"path\":\"assets/models/hero.rig.json\",\"model\":\"assets/models/hero.model.json\",\"template\":\"humanoid\"} fits one to a model."})}});
    }
    const std::string name = tooling_detail::arg_string(a, "name", true);
    const RigTemplateInfo* t = find_rig_template(name);
    if (!t) {
        std::vector<std::string> names;
        for (const RigTemplateInfo& x : rig_templates()) names.push_back(x.name);
        fail("not_found", "There is no rig template '" + name + "'.", did_you_mean(name, names));
    }
    Json doc = Json::object({{"format", kRigDocFormat}, {"model", "assets/models/x.model.json"}, {"template", name}});
    if (a.contains("options")) doc["options"] = a["options"];
    if (name == "generic") doc["bones"] = Json::array();
    const RigDoc parsed = checked(doc, "rig.templates");
    Json out = template_json(*t);
    out["bones"] = bones_json(rig_template_bones(parsed));
    Json landmarks = Json::array();
    for (const RigBoneInfo& b : rig_template_bones(parsed)) {
        landmarks.push_back(b.name);
        if (b.leaf) landmarks.push_back(b.name + ".tail");
    }
    out["landmarks"] = landmarks;
    out["nextSteps"] = Json::array({"`parts` of a rig document maps a bone name to the model parts that decide where it is; `landmarks` maps these names to explicit [x,y,z] positions."});
    return out;
}

// ---- rig.info ----

Json rig_info_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("rig.info", a, "", {"path", "fit"});
    const std::string rel = rig_path(tooling_detail::arg_string(a, "path", true));
    const Json json = read_json_file(projectDir, rel);
    std::vector<RigIssue> issues;
    auto doc = parse_rig_doc(json, rel, &issues);
    Json out = Json::object({{"path", rel}});
    if (doc.ok()) {
        const std::vector<RigIssue> more = rig_check_doc(*doc);
        issues.insert(issues.end(), more.begin(), more.end());
    }
    out["valid"] = doc.ok() && issues.empty();
    out["issues"] = issues_json(issues);
    if (!doc.ok() || !issues.empty()) {
        out["nextSteps"] = Json::array({"Fix the issues (each has its JSON pointer and the fix); schemas/rig.schema.json describes the format."});
        return out;
    }
    out["template"] = doc->templateName;
    out["model"] = doc->model;
    out["output"] = rig_document_output(*doc, rel);
    out["bake"] = bake_json(rig_bake_status(projectDir, rel));
    if (tooling_detail::arg_bool(a, "fit", true)) out["fit"] = try_fit(projectDir, *doc);
    out["nextSteps"] = Json::array({"rig.fit changes `parts`, `landmarks` and `options` and shows what the fit matched; rig.bake writes the skinned .glb."});
    return out;
}

// ---- rig.create ----

Json bake_part(const std::string& projectDir, const std::string& rel, bool bake, bool overwrite, Json& result) {
    if (!bake) {
        result["bake"] = bake_json(rig_bake_status(projectDir, rel));
        return Json();
    }
    auto b = bake_rig_document(projectDir, rel, {false, overwrite});
    if (!b.ok()) {
        result["bake"] = Json::object({{"state", "failed"}, {"message", b.error().message}, {"hint", b.error().hint}});
        return Json::array({"The document was written but could not be baked: " + b.error().message + " " + b.error().hint});
    }
    result["bake"] = Json::object({{"state", "baked"}, {"output", b->output}, {"bytes", b->bytes}, {"sha256", b->sha256}, {"joints", b->fit.bones.size()}});
    if (!b->skin.is_null()) result["skin"] = b->skin;
    result["provenance"] = b->provenance;
    return Json();
}

Json rig_create_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("rig.create", a, "", {"path", "model", "template", "options", "parts", "landmarks", "strict", "output", "doc", "overwrite", "bake", "skin"});
    const std::string rel = rig_path(tooling_detail::arg_string(a, "path", true));
    std::error_code ec;
    if (!tooling_detail::arg_bool(a, "overwrite", false) && stdfs::exists(project_file(projectDir, rel), ec))
        fail("exists", "'" + rel + "' already exists.", "Pass overwrite: true to replace it, or change it with rig.fit.");
    const std::string modelArg = tooling_detail::arg_string(a, "model", true);
    auto modelNorm = fs::normalize_checked(modelArg);
    if (!modelNorm.ok() || !ends_with(to_lower(*modelNorm), kModelDocSuffix))
        fail("invalid_argument", "rig.create `model` '" + modelArg + "' is not a model document.", "Pass the project path of a *.model.json, e.g. \"assets/models/hero.model.json\".");
    const std::string model = *modelNorm;
    require_model(projectDir, model);
    const std::string templateName = tooling_detail::arg_string(a, "template", true);
    if (!find_rig_template(templateName)) {
        std::vector<std::string> names;
        for (const RigTemplateInfo& x : rig_templates()) names.push_back(x.name);
        fail("invalid_argument", "rig.create `template` '" + templateName + "' is not a rig template.", did_you_mean(templateName, names));
    }
    std::vector<std::string> partNames;
    if (templateName == "generic") partNames = model_part_names(projectDir, model);
    RigDoc seed = make_rig_doc(model, templateName, partNames);
    Json json = rig_doc_to_json(seed);
    if (a.contains("doc")) json["doc"] = a["doc"];
    for (const char* key : {"options", "parts", "landmarks", "strict", "output", "skin"})
        if (a.contains(key)) json[key] = a[key];
    if (a.contains("options") && a["options"].is_object()) {  // the options given on top of the template's defaults
        Json merged = rig_doc_to_json(seed).value("options", Json::object());
        for (auto it = a["options"].begin(); it != a["options"].end(); ++it) merged[it.key()] = it.value();
        json["options"] = merged;
    }
    const RigDoc doc = checked(json, rel);
    require_usable_manifest(projectDir);
    Json fit = fit_or_throw(projectDir, doc, rel, "rig.create");
    write_document(projectDir, rel, rig_doc_to_json(doc));
    Json result = Json::object({{"path", rel}, {"output", rig_document_output(doc, rel)}, {"template", doc.templateName}, {"model", doc.model}, {"boneCount", rig_template_bones(doc).size()}});
    result["fit"] = std::move(fit);
    Json steps = Json::array();
    const Json bakeFailed = bake_part(projectDir, rel, tooling_detail::arg_bool(a, "bake", true), tooling_detail::arg_bool(a, "overwrite", false), result);
    if (bakeFailed.is_array())
        for (const Json& s : bakeFailed) steps.push_back(s);
    steps.push_back("rig.fit {\"path\":\"" + rel + "\"} shows the fit and changes `parts` and `landmarks`; the baked .glb carries the skeleton as a glTF skin (docs/RIGGING.md).");
    result["nextSteps"] = steps;
    return result;
}

// ---- rig.fit ----

// Applies `values` (an object, null values remove keys) to the object at json[key].
void merge_object(Json& json, const char* key, const Json& values, const char* command) {
    if (values.is_null()) {
        json.erase(key);
        return;
    }
    if (!values.is_object()) fail("invalid_argument", std::string(command) + ": `" + key + "` must be an object (a null value removes a key, null removes them all).", std::string("Example: {\"") + key + "\":{\"head\":null}}.");
    Json current = json.contains(key) && json[key].is_object() ? json[key] : Json::object();
    for (auto it = values.begin(); it != values.end(); ++it) {
        if (it.value().is_null()) current.erase(it.key());
        else current[it.key()] = it.value();
    }
    if (current.empty()) json.erase(key);
    else json[key] = current;
}

Json rig_fit_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("rig.fit", a, "", {"path", "parts", "landmarks", "options", "symmetryX", "strict", "dryRun", "bake", "overwrite", "skin"});
    const std::string rel = rig_path(tooling_detail::arg_string(a, "path", true));
    Json json = read_json_file(projectDir, rel);
    const bool dryRun = tooling_detail::arg_bool(a, "dryRun", false);
    Json changes = Json::array();
    for (const char* key : {"parts", "landmarks", "options", "skin"}) {
        if (!a.contains(key)) continue;
        merge_object(json, key, a[key], "rig.fit");
        changes.push_back(key);
    }
    if (a.contains("symmetryX")) {
        if (a["symmetryX"].is_null()) json.erase("symmetryX");
        else if (a["symmetryX"].is_number()) json["symmetryX"] = a["symmetryX"];
        else fail("invalid_argument", "rig.fit: `symmetryX` must be a number (the x of the symmetry plane) or null.", "Example: {\"symmetryX\":0}.");
        changes.push_back("symmetryX");
    }
    if (a.contains("strict")) {
        json["strict"] = tooling_detail::arg_bool(a, "strict", false);
        changes.push_back("strict");
    }
    // `options` replaced single keys: the rest of the template's options stay as they were
    const RigDoc doc = checked(json, rel);
    Json fit = fit_or_throw(projectDir, doc, rel, "rig.fit");
    Json result = Json::object({{"path", rel}, {"output", rig_document_output(doc, rel)}, {"changed", changes}});
    if (!changes.empty() && !dryRun) {
        require_usable_manifest(projectDir);
        write_document(projectDir, rel, rig_doc_to_json(doc));
        result["written"] = true;
    } else {
        result["written"] = false;
    }
    result["fit"] = std::move(fit);
    Json steps = Json::array();
    if (!dryRun && !changes.empty()) {
        const Json bakeFailed = bake_part(projectDir, rel, tooling_detail::arg_bool(a, "bake", true), tooling_detail::arg_bool(a, "overwrite", false), result);
        if (bakeFailed.is_array())
            for (const Json& s : bakeFailed) steps.push_back(s);
    } else {
        result["bake"] = bake_json(rig_bake_status(projectDir, rel));
    }
    if (changes.empty()) steps.push_back("Nothing was changed: pass `parts` ({\"arm_l\":[\"left_arm\"]}), `landmarks` ({\"head\":[0,1.6,0]}), `options` or `strict` to change the document.");
    result["nextSteps"] = steps;
    return result;
}

// ---- rig.bake ----

// True when `output` was baked by rig.bake with the mergeParts the call asks for: baking it again would write the same bytes.
bool merge_choice_unchanged(const std::string& projectDir, const std::string& output, bool wanted) {
    ProjectRootGuard root(projectDir);
    const Json recipe = recipe_of(assets::entry(output));
    if (!recipe.is_object() || recipe.value("command", std::string()) != "rig.bake") return false;
    const bool stored = recipe.contains("args") && recipe["args"].is_object() && recipe["args"].value("mergeParts", false);
    return stored == wanted;
}

RigBakeOptions merge_options(const Json& a, bool overwrite) {
    RigBakeOptions o;
    o.overwrite = overwrite;
    if (a.contains("mergeParts")) o.mergeParts = tooling_detail::arg_bool(a, "mergeParts", false);
    return o;
}

Json rig_bake_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("rig.bake", a, "", {"path", "force", "dryRun", "overwrite", "mergeParts"});
    const bool force = tooling_detail::arg_bool(a, "force", false), dryRun = tooling_detail::arg_bool(a, "dryRun", false), overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    std::vector<std::string> docs;
    const bool single = a.contains("path");
    if (single) docs.push_back(rig_path(tooling_detail::arg_string(a, "path", true)));
    else docs = list_rig_documents(projectDir);
    Json baked = Json::array(), unchanged = Json::array(), failed = Json::array();
    for (const std::string& rel : docs) {
        const RigBakeStatus status = rig_bake_status(projectDir, rel);
        std::string reason = rig_bake_state_name(status.state);
        if (status.state == RigBakeState::Fresh) {
            if (!force && !single && (!a.contains("mergeParts") || merge_choice_unchanged(projectDir, status.output, tooling_detail::arg_bool(a, "mergeParts", false)))) {
                unchanged.push_back(status.output);
                continue;
            }
            reason = "forced";
        }
        if (status.state == RigBakeState::Broken) {
            if (single) {
                std::vector<RigIssue> issues;
                (void)load_rig_document(projectDir, rel, &issues);
                throw CommandError("invalid_document", status.reason, status.hint, Json::object({{"path", rel}, {"issues", issues_json(issues)}}));
            }
            failed.push_back(Json::object({{"document", rel}, {"error", Json::object({{"message", status.reason}, {"hint", status.hint}})}}));
            continue;
        }
        if (dryRun) {
            baked.push_back(Json::object({{"document", rel}, {"out", status.output}, {"reason", reason}}));
            continue;
        }
        auto b = bake_rig_document(projectDir, rel, merge_options(a, overwrite));
        if (!b.ok()) {
            if (single) fail("failed", b.error().message, b.error().hint);
            failed.push_back(Json::object({{"document", rel}, {"out", status.output}, {"error", Json::object({{"message", b.error().message}, {"hint", b.error().hint}})}}));
            continue;
        }
        Json item = Json::object({{"document", rel}, {"out", b->output}, {"reason", reason}, {"bytes", b->bytes}, {"sha256", b->sha256}, {"joints", b->fit.bones.size()}, {"mergeParts", b->mergeParts}, {"submeshes", b->submeshesAfter}});
        if (b->mergeParts) item["submeshesBefore"] = b->submeshesBefore;
        if (!b->warnings.empty()) item["warnings"] = b->warnings;
        if (!b->skin.is_null()) item["skin"] = b->skin;
        baked.push_back(item);
    }
    Json result = Json::object({{dryRun ? "wouldBake" : "baked", baked}, {"count", baked.size()}, {"unchanged", unchanged}});
    if (dryRun) result["dryRun"] = true;
    if (!failed.empty()) result["failed"] = failed;
    Json steps = Json::array();
    if (docs.empty()) steps.push_back("There are no rig documents yet: rig.create {\"path\":\"assets/models/hero.rig.json\",\"model\":\"assets/models/hero.model.json\",\"template\":\"humanoid\"} writes one.");
    if (!failed.empty()) steps.push_back("Fix the documents in `failed` (rig.info {\"path\":...} lists every issue with its JSON pointer) and call rig.bake again.");
    if (!baked.empty() && !dryRun) steps.push_back("The .glb loads as a skinned mesh: the joints are its skin, named like the bones (docs/RIGGING.md, \"Canonical bones\").");
    result["nextSteps"] = steps;
    return result;
}

}  // namespace

void register_rig_commands(CommandRegistry& registry, const std::string& projectDir) {
    auto pathArg = [] { return str("The rig document, project-relative, under assets/, ending in .rig.json."); };
    {
        CommandInfo info;
        info.name = "rig.templates";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "List the skeleton templates (humanoid, quadruped, bird, tail, chain, generic) with their options and the words in part names they recognise; with `name`, the bones of one.";
        info.description =
            "A rig document (`*.rig.json`, docs/RIGGING.md) fits a skeleton template to a model. Every template names its bones the same way, `<role>[_<index>][_<side>]` (root, spine_1, neck, head, clavicle_l, arm_upper_l, arm_lower_l, hand_l, thigh_l, shin_l, foot_l, toe_l, tail_1...), "
            "and the (role, index, side) triple is what retargeting between templates maps. With no argument this returns the catalog: for each template what it is for, the pose it assumes, its options (spine, neck, tail, toes, pose, segments, axis) with range and default, "
            "and the words in a model part name that tell the fit which bone it is (\"arm_l\", \"left leg\", \"head\"...). With `name` (and optionally `options`) it returns the bones that template has for those options, in order (parents first): name, role, index, side, parent, leaf, "
            "and the landmark names a rig document's `landmarks` may use (\"<bone>\" for a joint, \"<bone>.tail\" for the end of a leaf bone). Example: {\"name\":\"quadruped\",\"options\":{\"tail\":6}}";
        info.inputSchema = Json::object({{"type", "object"}, {"additionalProperties", false},
                                         {"properties", obj({{"name", str("The template: humanoid, quadruped, bird, tail, chain or generic. Leave out for the catalog.")},
                                                             {"options", object_arg("The template's options (rig.templates {} lists them), to see the bones they give.")}})}});
        registry.add(info, [](const Json& args) { return rig_templates_command(args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "rig.info";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Check a rig document and fit it to its model without writing anything: every issue with its fix, the bones, where each joint came from and what the fit noticed.";
        info.description =
            "Reads `path` (*.rig.json). A document with mistakes returns valid false and ALL its issues, each with the JSON pointer, what is wrong and the fix (a bone or part name that does not exist gets a \"did you mean\"). "
            "A valid one returns where it bakes to and whether that .glb is fresh or stale, and (unless fit is false) the fit: for each bone its head and tail in the model's space and where they came from (override = the document's landmarks, "
            "part = a model part named for the bone, geometry = measured from the mesh, proportion = an ESTIMATE from the template's default proportions), which model parts each bone follows (`matched`), the parts no bone looked at (`unusedParts`) "
            "and the warnings. A fit that cannot be made returns state failed with the reason. Example: {\"path\":\"assets/models/hero.rig.json\"}";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()}, {"fit", boolean("Fit the template to the model for the report (evaluates the model).", true)}})}});
        registry.add(info, [projectDir](const Json& args) { return rig_info_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "rig.create";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Write a rig document for a model: a skeleton template (humanoid, quadruped, bird, tail, chain, generic) fitted to the model by its parts and landmarks, and bake it to a skinned .glb.";
        info.description =
            "Writes `path` (*.rig.json under assets/) that names the model document (`model`) and a "
            "`template`, with the template's `options` (rig.templates lists them: spine, neck and tail bone "
            "counts, toes, pose, segments, axis), optional `parts` ({bone: [model parts]}: which parts "
            "decide where a bone is, when their names do not say) and `landmarks` ({bone: [x,y,z], "
            "\"<bone>.tail\": [x,y,z]}: explicit joint positions in the model's space). The template is "
            "fitted to the model before anything is written (a fit that cannot be made fails and writes "
            "nothing): the answer lists every bone with its head and tail, whether each came from a part, "
            "the geometry or an estimate, which parts each bone follows, the parts nobody used and the "
            "warnings (a landmark that could not be found says what to name or give). A `generic` rig gets "
            "one bone per part of the model under `root`; edit the bones in the file. Example: "
            "{\"path\":\"assets/models/hero.rig.json\",\"model\":\"assets/models/hero.model.json\",\"template\":\"humanoid\",\"options\":{\"spine\":4}}"
            FA_COMMAND_DETAILS
            "Unless bake is false it is baked: <name>.rig.glb next to the document is the model with a glTF "
            "skin (joints named like the bones, rest pose = the model's pose); its vertices are bound to the "
            "bones with automatic skin weights (heat diffusion by default, rigid per part for a generic rig; "
            "the document's `skin` section and the skin3d.* commands change them, docs/RIGGING.md). The "
            "model must be a model document (*.model.json).";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"path", "model", "template"})}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()},
                                                             {"model", str("The model document to fit, project-relative, ending in .model.json.")},
                                                             {"template", Json::object({{"type", "string"}, {"enum", Json::array({"humanoid", "quadruped", "bird", "tail", "chain", "generic"})}, {"description", "The skeleton template."}})},
                                                             {"options", object_arg("The template's options, e.g. {\"spine\":4,\"tail\":3} (rig.templates {} lists them); the rest keep their defaults.")},
                                                             {"parts", object_arg("{bone: part name or list of part names}: the model parts that decide where a bone is. Normally the fit recognises parts by their names.")},
                                                             {"landmarks", object_arg("{bone or \"bone.tail\": [x,y,z]}: explicit joint positions in the model's space; they win over everything the fit finds.")},
                                                             {"strict", flag("Make a landmark that could only be estimated from proportions an error instead of a warning (default false).")},
                                                             {"output", object_arg("{path: where to bake, under assets/, ending in .glb}. Default: <name>.rig.glb next to the document.")},
                                                             {"skin", object_arg("The document's `skin` section: {method: auto|heat|voxel|rigid, maxInfluences, smooth, maxHops, locality, parts: {part: {method, bone}}, edits}. Left out: automatic weights. skin3d.* edits it afterwards (docs/RIGGING.md).")},
                                                             {"doc", str("A note on what the rig is for.")},
                                                             {"overwrite", boolean("Replace the document when it exists (and the .glb when nothing baked it).", false)},
                                                             {"bake", boolean("Bake the skinned .glb after writing.", true)}})}});
        registry.add(info, [projectDir](const Json& args) { return rig_create_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "rig.fit";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Change what a rig document tells the fit (parts, landmarks, options, symmetry, strict), fit the template to the model again and show what it matched; then bake.";
        info.description =
            "Reads `path` (*.rig.json), applies the changes you give, checks the document as a whole and fits the template to the model with the changes (a bad bone or part name, or a fit that cannot be made, fails with the issues, their JSON pointers and a \"did you mean\", and writes nothing), "
            "writes it and answers with the fit: each bone's head and tail and where it came from (override, part, geometry, proportion = estimate), the parts each bone follows (`matched`), the bones that follow no part, the parts no bone used and the warnings. "
            "`parts` and `landmarks` are merged key by key: a value sets that bone, null removes it, null as the whole value removes them all. Use `parts` when a part's name does not say which bone it is ({\"arm_l\": [\"sleeve_left\"]}), `landmarks` when "
            "a joint is somewhere the fit cannot know ({\"head\": [0, 1.62, 0.03], \"head.tail\": [0, 1.9, 0.03]}); `strict` makes every estimated joint an error so nothing is silently guessed. With nothing to change this only shows the fit. dryRun shows the fit "
            "the changes would give without writing. Unless bake is false the skinned .glb is baked again after a change. Example: {\"path\":\"assets/models/hero.rig.json\",\"landmarks\":{\"neck\":[0,1.55,0]},\"strict\":true}";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()},
                                                             {"parts", Json::object({{"type", Json::array({"object", "null"})}, {"description", "{bone: part name or list of part names}; a null value removes that bone's entry, null removes all of them."}})},
                                                             {"landmarks", Json::object({{"type", Json::array({"object", "null"})}, {"description", "{bone or \"bone.tail\": [x,y,z]}; a null value removes that landmark, null removes all of them."}})},
                                                             {"options", Json::object({{"type", Json::array({"object", "null"})}, {"description", "The template's options to change (rig.templates {} lists them); null as a value returns one to its default."}})},
                                                             {"symmetryX", Json::object({{"type", Json::array({"number", "null"})}, {"description", "The x of the symmetry plane left and right bones mirror about. Null: the centre of the model's bounds."}})},
                                                             {"strict", flag("Make estimated landmarks errors: true or false, left as it is when not given.")},
                                                             {"skin", Json::object({{"type", Json::array({"object", "null"})}, {"description", "Fields of the document's `skin` section to set ({method, maxInfluences, smooth, maxHops, locality, parts, edits}); a field given replaces that field, null removes it. skin3d.* edits the weights one operation at a time."}})},
                                                             {"dryRun", boolean("Fit with the changes but write nothing.", false)},
                                                             {"bake", boolean("Bake the skinned .glb after writing.", true)},
                                                             {"overwrite", boolean("Replace a .glb that no rig document baked.", false)}})}});
        registry.add(info, [projectDir](const Json& args) { return rig_fit_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "rig.bake";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Fit rig documents to their models and write the skinned .glb files next to them (only the missing or stale ones unless forced), with their recipe in assets.json.";
        info.description =
            "Without `path` this bakes every *.rig.json of the project whose .glb is missing or out of date (the rig document, its model document or a file they read changed: the recipe's hashes), like model.bake. With `path` it bakes that document. "
            "The .glb is the model's mesh exactly as model.bake writes it plus one glTF skin: a node per bone named like the bone (translation = head minus the parent's head, extras {role, and index and side when the bone has them}), inverseBindMatrices that make the rest pose "
            "draw the model unchanged, and JOINTS_0 / WEIGHTS_0 with up to four normalised influences per vertex, computed from the document's `skin` section (automatic heat-diffusion weights, rigid parts, and the edits skin3d.* wrote; deterministic). The origin follows the model's gameReady.origin; "
            "a textured model uses the picture its own bake made (bake the model first). The same inputs give the same bytes. assets.json records provenance and the recipe, so assets.regenerate and project.validate know when it is stale. "
            "A file that nothing baked is never replaced unless overwrite is true. `mergeParts` joins parts that share a material (fewer draw calls). Example: {} or {\"path\":\"assets/models/hero.rig.json\"}"
            FA_COMMAND_DETAILS
            "`mergeParts` welds the skinned parts that share a material into one submesh after the fit (a rigged character of 8 parts with 2 materials then draws in 2 calls per pass instead of 8): only the index list is regrouped, so the weights, joints and bind pose are the same and a posed frame looks the same; the result lists `submeshesBefore` and `submeshes`, and the part names of a merged submesh are joined with \"+\". The choice is kept in the recipe, so a later bake or `factoria export` repeats it. "
            "`factoria export` bakes the stale documents first.";
        info.inputSchema = Json::object({{"type", "object"}, {"additionalProperties", false},
                                         {"properties", obj({{"path", str("Bake only this document (project-relative, ending in .rig.json). Leave out for every document.")},
                                                             {"force", boolean("Bake documents that are fresh too.", false)},
                                                             {"dryRun", boolean("List what would be baked and why, and write nothing.", false)},
                                                             {"overwrite", boolean("Replace a file at the output that no rig document baked.", false)},
                                                             {"mergeParts", Json::object({{"type", "boolean"}, {"description", "Weld the skinned parts that share a material into one submesh (fewer draw calls). Left out: what the last bake of the document used (false the first time); the choice is kept in the recipe."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return rig_bake_command(projectDir, args.is_null() ? Json::object() : args); });
    }
}

}  // namespace fa::assets_detail
