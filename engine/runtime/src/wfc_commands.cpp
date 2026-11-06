// tilemap.generate: a level made from an example (Wave Function Collapse). The algorithm and its determinism rules live in
// fa/scene/wfc.h; this file reads the sample (a Tilemap entity or ASCII rows in the format of scene.import_ascii), checks the
// arguments with errors that teach, runs the generator and writes the result into a Tilemap and/or returns it as ASCII rows.
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <limits>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/perf.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"
#include "fa/physics/nav.h"
#include "fa/scene/autotile.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/wfc.h"

namespace fa {

namespace {

constexpr int kDefaultMaxAttempts = 10;
constexpr int kDefaultConstraintAttempts = 50;                         // with constraints or reachability a refused grid is common: more attempts
constexpr long long kDefaultMaxWork = 600'000'000;                     // units of work (wfc::GenStats::work) over all attempts: the cap a result depends on (about 16 s of Debug CPU)
constexpr long long kMaxWorkLimit = 100'000'000'000;
constexpr double kDefaultMaxSeconds = 120.0;                           // CPU seconds of the process: a safety net far above what kDefaultMaxWork takes, even on a slow machine
constexpr double kMaxSecondsLimit = 600.0;
constexpr std::int64_t kFrameWork = 500'000;                           // default work of one tilemap.generate_step (the script API: per frame without a window)
constexpr std::int64_t kStepWork = 1 << 16;                            // work per step() call: the caps are checked between calls
constexpr std::size_t kReachPaths = 16;                                // paths the reachability report lists
constexpr std::size_t kReachAreas = 5;                                 // unreachable areas the report lists

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

[[noreturn]] void bad_arg(const std::string& message, const std::string& hint = {}) {
    throw CommandError("invalid_argument", message, hint);
}

bool whole_number(const Json& v, long long& out) {
    if (v.is_number_integer() || v.is_number_unsigned()) {
        out = v.get<long long>();
        return true;
    }
    if (v.is_number_float()) {
        const double d = v.get<double>();
        if (d == std::floor(d) && std::fabs(d) < 9e15) {
            out = static_cast<long long>(d);
            return true;
        }
    }
    return false;
}

int int_arg(const Json& a, const char* key, int fallback, int lo, int hi, const std::string& hint) {
    if (!a.contains(key)) return fallback;
    long long v = 0;
    if (!whole_number(a[key], v)) bad_arg(std::string("'") + key + "' must be a whole number, got " + describe_json_value(a[key]), hint);
    if (v < lo || v > hi)
        bad_arg(std::string("'") + key + "' is " + std::to_string(v) + " but it must be between " + std::to_string(lo) + " and " + std::to_string(hi), hint);
    return int(v);
}

bool bool_arg(const Json& a, const char* key, bool fallback) {
    if (!a.contains(key)) return fallback;
    if (!a[key].is_boolean()) bad_arg(std::string("'") + key + "' must be true or false, got " + describe_json_value(a[key]), std::string("Example: \"") + key + "\": true.");
    return a[key].get<bool>();
}

void parse_size(const Json& a, int& w, int& h) {
    const std::string hint = "Give the output size in cells: [width, height], {\"width\": 64, \"height\": 40} or one number for a square. Each side is 1.." +
                             std::to_string(wfc::kMaxOutputSide) + ".";
    if (!a.contains("size")) bad_arg("Missing 'size'", hint);
    const Json& s = a["size"];
    long long x = 0, y = 0;
    auto bad = [&] { bad_arg("'size' must be [width, height], {width, height} or one whole number, got " + describe_json_value(s), hint); };
    if (s.is_array()) {
        if (s.size() != 2 || !whole_number(s[0], x) || !whole_number(s[1], y)) bad();
    } else if (s.is_object()) {
        if (!s.contains("width") || !s.contains("height") || !whole_number(s["width"], x) || !whole_number(s["height"], y)) bad();
    } else if (whole_number(s, x)) {
        y = x;
    } else {
        bad();
    }
    if (x < 1 || y < 1 || x > wfc::kMaxOutputSide || y > wfc::kMaxOutputSide)
        bad_arg("'size' is " + std::to_string(x) + " x " + std::to_string(y) + " but each side must be between 1 and " + std::to_string(wfc::kMaxOutputSide), hint);
    w = int(x);
    h = int(y);
}

std::string one_decimal(double v) {
    char buf[32];
    std::snprintf(buf, sizeof buf, "%.1f", v);
    return buf;
}

[[noreturn]] void throw_error(const Error& e) { throw CommandError("invalid_argument", e.message, e.hint); }

// ------------------------------------------------------------------------------------------------------------ the sample
struct SampleData {
    bool present = false;
    bool ascii = false;
    std::string source;              // "the Tilemap of entity 'rooms'" / "the ASCII rows"
    int width = 0;
    int height = 0;
    std::vector<int> tiles;          // tile value of every cell (-1 = none); for ASCII the tile of the cell's glyph
    AsciiSample glyphs;              // ASCII samples: the cells are indexes into glyphs.glyphs
    Json terrains = Json::array();   // the Tilemap's autotile rules (entity samples)
    Json solidTiles = Json::array(); // the tiles that block: Tilemap.solidTiles of an entity sample, `tilemap.solidTiles` of ASCII arguments
};

Json ascii_args_from(const Json& a, const Json& sample) {
    Json src = Json::object();
    if (sample.is_array()) {
        src["rows"] = sample;
    } else if (sample.is_object()) {
        src = sample;
    } else {  // a string with line breaks
        std::string text = sample.get<std::string>();
        Json rows = Json::array();
        std::size_t start = 0;
        while (start <= text.size()) {
            std::size_t nl = text.find('\n', start);
            std::string line = text.substr(start, nl == std::string::npos ? std::string::npos : nl - start);
            if (!line.empty() && line.back() == '\r') line.pop_back();
            if (nl == std::string::npos) {
                if (!line.empty()) rows.push_back(line);
                break;
            }
            rows.push_back(line);
            start = nl + 1;
        }
        src["rows"] = rows;
    }
    if (a.contains("legendFrom")) src["legendFrom"] = a["legendFrom"];
    if (a.contains("legend")) {
        if (!a["legend"].is_object()) bad_arg("'legend' must be an object mapping one-character glyphs to a tile index or an object, got " + describe_json_value(a["legend"]));
        Json merged = src.contains("legend") && src["legend"].is_object() ? src["legend"] : Json::object();
        for (auto it = a["legend"].begin(); it != a["legend"].end(); ++it) merged[it.key()] = it.value();
        src["legend"] = merged;
    }
    return src;
}

SampleData read_sample(Engine::Impl& I, const Json& a) {
    SampleData out;
    if (!a.contains("sample")) return out;
    const Json& s = a["sample"];
    out.present = true;
    const std::string hint =
        "`sample` is the id of an entity with a Tilemap, ASCII rows (an array of strings, or one string with line breaks) with a `legend`, an object "
        "{rows, legend?, legendFrom?} (the arguments of scene.import_ascii), or the path of a JSON file with such an object.";

    Json asciiArgs;
    if (s.is_string()) {
        const std::string text = s.get<std::string>();
        if (text.empty()) bad_arg("'sample' is an empty string, so there is nothing to learn from", hint);
        if (text.find('\n') != std::string::npos) {
            asciiArgs = ascii_args_from(a, s);
            out.source = "the ASCII rows of `sample`";
        } else if (ends_with(to_lower(text), ".json")) {
            auto norm = fs::normalize_checked(text);
            if (!norm.ok()) bad_arg("'sample': " + norm.error().message, norm.error().hint);
            if (!fs::exists(norm.value())) {
                std::vector<std::string> jsons = fs::list("", true, ".json");
                throw CommandError("not_found", "The sample file '" + norm.value() + "' does not exist. " + did_you_mean(norm.value(), jsons),
                                   "It is a JSON file with scene.import_ascii arguments: {\"rows\": [...], \"legend\": {...}}.");
            }
            auto doc = load_json_file(norm.value());
            if (!doc.ok()) bad_arg("The sample file '" + norm.value() + "': " + doc.error().message, doc.error().hint);
            if (!doc->is_object() || !doc->contains("rows"))
                bad_arg("The sample file '" + norm.value() + "' has no \"rows\": it is not a scene.import_ascii arguments file",
                        "Write {\"rows\": [\"#..#\", ...], \"legend\": {\"#\": 0}} in it.");
            asciiArgs = ascii_args_from(a, *doc);
            out.source = "the ASCII rows of '" + norm.value() + "'";
        } else {
            Entity e = I.world.find(text);
            if (!e) {
                std::vector<std::string> names;
                I.world.each<Tilemap>([&](Entity en, Tilemap&) { names.push_back(I.world.id_of(en)); });
                throw CommandError("not_found", "'sample' is '" + text + "': no entity has that id or name. " + did_you_mean(text, names),
                                   hint + " A single line of ASCII is not recognised as rows: pass an array [\"#..#\"] or add a line break.");
            }
            const Tilemap* tm = I.world.get<Tilemap>(e);
            if (!tm)
                bad_arg("Entity '" + text + "' has no Tilemap component, so it cannot be a sample", "Pass the id of an entity with a Tilemap, or ASCII rows. " + hint);
            const TilemapGrid grid = tilemap_grid(*tm);
            if (grid.empty()) bad_arg("The Tilemap of entity '" + text + "' is empty (0 x 0 tiles): there is nothing to learn from", "Paint or import a small example level first (scene.import_ascii).");
            out.width = grid.width;
            out.height = grid.height;
            out.tiles = grid.tiles;
            out.terrains = tm->terrains;
            out.solidTiles = tm->solidTiles;
            out.source = "the Tilemap of entity '" + I.world.id_of(e) + "'";
            return out;
        }
    } else if (s.is_array() || s.is_object()) {
        asciiArgs = ascii_args_from(a, s);
        out.source = "the ASCII rows of `sample`";
    } else {
        bad_arg("'sample' must be an entity id, ASCII rows or an object, got " + describe_json_value(s), hint);
    }
    out.ascii = true;
    if (asciiArgs.is_object() && asciiArgs.contains("tilemap") && asciiArgs["tilemap"].is_object() && asciiArgs["tilemap"].contains("solidTiles"))
        out.solidTiles = asciiArgs["tilemap"]["solidTiles"];
    out.glyphs = read_ascii_sample(asciiArgs);
    out.width = out.glyphs.width;
    out.height = out.glyphs.height;
    for (int g : out.glyphs.cells) out.tiles.push_back(out.glyphs.glyphs[std::size_t(g)].tile);
    return out;
}

// ------------------------------------------------------------------------------------------------------------ glyphs
// The ASCII form of a generated level: which character stands for which tile, with a legend scene.import_ascii accepts.
class GlyphBook {
public:
    explicit GlyphBook(const SampleData& sample) {
        if (!sample.ascii) return;
        for (const AsciiSampleGlyph& g : sample.glyphs.glyphs) {
            reserved_.insert(g.glyph);
            if (!g.hasPrefab && !tileGlyph_.count(g.tile)) {
                tileGlyph_[g.tile] = g.glyph;
                entry_[g.glyph] = g.legendEntry;
            }
        }
    }

