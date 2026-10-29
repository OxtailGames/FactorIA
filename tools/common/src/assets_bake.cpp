// assets.bake_sheet: an entity the ENGINE draws (a prefab, or an entity of a scene), played in a private world and baked into
// a sprite sheet. Shape2D with gradients and strokes, sprites, SpriteAnimator, Tint, tweens, particles and scripts all
// bake as they play, so an effect that costs many draw calls on a phone becomes one sprite.
//
// How it works. A second engine (headless, its own offscreen GPU target, a fixed step) loads a scene of two entities: a
// camera that clears to transparent and the entity, placed at the origin of the world. The camera looks at the origin, so
// the origin of the entity is the same pixel in every frame (the pivot that stays still), and the picture is a square canvas
// large enough for the whole animation; a frame is captured every 1/fps seconds of simulated time. The canvas is cropped
// to the union of what was drawn over all the frames (plus a margin), and the premultiplied pixels the GPU leaves are
// turned into straight alpha with the colour of the edge pixels bled outwards (no dark fringes when the sheet is filtered).
// A process has one graphics device: when this one already owns it (the editor, an MCP session), the same command runs in a
// child `factoria call` instead.
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "fa/platform/app.h"
#include "fa/runtime/engine.h"
#include "fa/tooling/asset_import.h"
#include "fa/tooling/self_update.h"
#include "headless_run.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kCommand = "assets.bake_sheet";
constexpr int kMaxFrames = 1024;         // frames of one sheet
constexpr int kMaxSheetSide = 16384;     // pixels
constexpr int kStartCanvas = 512;        // the square the first attempt draws into (pixels); doubled while the animation touches its edge
constexpr int kMaxCanvas = 4096;
constexpr double kMinScale = 0.01, kMaxScale = 32;
constexpr int kBleedAlpha = 48;          // pixels with less alpha than this take the colour of the solid pixels around them
const char* const kCameraId = "bake_camera";
const char* const kDefaultTargetId = "bake_target";

[[noreturn]] void bad(const std::string& pointer, const std::string& what, const std::string& hint) { arg_error(kCommand, pointer, what, hint); }

// ---- arguments ------------------------------------------------------------------------------------------------------

struct ClipSpec {
    std::string name;
    std::string call;         // a method of the entity's behaviour to call (empty = none)
    Json callArgs = Json::array();
    std::string event;        // a game event to send (empty = none)
    Json eventData;           // its data (null = none)
    int frames = 0;
    double fps = 0;
    bool loop = true;
    std::optional<double> warmup;  // seconds; overrides the command's
};

struct Spec {
    std::string path;                   // the PNG, project-relative
    std::string prefab, scene, entity;  // the source: prefab, or scene + entity id
    int frames = 12;
    double fps = 12;
    int columns = 0;
    int frameWidth = 0, frameHeight = 0;
    std::optional<double> scale;
    std::optional<std::array<double, 2>> pivot;
    std::vector<ClipSpec> clips;
    double warmup = 0;
    long long seed = 1;
    std::optional<Color> background;
    int padding = 1;
    int margin = 2;
    bool overwrite = false;
};

int int_arg(const Json& a, const char* key, int def, int lo, int hi, const std::string& hint) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi)
        bad(std::string("/") + key, std::format("expected a whole number from {} to {}.", lo, hi), hint);
    return int(it->get<long long>());
}

double number_arg(const Json& a, const std::string& pointerBase, const char* key, double def, double lo, double hi, const std::string& hint) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number() || !(it->get<double>() >= lo && it->get<double>() <= hi))
        bad(pointerBase + "/" + key, std::format("expected a number from {} to {}.", lo, hi), hint);
    return it->get<double>();
}

std::string project_json_path(const Json& a, const char* key, const std::string& pointer, const char* what) {
    auto it = a.find(key);
    if (it == a.end() || !it->is_string()) bad(pointer, std::string("expected the project path of ") + what + " as a string.", "Example: \"prefabs/burst.prefab.json\".");
    auto norm = fs::normalize_checked(it->get<std::string>());
    if (!norm.ok() || norm->empty())
        bad(pointer, "'" + it->get<std::string>() + "' is not a path inside the project.", "Use a project-relative path such as \"prefabs/burst.prefab.json\".");
    return *norm;
}

