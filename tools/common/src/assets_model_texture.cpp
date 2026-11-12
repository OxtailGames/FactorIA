// model.texture, model.decal, model.palette and model.bake_maps: the `texturing` and `vertexColors` sections of a model document (docs/MODELING.md,
// "Texturing"). Each edits the document field by field (checking the whole of it first, writing nothing on a mistake), bakes the .glb again and
// returns what was made. The bake itself is model_texture_bake.cpp (project side) and fa_scene's model_texture.h (the maps, wear and decals).
#include <algorithm>
#include <cmath>
#include <format>

#include "assets_internal.h"
#include "assets_shots.h"
#include "fa/core/strings.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/project_fs.h"
#include "model_texture_bake.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}

std::string model_path(const std::string& command, const std::string& arg) {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", command + ": `path` '" + arg + "' is not a model document under assets/.", "Model documents live in assets/, e.g. \"assets/models/door.model.json\".");
    if (!ends_with(to_lower(*norm), kModelDocSuffix))
        fail("invalid_argument", command + ": '" + *norm + "' does not end in .model.json.", "Name model documents <name>.model.json, e.g. \"assets/models/door.model.json\".");
    return *norm;
}

Json issues_json(const std::vector<ModelIssue>& issues) {
    Json list = Json::array();
    for (const ModelIssue& i : issues) list.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return list;
}

Json read_document(const std::string& projectDir, const std::string& rel) {
    auto text = tooling_detail::read_file(project_file(projectDir, rel));
    if (!text) {
        const std::vector<std::string> all = list_model_documents(projectDir);
        fail("not_found", "'" + rel + "' does not exist.", all.empty() ? "Make one with model.create {\"path\":\"" + rel + "\"}." : did_you_mean(rel, all) + " Model documents: " + join(all, ", ") + ".");
    }
    auto parsed = parse_json(*text, rel);
    if (!parsed.ok()) fail("invalid_document", parsed.error().message, parsed.error().hint.empty() ? "Fix the JSON syntax; schemas/model.schema.json describes the format." : parsed.error().hint);
    if (!parsed->is_object()) fail("invalid_document", rel + ": the document is not an object.", "Fix it by hand or write it again with model.create overwrite: true.");
    return std::move(*parsed);
}

// Fields of `set` over `out`: a value replaces, null removes the field.
void merge_fields(Json& out, const Json& set) {
    for (auto it = set.begin(); it != set.end(); ++it) {
        if (it.value().is_null()) out.erase(it.key());
        else out[it.key()] = it.value();
    }
}

// `set["parts"]` over `out["parts"]`, part by part (and field by field); a null part is removed.
void merge_parts(Json& out, const Json& parts) {
    Json merged = out.contains("parts") && out["parts"].is_object() ? out["parts"] : Json::object();
    for (auto p = parts.begin(); p != parts.end(); ++p) {
        if (p.value().is_null()) {
            merged.erase(p.key());
            continue;
        }
        if (!p.value().is_object()) {
            merged[p.key()] = p.value();  // the reader says what is wrong with it
            continue;
        }
        Json one = merged.contains(p.key()) && merged[p.key()].is_object() ? merged[p.key()] : Json::object();
        merge_fields(one, p.value());
        merged[p.key()] = one;
    }
    if (merged.empty()) out.erase("parts");
    else out["parts"] = merged;
}

Json merged_texturing(const Json& base, const Json& set) {
    Json out = base.is_object() ? base : Json::object();
    for (auto it = set.begin(); it != set.end(); ++it) {
        if (it.key() == "maps" && it.value().is_object()) {
            Json maps = out.contains("maps") && out["maps"].is_object() ? out["maps"] : Json::object();
            merge_fields(maps, it.value());
            if (maps.empty()) out.erase("maps");
            else out["maps"] = maps;
        } else if (it.value().is_null()) out.erase(it.key());
        else out[it.key()] = it.value();
    }
    return out;
}

Json merged_vertex_colors(const Json& base, const Json& set) {
    Json out = base.is_object() ? base : Json::object();
    for (auto it = set.begin(); it != set.end(); ++it) {
        if (it.key() == "parts" && it.value().is_object()) merge_parts(out, it.value());
        else if (it.value().is_null()) out.erase(it.key());
        else out[it.key()] = it.value();
    }
    return out;
}

// What a command changes in a document and how it then reports.
struct Edit {
    std::string command;
    std::string rel;
    Json json;       // the document, edited
    Json before;     // the document as it was
    bool changed() const { return json != before; }
    std::string hintDocs;
    std::vector<std::string> steps;
};

// Checks the edited document as a whole (a mistake lists every issue and writes nothing), then that the model builds with it.
ModelDoc check_document(const std::string& projectDir, Edit& edit) {
    std::vector<ModelIssue> issues;
    auto doc = parse_model_doc(edit.json, edit.rel, &issues);
    if (!doc.ok()) {
        Error e = doc.error();
        if (edit.changed()) e.message += std::string(e.message.empty() || e.message.back() == '.' ? " " : ". ") + "Nothing was written.";
        throw CommandError("invalid_document", e.message, e.hint.empty() ? edit.hintDocs : e.hint, Json::object({{"path", edit.rel}, {"issues", issues_json(issues)}}));
    }
    if (doc->texturing) {
        // a decal's picture must exist before anything is written: the bake would fail on it after the document changed
        for (std::size_t i = 0; i < doc->texturing->decals.size(); ++i) {
            const ModelDecalSpec& d = doc->texturing->decals[i];
            std::error_code ec;
            auto path = resolve_project_path(projectDir, d.image);
            if (!path.ok() || !std::filesystem::is_regular_file(*path, ec))
                throw CommandError("not_found", edit.command + ": the decal '" + d.name + "' names the image '" + d.image + "', which is not a file of the project. Nothing was written.",
                                   "Make a picture first: assets.generate_texture, or an image document (image.create) baked to a .png; then name its project path.", Json::object({{"pointer", "/texturing/decals/" + std::to_string(i) + "/image"}}));
        }
    }
    return std::move(*doc);
}

