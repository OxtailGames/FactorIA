// assets.contact_sheet: a set of pictures side by side at the size the player sees them, over the backgrounds of the game (a
// light one, a dark one and the clear colour of the main camera) and once more in greyscale, each with its file name. It is
// what an artist does before calling a set of sprites finished: squint at them on the real ground, small, in black and white.
// PNGs (and the other formats the engine reads) are drawn as they are; a sprite sheet shows its first frame, or all of them;
// a .glb model is drawn as a small thumbnail by the engine's own renderer (a studio light, turned three quarters), which needs
// a GPU like assets.preview_in_scene. Everything else is drawn on the CPU, so the same files give the same picture.
#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "assets_shots.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/image_tools.h"
#include "fa/core/strings.h"
#include "fa/platform/app.h"
#include "fa/runtime/engine.h"
#include "fa/scene/mesh_geometry.h"
#include "headless_run.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kCommand = "assets.contact_sheet";
constexpr int kMaxPaths = 48;
constexpr int kMaxSize = 512;      // longest side of a cell, pixels
constexpr int kMaxPicture = 2048;  // longest side of the picture returned to a model
constexpr int kModelRender = 256;  // the thumbnail of a model is drawn this big, then scaled
constexpr int kModelNative = 128;  // and shown this big when no size is asked
constexpr float kFont = 13.0f;
constexpr int kPad = 8;

[[noreturn]] void bad(const std::string& pointer, const std::string& what, const std::string& hint) {
    arg_error(kCommand, pointer, what, hint);
}

struct Background {
    std::string name;
    Rgb8 colour;
};

struct Item {
    std::string label;         // file name (with the frame)
    std::vector<Image> sizes;  // one picture per size asked (or one at native size)
    std::string info;          // "64x64"
};

Rgb8 rgb8(const Color& c) {
    auto byte = [](float v) { return std::uint8_t(std::lround(std::clamp(v, 0.0f, 1.0f) * 255)); };
    return {byte(c.r), byte(c.g), byte(c.b)};
}

std::string base_name(const std::string& rel) {
    const auto slash = rel.find_last_of('/');
    return slash == std::string::npos ? rel : rel.substr(slash + 1);
}

// The clear colour of the first primary camera of the project's main scene, when it has one.
std::optional<Color> main_camera_clear(const std::string& projectDir) {
    auto project = load_json_file((stdfs::path(projectDir) / "factoria.json").generic_string());
    std::string sceneRel = "scenes/main.scene.json";
    if (project.ok() && project->is_object() && project->contains("mainScene") && (*project)["mainScene"].is_string())
        sceneRel = (*project)["mainScene"].get<std::string>();
    auto scene = load_json_file((stdfs::path(projectDir) / sceneRel).generic_string());
    if (!scene.ok() || !scene->is_object() || !scene->contains("entities")) return std::nullopt;
    std::optional<Color> found;
    std::function<void(const Json&)> walk = [&](const Json& list) {
        if (!list.is_array() || found) return;
        for (const Json& e : list) {
            if (!e.is_object() || found) continue;
            if (e.contains("components") && e["components"].is_object() && e["components"].contains("Camera") &&
                e["components"]["Camera"].is_object()) {
                const Json& cam = e["components"]["Camera"];
                if (cam.value("primary", true) && cam.value("active", true)) {
                    Color c{0.08f, 0.08f, 0.12f, 1.0f};
                    if (cam.contains("clearColor")) {
                        std::string err;
                        if (!json_to(cam["clearColor"], c, &err)) continue;
                    }
                    found = c;
                    return;
                }
            }
            if (e.contains("children")) walk(e["children"]);
        }
    };
    walk((*scene)["entities"]);
    return found;
}

// ---- models ------------------------------------------------------------------------------------------------------------------

struct TempScene {
    stdfs::path file;
    ~TempScene() {
        std::error_code ec;
        if (!file.empty()) stdfs::remove(file, ec);
    }
};

