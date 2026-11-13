// image.create, image.info, image.export and image.layer.add / set / remove / move: they edit the JSON of a document, then call
// save_image_document (validate, write, bake) through commit_document. Docs: docs/IMAGES.md, "Commands".
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/style_guide.h"
#include "image_edit.h"
#include "image_frames.h"
#include "util.h"

namespace fa::imgedit {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using assets_detail::require_usable_manifest;
using tooling_detail::arg_bool;
using tooling_detail::arg_string;

namespace {

Json required_arg(const Json& a, const char* command, const char* key, const char* what, const std::string& example) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) arg_error(command, std::string("/") + key, std::string("`") + key + "` is required: " + what + ".", example);
    return *it;
}

int int_arg(const Json& a, const char* command, const char* key, int lo, int hi, int def, bool required = false) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) {
        if (required) arg_error(command, std::string("/") + key, std::string("`") + key + "` is required.", "A whole number from " + std::to_string(lo) + " to " + std::to_string(hi) + ".");
        return def;
    }
    if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi)
        arg_error(command, std::string("/") + key, std::string("`") + key + "` must be a whole number from " + std::to_string(lo) + " to " + std::to_string(hi) + ", got " + describe_json_value(*it) + ".", "");
    return int(it->get<long long>());
}

Json layer_summary(const LayerRef& r) {
    return Json::object({{"index", r.indexPath}, {"pointer", r.pointer}, {"name", r.layer->value("name", std::string())}, {"kind", r.layer->value("kind", std::string())}});
}

// The doc as the picture it makes now, or an error that teaches (a document that does not load).
Image render_or_fail(const std::string& projectDir, const std::string& rel, const Json& doc) {
    std::vector<ImageIssue> issues;
    auto parsed = parse_image_document(doc, rel, projectDir, &issues);
    if (!parsed.ok()) fail("invalid_argument", parsed.error().message, parsed.error().hint);
    ImageRenderOptions options;
    options.projectDir = projectDir;
    if (const FrameScope* fs = FrameScope::current()) options.frame = fs->frame();
    auto render = composite_image_document(*parsed, options);
    if (!render.ok()) fail("failed", render.error().message, render.error().hint);
    return std::move(render->image);
}

// ---- image.create ---------------------------------------------------------------------------------------------------

Json image_create(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.create";
    check_arg_keys(cmd, a, "", {"path", "width", "height", "background", "layers", "description", "palette", "ramps", "output", "overwrite", "bake"});
    const std::string rel = doc_path_arg(arg_string(a, "path", true), cmd);
    std::string output;
    if (a.contains("output") && !a["output"].is_null()) {
        if (!a["output"].is_string())
            arg_error(cmd, "/output", "expected a project path ending in .png, got " + describe_json_value(a["output"]) + ".", "Example: \"assets/art/hero.png\". Leave it out to bake next to the document.");
        const std::string raw = a["output"].get<std::string>();
        auto norm = fs::normalize_checked(raw);
        if (!norm.ok()) arg_error(cmd, "/output", norm.error().message, norm.error().hint);
        if (norm->empty() || fs::is_absolute(raw) || to_lower(fs::extension(*norm)) != ".png")
            arg_error(cmd, "/output", "`output` must be a project-relative path ending in .png, got '" + raw + "'.", "Example: \"assets/art/hero.png\". Leave it out to bake next to the document.");
        check_write_target(projectDir, *norm, cmd, "output");
        output = *norm;
    }
    check_write_target(projectDir, rel, cmd, "path");
    const int w = int_arg(a, cmd, "width", 1, kImageDocMaxSide, 0, true), h = int_arg(a, cmd, "height", 1, kImageDocMaxSide, 0, true);
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) fail("invalid_argument", path.error().message, path.error().hint);
    std::error_code ec;
    if (!arg_bool(a, "overwrite", false) && stdfs::exists(*path, ec))
        fail("exists", "'" + rel + "' already exists.", "Pass overwrite: true to replace it, or edit it with image.layer.add / image.paint / image.edit.");
    require_usable_manifest(projectDir);
    Json doc = Json::object({{"format", kImageDocFormat}, {"width", w}, {"height", h}});
    if (a.contains("background") && !a["background"].is_null()) doc["background"] = a["background"];
    if (a.contains("description") && a["description"].is_string()) doc["description"] = a["description"];
    if (!output.empty()) doc["output"] = output;
    for (const char* k : {"palette", "ramps"})
        if (a.contains(k) && !a[k].is_null()) doc[k] = a[k];
    if (a.contains("layers") && !a["layers"].is_null()) {
        if (!a["layers"].is_array()) arg_error(cmd, "/layers", "expected a list of layers, got " + describe_json_value(a["layers"]) + ".", "Example: [{\"kind\":\"fill\",\"color\":\"#203040\"}]. Layer kinds: docs.read IMAGES.");
        doc["layers"] = a["layers"];
    } else {
        doc["layers"] = Json::array();
    }
    Json out = commit_document(projectDir, rel, doc, std::nullopt, arg_bool(a, "bake", true), Json::object(), {}, cmd);
    out["nextSteps"] = Json::array({"Add layers: image.layer.add {\"path\":\"" + rel + "\",\"layer\":{\"kind\":\"fill\",\"color\":\"#203040\"}}.",
                                    "Paint on a layer: image.paint {\"path\":\"" + rel + "\",\"layer\":\"paint\",\"create\":true,\"strokes\":[...]}.",
                                    "Use the baked PNG '" + out["path"].get<std::string>() + "' as a Sprite texture."});
    return out;
}

