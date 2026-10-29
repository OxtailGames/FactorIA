// assets.animate_svg: an animation drawn with code, baked into a sprite sheet in one call. A project JS module (a `frame()`
// function that returns the SVG of each frame) or one SVG with SMIL animation is sampled frame by frame; every frame is
// rasterized with the path of assets.rasterize_svg (rasterize_svg_text: same pixels, same painterly styles), snapped to an
// optional palette, and laid out in a grid with gutters. The PNG and its `sheet` entry of assets.json are written together,
// and provenance.recipe records how to make the sheet again. The sandbox of the module is assets_anim_js.cpp, the sampling of
// SMIL is svg_smil.cpp.
#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "assets_anim_js.h"
#include "assets_internal.h"
#include "sheet_checks.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/asset_import.h"
#include "fa/tooling/palette.h"
#include "fa/tooling/svg_smil.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kCommand = "assets.animate_svg";
constexpr int kMaxCell = 1024;        // a frame side
constexpr int kMaxSheetSide = 8192;   // the PNG's side
constexpr int kMaxFrames = 2048;

struct ClipSpec {
    std::string name;
    int frames = 1;
    double fps = 12;
    bool loop = true;
    Json params = Json::object();
    std::optional<std::array<double, 2>> pivot;
};

struct FrameJob {
    int clip = 0;         // index in the clips
    int frame = 0;        // inside the clip
    int sheetFrame = 0;
};

std::string checked_png_path(const std::string& path) {
    auto norm = fs::normalize_checked(path);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", "The sheet goes under assets/, and '" + path + "' is not there.", "Use a path such as \"assets/art/coin_spin.png\".");
    if (to_lower(fs::extension(*norm)) != ".png")
        fail("invalid_argument", std::string(kCommand) + " writes PNG files, and '" + *norm + "' does not end in .png.", "Use a path such as \"assets/art/coin_spin.png\".");
    return *norm;
}

int int_arg(const Json& obj, const char* key, const std::string& pointer, int lo, int hi, int fallback, const char* hint) {
    auto it = obj.find(key);
    if (it == obj.end() || it->is_null()) return fallback;
    if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi)
        arg_error(kCommand, pointer + "/" + key, std::format("expected a whole number from {} to {}.", lo, hi), hint);
    return int(it->get<long long>());
}

double fps_arg(const Json& obj, const std::string& pointer, double fallback) {
    auto it = obj.find("fps");
    if (it == obj.end() || it->is_null()) return fallback;
    if (!it->is_number() || !(it->get<double>() > 0.0 && it->get<double>() <= 240.0))
        arg_error(kCommand, pointer + "/fps", "expected a number above 0 and up to 240 (frames per second).", "12 is a good rate for hand-drawn motion, 24 for smooth motion.");
    return it->get<double>();
}

bool loop_arg(const Json& obj, const std::string& pointer, bool fallback) {
    auto it = obj.find("loop");
    if (it == obj.end() || it->is_null()) return fallback;
    if (!it->is_boolean()) arg_error(kCommand, pointer + "/loop", "expected true or false.", "true repeats the clip (the default); false plays it once.");
    return it->get<bool>();
}

Json params_arg(const Json& obj, const std::string& pointer) {
    auto it = obj.find("params");
    if (it == obj.end() || it->is_null()) return Json::object();
    if (!it->is_object()) arg_error(kCommand, pointer + "/params", "expected an object.", "params is the object the module receives as `params`: {\"color\": \"#e8c66a\"}.");
    return *it;
}

std::optional<std::array<double, 2>> pivot_arg(const Json& obj, const std::string& pointer) {
    auto it = obj.find("pivot");
    if (it == obj.end() || it->is_null()) return std::nullopt;
    if (!it->is_array() || it->size() != 2 || !(*it)[0].is_number() || !(*it)[1].is_number() || (*it)[0].get<double>() < 0 || (*it)[0].get<double>() > 1 ||
        (*it)[1].get<double>() < 0 || (*it)[1].get<double>() > 1)
        arg_error(kCommand, pointer + "/pivot", "expected [x, y], two numbers from 0 to 1 measured from the top-left of the frame.",
                  "[0.5, 0.5] is the centre (the default); [0.5, 1] is the middle of the bottom edge, where a character stands.");
    return std::array<double, 2>{(*it)[0].get<double>(), (*it)[1].get<double>()};
}

