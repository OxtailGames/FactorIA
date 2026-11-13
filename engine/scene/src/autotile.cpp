#include "fa/scene/autotile.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <map>
#include <set>
#include <unordered_map>

#include "fa/core/strings.h"

namespace fa {

namespace {

struct ModeTables {
    std::vector<int> masks;
    std::array<int, 256> slotOfRaw{};
};

const ModeTables& tables(AutotileMode mode) {
    static const ModeTables basic = [] {
        ModeTables t;
        for (int s = 0; s < 16; ++s)
            t.masks.push_back((s & 1 ? kAutoN : 0) | (s & 2 ? kAutoE : 0) | (s & 4 ? kAutoS : 0) |
                              (s & 8 ? kAutoW : 0));
        for (int raw = 0; raw < 256; ++raw)
            t.slotOfRaw[std::size_t(raw)] =
                (raw & kAutoN ? 1 : 0) | (raw & kAutoE ? 2 : 0) | (raw & kAutoS ? 4 : 0) | (raw & kAutoW ? 8 : 0);
        return t;
    }();
    static const ModeTables blob = [] {
        ModeTables t;
        std::set<int> reduced;
        for (int raw = 0; raw < 256; ++raw) reduced.insert(autotile_reduce(AutotileMode::Blob47, raw));
        t.masks.assign(reduced.begin(), reduced.end());
        for (int raw = 0; raw < 256; ++raw) {
            const int r = autotile_reduce(AutotileMode::Blob47, raw);
            t.slotOfRaw[std::size_t(raw)] = int(std::lower_bound(t.masks.begin(), t.masks.end(), r) - t.masks.begin());
        }
        return t;
    }();
    return mode == AutotileMode::Basic16 ? basic : blob;
}

constexpr int kMaxTileValue = kTileFlagMask | kTileIndexMask;

bool is_tile_value(const Json& v) {
    if (!v.is_number()) return false;
    const double d = v.get<double>();
    return d == std::floor(d) && d >= 0.0 && d <= double(kMaxTileValue);
}

std::string json_text(const Json& v) { return describe_json_value(v); }

struct ParseOut {
    std::vector<Terrain> terrains;
    std::vector<TilemapIssue> issues;
};

ParseOut parse_impl(const Json& terrains) {
    ParseOut out;
    auto err = [&](std::string pointer, std::string message, std::string hint = {}) {
        out.issues.push_back({true, std::move(pointer), std::move(message), std::move(hint)});
    };
    if (!terrains.is_array()) {
        err("/terrains", "terrains must be an array of terrain objects, got " + json_text(terrains),
            "Example: \"terrains\": [{\"name\": \"grass\", \"mode\": \"blob47\", \"first\": 0}]. Use [] for no "
            "autotile rules.");
        return out;
    }
    static const std::vector<std::string> kKeys = {"name", "mode", "first", "tiles", "seed", "joins", "outside"};
    static const std::vector<std::string> kModes = {"basic16", "blob47"};
    static const std::vector<std::string> kOutside = {"empty", "terrain"};
    std::map<std::string, std::size_t> byName;
    std::map<int, std::string> owner;  // tile index -> terrain name
    for (std::size_t i = 0; i < terrains.size(); ++i) {
        const Json& e = terrains[i];
        const std::string at = "/terrains/" + std::to_string(i);
        if (!e.is_object()) {
            err(at, "terrain " + std::to_string(i) + " must be an object, got " + json_text(e),
                "Example: {\"name\": \"grass\", \"mode\": \"blob47\", \"first\": 0}.");
            continue;
        }
        bool bad = false;
        for (auto it = e.begin(); it != e.end(); ++it) {
            if (std::find(kKeys.begin(), kKeys.end(), it.key()) != kKeys.end()) continue;
            err(at + "/" + it.key(), "terrain " + std::to_string(i) + " has an unknown key '" + it.key() + "'",
                did_you_mean(it.key(), kKeys));
            bad = true;
        }
        Terrain t;
        // name
        if (!e.contains("name") || !e["name"].is_string() || e["name"].get<std::string>().empty()) {
            err(at + "/name", "terrain " + std::to_string(i) + " needs a \"name\" (a non-empty string)",
                "The name is what tilemap.paint_terrain and entity.tilemap.paintTerrain take, e.g. \"grass\".");
            bad = true;
        } else {
            t.name = e["name"].get<std::string>();
            if (byName.count(t.name)) {
                err(at + "/name",
                    "two terrains are named '" + t.name + "' (terrain " + std::to_string(byName[t.name]) + " and " +
                        std::to_string(i) + ")",
                    "Names must be unique: rename one of them.");
                bad = true;
            }
        }
        // mode
        bool haveMode = false;
        if (!e.contains("mode")) {
            err(at + "/mode",
                "terrain " + std::to_string(i) + (t.name.empty() ? "" : " ('" + t.name + "')") +
                    " needs a \"mode\": \"basic16\" or \"blob47\"",
                "basic16 looks at the 4 neighbours (16 tiles), blob47 at the 8 (47 tiles).");
            bad = true;
        } else if (!e["mode"].is_string() || !autotile_mode_from_name(e["mode"].get<std::string>(), t.mode)) {
            const std::string given = e["mode"].is_string() ? e["mode"].get<std::string>() : json_text(e["mode"]);
            err(at + "/mode", "unknown terrain mode " + (e["mode"].is_string() ? "'" + given + "'" : given),
                e["mode"].is_string()
                    ? did_you_mean(given, kModes)
                    : "Use \"basic16\" (4 neighbours, 16 tiles) or \"blob47\" (8 neighbours, 47 tiles).");
            bad = true;
        } else {
            haveMode = true;
        }
        const int count = haveMode ? autotile_tile_count(t.mode) : 0;
        // seed
        if (e.contains("seed")) {
            if (!e["seed"].is_number_integer()) {
                err(at + "/seed", "seed must be an integer, got " + json_text(e["seed"]),
                    "The seed picks the variation of each cell: the same seed gives the same map. Example: \"seed\": "
                    "7.");
                bad = true;
            } else {
                t.seed = e["seed"].get<std::int64_t>();
            }
        }
        // outside
        if (e.contains("outside")) {
            const std::string o = e["outside"].is_string() ? e["outside"].get<std::string>() : std::string();
            if (o == "terrain")
                t.outsideIsTerrain = true;
            else if (o != "empty") {
                err(at + "/outside", "outside must be \"empty\" or \"terrain\", got " + json_text(e["outside"]),
                    o.empty() ? "\"terrain\": the map edge counts as this terrain (no border tiles there); \"empty\" "
                                "(default): it counts as nothing."
                              : did_you_mean(o, kOutside));
                bad = true;
            }
        }
        // joins (names are checked when every terrain is known)
        if (e.contains("joins")) {
            if (!e["joins"].is_array()) {
                err(at + "/joins", "joins must be an array of terrain names, got " + json_text(e["joins"]),
                    "Example: \"joins\": [\"path\"].");
                bad = true;
            } else {
                for (std::size_t j = 0; j < e["joins"].size(); ++j) {
                    if (!e["joins"][j].is_string()) {
                        err(at + "/joins/" + std::to_string(j), "joins entry " + std::to_string(j) +
                                                                    " must be a terrain name, got " +
                                                                    json_text(e["joins"][j]));
                        bad = true;
                    } else {
                        t.joins.push_back(e["joins"][j].get<std::string>());
                    }
                }
            }
        }
        // tiles / first
        const bool hasFirst = e.contains("first"), hasTiles = e.contains("tiles");
        if (hasFirst && hasTiles) {
            err(at, "terrain " + std::to_string(i) + " has both \"first\" and \"tiles\"",
                "Give one: \"first\" for a run of tiles, or \"tiles\" for a list per slot.");
            bad = true;
        } else if (!hasFirst && !hasTiles) {
            err(at, "terrain " + std::to_string(i) + (t.name.empty() ? "" : " ('" + t.name + "')") + " lists no tiles",
                "Give \"first\": N (the tileset index of its first tile; the " +
                    std::string(haveMode ? std::to_string(count) : "16 or 47") +
                    " tiles follow in slot order) or \"tiles\": [...] with one entry per slot. image.tileset.build "
                    "writes these for you.");
            bad = true;
        } else if (hasFirst) {
            if (!is_tile_value(e["first"]) || e["first"].get<double>() >= double(kTileFlipX)) {
                err(at + "/first", "first must be a tileset index (a whole number >= 0), got " + json_text(e["first"]),
                    "It is the index of the terrain's slot 0 tile in the tileset (left-to-right, top-to-bottom).");
                bad = true;
            } else if (haveMode) {
                const int first = e["first"].get<int>();
                for (int s = 0; s < count; ++s) t.slots.push_back({first + s});
            }
        } else {
            const Json& tiles = e["tiles"];
            if (!tiles.is_array()) {
                err(at + "/tiles", "tiles must be an array with one entry per slot, got " + json_text(tiles),
                    "Each entry is a tile index, or an array of tile indices (variations of that look).");
                bad = true;
            } else if (haveMode && int(tiles.size()) != count) {
                err(at + "/tiles",
                    "a " + std::string(autotile_mode_name(t.mode)) + " terrain needs " + std::to_string(count) +
                        " tiles, \"tiles\" has " + std::to_string(tiles.size()),
                    "One entry per slot, in the order of autotile_masks(" + std::string(autotile_mode_name(t.mode)) +
                        ") (image.tileset.info prints it). To use a run of consecutive tiles give \"first\" instead.");
                bad = true;
            } else if (haveMode) {
                for (std::size_t s = 0; s < tiles.size(); ++s) {
                    const Json& entry = tiles[s];
                    const std::string sat = at + "/tiles/" + std::to_string(s);
                    std::vector<int> picks;
                    if (is_tile_value(entry)) {
                        picks.push_back(entry.get<int>());
                    } else if (entry.is_array() && !entry.empty()) {
                        for (std::size_t v = 0; v < entry.size(); ++v) {
                            if (!is_tile_value(entry[v])) {
                                err(sat + "/" + std::to_string(v),
                                    "variation " + std::to_string(v) + " of slot " + std::to_string(s) +
                                        " must be a tile index, got " + json_text(entry[v]),
                                    "Tile indices are whole numbers >= 0 (plus optional flip flags, see "
                                    "Tilemap.tiles).");
                                bad = true;
                            } else {
                                picks.push_back(entry[v].get<int>());
                            }
                        }
                    } else {
                        err(sat,
                            "slot " + std::to_string(s) +
                                " must be a tile index or a non-empty array of tile indices, got " + json_text(entry),
                            "-1 (empty) is not allowed: every look of a terrain needs a tile.");
                        bad = true;
                    }
                    t.slots.push_back(std::move(picks));
                }
            }
        }
        if (!t.name.empty() && !byName.count(t.name)) byName[t.name] = i;
        if (!bad && haveMode && int(t.slots.size()) == count) {
            // a tile index belongs to one terrain only: that is how a cell says which terrain it is
            for (const auto& slot : t.slots)
                for (int v : slot) {
                    const int idx = tile_index(v);
                    auto [it, fresh] = owner.emplace(idx, t.name);
                    if (!fresh && it->second != t.name && !bad) {
                        err(at + "/tiles",
                            "tile " + std::to_string(idx) + " belongs to both terrain '" + it->second + "' and '" +
                                t.name + "'",
                            "A cell's tile says which terrain it is, so two terrains cannot share a tile index: give "
                            "each its own range of the tileset.");
                        bad = true;
                    }
                }
        }
        if (!bad) out.terrains.push_back(std::move(t));
    }
    for (std::size_t i = 0; i < out.terrains.size(); ++i) {
        for (const std::string& j : out.terrains[i].joins) {
            if (byName.count(j) && j != out.terrains[i].name) continue;
            std::vector<std::string> names;
            for (const auto& [n, idx] : byName) {
                (void)idx;
                if (n != out.terrains[i].name) names.push_back(n);
            }
            const std::size_t at = byName[out.terrains[i].name];
            err("/terrains/" + std::to_string(at) + "/joins",
                j == out.terrains[i].name
                    ? "terrain '" + j + "' lists itself in joins (it always joins itself)"
                    : "terrain '" + out.terrains[i].name + "' joins '" + j + "', which is not a terrain of this map",
                names.empty() ? "Add the terrain to \"terrains\" first." : did_you_mean(j, names));
        }
    }
    return out;
}

// One map being re-tiled: terrain lookups by tile index and the current size.
struct Retiler {
    Tilemap& tm;
    const std::vector<Terrain>& terrains;
    TilemapSize size;
    std::unordered_map<int, std::pair<int, int>> byTile;  // tile index -> (terrain, slot)
    std::vector<std::vector<bool>> joined;                // joined[a][b]: cells of b count as neighbours of a

