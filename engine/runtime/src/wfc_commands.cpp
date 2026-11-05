// tilemap.generate: a level made from an example (Wave Function Collapse). The algorithm and its determinism rules live in
// fa/scene/wfc.h; this file reads the sample (a Tilemap entity or ASCII rows in the format of scene.import_ascii), checks the
// arguments with errors that teach, runs the generator and writes the result into a Tilemap and/or returns it as ASCII rows.
#include <algorithm>
#include <cmath>
#include <map>
#include <set>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"
#include "fa/scene/autotile.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/wfc.h"

namespace fa {

namespace {

constexpr int kDefaultMaxAttempts = 10;

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
};

Json ascii_args_from(Engine::Impl& I, const Json& a, const Json& sample) {
    (void)I;
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
            asciiArgs = ascii_args_from(I, a, s);
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
            asciiArgs = ascii_args_from(I, a, *doc);
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
            out.source = "the Tilemap of entity '" + I.world.id_of(e) + "'";
            return out;
        }
    } else if (s.is_array() || s.is_object()) {
        asciiArgs = ascii_args_from(I, a, s);
        out.source = "the ASCII rows of `sample`";
    } else {
        bad_arg("'sample' must be an entity id, ASCII rows or an object, got " + describe_json_value(s), hint);
    }
    out.ascii = true;
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

}  // namespace