    // The glyph for a tile value, and (in `legend`) its entry.
    const std::string& glyph_for_tile(int tile) {
        auto it = tileGlyph_.find(tile);
        if (it != tileGlyph_.end()) return it->second;
        std::string g;
        if (tile < 0 && !reserved_.count(".")) {
            g = ".";
        } else {
            g = next_palette();
        }
        reserved_.insert(g);
        entry_[g] = tile < 0 && g == "." ? Json() : Json(tile);
        return tileGlyph_.emplace(tile, g).first->second;
    }

    void use(const std::string& glyph, Json& legend) const {
        auto it = entry_.find(glyph);
        if (it != entry_.end() && !it->second.is_null()) legend[glyph] = it->second;
    }

private:
    std::string next_palette() {
        static const std::string kFirst = "#%=+*~^@&$:;-_|!?<>/\\ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        for (;;) {
            std::string g;
            if (paletteIndex_ < kFirst.size()) g = std::string(1, kFirst[paletteIndex_]);
            else g = utf8_encode(char32_t(0x100 + (paletteIndex_ - kFirst.size())));  // Latin Extended and beyond: one code point per glyph
            ++paletteIndex_;
            if (!reserved_.count(g)) return g;
        }
    }

    std::set<std::string> reserved_;
    std::map<int, std::string> tileGlyph_;
    std::map<std::string, Json> entry_;
    std::size_t paletteIndex_ = 0;
};

// ------------------------------------------------------------------------------------------------------------ tile references
// What a constraint's `tile` means in this model: the glyphs of an ASCII sample, the tile numbers of a Tilemap sample or of the
// tiled model (and the names of its terrains), -1 for an empty cell.
struct ModelView {
    bool tiled = false;
    const SampleData* sample = nullptr;
    const std::vector<int>* symbolTile = nullptr;   // symbol -> tile value (not for ASCII overlapping)
    const std::vector<Terrain>* terrains = nullptr;
    int symbolCount = 0;

