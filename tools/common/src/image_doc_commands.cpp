// The image.* commands: image.bake (draw a document into its PNG) and image.save (check, write and bake a document). The
// commands of M52.3 (image.create, image.layer.*, ...) edit the document and call save_image_document the same way.
#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/project_fs.h"
#include "image_doc_internal.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

Json result_json(const std::string& projectDir, const ImageBakeResult& r) {
    Json out = Json::object({{"document", r.document}, {"path", r.output}, {"width", r.width}, {"height", r.height}, {"written", r.written}, {"ai", r.ai}});
    if (!r.sha256.empty()) out["sha256"] = r.sha256;
    if (!r.inputs.empty()) out["inputs"] = r.inputs;
    if (!r.provenance.is_null()) out["provenance"] = r.provenance;
    if (!r.warnings.empty()) out["warnings"] = r.warnings;
    auto png = resolve_project_path(projectDir, r.output);
    std::error_code ec;
    if (png.ok() && std::filesystem::is_regular_file(*png, ec)) out["$image"] = Json::object({{"path", png->string()}, {"mimeType", "image/png"}});
    out["nextSteps"] = Json::array({"Look at the picture in this result. To change it, edit the layers of '" + r.document + "' and call image.bake again.",
                                    "Use it as a Sprite texture: Sprite.texture \"" + r.output + "\"."});
    return out;
}

void unwrap_error(const Error& e) { fail("invalid_argument", e.message, e.hint); }

Json image_bake(const std::string& projectDir, const Json& a) {
    check_arg_keys("image.bake", a, "", {"path", "onlyIfNeeded"});
    const std::string rel = tooling_detail::arg_string(a, "path", true);
    ImageBakeOptions options;
    options.onlyIfNeeded = tooling_detail::arg_bool(a, "onlyIfNeeded", false);
    auto r = bake_image_document(projectDir, rel, options);
    if (!r.ok()) unwrap_error(r.error());
    Json out = result_json(projectDir, *r);
    if (!r->written) out["note"] = "The picture was already current, so nothing was drawn (onlyIfNeeded).";
    return out;
}

Json image_save(const std::string& projectDir, const Json& a) {
    check_arg_keys("image.save", a, "", {"path", "document", "bake"});
    const std::string rel = tooling_detail::arg_string(a, "path", true);
    if (!a.contains("document") || !a["document"].is_object())
        arg_error("image.save", "/document", "expected the image document as an object.",
                  "Example: {\"path\":\"assets/art/sky.image.json\",\"document\":{\"width\":128,\"height\":128,\"layers\":[{\"kind\":\"gradient\",\"gradient\":{\"stops\":[{\"at\":0,\"color\":\"#102040\"},{\"at\":1,\"color\":\"#e08040\"}]}}]}}");
    auto r = save_image_document(projectDir, rel, a["document"], tooling_detail::arg_bool(a, "bake", true));
    if (!r.ok()) unwrap_error(r.error());
    return result_json(projectDir, *r);
}

}  // namespace

void register_image_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = "image.bake";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Draw a layered image document (*.image.json) into its PNG and return the picture.";
        info.description =
            "Composites the layers of the image document at `path` (project-relative, ending in .image.json) on the CPU and writes the PNG next to it "
            "(hero.image.json -> hero.png, or the document's `output`). Bytes are deterministic: the same document and files give the same PNG. "
            "Records provenance and the recipe {command image.bake, args {path}, inputs: the document and every file it reads} in assets.json, so "
            "assets.regenerate remakes the PNG and `factoria validate` warns when the document or a source file changed since (stale). "
            "A picture with a provider layer, or built from AI-made files, is recorded as AI-made. The result has the picture as `$image`, its size and any warnings. "
            "A problem in the document is an error with the file, the JSON pointer and a fix. Format and layers: docs.read IMAGES. "
            "Example: {\"path\":\"assets/art/hero.image.json\"}";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["path"],
          "properties":{
            "path":{"type":"string","description":"The image document, project-relative, ending in .image.json, e.g. \"assets/art/hero.image.json\"."},
            "onlyIfNeeded":{"type":"boolean","default":false,"description":"Skip the drawing when the PNG already matches the document and every file it reads (what the export does)."}
          }})");
        registry.add(info, [projectDir](const Json& args) { return image_bake(projectDir, args); });
    }
    {
        CommandInfo info;
        info.name = "image.save";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Check an image document, write it to a *.image.json file and bake its PNG; nothing is written when the document has a problem.";
        info.description =
            "Validates `document` (the layered image document as JSON: canvas width and height, background, layers bottom first; see docs.read IMAGES), "
            "writes it to `path` (project-relative, ending in .image.json) as canonical JSON and bakes the PNG like image.bake. A problem in the "
            "document is an error naming the JSON pointer (/layers/2/blend), what is wrong and how to fix it, and writes nothing. "
            "Example: {\"path\":\"assets/art/sky.image.json\",\"document\":{\"width\":128,\"height\":128,\"layers\":[{\"kind\":\"gradient\","
            "\"gradient\":{\"angle\":0,\"stops\":[{\"at\":0,\"color\":\"#102040\"},{\"at\":1,\"color\":\"#e08040\"}]}},{\"kind\":\"text\",\"text\":\"Hi\",\"size\":32,\"x\":8,\"y\":8}]}}";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["path","document"],
          "properties":{
            "path":{"type":"string","description":"Where to write the document, project-relative, ending in .image.json."},
            "document":{"type":"object","description":"The image document: {\"width\", \"height\", \"background\"?, \"output\"?, \"layers\": [...]}. See docs.read IMAGES for the layer kinds."},
            "bake":{"type":"boolean","default":true,"description":"Also draw the PNG. False only checks and writes the document."}
          }})");
        registry.add(info, [projectDir](const Json& args) { return image_save(projectDir, args); });
    }
}

}  // namespace fa::assets_detail