Json model_scene(const std::string& rel, const MeshGeometry& geometry) {
    const Vec3 centre = (geometry.bmin + geometry.bmax) * 0.5f;
    const Vec3 half = (geometry.bmax - geometry.bmin) * 0.5f;
    const float radius = std::max(1e-3f, std::sqrt(half.x * half.x + half.y * half.y + half.z * half.z));
    const float fov = 40.0f;
    const float distance = radius / std::sin(fov * 0.5f * 3.14159265f / 180.0f) * 1.08f;
    Json camera = Json::object(
        {{"id", "thumb_camera"},
         {"components", Json::object({{"Transform", Json::object({{"position", Json::array({0, 0, distance})}})},
                                      {"Camera", Json::object({{"projection", "perspective"},
                                                               {"fov", fov},
                                                               {"nearPlane", distance * 0.02f},
                                                               {"farPlane", distance * 8},
                                                               {"lighting", "studio"},
                                                               {"clearColor", Json::array({0, 0, 0, 0})}})}})}});
    Json model = Json::object(
        {{"id", "thumb_model"},
         {"components",
          Json::object({{"Transform", Json::object({{"position", Json::array({-centre.x, -centre.y, -centre.z})}})},
                        {"MeshRenderer", Json::object({{"mesh", rel}})}})}});
    Json pivot = Json::object(
        {{"id", "thumb_pivot"},
         {"components", Json::object({{"Transform", Json::object({{"rotation", Json::array({18, -32, 0})}})}})},
         {"children", Json::array({model})}});
    return Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({camera, pivot})}});
}

// Draws every model of `rels` once in one engine; the pictures have straight alpha (transparent around the model).
std::vector<Image> render_models(const std::string& projectDir, const std::vector<std::string>& rels) {
    std::vector<Json> scenes;
    for (const std::string& rel : rels) {
        auto geometry = load_mesh_geometry(rel);
        if (!geometry.ok())
            fail("invalid_argument", "'" + rel + "' cannot be read as a model: " + geometry.error().message,
                 geometry.error().hint);
        scenes.push_back(model_scene(rel, **geometry));
    }
    TempScene temp;
    const std::string sceneRel = ".factoria/tmp/contact_sheet.scene.json";
    temp.file = project_file(projectDir, sceneRel);
    std::string err;
    if (!tooling_detail::write_file(temp.file, scenes.front().dump(2), &err))
        fail("failed", "Cannot write the scene the thumbnails start from: " + err);
    EngineConfig cfg = tooling_detail::headless_engine_config(projectDir, sceneRel, true, RenderMode::OnDemand);
    cfg.width = kModelRender;
    cfg.height = kModelRender;
    Engine engine;
    if (!engine.init(cfg, nullptr, &err)) {
        if (err.find("No renderer") != std::string::npos || err.find("graphics") != std::string::npos)
            no_gpu_error(kCommand, err, "Without a GPU leave the .glb files out of `paths`.");
        fail("failed", "Cannot start the engine that draws the models: " + err);
    }
    struct Shutdown {
        Engine& e;
        ~Shutdown() { e.shutdown(); }
    } shutdown{engine};
    std::vector<Image> out;
    for (std::size_t i = 0; i < rels.size(); ++i) {
        std::string loadError;
        if (!engine.load_scene_json(scenes[i], rels[i], &loadError))
            fail("invalid_argument", "Cannot draw '" + rels[i] + "': " + loadError,
                 "Check the model with factoria validate.");
        engine.step(1);
        Image img;
        if (!engine.capture_scaled(img, 1.0, &err)) {
            if (err.find("No renderer") != std::string::npos)
                no_gpu_error(kCommand, err, "Without a GPU leave the .glb files out of `paths`.");
            fail("failed", "Cannot capture the thumbnail of '" + rels[i] + "': " + err);
        }
        for (std::size_t p = 0; p + 3 < img.rgba.size(); p += 4) {  // the GPU leaves premultiplied pixels
            const unsigned a = img.rgba[p + 3];
            if (a == 0 || a == 255) continue;
            for (int k = 0; k < 3; ++k)
                img.rgba[p + k] = std::uint8_t(std::min(255u, (img.rgba[p + k] * 255u + a / 2) / a));
        }
        out.push_back(std::move(img));
    }
    return out;
}

// ---- the sheet ---------------------------------------------------------------------------------------------------------------

Image cell_picture(const Image& src, double longest) {
    const double scale = longest / std::max(src.width, src.height);
    return resize_area(src, std::max(1, int(std::lround(src.width * scale))),
                       std::max(1, int(std::lround(src.height * scale))));
}

