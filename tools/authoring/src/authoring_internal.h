// The files of fa_authoring that register commands. Each defines one function with this shape, in namespace fa, and
// src/authoring.cpp calls it from the extension. A command file moved here from engine/runtime/src keeps its code and its
// register_<area>_commands name; it includes "authoring_internal.h" (which pulls in "fa/runtime/internal/engine_impl.h": Engine::Impl, need_entity,
// set_component, read_ascii_sample; engine tools only) instead of "engine_impl.h".
#pragma once

#include "fa/runtime/internal/engine_impl.h"

namespace fa {

void register_scene_file_commands(Engine& engine,
                                  Engine::Impl& impl);  // scene_file_commands.cpp: prefab.save, scene.format
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

void register_project_secret_commands(
    Engine& engine,
    Engine::Impl& impl);  // project_secret_commands.cpp: project.create_storage_secret

}  // namespace fa
