// The runtime commands of the big worlds of M75 (docs/BIG_WORLDS.md): the floating origin (world.origin, world.rebase,
// world.absolute_position) and the streamed cells (world.cells, world.stream_status). M75-P0 registered them all as `not_built` stubs
// so the names, arguments and docs were fixed before the packages that build them; the floating origin ones are real now (M75-P4a),
// the streaming ones (M75-P3a, the streamer in world_streamer.h) are real too.
#include "engine_impl.h"
#include <algorithm>
#include <cmath>

#include "fa/core/capability.h"
#include "fa/scene/floating_origin.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

}  // namespace

void register_world_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add(
        {"world.origin", "Read the floating origin: where the world's origin is, in double precision.",
         "Returns {enabled, origin: [x, y, z] (metres, doubles: the world position of the engine's local (0, 0, 0)), "
         "rebases "
         "(how many times the origin moved since the scene loaded), threshold, step, anchor} from the project's "
         "`world.floatingOrigin` settings and the running world. Read-only. Result: {enabled, origin, rebases, "
         "threshold, step, "
         "anchor, anchorPosition (the anchor's local position, null when there is none)}. Example: world.origin {}",
         parse_schema(R"({"type":"object","properties":{}})"), true, "world"},
        [&I](const Json&) -> Json {
            const FloatingOriginSettings& fo = I.project.floatingOrigin;
            const DVec3 o = I.world.origin();
            Vec3 anchor;
            Json anchorJson = nullptr;
            if (I.origin_anchor_position(anchor)) anchorJson = Json::array({anchor.x, anchor.y, anchor.z});
            return Json::object({{"enabled", fo.enabled},
                                 {"origin", Json::array({o.x, o.y, o.z})},
                                 {"rebases", I.world.rebase_count()},
                                 {"threshold", fo.threshold},
                                 {"step", fo.step},
                                 {"anchor", fo.anchor},
                                 {"anchorPosition", anchorJson}});
        });
    I.commands.add(
        {"world.rebase", "Move the floating origin now, shifting every entity so the camera is near (0, 0, 0) again.",
         "Moves the origin to `origin` (double metres, world space: the NEW origin, not a delta; `offset` is the old "
         "name of the "
         "same argument and still works) or to the position of `entity`, "
         "shifting every "
         "root Transform, physics body, audio source, navigation grid and particle by the difference in one step, so "
         "nothing "
         "visible changes. The difference is rounded to a whole multiple of `world.floatingOrigin.step` on each axis "
         "(so every "
         "shifted position is exact in float and the origin stays exact in double): the origin ends up at the nearest "
         "multiple of "
         "the step, and `shift` says by how much it moved. It does what the engine does by itself when the anchor goes "
         "past "
         "`world.floatingOrigin.threshold`, on demand, for tests and cutscenes. Without `origin` and `entity` it "
         "centres on the "
         "project's anchor. Fails when floating origin is not enabled in the project (set world.floatingOrigin.enabled "
         "in "
         "factoria.json), when `origin` (or `offset`) and `entity` are both given, and when the shift is more than "
         "16777216 steps (a "
         "float "
         "cannot hold it exactly): shift in several rebases. Scripts hear one `originShifted` event. Result: {origin, "
         "shift (the "
         "amount subtracted from every position, [x, y, z]: the `offset` of the `originShifted` event), shifted (root "
         "entities moved), rebases}. Example: world.rebase "
         "{\"origin\":[5000,0,0]}",
         parse_schema(R"({"type":"object","properties":{
           "origin":{"type":"array","items":{"type":"number"},"minItems":3,"maxItems":3,"description":"The new origin (not a delta): world metres [x, y, z] as doubles, rounded to the step."},
           "offset":{"type":"array","items":{"type":"number"},"minItems":3,"maxItems":3,"description":"Deprecated alias of `origin` (it is the new origin, not a delta, and not the `offset` of the originShifted event)."},
           "entity":{"type":"string","description":"Centre the origin on this entity's world position (an entity id)."}}})"),
         false, "world"},
        [&I](const Json& a) -> Json {
            const FloatingOriginSettings& fo = I.project.floatingOrigin;
            const bool hasNew = a.contains("origin") && !a["origin"].is_null();
            const bool hasOld = a.contains("offset") && !a["offset"].is_null();
            const bool hasOffset = hasNew || hasOld;  // `offset` is the deprecated name of `origin`
            const char* originKey = hasNew ? "origin" : "offset";
            const bool hasEntity = a.contains("entity") && !a["entity"].is_null();
            if (hasNew && hasOld)
                throw CommandError(
                    "invalid_argument",
                    "/origin and /offset are both given: they are the same argument (`offset` is the old name).",
                    "Pass only `origin`.");
            if (hasOffset && hasEntity)
                throw CommandError(
                    "invalid_argument",
                    std::string("/") + originKey +
                        " and /entity are both given: world.rebase moves the origin to one place.",
                    "Pass either `origin` (the new origin as [x, y, z] metres) or `entity` (an entity id), or neither "
                    "to centre on the project's anchor.");
            if (!fo.enabled)
                throw CommandError(
                    "not_enabled", "Floating origin is not enabled in this project, so world.rebase does nothing.",
                    "Set world.floatingOrigin.enabled to true in factoria.json (docs.read BIG_WORLDS, \"Floating "
                    "origin\"). Nothing was changed.");
            if (!(fo.step >= 1.0))
                throw CommandError("invalid_state",
                                   "/world/floatingOrigin/step is " + std::to_string(fo.step) + ", not a step.",
                                   "Use a power of two from 1 to 1048576 (docs.read BIG_WORLDS).");
            DVec3 target = I.world.origin();
            if (hasOffset) {
                const Json& o = a[originKey];
                if (!o.is_array() || o.size() != 3 || !o[0].is_number() || !o[1].is_number() || !o[2].is_number())
                    throw CommandError("invalid_argument",
                                       std::string("/") + originKey + " must be an array of three numbers, got " +
                                           o.dump() + ".",
                                       "Use the new origin in world metres, for example [5000, 0, 0].");
                target = {o[0].get<double>(), o[1].get<double>(), o[2].get<double>()};
            } else if (hasEntity) {
                target = I.world.absolute_position(need_entity(I.world, a, "entity"));
            } else {
                Vec3 anchor;
                if (!I.origin_anchor_position(anchor))
                    throw CommandError(
                        "not_found", "The anchor \"" + fo.anchor + "\" does not exist in this scene.",
                        "Add a primary Camera, or name an entity in world.floatingOrigin.anchor (\"entity:<id>\"), or "
                        "pass `offset` or `entity`.");
                target = I.world.to_absolute(anchor);
            }
            // The whole multiple of the step nearest to where the origin has to go, per axis (in double: no precision lost
            // before the check).
            const DVec3 want = target - I.world.origin();
            const double step = fo.step;
            const DVec3 shift{std::round(want.x / step) * step, std::round(want.y / step) * step,
                              std::round(want.z / step) * step};
            if (auto ok = check_rebase_offset(shift, step,
                                              hasOffset   ? (hasNew ? "/origin" : "/offset")
                                              : hasEntity ? "/entity"
                                                          : "/anchor");
                !ok)
                throw CommandError("invalid_argument", ok.error().message, ok.error().hint);
            std::int64_t shifted = 0;
            const Vec3 offset = to_vec3(shift);
            if (offset.x != 0.0f || offset.y != 0.0f || offset.z != 0.0f)
                for (Entity r : I.world.roots())
                    if (follows_floating_origin(I.world, r)) ++shifted;
            I.rebase_origin(offset);
            const DVec3 o = I.world.origin();
            return Json::object({{"origin", Json::array({o.x, o.y, o.z})},
                                 {"shift", Json::array({shift.x, shift.y, shift.z})},
                                 {"shifted", shifted},
                                 {"rebases", I.world.rebase_count()}});
        });
    I.commands.add({"world.absolute_position",
                    "Read an entity's position in double precision: the floating origin plus its local position.",
                    "Returns {entity, position: [x, y, z] (the origin plus the entity's world position, added in "
                    "double: the number that does "
                    "not change when a floating-origin rebase shifts the origin, exact to about a micrometre at 10 000 "
                    "km), origin: [x, y, z], "
                    "local: [x, y, z] (the entity's world position in the engine's float space, what scripts and the "
                    "editor read)}. Without "
                    "floating origin the origin is [0, 0, 0] and position equals local. Read-only. Example: "
                    "world.absolute_position "
                    "{\"entity\":\"player\"}",
                    parse_schema(R"({"type":"object","required":["entity"],"properties":{
           "entity":{"type":"string","description":"The entity id (or name)."}}})"),
                    true, "world"},
                   [&I](const Json& a) -> Json {
                       const Entity e = need_entity(I.world, a, "entity");
                       const Vec3 p = I.world.world_position(e);
                       const DVec3 o = I.world.origin(), abs = I.world.absolute_position(e);
                       return Json::object({{"entity", I.world.id_of(e)},
                                            {"position", Json::array({abs.x, abs.y, abs.z})},
                                            {"origin", Json::array({o.x, o.y, o.z})},
                                            {"local", Json::array({p.x, p.y, p.z})}});
                   });
    I.commands.add(
        {"world.cells", "List the cells of the streamed world and which are loaded.",
         "Lists the cells of the index of the scene's StreamedWorld (docs/BIG_WORLDS_STREAMING.md, \"Streaming\"): "
         "{world, "
         "dimension, cellSize, total, "
         "matching, truncated, cells: [{id, coord: [i, j], scene, bounds: {min, max}, state: \"unloaded\" | \"queued\" "
         "| \"loading\" | "
         "\"loaded\" | \"unloading\", entities (under the cell's root, 0 unless loaded), distance (metres on the plane "
         "to the nearest enabled "
         "StreamingAnchor, null with none), sizeBytes?, failed?}]}, sorted by distance (cells with no distance last, "
         "then by [j, i]). `state` "
         "keeps one state, `limit` caps the list (default 1000; `total` and `matching` count them all). Reads the "
         "index at once when the "
         "streamer has not (a StreamedWorld with a wrong index answers `error`). Read-only. Example: world.cells "
         "{\"state\":\"loaded\"}",
         parse_schema(R"({"type":"object","properties":{
               "state":{"type":"string","enum":["unloaded","queued","loading","loaded","unloading"],"description":"Only the cells in this state."},
               "limit":{"type":"integer","minimum":1,"maximum":100000,"description":"The most cells to list (default 1000)."}}})"),
         true, "world"},
        [&I](const Json& args) -> Json {
            if (!I.streamer)
                throw CommandError("not_running", "world.cells needs a running engine.",
                                   "Start the engine (Engine::init) first.");
            const std::string state =
                args.contains("state") && args["state"].is_string() ? args["state"].get<std::string>() : std::string();
            std::size_t limit = 1000;
            if (args.contains("limit") && args["limit"].is_number()) {
                const double v = args["limit"].get<double>();
                limit = std::size_t(std::clamp(v, 1.0, 100000.0));
            }
            Json out = I.streamer->cells(state, limit);
            if (out.contains("error"))
                throw CommandError(
                    "no_streamed_world", out["error"].get<std::string>(),
                    "Put a StreamedWorld component with `world` set to a <name>.world.json on an entity of the scene "
                    "(docs.read BIG_WORLDS, \"Streaming\"), then call this again.");
            return out;
        });
    I.commands.add(
        {"world.stream_status", "Read what the world streaming is doing: loads in flight, budget, cells loaded.",
         "Returns {enabled, world, cellsTotal, cellsLoaded, cellsLoading (jobs started and not applied yet), "
         "cellsQueued, cellsUnloading, "
         "inFlight, waitingToApply (read and parsed, not added to the world yet), anchors (enabled StreamingAnchor "
         "entities, and the camera "
         "with cameraLoadRadius), loadsStarted, loadsCancelled, cellsApplied, unloadsDone, bytesLoaded, "
         "appliedThisFrame, "
         "unloadedThisFrame, unitsThisFrame (the BackgroundLoader units of the last frame), maxLoadsInFlight, "
         "maxAppliesPerFrame, "
         "budget: {mode: \"units\" (exact, the same on every machine) | \"timed\", units | ms}, pending: [ids of the "
         "cells loading, then "
         "the queued ones, in the order they will be applied], lastError}. A game or a test waits until the cells "
         "around the player are in "
         "(pending empty and cellsUnloading 0). Read-only. Example: world.stream_status {}",
         parse_schema(R"({"type":"object","properties":{}})"), true, "world"},
        [&I](const Json&) -> Json {
            if (!I.streamer)
                throw CommandError("not_running", "world.stream_status needs a running engine.",
                                   "Start the engine (Engine::init) first.");
            Json out = I.streamer->status();
            const bool exact = I.replaying || !((I.windowed && !I.cfg.editorMode) || I.cfg.timedLoads);
            out["budget"] = exact ? Json::object({{"mode", "units"}, {"units", BackgroundLoader::kFixedUnitsPerFrame}})
                                  : Json::object({{"mode", "timed"}, {"ms", I.project.loadBudgetMs}});
            return out;
        });
    declare_command_capabilities(I.commands, {{"world.origin", capability_sets::reads()},
                                              {"world.absolute_position", capability_sets::reads()},
                                              {"world.rebase", capability_sets::changes_state()},
                                              {"world.cells", capability_sets::reads()},
                                              {"world.stream_status", capability_sets::reads()}});
}

}  // namespace fa
