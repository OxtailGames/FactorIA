// assets.preview_sheet: look at a sprite sheet the way the game will play it. Cuts the frames out of the PNG with the grid
// of its `sheet` entry (or the grid the caller states), draws them in a labelled contact sheet with the frame number, the cell
// edges and the pivot, optionally with the neighbour frames as an onion skin, and checks the frames: empty frames, shapes cut
// by the cell edge, a bounding box that jumps between frames, a loop whose seam shows, a grid that does not match the image.
// The checks are those of assets.animate_svg (sheet_checks.h), so a sheet from assets.animate_svg, assets.bake_sheet,
// assets.slice_sheet, an Aseprite import or drawn by hand is judged the same way. The picture is a temporary screenshot.
#include <algorithm>
#include <atomic>
#include <cmath>
#include <format>

#include "assets_internal.h"
#include "sheet_checks.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/image_tools.h"
#include "fa/core/screenshot_files.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kCommand = "assets.preview_sheet";

struct Rgb {
    std::uint8_t r, g, b;
};

void blend(Image& dst, int x, int y, Rgb c, double alpha) {
    if (x < 0 || y < 0 || x >= dst.width || y >= dst.height || alpha <= 0) return;
    std::uint8_t* p = &dst.rgba[(std::size_t(y) * dst.width + x) * 4];
    p[0] = std::uint8_t(p[0] + (c.r - p[0]) * alpha);
    p[1] = std::uint8_t(p[1] + (c.g - p[1]) * alpha);
    p[2] = std::uint8_t(p[2] + (c.b - p[2]) * alpha);
    p[3] = 255;
}

// `cell` (already magnified) over `dst`, each pixel with its own alpha times `opacity`; `tint` replaces its colour.
void composite(Image& dst, const Image& cell, double opacity, const Rgb* tint) {
    for (int y = 0; y < cell.height && y < dst.height; ++y)
        for (int x = 0; x < cell.width && x < dst.width; ++x) {
            const std::uint8_t* s = &cell.rgba[(std::size_t(y) * cell.width + x) * 4];
            const Rgb c = tint ? *tint : Rgb{s[0], s[1], s[2]};
            blend(dst, x, y, c, s[3] / 255.0 * opacity);
        }
}

void hline(Image& im, int x0, int x1, int y, Rgb c) {
    for (int x = x0; x <= x1; ++x) blend(im, x, y, c, 1);
}
void vline(Image& im, int x, int y0, int y1, Rgb c) {
    for (int y = y0; y <= y1; ++y) blend(im, x, y, c, 1);
}
void rect_outline(Image& im, int x0, int y0, int x1, int y1, Rgb c) {
    hline(im, x0, x1, y0, c);
    hline(im, x0, x1, y1, c);
    vline(im, x0, y0, y1, c);
    vline(im, x1, y0, y1, c);
}

struct Pivot {
    float x = 0.5f, y = 0.5f;  // 0..1 from the top-left of the frame
    bool recorded = false;
};

stdfs::path next_preview_file(const std::string& projectDir) {
    static std::atomic<int> counter{0};
    const stdfs::path dir = project_file(projectDir, kScreenshotDir);
    std::error_code ec;
    for (;;) {
        const int n = ++counter;
        const stdfs::path file = dir / std::format("frame_{}_sheet.png", n);
        if (!stdfs::exists(file, ec)) return file;
    }
}

