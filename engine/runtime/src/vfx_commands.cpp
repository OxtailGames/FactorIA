// The commands that play effect documents (`*.vfx.json`, docs/PARTICLES.md "Effect documents"): vfx.play and vfx.stop run an effect
// and vfx.list says which effects play. They are the game's API (`vfx` in "factoria"), so the player has them; the tools that check
// and measure a document (vfx.check, vfx.budget, vfx.filmstrip) are in tools/authoring/src/vfx_review_commands.cpp. This file also
// fills Impl::vfxHost, which update_vfx uses every frame to play an effect's sounds and call its commands, so it must run in every
// Engine. The effect itself is fa/scene/vfx.h.
#include <cmath>
#include <format>

#include "engine_impl.h"
#include "fa/core/strings.h"
#include "fa/scene/vfx.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

}  // namespace

// [x, y] or [x, y, z]: finite numbers, kept inside +-1e9 so a typo cannot throw an effect out of float range. Also used by
// vfx.filmstrip (tools/authoring), declared in engine_impl.h.
Vec3 vfx_position_arg(const Json& a, const char* key) {
    Vec3 out{0, 0, 0};
    if (!a.contains(key) || a[key].is_null()) return out;
    const Json& v = a[key];
    bool ok = v.is_array() && (v.size() == 2 || v.size() == 3);
    if (ok)
        for (const Json& c : v)
            ok = ok && c.is_number() && std::isfinite(c.get<double>()) && std::fabs(c.get<double>()) <= 1.0e9;
    if (!ok)
        throw CommandError(
            "invalid_argument",
            std::format("`{}` must be [x, y] or [x, y, z] (finite numbers), got {}.", key, describe_json_value(v)),
            "Example: \"position\": [120, 64].");
    return {v[0].get<float>(), v[1].get<float>(), v.size() == 3 ? v[2].get<float>() : 0.0f};
}

