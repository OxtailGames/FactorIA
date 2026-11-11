// model.import_clean: a generated or imported mesh (.glb, .gltf, .obj) is cleaned (fa_scene's model_import_clean: weld, floating pieces, winding,
// scale, origin, optional SDF remesh, decimation to a platform budget) and wrapped in a model document whose `mesh` node reads the cleaned mesh, so
// modifiers, selections, uv and gameReady apply to it (docs/MODELING.md, "Cleaning an imported mesh"). The mesh work is fa_scene's; this is the
// project side: reading the file, the textures, the files written, the document and the bake.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>

#include "assets_internal.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/scene/gltf_mesh.h"
#include "fa/scene/model_game_ready.h"
#include "fa/scene/model_import_clean.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/project_fs.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}
Json num(const char* what, std::optional<double> min = std::nullopt, std::optional<double> max = std::nullopt, std::optional<double> def = std::nullopt) {
    Json j = Json::object({{"type", "number"}, {"description", what}});
    if (min) j["minimum"] = *min;
    if (max) j["maximum"] = *max;
    if (def) j["default"] = *def;
    return j;
}
Json str(const char* what) { return Json::object({{"type", "string"}, {"description", what}}); }
Json boolean(const char* what, bool def) { return Json::object({{"type", "boolean"}, {"default", def}, {"description", what}}); }
Json choice(const char* what, std::vector<std::string> values, const char* def) {
    return Json::object({{"type", "string"}, {"enum", values}, {"default", def}, {"description", what}});
}

std::optional<double> opt_number(const Json& a, const char* key) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return std::nullopt;
    if (!it->is_number()) fail("invalid_argument", std::string("model.import_clean: `") + key + "` must be a number, got " + describe_json_value(*it) + ".", std::string("Example: {\"") + key + "\": 1.8}.");
    return it->get<double>();
}

void check_choice(const char* key, const std::string& value, const std::vector<std::string>& allowed) {
    if (std::find(allowed.begin(), allowed.end(), value) != allowed.end()) return;
    fail("invalid_argument", std::string("model.import_clean: `") + key + "` '" + value + "' is not one of " + join(allowed, ", ") + ". " + did_you_mean(value, allowed), "Pick one of the listed values.");
}

// Project-relative files under assets/ with one of `exts`, for "did you mean" (at most 400 looked at).
std::vector<std::string> candidate_files(const std::string& projectDir, const std::vector<std::string>& exts) {
    std::vector<std::string> out;
    std::error_code ec;
    const stdfs::path root = stdfs::path(projectDir) / "assets";
    if (!stdfs::exists(root, ec)) return out;
    for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end && out.size() < 400; it.increment(ec)) {
        if (!it->is_regular_file(ec)) continue;
        const std::string ext = to_lower(it->path().extension().string());
        if (std::find(exts.begin(), exts.end(), ext) == exts.end()) continue;
        out.push_back(stdfs::relative(it->path(), projectDir, ec).generic_string());
    }
    std::sort(out.begin(), out.end());
    return out;
}

std::string stem_of(const std::string& rel) {
    const std::string name = rel.substr(rel.find_last_of('/') == std::string::npos ? 0 : rel.find_last_of('/') + 1);
    const auto dot = name.find('.');
    return dot == std::string::npos ? name : name.substr(0, dot);
}

Json color_json(Color c) { return Json::array({round_to(c.r, 4), round_to(c.g, 4), round_to(c.b, 4), round_to(c.a, 4)}); }

Json material_json(const MeshMaterial& m) {
    Json j = Json::object({{"color", color_json(m.color)}});
    if (!m.texture.empty()) j["texture"] = m.texture;
    if (m.metallic) j["metallic"] = round_to(*m.metallic, 4);
    if (m.roughness) j["roughness"] = round_to(*m.roughness, 4);
    if (m.emissive.r > 0 || m.emissive.g > 0 || m.emissive.b > 0) j["emissive"] = color_json(m.emissive);
    if (m.doubleSided) j["doubleSided"] = true;
    if (m.blend) j["blend"] = true;
    return j;
}