    bool glyph_symbols() const { return !tiled && sample && sample->ascii; }
    // The tile value a symbol stands for (-1 = empty or a glyph without a tile).
    int tile_of(int symbol) const {
        if (glyph_symbols()) return sample->glyphs.glyphs[std::size_t(symbol)].tile;
        return (*symbolTile)[std::size_t(symbol)];
    }
    bool has_prefab(int symbol) const { return glyph_symbols() && sample->glyphs.glyphs[std::size_t(symbol)].hasPrefab; }
};

struct TileRefs {
    std::vector<int> symbols;   // ascending, no duplicates
    std::string label;          // "'#'", "tile 3", "terrain 'grass'"
};

std::string options_list(const ModelView& mv) {
    std::string out;
    int shown = 0;
    if (mv.glyph_symbols()) {
        for (const AsciiSampleGlyph& g : mv.sample->glyphs.glyphs) {
            if (shown++ == 12) return out + ", ...";
            out += (out.empty() ? "'" : ", '") + g.glyph + "'";
        }
        return out;
    }
    std::set<int> tiles;
    for (int s = 0; s < mv.symbolCount; ++s) tiles.insert(mv.tile_of(s));
    for (int t : tiles) {
        if (shown++ == 12) return out + ", ...";
        out += (out.empty() ? "" : ", ") + std::to_string(t);
    }
    if (mv.tiled && mv.terrains) {
        std::string names;
        for (const Terrain& t : *mv.terrains) names += (names.empty() ? "'" : ", '") + t.name + "'";
        out += "; terrains " + names;
    }
    return out;
}

TileRefs resolve_refs(const ModelView& mv, const Json& v, const std::string& pointer) {
    TileRefs out;
    std::set<int> found;
    auto one = [&](const Json& r, const std::string& at) {
        std::vector<int> matched;
        std::string label;
        if (r.is_string()) {
            const std::string text = r.get<std::string>();
            if (mv.glyph_symbols()) {
                label = "'" + text + "'";
                std::vector<std::string> names;
                for (int s = 0; s < mv.symbolCount; ++s) {
                    names.push_back(mv.sample->glyphs.glyphs[std::size_t(s)].glyph);
                    if (names.back() == text) matched.push_back(s);
                }
                if (matched.empty())
                    bad_arg(at + ": the glyph '" + text + "' is not in the sample, so the generated level never has it. " + did_you_mean(text, names),
                            "Name a glyph of the sample (" + options_list(mv) + ") or a tile number.");
            } else if (mv.tiled && mv.terrains) {
                label = "terrain '" + text + "'";
                std::set<int> values;
                std::vector<std::string> names;
                for (const Terrain& t : *mv.terrains) {
                    names.push_back(t.name);
                    if (t.name != text) continue;
                    for (const auto& slot : t.slots)
                        for (int tv : slot) values.insert(tv);
                }
                for (int s = 0; s < mv.symbolCount; ++s)
                    if (values.count(mv.tile_of(s))) matched.push_back(s);
                if (matched.empty())
                    bad_arg(at + ": '" + text + "' is not a terrain of the rules. " + did_you_mean(text, names),
                            "Name a terrain (" + options_list(mv) + ") or a tile number.");
            } else {
                bad_arg(at + ": a glyph like '" + text + "' only names a tile when the sample is ASCII rows; this model's tiles are numbers",
                        "Use the tile number (-1 = empty cell). Tiles: " + options_list(mv) + ".");
            }
        } else if (r.is_number_integer() || r.is_number_unsigned()) {
            const long long ref = r.get<long long>();
            label = ref < 0 ? "the empty tile" : "tile " + std::to_string(ref);
            // A plain index matches the tile however it is turned; a value with flip bits matches exactly that one.
            const bool exact = ref >= 0 && (ref & kTileFlagMask) != 0;
            for (int s = 0; s < mv.symbolCount; ++s) {
                if (mv.has_prefab(s)) continue;   // a glyph that spawns an object is named by its glyph
                const int t = mv.tile_of(s);
                const bool same = ref < 0 ? t < 0 : (t >= 0 && (exact ? static_cast<long long>(t) == ref : tile_index(t) == ref));
                if (same) matched.push_back(s);
            }
            if (matched.empty())
                bad_arg(at + ": " + label + " is not in " + (mv.tiled ? "the tiled model" : "the sample") + ", so the generated level never has it",
                        "Tiles here: " + options_list(mv) + (mv.tiled ? "" : ". Draw it in the sample first (the generator only places what the sample shows)."));
        } else {
            bad_arg(at + ": a tile is a glyph (\"#\"), a tile number (3, -1 = empty)" + std::string(mv.tiled ? " or a terrain name" : "") + ", got " + describe_json_value(r),
                    "Example: \"tile\": \"#\" for an ASCII sample, \"tile\": 3 for a tile number.");
        }
        found.insert(matched.begin(), matched.end());
        out.label += (out.label.empty() ? "" : "/") + label;
    };
    if (v.is_array()) {
        if (v.empty()) bad_arg(pointer + ": the list of tiles is empty", "List at least one tile, e.g. [\"#\"].");
        for (std::size_t i = 0; i < v.size(); ++i) one(v[i], pointer + "/" + std::to_string(i));
    } else {
        one(v, pointer);
    }
    out.symbols.assign(found.begin(), found.end());
    return out;
}

// ------------------------------------------------------------------------------------------------------------ constraints
struct Constraints {
    std::vector<wfc::CellRule> cellRules;
    std::vector<int> forbidden;
    std::vector<wfc::CountRule> counts;
    std::vector<std::string> countLabels;
    int fixedCells = 0;
    bool any() const { return !cellRules.empty() || !forbidden.empty() || !counts.empty(); }
};

void unknown_keys(const Json& obj, const std::set<std::string>& known, const std::string& pointer) {
    std::vector<std::string> list(known.begin(), known.end());
    for (auto it = obj.begin(); it != obj.end(); ++it)
        if (!known.count(it.key()))
            bad_arg(pointer + ": unknown key '" + it.key() + "'. " + did_you_mean(it.key(), list), "Keys here: " + join(list, ", ") + ".");
}

int cell_coord(const Json& v, const std::string& pointer, int lo, int hi, const char* what) {
    long long x = 0;
    if (!whole_number(v, x)) bad_arg(pointer + ": " + what + " must be a whole number, got " + describe_json_value(v));
    if (x < lo || x > hi)
        bad_arg(pointer + ": " + what + " is " + std::to_string(x) + " but the output has " + what + " 0.." + std::to_string(hi),
                "Cells count from 0 at the top-left: x is the column, y the row.");
    return int(x);
}

void parse_cell(const Json& v, const std::string& pointer, int width, int height, int& x, int& y) {
    if (!v.is_array() || v.size() != 2)
        bad_arg(pointer + ": a cell is [x, y], got " + describe_json_value(v), "Example: [3, 0]. x is the column, y the row, from 0 at the top-left.");
    x = cell_coord(v[0], pointer + "/0", 0, width - 1, "x");
    y = cell_coord(v[1], pointer + "/1", 0, height - 1, "y");
}

Constraints parse_constraints(const Json& a, const ModelView& mv, int width, int height) {
    Constraints out;
    if (!a.contains("constraints")) return out;
    const Json& c = a["constraints"];
    const std::string base = "/constraints";
    if (!c.is_object())
        bad_arg(base + ": 'constraints' must be an object, got " + describe_json_value(c),
                "Example: {\"fixed\":[{\"at\":[1,1],\"tile\":\"@\"}],\"forbidden\":[\"%\"],\"required\":[\"$\"],\"counts\":[{\"tile\":\"E\",\"max\":3}],\"border\":{\"tile\":\"#\"}}.");
    unknown_keys(c, {"fixed", "border", "forbidden", "required", "counts"}, base);
    auto list_of = [&](const char* key) -> const Json* {
        if (!c.contains(key)) return nullptr;
        if (!c[key].is_array()) bad_arg(base + "/" + key + ": must be an array, got " + describe_json_value(c[key]));
        return &c[key];
    };

    std::set<int> forbidden;
    std::vector<std::pair<std::set<int>, std::string>> forbiddenSources;
    if (const Json* f = list_of("forbidden"))
        for (std::size_t i = 0; i < f->size(); ++i) {
            const std::string at = base + "/forbidden/" + std::to_string(i);
            TileRefs r = resolve_refs(mv, (*f)[i], at);
            forbiddenSources.push_back({std::set<int>(r.symbols.begin(), r.symbols.end()), at});
            forbidden.insert(r.symbols.begin(), r.symbols.end());
        }
    auto forbidden_source = [&](int symbol) {
        for (const auto& src : forbiddenSources)
            if (src.first.count(symbol)) return src.second;
        return std::string();
    };

    // Fixed cells: the border first, explicit cells over it.
    struct Fixed {
        std::set<int> allowed;
        std::string pointer;
        std::string label;
        bool fromBorder = false;
    };
    std::map<int, Fixed> cells;   // output cell index -> what it may hold
    auto put = [&](int x, int y, const TileRefs& refs, const std::string& pointer, bool border) {
        const int index = y * width + x;
        auto it = cells.find(index);
        if (it == cells.end()) {
            if (cells.size() >= wfc::kMaxCellRules)
                bad_arg(pointer + ": more than " + std::to_string(wfc::kMaxCellRules) + " cells are fixed (the limit of one level; each costs work on every attempt)",
                        "Fix only what the level needs (an entrance, an exit, a border or a small rect) and let the sample fill the rest.");
            cells[index] = Fixed{std::set<int>(refs.symbols.begin(), refs.symbols.end()), pointer, refs.label, border};
            return;
        }
        if (it->second.fromBorder && !border) {   // an explicit cell replaces the border's
            it->second = Fixed{std::set<int>(refs.symbols.begin(), refs.symbols.end()), pointer, refs.label, false};
            return;
        }
        if (border) return;
        std::set<int> both;
        for (int s : refs.symbols)
            if (it->second.allowed.count(s)) both.insert(s);
        if (both.empty())
            bad_arg(pointer + ": the cell (" + std::to_string(x) + ", " + std::to_string(y) + ") is fixed to " + refs.label + " here and to " + it->second.label + " at " + it->second.pointer +
                        ": no tile satisfies both",
                    "Give each cell one tile; a cell listed twice must share a tile.");
        it->second.allowed = both;
        it->second.pointer = pointer;
    };
    if (c.contains("border")) {
        const Json& b = c["border"];
        const std::string at = base + "/border";
        if (!b.is_object() || !b.contains("tile"))
            bad_arg(at + ": 'border' is {\"tile\": <tile>, \"thickness\": 1}, got " + describe_json_value(b), "Example: \"border\": {\"tile\": \"#\"} walls in the edge of the level.");
        unknown_keys(b, {"tile", "thickness"}, at);
        TileRefs refs = resolve_refs(mv, b["tile"], at + "/tile");
        long long thickness = 1;
        if (b.contains("thickness") && !whole_number(b["thickness"], thickness)) bad_arg(at + "/thickness: must be a whole number, got " + describe_json_value(b["thickness"]));
        if (thickness < 1 || thickness > std::min(width, height))
            bad_arg(at + "/thickness: is " + std::to_string(thickness) + " but it must be between 1 and " + std::to_string(std::min(width, height)) + " for a " + std::to_string(width) + " x " + std::to_string(height) + " level");
        for (int y = 0; y < height; ++y)
            for (int x = 0; x < width; ++x)
                if (x < thickness || y < thickness || x >= width - thickness || y >= height - thickness) put(x, y, refs, at, true);
    }
    if (const Json* f = list_of("fixed"))
        for (std::size_t i = 0; i < f->size(); ++i) {
            const Json& e = (*f)[i];
            const std::string at = base + "/fixed/" + std::to_string(i);
            if (e.is_object()) unknown_keys(e, {"at", "rect", "tile"}, at);
            if (!e.is_object() || !e.contains("tile") || (e.contains("at") == e.contains("rect")))
                bad_arg(at + ": a fixed entry is {\"at\": [x, y], \"tile\": <tile>} or {\"rect\": [x, y, width, height], \"tile\": <tile>}, got " + describe_json_value(e),
                        "Example: {\"at\":[1,1],\"tile\":\"@\"} puts the entrance at the top-left corner; give `at` or `rect`, not both.");
            TileRefs refs = resolve_refs(mv, e["tile"], at + "/tile");
            if (e.contains("at")) {
                int x = 0, y = 0;
                parse_cell(e["at"], at + "/at", width, height, x, y);
                put(x, y, refs, at, false);
            } else {
                const Json& r = e["rect"];
                if (!r.is_array() || r.size() != 4) bad_arg(at + "/rect: a rect is [x, y, width, height], got " + describe_json_value(r), "Example: [0, 0, 8, 1] is the top row's first 8 cells.");
                int x = cell_coord(r[0], at + "/rect/0", 0, width - 1, "x");
                int y = cell_coord(r[1], at + "/rect/1", 0, height - 1, "y");
                long long w = 0, h = 0;
                if (!whole_number(r[2], w) || !whole_number(r[3], h) || w < 1 || h < 1 || x + w > width || y + h > height)
                    bad_arg(at + "/rect: the rect " + describe_json_value(r) + " must have a width and height of at least 1 and stay inside the " + std::to_string(width) + " x " + std::to_string(height) + " level");
                for (int yy = y; yy < y + int(h); ++yy)
                    for (int xx = x; xx < x + int(w); ++xx) put(xx, yy, refs, at, false);
            }
        }
    for (const auto& kv : cells) {
        const int x = kv.first % width, y = kv.first / width;
        std::vector<int> allowed;
        for (int s : kv.second.allowed)
            if (!forbidden.count(s)) allowed.push_back(s);
        if (allowed.empty()) {
            const std::string other = forbidden_source(*kv.second.allowed.begin());
            bad_arg(kv.second.pointer + ": the cell (" + std::to_string(x) + ", " + std::to_string(y) + ") is fixed to " + kv.second.label + ", which is also forbidden" +
                        (other.empty() ? std::string() : " at " + other),
                    "Remove it from `forbidden` or fix the cell to another tile.");
        }
        out.cellRules.push_back({x, y, allowed, kv.second.pointer});
    }
    out.fixedCells = int(cells.size());
    out.forbidden.assign(forbidden.begin(), forbidden.end());

    // Counts: `required` is a minimum of one, `counts` says min and max.
    long long sumMin = 0;
    const long long cellsTotal = static_cast<long long>(width) * height;
    std::vector<std::pair<std::set<int>, std::string>> minSets;
    auto add_count = [&](const TileRefs& refs, long long mn, long long mx, const std::string& at) {
        std::vector<int> usable;
        for (int s : refs.symbols)
            if (!forbidden.count(s)) usable.push_back(s);
        if (usable.empty() && mn > 0)
            bad_arg(at + ": " + refs.label + " must appear at least " + std::to_string(mn) + " time(s) but it is also forbidden at " + forbidden_source(refs.symbols.front()),
                    "Remove it from `forbidden`, or from `required` / `counts`.");
        wfc::CountRule rule;
        rule.symbols = refs.symbols;
        // Both fit the output (a minimum above it was refused by the caller); a maximum above it is the same as no maximum.
        rule.min = int(std::min(mn, cellsTotal));
        rule.max = mx < 0 ? -1 : int(std::min(mx, cellsTotal));
        rule.name = refs.label + " (" + at + ")";
        out.counts.push_back(rule);
        out.countLabels.push_back(refs.label);
        if (mn > 0) {
            sumMin += mn;
            minSets.push_back({std::set<int>(refs.symbols.begin(), refs.symbols.end()), at});
        }
    };
    if (const Json* r = list_of("required"))
        for (std::size_t i = 0; i < r->size(); ++i) {
            const std::string at = base + "/required/" + std::to_string(i);
            add_count(resolve_refs(mv, (*r)[i], at), 1, -1, at);
        }
    if (const Json* k = list_of("counts"))
        for (std::size_t i = 0; i < k->size(); ++i) {
            const Json& e = (*k)[i];
            const std::string at = base + "/counts/" + std::to_string(i);
            if (e.is_object()) unknown_keys(e, {"tile", "min", "max"}, at);
            if (!e.is_object() || !e.contains("tile") || (!e.contains("min") && !e.contains("max")))
                bad_arg(at + ": a count is {\"tile\": <tile>, \"min\": 1, \"max\": 3} with `min`, `max` or both, got " + describe_json_value(e),
                        "Example: {\"tile\":\"E\",\"max\":3} allows at most 3 enemies; {\"tile\":\"$\",\"min\":2,\"max\":5} wants 2 to 5 treasures.");
            long long mn = 0, mx = -1;
            if (e.contains("min") && (!whole_number(e["min"], mn) || mn < 0)) bad_arg(at + "/min: must be a whole number of 0 or more, got " + describe_json_value(e["min"]));
            if (e.contains("max") && (!whole_number(e["max"], mx) || mx < 0)) bad_arg(at + "/max: must be a whole number of 0 or more, got " + describe_json_value(e["max"]));
            if (mx >= 0 && mn > mx) bad_arg(at + ": min " + std::to_string(mn) + " is greater than max " + std::to_string(mx), "Make min at most max.");
            if (mn > cellsTotal)
                bad_arg(at + "/min: " + std::to_string(mn) + " cells are required but the output has only " + std::to_string(cellsTotal), "Ask for a bigger `size` or a smaller min.");
            add_count(resolve_refs(mv, e["tile"], at + "/tile"), mn, mx, at);
        }
    // Minimums of tiles that exclude each other add up: they must fit in the output.
    bool disjoint = true;
    for (std::size_t i = 0; i < minSets.size() && disjoint; ++i)
        for (std::size_t j = i + 1; j < minSets.size() && disjoint; ++j)
            for (int s : minSets[i].first)
                if (minSets[j].first.count(s)) {
                    disjoint = false;
                    break;
                }
    if (disjoint && sumMin > cellsTotal)
        bad_arg(base + ": the minimums add up to " + std::to_string(sumMin) + " cells but the output has only " + std::to_string(cellsTotal),
                "Ask for a bigger `size` or lower the minimums in `required` and `counts`.");
    return out;
}

// ------------------------------------------------------------------------------------------------------------ reachability
struct ReachSpec {
    bool enabled = false;
    bool hasFrom = false;
    int fromX = 0, fromY = 0;
    std::vector<std::pair<int, int>> toCells;   // explicit cells that must be reachable
    std::vector<int> toSymbols;                 // every cell holding one of these symbols must be reachable
    std::string toLabel;
    bool allConnected = false;
    bool diagonals = false;
    std::vector<int> solid;                     // tile indices that block
    std::vector<std::pair<int, float>> costs;   // tile index -> cost override (< 0 blocks), sorted
};

// The cost of entering a tile index: solid tiles block (-1), everything else costs 1, and `costs` overrides either per tile index.
float tile_cost(const ReachSpec& spec, int idx) {
    float cost = std::find(spec.solid.begin(), spec.solid.end(), idx) != spec.solid.end() ? -1.0f : 1.0f;
    auto o = std::lower_bound(spec.costs.begin(), spec.costs.end(), std::make_pair(idx, -std::numeric_limits<float>::infinity()));
    if (o != spec.costs.end() && o->first == idx) cost = o->second;
    return cost;
}

ReachSpec parse_reachability(const Json& a, const ModelView& mv, const SampleData& sample, const Tilemap* into, const Constraints& cons, int width, int height) {
    ReachSpec spec;
    if (!a.contains("reachability")) return spec;
    const Json& r = a["reachability"];
    const std::string base = "/reachability";
    if (!r.is_object())
        bad_arg(base + ": 'reachability' must be an object, got " + describe_json_value(r),
                "Example: {\"from\":[1,1],\"to\":[[30,18]],\"toTiles\":[\"$\"],\"allConnected\":true,\"solidTiles\":[0]}.");
    unknown_keys(r, {"from", "to", "toTiles", "allConnected", "solidTiles", "costs", "diagonals"}, base);
    spec.enabled = true;
    if (r.contains("from")) {
        parse_cell(r["from"], base + "/from", width, height, spec.fromX, spec.fromY);
        spec.hasFrom = true;
    }
    if (r.contains("to")) {
        const Json& t = r["to"];
        if (!t.is_array() || t.empty()) bad_arg(base + "/to: must be one cell [x, y] or a list of cells [[x, y], ...], got " + describe_json_value(t));
        auto push = [&](const Json& c, const std::string& at) {
            int x = 0, y = 0;
            parse_cell(c, at, width, height, x, y);
            spec.toCells.push_back({x, y});
        };
        if (t[0].is_number()) push(t, base + "/to");
        else
            for (std::size_t i = 0; i < t.size(); ++i) push(t[i], base + "/to/" + std::to_string(i));
    }
    if (r.contains("toTiles")) {
        TileRefs refs = resolve_refs(mv, r["toTiles"], base + "/toTiles");
        spec.toSymbols = refs.symbols;
        spec.toLabel = refs.label;
    }
    spec.allConnected = bool_arg(r, "allConnected", false);
    spec.diagonals = bool_arg(r, "diagonals", false);
    if ((!spec.toCells.empty() || !spec.toSymbols.empty()) && !spec.hasFrom)
        bad_arg(base + ": `to` and `toTiles` need a start: add \"from\": [x, y]", "Example: {\"from\":[1,1],\"to\":[[30,18]]} checks that the exit can be reached from the entrance.");
    if (!spec.hasFrom && !spec.allConnected)
        bad_arg(base + ": it checks nothing: give `from` with `to` / `toTiles`, or \"allConnected\": true", "Example: {\"from\":[1,1],\"to\":[[30,18]]}.");

    // Which tiles block: the call's own list, else the Tilemap the level goes into, else the sample's.
    const Json* solid = nullptr;
    if (r.contains("solidTiles")) {
        if (!r["solidTiles"].is_array()) bad_arg(base + "/solidTiles: must be a list of tile numbers, got " + describe_json_value(r["solidTiles"]), "Example: \"solidTiles\": [0, 2].");
        solid = &r["solidTiles"];
    } else if (into && into->solidTiles.is_array() && !into->solidTiles.empty()) {
        solid = &into->solidTiles;
    } else if (sample.solidTiles.is_array() && !sample.solidTiles.empty()) {
        solid = &sample.solidTiles;
    }
    if (!solid)
        bad_arg(base + ": it needs to know which tiles block the way and none were found (no `solidTiles` here, in the `into` Tilemap or in the sample)",
                "Add \"solidTiles\": [0] (the tile numbers that are walls) to `reachability`, or set Tilemap.solidTiles on `into`. Those are the rules nav.find_tile_path uses on the finished level too.");
    for (const Json& j : *solid) {
        long long v = 0;
        if (!whole_number(j, v)) bad_arg(base + "/solidTiles: tile numbers only, got " + describe_json_value(j));
        if (v < -1 || v > std::numeric_limits<int>::max()) bad_arg(base + "/solidTiles: the tile number " + std::to_string(v) + " is out of range", "Tile numbers are 0 or more (-1 is the empty cell).");
        spec.solid.push_back(tile_index(int(v)));
    }
    if (r.contains("costs")) {
        const Json& c = r["costs"];
        if (!c.is_object()) bad_arg(base + "/costs: must be {\"<tile>\": cost | null}, got " + describe_json_value(c), "Same as nav.find_tile_path: {\"3\": 2.5, \"7\": null}; null blocks, key \"-1\" is the empty cell.");
        for (auto it = c.begin(); it != c.end(); ++it) {
            long long key = 0;
            try {
                key = std::stoll(it.key());
            } catch (...) {
                bad_arg(base + "/costs: the key '" + it.key() + "' is not a tile number", "Keys are tile numbers as text: {\"3\": 2.5}.");
            }
            if (key < -1 || key > kTileIndexMask) bad_arg(base + "/costs: the tile number " + it.key() + " is out of range");
            const float v = it.value().is_number() ? it.value().get<float>() : -1.0f;
            spec.costs.push_back({int(key), v < 0.0f || std::isnan(v) ? -1.0f : v});
        }
        std::sort(spec.costs.begin(), spec.costs.end());
    }

    // A cell that is fixed to a blocking tile cannot be a start or a goal.
    if (!mv.tiled) {
        // Blocked as nav.find_tile_path sees it: a solid tile is walkable again when `costs` gives it a cost.
        auto fixed_solid = [&](int x, int y) {
            for (const wfc::CellRule& rule : cons.cellRules) {
                if (rule.x != x || rule.y != y) continue;
                for (int s : rule.allowed)
                    if (tile_cost(spec, tile_index(mv.tile_of(s))) >= 0.0f) return false;
                return true;
            }
            return false;
        };
        auto check = [&](int x, int y, const std::string& at) {
            if (fixed_solid(x, y))
                bad_arg(at + ": the cell (" + std::to_string(x) + ", " + std::to_string(y) + ") is fixed to a tile that blocks the way, so nothing can stand or arrive there",
                        "Fix it to a walkable tile, or take the tile out of `solidTiles`.");
        };
        if (spec.hasFrom) check(spec.fromX, spec.fromY, base + "/from");
        for (std::size_t i = 0; i < spec.toCells.size(); ++i) check(spec.toCells[i].first, spec.toCells[i].second, base + "/to" + (spec.toCells.size() > 1 ? "/" + std::to_string(i) : std::string()));
    }
    return spec;
}

// The cost grid nav.find_tile_path reads from a Tilemap (nav_tile_grid_from_tilemap): solid tiles block, every other cell, the
// empty ones too, costs 1, and `costs` overrides either rule per tile index.
NavTileGrid nav_grid_of(const ReachSpec& spec, int width, int height, const std::vector<int>& tiles) {
    NavTileGrid g;
    g.width = width;
    g.height = height;
    g.cost.resize(tiles.size());
    for (std::size_t i = 0; i < tiles.size(); ++i) {
        g.cost[i] = tile_cost(spec, tile_index(tiles[i]));
    }
    return g;
}

struct ReachResult {
    bool ok = false;
    std::string why;    // when !ok: what failed, in a sentence
    Json report;
};

std::string cell_text(int x, int y) { return "(" + std::to_string(x) + ", " + std::to_string(y) + ")"; }

// Is the level playable: the start reaches every goal, and (allConnected) all walkable cells form one area. `tiles` is what the
// level will hold (after re-tiling), `symbols` the generator's own cells. The walk follows nav.find_tile_path: 4-way or 8-way
// without cutting corners, a cell with a negative cost blocks.
// `work` gets the deterministic cost: one unit per cell for the cost grid, one for the flood fill, one for the goal scan and
// one per cell of the grid for each path searched (the search is bounded by the grid).
ReachResult check_reachability(const ReachSpec& spec, int width, int height, const std::vector<int>& tiles, const std::vector<int>& symbols, std::int64_t& work) {
    ReachResult res;
    const std::int64_t gridCells = std::int64_t(width) * height;
    work += 2 * gridCells;
    const NavTileGrid grid = nav_grid_of(spec, width, height, tiles);
    const std::size_t total = grid.cost.size();
    auto at = [&](int x, int y) { return std::size_t(y) * std::size_t(width) + std::size_t(x); };
    auto open = [&](int x, int y) { return x >= 0 && y >= 0 && x < width && y < height && grid.cost[at(x, y)] >= 0.0f; };

    // Areas: flood fill every walkable cell, scanning rows top to bottom so the numbering never depends on anything but the grid.
    struct Area {
        int cells = 0;
        int minX = 0, minY = 0, maxX = 0, maxY = 0;
        int firstX = 0, firstY = 0;
    };
    std::vector<int> areaOf(total, -1);
    std::vector<Area> areas;
    std::vector<std::pair<int, int>> queue;
    static constexpr int kStep[8][2] = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}, {1, 1}, {-1, 1}, {-1, -1}, {1, -1}};
    const int dirs = spec.diagonals ? 8 : 4;
    std::size_t walkable = 0;
    for (int y = 0; y < height; ++y)
        for (int x = 0; x < width; ++x) {
            if (!open(x, y)) continue;
            ++walkable;
            if (areaOf[at(x, y)] >= 0) continue;
            const int id = int(areas.size());
            Area area;
            area.minX = area.maxX = area.firstX = x;
            area.minY = area.maxY = area.firstY = y;
            queue.assign(1, {x, y});
            areaOf[at(x, y)] = id;
            for (std::size_t head = 0; head < queue.size(); ++head) {
                const auto [cx, cy] = queue[head];
                ++area.cells;
                area.minX = std::min(area.minX, cx);
                area.maxX = std::max(area.maxX, cx);
                area.minY = std::min(area.minY, cy);
                area.maxY = std::max(area.maxY, cy);
                for (int d = 0; d < dirs; ++d) {
                    const int nx = cx + kStep[d][0], ny = cy + kStep[d][1];
                    if (!open(nx, ny) || areaOf[at(nx, ny)] >= 0) continue;
                    if (d >= 4 && !(open(cx + kStep[d][0], cy) && open(cx, cy + kStep[d][1]))) continue;   // no corner cutting
                    areaOf[at(nx, ny)] = id;
                    queue.push_back({nx, ny});
                }
            }
            areas.push_back(area);
        }

    // The area everything is measured from: the start's, or (allConnected alone) the biggest one.
    int mainArea = -1;
    if (spec.hasFrom) {
        mainArea = open(spec.fromX, spec.fromY) ? areaOf[at(spec.fromX, spec.fromY)] : -1;
    } else {
        for (std::size_t i = 0; i < areas.size(); ++i)
            if (mainArea < 0 || areas[i].cells > areas[std::size_t(mainArea)].cells) mainArea = int(i);
    }
    Json report = Json::object();
    if (spec.hasFrom) report["from"] = Json::array({spec.fromX, spec.fromY});
    report["walkableCells"] = walkable;
    report["reachableCells"] = mainArea >= 0 ? areas[std::size_t(mainArea)].cells : 0;
    std::vector<std::size_t> cut;   // areas that are not the main one, biggest first
    for (std::size_t i = 0; i < areas.size(); ++i)
        if (int(i) != mainArea) cut.push_back(i);
    std::stable_sort(cut.begin(), cut.end(), [&](std::size_t l, std::size_t r) { return areas[l].cells > areas[r].cells; });
    long long cutCells = 0;
    for (std::size_t i : cut) cutCells += areas[i].cells;
    Json cutList = Json::array();
    for (std::size_t k = 0; k < cut.size() && k < kReachAreas; ++k) {
        const Area& ar = areas[cut[k]];
        cutList.push_back(Json::object({{"cells", ar.cells},
                                        {"rect", Json::array({ar.minX, ar.minY, ar.maxX - ar.minX + 1, ar.maxY - ar.minY + 1})},
                                        {"at", Json::array({ar.firstX, ar.firstY})}}));
    }
    report["unreachable"] = Json::object({{"cells", cutCells}, {"areas", cut.size()}, {"largest", cutList}});

    if (spec.hasFrom && !open(spec.fromX, spec.fromY)) {
        res.why = "the start " + cell_text(spec.fromX, spec.fromY) + " is a blocked cell (tile " + std::to_string(tile_index(tiles[at(spec.fromX, spec.fromY)])) + ")";
        res.report = report;
        return res;
    }

    // Goals: explicit cells first, then every cell holding a goal tile, top to bottom.
    std::vector<std::pair<int, int>> goals = spec.toCells;
    if (!spec.toSymbols.empty()) {
        work += gridCells;
        std::set<int> want(spec.toSymbols.begin(), spec.toSymbols.end());
        for (int y = 0; y < height; ++y)
            for (int x = 0; x < width; ++x)
                if (want.count(symbols[at(x, y)])) goals.push_back({x, y});
    }
    Json paths = Json::array();
    Json lost = Json::array();
    std::size_t lostCount = 0;
    NavTileOptions nopt;
    nopt.diagonals = spec.diagonals;
    nopt.maxNodes = int(std::min<std::size_t>(total * 2 + 16, std::size_t(std::numeric_limits<int>::max())));
    std::string firstLost;
    for (std::size_t i = 0; i < goals.size(); ++i) {
        const auto [gx, gy] = goals[i];
        const bool reachable = open(gx, gy) && areaOf[at(gx, gy)] == mainArea;
        if (!reachable) {
            if (lostCount++ < kReachAreas) lost.push_back(Json::array({gx, gy}));
            if (firstLost.empty()) firstLost = cell_text(gx, gy);
            continue;
        }
        if (paths.size() < kReachPaths) {
            work += gridCells;
            const NavTilePath path = nav_find_tile_path(grid, spec.fromX, spec.fromY, gx, gy, nopt);
            // The cost is a float sum: rounded, so the report does not differ in the last digit between compilers.
            if (path.found)
                paths.push_back(Json::object({{"to", Json::array({gx, gy})},
                                              {"steps", path.cells.empty() ? 0 : path.cells.size() - 1},
                                              {"cost", std::round(double(path.cost) * 1000.0) / 1000.0}}));
        }
    }
    report["goals"] = goals.size();
    report["paths"] = paths;
    if (lostCount > 0) report["unreachableGoals"] = lost;
    res.report = report;
    if (lostCount > 0) {
        res.why = "no route from the start " + cell_text(spec.fromX, spec.fromY) + " to " + std::to_string(lostCount) + " of " + std::to_string(goals.size()) +
                  " goal cell(s), the first at " + firstLost + "; " + std::to_string(cutCells) + " walkable cells in " + std::to_string(cut.size()) + " other area(s) are cut off";
        return res;
    }
    if (spec.allConnected && !cut.empty()) {
        const Area& ar = areas[cut.front()];
        res.why = std::to_string(cut.size()) + " walkable area(s) are cut off from the main one (" + std::to_string(cutCells) + " cells), the biggest around " + cell_text(ar.firstX, ar.firstY);
        return res;
    }
    res.ok = true;
    return res;
}