Spec parse_spec(const Json& a, double fixedHzHint) {
    (void)fixedHzHint;
    if (!a.is_object()) fail("invalid_argument", "assets.bake_sheet expects an object.", "See the description of the command for the fields.");
    check_arg_keys(kCommand, a, "",
                   {"path", "prefab", "scene", "entity", "frames", "fps", "columns", "frameWidth", "frameHeight", "scale", "pivot", "clips",
                    "warmup", "seed", "background", "padding", "margin", "overwrite", "ai", "author", "license"});
    Spec s;
    {
        auto norm = fs::normalize_checked(tooling_detail::arg_string(a, "path", true));
        if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
            fail("invalid_argument", "The sheet goes under assets/, and '" + tooling_detail::arg_string(a, "path", true) + "' is not there.",
                 "Use a path such as \"assets/fx/explosion.png\".");
        if (to_lower(fs::extension(*norm)) != ".png")
            fail("invalid_argument", std::string(kCommand) + " writes PNG files, and '" + *norm + "' does not end in .png.", "Use a path such as \"assets/fx/explosion.png\".");
        s.path = *norm;
    }
    const bool hasPrefab = a.contains("prefab"), hasScene = a.contains("scene"), hasEntity = a.contains("entity");
    if (hasPrefab && (hasScene || hasEntity))
        fail("invalid_argument", "Give either `prefab` or `scene` + `entity`, not both.", "A prefab is baked as it is; for an entity placed in a scene pass the scene file and the entity's id.");
    if (!hasPrefab && !(hasScene && hasEntity))
        fail("invalid_argument", hasScene ? "`scene` needs `entity`: the id of the entity to bake." : hasEntity ? "`entity` needs `scene`: the scene file that holds it."
                                                                                                          : "Say what to bake: `prefab`, or `scene` + `entity`.",
             "Example: {\"path\":\"assets/fx/burst.png\",\"prefab\":\"prefabs/burst.prefab.json\",\"frames\":16,\"fps\":24}");
    if (hasPrefab) {
        s.prefab = project_json_path(a, "prefab", "/prefab", "the prefab");
    } else {
        s.scene = project_json_path(a, "scene", "/scene", "the scene");
        if (!a["entity"].is_string() || a["entity"].get<std::string>().empty())
            bad("/entity", "expected the id of an entity of the scene.", "Use scene.list_entities or open the scene file to see the ids.");
        s.entity = a["entity"].get<std::string>();
    }

    s.frames = int_arg(a, "frames", 12, 1, kMaxFrames, "Frames per clip (or in all, without `clips`); 8 to 24 is typical.");
    s.fps = number_arg(a, "", "fps", 12, 1, 240, "Frames per second of simulated time; the fixed step of the project (60 Hz by default) is the highest that makes different frames.");
    s.columns = int_arg(a, "columns", 0, 0, kMaxFrames, "Leave it out (or 0) for a square-ish grid.");
    s.frameWidth = int_arg(a, "frameWidth", 0, 0, kMaxSheetSide, "Pixels. Leave out to fit the animation.");
    s.frameHeight = int_arg(a, "frameHeight", 0, 0, kMaxSheetSide, "Pixels. Leave out to fit the animation.");
    if (a.contains("scale") && !a["scale"].is_null())
        s.scale = number_arg(a, "", "scale", 1, kMinScale, kMaxScale, "Pixels per world unit: 1 draws the entity at the size it has in the world, 2 twice as big. Leave it out to fit frameWidth x frameHeight, or 1.");
    if (a.contains("pivot") && !a["pivot"].is_null()) {
        const Json& p = a["pivot"];
        if (!p.is_array() || p.size() != 2 || !p[0].is_number() || !p[1].is_number() || p[0].get<double>() < 0 || p[0].get<double>() > 1 || p[1].get<double>() < 0 || p[1].get<double>() > 1)
            bad("/pivot", "expected [x, y], two numbers from 0 to 1.", "The point of the frame, counted from its top-left corner, where the entity's origin lands: [0.5, 1] is the middle of the bottom edge (a character's feet). Leave it out to keep the origin where the animation puts it.");
        s.pivot = std::array<double, 2>{p[0].get<double>(), p[1].get<double>()};
    }
    s.warmup = number_arg(a, "", "warmup", 0, 0, 3600, "Seconds of simulated time to play before the first frame (a particle system that should start full).");
    s.seed = tooling_detail::arg_int(a, "seed", 1);
    if (a.contains("background") && !a["background"].is_null()) s.background = colour_arg(kCommand, a["background"], "/background");
    s.padding = int_arg(a, "padding", 1, 0, 64, "Transparent pixels around every cell (twice between two cells) so a filtered sprite does not bleed into its neighbour.");
    s.margin = int_arg(a, "margin", 2, 0, 256, "Pixels of empty space kept around the animation's outline.");
    s.overwrite = tooling_detail::arg_bool(a, "overwrite", false);

    if (a.contains("clips") && !a["clips"].is_null()) {
        const Json& list = a["clips"];
        if (!list.is_array() || list.empty())
            bad("/clips", "expected a non-empty array of clips.", "Example: [{\"name\":\"explode\",\"call\":\"explode\",\"frames\":24}, {\"name\":\"idle\",\"frames\":8}]");
        std::set<std::string> names;
        for (std::size_t i = 0; i < list.size(); ++i) {
            const Json& c = list[i];
            const std::string at = "/clips/" + std::to_string(i);
            if (!c.is_object()) bad(at, "expected an object {name, call | event, frames}.", "Example: {\"name\":\"explode\",\"call\":\"explode\",\"frames\":24}");
            check_arg_keys(kCommand, c, at, {"name", "call", "args", "event", "data", "frames", "fps", "loop", "warmup"});
            ClipSpec clip;
            if (!c.contains("name") || !c["name"].is_string() || c["name"].get<std::string>().empty())
                bad(at + "/name", "every clip needs a name.", "The name SpriteAnimator.clip plays it by: \"idle\", \"explode\"...");
            clip.name = c["name"].get<std::string>();
            if (!names.insert(clip.name).second) bad(at + "/name", "two clips are called '" + clip.name + "'.", "Clip names are unique in a sheet.");
            if (c.contains("call") && c.contains("event"))
                bad(at, "give `call` or `event`, not both.", "`call` runs a method of the entity's behaviour; `event` sends a game event the scripts listen to with world.on.");
            if (c.contains("call")) {
                if (!c["call"].is_string() || c["call"].get<std::string>().empty())
                    bad(at + "/call", "expected the name of a method of the entity's behaviour.", "Example: \"call\": \"explode\" runs this.explode() of the entity's Script.");
                clip.call = c["call"].get<std::string>();
            }
            if (c.contains("args")) {
                if (!c["args"].is_array() || clip.call.empty())
                    bad(at + "/args", "expected an array of arguments, and only next to `call`.", "Example: {\"call\":\"hit\",\"args\":[3]} runs this.hit(3).");
                clip.callArgs = c["args"];
            }
            if (c.contains("event")) {
                if (!c["event"].is_string() || c["event"].get<std::string>().empty())
                    bad(at + "/event", "expected the name of a game event.", "Example: \"event\": \"boss.die\" is what world.on(\"boss.die\", ...) hears.");
                clip.event = c["event"].get<std::string>();
            }
            if (c.contains("data")) {
                if (clip.event.empty()) bad(at + "/data", "`data` goes with `event`.", "Example: {\"event\":\"boss.die\",\"data\":{\"fast\":true}}");
                clip.eventData = c["data"];
            }
            clip.frames = int_arg(c, "frames", s.frames, 1, kMaxFrames, "Frames of this clip.");
            clip.fps = number_arg(c, at, "fps", s.fps, 1, 240, "Frames per second of this clip.");
            if (c.contains("loop")) {
                if (!c["loop"].is_boolean()) bad(at + "/loop", "expected true or false.", "Whether SpriteAnimator repeats the clip; a one-shot explosion is false.");
                clip.loop = c["loop"].get<bool>();
            }
            if (c.contains("warmup")) clip.warmup = number_arg(c, at, "warmup", 0, 0, 3600, "Seconds played before this clip's first frame.");
            s.clips.push_back(std::move(clip));
        }
    }
    int total = 0;
    if (s.clips.empty()) total = s.frames;
    for (const ClipSpec& c : s.clips) total += c.frames;
    if (total > kMaxFrames)
        fail("invalid_argument", std::format("The sheet would have {} frames; the most is {}.", total, kMaxFrames), "Bake fewer frames, or split the clips over two sheets.");
    return s;
}

// ---- the entity -------------------------------------------------------------------------------------------------------

bool find_entity(const Json& list, const std::string& id, const Json*& found, std::vector<std::string>& ids) {
    if (!list.is_array()) return false;
    for (const Json& e : list) {
        if (!e.is_object()) continue;
        if (e.contains("id") && e["id"].is_string()) {
            ids.push_back(e["id"].get<std::string>());
            if (!found && e["id"].get<std::string>() == id) found = &e;
        }
        if (e.contains("children")) find_entity(e["children"], id, found, ids);
    }
    return found != nullptr;
}

// Puts the entity at the origin of the world (keeping its depth z): a baked frame is drawn around the entity's own origin.
void place_at_origin(Json& entity, double z) {
    if (!entity.contains("components") || !entity["components"].is_object()) entity["components"] = Json::object();
    Json& comps = entity["components"];
    if (!comps.contains("Transform") || !comps["Transform"].is_object()) comps["Transform"] = Json::object();
    comps["Transform"]["position"] = Json::array({0, 0, z});
}

double position_z(const Json& entity) {
    if (!entity.contains("components") || !entity["components"].is_object()) return 0;
    const Json& comps = entity["components"];
    if (!comps.contains("Transform") || !comps["Transform"].is_object() || !comps["Transform"].contains("position")) return 0;
    const Json& p = comps["Transform"]["position"];
    return p.is_array() && p.size() >= 3 && p[2].is_number() ? p[2].get<double>() : 0;
}

struct Source {
    std::string file;      // the prefab or the scene file (project-relative): the input of the recipe, the name in messages
    std::string targetId;  // the id of the entity in the bake scene
    Json entity;           // its JSON in the bake scene
};

