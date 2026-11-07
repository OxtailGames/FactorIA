// review.sheet, review.pick, review.list, review.info: show N candidates as ONE numbered picture and record the one a person picks
// (docs/AI_GUIDE.md, "Show choices"; the storage is fa/tooling/review.h).
//
// review.sheet draws, for each item, a thumbnail with a big number, its label and one line of facts:
//   image   the picture as it is (colors, size, how much is transparent)        scene   the scene started and captured (GPU)
//   vector  an .svg rasterized on the CPU (size, shapes, colors)                prefab  the prefab spawned on a stage and framed (GPU)
//   level   a tilemap.generate result, one square per cell (no GPU)             vfx     the middle picture of vfx.filmstrip (GPU)
// Everything that is not a GPU item is drawn on the CPU, so the same input gives the same sheet on every machine. A scene, prefab
// or vfx item needs a graphics device like assets.preview_in_scene (no_gpu without one, before anything is written).
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <format>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <system_error>
#include <unordered_set>
#include <vector>

#include "assets_shots.h"
#include "fa/core/image_tools.h"
#include "fa/core/strings.h"
#include "fa/platform/app.h"
#include "fa/runtime/engine.h"
#include "fa/scene/bounds.h"
#include "fa/scene/components.h"
#include "fa/scene/mesh_geometry.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/review.h"
#include "headless_run.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kCommand = "review.sheet";
constexpr int kMaxSide = 8192;                 // the sheet may be this wide or tall
constexpr std::int64_t kMaxPixels = 16'777'216;  // and have this many pixels (64 MB of RGBA)
constexpr int kMaxLevelSide = 1024;            // a level thumbnail is generated up to this many cells a side
constexpr long kLevelMaxWork = 20'000'000;     // tilemap.generate `maxWork` when the item does not set it: a thumbnail must be quick
constexpr std::uint64_t kMaxImagePixels = 64'000'000;       // a picture is read up to this many pixels (256 MB decoded), checked from its header first
constexpr std::uintmax_t kMaxImageBytes = 64u * 1024u * 1024u;
constexpr std::uintmax_t kMaxSvgBytes = 8u * 1024u * 1024u;
constexpr int kColorCountCap = 1000;           // distinct colors are counted up to this many
constexpr int kStageSide = 512;                // design size of the stage a prefab is filmed on
constexpr int kVfxStageSide = 256;             // and the plain stage an effect is filmed on
constexpr int kPad = 8;
constexpr int kGap = 14;

[[noreturn]] void bad(const std::string& pointer, const std::string& what, const std::string& hint) { arg_error(kCommand, pointer, what, hint); }

std::string utf8(const stdfs::path& p) {
    const std::u8string u = p.generic_u8string();
    return std::string(reinterpret_cast<const char*>(u.data()), u.size());
}

[[noreturn]] void throw_outcome(const ReviewOutcome& o) { throw CommandError(o.code.empty() ? "failed" : o.code, o.message, o.hint); }

template <class T>
bool whole_number(const Json& v, double lo, double hi, T& out) {
    if (!v.is_number()) return false;
    const double d = v.get<double>();
    if (!(d >= lo && d <= hi) || d != std::floor(d)) return false;
    out = static_cast<T>(d);
    return true;
}

bool ends_with_text(const std::string& text, const char* tail) {
    const std::string t = tail;
    return text.size() >= t.size() && text.compare(text.size() - t.size(), t.size(), t) == 0;
}

// "1 entity", "3 entities".
std::string counted(std::size_t n, const char* one, const char* many) { return std::to_string(n) + " " + (n == 1 ? one : many); }

double round2(double v) { return std::round(v * 100.0) / 100.0; }

// ---- the request ---------------------------------------------------------------------------------------------------------------

const std::vector<std::string> kTypeKeys = {"image", "scene", "prefab", "level", "vector", "vfx"};
const std::vector<std::string> kItemKeys = {"image", "scene", "prefab", "level", "vector", "vfx", "label", "candidate", "steps", "stage", "seeds", "sampleScene"};

struct Item {
    int n = 0;               // 1-based number on the sheet (after a level's seeds are expanded)
    std::string type;        // image | scene | prefab | level | vector | vfx
    std::string source;      // the project file ("" for a level)
    std::string label;
    bool candidate = false;  // review.pick moves `source` away when another item is picked
    Json spec;               // the item as asked (a level: its arguments with the seed filled in)
    Json levelArgs;          // level: the arguments of tilemap.generate
    std::string levelScene;  // level: the scene the engine starts from when `sample` names an entity ("" = a stage with only a camera)
    int steps = 2;           // scene: frames to run before the picture
    std::string stage;       // vfx: the scene to play the effect in ("" = a plain dark stage)
    std::string pointer;     // "/items/3" in the request
    bool gpu() const { return type == "scene" || type == "prefab" || type == "vfx"; }
};

struct Request {
    std::vector<Item> items;
    std::string label;
    long columns = 0;     // 0 = automatic
    long thumbSize = 0;   // 0 = automatic
    std::string dropDir;
    Json meta = Json::object();  // the caller's own object, stored with the sheet and returned by pick / info / list
};

std::string main_scene(const std::string& projectDir) {
    auto project = load_json_file(utf8(project_file(projectDir, "factoria.json")));
    if (!project.ok() || !project->is_object()) return {};
    const auto it = project->find("mainScene");
    return it != project->end() && it->is_string() ? it->get<std::string>() : std::string();
}

[[noreturn]] void missing_file(const std::string& projectDir, const std::string& pointer, const std::string& rel, const char* kind) {
    std::vector<std::string> names;
    std::error_code ec;
    const std::string parent = fs::parent(rel);
    const stdfs::path folder = project_file(projectDir, parent.empty() ? "." : parent);
    const std::string ext = to_lower(fs::extension(rel));
    for (stdfs::directory_iterator it(folder, ec), end; !ec && it != end && names.size() < 300; it.increment(ec)) {
        std::error_code e2;
        if (!it->is_regular_file(e2)) continue;
        const std::u8string u = it->path().filename().u8string();
        const std::string name(reinterpret_cast<const char*>(u.data()), u.size());
        if (to_lower(fs::extension(name)) == ext) names.push_back(name);
    }
    std::string hint = did_you_mean(fs::filename(rel), names);
    if (hint.empty()) hint = std::string("assets.list shows the files of the project; give the project-relative path of ") + kind + ".";
    bad(pointer, "'" + rel + "' does not exist.", hint);
}

// The project path in `item[key]`, normalized: inside the project (no absolute path, no "..", no link that leads out), ending in one of
// `suffixes` (compared in lower case) and an existing file. Every problem is an argument error with its JSON pointer.
std::string path_member(const std::string& projectDir, const Json& item, const std::string& pointer, const std::string& key, const char* what,
                        const char* example, const std::vector<std::string>& suffixes) {
    const Json& v = item[key];
    const std::string at = pointer + "/" + key;
    if (!v.is_string() || v.get<std::string>().empty()) bad(at, std::string("expected the project path of ") + what + " as a string.", std::string("Example: \"") + example + "\".");
    const std::string given = v.get<std::string>();
    auto norm = fs::normalize_checked(given);
    if (given[0] == '/' || given[0] == '\\' || given[0] == '~' || (given.size() > 1 && given[1] == ':') || !norm.ok() || norm->empty())
        bad(at, "'" + given + "' is not a path inside the project.", std::string("Use a project-relative path such as \"") + example + "\".");
    const std::string lowered = to_lower(*norm);
    const bool suffixOk = std::any_of(suffixes.begin(), suffixes.end(), [&](const std::string& t) {
        return lowered.size() >= t.size() && lowered.compare(lowered.size() - t.size(), t.size(), t) == 0;
    });
    if (!suffixOk) {
        const std::string ext = to_lower(fs::extension(*norm));
        bad(at, "'" + *norm + "' is not " + what + " (" + (ext.empty() ? "no extension" : "it ends in " + ext) + ").", "Expected a file ending in " + join(suffixes, ", ") + ", such as \"" + example + "\".");
    }
    auto resolved = resolve_project_path(projectDir, *norm);
    if (!resolved.ok()) bad(at, resolved.error().message, resolved.error().hint.empty() ? std::string("Use a project-relative path such as \"") + example + "\"." : resolved.error().hint);
    std::error_code ec;
    if (!stdfs::is_regular_file(*resolved, ec)) missing_file(projectDir, at, *norm, what);
    return *norm;
}

std::string base_label(const std::string& rel) {
    std::string name = fs::filename(rel);
    for (const char* tail : {".scene.json", ".prefab.json", ".vfx.json"}) {
        const std::string t = tail;
        if (name.size() > t.size() && to_lower(name).compare(name.size() - t.size(), t.size(), t) == 0) return name.substr(0, name.size() - t.size());
    }
    const auto dot = name.find_last_of('.');
    return dot == std::string::npos || dot == 0 ? name : name.substr(0, dot);
}

// The cells of the level asked for, so a size over the cap is refused now with its JSON pointer.
void check_level_size(const Json& level, const std::string& pointer) {
    const auto it = level.find("size");
    if (it == level.end()) return;
    const std::string at = pointer + "/size";
    auto side = [&](const Json& v, const std::string& where) {
        long cells = 0;
        if (!whole_number(v, 1, 1e9, cells)) bad(where, "expected a whole number of cells, 1 or more.", "Example: \"size\": [40, 24].");
        if (cells > kMaxLevelSide)
            bad(where, std::format("{} cells is more than a thumbnail needs (the most is {} per side).", cells, kMaxLevelSide), "Review a smaller level (a sample of the same style at 40 x 24 shows what the seed does), then generate the full size with tilemap.generate.");
    };
    if (it->is_number()) side(*it, at);
    else if (it->is_array() && it->size() == 2) {
        side((*it)[0], at + "/0");
        side((*it)[1], at + "/1");
    } else if (it->is_object() && it->contains("width") && it->contains("height")) {
        side((*it)["width"], at + "/width");
        side((*it)["height"], at + "/height");
    } else {
        bad(at, "expected [width, height], {width, height} or one number.", "Example: \"size\": [40, 24].");
    }
}