// ---- image.info -----------------------------------------------------------------------------------------------------

void collect_inputs(const Json& list, std::vector<std::string>& out) {
    if (!list.is_array()) return;
    for (const Json& l : list) {
        if (!l.is_object()) continue;
        auto add = [&](const Json& v) {
            if (v.is_string() && !v.get<std::string>().empty()) out.push_back(fs::normalize(v.get<std::string>()));
        };
        if (l.contains("source")) add(l["source"]);
        if (l.contains("cels") && l["cels"].is_array())
            for (const Json& c : l["cels"])
                if (c.is_object() && c.contains("source")) add(c["source"]);
        if (l.contains("font") && l["font"].is_string() && l["font"].get<std::string>().find("builtin:") != 0) add(l["font"]);
        if (l.contains("masks") && l["masks"].is_array())
            for (const Json& m : l["masks"])
                if (m.is_object() && m.contains("source")) add(m["source"]);
        if (l.contains("layers")) collect_inputs(l["layers"], out);
    }
}

Json info_tree(const std::string& projectDir, const Json& list, std::vector<int>& path) {
    Json out = Json::array();
    if (!list.is_array()) return out;
    for (std::size_t i = 0; i < list.size(); ++i) {
        const Json& l = list[i];
        if (!l.is_object()) continue;
        path.push_back(int(i));
        Json n = Json::object({{"index", index_path_string(path)}});
        std::string ptr;
        for (std::size_t k = 0; k < path.size(); ++k) ptr += "/layers/" + std::to_string(path[k]);
        n["pointer"] = ptr;
        n["name"] = l.value("name", std::string());
        n["kind"] = l.value("kind", std::string());
        n["visible"] = l.value("visible", true);
        n["opacity"] = l.value("opacity", 1.0);
        n["blend"] = l.value("blend", std::string("normal"));
        n["x"] = l.value("x", 0);
        n["y"] = l.value("y", 0);
        if (l.value("clip", false)) n["clip"] = true;
        for (const char* k : {"masks", "adjustments", "effects"})
            if (l.contains(k) && l[k].is_array() && !l[k].empty()) n[k] = l[k].size();
        if (l.contains("source") && l["source"].is_string()) {
            n["source"] = l["source"];
            assets_detail::ProjectRootGuard root(projectDir);
            auto size = texture_size(l["source"].get<std::string>());
            if (size.ok()) n["size"] = Json::object({{"width", size->width}, {"height", size->height}});
        } else if (l.value("kind", std::string()) == "indexed" && l.contains("rows") && l["rows"].is_array() && !l["rows"].empty() && l["rows"][0].is_string()) {
            n["size"] = Json::object({{"width", l["rows"][0].get<std::string>().size()}, {"height", l["rows"].size()}});
        } else if (l.contains("width") || l.contains("height")) {
            n["size"] = Json::object({{"width", l.value("width", 0)}, {"height", l.value("height", 0)}});
        }
        if (l.value("kind", std::string()) == "text" && l.contains("text")) n["text"] = l["text"];
        if (l.contains("cels") && l["cels"].is_array() && !l["cels"].empty()) {
            Json frames = Json::array();
            for (const Json& c : l["cels"])
                if (c.is_object() && c.contains("frame")) frames.push_back(c["frame"]);
            n["celFrames"] = frames;   // the frames after the first where the layer changes (the others keep the cel before)
        }
        if (l.contains("layers")) n["children"] = info_tree(projectDir, l["layers"], path);
        path.pop_back();
        out.push_back(std::move(n));
    }
    return out;
}

