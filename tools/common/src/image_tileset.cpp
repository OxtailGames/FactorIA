// The tileset generator (fa/tooling/image_tileset.h): parts -> the tiles of a 16 or 47 autotile set.
#include "fa/tooling/image_tileset.h"

#include <algorithm>
#include <format>
#include <map>
#include <set>

#include "fa/scene/autotile.h"

namespace fa {

namespace {

const std::vector<std::string> kParts = {"inside",        "edge",          "corner",       "innerCorner", "edgeBottom",
                                         "edgeLeft",      "edgeRight",     "cornerNE",     "cornerSE",    "cornerSW",
                                         "innerCornerNE", "innerCornerSE", "innerCornerSW"};

AutotileMode mode_of(const TilesetSpec& spec) {
    AutotileMode m = AutotileMode::Blob47;
    autotile_mode_from_name(spec.mode, m);
    return m;
}

// ---- tile transforms -----------------------------------------------------------------------------------------------------------

Image flipped(const Image& src, bool horizontal, bool vertical) {
    Image out = src;
    for (int y = 0; y < src.height; ++y)
        for (int x = 0; x < src.width; ++x) {
            const int sx = horizontal ? src.width - 1 - x : x, sy = vertical ? src.height - 1 - y : y;
            std::copy_n(&src.rgba[(std::size_t(sy) * src.width + sx) * 4], 4,
                        &out.rgba[(std::size_t(y) * src.width + x) * 4]);
        }
    return out;
}

Image transposed(const Image& src) {  // square tiles: (x, y) -> (y, x)
    Image out = src;
    for (int y = 0; y < src.height; ++y)
        for (int x = 0; x < src.width; ++x)
            std::copy_n(&src.rgba[(std::size_t(x) * src.width + y) * 4], 4,
                        &out.rgba[(std::size_t(y) * src.width + x) * 4]);
    return out;
}

// ---- the parts as pictures -----------------------------------------------------------------------------------------------------

Result<Image> part_image(const TilesetPart& part, const TilesetSpec& spec, const PixelPalette& palette,
                         const TilesetLoader& load) {
    const int tw = spec.tileWidth, th = spec.tileHeight;
    const std::string hint = std::format(
        "Every picture of a tileset part is exactly one tile: {} x {} pixels (tileWidth x tileHeight).", tw, th);
    Image out;
    out.width = tw;
    out.height = th;
    out.rgba.assign(std::size_t(tw) * th * 4, 0);
    if (!part.source.empty()) {
        const Image& src = load(part.pointer + "/source", part.source);
        if (src.width != tw || src.height != th)
            return make_error(std::format("{}/source: '{}' is {} x {} pixels but the tiles of this set are {} x {}.",
                                          part.pointer, part.source, src.width, src.height, tw, th),
                              hint + " Resize the picture, or change tileWidth / tileHeight of the layer.");
        return src;
    }
    if (!part.rows.empty()) {
        if (palette.empty())
            return make_error(part.pointer + "/rows: the document has no palette to look the rows' colours up in.",
                              "Add `palette` to the document (a list of colours) or set style.palette in assets.json.");
        auto grid = index_grid_from_rows(part.rows, palette.size());
        if (!grid.ok()) return make_error(part.pointer + "/rows: " + grid.error().message, grid.error().hint);
        if (grid->w != tw || grid->h != th)
            return make_error(std::format("{}/rows: the rows are {} x {} pixels but the tiles of this set are {} x {}.",
                                          part.pointer, grid->w, grid->h, tw, th),
                              hint);
        return index_grid_image(*grid, palette);
    }
    if (part.color) {
        const Color c = *part.color;
        const std::uint8_t px[4] = {std::uint8_t(c.r * 255.0f + 0.5f), std::uint8_t(c.g * 255.0f + 0.5f),
                                    std::uint8_t(c.b * 255.0f + 0.5f), std::uint8_t(c.a * 255.0f + 0.5f)};
        for (std::size_t i = 0; i < out.rgba.size(); i += 4) std::copy_n(px, 4, &out.rgba[i]);
        return out;
    }
    return make_error(
        part.pointer + ": the part has no picture.",
        "Give `source` (a PNG of one tile), `rows` (text rows of one tile) or `color` (one flat colour).");
}

// The variants of every part, as pictures of one tile.
using PartPictures = std::map<std::string, std::vector<Image>>;

// One side of a tile: where a terrain edge or corner points.
enum class Side { Top, Bottom, Left, Right };

struct Quadrant {
    int x, y;  // where it sits in the tile (0 or half the tile)
    int vBit, hBit, dBit;
    Side vSide, hSide;  // the sides of the tile it touches vertically (top/bottom) and horizontally (left/right)
};

}  // namespace

const std::vector<std::string>& tileset_part_names() { return kParts; }

std::vector<std::string> tileset_required_parts(const std::string& mode, bool squareTile) {
    std::vector<std::string> out = {"inside", "edge", "corner"};
    if (mode == "blob47") out.push_back("innerCorner");
    if (!squareTile) out.push_back("edgeLeft");
    return out;
}

TilesetLayout tileset_layout(const TilesetSpec& spec) {
    TilesetLayout l;
    l.tileWidth = spec.tileWidth;
    l.tileHeight = spec.tileHeight;
    l.slots = autotile_tile_count(mode_of(spec));
    l.variations = std::max(1, spec.variations);
    l.tiles = l.slots * l.variations;
    l.columns = spec.columns > 0 ? spec.columns : (mode_of(spec) == AutotileMode::Basic16 ? 4 : 8);
    l.rows = (l.tiles + l.columns - 1) / l.columns;
    return l;
}

std::vector<int> tileset_tile_masks(const TilesetSpec& spec) {
    const auto& masks = autotile_masks(mode_of(spec));
    std::vector<int> out;
    for (int m : masks)
        for (int v = 0; v < std::max(1, spec.variations); ++v) out.push_back(m);
    return out;
}

Result<TilesetBuild> build_tileset(const TilesetSpec& spec, const PixelPalette& palette, const TilesetLoader& load) {
    const AutotileMode mode = mode_of(spec);
    const bool blob = mode == AutotileMode::Blob47;
    TilesetBuild build;
    build.layout = tileset_layout(spec);
    const TilesetLayout& lay = build.layout;
    const int tw = lay.tileWidth, th = lay.tileHeight, qw = tw / 2, qh = th / 2;

    // every part as pictures
    PartPictures pics;
    for (const auto& [name, variants] : spec.parts)
        for (const TilesetPart& v : variants) {
            auto img = part_image(v, spec, palette, load);
            if (!img.ok()) return make_error(img.error().message, img.error().hint);
            pics[name].push_back(std::move(*img));
        }
    for (const std::string& need : tileset_required_parts(spec.mode, tw == th))
        if (!pics.count(need))
            return make_error(
                "The tileset has no `" + need + "` part.",
                "A " + spec.mode + " set needs at least: " +
                    [&] {
                        std::string s;
                        for (const std::string& n : tileset_required_parts(spec.mode, tw == th))
                            s += (s.empty() ? "" : ", ") + n;
                        return s;
                    }() +
                    ". Add \"parts\": {\"" + need +
                    "\": {\"rows\": [...]}} (or {\"source\": \"x.png\"}); see image.tileset.info for what each part "
                    "is.");

    // The picture of a part in an orientation for a variant pick: the override part when the document has it, else the base part flipped or transposed.
    auto base_pick = [&](const std::string& name, int pick) -> const Image& {
        const auto& list = pics.at(name);
        return list[std::size_t(pick) % list.size()];
    };
    // A corner picture for the quadrant at (right, bottom): the override part (cornerNE, ...) when the document has it, else the base part flipped.
    auto oriented = [&](const std::string& kind, bool right, bool bottom, int pick) -> Image {
        if (right || bottom) {
            const std::string overrideName = kind + (bottom ? "S" : "N") + (right ? "E" : "W");
            if (pics.count(overrideName)) return base_pick(overrideName, pick);
        }
        return flipped(base_pick(kind, pick), right, bottom);
    };
    auto edge_image = [&](Side side, int pick) -> Image {
        switch (side) {
            case Side::Top: return base_pick("edge", pick);
            case Side::Bottom:
                return pics.count("edgeBottom") ? base_pick("edgeBottom", pick)
                                                : flipped(base_pick("edge", pick), false, true);
            case Side::Left:
                return pics.count("edgeLeft") ? base_pick("edgeLeft", pick) : transposed(base_pick("edge", pick));
            case Side::Right:
                if (pics.count("edgeRight")) return base_pick("edgeRight", pick);
                return flipped(pics.count("edgeLeft") ? base_pick("edgeLeft", pick)
                                                      : transposed(base_pick("edge", pick)),
                               true, false);
        }
        return Image();
    };

    const Quadrant quads[4] = {{0, 0, kAutoN, kAutoW, kAutoNW, Side::Top, Side::Left},
                               {qw, 0, kAutoN, kAutoE, kAutoNE, Side::Top, Side::Right},
                               {0, qh, kAutoS, kAutoW, kAutoSW, Side::Bottom, Side::Left},
                               {qw, qh, kAutoS, kAutoE, kAutoSE, Side::Bottom, Side::Right}};

    build.sheet.width = lay.width();
    build.sheet.height = lay.height();
    build.sheet.rgba.assign(std::size_t(build.sheet.width) * build.sheet.height * 4, 0);

    const auto& masks = autotile_masks(mode);
    std::vector<int> repeated;  // tiles whose variation looks like an earlier one of the same slot
    bool anyVariantAnywhere = false;
    for (int slot = 0; slot < lay.slots; ++slot) {
        const int mask = masks[std::size_t(slot)];
        std::set<std::vector<int>> used;
        for (int v = 0; v < lay.variations; ++v) {
            const int tileIndex = lay.tile_index(slot, v);
            std::vector<int> picks;
            TileJoinSources sources;
            Image tile;
            bool choice = false;  // some quadrant could pick between variants
            for (int attempt = 0; attempt < 32; ++attempt) {
                picks.clear();
                tile = Image();
                tile.width = tw;
                tile.height = th;
                tile.rgba.assign(std::size_t(tw) * th * 4, 0);
                for (int q = 0; q < 4; ++q) {
                    const Quadrant& Q = quads[q];
                    const bool a = (mask & Q.vBit) != 0, b = (mask & Q.hBit) != 0, d = !blob || (mask & Q.dBit) != 0;
                    const bool right = Q.hSide == Side::Right, bottom = Q.vSide == Side::Bottom;
                    const std::string base = !a && !b ? "corner"
                                             : a && b ? (d ? "inside" : "innerCorner")
                                                      : "edge";  // the part whose variants the pick counts
                    const std::size_t count = pics.at(base).size();
                    int pick = 0;
                    if (v > 0 && count > 1)
                        pick = int(autotile_hash(spec.seed + std::int64_t(attempt) * 7919, tileIndex, q) % count);
                    picks.push_back(pick);
                    Image src;
                    std::string key =
                        base + "#" +
                        std::to_string(pick);  // the picture this quadrant is cut from: part, orientation, variant
                    if (!a && !b) {
                        src = oriented("corner", right, bottom, pick);
                        key += std::string("/") + (right ? "r" : "l") + (bottom ? "b" : "t");
                    } else if (a && b) {
                        src = d ? base_pick("inside", pick) : oriented("innerCorner", right, bottom, pick);
                        if (!d) key += std::string("/") + (right ? "r" : "l") + (bottom ? "b" : "t");
                    } else if (!a) {
                        src = edge_image(Q.vSide, pick);  // nothing across the top/bottom: a horizontal edge
                        key += "/" + std::to_string(int(Q.vSide));
                    } else {
                        src = edge_image(Q.hSide, pick);  // nothing across the left/right: a vertical edge
                        key += "/" + std::to_string(int(Q.hSide));
                    }
                    TileJoinSource& js = sources[std::size_t(q)];
                    js = TileJoinSource();
                    js.part = base;
                    js.key = key;
                    for (int y = 0; y < qh; ++y)
                        for (int x : {qw - 1, qw}) {
                            const std::uint8_t* p = &src.rgba[(std::size_t(Q.y + y) * tw + x) * 4];
                            js.columns.insert(js.columns.end(), p, p + 4);
                        }
                    for (int x = 0; x < qw; ++x)
                        for (int y : {qh - 1, qh}) {
                            const std::uint8_t* p = &src.rgba[(std::size_t(y) * tw + Q.x + x) * 4];
                            js.rows.insert(js.rows.end(), p, p + 4);
                        }
                    for (int y = 0; y < qh; ++y)
                        std::copy_n(&src.rgba[(std::size_t(Q.y + y) * tw + Q.x) * 4], std::size_t(qw) * 4,
                                    &tile.rgba[(std::size_t(Q.y + y) * tw + Q.x) * 4]);
                    if (count > 1) choice = true;
                }
                if (v == 0 || !used.count(picks)) break;
            }
            build.joins.resize(std::size_t(lay.tiles));
            build.joins[std::size_t(tileIndex)] = sources;
            if (choice) anyVariantAnywhere = true;
            if (v > 0 && used.count(picks)) repeated.push_back(tileIndex);
            used.insert(picks);
            const int col = tileIndex % lay.columns, row = tileIndex / lay.columns;
            for (int y = 0; y < th; ++y)
                std::copy_n(
                    &tile.rgba[std::size_t(y) * tw * 4], std::size_t(tw) * 4,
                    &build.sheet.rgba[(std::size_t(row * th + y) * build.sheet.width + std::size_t(col) * tw) * 4]);
        }
    }
    if (lay.variations > 1 && !anyVariantAnywhere)
        build.warnings.push_back(
            std::format("The set has {} variations of each tile, but every part has a single picture, so they are "
                        "identical. Give `inside`, `edge` and `corner` a list of pictures (variants).",
                        lay.variations));
    else if (!repeated.empty()) {
        std::string list;
        for (std::size_t i = 0; i < repeated.size() && i < 5; ++i)
            list += (i ? ", " : "") + std::to_string(repeated[i]);
        build.warnings.push_back(
            std::format("{} tile{} repeat{} an earlier variation of the same look (tile {}{}): the parts they are made "
                        "of have too few variants. Add variants to the parts, or use fewer variations.",
                        repeated.size(), repeated.size() == 1 ? "" : "s", repeated.size() == 1 ? "s" : "", list,
                        repeated.size() > 5 ? ", ..." : ""));
    }
    return build;
}

Json tileset_terrain_json(const TilesetSpec& spec, const std::string& fallbackName) {
    const TilesetLayout lay = tileset_layout(spec);
    Json tiles = Json::array();
    for (int slot = 0; slot < lay.slots; ++slot) {
        if (lay.variations == 1) {
            tiles.push_back(slot);
        } else {
            Json list = Json::array();
            for (int v = 0; v < lay.variations; ++v) list.push_back(lay.tile_index(slot, v));
            tiles.push_back(list);
        }
    }
    const std::string name = !spec.terrain.empty() ? spec.terrain : !fallbackName.empty() ? fallbackName : "terrain";
    Json t = Json::object({{"name", name}, {"mode", spec.mode}});
    if (spec.seed != 0) t["seed"] = spec.seed;
    t["tiles"] = tiles;
    return t;
}

Json tileset_rules_file_json(const TilesetSpec& spec, const std::string& fallbackName) {
    return Json::object(
        {{"format", kTerrainsFormat}, {"terrains", Json::array({tileset_terrain_json(spec, fallbackName)})}});
}

}  // namespace fa