void write_document(const std::string& projectDir, const Edit& edit) {
    if (!edit.changed()) return;
    require_usable_manifest(projectDir);
    std::string err;
    if (!tooling_detail::write_file(project_write_file(projectDir, edit.rel), dump_json(edit.json), &err)) fail("failed", "Cannot write '" + edit.rel + "': " + err, "Check that the folder is writable.");
}

// A model that is textured needs the atlas: add `uv: {method: unwrap}` when the document says nothing about uvs.
bool ensure_atlas_uv(Json& json) {
    if (json.contains("uv")) return false;
    json["uv"] = Json::object({{"method", "unwrap"}});
    return true;
}

// Bakes (unless the caller said no) and puts what came out into `result`: the bake, the texture's report, warnings and the picture.
void bake_and_report(const std::string& projectDir, const Edit& edit, const Json& a, bool wantsPicture, Json& result, std::vector<std::string>& steps) {
    const bool changed = edit.changed();
    if (tooling_detail::arg_bool(a, "bake", true)) {
        auto b = bake_model_document(projectDir, edit.rel, {!changed, tooling_detail::arg_bool(a, "overwrite", false)});
        if (!b.ok()) {
            result["bake"] = Json::object({{"state", "failed"}, {"message", b.error().message}, {"hint", b.error().hint}});
            steps.push_back((changed ? "The document was written but could not be baked: " : "The model could not be baked: ") + b.error().message + " " + b.error().hint);
            return;
        }
        if (b->written) {
            result["bake"] = Json::object({{"state", "baked"}, {"output", b->output}, {"bytes", b->bytes}});
            if (!b->extras.empty()) result["extras"] = b->extras;
            if (!b->texture.is_null()) {
                result["texture"] = b->texture;
                if (wantsPicture) {
                    auto path = resolve_project_path(projectDir, b->texture.value("image", std::string()));
                    if (path.ok()) result["$image"] = image_member(*path, false);
                }
            }
            if (!b->warnings.empty()) result["warnings"] = b->warnings;
        } else {
            const ModelBakeStatus status = model_bake_status(projectDir, edit.rel);
            result["bake"] = Json::object({{"state", model_bake_state_name(status.state)}, {"output", status.output}, {"reason", "nothing changed and the .glb is current"}});
        }
    } else {
        const ModelBakeStatus status = model_bake_status(projectDir, edit.rel);
        result["bake"] = Json::object({{"state", model_bake_state_name(status.state)}, {"output", status.output}, {"reason", status.reason}});
        if (changed) steps.push_back("The .glb and the texture were not rebuilt: model.bake {\"path\":\"" + edit.rel + "\"} does it.");
    }
}

void common_texture_steps(const Json& result, std::vector<std::string>& steps) {
    if (!result.contains("texture")) return;
    const Json& t = result["texture"];
    const Json& report = t.value("report", Json::object());
    steps.push_back("The texture is a layered image document: '" + t.value("document", std::string()) + "'. Open it as an image (image.info) and paint on the layer \"paint\" or your own layers above the \"model: ...\" ones; "
                    "a model bake draws the picture again from all of them and never touches yours.");
    if (report.value("overlap", 0.0) > 0.02) steps.push_back("Some texels are claimed by two uv pieces (report.overlap): paint there shows on both. Raise uv.textureSize or lower uv.texelsPerUnit (model.uv).");
    for (const Json& d : report.value("decals", Json::array()))
        if (d.value("texels", 0) == 0) steps.push_back("The decal '" + d.value("name", std::string()) + "' painted no texel: check its position (model space), normal, size, `parts` and `faces`, and that the surface it sits on faces along `normal`.");
}

// ---- model.texture ----