Json image_info(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.info";
    check_arg_keys(cmd, a, "", {"path"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd, false);
    Json out = Json::object({{"document", d.rel}, {"width", d.json.value("width", 0)}, {"height", d.json.value("height", 0)}});
    if (d.json.contains("background")) out["background"] = d.json["background"];
    if (d.json.contains("description")) out["description"] = d.json["description"];
    std::vector<ImageIssue> issues;
    auto parsed = parse_image_document(d.json, d.rel, projectDir, &issues);
    out["valid"] = parsed.ok();
    if (parsed.ok() && !parsed->palette.empty())
        out["palette"] = Json::object({{"source", d.json.contains("palette") ? "document" : "style"},
                                       {"colors", parsed->palette.size()},
                                       {"ramps", parsed->palette.ramps.size()},
                                       {"hint", "image.palette lists the colours with their indices and shades."}});
    if (!issues.empty()) {
        Json list = Json::array();
        for (const ImageIssue& i : issues) list.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
        out["problems"] = list;
    }
    if (json_animated(d.json)) {
        const int count = json_frame_count(d.json);
        Json frames = Json::array();
        int total = 0;
        for (int f = 0; f < count; ++f) {
            const int ms = d.json.contains("frames") && d.json["frames"][std::size_t(f)].is_object() ? d.json["frames"][std::size_t(f)].value("duration", 100) : 100;
            total += ms;
            Json fr = Json::object({{"frame", f}, {"duration", ms}});
            Json names = Json::array();
            if (d.json.contains("tags") && d.json["tags"].is_array())
                for (const Json& t : d.json["tags"])
                    if (t.is_object() && t.value("from", 0) <= f && f <= t.value("to", 0)) names.push_back(t.value("name", std::string()));
            if (!names.empty()) fr["tags"] = names;
            frames.push_back(fr);
        }
        Json anim = Json::object({{"frameCount", count}, {"totalMs", total}, {"frames", frames}, {"tags", d.json.value("tags", Json::array())}});
        if (parsed.ok()) {
            auto plan = plan_image_sheet(*parsed);
            if (plan.ok()) {
                anim["sheet"] = plan->sheet;
                if (!plan->warnings.empty()) anim["sheetWarnings"] = plan->warnings;
            } else {
                anim["sheetProblem"] = plan.error().message;
            }
        }
        out["animation"] = anim;
    }
    std::vector<int> path;
    out["layers"] = info_tree(projectDir, d.json["layers"], path);
    std::vector<std::string> inputs;
    collect_inputs(d.json["layers"], inputs);
    std::sort(inputs.begin(), inputs.end());
    inputs.erase(std::unique(inputs.begin(), inputs.end()), inputs.end());
    out["inputs"] = inputs;
    const ImageBakeStatus status = image_bake_status(projectDir, d.rel);
    out["bake"] = Json::object({{"state", image_bake_state_name(status.state)}, {"path", status.output}, {"reason", status.reason}});
    out["selections"] = list_selections(projectDir, d.rel);
    if (!status.output.empty()) {
        auto png = resolve_project_path(projectDir, status.output);
        std::error_code ec;
        if (png.ok() && stdfs::is_regular_file(*png, ec)) out["$image"] = Json::object({{"path", png->string()}, {"mimeType", "image/png"}});
    }
    Json steps = Json::array();
    if (status.state != ImageBakeState::Fresh && status.state != ImageBakeState::Broken)
        steps.push_back("The PNG is " + std::string(image_bake_state_name(status.state)) + ": call image.bake {\"path\":\"" + d.rel + "\"}.");
    steps.push_back("Address a layer by its name or its index path (\"index\" above) in image.layer.*, image.edit, image.paint and image.select.");
    out["nextSteps"] = steps;
    return out;
}

// ---- image.export ---------------------------------------------------------------------------------------------------

Image scale_nearest(const Image& src, int w, int h) {
    Image out;
    out.width = w;
    out.height = h;
    out.rgba.resize(std::size_t(w) * h * 4);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            const int sx = std::min(src.width - 1, int(std::floor((x + 0.5) * src.width / w)));
            const int sy = std::min(src.height - 1, int(std::floor((y + 0.5) * src.height / h)));
            std::copy_n(&src.rgba[(std::size_t(sy) * src.width + sx) * 4], 4, &out.rgba[(std::size_t(y) * w + x) * 4]);
        }
    return out;
}

