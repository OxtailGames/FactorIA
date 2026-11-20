// Shared cgltf setup: every glTF reader of the engine (skeleton.h, the renderer's mesh loader) reads the file and its
// external buffers through fa::fs, so a packed game works.
#pragma once

#include <cgltf.h>

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"
#include "fa/scene/material_layers.h"

namespace fa {

// Points opts.file.read / release at fa::fs. Call before cgltf_parse / cgltf_load_buffers.
void gltf_use_fs(cgltf_options& opts);

// Refuses a glTF whose base64 data URI buffer declares more bytes than its payload can decode to (cgltf allocates the
// declared byteLength before decoding, so a few KB of file could ask for any size). Error: the file, /buffers/N, declared
// versus available bytes, how to fix. External .bin files are read whole by opts.file.read (its size wins over the
// declared one) and the GLB BIN chunk is compared with byteLength by cgltf, so only data URIs need this. Every reader of a
// glTF calls it between cgltf_parse and cgltf_load_buffers.
Result<void> gltf_check_buffer_sizes(const cgltf_data* data, std::string_view path);

// Checks a parsed glTF whose buffers are loaded (cgltf_load_buffers) before anything reads its accessors: every accessor,
// buffer view, index, sparse block and texture reference lies inside what it points at. cgltf_parse checks the JSON's shape,
// not the numbers, so a file whose accessor runs past its buffer would be read out of bounds. The error names `path` and
// the first thing wrong. It also refuses an accessor whose start in its buffer, or whose stride, is not a multiple of its
// component size (the specification forbids it, and cgltf reads floats and indices through typed pointers). Every reader of
// a glTF calls it once, after cgltf_load_buffers.
Result<void> gltf_check(cgltf_data* data, std::string_view path);

// Reads the five extensions of `m` into `out` (a material without them gives the defaults). A value outside its range, or not a
// number, is clamped (NaN becomes the default) and says so in `warnings`: "<what>: ior 7 is outside 1..3, clamped to 3". `what`
// names the file and the material, e.g. "assets/car.glb: material 'paint'".
void read_material_layers(const cgltf_material& m, const std::string& what, MaterialLayers& out,
                          std::vector<std::string>& warnings);

}  // namespace fa