Source load_source(const std::string& projectDir, const Spec& spec) {
    Source src;
    src.file = spec.prefab.empty() ? spec.scene : spec.prefab;
    const stdfs::path file = project_file(projectDir, src.file);
    std::error_code ec;
    if (!stdfs::is_regular_file(file, ec))
        fail("not_found", "'" + src.file + "' does not exist.", spec.prefab.empty() ? "Use scene.list_entities or check the scene's path." : "Check the path of the prefab; prefabs end in .prefab.json and live in the project folder.");
    auto text = tooling_detail::read_file(file);
    auto doc = text ? parse_json(*text, src.file) : Result<Json>(Error{"cannot read " + src.file, ""});
    if (!doc.ok()) fail("invalid_argument", "'" + src.file + "' is not valid JSON: " + doc.error().message, doc.error().hint);
    if (!spec.prefab.empty()) {
        if (!doc->is_object() || !doc->contains("entity") || !(*doc)["entity"].is_object())
            fail("invalid_argument", "'" + src.file + "' is not a prefab: it has no \"entity\" object.", "A prefab file looks like {\"format\": \"factoria.prefab/1\", \"entity\": {...}}.");
        const Json& e = (*doc)["entity"];
        src.targetId = e.contains("id") && e["id"].is_string() && !e["id"].get<std::string>().empty() ? e["id"].get<std::string>() : kDefaultTargetId;
        src.entity = Json::object({{"prefab", src.file}, {"id", src.targetId}});
        place_at_origin(src.entity, position_z(e));
    } else {
        const Json* found = nullptr;
        std::vector<std::string> ids;
        if (!doc->is_object() || !doc->contains("entities") || !find_entity((*doc)["entities"], spec.entity, found, ids))
            fail("not_found", "The scene '" + src.file + "' has no entity '" + spec.entity + "'.",
                 ids.empty() ? "The scene lists no entities with an id." : did_you_mean(spec.entity, ids) + " Entities of the scene: " + join(std::vector<std::string>(ids.begin(), ids.begin() + std::min<std::size_t>(ids.size(), 12)), ", ") + ".");
        src.targetId = spec.entity;
        src.entity = *found;
        place_at_origin(src.entity, position_z(*found));
    }
    return src;
}

// The project files the entity depends on (scripts, textures, nested prefabs): the inputs of the recipe, so a changed script
// makes the sheet stale.
void collect_inputs(const std::string& projectDir, const Json& node, const std::string& parentKey, std::set<std::string>& out, int depth = 0) {
    if (depth > 12) return;
    auto add_file = [&](const std::string& rel) {
        auto norm = fs::normalize_checked(rel);
        if (!norm.ok() || norm->empty()) return;
        std::error_code ec;
        try {
            if (stdfs::is_regular_file(project_file(projectDir, *norm), ec)) out.insert(*norm);
        } catch (const CommandError&) {
        }
    };
    if (node.is_object()) {
        for (auto it = node.begin(); it != node.end(); ++it) {
            if (it->is_string()) {
                const std::string& key = it.key();
                if (key == "texture" || key == "prefab" || (key == "path" && parentKey == "Script")) add_file(it->get<std::string>());
                if (key == "prefab") {
                    auto loaded = load_json_file((stdfs::path(projectDir) / it->get<std::string>()).generic_string());
                    if (loaded.ok()) collect_inputs(projectDir, *loaded, "", out, depth + 1);
                }
            } else {
                collect_inputs(projectDir, *it, it.key(), out, depth + 1);
            }
        }
    } else if (node.is_array()) {
        for (const Json& c : node) collect_inputs(projectDir, c, parentKey, out, depth + 1);
    }
}

bool any_ai(const Json& node, const std::string& projectDir, const std::set<std::string>& files) {
    for (const std::string& rel : files) {
        const Json e = assets::entry(rel);
        if (e.is_object() && e.contains("provenance") && e["provenance"].is_object() && e["provenance"].value("ai", false)) return true;
    }
    (void)node;
    (void)projectDir;
    return false;
}

Json camera_scene(const Json* entity, double orthoSize) {
    Json camera = Json::object(
        {{"id", kCameraId},
         {"components", Json::object({{"Transform", Json::object({{"position", Json::array({0, 0, 0})}})},
                                      {"Camera", Json::object({{"orthoSize", orthoSize}, {"clearColor", Json::array({0, 0, 0, 0})}})}})}});
    Json entities = Json::array({camera});
    if (entity) entities.push_back(*entity);
    return Json::object({{"format", "factoria.scene/1"}, {"entities", entities}});
}

// ---- one run of the animation ---------------------------------------------------------------------------------------------

struct Crop {            // the pixels a frame drew (premultiplied, as the GPU left them) and where they sit on the canvas
    int x0 = 0, y0 = 0, w = 0, h = 0;
    std::vector<std::uint8_t> rgba;
    bool empty() const { return w == 0; }
};

struct ClipFrames {
    std::vector<Crop> frames;
};

struct Pass {
    int canvas = 0;
    double scale = 1;
    std::vector<ClipFrames> clips;
    int x0 = 0, y0 = 0, x1 = 0, y1 = 0;  // the union of what was drawn, with the origin (canvas pixels; x1, y1 exclusive)
    bool any = false;
    bool touchesEdge = false;
};

std::string clip_label(const Spec& spec, std::size_t i) { return spec.clips.empty() ? std::string("the animation") : "clip '" + spec.clips[i].name + "'"; }

[[noreturn]] void script_failure(const std::string& what, const std::string& file, const std::string& detail, const std::string& hint) {
    fail("script_error", "Baking '" + file + "' failed: " + what + (detail.empty() ? "" : ": " + detail), hint);
}

std::string first_script_error(Engine& engine) {
    const auto& errors = engine.scripts().errors();
    return errors.empty() ? std::string() : errors.front().to_string();
}

// The JS the engine evaluates to start a clip.
std::string trigger_code(const Source& src, const ClipSpec& clip) {
    if (!clip.call.empty()) {
        return "(() => {"
               "const e = world.find(" + Json(src.targetId).dump() + "); if (!e) return {error: 'entity'};"
               "const b = e.behaviour; if (!b) return {error: 'behaviour'};"
               "const name = " + Json(clip.call).dump() + "; const m = b[name];"
               "if (typeof m !== 'function') { const names = []; let o = b;"
               " while (o && o !== Object.prototype) { for (const k of Object.getOwnPropertyNames(o)) { if (k === 'constructor') continue;"
               "  let v; try { v = b[k]; } catch (err) { continue; } if (typeof v === 'function' && !names.includes(k)) names.push(k); } o = Object.getPrototypeOf(o); }"
               " return {error: 'method', methods: names}; }"
               "m.apply(b, " + clip.callArgs.dump() + "); return {ok: true}; })()";
    }
    return "(world.emit(" + Json(clip.event).dump() + ", " + (clip.eventData.is_null() ? std::string("{}") : clip.eventData.dump()) + "), {ok: true})";
}

void tight_crop(const Image& img, Crop& out) {
    int x0 = img.width, y0 = img.height, x1 = 0, y1 = 0;
    for (int y = 0; y < img.height; ++y) {
        const std::uint8_t* row = &img.rgba[std::size_t(y) * img.width * 4];
        for (int x = 0; x < img.width; ++x) {
            const std::uint8_t* p = row + x * 4;
            if (p[3] == 0 && p[0] == 0 && p[1] == 0 && p[2] == 0) continue;
            x0 = std::min(x0, x);
            x1 = std::max(x1, x + 1);
            y0 = std::min(y0, y);
            y1 = std::max(y1, y + 1);
        }
    }
    if (x1 <= x0 || y1 <= y0) return;
    out.x0 = x0;
    out.y0 = y0;
    out.w = x1 - x0;
    out.h = y1 - y0;
    out.rgba.resize(std::size_t(out.w) * out.h * 4);
    for (int y = 0; y < out.h; ++y)
        std::copy_n(&img.rgba[(std::size_t(y0 + y) * img.width + x0) * 4], std::size_t(out.w) * 4, &out.rgba[std::size_t(y) * out.w * 4]);
}

struct TempScene {
    stdfs::path file;
    ~TempScene() {
        std::error_code ec;
        if (!file.empty()) stdfs::remove(file, ec);
    }
};

