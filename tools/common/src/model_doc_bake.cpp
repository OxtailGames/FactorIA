// Baking a model document: the .glb next to it (through the mesh.save path), its provenance and recipe in assets.json, and the status of a
// baked document. "Stale" is the recipe's, like every made asset (docs/ASSETS.md "Recipes").
#include <algorithm>
#include <cstring>
#include <filesystem>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/render/fonts.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/project_fs.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;
using assets_detail::ProjectRootGuard;

constexpr const char* kBakeCommand = "model.bake";

std::string normalized(const std::string& rel) {
    auto norm = fs::normalize_checked(rel);
    return norm.ok() && !norm->empty() ? *norm : rel;
}

Json manifest_entry(const std::string& projectDir, const std::string& rel) {
    ProjectRootGuard root(projectDir);
    return assets::entry(rel);
}

bool load_for_bake(const std::string& projectDir, const std::string& rel, ModelDoc& doc, ModelBakeStatus& status) {
    ProjectRootGuard root(projectDir);
    auto loaded = load_model_doc(rel);
    if (!loaded.ok()) {
        status.state = ModelBakeState::Broken;
        status.reason = loaded.error().message;
        status.hint = loaded.error().hint;
        return false;
    }
    doc = std::move(*loaded);
    status.output = model_document_output(doc, rel);
    return true;
}

}  // namespace

ModelEvalOptions model_project_eval_options() {
    ModelEvalOptions options;
    options.text = [](const ModelTextRequest& r) -> Result<ModelTextOutline> {
        const TextAnchor anchor = r.anchor == "start" ? TextAnchor::Start : r.anchor == "end" ? TextAnchor::End : TextAnchor::Middle;
        auto outline = outline_text(r.text, r.font, 1.0f, anchor, r.letterSpacing, r.lineSpacing);
        if (!outline.ok()) return outline.error();
        ModelTextOutline out;
        out.cmds.reserve(outline->cmds.size());
        for (const TextOutlineCmd& c : outline->cmds) {
            ModelGlyphCmd m;
            m.kind = static_cast<ModelGlyphCmd::Kind>(c.kind);
            m.x = c.x;
            m.y = c.y;
            m.cx = c.cx;
            m.cy = c.cy;
            m.dx = c.dx;
            m.dy = c.dy;
            out.cmds.push_back(m);
        }
        out.glyphs = outline->glyphs;
        out.missing = outline->missing;
        return out;
    };
    return options;
}

std::string model_document_output(const ModelDoc& doc, const std::string& relIn) {
    if (!doc.outputPath.empty()) return normalized(doc.outputPath);
    const std::string rel = normalized(relIn);
    if (ends_with(rel, kModelDocSuffix)) return rel.substr(0, rel.size() - std::strlen(kModelDocSuffix)) + ".glb";
    const auto dot = rel.rfind('.');
    return (dot == std::string::npos ? rel : rel.substr(0, dot)) + ".glb";
}

const char* model_bake_state_name(ModelBakeState state) {
    switch (state) {
        case ModelBakeState::Fresh: return "fresh";
        case ModelBakeState::Missing: return "missing";
        case ModelBakeState::Stale: return "stale";
        case ModelBakeState::Unrecorded: return "unrecorded";
        case ModelBakeState::Broken: return "broken";
    }
    return "";
}

ModelBakeStatus model_bake_status(const std::string& projectDir, const std::string& relIn) {
    ModelBakeStatus status;
    const std::string rel = normalized(relIn);
    ModelDoc doc;
    if (!load_for_bake(projectDir, rel, doc, status)) return status;
    auto file = resolve_project_path(projectDir, status.output);
    std::error_code ec;
    if (!file.ok() || !stdfs::is_regular_file(*file, ec)) {
        status.state = ModelBakeState::Missing;
        status.reason = "'" + status.output + "' has not been baked yet.";
        return status;
    }
    const Json recipe = assets_detail::recipe_of(manifest_entry(projectDir, status.output));
    if (recipe.is_null() || recipe.value("command", std::string()) != kBakeCommand || recipe["args"].value("path", std::string()) != rel) {
        status.state = ModelBakeState::Unrecorded;
        status.reason = "'" + status.output + "' exists, but assets.json does not say it was baked from '" + rel + "'.";
        return status;
    }
    const assets_detail::RecipeCheck check = assets_detail::check_recipe(projectDir, recipe);
    if (!check.changed.empty() || !check.missing.empty()) {
        status.state = ModelBakeState::Stale;
        status.reason = !check.changed.empty() ? "changed since the bake: " + join(check.changed, ", ") : "no longer readable: " + join(check.missing, ", ");
        return status;
    }
    status.state = ModelBakeState::Fresh;
    status.reason = "'" + status.output + "' matches the document and the files it reads.";
    return status;
}

