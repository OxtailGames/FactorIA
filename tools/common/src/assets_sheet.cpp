// assets.slice_sheet: makes an image playable by SpriteAnimator (a uniform grid of frames, row-major), by checking the
// grid it already has or by finding the frames of a sheet with transparent gutters and repacking them.
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <format>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr int kAlphaMin = 8;             // a pixel with less alpha is empty: the faint noise around generated sprites
constexpr int kBackgroundTolerance = 6;  // levels per channel a background may vary (JPEG noise)
constexpr int kMaxSide = 16384;

struct Rect {
    int x0 = 0, y0 = 0, x1 = 0, y1 = 0;  // x1, y1 exclusive
    int width() const { return x1 - x0; }
    int height() const { return y1 - y0; }
    bool intersects(const Rect& o) const { return x0 < o.x1 && o.x0 < x1 && y0 < o.y1 && o.y0 < y1; }
    void merge(const Rect& o) {
        x0 = std::min(x0, o.x0);
        y0 = std::min(y0, o.y0);
        x1 = std::max(x1, o.x1);
        y1 = std::max(y1, o.y1);
    }
};

const std::uint8_t* px(const Image& img, int x, int y) { return &img.rgba[(std::size_t(y) * img.width + x) * 4]; }
std::uint8_t* px(Image& img, int x, int y) { return &img.rgba[(std::size_t(y) * img.width + x) * 4]; }

bool near_color(const std::uint8_t* p, const std::array<std::uint8_t, 3>& c) {
    return p[3] == 255 && std::abs(int(p[0]) - c[0]) <= kBackgroundTolerance && std::abs(int(p[1]) - c[1]) <= kBackgroundTolerance &&
           std::abs(int(p[2]) - c[2]) <= kBackgroundTolerance;
}

// Makes the solid background that touches the corners transparent (flood fill: the same colour inside a sprite stays).
// Returns the number of pixels cleared.
std::size_t clear_background(Image& img, const std::array<std::uint8_t, 3>& color) {
    std::vector<int> stack;
    std::size_t cleared = 0;
    auto visit = [&](int x, int y) {
        std::uint8_t* p = px(img, x, y);
        if (!near_color(p, color)) return;
        p[3] = 0;
        ++cleared;
        stack.push_back(y * img.width + x);
    };
    visit(0, 0);
    visit(img.width - 1, 0);
    visit(0, img.height - 1);
    visit(img.width - 1, img.height - 1);
    while (!stack.empty()) {
        const int i = stack.back();
        stack.pop_back();
        const int x = i % img.width, y = i / img.width;
        if (x > 0) visit(x - 1, y);
        if (x + 1 < img.width) visit(x + 1, y);
        if (y > 0) visit(x, y - 1);
        if (y + 1 < img.height) visit(x, y + 1);
    }
    return cleared;
}

// The bounding box of every group of touching (8-connected) non-empty pixels.
std::vector<Rect> find_sprites(const Image& img) {
    const int w = img.width, h = img.height;
    std::vector<std::uint8_t> seen(std::size_t(w) * h, 0);
    std::vector<Rect> found;
    std::vector<int> stack;
    auto solid = [&](int i) { return img.rgba[std::size_t(i) * 4 + 3] >= kAlphaMin; };
    for (int start = 0; start < w * h; ++start) {
        if (seen[start] || !solid(start)) continue;
        Rect r{start % w, start / w, start % w + 1, start / w + 1};
        seen[start] = 1;
        stack.push_back(start);
        while (!stack.empty()) {
            const int i = stack.back();
            stack.pop_back();
            const int x = i % w, y = i / w;
            r.merge({x, y, x + 1, y + 1});
            for (int ny = std::max(0, y - 1); ny <= std::min(h - 1, y + 1); ++ny)
                for (int nx = std::max(0, x - 1); nx <= std::min(w - 1, x + 1); ++nx) {
                    const int j = ny * w + nx;
                    if (seen[j] || !solid(j)) continue;
                    seen[j] = 1;
                    stack.push_back(j);
                }
        }
        found.push_back(r);
    }
    return found;
}

