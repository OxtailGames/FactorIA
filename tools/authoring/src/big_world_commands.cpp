// The commands of the big worlds of M75 that write project files (docs/BIG_WORLDS.md): register_big_world_commands
// registers terrain.* (terrain3d_commands.cpp) and foliage.* (foliage_commands.cpp).
#include "authoring_internal.h"

namespace fa {

void register_big_world_commands(Engine& engine, Engine::Impl& I) {
    register_terrain3d_commands(engine, I);
    // foliage.scatter, foliage.paint, foliage.clear and foliage.restore: foliage_commands.cpp (M75-P6b)
    register_foliage_commands(engine, I);
    // levels of detail: model.generate_lods lives in fa_tooling next to the model documents it edits (assets_model.cpp)
}

}  // namespace fa