Pass run_pass(const std::string& projectDir, const Spec& spec, const Source& src, double scale, int canvas) {
    Pass pass;
    pass.canvas = canvas;
    pass.scale = scale;

    const double orthoSize = canvas / (2.0 * scale);
    TempScene temp;
    const std::string sceneRel = ".factoria/tmp/bake_sheet.scene.json";
    temp.file = project_file(projectDir, sceneRel);
    {
        std::string err;
        if (!tooling_detail::write_file(temp.file, camera_scene(nullptr, orthoSize).dump(2), &err)) fail("failed", "Cannot write the scene the bake starts from: " + err);
    }
    EngineConfig cfg = tooling_detail::headless_engine_config(projectDir, sceneRel, true, RenderMode::OnDemand);
    cfg.width = canvas;
    cfg.height = canvas;
    cfg.seed = std::uint64_t(spec.seed);
    Engine engine;
    std::string err;
    if (!engine.init(cfg, nullptr, &err)) fail("failed", "Cannot start the engine that draws the animation: " + err);
    struct Shutdown {
        Engine& e;
        ~Shutdown() { e.shutdown(); }
    } shutdown{engine};
    const double fixedHz = 1.0 / engine.fixed_dt();

    const Json sceneJson = camera_scene(&src.entity, orthoSize);
    const std::size_t clipCount = std::max<std::size_t>(1, spec.clips.size());
    bool first = true;
    for (std::size_t ci = 0; ci < clipCount; ++ci) {
        ClipSpec fallback;
        fallback.frames = spec.frames;
        fallback.fps = spec.fps;
        const ClipSpec& clip = spec.clips.empty() ? fallback : spec.clips[ci];
        if (clip.fps > fixedHz + 1e-9)
            fail("invalid_argument", std::format("{} asks for {} frames per second, and the simulation steps {} times per second: some frames would repeat.", clip_label(spec, ci), clip.fps, fixedHz),
                 "Use a fps of at most " + std::to_string(int(fixedHz)) + " (fixedHz in factoria.json is the simulation rate).");

        // A fresh world for each clip, with the same seed: a clip does not depend on the ones before it.
        std::string loadError;
        if (!engine.load_scene_json(sceneJson, src.file, &loadError)) fail("invalid_argument", "Cannot load '" + src.file + "' for baking: " + loadError, "Open the file and fix what the message points at; scene.import_ascii / project.validate help.");
        engine.world().rng().reseed(std::uint64_t(spec.seed));
        engine.scripts().clear_errors();
        engine.step(1);  // the scripts of the entity start
        const double warmup = clip.warmup ? *clip.warmup : spec.warmup;
        if (const long n = std::lround(warmup * fixedHz); n > 0) engine.step(int(n));
        if (std::string e = first_script_error(engine); !e.empty())
            script_failure("a script failed while the entity started" + std::string(spec.clips.empty() ? "" : " (" + clip_label(spec, ci) + ")"), src.file, e,
                           "Fix the script (script.errors lists the errors of a running game), then bake again.");

        if (!clip.call.empty() || !clip.event.empty()) {
            auto r = engine.scripts().eval(trigger_code(src, clip));
            if (!r.ok())
                script_failure(std::format("{} could not be started with {}", clip_label(spec, ci), clip.call.empty() ? "the event '" + clip.event + "'" : "the call '" + clip.call + "'"), src.file, r.error().message,
                               "The method is called on the behaviour of the entity '" + src.targetId + "'; fix the script and bake again.");
            const std::string what = r->value("error", std::string());
            if (what == "entity" || what == "behaviour")
                script_failure(std::format("{} calls '{}', and the entity '{}' {}", clip_label(spec, ci), clip.call, src.targetId, what == "entity" ? "is not in the baked world" : "has no Script"), src.file, "",
                               "`call` runs a method of the entity's behaviour: add a Script component to the entity, or use `event` to send a game event instead.");
            if (what == "method") {
                std::vector<std::string> methods;
                for (const Json& m : (*r)["methods"]) methods.push_back(m.get<std::string>());
                script_failure(std::format("{} calls '{}', which the behaviour of '{}' does not have", clip_label(spec, ci), clip.call, src.targetId), src.file, "",
                               (methods.empty() ? std::string("The behaviour has no methods.") : did_you_mean(clip.call, methods) + " Its methods: " + join(methods, ", ") + "."));
            }
            if (std::string e = first_script_error(engine); !e.empty())
                script_failure(std::format("{} raised an error when it started", clip_label(spec, ci)), src.file, e, "Fix the script (script.errors lists the errors of a running game), then bake again.");
        }

        ClipFrames frames;
        long stepped = 0;
        for (int f = 0; f < clip.frames; ++f) {
            const long target = std::lround(f * fixedHz / clip.fps);
            if (target > stepped) engine.step(int(target - stepped));
            stepped = target;
            if (std::string e = first_script_error(engine); !e.empty())
                script_failure(std::format("a script failed at frame {} of {}", f, clip_label(spec, ci)), src.file, e, "Fix the script (script.errors lists the errors of a running game), then bake again.");
            Image img;
            if (!engine.capture_scaled(img, 1.0, &err)) {
                if (first && err.find("No renderer") != std::string::npos)
                    fail("no_gpu", "Baking draws with the GPU, and this computer has no graphics device the engine can use. " + err,
                         "Run it on a machine with a GPU (Metal, Direct3D 11, OpenGL); a Linux CI needs Mesa's EGL (llvmpipe).");
                fail("failed", "Cannot capture frame " + std::to_string(f) + " of " + clip_label(spec, ci) + ": " + err);
            }
            first = false;
            if (img.width != canvas || img.height != canvas)
                fail("failed", std::format("The engine drew {}x{} pixels where {}x{} were asked.", img.width, img.height, canvas, canvas));
            Crop crop;
            tight_crop(img, crop);
            if (!crop.empty()) {
                if (!pass.any) {
                    pass.x0 = crop.x0;
                    pass.y0 = crop.y0;
                    pass.x1 = crop.x0 + crop.w;
                    pass.y1 = crop.y0 + crop.h;
                    pass.any = true;
                }
                pass.x0 = std::min(pass.x0, crop.x0);
                pass.y0 = std::min(pass.y0, crop.y0);
                pass.x1 = std::max(pass.x1, crop.x0 + crop.w);
                pass.y1 = std::max(pass.y1, crop.y0 + crop.h);
            }
            frames.frames.push_back(std::move(crop));
        }
        pass.clips.push_back(std::move(frames));
    }
    if (pass.any) {
        const int o = canvas / 2;  // the origin of the entity: the pixel corner the camera looks at
        pass.x0 = std::min(pass.x0, o);
        pass.y0 = std::min(pass.y0, o);
        pass.x1 = std::max(pass.x1, o);
        pass.y1 = std::max(pass.y1, o);
        pass.touchesEdge = pass.x0 <= 0 || pass.y0 <= 0 || pass.x1 >= canvas || pass.y1 >= canvas;
    }
    return pass;
}

// ---- the layout of a cell -----------------------------------------------------------------------------------------------------

struct Axis {
    int size = 0;       // pixels of the cell along the axis
    int origin = 0;     // pixels from the cell's start to the pivot
    std::string error;  // why the animation does not fit
};