// Sprites whose boxes overlap (both axes) are one frame: a detached spark or a floating eye belongs to its character.
void merge_overlapping(std::vector<Rect>& rects) {
    for (bool merged = true; merged;) {
        merged = false;
        for (std::size_t i = 0; i < rects.size(); ++i)
            for (std::size_t j = i + 1; j < rects.size();) {
                if (rects[i].intersects(rects[j])) {
                    rects[i].merge(rects[j]);
                    rects.erase(rects.begin() + std::ptrdiff_t(j));
                    merged = true;
                } else {
                    ++j;
                }
            }
    }
}

// Rows from the top, left to right inside a row: a sprite joins the current row while it starts above the row's bottom.
std::vector<std::vector<Rect>> group_rows(std::vector<Rect> rects) {
    std::sort(rects.begin(), rects.end(), [](const Rect& a, const Rect& b) { return a.y0 != b.y0 ? a.y0 < b.y0 : a.x0 < b.x0; });
    std::vector<std::vector<Rect>> rows;
    int bottom = 0;
    for (const Rect& r : rects) {
        if (rows.empty() || r.y0 >= bottom) {
            rows.emplace_back();
            bottom = r.y1;
        }
        rows.back().push_back(r);
        bottom = std::max(bottom, r.y1);
    }
    for (auto& row : rows) std::sort(row.begin(), row.end(), [](const Rect& a, const Rect& b) { return a.x0 < b.x0; });
    return rows;
}

std::string divisors_of(int n) {
    std::vector<std::string> shown;
    for (int d = 1; d <= n && shown.size() < 12; ++d)
        if (n % d == 0) shown.push_back(std::to_string(d));
    return join(shown, ", ");
}

struct Grid {
    int columns = 1, rows = 1, frameWidth = 0, frameHeight = 0;
};

}  // namespace

Json sheet_entry(int columns, int rows, int frameWidth, int frameHeight, int frames, const std::vector<SheetClip>& clips,
                 int padding, std::optional<std::array<double, 2>> pivot) {
    Json sheet = Json::object({{"columns", columns}, {"rows", rows}, {"frameWidth", frameWidth},
                               {"frameHeight", frameHeight}, {"frames", frames}});
    if (padding > 0) sheet["padding"] = padding;
    if (pivot) sheet["pivot"] = Json::array({(*pivot)[0], (*pivot)[1]});
    if (!clips.empty()) {
        Json list = Json::array();
        for (const SheetClip& c : clips) {
            Json clip = Json::object({{"name", c.name}, {"firstFrame", c.firstFrame}, {"lastFrame", c.lastFrame},
                                      {"fps", c.fps}, {"loop", c.loop}});
            if (c.pivot) clip["pivot"] = Json::array({(*c.pivot)[0], (*c.pivot)[1]});
            list.push_back(clip);
        }
        sheet["clips"] = list;
    }
    return sheet;
}

std::vector<std::string> sheet_next_steps(const std::string& texture, const Json& sheet, double fps) {
    const int frames = sheet.value("frames", 1);
    std::vector<std::string> steps = {
        std::format("Draw it: a Sprite with \"texture\": \"{}\" (leave region and size empty: SpriteAnimator sets the region, and the "
                    "frame size is the sprite size).", texture),
        std::format("Play all of it: a SpriteAnimator with {{\"columns\": {}, \"rows\": {}, \"firstFrame\": 0, \"lastFrame\": {}, "
                    "\"fps\": {}}}.", sheet.value("columns", 1), sheet.value("rows", 1), frames - 1, fps)};
    if (sheet.contains("clips")) {
        std::string clips;
        for (const Json& c : sheet["clips"])
            clips += std::format("{}{} = firstFrame {}, lastFrame {}, fps {}", clips.empty() ? "" : "; ", c.value("name", ""),
                                 c.value("firstFrame", 0), c.value("lastFrame", 0), c.value("fps", 10.0));
        steps.push_back("Play one clip by setting these SpriteAnimator fields (the `sheet` entry of assets.json keeps them): " + clips + ".");
    }
    return steps;
}

