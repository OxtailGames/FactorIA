// Baking a rig document: the model it names evaluated and fitted, the skinned .glb next to the document, its provenance and recipe in
// assets.json, and the status of a baked document. "Stale" is the recipe's, like every made asset (docs/ASSETS.md "Recipes").
#include <algorithm>
#include <cstring>
#include <filesystem>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/scene/model_game_ready.h"
#include "fa/scene/rig_glb.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/rig_bake.h"
#include "model_texture_bake.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;
using assets_detail::ProjectRootGuard;

constexpr const char* kBakeCommand = "rig.bake";

std::string normalized(const std::string& rel) {
    auto norm = fs::normalize_checked(rel);
    return norm.ok() && !norm->empty() ? *norm : rel;
}

Json manifest_entry(const std::string& projectDir, const std::string& rel) {
    ProjectRootGuard root(projectDir);
    return assets::entry(rel);
}

}  // namespace

std::string rig_document_output(const RigDoc& doc, const std::string& relIn) {
    if (!doc.outputPath.empty()) return normalized(doc.outputPath);
    const std::string rel = normalized(relIn);
    if (ends_with(rel, kRigDocSuffix)) return rel.substr(0, rel.size() - std::strlen(kRigDocSuffix)) + ".rig.glb";
    const auto dot = rel.rfind('.');
    return (dot == std::string::npos ? rel : rel.substr(0, dot)) + ".rig.glb";
}

Result<RigDoc> load_rig_document(const std::string& projectDir, const std::string& rel, std::vector<RigIssue>* issues) {
    ProjectRootGuard root(projectDir);
    std::vector<RigIssue> local;
    std::vector<RigIssue>& list = issues ? *issues : local;
    auto doc = load_rig_doc(rel, &list);
    if (!doc.ok()) return doc.error();
    // what needs the template: the names in `parts` and `landmarks`, a generic rig's bones
    const std::vector<RigIssue> more = rig_check_doc(*doc);
    list.insert(list.end(), more.begin(), more.end());
    if (!more.empty()) return make_error(rel + " " + more[0].pointer + ": " + more[0].message, more[0].hint);
    return doc;
}

Result<RigEvaluation> rig_evaluate(const std::string& projectDir, const RigDoc& rigDoc) {
    RigEvaluation out;
    out.modelPath = normalized(rigDoc.model);
    ProjectRootGuard root(projectDir);
    {
        auto file = resolve_project_path(projectDir, out.modelPath);
        std::error_code ec;
        if (!file.ok() || !stdfs::is_regular_file(*file, ec)) {
            const std::vector<std::string> all = list_model_documents(projectDir);
            return make_error("the model '" + out.modelPath + "' of the rig does not exist",
                              all.empty() ? "Make one with model.create, then set \"model\" to its path."
                                          : did_you_mean(out.modelPath, all) + " Model documents: " + join(all, ", ") + ".");
        }
    }
    std::vector<ModelIssue> issues;
    auto model = load_model_doc(out.modelPath, &issues);
    if (!model.ok()) return make_error("the model '" + out.modelPath + "' of the rig does not load: " + model.error().message, model.error().hint);
    out.model = std::move(*model);
    auto build = evaluate_model(out.model, model_project_eval_options(projectDir));
    if (!build.ok()) return make_error("the model '" + out.modelPath + "' of the rig does not build: " + build.error().message, build.error().hint);
    out.build = std::move(*build);

    // the origin the model's .glb has, so the skin sits where the model is drawn; never merged: the parts are what the fit looks at
    out.mesh = out.build.data;
    if (!out.model.gameReady.is_null()) {
        auto ready = parse_game_ready(out.model.gameReady, "/gameReady");
        if (ready.ok()) {
            out.originOffset = model_origin_offset(out.build.data, ready->origin);
            if (out.originOffset.x != 0 || out.originOffset.y != 0 || out.originOffset.z != 0) out.mesh = model_translated(out.build.data, out.originOffset);
        }
    }
    auto fit = fit_rig(rigDoc, out.mesh);
    if (!fit.ok()) return make_error(fit.error().message, fit.error().hint);
    out.fit = std::move(*fit);
    out.warnings = out.fit.warnings;

    out.inputs.push_back(out.modelPath);
    for (const std::string& s : out.build.inputs)
        if (s != out.modelPath) out.inputs.push_back(s);
    if (out.model.texturing) {
        // the picture the model's own bake composed: the rig draws the model the way the model's .glb does
        const std::string output = model_document_output(out.model, out.modelPath);
        const Json prov = manifest_entry(projectDir, output).value("provenance", Json());
        std::string png;
        if (prov.is_object() && prov.value("texture", Json()).is_object()) png = prov["texture"].value("image", std::string());
        auto pngFile = png.empty() ? Result<stdfs::path>(make_error("none")) : resolve_project_path(projectDir, png);
        std::error_code ec;
        if (!png.empty() && pngFile.ok() && stdfs::is_regular_file(*pngFile, ec)) {
            model_texture_detail::apply_texture(out.mesh, out.model, png);
            if (std::find(out.inputs.begin(), out.inputs.end(), png) == out.inputs.end()) out.inputs.push_back(png);
        } else {
            out.warnings.push_back("The model '" + out.modelPath + "' has a texturing section but has not been baked, so the rig's .glb has no texture. Bake the model first "
                                   "(model.bake), then bake the rig again.");
        }
    }
    return out;
}