    Retiler(Tilemap& t, const std::vector<Terrain>& ts) : tm(t), terrains(ts), size(tilemap_size(t)) {
        std::map<std::string, int> idx;
        for (std::size_t i = 0; i < terrains.size(); ++i) idx[terrains[i].name] = int(i);
        joined.assign(terrains.size(), std::vector<bool>(terrains.size(), false));
        for (std::size_t i = 0; i < terrains.size(); ++i) {
            joined[i][i] = true;
            for (const std::string& j : terrains[i].joins) joined[i][std::size_t(idx[j])] = true;
            for (std::size_t s = 0; s < terrains[i].slots.size(); ++s)
                for (int v : terrains[i].slots[s]) byTile.emplace(tile_index(v), std::make_pair(int(i), int(s)));
        }
    }

    int terrain_at(int col, int row) const {
        const int v = tilemap_tile_at(tm, size, col, row);
        if (v < 0) return -1;
        auto it = byTile.find(tile_index(v));
        return it == byTile.end() ? -1 : it->second.first;
    }

    bool in_map(int col, int row) const { return col >= 0 && row >= 0 && col < size.width && row < size.height; }

    bool counts(int self, int col, int row) const {
        if (!in_map(col, row)) return terrains[std::size_t(self)].outsideIsTerrain;
        const int other = terrain_at(col, row);
        return other >= 0 && joined[std::size_t(self)][std::size_t(other)];
    }