void register_wfc_commands(Engine&, Engine::Impl& I) {
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
         "smaller n mixes more freely. `tiled` ignores n and reads which tiles may touch from the autotile rules (Tilemap.terrains, "
         "tilemap.set_terrains, image.tileset.build) of the sample's Tilemap, of `into`, or from `terrains`; the sample only sets how "
         "often each tile is picked, and blob47 corners are fixed afterwards like tilemap.retile. Without rules it fails and says how "
         "to add them. `symmetry` 1 (default) uses the sample as drawn, 2 adds its mirror image, 4 its three turns, 8 turns and mirrors "
         "(use it for floors and walls, not for tiles that point somewhere). `periodic` true makes the output wrap around its edges "
         "(a tileable level) and, unless `periodicInput` says otherwise, also lets the sample wrap. `seed` (default 0) picks the "
         "level: same sample, seed and arguments, same level, on every platform. A dead end (a cell with no pattern left) restarts with "
         "the next derived seed, up to `maxAttempts` (default 10); when all fail the error says where, and what to try (a bigger or more "
         "varied sample, a smaller n, symmetry, periodic). Output: with `into` (the id of an entity with a Tilemap) the grid is written "
         "there (tileset, tileSize and solidTiles stay) in the RUNNING world; without it the grid comes back as `rows` + `legend`, ready for "
         "scene.import_ascii, and with `rows` true it comes back as well when `into` is given. Glyphs of an ASCII sample that spawn "
         "prefabs come back as the same glyph in `rows`; `into` writes only their tiles, so build objects with scene.import_ascii. "
         "A Tilemap sample is printed with generated glyphs ('.' = empty). Returns {model, width, height, seed, rows?, legend, "
         "counts: {glyph: cells}, into?, warnings?, sample: {source, width, height}, stats: {attempts, contradictions, rejected, patterns, "
         "cells, observations, propagations, ms, memoryBytes}}. Limits: output sides up to 2048, sample up to 262144 cells, 20000 patterns, "
         "about 256 MB of solver memory (the error says what to shrink). Example: tilemap.generate {\"sample\":[\"........\",\"..##....\",\"..##..#.\","
         "\"......#.\",\"..#.....\",\"........\"],\"legend\":{\"#\":0},\"size\":[32,20],\"seed\":7,\"n\":3,\"symmetry\":8}",
         parse_schema(R"json({"type":"object","required":["size"],"properties":{
               "sample":{"type":["string","array","object"],"description":"The example to learn from: the id of an entity with a Tilemap; ASCII rows (array of strings, or one string with line breaks) with `legend`; an object {rows, legend?, legendFrom?} (scene.import_ascii arguments); or a project-relative .json file with such an object. Required for model overlapping; for tiled it only sets the tile frequencies.","items":{"type":"string"}},
               "legend":{"type":"object","description":"Glyph -> tile index or {tile?, rotate?, flipX?, flipY?, prefab?...}, as in scene.import_ascii; for ASCII rows given as an array or text. '.' and ' ' are empty unless defined here."},
               "legendFrom":{"type":"string","description":"Project-relative JSON file with a shared legend (see scene.import_ascii), merged under `legend`."},
               "size":{"type":["array","object","integer"],"description":"Output size in cells: [width, height], {width, height} or one number for a square. Each side 1..2048 (and at least n for overlapping).","items":{"type":"integer"}},
               "seed":{"type":"integer","default":0,"description":"Picks the level. The same sample, seed and arguments always give the same level. Each restart after a dead end uses the next derived seed."},
               "model":{"type":"string","enum":["overlapping","tiled"],"default":"overlapping","description":"overlapping: learn the n x n patterns of the sample. tiled: tile adjacency from the autotile rules (Tilemap.terrains)."},
               "n":{"type":"integer","default":3,"minimum":2,"maximum":5,"description":"Overlapping model: side of the learned windows, 2..5. Bigger copies larger pieces of the sample; smaller mixes more. Ignored by tiled."},
               "symmetry":{"type":"integer","default":1,"enum":[1,2,4,8],"description":"1 = the sample as drawn, 2 = also mirrored left-right, 4 = also turned 90/180/270 degrees, 8 = turned and mirrored. Only for tiles that look the same turned (floor, wall); overlapping model."},
               "periodic":{"type":"boolean","default":false,"description":"The output wraps around its edges (a tileable level). Also lets the sample wrap unless periodicInput is given."},
               "periodicInput":{"type":"boolean","description":"The sample wraps around its edges (patterns cross them). Default: the value of `periodic`."},
               "maxAttempts":{"type":"integer","default":10,"minimum":1,"maximum":1000,"description":"Attempts before giving up: a dead end restarts with the next derived seed."},
               "into":{"type":"string","description":"Id of an entity with a Tilemap to write the result into (its tiles, width and height are replaced; tileset, tileSize and solidTiles stay). RUNNING world only."},
               "rows":{"type":"boolean","description":"Return the level as ASCII `rows`. Default: true without `into`, false with it."},
               "terrains":{"type":"array","items":{"type":"object"},"description":"Tiled model: autotile rules to use instead of the Tilemap's own (same objects as Tilemap.terrains)."}}})json"),
         false, "scene"},
        [&I](const Json& a) {
            // ---- arguments
            const std::string model = a.value("model", std::string("overlapping"));
            if (model != "overlapping" && model != "tiled")
                bad_arg("Unknown model '" + model + "'. " + did_you_mean(model, std::vector<std::string>{"overlapping", "tiled"}),
                        "`overlapping` learns the n x n patterns of a sample; `tiled` uses the adjacency of the autotile rules.");
            const bool tiled = model == "tiled";
            int width = 0, height = 0;
            parse_size(a, width, height);
            const int n = int_arg(a, "n", 3, wfc::kMinPatternSize, wfc::kMaxPatternSize,
                                  "n is the side of the learned windows: 2..5, usually 3. A bigger n copies larger pieces of the sample, a smaller n mixes more freely.");
            const int symmetry = int_arg(a, "symmetry", 1, 1, 8, "symmetry is 1 (as drawn), 2 (+ mirror), 4 (+ turns) or 8 (turns and mirrors).");
            if (a.contains("symmetry") && symmetry != 1 && symmetry != 2 && symmetry != 4 && symmetry != 8)
                bad_arg("'symmetry' is " + std::to_string(symmetry) + " but it must be 1, 2, 4 or 8", "1 = as drawn, 2 = also mirrored left-right, 4 = also turned, 8 = turned and mirrored.");
            const int maxAttempts = int_arg(a, "maxAttempts", kDefaultMaxAttempts, 1, wfc::kMaxAttempts,
                                            "Each attempt restarts from the next derived seed. 10 is the default; a few hundred only helps a very strict sample.");
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
            Tilemap* into = nullptr;
            if (hasInto) {
                const std::string id = a["into"].get<std::string>();
                intoEntity = need_entity(I.world, a, "into");
                into = I.world.get<Tilemap>(intoEntity);
                if (!into)
                    bad_arg("Entity '" + id + "' has no Tilemap component, so the level cannot be written into it",
                            "Pass the id of the entity that holds the Tilemap (scene.import_ascii names it 'tilemap'), or leave `into` out to get the rows back.");
            }

            SampleData sample = read_sample(I, a);
            std::vector<std::string> warnings;
            if (!tiled && !sample.present)
                bad_arg("The overlapping model needs a `sample` to learn from",
                        "Pass `sample`: the id of an entity with a Tilemap, or ASCII rows with a `legend`, e.g. \"sample\": [\"#####\",\"#...#\",\"#####\"], \"legend\": {\"#\": 0}. "
                        "To generate from autotile rules alone use \"model\": \"tiled\".");
            if (sample.present && (sample.width <= 0 || sample.height <= 0)) bad_arg("The sample is empty: it has no cells", "Give a sample with a few rows and columns.");

            // ---- the model
            std::shared_ptr<wfc::PatternModel> patternModel;
            std::vector<int> symbolTile;            // symbol id -> tile value (tile-valued symbols)
            std::vector<Terrain> terrains;
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
                std::map<int, std::uint32_t> counts;
                std::set<int> ruleTiles;
                for (const Terrain& t : terrains)
                    for (const auto& slot : t.slots)
                        for (int v : slot) ruleTiles.insert(v);
                if (sample.present) {
                    std::set<int> ignored;
                    for (int t : sample.tiles) {
                        if (t >= 0 && ruleTiles.count(t)) counts[t] += 1;
                        else if (t >= 0) ignored.insert(t);
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
                for (int v : ruleTiles) weights.push_back({v, 1u + (counts.count(v) ? counts[v] : 0u)});
                auto built = wfc::build_terrain_model(terrains, weights);
                if (!built.ok()) throw_error(built.error());
                patternModel = built->model;
                symbolTile = built->tileValues;
            }

            // ---- generate
            wfc::GenerateOptions go;
            go.width = width;
            go.height = height;
            go.periodic = periodic;
            go.seed = seed;
            go.maxAttempts = maxAttempts;
            auto gen = wfc::Generator::create(patternModel, go);
            if (!gen.ok()) throw_error(gen.error());
            wfc::Generator& g = **gen;
            if (g.run() != wfc::GenStatus::Done) throw CommandError("generation_failed", g.failure_message(), g.failure_hint());

            // ---- the result as tiles and glyphs
            const std::vector<int>& cellsOut = g.output();
            std::vector<int> tiles(cellsOut.size(), -1);
            std::vector<std::string> glyphOfCell(cellsOut.size());
            GlyphBook book(sample);
            Json legend = Json::object();
            int prefabCells = 0;
            if (!tiled && sample.ascii) {
                for (std::size_t i = 0; i < cellsOut.size(); ++i) {
                    const AsciiSampleGlyph& sg = sample.glyphs.glyphs[std::size_t(cellsOut[i])];
                    tiles[i] = sg.tile;
                    glyphOfCell[i] = sg.glyph;
                    if (sg.hasPrefab) ++prefabCells;
                    if (!sg.legendEntry.is_null()) legend[sg.glyph] = sg.legendEntry;
                }
            } else {
                for (std::size_t i = 0; i < cellsOut.size(); ++i) tiles[i] = symbolTile[std::size_t(cellsOut[i])];
                if (tiled) retile_terrain_grid(terrains, width, height, tiles);
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
                out["into"] = I.world.id_of(intoEntity);
            }
            if (sample.present)
                out["sample"] = Json::object({{"source", sample.source}, {"width", sample.width}, {"height", sample.height}});
            const wfc::GenStats& st = g.stats();
            out["stats"] = Json::object({{"attempts", st.attempts}, {"contradictions", st.contradictions}, {"rejected", st.rejected}, {"patterns", st.patterns},
                                         {"cells", st.cells}, {"observations", st.observations}, {"propagations", st.propagations},
                                         {"ms", std::round(st.ms * 10.0) / 10.0}, {"memoryBytes", st.memoryBytes}});
            if (!warnings.empty()) out["warnings"] = warnings;
            return out;
        });
}

}  // namespace fa