// ------------------------------------------------------------------------------------------------------------ one generation
// Everything a generation holds from the moment its arguments are checked to the moment its level is written. The command
// `tilemap.generate` creates one and runs it to the end; the script API (`tilemap.generate` in a Behaviour) keeps it in
// Engine::Impl::wfcJobs and advances it a little every frame through tilemap.generate_step. Not copyable or movable: `view`
// points at the members next to it and the reachability check at the object itself.
struct GenRun {
    // the arguments
    std::string model;
    bool tiled = false;
    int width = 0, height = 0, n = 3, symmetry = 1;
    long long maxWork = kDefaultMaxWork, seedValue = 0;
    double maxSeconds = kDefaultMaxSeconds;
    bool hasInto = false, wantRows = true;
    Entity intoEntity;
    // what was read and built from them
    SampleData sample;
    std::vector<std::string> warnings;
    std::shared_ptr<wfc::PatternModel> patternModel;
    std::vector<int> symbolTile;   // symbol id -> tile value (tile-valued symbols)
    std::vector<Terrain> terrains;
    ModelView view;
    Constraints cons;
    ReachSpec reach;
    Json reachReport;
    std::unique_ptr<wfc::Generator> gen;
    std::uint64_t memoryBytes = 0;     // what the solver may hold (wfc::estimate_generator_memory + the reachability check)
    double cpuSeconds = 0.0;           // CPU the process spent inside step_generation() calls of this generation
    std::uint64_t sceneGeneration = 0; // World::scene_generation() when it was created: a script generation belongs to that scene

