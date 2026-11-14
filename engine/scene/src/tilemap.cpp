#include "fa/scene/tilemap.h"

#include "fa/scene/autotile.h"

#include <algorithm>
#include <cmath>
#include <functional>

namespace fa {

namespace {

constexpr std::size_t kMaxReported = 5;  // element-level problems reported per component

const char* kAsciiHint =
    "To author a level from ASCII art use the scene.import_ascii command (rows + legend): it writes valid tiles.";

std::string number_text(double v) {
    if (v == std::floor(v) && std::fabs(v) < 1e15) return std::to_string(static_cast<long long>(v));
    return std::to_string(v);
}

// A tile value as the renderer and physics see it: a whole number >= 0 (index plus flag bits); a negative one is empty.
int tile_value(std::int32_t v) { return v < 0 ? -1 : v; }

// A tile written in a Json (the rows form of a file, a test): numbers keep their value; anything else, negative
// numbers and values the array cannot hold are empty.
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
    const int count = static_cast<int>(std::min<std::size_t>(tm.tiles.size(), std::size_t(INT32_MAX)));
    if (count <= 0) return size;
    size.width = tm.width;
    size.height = tm.height;
    if (size.width <= 0) size.width = size.height > 0 ? (count + size.height - 1) / size.height : count;
    if (size.height <= 0) size.height = (count + size.width - 1) / size.width;
    return size;
}

int tilemap_tile_at(const Tilemap& tm, const TilemapSize& size, int col, int row) {
    if (col < 0 || row < 0 || col >= size.width || row >= size.height) return -1;
    const std::size_t i = std::size_t(row) * std::size_t(size.width) + std::size_t(col);
    return i < tm.tiles.size() ? tile_value(std::as_const(tm.tiles)[i]) : -1;
}

bool set_tilemap_tile(Tilemap& tm, int col, int row, int value) {
    const TilemapSize size = tilemap_size(tm);
    if (size.empty() || col < 0 || row < 0 || col >= size.width || row >= size.height) return false;
    if (value < -1) return false;
    const int old = tilemap_tile_at(tm, size, col, row);
    const std::size_t i = std::size_t(row) * std::size_t(size.width) + std::size_t(col);
    if (tm.tiles.size() <= i) tm.tiles.resize(i + 1, -1);  // a flat list shorter than the map grows to reach the cell
    if (std::as_const(tm.tiles)[i] == value) return true;  // already there: no change, no edit, no version bump
    tm.tiles.set(i, value);  // exactly one version bump, so a consumer can match the bumps against the edits
    constexpr std::size_t kMaxEdits = 4096;
    if (tm.editsArray !=
        tm.tiles.id()) {  // the list came with another array (a copy, an assignment): it explains nothing here
        tm.edits.clear();
        tm.editsArray = tm.tiles.id();
    }
    // The oldest half goes when the list is full: a consumer that has not looked for that long reads every tile instead.
    if (tm.edits.size() >= kMaxEdits)
        tm.edits.erase(tm.edits.begin(), tm.edits.begin() + std::ptrdiff_t(kMaxEdits / 2));
    tm.edits.push_back({row * size.width + col, tile_index(old), tile_index(value), tm.tiles.version()});
    return true;
}

std::uint32_t tilemap_version(Tilemap& tm) {
    if (!tm.sizeSeen) {
        tm.sizeSeen = true;  // the first call takes the baseline
    } else if (tm.seenWidth != tm.width || tm.seenHeight != tm.height) {
        ++tm.sizeChanges;
    }
    tm.seenWidth = tm.width;
    tm.seenHeight = tm.height;
    return static_cast<std::uint32_t>(tm.tiles.version() + tm.sizeChanges);
}

TilemapStamp tilemap_stamp(const Tilemap& tm) {
    return {tm.tiles.id(), tm.tiles.version(), tm.width, tm.height, tm.tiles.size()};
}

bool tilemap_edits_since(const Tilemap& tm, const TilemapStamp& stamp, std::span<const TileEdit>& edits) {
    edits = {};
    const TilemapStamp now = tilemap_stamp(tm);
    if (stamp.arrayId != now.arrayId || stamp.width != now.width || stamp.height != now.height ||
        stamp.count != now.count || stamp.version > now.version)
        return false;
    const std::uint64_t steps = now.version - stamp.version;
    if (steps == 0) return true;
    if (tm.editsArray != now.arrayId || tm.edits.size() < steps) return false;
    // The versions in the list grow strictly: `steps` edits whose first is the step after the stamp and whose last is the
    // current version cover every step exactly once.
    const std::span<const TileEdit> tail(tm.edits.data() + (tm.edits.size() - std::size_t(steps)), std::size_t(steps));
    if (tail.front().version != stamp.version + 1 || tail.back().version != now.version) return false;
    edits = tail;
    return true;
}

TilemapGrid tilemap_grid(const Tilemap& tm) {
    TilemapGrid g;
    const TilemapSize size = tilemap_size(tm);
    if (size.empty()) return g;
    g.width = size.width;
    g.height = size.height;
    g.tiles.assign(std::size_t(g.width) * std::size_t(g.height), -1);
    const ArrayI32& t = tm.tiles;
    for (std::size_t i = 0; i < t.size() && i < g.tiles.size(); ++i) g.tiles[i] = tile_value(t[i]);
    return g;
}

bool tilemap_rows_form(const Json& fields) {
    if (!fields.is_object()) return false;
    const auto it = fields.find("tiles");
    return it != fields.end() && it->is_array() && !it->empty() && (*it)[0].is_array();
}

std::vector<TilemapIssue> check_tilemap_tiles_json(const Json& fields) {
    std::vector<TilemapIssue> out;
    if (!fields.is_object() || tilemap_rows_form(fields)) return out;
    const auto it = fields.find("tiles");
    if (it == fields.end()) return out;
    if (!it->is_array()) {
        out.push_back({true, "/tiles", "tiles must be an array of integers, got " + describe_json_value(*it),
                       "Write tiles as width*height integers (-1 = empty), row-major with row 0 at the TOP, or as an "
                       "array of rows. " +
                           std::string(kAsciiHint)});
        return out;
    }
    std::size_t bad = 0;
    for (std::size_t i = 0; i < it->size(); ++i) {
        const Json& v = (*it)[i];
        if (v.is_number() && v.get<double>() == std::floor(v.get<double>())) continue;
        if (++bad <= kMaxReported)
            out.push_back({true, "/tiles/" + std::to_string(i),
                           v.is_string()
                               ? "tile is the string " + describe_json_value(v) + " but tiles must be integers"
                               : "tile must be an integer, got " + describe_json_value(v),
                           "Tile indices count from 0 in the tileset (left-to-right, top-to-bottom); -1 = empty. " +
                               std::string(kAsciiHint)});
    }
    if (bad > kMaxReported)
        out.push_back({true, "/tiles", "... and " + std::to_string(bad - kMaxReported) + " more invalid tiles", ""});
    return out;
}

std::vector<TilemapIssue> flatten_tilemap_rows(Json& fields) {
    std::vector<TilemapIssue> out;
    if (!tilemap_rows_form(fields)) return out;
    const Json& rows = fields["tiles"];
    auto err = [&](std::string pointer, std::string message, std::string hint) {
        out.push_back({true, std::move(pointer), std::move(message), std::move(hint)});
    };
    auto whole = [&](const char* key) -> std::int64_t {
        const auto it = fields.find(key);
        return it != fields.end() && it->is_number_integer() ? it->get<std::int64_t>() : 0;
    };
    const std::int64_t w = whole("width"), h = whole("height");
    const std::string rowsHint =
        "tiles is stored flat (row-major, row 0 at the TOP, width*height integers, -1 = empty); an array of rows is "
        "converted when it is read, so every row needs the same number of tiles: pad with -1.";
    bool mixed = false;
    for (std::size_t r = 0; r < rows.size() && !mixed; ++r)
        if (!rows[r].is_array()) {
            err("/tiles/" + std::to_string(r),
                "tiles mixes rows (arrays) and single tiles: entry " + std::to_string(r) + " is " +
                    describe_json_value(rows[r]),
                "Use one form: all rows as arrays of integers, or one flat array of width*height integers.");
            mixed = true;
        }
    if (mixed) return out;
    const std::int64_t expected = w > 0 ? w : std::int64_t(rows[0].size());
    std::size_t ragged = 0;
    for (std::size_t r = 0; r < rows.size(); ++r) {
        if (std::int64_t(rows[r].size()) == expected) continue;
        if (++ragged > kMaxReported) continue;
        err("/tiles/" + std::to_string(r),
            "row " + std::to_string(r) + " of tiles has " + std::to_string(rows[r].size()) +
                " entries but the map is " + std::to_string(expected) + " tiles wide" +
                (w > 0 ? " (width)" : " (row 0)"),
            rowsHint);
    }
    if (ragged > kMaxReported)
        err("/tiles", "... and " + std::to_string(ragged - kMaxReported) + " more rows with the wrong length",
            rowsHint);
    if (h > 0 && std::int64_t(rows.size()) != h)
        err("/tiles", "tiles has " + std::to_string(rows.size()) + " rows but height is " + std::to_string(h),
            "Make height equal to the number of rows (row 0 is the TOP row), or leave height out.");
    if (std::int64_t(rows.size()) * expected > std::int64_t(kMaxTypedArrayElements))
        err("/tiles",
            "the map has " + std::to_string(rows.size()) + " x " + std::to_string(expected) + " tiles, more than the " +
                std::to_string(kMaxTypedArrayElements) + " a Tilemap can hold",
            "Split the map into several Tilemap entities.");
    if (!out.empty()) return out;
    Json flat = Json::array();
    flat.get_ref<Json::array_t&>().reserve(std::size_t(rows.size()) * std::size_t(expected));
    std::size_t bad = 0;
    for (std::size_t r = 0; r < rows.size(); ++r)
        for (std::size_t c = 0; c < rows[r].size(); ++c) {
            const Json& v = rows[r][c];
            if (!v.is_number() || v.get<double>() != std::floor(v.get<double>())) {
                if (++bad <= kMaxReported)
                    err("/tiles/" + std::to_string(r) + "/" + std::to_string(c),
                        v.is_string() ? "tile is the string " + describe_json_value(v) + " but tiles must be integers"
                                      : "tile must be an integer, got " + describe_json_value(v),
                        "Tile indices count from 0 in the tileset (left-to-right, top-to-bottom); -1 = empty. " +
                            std::string(kAsciiHint));
                continue;
            }
            // 3.0 is a whole number: store the integer, so the array reads it (a value out of range stays as it is and
            // is refused with the array's own message).
            const double d = v.get<double>();
            if (!v.is_number_integer() && std::fabs(d) < 2147483648.0)
                flat.push_back(std::int64_t(d));
            else
                flat.push_back(v);
        }
    if (bad > kMaxReported) err("/tiles", "... and " + std::to_string(bad - kMaxReported) + " more invalid tiles", "");
    if (!out.empty()) return out;
    const std::int64_t height = std::int64_t(rows.size());
    fields["tiles"] = std::move(flat);
    fields["width"] = expected;
    fields["height"] = height;
    return out;
}

void set_tilemap_tiles(Tilemap& tm, const Json& tiles) {
    if (!tiles.is_array()) {
        tm.tiles.clear();
        return;
    }
    std::vector<std::int32_t> flat;
    if (!tiles.empty() && tiles[0].is_array()) {
        std::size_t width = 0;
        for (const Json& row : tiles)
            if (row.is_array()) width = std::max(width, row.size());
        flat.assign(width * tiles.size(), -1);
        for (std::size_t r = 0; r < tiles.size(); ++r)
            if (tiles[r].is_array())
                for (std::size_t c = 0; c < tiles[r].size(); ++c) flat[r * width + c] = tile_value(tiles[r][c]);
        tm.width = static_cast<std::int32_t>(width);
        tm.height = width > 0 ? static_cast<std::int32_t>(tiles.size()) : 0;
    } else {
        flat.reserve(tiles.size());
        for (const Json& v : tiles) flat.push_back(tile_value(v));
    }
    tm.tiles.assign(flat.data(), flat.size());
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
        err("/tileSize",
            "tileSize [" + number_text(tm.tileSize.x) + ", " + number_text(tm.tileSize.y) +
                "] must be positive in both axes",
            "Example: \"tileSize\": [32, 32] (the size of one tile in the tileset image AND in the world).");

    if (tilemap_isometric(tm) && tm.tileSize.x > 0 && tm.tileSize.y > 0) {
        if (tm.groundHeight < 0.0f || tm.groundOffset < 0.0f)
            err(tm.groundHeight < 0.0f ? "/groundHeight" : "/groundOffset",
                "groundHeight and groundOffset cannot be negative",
                "Use 0 for the default (groundHeight = tileSize.y, groundOffset = 0).");
        else if (tm.groundOffset + tilemap_ground_height(tm) > tm.tileSize.y + 1e-3f)
            warn("/groundOffset",
                 "the ground diamond (groundOffset " + number_text(tm.groundOffset) + " + height " +
                     number_text(tilemap_ground_height(tm)) + ") is taller than the tile image (tileSize.y " +
                     number_text(tm.tileSize.y) + "): the bottom of the diamond is cut off",
                 "Make tileSize.y at least groundOffset + groundHeight, or lower groundOffset / groundHeight.");
    }

    // ---- solidTiles
    if (!tm.solidTiles.is_array()) {
        err("/solidTiles", "solidTiles must be an array of tile indices, got " + describe_json_value(tm.solidTiles),
            "Example: \"solidTiles\": [0, 1, 2]. Use [] for no collision.");
    } else {
        std::size_t bad = 0;
        for (std::size_t i = 0; i < tm.solidTiles.size(); ++i) {
            const Json& v = tm.solidTiles[i];
            if (v.is_number() && v.get<double>() == std::floor(v.get<double>()) && v.get<double>() < double(kTileFlipX))
                continue;
            if (++bad <= kMaxReported)
                err("/solidTiles/" + std::to_string(i),
                    "solidTiles entry " + std::to_string(i) + " must be an integer tile index, got " +
                        describe_json_value(v),
                    "List plain tile numbers of the tileset, e.g. [0, 1, 2]; flip and rotate flags are not part of "
                    "them (a flipped solid tile is still solid).");
        }
        if (bad > kMaxReported)
            err("/solidTiles", "... and " + std::to_string(bad - kMaxReported) + " more invalid solidTiles entries");
    }

    // ---- terrains (autotile rules)
    if (!tm.terrains.is_array() || !tm.terrains.empty()) {
        std::size_t shown = 0;
        for (TilemapIssue& issue : check_terrains(tm.terrains))
            if (++shown <= kMaxReported) out.push_back(std::move(issue));
    }

    // ---- tiles (flat: a file's array of rows was flattened by flatten_tilemap_rows before it got here)
    const ArrayI32& t = tm.tiles;
    const std::int64_t w = tm.width, h = tm.height;
    if (t.empty()) {
        if (w > 0 && h > 0)
            warn("/tiles",
                 "tiles is empty although width x height is " + std::to_string(w) + " x " + std::to_string(h) +
                     ": nothing is drawn and nothing collides",
                 std::string("Fill tiles with width*height integers (-1 = empty). ") + kAsciiHint);
        return out;
    }

    std::size_t badElements = 0;
    for (std::size_t i = 0; i < t.size(); ++i) {
        if (t[i] >= -1) continue;
        if (++badElements <= kMaxReported)
            err("/tiles/" + std::to_string(i), "tile index " + std::to_string(t[i]) + " is invalid",
                "Tile indices count from 0 in the tileset (left-to-right, top-to-bottom); -1 = empty. To flip or "
                "rotate a tile add 268435456 (flipX), 536870912 (flipY) and/or 1073741824 (transpose) to its index.");
    }
    if (badElements > kMaxReported)
        err("/tiles", "... and " + std::to_string(badElements - kMaxReported) + " more invalid tiles");
    if (w > 0 && h > 0 && std::int64_t(t.size()) != w * h)
        err("/tiles",
            "tiles has " + std::to_string(t.size()) + " entries but width x height is " + std::to_string(w) + " x " +
                std::to_string(h) + " = " + std::to_string(w * h),
            "tiles is row-major with row 0 at the TOP: give exactly width*height integers (-1 = empty), or fix "
            "width/height. " +
                std::string(kAsciiHint));

    // The list alone does not say where a row ends, so a missing width means "one single row" (the same on screen and
    // in physics).
    const TilemapGrid g = tilemap_grid(tm);
    const std::string read = std::to_string(g.width) + " x " + std::to_string(g.height);
    if (w <= 0)
        warn("/width",
             "width is not set, so the " + std::to_string(t.size()) + " flat tiles are read as a " + read +
                 " map (width x height)",
             "Set width (tiles per row) and height (number of rows), or write tiles as an array of rows, which "
             "needs neither.");
    else if (h <= 0 && std::int64_t(t.size()) % w != 0)
        warn("/height",
             "height is not set and " + std::to_string(t.size()) + " tiles do not fill whole rows of " +
                 std::to_string(w) + ": the map is read as " + read,
             "Set height (number of rows) so tiles has exactly width*height entries.");
    return out;
}

void set_tilemap_grid(Tilemap& tm, int width, int height, const std::vector<int>& tiles) {
    tm.width = width;
    tm.height = height;
    static_assert(sizeof(int) == sizeof(std::int32_t));
    tm.tiles.assign(tiles.data(), tiles.size());
}

float tilemap_ground_height(const Tilemap& tm) {
    return tilemap_isometric(tm) && tm.groundHeight > 0.0f ? tm.groundHeight : tm.tileSize.y;
}

Vec2 tilemap_cell_center(const Tilemap& tm, int col, int row) {
    if (tilemap_isometric(tm)) {
        const float hw = tm.tileSize.x * 0.5f, hh = tilemap_ground_height(tm) * 0.5f;
        return {float(col - row) * hw, -float(col + row + 1) * hh};
    }
    return {(float(col) + 0.5f) * tm.tileSize.x, -(float(row) + 0.5f) * tm.tileSize.y};
}

void tilemap_local_to_cell(const Tilemap& tm, float m[4]) {
    m[0] = m[1] = m[2] = m[3] = 0.0f;
    if (!(tm.tileSize.x > 0.0f) || !(tm.tileSize.y > 0.0f)) return;
    if (tilemap_isometric(tm)) {
        const float ax = 0.5f / (tm.tileSize.x * 0.5f), ay = 0.5f / (tilemap_ground_height(tm) * 0.5f);
        m[0] = ax;
        m[1] = -ay;
        m[2] = -ax;
        m[3] = -ay;
    } else {
        m[0] = 1.0f / tm.tileSize.x;
        m[3] = -1.0f / tm.tileSize.y;
    }
}

bool tilemap_cell_at_local(const Tilemap& tm, Vec2 local, int& col, int& row) {
    float m[4];
    tilemap_local_to_cell(tm, m);
    if (m[0] == 0.0f && m[1] == 0.0f) return false;
    const float cx = m[0] * local.x + m[1] * local.y, cy = m[2] * local.x + m[3] * local.y;
    if (!std::isfinite(cx) || !std::isfinite(cy) || std::fabs(cx) > 1e9f || std::fabs(cy) > 1e9f) return false;
    col = static_cast<int>(std::floor(cx));
    row = static_cast<int>(std::floor(cy));
    return true;
}

Rect tilemap_local_bounds(const Tilemap& tm, const TilemapSize& size) {
    const float w = float(size.width), h = float(size.height);
    if (!tilemap_isometric(tm)) return Rect{0.0f, -h * tm.tileSize.y, w * tm.tileSize.x, h * tm.tileSize.y};
    // Tile (c, r) has its image x in [(c-r-1)*hw ... (c-r+1)*hw] and y from topVertex + groundOffset down by tileSize.y,
    // where topVertex = -(c+r)*hh. The extremes are the corner cells.
    const float hw = tm.tileSize.x * 0.5f, hh = tilemap_ground_height(tm) * 0.5f;
    const float minX = -(h)*hw;         // c = 0, r = height - 1: left edge of its image
    const float maxX = w * hw;          // c = width - 1, r = 0: right edge of its image
    const float top = tm.groundOffset;  // tile (0, 0)
    const float bottom = -(w + h - 2.0f) * hh + tm.groundOffset - tm.tileSize.y;  // tile (width - 1, height - 1)
    return Rect{minX, bottom, maxX - minX, top - bottom};
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