Request parse_request(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "review.sheet expects an object.", "Pass {\"items\":[{\"image\":\"assets/a.png\"},{\"image\":\"assets/b.png\"}]}.");
    check_arg_keys(kCommand, a, "", {"items", "label", "columns", "thumbSize", "candidates", "dropDir", "meta"});
    Request req;
    if (!a.contains("items") || !a["items"].is_array() || a["items"].empty())
        bad("/items", "expected a list of 1 to " + std::to_string(kReviewMaxItems) + " items.", "Example: {\"items\":[{\"image\":\"assets/a.png\"},{\"scene\":\"scenes/level2.scene.json\"},{\"level\":{\"sample\":\"example\",\"size\":[40,24]},\"seeds\":[1,2,3]}]}.");
    if (a["items"].size() > std::size_t(kReviewMaxItems))
        bad("/items", std::format("{} items are too many for one sheet; the most is {}.", a["items"].size(), kReviewMaxItems), "A person picks better from 4 to 9. Make two sheets, or drop the weakest candidates first.");
    if (a.contains("label") && !a["label"].is_null()) {
        if (!a["label"].is_string() || a["label"].get<std::string>().size() > 120) bad("/label", "expected a short text (at most 120 characters).", "Example: \"Hero portrait, round 2\".");
        req.label = a["label"].get<std::string>();
    }
    if (a.contains("columns") && !a["columns"].is_null() && !whole_number(a["columns"], 1, 12, req.columns))
        bad("/columns", "expected a whole number from 1 to 12.", "Thumbnails per row. Leave it out for a nearly square sheet.");
    if (a.contains("thumbSize") && !a["thumbSize"].is_null() && !whole_number(a["thumbSize"], 64, 512, req.thumbSize))
        bad("/thumbSize", "expected a whole number from 64 to 512.", "Pixels of the square each thumbnail is fitted into. Leave it out to choose from the number of items.");
    const bool allCandidates = tooling_detail::arg_bool(a, "candidates", false);
    req.dropDir = kReviewDropDir;
    if (a.contains("dropDir") && !a["dropDir"].is_null()) {
        const std::string hint = "Candidates that are not picked are MOVED there, never deleted. Example: \".factoria/assets/candidates\". Leave it out for " + std::string(kReviewDropDir) + ".";
        if (!a["dropDir"].is_string()) bad("/dropDir", "expected a project-relative folder below .factoria/.", hint);
        const std::string given = a["dropDir"].get<std::string>();
        if (const std::string why = review_drop_dir_problem(given); !why.empty()) bad("/dropDir", why + ".", hint);
        req.dropDir = *fs::normalize_checked(given);
        if (auto resolved = resolve_project_path(projectDir, req.dropDir); !resolved.ok()) bad("/dropDir", resolved.error().message, hint);
    }
    if (a.contains("meta") && !a["meta"].is_null()) {
        if (!a["meta"].is_object()) bad("/meta", "expected an object.", "Your own facts about this sheet, kept with it and returned by review.pick, review.info and review.list. Example: {\"slot\": \"hero\"}.");
        if (a["meta"].dump().size() > std::size_t(kReviewMetaMaxBytes)) bad("/meta", std::format("takes more than {} bytes written as JSON.", kReviewMetaMaxBytes), "Keep a key or two (the slot the choice is for); big data belongs in a file of the project.");
        req.meta = a["meta"];
    }

    const std::string mainScenePath = main_scene(projectDir);
    // Every file the items read, by comparison key: the item that read it and whether it is a candidate. A pick moves candidates, so a
    // candidate's file may be read by no other item (and no effect may use it as its stage).
    struct FileUse {
        std::size_t first = 0;
        bool candidate = false;
    };
    std::map<std::string, FileUse> files;
    std::vector<std::pair<std::string, std::string>> stages;  // (key of the stage scene, pointer of the item that plays in it)
    const Json& list = a["items"];
    for (std::size_t i = 0; i < list.size(); ++i) {
        const Json& item = list[i];
        const std::string pointer = "/items/" + std::to_string(i);
        if (!item.is_object())
            bad(pointer, "expected an object with one of " + join(kTypeKeys, ", ") + ".", "Example: {\"image\": \"assets/hero_a.png\", \"label\": \"A\"}.");
        check_arg_keys(kCommand, item, pointer, kItemKeys);
        std::vector<std::string> present;
        for (const std::string& k : kTypeKeys)
            if (item.contains(k)) present.push_back(k);
        if (present.empty()) bad(pointer, "an item needs one of " + join(kTypeKeys, ", ") + ".", "Example: {\"scene\": \"scenes/level2.scene.json\"}; `label` and `candidate` are the only keys that go with any of them.");
        if (present.size() > 1) bad(pointer, "an item shows ONE thing, but it has " + join(present, " and ") + ".", "Put each in its own item.");
        const std::string type = present.front();
        if (item.contains("steps") && type != "scene") bad(pointer + "/steps", "`steps` belongs to a scene item.", "It is the number of frames the scene runs before the picture.");
        if (item.contains("stage") && type != "vfx") bad(pointer + "/stage", "`stage` belongs to a vfx item.", "It is the scene the effect plays in.");
        if (item.contains("seeds") && type != "level") bad(pointer + "/seeds", "`seeds` belongs to a level item.", "It makes one thumbnail per seed from the same arguments.");
        if (item.contains("sampleScene") && type != "level") bad(pointer + "/sampleScene", "`sampleScene` belongs to a level item.", "It is the scene whose Tilemap entity `level.sample` names.");

        Item base;
        base.type = type;
        base.pointer = pointer;
        if (item.contains("label") && !item["label"].is_null()) {
            if (!item["label"].is_string() || item["label"].get<std::string>().size() > 80) bad(pointer + "/label", "expected a short text (at most 80 characters).", "Example: \"A: round face\".");
            base.label = item["label"].get<std::string>();
        }
        base.candidate = allCandidates && type != "level";
        if (item.contains("candidate") && !item["candidate"].is_null()) {
            if (!item["candidate"].is_boolean()) bad(pointer + "/candidate", "expected true or false.", "true: review.pick moves this item's file away when another item is picked. Default false.");
            if (type == "level" && item["candidate"].get<bool>()) bad(pointer + "/candidate", "a level is not a file, so there is nothing to move.", "Leave `candidate` out of level items: a pick only records the seed.");
            if (type != "level") base.candidate = item["candidate"].get<bool>();
        }

        if (type == "level") {
            const Json& level = item["level"];
            if (!level.is_object() || level.empty()) bad(pointer + "/level", "expected the arguments of tilemap.generate as an object.", "Example: {\"sample\": \"example\", \"size\": [40, 24]}; `seeds` goes next to `level`, not inside it.");
            if (level.contains("into")) bad(pointer + "/level/into", "a review never writes into a Tilemap.", "Leave `into` out: the thumbnail comes from the returned rows. Generate the picked level with tilemap.generate afterwards.");
            if (level.contains("seeds")) bad(pointer + "/level/seeds", "`seeds` goes next to `level`, not inside it.", "Example: {\"level\": {...}, \"seeds\": [1, 2, 3]}.");
            check_level_size(level, pointer + "/level");
            // `sample` is an entity id or name, ASCII rows (array, object or text with line breaks) or the path of a rows file. Only the first
            // needs a scene to look the entity up in: `sampleScene`, else the project's main scene.
            std::string sceneRel;
            const std::string sampleText = level.contains("sample") && level["sample"].is_string() ? level["sample"].get<std::string>() : std::string();
            const bool rowsFile = ends_with_text(to_lower(sampleText), ".json");
            const bool entitySample = !sampleText.empty() && sampleText.find('\n') == std::string::npos && !rowsFile;
            if (item.contains("sampleScene") && !item["sampleScene"].is_null()) {
                if (!entitySample)
                    bad(pointer + "/sampleScene", "`sampleScene` is only used when level.sample is the id or name of an entity with a Tilemap.", "Leave it out, or give `level.sample` as an entity id; ASCII rows and rows files need no scene.");
                sceneRel = path_member(projectDir, item, pointer, "sampleScene", "a scene", "scenes/town.scene.json", {".scene.json"});
            } else if (entitySample) {
                sceneRel = mainScenePath.empty() ? std::string() : fs::normalize(mainScenePath);
                std::error_code ec;
                if (sceneRel.empty() || !stdfs::is_regular_file(project_file(projectDir, sceneRel), ec))
                    bad(pointer + "/level/sample", "'" + sampleText + "' names an entity, but there is no scene to look it up in: the project has no main scene.",
                        "Give `sampleScene` next to `level` (the scene whose Tilemap entity it is), or use ASCII rows: {\"sample\": [\"#..#\", \"#..#\"], \"legend\": {\"#\": 0, \".\": 1}}.");
            }
            if (rowsFile && sampleText.find('\n') == std::string::npos) {
                auto rows = resolve_project_path(projectDir, sampleText);
                if (!rows.ok()) bad(pointer + "/level/sample", rows.error().message, "A rows file is a project path such as \"data/town_rows.json\".");
            }
            std::vector<long long> seeds;
            if (item.contains("seeds")) {
                if (level.contains("seed")) bad(pointer + "/seeds", "`seeds` and level.seed are both given.", "Use `seeds` for several levels, or `seed` inside `level` for one.");
                const Json& s = item["seeds"];
                if (!s.is_array() || s.empty() || s.size() > std::size_t(kReviewMaxItems)) bad(pointer + "/seeds", std::format("expected a list of 1 to {} seeds.", kReviewMaxItems), "Example: [1, 2, 3, 4].");
                for (std::size_t k = 0; k < s.size(); ++k) {
                    long long seed = 0;
                    if (!whole_number(s[k], 0, 4294967295.0, seed)) bad(pointer + "/seeds/" + std::to_string(k), "expected a whole number from 0 to 4294967295.", "A seed picks one level: the same sample, arguments and seed always give the same level.");
                    seeds.push_back(seed);
                }
            } else {
                long long seed = 0;
                if (level.contains("seed") && !whole_number(level["seed"], 0, 4294967295.0, seed))
                    bad(pointer + "/level/seed", "expected a whole number from 0 to 4294967295.", "A seed picks one level.");
                seeds.push_back(seed);
            }
            for (std::size_t k = 0; k < seeds.size(); ++k) {
                Item it = base;
                it.levelScene = sceneRel;
                it.levelArgs = level;
                it.levelArgs["seed"] = seeds[k];
                if (!it.levelArgs.contains("maxWork")) it.levelArgs["maxWork"] = kLevelMaxWork;
                Json spec = level;
                spec["seed"] = seeds[k];
                it.spec = Json::object({{"level", spec}});
                if (!sceneRel.empty()) it.spec["sampleScene"] = sceneRel;
                const std::string seedText = "seed " + std::to_string(seeds[k]);
                it.label = base.label.empty() ? "level " + seedText : base.label + (item.contains("seeds") ? " " + seedText : "");
                req.items.push_back(std::move(it));
            }
            continue;
        }

        static const std::vector<std::string> imageExt = {".png", ".jpg", ".jpeg", ".bmp", ".tga"};
        if (type == "image") base.source = path_member(projectDir, item, pointer, "image", "a picture", "assets/hero.png", imageExt);
        else if (type == "scene") base.source = path_member(projectDir, item, pointer, "scene", "a scene", "scenes/level2.scene.json", {".scene.json"});
        else if (type == "prefab") base.source = path_member(projectDir, item, pointer, "prefab", "a prefab", "prefabs/enemy.prefab.json", {".prefab.json"});
        else if (type == "vector") base.source = path_member(projectDir, item, pointer, "vector", "an SVG", "assets/art/logo.svg", {".svg"});
        else base.source = path_member(projectDir, item, pointer, "vfx", "an effect", "assets/vfx/hit.vfx.json", {".vfx.json"});
        base.spec = Json::object({{type, base.source}});
        if (type == "scene" && item.contains("steps")) {
            long steps = 0;
            if (!whole_number(item["steps"], 0, 600, steps)) bad(pointer + "/steps", "expected a whole number from 0 to 600.", "Frames the scene runs before the picture (scripts start, a spawner settles). Default 2.");
            base.steps = int(steps);
            base.spec["steps"] = steps;
        }
        if (type == "vfx" && item.contains("stage") && !item["stage"].is_null()) {
            base.stage = path_member(projectDir, item, pointer, "stage", "a scene", "scenes/arena.scene.json", {".scene.json"});
            base.spec["stage"] = base.stage;
            stages.emplace_back(review_path_key(base.stage), pointer);
        }
        if (base.label.empty()) base.label = base_label(base.source);
        const std::string fileKey = review_path_key(base.source);
        if (base.candidate) {
            // The same checks review.pick makes again before it moves anything.
            if (const std::string why = review_candidate_problem(projectDir, type, base.source); !why.empty())
                bad(pointer + "/candidate", why + ": review.pick would move it away.", "Leave `candidate` off it. Only files you MADE as variants for this choice are candidates.");
        }
        if (const auto used = files.find(fileKey); used != files.end() && (used->second.candidate || base.candidate))
            bad(pointer + "/" + type, "'" + base.source + "' is already the file of item " + std::to_string(used->second.first + 1) + (used->second.candidate || base.candidate ? ", and a pick moves candidates away" : "") + ".",
                "Each candidate file appears once on a sheet, and no other item may show it: a pick moves the files of the items that were not chosen. Copy the file for the second use, or drop `candidate`.");
        else if (used == files.end())
            files[fileKey] = {i, base.candidate};
        else if (base.candidate) used->second.candidate = true;
        req.items.push_back(std::move(base));
    }
    // An effect's stage scene is read while the sheet is drawn, and again by whoever plays the effect: it must not be moved by the pick.
    for (const auto& [stageKey, stagePointer] : stages) {
        const auto used = files.find(stageKey);
        if (used != files.end() && used->second.candidate)
            bad(stagePointer + "/stage", "that scene is a candidate of item " + std::to_string(used->second.first + 1) + ": review.pick would move the stage away.", "Leave `candidate` off the stage scene, or use a stage that is not a candidate.");
    }
    if (req.items.size() > std::size_t(kReviewMaxItems))
        bad("/items", std::format("the items make {} thumbnails once the `seeds` are expanded; the most is {}.", req.items.size(), kReviewMaxItems), "Use fewer seeds or fewer items.");
    for (std::size_t i = 0; i < req.items.size(); ++i) req.items[i].n = int(i) + 1;
    return req;
}

