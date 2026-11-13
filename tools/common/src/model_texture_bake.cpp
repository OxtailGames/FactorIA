// The project side of a model document's `texturing` section: layer pictures, the image document they are composed in, the material. See
// model_texture_bake.h and docs/MODELING.md, "Texturing".
#include "model_texture_bake.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <filesystem>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/scene/model_texture.h"
#include "fa/tooling/image_doc.h"
#include "util.h"

namespace fa::model_texture_detail {

namespace {

namespace stdfs = std::filesystem;
using assets_detail::fail;
using assets_detail::project_file;

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}

bool write_png_if_changed(const std::string& projectDir, const std::string& rel, const Image& image) {
    const std::vector<std::uint8_t> png = encode_png(image);
    const std::string_view bytes(reinterpret_cast<const char*>(png.data()), png.size());
    const stdfs::path file = assets_detail::project_write_file(projectDir, rel);
    if (auto old = tooling_detail::read_file(file); old && *old == bytes) return false;
    std::string err;
    if (!tooling_detail::write_file(file, bytes, &err))
        fail("failed", "Cannot write '" + rel + "': " + err, "Check that the folder is writable.");
    return true;
}

// The layers the bake owns, bottom first, with the picture each shows.
struct Reserved {
    const char* name;
    std::string file;
    const char* blend;
    bool visible;
    float opacity;
};

Json layer_json(const Reserved& r) {
    Json l = Json::object({{"kind", "pixels"}, {"name", r.name}, {"source", r.file}});
    if (std::string(r.blend) != "normal") l["blend"] = r.blend;
    if (!r.visible) l["visible"] = false;
    if (r.opacity != 1.0f) l["opacity"] = r.opacity;
    return l;
}

bool is_reserved_name(const std::string& name) {
    return name == kLayerBase || name == kLayerDecals || name == kLayerWear || name == kLayerOcclusion ||
           name == kLayerUv;
}

// A layer people made: has it anything drawn on it? (A blank paint layer, the one the first bake adds, has not.)
bool layer_has_content(const std::string& projectDir, const Json& layer) {
    const std::string kind = layer.is_object() ? layer.value("kind", std::string()) : std::string();
    if (kind == "pixels" || kind == "provider") {
        if (!layer.contains("source") || !layer["source"].is_string()) return false;
        auto img = load_image(project_file(projectDir, layer["source"].get<std::string>()).string());
        if (!img.ok()) return true;  // cannot tell: assume it matters
        for (std::size_t i = 3; i < img->rgba.size(); i += 4)
            if (img->rgba[i] != 0) return true;
        return false;
    }
    return true;
}

// The uv of every triangle corner, in triangle order: splitting vertices (vertexColors "flat") does not change it, moving a chart does.
std::string layout_fingerprint(const MeshData& mesh) {
    std::string bytes;
    bytes.reserve(mesh.indices.size() * 8);
    for (std::uint32_t index : mesh.indices) {
        for (std::size_t k = 0; k < 2; ++k) {
            const std::size_t at = std::size_t(index) * 2 + k;
            const std::int32_t q = at < mesh.uvs.size() ? std::int32_t(std::lround(mesh.uvs[at] * 4096.0f)) : 0;
            bytes.append(reinterpret_cast<const char*>(&q), sizeof q);
        }
    }
    return sha256_hex(bytes).substr(0, 16);
}

}  // namespace

std::string output_stem(const std::string& output) {
    return output.size() > 4 && to_lower(output.substr(output.size() - 4)) == ".glb"
               ? output.substr(0, output.size() - 4)
               : output;
}

std::string document_path(const ModelDoc& doc, const std::string& output) {
    if (doc.texturing && !doc.texturing->document.empty()) {
        auto norm = fs::normalize_checked(doc.texturing->document);
        return norm.ok() && !norm->empty() ? *norm : doc.texturing->document;
    }
    return output_stem(output) + ".texture" + kImageDocSuffix;
}

