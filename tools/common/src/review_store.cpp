// The storage of review sheets (fa/tooling/review.h): sheet folders under .factoria/review/, their manifests, and review.pick's
// moves of dropped candidates. Every write of shared state happens under the repo's cross-process lock.
#include "fa/tooling/review.h"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <format>
#include <set>
#include <system_error>

#include "fa/core/command.h"
#include "fa/core/date.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/tooling/feedback_share.h"
#include "fa/tooling/project_fs.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;

// UTF-8 whatever the platform: generic_string() on Windows is the ANSI code page, which mangles accents.
std::string utf8(const stdfs::path& p) {
    const std::u8string u = p.generic_u8string();
    return std::string(reinterpret_cast<const char*>(u.data()), u.size());
}

stdfs::path from_utf8(const std::string& s) { return stdfs::path(std::u8string(reinterpret_cast<const char8_t*>(s.data()), s.size())); }

stdfs::path project_path(const std::string& projectDir, const std::string& rel) { return from_utf8(projectDir) / from_utf8(rel); }

ReviewOutcome failure(std::string code, std::string message, std::string hint = {}) {
    ReviewOutcome o;
    o.ok = false;
    o.code = std::move(code);
    o.message = std::move(message);
    o.hint = std::move(hint);
    return o;
}

ReviewOutcome success(Json value) {
    ReviewOutcome o;
    o.value = std::move(value);
    return o;
}

std::string sheet_name(long number) { return std::format("sheet-{:04d}", number); }

// "sheet-0012" -> 12; -1 when `name` is not a sheet id (sheet- and 1 to 9 digits).
long sheet_number(const std::string& name) {
    if (name.size() < 7 || name.size() > 15 || name.compare(0, 6, "sheet-") != 0) return -1;
    long value = 0;
    for (std::size_t i = 6; i < name.size(); ++i) {
        if (!std::isdigit(static_cast<unsigned char>(name[i]))) return -1;
        value = value * 10 + (name[i] - '0');
    }
    return value;
}

// The sheet folders, ascending by number. `finishedOnly`: only those with a manifest.json.
std::vector<std::pair<long, std::string>> sheet_ids(const std::string& projectDir, bool finishedOnly) {
    std::vector<std::pair<long, std::string>> out;
    std::error_code ec;
    const stdfs::path root = project_path(projectDir, kReviewDir);
    for (stdfs::directory_iterator it(root, ec), end; !ec && it != end; it.increment(ec)) {
        std::error_code e2;
        if (!it->is_directory(e2)) continue;
        const std::u8string u = it->path().filename().u8string();
        const std::string name(reinterpret_cast<const char*>(u.data()), u.size());
        const long number = sheet_number(name);
        if (number < 0) continue;
        if (finishedOnly && !stdfs::is_regular_file(it->path() / "manifest.json", e2)) continue;
        out.emplace_back(number, name);
    }
    std::sort(out.begin(), out.end());
    return out;
}

// Takes the lock of the review folder, or says why not (nothing is changed then).
struct ReviewLock {
    ShareLock lock;
    explicit ReviewLock(const std::string& projectDir) : lock(share_env(), project_path(projectDir, kReviewDir)) {}
    bool held() const { return lock.held(); }
    ReviewOutcome busy() const {
        return failure("busy", "The review sheets of this project are being changed by another process: " + lock.error(),
                       "Nothing was changed. Try again in a few seconds.");
    }
};