    GenRun() = default;
    GenRun(const GenRun&) = delete;
    GenRun& operator=(const GenRun&) = delete;

    // The tiles a grid of symbols becomes: the sample's tiles, or the model's tile values re-tiled with the autotile rules.
    std::vector<int> tiles_of(const std::vector<int>& symbols) {
        std::vector<int> t(symbols.size(), -1);
        if (!tiled && sample.ascii) {
            for (std::size_t i = 0; i < symbols.size(); ++i) t[i] = sample.glyphs.glyphs[std::size_t(symbols[i])].tile;
        } else {
            for (std::size_t i = 0; i < symbols.size(); ++i) t[i] = symbolTile[std::size_t(symbols[i])];
            if (tiled) retile_terrain_grid(terrains, width, height, t);
        }
        return t;
    }
};

constexpr std::size_t kMaxWfcJobs = 8;   // generations a game may have running at once (their memory adds up: see held_bytes)

std::shared_ptr<GenRun> job_of(Engine::Impl& I, int id) {
    auto it = I.wfcJobs.find(id);
    return it == I.wfcJobs.end() ? nullptr : std::static_pointer_cast<GenRun>(it->second);
}

// A generation belongs to the scene that started it: after a load nobody can receive its level, so it is dropped (and its
// memory with it). Called by every command that starts or advances one.
void drop_stale_jobs(Engine::Impl& I) {
    const std::uint64_t now = I.world.scene_generation();
    for (auto it = I.wfcJobs.begin(); it != I.wfcJobs.end();) {
        if (std::static_pointer_cast<GenRun>(it->second)->sceneGeneration != now) it = I.wfcJobs.erase(it);
        else ++it;
    }
}

// The solver memory the running script generations hold: a new one has to fit beside them under wfc::kWfcMemoryBudget.
std::uint64_t held_bytes(Engine::Impl& I) {
    std::uint64_t sum = 0;
    for (const auto& kv : I.wfcJobs) sum += std::static_pointer_cast<GenRun>(kv.second)->memoryBytes;
    return sum;
}

