// assets.preview_in_scene: an asset drawn inside a scene of the game, at the screen sizes of a phone and of a desktop. A second
// engine (headless, its own offscreen GPU target) starts the scene as it is on disk, puts a temporary entity in the world (a
// PNG as a Sprite, a .glb as a MeshRenderer), steps a few frames and captures the picture, once per reference resolution. The
// scene file is never written; the temporary entity lives only in that engine, which is gone when the command returns. The
// pictures come back as ONE image with the screens side by side, each labelled with its name and size.
// A process has one graphics device: when this one already owns it (the editor, an MCP session), the same command runs in a
// child `factoria call` instead (as assets.bake_sheet does).
#include <algorithm>
#include <cmath>
#include <format>

#include "assets_shots.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/platform/app.h"
#include "fa/runtime/engine.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/components.h"
#include "fa/scene/mesh_geometry.h"
#include "headless_run.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kCommand = "assets.preview_in_scene";
constexpr int kMaxPicture = 2048;
constexpr int kMaxSide = 4096;
constexpr const char* kTempId = "preview_in_scene_asset";

[[noreturn]] void bad(const std::string& pointer, const std::string& what, const std::string& hint) { arg_error(kCommand, pointer, what, hint); }

struct Screen {
    std::string name;
    int width = 0, height = 0;
};

// The reference resolutions: a phone held upright (19.5:9) and a desktop window (16:9). The game's design resolution is
// replaced by them for the run, so a camera that shows a fixed height of world shows the same height on both.
std::vector<Screen> parse_resolutions(const Json& a) {
    if (!a.contains("resolutions") || a["resolutions"].is_null()) return {{"phone", 540, 1170}, {"desktop", 1280, 720}};
    if (!a["resolutions"].is_array() || a["resolutions"].empty() || a["resolutions"].size() > 4)
        bad("/resolutions", "expected a list of 1 to 4 resolutions.", "Names \"phone\" (540x1170), \"tablet\" (1024x768), \"desktop\" (1280x720), or \"WxH\" like \"800x600\". Default [\"phone\", \"desktop\"].");
    std::vector<Screen> out;
    for (std::size_t i = 0; i < a["resolutions"].size(); ++i) {
        const Json& r = a["resolutions"][i];
        const std::string at = "/resolutions/" + std::to_string(i);
        if (!r.is_string()) bad(at, "expected a name or \"WxH\" as a string.", "Example: \"phone\" or \"800x600\".");
        const std::string s = to_lower(r.get<std::string>());
        Screen sc;
        if (s == "phone") sc = {"phone", 540, 1170};
        else if (s == "tablet") sc = {"tablet", 1024, 768};
        else if (s == "desktop") sc = {"desktop", 1280, 720};
        else {
            const auto x = s.find('x');
            int w = 0, h = 0;
            try {
                if (x == std::string::npos || x == 0 || x + 1 >= s.size()) throw std::invalid_argument("");
                std::size_t used = 0;
                w = std::stoi(s.substr(0, x), &used);
                if (used != x) throw std::invalid_argument("");
                h = std::stoi(s.substr(x + 1), &used);
                if (used != s.size() - x - 1) throw std::invalid_argument("");
            } catch (const std::exception&) {
                bad(at, "'" + r.get<std::string>() + "' is not a resolution.", "Use \"phone\", \"tablet\", \"desktop\" or \"WxH\" such as \"800x600\"." + std::string(" ") + did_you_mean(s, std::vector<std::string>{"phone", "tablet", "desktop"}));
            }
            if (w < 64 || h < 64 || w > kMaxSide || h > kMaxSide) bad(at, std::format("{}x{} is outside 64..{} pixels per side.", w, h, kMaxSide), "Use a size a screen has, such as \"800x600\".");
            sc = {std::format("{}x{}", w, h), w, h};
        }
        for (const Screen& other : out)
            if (other.width == sc.width && other.height == sc.height) bad(at, "'" + r.get<std::string>() + "' repeats a resolution already listed.", "List each resolution once.");
        out.push_back(sc);
    }
    return out;
}

bool number_list(const Json& v, std::size_t minCount, std::size_t maxCount, std::vector<double>& out) {
    if (!v.is_array() || v.size() < minCount || v.size() > maxCount) return false;
    for (const Json& n : v) {
        if (!n.is_number()) return false;
        out.push_back(n.get<double>());
    }
    return true;
}