// Resolves "latest", "3", "sheet-3" or "sheet-0003" to the folder name, or an error that lists the sheets there are.
ReviewOutcome resolve_sheet(const std::string& projectDir, const std::string& ref) {
    const auto all = sheet_ids(projectDir, true);
    const std::string lowered = to_lower(ref);
    if (lowered == "latest") {
        if (all.empty())
            return failure("not_found", "There is no review sheet in this project yet.", "review.sheet makes one: {\"items\":[{\"image\":\"assets/a.png\"},{\"image\":\"assets/b.png\"}]}.");
        return success(Json(all.back().second));
    }
    long number = -1;
    if (!lowered.empty() && std::all_of(lowered.begin(), lowered.end(), [](unsigned char c) { return std::isdigit(c); }) && lowered.size() <= 9)
        number = std::stol(lowered);
    else
        number = sheet_number(lowered);
    if (number >= 0) {
        const std::string name = sheet_name(number);
        for (const auto& s : all)
            if (s.second == name) return success(Json(name));
        // A longer number written with leading zeros ("sheet-00003") names the same sheet.
        for (const auto& s : all)
            if (s.first == number) return success(Json(s.second));
    }
    std::vector<std::string> names;
    for (auto it = all.rbegin(); it != all.rend() && names.size() < 12; ++it) names.push_back(it->second);
    std::string hint = names.empty() ? "There is no sheet yet: review.sheet makes one." : did_you_mean(ref, names);
    if (!names.empty()) hint += " Sheets (newest first): " + join(names, ", ") + ". review.list shows them all; \"latest\" is the newest.";
    return failure("not_found", "'" + ref + "' is not a review sheet of this project.", hint);
}

ReviewOutcome read_manifest(const std::string& projectDir, const std::string& id) {
    const std::string rel = std::string(kReviewDir) + "/" + id + "/manifest.json";
    auto text = fs::read_text(utf8(project_path(projectDir, rel)));
    if (!text.ok()) return failure("not_found", "Cannot read " + rel + ": " + text.error().message, text.error().hint);
    auto parsed = parse_json(*text, rel);
    if (!parsed.ok()) return failure("failed", rel + " is not valid JSON: " + parsed.error().message, "Delete the sheet folder " + std::string(kReviewDir) + "/" + id + " or fix the file.");
    if (!parsed->is_object() || parsed->value("format", std::string()) != kReviewFormat)
        return failure("failed", rel + " is not a " + kReviewFormat + " manifest.", "It was not written by review.sheet; leave it alone or delete the folder.");
    return success(std::move(*parsed));
}

ReviewOutcome write_text_file(const stdfs::path& file, const std::string& text) {
    auto r = fs::write_bytes(utf8(file), text.data(), text.size());
    if (!r.ok()) return failure("failed", "Cannot write " + utf8(file) + ": " + r.error().message, r.error().hint.empty() ? "Check that the disk has room and the folder is writable." : r.error().hint);
    return success(Json());
}

std::string who_name(const std::string& given) {
    if (!given.empty()) return given;
    switch (command_caller()) {
        case CommandCaller::Agent: return "agent";
        case CommandCaller::Mcp: return "mcp";
        default: return "user";
    }
}

// The project's main scene (project-relative), "" when unknown: a candidate must never be that file.
std::string main_scene_of(const std::string& projectDir) {
    auto project = load_json_file(utf8(project_path(projectDir, "factoria.json")));
    if (!project.ok() || !project->is_object()) return {};
    const auto it = project->find("mainScene");
    return it != project->end() && it->is_string() ? it->get<std::string>() : std::string();
}

bool in_vcs_folder(const std::string& key) {
    const std::string first = key.substr(0, key.find('/'));
    return first == ".git" || first == ".hg" || first == ".svn";
}

bool ends_with_text(const std::string& text, const char* tail) {
    const std::string t = tail;
    return text.size() >= t.size() && text.compare(text.size() - t.size(), t.size(), t) == 0;
}

bool starts_with_text(const std::string& text, const std::string& head) { return text.compare(0, head.size(), head) == 0; }

// A path that is certainly not project-relative: "/x", "\\x", "C:..." or "~/x".
bool looks_absolute(const std::string& rel) { return !rel.empty() && (rel[0] == '/' || rel[0] == '\\' || rel[0] == '~' || (rel.size() > 1 && rel[1] == ':')); }

// Seconds since 1970 of the engine's clock (overridable in tests through ShareEnv).
std::int64_t clock_now() { return share_env().clock(); }

struct Move {
    int n = 0;
    std::string label, from, to;
    stdfs::path absFrom, absTo;
    bool done = false;
};

// Puts back the moves already made, newest first. Returns the files that could not be put back.
std::vector<std::string> roll_back(std::vector<Move>& moves) {
    std::vector<std::string> stuck;
    for (auto it = moves.rbegin(); it != moves.rend(); ++it) {
        if (!it->done) continue;
        std::error_code ec;
        fs::replace_file(it->absTo, it->absFrom, ec);
        if (ec) stuck.push_back(it->to + " (" + ec.message() + ")");
        else it->done = false;
    }
    return stuck;
}

}  // namespace