Result<ModelBakeResult> bake_model_document(const std::string& projectDir, const std::string& relIn, const ModelBakeOptions& options) {
    const std::string rel = normalized(relIn);
    if (!ends_with(rel, kModelDocSuffix))
        return make_error("'" + rel + "' is not a model document (its name must end in " + kModelDocSuffix + ").", "Name it like \"assets/models/door.model.json\".");
    ModelDoc doc;
    ModelBakeStatus status;
    if (!load_for_bake(projectDir, rel, doc, status)) return make_error(status.reason, status.hint);
    ModelBakeResult result;
    result.document = rel;
    result.output = status.output;
    if (options.onlyIfNeeded && model_bake_status(projectDir, rel).state == ModelBakeState::Fresh) return result;
    if (!starts_with(result.output, "assets/"))
        return make_error(rel + ": the model would be written to '" + result.output + "', outside assets/.", "Put it under assets/, e.g. \"output\": {\"path\": \"assets/models/door.glb\"}.");

    auto outPath = resolve_project_path(projectDir, result.output);
    if (!outPath.ok()) return make_error(outPath.error().message, outPath.error().hint);
    if (!options.overwrite) {
        std::error_code ec;
        if (stdfs::exists(*outPath, ec)) {
            const Json recipe = assets_detail::recipe_of(manifest_entry(projectDir, result.output));
            if (recipe.is_null() || recipe.value("command", std::string()) != kBakeCommand)
                return make_error("'" + result.output + "' already exists and was not baked by a model document.", "Pass overwrite: true to replace it, or set another \"output\": {\"path\"} in the document.");
        }
    }

    ProjectRootGuard root(projectDir);
    auto build = evaluate_model(doc, model_project_eval_options());
    if (!build.ok()) return make_error(rel + ": " + build.error().message, build.error().hint);
    auto bytes = mesh_to_glb(build->data, result.output);
    if (!bytes.ok()) return make_error(rel + ": cannot write '" + result.output + "': " + bytes.error().message, bytes.error().hint);
    result.sha256 = sha256_hex(bytes->data(), bytes->size());
    result.bytes = bytes->size();

    std::vector<std::string> inputs = {rel};
    for (const std::string& s : build->inputs)  // sorted, unique
        if (s != rel) inputs.push_back(s);
    result.inputs = inputs;

    // who made the pieces: AI-made textures or fonts make the model AI-made, and their licenses travel
    bool ai = false;
    std::set<std::string> licenses, authors;
    for (const std::string& input : build->inputs) {
        const Json entry = manifest_entry(projectDir, input);
        const Json prov = entry.is_object() ? entry.value("provenance", Json()) : Json();
        if (!prov.is_object()) continue;
        ai = ai || prov.value("ai", false);
        if (prov.contains("license") && prov["license"].is_string()) licenses.insert(prov["license"].get<std::string>());
        if (prov.contains("author") && prov["author"].is_string()) authors.insert(prov["author"].get<std::string>());
    }

    try {
        assets_detail::require_usable_manifest(projectDir);
        const Json previous = manifest_entry(projectDir, result.output);
        const Json previousProv = previous.is_object() ? previous.value("provenance", Json()) : Json();
        std::string err;
        bool same = false;
        const std::string_view view(reinterpret_cast<const char*>(bytes->data()), bytes->size());
        if (auto old = tooling_detail::read_file(*outPath)) same = *old == view;
        if (!same && !tooling_detail::write_file(*outPath, view, &err)) return make_error("Cannot write '" + result.output + "': " + err, "Check that the folder is writable.");
        result.written = true;

        const bool madeHere = previousProv.is_object() && previousProv.value("provider", std::string()) == "factoria model.bake";
        std::string license = licenses.empty() ? "CC0-1.0" : join(std::vector<std::string>(licenses.begin(), licenses.end()), "; ");
        if (madeHere && previousProv.contains("license") && previousProv["license"].is_string()) license = previousProv["license"].get<std::string>();
        std::string author = authors.empty() ? "factoria" : join(std::vector<std::string>(authors.begin(), authors.end()), "; ");
        if (madeHere && previousProv.contains("author") && previousProv["author"].is_string()) author = previousProv["author"].get<std::string>();
        std::vector<std::string> partNames;
        for (const ModelPartInfo& p : build->parts)
            if (!p.part.empty() && std::find(partNames.begin(), partNames.end(), p.part) == partNames.end()) partNames.push_back(p.part);
        std::string notes = std::format("Built from the model document '{}': {} triangles, {} submesh{}", rel, build->stats.triangles, build->parts.size(), build->parts.size() == 1 ? "" : "es");
        if (!partNames.empty()) notes += "; parts: " + join(partNames, ", ");
        notes += ".";
        Json prov = Json::object({{"origin", ai ? "generated" : "original"},
                                  {"ai", ai},
                                  {"kind", "model3d"},
                                  {"provider", "factoria model.bake"},
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
        if (!updated.ok()) return make_error("The model was written, but assets.json was not updated: " + updated.error().message, updated.error().hint);
    } catch (const CommandError& e) {
        return make_error(e.what(), e.hint);
    }
    result.build = std::move(*build);
    return result;
}

std::vector<std::string> list_model_documents(const std::string& projectDir) {
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
        if (ends_with(name, kModelDocSuffix)) out.push_back(rel);
    }
    std::sort(out.begin(), out.end());
    return out;
}

Result<std::vector<ModelBakeResult>> bake_model_documents_if_needed(const std::string& projectDir) {
    std::vector<ModelBakeResult> baked;
    for (const std::string& rel : list_model_documents(projectDir)) {
        if (model_bake_status(projectDir, rel).state == ModelBakeState::Fresh) continue;
        auto r = bake_model_document(projectDir, rel, {false, false});
        if (!r.ok()) return make_error(r.error().message, r.error().hint);
        baked.push_back(std::move(*r));
    }
    return baked;
}

}  // namespace fa
