// The commands of the effect documents (`*.vfx.json`, docs/PARTICLES.md "Effect documents"): vfx.play and vfx.stop run an effect,
// vfx.check reads one and lists every problem, vfx.list says which effects play. The effect itself is fa/scene/vfx.h.
#include <cmath>
#include <format>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/vfx.h"

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

void register_vfx_commands(Engine&, Engine::Impl& I) {
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
           "read and checked now: an invalid one is an error naming the JSON pointer. At most 64 effects play at once: past that the "
           "call returns {\"id\": null, \"dropped\": true} (logged once). The effect advances with the game clock (game.step, "
           "time.scale), so the same calls at the same steps give the same result. Example: "
           "vfx.play {\"effect\":\"assets/vfx/hit.vfx.json\",\"position\":[120,64]}",
           parse_schema(R"({"type":"object","additionalProperties":false,"required":["effect"],"properties":{
               "effect":{"type":"string","description":"Project path of the effect document, e.g. \"assets/vfx/hit.vfx.json\" (docs/PARTICLES.md, \"Effect documents\")."},
               "position":{"type":"array","items":{"type":"number"},"description":"[x, y] or [x, y, z]: world position, or relative to `entity` when that is given. Default [0, 0]."},
               "entity":{"type":"string","description":"Entity (id or name) the effect follows: it becomes the effect's parent."},
               "rotation":{"type":"number","description":"Degrees around z (2D). Default 0."},
               "scale":{"type":"number","minimum":0.001,"maximum":1000,"default":1,"description":"Scale of the effect's entity: the offsets of its parts and the spawn shape of its emitters grow with it; the sizes written in the file (particle size, light radius) do not. 1 = as written."},
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
           "(the document's own clock), `duration` its length. Use it in a test to see that an effect started and ended: "
           "game.step, then vfx.list. Example: vfx.list {}.",
           parse_schema(R"({"type":"object","additionalProperties":false,"properties":{}})"), true, "game"},
          [&I](const Json&) {
              Json list = Json::array();
              for (Entity e : I.world.entities_with(&World::type_of<Vfx>())) {
                  const Vfx* v = I.world.get<Vfx>(e);
                  if (!v || !v->playing) continue;
                  list.push_back(Json::object({{"id", I.world.id_of(e)}, {"effect", v->effect}, {"time", std::round(double(v->time) * 1000.0) / 1000.0},
                                               {"duration", std::round(double(v->duration) * 1000.0) / 1000.0}, {"loop", v->loop}, {"speed", v->speed}}));
              }
              Json limits = Json::object({{"parts", kVfxMaxParts}, {"emitters", kVfxMaxEmitters}, {"commands", kVfxMaxCommands},
                                          {"durationSeconds", kVfxMaxDuration}, {"commandPrefixes", vfx_command_prefixes()}});
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
}

}  // namespace fa
