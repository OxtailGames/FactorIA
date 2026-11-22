// The commands of the big worlds of M75 that write project files (docs/BIG_WORLDS.md): world.split_cells, world.merge_cells,
// and foliage.* (terrain.* is terrain3d_commands.cpp). M75-P0 registers them so the names, arguments and docs are
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
    add_stub(I, "world.split_cells", "Split a scene into streamable cells on a grid, with a manifest.",
             "Will cut the scene's entities into a grid of cells `cellSize` metres wide on X and Z, write one scene "
             "file per cell "
             "and the index `<name>.world.json` (the manifest: cell size, each cell's bounds and file, the entities "
             "that stay always loaded), and report what it wrote. `dryRun` only reports. "
             "Writes next to the scene unless `output` names a folder. Result: {cells, files, alwaysLoaded}. "
             "Example: world.split_cells {\"scene\":\"scenes/world.scene.json\",\"cellSize\":128}",
             R"({"type":"object","properties":{
               "scene":{"type":"string","description":"The scene file to split (project-relative path)."},
               "cellSize":{"type":"number","minimum":1,"default":128,"description":"Width of a cell in metres, on X and Z."},
               "output":{"type":"string","description":"Folder for the cell files (default: next to the scene)."},
               "dryRun":{"type":"boolean","default":false,"description":"Only report what would be written."}},"required":["scene"]})",
             "M75.3", "world");
    add_stub(I, "world.merge_cells", "Merge the cells of a split scene back into one scene file.",
             "Will read a manifest written by world.split_cells and write the entities of every cell back into one "
             "scene file "
             "(the inverse of the split, so a level can be edited as one file). `dryRun` only reports. Result: {scene, "
             "entities}. "
             "Example: world.merge_cells {\"manifest\":\"scenes/main.world.json\"}",
             R"({"type":"object","properties":{
               "manifest":{"type":"string","description":"The manifest file written by world.split_cells."},
               "output":{"type":"string","description":"The scene file to write (default: the scene the manifest was made from)."},
               "dryRun":{"type":"boolean","default":false,"description":"Only report what would be written."}},"required":["manifest"]})",
             "M75.3", "world");
    // levels of detail: model.generate_lods and model.bake_impostor live in fa_tooling next to the model documents (assets_model.cpp)
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
    declare_command_capabilities(I.commands, {{"world.split_cells", capability_sets::edits_project()},
                                              {"world.merge_cells", capability_sets::edits_project()},
                                              {"foliage.scatter", capability_sets::edits_project()},
                                              {"foliage.paint", capability_sets::edits_project()},
                                              {"foliage.clear", capability_sets::edits_project()}});
}

}  // namespace fa
