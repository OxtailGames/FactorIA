#include "fa/authoring/authoring.h"

#include "authoring_internal.h"
#include "fa/runtime/command_extension.h"

namespace fa::authoring {

namespace {

// What every Engine gets: one call per file of commands, in this order. A file that moves here from the runtime adds its line
// to the group of its area.
void register_authoring_commands(Engine& engine) {
    Engine::Impl& impl = engine.runtime_impl();

    // scenes, prefabs
    register_scene_file_commands(engine, impl);

    // animation, rigs
    register_anim_commands(engine, impl);   // anim.create_clip, anim.set_keys, anim.list, anim.check, ...
    register_bones_commands(engine, impl);  // bones.create, skin.bind, skin.auto_weights, skin.set_weights
}

}  // namespace

void install() { register_command_extension("authoring", register_authoring_commands); }

}  // namespace fa::authoring