Json model_texture_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.texture", a, "", {"path", "set", "replace", "clear", "bake", "overwrite", "picture"});
    Edit edit;
    edit.command = "model.texture";
    edit.rel = model_path("model.texture", tooling_detail::arg_string(a, "path", true));
    edit.hintDocs = "docs/MODELING.md, \"Texturing\", lists the fields of the texturing section; schemas/model.schema.json has them too.";
    const bool clear = tooling_detail::arg_bool(a, "clear", false), replace = tooling_detail::arg_bool(a, "replace", false), hasSet = a.contains("set");
    if (clear && hasSet) fail("invalid_argument", "model.texture: give `set` or `clear`, not both.", "`clear: true` removes the texturing section (and the layer pictures with it); `set` changes it.");
    if (hasSet && !a["set"].is_object())
        fail("invalid_argument", "model.texture: `set` must be an object such as {\"size\": 1024, \"ao\": true, \"wear\": [{\"mask\": \"edges\"}]}.", "Fields: size, bleed, vertexColors, background, document, ao, maps, wear, decals. A null value removes a field.");
    if (replace && !hasSet) fail("invalid_argument", "model.texture: `replace` needs a `set` to put in place of the section.", "Example: {\"set\": {\"ao\": true}, \"replace\": true}.");

    edit.json = read_document(projectDir, edit.rel);
    edit.before = edit.json;
    const Json beforeSection = edit.json.contains("texturing") ? edit.json["texturing"] : Json();
    bool addedUv = false;
    if (clear) edit.json.erase("texturing");
    else if (hasSet) {
        edit.json["texturing"] = merged_texturing(replace ? Json::object() : beforeSection, a["set"]);
        addedUv = ensure_atlas_uv(edit.json);
    }
    ModelDoc doc = check_document(projectDir, edit);

    // the model must build before anything is written
    {
        ProjectRootGuard root(projectDir);
        auto built = evaluate_model(doc, model_project_eval_options(projectDir));
        if (!built.ok()) fail("failed", edit.rel + ": " + built.error().message, built.error().hint);
    }
    write_document(projectDir, edit);

    Json result = Json::object({{"path", edit.rel}, {"changed", edit.changed()}});
    result["texturing"] = doc.texturing ? model_texturing_json(*doc.texturing) : Json();
    if (addedUv) result["uvAdded"] = Json::object({{"method", "unwrap"}, {"note", "The document had no uv section; the texture needs an atlas, so {\"method\":\"unwrap\"} was added. model.uv changes it."}});
    std::vector<std::string> steps;
    if (!doc.texturing) {
        steps.push_back(clear ? "The texturing section is gone: the layer pictures were removed with the next bake; the texture's image document and its paint layers stay (delete them yourself if they are not wanted)."
                              : "The document has no texturing section: model.texture {\"path\":\"" + edit.rel + "\",\"set\":{\"ao\":true}} adds one.");
    }
    bake_and_report(projectDir, edit, a, tooling_detail::arg_bool(a, "picture", true), result, steps);
    common_texture_steps(result, steps);
    result["nextSteps"] = steps;
    return result;
}

// ---- model.decal ----

std::string fresh_decal_name(const Json& decals) {
    for (int k = 1;; ++k) {
        const std::string name = "decal" + std::to_string(k);
        bool used = false;
        for (const Json& d : decals)
            if (d.is_object() && d.value("name", std::string()) == name) used = true;
        if (!used) return name;
    }
}

Json model_decal_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.decal", a, "", {"path", "add", "remove", "clear", "bake", "overwrite", "picture"});
    Edit edit;
    edit.command = "model.decal";
    edit.rel = model_path("model.decal", tooling_detail::arg_string(a, "path", true));
    edit.hintDocs = "docs/MODELING.md, \"Texturing\", lists the fields of a decal.";
    const bool hasAdd = a.contains("add"), hasRemove = a.contains("remove"), clear = tooling_detail::arg_bool(a, "clear", false);
    if (hasAdd + hasRemove + int(clear) > 1) fail("invalid_argument", "model.decal: give one of `add`, `remove` and `clear`.", "Add a decal, then remove another with a second call.");
    if (hasAdd && !(a["add"].is_object() || a["add"].is_array()))
        fail("invalid_argument", "model.decal: `add` must be a decal object (or a list of them) such as {\"image\":\"assets/textures/logo.png\",\"position\":[0,0.5,0.5],\"normal\":\"front\",\"size\":[0.3,0.3]}.",
             "Fields: name, image, position, size (required: image, position, size), normal, depth, rotation, opacity, tint, maxAngle, parts, faces.");
    if (hasRemove && !(a["remove"].is_string() || a["remove"].is_array()))
        fail("invalid_argument", "model.decal: `remove` must be the name of a decal (or a list of names).", "Names are in model.texture's result (texturing.decals) and in the document.");

    edit.json = read_document(projectDir, edit.rel);
    edit.before = edit.json;
    Json section = edit.json.contains("texturing") && edit.json["texturing"].is_object() ? edit.json["texturing"] : Json::object();
    Json decals = section.contains("decals") && section["decals"].is_array() ? section["decals"] : Json::array();
    std::vector<std::string> changes;
    bool addedUv = false;
    if (hasAdd) {
        const Json list = a["add"].is_array() ? a["add"] : Json::array({a["add"]});
        for (Json d : list) {
            if (d.is_object() && !d.contains("name")) d["name"] = fresh_decal_name(decals);
            // a decal with a name that exists replaces it
            const std::string name = d.is_object() && d["name"].is_string() ? d["name"].get<std::string>() : std::string();
            bool replaced = false;
            for (Json& old : decals)
                if (!name.empty() && old.is_object() && old.value("name", std::string()) == name) {
                    old = d;
                    replaced = true;
                }
            if (!replaced) decals.push_back(d);
            changes.push_back((replaced ? "replaced " : "added ") + (name.empty() ? std::string("a decal") : "'" + name + "'"));
        }
    } else if (hasRemove) {
        const std::vector<std::string> names = a["remove"].is_string() ? std::vector<std::string>{a["remove"].get<std::string>()} : [&] {
            std::vector<std::string> out;
            for (const Json& n : a["remove"])
                if (n.is_string()) out.push_back(n.get<std::string>());
            return out;
        }();
        std::vector<std::string> known;
        for (const Json& d : decals)
            if (d.is_object() && d.contains("name") && d["name"].is_string()) known.push_back(d["name"].get<std::string>());
        for (const std::string& n : names) {
            if (std::find(known.begin(), known.end(), n) == known.end())
                fail("not_found", "model.decal: there is no decal '" + n + "' in " + edit.rel + ".", known.empty() ? "The document has no named decals; model.decal add puts one." : did_you_mean(n, known) + " Decals: " + join(known, ", ") + ".");
            Json kept = Json::array();
            for (const Json& d : decals)
                if (!(d.is_object() && d.value("name", std::string()) == n)) kept.push_back(d);
            decals = kept;
            changes.push_back("removed '" + n + "'");
        }
    } else if (clear) {
        if (!decals.empty()) changes.push_back("removed all " + std::to_string(decals.size()));
        decals = Json::array();
    }
    if (hasAdd || hasRemove || clear) {
        if (decals.empty()) section.erase("decals");
        else section["decals"] = decals;
        edit.json["texturing"] = section;
        if (hasAdd) addedUv = ensure_atlas_uv(edit.json);
    }
    ModelDoc doc = check_document(projectDir, edit);
    {
        ProjectRootGuard root(projectDir);
        auto built = evaluate_model(doc, model_project_eval_options(projectDir));
        if (!built.ok()) fail("failed", edit.rel + ": " + built.error().message, built.error().hint);
    }
    write_document(projectDir, edit);

    Json result = Json::object({{"path", edit.rel}, {"changed", edit.changed()}});
    Json list = Json::array();
    if (doc.texturing) list = model_texturing_json(*doc.texturing).value("decals", Json::array());
    result["decals"] = list;
    if (!changes.empty()) result["changes"] = changes;
    if (addedUv) result["uvAdded"] = Json::object({{"method", "unwrap"}, {"note", "The document had no uv section; decals are baked into an atlas, so {\"method\":\"unwrap\"} was added. model.uv changes it."}});
    std::vector<std::string> steps;
    bake_and_report(projectDir, edit, a, tooling_detail::arg_bool(a, "picture", true), result, steps);
    common_texture_steps(result, steps);
    if (!hasAdd && !hasRemove && !clear) steps.push_back("With no `add`, `remove` or `clear` this only lists the decals. Add one: model.decal {\"path\":\"" + edit.rel + "\",\"add\":{\"image\":\"assets/textures/mark.png\",\"position\":[0,0.5,0.5],\"normal\":\"front\",\"size\":[0.3,0.3]}}.");
    result["nextSteps"] = steps;
    return result;
}