// ---- the layout ----------------------------------------------------------------------------------------------------------------

struct Layout {
    int columns = 1, rows = 1, thumb = 128;
    int labelPx = 13, numberPx = 28;
    int headerH = 0, infoH = 0, cellW = 0, cellH = 0, titleH = 36;
    int width = 0, height = 0;
};

// The sheet for `count` thumbnails; false (with `problem` and the argument it blames) when it would be over the caps.
bool plan_layout(int count, long columnsAsked, long thumbAsked, Layout& out, std::string& problem, std::string& pointer) {
    Layout l;
    l.columns = columnsAsked > 0 ? int(std::min<long>(columnsAsked, count)) : (count <= 4 ? count : std::min(12, int(std::ceil(std::sqrt(count * 1.5)))));
    l.rows = (count + l.columns - 1) / l.columns;
    auto measure = [&](int thumb) {
        Layout m = l;
        m.thumb = thumb;
        m.labelPx = std::clamp(thumb / 14, 12, 18);
        m.numberPx = std::clamp(thumb / 4, 28, 56);
        m.headerH = m.numberPx + 10;
        m.infoH = 2 * (m.labelPx + 4);
        m.cellW = thumb + 2 * kPad;
        m.cellH = kPad + m.headerH + kPad / 2 + thumb + 4 + m.infoH + kPad;
        m.width = kGap + m.columns * (m.cellW + kGap);
        m.height = m.titleH + kGap + m.rows * (m.cellH + kGap);
        return m;
    };
    auto fits = [](const Layout& m) {
        return m.width <= kMaxSide && m.height <= kMaxSide && std::int64_t(m.width) * std::int64_t(m.height) <= kMaxPixels;
    };
    if (thumbAsked > 0) {
        out = measure(int(thumbAsked));
        if (fits(out)) return true;
        problem = std::format("{} thumbnails of {} px in {} columns make a sheet of {} x {} px; the limit is {} px a side and {} million pixels.", count, thumbAsked, l.columns,
                              out.width, out.height, kMaxSide, kMaxPixels / 1'000'000);
        pointer = "/thumbSize";
        return false;
    }
    int thumb = std::clamp((1800 - kGap) / l.columns - kGap - 2 * kPad, 96, 320);
    for (; thumb >= 64; thumb -= 16) {
        out = measure(thumb);
        if (fits(out)) return true;
    }
    out = measure(64);
    problem = std::format("{} thumbnails in {} columns make a sheet of {} x {} px even at 64 px each; the limit is {} px a side.", count, l.columns, out.width, out.height, kMaxSide);
    pointer = columnsAsked > 0 ? "/columns" : "/items";
    return false;
}

// ---- drawing -------------------------------------------------------------------------------------------------------------------

struct Rendered {
    Image picture;                   // straight-alpha RGBA of any size; fitted into the thumbnail area later
    bool ok = true;
    std::string error;               // why the thumbnail failed (ok == false)
    std::string info;                // the line under the thumbnail: facts separated by ", "
    Json numbers = Json::object();   // the same facts for a program
    std::vector<std::string> warnings;
};

Rendered failed_tile(std::string why) {
    Rendered r;
    r.ok = false;
    r.error = std::move(why);
    r.info = "failed";
    return r;
}

Image blank(int w, int h, Rgb8 c) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(std::size_t(w) * std::size_t(h) * 4, 255);
    fill_rect_rgb(img, 0, 0, w, h, c);
    return img;
}

// `text` cut to fit `maxW` pixels, ending in "..." when it had to be.
std::string fit_text(const std::string& text, float px, int maxW) {
    if (text_width(text, px) <= maxW) return text;
    std::string cut = text;
    while (!cut.empty() && text_width(cut + "...", px) > maxW) cut.pop_back();
    return cut + "...";
}

// Words wrapped to lines of at most `maxW` pixels; at most `maxLines`, the last one ends in "..." when text is left over.
std::vector<std::string> wrap_text(const std::string& text, float px, int maxW, int maxLines) {
    std::vector<std::string> lines;
    std::string line;
    std::size_t pos = 0;
    bool cut = false;
    while (pos < text.size()) {
        std::size_t end = text.find(' ', pos);
        if (end == std::string::npos) end = text.size();
        const std::string word = text.substr(pos, end - pos);
        pos = end + 1;
        if (word.empty()) continue;
        const std::string tryLine = line.empty() ? word : line + " " + word;
        if (line.empty() || text_width(tryLine, px) <= maxW) {
            line = tryLine;
            continue;
        }
        lines.push_back(line);
        line = word;
        if (int(lines.size()) == maxLines) {
            cut = true;
            break;
        }
    }
    if (!cut && !line.empty()) lines.push_back(line);
    if (int(lines.size()) > maxLines) {
        lines.resize(std::size_t(maxLines));
        cut = true;
    }
    for (std::string& l : lines) l = fit_text(l, px, maxW);
    if (cut && !lines.empty()) lines.back() = fit_text(lines.back() + "...", px, maxW);
    return lines;
}

// `src` fitted into an `area` x `area` square: shrunk with averaging, grown by a whole factor (hard pixels stay hard).
Image fit_picture(const Image& src, int area) {
    if (src.width <= 0 || src.height <= 0) return src;
    const int longest = std::max(src.width, src.height);
    if (longest > area) {
        const double scale = double(area) / longest;
        return resize_area(src, std::max(1, int(std::lround(src.width * scale))), std::max(1, int(std::lround(src.height * scale))));
    }
    const int k = std::max(1, area / longest);
    return k == 1 ? src : resize_area(src, src.width * k, src.height * k);
}

Image placeholder(int w, int h, const std::string& text, Rgb8 textColor) {
    Image img = blank(w, h, {40, 40, 48});
    const float px = 18.0f;
    int y = h / 2 - 12;
    for (const std::string& line : wrap_text(text, px, w - 16, 3)) {
        draw_text(img, (w - text_width(line, px)) / 2, y, line, px, textColor);
        y += 24;
    }
    return img;
}

// ---- the renderers that need no GPU --------------------------------------------------------------------------------------------

