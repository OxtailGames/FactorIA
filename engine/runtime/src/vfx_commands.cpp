// The commands of the effect documents (`*.vfx.json`, docs/PARTICLES.md "Effect documents"): vfx.play and vfx.stop run an effect,
// vfx.check reads one and lists every problem, vfx.list says which effects play, vfx.budget measures what one costs on a phone
// (headless) and vfx.filmstrip films one playing in the game. The effect itself is fa/scene/vfx.h.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <format>
#include <optional>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/image_tools.h"
#include "fa/core/strings.h"
#include "fa/scene/vfx.h"
#include "fa/scene/vfx_budget.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

// [x, y] or [x, y, z]: finite numbers, kept inside +-1e9 so a typo cannot throw an effect out of float range.
Vec3 position_arg(const Json& a, const char* key) {
    Vec3 out{0, 0, 0};
    if (!a.contains(key) || a[key].is_null()) return out;
    const Json& v = a[key];
    bool ok = v.is_array() && (v.size() == 2 || v.size() == 3);
    if (ok)
        for (const Json& c : v) ok = ok && c.is_number() && std::isfinite(c.get<double>()) && std::fabs(c.get<double>()) <= 1.0e9;
    if (!ok)
        throw CommandError("invalid_argument", std::format("`{}` must be [x, y] or [x, y, z] (finite numbers), got {}.", key, describe_json_value(v)),
                           "Example: \"position\": [120, 64].");
    return {v[0].get<float>(), v[1].get<float>(), v.size() == 3 ? v[2].get<float>() : 0.0f};
}

Json issues_json(const std::vector<VfxIssue>& issues, bool errors) {
    Json out = Json::array();
    for (const VfxIssue& i : issues)
        if (i.error == errors) out.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return out;
}

constexpr int kMaxFilmstripTiles = 64;
constexpr int kMaxSheetSide = 8192;
constexpr double kAutoSheetWidth = 1600;  // a filmstrip without `zoom` is drawn to be about this wide
constexpr double kMaxFilmSpan = 3.0;      // seconds of effect a filmstrip covers when `everyFrames` is not given

// The project's main camera as vfx.budget projects 3D quads through it: the active primary Camera that draws to the screen with the
// lowest depth (the one the renderer calls "the" camera). Empty when the world has none.
// The renderer's own camera list (renderer.cpp, ordered by depth) is private to the render module, so this repeats its filter; it also
// ignores Camera.viewport and the scale mode (Expand): the view is taken as the design size, so the aspect is the design size's.
std::optional<VfxBudgetCamera> main_camera(Engine::Impl& I) {
    Entity best = kNullEntity;
    int bestDepth = 0;
    const TypeInfo* ct = TypeRegistry::global().of<Camera>();
    for (Entity e : I.world.entities_with(ct)) {
        const Camera* c = I.world.get<Camera>(e);
        if (!c || !c->primary || !c->renderTarget.empty() || !I.world.active_in_hierarchy(e)) continue;
        if (best == kNullEntity || c->depth < bestDepth) {
            best = e;
            bestDepth = c->depth;
        }
    }
    if (best == kNullEntity) return std::nullopt;
    const Camera& c = *I.world.get<Camera>(best);
    const Mat4 m = I.world.world_matrix(best);
    VfxBudgetCamera out;
    out.perspective = c.projection == Projection::Perspective;
    out.fovDegrees = std::clamp(double(c.fov), 1.0, 179.0);
    out.orthoHalfHeight = c.orthoSize > 0 ? double(c.orthoSize) : double(I.design_size().y) * 0.5;
    out.nearPlane = c.nearPlane;
    out.forward = normalize(m.transform_dir(kForward));
    out.right = normalize(m.transform_dir(Vec3{1, 0, 0}));
    out.up = normalize(m.transform_dir(Vec3{0, 1, 0}));
    return out;
}

std::string abs_path(const std::string& p) {
    if (fs::is_absolute(p)) return p;
    return fs::resolve(p).generic_string();
}