Json preview(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "assets.preview_sheet expects an object.", "Pass {\"path\": \"assets/hero.png\"}.");
    check_arg_keys(kCommand, a, "", {"path", "clip", "onion", "scale", "columns", "rows", "frameWidth", "frameHeight", "padding", "tileColumns"});
    const std::string rel = tooling_detail::arg_string(a, "path", true);
    const stdfs::path imageFile = project_file(projectDir, rel);
    std::error_code ec;
    if (!stdfs::is_regular_file(imageFile, ec))
        fail("not_found", "'" + rel + "' does not exist.", "Use assets.list to see the images of the project.");
    auto loaded = load_image(imageFile);
    if (!loaded.ok()) fail("invalid_argument", "'" + rel + "': " + loaded.error().message, loaded.error().hint);
    const Image& img = *loaded;

    std::shared_ptr<const assets::Sheet> entry;
    {
        ProjectRootGuard root(projectDir);
        entry = assets::sheet(rel);
    }
    std::vector<std::string> warnings;

    // ---- the grid: the explicit arguments, else the `sheet` entry ----
    auto stated = [&](const char* key) { return int(tooling_detail::arg_int(a, key, 0)); };
    int columns = stated("columns"), rows = stated("rows"), frameW = stated("frameWidth"), frameH = stated("frameHeight");
    int padding = a.contains("padding") ? stated("padding") : -1;
    if (entry) {
        if (columns == 0) columns = entry->columns;
        if (rows == 0) rows = entry->rows;
        if (frameW == 0) frameW = entry->frameWidth;
        if (frameH == 0) frameH = entry->frameHeight;
        if (padding < 0) padding = entry->padding;
    }
    padding = std::max(0, padding);
    if (!entry && columns == 0 && rows == 0 && frameW == 0 && frameH == 0)
        fail("no_grid", "'" + rel + "' has no `sheet` entry in assets.json, and the grid was not given.",
             "Pass columns and rows (or frameWidth and frameHeight), e.g. {\"path\": \"" + rel + "\", \"columns\": 4, \"rows\": 2}; "
             "or record the sheet with assets.slice_sheet, assets.animate_svg or assets.bake_sheet.");
    if (columns <= 0 && frameW > 0) columns = std::max(1, img.width / (frameW + 2 * padding));
    if (rows <= 0 && frameH > 0) rows = std::max(1, img.height / (frameH + 2 * padding));
    columns = std::max(1, columns);
    rows = std::max(1, rows);
    const bool recordedSize = frameW > 0 && frameH > 0;
    if (frameW <= 0) frameW = img.width / columns - 2 * padding;
    if (frameH <= 0) frameH = img.height / rows - 2 * padding;
    if (frameW < 1 || frameH < 1)
        fail("invalid_argument", std::format("The grid {}x{} with padding {} leaves no room for a frame in the {}x{} image.", columns, rows, padding, img.width, img.height),
             "Use fewer columns/rows or a smaller padding. The image is " + std::to_string(img.width) + "x" + std::to_string(img.height) + " px.");
    const int cellW = frameW + 2 * padding, cellH = frameH + 2 * padding;
    if (columns * cellW != img.width || rows * cellH != img.height) {
        warnings.push_back(std::format(
            "The grid does not match the image: {} columns x {} rows of {}x{} cells (frame {}x{} + padding {}) is {}x{} px, but the image is {}x{} px. "
            "The frames shown may be cut at the wrong place. {}",
            columns, rows, cellW, cellH, frameW, frameH, padding, columns * cellW, rows * cellH, img.width, img.height,
            entry ? "Fix the `sheet` entry of assets.json (columns, rows, frameWidth, frameHeight, padding) or paint the sheet again."
                  : "Give columns, rows and padding that fit the image."));
        if (!recordedSize) warnings.back() += " (The frame size was derived from the image: it is not recorded.)";
    }
    const int capacity = columns * rows;
    int frames = entry && entry->frames > 0 ? entry->frames : capacity;
    if (frames > capacity) {
        warnings.push_back(std::format("The sheet entry says {} frames but a {}x{} grid holds {}: the frames past {} are not drawn.", frames, columns, rows, capacity, capacity - 1));
        frames = capacity;
    }

    // ---- which frames ----
    const std::string clipName = tooling_detail::arg_string(a, "clip", false);
    struct Span {
        std::string name;
        int first = 0, last = 0;
        bool loop = true;
        Pivot pivot;
    };
    Pivot sheetPivot;
    if (entry && entry->pivot) sheetPivot = {(*entry->pivot)[0], (*entry->pivot)[1], true};
    std::vector<Span> spans;  // the clips shown
    if (!clipName.empty()) {
        const assets::SheetClip* clip = entry ? entry->find(clipName) : nullptr;
        if (!clip) {
            const std::vector<std::string> names = entry ? entry->clip_names() : std::vector<std::string>{};
            fail("unknown_clip", std::format("'{}' has no clip \"{}\".", rel, clipName),
                 names.empty() ? "The sheet has no clips recorded; drop `clip` to see all the frames."
                               : "Its clips: " + [&] { std::string s; for (const auto& n : names) s += (s.empty() ? "" : ", ") + n; return s; }() + "." + did_you_mean(clipName, names));
        }
        Span s{clip->name, clip->firstFrame, clip->lastFrame, clip->loop, sheetPivot};
        if (clip->pivot) s.pivot = {(*clip->pivot)[0], (*clip->pivot)[1], true};
        spans.push_back(s);
    } else if (entry && !entry->clips.empty()) {
        for (const assets::SheetClip& c : entry->clips) {
            Span s{c.name, c.firstFrame, c.lastFrame, c.loop, sheetPivot};
            if (c.pivot) s.pivot = {(*c.pivot)[0], (*c.pivot)[1], true};
            spans.push_back(s);
        }
    } else {
        spans.push_back(Span{"", 0, frames - 1, true, sheetPivot});
    }
    // Frames to draw, in order, each with the span it belongs to (a frame in two clips is drawn once, for the first).
    std::vector<int> shown;
    std::vector<std::size_t> owner;
    for (std::size_t si = 0; si < spans.size(); ++si) {
        Span& s = spans[si];
        if (s.last >= frames || s.first > s.last || s.first < 0) {
            warnings.push_back(std::format("Clip \"{}\" runs from frame {} to {}, but the sheet has {} frames (0..{}): the part outside is not drawn.", s.name, s.first, s.last, frames, frames - 1));
            s.first = std::clamp(s.first, 0, frames - 1);
            s.last = std::clamp(s.last, s.first, frames - 1);
        }
        for (int f = s.first; f <= s.last; ++f)
            if (std::find(shown.begin(), shown.end(), f) == shown.end()) {
                shown.push_back(f);
                owner.push_back(si);
            }
    }
    if (shown.empty()) fail("invalid_argument", "The sheet has no frames to show.", "Check `frames` and the clips of its `sheet` entry.");

    auto cell_of = [&](int frame) {
        const int col = frame % columns, row = frame / columns;
        return crop_image(img, padding + col * cellW - padding, padding + row * cellH - padding, cellW, cellH);
    };
    auto frame_of = [&](int frame) {
        const int col = frame % columns, row = frame / columns;
        return crop_image(img, padding + col * cellW, padding + row * cellH, frameW, frameH);
    };

    // ---- checks ----
    std::vector<std::string> emptyFrames, edgeFrames, jumpFrames;
    std::vector<InkBox> boxes(static_cast<std::size_t>(frames));
    std::vector<bool> checked(static_cast<std::size_t>(frames), false);
    for (int f : shown) {
        const Image fr = frame_of(f);
        boxes[std::size_t(f)] = ink_box(fr);
        checked[std::size_t(f)] = true;
        if (picture_is_empty(fr)) emptyFrames.push_back(std::to_string(f));
        else if (touches_edge(fr)) edgeFrames.push_back(std::to_string(f));
    }
    if (!emptyFrames.empty())
        warnings.push_back(std::format("{} of the {} frames shown draw nothing (frame {}): an empty cell, or the grid is cut at the wrong place.", emptyFrames.size(), shown.size(), list_frames(emptyFrames)));
    if (!edgeFrames.empty())
        warnings.push_back(std::format("Shapes touch the edge of the cell in {} frame(s) (frame {}): they may be cut off. Redraw them smaller inside the cell, make frameWidth/frameHeight larger, or add `padding`.", edgeFrames.size(), list_frames(edgeFrames)));
    for (const Span& s : spans) {
        for (int f = s.first + 1; f <= s.last; ++f) {
            const InkBox &p = boxes[std::size_t(f - 1)], &q = boxes[std::size_t(f)];
            if (!checked[std::size_t(f)] || !checked[std::size_t(f - 1)] || p.empty || q.empty) continue;
            const double dx = std::abs((p.x0 + p.x1) - (q.x0 + q.x1)) / 2.0, dy = std::abs((p.y0 + p.y1) - (q.y0 + q.y1)) / 2.0;
            if (dx > 0.3 * frameW || dy > 0.3 * frameH) jumpFrames.push_back(std::to_string(f));
        }
        if (s.loop && s.last - s.first + 1 >= 3) {
            std::vector<Image> pics;
            for (int f = s.first; f <= s.last; ++f) pics.push_back(frame_of(f));
            std::vector<const Image*> ptrs;
            for (const Image& p : pics) ptrs.push_back(&p);
            if (auto w = loop_seam_warning(ptrs, s.name.empty() ? std::string() : " of clip \"" + s.name + "\"")) warnings.push_back(*w);
        }
    }
    if (!jumpFrames.empty())
        warnings.push_back(std::format("The drawing jumps between frames: its bounding box moves by more than 30% of the frame from the previous one in frame {}. "
                                       "Keep the subject in place in the cell (move it with the Transform, not inside the sheet), or the frames are not aligned.", list_frames(jumpFrames)));

    // ---- the picture ----
    const bool onion = tooling_detail::arg_bool(a, "onion", false);
    int scale = int(tooling_detail::arg_int(a, "scale", 0));
    if (scale <= 0) scale = std::clamp(160 / std::max(cellW, cellH), 1, 8);
    scale = std::clamp(scale, 1, 16);
    int tileColumns = int(tooling_detail::arg_int(a, "tileColumns", 0));
    if (tileColumns <= 0 && spans.size() == 1 && clipName.empty()) tileColumns = std::min(columns, int(shown.size()));
    while (scale > 1) {  // keep the picture small enough to be sent to a model
        const SheetLayout l = sheet_layout(int(shown.size()), tileColumns, cellW * scale, cellH * scale);
        if (l.width <= 2048 && l.height <= 2048) break;
        --scale;
    }
    const Rgb frameEdge{0, 220, 255}, cellEdge{110, 110, 120}, pivotMark{255, 60, 200};
    const Rgb red{255, 70, 70}, blue{70, 130, 255};
    std::vector<Image> tiles;
    std::vector<std::string> labels;
    for (std::size_t i = 0; i < shown.size(); ++i) {
        const int f = shown[i];
        Image tile;
        tile.width = cellW * scale;
        tile.height = cellH * scale;
        tile.rgba.resize(std::size_t(tile.width) * tile.height * 4);
        for (int y = 0; y < tile.height; ++y)
            for (int x = 0; x < tile.width; ++x) {
                const bool light = ((x / 8) + (y / 8)) % 2 == 0;
                std::uint8_t* p = &tile.rgba[(std::size_t(y) * tile.width + x) * 4];
                p[0] = p[1] = std::uint8_t(light ? 74 : 58);
                p[2] = std::uint8_t(light ? 80 : 64);
                p[3] = 255;
            }
        const Span& span = spans[owner[i]];
        if (onion) {
            if (f > span.first) composite(tile, resize_nearest(cell_of(f - 1), tile.width, tile.height), 0.4, &red);
            if (f < span.last) composite(tile, resize_nearest(cell_of(f + 1), tile.width, tile.height), 0.4, &blue);
        }
        composite(tile, resize_nearest(cell_of(f), tile.width, tile.height), 1.0, nullptr);
        if (padding > 0) rect_outline(tile, 0, 0, tile.width - 1, tile.height - 1, cellEdge);
        rect_outline(tile, padding * scale, padding * scale, (padding + frameW) * scale - 1, (padding + frameH) * scale - 1, frameEdge);
        const int px = int((padding + span.pivot.x * frameW) * scale), py = int((padding + span.pivot.y * frameH) * scale);
        const int arm = std::max(4, scale * 2);
        hline(tile, px - arm, px + arm, std::clamp(py, 0, tile.height - 1), pivotMark);
        vline(tile, std::clamp(px, 0, tile.width - 1), py - arm, py + arm, pivotMark);
        tiles.push_back(std::move(tile));
        labels.push_back("f" + std::to_string(f));
    }
    SheetLayout layout;
    const Image sheetPicture = contact_sheet(tiles, labels, tileColumns, -1, &layout);
    const stdfs::path out = next_preview_file(projectDir);
    const std::vector<std::uint8_t> png = encode_png(sheetPicture);
    std::string err;
    if (!tooling_detail::write_file(out, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err)) fail("failed", err);

    // ---- the result ----
    Json frameInfo = Json::array();
    for (int f : shown) {
        const InkBox& b = boxes[std::size_t(f)];
        Json j = Json::object({{"frame", f}, {"empty", b.empty}});
        if (!b.empty) j["bbox"] = Json::array({b.x0, b.y0, b.width(), b.height()});
        frameInfo.push_back(j);
    }
    Json clipsJson = Json::array();
    for (const Span& s : spans) {
        if (s.name.empty()) continue;
        Json c = Json::object({{"name", s.name}, {"firstFrame", s.first}, {"lastFrame", s.last}, {"loop", s.loop}});
        c["pivot"] = Json::array({s.pivot.x, s.pivot.y});
        clipsJson.push_back(c);
    }
    Json result = Json::object(
        {{"path", rel},
         {"grid", Json::object({{"columns", columns}, {"rows", rows}, {"frameWidth", frameW}, {"frameHeight", frameH}, {"padding", padding}, {"cellWidth", cellW}, {"cellHeight", cellH},
                                {"imageWidth", img.width}, {"imageHeight", img.height}, {"frames", frames}, {"fromSheetEntry", bool(entry)}})},
         {"shownFrames", int(shown.size())},
         {"pivot", Json::array({sheetPivot.x, sheetPivot.y})},
         {"frames", frameInfo},
         {"scale", scale},
         {"picture", Json::object({{"width", sheetPicture.width}, {"height", sheetPicture.height}, {"tileColumns", layout.columns}})}});
    if (!clipsJson.empty()) result["clips"] = clipsJson;
    if (!clipName.empty()) result["clip"] = clipName;
    result["warnings"] = warnings;
    std::vector<std::string> steps;
    steps.push_back("Read the picture: each tile is a frame with its number (f<n>); the cyan rectangle is the frame, a grey one around it is the padding gutter, the magenta cross is the pivot "
                    "([x, y] from the top-left; Sprite.pivot is from the bottom-left, so the engine uses [x, 1 - y]).");
    if (!onion) steps.push_back("Pass onion: true to see each frame over the previous one (red) and the next one (blue): motion that is too big or not aligned shows as a gap.");
    if (!entry) steps.push_back("The sheet has no `sheet` entry, so a SpriteAnimator would need columns, rows, firstFrame, lastFrame and fps by hand; assets.slice_sheet can record the grid with clips.");
    else if (entry->clips.empty() == false && clipName.empty())
        steps.push_back("Look at one clip alone with {\"clip\": \"" + entry->clips.front().name + "\"}.");
    if (!warnings.empty()) steps.push_back("Fix the warnings, then preview again; assets.animate_svg or assets.bake_sheet draw the sheet again with overwrite: true.");
    result["nextSteps"] = steps;
    result["$image"] = Json::object({{"path", out.string()}, {"mimeType", "image/png"}, {"temporary", true}});
    return result;
}

}  // namespace