struct Spec {
    std::string path, scene, entity, placement = "beside", ext;
    std::optional<std::vector<double>> at;
    std::vector<double> offset{0, 0};
    std::optional<std::vector<double>> size;  // [n] longest side, or [w, h]
    std::vector<Screen> screens;
    int steps = 2;
    bool center = false;
};

Spec parse_spec(const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "assets.preview_in_scene expects an object.", "Pass {\"path\":\"assets/hero.png\",\"scene\":\"scenes/main.scene.json\",\"at\":[0,0]}.");
    check_arg_keys(kCommand, a, "", {"path", "scene", "at", "entity", "placement", "offset", "size", "resolutions", "steps", "center"});
    Spec s;
    auto norm_path = [&](const char* key, const char* what, const char* example) {
        auto it = a.find(key);
        if (it == a.end() || !it->is_string()) bad(std::string("/") + key, std::string("expected the project path of ") + what + " as a string.", std::string("Example: \"") + example + "\".");
        auto norm = fs::normalize_checked(it->get<std::string>());
        if (!norm.ok() || norm->empty()) bad(std::string("/") + key, "'" + it->get<std::string>() + "' is not a path inside the project.", std::string("Use a project-relative path such as \"") + example + "\".");
        return *norm;
    };
    s.path = norm_path("path", "the asset", "assets/hero.png");
    s.scene = norm_path("scene", "the scene", "scenes/main.scene.json");
    s.ext = to_lower(fs::extension(s.path));
    if (s.ext != ".png" && s.ext != ".jpg" && s.ext != ".jpeg" && s.ext != ".glb")
        fail("invalid_argument", "'" + s.path + "' is not something to place in a scene (" + (s.ext.empty() ? "no extension" : s.ext) + ").",
             "assets.preview_in_scene places a PNG (JPG) as a Sprite or a .glb as a MeshRenderer. For sound use assets.spectrogram; for a .gltf import it as .glb with assets.import.");
    if (a.contains("at") && !a["at"].is_null()) {
        std::vector<double> v;
        if (!number_list(a["at"], 2, 3, v)) bad("/at", "expected [x, y] or [x, y, z], numbers in world units.", "Example: [0, 0]; scene.list_entities shows where the entities of the scene are.");
        s.at = v;
    }
    if (a.contains("entity") && !a["entity"].is_null()) {
        if (!a["entity"].is_string() || a["entity"].get<std::string>().empty()) bad("/entity", "expected the id (or name) of an entity of the scene.", "scene.list_entities lists them.");
        s.entity = a["entity"].get<std::string>();
    }
    if (s.at && !s.entity.empty()) bad("/entity", "give `at` or `entity`, not both.", "`at` is a world position; `entity` places the asset next to (or in place of) that entity. Use `offset` to move it from the entity.");
    if (a.contains("placement") && !a["placement"].is_null()) {
        const std::string p = a["placement"].is_string() ? a["placement"].get<std::string>() : "";
        if (p != "beside" && p != "replace") bad("/placement", "expected \"beside\" or \"replace\".", "beside (default): next to the entity; replace: at its position, with the entity hidden for the picture. Only with `entity`.");
        if (s.entity.empty()) bad("/placement", "`placement` needs `entity`.", "Name the entity the asset goes next to or replaces, or use `at`.");
        s.placement = p;
    }
    if (a.contains("offset") && !a["offset"].is_null()) {
        std::vector<double> v;
        if (!number_list(a["offset"], 2, 2, v)) bad("/offset", "expected [x, y] in world units.", "Added to the position: [40, 0] moves the asset 40 units to the right.");
        s.offset = v;
    }
    if (a.contains("size") && !a["size"].is_null()) {
        std::vector<double> v;
        const Json& sz = a["size"];
        const bool ok = sz.is_number() ? (v.push_back(sz.get<double>()), true) : number_list(sz, 2, 2, v);
        if (!ok || std::any_of(v.begin(), v.end(), [](double n) { return !(n > 0 && n <= 100000); }))
            bad("/size", "expected a positive number, or [width, height] for a sprite.", s.ext == ".glb" ? "For a model it is the largest dimension in world units (meters): 2 makes it 2 m long." : "In world units, as Sprite.size: 48 makes the longest side 48 units, [64, 32] sets both. Leave it out for the size of the picture in pixels.");
        if (s.ext == ".glb" && v.size() != 1) bad("/size", "a model takes one number: its largest dimension in world units.", "Example: \"size\": 2.");
        s.size = v;
    }
    s.screens = parse_resolutions(a);
    s.steps = int(tooling_detail::arg_int(a, "steps", 2));
    if (s.steps < 0 || s.steps > 600) bad("/steps", "expected a whole number from 0 to 600.", "Frames the scene runs before the asset is placed (its scripts start, a tween or spawner settles). Default 2.");
    s.center = tooling_detail::arg_bool(a, "center", false);
    return s;
}