// Checks the arguments of tilemap.generate, reads the sample, builds the model and the rules, and creates the generator, which
// has not taken a step yet. Throws CommandError for every mistake, before anything big is allocated.
std::shared_ptr<GenRun> prepare_generation(Engine::Impl& I, const Json& a) {
    auto run = std::make_shared<GenRun>();
    GenRun& r = *run;
    const std::uint64_t heldBytes = held_bytes(I);
    SampleData& sample = r.sample;
    std::vector<std::string>& warnings = r.warnings;
    std::shared_ptr<wfc::PatternModel>& patternModel = r.patternModel;
    std::vector<int>& symbolTile = r.symbolTile;
    std::vector<Terrain>& terrains = r.terrains;
    ModelView& view = r.view;
    Constraints& cons = r.cons;
    ReachSpec& reach = r.reach;
    // ---- arguments
    if (a.contains("model") && !a["model"].is_string())
        bad_arg("'model' must be the text \"overlapping\" or \"tiled\", got " + describe_json_value(a["model"]),
                "`overlapping` learns the n x n patterns of a sample; `tiled` uses the adjacency of the autotile rules.");
    const std::string model = a.value("model", std::string("overlapping"));
    if (model != "overlapping" && model != "tiled")
        bad_arg("Unknown model '" + model + "'. " + did_you_mean(model, std::vector<std::string>{"overlapping", "tiled"}),
                "`overlapping` learns the n x n patterns of a sample; `tiled` uses the adjacency of the autotile rules.");
    const bool tiled = model == "tiled";
    int width = 0, height = 0;
    parse_size(a, width, height);
    // n and symmetry belong to the overlapping model: the tiled one ignores them, so they are not even checked there.
    int n = 3, symmetry = 1;
    if (!tiled) {
        n = int_arg(a, "n", 3, wfc::kMinPatternSize, wfc::kMaxPatternSize,
                    "n is the side of the learned windows: 2..5, usually 3. A bigger n copies larger pieces of the sample, a smaller n mixes more freely.");
        symmetry = int_arg(a, "symmetry", 1, 1, 8, "symmetry is 1 (as drawn), 2 (+ mirror), 4 (+ turns) or 8 (turns and mirrors).");
        if (a.contains("symmetry") && symmetry != 1 && symmetry != 2 && symmetry != 4 && symmetry != 8)
            bad_arg("'symmetry' is " + std::to_string(symmetry) + " but it must be 1, 2, 4 or 8", "1 = as drawn, 2 = also mirrored left-right, 4 = also turned, 8 = turned and mirrored.");
    }
    const bool strict = a.contains("constraints") || a.contains("reachability");
    const int maxAttempts = int_arg(a, "maxAttempts", strict ? kDefaultConstraintAttempts : kDefaultMaxAttempts, 1, wfc::kMaxAttempts,
                                    "Each attempt restarts from the next derived seed. 10 is the default (50 with `constraints` or `reachability`, which refuse many grids); a few hundred only helps a very strict sample.");
    long long maxWork = kDefaultMaxWork;
    if (a.contains("maxWork") && (!whole_number(a["maxWork"], maxWork) || maxWork < 1 || maxWork > kMaxWorkLimit))
        bad_arg("'maxWork' must be a whole number between 1 and " + std::to_string(kMaxWorkLimit) + ", got " + describe_json_value(a["maxWork"]),
                "It caps the work over all attempts (units: about one step of the inner loops; `stats.work` of an earlier run shows what a level needs). Default " + std::to_string(kDefaultMaxWork) + ".");
    double maxSeconds = kDefaultMaxSeconds;
    if (a.contains("maxSeconds") && (!a["maxSeconds"].is_number() || a["maxSeconds"].get<double>() <= 0.0 || a["maxSeconds"].get<double>() > kMaxSecondsLimit))
        bad_arg("'maxSeconds' must be a number of CPU seconds above 0 and up to " + std::to_string(int(kMaxSecondsLimit)) + ", got " + describe_json_value(a["maxSeconds"]),
                "It is a safety net on the CPU time of the process (all threads; wall clock on the web build). `maxWork` is the cap that decides. Default " + std::to_string(int(kDefaultMaxSeconds)) + ".");
    if (a.contains("maxSeconds")) maxSeconds = a["maxSeconds"].get<double>();
    const bool periodic = bool_arg(a, "periodic", false);
    const bool periodicInput = bool_arg(a, "periodicInput", periodic);
    long long seedValue = 0;
    if (a.contains("seed") && !whole_number(a["seed"], seedValue))
        bad_arg("'seed' must be a whole number, got " + describe_json_value(a["seed"]), "Example: \"seed\": 12345.");
    const std::uint64_t seed = std::uint64_t(seedValue);
    const bool hasInto = a.contains("into");
    if (hasInto && !a["into"].is_string()) bad_arg("'into' must be the id of an entity with a Tilemap, got " + describe_json_value(a["into"]));
    const bool wantRows = bool_arg(a, "rows", !hasInto);

    Entity intoEntity;
    const Tilemap* into = nullptr;
    if (hasInto) {
        const std::string id = a["into"].get<std::string>();
        intoEntity = need_entity(I.world, a, "into");
        into = I.world.get<Tilemap>(intoEntity);
        if (!into)
            bad_arg("Entity '" + id + "' has no Tilemap component, so the level cannot be written into it",
                    "Pass the id of the entity that holds the Tilemap (scene.import_ascii names it 'tilemap'), or leave `into` out to get the rows back.");
    }

    r.model = model;
    r.tiled = tiled;
    r.width = width;
    r.height = height;
    r.n = n;
    r.symmetry = symmetry;
    r.maxWork = maxWork;
    r.maxSeconds = maxSeconds;
    r.seedValue = seedValue;
    r.hasInto = hasInto;
    r.wantRows = wantRows;
    r.intoEntity = intoEntity;
    r.sceneGeneration = I.world.scene_generation();

    sample = read_sample(I, a);
    if (!tiled && !sample.present)
        bad_arg("The overlapping model needs a `sample` to learn from",
                "Pass `sample`: the id of an entity with a Tilemap, or ASCII rows with a `legend`, e.g. \"sample\": [\"#####\",\"#...#\",\"#####\"], \"legend\": {\"#\": 0}. "
                "To generate from autotile rules alone use \"model\": \"tiled\".");
    if (sample.present && (sample.width <= 0 || sample.height <= 0)) bad_arg("The sample is empty: it has no cells", "Give a sample with a few rows and columns.");

    // ---- the model
                if (!tiled) {
        wfc::Sample s;
        s.width = sample.width;
        s.height = sample.height;
        if (sample.ascii) {
            s.cells = sample.glyphs.cells;
            s.symbolCount = int(sample.glyphs.glyphs.size());
        } else {
            std::map<int, int> symbolOf;
            for (int t : sample.tiles) {
                auto it = symbolOf.find(t);
                if (it == symbolOf.end()) {
                    it = symbolOf.emplace(t, int(symbolTile.size())).first;
                    symbolTile.push_back(t);
                }
                s.cells.push_back(it->second);
            }
            s.symbolCount = int(symbolTile.size());
        }
        wfc::OverlapOptions oo;
        oo.n = n;
        oo.symmetry = symmetry;
        oo.periodicInput = periodicInput;
        auto built = wfc::build_overlapping_model(s, oo);
        if (!built.ok()) throw_error(built.error());
        patternModel = *built;
    } else {
        Json rules = Json::array();
        std::string where;
        if (a.contains("terrains")) {
            rules = a["terrains"];
            where = "`terrains`";
        } else if (sample.present && !sample.ascii && sample.terrains.is_array() && !sample.terrains.empty()) {
            rules = sample.terrains;
            where = "the sample's Tilemap";
        } else if (into && into->terrains.is_array() && !into->terrains.empty()) {
            rules = into->terrains;
            where = "the `into` Tilemap";
        }
        if (!rules.is_array() || rules.empty())
            bad_arg("The tiled model needs autotile rules (terrains) to know which tiles may touch, and none were found: " +
                        std::string(a.contains("terrains") ? "`terrains` is empty" : "the sample's Tilemap and the `into` Tilemap have no Tilemap.terrains"),
                    "Add rules to the Tilemap: tilemap.set_terrains {\"id\":\"map\",\"path\":\"assets/art/ground.terrains.json\"} (image.tileset.build writes that file), "
                    "or pass `terrains` here ([{\"name\":\"grass\",\"mode\":\"blob47\",\"first\":0}]). Or use \"model\": \"overlapping\", which needs only a sample.");
        auto parsed = parse_terrains(rules);
        if (!parsed.ok()) bad_arg("The terrain rules of " + where + " are invalid: " + parsed.error().message, parsed.error().hint);
        terrains = *parsed;
        // The sample's tiles are counted by tile index: the rules list a tile once, the sample may hold it turned or flipped.
        std::map<int, std::uint32_t> counts;
        std::set<int> ruleTiles;
        std::set<int> ruleIndexes;
        for (const Terrain& t : terrains)
            for (const auto& slot : t.slots)
                for (int v : slot) {
                    ruleTiles.insert(v);
                    ruleIndexes.insert(tile_index(v));
                }
        if (sample.present) {
            std::set<int> ignored;
            for (int t : sample.tiles) {
                if (t < 0) continue;
                const int idx = tile_index(t);
                if (ruleIndexes.count(idx)) counts[idx] += 1;
                else ignored.insert(idx);
            }
            if (!ignored.empty()) {
                std::string list;
                int shown = 0;
                for (int t : ignored) {
                    if (shown++ == 6) {
                        list += ", ...";
                        break;
                    }
                    list += (list.empty() ? "" : ", ") + std::to_string(t);
                }
                warnings.push_back("The sample holds tiles that belong to no terrain (" + list + "): the tiled model cannot place them, so they were ignored.");
            }
        }
        std::vector<std::pair<int, std::uint32_t>> weights;
        for (int v : ruleTiles) {
            auto c = counts.find(tile_index(v));
            weights.push_back({v, 1u + (c != counts.end() ? c->second : 0u)});
        }
        auto built = wfc::build_terrain_model(terrains, weights);
        if (!built.ok()) throw_error(built.error());
        patternModel = built->model;
        symbolTile = built->tileValues;
    }

    // ---- the size first: nothing below allocates per cell or per fixed cell before the memory estimate is known to fit
    // (the reachability check holds a few grids of its own: tiles, costs, areas, a queue, about 32 bytes a cell)
    const std::uint64_t reachBytes = a.contains("reachability") ? std::uint64_t(width) * std::uint64_t(height) * 32u : 0u;
    if (auto fits = wfc::check_generator_memory(*patternModel, width, height, periodic, reachBytes + heldBytes); !fits.ok()) throw_error(fits.error());

    // ---- constraints and reachability (checked against the model before anything is generated)
    view.tiled = tiled;
    view.sample = &sample;
    view.symbolTile = &symbolTile;
    view.terrains = &terrains;
    view.symbolCount = (!tiled && sample.ascii) ? int(sample.glyphs.glyphs.size()) : int(symbolTile.size());
    cons = parse_constraints(a, view, width, height);
    reach = parse_reachability(a, view, sample, into, cons, width, height);

    // ---- generate
    wfc::GenerateOptions go;
    go.width = width;
    go.height = height;
    go.periodic = periodic;
    go.seed = seed;
    go.maxAttempts = maxAttempts;
    go.forbidden = cons.forbidden;
    go.cellRules = cons.cellRules;
    go.counts = cons.counts;
    go.maxWork = maxWork;
    if (reach.enabled)
        go.accept = [self = run.get()](const std::vector<int>& symbols, std::string& why, std::int64_t& work) {
            work += std::int64_t(self->width) * self->height;   // tiles_of
            ReachResult res = check_reachability(self->reach, self->width, self->height, self->tiles_of(symbols), symbols, work);
            self->reachReport = res.report;
            why = res.why;
            return res.ok;
        };
    auto gen = wfc::Generator::create(patternModel, go);
    if (!gen.ok()) throw_error(gen.error());
    run->gen = std::move(*gen);
    run->memoryBytes = run->gen->stats().memoryBytes + reachBytes;

    return run;
}

CommandError budget_error(GenRun& r, bool overWork) {
    const wfc::GenStats& so = r.gen->stats();
    const std::string size = std::to_string(r.width) + " x " + std::to_string(r.height) + " output, " + std::to_string(so.cells) + " solver cells, " +
                             std::to_string(so.patterns) + " patterns" + (r.tiled ? "" : ", n " + std::to_string(r.n) + ", symmetry " + std::to_string(r.symmetry));
    return CommandError(
        "budget_exceeded",
        "tilemap.generate stopped after " + std::to_string(so.attempts) + " attempt(s) (" + std::to_string(so.contradictions) + " dead ends, " + std::to_string(so.rejected) +
            " refused): it used " + std::to_string(so.work) + " units of work (`maxWork` " + std::to_string(r.maxWork) + ") and " + one_decimal(r.cpuSeconds) +
            " CPU seconds (`maxSeconds` " + one_decimal(r.maxSeconds) + ", counting every thread of the process) for a " + size + ".",
        std::string(overWork ? "The work cap was hit. " : "The CPU time safety cap was hit (the machine is very slow or busy). ") +
            "Make the level smaller (`size`), use a smaller `n` or `symmetry` 1 (fewer patterns), a simpler sample, or fewer constraints; "
            "or raise `" + (overWork ? "maxWork" : "maxSeconds") + "` (up to " + (overWork ? std::to_string(kMaxWorkLimit) : std::to_string(int(kMaxSecondsLimit))) + ") if you accept the wait.");
}

// Advances the generator: one step() of at most `workBudget` units, or, when `budgetMs` > 0, steps of at most kStepWork units until that
// many milliseconds have passed (at least one step). The level never depends on how it is cut: the cap a result depends on is `maxWork` (inside the
// generator, deterministic units), while the CPU safety net and `budgetMs` only pace the call. True when the level is done; throws
// CommandError when it failed or hit a cap.
bool step_generation(GenRun& r, std::int64_t workBudget, double budgetMs) {
    wfc::Generator& g = *r.gen;
    const double cpuStart = process_cpu_seconds();
    const auto wallStart = std::chrono::steady_clock::now();
    wfc::GenStatus status = wfc::GenStatus::Running;
    bool overTime = false;
    while (true) {
        status = g.step(budgetMs > 0.0 ? std::min(workBudget, kStepWork) : workBudget);  // small pieces under a time budget, so it is checked often
        if (status != wfc::GenStatus::Running) break;
        if (r.cpuSeconds + (process_cpu_seconds() - cpuStart) > r.maxSeconds) {
            overTime = true;
            break;
        }
        if (budgetMs <= 0.0) break;
        if (std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - wallStart).count() >= budgetMs) break;
    }
    r.cpuSeconds += process_cpu_seconds() - cpuStart;
    if (overTime) throw budget_error(r, false);
    if (status == wfc::GenStatus::Failed && g.failure().workLimit) throw budget_error(r, true);
    if (status != wfc::GenStatus::Done && status != wfc::GenStatus::Running) throw CommandError("generation_failed", g.failure_message(), g.failure_hint());
    return status == wfc::GenStatus::Done;
}

