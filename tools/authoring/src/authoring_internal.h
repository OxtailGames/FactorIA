// The files of fa_authoring that register commands. Each defines one function with this shape, in namespace fa, and
// src/authoring.cpp calls it from the extension. A command file moved here from engine/runtime/src keeps its code and its
// register_<area>_commands name; it includes "authoring_internal.h" (which pulls in "fa/runtime/internal/engine_impl.h": Engine::Impl, need_entity,
// set_component, read_ascii_sample; engine tools only) instead of "engine_impl.h".
#pragma once

#include "fa/runtime/internal/engine_impl.h"

namespace fa {

void register_scene_file_commands(Engine& engine,
                                  Engine::Impl& impl);  // scene_file_commands.cpp: prefab.save, scene.format
void register_prefab_override_commands(
    Engine& engine,
    Engine::Impl& impl);  // prefab_override_commands.cpp: prefab.overrides, prefab.revert, prefab.apply
// scene_file_commands.cpp: the entity JSON prefab.apply writes for a child added under an instance (see there).
Json prefab_child_json(const World& w, Entity child, std::vector<std::string>& notes);
void register_scene_clipboard_commands(
    Engine& engine,
    Engine::Impl& impl);  // scene_clipboard_commands.cpp: scene.copy_entities, scene.paste_entities
void register_ascii_level_commands(Engine& engine,
                                   Engine::Impl& impl);  // level_commands.cpp: scene.import_ascii, scene.ascii_edit

void register_anim_commands(Engine& engine,
                            Engine::Impl& impl);  // anim_commands.cpp (+ anim_view_commands.cpp): anim.*
void register_bones_commands(Engine& engine, Engine::Impl& impl);  // bones_commands.cpp: bones.create, skin.*
void register_vfx_review_commands(Engine& engine,
                                  Engine::Impl& impl);  // vfx_review_commands.cpp: vfx.check, vfx.budget, vfx.filmstrip
void register_mesh_commands(
    Engine& engine,
    Engine::Impl& impl);  // mesh_commands.cpp: mesh.create, mesh.update, mesh.destroy, mesh.save, mesh.list, mesh.info

void register_lightmap_commands(
    Engine& engine,
    Engine::Impl&
        impl);  // lightmap_commands.cpp: lightmap.bake, lightmap.bake_start, lightmap.bake_status, lightmap.bake_cancel

void register_project_secret_commands(
    Engine& engine,
    Engine::Impl& impl);  // project_secret_commands.cpp: project.create_storage_secret

void register_probe_commands(Engine& engine, Engine::Impl& impl);  // probe_commands.cpp: probe.bake

// big_world_commands.cpp: foliage.* (M75 stubs that fail with
// not_built until their package lands); it also calls register_terrain3d_commands.
void register_big_world_commands(Engine& engine, Engine::Impl& impl);
// tilemap_split_commands.cpp: tilemap.split_cells (a tilemap cut into the chunk cells of a streamed 2D world).
void register_tilemap_split_commands(Engine& engine, Engine::Impl& impl);
// world_split_commands.cpp: world.split_cells, world.merge_cells (a scene cut into the cells of a streamed world and back).
void register_world_split_commands(Engine& engine, Engine::Impl& impl);
// hlod_commands.cpp: world.bake_hlod (the merged, simplified proxy mesh of a LodGroup).
void register_hlod_commands(Engine& engine, Engine::Impl& impl);
// terrain3d_commands.cpp: terrain.create, terrain.sculpt, terrain.paint, terrain.holes, terrain.generate, terrain.save,
// terrain.undo, terrain.redo.
void register_terrain3d_commands(Engine& engine, Engine::Impl& impl);

}  // namespace fa