ReviewOutcome review_reserve(const std::string& projectDir) {
    ReviewLock lock(projectDir);
    if (!lock.held()) return lock.busy();
    const auto all = sheet_ids(projectDir, false);
    const long next = all.empty() ? 1 : all.back().first + 1;
    const std::string id = sheet_name(next);
    std::error_code ec;
    stdfs::create_directories(project_path(projectDir, std::string(kReviewDir) + "/" + id + "/thumbs"), ec);
    if (ec) return failure("failed", "Cannot create " + std::string(kReviewDir) + "/" + id + ": " + ec.message(), "Check that the project folder is writable and the disk has room.");
    return success(Json::object({{"id", id}, {"dir", std::string(kReviewDir) + "/" + id}}));
}

void review_abandon(const std::string& projectDir, const std::string& id) {
    if (sheet_number(id) < 0) return;
    const stdfs::path dir = project_path(projectDir, std::string(kReviewDir) + "/" + id);
    std::error_code ec;
    if (stdfs::exists(dir / "manifest.json", ec)) return;
    fs::remove_tree(dir, ec);
}

ReviewOutcome review_commit(const std::string& projectDir, const std::string& id, Json manifest, const Image& sheet, const std::vector<ReviewThumb>& thumbs) {
    if (sheet_number(id) < 0) return failure("invalid_argument", "'" + id + "' is not a sheet id.");
    const std::string dirRel = std::string(kReviewDir) + "/" + id;
    const stdfs::path dir = project_path(projectDir, dirRel);
    for (const ReviewThumb& t : thumbs) {
        const std::vector<std::uint8_t> png = encode_png(t.picture);
        auto r = fs::write_bytes(utf8(dir / std::format("thumbs/{:02d}.png", t.n)), png.data(), png.size());
        if (!r.ok()) return failure("failed", "Cannot write the thumbnail " + std::to_string(t.n) + " of " + id + ": " + r.error().message, "Check that the disk has room.");
    }
    const std::vector<std::uint8_t> png = encode_png(sheet);
    auto picture = fs::write_bytes(utf8(dir / "sheet.png"), png.data(), png.size());
    if (!picture.ok()) return failure("failed", "Cannot write the picture of " + id + ": " + picture.error().message, "Check that the disk has room.");

    const std::int64_t now = share_env().clock();
    Json out = Json::object();
    out["format"] = kReviewFormat;
    out["id"] = id;
    out["createdAt"] = iso_utc_ms(now * 1000);
    out["createdUnix"] = now;
    out["engineVersion"] = share_env().version();
    for (auto it = manifest.begin(); it != manifest.end(); ++it) out[it.key()] = it.value();
    if (!out.contains("picked")) out["picked"] = nullptr;
    auto written = write_text_file(dir / "manifest.json", out.dump(2) + "\n");
    if (!written.ok) return written;
    return success(std::move(out));
}

ReviewOutcome review_load(const std::string& projectDir, const std::string& sheet) {
    ReviewOutcome id = resolve_sheet(projectDir, sheet);
    if (!id.ok) return id;
    return read_manifest(projectDir, id.value.get<std::string>());
}

