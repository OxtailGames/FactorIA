// glTF / GLB files through cgltf: the skeleton and animation reader (parse_skeleton) and the mesh reader behind the model
// importer (read_gltf_mesh_bytes). Both must refuse a file whose accessors point outside its buffers, and neither may build
// a mesh or a skeleton of unbounded size from a small file.
#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/scene/gltf_mesh.h"
#include "fa/scene/skeleton.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), fa::fuzz::empty_project(), true);
    (void)once;
    const std::vector<std::uint8_t> bytes(data, data + size);
    (void)fa::parse_skeleton(bytes, "fuzz.glb");
    (void)fa::read_gltf_mesh_bytes(bytes, "fuzz.glb");
    return 0;
}