// The size a picture announces in its header, so a small file that holds a huge picture is refused BEFORE its pixels are made.
// PNG, BMP and JPEG are recognised by their signature, TGA (it has none) by `tgaExtension`. False: not recognised.
bool declared_size(const std::vector<std::uint8_t>& d, bool tgaExtension, std::uint64_t& width, std::uint64_t& height) {
    auto le16 = [&](std::size_t at) { return std::uint64_t(d[at]) | (std::uint64_t(d[at + 1]) << 8); };
    auto le32 = [&](std::size_t at) { return le16(at) | (le16(at + 2) << 16); };
    auto be16 = [&](std::size_t at) { return (std::uint64_t(d[at]) << 8) | std::uint64_t(d[at + 1]); };
    auto be32 = [&](std::size_t at) { return (be16(at) << 16) | be16(at + 2); };
    if (d.size() >= 24 && d[0] == 0x89 && d[1] == 'P' && d[2] == 'N' && d[3] == 'G') {
        width = be32(16);
        height = be32(20);
        return true;
    }
    if (d.size() >= 26 && d[0] == 'B' && d[1] == 'M') {
        if (le32(14) == 12) {  // the old core header: 16-bit sizes
            width = le16(18);
            height = le16(20);
        } else {  // 32-bit signed sizes; a negative height is a top-down picture
            const std::int64_t w = std::int32_t(le32(18)), h = std::int32_t(le32(22));
            width = std::uint64_t(w < 0 ? -w : w);
            height = std::uint64_t(h < 0 ? -h : h);
        }
        return true;
    }
    if (d.size() >= 4 && d[0] == 0xFF && d[1] == 0xD8) {  // JPEG: walk the segments to the first start-of-frame
        std::size_t at = 2;
        while (at + 4 <= d.size()) {
            if (d[at] != 0xFF) return false;
            const std::uint8_t marker = d[at + 1];
            if (marker == 0xFF) {  // fill byte
                ++at;
                continue;
            }
            if (marker == 0xD8 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {  // markers without a length
                at += 2;
                continue;
            }
            const std::size_t length = std::size_t(be16(at + 2));
            if (marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) {
                if (at + 9 > d.size()) return false;
                height = be16(at + 5);
                width = be16(at + 7);
                return true;
            }
            if (marker == 0xD9 || marker == 0xDA || length < 2) return false;  // the pixels start before any frame header: not a picture we can size
            at += 2 + length;
        }
        return false;
    }
    if (tgaExtension && d.size() >= 18) {
        width = le16(12);
        height = le16(14);
        return true;
    }
    return false;
}

Rendered render_image(const stdfs::path& file) {
    std::error_code ec;
    const std::uintmax_t bytes = stdfs::file_size(file, ec);
    if (!ec && bytes > kMaxImageBytes) return failed_tile(std::format("the file is {} MB; the most a review reads is {} MB", bytes / (1024 * 1024), kMaxImageBytes / (1024 * 1024)));
    Result<Image> loaded(Error{"not read", ""});
    {
        auto data = read_bytes(file);
        if (!data.ok()) return failed_tile(data.error().message);
        std::uint64_t w = 0, h = 0;
        if (declared_size(*data, to_lower(fs::extension(utf8(file))) == ".tga", w, h) && w * h > kMaxImagePixels)  // 64-bit: both are at most 2^32
            return failed_tile(std::format("the picture is {}x{}; the most a review reads is {} million pixels", w, h, kMaxImagePixels / 1'000'000));
        loaded = decode_image(data->data(), data->size());
    }  // the file's bytes are freed before the pixels are counted
    if (!loaded.ok()) return failed_tile(loaded.error().message);
    Rendered r;
    const Image& img = *loaded;
    std::unordered_set<std::uint32_t> colors;
    std::size_t clear = 0, total = std::size_t(img.width) * std::size_t(img.height);
    bool capped = false;
    for (std::size_t i = 0; i + 3 < img.rgba.size(); i += 4) {
        if (img.rgba[i + 3] == 0) {
            ++clear;
            continue;
        }
        if (capped) continue;
        colors.insert(std::uint32_t(img.rgba[i]) << 24 | std::uint32_t(img.rgba[i + 1]) << 16 | std::uint32_t(img.rgba[i + 2]) << 8 | img.rgba[i + 3]);
        if (colors.size() > std::size_t(kColorCountCap)) capped = true;
    }
    const int percent = total == 0 ? 0 : int(std::lround(100.0 * double(clear) / double(total)));
    const std::string colorText = capped ? std::to_string(kColorCountCap) + "+" : std::to_string(colors.size());
    r.info = std::format("{}x{}, {}, {}% clear", img.width, img.height, capped ? colorText + " colors" : counted(colors.size(), "color", "colors"), percent);
    r.numbers = Json::object({{"width", img.width}, {"height", img.height}, {"colors", capped ? kColorCountCap : int(colors.size())}, {"colorsCapped", capped}, {"transparentPercent", percent}});
    r.picture = std::move(*loaded);  // moved, not copied: the decoded picture can be 256 MB
    return r;
}

Rendered render_vector(const stdfs::path& file, int area) {
    std::error_code ec;
    const std::uintmax_t bytes = stdfs::file_size(file, ec);
    if (!ec && bytes > kMaxSvgBytes) return failed_tile(std::format("the file is {} MB; the most a review reads is {} MB", bytes / (1024 * 1024), kMaxSvgBytes / (1024 * 1024)));
    auto data = read_bytes(file);
    if (!data.ok()) return failed_tile(data.error().message);
    const std::string text(data->begin(), data->end());
    Rendered r;
    try {
        std::vector<std::string> warnings;
        SvgRaster raster = rasterize_svg_text(text, area, area, "none", 0.0, 0, warnings);
        r.picture = std::move(raster.image);
        r.warnings = std::move(warnings);
        // The shapes and colors are counted from the text of the file: a quick measure, not a parse.
        int shapes = 0;
        for (const char* tag : {"<path", "<rect", "<circle", "<ellipse", "<polygon", "<polyline", "<line"})
            for (std::size_t p = text.find(tag); p != std::string::npos; p = text.find(tag, p + 1)) ++shapes;
        std::set<std::string> colors;
        for (std::size_t p = text.find('#'); p != std::string::npos; p = text.find('#', p + 1)) {
            std::size_t e = p + 1;
            while (e < text.size() && std::isxdigit(static_cast<unsigned char>(text[e]))) ++e;
            if (e - p - 1 == 3 || e - p - 1 == 6) colors.insert(to_lower(text.substr(p, e - p)));
        }
        const int w = int(std::lround(raster.svgWidth)), h = int(std::lround(raster.svgHeight));
        r.info = std::format("{}x{}, {}, {}", w, h, counted(std::size_t(shapes), "shape", "shapes"), counted(colors.size(), "color", "colors"));
        r.numbers = Json::object({{"width", w}, {"height", h}, {"shapes", shapes}, {"colors", int(colors.size())}});
    } catch (const CommandError& e) {
        return failed_tile(e.what());
    }
    return r;
}

Rgb8 glyph_color(char g) {
    if (g == '.' || g == ' ') return {38, 42, 52};
    if (g == '#') return {128, 124, 140};
    static const Rgb8 palette[] = {{214, 92, 92}, {92, 168, 214}, {104, 190, 112}, {226, 184, 76}, {176, 112, 208},
                                   {86, 196, 190}, {230, 130, 70}, {150, 150, 70}, {200, 100, 160}, {120, 140, 230}};
    return palette[static_cast<unsigned char>(g) % 10];
}

// One square per cell, `cell` pixels a side; letters on the squares when they are big enough to read.
Image draw_level(const std::vector<std::string>& rows, int width, int height, int cell) {
    Image img = blank(width * cell, height * cell, {20, 22, 28});
    for (int y = 0; y < height; ++y) {
        const std::string& row = rows[std::size_t(y)];
        for (int x = 0; x < width; ++x) {
            const char g = std::size_t(x) < row.size() ? row[std::size_t(x)] : ' ';
            const Rgb8 c = glyph_color(g);
            const int inset = cell >= 6 ? 1 : 0;
            fill_rect_rgb(img, x * cell + inset, y * cell + inset, cell - inset, cell - inset, c);
            if (cell >= 12 && g != '.' && g != ' ') {
                const std::string letter(1, g);
                const float px = float(cell) * 0.7f;
                const Rgb8 on = c.r + c.g + c.b > 3 * 128 ? Rgb8{20, 20, 24} : Rgb8{235, 235, 240};
                draw_text(img, x * cell + (cell - text_width(letter, px)) / 2, y * cell + int(float(cell) * 0.08f), letter, px, on);
            }
        }
    }
    return img;
}

Rendered render_level(Engine& engine, const Item& item, int area) {
    CommandResult res = engine.commands().call("tilemap.generate", item.levelArgs);
    if (!res.ok) {
        const std::string code = res.error.value("code", std::string());
        const std::string message = res.error.value("message", std::string());
        // A problem with the arguments is the caller's to fix, for every seed alike; a level that could not be made is one tile.
        if (code == "invalid_argument" || code == "not_found")
            throw CommandError("invalid_argument", std::string(kCommand) + " " + item.pointer + "/level: " + message, res.error.value("hint", std::string("tilemap.generate describes every argument.")));
        return failed_tile(message);
    }
    const Json& out = res.result;
    const auto rowsIt = out.find("rows");
    if (rowsIt == out.end() || !rowsIt->is_array()) return failed_tile("tilemap.generate returned no rows");
    std::vector<std::string> rows;
    for (const Json& row : *rowsIt) rows.push_back(row.is_string() ? row.get<std::string>() : std::string());
    const int height = int(std::min<std::size_t>(rows.size(), kMaxLevelSide));
    int width = 0;
    for (const std::string& row : rows) width = std::max(width, int(std::min<std::size_t>(row.size(), kMaxLevelSide)));
    if (width <= 0 || height <= 0) return failed_tile("the level is empty");
    const int cell = std::clamp(area / std::max(width, height), 1, 16);
    Rendered r;
    r.picture = draw_level(rows, width, height, cell);
    long attempts = 1;
    if (const auto stats = out.find("stats"); stats != out.end() && stats->is_object()) attempts = stats->value("attempts", 1L);
    Json counts = Json::object();
    if (const auto c = out.find("counts"); c != out.end() && c->is_object()) counts = *c;
    r.info = std::format("{}x{}, seed {}, {} {}", width, height, item.levelArgs.value("seed", 0LL), attempts, attempts == 1 ? "try" : "tries");
    r.numbers = Json::object({{"width", width}, {"height", height}, {"seed", item.levelArgs.value("seed", 0LL)}, {"attempts", attempts}, {"counts", counts}});
    return r;
}

// ---- the renderers that need the GPU -------------------------------------------------------------------------------------------

struct TempFile {
    stdfs::path file;
    ~TempFile() {
        std::error_code ec;
        if (!file.empty()) fs::remove_file(file, ec);
    }
};

// The picture of `engine` now, straight alpha (the GPU leaves premultiplied pixels). "" when taken; else why not. No graphics at all is an
// error of the whole command (no_gpu).
std::string capture_picture(Engine& engine, Image& img) {
    std::string err;
    if (!engine.capture_scaled(img, 1.0, &err)) {
        if (err.find("No renderer") != std::string::npos) no_gpu_error(kCommand, err, "Leave the scene, prefab and vfx items out: images, vector art and levels need no GPU.");
        return err.empty() ? "the picture could not be captured" : err;
    }
    for (std::size_t p = 0; p + 3 < img.rgba.size(); p += 4) {
        const unsigned a = img.rgba[p + 3];
        if (a == 0 || a == 255) continue;
        for (int k = 0; k < 3; ++k) img.rgba[p + k] = std::uint8_t(std::min(255u, (img.rgba[p + k] * 255u + a / 2) / a));
    }
    return {};
}

std::string first_script_error(Engine& engine) {
    const auto& errors = engine.scripts().errors();
    return errors.empty() ? std::string() : errors.front().to_string();
}

// A scene file with a camera (id review_camera) and an empty node (id review_pivot) under .factoria/tmp/, removed with `guard`.
std::string write_stage(const std::string& projectDir, const std::string& sheetId, const char* tag, TempFile& guard) {
    const std::string rel = std::string(fs::kScratchDir) + "/review-" + sheetId + "-" + tag + ".scene.json";
    Json camera = Json::object({{"id", "review_camera"},
                                {"components", Json::object({{"Transform", Json::object()},
                                                             {"Camera", Json::object({{"projection", "orthographic"}, {"primary", true}, {"clearColor", Json::array({0.1, 0.1, 0.13, 1})}})}})}});
    Json pivot = Json::object({{"id", "review_pivot"}, {"components", Json::object({{"Transform", Json::object()}})}});
    const Json scene = Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({camera, pivot})}});
    guard.file = project_file(projectDir, rel);
    const std::string text = scene.dump(2);
    auto written = fs::write_bytes(utf8(guard.file), text.data(), text.size());
    if (!written.ok()) fail("failed", "Cannot write the stage scene for the thumbnails: " + written.error().message, "Check that .factoria/tmp/ is writable.");
    return rel;
}

// The engine with graphics that films the scene, prefab and effect items of a sheet. One engine lives at a time (the graphics backend is
// one per process) and is reused for every item of the same view size: a scene or an effect on its own stage films at the project's
// own size (0 x 0), a prefab on a 512 px stage, an effect on the plain stage at 256 px. The engine starts on a stage scene this class
// writes (a camera and an empty node), so a broken scene of the user cannot be mistaken for a missing graphics device: the first start
// failing is an error of the whole command (no_gpu when the device is the reason), never a red tile. Items are drawn grouped by size.
class GpuSession {
public:
    GpuSession(std::string projectDir, std::string sheetId) : projectDir_(std::move(projectDir)), sheetId_(std::move(sheetId)) {}
    GpuSession(const GpuSession&) = delete;
    GpuSession& operator=(const GpuSession&) = delete;
    ~GpuSession() { close(); }

    // The engine for a view of w x h design pixels (0 x 0: the project's own), started on the stage scene.
    Engine& engine(int w, int h) {
        if (engine_ && w_ == w && h_ == h) return *engine_;
        close();
        auto started = std::make_unique<Engine>();
        EngineConfig cfg = tooling_detail::headless_engine_config(projectDir_, stage_rel(), true, RenderMode::OnDemand);
        cfg.width = w;
        cfg.height = h;
        std::string err;
        if (!started->init(cfg, nullptr, &err)) {
            if (err.find("No renderer") != std::string::npos || err.find("graphics") != std::string::npos)
                no_gpu_error(kCommand, err, "Leave the scene, prefab and vfx items out: images, vector art and levels need no GPU.");
            fail("failed", "Cannot start the engine that films the scenes, prefabs and effects: " + (err.empty() ? std::string("it did not start") : err),
                 "Nothing was written. Images, vector art and levels need no engine with graphics: leave the scene, prefab and vfx items out.");
        }
        engine_ = std::move(started);
        w_ = w;
        h_ = h;
        return *engine_;
    }
    // The stage scene (project-relative), written on first use and removed with the session.
    const std::string& stage_rel() {
        if (stage_.empty()) stage_ = write_stage(projectDir_, sheetId_, "stage", guard_);
        return stage_;
    }
    // The world of the stage afresh (the effects and prefabs of the last item gone) and no script error left over. "" or why not.
    std::string load_stage(Engine& e) { return load(e, stage_rel()); }
    // Loads a scene of the project: its script errors start from none. "" or why not.
    std::string load(Engine& e, const std::string& sceneRel) {
        e.scripts().clear_errors();
        std::string err;
        if (!e.load_scene(sceneRel, &err)) return err.empty() ? "the scene did not load" : err;
        return {};
    }

private:
    void close() {
        if (engine_) engine_->shutdown();
        engine_.reset();
    }
    std::string projectDir_, sheetId_, stage_;
    TempFile guard_;
    std::unique_ptr<Engine> engine_;
    int w_ = -1, h_ = -1;
};

