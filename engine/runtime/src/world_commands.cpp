// The runtime commands of the big worlds of M75 (docs/BIG_WORLDS.md): the floating origin (world.origin, world.rebase) and the
// streamed cells (world.cells, world.stream_status). M75-P0 registers them so the names, arguments and docs are fixed before the
// packages that build them: each one fails with `not_built` and names the package that fills it in. The later packages replace the
// handler and keep the name, the schema and the description (they may only add to them). world.cells and world.stream_status are built
// (M75.3, the streamer in world_streamer.h); world.origin and world.rebase are still stubs.
#include "engine_impl.h"
#include <algorithm>

#include "fa/core/capability.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

void add_stub(Engine::Impl& I, const char* name, const char* summary, const std::string& description,
              const char* schema, const char* package, bool readOnly = true) {
    const std::string cmd = name;
    const std::string pkg = package;
    I.commands.add(
        {name, summary,
         description + " Not built yet (planned, " + pkg + "): the command exists so its name and arguments are fixed.",
         parse_schema(schema), readOnly, "world"},
        [cmd, pkg](const Json&) -> Json {
            throw CommandError(
                "not_built", cmd + " is not built yet: it is planned for a coming version.",
                "Package " + pkg +
                    " of the big worlds builds it: read docs/BIG_WORLDS.md (docs.read BIG_WORLDS) for what " + cmd +
                    " will do. Nothing was changed.");
        });
}

}  // namespace

void register_world_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    add_stub(
        I, "world.origin", "Read the floating origin: where the world's origin is, in double precision.",
        "Will return {enabled, origin: [x, y, z] (metres, doubles: the world position of the engine's local (0, 0, "
        "0)), rebases "
        "(how many times the origin moved since the scene loaded), threshold, step, anchor} from the project's "
        "`world.floatingOrigin` settings and the running world. Read-only. Result (one shape, also when the floating "
        "origin "
        "is off, then enabled is false and origin [0, 0, 0]): {enabled, origin, rebases, threshold, step, anchor}. "
        "Example: world.origin {}",
        R"({"type":"object","properties":{}})", "M75.4");
    add_stub(
        I, "world.rebase", "Move the floating origin now, shifting every entity so the camera is near (0, 0, 0) again.",
        "Will move the origin to `offset` (double metres, world space) or to the position of `entity`, shifting every "
        "Transform, physics body, audio source and particle by the difference in one step, so nothing visible changes. "
        "It "
        "does what the engine does by itself when the anchor goes past `world.floatingOrigin.threshold`, on demand, "
        "for tests "
        "and cutscenes. Without `offset` and `entity` it centres on the project's anchor. Fails when floating origin "
        "is not "
        "enabled in the project. Result: {origin, shifted (entities moved)}. Example: world.rebase "
        "{\"offset\":[5000,0,0]}",
        R"({"type":"object","properties":{
               "offset":{"type":"array","items":{"type":"number"},"minItems":3,"maxItems":3,"description":"The new origin: world metres [x, y, z] as doubles."},
               "entity":{"type":"string","description":"Centre the origin on this entity's world position (an entity id)."}}})",
        "M75.4", false);
    add_stub(I, "world.absolute_position",
             "Read an entity's position in double precision: the floating origin plus its local position.",
             "Will return {entity, position: [x, y, z] (the origin plus the entity's world position, in doubles), "
             "origin: [x, y, z], "
             "local: [x, y, z] (the entity's world position in the engine's float space)} so a game far from the "
             "origin still "
             "knows where things are. Read-only. Example: world.absolute_position {\"entity\":\"player\"}",
             R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id."}},"required":["entity"]})",
             "M75.4");
    I.commands.add(
        {"world.cells", "List the cells of the streamed world and which are loaded.",
         "Lists the cells of the index of the scene's StreamedWorld (docs/BIG_WORLDS.md, \"Streaming\"): {world, "
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