struct Frames {
    std::vector<Image> frames;
    int total = 1;  // frames the sheet has
    bool sheet = false;
};

Frames cut_frames(const std::string& rel, const Image& img, bool all) {
    Frames f;
    std::shared_ptr<const assets::Sheet> entry = assets::sheet(rel);
    if (!entry) {
        f.frames.push_back(img);
        return f;
    }
    f.sheet = true;
    const int padding = std::max(0, entry->padding);
    const int columns = std::max(1, entry->columns), rows = std::max(1, entry->rows);
    const int fw = entry->frameWidth > 0 ? entry->frameWidth : std::max(1, img.width / columns - 2 * padding);
    const int fh = entry->frameHeight > 0 ? entry->frameHeight : std::max(1, img.height / rows - 2 * padding);
    const int cw = fw + 2 * padding, ch = fh + 2 * padding;
    f.total = std::clamp(entry->frames > 0 ? entry->frames : columns * rows, 1, columns * rows);
    for (int i = 0; i < (all ? f.total : 1); ++i)
        f.frames.push_back(crop_image(img, padding + (i % columns) * cw, padding + (i / columns) * ch, fw, fh));
    return f;
}

Json contact_sheet_command(const std::string& projectDir, const Json& a) {
    if (!a.is_object())
        fail("invalid_argument", "assets.contact_sheet expects an object.",
             "Pass {\"paths\": [\"assets/hero.png\", \"assets/enemy.png\"]}.");
    check_arg_keys(kCommand, a, "",
                   {"paths", "backgrounds", "sizes", "greyscale", "columns", "allFrames", "path", "overwrite"});

    // ---- arguments ----
    if (!a.contains("paths") || !a["paths"].is_array() || a["paths"].empty() ||
        a["paths"].size() > std::size_t(kMaxPaths))
        bad("/paths", std::format("expected a list of 1 to {} project paths.", kMaxPaths),
            "Example: {\"paths\": [\"assets/hero.png\", \"assets/enemy.png\"]}; assets.list shows the images of the "
            "project.");
    std::vector<std::string> paths;
    for (std::size_t i = 0; i < a["paths"].size(); ++i) {
        const Json& p = a["paths"][i];
        const std::string at = "/paths/" + std::to_string(i);
        if (!p.is_string()) bad(at, "expected a project-relative path as a string.", "Example: \"assets/hero.png\".");
        auto norm = fs::normalize_checked(p.get<std::string>());
        if (!norm.ok() || norm->empty())
            bad(at, "'" + p.get<std::string>() + "' is not a path inside the project.",
                "Use a project-relative path such as \"assets/hero.png\".");
        paths.push_back(*norm);
    }
    std::vector<double> sizes;
    if (a.contains("sizes") && !a["sizes"].is_null()) {
        if (!a["sizes"].is_array() || a["sizes"].empty() || a["sizes"].size() > 6)
            bad("/sizes", "expected a list of 1 to 6 sizes in pixels.",
                "Example: [32, 64]: the longest side of each picture on the screen of the player, one column per size. "
                "Leave it out for the native size.");
        for (std::size_t i = 0; i < a["sizes"].size(); ++i) {
            const Json& s = a["sizes"][i];
            if (!s.is_number() || s.get<double>() < 4 || s.get<double>() > kMaxSize)
                bad("/sizes/" + std::to_string(i), std::format("expected a number of pixels from 4 to {}.", kMaxSize),
                    "It is the longest side of the picture as the player sees it: Sprite.size on screen times the "
                    "render scale, e.g. 48.");
            sizes.push_back(s.get<double>());
        }
    }
    const bool greyscale = tooling_detail::arg_bool(a, "greyscale", true);
    const bool allFrames = tooling_detail::arg_bool(a, "allFrames", false);
    const int columns = int(tooling_detail::arg_int(a, "columns", 8));
    if (columns < 1 || columns > 16)
        bad("/columns", "expected a whole number from 1 to 16.",
            "Cells per line before the sheet wraps to the next block of rows. Default 8.");
    // The picture is kept only when the caller gives `path`: that needs writeProject, and the path is judged now, before any drawing.
    std::string outRel;
    stdfs::path outFile;
    if (a.contains("path") && !a["path"].is_null()) {
        if (!a["path"].is_string() || to_lower(fs::extension(a["path"].get<std::string>())) != ".png")
            bad("/path", "expected a path ending in .png.",
                "Example: \"docs/review/enemies.png\". Leave it out to only look at the picture (no project file is "
                "written).");
        outFile = caller_output_file(projectDir, a["path"].get<std::string>(), kCommand);
        outRel = output_spelling(a["path"].get<std::string>());
        if (!tooling_detail::arg_bool(a, "overwrite", false)) {
            std::error_code ec;
            if (stdfs::exists(outFile, ec))
                fail("exists", "'" + outRel + "' already exists.",
                     "Pass overwrite: true to replace it, or choose another `path`.");
        }
    }

    std::vector<Background> backgrounds;
    std::set<std::string> seen;
    auto add_background = [&](const std::string& name, const Color& c) {
        if (seen.insert(hex_colour(c)).second) backgrounds.push_back({name, rgb8(c)});
    };
    if (a.contains("backgrounds") && !a["backgrounds"].is_null()) {
        if (!a["backgrounds"].is_array() || a["backgrounds"].empty() || a["backgrounds"].size() > 6)
            bad("/backgrounds", "expected a list of 1 to 6 colours.",
                "Example: [\"#ffffff\", \"#202028\", \"#3a7d44\"]. Leave it out for a light one, a dark one and the "
                "clear colour of the main camera.");
        for (std::size_t i = 0; i < a["backgrounds"].size(); ++i) {
            const Color c = colour_arg(kCommand, a["backgrounds"][i], "/backgrounds/" + std::to_string(i));
            if (seen.insert(hex_colour(c)).second) backgrounds.push_back({hex_colour(c), rgb8(c)});
        }
    } else {
        add_background("light", Color{0.91f, 0.91f, 0.93f, 1});
        add_background("dark", Color{0.086f, 0.086f, 0.11f, 1});
        if (auto clear = main_camera_clear(projectDir)) add_background("camera", *clear);
    }

    // ---- the pictures ----
    ProjectRootGuard root(projectDir);
    std::vector<std::string> glbs;
    for (const std::string& rel : paths) {
        const std::string ext = to_lower(fs::extension(rel));
        std::error_code ec;
        if (!stdfs::is_regular_file(project_file(projectDir, rel), ec))
            fail("not_found", "'" + rel + "' does not exist.",
                 "assets.list shows the images and models of the project.");
        if (ext == ".glb")
            glbs.push_back(rel);
        else if (ext == ".gltf")
            fail("invalid_argument", "'" + rel + "' is a .gltf: only .glb models are drawn in a contact sheet.",
                 "Use assets.preview_in_scene for the .gltf, or assets.import to make a .glb.");
        else if (ext != ".png" && ext != ".jpg" && ext != ".jpeg" && ext != ".bmp" && ext != ".tga")
            fail("invalid_argument",
                 "'" + rel + "' is not a picture or a .glb model (" + (ext.empty() ? "no extension" : ext) + ").",
                 "A contact sheet shows PNG (and JPG, BMP, TGA) images and .glb models. For sound use "
                 "assets.spectrogram; for a font, a Text in a scene and game.screenshot.");
    }
    std::vector<Image> modelPictures;
    if (!glbs.empty()) {
        if (gfx_device_active()) return call_in_child(projectDir, kCommand, a);
        modelPictures = render_models(projectDir, glbs);
    }

    std::vector<std::string> warnings;
    std::vector<Item> items;
    std::size_t glbIndex = 0;
    for (const std::string& rel : paths) {
        const bool isModel = to_lower(fs::extension(rel)) == ".glb";
        std::vector<Image> pictures;
        std::vector<std::string> labels;
        std::string info;
        if (isModel) {
            pictures.push_back(modelPictures[glbIndex++]);
            labels.push_back(base_name(rel));
            info = "model";
        } else {
            auto loaded = load_image(project_file(projectDir, rel));
            if (!loaded.ok()) fail("invalid_argument", "'" + rel + "': " + loaded.error().message, loaded.error().hint);
            Frames frames = cut_frames(rel, *loaded, allFrames);
            for (std::size_t i = 0; i < frames.frames.size(); ++i) {
                pictures.push_back(std::move(frames.frames[i]));
                labels.push_back(base_name(rel) +
                                 (frames.sheet && (allFrames || frames.total > 1) ? " f" + std::to_string(i) : ""));
            }
            if (frames.sheet && !allFrames && frames.total > 1)
                warnings.push_back(std::format("'{}' is a sprite sheet of {} frames: only frame 0 is shown. Pass "
                                               "allFrames: true to see all of them.",
                                               rel, frames.total));
            info = std::format("{}x{}", pictures.front().width, pictures.front().height);
        }
        for (std::size_t i = 0; i < pictures.size(); ++i) {
            Item item;
            item.label = labels[i];
            item.info = info;
            const Image& src = pictures[i];
            const double nativeLongest = isModel ? kModelNative : std::max(src.width, src.height);
            if (sizes.empty()) {
                if (nativeLongest > kMaxSize) {
                    warnings.push_back(
                        std::format("'{}' is {} px on its longest side: shown at {} px. Pass `sizes` to choose.", rel,
                                    int(nativeLongest), kMaxSize));
                    item.sizes.push_back(cell_picture(src, kMaxSize));
                } else {
                    item.sizes.push_back(isModel ? cell_picture(src, kModelNative) : src);
                }
            } else {
                for (double s : sizes) item.sizes.push_back(cell_picture(src, s));
            }
            items.push_back(std::move(item));
        }
    }

    // ---- the cells: one column per (picture, size) ----
    struct Cell {
        const Image* pic;
        std::string label, info;
    };
    std::vector<Cell> cells;
    for (const Item& item : items)
        for (const Image& s : item.sizes)
            cells.push_back({&s, item.label, sizes.empty() ? item.info : std::format("{}x{}", s.width, s.height)});
    if (cells.size() > 160)
        fail("invalid_argument",
             std::format("{} cells (pictures x sizes x frames) are too many for one picture; the most is 160.",
                         cells.size()),
             "Split `paths` in two calls, or use fewer `sizes`, or leave out allFrames.");

    struct Row {
        std::string name;
        Rgb8 bg;
        bool grey;
    };
    std::vector<Row> rows;
    for (const Background& b : backgrounds) rows.push_back({b.name, b.colour, false});
    if (greyscale) rows.push_back({"greyscale", {128, 128, 128}, true});

    int gutter = 0;
    for (const Row& r : rows) gutter = std::max(gutter, text_width(r.name, kFont));
    gutter += 2 * kPad;
    const int headerH = 2 * int(kFont + 4) + kPad;

    struct Block {
        std::size_t first, last;  // cells [first, last)
        std::vector<int> widths;
        int cellH = 0;
        int y = 0, height = 0;
    };
    std::vector<Block> blocks;
    int width = 0, height = 0;
    for (std::size_t first = 0; first < cells.size(); first += std::size_t(columns)) {
        Block b;
        b.first = first;
        b.last = std::min(cells.size(), first + std::size_t(columns));
        for (std::size_t c = b.first; c < b.last; ++c) {
            b.widths.push_back(std::max(cells[c].pic->width,
                                        std::max(text_width(cells[c].label, kFont), text_width(cells[c].info, kFont))) +
                               2 * kPad);
            b.cellH = std::max(b.cellH, cells[c].pic->height + 2 * kPad);
        }
        b.y = height;
        b.height = headerH + int(rows.size()) * b.cellH;
        height += b.height;
        int w = gutter;
        for (int cw : b.widths) w += cw;
        width = std::max(width, w);
        blocks.push_back(std::move(b));
    }

    Image sheet;
    sheet.width = width;
    sheet.height = height;
    sheet.rgba.assign(std::size_t(width) * height * 4, 255);
    fill_rect_rgb(sheet, 0, 0, width, height, {34, 34, 40});
    for (const Block& b : blocks) {
        int x = gutter;
        for (std::size_t c = b.first; c < b.last; ++c) {
            const int cw = b.widths[c - b.first];
            draw_text(sheet, x + kPad, b.y + 2, cells[c].label, kFont, {235, 235, 240});
            draw_text(sheet, x + kPad, b.y + 2 + int(kFont + 4), cells[c].info, kFont, {150, 150, 160});
            for (std::size_t r = 0; r < rows.size(); ++r) {
                const int y = b.y + headerH + int(r) * b.cellH;
                fill_rect_rgb(sheet, x, y, cw, b.cellH, rows[r].bg);
                const Image pic = rows[r].grey ? to_greyscale(*cells[c].pic) : *cells[c].pic;
                draw_over(sheet, pic, x + (cw - pic.width) / 2, y + (b.cellH - pic.height) / 2);
            }
            x += cw;
        }
        for (std::size_t r = 0; r < rows.size(); ++r) {
            const int y = b.y + headerH + int(r) * b.cellH;
            const Rgb8 on =
                rows[r].bg.r + rows[r].bg.g + rows[r].bg.b > 3 * 128 ? Rgb8{20, 20, 24} : Rgb8{225, 225, 230};
            fill_rect_rgb(sheet, 0, y, gutter, b.cellH, rows[r].bg);
            draw_text(sheet, kPad, y + kPad, rows[r].name, kFont, on);
        }
    }

    double pictureScale = 1.0;
    if (std::max(sheet.width, sheet.height) > kMaxPicture) {
        pictureScale = double(kMaxPicture) / std::max(sheet.width, sheet.height);
        sheet = resize_area(sheet, std::max(1, int(std::lround(sheet.width * pictureScale))),
                            std::max(1, int(std::lround(sheet.height * pictureScale))));
        warnings.push_back(std::format("The sheet was {} px wide or tall and is shown reduced to {}%: give fewer "
                                       "pictures, `sizes` or a smaller `columns` to see them as they are.",
                                       kMaxPicture, int(std::lround(pictureScale * 100))));
    }

    // ---- the result ----
    Json result = Json::object({{"paths", paths}});
    Json rowNames = Json::array();
    for (const Row& r : rows) rowNames.push_back(r.name);
    Json bgJson = Json::array();
    for (const Background& b : backgrounds)
        bgJson.push_back(Json::object(
            {{"name", b.name}, {"color", std::format("#{:02x}{:02x}{:02x}", b.colour.r, b.colour.g, b.colour.b)}}));
    result["backgrounds"] = bgJson;
    result["rows"] = rowNames;
    result["cells"] = int(cells.size());
    result["picture"] = Json::object({{"width", sheet.width}, {"height", sheet.height}, {"scale", pictureScale}});
    if (!outRel.empty()) {
        const std::vector<std::uint8_t> png = encode_png(sheet);
        std::string err;
        if (!tooling_detail::write_file(outFile,
                                        std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err))
            fail("failed", err);
        result["written"] = outRel;
        result["$image"] = image_member(outFile, false);
    } else {
        result["$image"] = image_member(write_temporary_picture(projectDir, sheet, "contacts"), true);
    }
    result["warnings"] = warnings;
    std::vector<std::string> steps;
    steps.push_back("Read the picture: one column per picture" + std::string(sizes.empty() ? "" : " and size") +
                    " (file name and size above it), one row per background" +
                    (greyscale ? ", the last one in greyscale." : "."));
    steps.push_back("Look for what disappears: a shape that merges with one background, an outline that vanishes when "
                    "small, two sprites that look the same in greyscale (the value structure is too flat).");
    if (sizes.empty())
        steps.push_back("Pass sizes: [32, 64] to see them at the sizes the camera shows them (Sprite.size on screen, "
                        "times the render scale).");
    steps.push_back(
        "To see one asset in the real scene, with its lighting and neighbours, use assets.preview_in_scene; for the "
        "whole game use game.screenshot; for a sprite sheet's frames and pivot assets.preview_sheet.");
    if (outRel.empty())
        steps.push_back("Pass path to keep the picture as a PNG in the project (for a review or a pull request).");
    result["nextSteps"] = steps;
    return result;
}

}  // namespace