std::string first_script_error(Engine& engine) {
    const auto& errors = engine.scripts().errors();
    return errors.empty() ? std::string() : errors.front().to_string();
}

// A very rough size of an entity for placing something beside it: Sprite / Shape2D size, else 64.
Vec2 rough_size(World& w, Entity e) {
    if (auto* s = w.get<Sprite>(e); s && s->size.x > 0 && s->size.y > 0) return s->size;
    if (auto* s = w.get<Shape2D>(e); s && s->size.x > 0 && s->size.y > 0) return s->size;
    return {64, 64};
}

struct Shot {
    Image image;
    Json info;
    std::vector<std::string> warnings;
};

Shot take_shot(const std::string& projectDir, const Spec& spec, const Screen& screen, const Vec2& assetSize, const Json& assetEntity, double modelExtent, bool isModel) {
    Shot shot;
    EngineConfig cfg = tooling_detail::headless_engine_config(projectDir, spec.scene, true, RenderMode::OnDemand);
    cfg.width = screen.width;
    cfg.height = screen.height;
    Engine engine;
    std::string err;
    if (!engine.init(cfg, nullptr, &err)) {
        if (err.find("No renderer") != std::string::npos || err.find("graphics") != std::string::npos)
            no_gpu_error(kCommand, err, "Without one, game.screenshot after a scene edit is not possible either; ask for a machine with a GPU.");
        fail("failed", "Cannot start the engine that draws the scene '" + spec.scene + "': " + err, "Check the scene with scene.validate / factoria validate, and run game.screenshot on it.");
    }
    struct Shutdown {
        Engine& e;
        ~Shutdown() { e.shutdown(); }
    } shutdown{engine};
    World& world = engine.world();
    if (spec.steps > 0) engine.step(spec.steps);
    if (std::string e = first_script_error(engine); !e.empty())
        shot.warnings.push_back("A script of the scene '" + spec.scene + "' failed before the asset was placed (" + screen.name + "): " + e + " The picture may not show the scene as intended.");

    // ---- where ----
    Vec3 position{0, 0, 0};
    Entity camera = kNullEntity;
    const std::vector<Entity> cameras = rendering_cameras(world);
    if (!cameras.empty()) camera = cameras.front();
    const Camera* camData = camera != kNullEntity ? world.get<Camera>(camera) : nullptr;
    const bool ortho = !camData || camData->projection == Projection::Orthographic;
    Entity target = kNullEntity;
    if (spec.at) {
        position = {float((*spec.at)[0]), float((*spec.at)[1]), spec.at->size() > 2 ? float((*spec.at)[2]) : 0.0f};
    } else if (!spec.entity.empty()) {
        target = world.find(spec.entity);
        if (target == kNullEntity) {
            std::vector<std::string> ids;
            for (Entity e : world.entities()) ids.push_back(world.id_of(e));
            std::sort(ids.begin(), ids.end());
            fail("not_found", "The scene '" + spec.scene + "' has no entity '" + spec.entity + "' (after " + std::to_string(spec.steps) + " frames).",
                 did_you_mean(spec.entity, ids) + " Entities: " + join(std::vector<std::string>(ids.begin(), ids.begin() + std::min<std::size_t>(ids.size(), 12)), ", ") + (ids.size() > 12 ? ", ..." : "") + ". scene.list_entities lists them all.");
        }
        position = world.world_position(target);
        if (spec.placement == "beside") {
            const Vec2 other = rough_size(world, target);
            position.x += other.x * 0.5f + assetSize.x * 0.5f + 8;
        }
    } else if (camera != kNullEntity) {
        const Vec3 cp = world.world_position(camera);
        if (ortho) {
            position = {cp.x, cp.y, 0};
        } else {
            const Mat4 m = world.world_matrix(camera);
            Vec3 fwd{-m.m[8], -m.m[9], -m.m[10]};
            const float len = std::sqrt(fwd.x * fwd.x + fwd.y * fwd.y + fwd.z * fwd.z);
            if (len > 0) fwd = fwd / len;
            const float distance = float(std::max(3.0, modelExtent * 2.5));
            position = cp + fwd * distance;
        }
    }
    position.x += float(spec.offset[0]);
    position.y += float(spec.offset[1]);

    Json entity = assetEntity;
    entity["components"]["Transform"]["position"] = Json::array({position.x, position.y, position.z});
    CommandResult spawned = engine.commands().call("scene.spawn", Json::object({{"entity", entity}}));
    if (!spawned.ok)
        fail("invalid_argument", "The scene could not take the asset: " + spawned.error.value("message", std::string()), spawned.error.value("hint", std::string()));
    if (target != kNullEntity && spec.placement == "replace") world.set_active(target, false);
    if (spec.center && camera != kNullEntity && ortho) {
        const Vec3 cp = world.world_position(camera);
        world.set_world_position(camera, {position.x, position.y, cp.z});
    }
    engine.step(1);

    if (std::string e = first_script_error(engine); !e.empty() && shot.warnings.empty())
        shot.warnings.push_back("A script of the scene failed while the asset was shown (" + screen.name + "): " + e);

    // ---- is it in view ----
    bool onScreen = true;
    if (camera != kNullEntity && ortho) {
        const OrthoView view = ortho_view(world, {float(screen.width), float(screen.height)}, camera, nullptr);
        const Vec3 p = world.world_position(world.find_by_id(kTempId) != kNullEntity ? world.find_by_id(kTempId) : camera);
        const Vec2 s = view.to_screen(p);
        onScreen = s.x >= 0 && s.y >= 0 && s.x <= screen.width && s.y <= screen.height;
        if (!onScreen)
            shot.warnings.push_back(std::format("At {} ({}x{}) the asset is outside the view (its centre would be at pixel {}, {}). Pass `at` inside the camera's view, or `center: true` to move the camera onto it.", screen.name, screen.width, screen.height, int(s.x), int(s.y)));
    }
    if (!engine.capture_scaled(shot.image, 1.0, &err)) {
        if (err.find("No renderer") != std::string::npos) no_gpu_error(kCommand, err, "");
        fail("failed", "Cannot capture the scene at " + screen.name + ": " + err);
    }
    shot.info = Json::object({{"name", screen.name}, {"width", screen.width}, {"height", screen.height}, {"position", Json::array({position.x, position.y, position.z})}});
    if (camera != kNullEntity && ortho) shot.info["onScreen"] = onScreen;
    return shot;
}

