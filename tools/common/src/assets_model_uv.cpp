// model.uv: the `uv` section of a model document (docs/MODELING.md, "UVs"): set, merge or clear it, measure what it makes (texel density, stretch,
// seams, overlap, how full the texture is) and draw the UV layout. The maker is fa_scene's (fa/scene/model_uv.h).
#include <algorithm>
#include <atomic>
#include <cmath>
#include <format>

#include "assets_internal.h"
#include "fa/core/screenshot_files.h"
#include "fa/core/strings.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/project_fs.h"
#include "picture_canvas.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

using picture::Canvas;
using picture::Rgb;

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}

std::string uv_doc_path(const std::string& arg) {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", "`path` '" + arg + "' is not a model document under assets/.", "Model documents live in assets/, e.g. \"assets/models/door.model.json\".");
    if (!ends_with(to_lower(*norm), kModelDocSuffix))
        fail("invalid_argument", "'" + *norm + "' does not end in .model.json.", "Name model documents <name>.model.json, e.g. \"assets/models/door.model.json\".");
    return *norm;
}

Json issues_json(const std::vector<ModelIssue>& issues) {
    Json list = Json::array();
    for (const ModelIssue& i : issues) list.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return list;
}

// The `set` of model.uv merged over the section: a field replaces, null removes it; `parts` merges part by part (and field by field).
Json merged_uv(const Json& base, const Json& set) {
    Json out = base.is_object() ? base : Json::object();
    for (auto it = set.begin(); it != set.end(); ++it) {
        if (it.key() == "parts" && it.value().is_object()) {
            Json parts = out.contains("parts") && out["parts"].is_object() ? out["parts"] : Json::object();
            for (auto p = it.value().begin(); p != it.value().end(); ++p) {
                if (p.value().is_null()) {
                    parts.erase(p.key());
                    continue;
                }
                if (!p.value().is_object()) {
                    parts[p.key()] = p.value();  // the reader says what is wrong with it
                    continue;
                }
                Json one = parts.contains(p.key()) && parts[p.key()].is_object() ? parts[p.key()] : Json::object();
                for (auto f = p.value().begin(); f != p.value().end(); ++f) {
                    if (f.value().is_null()) one.erase(f.key());
                    else one[f.key()] = f.value();
                }
                parts[p.key()] = one;
            }
            if (parts.empty()) out.erase("parts");
            else out["parts"] = parts;
        } else if (it.value().is_null()) {
            out.erase(it.key());
        } else {
            out[it.key()] = it.value();
        }
    }
    return out;
}

// The mesh a build made, as the maker's measuring wants it, and the names of its parts.
ModelMesh mesh_of(const MeshData& d, std::vector<std::string>& names) {
    ModelMesh m;
    for (std::size_t i = 0; i + 2 < d.positions.size(); i += 3) m.positions.push_back({d.positions[i], d.positions[i + 1], d.positions[i + 2]});
    for (std::size_t i = 0; i + 2 < d.normals.size(); i += 3) m.normals.push_back({d.normals[i], d.normals[i + 1], d.normals[i + 2]});
    for (std::size_t i = 0; i + 1 < d.uvs.size(); i += 2) m.uvs.push_back({d.uvs[i], d.uvs[i + 1]});
    m.indices = d.indices;
    m.triParts.assign(d.triangle_count(), 0);
    names.clear();
    for (std::size_t s = 0; s < d.submeshes.size(); ++s) {
        names.push_back(d.submeshes[s].part);
        for (std::uint32_t k = d.submeshes[s].start; k < d.submeshes[s].start + d.submeshes[s].count && k / 3 < m.triParts.size(); k += 3) m.triParts[k / 3] = std::uint32_t(s);
    }
    return m;
}

constexpr Rgb kPartColors[] = {{86, 180, 233}, {230, 159, 0}, {0, 190, 140}, {240, 228, 66}, {204, 121, 167}, {235, 110, 40}, {150, 150, 255}, {200, 200, 200}};

std::filesystem::path next_layout_file(const std::string& projectDir) {
    static std::atomic<int> counter{0};
    const std::filesystem::path dir = project_file(projectDir, kScreenshotDir);
    std::error_code ec;
    for (;;) {
        const std::filesystem::path file = dir / std::format("frame_{}_uv.png", ++counter);
        if (!std::filesystem::exists(file, ec)) return file;
    }
}