std::optional<std::array<std::uint8_t, 3>> opaque_corner_color(const Image& image) {
    if (image.empty()) return std::nullopt;
    const std::uint8_t* first = px(image, 0, 0);
    const std::array<std::uint8_t, 3> color = {first[0], first[1], first[2]};
    for (const auto& [x, y] : {std::pair{image.width - 1, 0}, std::pair{0, image.height - 1}, std::pair{image.width - 1, image.height - 1}})
        if (!near_color(px(image, x, y), color)) return std::nullopt;
    return near_color(first, color) ? std::optional(color) : std::nullopt;
}

namespace {

// ---- the command ----------------------------------------------------------------------------------------------

Image read_image(const std::string& projectDir, const std::string& rel) {
    const stdfs::path file = project_file(projectDir, rel);
    std::error_code ec;
    if (!stdfs::is_regular_file(file, ec))
        fail("not_found", "'" + rel + "' does not exist.", "Use assets.list to see the images of the project, or assets.import to bring one in.");
    auto image = load_image(file);
    if (!image.ok()) fail("invalid_argument", "'" + rel + "': " + image.error().message, image.error().hint);
    return std::move(*image);
}

// Grid mode: the layout the caller states (columns and rows, or the size of a frame) checked against the image.
Grid resolve_grid(const Image& img, const Json& a) {
    Grid g;
    g.columns = int(tooling_detail::arg_int(a, "columns", 0));
    g.rows = int(tooling_detail::arg_int(a, "rows", 0));
    g.frameWidth = int(tooling_detail::arg_int(a, "frameWidth", 0));
    g.frameHeight = int(tooling_detail::arg_int(a, "frameHeight", 0));
    struct Axis {
        const char* count;  // "columns"
        const char* size;   // "frameWidth"
        const char* side;   // "width"
        int total;          // image pixels along the axis
        int* n;
        int* frame;
    };
    for (const Axis& axis : {Axis{"columns", "frameWidth", "width", img.width, &g.columns, &g.frameWidth},
                             Axis{"rows", "frameHeight", "height", img.height, &g.rows, &g.frameHeight}}) {
        const std::string fix = std::format("Pass {} or {} values that divide {}: {}. Or, when the frames are separated by gutters or "
                                            "have different sizes, pass auto: true.", axis.count, axis.size, axis.total, divisors_of(axis.total));
        if (*axis.frame > 0) {
            if (axis.total % *axis.frame != 0)
                fail("invalid_argument", std::format("{} {} does not divide the image {} ({} px): {} frames fit and {} px are left over.",
                                                     axis.size, *axis.frame, axis.side, axis.total, axis.total / *axis.frame, axis.total % *axis.frame), fix);
            if (*axis.n > 0 && *axis.n != axis.total / *axis.frame)
                fail("invalid_argument", std::format("{} {} and {} {} disagree: the image {} is {} px.", axis.count, *axis.n, axis.size,
                                                     *axis.frame, axis.side, axis.total),
                     std::format("Give only one of {} and {}.", axis.count, axis.size));
            *axis.n = axis.total / *axis.frame;
        } else {
            if (*axis.n == 0) *axis.n = 1;
            if (axis.total % *axis.n != 0)
                fail("invalid_argument", std::format("The image {} is {} px: it cannot be cut into {} {} ({:.1f} px each).", axis.side,
                                                     axis.total, *axis.n, axis.count, double(axis.total) / *axis.n), fix);
            *axis.frame = axis.total / *axis.n;
        }
    }
    return g;
}

// Frames whose cells hold no visible pixel: the sign of a `frames` that is too high or a grid that is wrong.
std::vector<int> empty_frames(const Image& img, const Grid& g, int frames) {
    std::vector<int> empty;
    for (int f = 0; f < frames; ++f) {
        const int ox = (f % g.columns) * g.frameWidth, oy = (f / g.columns) * g.frameHeight;
        bool any = false;
        for (int y = oy; y < oy + g.frameHeight && !any; ++y)
            for (int x = ox; x < ox + g.frameWidth && !any; ++x) any = px(img, x, y)[3] >= kAlphaMin;
        if (!any) empty.push_back(f);
    }
    return empty;
}

std::string list_numbers(const std::vector<int>& v) {
    std::vector<std::string> shown;
    for (std::size_t i = 0; i < v.size() && i < 8; ++i) shown.push_back(std::to_string(v[i]));
    return join(shown, ", ") + (v.size() > 8 ? ", ..." : "");
}

// Auto mode: finds the sprites, repacks them into a uniform grid. Fills `packed`, `rects` (in the source) and the grid.
Grid slice_auto(const Image& img, const Json& a, Image& packed, std::vector<Rect>& rects) {
    rects = find_sprites(img);
    if (rects.empty())
        fail("invalid_argument", "The image has no visible pixel, so there is no sprite to find.",
             "Check that the image is the right one (assets.list); regenerate it if it came out empty.");
    merge_overlapping(rects);
    if (rects.size() == 1 && rects[0].width() == img.width && rects[0].height() == img.height)
        fail("invalid_argument", "The image is one single sprite: there are no transparent gutters between frames to find.",
             "If the frames sit on a solid background pass background: \"auto\" to make it transparent first (or regenerate the "
             "image with transparent: true); if it is a regular grid, pass columns and rows instead of auto.");
    const int expected = int(tooling_detail::arg_int(a, "frames", 0));
    if (expected > 0 && int(rects.size()) != expected) {
        std::string list;
        for (std::size_t i = 0; i < rects.size() && i < 12; ++i)
            list += std::format("{}[x {}, y {}, {}x{}]", list.empty() ? "" : ", ", rects[i].x0, rects[i].y0, rects[i].width(), rects[i].height());
        fail("invalid_argument", std::format("Found {} sprites but frames is {}. Found: {}{}.", rects.size(), expected, list, rects.size() > 12 ? ", ..." : ""),
             rects.size() > size_t(expected)
                 ? "Specks or stray pixels count as sprites; clean the image, or drop `frames` to take what is found."
                 : "Sprites that touch or overlap are one frame; leave a transparent gutter between them, or drop `frames`.");
    }
    auto rows = group_rows(rects);
    rects.clear();
    int cellW = 0, cellH = 0;
    std::size_t widest = 0;
    for (const auto& row : rows) {
        widest = std::max(widest, row.size());
        for (const Rect& r : row) {
            rects.push_back(r);
            cellW = std::max(cellW, r.width());
            cellH = std::max(cellH, r.height());
        }
    }
    Grid g;
    const int wanted = int(tooling_detail::arg_int(a, "columns", 0));
    g.columns = std::min(int(rects.size()), wanted > 0 ? wanted : int(widest));
    g.rows = (int(rects.size()) + g.columns - 1) / g.columns;
    g.frameWidth = cellW;
    g.frameHeight = cellH;
    if (std::size_t(g.columns) * cellW > kMaxSide || std::size_t(g.rows) * cellH > kMaxSide)
        fail("invalid_argument", std::format("The repacked sheet would be {}x{} px ({} frames of {}x{}), more than the {} px a texture can have.",
                                             g.columns * cellW, g.rows * cellH, rects.size(), cellW, cellH, kMaxSide),
             "The largest sprite sets the frame size: remove an oversized sprite, or scale the image down first.");
    const bool bottom = a.value("align", std::string("center")) == "bottom";
    packed.width = g.columns * cellW;
    packed.height = g.rows * cellH;
    packed.rgba.assign(std::size_t(packed.width) * packed.height * 4, 0);
    for (std::size_t i = 0; i < rects.size(); ++i) {
        const Rect& r = rects[i];
        const int ox = int(i) % g.columns * cellW + (cellW - r.width()) / 2;
        const int oy = int(i) / g.columns * cellH + (bottom ? cellH - r.height() : (cellH - r.height()) / 2);
        for (int y = 0; y < r.height(); ++y)
            std::copy_n(px(img, r.x0, r.y0 + y), std::size_t(r.width()) * 4, px(packed, ox, oy + y));
    }
    return g;
}

Json slice_sheet(const std::string& projectDir, const Json& a) {
    const std::string pathArg = tooling_detail::arg_string(a, "path", true);
    auto path = fs::normalize_checked(pathArg);
    if (!path.ok() || path->empty()) fail("invalid_argument", "Invalid path '" + pathArg + "'.", "Use a project-relative path such as \"assets/hero.png\".");
    const bool autoMode = tooling_detail::arg_bool(a, "auto", false);
    const std::string background = a.value("background", std::string("none"));
    if (autoMode && (a.contains("rows") || a.contains("frameWidth") || a.contains("frameHeight")))
        fail("invalid_argument", "`rows`, `frameWidth` and `frameHeight` describe a grid; auto: true finds the frames itself.",
             "Drop them, or drop auto. `columns` and `frames` (the number of sprites you expect) are allowed with auto.");
    require_usable_manifest(projectDir);

    Image image = read_image(projectDir, *path);
    Json warnings = Json::array();
    std::size_t cleared = 0;
    bool changed = false;
    if (background == "auto") {
        if (auto color = opaque_corner_color(image)) {
            cleared = clear_background(image, *color);
            changed = true;
        } else if (px(image, 0, 0)[3] != 0 || px(image, image.width - 1, 0)[3] != 0) {
            fail("invalid_argument", "background \"auto\" needs the four corners of the image to be the same opaque colour, and they are not.",
                 "Remove the background in an image editor, or regenerate the image with transparent: true. A plain white or "
                 "green-screen background must be the same colour in all four corners.");
        } else {
            warnings.push_back("The corners are already transparent: the background was left as it is.");
        }
    }

    Grid grid;
    Image packed;
    std::vector<Rect> rects;
    if (autoMode) {
        grid = slice_auto(image, a, packed, rects);
        changed = true;
    } else {
        grid = resolve_grid(image, a);
    }
    const Image& sheetImage = autoMode ? packed : image;
    const int available = grid.columns * grid.rows;
    const int frames = autoMode ? int(rects.size()) : int(tooling_detail::arg_int(a, "frames", available));
    if (frames < 1 || frames > available)
        fail("invalid_argument", std::format("frames is {} but a {} x {} grid has {} cells.", frames, grid.columns, grid.rows, available),
             "frames counts the used cells, row by row from the top-left: 1.." + std::to_string(available) + ".");
    if (!autoMode)
        if (auto empty = empty_frames(image, grid, frames); !empty.empty())
            warnings.push_back(std::format("{} of the {} frames are empty (frames {}): the grid or `frames` may be wrong.", empty.size(), frames, list_numbers(empty)));
    if (std::max(sheetImage.width, sheetImage.height) > 4096)
        warnings.push_back(std::format("The sheet is {}x{} px; many mobile GPUs cannot sample a texture over 4096 px.", sheetImage.width, sheetImage.height));

    // Where the sheet is: the image itself, or a new PNG when the pixels changed (or `out` asks for one).
    std::string target = *path;
    if (changed || a.contains("out")) {
        const std::string defaultOut = (stdfs::path(*path).parent_path() / (stdfs::path(*path).stem().string() + "_sheet.png")).generic_string();
        auto out = fs::normalize_checked(tooling_detail::arg_string(a, "out", false, defaultOut));
        if (!out.ok() || out->empty() || to_lower(fs::extension(*out)) != ".png")
            fail("invalid_argument", "`out` must be a project-relative .png path.", "For example \"assets/hero_sheet.png\".");
        if (auto w = fs::check_writable(*out); !w.ok()) fail("invalid_argument", w.error().message, w.error().hint);
        const auto png = encode_png(sheetImage);
        std::string err;
        if (!tooling_detail::write_file(project_file(projectDir, *out), std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err))
            fail("failed", err);
        target = *out;
    }

    const Json sheet = sheet_entry(grid.columns, grid.rows, grid.frameWidth, grid.frameHeight, frames, {});
    {
        ProjectRootGuard root(projectDir);
        const Json provenance = target == *path ? Json() : assets::entry(*path).value("provenance", Json());
        // The recipe of a new PNG: slicing `path` again gives it back. Nothing is recorded when no file is made (the grid is only
        // written to assets.json) or when the PNG replaces the image it was cut from: that source is gone, and slicing the result
        // again would not give the same pixels.
        Json recipe;
        if (target == *path) {
            if (changed || a.contains("out"))
                warnings.push_back("'" + *path + "' was replaced by its own sliced version, so no recipe was recorded (the original image is gone). Slice into another file with `out` to keep it regenerable.");
        } else if (provenance.is_object()) {
            Json args = recipe_args(a, {{"path", *path}, {"out", target}});
            if (args.contains("fps")) args.erase("fps");  // only the result's SpriteAnimator fields use it
            recipe = make_recipe(projectDir, "assets.slice_sheet", std::move(args), {*path});
        } else {
            warnings.push_back("'" + *path + "' has no provenance record, so '" + target + "' got none and no recipe. Record where it came from with assets.set_provenance and slice again.");
        }
        const bool replaced = target == *path && (changed || a.contains("out"));
        auto r = assets::update_entry(target, [&](Json& e) {
            e["sheet"] = sheet;
            // The file is now this sliced version: the recipe that made the original no longer gives these bytes.
            if (replaced && e.contains("provenance") && e["provenance"].is_object()) e["provenance"].erase("recipe");
            if (!provenance.is_null()) {
                Json copy = provenance;
                const std::string note = "Sliced from " + *path + " by assets.slice_sheet.";
                copy["notes"] = copy.contains("notes") ? Json(copy["notes"].get<std::string>() + " " + note) : Json(note);
                copy.erase("recipe");  // the source's own recipe made the source, not this sheet
                if (!recipe.is_null()) copy["recipe"] = recipe;
                e["provenance"] = copy;
            }
        });
        if (!r.ok()) fail("failed", r.error().message, r.error().hint);
    }

    const double fps = a.value("fps", 10.0);
    Json result = Json::object({{"path", target}, {"mode", autoMode ? "auto" : "grid"}, {"written", target != *path},
                                {"imageSize", Json::array({sheetImage.width, sheetImage.height})}, {"sheet", sheet},
                                {"spriteAnimator", Json::object({{"columns", grid.columns}, {"rows", grid.rows}, {"firstFrame", 0},
                                                                 {"lastFrame", frames - 1}, {"fps", fps}, {"loop", true}})}});
    if (autoMode) {
        Json found = Json::array();
        for (std::size_t i = 0; i < rects.size() && i < 64; ++i)
            found.push_back(Json::array({rects[i].x0, rects[i].y0, rects[i].width(), rects[i].height()}));
        result["foundSprites"] = found;  // [x, y, w, h] in the source image, in frame order
    }
    if (cleared > 0) result["backgroundPixelsCleared"] = cleared;
    if (!warnings.empty()) result["warnings"] = warnings;
    result["nextSteps"] = sheet_next_steps(target, sheet, fps);
    return result;
}

}  // namespace