// `before` and `after`: pixels the animation needs before and after the pivot (the margin included).
Axis fit_axis(int before, int after, int given, std::optional<double> pivot, const char* sizeArg, const char* dimension, const char* startSide, const char* endSide, double scale) {
    Axis a;
    auto too_small = [&](int needed) {
        a.error = std::format("The animation reaches {} px {} the pivot and {} px {} it (the margin included) at scale {}, so the frame needs a {} of {} px{}, and {} is {}.",
                              before, startSide, after, endSide, scale, dimension, needed, pivot ? " at that pivot" : "", sizeArg, given);
    };
    if (given > 0) {
        if (pivot) {
            a.origin = int(std::lround(*pivot * given));
            if (a.origin < before || given - a.origin < after) {
                too_small(*pivot > 0 && *pivot < 1 ? int(std::ceil(std::max(before / *pivot, after / (1 - *pivot)))) : before + after);
                return a;
            }
        } else {
            if (before + after > given) {
                too_small(before + after);
                return a;
            }
            a.origin = before + (given - before - after) / 2;
        }
        a.size = given;
        return a;
    }
    if (pivot) {
        const double p = *pivot;
        if ((p <= 0 && before > 0) || (p >= 1 && after > 0)) {
            a.error = std::format("The pivot is at the very {} of the frame, but the animation reaches {} px past it.", p <= 0 ? "start" : "end", p <= 0 ? before : after);
            return a;
        }
        int size = p <= 0 ? after : p >= 1 ? before : int(std::ceil(std::max(before / p, after / (1 - p))));
        size = std::max(size, 1);
        for (int guard = 0; guard < 4096; ++guard, ++size) {
            a.origin = int(std::lround(p * size));
            if (a.origin >= before && size - a.origin >= after) break;
        }
        a.size = size;
        return a;
    }
    a.size = std::max(before + after, 1);
    a.origin = before;
    return a;
}

struct Layout {
    int w = 0, h = 0, ox = 0, oy = 0;
    std::string error;
};

Layout compute_layout(const Pass& pass, const Spec& spec) {
    const int o = pass.canvas / 2;
    Layout l;
    const int m = spec.margin;
    const Axis ax = fit_axis(o - pass.x0 + m, pass.x1 - o + m, spec.frameWidth, spec.pivot ? std::optional<double>((*spec.pivot)[0]) : std::nullopt, "frameWidth", "width", "left of", "right of", pass.scale);
    const Axis ay = fit_axis(o - pass.y0 + m, pass.y1 - o + m, spec.frameHeight, spec.pivot ? std::optional<double>((*spec.pivot)[1]) : std::nullopt, "frameHeight", "height", "above", "below", pass.scale);
    if (!ax.error.empty()) l.error = ax.error;
    else if (!ay.error.empty()) l.error = ay.error;
    l.w = ax.size;
    l.h = ay.size;
    l.ox = ax.origin;
    l.oy = ay.origin;
    return l;
}

// The scale at which an animation that measured `pass` (at pass.scale) should fit a cell of frameWidth x frameHeight.
double fit_scale(const Pass& pass, const Spec& spec) {
    const int o = pass.canvas / 2;
    const double m = spec.margin;
    double best = kMaxScale;
    auto consider = [&](double available, double content) {
        if (content > 0) best = std::min(best, available / content * pass.scale);
    };
    const double l = o - pass.x0, r = pass.x1 - o, t = o - pass.y0, b = pass.y1 - o;
    if (spec.pivot) {
        consider(spec.frameWidth * (*spec.pivot)[0] - m, l);
        consider(spec.frameWidth * (1 - (*spec.pivot)[0]) - m, r);
        consider(spec.frameHeight * (*spec.pivot)[1] - m, t);
        consider(spec.frameHeight * (1 - (*spec.pivot)[1]) - m, b);
    } else {
        consider(spec.frameWidth - 2 * m, l + r);
        consider(spec.frameHeight - 2 * m, t + b);
    }
    return std::clamp(best, kMinScale, kMaxScale);
}

// ---- pixels ---------------------------------------------------------------------------------------------------------------------------

// Premultiplied RGBA (what the GPU leaves on a transparent clear) to straight alpha. Additive blending adds light to the colour
// and leaves the alpha, so a pixel brighter than its alpha takes the brightest channel as its alpha (a glow stays visible).
void unpremultiply(const std::uint8_t* in, std::uint8_t* out) {
    const int r = in[0], g = in[1], b = in[2], a0 = in[3];
    const int a = std::max({a0, r, g, b});
    if (a == 0) {
        out[0] = out[1] = out[2] = out[3] = 0;
        return;
    }
    out[0] = std::uint8_t(std::min(255, (r * 255 + a / 2) / a));
    out[1] = std::uint8_t(std::min(255, (g * 255 + a / 2) / a));
    out[2] = std::uint8_t(std::min(255, (b * 255 + a / 2) / a));
    out[3] = std::uint8_t(a);
}

// A pixel with little alpha cannot hold its colour in 8 premultiplied bits, so it comes out dark and, filtered with its solid
// neighbours, draws a dark halo. Those pixels (and the empty ones next to them) take the average colour of the solid pixels
// within two pixels instead; their alpha is kept.
void bleed_colour(Image& img) {
    const Image src = img;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
            if (p[3] >= kBleedAlpha) continue;
            long sumR = 0, sumG = 0, sumB = 0, sumW = 0;
            for (int dy = -2; dy <= 2; ++dy)
                for (int dx = -2; dx <= 2; ++dx) {
                    const int nx = x + dx, ny = y + dy;
                    if (nx < 0 || ny < 0 || nx >= img.width || ny >= img.height) continue;
                    const std::uint8_t* q = &src.rgba[(std::size_t(ny) * img.width + nx) * 4];
                    if (q[3] < kBleedAlpha) continue;
                    sumR += long(q[0]) * q[3];
                    sumG += long(q[1]) * q[3];
                    sumB += long(q[2]) * q[3];
                    sumW += q[3];
                }
            if (sumW == 0) continue;
            p[0] = std::uint8_t((sumR + sumW / 2) / sumW);
            p[1] = std::uint8_t((sumG + sumW / 2) / sumW);
            p[2] = std::uint8_t((sumB + sumW / 2) / sumW);
        }
}

void put_background(Image& img, const Color& bg) {
    const double br = bg.r * 255.0, bgc = bg.g * 255.0, bb = bg.b * 255.0, ba = bg.a;
    for (std::size_t i = 0; i < img.rgba.size(); i += 4) {
        const double sa = img.rgba[i + 3] / 255.0, oa = sa + ba * (1.0 - sa);
        auto mixc = [&](double s, double b) { return oa <= 0 ? 0.0 : (s * sa + b * ba * (1.0 - sa)) / oa; };
        img.rgba[i] = std::uint8_t(std::clamp(std::lround(mixc(img.rgba[i], br)), 0L, 255L));
        img.rgba[i + 1] = std::uint8_t(std::clamp(std::lround(mixc(img.rgba[i + 1], bgc)), 0L, 255L));
        img.rgba[i + 2] = std::uint8_t(std::clamp(std::lround(mixc(img.rgba[i + 2], bb)), 0L, 255L));
        img.rgba[i + 3] = std::uint8_t(std::clamp(std::lround(oa * 255.0), 0L, 255L));
    }
}

// The straight-alpha picture of one frame in a w x h cell whose pivot pixel is (ox, oy).
Image render_cell(const Crop& crop, const Layout& l, int canvas, const std::optional<Color>& background) {
    Image cell;
    cell.width = l.w;
    cell.height = l.h;
    cell.rgba.assign(std::size_t(l.w) * l.h * 4, 0);
    const int o = canvas / 2;
    for (int y = 0; y < crop.h; ++y) {
        const int dy = l.oy + (crop.y0 + y - o);
        if (dy < 0 || dy >= l.h) continue;
        for (int x = 0; x < crop.w; ++x) {
            const int dx = l.ox + (crop.x0 + x - o);
            if (dx < 0 || dx >= l.w) continue;
            unpremultiply(&crop.rgba[(std::size_t(y) * crop.w + x) * 4], &cell.rgba[(std::size_t(dy) * l.w + dx) * 4]);
        }
    }
    bleed_colour(cell);
    if (background) put_background(cell, *background);
    return cell;
}