// The UV layout as a picture: the unit square of the texture, every triangle at its uvs (a colour per part, mirrored triangles red, edges dark;
// triangles that overlap look darker), and the numbers underneath.
Image layout_picture(const ModelMesh& mesh, const std::vector<std::string>& names, const ModelUvReport& r) {
    constexpr int kSide = 768, kMargin = 16, kFooter = 64;
    Canvas canvas(kSide + 2 * kMargin, kSide + 2 * kMargin + kFooter, {24, 26, 30});
    float lo_u = 0, hi_u = 1, lo_v = 0, hi_v = 1;
    for (const Vec2& uv : mesh.uvs) {
        lo_u = std::min(lo_u, uv.x);
        hi_u = std::max(hi_u, uv.x);
        lo_v = std::min(lo_v, uv.y);
        hi_v = std::max(hi_v, uv.y);
    }
    const float span = std::max(hi_u - lo_u, hi_v - lo_v);
    const double scale = kSide / double(span > 0 ? span : 1.0f);
    auto px = [&](float u) { return kMargin + (double(u) - double(lo_u)) * scale; };
    auto py = [&](float v) { return kMargin + (double(v) - double(lo_v)) * scale; };
    canvas.rect(int(px(0)), int(py(0)), int(px(1)), int(py(1)), {44, 48, 56});
    for (std::size_t t = 0; t < mesh.triangle_count(); ++t) {
        double x[3], y[3];
        for (int k = 0; k < 3; ++k) {
            const Vec2 uv = mesh.uvs[mesh.indices[t * 3 + std::size_t(k)]];
            x[k] = px(uv.x);
            y[k] = py(uv.y);
        }
        const double area = (x[1] - x[0]) * (y[2] - y[0]) - (x[2] - x[0]) * (y[1] - y[0]);  // image space (y down): negative = drawn counter-clockwise
        const Rgb fill = area > 0 ? Rgb{220, 60, 60} : kPartColors[mesh.triParts[t] % 8];
        const int x0 = std::max(0, int(std::floor(std::min({x[0], x[1], x[2]})))), x1 = std::min(canvas.img.width - 1, int(std::ceil(std::max({x[0], x[1], x[2]}))));
        const int y0 = std::max(0, int(std::floor(std::min({y[0], y[1], y[2]})))), y1 = std::min(canvas.img.height - 1, int(std::ceil(std::max({y[0], y[1], y[2]}))));
        if (area != 0 && (x1 - x0) * (y1 - y0) < 4000000)
            for (int yy = y0; yy <= y1; ++yy)
                for (int xx = x0; xx <= x1; ++xx) {
                    const double cx = xx + 0.5, cy = yy + 0.5;
                    const double w0 = ((x[1] - cx) * (y[2] - cy) - (x[2] - cx) * (y[1] - cy)) / area;
                    const double w1 = ((x[2] - cx) * (y[0] - cy) - (x[0] - cx) * (y[2] - cy)) / area;
                    const double w2 = 1 - w0 - w1;
                    if (w0 >= 0 && w1 >= 0 && w2 >= 0) canvas.blend(xx, yy, fill, 0.45);
                }
        for (int k = 0; k < 3; ++k) canvas.line(x[k], y[k], x[(k + 1) % 3], y[(k + 1) % 3], {12, 12, 14}, 1);
    }
    // the unit square's frame on top
    for (int o = 0; o < 2; ++o) {
        canvas.hline(int(px(0)), int(px(1)), int(py(o ? 1.0f : 0.0f)), {240, 240, 240});
        canvas.vline(int(px(o ? 1.0f : 0.0f)), int(py(0)), int(py(1)), {240, 240, 240});
    }
    const int top = kSide + 2 * kMargin;
    const std::string headline = r.layout == "tile"
                                     ? std::format("tile layout: {:.0f} texels/m on a {}px texture, {} pieces, uv range {:.2f} x {:.2f} (the white square is one repeat)", r.texelsPerMeter, r.textureSize, r.charts, hi_u - lo_u, hi_v - lo_v)
                                     : std::format("atlas {0}x{0}: {1:.0f} texels/m (asked {2:.0f}), {3} pieces, {4:.0f}% of the texture used", r.textureSize, r.texelsPerMeter, r.texelsPerUnit, r.charts, r.utilization * 100);
    canvas.text(headline, kMargin, top + 4, 15, {235, 235, 235});
    canvas.text(std::format("stretch mean {:.2f} worst {:.2f} | seams {} ({:.1f} m) | overlap {:.1f}% | mirrored {} | outside {}", r.stretchMean, std::min(r.stretchMax, 999.0), r.seamEdges, r.seamLength,
                            r.overlap * 100, r.flippedTriangles, r.outsideTriangles),
                kMargin, top + 24, 15, {235, 235, 235});
    int lx = kMargin;
    for (std::size_t p = 0; p < names.size() && p < 8; ++p) {
        canvas.rect(lx, top + 46, lx + 10, top + 56, kPartColors[p % 8]);
        const std::string label = names[p].empty() ? std::string("(no part)") : names[p];
        canvas.text(label, lx + 14, top + 44, 13, {200, 200, 200});
        lx += 14 + int(label.size()) * 8 + 16;
    }
    return std::move(canvas.img);
}

