#include "editor_tools.h"

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <set>

#include "fa/core/strings.h"

namespace fa::editor {

namespace {

std::string str(const Json& j, const char* key, const std::string& fallback = {}) {
    return j.is_object() && j.contains(key) && j[key].is_string() ? j[key].get<std::string>() : fallback;
}

std::vector<std::string> string_list(const Json& j) {
    std::vector<std::string> out;
    if (j.is_array())
        for (const Json& v : j)
            if (v.is_string()) out.push_back(v.get<std::string>());
    return out;
}

std::string number_text(const Json& n) {
    if (n.is_number_integer()) return std::to_string(n.get<long long>());
    if (!n.is_number()) return "?";
    char buf[32];
    std::snprintf(buf, sizeof buf, "%.4g", n.get<double>());
    return buf;
}

// "file:3:5: message" style errors keep the position the engine reported; other messages get " (hint)" appended.
std::string with_hint(const std::string& message, const std::string& hint) {
    return hint.empty() ? message : message + " " + hint;
}

}  // namespace

// ------------------------------------------------------------------------------------------------ Save as prefab
std::string suggest_prefab_path(const std::string& entityId) {
    std::string name;
    for (char c : entityId) {
        const unsigned char u = static_cast<unsigned char>(c);
        name += (std::isalnum(u) || c == '_' || c == '-' || c == '.') ? c : '_';
    }
    while (!name.empty() && name.front() == '.') name.erase(name.begin());
    if (name.empty()) name = "entity";
    return "prefabs/" + name + ".prefab.json";
}

PrefabSaveOutcome save_prefab(const CommandRegistry& commands, const std::string& entityId, const std::string& path, bool overwrite) {
    PrefabSaveOutcome out;
    Json args = Json::object({{"id", entityId}, {"path", path}});
    if (overwrite) args["overwrite"] = true;
    const CommandResult r = commands.call("prefab.save", args);
    if (!r.ok) {
        out.code = str(r.error, "code", "failed");
        out.message = str(r.error, "message", "prefab.save failed");
        out.hint = str(r.error, "hint");
        out.alreadyExists = out.code == "already_exists";
        out.path = path;
        return out;
    }
    out.ok = true;
    out.path = str(r.result, "path", path);
    out.children = r.result.value("children", std::size_t(0));
    out.overwritten = r.result.value("overwritten", false);
    out.notes = string_list(r.result.contains("notes") ? r.result["notes"] : Json());
    return out;
}

// ------------------------------------------------------------------------------------------------ Import ASCII level
namespace {

// Lines of the rows box: "\r" removed, blank lines at the top and bottom dropped (copy/paste leaves them), blank lines in the
// middle kept so the engine reports them with their row number.
std::vector<std::string> row_lines(const std::string& text) {
    std::vector<std::string> lines;
    std::string cur;
    for (char c : text) {
        if (c == '\n') {
            lines.push_back(cur);
            cur.clear();
        } else if (c != '\r') {
            cur += c;
        }
    }
    lines.push_back(cur);
    while (!lines.empty() && lines.back().empty()) lines.pop_back();
    size_t first = 0;
    while (first < lines.size() && lines[first].empty()) ++first;
    lines.erase(lines.begin(), lines.begin() + static_cast<std::ptrdiff_t>(first));
    return lines;
}

Result<Json> parse_box(const std::string& text, const char* box, bool required, const char* example) {
    if (trim(text).empty()) {
        if (required) return make_error(std::string("The ") + box + " box is empty.", std::string("Example: ") + example);
        return Json::object();
    }
    auto parsed = parse_json(text, box);
    if (!parsed.ok()) return make_error(parsed.error().message, "Fix the JSON in the " + std::string(box) + " box (the position above is line:column).");
    if (!parsed->is_object())
        return make_error(std::string("The ") + box + " box must be a JSON object { ... }, got " + describe_json_value(*parsed) + ".",
                          std::string("Example: ") + example);
    return *parsed;
}

}  // namespace

Result<Json> ascii_import_args(const AsciiImportForm& form, bool dryRun) {
    const std::vector<std::string> lines = row_lines(form.rows);
    if (lines.empty())
        return make_error("The rows box is empty.",
                          "Type the map, one row per line and ONE CHARACTER PER TILE, row 0 = the TOP row. Example:\n#####\n#.o.#\n#####");
    Json args = Json::object();
    Json rows = Json::array();
    for (const std::string& l : lines) rows.push_back(l);
    args["rows"] = rows;

    auto legend = parse_box(form.legend, "legend", true, "{\"#\": 0, \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}}");
    if (!legend.ok()) return legend.error();
    args["legend"] = *legend;

    auto tilemap = parse_box(form.tilemap, "tilemap", false, "{\"tileset\": \"assets/tiles.png\", \"tileSize\": [32, 32], \"solidTiles\": [0]}");
    if (!tilemap.ok()) return tilemap.error();
    if (!tilemap->empty()) args["tilemap"] = *tilemap;

    auto options = parse_box(form.options, "options", false, "{\"entity\": \"map\", \"anchor\": \"bottom-left\", \"position\": [0, 0]}");
    if (!options.ok()) return options.error();
    for (auto it = options->begin(); it != options->end(); ++it) {
        static const std::set<std::string> own = {"rows", "legend", "tilemap", "path", "from", "dryRun", "save"};
        if (own.count(it.key()))
            return make_error("The options box cannot contain '" + it.key() + "': it has its own place in this dialog.",
                              "Keep only entity, replace, position and anchor in options.");
        args[it.key()] = it.value();
    }

    if (form.toFile) {
        if (trim(form.path).empty())
            return make_error("The target scene file is empty.", "Type the scene file to build, e.g. scenes/level1.scene.json, or switch the target to the running scene.");
        args["path"] = std::string(trim(form.path));
        if (!trim(form.from).empty()) args["from"] = std::string(trim(form.from));
        if (dryRun) args["dryRun"] = true;
    } else if (form.save) {
        args["save"] = true;
    }
    return args;
}

Result<AsciiImportForm> load_ascii_form(const std::string& file) {
    auto j = load_json_file(file);
    if (!j.ok()) return j.error();
    if (!j->is_object()) {
        std::string what = j->is_array() ? "an array of " + std::to_string(j->size()) + " entries" : describe_json_value(*j);
        return make_error(file + ": expected one object with \"rows\" and \"legend\" (the arguments of scene.import_ascii), got " + what + ".",
                          "A level argument file looks like examples/sky-hopper/levels/level1.json: {\"rows\": [...], \"legend\": {...}, \"path\": \"scenes/level1.scene.json\"}.");
    }
    std::vector<std::string> keys;
    for (auto it = j->begin(); it != j->end(); ++it) keys.push_back(it.key());
    for (const char* need : {"rows", "legend"})
        if (!j->contains(need))
            return make_error(file + ": missing \"" + need + "\". Keys found: " + (keys.empty() ? std::string("none") : join(keys, ", ")) + ". " + did_you_mean(need, keys),
                              "scene.import_ascii needs \"rows\" (array of strings) and \"legend\" (object).");
    if (!(*j)["rows"].is_array() || !(*j)["legend"].is_object())
        return make_error(file + ": \"rows\" must be an array of strings and \"legend\" an object.",
                          "Example: {\"rows\": [\"#.#\"], \"legend\": {\"#\": 0}}.");
    AsciiImportForm form;
    std::string rows;
    for (const Json& r : (*j)["rows"]) {
        if (!r.is_string()) return make_error(file + ": every entry of \"rows\" must be a string, got " + describe_json_value(r) + ".");
        rows += r.get<std::string>() + "\n";
    }
    if (!rows.empty()) rows.pop_back();
    form.rows = rows;
    const JsonFormat compact;
    form.legend = dump_json((*j)["legend"], compact);
    if (j->contains("tilemap") && (*j)["tilemap"].is_object()) form.tilemap = dump_json((*j)["tilemap"], compact);
    form.path = str(*j, "path");
    form.from = str(*j, "from");
    form.toFile = !form.path.empty();
    form.save = j->value("save", false);
    Json rest = Json::object();
    for (auto it = j->begin(); it != j->end(); ++it) {
        static const std::set<std::string> own = {"rows", "legend", "tilemap", "path", "from", "dryRun", "save"};
        if (!own.count(it.key())) rest[it.key()] = it.value();
    }
    if (!rest.empty()) form.options = dump_json(rest, compact);
    return form;
}

std::vector<std::string> level_files(const std::vector<std::string>& projectFiles) {
    std::vector<std::string> out;
    for (const std::string& f : projectFiles) {
        const std::string lower = to_lower(f);
        if (!starts_with(lower, "levels/") || !ends_with(lower, ".json")) continue;
        if (ends_with(lower, ".scene.json") || ends_with(lower, ".prefab.json")) continue;
        out.push_back(f);
    }
    std::sort(out.begin(), out.end());
    return out;
}

AsciiImportOutcome run_ascii_import(const CommandRegistry& commands, const AsciiImportForm& form, bool dryRun) {
    AsciiImportOutcome out;
    out.dryRun = dryRun && form.toFile;
    auto args = ascii_import_args(form, dryRun);
    if (!args.ok()) {
        out.code = "invalid_argument";
        out.message = args.error().message;
        out.hint = args.error().hint;
        return out;
    }
    const CommandResult r = commands.call("scene.import_ascii", *args);
    if (!r.ok) {
        out.code = str(r.error, "code", "failed");
        out.message = str(r.error, "message", "scene.import_ascii failed");
        out.hint = str(r.error, "hint");
        return out;
    }
    const Json& res = r.result;
    out.ok = true;
    out.tilemap = str(res, "tilemap");
    out.width = res.value("width", 0);
    out.height = res.value("height", 0);
    out.tileCount = res.value("tileCount", 0);
    out.path = str(res, "path");
    out.saved = str(res, "saved");
    out.entityCount = res.value("entityCount", std::size_t(0));
    if (res.contains("removed") && res["removed"].is_array()) out.removed = res["removed"].size();
    if (res.contains("spawned") && res["spawned"].is_array()) {
        out.spawned = res["spawned"].size();
        for (const Json& s : res["spawned"]) {
            std::string line = str(s, "id") + "  " + str(s, "prefab");
            if (s.contains("cell") && s["cell"].is_array() && s["cell"].size() == 2)
                line += "  cell (" + number_text(s["cell"][0]) + ", " + number_text(s["cell"][1]) + ")";
            if (s.contains("position") && s["position"].is_array() && s["position"].size() >= 2)
                line += "  at (" + number_text(s["position"][0]) + ", " + number_text(s["position"][1]) + ")";
            out.spawnedLines.push_back(line);
        }
    }
    out.warnings = string_list(res.contains("warnings") ? res["warnings"] : Json());
    out.notes = string_list(res.contains("notes") ? res["notes"] : Json());
    return out;
}

// ------------------------------------------------------------------------------------------------ Format scene files
FormatOutcome run_scene_format(const CommandRegistry& commands, bool check, const std::vector<std::string>& paths) {
    FormatOutcome out;
    out.check = check;
    Json args = Json::object({{"check", check}});
    if (!paths.empty()) {
        Json p = Json::array();
        for (const std::string& s : paths) p.push_back(s);
        args["paths"] = p;
    }
    const CommandResult r = commands.call("scene.format", args);
    if (!r.ok) {
        out.code = str(r.error, "code", "failed");
        out.message = str(r.error, "message", "scene.format failed");
        out.hint = str(r.error, "hint");
        return out;
    }
    out.ok = true;
    const Json& res = r.result;
    out.files = string_list(res.contains(check ? "notCanonical" : "formatted") ? res[check ? "notCanonical" : "formatted"] : Json());
    out.unchanged = res.value("unchanged", std::size_t(0));
    if (res.contains("errors") && res["errors"].is_array())
        for (const Json& e : res["errors"]) out.errors.push_back(with_hint(str(e, "message", str(e, "file")), str(e, "hint")));
    out.notes = string_list(res.contains("notes") ? res["notes"] : Json());
    return out;
}

// ------------------------------------------------------------------------------------------------ Audio panel
std::size_t poll_audio_log(const CommandRegistry& commands, AudioLogState& state) {
    const CommandResult r = commands.call("audio.log", Json::object({{"after", state.after}, {"max", 1000}}));
    if (!r.ok) {
        state.error = str(r.error, "message", "audio.log failed");
        return 0;
    }
    state.error.clear();
    state.dropped = r.result.value("dropped", std::uint64_t(0));
    std::size_t added = 0;
    if (r.result.contains("plays") && r.result["plays"].is_array()) {
        for (const Json& p : r.result["plays"]) {
            AudioPlay a;
            a.seq = p.value("seq", std::uint64_t(0));
            if (a.seq <= state.after) continue;
            a.frame = p.value("frame", std::uint64_t(0));
            a.time = p.value("time", 0.0);
            a.path = str(p, "path");
            a.bus = str(p, "bus", "sfx");
            a.source = str(p, "source");
            a.volume = p.value("volume", 1.0f);
            a.pitch = p.value("pitch", 1.0f);
            a.pan = p.value("pan", 0.0f);
            a.loop = p.value("loop", false);
            a.music = p.value("music", false);
            a.ok = p.value("ok", true);
            state.plays.push_back(std::move(a));
            ++added;
        }
    }
    state.after = std::max<std::uint64_t>(state.after, r.result.value("lastSeq", std::uint64_t(0)));
    if (state.plays.size() > AudioLogState::kMax)
        state.plays.erase(state.plays.begin(), state.plays.begin() + static_cast<std::ptrdiff_t>(state.plays.size() - AudioLogState::kMax));
    return added;
}

void clear_audio_log(AudioLogState& state) {
    state.plays.clear();
}

void reset_audio_log(AudioLogState& state) {
    state.plays.clear();
    state.after = 0;
    state.scrolledTo = 0;
    state.dropped = 0;
    state.error.clear();
}

bool audio_play_visible(const AudioPlay& play, const AudioLogState& state) {
    if (state.onlyFailed && play.ok) return false;
    if (state.filter.empty()) return true;
    return to_lower(play.path).find(to_lower(state.filter)) != std::string::npos;
}

}  // namespace fa::editor