const char* rig_bake_state_name(RigBakeState state) {
    switch (state) {
        case RigBakeState::Fresh: return "fresh";
        case RigBakeState::Missing: return "missing";
        case RigBakeState::Stale: return "stale";
        case RigBakeState::Unrecorded: return "unrecorded";
        case RigBakeState::Broken: return "broken";
    }
    return "";
}

RigBakeStatus rig_bake_status(const std::string& projectDir, const std::string& relIn) {
    RigBakeStatus status;
    const std::string rel = normalized(relIn);
    auto doc = load_rig_document(projectDir, rel);
    if (!doc.ok()) {
        status.state = RigBakeState::Broken;
        status.reason = doc.error().message;
        status.hint = doc.error().hint;
        return status;
    }
    status.output = rig_document_output(*doc, rel);
    auto file = resolve_project_path(projectDir, status.output);
    std::error_code ec;
    if (!file.ok() || !stdfs::is_regular_file(*file, ec)) {
        status.state = RigBakeState::Missing;
        status.reason = "'" + status.output + "' has not been baked yet.";
        return status;
    }
    const Json recipe = assets_detail::recipe_of(manifest_entry(projectDir, status.output));
    if (recipe.is_null() || recipe.value("command", std::string()) != kBakeCommand || recipe["args"].value("path", std::string()) != rel) {
        status.state = RigBakeState::Unrecorded;
        status.reason = "'" + status.output + "' exists, but assets.json does not say it was baked from '" + rel + "'.";
        return status;
    }
    const assets_detail::RecipeCheck check = assets_detail::check_recipe(projectDir, recipe);
    if (!check.changed.empty() || !check.missing.empty()) {
        status.state = RigBakeState::Stale;
        status.reason = !check.changed.empty() ? "changed since the bake: " + join(check.changed, ", ") : "no longer readable: " + join(check.missing, ", ");
        return status;
    }
    status.state = RigBakeState::Fresh;
    status.reason = "'" + status.output + "' matches the rig document, its model and the files they read.";
    return status;
}