Rendered render_scene(GpuSession& session, const Item& item) {
    Engine& engine = session.engine(0, 0);
    Rendered r;
    if (std::string err = session.load(engine, item.source); !err.empty()) return failed_tile("the scene did not start: " + err);
    if (item.steps > 0) engine.step(item.steps);
    if (std::string e = first_script_error(engine); !e.empty()) r.warnings.push_back("A script of '" + item.source + "' failed (item " + std::to_string(item.n) + "): " + e);
    if (std::string err = capture_picture(engine, r.picture); !err.empty()) return failed_tile(err);
    const auto entities = engine.world().entity_count();
    r.info = std::format("{}, {}x{}", counted(std::size_t(entities), "entity", "entities"), r.picture.width, r.picture.height);
    r.numbers = Json::object({{"entities", entities}, {"width", r.picture.width}, {"height", r.picture.height}, {"steps", item.steps}});
    return r;
}

struct Box {
    Vec3 lo{1e30f, 1e30f, 1e30f}, hi{-1e30f, -1e30f, -1e30f};
    bool any = false;
    void add(const Vec3& p) {
        lo = {std::min(lo.x, p.x), std::min(lo.y, p.y), std::min(lo.z, p.z)};
        hi = {std::max(hi.x, p.x), std::max(hi.y, p.y), std::max(hi.z, p.z)};
        any = true;
    }
};

void collect_subtree(World& w, Entity e, std::vector<Entity>& out) {
    out.push_back(e);
    for (Entity c : w.children(e)) collect_subtree(w, c, out);
}

Rendered render_prefab(GpuSession& session, const Item& item) {
    Engine& engine = session.engine(kStageSide, kStageSide);
    if (std::string err = session.load_stage(engine); !err.empty()) return failed_tile("the stage did not start: " + err);
    World& world = engine.world();
    CommandResult spawned = engine.commands().call("scene.spawn", Json::object({{"prefab", item.source}, {"parent", "review_pivot"}, {"position", Json::array({0, 0, 0})}}));
    if (!spawned.ok) return failed_tile(spawned.error.value("message", std::string("the prefab could not be spawned")));
    const Entity root = world.find_by_id(spawned.result.value("id", std::string()));
    const Entity cameraEntity = world.find_by_id("review_camera");
    const Entity pivot = world.find_by_id("review_pivot");
    if (root == kNullEntity || cameraEntity == kNullEntity || pivot == kNullEntity) return failed_tile("the prefab did not spawn");
    engine.step(1);  // scripts start, children made by a script exist
    Rendered r;
    if (std::string e = first_script_error(engine); !e.empty()) r.warnings.push_back("A script of the prefab '" + item.source + "' failed (item " + std::to_string(item.n) + "): " + e);

    std::vector<Entity> subtree;
    collect_subtree(world, root, subtree);
    // 2D: the union of the visuals' rectangles. 3D: the boxes of the meshes.
    std::optional<Rect> rect;
    for (Entity e : subtree) {
        auto er = entity_world_rect(world, e);
        if (!er) continue;
        if (!rect) {
            rect = *er;
            continue;
        }
        const float x0 = std::min(rect->x, er->x), y0 = std::min(rect->y, er->y);
        const float x1 = std::max(rect->x + rect->w, er->x + er->w), y1 = std::max(rect->y + rect->h, er->y + er->h);
        rect = Rect{x0, y0, x1 - x0, y1 - y0};
    }
    Box box;
    for (Entity e : subtree) {
        const MeshRenderer* mesh = world.get<MeshRenderer>(e);
        if (!mesh) continue;
        Vec3 lo{-0.5f, -0.5f, -0.5f}, hi{0.5f, 0.5f, 0.5f};
        const std::string ext = to_lower(fs::extension(mesh->mesh));
        if (ext == ".glb" || ext == ".gltf") {
            auto geometry = load_mesh_geometry(mesh->mesh);
            if (!geometry.ok()) continue;
            lo = (*geometry)->bmin;
            hi = (*geometry)->bmax;
        }
        const Mat4 m = world.world_matrix(e);
        for (int corner = 0; corner < 8; ++corner) {
            const float x = corner & 1 ? hi.x : lo.x, y = corner & 2 ? hi.y : lo.y, z = corner & 4 ? hi.z : lo.z;
            box.add({m.m[0] * x + m.m[4] * y + m.m[8] * z + m.m[12], m.m[1] * x + m.m[5] * y + m.m[9] * z + m.m[13], m.m[2] * x + m.m[6] * y + m.m[10] * z + m.m[14]});
        }
    }
    Camera* camera = world.get<Camera>(cameraEntity);
    if (!camera) return failed_tile("the stage lost its camera");
    if (rect && rect->w > 0 && rect->h > 0) {
        const float side = std::max(rect->w, rect->h) * 1.2f;
        camera->orthoSize = std::max(1.0f, side * 0.5f);
        world.set_world_position(cameraEntity, {rect->x + rect->w * 0.5f, rect->y + rect->h * 0.5f, world.world_position(cameraEntity).z});
        r.info = std::format("{}, {}x{}", counted(subtree.size(), "entity", "entities"), int(std::lround(rect->w)), int(std::lround(rect->h)));
        r.numbers = Json::object({{"entities", int(subtree.size())}, {"width", round2(rect->w)}, {"height", round2(rect->h)}});
    } else if (box.any) {
        const Vec3 centre = (box.lo + box.hi) * 0.5f;
        const Vec3 half = (box.hi - box.lo) * 0.5f;
        const float radius = std::max(1e-3f, std::sqrt(half.x * half.x + half.y * half.y + half.z * half.z));
        const float fov = 40.0f;
        const float distance = radius / std::sin(fov * 0.5f * 3.14159265f / 180.0f) * 1.08f;
        if (Transform* t = world.get<Transform>(root)) t->position = t->position - centre;
        if (Transform* t = world.get<Transform>(pivot)) t->rotation = {18, -32, 0};
        camera->projection = Projection::Perspective;
        camera->fov = fov;
        camera->nearPlane = distance * 0.02f;
        camera->farPlane = distance * 8.0f;
        camera->lighting = CameraLighting::Studio;
        world.set_world_position(cameraEntity, {0, 0, distance});
        const Vec3 size = box.hi - box.lo;
        r.info = std::format("{}, 3D {:.1f}x{:.1f}x{:.1f}", counted(subtree.size(), "entity", "entities"), size.x, size.y, size.z);
        r.numbers = Json::object({{"entities", int(subtree.size())}, {"sizeX", round2(size.x)}, {"sizeY", round2(size.y)}, {"sizeZ", round2(size.z)}});
    } else {
        r.picture = placeholder(kStageSide, kStageSide, "no visuals", {170, 170, 180});
        r.info = std::format("{}, no visuals", counted(subtree.size(), "entity", "entities"));
        r.numbers = Json::object({{"entities", int(subtree.size())}, {"visuals", 0}});
        r.warnings.push_back("The prefab '" + item.source + "' (item " + std::to_string(item.n) + ") has nothing to draw: no Sprite, Shape2D, Text or MeshRenderer.");
        return r;
    }
    engine.step(1);
    if (std::string err = capture_picture(engine, r.picture); !err.empty()) return failed_tile(err);
    return r;
}

Rendered render_vfx(GpuSession& session, const std::string& projectDir, const std::string& sheetId, const Item& item) {
    TempFile strip;
    // An effect on its own stage films at the project's size (that scene's camera and backdrop); on the plain stage at 256 px.
    Engine& engine = item.stage.empty() ? session.engine(kVfxStageSide, kVfxStageSide) : session.engine(0, 0);
    if (std::string err = item.stage.empty() ? session.load_stage(engine) : session.load(engine, item.stage); !err.empty()) return failed_tile("the stage did not start: " + err);
    const std::string stripRel = std::string(fs::kScratchDir) + "/review-" + sheetId + "-vfx-" + std::to_string(item.n) + ".png";
    strip.file = project_file(projectDir, stripRel);
    CommandResult film = engine.commands().call("vfx.filmstrip", Json::object({{"effect", item.source}, {"frames", 3}, {"columns", 3}, {"size", 256}, {"zoom", 1}, {"path", stripRel}}));
    if (!film.ok) {
        if (film.error.value("code", std::string()) == "unavailable" && film.error.value("message", std::string()).find("No renderer") != std::string::npos)
            no_gpu_error(kCommand, film.error.value("message", std::string()), "Leave the scene, prefab and vfx items out.");
        return failed_tile(film.error.value("message", std::string("vfx.filmstrip failed")));
    }
    auto loaded = load_image(strip.file);
    if (!loaded.ok()) return failed_tile("the film strip could not be read: " + loaded.error().message);
    const Json& fr = film.result;
    const int columns = fr.value("columns", 3), tw = fr.value("tileWidth", 0), th = fr.value("tileHeight", 0);
    const SheetLayout layout = sheet_layout(3, columns, tw, th);
    if (tw <= 0 || th <= 0 || layout.width != loaded->width || layout.height != loaded->height) return failed_tile("the film strip has an unexpected size");
    Rendered r;
    // The middle picture of three: halfway through the effect. The label in its corner is its time.
    r.picture = crop_image(*loaded, layout.gap + (1 % layout.columns) * (tw + layout.gap), layout.gap + (1 / layout.columns) * (th + layout.gap), tw, th);
    int peak = 0;
    double settled = 0;
    CommandResult budget = engine.commands().call("vfx.budget", Json::object({{"path", item.source}}));
    if (budget.ok) {
        peak = budget.result.value("peakParticles", 0);
        settled = budget.result.value("settledAt", 0.0);
    } else {
        r.warnings.push_back("vfx.budget failed for '" + item.source + "' (item " + std::to_string(item.n) + "): " + budget.error.value("message", std::string()));
    }
    const double duration = fr.value("duration", 0.0);
    r.info = std::format("peak {}, {:.1f} s", counted(std::size_t(std::max(peak, 0)), "particle", "particles"), std::max(duration, settled));
    r.numbers = Json::object({{"peakParticles", peak}, {"settledAt", round2(settled)}, {"duration", round2(duration)}});
    return r;
}

// ---- the sheet ----------------------------------------------------------------------------------------------------------------

struct Composed {
    Image sheet;
    std::vector<ReviewThumb> thumbs;
    Json cells = Json::array();  // per item: {cell, picture} rectangles
};

