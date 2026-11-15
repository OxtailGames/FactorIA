// The files of fa_authoring that register commands. Each defines one function with this shape, in namespace fa, and
// src/authoring.cpp calls it from the extension. A command file moved here from engine/runtime/src keeps its code and its
// register_<area>_commands name; it includes "fa/runtime/internal/engine_impl.h" (Engine::Impl, need_entity, set_component,
// read_ascii_sample: engine tools only) instead of "engine_impl.h".
#pragma once

#include "fa/runtime/internal/engine_impl.h"

namespace fa {

void register_scene_file_commands(Engine& engine,
                                  Engine::Impl& impl);  // scene_file_commands.cpp: prefab.save, scene.format

void register_anim_commands(Engine& engine,
                            Engine::Impl& impl);  // anim_commands.cpp (+ anim_view_commands.cpp): anim.*
void register_bones_commands(Engine& engine, Engine::Impl& impl);  // bones_commands.cpp: bones.create, skin.*

}  // namespace fa