Json budget_json(const VfxBudget& b) {
    Json per = Json::array();
    for (const VfxEmitterBudget& e : b.perEmitter)
        per.push_back(Json::object({{"part", e.part}, {"name", e.name}, {"peakParticles", e.peakParticles}, {"peakAt", std::round(e.peakAt * 1000.0) / 1000.0},
                                    {"peakOverdraw", std::round(e.peakOverdraw * 100.0) / 100.0}, {"maxParticles", e.maxParticles}, {"capped", e.capped}}));
    Json line = Json::array();
    for (const VfxSample& s : b.timeline) line.push_back(Json::object({{"t", s.t}, {"particles", s.particles}, {"overdraw", s.overdraw}}));
    Json findings = Json::array();
    for (const VfxBudgetFinding& f : b.findings)
        findings.push_back(Json::object({{"kind", f.kind}, {"severity", f.severity}, {"pointer", f.pointer}, {"message", f.message}, {"hint", f.hint}, {"fix", f.fix}}));
    const VfxBudgetLimits& lim = vfx_budget_limits(b.preset);
    return Json::object({{"path", b.path},
                         {"preset", b.preset},
                         {"limits", Json::object({{"particles", lim.maxParticles}, {"overdraw", lim.maxOverdraw}, {"emitters", lim.maxEmitters}})},
                         {"duration", b.duration},
                         {"settledAt", std::round(b.settledAt * 1000.0) / 1000.0},
                         {"truncated", b.truncated},
                         {"emitters", b.emitters},
                         {"lights", b.lights},
                         {"peakParticles", b.peakParticles},
                         {"peakAt", std::round(b.peakAt * 1000.0) / 1000.0},
                         {"peakOverdraw", std::round(b.peakOverdraw * 100.0) / 100.0},
                         {"peakOverdrawAt", std::round(b.peakOverdrawAt * 1000.0) / 1000.0},
                         {"meanOverdraw", std::round(b.meanOverdraw * 100.0) / 100.0},
                         {"perEmitter", per},
                         {"timeline", line},
                         {"findings", findings},
                         {"notes", b.notes},
                         {"ok", b.findings.empty()}});
}

const char* kind_text(VfxPartKind k) {
    switch (k) {
        case VfxPartKind::Emitter: return "emitter";
        case VfxPartKind::Light: return "light";
        case VfxPartKind::Sound: return "sound";
        case VfxPartKind::Command: return "command";
    }
    return "emitter";
}

}  // namespace