Json model_uv_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.uv", a, "", {"path", "set", "replace", "clear", "bake", "overwrite", "picture"});
    const std::string rel = uv_doc_path(tooling_detail::arg_string(a, "path", true));
    const bool clear = tooling_detail::arg_bool(a, "clear", false), replace = tooling_detail::arg_bool(a, "replace", false);
    const bool hasSet = a.contains("set");
    if (clear && hasSet) fail("invalid_argument", "model.uv: give `set` or `clear`, not both.", "`clear: true` removes the uv section; `set` changes it.");
    if (hasSet && !a["set"].is_object())
        fail("invalid_argument", "model.uv: `set` must be an object such as {\"method\": \"unwrap\", \"texelsPerUnit\": 128}.", "Fields: layout, method, axis, texelsPerUnit, textureSize, padding, seams, rotate, parts. A null value removes a field.");
    if (replace && !hasSet) fail("invalid_argument", "model.uv: `replace` needs a `set` to put in place of the section.", "Example: {\"set\": {\"method\": \"box\"}, \"replace\": true}.");

    auto text = tooling_detail::read_file(project_file(projectDir, rel));
    if (!text) {
        const std::vector<std::string> all = list_model_documents(projectDir);
        fail("not_found", "'" + rel + "' does not exist.", all.empty() ? "Make one with model.create {\"path\":\"" + rel + "\"}." : did_you_mean(rel, all) + " Model documents: " + join(all, ", ") + ".");
    }
    auto parsed = parse_json(*text, rel);
    if (!parsed.ok()) fail("invalid_document", parsed.error().message, parsed.error().hint.empty() ? "Fix the JSON syntax; schemas/model.schema.json describes the format." : parsed.error().hint);
    Json json = std::move(*parsed);
    if (!json.is_object()) fail("invalid_document", rel + ": the document is not an object.", "Fix it by hand or write it again with model.create overwrite: true.");

    const Json before = json.contains("uv") ? json["uv"] : Json();
    if (clear) json.erase("uv");
    else if (hasSet) {
        if (replace) {
            Json fresh = Json::object();
            json["uv"] = merged_uv(fresh, a["set"]);
        } else {
            json["uv"] = merged_uv(before, a["set"]);
        }
    }
    const bool changed = (json.contains("uv") ? json["uv"] : Json()) != before;

    std::vector<ModelIssue> issues;
    auto doc = parse_model_doc(json, rel, &issues);
    if (!doc.ok()) {
        Error e = doc.error();
        if (changed) e.message += std::string(e.message.empty() || e.message.back() == '.' ? " " : ". ") + "Nothing was written.";
        throw CommandError("invalid_document", e.message, e.hint.empty() ? "docs/MODELING.md, \"UVs\", lists the fields of the uv section." : e.hint, Json::object({{"path", rel}, {"issues", issues_json(issues)}}));
    }
    if (changed) {
        require_usable_manifest(projectDir);
        std::string err;
        if (!tooling_detail::write_file(project_write_file(projectDir, rel), dump_json(json), &err)) fail("failed", "Cannot write '" + rel + "': " + err, "Check that the folder is writable.");
    }

    ModelBuild build;
    {
        ProjectRootGuard root(projectDir);
        auto built = evaluate_model(*doc, model_project_eval_options(projectDir));
        if (!built.ok()) fail("failed", rel + ": " + built.error().message, built.error().hint);
        build = std::move(*built);
    }
    std::vector<std::string> names;
    const ModelMesh mesh = mesh_of(build.data, names);
    const bool made = build.uv.has_value();
    const ModelUvReport report = made ? *build.uv : model_uv_measure(mesh, names);

    Json result = Json::object({{"path", rel}, {"changed", changed}});
    result["uv"] = doc->uv ? model_uv_settings_json(*doc->uv) : Json();
    result["source"] = made ? "uv section" : "the primitives' own uvs (the document has no uv section)";
    result["report"] = model_uv_report_json(report);
    if (!build.warnings.empty()) result["warnings"] = build.warnings;  // the build's own: a part name `parts` does not know, a heavy mesh, ...
    if (build.uv) result["styleTexelsPerUnit"] = style_texels_per_unit(projectDir) ? Json(*style_texels_per_unit(projectDir)) : Json();
    std::vector<std::string> steps;
    if (!made) steps.push_back("Add a uv section to give the model one unique, non-overlapping layout: model.uv {\"path\":\"" + rel + "\",\"set\":{\"method\":\"unwrap\"}}.");
    if (!report.warnings.empty()) steps.push_back("Read `report.warnings`: each says what to change (`set` another method for a part, more `seams`, a bigger `textureSize`, a lower `texelsPerUnit`).");

    if (changed && tooling_detail::arg_bool(a, "bake", true)) {
        auto b = bake_model_document(projectDir, rel, {false, tooling_detail::arg_bool(a, "overwrite", false)});
        if (!b.ok()) {
            result["bake"] = Json::object({{"state", "failed"}, {"message", b.error().message}, {"hint", b.error().hint}});
            steps.push_back("The document was written but could not be baked: " + b.error().message + " " + b.error().hint);
        } else {
            result["bake"] = Json::object({{"state", "baked"}, {"output", b->output}, {"bytes", b->bytes}});
        }
    } else {
        const ModelBakeStatus status = model_bake_status(projectDir, rel);
        result["bake"] = Json::object({{"state", model_bake_state_name(status.state)}, {"output", status.output}, {"reason", status.reason}});
        if (changed) steps.push_back("The .glb was not rebuilt: model.bake {\"path\":\"" + rel + "\"} does it.");
    }
    if (tooling_detail::arg_bool(a, "picture", true) && mesh.triangle_count() > 0) {
        const Image picture = layout_picture(mesh, names, report);
        const std::filesystem::path file = next_layout_file(projectDir);
        const std::vector<std::uint8_t> png = encode_png(picture);
        std::string err;
        if (!tooling_detail::write_file(file, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err)) fail("failed", err);
        result["$image"] = Json::object({{"path", file.string()}, {"mimeType", "image/png"}, {"temporary", true}});
    }
    result["nextSteps"] = steps;
    return result;
}

}  // namespace