double round6(double v) { return std::round(v * 1e6) / 1e6; }

// ---- the child process ----------------------------------------------------------------------------------------------------

// A process has one graphics device and this one already has it: the same command in a `factoria call` child, which has its own.
Json bake_in_child(const std::string& projectDir, const Json& args) {
    stdfs::path exe = executable_path();
    if (!exe.empty() && exe.stem() != "factoria") {  // the editor or a game: the command line tool sits next to it
        stdfs::path sibling = exe.parent_path() / ("factoria" + exe.extension().string());
        std::error_code ec;
        exe = stdfs::exists(sibling, ec) ? sibling : stdfs::path();
    }
    if (exe.empty())
        fail("gpu_busy", "This process already uses the graphics card (the editor, a window or a session with graphics), and baking needs a second device; the factoria executable could not be located to run it in a child process.",
             "Run it from a terminal: factoria call assets.bake_sheet '{...}'.");
    ProcessOptions po;
    po.argv = {exe.string(), "call", "--project", projectDir, "--no-graphics", "--json", kCommand, args.dump()};
    po.workingDir = projectDir;
    po.timeoutSeconds = 900;
    auto run = run_process(po);
    if (!run.ok()) fail("failed", "Cannot start " + exe.string() + " to bake in a child process: " + run.error().message, run.error().hint);
    auto out = parse_json(run->stdoutText, "<assets.bake_sheet in a child process>");
    if (!out.ok()) {
        const std::string tail = run->stderrText.size() > 600 ? run->stderrText.substr(run->stderrText.size() - 600) : run->stderrText;
        fail("failed", std::format("The child process that bakes (exit code {}) printed no result. Its error output ended with: {}", run->exitCode, tail),
             "Run the command from a terminal to see it: factoria call assets.bake_sheet '{...}'.");
    }
    if (out->is_object() && out->contains("ok") && (*out)["ok"] == false) {
        const Json err = out->value("error", Json::object());
        throw CommandError(err.value("code", std::string("failed")), err.value("message", std::string("The child process failed.")), err.value("hint", std::string()));
    }
    return *out;
}

// ---- the command ------------------------------------------------------------------------------------------------------------------------

