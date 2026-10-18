// Shared cgltf setup: every glTF reader of the engine (skeleton.h, the renderer's mesh loader) reads the file and its
// external buffers through fa::fs, so a packed game works.
#pragma once

#include <cgltf.h>

namespace fa {

// Points opts.file.read / release at fa::fs. Call before cgltf_parse / cgltf_load_buffers.
void gltf_use_fs(cgltf_options& opts);

}  // namespace fa
