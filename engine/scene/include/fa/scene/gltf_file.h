// Shared cgltf setup: every glTF reader of the engine (skeleton.h, the renderer's mesh loader) reads the file and its
// external buffers through fa::fs, so a packed game works.
#pragma once

#include <cgltf.h>

#include <string_view>

#include "fa/core/types.h"

namespace fa {

// Points opts.file.read / release at fa::fs. Call before cgltf_parse / cgltf_load_buffers.
void gltf_use_fs(cgltf_options& opts);

// Checks a parsed glTF whose buffers are loaded (cgltf_load_buffers) before anything reads its accessors: every accessor,
// buffer view, index, sparse block and texture reference lies inside what it points at. cgltf_parse checks the JSON's shape,
// not the numbers, so a file whose accessor runs past its buffer would be read out of bounds. The error names `path` and
// the first thing wrong. Every reader of a glTF calls it once, after cgltf_load_buffers.
Result<void> gltf_check(cgltf_data* data, std::string_view path);

}  // namespace fa