// ---- model.palette ----

Image swatch_picture(const std::vector<Vec4>& palette, const std::string& title) {
    constexpr int kCell = 72, kPerRow = 8, kMargin = 12, kTitle = 28;
    const int rows = std::max(1, int((palette.size() + kPerRow - 1) / kPerRow));
    const int columns = std::min<int>(kPerRow, std::max<int>(1, int(palette.size())));
    Image img;
    img.width = kMargin * 2 + columns * kCell;
    img.height = kMargin * 2 + kTitle + rows * (kCell + 18);
    img.rgba.assign(std::size_t(img.width) * std::size_t(img.height) * 4, 255);
    fill_rect_rgb(img, 0, 0, img.width, img.height, {28, 30, 34});
    draw_text(img, kMargin, kMargin, title, 15, {235, 235, 235});
    auto byte = [](float v) { return std::uint8_t(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
    for (std::size_t i = 0; i < palette.size(); ++i) {
        const int x = kMargin + int(i % kPerRow) * kCell, y = kMargin + kTitle + int(i / kPerRow) * (kCell + 18);
        fill_rect_rgb(img, x + 2, y, kCell - 4, kCell - 4, {byte(palette[i].x), byte(palette[i].y), byte(palette[i].z)});
        draw_text(img, x + 4, y + kCell - 2, std::to_string(i), 12, {210, 210, 210});
    }
    return img;
}

Json model_palette_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.palette", a, "", {"path", "set", "replace", "clear", "bake", "overwrite", "picture"});
    Edit edit;
    edit.command = "model.palette";
    edit.rel = model_path("model.palette", tooling_detail::arg_string(a, "path", true));
    edit.hintDocs = "docs/MODELING.md, \"Texturing\", lists the fields of the vertexColors section.";
    const bool clear = tooling_detail::arg_bool(a, "clear", false), replace = tooling_detail::arg_bool(a, "replace", false), hasSet = a.contains("set");
    if (clear && hasSet) fail("invalid_argument", "model.palette: give `set` or `clear`, not both.", "`clear: true` removes the vertexColors section; `set` changes it.");
    if (hasSet && !a["set"].is_object())
        fail("invalid_argument", "model.palette: `set` must be an object such as {\"palette\": \"style\", \"flat\": true, \"parts\": {\"roof\": {\"color\": \"#8a3b2b\"}}}.", "Fields: palette, snap, flat, variation, seed, color, parts. A null value removes a field.");
    if (replace && !hasSet) fail("invalid_argument", "model.palette: `replace` needs a `set` to put in place of the section.", "Example: {\"set\": {\"flat\": true}, \"replace\": true}.");

    edit.json = read_document(projectDir, edit.rel);
    edit.before = edit.json;
    const Json beforeSection = edit.json.contains("vertexColors") ? edit.json["vertexColors"] : Json();
    if (clear) edit.json.erase("vertexColors");
    else if (hasSet) edit.json["vertexColors"] = merged_vertex_colors(replace ? Json::object() : beforeSection, a["set"]);
    ModelDoc doc = check_document(projectDir, edit);

    ModelBuild build;
    {
        ProjectRootGuard root(projectDir);
        auto built = evaluate_model(doc, model_project_eval_options(projectDir));
        if (!built.ok()) fail("failed", edit.rel + ": " + built.error().message, built.error().hint);
        build = std::move(*built);
    }
    write_document(projectDir, edit);

    Json result = Json::object({{"path", edit.rel}, {"changed", edit.changed()}});
    result["vertexColors"] = doc.vertexColors ? model_vertex_colors_json(*doc.vertexColors) : Json();
    std::vector<Vec4> palette;
    if (build.vertexColors) {
        const ModelVertexColorReport& r = *build.vertexColors;
        Json report = Json::object({{"paletteSize", r.paletteSize}, {"coloredTriangles", r.coloredTriangles}, {"distinctColors", r.distinctColors},
                                    {"verticesBefore", r.verticesBefore}, {"verticesAfter", r.verticesAfter}});
        if (!r.warnings.empty()) report["warnings"] = r.warnings;
        result["report"] = report;
    }
    if (doc.vertexColors) {
        palette = doc.vertexColors->style ? style_palette_colors(projectDir) : doc.vertexColors->palette;
        Json colors = Json::array();
        auto byte = [](float v) { return int(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
        for (const Vec4& c : palette) colors.push_back(std::format("#{:02x}{:02x}{:02x}", byte(c.x), byte(c.y), byte(c.z)));
        result["palette"] = colors;
    }
    if (!build.warnings.empty()) result["warnings"] = build.warnings;
    std::vector<std::string> steps;
    if (!doc.vertexColors) steps.push_back("The document has no vertexColors section. model.palette {\"path\":\"" + edit.rel + "\",\"set\":{\"palette\":\"style\",\"parts\":{\"wall\":{\"color\":0}}}} gives parts colours from a palette.");
    else if (doc.vertexColors->style && palette.empty()) steps.push_back("\"palette\": \"style\" found no palette: the project's assets.json has no style.palette (assets.style sets one), so the colours are not snapped.");
    bake_and_report(projectDir, edit, a, false, result, steps);
    if (tooling_detail::arg_bool(a, "picture", true) && !palette.empty()) {
        const Image sheet = swatch_picture(palette, doc.vertexColors->style ? "style palette (indices as `color` values)" : "palette (indices as `color` values)");
        result["$image"] = image_member(write_temporary_picture(projectDir, sheet, "palette"), true);
    }
    result["nextSteps"] = steps;
    return result;
}

// ---- model.bake_maps ----

Image maps_sheet(const std::vector<std::pair<std::string, const Image*>>& maps, int side, const ModelMapsResult& r) {
    constexpr int kMargin = 12, kHeader = 22, kFooter = 20;
    const int n = int(maps.size());
    Image img;
    img.width = kMargin + n * (side + kMargin);
    img.height = kMargin + kHeader + side + kFooter + kMargin;
    img.rgba.assign(std::size_t(img.width) * std::size_t(img.height) * 4, 255);
    fill_rect_rgb(img, 0, 0, img.width, img.height, {28, 30, 34});
    for (int i = 0; i < n; ++i) {
        const int x = kMargin + i * (side + kMargin), y = kMargin;
        draw_text(img, x, y, maps[std::size_t(i)].first, 15, {235, 235, 235});
        draw_over(img, resize_area(*maps[std::size_t(i)].second, side, side), x, y + kHeader);
        for (const ModelMapStats& s : r.report.maps)
            if (s.name == maps[std::size_t(i)].first) draw_text(img, x, y + kHeader + side + 3, std::format("mean {:.2f}  min {:.2f}  max {:.2f}", s.mean, s.min, s.max), 12, {200, 200, 200});
    }
    return img;
}

Json model_bake_maps_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.bake_maps", a, "", {"path", "maps", "size", "samples", "distance", "thicknessDistance", "edgeAngle", "edgeWidth", "picture"});
    const std::string rel = model_path("model.bake_maps", tooling_detail::arg_string(a, "path", true));
    Json json = read_document(projectDir, rel);
    bool addedUv = ensure_atlas_uv(json);
    std::vector<ModelIssue> issues;
    auto doc = parse_model_doc(json, rel, &issues);
    if (!doc.ok())
        throw CommandError("invalid_document", doc.error().message, doc.error().hint.empty() ? "schemas/model.schema.json describes the format." : doc.error().hint, Json::object({{"path", rel}, {"issues", issues_json(issues)}}));
    if (doc->uv && doc->uv->layout != "atlas")
        fail("invalid_argument", "model.bake_maps: the maps are baked into a uv atlas, but the uv section's layout is \"" + doc->uv->layout + "\".", "Set the uv layout to \"atlas\" (model.uv), or measure on a copy of the model.");

    std::vector<std::string> maps = {"ao", "curvature", "thickness"};
    if (a.contains("maps")) {
        if (!a["maps"].is_array() || a["maps"].empty()) fail("invalid_argument", "model.bake_maps: `maps` must be a list such as [\"ao\", \"curvature\"].", "Maps: ao, curvature, thickness. Leave it out for all three.");
        maps.clear();
        for (const Json& m : a["maps"]) {
            const std::string name = m.is_string() ? m.get<std::string>() : std::string();
            static const std::vector<std::string> all = {"ao", "curvature", "thickness"};
            if (std::find(all.begin(), all.end(), name) == all.end())
                fail("invalid_argument", "model.bake_maps: '" + (m.is_string() ? name : m.dump()) + "' is not a map.", did_you_mean(name, all) + " Maps: ao, curvature, thickness.");
            if (std::find(maps.begin(), maps.end(), name) == maps.end()) maps.push_back(name);
        }
    }
    ModelMapSettings settings = doc->texturing ? doc->texturing->maps : ModelMapSettings{};
    auto number = [&](const char* key, double lo, double hi, double& value) {
        if (!a.contains(key)) return;
        if (!a[key].is_number() || a[key].get<double>() < lo || a[key].get<double>() > hi)
            fail("invalid_argument", std::string("model.bake_maps: `") + key + "` must be a number from " + std::to_string(lo) + " to " + std::to_string(hi) + ".", "Leave it out for the model's texturing.maps value, or the default.");
        value = a[key].get<double>();
    };
    {
        double samples = settings.samples, distance = settings.distance, thick = settings.thicknessDistance, angle = settings.edgeAngle, width = settings.edgeWidth;
        number("samples", 4, kModelTextureMaxSamples, samples);
        number("distance", 0, 10000, distance);
        number("thicknessDistance", 0, 10000, thick);
        number("edgeAngle", 1, 179, angle);
        number("edgeWidth", 0, 10000, width);
        settings.samples = int(samples);
        settings.distance = float(distance);
        settings.thicknessDistance = float(thick);
        settings.edgeAngle = float(angle);
        settings.edgeWidth = float(width);
    }
    ModelBuild build;
    {
        ProjectRootGuard root(projectDir);
        auto built = evaluate_model(*doc, model_project_eval_options(projectDir));
        if (!built.ok()) fail("failed", rel + ": " + built.error().message, built.error().hint);
        build = std::move(*built);
    }
    int size = doc->texturing && doc->texturing->size > 0 ? doc->texturing->size : (build.uv ? build.uv->textureSize : 0);
    if (a.contains("size")) {
        if (!a["size"].is_number_integer() || a["size"].get<long long>() < kModelTextureMinSize || a["size"].get<long long>() > kModelTextureMaxSize)
            fail("invalid_argument", std::format("model.bake_maps: `size` must be an integer from {} to {}.", kModelTextureMinSize, kModelTextureMaxSize), "Use a power of two such as 512 or 1024; leave it out for the model's own texture size.");
        size = int(a["size"].get<long long>());
    }
    if (size <= 0) size = 512;
    const int bleed = doc->texturing && doc->texturing->bleed >= 0 ? doc->texturing->bleed : (doc->uv ? doc->uv->padding : 2);
    auto baked = bake_model_maps(build.data, size, bleed, settings, maps);
    if (!baked.ok()) fail("failed", rel + ": " + baked.error().message, baked.error().hint);

    Json result = Json::object({{"path", rel}, {"size", baked->size}, {"samples", settings.samples}});
    result["report"] = model_texture_detail::report_json(baked->report);
    if (addedUv) result["uvAdded"] = Json::object({{"method", "unwrap"}, {"note", "The document has no uv section: the maps were measured on the atlas an unwrap makes (nothing was written)."}});
    std::vector<std::pair<std::string, const Image*>> pictures;
    if (!baked->ao.empty()) pictures.emplace_back("ao", &baked->ao);
    if (!baked->curvature.empty()) pictures.emplace_back("curvature", &baked->curvature);
    if (!baked->thickness.empty()) pictures.emplace_back("thickness", &baked->thickness);
    if (tooling_detail::arg_bool(a, "picture", true) && !pictures.empty())
        result["$image"] = image_member(write_temporary_picture(projectDir, maps_sheet(pictures, std::min(size, pictures.size() > 2 ? 320 : 480), *baked), "maps"), true);
    std::vector<std::string> steps = {
        "Nothing was written. To keep a map as a picture next to the model, list it in texturing.maps.write (model.texture {\"path\":\"" + rel + "\",\"set\":{\"maps\":{\"write\":[\"" + maps.front() + "\"]}}}); to use one, add a wear entry (mask \"edges\", \"cavity\", \"ao\" or \"thickness\").",
        "ao: 1 (white) is open, darker is occluded; curvature: 0.5 grey is flat, lighter is convex, darker concave; thickness: darker is a thin shell."};
    for (const std::string& w : baked->report.warnings) steps.push_back(w);
    result["nextSteps"] = steps;
    return result;
}

Json prop(const char* type, const char* description) { return Json::object({{"type", type}, {"description", description}}); }
Json prop_default(const char* type, const char* description, Json def) { return Json::object({{"type", type}, {"default", def}, {"description", description}}); }

}  // namespace

void register_model_texture_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = "model.texture";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Texture a model document: materials with tiling textures projected triplanar into the UV atlas, vertex colours, baked ambient occlusion and wear (worn edges, dirt in cavities) built from baked curvature and thickness, "
                       "and decals; the result is a layered image document you can paint on. Returns the texture picture.";
        info.description =
            "The `texturing` section of a model document (docs/MODELING.md, \"Texturing\") makes the CPU "
            "bake the model's colour into its UV atlas (it needs a `uv` section with layout \"atlas\"; with "
            "none, {\"method\":\"unwrap\"} is added). Example: "
            "{\"path\":\"assets/models/crate.model.json\",\"set\":{\"size\":1024,\"ao\":true,\"wear\":[{\"mask\":\"edges\",\"color\":\"#d9d2c0\"},{\"mask\":\"cavity\",\"color\":\"#2a2018\",\"amount\":0.6}]}}"
            FA_COMMAND_DETAILS
            "What goes into the picture: the colour of each material (a material with a `texture` is "
            "projected along the three axes and blended by the normal, `textureScale` metres per repeat, "
            "`textureOffset`, `sharpness`, `tint` on the material; the texture never goes through the "
            "model's uvs once the section exists), the vertex colours (`vertexColors` section: \"bake\" puts "
            "them in the picture, \"keep\" leaves them on the mesh), `ao` (ambient occlusion multiplied in: "
            "true or {strength, parts}), `wear` (a list of {mask: edges | cavity | ao | thickness, color, "
            "amount, width, threshold, noise, noiseScale, seed, upBias, parts}: worn paint on convex edges, "
            "dirt in concave corners, dust on top faces) and `decals` (see model.decal). `maps` sets how the "
            "occlusion, curvature and thickness are measured (samples, distance, thicknessDistance, "
            "edgeAngle, edgeWidth) and `write` lists the maps also kept as grey pictures next to the model. "
            "`size` 0 uses the uv section's texture size; `bleed` spreads the colours past each piece so "
            "mipmaps do not show the background. The bake writes the layers as pictures next to the .glb "
            "(<name>.base.png, .decals.png, .wear.png, .occlusion.png, .uv.png) and composes them in the "
            "image document <name>.texture.image.json (M52) whose baked picture is the .glb's base colour "
            "texture; the LOD .glbs of `gameReady` use the same picture. Open that document like any image "
            "(image.info, image.* commands) and paint on the layer \"paint\" or any layer of your own: a "
            "re-bake only rewrites the layers named \"model: ...\" and never touches yours. With `set` the "
            "fields are merged into the section (a null removes one; `maps` merges field by field, `wear` "
            "and `decals` are replaced as lists), `replace: true` puts `set` in place of the section, "
            "`clear: true` removes it. The document is checked as a whole and a mistake returns every issue "
            "with its JSON pointer and writes nothing. Then the model is baked (unless bake is false). With "
            "no `set` or `clear` it bakes only if something is out of date and reports. The result has the "
            "section with its defaults, `texture` (the image document, the picture, the layer pictures, the "
            "measurements: texels covered, overlap, each map's mean/min/max, each wear and decal's coverage, "
            "each part's mapping) and warnings, and a picture of the baked texture.";
        info.inputSchema = Json::object(
            {{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
             {"properties",
              obj({{"path", prop("string", "The model document, project-relative, under assets/, ending in .model.json.")},
                   {"set", prop("object", "Fields of the texturing section to change: size, bleed, vertexColors, background, document, ao, maps, wear, decals. A null value removes a field; maps merges field by field; wear and decals are replaced whole (model.decal edits single decals).")},
                   {"replace", prop_default("boolean", "Put `set` in place of the whole section instead of merging it.", false)},
                   {"clear", prop_default("boolean", "Remove the texturing section. The layer pictures go with the next bake; the texture's image document and what you painted stay.", false)},
                   {"bake", prop_default("boolean", "Bake the model and its texture again after a change.", true)},
                   {"overwrite", prop_default("boolean", "Replace a .glb that no model document baked.", false)},
                   {"picture", prop_default("boolean", "Return the baked texture ($image).", true)}})}});
        mark_paths(info.inputSchema, "write", {"path"});
        registry.add(info, [projectDir](const Json& args) { return model_texture_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "model.decal";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Add, replace, remove or clear the decals of a model document: pictures (logos, stains, markings) projected on its surface and baked into the texture.";
        info.description =
            "A decal is an image of the project (assets.generate_texture output, or the baked png of an "
            "image document) projected along the opposite of its `normal` from `position` (model space, "
            "metres), `size` [w, h] metres, `rotation` degrees around the normal, `opacity`, `tint`, `depth` "
            "(how far from the plane through `position` the projection reaches, each way; 0 = the smaller "
            "side), `maxAngle` (surfaces turned more than this away from `normal` are left alone, default "
            "75). `parts` restricts it to named parts and `faces` to the faces of a selection query "
            "(model.select tries one). Decals are composited in order into the layer \"model: decals\" of "
            "the texture; transparent pixels of the image stay transparent. `add` takes one decal or a list "
            "(a decal whose name exists replaces it; a missing name becomes decal1, decal2...); `remove` "
            "takes a name or a list; `clear` removes all. With none of them it only lists. Example: "
            "{\"path\":\"assets/models/crate.model.json\",\"add\":{\"name\":\"label\",\"image\":\"assets/textures/label.png\",\"position\":[0,0.2,0.5],\"normal\":\"front\",\"size\":[0.4,0.25]}}"
            FA_COMMAND_DETAILS
            "Adding decals to a model with no texturing section creates one (and a uv unwrap when it has no "
            "uv section). The decals must name existing images and the whole document is checked first; "
            "nothing is written on a mistake. The report says how many texels each decal painted: 0 means it "
            "missed the surface.";
        info.inputSchema = Json::object(
            {{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
             {"properties",
              obj({{"path", prop("string", "The model document, project-relative, under assets/, ending in .model.json.")},
                   {"add", Json::object({{"type", Json::array({"object", "array"})}, {"description", "A decal {name, image, position, size, normal, depth, rotation, opacity, tint, maxAngle, parts, faces} or a list of them. An existing name is replaced."}})},
                   {"remove", Json::object({{"type", Json::array({"string", "array"})}, {"description", "The name of a decal to remove, or a list of names."}})},
                   {"clear", prop_default("boolean", "Remove every decal.", false)},
                   {"bake", prop_default("boolean", "Bake the model and its texture again after a change.", true)},
                   {"overwrite", prop_default("boolean", "Replace a .glb that no model document baked.", false)},
                   {"picture", prop_default("boolean", "Return the baked texture ($image).", true)}})}});
        mark_paths(info.inputSchema, "write", {"path"});
        registry.add(info, [projectDir](const Json& args) { return model_decal_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "model.palette";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Colour a model with a palette without a texture: the `vertexColors` section (style palette or your own colours, one colour or a gradient per part, flat low-poly faces); returns the palette swatches.";
        info.description =
            "The `vertexColors` section of a model document writes colours into the mesh while it is "
            "evaluated, so a low-poly model needs no texture. `palette` is \"style\" (the project's "
            "assets.json style.palette) or a list of colours; with a palette every colour snaps to the "
            "nearest one (`snap: false` turns that off). `color` is the colour of the parts with no entry; "
            "`parts` gives each part (by name, \"\" for nodes with no part) `color` (a colour or the index "
            "of a palette colour), or a `gradient` {axis, from, to, via, range} along a model axis, and its "
            "own `variation`. `flat: true` gives every triangle one colour (vertices are split: the faceted "
            "look); `variation` (0..0.5) changes each triangle's or vertex's brightness a little, "
            "deterministically from `seed`. Colours are \"#rrggbb\", \"#rrggbbaa\" or [r, g, b, a] from 0 to "
            "1. Example: "
            "{\"path\":\"assets/models/house.model.json\",\"set\":{\"palette\":\"style\",\"flat\":true,\"variation\":0.05,\"parts\":{\"roof\":{\"color\":2},\"wall\":{\"gradient\":{\"from\":0,\"to\":1,\"axis\":\"y\"}}}}}"
            FA_COMMAND_DETAILS
            "The colours multiply any the nodes already have, and go into the .glb as vertex colours (or "
            "into the texture when the document has a `texturing` section). A bake that used the style "
            "palette is stale when the style guide's palette changes. With `set` the fields are merged (a "
            "null removes one; `parts` merges part by part), `replace` puts `set` in place of the section, "
            "`clear` removes it; the document is checked as a whole first. The result has the section, the "
            "palette as hex, the report (triangles coloured, distinct colours, vertices before and after the "
            "split) and warnings (a part name the model does not have).";
        info.inputSchema = Json::object(
            {{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
             {"properties",
              obj({{"path", prop("string", "The model document, project-relative, under assets/, ending in .model.json.")},
                   {"set", prop("object", "Fields of the vertexColors section to change: palette, snap, flat, variation, seed, color, parts. A null value removes a field; parts merges part by part (a null part is removed).")},
                   {"replace", prop_default("boolean", "Put `set` in place of the whole section instead of merging it.", false)},
                   {"clear", prop_default("boolean", "Remove the vertexColors section.", false)},
                   {"bake", prop_default("boolean", "Bake the .glb again after a change.", true)},
                   {"overwrite", prop_default("boolean", "Replace a .glb that no model document baked.", false)},
                   {"picture", prop_default("boolean", "Return the palette swatches ($image) when there is a palette.", true)}})}});
        mark_paths(info.inputSchema, "write", {"path"});
        registry.add(info, [projectDir](const Json& args) { return model_palette_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "model.bake_maps";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Bake a model's ambient occlusion, curvature and thickness maps in its UV atlas and measure them (nothing is written): the masks that texturing wear is built from. Returns the maps as pictures.";
        info.description =
            "Measures the maps that `texturing` wear and `ao` use, so you can choose thresholds before changing the document. ao: 1 (white) is open, lower is occluded by the rest of the model (rays up to `distance`, `samples` per texel); "
            "curvature: 0.5 grey is flat, lighter is a convex edge, darker a concave corner (sharp edges turn the surface by at least `edgeAngle` degrees and give a band `edgeWidth` metres wide); thickness: how far the inside of the shell is "
            "from the opposite surface up to `thicknessDistance`, darker is thin. All three are CPU and deterministic. The defaults are the document's texturing.maps (else samples 16, distance 15% and thicknessDistance 50% of the model's diagonal, edgeAngle 20, edgeWidth 3% of the diagonal). "
            "The atlas is the document's `uv` section (a model with none is unwrapped for the measurement; nothing is written). `size` defaults to texturing.size, else the uv texture size. "
            "The result has each map's mean, min, max and coverage over the covered texels, the texels covered and the share claimed by two pieces, and one picture with the maps side by side. "
            "To keep the maps as pictures next to the model add them to texturing.maps.write; to paint with them add wear entries (model.texture). "
            "Example: {\"path\":\"assets/models/crate.model.json\",\"maps\":[\"ao\",\"curvature\"],\"size\":512}";
        info.inputSchema = Json::object(
            {{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
             {"properties",
              obj({{"path", prop("string", "The model document, project-relative, under assets/, ending in .model.json.")},
                   {"maps", Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}, {"enum", Json::array({"ao", "curvature", "thickness"})}})}, {"description", "The maps to bake; default all three."}})},
                   {"size", prop("integer", "Side of the atlas in texels (16..4096); default texturing.size, else the uv section's texture size.")},
                   {"samples", prop("integer", "Rays per texel for ao and thickness (4..256); default texturing.maps.samples or 16.")},
                   {"distance", prop("number", "Metres an occluder may be away; 0 = 15% of the model's diagonal.")},
                   {"thicknessDistance", prop("number", "Metres the thickness is measured up to; 0 = 50% of the diagonal.")},
                   {"edgeAngle", prop("number", "Degrees an edge must turn the surface to count as sharp (1..179).")},
                   {"edgeWidth", prop("number", "Metres wide the band along a sharp edge is; 0 = 3% of the diagonal.")},
                   {"picture", prop_default("boolean", "Return the maps as one picture ($image).", true)}})}});
        mark_paths(info.inputSchema, "read", {"path"});
        registry.add(info, [projectDir](const Json& args) { return model_bake_maps_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    // Capabilities (capability.h): texture, decal and palette change a document (and bake it); bake_maps measures in memory and makes a temporary
    // picture, so it is declared like the preview commands (model.preview, anim3d.preview): changes_state.
    using namespace capability_sets;
    declare_command_capabilities(registry, {{"model.texture", writes_project()}, {"model.decal", writes_project()}, {"model.palette", writes_project()},
                                            {"model.bake_maps", changes_state()}});
}

}  // namespace fa::assets_detail
