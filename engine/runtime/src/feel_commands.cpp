// The game feel commands (M62.1): feel.shake, feel.hitStop, feel.flash, feel.knockback, feel.squash start one effect, feel.cancel
// ends them, feel.settings sets the accessibility choices and feel.state shows what is running. They are the same effects as
// camera.shake, time.hitStop, entity.flash / knockback / squash in a script (fa/scene/feel.h): one implementation, so a tool or a
// test sees exactly what the game does. Each command's arguments are the fields of that action (the `feel` action JSON a clip
// event carries), plus `entity` for the target.
#include <format>

#include "engine_impl.h"
#include "fa/scene/feel.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

// Runs `action` with the arguments of the command: `entity` is the target, every other key an option of the action.
Json run_action(Engine::Impl& I, const Json& a, const char* action, const char* command, bool entityRequired) {
    Entity target = kNullEntity;
    if (a.contains("entity") && !a["entity"].is_null()) target = need_entity(I.world, a, "entity");
    else if (entityRequired)
        throw CommandError("invalid_argument", std::format("{} needs `entity`.", command),
                           "Pass the id or name of the entity: scene.list shows them.");
    Json act = a;
    act.erase("entity");
    act["action"] = action;
    auto r = feel_apply_action(I.world, target, act);
    if (!r.ok()) throw CommandError("invalid_argument", std::format("{}: {}", command, r.error().message), r.error().hint);
    const FeelState& fs = I.world.feel();
    Json out = Json::object({{"ok", true}, {"action", action}});
    out["hitStopRemaining"] = fs.hit_stop_remaining();
    out["reduceMotion"] = fs.reduce_motion();
    out["reducedEffects"] = fs.reduced_effects();
    return out;
}

}  // namespace