Json model_uv_report_json(const ModelUvReport& r) {
    Json parts = Json::array();
    for (const ModelUvPartReport& p : r.parts)
        parts.push_back(obj({{"part", p.part}, {"method", p.method}, {"triangles", p.triangles}, {"charts", p.charts}, {"texelsPerMeter", round_to(p.texelsPerMeter, 2)},
                             {"stretchMean", round_to(p.stretchMean, 3)}, {"stretchMax", round_to(std::min(p.stretchMax, 1e6), 3)}}));
    Json out = obj({{"layout", r.layout},
                    {"textureSize", r.textureSize},
                    {"texelsPerUnit", round_to(r.texelsPerUnit, 2)},
                    {"texelsPerUnitUsed", round_to(r.texelsPerUnitUsed, 2)},
                    {"triangles", r.triangles},
                    {"charts", r.charts},
                    {"surfaceArea", round_to(r.surfaceArea, 4)},
                    {"texelsPerMeter", obj({{"mean", round_to(r.texelsPerMeter, 2)}, {"min", round_to(r.texelsPerMeterMin, 2)}, {"max", round_to(r.texelsPerMeterMax, 2)}})},
                    {"stretch", obj({{"mean", round_to(r.stretchMean, 3)}, {"max", round_to(std::min(r.stretchMax, 1e6), 3)}})},
                    {"seams", obj({{"edges", r.seamEdges}, {"length", round_to(r.seamLength, 3)}})},
                    {"flippedTriangles", r.flippedTriangles},
                    {"utilization", round_to(r.utilization, 4)},
                    {"overlap", round_to(r.overlap, 4)},
                    {"outsideTriangles", r.outsideTriangles},
                    {"parts", parts}});
    if (!r.warnings.empty()) out["warnings"] = r.warnings;
    return out;
}

