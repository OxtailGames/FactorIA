// Baking an image document: the PNG next to it, its provenance and recipe in assets.json, and the status of a baked document
// (is the PNG current?). "Stale" is the recipe's: the PNG was baked from the document and the files it read as they were; when
// one of them has another SHA-256 now, the PNG is stale (the same check `factoria validate` and the editor already do for every
// made asset, docs/ASSETS.md "Recipes").
#include <algorithm>
#include <cstring>
#include <filesystem>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "image_doc_internal.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;
using assets_detail::ProjectRootGuard;

constexpr const char* kBakeCommand = "image.bake";

bool is_document_path(const std::string& rel) { return ends_with(rel, kImageDocSuffix); }

void collect_providers(const std::vector<ImageLayer>& layers, std::vector<const ImageLayer*>& out) {
    for (const ImageLayer& l : layers) {
        if (l.kind == ImageLayerKind::Provider) out.push_back(&l);
        if (l.kind == ImageLayerKind::Group) collect_providers(l.children, out);
    }
}

std::string normalized(const std::string& rel) {
    auto norm = fs::normalize_checked(rel);
    return norm.ok() && !norm->empty() ? *norm : rel;
}

// The manifest entry of a project file, read from projectDir's assets.json.
Json manifest_entry(const std::string& projectDir, const std::string& rel) {
    ProjectRootGuard root(projectDir);
    return assets::entry(rel);
}

}  // namespace

std::string image_document_output(const ImageDocument& doc, const std::string& rel) {
    if (!doc.output.empty()) return doc.output;
    const std::string norm = normalized(rel);
    if (ends_with(norm, kImageDocSuffix)) return norm.substr(0, norm.size() - std::strlen(kImageDocSuffix)) + ".png";
    const auto dot = norm.rfind('.');
    return (dot == std::string::npos ? norm : norm.substr(0, dot)) + ".png";
}

const char* image_bake_state_name(ImageBakeState state) {
    switch (state) {
        case ImageBakeState::Fresh: return "fresh";
        case ImageBakeState::Missing: return "missing";
        case ImageBakeState::Stale: return "stale";
        case ImageBakeState::Unrecorded: return "unrecorded";
        case ImageBakeState::Broken: return "broken";
    }
    return "";
}

ImageBakeStatus image_bake_status(const std::string& projectDir, const std::string& relIn) {
    ImageBakeStatus status;
    const std::string rel = normalized(relIn);
    auto doc = load_image_document(projectDir, rel);
    if (!doc.ok()) {
        status.state = ImageBakeState::Broken;
        status.reason = doc.error().message;
        return status;
    }
    status.output = image_document_output(*doc, rel);
    auto png = resolve_project_path(projectDir, status.output);
    std::error_code ec;
    if (!png.ok() || !stdfs::is_regular_file(*png, ec)) {
        status.state = ImageBakeState::Missing;
        status.reason = "'" + status.output + "' has not been baked yet.";
        return status;
    }
    const Json recipe = assets_detail::recipe_of(manifest_entry(projectDir, status.output));
    if (recipe.is_null() || recipe.value("command", std::string()) != kBakeCommand || recipe["args"].value("path", std::string()) != rel) {
        status.state = ImageBakeState::Unrecorded;
        status.reason = "'" + status.output + "' exists, but assets.json does not say it was baked from '" + rel + "'.";
        return status;
    }
    const assets_detail::RecipeCheck check = assets_detail::check_recipe(projectDir, recipe);
    if (!check.changed.empty() || !check.missing.empty()) {
        status.state = ImageBakeState::Stale;
        status.reason = !check.changed.empty() ? "changed since the bake: " + join(check.changed, ", ") : "no longer readable: " + join(check.missing, ", ");
        return status;
    }
    status.state = ImageBakeState::Fresh;
    status.reason = "'" + status.output + "' matches the document and the files it reads.";
    return status;
}