std::vector<std::string> layer_files(const ModelDoc& doc, const std::string& output) {
    std::vector<std::string> out;
    if (!doc.texturing) return out;
    const ModelTexturing& t = *doc.texturing;
    const std::string stem = output_stem(output);
    out.push_back(stem + ".base.png");
    if (!t.decals.empty()) out.push_back(stem + ".decals.png");
    if (!t.wear.empty()) out.push_back(stem + ".wear.png");
    if (t.aoStrength) out.push_back(stem + ".occlusion.png");
    out.push_back(stem + ".uv.png");
    for (const char* map : {"ao", "curvature", "thickness"})
        if (std::find(t.maps.write.begin(), t.maps.write.end(), map) != t.maps.write.end())
            out.push_back(stem + "." + map + ".png");
    return out;
}

Json report_json(const ModelTextureReport& r) {
    auto stats = [](const std::vector<ModelMapStats>& list) {
        Json a = Json::array();
        for (const ModelMapStats& m : list)
            a.push_back(Json::object({{"name", m.name},
                                      {"mean", round_to(m.mean, 4)},
                                      {"min", round_to(m.min, 4)},
                                      {"max", round_to(m.max, 4)},
                                      {"coverage", round_to(m.coverage, 4)}}));
        return a;
    };
    Json out = Json::object({{"size", r.size},
                             {"bleed", r.bleed},
                             {"texels", r.texels},
                             {"utilization", round_to(r.utilization, 4)},
                             {"overlap", round_to(r.overlap, 4)}});
    out["maps"] = stats(r.maps);
    out["wear"] = stats(r.wear);
    Json decals = Json::array();
    for (const auto& d : r.decals)
        decals.push_back(Json::object({{"name", d.name}, {"texels", d.texels}, {"triangles", d.triangles}}));
    out["decals"] = decals;
    Json parts = Json::array();
    for (const auto& p : r.parts) {
        Json one =
            Json::object({{"part", p.part}, {"material", p.material}, {"mapping", p.mapping}, {"texels", p.texels}});
        if (!p.texture.empty()) one["texture"] = p.texture;
        parts.push_back(one);
    }
    out["parts"] = parts;
    if (!r.warnings.empty()) out["warnings"] = r.warnings;
    return out;
}

void apply_texture(MeshData& mesh, const ModelDoc& doc, const std::string& png) {
    for (MeshSubmesh& sm : mesh.submeshes) {
        sm.material.texture = png;
        sm.material.color = Color{1, 1, 1, 1};
    }
    if (doc.texturing && doc.texturing->vertexColors == "bake") mesh.colors.clear();
}

