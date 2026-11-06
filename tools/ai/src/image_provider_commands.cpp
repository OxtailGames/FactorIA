// image.inpaint and image.generate_layer: a picture from the image provider becomes a `provider` layer of an image document.
// Docs: docs/IMAGES.md, "Pictures from a provider"; docs/AI_PROVIDERS.md, "Asset providers".
#include "fa/ai/image_provider.h"

#include <algorithm>
#include <format>
#include <memory>
#include <optional>

#include "asset_commands.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/tooling/pixel_art.h"
#include "util.h"

namespace fa::ai {

namespace {

using namespace util;
using asset_support::ProjectScope;

constexpr int kMinSentSide = 512;    // a picture smaller than this is magnified before it is sent (a 32x32 canvas says nothing to a model)
constexpr int kMaxSentSide = 2048;

[[noreturn]] void invalid(const std::string& pointer, const std::string& what, const std::string& hint) {
    throw CommandError("invalid_argument", "/" + pointer + ": " + what, hint);
}

void check_keys(const Json& args, const char* command, const std::vector<std::string>& allowed) {
    if (!args.is_object()) throw CommandError("invalid_argument", std::string(command) + ": the arguments must be an object", "Example: {\"path\":\"assets/art/hero.image.json\",\"prompt\":\"...\"}.");
    for (auto it = args.begin(); it != args.end(); ++it) {
        if (std::find(allowed.begin(), allowed.end(), it.key()) != allowed.end()) continue;
        throw CommandError("invalid_argument", std::string(command) + " /" + it.key() + ": unknown argument", fa::did_you_mean(it.key(), allowed) + " Arguments: " + fa::join(allowed, ", ") + ".");
    }
}

// What to do without a provider, with the exact commands for this document.
std::string offline_route(const ImageEditInput& in, bool inpaint, const std::string& command) {
    const std::string doc = in.doc, sel = in.selection.empty() ? "<selection>" : in.selection;
    if (inpaint)
        return "Offline and free, inside the selection '" + sel + "': image.edit {\"path\":\"" + doc + "\",\"selection\":\"" + sel +
               "\",\"layer\":\"<pixels layer>\",\"action\":{\"type\":\"fill\",\"color\":\"#6a8a5a\"}} fills it (actions: fill, recolor, move, transform, delete, copy, cut), "
               "image.paint {\"path\":\"" + doc + "\",\"layer\":\"<pixels layer>\",\"selection\":\"" + sel + "\",\"strokes\":[...]} paints strokes that stay inside it, "
               "and for pixel art image.draw / image.pixel with `selection`. A texture fits too: assets.generate_texture {\"path\":\"assets/tex/patch.png\",...} then image.layer.add "
               "with a `pixels` layer and a `pixels` mask of the selection.";
    (void)command;
    return "Offline and free: assets.generate_texture {\"path\":\"assets/tex/patch.png\",\"kind\":\"stone\"} makes tileable surfaces and assets.rasterize_svg turns an SVG you write into a PNG; "
           "add either to '" + doc + "' with image.layer.add {\"layer\":{\"kind\":\"pixels\",\"source\":\"assets/tex/patch.png\"}}, or draw the layer yourself with kind `svg`, `gradient`, "
           "`procedural` or `text` (docs.read IMAGES). Everything stays editable, and no provider is needed.";
}

[[noreturn]] void no_provider(const Error& e, const ImageEditInput& in, bool inpaint, const std::string& command) {
    throw CommandError("no_provider", e.message,
                       e.hint + "\nConfigure one in ai.json (in the editor: AI Settings, docs/AI_PROVIDERS.md). The provider must be able to make images" + (inpaint ? " AND repaint part of one (inpainting): the built-in openai provider (OPENAI_API_KEY), the fake provider "
                                                                                          "for trying the flow, or an asset-command provider whose argv has {input} and {mask}. See docs/AI_PROVIDERS.md, \"Asset providers\"." : ".") +
                           "\n" + offline_route(in, inpaint, command));
}

Image magnified(const Image& src, int k) {
    if (k <= 1) return src;
    Image out;
    out.width = src.width * k;
    out.height = src.height * k;
    out.rgba.resize(static_cast<std::size_t>(out.width) * out.height * 4);
    for (int y = 0; y < out.height; ++y)
        for (int x = 0; x < out.width; ++x)
            std::copy_n(&src.rgba[(static_cast<std::size_t>(y / k) * src.width + x / k) * 4], 4, &out.rgba[(static_cast<std::size_t>(y) * out.width + x) * 4]);
    return out;
}

std::string png_bytes(const Image& img) {
    const std::vector<std::uint8_t> png = encode_png(img);
    return std::string(png.begin(), png.end());
}

// Whole pixels from `value`, or the canvas size when it is absent. `key` for messages.
int size_member(const Json& obj, const char* key, int def, const std::string& pointer) {
    const Json* v = child(obj, key);
    if (!v || v->is_null()) return def;
    if (!v->is_number_integer() || v->get<long long>() < 8 || v->get<long long>() > 4096)
        invalid(pointer + "/" + key, "must be a whole number from 8 to 4096, got " + describe_json_value(*v) + ".", "Example: \"size\":{\"width\":128,\"height\":96}.");
    return int(v->get<long long>());
}

}  // namespace

ImageEditPlan plan_image_edit(const ImageEditEnv& env, bool inpaint, const Json& args) {
    const std::string command = inpaint ? "image.inpaint" : "image.generate_layer";
    const char* cmd = command.c_str();
    check_keys(args, cmd,
               inpaint ? std::vector<std::string>{"path", "selection", "selectionName", "prompt", "layer", "frame", "name", "seed", "references", "style", "provider",
                                                   "model", "quantize", "dryRun", "approved", "author", "bake"}
                       : std::vector<std::string>{"path", "prompt", "selection", "selectionName", "size", "placement", "name", "transparent", "seed", "references",
                                                  "style", "provider", "model", "quantize", "dryRun", "approved", "author", "bake"});
    if (env.projectDir.empty())
        throw CommandError("no_project", "There is no project folder to work in", "Run from a project folder (the one with project.json) or pass --project to the factoria CLI.");
    ProjectScope scope(env.projectDir);
    ImageEditPlan plan;
    plan.inpaint = inpaint;
    plan.command = command;
    plan.args = args;

    std::string prompt = str(args, "prompt");
    if (prompt.find_first_not_of(" \t\r\n") == std::string::npos)
        throw CommandError("invalid_argument", "'prompt' is empty", inpaint ? "Say what the selection should become, e.g. \"a mossy stone arch\"." : "Say what to draw, e.g. \"a flickering torch, side view\".");

    // the document, the selection and the picture
    ImageEditInput in = image_edit_input(env.projectDir, args, inpaint, inpaint, cmd);
    plan.doc = in.doc;
    plan.selection = in.selection;
    plan.canvasWidth = in.width;
    plan.canvasHeight = in.height;
    plan.warnings = in.warnings;
    if (in.animated && !args.contains("frame") && inpaint)
        plan.warnings.push_back("The document is animated; the picture sent is frame 0 and the new layer shows in every frame (pass `frame` to choose the frame that is sent).");
    else if (in.animated)
        plan.warnings.push_back("The new layer shows in every frame of the animated document.");

    // layer name
    const std::string base = inpaint ? "inpaint" : "generated";
    const std::string wanted = str(args, "name");
    plan.layerName = image_unique_layer_name(env.projectDir, in.doc, wanted.empty() ? base : wanted);
    if (!wanted.empty() && plan.layerName != wanted)
        throw CommandError("invalid_argument", "/name: a layer named '" + wanted + "' exists already", "Layer names are distinct because they address layers: use '" + plan.layerName + "' or remove the old layer.");

    // quantize
    plan.quantize = in.palette;
    if (const Json* q = child(args, "quantize"); q && q->is_boolean()) {
        if (q->get<bool>() && !in.palette)
            invalid("quantize", "the document has no palette to reduce the picture to.", "Give the document a palette (image.palette {\"palette\":[...]}) or leave `quantize` out.");
        plan.quantize = q->get<bool>();
    }
    plan.colours = in.colours;

    // provider
    auto cfgResult = env.load ? env.load() : Result<AiConfig>(make_error("No configuration loader", ""));
    if (!cfgResult) throw CommandError("invalid_config", cfgResult.error().message, cfgResult.error().hint);
    const AiConfig cfg = std::move(*cfgResult);
    auto target = resolve_asset_target(cfg, MediaKind::Image, str(args, "provider"), str(args, "model"), {}, env.runtime.env);
    if (!target) no_provider(target.error(), in, inpaint, command);
    if (inpaint && !asset_can_inpaint(*target->provider)) {
        std::vector<std::string> able;
        for (const auto& [name, p] : cfg.providers)
            if (provider_makes(p.kind, MediaKind::Image) && asset_can_inpaint(p)) able.push_back(name);
        no_provider(Error{"Provider '" + target->provider->name + "' (" + provider_kind_name(target->provider->kind) + ") makes images but cannot inpaint (repaint part of a picture)",
                          "Providers that can: " + (able.empty() ? std::string("none configured") : fa::join(able, ", ")) +
                              ". An asset-command provider can if its argv has {input} and {mask}. Pass `provider` to use one, or route assets.image to it in ai.json."},
                    in, true, command);
    }
    plan.provider = *target->provider;
    plan.limits = cfg.limits;

    // the request
    const asset_support::Style style = flag(args, "style", true) ? asset_support::load_house_style() : asset_support::Style{};
    AssetRequest& req = plan.request;
    req.kind = MediaKind::Image;
    req.prompt = style.prompt.empty() ? prompt : prompt + "\n\nStyle: " + style.prompt;
    req.model = target->model;
    if (const Json* seed = child(args, "seed"); seed && seed->is_number_integer()) req.seed = seed->get<i64>();
    std::vector<std::string> refs;
    if (const Json* r = child(args, "references"); r && r->is_array())
        for (const Json& v : *r)
            if (v.is_string()) refs.push_back(v.get<std::string>());
    refs.insert(refs.end(), style.references.begin(), style.references.end());
    plan.referencePaths = asset_support::normalized_unique_paths(refs);
    req.references = asset_support::load_reference_images(plan.referencePaths);

    if (inpaint) {
        const int longest = std::max(in.width, in.height);
        plan.sendScale = longest >= kMinSentSide ? 1 : std::min((kMinSentSide + longest - 1) / longest, std::max(1, kMaxSentSide / longest));
        plan.layerWidth = in.width;
        plan.layerHeight = in.height;
        const Image picture = magnified(in.picture, plan.sendScale);
        Image grey;
        grey.width = in.width;
        grey.height = in.height;
        grey.rgba.resize(static_cast<std::size_t>(in.width) * in.height * 4);
        for (std::size_t i = 0; i < in.mask.size(); ++i) {
            grey.rgba[i * 4] = grey.rgba[i * 4 + 1] = grey.rgba[i * 4 + 2] = in.mask[i];
            grey.rgba[i * 4 + 3] = 255;
        }
        req.editImage = png_bytes(picture);
        req.editMask = png_bytes(magnified(grey, plan.sendScale));
        req.width = picture.width;
        req.height = picture.height;
        req.transparent = false;
    } else {
        const Json* size = child(args, "size");
        if (size && !size->is_object()) invalid("size", "expected {\"width\":..,\"height\":..}, got " + describe_json_value(*size) + ".", "Example: \"size\":{\"width\":128,\"height\":96}; leave it out for the whole canvas.");
        plan.layerWidth = size ? size_member(*size, "width", in.width, "size") : in.width;
        plan.layerHeight = size ? size_member(*size, "height", in.height, "size") : in.height;
        // placement: "fill" (the canvas, default without a size), "center" (default with a size), or {x, y}
        const Json* placement = child(args, "placement");
        std::string mode = !size ? "fill" : "center";
        if (placement && placement->is_string()) mode = placement->get<std::string>();
        if (placement && placement->is_object()) {
            mode = "xy";
            plan.x = int(num(*placement, "x", 0));
            plan.y = int(num(*placement, "y", 0));
        } else if (placement && !placement->is_string() && !placement->is_null()) {
            invalid("placement", "expected \"fill\", \"center\" or {\"x\":..,\"y\":..}, got " + describe_json_value(*placement) + ".", "Example: \"placement\":{\"x\":16,\"y\":8}.");
        }
        if (mode == "fill") {
            plan.layerWidth = in.width;
            plan.layerHeight = in.height;
        } else if (mode == "center") {
            plan.x = (in.width - plan.layerWidth) / 2;
            plan.y = (in.height - plan.layerHeight) / 2;
        } else if (mode != "xy") {
            invalid("placement", "unknown placement '" + mode + "'.", "Use \"fill\", \"center\" or {\"x\":..,\"y\":..}.");
        }
        req.width = plan.layerWidth;
        req.height = plan.layerHeight;
        req.transparent = flag(args, "transparent", false);
    }

    // what would be sent, and what it may cost
    plan.cost = estimate_asset_cost(plan.provider, req, 1);
    plan.estimate = Json::object({{"command", command},
                                  {"document", plan.doc},
                                  {"provider", plan.provider.name},
                                  {"providerKind", provider_kind_name(plan.provider.kind)},
                                  {"model", req.model.empty() ? asset_default_model(plan.provider, MediaKind::Image) : req.model},
                                  {"images", 1},
                                  {"sentSize", std::format("{}x{}", req.width, req.height)},
                                  {"layerSize", std::format("{}x{}", plan.layerWidth, plan.layerHeight)},
                                  {"referenceImages", req.references.size()},
                                  {"selection", plan.selection},
                                  {"selectedPixels", in.selectedPixels},
                                  {"quantizeToPalette", plan.quantize},
                                  {"billing", plan.cost.free ? "none: " + plan.cost.basis
                                                            : "one image from '" + plan.provider.name + "': " + plan.cost.basis +
                                                              " (an estimate; the provider's own bill decides). The call is not repeated if it fails after the provider answered"},
                                  {"prompt", req.prompt}});
    const Json estimated = estimate_to_json(plan.cost);
    for (const auto& [key, value] : estimated.items()) plan.estimate[key] = value;
    return plan;
}

AssetCostGuard begin_image_edit_cost(const ImageEditPlan& plan, const ImageEditEnv& env, bool approved, const CancelFlag* cancel) {
    AssetCall call;
    call.command = plan.command;
    call.what = std::format("a {}x{} picture for the layer '{}' of {}", plan.layerWidth, plan.layerHeight, plan.layerName, plan.doc);
    call.prompt = plan.request.prompt;
    call.projectDir = env.projectDir;
    call.provider = plan.provider.name;
    call.model = plan.request.model;
    call.kind = MediaKind::Image;
    call.estimate = plan.cost;
    call.cancel = cancel;
    return AssetCostGuard::begin(plan.limits, call, approved);
}

Result<AssetResult> run_image_edit(const ImageEditPlan& plan, const ProviderRuntime& runtime, const CancelFlag* cancel) {
    return generate_asset(plan.provider, plan.request, runtime, cancel);
}

ImageEditStored store_image_edit(const ImageEditEnv& env, const ImageEditPlan& plan, const AssetResult& made) {
    ProjectScope scope(env.projectDir);
    auto decoded = decode_image(reinterpret_cast<const std::uint8_t*>(made.bytes.data()), made.bytes.size());
    if (!decoded)
        throw CommandError("bad_output", std::format("The provider '{}' returned data that is not an image: {}", plan.provider.name, decoded.error().message),
                           "Check the provider and model with ai.providers (action doctor).");
    Image image = std::move(*decoded);
    std::string notes = plan.inpaint ? "Inpainting of " + (plan.selection.empty() ? std::string("the picture") : "selection '" + plan.selection + "'") +
                                           " in " + plan.doc + "."
                                     : "Generated layer for " + plan.doc + ".";
    ImageEditStored out;
    if (image.width != plan.layerWidth || image.height != plan.layerHeight) {
        notes += std::format(" Resized from {}x{} to {}x{}.", image.width, image.height, plan.layerWidth, plan.layerHeight);
        if (!plan.quantize) image = resize_image(image, plan.layerWidth, plan.layerHeight);
    }
    if (plan.quantize) {
        PixelPalette pal;
        for (const auto& rgb : plan.colours) pal.entries.push_back({"", rgb});
        image = index_grid_image(pixel_dominant_downscale(image, pal, plan.layerWidth, plan.layerHeight, 0.5), pal);
        notes += std::format(" Reduced to the {} colours of the document's palette.", pal.size());
    }
    const std::string source = image_provider_source_path(env.projectDir, plan.doc, plan.layerName);
    const std::string bytes = png_bytes(image);
    if (auto w = fs::write_bytes(source, bytes.data(), bytes.size()); !w) throw CommandError("write_failed", w.error().message, w.error().hint);

    if (!plan.request.references.empty() && !made.usedReferences)
        out.warnings.push_back(std::format("The provider '{}' cannot take reference images, so the {} reference(s) were not sent (the style prompt was).", plan.provider.name, plan.request.references.size()));
    if (plan.request.seed && !made.seed) out.warnings.push_back(std::format("The provider '{}' takes no seed; it was ignored.", plan.provider.name));

    const std::vector<std::string> refs = made.usedReferences ? plan.referencePaths : std::vector<std::string>();
    const Json provenance = asset_support::image_provenance(plan.args, plan.provider, made, plan.request.prompt, refs, notes);
    asset_support::record_provenance(source, provenance);

    // what the layer carries (the keys a provider record allows)
    Json layerProv = Json::object({{"provider", plan.provider.name}});
    for (const char* k : {"model", "prompt", "seed", "references", "license", "author", "notes"}) {
        if (std::string(k) == "notes") layerProv[k] = notes;
        else if (provenance.contains(k)) layerProv[k] = provenance[k];
    }
    out.addArgs = Json::object({{"path", plan.doc}, {"source", source}, {"name", plan.layerName}, {"provenance", layerProv}});
    if (!plan.selection.empty()) out.addArgs["selection"] = plan.selection;
    if (plan.x) out.addArgs["x"] = plan.x;
    if (plan.y) out.addArgs["y"] = plan.y;
    if (plan.args.contains("bake") && plan.args["bake"].is_boolean()) out.addArgs["bake"] = plan.args["bake"];
    out.warnings.insert(out.warnings.begin(), plan.warnings.begin(), plan.warnings.end());
    out.details = Json::object({{"source", source}, {"width", image.width}, {"height", image.height}, {"provenance", provenance}});
    return out;
}

void register_image_provider_commands(CommandRegistry& registry, std::function<Result<AiConfig>()> load, std::function<std::string()> projectDir,
                                      ProviderRuntime runtime, const CancelFlag* cancel, std::string runKey,
                                      AssetApprover approver) {
    struct Shared {
        std::function<Result<AiConfig>()> load;
        std::function<std::string()> projectDir;
        ProviderRuntime runtime;
        const CancelFlag* cancel;
        std::string runKey;
        AssetApprover approver;
    };
    auto shared = std::make_shared<Shared>(Shared{std::move(load), std::move(projectDir), std::move(runtime), cancel, std::move(runKey), std::move(approver)});
    auto add = [&](const char* name, const char* summary, const std::string& description, const std::string& properties, const char* required, bool inpaint) {
        CommandInfo info;
        info.name = name;
        info.category = "assets";
        info.readOnly = false;
        info.summary = summary;
        info.description = description;
        info.inputSchema = Json::parse(std::string(R"({"type":"object","required":)") + required + R"(,"additionalProperties":false,"properties":{)" + properties + "}}");
        registry.add(std::move(info), [shared, inpaint](const Json& args) -> Json {
            const ImageEditEnv env{shared->load, shared->projectDir(), shared->runtime};
            std::optional<AssetRunScope> run;
            if (!shared->runKey.empty() || shared->approver) run.emplace(shared->runKey.empty() ? asset_run_key() : shared->runKey, shared->approver);
            ImageEditPlan plan = plan_image_edit(env, inpaint, args);
            if (flag(args, "dryRun", false)) {
                return Json::object({{"dryRun", true}, {"sent", false}, {"estimate", plan.estimate}, {"warnings", plan.warnings},
                                     {"next", "Nothing was sent or paid for. Call again without dryRun to make the picture."}});
            }
            AssetCostGuard guard = begin_image_edit_cost(plan, env, flag(args, "approved"), shared->cancel);
            if (!guard.go()) return guard.needs_approval();
            auto made = run_image_edit(plan, env.runtime, shared->cancel);
            if (!made) throw CommandError("generation_failed", made.error().message, made.error().hint);
            guard.commit();
            ImageEditStored stored = store_image_edit(env, plan, *made);
            ProjectScope scope(env.projectDir);
            Json out = image_layer_add_provider(env.projectDir, stored.addArgs);
            Json warnings = out.contains("warnings") ? out["warnings"] : Json::array();
            for (const std::string& w : stored.warnings) warnings.push_back(w);
            for (const std::string& w : guard.warnings()) warnings.push_back(w);
            if (!warnings.empty()) out["warnings"] = warnings;
            const Json cost = guard.cost_json();
            for (const auto& [key, value] : cost.items()) out[key] = value;
            out["generated"] = stored.details;
            out["provider"] = plan.provider.name;
            out["estimate"] = plan.estimate;
            out["next"] = std::string("The picture is the `provider` layer '") + plan.layerName + "' (AI-made, with its provenance). Look at it in `$image`; image.layer.set changes its "
                          "opacity, blend or masks, image.layer.remove drops it, and nothing regenerates it unless you call " + plan.command + " again.";
            return out;
        });
    };
    const std::string common = R"J(
      "path":{"type":"string","description":"The image document, project-relative, ending in .image.json."},
      "prompt":{"type":"string","description":"What to draw."},
      "name":{"type":"string","description":"Name of the new layer (distinct). Default: inpaint / generated, then numbered."},
      "provider":{"type":"string","description":"Asset provider to use instead of the one ai.json assigns to images (a name from ai.providers, e.g. \"fake\" to try the flow offline)."},
      "model":{"type":"string","description":"Model to use instead of the one in ai.json."},
      "seed":{"type":"integer","description":"Seed, for providers that take one (fake, asset-command with {seed}); recorded in the layer's provenance. Others ignore it with a warning."},
      "references":{"type":"array","items":{"type":"string"},"description":"Project-relative images the result should follow, in addition to style.references of assets.json."},
      "style":{"type":"boolean","default":true,"description":"Apply the house style of assets.json (style.prompt, style.references). false skips it for this call."},
      "quantize":{"type":"boolean","description":"Reduce the picture to the document's palette. Default: true when the document has a palette (an indexed document), else false."},
      "dryRun":{"type":"boolean","default":false,"description":"Only check the call and return what would be sent and what it may cost. Sends nothing, writes nothing."},
      "approved":{"type":"boolean","default":false,"description":"The USER said yes to this paid call, after a needsApproval answer showed them the plan and the estimate. Never set it unless the user approved this call in this conversation; the fake provider and local programs never need it."},
      "author":{"type":"string","description":"Who gets the credit in the provenance record. Default: \"factoria\"."},
      "bake":{"type":"boolean","default":true,"description":"Also draw the PNG of the document (default true)."})J";
    add("image.inpaint", "Repaint the selected part of an image document with the image provider and add the result as a masked `provider` layer.",
        "Sends the picture of the document (its composite, or `layer` alone, at `frame`) and the selection as the mask to an image provider that can inpaint, and adds what it "
        "paints as a new `provider` layer over the whole canvas whose mask is the selection (with the selection's feather), so the rest of the picture is untouched and the layer "
        "can be hidden, moved or removed. `selection` is the name of a stored selection (image.select; \"all\" is the whole canvas) or an object with the arguments of image.select "
        "(stored as `selectionName`, default \"inpaint\"). The layer carries the provider's provenance (provider, model, prompt, seed, references, license) and is recorded in "
        "assets.json; the baked picture counts as AI-made. In a document with a palette the result is reduced to it (pixel_dominant_downscale: palette colours only, no blends). A picture "
        "smaller than 512 px is magnified by whole pixels before it is sent, and the answer is resized back. Providers that can inpaint: the built-in openai (OPENAI_API_KEY), fake "
        "(placeholder pattern, free, offline) and asset-command providers whose argv has {input} and {mask}. Without one the error says how to configure it (docs/AI_PROVIDERS.md) "
        "and the offline route with exact commands. The call is synchronous and costs what the provider charges for one image: `dryRun` shows what would be sent and the estimate. " + std::string(asset_cost_doc()) + " A provider layer "
        "is never regenerated by itself: call this again for another try. "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"selection\":\"sky\",\"prompt\":\"a stormy sky with a red moon\",\"seed\":7}",
        common + R"J(,
      "selection":{"description":"The part to repaint: the name of a stored selection (image.select), \"all\", or an object with the arguments of image.select (by, x, y, width, height, color, ...)."},
      "selectionName":{"type":"string","description":"Name an inline selection is stored under (default \"inpaint\")."},
      "layer":{"description":"Send only this layer (name or index path) instead of the whole composite."},
      "frame":{"type":"integer","minimum":0,"description":"The frame of an animated document the picture is of (default 0). The new layer shows in every frame."})J",
        R"(["path","selection","prompt"])", true);
    add("image.generate_layer", "Generate a picture with the image provider and add it to an image document as a `provider` layer, optionally masked by a selection.",
        "Draws `prompt` with the image provider and adds the picture as a `provider` layer: the whole canvas by default, or `size` {width,height} at `placement` (\"center\" when a size is "
        "given, \"fill\", or {x,y}). `selection` (a stored selection, \"all\", or an inline image.select object) masks the layer so it shows only there. The layer carries the "
        "provider's provenance and is recorded in assets.json; the baked picture counts as AI-made. `transparent` asks for a transparent background (sprites, props). In a document "
        "with a palette the result is reduced to it. Any image provider works (openai, fake, asset-command); without one the error says how to configure it (docs/AI_PROVIDERS.md) "
        "and the offline route with exact commands. The call is synchronous and costs what the provider charges for one image: `dryRun` shows what would be sent and the estimate. " + std::string(asset_cost_doc()) + " A provider layer is "
        "never regenerated by itself. "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"prompt\":\"a brass key, side view\",\"size\":{\"width\":64,\"height\":64},\"placement\":{\"x\":10,\"y\":4},\"transparent\":true}",
        common + R"J(,
      "selection":{"description":"Show the layer only inside this selection: a stored name (image.select), \"all\", or an inline object with the arguments of image.select."},
      "selectionName":{"type":"string","description":"Name an inline selection is stored under (default \"inpaint\")."},
      "size":{"type":"object","description":"Size of the picture in pixels, {\"width\":..,\"height\":..} (8 to 4096). Default: the canvas.","properties":{"width":{"type":"integer"},"height":{"type":"integer"}}},
      "placement":{"description":"Where it goes: \"fill\" (the canvas), \"center\" (default with a size), or {\"x\":..,\"y\":..} for the top-left corner."},
      "transparent":{"type":"boolean","default":false,"description":"Ask for a transparent background."})J",
        R"(["path","prompt"])", false);
}

}  // namespace fa::ai