Json animate(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "assets.animate_svg expects an object.", "See the description of the command for the fields.");
    check_arg_keys(kCommand, a, "", {"path", "source", "svg", "frames", "fps", "loop", "columns", "frameWidth", "frameHeight", "params", "seed", "clips", "pivot",
                                     "palette", "style", "styleStrength", "padding", "overwrite", "ai", "author", "license", "timeLimitMs"});
    const std::string rel = checked_png_path(tooling_detail::arg_string(a, "path", true));
    const bool hasSvg = a.contains("svg"), hasSource = a.contains("source");
    if (hasSvg == hasSource)
        fail("invalid_argument", hasSvg ? "Give either `source` (a module or an SVG file of the project) or `svg` (SVG text with SMIL animation), not both."
                                        : "Give `source` (a project module such as \"art/coin_spin.anim.js\") or `svg` (one SVG with SMIL animation).",
             "Example: {\"path\":\"assets/art/coin_spin.png\",\"source\":\"art/coin_spin.anim.js\",\"frames\":8,\"fps\":10,\"frameWidth\":64,\"frameHeight\":64}");

    // ---- the source ----
    std::string sourceRel, svgText;
    bool isModule = false;
    if (hasSvg) {
        svgText = tooling_detail::arg_string(a, "svg", true);
        if (svgText.find("<svg") == std::string::npos)
            arg_error(kCommand, "/svg", "the text has no <svg> element.", "Start with <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\"> and put <animate> elements inside the shapes.");
    } else {
        auto norm = fs::normalize_checked(tooling_detail::arg_string(a, "source", true));
        if (!norm.ok() || norm->empty()) arg_error(kCommand, "/source", "not a project path.", "Use a project-relative path such as \"art/coin_spin.anim.js\".");
        sourceRel = *norm;
        const std::string ext = to_lower(fs::extension(sourceRel));
        if (ext == ".js" || ext == ".mjs") {
            isModule = true;
        } else if (ext == ".svg") {
            auto data = tooling_detail::read_file(project_file(projectDir, sourceRel));
            if (!data) fail("not_found", "Cannot read '" + sourceRel + "'.", "Check the path; it is relative to the project folder.");
            svgText = std::move(*data);
        } else {
            arg_error(kCommand, "/source", "'" + sourceRel + "' is neither a JavaScript module (.js) nor an .svg file.",
                      "Name the module that draws the frames (\"art/coin_spin.anim.js\"), or an .svg with SMIL animation.");
        }
    }

    // ---- the frames ----
    const double fps = fps_arg(a, "", 12);
    const bool loop = loop_arg(a, "", true);
    const int frameW = int_arg(a, "frameWidth", "", 1, kMaxCell, 64, "The size of one frame in pixels, 1 to 1024; the SVG is fitted inside, aspect kept, centred.");
    const int frameH = int_arg(a, "frameHeight", "", 1, kMaxCell, frameW, "The size of one frame in pixels, 1 to 1024; the SVG is fitted inside, aspect kept, centred.");
    const int padding = int_arg(a, "padding", "", 0, 64, 0, "Transparent pixels around every cell (0 to 64): 1 or 2 keeps filtered frames from bleeding into each other.");
    const std::uint32_t seed = std::uint32_t(tooling_detail::arg_int(a, "seed", 0));
    const Json params = params_arg(a, "");
    const auto pivot = pivot_arg(a, "");
    const int timeLimitMs = int_arg(a, "timeLimitMs", "", 10, 60000, 2000, "Milliseconds a module may take to load, and for each frame (default 2000).");
    std::vector<std::string> warnings;
    auto warn = [&](const std::string& w) {
        if (std::find(warnings.begin(), warnings.end(), w) == warnings.end()) warnings.push_back(w);
    };

    std::optional<SmilSvg> smil;
    double cycle = 0;
    if (!isModule) {
        auto parsed = SmilSvg::parse(svgText);
        if (!parsed.ok()) fail("invalid_svg", (sourceRel.empty() ? std::string("`svg`: ") : sourceRel + ": ") + parsed.error().message, parsed.error().hint);
        smil = std::move(*parsed);
        cycle = smil->cycle_seconds();
        if (smil->animation_count() == 0)
            warn("The SVG has no <animate>, <set>, <animateTransform> or <animateMotion> element: every frame is the same. Animate it, or give `source` a module that draws each frame.");
        if (a.contains("params") && !params.empty()) warn("`params` only reaches a module (`source`); an SVG with SMIL ignores it.");
    }

    std::vector<ClipSpec> clips;
    const bool hasClips = a.contains("clips") && !a["clips"].is_null();
    if (hasClips) {
        if (!isModule)
            arg_error(kCommand, "/clips", "clips need a module (`source`): one SMIL SVG has a single timeline.",
                      "Draw the clips in a module that reads `clip` from its argument, or call assets.animate_svg once per animation.");
        if (a.contains("frames"))
            arg_error(kCommand, "/frames", "give `frames` per clip when there are `clips`; the sheet holds all of them one after another.", "Remove /frames and set /clips/0/frames.");
        const Json& list = a["clips"];
        if (!list.is_array() || list.empty())
            arg_error(kCommand, "/clips", "expected a non-empty array of clips.",
                      "Example: [{\"name\":\"idle\",\"frames\":4,\"fps\":6},{\"name\":\"spin\",\"frames\":8,\"fps\":12}]");
        std::set<std::string> seen;
        for (std::size_t i = 0; i < list.size(); ++i) {
            const std::string ptr = "/clips/" + std::to_string(i);
            const Json& c = list[i];
            if (!c.is_object()) arg_error(kCommand, ptr, "expected an object {name, frames, fps, loop, params, pivot}.", "Example: {\"name\":\"idle\",\"frames\":4,\"fps\":6}");
            check_arg_keys(kCommand, c, ptr, {"name", "frames", "fps", "loop", "params", "pivot"});
            ClipSpec spec;
            if (!c.contains("name") || !c["name"].is_string() || c["name"].get<std::string>().empty())
                arg_error(kCommand, ptr + "/name", "expected a non-empty string.", "The name the module reads as `clip` and the SpriteAnimator plays: \"idle\", \"spin\".");
            spec.name = c["name"].get<std::string>();
            if (!seen.insert(spec.name).second) arg_error(kCommand, ptr + "/name", "the name '" + spec.name + "' is used by two clips.", "Give every clip its own name.");
            spec.frames = int_arg(c, "frames", ptr, 1, kMaxFrames, 0, "The number of frames of this clip.");
            if (spec.frames == 0) arg_error(kCommand, ptr + "/frames", "required: how many frames the clip has.", "For example \"frames\": 8.");
            spec.fps = fps_arg(c, ptr, fps);
            spec.loop = loop_arg(c, ptr, loop);
            spec.params = params_arg(c, ptr);
            spec.pivot = pivot_arg(c, ptr);
            clips.push_back(std::move(spec));
        }
    } else {
        ClipSpec spec;
        spec.name = stdfs::path(rel).stem().string();
        if (spec.name.empty()) spec.name = "clip";
        int frames = int_arg(a, "frames", "", 1, kMaxFrames, 0, "The number of frames of the animation.");
        if (frames == 0) {
            if (isModule)
                arg_error(kCommand, "/frames", "required with a module: how many frames to draw.", "For example \"frames\": 8 (with fps 10 that is 0.8 s).");
            frames = cycle > 0 ? std::max(1, int(std::lround(cycle * fps))) : 1;
            if (frames > kMaxFrames) arg_error(kCommand, "/frames", std::format("the animation lasts {} s, which is {} frames at {} fps.", cycle, frames, fps), "Pass `frames` and a lower `fps`.");
        }
        spec.frames = frames;
        spec.fps = fps;
        spec.loop = loop;
        clips.push_back(std::move(spec));
    }
    int total = 0;
    for (const ClipSpec& c : clips) total += c.frames;
    if (total > kMaxFrames) arg_error(kCommand, hasClips ? "/clips" : "/frames", std::format("{} frames in all; the most a sheet takes is {}.", total, kMaxFrames), "Draw fewer frames, or split the animation into two sheets.");

    int columns = int_arg(a, "columns", "", 1, kMaxFrames, 0, "How many frames per row of the sheet.");
    if (columns == 0) columns = int(std::ceil(std::sqrt(double(total))));
    if (columns > total) {
        warn(std::format("columns {} is more than the {} frames; it was lowered to {}.", columns, total, total));
        columns = total;
    }
    const int rows = (total + columns - 1) / columns;
    const int cellW = frameW + 2 * padding, cellH = frameH + 2 * padding;
    const long long sheetW = (long long)columns * cellW, sheetH = (long long)rows * cellH;
    if (sheetW > kMaxSheetSide || sheetH > kMaxSheetSide)
        fail("invalid_argument", std::format("The sheet would be {}x{} px ({} columns x {} rows of {}x{} cells); the most is {}.", sheetW, sheetH, columns, rows, cellW, cellH, kMaxSheetSide),
             "Make the frames smaller, or set `columns` so the sheet is closer to a square (" + std::to_string(int(std::ceil(std::sqrt(double(total))))) + " columns for " + std::to_string(total) + " frames).");

    // ---- the look ----
    std::string style = "none";
    if (a.contains("style") && !a["style"].is_null()) {
        if (!a["style"].is_string()) arg_error(kCommand, "/style", "expected a string.", "One of: " + join(image_style_names(), ", ") + ".");
        style = to_lower(a["style"].get<std::string>());
        const auto& names = image_style_names();
        if (std::find(names.begin(), names.end(), style) == names.end())
            arg_error(kCommand, "/style", "unknown style '" + a["style"].get<std::string>() + "'.", did_you_mean(style, names) + " Styles: " + join(names, ", ") + ".");
    }
    double styleStrength = 1.0;
    if (a.contains("styleStrength") && !a["styleStrength"].is_null()) {
        if (!a["styleStrength"].is_number() || !(a["styleStrength"].get<double>() >= 0.0 && a["styleStrength"].get<double>() <= 1.0))
            arg_error(kCommand, "/styleStrength", "expected a number from 0 to 1.", "0 leaves the picture as drawn, 1 is the full effect (the default); 0.5 is subtle.");
        styleStrength = a["styleStrength"].get<double>();
    }
    if (style == "none" && a.contains("styleStrength")) warn("styleStrength only matters with a `style`; it was ignored.");
    std::optional<Palette> palette;
    std::vector<std::string> inputs;
    if (a.contains("palette") && !a["palette"].is_null()) {
        ProjectRootGuard root(projectDir);
        auto loaded = load_palette(a["palette"]);
        if (!loaded.ok()) arg_error(kCommand, "/palette", loaded.error().message, loaded.error().hint);
        palette = std::move(*loaded);
        if (a["palette"].is_string()) {
            auto norm = fs::normalize_checked(a["palette"].get<std::string>());
            if (norm.ok() && !norm->empty()) inputs.push_back(*norm);
        }
    }

    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    const stdfs::path file = project_file(projectDir, rel);
    std::error_code ec;
    if (!overwrite && stdfs::exists(file, ec)) fail("exists", "'" + rel + "' already exists.", "Pass overwrite: true to replace it, or choose another `path`.");
    require_usable_manifest(projectDir);

    // ---- draw every frame ----
    std::unique_ptr<AnimModule> module;
    if (isModule) {
        AnimModule::Limits limits;
        limits.seconds = timeLimitMs / 1000.0;
        module = AnimModule::load(projectDir, sourceRel, limits);
    }
    std::vector<FrameJob> jobs;
    for (std::size_t c = 0; c < clips.size(); ++c)
        for (int f = 0; f < clips[c].frames; ++f) jobs.push_back({int(c), f, int(jobs.size())});

    std::vector<Image> pictures(jobs.size());
    std::vector<std::string> emptyFrames, edgeFrames;
    for (const FrameJob& job : jobs) {
        const ClipSpec& clip = clips[std::size_t(job.clip)];
        const double t = job.frame / clip.fps;
        const std::string where = hasClips ? std::format("frame {} of clip \"{}\"", job.frame, clip.name) : std::format("frame {}", job.frame);
        std::string text;
        if (isModule) {
            AnimFrame f;
            f.clip = hasClips ? clip.name : "";
            f.frame = job.frame;
            f.frames = clip.frames;
            f.sheetFrame = job.sheetFrame;
            f.fps = clip.fps;
            f.t = t;
            f.progress = clip.loop ? double(job.frame) / clip.frames : (clip.frames > 1 ? double(job.frame) / (clip.frames - 1) : 0.0);
            f.width = frameW;
            f.height = frameH;
            f.params = params;
            if (hasClips)
                for (auto it = clip.params.begin(); it != clip.params.end(); ++it) f.params[it.key()] = it.value();
            f.baseSeed = seed;
            // the stream of a frame depends on the seed and the frame (its place in the sheet), nothing else
            f.seed = (seed * 2654435761u) ^ (std::uint32_t(job.sheetFrame + 1) * 40503u) ^ 0x9e3779b9u;
            text = module->draw(f);
        } else {
            text = smil->sample(t);
        }
        std::vector<std::string> local;
        Image picture;
        try {
            picture = rasterize_svg_text(text, frameW, frameH, style, styleStrength, seed, local).image;
        } catch (const CommandError& e) {
            if (e.code != "no_shapes") {
                fail(e.code.c_str(), (isModule ? sourceRel + ": " : std::string()) + where + " is not a drawable SVG: " + e.what(), e.hint);
            }
            picture.width = frameW;
            picture.height = frameH;
            picture.rgba.assign(std::size_t(frameW) * frameH * 4, 0);
            for (const std::string& w : local) warn(w);
            const std::string what = e.what();
            if (what.find("not supported") != std::string::npos) warn(where + ": " + what);
        }
        for (const std::string& w : local) warn(w);
        if (palette) picture = quantize_to_palette(picture, *palette);
        if (picture_is_empty(picture)) {
            emptyFrames.push_back(std::to_string(job.sheetFrame));
        } else if (touches_edge(picture)) {
            edgeFrames.push_back(std::to_string(job.sheetFrame));
        }
        pictures[std::size_t(job.sheetFrame)] = std::move(picture);
    }
    if (smil)
        for (const std::string& w : smil->warnings()) warn(w);
    if (!emptyFrames.empty())
        warn(std::format("{} of the {} frames draw nothing (frame {}): the shapes may sit outside the viewBox, or the module returned an empty drawing.", emptyFrames.size(), total, list_frames(emptyFrames)));
    if (!edgeFrames.empty())
        warn(std::format("Shapes touch the edge of the cell in {} frame(s) (frame {}): they may be cut off. Draw smaller inside the viewBox, or make frameWidth/frameHeight larger, or set `padding` (a transparent gutter around each frame).", edgeFrames.size(), list_frames(edgeFrames)));
    {
        int first = 0;
        for (const ClipSpec& clip : clips) {
            if (clip.loop && clip.frames >= 3) {
                std::vector<const Image*> clipFrames;
                for (int f = 0; f < clip.frames; ++f) clipFrames.push_back(&pictures[std::size_t(first + f)]);
                if (auto w = loop_seam_warning(clipFrames, hasClips ? " of clip \"" + clip.name + "\"" : std::string())) warn(*w);
            }
            first += clip.frames;
        }
    }
    if (std::max(sheetW, sheetH) > 4096)
        warn(std::format("The sheet is {}x{} px; many mobile GPUs cannot sample a texture over 4096 px.", sheetW, sheetH));

    // ---- the sheet ----
    Image sheetImage;
    sheetImage.width = int(sheetW);
    sheetImage.height = int(sheetH);
    sheetImage.rgba.assign(std::size_t(sheetW) * std::size_t(sheetH) * 4, 0);
    for (std::size_t i = 0; i < pictures.size(); ++i) {
        const int col = int(i) % columns, row = int(i) / columns;
        const int x0 = padding + col * cellW, y0 = padding + row * cellH;
        for (int y = 0; y < frameH; ++y)
            std::copy_n(&pictures[i].rgba[std::size_t(y) * frameW * 4], std::size_t(frameW) * 4,
                        &sheetImage.rgba[((std::size_t(y0 + y) * sheetImage.width) + x0) * 4]);
    }
    const std::vector<std::uint8_t> png = encode_png(sheetImage);
    std::string err;
    if (!tooling_detail::write_file(file, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err)) fail("failed", err);

    std::vector<SheetClip> sheetClips;
    {
        int first = 0;
        for (const ClipSpec& c : clips) {
            SheetClip sc;
            sc.name = c.name;
            sc.firstFrame = first;
            sc.lastFrame = first + c.frames - 1;
            sc.fps = c.fps;
            sc.loop = c.loop;
            sc.pivot = c.pivot;
            sheetClips.push_back(sc);
            first += c.frames;
        }
    }
    const Json sheet = sheet_entry(columns, rows, frameW, frameH, total, sheetClips, padding, pivot);

    // ---- the record: provenance and recipe ----
    const bool ai = tooling_detail::arg_bool(a, "ai", true);
    const std::string author = tooling_detail::arg_string(a, "author", false, ai ? "" : "factoria");
    const std::string license = tooling_detail::arg_string(a, "license", false, "CC0-1.0");
    Json recipeArgs = Json::object({{"path", rel}, {"fps", fps}, {"loop", loop}, {"columns", columns}, {"frameWidth", frameW}, {"frameHeight", frameH},
                                    {"padding", padding}, {"seed", seed}, {"overwrite", true}});
    if (hasSvg) recipeArgs["svg"] = svgText;
    else recipeArgs["source"] = sourceRel;
    if (hasClips) recipeArgs["clips"] = a["clips"];
    else recipeArgs["frames"] = total;
    if (a.contains("params") && !a["params"].is_null()) recipeArgs["params"] = params;
    if (pivot) recipeArgs["pivot"] = Json::array({(*pivot)[0], (*pivot)[1]});
    if (a.contains("palette") && !a["palette"].is_null()) recipeArgs["palette"] = a["palette"];
    if (style != "none") {
        recipeArgs["style"] = style;
        recipeArgs["styleStrength"] = styleStrength;
    }
    if (a.contains("timeLimitMs")) recipeArgs["timeLimitMs"] = timeLimitMs;
    if (!ai) recipeArgs["ai"] = false;
    if (a.contains("author")) recipeArgs["author"] = author;
    if (a.contains("license")) recipeArgs["license"] = license;
    {
        std::vector<std::string> read;  // the source first (a module, then what it imported), then the palette image
        if (module) read = module->files();
        else if (!sourceRel.empty()) read.push_back(sourceRel);
        inputs.insert(inputs.begin(), read.begin(), read.end());
    }
    const Json recipe = make_recipe(projectDir, kCommand, recipeArgs, inputs);

    const std::string what = isModule ? "module '" + sourceRel + "'" : (sourceRel.empty() ? std::string("SVG text given to the command") : "SVG '" + sourceRel + "'");
    Json provenance = Json::object({{"origin", ai ? "generated" : "original"},
                                    {"ai", ai},
                                    {"kind", "image"},
                                    {"provider", "factoria assets.animate_svg"},
                                    {"license", license},
                                    {"notes", std::format("{} frames of {}x{} baked from {}{}{}.", total, frameW, frameH, what, style == "none" ? std::string() : std::format(", style {} (strength {})", style, styleStrength),
                                                          palette ? ", snapped to a palette" : "")},
                                    {"date", assets::today()},
                                    {"recipe", recipe}});
    if (!author.empty()) provenance["author"] = author;
    if (!sourceRel.empty()) provenance["source"] = sourceRel;
    {
        ProjectRootGuard root(projectDir);
        auto r = assets::update_entry(rel, [&](Json& e) {
            e.erase("analysis");
            e["sheet"] = sheet;
            e["provenance"] = provenance;
        });
        if (!r.ok()) fail("failed", "The sheet was written, but assets.json was not updated: " + r.error().message, r.error().hint);
    }

    Json layout = Json::object({{"columns", columns}, {"rows", rows}, {"frameWidth", frameW}, {"frameHeight", frameH}, {"padding", padding},
                                {"cellWidth", cellW}, {"cellHeight", cellH}, {"imageWidth", sheetImage.width}, {"imageHeight", sheetImage.height},
                                {"frames", total}, {"clips", sheet.value("clips", Json::array())}});
    if (pivot) layout["pivot"] = sheet["pivot"];
    Json result = Json::object({{"path", rel}, {"width", sheetImage.width}, {"height", sheetImage.height}, {"layout", layout}, {"sheet", sheet}, {"provenance", provenance}});
    if (smil && cycle > 0) result["cycleSeconds"] = cycle;
    if (module && !module->logs().empty()) result["console"] = module->logs();
    if (!warnings.empty()) result["warnings"] = warnings;
    result["$image"] = Json::object({{"path", file.string()}, {"mimeType", "image/png"}});
    std::vector<std::string> steps = sheet_next_steps(rel, sheet, hasClips ? clips[0].fps : fps);
    steps.push_back("Look at the sheet in this result. To change the animation, edit " + (isModule ? sourceRel : std::string("the SVG")) + " and call again with overwrite: true, "
                    "or run assets.regenerate {\"path\":\"" + rel + "\"} (the recipe is in the provenance; {\"stale\":true} makes again every asset whose source changed).");
    result["nextSteps"] = steps;
    return result;
}

}  // namespace