// Bilinear colour of a base colour texture at a uv (repeat wrap, v down), RGBA 0..1.
Vec4 sample_image(const Image& img, Vec2 uv) {
    auto wrap = [](float t) { return t - std::floor(t); };
    const float fx = wrap(uv.x) * float(img.width) - 0.5f, fy = wrap(uv.y) * float(img.height) - 0.5f;
    const int x0 = int(std::floor(fx)), y0 = int(std::floor(fy));
    const float tx = fx - float(x0), ty = fy - float(y0);
    auto px = [&](int x, int y) {
        x = ((x % img.width) + img.width) % img.width;
        y = ((y % img.height) + img.height) % img.height;
        const std::uint8_t* p = &img.rgba[(std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 4];
        return Vec4{float(p[0]) / 255.0f, float(p[1]) / 255.0f, float(p[2]) / 255.0f, float(p[3]) / 255.0f};
    };
    return lerp(lerp(px(x0, y0), px(x0 + 1, y0), tx), lerp(px(x0, y0 + 1), px(x0 + 1, y0 + 1), tx), ty);
}

// The height (Y extent, metres) of a reference model: a model document (evaluated) or a .glb/.gltf; "human" is 1.8 m.
double reference_height(const std::string& projectDir, const std::string& ref, std::string& what) {
    if (ref == "human") {
        what = "the 1.8 m human";
        return 1.8;
    }
    auto norm = fs::normalize_checked(ref);
    const std::string lower = norm.ok() ? to_lower(*norm) : std::string();
    if (!norm.ok() || norm->empty() || !(ends_with(lower, kModelDocSuffix) || ends_with(lower, ".glb") || ends_with(lower, ".gltf"))) {
        std::vector<std::string> all = list_model_documents(projectDir);
        for (const std::string& f : candidate_files(projectDir, {".glb", ".gltf"})) all.push_back(f);
        fail("invalid_argument", "model.import_clean: `reference` '" + ref + "' is not \"human\" or a project model (.model.json, .glb, .gltf).",
             (all.empty() ? std::string("Use \"human\" (1.8 m) or give `height` in metres.") : did_you_mean(ref, all) + " Models: " + join(all, ", ") + ".") + " `reference` scales to that model's height.");
    }
    if (!stdfs::exists(project_file(projectDir, *norm)))
        fail("not_found", "model.import_clean: `reference` '" + *norm + "' does not exist.", "Name a model of the project, \"human\", or give `height` in metres.");
    ProjectRootGuard root(projectDir);
    what = "'" + *norm + "'";
    if (ends_with(lower, kModelDocSuffix)) {
        std::vector<ModelIssue> issues;
        auto doc = load_model_doc(*norm, &issues);
        if (!doc.ok()) fail("invalid_document", "model.import_clean: `reference` " + *norm + ": " + doc.error().message, doc.error().hint);
        auto build = evaluate_model(*doc, model_project_eval_options(projectDir));
        if (!build.ok()) fail("failed", "model.import_clean: `reference` " + *norm + ": " + build.error().message, build.error().hint);
        return double(build->stats.bmax.y - build->stats.bmin.y);
    }
    auto read = read_gltf_mesh(*norm);
    if (!read.ok()) fail("failed", "model.import_clean: `reference` " + *norm + ": " + read.error().message, read.error().hint);
    return double(read->data.bmax.y - read->data.bmin.y);
}

Json model_import_clean_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.import_clean", a, "",
                   {"source", "out", "overwrite", "upAxis", "weldDistance", "removeFloating", "minPieceSize", "origin", "height", "reference", "scale", "platform", "triangles", "remesh", "remeshCells", "remeshVoxel",
                    "unwrap", "texelsPerUnit", "bake"});
    ModelCleanOptions o;
    // ---- arguments ----
    const std::string sourceArg = tooling_detail::arg_string(a, "source", true);
    auto src = fs::normalize_checked(sourceArg);
    const std::string srcLower = src.ok() ? to_lower(*src) : std::string();
    if (!src.ok() || src->empty() || !(ends_with(srcLower, ".glb") || ends_with(srcLower, ".gltf") || ends_with(srcLower, ".obj")))
        fail("invalid_argument", "model.import_clean: `source` '" + sourceArg + "' is not a project-relative .glb, .gltf or .obj file.",
             "Put the mesh in the project (assets.import copies a file in) and name it, e.g. \"assets/models/robot.glb\". assets.generate_model writes its result there.");
    std::string source = *src;
    if (!stdfs::exists(project_file(projectDir, source))) {
        const std::vector<std::string> all = candidate_files(projectDir, {".glb", ".gltf", ".obj"});
        fail("not_found", "model.import_clean: `source` '" + source + "' does not exist.", all.empty() ? "Import the mesh first: assets.import {\"source\":\"/path/robot.glb\"}." : did_you_mean(source, all) + " Meshes: " + join(all, ", ") + ".");
    }
    o.upAxis = tooling_detail::arg_string(a, "upAxis", false, "y");
    check_choice("upAxis", o.upAxis, {"y", "z"});
    o.origin = tooling_detail::arg_string(a, "origin", false, "bottom_center");
    check_choice("origin", o.origin, {"keep", "center", "bottom", "bottom_center"});
    const std::string unwrap = tooling_detail::arg_string(a, "unwrap", false, "auto");
    check_choice("unwrap", unwrap, {"auto", "always", "never"});
    const std::string platform = tooling_detail::arg_string(a, "platform", false, "desktop");
    {
        std::vector<std::string> names;
        for (const ModelPlatformBudget& b : model_platform_budgets()) names.push_back(b.platform);
        check_choice("platform", platform, names);
    }
    o.weldDistance = opt_number(a, "weldDistance").value_or(0);
    if (o.weldDistance < 0) fail("invalid_argument", "model.import_clean: `weldDistance` must be 0 or more metres.", "0 welds vertices a millionth of the model's size apart; 0.001 welds 1 mm.");
    o.removeFloating = tooling_detail::arg_bool(a, "removeFloating", true);
    o.minPieceSize = opt_number(a, "minPieceSize").value_or(0.02);
    if (o.minPieceSize < 0 || o.minPieceSize > 1) fail("invalid_argument", "model.import_clean: `minPieceSize` must be between 0 and 1.", "A fraction of the biggest piece's size: 0.02 removes pieces smaller than 2% of it.");
    o.height = opt_number(a, "height");
    o.scale = opt_number(a, "scale");
    const std::string reference = tooling_detail::arg_string(a, "reference", false, "");
    if (int(o.height.has_value()) + int(o.scale.has_value()) + int(!reference.empty()) > 1)
        fail("invalid_argument", "model.import_clean: give only one of `height`, `reference` and `scale`.", "`height` scales to a size in metres, `reference` to another model's height (or \"human\"), `scale` multiplies by a factor.");
    if (o.height && !(*o.height > 0.0001 && *o.height < 100000)) fail("invalid_argument", "model.import_clean: `height` must be between 0.0001 and 100000 metres.", "A person is 1.8, a door 2.1, a house 8.");
    if (o.scale && !(*o.scale > 1e-6 && *o.scale < 1e6)) fail("invalid_argument", "model.import_clean: `scale` must be between 0.000001 and 1000000.", "0.01 turns centimetres into metres, 0.001 millimetres.");
    std::string referenceWhat;
    if (!reference.empty()) o.height = reference_height(projectDir, reference, referenceWhat);
    if (o.height && !(*o.height > 0.0001)) fail("invalid_argument", "model.import_clean: the reference model has no height.", "Use a reference that is taller than 0 or give `height`.");
    o.remesh = tooling_detail::arg_bool(a, "remesh", false);
    o.remeshCells = int(tooling_detail::arg_int(a, "remeshCells", 128));
    if (o.remeshCells < 16 || o.remeshCells > 400) fail("invalid_argument", "model.import_clean: `remeshCells` must be between 16 and 400.", "Cells along the longest side: 128 is a good start, more is finer and slower.");
    o.remeshVoxel = opt_number(a, "remeshVoxel").value_or(0);
    if (o.remeshVoxel < 0) fail("invalid_argument", "model.import_clean: `remeshVoxel` must be 0 or more metres.", "0 uses `remeshCells`.");
    std::size_t budgetTriangles = 0;
    for (const ModelPlatformBudget& b : model_platform_budgets())
        if (b.platform == platform) budgetTriangles = b.triangles;
    const long trianglesArg = tooling_detail::arg_int(a, "triangles", -1);
    if (trianglesArg == 0 || trianglesArg < -1) fail("invalid_argument", "model.import_clean: `triangles` must be 1 or more.", "The most triangles to keep; left out, the `platform` budget (" + platform + ": " + std::to_string(budgetTriangles) + ") is used.");
    o.targetTriangles = trianglesArg > 0 ? std::size_t(trianglesArg) : budgetTriangles;
    const bool bake = tooling_detail::arg_bool(a, "bake", true), overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    const std::optional<double> texels = opt_number(a, "texelsPerUnit");
    if (texels && !(*texels > 0)) fail("invalid_argument", "model.import_clean: `texelsPerUnit` must be above 0.", "Texels per metre of the unwrap, e.g. 128.");

    const std::string stem = stem_of(source);
    const std::string dir = fs::parent(source);
    const std::string prefix = dir.empty() ? std::string() : dir + "/";
    std::string docRel = tooling_detail::arg_string(a, "out", false, prefix + stem + "_clean" + kModelDocSuffix);
    {
        auto n = fs::normalize_checked(docRel);
        if (!n.ok() || n->empty() || !starts_with(*n, "assets/") || !ends_with(to_lower(*n), kModelDocSuffix))
            fail("invalid_argument", "model.import_clean: `out` '" + docRel + "' is not a model document under assets/ ending in .model.json.", "Example: \"assets/models/robot_clean.model.json\".");
        docRel = *n;
    }
    const std::string docStem = docRel.substr(0, docRel.size() - std::string(kModelDocSuffix).size());
    const std::string meshRel = docStem + ".mesh.glb";
    std::error_code ec;
    if (!overwrite && stdfs::exists(project_file(projectDir, docRel), ec))
        fail("exists", "model.import_clean: '" + docRel + "' already exists.", "Pass overwrite: true to replace it, or give another `out`.");
    require_usable_manifest(projectDir);

    ProjectRootGuard root(projectDir);
    Json result = Json::object();
    std::vector<std::string> notes;
    // ---- the .obj goes through the importer, which makes a .gltf ----
    if (ends_with(srcLower, ".obj")) {
        const std::string gltfRel = prefix + stem + ".gltf";
        if (stdfs::exists(project_file(projectDir, gltfRel), ec)) {
            notes.push_back("'" + gltfRel + "' already existed and was used as the conversion of '" + source + "'; delete it to convert the .obj again.");
        } else {
            ImportRequest req;
            req.source = project_file(projectDir, source);
            req.dest = gltfRel;
            auto imported = import_obj(req);
            if (!imported.ok()) fail("failed", "model.import_clean: " + source + ": " + imported.error().message, imported.error().hint.empty() ? "Check that the .obj has `v` and `f` lines." : imported.error().hint);
            for (const OutFile& f : imported->files) {
                std::string err;
                if (!tooling_detail::write_file(project_file(projectDir, f.path), std::string_view(reinterpret_cast<const char*>(f.bytes.data()), f.bytes.size()), &err))
                    fail("failed", "model.import_clean: cannot write '" + f.path + "': " + err, "Check that the folder is writable.");
            }
            for (const std::string& w : imported->warnings) notes.push_back(w);
        }
        result["converted"] = gltfRel;
        source = gltfRel;
    }
    // ---- read ----
    auto read = read_gltf_mesh(source);
    if (!read.ok()) fail("failed", "model.import_clean: " + read.error().message, read.error().hint.empty() ? "Re-export the model as .glb." : read.error().hint);
    GltfMesh& gm = *read;
    if (gm.data.triangle_count() == 0) fail("failed", "model.import_clean: '" + source + "' has no triangles.", "Re-export the model with its mesh (not only lines, points or an empty scene).");
    for (const std::string& w : gm.warnings) notes.push_back(w);
    // embedded textures become project files
    for (const GltfEmbeddedImage& e : gm.embedded) {
        if (e.material >= gm.materials.size()) continue;
        const std::string rel = std::format("{}.tex{}.{}", docStem, e.material + 1, e.extension);
        std::string err;
        if (!tooling_detail::write_file(project_file(projectDir, rel), std::string_view(reinterpret_cast<const char*>(e.bytes.data()), e.bytes.size()), &err))
            fail("failed", "model.import_clean: cannot write '" + rel + "': " + err, "Check that the folder is writable.");
        gm.materials[e.material].texture = rel;
        for (std::size_t s = 0; s < gm.data.submeshes.size(); ++s)
            if (s < gm.submeshMaterial.size() && gm.submeshMaterial[s] == e.material) gm.data.submeshes[s].material.texture = rel;
    }
    // the texture sampler of the remesh
    std::map<std::string, Image> images;
    std::vector<std::string> textureNotes;
    if (o.remesh) {
        for (const MeshSubmesh& sm : gm.data.submeshes) {
            if (sm.material.texture.empty() || images.count(sm.material.name)) continue;
            auto img = load_image(sm.material.texture);
            if (img.ok() && !img->empty()) images.emplace(sm.material.name, std::move(*img));
            else textureNotes.push_back("the texture '" + sm.material.texture + "' of material '" + sm.material.name + "' could not be read" + (img.ok() ? std::string() : ": " + img.error().message));
        }
        if (!images.empty())
            o.textureSampler = [&images](const std::string& material, Vec2 uv) -> std::optional<Vec4> {
                auto it = images.find(material);
                if (it == images.end()) return std::nullopt;
                return sample_image(it->second, uv);
            };
    }
    // ---- clean ----
    auto cleaned = model_import_clean(gm.data, o);
    if (!cleaned.ok()) fail("failed", "model.import_clean: " + source + ": " + cleaned.error().message, cleaned.error().hint);
    ModelCleanReport& rep = cleaned->report;
    MeshData& mesh = cleaned->mesh;
    for (const std::string& n : textureNotes) rep.warnings.push_back(n);
    const bool needUnwrap = unwrap == "always" || (unwrap == "auto" && (!rep.hadUvs || rep.remeshed));
    if (rep.remeshed) {
        // the remesh made new triangles with no uvs: textures cannot stay, their colour is carried by the vertex colours (when it could be read)
        for (MeshSubmesh& sm : mesh.submeshes) sm.material.texture.clear();
    } else if (needUnwrap && rep.hadUvs) {
        for (MeshSubmesh& sm : mesh.submeshes) sm.material.texture.clear();
        rep.warnings.push_back("`unwrap` replaced the mesh's own uvs, so its textures (made for those uvs) no longer fit and were left out of the materials. Paint or generate new ones for the new uvs (assets.generate_texture, model.uv).");
    }
    if (rep.remeshed && rep.texturesDropped && !rep.texturesToColors)
        for (const MeshMaterial& m : gm.materials)
            if (!m.texture.empty()) {
                rep.warnings.push_back("the remesh cannot keep texture coordinates and the base colour texture(s) could not be carried as vertex colours: the materials keep their colour factors only.");
                break;
            }
    for (const std::string& n : notes) rep.warnings.push_back(n);

    // ---- write the cleaned mesh and the document ----
    auto glb = mesh_to_glb(mesh, meshRel);
    if (!glb.ok()) fail("failed", "model.import_clean: " + glb.error().message, glb.error().hint);
    {
        std::string err;
        if (!tooling_detail::write_file(project_file(projectDir, meshRel), std::string_view(reinterpret_cast<const char*>(glb->data()), glb->size()), &err))
            fail("failed", "model.import_clean: cannot write '" + meshRel + "': " + err, "Check that the folder is writable.");
    }
    Json materials = Json::object();
    for (const MeshSubmesh& sm : mesh.submeshes)
        if (!sm.material.name.empty() && !materials.contains(sm.material.name)) materials[sm.material.name] = material_json(sm.material);
    Json doc = Json::object({{"format", kModelDocFormat}});
    doc["doc"] = std::format("Cleaned copy of {} (model.import_clean): welded, {} floating piece(s) removed, scaled x{:.4g}, origin {}{}{}.", source, rep.removedPieceCount, rep.scaleFactor, o.origin,
                             rep.remeshed ? ", remeshed" : "", rep.decimated ? ", decimated" : "");
    if (!materials.empty()) doc["materials"] = materials;
    if (needUnwrap) {
        Json uv = Json::object({{"layout", "atlas"}, {"method", "unwrap"}});
        if (texels) {
            uv["texelsPerUnit"] = *texels;
        } else {
            // The unwrap packs the surface at texels per metre; a model far bigger than a game prop would ask for a texture beyond 4096 and take minutes. Keep the atlas within about 2048.
            const double wanted = [&] {
                const float d = model_project_eval_options(projectDir).defaultTexelsPerMeter;
                return d > 0 ? double(d) : 128.0;
            }();
            const double fit = 1800.0 / std::sqrt(std::max(rep.statsAfter.area, 1e-6));
            if (fit < wanted) {
                const double used = std::max(round_to(fit, 2), 0.01);
                uv["texelsPerUnit"] = used;
                rep.warnings.push_back(std::format("the model has {:.4g} m2 of surface, so the unwrap uses {:g} texels per metre (not {:g}) to keep the texture near 2048 px. If it is not the size of a game object, pass `height`, `reference` or `scale`; or give `texelsPerUnit`.",
                                                   rep.statsAfter.area, used, wanted));
            }
        }
        doc["uv"] = uv;
    }
    doc["nodes"] = Json::array({Json::object({{"op", "mesh"}, {"id", "mesh_1"}, {"source", meshRel}})});
    {
        std::vector<ModelIssue> issues;
        auto parsed = parse_model_doc(doc, docRel, &issues);
        if (!parsed.ok()) {
            Json list = Json::array();
            for (const ModelIssue& i : issues) list.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
            throw CommandError("invalid_document", "model.import_clean: the document it made is not valid: " + parsed.error().message, parsed.error().hint, Json::object({{"path", docRel}, {"issues", list}}));
        }
        std::string err;
        if (!tooling_detail::write_file(project_file(projectDir, docRel), dump_json(doc), &err)) fail("failed", "Cannot write '" + docRel + "': " + err, "Check that the folder is writable.");
        result["output"] = model_document_output(*parsed, docRel);
    }
    result["path"] = docRel;
    result["mesh"] = meshRel;
    result["source"] = source;
    // ---- bake ----
    Json bakeJson;
    std::optional<std::size_t> bakedTriangles;
    if (bake) {
        auto b = bake_model_document(projectDir, docRel, {false, overwrite});
        if (!b.ok()) {
            bakeJson = Json::object({{"state", "failed"}, {"message", b.error().message}, {"hint", b.error().hint}});
            rep.warnings.push_back("the document was written but not baked: " + b.error().message + " " + b.error().hint);
        } else {
            bakeJson = Json::object({{"state", "baked"}, {"output", b->output}, {"bytes", b->bytes}});
            bakedTriangles = b->build.stats.triangles;
            result["provenance"] = b->provenance;
            for (const std::string& w : b->build.warnings) rep.warnings.push_back(w);
        }
    } else {
        const ModelBakeStatus st = model_bake_status(projectDir, docRel);
        bakeJson = Json::object({{"state", model_bake_state_name(st.state)}, {"output", st.output}, {"reason", st.reason}});
    }
    result["bake"] = bakeJson;
    // ---- the report ----
    Json report = model_clean_report_json(rep);
    {
        std::vector<std::string> fixed;
        Json budget = Json::array();
        for (const ModelPlatformBudget& b : model_platform_budgets())
            budget.push_back(Json::object({{"platform", b.platform}, {"triangles", rep.trianglesAfter}, {"limit", b.triangles}, {"fits", rep.trianglesAfter <= b.triangles}, {"drawCalls", mesh.submeshes.size()}, {"drawCallLimit", b.submeshes},
                                           {"drawCallsFit", mesh.submeshes.size() <= b.submeshes}}));
        report["budget"] = budget;
        report["materials"] = materials.size();
        report["unwrapped"] = needUnwrap;
        if (needUnwrap && !bakedTriangles) report["unwrapNote"] = "The unwrap is applied when the document is baked.";
    }
    std::string summary = std::format("{} -> {} triangles", rep.trianglesBefore, rep.trianglesAfter);
    if (rep.removedPieceCount > 0) summary += std::format(", {} floating piece(s) removed", rep.removedPieceCount);
    if (rep.verticesWelded > 0) summary += std::format(", {} vertices welded", rep.verticesWelded);
    if (rep.scaleFactor != 1) summary += std::format(", scaled x{:.4g}", rep.scaleFactor);
    result["summary"] = summary;
    result["report"] = report;
    if (!reference.empty()) result["referenceHeight"] = Json::object({{"reference", reference}, {"what", referenceWhat}, {"metres", round_to(*o.height, 4)}});
    Json steps = Json::array();
    steps.push_back("model.info {\"path\":\"" + docRel + "\"} measures the baked model; model.edit adds modifiers or nodes next to the `mesh_1` node, model.uv and model.game_ready change the uv and game-ready settings.");
    if (platform != "desktop" || rep.trianglesAfter > 20000)
        steps.push_back("model.game_ready {\"path\":\"" + docRel + "\",\"lods\":[{\"ratio\":0.5},{\"ratio\":0.15}],\"collider\":{\"shape\":\"convex\"}} adds LODs and a collider and checks every platform's budget.");
    if (!rep.remeshed && (rep.statsAfter.boundaryEdges > 0 || rep.statsAfter.nonManifoldEdges > 0))
        steps.push_back("The surface still has open or non-manifold edges: model.import_clean again with remesh: true (overwrite: true) makes a closed manifold surface.");
    if (rep.removedPieceCount > 0 && rep.removedPieces.size() > 0)
        steps.push_back("If a removed piece was meant to stay (an eye, a button), lower `minPieceSize` (now " + std::format("{:g}", o.minPieceSize) + ") or pass removeFloating: false.");
    result["nextSteps"] = steps;
    return result;
}

}  // namespace