Result<TextureBake> bake_model_texture(const std::string& projectDir, const ModelDoc& doc, const ModelBuild& build,
                                       const std::string& output, const std::string& previousLayout) {
    TextureBake out;
    const ModelTexturing& T = *doc.texturing;
    ModelTextureInput in;
    in.mesh = &build.data;
    in.settings = &T;
    for (const auto& [name, m] : doc.materialTexturing) in.mappings.emplace_back(name, m);
    in.images = [](const std::string& path) -> Result<Image> { return load_image(path); };
    if (build.uv) in.uvTextureSize = build.uv->textureSize;
    if (doc.uv) in.uvPadding = doc.uv->padding;
    auto baked = bake_model_textures(in);
    if (!baked.ok()) return baked.error();
    const ModelTextureLayers& L = *baked;
    out.size = L.size;
    out.report = L.report;
    out.layout = layout_fingerprint(build.data);
    out.warnings = L.report.warnings;
    out.inputs = L.inputs;

    // ---- the pictures
    const std::string stem = output_stem(output);
    const std::vector<std::string> wanted = layer_files(doc, output);
    auto file_of = [&](const char* tag) { return stem + "." + tag + ".png"; };
    struct Out {
        std::string file;
        const Image* image;
    };
    std::vector<Out> pictures = {{file_of("base"), &L.base}, {file_of("uv"), &L.uvWire}};
    if (L.hasDecals) pictures.push_back({file_of("decals"), &L.decals});
    if (L.hasWear) pictures.push_back({file_of("wear"), &L.wear});
    if (!L.occlusion.empty()) pictures.push_back({file_of("occlusion"), &L.occlusion});
    if (!L.ao.empty()) pictures.push_back({file_of("ao"), &L.ao});
    if (!L.curvature.empty()) pictures.push_back({file_of("curvature"), &L.curvature});
    if (!L.thickness.empty()) pictures.push_back({file_of("thickness"), &L.thickness});
    for (const Out& p : pictures) {
        write_png_if_changed(projectDir, p.file, *p.image);
        out.files.push_back(p.file);
    }
    // the files the document says it makes must be the ones made: a mismatch would leave the model "missing" for ever
    {
        std::set<std::string> a(wanted.begin(), wanted.end()), b(out.files.begin(), out.files.end());
        if (a != b)
            return make_error("Internal error: the texture bake wrote other pictures than the document asks for.",
                              "Report this as an engine bug.");
    }

    // ---- the image document
    const std::string docPath = document_path(doc, output);
    out.document = docPath;
    if (!starts_with(docPath, "assets/") || !ends_with(docPath, kImageDocSuffix))
        return make_error("texturing.document '" + docPath + "' must be under assets/ and end in " + kImageDocSuffix +
                              ".",
                          "Example: \"assets/models/door.texture.image.json\".");

    std::vector<Reserved> reserved;
    reserved.push_back({kLayerBase, file_of("base"), "normal", true, 1.0f});
    if (L.hasDecals) reserved.push_back({kLayerDecals, file_of("decals"), "normal", true, 1.0f});
    if (L.hasWear) reserved.push_back({kLayerWear, file_of("wear"), "normal", true, 1.0f});
    if (!L.occlusion.empty()) reserved.push_back({kLayerOcclusion, file_of("occlusion"), "multiply", true, 1.0f});
    reserved.push_back({kLayerUv, file_of("uv"), "normal", false, 1.0f});

    const stdfs::path docFile = project_file(projectDir, docPath);
    std::optional<std::string> existing = tooling_detail::read_file(docFile);
    Json json;
    bool changed = false;
    const std::string paintFile = stem + ".paint.png";
    if (!existing) {
        out.documentCreated = true;
        json = Json::object({{"format", kImageDocFormat}, {"width", L.size}, {"height", L.size}});
        json["description"] =
            "The texture of the model " + output +
            ". The layers named \"model: ...\" are the model's: every model bake rewrites their pictures. "
            "Paint on layers of your own above them; a bake never touches those.";
        Json layers = Json::array();
        for (const Reserved& r : reserved) layers.push_back(layer_json(r));
        // a blank layer to paint on
        Image blank;
        blank.width = blank.height = L.size;
        blank.rgba.assign(std::size_t(L.size) * std::size_t(L.size) * 4, 0);
        write_png_if_changed(projectDir, paintFile, blank);
        layers.push_back(Json::object({{"kind", "pixels"}, {"name", "paint"}, {"source", paintFile}}));
        json["layers"] = layers;
        changed = true;
    } else {
        auto parsed = parse_json(*existing, docPath);
        if (!parsed.ok())
            return make_error(docPath + ": " + parsed.error().message,
                              "Fix the JSON, or delete the file: the next model bake writes a new texture document "
                              "(painted layers are lost with it).");
        json = std::move(*parsed);
        if (!json.is_object() || !json.contains("layers") || !json["layers"].is_array())
            return make_error(docPath + ": the texture document is not an image document with a `layers` list.",
                              "Delete the file: the next model bake writes a new one.");
        const Json before = json;
        const bool layoutMoved = !previousLayout.empty() && previousLayout != out.layout;
        const int oldW = json.value("width", 0), oldH = json.value("height", 0);
        Json layers = json["layers"];
        // the layers people painted (anything that is not the model's)
        bool painted = false;
        if (layoutMoved || oldW != L.size || oldH != L.size)
            for (const Json& l : layers)
                if (l.is_object() && !is_reserved_name(l.value("name", std::string())) &&
                    layer_has_content(projectDir, l))
                    painted = true;
        if (oldW != L.size || oldH != L.size) {
            json["width"] = L.size;
            json["height"] = L.size;
            if (painted)
                out.warnings.push_back(std::format(
                    "The texture is {0}x{0} now (it was {1}x{2}): the layers you painted keep their pixels, which no "
                    "longer cover the same spots. Paint them again, or change texturing.size / uv.textureSize back.",
                    L.size, oldW, oldH));
        } else if (layoutMoved && painted) {
            out.warnings.push_back("The uv layout changed since the last bake: the layers you painted in '" + docPath +
                                   "' keep their pixels, which no longer line up with the model. "
                                   "Paint them again; keep a uv change for before you start painting.");
        }
        // remove the model's layers that this bake does not make, keep the others where they are
        Json kept = Json::array();
        for (const Json& l : layers) {
            const std::string name = l.is_object() ? l.value("name", std::string()) : std::string();
            if (is_reserved_name(name)) {
                bool still = false;
                for (const Reserved& r : reserved) still = still || name == r.name;
                if (!still) continue;
            }
            kept.push_back(l);
        }
        layers = kept;
        // point the model's layers at this bake's pictures (their other settings, such as opacity, are the user's), and add the missing ones
        std::vector<std::string> canon;
        for (const Reserved& r : reserved) canon.push_back(r.name);
        auto find_layer = [&](const std::string& name) -> int {
            for (std::size_t i = 0; i < layers.size(); ++i)
                if (layers[i].is_object() && layers[i].value("name", std::string()) == name) return int(i);
            return -1;
        };
        for (std::size_t k = 0; k < reserved.size(); ++k) {
            const Reserved& r = reserved[k];
            const int at = find_layer(r.name);
            if (at >= 0) {
                layers[std::size_t(at)]["source"] = r.file;
                continue;
            }
            // after the nearest model layer below it in the canonical order, else at the bottom
            int pos = 0;
            for (std::size_t j = k; j-- > 0;) {
                const int p = find_layer(reserved[j].name);
                if (p >= 0) {
                    pos = p + 1;
                    break;
                }
            }
            Json copy = Json::array();
            for (int i = 0; i < pos; ++i) copy.push_back(layers[std::size_t(i)]);
            copy.push_back(layer_json(r));
            for (std::size_t i = std::size_t(pos); i < layers.size(); ++i) copy.push_back(layers[i]);
            layers = copy;
        }
        json["layers"] = layers;
        changed = json != before;
    }

    // saving checks the document and bakes it; an unchanged one is only baked when its picture is not current
    std::string pngPath;
    {
        if (changed) {
            auto saved = save_image_document(projectDir, docPath, json, true);
            if (!saved.ok()) return make_error(docPath + ": " + saved.error().message, saved.error().hint);
            pngPath = saved->output;
        } else {
            auto loaded = load_image_document(projectDir, docPath);
            if (!loaded.ok()) return make_error(loaded.error().message, loaded.error().hint);
            pngPath = image_document_output(*loaded, docPath);
            auto b = bake_image_document(projectDir, docPath, {true});
            if (!b.ok()) return make_error(docPath + ": " + b.error().message, b.error().hint);
        }
    }
    out.png = pngPath;
    out.inputs.push_back(docPath);
    std::sort(out.inputs.begin(), out.inputs.end());
    out.inputs.erase(std::unique(out.inputs.begin(), out.inputs.end()), out.inputs.end());
    return out;
}

}  // namespace fa::model_texture_detail