Json preview(const std::string& projectDir, const Json& a) {
    const Spec spec = parse_spec(a);
    ProjectRootGuard root(projectDir);
    std::error_code ec;
    if (!stdfs::is_regular_file(project_file(projectDir, spec.path), ec)) fail("not_found", "'" + spec.path + "' does not exist.", "assets.list shows the images and models of the project; assets.import brings a file in.");
    if (!stdfs::is_regular_file(project_file(projectDir, spec.scene), ec)) fail("not_found", "The scene '" + spec.scene + "' does not exist.", "Scenes live under scenes/ and end in .scene.json; project.info names the main scene.");
    if (gfx_device_active()) return call_in_child(projectDir, kCommand, a);

    // ---- the temporary entity ----
    const bool isModel = spec.ext == ".glb";
    Json entity = Json::object({{"id", kTempId}, {"name", "Preview (temporary)"}, {"components", Json::object({{"Transform", Json::object()}})}});
    Vec2 assetSize{64, 64};
    double modelExtent = 1;
    std::vector<std::string> warnings;
    Json asset = Json::object({{"path", spec.path}, {"kind", isModel ? "model" : "sprite"}});
    if (isModel) {
        auto geometry = load_mesh_geometry(spec.path);
        if (!geometry.ok()) fail("invalid_argument", "'" + spec.path + "' cannot be read as a model: " + geometry.error().message, geometry.error().hint);
        const Vec3 extent = (*geometry)->bmax - (*geometry)->bmin;
        modelExtent = std::max({extent.x, extent.y, extent.z, 1e-3f});
        double scale = spec.size ? (*spec.size)[0] / modelExtent : 1.0;
        entity["components"]["Transform"]["scale"] = Json::array({scale, scale, scale});
        entity["components"]["MeshRenderer"] = Json::object({{"mesh", spec.path}});
        modelExtent *= scale;
        assetSize = {float(modelExtent), float(modelExtent)};
        asset["size"] = Json::array({extent.x * scale, extent.y * scale, extent.z * scale});
    } else {
        auto loaded = load_image(project_file(projectDir, spec.path));
        if (!loaded.ok()) fail("invalid_argument", "'" + spec.path + "': " + loaded.error().message, loaded.error().hint);
        double w = loaded->width, h = loaded->height;
        Json sprite = Json::object({{"texture", spec.path}, {"layer", 10000}});
        if (auto entry = assets::sheet(spec.path)) {  // a sprite sheet: its first frame
            const int pad = std::max(0, entry->padding);
            const int fw = entry->frameWidth > 0 ? entry->frameWidth : std::max(1, loaded->width / std::max(1, entry->columns) - 2 * pad);
            const int fh = entry->frameHeight > 0 ? entry->frameHeight : std::max(1, loaded->height / std::max(1, entry->rows) - 2 * pad);
            sprite["region"] = Json::array({pad, pad, fw, fh});
            w = fw;
            h = fh;
            warnings.push_back("'" + spec.path + "' is a sprite sheet: its first frame is placed. Add a SpriteAnimator in the scene to play it.");
        }
        if (spec.size) {
            if (spec.size->size() == 2) {
                w = (*spec.size)[0];
                h = (*spec.size)[1];
            } else {
                const double k = (*spec.size)[0] / std::max(w, h);
                w *= k;
                h *= k;
            }
            sprite["size"] = Json::array({w, h});
        }
        entity["components"]["Sprite"] = sprite;
        assetSize = {float(w), float(h)};
        asset["size"] = Json::array({w, h});
        asset["nativePixels"] = Json::array({loaded->width, loaded->height});
    }

    // ---- one picture per resolution ----
    std::vector<Shot> shots;
    for (const Screen& screen : spec.screens) shots.push_back(take_shot(projectDir, spec, screen, assetSize, entity, modelExtent, isModel));
    for (const Shot& s : shots) warnings.insert(warnings.end(), s.warnings.begin(), s.warnings.end());

    // ---- the picture: the screens side by side, a label above each ----
    constexpr int gap = 12;
    const int labelH = 22;
    int width = gap, height = 0;
    for (const Shot& s : shots) {
        width += s.image.width + gap;
        height = std::max(height, s.image.height);
    }
    height += labelH + gap;
    Image sheet;
    sheet.width = width;
    sheet.height = height;
    sheet.rgba.assign(std::size_t(width) * height * 4, 255);
    fill_rect_rgb(sheet, 0, 0, width, height, {34, 34, 40});
    int x = gap;
    Json screens = Json::array();
    for (std::size_t i = 0; i < shots.size(); ++i) {
        const Image& im = shots[i].image;
        draw_text(sheet, x, 3, std::format("{} {}x{}", spec.screens[i].name, im.width, im.height), 14.0f, {235, 235, 240});
        draw_over(sheet, im, x, labelH);
        Json info = shots[i].info;
        info["x"] = x;
        info["y"] = labelH;
        screens.push_back(info);
        x += im.width + gap;
    }
    double pictureScale = 1.0;
    if (std::max(sheet.width, sheet.height) > kMaxPicture) {
        pictureScale = double(kMaxPicture) / std::max(sheet.width, sheet.height);
        sheet = resize_area(sheet, std::max(1, int(std::lround(sheet.width * pictureScale))), std::max(1, int(std::lround(sheet.height * pictureScale))));
        warnings.push_back(std::format("The screens together were larger than {} px and the picture is reduced to {}%: ask for fewer or smaller `resolutions` to see them as drawn.", kMaxPicture, int(std::lround(pictureScale * 100))));
    }

    Json result = Json::object({{"asset", asset}, {"scene", spec.scene}, {"screens", screens}});
    if (!spec.entity.empty()) result["entity"] = Json::object({{"id", spec.entity}, {"placement", spec.placement}});
    result["picture"] = Json::object({{"width", sheet.width}, {"height", sheet.height}, {"scale", pictureScale}});
    result["sceneFileChanged"] = false;
    result["warnings"] = warnings;
    std::vector<std::string> steps;
    steps.push_back("Read the picture: one screen per label (name and pixels), the scene as it starts plus the temporary asset. The scene file was not touched and the temporary entity is gone.");
    steps.push_back("Judge the asset against its neighbours: scale, outline against the ground, colour in that light. Fix the asset and run this again; assets.contact_sheet compares it with the rest of the set on several backgrounds.");
    if (!spec.at && spec.entity.empty()) steps.push_back("It was placed at the middle of the view. Pass `at` [x, y] to try another place, or `entity` to put it next to (or, with placement \"replace\", in place of) an entity of the scene.");
    steps.push_back("To keep it in the game, add it with scene.spawn or a Sprite / MeshRenderer on an entity, then check the real scene with game.screenshot.");
    result["nextSteps"] = steps;
    result["$image"] = image_member(write_temporary_picture(projectDir, sheet, "inscene"), true);
    return result;
}

}  // namespace

