#include "fa/scene/tilemap.h"

#include <algorithm>
#include <cmath>

namespace fa {

namespace {

constexpr std::size_t kMaxReported = 5;  // element-level problems reported per component

const char* kAsciiHint =
    "To author a level from ASCII art use the scene.import_ascii command (rows + legend): it writes valid tiles.";

std::string number_text(double v) {
    if (v == std::floor(v) && std::fabs(v) < 1e15) return std::to_string(static_cast<long long>(v));
    return std::to_string(v);
}

// A tile value as the renderer and physics see it: whole numbers >= 0 (index plus flag bits); anything else (strings,
// null, -1, nonsense) is empty.
int tile_value(const Json& v) {
    if (!v.is_number()) return -1;
    const double d = v.get<double>();
    if (!(d >= 0.0) || d > double(kTileFlagMask | kTileIndexMask)) return -1;
    return static_cast<int>(d);
}

}  // namespace

int make_tile(int index, int turns, bool flipX, bool flipY) {
    if (index < 0) return -1;
    int flags = 0;
    switch (((turns % 4) + 4) % 4) {
        case 1: flags = kTileTranspose | kTileFlipX; break;
        case 2: flags = kTileFlipX | kTileFlipY; break;
        case 3: flags = kTileTranspose | kTileFlipY; break;
        default: break;
    }
    // The mirrors come after the turn: they toggle the final x / y mirror.
    if (flipX) flags ^= kTileFlipX;
    if (flipY) flags ^= kTileFlipY;
    return (index & kTileIndexMask) | flags;
}

TilemapSize tilemap_size(const Tilemap& tm) {
    TilemapSize size;
    const Json& t = tm.tiles;
    if (!t.is_array() || t.empty()) return size;
    if (t[0].is_array()) {
        for (const Json& row : t)
            if (row.is_array()) size.width = std::max(size.width, static_cast<int>(row.size()));
        if (size.width > 0) size.height = static_cast<int>(t.size());
        return size;
    }
    const int count = static_cast<int>(t.size());
    size.width = tm.width;
    size.height = tm.height;
    if (size.width <= 0) size.width = size.height > 0 ? (count + size.height - 1) / size.height : count;
    if (size.height <= 0) size.height = (count + size.width - 1) / size.width;
    return size;
}

int tilemap_tile_at(const Tilemap& tm, const TilemapSize& size, int col, int row) {
    if (col < 0 || row < 0 || col >= size.width || row >= size.height || !tm.tiles.is_array()) return -1;
    const Json& t = tm.tiles;
    if (!t.empty() && t[0].is_array()) {
        const Json& r = t[std::size_t(row)];
        return r.is_array() && std::size_t(col) < r.size() ? tile_value(r[std::size_t(col)]) : -1;
    }
    const std::size_t i = std::size_t(row) * std::size_t(size.width) + std::size_t(col);
    return i < t.size() ? tile_value(t[i]) : -1;
}

bool set_tilemap_tile(Tilemap& tm, int col, int row, int value) {
    const TilemapSize size = tilemap_size(tm);
    if (size.empty() || col < 0 || row < 0 || col >= size.width || row >= size.height) return false;
    if (value < -1 || value > (kTileFlagMask | kTileIndexMask)) return false;
    const int old = tilemap_tile_at(tm, size, col, row);
    Json* slot = nullptr;
    if (tm.tiles[0].is_array()) {
        Json& r = tm.tiles[std::size_t(row)];
        if (!r.is_array()) r = Json::array();
        while (r.size() <= std::size_t(col)) r.push_back(-1);
        slot = &r[std::size_t(col)];
    } else {
        const std::size_t i = std::size_t(row) * std::size_t(size.width) + std::size_t(col);
        while (tm.tiles.size() <= i) tm.tiles.push_back(-1);
        slot = &tm.tiles[i];
    }
    *slot = value;
    constexpr std::size_t kMaxEdits = 4096;  // nobody reads them (no physics): drop them, physics then compares hashes
    if (tm.edits.size() >= kMaxEdits) tm.edits.clear();
    tm.edits.push_back({row * size.width + col, tile_index(old), tile_index(value)});
    return true;
}

TilemapGrid tilemap_grid(const Tilemap& tm) {
    TilemapGrid g;
    const TilemapSize size = tilemap_size(tm);
    if (size.empty()) return g;
    g.width = size.width;
    g.height = size.height;
    g.tiles.assign(std::size_t(g.width) * std::size_t(g.height), -1);
    const Json& t = tm.tiles;
    if (t[0].is_array()) {
        for (int r = 0; r < g.height; ++r) {
            const Json& row = t[std::size_t(r)];
            if (!row.is_array()) continue;
            const int n = std::min(static_cast<int>(row.size()), g.width);
            for (int c = 0; c < n; ++c) g.tiles[std::size_t(r) * std::size_t(g.width) + std::size_t(c)] = tile_value(row[std::size_t(c)]);
        }
    } else {
        for (std::size_t i = 0; i < t.size() && i < g.tiles.size(); ++i) g.tiles[i] = tile_value(t[i]);
    }
    return g;
}

int tileset_columns(const Tilemap& tm, int imageWidth) {
    if (tm.columns > 0) return tm.columns;
    if (imageWidth <= 0 || tm.tileSize.x <= 0) return 0;
    const float usable = float(imageWidth - 2 * std::max(0, tm.margin) + std::max(0, tm.spacing));
    return std::max(1, static_cast<int>(usable / (tm.tileSize.x + float(std::max(0, tm.spacing)))));
}

std::vector<TilemapIssue> check_tilemap(const Tilemap& tm) {
    std::vector<TilemapIssue> out;
    auto err = [&](std::string pointer, std::string message, std::string hint = {}) {
        out.push_back({true, std::move(pointer), std::move(message), std::move(hint)});
    };
    auto warn = [&](std::string pointer, std::string message, std::string hint = {}) {
        out.push_back({false, std::move(pointer), std::move(message), std::move(hint)});
    };

    if (tm.tileSize.x <= 0 || tm.tileSize.y <= 0)
        err("/tileSize", "tileSize [" + number_text(tm.tileSize.x) + ", " + number_text(tm.tileSize.y) + "] must be positive in both axes",
            "Example: \"tileSize\": [32, 32] (the size of one tile in the tileset image AND in the world).");

    // ---- solidTiles
    if (!tm.solidTiles.is_array()) {
        err("/solidTiles", "solidTiles must be an array of tile indices, got " + describe_json_value(tm.solidTiles),
            "Example: \"solidTiles\": [0, 1, 2]. Use [] for no collision.");
    } else {
        std::size_t bad = 0;
        for (std::size_t i = 0; i < tm.solidTiles.size(); ++i) {
            const Json& v = tm.solidTiles[i];
            if (v.is_number() && v.get<double>() == std::floor(v.get<double>()) && v.get<double>() < double(kTileFlipX)) continue;
            if (++bad <= kMaxReported)
                err("/solidTiles/" + std::to_string(i), "solidTiles entry " + std::to_string(i) + " must be an integer tile index, got " + describe_json_value(v),
                    "List plain tile numbers of the tileset, e.g. [0, 1, 2]; flip and rotate flags are not part of them (a flipped solid tile is still solid).");
        }
        if (bad > kMaxReported) err("/solidTiles", "... and " + std::to_string(bad - kMaxReported) + " more invalid solidTiles entries");
    }

    // ---- tiles
    const Json& t = tm.tiles;
    const std::int64_t w = tm.width, h = tm.height;
    if (!t.is_array()) {
        err("/tiles", "tiles must be an array (flat width*height integers, or an array of rows), got " + describe_json_value(t),
            std::string("Example: \"width\": 3, \"height\": 2, \"tiles\": [-1, 0, 0, 1, 1, 1]. ") + kAsciiHint);
        return out;
    }
    if (t.empty()) {
        if (w > 0 && h > 0)
            warn("/tiles", "tiles is empty although width x height is " + std::to_string(w) + " x " + std::to_string(h) + ": nothing is drawn and nothing collides",
                 std::string("Fill tiles with width*height integers (-1 = empty). ") + kAsciiHint);
        return out;
    }

    std::size_t badElements = 0;
    auto check_tile = [&](const Json& v, const std::string& pointer) {
        std::string problem, hint;
        if (v.is_number()) {
            double d = v.get<double>();
            if (d != std::floor(d)) problem = "tile index " + number_text(d) + " is not a whole number";
            else if (d < -1) problem = "tile index " + number_text(d) + " is invalid";
            else if (d > double(kTileFlagMask | kTileIndexMask))
                problem = "tile value " + number_text(d) + " is too large: an index below " + std::to_string(kTileFlipX) +
                          " plus at most the three flip flags";
            if (!problem.empty())
                hint = "Tile indices count from 0 in the tileset (left-to-right, top-to-bottom); -1 = empty. To flip or rotate a tile add "
                       "268435456 (flipX), 536870912 (flipY) and/or 1073741824 (transpose) to its index.";
        } else if (v.is_string()) {
            problem = "tile is the string " + describe_json_value(v) + " but tiles must be integers";
            hint = kAsciiHint;
        } else {
            problem = "tile must be an integer, got " + describe_json_value(v);
            hint = "Tile indices count from 0 in the tileset; -1 = empty.";
        }
        if (problem.empty()) return;
        if (++badElements <= kMaxReported) err(pointer, problem, hint);
    };

    const bool rowForm = t[0].is_array();
    const bool sizeKnown = w > 0 && h > 0;
    if (rowForm) {
        bool mixed = false;
        for (std::size_t r = 0; r < t.size(); ++r) {
            if (!t[r].is_array()) {
                if (!mixed) err("/tiles/" + std::to_string(r), "tiles mixes rows (arrays) and single tiles: entry " + std::to_string(r) + " is " + describe_json_value(t[r]),
                                "Use one form: all rows as arrays of integers, or one flat array of width*height integers.");
                mixed = true;
                continue;
            }
            for (std::size_t c = 0; c < t[r].size(); ++c) check_tile(t[r][c], "/tiles/" + std::to_string(r) + "/" + std::to_string(c));
        }
        if (badElements > kMaxReported) err("/tiles", "... and " + std::to_string(badElements - kMaxReported) + " more invalid tiles");
        if (!mixed) {
            const std::int64_t expected = w > 0 ? w : std::int64_t(t[0].size());
            std::size_t raggedReported = 0;
            for (std::size_t r = 0; r < t.size(); ++r) {
                if (std::int64_t(t[r].size()) == expected) continue;
                if (++raggedReported > kMaxReported) continue;
                err("/tiles/" + std::to_string(r),
                    "row " + std::to_string(r) + " of tiles has " + std::to_string(t[r].size()) + " entries but the map is " + std::to_string(expected) +
                        " tiles wide" + (w > 0 ? " (width)" : " (row 0)"),
                    "Every row needs the same number of tiles; pad with -1 (empty).");
            }
            if (raggedReported > kMaxReported) err("/tiles", "... and " + std::to_string(raggedReported - kMaxReported) + " more rows with the wrong length");
            if (h > 0 && std::int64_t(t.size()) != h)
                err("/tiles", "tiles has " + std::to_string(t.size()) + " rows but height is " + std::to_string(h),
                    "Make height equal to the number of rows (row 0 is the TOP row).");
        }
    } else {
        for (std::size_t i = 0; i < t.size(); ++i) {
            if (t[i].is_array()) {
                err("/tiles/" + std::to_string(i), "tiles mixes single tiles and rows: entry " + std::to_string(i) + " is an array",
                    "Use one form: all rows as arrays of integers, or one flat array of width*height integers.");
                break;
            }
            check_tile(t[i], "/tiles/" + std::to_string(i));
        }
        if (badElements > kMaxReported) err("/tiles", "... and " + std::to_string(badElements - kMaxReported) + " more invalid tiles");
        if (sizeKnown && std::int64_t(t.size()) != w * h)
            err("/tiles",
                "tiles has " + std::to_string(t.size()) + " entries but width x height is " + std::to_string(w) + " x " + std::to_string(h) + " = " + std::to_string(w * h),
                "tiles is row-major with row 0 at the TOP: give exactly width*height integers (-1 = empty), or fix width/height. " + std::string(kAsciiHint));
    }

    // Rows form: the rows define the size, width/height are optional (checked above when present). Flat form: the list
    // alone does not say where a row ends, so a missing width means "one single row" (the same on screen and in physics).
    if (!rowForm) {
        const TilemapGrid g = tilemap_grid(tm);
        const std::string read = std::to_string(g.width) + " x " + std::to_string(g.height);
        if (w <= 0)
            warn("/width", "width is not set, so the " + std::to_string(t.size()) + " flat tiles are read as a " + read + " map (width x height)",
                 "Set width (tiles per row) and height (number of rows), or write tiles as an array of rows, which needs neither.");
        else if (h <= 0 && std::int64_t(t.size()) % w != 0)
            warn("/height", "height is not set and " + std::to_string(t.size()) + " tiles do not fill whole rows of " + std::to_string(w) + ": the map is read as " + read,
                 "Set height (number of rows) so tiles has exactly width*height entries.");
    }
    return out;
}

void set_tilemap_grid(Tilemap& tm, int width, int height, const std::vector<int>& tiles) {
    tm.width = width;
    tm.height = height;
    Json arr = Json::array();
    for (int v : tiles) arr.push_back(v);
    tm.tiles = std::move(arr);
}

Vec2 tilemap_cell_center(const Tilemap& tm, int col, int row) {
    return {(float(col) + 0.5f) * tm.tileSize.x, -(float(row) + 0.5f) * tm.tileSize.y};
}

int tileset_tile_count(const Tilemap& tm, int imageWidth, int imageHeight) {
    if (imageWidth <= 0 || imageHeight <= 0 || tm.tileSize.x <= 0 || tm.tileSize.y <= 0) return 0;
    const float usableY = float(imageHeight - 2 * std::max(0, tm.margin) + std::max(0, tm.spacing));
    const int tilesY = int(usableY / (tm.tileSize.y + float(std::max(0, tm.spacing))));
    const int cols = tileset_columns(tm, imageWidth);
    if (cols <= 0 || tilesY <= 0) return 0;
    return cols * tilesY;
}

}  // namespace fa