void register_vfx_commands(Engine& /*engine*/, Engine::Impl& I) {
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
        if (!I.commands.has(command)) return "there is no command '" + command + "'";
        const CommandResult r = I.commands.call(command, args);
        if (r.ok) return {};
        std::string why = r.error.is_object() ? r.error.value("message", std::string("failed")) : std::string("failed");
        if (r.error.is_object() && r.error.contains("hint") && r.error["hint"].is_string() &&
            !r.error["hint"].get<std::string>().empty())
            why += " (" + r.error["hint"].get<std::string>() + ")";
        return why;
    };

    I.commands.add(
        {"vfx.play", "Play an effect document (*.vfx.json) at a position, or on an entity.",
         "Makes an entity with a Vfx component (autoDestroy on) that plays the effect: its emitters and light flash "
         "become children "
         "of it, its sounds and commands (a camera shake, a hit-stop...) fire at their times. Without `entity` the "
         "effect is in "
         "world space at `position`; with `entity` it is that entity's child at the local `position`, so it follows "
         "it. The file is "
         "read and checked now: an invalid one is an error naming the JSON pointer. At most 64 effects play at once "
         "(an ended effect counts "
         "until its emitters' particles are gone): past that the "
         "call returns {\"id\": null, \"dropped\": true} (logged once). The effect advances with the game clock "
         "(game.step, "
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
            o.position = vfx_position_arg(a, "position");
            if (a.contains("entity") && !a["entity"].is_null()) o.parent = need_entity(I.world, a, "entity");
            if (a.contains("rotation")) {
                const double r = a["rotation"].is_number() ? a["rotation"].get<double>() : std::nan("");
                if (!std::isfinite(r) || std::fabs(r) > 1.0e6)
                    throw CommandError("invalid_argument", "`rotation` must be a number of degrees.",
                                       "Example: \"rotation\": 90.");
                o.rotation = float(r);
            }
            o.scale = a.value("scale", 1.0f);
            o.speed = a.value("speed", 1.0f);
            o.loop = a.value("loop", false);
            const std::string effect = a.value("effect", std::string());
            auto r = vfx_play(I.world, effect, o);
            if (!r.ok())
                throw CommandError("invalid_argument", "vfx.play: " + r.error().message,
                                   r.error().hint.empty() ? "vfx.check (CLI, editor) lists every problem of the file."
                                                          : r.error().hint);
            if (r->is_null())
                return Json::object({{"id", nullptr}, {"dropped", true}, {"playing", vfx_playing_count(I.world)}});
            auto doc = load_vfx(effect);  // cached by the call above
            return Json::object(
                {{"id", I.world.id_of(*r)}, {"dropped", false}, {"duration", doc.ok() ? (*doc)->duration : 0.0}});
        });

    I.commands.add({"vfx.stop", "End an effect started by vfx.play (or a Vfx entity).",
                    "`immediate` true removes the effect's entity and its children at once (particles vanish); the "
                    "default lets the emitters "
                    "stop emitting and their particles finish, ends the lights, and the parts that had not started "
                    "never do. Example: "
                    "vfx.stop {\"id\":\"vfx_hit_3\"}",
                    parse_schema(R"({"type":"object","additionalProperties":false,"required":["id"],"properties":{
               "id":{"type":"string","description":"The entity (id or name) with the Vfx, as vfx.play returned it."},
               "immediate":{"type":"boolean","default":false,"description":"Remove it now instead of letting its particles finish."}}})"),
                    false, "game"},
                   [&I](const Json& a) {
                       const Entity e = need_entity(I.world, a, "id");
                       if (!I.world.get<Vfx>(e))
                           throw CommandError("invalid_argument",
                                              std::format("vfx.stop: '{}' has no Vfx component.", I.world.id_of(e)),
                                              "Pass the id vfx.play returned; vfx.list shows the effects that play.");
                       vfx_stop(I.world, e, a.value("immediate", false));
                       return Json::object({{"stopped", true}});
                   });

    I.commands.add(
        {"vfx.list", "The effects that play now, and the limits of an effect.",
         "Returns {playing: [{id, effect, time, duration, loop, speed}], count, max, limits}. `time` is seconds into "
         "the effect "
         "(the document's own clock), `duration` its length. An effect started by vfx.play counts at once, before the "
         "next step "
         "(time 0). Use it in a test to see that an effect started and ended: "
         "game.step, then vfx.list. Example: vfx.list {}.",
         parse_schema(R"({"type":"object","additionalProperties":false,"properties":{}})"), true, "game"},
        [&I](const Json&) {
            Json list = Json::array();
            I.world.each<Vfx>([&](Entity e, Vfx& vfx) {
                const Vfx* v = &vfx;
                if (!(v->playing || vfx_starts_next_step(*v))) return;
                double duration = double(v->duration);
                if (duration <= 0.0 &&
                    !v->playing) {  // started this step: the document is not read by the system yet (load_vfx has it cached)
                    auto doc = load_vfx(v->effect);
                    if (doc.ok()) duration = (*doc)->duration;
                }
                list.push_back(Json::object({{"id", I.world.id_of(e)},
                                             {"effect", v->effect},
                                             {"time", std::round(double(v->time) * 1000.0) / 1000.0},
                                             {"duration", std::round(duration * 1000.0) / 1000.0},
                                             {"loop", v->loop},
                                             {"speed", v->speed}}));
            });
            Json limits = Json::object({{"parts", kVfxMaxParts},
                                        {"emitters", kVfxMaxEmitters},
                                        {"commands", kVfxMaxCommands},
                                        {"durationSeconds", kVfxMaxDuration},
                                        {"allowedCommands", vfx_allowed_commands()}});
            return Json::object(
                {{"playing", list}, {"count", list.size()}, {"max", kVfxMaxPlaying}, {"limits", limits}});
        });

    // Capabilities (capability.h): what each command does outside the engine's memory.
    declare_command_capabilities(I.commands, {
                                                 {"vfx.play", capability_sets::changes_state()},
                                                 {"vfx.stop", capability_sets::changes_state()},
                                                 {"vfx.list", capability_sets::reads()},
                                             });
}

}  // namespace fa