void register_animate_svg_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Draw an animation with code (a JS module that returns the SVG of each frame, or an SVG with SMIL) and bake it into a sprite sheet PNG plus its `sheet` entry, offline: no provider, no key.";
    info.description =
        "Writes a sprite sheet at `path` (under assets/, ending in .png) and its `sheet` entry in assets.json in one call, from an animation you write as code. Two ways to draw it. "
        "(1) `source`: a project JavaScript module, e.g. \"art/coin_spin.anim.js\", whose default export is `frame({t, frame, frames, fps, progress, params, rng, seed, rngFor, clip, sheetFrame, width, height}) => string`, "
        "the SVG of that frame. t is the time in seconds (frame / fps); frame counts from 0 inside the clip and frames is the clip's length; progress runs 0..1 through the clip (frame / frames for a looping clip, so the last frame leads into the first; "
        "frame / (frames - 1) for loop false, so the last frame is the end pose); params is the `params` argument (a clip's own params are merged over it); rng() is a seeded random number in 0..1 for this frame "
        "(also rng.range(a, b), rng.int(n), rng.pick(list), rng.chance(p), rng.gauss()), different on every frame; rngFor(key) is a random stream that is the SAME on every frame for one key (a sparkle that stays where it is); clip is the clip name with `clips`. "
        "The module runs in a sandboxed QuickJS context: the language only (Math, JSON, Array...), no engine bindings, no DOM, no timers, no files; it may `import` other project files with a relative path (\"./shapes.js\"). "
        "Math.random is a seeded stream and Date a fixed day moved to the frame's time, so the same module always draws the same frames. Loading and each frame have a time limit (`timeLimitMs`, 2000 by default) and the context a memory limit. "
        "A mistake is reported with the module's file, line and column, the source line, and the frame being drawn; console.log output comes back in `console`. "
        "(2) `svg` (text) or `source` ending in .svg: one SVG with SMIL animation (<animate>, <set>, <animateTransform>, <animateMotion> with values, keyTimes, keySplines, begin, dur, repeatCount, fill=\"freeze\", additive, accumulate and `id.begin` sync-bases), "
        "sampled at t = frame / fps. Without `frames` the sheet takes one pass of the animation (cycle seconds * fps frames). What is not sampled (event begins such as click, CSS animations, the rest of SMIL) is a warning that names the element. "
        "Every frame is rasterized exactly as assets.rasterize_svg does (nanosvg: paths, shapes, gradients, strokes, clipPath, mask, pattern; no text or filters) into a transparent `frameWidth` x `frameHeight` cell (default 64 x 64; the SVG is fitted inside, aspect kept, centred), "
        "then the painterly `style` / `styleStrength` is applied (the style's seed is `seed`, the same for every frame, so the paper texture stays put while the drawing moves) and the pixels are snapped to `palette` (a list of \"#rrggbb\" or an image of the project). "
        "The frames go row by row in a grid of `columns` (default ceil(sqrt(frames))) with a transparent gutter of `padding` pixels around every cell (cell i starts at x = padding + column * (frameWidth + 2 * padding)). "
        "`pivot` ([x, y] in 0..1 from the top-left, default the centre) is recorded in the sheet entry. `clips` makes several named clips from one module: [{name, frames, fps, loop, params, pivot}], laid out one after another in the sheet "
        "(do not also give `frames`); the module receives `clip` and draws that animation; each clip becomes a clip of the sheet entry with its fps and loop. Without `clips` the sheet entry has one clip named like the file, so fps and loop are kept. "
        "The result returns the sheet as an image, the layout (columns, rows, cell size, clips) and warnings: frames that draw nothing, shapes touching the edge of the cell, a loop whose last frame jumps from the first (or repeats it), SMIL not sampled. "
        "Provenance (origin generated, ai true: the calling agent wrote the code; pass ai: false with author and license for art a person drew) carries a recipe (this command, its arguments, the module and the files it imported with their SHA-256), "
        "so the sheet can be made again, byte for byte. Use this for motion that follows rules (spin, bob, pulse, sparkle, flame, waves, loaders); for an engine-drawn entity use assets.bake_sheet, for painted frame-by-frame art ask an image provider. "
        "Example: {\"path\":\"assets/art/coin_spin.png\",\"source\":\"art/coin_spin.anim.js\",\"frames\":8,\"fps\":10,\"frameWidth\":64,\"frameHeight\":64,\"padding\":1} with art/coin_spin.anim.js = "
        "\"export default function frame({progress}) { const w = Math.abs(Math.cos(progress * Math.PI * 2)) * 40; return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><ellipse cx='50' cy='50' rx='${w + 4}' ry='42' fill='#e8c66a' stroke='#8b6a1e' stroke-width='4'/></svg>`; }\"";
    const Json pivotSchema = Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}})}, {"minItems", 2}, {"maxItems", 2}});
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"path"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"path", Json::object({{"type", "string"}, {"description", "Where to write the sheet, project-relative, under assets/ and ending in .png."}})},
               {"source", Json::object({{"type", "string"}, {"description", "A project-relative JavaScript module whose default export draws one frame (\"art/coin_spin.anim.js\"), or an .svg file with SMIL animation. Give this or `svg`."}})},
               {"svg", Json::object({{"type", "string"}, {"description", "One SVG with SMIL animation as text, sampled at every frame. Give this or `source`."}})},
               {"frames", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", kMaxFrames}, {"description", "Number of frames. Required with a module; with SMIL the default is one pass of the animation. Not with `clips` (they give their own)."}})},
               {"fps", Json::object({{"type", "number"}, {"exclusiveMinimum", 0}, {"maximum", 240}, {"default", 12}, {"description", "Frames per second: t = frame / fps, and the fps of the sheet's clip."}})},
               {"loop", Json::object({{"type", "boolean"}, {"default", true}, {"description", "Whether the clip repeats. Decides `progress` (frame / frames when true, frame / (frames - 1) when false) and the loop-jump warning."}})},
               {"columns", Json::object({{"type", "integer"}, {"minimum", 1}, {"description", "Frames per row of the sheet. Default ceil(sqrt(frames))."}})},
               {"frameWidth", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", kMaxCell}, {"default", 64}, {"description", "Width of one frame in pixels; the SVG is fitted inside, aspect kept, centred."}})},
               {"frameHeight", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", kMaxCell}, {"description", "Height of one frame in pixels. Default: frameWidth."}})},
               {"params", Json::object({{"type", "object"}, {"description", "Passed to the module as `params` (colours, counts, amplitudes), so one module serves several sheets."}})},
               {"seed", Json::object({{"type", "integer"}, {"default", 0}, {"description", "Seeds rng, Math.random and rngFor of the module, and the painterly style. The same seed always gives the same sheet."}})},
               {"clips", Json::object({{"type", "array"}, {"description", "Several named clips from one module, laid out one after another: [{name, frames, fps, loop, params, pivot}]. Module only."},
                                       {"items", Json::object({{"type", "object"}, {"additionalProperties", false}, {"required", Json::array({"name", "frames"})},
                                                               {"properties", Json::object({{"name", Json::object({{"type", "string"}, {"description", "The clip's name; the module reads it as `clip`."}})},
                                                                                            {"frames", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", kMaxFrames}, {"description", "Frames of this clip."}})},
                                                                                            {"fps", Json::object({{"type", "number"}, {"description", "Frames per second of this clip. Default: the top-level fps."}})},
                                                                                            {"loop", Json::object({{"type", "boolean"}, {"description", "Whether this clip repeats. Default: the top-level loop."}})},
                                                                                            {"params", Json::object({{"type", "object"}, {"description", "Merged over the top-level params for this clip."}})},
                                                                                            {"pivot", pivotSchema}})}})}})},
               {"pivot", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}})}, {"minItems", 2}, {"maxItems", 2},
                                       {"description", "[x, y] in 0..1 from the top-left of the frame: the point that stays still. Recorded in the sheet entry. Default [0.5, 0.5]."}})},
               {"palette", Json::object({{"description", "Snap every pixel to these colours: a list of \"#rrggbb\" strings, or the project-relative path of an image whose distinct opaque colours are the palette (at most 256). Alpha is kept."}})},
               {"style", Json::object({{"type", "string"}, {"enum", image_style_names()}, {"description", "Default none. The painterly look of assets.rasterize_svg applied to every frame (watercolor, ink, inkwash, paper). The same seed for all frames, so the texture does not boil."}})},
               {"styleStrength", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "How strong the `style` is, 0 to 1 (default 1). Ignored without a `style`."}})},
               {"padding", Json::object({{"type", "integer"}, {"minimum", 0}, {"maximum", 64}, {"default", 0}, {"description", "Transparent pixels around every cell: 1 or 2 keeps filtered frames from bleeding into each other. Recorded in the sheet entry."}})},
               {"timeLimitMs", Json::object({{"type", "integer"}, {"minimum", 10}, {"maximum", 60000}, {"default", 2000}, {"description", "Milliseconds the module may take to load and, separately, to draw each frame; over it the call fails naming the frame."}})},
               {"overwrite", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Replace the sheet when it already exists."}})},
               {"ai", Json::object({{"type", "boolean"}, {"default", true}, {"description", "Whether the code was written by an AI (the default, since the caller is an agent). Set false for art a person made; it then counts as original work in the AI disclosure."}})},
               {"author", Json::object({{"type", "string"}, {"description", "Who gets the credit in the provenance record."}})},
               {"license", Json::object({{"type", "string"}, {"default", "CC0-1.0"}, {"description", "License of the sheet for the provenance record."}})}})}});
    registry.add(info, [projectDir](const Json& args) { return animate(projectDir, args); });
}

}  // namespace fa::assets_detail
