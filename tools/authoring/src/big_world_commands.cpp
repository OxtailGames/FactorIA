// The commands of the big worlds of M75 that write project files (docs/BIG_WORLDS.md): world.split_cells, world.merge_cells,
// model.generate_lods, model.bake_impostor, terrain.* and foliage.*. M75-P0 registers them so the names, arguments and docs are
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

void add_stub(Engine::Impl& I, const char* name, const char* summary, const std::string& description, const char* schema,
              const char* package, const char* category, bool readOnly = false) {
    const std::string cmd = name;
    const std::string pkg = package;
    I.commands.add({name, summary, description + " Not built yet (planned, " + pkg + "): the command exists so its name and arguments are fixed.",
                    parse_schema(schema), readOnly, category},
                   [cmd, pkg](const Json&) -> Json {
                       throw CommandError("not_built", cmd + " is not built yet (" + pkg + ").",
                                          "Big worlds are planned for M75: read docs/BIG_WORLDS.md (docs.read BIG_WORLDS) for what " +
                                              cmd + " will do and when. Nothing was changed.");
                   });
}

}  // namespace

void register_big_world_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    // world streaming
    add_stub(I, "world.split_cells", "Split a scene into streamable cells on a grid, with a manifest.",
             "Will cut the scene's entities into a grid of cells `cellSize` metres wide on X and Z, write one scene file per cell "
             "and the index `<name>.world.json` (the manifest: cell size, each cell's bounds and file, the entities that stay always loaded), and report what it wrote. `dryRun` only reports. "
             "Writes next to the scene unless `output` names a folder. Result: {cells, files, alwaysLoaded}. "
             "Example: world.split_cells {\"scene\":\"scenes/world.scene.json\",\"cellSize\":128}",
             R"({"type":"object","properties":{
               "scene":{"type":"string","description":"The scene file to split (project-relative path)."},
               "cellSize":{"type":"number","minimum":1,"default":128,"description":"Width of a cell in metres, on X and Z."},
               "output":{"type":"string","description":"Folder for the cell files (default: next to the scene)."},
               "dryRun":{"type":"boolean","default":false,"description":"Only report what would be written."}},"required":["scene"]})",
             "M75.3", "world");
    add_stub(I, "world.merge_cells", "Merge the cells of a split scene back into one scene file.",
             "Will read a manifest written by world.split_cells and write the entities of every cell back into one scene file "
             "(the inverse of the split, so a level can be edited as one file). `dryRun` only reports. Result: {scene, entities}. "
             "Example: world.merge_cells {\"manifest\":\"scenes/main.world.json\"}",
             R"({"type":"object","properties":{
               "manifest":{"type":"string","description":"The manifest file written by world.split_cells."},
               "output":{"type":"string","description":"The scene file to write (default: the scene the manifest was made from)."},
               "dryRun":{"type":"boolean","default":false,"description":"Only report what would be written."}},"required":["manifest"]})",
             "M75.3", "world");
    // levels of detail
    add_stub(I, "model.generate_lods", "Generate simplified LOD meshes of a model and write them to the project.",
             "Will simplify a model's meshes to `levels` lower levels of detail (each keeps `ratios[i]` of the triangles of the "
             "level above, within `maxError` metres of the original), write each as a mesh file and fill the MeshRenderer.lods "
             "of every entity that uses the model when `apply` is true. Result: {levels: [{file, triangles, error}]}. "
             "Example: model.generate_lods {\"model\":\"models/rock.glb\",\"levels\":3}",
             R"({"type":"object","properties":{
               "model":{"type":"string","description":"The model or mesh file to simplify (project-relative path)."},
               "levels":{"type":"integer","minimum":1,"maximum":8,"default":3,"description":"How many lower levels to make."},
               "ratios":{"type":"array","items":{"type":"number","exclusiveMinimum":0,"maximum":1},"description":"Share of triangles each level keeps of the one above (default 0.5 each)."},
               "maxError":{"type":"number","minimum":0,"description":"Largest distance in metres a vertex may move (default: none)."},
               "apply":{"type":"boolean","default":false,"description":"Also fill MeshRenderer.lods of the entities that use the model."}},"required":["model"]})",
             "M75.1", "assets");
    add_stub(I, "model.bake_impostor", "Bake a billboard impostor texture of a model from several views.",
             "Will render the model from `views` directions around it into an atlas of `resolution` pixels per view, write the atlas "
             "and its data file, and set MeshRenderer.impostor of the entities that use the model when `apply` is true. "
             "Result: {file, views, resolution}. Example: model.bake_impostor {\"model\":\"models/tree.glb\",\"views\":8}",
             R"({"type":"object","properties":{
               "model":{"type":"string","description":"The model or mesh file to bake (project-relative path)."},
               "views":{"type":"integer","minimum":1,"maximum":64,"default":8,"description":"How many directions around the model."},
               "resolution":{"type":"integer","minimum":16,"maximum":2048,"default":256,"description":"Pixels of one view's side."},
               "apply":{"type":"boolean","default":false,"description":"Also set MeshRenderer.impostor of the entities that use the model."}},"required":["model"]})",
             "M75.1", "assets");
    // terrain
    add_stub(I, "terrain.create", "Create a Terrain entity with a heightmap file.",
             "Will create an entity with a Terrain component and write a flat 16-bit heightmap of `resolution` samples per side "
             "(or import `heightmap`), `size` metres wide, with one layer. Result: {entity, heightmap}. "
             "Example: terrain.create {\"name\":\"ground\",\"size\":[1024,1024]}",
             R"({"type":"object","properties":{
               "name":{"type":"string","description":"Entity id of the terrain."},
               "size":{"type":"array","items":{"type":"number","exclusiveMinimum":0},"minItems":2,"maxItems":2,"description":"Metres [x, z] the terrain covers."},
               "resolution":{"type":"integer","minimum":17,"maximum":8193,"default":513,"description":"Samples per side of a new heightmap."},
               "heightmap":{"type":"string","description":"Import this 16-bit greyscale PNG or .r16 file instead of a flat one."},
               "heightScale":{"type":"number","default":100,"description":"Metres of height of a white sample."}}})",
             "M75.5", "world");
    add_stub(I, "terrain.sculpt", "Raise, lower, smooth or flatten the heightmap of a Terrain in a circle.",
             "Will change the samples of the terrain's heightmap file within `radius` metres of `center` with the brush `tool` "
             "(raise, lower, smooth, flatten), scaled by `strength` and a smooth falloff, and write the file back. "
             "Result: {changedSamples, bounds}. Example: terrain.sculpt {\"entity\":\"ground\",\"tool\":\"raise\",\"center\":[100,50],\"radius\":20}",
             R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Terrain."},
               "tool":{"type":"string","enum":["raise","lower","smooth","flatten"],"default":"raise","description":"The brush."},
               "center":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"World metres [x, z]."},
               "radius":{"type":"number","exclusiveMinimum":0,"description":"Brush radius in metres."},
               "strength":{"type":"number","minimum":0,"maximum":1,"default":0.5,"description":"How much of the brush applies."}},"required":["entity","center","radius"]})",
             "M75.5", "world");
    add_stub(I, "terrain.paint", "Paint a material layer of a Terrain in a circle.",
             "Will raise the weight of `layer` (an index into Terrain.layers) within `radius` metres of `center` by `strength` and "
             "lower the others, and write the splat map files back. Result: {changedTexels}. "
             "Example: terrain.paint {\"entity\":\"ground\",\"layer\":1,\"center\":[10,10],\"radius\":8}",
             R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Terrain."},
               "layer":{"type":"integer","minimum":0,"maximum":7,"description":"Index into Terrain.layers."},
               "center":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"World metres [x, z]."},
               "radius":{"type":"number","exclusiveMinimum":0,"description":"Brush radius in metres."},
               "strength":{"type":"number","minimum":0,"maximum":1,"default":0.5,"description":"How much of the brush applies."}},"required":["entity","layer","center","radius"]})",
             "M75.5", "world");
    add_stub(I, "terrain.holes", "Cut or fill holes (caves, tunnels) in a Terrain in a circle.",
             "Will set the texels of the terrain's holes image within `radius` metres of `center` (mode \"cut\" makes a hole, "
             "\"fill\" closes it) and write it back; the collider follows. Result: {changedTexels}. "
             "Example: terrain.holes {\"entity\":\"ground\",\"center\":[0,0],\"radius\":3}",
             R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Terrain."},
               "mode":{"type":"string","enum":["cut","fill"],"default":"cut","description":"Make a hole or close one."},
               "center":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"World metres [x, z]."},
               "radius":{"type":"number","exclusiveMinimum":0,"description":"Radius in metres."}},"required":["entity","center","radius"]})",
             "M75.5", "world");
    add_stub(I, "terrain.generate", "Fill a Terrain's heightmap with seeded procedural noise and optional erosion.",
             "Will replace the heightmap with fractal noise (`seed`, `frequency`, `octaves`) and `erosion` iterations of "
             "hydraulic erosion, deterministically (the same arguments give the same file). Result: {heightmap, minHeight, maxHeight}. "
             "Example: terrain.generate {\"entity\":\"ground\",\"seed\":7,\"octaves\":5}",
             R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Terrain."},
               "seed":{"type":"integer","default":1,"description":"The same seed gives the same terrain."},
               "frequency":{"type":"number","exclusiveMinimum":0,"default":0.004,"description":"Noise features per metre."},
               "octaves":{"type":"integer","minimum":1,"maximum":10,"default":5,"description":"Layers of noise."},
               "erosion":{"type":"integer","minimum":0,"maximum":200000,"default":0,"description":"Iterations of hydraulic erosion."}},"required":["entity"]})",
             "M75.5", "world");
    // foliage
    add_stub(I, "foliage.scatter", "Fill a Foliage's instances by a ScatterRule over a terrain.",
             "Will read the ScatterRule of `rule` (an entity id; default: the Foliage entity's own ScatterRule), place instances on "
             "the Terrain it names by density, slope, height and layers, deterministically from its seed, and write the Foliage's "
             "`instances` file. `dryRun` only counts. Result: {instances, file}. Example: foliage.scatter {\"entity\":\"grass\"}",
             R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "rule":{"type":"string","description":"Entity id with the ScatterRule (default: the Foliage entity)."},
               "dryRun":{"type":"boolean","default":false,"description":"Only count the instances."}},"required":["entity"]})",
             "M75.6", "world");
    add_stub(I, "foliage.paint", "Add or remove foliage instances by hand in a circle on the ground.",
             "Will add instances (mode \"add\", `density` per square metre) or remove them (mode \"remove\") within `radius` metres "
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
             "Will empty the Foliage's instances file, or only the instances inside `region` ([minX, minZ, maxX, maxZ] world "
             "metres). Result: {removed}. Example: foliage.clear {\"entity\":\"grass\"}",
             R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "region":{"type":"array","items":{"type":"number"},"minItems":4,"maxItems":4,"description":"[minX, minZ, maxX, maxZ] in world metres; omit for all."}},"required":["entity"]})",
             "M75.6", "world");
    declare_command_capabilities(I.commands, {{"world.split_cells", capability_sets::edits_project()},
                                              {"world.merge_cells", capability_sets::edits_project()},
                                              {"model.generate_lods", capability_sets::edits_project()},
                                              {"model.bake_impostor", capability_sets::edits_project()},
                                              {"terrain.create", capability_sets::edits_project()},
                                              {"terrain.sculpt", capability_sets::edits_project()},
                                              {"terrain.paint", capability_sets::edits_project()},
                                              {"terrain.holes", capability_sets::edits_project()},
                                              {"terrain.generate", capability_sets::edits_project()},
                                              {"foliage.scatter", capability_sets::edits_project()},
                                              {"foliage.paint", capability_sets::edits_project()},
                                              {"foliage.clear", capability_sets::edits_project()}});
}

}  // namespace fa