void register_preview_sheet_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = true;
    info.summary = "Look at a sprite sheet the way the game plays it: a labelled grid of its frames (numbers, cell edges, pivot, optional onion skin) plus checks for empty, cut or jumping frames and a loop seam.";
    info.description =
        "Cuts the frames of the sheet at `path` with the grid of its `sheet` entry in assets.json (columns, rows, frameWidth, frameHeight, padding, frames; or the grid you pass), and returns a picture: every frame in a tile with its number "
        "(f<n>), a cyan rectangle for the frame, a grey one for the padding gutter around it and a magenta cross for the pivot (the clip's pivot, else the sheet's, else the centre; [x, y] from the top-left). "
        "`clip` shows one clip of the sheet; without it all the clips (or all the frames). `onion: true` draws the previous frame in red and the next in blue under the current one. "
        "It also checks the frames and returns `warnings` for: frames that draw nothing, shapes touching the edge of the cell (cut off), a bounding box that jumps by more than 30% of the frame between consecutive frames, a looping clip whose last frame jumps from the first or repeats it, and a grid that does not match the image size. "
        "The checks are the same for a sheet from assets.animate_svg, assets.bake_sheet, assets.slice_sheet or an Aseprite import, or one drawn by hand. The picture is a temporary screenshot in .factoria/screenshots. "
        "A wrong `clip` fails listing the clips of the sheet with a \"did you mean\". Example: {\"path\":\"assets/hero.png\",\"clip\":\"walk\",\"onion\":true}.";
    auto integer = [](const char* what, int minimum, int maximum) {
        return Json::object({{"type", "integer"}, {"minimum", minimum}, {"maximum", maximum}, {"description", what}});
    };
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"path"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"path", Json::object({{"type", "string"}, {"description", "Project-relative path of the sprite sheet image."}})},
               {"clip", Json::object({{"type", "string"}, {"description", "Show only this clip of the sheet entry (its frames, loop seam and pivot). Default: all the clips, or all the frames."}})},
               {"onion", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Draw the previous frame in red and the next one in blue under each frame (onion skin)."}})},
               {"scale", integer("Magnification of each frame (whole numbers, nearest-neighbour). Default: enough for about 160 px per tile.", 1, 16)},
               {"tileColumns", integer("Tiles per row of the picture. Default: the sheet's columns for the whole sheet, else the closest to a square.", 1, 64)},
               {"columns", integer("The grid when the sheet has no `sheet` entry (or to override it): frames per row.", 1, 1024)},
               {"rows", integer("The grid when the sheet has no `sheet` entry (or to override it): rows.", 1, 1024)},
               {"frameWidth", integer("Width of one frame in pixels, when it is not recorded. Default: the image divided by the grid.", 1, 8192)},
               {"frameHeight", integer("Height of one frame in pixels, when it is not recorded. Default: the image divided by the grid.", 1, 8192)},
               {"padding", integer("Transparent gutter around each cell, in pixels (cell i starts at padding + column * (frameWidth + 2 * padding)). Default: the sheet entry's, else 0.", 0, 64)}})}});
    registry.add(info, [projectDir](const Json& args) { return preview(projectDir, args); });
}

}  // namespace fa::assets_detail