void register_contact_sheet_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.summary = "Look at a set of images (or .glb models) side by side at their on-screen size, over light, dark "
                   "and camera-colour backgrounds and in greyscale, labelled with their file names.";
    info.description =
        "Draws one picture (returned to you as an image) with a column for each picture of `paths` (and for "
        "each of `sizes`) and a row for each background, so you can judge a set of assets the way the player "
        "meets them: small, on the real ground, in black and white. `backgrounds` default to a light colour, "
        "a dark colour and the clear colour of the first primary camera of the project's main scene (when it "
        "has one); the last row is the same pictures in greyscale over mid-grey (`greyscale: false` leaves "
        "it out). `sizes` are pixels of the longest side of each picture as the player sees it (Sprite.size "
        "on screen times the render scale): [32, 64] draws every picture twice, shrunk with averaging or "
        "grown with hard pixels; without `sizes` each picture is drawn at its native size (at most 512). "
        "PNG, JPG, BMP and TGA files are drawn as they are; a sprite sheet (one with a `sheet` entry in "
        "assets.json) shows its first frame, or all frames with `allFrames: true`. Example: "
        "{\"paths\":[\"assets/hero.png\",\"assets/slime.png\"],\"sizes\":[32,64]}." FA_COMMAND_DETAILS
        "A .glb model is drawn as a thumbnail by the engine's renderer (a studio light, turned three "
        "quarters, transparent around it), which needs a graphics device (Metal, Direct3D 11 or OpenGL; "
        "without one the command fails with no_gpu, and you can leave the models out); a model in the real "
        "scene, with its lighting, is assets.preview_in_scene. Each column is labelled with the file name "
        "and its size in the font that comes with the engine. A line holds `columns` cells (default 8), then "
        "the sheet continues below. No project file is written unless `path` is given (the picture is otherwise a "
        "temporary screenshot in .factoria/screenshots): then the PNG is also saved "
        "there, which needs the writeProject capability (an existing file is not replaced without `overwrite: true`). "
        "The same inputs give the same "
        "picture.";
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"paths"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"paths",
                Json::object(
                    {{"type", "array"},
                     {"minItems", 1},
                     {"maxItems", kMaxPaths},
                     {"items", Json::object({{"type", "string"}})},
                     {"description", "Project-relative paths of the pictures (PNG, JPG, BMP, TGA) and .glb models to "
                                     "show, in this order. A sprite sheet shows its first frame (see allFrames)."}})},
               {"backgrounds",
                Json::object({{"type", "array"},
                              {"minItems", 1},
                              {"maxItems", 6},
                              {"items", Json::object({{"type", "string"}})},
                              {"description",
                               "Colours (\"#rrggbb\", a name, or [r, g, b] in 0..1) to draw the pictures over, one row "
                               "each. Default: a light one, a dark one and the clear colour of the main camera."}})},
               {"sizes",
                Json::object(
                    {{"type", "array"},
                     {"minItems", 1},
                     {"maxItems", 6},
                     {"items", Json::object({{"type", "number"}, {"minimum", 4}, {"maximum", kMaxSize}})},
                     {"description", "Longest side in pixels of each picture as the player sees it; one column per "
                                     "picture and size. Default: the native size of each picture."}})},
               {"greyscale", Json::object({{"type", "boolean"},
                                           {"default", true},
                                           {"description", "Add a last row with the pictures in greyscale over "
                                                           "mid-grey, to judge their value structure."}})},
               {"columns", Json::object({{"type", "integer"},
                                         {"minimum", 1},
                                         {"maximum", 16},
                                         {"default", 8},
                                         {"description", "Cells per line; more wrap to a new block of rows below."}})},
               {"allFrames",
                Json::object(
                    {{"type", "boolean"},
                     {"default", false},
                     {"description", "A sprite sheet shows all its frames (a column each) instead of the first."}})},
               {"path",
                path_property("write",
                              "Also save the picture as a PNG at this path (ending in .png; project-relative, an "
                              "absolute path only for the command-line user). Needs the writeProject capability. "
                              "Without it only a temporary screenshot in .factoria/screenshots is made.")},
               {"overwrite", Json::object({{"type", "boolean"},
                                           {"default", false},
                                           {"description", "With `path`: replace the file when it exists."}})}})}});
    registry.add(info, [projectDir](const Json& args) { return contact_sheet_command(projectDir, args); });
    // Capabilities (capability.h): it draws a temporary screenshot in .factoria/screenshots (state); `path`, which keeps the picture, is
    // checked for writeProject by the handler. A .glb is drawn in a child `factoria call` of this same command when this process
    // holds the graphics device.
    declare_command_capabilities(registry, {{kCommand, capability_sets::changes_state()}});
}

}  // namespace fa::assets_detail