ReviewOutcome review_list(const std::string& projectDir, int limit) {
    limit = std::clamp(limit, 1, kReviewListMax);
    const auto all = sheet_ids(projectDir, true);
    Json sheets = Json::array();
    Json unreadable = Json::array();
    for (auto it = all.rbegin(); it != all.rend() && int(sheets.size()) < limit; ++it) {
        ReviewOutcome m = read_manifest(projectDir, it->second);
        if (!m.ok) {
            unreadable.push_back(Json::object({{"id", it->second}, {"problem", m.message}}));
            continue;
        }
        const Json& j = m.value;
        Json picked = nullptr;
        std::string pickedLabel;
        const auto p = j.find("picked");
        if (p != j.end() && p->is_object()) {
            picked = p->value("n", 0);
            if (const auto pl = p->find("label"); pl != p->end() && pl->is_string()) pickedLabel = pl->get<std::string>();
        }
        Json picture = nullptr;
        if (const auto pic = j.find("picture"); pic != j.end() && pic->is_object()) picture = pic->value("path", std::string());
        const auto items = j.find("items");
        const auto meta = j.find("meta");
        sheets.push_back(Json::object({{"id", it->second},
                                       {"label", j.value("label", std::string())},
                                       {"createdAt", j.value("createdAt", std::string())},
                                       {"count", items != j.end() && items->is_array() ? int(items->size()) : 0},
                                       {"picked", picked},
                                       {"pickedLabel", pickedLabel},
                                       {"picture", picture},
                                       {"meta", meta != j.end() && meta->is_object() ? *meta : Json::object()},
                                       {"dir", std::string(kReviewDir) + "/" + it->second}}));
    }
    Json out = Json::object({{"total", int(all.size())}, {"sheets", sheets}});
    if (!unreadable.empty()) out["unreadable"] = unreadable;
    // Folders with no manifest: a sheet being made right now, or one whose process died (review_cleanup removes the old ones).
    Json orphans = Json::array();
    for (const auto& s : sheet_ids(projectDir, false))
        if (std::none_of(all.begin(), all.end(), [&](const auto& f) { return f.first == s.first; })) orphans.push_back(s.second);
    if (!orphans.empty()) out["orphans"] = orphans;
    return success(std::move(out));
}

std::string review_path_key(const std::string& rel) {
    std::string text = rel;
    std::replace(text.begin(), text.end(), '\\', '/');
    const std::string norm = fs::normalize(text);
    if (!norm.empty()) text = norm;
    std::string out;
    for (const std::string& part : split(text, '/')) {
        std::string p = part;
        const bool onlyDots = !p.empty() && p.find_first_not_of('.') == std::string::npos;
        if (!onlyDots)
            while (!p.empty() && (p.back() == '.' || p.back() == ' ')) p.pop_back();  // Windows ignores a trailing dot or space
        if (p.empty()) continue;
        if (!out.empty()) out += '/';
        out += p;
    }
    return to_lower(out);
}

std::string review_candidate_problem(const std::string& projectDir, const std::string& type, const std::string& rel) {
    if (rel.empty()) return "it names no file";
    if (looks_absolute(rel)) return "'" + rel + "' is an absolute path, and only files inside the project can be moved";
    auto norm = fs::normalize_checked(rel);
    if (!norm.ok() || norm->empty()) return "'" + rel + "' is not a path inside the project";
    auto resolved = resolve_project_path(projectDir, *norm);
    if (!resolved.ok()) return resolved.error().message;
    const std::string key = review_path_key(*norm);
    if (type == "scene") {
        if (!ends_with_text(key, ".scene.json")) return "'" + *norm + "' is not a scene (.scene.json)";
    } else if (type == "prefab") {
        if (!ends_with_text(key, ".prefab.json")) return "'" + *norm + "' is not a prefab (.prefab.json)";
    } else if (type == "vfx") {
        if (!ends_with_text(key, ".vfx.json")) return "'" + *norm + "' is not an effect (.vfx.json)";
    } else if (type == "vector") {
        if (!ends_with_text(key, ".svg")) return "'" + *norm + "' is not an SVG";
    } else if (type == "image") {
        if (!ends_with_text(key, ".png") && !ends_with_text(key, ".jpg") && !ends_with_text(key, ".jpeg") && !ends_with_text(key, ".bmp") && !ends_with_text(key, ".tga"))
            return "'" + *norm + "' is not a picture (.png, .jpg, .jpeg, .bmp, .tga)";
    } else {
        return "a '" + type + "' item has no file to move";
    }
    if (key == "factoria.json" || key == "assets.json") return "'" + *norm + "' is a file of the project itself";
    if (key == ".factoria" || starts_with_text(key, ".factoria/")) return "'" + *norm + "' is inside .factoria/, where the tools keep their own files";
    if (in_vcs_folder(key)) return "'" + *norm + "' is inside a version-control folder";
    const std::string mainScene = main_scene_of(projectDir);
    if (!mainScene.empty() && key == review_path_key(mainScene)) return "'" + *norm + "' is the main scene of the project";
    return {};
}

