#include "level_gen_model.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <map>

#include "fa/core/utf8.h"

namespace fa::editor {

namespace {

std::string error_text(const CommandResult& r, std::string* hint) {
    std::string message = "the command failed";
    if (r.error.is_object()) {
        if (r.error.contains("message") && r.error["message"].is_string())
            message = r.error["message"].get<std::string>();
        if (hint && r.error.contains("hint") && r.error["hint"].is_string()) *hint = r.error["hint"].get<std::string>();
    }
    return message;
}

std::string first_line(const std::string& s) {
    const std::size_t nl = s.find('\n');
    std::string line = nl == std::string::npos ? s : s.substr(0, nl);
    if (line.size() > 160) line = line.substr(0, 157) + "...";
    return line;
}

// An integer member of a command answer, `fallback` when it is missing or of another type (json's value() throws on a wrong type).
int int_or(const Json& o, const char* key, int fallback) {
    if (!o.is_object() || !o.contains(key) || !o[key].is_number_integer()) return fallback;
    const long long v = o[key].get<long long>();
    return int(std::clamp<long long>(v, 0, 2048));  // the command's own limit of a side
}

// The tile and marker flag one legend entry gives.
LevelGenCell cell_of_legend(const Json& legend, char32_t glyph) {
    LevelGenCell c;
    c.glyph = glyph;
    const std::string key = utf8_encode(glyph);
    if (!legend.is_object() || !legend.contains(key)) return c;
    const Json& e = legend[key];
    if (e.is_number_integer()) {
        c.tile = int(std::clamp<long long>(e.get<long long>(), -1, 1 << 30));
    } else if (e.is_object()) {
        if (e.contains("tile") && e["tile"].is_number_integer())
            c.tile = int(std::clamp<long long>(e["tile"].get<long long>(), -1, 1 << 30));
        c.marker = e.contains("prefab");
    }
    return c;
}

// The table the window draws from: every cell of every row decoded once, one legend lookup per distinct glyph.
void build_cells(LevelGenPreview& p) {
    p.cells.assign(std::size_t(p.width) * std::size_t(p.height), LevelGenCell{});
    std::map<char32_t, LevelGenCell> byGlyph;
    for (int row = 0; row < p.height && row < int(p.rows.size()); ++row) {
        const std::string& text = p.rows[std::size_t(row)];
        std::size_t i = 0;
        for (int col = 0; col < p.width && i < text.size(); ++col) {
            const char32_t g = utf8_next(text, i);
            auto it = byGlyph.find(g);
            if (it == byGlyph.end()) it = byGlyph.emplace(g, cell_of_legend(p.legend, g)).first;
            p.cells[std::size_t(row) * std::size_t(p.width) + std::size_t(col)] = it->second;
        }
    }
}

}  // namespace

Result<Json> level_gen_arguments(const LevelGenOptions& o) {
    if (o.sampleFile.empty() && o.sampleEntity.empty())
        return Error{"No sample: the generator learns from a level you drew.",
                     "Select an entity with a Tilemap and press \"Use the selected Tilemap\", or type a .json level "
                     "file (rows + legend, the "
                     "format of scene.import_ascii)."};
    if (o.width < 1 || o.width > 2048 || o.height < 1 || o.height > 2048)
        return Error{"The size " + std::to_string(o.width) + " x " + std::to_string(o.height) +
                         " cells is out of range.",
                     "Each side is 1..2048; a few dozen cells make a screen-sized level and generate in a blink."};
    if (o.seed < 0 || o.seed > kLevelGenMaxSeed)
        return Error{"The seed " + std::to_string(o.seed) + " is out of range.",
                     "A seed is a whole number from 0 to 2147483647."};
    if (o.model != "overlapping" && o.model != "tiled")
        return Error{"Unknown model '" + o.model + "'.",
                     "Use \"overlapping\" (learns the sample's patterns) or \"tiled\" (the autotile rules)."};
    Json a = Json::object();
    a["sample"] = o.sampleFile.empty() ? o.sampleEntity : o.sampleFile;
    a["size"] = Json::array({o.width, o.height});
    a["seed"] = o.seed;
    a["model"] = o.model;
    if (o.model == "overlapping") {
        a["n"] = std::clamp(o.n, 2, 5);
        a["symmetry"] = (o.symmetry == 2 || o.symmetry == 4 || o.symmetry == 8) ? o.symmetry : 1;
    }
    if (o.periodic) a["periodic"] = true;
    // Whitespace only is "no extra options".
    const bool blank =
        std::all_of(o.extra.begin(), o.extra.end(), [](unsigned char c) { return std::isspace(c) != 0; });
    if (!blank) {
        Result<Json> extra = parse_json(o.extra, "the extra options");
        if (!extra.ok())
            return Error{"The extra options are not valid JSON: " + extra.error().message,
                         "Write one JSON object, for example {\"constraints\": {\"border\": {\"tile\": 0}}, "
                         "\"maxAttempts\": 20}."};
        if (!extra.value().is_object())
            return Error{
                "The extra options must be a JSON object, like {\"maxAttempts\": 20}.",
                "They are merged over the arguments above: constraints, reachability, maxAttempts, maxWork..."};
        // The fields of the window own these: a value in the options would change the level without the window (the seed in the history,
        // the size of the preview) knowing, so it is refused and the field to use is named.
        static const std::pair<const char*, const char*> owned[] = {
            {"sample", "the Sample section (\"Use the selected Tilemap\" or the level file field)"},
            {"size", "the Size field"},
            {"seed", "the Seed field (or Previous / Next / Random seed)"},
            {"model", "the Model box"},
            {"n", "the Window n slider"},
            {"symmetry", "the Symmetry box"},
            {"periodic", "the \"Wraps around its edges\" checkbox"}};
        for (auto it = extra.value().begin(); it != extra.value().end(); ++it) {
            for (const auto& [key, field] : owned)
                if (it.key() == key)
                    return Error{"The extra option '" + it.key() + "' is set by the window, not here.",
                                 std::string("Remove '") + key + "' from the options and use " + field +
                                     "; the history and the preview then show what was generated."};
            if (it.key() == "into" || it.key() == "place" || it.key() == "rows")
                return Error{"The extra option '" + it.key() + "' is not allowed here.",
                             "The window shows the level as a preview; Keep builds it in the scene. Remove '" +
                                 it.key() + "'."};
            a[it.key()] = it.value();
        }
    }
    return a;
}

void LevelGenSession::fail(const std::string& error, const std::string& hint) {
    state_ = State::Failed;
    error_ = error;
    hint_ = hint;
    job_ = 0;
    tries_.push_back(LevelGenTry{seed_, false, first_line(error)});
    if (tries_.size() > kMaxTries) tries_.erase(tries_.begin());
}

void LevelGenSession::cancel(const LevelGenCaller& call) {
    if (job_ != 0 && call) call("tilemap.generate_cancel", Json::object({{"job", job_}}));
    job_ = 0;
    if (state_ == State::Running) state_ = preview_.valid ? State::Ready : State::Idle;
}

void LevelGenSession::clear(const LevelGenCaller& call) {
    cancel(call);
    job_ = 0;
    state_ = State::Idle;
    progress_ = 0;
    preview_ = LevelGenPreview{};
    error_.clear();
    hint_.clear();
    notice_.clear();
    tries_.clear();
}

void LevelGenSession::start(const LevelGenOptions& o, const LevelGenCaller& call) {
    cancel(call);
    error_.clear();
    hint_.clear();
    notice_.clear();
    progress_ = 0;
    seed_ = o.seed;
    Result<Json> args = level_gen_arguments(o);
    if (!args.ok()) {
        fail(args.error().message, args.error().hint);
        return;
    }
    CommandResult r = call("tilemap.generate_start", args.value());
    if (!r.ok) {
        std::string hint;
        std::string message = error_text(r, &hint);
        fail(message, hint);
        return;
    }
    job_ = r.result.value("job", 0);
    state_ = job_ != 0 ? State::Running : State::Failed;
    if (job_ == 0)
        fail("The generator did not start a job.", "Update the engine: tilemap.generate_start answers {job}.");
}

bool LevelGenSession::tick(const LevelGenCaller& call, double budgetMs) {
    if (state_ != State::Running || job_ == 0) return false;
    Json a = Json::object({{"job", job_}, {"budgetMs", std::clamp(budgetMs, 0.5, 50.0)}});
    CommandResult r = call("tilemap.generate_step", a);
    if (!r.ok && r.error.is_object() && r.error.value("code", std::string()) == "not_found") {
        // The engine dropped the job: the scene changed under it (Play, a scene load). Nothing went wrong with the options, so it is a
        // note and not an error, and the last good preview stays.
        job_ = 0;
        state_ = preview_.valid ? State::Ready : State::Idle;
        notice_ = "The generation stopped because the scene changed (the game started or another scene loaded). Press "
                  "Generate to run it again.";
        return false;
    }
    if (!r.ok) {
        std::string hint;
        std::string message = error_text(r, &hint);
        fail(message, hint);  // the engine ends the job on an error
        return false;
    }
    progress_ = std::clamp(r.result.value("progress", 0.0), 0.0, 1.0);
    if (!r.result.value("done", false)) return true;
    job_ = 0;
    const Json& res = r.result.contains("result") ? r.result["result"] : Json::object();
    LevelGenPreview p;
    p.valid = res.contains("rows") && res["rows"].is_array();
    if (!p.valid) {
        fail("The generator finished without rows.",
             "Update the engine: tilemap.generate answers {rows, legend, stats}.");
        return false;
    }
    for (const Json& row : res["rows"]) p.rows.push_back(row.is_string() ? row.get<std::string>() : std::string());
    p.width = int_or(res, "width", 0);
    p.height = int_or(res, "height", int(std::min<std::size_t>(p.rows.size(), 2048)));
    if (p.width == 0)  // an answer without a usable width: the longest row says it
        for (const std::string& row : p.rows)
            p.width = std::max(p.width, int(std::min<std::size_t>(utf8_length(row), 2048)));
    p.seed = res.contains("seed") && res["seed"].is_number_integer() ? res["seed"].get<std::int64_t>() : seed_;
    if (res.contains("legend") && res["legend"].is_object()) p.legend = res["legend"];
    if (res.contains("stats") && res["stats"].is_object()) p.stats = res["stats"];
    if (res.contains("warnings") && res["warnings"].is_array())
        for (const Json& w : res["warnings"])
            if (w.is_string()) p.warnings.push_back(w.get<std::string>());
    build_cells(p);
    preview_ = std::move(p);
    state_ = State::Ready;
    progress_ = 1.0;
    const int attempts = int_or(preview_.stats, "attempts", 1);
    tries_.push_back(LevelGenTry{preview_.seed, true, std::to_string(attempts) + " attempt(s)"});
    if (tries_.size() > kMaxTries) tries_.erase(tries_.begin());
    return false;
}

LevelGenCell level_gen_cell(const LevelGenPreview& p, int col, int row) {
    if (col < 0 || row < 0 || col >= p.width || row >= p.height) return LevelGenCell{};
    const std::size_t i = std::size_t(row) * std::size_t(p.width) + std::size_t(col);
    return i < p.cells.size() ? p.cells[i] : LevelGenCell{};
}

std::string level_gen_glyph_text(const LevelGenCell& c) { return c.glyph == 0 ? std::string() : utf8_encode(c.glyph); }

Json level_gen_tilemap_fields(const Json& c) {
    Json out = Json::object();
    if (!c.is_object()) return out;
    for (const char* k : {"tileset", "tileSize", "columns", "margin", "spacing", "projection", "groundHeight",
                          "groundOffset", "solidTiles", "color", "layer"})
        if (c.contains(k)) out[k] = c[k];
    return out;
}

Json level_gen_keep_arguments(const LevelGenPreview& p, const std::string& entity, const Json& tilemapFields, double x,
                              double y) {
    Json a = Json::object();
    a["rows"] = p.rows;
    a["legend"] = p.legend;
    a["entity"] = entity;
    if (tilemapFields.is_object() && !tilemapFields.empty()) a["tilemap"] = tilemapFields;
    a["position"] = Json::array({std::round(x * 1000.0) / 1000.0, std::round(y * 1000.0) / 1000.0});
    a["anchor"] = "top-left";
    return a;
}

std::string level_gen_file_text(const LevelGenPreview& p, const std::string& entity, const Json& tilemapFields) {
    Json f = Json::object();
    f["rows"] = p.rows;
    f["legend"] = p.legend;
    if (!entity.empty()) f["entity"] = entity;
    if (tilemapFields.is_object() && !tilemapFields.empty()) f["tilemap"] = tilemapFields;
    // One row per line: the file is meant to be read and edited by hand (scene.ascii_edit works on it).
    std::string text = "{\n  \"rows\": [\n";
    for (std::size_t i = 0; i < p.rows.size(); ++i)
        text += "    " + Json(p.rows[i]).dump() + (i + 1 < p.rows.size() ? ",\n" : "\n");
    text += "  ],\n  \"legend\": " + p.legend.dump();
    if (f.contains("entity")) text += ",\n  \"entity\": " + f["entity"].dump();
    if (f.contains("tilemap")) text += ",\n  \"tilemap\": " + f["tilemap"].dump();
    text += "\n}\n";
    return text;
}

std::string level_gen_safe_name(const std::string& text) {
    std::string out;
    for (unsigned char c : text)
        if (std::isalnum(c) || c == '_' || c == '-') out.push_back(char(c));
    return out;
}

}  // namespace fa::editor
