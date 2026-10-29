// assets.import: brings a file made elsewhere into assets/ and records its provenance in assets.json.
// The importers of the formats that need converting live in assets_aseprite.cpp, assets_obj.cpp and assets_fbx.cpp; the
// formats the engine reads as they are (and PSD, which only needs decoding) are handled here.
#include <algorithm>
#include <cctype>
#include <format>
#include <map>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/asset_import.h"
#include "fa/tooling/project_fs.h"
#include "util.h"

namespace fa {

using namespace assets_detail;
using tooling_detail::arg_bool;
using tooling_detail::arg_string;

namespace assets_detail {

[[noreturn]] void fail(const char* code, const std::string& message, const std::string& hint) {
    throw CommandError(code, message, hint);
}

stdfs::path project_file(const std::string& projectDir, const std::string& rel) {
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) fail("invalid_argument", path.error().message, path.error().hint);
    return *path;
}

void require_usable_manifest(const std::string& projectDir) {
    const auto text = tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile);
    if (!text) return;
    auto parsed = parse_json(*text, assets::kManifestFile);
    if (!parsed.ok() || !parsed->is_object())
        fail("failed", std::string(assets::kManifestFile) + " is not valid, so it cannot record this asset: " +
                           (parsed.ok() ? "it must be a JSON object." : parsed.error().message),
             "Run project.validate and fix the file (schemas/assets.schema.json), then try again.");
}

std::string safe_file_name(const std::string& name, const char* fallback) {
    std::string out = name;
    for (char& c : out)
        if (!std::isalnum(static_cast<unsigned char>(c)) && c != '.' && c != '-' && c != '_') c = '_';
    return out.empty() ? fallback : out;
}

Result<std::vector<std::uint8_t>> read_bytes(const stdfs::path& path) {
    auto text = tooling_detail::read_file(path);
    if (!text) return make_error("cannot read '" + path.string() + "'");
    return std::vector<std::uint8_t>(text->begin(), text->end());
}

Result<Image> load_image(const stdfs::path& file) {
    auto bytes = read_bytes(file);
    if (!bytes.ok()) return bytes.error();
    return decode_image(bytes->data(), bytes->size());
}

}  // namespace assets_detail