Result<ImageBakeResult> bake_image_document(const std::string& projectDir, const std::string& relIn, const ImageBakeOptions& options) {
    const std::string rel = normalized(relIn);
    if (!is_document_path(rel))
        return make_error("'" + rel + "' is not an image document (its name must end in " + kImageDocSuffix + ").", "Name it like \"assets/art/hero.image.json\".");
    auto doc = load_image_document(projectDir, rel);
    if (!doc.ok()) return make_error(doc.error().message, doc.error().hint);
    ImageBakeResult result;
    result.document = rel;
    result.output = image_document_output(*doc, rel);
    result.width = doc->width;
    result.height = doc->height;
    if (options.onlyIfNeeded && image_bake_status(projectDir, rel).state == ImageBakeState::Fresh) return result;

    auto render = composite_image_document(*doc, {projectDir});
    if (!render.ok()) return make_error(render.error().message, render.error().hint);
    result.warnings = render->warnings;

    bool opaque = true;
    for (std::size_t i = 3; i < render->image.rgba.size() && opaque; i += 4) opaque = render->image.rgba[i] == 255;
    const std::vector<std::uint8_t> png = opaque ? encode_png_rgb(render->image) : encode_png(render->image);
    result.sha256 = sha256_hex(png.data(), png.size());

    auto outPath = resolve_project_path(projectDir, result.output);
    if (!outPath.ok()) return make_error(outPath.error().message, outPath.error().hint);

    // who made the pieces: AI-made sources make the baked picture AI-made, and their licenses travel
    std::vector<const ImageLayer*> providers;
    collect_providers(doc->layers, providers);
    result.ai = !providers.empty();
    std::set<std::string> licenses, aiSources;
    for (const std::string& input : render->inputs) {
        const Json entry = manifest_entry(projectDir, input);
        const Json prov = entry.is_object() ? entry.value("provenance", Json()) : Json();
        if (!prov.is_object()) continue;
        if (prov.value("ai", false)) {
            result.ai = true;
            aiSources.insert(input);
        }
        if (prov.contains("license") && prov["license"].is_string()) licenses.insert(prov["license"].get<std::string>());
    }
    for (const ImageLayer* p : providers) aiSources.insert(p->source);

    std::vector<std::string> inputs = {rel};
    inputs.insert(inputs.end(), render->inputs.begin(), render->inputs.end());
    std::sort(inputs.begin() + 1, inputs.end());
    inputs.erase(std::unique(inputs.begin(), inputs.end()), inputs.end());
    result.inputs = inputs;

    try {
        assets_detail::require_usable_manifest(projectDir);
        const Json previous = manifest_entry(projectDir, result.output);
        const Json previousProv = previous.is_object() ? previous.value("provenance", Json()) : Json();
        std::string err;
        bool same = false;
        if (auto old = tooling_detail::read_file(*outPath)) same = *old == std::string_view(reinterpret_cast<const char*>(png.data()), png.size());
        if (!same && !tooling_detail::write_file(*outPath, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err))
            return make_error("Cannot write '" + result.output + "': " + err, "Check that the folder is writable.");
        result.written = true;

        std::string license = "CC0-1.0";
        if (previousProv.is_object() && previousProv.contains("license") && previousProv["license"].is_string()) license = previousProv["license"].get<std::string>();
        else if (!licenses.empty()) license = join(std::vector<std::string>(licenses.begin(), licenses.end()), "; ");
        std::string author = "factoria";
        if (previousProv.is_object() && previousProv.contains("author") && previousProv["author"].is_string()) author = previousProv["author"].get<std::string>();
        std::string notes = std::format("Composited from the image document '{}' ({} layer{}), {}x{}.", rel, doc->layers.size(), doc->layers.size() == 1 ? "" : "s", doc->width, doc->height);
        if (!aiSources.empty()) notes += " Contains AI-made pictures: " + join(std::vector<std::string>(aiSources.begin(), aiSources.end()), ", ") + ".";
        Json prov = Json::object({{"origin", result.ai ? "generated" : "original"},
                                  {"ai", result.ai},
                                  {"kind", "image"},
                                  {"provider", "factoria image.bake"},
                                  {"license", license},
                                  {"author", author},
                                  {"source", rel},
                                  {"notes", notes},
                                  {"date", assets::today()}});
        prov["recipe"] = assets_detail::make_recipe(projectDir, kBakeCommand, Json::object({{"path", rel}}), inputs);
        result.provenance = prov;
        ProjectRootGuard root(projectDir);
        auto updated = assets::update_entry(result.output, [&](Json& e) {
            e.erase("analysis");
            e["provenance"] = prov;
        });
        if (!updated.ok()) return make_error("The picture was written, but assets.json was not updated: " + updated.error().message, updated.error().hint);
        // a provider layer's record: when the picture has none in assets.json yet, the document's goes there
        for (const ImageLayer* p : providers) {
            if (!p->provenance.is_object()) continue;
            const Json entry = assets::entry(p->source);
            if (entry.is_object() && entry.contains("provenance")) continue;
            Json record = p->provenance;
            record["origin"] = "generated";
            record["ai"] = true;
            record["kind"] = "image";
            record["date"] = assets::today();
            (void)assets::update_entry(p->source, [&](Json& e) { e["provenance"] = record; });
        }
    } catch (const CommandError& e) {
        return make_error(e.what(), e.hint);
    }
    return result;
}

Result<ImageBakeResult> save_image_document(const std::string& projectDir, const std::string& relIn, const Json& document, bool bake) {
    const std::string rel = normalized(relIn);
    if (!is_document_path(rel))
        return make_error("'" + rel + "' is not an image document path (it must end in " + kImageDocSuffix + ").", "Name it like \"assets/art/hero.image.json\".");
    auto parsed = parse_image_document(document, rel, projectDir);
    if (!parsed.ok()) return make_error(parsed.error().message + " Nothing was written.", parsed.error().hint);
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) return make_error(path.error().message, path.error().hint);
    std::string err;
    if (!tooling_detail::write_file(*path, dump_json(document), &err)) return make_error("Cannot write '" + rel + "': " + err, "Check that the folder is writable.");
    if (!bake) {
        ImageBakeResult r;
        r.document = rel;
        r.output = image_document_output(*parsed, rel);
        r.width = parsed->width;
        r.height = parsed->height;
        return r;
    }
    return bake_image_document(projectDir, rel);
}

std::vector<std::string> list_image_documents(const std::string& projectDir) {
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
        if (ends_with(name, kImageDocSuffix)) out.push_back(rel);
    }
    std::sort(out.begin(), out.end());
    return out;
}

Result<std::vector<ImageBakeResult>> bake_image_documents_if_needed(const std::string& projectDir) {
    std::vector<ImageBakeResult> baked;
    for (const std::string& rel : list_image_documents(projectDir)) {
        const ImageBakeStatus status = image_bake_status(projectDir, rel);
        if (status.state == ImageBakeState::Fresh) continue;
        auto r = bake_image_document(projectDir, rel);
        if (!r.ok()) return make_error(r.error().message, r.error().hint);
        baked.push_back(std::move(*r));
    }
    return baked;
}

}  // namespace fa