void register_model_import_clean_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "model.import_clean";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Clean a generated or imported mesh (.glb, .gltf, .obj) into a game-ready model document: weld, drop floating bits, recentre, scale to a reference, decimate to a platform budget, optionally remesh, unwrap, and bake.";
    info.description =
        "Takes the mesh `source` (project-relative; assets.generate_model and assets.import put meshes "
        "there) and does, in order: `upAxis` (z-up exports are turned to y-up), weld (vertices at the same "
        "place with the same uv, colour and a similar normal become one, so seams stay), degenerate and "
        "repeated triangles removed, floating pieces removed (separate pieces whose size is under "
        "`minPieceSize`, default 2%, of the biggest piece's; the biggest is always kept, and the report "
        "lists what went), a consistent winding (neighbouring triangles agree and closed pieces face "
        "outward), scale (`height` in metres, `reference` = \"human\" (1.8 m) or a project model whose "
        "height to match, or `scale` factor; without one the size is kept, with a warning when it is not a "
        "size a game uses), `origin` (keep, center, bottom or bottom_center, the ground centre: the "
        "default), an optional remesh (`remesh: true` ... Example: "
        "{\"source\":\"assets/models/robot.glb\",\"height\":1.8,\"platform\":\"mobile\"}"
        FA_COMMAND_DETAILS
        "... the surface is rebuilt from a thickened distance field, so holes, non-manifold edges and "
        "self-intersections of AI meshes become one closed manifold surface; `remeshCells` along the longest "
        "side or `remeshVoxel` metres; texture coordinates cannot survive it, so base colour textures are "
        "sampled into vertex colours and the surface is unwrapped again; thin sheets become thin solids), "
        "and decimation to `triangles` or the `platform` budget (desktop 100000, mobile 20000, web 40000; "
        "meshoptimizer, keeping uvs, colours and part seams). `unwrap`: auto (default; unwrap with model_uv "
        "when the mesh has no uvs or was remeshed), always, never. A .obj goes through assets.import's "
        "converter first (the .gltf is written next to it and reused when it exists). Materials and textures "
        "of the source stay (embedded textures are written as project files). The result is a model document "
        "`<name>_clean.model.json` (or `out`) with a `mesh` node reading the cleaned mesh "
        "`<name>_clean.mesh.glb`, baked to `<name>_clean.glb`: modifiers, selections, uv and gameReady apply "
        "to it like to any model. The report teaches what was done: triangles and vertices before and after, "
        "vertices welded, pieces found and removed (size, place), triangles reoriented, non-manifold and "
        "open edges before and after, scale factor and its reason, the origin shift, remesh and decimation "
        "details, the fit to every platform's budget, and warnings.";
    info.inputSchema = Json::object(
        {{"type", "object"}, {"required", Json::array({"source"})}, {"additionalProperties", false},
         {"properties",
          obj({{"source", str("The mesh to clean: a project-relative .glb, .gltf or .obj.")},
               {"out", str("The model document to write, under assets/, ending in .model.json. Default <source folder>/<name>_clean.model.json.")},
               {"overwrite", boolean("Replace the document, and a .glb that no model document baked.", false)},
               {"upAxis", choice("Which axis is up in the source: y (glTF, the engine) or z (Blender and CAD exports; turned to y).", {"y", "z"}, "y")},
               {"weldDistance", num("Vertices closer than this many metres are one (when uv, colour and normal agree). 0 = a millionth of the model's size.", 0, std::nullopt, 0)},
               {"removeFloating", boolean("Remove separate pieces smaller than `minPieceSize` of the biggest piece.", true)},
               {"minPieceSize", num("A piece whose size is under this fraction of the biggest piece's is floating and removed (0..1).", 0, 1, 0.02)},
               {"origin", choice("Where the model's origin goes: keep, center, bottom, bottom_center (the ground centre).", {"keep", "center", "bottom", "bottom_center"}, "bottom_center")},
               {"height", num("Scale so the model is this many metres tall (Y extent). Exclusive with reference and scale.", 0.0001, 100000)},
               {"reference", str("Scale to the height of this model: \"human\" (1.8 m) or a project .model.json, .glb or .gltf. Exclusive with height and scale.")},
               {"scale", num("Multiply the size by this factor (0.01 for centimetres). Exclusive with height and reference.", 0.000001, 1000000)},
               {"platform", choice("The budget to decimate to: desktop, mobile or web (model.game_ready lists them).", {"desktop", "mobile", "web"}, "desktop")},
               {"triangles", Json::object({{"type", "integer"}, {"minimum", 1}, {"description", "Decimate to at most this many triangles instead of the platform budget."}})},
               {"remesh", boolean("Rebuild the surface through a signed distance field: closed, manifold, no self-intersection; loses texture coordinates.", false)},
               {"remeshCells", Json::object({{"type", "integer"}, {"minimum", 16}, {"maximum", 400}, {"default", 128}, {"description", "Remesh: cells along the longest side."}})},
               {"remeshVoxel", num("Remesh: the cell size in metres instead of remeshCells (0 = use remeshCells).", 0, std::nullopt, 0)},
               {"unwrap", choice("Unwrap with xatlas into the document's uv section: auto (when the mesh has no uvs or was remeshed), always or never.", {"auto", "always", "never"}, "auto")},
               {"texelsPerUnit", num("Texels per metre of the unwrap (default the project's style guide, else 128).", 0)},
               {"bake", boolean("Bake the document to its .glb.", true)}})}});
    registry.add(info, [projectDir](const Json& args) { return model_import_clean_command(projectDir, args.is_null() ? Json::object() : args); });
}

}  // namespace fa::assets_detail