// The result of a finished generation (and `into` written). The grid is the same whichever way the steps were cut.
Json finish_generation(Engine::Impl& I, GenRun& r) {
    wfc::Generator& g = *r.gen;
    const int width = r.width, height = r.height;
    const bool tiled = r.tiled, hasInto = r.hasInto, wantRows = r.wantRows;
    const std::string& model = r.model;
    const long long seedValue = r.seedValue;
    SampleData& sample = r.sample;
    std::vector<std::string>& warnings = r.warnings;
    Constraints& cons = r.cons;
    ReachSpec& reach = r.reach;
    Tilemap* into = nullptr;
    if (hasInto) {
        if (!I.world.alive(r.intoEntity) || !(into = I.world.get<Tilemap>(r.intoEntity)))
            throw CommandError("not_found", "The entity given as `into` is gone or has no Tilemap any more, so the level cannot be written into it",
                               "Keep the Tilemap entity alive until the generation finishes, or leave `into` out and place the rows yourself.");
    }
    const std::vector<int>& cellsOut = g.output();
    std::vector<int> tiles = r.tiles_of(cellsOut);
    std::vector<std::string> glyphOfCell(cellsOut.size());
    GlyphBook book(sample);
    Json legend = Json::object();
    int prefabCells = 0;
    if (!tiled && sample.ascii) {
        for (std::size_t i = 0; i < cellsOut.size(); ++i) {
            const AsciiSampleGlyph& sg = sample.glyphs.glyphs[std::size_t(cellsOut[i])];
            glyphOfCell[i] = sg.glyph;
            if (sg.hasPrefab) ++prefabCells;
            if (!sg.legendEntry.is_null()) legend[sg.glyph] = sg.legendEntry;
        }
    } else {
        for (std::size_t i = 0; i < tiles.size(); ++i) {
            glyphOfCell[i] = book.glyph_for_tile(tiles[i]);
            book.use(glyphOfCell[i], legend);
        }
    }
    if (prefabCells > 0)
        warnings.push_back(std::to_string(prefabCells) + " cell(s) hold glyphs that spawn objects: " + std::string(hasInto ? "`into` wrote only their tiles; " : "") +
                           "call scene.import_ascii with the returned rows and legend to place the objects.");

    Json out = Json::object();
    out["model"] = model;
    out["width"] = width;
    out["height"] = height;
    out["seed"] = seedValue;
    std::map<std::string, int> glyphCounts;
    for (const std::string& gl : glyphOfCell) ++glyphCounts[gl];
    Json counts = Json::object();
    for (const auto& kv : glyphCounts) counts[kv.first] = kv.second;
    out["counts"] = counts;
    out["legend"] = legend;
    if (wantRows) {
        Json rows = Json::array();
        for (int y = 0; y < height; ++y) {
            std::string row;
            for (int x = 0; x < width; ++x) row += glyphOfCell[std::size_t(y) * std::size_t(width) + std::size_t(x)];
            rows.push_back(row);
        }
        out["rows"] = rows;
    }
    if (into) {
        set_tilemap_grid(*into, width, height, tiles);
        out["into"] = I.world.id_of(r.intoEntity);
    }
    if (sample.present)
        out["sample"] = Json::object({{"source", sample.source}, {"width", sample.width}, {"height", sample.height}});
    const wfc::GenStats& st = g.stats();
    out["stats"] = Json::object({{"attempts", st.attempts}, {"contradictions", st.contradictions}, {"rejected", st.rejected}, {"patterns", st.patterns},
                                 {"cells", st.cells}, {"observations", st.observations}, {"propagations", st.propagations}, {"work", st.work},
                                 {"pinned", st.pinned}, {"ms", std::round(st.ms * 10.0) / 10.0}, {"memoryBytes", st.memoryBytes},
                                 {"peakBytes", st.peakBytes}});
    if (cons.any()) {
        Json counted = Json::array();
        for (std::size_t k = 0; k < cons.counts.size(); ++k) {
            const wfc::CountRule& rule = cons.counts[k];
            const std::set<int> symbols(rule.symbols.begin(), rule.symbols.end());
            int found = 0;
            for (int sym : cellsOut) found += symbols.count(sym) ? 1 : 0;
            Json entry = Json::object({{"tile", cons.countLabels[k]}, {"found", found}});
            if (rule.min > 0) entry["min"] = rule.min;
            if (rule.max >= 0) entry["max"] = rule.max;
            counted.push_back(entry);
        }
        out["constraints"] = Json::object({{"fixedCells", cons.fixedCells}, {"forbiddenTiles", cons.forbidden.size()}, {"counts", counted}, {"pinnedCells", st.pinned}});
    }
    if (reach.enabled) out["reachability"] = r.reachReport;
    if (!warnings.empty()) out["warnings"] = warnings;
    return out;
}

// ---- tilemap.generate_start / generate_step / generate_cancel: the same generation, advanced by the caller

Json step_result(GenRun& r, bool done) {
    const wfc::GenStats& st = r.gen->stats();
    Json out = Json::object({{"done", done}, {"progress", done ? 1.0 : std::round(r.gen->progress() * 1000.0) / 1000.0}, {"attempts", st.attempts}, {"work", st.work},
                             {"contradictions", st.contradictions}, {"rejected", st.rejected}});
    return out;
}

int job_id_arg(const Json& a) {
    if (!a.contains("job")) bad_arg("Missing 'job'", "It is the number tilemap.generate_start returned. Example: {\"job\": 1}.");
    long long id = 0;
    if (!whole_number(a["job"], id) || id < 1 || id > std::numeric_limits<int>::max())
        bad_arg("'job' must be the whole number tilemap.generate_start returned, got " + describe_json_value(a["job"]), "Example: {\"job\": 1}.");
    return int(id);
}

}  // namespace