Json bake_sheet(const std::string& projectDir, const Json& a) {
    const Spec spec = parse_spec(a, 60);
    const stdfs::path file = project_file(projectDir, spec.path);
    std::error_code ec;
    if (!spec.overwrite && stdfs::exists(file, ec)) fail("exists", "'" + spec.path + "' already exists.", "Pass overwrite: true to replace it, or choose another `path`.");
    ProjectRootGuard root(projectDir);
    require_usable_manifest(projectDir);
    const Source src = load_source(projectDir, spec);
    if (gfx_device_active()) return bake_in_child(projectDir, a);

    // ---- draw the animation, large enough that nothing touches the edge of the canvas
    int canvas = kStartCanvas;
    double scale = spec.scale.value_or(1.0);
    std::vector<std::string> warnings;
    auto settle = [&](double s) {
        for (;;) {
            Pass pass = run_pass(projectDir, spec, src, s, canvas);
            if (!pass.touchesEdge || canvas >= kMaxCanvas) return pass;
            canvas *= 2;
        }
    };
    Pass pass = settle(scale);
    if (!pass.any)
        fail("empty", "Nothing was drawn: every frame of '" + src.file + "' is empty.",
             "The entity needs something visible: a Sprite or Shape2D with a size and a colour with alpha, a ParticleEmitter that has emitted by the first frame (try `warmup`), and no `active: false`. "
             "A Text with space \"screen\" is drawn at its screen position, not around the entity.");
    if (pass.touchesEdge) warnings.push_back(std::format("The animation reaches the edge of the {} px canvas the bake draws on, so it is cut there: lower `scale` or make the entity smaller.", pass.canvas));

    Layout layout;
    const bool fit = !spec.scale && spec.frameWidth > 0 && spec.frameHeight > 0;
    if (fit) {
        // Measure at scale 1, then draw again at the scale that fits the cell; a pixel or two of antialiasing may need a second try.
        scale = fit_scale(pass, spec);
        for (int attempt = 0;; ++attempt) {
            scale *= attempt == 0 ? 0.99 : 0.96;
            pass = settle(scale);
            layout = compute_layout(pass, spec);
            if (layout.error.empty()) break;
            if (attempt >= 6) fail("invalid_argument", layout.error + " It could not be fitted by scaling.", "Make frameWidth and frameHeight larger, or the margin smaller.");
        }
    } else {
        layout = compute_layout(pass, spec);
        if (!layout.error.empty())
            fail("invalid_argument", layout.error, spec.scale ? "Make the frame larger, lower `scale`, or leave frameWidth / frameHeight out to fit the animation." : "Make the frame larger, or leave frameWidth / frameHeight out to fit the animation; with both and no `scale` the animation is scaled to fit.");
    }
    scale = pass.scale;

    // ---- the sheet
    int total = 0;
    std::vector<SheetClip> sheetClips;
    std::vector<Json> clipLoops;
    for (std::size_t ci = 0; ci < pass.clips.size(); ++ci) {
        const int n = int(pass.clips[ci].frames.size());
        if (!spec.clips.empty()) {
            sheetClips.push_back({spec.clips[ci].name, total, total + n - 1, spec.clips[ci].fps});
        }
        total += n;
    }
    const int columns = spec.columns > 0 ? std::min(spec.columns, total) : std::max(1, int(std::ceil(std::sqrt(double(total)))));
    const int rows = (total + columns - 1) / columns;
    const int pitchX = layout.w + 2 * spec.padding, pitchY = layout.h + 2 * spec.padding;
    if (std::int64_t(columns) * pitchX > kMaxSheetSide || std::int64_t(rows) * pitchY > kMaxSheetSide)
        fail("invalid_argument", std::format("The sheet would be {}x{} pixels ({} frames of {}x{} in {} columns); the most is {} on a side.", columns * pitchX, rows * pitchY, total, layout.w, layout.h, columns, kMaxSheetSide),
             "Lower `scale`, bake fewer frames, or pass more `columns` (a wider, shorter grid) or fewer.");
    Image sheet;
    sheet.width = columns * pitchX;
    sheet.height = rows * pitchY;
    sheet.rgba.assign(std::size_t(sheet.width) * sheet.height * 4, 0);
    int index = 0;
    int emptyFrames = 0;
    std::vector<std::string> identicalClips;
    for (std::size_t ci = 0; ci < pass.clips.size(); ++ci) {
        const auto& frames = pass.clips[ci].frames;
        bool allSame = frames.size() > 1;
        for (std::size_t f = 0; f < frames.size(); ++f) {
            const Crop& crop = frames[f];
            if (crop.empty()) ++emptyFrames;
            if (f > 0 && (crop.x0 != frames[0].x0 || crop.y0 != frames[0].y0 || crop.w != frames[0].w || crop.h != frames[0].h || crop.rgba != frames[0].rgba)) allSame = false;
            const Image cell = render_cell(crop, layout, pass.canvas, spec.background);
            const int col = index % columns, row = index / columns;
            const int cx = spec.padding + col * pitchX, cy = spec.padding + row * pitchY;
            for (int y = 0; y < cell.height; ++y)
                std::copy_n(&cell.rgba[std::size_t(y) * cell.width * 4], std::size_t(cell.width) * 4, &sheet.rgba[(std::size_t(cy + y) * sheet.width + cx) * 4]);
            ++index;
        }
        if (allSame) identicalClips.push_back(spec.clips.empty() ? std::string("the animation") : "'" + spec.clips[ci].name + "'");
    }
    if (spec.background) {  // the gutters too, so the sheet is one colour behind the frames
        for (int y = 0; y < sheet.height; ++y)
            for (int x = 0; x < sheet.width; ++x) {
                const int px = x % pitchX, py = y % pitchY;
                if (px >= spec.padding && px < spec.padding + layout.w && py >= spec.padding && py < spec.padding + layout.h && index > (y / pitchY) * columns + x / pitchX) continue;
                Image one;
                one.width = 1;
                one.height = 1;
                one.rgba = {0, 0, 0, 0};
                put_background(one, *spec.background);
                std::copy_n(one.rgba.begin(), 4, &sheet.rgba[(std::size_t(y) * sheet.width + x) * 4]);
            }
    }
    if (emptyFrames > 0) warnings.push_back(std::format("{} of the {} frames are empty (nothing is drawn at that moment): a particle burst that has not started, or an entity that is hidden for a while.", emptyFrames, total));
    if (!identicalClips.empty())
        warnings.push_back("The frames of " + join(identicalClips, ", ") + " are all identical: nothing in the entity changes over time. It needs a SpriteAnimator, a tween, a ParticleEmitter or a script that moves it; for a clip started by a script pass `call` or `event`.");

    bool opaque = true;
    for (std::size_t i = 3; i < sheet.rgba.size() && opaque; i += 4) opaque = sheet.rgba[i] == 255;
    const std::vector<std::uint8_t> png = opaque ? encode_png_rgb(sheet) : encode_png(sheet);
    std::string werr;
    if (!tooling_detail::write_file(file, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &werr)) fail("failed", werr);

    // ---- the manifest: the sheet, the provenance and the recipe
    const std::array<double, 2> pivot = {round6(double(layout.ox) / layout.w), round6(double(layout.oy) / layout.h)};
    Json sheetEntry = sheet_entry(columns, rows, layout.w, layout.h, total, sheetClips);
    if (spec.padding > 0) sheetEntry["padding"] = spec.padding;
    sheetEntry["pivot"] = Json::array({pivot[0], pivot[1]});
    if (sheetEntry.contains("clips"))
        for (std::size_t i = 0; i < spec.clips.size(); ++i) sheetEntry["clips"][i]["loop"] = spec.clips[i].loop;

    std::set<std::string> inputs;
    inputs.insert(src.file);
    collect_inputs(projectDir, spec.prefab.empty() ? src.entity : Json::object({{"prefab", src.file}}), "", inputs);
    if (!spec.scene.empty()) collect_inputs(projectDir, src.entity, "", inputs);
    const bool ai = a.contains("ai") ? tooling_detail::arg_bool(a, "ai", false) : any_ai(src.entity, projectDir, inputs);
    const std::string author = tooling_detail::arg_string(a, "author", false, ai ? "" : "factoria");
    const std::string license = tooling_detail::arg_string(a, "license", false, "CC0-1.0");

    Json recipeArgs = Json::object({{"path", spec.path}});
    if (!spec.prefab.empty()) recipeArgs["prefab"] = spec.prefab;
    else {
        recipeArgs["scene"] = spec.scene;
        recipeArgs["entity"] = spec.entity;
    }
    recipeArgs["frames"] = spec.frames;
    recipeArgs["fps"] = spec.fps;
    if (spec.columns > 0) recipeArgs["columns"] = spec.columns;
    if (spec.frameWidth > 0) recipeArgs["frameWidth"] = spec.frameWidth;
    if (spec.frameHeight > 0) recipeArgs["frameHeight"] = spec.frameHeight;
    if (spec.scale) recipeArgs["scale"] = *spec.scale;
    if (spec.pivot) recipeArgs["pivot"] = Json::array({(*spec.pivot)[0], (*spec.pivot)[1]});
    if (a.contains("clips")) recipeArgs["clips"] = a["clips"];
    recipeArgs["warmup"] = spec.warmup;
    recipeArgs["seed"] = spec.seed;
    if (a.contains("background") && !a["background"].is_null()) recipeArgs["background"] = a["background"];
    recipeArgs["padding"] = spec.padding;
    recipeArgs["margin"] = spec.margin;
    recipeArgs["overwrite"] = true;
    Json provenance = Json::object({{"origin", "generated"},
                                    {"ai", ai},
                                    {"kind", "image"},
                                    {"provider", "factoria assets.bake_sheet"},
                                    {"license", license},
                                    {"notes", std::format("Baked from {} '{}': {} frames at {} fps, {}x{} px each, scale {}, seed {}.", spec.prefab.empty() ? "entity '" + spec.entity + "' of scene" : "prefab", src.file, total, spec.fps,
                                                         layout.w, layout.h, round6(scale), spec.seed)},
                                    {"date", assets::today()},
                                    {"source", src.file}});
    if (!author.empty()) provenance["author"] = author;
    provenance["recipe"] = make_recipe(projectDir, kCommand, recipeArgs, std::vector<std::string>(inputs.begin(), inputs.end()));
    {
        auto r = assets::update_entry(spec.path, [&](Json& e) {
            e.erase("analysis");
            e["sheet"] = sheetEntry;
            e["provenance"] = provenance;
        });
        if (!r.ok()) fail("failed", "The sheet was written, but assets.json was not updated: " + r.error().message, r.error().hint);
    }

    Json result = Json::object({{"path", spec.path}, {"width", sheet.width}, {"height", sheet.height}, {"frames", total}, {"columns", columns}, {"rows", rows},
                                {"frameWidth", layout.w}, {"frameHeight", layout.h}, {"scale", round6(scale)}, {"pivot", Json::array({pivot[0], pivot[1]})},
                                {"sheet", sheetEntry}, {"provenance", provenance}});
    if (!warnings.empty()) result["warnings"] = warnings;
    result["$image"] = Json::object({{"path", file.string()}, {"mimeType", "image/png"}});
    std::vector<std::string> next = sheet_next_steps(spec.path, sheetEntry, spec.fps);
    next.push_back(std::format("The entity's origin is the pivot [{}, {}] of every frame, counted from the top-left corner of the frame. Sprite.pivot counts from the bottom-left corner: to keep the baked origin where the entity was, set Sprite.pivot to [{}, {}].",
                               pivot[0], pivot[1], pivot[0], round6(1.0 - pivot[1])));
    next.push_back("Make it again after editing the prefab or its scripts with assets.regenerate (the recipe is in the provenance of assets.json). Look at the image in this result: if a frame is wrong, change the entity or its warmup and bake again.");
    result["nextSteps"] = next;
    return result;
}

}  // namespace

