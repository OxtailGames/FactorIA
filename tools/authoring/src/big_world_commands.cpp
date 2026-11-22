// The commands of the big worlds of M75 that write project files (docs/BIG_WORLDS.md): model.bake_impostor and foliage.* (terrain.* is terrain3d_commands.cpp). M75-P0 registers them so the names, arguments and docs are
// fixed before the packages that build them: each one fails with `not_built` and names the package that fills it in, and changes
// nothing. The later packages replace the handler and keep the name, the schema and the description (they may only add to them).
#include "authoring_internal.h"
#include "fa/core/capability.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

void add_stub(Engine::Impl& I, const char* name, const char* summary, const std::string& description,
              const char* schema, const char* package, const char* category, bool readOnly = false) {
    const std::string cmd = name;
    const std::string pkg = package;
    I.commands.add(
        {name, summary,
         description + " Not built yet (planned, " + pkg + "): the command exists so its name and arguments are fixed.",
         parse_schema(schema), readOnly, category},
        [cmd, pkg](const Json&) -> Json {
            throw CommandError(
                "not_built", cmd + " is not built yet: it is planned for a coming version.",
                "Package " + pkg +
                    " of the big worlds builds it: read docs/BIG_WORLDS.md (docs.read BIG_WORLDS) for what " + cmd +
                    " will do. Nothing was changed.");
        });
}

}  // namespace

void register_big_world_commands(Engine& engine, Engine::Impl& I) {
    register_terrain3d_commands(engine, I);
    // world streaming
    // levels of detail: model.generate_lods lives in fa_tooling next to the model documents it edits (assets_model.cpp)
    add_stub(
        I, "model.bake_impostor", "Bake a billboard impostor texture of a model from several views.",
        "Will render the model from `views` directions around it into an atlas of `resolution` pixels per view, write "
        "the atlas "
        "and its data file, and set MeshRenderer.impostor of the entities that use the model when `apply` is true. "
        "Result: {file, views, resolution}. Example: model.bake_impostor {\"model\":\"models/tree.glb\",\"views\":8}",
        R"({"type":"object","properties":{
               "model":{"type":"string","description":"The model or mesh file to bake (project-relative path)."},
               "views":{"type":"integer","minimum":1,"maximum":64,"default":8,"description":"How many directions around the model."},
               "resolution":{"type":"integer","minimum":16,"maximum":2048,"default":256,"description":"Pixels of one view's side."},
               "apply":{"type":"boolean","default":false,"description":"Also set MeshRenderer.impostor of the entities that use the model."}},"required":["model"]})",
        "M75.1", "assets");
    // foliage
    add_stub(I, "foliage.scatter", "Fill a Foliage's instances by a ScatterRule over a terrain.",
             "Will read the ScatterRule of `rule` (an entity id; default: the Foliage entity's own ScatterRule), place "
             "instances on "
             "the Terrain it names by density, slope, height and layers, deterministically from its seed, and write "
             "the Foliage's "
             "`instances` file, with each instance's mesh index into `Foliage.meshes`. It writes into the ONE Foliage "
             "entity, "
             "whose `meshes` it sets to all the meshes of the rule. `dryRun` only counts. Result: {instances, file}. "
             "Example: foliage.scatter {\"entity\":\"grass\"}",
             R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "rule":{"type":"string","description":"Entity id with the ScatterRule (default: the Foliage entity)."},
               "dryRun":{"type":"boolean","default":false,"description":"Only count the instances."}},"required":["entity"]})",
             "M75.6", "world");
    add_stub(I, "foliage.paint", "Add or remove foliage instances by hand in a circle on the ground.",
             "Will add instances (mode \"add\", `density` per square metre) or remove them (mode \"remove\") within "
             "`radius` metres "
             "of `center` and write the instances file back. Result: {added, removed}. "
             "Example: foliage.paint {\"entity\":\"grass\",\"center\":[10,20],\"radius\":5}",
             R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "mode":{"type":"string","enum":["add","remove"],"default":"add","description":"Add instances or remove them."},
               "center":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"World metres [x, z]."},
               "radius":{"type":"number","exclusiveMinimum":0,"description":"Brush radius in metres."},
               "density":{"type":"number","exclusiveMinimum":0,"default":1,"description":"Instances per square metre when adding."}},"required":["entity","center","radius"]})",
             "M75.6", "world");
    add_stub(I, "foliage.clear", "Remove every instance of a Foliage, or those in a rectangle.",
             "Will empty the Foliage's instances file, or only the instances inside `region` ([minX, minZ, maxX, maxZ] "
             "world "
             "metres). Result: {removed}. Example: foliage.clear {\"entity\":\"grass\"}",
             R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "region":{"type":"array","items":{"type":"number"},"minItems":4,"maxItems":4,"description":"[minX, minZ, maxX, maxZ] in world metres; omit for all."}},"required":["entity"]})",
             "M75.6", "world");
    declare_command_capabilities(I.commands, {{"model.bake_impostor", capability_sets::edits_project()},
                                              {"foliage.scatter", capability_sets::edits_project()},
                                              {"foliage.paint", capability_sets::edits_project()},
                                              {"foliage.clear", capability_sets::edits_project()}});
}

}  // namespace fa
