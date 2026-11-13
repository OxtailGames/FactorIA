// Reads a glTF/.glb file into a MeshData (every mesh node, placed by its world transform, merged into one mesh with a submesh per material and
// part). This is what a model document's `mesh` operation (model_doc.h) and `model.import_clean` (docs/MODELING.md, "Cleaning an imported mesh")
// start from. GPU-free; the file and its buffers are read through fa::fs, so a project path works.
//
// What is read: POSITION, NORMAL, TEXCOORD_0, COLOR_0 and the indices of triangle primitives (other primitive types are skipped with a warning),
// and per material its name, base colour, base colour texture, metallic, roughness, emissive, double-sided and alpha blend. Tangents are made
// again; skins, morph targets, animations and texture transforms are ignored (the mesh is in its bind pose). The part of a submesh is the
// primitive's `extras.part` (what mesh.save and model.bake write), else "".
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/types.h"
#include "fa/scene/mesh_store.h"

namespace fa {

// An image that is inside the file (a .glb buffer view or a data: URI) used as the base colour texture of material `material` (an index into the
// submeshes' materials by order of first use: GltfMesh::materials). The caller writes it to a project file and sets MeshMaterial::texture.
struct GltfEmbeddedImage {
    std::size_t material = 0;
    std::string extension;  // "png" or "jpg"
    std::vector<std::uint8_t> bytes;
};

struct GltfMesh {
    MeshData data;  // one submesh per (material, part), in order of first use
    std::vector<MeshMaterial>
        materials;  // the distinct materials in the order of `data.submeshes`' first use; names are unique ("material_1" when the file names none)
    std::vector<std::size_t>
        submeshMaterial;  // for each of data.submeshes: its index into `materials`, or SIZE_MAX for the default (no material)
    std::vector<GltfEmbeddedImage> embedded;
    std::vector<std::string> warnings;
    std::size_t meshNodes = 0;  // nodes that carried a mesh
};

// `path` is project-relative (or absolute) and ends in .glb or .gltf. Errors name the file and say what is wrong.
Result<GltfMesh> read_gltf_mesh(const std::string& path);
// The same on a file already in memory (a .glb, or a .gltf whose buffers are embedded; an external .bin is looked up through fa::fs
// next to `path`, which names the file in the errors and is not read). The fuzz target `gltf` and tests call it.
Result<GltfMesh> read_gltf_mesh_bytes(const std::vector<std::uint8_t>& bytes, const std::string& path);

}  // namespace fa