Composed compose(const Layout& l, const std::vector<Item>& items, const std::vector<Rendered>& rendered, const std::string& title, const std::string& id) {
    Composed c;
    c.sheet = blank(l.width, l.height, {24, 24, 30});
    const Rgb8 white{238, 238, 244}, dim{150, 150, 164};
    draw_text(c.sheet, kGap, 6, fit_text(title, 20.0f, l.width - 2 * kGap - 140), 20.0f, white);
    const int idW = text_width(id, 14.0f);
    draw_text(c.sheet, l.width - kGap - idW, 12, id, 14.0f, dim);
    for (std::size_t i = 0; i < items.size(); ++i) {
        const Item& item = items[i];
        const Rendered& r = rendered[i];
        const int col = int(i) % l.columns, row = int(i) / l.columns;
        const int cx = kGap + col * (l.cellW + kGap), cy = l.titleH + kGap + row * (l.cellH + kGap);
        fill_rect_rgb(c.sheet, cx, cy, l.cellW, l.cellH, {42, 42, 52});
        // the number
        const std::string number = std::to_string(item.n);
        const float numPx = float(l.numberPx);
        const int badgeW = std::max(l.headerH, text_width(number, numPx) + 18);
        fill_rect_rgb(c.sheet, cx + kPad, cy + kPad, badgeW, l.headerH, r.ok ? Rgb8{242, 183, 5} : Rgb8{190, 70, 70});
        draw_text(c.sheet, cx + kPad + (badgeW - text_width(number, numPx)) / 2, cy + kPad + 3, number, numPx, {20, 20, 26});
        // the label
        const float labelPx = float(l.labelPx);
        const int labelX = cx + kPad + badgeW + 8;
        draw_text(c.sheet, labelX, cy + kPad + (l.headerH - l.labelPx) / 2 - 2, fit_text(item.label, labelPx, cx + l.cellW - kPad - labelX), labelPx, white);
        // the picture
        const int px = cx + kPad, py = cy + kPad + l.headerH + kPad / 2;
        fill_rect_rgb(c.sheet, px, py, l.thumb, l.thumb, {30, 30, 38});
        Image fitted;
        if (r.ok) {
            fitted = fit_picture(r.picture, l.thumb);
            draw_over(c.sheet, fitted, px + (l.thumb - fitted.width) / 2, py + (l.thumb - fitted.height) / 2);
        } else {
            fitted = placeholder(l.thumb, l.thumb, r.error, {240, 140, 140});
            draw_over(c.sheet, fitted, px, py);
        }
        // the facts
        int ty = py + l.thumb + 4;
        for (const std::string& line : wrap_text(r.info, labelPx, l.thumb, 2)) {
            draw_text(c.sheet, px, ty, line, labelPx, dim);
            ty += l.labelPx + 4;
        }
        c.thumbs.push_back({item.n, std::move(fitted)});
        c.cells.push_back(Json::object({{"cell", Json::object({{"x", cx}, {"y", cy}, {"w", l.cellW}, {"h", l.cellH}})},
                                        {"picture", Json::object({{"x", px}, {"y", py}, {"w", l.thumb}, {"h", l.thumb}})}}));
    }
    return c;
}

struct Reserved {
    std::string projectDir, id;
    bool keep = false;
    ~Reserved() {
        if (!keep && !id.empty()) review_abandon(projectDir, id);
    }
};

Json sheet_command(const std::string& projectDir, const Json& a) {
    Request req = parse_request(projectDir, a);
    Layout layout;
    {
        std::string problem, pointer;
        if (!plan_layout(int(req.items.size()), req.columns, req.thumbSize, layout, problem, pointer))
            bad(pointer, problem, pointer == "/thumbSize" ? "Use a smaller thumbSize, more columns, or fewer items." : "Fewer items, or make two sheets.");
    }
    const bool needGpu = std::any_of(req.items.begin(), req.items.end(), [](const Item& i) { return i.gpu(); });
    if (needGpu && gfx_device_active()) return call_in_child(projectDir, kCommand, a);

    ProjectRootGuard root(projectDir);
    ReviewOutcome reserved = review_reserve(projectDir);
    if (!reserved.ok) throw_outcome(reserved);
    Reserved guard{projectDir, reserved.value.value("id", std::string())};
    const std::string id = guard.id;

    std::vector<Rendered> rendered(req.items.size());
    std::vector<std::string> warnings;
    // Each picture is fitted into its thumbnail right after it is drawn and the original dropped: a sheet of 48 big pictures must not hold
    // 48 big pictures (the thumbnails are at most 512 px a side).
    auto shrink = [&](Rendered& r) {
        if (r.ok && !r.picture.rgba.empty()) {
            Image small = fit_picture(r.picture, layout.thumb);
            r.picture = std::move(small);
        }
    };
    // The pictures that need no GPU first (their argument errors come before any engine starts), then the levels, then the GPU.
    for (std::size_t i = 0; i < req.items.size(); ++i) {
        const Item& item = req.items[i];
        if (item.type == "image") rendered[i] = render_image(project_file(projectDir, item.source));
        else if (item.type == "vector") rendered[i] = render_vector(project_file(projectDir, item.source), layout.thumb);
        else continue;
        shrink(rendered[i]);
    }
    // Levels: one engine (graphics off) per scene the `sample` entities are looked up in; the others start on a stage with only a camera.
    std::vector<std::string> levelScenes;
    for (const Item& item : req.items)
        if (item.type == "level" && std::find(levelScenes.begin(), levelScenes.end(), item.levelScene) == levelScenes.end()) levelScenes.push_back(item.levelScene);
    if (!levelScenes.empty()) {
        TempFile stage;
        const std::string stageRel = write_stage(projectDir, id, "level", stage);
        for (const std::string& scene : levelScenes) {
            Engine engine;
            std::string err;
            const std::string startScene = scene.empty() ? stageRel : scene;
            if (!engine.init(tooling_detail::headless_engine_config(projectDir, startScene, false, RenderMode::OnDemand), nullptr, &err)) {
                const auto first = std::find_if(req.items.begin(), req.items.end(), [&](const Item& i) { return i.type == "level" && i.levelScene == scene; });
                if (!scene.empty()) bad(first->pointer + "/level/sample", "the scene '" + scene + "' did not load, so the entity cannot be looked up: " + err, "Fix the scene (project.validate), or give another `sampleScene`, or ASCII rows as the sample.");
                fail("failed", "Cannot start the engine that generates the levels: " + err);
            }
            struct Shutdown {
                Engine& e;
                ~Shutdown() { e.shutdown(); }
            } shutdown{engine};
            for (std::size_t i = 0; i < req.items.size(); ++i) {
                if (req.items[i].type != "level" || req.items[i].levelScene != scene) continue;
                rendered[i] = render_level(engine, req.items[i], layout.thumb);
                shrink(rendered[i]);
            }
        }
    }
    {
        // The GPU items, grouped by the size of their view so one engine serves all of a size (stable: items keep their order inside a group).
        std::vector<std::size_t> order;
        for (std::size_t i = 0; i < req.items.size(); ++i)
            if (req.items[i].gpu()) order.push_back(i);
        auto viewSide = [&](const Item& item) { return item.type == "prefab" ? kStageSide : (item.type == "vfx" && item.stage.empty() ? kVfxStageSide : 0); };
        std::stable_sort(order.begin(), order.end(), [&](std::size_t a, std::size_t b) { return viewSide(req.items[a]) < viewSide(req.items[b]); });
        if (!order.empty()) {
            GpuSession session(projectDir, id);
            for (std::size_t i : order) {
                const Item& item = req.items[i];
                if (item.type == "scene") rendered[i] = render_scene(session, item);
                else if (item.type == "prefab") rendered[i] = render_prefab(session, item);
                else rendered[i] = render_vfx(session, projectDir, id, item);
                shrink(rendered[i]);
            }
        }
    }
    for (std::size_t i = 0; i < rendered.size(); ++i) {
        for (const std::string& w : rendered[i].warnings) warnings.push_back(w);
        if (!rendered[i].ok) warnings.push_back(std::format("Item {} ('{}') could not be drawn and cannot be picked: {}", req.items[i].n, req.items[i].label, rendered[i].error));
    }
    if (std::none_of(rendered.begin(), rendered.end(), [](const Rendered& r) { return r.ok; }))
        fail("failed", "None of the " + std::to_string(rendered.size()) + " items could be drawn: " + rendered.front().error, "Nothing was written. Fix the first problem (the others are likely the same) and call review.sheet again.");

    const std::string title = req.label.empty() ? "Pick one: say its number" : req.label;
    Composed composed = compose(layout, req.items, rendered, title, id);

    // ---- the manifest ----
    Json items = Json::array();
    for (std::size_t i = 0; i < req.items.size(); ++i) {
        const Item& item = req.items[i];
        const Rendered& r = rendered[i];
        Json j = Json::object({{"n", item.n}, {"type", item.type}, {"label", item.label}, {"source", item.source}, {"candidate", item.candidate}, {"ok", r.ok}});
        if (!r.ok) j["error"] = r.error;
        j["info"] = r.info;
        j["numbers"] = r.numbers;
        j["thumb"] = std::format("thumbs/{:02d}.png", item.n);
        j["cell"] = composed.cells[i]["cell"];
        j["picture"] = composed.cells[i]["picture"];
        j["spec"] = item.spec;
        items.push_back(j);
    }
    const std::string dirRel = std::string(kReviewDir) + "/" + id;
    Json manifest = Json::object({{"label", req.label},
                                  {"columns", layout.columns},
                                  {"rows", layout.rows},
                                  {"thumbSize", layout.thumb},
                                  {"picture", Json::object({{"path", dirRel + "/sheet.png"}, {"width", composed.sheet.width}, {"height", composed.sheet.height}})},
                                  {"dropDir", req.dropDir},
                                  {"meta", req.meta},
                                  {"items", items},
                                  {"picked", nullptr},
                                  {"warnings", warnings}});
    ReviewOutcome committed = review_commit(projectDir, id, manifest, composed.sheet, composed.thumbs);
    if (!committed.ok) throw_outcome(committed);
    guard.keep = true;

    // Housekeeping after the sheet exists, so it can never stop a sheet from being made: old dropped files and abandoned sheet folders.
    Json housekeeping = Json::object();
    {
        ReviewOutcome cleaned = review_cleanup(projectDir, ReviewCleanupOptions{});
        if (!cleaned.ok) {
            warnings.push_back("The housekeeping of old review files did not run (" + cleaned.message + "); it runs again with the next sheet or review.cleanup.");
        } else {
            std::size_t files = 0;
            for (const Json& e : cleaned.value["droppedExpired"]) files += e["files"].size();
            if (files > 0 || !cleaned.value["orphansRemoved"].empty())
                housekeeping = Json::object({{"droppedFilesDeleted", files}, {"orphanSheetsRemoved", cleaned.value["orphansRemoved"]}});
            for (const Json& sk : cleaned.value["skipped"]) warnings.push_back("Housekeeping of " + sk.value("sheet", std::string()) + ": " + sk.value("reason", std::string()));
        }
    }

    // ---- the result ----
    Json list = Json::array();
    for (const Json& j : items) list.push_back(Json::object({{"n", j["n"]}, {"type", j["type"]}, {"label", j["label"]}, {"info", j["info"]}, {"ok", j["ok"]}, {"source", j["source"]}, {"candidate", j["candidate"]}}));
    Json result = Json::object({{"sheet", id},
                                {"dir", dirRel},
                                {"manifest", dirRel + "/manifest.json"},
                                {"picture", committed.value["picture"]},
                                {"columns", layout.columns},
                                {"rows", layout.rows},
                                {"thumbSize", layout.thumb},
                                {"count", int(req.items.size())},
                                {"items", list},
                                {"meta", req.meta},
                                {"warnings", warnings}});
    if (!housekeeping.empty()) result["housekeeping"] = housekeeping;
    result["$image"] = Json::object({{"path", utf8(project_file(projectDir, dirRel + "/sheet.png"))}, {"mimeType", "image/png"}});
    const bool anyCandidate = std::any_of(req.items.begin(), req.items.end(), [](const Item& i) { return i.candidate; });
    std::vector<std::string> steps;
    steps.push_back("Show the picture to the person and ask for ONE number from 1 to " + std::to_string(req.items.size()) + ". Do not choose for them.");
    steps.push_back("Then call review.pick {\"sheet\": \"" + id + "\", \"n\": <their number>} to record it" + (anyCandidate ? " (the files of the other candidates are moved to " + req.dropDir + "/" + id + "/, never deleted)." : "."));
    steps.push_back("review.list shows the sheets of this project, review.info the details of one.");
    result["nextSteps"] = steps;
    return result;
}