Json image_export(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.export";
    check_arg_keys(cmd, a, "", {"path", "out", "scale", "layer", "trim", "filter", "overwrite", "frame"});
    // `out` is judged first, before the document is opened and rendered: a path that may not be written fails without any work.
    const std::string outArg = arg_string(a, "out", true);
    auto outNorm = fs::normalize_checked(outArg);
    if (!outNorm.ok() || outNorm->empty() || !ends_with(to_lower(*outNorm), ".png"))
        arg_error(cmd, "/out", "'" + outArg + "' is not a project-relative .png path.", "Example: \"assets/art/hero-export.png\".");
    check_write_target(projectDir, *outNorm, cmd, "out");
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd, false);
    FrameScope frameScope(projectDir, d.rel, d.json, a, cmd);
    auto outPath = resolve_project_path(projectDir, *outNorm);
    if (!outPath.ok()) fail("invalid_argument", outPath.error().message, outPath.error().hint);
    std::error_code ec;
    if (!arg_bool(a, "overwrite", false) && stdfs::exists(*outPath, ec))
        fail("exists", "'" + *outNorm + "' already exists.", "Pass overwrite: true to replace it, or choose another `out`.");
    if (ends_with(*outNorm, kImageDocSuffix)) arg_error(cmd, "/out", "`out` is the PNG to write, not a document.", "Example: \"assets/art/hero-export.png\".");
    double scale = 1;
    if (a.contains("scale") && !a["scale"].is_null()) {
        if (!a["scale"].is_number() || a["scale"].get<double>() < 0.01 || a["scale"].get<double>() > 16)
            arg_error(cmd, "/scale", "`scale` must be a number from 0.01 to 16, got " + describe_json_value(a["scale"]) + ".", "2 doubles the size, 0.5 halves it.");
        scale = a["scale"].get<double>();
    }
    const int W = d.json.value("width", 0), H = d.json.value("height", 0);
    Image img;
    Json extra = Json::object();
    std::vector<std::string> warnings;
    if (a.contains("layer") && !a["layer"].is_null()) {
        LayerRef ref = find_layer(d.json, a["layer"], cmd);
        // the document's own checks first, so a broken document is reported with its pointers
        (void)render_or_fail(projectDir, d.rel, d.json);
        img = render_layer_alone(projectDir, *ref.layer, W, H, ref.parentX, ref.parentY, &warnings, &d.json);
        extra["layer"] = layer_summary(ref);
        if (ref.parentX || ref.parentY) warnings.push_back("The layer is drawn at its place on the canvas: the offsets of its groups count, their opacity, blend and masks do not.");
    } else {
        img = render_or_fail(projectDir, d.rel, d.json);
    }
    if (arg_bool(a, "trim", false)) {
        int x0 = img.width, y0 = img.height, x1 = -1, y1 = -1;
        for (int y = 0; y < img.height; ++y)
            for (int x = 0; x < img.width; ++x)
                if (img.rgba[(std::size_t(y) * img.width + x) * 4 + 3]) {
                    x0 = std::min(x0, x);
                    x1 = std::max(x1, x);
                    y0 = std::min(y0, y);
                    y1 = std::max(y1, y);
                }
        if (x1 < 0) fail("invalid_argument", "image.export /trim: nothing is drawn (every pixel is transparent), so there is nothing to trim to.", "Export without trim, or check the layer's visibility and masks.");
        Image c;
        c.width = x1 - x0 + 1;
        c.height = y1 - y0 + 1;
        c.rgba.resize(std::size_t(c.width) * c.height * 4);
        for (int y = 0; y < c.height; ++y)
            std::copy_n(&img.rgba[(std::size_t(y + y0) * img.width + x0) * 4], std::size_t(c.width) * 4, &c.rgba[std::size_t(y) * c.width * 4]);
        extra["trimmedTo"] = Region{x0, y0, c.width, c.height}.to_json();
        img = std::move(c);
    }
    if (scale != 1) {
        const int nw = std::max(1, int(std::lround(img.width * scale))), nh = std::max(1, int(std::lround(img.height * scale)));
        if (nw > 8192 || nh > 8192) arg_error(cmd, "/scale", std::format("the result would be {}x{} pixels; the limit is 8192.", nw, nh), "Use a smaller scale.");
        std::string filter = arg_string(a, "filter", false);
        if (filter.empty()) {
            auto style = load_style_guide(projectDir);
            filter = style.guide.pixelArt.value_or(false) ? "nearest" : "bilinear";
        }
        if (filter != "nearest" && filter != "bilinear") arg_error(cmd, "/filter", "unknown filter '" + filter + "'.", did_you_mean(filter, std::vector<std::string>{"nearest", "bilinear"}));
        img = filter == "nearest" ? scale_nearest(img, nw, nh) : resize_image(img, nw, nh);
        extra["filter"] = filter;
    }
    require_usable_manifest(projectDir);
    write_layer_png(projectDir, *outNorm, d.rel, img, cmd, false);
    Json out = Json::object({{"document", d.rel}, {"path", *outNorm}, {"width", img.width}, {"height", img.height}, {"scale", scale}});
    for (auto it = extra.begin(); it != extra.end(); ++it) out[it.key()] = it.value();
    out["$image"] = Json::object({{"path", outPath->string()}, {"mimeType", "image/png"}});
    if (!warnings.empty()) out["warnings"] = warnings;
    out["nextSteps"] = Json::array({"The PNG is a plain file: it is not baked from the document, so changing the document does not update it (run the export again)."});
    return out;
}

// ---- image.layer.* ---------------------------------------------------------------------------------------------------

void require_unique_name(const Json& doc, const std::string& name, const char* cmd, const std::string& pointer, const Json* except = nullptr) {
    Json& d = const_cast<Json&>(doc);
    std::vector<Json*> stack;
    std::function<void(Json&)> walk = [&](Json& list) {
        if (!list.is_array()) return;
        for (Json& l : list) {
            if (!l.is_object()) continue;
            if (&l != except && l.value("name", std::string()) == name)
                arg_error(cmd, pointer, "a layer named '" + name + "' already exists.", "Layer names address layers, so they must be distinct. Pick another name (" + describe_layers(doc, 12) + ").");
            if (l.contains("layers")) walk(l["layers"]);
        }
    };
    walk(d["layers"]);
}

