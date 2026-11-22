#include "fa/authoring/authoring.h"

#include "authoring_internal.h"
#include "fa/runtime/command_extension.h"

namespace fa::authoring {

namespace {

// What every Engine gets: one call per file of commands, in this order. A file that moves here from the runtime adds its line
// to the group of its area.
void register_authoring_commands(Engine& engine) {
    Engine::Impl& impl = engine.runtime_impl();

    // project settings
    register_project_secret_commands(engine, impl);  // project.create_storage_secret

    // scenes, prefabs
    register_scene_file_commands(engine, impl);
    register_prefab_override_commands(engine, impl);  // prefab.overrides, prefab.revert, prefab.apply
    register_scene_clipboard_commands(engine, impl);  // scene.copy_entities, scene.paste_entities

    // animation, rigs
    register_anim_commands(engine, impl);   // anim.create_clip, anim.set_keys, anim.list, anim.check, ...
    register_bones_commands(engine, impl);  // bones.create, skin.bind, skin.auto_weights, skin.set_weights
    // effects, meshes
    register_vfx_review_commands(engine, impl);  // vfx.check, vfx.budget, vfx.filmstrip
    register_mesh_commands(engine, impl);  // mesh.create, mesh.update, mesh.destroy, mesh.save, mesh.list, mesh.info
    // reflection probes
    register_probe_commands(engine, impl);  // probe.bake
    // lightmaps
    register_lightmap_commands(engine,
                               impl);  // lightmap.bake, lightmap.bake_start, lightmap.bake_status, lightmap.bake_cancel
    // big worlds (M75 stubs)
    register_big_world_commands(engine, impl);      // world.split_cells, model.bake_impostor, terrain.*, foliage.*, ...
    register_tilemap_split_commands(engine, impl);  // tilemap.split_cells
    // levels
    register_ascii_level_commands(engine, impl);
}

}  // namespace

void install() { register_command_extension("authoring", register_authoring_commands); }

}  // namespace fa::authoring