    int raw_mask(int self, int col, int row) const {
        int m = 0;
        if (counts(self, col, row - 1)) m |= kAutoN;
        if (counts(self, col + 1, row - 1)) m |= kAutoNE;
        if (counts(self, col + 1, row)) m |= kAutoE;
        if (counts(self, col + 1, row + 1)) m |= kAutoSE;
        if (counts(self, col, row + 1)) m |= kAutoS;
        if (counts(self, col - 1, row + 1)) m |= kAutoSW;
        if (counts(self, col - 1, row)) m |= kAutoW;
        if (counts(self, col - 1, row - 1)) m |= kAutoNW;
        return m;
    }

    // The tile a terrain cell should show; -1 when the cell is not a terrain cell.
    int wanted(int col, int row) const {
        const int self = terrain_at(col, row);
        if (self < 0) return -1;
        const Terrain& t = terrains[std::size_t(self)];
        const auto& picks = t.slots[std::size_t(autotile_slot(t.mode, raw_mask(self, col, row)))];
        return picks[autotile_hash(t.seed, col, row) % picks.size()];
    }

    void retile(int col, int row) {
        const int want = wanted(col, row);
        if (want < 0) return;
        if (tilemap_tile_at(tm, size, col, row) != want) set_tilemap_tile(tm, col, row, want);
    }
};

Error no_map_error() {
    return make_error("The tilemap has no cells to paint on (its size is 0 x 0).",
                      "Give it a size first: width, height and a tiles array (or rows), e.g. scene.set_component with "
                      "{\"width\": 20, \"height\": 12, \"tiles\": [...]}.");
}

}  // namespace

const char* autotile_mode_name(AutotileMode mode) { return mode == AutotileMode::Basic16 ? "basic16" : "blob47"; }

bool autotile_mode_from_name(const std::string& name, AutotileMode& out) {
    if (name == "basic16")
        out = AutotileMode::Basic16;
    else if (name == "blob47")
        out = AutotileMode::Blob47;
    else
        return false;
    return true;
}

int autotile_tile_count(AutotileMode mode) { return mode == AutotileMode::Basic16 ? 16 : 47; }

const std::vector<int>& autotile_masks(AutotileMode mode) { return tables(mode).masks; }

int autotile_reduce(AutotileMode mode, int raw) {
    raw &= 255;
    if (mode == AutotileMode::Basic16) return raw & (kAutoN | kAutoE | kAutoS | kAutoW);
    int m = raw;
    if (!((raw & kAutoN) && (raw & kAutoE))) m &= ~kAutoNE;
    if (!((raw & kAutoS) && (raw & kAutoE))) m &= ~kAutoSE;
    if (!((raw & kAutoS) && (raw & kAutoW))) m &= ~kAutoSW;
    if (!((raw & kAutoN) && (raw & kAutoW))) m &= ~kAutoNW;
    return m;
}

int autotile_slot(AutotileMode mode, int rawMask) { return tables(mode).slotOfRaw[std::size_t(rawMask & 255)]; }

std::uint32_t autotile_hash(std::int64_t seed, int col, int row) {
    std::uint64_t x = std::uint64_t(seed) * 0x9E3779B97F4A7C15ull +
                      std::uint64_t(std::uint32_t(col)) * 0xC2B2AE3D27D4EB4Full +
                      std::uint64_t(std::uint32_t(row)) * 0x165667B19E3779F9ull + 0x27D4EB2F165667C5ull;
    x ^= x >> 30;
    x *= 0xBF58476D1CE4E5B9ull;
    x ^= x >> 27;
    x *= 0x94D049BB133111EBull;
    x ^= x >> 31;
    return std::uint32_t(x >> 32);
}

Result<std::vector<Terrain>> parse_terrains(const Json& terrains) {
    ParseOut parsed = parse_impl(terrains);
    if (!parsed.issues.empty()) {
        const TilemapIssue& first = parsed.issues.front();
        std::string message = first.pointer + ": " + first.message;
        if (parsed.issues.size() > 1)
            message += " (and " + std::to_string(parsed.issues.size() - 1) + " more problem" +
                       (parsed.issues.size() > 2 ? "s" : "") + " in terrains)";
        return make_error(message, first.hint);
    }
    return std::move(parsed.terrains);
}

std::vector<TilemapIssue> check_terrains(const Json& terrains) { return parse_impl(terrains).issues; }

TerrainOfTile terrain_of_tile(const std::vector<Terrain>& terrains, int tileValue) {
    TerrainOfTile out;
    const int idx = tile_index(tileValue);
    if (idx < 0) return out;
    for (const Terrain& t : terrains)
        for (std::size_t s = 0; s < t.slots.size(); ++s)
            for (int v : t.slots[s])
                if (tile_index(v) == idx) {
                    out.terrain = t.name;
                    out.slot = int(s);
                    return out;
                }
    return out;
}

Result<TerrainPaintResult> paint_terrain(Tilemap& tm, const std::string& terrainName,
                                         const std::vector<std::pair<int, int>>& cells, bool erase) {
    auto parsed = parse_terrains(tm.terrains);
    if (!parsed.ok())
        return make_error("This tilemap's terrain rules are invalid: " + parsed.error().message, parsed.error().hint);
    const std::vector<Terrain>& terrains = *parsed;
    int self = -1;
    for (std::size_t i = 0; i < terrains.size(); ++i)
        if (terrains[i].name == terrainName) self = int(i);
    if (self < 0) {
        std::vector<std::string> names;
        for (const Terrain& t : terrains) names.push_back(t.name);
        if (names.empty())
            return make_error(
                "Unknown terrain '" + terrainName + "': this tilemap has no terrains.",
                "Add rules to the Tilemap component's \"terrains\" (tilemap.set_terrains, or image.tileset.build "
                "writes them), e.g. {\"name\": \"grass\", \"mode\": \"blob47\", \"first\": 0}.");
        return make_error("Unknown terrain '" + terrainName + "'.", did_you_mean(terrainName, names));
    }
    Retiler r(tm, terrains);
    if (r.size.empty()) return no_map_error();

    TerrainPaintResult result;
    std::set<std::pair<int, int>> touched;  // cells to re-tile and compare: the cells and their 8 neighbours
    std::vector<std::pair<int, int>> inside;
    for (const auto& c : cells) {
        if (!r.in_map(c.first, c.second)) {
            ++result.outside;
            continue;
        }
        inside.push_back(c);
        for (int dr = -1; dr <= 1; ++dr)
            for (int dc = -1; dc <= 1; ++dc)
                if (r.in_map(c.first + dc, c.second + dr)) touched.insert({c.first + dc, c.second + dr});
    }
    std::map<std::pair<int, int>, int> before;
    for (const auto& c : touched) before[c] = tilemap_tile_at(tm, r.size, c.first, c.second);

    const int placeholder = terrains[std::size_t(self)].slots[0][0];
    for (const auto& c : inside) {
        if (erase) {
            set_tilemap_tile(tm, c.first, c.second, -1);
        } else if (r.terrain_at(c.first, c.second) != self) {
            set_tilemap_tile(tm, c.first, c.second, placeholder);
        }
        ++result.painted;
    }
    for (const auto& c : touched) r.retile(c.first, c.second);
    for (const auto& c : touched) {
        const int now = tilemap_tile_at(tm, r.size, c.first, c.second);
        if (now != before[c]) result.changes.push_back({c.first, c.second, before[c], now});
    }
    return result;
}

Result<TerrainPaintResult> retile_terrains(Tilemap& tm) {
    auto parsed = parse_terrains(tm.terrains);
    if (!parsed.ok())
        return make_error("This tilemap's terrain rules are invalid: " + parsed.error().message, parsed.error().hint);
    if (parsed->empty())
        return make_error("This tilemap has no terrains to re-tile.",
                          "Add rules to the Tilemap component's \"terrains\" (tilemap.set_terrains).");
    Retiler r(tm, *parsed);
    if (r.size.empty()) return no_map_error();
    TerrainPaintResult result;
    std::vector<int> before(std::size_t(r.size.width) * std::size_t(r.size.height));
    for (int row = 0; row < r.size.height; ++row)
        for (int col = 0; col < r.size.width; ++col)
            before[std::size_t(row) * std::size_t(r.size.width) + std::size_t(col)] =
                tilemap_tile_at(tm, r.size, col, row);
    // the membership does not change while re-tiling (a terrain cell stays in its terrain), so the order is free
    for (int row = 0; row < r.size.height; ++row)
        for (int col = 0; col < r.size.width; ++col) r.retile(col, row);
    for (int row = 0; row < r.size.height; ++row)
        for (int col = 0; col < r.size.width; ++col) {
            const int was = before[std::size_t(row) * std::size_t(r.size.width) + std::size_t(col)];
            const int now = tilemap_tile_at(tm, r.size, col, row);
            if (was != now) result.changes.push_back({col, row, was, now});
        }
    return result;
}

void retile_terrain_grid(const std::vector<Terrain>& terrains, int width, int height, std::vector<int>& tiles) {
    if (terrains.empty() || width <= 0 || height <= 0 || tiles.size() != std::size_t(width) * std::size_t(height))
        return;
    Tilemap tm;
    set_tilemap_grid(tm, width, height, tiles);
    Retiler r(tm, terrains);
    for (int row = 0; row < height; ++row)
        for (int col = 0; col < width; ++col) r.retile(col, row);
    const TilemapGrid grid = tilemap_grid(tm);
    tiles = grid.tiles;
}

}  // namespace fa