void register_model_uv_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "model.uv";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Give a model document UVs (automatic unwrap, or box, cylinder, sphere and planar projections per part, packed into one texture at the style's texel density) and measure them; returns the UV layout picture.";
    info.description =
        "The `uv` section of a model document replaces the primitives' own uvs: `layout` \"atlas\" (default) "
        "packs every piece into one texture painted for this model, \"tile\" gives world-scale uvs that "
        "continue across the model and repeat. `method` is \"unwrap\" (xatlas cuts the surface into pieces "
        "and flattens each with little stretch; atlas default), or a projection: \"box\" (each face on the "
        "axis plane it looks at; tile default), \"cylinder\" and \"sphere\" (around `axis`), \"planar\" "
        "(along `axis`); `parts` overrides method, axis and texelsPerUnit per part name, so a wheel can be a "
        "cylinder and a body unwrapped. `texelsPerUnit` is texels per metre (default the project's "
        "assets.json style.texelsPerUnit, else 128); `textureSize` 0 picks the smallest power of two the "
        "pieces fit in, a fixed size the pieces do not fit lowers the density (a warning says so); `padding` "
        "empties texels around each piece; `seams` few, balanced or many; `rotate` lets the packer turn "
        "pieces. Example: "
        "{\"path\":\"assets/models/crate.model.json\",\"set\":{\"method\":\"unwrap\",\"texelsPerUnit\":256,\"parts\":{\"wheel\":{\"method\":\"cylinder\",\"axis\":\"x\"}}}}"
        FA_COMMAND_DETAILS
        "The same spec works on sdf organic shapes, whose default box uvs it replaces. With `set` the fields "
        "are merged into the section (a null value removes a field; `parts` merges part by part), `replace: "
        "true` puts `set` in place of the section, `clear: true` removes it; the document is checked as a "
        "whole and a mistake returns every issue with its JSON pointer and writes nothing. Then the .glb is "
        "baked again (unless bake is false). The result measures the uvs: texels per metre (mean, min, max, "
        "per part), stretch (1 = none, 2 = a texture drawn twice as long one way as the other), seams, "
        "mirrored triangles, how full the texture is, overlap and uvs outside 0..1, with warnings that say "
        "what to change; with no `set` or `clear` it only measures (a document with no uv section is "
        "measured on its primitives' own uvs). Unless picture is false it returns the layout (`$image`): the "
        "texture square with every triangle at its uvs, a colour per part, mirrored triangles red.";
    info.inputSchema = Json::object(
        {{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
         {"properties",
          obj({{"path", Json::object({{"type", "string"}, {"description", "The model document, project-relative, under assets/, ending in .model.json."}})},
               {"set", Json::object({{"type", "object"}, {"description", "Fields of the uv section to change: layout, method, axis, texelsPerUnit, textureSize, padding, seams, rotate, parts. A null value removes a field; parts merges part by part (a null part is removed)."}})},
               {"replace", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Put `set` in place of the whole section instead of merging it."}})},
               {"clear", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Remove the uv section: the model keeps its primitives' own uvs."}})},
               {"bake", Json::object({{"type", "boolean"}, {"default", true}, {"description", "Bake the .glb again after a change."}})},
               {"overwrite", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Replace a .glb that no model document baked."}})},
               {"picture", Json::object({{"type", "boolean"}, {"default", true}, {"description", "Return the UV layout picture ($image)."}})}})}});
    mark_paths(info.inputSchema, "write", {"path"});
    registry.add(info, [projectDir](const Json& args) { return model_uv_command(projectDir, args.is_null() ? Json::object() : args); });
    using namespace capability_sets;  // capability.h: changes the document's uv section and bakes it
    declare_command_capabilities(registry, {{"model.uv", writes_project()}});
}

}  // namespace fa::assets_detail