std::string review_drop_dir_problem(const std::string& dropDir) {
    if (dropDir.empty() || looks_absolute(dropDir)) return "'" + dropDir + "' is not a folder inside the project";
    auto norm = fs::normalize_checked(dropDir);
    if (!norm.ok() || norm->empty()) return "'" + dropDir + "' is not a folder inside the project";
    const std::string key = review_path_key(*norm);
    if (!starts_with_text(key, ".factoria/") || key.size() <= 10) return "'" + *norm + "' is not a folder below .factoria/";
    if (key == ".factoria/tmp" || starts_with_text(key, ".factoria/tmp/")) return "'" + *norm + "' is the scratch folder, which commands empty";
    if (key == ".factoria/review") return "'" + *norm + "' is the folder of the sheets themselves";
    if (starts_with_text(key, ".factoria/review/") && key != std::string(kReviewDropDir) && !starts_with_text(key, std::string(kReviewDropDir) + "/"))
        return "'" + *norm + "' is inside a sheet's folder; use " + kReviewDropDir + " or a folder outside .factoria/review/";
    return {};
}

ReviewOutcome review_pick(const std::string& projectDir, const std::string& sheet, long n, const ReviewPickOptions& options) {
    ReviewLock lock(projectDir);
    if (!lock.held()) return lock.busy();
    // Resolved under the lock: "latest" cannot move between the lookup and the change.
    ReviewOutcome idOutcome = resolve_sheet(projectDir, sheet);
    if (!idOutcome.ok) return idOutcome;
    const std::string id = idOutcome.value.get<std::string>();
    ReviewOutcome loaded = read_manifest(projectDir, id);
    if (!loaded.ok) return loaded;
    Json manifest = std::move(loaded.value);

    if (const auto p = manifest.find("picked"); p != manifest.end() && p->is_object())
        return failure("already_picked",
                       std::format("{} was already answered: number {} was picked ({}).", id, p->value("n", 0), p->value("at", std::string("earlier"))),
                       "A choice is final. To choose again make a new sheet with review.sheet. Files that were dropped are listed in the manifest (picked.dropped: from, to); move one back by hand to bring it back.");
    const auto itemsIt = manifest.find("items");
    if (itemsIt == manifest.end() || !itemsIt->is_array() || itemsIt->empty()) return failure("failed", id + " has no items.", "Make a new sheet with review.sheet.");
    const Json& items = *itemsIt;
    if (n < 1 || n > long(items.size()))
        return failure("invalid_argument", std::format("review.pick /n: {} is not on {}; its numbers go from 1 to {}.", n, id, items.size()),
                       "Use the number printed on the thumbnail the person chose. Ask them if you do not have it: never choose for them.");
    const Json& chosen = items[std::size_t(n - 1)];
    if (!chosen.value("ok", true))
        return failure("invalid_argument", std::format("review.pick /n: item {} of {} failed to render ({}), so it cannot be picked.", n, id, chosen.value("error", std::string("no reason recorded"))),
                       "Pick another number, or make a new sheet.");

    // ---- the moves ----
    // The manifest is a file anyone can edit, so nothing in it is trusted: every file to move is checked again here, exactly as
    // review.sheet checked it when the candidate was asked for, before the first one moves.
    std::vector<std::string> warnings;
    std::vector<Move> moves;
    if (options.drop) {
        const std::string manifestDrop = manifest.value("dropDir", std::string(kReviewDropDir));
        if (const std::string why = review_drop_dir_problem(manifestDrop); !why.empty())
            return failure("failed", "The manifest of " + id + " names '" + manifestDrop + "' as its drop folder: " + why + ".",
                           "Nothing was moved. Edit dropDir in the manifest to a folder below .factoria/ (the default is " + std::string(kReviewDropDir) + "), or pick with drop: false.");
        const std::string dropDir = *fs::normalize_checked(manifestDrop);
        // The files that stay: any file another item reads (the stage scene of an effect) is never moved, whoever it belongs to.
        std::set<std::string> inUse;
        for (const Json& item : items)
            if (const auto spec = item.find("spec"); spec != item.end() && spec->is_object())
                if (const auto stage = spec->find("stage"); stage != spec->end() && stage->is_string()) inUse.insert(review_path_key(stage->get<std::string>()));
        std::set<std::string> taken;  // sources already planned (paths are case-insensitive on Windows and macOS)
        const std::string chosenSource = review_path_key(chosen.value("source", std::string()));
        for (const Json& item : items) {
            const int number = item.value("n", 0);
            if (number == n || !item.value("candidate", false)) continue;
            const std::string source = item.value("source", std::string());
            if (source.empty()) continue;
            const std::string type = item.value("type", std::string());
            if (const std::string why = review_candidate_problem(projectDir, type, source); !why.empty())
                return failure("failed", std::format("Item {} of {} names '{}' as its candidate file, which review.pick may not move: {}.", number, id, source, why),
                               "Nothing was moved. Pick with drop: false, or fix `source` of that item in the manifest.");
            const std::string norm = *fs::normalize_checked(source);
            const std::string key = review_path_key(norm);
            if (inUse.count(key))
                return failure("failed", std::format("Item {} of {} would move '{}', which another item of the sheet uses as the stage of an effect.", number, id, norm),
                               "Nothing was moved. Pick with drop: false, or make the sheet again with a stage scene that is not a candidate.");
            if (key == chosenSource || !taken.insert(key).second) {
                warnings.push_back(std::format("Item {} shares its file '{}' with the picked item or another dropped one, so it was left where it is.", number, norm));
                continue;
            }
            Move m;
            m.n = number;
            m.label = item.value("label", std::string());
            m.from = norm;
            m.to = std::format("{}/{}/{:02d}_{}", dropDir, id, number, fs::filename(norm));
            if (auto where = resolve_project_path(projectDir, m.to); !where.ok())
                return failure("failed", std::format("Item {} of {} cannot be moved to '{}': {}", number, id, m.to, where.error().message), "Nothing was moved. The drop folder must be a real folder inside the project.");
            m.absFrom = project_path(projectDir, m.from);  // the file (or link) itself: it was checked to stay inside the project
            m.absTo = project_path(projectDir, m.to);
            moves.push_back(std::move(m));
        }
        // Preflight: every file is there, every destination is free. Nothing has moved yet.
        std::vector<Move> existing;
        for (Move& m : moves) {
            std::error_code ec;
            if (!stdfs::is_regular_file(m.absFrom, ec)) {
                warnings.push_back(std::format("Item {} ('{}') is no longer at '{}': there was nothing to move.", m.n, m.label, m.from));
                continue;
            }
            if (stdfs::exists(m.absTo, ec))
                return failure("exists", std::format("'{}' already exists, so item {} cannot be moved there.", m.to, m.n),
                               "Nothing was moved. Rename or remove that file (it is a leftover of an earlier pick), then pick again.");
            existing.push_back(std::move(m));
        }
        moves = std::move(existing);
        for (Move& m : moves) {
            ShareLock::keep_alive();  // a long change keeps the lock's file fresh so another process never takes it over
            std::error_code ec;
            stdfs::create_directories(m.absTo.parent_path(), ec);
            if (ec) {
                const auto stuck = roll_back(moves);
                return failure("failed", "Cannot create the drop folder for '" + m.from + "': " + ec.message(),
                               stuck.empty() ? "Nothing was changed." : "Could not put back: " + join(stuck, "; "));
            }
            fs::replace_file(m.absFrom, m.absTo, ec);
            if (ec) {
                const auto stuck = roll_back(moves);
                std::string hint = fs::is_sharing_violation(ec) ? "The file is open in another program (an editor, a viewer, an antivirus scan). Close it and pick again; nothing was changed." : "Nothing was changed.";
                if (!stuck.empty()) hint = "These could not be put back, move them by hand: " + join(stuck, "; ");
                return failure("failed", "Cannot move '" + m.from + "' to '" + m.to + "': " + ec.message() + (stuck.empty() ? " The files already moved were put back." : ""), hint);
            }
            m.done = true;
        }
    }

    // ---- record the choice ----
    std::int64_t now = clock_now();
    Json dropped = Json::array();
    for (const Move& m : moves) dropped.push_back(Json::object({{"n", m.n}, {"label", m.label}, {"from", m.from}, {"to", m.to}, {"status", "moved"}}));
    Json picked = Json::object({{"n", n},
                                {"label", chosen.value("label", std::string())},
                                {"at", iso_utc_ms(now * 1000)},
                                {"atUnix", now},
                                {"who", who_name(options.who)},
                                {"note", options.note},
                                {"drop", options.drop},
                                {"dropped", dropped},
                                {"spec", chosen.contains("spec") ? chosen["spec"] : Json::object()}});
    manifest["picked"] = picked;
    auto written = write_text_file(project_path(projectDir, std::string(kReviewDir) + "/" + id + "/manifest.json"), manifest.dump(2) + "\n");
    if (!written.ok) {
        const auto stuck = roll_back(moves);
        written.message += stuck.empty() ? " The files that were moved were put back; nothing was changed." : " These files could not be put back, move them by hand: " + join(stuck, "; ");
        return written;
    }

    // assets.json is not edited by a pick: say which of the moved files it still lists.
    if (!moves.empty()) {
        auto assets = load_json_file(utf8(project_path(projectDir, "assets.json")));
        if (assets.ok() && assets->is_object()) {
            const auto list = assets->find("assets");
            if (list != assets->end() && list->is_object())
                for (const Move& m : moves)
                    if (list->contains(m.from))
                        warnings.push_back("assets.json still lists '" + m.from + "', which moved to '" + m.to + "': remove that entry (or move the file back); project.validate reports it.");
        }
    }

    Json result = Json::object({{"sheet", id}, {"n", n}, {"label", chosen.value("label", std::string())}, {"type", chosen.value("type", std::string())},
                                {"source", chosen.value("source", std::string())}, {"spec", chosen.contains("spec") ? chosen["spec"] : Json::object()},
                                {"drop", options.drop}, {"dropped", dropped}, {"who", picked["who"]}, {"at", picked["at"]}});
    const auto meta = manifest.find("meta");
    result["meta"] = meta != manifest.end() && meta->is_object() ? *meta : Json::object();
    result["warnings"] = warnings;
    return success(std::move(result));
}