void register_feel_commands(Engine&, Engine::Impl& I) {
    I.commands.add({"feel.shake", "Camera shake: adds trauma to a camera (2D and 3D); it stacks up to `cap` and dies out over `duration`.",
           "The same as `camera.shake(amount, opts)` in a script. Adds `amount` (0..1) of trauma; the shake is trauma squared, smooth "
           "noise seeded from the world's RNG (deterministic), and only what is DRAWN moves: the camera's Transform does not change. "
           "A 2D camera moves in x, y and roll, a 3D one also looks a little around. With the player's reduceMotion on (feel.settings, "
           "else the system's) the amount is a quarter. Example: feel.shake {\"amount\":0.5,\"duration\":0.3}",
           parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"The camera (id or name). Default: the first camera drawn (camera.main)."},
               "amount":{"type":"number","minimum":0,"maximum":1,"default":0.4,"description":"Trauma to add, 0..1."},
               "duration":{"type":"number","minimum":0.01,"maximum":30,"default":0.4,"description":"Seconds the shake takes to die out (a longer one already running is kept)."},
               "frequency":{"type":"number","minimum":0.1,"maximum":200,"default":25,"description":"Noise samples per second: how jittery."},
               "maxOffset":{"type":"number","minimum":0,"description":"Largest offset at trauma 1, world units. Default: 2.5% of an orthographic camera's visible height, 0.3 for a perspective one."},
               "maxAngle":{"type":"number","minimum":0,"maximum":45,"default":2,"description":"Largest turn at trauma 1, degrees."},
               "cap":{"type":"number","minimum":0,"maximum":1,"default":1,"description":"Trauma never goes above this: stacked hits stop here."}}})"),
           false, "feel"},
          [&I](const Json& a) { return run_action(I, a, "shake", "feel.shake", false); });

    I.commands.add({"feel.hitStop", "Hit-stop: freezes or slows gameplay for a moment of real time; UI, audio and the stop's own timer keep going.",
           "The same as `time.hitStop(seconds, opts)`. Physics, onUpdate/onFixedUpdate, timers, particles and sprite animators stop (or "
           "slow to `scale`); the UI, audio, runWhilePaused behaviours, shake, flashes and squash keep running; `time.scale` and "
           "`game.paused` do not change. Overlapping calls do not add up: the longest wins and the smallest scale applies while they "
           "overlap. With reduceMotion on the duration is halved. The timer is REAL time: `game.step` frames count their fixed step. "
           "Example: feel.hitStop {\"duration\":0.08}",
           parse_schema(R"({"type":"object","properties":{
               "duration":{"type":"number","minimum":0,"maximum":5,"default":0.08,"description":"Real seconds."},
               "scale":{"type":"number","minimum":0,"maximum":1,"default":0,"description":"Game-time scale during the stop: 0 freezes, 0.2 is slow motion."}}})"),
           false, "feel"},
          [&I](const Json& a) { return run_action(I, a, "hitStop", "feel.hitStop", false); });

    I.commands.add({"feel.flash", "Draws an entity in one colour for a moment (a hit flash): sprites, shapes and 3D meshes, fading or square.",
           "The same as `entity.flash(opts)`. The entity's own colour, material and Transform never change. Children are flashed with "
           "it. Text, Tilemap, particles and UI are not flashed. With the player's reducedEffects on (feel.settings, else the system's "
           "reduce motion) the strength is capped at 0.35 and the flash always fades, never a full-bright strobe. Example: "
           "feel.flash {\"entity\":\"enemy\",\"color\":\"#ffffff\",\"duration\":0.1}",
           parse_schema(R"({"type":"object","required":["entity"],"properties":{
               "entity":{"type":"string","description":"The entity (id or name)."},
               "color":{"description":"The colour: \"#rrggbb\", a name or [r, g, b, a] in 0..1. Default white. Alpha is ignored."},
               "duration":{"type":"number","minimum":0.01,"maximum":30,"default":0.12,"description":"Seconds."},
               "fade":{"type":"boolean","default":true,"description":"true: from `strength` down to 0; false: `strength` for the whole duration, then off."},
               "strength":{"type":"number","minimum":0,"maximum":1,"default":1,"description":"How much of the colour replaces the entity's own (1 = solid)."}}})"),
           false, "feel"},
          [&I](const Json& a) { return run_action(I, a, "flash", "feel.flash", true); });

    I.commands.add({"feel.knockback", "Pushes an entity away and holds `isKnockedBack` for a moment: an impulse on its physics body, else a decaying velocity.",
           "The same as `entity.knockback(direction, opts)`. A dynamic RigidBody2D/RigidBody3D gets `speed` added to its velocity; an "
           "entity without one moves with a velocity that decays by exp(-decay * dt) on the fixed clock. For `lockTime` seconds "
           "`entity.isKnockedBack` is true: the movement script leaves the player without control. A hit-stop freezes it. Example: "
           "feel.knockback {\"entity\":\"player\",\"direction\":[-1,0.3],\"speed\":8}",
           parse_schema(R"({"type":"object","required":["entity"],"properties":{
               "entity":{"type":"string","description":"The entity (id or name)."},
               "direction":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":3,"default":[1,0],"description":"Which way, [x, y] or [x, y, z]; any length, it is normalised."},
               "speed":{"type":"number","minimum":0,"description":"World units per second added at once. Default: 6 metres per second, which is 6 units for a 3D entity and 6 times physics.pixelsPerMeter (600 pixels per second at 100) for a 2D one."},
               "lockTime":{"type":"number","minimum":0,"maximum":30,"default":0.25,"description":"Seconds isKnockedBack stays true."},
               "decay":{"type":"number","minimum":0,"maximum":1000,"default":8,"description":"Entities without a dynamic body: the velocity falls by exp(-decay * dt) per second."},
               "local":{"type":"boolean","default":false,"description":"true: `direction` is in the entity's own space (a mirrored sprite is pushed the other way)."}}})"),
           false, "feel"},
          [&I](const Json& a) { return run_action(I, a, "knockback", "feel.knockback", true); });

    I.commands.add({"feel.squash", "Squash and stretch: a short scale pulse that keeps the volume and springs back to exactly the entity's scale.",
           "The same as `entity.squash(opts)`. The pulse is drawn on top of the entity's own scale (volume kept: x * y in 2D, x * y * z "
           "with a mesh); `entity.scale` is never written, so nothing is left behind. amount > 0 squashes, < 0 stretches. With "
           "reduceMotion on the amount is a quarter. Example: feel.squash {\"entity\":\"player\",\"amount\":0.35,\"duration\":0.25}",
           parse_schema(R"({"type":"object","required":["entity"],"properties":{
               "entity":{"type":"string","description":"The entity (id or name)."},
               "amount":{"type":"number","minimum":-1.5,"maximum":1.5,"default":0.3,"description":"> 0 squashes (flatter and wider), < 0 stretches (taller and thinner)."},
               "duration":{"type":"number","minimum":0.01,"maximum":30,"default":0.3,"description":"Seconds until the entity is back to its own scale."},
               "axis":{"type":"string","enum":["x","y"],"default":"y","description":"The axis that gets shorter when amount > 0."}}})"),
           false, "feel"},
          [&I](const Json& a) { return run_action(I, a, "squash", "feel.squash", true); });

    I.commands.add({"feel.spawn", "Makes an effect appear: instantiates a prefab at an entity (or at a point) the next frame.",
           "The same as the \"spawn\" action of a clip event (docs/GAME_FEEL.md, \"Effects as data\"). The prefab appears at the "
           "entity's world position plus `offset`, or at `offset` itself without an entity, the next time the frame's game feel pass "
           "runs. Spawned entities are left out of saved scenes. Give `lifetime` to have it destroyed after that many seconds; "
           "without it the prefab has to end itself. Example: feel.spawn {\"entity\":\"enemy\",\"prefab\":\"prefabs/hit_spark.prefab.json\",\"lifetime\":0.4}",
           parse_schema(R"({"type":"object","required":["prefab"],"properties":{
               "entity":{"type":"string","description":"The entity the effect appears at (id or name). Default: the world origin plus `offset`."},
               "prefab":{"type":"string","description":"Project-relative path of the prefab."},
               "offset":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":3,"default":[0,0],"description":"Added to the entity's world position, [x, y] or [x, y, z]."},
               "local":{"type":"boolean","default":false,"description":"true: `offset` is in the entity's own space (a mirrored sprite puts it on the other side)."},
               "lifetime":{"type":"number","minimum":0,"default":0,"description":"Seconds of game time until the spawned entity is destroyed (a hit-stop, time.scale 0 or a pause holds the count); 0 = the prefab ends itself."}}})"),
           false, "feel"},
          [&I](const Json& a) { return run_action(I, a, "spawn", "feel.spawn", false); });

    I.commands.add({"feel.sound", "Plays a sound once through the audio system (the same one a clip event's \"sound\" action uses).",
           "The sound starts on the next audio update, on its bus, and shows in `audio.log` like any other play. Example: "
           "feel.sound {\"path\":\"audio/hit.wav\",\"volume\":0.8,\"pitch\":1.1}",
           parse_schema(R"({"type":"object","required":["path"],"properties":{
               "entity":{"type":"string","description":"The entity the sound belongs to (id or name); optional, only named in logs."},
               "path":{"type":"string","description":"Project-relative path of the sound."},
               "volume":{"type":"number","minimum":0,"maximum":4,"default":1,"description":"Volume."},
               "pitch":{"type":"number","minimum":0.1,"maximum":4,"default":1,"description":"Playback speed and pitch."},
               "pan":{"type":"number","minimum":-1,"maximum":1,"default":0,"description":"-1 left to 1 right."},
               "bus":{"type":"string","default":"sfx","description":"\"sfx\", \"music\", \"ui\" or a bus of the project."}}})"),
           false, "feel"},
          [&I](const Json& a) { return run_action(I, a, "sound", "feel.sound", false); });

    I.commands.add({"feel.cancel", "Ends the game feel effects of an entity at once (flash, squash, shake, knockback), or of everything.",
           "Without `entity` it ends every effect of the scene, hit-stops included. The entity's Transform is not touched: effects "
           "never wrote to it, except the position a body-less knockback already moved. Example: feel.cancel {}",
           parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"The entity (id or name). Default: everything."}}})"),
           false, "feel"},
          [&I](const Json& a) {
              const Entity e = a.contains("entity") && !a["entity"].is_null() ? need_entity(I.world, a, "entity") : kNullEntity;
              feel_cancel(I.world, e);
              return Json::object({{"ok", true}});
          });

    I.commands.add({"feel.settings", "The accessibility choices of the game feel effects: reduceMotion and reducedEffects.",
           "The same as `feel.reduceMotion` / `feel.reducedEffects` in a script. true or false is the player's choice, null follows the "
           "operating system's reduce motion again; a missing key stays as it is. reduceMotion shrinks shake and squash to a quarter "
           "and halves hit-stops; reducedEffects caps flashes at 0.35 and makes them fade. Applies to effects started afterwards. "
           "Returns the values in force. Example: feel.settings {\"reduceMotion\":true}",
           parse_schema(R"({"type":"object","properties":{
               "reduceMotion":{"type":["boolean","null"],"description":"true / false = the player's choice; null = follow the system."},
               "reducedEffects":{"type":["boolean","null"],"description":"true / false = the player's choice; null = follow the system."}}})"),
           false, "feel"},
          [&I](const Json& a) {
              FeelState& fs = I.world.feel();
              auto apply = [&](const char* key, std::optional<bool>& slot) {
                  auto it = a.find(key);
                  if (it == a.end()) return;
                  if (it->is_null()) slot.reset();
                  else if (it->is_boolean()) slot = it->get<bool>();
                  else throw CommandError("invalid_argument", std::format("feel.settings: '{}' must be true, false or null.", key),
                                          "true / false is the player's choice, null follows the system.");
              };
              apply("reduceMotion", fs.reduceMotionSetting);
              apply("reducedEffects", fs.reducedEffectsSetting);
              return Json::object({{"reduceMotion", fs.reduce_motion()}, {"reducedEffects", fs.reduced_effects()}});
          });

    I.commands.add({"feel.state", "What the game feel effects are doing now: hit-stop, and per entity its shake, flash, squash, knockback and drawn pose.",
           "Returns {reduceMotion, reducedEffects, reduceMotionSetting, reducedEffectsSetting, hitStop: {remaining, scale, running}, "
           "queued: {sounds, spawns, spawnLifetimes} (sounds and spawns waiting for the next frame, spawned effects that will be destroyed), entities: [{entity, shake?, flash?, squash?, knockback?, pose?}]}. `pose` is what is added to the entity at draw time "
           "(position, rotation degrees, scale factor); its Transform is unchanged. Example: feel.state {}",
           parse_schema(R"({"type":"object","properties":{}})"),
           true, "feel"},
          [&I](const Json&) { return feel_state_json(I.world); });

    // Capabilities (capability.h): what each command does outside the engine's memory.
    declare_command_capabilities(I.commands, {
        {"feel.shake", capability_sets::changes_state()},
        {"feel.flash", capability_sets::changes_state()},
        {"feel.knockback", capability_sets::changes_state()},
        {"feel.squash", capability_sets::changes_state()},
        {"feel.spawn", capability_sets::changes_state()},
        {"feel.sound", capability_sets::changes_state()},
        {"feel.cancel", capability_sets::changes_state()},
        {"feel.hitStop", capability_sets::changes_state()},
        {"feel.settings", capability_sets::changes_state()},
        {"feel.state", capability_sets::reads()},
    });
}

}  // namespace fa