void register_preview_scene_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = true;
    info.summary = "See an asset inside a scene of the game: it is placed (a PNG as a Sprite, a .glb as a MeshRenderer) in a private run of the scene and captured at phone and desktop resolutions.";
    info.description =
        "Starts the scene `scene` in a second, headless engine, steps `steps` frames (default 2) so its scripts start, puts a temporary entity with the asset in the world and captures the view once per resolution. The result is ONE image with the screens side by side, each labelled with its name and size, plus `screens` (each with its position in the picture and, for a 2D camera, whether the asset is in view). "
        "The scene file is never changed and the temporary entity exists only in that engine, so nothing needs cleaning up. "
        "Where: `at` [x, y(, z)] in world units; or `entity` (an id or name in the scene) with `placement` \"beside\" (default: to the right of it, using the size of its Sprite or Shape2D, 64 when it has none) or \"replace\" (at its position, the entity hidden for the picture); `offset` [x, y] moves it from there. Without either, the middle of the view: the camera's position for a 2D scene, a few meters in front of the camera for a 3D one. `center: true` also moves a 2D camera onto the asset (a script that moves the camera can undo it). "
        "How big: `size` is in world units like Sprite.size: a number is the longest side (the proportions of the picture are kept), [w, h] sets both; without it the sprite is drawn at its size in pixels. A .glb takes one number, its largest dimension in meters, or its own size. A sprite sheet is placed as its first frame (from its `sheet` entry). "
        "`resolutions` are \"phone\" (540x1170, upright), \"tablet\" (1024x768), \"desktop\" (1280x720) or \"WxH\"; default phone and desktop. The run uses the resolution as the design resolution of the game, so the world a camera shows follows the shape of the screen the way the game's scale mode does on a device: a camera with a fixed orthoSize shows the same height on both. "
        "Needs a GPU (Metal, Direct3D 11 or OpenGL; headless Linux needs Mesa's EGL); without one it fails with no_gpu. A process has one graphics device: when this one already uses it (the editor, an MCP session with graphics) the work runs in a child `factoria call` process. The same inputs give the same pixels on the same GPU. "
        "Example: {\"path\":\"assets/slime.png\",\"scene\":\"scenes/main.scene.json\",\"entity\":\"player\",\"size\":48}.";
    auto prop = [](const char* type, const char* text) { return Json::object({{"type", type}, {"description", text}}); };
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"path", "scene"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"path", prop("string", "Project-relative path of the asset: a PNG/JPG (placed as a Sprite) or a .glb (placed as a MeshRenderer).")},
               {"scene", prop("string", "Project-relative path of the scene to place it in, e.g. scenes/main.scene.json. The file is read, never written.")},
               {"at", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 2}, {"maxItems", 3}, {"description", "World position [x, y] or [x, y, z] for the asset. Not with `entity`."}})},
               {"entity", prop("string", "Id (or name) of an entity of the scene: the asset goes next to it, or in its place (see `placement`). Not with `at`.")},
               {"placement", Json::object({{"type", "string"}, {"enum", Json::array({"beside", "replace"})}, {"description", "With `entity`: beside = to the right of the entity; replace = at its position, with the entity hidden in the picture."}})},
               {"offset", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 2}, {"maxItems", 2}, {"description", "[x, y] in world units added to the position."}})},
               {"size", Json::object({{"description", "Sprite: a number (longest side) or [width, height], in world units like Sprite.size; default the size in pixels. Model: its largest dimension in meters; default its own size."}})},
               {"resolutions", Json::object({{"type", "array"}, {"minItems", 1}, {"maxItems", 4}, {"items", Json::object({{"type", "string"}})}, {"description", "\"phone\" (540x1170), \"tablet\" (1024x768), \"desktop\" (1280x720) or \"WxH\". Default [\"phone\", \"desktop\"]."}})},
               {"steps", Json::object({{"type", "integer"}, {"minimum", 0}, {"maximum", 600}, {"default", 2}, {"description", "Frames the scene runs before the asset is placed."}})},
               {"center", Json::object({{"type", "boolean"}, {"default", false}, {"description", "2D scenes: move the camera onto the asset so it is in view at every resolution."}})}})}});
    registry.add(info, [projectDir](const Json& args) { return preview(projectDir, args); });
}

}  // namespace fa::assets_detail