Result<RigBakeResult> bake_rig_document(const std::string& projectDir, const std::string& relIn, const RigBakeOptions& options) {
    const std::string rel = normalized(relIn);
    if (!ends_with(rel, kRigDocSuffix))
        return make_error("'" + rel + "' is not a rig document (its name must end in " + kRigDocSuffix + ").", "Name it like \"assets/models/hero.rig.json\".");
    auto doc = load_rig_document(projectDir, rel);
    if (!doc.ok()) return make_error(doc.error().message, doc.error().hint);
    RigBakeResult result;
    result.document = rel;
    result.output = rig_document_output(*doc, rel);
    if (options.onlyIfNeeded && rig_bake_status(projectDir, rel).state == RigBakeState::Fresh) return result;
    if (!starts_with(result.output, "assets/"))
        return make_error(rel + ": the skinned model would be written to '" + result.output + "', outside assets/.", "Put it under assets/, e.g. \"output\": {\"path\": \"assets/models/hero.rig.glb\"}.");

    auto outPath = resolve_project_path(projectDir, result.output);
    if (!outPath.ok()) return make_error(outPath.error().message, outPath.error().hint);
    if (!options.overwrite) {
        std::error_code ec;
        if (stdfs::exists(*outPath, ec)) {
            const Json recipe = assets_detail::recipe_of(manifest_entry(projectDir, result.output));
            if (recipe.is_null() || recipe.value("command", std::string()) != kBakeCommand)
                return make_error("'" + result.output + "' already exists and was not baked by a rig document.", "Pass overwrite: true to replace it, or set another \"output\": {\"path\"} in the document.");
        }
    }

    auto eval = rig_evaluate(projectDir, *doc);
    if (!eval.ok()) return make_error(rel + ": " + eval.error().message, eval.error().hint);
    auto bytes = rig_to_glb(eval->mesh, eval->fit, result.output);
    if (!bytes.ok()) return make_error(rel + ": cannot write '" + result.output + "': " + bytes.error().message, bytes.error().hint);
    result.sha256 = sha256_hex(bytes->data(), bytes->size());
    result.bytes = bytes->size();
    result.warnings = eval->warnings;

    std::vector<std::string> inputs = {rel};
    for (const std::string& s : eval->inputs)
        if (s != rel) inputs.push_back(s);
    result.inputs = inputs;

    bool ai = false;
    std::set<std::string> licenses, authors;
    for (const std::string& input : eval->inputs) {
        const Json entry = manifest_entry(projectDir, input);
        const Json prov = entry.is_object() ? entry.value("provenance", Json()) : Json();
        if (!prov.is_object()) continue;
        ai = ai || prov.value("ai", false);
        if (prov.contains("license") && prov["license"].is_string()) licenses.insert(prov["license"].get<std::string>());
        if (prov.contains("author") && prov["author"].is_string()) authors.insert(prov["author"].get<std::string>());
    }

    try {
        ProjectRootGuard root(projectDir);  // assets::update_entry writes the project's assets.json
        assets_detail::require_usable_manifest(projectDir);
        const Json previous = manifest_entry(projectDir, result.output);
        const Json previousProv = previous.is_object() ? previous.value("provenance", Json()) : Json();
        std::string err;
        bool same = false;
        const std::string_view view(reinterpret_cast<const char*>(bytes->data()), bytes->size());
        if (auto old = tooling_detail::read_file(*outPath)) same = *old == view;
        if (!same && !tooling_detail::write_file(*outPath, view, &err)) return make_error("Cannot write '" + result.output + "': " + err, "Check that the folder is writable.");
        result.written = true;

        const bool madeHere = previousProv.is_object() && previousProv.value("provider", std::string()) == "factoria rig.bake";
        std::string license = licenses.empty() ? "CC0-1.0" : join(std::vector<std::string>(licenses.begin(), licenses.end()), "; ");
        if (madeHere && previousProv.contains("license") && previousProv["license"].is_string()) license = previousProv["license"].get<std::string>();
        std::string author = authors.empty() ? "factoria" : join(std::vector<std::string>(authors.begin(), authors.end()), "; ");
        if (madeHere && previousProv.contains("author") && previousProv["author"].is_string()) author = previousProv["author"].get<std::string>();
        const std::string notes = std::format("A {} skeleton of {} bones fitted to the model '{}' by rig document '{}': {} landmarks from parts, {} from geometry, {} overridden, {} estimated. "
                                              "Vertices follow one bone each (rigid binding).",
                                              eval->fit.templateName, eval->fit.bones.size(), eval->modelPath, rel, eval->fit.fromParts, eval->fit.fromGeometry, eval->fit.overrides, eval->fit.estimated);
        Json prov = Json::object({{"origin", ai ? "generated" : "original"},
                                  {"ai", ai},
                                  {"kind", "model3d"},
                                  {"provider", "factoria rig.bake"},
                                  {"license", license},
                                  {"author", author},
                                  {"source", rel},
                                  {"notes", notes},
                                  {"date", assets::today()}});
        prov["recipe"] = assets_detail::make_recipe(projectDir, kBakeCommand, Json::object({{"path", rel}}), inputs);
        result.provenance = prov;
        auto updated = assets::update_entry(result.output, [&](Json& e) {
            e.erase("analysis");
            e["provenance"] = prov;
        });
        if (!updated.ok()) return make_error("The skinned model was written, but assets.json was not updated: " + updated.error().message, updated.error().hint);
    } catch (const CommandError& e) {
        return make_error(e.what(), e.hint);
    }
    result.fit = std::move(eval->fit);
    return result;
}

std::vector<std::string> list_rig_documents(const std::string& projectDir) {
    std::vector<std::string> out;
    const stdfs::path root(projectDir);
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        const std::string rel = it->path().lexically_relative(root).generic_string();
        std::error_code e2;
        if (it->is_directory(e2)) {
            if ((!name.empty() && name[0] == '.') || name == "node_modules" || rel == "build") it.disable_recursion_pending();
            continue;
        }
        if (ends_with(name, kRigDocSuffix)) out.push_back(rel);
    }
    std::sort(out.begin(), out.end());
    return out;
}

Result<std::vector<RigBakeResult>> bake_rig_documents_if_needed(const std::string& projectDir) {
    std::vector<RigBakeResult> baked;
    for (const std::string& rel : list_rig_documents(projectDir)) {
        if (rig_bake_status(projectDir, rel).state == RigBakeState::Fresh) continue;
        auto r = bake_rig_document(projectDir, rel, {false, false});
        if (!r.ok()) return make_error(r.error().message, r.error().hint);
        baked.push_back(std::move(*r));
    }
    return baked;
}

}  // namespace fa