// ---- review.pick, review.list, review.info ------------------------------------------------------------------------------------------

Json pick_command(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "review.pick expects an object.", "Pass {\"sheet\": \"latest\", \"n\": 3}.");
    check_arg_keys("review.pick", a, "", {"sheet", "n", "drop", "note"});
    if (!a.contains("n")) arg_error("review.pick", "/n", "missing: the number the person chose.", "It is the number printed on the thumbnail. Ask the person; never pick for them.");
    long n = 0;
    if (!whole_number(a["n"], 1, 100000, n)) arg_error("review.pick", "/n", "expected the whole number printed on a thumbnail.", "Example: {\"sheet\": \"latest\", \"n\": 3}.");
    std::string sheet = "latest";
    if (a.contains("sheet") && !a["sheet"].is_null()) {
        if (!a["sheet"].is_string() && !a["sheet"].is_number_integer()) arg_error("review.pick", "/sheet", "expected a sheet id such as \"sheet-0003\", its number, or \"latest\".", "review.list shows the sheets.");
        sheet = a["sheet"].is_string() ? a["sheet"].get<std::string>() : std::to_string(a["sheet"].get<long long>());
    }
    ReviewPickOptions options;
    options.drop = tooling_detail::arg_bool(a, "drop", true);
    if (a.contains("note") && !a["note"].is_null()) {
        if (!a["note"].is_string() || a["note"].get<std::string>().size() > 500) arg_error("review.pick", "/note", "expected a short text (at most 500 characters).", "Why this one was chosen, in the person's words.");
        options.note = a["note"].get<std::string>();
    }
    ReviewOutcome o = review_pick(projectDir, sheet, n, options);
    if (!o.ok) throw_outcome(o);
    Json result = o.value;
    std::vector<std::string> steps;
    const std::string type = result.value("type", std::string());
    const std::string source = result.value("source", std::string());
    if (type == "level") steps.push_back("Generate this level for real: tilemap.generate with the `spec.level` arguments of this result (same seed, same level; an entity `sample` is looked up in the open scene, which is `spec.sampleScene` or the main scene when the spec has none), then scene.import_ascii on its rows.");
    else if (type == "image" || type == "vector") steps.push_back("Use '" + source + "'. If it should be a game asset, assets.import registers it; the other candidates are in the dropped folder if the person changes their mind.");
    else if (type == "scene") steps.push_back("Keep working on '" + source + "' (scene.load); the other scenes are in the dropped folder.");
    else if (type == "prefab") steps.push_back("Use the prefab '" + source + "' (scene.spawn {prefab}); the other prefabs are in the dropped folder.");
    else if (type == "vfx") steps.push_back("Play '" + source + "' (vfx.play); vfx.review judges it with numbers.");
    if (!result["dropped"].empty()) steps.push_back("To bring a dropped candidate back, move the file from its `to` path to its `from` path (both are listed in `dropped`).");
    result["nextSteps"] = steps;
    return result;
}

Json list_command(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "review.list expects an object.", "Pass {} or {\"limit\": 5}.");
    check_arg_keys("review.list", a, "", {"limit"});
    long limit = kReviewListDefault;
    if (a.contains("limit") && !a["limit"].is_null() && !whole_number(a["limit"], 1, kReviewListMax, limit))
        arg_error("review.list", "/limit", std::format("expected a whole number from 1 to {}.", kReviewListMax), "How many sheets to list, newest first.");
    ReviewOutcome o = review_list(projectDir, int(limit));
    if (!o.ok) throw_outcome(o);
    return o.value;
}

Json info_command(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "review.info expects an object.", "Pass {\"sheet\": \"latest\"}.");
    check_arg_keys("review.info", a, "", {"sheet"});
    std::string sheet = "latest";
    if (a.contains("sheet") && !a["sheet"].is_null()) {
        if (!a["sheet"].is_string() && !a["sheet"].is_number_integer()) arg_error("review.info", "/sheet", "expected a sheet id such as \"sheet-0003\", its number, or \"latest\".", "review.list shows the sheets.");
        sheet = a["sheet"].is_string() ? a["sheet"].get<std::string>() : std::to_string(a["sheet"].get<long long>());
    }
    ReviewOutcome o = review_load(projectDir, sheet);
    if (!o.ok) throw_outcome(o);
    Json result = o.value;
    const std::string dir = std::string(kReviewDir) + "/" + result.value("id", std::string());
    result["dir"] = dir;
    result["$image"] = Json::object({{"path", utf8(project_file(projectDir, dir + "/sheet.png"))}, {"mimeType", "image/png"}});
    return result;
}

Json cleanup_command(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "review.cleanup expects an object.", "Pass {} or {\"dryRun\": true}.");
    check_arg_keys("review.cleanup", a, "", {"droppedDays", "orphanMinutes", "dryRun"});
    ReviewCleanupOptions options;
    long days = kReviewDroppedDays, minutes = kReviewOrphanMinutes;
    if (a.contains("droppedDays") && !a["droppedDays"].is_null() && !whole_number(a["droppedDays"], 0, 3650, days))
        arg_error("review.cleanup", "/droppedDays", "expected a whole number of days from 0 to 3650.", "Dropped candidates are deleted this many days after the pick; 0 keeps them for ever.");
    if (a.contains("orphanMinutes") && !a["orphanMinutes"].is_null() && !whole_number(a["orphanMinutes"], 0, 525600, minutes))
        arg_error("review.cleanup", "/orphanMinutes", "expected a whole number of minutes from 0 to 525600.", "A sheet folder without a manifest is removed once nothing in it changed for this long; 0 leaves them.");
    options.droppedDays = int(days);
    options.orphanMinutes = int(minutes);
    options.dryRun = tooling_detail::arg_bool(a, "dryRun", false);
    ReviewOutcome o = review_cleanup(projectDir, options);
    if (!o.ok) throw_outcome(o);
    return o.value;
}

Json prop(const char* type, const std::string& text) { return Json::object({{"type", type}, {"description", text}}); }

}  // namespace