void register_bake_sheet_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Bake an entity the engine draws (a prefab, or an entity of a scene) into a sprite sheet: Shape2D, tweens, particles and scripts play and are captured frame by frame.";
    info.description =
        "Plays a prefab (`prefab`) or an entity of a scene with its children (`scene` + `entity`) alone in a private world and captures it into a PNG sprite sheet at `path` (under assets/, ending in .png), with its `sheet` entry, provenance and recipe in assets.json. "
        "Use it to turn something that costs many draw calls on a phone (a glow made of shapes, a particle burst, a tweened badge, a scripted explosion) into ONE sprite, to make an effect once and play it as a SpriteAnimator, or to draw animated art with the engine's own Shape2D (gradients, strokes) instead of SVG. "
        "The world is simulated at the project's fixed step with the world RNG seeded from `seed`, so the same prefab, seed and settings bake the same pixels on the same GPU (the pixels of two different GPUs can differ by an edge pixel); a frame is captured every 1/`fps` seconds of simulated time, `frames` frames per clip. "
        "SpriteAnimator, Tint, tweens, ParticleEmitter, Shape2D, Sprite and the entity's scripts all run as in the game; nothing else is in the world (no other entities and no lights: a `lit` sprite is drawn as in a world without lights). The entity is placed at the origin of the world, even when the scene puts it elsewhere. "
        "Frame 0 is drawn after one step (the entity's start() has run) and after `warmup` seconds. "
        "`clips` bakes several named clips from one entity, each in a fresh world: `[{\"name\":\"explode\",\"call\":\"explode\",\"frames\":24,\"loop\":false}, {\"name\":\"idle\",\"frames\":8}]`; `call` runs that method of the entity's behaviour right after the warm-up (`args` are its arguments), `event` sends a game event instead (`data`); a clip with neither just plays. They follow each other in the sheet and become clips of its `sheet` entry (firstFrame, lastFrame, fps, loop). "
        "Framing: the pixels are drawn at `scale` pixels per world unit and cropped to everything drawn in ANY frame plus `margin`, so nothing is cut (a particle burst that grows is included) and the entity's origin is the same pixel in every frame: it is the `pivot` recorded in the sheet entry ([x, y] in 0..1 from the top-left of the frame). Give `pivot` to choose where the origin lands (a character's feet: [0.5, 1]); give `frameWidth` and `frameHeight` for a fixed cell: without `scale` the animation is scaled to fit it, with `scale` it must fit or the command fails and says how large the cell must be. "
        "The colours are straight alpha with the colour of the edge pixels bled outwards, so a sprite scaled with filtering has no dark halo; additive glows keep their light (their alpha is the brightest channel). `background` puts a colour behind the frames (default transparent). `padding` leaves transparent pixels around each cell (default 1; the sheet entry records it). "
        "Needs a GPU (Metal, Direct3D 11 or OpenGL; headless Linux needs Mesa's EGL). A process has one graphics device: when this one already uses it (the editor, an MCP session with graphics) the bake runs in a child `factoria call` process; from a terminal `factoria call assets.bake_sheet` works as is. "
        "A script that throws, a `call` that is not a method of the behaviour (with its methods and a suggestion) or a prefab that does not load fail with an error that names the prefab and the script. "
        "Provenance: origin generated, `ai` is true when the prefab, the scene or a texture it draws is recorded in assets.json as AI-made (pass `ai` to override, with `author` and `license`); the recipe holds the arguments and the SHA-256 of the prefab or scene, its scripts and textures, so assets.regenerate can make the sheet again and validate can tell when it is stale. "
        "Example: {\"path\":\"assets/fx/burst.png\",\"prefab\":\"prefabs/burst.prefab.json\",\"frames\":16,\"fps\":24,\"warmup\":0.5,\"pivot\":[0.5,0.5]}";
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"path"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"path", Json::object({{"type", "string"}, {"description", "Where to write the PNG sheet, project-relative, under assets/ and ending in .png."}})},
               {"prefab", Json::object({{"type", "string"}, {"description", "The prefab to bake, project-relative (\"prefabs/burst.prefab.json\"). Give this, or `scene` + `entity`."}})},
               {"scene", Json::object({{"type", "string"}, {"description", "A scene file that holds the entity to bake. Needs `entity`."}})},
               {"entity", Json::object({{"type", "string"}, {"description", "The id of the entity of `scene` to bake, with its children."}})},
               {"frames", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", kMaxFrames}, {"default", 12}, {"description", "Frames per clip (all of them without `clips`)."}})},
               {"fps", Json::object({{"type", "number"}, {"minimum", 1}, {"maximum", 240}, {"default", 12}, {"description", "Frames per second of simulated time (at most the project's fixed rate, 60 by default): a frame is captured every 1/fps seconds. Also the sheet's clip speed."}})},
               {"columns", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "Columns of the grid; 0 or absent = square-ish."}})},
               {"frameWidth", Json::object({{"type", "integer"}, {"minimum", 1}, {"description", "Pixels of a cell. Absent = as wide as the animation needs."}})},
               {"frameHeight", Json::object({{"type", "integer"}, {"minimum", 1}, {"description", "Pixels of a cell. Absent = as tall as the animation needs."}})},
               {"scale", Json::object({{"type", "number"}, {"minimum", kMinScale}, {"maximum", kMaxScale}, {"description", "Pixels per world unit (1 = the size the entity has in the world, 2 = twice as big). Absent: 1, or the scale that fits frameWidth x frameHeight when both are given."}})},
               {"pivot", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}})}, {"minItems", 2}, {"maxItems", 2}, {"description", "[x, y] in 0..1 from the top-left of the frame: where the entity's origin lands in every frame ([0.5, 1] = middle of the bottom edge). Absent: where the animation puts it (the cell is the tight box of everything drawn)."}})},
               {"clips", Json::object({{"type", "array"}, {"minItems", 1}, {"description", "Named clips, each in a fresh world: {name, call?, args?, event?, data?, frames?, fps?, loop?, warmup?}. `call` is a method of the entity's behaviour, `event` a game event (world.on); both start the clip after the warm-up. They follow each other in the sheet."},
                                        {"items", Json::object({{"type", "object"}, {"required", Json::array({"name"})}, {"additionalProperties", false},
                                                                {"properties", Json::object({{"name", Json::object({{"type", "string"}})}, {"call", Json::object({{"type", "string"}})},
                                                                                             {"args", Json::object({{"type", "array"}})}, {"event", Json::object({{"type", "string"}})}, {"data", Json::object({})},
                                                                                             {"frames", Json::object({{"type", "integer"}, {"minimum", 1}})}, {"fps", Json::object({{"type", "number"}, {"minimum", 1}})},
                                                                                             {"loop", Json::object({{"type", "boolean"}, {"default", true}})}, {"warmup", Json::object({{"type", "number"}, {"minimum", 0}})}})}})}})},
               {"warmup", Json::object({{"type", "number"}, {"minimum", 0}, {"default", 0}, {"description", "Seconds of simulated time to play before the first frame (a particle system that should start full). A clip can set its own."}})},
               {"seed", Json::object({{"type", "integer"}, {"default", 1}, {"description", "Seeds the world RNG (scripts' rng, random particles): the same seed gives the same sheet."}})},
               {"background", Json::object({{"description", "A colour behind the frames (\"#rrggbb\", \"#rrggbbaa\", a name or [r, g, b]). Default: transparent."}})},
               {"padding", Json::object({{"type", "integer"}, {"minimum", 0}, {"default", 1}, {"description", "Transparent pixels around every cell (twice between two cells), recorded in the sheet entry."}})},
               {"margin", Json::object({{"type", "integer"}, {"minimum", 0}, {"default", 2}, {"description", "Empty pixels kept around the animation's outline."}})},
               {"overwrite", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Replace the file when it already exists."}})},
               {"ai", Json::object({{"type", "boolean"}, {"description", "Override the AI disclosure. Default: true when the prefab/scene or a texture it draws is recorded as AI-made in assets.json."}})},
               {"author", Json::object({{"type", "string"}, {"description", "Who gets the credit in the provenance record."}})},
               {"license", Json::object({{"type", "string"}, {"default", "CC0-1.0"}, {"description", "License of the sheet for the provenance record."}})}})}});
    registry.add(info, [projectDir](const Json& args) { return bake_sheet(projectDir, args); });
}

}  // namespace fa::assets_detail
