// The runtime commands of the big worlds of M75 (docs/BIG_WORLDS.md): the floating origin (world.origin, world.rebase) and the
// streamed cells (world.cells, world.stream_status). M75-P0 registers them so the names, arguments and docs are fixed before the
// packages that build them: each one fails with `not_built` and names the package that fills it in. The later packages replace the
// handler and keep the name, the schema and the description (they may only add to them).
#include "engine_impl.h"
#include "fa/core/capability.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

void add_stub(Engine::Impl& I, const char* name, const char* summary, const std::string& description, const char* schema,
              const char* package, bool readOnly = true) {
    const std::string cmd = name;
    const std::string pkg = package;
    I.commands.add({name, summary, description + " Not built yet (planned, " + pkg + "): the command exists so its name and arguments are fixed.",
                    parse_schema(schema), readOnly, "world"},
                   [cmd, pkg](const Json&) -> Json {
                       throw CommandError("not_built", cmd + " is not built yet (" + pkg + ").",
                                          "Big worlds are planned for M75: read docs/BIG_WORLDS.md (docs.read BIG_WORLDS) for what " +
                                              cmd + " will do and when. Nothing was changed.");
                   });
}

}  // namespace

void register_world_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    add_stub(I, "world.origin", "Read the floating origin: where the world's origin is, in double precision.",
             "Will return {enabled, origin: [x, y, z] (metres, doubles: the world position of the engine's local (0, 0, 0)), rebases "
             "(how many times the origin moved since the scene loaded), threshold, step, anchor} from the project's "
             "`world.floatingOrigin` settings and the running world. Read-only. Result: {enabled, origin, rebases}. "
             "Example: world.origin {}",
             R"({"type":"object","properties":{}})", "M75.4");
    add_stub(I, "world.rebase", "Move the floating origin now, shifting every entity so the camera is near (0, 0, 0) again.",
             "Will move the origin to `offset` (double metres, world space) or to the position of `entity`, shifting every "
             "Transform, physics body, audio source and particle by the difference in one step, so nothing visible changes. It "
             "does what the engine does by itself when the anchor goes past `world.floatingOrigin.threshold`, on demand, for tests "
             "and cutscenes. Without `offset` and `entity` it centres on the project's anchor. Fails when floating origin is not "
             "enabled in the project. Result: {origin, shifted (entities moved)}. Example: world.rebase {\"offset\":[5000,0,0]}",
             R"({"type":"object","properties":{
               "offset":{"type":"array","items":{"type":"number"},"minItems":3,"maxItems":3,"description":"The new origin: world metres [x, y, z] as doubles."},
               "entity":{"type":"string","description":"Centre the origin on this entity's world position (an entity id)."}}})",
             "M75.4", false);
    add_stub(I, "world.cells", "List the cells of the streamed world and which are loaded.",
             "Will list every cell of the streamed world (the cells world.split_cells wrote): {cells: [{id, bounds: {min, max}, "
             "state: \"unloaded\" | \"loading\" | \"loaded\" | \"unloading\", entities, distance}]}, sorted by distance to the nearest "
             "StreamingAnchor. `state` filters the list. Read-only. Example: world.cells {\"state\":\"loaded\"}",
             R"({"type":"object","properties":{
               "state":{"type":"string","enum":["unloaded","loading","loaded","unloading"],"description":"Only the cells in this state."}}})",
             "M75.3");
    add_stub(I, "world.stream_status", "Read what the world streaming is doing: loads in flight, budget, cells loaded.",
             "Will return {cellsLoaded, cellsLoading, cellsTotal, anchors, loadsStarted, unloadsDone, bytesLoaded, frameBudgetMs, "
             "pending: [cell ids waiting], lastError} so a game or a test can wait until the cells around the player are in. "
             "Read-only. Result: the fields above. Example: world.stream_status {}",
             R"({"type":"object","properties":{}})", "M75.3");
    declare_command_capabilities(I.commands, {{"world.origin", capability_sets::reads()},
                                              {"world.rebase", capability_sets::changes_state()},
                                              {"world.cells", capability_sets::reads()},
                                              {"world.stream_status", capability_sets::reads()}});
}

}  // namespace fa