Json& group_list(Json& doc, const Json& parentArg, const char* cmd, LayerRef& parentRef, bool& isRoot) {
    isRoot = true;
    if (parentArg.is_null() || (parentArg.is_string() && parentArg.get<std::string>().empty())) return doc["layers"];
    parentRef = find_layer(doc, parentArg, cmd, "parent");
    if (parentRef.layer->value("kind", std::string()) != "group")
        arg_error(cmd, "/parent", "layer '" + parentRef.indexPath + "' is a " + parentRef.layer->value("kind", std::string("?")) + " layer, not a group.",
                  "Only a group holds layers. Make one with image.layer.add {\"layer\":{\"kind\":\"group\",\"name\":\"...\",\"layers\":[]}}.");
    isRoot = false;
    Json& g = *parentRef.layer;
    if (!g.contains("layers") || !g["layers"].is_array()) g["layers"] = Json::array();
    return g["layers"];
}

Json image_layer_add(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.layer.add";
    check_arg_keys(cmd, a, "", {"path", "layer", "parent", "index", "bake"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    Json layer = required_arg(a, cmd, "layer", "the layer to add, an object with `kind`",
                              "Example: {\"layer\":{\"kind\":\"fill\",\"name\":\"sky\",\"color\":\"#203040\"}}. Kinds: " + join(image_layer_kind_names(), ", ") + ".");
    if (!layer.is_object()) arg_error(cmd, "/layer", "expected an object, got " + describe_json_value(layer) + ".", "Example: {\"kind\":\"fill\",\"color\":\"#203040\"}.");
    if (!layer.contains("kind")) arg_error(cmd, "/layer/kind", "the layer needs a `kind`.", "Kinds: " + join(image_layer_kind_names(), ", ") + ".");
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    if (layer.contains("name") && layer["name"].is_string()) require_unique_name(d.json, layer["name"].get<std::string>(), cmd, "/layer/name");
    else layer["name"] = unique_layer_name(d.json, layer["kind"].is_string() ? layer["kind"].get<std::string>() : "layer");
    // `name` first, like the documents people write
    {
        Json ordered = Json::object();
        ordered["kind"] = layer["kind"];
        ordered["name"] = layer["name"];
        for (auto it = layer.begin(); it != layer.end(); ++it)
            if (it.key() != "kind" && it.key() != "name") ordered[it.key()] = it.value();
        layer = std::move(ordered);
    }
    LayerRef parentRef;
    bool isRoot = true;
    Json& list = group_list(d.json, a.contains("parent") ? a["parent"] : Json(), cmd, parentRef, isRoot);
    const int n = int(list.size());
    int index = n;
    if (a.contains("index") && !a["index"].is_null()) index = int_arg(a, cmd, "index", 0, n, n);
    list.insert(list.begin() + index, layer);
    std::vector<int> path = isRoot ? std::vector<int>{} : parentRef.path;
    path.push_back(index);
    LayerRef added = find_layer(d.json, index_path_string(path), cmd);
    Json extra = Json::object({{"layer", layer_summary(added)}});
    return commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, {}, cmd);
}

void merge_patch(Json& target, const Json& patch) {
    for (auto it = patch.begin(); it != patch.end(); ++it) {
        if (it.value().is_null()) target.erase(it.key());
        else if (it.value().is_object() && target.contains(it.key()) && target[it.key()].is_object() && it.key() != "texture" && it.key() != "provenance") merge_patch(target[it.key()], it.value());
        else target[it.key()] = it.value();
    }
}

Json image_layer_set(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.layer.set";
    check_arg_keys(cmd, a, "", {"path", "layer", "set", "bake"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    LayerRef ref = find_layer(d.json, required_arg(a, cmd, "layer", "the layer to change, by name or index path", "Example: \"layer\":\"sky\" or \"layer\":\"1/0\"."), cmd);
    Json patch = required_arg(a, cmd, "set", "the fields to change, an object", "Example: {\"set\":{\"opacity\":0.5,\"blend\":\"multiply\",\"visible\":false}}. null removes a field.");
    if (!patch.is_object()) arg_error(cmd, "/set", "expected an object, got " + describe_json_value(patch) + ".", "Example: {\"opacity\":0.5}.");
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    if (patch.contains("kind") && patch["kind"] != ref.layer->value("kind", std::string()))
        arg_error(cmd, "/set/kind", "a layer cannot change its kind (it is " + ref.layer->value("kind", std::string("?")) + ").", "Add a new layer of the other kind with image.layer.add and remove this one.");
    if (patch.contains("name") && patch["name"].is_string()) require_unique_name(d.json, patch["name"].get<std::string>(), cmd, "/set/name", ref.layer);
    merge_patch(*ref.layer, patch);
    Json extra = Json::object({{"layer", layer_summary(ref)}});
    return commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, {}, cmd);
}

Json image_layer_remove(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.layer.remove";
    check_arg_keys(cmd, a, "", {"path", "layer", "bake"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    LayerRef ref = find_layer(d.json, required_arg(a, cmd, "layer", "the layer to remove, by name or index path", "Example: \"layer\":\"sky\" or \"layer\":\"1/0\"."), cmd);
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    Json extra = Json::object({{"removed", layer_summary(ref)}});
    std::vector<std::string> warnings;
    std::string source = ref.layer->value("source", std::string());
    if (ref.index + 1 < int(ref.list->size()) && (*ref.list)[ref.index + 1].value("clip", false) && !ref.layer->value("clip", false))
        warnings.push_back("The layer above was clipped to the removed layer; it now clips to the layer below. Check it, or set its `clip` to false.");
    if (ref.layer->value("kind", std::string()) == "group") extra["removedChildren"] = ref.layer->contains("layers") ? (*ref.layer)["layers"].size() : 0;
    ref.list->erase(ref.list->begin() + ref.index);
    if (!source.empty()) extra["note"] = "The PNG '" + source + "' was kept on disk; delete it yourself if nothing else uses it.";
    return commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, warnings, cmd);
}

bool has_prefix_path(const std::vector<int>& path, const std::vector<int>& prefix) {
    return path.size() >= prefix.size() && std::equal(prefix.begin(), prefix.end(), path.begin());
}

Json image_layer_move(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.layer.move";
    check_arg_keys(cmd, a, "", {"path", "layer", "index", "parent", "bake"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    LayerRef ref = find_layer(d.json, required_arg(a, cmd, "layer", "the layer to move, by name or index path", "Example: \"layer\":\"sky\" or \"layer\":\"1/0\"."), cmd);
    if (!a.contains("index") && !a.contains("parent"))
        arg_error(cmd, "", "give `index` (the position in the list, 0 = the bottom) and/or `parent` (the group to move into).",
                  "Example: {\"layer\":\"sky\",\"index\":0} sends it to the bottom; {\"layer\":\"star\",\"parent\":\"stars\"} moves it to the top of the group 'stars'. " + describe_layers(d.json, 12));
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    const Json copy = *ref.layer;
    const std::vector<int> srcPath = ref.path;
    Json* srcList = ref.list;
    const int srcIndex = ref.index;
    LayerRef parentRef;
    bool isRoot = true;
    const bool changesParent = a.contains("parent");
    Json& target = changesParent ? group_list(d.json, a["parent"], cmd, parentRef, isRoot) : *ref.list;
    if (changesParent && !isRoot && has_prefix_path(parentRef.path, srcPath))
        arg_error(cmd, "/parent", "a layer cannot move into itself or into one of its own children.", "Pick another group (" + describe_layers(d.json, 12) + ").");
    const bool sameList = &target == srcList;
    const int finalSize = int(target.size()) - (sameList ? 1 : 0);
    int index = finalSize;
    if (a.contains("index") && !a["index"].is_null()) index = int_arg(a, cmd, "index", 0, finalSize, finalSize);
    // mark the original, insert the copy, remove the original: no pointer into the lists is used across the changes
    (*ref.layer)["__moving"] = true;
    const int insertAt = sameList && index > srcIndex ? index + 1 : index;
    Json fresh = copy;
    target.insert(target.begin() + insertAt, fresh);
    std::function<bool(Json&)> drop = [&](Json& list) {
        for (std::size_t i = 0; i < list.size(); ++i) {
            if (list[i].is_object() && list[i].contains("__moving")) {
                list.erase(list.begin() + i);
                return true;
            }
            if (list[i].is_object() && list[i].contains("layers") && drop(list[i]["layers"])) return true;
        }
        return false;
    };
    drop(d.json["layers"]);
    std::vector<std::string> warnings;
    Json extra = Json::object({{"moved", Json::object({{"from", index_path_string(srcPath)}, {"index", index}, {"parent", changesParent && !isRoot ? parentRef.indexPath : std::string(changesParent ? "" : "(unchanged)")}})}});
    return commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, warnings, cmd);
}

}  // namespace

// ---- registration ---------------------------------------------------------------------------------------------------

void register_edit_commands(CommandRegistry& registry, const std::string& projectDir) {
    const std::string pathDoc = "The image document, project-relative, ending in .image.json, e.g. 'assets/art/hero.image.json'.";
    const std::string layerDoc = "A layer: its name ('sky') or its index path ('1' is the second layer from the bottom, '1/0' the first child of the group at 1). Index paths count from the bottom, like the document.";
    const std::string bakeDoc = "Also draw the PNG (default true). False only writes the document.";
    auto add = [&](const char* name, const char* summary, const std::string& description, const char* schema, Json (*fn)(const std::string&, const Json&), bool readOnly = false) {
        CommandInfo info;
        info.name = name;
        info.category = "assets";
        info.readOnly = readOnly;
        info.summary = summary;
        info.description = description;
        info.inputSchema = Json::parse(schema);
        if (std::string(name) == "image.export") add_frame_support(info, "to export", false);
        add_image_command(registry, info, [projectDir, fn](const Json& args) { return fn(projectDir, args); }, std::string(name) != "image.export");
    };

    add("image.create", "Make a new layered image document (*.image.json) with a canvas size, a background and optional first layers, and bake its PNG.",
        "Writes a new image document at `path` (project-relative, ends in .image.json) with a width x height canvas (1..4096), an optional `background` colour "
        "and optional `layers` (bottom first; docs.read IMAGES lists the kinds), then bakes the PNG next to it. Refuses to replace an existing file unless "
        "overwrite is true. The result has the picture as `$image`, the changed `region` {x,y,width,height} (the whole canvas for a new document) and next steps. "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"width\":64,\"height\":64,\"background\":\"#00000000\",\"layers\":[{\"kind\":\"fill\",\"name\":\"sky\",\"color\":\"#203040\"}]}",
        R"({"type":"object","required":["path","width","height"],"properties":{
          "path":{"type":"string","description":"Where to write the document, project-relative, ending in .image.json."},
          "width":{"type":"integer","minimum":1,"maximum":4096,"description":"Canvas width in pixels."},
          "height":{"type":"integer","minimum":1,"maximum":4096,"description":"Canvas height in pixels."},
          "background":{"description":"A colour the canvas starts with: \"#rrggbb\", \"#rrggbbaa\", a CSS name or [r,g,b,a]. Without it the canvas starts transparent."},
          "layers":{"type":"array","items":{"type":"object"},"description":"The first layers, bottom first, each an object with `kind` (see docs.read IMAGES). Default none."},
          "description":{"type":"string","description":"A sentence for people and AIs about the picture."},
          "palette":{"description":"For indexed (pixel-art) layers: \"style\" (the style palette of assets.json, the default for an indexed layer) or a list of colours, each \"#rrggbb\" or {\"name\", \"color\"}; at most 81. See docs.read IMAGES, \"Pixel art\"."},
          "ramps":{"type":"array","description":"Colour ramps for shading by index: lists of palette colours (index, name or \"#rrggbb\") from the darkest to the lightest, e.g. [[\"skin-dark\",\"skin\",\"skin-light\"]]."},
          "output":{"type":"string","description":"The PNG the document bakes to, project-relative, ending in .png (e.g. \"assets/art/enemy.png\" to replace an existing picture). Default: next to the document, its name with .image.json replaced by .png."},
          "overwrite":{"type":"boolean","default":false,"description":"Replace the document when it already exists."},
          "bake":{"type":"boolean","default":true,"description":"Also draw the PNG."}}})",
        image_create);

    add("image.info", "Describe a layered image document: its layers as a tree with index paths, sizes, bake status, the files it reads and its stored selections.",
        "Reads the document at `path` and returns {document, width, height, background, valid, problems?, palette?: {source, colors, ramps} (when it has one: image.palette lists it), layers: [{index, pointer, name, kind, visible, opacity, blend, x, y, "
        "size?, source?, masks?, adjustments?, effects?, children?}], inputs, bake: {state, path, reason}, selections, $image}. `index` is the index path other image.* "
        "commands take in `layer` (\"1/0\"); names work too. `bake.state` is fresh, missing, stale, unrecorded or broken. `$image` is the baked PNG when it exists. "
        "An animated document (docs.read IMAGES, \"Frames and tags\") also has `animation`: {frameCount, totalMs, frames: [{frame, duration, tags?}], tags, sheet (the cell grid and clips the bake will write), sheetWarnings?}; "
        "a layer with cels lists `celFrames`, the frames where it changes. "
        "Read-only. Example: {\"path\":\"assets/art/hero.image.json\"}",
        R"({"type":"object","required":["path"],"properties":{"path":{"type":"string","description":"The image document, project-relative."}}})", image_info, true);

    add("image.export", "Write the flattened picture of a document, or one layer or group of it, to a PNG, optionally scaled or trimmed.",
        "Draws the document at `path` (or only `layer`, by name or index path, with its masks, adjustments and effects but at full opacity and normal blend; the offsets of "
        "the groups around it count) and writes a PNG to `out`. `scale` resizes (0.01..16) with `filter` nearest (pixel art) or bilinear; the default filter is nearest when "
        "assets.json style.pixelArt is true, else bilinear. `trim` crops to the pixels that show. The PNG is a plain copy, not baked from the document. Refuses to replace "
        "an existing file unless overwrite is true. Example: {\"path\":\"assets/art/hero.image.json\",\"out\":\"assets/art/hero-x2.png\",\"scale\":2}",
        R"({"type":"object","required":["path","out"],"properties":{
          "path":{"type":"string","description":"The image document."},
          "out":{"type":"string","description":"The PNG to write, project-relative, ending in .png."},
          "scale":{"type":"number","minimum":0.01,"maximum":16,"default":1,"description":"Size factor of the result."},
          "layer":{"description":"Export only this layer or group (name or index path) instead of the whole picture."},
          "trim":{"type":"boolean","default":false,"description":"Crop to the pixels that are not transparent."},
          "filter":{"type":"string","enum":["nearest","bilinear"],"description":"How scale resamples. Default: nearest for pixel-art projects, else bilinear."},
          "overwrite":{"type":"boolean","default":false,"description":"Replace `out` when it exists."}}})",
        image_export);

    add("image.layer.add", "Add a layer to an image document (at the top, or at an index, or inside a group) and bake the picture.",
        "Adds the `layer` object (its `kind` and fields as docs.read IMAGES describes) to the document at `path`: on top of the root list by default, at `index` "
        "(0 = the bottom) of the list, or inside the group `parent`. A layer without `name` gets one from its kind (\"fill\", \"fill 2\"); names must be distinct because "
        "they address layers. The document is checked completely (a problem names the JSON pointer, nothing is written) and baked. The result has the picture as "
        "`$image`, the changed `region`, and `layer` {index, pointer, name, kind} of the new layer. "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":{\"kind\":\"text\",\"text\":\"Hi\",\"size\":16,\"x\":4,\"y\":4}}",
        ("{\"type\":\"object\",\"required\":[\"path\",\"layer\"],\"properties\":{"
         "\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
         "\"layer\":{\"type\":\"object\",\"description\":\"The layer: {kind, name?, visible?, opacity?, blend?, x?, y?, clip?, masks?, ...fields of its kind}.\"},"
         "\"parent\":{\"description\":\"A group (name or index path) to add the layer into. Default: the top level.\"},"
         "\"index\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"Position in the list, 0 = the bottom. Default: the top.\"},"
         "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"" + bakeDoc + "\"}}}").c_str(),
        image_layer_add);

    add("image.layer.set", "Change fields of one layer (name, visible, opacity, blend, x, y, clip, masks, adjustments, effects, its kind's fields) and bake.",
        "Merges `set` into the layer: a field you give replaces the old one (objects such as `gradient` merge key by key; arrays such as `masks` are replaced whole), "
        "null removes a field. The `kind` cannot change. The layer is addressed by name or index path; a wrong name gets a did-you-mean and the layer list. The document is "
        "checked completely before anything is written. The result has the picture as `$image` and the changed `region`. "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"shadow\",\"set\":{\"opacity\":0.4,\"blend\":\"multiply\"}}",
        ("{\"type\":\"object\",\"required\":[\"path\",\"layer\",\"set\"],\"properties\":{"
         "\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
         "\"layer\":{\"description\":\"" + layerDoc + "\"},"
         "\"set\":{\"type\":\"object\",\"description\":\"The fields to change, e.g. {\\\"opacity\\\":0.5,\\\"visible\\\":false}. null removes a field.\"},"
         "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"" + bakeDoc + "\"}}}").c_str(),
        image_layer_set);

    add("image.layer.remove", "Remove a layer (and the children of a group) from an image document and bake.",
        "Deletes the layer addressed by name or index path. Its PNG stays on disk. Warns when the layer above was clipped to it. The result has the picture as `$image`, "
        "the changed `region` and `removed` {index, pointer, name, kind}. Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"1/0\"}",
        ("{\"type\":\"object\",\"required\":[\"path\",\"layer\"],\"properties\":{"
         "\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
         "\"layer\":{\"description\":\"" + layerDoc + "\"},"
         "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"" + bakeDoc + "\"}}}").c_str(),
        image_layer_remove);

    add("image.layer.move", "Move a layer to another position in its list, or into another group (or back to the top level), and bake.",
        "`index` is the layer's position in its list afterwards (0 = the bottom, so a higher index is drawn over more layers); without it the layer goes to the top of the "
        "list. `parent` moves it into that group (a name or index path; \"\" is the top level). The layer keeps its own x, y: moving it between groups with different offsets "
        "moves it on the canvas. A layer cannot move into its own children. The result has the picture as `$image` and the changed `region`. "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"glow\",\"index\":0}",
        ("{\"type\":\"object\",\"required\":[\"path\",\"layer\"],\"properties\":{"
         "\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
         "\"layer\":{\"description\":\"" + layerDoc + "\"},"
         "\"index\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"Position afterwards, 0 = the bottom. Default: the top.\"},"
         "\"parent\":{\"description\":\"Group to move into (name or index path), or \\\"\\\" for the top level. Default: stay in the same list.\"},"
         "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"" + bakeDoc + "\"}}}").c_str(),
        image_layer_move);
}

}  // namespace fa::imgedit
