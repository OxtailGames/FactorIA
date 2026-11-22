// The runtime commands of the big worlds of M75 (docs/BIG_WORLDS.md): the floating origin (world.origin, world.rebase,
// world.absolute_position) and the streamed cells (world.cells, world.stream_status). M75-P0 registered them all as `not_built` stubs
// so the names, arguments and docs were fixed before the packages that build them; the floating origin ones are real now (M75-P4a),
// the streaming ones are filled in by their package, which keeps the name, the schema and the description (it may only add to them).
#include "engine_impl.h"
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
         "Moves the origin to `offset` (double metres, world space: the new origin) or to the position of `entity`, "
         "shifting every "
         "root Transform, physics body, audio source, navigation grid and particle by the difference in one step, so "
         "nothing "
         "visible changes. The difference is rounded to a whole multiple of `world.floatingOrigin.step` on each axis "
         "(so every "
         "shifted position is exact in float and the origin stays exact in double): the origin ends up at the nearest "
         "multiple of "
         "the step, and `shift` says by how much it moved. It does what the engine does by itself when the anchor goes "
         "past "
         "`world.floatingOrigin.threshold`, on demand, for tests and cutscenes. Without `offset` and `entity` it "
         "centres on the "
         "project's anchor. Fails when floating origin is not enabled in the project (set world.floatingOrigin.enabled "
         "in "
         "factoria.json), when `offset` and `entity` are both given, and when the shift is more than 16777216 steps (a "
         "float "
         "cannot hold it exactly): shift in several rebases. Scripts hear one `originShifted` event. Result: {origin, "
         "shift (the "
         "offset applied, [x, y, z]), shifted (root entities moved), rebases}. Example: world.rebase "
         "{\"offset\":[5000,0,0]}",
         parse_schema(R"({"type":"object","properties":{
           "offset":{"type":"array","items":{"type":"number"},"minItems":3,"maxItems":3,"description":"The new origin: world metres [x, y, z] as doubles."},
           "entity":{"type":"string","description":"Centre the origin on this entity's world position (an entity id)."}}})"),
         false, "world"},
        [&I](const Json& a) -> Json {
            const FloatingOriginSettings& fo = I.project.floatingOrigin;
            const bool hasOffset = a.contains("offset") && !a["offset"].is_null();
            const bool hasEntity = a.contains("entity") && !a["entity"].is_null();
            if (hasOffset && hasEntity)
                throw CommandError(
                    "invalid_argument",
                    "/offset and /entity are both given: world.rebase moves the origin to one place.",
                    "Pass either `offset` (the new origin as [x, y, z] metres) or `entity` (an entity id), or neither "
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
                const Json& o = a["offset"];
                if (!o.is_array() || o.size() != 3 || !o[0].is_number() || !o[1].is_number() || !o[2].is_number())
                    throw CommandError("invalid_argument",
                                       "/offset must be an array of three numbers, got " + o.dump() + ".",
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
                                              hasOffset   ? "/offset"
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
    add_stub(I, "world.cells", "List the cells of the streamed world and which are loaded.",
             "Will list every cell of the streamed world (the cells world.split_cells wrote): {cells: [{id, bounds: "
             "{min, max}, "
             "state: \"unloaded\" | \"loading\" | \"loaded\" | \"unloading\", entities, distance}]}, sorted by "
             "distance to the nearest "
             "StreamingAnchor. `state` filters the list. Read-only. Example: world.cells {\"state\":\"loaded\"}",
             R"({"type":"object","properties":{
               "state":{"type":"string","enum":["unloaded","loading","loaded","unloading"],"description":"Only the cells in this state."}}})",
             "M75.3");
    add_stub(I, "world.stream_status", "Read what the world streaming is doing: loads in flight, budget, cells loaded.",
             "Will return {cellsLoaded, cellsLoading, cellsTotal, anchors, loadsStarted, unloadsDone, bytesLoaded, "
             "frameBudgetMs, "
             "pending: [cell ids waiting], lastError} so a game or a test can wait until the cells around the player "
             "are in. "
             "Read-only. Result: the fields above. Example: world.stream_status {}",
             R"({"type":"object","properties":{}})", "M75.3");
    declare_command_capabilities(I.commands, {{"world.origin", capability_sets::reads()},
                                              {"world.absolute_position", capability_sets::reads()},
                                              {"world.rebase", capability_sets::changes_state()},
                                              {"world.absolute_position", capability_sets::reads()},
                                              {"world.cells", capability_sets::reads()},
                                              {"world.stream_status", capability_sets::reads()}});
}

}  // namespace fa
