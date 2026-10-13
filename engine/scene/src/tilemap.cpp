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

}  // namespace

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
    bool hasSolid = false;
    if (!tm.solidTiles.is_array()) {
        err("/solidTiles", "solidTiles must be an array of tile indices, got " + describe_json_value(tm.solidTiles),
            "Example: \"solidTiles\": [0, 1, 2]. Use [] for no collision.");
    } else {
        std::size_t bad = 0;
        for (std::size_t i = 0; i < tm.solidTiles.size(); ++i) {
            const Json& v = tm.solidTiles[i];
            if (v.is_number() && v.get<double>() == std::floor(v.get<double>())) {
                hasSolid = true;
                continue;
            }
            if (++bad <= kMaxReported)
                err("/solidTiles/" + std::to_string(i), "solidTiles entry " + std::to_string(i) + " must be an integer tile index, got " + describe_json_value(v),
                    "List tile numbers of the tileset, e.g. [0, 1, 2].");
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
            if (!problem.empty()) hint = "Tile indices count from 0 in the tileset (left-to-right, top-to-bottom); -1 = empty.";
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
    bool sizeKnown = w > 0 && h > 0;
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

    if (!sizeKnown) {
        std::string msg = "width and height must both be set (> 0) to match tiles (width is " + std::to_string(w) + ", height is " + std::to_string(h) + ")";
        std::string hint = "The renderer guesses the size, but collision needs it. Set width and height (tiles per row / number of rows).";
        if (hasSolid) err("/width", msg + ", otherwise the solid tiles do not collide", hint);
        else warn("/width", msg, hint);
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
    const int tilesX = int(float(imageWidth) / tm.tileSize.x);
    const int tilesY = int(float(imageHeight) / tm.tileSize.y);
    const int cols = tm.columns > 0 ? tm.columns : std::max(1, tilesX);
    if (cols <= 0 || tilesY <= 0) return 0;
    return cols * tilesY;
}

}  // namespace fa