void register_review_commands(CommandRegistry& registry, const std::string& projectDir) {
    // ---- review.sheet ----
    {
        CommandInfo info;
        info.name = kCommand;
        info.category = "review";
        info.readOnly = false;
        info.summary = "Show N candidates as ONE picture with big numbers (images, scenes, prefabs, level seeds, vector art, effects) so a person can answer with one number.";
        info.description =
            "Make the candidates, call review.sheet, show the picture to the person, ask for ONE number, then review.pick. Do not choose for them and do not show candidates one by one. "
            "Each item is an object with exactly one of image (a PNG/JPG/BMP/TGA), scene, prefab, level (the arguments of tilemap.generate, with `seeds` next to it for one thumbnail per seed), vector (an .svg) or vfx (a .vfx.json), plus an optional label and candidate. "
            "Every thumbnail carries its number (1..N, in the item order), its label and one line of facts: an image its size, colors and how much is clear; a scene its entity count; a prefab its entities and size; a level its size, seed and tries; vector art its size, shapes and colors (counted from the file's text); an effect its peak particles and length. "
            "How each is drawn: images and vector art on the CPU as they are; a level on the CPU, one square per cell (letters on the squares when they are big enough); a scene is started and captured by the engine's renderer (`steps` frames in); a prefab is spawned on a plain stage and framed (2D from its visuals, 3D turned three quarters under a studio light); an effect is the MIDDLE picture of vfx.filmstrip (the label in its corner is its time), over a dark stage or your `stage` scene. "
            "Scenes, prefabs and effects need a graphics device like assets.preview_in_scene; without one the whole command fails with no_gpu before anything is written (images, vector art and levels need none). An item that cannot be drawn (a corrupt image, a level the solver could not make) is a red tile that review.pick refuses; if none can be drawn nothing is written; a wrong argument of a level fails the command with its JSON pointer. "
            "A level is generated with the project's engine (graphics off), at most 1024 cells a side, with `maxWork` " + std::to_string(kLevelMaxWork) + " unless you set it, so the same arguments and seed give the same thumbnail on every machine; tilemap.generate's `maxSeconds` is NOT fixed here (its default of 1800 CPU seconds is only a safety net far above what a thumbnail takes), so the work cap decides, never the speed of the machine. "
            "The level's `sample` takes the forms of tilemap.generate: ASCII rows as an array of strings (with `legend` next to it), an object {rows, legend?}, one string with line breaks, a project path of a .json rows file, or the id or name of an ENTITY WITH A TILEMAP. Only the entity form needs a scene to look the entity up in: it is the project's main scene (factoria.json mainScene), or the scene you name with `sampleScene` on the item; the thumbnails never change that scene. Without a main scene and without `sampleScene` an entity sample is an error with its JSON pointer. "
            "At most " + std::to_string(kReviewMaxItems) + " items (after `seeds` are expanded; 4 to 9 is what a person judges well) and a sheet of at most " + std::to_string(kMaxSide) + " px a side; the thumbnail size and the columns are chosen from the item count unless you give them. "
            "The sheet is stored under .factoria/review/<id>/ (sheet.png, manifest.json, thumbs/NN.png): the manifest records the items with their labels, facts and the exact arguments of each (a level's seed), when it was made, and later who picked what. The picture comes back as `$image` (a file in the project, not a temporary one). "
            "Mark `candidate: true` on the items whose FILES you made only for this choice (variants of an image, scene, prefab, vector art or effect): review.pick then MOVES the ones that were not chosen to .factoria/review/dropped/<id>/ (or `dropDir`), never deleting them. A file that is not marked is never touched. Levels are not files: picking one only records its seed. "
            "A candidate must be a file of the project of the kind its type needs (.scene.json, .prefab.json, .vfx.json, .svg, a picture), never factoria.json, assets.json, anything under .factoria/ or a version-control folder, the main scene, or a scene another item uses as its `stage`; no other item may show a candidate's file; paths are compared after normalizing (./, backslashes, upper case), and review.pick checks all of it again before it moves anything. "
            "`meta` is your own small object (e.g. {\"slot\":\"hero\"}, at most " + std::to_string(kReviewMetaMaxBytes) + " bytes as JSON), stored with the sheet and returned untouched by review.pick, review.info and review.list. "
            "After the sheet is made, files review.pick dropped more than " + std::to_string(kReviewDroppedDays) + " days ago and sheet folders abandoned (no manifest) for more than " + std::to_string(kReviewOrphanMinutes) + " minutes are cleaned up (review.cleanup says what; the sheets that were not answered and the chosen files are never touched). "
            "Result: {sheet, dir, manifest, picture: {path, width, height}, columns, rows, thumbSize, count, items: [{n, type, label, info, ok, source, candidate}], meta, warnings, housekeeping?, nextSteps, $image}. "
            "Example: review.sheet {\"label\":\"Which hero?\",\"items\":[{\"image\":\"assets/hero_a.png\",\"candidate\":true},{\"image\":\"assets/hero_b.png\",\"candidate\":true}]} or {\"items\":[{\"level\":{\"sample\":[\"#..#\",\"#..#\"],\"legend\":{\"#\":0,\".\":1},\"size\":[40,24]},\"seeds\":[1,2,3,4]}]}.";
        const Json itemSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"description", "One thing to show. Exactly one of image, scene, prefab, level, vector, vfx; label, candidate, steps, stage and seeds are the options."},
             {"properties",
              Json::object(
                  {{"image", prop("string", "Project path of a picture (PNG, JPG, BMP, TGA), drawn as it is.")},
                   {"scene", prop("string", "Project path of a scene (.scene.json): loaded, run for `steps` frames and captured. Needs a GPU.")},
                   {"prefab", prop("string", "Project path of a prefab (.prefab.json): spawned on a plain stage and framed. Needs a GPU.")},
                   {"level", Json::object({{"type", "object"}, {"description", "The arguments of tilemap.generate (`sample`, `size`, `n`...) of a level to look at; no `into` (nothing is written) and no `seed` together with `seeds`. `sample` is ASCII rows (an array of strings with a `legend` next to it, an object {rows, legend?}, or one string with line breaks), the project path of a .json rows file, or the id or name of an entity with a Tilemap (looked up in `sampleScene`, else the main scene). Sizes up to 1024 cells a side. `maxSeconds` is not fixed here (a safety net of 1800 CPU seconds); `maxWork` is (" + std::to_string(kLevelMaxWork) + " unless set)."}})},
                   {"vector", prop("string", "Project path of an .svg, rasterized as it is.")},
                   {"vfx", prop("string", "Project path of an effect (.vfx.json): the middle picture of vfx.filmstrip. Needs a GPU.")},
                   {"label", prop("string", "Text printed next to the number (at most 80 characters). Default: the file name, or \"level seed N\".")},
                   {"candidate", prop("boolean", "true: this item's file was made only for this choice, so review.pick moves it away when another item is picked. Default false (the sheet's `candidates`). Not for levels.")},
                   {"steps", Json::object({{"type", "integer"}, {"minimum", 0}, {"maximum", 600}, {"description", "Scene items: frames the scene runs before the picture. Default 2."}})},
                   {"stage", prop("string", "Effect items: project path of the scene the effect plays in (it must read against that scene's camera and backdrop). Default: a plain dark stage.")},
                   {"sampleScene", prop("string", "Level items whose `level.sample` is the id or name of an entity: the .scene.json that entity is in. Default: the project's main scene. Not used by the other sample forms.")},
                   {"seeds", Json::object({{"type", "array"}, {"minItems", 1}, {"maxItems", kReviewMaxItems}, {"items", Json::object({{"type", "integer"}, {"minimum", 0}, {"maximum", 4294967295.0}, {"description", "One seed."}})},
                                           {"description", "Level items: one thumbnail per seed, from the same `level` arguments, labelled \"seed N\". Not together with level.seed."}})}})}});
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"required", Json::array({"items"})},
             {"additionalProperties", false},
             {"properties",
              Json::object(
                  {{"items", Json::object({{"type", "array"}, {"minItems", 1}, {"maxItems", kReviewMaxItems}, {"items", itemSchema}, {"description", "What to show, in order: the first is number 1."}})},
                   {"label", prop("string", "The question or title printed at the top of the sheet, e.g. \"Which hero?\" (at most 120 characters).")},
                   {"columns", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", 12}, {"description", "Thumbnails per row. Default: nearly square."}})},
                   {"thumbSize", Json::object({{"type", "integer"}, {"minimum", 64}, {"maximum", 512}, {"description", "Pixels of the square each thumbnail is fitted into. Default: chosen from the number of items so the sheet is about 1800 px wide."}})},
                   {"candidates", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Treat every file item (not levels) as a candidate unless it says `candidate: false`: the files of the items that are not picked are moved away."}})},
                   {"dropDir", prop("string", "Project folder below .factoria/ that review.pick moves unpicked candidates into (a sub-folder per sheet). Not .factoria/tmp, not .factoria/review itself or another sheet's folder. Default .factoria/review/dropped.")},
                   {"meta", Json::object({{"type", "object"}, {"description", "Your own small object (e.g. {\"slot\":\"hero\"}, at most " + std::to_string(kReviewMetaMaxBytes) + " bytes as JSON), stored with the sheet and returned by review.pick, review.info and review.list. Default {}."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return sheet_command(projectDir, args); });
    }
    // ---- review.pick ----
    {
        CommandInfo info;
        info.name = "review.pick";
        info.category = "review";
        info.readOnly = false;
        info.summary = "Record which numbered thumbnail of a review sheet the person chose, and move the other candidates' files away (never deleting them).";
        info.description =
            "Call it with the number THE PERSON gave you for a sheet that review.sheet made; never pick for them (over MCP and the CLI nothing asks them, so the number must be theirs: show the sheet, ask, wait). "
            "The choice is written into the sheet's manifest (who, when, the note and the exact spec of the item: a level's seed and arguments) and is final: a sheet is picked once. "
            "With `drop` (default true) the files of every OTHER item marked `candidate` are MOVED to <dropDir>/<sheet id>/<NN>_<file name> (default .factoria/review/dropped/): nothing is deleted, the result and the manifest list each move (from, to) and moving the file back undoes it. "
            "What dropping means per item type: image, vector, scene, prefab and vfx items marked candidate: their file moves; items not marked candidate and level items (no file): only recorded. The picked item's file stays where it is. A candidate that shares its file with the picked item, or was already gone, is left alone and reported in `warnings`; assets.json is not edited (it warns when it still lists a moved file). "
            "Every file is checked again before the first one moves (the manifest is a file anyone can edit): it must be inside the project and of the kind its type needs, never factoria.json, assets.json, anything under .factoria/, a version-control folder, the main scene or a scene another item plays an effect in; the drop folder must be one review.sheet would accept; otherwise nothing is moved and the error says why. "
            "All or nothing: if a move fails (a file open in another program) the moves already made are put back and the manifest is not changed. The manifest is changed under the project's review lock, so the editor, the CLI and an agent may use sheets at once. "
            "A crash between the moves and the manifest write (a power cut) leaves the moved files in the drop folder with the sheet still unanswered: pick again (the files that are gone are reported, not an error), or move them back by hand from <dropDir>/<id>/. "
            "Errors: not_found (no such sheet), invalid_argument (a number not on the sheet, or the item failed to render), already_picked, exists (a leftover in the drop folder), busy (another process holds the lock). "
            "Result: {sheet, n, label, type, source, spec, drop, dropped: [{n, label, from, to, status}], who, at, meta (the object review.sheet was given), warnings, nextSteps}. Example: review.pick {\"sheet\":\"latest\",\"n\":3}.";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"required", Json::array({"n"})},
             {"additionalProperties", false},
             {"properties",
              Json::object(
                  {{"sheet", Json::object({{"type", Json::array({"string", "integer"})}, {"description", "The sheet: its id (\"sheet-0003\"), its number (3 or \"3\") or \"latest\" (default), the newest finished sheet."}})},
                   {"n", Json::object({{"type", "integer"}, {"minimum", 1}, {"description", "The number printed on the thumbnail the person chose. It must come from them."}})},
                   {"drop", Json::object({{"type", "boolean"}, {"default", true}, {"description", "Move the files of the other candidates to the sheet's drop folder. false: only record the choice and touch no file."}})},
                   {"note", prop("string", "Why it was chosen, in the person's words (at most 500 characters); kept in the manifest.")}})}});
        registry.add(info, [projectDir](const Json& args) { return pick_command(projectDir, args); });
    }
    // ---- review.cleanup ----
    {
        CommandInfo info;
        info.name = "review.cleanup";
        info.category = "review";
        info.readOnly = false;
        info.summary = "Delete the candidate files a review pick moved away long ago, and the folders of sheets that were never finished.";
        info.description =
            "review.sheet runs it by itself after each new sheet; call it to see what it would do (dryRun) or to use other ages. Two things only: "
            "(1) the files review.pick MOVED to a sheet's drop folder are deleted `droppedDays` days after the pick (the clock against the pick's time in the manifest); the manifest entry becomes status \"expired\" "
            "(\"gone\" when the file was already moved back or removed) and the empty folder goes. Nothing else is ever deleted there: only the files named `<NN>_<name>` that the pick put in <dropDir>/<sheet id>/. "
            "(2) a sheet folder with no manifest.json (the process died between starting the sheet and writing it; review.list shows these as `orphans`) is removed once nothing in it changed for `orphanMinutes` minutes. "
            "A sheet nobody has answered, the files of the picked item and every chosen file are never touched. At most " + std::to_string(kReviewCleanupMax) + " sheets are changed per call (`more` says there are others: call again). "
            "A file that is open in another program is kept and tried again next time. Runs under the project's review lock; busy when another process holds it (nothing changed). "
            "Result: {droppedExpired: [{sheet, files}], orphansRemoved: [ids], skipped: [{sheet, reason}], examined, more, dryRun, droppedDays, orphanMinutes}. Example: review.cleanup {\"dryRun\":true}.";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"properties",
              Json::object(
                  {{"droppedDays", Json::object({{"type", "integer"}, {"minimum", 0}, {"maximum", 3650}, {"default", kReviewDroppedDays}, {"description", "Delete a dropped candidate this many days after the pick. 0: keep them for ever."}})},
                   {"orphanMinutes", Json::object({{"type", "integer"}, {"minimum", 0}, {"maximum", 525600}, {"default", kReviewOrphanMinutes}, {"description", "Remove a sheet folder without a manifest once nothing in it changed for this many minutes. 0: leave them."}})},
                   {"dryRun", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Report what would be removed and remove nothing."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return cleanup_command(projectDir, args); });
    }
    // ---- review.list ----
    {
        CommandInfo info;
        info.name = "review.list";
        info.category = "review";
        info.readOnly = true;
        info.summary = "List the review sheets of the project, newest first, with what was picked.";
        info.description = "Reads .factoria/review/. Result: {total, sheets: [{id, label, createdAt, count, picked (the number, or null while unanswered), pickedLabel, picture, meta, dir}], unreadable?, orphans?}. "
                           "`orphans` are sheet folders with no manifest: a sheet being made right now, or one whose process died (review.cleanup removes the old ones). "
                           "Use it to find a sheet that is still waiting for an answer (picked null) or to see what was chosen before. Example: review.list {\"limit\":5}.";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"properties", Json::object({{"limit", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", kReviewListMax}, {"default", kReviewListDefault}, {"description", "The most sheets to list, newest first."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return list_command(projectDir, args); });
    }
    // ---- review.info ----
    {
        CommandInfo info;
        info.name = "review.info";
        info.category = "review";
        info.readOnly = true;
        info.summary = "The manifest of one review sheet (items, facts, the choice) and its picture.";
        info.description = "Result: the manifest of the sheet (format factoria.review/1: id, label, createdAt, columns, rows, thumbSize, picture, dropDir, items [{n, type, label, source, candidate, ok, info, numbers, thumb, cell, picture, spec}], picked ({n, label, at, atUnix, who, note, drop, dropped [{n, label, from, to, status: moved | expired | gone}], spec}), meta, warnings) plus `dir` and the picture as `$image`. "
                           "`picked` is null until review.pick answers it. Example: review.info {\"sheet\":\"sheet-0002\"}.";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"properties", Json::object({{"sheet", Json::object({{"type", Json::array({"string", "integer"})}, {"description", "The sheet: its id (\"sheet-0003\"), its number (3 or \"3\") or \"latest\" (default)."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return info_command(projectDir, args); });
    }
}

}  // namespace fa::assets_detail