void register_wfc_commands(Engine&, Engine::Impl& I) {
    const Json generateSchema = parse_schema(R"json({"type":"object","required":["size"],"properties":{
               "sample":{"type":["string","array","object"],"description":"The example to learn from: the id of an entity with a Tilemap; ASCII rows (array of strings, or one string with line breaks) with `legend`; an object {rows, legend?, legendFrom?} (scene.import_ascii arguments); or a project-relative .json file with such an object. Required for model overlapping; for tiled it only sets the tile frequencies.","items":{"type":"string"}},
               "legend":{"type":"object","description":"Glyph -> tile index or {tile?, rotate?, flipX?, flipY?, prefab?...}, as in scene.import_ascii; for ASCII rows given as an array or text. '.' and ' ' are empty unless defined here."},
               "legendFrom":{"type":"string","description":"Project-relative JSON file with a shared legend (see scene.import_ascii), merged under `legend`."},
               "size":{"type":["array","object","integer"],"description":"Output size in cells: [width, height], {width, height} or one number for a square. Each side 1..2048 (and at least n for overlapping).","items":{"type":"integer"}},
               "seed":{"type":"integer","default":0,"description":"Picks the level. The same sample, seed and arguments always give the same level. Each restart after a dead end uses the next derived seed."},
               "model":{"type":"string","enum":["overlapping","tiled"],"default":"overlapping","description":"overlapping: learn the n x n patterns of the sample. tiled: tile adjacency from the autotile rules (Tilemap.terrains)."},
               "n":{"type":"integer","default":3,"description":"Overlapping model: side of the learned windows, 2..5 (checked only for the overlapping model). Bigger copies larger pieces of the sample; smaller mixes more. Ignored by tiled (not even checked)."},
               "symmetry":{"type":"integer","default":1,"description":"One of 1, 2, 4, 8 (checked only for the overlapping model). 1 = the sample as drawn, 2 = also mirrored left-right, 4 = also turned 90/180/270 degrees, 8 = turned and mirrored. Only for tiles that look the same turned (floor, wall); overlapping model; ignored by tiled."},
               "periodic":{"type":"boolean","default":false,"description":"The output wraps around its edges (a tileable level). Also lets the sample wrap unless periodicInput is given."},
               "periodicInput":{"type":"boolean","description":"The sample wraps around its edges (patterns cross them). Default: the value of `periodic`."},
               "maxAttempts":{"type":"integer","default":10,"minimum":1,"maximum":1000,"description":"Attempts before giving up: a dead end (or a grid that breaks a constraint or is not reachable) restarts with the next derived seed. Default 10, 50 with constraints or reachability."},
               "maxWork":{"type":"integer","default":600000000,"minimum":1,"maximum":100000000000,"description":"Cap on the work (stats.work of an earlier run shows what a level needs: pattern removals and the adjacency they touch, cells observed, the fixed cells and the reachability check) over all attempts. It counts the same on every machine, so a level either always fits or never does. Hit it and the call fails with how to shrink the level or raise the cap."},
               "maxSeconds":{"type":"number","default":120,"exclusiveMinimum":0,"maximum":600,"description":"Safety net on the CPU seconds the process may spend on this call (all threads count; the web build counts wall-clock seconds). The cap a result depends on is maxWork: this one only stops a machine that is far slower than expected."},
               "constraints":{"type":"object","description":"Rules the level must follow. fixed: [{at:[x,y] | rect:[x,y,w,h], tile}] pins cells; border: {tile, thickness (default 1)}; forbidden: [tile]; required: [tile] (at least one each); counts: [{tile, min?, max?}]. A tile is a glyph of an ASCII sample, a tile number (-1 = empty) or a terrain name (tiled); a list = any of them. Contradictions are reported before generating, with the JSON pointer.","properties":{"fixed":{"type":"array","items":{"type":"object"}},"border":{"type":"object"},"forbidden":{"type":"array"},"required":{"type":"array"},"counts":{"type":"array","items":{"type":"object"}}}},
               "reachability":{"type":"object","description":"The level must be playable: {from:[x,y], to:[x,y] | [[x,y]...], toTiles:[tile] (every cell with one must be reachable), allConnected:true, solidTiles:[tile numbers that block] (default: Tilemap.solidTiles of `into`, then of the sample), costs:{tile:cost|null}, diagonals:bool}. Same walking rules as nav.find_tile_path. A grid that fails restarts with the next derived seed. The result's `reachability` reports unreachable cells and areas and the path lengths.","properties":{"from":{"type":"array","items":{"type":"integer"}},"to":{"type":"array"},"toTiles":{"type":["array","string","integer"]},"allConnected":{"type":"boolean"},"solidTiles":{"type":"array","items":{"type":"integer"}},"costs":{"type":"object"},"diagonals":{"type":"boolean"}}},
               "into":{"type":"string","description":"Id of an entity with a Tilemap to write the result into (its tiles, width and height are replaced; tileset, tileSize and solidTiles stay). RUNNING world only."},
               "rows":{"type":"boolean","description":"Return the level as ASCII `rows`. Default: true without `into`, false with it."},
               "terrains":{"type":"array","items":{"type":"object"},"description":"Tiled model: autotile rules to use instead of the Tilemap's own (same objects as Tilemap.terrains)."}}})json");
    I.commands.add(
        {"tilemap.generate",
         "Generate a level from an example with Wave Function Collapse: a grid that only contains the patterns of the sample.",
         "Learns from a small example level and makes a new, bigger one that looks like it, the same on every machine for the same "
         "arguments. `sample` is the example: the id of an entity with a Tilemap, ASCII rows (an array of strings, or a string with "
         "line breaks) with a `legend` in the format of scene.import_ascii (glyph -> tile index or {tile?, prefab?...}; '.' and ' ' are "
         "empty), an object {rows, legend?, legendFrom?}, or the path of a JSON file holding one. `size` is the output in cells ([width, "
         "height], {width, height} or one number). MODELS: `overlapping` (default) learns every n x n window of the sample (n 2..5, "
         "default 3) and fills the output cell by cell, always the one with the fewest options left, so every n x n window of the "
         "result also exists in the sample (with `symmetry` also in its rotations and mirrors); a bigger n copies larger pieces, a "
         "smaller n mixes more freely. `tiled` ignores n and symmetry (they are not even checked) and reads which tiles may touch from the autotile rules (Tilemap.terrains, "
         "tilemap.set_terrains, image.tileset.build) of the sample's Tilemap, of `into`, or from `terrains`; the sample only sets how "
         "often each tile is picked, and blob47 corners are fixed afterwards like tilemap.retile. Without rules it fails and says how "
         "to add them. `symmetry` 1 (default) uses the sample as drawn, 2 adds its mirror image, 4 its three turns, 8 turns and mirrors "
         "(use it for floors and walls, not for tiles that point somewhere). `periodic` true makes the output wrap around its edges "
         "(a tileable level) and, unless `periodicInput` says otherwise, also lets the sample wrap. `seed` (default 0) picks the "
         "level: same sample, seed and arguments, same level, on every platform. A dead end (a cell with no pattern left) restarts with "
         "the next derived seed, up to `maxAttempts` (default 10, 50 with `constraints` or `reachability`); when all fail the error says where, and what to try (a bigger or more "
         "varied sample, a smaller n, symmetry, periodic). Output: with `into` (the id of an entity with a Tilemap) the grid is written "
         "there (tileset, tileSize and solidTiles stay) in the RUNNING world; without it the grid comes back as `rows` + `legend`, ready for "
         "scene.import_ascii, and with `rows` true it comes back as well when `into` is given. Glyphs of an ASCII sample that spawn "
         "prefabs come back as the same glyph in `rows`; `into` writes only their tiles, so build objects with scene.import_ascii. "
         "A Tilemap sample is printed with generated glyphs ('.' = empty). "
         "CONSTRAINTS (`constraints`, checked before generating; each problem names its JSON pointer): `fixed` [{at:[x,y] | rect:[x,y,w,h], tile}] "
         "pins cells (an entrance, an exit), `border` {tile, thickness?} walls in the edge, `forbidden` [tile] never appear, `required` [tile] "
         "appear at least once, `counts` [{tile, min?, max?}]. A `tile` is a glyph of an ASCII sample, a tile number (-1 = empty) or, for the tiled model, a "
         "terrain name; a list of them means any of them. A tile the sample never shows cannot be placed. A missing minimum is repaired on the next attempt "
         "by pinning cells (positions drawn from the seed); a maximum or any other miss restarts. REACHABILITY (`reachability`): {from:[x,y], to:[x,y] | "
         "[[x,y]...], toTiles:[tile] (every cell holding one is a goal), allConnected:true (all walkable cells form one area), solidTiles:[tile numbers that "
         "block] (default: those of `into` or of the sample), costs:{tile: cost|null}, diagonals}. It uses the rules of nav.find_tile_path, on the finished "
         "level; a grid that fails restarts with the next derived seed, so the level you get is playable. The report lists walkable cells, the cells and "
         "areas that were cut off (a few rects) and the path length to each goal. Everything derives from `seed`, never the clock. "
         "LIMITS: `maxWork` (default 600000000 units of work over all attempts, counted the same on every machine: it is what decides whether a level is too big) "
         "and `maxSeconds` (default 120, a safety net: CPU seconds of the whole process counting every thread; on the web build wall-clock seconds) stop a level "
         "that cannot be solved with a teaching error. Returns {model, width, height, seed, rows?, legend, "
         "counts: {glyph: cells}, into?, warnings?, sample: {source, width, height}, constraints?: {fixedCells, forbiddenTiles, counts: [{tile, found, min?, max?}], "
         "pinnedCells}, reachability?, stats: {attempts, contradictions, rejected, patterns, cells, observations, propagations, work, pinned, ms, memoryBytes, "
         "peakBytes}}. The level and the counters (attempts, work...) are the same on every machine; stats.ms (the time it took), memoryBytes and peakBytes (bytes: they depend on the compiler and standard library) are not part of the determinism promise. "
         "Limits: output sides up to 2048, sample up to 262144 cells, 20000 patterns, "
         "about 256 MB of solver memory (checked first, before anything is built for the constraints; the error says what to shrink), 65536 fixed cells. Example: tilemap.generate {\"sample\":[\"........\",\"..##....\",\"..##..#.\","
         "\"......#.\",\"..#.....\",\"........\"],\"legend\":{\"#\":0},\"size\":[32,20],\"seed\":7,\"n\":3,\"symmetry\":8,"
         "\"constraints\":{\"border\":{\"tile\":\"#\"},\"fixed\":[{\"at\":[1,1],\"tile\":\".\"}]},\"reachability\":{\"from\":[1,1],\"allConnected\":true,\"solidTiles\":[0]}}",
         generateSchema,
         false, "scene"},
        [&I](const Json& a) {
            drop_stale_jobs(I);
            std::shared_ptr<GenRun> run = prepare_generation(I, a);
            // Stepped, not run(): the CPU safety cap is checked between steps (step_generation).
            while (!step_generation(*run, kStepWork, 0.0)) {
            }
            return finish_generation(I, *run);
        });

    // ---- the same generation in pieces: what the script API tilemap.generate runs on (docs/SCRIPTING.md, "Generating a level")
    I.commands.add(
        {"tilemap.generate_start",
         "Check the arguments of tilemap.generate and start a generation that you advance yourself with tilemap.generate_step.",
         "Takes exactly the arguments of tilemap.generate, checks them at once (the same errors, before anything is generated) and returns "
         "{job, width, height, seed, cells, patterns, memoryBytes} without generating. Then call tilemap.generate_step {job} until it answers "
         "done: its `result` is what tilemap.generate returns, and `into` is written at that moment, not before. The level does not depend on "
         "how the steps are cut: any `work` or `budgetMs` gives the same level and the same stats.work for the same arguments. A job belongs to "
         "the scene that started it (a scene load drops it) and holds its solver memory until it finishes, fails or is cancelled; at most 8 "
         "run at once and their memory adds up under the same 256 MB limit. Scripts do not need this: `tilemap.generate(...)` in a Behaviour "
         "starts the job, advances it every frame within a budget and places the objects of the sample. Example: tilemap.generate_start "
         "{\"sample\":[\"#####\",\"#...#\",\"#####\"],\"legend\":{\"#\":0},\"size\":[16,12],\"seed\":3}",
         generateSchema, false, "scene"},
        [&I](const Json& a) {
            drop_stale_jobs(I);
            if (I.wfcJobs.size() >= kMaxWfcJobs)
                bad_arg("There are already " + std::to_string(kMaxWfcJobs) + " generations running",
                        "Wait for one to finish (tilemap.generate_step until done) or drop one with tilemap.generate_cancel {job}.");
            std::shared_ptr<GenRun> run = prepare_generation(I, a);
            const int id = I.nextWfcJob++;
            I.wfcJobs[id] = run;
            const wfc::GenStats& st = run->gen->stats();
            return Json::object({{"job", id}, {"width", run->width}, {"height", run->height}, {"seed", run->seedValue}, {"cells", st.cells},
                                 {"patterns", st.patterns}, {"memoryBytes", run->memoryBytes}});
        });
    I.commands.add(
        {"tilemap.generate_step",
         "Advance a generation started with tilemap.generate_start by a bounded amount of work.",
         "Does at most `work` units of work (default 500000, about 10 ms of a Debug build; the same unit as stats.work) or, with `budgetMs`, steps until "
         "that many milliseconds have passed (at least one step). Returns {done:false, progress, attempts, work, contradictions, rejected} while it runs "
         "(progress 0..1 is the share of cells decided in the current attempt: it goes back to 0 when an attempt restarts) and {done:true, progress:1, "
         "result} when the level is finished, `result` being what tilemap.generate returns. A step can overshoot its budget by one unit of the algorithm: "
         "the start of an attempt and the end of one (the reachability check) each run in one piece, so they cost more on a very big level. Errors "
         "(the generation failed, hit `maxWork`, the entity of `into` is gone) end the job. A job whose scene was unloaded no longer exists. "
         "Example: tilemap.generate_step {\"job\":1,\"work\":200000}",
         parse_schema(R"json({"type":"object","required":["job"],"properties":{
               "job":{"type":"integer","minimum":1,"description":"The job tilemap.generate_start returned."},
               "work":{"type":"integer","default":500000,"minimum":1,"maximum":100000000,"description":"Units of work to do in this call (stats.work counts the same units)."},
               "budgetMs":{"type":"number","exclusiveMinimum":0,"maximum":1000,"description":"Instead of `work`: step until this many milliseconds have passed (at least one step). How far a job gets in a call then depends on the machine, never the level."}}})json"),
         false, "scene"},
        [&I](const Json& a) {
            drop_stale_jobs(I);
            const int id = job_id_arg(a);
            std::shared_ptr<GenRun> run = job_of(I, id);
            if (!run)
                bad_arg("There is no generation with job " + std::to_string(id),
                        "A job ends when it finishes, fails, is cancelled, or when its scene is unloaded. tilemap.generate_start returns the number to use.");
            long long work = kFrameWork;
            if (a.contains("work") && (!whole_number(a["work"], work) || work < 1 || work > 100'000'000))
                bad_arg("'work' must be a whole number between 1 and 100000000, got " + describe_json_value(a["work"]), "Units of work for this call. Default " + std::to_string(kFrameWork) + ".");
            double budgetMs = 0.0;
            if (a.contains("budgetMs") && (!a["budgetMs"].is_number() || a["budgetMs"].get<double>() <= 0.0 || a["budgetMs"].get<double>() > 1000.0))
                bad_arg("'budgetMs' must be a number of milliseconds above 0 and up to 1000, got " + describe_json_value(a["budgetMs"]), "Example: \"budgetMs\": 4.");
            if (a.contains("budgetMs")) budgetMs = a["budgetMs"].get<double>();
            try {
                const bool done = step_generation(*run, work, budgetMs);
                if (!done) return step_result(*run, false);
                Json out = step_result(*run, true);
                out["result"] = finish_generation(I, *run);
                I.wfcJobs.erase(id);
                return out;
            } catch (...) {
                I.wfcJobs.erase(id);  // a job that failed has nothing left to step
                throw;
            }
        });
    I.commands.add(
        {"tilemap.generate_cancel",
         "Drop a generation started with tilemap.generate_start and free its memory.",
         "Idempotent: an unknown job (finished, failed, already cancelled, or dropped by a scene load) answers {cancelled:false}. Example: tilemap.generate_cancel {\"job\":1}",
         parse_schema(R"json({"type":"object","required":["job"],"properties":{"job":{"type":"integer","minimum":1,"description":"The job tilemap.generate_start returned."}}})json"),
         false, "scene"},
        [&I](const Json& a) {
            const int id = job_id_arg(a);
            return Json::object({{"cancelled", I.wfcJobs.erase(id) > 0}});
        });

}

}  // namespace fa