namespace {

constexpr std::uintmax_t kMaxSourceBytes = std::uintmax_t(512) << 20;

struct Route {
    const char* importer;  // named in the result
    const char* outExt;    // the extension of the file that lands in the project
    Result<ImportOutput> (*run)(const ImportRequest& request);
};

std::string default_folder(const std::string& outExt) {
    switch (assets::kind_of("x" + outExt)) {
        case assets::AssetKind::Model: return "assets/models/";
        case assets::AssetKind::Audio: return "assets/audio/";
        case assets::AssetKind::Font: return "assets/fonts/";
        case assets::AssetKind::Video: return "assets/video/";
        default: return "assets/";
    }
}

// The project-relative path the asset lands at.
std::string plan_destination(const std::string& arg, const stdfs::path& source, const Route& route) {
    const std::string srcExt = to_lower(source.extension().string());
    const std::string name = safe_file_name(source.stem().string(), "asset") + route.outExt;
    std::string dest = default_folder(route.outExt) + name;
    if (!arg.empty()) {
        auto norm = fs::normalize_checked(arg);
        if (!norm.ok() || norm->empty()) fail("invalid_argument", "Invalid path '" + arg + "'.", "Use a project-relative path such as \"assets/hero.png\".");
        dest = ends_with(arg, "/") || ends_with(arg, "\\") ? *norm + "/" + name : *norm;
    }
    if (!starts_with(dest, "assets/"))
        fail("invalid_argument", "Imported files go under assets/, and '" + dest + "' is not there.",
             "Use a path such as \"" + default_folder(route.outExt) + name + "\".");
    if (to_lower(fs::extension(dest)) != route.outExt)
        fail("invalid_argument",
             std::format("A {} file is imported as '{}', so `path` must end in '{}' (got '{}').", srcExt, route.outExt, route.outExt, dest),
             "Change the extension, or leave `path` out for assets/" + name + ".");
    return dest;
}

stdfs::path resolve_source(const std::string& projectDir, const std::string& arg) {
    if (arg.find("://") != std::string::npos)
        fail("invalid_argument", "assets.import reads files on this machine, and '" + arg + "' is a URL.",
             "Download the file first, then import its local path. Pass the page it came from as `sourceUrl` so the credits keep it.");
    stdfs::path path = stdfs::path(arg).is_absolute() ? stdfs::path(arg) : project_file(projectDir, arg);
    std::error_code ec;
    if (!stdfs::is_regular_file(path, ec))
        fail("not_found", "The file '" + arg + "' does not exist" + (stdfs::is_directory(path, ec) ? " (it is a folder)." : "."),
             "Pass the absolute path of the file, or a path relative to the project folder.");
    if (stdfs::file_size(path, ec) > kMaxSourceBytes) fail("too_large", "'" + arg + "' is larger than 512 MB.", "Reduce it before importing.");
    return path;
}

// ---- the formats that are copied -----------------------------------------------------------------------------

Result<ImportOutput> import_copy(const ImportRequest& request) {
    auto bytes = read_bytes(request.source);
    if (!bytes.ok()) return bytes.error();
    ImportOutput out;
    out.details = Json::object();
    if (assets::kind_of(request.dest) == assets::AssetKind::Texture) {
        auto image = decode_image(bytes->data(), bytes->size());
        if (!image.ok())
            return make_error("'" + request.source.filename().string() + "' is not an image the engine can read: " + image.error().message,
                              "Open it in an image editor and save it again as PNG.");
        out.details = Json::object({{"width", image->width}, {"height", image->height}});
    }
    out.files.push_back({request.dest, std::move(*bytes)});
    return out;
}

std::string uri_decode(const std::string& uri) {
    std::string out;
    for (std::size_t i = 0; i < uri.size(); ++i) {
        if (uri[i] == '%' && i + 2 < uri.size() && std::isxdigit(static_cast<unsigned char>(uri[i + 1])) &&
            std::isxdigit(static_cast<unsigned char>(uri[i + 2]))) {
            out += char(std::stoi(uri.substr(i + 1, 2), nullptr, 16));
            i += 2;
        } else {
            out += uri[i];
        }
    }
    return out;
}

// The JSON chunk of a binary glTF (.glb), or an error that says what is wrong with the file.
Result<std::string> glb_json(const std::vector<std::uint8_t>& b, const std::string& file) {
    auto u32 = [&](std::size_t at) { return std::uint32_t(b[at]) | (std::uint32_t(b[at + 1]) << 8) | (std::uint32_t(b[at + 2]) << 16) | (std::uint32_t(b[at + 3]) << 24); };
    if (b.size() < 20 || std::string_view(reinterpret_cast<const char*>(b.data()), 4) != "glTF")
        return make_error("'" + file + "' is not a binary glTF (.glb) file.", "Export the model as glTF Binary (.glb) or glTF Separate (.gltf).");
    if (u32(16) != 0x4E4F534Au || 20 + std::size_t(u32(12)) > b.size())
        return make_error("'" + file + "' has no readable JSON chunk.", "Export the model again as glTF 2.0.");
    return std::string(reinterpret_cast<const char*>(b.data()) + 20, u32(12));
}

// A .gltf (or .glb) with the .bin buffers and images it refers to, which sit next to it (or in subfolders) and are copied along.
Result<ImportOutput> import_gltf_text(const ImportRequest& request, std::vector<std::uint8_t> bytes, const std::string& jsonText) {
    const std::string file = request.source.filename().string();
    auto doc = parse_json(jsonText, file);
    if (!doc.ok()) return make_error("'" + file + "' is not valid JSON: " + doc.error().message, "A .gltf is a JSON file; for a binary model use a .glb.");
    if (!doc->is_object() || !doc->contains("asset"))
        return make_error("'" + file + "' is not a glTF file (it has no \"asset\" section).", "Export the model as glTF 2.0 (.gltf or .glb) from your 3D tool.");
    ImportOutput out;
    out.files.push_back({request.dest, std::move(bytes)});
    const stdfs::path from = request.source.parent_path();
    const std::string toDir = fs::parent(request.dest);
    std::set<std::string> seen;
    int buffers = 0, images = 0;
    for (const char* key : {"buffers", "images"}) {
        if (!doc->contains(key) || !(*doc)[key].is_array()) continue;
        for (const Json& item : (*doc)[key]) {
            if (!item.is_object() || !item.contains("uri") || !item["uri"].is_string()) continue;
            const std::string raw = item["uri"].get<std::string>();
            if (starts_with(raw, "data:")) continue;
            const std::string uri = uri_decode(raw);
            const bool buffer = std::string(key) == "buffers";
            if (uri.find("://") != std::string::npos || fs::normalize(uri).empty() || stdfs::path(uri).is_absolute() || starts_with(uri, "/"))
                return make_error("'" + file + "' refers to '" + raw + "', which is not a file next to the model.",
                                  "Put the file in the folder of the .gltf (or a subfolder) and make the uri relative, e.g. \"textures/wood.png\".");
            const std::string norm = fs::normalize(uri);
            std::error_code ec;
            if (!stdfs::is_regular_file(from / norm, ec)) {
                if (buffer) return make_error("'" + file + "' needs the buffer '" + raw + "', which is not next to it.", "Copy the .bin file next to the .gltf and import again.");
                out.warnings.push_back("The texture '" + raw + "' is not next to the model, so it was not imported: the model will show the missing-texture checker.");
                continue;
            }
            if (!seen.insert(norm).second) continue;
            auto side = read_bytes(from / norm);
            if (!side.ok()) return side.error();
            out.files.push_back({toDir + "/" + norm, std::move(*side)});
            ++(buffer ? buffers : images);
        }
    }
    out.details = Json::object({{"buffers", buffers}, {"images", images}});
    return out;
}

Result<ImportOutput> import_gltf(const ImportRequest& request) {
    auto bytes = read_bytes(request.source);
    if (!bytes.ok()) return bytes.error();
    std::string text(reinterpret_cast<const char*>(bytes->data()), bytes->size());
    return import_gltf_text(request, std::move(*bytes), text);
}

Result<ImportOutput> import_glb(const ImportRequest& request) {
    auto bytes = read_bytes(request.source);
    if (!bytes.ok()) return bytes.error();
    auto json = glb_json(*bytes, request.source.filename().string());
    if (!json.ok()) return json.error();
    return import_gltf_text(request, std::move(*bytes), *json);
}

Result<ImportOutput> import_psd(const ImportRequest& request) {
    auto bytes = read_bytes(request.source);
    if (!bytes.ok()) return bytes.error();
    const std::string file = request.source.filename().string();
    if (bytes->size() < 4 || std::string_view(reinterpret_cast<const char*>(bytes->data()), 4) != "8BPS")
        return make_error("'" + file + "' is not a Photoshop (.psd) file.", "Large documents (.psb) are not supported: flatten and save a PNG.");
    auto image = decode_image(bytes->data(), bytes->size());
    if (!image.ok())
        return make_error("Cannot read the merged image of '" + file + "': " + image.error().message,
                          "Only 8 and 16 bit RGB PSDs are read, from their saved merged image. In Photoshop turn on "
                          "Edit > Preferences > File Handling > Maximize PSD and PSB File Compatibility and save again, convert the "
                          "mode to RGB, or export a PNG (File > Export > Quick Export as PNG).");
    ImportOutput out;
    out.files.push_back({request.dest, encode_png(*image)});
    out.details = Json::object({{"width", image->width}, {"height", image->height}, {"layersFlattened", true}});
    out.warnings.push_back("Layers were flattened: the PNG is the merged image of the PSD. To use layers separately, export each one "
                           "from Photoshop (File > Export > Layers to Files) and import those.");
    return out;
}

// Validate: every file (texture or buffer) a glTF/glb under assets/ refers to must exist next to it.
void check_model_files_impl(const std::string& projectDir, std::vector<ValidationIssue>& errors) {
    const stdfs::path root = stdfs::path(projectDir);
    std::error_code ec;
    if (!stdfs::is_directory(root / "assets", ec)) return;
    std::vector<stdfs::path> models;
    for (stdfs::recursive_directory_iterator it(root / "assets", stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string ext = to_lower(it->path().extension().string());
        if ((ext == ".gltf" || ext == ".glb") && it->is_regular_file(ec)) models.push_back(it->path());
    }
    std::sort(models.begin(), models.end());
    for (const stdfs::path& model : models) {
        const std::string rel = stdfs::relative(model, root, ec).generic_string();
        auto bytes = read_bytes(model);
        if (!bytes.ok()) continue;
        std::string text(reinterpret_cast<const char*>(bytes->data()), bytes->size());
        if (to_lower(model.extension().string()) == ".glb") {
            auto chunk = glb_json(*bytes, rel);
            if (!chunk.ok()) continue;
            text = std::move(*chunk);
        }
        auto doc = parse_json(text, rel);
        if (!doc.ok() || !doc->is_object()) continue;
        for (const char* key : {"images", "buffers"}) {
            if (!doc->contains(key) || !(*doc)[key].is_array()) continue;
            int index = 0;
            for (const Json& item : (*doc)[key]) {
                const int i = index++;
                if (!item.is_object() || !item.contains("uri") || !item["uri"].is_string()) continue;
                const std::string raw = item["uri"].get<std::string>();
                if (starts_with(raw, "data:") || raw.find("://") != std::string::npos) continue;
                const std::string norm = fs::normalize(uri_decode(raw));
                const bool image = std::string(key) == "images";
                if (!norm.empty() && stdfs::is_regular_file(model.parent_path() / norm, ec)) continue;
                const std::string where = fs::parent(rel);
                errors.push_back({rel, std::string("/") + key + "/" + std::to_string(i) + "/uri",
                                  std::string("This model refers to the ") + (image ? "texture" : "buffer") + " '" + raw + "', and '" +
                                      (where.empty() ? norm : where + "/" + norm) + "' does not exist: it draws untextured or fails to load.",
                                  "Copy the file there (assets.import of the model copies the files its uris point at), or edit the uri in the model."});
            }
        }
    }
}

const std::map<std::string, Route>& routes() {
    static const std::map<std::string, Route> r = {
        {".aseprite", {"aseprite", ".png", import_aseprite}}, {".ase", {"aseprite", ".png", import_aseprite}},
        {".psd", {"psd", ".png", import_psd}},                {".obj", {"obj", ".gltf", import_obj}},
        {".fbx", {"fbx", ".glb", import_fbx}},                {".gltf", {"gltf", ".gltf", import_gltf}},
        {".glb", {"glb", ".glb", import_glb}},              {".png", {"copy", ".png", import_copy}},
        {".jpg", {"copy", ".jpg", import_copy}},              {".jpeg", {"copy", ".jpeg", import_copy}},
        {".tga", {"copy", ".tga", import_copy}},              {".bmp", {"copy", ".bmp", import_copy}},
        {".wav", {"copy", ".wav", import_copy}},              {".ogg", {"copy", ".ogg", import_copy}},
        {".mp3", {"copy", ".mp3", import_copy}},              {".ttf", {"copy", ".ttf", import_copy}},
        {".otf", {"copy", ".otf", import_copy}},              {".qoa", {"copy", ".qoa", import_copy}},
        {".mpg", {"video", ".mpg", import_video}},            {".mpeg", {"video", ".mpeg", import_video}},
        {".mp4", {"video", ".mpg", import_video}},            {".m4v", {"video", ".mpg", import_video}},
        {".mov", {"video", ".mpg", import_video}},            {".webm", {"video", ".mpg", import_video}},
        {".mkv", {"video", ".mpg", import_video}},            {".avi", {"video", ".mpg", import_video}}};
    return r;
}

std::string supported_extensions() {
    std::vector<std::string> list;
    for (const auto& [ext, route] : routes()) list.push_back(ext);
    return join(list, ", ");
}

// ---- the command ----------------------------------------------------------------------------------------------

std::vector<std::string> default_next_steps(const std::string& path) {
    switch (assets::kind_of(path)) {
        case assets::AssetKind::Texture:
            return {"Draw it: a Sprite with \"texture\": \"" + path + "\" (or a MeshRenderer \"texture\", a Tilemap \"tileset\"). A sheet of several frames needs assets.slice_sheet first."};
        case assets::AssetKind::Model: return {"Show it: a MeshRenderer with \"mesh\": \"" + path + "\"."};
        case assets::AssetKind::Audio: return {"Play it: audio.play(\"" + path + "\") in a script, an AudioSource \"clip\", or SceneSettings \"music\"."};
        case assets::AssetKind::Font: return {"Use it: a Text with \"font\": \"" + path + "\"."};
        case assets::AssetKind::Video: return {"Show it: a Video component with \"path\": \"" + path + "\" and a \"size\"; entity.video.play() / seek() / on(\"ended\") in a script."};
        default: return {};
    }
}

Json import_asset(const std::string& projectDir, const Json& a) {
    const std::string sourceArg = arg_string(a, "source", true);
    const stdfs::path source = resolve_source(projectDir, sourceArg);
    const std::string ext = to_lower(source.extension().string());
    const auto route = routes().find(ext);
    if (route == routes().end()) {
        std::string hint = "Supported: " + supported_extensions() + ".";
        if (ext == ".blend") hint = "Export the model from Blender as glTF (File > Export > glTF 2.0) and import that. " + hint;
        else if (ext == ".svg") hint = "Rasterize it with assets.rasterize_svg {\"source\": <the .svg in the project>, \"path\": \"assets/<name>.png\"} (copy the file into the project first). " + hint;
        else if (ext == ".webp" || ext == ".gif" || ext == ".psb") hint = "Convert it to PNG first. " + hint;
        else if (ext == ".gif" || ext == ".flv" || ext == ".wmv") hint = "Convert it to .mp4 with ffmpeg first (factoria setup ffmpeg). " + hint;
        else if (ext == ".flac" || ext == ".m4a" || ext == ".aac") hint = "Convert it to OGG or WAV first. " + hint;
        fail("invalid_argument", "assets.import cannot read '" + ext + "' files.", hint);
    }
    ImportRequest request;
    request.source = source;
    request.dest = plan_destination(arg_string(a, "path", false), source, route->second);
    request.columns = int(tooling_detail::arg_int(a, "columns", 0));
    const bool overwrite = arg_bool(a, "overwrite", false);
    auto exists = [&](const std::string& rel) { std::error_code ec; return stdfs::exists(project_file(projectDir, rel), ec); };
    if (!overwrite && exists(request.dest))
        fail("exists", "'" + request.dest + "' already exists.", "Pass overwrite: true to replace it, or choose another `path`.");
    require_usable_manifest(projectDir);

    Result<ImportOutput> done = route->second.run(request);
    if (!done.ok()) fail("failed", done.error().message, done.error().hint);
    ImportOutput& out = *done;

    // The asset itself must not overwrite a file silently. Its textures often share a name with another model's (every
    // Kenney kit has Textures/colormap.png): an identical file is shared, a different one is kept and warned about, so the
    // models already in the project keep their textures. A different buffer (.bin) is a clash: the model cannot load
    // another model's geometry.
    std::vector<std::string> clashes;
    auto same_bytes = [&](const std::string& rel, const std::vector<std::uint8_t>& bytes) {
        auto old = read_bytes(project_file(projectDir, rel));
        return old.ok() && *old == bytes;
    };
    std::vector<OutFile> toWrite;
    for (std::size_t i = 0; i < out.files.size(); ++i) {
        OutFile& f = out.files[i];
        if (!overwrite && exists(f.path)) {
            if (i == 0) {
                clashes.push_back(f.path);
            } else if (same_bytes(f.path, f.bytes)) {
            } else if (to_lower(fs::extension(f.path)) == ".bin") {
                clashes.push_back(f.path);
            } else {
                out.warnings.push_back("'" + f.path + "' already exists and is a DIFFERENT file (another model's?), so it was kept and the "
                                       "model will draw with that one. Import this model into its own folder (`path`, e.g. "
                                       "\"" + fs::parent(f.path) + "/<pack>/\") or pass overwrite: true to replace it.");
            }
            continue;
        }
        toWrite.push_back(std::move(f));
    }
    if (!clashes.empty())
        fail("exists", "These files already exist: " + join(clashes, ", ") + ".", "Pass overwrite: true to replace them, or choose another `path` (the files next to a model follow its folder).");
    out.files = std::move(toWrite);

    Json provenance = Json::object({{"origin", "imported"}, {"date", assets::today()}});
    provenance["source"] = arg_string(a, "sourceUrl", false, replace_all(sourceArg, "\\", "/"));
    for (const char* key : {"license", "author"})
        if (const std::string v = arg_string(a, key, false); !v.empty()) provenance[key] = v;
    if (a.contains("ai") && a["ai"].is_boolean()) provenance["ai"] = a["ai"].get<bool>();

    Json written = Json::array();
    for (const OutFile& f : out.files) {
        std::string err;
        if (!tooling_detail::write_file(project_file(projectDir, f.path), std::string_view(reinterpret_cast<const char*>(f.bytes.data()), f.bytes.size()), &err))
            fail("failed", err);
        written.push_back(Json::object({{"path", f.path}, {"bytes", f.bytes.size()}, {"kind", assets::kind_name(assets::kind_of(f.path))}}));
    }
    {
        ProjectRootGuard root(projectDir);
        for (std::size_t i = 0; i < out.files.size(); ++i) {
            auto r = assets::update_entry(out.files[i].path, [&](Json& e) {
                e["provenance"] = provenance;
                if (i == 0 && !out.sheet.is_null()) e["sheet"] = out.sheet;
            });
            if (!r.ok()) fail("failed", "The files were written, but assets.json was not updated: " + r.error().message, r.error().hint);
        }
    }

    Json result = Json::object({{"importer", route->second.importer}, {"path", request.dest}, {"written", written}, {"provenance", provenance}});
    if (!out.sheet.is_null()) result["sheet"] = out.sheet;
    if (out.details.is_object() && !out.details.empty()) result["details"] = out.details;
    if (!out.warnings.empty()) result["warnings"] = out.warnings;
    std::vector<std::string> steps = out.nextSteps.empty() ? default_next_steps(request.dest) : out.nextSteps;
    steps.push_back(a.contains("license") ? "Credits: the license and author are in assets.json (provenance)." :
                    "Record the license: pass `license` (and `author`) when you import a file you did not make, e.g. \"CC0\" or \"CC-BY 4.0\"; "
                    "the credits and store disclosures read assets.json.");
    result["nextSteps"] = steps;
    return result;
}

}  // namespace

namespace assets_detail {
void check_model_files(const std::string& projectDir, std::vector<ValidationIssue>& errors) { check_model_files_impl(projectDir, errors); }
}  // namespace assets_detail

void register_asset_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "assets.import";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Bring a file made elsewhere (Aseprite, PSD, OBJ, FBX, PNG, WAV, glTF, MP4...) into the project's assets/ folder and record where it came from.";
    info.description =
        "Copies or converts `source` (an absolute path on this machine, or relative to the project) into assets/ and writes its provenance "
        "(origin imported, source, license, author, ai, date) in assets.json, so credits and store disclosures can be made later. "
        "The importer is chosen by the extension:\n"
        "- .png .jpg .tga .bmp, .wav .ogg .mp3 .qoa, .ttf .otf: copied as they are (images are checked to decode).\n"
        "- .gltf and .glb: copied with the .bin buffers and images their uris point at, which must sit next to the model or below it "
        "(a missing buffer is an error, a missing image a warning). An identical file already there is shared; a DIFFERENT image with "
        "the same name is kept and the result warns (kits ship different Textures/colormap.png files: import each kit into its own "
        "folder with `path`, or pass overwrite), and a DIFFERENT buffer is an `exists` error. project.validate reports a model whose "
        "texture or buffer is missing.\n"
        "- .aseprite .ase: becomes ONE PNG sprite sheet (frames in a grid, `columns` per row, default ceil(sqrt(frames))) and the "
        "`sheet` entry of assets.json: columns, rows, frameWidth, frameHeight, frames and a clip per tag (firstFrame, lastFrame, fps from "
        "the frame durations). Hidden layers are left out, layer and cel opacity apply, RGBA, grayscale and indexed colors work. "
        "Blend modes other than normal are drawn as normal, and ping-pong or reverse tags become forward clips (set SpriteAnimator.mode to play them that way); the result says so. "
        "The result lists the Sprite and SpriteAnimator settings that play it.\n"
        "- .psd: the merged image becomes a PNG (layers are flattened).\n"
        "- .obj (with its .mtl and textures): becomes a .gltf with an embedded buffer and the textures next to it; polygons are "
        "triangulated, objects/groups/materials become separate meshes, missing normals give flat shading, and the result has the "
        "bounds so you can scale it.\n"
        "- .fbx: converted to .glb by FBX2glTF ($FACTORIA_FBX2GLTF or PATH) or by Blender (PATH or its install folder). With neither "
        "installed the error says where to get them.\n"
        "- .mp4 .mov .webm .mkv .avi .m4v: converted to an MPEG-1 video with MP2 audio in an .mpg (the only video the engine plays, "
        "the same on every platform) by ffmpeg, at most 1280 px wide, quality 4, 30 fps when the frame rate is not one MPEG-1 has. "
        "ffmpeg is found through $FACTORIA_FFMPEG, PATH or the copy `factoria setup ffmpeg` installs; without it the error names that "
        "command. A source with no audio track gives a silent video (the result warns). The result has width, height, fps and "
        "duration and the Video component that plays it. An .mpg or .mpeg is checked to be MPEG-1 and copied.\n"
        "Files land in assets/ (models in assets/models/, sounds in assets/audio/, fonts in assets/fonts/, videos in assets/video/ by default) or at `path`, "
        "which must be under assets/. An existing file is an error unless overwrite is true. "
        "Example: {\"source\":\"C:/art/hero.aseprite\",\"license\":\"CC0\",\"author\":\"Ana\"}.";
    info.inputSchema = Json::parse(R"({
      "type":"object","required":["source"],
      "properties":{
        "source":{"type":"string","description":"The file to import: an absolute path on this machine, or a path relative to the project folder. Not a URL: download it first."},
        "path":{"type":"string","description":"Where it lands, under assets/ (a path ending in / is a folder). Default: assets/<name>.<ext>, or assets/models/, assets/audio/, assets/fonts/ or assets/video/ for those kinds. The extension is the importer's output (.png for Aseprite and PSD, .gltf for OBJ, .glb for FBX, .mpg for a video)."},
        "license":{"type":"string","description":"License or terms of the file, e.g. \"CC0\", \"CC-BY 4.0\", \"bought from itch.io, single project\". Recorded in assets.json."},
        "author":{"type":"string","description":"Who made it. Recorded in assets.json for the credits."},
        "sourceUrl":{"type":"string","description":"Where the file came from (a page URL). Recorded as the provenance source instead of the local path."},
        "ai":{"type":"boolean","description":"Set true when AI made the content elsewhere (Steam's AI disclosure reads it). Leave out when unknown."},
        "columns":{"type":"integer","minimum":1,"description":"Aseprite only: frames per row of the sheet (default ceil(sqrt(frames)))."},
        "overwrite":{"type":"boolean","default":false,"description":"Replace files that already exist."}
      }})");
    registry.add(info, [projectDir](const Json& args) { return import_asset(projectDir, args); });
    register_slice_sheet_command(registry, projectDir);
    register_pack_atlas_command(registry, projectDir);
    register_draw_icon_command(registry, projectDir);
    register_draw_capsules_command(registry, projectDir);
    register_synth_sound_command(registry, projectDir);
    register_texture_command(registry, projectDir);
    register_svg_command(registry, projectDir);
    register_animate_svg_command(registry, projectDir);
    register_preview_sheet_command(registry, projectDir);
    register_bake_sheet_command(registry, projectDir);
    register_audio_commands(registry, projectDir);
    register_subset_font_command(registry, projectDir);
}

}  // namespace fa