namespace {

// The newest change of anything in `dir` (itself included), nanoseconds since 1970; -1 when nothing can be read.
std::int64_t newest_change_ns(const stdfs::path& dir) {
    std::int64_t newest = fs::host_modified_time(dir);
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) newest = std::max(newest, fs::host_modified_time(it->path()));
    return newest;
}

}  // namespace

ReviewOutcome review_cleanup(const std::string& projectDir, const ReviewCleanupOptions& options) {
    ReviewLock lock(projectDir);
    if (!lock.held()) return lock.busy();
    const std::int64_t now = clock_now();
    Json expired = Json::array(), orphans = Json::array(), skipped = Json::array();
    int examined = 0, changed = 0;
    bool more = false;
    for (const auto& [number, id] : sheet_ids(projectDir, false)) {
        (void)number;
        if (changed >= kReviewCleanupMax) {
            more = true;
            break;
        }
        ShareLock::keep_alive();
        ++examined;
        const stdfs::path dir = project_path(projectDir, std::string(kReviewDir) + "/" + id);
        std::error_code ec;
        if (!stdfs::is_regular_file(dir / "manifest.json", ec)) {
            // Nothing wrote a manifest: review_commit writes it last, so this is a sheet in the making or one whose process died.
            if (options.orphanMinutes <= 0) continue;
            const std::int64_t newest = newest_change_ns(dir);
            if (newest < 0) continue;
            const std::int64_t ageSec = now - newest / 1'000'000'000;
            if (ageSec < std::int64_t(options.orphanMinutes) * 60) continue;
            if (!options.dryRun) {
                std::error_code rm;
                fs::remove_tree(dir, rm);
                if (rm) {
                    skipped.push_back(Json::object({{"sheet", id}, {"reason", "cannot remove the folder of a sheet that was never finished: " + rm.message()}}));
                    continue;
                }
            }
            orphans.push_back(id);
            ++changed;
            continue;
        }
        if (options.droppedDays <= 0) continue;
        ReviewOutcome loaded = read_manifest(projectDir, id);
        if (!loaded.ok) {
            skipped.push_back(Json::object({{"sheet", id}, {"reason", loaded.message}}));
            continue;
        }
        Json manifest = std::move(loaded.value);
        const auto pickedIt = manifest.find("picked");
        if (pickedIt == manifest.end() || !pickedIt->is_object()) continue;  // not answered: nothing was moved, and it is never expired
        Json& picked = *pickedIt;
        const auto atIt = picked.find("atUnix");
        if (atIt == picked.end() || !atIt->is_number()) continue;
        const std::int64_t at = atIt->is_number_integer() ? atIt->get<std::int64_t>() : std::int64_t(atIt->get<double>());
        if (now < at + std::int64_t(options.droppedDays) * 86400) continue;
        const auto droppedIt = picked.find("dropped");
        if (droppedIt == picked.end() || !droppedIt->is_array()) continue;
        const std::string manifestDrop = manifest.value("dropDir", std::string(kReviewDropDir));
        if (const std::string why = review_drop_dir_problem(manifestDrop); !why.empty()) {
            skipped.push_back(Json::object({{"sheet", id}, {"reason", "the drop folder '" + manifestDrop + "' is not one review.pick uses: " + why}}));
            continue;
        }
        const std::string prefix = review_path_key(*fs::normalize_checked(manifestDrop)) + "/" + to_lower(id) + "/";
        Json files = Json::array();
        bool touched = false;
        for (Json& entry : *droppedIt) {
            if (!entry.is_object() || entry.value("status", std::string()) != "moved") continue;
            ShareLock::keep_alive();
            const std::string to = entry.value("to", std::string());
            const std::string from = entry.value("from", std::string());
            const std::string key = review_path_key(to);
            // Only the file review.pick itself put in the sheet's drop folder: <dropDir>/<id>/<NN>_<name of the source>.
            const std::string expectedName = to_lower(std::format("{:02d}_{}", entry.value("n", 0), fs::filename(from)));
            if (!starts_with_text(key, prefix) || key.find('/', prefix.size()) != std::string::npos || key.substr(prefix.size()) != review_path_key(expectedName) ||
                !resolve_project_path(projectDir, to).ok()) {
                skipped.push_back(Json::object({{"sheet", id}, {"reason", "'" + to + "' is not a file review.pick put in " + prefix + ", so it was left alone"}}));
                continue;
            }
            const stdfs::path file = project_path(projectDir, to);
            std::error_code st;
            const stdfs::file_status status = stdfs::symlink_status(file, st);
            if (st || !stdfs::exists(status)) {
                if (!options.dryRun) entry["status"] = "gone";  // moved back (or removed by hand): nothing to delete
                touched = true;
                continue;
            }
            if (!stdfs::is_regular_file(status)) {
                skipped.push_back(Json::object({{"sheet", id}, {"reason", "'" + to + "' is not a plain file, so it was left alone"}}));
                continue;
            }
            if (!options.dryRun) {
                std::error_code rm;
                fs::remove_file(file, rm);
                if (rm) {
                    skipped.push_back(Json::object({{"sheet", id}, {"reason", "cannot delete '" + to + "': " + rm.message() + (fs::is_sharing_violation(rm) ? " (open in another program; the next cleanup tries again)" : "")}}));
                    continue;
                }
                entry["status"] = "expired";
            }
            files.push_back(to);
            touched = true;
        }
        if (!touched) continue;
        if (!options.dryRun) {
            auto written = write_text_file(dir / "manifest.json", manifest.dump(2) + "\n");
            if (!written.ok) {
                skipped.push_back(Json::object({{"sheet", id}, {"reason", written.message + " The files were deleted; the next cleanup marks them."}}));
            }
            std::error_code rm;
            stdfs::remove(project_path(projectDir, *fs::normalize_checked(manifestDrop) + "/" + id), rm);  // only when empty
        }
        if (!files.empty()) expired.push_back(Json::object({{"sheet", id}, {"files", files}}));
        ++changed;
    }
    Json out = Json::object({{"droppedExpired", expired}, {"orphansRemoved", orphans}, {"skipped", skipped}, {"examined", examined}, {"more", more}, {"dryRun", options.dryRun},
                             {"droppedDays", options.droppedDays}, {"orphanMinutes", options.orphanMinutes}});
    return success(std::move(out));
}

}  // namespace fa