void register_vfx_commands(Engine& engine, Engine::Impl& I) {
    // The effect system's two ways out. A sound is one play on the mixer (a clip that does not load answers voice 0); a command part
    // goes through the registry, so hooks and the command log see it, and a failure comes back as the message to log.
    I.vfxHost.play_sound = [&I](const std::string& clip, float volume, float pitch, const std::string& bus) {
        PlayParams pp;
        pp.volume = volume;
        pp.pitch = pitch;
        pp.bus = bus;
        return I.audio.play(clip, pp) != 0;
    };
    I.vfxHost.call = [&I](const std::string& command, const Json& args) -> std::string {
        // The parser refused every other name already; checked again here so no path to this function (a document built in code)
        // can run a command that writes files or changes settings.
        if (!vfx_command_allowed(command))
            return "an effect may not call '" + command + "' (allowed: " + join(vfx_allowed_commands(), ", ") + ")";
        if (!I.commands.has(command))
            return "there is no command '" + command + "'";
        const CommandResult r = I.commands.call(command, args);
        if (r.ok) return {};
        std::string why = r.error.is_object() ? r.error.value("message", std::string("failed")) : std::string("failed");
        if (r.error.is_object() && r.error.contains("hint") && r.error["hint"].is_string() && !r.error["hint"].get<std::string>().empty())
            why += " (" + r.error["hint"].get<std::string>() + ")";
        return why;
    };

    I.commands.add({"vfx.play", "Play an effect document (*.vfx.json) at a position, or on an entity.",
           "Makes an entity with a Vfx component (autoDestroy on) that plays the effect: its emitters and light flash become children "
           "of it, its sounds and commands (a camera shake, a hit-stop...) fire at their times. Without `entity` the effect is in "
           "world space at `position`; with `entity` it is that entity's child at the local `position`, so it follows it. The file is "
           "read and checked now: an invalid one is an error naming the JSON pointer. At most 64 effects play at once (an ended effect counts "
           "until its emitters' particles are gone): past that the "
           "call returns {\"id\": null, \"dropped\": true} (logged once). The effect advances with the game clock (game.step, "
           "time.scale), so the same calls at the same steps give the same result. Example: "
           "vfx.play {\"effect\":\"assets/vfx/hit.vfx.json\",\"position\":[120,64]}",
           parse_schema(R"({"type":"object","additionalProperties":false,"required":["effect"],"properties":{
               "effect":{"type":"string","description":"Project path of the effect document, e.g. \"assets/vfx/hit.vfx.json\" (docs/PARTICLES.md, \"Effect documents\")."},
               "position":{"type":"array","items":{"type":"number"},"description":"[x, y] or [x, y, z]: world position, or relative to `entity` when that is given. Default [0, 0]."},
               "entity":{"type":"string","description":"Entity (id or name) the effect follows: it becomes the effect's parent."},
               "rotation":{"type":"number","description":"Degrees around z (2D). Default 0."},
               "scale":{"type":"number","minimum":0.001,"maximum":1000,"default":1,"description":"Makes the whole effect that many times larger: positions and offsets, the emission shape, how fast and how far particles fly (start speed, gravity, turbulence), the size of particles and trails and the light radius. Times (lifetimes, the timeline) stay as written, and a command part (feel.shake, ...) calls its command with the arguments written in the file. A sub-emitter given as a prefab or an entity keeps its own size. 1 = as written."},
               "speed":{"type":"number","minimum":0.05,"maximum":20,"default":1,"description":"Speed of the timeline: 2 plays the parts' times twice as fast. The particles keep their own speed."},
               "loop":{"type":"boolean","default":false,"description":"Start again at the end until vfx.stop."}}})"),
           false, "game"},
          [&I](const Json& a) {
              VfxPlayOptions o;
              o.position = position_arg(a, "position");
              if (a.contains("entity") && !a["entity"].is_null()) o.parent = need_entity(I.world, a, "entity");
              if (a.contains("rotation")) {
                  const double r = a["rotation"].is_number() ? a["rotation"].get<double>() : std::nan("");
                  if (!std::isfinite(r) || std::fabs(r) > 1.0e6)
                      throw CommandError("invalid_argument", "`rotation` must be a number of degrees.", "Example: \"rotation\": 90.");
                  o.rotation = float(r);
              }
              o.scale = a.value("scale", 1.0f);
              o.speed = a.value("speed", 1.0f);
              o.loop = a.value("loop", false);
              const std::string effect = a.value("effect", std::string());
              auto r = vfx_play(I.world, effect, o);
              if (!r.ok()) throw CommandError("invalid_argument", "vfx.play: " + r.error().message, r.error().hint.empty() ? "vfx.check lists every problem of the file." : r.error().hint);
              if (r->is_null()) return Json::object({{"id", nullptr}, {"dropped", true}, {"playing", vfx_playing_count(I.world)}});
              auto doc = load_vfx(effect);  // cached by the call above
              return Json::object({{"id", I.world.id_of(*r)}, {"dropped", false}, {"duration", doc.ok() ? (*doc)->duration : 0.0}});
          });

    I.commands.add({"vfx.stop", "End an effect started by vfx.play (or a Vfx entity).",
           "`immediate` true removes the effect's entity and its children at once (particles vanish); the default lets the emitters "
           "stop emitting and their particles finish, ends the lights, and the parts that had not started never do. Example: "
           "vfx.stop {\"id\":\"vfx_hit_3\"}",
           parse_schema(R"({"type":"object","additionalProperties":false,"required":["id"],"properties":{
               "id":{"type":"string","description":"The entity (id or name) with the Vfx, as vfx.play returned it."},
               "immediate":{"type":"boolean","default":false,"description":"Remove it now instead of letting its particles finish."}}})"),
           false, "game"},
          [&I](const Json& a) {
              const Entity e = need_entity(I.world, a, "id");
              if (!I.world.get<Vfx>(e))
                  throw CommandError("invalid_argument", std::format("vfx.stop: '{}' has no Vfx component.", I.world.id_of(e)),
                                     "Pass the id vfx.play returned; vfx.list shows the effects that play.");
              vfx_stop(I.world, e, a.value("immediate", false));
              return Json::object({{"stopped", true}});
          });

    I.commands.add({"vfx.list", "The effects that play now, and the limits of an effect.",
           "Returns {playing: [{id, effect, time, duration, loop, speed}], count, max, limits}. `time` is seconds into the effect "
           "(the document's own clock), `duration` its length. An effect started by vfx.play counts at once, before the next step "
           "(time 0). Use it in a test to see that an effect started and ended: "
           "game.step, then vfx.list. Example: vfx.list {}.",
           parse_schema(R"({"type":"object","additionalProperties":false,"properties":{}})"), true, "game"},
          [&I](const Json&) {
              Json list = Json::array();
              for (Entity e : I.world.entities_with(&World::type_of<Vfx>())) {
                  const Vfx* v = I.world.get<Vfx>(e);
                  if (!v || !(v->playing || vfx_starts_next_step(*v))) continue;
                  double duration = double(v->duration);
                  if (duration <= 0.0 && !v->playing) {  // started this step: the document is not read by the system yet (load_vfx has it cached)
                      auto doc = load_vfx(v->effect);
                      if (doc.ok()) duration = (*doc)->duration;
                  }
                  list.push_back(Json::object({{"id", I.world.id_of(e)}, {"effect", v->effect}, {"time", std::round(double(v->time) * 1000.0) / 1000.0},
                                               {"duration", std::round(duration * 1000.0) / 1000.0}, {"loop", v->loop}, {"speed", v->speed}}));
              }
              Json limits = Json::object({{"parts", kVfxMaxParts}, {"emitters", kVfxMaxEmitters}, {"commands", kVfxMaxCommands},
                                          {"durationSeconds", kVfxMaxDuration}, {"allowedCommands", vfx_allowed_commands()}});
              return Json::object({{"playing", list}, {"count", list.size()}, {"max", kVfxMaxPlaying}, {"limits", limits}});
          });

    I.commands.add({"vfx.check", "Read an effect document (*.vfx.json) and list every problem, with its JSON pointer and the fix.",
           "Returns {ok, path, duration, parts: [{index, name, type, at, duration}], errors: [{pointer, message, hint}], warnings: [...]}. "
           "Errors stop the effect from playing; warnings (a `rate` with no duration, too many live particles) do not. A sound whose "
           "file is missing is an error. Example: vfx.check {\"path\":\"assets/vfx/hit.vfx.json\"}",
           parse_schema(R"({"type":"object","additionalProperties":false,"required":["path"],"properties":{
               "path":{"type":"string","description":"Project path of the effect document, e.g. \"assets/vfx/hit.vfx.json\"."}}})"),
           true, "game"},
          [](const Json& a) {
              const std::string path = a.value("path", std::string());
              std::vector<VfxIssue> issues;
              auto doc = load_vfx(path, &issues);
              Json out = Json::object({{"path", path}});
              if (doc.ok()) {
                  const auto missing = vfx_missing_assets(**doc, [](const std::string& p) { return fs::exists(p); });
                  issues.insert(issues.end(), missing.begin(), missing.end());
                  Json parts = Json::array();
                  for (std::size_t i = 0; i < (*doc)->parts.size(); ++i) {
                      const VfxPart& p = (*doc)->parts[i];
                      parts.push_back(Json::object({{"index", i}, {"name", p.name}, {"type", kind_text(p.kind)}, {"at", p.at}, {"duration", p.duration}}));
                  }
                  out["duration"] = (*doc)->duration;
                  out["parts"] = parts;
              } else if (issues.empty()) {
                  issues.push_back({true, "", doc.error().message, doc.error().hint});  // unreadable file, or not JSON
              }
              Json errors = issues_json(issues, true);
              out["ok"] = errors.empty();
              out["errors"] = errors;
              out["warnings"] = issues_json(issues, false);
              return out;
          });

    I.commands.add({"vfx.budget", "What an effect document costs on a phone: live particles and the screen they cover, with the fixes.",
           "Plays the document in a scratch world with the same timeline and particle sim a game runs (no "
           "renderer, no sound, the game is not touched, the same document and seed always give the same "
           "numbers) and returns {peakParticles, peakAt, peakOverdraw, peakOverdrawAt, meanOverdraw, "
           "settledAt, perEmitter: [{part, name, peakParticles, peakAt, peakOverdraw, maxParticles, "
           "capped}], timeline: [{t, particles, overdraw}], findings: [{kind, pointer, message, hint, fix: "
           "{command, args}}], notes, limits, ok}. `overdraw` is the sum of the particles' quads in screens "
           "(1.0 = as much quad area as the view has; stacked soft sprites are what a phone's GPU pays for). "
           "`findings` are what is over the `preset`'s budget (phone: 300 live particles, 1.5 screens, 5 "
           "emitters; desktop: 2000, 4.0, 8): each names the JSON pointer and, when one edit helps, carries "
           "a vfx.edit call (`fix`) that moves the effect toward it (run vfx.budget again to see where it "
           "lands; `fix` is null when no single edit would do). With 3D emitters the numbers also depend on "
           "that camera (its lens, and the scene that is loaded), so the same document can give other "
           "numbers in another scene. Example: vfx.budget {\"path\":\"assets/vfx/hit.vfx.json\"}"
           FA_COMMAND_DETAILS
           "The numbers are the particles the sim keeps alive: a camera that does not see them, ribbon "
           "trails and glow passes are not counted. A 3D emitter's size is in world units, so its overdraw "
           "is measured through the project's main camera (the active primary Camera with the lowest depth "
           "in the loaded scene): its quads are projected with the effect 5 m in front of the camera, on its "
           "axis (a perspective or an orthographic camera; a quad partly outside the view counts whole). "
           "`camera` in the result says which was used ({used:true, projection, distance, fov | height}); "
           "when there is no camera (no scene loaded, or none in it) a 3D emitter's particles are counted "
           "but its overdraw is 0 and not measured, and `camera` is {used:false, reason} and `notes` says so.",
           parse_schema(R"({"type":"object","additionalProperties":false,"required":["path"],"properties":{
               "path":{"type":"string","description":"Project path of the effect document, e.g. \"assets/vfx/hit.vfx.json\"."},
               "preset":{"type":"string","enum":["phone","desktop"],"default":"phone","description":"Whose budget the findings use."},
               "seed":{"type":"integer","minimum":0,"maximum":4294967295,"default":1,"description":"Seed of the particle sim: a different seed is a different (equally valid) roll of the random spread."},
               "view":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"[width, height] of the view in design pixels that overdraw is measured against. Default: the project's design size."}}})"),
           true, "game"},
          [&I](const Json& a) {
              const std::string path = a.value("path", std::string());
              const std::string preset = a.value("preset", std::string("phone"));
              if (preset != "phone" && preset != "desktop")
                  throw CommandError("invalid_argument", std::format("preset '{}' is not known.", preset), "Use \"phone\" or \"desktop\".");
              std::vector<VfxIssue> issues;
              auto doc = load_vfx(path, &issues);
              if (!doc.ok()) throw CommandError("invalid_argument", "vfx.budget: " + doc.error().message, doc.error().hint.empty() ? "vfx.check lists every problem of the file." : doc.error().hint);
              VfxBudgetOptions o;
              o.preset = preset;
              const double seed = a.contains("seed") && a["seed"].is_number() ? a["seed"].get<double>() : 1.0;
              if (!(seed >= 0 && seed <= 4294967295.0)) throw CommandError("invalid_argument", "`seed` must be an integer from 0 to 4294967295.", "Example: \"seed\": 7.");
              o.seed = std::uint32_t(seed);
              const Vec2 design = I.design_size();
              o.viewWidth = design.x;
              o.viewHeight = design.y;
              if (a.contains("view")) {
                  const Json& v = a["view"];
                  const bool ok = v.is_array() && v.size() == 2 && v[0].is_number() && v[1].is_number() && v[0].get<double>() >= 1 && v[1].get<double>() >= 1 &&
                                  v[0].get<double>() <= 16384 && v[1].get<double>() <= 16384;
                  if (!ok) throw CommandError("invalid_argument", std::format("`view` must be [width, height] from 1 to 16384, got {}.", describe_json_value(v)), "Example: \"view\": [1280, 720].");
                  o.viewWidth = v[0].get<double>();
                  o.viewHeight = v[1].get<double>();
              }
              // 3D emitters are projected through the project's main camera; the answer says what was used (or why nothing was).
              o.camera = main_camera(I);
              const VfxBudget measured = vfx_measure(**doc, o);
              Json out = budget_json(measured);
              bool any3d = false;
              for (const VfxPart& part : (*doc)->parts) {
                  if (part.kind != VfxPartKind::Emitter) continue;
                  ParticleEmitter pe;
                  (void)object_patch_from_json(World::type_of<ParticleEmitter>(), &pe, part.emitter);
                  any3d = any3d || pe.is3D;
              }
              Json camera = Json::object({{"used", measured.camera3d}});
              if (measured.camera3d) {
                  camera["projection"] = o.camera->perspective ? "perspective" : "orthographic";
                  camera["distance"] = o.cameraDistance;
                  if (o.camera->perspective) camera["fov"] = o.camera->fovDegrees;
                  else camera["height"] = o.camera->orthoHalfHeight * 2.0;
              } else if (any3d) {
                  camera["reason"] = "no active primary Camera in the loaded scene to project the 3D emitters' quads through";
              } else {
                  camera["reason"] = "the effect has no 3D emitter, so no camera was needed";
              }
              out["camera"] = camera;
              return out;
          });

    I.commands.add({"vfx.filmstrip", "Film an effect playing in the game: one picture with a grid of frames, to see its timing and look at once.",
           "Plays the effect at `position` (default: in a 2D game the world point in the middle of the view; "
           "in a 3D game the point 5 m in front of the main 3D camera, on its axis, which the result says in "
           "`positionNote`), steps the game and captures `region` at each step into one labelled grid PNG "
           "(label \"f3 +100\" = picture 3, 100 ms after the effect started), then removes the effect. THE "
           "GAME ADVANCES: the clock, the physics and the scripts run for the frames the strip takes (about "
           "3 s at most by default), so film on a stage scene or a paused moment; the camera and the "
           "backdrop are the ones the game has, which is what the effect must read against. The first "
           "picture is the frame after the effect started. By default the strip covers the effect's length "
           "(from vfx.budget, at most 3 s) in `frames` pictures; `everyFrames` sets the game frames between "
           "two pictures instead. The view is `size` design pixels around the effect, `region` [x, y, width, "
           "height] overrides it, and `zoom` magnifies (default: a sheet about 1600 px wide). At most 64 "
           "pictures, a sheet at most 8192 px a side. Needs graphics. Example: vfx.filmstrip "
           "{\"effect\":\"assets/vfx/hit.vfx.json\",\"position\":[640,360],\"frames\":12}"
           FA_COMMAND_DETAILS
           "Without `path` the picture is temporary (the MCP server shows it then deletes the file). The "
           "effect's sound and command parts really act on the game (a feel.hitStop stretches the labelled "
           "times, an audio.music keeps playing, a feel.spawn leaves its prefab). A `position` the camera "
           "cannot project into the view fails (it is behind the camera: aim the camera or give `region`). "
           "Result: {path (only with `path`), effect, duration, width, height, frames: [{index, frame, t}], "
           "columns, rows, tileWidth, tileHeight, zoom, everyFrames, region, position: [x, y, z] (where it "
           "played), positionDefault (true when `position` was left out), positionNote (only then: which "
           "default was used), $image}. vfx.review gives the picture to a vision model with the budget "
           "numbers.",
           parse_schema(R"({"type":"object","additionalProperties":false,"required":["effect"],"properties":{
               "effect":{"type":"string","description":"Project path of the effect document, e.g. \"assets/vfx/hit.vfx.json\"."},
               "position":{"type":"array","items":{"type":"number"},"description":"[x, y] or [x, y, z]: where the effect plays, in world units. Default: the world point in the middle of the view in a 2D game; in a 3D game the point 5 m in front of the main camera on its axis (the result says which in `positionNote`)."},
               "frames":{"type":"integer","minimum":2,"maximum":64,"default":12,"description":"Pictures in the strip."},
               "everyFrames":{"type":"integer","minimum":1,"maximum":600,"description":"Game frames between two pictures. Default: the effect's length (at most 3 s) divided over `frames`."},
               "size":{"type":"number","minimum":16,"maximum":4096,"default":256,"description":"Side, in design pixels, of the square around the effect that is filmed (ignored with `region`)."},
               "region":{"type":"array","items":{"type":"number"},"minItems":4,"maxItems":4,"description":"[x, y, width, height] in design pixels (origin top-left of the view)."},
               "zoom":{"type":"number","minimum":0.25,"maximum":32,"description":"Magnification of the region (default: a sheet about 1600 px wide)."},
               "columns":{"type":"integer","minimum":1,"maximum":64,"description":"Pictures per row (default: nearly square)."},
               "path":{"type":"string","description":"Keep the PNG here (project-relative or absolute)."}}})"),
           false, "game"},
          [&engine, &I](const Json& a) {
              const std::string effect = a.value("effect", std::string());
              if (!I.renderer || !I.renderer->initialized())
                  throw CommandError("unavailable", "No renderer: the engine runs with graphics=false.", "vfx.filmstrip needs graphics (headless needs Mesa/EGL). vfx.budget and vfx.check work without.");
              auto doc = load_vfx(effect);
              if (!doc.ok()) throw CommandError("invalid_argument", "vfx.filmstrip: " + doc.error().message, doc.error().hint.empty() ? "vfx.check lists every problem of the file." : doc.error().hint);
              const int count = a.value("frames", 12);
              if (count < 2 || count > kMaxFilmstripTiles)
                  throw CommandError("invalid_argument", std::format("frames {} is out of range (2 to {}).", count, kMaxFilmstripTiles), "Use 8 to 16 pictures for one effect.");
              const double hz = 1.0 / std::max(1e-6, engine.fixed_dt());
              double length = 0.0;
              int every = a.value("everyFrames", 0);
              if (every < 0 || every > 600) throw CommandError("invalid_argument", std::format("everyFrames {} is out of range (1 to 600).", every), "It is the number of game frames between two pictures.");
              if (every == 0) {
                  // The length on screen: the document's own length, or until its last particle dies, whichever is longer (the same numbers vfx.budget reports).
                  VfxBudgetOptions mo;
                  const Vec2 d = I.design_size();
                  mo.viewWidth = d.x;
                  mo.viewHeight = d.y;
                  const VfxBudget measured = vfx_measure(**doc, mo);
                  length = std::clamp(std::max((*doc)->duration, measured.settledAt), 0.1, kMaxFilmSpan);
                  every = std::max(1, int(std::lround(length * hz / (count - 1))));
              }

              const Vec2 view{float(I.renderer->target_width()), float(I.renderer->target_height())};
              Vec3 at{0, 0, 0};
              if (a.contains("position") && !a["position"].is_null()) at = position_arg(a, "position");
              else at = I.renderer->screen_to_world(Vec2{view.x * 0.5f, view.y * 0.5f});
              const bool given = a.contains("position") && !a["position"].is_null();
              if (!std::isfinite(at.x) || !std::isfinite(at.y) || !std::isfinite(at.z)) {
                  throw CommandError("invalid_argument", "vfx.filmstrip: the middle of the view is not a point of this world, so there is no place to play the effect at.",
                                     "Give `position` [x, y, z].");
              }
              std::string positionNote;
              if (!given) {
                  // In a 2D game the middle of the view is a point on the z = 0 plane. With a 3D perspective camera screen_to_world(depth 0) is the
                  // camera itself, where nothing can be filmed: play the effect a few metres in front of the lens instead, on the view axis.
                  Vec3 origin{}, dir{};
                  I.renderer->screen_ray(Vec2{view.x * 0.5f, view.y * 0.5f}, origin, dir);
                  const Vec3 gap = at - origin;
                  if (gap.x * gap.x + gap.y * gap.y + gap.z * gap.z < 1e-6f) {
                      at = origin + dir * float(kVfxDefaultCameraDistance);
                      positionNote = std::format("No `position` was given and this game has a 3D camera: the effect played at the point {:g} m in front of it, on its view axis "
                                                 "([{:.3f}, {:.3f}, {:.3f}]). Give `position` to film it somewhere else.", kVfxDefaultCameraDistance, at.x, at.y, at.z);
                  } else {
                      positionNote = std::format("No `position` was given: the effect played at the world point in the middle of the view ([{:.3f}, {:.3f}, {:.3f}]).", at.x, at.y, at.z);
                  }
              }
              Rect region{};
              if (a.contains("region")) {
                  std::string err;
                  if (!json_to(a["region"], region, &err)) throw CommandError("invalid_argument", "region: " + err, "Use [x, y, width, height] in design pixels.");
                  if (!(region.w > 0 && region.h > 0)) throw CommandError("invalid_argument", "region has no area.", "Width and height must be above 0.");
              } else {
                  const Vec2 s = I.renderer->world_to_screen(at);
                  if (!std::isfinite(s.x) || !std::isfinite(s.y))
                      throw CommandError("invalid_argument", "vfx.filmstrip: `position` does not project to a point of the view (it is behind the camera, or the camera cannot see it).",
                                         "Aim the camera at the effect, or give `region` [x, y, width, height] in design pixels to film that part of the view.");
                  const float side = a.value("size", 256.0f);
                  const float x0 = std::clamp(s.x - side * 0.5f, 0.0f, std::max(0.0f, view.x - 1.0f));
                  const float y0 = std::clamp(s.y - side * 0.5f, 0.0f, std::max(0.0f, view.y - 1.0f));
                  region = Rect{x0, y0, std::max(1.0f, std::min(side, view.x - x0)), std::max(1.0f, std::min(side, view.y - y0))};
              }
              const int wanted = a.value("columns", 0);
              const auto at1 = Engine::plan_region(view, region, 1.0);
              if (!at1.error.empty()) throw CommandError("invalid_argument", at1.error, "See the `region` argument of game.screenshot.");
              double zoom = 1.0;
              if (a.contains("zoom")) zoom = a.value("zoom", 1.0);
              else zoom = std::clamp(kAutoSheetWidth / std::max(1, sheet_layout(count, wanted, at1.width, at1.height).width), 0.25, 4.0);
              const auto plan = Engine::plan_region(view, region, zoom);
              if (!plan.error.empty()) throw CommandError("invalid_argument", plan.error, "See the `region` and `zoom` arguments.");
              const SheetLayout predicted = sheet_layout(count, wanted, plan.width, plan.height);
              if (predicted.width > kMaxSheetSide || predicted.height > kMaxSheetSide)
                  throw CommandError("invalid_argument", std::format("The sheet would be {}x{} px, over the 8192 px limit per side.", predicted.width, predicted.height),
                                     "Use a smaller zoom, region or size, more columns, or fewer frames.");

              VfxPlayOptions po;
              po.position = at;
              auto played = vfx_play(I.world, effect, po);
              if (!played.ok()) throw CommandError("invalid_argument", "vfx.filmstrip: " + played.error().message, played.error().hint.empty() ? "vfx.check lists every problem of the file." : played.error().hint);
              if (played->is_null())
                  throw CommandError("unavailable", "vfx.filmstrip: the game already plays the most effects it allows.", "Wait for them to end (vfx.list) or vfx.stop some.");
              const Entity fx = *played;
              const std::uint64_t startFrame = I.frame;
              std::vector<Image> shots;
              std::vector<std::string> labels;
              Json frames = Json::array();
              std::string err;
              bool failed = false;
              engine.step(1);  // the effect starts at the next fixed step
              for (int i = 0; i < count && !failed; ++i) {
                  if (i > 0) engine.step(every);
                  Image tile;
                  if (!engine.capture_region(tile, region, zoom, &err)) {
                      failed = true;
                      break;
                  }
                  const int offset = static_cast<int>(I.frame - startFrame);
                  const double seconds = double(offset) / hz;
                  labels.push_back("f" + std::to_string(i) + " +" + std::to_string(int(std::lround(seconds * 1000.0))));
                  frames.push_back(Json::object({{"index", i}, {"frame", I.frame}, {"t", std::round(seconds * 1000.0) / 1000.0}}));
                  shots.push_back(std::move(tile));
              }
              // Whatever happened, the effect does not stay in the game: a script may have ended it, or the scene may have changed
              // while the game stepped, so check that the entity is still the effect before removing it.
              if (I.world.alive(fx) && I.world.get<Vfx>(fx)) {
                  vfx_stop(I.world, fx, true);
                  if (!I.inFrame) I.world.flush();  // inside a frame (a script called this) the frame applies the destroy
              }
              if (failed) throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");

              SheetLayout l;
              Image img = contact_sheet(shots, labels, wanted, -1, &l);
              const bool temporary = !(a.contains("path") && a["path"].is_string() && !a["path"].get<std::string>().empty());
              const std::string path = temporary ? ".factoria/screenshots/frame_" + std::to_string(I.frame) + "_vfx.png" : a["path"].get<std::string>();
              auto saved = save_png(img, path);
              if (!saved.ok()) throw CommandError("unavailable", saved.error().message, saved.error().hint.empty() ? "Check the path is inside a writable folder." : saved.error().hint);
              const std::string abs = abs_path(path);
              Json j = Json::object();
              if (!temporary) j["path"] = abs;
              j["effect"] = effect;
              j["duration"] = (*doc)->duration;
              j["width"] = img.width;
              j["height"] = img.height;
              j["frames"] = frames;
              j["columns"] = l.columns;
              j["rows"] = l.rows;
              j["tileWidth"] = l.tileWidth;
              j["tileHeight"] = l.tileHeight;
              j["zoom"] = zoom;
              j["everyFrames"] = every;
              j["region"] = Json::array({plan.x0, plan.y0, plan.x1 - plan.x0, plan.y1 - plan.y0});
              j["position"] = Json::array({at.x, at.y, at.z});
              j["positionDefault"] = !given;
              if (!given) j["positionNote"] = positionNote;
              Json image = Json::object({{"path", abs}, {"mimeType", "image/png"}});
              if (temporary) {
                  j["temporary"] = true;
                  j["note"] = "Temporary picture: whoever shows it deletes the file. Pass `path` to keep it.";
                  image["temporary"] = true;
              }
              j["$image"] = image;
              return j;
          });
}

}  // namespace fa