void register_slice_sheet_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "assets.slice_sheet";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Make an image playable by SpriteAnimator: check its frame grid, or find the frames of an uneven sheet and repack them.";
    info.description =
        "SpriteAnimator plays a uniform grid of frames (columns x rows, row-major from the top-left). Two ways to get one:\n"
        "1. The image already is a grid: give columns/rows (or frameWidth/frameHeight). The grid is checked against the image "
        "size (a width that columns does not divide is an error that lists the columns that fit) and recorded as the `sheet` of "
        "the image in assets.json. Example: {\"path\":\"assets/hero.png\",\"columns\":4,\"rows\":2,\"fps\":12}.\n"
        "2. Frames separated by transparent gutters and of uneven sizes, as AI-generated and downloaded sheets often are: pass "
        "auto: true. Every group of touching pixels is a sprite (sprites whose boxes overlap are one frame), ordered by rows then "
        "columns, and repacked into a uniform grid of the largest sprite's size, each centred (align \"bottom\" stands characters "
        "on the same ground line). The new PNG is `out` (default <name>_sheet.png next to the image; the source is kept). "
        "`frames` is the number of sprites you expect: a different count is an error that lists what was found. Example: "
        "{\"path\":\"assets/hero_raw.png\",\"auto\":true,\"frames\":8,\"align\":\"bottom\",\"background\":\"auto\"}.\n"
        "background \"auto\" first makes a solid background transparent (the four corners must be the same opaque colour; the "
        "background that touches them is cleared, the same colour inside a sprite stays), also for a grid. The result has the "
        "`sheet`, the SpriteAnimator fields and the Sprite texture to use. Aseprite files need no slicing: assets.import reads "
        "their frames and tags.";
    info.inputSchema = Json::parse(R"({
      "type":"object","required":["path"],
      "properties":{
        "path":{"type":"string","description":"Project-relative image (png, jpg, tga, bmp), e.g. \"assets/hero.png\"."},
        "columns":{"type":"integer","minimum":1,"description":"Grid mode: frames per row (1 if neither columns nor frameWidth is given). With auto: frames per row of the new sheet (default: the most sprites found in one row)."},
        "rows":{"type":"integer","minimum":1,"description":"Grid mode: number of rows (1 if neither rows nor frameHeight is given)."},
        "frameWidth":{"type":"integer","minimum":1,"description":"Grid mode: width of a frame in pixels, instead of columns."},
        "frameHeight":{"type":"integer","minimum":1,"description":"Grid mode: height of a frame in pixels, instead of rows."},
        "frames":{"type":"integer","minimum":1,"description":"Grid mode: how many cells are used, row by row (default all; the last row may be partly empty). With auto: the number of sprites you expect (a different count is an error)."},
        "fps":{"type":"number","minimum":0,"maximum":1000,"description":"Playback speed to put in the SpriteAnimator fields of the result (default 10). Not stored in assets.json."},
        "auto":{"type":"boolean","description":"Find the frames (groups of touching pixels separated by transparent gutters) and repack them into a uniform grid. Default false."},
        "align":{"type":"string","enum":["center","bottom"],"description":"auto only: where a sprite sits in its cell. center (default), or bottom: centred horizontally with feet on the cell's bottom edge, for characters standing on the ground."},
        "background":{"type":"string","enum":["none","auto"],"description":"auto: first make the solid background (the four corners the same opaque colour) transparent. Default none."},
        "out":{"type":"string","description":"PNG to write when the pixels change (auto, background) or when given: default <name>_sheet.png next to the image. An existing file is replaced; use the image's own path to change it in place."}
      }})");
    registry.add(info, [projectDir](const Json& args) { return slice_sheet(projectDir, args); });
}

}  // namespace fa::assets_detail
